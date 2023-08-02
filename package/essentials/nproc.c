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

#include "include/incontainer/nproc.h"

int main(int argc, char * argv[])
{
	printf("%d\n", get_container_cpus());
	return 0;
}
