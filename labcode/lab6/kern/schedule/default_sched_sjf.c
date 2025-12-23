#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

/*
 * 最短作业优先（简单版，按 time_slice 估计长度，抢占式）
 *  - 使用有序链表：time_slice 越小越靠前
 *  - 每次选最短剩余的进程运行；耗尽时间片则请求调度
 */

static void
sjf_init(struct run_queue *rq)
{
    list_init(&(rq->run_list));
    rq->lab6_run_pool = NULL;
    rq->proc_num = 0;
}

static void
sjf_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    if (proc->time_slice <= 0)
    {
        proc->time_slice = rq->max_time_slice;
    }
    proc->rq = rq;

    list_entry_t *le = &(rq->run_list);
    while ((le = list_next(le)) != &(rq->run_list))
    {
        struct proc_struct *p = le2proc(le, run_link);
        if (proc->time_slice < p->time_slice)
        {
            break;
        }
    }
    list_add_before(le, &(proc->run_link));
    rq->proc_num++;
}

static void
sjf_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    list_del_init(&(proc->run_link));
    proc->rq = NULL;
    if (rq->proc_num > 0)
    {
        rq->proc_num--;
    }
}

static struct proc_struct *
sjf_pick_next(struct run_queue *rq)
{
    if (list_empty(&(rq->run_list)))
    {
        return NULL;
    }
    list_entry_t *le = list_next(&(rq->run_list));
    return le2proc(le, run_link);
}

static void
sjf_proc_tick(struct run_queue *rq, struct proc_struct *proc)
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

struct sched_class sjf_sched_class = {
    .name = "sjf_scheduler",
    .init = sjf_init,
    .enqueue = sjf_enqueue,
    .dequeue = sjf_dequeue,
    .pick_next = sjf_pick_next,
    .proc_tick = sjf_proc_tick,
};
