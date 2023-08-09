#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2023, Konstantin Demin

set -f

rootdir=$(readlink -e "$(dirname "$0")/../..")
cd "${rootdir:?}" || exit

export PATH="${rootdir}/scripts:${PATH}"

. "${rootdir}/scripts/_common.sh"
. "${rootdir}/image/nodejs/common.envsh"

export BUILD_IMAGE_ARGS="${BUILD_IMAGE_ARGS}
	CI
	NODEJS_VERSION
	NODEJS_MAJOR_VERSION
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

	export NODEJS_VERSION="$1"
	export NODEJS_MAJOR_VERSION=$(printf '%s' "${NODEJS_VERSION}" | cut -d. -f1)

	stem="nodejs-${NODEJS_MAJOR_VERSION}"

	export BUILD_IMAGE_VOLUMES="
		$(build_artifacts_volumes "${stem}" "${DEB_SRC_BUILD_DIR}" "${_SRC_DIR}" "${_PKG_DIR}")
	"

	build_image="${IMAGE_PATH}/nodejs-build:${NODEJS_VERSION}-${SUITE}"

	set -e

	BUILD_IMAGE_TARGET=build-pkg \
	scripts/build-image.sh image/nodejs/ "${build_image}"

	podman image rm -f "${build_image}"

	set +e

}

if [ $# = 0 ] ; then
	for njsver in ${nodejs_versions} ; do
		build_single "${njsver}"
	done
else
	for njsver ; do
		build_single "${njsver}"
	done
fi
