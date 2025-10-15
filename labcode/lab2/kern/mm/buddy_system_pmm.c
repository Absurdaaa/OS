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

// 系统物理内存大小为128MB，每个页大小4KB，除去kernel等占用的内存，我们设置阶数为14
#define MAX_ORDER 14

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

// Buddy系统检查函数
static void
buddy_system_check(void) {
    // 统计各order的空闲块
    int total_blocks = 0;
    size_t total_pages = 0;
    
    cprintf("Free blocks in each order:\n");
    for (int i = 0; i < MAX_ORDER; i++) {
        list_entry_t *le = &(free_area[i].free_list);
        int count = 0;
        while ((le = list_next(le)) != &(free_area[i].free_list)) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p));
            count++;
        }
        if (count > 0) {
            size_t pages_in_order = count * (1 << i);
            cprintf("  Order %2d (2^%2d = %5d pages): %d blocks, %5d total pages (%3d MB)\n",
                    i, i, (1 << i), count,
                    (int)pages_in_order, (int)((pages_in_order * 4) / 1024));
            total_blocks += count;
            total_pages += pages_in_order;
        }
    }
    cprintf("Summary: %d blocks, %d free pages (%d MB)\n\n", 
            total_blocks, (int)total_pages, (int)((total_pages * 4) / 1024));
    
    // 基本功能测试
    cprintf("--- Basic allocation test ---\n");
    basic_check();
    cprintf("Basic test passed\n\n");
    
    // 测试分配2的幂次大小
    cprintf("--- Power-of-2 allocation test ---\n");
    struct Page *p0 = alloc_pages(1);
    assert(p0 != NULL);
    cprintf("Allocated 1 page successfully\n");
    
    struct Page *p1 = alloc_pages(2);
    assert(p1 != NULL);
    cprintf("Allocated 2 pages successfully\n");
    
    struct Page *p2 = alloc_pages(4);
    assert(p2 != NULL);
    cprintf("Allocated 4 pages successfully\n");
    
    free_pages(p0, 1);
    free_pages(p1, 2);
    free_pages(p2, 4);
    cprintf("Freed all test allocations\n\n");
    
    // 测试分配非2的幂次大小
    cprintf("--- Non-power-of-2 allocation test ---\n");
    struct Page *p3 = alloc_pages(3);  // 应该分配4页
    assert(p3 != NULL);
    assert(p3->property == 4);
    cprintf("Allocated 3 pages (rounded up to %u pages)\n", p3->property);
    free_pages(p3, 3);
    cprintf("Freed 3 pages\n\n");
    
    cprintf("========== buddy_system_check() succeeded! ==========\n");
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