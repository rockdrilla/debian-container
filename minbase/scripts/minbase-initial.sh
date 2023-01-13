#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

# $1 - path
# $2 - install symlink to another file (optional)
divert() {
	if ! [ -f "$1" ] ; then
		env printf "won't divert (missing): %q\\n" "$1" 1>&2
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

# try generate CA bundle with minimal bloat
bundle='/etc/ssl/certs/ca-certificates.crt'
while : ; do
	if [ -s "${bundle}" ] ; then break ; fi

	if update-ca-certificates ; then break ; fi

	if ! apt-update ; then
		export APT_OPTS='-o Acquire::https::Verify-Peer=false -o Acquire::Check-Valid-Until=false -o Acquire::Max-FutureTime=7200'
	fi

	f='/usr/local/cabundle.tar'

	APT_WRAP_DEPS='ca-certificates' \
	apt-wrap tar -cPf "$f" "${bundle}"

	unset APT_OPTS

	tar -xPf "$f"
	rm -f "$f"
	unset f

	break
done
unset bundle

# set timezone
[ -z "${TZ}" ] || {
	f='/usr/local/tzdata.tar'

	APT_WRAP_DEPS='tzdata' \
	apt-wrap sh -ec "tz ${TZ} ; tar -cPf $f /etc/localtime /etc/timezone"

	tar -xPf "$f"
	rm -f "$f"
	unset f
}