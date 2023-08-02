/* log-stderr: print message to stderr
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_IO_LOG_STDERR
#define HEADER_INCLUDED_IO_LOG_STDERR 1

#include "../misc/ext-c-begin.h"

#include <ctype.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "../misc/cc-inline.h"
#include "../misc/strfun.h"
#include "../num/minmax.h"
#include "const.h"

#ifndef LOG_BUFFER_SIZE
#define LOG_BUFFER_SIZE  ((PATH_MAX) + 4096)
#endif

#if (LOG_BUFFER_SIZE) < 4096
#error too small log buffer size
#endif

static
void vlog_stderr(const char * prefix, const char * suffix, const char * fmt, va_list args)
__attribute__((format (printf, 3, 0)));

static
void vlog_stderr_error(const char * prefix, int error_num, const char * fmt, va_list args)
__attribute__((format (printf, 3, 0)));

static
void vlog_stderr_path_error(const char * prefix, const char * path_name, int error_num, const char * fmt, va_list args)
__attribute__((format (printf, 4, 0)));

static
void log_stderr(const char * fmt, ...)
__attribute__((format (printf, 1, 2)));

static
void log_stderr_ex(const char * prefix, const char * suffix, const char * fmt, ...)
__attribute__((format (printf, 3, 4)));

static
void log_stderr_error(int error_num, const char * fmt, ...)
__attribute__((format (printf, 2, 3)));

static
void log_stderr_error_ex(const char * prefix, int error_num, const char * fmt, ...)
__attribute__((format (printf, 3, 4)));

static
void log_stderr_path_error(const char * path_name, int error_num, const char * fmt, ...)
__attribute__((format (printf, 3, 4)));

static
void log_stderr_path_error_ex(const char * prefix, const char * path_name, int error_num, const char * fmt, ...)
__attribute__((format (printf, 4, 5)));

static
size_t _vlog_timestamp(char * buffer)
{
	char b[64];
	struct timespec ts;
	struct tm tm;
	size_t x = 0;

	if (!timespec_get(&ts, TIME_UTC))
		return 0;

	if (!localtime_r(&(ts.tv_sec), &tm))
		return 0;

	x += strftime(b + x, sizeof(b) - x, "%Y-%m-%d %H:%M:%S", &tm);
	x += snprintf(b + x, sizeof(b) - x, ".%06d", (int) (ts.tv_nsec / 1000));
	x += strftime(b + x, sizeof(b) - x, "%z", &tm);
	b[x] = 0;

	if (buffer)
		strncpy(buffer, b, x);

	return x;
}

static
size_t _vlog_string(char * buffer, size_t length, const char * fmt, va_list args)
{
	int x;
	size_t len;

	if (!fmt) return 0;

	if (!buffer) {
		/* length estimation */

		va_list args2;

		va_copy(args2, args);
		x = vsnprintf(NULL, 0, fmt, args2);
		va_end(args2);
		len = (x > 0) ? x : 0;
	} else {
		/* regular print

		   caveats:
		   - GCC doesn't have vsprintf_s() or vsnprintf_s() - or I'm just a dullboy
		   - vsnprintf() doesn't truncate output / respect provided "length"

		   actual for:
		   GCC 13.x (13.1.0-9 in Debian) as of 2023.07.31

		   solution:
		   use intermediate buffer and odd vsprintf() *sigh*
		*/

		char _b[(LOG_BUFFER_SIZE)];
		char * b = _b;

		// x = vsnprintf(buffer, length + 1, fmt, args);
		x = vsprintf(b, fmt, args);
		va_end(args);

		len = (x > 0) ? x : 0;

		b = trim_whitespace_ro(b, &len);

		len = min(len, length);
		if (len)
			(void) memcpy(buffer, b, len);
	}

	return len;
}

static
void vlog_stderr(const char * prefix, const char * suffix, const char * fmt, va_list args)
{
	char b[(LOG_BUFFER_SIZE)];
	size_t len_ts = 0,
	       len_pre = 0,
	       len_args = 0,
	       len_suf = 0,
	       len_max,
		   len_eos,
	       len_cur = 0;

	/* early "print" timestamp - buffer must provide enough space */
	len_ts = _vlog_timestamp(b);

	len_pre  = (prefix) ? strlen(prefix) : 0;
	len_args = (fmt)    ? _vlog_string(NULL, 0, fmt, args) : 0;
	len_suf  = (suffix) ? strlen(suffix) : 0;

	len_max = len_ts   + ((len_ts)   ? 1 /* space/LF */ : 0)
	        + len_pre  + ((len_pre)  ? 1 /* space/LF */ : 0)
	        + len_args + ((len_args) ? 1 /* space/LF */ : 0)
	        + len_suf  + ((len_suf)  ? 1 /* space/LF */ : 0)
	        ;

	len_max = min(len_max, (LOG_BUFFER_SIZE));
	len_max--; /* reserve space for LF */
	len_eos = len_max - 1; /* kinda quirk */

	/* no checks - buffer must provide enough space */
	len_cur += len_ts;

	if (len_pre)
		prefix = trim_whitespace_ro(prefix, &len_pre);

	if (len_pre) {
		if (!(len_cur < len_eos))
			goto vlog_stderr_eol;

		b[len_cur++] = ' ';
	}

	len_pre = min(len_pre, len_max - len_cur);
	if (len_pre) {
		(void) memcpy(b + len_cur, prefix, len_pre);
		len_cur += len_pre;
	}

	if (len_args) {
		if (!(len_cur < len_eos))
			goto vlog_stderr_eol;

		b[len_cur++] = ' ';
	}

	len_args = min(len_args, len_max - len_cur);
	if (len_args) {
		len_cur += _vlog_string(b + len_cur, len_args, fmt, args);
	}

	if (len_suf)
		suffix = trim_whitespace_ro(suffix, &len_suf);

	if (len_suf) {
		if (!(len_cur < len_eos))
			goto vlog_stderr_eol;

		b[len_cur++] = ' ';
	}

	len_suf = min(len_suf, len_max - len_cur);
	if (len_suf) {
		(void) memcpy(b + len_cur, suffix, len_suf);
		len_cur += len_suf;
	}

vlog_stderr_eol:

	b[len_cur] = '\n';

	(void) write(STDERR_FILENO, b, len_cur + 1);
}

static
void vlog_stderr_error(const char * prefix, int error_num, const char * fmt, va_list args)
{
	char b[(LOG_BUFFER_SIZE)];
	const size_t max_len = sizeof(b) - 1;
	int x;
	size_t cur_len = 0, err_len = 0;
	char * b2;
	char * e_str;

	if (error_num) {
		x = snprintf(b, max_len, "error %d: ", error_num);
		cur_len = x = (x > 0) ? x : 0;
		b2 = b + cur_len;
		e_str = strerror_r(error_num, b2, max_len - cur_len);
		if (e_str) {
			err_len = strlen(e_str);
			err_len = min(err_len, max_len - cur_len);
			cur_len += err_len;
			if (e_str != b2)
				(void) strncpy(b2, e_str, max_len - cur_len);
		}
	}

	b[cur_len] = 0;
	vlog_stderr(prefix, (cur_len) ? b : NULL, fmt, args);

	/* restore errno */
	errno = error_num;
}

/* should be reusing vlog_stderr_error() but... */
static
void vlog_stderr_path_error(const char * prefix, const char * path_name, int error_num, const char * fmt, va_list args)
{
	char b[(LOG_BUFFER_SIZE)];
	const size_t max_len = sizeof(b) - 1;
	int x;
	size_t cur_len = 0, err_len = 0;
	char * b2;
	char * e_str;

	if (error_num) {
		x = snprintf(b, max_len, "path '%s' error %d: ", path_name, error_num);
		cur_len = x = (x > 0) ? x : 0;
		b2 = b + cur_len;
		e_str = strerror_r(error_num, b2, max_len - cur_len);
		if (e_str) {
			err_len = strlen(e_str);
			err_len = min(err_len, max_len - cur_len);
			cur_len += err_len;
			if (e_str != b2)
				(void) strncpy(b2, e_str, max_len - cur_len);
		}
	} else {
		x = snprintf(b, max_len, "path '%s'", path_name);
		cur_len = x = (x > 0) ? x : 0;
	}

	b[cur_len] = 0;
	vlog_stderr(prefix, (cur_len) ? b : NULL, fmt, args);

	/* restore errno */
	errno = error_num;
}

static
void log_stderr(const char * fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	vlog_stderr(NULL, NULL, fmt, args);
	// va_end(args); /* not needed */
}

static
void log_stderr_ex(const char * prefix, const char * suffix, const char * fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	vlog_stderr(prefix, suffix, fmt, args);
	// va_end(args); /* not needed */
}

static
void log_stderr_error(int error_num, const char * fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	vlog_stderr_error(NULL, error_num, fmt, args);
	// va_end(args); /* not needed */

	/* restore errno */
	errno = error_num;
}

static
void log_stderr_error_ex(const char * prefix, int error_num, const char * fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	vlog_stderr_error(prefix, error_num, fmt, args);
	// va_end(args); /* not needed */

	/* restore errno */
	errno = error_num;
}

static
void log_stderr_path_error(const char * path_name, int error_num, const char * fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	vlog_stderr_path_error(NULL, path_name, error_num, fmt, args);
	// va_end(args); /* not needed */

	/* restore errno */
	errno = error_num;
}

static
void log_stderr_path_error_ex(const char * prefix, const char * path_name, int error_num, const char * fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	vlog_stderr_path_error(prefix, path_name, error_num, fmt, args);
	// va_end(args); /* not needed */

	/* restore errno */
	errno = error_num;
}

#include "../misc/ext-c-end.h"

#endif /* HEADER_INCLUDED_IO_LOG_STDERR */
