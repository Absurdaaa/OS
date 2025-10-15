# 操作系统实验2：物理内存管理

## 1 练习1：理解first-fit 连续物理内存分配算法

### 1.1 算法概述

First-Fit（首次适应）算法是一种连续内存分配策略，当收到内存分配请求时，从空闲内存块链表的起始位置开始搜索，选择第一个能够满足请求大小的空闲块进行分配。如果选中的空闲块大小明显大于请求大小，则将其分割为两部分：一部分分配给请求者，剩余部分作为新的空闲块。

通过分析`kern/mm/default_pmm.c`中的源码实现，可以深入理解First-Fit算法的工作机制和实现细节。

### 1.2 数据结构分析

页面描述符结构体Page定义在`memlayout.h:34-39`：
```c
struct Page {
    int ref;                        // 页面引用计数器
    uint64_t flags;                 // 页面状态标志位
    unsigned int property;          // 空闲块大小（仅对空闲块首页有效）
    list_entry_t page_link;         // 双向链表节点
};
```

空闲区域管理结构体free_area_t定义在`memlayout.h:58-61`：
```c
typedef struct {
    list_entry_t free_list;         // 空闲块链表头
    unsigned int nr_free;           // 空闲页面总数
} free_area_t;
```

### 1.3 核心函数实现分析

#### 1.3.1 default_init函数

位置：`default_pmm.c:131-134`

该函数负责初始化内存管理器的全局状态。通过调用`list_init(&free_list)`初始化空闲块双向链表，并将空闲页面计数器`nr_free`置零，为后续的内存分配和释放操作建立初始状态。

#### 1.3.2 default_init_memmap函数

位置：`default_pmm.c:140-165`

该函数初始化一段连续的物理内存空间，将其纳入内存管理器的管辖范围。具体实现过程首先进行页面状态初始化，遍历从`base`开始的`n`个页面，清除所有页面的标志位和引用计数。然后进行空闲块属性设置，设置块首页的`property`字段为块大小`n`，并设置`PG_property`标志位。接下来进行链表插入，按地址升序将空闲块插入到`free_list`中，保持链表的地址有序性。最后进行计数器更新，更新全局空闲页面计数`nr_free += n`。

该函数在系统启动时被调用，用于建立初始的空闲内存池。

#### 1.3.3 default_alloc_pages函数

位置：`default_pmm.c:168-195`

该函数分配`n`个连续的物理页面，是First-Fit算法的核心实现。实现过程首先进行可行性检查，验证`n > nr_free`条件，如果空闲页面不足则直接返回NULL。接着进行空闲块搜索，从链表头开始遍历，寻找第一个满足`p->property >= n`的空闲块。如果找到的空闲块大小大于请求大小，则进行块分割处理，计算剩余部分起始地址为`struct Page *p = page + n`，设置剩余块的属性为`p->property = page->property - n`，并将剩余块重新插入链表。随后进行状态更新，清除已分配页面的`PG_property`标志，更新空闲页面计数。最后返回分配的页面起始地址。

该函数体现了First-Fit算法的核心思想：总是选择第一个满足条件的空闲块进行分配。

#### 1.3.4 default_free_pages函数

位置：`default_pmm.c:198-245`

该函数释放`n`个连续的物理页面。实现过程首先进行页面状态重置，清除释放页面的所有标志位，重置引用计数。然后进行空闲块设置，设置释放块首页的`property`为`n`，设置`PG_property`标志。接下来进行有序插入，按地址升序将释放块插入到空闲链表中。随后进行相邻块合并，检查并合并地址连续的相邻空闲块，包括前向合并检查前一个块是否与当前块地址连续，以及后向合并检查后一个块是否与当前块地址连续。最后进行计数器更新，更新全局空闲页面计数。

合并策略通过检查前一个和后一个块是否与当前块地址连续，如果连续则合并，有效减少了外部碎片。

### 1.4 物理内存分配过程

整个物理内存分配过程包括初始化阶段、分配阶段、释放阶段和碎片管理四个主要阶段。在初始化阶段，系统启动时通过`default_init_memmap`将所有可用物理内存组织成空闲块链表。在分配阶段，当需要分配内存时，`default_alloc_pages`从链表头开始遍历，找到第一个足够大的空闲块进行分配。在释放阶段，当释放内存时，`default_free_pages`将释放的块插入链表，并尝试与相邻块合并。在碎片管理阶段，通过合并相邻的空闲块来减少外部碎片，提高内存利用率。

### 1.5 算法特点分析

First-Fit算法具有实现简单、分配速度快和内存开销小的优点。该算法逻辑直观，易于理解和维护，平均情况下分配速度较快，无需遍历整个链表，且不需要额外的数据结构维护空闲块信息。然而，First-Fit算法也存在一些缺点，可能会产生大量小的外部碎片，大块内存可能被分割导致后续无法满足大内存请求，内存利用率不是最优的。

时间复杂度方面，分配操作为O(n)，其中n为空闲块数量，最坏情况下需要遍历整个空闲链表；释放操作也为O(n)，需要找到合适的插入位置并进行可能的合并操作。空间复杂度为O(1)，仅需维护链表结构和计数器，空间开销恒定。

## 2 练习2：实现 Best-Fit 连续物理内存分配算法

### 2.1 算法设计原理

Best-Fit（最佳适应）算法是对First-Fit算法的改进，其核心思想是在所有满足分配条件的空闲块中，选择大小最接近请求大小的块进行分配。这种策略旨在减少大块内存被分割的可能性，从而降低外部碎片的产生。

### 2.2 实现方案

基于对First-Fit算法的分析，我设计实现了Best-Fit分配算法。该算法复用了First-Fit的数据结构和大部分辅助函数，仅修改了内存分配策略。

### 2.3 核心实现

Best-Fit算法的核心修改在于内存分配函数，需要遍历整个空闲链表以找到最优的空闲块：

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

### 2.4 实现特点

#### 2.4.1 核心改进点

Best-Fit算法的核心改进点包括全局搜索策略、最小块选择和提前终止优化。与First-Fit不同，Best-Fit需要遍历整个空闲链表以确保找到最优块。算法维护`min_size`变量记录当前找到的最小满足条件的块，并且在找到大小正好匹配的块时可以提前终止搜索。

#### 2.4.2 兼容性设计

在兼容性设计方面，Best-Fit算法的释放操作完全复用First-Fit的实现，数据结构和初始化过程保持不变，仅修改分配策略，确保系统的稳定性。

### 2.5 算法复杂度分析

时间复杂度方面，分配操作为O(n)，其中n为空闲块数量，必须遍历整个空闲链表；释放操作为O(n)，与First-Fit算法相同。空间复杂度为O(1)，与First-Fit算法相同。

### 2.6 算法特点分析

Best-Fit算法具有减少外部碎片、提高内存利用率和保留大块内存的优点。该算法选择最小的满足条件的块，减少大块内存的分割，长期运行下能够更好地利用内存资源，并为后续的大内存请求保留更大的空闲块。然而，Best-Fit算法也存在一些缺点，分配速度较慢，必须遍历整个空闲链表，时间开销较大，长期运行可能产生大量小的、难以利用的碎片，实现复杂度略高，相比First-Fit需要额外的比较和选择逻辑。

## 3 练习3：当OS无法提前知道硬件可用物理内存范围时的解决方案

### 3.1 当前系统实现分析

现代操作系统通常依赖于硬件抽象层来获取物理内存信息。通过分析当前RISC-V系统的实现，可以发现系统采用了基于设备树(Device Tree)的内存发现机制。

在系统启动过程中，`dtb_init()` 函数（位于 `kern/driver/dtb.c:107-142`）承担了解析设备树并提取内存配置信息的核心职责。该函数首先验证设备树的魔数，确保数据结构的完整性：

```c
// 验证DTB魔数
uint32_t magic = fdt32_to_cpu(header->magic);
if (magic != 0xd00dfeed) {
    cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
    return;
}
```

随后，函数通过 `extract_memory_info()` 递归解析设备树结构，定位到 `memory` 节点并提取其 `reg` 属性。该属性包含了物理内存的基地址和大小信息，这些信息被存储在全局变量 `memory_base` 和 `memory_size` 中，供系统的其他模块使用。

系统通过两个简洁的接口函数对外提供内存信息：
- `get_memory_base()` （`kern/driver/dtb.c:144`）返回物理内存的基地址
- `get_memory_size()` （`kern/driver/dtb.c:148`）返回物理内存的总容量

在物理内存管理器的初始化阶段，`page_init()` 函数（`kern/mm/pmm.c:69-74`）调用这些接口获取内存范围信息：

```c
static void page_init(void) {
    uint64_t mem_begin = get_memory_base();
    uint64_t mem_size  = get_memory_size();
    if (mem_size == 0) {
        panic("DTB memory info not available");
    }
    uint64_t mem_end   = mem_begin + mem_size;

    npage = maxpa / PGSIZE;
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
    // 初始化页面描述符并建立空闲内存链表
}
```

这种基于设备树的方法具有标准化、信息准确的优点，但其前提是bootloader必须正确传递设备树，且硬件平台必须支持设备树规范。

### 3.2 替代实现方案的深度分析

当操作系统无法依赖设备树或其他预设的硬件信息时，需要采用更加主动的内存发现策略。以下分析几种具有代表性的技术方案。

#### 3.2.1 基于试探性读写的内存探测技术

内存探测技术是一种不依赖硬件特定信息的通用方法。其核心思想是通过试探性的内存访问来验证内存区域的有效性。该方法在嵌入式系统和个人计算机的早期发展阶段被广泛应用。

实现该技术需要考虑多个关键因素。首先是探测的安全性，必须避免对现有系统数据造成破坏。其次是探测的准确性，需要设计可靠的验证模式来区分真实的内存和硬件响应的假象。

一个典型的内存探测算法可能如下实现：

```c
static bool probe_memory_region(uint64_t start_addr, size_t size) {
    const uint32_t test_patterns[] = {0xAAAAAAAA, 0x55555555, 0xFFFFFFFF, 0x00000000};
    volatile uint32_t *test_addr = (volatile uint32_t *)start_addr;
    size_t test_size = size / sizeof(uint32_t);

    // 保存原始内容
    uint32_t *backup = malloc(size);
    if (!backup) return false;

    memcpy(backup, (void *)test_addr, size);

    // 执行多模式测试
    for (int pattern_idx = 0; pattern_idx < 4; pattern_idx++) {
        uint32_t pattern = test_patterns[pattern_idx];

        // 写入测试模式
        for (size_t i = 0; i < test_size; i++) {
            test_addr[i] = pattern;
        }

        // 验证写入结果
        bool pattern_valid = true;
        for (size_t i = 0; i < test_size; i++) {
            if (test_addr[i] != pattern) {
                pattern_valid = false;
                break;
            }
        }

        if (!pattern_valid) {
            memcpy((void *)test_addr, backup, size);
            free(backup);
            return false;
        }
    }

    // 恢复原始内容
    memcpy((void *)test_addr, backup, size);
    free(backup);
    return true;
}
```

该算法通过四个不同的测试模式（0xAA、0x55、0xFF、0x00）来验证内存的可靠性。每个模式都包含写入-验证循环，确保内存单元能够正确存储和检索数据。探测完成后，算法会恢复原始内容，保证系统状态的一致性。

这种方法的复杂度在于处理硬件异常和缓存一致性。RISC-V架构下的内存访问异常可能通过页面故障或总线错误表现出来，需要在操作系统层面建立相应的异常处理机制。

#### 3.2.2 基于固件接口的标准化查询方法

现代计算机系统通常提供标准化的固件接口来查询硬件配置。在x86架构下，BIOS中断服务INT 0x15的E820功能提供了详细的内存映射信息。调用该接口需要设置特定的寄存器值并执行软件中断：

```assembly
mov eax, 0xe820
mov edx, 'SMAP'
mov ecx, 24         ; 缓冲区大小
mov ebx, 0          ; 续传值
int 0x15
```

该调用返回一个包含内存区域基址、长度和类型的结构体数组。类型字段标识了内存的用途，如可用内存、保留区域、ACPI数据等。这种方法的优势在于提供了标准化的接口，但需要针对不同的架构实现相应的调用约定。

在ARM/RISC-V平台上，UEFI（Unified Extensible Firmware Interface）提供了类似的内存查询服务。UEFI的`GetMemoryMap`接口返回内存描述符数组，每个描述符包含了内存的类型、物理地址和属性信息。

#### 3.2.3 基于硬件寄存器的直接访问方法

某些硬件平台提供了直接访问内存控制器配置的能力。在RISC-V架构中，这通常通过控制和状态寄存器（CSR）或内存映射I/O（MMIO）实现。

例如，某些RISC-V实现可能提供内存配置寄存器，可以通过CSR指令直接读取：

```c
// 伪代码：读取内存配置寄存器
static uint64_t read_memory_config(void) {
    uint64_t config = 0;

    // 检查内存配置寄存器是否存在
    if (csr_read_allowed(MEMORY_CONFIG_CSR)) {
        config = read_csr(MEMORY_CONFIG_CSR);
    }

    return config;
}

// 从配置寄存器中提取内存大小信息
static uint64_t extract_memory_size(uint64_t config) {
    // 假设内存大小信息存储在配置寄存器的特定位域中
    uint64_t size_bits = (config >> MEMORY_SIZE_SHIFT) & MEMORY_SIZE_MASK;
    return size_bits * MEMORY_UNIT_SIZE;  // 转换为字节
}
```

这种方法的优势在于速度快且信息准确，但高度依赖硬件的具体实现。不同的SoC厂商可能采用完全不同的寄存器布局和访问方式，需要在操作系统层面实现大量的驱动代码。

#### 3.2.4 多阶段渐进式启动策略

多阶段启动策略是一种综合性的解决方案，它结合了保守启动和动态探测的优点。该策略将系统启动过程分为多个阶段，每个阶段逐步扩展对物理内存的访问和控制。

第一阶段称为保守启动阶段，系统使用预设的最小内存区域启动基本功能。这个内存区域通常位于已知的安全地址，大小足够容纳内核的临界部分和基本的数据结构。

```c
// 保守启动的内存配置
#define CONSERVATIVE_MEMORY_BASE   0x80200000
#define CONSERVATIVE_MEMORY_SIZE   (8 * 1024 * 1024)  // 8MB

static void conservative_init(void) {
    // 仅初始化保守内存区域的页面管理
    init_conservative_pmm(CONSERVATIVE_MEMORY_BASE,
                         CONSERVATIVE_MEMORY_SIZE);

    // 建立基本的内存分配器
    init_basic_allocator();

    // 启动控制台和其他基本服务
    init_console();
    init_interrupt_handler();
}
```

第二阶段是内存探测阶段，系统在已经建立的保护机制下，安全地扩展对更多内存区域的访问。探测过程采用分块、递增的方式进行，每发现一个新的内存区域，就将其纳入内存管理器的控制范围。

```c
static void memory_discovery_phase(void) {
    uint64_t probe_base = CONSERVATIVE_MEMORY_BASE + CONSERVATIVE_MEMORY_SIZE;
    uint64_t probe_limit = MAX_PHYSICAL_MEMORY;
    const size_t probe_granularity = 1024 * 1024;  // 1MB粒度

    while (probe_base < probe_limit) {
        if (safe_probe_memory_region(probe_base, probe_granularity)) {
            // 发现有效内存，添加到管理器
            add_memory_region_to_pmm(probe_base, probe_granularity);
            probe_base += probe_granularity;
        } else {
            // 探测失败，可能达到内存边界
            break;
        }
    }

    // 重建完整的内存管理结构
    rebuild_full_memory_management();
}
```

最后的完整初始化阶段，系统根据探测到的完整内存信息，重建内存管理数据结构，启用完整的内存管理功能，包括虚拟内存、页面置换等高级特性。

这种策略的实现复杂度在于数据结构的迁移和重建过程。系统需要谨慎地将临时数据结构迁移到新发现的内存区域，同时保持系统的一致性和稳定性。

### 3.3 针对RISC-V架构的优化实现方案

考虑到当前实验环境的RISC-V架构特点，推荐采用多阶段启动与安全探测相结合的方案。该方案在保持系统稳定性的同时，提供了最大程度的硬件兼容性。

#### 3.3.1 实现架构设计

实现的核心是建立一个渐进式的内存发现机制，该机制能够在不同的启动阶段提供适当级别的内存管理服务。

第一阶段的关键是建立最小化的内存管理环境。基于对当前代码的分析，可以利用现有的 `page_init()` 函数框架，但需要修改其内存发现逻辑：

```c
static void enhanced_page_init(void) {
    // 阶段1：使用预设的最小内存配置
    uint64_t conservative_base = CONSERVATIVE_MEMORY_BASE;
    uint64_t conservative_size = CONSERVATIVE_MEMORY_SIZE;

    // 验证最小内存区域的可用性
    if (!verify_conservative_memory(conservative_base, conservative_size)) {
        panic("Conservative memory region unavailable");
    }

    // 初始化最小内存管理器
    init_minimal_pmm(conservative_base, conservative_size);

    // 启动基本服务
    dtb_init();  // 尝试解析设备树
    cons_init();

    // 阶段2：如果设备树解析失败，执行内存探测
    if (get_memory_size() == 0) {
        perform_memory_discovery();
    }

    // 阶段3：完整初始化
    complete_memory_initialization();
}
```

内存探测的实现需要特别关注安全性。考虑到RISC-V架构的内存模型，探测算法应该：

1. 使用页面对齐的探测边界，避免跨页操作的复杂性
2. 实现异常处理机制，安全地处理内存访问错误
3. 使用缓存刷新指令确保数据一致性
4. 采用保守的探测步长，平衡速度和准确性

#### 3.3.2 技术实现细节

安全探测的实现需要深入理解RISC-V架构的异常处理机制。当探测到无效内存地址时，处理器会生成页面故障异常。操作系统需要建立相应的异常处理程序：

```c
// 内存探测异常处理
static bool memory_probe_fault = false;

void handle_memory_fault(uint64_t fault_addr, uint64_t fault_cause) {
    if (is_memory_probe_active()) {
        memory_probe_fault = true;
        // 修改返回地址，跳过故障指令
        uint64_t epc = read_csr(sepc);
        write_csr(sepc, epc + 4);  // 假设指令长度为4字节
    } else {
        // 其他类型的内存故障，进行标准处理
        panic("Unexpected memory fault");
    }
}

// 安全的内存探测函数
static bool safe_probe_memory(uint64_t addr) {
    memory_probe_fault = false;
    set_memory_probe_active(true);

    // 执行试探性访问
    volatile uint64_t test_val = *(volatile uint64_t *)addr;

    set_memory_probe_active(false);

    return !memory_probe_fault;
}
```

这种异常处理机制允许探测算法在遇到无效内存时优雅地恢复，而不是导致系统崩溃。

缓存一致性是另一个需要重点考虑的技术问题。RISC-V架构的缓存策略可能导致写入操作不会立即反映到主内存中，从而影响探测结果的准确性。解决方法是在关键的探测步骤中使用缓存刷新指令：

```c
static inline void flush_cache_line(uint64_t addr) {
    asm volatile ("fence rw,rw" ::: "memory");
    asm volatile ("fence.iorw,iowr" ::: "memory");
}

static bool probe_with_cache_consistency(uint64_t addr) {
    // 执行写入操作
    volatile uint64_t *ptr = (volatile uint64_t *)addr;
    uint64_t test_value = 0xDEADBEEFCAFEBABE;
    *ptr = test_value;

    // 刷新缓存确保写入到达主内存
    flush_cache_line((uint64_t)ptr);

    // 读取验证
    uint64_t read_value = *ptr;

    return (read_value == test_value);
}
```

通过结合这些技术实现细节，可以构建一个既安全又高效的内存发现机制，为操作系统提供完整的物理内存信息。

## 4 总结

通过本实验，我深入分析了ucore操作系统中的First-Fit连续物理内存分配算法，理解了物理内存管理的核心机制。在此基础上，设计实现了Best-Fit算法，并通过对比分析阐明了两种算法的适用场景和性能特点。

First-Fit算法适合对分配速度要求较高、内存请求大小差异较大的场景；而Best-Fit算法更适合对内存利用率要求较高、内存请求大小相对均匀的场景。两种算法各有优缺点，实际系统中的内存管理器往往需要根据具体的应用场景和性能需求进行权衡和选择。

此外，通过分析当OS无法提前知道硬件可用物理内存范围时的解决方案，我深入理解了操作系统在不同硬件环境下的适应策略。每种方法都有其适用场景：设备树方法适合现代嵌入式系统，内存探测方法通用性强但启动时间长，BIOS/UEFI方法标准化程度高，硬件寄存器方法快速准确，多阶段方法容错性强，配置文件方法简单直接。在实际的操作系统设计中，往往需要根据具体的应用场景和硬件环境，选择合适的方案或者组合使用多种方法，以在启动速度、系统稳定性、硬件兼容性和维护成本之间取得平衡。

通过本实验，我不仅掌握了连续内存分配算法的实现原理，还深入理解了操作系统内存管理的复杂性和重要性，为后续学习更复杂的内存管理机制奠定了基础。