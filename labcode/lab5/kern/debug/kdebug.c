#include <assert.h>
#include <defs.h>
#include <stdio.h>

/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
// 打印内核信息 - 输出内核相关的关键信息，包括：
// - 内核入口地址
// - 文本段(.text)结束地址(etext)
// - 数据段(.data)结束地址(edata)
// - 内核内存占用结束地址(end)
// - 内核总共使用的内存大小(KB为单位)
void print_kerninfo(void)
{
  // 声明外部符号：这些符号由链接器在链接时确定具体地址
  // etext: 文本段结束地址
  // edata: 数据段结束地址
  // end:   内核所有段(包括bss)的结束地址
  // kern_init: 内核入口函数地址
  extern char etext[], edata[], end[], kern_init[];

  cprintf("Special kernel symbols:\n");
  cprintf("  entry  0x%08x (virtual)\n", kern_init); // 内核入口地址(虚拟地址)
  cprintf("  etext  0x%08x (virtual)\n", etext);     // 文本段结束地址(虚拟地址)
  cprintf("  edata  0x%08x (virtual)\n", edata);     // 数据段结束地址(虚拟地址)
  cprintf("  end    0x%08x (virtual)\n", end);       // 内核内存占用结束地址(虚拟地址)

  // 计算内核可执行文件的内存占用大小(KB)
  // 公式说明：(end - kern_init) 得到字节数，+1023是为了向上取整，再除以1024转换为KB
  cprintf("Kernel executable memory footprint: %dKB\n",
          (end - kern_init + 1023) / 1024);
}

/* *
 * print_debuginfo - read and print the stat information for the address @eip,
 * and info.eip_fn_addr should be the first address of the related function.
 * */
// 打印调试信息 - 根据指定的EIP(指令指针)地址，读取并打印对应的状态信息
// 参数：
//   eip: 要查询的指令指针地址
// 要求：
//   info.eip_fn_addr 应指向该EIP所属函数的起始地址
void print_debuginfo(uintptr_t eip) { panic("Not Implemented!"); }

/* *
 * print_stackframe - print a list of the saved eip values from the nested
 * 'call' instructions that led to the current point of execution
 *
 * The x86 stack pointer, namely esp, points to the lowest location on the stack
 * that is currently in use. Everything below that location in stack is free.
 * Pushing a value onto the stack will invole decreasing the stack pointer and then
 * writing the value to the place that stack pointer pointes to. And popping a value do
 * the opposite.
 *
 * The ebp (base pointer) register, in contrast, is associated with the stack
 * primarily by software convention. On entry to a C function, the function's
 * prologue code normally saves the previous function's base pointer by pushing
 * it onto the stack, and then copies the current esp value into ebp for the
 * duration of the function. If all the functions in a program obey this convention,
 * then at any given point during the program's execution, it is possible to
 * trace back through the stack by following the chain of saved ebp pointers and
 * determining exactly what nested sequence of function calls caused this particular point
 * in the program to be reached. This capability can be particularly useful, for
 * example, when a particular function causes an assert failure or panic because bad
 * arguments were passed to it, but you aren't sure who passed the bad arguments. A stack
 * backtrace lets you find the offending function.
 *
 * The inline function read_ebp() can tell us the value of current ebp. And the
 * non-inline function read_eip() is useful, it can read the value of current
 * eip, since while calling this function, read_eip() can read the caller's eip from
 * stack easily.
 *
 * In print_debuginfo(), the function debuginfo_eip() can get enough information
 * about calling-chain. Finally print_stackframe() will trace and print them for
 * debugging.
 *
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
// 打印栈帧 - 输出导致当前执行点的嵌套call指令所保存的所有EIP值（栈回溯）
//
// X86架构栈机制说明：
//   - 栈指针(esp)：指向当前栈中正在使用的最低地址，该地址以下的栈空间为空闲
//   - 压栈操作：先减小esp，再将值写入esp指向的地址
//   - 出栈操作：先读取esp指向的值，再增大esp
//
// 基址指针(ebp)使用约定：
//   - 函数入口处，会先将调用者的ebp压栈保存，然后将当前esp的值赋给ebp
//   - 遵循该约定的情况下，可以通过ebp链回溯整个函数调用栈，确定当前执行点的调用路径
//   - 典型用途：当函数因参数错误触发assert/panic时，可通过栈回溯定位传递错误参数的调用者
//
// 辅助函数说明：
//   - read_ebp()(内联函数)：获取当前ebp寄存器的值
//   - read_eip()(非内联函数)：获取当前eip寄存器的值（调用时可从栈中读取调用者的eip）
//
// 实现依赖：
//   - print_debuginfo()中调用的debuginfo_eip()可获取调用链的完整信息
//   - print_stackframe()最终负责追踪并打印这些调试信息
//
// 边界条件：
//   - ebp链的长度有限，在boot/bootasm.S中跳转到内核入口前，ebp会被设为0，这是回溯的终止边界
void print_stackframe(void)
{
  panic("Not Implemented!");
}