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

for distro_suite_tags in ${dst_list} ; do
	extra_tags=
	IFS=: read -r DISTRO SUITE extra_tags <<-EOF
	${distro_suite_tags}
	EOF
	[ -z "${extra_tags}" ] || extra_tags=$(echo ":${extra_tags}" | sed -e 's/:/ :/g')

	export DISTRO SUITE

	export BUILD_IMAGE_VOLUMES="$(build_cache_volumes)"

	scripts/build-image.sh image/standard/ \
	  "${IMAGE_PATH}/${DISTRO}:${SUITE}" \
	  ${extra_tags}
done
