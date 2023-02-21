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

golang_versions='
	1.18.10
	1.19.6
	1.20.1
'

# build only Debian variant (for now)
export DISTRO=debian SUITE=bullseye

export BUILD_IMAGE_ARGS="
	${BUILD_IMAGE_ARGS}
	GOLANG_MIN_IMAGE
	GOLANG_VERSION
	GOLANG_BASE_VERSION
	DEB_BUILD_OPTIONS
	DEB_SRC_BUILD_PURGE
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

export DEB_SRC_BUILD_DIR=/usr/local/src
export _SRC_DIR=/usr/local/include
export _PKG_DIR=/usr/local/lib

export BUILD_IMAGE_ENV="GOLANG_VERSION"

export BUILD_IMAGE_CONTEXT=package/golang

build_single() {
	[ -n "$1" ] || return 0

	export GOLANG_VERSION="$1"

	export GOLANG_BASE_VERSION=$(printf '%s' "${GOLANG_VERSION}" | cut -d. -f1-2)

	stem="golang-${GOLANG_BASE_VERSION}"

	export BUILD_IMAGE_VOLUMES="
		$(build_artifacts_volumes "${stem}" "${DEB_SRC_BUILD_DIR}" "${_SRC_DIR}" "${_PKG_DIR}")
	"

	export GOLANG_MIN_IMAGE="golang-min:${GOLANG_VERSION}-${SUITE}"

	set -e

	BUILD_IMAGE_TARGET=minimal \
	scripts/build-image.sh image/golang/ \
	"${IMAGE_PATH}/${GOLANG_MIN_IMAGE}" ":${GOLANG_BASE_VERSION}-${SUITE}"

	BUILD_IMAGE_TARGET=regular \
	scripts/build-image.sh image/golang/ \
	"${IMAGE_PATH}/golang:${GOLANG_VERSION}-${SUITE}" ":${GOLANG_BASE_VERSION}-${SUITE}"

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
