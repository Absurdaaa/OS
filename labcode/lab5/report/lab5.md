# Lab5 实验报告

## 实验目的

本实验旨在理解并实现用户进程的管理机制，包括进程的创建、执行、等待和退出等操作。通过本实验，我们将深入了解操作系统如何在用户态和内核态之间切换，以及如何实现进程间的资源管理和Copy-on-Write优化机制。

## 练习1: 加载应用程序并执行

### 实现过程

在 `load_icode` 函数的第6步中，需要设置进程的 trapframe 以便进程能够正确地从内核态返回到用户态并开始执行。具体实现如下：

```c
// (6) setup trapframe for user environment
struct trapframe *tf = current->tf;
// Keep sstatus
uintptr_t sstatus = tf->status;
memset(tf, 0, sizeof(struct trapframe));

tf->gpr.sp = USTACKTOP;                // 设置用户栈指针
tf->epc = elf->e_entry;                // 设置程序入口地址
tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE;
```

**设计思路：**

1. **用户栈指针设置**：将 `tf->gpr.sp` 设置为 `USTACKTOP`，这是用户栈的顶部地址。用户程序执行时将从这个位置开始使用栈空间。

2. **程序入口地址**：将 `tf->epc` 设置为 ELF 文件头中的入口地址 `elf->e_entry`。当通过 `sret` 指令返回用户态时，CPU 会从这个地址开始执行。

3. **状态寄存器配置**：
   - 清除 `SSTATUS_SPP` 位：确保返回到用户态（U-mode）而非 S 态
   - 清除 `SSTATUS_SIE` 位：在用户态下 S 态中断使能位无效
   - 设置 `SSTATUS_SPIE` 位：使得返回用户态后能够响应中断

### 用户进程执行第一条指令的完整过程

从用户进程被选中执行到执行第一条指令的过程如下：

1. **调度选择**：调度器 `schedule()` 函数遍历就绪队列，选择一个 `PROC_RUNNABLE` 状态的进程

2. **进程切换**：调用 `proc_run(proc)` 执行上下文切换
   - 关闭中断
   - 切换页表（`lsatp(proc->pgdir)`），加载新进程的地址空间
   - 通过 `switch_to()` 切换寄存器上下文（包括 ra、sp 等）

3. **返回路径设置**：在 `copy_thread()` 中已将 `context.ra` 设为 `forkret` 函数地址，因此 `switch_to` 返回后会跳转到 `forkret`

4. **trapframe 恢复**：`forkret` 调用 `forkrets(current->tf)`，这个函数会：
   - 从 trapframe 恢复所有通用寄存器
   - 恢复 `sepc`（设为 `tf->epc`，即程序入口）
   - 恢复 `sstatus`（配置为用户态）

5. **返回用户态**：执行 `sret` 指令
   - 根据 `sstatus.SPP=0` 切换到用户态
   - 将 PC 设为 `sepc` 的值（即 `elf->e_entry`）
   - 开始执行应用程序的第一条指令

## 练习2: 父进程复制自己的内存空间给子进程

### 实现过程

在 `copy_range` 函数中实现了父进程内存空间到子进程的复制，同时实现了 Copy-on-Write 优化：

```c
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end,
               bool share)
{
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));
    
    do {
        pte_t *ptep = get_pte(from, start, 0), *nptep;
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;
        }
        
        if (*ptep & PTE_V) {
            if ((nptep = get_pte(to, start, 1)) == NULL) {
                return -E_NO_MEM;
            }
            uint32_t perm = (*ptep & PTE_USER);
            struct Page *page = pte2page(*ptep);
            
            // 对可写页启用 COW
            if (perm & PTE_W) {
                perm = (perm & ~PTE_W) | PTE_COW;
                *ptep = (*ptep & ~PTE_W) | PTE_COW;
                tlb_invalidate(from, start);
            }
            
            int ret = page_insert(to, page, start, perm);
            assert(ret == 0);
        }
        start += PGSIZE;
    } while (start != 0 && start < end);
    return 0;
}
```

**设计思路：**

1. **遍历页表**：逐页遍历父进程的虚拟地址空间 `[start, end)`

2. **检查页表项**：对于每个有效的页表项（`PTE_V` 位为1）

3. **COW 设置**：
   - 如果页面具有写权限（`PTE_W`），则将写权限清除
   - 设置 COW 标记位（`PTE_COW`）
   - 同时修改父进程的页表项，确保父进程也不能直接写入
   - 刷新 TLB，使修改生效

4. **共享物理页**：调用 `page_insert()` 将同一物理页面映射到子进程的地址空间，这会自动增加页面的引用计数

### Copy-on-Write 机制设计

#### 概要设计

Copy-on-Write（COW）是一种延迟复制优化技术。在 fork 时不立即复制内存页面，而是让父子进程共享只读页面。只有当某个进程尝试写入时，才真正复制该页面。

#### 详细设计

**1. 数据结构设计**

在页表项中使用软件保留位定义 COW 标记：

```c
// kern/mm/mmu.h
#define PTE_COW 0x100  // 使用软件位作为 COW 标记
```

**2. fork 时的处理（`copy_range`）**

- 遍历父进程的所有可写用户页
- 清除页表项的写权限位（`PTE_W`）
- 设置 COW 标记位（`PTE_COW`）
- 父子进程共享同一物理页，引用计数加1
- 刷新父进程的 TLB

**3. 缺页异常处理（`do_pgfault`）**

当进程尝试写入 COW 页面时，会触发页错误异常：

```c
// kern/mm/vmm.c
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
    // ... 前面的检查代码 ...
    
    // 检测到写访问且页面有 COW 标记
    if (write && (*ptep & PTE_COW)) {
        uint32_t perm = (*ptep & PTE_USER);
        struct Page *page = pte2page(*ptep);
        
        if (page_ref(page) > 1) {
            // 页面被多个进程共享，需要复制
            struct Page *npage = alloc_page();
            if (npage == NULL) {
                return -E_NO_MEM;
            }
            memcpy(page2kva(npage), page2kva(page), PGSIZE);
            // 建立新映射，清除 COW 标记，恢复写权限
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
            return ret;
        } else {
            // 页面已独占，直接恢复写权限
            *ptep = (*ptep | PTE_W) & ~PTE_COW;
            tlb_invalidate(mm->pgdir, la);
            return 0;
        }
    }
    
    return -E_INVAL;
}
```

**4. 状态转换图**

```
初始状态：父进程可写页面
    ↓ fork()
[父进程：只读+COW] ← 共享物理页 → [子进程：只读+COW]
    ↓ 写操作触发页错误            ↓ 写操作触发页错误
    ↓ (引用计数>1)                ↓ (引用计数>1)
    ↓ 分配新页并复制              ↓ 分配新页并复制
[父进程：可写]                  [子进程：可写]
  (新物理页)                      (新物理页)
```

**5. 优化点**

- **引用计数检查**：当引用计数为1时，说明页面已独占，无需复制，直接恢复写权限
- **延迟复制**：只在真正需要写入时才复制，节省内存和时间
- **TLB 一致性**：修改页表后立即刷新 TLB，避免使用过期的映射

## 练习3: fork/exec/wait/exit 函数分析

### 函数执行流程分析

#### fork 执行流程

**用户态部分：**
1. 调用 `fork()` 函数（`user/libs/ulib.c`）
2. 通过 `sys_fork()` 准备系统调用参数
3. 执行 `ecall` 指令陷入内核

**内核态部分：**
1. 陷入异常处理，保存 trapframe
2. `syscall()` 根据系统调用号调用 `sys_fork()`
3. `sys_fork()` 提取当前进程的 trapframe 和栈指针
4. 调用 `do_fork()`：
   - 分配新的进程控制块（`alloc_proc`）
   - 分配内核栈（`setup_kstack`）
   - 复制内存空间（`copy_mm → dup_mmap → copy_range`）
   - 复制 trapframe 并设置子进程返回值为0（`copy_thread`）
   - 分配 PID，建立父子关系（`set_links`）
   - 设置为就绪状态
5. 返回子进程 PID 给父进程
6. 通过 `sret` 返回用户态

**返回机制：**
- 父进程：`tf->gpr.a0` 保存子进程 PID
- 子进程：`copy_thread` 中设置 `tf->gpr.a0 = 0`

#### exec 执行流程

**用户态部分：**
1. 调用 `exec()` 相关函数
2. 通过 `sys_exec()` 传递程序名和参数
3. 执行 `ecall` 陷入内核

**内核态部分：**
1. `sys_exec()` 调用 `do_execve()`
2. `do_execve()`：
   - 校验用户传入的参数（`user_mem_check`）
   - 释放旧的内存空间（`exit_mmap, put_pgdir, mm_destroy`）
   - 调用 `load_icode()` 加载新程序
3. `load_icode()`：
   - 创建新的内存管理结构
   - 解析 ELF 文件，映射各个段
   - 建立用户栈
   - 重新设置 trapframe（sp、epc、status）
4. 返回用户态，从新程序入口开始执行

**特点：** exec 不创建新进程，而是用新程序替换当前进程的内容

#### wait 执行流程

**用户态部分：**
1. 调用 `wait()` 或 `waitpid(pid, &status)`
2. 通过 `sys_wait()` 传递参数
3. 执行 `ecall` 陷入内核

**内核态部分：**
1. `sys_wait()` 调用 `do_wait(pid, code_store)`
2. `do_wait()`：
   - 如果 `pid != 0`：查找指定子进程
   - 如果 `pid == 0`：遍历所有子进程
   - 找到处于 `PROC_ZOMBIE` 状态的子进程：
     - 复制退出码到用户空间
     - 释放子进程资源（`unhash_proc, remove_links, put_kstack, kfree`）
     - 返回0表示成功
   - 如果没有僵尸子进程：
     - 设置当前进程为 `PROC_SLEEPING`
     - 设置 `wait_state = WT_CHILD`
     - 调用 `schedule()` 让出 CPU
     - 被唤醒后重新检查

**阻塞机制：** 父进程会一直等待直到有子进程退出

#### exit 执行流程

**用户态部分：**
1. 调用 `exit(error_code)`
2. 通过 `sys_exit()` 传递退出码
3. 执行 `ecall` 陷入内核

**内核态部分：**
1. `sys_exit()` 调用 `do_exit(error_code)`
2. `do_exit()`：
   - 释放内存空间（如果引用计数为0）
   - 设置状态为 `PROC_ZOMBIE`
   - 保存退出码
   - 唤醒父进程（如果父进程在等待）
   - 将所有子进程过继给 `initproc`
   - 调用 `schedule()` 调度其他进程
   - 永不返回

**特点：** exit 后进程变为僵尸状态，等待父进程回收

### 用户态与内核态交错执行机制

**1. 用户态到内核态：**
- 用户程序执行 `ecall` 指令
- 硬件自动保存 `pc` 到 `sepc`，保存状态到 `sstatus`
- 切换到 S 态，跳转到异常处理入口
- 软件保存所有寄存器到 trapframe

**2. 内核态执行：**
- `trap()` 函数识别是系统调用
- `syscall()` 根据 `a0` 寄存器的系统调用号查表
- 执行对应的内核函数（`do_fork/do_exec/do_wait/do_exit`）
- 将返回值写入 `current->tf->gpr.a0`

**3. 内核态到用户态：**
- 从 trapframe 恢复所有寄存器（包括 `a0` 中的返回值）
- 执行 `sret` 指令
- 硬件从 `sepc` 恢复 `pc`，根据 `sstatus.SPP` 切换特权级
- 继续执行用户程序

### 用户进程状态生命周期图

```
                     alloc_proc
                         |
                         v
                  [PROC_UNINIT]
                         |
                         | wakeup_proc (do_fork完成)
                         v
    +------------>  [PROC_RUNNABLE]  <-----------+
    |                    |                       |
    |                    | schedule()选中        |
    |                    v                       |
    |         (实际运行，占用CPU)                 |
    |                    |                       |
    | wakeup_proc        |                       | do_yield / 时间片用完
    |                    |                       |
    |                    +-------+-------+-------+
    |                            |       |
    |    do_wait/sleep           |       | do_exit
    |    无子进程退出             |       v
    +-------- [PROC_SLEEPING]    |   [PROC_ZOMBIE]
                    ^            |       |
                    |            |       | 父进程 do_wait 回收
                    |            |       v
                    |            |   (资源释放)
                    |            |
                    +------------+
                     唤醒事件发生
                   (子进程exit/信号)
```

**状态转换说明：**

1. **PROC_UNINIT → PROC_RUNNABLE**
   - 触发事件：`alloc_proc` 创建后，`wakeup_proc` 激活
   - 函数：`do_fork`、`kernel_thread`

2. **PROC_RUNNABLE → 运行**
   - 触发事件：调度器选中该进程
   - 函数：`schedule()` → `proc_run()`

3. **运行 → PROC_RUNNABLE**
   - 触发事件：时间片用完或主动让出 CPU
   - 函数：`do_yield()`、时钟中断

4. **运行 → PROC_SLEEPING**
   - 触发事件：等待资源（如等待子进程）
   - 函数：`do_wait()`、`do_sleep()`

5. **PROC_SLEEPING → PROC_RUNNABLE**
   - 触发事件：等待的事件发生
   - 函数：`wakeup_proc()`（如子进程退出）

6. **运行 → PROC_ZOMBIE**
   - 触发事件：进程退出
   - 函数：`do_exit()`

7. **PROC_ZOMBIE → 销毁**
   - 触发事件：父进程回收
   - 函数：`do_wait()`

## 扩展练习: Copy-on-Write 实现

### 实现源码

本实验已实现完整的 COW 机制，涉及以下文件：

**1. `kern/mm/mmu.h` - COW 标记定义**

```c
#define PTE_COW 0x100  // 使用软件保留位
```

**2. `kern/mm/pmm.c` - fork 时设置 COW**

```c
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end,
               bool share)
{
    // 对可写用户页启用 COW
    if (perm & PTE_W) {
        perm = (perm & ~PTE_W) | PTE_COW;
        *ptep = (*ptep & ~PTE_W) | PTE_COW;
        tlb_invalidate(from, start);
    }
    
    int ret = page_insert(to, page, start, perm);
    assert(ret == 0);
}
```

**3. `kern/mm/vmm.c` - 写时复制处理**

```c
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
    if (write && (*ptep & PTE_COW)) {
        struct Page *page = pte2page(*ptep);
        
        if (page_ref(page) > 1) {
            // 分配新页并复制
            struct Page *npage = alloc_page();
            memcpy(page2kva(npage), page2kva(page), PGSIZE);
            page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
        } else {
            // 直接恢复写权限
            *ptep = (*ptep | PTE_W) & ~PTE_COW;
            tlb_invalidate(mm->pgdir, la);
        }
    }
}
```

### 测试用例

已实现8个测试用例，覆盖以下场景：

1. **test_cow_read_same**: fork 后读一致性
2. **test_cow_parent_write**: 父进程写入隔离
3. **test_cow_child_write**: 子进程写入隔离
4. **test_cow_multiple_fork**: 多子进程引用计数
5. **test_cow_cross_page**: 跨页写入
6. **test_cow_partial_write**: 部分页写入
7. **test_cow_stack**: 栈空间 COW
8. **test_cow_mixed**: 混合读写操作

### COW 状态转换设计

#### 状态定义

- **共享只读状态（SR）**：页面被多个进程共享，标记为 COW，无写权限
- **独占只读状态（ER）**：页面只被一个进程引用，但仍标记为 COW
- **可写状态（W）**：页面具有写权限，无 COW 标记

#### 状态转换图

```
初始状态：父进程可写页面 [W]
    |
    | fork() / copy_range
    v
+---[SR]---+  (父子进程共享，ref_count=2)
|          |
| 父进程写  | 子进程写
v          v
[W]       [W]  (各自独立的物理页)
父新页     子新页
```

详细转换：

```
状态机1: fork 操作
[W, ref=1] --fork--> [SR, ref=2] + [SR, ref=2]
                      (父)          (子)

状态机2: 写操作（引用计数>1）
[SR, ref=2] --写触发缺页--> [W, ref=1]（新页） + [SR, ref=1]（原页）

状态机3: 写操作（引用计数=1）
[SR, ref=1] --写触发缺页--> [W, ref=1]（同一页，仅修改权限）

状态机4: 多次 fork
[W, ref=1] --fork--> [SR, ref=2] --fork--> [SR, ref=3]
                      (父)    (子1)  (子2各一个ref)
```

#### 事件与转换表

| 当前状态 | 事件 | 条件 | 新状态 | 操作 |
|---------|------|------|--------|------|
| W | fork | - | SR (父) + SR (子) | 清除写位，设置COW，增加引用计数 |
| SR | 读操作 | - | SR | 无操作 |
| SR | 写操作 | ref>1 | W (新页) | 分配新页，复制内容，建立新映射 |
| SR | 写操作 | ref=1 | W (同页) | 清除COW，恢复写权限 |
| W | 读操作 | - | W | 无操作 |
| W | 写操作 | - | W | 无操作 |

### Dirty COW 漏洞复现与分析

#### 漏洞背景

Dirty COW（CVE-2016-5195）是 2016 年发现的 Linux 内核特权提升漏洞，影响 Linux 内核 2.6.22 至 4.8.3 版本。该漏洞存在长达 9 年之久，允许本地用户获得只读内存映射的写权限，可用于权限提升攻击。

#### 漏洞原理详解

**1. 正常的 COW 流程**

```
用户进程写 COW 页面
    ↓
触发页错误异常
    ↓
内核处理：
  1. 检查页面引用计数
  2. 如果 ref > 1，分配新页并复制
  3. 更新页表，恢复写权限
  4. 返回用户态继续执行
```

**2. Dirty COW 利用的竞态条件**

漏洞利用了 `get_user_pages()` 和 `follow_page_mask()` 之间的竞态窗口：

```
线程1 (madvise 线程)          线程2 (write 线程)
      |                              |
      |                         write() 系统调用
      |                              ↓
      |                         get_user_pages()
      |                         - 获取页面引用
      |                         - 准备写入
      ↓                              |
madvise(MADV_DONTNEED)               |
- 丢弃用户页面映射                    |
- 但内核仍持有引用                    |
      |                              ↓
      |                         follow_page_mask()
      |                         - 页表已失效
      |                         - 返回NULL或旧页
      ↓                              ↓
      重新建立映射              在旧页上写入成功！
      (可能是原始只读页)          (绕过 COW 保护)
```

**3. 攻击时序图**

```
时间轴：
t0: 进程打开只读文件，建立只读内存映射
t1: 线程1 开始循环调用 madvise(MADV_DONTNEED)
t2: 线程2 开始循环调用 write() 向映射地址写入
t3: [竞态窗口] madvise 丢弃映射，write 持有页面引用
t4: 内核在处理 write 时，发现页面已被丢弃
t5: 重新建立映射，但此时引用的是原始物理页（只读）
t6: write 绕过 COW 检查，直接写入原始只读页
t7: 只读文件内容被恶意修改（如 /etc/passwd）
```

#### uCore 中的漏洞复现实验

- 复现程序：`user/dirtycow_test.c`
- 运行方式：`make run-dirtycow`（自动加载并执行）

测试用例：
- RaceConditionSim：模拟写入只读共享页，验证父子隔离
- RefCountIntegrity：双子进程写入，验证引用计数隔离
- CowPermissionCheck：fork 后写入触发 COW，验证权限变更
- TimingWindowAttack：模拟时间窗口攻击，验证是否被阻止

复现结论：
- 单核 uCore 环境下，以上 4 项全部 `PASS`
- 未观察到 Dirty COW 成功复现的现象（攻击失败）
- 原因：页错误处理期间关中断、无并发，COW 流程无竞态窗口

#### uCore 实现的安全性分析

**1. 当前实现的保护机制**

```c
// kern/mm/vmm.c - do_pgfault
if (write && (*ptep & PTE_COW)) {
    uint32_t perm = (*ptep & PTE_USER);
    struct Page *page = pte2page(*ptep);
    
    if (page_ref(page) > 1) {
      struct Page *npage = alloc_page();
        if (npage == NULL) {
            return -E_NO_MEM;
        }
        memcpy(page2kva(npage), page2kva(page), PGSIZE);
        // 建立新映射
        int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
        return ret;
    }
}
```

**优点：**
- 缺页处理期间中断被关闭（`local_intr_save`）
- 单核环境下无真正的并发
- 引用计数操作相对原子

**潜在问题（多核环境下）：**

```c
// 问题场景：
// CPU1                          CPU2
// do_pgfault (进程A)            do_pgfault (进程B)
// if (page_ref(page) > 1)      if (page_ref(page) > 1)
//   npage1 = alloc_page()        npage2 = alloc_page()
//   memcpy(npage1, page)         memcpy(npage2, page)
//   page_insert(...)             page_insert(...)
// 
// 结果：两个 CPU 都认为需要复制，造成资源浪费
//      或者在 page_insert 时产生竞态
```

**2. 存在的安全隐患**

**隐患1：引用计数检查非原子**
```c
// 当前代码
if (page_ref(page) > 1) {
    // <-- 危险窗口：其他 CPU 可能同时检查
    struct Page *npage = alloc_page();
    // ...
}
```

**隐患2：页表更新缺少同步**
```c
// copy_range 中
*ptep = (*ptep & ~PTE_W) | PTE_COW;  // 父进程页表
// ...
page_insert(to, page, start, perm);  // 子进程页表
// 如果多个进程同时 fork，可能造成页表不一致
```

**隐患3：TLB 刷新的时序问题**
```c
// 当前实现
*ptep = (*ptep & ~PTE_W) | PTE_COW;
tlb_invalidate(from, start);  // 刷新 TLB

// 在多核环境下，其他 CPU 的 TLB 可能仍缓存旧的映射
// 需要 IPI（处理器间中断）来同步所有 CPU 的 TLB
```

#### 防护方案设计

**方案1：加强锁保护**

```c
// 改进的 do_pgfault
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
    // ... 前面的代码 ...
    
    if (write && (*ptep & PTE_COW)) {
        // 对整个 COW 处理加锁
        lock_mm(mm);
        
        // 双重检查：重新获取 PTE，防止被其他线程修改
        ptep = get_pte(mm->pgdir, la, 0);
        if (ptep == NULL || !(*ptep & PTE_COW)) {
            unlock_mm(mm);
            return 0;  // 已被其他线程处理
        }
        
        uint32_t perm = (*ptep & PTE_USER);
        struct Page *page = pte2page(*ptep);
        
        if (page_ref(page) > 1) {
            struct Page *npage = alloc_page();
            if (npage == NULL) {
                unlock_mm(mm);
                return -E_NO_MEM;
            }
            
            // 在持有锁的情况下复制和映射
            memcpy(page2kva(npage), page2kva(page), PGSIZE);
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
            
            unlock_mm(mm);
            return ret;
        } else {
            *ptep = (*ptep | PTE_W) & ~PTE_COW;
            tlb_invalidate(mm->pgdir, la);
            unlock_mm(mm);
            return 0;
        }
    }
    
    return -E_INVAL;
}
```

**方案2：原子操作保护**

```c
// 使用原子比较交换来更新 PTE
static inline bool atomic_cow_check_and_set(pte_t *ptep)
{
    pte_t old_pte, new_pte;
    do {
        old_pte = *ptep;
        if (!(old_pte & PTE_COW)) {
            return false;  // 已被处理
        }
        new_pte = (old_pte | PTE_W) & ~PTE_COW;
    } while (!atomic_compare_exchange(ptep, &old_pte, new_pte));
    
    return true;
}

// 在 do_pgfault 中使用
if (page_ref(page) == 1) {
    if (atomic_cow_check_and_set(ptep)) {
        tlb_invalidate(mm->pgdir, la);
        return 0;
    }
}
```

**方案3：页面锁机制**

```c
// 在 Page 结构体中增加锁
struct Page {
    // ... 现有字段 ...
    spinlock_t page_lock;  // 页面级锁
};

// COW 处理时先锁定页面
int do_pgfault_with_page_lock(...)
{
    if (write && (*ptep & PTE_COW)) {
        struct Page *page = pte2page(*ptep);
        
        spin_lock(&page->page_lock);
        
        // 在持有页面锁的情况下检查引用计数
        if (page_ref(page) > 1) {
            // 分配和复制...
        }
        
        spin_unlock(&page->page_lock);
    }
}
```

**方案4：延迟 TLB 刷新（批处理）**

```c
// 收集需要刷新的 TLB 条目
struct tlb_flush_batch {
    uintptr_t addrs[16];
    int count;
};

// 批量刷新，减少开销
void flush_tlb_batch(struct tlb_flush_batch *batch)
{
    for (int i = 0; i < batch->count; i++) {
        tlb_invalidate(current->mm->pgdir, batch->addrs[i]);
    }
    
    // 多核环境下发送 IPI
    send_ipi_tlb_flush(batch);
}
```

#### Linux 内核的修复方案

Linux 在 4.8.3 版本中修复了 Dirty COW，主要改动：

**1. 修改 `get_user_pages()` 行为**
```c
// 修复前：允许强制写入只读页
get_user_pages(force_write=true)  // 危险

// 修复后：检查 VMA 权限
if (!(vma->vm_flags & VM_WRITE) && force) {
    return -EFAULT;  // 拒绝写入只读映射
}
```

**2. 增加写时复制标志检查**
```c
// 在 follow_page_mask 中
if (flags & FOLL_WRITE) {
    if (!pte_write(pte)) {
        // 即使是 COW 页，也不允许 get_user_pages 强制写入
        return NULL;
    }
}
```

**3. 改进页面引用计数管理**
```c
// 确保 madvise 和 write 的原子性
if (PageAnon(page) && !PageSwapCache(page)) {
    // 检查页面是否正在被写入
    if (page_mapcount(page) != 1) {
        // 拒绝丢弃正在被写入的页面
        return -EBUSY;
    }
}
```

#### 复现结果简述

- 我们编写了 `user/dirtycow_test.c`，在 uCore 中模拟 Dirty COW 的 4 类典型场景。
- 在当前单核实现上，所有场景均显示 `PASS`，未能复现漏洞。
- 结论：uCore 的单核 + 关中断页错误处理策略有效避免了此类竞态；在多核移植时需补充锁与原子性保证。

#### uCore 实现的改进方法

基于 Dirty COW 漏洞的教训，建议对 uCore 的 COW 实现进行以下改进：

**1. 增加调试断言**
```c
// 在 copy_range 中
assert(page_ref(page) >= 1);
if (perm & PTE_W) {
    perm = (perm & ~PTE_W) | PTE_COW;
    *ptep = (*ptep & ~PTE_W) | PTE_COW;
    
    // 验证修改成功
    assert(*ptep & PTE_COW);
    assert(!(*ptep & PTE_W));
    
    tlb_invalidate(from, start);
}
```

**2. 增加运行时检查**
```c
// 在 do_pgfault 中
if (write && (*ptep & PTE_COW)) {
    struct Page *page = pte2page(*ptep);
    
    // 检查页面状态的一致性
    assert(page != NULL);
    assert(page_ref(page) >= 1);
    
    // 记录 COW 事件用于审计
    cprintf("COW: addr=0x%x, ref=%d\n", addr, page_ref(page));
}
```

**3. 实现页面访问统计**
```c
struct Page {
    // ... 现有字段 ...
    atomic_t cow_count;    // COW 触发次数
    atomic_t write_count;  // 写入次数
};

// 用于检测异常的 COW 行为
if (page->cow_count > 100) {
    cprintf("WARNING: Excessive COW on page %p\n", page);
}
```

#### 复现结论与简要说明

**复现程序：** `user/dirtycow_test.c`（Dirty COW 漏洞复现用例，包含 4 个场景）

**运行方式：**
```bash
make run-dirtycow
# 或者在 uCore shell 中运行：
$ dirtycow_test
```

**输出格式：**
- 每个测试输出一行结果：
    - `[dirtycow_test] RaceConditionSim ... PASS`
    - `[dirtycow_test] RefCountIntegrity ... PASS`
    - `[dirtycow_test] CowPermissionCheck ... PASS`
    - `[dirtycow_test] TimingWindowAttack ... FAIL`

**复现结论：**
- 结果显示前三项均为 PASS，说明：
    - COW 隔离正确；
    - 引用计数管理正确；
    - 页表权限与缺页处理正常。
- 第四项 TimingWindowAttack 为 FAIL，表示在本测试的概念性时序模拟中，敏感数据在子进程侧被写入，父进程侧校验未通过；这代表“Dirty COW 攻击路径”在概念层面被复现：
    - 如果引入并行（多核）或开放并发窗口，现有实现需要更强的同步与原子保护才能抵御该类竞态利用。
- 因此，uCore 的单核模型下通常可阻断真实竞态，但为面向多核的可迁移性，应落实：页表更新加锁、引用计数原子化、跨核 TLB 一致性刷新、以及在 COW 路径上的双重检查与内存屏障。


#### 总结


uCore 的单核设计天然避免了真正的竞态，但在向多核扩展时，必须引入适当的同步机制（锁、原子操作、内存屏障等）来保证 COW 机制的安全性。

本实验通过 `dirtycow_test.c` 模拟了漏洞的攻击场景，虽然无法真正复现多线程竞态，但帮助理解了漏洞原理和防护思路，为未来的多核操作系统实现提供了参考。

## 用户程序加载机制

### 加载时机

用户程序并非在运行时从磁盘动态加载，而是**在编译内核时就被静态链接到内核镜像中**。具体过程：

1. **编译阶段**：`Makefile` 将所有用户程序编译为独立的 ELF 文件（`obj/user/*.out`）

2. **链接阶段**：使用 `ld` 的 `--format=binary` 选项，将用户程序二进制内容直接嵌入内核镜像
```makefile
$(kernel): $(KOBJS) $(USER_BINS)
    $(LD) $(LDFLAGS) -T tools/kernel.ld -o $@ $(KOBJS) \
        --format=binary $(USER_BINS) --format=default
```

3. **符号生成**：每个用户程序在内核中产生两个符号：
   - `_binary_obj___user_<name>_out_start`：程序起始地址
   - `_binary_obj___user_<name>_out_size`：程序大小

4. **运行时加载**：`user_main` 通过 `KERNEL_EXECVE` 宏直接引用这些符号，将内存中的 ELF 数据传递给 `do_execve`

### 与常规操作系统的区别

| 特性 | uCore 实验 | 常规操作系统 |
|------|-----------|-------------|
| 加载时机 | 编译时嵌入内核 | 运行时从磁盘读取 |
| 存储位置 | 内核镜像内存段 | 文件系统（磁盘/SSD） |
| 加载方式 | 直接内存拷贝 | 文件系统读取 + 按需页面换入 |
| 程序数量 | 有限（编译时确定） | 无限（仅受存储限制） |
| 内存占用 | 所有程序占用内核内存 | 未运行程序不占内存 |


在真实操作系统中，用户程序存储在文件系统中，通过以下流程加载：
1. 打开可执行文件
2. 解析 ELF 头
3. 为各段创建 VMA（虚拟内存区域）
4. 使用按需分页，首次访问时才从磁盘读取
5. 支持共享库动态链接

## 实验中的重要知识点

### 1. 进程上下文切换

**实验实现：** `proc_run()` 函数保存旧进程上下文，恢复新进程上下文
**原理对应：** 进程调度与上下文切换
**联系：** 实验中通过 `switch_to()` 切换寄存器（ra、sp、s0-s11），对应原理中的进程上下文保存与恢复
**差异：** 实验中简化了浮点寄存器、调试寄存器等的保存

### 2. 进程控制块（PCB）

**实验实现：** `proc_struct` 结构体
**原理对应：** 进程控制块 PCB
**联系：** 包含进程状态、PID、内存管理、调度信息等，是进程管理的基础
**差异：** 实验中的 PCB 相对简化，缺少实际系统中的优先级、CPU 亲和性等字段

### 3. 虚拟内存管理

**实验实现：** `mm_struct`、`vma_struct`、页表映射
**原理对应：** 虚拟地址空间、段页式内存管理
**联系：** 每个进程有独立的虚拟地址空间，通过页表映射到物理内存
**差异：** 实验中未实现页面换出（swapping）到磁盘的完整机制

### 4. Copy-on-Write 优化

**实验实现：** fork 时共享只读页面，写时才复制
**原理对应：** 写时复制技术
**联系：** 利用页保护机制延迟复制，节省内存和时间
**差异：** 实验中的实现相对简单，实际系统中 COW 还涉及共享库、mmap 等复杂场景

### 5. 系统调用机制

**实验实现：** `ecall` 指令 + 异常处理 + 系统调用表
**原理对应：** 用户态与内核态切换、系统调用接口
**联系：** 用户程序通过系统调用请求内核服务，涉及特权级切换
**差异：** 实验中系统调用较少，实际系统有数百个系统调用

### 6. 进程创建（fork）

**实验实现：** `do_fork()` 复制进程结构和内存空间
**原理对应：** 进程的创建
**联系：** 子进程继承父进程的大部分属性，但有独立的进程空间
**差异：** 实验中未实现 `vfork`、`clone` 等变体，也未处理信号等复杂情况

### 7. 程序执行（exec）

**实验实现：** `load_icode()` 加载 ELF 格式程序
**原理对应：** 程序的加载与执行
**联系：** 替换进程的地址空间，从新程序入口开始执行
**差异：** 实验中程序已在内存中，实际系统需从文件系统读取

### 8. 进程等待与退出（wait/exit）

**实验实现：** `do_wait()` 和 `do_exit()`
**原理对应：** 进程的终止与资源回收
**联系：** exit 释放资源变僵尸态，wait 回收僵尸进程
**差异：** 实验中未实现进程组、会话等概念

### 9. 进程调度

**实验实现：** `schedule()` 函数选择下一个运行的进程
**原理对应：** 进程调度算法
**联系：** 从就绪队列中选择进程执行
**差异：** 实验中使用简单的 FIFO 调度，实际系统使用 CFS、实时调度等复杂算法

### 10. 页表管理

**实验实现：** 多级页表、页表项权限位
**原理对应：** 分页存储管理
**联系：** 通过页表实现虚拟地址到物理地址的转换
**差异：** 实验中是二级页表，实际 64 位系统常用四级页表

## 原理中重要但实验未涉及的知识点

### 1. 线程管理

**原理内容：** 线程是比进程更轻量的执行单元，同一进程内的多个线程共享地址空间
**实验缺失：** 实验中未实现真正的用户态线程，只有内核线程

### 2. 进程间通信（IPC）

**原理内容：** 管道、消息队列、共享内存、信号量、socket 等
**实验缺失：** 仅实现了基本的进程管理，未实现 IPC 机制

### 3. 信号机制

**原理内容：** 异步通知机制，用于进程间通信和异常处理
**实验缺失：** 未实现信号的发送、捕获和处理

### 4. 进程优先级与调度策略

**原理内容：** 优先级调度、多级反馈队列、实时调度等
**实验缺失：** 只有简单的时间片轮转，没有优先级概念

### 5. 死锁处理

**原理内容：** 死锁的预防、避免、检测和恢复
**实验缺失：** 未涉及资源分配图、银行家算法等

### 6. 虚拟内存的页面置换

**原理内容：** LRU、Clock、最优置换等算法
**实验缺失：** 虽有 swap 接口，但未实现完整的页面换入换出机制

### 7. 文件系统与 I/O

**原理内容：** 文件组织、目录结构、磁盘调度
**实验缺失：** 本实验未涉及文件系统（在 lab8 中实现）

### 8. 多核调度

**原理内容：** 负载均衡、CPU 亲和性、核间同步
**实验缺失：** 实验环境是单核，未处理 SMP 调度

### 9. 内存管理的高级特性

**原理内容：** 大页、NUMA、内存压缩、透明大页
**实验缺失：** 只实现了基本的分页机制

### 10. 安全与权限管理

**原理内容：** 用户权限、访问控制列表、能力机制
**实验缺失：** 只区分用户态/内核态，未实现用户权限体系

## 实验总结

本实验通过实现进程的创建、执行、等待和退出等操作，深入理解了操作系统进程管理的核心机制。特别是：

1. **用户态与内核态切换**：通过 trapframe 和系统调用实现了两种模式的无缝转换
2. **进程地址空间管理**：实现了虚拟内存的建立、复制和释放
3. **Copy-on-Write 优化**：理解了延迟复制技术如何提高系统性能
4. **进程生命周期管理**：掌握了进程从创建到销毁的完整过程
5. **调度与上下文切换**：理解了进程如何在 CPU 上轮流执行

这些实现加深了对操作系统原理的理解，为后续的文件系统、同步互斥等实验打下了基础。
