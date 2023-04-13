#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2023, Konstantin Demin

set -ef

shim_shlib='/@{NODEJS_PREFIX}/lib/libempty.so'
real_shlib='/@{NODEJS_PREFIX}/lib/libnode.so.@{NODEJS_API_VERSION}'

dest='/usr/lib/@{DEB_HOST_MULTIARCH}/libnode.so.@{NODEJS_API_VERSION}'

usage() {
	echo "# usage: ${0##*/} [shim|real|rm|status]" >&2
}

if [ $# = 0 ] ; then
	usage
	"$0" status
	exit
fi

case "$1" in
shim|real|rm|status)
	if [ -e "${dest}" ] ; then
		if ! [ -h "${dest}" ] ; then
			echo "${0##*/}: ${dest} is not a symbolic link" >&2
			exit 1
		fi
	fi
;;
esac

switch_to() {
	if ! [ -e "$1" ] ; then
		echo "# ${0##*/}: this package doesn't ship $1, quitting" >&2
		return "${2:-1}"
	fi
	if [ -e "${dest}" ] ; then
		rm "${dest}"
	fi
	ln -sv "$1" "${dest}"
}

status() {
	if [ -e "${dest}" ] ; then
		echo "# ${0##*/}: using $(readlink -e "${dest}") as ${dest}" >&2
	else
		echo "# ${0##*/}: ${dest} is missing" >&2
	fi
}

case "$1" in
rm)
	if [ -e "${dest}" ] ; then
		rm -v "${dest}"
	fi
;;
shim) switch_to "${shim_shlib}" ;;
real) switch_to "${real_shlib}" 0 ;;
status) status ;;
-h|--help) usage ;;
*)
	usage
	exit 1
;;
esac

exit 0
