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
. "${rootdir}/image/ansible-mini/common.envsh"

build_single() {
	[ -n "$1" ] || return 0

	export ANSIBLE_VERSION="$1"

	export BUILD_IMAGE_ENV="ANSIBLE_VERSION"

	export BUILD_IMAGE_VOLUMES="
		$(ci_apt_volumes)
		$(ci_python_volumes)
	"

	image="${IMAGE_PATH}/ansible-mini:${ANSIBLE_VERSION}-${SUITE}${IMAGE_TAG_SUFFIX}"

	extra_tags=":${ANSIBLE_VERSION}-${SUITE}"
	[ -z "${IMAGE_TAG_SUFFIX}" ] || extra_tags=

	set -e

	build-image.sh image/ansible-mini/ "${image}" ${extra_tags}

	set +e

}

if [ $# = 0 ] ; then
	for ver in ${ansible_versions} ; do
		build_single "${ver}"
	done
else
	for ver ; do
		build_single "${ver}"
	done
fi
