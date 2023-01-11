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

if [ -d "$1" ] ; then
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
	c="/${0##*/}"
	cp -a "$0" "$1$c"

	# reexec within chroot
	chroot "$1" "$c" "$@"
	rm "$1$c"
	exit
fi

# fix script permissions (if broken)
find /usr/local/bin -type f -exec chmod 0755 {} +

# remove "keep" files (if any)
find /usr/local/ -name .keep -type f -delete

# remove docs (if any)
find /usr/local -name '*.md' -type f -delete

# rename apt/dpkg configuration
mv /etc/apt/apt.conf.d/99mmdebstrap  /etc/apt/apt.conf.d/container
mv /etc/dpkg/dpkg.cfg.d/99mmdebstrap /etc/dpkg/dpkg.cfg.d/container

## approach to minimize manually installed packages list
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
| xargs -r quiet apt-mark auto

rm -rf "$w"

# fix ownership:
# mmdebstrap's actions 'sync-in' and 'copy-in' preserves source user/group
fix_ownership() {
	s="${1%%|*}" ; a="${1##*|}"
	# sysroot_skiplist='^/(dev|proc|run|sys)$'
	find / -regextype egrep \
	  -regex '^/(dev|proc|run|sys)$' -prune -o \
	  '(' $s -exec $a '{}' '+' ')'
}

[ "$4" = 0 ] || fix_ownership "-uid $4|chown -h 0"
[ "$5" = 0 ] || fix_ownership "-gid $5|chgrp -h 0"

# reproducibility
echo "$2-$3" > /etc/hostname
: > /etc/resolv.conf
