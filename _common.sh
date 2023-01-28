#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -f

SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(date -u '+%s')}"
BUILD_IMAGE_ARGS="${BUILD_IMAGE_ARGS:-IMAGE_REGISTRY IMAGE_DIRECTORY DISTRO SUITE}"
BUILD_IMAGE_PUSH="${BUILD_IMAGE_PUSH:-0}"
export SOURCE_DATE_EPOCH BUILD_IMAGE_ARGS BUILD_IMAGE_PUSH

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
	"${rootdir:?}/scripts/build-image.sh" /bin/true "$@"
}

build_artifacts_path() {
	printf '%s' "${rootdir:?}/build-artifacts/${DISTRO:?}-${SUITE:?}-${1:?}"
}

# NB: "/build" isn't actually a final artefact directory
build_artifacts_volumes() {
	mkdir -p \
		"$(build_artifacts_path "$1")/build" \
		"$(build_artifacts_path "$1")/src" \
		"$(build_artifacts_path "$1")/pkg" \
	>&2 || exit 1
	printf ' %s ' \
		"$(build_artifacts_path "$1")/build:$2" \
		"$(build_artifacts_path "$1")/src:$3" \
		"$(build_artifacts_path "$1")/pkg:$4" \

}

build_cache_path() {
	printf '%s' "${rootdir:?}/build-cache/${DISTRO:?}-${SUITE:?}"
}

build_cache_volumes() {
	mkdir -p \
		"$(build_cache_path)/apt-cache" \
		"$(build_cache_path)/apt-lists" \
	>&2 || exit 1
	printf ' %s ' \
		"$(build_cache_path)/apt-cache:/var/cache/apt/archives" \
		"$(build_cache_path)/apt-lists:/var/lib/apt/lists" \

}

shared_cache_path() {
	mkdir -p \
		"${rootdir:?}/build-cache/${1:?}" \
	>&2 || exit 1
	printf '%s' "${rootdir}/build-cache/$1"
}

dst_list='
	debian:bullseye:11:stable:latest
	debian:bookworm:12
	debian:sid
	ubuntu:focal:20.04:lts
	ubuntu:jammy:22.04:stable:latest
'