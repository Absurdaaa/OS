/*
 * clock.c
 * 用于RISC-V操作系统的时钟驱动，实现定时器初始化和时钟中断设置。
 * 主要功能：
 * 1. 初始化时钟，使系统能定时产生时钟中断（如每秒100次）。
 * 2. 设置下一个时钟事件，驱动系统时钟节拍。
 * 3. 提供获取当前CPU周期数的接口。
 * 4. 维护系统节拍计数器ticks。
 * 适用于Spike和QEMU等RISC-V仿真环境。
 */

#include <clock.h>
#include <defs.h>
#include <sbi.h>
#include <stdio.h>
#include <riscv.h>

// 系统节拍计数器，记录时钟中断次数
volatile size_t ticks;

/*
 * get_cycles - 获取当前CPU周期数
 * 用于定时器设置和时间测量。
 * 该函数通过汇编指令读取CPU的时间寄存器（rdtime/rdtimeh），
 * 在64位RISC-V下直接读取64位时间，在32位下通过两次读取高低位保证一致性。
 */
static inline uint64_t get_cycles(void) {
#if __riscv_xlen == 64
    uint64_t n;
    // 读取64位CPU周期数
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    return n;
#else
    uint32_t lo, hi, tmp;
    // 读取高低位并保证一致性，避免读取过程中高位变化导致结果错误
    __asm__ __volatile__(
        "1:\n"
        "rdtimeh %0\n"
        "rdtime %1\n"
        "rdtimeh %2\n"
        "bne %0, %2, 1b"
        : "=&r"(hi), "=&r"(lo), "=&r"(tmp));
    return ((uint64_t)hi << 32) | lo;
#endif
}

// Hardcode timebase
// timebase用于设定时钟中断的周期（单位：CPU周期数），
// 决定每次时钟中断之间的间隔，从而控制系统时钟节拍频率。
// 例如，timebase=100000表示每隔100000个CPU周期触发一次时钟中断。
// 该值可根据仿真环境（Spike/QEMU）调整，影响时钟中断频率。
static uint64_t timebase = 100000;

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * 初始化时钟系统，使能定时器中断，并设置下一个时钟事件。
 * Spike环境下建议除以500，QEMU环境下建议除以100。
 * 初始化ticks计数器为0，并打印初始化信息。
 * */
void clock_init(void) {
    // enable timer interrupt in sie
    // 使能Supervisor Timer Interrupt（STIP），允许定时器中断
    set_csr(sie, MIP_STIP);
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    // timebase = sbi_timebase() / 500;
    // 设置下一个时钟事件
    clock_set_next_event();

    // initialize time counter 'ticks' to zero
    // 初始化节拍计数器
    ticks = 0;

    // 打印初始化信息
    cprintf("++ setup timer interrupts\n");
}

/*
 * clock_set_next_event - 设置下一次时钟中断的触发时间
 * 通过sbi_set_timer通知SBI层在指定周期数产生中断
 * 该函数会将下一个中断时间设为当前周期数加上timebase，实现周期性时钟中断。
 */
void clock_set_next_event(void) {
    // 设定下一个中断时间为当前周期数加上timebase
    sbi_set_timer(get_cycles() + timebase);
}

/*
 * sbi_set_timer - 设置下一次定时器中断的时间
 * @stime_value: 触发定时器中断的目标时间（CPU周期数）
 * 通过SBI调用，通知底层固件在指定时间产生时钟中断。
 * 该函数是与RISC-V SBI接口的桥梁，实际设置硬件定时器。
 */
