/*
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2020 Andrei Pangin
 * (c) 2022-2023 Konstantin Demin
 *
 * refs:
 * - [1] https://www.kernel.org/doc/Documentation/admin-guide/cputopology.rst
 *
 */

#ifndef HEADER_INCLUDED_INCONTAINER_NPROC
#define HEADER_INCLUDED_INCONTAINER_NPROC 1

#include "../misc/ext-c-begin.h"

#include <errno.h>
#include <sched.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <sys/syscall.h>
#include <sys/stat.h>

#include "../io/fgets.h"
#include "../io/fopen.h"
#include "../misc/cc-inline.h"
#include "../misc/memfun.h"
#include "../misc/read-int.h"
#include "../num/ceildiv.h"
#include "../num/getmsb.h"
#include "../num/minmax.h"
#include "../num/popcnt.h"
#include "../procfs/cgroup-v1.h"
#include "../procfs/cgroup-v2.h"

/* ephemeral limit borrowed from Linux kernel sources (actual as of 2023.08.02) */
#ifndef CPU_MAX
#define CPU_MAX  8192
#endif

static const int cpu_max = (CPU_MAX);
#define CPU_MAX_BYTES  (((CPU_MAX) / 8) + (((CPU_MAX) % 8) ? 1 : 0))
static const size_t cpu_max_bytes = (CPU_MAX_BYTES);
#define CPU_MAX_ARRLEN  (((CPU_MAX_BYTES) / sizeof(size_t)) + (((CPU_MAX_BYTES) % sizeof(size_t)) ? 1 : 0))
static const size_t cpu_max_arrlen = (CPU_MAX_ARRLEN);

typedef struct {
	size_t length;
	int count, min, max;
} cpu_set_info_t;

enum {
	nproc_kind_normal = 0,
	nproc_kind_force,
	nproc_kind_min,
};

/* TODO: add "fixed" layout too */
enum {
	nproc_adjust_cpuset_none = 0,
	nproc_adjust_cpuset_random,
};

static const char * env_nproc = "NPROC";
static const char * env_nproc_kind = "NPROC_KIND";
static const char * file_nproc = "/run/lock/nproc";

static long   nproc_sched_getaffinity_sys(pid_t tid, size_t cpusetsize, cpu_set_t * cpuset);
static size_t nproc_sched_getaffinity(pid_t tid, size_t cpusetsize, cpu_set_t * cpuset);
static size_t nproc_sched_getaffinity_ex(pid_t tid, size_t cpusetsize, cpu_set_t * cpuset, cpu_set_info_t * info);

static uint32_t nproc_sched_cpucount(size_t cpusetsize, const cpu_set_t * cpuset);
static uint32_t nproc_sched_cpucount_ex(size_t cpusetsize, const cpu_set_t * cpuset, cpu_set_info_t * info);
static uint32_t nproc_sched_cpucount_lean(pid_t tid);

static int get_nproc_value(void);
static void set_nproc_value(int value);
static void set_nproc_file_value(int value, int force);
static int get_nproc_kind(void);
static void set_nproc_kind(int kind);

static int get_container_cpus_sysfs(void);
static int get_container_cpus_cgroups(void);
static int get_container_cpus_sched_affinity(void);

static int adjust_cpuset_to_count_random(size_t cpusetsize, const cpu_set_t * cpuset, uint32_t cpucount);

static int get_cpuset(const char * cgroup_path, const char * parameter);
static int get_quota_v1(const char * cgroup_path);
static int get_shares_v1(const char * cgroup_path);
static int get_quota_v2(const char * cgroup_path);

static
CC_FORCE_INLINE
int clamp_cpucount(long n)
{
	return (n > 0) ? min(n, cpu_max) : 0;
}

static
int get_container_cpus(void)
{
	pid_t pid = 0;
	int x = 0, n = 0, k = nproc_kind_normal;

	pid = getpid();
	if (pid > 1) {
		x = read_int_file(10, file_nproc);
		if ((x < 1) || (x > cpu_max)) {
			x = 0;
			(void) unlink(file_nproc);
		}
	}

	if (!x) {
		x = min_positive(x, get_container_cpus_sysfs());
		x = min_positive(x, get_container_cpus_cgroups());
		x = min_positive(x, get_container_cpus_sched_affinity());
	}

	n = get_nproc_value();
	k = get_nproc_kind();

	if (!n) n = x;

	if (k == nproc_kind_min) {
		if (n > x)
			set_nproc_kind(k = nproc_kind_force);
		else
			n = x;
	}

	if (x >= n)
		set_nproc_kind(k = nproc_kind_normal);

	switch (k) {
	case nproc_kind_force:
		x = n;
		break;
	case nproc_kind_normal:
		x = min_positive(x, n);
		break;
	}

	/* last resort */
	if (!x) x = 1;

	set_nproc_value(x);

	if (pid == 1)
		set_nproc_file_value(x, 1);

	return x;
}

static
void adjust_container_cpuset(int num)
{
	char * s_env = NULL;
	int mode = nproc_adjust_cpuset_none;
	size_t length;
	cpu_set_info_t cpuset_info;
	cpu_set_t * cpuset = NULL;

	if ((s_env = getenv("NPROC_CPUSET"))) {
		if (strcmp(s_env, "none") == 0) {
			mode = nproc_adjust_cpuset_none;
		}
		else
		if (strcmp(s_env, "random") == 0) {
			mode = nproc_adjust_cpuset_random;
		}
	}

	if (mode == nproc_adjust_cpuset_none)
		return;

	if (mode == nproc_adjust_cpuset_random)
		srand(time(NULL));

	(void) memset(&cpuset_info, 0, sizeof(cpuset_info));
	length = nproc_sched_getaffinity_ex(0, 0, NULL, &cpuset_info);
	if (!length) return;

	cpuset = (cpu_set_t *) malloc(length);
	if (!cpuset) return;

	if (!nproc_sched_getaffinity(0, length, cpuset))
		goto free_cpuset;

	switch (mode) {
	case nproc_adjust_cpuset_random:
		if (!adjust_cpuset_to_count_random(length, cpuset, num))
			goto free_cpuset;
		break;
	}

	(void) sched_setaffinity(0, length, cpuset);

free_cpuset:
	free(cpuset);
	cpuset = NULL;
}

static long cpulist_to_count(const char * string);
static long cpulist_from_file(FILE * file);
static long cpulist_from_path(const char * directory, const char * filepath);

static
CC_INLINE
int get_nproc_value(void)
{
	int v = 0;
	char * s_env = NULL;

	s_env = getenv(env_nproc);
	if (!s_env) return 0;

	v = read_int_str(10, s_env);
	if ((v < 1) || (v > cpu_max)) {
		return 0;
	}

	return v;
}

static
CC_INLINE
void set_nproc_value(int value)
{
	char b[16];

	(void) memset(b, 0, sizeof(b));
	(void) sprintf(b, "%d", value);

	(void) setenv(env_nproc, b, 1);
}

static
CC_INLINE
void set_nproc_file_value(int value, int force)
{
	char b[16];
	int f;

	f = open(file_nproc, O_WRONLY | O_CREAT | ((force) ? O_TRUNC : O_EXCL), 0444);
	if (f < 0) return;

	(void) memset(b, 0, sizeof(b));
	(void) sprintf(b, "%d", value);

	(void) write(f, b, strnlen(b, sizeof(b)));
	(void) fchmod(f, 0444);
	(void) fsync(f);
	(void) close(f);
}

static
CC_INLINE
int get_nproc_kind(void)
{
	int k = nproc_kind_normal;
	char * s_env = NULL;

	s_env = getenv(env_nproc_kind);
	if (!s_env) return nproc_kind_normal;

	if (strcmp(s_env, "force") == 0)
		k = nproc_kind_force;
	else
	if (strcmp(s_env, "min") == 0)
		k = nproc_kind_min;

	return k;
}

static
CC_INLINE
void set_nproc_kind(int kind)
{
	char * s = NULL;

	switch (kind) {
	case nproc_kind_force:
		s = "force";
		break;
	case nproc_kind_min:
		s = "min";
		break;
	default:
		(void) unsetenv(env_nproc_kind);
		return;
	}

	if (!s) return;

	(void) setenv(env_nproc_kind, s, 1);
}

static
int get_container_cpus_sysfs(void)
{
	static const char * sysfs_dir = "/sys/devices/system/cpu";

	int x = 0;

	x = min_positive(x, clamp_cpucount(cpulist_from_path(sysfs_dir, "online")));
	x = min_positive(x, clamp_cpucount(cpulist_from_path(sysfs_dir, "possible")));
	x = min_positive(x, clamp_cpucount(cpulist_from_path(sysfs_dir, "present")));
	return x;
}

static
int get_container_cpus_cgroups(void)
{
	char tpath[PATH_MAX];
	int x = 0;

	if (get_cgroup_v1_path(0, "cpuset", tpath))
		x = min_positive(x, get_cpuset(tpath, "cpuset.effective_cpus"));

	if (get_cgroup_v1_path(0, "cpu", tpath)) {
		x = min_positive(x, get_quota_v1(tpath));
		x = min_positive(x, get_shares_v1(tpath));
	}

	if (get_cgroup_v2_path(0, tpath)) {
		x = min_positive(x, get_cpuset(tpath, "cpuset.cpus.effective"));
		x = min_positive(x, get_quota_v2(tpath));
	}

	return x;
}

static
int get_container_cpus_sched_affinity(void)
{
	return clamp_cpucount(nproc_sched_cpucount_lean(0));
}

/* randomly exclude cpus from "cpuset" to adjust count to "cpucount" */
static
int adjust_cpuset_to_count_random(size_t cpusetsize, const cpu_set_t * cpuset, uint32_t cpucount)
{
	cpu_set_info_t info;
	uint32_t cpucount_real;

	if (!cpuset)     return 0;
	if (!cpusetsize) return 0;
	if (!cpucount)   return 0;

	cpucount_real = nproc_sched_cpucount_ex(cpusetsize, cpuset, &info);
	// if (!cpucount_real) return 0;
	if (cpucount >= cpucount_real) return 0;

	/*
	 - pick random cpu number in [n_min;n_max]
	 - test is this cpu number used in cpuset
	 - exclude this cpu number from cpuset if it was set
	*/
	for (int i = 0; cpucount_real > cpucount; ) {
		if (info.min >= info.max) break;

		i = info.max - info.min + 1;
		i = info.min + (rand() % i);

		if (!CPU_ISSET_S(i, cpusetsize, cpuset))
			continue;

		CPU_CLR_S(i, cpusetsize, cpuset);
		cpucount_real--;

		if (i == info.min)
			info.min++;
		else
		if (i == info.max)
			info.max--;
	}

	return (cpucount == cpucount_real);
}

static
long nproc_sched_getaffinity_sys(pid_t tid, size_t cpusetsize, cpu_set_t * cpuset)
{
	long sysret;
	size_t len;

	if (!cpuset)     return -1;
	if (!cpusetsize) return -1;

	/* cpuset must be aligned! */
	if ((cpusetsize % sizeof(size_t))) return -1;

	(void) memset(cpuset, 0, cpusetsize);

	sysret = syscall(SYS_sched_getaffinity, tid, cpusetsize, cpuset);
	if (sysret <= 0) return sysret;

	/* ok: value is already clamped */
	len = (size_t) sysret;
	if (len < cpusetsize) {
		(void) memset(memfun_ptr_offset(cpuset, len), 0, cpusetsize - len);
	}

	return sysret;
}

static
size_t nproc_sched_getaffinity(pid_t tid, size_t cpusetsize, cpu_set_t * cpuset)
{
	long sysret = nproc_sched_getaffinity_sys(tid, cpusetsize, cpuset);

	return (sysret < 0) ? 0 : (size_t) sysret;
}

/* reimplement sched_cpucount() */
static
uint32_t nproc_sched_cpucount(size_t cpusetsize, const cpu_set_t * cpuset)
{
	const size_t * mask = NULL;
	size_t rounds;
	uint32_t count;

	if (!cpuset)     return 0;
	if (!cpusetsize) return 0;

	/* only account aligned data in cpuset */

	mask = (const size_t *) cpuset;
	cpusetsize = min(cpusetsize, cpu_max_bytes);
	rounds = cpusetsize / sizeof(size_t);
	count = 0;

	for (size_t i = 0; i < rounds; i++) {
		count += popcntl(mask[i]);
	}

	return count;
}

static
uint32_t nproc_sched_cpucount_ex(size_t cpusetsize, const cpu_set_t * cpuset, cpu_set_info_t * info)
{
	const size_t * mask = NULL;
	size_t x, rounds;
	uint32_t count, length, n_min, cpu_min, cpu_max;

	if (!info)
		return nproc_sched_cpucount(cpusetsize, cpuset);

	if (!cpuset)     return 0;
	if (!cpusetsize) return 0;

	/* only account aligned data in cpuset */

	mask = (const size_t *) cpuset;
	cpusetsize = min(cpusetsize, cpu_max_bytes);
	rounds = cpusetsize / sizeof(size_t);
	count = length = n_min = cpu_min = cpu_max = 0;

	for (size_t i = 0; i < rounds; i++) {
		if (!(x = mask[i])) continue;

		count += popcntl(x);
		length = i * sizeof(size_t);
		cpu_max = length + getmsbl(x) - 1;

		/* magic!
		 * get number of lowest significant bit
		 * ref: https://stackoverflow.com/a/18806607
		*/
		if (!n_min) {
			cpu_min = length + getmsbl(x & (~x + 1)) - 1;
			n_min = 1;
		}
	}

	info->length = length;
	info->count = count;
	info->min = cpu_min;
	info->max = cpu_max;

	return count;
}

static
size_t nproc_sched_getaffinity_ex(pid_t tid, size_t cpusetsize, cpu_set_t * cpuset, cpu_set_info_t * info)
{
	size_t mask[cpu_max_arrlen];
	size_t length;

	length = nproc_sched_getaffinity(tid, sizeof(mask), (cpu_set_t *) mask);
	if (!length) return 0;

	if (cpuset && (cpusetsize >= length)) {
		(void) memset(cpuset, 0, cpusetsize);
		(void) memcpy(cpuset, mask, length);
	}

	(void) nproc_sched_cpucount_ex(length, (const cpu_set_t *) mask, info);

	return length;
}

static
uint32_t nproc_sched_cpucount_lean(pid_t tid)
{
	cpu_set_info_t info;

	if (!nproc_sched_getaffinity_ex(tid, 0, NULL, &info))
		return 0;

	return info.count;
}

static
int get_cpuset(const char * cgroup_path, const char * parameter)
{
	return clamp_cpucount(cpulist_from_path(cgroup_path, parameter));
}

static
int get_quota_v1(const char * cgroup_path)
{
	int fd_dir;
	long result, cfs_quota, cfs_period;

	if (!cgroup_path) return 0;

	fd_dir = open(cgroup_path, O_RDONLY | O_DIRECTORY);
	if (fd_dir < 0) return 0;

	cfs_quota  = read_long_at_file(10, fd_dir, "cpu.cfs_quota_us");
	cfs_period = read_long_at_file(10, fd_dir, "cpu.cfs_period_us");
	(void) close(fd_dir);

	result = 0;
	if ((cfs_quota > 0) && (cfs_period > 0)) {
		result = ceildivl(cfs_quota, cfs_period);

		/* adjust */
		if (!result) result = 1;
	}

	return clamp_cpucount(result);
}

static
int get_shares_v1(const char * cgroup_path)
{
	int fd_dir;
	long result;

	if (!cgroup_path) return 0;

	fd_dir = open(cgroup_path, O_RDONLY | O_DIRECTORY);
	if (fd_dir < 0) return 0;

	result = read_long_at_file(10, fd_dir, "cpu.shares");
	(void) close(fd_dir);

	if (result > 1024) {
		result = ceildivl(result, 1024);

		/* adjust */
		if (!result) result = 1;
	}

	return clamp_cpucount(result);
}

static
int get_quota_v2(const char * cgroup_path)
{
	FILE * f = NULL;
	long result;

	if (!cgroup_path) return 0;

	f = fopen_path(cgroup_path, "cpu.max", O_RDONLY, "r");
	if (!f) return 0;

	result = 0;
	do {
		const unsigned int n_part = 2;

		char buf[128];
		char * part[n_part + 1];
		long cfs_quota, cfs_period;

		if (!fgets_noeol(buf, sizeof(buf), f))
			break;

		if (split_string(buf, ' ', n_part, part) < n_part)
			break;

		cfs_quota  = read_long_str(10, part[0]);
		cfs_period = read_long_str(10, part[1]);

		if ((cfs_quota > 0) && (cfs_period > 0)) {
			result = ceildivl(cfs_quota, cfs_period);

			/* adjust */
			if (!result) result = 1;
		}
	} while (0);

	(void) fclose(f);

	return clamp_cpucount(result);
}

/* misc functions */

static
long cpulist_to_count(const char * string)
{
	const int n_range = 2;

	char buf[128];
	char * range[n_range + 1];
	long result, a, b;
	const char * s = NULL;
	const char * t = NULL;

	if (!string) return 0;

	result = 0;
	s = string;
	while (s) {
		if (!(s[0])) break;

		t = next_token(s, ',');
		if (t) {
			a = t - s - 1;
			(void) memcpy(buf, s, a);
			buf[a] = 0;
		} else {
			(void) memset(buf, 0, sizeof(buf));
			strncpy(buf, s, sizeof(buf) - 1);
		}

		switch (split_string(buf, '-', n_range, range)) {
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

		s = t;
	}

	return result;
}

static
long cpulist_from_file(FILE * file)
{
	long result;
	char buf[16384];

	if (!file) return 0;

	result = 0;
	(void) memset(buf, 0, sizeof(buf));
	if (fgets_noeol(buf, sizeof(buf) - 1, file))
		result = cpulist_to_count(buf);

	return result;
}

static
long cpulist_from_path(const char * directory, const char * filepath)
{
	FILE * f = NULL;
	long result;

	if (!directory) return 0;
	if (!filepath)  return 0;

	if (directory)
		f = fopen_path(directory, filepath, O_RDONLY, "r");
	else
		f = fopen(filepath, "r");

	if (!f) return 0;

	result = cpulist_from_file(f);

	(void) fclose(f);

	return result;
}

static
size_t get_system_cpuset_len(void)
{
	int i;
	size_t u, t;

	i = read_int_file(10, "/sys/devices/system/cpu/kernel_max");
	if ((i >= 0) && (i < (INT_MAX / 2))) {
		u = i + 1;
		// u = ceildiv(i + 1, sizeof(size_t)) * sizeof(size_t);
		t = u % sizeof(size_t);
		if (t) u += sizeof(size_t) - t;
	}
	else
		u = nproc_sched_getaffinity_ex(0, 0, NULL, NULL);

	return u;
}

#include "../misc/ext-c-end.h"

#endif /* HEADER_INCLUDED_INCONTAINER_NPROC */
