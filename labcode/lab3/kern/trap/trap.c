#include <assert.h>
#include <clock.h>
#include <console.h>
#include <defs.h>
#include <kdebug.h>
#include <memlayout.h>
#include <mmu.h>
#include <riscv.h>
#include <stdio.h>
#include <trap.h>
#include <sbi.h>

#define TICK_NUM 100

int print_num = 0;    // 打印次数计数器,打印10次之后调用关机函数

// print_ticks - 打印时钟中断次数
static void print_ticks() {
    cprintf("%d ticks\n", TICK_NUM);
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S·  
 * idt_init - 初始化中断描述符表（IDT），设置异常向量入口地址
 */
void idt_init(void) {
    /* LAB3 YOUR CODE : STEP 2 */
    /* (1) Where are the entry addrs of each Interrupt Service Routine (ISR)?
     *     All ISR's entry addrs are stored in __vectors. where is uintptr_t
     * __vectors[] ?
     *     __vectors[] is in kern/trap/vector.S which is produced by
     * tools/vector.c
     *     (try "make" command in lab3, then you will find vector.S in kern/trap
     * DIR)
     *     You can use  "extern uintptr_t __vectors[];" to define this extern
     * variable which will be used later.
     * (2) Now you should setup the entries of ISR in Interrupt Description
     * Table (IDT).
     *     Can you see idt[256] in this file? Yes, it's IDT! you can use SETGATE
     * macro to setup each item of IDT
     * (3) After setup the contents of IDT, you will let CPU know where is the
     * IDT by using 'lidt' instruction.
     *     You don't know the meaning of this instruction? just google it! and
     * check the libs/x86.h to know more.
     *     Notice: the argument of lidt is idt_pd. try to find it!
     */
    /* LAB3 你的代码：STEP 2 */
    /* (1) 每个中断服务例程（ISR）的入口地址在哪里？
     *     所有 ISR 的入口地址都存储在 __vectors 中。那么 uintptr_t __vectors[] 在哪里？
     *     __vectors[] 位于 kern/trap/vector.S 文件中，这个文件是由 tools/vector.c 生成的。
     *     （你可以在 lab3 目录下执行 "make" 命令，然后会在 kern/trap 目录下看到 vector.S 文件）
     *     你可以用 "extern uintptr_t __vectors[];" 来声明这个外部变量，后续会用到它。
     * (2) 现在你需要在中断描述符表（IDT）中设置 ISR 的入口。
     *     你能在这个文件里看到 idt[256] 吗？是的，这就是 IDT！你可以用 SETGATE 宏来设置 IDT 的每一项。
     * (3) 设置好 IDT 内容后，你需要让 CPU 知道 IDT 的位置，可以用 'lidt' 指令。
     *     你不知道这个指令什么意思？可以去 Google 查查！也可以看看 libs/x86.h 文件了解更多。
     *     注意：lidt 的参数是 idt_pd。试着找找它！
     */

    // 1. 声明异常处理入口函数 __alltraps
    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    // 设置 sscratch 为 0，表示当前在内核态
    write_csr(sscratch, 0);
    /* Set the exception vector address */
    // 设置异常向量表地址为 __alltraps
    write_csr(stvec, &__alltraps);
}

/* trap_in_kernel - test if trap happened in kernel */
/* trap_in_kernel - 判断异常是否发生在内核态 */
bool trap_in_kernel(struct trapframe *tf) {
    // SSTATUS_SPP 标志位为 1 表示在内核态
    return (tf->status & SSTATUS_SPP) != 0;
}

// print_trapframe - 打印 trapframe 结构体内容，便于调试
void print_trapframe(struct trapframe *tf) {
    cprintf("trapframe at %p\n", tf);
    print_regs(&tf->gpr);
    cprintf("  status   0x%08x\n", tf->status);
    cprintf("  epc      0x%08x\n", tf->epc);
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

// print_regs - 打印 pushregs 结构体内容，显示所有寄存器值
void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    cprintf("  ra       0x%08x\n", gpr->ra);
    cprintf("  sp       0x%08x\n", gpr->sp);
    cprintf("  gp       0x%08x\n", gpr->gp);
    cprintf("  tp       0x%08x\n", gpr->tp);
    cprintf("  t0       0x%08x\n", gpr->t0);
    cprintf("  t1       0x%08x\n", gpr->t1);
    cprintf("  t2       0x%08x\n", gpr->t2);
    cprintf("  s0       0x%08x\n", gpr->s0);
    cprintf("  s1       0x%08x\n", gpr->s1);
    cprintf("  a0       0x%08x\n", gpr->a0);
    cprintf("  a1       0x%08x\n", gpr->a1);
    cprintf("  a2       0x%08x\n", gpr->a2);
    cprintf("  a3       0x%08x\n", gpr->a3);
    cprintf("  a4       0x%08x\n", gpr->a4);
    cprintf("  a5       0x%08x\n", gpr->a5);
    cprintf("  a6       0x%08x\n", gpr->a6);
    cprintf("  a7       0x%08x\n", gpr->a7);
    cprintf("  s2       0x%08x\n", gpr->s2);
    cprintf("  s3       0x%08x\n", gpr->s3);
    cprintf("  s4       0x%08x\n", gpr->s4);
    cprintf("  s5       0x%08x\n", gpr->s5);
    cprintf("  s6       0x%08x\n", gpr->s6);
    cprintf("  s7       0x%08x\n", gpr->s7);
    cprintf("  s8       0x%08x\n", gpr->s8);
    cprintf("  s9       0x%08x\n", gpr->s9);
    cprintf("  s10      0x%08x\n", gpr->s10);
    cprintf("  s11      0x%08x\n", gpr->s11);
    cprintf("  t3       0x%08x\n", gpr->t3);
    cprintf("  t4       0x%08x\n", gpr->t4);
    cprintf("  t5       0x%08x\n", gpr->t5);
    cprintf("  t6       0x%08x\n", gpr->t6);
}

// interrupt_handler - 中断处理函数，根据 cause 判断中断类型并处理
    // trapframe 结构体保存异常现场，包括所有寄存器和相关状态
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
        case IRQ_U_SOFT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_SOFT:
            cprintf("Supervisor software interrupt\n");
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
            break;
        case IRQ_S_TIMER:
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // 如果不注释下一行，则每个时钟中断都会打印一次
            // cprintf("Supervisor timer interrupt\n");
             /* LAB3 EXERCISE1   YOUR CODE : 2312966 */
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            // 1. 设置下次时钟中断
            // 2. 维护时钟计数器
            // 3. 每100次中断打印一次
            // 4. 达到指定次数后关机
            clock_set_next_event(); // 发生这次时钟中断的时候，我们要设置下一次时钟中断
            if (++ticks % TICK_NUM == 0)
            {
              print_num++;
              print_ticks();
            }
            if (print_num == 10)
            {
              cprintf("Calling SBI shutdown...\n");
              sbi_shutdown();
            }
            break;
        case IRQ_H_TIMER:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_TIMER:
            cprintf("Machine software interrupt\n");
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
            break;
        case IRQ_H_EXT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_EXT:
            cprintf("Machine software interrupt\n");
            break;
        default:
            // 未知中断类型，打印 trapframe 便于调试
            print_trapframe(tf);
            break;
    }
}

// exception_handler - 异常处理函数，根据 cause 判断异常类型并处理
void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
        case CAUSE_MISALIGNED_FETCH:
            // 指令地址未对齐异常
            break;
        case CAUSE_FAULT_FETCH:
            // 指令访问异常
            break;
        case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
             /* LAB3 CHALLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            // 1. 打印非法指令异常信息
            // 2. 打印异常指令地址
            // 3. 跳过异常指令，更新 epc
            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB3 CHALLLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            // 1. 打印断点异常信息
            // 2. 打印异常指令地址
            // 3. 跳过断点指令，更新 epc
            break;
        case CAUSE_MISALIGNED_LOAD:
            // 加载地址未对齐异常
            break;
        case CAUSE_FAULT_LOAD:
            // 加载访问异常
            break;
        case CAUSE_MISALIGNED_STORE:
            // 存储地址未对齐异常
            break;
        case CAUSE_FAULT_STORE:
            // 存储访问异常
            break;
        case CAUSE_USER_ECALL:
            // 用户态系统调用异常
            break;
        case CAUSE_SUPERVISOR_ECALL:
            // 管理员态系统调用异常
            break;
        case CAUSE_HYPERVISOR_ECALL:
            // 虚拟机态系统调用异常
            break;
        case CAUSE_MACHINE_ECALL:
            // 机器态系统调用异常
            break;
        default:
            // 未知异常类型，打印 trapframe 便于调试
            print_trapframe(tf);
            break;
    }
}

// trap_dispatch - 分发异常或中断到对应处理函数
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
        // interrupts
        // cause < 0 表示中断
        interrupt_handler(tf);
    } else {
        // exceptions
        // cause >= 0 表示异常
        exception_handler(tf);
    }
}

/* *
 * trap - handles or dispatches an exception/interrupt. if and when trap()
 * returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
/* trap - 处理异常或中断，分发到对应的处理函数
 * 返回后由 trapentry.S 恢复 CPU 状态并返回异常现场
 */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    // 根据异常类型分发处理
    trap_dispatch(tf);
}
