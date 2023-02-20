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

build_single() {
	[ -n "$1" ] || continue

	export PYTHON_VERSION="$1"

	export PYTHON_BASE_VERSION=$(printf '%s' "${PYTHON_VERSION}" | cut -d. -f1-2)

	stem="python-${PYTHON_BASE_VERSION}"

	export BUILD_IMAGE_VOLUMES="$(build_cache_volumes)
		$(build_artifacts_volumes "${stem}" "${DEB_SRC_BUILD_DIR}" "${_SRC_DIR}" "${_PKG_DIR}")
	"

	preseed=$(shared_cache_path "${stem}")
	: > "${preseed}/placeholder"

#	: "${GET_PIP_URL:=https://github.com/pypa/get-pip/raw/22.3.1/public/get-pip.py}"
#	: "${GET_PIP_SHA256:=1e501cf004eac1b7eb1f97266d28f995ae835d30250bec7f8850562703067dc6}"
#	if ! [ -s "${preseed}/get-pip.py" ] ; then
#		curl -sSL -o "${preseed}/get-pip.py" "${GET_PIP_URL}"
#	fi
#	echo "${GET_PIP_SHA256} *${preseed}/get-pip.py" | sha256sum -c - || exit 1

	export BUILD_IMAGE_CONTEXTS="
		preseed=${preseed}
	"

	set -e

	BUILD_IMAGE_TARGET=minimal \
	scripts/build-image.sh image/python/ \
	"${IMAGE_PATH}/python-min:${PYTHON_VERSION}-${SUITE}" ":${PYTHON_BASE_VERSION}-${SUITE}"

	set +e

	# share preseed with next builds
	(
		cd "$(build_artifacts_path "${stem}")/src" || exit 1
		find ./ -name '*.orig.*'   -type f -exec cp -nv -t "${preseed}" '{}' '+'
		find ./ -name '*.orig-*.*' -type f -exec cp -nv -t "${preseed}" '{}' '+'
	)

	set -e

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
