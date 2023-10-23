#!/bin/sh
set -f ; set +e

# close stdin (/etc/ca-certificates/update.d/*)
exec </dev/null

orig_file='/etc/ssl/certs/java/cacerts'
var='/var/lib/k2/persistence'
state="${var}/ca-bundle-java.sha256"
backup="${var}/ca-bundle-java.gz"
refine_trigger='k2-ca-bundle-java-verify'

verify() {
	[ -s "${state}" ] || return 1
	sha256sum -c < "${state}" >/dev/null 2>&1
}
save() {
	[ -s "${orig_file}" ] || return 1

	mkdir -p "${var}" || return 1
	sha256sum -b "${orig_file}" > "${state}"
	gzip -9f < "${orig_file}" > "${backup}"
}
restore() {
	[ -s "${backup}" ] || return 1
	mkdir -p "$(dirname "${orig_file}")" || return 1
	gzip -df < "${backup}" > "${orig_file}"
}

case "${0##*/}" in
k2-*-hook )
	verify || save
	# suppress errors for hook scripts (e.g. under /etc)
	exit 0
;;
k2-*-update )
	verify || save
	exit
;;
k2-*-restore )
	verify || restore
	exit
;;
esac

if [ -z "${DPKG_MAINTSCRIPT_NAME}" ] ; then
	echo "$0: this script is not intended to be ran in that way" >&2
	exit 1
fi

find_fast() {
	find "$@" -printf . -quit | grep -Fq .
}

case "$1" in
triggered )
	case " $2 " in
	*" ${refine_trigger} "* )
		verify || restore
		exit 0
	;;
	esac

	dpkg-trigger ${refine_trigger}

	verify || save
	exit 0
;;
purge )
	rm -vf "${state}" "${backup}"
	find_fast "${var}" -mindepth 1 || rm -vrf "${var}"
	exit 0
;;
esac
