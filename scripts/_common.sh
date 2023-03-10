#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -f

: "${SOURCE_DATE_EPOCH:=$(date -u '+%s')}"
: "${BUILD_IMAGE_ARGS:=IMAGE_PATH DISTRO SUITE}"
: "${BUILD_IMAGE_PUSH:=0}"
export SOURCE_DATE_EPOCH BUILD_IMAGE_ARGS BUILD_IMAGE_PUSH

# NB: assume that we're already logged in registry

stub_build() {
	BUILD_IMAGE_SCRIPT_CUSTOM=1 \
	BUILD_IMAGE_BASE=0 \
	BUILD_IMAGE_SCRIPT_PRE=/bin/true \
	BUILD_IMAGE_SCRIPT_POST=/bin/true \
	"${rootdir:?}/scripts/build-image.sh" /bin/true "$@"
}

_build_artifacts_path() {
	printf '%s' "${rootdir:?}/build-artifacts/${DISTRO:?}-${SUITE:?}-${1:?}"
}

build_artifacts_path() {
	mkdir -p "$(_build_artifacts_path "$@")" >&2 || exit 1
	_build_artifacts_path "$@"
}

# NB: "/build" isn't actually a final artefact directory
build_artifacts_volumes() {
	printf ' %s ' \
		"$(build_artifacts_path "$1/build"):$2" \
		"$(build_artifacts_path "$1/src"):$3" \
		"$(build_artifacts_path "$1/pkg"):$4" \

}

default_D_S_T='
	debian:bullseye:11:stable:latest
	debian:bookworm:12:testing
	debian:sid:unstable
	ubuntu:focal:20.04:lts
	ubuntu:jammy:22.04:stable:latest
'

if [ -z "${DISTRO_SUITE_TAGS}" ] ; then
DISTRO_SUITE_TAGS="${default_D_S_T}"
fi

set_default_distro_suite() {
	[ -n "${DISTRO}" ] || export DISTRO=debian

	[ -z "${SUITE}" ] || return 0

	for _d_s_t in ${default_D_S_T} ; do
		case "${_d_s_t}" in
		${DISTRO}:*:stable*) ;;
		*) continue ;;
		esac

		IFS=: read -r _distro SUITE _tags <<-EOF
		${_d_s_t}
		EOF

		export SUITE
		break
	done
	unset _d_s_t _distro _tags
}
