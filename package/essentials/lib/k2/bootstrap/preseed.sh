#!/bin/sh
set -f ; set +e

data_dir=/usr/share/k2/bootstrap

bundle=/etc/ssl/certs/ca-certificates.crt
java_bundle=/etc/ssl/certs/java/cacerts

have_cmd() { command -v "$1" >/dev/null 2>&1 ; }

find_fast() {
	find "$@" -printf . -quit | grep -Fq .
}

setup() {
	for f in "${bundle}" "${java_bundle}" ; do
		if [ -s "$f" ] ; then continue ; fi
		mkdir -p "${f%/*}"
		cp "${data_dir}/${f##*/}" "${f}"
	done

	while [ -d "${data_dir}/preseed" ] ; do
		find_fast "${data_dir}/preseed/" -mindepth 1 || break

		set -e
		t=$(mktemp -d)
		tar -C "${data_dir}/preseed" -cf - . | tar -C "$t" -xf -
		set +e

		# unroll templates (if any)
		distro=$(sed -En '/^ID=(.+)$/s//\1/p' /etc/os-release)
		suite=$(sed -En '/^VERSION_CODENAME=(.+)$/s//\1/p' /etc/os-release)

		find "$t/" -type f -exec grep -FIZl '@{' '{}' '+' \
		| xargs -0 -r sed -i -e "s/@{distro}/${distro}/g;s/@{suite}/${suite}/g"

		# CA certificates
		s="$t/crt"
		while [ -d "$s" ] ; do
			find_fast "$s/" -type f || break

			d='/usr/local/share/ca-certificates'
			mkdir -p "$d"

			# copy *.pem (with directory structure, if any)
			find "$s/" -iname '*.pem' -type f -printf '%P\0' \
			| tar -C "$s" --null -T - -cf - \
			| tar -C "$d" -xf -

			# copy *.crt (with directory structure, if any)
			find "$s/" -name '*.crt' -type f -printf '%P\0' \
			| tar -C "$s" --null -T - -cf - \
			| tar -C "$d" -xf -

			# rename *.pem -> *.crt (if any)
			find "$d/" -iname '*.pem' -type f \
			  -execdir mv -n '{}' '{}.crt' ';'

			if have_cmd update-ca-certificates ; then
				update-ca-certificates
			fi
		break ; done
		rm -rf "$s"

		# apt configuration
		s="$t/apt"
		while [ -d "$s" ] ; do
			find_fast "$s/" -type f || break

			# sources
			find "$s/" -name '*.list' -type f \
			  -execdir mv -t /etc/apt/sources.list.d '{}' ';'

			# keyrings
			find "$s/" -regextype egrep -regex '.+\.(asc|gpg)$' -type f \
			  -execdir mv -t /etc/apt/trusted.gpg.d '{}' ';'

			# generic configuration
			find "$s/" -name '*.conf' -type f \
			  -execdir mv -t /etc/apt/apt.conf.d '{}' ';'

			# apt pinning
			find "$s/" -name '*.pin' -type f \
			  -execdir mv -t /etc/apt/preferences.d '{}' ';'
		break ; done
		rm -rf "$s"

		# other files - extracted in root (!)
		s="$t/files"
		while [ -d "$s" ] ; do
			find_fast "$s/" -type f || break

			tar -C "$s" -cf - . | tar -C / -xf -
		break ; done
		rm -rf "$s"

		rm -rf "$t"
	break ; done
}

if [ -z "${DPKG_MAINTSCRIPT_NAME}" ] ; then
	setup
	exit 0
fi

case "$1" in
configure ) setup ;;
esac
