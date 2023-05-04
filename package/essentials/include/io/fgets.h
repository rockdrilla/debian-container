/* fgets: wrapper around fgets() with trim leading newline
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_IO_FGETS
#define HEADER_INCLUDED_IO_FGETS 1

#include "../misc/ext-c-begin.h"

#include <stdio.h>
#include <string.h>

static
char * fgets_trim(char * s, int n, FILE * stream)
{
	s = fgets(s, n, stream);
	if (!s) return NULL;
	s[strcspn(s, "\r\n")] = 0;
	return s;
}

#include "../misc/ext-c-end.h"

#endif /* HEADER_INCLUDED_IO_FGETS */
