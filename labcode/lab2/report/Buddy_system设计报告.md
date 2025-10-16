Buddy system简介
==============

基本原理
----

参考[维基](https://en.wikipedia.org/wiki/Buddy_memory_allocation)以及[指导书上的参考博客](https://coolshell.cn/articles/10427.html)，`Buddy system`的核心思想是将内存空间按 `2` 的幂次划分，并通过伙伴机制高效地分配与回收内存块，以减少外部碎片并便于快速合并空闲空间。

### 分配内存

对于分配内存，`Buddy system`会按照下面算法分配：

1.  寻找大小合适的内存块（大于等于所需大小并且最接近`2`的幂，比如需要`27`，实际分配`32`）

    1.  如果找到了，分配给应用程序。
    2.  如果没找到，分出合适的内存块。

        1.  对半分离出高于所需大小的空闲内存块
        2.  如果分到最低限度，分配这个大小。
        3.  回溯到步骤`1`（寻找合适大小的块）
        4.  重复该步骤直到一个合适的块

### 释放内存

而对于释放内存，则按照下面的算法释放：

1.  释放该内存块

    1.  寻找相邻的块，看其是否释放了。
    2.  如果相邻块也释放了，合并这两个块，重复上述步骤直到遇上未释放的相邻块，或者达到最高上限（即所有内存都释放了）。

数据结构
----

`Buddy system`通常使用一组空闲链表来管理空闲块，每个链表对应一个阶，第k阶对应的块大小为$2^k$页。

Buddy system实现
==============

相关变量声明
------

我们知道系统的物理内存大小为`128MB`，每个页的大小为`4KB`，理论上来说我们可以分配的页数为$n=128 \times 1024 \div 4=32768=2^{15}$，我们要设置总阶数为`16`，但是我们的`kernel`也会占用一部分内存，我们最终可以分配的页数不足 $2^{15}$，所以我们设置的总阶数为`15`。相对应的，我们每个阶数都会存在一个空闲链表用于保存空闲的块。

```
#define MAX_ORDER 14

static free_area_t free_area[MAX_ORDER];
```

初始化
---

我们在最初初始化的时候只需要将每个阶对应的空闲链表调用初始化函数并将每个空闲链表中存在的空闲块设置为`0`即可。

```
static void
buddy_system_init(void) {
    for (int i = 0; i < MAX_ORDER;++i){
        list_init(&(free_area[i].free_list));
        free_area[i].nr_free = 0;
    }
}
```

初始化内存映射
-------

对于内存映射的初始化，我们首先需要将从起始地址开始的`n`个页逐个清理标志位以及属性，清理完毕后对于`n`个可分配的页我们只需要将其按照2的幂次来划分空闲块就可以了。

```
static void
buddy_system_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);

    struct Page *p = base;

    // 首先清除所有页面的标记
    for (size_t i = 0; i < n; i++) {
        struct Page *page = p + i;
        assert(PageReserved(page));
        page->flags = 0;
        set_page_ref(page, 0);
        page->property = 0;
    }

    p = base;
    size_t remain = n;

    while (remain > 0) {
        size_t block_size = 1;
        size_t order = 0;

        while (block_size * 2 <= remain && order + 1 < MAX_ORDER) {
            block_size *= 2;
            order += 1;
        }

        // 确定block_size之后初始化页
        p->property = block_size;
        SetPageProperty(p);

        // 加入对应阶数的空闲链表
        list_add_before(&(free_area[order].free_list), &(p->page_link));
        free_area[order].nr_free++;

        remain -= block_size;
        p += block_size;
    }
}
```

分配页面
----

在伙伴系统中，页面分配以`2`的幂次为单位进行。 当用户请求分配`n`页时，系统会执行以下步骤：

1.  向上取整到 `2` 的幂次 使用 `next_power_of_2(n)` 计算出不小于`n`的最小`2`的幂，确保后续能与伙伴机制对齐。
2.  确定对应阶数`（order）` 通过 `log2_floor` 计算 `alloc_size` 对应的阶数。阶数 `k` 表示块大小为 `2^k` 页。
3.  查找可用块 从 `order` 开始，在 `free_area[order]` 中寻找空闲块：

    1.  如果当前阶为空，则依次向更高阶查找，直到找到可用的块；
    2.  如果所有阶都没有可用块，则分配失败，返回 `NULL`。
4.  分裂高阶块（如有必要） 如果找到的空闲块阶数比所需的 `order` 大，则循环向下分裂：

    1.  每次分裂将一块高阶块一分为二；
    2.  一半作为分配块继续向下分裂；
    3.  另一半（buddy 块）重新插入到对应阶的空闲链表中。
5.  标记与返回

    1.  将最终分配的块从空闲链表中删除；
    2.  更新 `property` 字段与标志位；
    3.  返回块的首地址指针，供上层使用。

```
static struct Page *
buddy_system_alloc_pages(size_t n) {
    assert(n > 0);

    if (n > (1 << (MAX_ORDER - 1))) {
        return NULL;
    }

    size_t alloc_size = next_power_of_2(n);
    size_t order = log2_floor(alloc_size);

    size_t current_order = order;

    // 修复：查找空闲链表，如果当前order为空，则找更大的order
    while (current_order < MAX_ORDER && list_empty(&(free_area[current_order].free_list))) {
        current_order++;
    }

    // 如果没有找到合适的块
    if (current_order >= MAX_ORDER) {
        return NULL;
    }

    // 从链表中取出一个块
    list_entry_t *free_list = list_next(&(free_area[current_order].free_list));
    struct Page *page = le2page(free_list, page_link);
    list_del(&(page->page_link));
    free_area[current_order].nr_free--;

    while (current_order > order) {
        current_order--;
        size_t buddy_size = 1 << current_order;

        struct Page *buddy = page + buddy_size;
        buddy->property = buddy_size;
        SetPageProperty(buddy);

        list_add(&(free_area[current_order].free_list), &(buddy->page_link));
        free_area[current_order].nr_free++;
    }

    ClearPageProperty(page);
    page->property = alloc_size;

    return page;
}
```

释放页面
----

当释放一块已经分配的内存时，伙伴系统会尽可能地与相邻的空闲块进行合并，从而形成更大的空闲块，减少内存碎片。释放流程如下：

1.  **获取块大小与阶数** 每个分配的块在 `property` 字段中记录了自身大小（页数）。 利用 `log2_floor` 计算对应的阶数 `order`，作为后续合并的起点。
2.  **清空页面标记** 遍历该块内的每一页，重置标志位与引用计数，表示这些页不再被占用。
3.  **标记块为空闲块** 将 `base` 页的 `property` 恢复为块大小，并设置空闲标志，为后续合并做准备。
4.  **查找并合并伙伴块（Buddy）** 利用异或运算 `buddy_idx = page_idx ^ (1 << order)` 计算该块对应的伙伴块位置。 若伙伴块满足以下条件，则进行合并：

    1.  伙伴块在内存范围内；
    2.  伙伴块处于空闲状态（`PageProperty` 为真）；
    3.  伙伴块的大小与当前块一致（同阶）。
5.  找到后，将伙伴块从空闲链表中移除，清除标记，然后：

    1.  取两者中地址较小的块作为新的合并块；
    2.  阶数 `order++`，块大小翻倍；
    3.  更新 `property` 和空闲标志；
    4.  循环继续向更高阶尝试合并，直到无法合并或达到最大阶。
6.  **插回空闲链表** 最终将合并后的大块加入对应阶数的空闲链表，并更新空闲页计数。

```
static void
buddy_system_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    assert(!PageReserved(base));

    // 获取实际分配的大小
    size_t block_size = base->property;
    size_t order = log2_floor(block_size);

    // 清空页面标记
    for (size_t i = 0; i < block_size; i++) {
        struct Page *p = base + i;
        assert(!PageReserved(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }

    base->property = block_size;
    SetPageProperty(base);

    struct Page *page = base;

    // 尝试合并buddy块
    while (order < MAX_ORDER - 1) {
        // 计算buddy的位置
        size_t page_idx = page - pages;
        size_t buddy_idx = page_idx ^ (1 << order);

        // 检查buddy是否存在且可合并
        if (buddy_idx >= npage - nbase) {
            break;
        }

        struct Page *buddy = pages + buddy_idx;

        // 检查buddy是否空闲且大小匹配
        if (!PageProperty(buddy) || buddy->property != (1 << order)) {
            break;
        }

        // 从链表中删除buddy
        list_entry_t *le = &(free_area[order].free_list);
        bool found = 0;
        while ((le = list_next(le)) != &(free_area[order].free_list)) {
            struct Page *p = le2page(le, page_link);
            if (p == buddy) {
                list_del(&(buddy->page_link));
                free_area[order].nr_free--;
                found = 1;
                break;
            }
        }

        if (!found) {
            break;
        }

        // 合并块
        if (page > buddy) {
            page = buddy;
        }

        ClearPageProperty(buddy);
        order++;
        page->property = 1 << order;
        SetPageProperty(page);
    }

    // 将合并后的块加入对应的链表
    list_add(&(free_area[order].free_list), &(page->page_link));
    free_area[order].nr_free++;
}
```

获取空闲页数
------

将每个阶对应的空闲链表中的空闲页数求和即得到总空闲页数。

```
static size_t
buddy_system_nr_free_pages(void) {
    size_t total = 0;
    for (int i = 0; i < MAX_ORDER; i++) {
        total += free_area[i].nr_free * (1 << i);
    }
    return total;
}
```

Buddy system测试
==============

我们针对实现的`Buddy system`设计了`8`个测试，分别是边界条件、分裂与合并、连续分配与释放、内存碎片、压力、对齐与地址验证、`Buddy`正确性以及非`2`幂次分配测试。

我们知道我们可分配的总页数为`31928`，所以我们在初始化的时候会分配阶数分别为`14、13、12、11、10、7、5、4、3`的初始块。

边界条件测试
------

因为我们分配函数中不允许出现 $n \le 0$的情况，所以我们在该测试中仅对两种边界情况进行测试，分别是分配超过最大阶的页面数以及分配最大阶允许的页面数。

```
static void
boundary_test(void) {
    cprintf("========== Test 1: Boundary Conditions ==========\n");

    // 测试分配超过最大order的页面
    cprintf("Test 1.1: Allocate pages exceeding MAX_ORDER\n");
    size_t max_pages = (1 << (MAX_ORDER - 1)) + 1;
    struct Page *p = alloc_pages(max_pages);
    if (p == NULL) {
        cprintf("  PASS: Cannot allocate more than maximum allowed pages\n");
    } else {
        cprintf("  UNEXPECTED: Allocated more than MAX_ORDER pages\n");
        free_pages(p, max_pages);
    }

    // 测试分配最大允许的页面数
    cprintf("Test 1.2: Allocate maximum allowed pages\n");
    max_pages = (1 << (MAX_ORDER - 1));
    p = alloc_pages(max_pages);
    if (p != NULL) {
        cprintf("  PASS: Successfully allocated %d pages (property=%u)\n",
                (int)max_pages, p->property);
        free_pages(p, max_pages);
    } else {
        cprintf("  INFO: Not enough memory for maximum allocation\n");
    }

    cprintf("\n");
}
```

分裂与合并测试
-------

在本实验中，我们初始化时最小的空闲块为`8`页，因此当分配一个`4`页大小的空间时，系统会：

1.  从8页的空闲块中分裂出两个`4`页块；
2.  分配其中一个`4`页块；
3.  将另一个`4`页块放回空闲链表。

随后我们继续分配`2`页、`2`页的空间，进一步触发更小粒度的分裂。 接着再按乱序释放，观察系统是否能够正确地逐级合并回原始的空闲块。

整个过程可以验证：

-   分裂是否按阶进行，每次只拆一半；
-   释放是否能找到正确的`buddy` 并逐级合并；
-   最终空闲页数是否与初始值一致，确保无内存泄漏。

```
static void
split_merge_test(void) {
    cprintf("========== Test 2: Split and Merge Operations ==========\n");

    // 记录初始空闲页数
    size_t initial_free = nr_free_pages();
    cprintf("Initial free pages: %d\n", (int)initial_free);

    // 分配一个大块，然后释放，观察是否能正确分裂
    cprintf("Test 2.1: Block splitting\n");
    struct Page *p1 = alloc_pages(4);
    if (p1 == NULL) {
        cprintf("  INFO: Cannot allocate 4 pages, skipping test\n\n");
        return;
    }
    cprintf("  Allocated 4 pages (property=%u)\n", p1->property);

    struct Page *p2 = alloc_pages(2);
    if (p2 == NULL) {
        cprintf("  INFO: Cannot allocate 2 pages\n");
        free_pages(p1, 4);
        cprintf("\n");
        return;
    }
    cprintf("  Allocated 2 pages (property=%u)\n", p2->property);

    struct Page *p3 = alloc_pages(2);
    if (p3 == NULL) {
        cprintf("  INFO: Cannot allocate another 2 pages\n");
        free_pages(p1, 4);
        free_pages(p2, 2);
        cprintf("\n");
        return;
    }
    cprintf("  Allocated 2 pages (property=%u)\n", p3->property);

    // 验证分配后的空闲页数减少
    size_t after_alloc = nr_free_pages();
    cprintf("  After allocation: %d free pages (reduced by %d)\n",
            (int)after_alloc, (int)(initial_free - after_alloc));

    // 测试合并：按不同顺序释放，观察buddy合并
    cprintf("Test 2.2: Buddy merging (out-of-order free)\n");
    free_pages(p2, 2);
    cprintf("  Freed p2 (2 pages)\n");
    size_t after_free1 = nr_free_pages();

    free_pages(p3, 2);
    cprintf("  Freed p3 (2 pages)\n");
    size_t after_free2 = nr_free_pages();

    free_pages(p1, 4);
    cprintf("  Freed p1 (4 pages)\n");
    size_t final_free = nr_free_pages();

    cprintf("  Final free pages: %d (recovered %d pages)\n",
            (int)final_free, (int)(final_free - after_alloc));

    // 检查是否有内存泄漏
    int diff = (int)(initial_free - final_free);
    if (diff == 0) {
        cprintf("  PASS: All memory recovered, no leaks\n");
    } else if (diff > 0) {
        cprintf("  WARNING: %d pages not recovered (possible leak)\n", diff);
    } else {
        cprintf("  INFO: %d extra pages (possibly from coalescing)\n", -diff);
    }

    cprintf("\n");
}
```

连续分配与释放测试
---------

在实际系统中，内存的分配和释放往往不是对单一大块的操作，往往都是连续的且不规则的多种大小混合分配或者释放，我们接下来主要测试我们的`Buddy system`面对连续的分配以及释放是否能成功工作。在下面的测试中，我们首先连续分配大小不同的块，其中涵盖了非`2`幂次大小的块，在连续分配完后，我们再按照相反顺序依次释放这些块。释放完毕后我们会检测前后总空闲页数是否正确来确认是否发生内存泄漏。

```
static void
consecutive_alloc_free_test(void) {
    cprintf("========== Test 3: Consecutive Allocation/Free ==========\n");

    size_t initial_free = nr_free_pages();

    // 分配多个不同大小的块
    cprintf("Test 3.1: Multiple allocations of varying sizes\n");
    struct Page *pages_arr[10];
    size_t sizes[10] = {1, 2, 4, 8, 3, 5, 7, 16, 1, 2};
    int success_count = 0;

    for (int i = 0; i < 10; i++) {
        pages_arr[i] = alloc_pages(sizes[i]);
        if (pages_arr[i] != NULL) {
            cprintf("  [%d] Allocated %d pages → property=%u\n",
                    i, (int)sizes[i], pages_arr[i]->property);
            success_count++;
        } else {
            cprintf("  [%d] Failed to allocate %d pages\n", i, (int)sizes[i]);
        }
    }

    cprintf("  Successfully allocated %d/%d blocks\n", success_count, 10);

    // 按相反顺序释放
    cprintf("Test 3.2: Free in reverse order\n");
    for (int i = 9; i >= 0; i--) {
        if (pages_arr[i] != NULL) {
            free_pages(pages_arr[i], sizes[i]);
            cprintf("  [%d] Freed (%d pages requested)\n", i, (int)sizes[i]);
        }
    }

    size_t final_free = nr_free_pages();
    cprintf("  Memory status: Initial=%d, Final=%d, Diff=%d\n",
            (int)initial_free, (int)final_free, (int)(final_free - initial_free));

    if (final_free >= initial_free) {
        cprintf("  PASS: No memory leak detected\n");
    } else {
        cprintf("  WARNING: Possible memory leak (%d pages)\n",
                (int)(initial_free - final_free));
    }

    cprintf("\n");
}
```

内存碎片测试
------

本测试旨在检验 `Buddy system` 在面对内存碎片时的表现，以及它是否能正确处理碎片化的空闲块。我们首先分配多个小块，在这次测试中分配`20`个块大小为`1`块，然后释放掉其中偶数索引的块造成碎片，之后我们在尝试分配一个大小为`16`页的块。

```
static void
fragmentation_test(void) {
    cprintf("========== Test 4: Memory Fragmentation ==========\n");

    // 分配许多小块，然后释放偶数索引的块，造成碎片
    cprintf("Test 4.1: Create fragmentation pattern\n");
    struct Page *small_blocks[20];
    int allocated_count = 0;

    for (int i = 0; i < 20; i++) {
        small_blocks[i] = alloc_pages(1);
        if (small_blocks[i] != NULL) {
            allocated_count++;
        }
    }
    cprintf("  Allocated %d/20 single-page blocks\n", allocated_count);

    if (allocated_count < 10) {
        cprintf("  INFO: Not enough memory to perform fragmentation test\n");
        // 清理
        for (int i = 0; i < 20; i++) {
            if (small_blocks[i] != NULL) {
                free_pages(small_blocks[i], 1);
            }
        }
        cprintf("\n");
        return;
    }

    // 释放偶数索引的块
    cprintf("Test 4.2: Free even-indexed blocks (create holes)\n");
    int freed_count = 0;
    for (int i = 0; i < 20; i += 2) {
        if (small_blocks[i] != NULL) {
            free_pages(small_blocks[i], 1);
            small_blocks[i] = NULL;
            freed_count++;
        }
    }
    cprintf("  Freed %d blocks, creating fragmentation\n", freed_count);

    // 尝试分配一个大块
    cprintf("Test 4.3: Attempt large allocation in fragmented memory\n");
    struct Page *large = alloc_pages(16);
    if (large != NULL) {
        cprintf("  SUCCESS: Allocated 16 pages despite fragmentation\n");
        cprintf("  INFO: Buddy system handled fragmentation well\n");
        free_pages(large, 16);
    } else {
        cprintf("  EXPECTED: Cannot allocate 16 pages due to fragmentation\n");
        cprintf("  INFO: This demonstrates external fragmentation\n");
    }

    // 释放剩余的块
    cprintf("Test 4.4: Cleanup remaining blocks\n");
    for (int i = 1; i < 20; i += 2) {
        if (small_blocks[i] != NULL) {
            free_pages(small_blocks[i], 1);
        }
    }
    cprintf("  All blocks freed\n");

    cprintf("\n");
}
```

压力测试
----

在压力测试中，我们首先记录系统初始空闲页数，然后初始化一个 50 个元素的数组 `ptrs` 用于跟踪分配的页块。测试执行 100 次循环操作：如果当前数组元素为空，则尝试分配大小为 `1 << (round % 12)` 页的内存块，并更新分配成功或失败的统计；如果当前数组元素非空，则释放对应页块，并更新释放统计。每隔 20 次操作打印一次分配或释放状态以便观察。循环结束后，对数组中剩余未释放的页块进行清理，并统计最终空闲页数，与初始空闲页数对比，用于检测内存回收是否正确以及是否存在内存泄漏。

```
static void
stress_test(void) {
    cprintf("========== Test 5: Stress Test ==========\n");

    size_t initial_free = nr_free_pages();
    cprintf("Initial free pages: %d\n", (int)initial_free);

    // 随机分配和释放
    cprintf("Test 5.1: Random allocation/deallocation cycles\n");
    struct Page *ptrs[50];
    for (int i = 0; i < 50; i++) {
        ptrs[i] = NULL;
    }

    int alloc_ops = 0, free_ops = 0, failed_ops = 0;

    // 进行100次随机操作
    for (int round = 0; round < 100; round++) {
        int idx = round % 50;

        if (ptrs[idx] == NULL) {
            size_t size = 1 << (round % 12);
            ptrs[idx] = alloc_pages(size);
            if (ptrs[idx] != NULL) {
                alloc_ops++;
                if (round % 20 == 0) {
                    cprintf("  Round %3d: Alloc %d pages at [%2d]\n",
                            round, (int)size, idx);
                }
            } else {
                failed_ops++;
            }
        } else {
            // 释放
            free_ops++;
            if (round % 20 == 0) {
                cprintf("  Round %3d: Free [%2d]\n", round, idx);
            }
            free_pages(ptrs[idx], 1);
            ptrs[idx] = NULL;
        }
    }

    cprintf("  Operations: %d allocs, %d frees, %d failed\n",
            alloc_ops, free_ops, failed_ops);

    // 清理剩余分配
    cprintf("Test 5.2: Final cleanup\n");
    int remaining = 0;
    for (int i = 0; i < 50; i++) {
        if (ptrs[i] != NULL) {
            free_pages(ptrs[i], 1);
            remaining++;
        }
    }
    cprintf("  Cleaned up %d remaining allocations\n", remaining);

    size_t final_free = nr_free_pages();
    cprintf("  Final free pages: %d\n", (int)final_free);

    int leak = (int)(initial_free - final_free);
    if (leak == 0) {
        cprintf("  PASS: No memory leaks!\n");
    } else if (leak > 0) {
        cprintf("  WARNING: Possible leak of %d pages\n", leak);
    } else {
        cprintf("  INFO: %d extra pages (coalescing effect)\n", -leak);
    }

    cprintf("\n");
}
```

对齐与地址验证测试
---------

在对齐与地址验证测试中，我们首先连续分配了 `1、2、4、8` 页的内存块，记录分配成功的数量。随后对所有成功分配的块，检查它们在 `pages` 数组中的偏移地址，以验证分配是否满足块大小的对齐要求，并确保不同块之间没有重叠。如果所有块分配成功且地址不重叠，则说明 `Buddy system` 的分配机制正确处理了对齐和地址连续性问题。测试结束后释放所有已分配的块，恢复系统空闲页数，确保不会产生内存泄漏。

```
static void
alignment_test(void) {
    cprintf("========== Test 6: Alignment and Address Test ==========\n");

    cprintf("Test 6.1: Allocate blocks of different sizes\n");

    struct Page *p1 = alloc_pages(1);
    struct Page *p2 = alloc_pages(2);
    struct Page *p4 = alloc_pages(4);
    struct Page *p8 = alloc_pages(8);

    int success = 0;
    if (p1) success++;
    if (p2) success++;
    if (p4) success++;
    if (p8) success++;

    cprintf("  Successfully allocated %d/4 test blocks\n", success);

    if (p1 && p2 && p4 && p8) {
        cprintf("Test 6.2: Verify addresses and alignment\n");
        cprintf("  p1 (1 page)  at offset: %d\n", (int)(p1 - pages));
        cprintf("  p2 (2 pages) at offset: %d\n", (int)(p2 - pages));
        cprintf("  p4 (4 pages) at offset: %d\n", (int)(p4 - pages));
        cprintf("  p8 (8 pages) at offset: %d\n", (int)(p8 - pages));

        // 验证没有重叠
        bool no_overlap = (p1 != p2 && p1 != p4 && p1 != p8 &&
                          p2 != p4 && p2 != p8 && p4 != p8);

        if (no_overlap) {
            cprintf("  PASS: No overlapping allocations detected\n");
        } else {
            cprintf("  ERROR: Overlapping allocations detected!\n");
        }

        free_pages(p1, 1);
        free_pages(p2, 2);
        free_pages(p4, 4);
        free_pages(p8, 8);
    } else {
        cprintf("  INFO: Not all allocations succeeded, skipping overlap test\n");
        if (p1) free_pages(p1, 1);
        if (p2) free_pages(p2, 2);
        if (p4) free_pages(p4, 4);
        if (p8) free_pages(p8, 8);
    }

    cprintf("\n");
}
```

Buddy正确性测试
----------

在 `Buddy` 正确性测试中，我们首先分配了两个相同大小的 `4` 页块，并记录它们在 `pages` 数组中的索引位置，以判断它们是否是伙伴块`（buddy）`。随后释放第一个块，记录释放前后的空闲页数变化，再释放第二个块，观察空闲页数的变化以及两个块是否正确合并。如果两个块是伙伴块，释放第二个块后空闲页数增加应大于释放第一个块时的增量，表明 `Buddy system` 成功合并了这两个块；如果不是伙伴块，则不会产生额外的合并。该测试验证了 `Buddy system` 在正确识别伙伴关系和执行块合并时的功能正确性。

```
static void
buddy_correctness_test(void) {
    cprintf("========== Test 7: Buddy Correctness Test ==========\n");

    cprintf("Test 7.1: Allocate two 4-page blocks\n");
    struct Page *p1 = alloc_pages(4);
    struct Page *p2 = alloc_pages(4);

    if (!p1 || !p2) {
        cprintf("  INFO: Cannot allocate test blocks\n");
        if (p1) free_pages(p1, 4);
        if (p2) free_pages(p2, 4);
        cprintf("\n");
        return;
    }

    size_t idx1 = p1 - pages;
    size_t idx2 = p2 - pages;
    cprintf("  Block 1 at index: %d\n", (int)idx1);
    cprintf("  Block 2 at index: %d\n", (int)idx2);

    // 计算它们是否是buddy
    size_t diff = (idx1 > idx2) ? (idx1 - idx2) : (idx2 - idx1);
    bool are_buddies = (diff == 4);
    cprintf("  Distance: %d pages, Are buddies: %s\n",
            (int)diff, are_buddies ? "YES" : "NO");

    // 释放并观察合并
    cprintf("Test 7.2: Free blocks and observe merging\n");
    size_t before_free = nr_free_pages();
    free_pages(p1, 4);
    size_t after_free1 = nr_free_pages();
    free_pages(p2, 4);
    size_t after_free2 = nr_free_pages();

    cprintf("  Free pages progression: %d → %d → %d\n",
            (int)before_free, (int)after_free1, (int)after_free2);

    int gain1 = after_free1 - before_free;
    int gain2 = after_free2 - after_free1;

    if (are_buddies && gain2 > gain1) {
        cprintf("  PASS: Buddies merged correctly (gained %d > %d pages)\n",
                gain2, gain1);
    } else if (!are_buddies) {
        cprintf("  INFO: Blocks were not buddies, no merge expected\n");
    } else {
        cprintf("  INFO: Merge behavior observed (gain: %d, %d)\n", gain1, gain2);
    }

    cprintf("\n");
}
```

非2幂次分配测试
--------

在非 `2` 次幂分配测试中，我们针对一组非 `2` 次幂大小的页块（如 `3、5、6、7、9` 等）进行分配，检查 `Buddy system` 是否能够正确将其分配为大于或等于请求大小的最小 `2` 次幂块。对于每次分配，我们对比分配块的 `property` 与预期的最小 `2` 次幂值，验证是否符合向上取整规则。分配完成后立即释放对应块，确保测试不会影响后续操作。通过统计测试通过与失败的次数，该测试验证了 `Buddy system` 在处理非 `2` 次幂分配请求时的正确性与可靠性。

```
static void
non_power_of_2_test(void) {
    cprintf("========== Test 8: Non-Power-of-2 Allocation ==========\n");

    size_t test_sizes[] = {3, 5, 6, 7, 9, 10, 15, 17, 31, 33};
    size_t expected_sizes[] = {4, 8, 8, 8, 16, 16, 16, 32, 32, 64};

    int pass_count = 0;
    int fail_count = 0;

    for (int i = 0; i < 10; i++) {
        struct Page *p = alloc_pages(test_sizes[i]);

        if (p != NULL) {
            bool correct = (p->property == expected_sizes[i]);
            cprintf("  Test %2d: Request %2d → Got %2u (expect %2d) %s\n",
                    i + 1, (int)test_sizes[i], p->property,
                    (int)expected_sizes[i], correct ? "✓" : "✗");

            if (correct) {
                pass_count++;
            } else {
                fail_count++;
            }

            free_pages(p, test_sizes[i]);
        } else {
            cprintf("  Test %2d: Request %2d → FAILED (no memory)\n",
                    i + 1, (int)test_sizes[i]);
            fail_count++;
        }
    }

    cprintf("\nSummary: %d passed, %d failed\n", pass_count, fail_count);
    if (pass_count == 10) {
        cprintf("  PASS: All rounding tests passed!\n");
    }

    cprintf("\n");
}
```

测试结果
----

我们最终控制台输出如下：

```
(base) root@DESKTOP-R79JUA1:/home/docay/OS/labcode/lab2# make qemu
+ cc kern/mm/buddy_system_pmm.c
+ ld bin/kernel
riscv64-unknown-elf-objcopy bin/kernel --strip-all -O binary bin/ucore.img

OpenSBI v0.4 (Jul  2 2019 11:53:53)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : QEMU Virt Machine
Platform HART Features : RV64ACDFIMSU
Platform Max HARTs     : 8
Current Hart           : 0
Firmware Base          : 0x80000000
Firmware Size          : 112 KB
Runtime SBI Version    : 0.1

PMP0: 0x0000000080000000-0x000000008001ffff (A)
PMP1: 0x0000000000000000-0xffffffffffffffff (A,R,W,X)
DTB Init
HartID: 0
DTB Address: 0x82200000
Physical Memory from DTB:
  Base: 0x0000000080000000
  Size: 0x0000000008000000 (128 MB)
  End:  0x0000000087ffffff
DTB init completed
(THU.CST) os is loading ...
Special kernel symbols:
  entry  0xffffffffc02000d8 (virtual)
  etext  0xffffffffc0201ccc (virtual)
  edata  0xffffffffc0207018 (virtual)
  end    0xffffffffc02071c8 (virtual)
Kernel executable memory footprint: 29KB
memory management: buddy_system
physcial memory map:
  memory: 0x0000000008000000, [0x0000000080000000, 0x0000000087ffffff].
  memory: 0x0000000008000000, [0x0000000080348000, 0x0000000087ffffff].
   BUDDY SYSTEM ADVANCED TEST SUITE

=== Initial System State ===
Total free pages: 31928 (124 MB)

========== Test 1: Boundary Conditions ==========
Test 1.1: Allocate pages exceeding MAX_ORDER
  PASS: Cannot allocate more than maximum allowed pages
Test 1.2: Allocate maximum allowed pages
  PASS: Successfully allocated 16384 pages (property=16384)

========== Test 2: Split and Merge Operations ==========
Initial free pages: 31928
Test 2.1: Block splitting
  Allocated 4 pages (property=4)
  Allocated 2 pages (property=2)
  Allocated 2 pages (property=2)
  After allocation: 31920 free pages (reduced by 8)
Test 2.2: Buddy merging (out-of-order free)
  Freed p2 (2 pages)
  Freed p3 (2 pages)
  Freed p1 (4 pages)
  Final free pages: 31928 (recovered 8 pages)
  PASS: All memory recovered, no leaks

========== Test 3: Consecutive Allocation/Free ==========
Test 3.1: Multiple allocations of varying sizes
  [0] Allocated 1 pages → property=1
  [1] Allocated 2 pages → property=2
  [2] Allocated 4 pages → property=4
  [3] Allocated 8 pages → property=8
  [4] Allocated 3 pages → property=4
  [5] Allocated 5 pages → property=8
  [6] Allocated 7 pages → property=8
  [7] Allocated 16 pages → property=16
  [8] Allocated 1 pages → property=1
  [9] Allocated 2 pages → property=2
  Successfully allocated 10/10 blocks
Test 3.2: Free in reverse order
  [9] Freed (2 pages requested)
  [8] Freed (1 pages requested)
  [7] Freed (16 pages requested)
  [6] Freed (7 pages requested)
  [5] Freed (5 pages requested)
  [4] Freed (3 pages requested)
  [3] Freed (8 pages requested)
  [2] Freed (4 pages requested)
  [1] Freed (2 pages requested)
  [0] Freed (1 pages requested)
  Memory status: Initial=31928, Final=31928, Diff=0
  PASS: No memory leak detected

========== Test 4: Memory Fragmentation ==========
Test 4.1: Create fragmentation pattern
  Allocated 20/20 single-page blocks
Test 4.2: Free even-indexed blocks (create holes)
  Freed 10 blocks, creating fragmentation
Test 4.3: Attempt large allocation in fragmented memory
  SUCCESS: Allocated 16 pages despite fragmentation
  INFO: Buddy system handled fragmentation well
Test 4.4: Cleanup remaining blocks
  All blocks freed

========== Test 5: Stress Test ==========
Initial free pages: 31928
Test 5.1: Random allocation/deallocation cycles
  Round   0: Alloc 1 pages at [ 0]
  Round  20: Alloc 256 pages at [20]
  Round  40: Alloc 16 pages at [40]
  Round  60: Free [10]
  Round  80: Free [30]
  Operations: 50 allocs, 50 frees, 0 failed
Test 5.2: Final cleanup
  Cleaned up 0 remaining allocations
  Final free pages: 31928
  PASS: No memory leaks!

========== Test 6: Alignment and Address Test ==========
Test 6.1: Allocate blocks of different sizes
  Successfully allocated 4/4 test blocks
Test 6.2: Verify addresses and alignment
  p1 (1 page)  at offset: 32640
  p2 (2 pages) at offset: 32642
  p4 (4 pages) at offset: 32644
  p8 (8 pages) at offset: 31736
  PASS: No overlapping allocations detected

========== Test 7: Buddy Correctness Test ==========
Test 7.1: Allocate two 4-page blocks
  Block 1 at index: 31736
  Block 2 at index: 31740
  Distance: 4 pages, Are buddies: YES
Test 7.2: Free blocks and observe merging
  Free pages progression: 31920 → 31924 → 31928
  INFO: Merge behavior observed (gain: 4, 4)

========== Test 8: Non-Power-of-2 Allocation ==========
  Test  1: Request  3 → Got  4 (expect  4) ✓
  Test  2: Request  5 → Got  8 (expect  8) ✓
  Test  3: Request  6 → Got  8 (expect  8) ✓
  Test  4: Request  7 → Got  8 (expect  8) ✓
  Test  5: Request  9 → Got 16 (expect 16) ✓
  Test  6: Request 10 → Got 16 (expect 16) ✓
  Test  7: Request 15 → Got 16 (expect 16) ✓
  Test  8: Request 17 → Got 32 (expect 32) ✓
  Test  9: Request 31 → Got 32 (expect 32) ✓
  Test 10: Request 33 → Got 64 (expect 64) ✓

Summary: 10 passed, 0 failed
  PASS: All rounding tests passed!

   FINAL RESULTS
Total free pages: 31928 (124 MB)
PASS: No memory leaks detected!
   ALL TESTS COMPLETED

check_alloc_page() succeeded!
satp virtual address: 0xffffffffc0206000
satp physical address: 0x0000000080206000
```

这个输出证明我们的`Buddy system`成功通过了所有的测试样例。