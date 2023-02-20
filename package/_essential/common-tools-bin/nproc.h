/*
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2020 Andrei Pangin
 * (c) 2022-2023 Konstantin Demin
 */

#ifndef HEADER_INCLUDED_NPROC
#define HEADER_INCLUDED_NPROC 1

#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "include/io/fgets.h"
#include "include/io/fopen.h"
#include "include/num/ceildiv.h"
#include "include/num/minmax.h"
#include "include/procfs/cgroup-v1.h"
#include "include/procfs/cgroup-v2.h"

// ephemeral limit
#define PROC_MAX 4096

#ifndef NPROC_SYSCONF_PROC
#define NPROC_SYSCONF_PROC sysconf
#endif

static const char * env_nproc = "NPROC";

static int debug = 0;

static CC_FORCE_INLINE
int is_valid_proc_count(long number)
{
	return ((number > 0) && (number <= PROC_MAX));
}

static
int get_cpuset(const char * cgroup_path, const char * parameter)
{
	if (cgroup_path == NULL) return 0;
	if (parameter == NULL)   return 0;

	FILE * f = fopen_path(cgroup_path, parameter, O_RDONLY, "r");
	if (!f) return 0;

	long result = 0;

	char buf[16384];
	const int n_range = 2;
	char * range[n_range + 1];

	do {
		if (!fgets_trim(buf, sizeof(buf), f)) break;

		char * t = buf;
		char * p;
		long a, b;

		while (t != NULL) {
			if (t[0] == 0) break;

			p = next_token(t, ',');
			if (p != NULL) {
				t[p - t - 1] = 0;
			}

			switch (split_string(t, '-', n_range + 1, range)) {
			case 1:
				result++;
				break;
			case 2:
				a = read_long_str(10, range[0]);
				if (a < 0) break;
				b = read_long_str(10, range[1]);
				if (b < 0) break;
				result += (b - a + 1);
				break;
			}

			t = p;
		}
	} while (0);

	fclose(f);

	return is_valid_proc_count(result) ? result : 0;
}

static
int get_quota_v1(const char * cgroup_path)
{
	if (cgroup_path == NULL) return 0;

	int fd_path = open(cgroup_path, O_RDONLY | O_DIRECTORY);
	if (fd_path < 0) return 0;

	long cfs_quota  = read_long_at_file(10, fd_path, "cpu.cfs_quota_us");
	long cfs_period = read_long_at_file(10, fd_path, "cpu.cfs_period_us");
	close(fd_path);

	long result = 0;
	if ((cfs_quota > 0) && (cfs_period > 0)) {
		result = ceildivl(cfs_quota, cfs_period);

		// adjust
		if (!result) result = 1;
	}

	return is_valid_proc_count(result) ? result : 0;
}

static
int get_shares_v1(const char * cgroup_path)
{
	if (cgroup_path == NULL) return 0;

	int fd_path = open(cgroup_path, O_RDONLY | O_DIRECTORY);
	if (fd_path < 0) return 0;

	long result = read_long_at_file(10, fd_path, "cpu.shares");
	close(fd_path);

	if (result < 0) return 0;

	if (result > 1024) {
		result = ceildivl(result, 1024);

		// adjust
		if (!result) result = 1;
	}

	return is_valid_proc_count(result) ? result : 0;
}

static
int get_quota_v2(const char * cgroup_path)
{
	if (cgroup_path == NULL) return 0;

	FILE * f = fopen_path(cgroup_path, "cpu.max", O_RDONLY, "r");
	if (!f) return 0;

	long result = 0;

	char buf[128];
	const unsigned int n_part = 2;
	char * part[n_part + 1];

	do {
		if (!fgets_trim(buf, sizeof(buf), f)) break;

		if (split_string(buf, ' ', n_part + 1, part) < n_part)
			break;

		long cfs_quota  = read_long_str(10, part[0]);
		long cfs_period = read_long_str(10, part[1]);

		if ((cfs_quota > 0) && (cfs_period > 0)) {
			result = ceildivl(cfs_quota, cfs_period);

			// adjust
			if (!result) result = 1;
		}
	} while (0);

	fclose(f);

	return is_valid_proc_count(result) ? result : 0;
}

// Try to discover the number of available CPUs in a [Docker] container
static
int find_container_cpus(void)
{
	long t = 0;

	int nproc_env       = 0,
		nproc_conf      = 0,
		nproc_online    = 0,
		nproc_cpuset_v1 = 0,
		nproc_quota_v1  = 0,
		nproc_shares_v1 = 0,
		nproc_cpuset_v2 = 0,
		nproc_quota_v2  = 0;

	char * env_val_count = getenv(env_nproc);
	if (env_val_count != NULL) {
		t = read_long_str(10, env_val_count);
		if ((t >= -(PROC_MAX)) && (t <= PROC_MAX)) {
			nproc_env = t;

			// trust environment with no particular reason :)
			if (nproc_env > 0) {
				return nproc_env;
			}

			// negative value means "soft limit"
		}
	}

	t = sysconf(_SC_NPROCESSORS_CONF);
	if (is_valid_proc_count(t)) {
		nproc_conf = t;
	}

	t = sysconf(_SC_NPROCESSORS_ONLN);
	if (is_valid_proc_count(t)) {
		nproc_online = t;
	}

	char tpath[PATH_MAX];

	if (get_cgroup_v1_path(0, "cpuset", tpath)) {
		t = get_cpuset(tpath, "cpuset.effective_cpus");
		if (is_valid_proc_count(t)) {
			nproc_cpuset_v1 = t;
		}
	}

	if (get_cgroup_v1_path(0, "cpu", tpath)) {
		t = get_quota_v1(tpath);
		if (is_valid_proc_count(t)) {
			nproc_quota_v1 = t;
		}

		t = get_shares_v1(tpath);
		if (is_valid_proc_count(t)) {
			nproc_shares_v1 = t;
		}
	}

	if (get_cgroup_v2_path(0, tpath)) {
		t = get_cpuset(tpath, "cpuset.cpus.effective");
		if (is_valid_proc_count(t)) {
			nproc_cpuset_v2 = t;
		}

		t = get_quota_v2(tpath);
		if (is_valid_proc_count(t)) {
			nproc_quota_v2 = t;
		}
	}

	if (nproc_env < 0) nproc_env = -nproc_env;

	int x = 0;
	x = min_positive(x, nproc_env);
	x = min_positive(x, nproc_conf);
	x = min_positive(x, nproc_online);
	x = min_positive(x, nproc_cpuset_v1);
	x = min_positive(x, nproc_quota_v1);
	x = min_positive(x, nproc_shares_v1);
	x = min_positive(x, nproc_cpuset_v2);
	x = min_positive(x, nproc_quota_v2);

	return x;
}

#endif /* HEADER_INCLUDED_NPROC */
