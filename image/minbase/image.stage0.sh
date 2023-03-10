#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -ef

distro="${1:?}"
suite="${2:?}"
image="${3:?}"

tarball=$(mktemp -u)'.tar'

dir0=$(readlink -f "$(dirname "$0")")

ts=
. "${dir0}/_common.sh"

image=$(to_lower "${image}")

"${dir0}/tarball.stage0.sh" "${distro}" "${suite}" "${tarball}" || {
	rm -f "${tarball}"
	exit 1
}

sha256() { sha256sum -b "$1" | sed -En '/^([[:xdigit:]]+).*$/{s//\L\1/;p;}' ; }

tar_sha256=$(sha256 "${tarball}")

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

while read -r i ; do
	[ -n "$i" ] || continue
	imgconf --env "$i"
done <<-EOF
$(grep -Ev '^\s*(#|$)' < "${dir0}/setup/env.sh")
EOF

buildah commit --rm --squash --timestamp "${ts}" "$c" "${image}"

echo "${image} has been built successfully" >&2
