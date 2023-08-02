/* fgets: wrapper around fgets() with trim leading newline
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_IO_FGETS
#define HEADER_INCLUDED_IO_FGETS 1

#include "../misc/ext-c-begin.h"

#include <errno.h>
#include <stdio.h>
#include <string.h>

static
char * fgets_noeol(char * s, int size, FILE * stream)
{
	if (!s) return NULL;
	if (!stream) return NULL;

	errno = 0;
	s = fgets(s, size, stream);
	if (!s) return NULL;

	s[strcspn(s, "\r\n")] = 0;
	return s;
}

#include "../misc/ext-c-end.h"

#endif /* HEADER_INCLUDED_IO_FGETS */
