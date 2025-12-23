## 练习 0：填充已有实验代码

本实验依赖实验2/3/4/5的基础代码。已将对应实验的代码填入lab6中标记有"LAB2"/"LAB3"/"LAB4"/"LAB5"的位置：

- **LAB3**：[kern/trap/trap.c](../kern/trap/trap.c) 中的时钟中断处理代码（`clock_set_next_event()` 和进程时间片管理）
- **LAB4/LAB5**：[kern/process/proc.c](../kern/process/proc.c) 中的 `do_fork()` 函数实现，包括进程创建、父子关系设置等
- **LAB5**：[kern/process/proc.c](../kern/process/proc.c) 中的 `load_icode()` 用户态陷阱帧设置

编译测试通过，系统成功启动并运行调度测试程序。

## 练习 1：理解调度器框架的实现（不需要编码）

### 1.1 sched_class 结构体分析

`sched_class` 定义在 [kern/schedule/sched.h](../kern/schedule/sched.h#L17-L37) 中，是调度器框架的核心抽象接口：

- **`init`**：初始化运行队列的数据结构（链表/堆、计数器、时间片上限）。在 `sched_init()` 中仅调用一次，完成调度器的启动初始化。
  
- **`enqueue`**：将就绪进程插入运行队列。负责设置进程的时间片、`rq` 指针，并维护队列的元数据（如 `proc_num`）。在 `wakeup_proc()` 和 `schedule()` 中被调用，实现进程就绪状态管理。
  
- **`dequeue`**：从运行队列中移除进程。更新队列元数据，清除进程的 `rq` 指针。由 `schedule()` 在选出下一个进程后调用。
  
- **`pick_next`**：选择下一个要运行的进程，是调度策略的核心。不同调度算法（RR、Stride等）在此函数中实现各自的选择逻辑。在 `schedule()` 需要切换进程时调用。
  
- **`proc_tick`**：时钟中断处理函数。对当前进程的时间片递减，决定是否设置 `need_resched` 标志。通过 `sched_class_proc_tick()` 在时钟中断处理程序中被统一调用。

**为何使用函数指针？**

采用函数指针而非直接实现函数的设计，体现了"策略与机制分离"的思想：
- **框架层**（`sched.c`）只关心调度的流程和接口，不关心具体算法细节
- **策略层**（各个调度类实现）通过实现 `sched_class` 接口来提供不同的调度算法
- 这种设计使得**切换调度算法**只需更改 `sched_class` 指针，无需修改调度框架代码
- 支持**多种调度算法共存**，便于对比测试和扩展新算法


### 1.2 run_queue 结构体差异分析

**lab5 的 run_queue**（仅包含基本链表结构）：
```c
struct run_queue {
    list_entry_t run_list;      // 运行队列链表
    unsigned int proc_num;       // 队列中进程数
    int max_time_slice;         // 最大时间片
};
```

**lab6 的 run_queue**（增加斜堆支持）：
```c
struct run_queue {
    list_entry_t run_list;
    unsigned int proc_num;
    int max_time_slice;
    // For LAB6 ONLY
    skew_heap_entry_t *lab6_run_pool;  // 斜堆根指针
};
```

**为何需要两种数据结构？**

- **RR 调度算法**：使用 `run_list` 链表维护 FIFO 顺序队列，实现简单的轮转调度
- **Stride 调度算法**：需要按 stride 值选取最小的进程，使用 `lab6_run_pool` 斜堆（优先队列）实现高效的最小值查找
- 统一的 `run_queue` 结构同时支持两种内部数据结构，使得**不同调度类可以共享同一框架**，根据需要选择合适的数据结构

这种设计体现了框架的灵活性：调度框架不关心底层使用链表还是堆，只通过 `sched_class` 接口操作队列。

### 1.3 调度器框架函数演进分析

#### sched_init() 的变化

**lab5**：直接初始化链表
```c
void sched_init(void) {
    list_init(&run_queue.run_list);
    run_queue.proc_num = 0;
    run_queue.max_time_slice = MAX_TIME_SLICE;
}
```

**lab6**：通过调度类初始化
```c
void sched_init(void) {
    sched_class = &default_sched_class;  // 可切换为其他调度类
    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);  // 调用具体调度算法的初始化函数
}
```

**改进意义**：实现了框架与策略的分离，切换调度算法只需更改 `sched_class` 指针。

#### wakeup_proc() 的变化

**lab5**：直接操作链表
```c
void wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
    if (proc->state != PROC_RUNNABLE) {
        proc->state = PROC_RUNNABLE;
        list_add_before(&run_queue.run_list, &proc->run_link);
        run_queue.proc_num++;
    }
}
```

**lab6**：调用调度类的 enqueue 接口
```c
void wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
    if (proc->state != PROC_RUNNABLE) {
        proc->state = PROC_RUNNABLE;
        proc->wait_state = 0;
        if (proc != current) {
            sched_class->enqueue(rq, proc);  // 通过接口入队
        }
    }
}
```

**改进意义**：避免硬编码插入逻辑，支持不同调度算法使用不同的队列结构。

#### schedule() 的变化

**统一的调度流程**：
1. 保存当前进程状态
2. 如果当前进程仍可运行，调用 `sched_class->enqueue()` 将其放回队列
3. 调用 `sched_class->pick_next()` 选择下一个进程
4. 调用 `sched_class->dequeue()` 将选中的进程移出队列
5. 调用 `proc_run()` 完成上下文切换

所有策略差异都通过 `sched_class` 的函数指针体现，**核心调度框架完全不关心具体的队列实现和选择算法**。

### 1.4 调度器框架使用流程

#### 调度类初始化流程

```
kern_init()
  └─> pmm_init()        // 物理内存管理初始化
  └─> vmm_init()        // 虚拟内存管理初始化
  └─> sched_init()      // 调度器初始化
      ├─> sched_class = &default_sched_class  // 选择调度类
      ├─> rq->max_time_slice = MAX_TIME_SLICE
      └─> sched_class->init(rq)               // 调用具体算法初始化
  └─> proc_init()       // 创建 idle/init 进程
```

**关键点**：`default_sched_class` 是默认的RR调度类，可以通过编译宏切换为其他调度算法（如 Stride）。

#### 进程调度流程图

```
时钟中断
  └─> trap()
      └─> interrupt_handler()
          └─> case IRQ_S_TIMER:
              ├─> clock_set_next_event()           // 设置下次中断
              ├─> ticks++
              └─> sched_class_proc_tick(current)   // 调用调度类的 proc_tick
                  └─> sched_class->proc_tick(rq, current)
                      ├─> current->time_slice--     // 递减时间片
                      └─> if (time_slice == 0)
                          └─> need_resched = 1      // 设置调度标志
  
  └─> 中断返回前检查 need_resched
      └─> if (need_resched)
          └─> schedule()
              ├─> if (current->state == PROC_RUNNABLE)
              │   └─> sched_class->enqueue(rq, current)  // 当前进程重新入队
              ├─> next = sched_class->pick_next(rq)      // 选择下一个进程
              ├─> sched_class->dequeue(rq, next)         // 将其移出队列
              └─> proc_run(next)                         // 上下文切换
```

**need_resched 标志的作用**：
- 作为"请求调度"的信号，由时钟中断、`yield` 系统调用、进程唤醒等场景设置
- 保证进程切换只在**安全点**（中断返回前）发生，而不是在任意位置切换
- 避免在持有锁或处于临界区时进行上下文切换

#### 调度算法切换机制

**添加新调度算法的步骤**：
1. 在 `kern/schedule/` 创建新的调度算法实现文件（如 `stride_sched.c`）
2. 实现 `sched_class` 的所有接口函数（`init`, `enqueue`, `dequeue`, `pick_next`, `proc_tick`）
3. 在 `kern/schedule/sched.h` 中声明新的调度类
4. 在 `kern/schedule/sched.c::sched_init()` 中通过编译宏选择调度类

**为什么切换调度算法很容易？**
- 调度框架（`schedule()`, `wakeup_proc()` 等）**完全基于接口编程**，不依赖具体实现
- 只需在 `sched_init()` 中更改一行代码（或使用编译宏）即可切换
- 不同调度算法可以使用不同的数据结构（链表/堆/红黑树等），框架层无感知

## 练习 2：实现 Round Robin 调度算法（需要编码）

### 2.1 lab5/lab6 关键差异分析

**典型差异函数**：[kern/schedule/sched.c](../kern/schedule/sched.c) 中的 `wakeup_proc()`

**lab5 实现**：
```c
void wakeup_proc(struct proc_struct *proc) {
    if (proc->state != PROC_RUNNABLE) {
        proc->state = PROC_RUNNABLE;
        // 直接操作全局run_list链表
        list_add_before(&run_queue.run_list, &proc->run_link);
        run_queue.proc_num++;
    }
}
```

**lab6 实现**：
```c
void wakeup_proc(struct proc_struct *proc) {
    if (proc->state != PROC_RUNNABLE) {
        proc->state = PROC_RUNNABLE;
        proc->wait_state = 0;
        if (proc != current) {
            // 通过调度类接口操作队列
            sched_class->enqueue(rq, proc);
        }
    }
}
```

**为什么必须做这个改动？**

1. **支持多种调度算法**：lab5 硬编码使用链表插入，无法支持 Stride 等需要堆结构的算法。lab6 通过调用 `sched_class->enqueue()`，不同调度类可以使用不同的数据结构。

2. **避免调度器失效**：如果保持 lab5 的实现，在切换到 Stride 调度器时：
   - `wakeup_proc()` 仍然向链表中插入进程
   - 但 Stride 的 `pick_next()` 从斜堆中选择进程
   - 链表和堆的数据不一致，导致进程丢失或重复调度
   - 运行队列元数据（`proc_num`）无法正确维护
   - **最终导致调度失败或内核崩溃**

3. **框架与策略解耦**：通过接口调用，唤醒逻辑与具体调度算法完全解耦，便于扩展和维护。

### 2.2 RR 调度算法实现

所有实现代码位于 [kern/schedule/default_sched.c](../kern/schedule/default_sched.c)

#### RR_init 实现思路

**功能**：初始化运行队列的数据结构

```c
static void RR_init(struct run_queue *rq) {
    list_init(&(rq->run_list));  // 初始化链表为空
    rq->proc_num = 0;             // 进程数清零
    rq->lab6_run_pool = NULL;    // 清空斜堆（RR不使用）
}
```

**关键点**：
- 必须初始化 `run_list` 为空链表，否则后续的 `list_empty()` 判断会出错
- `proc_num` 必须清零，保证入队/出队计数正确
- 虽然 RR 不使用 `lab6_run_pool`，但也要将其置为 NULL，保证结构完整性

#### RR_enqueue 实现思路

**功能**：将进程插入运行队列尾部（FIFO顺序）

```c
static void RR_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    // 检查并重置时间片
    if (proc->time_slice <= 0 || proc->time_slice > rq->max_time_slice) {
        proc->time_slice = rq->max_time_slice;
    }
    // 设置进程所属的运行队列
    proc->rq = rq;
    // 尾插法：在run_list前面插入 = 插入到队列尾部
    list_add_before(&(rq->run_list), &(proc->run_link));
    // 更新进程计数
    rq->proc_num++;
}
```

**关键点**：
- **时间片重置**：新入队或时间片耗尽的进程需要分配新的时间片
- **`list_add_before(&run_list, &run_link)`**：由于 `run_list` 是循环链表的头节点，在其前面插入等价于尾插，实现 FIFO
- **设置 `proc->rq`**：记录进程所属的运行队列，用于后续操作验证
- **边界条件**：时间片可能为 0（新进程）或超出上限（异常情况），统一重置为 `max_time_slice`

#### RR_dequeue 实现思路

**功能**：将进程从运行队列中移除

```c
static void RR_dequeue(struct run_queue *rq, struct proc_struct *proc) {
    // 从链表中删除节点并重新初始化
    list_del_init(&(proc->run_link));
    // 清除队列关联
    proc->rq = NULL;
    // 安全递减计数（避免下溢）
    if (rq->proc_num > 0) {
        rq->proc_num--;
    }
}
```

**关键点**：
- **`list_del_init()`**：删除节点后重新初始化链表指针，避免野指针
- **清除 `proc->rq`**：表示进程不再属于任何运行队列
- **防止计数下溢**：虽然正常情况下不会出现，但加上判断增强健壮性

#### RR_pick_next 实现思路

**功能**：选择下一个要运行的进程（队首进程）

```c
static struct proc_struct *RR_pick_next(struct run_queue *rq) {
    // 检查队列是否为空
    if (list_empty(&(rq->run_list))) {
        return NULL;
    }
    // 取链表的第一个元素（队首）
    list_entry_t *le = list_next(&(rq->run_list));
    // 通过宏转换为进程结构体指针
    return le2proc(le, run_link);
}
```

**关键点**：
- **空队列处理**：必须先检查队列是否为空，否则 `list_next()` 会返回头节点本身
- **`list_next(&run_list)`**：获取链表头节点的下一个元素，即队首进程
- **`le2proc(le, run_link)`**：通过 `run_link` 字段偏移计算出 `proc_struct` 的地址
- **符合 FIFO 语义**：总是选择最先入队的进程

#### RR_proc_tick 实现思路

**功能**：时钟中断时递减时间片，决定是否触发调度

```c
static void RR_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    // 递减时间片
    if (proc->time_slice > 0) {
        proc->time_slice--;
    }
    // 时间片耗尽时请求调度
    if (proc->time_slice == 0) {
        proc->need_resched = 1;
    }
}
```

**关键点**：
- **安全递减**：先判断 `> 0` 再递减，避免负数
- **设置 `need_resched`**：这是触发进程切换的关键标志
- **为什么必须设置 `need_resched`？**
  - 如果不设置，时间片耗尽后当前进程仍会继续运行
  - 其他就绪进程永远得不到调度，RR 调度算法失效
  - 系统退化为非抢占式调度，响应性极差

#### 边界条件处理总结

1. **空队列**：`RR_pick_next()` 返回 NULL，由 `schedule()` 处理
2. **时间片异常**：`RR_enqueue()` 统一重置为 `max_time_slice`
3. **计数保护**：`RR_dequeue()` 检查 `proc_num > 0` 再递减
4. **空闲进程**：框架层（`schedule()`）已经排除，调度类无需特殊处理


### 2.3 测试结果与调度现象

#### make grade 输出结果

```
badsegment:              (3.6s)
  -check result:                             OK
  -check output:                             OK
divzero:                 (1.6s)
  -check result:                             OK
  -check output:                             OK
softint:                 (1.6s)
  -check result:                             OK
  -check output:                             OK
faultread:               (1.6s)
  -check result:                             OK
  -check output:                             OK
faultreadkernel:         (1.6s)
  -check result:                             OK
  -check output:                             OK
hello:                   (1.6s)
  -check result:                             OK
  -check output:                             OK
testbss:                 (1.6s)
  -check result:                             OK
  -check output:                             OK
pgdir:                   (1.6s)
  -check result:                             OK
  -check output:                             OK
yield:                   (1.6s)
  -check result:                             OK
  -check output:                             OK
badarg:                  (1.6s)
  -check result:                             OK
  -check output:                             OK
exit:                    (1.6s)
  -check result:                             OK
  -check output:                             OK
spin:                    (1.6s)
  -check result:                             OK
  -check output:                             OK
waitkill:                (2.6s)
  -check result:                             OK
  -check output:                             OK
forktest:                (1.6s)
  -check result:                             OK
  -check output:                             OK
forktree:                (1.6s)
  -check result:                             OK
  -check output:                             OK
priority:                (2.0s)
  -check result:                             OK
  -check output:                             OK
Total Score: 170/170
```

**结果分析**：所有测试用例通过，RR 调度器工作正常。

#### QEMU 中观察到的调度现象

运行 `priority` 测试程序的输出片段：

```
kernel_execve: pid = 2, name = "priority".
set priority to 6
main: fork ok,now need to wait pids.
set priority to 5
set priority to 4
set priority to 3
set priority to 2
set priority to 1
child pid 7, acc 432000, time 2010
child pid 6, acc 424000, time 2010
child pid 5, acc 420000, time 2010
child pid 4, acc 420000, time 2010
child pid 3, acc 416000, time 2020
main: pid 3, acc 416000, time 2020
main: pid 4, acc 420000, time 2020
main: pid 5, acc 420000, time 2020
main: pid 6, acc 424000, time 2020
main: pid 0, acc 432000, time 2020
main: wait pids over
sched result: 1 1 1 1 1
all user-mode processes have quit.
init check memory pass.
```

**调度现象分析**：

1. **时间片轮转**：多个子进程的 `acc` 值接近（416000-432000），说明各进程获得了基本均等的 CPU 时间
2. **公平性**：`sched result: 1 1 1 1 1` 表示所有进程的相对执行时间比例相同
3. **RR 特性**：由于 RR 不考虑优先级（`set priority` 在 RR 中不生效），所有进程平等竞争
4. **抢占式调度**：可以观察到进程之间频繁切换，时间片耗尽后能够及时调度其他进程

### 2.4 Round Robin 调度算法分析

#### 优点

1. **公平性好**：所有进程获得相等的 CPU 时间片，避免饥饿
2. **响应时间可预测**：最大等待时间 = (进程数 - 1) × 时间片大小
3. **实现简单**：只需维护一个 FIFO 队列，算法复杂度低
4. **适合分时系统**：能够保证多个用户程序都得到响应

#### 缺点

1. **不区分优先级**：重要进程和普通进程得到相同待遇
2. **不考虑进程特性**：I/O 密集型和 CPU 密集型进程一视同仁
3. **平均周转时间可能较长**：短作业可能需要等待长作业完成其时间片
4. **上下文切换开销**：时间片过小会导致频繁切换，降低系统效率

#### 时间片大小的影响

**时间片过小**（如 1ms）：
- **优点**：响应速度快，交互性好
- **缺点**：上下文切换频繁，CPU 利用率低，系统开销大

**时间片过大**（如 100ms）：
- **优点**：上下文切换少，吞吐量高
- **缺点**：响应时间长，退化为 FIFO，交互性差

**时间片优化策略**：
- **经验值**：通常设置为 10-100ms，本实验中 `MAX_TIME_SLICE = 5` 个时钟周期
- **动态调整**：根据系统负载和进程特性调整时间片大小
- **自适应策略**：I/O 密集型进程可以分配较小时间片，CPU 密集型进程分配较大时间片

**代码中的时间片设置**：在 [kern/schedule/sched.h](../kern/schedule/sched.h#L8)
```c
#define MAX_TIME_SLICE 5
```

#### need_resched 标志的作用

在 `RR_proc_tick()` 中设置 `need_resched = 1` 是实现抢占式调度的关键：

```c
if (proc->time_slice == 0) {
    proc->need_resched = 1;  // 请求调度
}
```

**为什么需要这个标志？**

1. **延迟调度**：不能在中断处理程序中直接切换进程（可能持有锁），需要标记后在安全点切换
2. **统一入口**：时钟中断、系统调用、I/O 完成等多种事件都通过设置此标志请求调度
3. **避免嵌套**：防止在调度过程中再次触发调度，导致栈溢出
4. **保证原子性**：在中断返回前统一检查并调度，保证调度的原子性

**不设置的后果**：
- 当前进程时间片耗尽后继续运行
- 其他就绪进程永远得不到 CPU
- RR 调度器完全失效，系统退化为非抢占式调度

### 2.5 扩展思考

#### 实现优先级 RR 调度

**方案一：多级队列**
```c
struct run_queue rq[NUM_PRIORITY];  // 每个优先级一个队列

void RR_enqueue_priority(struct run_queue *rq, struct proc_struct *proc) {
    int priority = proc->priority;
    list_add_before(&rq[priority].run_list, &proc->run_link);
    rq[priority].proc_num++;
}

struct proc_struct *RR_pick_next_priority(struct run_queue *rq) {
    // 从高优先级到低优先级扫描
    for (int i = NUM_PRIORITY - 1; i >= 0; i--) {
        if (!list_empty(&rq[i].run_list)) {
            list_entry_t *le = list_next(&rq[i].run_list);
            return le2proc(le, run_link);
        }
    }
    return NULL;
}
```

**方案二：优先级加权时间片**
```c
void RR_enqueue_weighted(struct run_queue *rq, struct proc_struct *proc) {
    // 根据优先级设置不同的时间片
    proc->time_slice = rq->max_time_slice * proc->priority;
    list_add_before(&rq->run_list, &proc->run_link);
}
```

**需要修改的代码**：
- `proc_struct` 添加 `priority` 字段
- 修改 `RR_enqueue()` 和 `RR_pick_next()`
- 添加设置优先级的系统调用接口

#### 多核调度支持

**当前实现的限制**：
- 只有一个全局 `run_queue`，所有 CPU 共享
- `schedule()` 没有考虑 CPU 亲和性
- 没有负载均衡机制

**多核支持改进方案**：

1. **每CPU运行队列**：
```c
struct run_queue per_cpu_rq[NCPU];  // 每个CPU一个队列

void schedule(void) {
    int cpu_id = cpuid();
    struct run_queue *rq = &per_cpu_rq[cpu_id];
    struct proc_struct *next = sched_class->pick_next(rq);
    // ...
}
```

2. **负载均衡**：
```c
void load_balance(void) {
    // 定期检查各CPU的队列长度
    // 将进程从繁忙CPU迁移到空闲CPU
    if (rq[cpu_i].proc_num > rq[cpu_j].proc_num + THRESHOLD) {
        migrate_proc(cpu_i, cpu_j);
    }
}
```

3. **同步保护**：
```c
void RR_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    spin_lock(&rq->lock);  // 加锁保护
    // 原有逻辑
    spin_unlock(&rq->lock);
}
```

4. **CPU 亲和性**：
```c
struct proc_struct {
    // ...
    int cpu_affinity;  // 绑定的CPU编号
    int last_cpu;      // 上次运行的CPU
};
```

**实现难点**：
- 锁竞争：多个 CPU 同时访问运行队列需要同步
- 缓存一致性：进程在 CPU 间迁移会失去缓存局部性
- 负载均衡策略：如何平衡负载均衡和缓存亲和性

---

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
