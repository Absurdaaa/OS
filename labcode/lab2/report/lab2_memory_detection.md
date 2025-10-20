# 物理内存探测技术实现

## 1 技术背景与挑战

在操作系统启动过程中，获取可用物理内存范围是一项关键的基础性工作。当设备树（DTB）信息不可用或需要验证其准确性时，操作系统必须具备独立探测物理内存的能力。直接访问未知内存地址可能引发系统异常或崩溃，因此需要设计安全可靠的内存探测机制。

## 2 技术方案设计

### 2.1 总体架构

我设计实现了基于启发式算法的内存检测方案，该方案包含两个核心模块：
- `kern/mm/memdetect.h` - 接口声明
- `kern/mm/memdetect.c` - 具体实现

### 2.2 核心算法实现

#### 2.2.1 内存可访问性测试算法

`test_memory_accessible`函数采用实际的内存读写操作来验证目标地址的可访问性：

```c
static int test_memory_accessible(uintptr_t phys_addr) {
    volatile uint64_t *test_addr;
    uint64_t original_value, read_value;

    // 映射物理地址到虚拟地址
    test_addr = (volatile uint64_t *)(phys_addr + PHYSICAL_MEMORY_OFFSET);

    // 基本合理性检查
    if (phys_addr < DRAM_BASE || phys_addr > DRAM_BASE + 1024 * 1024 * 1024) {
        return 0;  // 超出合理内存范围
    }

    // 测试1：先读取原始值
    original_value = *test_addr;

    // 测试2：写入测试模式并读回
    *test_addr = MEMORY_TEST_PATTERN_1;
    read_value = *test_addr;

    if (read_value != MEMORY_TEST_PATTERN_1) {
        *test_addr = original_value;  // 恢复原始值
        return 0;  // 写入测试失败
    }

    // 测试3：使用不同模式进行双重验证
    *test_addr = MEMORY_TEST_PATTERN_2;
    read_value = *test_addr;
    *test_addr = original_value;  // 总是恢复原始值

    if (read_value != MEMORY_TEST_PATTERN_2) {
        return 0;  // 第二次测试失败
    }

    return 1;  // 内存可访问且可写
}
```

该算法的技术特点是通过三个阶段的测试来验证内存的可访问性：首先读取原始值并保存，然后写入特定测试模式并验证，最后使用不同模式进行二次验证。每次测试后都恢复原始值，确保不影响系统正常运行。

#### 2.2.2 渐进式内存边界检测算法

`detect_physical_memory_range`函数采用渐进式检测策略来定位内存边界：

```c
void detect_physical_memory_range(void) {
    // 从16MB开始，逐步检测更大的内存范围
    uintptr_t current_size = 16 * 1024 * 1024;  // 起始16MB
    uintptr_t max_size = 512 * 1024 * 1024;     // 最大检测512MB
    uintptr_t step_size = 16 * 1024 * 1024;    // 每次增加16MB

    // 渐进式测试：16MB -> 32MB -> 48MB -> ...
    while (current_size <= max_size) {
        uintptr_t test_addr = DRAM_BASE + current_size - PGSIZE;

        if (test_memory_accessible(test_addr)) {
            // 当前大小可访问，继续测试更大的
            detected_size = current_size;
            current_size += step_size;
        } else {
            // 找到不可访问的边界，停止
            break;
        }
    }

    // 进行更精细的边界检测（64KB步长）
    if (detected_size > step_size) {
        uintptr_t fine_start = detected_size - step_size + PGSIZE;
        uintptr_t fine_step = PGSIZE * 16;  // 64KB步长

        for (uintptr_t addr = fine_start; addr <= detected_size; addr += fine_step) {
            if (!test_memory_accessible(addr)) {
                break;
            }
            detected_size = addr - DRAM_BASE + fine_step;
        }
    }
}
```

该算法采用两阶段检测策略：第一阶段进行大步长（16MB）的粗粒度检测，快速确定大致的内存边界；第二阶段进行小步长（64KB）的精细检测，准确定位内存的实际边界。

## 3 系统集成与测试

### 3.1 集成策略

在`pmm.c`的`page_init()`函数中，DTB检测完成后调用内存探测功能：

```c
cprintf("Calling memory detection for verification...\n");
detect_physical_memory_range();
```

这种集成方式既不影响原有逻辑，又能验证DTB信息的准确性。

### 3.2 实验结果

在QEMU环境中的测试结果表明：

```
=== Physical Memory Detection Start (Real Access Test) ===
Starting with 16MB and progressively testing larger ranges...

Testing 16MB total...
✓ 16MB: ACCESSIBLE
Testing 32MB total...
✓ 32MB: ACCESSIBLE
Testing 48MB total...
✓ 48MB: ACCESSIBLE
Testing 64MB total...
✓ 64MB: ACCESSIBLE
Testing 80MB total...
✓ 80MB: ACCESSIBLE
Testing 96MB total...
✓ 96MB: ACCESSIBLE
Testing 112MB total...
✓ 112MB: ACCESSIBLE
Testing 128MB total...
✓ 128MB: ACCESSIBLE
Testing 144MB total...

=== Physical Memory Detection Results ===
Detected Physical Memory Base: 0x80000000
Detected Physical Memory End: 0x87FFFFFF
Detected Physical Memory Size: 0x8000000 (128 MB)
Total pages detected: 32768
```

### 3.3 结果验证

**DTB信息对比分析**：
- DTB获取的内存：128MB (0x80000000 - 0x87ffffff)
- 实际访问检测：128MB (0x80000000 - 0x87ffffff)

检测结果与DTB信息完全一致，验证了基于真实内存访问的探测算法的有效性。在16MB-128MB范围内的所有测试点都通过了真实的内存读写验证，而在144MB测试时系统正常响应，没有出现崩溃现象。
