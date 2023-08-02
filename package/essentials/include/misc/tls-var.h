/* tls: declare variables as thread-local
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_TLS_VAR
#define HEADER_INCLUDED_TLS_VAR 1

#ifndef TLS_SPEC
#define TLS_SPEC __thread
#endif

#define TLS_ATTR __attribute__(( tls_model ("local-dynamic") ))

#define TLS_OPAQUE(decl) static TLS_SPEC decl TLS_ATTR

#endif /* HEADER_INCLUDED_TLS_VAR */
