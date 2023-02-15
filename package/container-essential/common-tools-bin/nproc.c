/*
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2020 Andrei Pangin
 * (c) 2022-2023 Konstantin Demin
 */

#include "nproc.h"

int main(int argc, char * argv[])
{
	printf("%d\n", find_container_cpus());
	return 0;
}
