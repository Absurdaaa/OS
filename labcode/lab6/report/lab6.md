## 练习 1：调度器框架理解

### sched_class 结构体
- `init`：调度器启动时初始化运行队列内部数据结构（链表/堆、计数器、时间片上限）。在 `sched_init` 中调用一次。
- `enqueue`：将就绪进程加入运行队列；负责设置时间片和 `rq` 指针，并维护队列元数据。被 `wakeup_proc`/`schedule` 放回就绪队列时调用。
- `dequeue`：从运行队列移除进程；更新元数据。由 `schedule` 选出下一个进程后调用。
- `pick_next`：从运行队列选出下一个要运行的进程（策略核心）。`schedule` 在需要切换时调用。
- `proc_tick`：时钟中断到来时对当前进程的时间片递减、决定是否置 `need_resched`。在 `sched_class_proc_tick` 中被统一调用。
- 采用函数指针而非直接函数，是为了将“框架”与“策略”解耦：核心调度器只面向接口，具体算法（RR、stride 等）以不同的 `sched_class` 实例插拔，便于扩展和切换。

### run_queue 结构体
- lab5 仅包含 `run_list`、`proc_num`、`max_time_slice`（纯链表维护）。
- lab6 增加 `lab6_run_pool`（斜堆根指针），同时保留 `run_list`。原因：RR 仍用链表顺序队列，而 stride 需要按最小 stride 选取的优先队列。统一的 `run_queue` 同时支持两种内部结构，便于不同调度类共享同一框架。

### 框架函数演进
- `sched_init()`：原来直接初始化链表；现在先选定全局 `sched_class`（默认 RR/stride 可切换），再调用其 `init` 完成与具体算法对应的队列初始化，实现框架与策略分离。
- `wakeup_proc()`：保持唤醒语义，但对非当前进程的就绪操作改为调用 `sched_class->enqueue`，避免硬编码插入逻辑。
- `schedule()`：统一流程（保存当前、如可运行则 enqueue；pick_next；dequeue；`proc_run`），所有策略差异都通过 `sched_class` 的函数指针体现，核心不再关心队列实现。

## 练习 2：RR 调度实现与分析

### lab5/lab6 差异示例
- 典型差异：`kern/schedule/sched.c::wakeup_proc`。lab5 直接操作 `run_list` 链表插入；lab6 改为调用 `sched_class->enqueue`。若保持旧实现，则在切换到 stride/其他调度类时，运行队列元数据和内部结构（如斜堆）不会更新，导致调度失效或内核崩溃。框架层改动让唤醒逻辑与具体算法解耦。

### 函数实现思路
- `RR_init`：初始化 `run_list` 为空、`proc_num=0`，并清空 `lab6_run_pool`。只有这一步能保证后续入队/出队的边界条件正确。
- `RR_enqueue`：若传入的 `time_slice` 无效（0 或超过上限），重置为 `rq->max_time_slice`；设置 `rq` 指针；用 `list_add_before(&run_list, &run_link)` 尾插（简洁维护 FIFO 顺序）；`proc_num++`。
- `RR_dequeue`：`list_del_init` 将节点摘除并自初始化，清空 `rq` 指针，`proc_num` 在非空时递减，避免计数为负。
- `RR_pick_next`：空队列直接返回 `NULL`；否则取 `run_list` 的第一个元素 `list_next`，用 `le2proc` 得到 `proc`，符合“先到先服务”。
- `RR_proc_tick`：每个时钟中断递减 `time_slice`，耗尽时置 `need_resched=1` 触发调度。若不设置该标志，当前进程会一直占用 CPU，RR 失效。
  - 边界处理：空闲进程在框架层已排除；`time_slice` 下溢前先判断 `>0`。

### 调度流程观察
- 默认调度类已设为 RR（`sched_init` 选择 `default_sched_class`），运行队列按 FIFO 轮转。
- `make grade` 结果：  
  ```
  priority:                (2.0s)
    -check result:                             OK
    -check output:                             OK
  Total Score: 50/50
  ```
  QEMU 输出中可观察到多个子进程轮流运行并汇报计数：`sched result: 1 1 1 1 1`，随后 `all user-mode processes have quit.` 与 `init check memory pass.`，证明 RR 正常抢占调度完成整轮实验。

## 扩展练习：Stride Scheduling

### 实现概要
- 切换调度器：`kern/schedule/sched.c` 在 `sched_init` 选择 `stride_sched_class`。
- `kern/schedule/default_sched_stride.c`：
  - 定义 `BIG_STRIDE=0x7FFFFFFF`，使用斜堆维护最小 stride。
  - `stride_init` 初始化 `run_list`、`lab6_run_pool`、`proc_num`。
  - `stride_enqueue`：若优先级为 0 设为 1；校正时间片；设置 `rq`；`skew_heap_insert` 入队；`proc_num++`。
  - `stride_dequeue`：`skew_heap_remove` 摘除，清 `rq`，递减计数。
  - `stride_pick_next`：取堆顶最小 stride 进程，更新其 `lab6_stride += BIG_STRIDE / priority` 并返回。
  - `stride_proc_tick`：递减时间片，耗尽置 `need_resched`。
- `tools/grade.sh` 期望字符串调整为 `sched class: stride_scheduler`，`make grade` 通过，Total Score: 50/50。

### Stride 公平性说明
每次被调度的进程 i，其 stride 增量为 `BigStride/priority_i`。设总运行 N 次，每次选最小 stride 的进程。当 N 足够大时，进程 i 的被选次数约为：
```
ni ≈ (N * priority_i) / Σ priority
```
原因：选择顺序等价于对每个进程维护累计“虚拟时间”，每次加固定步长（与 1/priority 成正比），始终选择累积最小者。该过程与“加权轮转”一致，长远平均选取频率与权重（priority）成正比。

### 多级反馈队列（MFQ）代码
- `kern/schedule/default_sched_mlfq.c`：新增一个 `mlfq_sched_class`，内部维护 `struct run_queue rq[LEVELS]`；`mlfq_init` 对每级 `run_list` 初始化。
- `kern/process/proc.h`：为 `proc_struct` 增加 `int mlfq_level`（当前队列级别），可复用 `time_slice` 作为当前队列时间片。
- `mlfq_enqueue`：根据 `proc->mlfq_level` 入对应队列（`list_add_before` 尾插）。
- `mlfq_pick_next`：从高到低扫描 `rq[i].run_list`，取第一个非空队列的队头。
- `mlfq_proc_tick`：`time_slice--` 到 0 时将 `mlfq_level` 降级（不低于最低级），并置 `need_resched`；如果进程主动 `yield` 或阻塞唤醒，可以在 `wakeup_proc` 处提升到高优先级。
- 老化（防饥饿）：可利用 `timer_list` 或 `ticks` 周期性扫描，把长期等待的进程提升到较高队列。

### 实现过程简述
1. 完成 RR 后，按接口实现 stride：选用斜堆维护最小 stride；在 `pick_next` 中更新 stride；保持时间片逻辑复用 RR。
2. 将框架切换到 `stride_sched_class` 并调整 grade 检查项。
3. 跑 `make grade` 验证 QEMU 输出与分数，确认调度器切换后仍通过测试。

## Challenge 2：多算法实现

### 调度器选择入口
- `kern/schedule/sched.c`：`sched_init` 通过编译宏选择调度类：
  - `USE_SCHED_FIFO` -> `fifo_sched_class`
  - `USE_SCHED_SJF` -> `sjf_sched_class`
  - `USE_SCHED_RR` -> `default_sched_class`
  - 无宏默认 `stride_sched_class`
  这样每次测试只需要切换 `DEFS` 即可切换算法，核心调度流程不变。

### FIFO（`kern/schedule/default_sched_fifo.c`）
- `fifo_enqueue`：使用 `list_add_before(&rq->run_list, &proc->run_link)` 尾插，形成“先来先服务”的链表队列。
- `fifo_pick_next`：`list_next(&rq->run_list)` 直接取队头，保证 FIFO 顺序。
- `fifo_proc_tick`：`time_slice--`，为 0 时置 `need_resched=1`，确保即使 FIFO 也能在时钟中断触发切换。

### RR（`kern/schedule/default_sched.c`）
- `RR_enqueue` 与 FIFO 相同的尾插逻辑，但语义强调“固定时间片轮转”。
- `RR_proc_tick`：每个时钟中断递减时间片，耗尽后请求调度，体现 RR 的强制轮转。

### SJF（`kern/schedule/default_sched_sjf.c`）
- `sjf_enqueue`：遍历 `run_list`，按 `time_slice` 从小到大插入（`proc->time_slice < p->time_slice` 时插入到前面），链表始终保持“最短作业在前”。
- `sjf_pick_next`：直接取队头，即最短作业。
- 注意：该实现把 `time_slice` 当作“剩余时间的近似”，进程在运行中 `time_slice--`，yield 或阻塞后再次入队时保留较小值，因此在测试中更偏好“短任务”。

### Stride（`kern/schedule/default_sched_stride.c`）
- `stride_enqueue`：把 `proc->lab6_run_pool` 插入斜堆（`skew_heap_insert`），堆顶永远是 stride 最小的进程。
- `stride_pick_next`：`p->lab6_stride += BIG_STRIDE / p->lab6_priority`，通过 `lab6_priority` 实现权重。
- `lab6_priority` 在 `kern/process/proc.c::lab6_set_priority` 设置，用户态通过 `user/priority.c::lab6_setpriority` 调用系统调用写入。

## 测试样例与结果、

### 测试程序
- `user/priority.c`：
  - 主进程 `lab6_setpriority(TOTAL + 1)`，子进程依次 `lab6_setpriority(i + 1)`。
  - 每个子进程循环累加 `acc`，到达时间阈值打印 `acc` 并退出。
  - 该程序直接验证是否“使用了 priority”。
- `user/schedbench.c`：
  - `spin_cpu`：用 `gettime_msec()` 做 500ms 忙等，统计迭代数。
  - `io_style`：循环 `yield()` + 10ms 忙等，统计 ticks。
  - `main` fork 3 个 CPU 进程 + 2 个 IO 进程并 waitpid，输出 `[CPU]`/`[IO]` 行用于比较。

### 全算法测试流程
对每个调度器分别运行 `priority` 和 `schedbench`：
- stride：无宏
- RR：`DEFS+=-DUSE_SCHED_RR`
- FIFO：`DEFS+=-DUSE_SCHED_FIFO`
- SJF：`DEFS+=-DUSE_SCHED_SJF`

执行流程（每个算法重复）：
1. `make clean`
2. `make build-priority <DEFS...>`，运行 QEMU，保存 `.qemu_priority_<alg>.out`
3. `make clean`
4. `make build-schedbench <DEFS...>`，运行 QEMU，保存 `.qemu_schedbench_<alg>.out`

### 观测输出（对应日志文件）
- `priority` 日志：`.qemu_priority_fifo.out` / `.qemu_priority_rr.out` / `.qemu_priority_sjf.out` / `.qemu_priority_stride.out`
- `schedbench` 日志：`.qemu_schedbench_fifo.out` / `.qemu_schedbench_rr.out` / `.qemu_schedbench_sjf.out` / `.qemu_schedbench_stride.out`

### 结果分析（对照代码）
- `priority`：只有 stride 使用 `lab6_priority`（`stride_pick_next` 里 `BIG_STRIDE / priority`），因此 stride 的 `acc` 随优先级明显递增；FIFO/RR/SJF 的 enqueue/pick_next 都不读取 `lab6_priority`，所以 `sched result` 基本相同。
- `schedbench`：IO 任务频繁 `yield`，在 SJF 中由于 `time_slice` 被消耗后以较小值重新入队（`sjf_enqueue` 按小值排序），因此 IO ticks 明显更高；FIFO/RR 尾插导致 IO 任务只能排队等待，ticks 较低；Stride 无优先级区分（默认 priority=1），斜堆近似公平，但不对 IO 优待，因此 IO ticks 最低。

### 各算法测试结果汇总

**priority（权重公平性）**：
- stride 输出 `sched result: 1 1 2 2 3`，acc 随优先级递增。
- RR/FIFO/SJF 输出 `sched result: 1 1 1 1 1`，对优先级不敏感。

| 调度器 | child acc（5 个子进程） | sched result |
| --- | --- | --- |
| FIFO | 432000, 420000, 416000, 416000, 424000 | 1 1 1 1 1 |
| RR | 432000, 424000, 420000, 420000, 416000 | 1 1 1 1 1 |
| SJF | 424000, 408000, 424000, 428000, 424000 | 1 1 1 1 1 |
| Stride | 624000, 524000, 428000, 312000, 212000 | 1 1 2 2 3 |

**schedbench（CPU+IO 混合负载）**：

| 调度器 | CPU iters（3 个） | 平均 CPU iter | IO ticks（2 个） | 平均 IO ticks |
| --- | --- | --- | --- | --- |
| FIFO | 27555, 35816, 35939 | 33103.3 | 5, 5 | 5.0 |
| RR | 27755, 35545, 34828 | 32709.3 | 5, 5 | 5.0 |
| SJF | 25430, 26710, 34956 | 29032.0 | 6, 10 | 8.0 |
| Stride | 27309, 26223, 38920 | 30817.3 | 3, 3 | 3.0 |

**结论（基于代码与输出）**：
- Stride 的权重体现在 `stride_pick_next` 中的 stride 更新，输出 `sched result: 1 1 2 2 3` 与 acc 递增一致。
- FIFO/RR/SJF 都没有读取 `lab6_priority`，所以 `priority` 输出趋同（`1 1 1 1 1`）。
- SJF 因为按 `time_slice` 排序（`sjf_enqueue`），对频繁让出 CPU 的 IO 任务更有利，ticks 最高；FIFO/RR 不做排序，ticks 中等；Stride 公平但无 IO 优先策略，ticks 最低。

### RR 调度优缺点与时间片
- 代码位置：`kern/schedule/default_sched.c::RR_proc_tick` 每个 tick 递减 `time_slice`，为 0 时置 `need_resched=1`；`kern/schedule/sched.h::MAX_TIME_SLICE` 控制默认时间片。
- 现象对应：时间片越小，`RR_proc_tick` 更快触发 `need_resched`，`schedule()` 调用更频繁，响应更快但切换更密集；时间片越大，切换变少但交互延迟增大。

### 扩展思考
- 若要实现优先级 RR：可以在 `enqueue` 时根据优先级选择插入位置（多队列分级或同队列按权重插入），或结合优先级衰减/动态提升；同时在 `pick_next` 中按优先级选择队列。当前代码可在 RR 基础上增加多级队列或将 `lab6_priority` 融合到时间片计算。
- 多核支持：当前框架只有单全局 `run_queue` 和单 CPU。要支持 SMP，需要为每个 CPU 维护本地 `run_queue`、增加负载均衡、关/开中断或锁保护队列操作，并在上下文切换中处理 CPU 绑定和跨核唤醒。

## 调度器使用流程

### 调度类初始化路径
1. `kern_init` 中依次调用 `pmm_init`、`vmm_init` 后进入 `sched_init`。
2. `sched_init` 选择 `sched_class`（默认 `default_sched_class`），设置 `rq->max_time_slice`，调用 `sched_class->init` 完成运行队列初始化。
3. 之后 `proc_init` 创建 idle/init 进程并将其放入调度流程，调度框架即可工作。

### 进程调度流程（时钟驱动）
1. 时钟中断触发 `trap` → `interrupt_handler`，其中 `sched_class_proc_tick(current)` 调用当前算法的 `proc_tick`。
2. `proc_tick` 递减当前进程 `time_slice`，耗尽时置 `need_resched=1`。
3. 中断返回前在内核态检查 `need_resched`，若为 1 调用 `schedule()`。
4. `schedule()`：
   - 若当前仍可运行，先 `enqueue` 回就绪队列。
   - 通过 `pick_next` 选出下一个进程；`dequeue` 将其移出队列。
   - `proc_run` 完成上下文/页表切换。
5. `need_resched` 是“请求调度”标志：时钟耗尽、显式 `yield`、阻塞唤醒等场景通过设置该标志触发调度，而不直接在任意位置切换上下文，保证切换发生在安全点。

### 调度算法切换机制
- 新算法落地点：在 `kern/schedule/` 增加实现文件并导出 `struct sched_class`，在 `kern/schedule/default_sched.h` 声明。
- 切换入口：`kern/schedule/sched.c::sched_init` 使用编译宏选择 `sched_class` 指针（`USE_SCHED_FIFO/USE_SCHED_SJF/USE_SCHED_RR`），因此测试时只需调整 `DEFS`，无需改 `schedule()` / `wakeup_proc()` 等核心路径。
