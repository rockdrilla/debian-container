/* degree2: current and next 2's degree
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_NUM_DEGREE2_HH
#define HEADER_INCLUDED_NUM_DEGREE2_HH 1

#include "degree2.h"

template<typename T>
static \
CC_FORCE_INLINE \
T degree2_curr_t(T a);

template<typename T>
static \
CC_FORCE_INLINE \
T degree2_next_t(T a);

#define _DEGREE2_T_CURR_FUNC(n, T) \
	template<> \
	CC_FORCE_INLINE \
	T degree2_curr_t<T>(T a) \
	{ \
		return degree2_curr ## n (a); \
	}

_DEGREE2_T_CURR_FUNC(,   unsigned int)
_DEGREE2_T_CURR_FUNC(l,  unsigned long)
_DEGREE2_T_CURR_FUNC(ll, unsigned long long)

#define _DEGREE2_T_NEXT_FUNC(n, T) \
	template<> \
	CC_FORCE_INLINE \
	T degree2_next_t<T>(T a) \
	{ \
		return degree2_next ## n (a); \
	}

_DEGREE2_T_NEXT_FUNC(,   unsigned int)
_DEGREE2_T_NEXT_FUNC(l,  unsigned long)
_DEGREE2_T_NEXT_FUNC(ll, unsigned long long)

#endif /* HEADER_INCLUDED_NUM_DEGREE2_HH */
