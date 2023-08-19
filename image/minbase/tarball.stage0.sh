#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2021-2023, Konstantin Demin

set -ef

distro="${1:?}"
suite="${2:?}"
tarball="$3"

dir0=$(readlink -f "$(dirname "$0")")
rootdir=$(readlink -e "${dir0}/../..")

ts=
. "${dir0}/common.envsh"

# mmdebstrap companion script
: "${TARFILTER:=tarfilter}"
if ! command -v "${TARFILTER%% *}" >/dev/null ; then
	# try Debian one
	TARFILTER='mmtarfilter'
	command -v "${TARFILTER%% *}" >/dev/null
fi

# HACK: we need 'shared' /tmp not per-user one :)
# only affects installations with "libpam-tmpdir" installed
orig_tmp="${TMPDIR:-/tmp}"
export TMPDIR=/tmp TEMPDIR=/tmp TMP=/tmp TEMP=/tmp

have_preseed=
if [ -d "${rootdir}/preseed" ] ; then
	have_preseed=1
fi

if [ "${distro}" = ubuntu ] ; then
	# HACK: substitute dpkg-deb with own wrapper
	# ref: https://gitlab.mister-muffin.de/josch/mmdebstrap/issues/31
	# TODO: review and remove near 2025
	export PATH="${dir0}/setup:${PATH}"
fi

uid=$(ps -n -o euid= -p $$)
gid=$(ps -n -o egid= -p $$)

sources_tmp=$(mktemp) ; : "${sources_tmp:?}"
uri=
case "${distro}" in
debian)
	for u in "${MMDEBSTRAP_BUILD_MIRROR_DEBIAN}" "${MMDEBSTRAP_MIRROR_DEBIAN}" ; do
		[ -n "$u" ] || continue
		uri="$u"
		break
	done
;;
ubuntu)
	for u in "${MMDEBSTRAP_BUILD_MIRROR_UBUNTU}" "${MMDEBSTRAP_MIRROR_UBUNTU}" ; do
		[ -n "$u" ] || continue
		uri="$u"
		break
	done
;;
esac
[ -n "${uri}" ] || uri='default'

package/essentials/bin/apt-sources -p -d ${distro} -s ${suite} "${uri}" > "${sources_tmp}"

tarball_tmp=$(mktemp -u)'.tar'

set +e
mmdebstrap \
  --format=tar \
  --variant=apt \
  --include='ca-certificates-java,default-jre-headless' \
  --aptopt="${dir0}/setup/apt.conf" \
  --dpkgopt="${dir0}/setup/dpkg.cfg" \
  ${have_preseed:+ --customize-hook='chroot "$1" mkdir -p /usr/local/preseed' } \
  ${have_preseed:+ --customize-hook="sync-in '${rootdir}/preseed' /usr/local/preseed" } \
  --customize-hook="'${dir0}/setup/mmdebstrap-hook.stage0.sh' \"\$1\" ${distro} ${suite} ${uid} ${gid}" \
  --skip=cleanup/apt \
  --skip=cleanup/tmp \
  --skip=cleanup/run \
  "${suite}" "${tarball_tmp}" \
  - < "${sources_tmp}"
set -e

rm -f "${sources_tmp}"
unset sources_tmp

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
	--path-exclude='/tmp/*' \
	--path-exclude='/run/lock/*' \
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
