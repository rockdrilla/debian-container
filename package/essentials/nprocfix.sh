#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2022-2023, Konstantin Demin

set -f

# normalize LD_PRELOAD:
# - normalize separators
# - strip libincontainer.so (if any)
reparse_ld_preload() {
	tr -s ' :' '\0' \
	| grep -zEv '^(.+/|)libincontainer\.so$' \
	| paste -zsd':' \
	| tr -d '\0'
}

enforce_libincontainer_so() {
	_ld_preload="${LD_PRELOAD}"
	unset LD_PRELOAD
	set +e
	LD_PRELOAD=$(printf '%s' "${_ld_preload}" | reparse_ld_preload)
	export LD_PRELOAD="libincontainer.so${LD_PRELOAD:+:$LD_PRELOAD}"
	unset _ld_preload
}

case "${LD_PRELOAD}" in
libincontainer.so ) ;;
*)
	enforce_libincontainer_so
;;
esac

exec "$@"
