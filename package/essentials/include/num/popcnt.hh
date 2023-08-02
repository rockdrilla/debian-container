/* popcnt: simple wrapper
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_NUM_POPCNT_HH
#define HEADER_INCLUDED_NUM_POPCNT_HH 1

#include "popcnt.h"

template<typename T>
static \
CC_FORCE_INLINE \
T popcnt_t(T a);

#define _POPCNT_T_DEFINE_FUNC(n, T) \
	template<> \
	CC_FORCE_INLINE \
	T popcnt_t<T>(T a) \
	{ \
		return popcnt ## n (a); \
	}

_POPCNT_T_DEFINE_FUNC(,   unsigned int)
_POPCNT_T_DEFINE_FUNC(l,  unsigned long)
_POPCNT_T_DEFINE_FUNC(ll, unsigned long long)

#endif /* HEADER_INCLUDED_NUM_POPCNT_HH */
