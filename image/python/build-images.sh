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
. "${rootdir}/image/python/common.envsh"

export BUILD_IMAGE_ARGS="${BUILD_IMAGE_ARGS}
	PYTHON_MIN_IMAGE
"

build_single() {
	[ -n "$1" ] || return 0

	export PYTHON_VERSION="$1"
	export PYTHON_BASE_VERSION=$(printf '%s' "${PYTHON_VERSION}" | cut -d. -f1-2)

	export BUILD_IMAGE_ENV="PYTHON_VERSION PYTHON_BASE_VERSION"

	stem="python-${PYTHON_BASE_VERSION}"

	packages="$(build_artifacts_path "${stem}/pkg")"
	export BUILD_IMAGE_CONTEXTS="
		packages=${packages}
	"

	export PYTHON_MIN_IMAGE="python-min:${PYTHON_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"
	full_image="${IMAGE_PATH}/python:${PYTHON_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"

	extra_tags=":${PYTHON_BASE_VERSION}-${SUITE}"
	[ -z "${IMAGE_TAG_SUFFIX}" ] || extra_tags=

	set -e

	BUILD_IMAGE_TARGET="minimal${APT_REPO_PREFIX:+-apt}" \
	scripts/build-image.sh image/python/ "${IMAGE_PATH}/${PYTHON_MIN_IMAGE}" ${extra_tags}

	# "python" derives env from "python-min"
	unset BUILD_IMAGE_ENV

	BUILD_IMAGE_TARGET="regular${APT_REPO_PREFIX:+-apt}" \
	scripts/build-image.sh image/python/ "${full_image}" ${extra_tags}

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
