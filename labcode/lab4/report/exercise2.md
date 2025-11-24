# Lab4 Exercise2: 实现 do_fork 函数

## 一、实验目的

完成 `kern/process/proc.c` 中的 `do_fork` 函数，实现内核线程的创建机制。

## 二、背景知识

### 2.1 内核线程创建流程

创建一个内核线程需要分配和设置好很多资源：

1. **进程控制块 (PCB)**：记录进程的必要信息
2. **内核栈 (Kernel Stack)**：用于内核态执行时的函数调用和局部变量
3. **上下文 (Context)**：保存进程切换时的寄存器状态
4. **中断帧 (Trapframe)**：保存进程的执行现场

### 2.2 函数调用关系

```
kernel_thread()
    └─> do_fork()
            ├─> alloc_proc()      // 分配并初始化 PCB
            ├─> setup_kstack()    // 分配内核栈
            ├─> copy_mm()         // 复制/共享内存管理信息
            ├─> copy_thread()     // 设置中断帧和上下文
            ├─> hash_proc()       // 加入进程哈希表
            ├─> list_add()        // 加入进程链表
            └─> (设置为 RUNNABLE) // 唤醒新进程
```

### 2.3 do_fork 的作用

`do_fork` 创建当前内核线程的一个副本。对于内核线程来说，需要"fork"的核心资源是：
- **内核栈 (kstack)**：每个线程独立的内核栈
- **中断帧 (trapframe)**：保存线程的执行状态

## 三、实现步骤

### 3.1 函数签名

```c
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
```

**参数说明：**
- `clone_flags`：标志位，用于指导如何克隆子进程（如 `CLONE_VM` 表示共享内存）
- `stack`：父进程的用户栈指针（如果为 0，表示创建内核线程）
- `tf`：中断帧信息，将被复制到子进程的 `proc->tf`

### 3.2 详细实现步骤

#### 步骤 1：调用 alloc_proc 分配进程控制块

```c
proc = alloc_proc();
if(proc == NULL)
{
    goto fork_out;  // 分配失败，返回 -E_NO_MEM
}
```

**说明：**
- `alloc_proc()` 分配一块内存用于存储 `proc_struct`
- 初始化进程的基本字段（state、pid、kstack 等）
- 如果分配失败，跳转到错误处理

#### 步骤 2：为进程分配内核栈

```c
if(setup_kstack(proc) < 0)
{
    goto bad_fork_cleanup_proc;  // 失败则释放 proc_struct
}
```

**说明：**
- `setup_kstack()` 调用 `alloc_pages(KSTACKPAGE)` 分配物理页
- 通常分配 2 页（8KB）作为内核栈
- 将物理地址转换为虚拟地址并存储在 `proc->kstack`
- 失败时需要释放已分配的 `proc_struct`

#### 步骤 3：复制内存管理信息

```c
if(copy_mm(clone_flags, proc) < 0)
{
    goto bad_fork_cleanup_kstack;  // 失败则释放内核栈和 proc_struct
}
```

**说明：**
- 对于内核线程，`current->mm == NULL`，所以这一步实际上什么都不做
- 对于用户进程，如果 `clone_flags & CLONE_VM`，则共享内存；否则复制内存
- 失败时需要释放已分配的内核栈和 `proc_struct`

#### 步骤 4：设置中断帧和上下文

```c
copy_thread(proc, stack, tf);
```

**说明：**
- 在内核栈顶预留 `trapframe` 的空间
- 将父进程的 `trapframe` 复制到子进程
- 设置子进程的返回值 `a0 = 0`（标识这是子进程）
- 设置上下文：
  - `proc->context.ra = forkret`：第一次调度时的入口点
  - `proc->context.sp = proc->tf`：上下文栈指针指向中断帧

#### 步骤 5：将新进程加入进程管理结构

```c
bool intr_flag;
local_intr_save(intr_flag);  // 关闭中断，进入临界区
{
    proc->parent = current;           // 设置父进程
    proc->pid = get_pid();            // 分配唯一的进程 ID
    hash_proc(proc);                  // 加入进程哈希表（根据 pid 快速查找）
    list_add(&proc_list, &proc->list_link);  // 加入全局进程链表
    nr_process++;                     // 进程总数加 1
    proc->state = PROC_RUNNABLE;      // 设置为可运行状态（唤醒）
}
local_intr_restore(intr_flag);  // 恢复中断
```

**说明：**
- **为什么需要关闭中断？**
  - 这些操作涉及全局数据结构（`proc_list`、`hash_list`、`nr_process`）
  - 如果在操作过程中发生中断，调度器可能访问到不一致的状态
  - 使用 `local_intr_save/restore` 构成**临界区**，保证原子性
  
- **`hash_proc(proc)`**：将进程加入哈希表，方便 `find_proc(pid)` 快速查找
  
- **`list_add(&proc_list, &proc->list_link)`**：将进程加入全局链表
  - 注意：这里使用 `list_add` 而不是 `list_add_tail`
  - 将新进程加到链表头部，下次调度时能更快被选中
  
- **`nr_process++`**：全局进程计数器加 1
  
- **直接设置 `proc->state = PROC_RUNNABLE`** 而不是调用 `wakeup_proc()`
  - 原因：`wakeup_proc()` 有断言检查 `assert(proc->state != PROC_RUNNABLE)`
  - 新创建的进程状态是 `PROC_UNINIT`，可以直接设置为 `PROC_RUNNABLE`

#### 步骤 6：返回新进程的 PID

```c
ret = proc->pid;
```

**说明：**
- 父进程的返回值是子进程的 PID
- 子进程的返回值是 0（在 `copy_thread` 中设置）

### 3.3 错误处理

```c
fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);      // 释放内核栈
bad_fork_cleanup_proc:
    kfree(proc);           // 释放进程控制块
    goto fork_out;
```

**说明：**
- 使用 `goto` 实现多级错误处理，避免资源泄漏
- 遵循"谁分配谁释放"的原则

## 四、完整代码实现

```c
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    
    // 检查进程数是否超限
    if (nr_process >= MAX_PROCESS)
    {
        goto fork_out;
    }
    
    ret = -E_NO_MEM;  // 默认返回内存不足错误
    
    // 1. 调用 alloc_proc 分配进程控制块
    proc = alloc_proc();
    if(proc == NULL)
    {
        goto fork_out;
    }

    // 2. 为进程分配内核栈
    if(setup_kstack(proc) < 0)
    {
        goto bad_fork_cleanup_proc;
    }

    // 3. 复制内存管理信息（内核线程不需要）
    if(copy_mm(clone_flags, proc) < 0)
    {
        goto bad_fork_cleanup_kstack;
    }

    // 4. 设置中断帧和上下文
    copy_thread(proc, stack, tf);
    
    // 5. 将新进程加入进程管理结构（临界区）
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->parent = current;           // 设置父进程
        proc->pid = get_pid();            // 分配进程 ID
        hash_proc(proc);                  // 加入哈希表
        list_add(&proc_list, &proc->list_link);  // 加入进程链表
        nr_process++;                     // 进程计数加 1
        proc->state = PROC_RUNNABLE;      // 唤醒进程
    }
    local_intr_restore(intr_flag);
    
    // 6. 返回新进程的 PID
    ret = proc->pid;

fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
```

## 五、关键技术点

### 5.1 中断保护的必要性

在修改全局数据结构时必须关闭中断：

```c
bool intr_flag;
local_intr_save(intr_flag);     // 保存中断状态并关闭中断
{
    // 临界区：操作全局数据结构
    proc->pid = get_pid();
    hash_proc(proc);
    list_add(&proc_list, &proc->list_link);
    nr_process++;
    proc->state = PROC_RUNNABLE;
}
local_intr_restore(intr_flag);  // 恢复中断状态
```

**原因：**
- 如果不关闭中断，时钟中断可能触发调度器 `schedule()`
- 调度器会遍历 `proc_list`，可能访问到尚未完全初始化的进程
- 导致系统崩溃或产生不可预测的行为

### 5.2 为什么不使用 wakeup_proc()

观察 `wakeup_proc()` 的实现：

```c
void wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
    proc->state = PROC_RUNNABLE;
}
```

**问题：**
- `wakeup_proc()` 断言进程状态不是 `PROC_RUNNABLE`
- 它设计用于唤醒处于 `PROC_SLEEPING` 状态的进程
- 新创建的进程状态是 `PROC_UNINIT`，可以直接设置为 `PROC_RUNNABLE`

**结论：**
直接设置 `proc->state = PROC_RUNNABLE` 更加简洁高效。

### 5.3 进程创建后的执行流程

新进程第一次被调度执行时的流程：

```
schedule() 选中新进程
    ↓
proc_run(new_proc)
    ↓
switch_to(&old->context, &new->context)  // 上下文切换
    ↓
恢复 new->context.ra 和 new->context.sp
    ↓
返回到 forkret (因为 context.ra = forkret)
    ↓
forkret() 调用 forkrets(current->tf)
    ↓
__trapret 恢复中断帧
    ↓
sret 指令返回
    ↓
跳转到 tf->epc (对于内核线程是 kernel_thread_entry)
    ↓
kernel_thread_entry 调用实际的线程函数
```

这些知识为后续实现用户进程、进程调度算法等功能奠定了坚实的基础。

## 六、实验实现过程简要说明

在本实验中，我按照实验指导给出的步骤，在 `kern/process/proc.c` 中完成了 `do_fork` 函数，用于真正创建新的内核线程。整体思路是：以当前内核线程为模板，只为新线程分配必要的资源（PCB、内核栈、trapframe、上下文），并把它纳入系统的进程管理结构，最后返回新线程的 pid。具体处理如下：

### 6.1 调用 `alloc_proc` 分配 PCB

首先调用 `alloc_proc()`，在内核堆上分配并初始化一个 `struct proc_struct`，作为新线程的 PCB。这里仅获得了一块记录进程信息的内存（`state`、`pid` 等字段被初始化），还没有分配栈等资源。若分配失败，直接返回错误码。

### 6.2 为进程分配内核栈
成功获得 PCB 后，调用 `setup_kstack(proc)`，通过页分配器为新线程分配若干页内存作为内核栈，并将其虚拟地址写入 `proc->kstack`。如果这一阶段失败，就释放已经分配的 PCB，避免内存泄露。

### 6.3 复制内存管理信息

然后调用 `copy_mm(clone_flags, proc)`。在当前实验中我们只创建内核线程，`current->mm == NULL`，所以 `copy_mm` 实际上不做任何复制工作，只做断言检查并返回 0。保留这一步是为了后续扩展到用户进程时能直接复用。

### 6.4 复制上下文与中断帧
接着调用 `copy_thread(proc, stack, tf)`：
- 在新进程的内核栈顶预留一块空间，放置 `struct trapframe`，并令 `proc->tf` 指向这块空间
- 将父线程传入的 `*tf` 复制到子线程的 `trapframe` 中
- 把子线程 `tf->gpr.a0` 设为 0，使子线程在恢复 trapframe 后看到的返回值为 0，从而和父线程区分开
- 根据 `stack` 参数设置子线程的栈指针（内核线程时为 0，此时直接使用 `proc->tf` 作为初始栈顶）
- 设置子线程的上下文：`proc->context.ra = forkret`，`proc->context.sp = proc->tf`，以便第一次被调度时从 `forkret` 开始执行、并通过 `trapframe` 进入真正的线程入口函数

### 6.5 将新进程加入进程列表并设置为 RUNNABLE

修改全局进程管理结构时，通过 `local_intr_save/restore` 关闭中断，构造临界区：
- `proc->parent = current;` 记录父子关系
- `proc->pid = get_pid();` 为新线程分配一个进程号
- `hash_proc(proc);` 将新进程插入以 pid 为键的哈希表，便于后续通过 `find_proc` 快速查找
- `list_add(&proc_list, &proc->list_link);` 将新进程挂入全局进程链表
- `nr_process++;` 全局进程计数加一
- 将 `proc->state` 从 `PROC_UNINIT` 改为 `PROC_RUNNABLE`，表示该线程已经准备好被调度器选择执行

这样就完成了"把新线程正式纳入内核调度管理"的所有必要操作。

### 6.6 返回新进程号

最后，将 `ret` 设为 `proc->pid` 作为 `do_fork` 的返回值。对于调用 `do_fork` 的父线程来说，返回的是子线程的 pid；对子线程来说，恢复现场后看到的返回值是 0（在 `copy_thread` 中已经设置）。

综上，`do_fork` 完成了"为新创建的内核线程分配资源（PCB、内核栈、trapframe、context）并将其加入调度体系"的全部工作，符合实验给出的流程要求。

## 七、问题回答：ucore 是否做到给每个新 fork 的线程一个唯一的 id？

### 结论

**做到了，在当前系统的活动进程集合内，pid 是唯一的。**

### 分析与理由

#### 1. 统一通过 `get_pid()` 分配 pid

在 `do_fork` 中，新线程的 pid 不是随意赋值，而是统一由 `get_pid()` 生成：

```c
proc->pid = get_pid();
```

`get_pid()` 内部维护了静态变量 `last_pid` 和 `next_safe`，每次调用时会：
- 先自增 `last_pid`，必要时从 1 重新开始
- 遍历当前 `proc_list` 中所有已存在的进程，检查是否有与 `last_pid` 相同的 pid
  - 如果冲突，就继续自增 `last_pid` 并重新检查
  - 同时利用 `next_safe` 记录一个"当前扫描中可安全使用的 pid 上界"，减少重复遍历

只有在确认没有任何现存进程使用该 pid 后，`get_pid()` 才返回它。

#### 2. pid 可能被重用，但不会与"在运行的进程"冲突

当 `last_pid` 增加到一定程度（例如达到 `MAX_PID`）时，它会回绕到 1，并再次在当前进程集合中查找"空闲的 pid"。

- 对于已经完全退出并被回收的进程，其 pid 将不再出现在 `proc_list` 中，因此将来可能被重用
- 对于仍然存在的进程（包括就绪、运行、睡眠、僵尸但未回收），它们的 pid 会阻止 `get_pid()` 分配相同的值

因此，从"当前所有存活进程"的视角看，它们的 pid 始终互不相同。

#### 3. 与全局结构一致配合

新分配的 pid 会同时被：
- 写入 `proc->pid`
- 用于将该进程插入 `hash_list`（`hash_proc`）和 `proc_list`

后续 `find_proc(pid)` 通过哈希表 + 线性扫描链表，并再次比较 `proc->pid == pid` 来精确匹配，保证不会因为哈希冲突而混淆不同进程。

#### 4. 总结

综合以上分析，可以认为：
- **在任何时刻，系统中所有活动的线程/进程，其 pid 在集合内都是唯一的**
- pid 在时间轴上可以被回收并重新分配，但不会与仍存在的旧进程冲突

因此，ucore 从 `get_pid()` 的实现和全局进程管理结构的使用来看，确实达到了"给每个新 fork 的线程一个唯一 id（在当前系统内唯一）"的设计目标。
