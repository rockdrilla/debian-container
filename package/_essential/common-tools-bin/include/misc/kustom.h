/* kustom: shifty-nifty macros for custom names/types/funcs/etc
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_KUSTOM
#define HEADER_INCLUDED_KUSTOM 1

#define KUSTOM_NAME(prefix, type, kind)  prefix ## _ ## type ## _ ## kind

#define KUSTOM_PROC(type, proc)       type ## __ ## proc
#define KUSTOM_CALL(type, proc, ...)  (KUSTOM_PROC(type, proc) (__VA_ARGS__))

/* for "internals" */

#define KUSTOM_PROC_INT(type, proc)       type ## __int__ ## proc
#define KUSTOM_CALL_INT(type, proc, ...)  (KUSTOM_PROC_INT(type, proc) (__VA_ARGS__))

#endif /* HEADER_INCLUDED_KUSTOM */
