/* strfun: string fun
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_STRFUN
#define HEADER_INCLUDED_STRFUN 1

#include "ext-c-begin.h"

#include <ctype.h>
#include <string.h>

static
unsigned int split_string(char * string, int delimiter, unsigned int max_tokens, char * out_tokens[])
{
	unsigned int i = 0;
	char * t = string;

	if (!string)     return 0;
	if (!(*string))  return 0;
	if (!delimiter)  return 0;
	if (!max_tokens) return 0;
	if (!out_tokens) return 0;

	memset(out_tokens, 0, sizeof(out_tokens[0]) * max_tokens);

	for (; i < max_tokens; ) {
		if (i) *t++ = 0;

		if (!(*t)) break;

		out_tokens[i++] = t;

		t = strchr(t, delimiter);
		if (!t) break;
	}

	return i;
}

static
char * next_token(const char * string, int delimiter)
{
	char * t;

	if (!string)    return NULL;
	if (!(*string)) return NULL;
	if (!delimiter) return NULL;

	t = (char *) strchr(string, delimiter);
	if (t) t++;

	return t;
}

static
char * find_token(const char * string, int delimiter, const char * token)
{
	size_t s, n, x;
	const char * t;

	if (!string)    return NULL;
	if (!delimiter) return NULL;
	if (!token)     return NULL;

	s = strlen(string);
	if (!s) return NULL;

	n = strlen(token);
	if (!n) return NULL;

	t = string;

	x = 0;
	for (const char * p = t; t; t = p) {
		if (!(*t)) break;

		p = strchr(t, delimiter);
		if (p)
			x = (size_t) p++ - (size_t) t;
		else
			x = (size_t) string + s - (size_t) t;

		if (x != n) continue;

		if (strncmp(t, token, n) == 0)
			return (char *) t;
	}

	return NULL;
}

static
unsigned int get_token_count(const char * string, int delimiter)
{
	unsigned int c = 0;

	if (!delimiter) return 0;

	for (const char * t = string; t;) {
		if (!(*t)) break;

		c++;

		t = strchr(t, delimiter);
		if (t) t++;
	}

	return c;
}

static
char * trim_whitespace_ro(const char * string, size_t * length)
{
	char * s = (char *) string;
	size_t l;

	if (!string) return NULL;
	if (!length) return s;

	l = *length;

	/* very naive */
	for(; (l) && (s[0]) && isspace(s[0]); s++, l--) ;
	for(; (l) && (s[l - 1]) && isspace(s[l - 1]); l--) ;

	*length = l;
	return s;
}

static
char * trim_whitespace(char * string)
{
	char * s = (char *) string;
	size_t l;

	if (!string) return NULL;

	l = strlen(string);
	s = trim_whitespace_ro(string, &l);
	if (!s) return string;

	s[l] = 0;
	return s;
}

#include "ext-c-end.h"

#endif /* HEADER_INCLUDED_STRFUN */
