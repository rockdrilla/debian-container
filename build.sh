#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -f

# the one may want to set this:
# : "${BUILDAH_FORMAT:=docker}"
# export BUILDAH_FORMAT

dir0=$(readlink -f "$(dirname "$0")")

SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(date -u '+%s')}
export SOURCE_DATE_EPOCH

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
	"${dir0}/scripts/build-image.sh" /bin/true "$@"
}

for distro_suite in \
	debian:bullseye:11:stable:latest debian:bookworm:12 debian:sid \
	ubuntu:focal:20.04:lts ubuntu:jammy:22.04:stable:latest \
; do
	IFS=: read -r distro suite extra_tags <<-EOF
	${distro_suite}
	EOF
	if [ -n "${extra_tags}" ] ; then
		extra_tags=$(echo ":${extra_tags}" | sed -e 's/:/ :/g')
	fi

	image="${IMAGE_PATH}/${distro}-min:${suite}"
	"${dir0}/minbase/image.sh" ${distro} ${suite} "${image}"
	stub_build "${image}" ${extra_tags}

	(
		export BUILD_IMAGE_ARGS='IMAGE_REGISTRY IMAGE_DIRECTORY DISTRO SUITE'
		export DISTRO="${distro}"
		export SUITE="${suite}"

		"${dir0}/scripts/build-image.sh" \
		  "${dir0}/standard" \
		  "${IMAGE_PATH}/${distro}:${suite}" \
		  ${extra_tags}
	)

done
