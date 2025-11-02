# 练习一

## 要求：

请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print\_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut\_down()函数关机。

## 实验过程：

1. **时钟中断**

首先我们需要理解时钟中断，时钟中断其实相当于体系结构里面的时钟信号。在`kern/driver/clock.h`中定义主要功能。除了可以初始化设置时钟中断的频率之外，还提供了设置下一次时钟中断的函数​*`clock_set_next_event()`*​。在下面的代码任务中我们需要用这个函数来实现时钟的周期中断。

2. 主要实现的代码部分：

接下来我们实现练习一的主要部分，练习一要求每遇到100次时钟中断后，调用print\_ticks子程序，在打印完10行后调用sbi.h中的shut\_down()函数关机。

由于最后需要调用关机函数，我们需要包含sbi.h

```C++
#include <sbi.h>
```

我们先初始化一个打印次数的变量。

```C++
int print_num = 0;
```

每次中断我们都需要设置下一次的时钟中断。再中断100次之后，我们调用*`print_ticks`*函数打印信息，并且增加打印次数，当打印次数到达10次之后，我们调用关机函数停止程序。

```C++
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
        ...
        case IRQ_S_TIMER:
            // 如果不注释下一行，则每个时钟中断都会打印一次
            // cprintf("Supervisor timer interrupt\n");
            clock_set_next_event();​ ​// 发生这次时钟中断的时候，我们要设置下一次时钟中断
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
            ...
    }
```

---

# 扩展三

## 要求

编程完善在触发一条非法指令异常和断点异常，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即`Illegal instruction caught at 0x(地址)`，`ebreak caught at 0x（地址）`与`Exception type:Illegal instruction`，`Exception type: breakpoint`。

---

## 实验流程

我们在扩展中对断点以及非法指令的处理均为首先打印非法信息，然后打印异常指令的地址，最后跳过断点/异常指令并更新epc寄存器。

### 非法指令异常处理

我们按照指导书中的要求首先打印非法指令的异常信息，即`Exception type:Illegal instruction`，然后我们将保存异常现场结构体的epc取出来并打印异常指令的地址，然后我们判断异常指令的长度为2或4字节，根据异常指令的长度来更新我们的epc。我们具体实现代码如下：

```C++
case CAUSE_ILLEGAL_INSTRUCTION:
            {
                cprintf("Exception type:Illegal instruction\n");
                uintptr_t ep = tf->epc;
                cprintf("Illegal instruction caught at 0x%08x\n", (unsigned)ep);
                int ilen = riscv_inst_length(ep);​ ​// 判断当前触发异常指令占多少字节
                // 跳过触发异常的指令，继续执行后续指令
                tf->epc = ep + ilen;
                break;
            }
```

### 中断指令异常处理

对于中断指令，我们处理的方法也是一样的，基本思路都是先打印信息然后依据异常指令的长度来更新，我们这里不再赘述。我们对于中断指令的代码实现如下：

```C++
case CAUSE_BREAKPOINT:
            {
                cprintf("Exception type: breakpoint\n");
                uintptr_t ep = tf->epc;
                cprintf("ebreak caught at 0x%08x\n", (unsigned)ep);
                int ilen = riscv_inst_length(ep);
                tf->epc = ep + ilen;
                break;
            }
```

### 异常指令长度判断

在riscv中，一般指令的长度为2字节或者4字节，我们需要自己实现对异常指令的长度求解。在riscv中，如果指令的最低两位是11，则该指令长度为32位以上，若最低两位不是11，则指令长度为16位（2字节）。我们基于这个定义实现我们异常指令长度判断的函数：

```C++
static inline int riscv_inst_length(uintptr_t epc) {
    volatile uint16_t *p16 = (volatile uint16_t *)epc;
    uint16_t low = *p16;
    int len = (low & 0x3) != 0x3 ? 2 : 4;
    // ​cprintf("riscv_inst_length: 0x%04x → %d bytes\n", low, len);
    return len;
}
```

### 实验结果

我们选择在init.c中中添加我们的非法指令，我们在init.c中分别加上中断以及异常指令，我们加上如下汇编指令：

```C++
asm volatile("ebreak");​          ​// 触发断点
    asm volatile(".word 0xffffffff");​ ​// 非法指令
```

然后我们在终端中运行`make qemu`查看我们的测试结果，我们的测试结果以及对应的汇编代码如下：

![](https://nankai.feishu.cn/space/api/box/stream/download/asynccode/?code=YzQ2NjYzNWUwMDczNDA0MmE5NzU2YmZhMDczN2IzNTFfR3FTUVVSbVNlejNNMXZqTFFUQWsxZTdpYU1xZEdsZ0dfVG9rZW46WlBYOWJYM2NJb29JRjB4V3RIMWM1UExnbmNiXzE3NjIwODU4MzQ6MTc2MjA4OTQzNF9WNA)![](https://nankai.feishu.cn/space/api/box/stream/download/asynccode/?code=NmE0MGNjMDg4ODhmZjA3YzdlOGFmOWZkM2IyZTc4ZjNfdU1lSzNKOHl2STZNR01SZFVnb0IyWUV2MW5QT2duOFBfVG9rZW46QVI4QmJ5RXR6b3VreHN4SUVOcGNBb09nblVYXzE3NjIwODU4MzQ6MTc2MjA4OTQzNF9WNA)

可以看到，我们的OS在正确的地址做出了正确的异常处理。

# 重要知识点

1. DTB（Device Tree Blob，设备树二进制文件）

用于描述硬件设备信息。它在操作系统启动时提供CPU、内存、外设等硬件结构和参数，方便内核根据dtb自动识别和初始化硬件，无需硬编码设备信息。

2. 大端格式（Big Endian）

是一种字节序存储方式，指数据的高位字节存放在内存的低地址处，低位字节存放在高地址处。例如，32位整数0x12345678在大端格式下的内存排列是：12 34 56 78（从低地址到高地址）。

DTB一般为大端格式，而RISC-V等平台一般使用小端格式，所以在/kern/driver/dtb.c中需要进行字节顺序转换。

3. 魔数（magic number）

`0xd00dfeed` 是DTB文件的标准魔数。如果读取到的 `magic` 不等于这个值，说明DTB文件格式错误或数据损坏，于是打印错误信息并返回，不再继续解析DTB内容。
