#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -ef

unset LANGUAGE LC_COLLATE LC_CTYPE LC_MESSAGES LC_NUMERIC LC_TIME
export LANG=C.UTF-8 LC_ALL=C.UTF-8

distro="${1:?}"
suite="${2:?}"
image="${3:?}"

tarball=$(mktemp -u)'.tar'

dir0=$(readlink -f "$(dirname "$0")")

ts=
. "${dir0}/common.envsh"

image=$(to_lower "${image}")

"${dir0}/tarball.stage0.sh" "${distro}" "${suite}" "${tarball}" || {
	rm -f "${tarball}"
	exit 1
}

c=$(buildah from scratch || true)
if [ -z "$c" ] ; then
	rm -f "${tarball}"
	exit 1
fi

buildah add "$c" "${tarball}" /
rm -f "${tarball}" ; unset tarball

eval "$(printf 'imgconf() { buildah config "$@" %s ; }' "$c")"

imgconf --workingdir /
imgconf --cmd bash

while read -r v ; do
	[ -n "$v" ] || continue
	imgconf --volume "$v"
done <<-EOF
$(grep -Ev '^\s*(#|$)' < "${dir0}/setup/volumes.list")
EOF

while read -r i ; do
	[ -n "$i" ] || continue
	case "$i" in
	LD_PRELOAD=* ) continue ;;
	esac
	imgconf --env "$i"
done <<-EOF
$(grep -Ev '^\s*(#|$)' < "${dir0}/setup/env.sh")
EOF

buildah commit --rm --squash "$c" "${image}"

echo "${image} has been built successfully" >&2
