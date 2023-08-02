/* fopen: extra fopen()-like methods
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_IO_FOPEN
#define HEADER_INCLUDED_IO_FOPEN 1

#include "../misc/ext-c-begin.h"

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

static
FILE * fopen_at(int fd_directory, const char * filepath, int flags, const char * fmode);

static
FILE * fopen_path(const char * directory, const char * filepath, int flags, const char * fmode);

static
FILE * fopen_at(int fd_dir, const char * path, int flags, const char * mode)
{
	int fd_file;

	if (fd_dir < 0) return NULL;
	if (!path) return NULL;

	fd_file = openat(fd_dir, path, flags);
	if (fd_file < 0) return NULL;

	errno = 0;
	return fdopen(fd_file, mode);
}

static
FILE * fopen_path(const char * dir, const char * path, int flags, const char * mode)
{
	int err, fd_dir, fd_file;

	if (!dir) return NULL;
	if (!path) return NULL;

	fd_dir = open(dir, O_RDONLY | O_DIRECTORY);
	if (fd_dir < 0) return NULL;

	fd_file = openat(fd_dir, path, flags);
	if (fd_file < 0) {
		err = errno;
		(void) close(fd_dir);
		errno = err;
		return NULL;
	}

	(void) close(fd_dir);

	errno = 0;
	return fdopen(fd_file, mode);
}

#include "../misc/ext-c-end.h"

#endif /* HEADER_INCLUDED_IO_FOPEN */
