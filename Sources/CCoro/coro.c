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
 */

#include "coro.h"

#include <stdlib.h>
#include <stddef.h>
#include <string.h>


/*****************************************************************************/
/* asm backend only                                                          */
/*****************************************************************************/

/*
 * coro_startup, if implemented, can lift new coro parameters from the
 * saved registers. Alternatively, we can pass parameters via globals at
 * the cost of 2 additional coro_transfer calls in coro_create.
 */
# if __arm__ || __aarch64__
#  define CORO_STARTUP 1
# else
#  define CORO_STARTUP 0
# endif

# if CORO_STARTUP
void coro_startup(); /* custom calling convention */
# else
static __thread coro_func coro_init_func;
static __thread void *coro_init_arg;
static __thread coro_context *new_coro, *create_coro;

static void
coro_init (void)
{
    volatile coro_func func = coro_init_func;
    volatile void *arg = coro_init_arg;

    coro_transfer (new_coro, create_coro);

#if __GCC_HAVE_DWARF2_CFI_ASM && __amd64
    asm (".cfi_undefined rip");
#endif

    func ((void *)arg);

    /* the new coro returned. bad. just abort() for now */
    abort ();
}
# endif

#if _WIN32 || __CYGWIN__
#define CORO_WIN_TIB 1
#endif

asm (
     "\t.text\n"
#if _WIN32 || __CYGWIN__ || __APPLE__
     "\t.globl _coro_transfer\n"
     "_coro_transfer:\n"
#else
     "\t.globl coro_transfer\n"
     "coro_transfer:\n"
#endif
     /* windows, of course, gives a shit on the amd64 ABI and uses different registers */
     /* http://blogs.msdn.com/freik/archive/2005/03/17/398200.aspx */
#if __amd64

#if _WIN32 || __CYGWIN__
#define NUM_SAVED 29
     "\tsubq $168, %rsp\t" /* one dummy qword to improve alignment */
     "\tmovaps %xmm6, (%rsp)\n"
     "\tmovaps %xmm7, 16(%rsp)\n"
     "\tmovaps %xmm8, 32(%rsp)\n"
     "\tmovaps %xmm9, 48(%rsp)\n"
     "\tmovaps %xmm10, 64(%rsp)\n"
     "\tmovaps %xmm11, 80(%rsp)\n"
     "\tmovaps %xmm12, 96(%rsp)\n"
     "\tmovaps %xmm13, 112(%rsp)\n"
     "\tmovaps %xmm14, 128(%rsp)\n"
     "\tmovaps %xmm15, 144(%rsp)\n"
     "\tpushq %rsi\n"
     "\tpushq %rdi\n"
     "\tpushq %rbp\n"
     "\tpushq %rbx\n"
     "\tpushq %r12\n"
     "\tpushq %r13\n"
     "\tpushq %r14\n"
     "\tpushq %r15\n"
#if CORO_WIN_TIB
     "\tpushq %fs:0x0\n"
     "\tpushq %fs:0x8\n"
     "\tpushq %fs:0xc\n"
#endif
     "\tmovq %rsp, (%rcx)\n"
     "\tmovq (%rdx), %rsp\n"
#if CORO_WIN_TIB
     "\tpopq %fs:0xc\n"
     "\tpopq %fs:0x8\n"
     "\tpopq %fs:0x0\n"
#endif
     "\tpopq %r15\n"
     "\tpopq %r14\n"
     "\tpopq %r13\n"
     "\tpopq %r12\n"
     "\tpopq %rbx\n"
     "\tpopq %rbp\n"
     "\tpopq %rdi\n"
     "\tpopq %rsi\n"
     "\tmovaps (%rsp), %xmm6\n"
     "\tmovaps 16(%rsp), %xmm7\n"
     "\tmovaps 32(%rsp), %xmm8\n"
     "\tmovaps 48(%rsp), %xmm9\n"
     "\tmovaps 64(%rsp), %xmm10\n"
     "\tmovaps 80(%rsp), %xmm11\n"
     "\tmovaps 96(%rsp), %xmm12\n"
     "\tmovaps 112(%rsp), %xmm13\n"
     "\tmovaps 128(%rsp), %xmm14\n"
     "\tmovaps 144(%rsp), %xmm15\n"
     "\taddq $168, %rsp\n"
#else
#define NUM_SAVED 6
     "\tpushq %rbp\n"
     "\tpushq %rbx\n"
     "\tpushq %r12\n"
     "\tpushq %r13\n"
     "\tpushq %r14\n"
     "\tpushq %r15\n"
     "\tmovq %rsp, (%rdi)\n"
     "\tmovq (%rsi), %rsp\n"
     "\tpopq %r15\n"
     "\tpopq %r14\n"
     "\tpopq %r13\n"
     "\tpopq %r12\n"
     "\tpopq %rbx\n"
     "\tpopq %rbp\n"
#endif
     "\tpopq %rcx\n"
     "\tjmpq *%rcx\n"

#elif __i386

#define NUM_SAVED 4
     "\tpushl %ebp\n"
     "\tpushl %ebx\n"
     "\tpushl %esi\n"
     "\tpushl %edi\n"
#if CORO_WIN_TIB
#undef NUM_SAVED
#define NUM_SAVED 7
     "\tpushl %fs:0\n"
     "\tpushl %fs:4\n"
     "\tpushl %fs:8\n"
#endif
     "\tmovl %esp, (%eax)\n"
     "\tmovl (%edx), %esp\n"
#if CORO_WIN_TIB
     "\tpopl %fs:8\n"
     "\tpopl %fs:4\n"
     "\tpopl %fs:0\n"
#endif
     "\tpopl %edi\n"
     "\tpopl %esi\n"
     "\tpopl %ebx\n"
     "\tpopl %ebp\n"
     "\tpopl %ecx\n"
     "\tjmpl *%ecx\n"

#elif __ARM_ARCH==7

#define NUM_SAVED 25
     "\tvpush {d8-d15}\n"
     "\tpush {r4-r11,lr}\n"
     "\tstr sp, [r0]\n"
     "\tldr sp, [r1]\n"
     "\tpop {r4-r11,lr}\n"
     "\tvpop {d8-d15}\n"
     "\tmov r15, lr\n"

#elif __aarch64__

#define NUM_SAVED 20
     "\tsub x2, sp, #8 * 20\n"
     "\tstp x19, x20, [x2, #16 * 0]\n"
     "\tstp x21, x22, [x2, #16 * 1]\n"
     "\tstp x23, x24, [x2, #16 * 2]\n"
     "\tstp x25, x26, [x2, #16 * 3]\n"
     "\tstp x27, x28, [x2, #16 * 4]\n"
     "\tstp x29, x30, [x2, #16 * 5]\n"
     "\tstp d8,  d9,  [x2, #16 * 6]\n"
     "\tstp d10, d11, [x2, #16 * 7]\n"
     "\tstp d12, d13, [x2, #16 * 8]\n"
     "\tstp d14, d15, [x2, #16 * 9]\n"
     "\tstr x2, [x0, #0]\n"
     "\tldr x3, [x1, #0]\n"
     "\tldp x19, x20, [x3, #16 * 0]\n"
     "\tldp x21, x22, [x3, #16 * 1]\n"
     "\tldp x23, x24, [x3, #16 * 2]\n"
     "\tldp x25, x26, [x3, #16 * 3]\n"
     "\tldp x27, x28, [x3, #16 * 4]\n"
     "\tldp x29, x30, [x3, #16 * 5]\n"
     "\tldp d8,  d9,  [x3, #16 * 6]\n"
     "\tldp d10, d11, [x3, #16 * 7]\n"
     "\tldp d12, d13, [x3, #16 * 8]\n"
     "\tldp d14, d15, [x3, #16 * 9]\n"
     "\tadd sp, x3, #8 * 20\n"
     "\tret\n"

#else
#error unsupported architecture
#endif
     );

#if CORO_STARTUP
asm (
     "\t.globl _coro_startup\n"
     "_coro_startup:\n"

#if __ARM_ARCH==7

     ".fnstart\n"
     ".save {lr}\n"
     ".pad #12\n"
     "\tmov lr, #0\n"
     "\tpush {lr}\n"
     "\tsub sp, #12\n"
     "\tmov r0, r5\n"
     "\tblx r4\n"
     "\tb abort\n"
     ".fnend\n"

#elif __aarch64__

     ".cfi_startproc\n"
     "\tmov x30, #0\n"
     "\tsub sp, sp, #16\n"
     "\tstr x30, [sp, #0]\n"
     ".cfi_def_cfa_offset 16\n"
     ".cfi_offset 30, -16\n"
     "\tmov x0, x20\n"
     "\tblr x19\n"
     "\tb _abort\n"
     ".cfi_endproc\n"

#else
#error unsupported architecture
#endif
     );
#endif

void
coro_create (coro_context *ctx, coro_func coro, void *arg, void *sptr, size_t ssize)
{
    if (!coro)
        return;

# if !CORO_STARTUP
    coro_context nctx;

    coro_init_func = coro;
    coro_init_arg  = arg;

    new_coro    = ctx;
    create_coro = &nctx;
# endif

    ctx->sp = (void **)(ssize + (char *)sptr);
#if __i386 || __x86_64
    *--ctx->sp = (void *)0;
    *--ctx->sp = (void *)coro_init;
#elif (__arm__ && __ARM_ARCH == 7) || __aarch64__
    /* return address stored in lr register, don't push anything */
#else
#error unsupported architecture
#endif

#if CORO_WIN_TIB
    *--ctx->sp = 0;                    /* ExceptionList */
    *--ctx->sp = (char *)sptr + ssize; /* StackBase */
    *--ctx->sp = sptr;                 /* StackLimit */
#endif

    ctx->sp -= NUM_SAVED;
    memset (ctx->sp, 0, sizeof (*ctx->sp) * NUM_SAVED);

#if __i386 || __x86_64
    /* done already */
#elif __arm__ && __ARM_ARCH == 7
    ctx->sp[0] = coro; /* r4 */
    ctx->sp[1] = arg;  /* r5 */
    ctx->sp[8] = (void *)coro_startup; /* lr */
#elif __aarch64__
    ctx->sp[0] = coro; /* x19 */
    ctx->sp[1] = arg;  /* x20 */
    ctx->sp[11] = (void *)coro_startup; /* lr */
#else
#error unsupported architecture
#endif

# if !CORO_STARTUP
    coro_transfer (create_coro, new_coro);
# endif
}
