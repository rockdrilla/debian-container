#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

if [ -n "${SOURCE_DATE_EPOCH}" ] ; then
	ts="${SOURCE_DATE_EPOCH}"
else
	ts=$(date -u '+%s')
	export SOURCE_DATE_EPOCH="${ts}"
fi

to_lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' ; }

distro=$(to_lower "${distro}")
suite=$(to_lower "${suite}")

# adjust suite (naive)
case "${distro}" in
debian)
	case "${suite}" in
	11) suite=bullseye ;;
	12) suite=bookworm ;;
	13) suite=trixie ;;
	esac
;;
ubuntu)
	case "${suite}" in
	20.04) suite=focal ;;
	22.04) suite=jammy ;;
	esac
;;
esac
