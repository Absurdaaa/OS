#ifndef __KERN_FS_VFS_INODE_H__
#define __KERN_FS_VFS_INODE_H__

#include <defs.h>
#include <dev.h>
#include <sfs.h>
#include <atomic.h>
#include <assert.h>

struct stat;
struct iobuf;

/*
 * A struct inode is an abstract representation of a file.
 *
 * It is an interface that allows the kernel's filesystem-independent 
 * code to interact usefully with multiple sets of filesystem code.
 */

/*
 * Abstract low-level file.
 *
 * Note: in_info is Filesystem-specific data, in_type is the inode type
 *
 * open_count is managed using VOP_INCOPEN and VOP_DECOPEN by
 * vfs_open() and vfs_close(). Code above the VFS layer should not
 * need to worry about it.
 */
struct inode {
    //包含不同文件系统特定inode信息的union成员变量
    union {
      struct device __device_info;       // 设备文件系统内存inode信息
      struct sfs_inode __sfs_inode_info; // SFS文件系统内存inode信息
    } in_info;
    // 此inode所属文件系统类型
    enum {
        inode_type_device_info = 0x1234,
        inode_type_sfs_inode_info,
    } in_type;

    int ref_count;  // 此inode的引用计数
    int open_count; //打开此inode对应文件的个数
    struct fs *in_fs; // 抽象的文件系统，包含访问文件系统的函数指针
    const struct inode_ops *in_ops; // 抽象的inode操作，包含访问inode的函数指针
};

#define __in_type(type)                                             inode_type_##type##_info

#define check_inode_type(node, type)                                ((node)->in_type == __in_type(type))

#define __vop_info(node, type)                                      \
    ({                                                              \
        struct inode *__node = (node);                              \
        assert(__node != NULL && check_inode_type(__node, type));   \
        &(__node->in_info.__##type##_info);                         \
     })

#define vop_info(node, type)                                        __vop_info(node, type)

#define info2node(info, type)                                       \
    to_struct((info), struct inode, in_info.__##type##_info)

struct inode *__alloc_inode(int type);

#define alloc_inode(type)                                           __alloc_inode(__in_type(type))

#define MAX_INODE_COUNT                     0x10000

int inode_ref_inc(struct inode *node);
int inode_ref_dec(struct inode *node);
int inode_open_inc(struct inode *node);
int inode_open_dec(struct inode *node);

void inode_init(struct inode *node, const struct inode_ops *ops, struct fs *fs);
void inode_kill(struct inode *node);

#define VOP_MAGIC                           0x8c4ba476

/*
 * Abstract operations on a inode.
 *
 * These are used in the form VOP_FOO(inode, args), which are macros
 * that expands to inode->inode_ops->vop_foo(inode, args). The operations
 * "foo" are:
 *
 *    vop_open        - Called on open() of a file. Can be used to
 *                      reject illegal or undesired open modes. Note that
 *                      various operations can be performed without the
 *                      file actually being opened.
 *                      The inode need not look at O_CREAT, O_EXCL, or 
 *                      O_TRUNC, as these are handled in the VFS layer.
 *
 *                      VOP_EACHOPEN should not be called directly from
 *                      above the VFS layer - use vfs_open() to open inodes.
 *                      This maintains the open count so VOP_LASTCLOSE can
 *                      be called at the right time.
 *
 *    vop_close       - To be called on *last* close() of a file.
 *
 *                      VOP_LASTCLOSE should not be called directly from
 *                      above the VFS layer - use vfs_close() to close
 *                      inodes opened with vfs_open().
 *
 *    vop_reclaim     - Called when inode is no longer in use. Note that
 *                      this may be substantially after vop_lastclose is
 *                      called.
 *
 *****************************************
 *
 *    vop_read        - Read data from file to uio, at offset specified
 *                      in the uio, updating uio_resid to reflect the
 *                      amount read, and updating uio_offset to match.
 *                      Not allowed on directories or symlinks.
 *
 *    vop_getdirentry - Read a single filename from a directory into a
 *                      uio, choosing what name based on the offset
 *                      field in the uio, and updating that field.
 *                      Unlike with I/O on regular files, the value of
 *                      the offset field is not interpreted outside
 *                      the filesystem and thus need not be a byte
 *                      count. However, the uio_resid field should be
 *                      handled in the normal fashion.
 *                      On non-directory objects, return ENOTDIR.
 *
 *    vop_write       - Write data from uio to file at offset specified
 *                      in the uio, updating uio_resid to reflect the
 *                      amount written, and updating uio_offset to match.
 *                      Not allowed on directories or symlinks.
 *
 *    vop_ioctl       - Perform ioctl operation OP on file using data
 *                      DATA. The interpretation of the data is specific
 *                      to each ioctl.
 *
 *    vop_fstat        -Return info about a file. The pointer is a 
 *                      pointer to struct stat; see stat.h.
 *
 *    vop_gettype     - Return type of file. The values for file types
 *                      are in sfs.h.
 *
 *    vop_tryseek     - Check if seeking to the specified position within
 *                      the file is legal. (For instance, all seeks
 *                      are illegal on serial port devices, and seeks
 *                      past EOF on files whose sizes are fixed may be
 *                      as well.)
 *
 *    vop_fsync       - Force any dirty buffers associated with this file
 *                      to stable storage.
 *
 *    vop_truncate    - Forcibly set size of file to the length passed
 *                      in, discarding any excess blocks.
 *
 *    vop_namefile    - Compute pathname relative to filesystem root
 *                      of the file and copy to the specified io buffer. 
 *                      Need not work on objects that are not
 *                      directories.
 *
 *****************************************
 *
 *    vop_creat       - Create a regular file named NAME in the passed
 *                      directory DIR. If boolean EXCL is true, fail if
 *                      the file already exists; otherwise, use the
 *                      existing file if there is one. Hand back the
 *                      inode for the file as per vop_lookup.
 *
 *****************************************
 *
 *    vop_lookup      - Parse PATHNAME relative to the passed directory
 *                      DIR, and hand back the inode for the file it
 *                      refers to. May destroy PATHNAME. Should increment
 *                      refcount on inode handed back.
 */
/*
 * 索引节点（inode）的抽象操作集合。
 *
 * 这些操作以 VOP_FOO(inode, args) 的形式调用，该宏会展开为
 * inode->inode_ops->vop_foo(inode, args)。其中各类操作 "foo" 的含义如下：
 *
 *    vop_open        - 在文件执行 open() 操作时被调用。可用于拒绝非法或不期望的打开模式。
 *                      注意：即使文件未被实际打开，也可以执行多种操作。
 *                      索引节点（inode）无需处理 O_CREAT、O_EXCL 或 O_TRUNC 标志，
 *                      这些标志由虚拟文件系统（VFS）层统一处理。
 *
 *                      注意：不应在 VFS 层之上直接调用 VOP_EACHOPEN —— 应使用 vfs_open()
 *                      来打开索引节点。该函数会维护文件打开计数，确保 VOP_LASTCLOSE
 *                      在正确的时机被调用。
 *
 *    vop_close       - 在文件执行 *最后一次* close() 操作时被调用。
 *
 *                      注意：不应在 VFS 层之上直接调用 VOP_LASTCLOSE —— 应使用 vfs_close()
 *                      来关闭通过 vfs_open() 打开的索引节点。
 *
 *    vop_reclaim     - 当索引节点不再被使用时被调用。注意：该操作的调用时机
 *                      可能远晚于 vop_lastclose 的调用时机。
 *
 *****************************************
 *
 *    vop_read        - 从文件中读取数据到 uio 结构体中，读取的偏移量由 uio 结构体指定，
 *                      同时更新 uio_resid 字段以反映剩余未读取的字节数，并同步更新 uio_offset
 *                      字段（记录当前读取偏移）。
 *                      该操作不允许对目录或符号链接执行。
 *
 *    vop_getdirentry - 从目录中读取单个文件名到 uio 结构体中，根据 uio 结构体的 offset
 *                      字段决定读取哪个文件名，并更新该 offset 字段。
 *                      与普通文件 I/O 不同，offset 字段的值不会在文件系统外部被解析，
 *                      因此它不一定是字节计数。但 uio_resid 字段仍需按照常规方式处理。
 *                      若对非目录对象执行该操作，应返回 ENOTDIR 错误（非目录错误）。
 *
 *    vop_write       - 从 uio 结构体中将数据写入文件，写入的偏移量由 uio 结构体指定，
 *                      同时更新 uio_resid 字段以反映剩余未写入的字节数，并同步更新 uio_offset
 *                      字段（记录当前写入偏移）。
 *                      该操作不允许对目录或符号链接执行。
 *
 *    vop_ioctl       - 对文件执行编号为 OP 的 ioctl 控制操作，操作数据为 DATA。
 *                      数据的具体含义与每个 ioctl 操作自身相关（不同操作对应不同数据格式）。
 *
 *    vop_fstat       - 返回文件的相关信息。传入的指针指向 stat 结构体（详见 stat.h 头文件）。
 *
 *    vop_gettype     - 返回文件的类型。文件类型的取值定义在 sfs.h 头文件中。
 *
 *    vop_tryseek     - 检查将文件偏移量定位到指定位置是否合法。
 *                      （例如：对串口设备执行任何定位操作都是非法的；
 *                        对于固定大小的文件，将偏移量定位到文件末尾（EOF）之后也可能是非法的。）
 *
 *    vop_fsync       - 将与该文件关联的所有脏缓冲区（未写入持久存储的缓存数据）强制刷新到
 *                      持久化存储设备中。
 *
 *    vop_truncate    - 将文件大小强制设置为传入的长度值，丢弃超出该长度的所有数据块。
 *
 *    vop_namefile    - 计算该文件相对于文件系统根目录的路径名，并将其复制到指定的 io 缓冲区中。
 *                      该操作无需支持非目录类型的对象。
 *
 *****************************************
 *
 *    vop_creat       - 在传入的目录 DIR 中创建一个名为 NAME 的普通文件。
 *                      若布尔值 EXCL 为真（true），则当文件已存在时创建失败；
 *                      若为假（false），则当文件已存在时直接使用该现有文件。
 *                      与 vop_lookup 操作类似，返回该文件对应的索引节点。
 *
 *****************************************
 *
 *    vop_lookup      - 相对于传入的目录 DIR 解析路径名 PATHNAME，并返回该路径名指向的
 *                      文件对应的索引节点。该操作可能会销毁 PATHNAME（占用的内存）。
 *                      对于返回的索引节点，应将其引用计数递增。
 */
/**
 * inode_ops 是对常规文件、目录、设备文件所有操作的一个抽象函数表示。对于某一具体的文件系统中的文件或目录，只需实现相关的函数，就可以被用户进程访问具体的文件了，且用户进程无需了解具体文件系统的实现细节。
 */
struct inode_ops {
    unsigned long vop_magic;
    int (*vop_open)(struct inode *node, uint32_t open_flags);
    int (*vop_close)(struct inode *node);
    int (*vop_read)(struct inode *node, struct iobuf *iob);
    int (*vop_write)(struct inode *node, struct iobuf *iob);
    int (*vop_fstat)(struct inode *node, struct stat *stat);
    int (*vop_fsync)(struct inode *node);
    int (*vop_namefile)(struct inode *node, struct iobuf *iob);
    int (*vop_getdirentry)(struct inode *node, struct iobuf *iob);
    int (*vop_reclaim)(struct inode *node);
    int (*vop_gettype)(struct inode *node, uint32_t *type_store);
    int (*vop_tryseek)(struct inode *node, off_t pos);
    int (*vop_truncate)(struct inode *node, off_t len);
    int (*vop_create)(struct inode *node, const char *name, bool excl, struct inode **node_store);
    int (*vop_lookup)(struct inode *node, char *path, struct inode **node_store);
    int (*vop_ioctl)(struct inode *node, int op, void *data);
};

/*
 * Consistency check
 */
void inode_check(struct inode *node, const char *opstr);

#define __vop_op(node, sym)                                                                         \
    ({                                                                                              \
        struct inode *__node = (node);                                                              \
        assert(__node != NULL && __node->in_ops != NULL && __node->in_ops->vop_##sym != NULL);      \
        inode_check(__node, #sym);                                                                  \
        __node->in_ops->vop_##sym;                                                                  \
     })

#define vop_open(node, open_flags)                                  (__vop_op(node, open)(node, open_flags))
#define vop_close(node)                                             (__vop_op(node, close)(node))
#define vop_read(node, iob)                                         (__vop_op(node, read)(node, iob))
#define vop_write(node, iob)                                        (__vop_op(node, write)(node, iob))
#define vop_fstat(node, stat)                                       (__vop_op(node, fstat)(node, stat))
#define vop_fsync(node)                                             (__vop_op(node, fsync)(node))
#define vop_namefile(node, iob)                                     (__vop_op(node, namefile)(node, iob))
#define vop_getdirentry(node, iob)                                  (__vop_op(node, getdirentry)(node, iob))
#define vop_reclaim(node)                                           (__vop_op(node, reclaim)(node))
#define vop_ioctl(node, op, data)                                   (__vop_op(node, ioctl)(node, op, data))
#define vop_gettype(node, type_store)                               (__vop_op(node, gettype)(node, type_store))
#define vop_tryseek(node, pos)                                      (__vop_op(node, tryseek)(node, pos))
#define vop_truncate(node, len)                                     (__vop_op(node, truncate)(node, len))
#define vop_create(node, name, excl, node_store)                    (__vop_op(node, create)(node, name, excl, node_store))
#define vop_lookup(node, path, node_store)                          (__vop_op(node, lookup)(node, path, node_store))


#define vop_fs(node)                                                ((node)->in_fs)
#define vop_init(node, ops, fs)                                     inode_init(node, ops, fs)
#define vop_kill(node)                                              inode_kill(node)

/*
 * Reference count manipulation (handled above filesystem level)
 */
#define vop_ref_inc(node)                                           inode_ref_inc(node)
#define vop_ref_dec(node)                                           inode_ref_dec(node)
/*
 * Open count manipulation (handled above filesystem level)
 *
 * VOP_INCOPEN is called by vfs_open. VOP_DECOPEN is called by vfs_close.
 * Neither of these should need to be called from above the vfs layer.
 */
#define vop_open_inc(node)                                          inode_open_inc(node)
#define vop_open_dec(node)                                          inode_open_dec(node)


static inline int
inode_ref_count(struct inode *node) {
    return node->ref_count;
}

static inline int
inode_open_count(struct inode *node) {
    return node->open_count;
}

#endif /* !__KERN_FS_VFS_INODE_H__ */

