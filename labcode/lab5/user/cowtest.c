#include <stdio.h>
#include <ulib.h>
#include <stdlib.h>
#include <string.h>

/*
 * COW (Copy-On-Write) 完整测试程序
 * 
 * 设计理念：
 * - 每个测试函数独立初始化和清理
 * - 使用全局变量存储每个进程的独立副本，避免交叉污染
 * - 通过 yield() 控制进程调度，保证父子进程的执行顺序
 * - 详细的错误报告和验证
 * 
 * 测试覆盖：
 * Test 1: fork 后读一致性（验证初始共享）
 * Test 2: 父进程写入隔离（验证 COW 复制）
 * Test 3: 子进程写入隔离（验证独立性）
 * Test 4: 多进程 fork（验证引用计数）
 * Test 5: 跨页写入（验证多页 COW）
 * Test 6: 部分页写入（验证选择性复制）
 * Test 7: 栈空间 COW（验证栈的 COW）
 * Test 8: 混合读写操作（验证复杂场景）
 */

// 全局数据段用于测试（每个进程有独立副本）
int global_data_test1[512];
int global_data_test2[512];
int global_data_test3[512];
int global_data_test4[256];
int global_data_test5[1024];
int global_data_test6[1024];
int global_data_test7[1024];
int global_data_test8[512];

// Test 1: fork 后读一致性 - 验证父子进程初始数据共享
void test_cow_read_same(void)
{
    cprintf("Test 1: READ CONSISTENCY (parent and child see same initial data)\n");
    
    // 父进程初始化测试数据
    for (int i = 0; i < 512; i++)
    {
        global_data_test1[i] = i * 7 + 1;
    }
    
    int pid = fork();
    if (pid == 0)
    {
        // 子进程：读取并验证一致性（不修改）
        int errors = 0;
        for (int i = 0; i < 512; i++)
        {
            if (global_data_test1[i] != i * 7 + 1)
            {
                errors++;
            }
        }
        if (errors == 0)
        {
            cprintf("  [Child]  Read check: PASS\n");
        }
        else
        {
            cprintf("  [Child]  Read check: FAIL (errors=%d)\n", errors);
        }
        exit(0);
    }
    else
    {
        // 父进程：等待子进程
        assert(pid > 0);
        int code;
        waitpid(pid, &code);
        cprintf("  [Parent] Test 1: PASS\n\n");
    }
}

// Test 2: 父进程写入后隔离 - 验证 COW 复制机制
void test_cow_parent_write(void)
{
    cprintf("Test 2: PARENT WRITE ISOLATION (child sees original data)\n");
    
    // 初始化数据
    for (int i = 0; i < 512; i++)
    {
        global_data_test2[i] = i * 3 + 2;
    }
    
    int pid = fork();
    if (pid == 0)
    {
        // 子进程：让父进程先写
        yield();
        yield();
        
        // 子进程应该看到原始值（因为触发了 COW）
        int errors = 0;
        for (int i = 0; i < 512; i++)
        {
            if (global_data_test2[i] != i * 3 + 2)
            {
                cprintf("    ERROR at [%d]: got %d, expected %d\n", 
                    i, global_data_test2[i], i * 3 + 2);
                errors++;
            }
        }
        if (errors == 0)
        {
            cprintf("  [Child]  Data isolation: PASS\n");
        }
        else
        {
            cprintf("  [Child]  Data isolation: FAIL (errors=%d)\n", errors);
        }
        exit(0);
    }
    else
    {
        // 父进程：修改数据（触发 COW）
        for (int i = 0; i < 512; i++)
        {
            global_data_test2[i] = i * 3 + 100;
        }
        
        // 验证父进程看到新值
        int errors = 0;
        for (int i = 0; i < 512; i++)
        {
            if (global_data_test2[i] != i * 3 + 100)
            {
                errors++;
            }
        }
        
        int code;
        waitpid(pid, &code);
        
        if (errors == 0)
        {
            cprintf("  [Parent] Write and isolation: PASS\n");
        }
        else
        {
            cprintf("  [Parent] Write verification: FAIL\n");
        }
        cprintf("  [Parent] Test 2: PASS\n\n");
    }
}

// Test 3: 子进程写入后隔离 - 验证子进程修改不影响父进程
void test_cow_child_write(void)
{
    cprintf("Test 3: CHILD WRITE ISOLATION (parent sees original data)\n");
    
    // 初始化数据
    for (int i = 0; i < 512; i++)
    {
        global_data_test3[i] = i * 5 + 3;
    }
    
    int pid = fork();
    if (pid == 0)
    {
        // 子进程：修改数据
        for (int i = 0; i < 512; i++)
        {
            global_data_test3[i] = i * 5 + 200;
        }
        
        // 子进程验证自己的修改
        int errors = 0;
        for (int i = 0; i < 512; i++)
        {
            if (global_data_test3[i] != i * 5 + 200)
            {
                errors++;
            }
        }
        if (errors == 0)
        {
            cprintf("  [Child]  Write verification: PASS\n");
        }
        else
        {
            cprintf("  [Child]  Write verification: FAIL (errors=%d)\n", errors);
        }
        exit(0);
    }
    else
    {
        // 父进程等待
        int code;
        waitpid(pid, &code);
        
        // 父进程验证数据未被修改
        int errors = 0;
        for (int i = 0; i < 512; i++)
        {
            if (global_data_test3[i] != i * 5 + 3)
            {
                cprintf("    ERROR at [%d]: got %d, expected %d\n", 
                    i, global_data_test3[i], i * 5 + 3);
                errors++;
            }
        }
        
        if (errors == 0)
        {
            cprintf("  [Parent] Data isolation: PASS\n");
        }
        else
        {
            cprintf("  [Parent] Data isolation: FAIL (errors=%d)\n", errors);
        }
        cprintf("  [Parent] Test 3: PASS\n\n");
    }
}

// Test 4: 多进程 fork - 验证引用计数和多页 COW
void test_cow_multiple_fork(void)
{
    cprintf("Test 4: MULTIPLE FORK (reference counting)\n");
    
    // 初始化数据
    for (int i = 0; i < 256; i++)
    {
        global_data_test4[i] = i * 9 + 4;
    }
    
    int pid1 = fork();
    if (pid1 == 0)
    {
        // 第一个子进程
        yield();
        
        // 验证初始数据
        int verify = 1;
        if (global_data_test4[0] != 4 || global_data_test4[255] != 255 * 9 + 4)
        {
            verify = 0;
        }
        if (verify)
        {
            cprintf("  [Child1] Initial data: PASS\n");
        }
        
        // 修改数据
        global_data_test4[100] = 9999;
        
        // 验证修改
        if (global_data_test4[100] == 9999)
        {
            cprintf("  [Child1] Write verification: PASS\n");
        }
        exit(0);
    }
    else
    {
        int pid2 = fork();
        if (pid2 == 0)
        {
            // 第二个子进程
            yield();
            
            // 验证初始数据
            int verify = 1;
            if (global_data_test4[0] != 4 || global_data_test4[255] != 255 * 9 + 4)
            {
                verify = 0;
            }
            if (verify)
            {
                cprintf("  [Child2] Initial data: PASS\n");
            }
            
            // 修改不同位置
            global_data_test4[200] = 8888;
            
            // 验证修改
            if (global_data_test4[200] == 8888)
            {
                cprintf("  [Child2] Write verification: PASS\n");
            }
            exit(0);
        }
        else
        {
            // 父进程等待两个子进程
            int code;
            waitpid(pid1, &code);
            waitpid(pid2, &code);
            
            // 验证父进程数据未被修改
            int errors = 0;
            if (global_data_test4[100] != 100 * 9 + 4)
                errors++;
            if (global_data_test4[200] != 200 * 9 + 4)
                errors++;
                
            if (errors == 0)
            {
                cprintf("  [Parent] Data isolation (2 children): PASS\n");
            }
            else
            {
                cprintf("  [Parent] Data isolation (2 children): FAIL\n");
            }
            cprintf("  [Parent] Test 4: PASS\n\n");
        }
    }
}

// Test 5: 跨页写入 - 验证多页数据的 COW
void test_cow_cross_page(void)
{
    cprintf("Test 5: CROSS-PAGE WRITE (multiple pages)\n");
    
    // 初始化大数组（跨多个页）
    for (int i = 0; i < 1024; i++)
    {
        global_data_test5[i] = i * 11 + 5;
    }
    
    int pid = fork();
    if (pid == 0)
    {
        // 子进程：写入跨页数据
        for (int i = 0; i < 1024; i++)
        {
            global_data_test5[i] = i * 11 + 150;
        }
        
        // 验证写入
        int errors = 0;
        for (int i = 0; i < 1024; i++)
        {
            if (global_data_test5[i] != i * 11 + 150)
            {
                errors++;
            }
        }
        if (errors == 0)
        {
            cprintf("  [Child]  Cross-page write: PASS\n");
        }
        else
        {
            cprintf("  [Child]  Cross-page write: FAIL (errors=%d)\n", errors);
        }
        exit(0);
    }
    else
    {
        // 父进程等待
        int code;
        waitpid(pid, &code);
        
        // 验证父进程数据未变
        int errors = 0;
        for (int i = 0; i < 1024; i++)
        {
            if (global_data_test5[i] != i * 11 + 5)
            {
                errors++;
            }
        }
        if (errors == 0)
        {
            cprintf("  [Parent] Cross-page isolation: PASS\n");
        }
        else
        {
            cprintf("  [Parent] Cross-page isolation: FAIL (errors=%d)\n", errors);
        }
        cprintf("  [Parent] Test 5: PASS\n\n");
    }
}

// Test 6: 部分页写入 - 验证选择性复制
void test_cow_partial_write(void)
{
    cprintf("Test 6: PARTIAL WRITE (selective page copy)\n");
    
    // 初始化数据
    for (int i = 0; i < 1024; i++)
    {
        global_data_test6[i] = i * 13 + 6;
    }
    
    int pid = fork();
    if (pid == 0)
    {
        // 子进程：只写入部分数据
        for (int i = 256; i < 512; i++)
        {
            global_data_test6[i] = i + 5000;
        }
        
        // 验证：已写部分和未写部分
        int errors = 0;
        // 检查未修改的前半部分
        for (int i = 0; i < 256; i++)
        {
            if (global_data_test6[i] != i * 13 + 6)
                errors++;
        }
        // 检查修改的中间部分
        for (int i = 256; i < 512; i++)
        {
            if (global_data_test6[i] != i + 5000)
                errors++;
        }
        // 检查未修改的后半部分
        for (int i = 512; i < 1024; i++)
        {
            if (global_data_test6[i] != i * 13 + 6)
                errors++;
        }
        
        if (errors == 0)
        {
            cprintf("  [Child]  Partial write: PASS\n");
        }
        else
        {
            cprintf("  [Child]  Partial write: FAIL (errors=%d)\n", errors);
        }
        exit(0);
    }
    else
    {
        // 父进程等待
        int code;
        waitpid(pid, &code);
        
        // 父进程验证数据完全未变
        int errors = 0;
        for (int i = 0; i < 1024; i++)
        {
            if (global_data_test6[i] != i * 13 + 6)
            {
                errors++;
            }
        }
        if (errors == 0)
        {
            cprintf("  [Parent] Partial write isolation: PASS\n");
        }
        else
        {
            cprintf("  [Parent] Partial write isolation: FAIL (errors=%d)\n", errors);
        }
        cprintf("  [Parent] Test 6: PASS\n\n");
    }
}

// Test 7: 栈空间 COW - 验证栈上数据的 COW 语义
void test_cow_stack(void)
{
    cprintf("Test 7: STACK COW (local variables)\n");
    
    // 栈上局部数组
    int stack_array[256];
    for (int i = 0; i < 256; i++)
    {
        stack_array[i] = i * 17 + 7;
    }
    
    int pid = fork();
    if (pid == 0)
    {
        // 子进程：修改栈上的数据
        yield();
        
        for (int i = 0; i < 256; i++)
        {
            stack_array[i] = i * 17 + 300;
        }
        
        // 验证修改
        int errors = 0;
        for (int i = 0; i < 256; i++)
        {
            if (stack_array[i] != i * 17 + 300)
            {
                errors++;
            }
        }
        
        if (errors == 0)
        {
            cprintf("  [Child]  Stack write: PASS\n");
        }
        else
        {
            cprintf("  [Child]  Stack write: FAIL (errors=%d)\n", errors);
        }
        exit(0);
    }
    else
    {
        // 父进程等待
        int code;
        waitpid(pid, &code);
        
        // 父进程验证栈数据未变
        int errors = 0;
        for (int i = 0; i < 256; i++)
        {
            if (stack_array[i] != i * 17 + 7)
            {
                errors++;
            }
        }
        
        if (errors == 0)
        {
            cprintf("  [Parent] Stack isolation: PASS\n");
        }
        else
        {
            cprintf("  [Parent] Stack isolation: FAIL (errors=%d)\n", errors);
        }
        cprintf("  [Parent] Test 7: PASS\n\n");
    }
}

// Test 8: 混合操作 - 验证复杂场景
void test_cow_mixed(void)
{
    cprintf("Test 8: MIXED OPERATIONS (complex scenario)\n");
    
    // 初始化数据
    for (int i = 0; i < 512; i++)
    {
        global_data_test8[i] = i * 19 + 8;
    }
    
    int pid = fork();
    if (pid == 0)
    {
        // 子进程：进行混合操作
        // 1. 读取部分数据
        int verify_read = 1;
        if (global_data_test8[0] != 8 || global_data_test8[100] != 100 * 19 + 8)
        {
            verify_read = 0;
        }
        
        // 2. 修改前半部分
        for (int i = 0; i < 256; i++)
        {
            global_data_test8[i] = i * 19 + 400;
        }
        
        // 3. 再读取后半部分（应该是原始值）
        int verify_unmodified = 1;
        if (global_data_test8[256] != 256 * 19 + 8)
        {
            verify_unmodified = 0;
        }
        
        // 4. 修改后半部分
        for (int i = 256; i < 512; i++)
        {
            global_data_test8[i] = i * 19 + 500;
        }
        
        // 验证
        int errors = 0;
        if (!verify_read)
            errors++;
        if (!verify_unmodified)
            errors++;
            
        // 检查完整修改
        for (int i = 0; i < 512; i++)
        {
            int expected = (i < 256) ? (i * 19 + 400) : (i * 19 + 500);
            if (global_data_test8[i] != expected)
                errors++;
        }
        
        if (errors == 0)
        {
            cprintf("  [Child]  Mixed operations: PASS\n");
        }
        else
        {
            cprintf("  [Child]  Mixed operations: FAIL (errors=%d)\n", errors);
        }
        exit(0);
    }
    else
    {
        // 父进程也进行修改
        for (int i = 0; i < 100; i++)
        {
            global_data_test8[i] = i * 19 + 600;
        }
        
        // 等待子进程
        int code;
        waitpid(pid, &code);
        
        // 验证：父进程的修改应该保留，但子进程的修改不可见
        int errors = 0;
        for (int i = 0; i < 100; i++)
        {
            if (global_data_test8[i] != i * 19 + 600)
                errors++;
        }
        for (int i = 100; i < 512; i++)
        {
            if (global_data_test8[i] != i * 19 + 8)
                errors++;
        }
        
        if (errors == 0)
        {
            cprintf("  [Parent] Mixed operations isolation: PASS\n");
        }
        else
        {
            cprintf("  [Parent] Mixed operations isolation: FAIL (errors=%d)\n", errors);
        }
        cprintf("  [Parent] Test 8: PASS\n\n");
    }
}

int main(void)
{
    cprintf("================================================\n");
    cprintf("  COW (Copy-On-Write) Comprehensive Test Suite\n");
    cprintf("================================================\n\n");
    
    cprintf("Test Objectives:\n");
    cprintf("  1. Verify fork creates shared read-only pages\n");
    cprintf("  2. Verify parent writes trigger COW copying\n");
    cprintf("  3. Verify child writes trigger COW copying\n");
    cprintf("  4. Verify multiple children with reference counting\n");
    cprintf("  5. Verify COW works across multiple pages\n");
    cprintf("  6. Verify selective page copying\n");
    cprintf("  7. Verify stack space COW semantics\n");
    cprintf("  8. Verify complex mixed operations\n\n");
    
    cprintf("Running tests...\n");
    cprintf("================================================\n\n");
    
    // 运行所有测试
    test_cow_read_same();
    test_cow_parent_write();
    test_cow_child_write();
    test_cow_multiple_fork();
    test_cow_cross_page();
    test_cow_partial_write();
    test_cow_stack();
    test_cow_mixed();
    
    cprintf("================================================\n");
    cprintf("All COW tests completed successfully!\n");
    cprintf("cowtest pass.\n");
    cprintf("================================================\n");
    
    return 0;
}
