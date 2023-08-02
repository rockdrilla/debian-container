/* is-elf: trivial file type check for ELF files
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 *
 * Rough alternative (but slow):
 *   file -L -N -F '|' -p -S /path/to/file \
 *   | mawk -F '|' 'BEGIN { ORS="\0"; } $2 ~ "^ ?ELF " { print $1; }'
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

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <sys/stat.h>

#include <elf.h>
#include <endian.h>

#include "include/misc/cc-inline.h"
#include "include/io/log-stderr.h"

#define IS_ELF_OPTS "hqvz"

static
void usage(int retcode)
{
	static const char usage_msg[] =
	"is-elf 0.0.2\n"
	"Usage: is-elf [-" IS_ELF_OPTS "] <file> [..<file>]\n"
	" -h  - help: show this message\n"
	" -q  - quiet: don't print error messages in stderr\n"
	" -v  - verbose: print information messages in stderr\n"
	" -z  - zero separator: separate entries with \\0 instead of \\n\n"
	;

	(void) write(STDERR_FILENO, usage_msg, sizeof(usage_msg));

	exit(retcode);
}

static const char * log_pfx = "is_elf:";

static struct {
	uint8_t Quiet,
	        Verbose,
	        Zero_separator;
} opt;

static char entry_separator = '\n';

#define do_log(...)  { if (!opt.Quiet) log_stderr_ex(log_pfx, NULL, __VA_ARGS__); }
static void do_log_path_error(int error_num, const char * where, const char * name);

static void parse_opts(int argc, char * const * argv);
static int is_elf(const char * arg);

int main(int argc, char * argv[])
{
	if (argc < 2) usage(0);

	parse_opts(argc, (char * const *) argv);

/* TODO */
#if 0
	{
		int any_elf = 0;
		for (int i = optind; i < argc; i++) {
			any_elf |= is_elf(argv[i]);
		}
		return (any_elf != 0) ? 0 : EINVAL;
	}
#endif

	for (int i = optind; i < argc; i++) {
		(void) is_elf(argv[i]);
	}
	return 0;
}

static
void parse_opts(int argc, char * const * argv)
{
	int o;

	memset(&opt, 0, sizeof(opt));

	while ((o = getopt(argc, argv, IS_ELF_OPTS)) != -1) {
		switch (o) {
		case 'h':
			usage(0);
			break;
		case 'q':
			if (opt.Quiet) break;
			opt.Quiet = 1;
			continue;
		case 'v':
			if (opt.Verbose) break;
			opt.Verbose = 1;
			continue;
		case 'z':
			if (opt.Zero_separator) break;
			opt.Zero_separator = 1;
			continue;
		}

		usage(EINVAL);
	}

	if (optind >= argc) usage(EINVAL);
	if (opt.Zero_separator) entry_separator = 0;
}

static int bo_target = ELFDATANONE;

static
CC_FORCE_INLINE
uint16_t u16toh(uint16_t value)
{
	return (bo_target == ELFDATA2LSB) ? le16toh(value) : be16toh(value);
}

static
CC_FORCE_INLINE
uint32_t u32toh(uint32_t value)
{
	return (bo_target == ELFDATA2LSB) ? le32toh(value) : be32toh(value);
}

static
int is_elf(const char * arg)
{
	char n_buf[sizeof(Elf32_Ehdr)];
	int n_ret = 0, f_fd;
	struct stat f_stat;

	f_fd = open(arg, O_RDONLY);
	if (f_fd < 0) {
		do_log_path_error(errno, "open(2)", arg);
		goto cleanup;
	}

	(void) memset(&f_stat, 0, sizeof(f_stat));
	if (fstat(f_fd, &f_stat) < 0) {
		do_log_path_error(errno, "fstat(2)", arg);
		goto cleanup;
	}

	if (!S_ISREG(f_stat.st_mode)) {
		fprintf(stderr, "argument error: not a regular file: %s\n", arg);
		goto cleanup;
	}

	if (f_stat.st_size < (off_t) sizeof(n_buf)) {
		/* file is too short for ELF */
		goto cleanup;
	}

	if (sizeof(n_buf) != read(f_fd, n_buf, sizeof(n_buf))) {
		do_log_path_error(errno, "read(2)", arg);
		goto cleanup;
	}

	(void) close(f_fd);
	f_fd = -1;

	bo_target = ELFDATANONE;

	const uint32_t elf_sig = (ELFMAG0 << 24) | (ELFMAG1 << 16) | (ELFMAG2 << 8) | (ELFMAG3);
	if (elf_sig != u32toh(*((uint32_t *) n_buf))) {
		goto cleanup;
	}

	switch (n_buf[EI_CLASS]) {
	case ELFCLASS32: /* -fallthrough */
	case ELFCLASS64: break;
	default: goto cleanup;
	}

	switch (bo_target = n_buf[EI_DATA]) {
	case ELFDATA2LSB: /* -fallthrough */
	case ELFDATA2MSB: break;
	default: goto cleanup;
	}

	switch (n_buf[EI_VERSION]) {
	case EV_CURRENT: break;
	default: goto cleanup;
	}

	switch (n_buf[EI_OSABI]) {
	case ELFOSABI_SYSV: /* -fallthrough */
	case ELFOSABI_GNU:  break;
	default: goto cleanup;
	}

	Elf32_Ehdr * ehdr = (Elf32_Ehdr *) n_buf;

	switch (u16toh(ehdr->e_type)) {
	case ET_REL:  /* -fallthrough */
	case ET_EXEC: /* -fallthrough */
	case ET_DYN:  break;
	default: goto cleanup;
	}

	switch (u16toh(ehdr->e_machine)) {
	case EM_386:     /* -fallthrough */
	case EM_PPC64:   /* -fallthrough */
	case EM_S390:    /* -fallthrough */
	case EM_X86_64:  /* -fallthrough */
	case EM_AARCH64: break;
	default: goto cleanup;
	}

	switch (u32toh(ehdr->e_version)) {
	case EV_CURRENT: break;
	default: goto cleanup;
	}

	n_ret = 1;
	fputs(arg, stdout);
	fputc(entry_separator, stdout);

cleanup:
	if (f_fd >= 0)
		(void) close(f_fd);

	return n_ret;
}

static
CC_INLINE
void do_log_path_error(int error_num, const char * where, const char * name)
{
	if (opt.Quiet) return;

	log_stderr_path_error_ex(log_pfx, name, error_num, "%s", where);
}
