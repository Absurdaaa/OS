#include <stdio.h>
#include <ulib.h>
#include <stdlib.h>

/*
 * Dirty COW 漏洞复现测试
 * 
 * CVE-2016-5195: 在多线程环境下，利用 COW 机制的竞态条件，
 * 可以在不具有写权限的情况下修改只读内存页。
 * 
 * 在 uCore 中，由于是单核且缺页处理时关中断，真正的竞态条件
 * 难以触发。但我们可以模拟漏洞的利用场景。
 */

// 模拟一个只读的共享数据（本应是父子进程共享的只读页）
int readonly_data[256] __attribute__((section(".data")));

/*
 * 测试1: 模拟 Dirty COW 的攻击场景
 * 
 * 场景：父进程有一个只读映射（通过 COW 机制），子进程尝试
 * 通过反复触发缺页来竞争修改只读页面
 */
void test_dirtycow_race_simulation(void)
{
    cprintf("[dirtycow_test] RaceConditionSim ... ");
    
    // 初始化只读数据
    for (int i = 0; i < 256; i++) {
        readonly_data[i] = i * 2;
    }
    
    // minimal output
    
    int pid = fork();
    
    if (pid == 0) {
        // 子进程：尝试模拟 Dirty COW 攻击
        // minimal
        
        // 策略1: 反复尝试写入（在真实漏洞中，这会与 COW 处理竞争）
        volatile int *target = &readonly_data[0];
        int attack_value = 0xDEADBEEF;
        
        // 尝试多次写入来触发竞态
        for (int attempt = 0; attempt < 100; attempt++) {
            // 在真实的 Dirty COW 中，这里会：
            // 1. 通过 madvise(MADV_DONTNEED) 丢弃页面
            // 2. 在 COW 处理过程中写入
            // 3. 利用时间窗口修改原始只读页
            
            *target = attack_value;
            
            // 验证是否成功写入
            if (*target == attack_value) {
                // success
                break;
            }
        }
        
        // 检查是否意外修改了父进程的数据
        // minimal
        exit(0);
    }
    else {
        // 父进程：等待并检查数据是否被子进程修改
        int code;
        waitpid(pid, &code);
        
        cprintf(readonly_data[0] == 0 ? "PASS\n" : "FAIL\n");
    }
    
    cprintf("");
}

/*
 * 测试2: 检查页引用计数的正确性
 * 
 * Dirty COW 的一个变种是利用引用计数的错误更新
 */
void test_reference_count_integrity(void)
{
    cprintf("[dirtycow_test] RefCountIntegrity ... ");
    
    int shared_array[128];
    for (int i = 0; i < 128; i++) {
        shared_array[i] = i * 3;
    }
    
    // minimal
    
    int pid1 = fork();
    if (pid1 == 0) {
        // 第一个子进程
        // minimal
        
        // 触发 COW
        shared_array[0] = 1111;
        
        // minimal
        exit(0);
    }
    
    // 父进程立即 fork 第二个子进程
    int pid2 = fork();
    if (pid2 == 0) {
        // 第二个子进程
        yield(); // 让 Child1 先执行
        
        // minimal
        
        // 此时页面引用计数应该正确
        shared_array[0] = 2222;
        
        // minimal
        exit(0);
    }
    
    // 父进程等待两个子进程
    int code;
    waitpid(pid1, &code);
    waitpid(pid2, &code);
    
    cprintf(shared_array[0] == 0 ? "PASS\n" : "FAIL\n");
    
    cprintf("");
}

/*
 * 测试3: 检查 COW 页面权限的正确设置
 * 
 * 验证 fork 后页面权限是否正确设为只读+COW
 */
void test_cow_permission_check(void)
{
    cprintf("[dirtycow_test] CowPermissionCheck ... ");
    
    int test_data[64];
    for (int i = 0; i < 64; i++) {
        test_data[i] = i * 5;
    }
    
    // minimal
    
    int pid = fork();
    if (pid == 0) {
        // 子进程：检查能否读取（应该可以）
        // minimal
        
        // 尝试写入（应该触发 COW）
        test_data[10] = 9999;
        
        // minimal
        exit(0);
    }
    else {
        // 父进程也尝试写入
        test_data[20] = 8888;
        
        int code;
        waitpid(pid, &code);
        
        cprintf((test_data[10] == 10 * 5 && test_data[20] == 8888) ? "PASS\n" : "FAIL\n");
    }
    
    cprintf("");
}

/*
 * 测试4: 模拟写时复制过程中的时间窗口
 * 
 * 在真实的 Dirty COW 漏洞中，攻击者利用 madvise + write 的竞争
 * 来在 COW 处理的时间窗口中修改只读页
 */
void test_cow_timing_window(void)
{
    cprintf("[dirtycow_test] TimingWindowAttack ... ");
    
    int sensitive_data[32];
    for (int i = 0; i < 32; i++) {
        sensitive_data[i] = 0x1000 + i;
    }
    
    // minimal
    
    int pid = fork();
    if (pid == 0) {
        // 子进程：模拟攻击者
        // minimal
        
        volatile int *target = &sensitive_data[0];
        int malicious_value = 0xBADC0DE;
        int success = 0;
        
        // 尝试在 COW 处理的时间窗口中写入
        for (int i = 0; i < 50; i++) {
            // 在真实攻击中，这里会：
            // 线程1: 反复调用 madvise(MADV_DONTNEED) 来丢弃页面
            // 线程2: 反复写入目标地址
            // 利用 COW 复制和页面丢弃之间的竞态窗口
            
            *target = malicious_value;
            
            if (*target == malicious_value) {
                success = 1;
                // minimal
                break;
            }
            
            // 模拟时间延迟
            for (volatile int j = 0; j < 100; j++);
        }
        
        // minimal
        exit(0);
    }
    else {
        int code;
        waitpid(pid, &code);
        
        cprintf(sensitive_data[0] == 0x1000 ? "PASS\n" : "FAIL\n");
    }
    
    cprintf("");
}

int main(void)
{
    // minimal start
    
    // 运行所有测试
    test_dirtycow_race_simulation();
    test_reference_count_integrity();
    test_cow_permission_check();
    test_cow_timing_window();
    
    // minimal end
    
    return 0;
}
