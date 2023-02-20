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

python_versions='
	3.9.16
	3.10.10
	3.11.2
'

: "${DEB_BUILD_OPTIONS:=pgo_full lto_part=none}"
export DEB_BUILD_OPTIONS

# build only Debian variant (for now)
export DISTRO=debian SUITE=bullseye

export BUILD_IMAGE_ARGS="
	${BUILD_IMAGE_ARGS}
	PYTHON_VERSION
	PYTHON_BASE_VERSION
	DEB_BUILD_OPTIONS
	DEB_SRC_BUILD_PURGE
	DEB_SRC_BUILD_DIR
	_SRC_DIR
	_PKG_DIR
"

export DEB_SRC_BUILD_DIR=/usr/local/src
export _SRC_DIR=/usr/local/include
export _PKG_DIR=/usr/local/lib

export BUILD_IMAGE_ENV="PYTHON_VERSION"
export BUILD_IMAGE_ENV_FILE=image/python/python.env

export BUILD_IMAGE_CONTEXT=package/python

build_single() {
	[ -n "$1" ] || return 0

	export PYTHON_VERSION="$1"

	export PYTHON_BASE_VERSION=$(printf '%s' "${PYTHON_VERSION}" | cut -d. -f1-2)

	stem="python-${PYTHON_BASE_VERSION}"

	export BUILD_IMAGE_VOLUMES="
		$(build_artifacts_volumes "${stem}" "${DEB_SRC_BUILD_DIR}" "${_SRC_DIR}" "${_PKG_DIR}")
	"

	set -e

	BUILD_IMAGE_TARGET=minimal \
	scripts/build-image.sh image/python/ \
	"${IMAGE_PATH}/python-min:${PYTHON_VERSION}-${SUITE}" ":${PYTHON_BASE_VERSION}-${SUITE}"

	BUILD_IMAGE_TARGET=regular \
	scripts/build-image.sh image/python/ \
	"${IMAGE_PATH}/python:${PYTHON_VERSION}-${SUITE}" ":${PYTHON_BASE_VERSION}-${SUITE}"

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
