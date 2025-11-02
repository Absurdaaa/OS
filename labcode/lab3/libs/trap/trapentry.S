#include <riscv.h>

/*
 * trapentry.S - RISC-V 中断/异常处理入口
 * 
 * 功能：
 * 1. 保存异常现场（上下文切换）
 * 2. 调用 C 语言处理函数 trap()
 * 3. 恢复异常现场并返回
 * 
 * RISC-V 中断与异常的区别：
 * ┌────────────┬─────────────────┬─────────────────┐
 * │   特性     │   中断(Interrupt)│   异常(Exception)│
 * ├────────────┼─────────────────┼─────────────────┤
 * │ scause最高位│       1         │       0         │
 * │ 触发原因    │   外部事件      │   当前指令      │
 * │ 是否同步    │   异步          │   同步          │
 * │ 典型例子    │ 时钟中断、I/O   │ 非法指令、缺页  │
 * └────────────┴─────────────────┴─────────────────┘
 */

    /*
     * SAVE_ALL - 保存所有寄存器到栈（上下文切换的核心）+
     * 作用：构建 trapframe 结构，保存异常发生时的完整 CPU 状态
     * 
     * trapframe 结构（36 个寄存器）：
     *   [0-31]  : 32个通用寄存器 (x0-x31)
     *   [32]    : sstatus (CPU状态寄存器)
     *   [33]    : sepc (异常PC，异常发生时的指令地址)
     *   [34]    : sbadaddr (异常地址，如访问异常的内存地址)
     *   [35]    : scause (异常原因码，区分中断/异常类型)
     * 
     * 关键寄存器说明：
     *   sscratch: 临时保存 sp，用于区分内核态/用户态
     *   sepc:     异常发生时的 PC，sret 指令会从这里恢复
     *   scause:   最高位=1表示中断，=0表示异常；低位表示具体类型
     *   sstatus:  保存 CPU 状态，包括中断使能位(SIE)和特权级(SPP)
     */
    .macro SAVE_ALL

    /*
     * 步骤1: 保存当前栈指针到 sscratch
     * 
     * 为什么要这样做？
     * - sscratch 是暂存寄存器，用于在修改 sp 前保存其原始值
     * - 后续需要将原始 sp 保存到 trapframe[2] 位置
     * - 在异常嵌套时，可以通过 sscratch 恢复外层的栈
     */
    csrw sscratch, sp

    /*
     * 步骤2: 在栈上为 trapframe 分配空间
     * 
     * 空间大小: 36 * REGBYTES
     *   - REGBYTES = 8 (64位系统) 或 4 (32位系统)
     *   - 总共 288 字节 (64位) 或 144 字节 (32位)
     * 
     * 内存布局（从低地址到高地址）：
     *   sp+0    : x0  (zero)
     *   sp+8    : x1  (ra - 返回地址)
     *   sp+16   : x2  (sp - 栈指针，后续保存)
     *   sp+24   : x3  (gp - 全局指针)
     *   ...
     *   sp+248  : x31 (t6)
     *   sp+256  : sstatus
     *   sp+264  : sepc
     *   sp+272  : sbadaddr
     *   sp+280  : scause
     */
    addi sp, sp, -36 * REGBYTES

    /*
     * 步骤3: 保存所有通用寄存器 (x0-x31)
     * 
     * RISC-V 寄存器分类：
     *   x0  (zero) : 硬连线为0，读取永远是0，写入无效
     *   x1  (ra)   : 返回地址寄存器，函数调用时保存返回地址
     *   x2  (sp)   : 栈指针，指向当前栈顶（这里暂不保存，后续单独处理）
     *   x3  (gp)   : 全局指针，指向全局变量区
     *   x4  (tp)   : 线程指针，指向线程本地存储(TLS)
     *   x5-x7, x28-x31 (t0-t6) : 临时寄存器，调用者保存
     *   x8-x9, x18-x27 (s0-s11): 保存寄存器，被调用者保存
     *   x10-x17 (a0-a7): 函数参数/返回值寄存器
     * 
     * 注意：x2(sp) 此时已经指向新分配的 trapframe，所以先不保存
     */
    # 依次保存x寄存器（x0~x31），x2为sp，x0为零寄存器
    STORE x0, 0*REGBYTES(sp)     # 保存 x0 (zero) - 虽然总是0，但为了结构完整性
    STORE x1, 1*REGBYTES(sp)     # 保存 x1 (ra) - 返回地址
    STORE x3, 3*REGBYTES(sp)     # 保存 x3 (gp) - 全局指针
    STORE x4, 4*REGBYTES(sp)     # 保存 x4 (tp) - 线程指针
    STORE x5, 5*REGBYTES(sp)     # 保存 x5 (t0) - 临时寄存器
    STORE x6, 6*REGBYTES(sp)     # 保存 x6 (t1)
    STORE x7, 7*REGBYTES(sp)     # 保存 x7 (t2)
    STORE x8, 8*REGBYTES(sp)     # 保存 x8 (s0/fp) - 保存寄存器/帧指针
    STORE x9, 9*REGBYTES(sp)     # 保存 x9 (s1) - 保存寄存器
    STORE x10, 10*REGBYTES(sp)   # 保存 x10 (a0) - 函数参数/返回值
    STORE x11, 11*REGBYTES(sp)   # 保存 x11 (a1) - 函数参数/返回值
    STORE x12, 12*REGBYTES(sp)   # 保存 x12 (a2) - 函数参数
    STORE x13, 13*REGBYTES(sp)   # 保存 x13 (a3)
    STORE x14, 14*REGBYTES(sp)   # 保存 x14 (a4)
    STORE x15, 15*REGBYTES(sp)   # 保存 x15 (a5)
    STORE x16, 16*REGBYTES(sp)   # 保存 x16 (a6)
    STORE x17, 17*REGBYTES(sp)   # 保存 x17 (a7)
    STORE x18, 18*REGBYTES(sp)   # 保存 x18 (s2) - 保存寄存器
    STORE x19, 19*REGBYTES(sp)   # 保存 x19 (s3)
    STORE x20, 20*REGBYTES(sp)   # 保存 x20 (s4)
    STORE x21, 21*REGBYTES(sp)   # 保存 x21 (s5)
    STORE x22, 22*REGBYTES(sp)   # 保存 x22 (s6)
    STORE x23, 23*REGBYTES(sp)   # 保存 x23 (s7)
    STORE x24, 24*REGBYTES(sp)   # 保存 x24 (s8)
    STORE x25, 25*REGBYTES(sp)   # 保存 x25 (s9)
    STORE x26, 26*REGBYTES(sp)   # 保存 x26 (s10)
    STORE x27, 27*REGBYTES(sp)   # 保存 x27 (s11)
    STORE x28, 28*REGBYTES(sp)   # 保存 x28 (t3) - 临时寄存器
    STORE x29, 29*REGBYTES(sp)   # 保存 x29 (t4)
    STORE x30, 30*REGBYTES(sp)   # 保存 x30 (t5)
    STORE x31, 31*REGBYTES(sp)   # 保存 x31 (t6)

    /*
     * 步骤4: 读取并保存 CSR（控制状态寄存器）
     * 
     * 关键 CSR 寄存器：
     *   sscratch : S-Mode 暂存寄存器，前面已保存了原始 sp
     *   sstatus  : S-Mode 状态寄存器
     *             - SPP 位：保存异常前的特权级 (0=U-Mode, 1=S-Mode)
     *              - SIE 位：S-Mode 中断使能位
     *               - SPIE位：保存异常前的 SIE 值
     *   sepc     : S-Mode 异常程序计数器，保存异常发生时的 PC
     *              - 中断：指向被中断的指令
     *              - 异常：指向触发异常的指令
     *   sbadaddr : S-Mode 异常地址，保存触发异常的内存地址
     *              - 对于访问异常（缺页、非法访问）有效
     *              - 其他异常类型此值无意义
     *   scause   : S-Mode 异常原因寄存器
     *              - 最高位：1=中断，0=异常
     *              - 低位：具体原因码
     *                中断: 1=软件中断, 5=时钟中断, 9=外部中断
     *                异常: 2=非法指令, 3=断点, 5=加载访问异常, 8=系统调用
     * 
     * 使用临时寄存器 s0-s4 来暂存：
     */
    # 获取并保存异常相关寄存器
    # s0: 原sscratch（sp），用于恢复
    # s1: sstatus，保存异常前的状态
    # s2: sepc，保存异常前的PC
    # s3: sbadaddr，保存异常地址
    # s4: scause，保存异常原因
    csrrw s0, sscratch, x0      // 交换sscratch和x0（清零sscratch），s0 = 原始sp
    csrr s1, sstatus            // 读取 sstatus → s1
    csrr s2, sepc               // 读取 sepc (异常PC) → s2
    csrr s3, sbadaddr           // 读取 sbadaddr (异常地址) → s3
    csrr s4, scause             // 读取 scause (异常原因) → s4

    /*
     * 步骤5: 将 CSR 寄存器保存到 trapframe
     * 
     * 保存位置：
     *   trapframe[2]  = 原始 sp (从 s0 保存)
     *   trapframe[32] = sstatus (从 s1 保存)
     *   trapframe[33] = sepc (从 s2 保存)
     *   trapframe[34] = sbadaddr (从 s3 保存)
     *   trapframe[35] = scause (从 s4 保存)
     * 
     * 至此，trapframe 完整保存了异常发生时的所有 CPU 状态！
     */
    // 保存上述特殊寄存器
    STORE s0, 2*REGBYTES(sp)    // 保存原始 sp（用于恢复）
    STORE s1, 32*REGBYTES(sp)   // 保存 sstatus
    STORE s2, 33*REGBYTES(sp)   // 保存 sepc
    STORE s3, 34*REGBYTES(sp)   // 保存 sbadaddr
    STORE s4, 35*REGBYTES(sp)   // 保存 scause
    .endm

    /*
     * RESTORE_ALL - 从栈恢复所有寄存器（上下文恢复）
     * 
     * 作用：从 trapframe 恢复异常发生时的 CPU 状态
     * 
     * 恢复顺序：
     *   1. 先恢复 sstatus 和 sepc（sret 指令需要）
     *   2. 再恢复通用寄存器 x1, x3-x31
     *   3. 最后恢复 sp（x2）
     * 
     * 为什么最后恢复 sp？
     *   因为在恢复过程中，需要用 sp 来访问 trapframe 的各个位置
     *   只有所有其他寄存器恢复完后，才能修改 sp
     */
    // 从栈恢复所有寄存器
    .macro RESTORE_ALL

    /*
     * 步骤1: 恢复 sstatus 和 sepc
     * 
     * 这两个寄存器必须先恢复，因为：
     *   - sstatus: sret 会根据 SPP 位切换特权级
     *              会根据 SPIE 位恢复中断使能状态
     *   - sepc:    sret 会跳转到 sepc 指向的地址
     */
    // 恢复sstatus和sepc（异常返回需要）
    LOAD s1, 32*REGBYTES(sp)    // 从 trapframe[32] 加载 sstatus
    LOAD s2, 33*REGBYTES(sp)    // 从 trapframe[33] 加载 sepc

    csrw sstatus, s1            // 写入 sstatus
    csrw sepc, s2               // 写入 sepc

    /*
     * 步骤2: 恢复通用寄存器 (x1, x3-x31)
     * 
     * 注意：x0 不需要恢复（硬连线为0）
     *       x2(sp) 最后恢复
     */
    # 恢复x寄存器（x1~x31），x2为sp，最后恢复
    LOAD x1, 1*REGBYTES(sp)     // 恢复 ra (返回地址)
    LOAD x3, 3*REGBYTES(sp)     // 恢复 gp
    LOAD x4, 4*REGBYTES(sp)     // 恢复 tp
    LOAD x5, 5*REGBYTES(sp)     // 恢复 t0
    LOAD x6, 6*REGBYTES(sp)     // 恢复 t1
    LOAD x7, 7*REGBYTES(sp)     // 恢复 t2
    LOAD x8, 8*REGBYTES(sp)     // 恢复 s0/fp
    LOAD x9, 9*REGBYTES(sp)     // 恢复 s1
    LOAD x10, 10*REGBYTES(sp)   // 恢复 a0
    LOAD x11, 11*REGBYTES(sp)   // 恢复 a1
    LOAD x12, 12*REGBYTES(sp)   // 恢复 a2
    LOAD x13, 13*REGBYTES(sp)   // 恢复 a3
    LOAD x14, 14*REGBYTES(sp)   // 恢复 a4
    LOAD x15, 15*REGBYTES(sp)   // 恢复 a5
    LOAD x16, 16*REGBYTES(sp)   // 恢复 a6
    LOAD x17, 17*REGBYTES(sp)   // 恢复 a7
    LOAD x18, 18*REGBYTES(sp)   // 恢复 s2
    LOAD x19, 19*REGBYTES(sp)   // 恢复 s3
    LOAD x20, 20*REGBYTES(sp)   // 恢复 s4
    LOAD x21, 21*REGBYTES(sp)   // 恢复 s5
    LOAD x22, 22*REGBYTES(sp)   // 恢复 s6
    LOAD x23, 23*REGBYTES(sp)   // 恢复 s7
    LOAD x24, 24*REGBYTES(sp)   // 恢复 s8
    LOAD x25, 25*REGBYTES(sp)   // 恢复 s9
    LOAD x26, 26*REGBYTES(sp)   // 恢复 s10
    LOAD x27, 27*REGBYTES(sp)   // 恢复 s11
    LOAD x28, 28*REGBYTES(sp)   // 恢复 t3
    LOAD x29, 29*REGBYTES(sp)   // 恢复 t4
    LOAD x30, 30*REGBYTES(sp)   // 恢复 t5
    LOAD x31, 31*REGBYTES(sp)   // 恢复 t6
    
    /*
     * 步骤3: 最后恢复栈指针 sp
     * 
     * 为什么最后恢复？
     *   因为前面所有的 LOAD 指令都依赖 sp 来访问 trapframe
     *   只有所有寄存器都恢复完毕后，才能修改 sp
     */
    # 最后恢复sp
    LOAD x2, 2*REGBYTES(sp)     // 恢复 sp，回到异常发生前的栈位置
    .endm

    /*
     * __alltraps - 异常/中断统一入口点
     * 
     * 硬件自动完成的操作（在跳转到这里之前）：
     *   1. PC → sepc (保存异常发生时的 PC)
     *   2. 特权级 → sstatus.SPP (保存异常前的特权级)
     *   3. 中断使能 → sstatus.SPIE (保存异常前的 SIE)
     *   4. 清除 sstatus.SIE (屏蔽 S-Mode 中断)
     *   5. 跳转到 stvec (即这里的 __alltraps)
     * 
     * 流程：
     *   中断/异常发生 → 硬件跳转到这里 → SAVE_ALL → trap() → RESTORE_ALL → sret
     * 
     * 中断与异常的处理路径：
     *   ┌────────────────┐
     *   │ 中断/异常发生   │
     *   └────────┬───────┘
     *            ↓ (硬件自动)
     *   ┌────────────────┐
     *   │ 跳转到 stvec    │ ← idt_init() 中设置为 __alltraps
     *   └────────┬───────┘
     *            ↓
     *   ┌────────────────┐
     *   │  __alltraps    │ ← 我们现在在这里
     *   └────────┬───────┘
     *            ↓
     *   ┌────────────────┐
     *   │   SAVE_ALL     │ 保存上下文
     *   └────────┬───────┘
     *            ↓
     *   ┌────────────────┐
     *   │   trap(tf)     │ 调用 C 处理函数
     *   └────────┬───────┘
     *            ↓
     *   ┌────────────────┐
     *   │  RESTORE_ALL   │ 恢复上下文
     *   └────────┬───────┘
     *            ↓
     *   ┌────────────────┐
     *   │     sret       │ 返回用户程序
     *   └────────────────┘
     */
    // 异常入口，全局符号
    .globl __alltraps
    .align(2)              // 对齐到 4 字节边界（2^2 = 4）
__alltraps:
    /*
     * 步骤1: 保存完整的异常现场
     * 
     * SAVE_ALL 宏会在栈上构建一个 trapframe 结构
     * 包含所有寄存器和 CSR 的值
     */
    SAVE_ALL                   // 保存现场（上下文切换开始）

    /*
     * 步骤2: 调用 C 语言的 trap() 函数
     * 
     * 参数传递（RISC-V 调用约定）：
     *   a0 (x10): 第一个参数，这里传递 trapframe 指针
     *   
     * 此时 sp 指向 trapframe 的起始地址
     * 将 sp 复制到 a0，作为 trap(struct trapframe *tf) 的参数
     */
    move  a0, sp               // a0 = &trapframe，传递给 trap() 函数
    
    /*
     * 调用 trap() 处理函数
     * 
     * trap() 位于 kern/trap/trap.c，会根据 scause 分发到：
     *   - interrupt_handler() : 处理中断（scause 最高位 = 1）
     *   - exception_handler() : 处理异常（scause 最高位 = 0）
     * 
     * jal 指令：
     *   - 将返回地址保存到 ra (x1)
     *   - 跳转到 trap 函数
     */
    jal trap                   // 跳转到 trap 处理函数
    
    /*
     * trap() 返回到这里
     * 
     * 重要约定：
     *   trap() 函数必须保证 sp 不变，即 trapframe 的位置不变
     *   这样才能正确恢复上下文
     */
    # trap返回后，sp应与进入trap前一致

    /*
     * __trapret - 异常返回路径
     * 
     * 从 trap() 返回后，会继续执行到这里
     * 也可以从其他地方直接跳转到这里（如进程切换后）
     */
    // 异常返回，全局符号
    .globl __trapret
__trapret:
    /*
     * 步骤1: 恢复异常现场
     * 
     * RESTORE_ALL 宏会从 trapframe 恢复所有寄存器
     * 包括 sstatus 和 sepc
     */
    RESTORE_ALL                // 恢复现场（上下文切换完成）
    
    /*
     * 步骤2: 执行 sret 指令返回
     * 
     * sret (Supervisor Return) 指令的作用：
     *   1. PC ← sepc (跳转到异常发生时的地址)
     *   2. 特权级 ← sstatus.SPP (恢复到异常前的特权级)
     *   3. sstatus.SIE ← sstatus.SPIE (恢复中断使能状态)
     *   4. sstatus.SPIE ← 1 (为下次异常准备)
     *   5. sstatus.SPP ← 0 (为下次异常准备，默认来自 U-Mode)
     * 
     * 中断与异常的区别在返回时的体现：
     *   - 中断：sepc 指向被中断的指令，返回后继续执行该指令
     *   - 异常：sepc 可能被修改（如跳过非法指令），返回到新地址
     * 
     * 例如：
     *   时钟中断：sepc 不变，返回继续执行
     *   断点异常：sepc += 指令长度，跳过 ebreak 指令
     *   非法指令：sepc += 指令长度，跳过非法指令
     */
    # 从 Supervisor 模式返回
    sret                       // 异常返回指令

/*
 * ============================================================================
 * 完整的中断/异常处理流程总结
 * ============================================================================
 * 
 * 1. 中断/异常发生（硬件自动）：
 *    - 保存 PC → sepc
 *    - 保存特权级 → sstatus.SPP
 *    - 屏蔽中断 (sstatus.SIE ← 0)
 *    - 跳转到 stvec (__alltraps)
 * 
 * 2. __alltraps：
 *    - SAVE_ALL：保存所有寄存器到栈（构建 trapframe）
 *    - move a0, sp：传递 trapframe 指针
 *    - jal trap：调用 C 处理函数
 * 
 * 3. trap() 函数（C 语言）：
 *    - trap_dispatch(tf)：根据 scause 分发
 *      ├─ 中断 (scause < 0)：interrupt_handler(tf)
 *      │   ├─ IRQ_S_TIMER：时钟中断处理
 *      │   ├─ IRQ_S_SOFT：软件中断处理
 *      │   └─ IRQ_S_EXT：外部中断处理
 *      └─ 异常 (scause >= 0)：exception_handler(tf)
 *          ├─ CAUSE_ILLEGAL_INSTRUCTION：非法指令
 *          ├─ CAUSE_BREAKPOINT：断点
 *          ├─ CAUSE_FAULT_LOAD：加载访问异常（缺页）
 *          └─ CAUSE_USER_ECALL：系统调用
 * 
 * 4. __trapret：
 *    - RESTORE_ALL：恢复所有寄存器
 *    - sret：返回到异常发生前的位置
 * 
 * ============================================================================
 * 中断与异常的关键区别
 * ============================================================================
 * 
 * 【触发时机】
 *   中断：异步，随时可能发生（如时钟到期、设备就绪）
 *   异常：同步，由当前指令引发（如非法指令、缺页）
 * 
 * 【scause 值】
 *   中断：最高位 = 1（如 0x8000000000000005 表示 S-Mode 时钟中断）
 *   异常：最高位 = 0（如 0x0000000000000002 表示非法指令）
 * 
 * 【sepc 处理】
 *   中断：sepc 通常不修改，返回后继续执行被中断的指令
 *   异常：可能修改 sepc，跳过触发异常的指令（如断点、非法指令）
 * 
 * 【可恢复性】
 *   中断：完全可恢复，处理后继续执行
 *   异常：分情况
 *     - 可恢复（Fault）：断点、缺页（修复后重新执行）
 *     - 部分可恢复：非法指令（跳过后继续）
 *     - 不可恢复（Abort）：严重硬件错误
 * 
 * ============================================================================
 */
