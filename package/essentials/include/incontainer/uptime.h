/*
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2023 Konstantin Demin
 */

#ifndef HEADER_INCLUDED_INCONTAINER_UPTIME
#define HEADER_INCLUDED_INCONTAINER_UPTIME 1

#include "../misc/ext-c-begin.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <sys/stat.h>

#include "../io/log-stderr.h"
#include "../misc/cc-inline.h"
#include "../misc/tls-var.h"
#include "../num/minmax.h"


typedef struct {
	time_t since,
	       now,
	       total_seconds;
	int seconds,
	    minutes,
	    hours,
	    days,
	    weeks,
	    years,
	    total_days;
	struct tm now_tm;
} time_duration;

static
long get_system_uptime(time_duration * duration) {
	static const char * timeref_path = "/sys/kernel";
	static const char * log_pfx = "uptime";

	static int init = 0;
	static time_t since;

	long ret = -1;
	time_t now, range;
	struct tm now_tm;
	ldiv_t qr;

	// (void) timespec_get(&now_ts, TIME_UTC);
	now = time(NULL);
	if (now == ((time_t) -1)) {
		log_stderr_error_ex(log_pfx, errno, NULL);
		return ret;
	}

	(void) memset(&now_tm, 0, sizeof(now_tm));
	if (!localtime_r(&now, &now_tm)) {
		log_stderr_error_ex(log_pfx, errno, NULL);
		return ret;
	}

	if (!init) {
		struct stat st;

		(void) memset(&st, 0, sizeof(st));
		if (lstat(timeref_path, &st) < 0) {
			log_stderr_path_error_ex(log_pfx, timeref_path, errno, NULL);
			return ret;
		}

		since = min_positive(st.st_atim.tv_sec, st.st_ctim.tv_sec);
		since = min_positive(since, st.st_mtim.tv_sec);
		/* "since" is local - adjust to UTC */
		since -= now_tm.tm_gmtoff;

		init = 1;
	}

	/* "now" is local - adjust to UTC */
	range = now - now_tm.tm_gmtoff - since;
	ret = (long) range;

	if (ret < 0) {
		errno = EAGAIN;
		return -1;
	}

	if (!duration) return ret;

	(void) memset(duration, 0, sizeof(time_duration));

	/* "since" is UTC - adjust to local */
	duration->since = since + now_tm.tm_gmtoff;
	duration->now = now;
	duration->total_seconds = range;

	while (range) {
		qr = ldiv(range, 60);
		duration->seconds = qr.rem;
		if (!(range = qr.quot)) break;

		qr = ldiv(range, 60);
		duration->minutes = qr.rem;
		if (!(range = qr.quot)) break;

		qr = ldiv(range, 24);
		duration->hours = qr.rem;
		if (!(range = qr.quot)) break;

		duration->total_days = range;

		qr = ldiv(range, 365);
		duration->days = qr.rem;
		duration->years = qr.quot;

		qr = ldiv(duration->days, 7);
		duration->weeks = qr.quot;
		duration->days = qr.rem;

		break;
	}

	(void) memcpy(&duration->now_tm, &now_tm, sizeof(now_tm));

	return ret;
}

static const char * str_empty = "";
static const char * str_comma = ", ";

/* for use by sprint_uptime_standard() and sprint_uptime_pretty() */
TLS_OPAQUE(char buf[256]);

static
char * sprint_uptime_standard(void)
{
	int pos;
	time_duration d;

	(void) memset(buf, 0, sizeof(buf));

	if (get_system_uptime(&d) < 0)
		return buf;

	/* leading space is mandatory / for historical reasons */
	pos = sprintf(buf, " %02d:%02d:%02d up ",
	              d.now_tm.tm_hour, d.now_tm.tm_min, d.now_tm.tm_sec);

	if (d.total_days)
		pos += sprintf(buf + pos, "%d %s, ",
		               d.total_days,
		               (d.total_days > 1) ? "days" : "day");

	if (d.hours)
		pos += sprintf(buf + pos, "%d:%02d",
		               d.hours, d.minutes);
	else
		pos += sprintf(buf + pos, "%d min",
		               d.minutes);

	/* fake remaining info */
	(void) strcat(buf + pos, ", 1 user, load average: 0.01, 0.01, 0.01");

	return buf;
}

static
char * sprint_uptime_pretty(void)
{
	int pos = 3; /* initial buffer content */
	int comma = 0;
	time_duration d;

	(void) memset(buf, 0, sizeof(buf));

	if (get_system_uptime(&d) < 0)
		return buf;

	(void) strcat(buf, "up ");

	if (d.years) {
		pos += sprintf(buf + pos, "%s%d %s",
		               (comma) ? str_comma : str_empty,
		               d.years,
		               (d.years > 1) ? "years" : "year");
		comma = 1;
	}

	if (d.weeks) {
		pos += sprintf(buf + pos, "%s%d %s",
		               (comma) ? str_comma : str_empty,
		               d.weeks,
		               (d.weeks > 1) ? "weeks" : "week");
		comma = 1;
	}

	if (d.days) {
		pos += sprintf(buf + pos, "%s%d %s",
		               (comma) ? str_comma : str_empty,
		               d.days,
		               (d.days > 1) ? "days" : "day");
		comma = 1;
	}

	if (d.hours) {
		pos += sprintf(buf + pos, "%s%d %s",
		               (comma) ? str_comma : str_empty,
		               d.hours,
		               (d.hours > 1) ? "hours" : "hour");
		comma = 1;
	}

	(void) sprintf(buf + pos, "%s%d %s",
	               (comma) ? str_comma : str_empty,
	               d.minutes,
	               (d.minutes != 1) ? "minutes" : "minute");

	return buf;
}

#include "../misc/ext-c-end.h"

#endif /* HEADER_INCLUDED_INCONTAINER_UPTIME */
