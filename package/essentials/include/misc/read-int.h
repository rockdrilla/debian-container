/* read_{int}_{from}: read integers from different sources
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_READ_INT
#define HEADER_INCLUDED_READ_INT 1

#include "ext-c-begin.h"

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "../misc/cc-inline.h"
#include "../misc/strfun.h"
#include "../num/minmax.h"

#define _READINT_DEFINE_BASE_FUNC(n, t, tdefault, f) \
	static \
	t read_ ## n ## _str (int base, const char * string) { \
		char buf[128]; \
		size_t len; \
		t result = (tdefault); \
		if (!string) return result; \
		len = strlen(string); \
		string = trim_whitespace_ro(string, &len); \
		len = min(len, sizeof(buf) - 1); \
		strncpy(buf, string, len); \
		buf[len] = 0; \
		errno = 0; \
		result = f(buf, NULL, base); \
		if (errno) result = tdefault; \
		return result; \
	}

_READINT_DEFINE_BASE_FUNC( long,          long,  LONG_MIN, strtol)
_READINT_DEFINE_BASE_FUNC(ulong, unsigned long, ULONG_MAX, strtoul)

_READINT_DEFINE_BASE_FUNC( llong,          long long,  LLONG_MIN, strtoll)
_READINT_DEFINE_BASE_FUNC(ullong, unsigned long long, ULLONG_MAX, strtoull)

#if INT_MAX != LONG_MAX

static
CC_FORCE_INLINE
int read_int_str(int base, const char * string) {
	int result = INT_MIN;
	long tmp = read_long_str(base, string);
	if (errno != 0) return result;
	if (tmp < INT_MIN) return INT_MIN;
	if (tmp > INT_MAX) return INT_MAX;
	return (int) tmp;
}

static
CC_FORCE_INLINE
unsigned int read_uint_str(int base, const char * string) {
	int result = UINT_MAX;
	long tmp = read_ulong_str(base, string);
	if (errno != 0) return result;
	if (tmp > UINT_MAX) return UINT_MAX;
	return (unsigned int) tmp;
}

#else /* INT_MAX == LONG_MAX */

static
CC_FORCE_INLINE
int read_int_str(int base, const char * string) {
	return read_long_str(base, string);
}

static
CC_FORCE_INLINE
unsigned int read_uint_str(int base, const char * string) {
	return read_ulong_str(base, string);
}

#endif /* INT_MAX != LONG_MAX */

/* _read_*_fd is kinda "private" due to "inaccurate" reads */

#define _READINT_DEFINE_FUNC(n, t, tdefault) \
	static \
	t _read_ ## n ## _fd (int base, int fd) { \
		t result = (tdefault); \
		char buf[128]; \
		ssize_t nread; \
		if (fd < 0) return result; \
		if (base < 3) return result; \
		nread = read(fd, buf, sizeof(buf) - 1); \
		if (nread <= 0) return result; \
		buf[nread] = 0; \
		return read_ ## n ## _str (base, buf); \
	} \
	static \
	t read_ ## n ## _file (int base, const char * filepath) { \
		t result = (tdefault); \
		int fd, err; \
		if (!filepath) return result; \
		if (base < 3) return result; \
		fd = open(filepath, O_RDONLY); \
		if (fd < 0) return result; \
		result = _read_  ## n ## _fd (base, fd); \
		err = errno; \
		close(fd); \
		errno = err; \
		return result; \
	} \
	static \
	t read_ ## n ## _at_file (int base, int dir_fd, const char * filepath) { \
		t result = (tdefault); \
		int fd, err; \
		if (dir_fd < 0) return result; \
		if (!filepath) return result; \
		if (base < 3) return result; \
		fd = openat(dir_fd, filepath, O_RDONLY); \
		if (fd < 0) return result; \
		result = _read_  ## n ## _fd (base, fd); \
		err = errno; \
		close(fd); \
		errno = err; \
		return result; \
	}

_READINT_DEFINE_FUNC( int,          int,  INT_MIN)
_READINT_DEFINE_FUNC(uint, unsigned int, UINT_MAX)

_READINT_DEFINE_FUNC( long,          long,  LONG_MIN)
_READINT_DEFINE_FUNC(ulong, unsigned long, ULONG_MAX)

_READINT_DEFINE_FUNC( llong,          long long,  LLONG_MIN)
_READINT_DEFINE_FUNC(ullong, unsigned long long, ULLONG_MAX)

#include "ext-c-end.h"

#endif /* HEADER_INCLUDED_READ_INT */
