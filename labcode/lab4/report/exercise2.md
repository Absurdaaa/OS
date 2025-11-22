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

## 六、测试与验证

### 6.1 编译测试

```bash
make clean
make
```

预期结果：编译成功，无错误。

### 6.2 运行测试

```bash
make qemu
```

预期输出应包含：
```
alloc_proc() correct!
this initproc, pid = 1, name = "init"
To U: "Hello world!!".
To U: "en.., Bye, Bye. :)"
```

说明 `do_fork` 成功创建了 `init` 进程（PID=1）。

## 七、常见问题与调试

### 7.1 问题：进程无法被调度执行

**可能原因：**
- 忘记设置 `proc->state = PROC_RUNNABLE`
- 忘记将进程加入 `proc_list`

**解决方案：**
检查是否完成步骤 5 的所有操作。

### 7.2 问题：系统崩溃或产生随机错误

**可能原因：**
- 没有关闭中断保护临界区
- 进程链表或哈希表操作不正确

**解决方案：**
确保使用 `local_intr_save/restore` 保护全局数据结构的修改。

### 7.3 问题：内存泄漏

**可能原因：**
- 错误处理路径中没有释放已分配的资源

**解决方案：**
检查所有 `goto` 跳转是否正确释放了资源。

## 八、总结

本实验完成了 `do_fork` 函数的实现，这是操作系统进程管理的核心功能之一。通过本实验：

1. **理解了进程创建的完整流程**：从分配资源到设置状态
2. **掌握了临界区保护的重要性**：使用中断保护避免竞态条件
3. **学会了错误处理的规范方法**：使用 `goto` 实现多级资源释放
4. **理解了进程调度的基本机制**：通过 `proc_list` 和状态管理

这些知识为后续实现用户进程、进程调度算法等功能奠定了坚实的基础。
