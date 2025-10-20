#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>

/* In the first fit algorithm, the allocator keeps a list of free blocks (known as the free list) and,
   on receiving a request for memory, scans along the list for the first block that is large enough to
   satisfy the request. If the chosen block is significantly larger than that requested, then it is 
   usually split, and the remainder added to the list as another free block.
   Please see Page 196~198, Section 8.2 of Yan Wei Min's chinese book "Data Structure -- C programming language"
*/
// LAB2 EXERCISE 1: YOUR CODE
// you should rewrite functions: default_init,default_init_memmap,default_alloc_pages, default_free_pages.
/*
 * Details of FFMA
 * (1) Prepare: In order to implement the First-Fit Mem Alloc (FFMA), we should manage the free mem block use some list.
 *              The struct free_area_t is used for the management of free mem blocks. At first you should
 *              be familiar to the struct list in list.h. struct list is a simple doubly linked list implementation.
 *              You should know howto USE: list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *              Another tricky method is to transform a general list struct to a special struct (such as struct page):
 *              you can find some MACRO: le2page (in memlayout.h), (in future labs: le2vma (in vmm.h), le2proc (in proc.h),etc.)
 * (2) default_init: you can reuse the  demo default_init fun to init the free_list and set nr_free to 0.
 *              free_list is used to record the free mem blocks. nr_free is the total number for free mem blocks.
 * (3) default_init_memmap:  CALL GRAPH: kern_init --> pmm_init-->page_init-->init_memmap--> pmm_manager->init_memmap
 *              This fun is used to init a free block (with parameter: addr_base, page_number).
 *              First you should init each page (in memlayout.h) in this free block, include:
 *                  p->flags should be set bit PG_property (means this page is valid. In pmm_init fun (in pmm.c),
 *                  the bit PG_reserved is setted in p->flags)
 *                  if this page  is free and is not the first page of free block, p->property should be set to 0.
 *                  if this page  is free and is the first page of free block, p->property should be set to total num of block.
 *                  p->ref should be 0, because now p is free and no reference.
 *                  We can use p->page_link to link this page to free_list, (such as: list_add_before(&free_list, &(p->page_link)); )
 *              Finally, we should sum the number of free mem block: nr_free+=n
 * (4) default_alloc_pages: search find a first free block (block size >=n) in free list and reszie the free block, return the addr
 *              of malloced block.
 *              (4.1) So you should search freelist like this:
 *                       list_entry_t le = &free_list;
 *                       while((le=list_next(le)) != &free_list) {
 *                       ....
 *                 (4.1.1) In while loop, get the struct page and check the p->property (record the num of free block) >=n?
 *                       struct Page *p = le2page(le, page_link);
 *                       if(p->property >= n){ ...
 *                 (4.1.2) If we find this p, then it' means we find a free block(block size >=n), and the first n pages can be malloced.
 *                     Some flag bits of this page should be setted: PG_reserved =1, PG_property =0
 *                     unlink the pages from free_list
 *                     (4.1.2.1) If (p->property >n), we should re-caluclate number of the the rest of this free block,
 *                           (such as: le2page(le,page_link))->property = p->property - n;)
 *                 (4.1.3)  re-caluclate nr_free (number of the the rest of all free block)
 *                 (4.1.4)  return p
 *               (4.2) If we can not find a free block (block size >=n), then return NULL
 * (5) default_free_pages: relink the pages into  free list, maybe merge small free blocks into big free blocks.
 *               (5.1) according the base addr of withdrawed blocks, search free list, find the correct position
 *                     (from low to high addr), and insert the pages. (may use list_next, le2page, list_add_before)
 *               (5.2) reset the fields of pages, such as p->ref, p->flags (PageProperty)
 *               (5.3) try to merge low addr or high addr blocks. Notice: should change some pages's p->property correctly.
 */
/* 在“首次适配（first fit）”算法中，分配器维护一张空闲块链表（free list）。
   当收到一条内存分配请求时，它沿着这张链表扫描，找到第一块
   大小足以满足请求的空闲块。如果选中的空闲块明显大于请求的大小，
   通常会把它拆分：前一部分分配给请求者，剩余部分作为新的空闲块
   重新挂回空闲链表。
   参考：严蔚敏《数据结构——C语言版》8.2节，第196～198页。
*/

// LAB2 练习 1：请在此处编写你的代码
// 需要你改写的函数：default_init、default_init_memmap、default_alloc_pages、default_free_pages。
/*
 * FFMA（First-Fit Mem Alloc）实现细节
 * (1) 预备：
 *     为了实现首次适配的内存分配（FFMA），我们需要用某种链表来管理空闲内存块。
 *     结构体 free_area_t 用于管理空闲块。首先请熟悉 list.h 中的双向链表实现 struct list。
 *     需要掌握的用法：list_init、list_add（或 list_add_after）、list_add_before、
 *                    list_del、list_next、list_prev。
 *     另一个常用技巧是把通用的链表结点转回到特定的结构体（如 struct page）：
 *     你可以使用一些宏，例如：le2page（在 memlayout.h 中；后续实验里还有
 *     le2vma（vmm.h）、le2proc（proc.h）等）。
 *
 * (2) default_init：
 *     可以复用示例中的 default_init 函数来初始化 free_list，并把 nr_free 置 0。
 *     free_list 用来记录所有空闲块；nr_free 表示空闲块的总页数。
 *
 * (3) default_init_memmap：
 *     调用关系：kern_init --> pmm_init --> page_init --> init_memmap --> pmm_manager->init_memmap
 *     该函数用于初始化一段空闲块（参数为：addr_base，page_number）。
 *     首先需要初始化这段空闲块内的每个 page（见 memlayout.h），包括：
 *       - p->flags 要设置 PG_property 位（表示该页可用于分配。注意在 pmm.c 的 pmm_init 中，
 *         p->flags 的 PG_reserved 位曾被设置过）。
 *       - 如果该页空闲且不是空闲块的首页，则 p->property 置为 0；
 *         如果该页空闲且是空闲块的首页，则 p->property 置为该块包含的页数。
 *       - p->ref 置 0，因为此时页面空闲，无引用。
 *       - 使用 p->page_link 把该页挂到 free_list 上（例如：
 *         list_add_before(&free_list, &(p->page_link)); ）。
 *     最后，累加空闲页数量：nr_free += n。
 *
 * (4) default_alloc_pages：
 *     在 free_list 中查找第一块满足大小（block size >= n）的空闲块，必要时调整空闲块，
 *     并返回分配到的页的起始地址。
 *     (4.1) 按如下方式遍历空闲链表：
 *           list_entry_t le = &free_list;
 *           while ((le = list_next(le)) != &free_list) {
 *               ...
 *           }
 *     (4.1.1) 在循环中，取出对应的 struct Page 并检查 p->property（记录该空闲块的页数）是否 >= n：
 *             struct Page *p = le2page(le, page_link);
 *             if (p->property >= n) { ... }
 *     (4.1.2) 如果找到了 p，说明我们找到了一个大小足够的空闲块，其前 n 页可分配。
 *             需要设置这些页的一些标志位：PG_reserved = 1，PG_property = 0；
 *             并把这些页从 free_list 中摘链。
 *             (4.1.2.1) 若 p->property > n，还需要重新计算该空闲块剩余部分的页数，
 *                       例如： (le2page(le, page_link))->property = p->property - n;
 *     (4.1.3) 重新计算 nr_free（所有空闲页的总数，扣除已分配的 n 页）。
 *     (4.1.4) 返回 p。
 *     (4.2) 如果找不到满足条件（block size >= n）的空闲块，则返回 NULL。
 *
 * (5) default_free_pages：
 *     释放页并把它们重新挂回空闲链表，同时尽量把相邻的小空闲块合并为更大的空闲块。
 *     (5.1) 根据被释放块的起始地址，在 free_list 中按地址从小到大找到正确插入位置，
 *           然后把这些页插入（可能会用到 list_next、le2page、list_add_before）。
 *     (5.2) 重置这些页的字段，比如 p->ref、p->flags（设置 PageProperty）。
 *     (5.3) 尝试与低地址或高地址相邻的空闲块合并。注意：合并后要正确更新相关页的 p->property。
 */



static free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
}

/**
 * HQZ: 这个函数相当于是使用一个PAGE数组对一段物理内存的链表进行初始化，如果初始化为空得到的是大小为1的链表
 */
static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
      assert(PageReserved(p)); // 要求这些页之前处于“保留/未加入分配器”的状态，避免重复加入
      p->flags = p->property = 0;
      set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {// 讲base插入到合适的地址
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {// 这里是如果遍历到最后都没有合适的位置插入直接插入到最后
                list_add(le, &(base->page_link));
            }
        }
    }
}

static struct Page *
default_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));// 如果page实际分走的页面比n多，那么就把剩下的部分重新插入到链表中
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}

static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    // 这里处理和初始化一样
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
    // 这里是看如果base前面的空间如果和base是连续的就合并
    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }
    // 这里是看如果base后面的空间如果和base是连续的就合并
    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
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

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);
    assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
    assert((p1 = alloc_pages(3)) != NULL);
    assert(alloc_page() == NULL);
    assert(p0 + 2 == p1);

    p2 = p0 + 1;
    free_page(p0);
    free_pages(p1, 3);
    assert(PageProperty(p0) && p0->property == 1);
    assert(PageProperty(p1) && p1->property == 3);

    assert((p0 = alloc_page()) == p2 - 1);
    free_page(p0);
    assert((p0 = alloc_pages(2)) == p2 + 1);

    free_pages(p0, 2);
    free_page(p2);

    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
}

const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
    .check = default_check,
};

