/*
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2023 Konstantin Demin
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

#include <cstdint>

#include "include/misc/ext-c-begin.h"

#include <getopt.h>

#include "include/misc/ext-c-end.h"

#include "include/incontainer/uptime.h"

#define UPTIME_OPTS "hpsSV"

static void version(void) __attribute__ ((noreturn));

static
void version(void) {
	static const char version_msg[] = "uptime 0.0.1\n";
	(void) write(STDOUT_FILENO, version_msg, sizeof(version_msg));
	exit(0);
}

static void usage(int retcode) __attribute__ ((noreturn));

static
void usage(int retcode)
{
	static const char usage_msg[] =
	"uptime 0.0.1\n"
	"Usage: uptime [-" UPTIME_OPTS "]\n"
	" -h, --help     - show this message\n"
	" -p, --pretty   - show uptime in pretty format\n"
	" -s, --since    - system up since\n"
	" -S, --seconds  - show uptime in seconds\n"
	" -V, --version  - version information\n"
	;

	(void) write(STDERR_FILENO, usage_msg, sizeof(usage_msg));

	exit(retcode);
}

static const struct option uptime_longopts[] = {
	{ "help",    no_argument, NULL, 'h' },
	{ "pretty",  no_argument, NULL, 'p' },
	{ "since",   no_argument, NULL, 's' },
	{ "seconds", no_argument, NULL, 'S' },
	{ "version", no_argument, NULL, 'V' },
	{ NULL, 0, NULL, 0 }
};

enum struct uptime_mode : unsigned int {
	normal = 0,
	pretty,
	since,
	seconds,
};
static uptime_mode mode = uptime_mode::normal;

static const char * log_pfx = "uptime:";

static void parse_opts(int argc, char * const * argv);
static void print_uptime_since(time_duration * duration);

int main(int argc, char * argv[])
{
	time_duration d;

	parse_opts(argc, (char * const *) argv);

	if (get_system_uptime(&d) < 0)
		return errno;

	errno = 0;

	switch (mode) {
	case uptime_mode::normal:
		(void) printf("%s\n", sprint_uptime_standard());
		break;
	case uptime_mode::pretty:
		(void) printf("%s\n", sprint_uptime_pretty());
		break;
	case uptime_mode::since:
		print_uptime_since(&d);
		break;
	case uptime_mode::seconds:
		(void) printf("%ld\n", d.total_seconds);
		break;
	}

	return errno;
}

static
void parse_opts(int argc, char * const * argv)
{
	int o;
	while ((o = getopt_long(argc, argv, UPTIME_OPTS, uptime_longopts, NULL)) != -1) {
		switch (o) {
		case 'h':
			usage(0);
		case 'V':
			version();
		case 'p':
			mode = uptime_mode::pretty;
			return;
		case 's':
			mode = uptime_mode::since;
			return;
		case 'S':
			mode = uptime_mode::seconds;
			return;
		}

		usage(EINVAL);
	}
}

static
void print_uptime_since(time_duration * duration)
{
	struct tm t;

	(void) memset(&t, 0, sizeof(t));
	if (!localtime_r(&duration->since, &t)) {
		log_stderr_error_ex(log_pfx, errno, NULL);
		return;
	}

	(void) printf("%04d-%02d-%02d %02d:%02d:%02d\n",
	              t.tm_year + 1900, t.tm_mon + 1, t.tm_mday,
	              t.tm_hour, t.tm_min, t.tm_sec);
}
