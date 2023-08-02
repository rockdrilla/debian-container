/* uvector: dynamic array
 *
 * - uvector "str": "contiguous" string stream
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_UVECTOR_STR
#define HEADER_INCLUDED_UVECTOR_STR

#include "type0.h"

UVECTOR_DEFINE_TYPE0(ptroff_v, unsigned int, size_t)

typedef struct {
	char     * ptr;
	size_t     used, allocated;
	ptroff_v   offsets;
} string_v;

static
void
UVECTOR_PROC(string_v, init) (string_v * vector)
{
	(void) memset(vector, 0, sizeof(string_v));
	UVECTOR_CALL(ptroff_v, init, &(vector->offsets));
}

static
void
UVECTOR_PROC(string_v, free) (string_v * vector)
{
	UVECTOR_CALL(ptroff_v, free, &(vector->offsets));
	memfun_free(vector->ptr, vector->used);
	(void) memset(vector, 0, sizeof(string_v));
}

static
int
UVECTOR_PROC(string_v, dup) (string_v * destination, const string_v * source)
{
	UVECTOR_CALL(string_v, init, destination);
	destination->ptr = (char *) memfun_alloc(source->used);
	if (!destination->ptr) return 0;

	if (!UVECTOR_CALL(ptroff_v, dup, &(destination->offsets), &(source->offsets))) {
		UVECTOR_CALL(string_v, free, destination);
		return 0;
	}

	(void) memcpy(destination->ptr, source->ptr, source->used);
	destination->allocated = source->allocated;
	destination->used      = source->used;

	return 1;
}

static
CC_FORCE_INLINE
unsigned int
UVECTOR_PROC(string_v, count) (const string_v * vector)
{
	return vector->offsets.used;
}

static
const char *
UVECTOR_PROC_INT(string_v, get) (const string_v * vector, unsigned int index)
{
	return (const char *) memfun_ptr_offset(vector->ptr, UVECTOR_CALL(ptroff_v, get_by_val, &(vector->offsets), index));
}

static
const char *
UVECTOR_PROC(string_v, get) (const string_v * vector, unsigned int index)
{
	if (index >= vector->offsets.used) return NULL;

	return UVECTOR_CALL_INT(string_v, get, vector, index);
}

static
unsigned int
UVECTOR_PROC(string_v, append_fixed) (string_v * vector, const char * string, unsigned int length)
{
	size_t new_used = roundbyl(vector->used + length + 1, sizeof(size_t));
	if (new_used > vector->allocated) {
		void * nptr = memfun_realloc_ex(vector->ptr, &(vector->allocated), length + 1);
		if (!nptr) return UVECTOR_NAME(ptroff_v, idx_inv);

		vector->ptr = (char *) nptr;
	}

	unsigned int idx = UVECTOR_CALL(ptroff_v, append_by_val, &(vector->offsets), vector->used);
	if (UVECTOR_CALL(ptroff_v, is_inv, idx))
		return idx;

	memcpy(memfun_ptr_offset(vector->ptr, vector->used), string, length);
	vector->used = new_used;

	return idx;
}

static
CC_FORCE_INLINE
unsigned int
UVECTOR_PROC(string_v, append) (string_v * vector, const char * string)
{
	return UVECTOR_CALL(string_v, append_fixed, vector, string, (string) ? strlen(string) : 0);
}

static
unsigned int
UVECTOR_PROC(string_v, copy_range) (string_v * destination, const string_v * source, unsigned int begin, unsigned int count)
{
	if (begin >= source->offsets.used) return 0;

	unsigned int end = begin + count;
	if (end > source->offsets.used) {
		count = source->offsets.used - begin;
		end = source->offsets.used;
	}

	UVECTOR_CALL(string_v, init, destination);
	for (unsigned int i = begin; i < end; i++) {
		UVECTOR_CALL(string_v, append, destination, UVECTOR_CALL(string_v, get, source, i));
	}

	return count;
}

static
const char * const *
UVECTOR_PROC(string_v, to_ptrlist) (const string_v * vector)
{
	const char ** ptrlist;
	ptrlist = (const char **) memfun_alloc((vector->offsets.used + 1) * sizeof(char *));
	if (!ptrlist) return NULL;

	for (unsigned int i = 0; i < vector->offsets.used; i++) {
		ptrlist[i] = UVECTOR_CALL_INT(string_v, get, vector, i);
	}

	return (const char * const *) ptrlist;
}

#endif /* HEADER_INCLUDED_UVECTOR_STR */
