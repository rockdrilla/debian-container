/* xvp: simple (or sophisticated?) launcher
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 *
 * Example usage in shell scripts:
 *   xvp -u program /tmp/list
 * is roughly equal to:
 *   xargs -0 -a /tmp/list program &
 *   wait ; rm -f /tmp/list
 * where /tmp/list is file with NUL-separated arguments
 * except:
 * - `xvp' is NOT replacement for `xargs' or `xe'
 * - return code is EXACT program return code
 *   or appropriate error code
 * - /tmp/list is deleted by `xvp' as early as possible
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

#include <cerrno>
#include <climits>
#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <cstring>

#include "include/misc/ext-c-begin.h"

#include <dirent.h>
#include <fcntl.h>

#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/wait.h>

#include "include/misc/ext-c-end.h"

#include "include/io/const.h"
#include "include/io/log-stderr.h"
#include "include/misc/cc-inline.h"

#include "include/uvector/uvector.hh"

#define XVP_OPTS "a:cfhinsu"

static
void usage(int retcode)
{
	static const char usage_msg[] =
	"xvp 0.3.1\n"
	"Usage: xvp [-a <arg0>] [-cfhinsu] <program> [..<common args>] {<arg file>|-}\n"
	" -h  - help: show this message\n"
	" -a  - arg0: set argv[0] for <program> to <arg0>\n"
	" -c  - clean env: run <program> with empty environment\n"
	" -i  - info: print limits and do nothing\n"
	" -n  - no wait: run as much processes at once as possible\n"
	" -f  - force: force _single_ <program> execution or return error\n"
	" -s  - strict: stop after first failed child process\n"
	" -u  - unlink: delete <arg file> if it's regular file\n"
	"\n"
	" <arg file>  - file with NUL-separated arguments or stdin if \"-\" was specified\n"
	"\n"
	" Notes:\n"
	" - options \"-n\" and \"-s\" are mutually exclusive;\n"
	" - option \"-u\" is ignored if reading from stdin.\n"
	;

	(void) write(STDERR_FILENO, usage_msg, sizeof(usage_msg));

	exit(retcode);
}

static const char * log_pfx = "xvp:";

static struct {
	char * Arg0;
	uint8_t _Script_stdin,
	        Clean_env,
	        Force_once,
	        Info_only,
	        No_wait,
	        Strict,
	        Unlink_argfile;
} opt;

static const char * callee = nullptr;
static const char * script = nullptr;

#define do_log(...)  log_stderr_ex(log_pfx, NULL, __VA_ARGS__)
static void do_log_error(int error_num, const char * where);
static void do_log_path_error(int error_num, const char * where, const char * name);

static void parse_opts(int argc, char * const * argv);
static void prepare(int argc, char * argv[]);
static void run(void);

int main(int argc, char * argv[])
{
	if (argc < 2) usage(0);

	parse_opts(argc, (char * const *) argv);
	prepare(argc, argv);
	run();

	return 0;
}

static int handle_file_type(uint32_t type, const char * arg);

static
void parse_opts(int argc, char * const * argv)
{
	int o;

	memset(&opt, 0, sizeof(opt));

	while ((o = getopt(argc, argv, "++" XVP_OPTS)) != -1) {
		switch (o) {
		case 'h':
			usage(0);
			break;
		case 'a':
			if (opt.Arg0) break;
			opt.Arg0 = optarg;
			continue;
		case 'c':
			if (opt.Clean_env) break;
			opt.Clean_env = 1;
			continue;
		case 'f':
			if (opt.Force_once) break;
			opt.Force_once = 1;
			continue;
		case 'i':
			if (opt.Info_only) break;
			opt.Info_only = 1;
			continue;
		case 'n':
			if (opt.No_wait || opt.Strict) break;
			opt.No_wait = 1;
			continue;
		case 's':
			if (opt.No_wait || opt.Strict) break;
			opt.Strict = 1;
			continue;
		case 'u':
			if (opt.Unlink_argfile) break;
			opt.Unlink_argfile = 1;
			continue;
		}

		usage(EINVAL);
	}

	if (((argc - optind) < 2) && !opt.Info_only)
		usage(EINVAL);
}

static
size_t get_env_size(void)
{
	static size_t x = 0;
	if (x) return x;

	for (char ** p = environ; p && *p; ++p) {
		x += strlen(*p) + 1;
	}

	return x;
}

static
size_t get_arg_max(void)
{
	static size_t x = 0;
	if (x) return x;

#ifdef _SC_ARG_MAX
	long len = sysconf(_SC_ARG_MAX);
	if (len > 0) return x = len;
#endif

#ifdef ARG_MAX
	if (ARG_MAX > 0) return x = ARG_MAX;
#endif

#ifdef RLIMIT_STACK
	struct rlimit stack_limit;
	if (!getrlimit(RLIMIT_STACK, &stack_limit))
		return x = (stack_limit.rlim_cur / 4);
#endif

	/* differs from "findutils" variant */
	return x = (LONG_MAX >> 1);
}

static size_t size_env, size_args, argc_max;
static uvector::str<> argv_init, argv_curr;

static struct stat f_stat;

/* differs from "findutils" variant */
static constexpr size_t argc_padding = 4;

static
CC_INLINE
size_t get_argv_fullsize(const uvector::str<> * argv)
{
	return argv->used() + argv->count() * sizeof(size_t);
}

static
CC_INLINE
bool is_argv_full(const uvector::str<> * argv) {
	if (argv->count() >= argc_max)
		return true;

	if (get_argv_fullsize(argv) >= size_args)
		return true;

	return false;
}

static
CC_INLINE
bool is_argv_full(const uvector::str<> * argv, size_t extra_arg_length) {
	if (argv->count() >= argc_max)
		return true;

	if ((get_argv_fullsize(argv) + extra_arg_length + 1) >= size_args)
		return true;

	return false;
}

static
void prepare(int argc, char * argv[])
{
	callee = argv[optind];
	script = argv[argc - 1];
	if (strcmp(script, "-") == 0) {
		opt._Script_stdin = 1;
		script = "/dev/stdin";
	}

	size_env = get_env_size();
	size_t x = roundbyl(size_env, memfun_page_default);

	const uint32_t POSIX_ENV_HEADROOM = memfun_page_default / 2;
	if ((x - size_env) <= POSIX_ENV_HEADROOM)
		x += memfun_page_default;

	size_env = x;
	if (opt.Clean_env) {
		size_env = POSIX_ENV_HEADROOM;
	}

	size_args = get_arg_max() - size_env;
	argc_max = (size_args / sizeof(size_t)) - argc_padding;
	size_args -= argc_padding * sizeof(size_t);

	argv_init.append(opt.Arg0 ? opt.Arg0 : callee);
	for (int i = (optind + 1); i < (argc - 1); i++) {
		argv_init.append(argv[i]);
	}

	if (is_argv_full(&argv_init)) {
		do_log_error(E2BIG, "prepare()");
		exit(E2BIG);
	}
}

static
CC_INLINE
void do_sleep(void)
{
	static int init = 0;
	static struct timespec sleep_ts;

	if (!init) {
		sleep_ts.tv_sec  = 0;
		sleep_ts.tv_nsec = 1;
		init = 1;
	}

	(void) nanosleep(&sleep_ts, NULL);
}

static
void do_exec(void)
{
	if (argv_curr.count() == argv_init.count())
		return;

	argv_init.free();

	if (opt._Script_stdin) {
		int fd_null = open("/dev/null", O_RDONLY);
		if (fd_null >= 0) {
			(void) dup2(fd_null, 0);
			(void) close(fd_null);
		}
		else
			(void) close(0);
	}

	auto argv = argv_curr.to_ptrlist<char * const>();
	int err = 0;
	while (!err) {
		if (opt.Clean_env) {
			char * envp[] = { nullptr };
			(void) execvpe(callee, argv, envp);
		}
		else
			(void) execvp(callee, argv);

		/* execution follows here in case of errors */
		err = errno;

		if (opt.No_wait) {
			opt.No_wait = 0;
			err = 0;

			(void) wait(nullptr);
			do_sleep();
		}
	}

	do_log_error(err, "do_exec()::execvp(3)");
	exit(err);
}

static
CC_INLINE
int compare_stats(const struct stat * s1, const struct stat * s2)
{
	if (s1->st_dev != s2->st_dev) return 0;
	if (s1->st_ino != s2->st_ino) return 0;

	auto m1 = s1->st_mode & S_IFMT;
	auto m2 = s2->st_mode & S_IFMT;

	return (m1 == m2);
}

static
void delete_script(void)
{
	if (opt._Script_stdin) return;
	if (!opt.Unlink_argfile) return;

	opt.Unlink_argfile = 0;

	struct stat l_stat;
	(void) memset(&l_stat, 0, sizeof(l_stat));
	if (lstat(script, &l_stat) < 0) {
		do_log_path_error(errno, "delete_script()::lstat(2)", script);
		return;
	}

	if (!compare_stats(&f_stat, &l_stat)) return;

	if (DT_REG != IFTODT(l_stat.st_mode)) return;

	(void) unlink(script);
}

static
void run(void)
{
	size_t s_buf_arg = 32 * memfun_page_size();

	if (opt.Info_only) {
		(void) fprintf(stderr, "System page size: %lu\n", memfun_page_size());
		(void) fprintf(stderr, "Maximum (single) argument length: %lu\n", s_buf_arg);
		(void) fprintf(stderr, "Environment size, as is: %lu\n", get_env_size());
		(void) fprintf(stderr, "Environment size, round: %lu\n", size_env);
		(void) fprintf(stderr, "Maximum arguments length, system:  %lu\n", get_arg_max());
		(void) fprintf(stderr, "Maximum arguments length, current: %lu\n", size_args);
		(void) fprintf(stderr, "Initial arguments length:          %lu\n", get_argv_fullsize(&argv_init));
		(void) fprintf(stderr, "Maximum argument count: %lu\n", argc_max);
		(void) fprintf(stderr, "Initial argument count: %u\n", argv_init.count());
		return;
	}

	int err = 0;
	int fd = -1;

	struct stat tmp_stat;

	size_t n_buf = 0, total = 0, block;
	ssize_t n_read = 0;
	char * tbuf = nullptr;
	uint32_t arg_idx;
	int arg_pend = 0, exec_ready = 0;
	pid_t child;
	siginfo_t child_info;

	size_t s_buf_read = s_buf_arg + memfun_page_size(); /* s_buf_arg + one extra page */
	auto buf_arg  = memfun_t_alloc<char>(s_buf_arg);
	auto buf_read = memfun_t_alloc<char>(s_buf_read);
	if ((!buf_arg) || (!buf_read)) {
		err = errno;
		if (!err) err = ENOMEM;
		goto _run_err;
	}

	argv_curr.free();
	argv_curr.append(argv_init);
	if (!argv_curr.allocated()) {
		err = errno;
		if (!err) err = ENOMEM;
		goto _run_err;
	}

	if (opt._Script_stdin)
		fd = 0;
	else {
		fd = open(script, O_RDONLY | O_CLOEXEC);
		if (fd < 0) {
			err = errno;
			do_log_path_error(err, "run()::open(2)", script);
			exit(err);
		}
	}

	(void) memset(&f_stat, 0, sizeof(f_stat));
	if (fstat(fd, &f_stat) < 0) {
		err = errno;
		do_log_path_error(err, "run()::fstat(2)", script);
		exit(err);
	}
	f_stat.st_mode &= S_IFMT;

	if (!handle_file_type(IFTODT(f_stat.st_mode), script)) {
		err = EINVAL;
		exit(err);
	}

	while (!opt._Script_stdin) {
		(void) memset(&tmp_stat, 0, sizeof(tmp_stat));
		if (fstat(0, &tmp_stat) < 0) break;

		if (!compare_stats(&f_stat, &tmp_stat)) break;

		opt._Script_stdin = 1;
		(void) close(fd);
		fd = 0;
	}

	(void) memset(buf_arg, 0, s_buf_arg);

	for (;;) {
		if (arg_pend) {
			arg_idx = argv_curr.append(buf_arg, total);
			if (uvector::str<>::is_inv(arg_idx)) {
				err = errno;
				if (!err) err = ENOMEM;
				goto _run_out;
			}

			total = 0;
			arg_pend = 0;
			(void) memset(buf_arg, 0, s_buf_arg);
		}

		if (!n_buf) {
			(void) memset(buf_read, 0, s_buf_read);
			n_read = read(fd, buf_read, s_buf_read);
			if (n_read > 0) n_buf = (size_t) n_read;
			tbuf = buf_read;
		}

		while (n_buf > 0) {
			block = strnlen(tbuf, n_buf);
			total += block;

			if ((total + 1) >= s_buf_arg) {
				if (block == n_buf) {
					n_buf = 0;
					break;
				}

				block++; n_buf -= block; tbuf += block;

				total = 0;
				(void) memset(buf_arg, 0, s_buf_arg);

				continue;
			}

			(void) memcpy(buf_arg + total - block, tbuf, block);

			if (block == n_buf) {
				n_buf = 0;
				break;
			}

			block++; n_buf -= block; tbuf += block;

			if (is_argv_full(&argv_curr, total)) {
				exec_ready = 1;
				arg_pend = 1;
				break;
			}

			arg_idx = argv_curr.append(buf_arg, total);
			if (uvector::str<>::is_inv(arg_idx)) {
				err = errno;
				if (!err) err = ENOMEM;
				goto _run_out;
			}

			total = 0;
			(void) memset(buf_arg, 0, s_buf_arg);

			if (is_argv_full(&argv_curr, 0)) {
				exec_ready = 1;
				break;
			}
		}

		if (n_read <= 0) break;

		if (!exec_ready) continue;

		if (opt.Force_once) {
			err = E2BIG;
			goto _run_out;
		}

		child = fork();
		if (!child) do_exec();
		if (child == -1) {
			err = errno;
			if (!err) err = ENOMEM;
			goto _run_out;
		}

		(void) waitpid(-1, nullptr, WNOHANG);

		if (!opt.No_wait) {
			err = ECHILD;

			/* wait for child */
			do {
				do_sleep();

				(void) memset(&child_info, 0, sizeof(child_info));
				if (waitid(P_PID, child, &child_info, WEXITED | WSTOPPED | WCONTINUED))
					break;

				switch (child_info.si_code) {
				case CLD_KILLED:    break;
				case CLD_DUMPED:    break;
				case CLD_TRAPPED:   break;
				case CLD_STOPPED:   break;
				case CLD_CONTINUED: break;
				case CLD_EXITED:
					err = child_info.si_status;
					break;
				default:
					log_stderr("xvp: child process %d has been turned into unknown state (siginfo_t.si_code=%d)",
					           child, child_info.si_code);
					child = 0;
					break;
				}

				if (!opt.Strict) {
					switch (child_info.si_code) {
					case CLD_EXITED: /* -fallthrough */
					case CLD_KILLED: /* -fallthrough */
					case CLD_DUMPED: /* -fallthrough */
					case CLD_TRAPPED:
						child = 0;
						break;
					}
				} else {
					switch (child_info.si_code) {
					case CLD_STOPPED:
						log_stderr("xvp: child process %d has been stopped", child);
						break;
					case CLD_CONTINUED:
						log_stderr("xvp: child process %d has been continued", child);
						break;
					case CLD_EXITED:
						if (!err) {
							child = 0;
							break;
						}

						log_stderr("xvp: child process %d has exited with non-null return code: %d", child, err);
						goto _run_out;
					case CLD_KILLED:
						log_stderr("xvp: child process %d has been killed by signal %d", child, child_info.si_status);
						goto _run_out;
					case CLD_DUMPED:
						log_stderr("xvp: child process %d has been dumped by signal %d", child, child_info.si_status);
						goto _run_out;
					case CLD_TRAPPED:
						log_stderr("xvp: child process %d has been trapped by signal %d", child, child_info.si_status);
						goto _run_out;
					}
				}
			} while (child);
		}

		/* do rest of work */
		exec_ready = 0;

		/* refine current argv */
		argv_curr.free();
		(void) argv_curr.append(argv_init);
		if (!argv_curr.allocated()) {
			err = errno;
			if (!err) err = ENOMEM;
			goto _run_out;
		}
	}

	(void) close(fd);
	fd = -1;

	delete_script();

	(void) memset(&child_info, 0, sizeof(child_info));
	(void) waitid(P_ALL, 0, &child_info, WEXITED);
	do_sleep();

	do_exec();
	exit(err);

_run_out:
	if (fd >= 0)
		(void) close(fd);

	delete_script();

_run_err:
	do_log_error(err, "run()");
	exit(err);
}

static
int handle_file_type(uint32_t type, const char * arg)
{
	const char * e_type = nullptr;
	switch (type) {
	case DT_BLK:  break;
	case DT_CHR:  break;
	case DT_FIFO: break;
	case DT_REG:  break;
	case DT_SOCK: break;
	case DT_DIR:  e_type = "directory";          break;
	case DT_LNK:  e_type = "symbolic link";      break;
	default:      e_type = "unknown entry type"; break;
	}

	if (!e_type) return 1;

	(void) fprintf(stderr, "xvp: <arg file> %s is type of %s\n", arg, e_type);
	return 0;
}

static
CC_INLINE
void do_log_error(int error_num, const char * where)
{
	log_stderr_error_ex(log_pfx, error_num, "%s", where);
}

static
CC_INLINE
void do_log_path_error(int error_num, const char * where, const char * name)
{
	log_stderr_path_error_ex(log_pfx, name, error_num, "%s", where);
}
