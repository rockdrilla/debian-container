/* cc-inline: try to deal with "inline"
 *
 * SPDX-License-Identifier: Apache-2.0
 * (c) 2022-2023, Konstantin Demin
 */

#ifndef HEADER_INCLUDED_CC_INLINE
#define HEADER_INCLUDED_CC_INLINE 1

#define CC_NO_INLINE  __attribute__(( used,noinline ))
#ifndef CC_NO_FORCED_INLINE
  #define CC_INLINE        inline
  #define CC_FORCE_INLINE  __attribute__(( always_inline ))
#else /* CC_NO_FORCED_INLINE */
  #define CC_INLINE
  #define CC_FORCE_INLINE  inline
#endif /* CC_NO_FORCED_INLINE */

#endif /* HEADER_INCLUDED_CC_INLINE */
