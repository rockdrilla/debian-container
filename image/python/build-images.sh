#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -f

# the one may want to set this:
# : "${BUILDAH_FORMAT:=docker}"
# export BUILDAH_FORMAT

rootdir=$(readlink -e "$(dirname "$0")/../..")
cd "${rootdir:?}" || exit

. "${rootdir}/.ci/common.envsh"
. "${rootdir}/image/python/common.envsh"

export BUILD_IMAGE_ARGS="${BUILD_IMAGE_ARGS}
	PYTHON_MIN_IMAGE
	PYTHON_IMAGE
"

build_single() {
	[ -n "$1" ] || return 0

	export PYTHON_VERSION="$1"
	export PYTHON_BASE_VERSION=$(printf '%s' "${PYTHON_VERSION}" | cut -d. -f1-2)

	stem="python-${PYTHON_BASE_VERSION}"

	if [ -z "${CI}" ] ; then
		packages="$(build_artifacts_path "${stem}/pkg")"
		export BUILD_IMAGE_CONTEXTS="
			packages=${packages}
		"
	fi

	export BUILD_IMAGE_VOLUMES="
		$(ci_apt_volumes)
	"

	export PYTHON_MIN_IMAGE="python-min:${PYTHON_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"
	export PYTHON_IMAGE="python:${PYTHON_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"
	export PYTHON_DEV_IMAGE="python-dev:${PYTHON_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"

	extra_tags=":${PYTHON_BASE_VERSION}-${SUITE}"
	[ -z "${IMAGE_TAG_SUFFIX}" ] || extra_tags=

	set -e

	if [ -z "${CI}" ] ; then
		PYTHON_PKG_IMAGE="python-pkg:${PYTHON_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"

		BUILD_IMAGE_TARGET="pkg" \
		build-image.sh image/python/ "${IMAGE_PATH}/${PYTHON_PKG_IMAGE}"
	fi

	BUILD_IMAGE_TARGET="minimal${CI:+-ci}" \
	BUILD_IMAGE_ENV="PYTHON_VERSION PYTHON_BASE_VERSION" \
	build-image.sh image/python/ "${IMAGE_PATH}/${PYTHON_MIN_IMAGE}" ${extra_tags}

	# wait for image registry
	sleep 10

	# "python" derives env from "python-min"

	BUILD_IMAGE_TARGET="regular${CI:+-ci}" \
	build-image.sh image/python/ "${IMAGE_PATH}/${PYTHON_IMAGE}" ${extra_tags}

	# wait for image registry
	sleep 10

	# "python-dev" derives env from "python"

	BUILD_IMAGE_TARGET="dev${CI:+-ci}" \
	build-image.sh image/python/ "${IMAGE_PATH}/${PYTHON_DEV_IMAGE}" ${extra_tags}

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
