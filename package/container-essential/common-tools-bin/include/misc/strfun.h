/* strfun: string fun
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_STRFUN
#define HEADER_INCLUDED_STRFUN 1

#include "ext-c-begin.h"

#include <string.h>

static
unsigned int split_string(char * string, int delimiter, unsigned int max_tokens, char * out_tokens[])
{
	if (!string)        return 0;
	if (!(*string))     return 0;
	if (delimiter == 0) return 0;
	if (!max_tokens)    return 0;
	if (!out_tokens)    return 0;

	memset(out_tokens, 0, sizeof(out_tokens[0]) * max_tokens);

	unsigned int i = 0;
	char * t = string;
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
	if (!string)        return NULL;
	if (!(*string))     return NULL;
	if (delimiter == 0) return NULL;

	char * t = (char *) strchr(string, delimiter);
	if (t) t++;

	return t;
}

static
char * find_token(const char * string, int delimiter, const char * token)
{
	if (!string)        return NULL;
	if (delimiter == 0) return NULL;
	if (!token)         return NULL;

	size_t s = strlen(string);
	if (!s) return NULL;

	size_t n = strlen(token);
	if (!n) return NULL;

	const char * t = string;
	const char * p = t;
	size_t x;

	while (t) {
		t = p;

		if (!(*t)) break;

		p = strchr(t, delimiter);
		if (p) {
			x = (size_t) p++ - (size_t) t;
		} else {
			x = (size_t) string + s - (size_t) t;
		}

		if (x != n) continue;

		if (strncmp(t, token, n) == 0)
			return (char *) t;
	}

	return NULL;
}

static
unsigned int get_token_count(const char * string, int delimiter)
{
	if (delimiter == 0) return 0;

	unsigned int c = 0;

	for (const char * t = string; t;) {
		if (!(*t)) break;

		c++;

		t = strchr(t, delimiter);
		if (t) t++;
	}

	return c;
}

#include "ext-c-end.h"

#endif /* HEADER_INCLUDED_STRFUN */
