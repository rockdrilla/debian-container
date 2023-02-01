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

find_fast() {
	find "$@" -printf . -quit | grep -Fq .
}

renmov() {
	[ -f "$1" ]
	mkdir -p "$(dirname "$2")"
	mv "$1" "$2"
}

# fix ownership:
# mmdebstrap's actions 'sync-in' and 'copy-in' preserves source user/group
fix_ownership() {
	s="${1%%|*}" ; a="${1##*|}"
	find /usr/local/ -xdev $s -exec $a '{}' '+'
}

[ "$4" = 0 ] || fix_ownership "-uid $4|chown -h 0"
[ "$5" = 0 ] || fix_ownership "-gid $5|chgrp -h 0"

# fix script permissions (if broken)
find /usr/local/bin -type f -exec chmod 0755 {} +

# adjust bootstrap script
f='/usr/local/bin/minbase-initial.sh'
if [ -f "$f" ] ; then
	chmod -x "$f"
	mv "$f" /usr/local/
fi

# remove "keep" files (if any)
find /usr/local/ -xdev -name .keep -type f -delete

# remove docs (if any)
find /usr/local/ -xdev -name '*.md' -type f -delete

# strip apt keyrings from sources.list:
sed -i -E 's/ \[[^]]+]//' /etc/apt/sources.list

# rename/move apt&dpkg configuration
renmov /etc/apt/apt.conf.d/99mmdebstrap  /etc/apt/apt.conf.d/container
renmov /etc/dpkg/dpkg.cfg.d/99mmdebstrap /etc/dpkg/dpkg.cfg.d/container

preseed='/usr/local/preseed'
if [ -d "${preseed}" ] ; then
	# apt configuration
	s="${preseed}/apt"
	if find_fast "$s" -mindepth 1 ; then
		# sources
		find "$s" -name '*.list' -type f \
		  -execdir mv -vt /etc/apt/sources.list.d '{}' ';'
		# keyrings
		find "$s" -name '*.asc' -type f \
		  -execdir mv -vt /etc/apt/trusted.gpg.d '{}' ';'
		find "$s" -name '*.gpg' -type f \
		  -execdir mv -vt /etc/apt/trusted.gpg.d '{}' ';'
		# generic configuration
		find "$s" -name '*.conf' -type f \
		  -execdir mv -vt /etc/apt/apt.conf.d '{}' ';'
		# apt pinning
		find "$s" -name '*.pin' -type f \
		  -execdir mv -vt /etc/apt/preferences.d '{}' ';'

		rm -vrf "$s"
	fi
	rm -rf "$s"

	# CA certificates
	s="${preseed}/crt"
	if find_fast "$s" -mindepth 1 ; then
		d='/usr/local/share/ca-certificates'
		mkdir -p "$d"

		find "$s" -name '*.crt' -type f \
		  -execdir mv -vnt "$d" '{}' ';'

		# rename *.pem -> *.crt (if any)
		(
		cd "$s"
		find "$s" -iname '*.pem' -type f -printf '%P\n' \
		| while read -r f ; do
			[ -n "$f" ] || continue
			f_new="${f%.*}.crt"
			mv -v "$f" "${f_new}"
		done
		)

		find "$s" -name '*.crt' -type f \
		  -execdir mv -vnt "$d" '{}' ';'

		rm -vrf "$s"
	fi
	rm -rf "$s"

	# other files - extracted in root (!)
	s="${preseed}/files"
	if find_fast "$s" -mindepth 1 ; then
		tar -C "$s" -cf - . | tar -C / -xvf -

		rm -rf "$s"
	fi
	rm -rf "$s"

	rm -vrf "${preseed}"
fi

case "$2:$3" in
# enable backports for these releases
debian:bullseye | ubuntu:focal)
	apt-backports enable
	apt-pin backports-dev 500 "$3-backports" src:debhelper src:devscripts
;;
esac

# source/run bootstrap script
. /usr/local/minbase-initial.sh

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
| xargs -r quiet apt-mark auto

rm -rf "$w"

# replace "usrmerge" with "usr-is-merged"
apt-update
if apt-install usr-is-merged >/dev/null 2>&1 ; then
	quiet dpkg -P usrmerge
fi

# cleanup installed packages
quiet apt-autoremove

# reproducibility
echo "$2-$3" > /etc/hostname
: > /etc/resolv.conf

# run whole image cleanup script
VERBOSE=1 cleanup
