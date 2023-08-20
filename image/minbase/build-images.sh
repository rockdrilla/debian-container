#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -ef

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
	[ -z "${tags}" ] || tags=$(echo ":${tags}" | sed -e 's/:/ :/g')

	# for latter usage
	export DISTRO SUITE

	stage0_image="${IMAGE_PATH}/${DISTRO}-stage0:${SUITE}"

	image/minbase/image.stage0.sh ${DISTRO} ${SUITE} "${stage0_image}"

	# build packages
	(
		export BUILD_IMAGE_PUSH=0
		export BUILD_IMAGE_CONTEXT="${rootdir}"

		export STAGE0_IMAGE="${DISTRO}-stage0:${SUITE}"

		export BUILD_IMAGE_ARGS="
			${BUILD_IMAGE_ARGS}
			STAGE0_IMAGE
			DEB_BUILD_OPTIONS
			DEB_BUILD_PROFILES
			DEB_SRC_BUILD_PURGE
			DEB_SRC_BUILD_DIR
			_SRC_DIR
			_PKG_DIR
		"

		export DEB_SRC_BUILD_DIR=/build
		export _SRC_DIR=/deb.src
		export _PKG_DIR=/deb.pkg

		stem="essentials"
		rm -rf "$(build_artifacts_path "${stem}")"

		export BUILD_IMAGE_VOLUMES="
			$(build_artifacts_volumes "${stem}" "${DEB_SRC_BUILD_DIR}" "${_SRC_DIR}" "${_PKG_DIR}")
		"

		if [ -d "${rootdir}/preseed" ] ; then
			export BUILD_IMAGE_VOLUMES="${BUILD_IMAGE_VOLUMES}
				${rootdir}/preseed:/usr/local/preseed:ro
			"
		fi

		build-image.sh image/minbase/Dockerfile.stage1
	) || exit 1

	# remove intermediate images
	podman image rm -f "${stage0_image}"

	sleep 1

	image="${IMAGE_PATH}/${DISTRO}:${SUITE}${IMAGE_TAG_SUFFIX}"
	image/minbase/image.sh ${DISTRO} ${SUITE} "${image}"
	stub_build "${image}" ${tags}
done
