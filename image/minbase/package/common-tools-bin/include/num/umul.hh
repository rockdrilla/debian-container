/* umul: (safe) unsigned multiply
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_NUM_UMUL_HH
#define HEADER_INCLUDED_NUM_UMUL_HH 1

#include "umul.h"

template<typename T1, typename T2 = T1>
static CC_FORCE_INLINE \
int umul_t(T1 a, T2 b, T1 * r);

#define _UMUL_T_DEFINE_COMPAT_FUNC(n, T1, T2) \
	template<> CC_FORCE_INLINE \
	int umul_t<T1>(T1 a, T2 b, T1 * r) \
	{ \
		return umul ## n (a, b, r); \
	}

#define _UMUL_T_DEFINE_FUNC(n, T) \
	_UMUL_T_DEFINE_COMPAT_FUNC(n, T, T)

_UMUL_T_DEFINE_FUNC(,   unsigned int)
_UMUL_T_DEFINE_FUNC(l,  unsigned long)
_UMUL_T_DEFINE_FUNC(ll, unsigned long long)

_UMUL_T_DEFINE_COMPAT_FUNC(l,  unsigned long,      unsigned int)
_UMUL_T_DEFINE_COMPAT_FUNC(ll, unsigned long long, unsigned int)
_UMUL_T_DEFINE_COMPAT_FUNC(ll, unsigned long long, unsigned long)

#endif /* HEADER_INCLUDED_NUM_UMUL_HH */
