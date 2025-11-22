# Lab4 Exercise3: 编写 proc_run 函数

## 一、实验目的

- 理解 CPU 上下文切换的关键步骤：关中断、切换当前进程指针、切换页表、切换上下文、开中断。
- 完成 `proc_run` 的实现并验证内核线程的创建与调度。

## 二、背景知识

`proc_run` 的职责是将指定的进程切换到 CPU 上运行。切换过程需保证原子性（通过关中断），并正确切换地址空间与寄存器上下文。

涉及的关键函数/宏：
- `local_intr_save(x)` / `local_intr_restore(x)`：关/开本地中断
- `lsatp(pgdir)`：写 SATP 寄存器，切换页表
- `switch_to(from, to)`：在两个进程的 `context` 之间切换
- `current`：当前正在 CPU 上执行的进程指针

## 三、实现步骤

1. 若 `proc == current`，直接返回（无需切换）。
2. 关中断，进入临界区。
3. 记录旧进程 `prev = current`，并将 `current = proc`。
4. 调用 `lsatp(proc->pgdir)` 切换地址空间。
5. 调用 `switch_to(&prev->context, &proc->context)` 进行上下文切换。
6. 开中断，退出临界区。

## 四、关键代码（说明性片段）

以下为核心逻辑，完整实现见 `kern/process/proc.c`：

```c
// ...existing code...
void proc_run(struct proc_struct *proc)
{
    if (proc != current) {
        bool intr_flag;
        local_intr_save(intr_flag);
        {
            struct proc_struct *prev = current;
            current = proc;
            lsatp(proc->pgdir);
            switch_to(&(prev->context), &(proc->context));
        }
        local_intr_restore(intr_flag);
    }
}
// ...existing code...
```

要点：
- 必须在关中断的临界区内同时完成 `current` 指针、页表和上下文的切换，避免并发引发不一致。
- `switch_to` 恢复到 `proc->context`，若是首次运行，将从 `forkret` 开始执行。

## 五、执行流程回顾

- `schedule()` 选择就绪进程 `p` → `proc_run(p)`。
- 切换 `current`、SATP、上下文。
- 初次恢复到 `p` 时，返回到 `forkret` → `forkrets(current->tf)` → 按 `trapframe` 恢复 → 跳转到 `tf->epc`。
- 对内核线程，`tf->epc == kernel_thread_entry`，随后进入线程函数体。

## 六、编译与运行

- 编译：`make`
- 运行：`make qemu`

预期输出（核心片段）：
```
alloc_proc() correct!
this initproc, pid = 1, name = "init"
To U: "Hello world!!".
To U: "en.., Bye, Bye. :)"
```

上述输出表明：
- `idleproc` 正常初始化；
- 通过 `kernel_thread` 创建并调度了 `initproc`，正确完成 `proc_run` 切换。

## 七、问题回答

- 在本实验的执行过程中，创建且运行了几个内核线程？
  - 共 2 个：`idleproc`（PID=0）与 `initproc`（PID=1，对应 `init_main` 内核线程）。

## 八、常见问题与调试

- 忘记关/开中断：可能在切换过程中被打断，导致 `current`、页表与上下文不一致，产生随机崩溃。
- 未切换 SATP：会在错误的地址空间中继续执行，出现页故障或访问异常。
- `proc == current` 仍强制切换：造成额外开销，甚至引发死循环或栈回溯异常。

## 九、总结

`proc_run` 是调度器与上下文切换的关键纽带。通过原子地更新 `current`、切换页表和上下文，内核能够在多个内核线程之间安全高效地切换，为后续用户进程与更复杂的调度策略打下基础。
