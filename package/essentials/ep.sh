#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2022-2023, Konstantin Demin

# TL;DR head to "ep.sh itself" marker

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

if [ -z "${__EP_SRC}" ] ; then

# ep.sh itself

set -f

# normalize LD_PRELOAD:
# - normalize separators
# - strip k2env.so (if any)
reparse_ld_preload() {
	tr -s ' :' '\0' \
	| grep -zEv '^(.+/|)k2env\.so$' \
	| paste -zsd':' \
	| tr -d '\0'
}

enforce_k2env_so() {
	_ld_preload="${LD_PRELOAD}"
	unset LD_PRELOAD
	set +e
	LD_PRELOAD=$(printf '%s' "${_ld_preload}" | reparse_ld_preload)
	export LD_PRELOAD="k2env.so${LD_PRELOAD:+:$LD_PRELOAD}"
	unset _ld_preload
}

# enforce k2env.so to be in LD_PRELOAD
case "${LD_PRELOAD}" in
k2env.so | k2env.so[\ :]* ) ;;
* )
	enforce_k2env_so

	# early set NPROC
	NPROC=$(nproc)
	export NPROC
;;
esac

# early set MALLOC_ARENA_MAX
__arenas=2
if [ -n "${NPROC}" ] ; then
    [ "${__arenas}" -ge "${NPROC}" ] || __arenas=${NPROC}
fi
: "${MALLOC_ARENA_MAX:=${__arenas}}"
unset __arenas
export MALLOC_ARENA_MAX

# handle "env" execution
if [ "$1" = env ] ; then
	export EP_ENV=1
fi

__EP_SRC="$0"

# CI handling
: "${EP_CI:=$CI}"
export EP_CI

case "${EP_CI}" in
0 | 1 ) ;;
[Ff][Aa][Ll][Ss][Ee] )
	EP_CI=0
;;
[Tt][Rr][Uu][Ee] )
	EP_CI=1
;;
* )
	EP_CI=0

	__ci=''
	# try to detect various CI systems via env
	__ci="${__ci}${BUILD_ID}${BUILD_NUMBER}${CI_APP_ID}"
	__ci="${__ci}${CI_BUILD_ID}${CI_BUILD_NUMBER}${CI_NAME}"
	__ci="${__ci}${CONTINUOUS_INTEGRATION}${RUN_ID}"

	if [ -n "${__ci}" ] ; then
		EP_CI=1
	fi

	unset __ci
;;
esac

if [ "${EP_CI}" = 1 ] ; then
	export EP_INIT=1 LANG=C.UTF-8 LC_ALL=C.UTF-8 TZ=Etc/UTC
fi

# PID1 handling
# "EP_INIT={no|false|0|pid1_prog[ args]}"
if [ "$$" = 1 ] ; then
	: "${EP_INIT:=1}"
else
	: "${EP_INIT:=0}"
fi

# unexport variable
__EP_t=${EP_INIT} ; unset EP_INIT
EP_INIT=${__EP_t} ; unset __EP_t

case "${EP_INIT}" in
1 | [Yy][Ee][Ss] | [Tt][Rr][Uu][Ee] )
	EP_INIT='dumb-init --'
;;
esac

case "${EP_INIT}" in
0 | [Nn][Oo] | [Ff][Aa][Ll][Ss][Ee] )
	unset EP_INIT
;;
* )
	if ! have_cmd "${EP_INIT%% *}" ; then
		log "pid1: ${EP_INIT} is not found"
		unset EP_INIT
	fi
;;
esac

# switching user
# "EP_RUNAS=user[:group]"
unset EP_RUNAS_USER EP_RUNAS_GROUP
if [ -z "${EP_RUNAS}" ] ; then
	unset EP_RUNAS
else
	if ! run-as "${EP_RUNAS}" true >&2 ; then
		unset EP_RUNAS
	fi
fi

# switching priority
# "EP_PRIO=nice_level[:ionice_class[ ionice_level][:chrt_level[ chrt_options]]]"
if [ -z "${EP_PRIO}" ] ; then
	unset EP_PRIO
else
	if ! run-prio "${EP_PRIO}" true >&2 ; then
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
		set +e
		__EP_SRC="$0"
	;;
	* )
		if [ -x "$f" ] ; then
			if [ -n "${EP_ENV}" ] ; then
				log "skipping $f - running 'env only' mode"
				continue
			fi

			log "running $f"

			__EP_SRC="$f" \
			"$f" "$@"
		else
			log "skipping $f - not executable"
		fi
	;;
	esac
done <<EOF
$(if [ -d /ep.ovl ] ; then overlay-dir-list /ep.d /ep.ovl ; else ufind -q /ep.d | sort -V ; fi)
EOF

unset __EP_SRC EP_VERBOSE

# enforce k2env.so to be in LD_PRELOAD
case "${LD_PRELOAD}" in
k2env.so | k2env.so[\ :]* ) ;;
* )
	enforce_k2env_so
;;
esac

exec \
	${EP_PRIO:+ run-prio "${EP_PRIO}" } \
	${EP_RUNAS:+ run-as "${EP_RUNAS}" } \
	${LD_PRELOAD:+ env LD_PRELOAD="${LD_PRELOAD}" } \
	${EP_INIT} \
	"$@"

fi
