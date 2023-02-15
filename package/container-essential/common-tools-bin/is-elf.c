/* is-elf: trivial file type check for ELF files
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 * 
 * Rough alternative (but slow):
 *   file -L -N -F '|' -p -S /path/to/file \
 *   | mawk -F '|' 'BEGIN { ORS="\0"; } $2 ~ "^ ?ELF " { print $1; }'
 */
#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <sys/stat.h>

#include <elf.h>
#include <endian.h>

static char entry_separator = '\n';

static void usage(int retcode)
{
	(void) fputs(
	"Usage: is-elf [-z] <file> [..<file>]\n"
	"  <file> - file meant to be ELF\n"
	"  -z  - separate entries with \\0 instead of \\n\n"
	, stderr);

	exit(retcode);
}

static int is_elf(const char * arg);

int main(int argc, char * argv[])
{
	if (argc < 2) {
		usage(0);
		return 0;
	}

	// skip 1st argument
	argc--; argv++;

	if (strcmp(argv[0], "-z") == 0) {
		entry_separator = 0;
		// skip argument
		argc--; argv++;
	}

	int any_elf = 0;
	for (int i = 0; i < argc; i++) {
		any_elf |= is_elf(argv[i]);
	}

//	return (any_elf != 0) ? 0 : EINVAL;
	return 0;
}

static int bo_target = ELFDATANONE;
static uint16_t u16toh(uint16_t value)
{
	return (bo_target == ELFDATA2LSB) ? le16toh(value) : be16toh(value);
}
static uint32_t u32toh(uint32_t value)
{
	return (bo_target == ELFDATA2LSB) ? le32toh(value) : be32toh(value);
}

static void dump_path_error(int error_num, const char * where, const char * name);

static int is_elf(const char * arg)
{
	static char n_buf[sizeof(Elf32_Ehdr)];
	int n_ret = 0;

	int f_fd = open(arg, O_RDONLY);
	if (f_fd < 0) {
		dump_path_error(errno, "is_elf:open(2)", arg);
		goto cleanup;
	}

	struct stat f_stat;
	memset(&f_stat, 0, sizeof(f_stat));
	if (fstat(f_fd, &f_stat) < 0) {
		dump_path_error(errno, "is_elf:fstat(2)", arg);
		goto cleanup;
	}

	if (!S_ISREG(f_stat.st_mode)) {
		fprintf(stderr, "argument error: not a regular file: %s\n", arg);
		goto cleanup;
	}

	if (f_stat.st_size < (off_t) sizeof(n_buf)) {
		// file is too short for ELF
		goto cleanup;
	}

	if (sizeof(n_buf) != read(f_fd, n_buf, sizeof(n_buf))) {
		dump_path_error(errno, "is_elf:read(2)", arg);
		goto cleanup;
	}

	close(f_fd); f_fd = -1;

	bo_target = ELFDATANONE;

	const uint32_t elf_sig = (ELFMAG0 << 24) | (ELFMAG1 << 16) | (ELFMAG2 << 8) | (ELFMAG3);
	if (elf_sig != u32toh(*((uint32_t *) n_buf))) {
		goto cleanup;
	}

	switch (n_buf[EI_CLASS]) {
	case ELFCLASS32:
		// -fallthrough
	case ELFCLASS64:
		break;
	default:
		goto cleanup;
	}

	switch (bo_target = n_buf[EI_DATA]) {
	case ELFDATA2LSB:
		// -fallthrough
	case ELFDATA2MSB:
		break;
	default:
		goto cleanup;
	}

	switch (n_buf[EI_VERSION]) {
	case EV_CURRENT:
		break;
	default:
		goto cleanup;
	}

	switch (n_buf[EI_OSABI]) {
	case ELFOSABI_SYSV:
		// -fallthrough
	case ELFOSABI_GNU:
		break;
	default:
		goto cleanup;
	}

	Elf32_Ehdr * ehdr = (Elf32_Ehdr *) n_buf;

	switch (u16toh(ehdr->e_type)) {
	case ET_REL:
		// -fallthrough
	case ET_EXEC:
		// -fallthrough
	case ET_DYN:
		break;
	default:
		goto cleanup;
	}

	switch (u16toh(ehdr->e_machine)) {
	case EM_386:
		// -fallthrough
	case EM_PPC64:
		// -fallthrough
	case EM_S390:
		// -fallthrough
	case EM_X86_64:
		// -fallthrough
	case EM_AARCH64:
		break;
	default:
		goto cleanup;
	}

	switch (u32toh(ehdr->e_version)) {
	case EV_CURRENT:
		break;
	default:
		goto cleanup;
	}

	n_ret = 1;
	fputs(arg, stdout);
	fputc(entry_separator, stdout);

cleanup:
	if (f_fd >= 0) {
		close(f_fd);
	}

	return n_ret;
}

static void dump_path_error(int error_num, const char * where, const char * name)
{
	static char e_buf[8192];
	char * e_str = NULL;

	memset(&e_buf, 0, sizeof(e_buf));
	e_str = strerror_r(error_num, e_buf, sizeof(e_buf) - 1);
	fprintf(stderr, "%s path '%s' error %d: %s\n", where, name, error_num, e_str);
}
