#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2023, Konstantin Demin

set -f

# the one may want to set this:
# : "${BUILDAH_FORMAT:=docker}"
# export BUILDAH_FORMAT

rootdir=$(readlink -e "$(dirname "$0")/../..")
cd "${rootdir:?}" || exit

export PATH="${rootdir}/scripts:${PATH}"

. "${rootdir}/scripts/_common.sh"
. "${rootdir}/image/nodejs/common.envsh"

export BUILD_IMAGE_ARGS="${BUILD_IMAGE_ARGS}
	NODEJS_MAJOR_VERSION
	NODEJS_MIN_IMAGE
"

build_single() {
	[ -n "$1" ] || return 0

	export NODEJS_VERSION="$1"
	export NODEJS_MAJOR_VERSION=$(printf '%s' "${NODEJS_VERSION}" | cut -d. -f1)

	export BUILD_IMAGE_ENV="NODEJS_VERSION NODEJS_MAJOR_VERSION"

	stem="nodejs-${NODEJS_MAJOR_VERSION}"

	packages="$(build_artifacts_path "${stem}/pkg")"
	export BUILD_IMAGE_CONTEXTS="
		packages=${packages}
	"

	export NODEJS_MIN_IMAGE="nodejs-min:${NODEJS_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"
	full_image="${IMAGE_PATH}/nodejs:${NODEJS_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"

	extra_tags=":${NODEJS_MAJOR_VERSION}-${SUITE}"
	[ -z "${IMAGE_TAG_SUFFIX}" ] || extra_tags=

	set -e

	BUILD_IMAGE_TARGET="minimal${APT_REPO_PREFIX:+-apt}" \
	scripts/build-image.sh image/nodejs/ "${IMAGE_PATH}/${NODEJS_MIN_IMAGE}" ${extra_tags}

	# "nodejs" derives env from "nodejs-min"
	unset BUILD_IMAGE_ENV

	BUILD_IMAGE_TARGET="regular${APT_REPO_PREFIX:+-apt}" \
	scripts/build-image.sh image/nodejs/ "${full_image}" ${extra_tags}

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
