/* uhash: simple grow-only hash
 *
 * - uhash "type 0": key is "scalar", no value
 *
 * refs:
 * - [1] https://github.com/etherealvisage/avl
 * - [2] https://github.com/DanielGibson/Snippets
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_UHASH_TYPE0
#define HEADER_INCLUDED_UHASH_TYPE0 1

#include "common.h"

#define _UHASH_NAME_NODE__TYPE0(user_t, key_t) \
	typedef struct UHASH_NAME(user_t, node) { \
		key_t        key; \
		UHASH_IDX_T  left, right; \
		int          depth; \
	} UHASH_NAME(user_t, node);

#define _UHASH_NAMEIMPL__TYPE0(user_t) \
	UVECTOR_NAME(user_t, v_node)   nodes; \
	UHASH_NAME(user_t, key_cmp)    key_comparator; \
	UHASH_IDX_T                    tree_root;


#define _UHASH_PROC_KEY__TYPE0(user_t, key_t) \
	static CC_FORCE_INLINE \
	key_t \
	UHASH_PROC_INT(user_t, key) (const user_t * hash, const UHASH_NAME(user_t, node) * node) { \
		return node->key; \
	} \
	\
	static \
	const key_t * \
	UHASH_PROC(user_t, key) (const user_t * hash, UHASH_IDX_T node_index) { \
		const UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, cnode, hash, node_index); \
		if (!node) return NULL; \
		return &(node->key); \
	} \
	\
	static CC_FORCE_INLINE \
	void \
	UHASH_PROC_INT(user_t, set_key) (user_t * hash, UHASH_NAME(user_t, node) * node, key_t key) { \
		node->key = key; \
	} \
	\
	static \
	void \
	UHASH_PROC(user_t, set_key) (user_t * hash, UHASH_IDX_T node_index, key_t key) { \
		UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, node, hash, node_index); \
		if (!node) return; \
		UHASH_CALL_INT(user_t, set_key, hash, node, key); \
	}


#define _UHASH_PROC__INIT_NODE__TYPE0(user_t, key_t) \
	static CC_FORCE_INLINE \
	void \
	UHASH_PROC_INT(user_t, init_node) (user_t * hash, UHASH_NAME(user_t, node) * node, key_t key, int value) { \
		node->depth = 1; \
		UHASH_CALL_INT(user_t, set_key, hash, node, key); \
	}

#define _UHASH_PROCIMPL_INIT__TYPE0(user_t) \
	{ \
	memset(hash, 0, sizeof(user_t)); \
	UHASH_VCALL(user_t, v_node, init, &(hash->nodes)); \
	}

#define _UHASH_PROC_INIT__TYPE0(user_t) \
	static \
	void \
	UHASH_PROC(user_t, init) (user_t * hash) \
		_UHASH_PROCIMPL_INIT__TYPE0(user_t)

#define _UHASH_PROCIMPL_FREE__TYPE0(user_t) \
	{ \
	UHASH_VCALL(user_t, v_node, free, &(hash->nodes)); \
	memset(hash, 0, sizeof(user_t)); \
	}

#define _UHASH_PROC_FREE__TYPE0(user_t) \
	static \
	void \
	UHASH_PROC(user_t, free) (user_t * hash) \
		_UHASH_PROCIMPL_FREE__TYPE0(user_t)


#define _UHASH_PROC_SEARCH__TYPE0(user_t, key_t) \
	static \
	UHASH_IDX_T \
	UHASH_PROC(user_t, search) (user_t * hash, key_t key) \
		_UHASH_PROCIMPL_SEARCH(user_t)

#define _UHASH_PROC_INSERT__TYPE0(user_t, key_t) \
	static \
	UHASH_IDX_T \
	UHASH_PROC(user_t, insert) (user_t * hash, key_t key) { \
		const int value = 0; \
		_UHASH_PROCIMPL_INSERT(user_t, 0) \
	} \
	\
	static \
	UHASH_IDX_T \
	UHASH_PROC(user_t, insert_strict) (user_t * hash, key_t key) { \
		const int value = 0; \
		_UHASH_PROCIMPL_INSERT(user_t, 1) \
	} \
	\
	static \
	UHASH_IDX_T \
	UHASH_PROC(user_t, insert_ex) (user_t * hash, key_t key, int strict) { \
		const int value = 0; \
		_UHASH_PROCIMPL_INSERT(user_t, strict) \
	}


#define UHASH_DEFINE_TYPE0(user_t, key_t) \
	_UHASH_NAMEPROC_KEY_VISITOR(user_t, key_t) \
	_UHASH_NAMEPROC_CMP_KEY_PLAIN(user_t, key_t) \
	\
	_UHASH_NAME_NODE__TYPE0(user_t, key_t) \
	UVECTOR_DEFINE_TYPE0(UVECTOR_NAME(user_t, v_idx),  UHASH_IDX_T, UHASH_IDX_T) \
	UVECTOR_DEFINE_TYPE1(UVECTOR_NAME(user_t, v_node), UHASH_IDX_T, UHASH_NAME(user_t, node)) \
	typedef struct { \
		_UHASH_NAMEIMPL__TYPE0(user_t) \
	} user_t; \
	\
	_UHASH_PROC_NODE(user_t) \
	_UHASH_PROC_KEY__TYPE0(user_t, key_t) \
	\
	_UHASH_PROC__INIT_NODE__TYPE0(user_t, key_t) \
	_UHASH_PROC_INIT__TYPE0(user_t) \
	_UHASH_PROC_FREE__TYPE0(user_t) \
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
	_UHASH_PROC_SEARCH__TYPE0(user_t, key_t) \
	_UHASH_PROC_INSERT__TYPE0(user_t, key_t) \


#endif /* HEADER_INCLUDED_UHASH_TYPE0 */
