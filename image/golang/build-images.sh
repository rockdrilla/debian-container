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
. "${rootdir}/image/golang/common.envsh"

export BUILD_IMAGE_ARGS="${BUILD_IMAGE_ARGS}
	GOLANG_MIN_IMAGE
"

build_single() {
	[ -n "$1" ] || return 0

	export GOLANG_VERSION="$1"
	export GOLANG_BASE_VERSION=$(printf '%s' "${GOLANG_VERSION}" | cut -d. -f1-2)

	stem="golang-${GOLANG_BASE_VERSION}"

	if [ -z "${CI}" ] ; then
		packages="$(build_artifacts_path "${stem}/pkg")"
		export BUILD_IMAGE_CONTEXTS="
			packages=${packages}
		"
	fi

	export GOLANG_MIN_IMAGE="golang-min:${GOLANG_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"
	full_image="${IMAGE_PATH}/golang:${GOLANG_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"

	extra_tags=":${GOLANG_BASE_VERSION}-${SUITE}"
	[ -z "${IMAGE_TAG_SUFFIX}" ] || extra_tags=

	set -e

	BUILD_IMAGE_TARGET="minimal${CI:+-ci}" \
	BUILD_IMAGE_ENV="GOLANG_VERSION GOLANG_BASE_VERSION" \
	scripts/build-image.sh image/golang/ "${IMAGE_PATH}/${GOLANG_MIN_IMAGE}" ${extra_tags}

	# "golang" derives env from "golang-min"

	BUILD_IMAGE_TARGET="regular${CI:+-ci}" \
	scripts/build-image.sh image/golang/ "${full_image}" ${extra_tags}

	set +e

}

if [ $# = 0 ] ; then
	for gover in ${golang_versions} ; do
		build_single "${gover}"
	done
else
	for gover ; do
		build_single "${gover}"
	done
fi
