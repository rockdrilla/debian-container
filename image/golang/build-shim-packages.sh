#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2023, Konstantin Demin

set -f

rootdir=$(readlink -e "$(dirname "$0")/../..")
cd "${rootdir:?}" || exit

. "${rootdir}/.ci/common.envsh"
. "${rootdir}/image/golang/common.envsh"

export BUILD_IMAGE_ARGS="${BUILD_IMAGE_ARGS}
	CI
	GOLANG_VERSION
	GOLANG_BASE_VERSION
	DEB_BUILD_OPTIONS
	DEB_BUILD_PROFILES
	DEB_SRC_BUILD_DIR
	_SRC_DIR
	_PKG_DIR
"

export DEB_SRC_BUILD_DIR=/build
export _SRC_DIR=/deb.src
export _PKG_DIR=/deb.pkg

export BUILD_IMAGE_CONTEXT=.
export BUILD_IMAGE_PUSH=0

build_single() {
	[ -n "$1" ] || return 0

	# if ${IMAGE_TAG_SUFFIX} is non-empty - build packages but don't upload to hosted APT registry
	# (our CI uploads freshly built packages via ${BUILD_IMAGE_SCRIPT_POST})
	[ -z "${IMAGE_TAG_SUFFIX}" ] || export BUILD_IMAGE_SCRIPT_POST=/bin/true

	export GOLANG_VERSION="$1"
	export GOLANG_BASE_VERSION=$(printf '%s' "${GOLANG_VERSION}" | cut -d. -f1-2)

	stem="golang-${GOLANG_BASE_VERSION}"

	export BUILD_IMAGE_VOLUMES="
		$(ci_apt_volumes)
		$(build_artifacts_volumes "${stem}" "${DEB_SRC_BUILD_DIR}" "${_SRC_DIR}" "${_PKG_DIR}")
	"

	set -e

	BUILD_IMAGE_TARGET=build-shim \
	build-image.sh image/golang/

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
