#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -f

# the one may want to set this:
# : "${BUILDAH_FORMAT:=docker}"
# export BUILDAH_FORMAT

dir0=$(readlink -e "$(dirname "$0")")
cd "${dir0:?}" || exit

export PATH="${dir0}/scripts:${PATH}"

SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(date -u '+%s')}
BUILD_IMAGE_PUSH=${BUILD_IMAGE_PUSH:-0}
export SOURCE_DATE_EPOCH BUILD_IMAGE_PUSH

# set by env, e.g.:
#   export IMAGE_REGISTRY='docker.io'
#   export IMAGE_DIRECTORY='rockdrilla'
IMAGE_PATH="${IMAGE_REGISTRY:?}/${IMAGE_DIRECTORY:?}"

# NB: assume that we're already logged in registry

stub_build() {
	BUILD_IMAGE_SCRIPT_CUSTOM=1 \
	BUILD_IMAGE_BASE=0 \
	BUILD_IMAGE_SCRIPT_PRE=/bin/true \
	BUILD_IMAGE_SCRIPT_POST=/bin/true \
	scripts/build-image.sh /bin/true "$@"
}

dst_list='
	debian:bullseye:11:stable:latest
	debian:bookworm:12
	debian:sid
	ubuntu:focal:20.04:lts
	ubuntu:jammy:22.04:stable:latest
'

for distro_suite_tags in ${dst_list} ; do
	extra_tags=
	IFS=: read -r DISTRO SUITE extra_tags <<-EOF
	${distro_suite_tags}
	EOF
	if [ -n "${extra_tags}" ] ; then
		extra_tags=$(echo ":${extra_tags}" | sed -e 's/:/ :/g')
	fi

	image="${IMAGE_PATH}/${DISTRO}-min:${SUITE}"
	image-minbase/image.sh ${DISTRO} ${SUITE} "${image}"
	stub_build "${image}" ${extra_tags}
done

export BUILD_IMAGE_ARGS='IMAGE_REGISTRY IMAGE_DIRECTORY DISTRO SUITE'

for distro_suite_tags in ${dst_list} ; do
	extra_tags=
	IFS=: read -r DISTRO SUITE extra_tags <<-EOF
	${distro_suite_tags}
	EOF
	if [ -n "${extra_tags}" ] ; then
		extra_tags=$(echo ":${extra_tags}" | sed -e 's/:/ :/g')
	fi

	export DISTRO SUITE

	scripts/build-image.sh image-standard/ \
	  "${IMAGE_PATH}/${DISTRO}:${SUITE}" \
	  ${extra_tags}

done

export BUILD_IMAGE_ARGS="${BUILD_IMAGE_ARGS} BASE_IMAGE"

for distro_suite_tags in ${dst_list} ; do
	extra_tags=
	IFS=: read -r DISTRO SUITE extra_tags <<-EOF
	${distro_suite_tags}
	EOF
	if [ -n "${extra_tags}" ] ; then
		extra_tags=$(echo ":${extra_tags}" | sed -e 's/:/ :/g')
	fi

	export DISTRO SUITE

	scripts/build-image.sh image-buildd/ \
	  "${IMAGE_PATH}/${DISTRO}-buildd:${SUITE}" \
	  ${extra_tags}

done
