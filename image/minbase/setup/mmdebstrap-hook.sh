#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

# script parameters:
# $1 - chroot path
# $2 - distro name
# $3 - suite name
# $4 - uid
# $5 - gid

set -e

c="/tmp/${0##*/}"
if [ "$0" != "$c" ] ; then
	dir0=$(dirname "$0")

	# read environment from file (except PATH)
	while read -r i ; do
		[ -n "$i" ] || continue
		case "$i" in
		PATH=*) continue ;;
		esac
		export "${i?}"
	done <<-EOF
	$(grep -Ev '^\s*(#|$)' < "${dir0}/env.sh")
	EOF

	# copy self inside chroot
	cp -a "$0" "$1$c"

	# reexec within chroot
	chroot "$1" "$c" "$@"
	rm -f "$1$c"
	exit
fi

have_cmd() { command -v "$1" >/dev/null 2>&1 ; }

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

renmov() {
	[ -f "$1" ]
	mkdir -p "$(dirname "$2")"
	mv "$1" "$2"
}

# fix ownership:
# mmdebstrap's actions 'sync-in' and 'copy-in' preserves source user/group
fix_ownership() {
	find /usr/local/ -xdev ${1%%|*} -exec ${1##*|} '{}' '+'
}

[ "$4" = 0 ] || fix_ownership "-uid $4|chown -h 0"
[ "$5" = 0 ] || fix_ownership "-gid $5|chgrp -h 0"

# strip apt keyrings from sources.list:
sed -i -E 's/ \[[^]]+]//' /etc/apt/sources.list

# symlink (missing) keyrings (also deduplicate files a bit)
find /usr/share/keyrings/ -follow ! -name '*removed*' -type f -size +1c \
| sort -V \
| while read -r keyring ; do
	[ -n "${keyring}" ] || continue
	ln -fvs "${keyring}" "/etc/apt/trusted.gpg.d/${keyring##*/}"
done

# rename/move apt&dpkg configuration
renmov /etc/apt/apt.conf.d/99mmdebstrap  /etc/apt/apt.conf.d/container
renmov /etc/dpkg/dpkg.cfg.d/99mmdebstrap /etc/dpkg/dpkg.cfg.d/container

# approach to minimize manually installed packages list
w=$(mktemp -d) ; : "${w:?}"

dpkg-query --show --showformat='${db:Status-Abbrev}|${Essential}|${binary:Package}|${Version}\n' \
> "$w/all"

mawk -F '|' '{ if ($1 ~ "^[hi]i ") print $0;}' \
< "$w/all" \
> "$w/good"

mawk -F '|' '{ if ($2 == "yes") print $3;}' \
< "$w/good" \
| cut -d : -f 1 \
| sort -V \
> "$w/essential"

apt-mark showmanual \
| cut -d : -f 1 \
| sort -V \
> "$w/manual"

grep -Fvx -f "$w/essential" \
< "$w/manual" \
> "$w/manual.regular"

# apt is manually installed (by mmdebstrap but it doesn't matter)
echo apt \
| tr -s '[:space:]' '\n' \
| grep -Fvx -f - "$w/manual.regular" \
| xargs -r apt-mark auto

rm -rf "$w"

# simple regex for matching *.deb
arch=$(dpkg --print-architecture)
deb_file_mask=$(printf '.+_(all|%s)\.deb$' "${arch:?}")

# install own packages
bootstrap='/usr/local/bootstrap'

set +e
for i in 1 2 ; do
	# quirk: update package lists
	# hits on relatively old releases like Ubuntu 20.04 "focal"
	apt update
	/usr/lib/dpkg/methods/apt/update "${DPKG_ADMINDIR:-/var/lib/dpkg}" apt apt

	env -C "${bootstrap}" \
	find ./ -regextype egrep -regex "${deb_file_mask}" -type f \
	  -exec dpkg -i '{}' '+' || apt-get -y --fix-broken install

	set -e
done

rm -rf "${bootstrap}"

# fixtures
update-container-persistent-ca-bundle
update-container-persistent-ca-bundle-java

# remove bootstrap package(s)
apt-list-installed | grep -E '^container-bootstrap' \
| xargs -r dpkg -P || :

# replace "usrmerge" with "usr-is-merged"
apt-update
if apt-install usr-is-merged >/dev/null 2>&1 ; then
	dpkg -P usrmerge
fi

# set timezone
# NB: releases after Debian 12 "Bookworm" won't need /etc/timezone anymore.
# ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=822733
[ -z "${TZ}" ] || {
	f='/usr/local/tzdata.tar'

	apt-wrap 'tzdata' sh -ec "tz ${TZ} ; tar -cPf $f /etc/timezone"

	tar -xPf "$f" ; rm -f "$f" ; unset f
}

preseed='/usr/local/preseed'
if [ -d "${preseed}" ] ; then
	# extra packages
	s="${preseed}/pkg"
	if find_fast "$s/" -regextype egrep -regex "${deb_file_mask}" -type f ; then
		env -C "$s" apt-env \
		find ./ -regextype egrep -regex "${deb_file_mask}" -type f \
		  -exec dpkg -i '{}' '+' || apt-install --fix-broken

		rm -vrf "$s"
	fi
	rm -rf "$s"

	unset s
fi

# finish with preseed
rm -vrf "${preseed}"

# cleanup installed packages
apt-autoremove

# reproducibility
echo "$2-$3" > /etc/hostname
: > /etc/resolv.conf

# run whole image cleanup script
VERBOSE=1 cleanup
