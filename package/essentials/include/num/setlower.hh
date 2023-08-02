/* set lower: set all bits to 1 starting from most significant set bit
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_NUM_SETLOWER_HH
#define HEADER_INCLUDED_NUM_SETLOWER_HH 1

#include "setlower.h"

template<typename T>
static \
CC_FORCE_INLINE \
T set_lower_t(T a);

#define _SETLOWER_T_DEFINE_FUNC(n, T) \
	template<> \
	CC_FORCE_INLINE \
	T set_lower_t<T>(T a) \
	{ \
		return set_lower ## n (a); \
	}

_SETLOWER_T_DEFINE_FUNC(,   unsigned int)
_SETLOWER_T_DEFINE_FUNC(l,  unsigned long)
_SETLOWER_T_DEFINE_FUNC(ll, unsigned long long)

#endif /* HEADER_INCLUDED_NUM_SETLOWER_HH */
