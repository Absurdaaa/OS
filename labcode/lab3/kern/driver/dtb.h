#ifndef __KERN_DRIVER_DTB_H__
#define __KERN_DRIVER_DTB_H__

#include <defs.h>

// Defined in entry.S
extern uint64_t boot_hartid; // 保存启动时的主核（hart）编号，告诉内核当前是由哪个CPU核心启动的。
extern uint64_t boot_dtb; // 保存启动时传入的设备树（DTB）地址，内核通过该地址解析硬件信息。

void dtb_init(void);
uint64_t get_memory_base(void);
uint64_t get_memory_size(void);

#endif /* !__KERN_DRIVER_DTB_H__ */
