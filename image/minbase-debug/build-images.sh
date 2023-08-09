#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -f

# the one may want to set this:
# : "${BUILDAH_FORMAT:=docker}"
# export BUILDAH_FORMAT

rootdir=$(readlink -e "$(dirname "$0")/../..")
cd "${rootdir:?}" || exit

export PATH="${rootdir}/scripts:${PATH}"

. "${rootdir}/scripts/_common.sh"

for d_s_t in ${DISTRO_SUITE_TAGS} ; do
	tags=
	IFS=: read -r DISTRO SUITE tags <<-EOF
	${d_s_t}
	EOF
	[ -z "${IMAGE_TAG_SUFFIX}" ] || tags=
	[ -z "${tags}" ] || tags=$(echo ":${tags}" | sed -e 's/:/ :/g')

	export DISTRO SUITE

	scripts/build-image.sh image/minbase-debug/ \
	  "${IMAGE_PATH}/${DISTRO}-debug:${SUITE}${IMAGE_TAG_SUFFIX}" \
	  ${tags}
done
