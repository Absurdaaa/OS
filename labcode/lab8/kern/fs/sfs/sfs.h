#ifndef __KERN_FS_SFS_SFS_H__
#define __KERN_FS_SFS_SFS_H__

#include <defs.h>
#include <mmu.h>
#include <list.h>
#include <sem.h>
#include <unistd.h>

/*
 * Simple FS (SFS) definitions visible to ucore. This covers the on-disk format
 * and is used by tools that work on SFS volumes, such as mksfs.
 */

#define SFS_MAGIC                                   0x2f8dbe2a              /* magic number for sfs */
#define SFS_BLKSIZE                                 PGSIZE                  /* size of block */
#define SFS_NDIRECT                                 12                      /* # of direct blocks in inode */
#define SFS_MAX_INFO_LEN                            31                      /* max length of infomation */
#define SFS_MAX_FNAME_LEN                           FS_MAX_FNAME_LEN        /* max length of filename */
#define SFS_MAX_FILE_SIZE                           (1024UL * 1024 * 128)   /* max file size (128M) */
#define SFS_BLKN_SUPER                              0                       /* block the superblock lives in */
#define SFS_BLKN_ROOT                               1                       /* location of the root dir inode */
#define SFS_BLKN_FREEMAP                            2                       /* 1st block of the freemap */

/* # of bits in a block */
#define SFS_BLKBITS                                 (SFS_BLKSIZE * CHAR_BIT)

/* # of entries in a block */
#define SFS_BLK_NENTRY                              (SFS_BLKSIZE / sizeof(uint32_t))

/* file types */
#define SFS_TYPE_INVAL                              0       /* Should not appear on disk */
#define SFS_TYPE_FILE                               1
#define SFS_TYPE_DIR                                2
#define SFS_TYPE_LINK                               3

/*
 * On-disk superblock
 */

// 包含了关于文件系统的所有关键参数，当计算机被启动或文件系统被首次接触时，超级块的内容就会被装入内存。
// 超级块
struct sfs_super {
    // 文件系统的魔数，用于验证文件系统的类型和完整性
    //其值为 0x2f8dbe2a，内核通过它来检查磁盘镜像是否是合法的 SFS 文件系统img
    uint32_t magic;                                 /* magic number, should be SFS_MAGIC */
    // 文件系统的总块数，，即 img 的大小
    uint32_t blocks;                                /* # of blocks in fs */
    // 没有被使用的块数
    uint32_t unused_blocks;                         /* # of unused blocks in fs */
    // 文件系统的信息描述
    // 包含了字符串simple file system
    char info[SFS_MAX_INFO_LEN + 1];                /* infomation for sfs  */
};

/* inode（磁盘上的） */
struct sfs_disk_inode {
    uint32_t size;                /* 文件大小（以字节为单位） */
    uint16_t type;                /* 文件类型（上面定义的 SYS_TYPE_* 之一） */
    uint16_t nlinks;              /* 指向该文件的硬链接数量 */
    uint32_t blocks;              /* 文件占用的磁盘块数量 */
    uint32_t direct[SFS_NDIRECT]; /* 直接块指针 */
    uint32_t indirect;            /* 间接块指针 */
    // uint32_t db_indirect;      /* 双重间接块指针 */
    // 未使用
};

/* file entry (on disk) */
struct sfs_disk_entry {
    uint32_t ino;                                   /* inode number */
    char name[SFS_MAX_FNAME_LEN + 1];               /* file name */
};

#define sfs_dentry_size                             \
    sizeof(((struct sfs_disk_entry *)0)->name)

/* sfs 的 inode 结构 */
struct sfs_inode {
    struct sfs_disk_inode *din;     /* 磁盘上的 inode（on-disk inode） */
    uint32_t ino;                   /* inode 编号 */
    bool dirty;                     /* inode 是否被修改过（脏标志） */
    int reclaim_count;              /* 回收计数，降到 0 时销毁该 inode */
    semaphore_t sem;                /* 保护 din 的信号量 */
    list_entry_t inode_link;        /* 用于挂入 sfs_fs 中 inode 链表的链表节点 */
    list_entry_t hash_link;         /* 用于挂入 sfs_fs 中 inode 哈希链表的链表节点 */
};

#define le2sin(le, member)                          \
    to_struct((le), struct sfs_inode, member)

/**
 * struct sfs_fs - SFS文件系统的核心控制结构体（内存中）
 *                用于管理SFS文件系统的整体状态、设备关联、资源锁及索引节点等核心资源
 */
struct sfs_fs
{
  struct sfs_super super;  /* 磁盘上的超级块（存储文件系统的全局元数据） */
  struct device *dev;      /* 该文件系统挂载的目标存储设备 */
  struct bitmap *freemap;  /* 块空闲位图（已被使用的块标记为0，未使用的块标记为1） */
  bool super_dirty;        /* 超级块/空闲位图是否被修改（脏标记：为true时需刷写到磁盘） */
  void *sfs_buffer;        /* 用于非块对齐I/O操作的缓冲区（解决数据读写与设备块大小不匹配的问题） */
  semaphore_t fs_sem;      /* 保护整个文件系统的信号量（全局文件系统操作互斥/同步） */
  semaphore_t io_sem;      /* 保护I/O操作的信号量（用于控制磁盘读写操作的并发访问） */
  semaphore_t mutex_sem;   /* 保护链接/解除链接及重命名操作的信号量（保证文件目录操作的原子性） */
  list_entry_t inode_list; /* 索引节点（inode）链表（管理内存中所有活跃的索引节点） */
  list_entry_t *hash_list; /* 索引节点（inode）哈希链表（用于快速查找索引节点，提高查询效率） */
};

/* hash for sfs */
#define SFS_HLIST_SHIFT                             10
#define SFS_HLIST_SIZE                              (1 << SFS_HLIST_SHIFT)
#define sin_hashfn(x)                               (hash32(x, SFS_HLIST_SHIFT))

/* size of freemap (in bits) */
#define sfs_freemap_bits(super)                     ROUNDUP((super)->blocks, SFS_BLKBITS)

/* size of freemap (in blocks) */
#define sfs_freemap_blocks(super)                   ROUNDUP_DIV((super)->blocks, SFS_BLKBITS)

struct fs;
struct inode;

void sfs_init(void);
int sfs_mount(const char *devname);

void lock_sfs_fs(struct sfs_fs *sfs);
void lock_sfs_io(struct sfs_fs *sfs);
void unlock_sfs_fs(struct sfs_fs *sfs);
void unlock_sfs_io(struct sfs_fs *sfs);

int sfs_rblock(struct sfs_fs *sfs, void *buf, uint32_t blkno, uint32_t nblks);
int sfs_wblock(struct sfs_fs *sfs, void *buf, uint32_t blkno, uint32_t nblks);
int sfs_rbuf(struct sfs_fs *sfs, void *buf, size_t len, uint32_t blkno, off_t offset);
int sfs_wbuf(struct sfs_fs *sfs, void *buf, size_t len, uint32_t blkno, off_t offset);
int sfs_sync_super(struct sfs_fs *sfs);
int sfs_sync_freemap(struct sfs_fs *sfs);
int sfs_clear_block(struct sfs_fs *sfs, uint32_t blkno, uint32_t nblks);

int sfs_load_inode(struct sfs_fs *sfs, struct inode **node_store, uint32_t ino);

#endif /* !__KERN_FS_SFS_SFS_H__ */

