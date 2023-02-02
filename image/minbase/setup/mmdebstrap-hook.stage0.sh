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

# fix script permissions (if broken)
find /usr/local/bin/ -type f -exec chmod 0755 {} +

# strip apt keyrings from sources.list:
sed -i -E 's/ \[[^]]+]//' /etc/apt/sources.list

# rename/move apt&dpkg configuration
renmov /etc/apt/apt.conf.d/99mmdebstrap  /etc/apt/apt.conf.d/container
renmov /etc/dpkg/dpkg.cfg.d/99mmdebstrap /etc/dpkg/dpkg.cfg.d/container

preseed='/usr/local/preseed'
if [ -d "${preseed}" ] ; then
	# CA certificates
	s="${preseed}/crt"
	if find_fast "$s/" -type f ; then
		d='/usr/local/share/ca-certificates'
		mkdir -p "$d"

		# rename *.pem -> *.crt (if any)
		find "$s/" -iname '*.pem' -type f \
		  -execdir mv -vn '{}' '{}.crt' ';'

		# copy *.crt (with directory structure, if any)
		find "$s/" -name '*.crt' -type f -printf '%P\0' \
		| tar -C "$s" --null -T - -cf - \
		| tar -C "$d" -xf -

		rm -vrf "$s"
	fi
	rm -rf "$s"

	unset s
fi

# finish with preseed
rm -vrf "${preseed}"

# perform container configuration
mkdir -p /etc/container/dpkg-filter/
/usr/local/lib/container/bootstrap/settings.sh

# try generate CA bundle with minimal bloat and make it persistent to package removal
bundle='/etc/ssl/certs/ca-certificates.crt'
java_bundle='/etc/ssl/certs/java/cacerts'

if ! apt-update ; then
	export APT_OPTS='-o Acquire::https::Verify-Peer=false -o Acquire::Check-Valid-Until=false -o Acquire::Max-FutureTime=7200'
fi

f='/usr/local/cabundle.tar'
apt-wrap 'ca-certificates-java' sh -c "update-ca-certificates --fresh ; tar -cPf $f ${bundle} ${java_bundle}"
tar -xPf "$f" ; unset f
# NB: file is preserved for "stage 1/2"

unset APT_OPTS

ls -l "${bundle}" "${java_bundle}"

# set timezone
[ -z "${TZ}" ] || {
	f='/usr/local/tzdata.tar'

	apt-wrap 'tzdata' sh -ec "tz ${TZ} ; tar -cPf $f /etc/timezone"

	tar -xPf "$f" ; rm -f "$f" ; unset f
}

# run whole image cleanup script
cleanup
