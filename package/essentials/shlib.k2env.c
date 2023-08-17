/*
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2020 Andrei Pangin
 * (c) 2022-2023 Konstantin Demin
 */

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__  1
#endif

#ifndef _LARGEFILE_SOURCE
#define _LARGEFILE_SOURCE
#endif

#ifndef _FILE_OFFSET_BITS
#define _FILE_OFFSET_BITS 64
#endif

#ifndef _XOPEN_SOURCE
#define _XOPEN_SOURCE 700
#endif

#include <dlfcn.h>
#include <errno.h>
#include <pthread.h>
#include <sched.h>
#include <unistd.h>

#include "include/io/log-stderr.h"
#include "include/misc/cc-inline.h"
#include "include/num/ceildiv.h"
#include "include/num/minmax.h"

#include "include/incontainer/nproc.h"
#include "include/incontainer/uptime.h"

/* embeds CC_NO_INLINE */
#define SHLIB_EXPORT __attribute__ (( used,noinline,visibility("default") ))

static int    ncpu       = 0;
static size_t cpuset_len = 0;

static int init_real_sysconf(void);

/* library entrypoint */

__attribute__(( constructor ))
static
void init_shlib(void)
{
	(void) init_real_sysconf();

	/* incontainer/nproc.h */

	ncpu = get_container_cpus();
	if (ncpu < 1) ncpu = 1;
	set_env_container_cpus(ncpu);

	cpuset_len = get_system_cpuset_len();

	/* set affinity if requested by env */
	adjust_container_cpuset(ncpu);

	/* incontainer/uptime.h */

	(void) get_system_uptime(NULL);
}

/* libc override section */

SHLIB_EXPORT
int get_nprocs(void)
{
	return ncpu;
}

SHLIB_EXPORT
int get_nprocs_conf(void)
{
	return ncpu;
}

typedef long (* proc_t_sysconf )(int);
static proc_t_sysconf real_sysconf = 0;

static
CC_INLINE
long wrap_sysconf(int name)
{
	return (init_real_sysconf()) ? real_sysconf(name) : -1;
}

static
CC_FORCE_INLINE
long new_sysconf(int name)
{
	switch (name) {
	case _SC_NPROCESSORS_CONF: /* -fallthrough */
	case _SC_NPROCESSORS_ONLN:
		return ncpu;
	}

	return wrap_sysconf(name);
}

SHLIB_EXPORT
long sysconf(int name)
{
	return new_sysconf(name);
}

SHLIB_EXPORT
long __sysconf(int name)
{
	return new_sysconf(name);
}

static
CC_FORCE_INLINE
int new_sched_cpucount(size_t setsize, const cpu_set_t * cpuset)
{
	int x = nproc_sched_cpucount(setsize, cpuset);
	return min(x, ncpu);
}

/* NB: not a real exported symbol as of 2023.08.01 in glibc 2.37 */
SHLIB_EXPORT
int sched_cpucount(size_t setsize, const cpu_set_t * cpuset)
{
	return new_sched_cpucount(setsize, cpuset);
}

SHLIB_EXPORT
cpu_set_t * __sched_cpualloc(size_t count)
{
	return malloc((cpuset_len) ? cpuset_len : CPU_ALLOC_SIZE(count));
}

SHLIB_EXPORT
int __sched_cpucount(size_t setsize, const cpu_set_t * cpuset)
{
	return new_sched_cpucount(setsize, cpuset);
}

static
CC_FORCE_INLINE
int new_getaffinity(pid_t tid, size_t cpusetsize, cpu_set_t * cpuset)
{
	if (!nproc_sched_getaffinity(tid, cpusetsize, cpuset))
		return -1;

	(void) adjust_cpuset_to_count_random(cpusetsize, cpuset, ncpu);
	return 0;
}

SHLIB_EXPORT
int sched_getaffinity(pid_t pid, size_t cpusetsize, cpu_set_t * cpuset)
{
	return new_getaffinity(pid, cpusetsize, cpuset);
}

SHLIB_EXPORT
int pthread_getaffinity_np(pthread_t tid, size_t cpusetsize, cpu_set_t * cpuset)
{
	return new_getaffinity(tid, cpusetsize, cpuset);
}

/* libprocps override section */

SHLIB_EXPORT
int procps_uptime(double * uptime_secs, double * idle_secs)
{
	long seconds = get_system_uptime(NULL);
	if (seconds < 0)
		return -errno;

	if (uptime_secs)
		*uptime_secs = (double) seconds;
	if (idle_secs)
		*idle_secs = 0.0;

	return 0;
}

SHLIB_EXPORT
char * procps_uptime_sprint(void)
{
	return sprint_uptime_standard();
}

SHLIB_EXPORT
char * procps_uptime_sprint_short(void)
{
	return sprint_uptime_pretty();
}

/* own functions */

static
void * dlsym_wrap(const char * name)
{
	void * proc = NULL;

	errno = 0;
	proc = dlsym(RTLD_NEXT, name);
	if (!proc) {
		log_stderr_error_ex("k2env.so",
		                    (errno != 0) ? errno : ENOSYS,
		                    "unable to find %s() function", name);
	}

	return proc;
}

static
int init_real_sysconf(void)
{
	static int init = 0;

	errno = 0;
	if (!init) {
		// real_sysconf = (proc_t_sysconf) dlsym_wrap("sysconf");
		union {
			proc_t_sysconf func;
			void * ptr;
		} tmp;
		tmp.ptr = dlsym_wrap("sysconf");
		real_sysconf = tmp.func;
		init = 1;
	}

	return (real_sysconf) ? 1 : 0;
}
