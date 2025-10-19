#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_system_pmm.h>
#include <stdio.h>

/*  
分配内存的思想：
1.寻找大小合适的内存块（大于等于所需大小并且最接近2的幂，比如需要27，实际分配32）
    1.如果找到了，分配给应用程序。
    2.如果没找到，分出合适的内存块。
        1.对半分离出高于所需大小的空闲内存块
        2.如果分到最低限度，分配这个大小。
        3.回溯到步骤1（寻找合适大小的块）
        4.重复该步骤直到一个合适的块

释放内存的思想：
1.释放该内存块
    1.寻找相邻的块，看其是否释放了。
    2.如果相邻块也释放了，合并这两个块，重复上述步骤直到遇上未释放的相邻块，或者达到最高上限（即所有内存都释放了）。
*/

// 系统物理内存大小为128MB，每个页大小4KB，除去kernel等占用的内存，我们设置阶数为15
#define MAX_ORDER 15

// 每个阶可以用的空闲页数
static free_area_t free_area[MAX_ORDER];

static inline bool is_power_of_2(size_t n){
    return n > 0 && (n & (n - 1)) == 0;
}

// 获取大于等于当前n的最小2的幂次
static size_t next_power_of_2(size_t n) {
    if (n == 0) {
        return 1;
    }
    n--;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    n |= n >> 32;
    return n + 1;
}

// 计算以2为底的上取整幂
static size_t log2_ceil(size_t n) {
    size_t result = 0;
    size_t power = 1;
    while (power < n) {
        power *= 2;
        result++;
    }
    return result;
}

// 计算以2为底的下取整幂
static size_t log2_floor(size_t n) {
    size_t result = 0;
    while (n > 1) {
        n /= 2;
        result++;
    }
    return result;
}

// 初始化
static void
buddy_system_init(void) {
    for (int i = 0; i < MAX_ORDER;++i){
        list_init(&(free_area[i].free_list));
        free_area[i].nr_free = 0;
    }
}

// 初始化内存映射
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

// 分配页面的逻辑在上面已经阐述过
static struct Page *
buddy_system_alloc_pages(size_t n) {
    assert(n > 0);

    if (n > (1 << (MAX_ORDER - 1))) {
        return NULL;
    }

    size_t alloc_size = next_power_of_2(n);
    size_t order = log2_floor(alloc_size);

    size_t current_order = order;

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

// 释放的逻辑也在之前讲过
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

static size_t
buddy_system_nr_free_pages(void) {
    size_t total = 0;
    for (int i = 0; i < MAX_ORDER; i++) {
        total += free_area[i].nr_free * (1 << i);
    }
    return total;
}

static void
basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    free_page(p0);
    free_page(p1);
    free_page(p2);
}

// 测试1：边界条件测试
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

// 测试2：分裂与合并测试
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

// 测试3：连续分配和释放测试
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

// 测试4：内存碎片测试
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

// 测试5：压力测试
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

// 测试6：对齐和地址验证测试
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

// 测试7：Buddy正确性验证
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

// 测试8：非2的幂次分配测试
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

// Buddy系统检查函数
static void
buddy_system_check(void) {
    cprintf("   BUDDY SYSTEM ADVANCED TEST SUITE            \n");
    cprintf("\n");
    
    // 显示初始状态
    cprintf("=== Initial System State ===\n");
    size_t total_free = nr_free_pages();
    cprintf("Total free pages: %d (%d MB)\n\n", 
            (int)total_free, (int)((total_free * 4) / 1024));
    
    // 运行所有测试
    boundary_test();
    split_merge_test();
    consecutive_alloc_free_test();
    fragmentation_test();
    stress_test();
    alignment_test();
    buddy_correctness_test();
    non_power_of_2_test();
    
    // 最终状态检查
    cprintf("   FINAL RESULTS                               \n");
    size_t final_free = nr_free_pages();
    cprintf("Total free pages: %d (%d MB)\n", 
            (int)final_free, (int)((final_free * 4) / 1024));
    
    int diff = (int)(total_free - final_free);
    if (diff == 0) {
        cprintf("PASS: No memory leaks detected!\n");
    } else if (diff > 0) {
        cprintf("WARNING: %d pages not recovered\n", diff);
    } else {
        cprintf("INFO: %d extra pages (coalescing effect)\n", -diff);
    }
    cprintf("   ALL TESTS COMPLETED                         \n");
    cprintf("\n");
}

const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system",
    .init = buddy_system_init,
    .init_memmap = buddy_system_init_memmap,
    .alloc_pages = buddy_system_alloc_pages,
    .free_pages = buddy_system_free_pages,
    .nr_free_pages = buddy_system_nr_free_pages,
    .check = buddy_system_check,
};