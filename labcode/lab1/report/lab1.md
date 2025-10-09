# 练习1：理解内核启动中的程序入口操作

阅读 kern/init/entry.S内容代码，结合操作系统内核启动流程，说明指令 la sp, bootstacktop 完成了什么操作，目的是什么？ tail kern\_init 完成了什么操作，目的是什么？

---

## `la sp, bootstacktop` 指令理论分析

**理论展开为：**

```Assembly
auipc sp, %pcrel_hi(bootstacktop)    # 加载bootstacktop的高20位到sp
addi  sp, sp, %pcrel_lo(bootstacktop) # 加上低12位偏移
```

**具体操作：**

1. ​**计算bootstacktop的绝对地址**​：通过PC相对寻址方式获取内核栈顶的物理地址
2. ​**设置栈指针寄存器**​：将计算得到的地址加载到sp寄存器中

### 目的和意义：

#### 1. 为C代码执行建立运行环境

* C语言函数调用依赖栈来保存返回地址、局部变量、函数参数等
* 没有有效的栈指针，任何C函数都无法正常执行

#### 2. 建立内核栈空间

* `bootstacktop` 指向预先在内核数据段分配的内核栈的顶部
* 栈空间大小由 `KSTACKSIZE` 定义（通常是多个页面）
* 栈从高地址向低地址增长，所以初始时sp指向栈顶

#### 3. 内存布局准备

```Plain
bootstack (栈底) → [ 内核栈空间 KSTACKSIZE ] → bootstacktop (栈顶, sp初始指向这里)
```

#### 4. 为后续操作提供基础

* 中断处理需要栈来保存上下文
* 内存管理初始化需要栈空间
* 进程调度等核心功能都依赖栈

## `tail kern_init` 指令理论分析

```Assembly
jal x0, kern_init  # 跳转到kern_init，不保存返回地址到ra寄存器
```

**具体操作：**

1. ​**直接跳转**​：无条件跳转到 `kern_init` 函数的入口地址
2. ​**尾调用优化**​：不将返回地址保存到ra寄存器(x1)
3. ​**不建立栈帧**​：不修改当前栈指针

### 目的和意义：

#### 1. 控制权转移

* 从汇编启动代码跳转到C语言内核初始化代码
* 标志着低级硬件初始化完成，进入高级内核初始化阶段

#### 2. 尾调用优化

* ​**不保存返回地址**​：因为这是内核入口，不需要返回到启动代码
* ​**节省栈空间**​：不创建新的栈帧，复用当前的栈环境
* ​**性能优化**​：减少不必要的寄存器操作

#### 3. 单向执行流程

```Plain
汇编启动代码 (entry.S) 
    → tail kern_init (永不返回)
        → C内核初始化 (kern_init)
            → 操作系统主循环
```

#### 4. 符合内核启动语义

* 内核启动是"单程票"，不需要返回启动代码
* 如果`kern_init`意外返回，系统将进入未定义状态

## 整体启动流程上下文

### 系统启动序列：

1. **硬件上电** → BIOS/OpenSBI初始化
2. **加载内核** → 将内核镜像加载到内存
3. **跳转到entry** → 执行`kern_entry`（当前代码）
4. **栈初始化** → `la sp, bootstacktop`
5. **进入C环境** → `tail kern_init`
6. **内核初始化** → 在`kern_init()`中继续初始化过程

### 在操作系统原理中的体现：

1. ​**运行环境建立**​：为高级语言提供必要的硬件环境
2. ​**内存管理基础**​：栈是内存管理的重要组成部分
3. ​**控制流转移**​：从固定启动序列到灵活的内核代码
4. ​**抽象层次提升**​：从底层硬件操作到高级内核服务

这两条指令共同完成了从"裸机环境"到"内核运行环境"的关键转变，是操作系统启动过程中承上启下的重要环节。

---

## 两条指令的实际分析

但实际上我们用GDB进行分析的时候发现并不一致：

1. 首先我们在入口处打上断点

```Plain
b *0x80200000
```

2. 用指令查看预期的栈顶指针，预期为0x80203000

```Assembly
(gdb) info address bootstacktop
Symbol "bootstacktop" is at 0x80203000 in a file compiled without debugging.
```

![](labcode/lab1/report/img/addr.jpg)

3. 用指令查看附近的编译指令，发现和预期的auipc和addi指令不一样，这里用的是auipc和mv，这里由于预期的地址为0x80203000，并没有偏移地址，所以这里addi应该是加0，而`mv sp,sp` 是 `addi sp, sp, 0` 的伪指令，GDB的反汇编器将常见的指令序列转换回伪指令形式显示，所以显示的不一样。后面的j指令同样是伪指令。

```Assembly
(gdb) display/5i 0x80200000
2: x/5i 0x80200000
   0x80200000 <kern_entry>:     auipc   sp,0x3
   0x80200004 <kern_entry+4>:   mv      sp,sp
=> 0x80200008 <kern_entry+8>:   j       0x8020000a <kern_init>
   0x8020000a <kern_init>:      auipc   a0,0x3
   0x8020000e <kern_init+4>:    addi    a0,a0,-2
```

![](labcode/lab1/report/img/x5i.jpg)

这里我们可以用si指令单步执行来对应指令，并同时用i r指令查看关键寄存器的状态。

![](labcode/lab1/report/img/si.jpg)

---

# 练习2: 使用GDB验证启动流程

为了熟悉使用 QEMU 和 GDB 的调试方法，请使用 GDB 跟踪 QEMU 模拟的 RISC-V 从加电开始，直到执行内核第一条指令（跳转到 0x80200000）的整个过程。通过调试，请思考并回答：RISC-V 硬件加电后最初执行的几条指令位于什么地址？它们主要完成了哪些功能？请在报告中简要记录你的调试过程、观察结果和问题的答案。

---

### 问题1：RISC-V硬件加电后最初执行的几条指令位于什么地址？

答案： 位于 0x1000 地址到 0x1010 地址。

### 问题2：它们主要完成了哪些功能？

在0x1000处的前5条指令完成了：

1. `auipc t0,0x0` - 将PC加上立即数(0x0<<12)并存入寄存器t0，这一条指令的作用是生成一个基地址，用于后续计算跳转目标或数据地址。在启动的过程中，它通常用来定位内核映像在内存中的偏移
2. `addi a1,t0,32` - 将t0中的数据加上立即数32并且存入寄存器a1中，这一条指令被用于计算内核入口地址或栈地址的偏移。结合auipc，完成从复位向量到内核入口的地址计算。
3. `csrr a0,mhartid` - 读取hart ID(当前CPU核心编号)到寄存器a0，这一条指令在多核系统中可以让CPU的每个核心知道自己是第几个hart。
4. `ld t0,24(t0)` - 从固定偏移(0x1018)加载OpenSBI主入口地址到t0(0x80000000)，用于读取内核入口指针。在启动流程中，它通常用来获取kern\_entry的实际地址。
5. `jr t0` - 跳转到OpenSBI主初始化代码(0x80000000)，将控制权交给内核入口(kern\_entry)，完成从复位向量到内核入口的跳转。

主要功能总结：

* ​**建立基地址**​：通过 `auipc` + `addi` 计算偏移，为后续读取跳转目标地址做准备；
* ​**识别 CPU 核心**​：利用 `csrr a0, mhartid` 获取当前 hart ID，为多核启动流程做区分（主核负责初始化，从核可能等待）；
* ​**加载内核入口地址**​：通过 `ld t0, 24(t0)` 从固定偏移位置加载 OpenSBI 或内核入口地址；
* ​**完成跳转**​：使用 `jr t0` 跳转至内核（kern\_entry）或 OpenSBI 主入口地址，正式进入内核初始化阶段；
* ​**实现从复位向量到内核入口的控制权转移**​，为内核运行奠定初始环境基础。

### 通过OPENSBI源码分析跳转到OS加载的过程

#### 入口点

OpenSBI的入口点在`firmware/fw_base.S:48`的`_start`标签：

```Assembly
.globl _start
_start:
    /* Find preferred boot HART id */
    MOV_3R s0, a0, s1, a1, s2, a2
    call fw_boot_hart
    add a6, a0, zero
    MOV_3R a0, s0, a1, s1, a2, s2
    li a7, -1
    beq a6, a7, _try_lottery
    /* Jump to relocation wait loop if we are not boot hart */
    bne a0, a6, _wait_for_boot_hart
```

1. 调用`fw_boot_hart()`获取boot HART ID
2. 如果当前HART不是boot HART，跳转到等待循环
3. 只有boot HART继续执行初始化流程

#### Boot HART选择机制

OpenSBI使用两种机制选择boot HART：

1. ​**固定ID方式**​：平台指定的boot HART ID
2. ​**彩票机制**​：通过原子操作确保只有一个HART成为boot HART

```Assembly
_try_lottery:
    lla a6, _boot_lottery
    li a7, BOOT_LOTTERY_ACQUIRED
    amoswap.w a6, a7, (a6)
    bnez a6, _wait_for_boot_hart
```

#### 重定位过程

Boot HART执行重定位：

```Assembly
/* relocate the global table content */
li t0, FW_TEXT_START    /* link start */
lla t1, _fw_start       /* load start */
sub t2, t1, t0          /* load offset */
lla t0, __rela_dyn_start
lla t1, __rela_dyn_end
beq t0, t1, _relocate_done
```

重定位完成后，代码在实际的链接地址上运行。

#### 中间步骤：初始化/冷启动/热启动

冷启动HART执行`init_coldboot()`函数（`lib/sbi/sbi_init.c:218`）：

```C
static void __noreturn init_coldboot(struct sbi_scratch *scratch, u32 hartid)
{
    int rc;
    const struct sbi_platform *plat = sbi_platform_ptr(scratch);

    /* 1. 初始化scratch空间 */
    rc = sbi_scratch_init(scratch);

    /* 2. 初始化堆内存 */
    rc = sbi_heap_init(scratch);

    /* 3. 初始化域管理 */
    rc = sbi_domain_init(scratch, hartid);

    /* 4. 初始化HSM */
    rc = sbi_hsm_init(scratch, true);

    /* 5. 平台早期初始化 */
    rc = sbi_platform_early_init(plat, true);

    /* 6. HART初始化 */
    rc = sbi_hart_init(scratch, true);

    /* 7. 设备初始化 */
    rc = sbi_irqchip_init(scratch, true);  // 中断控制器
    rc = sbi_ipi_init(scratch, true);      // 处理器间中断
    rc = sbi_timer_init(scratch, true);    // 定时器

    /* 8. 平台最终初始化 */
    rc = sbi_platform_final_init(plat, true);

    /* 9. Ecall初始化 */
    rc = sbi_ecall_init();

    /* 10. 域启动 */
    rc = sbi_domain_startup(scratch, hartid);

    /* 11. PMP配置 */
    rc = sbi_hart_pmp_configure(scratch);

    /* 12. 完成启动 */
    sbi_hsm_hart_start_finish(scratch, hartid);
}
```

非boot HART执行`init_warmboot()`：

```C
static void __noreturn init_warmboot(struct sbi_scratch *scratch, u32 hartid)
{
    /* 等待冷启动完成 */
    wait_for_coldboot(scratch);

    /* 获取HART状态 */
    hstate = sbi_hsm_hart_get_state(sbi_domain_thishart_ptr(), hartid);

    if (hstate == SBI_HSM_STATE_SUSPENDED) {
        init_warm_resume(scratch, hartid);
    } else {
        init_warm_startup(scratch, hartid);
    }
}
```

#### 跳转触发点

跳转到OS在`sbi_hsm_hart_start_finish()`函数中触发（`lib/sbi/sbi_hsm.c`）：

```C
void __noreturn sbi_hsm_hart_start_finish(struct sbi_scratch *scratch,
                                          u32 hartid)
{
    unsigned long next_arg1;
    unsigned long next_addr;
    unsigned long next_mode;
    struct sbi_hsm_data *hdata = sbi_scratch_offset_ptr(scratch,
                                                        hart_data_offset);

    /* 状态转换：START_PENDING -> STARTED */
    if (!__sbi_hsm_hart_change_state(hdata, SBI_HSM_STATE_START_PENDING,
                                     SBI_HSM_STATE_STARTED))
        sbi_hart_hang();

    /* 获取跳转参数 */
    next_arg1 = scratch->next_arg1;  // 通常指向FDT
    next_addr = scratch->next_addr;  // OS入口点地址
    next_mode = scratch->next_mode;  // 目标特权级（通常是PRV_S）

    /* 释放启动票据 */
    hsm_start_ticket_release(hdata);

    /* 执行特权级切换和跳转 */
    sbi_hart_switch_mode(hartid, next_arg1, next_addr, next_mode, false);
}
```

`sbi_hart_switch_mode()`函数（`lib/sbi/sbi_hart.c`）实现关键的特权级切换：

```C
void __noreturn sbi_hart_switch_mode(unsigned long arg0, unsigned long arg1,
                                     unsigned long next_addr, unsigned long next_mode,
                                     bool next_virt)
{
    unsigned long val;

    /* 检查目标特权级是否支持 */
    switch (next_mode) {
    case PRV_M:
        break;
    case PRV_S:
        if (!misa_extension('S'))
            sbi_hart_hang();
        break;
    case PRV_U:
        if (!misa_extension('U'))
            sbi_hart_hang();
        break;
    default:
        sbi_hart_hang();
    }

    /* 配置MSTATUS寄存器 */
    val = csr_read(CSR_MSTATUS);
    val = INSERT_FIELD(val, MSTATUS_MPP, next_mode);  // 设置返回后的特权级
    val = INSERT_FIELD(val, MSTATUS_MPIE, 0);        // 禁用中断使能
    csr_write(CSR_MSTATUS, val);

    /* 设置异常返回地址 */
    csr_write(CSR_MEPC, next_addr);

    /* 根据目标特权级配置CSR */
    if (next_mode == PRV_S) {
        csr_write(CSR_STVEC, next_addr);   // S-mode中断向量
        csr_write(CSR_SSCRATCH, 0);        // S-mode scratch寄存器
        csr_write(CSR_SIE, 0);             // 清除中断使能
        csr_write(CSR_SATP, 0);            // 清除页表
    }

    /* 设置函数参数 */
    register unsigned long a0 asm("a0") = arg0;  // 通常为hartid
    register unsigned long a1 asm("a1") = arg1;  // 通常为FDT地址

    /* 执行mret指令，切换特权级并跳转 */
    __asm__ __volatile__("mret" : : "r"(a0), "r"(a1));
    __builtin_unreachable();
}
```

### 逐步调试

同时我们尝试使用逐步的SI来逐次运行，通过python程序进行运行

```Python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import os
import signal
import socket
import subprocess
import sys
import time
from datetime import datetime
import pexpect
def wait_port(host: str, port: int, timeout_s: int = 40) -> bool:
    t0 = time.time()
    while time.time() - t0 < timeout_s:
        try:
            with socket.create_connection((host, port), timeout=1.0):
                return True
        except OSError:
            time.sleep(0.2)
    return False

def main():
    parser = argparse.ArgumentParser(
        
    )
    parser.add_argument("--workspace", default=".")
    parser.add_argument("--port", type=int, default=1234)
    parser.add_argument("--steps", type=int, default=100000)
    parser.add_argument("--gdb_cmd", default="make gdb")
    parser.add_argument("--qemu_cmd", default="make debug")
    parser.add_argument("--kill_port_first", action="store_true")
    parser.add_argument("--no_color", action="store_true")
    args = parser.parse_args()

    ws = os.path.abspath(args.workspace)
    os.makedirs(ws, exist_ok=True)

    qemu_log_path = os.path.join(ws, "qemu.log")
    gdb_transcript_path = os.path.join(ws, "gdb_transcript.log")
    gdb_steps_path = os.path.join(ws, "gdb_steps.log")

    if args.kill_port_first:
        try:
            subprocess.run(f"fuser -k {args.port}/tcp", shell=True, check=False)
        except Exception:
            subprocess.run(f"lsof -ti :{args.port} | xargs -r kill -9", shell=True, check=False)

    qemu_log = open(qemu_log_path, "w", buffering=1)
    qemu_proc = subprocess.Popen(
        args.qemu_cmd,
        cwd=ws,
        shell=True,
        stdout=qemu_log,
        stderr=subprocess.STDOUT,
        preexec_fn=os.setsid,   
    )
    if not wait_port("127.0.0.1", args.port, timeout_s=60):
        try:
            os.killpg(os.getpgid(qemu_proc.pid), signal.SIGTERM)
        except Exception:
            pass
        qemu_log.close()
        sys.exit(1)
    gdb_cmd = args.gdb_cmd
    if args.no_color:
        gdb_cmd += " -ex 'set style enabled off'"
    gdb_transcript = open(gdb_transcript_path, "w", buffering=1)
    gdb_steps = open(gdb_steps_path, "w", buffering=1)

    child = pexpect.spawn(
        f"bash -lc \"{gdb_cmd}\"",
        cwd=ws,
        encoding="utf-8",
        timeout=10,
        maxread=200_000,
        logfile=gdb_transcript, 
    )
    try:
        child.expect(r"\(gdb\)\s*")
    except pexpect.TIMEOUT:
        raise

    for c in ("set pagination off", "set disassemble-next-line on"):
        child.sendline(c)
        child.expect(r"\(gdb\)\s*")
    def gdb_run_and_capture(cmd: str) -> str:
        child.sendline(cmd)
        child.expect(r"\(gdb\)\s*")
        return child.before 

   
    try:
        for i in range(1, args.steps + 1):
            dis = gdb_run_and_capture("x/i $pc")
            child.sendline("si")
            child.expect(r"\(gdb\)\s*", timeout=10)
            si_out = child.before

    except KeyboardInterrupt:
        print("\n")
    except Exception as e:
        print(f"[ERROR] 单步过程中出错：{e}", file=sys.stderr)
    finally:
        # 关闭 GDB
        try:
            child.sendline("detach")
            child.expect(r"\(gdb\)\s*", timeout=3)
        except Exception:
            pass
        try:
            child.sendline("quit")
            child.close(force=True)
        except Exception:
            pass
        gdb_transcript.close()
        try:
            os.killpg(os.getpgid(qemu_proc.pid), signal.SIGTERM)
        except Exception:
            pass
        qemu_log.flush()
        qemu_log.close()

if __name__ == "__main__":
    main()
```

虽然分析了100000条的数据，但是查看log分析不出来有效的信息，汇编指令发现在一直跳转，推测为初始化步骤。

# 知识点总结

## 重要知识点

本实验主要涉及 RISC-V 启动过程和内核初始化的关键机制，具体包括以下几个方面：

**1. RISC-V 启动地址与初始指令执行流程**  RISC-V CPU 在加电复位后，会从固定的物理地址 0x1000 开始执行指令。  从 0x1000 到 0x1010 的这几条指令主要完成了以下功能：

* 利用 `auipc` 和 `addi` 计算基地址和偏移，用于定位内核入口地址；
* 通过 `csrr a0, mhartid` 读取当前 hart ID，确定是哪个 CPU 核心；
* 使用 `ld` 从内存中加载内核入口地址；
* 最后用 `jr` 跳转到 0x80000000，将控制权交给 OpenSBI 或内核启动代码。

**2. 栈的初始化与内核入口跳转**  在进入内核之前，需要先设置好内核栈。 `la sp, bootstacktop` 指令将内核预留的栈顶地址加载到栈指针寄存器 sp 中，为内核 C 代码的运行准备好基本环境。  随后，使用 `tail kern_init`（伪指令，实际是跳转）进入内核的 `kern_init` 函数，开始进行进一步的初始化工作。

**3. GDB 调试的使用**  本实验通过 QEMU + GDB 对启动流程进行了精确的跟踪和验证。  常用的调试命令包括：

* `b *0x1000`：在指定地址打断点；
* `si`：单步执行一条指令；
* `x/10i $pc`：查看当前 PC 附近的汇编指令；
* `watch *0x地址`：观察内存地址的变化。  通过这些命令，可以清晰地看到从复位向量到内核入口的完整执行路径。

**4. 汇编伪指令与实际指令的对应关系**  实验中看到 `la`、`tail` 等伪指令在反汇编时会被展开成多条实际机器指令（如 `auipc`、`mv`、`j` 等）。  这说明汇编伪指令只是编程时的简化写法，实际执行时依然是底层的基本指令。

**5. 固定的内核加载地址**  实验中内核被放置在物理地址 0x80200000 处，通过跳转进入内核入口 `kern_entry`，完成从启动阶段到内核运行阶段的切换。  这是 RISC-V 平台上一种常见的固定加载布局，方便在早期没有分页机制的情况下进行跳转。

---

## 额外知识点

本实验聚焦在从 0x1000 到内核入口的基本启动流程，一些更深入的内容虽然没有直接涉及，但对于理解整个启动过程非常重要：

**1. OpenSBI 的工作内容**  从 0x80000000 到 0x80200000 的这段空间通常由 OpenSBI 占用。  OpenSBI 会进行底层初始化工作，包括：重定位、清空寄存器、清除 bss 段、设置栈、读取设备树、完成硬件信息传递等，为内核提供标准的运行环境。

**2. QEMU 的架构背景**  本实验使用 QEMU 来模拟 RISC-V 硬件。  QEMU 是一个开源的虚拟机和硬件模拟器，能够模拟多种架构。  它分为两层：

* 上层是虚拟机管理器，负责虚拟机的创建、启动、暂停、删除等；
* 下层是执行器，模拟实际的 CPU、内存和外设。  通过这种方式，实验可以在没有真实 RISC-V 硬件的情况下，对内核启动过程进行完整的调试和验证。

---

