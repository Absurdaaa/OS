# 扩展练习 Challenge1：完成基于“UNIX的PIPE机制”的设计方案

> 完成基于“UNIX的PIPE机制”的设计方案 如果要在ucore里加入UNIX的管道（Pipe）机制，至少需要定义哪些数据结构和接口？（接口给出语义即可，不必具体实现。数据结构的设计应当给出一个（或多个）具体的C语言struct定义。在网络上查找相关的Linux资料和实现，请在实验报告中给出设计实现”UNIX的PIPE机制“的概要设方案，你的设计应当体现出对可能出现的同步互斥问题的处理。）

## 一、UNIX的管道（Pipe）机制原理

UNIX PIPE 是一种进程间通信（IPC）机制，提供一个 ​**单向字节流通道**​：一个进程向写端写入数据，另一个进程从读端读取，按照 FIFO（先进先出）顺序传输，不需要显式共享内存或文件。系统调用 `pipe()` 会返回两个文件描述符，一个用于读，一个用于写。内核自动管理缓冲区、阻塞/唤醒等机制。

Linux 内核内部实际上通过一个 **虚拟文件系统 pipefs** 来实现 pipe，每个 pipe 对象在内核中维护一个 ​**环形缓冲区**​（ring buffer）来保存待传输数据，同时为缓冲区读写两端维护状态和同步机制。

## 二、数据结构和接口设计

#### 1. 数据结构设计

以下结构体定义展示了如何组织管道缓冲区和端点在 uCore 内核中的表示。

```C++
// 管道内部缓冲区数据，位于内核空间
typedef struct uc_pipe_buf {
    char *data;              // 数据缓冲区指针（内核地址）
    size_t size;             // 缓冲区总大小
    size_t read_pos;         // 当前读位置索引
    size_t write_pos;        // 当前写位置索引
    bool full;               // 缓冲区是否已满标志
} uc_pipe_buf_t;

// 管道主对象：管理环缓存与同步
typedef struct uc_pipe {uc_pipe_buf_t buf;       // 管道缓冲区
    spinlock_t lock;         // 自旋锁保护缓冲区
    wait_queue_head_t read_q; // 等待读队列
    wait_queue_head_t write_q;// 等待写队列
    int ref_readers;         // 读端引用计数
    int ref_writers;         // 写端引用计数
} uc_pipe_t;

// 管道端（读/写端）映射为文件描述符关联对象
typedef struct uc_pipe_end {uc_pipe_t *pipe;         // 所属管道对象
    bool can_read;           // 是否可读
    bool can_write;          // 是否可写
} uc_pipe_end_t;
```

**结构体说明与用途：**

* `uc_pipe_buf_t` 定义了缓冲区的基本内存布局和位置索引，用于追踪管道中Byte流的数据。
* `uc_pipe_t` 是主要的Pipe对象：包含缓冲区、锁、进程等待队列与引用计数，用于多个进程安全共享。
* `uc_pipe_end_t` 表示文件描述符层面的接口，每个返回给用户的 fd 都关联一个端（读或写）。
* `spinlock_t` 用于保护多个 CPU/线程并发访问缓冲区状态。
* `wait_queue_head_t` 用于阻塞进程：当读端无数据时阻塞读者，当写端缓冲区满时阻塞写者。

#### 2. 接口设计与语义
| 接口名称                                                                       | 语义说明                                                             |
| -------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| `int uc_pipe_create(uc_pipe_end_t ends[2])`                                | 创建一个管道，返回一对读/写端对象。                                  |
| `ssize_t uc_pipe_read(uc_pipe_end_t *end, void *buf, size_t count)`        | 从管道读取最多`count`字节；若无数据则阻塞（或返回 0 表示 EOF）。 |
| `ssize_t uc_pipe_write(uc_pipe_end_t *end, const void *buf, size_t count)` | 写入数据到管道；缓冲区满则阻塞或返回写入字节数。                     |
| `int uc_pipe_close_end(uc_pipe_end_t *end)`                                | 关闭某个端；维护引用计数，最后一个端关闭释放管道。                   |


**接口语义细节：**

* ​**创建**​: 分配 `uc_pipe_t` 并初始化缓冲区、锁、等待队列；返回两个端的句柄。
* ​**读/写**​: 在 `uc_pipe_t` 保护下对 `data` 环形缓冲的相应位置读/写。空与满条件为阻塞点。
* ​**关闭**​: 每次调用减少引用计数，如 `ref_readers` 或 `ref_writers` 为 0 时清理内存。

## 三、同步互斥问题的处理

由于我们没有完成lab7，这里先对可能会遇到的同步互斥问题进行简单介绍：

1. #### 同步互斥

多个进程或线程可能同时对同一个管道执行 `read`/`write` 操作；不加锁的话会导致读写冲突、数据丢失、不一致或竞态。特别是在缓冲区读指针与写指针移动时、缓冲区状态判断（空 vs 满）时需要原子性操作。

2. #### 设计如何解决同步问题

* 对管道核心结构 `uc_pipe_t` 使用 ​**自旋锁 (`spinlock_t`**​​**)**​，使得对缓冲区状态、索引更新等都在临界区内完成。
* 使用 ​**等待队列 (`wait_queue_head_t`**​​**)**​：当缓冲区空时阻塞读者，在写者写入新数据后唤醒读者；当缓冲区满时阻塞写者，在读者读取后唤醒写者。
* 对引用计数也使用原子更新，确保 `close` 正确触发资源释放。

这样设计保证了 ​**线程/进程间对共享 pipe 状态的一致性与正确顺序访问**​。

# 扩展练习 Challenge2：完成基于“UNIX的软连接和硬连接机制”的设计方案

> 如果要在ucore里加入UNIX的软连接和硬连接机制，至少需要定义哪些数据结构和接口？（接口给出语义即可，不必具体实现。数据结构的设计应当给出一个（或多个）具体的C语言struct定义。在网络上查找相关的Linux资料和实现，请在实验报告中给出设计实现”UNIX的软连接和硬连接机制“的概要设方案，你的设计应当体现出对可能出现的同步互斥问题的处理。）

## 一、软连接和硬连接机制介绍

在 UNIX/Linux 文件系统中：

* ​**硬连接（Hard Link）**​：多个目录项指向同一个 inode，即文件数据结构。删除一个链接只是减少 inode 的引用计数；只要还有链接存在数据仍然保留。
* ​**软连接（Symbolic/Soft Link）**​：是一个特殊类型的文件，其内容为另一个文件的路径名。软链接可跨文件系统，但如果目标被删除则成为悬挂链接。

## 二、数据结构与接口设计

1. #### 数据结构定义

```C++
// 扩展 inode 结构以支持链接计数
typedef struct inode {
    uint32_t i_mode;         // 文件类型、权限和标志
    uint32_t i_nlink;        // 硬链接计数（这个在磁盘的inode原本有实现）
    ...// 其他 inode 成员
} uc_inode_t;

// 软链接文件的特殊内容表示
typedef struct uc_symlink {
    uc_inode_t *inode;       // 软链接的 inode
    char *target_path;       // 目标路径字符串
} uc_symlink_t;
```

**说明：**

* `i_nlink` 用于记录硬链接数量；每创建一个硬链接该计数 +1。
* 软链接本身是一个 inode 但其数据指向一个路径，因此特设 `uc_symlink_t` 结构保存目标字符串。

2. #### 接口设计及语义
| 接口名称                                                            | 语义说明                                                       |
| --------------------------------------------------------------- | ---------------------------------------------------------- |
| `int uc_link(const char *oldpath, const char *newpath)`         | 创建硬链接：在目标目录中新建一个目录项指向 `oldpath` 所在 inode；inode->i_nlink++。 |
| `int uc_unlink(const char *path)`                               | 删除文件/链接：移除目录项；对硬链接减少 `i_nlink`，若为 0 则删除 inode。             |
| `int uc_symlink(const char *target, const char *linkpath)`      | 创建软链接：在文件系统中新建一个特殊 inode，其数据为指向 `target` 的路径。              |
| `ssize_t uc_readlink(const char *path, char *buf, size_t size)` | 读取软链接的目标路径字符串到用户缓冲。                                        |

**语义细节：**

* `uc_link` 不允许目录的硬链接（避免循环），且不能跨文件系统。
* 软链接可跨文件系统，无须目标存在，但后续访问时需判断。
* 删除软链接时只影响链接本身，不减少原 inode 的硬链接计数。

## 三、同步互斥问题的处理

尽管软/硬链接比管道机制没有同等的高并发缓冲访问，但仍存在共享元数据（inode）更新的竞态：

* **引用计数与目录结构的修改**可能由多个进程同时触发（比如同时删除多个硬链接），因此对 `i_nlink` 和目录项列表需加锁。
* 设计时可以在 inode 上添加 ​**inode 锁**​（如互斥锁）以及在目录上使用 **目录锁** 保护目录条目列表的增删改。

这些同步措施确保：更新链接计数和修改目录结构时的原子性与一致性。

# 扩展练习相关的参考资料链接：

## Challenge1

* https://blog.csdn.net/jinking01/article/details/120558894
* https://www.cnblogs.com/biyeymyhjob/archive/2012/11/03/2751593.html
* https://blog.csdn.net/cheng\_lin0201/article/details/129949364

## Challenge2

* https://blog.csdn.net/qq\_28877125/article/details/135147552
* https://gnu-linux.readthedocs.io/zh/latest/Chapter03/00\_link.html
* https://www.answerywj.com/2016/08/02/link-in-linux/#/%E7%BC%BA%E7%82%B9
