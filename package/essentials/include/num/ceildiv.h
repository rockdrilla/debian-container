/* ceildiv: (safe) "ceil-div" variant
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_NUM_CEILDIV
#define HEADER_INCLUDED_NUM_CEILDIV 1

#include "../misc/ext-c-begin.h"

#include <stdlib.h>

#include "../misc/cc-inline.h"

#define _CEILDIV_DEFINE_FUNC(n, t) \
	static \
	CC_INLINE \
	t ceildiv ## n (t a, t b) { \
		n ## div_t qr = n ## div(a, b); \
		return qr.quot + ((qr.rem) ? 1 : 0); \
	}

_CEILDIV_DEFINE_FUNC(,   int)
_CEILDIV_DEFINE_FUNC(l,  long)
_CEILDIV_DEFINE_FUNC(ll, long long)

#include "../misc/ext-c-end.h"

#endif /* HEADER_INCLUDED_NUM_CEILDIV */
