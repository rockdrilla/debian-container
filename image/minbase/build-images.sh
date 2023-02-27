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

. "${rootdir}/scripts/_common.sh"

# stage 0: build with Debian testing (!)
for d_s_t in ${DISTRO_SUITE_TAGS} ; do

	case "${d_s_t}" in
	debian:*:testing*) ;;
	*) continue ;;
	esac

	tags=
	IFS=: read -r DISTRO SUITE tags <<-EOF
	${d_s_t}
	EOF

	# for latter usage
	export DISTRO SUITE

	image/minbase/image.stage0.sh ${DISTRO} ${SUITE} "${IMAGE_PATH}/${DISTRO}-min-stage0:${SUITE}"
done

# stage 1: build "arch:all" packages with Debian testing (!)
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
	rm -rf "$(build_artifacts_path "${stem}")"

	export BUILD_IMAGE_VOLUMES="
		$(build_artifacts_volumes "${stem}" "${DEB_SRC_BUILD_DIR}" "${_SRC_DIR}" "${_PKG_DIR}")
	"

	# (our CI uploads freshly built packages via ${BUILD_IMAGE_SCRIPT_POST})
	BUILD_IMAGE_SCRIPT_POST=/bin/true \
	scripts/build-image.sh image/minbase/Dockerfile.stage1 "${IMAGE_PATH}/${DISTRO}-min-stage1:${SUITE}"

	pkg_path="${rootdir}/build-artifacts/${stem}"
	rm -rf "${pkg_path}"
	mkdir -p "${pkg_path}"
	find "$(build_artifacts_path "${stem}")/pkg/" -type f -name '*.deb' -execdir mv -vt "${pkg_path}" '{}' '+'
) || exit 1

# remove intermediate images
podman image rm -f "${IMAGE_PATH}/${DISTRO}-min-stage0:${SUITE}"
podman image rm -f "${IMAGE_PATH}/${DISTRO}-min-stage1:${SUITE}"

# suppress building dbgsym packages
export DEB_BUILD_OPTIONS='noautodbgsym'

# stages 2 and 3: build semi-final images and then build against it 'arch:any' packages
for d_s_t in ${DISTRO_SUITE_TAGS} ; do
	tags=
	IFS=: read -r DISTRO SUITE tags <<-EOF
	${d_s_t}
	EOF

	export DISTRO SUITE

	# stage 2: build images suitable for building arch-any packages
	image/minbase/image.sh ${DISTRO} ${SUITE} "${IMAGE_PATH}/${DISTRO}-min-stage2:${SUITE}"

	# stage 3: build "arch:any" packages
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

		stem="container-packages-arch"
		rm -rf "$(build_artifacts_path "${stem}")"

		export BUILD_IMAGE_VOLUMES="
			$(build_artifacts_volumes "${stem}" "${DEB_SRC_BUILD_DIR}" "${_SRC_DIR}" "${_PKG_DIR}")
		"

		scripts/build-image.sh image/minbase/Dockerfile.stage3 "${IMAGE_PATH}/${DISTRO}-min-stage3:${SUITE}"
	) || exit 1

	# remove intermediate images
	podman image rm -f "${IMAGE_PATH}/${DISTRO}-min-stage2:${SUITE}"
	podman image rm -f "${IMAGE_PATH}/${DISTRO}-min-stage3:${SUITE}"
done

bootstrap_suite_packages="${rootdir}/build-artifacts/container-packages/arch"

# build final images
for d_s_t in ${DISTRO_SUITE_TAGS} ; do
	tags=
	IFS=: read -r DISTRO SUITE tags <<-EOF
	${d_s_t}
	EOF
	[ -z "${IMAGE_TAG_SUFFIX}" ] || tags=
	[ -z "${tags}" ] || tags=$(echo ":${tags}" | sed -e 's/:/ :/g')

	rm -rf "${bootstrap_suite_packages}"
	mkdir -p "${bootstrap_suite_packages}"

	find "$(build_artifacts_path container-packages-arch)/pkg/" -type f -name '*.deb' -execdir cp -vt "${bootstrap_suite_packages}" '{}' '+'

	image="${IMAGE_PATH}/${DISTRO}-min:${SUITE}${IMAGE_TAG_SUFFIX}"
	image/minbase/image.sh ${DISTRO} ${SUITE} "${image}"
	stub_build "${image}" ${tags}

	rm -rf "${bootstrap_suite_packages}"
done
