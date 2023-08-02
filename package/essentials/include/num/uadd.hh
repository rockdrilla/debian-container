/* uadd: (safe) unsigned add
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_NUM_UADD_HH
#define HEADER_INCLUDED_NUM_UADD_HH 1

#include "uadd.h"

template<typename T1, typename T2 = T1>
static \
CC_FORCE_INLINE \
int uadd_t(T1 a, T2 b, T1 * r);

#define _UADD_T_DEFINE_COMPAT_FUNC(n, T1, T2) \
	template<> \
	CC_FORCE_INLINE \
	int uadd_t<T1>(T1 a, T2 b, T1 * r) \
	{ \
		return uadd ## n (a, b, r); \
	}

#define _UADD_T_DEFINE_FUNC(n, T) \
	_UADD_T_DEFINE_COMPAT_FUNC(n, T, T)

_UADD_T_DEFINE_FUNC(,   unsigned int)
_UADD_T_DEFINE_FUNC(l,  unsigned long)
_UADD_T_DEFINE_FUNC(ll, unsigned long long)

_UADD_T_DEFINE_COMPAT_FUNC(l,  unsigned long,      unsigned int)
_UADD_T_DEFINE_COMPAT_FUNC(ll, unsigned long long, unsigned int)
_UADD_T_DEFINE_COMPAT_FUNC(ll, unsigned long long, unsigned long)

#endif /* HEADER_INCLUDED_NUM_UADD_HH */
