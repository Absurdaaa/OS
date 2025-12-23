#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

/*
 * 简单 FIFO（可抢占）调度：
 *  - 就绪队列使用链表按到达顺序排列
 *  - time_slice 用于与框架对齐，耗尽则请求重新调度
 */

static void
fifo_init(struct run_queue *rq)
{
    list_init(&(rq->run_list));
    rq->lab6_run_pool = NULL;
    rq->proc_num = 0;
}

static void
fifo_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    if (proc->time_slice <= 0 || proc->time_slice > rq->max_time_slice)
    {
        proc->time_slice = rq->max_time_slice;
    }
    proc->rq = rq;
    list_add_before(&(rq->run_list), &(proc->run_link));
    rq->proc_num++;
}

static void
fifo_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    list_del_init(&(proc->run_link));
    proc->rq = NULL;
    if (rq->proc_num > 0)
    {
        rq->proc_num--;
    }
}

static struct proc_struct *
fifo_pick_next(struct run_queue *rq)
{
    if (list_empty(&(rq->run_list)))
    {
        return NULL;
    }
    list_entry_t *le = list_next(&(rq->run_list));
    return le2proc(le, run_link);
}

static void
fifo_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    if (proc->time_slice > 0)
    {
        proc->time_slice--;
    }
    if (proc->time_slice == 0)
    {
        proc->need_resched = 1;
    }
}

struct sched_class fifo_sched_class = {
    .name = "fifo_scheduler",
    .init = fifo_init,
    .enqueue = fifo_enqueue,
    .dequeue = fifo_dequeue,
    .pick_next = fifo_pick_next,
    .proc_tick = fifo_proc_tick,
};
