SLUB分配器设计报告
================

SLUB简介
--------

SLUB（The Unqueued SLAB Allocator）是一种面向对象的内存分配器，主要用于高效分配和回收小对象。它在 Linux 内核中广泛应用，能够减少碎片、提升分配速度，并支持多种 size-class 的对象分配。SLUB 通过将对象分配与页分配分离，复用底层的页分配器（如 buddy system），实现了两层分配架构：页级分配和对象级分配。

基本原理
--------

SLUB 的核心思想是将内存划分为 slab，每个 slab 通常为一页或多页，内部再分割为若干个等大小的对象。对象通过 freelist 链表管理，分配和回收均为 O(1) 操作。SLUB 维护 partial（部分使用）和 full（已满）两类 slab 链表，空 slab 直接释放回底层页分配器，避免维护空 slab 链表。

分配对象流程：

1. 选择合适的 size-class（如 16, 32, 64, ... 2048 字节）。
2. 在 partial 链表中查找有空闲对象的 slab。
3. 若无可用 slab，则新建一个 slab（分配一页）。
4. 从 slab 的 freelist 弹出一个对象，更新 inuse 计数。
5. 若 slab 满，则移入 full 链表。

释放对象流程：

1. 通过对象地址定位所属 slab。
2. 若 slab 在 full 链表，则移回 partial 链表。
3. 对象头插回 freelist，inuse 计数减一。
4. 若 slab 变为空，则释放 slab 回底层页分配器。

数据结构
--------

SLUB 主要数据结构如下：

- `struct slab`：每个 slab 的头部，存放于页起始处，包含 magic 标识、所属 cache、freelist、inuse、objects、链表节点等。
- `struct kmem_cache`：每个 size-class 的管理结构，包含对象大小、对齐、partial/full 链表等。
- `cache_list`：全局所有 cache 的链表。
- `size_caches[]`：常用 size-class 的 cache 数组。

SLUB实现
--------

相关变量声明
------------

SLUB 通过 `SLAB_ORDER` 宏控制 slab 的页数（本实现为单页 slab），每个 slab 的大小为 `SLAB_BYTES = PGSIZE * SLAB_PAGES`。对象分配时按对齐要求分割 slab 空间，freelist 采用对象首部存放 next 指针。

初始化
------

- `slub_init()` 初始化全局 cache 链表和底层 buddy system。
- `init_size_caches()` 初始化常用 size-class 的 cache。

slab创建与释放
-------------

- `slab_new()` 从 buddy system 分配一页，初始化 slab 头部和 freelist。
- `slab_release()` 释放 slab 回 buddy system。

cache管理
---------

- `kmem_cache_create()` 创建新的 cache，分配一页存放 cache 结构体，初始化 partial/full 链表。
- `kmem_cache_destroy()` 回收 cache 所有 slab，并释放 cache 自身。

对象分配与回收
-------------

- `kmem_cache_alloc()` 从 partial slab 分配对象，若 slab 满则移入 full 链表。
- `kmem_cache_free()` 回收对象，若 slab 空则释放回 buddy system。

kmalloc/kfree接口
----------------

- `kmalloc(size)` 根据 size 选择合适的 cache 分配对象，超过 2048 字节直接走页分配。
- `kfree(ptr, size_hint)` 回收对象或页，自动识别对象归属。

页级接口
--------

SLUB 复用 buddy system 的页分配接口，实现 `alloc_pages`、`free_pages`、`nr_free_pages` 等。

测试说明
--------

SLUB 实现包含自检函数 `slub_check()`，覆盖如下测试：

1. 创建 cache 并分配对象，验证 slab 容量和分配正确性。
2. 分配 cap 个对象只产生 1 个 slab，超出则新建 slab。
3. 回收对象后应复用地址（LIFO）。
4. 回收所有对象后 slab 应释放回 buddy system，无内存泄漏。
5. 销毁 cache 后页数回归基线。
6. kmalloc/kfree 路径测试，size-class 命中与页分配均可用。
7. 交错分配/回收，验证健壮性。

测试结果
--------

所有测试均通过，分配与回收无内存泄漏，size-class 和页分配均正常工作，slab 复用 buddy system 页分配器，整体架构清晰，易于扩展。

总结
----

本 SLUB 实现采用单页 slab，复用 buddy system 做页分配，支持常用 size-class 的对象分配，分配/回收均为 O(1)，空 slab 直接释放回页分配器，简化管理。测试覆盖分配、回收、复用、健壮性等场景，验证了实现的正确性和高效性。该设计易于扩展为多页 slab，适合嵌入式和教学场景。
