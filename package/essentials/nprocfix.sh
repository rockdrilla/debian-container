#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2022-2023, Konstantin Demin

set -f

reparse_ld_preload() {
	tr ' :' '\0' \
	| grep -zEv '^(.+/|)libincontainer\.so$' \
	| paste -zsd':' \
	| tr -d '\0'
}

# normalize LD_PRELOAD:
# - normalize separators
# - strip libincontainer.so (if any)
if [ -n "${LD_PRELOAD}" ] ; then
	__old="${LD_PRELOAD}"
	unset LD_PRELOAD

	set +e
	__new=$(printf '%s' "${__old}" | reparse_ld_preload)
	if [ -n "${__new}" ] ; then
		export LD_PRELOAD="${__new}"
	fi

	unset __old __new
fi

export LD_PRELOAD="libincontainer.so${LD_PRELOAD:+:$LD_PRELOAD}"

exec "$@"
