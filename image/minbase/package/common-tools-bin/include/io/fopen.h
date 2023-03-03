/* fopen: extra fopen()-like methods
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_IO_FOPEN
#define HEADER_INCLUDED_IO_FOPEN 1

#include "../misc/ext-c-begin.h"

#include <fcntl.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>

static
FILE * fopen_at(int fd_directory, const char * filepath, int flags, const char * fmode)
{
	if (fd_directory < 0) return NULL;

	int fd_file = openat(fd_directory, filepath, flags);
	if (fd_file < 0) return NULL;

	errno = 0;
	return fdopen(fd_file, fmode);
}

static
FILE * fopen_path(const char * directory, const char * filepath, int flags, const char * fmode)
{
	int err;

	int fd_dir = open(directory, O_RDONLY | O_DIRECTORY);
	if (fd_dir < 0) return NULL;

	int fd_file = openat(fd_dir, filepath, flags);
	if (fd_file < 0) {
		err = errno;
		close(fd_dir);
		errno = err;
		return NULL;
	}

	close(fd_dir);

	errno = 0;
	return fdopen(fd_file, fmode);
}

#include "../misc/ext-c-end.h"

#endif /* HEADER_INCLUDED_IO_FOPEN */
