#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2023, Konstantin Demin

set -f

# the one may want to set this:
# : "${BUILDAH_FORMAT:=docker}"
# export BUILDAH_FORMAT

rootdir=$(readlink -e "$(dirname "$0")/../..")
cd "${rootdir:?}" || exit

. "${rootdir}/.ci/common.envsh"
. "${rootdir}/image/nodejs/common.envsh"

export BUILD_IMAGE_ARGS="${BUILD_IMAGE_ARGS}
	NODEJS_MIN_IMAGE
	NODEJS_IMAGE
"

build_single() {
	[ -n "$1" ] || return 0

	export NODEJS_VERSION="$1"
	export NODEJS_MAJOR_VERSION=$(printf '%s' "${NODEJS_VERSION}" | cut -d. -f1)

	stem="nodejs-${NODEJS_MAJOR_VERSION}"

	if [ -z "${CI}" ] ; then
		packages="$(build_artifacts_path "${stem}/pkg")"
		export BUILD_IMAGE_CONTEXTS="
			packages=${packages}
		"
	fi

	export BUILD_IMAGE_VOLUMES="
		$(ci_apt_volumes)
	"

	export NODEJS_MIN_IMAGE="nodejs-min:${NODEJS_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"
	export NODEJS_IMAGE="nodejs:${NODEJS_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"
	export NODEJS_DEV_IMAGE="nodejs-dev:${NODEJS_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"

	extra_tags=":${NODEJS_MAJOR_VERSION}-${SUITE}"
	[ -z "${IMAGE_TAG_SUFFIX}" ] || extra_tags=

	set -e

	if [ -z "${CI}" ] ; then
		NODEJS_PKG_IMAGE="nodejs-pkg:${NODEJS_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"

		BUILD_IMAGE_TARGET="pkg" \
		build-image.sh image/nodejs/ "${IMAGE_PATH}/${NODEJS_PKG_IMAGE}"
	fi

	BUILD_IMAGE_TARGET="minimal${CI:+-ci}" \
	BUILD_IMAGE_ENVS="NODEJS_VERSION NODEJS_MAJOR_VERSION" \
	build-image.sh image/nodejs/ "${IMAGE_PATH}/${NODEJS_MIN_IMAGE}" ${extra_tags}

	# "nodejs" derives env from "nodejs-min"

	BUILD_IMAGE_PULL=0 \
	BUILD_IMAGE_TARGET="regular${CI:+-ci}" \
	build-image.sh image/nodejs/ "${IMAGE_PATH}/${NODEJS_IMAGE}" ${extra_tags}

	# "nodejs-dev" derives env from "nodejs"

	BUILD_IMAGE_PULL=0 \
	BUILD_IMAGE_TARGET="dev${CI:+-ci}" \
	build-image.sh image/nodejs/ "${IMAGE_PATH}/${NODEJS_DEV_IMAGE}" ${extra_tags}

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
