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
	rootdir=$(readlink -e "${dir0}/../../..")
	pkg_dir="${rootdir}/package/essentials"

	echo "# rootdir: ${rootdir}" >&2
	echo "# pkg_dir: ${pkg_dir}" >&2

	# naive copy of container essential packages inside chroot
	# e.g.: package/essentials/common-tools/bin -> /usr/local/bin
	find "${pkg_dir}/" -mindepth 1 -maxdepth 1 -type d \
	| grep -E '/(bin|etc|lib|sbin|share)$' \
	| while read -r dir ; do
		cp -vaR "${dir}/" "$1/usr/local/"
	done

	# read environment from file (except PATH)
	while read -r i ; do
		[ -n "$i" ] || continue
		case "$i" in
		PATH=* | LD_* | LANG* | LC_* ) continue ;;
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

rand4() {
	od -v -A n -t x4 -N 4 < /dev/urandom | tr -d '[:space:]'
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

# rename/move apt&dpkg configuration
renmov /etc/apt/apt.conf.d/99mmdebstrap  /etc/apt/apt.conf.d/k2
renmov /etc/dpkg/dpkg.cfg.d/99mmdebstrap /etc/dpkg/dpkg.cfg.d/k2

preseed='/usr/local/preseed'
if [ -d "${preseed}" ] ; then
	# CA certificates
	s="${preseed}/crt"
	if find_fast "$s/" -type f ; then
		d='/usr/local/share/ca-certificates'
		mkdir -p "$d"

		# convert/enforce *.pem (if any) to PEM format
		find "$s/" -iname '*.pem' -type f \
		| while read -r src ; do
			[ -n "${src}" ] || continue
			dst_name="${src%.[Pp][Ee][Mm]}"
			dst="${dst_name}.crt"
			! [ -f "${dst}" ] || dst="${dst_name}.pem.crt"
			! [ -f "${dst}" ] || dst="${dst_name}.$(rand4).pem.crt"
			openssl x509 -in "${src}" -out "${dst}" -outform PEM
			echo "${src} -> ${dst}"
			rm -f "${src}"
		done

		# adjust file name extensions
		find "$s/" -iname '*.crt' -type f \
		| while read -r src ; do
			[ -n "${src}" ] || continue
			dst="${src%.[Cc][Rr][Tt]}.crt"
			[ "${src}" = "${dst}" ] || mv -fv "${src}" "${dst}"
		done

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

# quirk: update package lists
# hits on relatively old releases like Ubuntu 20.04 "focal"
set +e
apt update
/usr/lib/dpkg/methods/apt/update "${DPKG_ADMINDIR:-/var/lib/dpkg}" apt apt
set -e

# perform container configuration
mkdir -p /etc/k2/dpkg-filter/
/usr/local/lib/k2/bootstrap/settings.sh

# generate CA bundles
update-ca-certificates --fresh

# adjust missing CAs with certifi
certifi_uri="${MMDEBSTRAP_MIRROR_CERTIFI:-https://github.com/certifi/python-certifi/raw/master}/certifi/cacert.pem"
{
	w=$(mktemp -d) ; : "${w:?}"
	curl -sSL -o "$w/cacert.pem" "${certifi_uri}"

	def_bundle='/etc/ssl/certs/ca-certificates.crt'

	bundle_offsets() {
		grep -Fhne '-----END CERTIFICATE-----' "$1" | cut -d : -f 1 \
		| {
			s=1 ; while read -r e ; do
				[ -n "$e" ] || continue
				echo "$s,$e"
				s=$((e+1))
			done
		}
	}

	set +e
	bundle_offsets "${def_bundle}" > "$w/offsets.0"
	bundle_offsets "$w/cacert.pem" > "$w/offsets.1"
	set -e

	bundle_fingerprints() {
		while read -r a ; do
			[ -n "$a" ] || continue
			sed -ne "${a}p" "$1" | openssl x509 -noout -fingerprint
		done < "$2"
	}

	set +e
	bundle_fingerprints "${def_bundle}" "$w/offsets.0" > "$w/fingerprints.0"
	bundle_fingerprints "$w/cacert.pem" "$w/offsets.1" > "$w/fingerprints.1"
	set -e

	set +e
	grep -Fxv -f "$w/fingerprints.0" "$w/fingerprints.1" > "$w/fingerprints.diff"
	set -e

	if [ -s "$w/fingerprints.diff" ] ; then
		set +e
		grep -Fxn -f "$w/fingerprints.diff" "$w/fingerprints.1" | cut -d : -f 1 > "$w/records.diff"
		set -e

		terse_fingerprint() {
			cut -d = -f 2- | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]'
		}

		mkdir "$w/certifi-extras"

		while read -r n ; do
			[ -n "$n" ] || continue
			fp=$(sed -ne "${n}p" "$w/fingerprints.1" | terse_fingerprint)
			off=$(sed -ne "${n}p" "$w/offsets.1")
			sed -ne "${off}p" "$w/cacert.pem" | openssl x509 > "$w/certifi-extras/${fp}.crt"
		done < "$w/records.diff"

		env -C "$w" find "certifi-extras/" -mindepth 1 -exec ls -ld {} +

		for d in /usr/local/preseed/crt /usr/local/share/ca-certificates ; do
			mkdir -p "$d"
			tar -C "$w" -cf - certifi-extras | tar -C "$d" -xf -
		done
	fi

	rm -rf "$w"
}

# generate CA bundles (again)
update-ca-certificates --fresh

# cleanup
apt-remove ca-certificates-java default-jre-headless
apt-autoremove

# drop setuid/setgid
while read -r f ; do
	[ -n "$f" ] || continue

	u=$(env stat -c '%u' "$f")
	g=$(env stat -c '%g' "$f")

	m='0'$(env stat -c '%a' "$f")
	m=$(( m & ~07000 ))
	m='0'$(printf '%o' $m)

	dpkg-statoverride --update --add "#$u" "#$g" "$m" "$f"
done <<-EOF
$(find / -xdev -perm /07000 -type f | sort -uV)
EOF

# set timezone
# NB: releases after Debian 12 "Bookworm" won't need /etc/timezone anymore.
# ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=822733
[ -z "${TZ}" ] || {
	TZ_LEAN=1 tz "${TZ}"
}

# run whole image cleanup script
cleanup
