#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

have_cmd() { command -v "$1" >/dev/null 2>&1 ; }

# $1 - path
# $2 - install symlink to another file (optional)
divert() {
	if ! [ -f "$1" ] ; then
		env printf "won't divert (missing): %q\\n" "$1" >&2
		return 0
	fi
	__suffix=$(dpkg-query --search "$1" || echo local)
	__suffix="${__suffix%%:*}"
	quiet dpkg-divert --divert "$1.${__suffix}" --rename "$1"
	ln -s "${2:-/bin/true}" "$1"
	unset __suffix
}

find_fast() {
	find "$@" -printf . -quit | grep -Fq .
}

find_fresh_ts() {
	{
		find "$@" -exec stat -c '%Y' '{}' '+' 2>/dev/null || :
		# duck and cover!
		echo 1
	} | sort -rn | head -n 1
}

# bootstrap apt&dpkg configuration
tar -C /usr/local/etc/ -cf - apt dpkg | tar -C /etc -xf -

# debconf itself:
debconf-set-selections <<-EOF
	debconf  debconf/frontend  select  Noninteractive
	debconf  debconf/priority  select  critical
EOF

# prevent services from auto-starting, part 1
s='/usr/sbin/policy-rc.d'
# remove file
rm -f "$s"
# provide real script in another location
x='/usr/local/sbin/policy-rc.d'
cat > "$x" <<-EOF
	#!/bin/sh
	exit 101
EOF
chmod 0755 "$x"
# install as symlink
ln -s "$x" "$s"
unset s x

# prevent services from auto-starting, part 2
b='/sbin/start-stop-daemon'
r="$b.REAL"
# undo mmdebstrap hack (if any)
if [ -f "$r" ] ; then mv -f "$r" "$b" ; fi
# rename via dpkg-divert and symlink to /bin/true
divert "$b"
unset b r

# always report that we're in chroot (oh God, who's still using ischroot?..)
divert /usr/bin/ischroot

# man-db:
debconf-set-selections <<-EOF
	man-db  man-db/auto-update     boolean  false
	man-db  man-db/install-setuid  boolean  false
EOF
rm -rf /var/lib/man-db/auto-update /var/cache/man

# hide systemd helpers
divert /usr/bin/deb-systemd-helper
divert /usr/bin/deb-systemd-invoke

# reduce impact from util-linux{,-extra}
dpkg_filter_cfg='/usr/local/etc/dpkg-filter/util-linux.auto'

util_linux_allowed='choom chrt fallocate findmnt flock getopt hardlink
ionice ipcmk ipcrm ipcs lscpu lsfd lsipc lslocks lsmem lsns more
mountpoint namei nsenter prlimit rename.ul rev runuser setarch setpriv
setsid setterm taskset uclampset unshare whereis'

allowed_regex='bin/('$(printf '%s' "${util_linux_allowed}" | tr -s '[:space:]' '|')')$'

find "${DPKG_ADMINDIR:-/var/lib/dpkg}/info/" -name 'util-linux*.list' \
  -exec grep -hE 'bin/.+' '{}' '+' \
| grep -Ev "${allowed_regex}" \
| sort -uV \
| sed -E 's/^/delete=/' \
> "${dpkg_filter_cfg}"

dpkg-filter "${dpkg_filter_cfg}"

unset dpkg_filter_cfg util_linux_allowed allowed_regex

# try generate CA bundle with minimal bloat and make it persistent to package removal
persistence_package='container-persistent-ca-bundle'
bundle='/etc/ssl/certs/ca-certificates.crt'
java_bundle='/etc/ssl/certs/java/cacerts'
local_certs='/usr/local/share/ca-certificates'
while : ; do
	if apt-list-installed | grep -qE "^${persistence_package}:" ; then
		# refusing to override already installed package
		break
	fi

	export SOURCE_DATE_EPOCH=$(date -u +%s)
	tar_opts='--blocking-factor=1 --format=gnu --no-selinux --no-xattrs --sparse --sort=name'
	export TAR_OPTIONS="${tar_opts} --mtime @${SOURCE_DATE_EPOCH} --numeric-owner --owner=0 --group=0 --exclude-vcs"

	# create package "inplace"
	refine_trigger="${persistence_package}-verify"
	script_path="/usr/lib/${persistence_package}/script.sh"
	var_dir="/var/lib/${persistence_package}"

	t=$(mktemp -d) ; : "${t:?}"

	mkdir -p "$t/DEBIAN" "$t${var_dir}"

	cat > "$t/DEBIAN/control" <<-EOF
		Package: ${persistence_package}
		Version: 20230127
		Architecture: all
		Maintainer: Konstantin Demin <rockdrilla@gmail.com>
		Installed-Size: 8
		Essential: yes
		Enhances: ca-certificates, ca-certificates-java
		Section: misc
		Priority: important
		Multi-Arch: foreign
		Description: container persistence - CA bundle
		 This package maintains persistence of CA certificate bundles, namely:
		 .
		 - ${bundle}
		 .
		 - ${java_bundle}
		 .
		 Normally, this package tracks these files via deb-triggers(5).
		 Hovewer, the one may run \`update-${persistence_package}'
		 to ensure that stored CA bundles are in sync, or
		 \`restore-${persistence_package}' to restore previous state
		 of CA bundles.
	EOF

	cat > "$t/DEBIAN/triggers" <<-EOF
		interest-await   /etc/ssl
		interest-await   /usr/share/ca-certificates
		interest-await   /usr/share/ca-certificates-java
		interest-await   update-ca-certificates
		interest-await   update-ca-certificates-fresh
		interest-await   update-ca-certificates-java
		interest-await   update-ca-certificates-java-fresh
		interest-noawait ${refine_trigger}
	EOF

	cat > "$t/script" <<-'EOF'
		#!/bin/sh
		set -f ; set +e

		# close stdin (/etc/ca-certificates/update.d/*)
		exec </dev/null

		self='@{persistence_package}'
		files='@{bundle} @{java_bundle}'
		var='@{var_dir}'
		state="${var}/ca.sha256"
		tarball="${var}/ca.tar.gz"
		tar_opts='@{tar_opts}'
		refine_trigger='@{refine_trigger}'

		verify() {
		    [ -s "${state}" ] || return 1
		    sha256sum -c < "${state}" >/dev/null 2>&1
		}
		save() {
		    ok=1
		    for f in ${files} ; do
		        [ -s "$f" ] || ok=0
		    done
		    [ "${ok}" = 1 ] || return 1

		    sha256sum -b ${files} > "${state}"
		    tar ${tar_opts} -cPf - ${files} | gzip -9 > "${tarball}"
		}
		restore() {
		    [ -s "${tarball}" ] || return 1
		    tar -xPf "${tarball}"
		}

		case "${0##*/}" in
		@{persistence_package}-hook)
		    verify || save
		    # suppress errors for hook scripts under /etc
		    exit 0
		;;
		update-@{persistence_package})
		    verify || save
		    exit
		;;
		restore-@{persistence_package})
		    verify || restore
		    exit
		;;
		esac

		if [ -z "${DPKG_MAINTSCRIPT_NAME}" ] ; then
		    echo 'this script is not intended to be ran in that way' >&2
		    exit 1
		fi

		case "$1" in
		triggered)
		    case " $2 " in
		    *" ${refine_trigger} "*)
		        verify || restore
		        exit 0
		    ;;
		    esac

		    dpkg-trigger ${refine_trigger}

		    verify || save
		;;
		esac
		exit 0
	EOF
	sed -i -E \
	  -e "s|@\{persistence_package\}|${persistence_package}|g" \
	  -e "s|@\{refine_trigger\}|${refine_trigger}|g" \
	  -e "s|@\{var_dir\}|${var_dir}|g" \
	  -e "s|@\{bundle\}|${bundle}|g" \
	  -e "s|@\{java_bundle\}|${java_bundle}|g" \
	  -e "s|@\{tar_opts\}|${tar_opts}|g" \
	"$t/script"
	chmod +x "$t/script"
	mkdir -p "$t/usr/lib/${persistence_package}"
	mv "$t/script" "$t${script_path}"

	cat > "$t/DEBIAN/postinst" <<-EOF
		#!/bin/sh
		set -e
		. ${script_path}
	EOF
	chmod +x "$t/DEBIAN/postinst"

	mkdir -p "$t/usr/sbin"
	ln -s "${script_path}" "$t/usr/sbin/update-${persistence_package}"
	ln -s "${script_path}" "$t/usr/sbin/restore-${persistence_package}"

	mkdir -p "$t/etc/ca-certificates/update.d"
	ln -s "${script_path}" "$t/etc/ca-certificates/update.d/${persistence_package}-hook"

	chmod -R go-w "$t"

	tmp_pkg="/tmp/${persistence_package}.deb"
	dpkg-deb -b "$t" ${tmp_pkg}

	unset SOURCE_DATE_EPOCH TAR_OPTIONS tar_opts refine_trigger var_dir script_path
	rm -rf "$t" ; unset t

	dpkg -i ${tmp_pkg} ; rm -f ${tmp_pkg}

	if have_cmd update-ca-certificates ; then
		update-ca-certificates
	fi

	if ! apt-update ; then
		export APT_OPTS='-o Acquire::https::Verify-Peer=false -o Acquire::Check-Valid-Until=false -o Acquire::Max-FutureTime=7200'
	fi

	apt-wrap 'ca-certificates-java' true nords never back down

	unset APT_OPTS

	ls -l ${bundle} ${java_bundle}

	if ! [ -d "${local_certs}" ] ; then
		mkdir -p "${local_certs}"
		touch -r "${bundle}" "${local_certs}"
	fi

	break
done
unset persistence_package bundle java_bundle local_certs

# set timezone
[ -z "${TZ}" ] || {
	f='/usr/local/tzdata.tar'

	apt-wrap 'tzdata' sh -ec "tz ${TZ} ; tar -cPf $f /etc/localtime /etc/timezone"

	tar -xPf "$f"
	rm -f "$f"
	unset f
}
