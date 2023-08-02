/* uvector: dynamic array (c++-like version)
 *
 * - "in-place" static allocation
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_UVECTOR_INPLACE_HH
#define HEADER_INCLUDED_UVECTOR_INPLACE_HH 1

#include "base.hh"
#include "dynmem.hh"

#include "../num/minmax.h"

namespace uvector {

template<typename value_t, typename index_t = size_t, index_t max_elements = 0>
struct inplace {

protected:

	using _base = base<value_t, index_t>;
	using value_align_t = typename _base::value_align_t;

	static constexpr size_t  item_size  = _base::item_size;
	static constexpr size_t  align_size = _base::align_size;
	static constexpr index_t idx_max    = (max_elements < _base::idx_max) ? max_elements : _base::idx_max;
	static constexpr index_t idx_inv    = _base::idx_inv;

	index_t       _used = 0;
	value_align_t _arr[idx_max];

	CC_FORCE_INLINE
	void _flush_self(void)
	{
		memset(this, 0, sizeof(*this));
	}

	CC_FORCE_INLINE
	const value_t * _get_ptr(index_t index)
	const {
		return (const value_t *) &(_arr[index]);
	}

	CC_FORCE_INLINE
	const value_t & _get_val(index_t index)
	const {
		return _arr[index]._.value;
	}

	CC_INLINE
	bool _set_ptr(index_t index, const value_t * source)
	{
		auto item = (value_t *) _get_ptr(index);
		if (!item) return false;

		if (source)
			(void) memcpy(item, source, item_size);
		else
			(void) memset(item, 0, item_size);
		return true;
	}

	CC_INLINE
	index_t _append(const value_t * source)
	{
		return (_set_ptr(_used, source)) ? (_used++) : idx_inv;
	}

public:

	static
	CC_FORCE_INLINE
	bool is_inv(index_t index)
	{
		return (idx_max < index);
	}

	static
	CC_FORCE_INLINE
	bool is_wfall(index_t index)
	{
		return false;
	}

	inplace()
	{
		_flush_self();
	}

	template<index_t source_max>
	inplace(const inplace<value_t, index_t, source_max> * source)
	{
		_flush_self();
		if (!source) return;

		_used = min(idx_max, source->used());
		if (_used)
			(void) memcpy(_arr, source->get(0), _base::offset_of(_used));
	}

	template<unsigned int source_growth>
	inplace(const dynmem<value_t, index_t, source_growth> & source)
	{
		_flush_self();

		_used = min(idx_max, source.used());
		if (_used)
			(void) memcpy(_arr, (void *) source.get(0), _base::offset_of(_used));
	}

	inplace & operator = (const inplace & other) = default;

	void free(void)
	{
		_flush_self();
	}

	CC_FORCE_INLINE
	index_t used(void)
	const {
		return _used;
	}

	CC_FORCE_INLINE
	index_t allocated(void)
	const {
		return idx_max;
	}

	CC_FORCE_INLINE
	const value_t * get(index_t index)
	const {
		return (index < used()) ? _get_ptr(index) : nullptr;
	}

	bool set(index_t index, const value_t * source)
	{
		return (index < used()) ? _set_ptr(index, &source) : false;
	}

	const value_t get_val(index_t index)
	const {
		if (index < used())
			return _get_val(index);

		value_t _default[1] = {};
		return _default[0];
	}

	const value_t get_val(index_t index, const value_t & fallback)
	const {
		return (index < used()) ? _get_val(index) : fallback;
	}

	bool set(index_t index, const value_t & source)
	{
		return (index < used()) ? _set_ptr(index, &source) : false;
	}

	index_t append(const value_t * source)
	{
		return (used() < idx_max) ? _append(source) : idx_inv;
	}

	index_t append(const value_t & source)
	{
		return (used() < idx_max) ? _append(&source) : idx_inv;
	}

	template<index_t source_max>
	index_t append(const inplace<value_t, index_t, source_max> * source, index_t begin, index_t count)
	{
		if (!source) return 0;
		if (source->used() < begin) return 0;

		index_t end = source->used();
		end = min(end, begin + count);
		count = end - begin;

		index_t i, k = idx_inv;
		for (i = begin; i < end; i++) {
			k = append(source->get(i));
			if (is_inv(k)) break;
		}

		if (is_inv(k)) count = i - begin;
		return count;
	}

	template<index_t source_max>
	index_t append(const inplace<value_t, index_t, source_max> * source)
	{
		return append(source, 0, source->used());
	}

	template<unsigned int source_growth>
	index_t append(const dynmem<value_t, index_t, source_growth> & source, index_t begin, index_t count)
	{
		if (source.used() < begin) return 0;

		index_t end = source.used();
		end = min(end, begin + count);
		count = end - begin;

		index_t i, k = idx_inv;
		for (i = begin; i < end; i++) {
			k = append(source.get(i));
			if (is_inv(k)) break;
		}

		if (is_inv(k)) count = i - begin;
		return count;
	}

	template<unsigned int source_growth>
	index_t append(const dynmem<value_t, index_t, source_growth> & source)
	{
		return append(source, 0, source.used());
	}

	index_t walk(bool (*visitor)(index_t, const value_t *))
	const {
		index_t i = 0;
		for (; i < used(); i++) {
			if (!visitor(i, get(i))) break;
		}
		return i;
	}

	template<typename T = void>
	index_t walk(bool (*visitor)(index_t, const value_t *, T *), T * state)
	const {
		index_t i = 0;
		for (; i < used(); i++) {
			if (!visitor(i, get(i), state)) break;
		}
		return i;
	}

	index_t rwalk(bool (*visitor)(index_t, const value_t *))
	const {
		index_t i = used();
		while ((i--)) {
			if (!visitor(i, get(i))) break;
		}
		return i;
	}

	template<typename T = void>
	index_t rwalk(bool (*visitor)(index_t, const value_t *, T *), T * state)
	const {
		index_t i = used();
		while ((i--)) {
			if (!visitor(i, get(i), state)) break;
		}
		return i;
	}

};

} /* namespace uvector */

#endif /* HEADER_INCLUDED_UVECTOR_INPLACE_HH */
