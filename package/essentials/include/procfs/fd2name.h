/* fd2name: (try) read real name from open file descriptor
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_PROCFS_FD2NAME
#define HEADER_INCLUDED_PROCFS_FD2NAME 1

#include "../misc/ext-c-begin.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static
uint32_t procfs_fd2name(int fd, char * buffer, uint32_t buffer_size)
{
	/* "/proc/self/fd/" - 14, "%d" - up to 10 */
	char procfs_link[32];
	ssize_t x;

	if (fd < 0)  return 0;
	if (!buffer) return 0;

	(void) memset(procfs_link, 0, sizeof(procfs_link));
	(void) snprintf(procfs_link, sizeof(procfs_link) - 1, "/proc/self/fd/%d", fd);
	x = readlink(procfs_link, buffer, buffer_size - 1);
	x = (x > 0) ? x : 0;
	buffer[x] = 0;
	return x;
}

#include "../misc/ext-c-end.h"

#endif /* HEADER_INCLUDED_PROCFS_FD2NAME */
