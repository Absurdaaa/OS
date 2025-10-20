# 操作系统实验二：物理内存管理

## 1 First-Fit连续物理内存分配算法解析

### 1.1 算法理论基础

First-Fit算法是一种基础的连续内存分配策略，其核心机制是在收到内存分配请求时，从空闲内存块链表的起始位置进行线性搜索，选择首个满足大小需求的空闲块进行分配。若目标块容量超出实际需求，则采用分割策略，将超出部分重新构建为空闲块。

### 1.2 数据结构

页面描述符结构体Page定义于`memlayout.h:34-39`：
```c
struct Page {
    int ref;                        // 页面引用计数
    uint64_t flags;                 // 页面状态标志
    unsigned int property;          // 空闲块大小（仅首页有效）
    list_entry_t page_link;         // 双向链表节点
};
```

空闲区域管理结构体free_area_t定义于`memlayout.h:58-61`：
```c
typedef struct {
    list_entry_t free_list;         // 空闲块链表头
    unsigned int nr_free;           // 空闲页面总数
} free_area_t;
```

### 1.3 核心函数实现

#### 1.3.1 初始化函数

`default_init`函数（`default_pmm.c:131-134`）执行内存管理器的初始化操作，通过`list_init(&free_list)`建立空闲块双向链表，将`nr_free`置零，为后续操作建立初始状态。

#### 1.3.2 内存映射初始化

`default_init_memmap`函数（`default_pmm.c:140-165`）负责将连续物理内存空间纳入管理系统。其实现流程包括：遍历页面并清除标志位与引用计数，设置块首页的`property`字段和`PG_property`标志，按地址升序插入空闲链表，更新全局空闲页面计数。

#### 1.3.3 页面分配

`default_alloc_pages`函数（`default_pmm.c:168-195`）实现了First-Fit算法的核心分配逻辑。该函数首先验证资源充足性，然后线性搜索满足条件的首个空闲块，执行必要的分割操作，最后更新状态并返回分配的页面起始地址。

#### 1.3.4 页面释放

`default_free_pages`函数（`default_pmm.c:198-245`）实现页面释放功能。其流程包括重置页面状态，配置空闲块属性，按地址升序插入链表，执行相邻块合并操作，更新全局计数器。

### 1.4 算法特性

First-Fit算法具有实现简洁的特点，逻辑直观且易于维护。其时间复杂度为O(n)，其中n为空闲块数量。空间复杂度为O(1)，仅需维护基本的数据结构。该算法存在外部碎片问题，可能导致内存利用率下降。

## 2 Best-Fit连续物理内存分配算法实现

### 2.1 算法原理

Best-Fit算法是对First-Fit的改进策略，其核心思想是在所有满足分配条件的空闲块中选择大小最接近请求值的块进行分配，旨在减少大块内存的分割，降低外部碎片产生。

### 2.2 核心实现

基于First-Fit算法的数据结构，我设计了Best-Fit分配算法的实现。其核心修改在于内存分配函数的实现策略：

```c
static struct Page *
best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }

    struct Page *best_page = NULL;
    size_t min_size = SIZE_MAX;
    list_entry_t *le = &free_list;

    // 遍历整个空闲链表，寻找最小的满足条件的块
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n && p->property < min_size) {
            min_size = p->property;
            best_page = p;
            // 如果找到大小正好匹配的块，直接选择
            if (p->property == n) {
                break;
            }
        }
    }

    if (best_page != NULL) {
        list_entry_t* prev = list_prev(&(best_page->page_link));
        list_del(&(best_page->page_link));

        // 如果块大小大于请求大小，进行分割
        if (best_page->property > n) {
            struct Page *p = best_page + n;
            p->property = best_page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }

        nr_free -= n;
        ClearPageProperty(best_page);
    }

    return best_page;
}
```

### 2.3 算法特征

Best-Fit算法需要遍历整个空闲链表以确保找到最优块，其时间复杂度为O(n)。该算法通过选择最小满足块来减少外部碎片，提高内存利用率，但分配速度相对较慢，且长期运行可能产生难以利用的小碎片。

## 3 物理内存探测技术分析

详细内容请参见[物理内存探测技术实现](lab2_memory_detection.md)