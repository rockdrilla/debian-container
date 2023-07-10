#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# (c) 2023, Konstantin Demin

set -f

field="${1:?}"
source="$2"
if [ "${source}" = '-' ] ; then source= ; fi

# "safe" sed separator
xsedx=$(printf '\027')

match_start="\\${xsedx}^${field}:.*\$${xsedx}"
match_end1="\\${xsedx}^\\S.*\$${xsedx}"
match_end2="\\${xsedx}^\$${xsedx}"

replace1="s${xsedx}^${field}:\\s*\$${xsedx}${xsedx}"
replace2="s${xsedx}^${field}:\\s+(\\S.*)\\s*\$${xsedx}\\1${xsedx}"

match_script="h;:a;\$bb;n;${match_end1}bb;${match_end2}bb;H;ba;:b;x;${replace1};${replace2};p"

script="${match_start}{${match_script}}"

sed -En -e "${script}" ${source:+"${source}"}
