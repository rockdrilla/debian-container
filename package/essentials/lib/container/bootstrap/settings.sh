#!/bin/sh
set -f ; set +e

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

	echo "delete=$1.*" >> /etc/container/dpkg-filter/bootstrap-divert.auto
}

setup() {

	VERSION_CODENAME=$(sed -En '/^VERSION_CODENAME=(.+)$/s//\1/p' /etc/os-release)
	case "${VERSION_CODENAME}" in
	# enable backports for these releases:
	# bullseye - Debian 11
	# focal    - Ubuntu 20.04
	bullseye | focal)
		apt-backports enable
		apt-pin backports-dev 500 '@{suite}-backports' src:debhelper src:devscripts src:dh-golang src:dh-python src:dh-cargo src:golang src:rustc src:cargo
	;;
	esac

	# debconf itself:
	debconf-set-selections <<-EOF
		debconf  debconf/frontend  select  Noninteractive
		debconf  debconf/priority  select  critical
	EOF

	# prevent services from auto-starting, part 1
	s='/usr/sbin/policy-rc.d'
	# remove file
	rm -f "$s"
	# provide real script with different name
	x="$s.real"
	cat > "$x" <<-EOF
		#!/bin/sh
		exit 101
	EOF
	chmod 0755 "$x"
	# install as symlink
	ln -s "$x" "$s"

	# prevent services from auto-starting, part 2
	b='/sbin/start-stop-daemon'
	r="$b.REAL"
	# undo mmdebstrap hack (if any)
	if [ -f "$r" ] ; then mv -f "$r" "$b" ; fi
	# rename via dpkg-divert and symlink to /bin/true
	divert "$b"

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

}

if [ -z "${DPKG_MAINTSCRIPT_NAME}" ] ; then
	setup
	exit 0
fi

case "$1" in
configure) setup ;;
esac
