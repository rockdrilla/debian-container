/*
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2023 Konstantin Demin
 */

#define _GNU_SOURCE

#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "include/io/const.h"

static const char env_ld_preload[] = "LD_PRELOAD";
static const char env_nprocfix[] = "NPROCFIX";
static const char libnprocfix_so[] = "libnprocfix.so";
static const char exesuffix[] = ".real";

int main(int argc, char * argv[])
{
	const char * arg0 = argv[0];
	// in case of login shell
	if (arg0[0] == '-') arg0++;
	size_t arg0_len = strlen(arg0);
	if ((!arg0_len) || (arg0_len > (PATH_MAX - sizeof(exesuffix)))) {
		return ENOEXEC;
	}

	char new_preload[65536];
	memset(new_preload, 0, sizeof(new_preload));
	strcpy(new_preload, libnprocfix_so);

	char * env_curr = getenv(env_ld_preload);
	if (env_curr) {
		const char * s = NULL;
		size_t len = 0;
		char soname[PATH_MAX];

		for (s = env_curr; (*s) ; s += len, (*s) ? (s++) : s) {
			len = strcspn(s, " :");
			if ((!len) || (len >= sizeof(soname))) {
				continue;
			}

			memset(soname, 0, sizeof(soname));
			memcpy(soname, s, len);

			if (strstr(soname, libnprocfix_so)) {
				continue;
			}

			if ((strlen(new_preload) + len + 1) >= sizeof(new_preload)) {
				// soname doesn't fit in remaining space
				// TODO: maybe break?
				continue;
			}

			strcat(new_preload, ":");
			strcat(new_preload, soname);
		}
	}

	setenv(env_ld_preload, new_preload, 1);

	const char * exe;
	char exe_buf[PATH_MAX];

	const char * exe_env = getenv(env_nprocfix);
	if (exe_env) {
		exe = exe_env;
	} else {
		memset(exe_buf, 0, sizeof(exe_buf));
		strcpy(exe_buf, arg0);
		strcat(exe_buf, exesuffix);
		exe = exe_buf;
	}

	execvp(exe, argv);

	// execution follows here in case of errors
	return errno;
}
