#include <riscv.h>

    /*
     * 宏: SAVE_ALL
     * 功能: 保存异常发生时的完整CPU上下文（所有寄存器）到内核栈
     * 
     * 调用时机: 当CPU发生异常/中断时，硬件自动跳转到 stvec 指向的 __alltraps
     *          在 __alltraps 中首先调用此宏保存现场，然后才能安全调用C函数处理异常
     * 
     * 保存内容:
     *   - x0~x31: 32个通用寄存器（包括sp、ra等）
     *   - sstatus: 异常前的状态寄存器（包含中断使能位等）
     *   - sepc: 异常发生时的PC（异常返回地址）
     *   - sbadaddr: 引发异常的地址（如缺页地址）
     *   - scause: 异常原因编码（如时钟中断、缺页等）
     * 
     * 栈布局（每个槽位 REGBYTES 字节，64位下为8字节）:
     *   sp+0:  x0      sp+16: x16     sp+32: sstatus
     *   sp+8:  x1(ra)  ...            sp+33: sepc
     *   sp+16: x2(sp)  sp+31: x31     sp+34: sbadaddr
     *   ...                           sp+35: scause
     */
    .macro SAVE_ALL

    // 步骤1: 先将当前sp暂存到sscratch，以便保存原始sp值
    // （因为接下来要修改sp来分配栈空间，但我们需要记住进入异常时的sp）
    csrw sscratch, sp

    // 步骤2: 在当前栈上为36个寄存器分配空间
    // （32个通用寄存器 + 4个异常相关CSR寄存器）
    addi sp, sp, -36 * REGBYTES

    // 步骤3: 依次保存所有通用寄存器（x0~x31）
    // 注意: x0 恒为0，保存它只是为了占位保持结构对齐
    //      x2(sp) 暂时保存修改后的sp，后续会用原始sp覆盖
    STORE x0, 0*REGBYTES(sp)
    STORE x1, 1*REGBYTES(sp)     // ra: 返回地址
    STORE x3, 3*REGBYTES(sp)     // gp: 全局指针
    STORE x4, 4*REGBYTES(sp)     // tp: 线程指针
    STORE x5, 5*REGBYTES(sp)     // t0-t2: 临时寄存器
    STORE x6, 6*REGBYTES(sp)
    STORE x7, 7*REGBYTES(sp)
    STORE x8, 8*REGBYTES(sp)     // s0/fp: 保存寄存器/帧指针
    STORE x9, 9*REGBYTES(sp)     // s1: 保存寄存器
    STORE x10, 10*REGBYTES(sp)   // a0-a7: 函数参数/返回值
    STORE x11, 11*REGBYTES(sp)
    STORE x12, 12*REGBYTES(sp)
    STORE x13, 13*REGBYTES(sp)
    STORE x14, 14*REGBYTES(sp)
    STORE x15, 15*REGBYTES(sp)
    STORE x16, 16*REGBYTES(sp)
    STORE x17, 17*REGBYTES(sp)
    STORE x18, 18*REGBYTES(sp)   // s2-s11: 保存寄存器
    STORE x19, 19*REGBYTES(sp)
    STORE x20, 20*REGBYTES(sp)
    STORE x21, 21*REGBYTES(sp)
    STORE x22, 22*REGBYTES(sp)
    STORE x23, 23*REGBYTES(sp)
    STORE x24, 24*REGBYTES(sp)
    STORE x25, 25*REGBYTES(sp)
    STORE x26, 26*REGBYTES(sp)
    STORE x27, 27*REGBYTES(sp)
    STORE x28, 28*REGBYTES(sp)   // t3-t6: 临时寄存器
    STORE x29, 29*REGBYTES(sp)
    STORE x30, 30*REGBYTES(sp)
    STORE x31, 31*REGBYTES(sp)

    // 步骤4: 读取并保存异常相关的CSR寄存器
    // 这些寄存器包含了异常发生时的关键信息，必须保存以便C处理函数分析
    csrrw s0, sscratch, x0      // 从sscratch读取原始sp（步骤1保存的），同时清零sscratch
    csrr s1, sstatus            // 读取异常前的状态（中断使能、特权级等）
    csrr s2, sepc               // 读取异常返回地址（异常发生时的PC）
    csrr s3, sbadaddr           // 读取触发异常的地址（如缺页异常的虚拟地址）
    csrr s4, scause             // 读取异常原因码（区分时钟中断、系统调用、缺页等）

    csrrw s0, sscratch, x0      // 从sscratch读取原始sp（步骤1保存的），同时清零sscratch
    csrr s1, sstatus            // 读取异常前的状态（中断使能、特权级等）
    csrr s2, sepc               // 读取异常返回地址（异常发生时的PC）
    csrr s3, sbadaddr           // 读取触发异常的地址（如缺页异常的虚拟地址）
    csrr s4, scause             // 读取异常原因码（区分时钟中断、系统调用、缺页等）

    // 步骤5: 将上述CSR寄存器值保存到栈的对应位置
    STORE s0, 2*REGBYTES(sp)    // 保存原始sp（用于恢复现场）
    STORE s1, 32*REGBYTES(sp)   // 保存sstatus
    STORE s2, 33*REGBYTES(sp)   // 保存sepc
    STORE s3, 34*REGBYTES(sp)   // 保存sbadaddr
    STORE s4, 35*REGBYTES(sp)   // 保存scause
    
    // 现在栈上已保存完整的trapframe结构，可以安全调用C函数了
    .endm

    /*
     * 宏: RESTORE_ALL
     * 功能: 从内核栈恢复异常发生时的CPU上下文（所有寄存器）
     * 
     * 调用时机: 在C函数trap()处理完异常后，返回到__trapret，调用此宏恢复现场
     *          然后执行sret指令返回到异常发生点继续执行
     * 
     * 恢复顺序: 
     *   1. 先恢复sstatus和sepc（这两个寄存器决定异常返回后的状态和位置）
     *   2. 再恢复所有通用寄存器x1~x31
     *   3. 最后恢复sp（因为恢复过程中一直在用sp访问栈）
     * 
     * 注意: 必须与SAVE_ALL的栈布局严格对应
     */
    .macro RESTORE_ALL

    // 步骤1: 先恢复异常返回需要的关键CSR寄存器
    LOAD s1, 32*REGBYTES(sp)    // 从栈读取保存的sstatus
    LOAD s2, 33*REGBYTES(sp)    // 从栈读取保存的sepc

    csrw sstatus, s1            // 恢复sstatus（包括中断使能位等状态）
    csrw sepc, s2               // 恢复sepc（sret将跳转到这个地址）

    // 步骤2: 恢复所有通用寄存器（x1~x31），注意跳过x2(sp)
    // x2(sp)最后恢复，因为现在还需要用sp来访问栈上的数据
    LOAD x1, 1*REGBYTES(sp)     // ra: 返回地址
    LOAD x3, 3*REGBYTES(sp)     // gp: 全局指针
    LOAD x4, 4*REGBYTES(sp)     // tp: 线程指针
    LOAD x5, 5*REGBYTES(sp)     // t0-t2: 临时寄存器
    LOAD x6, 6*REGBYTES(sp)
    LOAD x7, 7*REGBYTES(sp)
    LOAD x8, 8*REGBYTES(sp)     // s0/fp: 保存寄存器
    LOAD x9, 9*REGBYTES(sp)     // s1: 保存寄存器
    LOAD x10, 10*REGBYTES(sp)   // a0-a7: 函数参数/返回值
    LOAD x11, 11*REGBYTES(sp)
    LOAD x12, 12*REGBYTES(sp)
    LOAD x13, 13*REGBYTES(sp)
    LOAD x14, 14*REGBYTES(sp)
    LOAD x15, 15*REGBYTES(sp)
    LOAD x16, 16*REGBYTES(sp)
    LOAD x17, 17*REGBYTES(sp)
    LOAD x18, 18*REGBYTES(sp)   // s2-s11: 保存寄存器
    LOAD x19, 19*REGBYTES(sp)
    LOAD x20, 20*REGBYTES(sp)
    LOAD x21, 21*REGBYTES(sp)
    LOAD x22, 22*REGBYTES(sp)
    LOAD x23, 23*REGBYTES(sp)
    LOAD x24, 24*REGBYTES(sp)
    LOAD x25, 25*REGBYTES(sp)
    LOAD x26, 26*REGBYTES(sp)
    LOAD x27, 27*REGBYTES(sp)
    LOAD x28, 28*REGBYTES(sp)   // t3-t6: 临时寄存器
    LOAD x29, 29*REGBYTES(sp)
    LOAD x30, 30*REGBYTES(sp)
    LOAD x31, 31*REGBYTES(sp)
    
    // 步骤3: 最后恢复sp（栈指针）
    // 这里恢复的是SAVE_ALL步骤1中保存到sscratch的原始sp值
    LOAD x2, 2*REGBYTES(sp)
    
    // 现在所有寄存器都已恢复到异常发生前的状态
    .endm

    /*
     * __alltraps: 异常/中断统一入口
     * 
     * 工作流程:
     *   1. CPU发生异常时，硬件自动:
     *      - 将异常原因写入scause
     *      - 将异常地址写入sepc
     *      - 将触发异常的地址写入sbadaddr（如果适用）
     *      - 跳转到stvec指向的地址（在kern/trap/trap.c的idt_init()中设置为__alltraps）
     *   
     *   2. 本函数执行:
     *      - 调用SAVE_ALL宏保存完整的CPU上下文到栈
     *      - 将栈指针sp（指向trapframe结构）作为参数传给trap()函数
     *      - 调用C函数trap()进行具体的异常处理（时钟中断、缺页、系统调用等）
     *      - trap()返回后，继续执行到__trapret恢复现场
     * 
     * 与项目其他部分的关联:
     *   - kern/trap/trap.c: idt_init()设置stvec指向此函数
     *   - kern/trap/trap.c: trap()函数接收trapframe指针，根据scause分发处理
     *   - kern/init/init.c: kern_init()中调用idt_init()和clock_init()启用中断
     */
    .globl __alltraps
    .align(2)   // 中断入口点 __alltraps 必须四字节对齐（RISC-V要求）
__alltraps:
    SAVE_ALL                   // 保存完整的CPU上下文（所有寄存器）

    move  a0, sp               // 将sp（指向trapframe）传给trap函数作为第一个参数
    jal trap                   // 跳转到C函数trap()处理异常
                              // trap()函数会根据trapframe->cause分发到具体处理函数
                              // 返回后继续执行下面的__trapret

    /*
     * __trapret: 异常返回入口
     * 
     * 功能: 恢复异常前的CPU上下文并返回到异常发生点
     * 
     * 调用路径:
     *   - 正常路径: __alltraps -> trap() -> 返回 -> __trapret
     *   - 也可被其他代码显式调用（如进程切换后恢复用户态）
     * 
     * 执行流程:
     *   1. 调用RESTORE_ALL恢复所有寄存器（包括sepc和sstatus）
     *   2. 执行sret指令（supervisor return）:
     *      - 硬件自动将PC设置为sepc的值（异常发生点或修改后的地址）
     *      - 恢复特权级和中断状态（根据sstatus）
     *      - 继续执行被中断的代码
     */
    .globl __trapret
__trapret:
    RESTORE_ALL                // 恢复CPU上下文（所有寄存器）
    sret                       // 异常返回指令：PC <- sepc，特权级恢复
