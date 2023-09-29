#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2022-2023, Konstantin Demin

set -f

# normalize LD_PRELOAD:
# - normalize separators
# - strip k2env.so in middle/end of string (if any)
# - prepend k2env.so to beginning of string
reparse_ld_preload() {
	sed -zE 's/[ :]+/:/g;s/:k2env\.so(:|$)/:/g;s/^:*/k2env.so:/;s/:$//'
}

enforce_k2env_so() {
	_ld_preload="${LD_PRELOAD}"
	unset LD_PRELOAD
	set +e
	LD_PRELOAD=$(printf '%s' "${_ld_preload}" | reparse_ld_preload)
	export LD_PRELOAD
	unset _ld_preload
}

# enforce k2env.so to be in LD_PRELOAD
case "${LD_PRELOAD}" in
k2env.so | k2env.so:* ) ;;
* )
	enforce_k2env_so
	# re-execute self
	exec "$0" "$@"
;;
esac

unset __EP_SRC ; __EP_SRC="$0"

# preserve MALLOC_ARENA_MAX (if any)
EP_GLIBC_MALLOC_ARENAS=${MALLOC_ARENA_MAX:-2}
export MALLOC_ARENA_MAX=2

# common shell functions: begin

log_always() {
	echo "# $(date +'%Y-%m-%d %H:%M:%S.%03N %z'): ${__EP_SRC}${*:+: $*}" >&2
}
if [ "${EP_VERBOSE:-0}" = 1 ] ; then
	log() { log_always "$@" ; }
else
	log() { : ;}
fi

have_cmd() { command -v "$1" >/dev/null 2>&1 ; }

run_user_cmd() { ${EP_RUNAS:+run-as "${EP_RUNAS}"} "$@" ; }

# common shell functions: end

# PID1 handling
if [ "$$" = 1 ] ; then
	: "${EP_INIT:=1}"
fi
: "${EP_INIT:=0}"

# handle "env" execution
case "${EP_ENV}" in
0 | 1 ) ;;
*)
	EP_ENV=0
	case "$1" in
	env | /bin/env | /usr/bin/env )
		EP_ENV=1
	;;
	esac
;;
esac
: "${EP_ENV:=0}"
export EP_ENV

# CI handling
case "${EP_CI:=$CI}" in
0 | 1 ) ;;
[Ff][Aa][Ll][Ss][Ee] )  EP_CI=0 ;;
[Tt][Rr][Uu][Ee] )      EP_CI=1 ;;
* )
	EP_CI=0

	# try to detect various CI systems via env
	for i in \
	  ${BUILD_ID:+X} \
	  ${BUILD_NUMBER:+X} \
	  ${CI_APP_ID:+X} \
	  ${CI_BUILD_ID:+X} \
	  ${CI_BUILD_NUMBER:+X} \
	  ${CI_NAME:+X} \
	  ${CONTINUOUS_INTEGRATION:+X} \
	  ${RUN_ID:+X} \
	; do
		[ -n "$i" ] || continue
		EP_CI=1 ; break
	done ; unset i
;;
esac
if [ "${EP_CI}" = 1 ] ; then
	unset LANGUAGE LC_COLLATE LC_CTYPE LC_MESSAGES LC_NUMERIC LC_TIME
	export LANG=C.UTF-8 LC_ALL=C.UTF-8 TZ=Etc/UTC
fi
export EP_CI

# unexport variable
__EP_t=${EP_INIT} ; unset EP_INIT
EP_INIT=${__EP_t} ; unset __EP_t

case "${EP_INIT}" in
1 | [Yy][Ee][Ss] | [Tt][Rr][Uu][Ee] )
	EP_INIT='dumb-init --'
;;
0 | [Nn][Oo] | [Ff][Aa][Ll][Ss][Ee] )
	unset EP_INIT
;;
esac
if [ -n "${EP_INIT}" ] ; then
	if ! have_cmd "${EP_INIT%% *}" ; then
		log_always "missing init: ${EP_INIT}"
		unset EP_INIT
	fi
fi

# switching user
# "EP_RUNAS=user[:group]"
if [ -z "${EP_RUNAS}" ] ; then
	unset EP_RUNAS
else
	if ! run-as "${EP_RUNAS}" true >&2 ; then
		log_always "broken 'user:group' spec: '${EP_RUNAS}'"
		unset EP_RUNAS
	fi
fi

# switching priority
# "EP_PRIO=nice_level[:ionice_class[ ionice_level][:chrt_level[ chrt_options]]]"
if [ -z "${EP_PRIO}" ] ; then
	unset EP_PRIO
else
	if ! run-prio "${EP_PRIO}" true >&2 ; then
		log_always "broken 'prio' spec: '${EP_PRIO}'"
		unset EP_PRIO
	fi
fi

# run parts (if any)
while read -r f ; do
	[ -n "$f" ] || continue

	case "$f" in
	*.envsh )
		log "sourcing $f"

		__EP_SRC="$f"
		. "$f"
		__EP_SRC="$0"

		# fixups after sourcing (foreign) script
		set +e
		export MALLOC_ARENA_MAX=2
		# enforce k2env.so to be in LD_PRELOAD
		case "${LD_PRELOAD}" in
		k2env.so | k2env.so:* ) ;;
		* ) enforce_k2env_so ;;
		esac
	;;
	* )
		if ! [ -x "$f" ] ; then
			log "skipping $f - not executable"
			continue
		fi
		if [ "${EP_ENV}" = 1 ] ; then
			log "skipping $f - running 'env only' mode"
			continue
		fi
		log "running $f"
		"$f" "$@"
	;;
	esac
done <<EOF
$(if [ -d /ep.ovl ] ; then overlay-dir-list /ep.d /ep.ovl ; else find /ep.d -follow -type f | sort -V ; fi)
EOF

unset __EP_SRC EP_VERBOSE

# restore MALLOC_ARENA_MAX
MALLOC_ARENA_MAX=${EP_GLIBC_MALLOC_ARENAS}
export MALLOC_ARENA_MAX
unset EP_GLIBC_MALLOC_ARENAS

exec \
	${EP_PRIO:+ run-prio "${EP_PRIO}" } \
	${EP_RUNAS:+ run-as "${EP_RUNAS}" } \
	${LD_PRELOAD:+ env LD_PRELOAD="${LD_PRELOAD}" } \
	${EP_INIT} \
	"$@"
