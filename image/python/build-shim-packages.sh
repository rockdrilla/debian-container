#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2023, Konstantin Demin

set -f

rootdir=$(readlink -e "$(dirname "$0")/../..")
cd "${rootdir:?}" || exit

. "${rootdir}/.ci/common.envsh"
. "${rootdir}/image/python/common.envsh"

export BUILD_IMAGE_ARGS="${BUILD_IMAGE_ARGS}
	PYTHON_VERSION
	PYTHON_BASE_VERSION
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

	export PYTHON_VERSION="$1"
	export PYTHON_BASE_VERSION=$(printf '%s' "${PYTHON_VERSION}" | cut -d. -f1-2)

	stem="python-${PYTHON_BASE_VERSION}"

	export BUILD_IMAGE_VOLUMES="
		$(ci_apt_volumes)
		$(build_artifacts_volumes "${stem}" "${DEB_SRC_BUILD_DIR}" "${_SRC_DIR}" "${_PKG_DIR}")
	"

	build_image="${IMAGE_PATH}/python-shim-build:${PYTHON_VERSION}-${SUITE}"

	set -e

	BUILD_IMAGE_TARGET=build-shim \
	build-image.sh image/python/ "${build_image}"

	podman image rm -f "${build_image}"

	set +e

}

if [ $# = 0 ] ; then
	for pyver in ${python_versions} ; do
		build_single "${pyver}"
	done
else
	for pyver ; do
		build_single "${pyver}"
	done
fi
