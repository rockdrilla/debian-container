/* uvector: dynamic array
 *
 * - common definitions
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_UVECTOR_COMMON
#define HEADER_INCLUDED_UVECTOR_COMMON 1

#include "../misc/cc-inline.h"
#include "../misc/kustom.h"
#include "../misc/memfun.h"
#include "../num/getmsb.h"

#define UVECTOR_NAME(t, k)  KUSTOM_NAME(uvector, t, k)
#define UVECTOR_PROC        KUSTOM_PROC
#define UVECTOR_CALL        KUSTOM_CALL
#define UVECTOR_PROC_INT    KUSTOM_PROC_INT
#define UVECTOR_CALL_INT    KUSTOM_CALL_INT

static const int UVECTOR_NAME(ptr, bits) = sizeof(size_t) * CHAR_BIT;

#define _UVECTOR_DEFINE_CONSTANT_COMMON(user_t, index_t, value_t) \
	static const int     UVECTOR_NAME(user_t, r_idx_bits) = sizeof(index_t) * CHAR_BIT; \
	static const index_t UVECTOR_NAME(user_t, r_idx_max)  = ~((index_t) 0); \
	\
	static const size_t UVECTOR_NAME(user_t, item_size)  = sizeof(value_t); \
	static const size_t UVECTOR_NAME(user_t, align_size) = (sizeof(value_t)) ? MEMFUN_MACRO_ALIGN(sizeof(value_t)) : 1; \
	\
	static const int UVECTOR_NAME(user_t, align_bits) = GETMSB_MACRO32(UVECTOR_NAME(user_t, align_size)); \
	static const int UVECTOR_NAME(user_t, fence_bits) = (UVECTOR_NAME(user_t, r_idx_bits) < UVECTOR_NAME(ptr, bits)) ? 1 : UVECTOR_NAME(user_t, align_bits); \
	\
	static const index_t UVECTOR_NAME(user_t, idx_inv) = UVECTOR_NAME(user_t, r_idx_max); \
	static const index_t UVECTOR_NAME(user_t, idx_max) = UVECTOR_NAME(user_t, r_idx_max) >> UVECTOR_NAME(user_t, fence_bits); \
	\
	static const int UVECTOR_NAME(user_t, idx_bits)   = UVECTOR_NAME(user_t, r_idx_bits) - UVECTOR_NAME(user_t, fence_bits); \
	static const int UVECTOR_NAME(user_t, wfall_bits) = UVECTOR_NAME(user_t, idx_bits) - 1; \

#define _UVECTOR_DEFINE_CONSTANT(user_t, index_t, value_t) \
	_UVECTOR_DEFINE_CONSTANT_COMMON(user_t, index_t, value_t) \
	static const size_t UVECTOR_NAME(user_t, growth) = MEMFUN_MACRO_CALC_GROWTH(UVECTOR_NAME(user_t, align_size)); \

#define _UVECTOR_DEFINE_CONSTANT_EX(user_t, index_t, value_t, growth_factor) \
	_UVECTOR_DEFINE_CONSTANT_COMMON(user_t, index_t, value_t) \
	static const size_t UVECTOR_NAME(user_t, growth) = MEMFUN_MACRO_CALC_GROWTH_EX(UVECTOR_NAME(user_t, align_size), growth_factor); \

#define _UVECTOR_DEFINE_TYPE(user_t, index_t, value_t) \
	typedef struct { \
		union { \
		char     bytes[ /* UVECTOR_NAME(user_t, align_size) */ MEMFUN_MACRO_ALIGN(sizeof(value_t)) ]; \
		value_t  dummy; \
		} _;\
	} UVECTOR_NAME(user_t, alval); \
	\
	typedef struct { \
	  UVECTOR_NAME(user_t, alval) * ptr; \
	  index_t                       used, allocated; \
	} user_t;


#define _UVECTOR_DEFINE_VISITOR_PROC(user_t, index_t, value_t) \
	typedef void (* UVECTOR_NAME(user_t,  visitor))    (index_t index,       value_t * value); \
	typedef void (* UVECTOR_NAME(user_t, cvisitor))    (index_t index, const value_t * value); \
	typedef void (* UVECTOR_NAME(user_t,  visitor_ex)) (index_t index,       value_t * value, void * state); \
	typedef void (* UVECTOR_NAME(user_t, cvisitor_ex)) (index_t index, const value_t * value, void * state); \


#define _UVECTOR_PROC__INIT_FREE(user_t, index_t) \
	static \
	void \
	UVECTOR_PROC(user_t, init) (user_t * vector) { \
		(void) memset(vector, 0, sizeof(user_t)); \
	} \
	\
	static \
	int \
	UVECTOR_PROC(user_t, init_ex) (user_t * vector, index_t initial_size) { \
		UVECTOR_CALL(user_t, init, vector); \
		return UVECTOR_CALL(user_t, grow_by_count, vector, (initial_size) ? initial_size : 1); \
	} \
	\
	static \
	void \
	UVECTOR_PROC(user_t, free) (user_t * vector) { \
		memfun_free(vector->ptr, UVECTOR_CALL(user_t, offset_of, vector->used)); \
		(void) memset(vector, 0, sizeof(user_t)); \
	} \
	\
	static \
	int \
	UVECTOR_PROC(user_t, dup) (user_t * destination, const user_t * source) { \
		if (!UVECTOR_CALL(user_t, init_ex, destination, source->used)) \
			return 0; \
		(void) memcpy(destination->ptr, source->ptr, UVECTOR_CALL(user_t, offset_of, source->used)); \
		destination->used = source->used; \
		return 1; \
	} \
	\
	static \
	index_t \
	UVECTOR_PROC(user_t, copy_range) (user_t * destination, const user_t * source, index_t begin, index_t count) { \
		if (begin >= source->used) return 0; \
		index_t end = begin + count; \
		if (end > source->used) count = source->used - begin; \
		UVECTOR_CALL(user_t, init_ex, destination, count); \
		(void) memcpy(destination->ptr, UVECTOR_CALL_INT(user_t, ptr_of, source, begin), UVECTOR_CALL(user_t, offset_of, count)); \
		return destination->used = count; \
	}


#define _UVECTOR_PROC__INDEX(user_t, index_t, value_t) \
	static \
	CC_FORCE_INLINE \
	size_t \
	UVECTOR_PROC(user_t, offset_of) (index_t index) { \
		return (size_t) memfun_ptr_offset_ex(NULL, UVECTOR_NAME(user_t, align_size), index); \
	} \
	\
	static \
	CC_FORCE_INLINE \
	value_t * \
	UVECTOR_PROC_INT(user_t, ptr_of) (const user_t * vector, index_t index) { \
		return (value_t *) memfun_ptr_offset_ex(vector->ptr, UVECTOR_NAME(user_t, align_size), index); \
	} \
	\
	static \
	CC_FORCE_INLINE \
	int \
	UVECTOR_PROC(user_t, is_inv) (index_t index) { \
		return ((index >> UVECTOR_NAME(user_t, idx_bits)) != 0); \
	} \
	\
	static \
	CC_FORCE_INLINE \
	int \
	UVECTOR_PROC_INT(user_t, is_wfall) (index_t index) { \
		return ((index >> UVECTOR_NAME(user_t, wfall_bits)) != 0); \
	}


#define _UVECTOR_PROC__GROW(user_t, index_t) \
	static \
	int \
	UVECTOR_PROC_INT(user_t, grow_by_bytes) (user_t * vector, size_t bytes) { \
		size_t _new = UVECTOR_CALL(user_t, offset_of, vector->allocated); \
		UVECTOR_NAME(user_t, alval) * nptr = (UVECTOR_NAME(user_t, alval) *) memfun_realloc_ex(vector->ptr, &_new, bytes); \
		if ((!nptr) || (!_new)) return 0; \
		size_t _alloc = _new / UVECTOR_NAME(user_t, align_size); \
		vector->allocated = (_alloc < UVECTOR_NAME(user_t, idx_max)) ? _alloc : UVECTOR_NAME(user_t, idx_max); \
		if (vector->ptr == nptr) return 1; \
		vector->ptr = nptr; \
		return 2; \
	} \
	\
	static \
	int \
	UVECTOR_PROC_INT(user_t, grow_by_count) (user_t * vector, index_t count) { \
		size_t _new = 0; \
		if (UVECTOR_CALL_INT(user_t, is_wfall, vector->allocated)) { \
			if (!uaddl(vector->allocated, count, &_new)) \
				return 0; \
		} else \
			_new = vector->allocated + count; \
		if (UVECTOR_CALL(user_t, is_inv, _new)) \
			return 0; \
		return UVECTOR_CALL_INT(user_t, grow_by_bytes, vector, UVECTOR_CALL(user_t, offset_of, count)); \
	} \
	\
	static \
	int \
	UVECTOR_PROC(user_t, grow_by_bytes) (user_t * vector, size_t bytes) { \
		if (!bytes) return 0; \
		if (vector->allocated >= UVECTOR_NAME(user_t, idx_max)) \
			return 0; \
		return UVECTOR_CALL_INT(user_t, grow_by_bytes, vector, bytes); \
	} \
	\
	static \
	int \
	UVECTOR_PROC(user_t, grow_by_count) (user_t * vector, index_t count) { \
		if (!count) return 0; \
		if (UVECTOR_CALL_INT(user_t, is_wfall, count)) \
			return 0; \
		if (vector->allocated >= UVECTOR_NAME(user_t, idx_max)) \
			return 0; \
		return UVECTOR_CALL_INT(user_t, grow_by_count, vector, count); \
	} \
	\
	static \
	int \
	UVECTOR_PROC(user_t, grow_auto) (user_t * vector) { \
		if (vector->used < vector->allocated) \
			return 1; \
		return UVECTOR_CALL(user_t, grow_by_bytes, vector, UVECTOR_NAME(user_t, growth)); \
	}


#define _UVECTOR_PROC__BY_PTR(user_t, index_t, value_t) \
	static \
	value_t * \
	UVECTOR_PROC(user_t, get_by_ptr) (const user_t * vector, index_t index) { \
		if (index >= vector->used) \
			return NULL; \
		return UVECTOR_CALL_INT(user_t, ptr_of, vector, index); \
	} \
	\
	static \
	CC_FORCE_INLINE \
	void \
	UVECTOR_PROC_INT(user_t, set_by_ptr) (user_t * vector, index_t index, const value_t * source) { \
		void * item = UVECTOR_CALL_INT(user_t, ptr_of, vector, index); \
		if (source) \
			(void) memcpy(item, source, UVECTOR_NAME(user_t, item_size)); \
		else \
			(void) memset(item, 0, UVECTOR_NAME(user_t, item_size)); \
	} \
	\
	static \
	int \
	UVECTOR_PROC(user_t, set_by_ptr) (user_t * vector, index_t index, const value_t * source) { \
		if (index >= vector->used) \
			return 0; \
		UVECTOR_CALL_INT(user_t, set_by_ptr, vector, index, source); \
		return 1; \
	} \
	\
	static \
	index_t \
	UVECTOR_PROC(user_t, append_by_ptr) (user_t * vector, const value_t * source) { \
		if (!UVECTOR_CALL(user_t, grow_auto, vector)) \
			return UVECTOR_NAME(user_t, idx_inv); \
		UVECTOR_CALL_INT(user_t, set_by_ptr, vector, vector->used, source); \
		return (vector->used++); \
	}


#define _UVECTOR_PROC__BY_VAL(user_t, index_t, value_t) \
	static \
	CC_FORCE_INLINE \
	value_t \
	UVECTOR_PROC_INT(user_t, get_by_val) (const user_t * vector, index_t index) { \
		value_t * item = UVECTOR_CALL_INT(user_t, ptr_of, vector, index); \
		return *item; \
	} \
	\
	static \
	value_t \
	UVECTOR_PROC(user_t, get_by_val) (const user_t * vector, index_t index) { \
		if (index >= vector->used) { \
			static value_t default_value; \
			static int default_init = 0; \
			if (!default_init) { \
				(void) memset(&default_value, 0, sizeof(value_t)); \
				default_init = 1; \
			} \
			return default_value; \
		} \
		return UVECTOR_CALL_INT(user_t, get_by_val, vector, index); \
	} \
	\
	static \
	CC_FORCE_INLINE \
	void \
	UVECTOR_PROC_INT(user_t, set_by_val) (user_t * vector, index_t index, value_t value) { \
		value_t * item = UVECTOR_CALL_INT(user_t, ptr_of, vector, index); \
		*item = value; \
	} \
	\
	static \
	int \
	UVECTOR_PROC(user_t, set_by_val) (user_t * vector, index_t index, value_t value) { \
		if (index >= vector->used) \
			return 0; \
		UVECTOR_CALL_INT(user_t, set_by_val, vector, index, value); \
		return 1; \
	} \
	\
	static \
	index_t \
	UVECTOR_PROC(user_t, append_by_val) (user_t * vector, value_t value) { \
		if (!UVECTOR_CALL(user_t, grow_auto, vector)) \
			return UVECTOR_NAME(user_t, idx_inv); \
		UVECTOR_CALL_INT(user_t, set_by_val, vector, vector->used, value); \
		return (vector->used++); \
	}


#define _UVECTOR_PROC__WALK(user_t, index_t, value_t) \
	static \
	void \
	UVECTOR_PROC(user_t, walk) (user_t * vector, UVECTOR_NAME(user_t, visitor) visitor) { \
		for (index_t i = 0; i < vector->used; i++) { \
			visitor(i, UVECTOR_CALL_INT(user_t, ptr_of, vector, i)); \
		} \
	} \
	\
	static \
	void \
	UVECTOR_PROC(user_t, walk_ex) (user_t * vector, UVECTOR_NAME(user_t, visitor_ex) visitor, void * state) { \
		for (index_t i = 0; i < vector->used; i++) { \
			visitor(i, UVECTOR_CALL_INT(user_t, ptr_of, vector, i), state); \
		} \
	} \
	\
	static \
	void \
	UVECTOR_PROC(user_t, const_walk) (const user_t * vector, UVECTOR_NAME(user_t, cvisitor) visitor) { \
		for (index_t i = 0; i < vector->used; i++) { \
			visitor(i, (const value_t *) UVECTOR_CALL_INT(user_t, ptr_of, vector, i)); \
		} \
	} \
	\
	static \
	void \
	UVECTOR_PROC(user_t, const_walk_ex) (const user_t * vector, UVECTOR_NAME(user_t, cvisitor_ex) visitor, void * state) { \
		for (index_t i = 0; i < vector->used; i++) { \
			visitor(i, (const value_t *) UVECTOR_CALL_INT(user_t, ptr_of, vector, i), state); \
		} \
	} \
	\
	static \
	void \
	UVECTOR_PROC(user_t, rwalk) (user_t * vector, UVECTOR_NAME(user_t, visitor) visitor) { \
		for (index_t i = vector->used; (i--) != 0; ) { \
			visitor(i, UVECTOR_CALL_INT(user_t, ptr_of, vector, i)); \
		} \
	} \
	\
	static \
	void \
	UVECTOR_PROC(user_t, rwalk_ex) (user_t * vector, UVECTOR_NAME(user_t, visitor_ex) visitor, void * state) { \
		for (index_t i = vector->used; (i--) != 0; ) { \
			visitor(i, UVECTOR_CALL_INT(user_t, ptr_of, vector, i), state); \
		} \
	} \
	\
	static \
	void \
	UVECTOR_PROC(user_t, const_rwalk) (const user_t * vector, UVECTOR_NAME(user_t, cvisitor) visitor) { \
		for (index_t i = vector->used; (i--) != 0; ) { \
			visitor(i, (const value_t *) UVECTOR_CALL_INT(user_t, ptr_of, vector, i)); \
		} \
	} \
	\
	static \
	void \
	UVECTOR_PROC(user_t, const_rwalk_ex) (const user_t * vector, UVECTOR_NAME(user_t, cvisitor_ex) visitor, void * state) { \
		for (index_t i = vector->used; (i--) != 0; ) { \
			visitor(i, (const value_t *) UVECTOR_CALL_INT(user_t, ptr_of, vector, i), state); \
		} \
	}


#endif /* HEADER_INCLUDED_UVECTOR_COMMON */
