#!/bin/sh
## SPDX-License-Identifier: Apache-2.0
## (c) 2022-2023, Konstantin Demin
find "$@" -follow -type f -print0 \
| xargs -0 -r -n 128 stat -L --printf='%d:%i|%n\0' \
| sort -z -u -t '|' -k1,1 \
| cut -z -d '|' -f 2 \
| tr '\0' '\n'
