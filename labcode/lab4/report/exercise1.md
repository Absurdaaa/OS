# Lab4 Exercise1: 分配并初始化 PCB

## 一、实验目的
完成 `kern/process/proc.c` 中 `alloc_proc()` 对新内核线程的进程控制块（PCB，`struct proc_struct`）的最基本初始化，使其满足后续 `proc_init()` 的一致性校验并能够被 `do_fork()`、`copy_thread()` 等流程正确使用。

## 二、背景知识

- PCB 记录进程管理信息，包括进程状态、PID、内核栈、调度标志、父子关系、内存管理、上下文、陷入帧、页表基址、进程名以及全局链表/哈希表链接等。
- 内核线程不拥有独立的用户地址空间（`mm == NULL`），其页表基址通常指向内核的页目录（本项目为 `boot_pgdir_pa`），以使用统一的内核虚拟地址空间。
- “上下文”和“陷入帧”分别承担“调度器切换时的最小寄存器集保存”和“中断/异常现场的完整保存与恢复”的职责。

## 三、关键数据结构

- `struct proc_struct`
  - 重要字段：`state`、`pid`、`runs`、`kstack`、`need_resched`、`parent`、`mm`、`context`、`tf`、`pgdir`、`flags`、`name`、`list_link`、`hash_link`
- `struct context`
  - 字段：`ra`、`sp`、`s0`–`s11`，表示调度器切换所需的最小寄存器集
- `struct trapframe`
  - 字段：`gpr`（保存所有通用寄存器，含 a0–a7、s0–s11 等）、`status`、`epc`、`badvaddr`、`cause`

## 四、设计与实现

### 4.1 设计要点
- 置零初始化确保所有标志和计数为已知状态，防止未定义行为。
- 为内核线程设置统一的页表基址（`pgdir = boot_pgdir_pa`），`mm = NULL`，体现“共享内核地址空间”的特点。
- 上下文（`context`）和陷入帧（`tf`）在 `alloc_proc` 阶段仅置零/置空，真正的初始执行现场由 `copy_thread()` 在分配内核栈后完成。

### 4.2 关键实现步骤与代码
在 `alloc_proc()` 中初始化所有字段：
```c
// d:\study\OS\lab4\kern\process\proc.c
memset(proc, 0, sizeof(struct proc_struct));
proc->state = PROC_UNINIT;
proc->pid = -1;
proc->runs = 0;
proc->kstack = 0;
proc->need_resched = 0;
proc->parent = NULL;
proc->mm = NULL;
memset(&proc->context, 0, sizeof(proc->context));
proc->tf = NULL;
proc->pgdir = boot_pgdir_pa;
proc->flags = 0;
memset(proc->name, 0, sizeof(proc->name));
list_init(&proc->list_link);
list_init(&proc->hash_link);
```

- `state = PROC_UNINIT`：标识“刚分配尚未可运行”状态
- `pid = -1`：表示尚未分配 PID（后续由 `get_pid()` 设置）
- `kstack = 0`：尚未分配内核栈（由 `setup_kstack()` 负责）
- `need_resched = 0`：新建线程不需要立即让出 CPU
- `parent = NULL`：父子关系稍后在 `do_fork()` 中填充
- `mm = NULL`：内核线程不使用用户地址空间
- `context` 全零：等待 `copy_thread()` 写入 `ra`/`sp`（初始切换入口/栈）
- `tf = NULL`：等待 `copy_thread()` 放置到内核栈顶
- `pgdir = boot_pgdir_pa`：共享内核页表基址
- `name` 全零：等待 `set_proc_name()` 设置
- 初始化双向链表节点：使其可安全加入全局进程表/哈希表

`proc_init()` 会对上述初始化进行一致性检查并打印提示：
- 满足条件时输出：`alloc_proc() correct!`

## 五、调用关系与执行流

- `kernel_thread()` 构造临时 `trapframe`（设置 `tf.epc = kernel_thread_entry`、`tf.status`），并调用 `do_fork()`
- `do_fork()` 执行：
  - `alloc_proc()` 分配并初始 PCB
  - `setup_kstack()` 分配内核栈
  - `copy_mm()` 内核线程不做事（`mm == NULL`）
  - `copy_thread()` 将 `tf` 复制到内核栈顶并设置初始 `context`
    - `proc->tf = kstack + KSTACKSIZE - sizeof(struct trapframe)`
    - `proc->tf->gpr.a0 = 0`（子进程返回值为 0）
    - `proc->context.ra = forkret`，`proc->context.sp = proc->tf`
- 首次调度到该进程时，`switch_to()` 恢复 `context`，跳到 `forkret()`，再调用 `forkrets(current->tf)`，最终在 `__trapret` 恢复陷入帧并通过 `sret` 跳转到 `tf->epc`

## 六、问题回答：`context` 与 `trapframe` 的含义与作用

- `struct context context`
  - 含义：调度器执行“进程切换”时所需的最小寄存器集（`ra`、`sp`、`s0`–`s11`），用于保存/恢复被切换出去与切换进来的线程状态。
  - 本实验作用：
    - 在 `copy_thread()` 中设置新线程的初始 `context`：`context.ra = forkret`，`context.sp = proc->tf`
    - 当调度器执行 `switch_to()` 时，将跳转到 `forkret()`，并使用 `sp` 指向刚刚放置在内核栈顶的 `trapframe`，从而进入标准的“恢复现场→返回执行点”流程。

- `struct trapframe *tf`
  - 含义：一次中断/异常/系统调用时保存的完整执行现场，包括通用寄存器集（`gpr`）、处理器状态（`status`）、下一条要执行的指令地址（`epc`）等。
  - 本实验作用：
    - 由 `copy_thread()` 将父进程的 `tf` 复制到子进程的内核栈顶，并做差异化设置（`a0 = 0` 表示子进程）
    - `forkret()` 调用 `forkrets(current->tf)`，由 `__trapret` 统一恢复 `trapframe` 并通过 `sret` 返回至 `tf->epc` 指定的入口（内核线程为 `kernel_thread_entry`）

简而言之：`context` 负责“调度器层面的最小现场保存与切换”，`trapframe` 负责“从中断/异常返回到具体执行点时的完整现场恢复”。在本实验的内核线程创建流程中，`context` 用来让线程第一次被调度时进入 `forkret()`，而 `trapframe` 则负责在 `__trapret` 中被恢复，使控制流跳转到 `kernel_thread_entry` 并开始运行线程函数。

## 七、测试与验证

- 编译运行：
  - `make clean && make`
  - `make qemu`
- 输出包含：
  - `alloc_proc() correct!`

## 八、小结
本实验通过对 `alloc_proc()` 的全面初始化，为内核线程的创建与首次调度打下了坚实基础。`context` 与 `trapframe` 的分工明确：一个用于调度器的最小上下文切换，另一个用于陷入返回时的完整现场恢复。理解两者的衔接（`copy_thread` → `forkret` → `forkrets` → `__trapret`）是掌握 uCore 线程启动流程的关键。