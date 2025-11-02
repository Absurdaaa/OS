#ifndef __KERN_MM_SLUB_PMM_H__
#define __KERN_MM_SLUB_PMM_H__

#include <pmm.h>

extern const struct pmm_manager slub_pmm_manager;

// 如果需要暴露字节分配接口
void *slub_alloc_bytes(size_t bytes);

#endif /* ! __KERN_MM_SLUB_PMM_H__ */
