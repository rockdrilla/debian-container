/* mountinfo: parse /proc/{pid}/mountinfo
 *
 * refs:
 * - [1] https://www.kernel.org/doc/Documentation/filesystems/proc.txt
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_PROCFS_MOUNTINFO
#define HEADER_INCLUDED_PROCFS_MOUNTINFO 1

#include "../misc/ext-c-begin.h"

#include <stdio.h>
#include <unistd.h>

#include "../io/const.h"
#include "../io/fgets.h"
#include "../misc/read-int.h"
#include "../misc/strfun.h"

typedef struct {
	int id,
	    parent_id,
	    major,
	    minor;

	char * root,
	     * mount_point,
	     * mount_options,
	     * optional,
	     * fs_type,
	     * mount_source,
	     * super_options;
} procfs_mountinfo_entry;

typedef int (* procfs_mountinfo_callback ) (const procfs_mountinfo_entry * entry, void * state);

static
int procfs_mountinfo_walk(pid_t pid, const procfs_mountinfo_callback callback, void * state)
{
	if (!callback) return 0;

	FILE * f = NULL;

	if (pid > 0) {
		/* "/proc/" + "/mountinfo" - 16, "%d" - up to 10 */
		char procfs_path[32];
		snprintf(procfs_path, sizeof(procfs_path), "/proc/%d/mountinfo", pid);
		f = fopen(procfs_path, "r");
	} else
		f = fopen("/proc/self/mountinfo", "r");

	if (!f) return 0;

	/* split up to entry.optional */
	const unsigned int n_part = 7;
	char * part[n_part];

	procfs_mountinfo_entry entry;

	const int n_buf = PATH_MAX /* entry.root */
	                + PATH_MAX /* entry.mount_point */
	                + PATH_MAX /* entry.mount_options */
	                + PATH_MAX /* entry.super_options */
	                + PATH_MAX /* remaining fields */;
	char buf[n_buf];

	int result = 0;

	char * sep;
	while (fgets_trim(buf, n_buf, f)) {
		memset(&entry, 0, sizeof(entry));

		if (split_string(buf, ' ', n_part, part) != n_part)
			continue;

		entry.id            = read_int_str(10, part[0]);
		entry.parent_id     = read_int_str(10, part[1]);

		entry.root          = part[3];
		entry.mount_point   = part[4];
		entry.mount_options = part[5];
		entry.optional      = part[6];

		if (split_string(part[2], ':', 3, part) != 2)
			continue;

		entry.major = read_int_str(10, part[0]);
		entry.minor = read_int_str(10, part[1]);

		sep = find_token(entry.optional, ' ', "-");
		if (sep == NULL) continue;

		if (sep == entry.optional)
			entry.optional = NULL;
		else
			entry.optional[sep - entry.optional - 1] = 0;

		sep += 2; // go to next token

		if (split_string(sep, ' ', 3, part) != 3)
			continue;

		entry.fs_type       = part[0];
		entry.mount_source  = part[1];
		entry.super_options = part[2];

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

#endif /* HEADER_INCLUDED_PROCFS_MOUNTINFO */
