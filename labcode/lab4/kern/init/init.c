#include <defs.h>
#include <stdio.h>
#include <string.h>
#include <console.h>
#include <kdebug.h>
#include <picirq.h>
#include <trap.h>
#include <clock.h>
#include <intr.h>
#include <pmm.h>
#include <vmm.h>
#include <proc.h>
#include <kmonitor.h>
#include <dtb.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    dtb_init();
    cons_init(); // init the console

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);

    print_kerninfo();

    // grade_backtrace();

    pmm_init(); // init physical memory management

    pic_init(); // init interrupt controller，初始化中断控制器
    idt_init(); // init interrupt descriptor table，初始化中断描述符表

    vmm_init();  // init virtual memory management，初始化虚拟内存管理
    proc_init(); // init process table，初始化进程表

    // 打印调试
    // const char *message2 = "proc_init done.";
    // cprintf("%s\n\n", message2);

    clock_init();  // init clock interrupt，初始化时钟中断
    intr_enable(); // enable irq interrupt，使能 IRQ 中断

    cpu_idle(); // run idle process，运行空闲进程
}

static void
lab1_print_cur_status(void)
{
    static int round = 0;
    round++;
}
