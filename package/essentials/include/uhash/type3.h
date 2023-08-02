/* uhash: simple grow-only hash
 *
 * - uhash "type 3": both key and value are "aggregate"
 *
 * refs:
 * - [1] https://github.com/etherealvisage/avl
 * - [2] https://github.com/DanielGibson/Snippets
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_UHASH_TYPE3
#define HEADER_INCLUDED_UHASH_TYPE3 1

#include "type2.h"

#define _UHASH_NAME_NODE__TYPE3(user_t) \
	typedef struct UHASH_NAME(user_t, node) { \
		UHASH_IDX_T  key; \
		UHASH_IDX_T  left, right; \
		UHASH_IDX_T  value; \
		int          depth; \
	} UHASH_NAME(user_t, node);

#define _UHASH_NAMEIMPL__TYPE3(user_t) \
	UVECTOR_NAME(user_t, v_node)    nodes; \
	UVECTOR_NAME(user_t, v_key)     keys; \
	UVECTOR_NAME(user_t, v_value)   values; \
	UHASH_NAME(user_t, key_cmp)     key_comparator; \
	UHASH_NAME(user_t, value_proc)  value_constructor; \
	UHASH_NAME(user_t, value_proc)  value_destructor; \
	UHASH_IDX_T                     tree_root;


#define _UHASH_PROC_KEY__TYPE3(user_t, key_t) \
	static \
	CC_FORCE_INLINE \
	const key_t * \
	UHASH_PROC_INT(user_t, raw_key) (const user_t * hash, UHASH_IDX_T index) { \
		return UHASH_VCALL(user_t, v_key, get_by_ptr, &(hash->keys), _uhash_idx_int(index)); \
	} \
	\
	static \
	CC_FORCE_INLINE \
	const key_t * \
	UHASH_PROC_INT(user_t, key) (const user_t * hash, const UHASH_NAME(user_t, node) * node) { \
		return (node->key) ? UHASH_CALL_INT(user_t, raw_key, hash, node->key) : NULL; \
	} \
	\
	static \
	const key_t * \
	UHASH_PROC(user_t, key) (const user_t * hash, UHASH_IDX_T node_index) { \
		const UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, cnode, hash, node_index); \
		if (!node) return NULL; \
		return UHASH_CALL_INT(user_t, key, hash, node); \
	} \
	\
	static \
	void \
	UHASH_PROC_INT(user_t, set_key) (user_t * hash, UHASH_NAME(user_t, node) * node, const key_t * key) { \
		UHASH_IDX_T i; \
		switch (node->key) { \
		case 0: \
			if (!key) break; \
			i = UHASH_VCALL(user_t, v_key, append_by_ptr, &(hash->keys), key); \
			if (UHASH_VCALL(user_t, v_key, is_inv, i)) break; \
			node->key = _uhash_idx_pub(i); \
			break; \
		default: \
			i = _uhash_idx_int(node->key); \
			UHASH_VCALL(user_t, v_key, set_by_ptr, &(hash->keys), i, key); \
			if (!key) { \
				node->key = 0; \
				break; \
			} \
		} \
	} \
	\
	static \
	void \
	UHASH_PROC(user_t, set_key) (user_t * hash, UHASH_IDX_T node_index, const key_t * key) { \
		UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, node, hash, node_index); \
		if (!node) return; \
		UHASH_CALL_INT(user_t, set_key, hash, node, key); \
	}


#define _UHASH_PROC_VALUE__TYPE3(user_t, value_t) \
	_UHASH_PROC_VALUE__TYPE2(user_t, value_t)


#define _UHASH_PROC__INIT_NODE__TYPE3(user_t, key_t, value_t) \
	static \
	CC_FORCE_INLINE \
	void \
	UHASH_PROC_INT(user_t, init_node) (user_t * hash, UHASH_NAME(user_t, node) * node, const key_t * key, const value_t * value) { \
		node->depth = 1; \
		UHASH_CALL_INT(user_t, set_key, hash, node, key); \
		UHASH_CALL_INT(user_t, set_value, hash, node, value); \
	}

#define _UHASH_PROCIMPL_INIT__TYPE3(user_t, key_t, value_t) \
	{ \
	_UHASH_PROCIMPL_INIT__TYPE2(user_t, value_t) \
	UHASH_VCALL(user_t, v_key, init, &(hash->keys)); \
	}

#define _UHASH_PROC_INIT__TYPE3(user_t, key_t, value_t) \
	static \
	void \
	UHASH_PROC(user_t, init) (user_t * hash) \
		_UHASH_PROCIMPL_INIT__TYPE3(user_t, key_t, value_t)

#define _UHASH_PROCIMPL_FREE__TYPE3(user_t) \
	{ \
	UHASH_VCALL(user_t, v_key, free, &(hash->keys)); \
	_UHASH_PROCIMPL_FREE__TYPE2(user_t) \
	}

#define _UHASH_PROC_FREE__TYPE3(user_t) \
	static \
	void \
	UHASH_PROC(user_t, free) (user_t * hash) \
		_UHASH_PROCIMPL_FREE__TYPE3(user_t)


#define _UHASH_PROC_SEARCH__TYPE3(user_t, key_t) \
	static \
	UHASH_IDX_T \
	UHASH_PROC(user_t, search) (user_t * hash, key_t * key) \
		_UHASH_PROCIMPL_SEARCH(user_t)

#define _UHASH_PROC_INSERT__TYPE3(user_t, key_t, value_t) \
	static \
	UHASH_IDX_T \
	UHASH_PROC(user_t, insert) (user_t * hash, const key_t * key, const value_t * value) \
		_UHASH_PROCIMPL_INSERT(user_t, 0) \
	\
	static \
	UHASH_IDX_T \
	UHASH_PROC(user_t, insert_strict) (user_t * hash, const key_t * key, const value_t * value) \
		_UHASH_PROCIMPL_INSERT(user_t, 1) \
	\
	static \
	UHASH_IDX_T \
	UHASH_PROC(user_t, insert_ex) (user_t * hash, const key_t * key, const value_t * value, int strict) \
		_UHASH_PROCIMPL_INSERT(user_t, strict)


#define UHASH_DEFINE_TYPE3(user_t, key_t, value_t) \
	_UHASH_NAMEPROC_KEY_VISITOR(user_t, key_t) \
	_UHASH_NAMEPROC_VALUE_VISITOR(user_t, value_t) \
	_UHASH_NAMEPROC_CMP_KEY_PTR(user_t, key_t) \
	\
	_UHASH_NAME_NODE__TYPE3(user_t) \
	UVECTOR_DEFINE_TYPE0(UVECTOR_NAME(user_t, v_idx),   UHASH_IDX_T, UHASH_IDX_T) \
	UVECTOR_DEFINE_TYPE1(UVECTOR_NAME(user_t, v_node),  UHASH_IDX_T, UHASH_NAME(user_t, node)) \
	UVECTOR_DEFINE_TYPE1(UVECTOR_NAME(user_t, v_key),   UHASH_IDX_T, key_t) \
	UVECTOR_DEFINE_TYPE1(UVECTOR_NAME(user_t, v_value), UHASH_IDX_T, value_t) \
	typedef struct { \
		_UHASH_NAMEIMPL__TYPE3(user_t) \
	} user_t; \
	\
	_UHASH_PROC_NODE(user_t) \
	_UHASH_PROC_KEY__TYPE3(user_t, key_t) \
	_UHASH_PROC_VALUE__TYPE3(user_t, value_t) \
	\
	_UHASH_PROC__INIT_NODE__TYPE3(user_t, key_t, value_t) \
	_UHASH_PROC_INIT__TYPE3(user_t, key_t, value_t) \
	_UHASH_PROC_FREE__TYPE3(user_t) \
	\
	_UHASH_PROC_RELA_INDEX(user_t) \
	_UHASH_PROC_RELA_NODE(user_t) \
	_UHASH_PROC_LEFT(user_t) \
	_UHASH_PROC_RIGHT(user_t) \
	_UHASH_PROC_DEPTH(user_t) \
	_UHASH_PROC_TREE_DEPTH(user_t) \
	_UHASH_PROC_BALANCE_FACTOR(user_t) \
	_UHASH_PROC_UPDATE_DEPTH(user_t) \
	_UHASH_PROC_ROTATE_LEFT(user_t) \
	_UHASH_PROC_ROTATE_RIGHT(user_t) \
	_UHASH_PROC_ROTATE(user_t) \
	_UHASH_PROC_REBALANCE(user_t) \
	\
	_UHASH_PROC_SEARCH__TYPE3(user_t, key_t) \
	_UHASH_PROC_INSERT__TYPE3(user_t, key_t, value_t) \


#endif /* HEADER_INCLUDED_UHASH_TYPE3 */
