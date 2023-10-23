#!/bin/sh
set -ef

nproc=$(nproc)
[ -z "$1" ] || nproc="$1"
nproc=$(( nproc + 0 ))

# all "memory" numbers are in MiB

min=1024
max=6144

reserve=1024
limit=$(mawk '/^MemTotal:/ {print $2}' /proc/meminfo) || exit 0
limit=$(( limit / 1024 ))

f=/sys/fs/cgroup/memory.max
if [ -e "$f" ] ; then
	_limit=$(cat "$f") || :
	[ -n "${_limit}" ] || _limit=max
	case "${_limit}" in
	max ) ;;
	[1-9]* )
		limit=$(( _limit / 1048576 ))
		reserve=256
	;;
	esac
fi

threshold=$(( min + reserve ))
[ "${limit}" -ge "${threshold}" ] || exit 0
limit=$(( limit - reserve ))

parallel_limit=$(( limit / nproc ))

[ "${limit}" -le "${max}" ] || limit=${max}

[ "${parallel_limit}" -le "${max}" ] || parallel_limit=${max}
[ "${parallel_limit}" -ge "${min}" ] || parallel_limit=

output_limits() {
	for i ; do
		[ -n "$i" ] || continue
		printf '%s=%s ' '--memlimit' "${i}m"
	done
	echo
}

output_limits ${limit} ${parallel_limit}
