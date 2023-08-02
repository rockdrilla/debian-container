/* roundby: align value at certain alignment value
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_NUM_ROUNDBY_HH
#define HEADER_INCLUDED_NUM_ROUNDBY_HH 1

#include "roundby.h"

template<typename T1, typename T2 = T1>
static \
CC_FORCE_INLINE \
T1 roundby_t(T1 a, T2 b);

#define _ROUNDBY_T_DEFINE_COMPAT_FUNC(n, T1, T2) \
	template<> \
	CC_FORCE_INLINE \
	T1 roundby_t<T1>(T1 a, T2 b) \
	{ \
		return roundby ## n (a, b); \
	}

#define _ROUNDBY_T_DEFINE_FUNC(n, T) \
	_ROUNDBY_T_DEFINE_COMPAT_FUNC(n, T, T)

_ROUNDBY_T_DEFINE_FUNC(,   unsigned int)
_ROUNDBY_T_DEFINE_FUNC(l,  unsigned long)
_ROUNDBY_T_DEFINE_FUNC(ll, unsigned long long)

_ROUNDBY_T_DEFINE_COMPAT_FUNC(l,  unsigned long,      unsigned int)
_ROUNDBY_T_DEFINE_COMPAT_FUNC(ll, unsigned long long, unsigned int)
_ROUNDBY_T_DEFINE_COMPAT_FUNC(ll, unsigned long long, unsigned long)

#endif /* HEADER_INCLUDED_NUM_ROUNDBY_HH */
