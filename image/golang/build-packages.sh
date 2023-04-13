#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -f

rootdir=$(readlink -e "$(dirname "$0")/../..")
cd "${rootdir:?}" || exit

export PATH="${rootdir}/scripts:${PATH}"

. "${rootdir}/scripts/_common.sh"
. "${rootdir}/image/golang/common.envsh"

if [ $# = 0 ] ; then
	for gover in ${golang_versions} ; do
		image/golang/build-shim-packages.sh "${gover}"
	done
else
	for gover ; do
		image/golang/build-shim-packages.sh "${gover}"
	done
fi

export BUILD_IMAGE_ARGS="${BUILD_IMAGE_ARGS}
	CI
	GOLANG_VERSION
	GOLANG_BASE_VERSION
	DEB_BUILD_OPTIONS
	DEB_SRC_BUILD_DIR
	_SRC_DIR
	_PKG_DIR
	GOPROXY
	GOSUMDB
	GOPRIVATE
"

# for use with proxy
# export GOPROXY='http://127.0.0.1:8081/repository/proxy_go,direct'
# export GOSUMDB='sum.golang.org http://127.0.0.1:8081/repository/proxy_raw_go_sum'

export DEB_SRC_BUILD_DIR=/build
export _SRC_DIR=/deb.src
export _PKG_DIR=/deb.pkg

export BUILD_IMAGE_CONTEXT=package/golang

build_single() {
	[ -n "$1" ] || return 0

	# if ${IMAGE_TAG_SUFFIX} is non-empty - build packages but don't upload to hosted APT registry
	# (our CI uploads freshly built packages via ${BUILD_IMAGE_SCRIPT_POST})
	[ -z "${IMAGE_TAG_SUFFIX}" ] || export BUILD_IMAGE_SCRIPT_POST=/bin/true

	export GOLANG_VERSION="$1"
	export GOLANG_BASE_VERSION=$(printf '%s' "${GOLANG_VERSION}" | cut -d. -f1-2)

	stem="golang-${GOLANG_BASE_VERSION}"

	export BUILD_IMAGE_VOLUMES="
		$(build_artifacts_volumes "${stem}" "${DEB_SRC_BUILD_DIR}" "${_SRC_DIR}" "${_PKG_DIR}")
	"

	build_image="${IMAGE_PATH}/golang-build:${GOLANG_VERSION}-${SUITE}"

	set -e

	BUILD_IMAGE_TARGET=build \
	BUILD_IMAGE_PUSH=0 \
	scripts/build-image.sh image/golang/ "${build_image}"

	podman image rm -f "${build_image}"

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
