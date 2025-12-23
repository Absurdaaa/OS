#include <ulib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// 简单调度基准：混合 CPU 密集与 IO/交互型任务，观察不同调度算法下的时间片分配情况

static void
spin_cpu(int ms, const char *tag)
{
    int start = gettime_msec();
    unsigned long iter = 0;
    while (gettime_msec() - start < ms)
    {
        // 简单忙等
        for (volatile int i = 0; i < 1000; i++)
            ;
        iter++;
    }
    cprintf("[CPU ] pid=%d tag=%s iter=%lu elapsed=%dms\n", getpid(), tag, iter, gettime_msec() - start);
    exit((int)(iter & 0xFFFF));
}

static void
io_style(int ms, const char *tag)
{
    int start = gettime_msec();
    int ticks = 0;
    while (gettime_msec() - start < ms)
    {
        yield();
        int t0 = gettime_msec();
        while (gettime_msec() - t0 < 10)
            ;
        ticks++;
    }
    cprintf("[IO  ] pid=%d tag=%s ticks=%d elapsed=%dms\n", getpid(), tag, ticks, gettime_msec() - start);
    exit(ticks);
}

int main(void)
{
    cprintf("schedbench: mix cpu/io workers, each ~500ms\n");

    const int cpu_ms = 500;
    const int io_ms = 500;
    const int ncpu = 3, nio = 2;
    int pids[5], idx = 0;

    for (int i = 0; i < ncpu; i++)
    {
        if ((pids[idx] = fork()) == 0)
        {
            spin_cpu(cpu_ms, "cpu");
        }
        idx++;
    }
    for (int i = 0; i < nio; i++)
    {
        if ((pids[idx] = fork()) == 0)
        {
            io_style(io_ms, "io");
        }
        idx++;
    }

    for (int i = 0; i < idx; i++)
    {
        int status = 0;
        waitpid(pids[i], &status);
        cprintf("child pid=%d exit=%d\n", pids[i], status);
    }

    cprintf("schedbench done.\n");
    return 0;
}
