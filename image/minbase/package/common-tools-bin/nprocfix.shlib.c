/*
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2020 Andrei Pangin
 * (c) 2022-2023 Konstantin Demin
 */

long sysconf(int name);
typedef long (* sysconf_proc_t )(int);
static sysconf_proc_t real_sysconf = 0;

#define NPROC_SYSCONF_PROC real_sysconf

#include "nproc.h"

#include <dlfcn.h>

static int container_cpus = 0;

static int init_real_sysconf(void);
static int init_real_sched_getaffinity(void);
static int find_container_cpus(void);

__attribute__((constructor))
static
void init_online_cpus()
{
	init_real_sysconf();
	init_real_sched_getaffinity();

	container_cpus = find_container_cpus();

	char _nproc[16];
	memset(_nproc, 0, sizeof(_nproc));
	sprintf(_nproc, "%d", container_cpus);
	setenv(env_nproc, _nproc, 1);
}

int sched_getaffinity(pid_t pid, size_t cpusetsize, cpu_set_t * mask);
typedef int (* sched_getaffinity_proc_t )(pid_t, size_t, cpu_set_t *);
static sched_getaffinity_proc_t real_sched_getaffinity = 0;

// Fake sysconf(_SC_NPROCESSORS_CONF) and sysconf(_SC_NPROCESSORS_ONLN) to return container_cpus
long sysconf(int name)
{
	switch (name) {
	case _SC_NPROCESSORS_CONF:
		// -fallthrough
	case _SC_NPROCESSORS_ONLN:
		if (container_cpus > 0) return container_cpus;
		break;
	}

	if (!init_real_sysconf())
		return -1;

	return real_sysconf(name);
}

// Fake sched_getaffinity() to return the set of [0..container_cpus-1]
int sched_getaffinity(pid_t pid, size_t cpusetsize, cpu_set_t * mask)
{
	if (container_cpus > 0) {
		CPU_ZERO_S(cpusetsize, mask);
		for (int i = 0; i < container_cpus; i++) {
			CPU_SET_S(i, cpusetsize, mask);
		}
		return 0;
	}

	if (!init_real_sched_getaffinity())
		return -1;

	return real_sched_getaffinity(pid, cpusetsize, mask);
}

static
void * dlsym_wrap(const char * name)
{
	void * proc = NULL;
	int err = 0;

	errno = 0;
	proc = dlsym(RTLD_NEXT, name);
	if (proc == NULL) {
		err = (errno != 0) ? errno : ENOSYS;
		fprintf(stderr, "# libnprocfix.so: unable to find real %s() proc - this is likely an ERROR!\n", name);
		errno = err;
	}

	return proc;
}

static
int init_real_sysconf(void)
{
	static int init = 0;

	if (!init) {
		real_sysconf = (sysconf_proc_t) dlsym_wrap("sysconf");
		init = 1;
	}

	return (real_sysconf) ? 1 : 0;
}

static
int init_real_sched_getaffinity(void)
{
	static int init = 0;

	if (!init) {
		real_sched_getaffinity = (sched_getaffinity_proc_t) dlsym_wrap("sched_getaffinity");
		init = 1;
	}

	return (real_sched_getaffinity) ? 1 : 0;
}
