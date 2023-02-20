/* cgroup: parse /proc/{pid}/cgroup
 *
 * refs:
 * - [1] https://www.kernel.org/doc/Documentation/filesystems/proc.txt
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_PROCFS_CGROUP
#define HEADER_INCLUDED_PROCFS_CGROUP 1

#include "../misc/ext-c-begin.h"

#include <stdio.h>
#include <unistd.h>

#include "../io/const.h"
#include "../io/fgets.h"
#include "../misc/read-int.h"
#include "../misc/strfun.h"

typedef struct {
	int id;
	char * controllers,
	     * path;
} procfs_cgroup_entry;

typedef int (* procfs_cgroup_callback ) (const procfs_cgroup_entry * entry, void * state);

static
int procfs_cgroup_walk(pid_t pid, const procfs_cgroup_callback callback, void * state)
{
	if (!callback) return 0;

	FILE * f = NULL;

	if (pid > 0) {
		/* "/proc/" + "/cgroup" - 13, "%d" - up to 10 */
		char procfs_path[24];
		snprintf(procfs_path, sizeof(procfs_path), "/proc/%d/cgroup", pid);
		f = fopen(procfs_path, "r");
	} else
		f = fopen("/proc/self/cgroup", "r");

	if (!f) return 0;

	const unsigned int n_part = 3;
	char * part[n_part];

	procfs_cgroup_entry entry;

	const int n_buf = PATH_MAX /* entry.path */
	                + 1024 /* remaining fields */;
	char buf[n_buf];

	int result = 0;

	while (fgets_trim(buf, n_buf, f)) {
		if (split_string(buf, ':', n_part, part) != n_part)
			continue;

		entry.id          = read_int_str(10, part[0]);
		entry.controllers = part[1];
		entry.path        = part[2];

		int result_cb = callback(&entry, state);
		if (result_cb == 0) continue;
		if (result_cb < 0)  break;
		if (result_cb > 0)  result = 1;
		if (result_cb == 1) break;
	}

	fclose(f);

	return result;
}

#include "../misc/ext-c-end.h"

#endif /* HEADER_INCLUDED_PROCFS_CGROUP */
