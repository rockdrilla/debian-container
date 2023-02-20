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

	if (fd < 0) return 0;

	snprintf(procfs_link, sizeof(procfs_link), "/proc/self/fd/%d", fd);
	ssize_t result = readlink(procfs_link, buffer, buffer_size - 1);
	if (result <= 0) return 0;
	buffer[result] = 0;

	return result;
}

#include "../misc/ext-c-end.h"

#endif /* HEADER_INCLUDED_PROCFS_FD2NAME */
