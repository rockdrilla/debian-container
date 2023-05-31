#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2022-2023, Konstantin Demin

set -ef

arg0="${0##*/}"

have_cmd() { command -v "$1" >/dev/null 2>&1 ; }
git_ro() { GIT_OPTIONAL_LOCKS=0 command git "$@"; }

process_file_sh_style() {
	sed -E -e '/^\s*(#|$)/d' "$@"
}

usage() {
	cat >&2 <<-EOF
		Usage: ${arg0} <git ref start> <git ref end> [<filter file>|<filter stanza> [.. <filter stanza>]]
	EOF
	exit 1
}

have_cmd git || exit 1

if [ $# -lt 2 ] ; then
	usage
fi

ref_start="${1:?}"
ref_end="${2:?}"
shift 2

# bare run - to test refs
git_ro diff-tree -z --name-only -r "${ref_end}" "${ref_start}" >/dev/null

changes_git=$(mktemp)
: "${changes_git:?}"

git_root=$(git_ro rev-parse --show-toplevel)
git_pfx=$(git_ro rev-parse --show-prefix)
if [ -n "${git_pfx}" ] ; then
	git_pfx_re='^'$(glob2re.sh "${git_pfx}")
fi

# special magic with separator for sed "s" command
# char 027 (0x17) seems to be safe separator for sed "s" command;
# idea taken from Debian src:nginx/debian/dh_nginx
xsedx=$(env printf '\027')
sed_match() { printf '%s' "\\${xsedx}$1${xsedx}" ; }
sed_s() { printf '%s' "s${xsedx}$1${xsedx}$2${xsedx}" ; }

# no error checking section
set +e

git_ro diff-tree -z --name-only -r \
	"${ref_end}" "${ref_start}" \
| xargs -0 -r -I {} \
	find "${git_root}" -follow \
	\( -samefile "${git_root}/{}" -type f -printf '%P\0' \) \
	\, \
	\( -path "${git_root}/{}/" -type f -printf '%P\0' \) \
	2>/dev/null \
| sort -zuV \
> "${changes_git}"

# end of "no error checking section"
set -e

if ! [ -s "${changes_git}" ] ; then
	rm -f "${changes_git}"
	exit 1
fi

changes_list=$(mktemp)
: "${changes_list:?}"

if [ -n "${git_pfx}" ] ; then
	sed -Enz -e "$(sed_match "${git_pfx_re}"){$(sed_s "${git_pfx_re}")p}"
else
	cat
fi < "${changes_git}" > "${changes_list}"

if [ $# -eq 0 ] ; then
	xargs -0 -r -a "${changes_list}" printf '%s\n'

	rm -f "${changes_git}" "${changes_list}"
	exit 0
fi

# swap!
cat < "${changes_list}" > "${changes_git}"
: > "${changes_list}"

filt_file=$(mktemp)
: "${filt_file:?}"

if [ $# = 1 ] && [ -s "$1" ] ; then
	process_file_sh_style "$1"
else
	printf '%s\n' "$@"
fi > "${filt_file}"

if [ -s "${filt_file}" ] ; then
	while read -r filt_line ; do
		[ -n "${filt_line}" ] || continue

		filt_mode=include
		case "${filt_line}" in
		!* )
			filt_mode=exclude
			filt_line="${filt_line#!}"
			[ -n "${filt_line}" ] || continue
		;;
		esac

		filt_re='^'$(glob2re.sh "${filt_line}")'$'

		case "${filt_mode}" in
		include)
			grep -zE -e "${filt_re}" < "${changes_git}" >> "${changes_list}" || :
		;;
		exclude)
			if [ -s "${changes_list}" ] ; then
				sed -i -Enz -e "$(sed_match "${filt_re}")d" "${changes_list}"
			else
				grep -zEv -e "${filt_re}" < "${changes_git}" >> "${changes_list}" || :
			fi
		;;
		esac
	done < "${filt_file}"
fi

rm -f "${changes_git}" "${filt_file}"

xargs -0 -r -a "${changes_list}" printf '%s\n'

rm -f "${changes_list}"
exit 0
