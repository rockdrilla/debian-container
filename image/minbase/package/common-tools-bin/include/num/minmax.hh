/* minmax: min/max
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_NUM_MINMAX_HH
#define HEADER_INCLUDED_NUM_MINMAX_HH 1

#include "minmax.h"

template<typename T1, typename T2 = T1>
static CC_FORCE_INLINE \
T1 min_positive_t(T1 a, T2 b);

#define _MIN_POSITIVE_T_DEFINE_COMPAT_FUNC(n, T1, T2) \
	template<> CC_FORCE_INLINE \
	T1 min_positive_t<T1>(T1 a, T2 b) \
	{ \
		return min_positive ## n (a, b); \
	}

#define _MIN_POSITIVE_T_DEFINE_FUNC(n, T) \
	_MIN_POSITIVE_T_DEFINE_COMPAT_FUNC(n, T, T)

_MIN_POSITIVE_T_DEFINE_FUNC(,   int)
_MIN_POSITIVE_T_DEFINE_FUNC(l,  long)
_MIN_POSITIVE_T_DEFINE_FUNC(ll, long long)

_MIN_POSITIVE_T_DEFINE_COMPAT_FUNC(l,  long, int)
_MIN_POSITIVE_T_DEFINE_COMPAT_FUNC(ll, long long, int)
_MIN_POSITIVE_T_DEFINE_COMPAT_FUNC(ll, long long, long)

#endif /* HEADER_INCLUDED_NUM_MINMAX_HH */
