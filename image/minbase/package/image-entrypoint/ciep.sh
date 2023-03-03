#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2022-2023, Konstantin Demin

# TL;DR head to "ciep.sh itself" marker

# common shell functions: begin

log_always() {
	if [ $# = 0 ] ; then
		echo "# ${__CIEP_SOURCE}: $(date +'%Y-%m-%d %H:%M:%S %z')"
	else
		echo "# ${__CIEP_SOURCE}: $*"
	fi 1>&2
}
if [ "${CIEP_VERBOSE:-0}" = 1 ] ; then
	log() { log_always "$@" ; }
else
	log() { : ;}
fi

have_cmd() { command -v "$1" >/dev/null 2>&1 ; }

run_user_cmd() { ${CIEP_RUNAS:+run-as "${CIEP_RUNAS}"} "$@" ; }

# common shell functions: end

if [ -z "${__CIEP_SOURCE}" ] ; then

# ciep.sh itself

set -f

if [ "$1" = env ] ; then
	export CIEP_ENV=1
fi

__CIEP_SOURCE="$0"

# PID1 handling
# "CIEP_INIT={no|false|0|pid1_prog[ args]}"
if [ "$$" = 1 ] ; then
	: "${CIEP_INIT:=1}"
else
	: "${CIEP_INIT:=0}"
fi

# unexport variable
__CIEP_t=${CIEP_INIT} ; unset CIEP_INIT
CIEP_INIT=${__CIEP_t} ; unset __CIEP_t

case "${CIEP_INIT}" in
1 | [Yy][Ee][Ss] | [Tt][Rr][Uu][Ee])
	CIEP_INIT='dumb-init --'
;;
esac

case "${CIEP_INIT}" in
0 | [Nn][Oo] | [Ff][Aa][Ll][Ss][Ee])
	unset CIEP_INIT
;;
*)
	if ! have_cmd "${CIEP_INIT%% *}" ; then
		log "pid1: ${CIEP_INIT} is not found"
		unset CIEP_INIT
	fi
;;
esac

# switching user
# "CIEP_RUNAS=user[:group]"
unset CIEP_RUNAS_USER CIEP_RUNAS_GROUP
if [ -z "${CIEP_RUNAS}" ] ; then
	unset CIEP_RUNAS
else
	if ! run-as "${CIEP_RUNAS}" true >&2 ; then
		unset CIEP_RUNAS
	fi
fi

# switching priority
# "CIEP_PRIO=nice_level[:ionice_class[ ionice_level][:chrt_level[ chrt_options]]]"
if [ -z "${CIEP_PRIO}" ] ; then
	unset CIEP_PRIO
else
	if ! run-prio "${CIEP_PRIO}" true >&2 ; then
		unset CIEP_PRIO
	fi
fi

# run parts (if any)
while read -r f ; do
	[ -n "$f" ] || continue

	case "$f" in
	*.envsh)
		log "sourcing $f"
		__CIEP_SOURCE="$f"
		. "$f"
		__CIEP_SOURCE="$0"
	;;
	*)
		if [ -x "$f" ] ; then
			if [ -n "${CIEP_ENV}" ] ; then
				log "skipping $f - running 'env only' mode"
				continue
			fi

			log "running $f"

			__CIEP_SOURCE="$f" \
			"$f" "$@"
		else
			log "skipping $f - not executable"
		fi
	;;
	esac
done <<EOF
$(overlay-dir-list /ciep.d /ciep.user)
EOF

unset __CIEP_SOURCE CIEP_VERBOSE

exec \
	${CIEP_PRIO:+run-prio "${CIEP_PRIO}"} \
	${CIEP_RUNAS:+run-as "${CIEP_RUNAS}"} \
	${LD_PRELOAD:+env LD_PRELOAD="${LD_PRELOAD}"} \
	${CIEP_INIT} \
	"$@"

fi
