/* uhash: simple grow-only hash
 *
 * - uhash "type 1": both key and value are "scalars"
 *
 * refs:
 * - [1] https://github.com/etherealvisage/avl
 * - [2] https://github.com/DanielGibson/Snippets
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_UHASH_TYPE1
#define HEADER_INCLUDED_UHASH_TYPE1 1

#include "type0.h"

#define _UHASH_NAME_NODE__TYPE1(user_t, key_t, value_t) \
	typedef struct UHASH_NAME(user_t, node) { \
		key_t        key; \
		UHASH_IDX_T  left, right; \
		int          depth; \
		value_t      value; \
	} UHASH_NAME(user_t, node);

#define _UHASH_NAMEIMPL__TYPE1(user_t) \
	_UHASH_NAMEIMPL__TYPE0(user_t)


#define _UHASH_PROC_KEY__TYPE1(user_t, key_t) \
	_UHASH_PROC_KEY__TYPE0(user_t, key_t)


#define _UHASH_PROC_VALUE__TYPE1(user_t, value_t) \
	static CC_FORCE_INLINE \
	value_t \
	UHASH_PROC_INT(user_t, value) (const user_t * hash, const UHASH_NAME(user_t, node) * node) { \
		return node->value; \
	} \
	\
	static \
	const value_t * \
	UHASH_PROC(user_t, value) (const user_t * hash, UHASH_IDX_T node_index) { \
		const UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, cnode, hash, node_index); \
		if (!node) return NULL; \
		return &(node->value); \
	} \
	\
	static CC_FORCE_INLINE \
	void \
	UHASH_PROC_INT(user_t, set_value) (user_t * hash, UHASH_NAME(user_t, node) * node, value_t value) { \
		node->value = value; \
	} \
	\
	static \
	void \
	UHASH_PROC(user_t, set_value) (user_t * hash, UHASH_IDX_T node_index, value_t value) { \
		UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, node, hash, node_index); \
		if (!node) return; \
		UHASH_CALL_INT(user_t, set_value, hash, node, value); \
	}


#define _UHASH_PROC__INIT_NODE__TYPE1(user_t, key_t, value_t) \
	static CC_FORCE_INLINE \
	void \
	UHASH_PROC_INT(user_t, init_node) (user_t * hash, UHASH_NAME(user_t, node) * node, key_t key, value_t value) { \
		node->depth = 1; \
		UHASH_CALL_INT(user_t, set_key, hash, node, key); \
		UHASH_CALL_INT(user_t, set_value, hash, node, value); \
	}

#define _UHASH_PROC_INIT__TYPE1(user_t) \
	_UHASH_PROC_INIT__TYPE0(user_t)

#define _UHASH_PROC_FREE__TYPE1(user_t) \
	_UHASH_PROC_FREE__TYPE0(user_t)


#define _UHASH_PROC_SEARCH__TYPE1(user_t, key_t) \
	_UHASH_PROC_SEARCH__TYPE0(user_t, key_t)

#define _UHASH_PROC_INSERT__TYPE1(user_t, key_t, value_t) \
	static \
	UHASH_IDX_T \
	UHASH_PROC(user_t, insert) (user_t * hash, key_t key, value_t value) \
		_UHASH_PROCIMPL_INSERT(user_t, 0) \
	\
	static \
	UHASH_IDX_T \
	UHASH_PROC(user_t, insert_strict) (user_t * hash, key_t key, value_t value) \
		_UHASH_PROCIMPL_INSERT(user_t, 1) \
	\
	static \
	UHASH_IDX_T \
	UHASH_PROC(user_t, insert_ex) (user_t * hash, key_t key, value_t value, int strict) \
		_UHASH_PROCIMPL_INSERT(user_t, strict)


#define UHASH_DEFINE_TYPE1(user_t, key_t, value_t) \
	_UHASH_NAMEPROC_KEY_VISITOR(user_t, key_t) \
	_UHASH_NAMEPROC_VALUE_VISITOR(user_t, value_t) \
	_UHASH_NAMEPROC_CMP_KEY_PLAIN(user_t, key_t) \
	\
	_UHASH_NAME_NODE__TYPE1(user_t, key_t, value_t) \
	UVECTOR_DEFINE_TYPE0(UVECTOR_NAME(user_t, v_idx),  UHASH_IDX_T, UHASH_IDX_T) \
	UVECTOR_DEFINE_TYPE1(UVECTOR_NAME(user_t, v_node), UHASH_IDX_T, UHASH_NAME(user_t, node)) \
	typedef struct { \
		_UHASH_NAMEIMPL__TYPE1(user_t) \
	} user_t; \
	\
	_UHASH_PROC_NODE(user_t) \
	_UHASH_PROC_KEY__TYPE1(user_t, key_t) \
	_UHASH_PROC_VALUE__TYPE1(user_t, value_t) \
	\
	_UHASH_PROC__INIT_NODE__TYPE1(user_t, key_t, value_t) \
	_UHASH_PROC_INIT__TYPE1(user_t) \
	_UHASH_PROC_FREE__TYPE1(user_t) \
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
	_UHASH_PROC_SEARCH__TYPE1(user_t, key_t) \
	_UHASH_PROC_INSERT__TYPE1(user_t, key_t, value_t) \


#endif /* HEADER_INCLUDED_UHASH_TYPE1 */
