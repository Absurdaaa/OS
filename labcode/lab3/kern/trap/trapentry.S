#include <riscv.h>

    // 保存所有寄存器到栈
    .macro SAVE_ALL

    // 将当前sp保存到sscratch，方便异常嵌套时恢复
    csrw sscratch, sp

    // 为保存36个寄存器分配空间
    addi sp, sp, -36 * REGBYTES

    # 依次保存x寄存器（x0~x31），x2为sp，x0为零寄存器
    STORE x0, 0*REGBYTES(sp)
    STORE x1, 1*REGBYTES(sp)
    STORE x3, 3*REGBYTES(sp)
    STORE x4, 4*REGBYTES(sp)
    STORE x5, 5*REGBYTES(sp)
    STORE x6, 6*REGBYTES(sp)
    STORE x7, 7*REGBYTES(sp)
    STORE x8, 8*REGBYTES(sp)
    STORE x9, 9*REGBYTES(sp)
    STORE x10, 10*REGBYTES(sp)
    STORE x11, 11*REGBYTES(sp)
    STORE x12, 12*REGBYTES(sp)
    STORE x13, 13*REGBYTES(sp)
    STORE x14, 14*REGBYTES(sp)
    STORE x15, 15*REGBYTES(sp)
    STORE x16, 16*REGBYTES(sp)
    STORE x17, 17*REGBYTES(sp)
    STORE x18, 18*REGBYTES(sp)
    STORE x19, 19*REGBYTES(sp)
    STORE x20, 20*REGBYTES(sp)
    STORE x21, 21*REGBYTES(sp)
    STORE x22, 22*REGBYTES(sp)
    STORE x23, 23*REGBYTES(sp)
    STORE x24, 24*REGBYTES(sp)
    STORE x25, 25*REGBYTES(sp)
    STORE x26, 26*REGBYTES(sp)
    STORE x27, 27*REGBYTES(sp)
    STORE x28, 28*REGBYTES(sp)
    STORE x29, 29*REGBYTES(sp)
    STORE x30, 30*REGBYTES(sp)
    STORE x31, 31*REGBYTES(sp)

    # 获取并保存异常相关寄存器
    # s0: 原sscratch（sp），用于恢复
    # s1: sstatus，保存异常前的状态
    # s2: sepc，保存异常前的PC
    # s3: sbadaddr，保存异常地址
    # s4: scause，保存异常原因
    csrrw s0, sscratch, x0      // 交换sscratch和x0（清零sscratch）
    csrr s1, sstatus            // 读sstatus
    csrr s2, sepc               // 读sepc
    csrr s3, sbadaddr           // 读sbadaddr
    csrr s4, scause             // 读scause

    // 保存上述特殊寄存器
    STORE s0, 2*REGBYTES(sp)    // 恢复sp用
    STORE s1, 32*REGBYTES(sp)
    STORE s2, 33*REGBYTES(sp)
    STORE s3, 34*REGBYTES(sp)
    STORE s4, 35*REGBYTES(sp)
    .endm

    // 从栈恢复所有寄存器
    .macro RESTORE_ALL

    // 恢复sstatus和sepc（异常返回需要）
    LOAD s1, 32*REGBYTES(sp)
    LOAD s2, 33*REGBYTES(sp)

    csrw sstatus, s1
    csrw sepc, s2

    # 恢复x寄存器（x1~x31），x2为sp，最后恢复
    LOAD x1, 1*REGBYTES(sp)
    LOAD x3, 3*REGBYTES(sp)
    LOAD x4, 4*REGBYTES(sp)
    LOAD x5, 5*REGBYTES(sp)
    LOAD x6, 6*REGBYTES(sp)
    LOAD x7, 7*REGBYTES(sp)
    LOAD x8, 8*REGBYTES(sp)
    LOAD x9, 9*REGBYTES(sp)
    LOAD x10, 10*REGBYTES(sp)
    LOAD x11, 11*REGBYTES(sp)
    LOAD x12, 12*REGBYTES(sp)
    LOAD x13, 13*REGBYTES(sp)
    LOAD x14, 14*REGBYTES(sp)
    LOAD x15, 15*REGBYTES(sp)
    LOAD x16, 16*REGBYTES(sp)
    LOAD x17, 17*REGBYTES(sp)
    LOAD x18, 18*REGBYTES(sp)
    LOAD x19, 19*REGBYTES(sp)
    LOAD x20, 20*REGBYTES(sp)
    LOAD x21, 21*REGBYTES(sp)
    LOAD x22, 22*REGBYTES(sp)
    LOAD x23, 23*REGBYTES(sp)
    LOAD x24, 24*REGBYTES(sp)
    LOAD x25, 25*REGBYTES(sp)
    LOAD x26, 26*REGBYTES(sp)
    LOAD x27, 27*REGBYTES(sp)
    LOAD x28, 28*REGBYTES(sp)
    LOAD x29, 29*REGBYTES(sp)
    LOAD x30, 30*REGBYTES(sp)
    LOAD x31, 31*REGBYTES(sp)
    # 最后恢复sp
    LOAD x2, 2*REGBYTES(sp)
    .endm

    // 异常入口，全局符号
    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL                   // 保存现场

    move  a0, sp               // 将sp传给trap函数（参数a0）
    jal trap                   // 跳转到trap处理函数
    # trap返回后，sp应与进入trap前一致

    // 异常返回，全局符号
    .globl __trapret
__trapret:
    RESTORE_ALL                // 恢复现场
    # 从supervisor模式返回
    sret                       // 异常返回指令
