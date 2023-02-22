#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -f

# the one may want to set this:
# : "${BUILDAH_FORMAT:=docker}"
# export BUILDAH_FORMAT

rootdir=$(readlink -e "$(dirname "$0")")
cd "${rootdir:?}" || exit

export PATH="${rootdir}/scripts:${PATH}"

. ./scripts/_common.sh

image/minbase/build-images.sh

image/standard/build-images.sh

image/buildd/build-images.sh

image/golang/build-packages.sh
image/golang/build-images.sh

image/python/build-packages.sh
image/python/build-images.sh
