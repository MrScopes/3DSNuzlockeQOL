    .cpu mpcore
    .section ".crt0"
    .global _start
    .align 4
    .arm

_start:
    b startup

startup:
    mov     r4, lr
    ldr     r0, =__bss_start__
    ldr     r1, =__bss_end__
    sub     r1, r1, r0
    bl      ClearMem
    ldr     r0, [sp]
    bl      __entrypoint
    mov     pc, r4

ClearMem:
    mov     r2, #3
    add     r1, r1, r2
    bics    r1, r1, r2
    bxeq    lr
    mov     r2, #0

ClearLoop:
    stmia   r0!, {r2}
    subs    r1, r1, #4
    bne     ClearLoop
    bx      lr
