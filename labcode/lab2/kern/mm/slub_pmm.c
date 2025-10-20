// slub_pmm.c  —— 简化版 SLUB：对象级分配 + 复用伙伴系统做页级分配
#include <pmm.h>
#include <list.h>
#include <string.h>
#include <slub_pmm.h>
#include <stdio.h>
#include <buddy_system_pmm.h> // 直接复用伙伴系统做页分配  :contentReference[oaicite:2]{index=2}

/*
 * 设计说明（简化版）：
 *  - 单页 slab（SLAB_ORDER = 0），便于通过 page 边界快速获得 slab 头
 *  - slab 头部直接放在页的起始 kvaddr 处，不改 struct Page
 *  - freelist：对象首部存放 void* next 指针；分配/回收 O(1)
 *  - cache 维护 partial / full 两个链表（空 slab 回收给伙伴）
 *  - kmalloc 提供常用 size-class（16,32,64,...,2048），可按需扩展
 *
 * 注意：
 *  - 若要改为多页 slab：需要在 slab 中记录 order，并在 obj→slab 映射时
 *    使用向下对齐到 (PGSIZE << order) 的方式；本实现先保持单页，易于落地。
 */

// ========== 参数与宏 ==========
#ifndef SLAB_ORDER
#define SLAB_ORDER 0 // 单页 slab
#endif
#define SLAB_PAGES (1U << SLAB_ORDER)
#define SLAB_BYTES (PGSIZE * SLAB_PAGES)
#define SLAB_MAGIC 0x51B1B1B1u // 仅用于调试标识

// ========== 前置声明 ==========
struct kmem_cache;
struct slab;

// ========== slab 结构（放在页起始处） ==========
struct slab
{
  unsigned int magic;       // 调试用标识
  struct kmem_cache *cache; // 所属 cache
  void *freelist;           // 空闲 object 链
  unsigned short inuse;     // 已分配 object 数
  unsigned short objects;   // 总 object 数
  list_entry_t list_link;   // 串到 cache 的 partial/full
};

// ========== kmem_cache 结构 ==========
struct kmem_cache
{
  const char *name;
  unsigned int size;        // 每个对象的总大小（含对齐）
  unsigned int align;       // 对齐
  unsigned int object_size; // 提供给用户的大小（不含内部对齐开销）
  unsigned int min_partial; // partial 数阈值（简化：不用）
  list_entry_t list_node;   // 串到全局 cache_list
  list_entry_t partial;     // 半满 slab 链
  list_entry_t full;        // 满 slab 链
};

// ========== 全局 ==========
static list_entry_t cache_list; // 全部 cache 的链
static int slub_initialized = 0;

// ========== 工具函数 ==========
static inline unsigned int round_up(unsigned int x, unsigned int a)
{
  return (x + a - 1) & ~(a - 1);
}

static inline struct slab *kvaddr_to_slab(void *kvaddr_page_base)
{
  return (struct slab *)kvaddr_page_base;
}

static inline struct slab *obj_to_slab(void *obj)
{
  // 单页 slab：直接回页边界
  uintptr_t base = (uintptr_t)obj & ~(PGSIZE - 1);
  struct slab *s = kvaddr_to_slab((void *)base);
  return (s->magic == SLAB_MAGIC) ? s : NULL;
  return NULL;
}

// 查看是否还有空位和是否空
static inline int slab_is_full(struct slab *s) { return s->inuse == s->objects; }
static inline int slab_is_empty(struct slab *s) { return s->inuse == 0; }

// ========== 从伙伴系统分配/释放 slab 页 ==========
static struct slab *slab_new(struct kmem_cache *cache)
{
  struct Page *page = buddy_system_pmm_manager.alloc_pages(SLAB_PAGES); // 复用 buddy  :contentReference[oaicite:3]{index=3}
  
  // 分配失败
  if (!page)
    return NULL;

  // 获取这个页的虚拟地址
  void *kv = page2kva(page);
  memset(kv, 0, SLAB_BYTES);

  struct slab *s = (struct slab *)kv;
  s->magic = SLAB_MAGIC;
  s->cache = cache;
  list_init(&(s->list_link));

  // 计算可用区域：跳过 slab 头，按照 align 对齐
  unsigned int offset = round_up(sizeof(struct slab), cache->align);
  unsigned int usable = SLAB_BYTES - offset;
  if (usable < cache->size)
  {
    // 太挤，说明对象太大或 slab_order 太小
    buddy_system_pmm_manager.free_pages(page, SLAB_PAGES);
    return NULL;
  }

  s->objects = (unsigned short)(usable / cache->size);
  s->inuse = 0;

  // 构造 freelist：对象首部存储 next 指针
  char *p = (char *)kv + offset;
  void **prev = NULL;
  for (unsigned int i = 0; i < s->objects; i++)
  {
    void *obj = (void *)(p + i * cache->size);
    if (prev)
    {
      *prev = obj;
    }
    else
    {
      s->freelist = obj;
    }
    prev = (void **)obj;
  }
  if (prev)
    *prev = NULL;

  return s;
}

static void slab_release(struct slab *s)
{
  // 单页 slab：直接以页为单位释放回伙伴系统
  struct Page *page = kva2page((void *)s);
  buddy_system_pmm_manager.free_pages(page, SLAB_PAGES); // 复用 buddy  :contentReference[oaicite:4]{index=4}
}

// ========== cache 管理 ==========
static struct kmem_cache *kmem_cache_create(const char *name, unsigned int size, unsigned int align)
{
  if (!slub_initialized)
  {
    list_init(&cache_list);
    slub_initialized = 1;
  }
  if (align == 0)
    align = sizeof(void *);
  if (size == 0)
    return NULL;

  struct kmem_cache *c = (struct kmem_cache *)buddy_system_pmm_manager.alloc_pages(1);
  if (!c)
    return NULL;
  memset(page2kva(kva2page(c)), 0, PGSIZE); // 保守清零整页（c 在页上）

  // 直接把 cache 结构体放在这页的开头使用
  c = (struct kmem_cache *)page2kva(kva2page(c));

  c->name = name;
  c->object_size = size;
  c->align = align;
  c->size = round_up(size > sizeof(void *) ? size : sizeof(void *), align); // 至少容纳next指针
  c->min_partial = 0;
  list_init(&c->list_node);
  list_init(&c->partial);
  list_init(&c->full);

  list_add(&cache_list, &c->list_node);
  return c;
}

static void kmem_cache_destroy(struct kmem_cache *c)
{
  // 回收所有 partial/full slabs
  list_entry_t *le, *next;
  // partial
  le = list_next(&c->partial);
  while (le != &c->partial)
  {
    next = list_next(le);
    struct slab *s = to_struct(le, struct slab, list_link);
    list_del(le);
    slab_release(s);
    le = next;
  }
  // full
  le = list_next(&c->full);
  while (le != &c->full)
  {
    next = list_next(le);
    struct slab *s = to_struct(le, struct slab, list_link);
    list_del(le);
    slab_release(s);
    le = next;
  }
  // 把 cache 自己所在页也释放
  list_del(&c->list_node);
  struct Page *p = kva2page((void *)c);
  buddy_system_pmm_manager.free_pages(p, 1);
}

// ========== 对象分配/回收 ==========
static void *kmem_cache_alloc(struct kmem_cache *c)
{
  // 先从 partial 找 slab
  struct slab *s = NULL;
  if (!list_empty(&c->partial))
  {
    s = to_struct(list_next(&c->partial), struct slab, list_link);
  }
  else
  {
    // partial 没有，尝试新建
    s = slab_new(c);
    if (!s)
      return NULL;
    list_add(&c->partial, &s->list_link);
  }

  // 从 slab 弹出一个 object
  void *obj = s->freelist;
  if (!obj)
  {
    // 理论不该发生：partial 的 slab 一定有空位；兜底转移到 full 并再起一个
    list_del(&s->list_link);
    list_add(&c->full, &s->list_link);
    s = slab_new(c);
    if (!s)
      return NULL;
    list_add(&c->partial, &s->list_link);
    obj = s->freelist;
  }
  s->freelist = *((void **)obj);
  s->inuse++;

  // 若 slab 已满，移到 full
  if (slab_is_full(s))
  {
    list_del(&s->list_link);
    list_add(&c->full, &s->list_link);
  }
  return obj;
}

static void kmem_cache_free(struct kmem_cache *c, void *obj)
{
  if (!obj)
    return;
  struct slab *s = obj_to_slab(obj);
  if (!s || s->cache != c || s->magic != SLAB_MAGIC)
  {
    // 非法对象或 cache 不匹配
    return;
  }

  // 如果 slab 在 full，需要移回 partial
  if (slab_is_full(s))
  {
    list_del(&s->list_link);
    list_add(&c->partial, &s->list_link);
  }

  // 头插回 freelist
  *((void **)obj) = s->freelist;
  s->freelist = obj;
  s->inuse--;

  // 空 slab 直接释放给伙伴系统（不进空链表，简化）
  if (slab_is_empty(s))
  {
    list_del(&s->list_link);
    slab_release(s);
  }
}

// ========== kmalloc/kfree：常用 size-class ==========
static struct kmem_cache *size_caches[9] = {0};
// 16,32,64,128,256,512,1024,2048,4096(可选；单页 slab 会装不下加头时的大对象，默认停到2048)
static const unsigned int size_classes[8] = {
    16, 32, 64, 128, 256, 512, 1024, 2048};

static void init_size_caches(void)
{
  if (size_caches[0])
    return; // 已初始化
  for (int i = 0; i < 8; i++)
  {
    char *name = "kmalloc";
    // 注意：这里为了简化避免动态字符串，直接用同名 cache；
    // 如果你有 kprintf/snprintf，可拼 "kmalloc-%u"。
    size_caches[i] = kmem_cache_create(name, size_classes[i], sizeof(void *));
  }
}

static struct kmem_cache *select_cache(size_t size)
{
  for (int i = 0; i < 8; i++)
  {
    if (size <= size_classes[i])
      return size_caches[i];
  }
  return NULL;
}

void *kmalloc(size_t size)
{
  init_size_caches();
  struct kmem_cache *c = select_cache(size);
  if (c)
    return kmem_cache_alloc(c);

  // 超过 2048 的走页分配（对齐到页）
  size_t n = (size + PGSIZE - 1) / PGSIZE;
  struct Page *p = buddy_system_pmm_manager.alloc_pages(n); // 复用 buddy  :contentReference[oaicite:5]{index=5}
  return p ? page2kva(p) : NULL;
}

void kfree(void *ptr, size_t size_hint /* 可传0 */)
{
  if (!ptr)
    return;

  // 尝试按对象回收路径
  struct slab *s = obj_to_slab(ptr);
  if (s && s->magic == SLAB_MAGIC && s->cache)
  {
    kmem_cache_free(s->cache, ptr);
    return;
  }

  // 否则按页回收（要求调用方提供 size_hint 或者我们尝试只按 1 页回收）
  if (size_hint > 0)
  {
    size_t n = (size_hint + PGSIZE - 1) / PGSIZE;
    buddy_system_pmm_manager.free_pages(kva2page(ptr), n); // 复用 buddy  :contentReference[oaicite:6]{index=6}
  }
  else
  {
    // 没有 hint：最安全的是让上层传入；这里保守按 1 页回收（如不合适请改掉）
    buddy_system_pmm_manager.free_pages(kva2page(ptr), 1);
  }
}

// ========== pmm_manager：页级接口继续复用 buddy ==========
static void slub_init(void)
{
  // 初始化全局 cache 链表
  if (!slub_initialized)
  {
    list_init(&cache_list);
    slub_initialized = 1;
  }
  // 伙伴系统初始化
  buddy_system_pmm_manager.init(); // 复用 buddy  :contentReference[oaicite:7]{index=7}
  // 初始化 kmalloc size-classes
  init_size_caches();
}

static void slub_init_memmap(struct Page *base, size_t n)
{
  buddy_system_pmm_manager.init_memmap(base, n); // 复用 buddy  :contentReference[oaicite:8]{index=8}
}

static struct Page *slub_alloc_pages(size_t n)
{
  return buddy_system_pmm_manager.alloc_pages(n); // 复用 buddy  :contentReference[oaicite:9]{index=9}
}

static void slub_free_pages(struct Page *base, size_t n)
{
  buddy_system_pmm_manager.free_pages(base, n); // 复用 buddy  :contentReference[oaicite:10]{index=10}
}

static size_t slub_nr_free_pages(void)
{
  return buddy_system_pmm_manager.nr_free_pages(); // 复用 buddy  :contentReference[oaicite:11]{index=11}
}

// 放在 slub_pmm.c 内，替换原有 slub_check() 实现
static void slub_check(void)
{
  extern const struct pmm_manager buddy_system_pmm_manager; // 如果你想顺带校验 buddy，可保留；不想就删掉这行和调用

// ====== 工具：打印/断言 ======
#ifndef SLUBCHK_PRINTF
#define SLUBCHK_PRINTF cprintf // 你的内核一般有 cprintf；没有就改成 kprintf/printf
#endif
#ifndef SLUBCHK_ASSERT
#define SLUBCHK_ASSERT assert // ucore 风格里通常有 assert
#endif

  // ====== 前置：页数基线 ======
  size_t free0 = buddy_system_pmm_manager.nr_free_pages();

  SLUBCHK_PRINTF("[SLUB-CHECK] begin, free pages = %u\n", (unsigned)free0);

  // （可选）先跑一遍 buddy 的页级自检，确保底座没问题
  // 如果你的 buddy check 会影响总页数统计，建议放在 init 后第一次、或注释掉这两行
  if (buddy_system_pmm_manager.check)
  {
    SLUBCHK_PRINTF("[SLUB-CHECK] running buddy check (optional)...\n");
    buddy_system_pmm_manager.check();
  }

  // ====== 1) 基础：创建一个 64B 的 cache ======
  const unsigned OBJ_SZ = 64;
  struct kmem_cache *c64 = kmem_cache_create("kmalloc-64", OBJ_SZ, sizeof(void *));
  SLUBCHK_ASSERT(c64 != NULL);
  SLUBCHK_PRINTF("[SLUB-CHECK] kmem_cache_create(64) ok, cache=%p\n", c64);

  // 计算单个 slab 能装多少对象（要与 slab_new() 的逻辑严格一致）
  unsigned off = round_up(sizeof(struct slab), c64->align);
  SLUBCHK_ASSERT(SLAB_BYTES > off);
  unsigned cap = (SLAB_BYTES - off) / c64->size;
  SLUBCHK_ASSERT(cap > 0);
  SLUBCHK_PRINTF("[SLUB-CHECK] slab capacity for 64B = %u objects (order=%d)\n", cap, SLAB_ORDER);

  // ====== 2) 分配 cap 个对象：应只产生 1 个 slab，占用 1 * SLAB_PAGES 页 ======
  size_t free1a_before = buddy_system_pmm_manager.nr_free_pages();

  void **objs = (void **)kmalloc(sizeof(void *) * (cap + 2)); // 临时记录已分配的对象指针
  SLUBCHK_ASSERT(objs != NULL);

  for (unsigned i = 0; i < cap; i++)
  {
    objs[i] = kmem_cache_alloc(c64);
    SLUBCHK_ASSERT(objs[i] != NULL);
    // 简单一致性：对象必须落在某个有效 slab 上
    struct slab *s = obj_to_slab(objs[i]);
    SLUBCHK_ASSERT(s != NULL && s->cache == c64 && s->magic == SLAB_MAGIC);
  }

  size_t free1a_after = buddy_system_pmm_manager.nr_free_pages();
  // 只应该新建了 1 个 slab（= SLAB_PAGES 页）
  SLUBCHK_ASSERT((free1a_before - free1a_after) == SLAB_PAGES);
  SLUBCHK_PRINTF("[SLUB-CHECK] alloc %u objs → new slab pages used = %u ✓\n",
                 cap, (unsigned)(free1a_before - free1a_after));

  // 再取 1 个对象：应触发第 2 个 slab 的创建
  objs[cap] = kmem_cache_alloc(c64);
  SLUBCHK_ASSERT(objs[cap] != NULL);

  size_t free1b_after = buddy_system_pmm_manager.nr_free_pages();
  SLUBCHK_ASSERT((free1a_after - free1b_after) == SLAB_PAGES);
  SLUBCHK_PRINTF("[SLUB-CHECK] alloc one more → 2nd slab created, extra pages = %u ✓\n",
                 (unsigned)(free1a_after - free1b_after));

  // ====== 3) 立即回收 objs[cap]，应从 full→partial（或保持在 partial） ======
  struct slab *s_cap = obj_to_slab(objs[cap]);
  SLUBCHK_ASSERT(s_cap != NULL);
  unsigned inuse_before = s_cap->inuse;
  kmem_cache_free(c64, objs[cap]);
  SLUBCHK_ASSERT(s_cap->inuse + 1 == inuse_before); // inuse 减 1
  objs[cap] = NULL;

  // ====== 4) 指针重用：free + 立即 alloc 应复用同一地址（LIFO） ======
  void *tmp = objs[cap ? (cap - 1) : 0];
  kmem_cache_free(c64, tmp);
  void *tmp2 = kmem_cache_alloc(c64);
  SLUBCHK_ASSERT(tmp == tmp2);
  SLUBCHK_PRINTF("[SLUB-CHECK] freelist LIFO reuse ✓\n");

  // ====== 5) 回收剩余所有对象：两个 slab 都应逐步被清空并释放回伙伴系统 ======
  // 先把我们刚复用的那个也回收
  kmem_cache_free(c64, tmp2);

  // 回收 cap 个（第一个 slab 的所有对象）
  for (unsigned i = 0; i < cap; i++)
  {
    if (objs[i])
      kmem_cache_free(c64, objs[i]);
    objs[i] = NULL;
  }

  // 释放临时数组（这块是 kmalloc 的内存）
  kfree(objs, sizeof(void *) * (cap + 2));

  // cache 仍然存在，slab 清空后应已释放回伙伴系统（本实现中空 slab 立刻释放）
  size_t free2 = buddy_system_pmm_manager.nr_free_pages();
  SLUBCHK_ASSERT(free2 == free0);
  SLUBCHK_PRINTF("[SLUB-CHECK] free all objs → free pages back to baseline (%u) ✓\n", (unsigned)free2);

  // ====== 6) 销毁 cache，不应发生泄漏 ======
  kmem_cache_destroy(c64);
  size_t free3 = buddy_system_pmm_manager.nr_free_pages();
  SLUBCHK_ASSERT(free3 == free0);
  SLUBCHK_PRINTF("[SLUB-CHECK] kmem_cache_destroy → free pages = baseline (%u) ✓\n", (unsigned)free3);

  // ====== 7) kmalloc/kfree 路径：命中 size-class 与走页分配 ======
  // 7.1 命中 size-class（例如 200B → 256B 级）
  size_t fA = buddy_system_pmm_manager.nr_free_pages();
  void *p200 = kmalloc(200);
  SLUBCHK_ASSERT(p200 != NULL);
  // kfree 需要传 hint（你的实现里无 slab 头无法识别就按页回收），
  // 这里 p200 应该来自 slab，所以不传 hint，让它走 obj 回收路径（obj_to_slab 能识别）
  kfree(p200, 0);
  size_t fB = buddy_system_pmm_manager.nr_free_pages();
  SLUBCHK_ASSERT(fB == fA);
  SLUBCHK_PRINTF("[SLUB-CHECK] kmalloc(200)/kfree → via size-class ✓\n");

  // 7.2 大块 > 2048：应直接走页分配
  size_t big = 5000;
  size_t need_pages = (big + PGSIZE - 1) / PGSIZE;
  size_t fC = buddy_system_pmm_manager.nr_free_pages();
  void *pbig = kmalloc(big);
  SLUBCHK_ASSERT(pbig != NULL);
  size_t fD = buddy_system_pmm_manager.nr_free_pages();
  SLUBCHK_ASSERT((fC - fD) == need_pages);
  kfree(pbig, big); // 大块必须带 hint，以免按 1 页错误归还
  size_t fE = buddy_system_pmm_manager.nr_free_pages();
  SLUBCHK_ASSERT(fE == fC);
  SLUBCHK_PRINTF("[SLUB-CHECK] kmalloc(%u)/kfree %u → via page allocator (%u pages) ✓\n",
                 (unsigned)big, (unsigned)big, (unsigned)need_pages);

  // ====== 8) 交错分配/回收：健壮性（再测一次 64B cache） ======
  struct kmem_cache *c64b = kmem_cache_create("kmalloc-64b", OBJ_SZ, sizeof(void *));
  SLUBCHK_ASSERT(c64b);

  // 交错：分配 cap/2 个，释放一半，再分配 cap/2+1，最终释放
  unsigned half = cap / 2;
  void **arr = (void **)kmalloc(sizeof(void *) * (cap + 4));
  SLUBCHK_ASSERT(arr);

  for (unsigned i = 0; i < half; i++)
  {
    arr[i] = kmem_cache_alloc(c64b);
    SLUBCHK_ASSERT(arr[i]);
  }
  // 释放前四分之一
  for (unsigned i = 0; i < half / 2; i++)
  {
    kmem_cache_free(c64b, arr[i]);
    arr[i] = NULL;
  }
  // 再分配 half/2 + 1（可能触发第二个 slab）
  for (unsigned i = 0; i < half / 2 + 1; i++)
  {
    arr[half + i] = kmem_cache_alloc(c64b);
    SLUBCHK_ASSERT(arr[half + i]);
  }
  // 全部释放
  for (unsigned i = 0; i < cap; i++)
  {
    if (arr[i])
      kmem_cache_free(c64b, arr[i]);
  }
  kfree(arr, sizeof(void *) * (cap + 4));

  kmem_cache_destroy(c64b);
  size_t fZ = buddy_system_pmm_manager.nr_free_pages();
  SLUBCHK_ASSERT(fZ == free0);
  SLUBCHK_PRINTF("[SLUB-CHECK] interleaved alloc/free → baseline pages (%u) ✓\n", (unsigned)fZ);

  SLUBCHK_PRINTF("[SLUB-CHECK] ALL TESTS PASSED ✓\n");
}

const struct pmm_manager slub_pmm_manager = {
    .name = "slub",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages,
    .free_pages = slub_free_pages,
    .nr_free_pages = slub_nr_free_pages,
    .check = slub_check,
};
