#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -f

# the one may want to set this:
# : "${BUILDAH_FORMAT:=docker}"
# export BUILDAH_FORMAT

rootdir=$(readlink -e "$(dirname "$0")/../..")
cd "${rootdir:?}" || exit

. "${rootdir}/.ci/common.envsh"

for d_s_t in ${DISTRO_SUITE_TAGS} ; do
	tags=
	IFS=: read -r DISTRO SUITE tags <<-EOF
	${d_s_t}
	EOF
	[ -z "${IMAGE_TAG_SUFFIX}" ] || tags=
	[ -z "${tags}" ] || tags=$(echo ":${tags}" | sed -e 's/:/ :/g')

	export DISTRO SUITE

	export BUILD_IMAGE_VOLUMES="
		$(ci_apt_volumes)
	"

	export BUILDD_IMAGE="${DISTRO}-buildd:${SUITE}${IMAGE_TAG_SUFFIX}"
	helper_image="${IMAGE_PATH}/${DISTRO}-buildd-helper:${SUITE}${IMAGE_TAG_SUFFIX}"

	BUILD_IMAGE_TARGET="buildd" \
	build-image.sh image/buildd/ "${IMAGE_PATH}/${BUILDD_IMAGE}" ${tags}

	BUILD_IMAGE_TARGET="buildd-helper" \
	BUILD_IMAGE_ARGS="${BUILD_IMAGE_ARGS} BUILDD_IMAGE" \
	build-image.sh image/buildd/ "${helper_image}" ${tags}

done
