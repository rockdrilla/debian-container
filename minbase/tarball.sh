#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -ef

distro="${1:?}"
suite="${2:?}"
tarball="$3"

dir0=$(readlink -f "$(dirname "$0")")

ts=
. "${dir0}/_common.sh"

# mmdebstrap companion script
: "${TARFILTER:-tarfilter}"
if ! command -v "${TARFILTER%% *}" >/dev/null ; then
	# try Debian one
	TARFILTER='mmtarfilter'
	command -v "${TARFILTER%% *}" >/dev/null
fi

# HACK: we need 'shared' /tmp not per-user one :)
# only affects installations with "libpam-tmpdir" installed
orig_tmp="${TMPDIR:-/tmp}"
export TMPDIR=/tmp TEMPDIR=/tmp TMP=/tmp TEMP=/tmp

if [ "${distro}" = ubuntu ] ; then
	# HACK: substitute dpkg-deb with own wrapper
	# ref: https://gitlab.mister-muffin.de/josch/mmdebstrap/issues/31
	# TODO: review and remove near 2025
	export PATH="${dir0}/setup:${PATH}"
fi

uid=$(ps -n -o euid= -p $$)
gid=$(ps -n -o egid= -p $$)

case "${distro}" in
debian) comps='main,contrib,non-free' ;;
ubuntu) comps='main,restricted,universe,multiverse' ;;
esac

tarball_tmp=$(mktemp -u)'.tar'

mmdebstrap \
  --format=tar \
  --variant=apt \
  --components="${comps}" \
  --aptopt="${dir0}/setup/apt.conf" \
  --dpkgopt="${dir0}/setup/dpkg.cfg" \
  --customize-hook="'${dir0}/setup/mmdebstrap-hook.sh' \"\$1\" ${distro} ${suite} ${uid} ${gid}" \
  "${suite}" "${tarball_tmp}" || true

# test tarball
if ! tar -tf "${tarball_tmp}" >/dev/null ; then
	rm -f "${tarball_tmp}"
	exit 1
fi

# restore $TMPDIR
if [ -n "${orig_tmp}" ] ; then
	export TMP="${orig_tmp}"
	export TMPDIR="${TMP}" TEMPDIR="${TMP}" TEMP="${TMP}"
fi

# filter out tarball
tarball_new=$(mktemp)
${TARFILTER} \
	--path-exclude='/dev/*' \
	--path-exclude='/proc/*' \
	--path-exclude='/sys/*' \
< "${tarball_tmp}" \
> "${tarball_new}"

# test new tarball
if ! tar -tf "${tarball_new}" >/dev/null ; then
	rm -f "${tarball_tmp}" "${tarball_new}"
	exit 1
fi

rm -f "${tarball_tmp}"
unset tarball_tmp

touch -m -d "@${ts}" "${tarball_new}"

if [ -n "${tarball}" ] ; then
	[ -w "${tarball}" ] || touch "${tarball}"

	cat < "${tarball_new}" > "${tarball}"
	rm -f "${tarball_new}"
	touch -m -d "@${ts}" "${tarball}"
else
	echo "${tarball_new}"
fi
