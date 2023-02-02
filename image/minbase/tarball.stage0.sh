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

case "${distro}" in
debian) comps='main contrib non-free' ;;
ubuntu) comps='main restricted universe multiverse' ;;
esac

sources_tmp=
if [ -n "${MMDEBSTRAP_MIRROR}" ] ; then
	case "${distro}" in
	debian)
		case "${suite}" in
		unstable|sid) ;;
		*)
			# if MMDEBSTRAP_MIRROR is set then MMDEBSTRAP_SECMIRROR must be set too
			: "${MMDEBSTRAP_SECMIRROR:?}"
		;;
		esac
	;;
	esac

	sources_tmp=$(mktemp) ; : "${sources_tmp:?}"
	case "${distro}" in
	debian)
		: "${MMDEBSTRAP_KEYRING:=/usr/share/keyrings/debian-archive-keyring.gpg}"
		case "${suite}" in
		unstable|sid)
			cat <<-EOF
			deb [signed-by="${MMDEBSTRAP_KEYRING}"] ${MMDEBSTRAP_MIRROR} ${suite} ${comps}
			EOF
		;;
		*)
			cat <<-EOF
			deb [signed-by="${MMDEBSTRAP_KEYRING}"] ${MMDEBSTRAP_MIRROR} ${suite} ${comps}
			deb [signed-by="${MMDEBSTRAP_KEYRING}"] ${MMDEBSTRAP_MIRROR} ${suite}-updates ${comps}
			deb [signed-by="${MMDEBSTRAP_KEYRING}"] ${MMDEBSTRAP_MIRROR} ${suite}-proposed-updates ${comps}
			deb [signed-by="${MMDEBSTRAP_KEYRING}"] ${MMDEBSTRAP_SECMIRROR} ${suite}-security ${comps}
			EOF
		;;
		esac
	;;
	ubuntu)
		: "${MMDEBSTRAP_KEYRING:=/usr/share/keyrings/ubuntu-archive-keyring.gpg}"
		cat <<-EOF
		deb [signed-by="${MMDEBSTRAP_KEYRING}"] ${MMDEBSTRAP_MIRROR} ${suite} ${comps}
		deb [signed-by="${MMDEBSTRAP_KEYRING}"] ${MMDEBSTRAP_MIRROR} ${suite}-updates ${comps}
		deb [signed-by="${MMDEBSTRAP_KEYRING}"] ${MMDEBSTRAP_MIRROR} ${suite}-proposed ${comps}
		deb [signed-by="${MMDEBSTRAP_KEYRING}"] ${MMDEBSTRAP_MIRROR} ${suite}-security ${comps}
		EOF
	;;
	esac > "${sources_tmp}"
fi

tarball_tmp=$(mktemp -u)'.tar'

set +e
mmdebstrap \
  --format=tar \
  --variant=apt \
  --components="${comps}" \
  --aptopt="${dir0}/setup/apt.conf" \
  --dpkgopt="${dir0}/setup/dpkg.cfg" \
  ${have_preseed:+ --customize-hook='chroot "$1" mkdir -p /usr/local/preseed' } \
  ${have_preseed:+ --customize-hook="sync-in '${rootdir}/preseed' /usr/local/preseed" } \
  --customize-hook="'${dir0}/setup/mmdebstrap-hook.stage0.sh' \"\$1\" ${distro} ${suite} ${uid} ${gid}" \
  --skip=cleanup/apt \
  --skip=cleanup/tmp \
  --skip=cleanup/run \
  "${suite}" "${tarball_tmp}" \
  ${sources_tmp:+ - } <<-EOF
$(test -z "${sources_tmp}" || cat "${sources_tmp}")
EOF
set -e

if [ -n "${sources_tmp}" ] ; then
	rm -f "${sources_tmp}"
	unset sources_tmp
fi

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
