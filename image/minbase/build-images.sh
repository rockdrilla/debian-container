#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -ef

# the one may want to set this:
# : "${BUILDAH_FORMAT:=docker}"
# export BUILDAH_FORMAT

rootdir=$(readlink -e "$(dirname "$0")/../..")
cd "${rootdir:?}" || exit

export PATH="${rootdir}/scripts:${PATH}"

. "${rootdir}/_common.sh"

# stage 0: build with Debian testing (!)
for distro_suite_tags in ${dst_list} ; do

	case "${distro_suite_tags}" in
	debian:*:testing*) ;;
	*) continue ;;
	esac

	extra_tags=
	IFS=: read -r DISTRO SUITE extra_tags <<-EOF
	${distro_suite_tags}
	EOF
    [ -z "${extra_tags}" ] || extra_tags=$(echo ":${extra_tags}" | sed -e 's/:/ :/g')

	# for latter usage
	export DISTRO SUITE

	image="${IMAGE_PATH}/${DISTRO}-min-stage0:${SUITE}"

	image/minbase/image.stage0.sh ${DISTRO} ${SUITE} "${image}"

	BUILD_IMAGE_PUSH=0 \
	stub_build "${image}" ${extra_tags}
done

# stage 1/2: build with Debian testing (!)
(
	export BUILD_IMAGE_PUSH=0
	export BUILD_IMAGE_CONTEXT="${rootdir}"

	export BUILD_IMAGE_ARGS="
		${BUILD_IMAGE_ARGS}
		DEB_BUILD_OPTIONS
		DEB_SRC_BUILD_PURGE
		DEB_SRC_BUILD_DIR
		_SRC_DIR
		_PKG_DIR
	"

	export DEB_SRC_BUILD_DIR=/srv
	export _SRC_DIR=/media
	export _PKG_DIR=/mnt

	stem="container-packages"

	export BUILD_IMAGE_VOLUMES="$(build_cache_volumes)
		$(build_artifacts_volumes "${stem}" "${DEB_SRC_BUILD_DIR}" "${_SRC_DIR}" "${_PKG_DIR}")
	"

	scripts/build-image.sh image/minbase/Dockerfile.stage05 "${IMAGE_PATH}/${DISTRO}-min-stage05:${SUITE}"

	pkg_path="${rootdir}/build-artifacts/${stem}"
	mkdir -p "${pkg_path}"
	find "$(build_artifacts_path "${stem}")/pkg/" -type f -name '*.deb' -execdir mv -vt "${pkg_path}" '{}' '+'
)

# remove intermediate images
podman image rm -f "${IMAGE_PATH}/${DISTRO}-min-stage05:${SUITE}"
podman image rm -f "${IMAGE_PATH}/${DISTRO}-min-stage0:${SUITE}"

# build final images
for distro_suite_tags in ${dst_list} ; do
	extra_tags=
	IFS=: read -r DISTRO SUITE extra_tags <<-EOF
	${distro_suite_tags}
	EOF
    [ -z "${extra_tags}" ] || extra_tags=$(echo ":${extra_tags}" | sed -e 's/:/ :/g')

	image="${IMAGE_PATH}/${DISTRO}-min:${SUITE}"
	image/minbase/image.sh ${DISTRO} ${SUITE} "${image}"
	stub_build "${image}" ${extra_tags}
done
