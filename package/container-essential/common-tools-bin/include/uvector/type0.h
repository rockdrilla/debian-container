/* uvector: dynamic array
 *
 * - uvector "type 0": value is scalar
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_UVECTOR_TYPE0
#define HEADER_INCLUDED_UVECTOR_TYPE0

#include "common.h"

#define _UVECTOR_DEFINE_TYPE0_COMMON(user_t, index_t, value_t) \
	_UVECTOR_DEFINE_TYPE(user_t, index_t, value_t) \
	_UVECTOR_DEFINE_VISITOR_PROC(user_t, index_t, value_t) \
	_UVECTOR_PROC__INDEX(user_t, index_t, value_t) \
	_UVECTOR_PROC__GROW(user_t, index_t) \
	_UVECTOR_PROC__INIT_FREE(user_t, index_t) \
	_UVECTOR_PROC__WALK(user_t, index_t, value_t) \
	_UVECTOR_PROC__BY_PTR(user_t, index_t, value_t) \
	_UVECTOR_PROC__BY_VAL(user_t, index_t, value_t) \

#define UVECTOR_DEFINE_TYPE0(user_t, index_t, value_t) \
	_UVECTOR_DEFINE_CONSTANT(user_t, index_t, value_t) \
	_UVECTOR_DEFINE_TYPE0_COMMON(user_t, index_t, value_t) \

#define UVECTOR_DEFINE_TYPE0_EX(user_t, index_t, value_t, growth_factor) \
	_UVECTOR_DEFINE_CONSTANT_EX(user_t, index_t, value_t, growth_factor) \
	_UVECTOR_DEFINE_TYPE0_COMMON(user_t, index_t, value_t) \

#endif /* HEADER_INCLUDED_UVECTOR_TYPE0 */
