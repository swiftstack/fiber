/*
 * Copyright (c) 2001-2017 Marc Alexander Lehmann <schmorp@schmorp.de>
 *
 * Redistribution and use in source and binary forms, with or without modifica-
 * tion, are permitted provided that the following conditions are met:
 *
 *   1.  Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *
 *   2.  Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MER-
 * CHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPE-
 * CIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTH-
 * ERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Alternatively, the contents of this file may be used under the terms of
 * the GNU General Public License ("GPL") version 2 or any later version,
 * in which case the provisions of the GPL are applicable instead of
 * the above. If you wish to allow the use of your version of this file
 * only under the terms of the GPL and not to allow others to use your
 * version of this file under the BSD license, indicate your decision
 * by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL. If you do not delete the
 * provisions above, a recipient may use your version of this file under
 * either the BSD or the GPL.
 *
 * This library is modelled strictly after Ralf S. Engelschalls article at
 * http://www.gnu.org/software/pth/rse-pmt.ps. So most of the credit must
 * go to Ralf S. Engelschall <rse@engelschall.com>.
 *
 * This coroutine library is very much stripped down. You should either
 * build your own process abstraction using it or - better - just use GNU
 * Portable Threads, http://www.gnu.org/software/pth/.
 *
 */

/*
 * 2006-10-26 Include stddef.h on OS X to work around one of its bugs.
 *            Reported by Michael_G_Schwern.
 * 2006-11-26 Use _setjmp instead of setjmp on GNU/Linux.
 * 2007-04-27 Set unwind frame info if gcc 3+ and ELF is detected.
 *            Use _setjmp instead of setjmp on _XOPEN_SOURCE >= 600.
 * 2007-05-02 Add assembly versions for x86 and amd64 (to avoid reliance
 *            on SIGUSR2 and sigaltstack in Crossfire).
 * 2008-01-21 Disable CFI usage on anything but GNU/Linux.
 * 2008-03-02 Switched to 2-clause BSD license with GPL exception.
 * 2008-04-04 New (but highly unrecommended) pthreads backend.
 * 2008-04-24 Reinstate CORO_LOSER (had wrong stack adjustments).
 * 2008-10-30 Support assembly method on x86 with and without frame pointer.
 * 2008-11-03 Use a global asm statement for CORO_ASM, idea by pippijn.
 * 2008-11-05 Hopefully fix misaligned stacks with CORO_ASM/SETJMP.
 * 2008-11-07 rbp wasn't saved in CORO_ASM on x86_64.
 *            introduce coro_destroy, which is a nop except for pthreads.
 *            speed up CORO_PTHREAD. Do no longer leak threads either.
 *            coro_create now allows one to create source coro_contexts.
 *            do not rely on makecontext passing a void * correctly.
 *            try harder to get _setjmp/_longjmp.
 *            major code cleanup/restructuring.
 * 2008-11-10 the .cfi hacks are no longer needed.
 * 2008-11-16 work around a freebsd pthread bug.
 * 2008-11-19 define coro_*jmp symbols for easier porting.
 * 2009-06-23 tentative win32-backend support for mingw32 (Yasuhiro Matsumoto).
 * 2010-12-03 tentative support for uclibc (which lacks all sorts of things).
 * 2011-05-30 set initial callee-saved-registers to zero with CORO_ASM.
 *            use .cfi_undefined rip on linux-amd64 for better backtraces.
 * 2011-06-08 maybe properly implement weird windows amd64 calling conventions.
 * 2011-07-03 rely on __GCC_HAVE_DWARF2_CFI_ASM for cfi detection.
 * 2011-08-08 cygwin trashes stacks, use pthreads with double stack on cygwin.
 * 2012-12-04 reduce misprediction penalty for x86/amd64 assembly switcher.
 * 2012-12-05 experimental fiber backend (allocates stack twice).
 * 2012-12-07 API version 3 - add coro_stack_alloc/coro_stack_free.
 * 2012-12-21 valgrind stack registering was broken.
 * 2016-12-07 Remove all the code except CORO_ASM context switching.
 */

#ifndef CORO_H
#define CORO_H

#if __cplusplus
extern "C" {
#endif

/*
 * This library consists of only three files
 * coro.h, coro.c and LICENSE (and optionally README)
 *
 * It implements what is known as coroutines in:
 *
 *    Hand coded assembly, known to work only on a few architectures/ABI:
 *    GCC + x86/IA32 and amd64/x86_64 + GNU/Linux and a few BSDs. Fastest choice,
 *    if it works.
 *
 */

#include <stddef.h>

/*
 * This is the type for the initialization function of a new coroutine.
 */
typedef void (*coro_func)(void *);

/*
 * A coroutine state is saved in the following structure. Treat it as an
 * opaque type. errno and sigmask might be saved, but don't rely on it,
 * implement your own switching primitive if you need that.
 */
typedef struct coro_context coro_context;

/*
 * This function creates a new coroutine. Apart from a pointer to an
 * uninitialised coro_context, it expects a pointer to the entry function
 * and the single pointer value that is given to it as argument.
 *
 * Allocating/deallocating the stack is your own responsibility.
 *
 * As a special case, if coro, arg, sptr and ssze are all zero,
 * then an "empty" coro_context will be created that is suitable
 * as an initial source for coro_transfer.
 *
 * This function is not reentrant, but putting a mutex around it
 * will work.
 */
void coro_create (coro_context *ctx, /* an uninitialised coro_context */
                  coro_func coro,    /* the coroutine code to be executed */
                  void *arg,         /* a single pointer passed to the coro */
                  void *sptr,        /* start of stack area */
                  size_t ssze);      /* size of stack area in bytes */


/*
 * That was it. No other user-serviceable parts below here.
 */


struct coro_context
{
  void **sp; /* must be at offset 0 */
};

#if !__arm__ && !__aarch64__
void __attribute__ ((__noinline__, __regparm__(2)))
coro_transfer (coro_context *prev, coro_context *next);
#else
void __attribute__ ((__noinline__))
coro_transfer (coro_context *prev, coro_context *next);
#endif

# define coro_destroy(ctx) (void *)(ctx)


#if __cplusplus
}
#endif

#endif
