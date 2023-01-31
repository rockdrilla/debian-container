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

. "${rootdir}/_common.sh"

python_versions='
	3.9.16
	3.10.9
	3.11.1
'

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

export DEB_SRC_BUILD_DIR=/srv
export _SRC_DIR=/media
export _PKG_DIR=/mnt

for PYTHON_VERSION in ${python_versions} ; do
	export PYTHON_VERSION

	export PYTHON_BASE_VERSION=$(printf '%s' "${PYTHON_VERSION}" | cut -d. -f1-2)

	stem="python-${PYTHON_BASE_VERSION}"

	export BUILD_IMAGE_VOLUMES="$(build_cache_volumes)
		$(build_artifacts_volumes "${stem}" "${DEB_SRC_BUILD_DIR}" "${_SRC_DIR}" "${_PKG_DIR}")
	"

	export BUILD_IMAGE_CONTEXTS="
		tarballs=$(shared_cache_path "${stem}")
	"
	touch "$(shared_cache_path "${stem}")/placeholder"

	BUILD_IMAGE_TARGET=minimal \
	scripts/build-image.sh image/python/ \
	"${IMAGE_PATH}/python-min:${PYTHON_BASE_VERSION}-${SUITE}" ":${PYTHON_VERSION}-${SUITE}"

	# share tarballs with next builds
	(
		cd "$(build_artifacts_path "${stem}")/src" || exit 1
		dst="$(shared_cache_path "${stem}")"
		find ./ -name '*.orig.tar.*'   -type f -exec cp -nv -t "${dst}" '{}' '+'
		find ./ -name '*.orig-*.tar.*' -type f -exec cp -nv -t "${dst}" '{}' '+'
	)

	BUILD_IMAGE_TARGET=regular \
	scripts/build-image.sh image/python/ \
	"${IMAGE_PATH}/python:${PYTHON_BASE_VERSION}-${SUITE}" ":${PYTHON_VERSION}-${SUITE}"
done
