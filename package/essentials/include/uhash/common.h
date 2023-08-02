/* uhash: simple grow-only hash
 *
 * - common definitions
 *
 * refs:
 * - [1] https://github.com/etherealvisage/avl
 * - [2] https://github.com/DanielGibson/Snippets
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_UHASH_COMMON
#define HEADER_INCLUDED_UHASH_COMMON 1

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#ifdef UHASH_IDX_T
#undef UHASH_IDX_T
#endif
#ifndef UHASH_FULL_WIDTH_INDICES
  #ifdef UHASH_SHORT_INDICES
	#define UHASH_IDX_T  uint16_t
  #else
	#define UHASH_IDX_T  uint32_t
  #endif
#else
  #define UHASH_IDX_T  size_t
#endif

#include "../misc/cc-inline.h"
#include "../misc/kustom.h"
#include "../uvector/uvector.h"

#define UHASH_NAME(t, k)  KUSTOM_NAME(uhash, t, k)
#define UHASH_PROC        KUSTOM_PROC
#define UHASH_CALL        KUSTOM_CALL
#define UHASH_PROC_INT    KUSTOM_PROC_INT
#define UHASH_CALL_INT    KUSTOM_CALL_INT

#define UHASH_VCALL(user_t, type_v, proc, ...) (UVECTOR_CALL(UVECTOR_NAME(user_t, type_v), proc, ##__VA_ARGS__))

#define UHASH_DEFINE_DEFAULT_KEY_COMPARATOR(key_t) \
	static \
	int \
	UHASH_NAME(key_t, cmp) (key_t k1, key_t k2) { \
		if (k1 == k2) return 0; \
		return (k1 > k2) ? 1 : -1; \
	}

#define UHASH_SET_KEY_COMPARATOR(hash, key_Cmp) \
	{ \
	(hash)->key_comparator = key_Cmp; \
	}

#define UHASH_SET_DEFAULT_KEY_COMPARATOR(hash, key_t) \
	UHASH_SET_KEY_COMPARATOR(hash, UHASH_NAME(key_t, cmp))

#define UHASH_SET_VALUE_HANDLERS(hash, value_Ctor, value_Dtor) \
	{ \
	(hash)->value_constructor = value_Ctor; \
	(hash)->value_destructor  = value_Dtor; \
	}

static const int _uhash_avl_left  = 0;
static const int _uhash_avl_right = 1;

static
CC_FORCE_INLINE
UHASH_IDX_T _uhash_idx_int(UHASH_IDX_T idx) { return (idx - 1); }

static
CC_FORCE_INLINE
UHASH_IDX_T _uhash_idx_pub(UHASH_IDX_T idx) { return (idx + 1); }

static const int _uhash_idx_t_width = sizeof(UHASH_IDX_T) * CHAR_BIT;
static const int _uhash_idx_t_bits_selector = 2;
static const int _uhash_idx_t_bits_truindex = _uhash_idx_t_width - _uhash_idx_t_bits_selector;

static const UHASH_IDX_T _uhash_idx_t_max = ~((UHASH_IDX_T) 0ULL) >> _uhash_idx_t_bits_selector;
static const UHASH_IDX_T _uhash_idx_t_mask_truindex = _uhash_idx_t_max;

#define _UHASH_SELECTOR_SELF   0
#define _UHASH_SELECTOR_LEFT   1
#define _UHASH_SELECTOR_RIGHT  2
#define _UHASH_SELECTOR_ROOT   3
#define _UHASH_SELECTOR_MASK   ((UHASH_IDX_T) 3)

static
CC_FORCE_INLINE
UHASH_IDX_T _uhash_idx_truindex(UHASH_IDX_T idx) { return idx &  _uhash_idx_t_mask_truindex; }

static
CC_FORCE_INLINE
UHASH_IDX_T _uhash_idx_selector(UHASH_IDX_T idx) { return idx >> _uhash_idx_t_bits_truindex; }

static
CC_FORCE_INLINE
UHASH_IDX_T uhash_node_rela_index(UHASH_IDX_T selector, UHASH_IDX_T truindex) {
	return _uhash_idx_truindex(truindex) | ((selector & _UHASH_SELECTOR_MASK) << _uhash_idx_t_bits_truindex);
}

#define _UHASH_NAMEPROC_KEY_VISITOR(user_t, key_t) \
	typedef int (* UHASH_NAME(user_t, key_proc) ) (key_t * key);

#define _UHASH_NAMEPROC_VALUE_VISITOR(user_t, value_t) \
	typedef int (* UHASH_NAME(user_t, value_proc) ) (value_t * value);

#define _UHASH_NAMEPROC_CMP_KEY_PLAIN(user_t, key_t) \
	typedef int (* UHASH_NAME(user_t, key_cmp) ) (key_t key1, key_t key2);

#define _UHASH_NAMEPROC_CMP_KEY_PTR(user_t, key_t) \
	typedef int (* UHASH_NAME(user_t, key_cmp) ) (const key_t * key1, const key_t * key2);

#define _UHASH_PROC_NODE(user_t) \
	static \
	CC_FORCE_INLINE \
	UHASH_NAME(user_t, node) * \
	UHASH_PROC_INT(user_t, node) (user_t * hash, UHASH_IDX_T index) { \
		return UHASH_VCALL(user_t, v_node, get_by_ptr, &(hash->nodes), _uhash_idx_int(index)); \
	} \
	\
	static \
	UHASH_NAME(user_t, node) * \
	UHASH_PROC(user_t, node) (user_t * hash, UHASH_IDX_T node_index) { \
		return (node_index) ? UHASH_CALL_INT(user_t, node, hash, node_index) : NULL; \
	} \
	static \
	CC_FORCE_INLINE \
	const UHASH_NAME(user_t, node) * \
	UHASH_PROC_INT(user_t, cnode) (const user_t * hash, UHASH_IDX_T index) { \
		return UHASH_VCALL(user_t, v_node, get_by_ptr, &(hash->nodes), _uhash_idx_int(index)); \
	} \
	\
	static \
	const UHASH_NAME(user_t, node) * \
	UHASH_PROC(user_t, cnode) (const user_t * hash, UHASH_IDX_T node_index) { \
		return (node_index) ? UHASH_CALL_INT(user_t, cnode, hash, node_index) : NULL; \
	}

#define _UHASH_PROC_RELA_INDEX(user_t) \
	static \
	UHASH_IDX_T * \
	UHASH_PROC_INT(user_t, rela_index) (user_t * hash, UHASH_IDX_T index) { \
		UHASH_IDX_T selector = _uhash_idx_selector(index); \
		switch (selector) { \
		case _UHASH_SELECTOR_ROOT: \
			return &(hash->tree_root); \
		} \
		UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, node, hash, _uhash_idx_truindex(index)); \
		if (!node) return NULL; \
		switch (selector) { \
		case _UHASH_SELECTOR_LEFT: \
			return &(node->left); \
		case _UHASH_SELECTOR_RIGHT: \
			return &(node->right); \
		} \
		return NULL; \
	}

#define _UHASH_PROC_RELA_NODE(user_t) \
	static \
	const UHASH_NAME(user_t, node) * \
	UHASH_PROC(user_t, rela_node) (const user_t * hash, UHASH_IDX_T index) { \
		UHASH_IDX_T selector = _uhash_idx_selector(index); \
		switch (selector) { \
		case _UHASH_SELECTOR_ROOT: \
			return UHASH_CALL(user_t, cnode, hash, hash->tree_root); \
		} \
		const UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, cnode, hash, _uhash_idx_truindex(index)); \
		if (!node) return NULL; \
		switch (selector) { \
		case _UHASH_SELECTOR_LEFT: \
			return UHASH_CALL(user_t, cnode, hash, node->left); \
		case _UHASH_SELECTOR_RIGHT: \
			return UHASH_CALL(user_t, cnode, hash, node->right); \
		} \
		return node; \
	}

#define _UHASH_PROC_LEFT(user_t) \
	static \
	UHASH_IDX_T \
	UHASH_PROC(user_t, left) (const user_t * hash, UHASH_IDX_T node_index) { \
		const UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, cnode, hash, node_index); \
		return (node) ? node->left : 0; \
	}

#define _UHASH_PROC_RIGHT(user_t) \
	static \
	UHASH_IDX_T \
	UHASH_PROC(user_t, right) (const user_t * hash, UHASH_IDX_T node_index) { \
		const UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, cnode, hash, node_index); \
		return (node) ? node->right : 0; \
	}

#define _UHASH_PROC_DEPTH(user_t) \
	static \
	int \
	UHASH_PROC(user_t, depth) (const user_t * hash, UHASH_IDX_T node_index) { \
		const UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, cnode, hash, node_index); \
		return (node) ? node->depth : 0; \
	}

#define _UHASH_PROC_TREE_DEPTH(user_t) \
	static \
	int \
	UHASH_PROC(user_t, tree_depth) (const user_t * hash) { \
		return UHASH_CALL(user_t, depth, hash, hash->tree_root); \
	}

#define _UHASH_PROC_BALANCE_FACTOR(user_t) \
	static \
	int \
	UHASH_PROC(user_t, balance_factor) (const user_t * hash, UHASH_IDX_T node_index) { \
		const UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, cnode, hash, node_index); \
		if (!node) return 0; \
		int d_left  = UHASH_CALL(user_t, depth, hash, node->left); \
		int d_right = UHASH_CALL(user_t, depth, hash, node->right); \
		return (d_left - d_right); \
	}

#define _UHASH_PROC_UPDATE_DEPTH(user_t) \
	static \
	void \
	UHASH_PROC_INT(user_t, update_depth) (user_t * hash, UHASH_IDX_T node_index) { \
		UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, node, hash, node_index); \
		int d_left  = UHASH_CALL(user_t, depth, hash, node->left); \
		int d_right = UHASH_CALL(user_t, depth, hash, node->right); \
		if (d_left) \
			node->depth = d_left; \
		if (d_right) \
			if (node->depth < d_right) \
				node->depth = d_right; \
		node->depth++; \
	}

#define _UHASH_PROC_ROTATE_LEFT(user_t) \
	static \
	void \
	UHASH_PROC_INT(user_t, rotate_left) (user_t * hash, UHASH_IDX_T node_index) { \
		UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, node, hash, node_index); \
		UHASH_NAME(user_t, node) * left = UHASH_CALL(user_t, node, hash, node->left); \
		UHASH_IDX_T i = left->right; \
		UHASH_NAME(user_t, node) * x = UHASH_CALL(user_t, node, hash, i); \
		left->right = x->left; \
		x->left = node->left; \
		UHASH_CALL_INT(user_t, update_depth, hash, node->left); \
		node->left = i; \
		UHASH_CALL_INT(user_t, update_depth, hash, node->left); \
	}

#define _UHASH_PROC_ROTATE_RIGHT(user_t) \
	static \
	void \
	UHASH_PROC_INT(user_t, rotate_right) (user_t * hash, UHASH_IDX_T node_index) { \
		UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, node, hash, node_index); \
		UHASH_NAME(user_t, node) * right = UHASH_CALL(user_t, node, hash, node->right); \
		UHASH_IDX_T i = right->left; \
		UHASH_NAME(user_t, node) * x = UHASH_CALL(user_t, node, hash, i); \
		right->left = x->right; \
		x->right = node->right; \
		UHASH_CALL_INT(user_t, update_depth, hash, node->right); \
		node->right = i; \
		UHASH_CALL_INT(user_t, update_depth, hash, node->right); \
	}

#define _UHASH_PROC_ROTATE(user_t) \
	static \
	void \
	UHASH_PROC_INT(user_t, rotate) (user_t * hash, UHASH_IDX_T * node_index_ptr, int direction) { \
		UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, node, hash, *node_index_ptr); \
		UHASH_IDX_T i; \
		UHASH_NAME(user_t, node) * x; \
		if (direction == _uhash_avl_left) { \
			i = node->right; \
			x = UHASH_CALL(user_t, node, hash, i); \
			node->right = x->left; \
			x->left = *node_index_ptr; \
		} \
		else \
		if (direction == _uhash_avl_right) { \
			i = node->left; \
			x = UHASH_CALL(user_t, node, hash, i); \
			node->left = x->right; \
			x->right = *node_index_ptr; \
		} \
		else \
			return; \
		UHASH_CALL_INT(user_t, update_depth, hash, *node_index_ptr); \
		UHASH_CALL_INT(user_t, update_depth, hash, i); \
		*node_index_ptr = i; \
	}

#define _UHASH_PROC_REBALANCE(user_t) \
	static \
	void \
	UHASH_PROC_INT(user_t, rebalance) (user_t * hash, UHASH_IDX_T * node_index_ptr) { \
		UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, node, hash, *node_index_ptr); \
		int delta = UHASH_CALL(user_t, balance_factor, hash, *node_index_ptr); \
		if (delta > 1) { \
			if (UHASH_CALL(user_t, balance_factor, hash, node->left) < 0) \
				UHASH_CALL_INT(user_t, rotate_left, hash, *node_index_ptr); \
			\
			UHASH_CALL_INT(user_t, rotate, hash, node_index_ptr, _uhash_avl_right); \
		} \
		else \
		if (delta < -1) { \
			if (UHASH_CALL(user_t, balance_factor, hash, node->right) > 0) \
				UHASH_CALL_INT(user_t, rotate_right, hash, *node_index_ptr); \
			\
			UHASH_CALL_INT(user_t, rotate, hash, node_index_ptr, _uhash_avl_left); \
		} \
	}


#define _UHASH_PROCIMPL_SEARCH(user_t) \
	{ \
		UHASH_IDX_T idx = hash->tree_root; \
		while (idx) { \
			UHASH_NAME(user_t, node) * node = UHASH_CALL(user_t, node, hash, idx); \
			if (!node) return 0; \
			int cmp = hash->key_comparator(key, UHASH_CALL_INT(user_t, key, hash, node)); \
			if (!cmp) \
				return idx; \
			if (cmp > 0) \
				idx = node->right; \
			else \
				idx = node->left; \
		} \
		return 0; \
	}

#define _UHASH_PROCIMPL_INSERT(user_t, strict) \
	{ \
		if (hash->nodes.used == _uhash_idx_t_max) \
			return 0; \
		UHASH_IDX_T idx_rela = uhash_node_rela_index(_UHASH_SELECTOR_ROOT, 0); \
		UHASH_IDX_T * node_index_ptr; \
		UHASH_NAME(user_t, node) * node; \
		int cmp; \
		UVECTOR_NAME(user_t, v_idx) branch; \
		UHASH_VCALL(user_t, v_idx, init_ex, &branch, 1); \
		while (1) { \
			node_index_ptr = UHASH_CALL_INT(user_t, rela_index, hash, idx_rela); \
			if (!(*node_index_ptr)) { \
				UHASH_IDX_T i = UHASH_VCALL(user_t, v_node, append_by_ptr, &(hash->nodes), NULL); \
				if (UHASH_VCALL(user_t, v_node, is_inv, i)) break; \
				node_index_ptr = UHASH_CALL_INT(user_t, rela_index, hash, idx_rela); \
				idx_rela = *node_index_ptr = _uhash_idx_pub(i); \
				node = UHASH_VCALL(user_t, v_node, get_by_ptr, &(hash->nodes), i); \
				UHASH_CALL_INT(user_t, init_node, hash, node, key, value); \
				break; \
			} \
			node = UHASH_CALL(user_t, node, hash, *node_index_ptr); \
			cmp = hash->key_comparator(key, UHASH_CALL_INT(user_t, key, hash, node)); \
			if (!cmp) { \
				UHASH_VCALL(user_t, v_idx, free, &branch); \
				return (strict) ? 0 : *node_index_ptr; \
			} \
			UHASH_VCALL(user_t, v_idx, append_by_val, &branch, idx_rela); \
			if (cmp > 0) \
				idx_rela = uhash_node_rela_index(_UHASH_SELECTOR_RIGHT, *node_index_ptr); \
			else \
				idx_rela = uhash_node_rela_index(_UHASH_SELECTOR_LEFT, *node_index_ptr); \
		} \
		UHASH_IDX_T a; \
		UHASH_IDX_T * b; \
		for (UHASH_IDX_T i = branch.used; i; i--) { \
			a = UHASH_VCALL(user_t, v_idx, get_by_val, &branch, i - 1); \
			b = UHASH_CALL_INT(user_t, rela_index, hash, a); \
			UHASH_CALL_INT(user_t, rebalance, hash, b); \
			UHASH_CALL_INT(user_t, update_depth, hash, *b); \
		} \
		UHASH_VCALL(user_t, v_idx, free, &branch); \
		return idx_rela; \
	}

#endif /* HEADER_INCLUDED_UHASH_COMMON */
