/* mountinfo: parse /proc/{pid}/mountinfo
 *
 * refs:
 * - [1] https://www.kernel.org/doc/Documentation/filesystems/proc.txt
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_PROCFS_CGROUP_V2
#define HEADER_INCLUDED_PROCFS_CGROUP_V2 1

#include "../misc/ext-c-begin.h"

#include "mountinfo.h"
#include "cgroup.h"

typedef struct {
	char root[PATH_MAX],
	     mount_point[PATH_MAX],
	     path[PATH_MAX];
} _cgv2_walk;

static
int _cgv2_mountinfo(const procfs_mountinfo_entry * entry, _cgv2_walk * state)
{
	if (strcmp(entry->fs_type, "cgroup2") != 0)
		return 0;

	strcpy(state->root,        entry->root);
	strcpy(state->mount_point, entry->mount_point);
	return 1;
}

static
int _cgv2_cgroup(const procfs_cgroup_entry * entry, _cgv2_walk * state)
{
	if (entry->id != 0)
		return 0;
	if (entry->controllers[0])
		return 0;

	do {
		if (strcmp(state->root, "/") == 0) break;
		if (strcmp(state->root, entry->path) == 0) break;

		// many thanks to Podman for wasting approx. 4 hours of my life
		if (strncmp(state->root, "/../", 4) == 0) break;

		return 0;
	} while (0);

	strcpy(state->path, entry->path);
	return 1;
}

static
int get_cgroup_v2_path(pid_t pid, char * buf)
{
	_cgv2_walk state;

	memset(&state, 0, sizeof(state));

	if (!procfs_mountinfo_walk(pid, (procfs_mountinfo_callback) _cgv2_mountinfo, &state))
		return 0;

	if (!procfs_cgroup_walk(pid, (procfs_cgroup_callback) _cgv2_cgroup, &state))
		return 0;

	strcpy(buf, state.mount_point);
	if (strcmp(state.root, "/") == 0)
		strcat(buf, state.path);

	return 1;
}

#include "../misc/ext-c-end.h"

#endif /* HEADER_INCLUDED_PROCFS_CGROUP_V2 */
