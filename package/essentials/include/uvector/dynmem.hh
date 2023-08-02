/* uvector: dynamic array (c++-like version)
 *
 * - dynamic memory allocation
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_UVECTOR_DYNMEM_HH
#define HEADER_INCLUDED_UVECTOR_DYNMEM_HH 1

#include "base.hh"

namespace uvector {

template<typename value_t, typename index_t = size_t, unsigned int growth_factor = 0>
struct dynmem {

protected:

	using _base = base<value_t, index_t, growth_factor>;
	using value_align_t = typename _base::value_align_t;

	static constexpr size_t  item_size  = _base::item_size;
	static constexpr size_t  align_size = _base::align_size;
	static constexpr size_t  growth     = _base::growth;
	static constexpr index_t idx_max    = _base::idx_max;
	static constexpr index_t idx_inv    = _base::idx_inv;
	static constexpr int     idx_bits   = _base::idx_bits;

	index_t _used = 0, _allocated = 0;
	value_align_t * _ptr = nullptr;

	CC_FORCE_INLINE
	void _flush_self(void)
	{
		(void) memset(this, 0, sizeof(*this));
	}

	CC_FORCE_INLINE
	const value_t * _get_ptr(index_t index)
	const {
		return (const value_t *) memfun_ptr_offset_ex(_ptr, align_size, index);
	}

	CC_FORCE_INLINE
	const value_t & _get_val(index_t index)
	const {
		return _ptr[index]._.value;
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

	int _grow_by_bytes(size_t bytes)
	{
		size_t _new = offset_of(_allocated);
		auto nptr = memfun_t_realloc_ex(_ptr, &_new, bytes);
		if ((!nptr) || (!_new)) return 0;

		size_t _alloc = _new / align_size;
		_allocated = (_alloc < idx_max) ? _alloc : idx_max;

		if (_ptr == nptr) return 1;

		_ptr = nptr;
		return 2;
	}

	int _grow_by_count(index_t count)
	{
		size_t _new = 0;
		if (is_wfall(_allocated)) {
			if (!uaddl(_allocated, count, &_new))
				return 0;
		}
		else
			_new = _allocated + count;

		if (is_inv(_new)) return 0;

		return _grow_by_bytes(offset_of(count));
	}

public:

	static
	CC_FORCE_INLINE
	size_t offset_of(index_t index)
	{
		return _base::offset_of(index);
	}

	static
	CC_FORCE_INLINE
	bool is_inv(index_t index)
	{
		return _base::is_inv(index);
	}

	static
	CC_FORCE_INLINE
	bool is_wfall(index_t index)
	{
		return _base::is_wfall(index);
	}

	dynmem()
	{
		_flush_self();
	}

	template<unsigned int source_growth>
	dynmem(const dynmem<value_t, index_t, source_growth> & source)
	{
		_flush_self();

		if (!grow_by_count(source.used()))
			return;

		_used = source.used();
		if (_used)
			(void) memcpy(_ptr, source.get(0), offset_of(_used));
	}

	dynmem(index_t reserve_count)
	{
		_flush_self();
		grow_by_count(reserve_count);
	}

	dynmem & operator = (const dynmem & other) = default;

	void free(void)
	{
		memfun_t_free(_ptr, offset_of(_used));
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
		return _allocated;
	}

	const value_t * get(index_t index)
	const {
		return (index < used()) ? _get_ptr(index) : nullptr;
	}

	bool set(index_t index, const value_t * source) {
		return (index < used()) ? _set_ptr(index, source) : false;
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
		return (grow_auto()) ? _append(source) : idx_inv;
	}

	index_t append(const value_t & source)
	{
		return (grow_auto()) ? _append(&source) : idx_inv;
	}

	template<unsigned int source_growth>
	index_t append(const dynmem<value_t, index_t, source_growth> & source, index_t begin, index_t count)
	{
		if (begin >= source.used()) return 0;

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

	int grow_by_bytes(size_t bytes)
	{
		if (!bytes) return 0;
		if (idx_max < allocated()) return 0;

		return _grow_by_bytes(bytes);
	}

	int grow_by_count(index_t count)
	{
		if (!count) return 0;
		if (is_wfall(count)) return 0;
		if (allocated() >= idx_max) return 0;

		return _grow_by_count(count);
	}

	int grow_auto(void)
	{
		return (used() < allocated()) ? 1 : grow_by_bytes(growth);
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

#endif /* HEADER_INCLUDED_UVECTOR_DYNMEM_HH */
