#ifndef __KERN_TRAP_TRAP_H__
#define __KERN_TRAP_TRAP_H__

#include <defs.h>

// pushregs 结构体保存所有通用寄存器的值，用于异常现场保存
struct pushregs {
    uintptr_t zero;  // Hard-wired zero，硬连线为0的寄存器
    uintptr_t ra;    // Return address，返回地址寄存器
    uintptr_t sp;    // Stack pointer，栈指针寄存器
    uintptr_t gp;    // Global pointer，全局指针寄存器
    uintptr_t tp;    // Thread pointer，线程指针寄存器
    uintptr_t t0;    // Temporary，临时寄存器
    uintptr_t t1;    // Temporary，临时寄存器
    uintptr_t t2;    // Temporary，临时寄存器
    uintptr_t s0;    // Saved register/frame pointer，保存寄存器/帧指针
    uintptr_t s1;    // Saved register，保存寄存器
    uintptr_t a0;    // Function argument/return value，函数参数/返回值
    uintptr_t a1;    // Function argument/return value，函数参数/返回值
    uintptr_t a2;    // Function argument，函数参数
    uintptr_t a3;    // Function argument，函数参数
    uintptr_t a4;    // Function argument，函数参数
    uintptr_t a5;    // Function argument，函数参数
    uintptr_t a6;    // Function argument，函数参数
    uintptr_t a7;    // Function argument，函数参数
    uintptr_t s2;    // Saved register，保存寄存器
    uintptr_t s3;    // Saved register，保存寄存器
    uintptr_t s4;    // Saved register，保存寄存器
    uintptr_t s5;    // Saved register，保存寄存器
    uintptr_t s6;    // Saved register，保存寄存器
    uintptr_t s7;    // Saved register，保存寄存器
    uintptr_t s8;    // Saved register，保存寄存器
    uintptr_t s9;    // Saved register，保存寄存器
    uintptr_t s10;   // Saved register，保存寄存器
    uintptr_t s11;   // Saved register，保存寄存器
    uintptr_t t3;    // Temporary，临时寄存器
    uintptr_t t4;    // Temporary，临时寄存器
    uintptr_t t5;    // Temporary，临时寄存器
    uintptr_t t6;    // Temporary，临时寄存器
};

// trapframe 结构体保存异常现场，包括所有寄存器和相关状态
struct trapframe {
    struct pushregs gpr;   // 通用寄存器现场
    uintptr_t status;      // CPU 状态寄存器
    uintptr_t epc;         // 异常程序计数器（异常发生时的指令地址）
    uintptr_t badvaddr;    // 异常地址（如访问异常时的地址）
    uintptr_t cause;       // 异常/中断原因码
};

// trap - 异常/中断总入口函数，分发处理
void trap(struct trapframe *tf);
// idt_init - 初始化中断描述符表
void idt_init(void);
// print_trapframe - 打印 trapframe 结构体内容
void print_trapframe(struct trapframe *tf);
// print_regs - 打印 pushregs 结构体内容
void print_regs(struct pushregs* gpr);
// trap_in_kernel - 判断异常是否发生在内核态
bool trap_in_kernel(struct trapframe *tf);

#endif /* !__KERN_TRAP_TRAP_H__ */
