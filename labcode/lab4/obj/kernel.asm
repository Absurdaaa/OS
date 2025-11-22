
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49a60613          	addi	a2,a2,1178 # ffffffffc020d4ec <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	64b030ef          	jal	ra,ffffffffc0203eac <memset>
    dtb_init();
ffffffffc0200066:	514000ef          	jal	ra,ffffffffc020057a <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	49e000ef          	jal	ra,ffffffffc0200508 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	e9258593          	addi	a1,a1,-366 # ffffffffc0203f00 <etext+0x6>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	eaa50513          	addi	a0,a0,-342 # ffffffffc0203f20 <etext+0x26>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	15a000ef          	jal	ra,ffffffffc02001dc <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	0e0020ef          	jal	ra,ffffffffc0202166 <pmm_init>

    pic_init(); // init interrupt controller，初始化中断控制器
ffffffffc020008a:	0ad000ef          	jal	ra,ffffffffc0200936 <pic_init>
    idt_init(); // init interrupt descriptor table，初始化中断描述符表
ffffffffc020008e:	0ab000ef          	jal	ra,ffffffffc0200938 <idt_init>

    vmm_init();  // init virtual memory management，初始化虚拟内存管理
ffffffffc0200092:	649020ef          	jal	ra,ffffffffc0202eda <vmm_init>
    proc_init(); // init process table，初始化进程表
ffffffffc0200096:	608030ef          	jal	ra,ffffffffc020369e <proc_init>

    // 打印调试
    // const char *message2 = "proc_init done.";
    // cprintf("%s\n\n", message2);

    clock_init();  // init clock interrupt，初始化时钟中断
ffffffffc020009a:	41c000ef          	jal	ra,ffffffffc02004b6 <clock_init>
    intr_enable(); // enable irq interrupt，使能 IRQ 中断
ffffffffc020009e:	08d000ef          	jal	ra,ffffffffc020092a <intr_enable>

    cpu_idle(); // run idle process，运行空闲进程
ffffffffc02000a2:	04b030ef          	jal	ra,ffffffffc02038ec <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00004517          	auipc	a0,0x4
ffffffffc02000c0:	e6c50513          	addi	a0,a0,-404 # ffffffffc0203f28 <etext+0x2e>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	00009b97          	auipc	s7,0x9
ffffffffc02000d6:	f5eb8b93          	addi	s7,s7,-162 # ffffffffc0209030 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	0ee000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	0de000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	0cc000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	00009517          	auipc	a0,0x9
ffffffffc0200132:	f0250513          	addi	a0,a0,-254 # ffffffffc0209030 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	3a8000ef          	jal	ra,ffffffffc020050a <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	101030ef          	jal	ra,ffffffffc0203a88 <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc0208028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	0cb030ef          	jal	ra,ffffffffc0203a88 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a681                	j	ffffffffc020050a <cons_putc>

ffffffffc02001cc <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc02001cc:	1141                	addi	sp,sp,-16
ffffffffc02001ce:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001d0:	36e000ef          	jal	ra,ffffffffc020053e <cons_getc>
ffffffffc02001d4:	dd75                	beqz	a0,ffffffffc02001d0 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d6:	60a2                	ld	ra,8(sp)
ffffffffc02001d8:	0141                	addi	sp,sp,16
ffffffffc02001da:	8082                	ret

ffffffffc02001dc <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02001dc:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001de:	00004517          	auipc	a0,0x4
ffffffffc02001e2:	d5250513          	addi	a0,a0,-686 # ffffffffc0203f30 <etext+0x36>
{
ffffffffc02001e6:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e8:	fadff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001ec:	00000597          	auipc	a1,0x0
ffffffffc02001f0:	e5e58593          	addi	a1,a1,-418 # ffffffffc020004a <kern_init>
ffffffffc02001f4:	00004517          	auipc	a0,0x4
ffffffffc02001f8:	d5c50513          	addi	a0,a0,-676 # ffffffffc0203f50 <etext+0x56>
ffffffffc02001fc:	f99ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200200:	00004597          	auipc	a1,0x4
ffffffffc0200204:	cfa58593          	addi	a1,a1,-774 # ffffffffc0203efa <etext>
ffffffffc0200208:	00004517          	auipc	a0,0x4
ffffffffc020020c:	d6850513          	addi	a0,a0,-664 # ffffffffc0203f70 <etext+0x76>
ffffffffc0200210:	f85ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200214:	00009597          	auipc	a1,0x9
ffffffffc0200218:	e1c58593          	addi	a1,a1,-484 # ffffffffc0209030 <buf>
ffffffffc020021c:	00004517          	auipc	a0,0x4
ffffffffc0200220:	d7450513          	addi	a0,a0,-652 # ffffffffc0203f90 <etext+0x96>
ffffffffc0200224:	f71ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200228:	0000d597          	auipc	a1,0xd
ffffffffc020022c:	2c458593          	addi	a1,a1,708 # ffffffffc020d4ec <end>
ffffffffc0200230:	00004517          	auipc	a0,0x4
ffffffffc0200234:	d8050513          	addi	a0,a0,-640 # ffffffffc0203fb0 <etext+0xb6>
ffffffffc0200238:	f5dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023c:	0000d597          	auipc	a1,0xd
ffffffffc0200240:	6af58593          	addi	a1,a1,1711 # ffffffffc020d8eb <end+0x3ff>
ffffffffc0200244:	00000797          	auipc	a5,0x0
ffffffffc0200248:	e0678793          	addi	a5,a5,-506 # ffffffffc020004a <kern_init>
ffffffffc020024c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200250:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200254:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200256:	3ff5f593          	andi	a1,a1,1023
ffffffffc020025a:	95be                	add	a1,a1,a5
ffffffffc020025c:	85a9                	srai	a1,a1,0xa
ffffffffc020025e:	00004517          	auipc	a0,0x4
ffffffffc0200262:	d7250513          	addi	a0,a0,-654 # ffffffffc0203fd0 <etext+0xd6>
}
ffffffffc0200266:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200268:	b735                	j	ffffffffc0200194 <cprintf>

ffffffffc020026a <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc020026a:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020026c:	00004617          	auipc	a2,0x4
ffffffffc0200270:	d9460613          	addi	a2,a2,-620 # ffffffffc0204000 <etext+0x106>
ffffffffc0200274:	04900593          	li	a1,73
ffffffffc0200278:	00004517          	auipc	a0,0x4
ffffffffc020027c:	da050513          	addi	a0,a0,-608 # ffffffffc0204018 <etext+0x11e>
{
ffffffffc0200280:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200282:	1d8000ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0200286 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200286:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200288:	00004617          	auipc	a2,0x4
ffffffffc020028c:	da860613          	addi	a2,a2,-600 # ffffffffc0204030 <etext+0x136>
ffffffffc0200290:	00004597          	auipc	a1,0x4
ffffffffc0200294:	dc058593          	addi	a1,a1,-576 # ffffffffc0204050 <etext+0x156>
ffffffffc0200298:	00004517          	auipc	a0,0x4
ffffffffc020029c:	dc050513          	addi	a0,a0,-576 # ffffffffc0204058 <etext+0x15e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002a0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a2:	ef3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002a6:	00004617          	auipc	a2,0x4
ffffffffc02002aa:	dc260613          	addi	a2,a2,-574 # ffffffffc0204068 <etext+0x16e>
ffffffffc02002ae:	00004597          	auipc	a1,0x4
ffffffffc02002b2:	de258593          	addi	a1,a1,-542 # ffffffffc0204090 <etext+0x196>
ffffffffc02002b6:	00004517          	auipc	a0,0x4
ffffffffc02002ba:	da250513          	addi	a0,a0,-606 # ffffffffc0204058 <etext+0x15e>
ffffffffc02002be:	ed7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002c2:	00004617          	auipc	a2,0x4
ffffffffc02002c6:	dde60613          	addi	a2,a2,-546 # ffffffffc02040a0 <etext+0x1a6>
ffffffffc02002ca:	00004597          	auipc	a1,0x4
ffffffffc02002ce:	df658593          	addi	a1,a1,-522 # ffffffffc02040c0 <etext+0x1c6>
ffffffffc02002d2:	00004517          	auipc	a0,0x4
ffffffffc02002d6:	d8650513          	addi	a0,a0,-634 # ffffffffc0204058 <etext+0x15e>
ffffffffc02002da:	ebbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc02002de:	60a2                	ld	ra,8(sp)
ffffffffc02002e0:	4501                	li	a0,0
ffffffffc02002e2:	0141                	addi	sp,sp,16
ffffffffc02002e4:	8082                	ret

ffffffffc02002e6 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e6:	1141                	addi	sp,sp,-16
ffffffffc02002e8:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002ea:	ef3ff0ef          	jal	ra,ffffffffc02001dc <print_kerninfo>
    return 0;
}
ffffffffc02002ee:	60a2                	ld	ra,8(sp)
ffffffffc02002f0:	4501                	li	a0,0
ffffffffc02002f2:	0141                	addi	sp,sp,16
ffffffffc02002f4:	8082                	ret

ffffffffc02002f6 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002f6:	1141                	addi	sp,sp,-16
ffffffffc02002f8:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002fa:	f71ff0ef          	jal	ra,ffffffffc020026a <print_stackframe>
    return 0;
}
ffffffffc02002fe:	60a2                	ld	ra,8(sp)
ffffffffc0200300:	4501                	li	a0,0
ffffffffc0200302:	0141                	addi	sp,sp,16
ffffffffc0200304:	8082                	ret

ffffffffc0200306 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200306:	7115                	addi	sp,sp,-224
ffffffffc0200308:	ed5e                	sd	s7,152(sp)
ffffffffc020030a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020030c:	00004517          	auipc	a0,0x4
ffffffffc0200310:	dc450513          	addi	a0,a0,-572 # ffffffffc02040d0 <etext+0x1d6>
kmonitor(struct trapframe *tf) {
ffffffffc0200314:	ed86                	sd	ra,216(sp)
ffffffffc0200316:	e9a2                	sd	s0,208(sp)
ffffffffc0200318:	e5a6                	sd	s1,200(sp)
ffffffffc020031a:	e1ca                	sd	s2,192(sp)
ffffffffc020031c:	fd4e                	sd	s3,184(sp)
ffffffffc020031e:	f952                	sd	s4,176(sp)
ffffffffc0200320:	f556                	sd	s5,168(sp)
ffffffffc0200322:	f15a                	sd	s6,160(sp)
ffffffffc0200324:	e962                	sd	s8,144(sp)
ffffffffc0200326:	e566                	sd	s9,136(sp)
ffffffffc0200328:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032a:	e6bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020032e:	00004517          	auipc	a0,0x4
ffffffffc0200332:	dca50513          	addi	a0,a0,-566 # ffffffffc02040f8 <etext+0x1fe>
ffffffffc0200336:	e5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL) {
ffffffffc020033a:	000b8563          	beqz	s7,ffffffffc0200344 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020033e:	855e                	mv	a0,s7
ffffffffc0200340:	7e0000ef          	jal	ra,ffffffffc0200b20 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200344:	4501                	li	a0,0
ffffffffc0200346:	4581                	li	a1,0
ffffffffc0200348:	4601                	li	a2,0
ffffffffc020034a:	48a1                	li	a7,8
ffffffffc020034c:	00000073          	ecall
ffffffffc0200350:	00004c17          	auipc	s8,0x4
ffffffffc0200354:	e18c0c13          	addi	s8,s8,-488 # ffffffffc0204168 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200358:	00004917          	auipc	s2,0x4
ffffffffc020035c:	dc890913          	addi	s2,s2,-568 # ffffffffc0204120 <etext+0x226>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200360:	00004497          	auipc	s1,0x4
ffffffffc0200364:	dc848493          	addi	s1,s1,-568 # ffffffffc0204128 <etext+0x22e>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020036a:	00004b17          	auipc	s6,0x4
ffffffffc020036e:	dc6b0b13          	addi	s6,s6,-570 # ffffffffc0204130 <etext+0x236>
        argv[argc ++] = buf;
ffffffffc0200372:	00004a17          	auipc	s4,0x4
ffffffffc0200376:	cdea0a13          	addi	s4,s4,-802 # ffffffffc0204050 <etext+0x156>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020037a:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020037c:	854a                	mv	a0,s2
ffffffffc020037e:	d29ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc0200382:	842a                	mv	s0,a0
ffffffffc0200384:	dd65                	beqz	a0,ffffffffc020037c <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200386:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020038a:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038c:	e1bd                	bnez	a1,ffffffffc02003f2 <kmonitor+0xec>
    if (argc == 0) {
ffffffffc020038e:	fe0c87e3          	beqz	s9,ffffffffc020037c <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200392:	6582                	ld	a1,0(sp)
ffffffffc0200394:	00004d17          	auipc	s10,0x4
ffffffffc0200398:	dd4d0d13          	addi	s10,s10,-556 # ffffffffc0204168 <commands>
        argv[argc ++] = buf;
ffffffffc020039c:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039e:	4401                	li	s0,0
ffffffffc02003a0:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003a2:	2b1030ef          	jal	ra,ffffffffc0203e52 <strcmp>
ffffffffc02003a6:	c919                	beqz	a0,ffffffffc02003bc <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003a8:	2405                	addiw	s0,s0,1
ffffffffc02003aa:	0b540063          	beq	s0,s5,ffffffffc020044a <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ae:	000d3503          	ld	a0,0(s10)
ffffffffc02003b2:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003b6:	29d030ef          	jal	ra,ffffffffc0203e52 <strcmp>
ffffffffc02003ba:	f57d                	bnez	a0,ffffffffc02003a8 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003bc:	00141793          	slli	a5,s0,0x1
ffffffffc02003c0:	97a2                	add	a5,a5,s0
ffffffffc02003c2:	078e                	slli	a5,a5,0x3
ffffffffc02003c4:	97e2                	add	a5,a5,s8
ffffffffc02003c6:	6b9c                	ld	a5,16(a5)
ffffffffc02003c8:	865e                	mv	a2,s7
ffffffffc02003ca:	002c                	addi	a1,sp,8
ffffffffc02003cc:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003d0:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003d2:	fa0555e3          	bgez	a0,ffffffffc020037c <kmonitor+0x76>
}
ffffffffc02003d6:	60ee                	ld	ra,216(sp)
ffffffffc02003d8:	644e                	ld	s0,208(sp)
ffffffffc02003da:	64ae                	ld	s1,200(sp)
ffffffffc02003dc:	690e                	ld	s2,192(sp)
ffffffffc02003de:	79ea                	ld	s3,184(sp)
ffffffffc02003e0:	7a4a                	ld	s4,176(sp)
ffffffffc02003e2:	7aaa                	ld	s5,168(sp)
ffffffffc02003e4:	7b0a                	ld	s6,160(sp)
ffffffffc02003e6:	6bea                	ld	s7,152(sp)
ffffffffc02003e8:	6c4a                	ld	s8,144(sp)
ffffffffc02003ea:	6caa                	ld	s9,136(sp)
ffffffffc02003ec:	6d0a                	ld	s10,128(sp)
ffffffffc02003ee:	612d                	addi	sp,sp,224
ffffffffc02003f0:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003f2:	8526                	mv	a0,s1
ffffffffc02003f4:	2a3030ef          	jal	ra,ffffffffc0203e96 <strchr>
ffffffffc02003f8:	c901                	beqz	a0,ffffffffc0200408 <kmonitor+0x102>
ffffffffc02003fa:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003fe:	00040023          	sb	zero,0(s0)
ffffffffc0200402:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200404:	d5c9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200406:	b7f5                	j	ffffffffc02003f2 <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200408:	00044783          	lbu	a5,0(s0)
ffffffffc020040c:	d3c9                	beqz	a5,ffffffffc020038e <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc020040e:	033c8963          	beq	s9,s3,ffffffffc0200440 <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc0200412:	003c9793          	slli	a5,s9,0x3
ffffffffc0200416:	0118                	addi	a4,sp,128
ffffffffc0200418:	97ba                	add	a5,a5,a4
ffffffffc020041a:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020041e:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200422:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200424:	e591                	bnez	a1,ffffffffc0200430 <kmonitor+0x12a>
ffffffffc0200426:	b7b5                	j	ffffffffc0200392 <kmonitor+0x8c>
ffffffffc0200428:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020042c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020042e:	d1a5                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200430:	8526                	mv	a0,s1
ffffffffc0200432:	265030ef          	jal	ra,ffffffffc0203e96 <strchr>
ffffffffc0200436:	d96d                	beqz	a0,ffffffffc0200428 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200438:	00044583          	lbu	a1,0(s0)
ffffffffc020043c:	d9a9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc020043e:	bf55                	j	ffffffffc02003f2 <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200440:	45c1                	li	a1,16
ffffffffc0200442:	855a                	mv	a0,s6
ffffffffc0200444:	d51ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200448:	b7e9                	j	ffffffffc0200412 <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020044a:	6582                	ld	a1,0(sp)
ffffffffc020044c:	00004517          	auipc	a0,0x4
ffffffffc0200450:	d0450513          	addi	a0,a0,-764 # ffffffffc0204150 <etext+0x256>
ffffffffc0200454:	d41ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc0200458:	b715                	j	ffffffffc020037c <kmonitor+0x76>

ffffffffc020045a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020045a:	0000d317          	auipc	t1,0xd
ffffffffc020045e:	00e30313          	addi	t1,t1,14 # ffffffffc020d468 <is_panic>
ffffffffc0200462:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200466:	715d                	addi	sp,sp,-80
ffffffffc0200468:	ec06                	sd	ra,24(sp)
ffffffffc020046a:	e822                	sd	s0,16(sp)
ffffffffc020046c:	f436                	sd	a3,40(sp)
ffffffffc020046e:	f83a                	sd	a4,48(sp)
ffffffffc0200470:	fc3e                	sd	a5,56(sp)
ffffffffc0200472:	e0c2                	sd	a6,64(sp)
ffffffffc0200474:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200476:	020e1a63          	bnez	t3,ffffffffc02004aa <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020047a:	4785                	li	a5,1
ffffffffc020047c:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200480:	8432                	mv	s0,a2
ffffffffc0200482:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200484:	862e                	mv	a2,a1
ffffffffc0200486:	85aa                	mv	a1,a0
ffffffffc0200488:	00004517          	auipc	a0,0x4
ffffffffc020048c:	d2850513          	addi	a0,a0,-728 # ffffffffc02041b0 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200490:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200492:	d03ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200496:	65a2                	ld	a1,8(sp)
ffffffffc0200498:	8522                	mv	a0,s0
ffffffffc020049a:	cdbff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020049e:	00005517          	auipc	a0,0x5
ffffffffc02004a2:	de250513          	addi	a0,a0,-542 # ffffffffc0205280 <default_pmm_manager+0x530>
ffffffffc02004a6:	cefff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02004aa:	486000ef          	jal	ra,ffffffffc0200930 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004ae:	4501                	li	a0,0
ffffffffc02004b0:	e57ff0ef          	jal	ra,ffffffffc0200306 <kmonitor>
    while (1) {
ffffffffc02004b4:	bfed                	j	ffffffffc02004ae <__panic+0x54>

ffffffffc02004b6 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004b6:	67e1                	lui	a5,0x18
ffffffffc02004b8:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004bc:	0000d717          	auipc	a4,0xd
ffffffffc02004c0:	faf73e23          	sd	a5,-68(a4) # ffffffffc020d478 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004c4:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02004c8:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004ca:	953e                	add	a0,a0,a5
ffffffffc02004cc:	4601                	li	a2,0
ffffffffc02004ce:	4881                	li	a7,0
ffffffffc02004d0:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02004d4:	02000793          	li	a5,32
ffffffffc02004d8:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02004dc:	00004517          	auipc	a0,0x4
ffffffffc02004e0:	cf450513          	addi	a0,a0,-780 # ffffffffc02041d0 <commands+0x68>
    ticks = 0;
ffffffffc02004e4:	0000d797          	auipc	a5,0xd
ffffffffc02004e8:	f807b623          	sd	zero,-116(a5) # ffffffffc020d470 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02004ec:	b165                	j	ffffffffc0200194 <cprintf>

ffffffffc02004ee <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004ee:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004f2:	0000d797          	auipc	a5,0xd
ffffffffc02004f6:	f867b783          	ld	a5,-122(a5) # ffffffffc020d478 <timebase>
ffffffffc02004fa:	953e                	add	a0,a0,a5
ffffffffc02004fc:	4581                	li	a1,0
ffffffffc02004fe:	4601                	li	a2,0
ffffffffc0200500:	4881                	li	a7,0
ffffffffc0200502:	00000073          	ecall
ffffffffc0200506:	8082                	ret

ffffffffc0200508 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200508:	8082                	ret

ffffffffc020050a <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020050a:	100027f3          	csrr	a5,sstatus
ffffffffc020050e:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200510:	0ff57513          	zext.b	a0,a0
ffffffffc0200514:	e799                	bnez	a5,ffffffffc0200522 <cons_putc+0x18>
ffffffffc0200516:	4581                	li	a1,0
ffffffffc0200518:	4601                	li	a2,0
ffffffffc020051a:	4885                	li	a7,1
ffffffffc020051c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200520:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200522:	1101                	addi	sp,sp,-32
ffffffffc0200524:	ec06                	sd	ra,24(sp)
ffffffffc0200526:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200528:	408000ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020052c:	6522                	ld	a0,8(sp)
ffffffffc020052e:	4581                	li	a1,0
ffffffffc0200530:	4601                	li	a2,0
ffffffffc0200532:	4885                	li	a7,1
ffffffffc0200534:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200538:	60e2                	ld	ra,24(sp)
ffffffffc020053a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020053c:	a6fd                	j	ffffffffc020092a <intr_enable>

ffffffffc020053e <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020053e:	100027f3          	csrr	a5,sstatus
ffffffffc0200542:	8b89                	andi	a5,a5,2
ffffffffc0200544:	eb89                	bnez	a5,ffffffffc0200556 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200546:	4501                	li	a0,0
ffffffffc0200548:	4581                	li	a1,0
ffffffffc020054a:	4601                	li	a2,0
ffffffffc020054c:	4889                	li	a7,2
ffffffffc020054e:	00000073          	ecall
ffffffffc0200552:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200554:	8082                	ret
int cons_getc(void) {
ffffffffc0200556:	1101                	addi	sp,sp,-32
ffffffffc0200558:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020055a:	3d6000ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020055e:	4501                	li	a0,0
ffffffffc0200560:	4581                	li	a1,0
ffffffffc0200562:	4601                	li	a2,0
ffffffffc0200564:	4889                	li	a7,2
ffffffffc0200566:	00000073          	ecall
ffffffffc020056a:	2501                	sext.w	a0,a0
ffffffffc020056c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020056e:	3bc000ef          	jal	ra,ffffffffc020092a <intr_enable>
}
ffffffffc0200572:	60e2                	ld	ra,24(sp)
ffffffffc0200574:	6522                	ld	a0,8(sp)
ffffffffc0200576:	6105                	addi	sp,sp,32
ffffffffc0200578:	8082                	ret

ffffffffc020057a <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020057a:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020057c:	00004517          	auipc	a0,0x4
ffffffffc0200580:	c7450513          	addi	a0,a0,-908 # ffffffffc02041f0 <commands+0x88>
void dtb_init(void) {
ffffffffc0200584:	fc86                	sd	ra,120(sp)
ffffffffc0200586:	f8a2                	sd	s0,112(sp)
ffffffffc0200588:	e8d2                	sd	s4,80(sp)
ffffffffc020058a:	f4a6                	sd	s1,104(sp)
ffffffffc020058c:	f0ca                	sd	s2,96(sp)
ffffffffc020058e:	ecce                	sd	s3,88(sp)
ffffffffc0200590:	e4d6                	sd	s5,72(sp)
ffffffffc0200592:	e0da                	sd	s6,64(sp)
ffffffffc0200594:	fc5e                	sd	s7,56(sp)
ffffffffc0200596:	f862                	sd	s8,48(sp)
ffffffffc0200598:	f466                	sd	s9,40(sp)
ffffffffc020059a:	f06a                	sd	s10,32(sp)
ffffffffc020059c:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020059e:	bf7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005a2:	00009597          	auipc	a1,0x9
ffffffffc02005a6:	a5e5b583          	ld	a1,-1442(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc02005aa:	00004517          	auipc	a0,0x4
ffffffffc02005ae:	c5650513          	addi	a0,a0,-938 # ffffffffc0204200 <commands+0x98>
ffffffffc02005b2:	be3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005b6:	00009417          	auipc	s0,0x9
ffffffffc02005ba:	a5240413          	addi	s0,s0,-1454 # ffffffffc0209008 <boot_dtb>
ffffffffc02005be:	600c                	ld	a1,0(s0)
ffffffffc02005c0:	00004517          	auipc	a0,0x4
ffffffffc02005c4:	c5050513          	addi	a0,a0,-944 # ffffffffc0204210 <commands+0xa8>
ffffffffc02005c8:	bcdff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005cc:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005d0:	00004517          	auipc	a0,0x4
ffffffffc02005d4:	c5850513          	addi	a0,a0,-936 # ffffffffc0204228 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02005d8:	120a0463          	beqz	s4,ffffffffc0200700 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02005dc:	57f5                	li	a5,-3
ffffffffc02005de:	07fa                	slli	a5,a5,0x1e
ffffffffc02005e0:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02005e4:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e6:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ea:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ec:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02005f0:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f4:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f8:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005fc:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200600:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200602:	8ec9                	or	a3,a3,a0
ffffffffc0200604:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200608:	1b7d                	addi	s6,s6,-1
ffffffffc020060a:	0167f7b3          	and	a5,a5,s6
ffffffffc020060e:	8dd5                	or	a1,a1,a3
ffffffffc0200610:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200612:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200616:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200618:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed2a01>
ffffffffc020061c:	10f59163          	bne	a1,a5,ffffffffc020071e <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200620:	471c                	lw	a5,8(a4)
ffffffffc0200622:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200624:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200626:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020062a:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020062e:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200632:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200636:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020063a:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020063e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200642:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200646:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020064a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020064e:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200650:	01146433          	or	s0,s0,a7
ffffffffc0200654:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200658:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020065c:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200662:	8c49                	or	s0,s0,a0
ffffffffc0200664:	0166f6b3          	and	a3,a3,s6
ffffffffc0200668:	00ca6a33          	or	s4,s4,a2
ffffffffc020066c:	0167f7b3          	and	a5,a5,s6
ffffffffc0200670:	8c55                	or	s0,s0,a3
ffffffffc0200672:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200676:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200678:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020067a:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020067c:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200680:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200682:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200688:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020068a:	00004917          	auipc	s2,0x4
ffffffffc020068e:	bee90913          	addi	s2,s2,-1042 # ffffffffc0204278 <commands+0x110>
ffffffffc0200692:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200694:	4d91                	li	s11,4
ffffffffc0200696:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200698:	00004497          	auipc	s1,0x4
ffffffffc020069c:	bd848493          	addi	s1,s1,-1064 # ffffffffc0204270 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a0:	000a2703          	lw	a4,0(s4)
ffffffffc02006a4:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a8:	0087569b          	srliw	a3,a4,0x8
ffffffffc02006ac:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	0107571b          	srliw	a4,a4,0x10
ffffffffc02006bc:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006be:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c2:	0087171b          	slliw	a4,a4,0x8
ffffffffc02006c6:	8fd5                	or	a5,a5,a3
ffffffffc02006c8:	00eb7733          	and	a4,s6,a4
ffffffffc02006cc:	8fd9                	or	a5,a5,a4
ffffffffc02006ce:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02006d0:	09778c63          	beq	a5,s7,ffffffffc0200768 <dtb_init+0x1ee>
ffffffffc02006d4:	00fbea63          	bltu	s7,a5,ffffffffc02006e8 <dtb_init+0x16e>
ffffffffc02006d8:	07a78663          	beq	a5,s10,ffffffffc0200744 <dtb_init+0x1ca>
ffffffffc02006dc:	4709                	li	a4,2
ffffffffc02006de:	00e79763          	bne	a5,a4,ffffffffc02006ec <dtb_init+0x172>
ffffffffc02006e2:	4c81                	li	s9,0
ffffffffc02006e4:	8a56                	mv	s4,s5
ffffffffc02006e6:	bf6d                	j	ffffffffc02006a0 <dtb_init+0x126>
ffffffffc02006e8:	ffb78ee3          	beq	a5,s11,ffffffffc02006e4 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006ec:	00004517          	auipc	a0,0x4
ffffffffc02006f0:	c0450513          	addi	a0,a0,-1020 # ffffffffc02042f0 <commands+0x188>
ffffffffc02006f4:	aa1ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f8:	00004517          	auipc	a0,0x4
ffffffffc02006fc:	c3050513          	addi	a0,a0,-976 # ffffffffc0204328 <commands+0x1c0>
}
ffffffffc0200700:	7446                	ld	s0,112(sp)
ffffffffc0200702:	70e6                	ld	ra,120(sp)
ffffffffc0200704:	74a6                	ld	s1,104(sp)
ffffffffc0200706:	7906                	ld	s2,96(sp)
ffffffffc0200708:	69e6                	ld	s3,88(sp)
ffffffffc020070a:	6a46                	ld	s4,80(sp)
ffffffffc020070c:	6aa6                	ld	s5,72(sp)
ffffffffc020070e:	6b06                	ld	s6,64(sp)
ffffffffc0200710:	7be2                	ld	s7,56(sp)
ffffffffc0200712:	7c42                	ld	s8,48(sp)
ffffffffc0200714:	7ca2                	ld	s9,40(sp)
ffffffffc0200716:	7d02                	ld	s10,32(sp)
ffffffffc0200718:	6de2                	ld	s11,24(sp)
ffffffffc020071a:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020071c:	bca5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc020071e:	7446                	ld	s0,112(sp)
ffffffffc0200720:	70e6                	ld	ra,120(sp)
ffffffffc0200722:	74a6                	ld	s1,104(sp)
ffffffffc0200724:	7906                	ld	s2,96(sp)
ffffffffc0200726:	69e6                	ld	s3,88(sp)
ffffffffc0200728:	6a46                	ld	s4,80(sp)
ffffffffc020072a:	6aa6                	ld	s5,72(sp)
ffffffffc020072c:	6b06                	ld	s6,64(sp)
ffffffffc020072e:	7be2                	ld	s7,56(sp)
ffffffffc0200730:	7c42                	ld	s8,48(sp)
ffffffffc0200732:	7ca2                	ld	s9,40(sp)
ffffffffc0200734:	7d02                	ld	s10,32(sp)
ffffffffc0200736:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200738:	00004517          	auipc	a0,0x4
ffffffffc020073c:	b1050513          	addi	a0,a0,-1264 # ffffffffc0204248 <commands+0xe0>
}
ffffffffc0200740:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200742:	bc89                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc0200744:	8556                	mv	a0,s5
ffffffffc0200746:	6c4030ef          	jal	ra,ffffffffc0203e0a <strlen>
ffffffffc020074a:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020074c:	4619                	li	a2,6
ffffffffc020074e:	85a6                	mv	a1,s1
ffffffffc0200750:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200752:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200754:	71c030ef          	jal	ra,ffffffffc0203e70 <strncmp>
ffffffffc0200758:	e111                	bnez	a0,ffffffffc020075c <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020075a:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020075c:	0a91                	addi	s5,s5,4
ffffffffc020075e:	9ad2                	add	s5,s5,s4
ffffffffc0200760:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200764:	8a56                	mv	s4,s5
ffffffffc0200766:	bf2d                	j	ffffffffc02006a0 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200768:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020076c:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200770:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200774:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200778:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077c:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200780:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200784:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200790:	00eaeab3          	or	s5,s5,a4
ffffffffc0200794:	00fb77b3          	and	a5,s6,a5
ffffffffc0200798:	00faeab3          	or	s5,s5,a5
ffffffffc020079c:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020079e:	000c9c63          	bnez	s9,ffffffffc02007b6 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02007a2:	1a82                	slli	s5,s5,0x20
ffffffffc02007a4:	00368793          	addi	a5,a3,3
ffffffffc02007a8:	020ada93          	srli	s5,s5,0x20
ffffffffc02007ac:	9abe                	add	s5,s5,a5
ffffffffc02007ae:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007b2:	8a56                	mv	s4,s5
ffffffffc02007b4:	b5f5                	j	ffffffffc02006a0 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007b6:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ba:	85ca                	mv	a1,s2
ffffffffc02007bc:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007be:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c2:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c6:	0187971b          	slliw	a4,a5,0x18
ffffffffc02007ca:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007ce:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02007d2:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d4:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007d8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02007dc:	8d59                	or	a0,a0,a4
ffffffffc02007de:	00fb77b3          	and	a5,s6,a5
ffffffffc02007e2:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007e4:	1502                	slli	a0,a0,0x20
ffffffffc02007e6:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007e8:	9522                	add	a0,a0,s0
ffffffffc02007ea:	668030ef          	jal	ra,ffffffffc0203e52 <strcmp>
ffffffffc02007ee:	66a2                	ld	a3,8(sp)
ffffffffc02007f0:	f94d                	bnez	a0,ffffffffc02007a2 <dtb_init+0x228>
ffffffffc02007f2:	fb59f8e3          	bgeu	s3,s5,ffffffffc02007a2 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007f6:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007fa:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007fe:	00004517          	auipc	a0,0x4
ffffffffc0200802:	a8250513          	addi	a0,a0,-1406 # ffffffffc0204280 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200806:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080a:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020080e:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200812:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200816:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020081a:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020081e:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200822:	0187d693          	srli	a3,a5,0x18
ffffffffc0200826:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020082a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020082e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200832:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200836:	010f6f33          	or	t5,t5,a6
ffffffffc020083a:	0187529b          	srliw	t0,a4,0x18
ffffffffc020083e:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0186f6b3          	and	a3,a3,s8
ffffffffc020084e:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200852:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0107581b          	srliw	a6,a4,0x10
ffffffffc020085a:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085e:	8361                	srli	a4,a4,0x18
ffffffffc0200860:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200864:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200868:	01e6e6b3          	or	a3,a3,t5
ffffffffc020086c:	00cb7633          	and	a2,s6,a2
ffffffffc0200870:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200874:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200878:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020087c:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200880:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200884:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200888:	0088989b          	slliw	a7,a7,0x8
ffffffffc020088c:	011b78b3          	and	a7,s6,a7
ffffffffc0200890:	005eeeb3          	or	t4,t4,t0
ffffffffc0200894:	00c6e733          	or	a4,a3,a2
ffffffffc0200898:	006c6c33          	or	s8,s8,t1
ffffffffc020089c:	010b76b3          	and	a3,s6,a6
ffffffffc02008a0:	00bb7b33          	and	s6,s6,a1
ffffffffc02008a4:	01d7e7b3          	or	a5,a5,t4
ffffffffc02008a8:	016c6b33          	or	s6,s8,s6
ffffffffc02008ac:	01146433          	or	s0,s0,a7
ffffffffc02008b0:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02008b2:	1702                	slli	a4,a4,0x20
ffffffffc02008b4:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008b6:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008b8:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008ba:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008bc:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008c0:	0167eb33          	or	s6,a5,s6
ffffffffc02008c4:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008c6:	8cfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008ca:	85a2                	mv	a1,s0
ffffffffc02008cc:	00004517          	auipc	a0,0x4
ffffffffc02008d0:	9d450513          	addi	a0,a0,-1580 # ffffffffc02042a0 <commands+0x138>
ffffffffc02008d4:	8c1ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008d8:	014b5613          	srli	a2,s6,0x14
ffffffffc02008dc:	85da                	mv	a1,s6
ffffffffc02008de:	00004517          	auipc	a0,0x4
ffffffffc02008e2:	9da50513          	addi	a0,a0,-1574 # ffffffffc02042b8 <commands+0x150>
ffffffffc02008e6:	8afff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008ea:	008b05b3          	add	a1,s6,s0
ffffffffc02008ee:	15fd                	addi	a1,a1,-1
ffffffffc02008f0:	00004517          	auipc	a0,0x4
ffffffffc02008f4:	9e850513          	addi	a0,a0,-1560 # ffffffffc02042d8 <commands+0x170>
ffffffffc02008f8:	89dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02008fc:	00004517          	auipc	a0,0x4
ffffffffc0200900:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0204328 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200904:	0000d797          	auipc	a5,0xd
ffffffffc0200908:	b687be23          	sd	s0,-1156(a5) # ffffffffc020d480 <memory_base>
        memory_size = mem_size;
ffffffffc020090c:	0000d797          	auipc	a5,0xd
ffffffffc0200910:	b767be23          	sd	s6,-1156(a5) # ffffffffc020d488 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200914:	b3f5                	j	ffffffffc0200700 <dtb_init+0x186>

ffffffffc0200916 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200916:	0000d517          	auipc	a0,0xd
ffffffffc020091a:	b6a53503          	ld	a0,-1174(a0) # ffffffffc020d480 <memory_base>
ffffffffc020091e:	8082                	ret

ffffffffc0200920 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200920:	0000d517          	auipc	a0,0xd
ffffffffc0200924:	b6853503          	ld	a0,-1176(a0) # ffffffffc020d488 <memory_size>
ffffffffc0200928:	8082                	ret

ffffffffc020092a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020092a:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020092e:	8082                	ret

ffffffffc0200930 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200930:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200934:	8082                	ret

ffffffffc0200936 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200936:	8082                	ret

ffffffffc0200938 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200938:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020093c:	00000797          	auipc	a5,0x0
ffffffffc0200940:	3f078793          	addi	a5,a5,1008 # ffffffffc0200d2c <__alltraps>
ffffffffc0200944:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200948:	000407b7          	lui	a5,0x40
ffffffffc020094c:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200950:	8082                	ret

ffffffffc0200952 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200952:	610c                	ld	a1,0(a0)
{
ffffffffc0200954:	1141                	addi	sp,sp,-16
ffffffffc0200956:	e022                	sd	s0,0(sp)
ffffffffc0200958:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020095a:	00004517          	auipc	a0,0x4
ffffffffc020095e:	9e650513          	addi	a0,a0,-1562 # ffffffffc0204340 <commands+0x1d8>
{
ffffffffc0200962:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200964:	831ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200968:	640c                	ld	a1,8(s0)
ffffffffc020096a:	00004517          	auipc	a0,0x4
ffffffffc020096e:	9ee50513          	addi	a0,a0,-1554 # ffffffffc0204358 <commands+0x1f0>
ffffffffc0200972:	823ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200976:	680c                	ld	a1,16(s0)
ffffffffc0200978:	00004517          	auipc	a0,0x4
ffffffffc020097c:	9f850513          	addi	a0,a0,-1544 # ffffffffc0204370 <commands+0x208>
ffffffffc0200980:	815ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200984:	6c0c                	ld	a1,24(s0)
ffffffffc0200986:	00004517          	auipc	a0,0x4
ffffffffc020098a:	a0250513          	addi	a0,a0,-1534 # ffffffffc0204388 <commands+0x220>
ffffffffc020098e:	807ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200992:	700c                	ld	a1,32(s0)
ffffffffc0200994:	00004517          	auipc	a0,0x4
ffffffffc0200998:	a0c50513          	addi	a0,a0,-1524 # ffffffffc02043a0 <commands+0x238>
ffffffffc020099c:	ff8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02009a0:	740c                	ld	a1,40(s0)
ffffffffc02009a2:	00004517          	auipc	a0,0x4
ffffffffc02009a6:	a1650513          	addi	a0,a0,-1514 # ffffffffc02043b8 <commands+0x250>
ffffffffc02009aa:	feaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02009ae:	780c                	ld	a1,48(s0)
ffffffffc02009b0:	00004517          	auipc	a0,0x4
ffffffffc02009b4:	a2050513          	addi	a0,a0,-1504 # ffffffffc02043d0 <commands+0x268>
ffffffffc02009b8:	fdcff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02009bc:	7c0c                	ld	a1,56(s0)
ffffffffc02009be:	00004517          	auipc	a0,0x4
ffffffffc02009c2:	a2a50513          	addi	a0,a0,-1494 # ffffffffc02043e8 <commands+0x280>
ffffffffc02009c6:	fceff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02009ca:	602c                	ld	a1,64(s0)
ffffffffc02009cc:	00004517          	auipc	a0,0x4
ffffffffc02009d0:	a3450513          	addi	a0,a0,-1484 # ffffffffc0204400 <commands+0x298>
ffffffffc02009d4:	fc0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009d8:	642c                	ld	a1,72(s0)
ffffffffc02009da:	00004517          	auipc	a0,0x4
ffffffffc02009de:	a3e50513          	addi	a0,a0,-1474 # ffffffffc0204418 <commands+0x2b0>
ffffffffc02009e2:	fb2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009e6:	682c                	ld	a1,80(s0)
ffffffffc02009e8:	00004517          	auipc	a0,0x4
ffffffffc02009ec:	a4850513          	addi	a0,a0,-1464 # ffffffffc0204430 <commands+0x2c8>
ffffffffc02009f0:	fa4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009f4:	6c2c                	ld	a1,88(s0)
ffffffffc02009f6:	00004517          	auipc	a0,0x4
ffffffffc02009fa:	a5250513          	addi	a0,a0,-1454 # ffffffffc0204448 <commands+0x2e0>
ffffffffc02009fe:	f96ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a02:	702c                	ld	a1,96(s0)
ffffffffc0200a04:	00004517          	auipc	a0,0x4
ffffffffc0200a08:	a5c50513          	addi	a0,a0,-1444 # ffffffffc0204460 <commands+0x2f8>
ffffffffc0200a0c:	f88ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a10:	742c                	ld	a1,104(s0)
ffffffffc0200a12:	00004517          	auipc	a0,0x4
ffffffffc0200a16:	a6650513          	addi	a0,a0,-1434 # ffffffffc0204478 <commands+0x310>
ffffffffc0200a1a:	f7aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a1e:	782c                	ld	a1,112(s0)
ffffffffc0200a20:	00004517          	auipc	a0,0x4
ffffffffc0200a24:	a7050513          	addi	a0,a0,-1424 # ffffffffc0204490 <commands+0x328>
ffffffffc0200a28:	f6cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a2c:	7c2c                	ld	a1,120(s0)
ffffffffc0200a2e:	00004517          	auipc	a0,0x4
ffffffffc0200a32:	a7a50513          	addi	a0,a0,-1414 # ffffffffc02044a8 <commands+0x340>
ffffffffc0200a36:	f5eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a3a:	604c                	ld	a1,128(s0)
ffffffffc0200a3c:	00004517          	auipc	a0,0x4
ffffffffc0200a40:	a8450513          	addi	a0,a0,-1404 # ffffffffc02044c0 <commands+0x358>
ffffffffc0200a44:	f50ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a48:	644c                	ld	a1,136(s0)
ffffffffc0200a4a:	00004517          	auipc	a0,0x4
ffffffffc0200a4e:	a8e50513          	addi	a0,a0,-1394 # ffffffffc02044d8 <commands+0x370>
ffffffffc0200a52:	f42ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a56:	684c                	ld	a1,144(s0)
ffffffffc0200a58:	00004517          	auipc	a0,0x4
ffffffffc0200a5c:	a9850513          	addi	a0,a0,-1384 # ffffffffc02044f0 <commands+0x388>
ffffffffc0200a60:	f34ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a64:	6c4c                	ld	a1,152(s0)
ffffffffc0200a66:	00004517          	auipc	a0,0x4
ffffffffc0200a6a:	aa250513          	addi	a0,a0,-1374 # ffffffffc0204508 <commands+0x3a0>
ffffffffc0200a6e:	f26ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a72:	704c                	ld	a1,160(s0)
ffffffffc0200a74:	00004517          	auipc	a0,0x4
ffffffffc0200a78:	aac50513          	addi	a0,a0,-1364 # ffffffffc0204520 <commands+0x3b8>
ffffffffc0200a7c:	f18ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a80:	744c                	ld	a1,168(s0)
ffffffffc0200a82:	00004517          	auipc	a0,0x4
ffffffffc0200a86:	ab650513          	addi	a0,a0,-1354 # ffffffffc0204538 <commands+0x3d0>
ffffffffc0200a8a:	f0aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a8e:	784c                	ld	a1,176(s0)
ffffffffc0200a90:	00004517          	auipc	a0,0x4
ffffffffc0200a94:	ac050513          	addi	a0,a0,-1344 # ffffffffc0204550 <commands+0x3e8>
ffffffffc0200a98:	efcff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a9c:	7c4c                	ld	a1,184(s0)
ffffffffc0200a9e:	00004517          	auipc	a0,0x4
ffffffffc0200aa2:	aca50513          	addi	a0,a0,-1334 # ffffffffc0204568 <commands+0x400>
ffffffffc0200aa6:	eeeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200aaa:	606c                	ld	a1,192(s0)
ffffffffc0200aac:	00004517          	auipc	a0,0x4
ffffffffc0200ab0:	ad450513          	addi	a0,a0,-1324 # ffffffffc0204580 <commands+0x418>
ffffffffc0200ab4:	ee0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200ab8:	646c                	ld	a1,200(s0)
ffffffffc0200aba:	00004517          	auipc	a0,0x4
ffffffffc0200abe:	ade50513          	addi	a0,a0,-1314 # ffffffffc0204598 <commands+0x430>
ffffffffc0200ac2:	ed2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200ac6:	686c                	ld	a1,208(s0)
ffffffffc0200ac8:	00004517          	auipc	a0,0x4
ffffffffc0200acc:	ae850513          	addi	a0,a0,-1304 # ffffffffc02045b0 <commands+0x448>
ffffffffc0200ad0:	ec4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200ad4:	6c6c                	ld	a1,216(s0)
ffffffffc0200ad6:	00004517          	auipc	a0,0x4
ffffffffc0200ada:	af250513          	addi	a0,a0,-1294 # ffffffffc02045c8 <commands+0x460>
ffffffffc0200ade:	eb6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ae2:	706c                	ld	a1,224(s0)
ffffffffc0200ae4:	00004517          	auipc	a0,0x4
ffffffffc0200ae8:	afc50513          	addi	a0,a0,-1284 # ffffffffc02045e0 <commands+0x478>
ffffffffc0200aec:	ea8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200af0:	746c                	ld	a1,232(s0)
ffffffffc0200af2:	00004517          	auipc	a0,0x4
ffffffffc0200af6:	b0650513          	addi	a0,a0,-1274 # ffffffffc02045f8 <commands+0x490>
ffffffffc0200afa:	e9aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200afe:	786c                	ld	a1,240(s0)
ffffffffc0200b00:	00004517          	auipc	a0,0x4
ffffffffc0200b04:	b1050513          	addi	a0,a0,-1264 # ffffffffc0204610 <commands+0x4a8>
ffffffffc0200b08:	e8cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b0c:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b0e:	6402                	ld	s0,0(sp)
ffffffffc0200b10:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b12:	00004517          	auipc	a0,0x4
ffffffffc0200b16:	b1650513          	addi	a0,a0,-1258 # ffffffffc0204628 <commands+0x4c0>
}
ffffffffc0200b1a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b1c:	e78ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b20 <print_trapframe>:
{
ffffffffc0200b20:	1141                	addi	sp,sp,-16
ffffffffc0200b22:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b24:	85aa                	mv	a1,a0
{
ffffffffc0200b26:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b28:	00004517          	auipc	a0,0x4
ffffffffc0200b2c:	b1850513          	addi	a0,a0,-1256 # ffffffffc0204640 <commands+0x4d8>
{
ffffffffc0200b30:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b32:	e62ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b36:	8522                	mv	a0,s0
ffffffffc0200b38:	e1bff0ef          	jal	ra,ffffffffc0200952 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b3c:	10043583          	ld	a1,256(s0)
ffffffffc0200b40:	00004517          	auipc	a0,0x4
ffffffffc0200b44:	b1850513          	addi	a0,a0,-1256 # ffffffffc0204658 <commands+0x4f0>
ffffffffc0200b48:	e4cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b4c:	10843583          	ld	a1,264(s0)
ffffffffc0200b50:	00004517          	auipc	a0,0x4
ffffffffc0200b54:	b2050513          	addi	a0,a0,-1248 # ffffffffc0204670 <commands+0x508>
ffffffffc0200b58:	e3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b5c:	11043583          	ld	a1,272(s0)
ffffffffc0200b60:	00004517          	auipc	a0,0x4
ffffffffc0200b64:	b2850513          	addi	a0,a0,-1240 # ffffffffc0204688 <commands+0x520>
ffffffffc0200b68:	e2cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b6c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b70:	6402                	ld	s0,0(sp)
ffffffffc0200b72:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b74:	00004517          	auipc	a0,0x4
ffffffffc0200b78:	b2c50513          	addi	a0,a0,-1236 # ffffffffc02046a0 <commands+0x538>
}
ffffffffc0200b7c:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b7e:	e16ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b82 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200b82:	11853783          	ld	a5,280(a0)
ffffffffc0200b86:	472d                	li	a4,11
ffffffffc0200b88:	0786                	slli	a5,a5,0x1
ffffffffc0200b8a:	8385                	srli	a5,a5,0x1
ffffffffc0200b8c:	08f76663          	bltu	a4,a5,ffffffffc0200c18 <interrupt_handler+0x96>
ffffffffc0200b90:	00004717          	auipc	a4,0x4
ffffffffc0200b94:	bf870713          	addi	a4,a4,-1032 # ffffffffc0204788 <commands+0x620>
ffffffffc0200b98:	078a                	slli	a5,a5,0x2
ffffffffc0200b9a:	97ba                	add	a5,a5,a4
ffffffffc0200b9c:	439c                	lw	a5,0(a5)
ffffffffc0200b9e:	97ba                	add	a5,a5,a4
ffffffffc0200ba0:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200ba2:	00004517          	auipc	a0,0x4
ffffffffc0200ba6:	b7650513          	addi	a0,a0,-1162 # ffffffffc0204718 <commands+0x5b0>
ffffffffc0200baa:	deaff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200bae:	00004517          	auipc	a0,0x4
ffffffffc0200bb2:	b4a50513          	addi	a0,a0,-1206 # ffffffffc02046f8 <commands+0x590>
ffffffffc0200bb6:	ddeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200bba:	00004517          	auipc	a0,0x4
ffffffffc0200bbe:	afe50513          	addi	a0,a0,-1282 # ffffffffc02046b8 <commands+0x550>
ffffffffc0200bc2:	dd2ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200bc6:	00004517          	auipc	a0,0x4
ffffffffc0200bca:	b1250513          	addi	a0,a0,-1262 # ffffffffc02046d8 <commands+0x570>
ffffffffc0200bce:	dc6ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200bd2:	1141                	addi	sp,sp,-16
ffffffffc0200bd4:	e022                	sd	s0,0(sp)
ffffffffc0200bd6:	e406                	sd	ra,8(sp)
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        /*LAB3 请补充你在lab3中的代码 */ 
        clock_set_next_event(); // 发生这次时钟中断的时候，我们要设置下一次时钟中断
ffffffffc0200bd8:	917ff0ef          	jal	ra,ffffffffc02004ee <clock_set_next_event>
        if (++ticks % TICK_NUM == 0)
ffffffffc0200bdc:	0000d697          	auipc	a3,0xd
ffffffffc0200be0:	89468693          	addi	a3,a3,-1900 # ffffffffc020d470 <ticks>
ffffffffc0200be4:	629c                	ld	a5,0(a3)
ffffffffc0200be6:	06400713          	li	a4,100
ffffffffc0200bea:	0000d417          	auipc	s0,0xd
ffffffffc0200bee:	8a640413          	addi	s0,s0,-1882 # ffffffffc020d490 <print_num>
ffffffffc0200bf2:	0785                	addi	a5,a5,1
ffffffffc0200bf4:	02e7f733          	remu	a4,a5,a4
ffffffffc0200bf8:	e29c                	sd	a5,0(a3)
ffffffffc0200bfa:	c305                	beqz	a4,ffffffffc0200c1a <interrupt_handler+0x98>
        {
            print_num++;
            print_ticks();
        }
        if (print_num == 10)
ffffffffc0200bfc:	4018                	lw	a4,0(s0)
ffffffffc0200bfe:	47a9                	li	a5,10
ffffffffc0200c00:	02f70963          	beq	a4,a5,ffffffffc0200c32 <interrupt_handler+0xb0>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c04:	60a2                	ld	ra,8(sp)
ffffffffc0200c06:	6402                	ld	s0,0(sp)
ffffffffc0200c08:	0141                	addi	sp,sp,16
ffffffffc0200c0a:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c0c:	00004517          	auipc	a0,0x4
ffffffffc0200c10:	b5c50513          	addi	a0,a0,-1188 # ffffffffc0204768 <commands+0x600>
ffffffffc0200c14:	d80ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c18:	b721                	j	ffffffffc0200b20 <print_trapframe>
            print_num++;
ffffffffc0200c1a:	401c                	lw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c1c:	06400593          	li	a1,100
ffffffffc0200c20:	00004517          	auipc	a0,0x4
ffffffffc0200c24:	b1850513          	addi	a0,a0,-1256 # ffffffffc0204738 <commands+0x5d0>
            print_num++;
ffffffffc0200c28:	2785                	addiw	a5,a5,1
ffffffffc0200c2a:	c01c                	sw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c2c:	d68ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0200c30:	b7f1                	j	ffffffffc0200bfc <interrupt_handler+0x7a>
            cprintf("Calling SBI shutdown...\n");
ffffffffc0200c32:	00004517          	auipc	a0,0x4
ffffffffc0200c36:	b1650513          	addi	a0,a0,-1258 # ffffffffc0204748 <commands+0x5e0>
ffffffffc0200c3a:	d5aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200c3e:	4501                	li	a0,0
ffffffffc0200c40:	4581                	li	a1,0
ffffffffc0200c42:	4601                	li	a2,0
ffffffffc0200c44:	48a1                	li	a7,8
ffffffffc0200c46:	00000073          	ecall
}
ffffffffc0200c4a:	bf6d                	j	ffffffffc0200c04 <interrupt_handler+0x82>

ffffffffc0200c4c <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c4c:	11853783          	ld	a5,280(a0)
ffffffffc0200c50:	473d                	li	a4,15
ffffffffc0200c52:	0cf76563          	bltu	a4,a5,ffffffffc0200d1c <exception_handler+0xd0>
ffffffffc0200c56:	00004717          	auipc	a4,0x4
ffffffffc0200c5a:	cfa70713          	addi	a4,a4,-774 # ffffffffc0204950 <commands+0x7e8>
ffffffffc0200c5e:	078a                	slli	a5,a5,0x2
ffffffffc0200c60:	97ba                	add	a5,a5,a4
ffffffffc0200c62:	439c                	lw	a5,0(a5)
ffffffffc0200c64:	97ba                	add	a5,a5,a4
ffffffffc0200c66:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200c68:	00004517          	auipc	a0,0x4
ffffffffc0200c6c:	cd050513          	addi	a0,a0,-816 # ffffffffc0204938 <commands+0x7d0>
ffffffffc0200c70:	d24ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200c74:	00004517          	auipc	a0,0x4
ffffffffc0200c78:	b4450513          	addi	a0,a0,-1212 # ffffffffc02047b8 <commands+0x650>
ffffffffc0200c7c:	d18ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200c80:	00004517          	auipc	a0,0x4
ffffffffc0200c84:	b5850513          	addi	a0,a0,-1192 # ffffffffc02047d8 <commands+0x670>
ffffffffc0200c88:	d0cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200c8c:	00004517          	auipc	a0,0x4
ffffffffc0200c90:	b6c50513          	addi	a0,a0,-1172 # ffffffffc02047f8 <commands+0x690>
ffffffffc0200c94:	d00ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200c98:	00004517          	auipc	a0,0x4
ffffffffc0200c9c:	b7850513          	addi	a0,a0,-1160 # ffffffffc0204810 <commands+0x6a8>
ffffffffc0200ca0:	cf4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200ca4:	00004517          	auipc	a0,0x4
ffffffffc0200ca8:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0204820 <commands+0x6b8>
ffffffffc0200cac:	ce8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200cb0:	00004517          	auipc	a0,0x4
ffffffffc0200cb4:	b9050513          	addi	a0,a0,-1136 # ffffffffc0204840 <commands+0x6d8>
ffffffffc0200cb8:	cdcff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200cbc:	00004517          	auipc	a0,0x4
ffffffffc0200cc0:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0204858 <commands+0x6f0>
ffffffffc0200cc4:	cd0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200cc8:	00004517          	auipc	a0,0x4
ffffffffc0200ccc:	ba850513          	addi	a0,a0,-1112 # ffffffffc0204870 <commands+0x708>
ffffffffc0200cd0:	cc4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200cd4:	00004517          	auipc	a0,0x4
ffffffffc0200cd8:	bb450513          	addi	a0,a0,-1100 # ffffffffc0204888 <commands+0x720>
ffffffffc0200cdc:	cb8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200ce0:	00004517          	auipc	a0,0x4
ffffffffc0200ce4:	bc850513          	addi	a0,a0,-1080 # ffffffffc02048a8 <commands+0x740>
ffffffffc0200ce8:	cacff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cec:	00004517          	auipc	a0,0x4
ffffffffc0200cf0:	bdc50513          	addi	a0,a0,-1060 # ffffffffc02048c8 <commands+0x760>
ffffffffc0200cf4:	ca0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200cf8:	00004517          	auipc	a0,0x4
ffffffffc0200cfc:	bf050513          	addi	a0,a0,-1040 # ffffffffc02048e8 <commands+0x780>
ffffffffc0200d00:	c94ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200d04:	00004517          	auipc	a0,0x4
ffffffffc0200d08:	c0450513          	addi	a0,a0,-1020 # ffffffffc0204908 <commands+0x7a0>
ffffffffc0200d0c:	c88ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200d10:	00004517          	auipc	a0,0x4
ffffffffc0200d14:	c1050513          	addi	a0,a0,-1008 # ffffffffc0204920 <commands+0x7b8>
ffffffffc0200d18:	c7cff06f          	j	ffffffffc0200194 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200d1c:	b511                	j	ffffffffc0200b20 <print_trapframe>

ffffffffc0200d1e <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d1e:	11853783          	ld	a5,280(a0)
ffffffffc0200d22:	0007c363          	bltz	a5,ffffffffc0200d28 <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200d26:	b71d                	j	ffffffffc0200c4c <exception_handler>
        interrupt_handler(tf);
ffffffffc0200d28:	bda9                	j	ffffffffc0200b82 <interrupt_handler>
	...

ffffffffc0200d2c <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200d2c:	14011073          	csrw	sscratch,sp
ffffffffc0200d30:	712d                	addi	sp,sp,-288
ffffffffc0200d32:	e406                	sd	ra,8(sp)
ffffffffc0200d34:	ec0e                	sd	gp,24(sp)
ffffffffc0200d36:	f012                	sd	tp,32(sp)
ffffffffc0200d38:	f416                	sd	t0,40(sp)
ffffffffc0200d3a:	f81a                	sd	t1,48(sp)
ffffffffc0200d3c:	fc1e                	sd	t2,56(sp)
ffffffffc0200d3e:	e0a2                	sd	s0,64(sp)
ffffffffc0200d40:	e4a6                	sd	s1,72(sp)
ffffffffc0200d42:	e8aa                	sd	a0,80(sp)
ffffffffc0200d44:	ecae                	sd	a1,88(sp)
ffffffffc0200d46:	f0b2                	sd	a2,96(sp)
ffffffffc0200d48:	f4b6                	sd	a3,104(sp)
ffffffffc0200d4a:	f8ba                	sd	a4,112(sp)
ffffffffc0200d4c:	fcbe                	sd	a5,120(sp)
ffffffffc0200d4e:	e142                	sd	a6,128(sp)
ffffffffc0200d50:	e546                	sd	a7,136(sp)
ffffffffc0200d52:	e94a                	sd	s2,144(sp)
ffffffffc0200d54:	ed4e                	sd	s3,152(sp)
ffffffffc0200d56:	f152                	sd	s4,160(sp)
ffffffffc0200d58:	f556                	sd	s5,168(sp)
ffffffffc0200d5a:	f95a                	sd	s6,176(sp)
ffffffffc0200d5c:	fd5e                	sd	s7,184(sp)
ffffffffc0200d5e:	e1e2                	sd	s8,192(sp)
ffffffffc0200d60:	e5e6                	sd	s9,200(sp)
ffffffffc0200d62:	e9ea                	sd	s10,208(sp)
ffffffffc0200d64:	edee                	sd	s11,216(sp)
ffffffffc0200d66:	f1f2                	sd	t3,224(sp)
ffffffffc0200d68:	f5f6                	sd	t4,232(sp)
ffffffffc0200d6a:	f9fa                	sd	t5,240(sp)
ffffffffc0200d6c:	fdfe                	sd	t6,248(sp)
ffffffffc0200d6e:	14002473          	csrr	s0,sscratch
ffffffffc0200d72:	100024f3          	csrr	s1,sstatus
ffffffffc0200d76:	14102973          	csrr	s2,sepc
ffffffffc0200d7a:	143029f3          	csrr	s3,stval
ffffffffc0200d7e:	14202a73          	csrr	s4,scause
ffffffffc0200d82:	e822                	sd	s0,16(sp)
ffffffffc0200d84:	e226                	sd	s1,256(sp)
ffffffffc0200d86:	e64a                	sd	s2,264(sp)
ffffffffc0200d88:	ea4e                	sd	s3,272(sp)
ffffffffc0200d8a:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d8c:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d8e:	f91ff0ef          	jal	ra,ffffffffc0200d1e <trap>

ffffffffc0200d92 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d92:	6492                	ld	s1,256(sp)
ffffffffc0200d94:	6932                	ld	s2,264(sp)
ffffffffc0200d96:	10049073          	csrw	sstatus,s1
ffffffffc0200d9a:	14191073          	csrw	sepc,s2
ffffffffc0200d9e:	60a2                	ld	ra,8(sp)
ffffffffc0200da0:	61e2                	ld	gp,24(sp)
ffffffffc0200da2:	7202                	ld	tp,32(sp)
ffffffffc0200da4:	72a2                	ld	t0,40(sp)
ffffffffc0200da6:	7342                	ld	t1,48(sp)
ffffffffc0200da8:	73e2                	ld	t2,56(sp)
ffffffffc0200daa:	6406                	ld	s0,64(sp)
ffffffffc0200dac:	64a6                	ld	s1,72(sp)
ffffffffc0200dae:	6546                	ld	a0,80(sp)
ffffffffc0200db0:	65e6                	ld	a1,88(sp)
ffffffffc0200db2:	7606                	ld	a2,96(sp)
ffffffffc0200db4:	76a6                	ld	a3,104(sp)
ffffffffc0200db6:	7746                	ld	a4,112(sp)
ffffffffc0200db8:	77e6                	ld	a5,120(sp)
ffffffffc0200dba:	680a                	ld	a6,128(sp)
ffffffffc0200dbc:	68aa                	ld	a7,136(sp)
ffffffffc0200dbe:	694a                	ld	s2,144(sp)
ffffffffc0200dc0:	69ea                	ld	s3,152(sp)
ffffffffc0200dc2:	7a0a                	ld	s4,160(sp)
ffffffffc0200dc4:	7aaa                	ld	s5,168(sp)
ffffffffc0200dc6:	7b4a                	ld	s6,176(sp)
ffffffffc0200dc8:	7bea                	ld	s7,184(sp)
ffffffffc0200dca:	6c0e                	ld	s8,192(sp)
ffffffffc0200dcc:	6cae                	ld	s9,200(sp)
ffffffffc0200dce:	6d4e                	ld	s10,208(sp)
ffffffffc0200dd0:	6dee                	ld	s11,216(sp)
ffffffffc0200dd2:	7e0e                	ld	t3,224(sp)
ffffffffc0200dd4:	7eae                	ld	t4,232(sp)
ffffffffc0200dd6:	7f4e                	ld	t5,240(sp)
ffffffffc0200dd8:	7fee                	ld	t6,248(sp)
ffffffffc0200dda:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200ddc:	10200073          	sret

ffffffffc0200de0 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200de0:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200de2:	bf45                	j	ffffffffc0200d92 <__trapret>
	...

ffffffffc0200de6 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200de6:	00008797          	auipc	a5,0x8
ffffffffc0200dea:	64a78793          	addi	a5,a5,1610 # ffffffffc0209430 <free_area>
ffffffffc0200dee:	e79c                	sd	a5,8(a5)
ffffffffc0200df0:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200df2:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200df6:	8082                	ret

ffffffffc0200df8 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200df8:	00008517          	auipc	a0,0x8
ffffffffc0200dfc:	64856503          	lwu	a0,1608(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200e00:	8082                	ret

ffffffffc0200e02 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200e02:	715d                	addi	sp,sp,-80
ffffffffc0200e04:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e06:	00008417          	auipc	s0,0x8
ffffffffc0200e0a:	62a40413          	addi	s0,s0,1578 # ffffffffc0209430 <free_area>
ffffffffc0200e0e:	641c                	ld	a5,8(s0)
ffffffffc0200e10:	e486                	sd	ra,72(sp)
ffffffffc0200e12:	fc26                	sd	s1,56(sp)
ffffffffc0200e14:	f84a                	sd	s2,48(sp)
ffffffffc0200e16:	f44e                	sd	s3,40(sp)
ffffffffc0200e18:	f052                	sd	s4,32(sp)
ffffffffc0200e1a:	ec56                	sd	s5,24(sp)
ffffffffc0200e1c:	e85a                	sd	s6,16(sp)
ffffffffc0200e1e:	e45e                	sd	s7,8(sp)
ffffffffc0200e20:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e22:	2a878d63          	beq	a5,s0,ffffffffc02010dc <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200e26:	4481                	li	s1,0
ffffffffc0200e28:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e2a:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200e2e:	8b09                	andi	a4,a4,2
ffffffffc0200e30:	2a070a63          	beqz	a4,ffffffffc02010e4 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0200e34:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e38:	679c                	ld	a5,8(a5)
ffffffffc0200e3a:	2905                	addiw	s2,s2,1
ffffffffc0200e3c:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e3e:	fe8796e3          	bne	a5,s0,ffffffffc0200e2a <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200e42:	89a6                	mv	s3,s1
ffffffffc0200e44:	6db000ef          	jal	ra,ffffffffc0201d1e <nr_free_pages>
ffffffffc0200e48:	6f351e63          	bne	a0,s3,ffffffffc0201544 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e4c:	4505                	li	a0,1
ffffffffc0200e4e:	653000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0200e52:	8aaa                	mv	s5,a0
ffffffffc0200e54:	42050863          	beqz	a0,ffffffffc0201284 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e58:	4505                	li	a0,1
ffffffffc0200e5a:	647000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0200e5e:	89aa                	mv	s3,a0
ffffffffc0200e60:	70050263          	beqz	a0,ffffffffc0201564 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e64:	4505                	li	a0,1
ffffffffc0200e66:	63b000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0200e6a:	8a2a                	mv	s4,a0
ffffffffc0200e6c:	48050c63          	beqz	a0,ffffffffc0201304 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e70:	293a8a63          	beq	s5,s3,ffffffffc0201104 <default_check+0x302>
ffffffffc0200e74:	28aa8863          	beq	s5,a0,ffffffffc0201104 <default_check+0x302>
ffffffffc0200e78:	28a98663          	beq	s3,a0,ffffffffc0201104 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e7c:	000aa783          	lw	a5,0(s5)
ffffffffc0200e80:	2a079263          	bnez	a5,ffffffffc0201124 <default_check+0x322>
ffffffffc0200e84:	0009a783          	lw	a5,0(s3)
ffffffffc0200e88:	28079e63          	bnez	a5,ffffffffc0201124 <default_check+0x322>
ffffffffc0200e8c:	411c                	lw	a5,0(a0)
ffffffffc0200e8e:	28079b63          	bnez	a5,ffffffffc0201124 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200e92:	0000c797          	auipc	a5,0xc
ffffffffc0200e96:	6267b783          	ld	a5,1574(a5) # ffffffffc020d4b8 <pages>
ffffffffc0200e9a:	40fa8733          	sub	a4,s5,a5
ffffffffc0200e9e:	00005617          	auipc	a2,0x5
ffffffffc0200ea2:	b7263603          	ld	a2,-1166(a2) # ffffffffc0205a10 <nbase>
ffffffffc0200ea6:	8719                	srai	a4,a4,0x6
ffffffffc0200ea8:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200eaa:	0000c697          	auipc	a3,0xc
ffffffffc0200eae:	6066b683          	ld	a3,1542(a3) # ffffffffc020d4b0 <npage>
ffffffffc0200eb2:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200eb4:	0732                	slli	a4,a4,0xc
ffffffffc0200eb6:	28d77763          	bgeu	a4,a3,ffffffffc0201144 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200eba:	40f98733          	sub	a4,s3,a5
ffffffffc0200ebe:	8719                	srai	a4,a4,0x6
ffffffffc0200ec0:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ec2:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200ec4:	4cd77063          	bgeu	a4,a3,ffffffffc0201384 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200ec8:	40f507b3          	sub	a5,a0,a5
ffffffffc0200ecc:	8799                	srai	a5,a5,0x6
ffffffffc0200ece:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ed0:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ed2:	30d7f963          	bgeu	a5,a3,ffffffffc02011e4 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200ed6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200ed8:	00043c03          	ld	s8,0(s0)
ffffffffc0200edc:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200ee0:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200ee4:	e400                	sd	s0,8(s0)
ffffffffc0200ee6:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200ee8:	00008797          	auipc	a5,0x8
ffffffffc0200eec:	5407ac23          	sw	zero,1368(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200ef0:	5b1000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0200ef4:	2c051863          	bnez	a0,ffffffffc02011c4 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200ef8:	4585                	li	a1,1
ffffffffc0200efa:	8556                	mv	a0,s5
ffffffffc0200efc:	5e3000ef          	jal	ra,ffffffffc0201cde <free_pages>
    free_page(p1);
ffffffffc0200f00:	4585                	li	a1,1
ffffffffc0200f02:	854e                	mv	a0,s3
ffffffffc0200f04:	5db000ef          	jal	ra,ffffffffc0201cde <free_pages>
    free_page(p2);
ffffffffc0200f08:	4585                	li	a1,1
ffffffffc0200f0a:	8552                	mv	a0,s4
ffffffffc0200f0c:	5d3000ef          	jal	ra,ffffffffc0201cde <free_pages>
    assert(nr_free == 3);
ffffffffc0200f10:	4818                	lw	a4,16(s0)
ffffffffc0200f12:	478d                	li	a5,3
ffffffffc0200f14:	28f71863          	bne	a4,a5,ffffffffc02011a4 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f18:	4505                	li	a0,1
ffffffffc0200f1a:	587000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0200f1e:	89aa                	mv	s3,a0
ffffffffc0200f20:	26050263          	beqz	a0,ffffffffc0201184 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f24:	4505                	li	a0,1
ffffffffc0200f26:	57b000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0200f2a:	8aaa                	mv	s5,a0
ffffffffc0200f2c:	3a050c63          	beqz	a0,ffffffffc02012e4 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f30:	4505                	li	a0,1
ffffffffc0200f32:	56f000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0200f36:	8a2a                	mv	s4,a0
ffffffffc0200f38:	38050663          	beqz	a0,ffffffffc02012c4 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200f3c:	4505                	li	a0,1
ffffffffc0200f3e:	563000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0200f42:	36051163          	bnez	a0,ffffffffc02012a4 <default_check+0x4a2>
    free_page(p0);
ffffffffc0200f46:	4585                	li	a1,1
ffffffffc0200f48:	854e                	mv	a0,s3
ffffffffc0200f4a:	595000ef          	jal	ra,ffffffffc0201cde <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200f4e:	641c                	ld	a5,8(s0)
ffffffffc0200f50:	20878a63          	beq	a5,s0,ffffffffc0201164 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0200f54:	4505                	li	a0,1
ffffffffc0200f56:	54b000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0200f5a:	30a99563          	bne	s3,a0,ffffffffc0201264 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0200f5e:	4505                	li	a0,1
ffffffffc0200f60:	541000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0200f64:	2e051063          	bnez	a0,ffffffffc0201244 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0200f68:	481c                	lw	a5,16(s0)
ffffffffc0200f6a:	2a079d63          	bnez	a5,ffffffffc0201224 <default_check+0x422>
    free_page(p);
ffffffffc0200f6e:	854e                	mv	a0,s3
ffffffffc0200f70:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200f72:	01843023          	sd	s8,0(s0)
ffffffffc0200f76:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200f7a:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200f7e:	561000ef          	jal	ra,ffffffffc0201cde <free_pages>
    free_page(p1);
ffffffffc0200f82:	4585                	li	a1,1
ffffffffc0200f84:	8556                	mv	a0,s5
ffffffffc0200f86:	559000ef          	jal	ra,ffffffffc0201cde <free_pages>
    free_page(p2);
ffffffffc0200f8a:	4585                	li	a1,1
ffffffffc0200f8c:	8552                	mv	a0,s4
ffffffffc0200f8e:	551000ef          	jal	ra,ffffffffc0201cde <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200f92:	4515                	li	a0,5
ffffffffc0200f94:	50d000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0200f98:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f9a:	26050563          	beqz	a0,ffffffffc0201204 <default_check+0x402>
ffffffffc0200f9e:	651c                	ld	a5,8(a0)
ffffffffc0200fa0:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200fa2:	8b85                	andi	a5,a5,1
ffffffffc0200fa4:	54079063          	bnez	a5,ffffffffc02014e4 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200fa8:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200faa:	00043b03          	ld	s6,0(s0)
ffffffffc0200fae:	00843a83          	ld	s5,8(s0)
ffffffffc0200fb2:	e000                	sd	s0,0(s0)
ffffffffc0200fb4:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200fb6:	4eb000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0200fba:	50051563          	bnez	a0,ffffffffc02014c4 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200fbe:	08098a13          	addi	s4,s3,128
ffffffffc0200fc2:	8552                	mv	a0,s4
ffffffffc0200fc4:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200fc6:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200fca:	00008797          	auipc	a5,0x8
ffffffffc0200fce:	4607ab23          	sw	zero,1142(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200fd2:	50d000ef          	jal	ra,ffffffffc0201cde <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200fd6:	4511                	li	a0,4
ffffffffc0200fd8:	4c9000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0200fdc:	4c051463          	bnez	a0,ffffffffc02014a4 <default_check+0x6a2>
ffffffffc0200fe0:	0889b783          	ld	a5,136(s3)
ffffffffc0200fe4:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200fe6:	8b85                	andi	a5,a5,1
ffffffffc0200fe8:	48078e63          	beqz	a5,ffffffffc0201484 <default_check+0x682>
ffffffffc0200fec:	0909a703          	lw	a4,144(s3)
ffffffffc0200ff0:	478d                	li	a5,3
ffffffffc0200ff2:	48f71963          	bne	a4,a5,ffffffffc0201484 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200ff6:	450d                	li	a0,3
ffffffffc0200ff8:	4a9000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0200ffc:	8c2a                	mv	s8,a0
ffffffffc0200ffe:	46050363          	beqz	a0,ffffffffc0201464 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0201002:	4505                	li	a0,1
ffffffffc0201004:	49d000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0201008:	42051e63          	bnez	a0,ffffffffc0201444 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc020100c:	418a1c63          	bne	s4,s8,ffffffffc0201424 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201010:	4585                	li	a1,1
ffffffffc0201012:	854e                	mv	a0,s3
ffffffffc0201014:	4cb000ef          	jal	ra,ffffffffc0201cde <free_pages>
    free_pages(p1, 3);
ffffffffc0201018:	458d                	li	a1,3
ffffffffc020101a:	8552                	mv	a0,s4
ffffffffc020101c:	4c3000ef          	jal	ra,ffffffffc0201cde <free_pages>
ffffffffc0201020:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201024:	04098c13          	addi	s8,s3,64
ffffffffc0201028:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020102a:	8b85                	andi	a5,a5,1
ffffffffc020102c:	3c078c63          	beqz	a5,ffffffffc0201404 <default_check+0x602>
ffffffffc0201030:	0109a703          	lw	a4,16(s3)
ffffffffc0201034:	4785                	li	a5,1
ffffffffc0201036:	3cf71763          	bne	a4,a5,ffffffffc0201404 <default_check+0x602>
ffffffffc020103a:	008a3783          	ld	a5,8(s4)
ffffffffc020103e:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201040:	8b85                	andi	a5,a5,1
ffffffffc0201042:	3a078163          	beqz	a5,ffffffffc02013e4 <default_check+0x5e2>
ffffffffc0201046:	010a2703          	lw	a4,16(s4)
ffffffffc020104a:	478d                	li	a5,3
ffffffffc020104c:	38f71c63          	bne	a4,a5,ffffffffc02013e4 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201050:	4505                	li	a0,1
ffffffffc0201052:	44f000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0201056:	36a99763          	bne	s3,a0,ffffffffc02013c4 <default_check+0x5c2>
    free_page(p0);
ffffffffc020105a:	4585                	li	a1,1
ffffffffc020105c:	483000ef          	jal	ra,ffffffffc0201cde <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201060:	4509                	li	a0,2
ffffffffc0201062:	43f000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc0201066:	32aa1f63          	bne	s4,a0,ffffffffc02013a4 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020106a:	4589                	li	a1,2
ffffffffc020106c:	473000ef          	jal	ra,ffffffffc0201cde <free_pages>
    free_page(p2);
ffffffffc0201070:	4585                	li	a1,1
ffffffffc0201072:	8562                	mv	a0,s8
ffffffffc0201074:	46b000ef          	jal	ra,ffffffffc0201cde <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201078:	4515                	li	a0,5
ffffffffc020107a:	427000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc020107e:	89aa                	mv	s3,a0
ffffffffc0201080:	48050263          	beqz	a0,ffffffffc0201504 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201084:	4505                	li	a0,1
ffffffffc0201086:	41b000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
ffffffffc020108a:	2c051d63          	bnez	a0,ffffffffc0201364 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc020108e:	481c                	lw	a5,16(s0)
ffffffffc0201090:	2a079a63          	bnez	a5,ffffffffc0201344 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201094:	4595                	li	a1,5
ffffffffc0201096:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201098:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc020109c:	01643023          	sd	s6,0(s0)
ffffffffc02010a0:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02010a4:	43b000ef          	jal	ra,ffffffffc0201cde <free_pages>
    return listelm->next;
ffffffffc02010a8:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010aa:	00878963          	beq	a5,s0,ffffffffc02010bc <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02010ae:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010b2:	679c                	ld	a5,8(a5)
ffffffffc02010b4:	397d                	addiw	s2,s2,-1
ffffffffc02010b6:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010b8:	fe879be3          	bne	a5,s0,ffffffffc02010ae <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02010bc:	26091463          	bnez	s2,ffffffffc0201324 <default_check+0x522>
    assert(total == 0);
ffffffffc02010c0:	46049263          	bnez	s1,ffffffffc0201524 <default_check+0x722>
}
ffffffffc02010c4:	60a6                	ld	ra,72(sp)
ffffffffc02010c6:	6406                	ld	s0,64(sp)
ffffffffc02010c8:	74e2                	ld	s1,56(sp)
ffffffffc02010ca:	7942                	ld	s2,48(sp)
ffffffffc02010cc:	79a2                	ld	s3,40(sp)
ffffffffc02010ce:	7a02                	ld	s4,32(sp)
ffffffffc02010d0:	6ae2                	ld	s5,24(sp)
ffffffffc02010d2:	6b42                	ld	s6,16(sp)
ffffffffc02010d4:	6ba2                	ld	s7,8(sp)
ffffffffc02010d6:	6c02                	ld	s8,0(sp)
ffffffffc02010d8:	6161                	addi	sp,sp,80
ffffffffc02010da:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010dc:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02010de:	4481                	li	s1,0
ffffffffc02010e0:	4901                	li	s2,0
ffffffffc02010e2:	b38d                	j	ffffffffc0200e44 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02010e4:	00004697          	auipc	a3,0x4
ffffffffc02010e8:	8ac68693          	addi	a3,a3,-1876 # ffffffffc0204990 <commands+0x828>
ffffffffc02010ec:	00004617          	auipc	a2,0x4
ffffffffc02010f0:	8b460613          	addi	a2,a2,-1868 # ffffffffc02049a0 <commands+0x838>
ffffffffc02010f4:	0f000593          	li	a1,240
ffffffffc02010f8:	00004517          	auipc	a0,0x4
ffffffffc02010fc:	8c050513          	addi	a0,a0,-1856 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201100:	b5aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201104:	00004697          	auipc	a3,0x4
ffffffffc0201108:	94c68693          	addi	a3,a3,-1716 # ffffffffc0204a50 <commands+0x8e8>
ffffffffc020110c:	00004617          	auipc	a2,0x4
ffffffffc0201110:	89460613          	addi	a2,a2,-1900 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201114:	0bd00593          	li	a1,189
ffffffffc0201118:	00004517          	auipc	a0,0x4
ffffffffc020111c:	8a050513          	addi	a0,a0,-1888 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201120:	b3aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201124:	00004697          	auipc	a3,0x4
ffffffffc0201128:	95468693          	addi	a3,a3,-1708 # ffffffffc0204a78 <commands+0x910>
ffffffffc020112c:	00004617          	auipc	a2,0x4
ffffffffc0201130:	87460613          	addi	a2,a2,-1932 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201134:	0be00593          	li	a1,190
ffffffffc0201138:	00004517          	auipc	a0,0x4
ffffffffc020113c:	88050513          	addi	a0,a0,-1920 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201140:	b1aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201144:	00004697          	auipc	a3,0x4
ffffffffc0201148:	97468693          	addi	a3,a3,-1676 # ffffffffc0204ab8 <commands+0x950>
ffffffffc020114c:	00004617          	auipc	a2,0x4
ffffffffc0201150:	85460613          	addi	a2,a2,-1964 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201154:	0c000593          	li	a1,192
ffffffffc0201158:	00004517          	auipc	a0,0x4
ffffffffc020115c:	86050513          	addi	a0,a0,-1952 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201160:	afaff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201164:	00004697          	auipc	a3,0x4
ffffffffc0201168:	9dc68693          	addi	a3,a3,-1572 # ffffffffc0204b40 <commands+0x9d8>
ffffffffc020116c:	00004617          	auipc	a2,0x4
ffffffffc0201170:	83460613          	addi	a2,a2,-1996 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201174:	0d900593          	li	a1,217
ffffffffc0201178:	00004517          	auipc	a0,0x4
ffffffffc020117c:	84050513          	addi	a0,a0,-1984 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201180:	adaff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201184:	00004697          	auipc	a3,0x4
ffffffffc0201188:	86c68693          	addi	a3,a3,-1940 # ffffffffc02049f0 <commands+0x888>
ffffffffc020118c:	00004617          	auipc	a2,0x4
ffffffffc0201190:	81460613          	addi	a2,a2,-2028 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201194:	0d200593          	li	a1,210
ffffffffc0201198:	00004517          	auipc	a0,0x4
ffffffffc020119c:	82050513          	addi	a0,a0,-2016 # ffffffffc02049b8 <commands+0x850>
ffffffffc02011a0:	abaff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 3);
ffffffffc02011a4:	00004697          	auipc	a3,0x4
ffffffffc02011a8:	98c68693          	addi	a3,a3,-1652 # ffffffffc0204b30 <commands+0x9c8>
ffffffffc02011ac:	00003617          	auipc	a2,0x3
ffffffffc02011b0:	7f460613          	addi	a2,a2,2036 # ffffffffc02049a0 <commands+0x838>
ffffffffc02011b4:	0d000593          	li	a1,208
ffffffffc02011b8:	00004517          	auipc	a0,0x4
ffffffffc02011bc:	80050513          	addi	a0,a0,-2048 # ffffffffc02049b8 <commands+0x850>
ffffffffc02011c0:	a9aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011c4:	00004697          	auipc	a3,0x4
ffffffffc02011c8:	95468693          	addi	a3,a3,-1708 # ffffffffc0204b18 <commands+0x9b0>
ffffffffc02011cc:	00003617          	auipc	a2,0x3
ffffffffc02011d0:	7d460613          	addi	a2,a2,2004 # ffffffffc02049a0 <commands+0x838>
ffffffffc02011d4:	0cb00593          	li	a1,203
ffffffffc02011d8:	00003517          	auipc	a0,0x3
ffffffffc02011dc:	7e050513          	addi	a0,a0,2016 # ffffffffc02049b8 <commands+0x850>
ffffffffc02011e0:	a7aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02011e4:	00004697          	auipc	a3,0x4
ffffffffc02011e8:	91468693          	addi	a3,a3,-1772 # ffffffffc0204af8 <commands+0x990>
ffffffffc02011ec:	00003617          	auipc	a2,0x3
ffffffffc02011f0:	7b460613          	addi	a2,a2,1972 # ffffffffc02049a0 <commands+0x838>
ffffffffc02011f4:	0c200593          	li	a1,194
ffffffffc02011f8:	00003517          	auipc	a0,0x3
ffffffffc02011fc:	7c050513          	addi	a0,a0,1984 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201200:	a5aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != NULL);
ffffffffc0201204:	00004697          	auipc	a3,0x4
ffffffffc0201208:	98468693          	addi	a3,a3,-1660 # ffffffffc0204b88 <commands+0xa20>
ffffffffc020120c:	00003617          	auipc	a2,0x3
ffffffffc0201210:	79460613          	addi	a2,a2,1940 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201214:	0f800593          	li	a1,248
ffffffffc0201218:	00003517          	auipc	a0,0x3
ffffffffc020121c:	7a050513          	addi	a0,a0,1952 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201220:	a3aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc0201224:	00004697          	auipc	a3,0x4
ffffffffc0201228:	95468693          	addi	a3,a3,-1708 # ffffffffc0204b78 <commands+0xa10>
ffffffffc020122c:	00003617          	auipc	a2,0x3
ffffffffc0201230:	77460613          	addi	a2,a2,1908 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201234:	0df00593          	li	a1,223
ffffffffc0201238:	00003517          	auipc	a0,0x3
ffffffffc020123c:	78050513          	addi	a0,a0,1920 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201240:	a1aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201244:	00004697          	auipc	a3,0x4
ffffffffc0201248:	8d468693          	addi	a3,a3,-1836 # ffffffffc0204b18 <commands+0x9b0>
ffffffffc020124c:	00003617          	auipc	a2,0x3
ffffffffc0201250:	75460613          	addi	a2,a2,1876 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201254:	0dd00593          	li	a1,221
ffffffffc0201258:	00003517          	auipc	a0,0x3
ffffffffc020125c:	76050513          	addi	a0,a0,1888 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201260:	9faff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201264:	00004697          	auipc	a3,0x4
ffffffffc0201268:	8f468693          	addi	a3,a3,-1804 # ffffffffc0204b58 <commands+0x9f0>
ffffffffc020126c:	00003617          	auipc	a2,0x3
ffffffffc0201270:	73460613          	addi	a2,a2,1844 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201274:	0dc00593          	li	a1,220
ffffffffc0201278:	00003517          	auipc	a0,0x3
ffffffffc020127c:	74050513          	addi	a0,a0,1856 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201280:	9daff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201284:	00003697          	auipc	a3,0x3
ffffffffc0201288:	76c68693          	addi	a3,a3,1900 # ffffffffc02049f0 <commands+0x888>
ffffffffc020128c:	00003617          	auipc	a2,0x3
ffffffffc0201290:	71460613          	addi	a2,a2,1812 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201294:	0b900593          	li	a1,185
ffffffffc0201298:	00003517          	auipc	a0,0x3
ffffffffc020129c:	72050513          	addi	a0,a0,1824 # ffffffffc02049b8 <commands+0x850>
ffffffffc02012a0:	9baff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012a4:	00004697          	auipc	a3,0x4
ffffffffc02012a8:	87468693          	addi	a3,a3,-1932 # ffffffffc0204b18 <commands+0x9b0>
ffffffffc02012ac:	00003617          	auipc	a2,0x3
ffffffffc02012b0:	6f460613          	addi	a2,a2,1780 # ffffffffc02049a0 <commands+0x838>
ffffffffc02012b4:	0d600593          	li	a1,214
ffffffffc02012b8:	00003517          	auipc	a0,0x3
ffffffffc02012bc:	70050513          	addi	a0,a0,1792 # ffffffffc02049b8 <commands+0x850>
ffffffffc02012c0:	99aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02012c4:	00003697          	auipc	a3,0x3
ffffffffc02012c8:	76c68693          	addi	a3,a3,1900 # ffffffffc0204a30 <commands+0x8c8>
ffffffffc02012cc:	00003617          	auipc	a2,0x3
ffffffffc02012d0:	6d460613          	addi	a2,a2,1748 # ffffffffc02049a0 <commands+0x838>
ffffffffc02012d4:	0d400593          	li	a1,212
ffffffffc02012d8:	00003517          	auipc	a0,0x3
ffffffffc02012dc:	6e050513          	addi	a0,a0,1760 # ffffffffc02049b8 <commands+0x850>
ffffffffc02012e0:	97aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012e4:	00003697          	auipc	a3,0x3
ffffffffc02012e8:	72c68693          	addi	a3,a3,1836 # ffffffffc0204a10 <commands+0x8a8>
ffffffffc02012ec:	00003617          	auipc	a2,0x3
ffffffffc02012f0:	6b460613          	addi	a2,a2,1716 # ffffffffc02049a0 <commands+0x838>
ffffffffc02012f4:	0d300593          	li	a1,211
ffffffffc02012f8:	00003517          	auipc	a0,0x3
ffffffffc02012fc:	6c050513          	addi	a0,a0,1728 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201300:	95aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201304:	00003697          	auipc	a3,0x3
ffffffffc0201308:	72c68693          	addi	a3,a3,1836 # ffffffffc0204a30 <commands+0x8c8>
ffffffffc020130c:	00003617          	auipc	a2,0x3
ffffffffc0201310:	69460613          	addi	a2,a2,1684 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201314:	0bb00593          	li	a1,187
ffffffffc0201318:	00003517          	auipc	a0,0x3
ffffffffc020131c:	6a050513          	addi	a0,a0,1696 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201320:	93aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(count == 0);
ffffffffc0201324:	00004697          	auipc	a3,0x4
ffffffffc0201328:	9b468693          	addi	a3,a3,-1612 # ffffffffc0204cd8 <commands+0xb70>
ffffffffc020132c:	00003617          	auipc	a2,0x3
ffffffffc0201330:	67460613          	addi	a2,a2,1652 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201334:	12500593          	li	a1,293
ffffffffc0201338:	00003517          	auipc	a0,0x3
ffffffffc020133c:	68050513          	addi	a0,a0,1664 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201340:	91aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc0201344:	00004697          	auipc	a3,0x4
ffffffffc0201348:	83468693          	addi	a3,a3,-1996 # ffffffffc0204b78 <commands+0xa10>
ffffffffc020134c:	00003617          	auipc	a2,0x3
ffffffffc0201350:	65460613          	addi	a2,a2,1620 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201354:	11a00593          	li	a1,282
ffffffffc0201358:	00003517          	auipc	a0,0x3
ffffffffc020135c:	66050513          	addi	a0,a0,1632 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201360:	8faff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201364:	00003697          	auipc	a3,0x3
ffffffffc0201368:	7b468693          	addi	a3,a3,1972 # ffffffffc0204b18 <commands+0x9b0>
ffffffffc020136c:	00003617          	auipc	a2,0x3
ffffffffc0201370:	63460613          	addi	a2,a2,1588 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201374:	11800593          	li	a1,280
ffffffffc0201378:	00003517          	auipc	a0,0x3
ffffffffc020137c:	64050513          	addi	a0,a0,1600 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201380:	8daff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201384:	00003697          	auipc	a3,0x3
ffffffffc0201388:	75468693          	addi	a3,a3,1876 # ffffffffc0204ad8 <commands+0x970>
ffffffffc020138c:	00003617          	auipc	a2,0x3
ffffffffc0201390:	61460613          	addi	a2,a2,1556 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201394:	0c100593          	li	a1,193
ffffffffc0201398:	00003517          	auipc	a0,0x3
ffffffffc020139c:	62050513          	addi	a0,a0,1568 # ffffffffc02049b8 <commands+0x850>
ffffffffc02013a0:	8baff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02013a4:	00004697          	auipc	a3,0x4
ffffffffc02013a8:	8f468693          	addi	a3,a3,-1804 # ffffffffc0204c98 <commands+0xb30>
ffffffffc02013ac:	00003617          	auipc	a2,0x3
ffffffffc02013b0:	5f460613          	addi	a2,a2,1524 # ffffffffc02049a0 <commands+0x838>
ffffffffc02013b4:	11200593          	li	a1,274
ffffffffc02013b8:	00003517          	auipc	a0,0x3
ffffffffc02013bc:	60050513          	addi	a0,a0,1536 # ffffffffc02049b8 <commands+0x850>
ffffffffc02013c0:	89aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02013c4:	00004697          	auipc	a3,0x4
ffffffffc02013c8:	8b468693          	addi	a3,a3,-1868 # ffffffffc0204c78 <commands+0xb10>
ffffffffc02013cc:	00003617          	auipc	a2,0x3
ffffffffc02013d0:	5d460613          	addi	a2,a2,1492 # ffffffffc02049a0 <commands+0x838>
ffffffffc02013d4:	11000593          	li	a1,272
ffffffffc02013d8:	00003517          	auipc	a0,0x3
ffffffffc02013dc:	5e050513          	addi	a0,a0,1504 # ffffffffc02049b8 <commands+0x850>
ffffffffc02013e0:	87aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02013e4:	00004697          	auipc	a3,0x4
ffffffffc02013e8:	86c68693          	addi	a3,a3,-1940 # ffffffffc0204c50 <commands+0xae8>
ffffffffc02013ec:	00003617          	auipc	a2,0x3
ffffffffc02013f0:	5b460613          	addi	a2,a2,1460 # ffffffffc02049a0 <commands+0x838>
ffffffffc02013f4:	10e00593          	li	a1,270
ffffffffc02013f8:	00003517          	auipc	a0,0x3
ffffffffc02013fc:	5c050513          	addi	a0,a0,1472 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201400:	85aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201404:	00004697          	auipc	a3,0x4
ffffffffc0201408:	82468693          	addi	a3,a3,-2012 # ffffffffc0204c28 <commands+0xac0>
ffffffffc020140c:	00003617          	auipc	a2,0x3
ffffffffc0201410:	59460613          	addi	a2,a2,1428 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201414:	10d00593          	li	a1,269
ffffffffc0201418:	00003517          	auipc	a0,0x3
ffffffffc020141c:	5a050513          	addi	a0,a0,1440 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201420:	83aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201424:	00003697          	auipc	a3,0x3
ffffffffc0201428:	7f468693          	addi	a3,a3,2036 # ffffffffc0204c18 <commands+0xab0>
ffffffffc020142c:	00003617          	auipc	a2,0x3
ffffffffc0201430:	57460613          	addi	a2,a2,1396 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201434:	10800593          	li	a1,264
ffffffffc0201438:	00003517          	auipc	a0,0x3
ffffffffc020143c:	58050513          	addi	a0,a0,1408 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201440:	81aff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201444:	00003697          	auipc	a3,0x3
ffffffffc0201448:	6d468693          	addi	a3,a3,1748 # ffffffffc0204b18 <commands+0x9b0>
ffffffffc020144c:	00003617          	auipc	a2,0x3
ffffffffc0201450:	55460613          	addi	a2,a2,1364 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201454:	10700593          	li	a1,263
ffffffffc0201458:	00003517          	auipc	a0,0x3
ffffffffc020145c:	56050513          	addi	a0,a0,1376 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201460:	ffbfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201464:	00003697          	auipc	a3,0x3
ffffffffc0201468:	79468693          	addi	a3,a3,1940 # ffffffffc0204bf8 <commands+0xa90>
ffffffffc020146c:	00003617          	auipc	a2,0x3
ffffffffc0201470:	53460613          	addi	a2,a2,1332 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201474:	10600593          	li	a1,262
ffffffffc0201478:	00003517          	auipc	a0,0x3
ffffffffc020147c:	54050513          	addi	a0,a0,1344 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201480:	fdbfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201484:	00003697          	auipc	a3,0x3
ffffffffc0201488:	74468693          	addi	a3,a3,1860 # ffffffffc0204bc8 <commands+0xa60>
ffffffffc020148c:	00003617          	auipc	a2,0x3
ffffffffc0201490:	51460613          	addi	a2,a2,1300 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201494:	10500593          	li	a1,261
ffffffffc0201498:	00003517          	auipc	a0,0x3
ffffffffc020149c:	52050513          	addi	a0,a0,1312 # ffffffffc02049b8 <commands+0x850>
ffffffffc02014a0:	fbbfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02014a4:	00003697          	auipc	a3,0x3
ffffffffc02014a8:	70c68693          	addi	a3,a3,1804 # ffffffffc0204bb0 <commands+0xa48>
ffffffffc02014ac:	00003617          	auipc	a2,0x3
ffffffffc02014b0:	4f460613          	addi	a2,a2,1268 # ffffffffc02049a0 <commands+0x838>
ffffffffc02014b4:	10400593          	li	a1,260
ffffffffc02014b8:	00003517          	auipc	a0,0x3
ffffffffc02014bc:	50050513          	addi	a0,a0,1280 # ffffffffc02049b8 <commands+0x850>
ffffffffc02014c0:	f9bfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014c4:	00003697          	auipc	a3,0x3
ffffffffc02014c8:	65468693          	addi	a3,a3,1620 # ffffffffc0204b18 <commands+0x9b0>
ffffffffc02014cc:	00003617          	auipc	a2,0x3
ffffffffc02014d0:	4d460613          	addi	a2,a2,1236 # ffffffffc02049a0 <commands+0x838>
ffffffffc02014d4:	0fe00593          	li	a1,254
ffffffffc02014d8:	00003517          	auipc	a0,0x3
ffffffffc02014dc:	4e050513          	addi	a0,a0,1248 # ffffffffc02049b8 <commands+0x850>
ffffffffc02014e0:	f7bfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!PageProperty(p0));
ffffffffc02014e4:	00003697          	auipc	a3,0x3
ffffffffc02014e8:	6b468693          	addi	a3,a3,1716 # ffffffffc0204b98 <commands+0xa30>
ffffffffc02014ec:	00003617          	auipc	a2,0x3
ffffffffc02014f0:	4b460613          	addi	a2,a2,1204 # ffffffffc02049a0 <commands+0x838>
ffffffffc02014f4:	0f900593          	li	a1,249
ffffffffc02014f8:	00003517          	auipc	a0,0x3
ffffffffc02014fc:	4c050513          	addi	a0,a0,1216 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201500:	f5bfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201504:	00003697          	auipc	a3,0x3
ffffffffc0201508:	7b468693          	addi	a3,a3,1972 # ffffffffc0204cb8 <commands+0xb50>
ffffffffc020150c:	00003617          	auipc	a2,0x3
ffffffffc0201510:	49460613          	addi	a2,a2,1172 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201514:	11700593          	li	a1,279
ffffffffc0201518:	00003517          	auipc	a0,0x3
ffffffffc020151c:	4a050513          	addi	a0,a0,1184 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201520:	f3bfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == 0);
ffffffffc0201524:	00003697          	auipc	a3,0x3
ffffffffc0201528:	7c468693          	addi	a3,a3,1988 # ffffffffc0204ce8 <commands+0xb80>
ffffffffc020152c:	00003617          	auipc	a2,0x3
ffffffffc0201530:	47460613          	addi	a2,a2,1140 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201534:	12600593          	li	a1,294
ffffffffc0201538:	00003517          	auipc	a0,0x3
ffffffffc020153c:	48050513          	addi	a0,a0,1152 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201540:	f1bfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == nr_free_pages());
ffffffffc0201544:	00003697          	auipc	a3,0x3
ffffffffc0201548:	48c68693          	addi	a3,a3,1164 # ffffffffc02049d0 <commands+0x868>
ffffffffc020154c:	00003617          	auipc	a2,0x3
ffffffffc0201550:	45460613          	addi	a2,a2,1108 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201554:	0f300593          	li	a1,243
ffffffffc0201558:	00003517          	auipc	a0,0x3
ffffffffc020155c:	46050513          	addi	a0,a0,1120 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201560:	efbfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201564:	00003697          	auipc	a3,0x3
ffffffffc0201568:	4ac68693          	addi	a3,a3,1196 # ffffffffc0204a10 <commands+0x8a8>
ffffffffc020156c:	00003617          	auipc	a2,0x3
ffffffffc0201570:	43460613          	addi	a2,a2,1076 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201574:	0ba00593          	li	a1,186
ffffffffc0201578:	00003517          	auipc	a0,0x3
ffffffffc020157c:	44050513          	addi	a0,a0,1088 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201580:	edbfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201584 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201584:	1141                	addi	sp,sp,-16
ffffffffc0201586:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201588:	14058463          	beqz	a1,ffffffffc02016d0 <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc020158c:	00659693          	slli	a3,a1,0x6
ffffffffc0201590:	96aa                	add	a3,a3,a0
ffffffffc0201592:	87aa                	mv	a5,a0
ffffffffc0201594:	02d50263          	beq	a0,a3,ffffffffc02015b8 <default_free_pages+0x34>
ffffffffc0201598:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020159a:	8b05                	andi	a4,a4,1
ffffffffc020159c:	10071a63          	bnez	a4,ffffffffc02016b0 <default_free_pages+0x12c>
ffffffffc02015a0:	6798                	ld	a4,8(a5)
ffffffffc02015a2:	8b09                	andi	a4,a4,2
ffffffffc02015a4:	10071663          	bnez	a4,ffffffffc02016b0 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc02015a8:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02015ac:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015b0:	04078793          	addi	a5,a5,64
ffffffffc02015b4:	fed792e3          	bne	a5,a3,ffffffffc0201598 <default_free_pages+0x14>
    base->property = n;
ffffffffc02015b8:	2581                	sext.w	a1,a1
ffffffffc02015ba:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02015bc:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015c0:	4789                	li	a5,2
ffffffffc02015c2:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02015c6:	00008697          	auipc	a3,0x8
ffffffffc02015ca:	e6a68693          	addi	a3,a3,-406 # ffffffffc0209430 <free_area>
ffffffffc02015ce:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02015d0:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02015d2:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02015d6:	9db9                	addw	a1,a1,a4
ffffffffc02015d8:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02015da:	0ad78463          	beq	a5,a3,ffffffffc0201682 <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc02015de:	fe878713          	addi	a4,a5,-24
ffffffffc02015e2:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02015e6:	4581                	li	a1,0
            if (base < page) {
ffffffffc02015e8:	00e56a63          	bltu	a0,a4,ffffffffc02015fc <default_free_pages+0x78>
    return listelm->next;
ffffffffc02015ec:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02015ee:	04d70c63          	beq	a4,a3,ffffffffc0201646 <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc02015f2:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02015f4:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02015f8:	fee57ae3          	bgeu	a0,a4,ffffffffc02015ec <default_free_pages+0x68>
ffffffffc02015fc:	c199                	beqz	a1,ffffffffc0201602 <default_free_pages+0x7e>
ffffffffc02015fe:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201602:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201604:	e390                	sd	a2,0(a5)
ffffffffc0201606:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201608:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020160a:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc020160c:	00d70d63          	beq	a4,a3,ffffffffc0201626 <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0201610:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201614:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0201618:	02059813          	slli	a6,a1,0x20
ffffffffc020161c:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201620:	97b2                	add	a5,a5,a2
ffffffffc0201622:	02f50c63          	beq	a0,a5,ffffffffc020165a <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201626:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201628:	00d78c63          	beq	a5,a3,ffffffffc0201640 <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc020162c:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc020162e:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0201632:	02061593          	slli	a1,a2,0x20
ffffffffc0201636:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020163a:	972a                	add	a4,a4,a0
ffffffffc020163c:	04e68a63          	beq	a3,a4,ffffffffc0201690 <default_free_pages+0x10c>
}
ffffffffc0201640:	60a2                	ld	ra,8(sp)
ffffffffc0201642:	0141                	addi	sp,sp,16
ffffffffc0201644:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201646:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201648:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020164a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020164c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020164e:	02d70763          	beq	a4,a3,ffffffffc020167c <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201652:	8832                	mv	a6,a2
ffffffffc0201654:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201656:	87ba                	mv	a5,a4
ffffffffc0201658:	bf71                	j	ffffffffc02015f4 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020165a:	491c                	lw	a5,16(a0)
ffffffffc020165c:	9dbd                	addw	a1,a1,a5
ffffffffc020165e:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201662:	57f5                	li	a5,-3
ffffffffc0201664:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201668:	01853803          	ld	a6,24(a0)
ffffffffc020166c:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020166e:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201670:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201674:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201676:	0105b023          	sd	a6,0(a1)
ffffffffc020167a:	b77d                	j	ffffffffc0201628 <default_free_pages+0xa4>
ffffffffc020167c:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020167e:	873e                	mv	a4,a5
ffffffffc0201680:	bf41                	j	ffffffffc0201610 <default_free_pages+0x8c>
}
ffffffffc0201682:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201684:	e390                	sd	a2,0(a5)
ffffffffc0201686:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201688:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020168a:	ed1c                	sd	a5,24(a0)
ffffffffc020168c:	0141                	addi	sp,sp,16
ffffffffc020168e:	8082                	ret
            base->property += p->property;
ffffffffc0201690:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201694:	ff078693          	addi	a3,a5,-16
ffffffffc0201698:	9e39                	addw	a2,a2,a4
ffffffffc020169a:	c910                	sw	a2,16(a0)
ffffffffc020169c:	5775                	li	a4,-3
ffffffffc020169e:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02016a2:	6398                	ld	a4,0(a5)
ffffffffc02016a4:	679c                	ld	a5,8(a5)
}
ffffffffc02016a6:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02016a8:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02016aa:	e398                	sd	a4,0(a5)
ffffffffc02016ac:	0141                	addi	sp,sp,16
ffffffffc02016ae:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02016b0:	00003697          	auipc	a3,0x3
ffffffffc02016b4:	65068693          	addi	a3,a3,1616 # ffffffffc0204d00 <commands+0xb98>
ffffffffc02016b8:	00003617          	auipc	a2,0x3
ffffffffc02016bc:	2e860613          	addi	a2,a2,744 # ffffffffc02049a0 <commands+0x838>
ffffffffc02016c0:	08300593          	li	a1,131
ffffffffc02016c4:	00003517          	auipc	a0,0x3
ffffffffc02016c8:	2f450513          	addi	a0,a0,756 # ffffffffc02049b8 <commands+0x850>
ffffffffc02016cc:	d8ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc02016d0:	00003697          	auipc	a3,0x3
ffffffffc02016d4:	62868693          	addi	a3,a3,1576 # ffffffffc0204cf8 <commands+0xb90>
ffffffffc02016d8:	00003617          	auipc	a2,0x3
ffffffffc02016dc:	2c860613          	addi	a2,a2,712 # ffffffffc02049a0 <commands+0x838>
ffffffffc02016e0:	08000593          	li	a1,128
ffffffffc02016e4:	00003517          	auipc	a0,0x3
ffffffffc02016e8:	2d450513          	addi	a0,a0,724 # ffffffffc02049b8 <commands+0x850>
ffffffffc02016ec:	d6ffe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02016f0 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02016f0:	c941                	beqz	a0,ffffffffc0201780 <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc02016f2:	00008597          	auipc	a1,0x8
ffffffffc02016f6:	d3e58593          	addi	a1,a1,-706 # ffffffffc0209430 <free_area>
ffffffffc02016fa:	0105a803          	lw	a6,16(a1)
ffffffffc02016fe:	872a                	mv	a4,a0
ffffffffc0201700:	02081793          	slli	a5,a6,0x20
ffffffffc0201704:	9381                	srli	a5,a5,0x20
ffffffffc0201706:	00a7ee63          	bltu	a5,a0,ffffffffc0201722 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020170a:	87ae                	mv	a5,a1
ffffffffc020170c:	a801                	j	ffffffffc020171c <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc020170e:	ff87a683          	lw	a3,-8(a5)
ffffffffc0201712:	02069613          	slli	a2,a3,0x20
ffffffffc0201716:	9201                	srli	a2,a2,0x20
ffffffffc0201718:	00e67763          	bgeu	a2,a4,ffffffffc0201726 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc020171c:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020171e:	feb798e3          	bne	a5,a1,ffffffffc020170e <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201722:	4501                	li	a0,0
}
ffffffffc0201724:	8082                	ret
    return listelm->prev;
ffffffffc0201726:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020172a:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc020172e:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201732:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0201736:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020173a:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc020173e:	02c77863          	bgeu	a4,a2,ffffffffc020176e <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201742:	071a                	slli	a4,a4,0x6
ffffffffc0201744:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201746:	41c686bb          	subw	a3,a3,t3
ffffffffc020174a:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020174c:	00870613          	addi	a2,a4,8
ffffffffc0201750:	4689                	li	a3,2
ffffffffc0201752:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201756:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020175a:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc020175e:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201762:	e290                	sd	a2,0(a3)
ffffffffc0201764:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201768:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc020176a:	01173c23          	sd	a7,24(a4)
ffffffffc020176e:	41c8083b          	subw	a6,a6,t3
ffffffffc0201772:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201776:	5775                	li	a4,-3
ffffffffc0201778:	17c1                	addi	a5,a5,-16
ffffffffc020177a:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020177e:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201780:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201782:	00003697          	auipc	a3,0x3
ffffffffc0201786:	57668693          	addi	a3,a3,1398 # ffffffffc0204cf8 <commands+0xb90>
ffffffffc020178a:	00003617          	auipc	a2,0x3
ffffffffc020178e:	21660613          	addi	a2,a2,534 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201792:	06200593          	li	a1,98
ffffffffc0201796:	00003517          	auipc	a0,0x3
ffffffffc020179a:	22250513          	addi	a0,a0,546 # ffffffffc02049b8 <commands+0x850>
default_alloc_pages(size_t n) {
ffffffffc020179e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017a0:	cbbfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02017a4 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02017a4:	1141                	addi	sp,sp,-16
ffffffffc02017a6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017a8:	c5f1                	beqz	a1,ffffffffc0201874 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc02017aa:	00659693          	slli	a3,a1,0x6
ffffffffc02017ae:	96aa                	add	a3,a3,a0
ffffffffc02017b0:	87aa                	mv	a5,a0
ffffffffc02017b2:	00d50f63          	beq	a0,a3,ffffffffc02017d0 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02017b6:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02017b8:	8b05                	andi	a4,a4,1
ffffffffc02017ba:	cf49                	beqz	a4,ffffffffc0201854 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02017bc:	0007a823          	sw	zero,16(a5)
ffffffffc02017c0:	0007b423          	sd	zero,8(a5)
ffffffffc02017c4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02017c8:	04078793          	addi	a5,a5,64
ffffffffc02017cc:	fed795e3          	bne	a5,a3,ffffffffc02017b6 <default_init_memmap+0x12>
    base->property = n;
ffffffffc02017d0:	2581                	sext.w	a1,a1
ffffffffc02017d2:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017d4:	4789                	li	a5,2
ffffffffc02017d6:	00850713          	addi	a4,a0,8
ffffffffc02017da:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02017de:	00008697          	auipc	a3,0x8
ffffffffc02017e2:	c5268693          	addi	a3,a3,-942 # ffffffffc0209430 <free_area>
ffffffffc02017e6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02017e8:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02017ea:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02017ee:	9db9                	addw	a1,a1,a4
ffffffffc02017f0:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02017f2:	04d78a63          	beq	a5,a3,ffffffffc0201846 <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc02017f6:	fe878713          	addi	a4,a5,-24
ffffffffc02017fa:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02017fe:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201800:	00e56a63          	bltu	a0,a4,ffffffffc0201814 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201804:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201806:	02d70263          	beq	a4,a3,ffffffffc020182a <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc020180a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020180c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201810:	fee57ae3          	bgeu	a0,a4,ffffffffc0201804 <default_init_memmap+0x60>
ffffffffc0201814:	c199                	beqz	a1,ffffffffc020181a <default_init_memmap+0x76>
ffffffffc0201816:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020181a:	6398                	ld	a4,0(a5)
}
ffffffffc020181c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020181e:	e390                	sd	a2,0(a5)
ffffffffc0201820:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201822:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201824:	ed18                	sd	a4,24(a0)
ffffffffc0201826:	0141                	addi	sp,sp,16
ffffffffc0201828:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020182a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020182c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020182e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201830:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201832:	00d70663          	beq	a4,a3,ffffffffc020183e <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201836:	8832                	mv	a6,a2
ffffffffc0201838:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020183a:	87ba                	mv	a5,a4
ffffffffc020183c:	bfc1                	j	ffffffffc020180c <default_init_memmap+0x68>
}
ffffffffc020183e:	60a2                	ld	ra,8(sp)
ffffffffc0201840:	e290                	sd	a2,0(a3)
ffffffffc0201842:	0141                	addi	sp,sp,16
ffffffffc0201844:	8082                	ret
ffffffffc0201846:	60a2                	ld	ra,8(sp)
ffffffffc0201848:	e390                	sd	a2,0(a5)
ffffffffc020184a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020184c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020184e:	ed1c                	sd	a5,24(a0)
ffffffffc0201850:	0141                	addi	sp,sp,16
ffffffffc0201852:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201854:	00003697          	auipc	a3,0x3
ffffffffc0201858:	4d468693          	addi	a3,a3,1236 # ffffffffc0204d28 <commands+0xbc0>
ffffffffc020185c:	00003617          	auipc	a2,0x3
ffffffffc0201860:	14460613          	addi	a2,a2,324 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201864:	04900593          	li	a1,73
ffffffffc0201868:	00003517          	auipc	a0,0x3
ffffffffc020186c:	15050513          	addi	a0,a0,336 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201870:	bebfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc0201874:	00003697          	auipc	a3,0x3
ffffffffc0201878:	48468693          	addi	a3,a3,1156 # ffffffffc0204cf8 <commands+0xb90>
ffffffffc020187c:	00003617          	auipc	a2,0x3
ffffffffc0201880:	12460613          	addi	a2,a2,292 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201884:	04600593          	li	a1,70
ffffffffc0201888:	00003517          	auipc	a0,0x3
ffffffffc020188c:	13050513          	addi	a0,a0,304 # ffffffffc02049b8 <commands+0x850>
ffffffffc0201890:	bcbfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201894 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201894:	c94d                	beqz	a0,ffffffffc0201946 <slob_free+0xb2>
{
ffffffffc0201896:	1141                	addi	sp,sp,-16
ffffffffc0201898:	e022                	sd	s0,0(sp)
ffffffffc020189a:	e406                	sd	ra,8(sp)
ffffffffc020189c:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc020189e:	e9c1                	bnez	a1,ffffffffc020192e <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018a0:	100027f3          	csrr	a5,sstatus
ffffffffc02018a4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02018a6:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018a8:	ebd9                	bnez	a5,ffffffffc020193e <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018aa:	00007617          	auipc	a2,0x7
ffffffffc02018ae:	77660613          	addi	a2,a2,1910 # ffffffffc0209020 <slobfree>
ffffffffc02018b2:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018b4:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018b6:	679c                	ld	a5,8(a5)
ffffffffc02018b8:	02877a63          	bgeu	a4,s0,ffffffffc02018ec <slob_free+0x58>
ffffffffc02018bc:	00f46463          	bltu	s0,a5,ffffffffc02018c4 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018c0:	fef76ae3          	bltu	a4,a5,ffffffffc02018b4 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc02018c4:	400c                	lw	a1,0(s0)
ffffffffc02018c6:	00459693          	slli	a3,a1,0x4
ffffffffc02018ca:	96a2                	add	a3,a3,s0
ffffffffc02018cc:	02d78a63          	beq	a5,a3,ffffffffc0201900 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02018d0:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc02018d2:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02018d4:	00469793          	slli	a5,a3,0x4
ffffffffc02018d8:	97ba                	add	a5,a5,a4
ffffffffc02018da:	02f40e63          	beq	s0,a5,ffffffffc0201916 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc02018de:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc02018e0:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc02018e2:	e129                	bnez	a0,ffffffffc0201924 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02018e4:	60a2                	ld	ra,8(sp)
ffffffffc02018e6:	6402                	ld	s0,0(sp)
ffffffffc02018e8:	0141                	addi	sp,sp,16
ffffffffc02018ea:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018ec:	fcf764e3          	bltu	a4,a5,ffffffffc02018b4 <slob_free+0x20>
ffffffffc02018f0:	fcf472e3          	bgeu	s0,a5,ffffffffc02018b4 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc02018f4:	400c                	lw	a1,0(s0)
ffffffffc02018f6:	00459693          	slli	a3,a1,0x4
ffffffffc02018fa:	96a2                	add	a3,a3,s0
ffffffffc02018fc:	fcd79ae3          	bne	a5,a3,ffffffffc02018d0 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201900:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201902:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201904:	9db5                	addw	a1,a1,a3
ffffffffc0201906:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201908:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc020190a:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc020190c:	00469793          	slli	a5,a3,0x4
ffffffffc0201910:	97ba                	add	a5,a5,a4
ffffffffc0201912:	fcf416e3          	bne	s0,a5,ffffffffc02018de <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201916:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201918:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc020191a:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc020191c:	9ebd                	addw	a3,a3,a5
ffffffffc020191e:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201920:	e70c                	sd	a1,8(a4)
ffffffffc0201922:	d169                	beqz	a0,ffffffffc02018e4 <slob_free+0x50>
}
ffffffffc0201924:	6402                	ld	s0,0(sp)
ffffffffc0201926:	60a2                	ld	ra,8(sp)
ffffffffc0201928:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020192a:	800ff06f          	j	ffffffffc020092a <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc020192e:	25bd                	addiw	a1,a1,15
ffffffffc0201930:	8191                	srli	a1,a1,0x4
ffffffffc0201932:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201934:	100027f3          	csrr	a5,sstatus
ffffffffc0201938:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020193a:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020193c:	d7bd                	beqz	a5,ffffffffc02018aa <slob_free+0x16>
        intr_disable();
ffffffffc020193e:	ff3fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0201942:	4505                	li	a0,1
ffffffffc0201944:	b79d                	j	ffffffffc02018aa <slob_free+0x16>
ffffffffc0201946:	8082                	ret

ffffffffc0201948 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201948:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020194a:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc020194c:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201950:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201952:	34e000ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
	if (!page)
ffffffffc0201956:	c91d                	beqz	a0,ffffffffc020198c <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201958:	0000c697          	auipc	a3,0xc
ffffffffc020195c:	b606b683          	ld	a3,-1184(a3) # ffffffffc020d4b8 <pages>
ffffffffc0201960:	8d15                	sub	a0,a0,a3
ffffffffc0201962:	8519                	srai	a0,a0,0x6
ffffffffc0201964:	00004697          	auipc	a3,0x4
ffffffffc0201968:	0ac6b683          	ld	a3,172(a3) # ffffffffc0205a10 <nbase>
ffffffffc020196c:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc020196e:	00c51793          	slli	a5,a0,0xc
ffffffffc0201972:	83b1                	srli	a5,a5,0xc
ffffffffc0201974:	0000c717          	auipc	a4,0xc
ffffffffc0201978:	b3c73703          	ld	a4,-1220(a4) # ffffffffc020d4b0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc020197c:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc020197e:	00e7fa63          	bgeu	a5,a4,ffffffffc0201992 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201982:	0000c697          	auipc	a3,0xc
ffffffffc0201986:	b466b683          	ld	a3,-1210(a3) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc020198a:	9536                	add	a0,a0,a3
}
ffffffffc020198c:	60a2                	ld	ra,8(sp)
ffffffffc020198e:	0141                	addi	sp,sp,16
ffffffffc0201990:	8082                	ret
ffffffffc0201992:	86aa                	mv	a3,a0
ffffffffc0201994:	00003617          	auipc	a2,0x3
ffffffffc0201998:	3f460613          	addi	a2,a2,1012 # ffffffffc0204d88 <default_pmm_manager+0x38>
ffffffffc020199c:	07100593          	li	a1,113
ffffffffc02019a0:	00003517          	auipc	a0,0x3
ffffffffc02019a4:	41050513          	addi	a0,a0,1040 # ffffffffc0204db0 <default_pmm_manager+0x60>
ffffffffc02019a8:	ab3fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02019ac <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc02019ac:	1101                	addi	sp,sp,-32
ffffffffc02019ae:	ec06                	sd	ra,24(sp)
ffffffffc02019b0:	e822                	sd	s0,16(sp)
ffffffffc02019b2:	e426                	sd	s1,8(sp)
ffffffffc02019b4:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc02019b6:	01050713          	addi	a4,a0,16
ffffffffc02019ba:	6785                	lui	a5,0x1
ffffffffc02019bc:	0cf77363          	bgeu	a4,a5,ffffffffc0201a82 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02019c0:	00f50493          	addi	s1,a0,15
ffffffffc02019c4:	8091                	srli	s1,s1,0x4
ffffffffc02019c6:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019c8:	10002673          	csrr	a2,sstatus
ffffffffc02019cc:	8a09                	andi	a2,a2,2
ffffffffc02019ce:	e25d                	bnez	a2,ffffffffc0201a74 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc02019d0:	00007917          	auipc	s2,0x7
ffffffffc02019d4:	65090913          	addi	s2,s2,1616 # ffffffffc0209020 <slobfree>
ffffffffc02019d8:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019dc:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc02019de:	4398                	lw	a4,0(a5)
ffffffffc02019e0:	08975e63          	bge	a4,s1,ffffffffc0201a7c <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc02019e4:	00d78b63          	beq	a5,a3,ffffffffc02019fa <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019e8:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc02019ea:	4018                	lw	a4,0(s0)
ffffffffc02019ec:	02975a63          	bge	a4,s1,ffffffffc0201a20 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc02019f0:	00093683          	ld	a3,0(s2)
ffffffffc02019f4:	87a2                	mv	a5,s0
ffffffffc02019f6:	fed799e3          	bne	a5,a3,ffffffffc02019e8 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc02019fa:	ee31                	bnez	a2,ffffffffc0201a56 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02019fc:	4501                	li	a0,0
ffffffffc02019fe:	f4bff0ef          	jal	ra,ffffffffc0201948 <__slob_get_free_pages.constprop.0>
ffffffffc0201a02:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201a04:	cd05                	beqz	a0,ffffffffc0201a3c <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201a06:	6585                	lui	a1,0x1
ffffffffc0201a08:	e8dff0ef          	jal	ra,ffffffffc0201894 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a0c:	10002673          	csrr	a2,sstatus
ffffffffc0201a10:	8a09                	andi	a2,a2,2
ffffffffc0201a12:	ee05                	bnez	a2,ffffffffc0201a4a <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201a14:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201a18:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201a1a:	4018                	lw	a4,0(s0)
ffffffffc0201a1c:	fc974ae3          	blt	a4,s1,ffffffffc02019f0 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201a20:	04e48763          	beq	s1,a4,ffffffffc0201a6e <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201a24:	00449693          	slli	a3,s1,0x4
ffffffffc0201a28:	96a2                	add	a3,a3,s0
ffffffffc0201a2a:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201a2c:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201a2e:	9f05                	subw	a4,a4,s1
ffffffffc0201a30:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201a32:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201a34:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201a36:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0201a3a:	e20d                	bnez	a2,ffffffffc0201a5c <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201a3c:	60e2                	ld	ra,24(sp)
ffffffffc0201a3e:	8522                	mv	a0,s0
ffffffffc0201a40:	6442                	ld	s0,16(sp)
ffffffffc0201a42:	64a2                	ld	s1,8(sp)
ffffffffc0201a44:	6902                	ld	s2,0(sp)
ffffffffc0201a46:	6105                	addi	sp,sp,32
ffffffffc0201a48:	8082                	ret
        intr_disable();
ffffffffc0201a4a:	ee7fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
			cur = slobfree;
ffffffffc0201a4e:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201a52:	4605                	li	a2,1
ffffffffc0201a54:	b7d1                	j	ffffffffc0201a18 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201a56:	ed5fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201a5a:	b74d                	j	ffffffffc02019fc <slob_alloc.constprop.0+0x50>
ffffffffc0201a5c:	ecffe0ef          	jal	ra,ffffffffc020092a <intr_enable>
}
ffffffffc0201a60:	60e2                	ld	ra,24(sp)
ffffffffc0201a62:	8522                	mv	a0,s0
ffffffffc0201a64:	6442                	ld	s0,16(sp)
ffffffffc0201a66:	64a2                	ld	s1,8(sp)
ffffffffc0201a68:	6902                	ld	s2,0(sp)
ffffffffc0201a6a:	6105                	addi	sp,sp,32
ffffffffc0201a6c:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201a6e:	6418                	ld	a4,8(s0)
ffffffffc0201a70:	e798                	sd	a4,8(a5)
ffffffffc0201a72:	b7d1                	j	ffffffffc0201a36 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201a74:	ebdfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0201a78:	4605                	li	a2,1
ffffffffc0201a7a:	bf99                	j	ffffffffc02019d0 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201a7c:	843e                	mv	s0,a5
ffffffffc0201a7e:	87b6                	mv	a5,a3
ffffffffc0201a80:	b745                	j	ffffffffc0201a20 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a82:	00003697          	auipc	a3,0x3
ffffffffc0201a86:	33e68693          	addi	a3,a3,830 # ffffffffc0204dc0 <default_pmm_manager+0x70>
ffffffffc0201a8a:	00003617          	auipc	a2,0x3
ffffffffc0201a8e:	f1660613          	addi	a2,a2,-234 # ffffffffc02049a0 <commands+0x838>
ffffffffc0201a92:	06300593          	li	a1,99
ffffffffc0201a96:	00003517          	auipc	a0,0x3
ffffffffc0201a9a:	34a50513          	addi	a0,a0,842 # ffffffffc0204de0 <default_pmm_manager+0x90>
ffffffffc0201a9e:	9bdfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201aa2 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201aa2:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201aa4:	00003517          	auipc	a0,0x3
ffffffffc0201aa8:	35450513          	addi	a0,a0,852 # ffffffffc0204df8 <default_pmm_manager+0xa8>
{
ffffffffc0201aac:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201aae:	ee6fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201ab2:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ab4:	00003517          	auipc	a0,0x3
ffffffffc0201ab8:	35c50513          	addi	a0,a0,860 # ffffffffc0204e10 <default_pmm_manager+0xc0>
}
ffffffffc0201abc:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201abe:	ed6fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201ac2 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201ac2:	1101                	addi	sp,sp,-32
ffffffffc0201ac4:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ac6:	6905                	lui	s2,0x1
{
ffffffffc0201ac8:	e822                	sd	s0,16(sp)
ffffffffc0201aca:	ec06                	sd	ra,24(sp)
ffffffffc0201acc:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ace:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc0201ad2:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ad4:	04a7f963          	bgeu	a5,a0,ffffffffc0201b26 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201ad8:	4561                	li	a0,24
ffffffffc0201ada:	ed3ff0ef          	jal	ra,ffffffffc02019ac <slob_alloc.constprop.0>
ffffffffc0201ade:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201ae0:	c929                	beqz	a0,ffffffffc0201b32 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201ae2:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201ae6:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201ae8:	00f95763          	bge	s2,a5,ffffffffc0201af6 <kmalloc+0x34>
ffffffffc0201aec:	6705                	lui	a4,0x1
ffffffffc0201aee:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201af0:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201af2:	fef74ee3          	blt	a4,a5,ffffffffc0201aee <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201af6:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201af8:	e51ff0ef          	jal	ra,ffffffffc0201948 <__slob_get_free_pages.constprop.0>
ffffffffc0201afc:	e488                	sd	a0,8(s1)
ffffffffc0201afe:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201b00:	c525                	beqz	a0,ffffffffc0201b68 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b02:	100027f3          	csrr	a5,sstatus
ffffffffc0201b06:	8b89                	andi	a5,a5,2
ffffffffc0201b08:	ef8d                	bnez	a5,ffffffffc0201b42 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201b0a:	0000c797          	auipc	a5,0xc
ffffffffc0201b0e:	98e78793          	addi	a5,a5,-1650 # ffffffffc020d498 <bigblocks>
ffffffffc0201b12:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b14:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b16:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201b18:	60e2                	ld	ra,24(sp)
ffffffffc0201b1a:	8522                	mv	a0,s0
ffffffffc0201b1c:	6442                	ld	s0,16(sp)
ffffffffc0201b1e:	64a2                	ld	s1,8(sp)
ffffffffc0201b20:	6902                	ld	s2,0(sp)
ffffffffc0201b22:	6105                	addi	sp,sp,32
ffffffffc0201b24:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201b26:	0541                	addi	a0,a0,16
ffffffffc0201b28:	e85ff0ef          	jal	ra,ffffffffc02019ac <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201b2c:	01050413          	addi	s0,a0,16
ffffffffc0201b30:	f565                	bnez	a0,ffffffffc0201b18 <kmalloc+0x56>
ffffffffc0201b32:	4401                	li	s0,0
}
ffffffffc0201b34:	60e2                	ld	ra,24(sp)
ffffffffc0201b36:	8522                	mv	a0,s0
ffffffffc0201b38:	6442                	ld	s0,16(sp)
ffffffffc0201b3a:	64a2                	ld	s1,8(sp)
ffffffffc0201b3c:	6902                	ld	s2,0(sp)
ffffffffc0201b3e:	6105                	addi	sp,sp,32
ffffffffc0201b40:	8082                	ret
        intr_disable();
ffffffffc0201b42:	deffe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201b46:	0000c797          	auipc	a5,0xc
ffffffffc0201b4a:	95278793          	addi	a5,a5,-1710 # ffffffffc020d498 <bigblocks>
ffffffffc0201b4e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b50:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b52:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201b54:	dd7fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
		return bb->pages;
ffffffffc0201b58:	6480                	ld	s0,8(s1)
}
ffffffffc0201b5a:	60e2                	ld	ra,24(sp)
ffffffffc0201b5c:	64a2                	ld	s1,8(sp)
ffffffffc0201b5e:	8522                	mv	a0,s0
ffffffffc0201b60:	6442                	ld	s0,16(sp)
ffffffffc0201b62:	6902                	ld	s2,0(sp)
ffffffffc0201b64:	6105                	addi	sp,sp,32
ffffffffc0201b66:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b68:	45e1                	li	a1,24
ffffffffc0201b6a:	8526                	mv	a0,s1
ffffffffc0201b6c:	d29ff0ef          	jal	ra,ffffffffc0201894 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201b70:	b765                	j	ffffffffc0201b18 <kmalloc+0x56>

ffffffffc0201b72 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201b72:	c169                	beqz	a0,ffffffffc0201c34 <kfree+0xc2>
{
ffffffffc0201b74:	1101                	addi	sp,sp,-32
ffffffffc0201b76:	e822                	sd	s0,16(sp)
ffffffffc0201b78:	ec06                	sd	ra,24(sp)
ffffffffc0201b7a:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201b7c:	03451793          	slli	a5,a0,0x34
ffffffffc0201b80:	842a                	mv	s0,a0
ffffffffc0201b82:	e3d9                	bnez	a5,ffffffffc0201c08 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b84:	100027f3          	csrr	a5,sstatus
ffffffffc0201b88:	8b89                	andi	a5,a5,2
ffffffffc0201b8a:	e7d9                	bnez	a5,ffffffffc0201c18 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b8c:	0000c797          	auipc	a5,0xc
ffffffffc0201b90:	90c7b783          	ld	a5,-1780(a5) # ffffffffc020d498 <bigblocks>
    return 0;
ffffffffc0201b94:	4601                	li	a2,0
ffffffffc0201b96:	cbad                	beqz	a5,ffffffffc0201c08 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b98:	0000c697          	auipc	a3,0xc
ffffffffc0201b9c:	90068693          	addi	a3,a3,-1792 # ffffffffc020d498 <bigblocks>
ffffffffc0201ba0:	a021                	j	ffffffffc0201ba8 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201ba2:	01048693          	addi	a3,s1,16
ffffffffc0201ba6:	c3a5                	beqz	a5,ffffffffc0201c06 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201ba8:	6798                	ld	a4,8(a5)
ffffffffc0201baa:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201bac:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201bae:	fe871ae3          	bne	a4,s0,ffffffffc0201ba2 <kfree+0x30>
				*last = bb->next;
ffffffffc0201bb2:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201bb4:	ee2d                	bnez	a2,ffffffffc0201c2e <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201bb6:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201bba:	4098                	lw	a4,0(s1)
ffffffffc0201bbc:	08f46963          	bltu	s0,a5,ffffffffc0201c4e <kfree+0xdc>
ffffffffc0201bc0:	0000c697          	auipc	a3,0xc
ffffffffc0201bc4:	9086b683          	ld	a3,-1784(a3) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201bc8:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201bca:	8031                	srli	s0,s0,0xc
ffffffffc0201bcc:	0000c797          	auipc	a5,0xc
ffffffffc0201bd0:	8e47b783          	ld	a5,-1820(a5) # ffffffffc020d4b0 <npage>
ffffffffc0201bd4:	06f47163          	bgeu	s0,a5,ffffffffc0201c36 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201bd8:	00004517          	auipc	a0,0x4
ffffffffc0201bdc:	e3853503          	ld	a0,-456(a0) # ffffffffc0205a10 <nbase>
ffffffffc0201be0:	8c09                	sub	s0,s0,a0
ffffffffc0201be2:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201be4:	0000c517          	auipc	a0,0xc
ffffffffc0201be8:	8d453503          	ld	a0,-1836(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201bec:	4585                	li	a1,1
ffffffffc0201bee:	9522                	add	a0,a0,s0
ffffffffc0201bf0:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201bf4:	0ea000ef          	jal	ra,ffffffffc0201cde <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201bf8:	6442                	ld	s0,16(sp)
ffffffffc0201bfa:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bfc:	8526                	mv	a0,s1
}
ffffffffc0201bfe:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c00:	45e1                	li	a1,24
}
ffffffffc0201c02:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c04:	b941                	j	ffffffffc0201894 <slob_free>
ffffffffc0201c06:	e20d                	bnez	a2,ffffffffc0201c28 <kfree+0xb6>
ffffffffc0201c08:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201c0c:	6442                	ld	s0,16(sp)
ffffffffc0201c0e:	60e2                	ld	ra,24(sp)
ffffffffc0201c10:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c12:	4581                	li	a1,0
}
ffffffffc0201c14:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c16:	b9bd                	j	ffffffffc0201894 <slob_free>
        intr_disable();
ffffffffc0201c18:	d19fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201c1c:	0000c797          	auipc	a5,0xc
ffffffffc0201c20:	87c7b783          	ld	a5,-1924(a5) # ffffffffc020d498 <bigblocks>
        return 1;
ffffffffc0201c24:	4605                	li	a2,1
ffffffffc0201c26:	fbad                	bnez	a5,ffffffffc0201b98 <kfree+0x26>
        intr_enable();
ffffffffc0201c28:	d03fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201c2c:	bff1                	j	ffffffffc0201c08 <kfree+0x96>
ffffffffc0201c2e:	cfdfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201c32:	b751                	j	ffffffffc0201bb6 <kfree+0x44>
ffffffffc0201c34:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201c36:	00003617          	auipc	a2,0x3
ffffffffc0201c3a:	22260613          	addi	a2,a2,546 # ffffffffc0204e58 <default_pmm_manager+0x108>
ffffffffc0201c3e:	06900593          	li	a1,105
ffffffffc0201c42:	00003517          	auipc	a0,0x3
ffffffffc0201c46:	16e50513          	addi	a0,a0,366 # ffffffffc0204db0 <default_pmm_manager+0x60>
ffffffffc0201c4a:	811fe0ef          	jal	ra,ffffffffc020045a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201c4e:	86a2                	mv	a3,s0
ffffffffc0201c50:	00003617          	auipc	a2,0x3
ffffffffc0201c54:	1e060613          	addi	a2,a2,480 # ffffffffc0204e30 <default_pmm_manager+0xe0>
ffffffffc0201c58:	07700593          	li	a1,119
ffffffffc0201c5c:	00003517          	auipc	a0,0x3
ffffffffc0201c60:	15450513          	addi	a0,a0,340 # ffffffffc0204db0 <default_pmm_manager+0x60>
ffffffffc0201c64:	ff6fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c68 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201c68:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201c6a:	00003617          	auipc	a2,0x3
ffffffffc0201c6e:	1ee60613          	addi	a2,a2,494 # ffffffffc0204e58 <default_pmm_manager+0x108>
ffffffffc0201c72:	06900593          	li	a1,105
ffffffffc0201c76:	00003517          	auipc	a0,0x3
ffffffffc0201c7a:	13a50513          	addi	a0,a0,314 # ffffffffc0204db0 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201c7e:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201c80:	fdafe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c84 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201c84:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201c86:	00003617          	auipc	a2,0x3
ffffffffc0201c8a:	1f260613          	addi	a2,a2,498 # ffffffffc0204e78 <default_pmm_manager+0x128>
ffffffffc0201c8e:	07f00593          	li	a1,127
ffffffffc0201c92:	00003517          	auipc	a0,0x3
ffffffffc0201c96:	11e50513          	addi	a0,a0,286 # ffffffffc0204db0 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201c9a:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201c9c:	fbefe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201ca0 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ca0:	100027f3          	csrr	a5,sstatus
ffffffffc0201ca4:	8b89                	andi	a5,a5,2
ffffffffc0201ca6:	e799                	bnez	a5,ffffffffc0201cb4 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ca8:	0000c797          	auipc	a5,0xc
ffffffffc0201cac:	8187b783          	ld	a5,-2024(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cb0:	6f9c                	ld	a5,24(a5)
ffffffffc0201cb2:	8782                	jr	a5
{
ffffffffc0201cb4:	1141                	addi	sp,sp,-16
ffffffffc0201cb6:	e406                	sd	ra,8(sp)
ffffffffc0201cb8:	e022                	sd	s0,0(sp)
ffffffffc0201cba:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201cbc:	c75fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201cc0:	0000c797          	auipc	a5,0xc
ffffffffc0201cc4:	8007b783          	ld	a5,-2048(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cc8:	6f9c                	ld	a5,24(a5)
ffffffffc0201cca:	8522                	mv	a0,s0
ffffffffc0201ccc:	9782                	jalr	a5
ffffffffc0201cce:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201cd0:	c5bfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201cd4:	60a2                	ld	ra,8(sp)
ffffffffc0201cd6:	8522                	mv	a0,s0
ffffffffc0201cd8:	6402                	ld	s0,0(sp)
ffffffffc0201cda:	0141                	addi	sp,sp,16
ffffffffc0201cdc:	8082                	ret

ffffffffc0201cde <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201cde:	100027f3          	csrr	a5,sstatus
ffffffffc0201ce2:	8b89                	andi	a5,a5,2
ffffffffc0201ce4:	e799                	bnez	a5,ffffffffc0201cf2 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ce6:	0000b797          	auipc	a5,0xb
ffffffffc0201cea:	7da7b783          	ld	a5,2010(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cee:	739c                	ld	a5,32(a5)
ffffffffc0201cf0:	8782                	jr	a5
{
ffffffffc0201cf2:	1101                	addi	sp,sp,-32
ffffffffc0201cf4:	ec06                	sd	ra,24(sp)
ffffffffc0201cf6:	e822                	sd	s0,16(sp)
ffffffffc0201cf8:	e426                	sd	s1,8(sp)
ffffffffc0201cfa:	842a                	mv	s0,a0
ffffffffc0201cfc:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201cfe:	c33fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201d02:	0000b797          	auipc	a5,0xb
ffffffffc0201d06:	7be7b783          	ld	a5,1982(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d0a:	739c                	ld	a5,32(a5)
ffffffffc0201d0c:	85a6                	mv	a1,s1
ffffffffc0201d0e:	8522                	mv	a0,s0
ffffffffc0201d10:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201d12:	6442                	ld	s0,16(sp)
ffffffffc0201d14:	60e2                	ld	ra,24(sp)
ffffffffc0201d16:	64a2                	ld	s1,8(sp)
ffffffffc0201d18:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201d1a:	c11fe06f          	j	ffffffffc020092a <intr_enable>

ffffffffc0201d1e <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d1e:	100027f3          	csrr	a5,sstatus
ffffffffc0201d22:	8b89                	andi	a5,a5,2
ffffffffc0201d24:	e799                	bnez	a5,ffffffffc0201d32 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d26:	0000b797          	auipc	a5,0xb
ffffffffc0201d2a:	79a7b783          	ld	a5,1946(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d2e:	779c                	ld	a5,40(a5)
ffffffffc0201d30:	8782                	jr	a5
{
ffffffffc0201d32:	1141                	addi	sp,sp,-16
ffffffffc0201d34:	e406                	sd	ra,8(sp)
ffffffffc0201d36:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201d38:	bf9fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d3c:	0000b797          	auipc	a5,0xb
ffffffffc0201d40:	7847b783          	ld	a5,1924(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d44:	779c                	ld	a5,40(a5)
ffffffffc0201d46:	9782                	jalr	a5
ffffffffc0201d48:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201d4a:	be1fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201d4e:	60a2                	ld	ra,8(sp)
ffffffffc0201d50:	8522                	mv	a0,s0
ffffffffc0201d52:	6402                	ld	s0,0(sp)
ffffffffc0201d54:	0141                	addi	sp,sp,16
ffffffffc0201d56:	8082                	ret

ffffffffc0201d58 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d58:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201d5c:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201d60:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d62:	078e                	slli	a5,a5,0x3
{
ffffffffc0201d64:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d66:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201d6a:	6094                	ld	a3,0(s1)
{
ffffffffc0201d6c:	f04a                	sd	s2,32(sp)
ffffffffc0201d6e:	ec4e                	sd	s3,24(sp)
ffffffffc0201d70:	e852                	sd	s4,16(sp)
ffffffffc0201d72:	fc06                	sd	ra,56(sp)
ffffffffc0201d74:	f822                	sd	s0,48(sp)
ffffffffc0201d76:	e456                	sd	s5,8(sp)
ffffffffc0201d78:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201d7a:	0016f793          	andi	a5,a3,1
{
ffffffffc0201d7e:	892e                	mv	s2,a1
ffffffffc0201d80:	8a32                	mv	s4,a2
ffffffffc0201d82:	0000b997          	auipc	s3,0xb
ffffffffc0201d86:	72e98993          	addi	s3,s3,1838 # ffffffffc020d4b0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201d8a:	efbd                	bnez	a5,ffffffffc0201e08 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d8c:	14060c63          	beqz	a2,ffffffffc0201ee4 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d90:	100027f3          	csrr	a5,sstatus
ffffffffc0201d94:	8b89                	andi	a5,a5,2
ffffffffc0201d96:	14079963          	bnez	a5,ffffffffc0201ee8 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d9a:	0000b797          	auipc	a5,0xb
ffffffffc0201d9e:	7267b783          	ld	a5,1830(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201da2:	6f9c                	ld	a5,24(a5)
ffffffffc0201da4:	4505                	li	a0,1
ffffffffc0201da6:	9782                	jalr	a5
ffffffffc0201da8:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201daa:	12040d63          	beqz	s0,ffffffffc0201ee4 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201dae:	0000bb17          	auipc	s6,0xb
ffffffffc0201db2:	70ab0b13          	addi	s6,s6,1802 # ffffffffc020d4b8 <pages>
ffffffffc0201db6:	000b3503          	ld	a0,0(s6)
ffffffffc0201dba:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201dbe:	0000b997          	auipc	s3,0xb
ffffffffc0201dc2:	6f298993          	addi	s3,s3,1778 # ffffffffc020d4b0 <npage>
ffffffffc0201dc6:	40a40533          	sub	a0,s0,a0
ffffffffc0201dca:	8519                	srai	a0,a0,0x6
ffffffffc0201dcc:	9556                	add	a0,a0,s5
ffffffffc0201dce:	0009b703          	ld	a4,0(s3)
ffffffffc0201dd2:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201dd6:	4685                	li	a3,1
ffffffffc0201dd8:	c014                	sw	a3,0(s0)
ffffffffc0201dda:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ddc:	0532                	slli	a0,a0,0xc
ffffffffc0201dde:	16e7f763          	bgeu	a5,a4,ffffffffc0201f4c <get_pte+0x1f4>
ffffffffc0201de2:	0000b797          	auipc	a5,0xb
ffffffffc0201de6:	6e67b783          	ld	a5,1766(a5) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201dea:	6605                	lui	a2,0x1
ffffffffc0201dec:	4581                	li	a1,0
ffffffffc0201dee:	953e                	add	a0,a0,a5
ffffffffc0201df0:	0bc020ef          	jal	ra,ffffffffc0203eac <memset>
    return page - pages + nbase;
ffffffffc0201df4:	000b3683          	ld	a3,0(s6)
ffffffffc0201df8:	40d406b3          	sub	a3,s0,a3
ffffffffc0201dfc:	8699                	srai	a3,a3,0x6
ffffffffc0201dfe:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e00:	06aa                	slli	a3,a3,0xa
ffffffffc0201e02:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e06:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201e08:	77fd                	lui	a5,0xfffff
ffffffffc0201e0a:	068a                	slli	a3,a3,0x2
ffffffffc0201e0c:	0009b703          	ld	a4,0(s3)
ffffffffc0201e10:	8efd                	and	a3,a3,a5
ffffffffc0201e12:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e16:	10e7ff63          	bgeu	a5,a4,ffffffffc0201f34 <get_pte+0x1dc>
ffffffffc0201e1a:	0000ba97          	auipc	s5,0xb
ffffffffc0201e1e:	6aea8a93          	addi	s5,s5,1710 # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201e22:	000ab403          	ld	s0,0(s5)
ffffffffc0201e26:	01595793          	srli	a5,s2,0x15
ffffffffc0201e2a:	1ff7f793          	andi	a5,a5,511
ffffffffc0201e2e:	96a2                	add	a3,a3,s0
ffffffffc0201e30:	00379413          	slli	s0,a5,0x3
ffffffffc0201e34:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201e36:	6014                	ld	a3,0(s0)
ffffffffc0201e38:	0016f793          	andi	a5,a3,1
ffffffffc0201e3c:	ebad                	bnez	a5,ffffffffc0201eae <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e3e:	0a0a0363          	beqz	s4,ffffffffc0201ee4 <get_pte+0x18c>
ffffffffc0201e42:	100027f3          	csrr	a5,sstatus
ffffffffc0201e46:	8b89                	andi	a5,a5,2
ffffffffc0201e48:	efcd                	bnez	a5,ffffffffc0201f02 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e4a:	0000b797          	auipc	a5,0xb
ffffffffc0201e4e:	6767b783          	ld	a5,1654(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201e52:	6f9c                	ld	a5,24(a5)
ffffffffc0201e54:	4505                	li	a0,1
ffffffffc0201e56:	9782                	jalr	a5
ffffffffc0201e58:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e5a:	c4c9                	beqz	s1,ffffffffc0201ee4 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201e5c:	0000bb17          	auipc	s6,0xb
ffffffffc0201e60:	65cb0b13          	addi	s6,s6,1628 # ffffffffc020d4b8 <pages>
ffffffffc0201e64:	000b3503          	ld	a0,0(s6)
ffffffffc0201e68:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e6c:	0009b703          	ld	a4,0(s3)
ffffffffc0201e70:	40a48533          	sub	a0,s1,a0
ffffffffc0201e74:	8519                	srai	a0,a0,0x6
ffffffffc0201e76:	9552                	add	a0,a0,s4
ffffffffc0201e78:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201e7c:	4685                	li	a3,1
ffffffffc0201e7e:	c094                	sw	a3,0(s1)
ffffffffc0201e80:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e82:	0532                	slli	a0,a0,0xc
ffffffffc0201e84:	0ee7f163          	bgeu	a5,a4,ffffffffc0201f66 <get_pte+0x20e>
ffffffffc0201e88:	000ab783          	ld	a5,0(s5)
ffffffffc0201e8c:	6605                	lui	a2,0x1
ffffffffc0201e8e:	4581                	li	a1,0
ffffffffc0201e90:	953e                	add	a0,a0,a5
ffffffffc0201e92:	01a020ef          	jal	ra,ffffffffc0203eac <memset>
    return page - pages + nbase;
ffffffffc0201e96:	000b3683          	ld	a3,0(s6)
ffffffffc0201e9a:	40d486b3          	sub	a3,s1,a3
ffffffffc0201e9e:	8699                	srai	a3,a3,0x6
ffffffffc0201ea0:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201ea2:	06aa                	slli	a3,a3,0xa
ffffffffc0201ea4:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201ea8:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201eaa:	0009b703          	ld	a4,0(s3)
ffffffffc0201eae:	068a                	slli	a3,a3,0x2
ffffffffc0201eb0:	757d                	lui	a0,0xfffff
ffffffffc0201eb2:	8ee9                	and	a3,a3,a0
ffffffffc0201eb4:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201eb8:	06e7f263          	bgeu	a5,a4,ffffffffc0201f1c <get_pte+0x1c4>
ffffffffc0201ebc:	000ab503          	ld	a0,0(s5)
ffffffffc0201ec0:	00c95913          	srli	s2,s2,0xc
ffffffffc0201ec4:	1ff97913          	andi	s2,s2,511
ffffffffc0201ec8:	96aa                	add	a3,a3,a0
ffffffffc0201eca:	00391513          	slli	a0,s2,0x3
ffffffffc0201ece:	9536                	add	a0,a0,a3
}
ffffffffc0201ed0:	70e2                	ld	ra,56(sp)
ffffffffc0201ed2:	7442                	ld	s0,48(sp)
ffffffffc0201ed4:	74a2                	ld	s1,40(sp)
ffffffffc0201ed6:	7902                	ld	s2,32(sp)
ffffffffc0201ed8:	69e2                	ld	s3,24(sp)
ffffffffc0201eda:	6a42                	ld	s4,16(sp)
ffffffffc0201edc:	6aa2                	ld	s5,8(sp)
ffffffffc0201ede:	6b02                	ld	s6,0(sp)
ffffffffc0201ee0:	6121                	addi	sp,sp,64
ffffffffc0201ee2:	8082                	ret
            return NULL;
ffffffffc0201ee4:	4501                	li	a0,0
ffffffffc0201ee6:	b7ed                	j	ffffffffc0201ed0 <get_pte+0x178>
        intr_disable();
ffffffffc0201ee8:	a49fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201eec:	0000b797          	auipc	a5,0xb
ffffffffc0201ef0:	5d47b783          	ld	a5,1492(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201ef4:	6f9c                	ld	a5,24(a5)
ffffffffc0201ef6:	4505                	li	a0,1
ffffffffc0201ef8:	9782                	jalr	a5
ffffffffc0201efa:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201efc:	a2ffe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201f00:	b56d                	j	ffffffffc0201daa <get_pte+0x52>
        intr_disable();
ffffffffc0201f02:	a2ffe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0201f06:	0000b797          	auipc	a5,0xb
ffffffffc0201f0a:	5ba7b783          	ld	a5,1466(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201f0e:	6f9c                	ld	a5,24(a5)
ffffffffc0201f10:	4505                	li	a0,1
ffffffffc0201f12:	9782                	jalr	a5
ffffffffc0201f14:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201f16:	a15fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201f1a:	b781                	j	ffffffffc0201e5a <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f1c:	00003617          	auipc	a2,0x3
ffffffffc0201f20:	e6c60613          	addi	a2,a2,-404 # ffffffffc0204d88 <default_pmm_manager+0x38>
ffffffffc0201f24:	0fb00593          	li	a1,251
ffffffffc0201f28:	00003517          	auipc	a0,0x3
ffffffffc0201f2c:	f7850513          	addi	a0,a0,-136 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0201f30:	d2afe0ef          	jal	ra,ffffffffc020045a <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f34:	00003617          	auipc	a2,0x3
ffffffffc0201f38:	e5460613          	addi	a2,a2,-428 # ffffffffc0204d88 <default_pmm_manager+0x38>
ffffffffc0201f3c:	0ee00593          	li	a1,238
ffffffffc0201f40:	00003517          	auipc	a0,0x3
ffffffffc0201f44:	f6050513          	addi	a0,a0,-160 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0201f48:	d12fe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f4c:	86aa                	mv	a3,a0
ffffffffc0201f4e:	00003617          	auipc	a2,0x3
ffffffffc0201f52:	e3a60613          	addi	a2,a2,-454 # ffffffffc0204d88 <default_pmm_manager+0x38>
ffffffffc0201f56:	0eb00593          	li	a1,235
ffffffffc0201f5a:	00003517          	auipc	a0,0x3
ffffffffc0201f5e:	f4650513          	addi	a0,a0,-186 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0201f62:	cf8fe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f66:	86aa                	mv	a3,a0
ffffffffc0201f68:	00003617          	auipc	a2,0x3
ffffffffc0201f6c:	e2060613          	addi	a2,a2,-480 # ffffffffc0204d88 <default_pmm_manager+0x38>
ffffffffc0201f70:	0f800593          	li	a1,248
ffffffffc0201f74:	00003517          	auipc	a0,0x3
ffffffffc0201f78:	f2c50513          	addi	a0,a0,-212 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0201f7c:	cdefe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201f80 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201f80:	1141                	addi	sp,sp,-16
ffffffffc0201f82:	e022                	sd	s0,0(sp)
ffffffffc0201f84:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f86:	4601                	li	a2,0
{
ffffffffc0201f88:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f8a:	dcfff0ef          	jal	ra,ffffffffc0201d58 <get_pte>
    if (ptep_store != NULL)
ffffffffc0201f8e:	c011                	beqz	s0,ffffffffc0201f92 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201f90:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f92:	c511                	beqz	a0,ffffffffc0201f9e <get_page+0x1e>
ffffffffc0201f94:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201f96:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f98:	0017f713          	andi	a4,a5,1
ffffffffc0201f9c:	e709                	bnez	a4,ffffffffc0201fa6 <get_page+0x26>
}
ffffffffc0201f9e:	60a2                	ld	ra,8(sp)
ffffffffc0201fa0:	6402                	ld	s0,0(sp)
ffffffffc0201fa2:	0141                	addi	sp,sp,16
ffffffffc0201fa4:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201fa6:	078a                	slli	a5,a5,0x2
ffffffffc0201fa8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201faa:	0000b717          	auipc	a4,0xb
ffffffffc0201fae:	50673703          	ld	a4,1286(a4) # ffffffffc020d4b0 <npage>
ffffffffc0201fb2:	00e7ff63          	bgeu	a5,a4,ffffffffc0201fd0 <get_page+0x50>
ffffffffc0201fb6:	60a2                	ld	ra,8(sp)
ffffffffc0201fb8:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201fba:	fff80537          	lui	a0,0xfff80
ffffffffc0201fbe:	97aa                	add	a5,a5,a0
ffffffffc0201fc0:	079a                	slli	a5,a5,0x6
ffffffffc0201fc2:	0000b517          	auipc	a0,0xb
ffffffffc0201fc6:	4f653503          	ld	a0,1270(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201fca:	953e                	add	a0,a0,a5
ffffffffc0201fcc:	0141                	addi	sp,sp,16
ffffffffc0201fce:	8082                	ret
ffffffffc0201fd0:	c99ff0ef          	jal	ra,ffffffffc0201c68 <pa2page.part.0>

ffffffffc0201fd4 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201fd4:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fd6:	4601                	li	a2,0
{
ffffffffc0201fd8:	ec26                	sd	s1,24(sp)
ffffffffc0201fda:	f406                	sd	ra,40(sp)
ffffffffc0201fdc:	f022                	sd	s0,32(sp)
ffffffffc0201fde:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fe0:	d79ff0ef          	jal	ra,ffffffffc0201d58 <get_pte>
    if (ptep != NULL)
ffffffffc0201fe4:	c511                	beqz	a0,ffffffffc0201ff0 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0201fe6:	611c                	ld	a5,0(a0)
ffffffffc0201fe8:	842a                	mv	s0,a0
ffffffffc0201fea:	0017f713          	andi	a4,a5,1
ffffffffc0201fee:	e711                	bnez	a4,ffffffffc0201ffa <page_remove+0x26>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201ff0:	70a2                	ld	ra,40(sp)
ffffffffc0201ff2:	7402                	ld	s0,32(sp)
ffffffffc0201ff4:	64e2                	ld	s1,24(sp)
ffffffffc0201ff6:	6145                	addi	sp,sp,48
ffffffffc0201ff8:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201ffa:	078a                	slli	a5,a5,0x2
ffffffffc0201ffc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201ffe:	0000b717          	auipc	a4,0xb
ffffffffc0202002:	4b273703          	ld	a4,1202(a4) # ffffffffc020d4b0 <npage>
ffffffffc0202006:	06e7f363          	bgeu	a5,a4,ffffffffc020206c <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020200a:	fff80537          	lui	a0,0xfff80
ffffffffc020200e:	97aa                	add	a5,a5,a0
ffffffffc0202010:	079a                	slli	a5,a5,0x6
ffffffffc0202012:	0000b517          	auipc	a0,0xb
ffffffffc0202016:	4a653503          	ld	a0,1190(a0) # ffffffffc020d4b8 <pages>
ffffffffc020201a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020201c:	411c                	lw	a5,0(a0)
ffffffffc020201e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202022:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202024:	cb11                	beqz	a4,ffffffffc0202038 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202026:	00043023          	sd	zero,0(s0)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020202a:	12048073          	sfence.vma	s1
}
ffffffffc020202e:	70a2                	ld	ra,40(sp)
ffffffffc0202030:	7402                	ld	s0,32(sp)
ffffffffc0202032:	64e2                	ld	s1,24(sp)
ffffffffc0202034:	6145                	addi	sp,sp,48
ffffffffc0202036:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202038:	100027f3          	csrr	a5,sstatus
ffffffffc020203c:	8b89                	andi	a5,a5,2
ffffffffc020203e:	eb89                	bnez	a5,ffffffffc0202050 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202040:	0000b797          	auipc	a5,0xb
ffffffffc0202044:	4807b783          	ld	a5,1152(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202048:	739c                	ld	a5,32(a5)
ffffffffc020204a:	4585                	li	a1,1
ffffffffc020204c:	9782                	jalr	a5
    if (flag) {
ffffffffc020204e:	bfe1                	j	ffffffffc0202026 <page_remove+0x52>
        intr_disable();
ffffffffc0202050:	e42a                	sd	a0,8(sp)
ffffffffc0202052:	8dffe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202056:	0000b797          	auipc	a5,0xb
ffffffffc020205a:	46a7b783          	ld	a5,1130(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc020205e:	739c                	ld	a5,32(a5)
ffffffffc0202060:	6522                	ld	a0,8(sp)
ffffffffc0202062:	4585                	li	a1,1
ffffffffc0202064:	9782                	jalr	a5
        intr_enable();
ffffffffc0202066:	8c5fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020206a:	bf75                	j	ffffffffc0202026 <page_remove+0x52>
ffffffffc020206c:	bfdff0ef          	jal	ra,ffffffffc0201c68 <pa2page.part.0>

ffffffffc0202070 <page_insert>:
{
ffffffffc0202070:	7139                	addi	sp,sp,-64
ffffffffc0202072:	e852                	sd	s4,16(sp)
ffffffffc0202074:	8a32                	mv	s4,a2
ffffffffc0202076:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202078:	4605                	li	a2,1
{
ffffffffc020207a:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020207c:	85d2                	mv	a1,s4
{
ffffffffc020207e:	f426                	sd	s1,40(sp)
ffffffffc0202080:	fc06                	sd	ra,56(sp)
ffffffffc0202082:	f04a                	sd	s2,32(sp)
ffffffffc0202084:	ec4e                	sd	s3,24(sp)
ffffffffc0202086:	e456                	sd	s5,8(sp)
ffffffffc0202088:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020208a:	ccfff0ef          	jal	ra,ffffffffc0201d58 <get_pte>
    if (ptep == NULL)
ffffffffc020208e:	c961                	beqz	a0,ffffffffc020215e <page_insert+0xee>
    page->ref += 1;
ffffffffc0202090:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202092:	611c                	ld	a5,0(a0)
ffffffffc0202094:	89aa                	mv	s3,a0
ffffffffc0202096:	0016871b          	addiw	a4,a3,1
ffffffffc020209a:	c018                	sw	a4,0(s0)
ffffffffc020209c:	0017f713          	andi	a4,a5,1
ffffffffc02020a0:	ef05                	bnez	a4,ffffffffc02020d8 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc02020a2:	0000b717          	auipc	a4,0xb
ffffffffc02020a6:	41673703          	ld	a4,1046(a4) # ffffffffc020d4b8 <pages>
ffffffffc02020aa:	8c19                	sub	s0,s0,a4
ffffffffc02020ac:	000807b7          	lui	a5,0x80
ffffffffc02020b0:	8419                	srai	s0,s0,0x6
ffffffffc02020b2:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020b4:	042a                	slli	s0,s0,0xa
ffffffffc02020b6:	8cc1                	or	s1,s1,s0
ffffffffc02020b8:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02020bc:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020c0:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02020c4:	4501                	li	a0,0
}
ffffffffc02020c6:	70e2                	ld	ra,56(sp)
ffffffffc02020c8:	7442                	ld	s0,48(sp)
ffffffffc02020ca:	74a2                	ld	s1,40(sp)
ffffffffc02020cc:	7902                	ld	s2,32(sp)
ffffffffc02020ce:	69e2                	ld	s3,24(sp)
ffffffffc02020d0:	6a42                	ld	s4,16(sp)
ffffffffc02020d2:	6aa2                	ld	s5,8(sp)
ffffffffc02020d4:	6121                	addi	sp,sp,64
ffffffffc02020d6:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02020d8:	078a                	slli	a5,a5,0x2
ffffffffc02020da:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020dc:	0000b717          	auipc	a4,0xb
ffffffffc02020e0:	3d473703          	ld	a4,980(a4) # ffffffffc020d4b0 <npage>
ffffffffc02020e4:	06e7ff63          	bgeu	a5,a4,ffffffffc0202162 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02020e8:	0000ba97          	auipc	s5,0xb
ffffffffc02020ec:	3d0a8a93          	addi	s5,s5,976 # ffffffffc020d4b8 <pages>
ffffffffc02020f0:	000ab703          	ld	a4,0(s5)
ffffffffc02020f4:	fff80937          	lui	s2,0xfff80
ffffffffc02020f8:	993e                	add	s2,s2,a5
ffffffffc02020fa:	091a                	slli	s2,s2,0x6
ffffffffc02020fc:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02020fe:	01240c63          	beq	s0,s2,ffffffffc0202116 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202102:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd72b14>
ffffffffc0202106:	fff7869b          	addiw	a3,a5,-1
ffffffffc020210a:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc020210e:	c691                	beqz	a3,ffffffffc020211a <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202110:	120a0073          	sfence.vma	s4
}
ffffffffc0202114:	bf59                	j	ffffffffc02020aa <page_insert+0x3a>
ffffffffc0202116:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202118:	bf49                	j	ffffffffc02020aa <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020211a:	100027f3          	csrr	a5,sstatus
ffffffffc020211e:	8b89                	andi	a5,a5,2
ffffffffc0202120:	ef91                	bnez	a5,ffffffffc020213c <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202122:	0000b797          	auipc	a5,0xb
ffffffffc0202126:	39e7b783          	ld	a5,926(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc020212a:	739c                	ld	a5,32(a5)
ffffffffc020212c:	4585                	li	a1,1
ffffffffc020212e:	854a                	mv	a0,s2
ffffffffc0202130:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202132:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202136:	120a0073          	sfence.vma	s4
ffffffffc020213a:	bf85                	j	ffffffffc02020aa <page_insert+0x3a>
        intr_disable();
ffffffffc020213c:	ff4fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202140:	0000b797          	auipc	a5,0xb
ffffffffc0202144:	3807b783          	ld	a5,896(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202148:	739c                	ld	a5,32(a5)
ffffffffc020214a:	4585                	li	a1,1
ffffffffc020214c:	854a                	mv	a0,s2
ffffffffc020214e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202150:	fdafe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202154:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202158:	120a0073          	sfence.vma	s4
ffffffffc020215c:	b7b9                	j	ffffffffc02020aa <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020215e:	5571                	li	a0,-4
ffffffffc0202160:	b79d                	j	ffffffffc02020c6 <page_insert+0x56>
ffffffffc0202162:	b07ff0ef          	jal	ra,ffffffffc0201c68 <pa2page.part.0>

ffffffffc0202166 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202166:	00003797          	auipc	a5,0x3
ffffffffc020216a:	bea78793          	addi	a5,a5,-1046 # ffffffffc0204d50 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020216e:	638c                	ld	a1,0(a5)
{
ffffffffc0202170:	7159                	addi	sp,sp,-112
ffffffffc0202172:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202174:	00003517          	auipc	a0,0x3
ffffffffc0202178:	d3c50513          	addi	a0,a0,-708 # ffffffffc0204eb0 <default_pmm_manager+0x160>
    pmm_manager = &default_pmm_manager;
ffffffffc020217c:	0000bb17          	auipc	s6,0xb
ffffffffc0202180:	344b0b13          	addi	s6,s6,836 # ffffffffc020d4c0 <pmm_manager>
{
ffffffffc0202184:	f486                	sd	ra,104(sp)
ffffffffc0202186:	e8ca                	sd	s2,80(sp)
ffffffffc0202188:	e4ce                	sd	s3,72(sp)
ffffffffc020218a:	f0a2                	sd	s0,96(sp)
ffffffffc020218c:	eca6                	sd	s1,88(sp)
ffffffffc020218e:	e0d2                	sd	s4,64(sp)
ffffffffc0202190:	fc56                	sd	s5,56(sp)
ffffffffc0202192:	f45e                	sd	s7,40(sp)
ffffffffc0202194:	f062                	sd	s8,32(sp)
ffffffffc0202196:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202198:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020219c:	ff9fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc02021a0:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02021a4:	0000b997          	auipc	s3,0xb
ffffffffc02021a8:	32498993          	addi	s3,s3,804 # ffffffffc020d4c8 <va_pa_offset>
    pmm_manager->init();
ffffffffc02021ac:	679c                	ld	a5,8(a5)
ffffffffc02021ae:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02021b0:	57f5                	li	a5,-3
ffffffffc02021b2:	07fa                	slli	a5,a5,0x1e
ffffffffc02021b4:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02021b8:	f5efe0ef          	jal	ra,ffffffffc0200916 <get_memory_base>
ffffffffc02021bc:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02021be:	f62fe0ef          	jal	ra,ffffffffc0200920 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02021c2:	200505e3          	beqz	a0,ffffffffc0202bcc <pmm_init+0xa66>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021c6:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02021c8:	00003517          	auipc	a0,0x3
ffffffffc02021cc:	d2050513          	addi	a0,a0,-736 # ffffffffc0204ee8 <default_pmm_manager+0x198>
ffffffffc02021d0:	fc5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021d4:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02021d8:	fff40693          	addi	a3,s0,-1
ffffffffc02021dc:	864a                	mv	a2,s2
ffffffffc02021de:	85a6                	mv	a1,s1
ffffffffc02021e0:	00003517          	auipc	a0,0x3
ffffffffc02021e4:	d2050513          	addi	a0,a0,-736 # ffffffffc0204f00 <default_pmm_manager+0x1b0>
ffffffffc02021e8:	fadfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02021ec:	c8000737          	lui	a4,0xc8000
ffffffffc02021f0:	87a2                	mv	a5,s0
ffffffffc02021f2:	54876163          	bltu	a4,s0,ffffffffc0202734 <pmm_init+0x5ce>
ffffffffc02021f6:	757d                	lui	a0,0xfffff
ffffffffc02021f8:	0000c617          	auipc	a2,0xc
ffffffffc02021fc:	2f360613          	addi	a2,a2,755 # ffffffffc020e4eb <end+0xfff>
ffffffffc0202200:	8e69                	and	a2,a2,a0
ffffffffc0202202:	0000b497          	auipc	s1,0xb
ffffffffc0202206:	2ae48493          	addi	s1,s1,686 # ffffffffc020d4b0 <npage>
ffffffffc020220a:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020220e:	0000bb97          	auipc	s7,0xb
ffffffffc0202212:	2aab8b93          	addi	s7,s7,682 # ffffffffc020d4b8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202216:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202218:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020221c:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202220:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202222:	02f50863          	beq	a0,a5,ffffffffc0202252 <pmm_init+0xec>
ffffffffc0202226:	4781                	li	a5,0
ffffffffc0202228:	4585                	li	a1,1
ffffffffc020222a:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020222e:	00679513          	slli	a0,a5,0x6
ffffffffc0202232:	9532                	add	a0,a0,a2
ffffffffc0202234:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fdf1b1c>
ffffffffc0202238:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020223c:	6088                	ld	a0,0(s1)
ffffffffc020223e:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202240:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202244:	00d50733          	add	a4,a0,a3
ffffffffc0202248:	fee7e3e3          	bltu	a5,a4,ffffffffc020222e <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020224c:	071a                	slli	a4,a4,0x6
ffffffffc020224e:	00e606b3          	add	a3,a2,a4
ffffffffc0202252:	c02007b7          	lui	a5,0xc0200
ffffffffc0202256:	2ef6ece3          	bltu	a3,a5,ffffffffc0202d4e <pmm_init+0xbe8>
ffffffffc020225a:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020225e:	77fd                	lui	a5,0xfffff
ffffffffc0202260:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202262:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202264:	5086eb63          	bltu	a3,s0,ffffffffc020277a <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202268:	00003517          	auipc	a0,0x3
ffffffffc020226c:	cc050513          	addi	a0,a0,-832 # ffffffffc0204f28 <default_pmm_manager+0x1d8>
ffffffffc0202270:	f25fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202274:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202278:	0000b917          	auipc	s2,0xb
ffffffffc020227c:	23090913          	addi	s2,s2,560 # ffffffffc020d4a8 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202280:	7b9c                	ld	a5,48(a5)
ffffffffc0202282:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202284:	00003517          	auipc	a0,0x3
ffffffffc0202288:	cbc50513          	addi	a0,a0,-836 # ffffffffc0204f40 <default_pmm_manager+0x1f0>
ffffffffc020228c:	f09fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202290:	00006697          	auipc	a3,0x6
ffffffffc0202294:	d7068693          	addi	a3,a3,-656 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0202298:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020229c:	c02007b7          	lui	a5,0xc0200
ffffffffc02022a0:	28f6ebe3          	bltu	a3,a5,ffffffffc0202d36 <pmm_init+0xbd0>
ffffffffc02022a4:	0009b783          	ld	a5,0(s3)
ffffffffc02022a8:	8e9d                	sub	a3,a3,a5
ffffffffc02022aa:	0000b797          	auipc	a5,0xb
ffffffffc02022ae:	1ed7bb23          	sd	a3,502(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02022b2:	100027f3          	csrr	a5,sstatus
ffffffffc02022b6:	8b89                	andi	a5,a5,2
ffffffffc02022b8:	4a079763          	bnez	a5,ffffffffc0202766 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc02022bc:	000b3783          	ld	a5,0(s6)
ffffffffc02022c0:	779c                	ld	a5,40(a5)
ffffffffc02022c2:	9782                	jalr	a5
ffffffffc02022c4:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02022c6:	6098                	ld	a4,0(s1)
ffffffffc02022c8:	c80007b7          	lui	a5,0xc8000
ffffffffc02022cc:	83b1                	srli	a5,a5,0xc
ffffffffc02022ce:	66e7e363          	bltu	a5,a4,ffffffffc0202934 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02022d2:	00093503          	ld	a0,0(s2)
ffffffffc02022d6:	62050f63          	beqz	a0,ffffffffc0202914 <pmm_init+0x7ae>
ffffffffc02022da:	03451793          	slli	a5,a0,0x34
ffffffffc02022de:	62079b63          	bnez	a5,ffffffffc0202914 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02022e2:	4601                	li	a2,0
ffffffffc02022e4:	4581                	li	a1,0
ffffffffc02022e6:	c9bff0ef          	jal	ra,ffffffffc0201f80 <get_page>
ffffffffc02022ea:	60051563          	bnez	a0,ffffffffc02028f4 <pmm_init+0x78e>
ffffffffc02022ee:	100027f3          	csrr	a5,sstatus
ffffffffc02022f2:	8b89                	andi	a5,a5,2
ffffffffc02022f4:	44079e63          	bnez	a5,ffffffffc0202750 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022f8:	000b3783          	ld	a5,0(s6)
ffffffffc02022fc:	4505                	li	a0,1
ffffffffc02022fe:	6f9c                	ld	a5,24(a5)
ffffffffc0202300:	9782                	jalr	a5
ffffffffc0202302:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202304:	00093503          	ld	a0,0(s2)
ffffffffc0202308:	4681                	li	a3,0
ffffffffc020230a:	4601                	li	a2,0
ffffffffc020230c:	85d2                	mv	a1,s4
ffffffffc020230e:	d63ff0ef          	jal	ra,ffffffffc0202070 <page_insert>
ffffffffc0202312:	26051ae3          	bnez	a0,ffffffffc0202d86 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202316:	00093503          	ld	a0,0(s2)
ffffffffc020231a:	4601                	li	a2,0
ffffffffc020231c:	4581                	li	a1,0
ffffffffc020231e:	a3bff0ef          	jal	ra,ffffffffc0201d58 <get_pte>
ffffffffc0202322:	240502e3          	beqz	a0,ffffffffc0202d66 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0202326:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202328:	0017f713          	andi	a4,a5,1
ffffffffc020232c:	5a070263          	beqz	a4,ffffffffc02028d0 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202330:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202332:	078a                	slli	a5,a5,0x2
ffffffffc0202334:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202336:	58e7fb63          	bgeu	a5,a4,ffffffffc02028cc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020233a:	000bb683          	ld	a3,0(s7)
ffffffffc020233e:	fff80637          	lui	a2,0xfff80
ffffffffc0202342:	97b2                	add	a5,a5,a2
ffffffffc0202344:	079a                	slli	a5,a5,0x6
ffffffffc0202346:	97b6                	add	a5,a5,a3
ffffffffc0202348:	14fa17e3          	bne	s4,a5,ffffffffc0202c96 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc020234c:	000a2683          	lw	a3,0(s4) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc0202350:	4785                	li	a5,1
ffffffffc0202352:	12f692e3          	bne	a3,a5,ffffffffc0202c76 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202356:	00093503          	ld	a0,0(s2)
ffffffffc020235a:	77fd                	lui	a5,0xfffff
ffffffffc020235c:	6114                	ld	a3,0(a0)
ffffffffc020235e:	068a                	slli	a3,a3,0x2
ffffffffc0202360:	8efd                	and	a3,a3,a5
ffffffffc0202362:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202366:	0ee67ce3          	bgeu	a2,a4,ffffffffc0202c5e <pmm_init+0xaf8>
ffffffffc020236a:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020236e:	96e2                	add	a3,a3,s8
ffffffffc0202370:	0006ba83          	ld	s5,0(a3)
ffffffffc0202374:	0a8a                	slli	s5,s5,0x2
ffffffffc0202376:	00fafab3          	and	s5,s5,a5
ffffffffc020237a:	00cad793          	srli	a5,s5,0xc
ffffffffc020237e:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0202c44 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202382:	4601                	li	a2,0
ffffffffc0202384:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202386:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202388:	9d1ff0ef          	jal	ra,ffffffffc0201d58 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020238c:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020238e:	55551363          	bne	a0,s5,ffffffffc02028d4 <pmm_init+0x76e>
ffffffffc0202392:	100027f3          	csrr	a5,sstatus
ffffffffc0202396:	8b89                	andi	a5,a5,2
ffffffffc0202398:	3a079163          	bnez	a5,ffffffffc020273a <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc020239c:	000b3783          	ld	a5,0(s6)
ffffffffc02023a0:	4505                	li	a0,1
ffffffffc02023a2:	6f9c                	ld	a5,24(a5)
ffffffffc02023a4:	9782                	jalr	a5
ffffffffc02023a6:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02023a8:	00093503          	ld	a0,0(s2)
ffffffffc02023ac:	46d1                	li	a3,20
ffffffffc02023ae:	6605                	lui	a2,0x1
ffffffffc02023b0:	85e2                	mv	a1,s8
ffffffffc02023b2:	cbfff0ef          	jal	ra,ffffffffc0202070 <page_insert>
ffffffffc02023b6:	060517e3          	bnez	a0,ffffffffc0202c24 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02023ba:	00093503          	ld	a0,0(s2)
ffffffffc02023be:	4601                	li	a2,0
ffffffffc02023c0:	6585                	lui	a1,0x1
ffffffffc02023c2:	997ff0ef          	jal	ra,ffffffffc0201d58 <get_pte>
ffffffffc02023c6:	02050fe3          	beqz	a0,ffffffffc0202c04 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc02023ca:	611c                	ld	a5,0(a0)
ffffffffc02023cc:	0107f713          	andi	a4,a5,16
ffffffffc02023d0:	7c070e63          	beqz	a4,ffffffffc0202bac <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc02023d4:	8b91                	andi	a5,a5,4
ffffffffc02023d6:	7a078b63          	beqz	a5,ffffffffc0202b8c <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02023da:	00093503          	ld	a0,0(s2)
ffffffffc02023de:	611c                	ld	a5,0(a0)
ffffffffc02023e0:	8bc1                	andi	a5,a5,16
ffffffffc02023e2:	78078563          	beqz	a5,ffffffffc0202b6c <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02023e6:	000c2703          	lw	a4,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc02023ea:	4785                	li	a5,1
ffffffffc02023ec:	76f71063          	bne	a4,a5,ffffffffc0202b4c <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02023f0:	4681                	li	a3,0
ffffffffc02023f2:	6605                	lui	a2,0x1
ffffffffc02023f4:	85d2                	mv	a1,s4
ffffffffc02023f6:	c7bff0ef          	jal	ra,ffffffffc0202070 <page_insert>
ffffffffc02023fa:	72051963          	bnez	a0,ffffffffc0202b2c <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02023fe:	000a2703          	lw	a4,0(s4)
ffffffffc0202402:	4789                	li	a5,2
ffffffffc0202404:	70f71463          	bne	a4,a5,ffffffffc0202b0c <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202408:	000c2783          	lw	a5,0(s8)
ffffffffc020240c:	6e079063          	bnez	a5,ffffffffc0202aec <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202410:	00093503          	ld	a0,0(s2)
ffffffffc0202414:	4601                	li	a2,0
ffffffffc0202416:	6585                	lui	a1,0x1
ffffffffc0202418:	941ff0ef          	jal	ra,ffffffffc0201d58 <get_pte>
ffffffffc020241c:	6a050863          	beqz	a0,ffffffffc0202acc <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202420:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202422:	00177793          	andi	a5,a4,1
ffffffffc0202426:	4a078563          	beqz	a5,ffffffffc02028d0 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc020242a:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020242c:	00271793          	slli	a5,a4,0x2
ffffffffc0202430:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202432:	48d7fd63          	bgeu	a5,a3,ffffffffc02028cc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202436:	000bb683          	ld	a3,0(s7)
ffffffffc020243a:	fff80ab7          	lui	s5,0xfff80
ffffffffc020243e:	97d6                	add	a5,a5,s5
ffffffffc0202440:	079a                	slli	a5,a5,0x6
ffffffffc0202442:	97b6                	add	a5,a5,a3
ffffffffc0202444:	66fa1463          	bne	s4,a5,ffffffffc0202aac <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202448:	8b41                	andi	a4,a4,16
ffffffffc020244a:	64071163          	bnez	a4,ffffffffc0202a8c <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc020244e:	00093503          	ld	a0,0(s2)
ffffffffc0202452:	4581                	li	a1,0
ffffffffc0202454:	b81ff0ef          	jal	ra,ffffffffc0201fd4 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202458:	000a2c83          	lw	s9,0(s4)
ffffffffc020245c:	4785                	li	a5,1
ffffffffc020245e:	60fc9763          	bne	s9,a5,ffffffffc0202a6c <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202462:	000c2783          	lw	a5,0(s8)
ffffffffc0202466:	5e079363          	bnez	a5,ffffffffc0202a4c <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc020246a:	00093503          	ld	a0,0(s2)
ffffffffc020246e:	6585                	lui	a1,0x1
ffffffffc0202470:	b65ff0ef          	jal	ra,ffffffffc0201fd4 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202474:	000a2783          	lw	a5,0(s4)
ffffffffc0202478:	52079a63          	bnez	a5,ffffffffc02029ac <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc020247c:	000c2783          	lw	a5,0(s8)
ffffffffc0202480:	50079663          	bnez	a5,ffffffffc020298c <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202484:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202488:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020248a:	000a3683          	ld	a3,0(s4)
ffffffffc020248e:	068a                	slli	a3,a3,0x2
ffffffffc0202490:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202492:	42b6fd63          	bgeu	a3,a1,ffffffffc02028cc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202496:	000bb503          	ld	a0,0(s7)
ffffffffc020249a:	96d6                	add	a3,a3,s5
ffffffffc020249c:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020249e:	00d507b3          	add	a5,a0,a3
ffffffffc02024a2:	439c                	lw	a5,0(a5)
ffffffffc02024a4:	4d979463          	bne	a5,s9,ffffffffc020296c <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc02024a8:	8699                	srai	a3,a3,0x6
ffffffffc02024aa:	00080637          	lui	a2,0x80
ffffffffc02024ae:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02024b0:	00c69713          	slli	a4,a3,0xc
ffffffffc02024b4:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02024b6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02024b8:	48b77e63          	bgeu	a4,a1,ffffffffc0202954 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02024bc:	0009b703          	ld	a4,0(s3)
ffffffffc02024c0:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc02024c2:	629c                	ld	a5,0(a3)
ffffffffc02024c4:	078a                	slli	a5,a5,0x2
ffffffffc02024c6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024c8:	40b7f263          	bgeu	a5,a1,ffffffffc02028cc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02024cc:	8f91                	sub	a5,a5,a2
ffffffffc02024ce:	079a                	slli	a5,a5,0x6
ffffffffc02024d0:	953e                	add	a0,a0,a5
ffffffffc02024d2:	100027f3          	csrr	a5,sstatus
ffffffffc02024d6:	8b89                	andi	a5,a5,2
ffffffffc02024d8:	30079963          	bnez	a5,ffffffffc02027ea <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc02024dc:	000b3783          	ld	a5,0(s6)
ffffffffc02024e0:	4585                	li	a1,1
ffffffffc02024e2:	739c                	ld	a5,32(a5)
ffffffffc02024e4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02024e6:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02024ea:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024ec:	078a                	slli	a5,a5,0x2
ffffffffc02024ee:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024f0:	3ce7fe63          	bgeu	a5,a4,ffffffffc02028cc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02024f4:	000bb503          	ld	a0,0(s7)
ffffffffc02024f8:	fff80737          	lui	a4,0xfff80
ffffffffc02024fc:	97ba                	add	a5,a5,a4
ffffffffc02024fe:	079a                	slli	a5,a5,0x6
ffffffffc0202500:	953e                	add	a0,a0,a5
ffffffffc0202502:	100027f3          	csrr	a5,sstatus
ffffffffc0202506:	8b89                	andi	a5,a5,2
ffffffffc0202508:	2c079563          	bnez	a5,ffffffffc02027d2 <pmm_init+0x66c>
ffffffffc020250c:	000b3783          	ld	a5,0(s6)
ffffffffc0202510:	4585                	li	a1,1
ffffffffc0202512:	739c                	ld	a5,32(a5)
ffffffffc0202514:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202516:	00093783          	ld	a5,0(s2)
ffffffffc020251a:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b14>
    asm volatile("sfence.vma");
ffffffffc020251e:	12000073          	sfence.vma
ffffffffc0202522:	100027f3          	csrr	a5,sstatus
ffffffffc0202526:	8b89                	andi	a5,a5,2
ffffffffc0202528:	28079b63          	bnez	a5,ffffffffc02027be <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc020252c:	000b3783          	ld	a5,0(s6)
ffffffffc0202530:	779c                	ld	a5,40(a5)
ffffffffc0202532:	9782                	jalr	a5
ffffffffc0202534:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202536:	4b441b63          	bne	s0,s4,ffffffffc02029ec <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc020253a:	00003517          	auipc	a0,0x3
ffffffffc020253e:	d2e50513          	addi	a0,a0,-722 # ffffffffc0205268 <default_pmm_manager+0x518>
ffffffffc0202542:	c53fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202546:	100027f3          	csrr	a5,sstatus
ffffffffc020254a:	8b89                	andi	a5,a5,2
ffffffffc020254c:	24079f63          	bnez	a5,ffffffffc02027aa <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202550:	000b3783          	ld	a5,0(s6)
ffffffffc0202554:	779c                	ld	a5,40(a5)
ffffffffc0202556:	9782                	jalr	a5
ffffffffc0202558:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020255a:	6098                	ld	a4,0(s1)
ffffffffc020255c:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202560:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202562:	00c71793          	slli	a5,a4,0xc
ffffffffc0202566:	6a05                	lui	s4,0x1
ffffffffc0202568:	02f47c63          	bgeu	s0,a5,ffffffffc02025a0 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020256c:	00c45793          	srli	a5,s0,0xc
ffffffffc0202570:	00093503          	ld	a0,0(s2)
ffffffffc0202574:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202872 <pmm_init+0x70c>
ffffffffc0202578:	0009b583          	ld	a1,0(s3)
ffffffffc020257c:	4601                	li	a2,0
ffffffffc020257e:	95a2                	add	a1,a1,s0
ffffffffc0202580:	fd8ff0ef          	jal	ra,ffffffffc0201d58 <get_pte>
ffffffffc0202584:	32050463          	beqz	a0,ffffffffc02028ac <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202588:	611c                	ld	a5,0(a0)
ffffffffc020258a:	078a                	slli	a5,a5,0x2
ffffffffc020258c:	0157f7b3          	and	a5,a5,s5
ffffffffc0202590:	2e879e63          	bne	a5,s0,ffffffffc020288c <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202594:	6098                	ld	a4,0(s1)
ffffffffc0202596:	9452                	add	s0,s0,s4
ffffffffc0202598:	00c71793          	slli	a5,a4,0xc
ffffffffc020259c:	fcf468e3          	bltu	s0,a5,ffffffffc020256c <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc02025a0:	00093783          	ld	a5,0(s2)
ffffffffc02025a4:	639c                	ld	a5,0(a5)
ffffffffc02025a6:	42079363          	bnez	a5,ffffffffc02029cc <pmm_init+0x866>
ffffffffc02025aa:	100027f3          	csrr	a5,sstatus
ffffffffc02025ae:	8b89                	andi	a5,a5,2
ffffffffc02025b0:	24079963          	bnez	a5,ffffffffc0202802 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc02025b4:	000b3783          	ld	a5,0(s6)
ffffffffc02025b8:	4505                	li	a0,1
ffffffffc02025ba:	6f9c                	ld	a5,24(a5)
ffffffffc02025bc:	9782                	jalr	a5
ffffffffc02025be:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02025c0:	00093503          	ld	a0,0(s2)
ffffffffc02025c4:	4699                	li	a3,6
ffffffffc02025c6:	10000613          	li	a2,256
ffffffffc02025ca:	85d2                	mv	a1,s4
ffffffffc02025cc:	aa5ff0ef          	jal	ra,ffffffffc0202070 <page_insert>
ffffffffc02025d0:	44051e63          	bnez	a0,ffffffffc0202a2c <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc02025d4:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02025d8:	4785                	li	a5,1
ffffffffc02025da:	42f71963          	bne	a4,a5,ffffffffc0202a0c <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02025de:	00093503          	ld	a0,0(s2)
ffffffffc02025e2:	6405                	lui	s0,0x1
ffffffffc02025e4:	4699                	li	a3,6
ffffffffc02025e6:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025ea:	85d2                	mv	a1,s4
ffffffffc02025ec:	a85ff0ef          	jal	ra,ffffffffc0202070 <page_insert>
ffffffffc02025f0:	72051363          	bnez	a0,ffffffffc0202d16 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc02025f4:	000a2703          	lw	a4,0(s4)
ffffffffc02025f8:	4789                	li	a5,2
ffffffffc02025fa:	6ef71e63          	bne	a4,a5,ffffffffc0202cf6 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02025fe:	00003597          	auipc	a1,0x3
ffffffffc0202602:	db258593          	addi	a1,a1,-590 # ffffffffc02053b0 <default_pmm_manager+0x660>
ffffffffc0202606:	10000513          	li	a0,256
ffffffffc020260a:	037010ef          	jal	ra,ffffffffc0203e40 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020260e:	10040593          	addi	a1,s0,256
ffffffffc0202612:	10000513          	li	a0,256
ffffffffc0202616:	03d010ef          	jal	ra,ffffffffc0203e52 <strcmp>
ffffffffc020261a:	6a051e63          	bnez	a0,ffffffffc0202cd6 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc020261e:	000bb683          	ld	a3,0(s7)
ffffffffc0202622:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202626:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202628:	40da06b3          	sub	a3,s4,a3
ffffffffc020262c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020262e:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202630:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202632:	8031                	srli	s0,s0,0xc
ffffffffc0202634:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202638:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020263a:	30f77d63          	bgeu	a4,a5,ffffffffc0202954 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020263e:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202642:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202646:	96be                	add	a3,a3,a5
ffffffffc0202648:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020264c:	7be010ef          	jal	ra,ffffffffc0203e0a <strlen>
ffffffffc0202650:	66051363          	bnez	a0,ffffffffc0202cb6 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202654:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202658:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020265a:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fdf1b14>
ffffffffc020265e:	068a                	slli	a3,a3,0x2
ffffffffc0202660:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202662:	26f6f563          	bgeu	a3,a5,ffffffffc02028cc <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202666:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202668:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020266a:	2ef47563          	bgeu	s0,a5,ffffffffc0202954 <pmm_init+0x7ee>
ffffffffc020266e:	0009b403          	ld	s0,0(s3)
ffffffffc0202672:	9436                	add	s0,s0,a3
ffffffffc0202674:	100027f3          	csrr	a5,sstatus
ffffffffc0202678:	8b89                	andi	a5,a5,2
ffffffffc020267a:	1e079163          	bnez	a5,ffffffffc020285c <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc020267e:	000b3783          	ld	a5,0(s6)
ffffffffc0202682:	4585                	li	a1,1
ffffffffc0202684:	8552                	mv	a0,s4
ffffffffc0202686:	739c                	ld	a5,32(a5)
ffffffffc0202688:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020268a:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc020268c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020268e:	078a                	slli	a5,a5,0x2
ffffffffc0202690:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202692:	22e7fd63          	bgeu	a5,a4,ffffffffc02028cc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202696:	000bb503          	ld	a0,0(s7)
ffffffffc020269a:	fff80737          	lui	a4,0xfff80
ffffffffc020269e:	97ba                	add	a5,a5,a4
ffffffffc02026a0:	079a                	slli	a5,a5,0x6
ffffffffc02026a2:	953e                	add	a0,a0,a5
ffffffffc02026a4:	100027f3          	csrr	a5,sstatus
ffffffffc02026a8:	8b89                	andi	a5,a5,2
ffffffffc02026aa:	18079d63          	bnez	a5,ffffffffc0202844 <pmm_init+0x6de>
ffffffffc02026ae:	000b3783          	ld	a5,0(s6)
ffffffffc02026b2:	4585                	li	a1,1
ffffffffc02026b4:	739c                	ld	a5,32(a5)
ffffffffc02026b6:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02026b8:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc02026bc:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02026be:	078a                	slli	a5,a5,0x2
ffffffffc02026c0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026c2:	20e7f563          	bgeu	a5,a4,ffffffffc02028cc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02026c6:	000bb503          	ld	a0,0(s7)
ffffffffc02026ca:	fff80737          	lui	a4,0xfff80
ffffffffc02026ce:	97ba                	add	a5,a5,a4
ffffffffc02026d0:	079a                	slli	a5,a5,0x6
ffffffffc02026d2:	953e                	add	a0,a0,a5
ffffffffc02026d4:	100027f3          	csrr	a5,sstatus
ffffffffc02026d8:	8b89                	andi	a5,a5,2
ffffffffc02026da:	14079963          	bnez	a5,ffffffffc020282c <pmm_init+0x6c6>
ffffffffc02026de:	000b3783          	ld	a5,0(s6)
ffffffffc02026e2:	4585                	li	a1,1
ffffffffc02026e4:	739c                	ld	a5,32(a5)
ffffffffc02026e6:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02026e8:	00093783          	ld	a5,0(s2)
ffffffffc02026ec:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc02026f0:	12000073          	sfence.vma
ffffffffc02026f4:	100027f3          	csrr	a5,sstatus
ffffffffc02026f8:	8b89                	andi	a5,a5,2
ffffffffc02026fa:	10079f63          	bnez	a5,ffffffffc0202818 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026fe:	000b3783          	ld	a5,0(s6)
ffffffffc0202702:	779c                	ld	a5,40(a5)
ffffffffc0202704:	9782                	jalr	a5
ffffffffc0202706:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202708:	4c8c1e63          	bne	s8,s0,ffffffffc0202be4 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc020270c:	00003517          	auipc	a0,0x3
ffffffffc0202710:	d1c50513          	addi	a0,a0,-740 # ffffffffc0205428 <default_pmm_manager+0x6d8>
ffffffffc0202714:	a81fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202718:	7406                	ld	s0,96(sp)
ffffffffc020271a:	70a6                	ld	ra,104(sp)
ffffffffc020271c:	64e6                	ld	s1,88(sp)
ffffffffc020271e:	6946                	ld	s2,80(sp)
ffffffffc0202720:	69a6                	ld	s3,72(sp)
ffffffffc0202722:	6a06                	ld	s4,64(sp)
ffffffffc0202724:	7ae2                	ld	s5,56(sp)
ffffffffc0202726:	7b42                	ld	s6,48(sp)
ffffffffc0202728:	7ba2                	ld	s7,40(sp)
ffffffffc020272a:	7c02                	ld	s8,32(sp)
ffffffffc020272c:	6ce2                	ld	s9,24(sp)
ffffffffc020272e:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202730:	b72ff06f          	j	ffffffffc0201aa2 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202734:	c80007b7          	lui	a5,0xc8000
ffffffffc0202738:	bc7d                	j	ffffffffc02021f6 <pmm_init+0x90>
        intr_disable();
ffffffffc020273a:	9f6fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020273e:	000b3783          	ld	a5,0(s6)
ffffffffc0202742:	4505                	li	a0,1
ffffffffc0202744:	6f9c                	ld	a5,24(a5)
ffffffffc0202746:	9782                	jalr	a5
ffffffffc0202748:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020274a:	9e0fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020274e:	b9a9                	j	ffffffffc02023a8 <pmm_init+0x242>
        intr_disable();
ffffffffc0202750:	9e0fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202754:	000b3783          	ld	a5,0(s6)
ffffffffc0202758:	4505                	li	a0,1
ffffffffc020275a:	6f9c                	ld	a5,24(a5)
ffffffffc020275c:	9782                	jalr	a5
ffffffffc020275e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202760:	9cafe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202764:	b645                	j	ffffffffc0202304 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202766:	9cafe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020276a:	000b3783          	ld	a5,0(s6)
ffffffffc020276e:	779c                	ld	a5,40(a5)
ffffffffc0202770:	9782                	jalr	a5
ffffffffc0202772:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202774:	9b6fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202778:	b6b9                	j	ffffffffc02022c6 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020277a:	6705                	lui	a4,0x1
ffffffffc020277c:	177d                	addi	a4,a4,-1
ffffffffc020277e:	96ba                	add	a3,a3,a4
ffffffffc0202780:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202782:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202786:	14a77363          	bgeu	a4,a0,ffffffffc02028cc <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc020278a:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc020278e:	fff80537          	lui	a0,0xfff80
ffffffffc0202792:	972a                	add	a4,a4,a0
ffffffffc0202794:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202796:	8c1d                	sub	s0,s0,a5
ffffffffc0202798:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc020279c:	00c45593          	srli	a1,s0,0xc
ffffffffc02027a0:	9532                	add	a0,a0,a2
ffffffffc02027a2:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02027a4:	0009b583          	ld	a1,0(s3)
}
ffffffffc02027a8:	b4c1                	j	ffffffffc0202268 <pmm_init+0x102>
        intr_disable();
ffffffffc02027aa:	986fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02027ae:	000b3783          	ld	a5,0(s6)
ffffffffc02027b2:	779c                	ld	a5,40(a5)
ffffffffc02027b4:	9782                	jalr	a5
ffffffffc02027b6:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02027b8:	972fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027bc:	bb79                	j	ffffffffc020255a <pmm_init+0x3f4>
        intr_disable();
ffffffffc02027be:	972fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc02027c2:	000b3783          	ld	a5,0(s6)
ffffffffc02027c6:	779c                	ld	a5,40(a5)
ffffffffc02027c8:	9782                	jalr	a5
ffffffffc02027ca:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02027cc:	95efe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027d0:	b39d                	j	ffffffffc0202536 <pmm_init+0x3d0>
ffffffffc02027d2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027d4:	95cfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027d8:	000b3783          	ld	a5,0(s6)
ffffffffc02027dc:	6522                	ld	a0,8(sp)
ffffffffc02027de:	4585                	li	a1,1
ffffffffc02027e0:	739c                	ld	a5,32(a5)
ffffffffc02027e2:	9782                	jalr	a5
        intr_enable();
ffffffffc02027e4:	946fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027e8:	b33d                	j	ffffffffc0202516 <pmm_init+0x3b0>
ffffffffc02027ea:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027ec:	944fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc02027f0:	000b3783          	ld	a5,0(s6)
ffffffffc02027f4:	6522                	ld	a0,8(sp)
ffffffffc02027f6:	4585                	li	a1,1
ffffffffc02027f8:	739c                	ld	a5,32(a5)
ffffffffc02027fa:	9782                	jalr	a5
        intr_enable();
ffffffffc02027fc:	92efe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202800:	b1dd                	j	ffffffffc02024e6 <pmm_init+0x380>
        intr_disable();
ffffffffc0202802:	92efe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202806:	000b3783          	ld	a5,0(s6)
ffffffffc020280a:	4505                	li	a0,1
ffffffffc020280c:	6f9c                	ld	a5,24(a5)
ffffffffc020280e:	9782                	jalr	a5
ffffffffc0202810:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202812:	918fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202816:	b36d                	j	ffffffffc02025c0 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202818:	918fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020281c:	000b3783          	ld	a5,0(s6)
ffffffffc0202820:	779c                	ld	a5,40(a5)
ffffffffc0202822:	9782                	jalr	a5
ffffffffc0202824:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202826:	904fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020282a:	bdf9                	j	ffffffffc0202708 <pmm_init+0x5a2>
ffffffffc020282c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020282e:	902fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202832:	000b3783          	ld	a5,0(s6)
ffffffffc0202836:	6522                	ld	a0,8(sp)
ffffffffc0202838:	4585                	li	a1,1
ffffffffc020283a:	739c                	ld	a5,32(a5)
ffffffffc020283c:	9782                	jalr	a5
        intr_enable();
ffffffffc020283e:	8ecfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202842:	b55d                	j	ffffffffc02026e8 <pmm_init+0x582>
ffffffffc0202844:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202846:	8eafe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020284a:	000b3783          	ld	a5,0(s6)
ffffffffc020284e:	6522                	ld	a0,8(sp)
ffffffffc0202850:	4585                	li	a1,1
ffffffffc0202852:	739c                	ld	a5,32(a5)
ffffffffc0202854:	9782                	jalr	a5
        intr_enable();
ffffffffc0202856:	8d4fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020285a:	bdb9                	j	ffffffffc02026b8 <pmm_init+0x552>
        intr_disable();
ffffffffc020285c:	8d4fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202860:	000b3783          	ld	a5,0(s6)
ffffffffc0202864:	4585                	li	a1,1
ffffffffc0202866:	8552                	mv	a0,s4
ffffffffc0202868:	739c                	ld	a5,32(a5)
ffffffffc020286a:	9782                	jalr	a5
        intr_enable();
ffffffffc020286c:	8befe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202870:	bd29                	j	ffffffffc020268a <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202872:	86a2                	mv	a3,s0
ffffffffc0202874:	00002617          	auipc	a2,0x2
ffffffffc0202878:	51460613          	addi	a2,a2,1300 # ffffffffc0204d88 <default_pmm_manager+0x38>
ffffffffc020287c:	1a400593          	li	a1,420
ffffffffc0202880:	00002517          	auipc	a0,0x2
ffffffffc0202884:	62050513          	addi	a0,a0,1568 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202888:	bd3fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020288c:	00003697          	auipc	a3,0x3
ffffffffc0202890:	a3c68693          	addi	a3,a3,-1476 # ffffffffc02052c8 <default_pmm_manager+0x578>
ffffffffc0202894:	00002617          	auipc	a2,0x2
ffffffffc0202898:	10c60613          	addi	a2,a2,268 # ffffffffc02049a0 <commands+0x838>
ffffffffc020289c:	1a500593          	li	a1,421
ffffffffc02028a0:	00002517          	auipc	a0,0x2
ffffffffc02028a4:	60050513          	addi	a0,a0,1536 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc02028a8:	bb3fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02028ac:	00003697          	auipc	a3,0x3
ffffffffc02028b0:	9dc68693          	addi	a3,a3,-1572 # ffffffffc0205288 <default_pmm_manager+0x538>
ffffffffc02028b4:	00002617          	auipc	a2,0x2
ffffffffc02028b8:	0ec60613          	addi	a2,a2,236 # ffffffffc02049a0 <commands+0x838>
ffffffffc02028bc:	1a400593          	li	a1,420
ffffffffc02028c0:	00002517          	auipc	a0,0x2
ffffffffc02028c4:	5e050513          	addi	a0,a0,1504 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc02028c8:	b93fd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc02028cc:	b9cff0ef          	jal	ra,ffffffffc0201c68 <pa2page.part.0>
ffffffffc02028d0:	bb4ff0ef          	jal	ra,ffffffffc0201c84 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028d4:	00002697          	auipc	a3,0x2
ffffffffc02028d8:	7ac68693          	addi	a3,a3,1964 # ffffffffc0205080 <default_pmm_manager+0x330>
ffffffffc02028dc:	00002617          	auipc	a2,0x2
ffffffffc02028e0:	0c460613          	addi	a2,a2,196 # ffffffffc02049a0 <commands+0x838>
ffffffffc02028e4:	17400593          	li	a1,372
ffffffffc02028e8:	00002517          	auipc	a0,0x2
ffffffffc02028ec:	5b850513          	addi	a0,a0,1464 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc02028f0:	b6bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028f4:	00002697          	auipc	a3,0x2
ffffffffc02028f8:	6cc68693          	addi	a3,a3,1740 # ffffffffc0204fc0 <default_pmm_manager+0x270>
ffffffffc02028fc:	00002617          	auipc	a2,0x2
ffffffffc0202900:	0a460613          	addi	a2,a2,164 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202904:	16700593          	li	a1,359
ffffffffc0202908:	00002517          	auipc	a0,0x2
ffffffffc020290c:	59850513          	addi	a0,a0,1432 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202910:	b4bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202914:	00002697          	auipc	a3,0x2
ffffffffc0202918:	66c68693          	addi	a3,a3,1644 # ffffffffc0204f80 <default_pmm_manager+0x230>
ffffffffc020291c:	00002617          	auipc	a2,0x2
ffffffffc0202920:	08460613          	addi	a2,a2,132 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202924:	16600593          	li	a1,358
ffffffffc0202928:	00002517          	auipc	a0,0x2
ffffffffc020292c:	57850513          	addi	a0,a0,1400 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202930:	b2bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202934:	00002697          	auipc	a3,0x2
ffffffffc0202938:	62c68693          	addi	a3,a3,1580 # ffffffffc0204f60 <default_pmm_manager+0x210>
ffffffffc020293c:	00002617          	auipc	a2,0x2
ffffffffc0202940:	06460613          	addi	a2,a2,100 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202944:	16500593          	li	a1,357
ffffffffc0202948:	00002517          	auipc	a0,0x2
ffffffffc020294c:	55850513          	addi	a0,a0,1368 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202950:	b0bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    return KADDR(page2pa(page));
ffffffffc0202954:	00002617          	auipc	a2,0x2
ffffffffc0202958:	43460613          	addi	a2,a2,1076 # ffffffffc0204d88 <default_pmm_manager+0x38>
ffffffffc020295c:	07100593          	li	a1,113
ffffffffc0202960:	00002517          	auipc	a0,0x2
ffffffffc0202964:	45050513          	addi	a0,a0,1104 # ffffffffc0204db0 <default_pmm_manager+0x60>
ffffffffc0202968:	af3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc020296c:	00003697          	auipc	a3,0x3
ffffffffc0202970:	8a468693          	addi	a3,a3,-1884 # ffffffffc0205210 <default_pmm_manager+0x4c0>
ffffffffc0202974:	00002617          	auipc	a2,0x2
ffffffffc0202978:	02c60613          	addi	a2,a2,44 # ffffffffc02049a0 <commands+0x838>
ffffffffc020297c:	18d00593          	li	a1,397
ffffffffc0202980:	00002517          	auipc	a0,0x2
ffffffffc0202984:	52050513          	addi	a0,a0,1312 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202988:	ad3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020298c:	00003697          	auipc	a3,0x3
ffffffffc0202990:	83c68693          	addi	a3,a3,-1988 # ffffffffc02051c8 <default_pmm_manager+0x478>
ffffffffc0202994:	00002617          	auipc	a2,0x2
ffffffffc0202998:	00c60613          	addi	a2,a2,12 # ffffffffc02049a0 <commands+0x838>
ffffffffc020299c:	18b00593          	li	a1,395
ffffffffc02029a0:	00002517          	auipc	a0,0x2
ffffffffc02029a4:	50050513          	addi	a0,a0,1280 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc02029a8:	ab3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02029ac:	00003697          	auipc	a3,0x3
ffffffffc02029b0:	84c68693          	addi	a3,a3,-1972 # ffffffffc02051f8 <default_pmm_manager+0x4a8>
ffffffffc02029b4:	00002617          	auipc	a2,0x2
ffffffffc02029b8:	fec60613          	addi	a2,a2,-20 # ffffffffc02049a0 <commands+0x838>
ffffffffc02029bc:	18a00593          	li	a1,394
ffffffffc02029c0:	00002517          	auipc	a0,0x2
ffffffffc02029c4:	4e050513          	addi	a0,a0,1248 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc02029c8:	a93fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc02029cc:	00003697          	auipc	a3,0x3
ffffffffc02029d0:	91468693          	addi	a3,a3,-1772 # ffffffffc02052e0 <default_pmm_manager+0x590>
ffffffffc02029d4:	00002617          	auipc	a2,0x2
ffffffffc02029d8:	fcc60613          	addi	a2,a2,-52 # ffffffffc02049a0 <commands+0x838>
ffffffffc02029dc:	1a800593          	li	a1,424
ffffffffc02029e0:	00002517          	auipc	a0,0x2
ffffffffc02029e4:	4c050513          	addi	a0,a0,1216 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc02029e8:	a73fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02029ec:	00003697          	auipc	a3,0x3
ffffffffc02029f0:	85468693          	addi	a3,a3,-1964 # ffffffffc0205240 <default_pmm_manager+0x4f0>
ffffffffc02029f4:	00002617          	auipc	a2,0x2
ffffffffc02029f8:	fac60613          	addi	a2,a2,-84 # ffffffffc02049a0 <commands+0x838>
ffffffffc02029fc:	19500593          	li	a1,405
ffffffffc0202a00:	00002517          	auipc	a0,0x2
ffffffffc0202a04:	4a050513          	addi	a0,a0,1184 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202a08:	a53fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202a0c:	00003697          	auipc	a3,0x3
ffffffffc0202a10:	92c68693          	addi	a3,a3,-1748 # ffffffffc0205338 <default_pmm_manager+0x5e8>
ffffffffc0202a14:	00002617          	auipc	a2,0x2
ffffffffc0202a18:	f8c60613          	addi	a2,a2,-116 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202a1c:	1ad00593          	li	a1,429
ffffffffc0202a20:	00002517          	auipc	a0,0x2
ffffffffc0202a24:	48050513          	addi	a0,a0,1152 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202a28:	a33fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a2c:	00003697          	auipc	a3,0x3
ffffffffc0202a30:	8cc68693          	addi	a3,a3,-1844 # ffffffffc02052f8 <default_pmm_manager+0x5a8>
ffffffffc0202a34:	00002617          	auipc	a2,0x2
ffffffffc0202a38:	f6c60613          	addi	a2,a2,-148 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202a3c:	1ac00593          	li	a1,428
ffffffffc0202a40:	00002517          	auipc	a0,0x2
ffffffffc0202a44:	46050513          	addi	a0,a0,1120 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202a48:	a13fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a4c:	00002697          	auipc	a3,0x2
ffffffffc0202a50:	77c68693          	addi	a3,a3,1916 # ffffffffc02051c8 <default_pmm_manager+0x478>
ffffffffc0202a54:	00002617          	auipc	a2,0x2
ffffffffc0202a58:	f4c60613          	addi	a2,a2,-180 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202a5c:	18700593          	li	a1,391
ffffffffc0202a60:	00002517          	auipc	a0,0x2
ffffffffc0202a64:	44050513          	addi	a0,a0,1088 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202a68:	9f3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202a6c:	00002697          	auipc	a3,0x2
ffffffffc0202a70:	5fc68693          	addi	a3,a3,1532 # ffffffffc0205068 <default_pmm_manager+0x318>
ffffffffc0202a74:	00002617          	auipc	a2,0x2
ffffffffc0202a78:	f2c60613          	addi	a2,a2,-212 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202a7c:	18600593          	li	a1,390
ffffffffc0202a80:	00002517          	auipc	a0,0x2
ffffffffc0202a84:	42050513          	addi	a0,a0,1056 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202a88:	9d3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a8c:	00002697          	auipc	a3,0x2
ffffffffc0202a90:	75468693          	addi	a3,a3,1876 # ffffffffc02051e0 <default_pmm_manager+0x490>
ffffffffc0202a94:	00002617          	auipc	a2,0x2
ffffffffc0202a98:	f0c60613          	addi	a2,a2,-244 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202a9c:	18300593          	li	a1,387
ffffffffc0202aa0:	00002517          	auipc	a0,0x2
ffffffffc0202aa4:	40050513          	addi	a0,a0,1024 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202aa8:	9b3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202aac:	00002697          	auipc	a3,0x2
ffffffffc0202ab0:	5a468693          	addi	a3,a3,1444 # ffffffffc0205050 <default_pmm_manager+0x300>
ffffffffc0202ab4:	00002617          	auipc	a2,0x2
ffffffffc0202ab8:	eec60613          	addi	a2,a2,-276 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202abc:	18200593          	li	a1,386
ffffffffc0202ac0:	00002517          	auipc	a0,0x2
ffffffffc0202ac4:	3e050513          	addi	a0,a0,992 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202ac8:	993fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202acc:	00002697          	auipc	a3,0x2
ffffffffc0202ad0:	62468693          	addi	a3,a3,1572 # ffffffffc02050f0 <default_pmm_manager+0x3a0>
ffffffffc0202ad4:	00002617          	auipc	a2,0x2
ffffffffc0202ad8:	ecc60613          	addi	a2,a2,-308 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202adc:	18100593          	li	a1,385
ffffffffc0202ae0:	00002517          	auipc	a0,0x2
ffffffffc0202ae4:	3c050513          	addi	a0,a0,960 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202ae8:	973fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202aec:	00002697          	auipc	a3,0x2
ffffffffc0202af0:	6dc68693          	addi	a3,a3,1756 # ffffffffc02051c8 <default_pmm_manager+0x478>
ffffffffc0202af4:	00002617          	auipc	a2,0x2
ffffffffc0202af8:	eac60613          	addi	a2,a2,-340 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202afc:	18000593          	li	a1,384
ffffffffc0202b00:	00002517          	auipc	a0,0x2
ffffffffc0202b04:	3a050513          	addi	a0,a0,928 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202b08:	953fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202b0c:	00002697          	auipc	a3,0x2
ffffffffc0202b10:	6a468693          	addi	a3,a3,1700 # ffffffffc02051b0 <default_pmm_manager+0x460>
ffffffffc0202b14:	00002617          	auipc	a2,0x2
ffffffffc0202b18:	e8c60613          	addi	a2,a2,-372 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202b1c:	17f00593          	li	a1,383
ffffffffc0202b20:	00002517          	auipc	a0,0x2
ffffffffc0202b24:	38050513          	addi	a0,a0,896 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202b28:	933fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202b2c:	00002697          	auipc	a3,0x2
ffffffffc0202b30:	65468693          	addi	a3,a3,1620 # ffffffffc0205180 <default_pmm_manager+0x430>
ffffffffc0202b34:	00002617          	auipc	a2,0x2
ffffffffc0202b38:	e6c60613          	addi	a2,a2,-404 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202b3c:	17e00593          	li	a1,382
ffffffffc0202b40:	00002517          	auipc	a0,0x2
ffffffffc0202b44:	36050513          	addi	a0,a0,864 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202b48:	913fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202b4c:	00002697          	auipc	a3,0x2
ffffffffc0202b50:	61c68693          	addi	a3,a3,1564 # ffffffffc0205168 <default_pmm_manager+0x418>
ffffffffc0202b54:	00002617          	auipc	a2,0x2
ffffffffc0202b58:	e4c60613          	addi	a2,a2,-436 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202b5c:	17c00593          	li	a1,380
ffffffffc0202b60:	00002517          	auipc	a0,0x2
ffffffffc0202b64:	34050513          	addi	a0,a0,832 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202b68:	8f3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202b6c:	00002697          	auipc	a3,0x2
ffffffffc0202b70:	5dc68693          	addi	a3,a3,1500 # ffffffffc0205148 <default_pmm_manager+0x3f8>
ffffffffc0202b74:	00002617          	auipc	a2,0x2
ffffffffc0202b78:	e2c60613          	addi	a2,a2,-468 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202b7c:	17b00593          	li	a1,379
ffffffffc0202b80:	00002517          	auipc	a0,0x2
ffffffffc0202b84:	32050513          	addi	a0,a0,800 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202b88:	8d3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202b8c:	00002697          	auipc	a3,0x2
ffffffffc0202b90:	5ac68693          	addi	a3,a3,1452 # ffffffffc0205138 <default_pmm_manager+0x3e8>
ffffffffc0202b94:	00002617          	auipc	a2,0x2
ffffffffc0202b98:	e0c60613          	addi	a2,a2,-500 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202b9c:	17a00593          	li	a1,378
ffffffffc0202ba0:	00002517          	auipc	a0,0x2
ffffffffc0202ba4:	30050513          	addi	a0,a0,768 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202ba8:	8b3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202bac:	00002697          	auipc	a3,0x2
ffffffffc0202bb0:	57c68693          	addi	a3,a3,1404 # ffffffffc0205128 <default_pmm_manager+0x3d8>
ffffffffc0202bb4:	00002617          	auipc	a2,0x2
ffffffffc0202bb8:	dec60613          	addi	a2,a2,-532 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202bbc:	17900593          	li	a1,377
ffffffffc0202bc0:	00002517          	auipc	a0,0x2
ffffffffc0202bc4:	2e050513          	addi	a0,a0,736 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202bc8:	893fd0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("DTB memory info not available");
ffffffffc0202bcc:	00002617          	auipc	a2,0x2
ffffffffc0202bd0:	2fc60613          	addi	a2,a2,764 # ffffffffc0204ec8 <default_pmm_manager+0x178>
ffffffffc0202bd4:	06400593          	li	a1,100
ffffffffc0202bd8:	00002517          	auipc	a0,0x2
ffffffffc0202bdc:	2c850513          	addi	a0,a0,712 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202be0:	87bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202be4:	00002697          	auipc	a3,0x2
ffffffffc0202be8:	65c68693          	addi	a3,a3,1628 # ffffffffc0205240 <default_pmm_manager+0x4f0>
ffffffffc0202bec:	00002617          	auipc	a2,0x2
ffffffffc0202bf0:	db460613          	addi	a2,a2,-588 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202bf4:	1bf00593          	li	a1,447
ffffffffc0202bf8:	00002517          	auipc	a0,0x2
ffffffffc0202bfc:	2a850513          	addi	a0,a0,680 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202c00:	85bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202c04:	00002697          	auipc	a3,0x2
ffffffffc0202c08:	4ec68693          	addi	a3,a3,1260 # ffffffffc02050f0 <default_pmm_manager+0x3a0>
ffffffffc0202c0c:	00002617          	auipc	a2,0x2
ffffffffc0202c10:	d9460613          	addi	a2,a2,-620 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202c14:	17800593          	li	a1,376
ffffffffc0202c18:	00002517          	auipc	a0,0x2
ffffffffc0202c1c:	28850513          	addi	a0,a0,648 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202c20:	83bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202c24:	00002697          	auipc	a3,0x2
ffffffffc0202c28:	48c68693          	addi	a3,a3,1164 # ffffffffc02050b0 <default_pmm_manager+0x360>
ffffffffc0202c2c:	00002617          	auipc	a2,0x2
ffffffffc0202c30:	d7460613          	addi	a2,a2,-652 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202c34:	17700593          	li	a1,375
ffffffffc0202c38:	00002517          	auipc	a0,0x2
ffffffffc0202c3c:	26850513          	addi	a0,a0,616 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202c40:	81bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202c44:	86d6                	mv	a3,s5
ffffffffc0202c46:	00002617          	auipc	a2,0x2
ffffffffc0202c4a:	14260613          	addi	a2,a2,322 # ffffffffc0204d88 <default_pmm_manager+0x38>
ffffffffc0202c4e:	17300593          	li	a1,371
ffffffffc0202c52:	00002517          	auipc	a0,0x2
ffffffffc0202c56:	24e50513          	addi	a0,a0,590 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202c5a:	801fd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202c5e:	00002617          	auipc	a2,0x2
ffffffffc0202c62:	12a60613          	addi	a2,a2,298 # ffffffffc0204d88 <default_pmm_manager+0x38>
ffffffffc0202c66:	17200593          	li	a1,370
ffffffffc0202c6a:	00002517          	auipc	a0,0x2
ffffffffc0202c6e:	23650513          	addi	a0,a0,566 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202c72:	fe8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202c76:	00002697          	auipc	a3,0x2
ffffffffc0202c7a:	3f268693          	addi	a3,a3,1010 # ffffffffc0205068 <default_pmm_manager+0x318>
ffffffffc0202c7e:	00002617          	auipc	a2,0x2
ffffffffc0202c82:	d2260613          	addi	a2,a2,-734 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202c86:	17000593          	li	a1,368
ffffffffc0202c8a:	00002517          	auipc	a0,0x2
ffffffffc0202c8e:	21650513          	addi	a0,a0,534 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202c92:	fc8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c96:	00002697          	auipc	a3,0x2
ffffffffc0202c9a:	3ba68693          	addi	a3,a3,954 # ffffffffc0205050 <default_pmm_manager+0x300>
ffffffffc0202c9e:	00002617          	auipc	a2,0x2
ffffffffc0202ca2:	d0260613          	addi	a2,a2,-766 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202ca6:	16f00593          	li	a1,367
ffffffffc0202caa:	00002517          	auipc	a0,0x2
ffffffffc0202cae:	1f650513          	addi	a0,a0,502 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202cb2:	fa8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202cb6:	00002697          	auipc	a3,0x2
ffffffffc0202cba:	74a68693          	addi	a3,a3,1866 # ffffffffc0205400 <default_pmm_manager+0x6b0>
ffffffffc0202cbe:	00002617          	auipc	a2,0x2
ffffffffc0202cc2:	ce260613          	addi	a2,a2,-798 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202cc6:	1b600593          	li	a1,438
ffffffffc0202cca:	00002517          	auipc	a0,0x2
ffffffffc0202cce:	1d650513          	addi	a0,a0,470 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202cd2:	f88fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202cd6:	00002697          	auipc	a3,0x2
ffffffffc0202cda:	6f268693          	addi	a3,a3,1778 # ffffffffc02053c8 <default_pmm_manager+0x678>
ffffffffc0202cde:	00002617          	auipc	a2,0x2
ffffffffc0202ce2:	cc260613          	addi	a2,a2,-830 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202ce6:	1b300593          	li	a1,435
ffffffffc0202cea:	00002517          	auipc	a0,0x2
ffffffffc0202cee:	1b650513          	addi	a0,a0,438 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202cf2:	f68fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202cf6:	00002697          	auipc	a3,0x2
ffffffffc0202cfa:	6a268693          	addi	a3,a3,1698 # ffffffffc0205398 <default_pmm_manager+0x648>
ffffffffc0202cfe:	00002617          	auipc	a2,0x2
ffffffffc0202d02:	ca260613          	addi	a2,a2,-862 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202d06:	1af00593          	li	a1,431
ffffffffc0202d0a:	00002517          	auipc	a0,0x2
ffffffffc0202d0e:	19650513          	addi	a0,a0,406 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202d12:	f48fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202d16:	00002697          	auipc	a3,0x2
ffffffffc0202d1a:	63a68693          	addi	a3,a3,1594 # ffffffffc0205350 <default_pmm_manager+0x600>
ffffffffc0202d1e:	00002617          	auipc	a2,0x2
ffffffffc0202d22:	c8260613          	addi	a2,a2,-894 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202d26:	1ae00593          	li	a1,430
ffffffffc0202d2a:	00002517          	auipc	a0,0x2
ffffffffc0202d2e:	17650513          	addi	a0,a0,374 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202d32:	f28fd0ef          	jal	ra,ffffffffc020045a <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202d36:	00002617          	auipc	a2,0x2
ffffffffc0202d3a:	0fa60613          	addi	a2,a2,250 # ffffffffc0204e30 <default_pmm_manager+0xe0>
ffffffffc0202d3e:	0cb00593          	li	a1,203
ffffffffc0202d42:	00002517          	auipc	a0,0x2
ffffffffc0202d46:	15e50513          	addi	a0,a0,350 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202d4a:	f10fd0ef          	jal	ra,ffffffffc020045a <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202d4e:	00002617          	auipc	a2,0x2
ffffffffc0202d52:	0e260613          	addi	a2,a2,226 # ffffffffc0204e30 <default_pmm_manager+0xe0>
ffffffffc0202d56:	08000593          	li	a1,128
ffffffffc0202d5a:	00002517          	auipc	a0,0x2
ffffffffc0202d5e:	14650513          	addi	a0,a0,326 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202d62:	ef8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202d66:	00002697          	auipc	a3,0x2
ffffffffc0202d6a:	2ba68693          	addi	a3,a3,698 # ffffffffc0205020 <default_pmm_manager+0x2d0>
ffffffffc0202d6e:	00002617          	auipc	a2,0x2
ffffffffc0202d72:	c3260613          	addi	a2,a2,-974 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202d76:	16e00593          	li	a1,366
ffffffffc0202d7a:	00002517          	auipc	a0,0x2
ffffffffc0202d7e:	12650513          	addi	a0,a0,294 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202d82:	ed8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202d86:	00002697          	auipc	a3,0x2
ffffffffc0202d8a:	26a68693          	addi	a3,a3,618 # ffffffffc0204ff0 <default_pmm_manager+0x2a0>
ffffffffc0202d8e:	00002617          	auipc	a2,0x2
ffffffffc0202d92:	c1260613          	addi	a2,a2,-1006 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202d96:	16b00593          	li	a1,363
ffffffffc0202d9a:	00002517          	auipc	a0,0x2
ffffffffc0202d9e:	10650513          	addi	a0,a0,262 # ffffffffc0204ea0 <default_pmm_manager+0x150>
ffffffffc0202da2:	eb8fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202da6 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202da6:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202da8:	00002697          	auipc	a3,0x2
ffffffffc0202dac:	6a068693          	addi	a3,a3,1696 # ffffffffc0205448 <default_pmm_manager+0x6f8>
ffffffffc0202db0:	00002617          	auipc	a2,0x2
ffffffffc0202db4:	bf060613          	addi	a2,a2,-1040 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202db8:	08800593          	li	a1,136
ffffffffc0202dbc:	00002517          	auipc	a0,0x2
ffffffffc0202dc0:	6ac50513          	addi	a0,a0,1708 # ffffffffc0205468 <default_pmm_manager+0x718>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202dc4:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202dc6:	e94fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202dca <find_vma>:
{
ffffffffc0202dca:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0202dcc:	c505                	beqz	a0,ffffffffc0202df4 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0202dce:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202dd0:	c501                	beqz	a0,ffffffffc0202dd8 <find_vma+0xe>
ffffffffc0202dd2:	651c                	ld	a5,8(a0)
ffffffffc0202dd4:	02f5f263          	bgeu	a1,a5,ffffffffc0202df8 <find_vma+0x2e>
    return listelm->next;
ffffffffc0202dd8:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0202dda:	00f68d63          	beq	a3,a5,ffffffffc0202df4 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202dde:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7df2afc>
ffffffffc0202de2:	00e5e663          	bltu	a1,a4,ffffffffc0202dee <find_vma+0x24>
ffffffffc0202de6:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202dea:	00e5ec63          	bltu	a1,a4,ffffffffc0202e02 <find_vma+0x38>
ffffffffc0202dee:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202df0:	fef697e3          	bne	a3,a5,ffffffffc0202dde <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0202df4:	4501                	li	a0,0
}
ffffffffc0202df6:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202df8:	691c                	ld	a5,16(a0)
ffffffffc0202dfa:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0202dd8 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0202dfe:	ea88                	sd	a0,16(a3)
ffffffffc0202e00:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202e02:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202e06:	ea88                	sd	a0,16(a3)
ffffffffc0202e08:	8082                	ret

ffffffffc0202e0a <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e0a:	6590                	ld	a2,8(a1)
ffffffffc0202e0c:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202e10:	1141                	addi	sp,sp,-16
ffffffffc0202e12:	e406                	sd	ra,8(sp)
ffffffffc0202e14:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e16:	01066763          	bltu	a2,a6,ffffffffc0202e24 <insert_vma_struct+0x1a>
ffffffffc0202e1a:	a085                	j	ffffffffc0202e7a <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e1c:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202e20:	04e66863          	bltu	a2,a4,ffffffffc0202e70 <insert_vma_struct+0x66>
ffffffffc0202e24:	86be                	mv	a3,a5
ffffffffc0202e26:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202e28:	fef51ae3          	bne	a0,a5,ffffffffc0202e1c <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202e2c:	02a68463          	beq	a3,a0,ffffffffc0202e54 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202e30:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e34:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202e38:	08e8f163          	bgeu	a7,a4,ffffffffc0202eba <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e3c:	04e66f63          	bltu	a2,a4,ffffffffc0202e9a <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0202e40:	00f50a63          	beq	a0,a5,ffffffffc0202e54 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e44:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e48:	05076963          	bltu	a4,a6,ffffffffc0202e9a <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0202e4c:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202e50:	02c77363          	bgeu	a4,a2,ffffffffc0202e76 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202e54:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202e56:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202e58:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202e5c:	e390                	sd	a2,0(a5)
ffffffffc0202e5e:	e690                	sd	a2,8(a3)
}
ffffffffc0202e60:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202e62:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202e64:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202e66:	0017079b          	addiw	a5,a4,1
ffffffffc0202e6a:	d11c                	sw	a5,32(a0)
}
ffffffffc0202e6c:	0141                	addi	sp,sp,16
ffffffffc0202e6e:	8082                	ret
    if (le_prev != list)
ffffffffc0202e70:	fca690e3          	bne	a3,a0,ffffffffc0202e30 <insert_vma_struct+0x26>
ffffffffc0202e74:	bfd1                	j	ffffffffc0202e48 <insert_vma_struct+0x3e>
ffffffffc0202e76:	f31ff0ef          	jal	ra,ffffffffc0202da6 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e7a:	00002697          	auipc	a3,0x2
ffffffffc0202e7e:	5fe68693          	addi	a3,a3,1534 # ffffffffc0205478 <default_pmm_manager+0x728>
ffffffffc0202e82:	00002617          	auipc	a2,0x2
ffffffffc0202e86:	b1e60613          	addi	a2,a2,-1250 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202e8a:	08e00593          	li	a1,142
ffffffffc0202e8e:	00002517          	auipc	a0,0x2
ffffffffc0202e92:	5da50513          	addi	a0,a0,1498 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc0202e96:	dc4fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e9a:	00002697          	auipc	a3,0x2
ffffffffc0202e9e:	61e68693          	addi	a3,a3,1566 # ffffffffc02054b8 <default_pmm_manager+0x768>
ffffffffc0202ea2:	00002617          	auipc	a2,0x2
ffffffffc0202ea6:	afe60613          	addi	a2,a2,-1282 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202eaa:	08700593          	li	a1,135
ffffffffc0202eae:	00002517          	auipc	a0,0x2
ffffffffc0202eb2:	5ba50513          	addi	a0,a0,1466 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc0202eb6:	da4fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202eba:	00002697          	auipc	a3,0x2
ffffffffc0202ebe:	5de68693          	addi	a3,a3,1502 # ffffffffc0205498 <default_pmm_manager+0x748>
ffffffffc0202ec2:	00002617          	auipc	a2,0x2
ffffffffc0202ec6:	ade60613          	addi	a2,a2,-1314 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202eca:	08600593          	li	a1,134
ffffffffc0202ece:	00002517          	auipc	a0,0x2
ffffffffc0202ed2:	59a50513          	addi	a0,a0,1434 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc0202ed6:	d84fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202eda <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202eda:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202edc:	03000513          	li	a0,48
{
ffffffffc0202ee0:	fc06                	sd	ra,56(sp)
ffffffffc0202ee2:	f822                	sd	s0,48(sp)
ffffffffc0202ee4:	f426                	sd	s1,40(sp)
ffffffffc0202ee6:	f04a                	sd	s2,32(sp)
ffffffffc0202ee8:	ec4e                	sd	s3,24(sp)
ffffffffc0202eea:	e852                	sd	s4,16(sp)
ffffffffc0202eec:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202eee:	bd5fe0ef          	jal	ra,ffffffffc0201ac2 <kmalloc>
    if (mm != NULL)
ffffffffc0202ef2:	2e050f63          	beqz	a0,ffffffffc02031f0 <vmm_init+0x316>
ffffffffc0202ef6:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0202ef8:	e508                	sd	a0,8(a0)
ffffffffc0202efa:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202efc:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202f00:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202f04:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202f08:	02053423          	sd	zero,40(a0)
ffffffffc0202f0c:	03200413          	li	s0,50
ffffffffc0202f10:	a811                	j	ffffffffc0202f24 <vmm_init+0x4a>
        vma->vm_start = vm_start;
ffffffffc0202f12:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202f14:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f16:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0202f1a:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f1c:	8526                	mv	a0,s1
ffffffffc0202f1e:	eedff0ef          	jal	ra,ffffffffc0202e0a <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202f22:	c80d                	beqz	s0,ffffffffc0202f54 <vmm_init+0x7a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f24:	03000513          	li	a0,48
ffffffffc0202f28:	b9bfe0ef          	jal	ra,ffffffffc0201ac2 <kmalloc>
ffffffffc0202f2c:	85aa                	mv	a1,a0
ffffffffc0202f2e:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202f32:	f165                	bnez	a0,ffffffffc0202f12 <vmm_init+0x38>
        assert(vma != NULL);
ffffffffc0202f34:	00002697          	auipc	a3,0x2
ffffffffc0202f38:	71c68693          	addi	a3,a3,1820 # ffffffffc0205650 <default_pmm_manager+0x900>
ffffffffc0202f3c:	00002617          	auipc	a2,0x2
ffffffffc0202f40:	a6460613          	addi	a2,a2,-1436 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202f44:	0db00593          	li	a1,219
ffffffffc0202f48:	00002517          	auipc	a0,0x2
ffffffffc0202f4c:	52050513          	addi	a0,a0,1312 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc0202f50:	d0afd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc0202f54:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f58:	1f900913          	li	s2,505
ffffffffc0202f5c:	a819                	j	ffffffffc0202f72 <vmm_init+0x98>
        vma->vm_start = vm_start;
ffffffffc0202f5e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202f60:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f62:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f66:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f68:	8526                	mv	a0,s1
ffffffffc0202f6a:	ea1ff0ef          	jal	ra,ffffffffc0202e0a <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f6e:	03240a63          	beq	s0,s2,ffffffffc0202fa2 <vmm_init+0xc8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f72:	03000513          	li	a0,48
ffffffffc0202f76:	b4dfe0ef          	jal	ra,ffffffffc0201ac2 <kmalloc>
ffffffffc0202f7a:	85aa                	mv	a1,a0
ffffffffc0202f7c:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202f80:	fd79                	bnez	a0,ffffffffc0202f5e <vmm_init+0x84>
        assert(vma != NULL);
ffffffffc0202f82:	00002697          	auipc	a3,0x2
ffffffffc0202f86:	6ce68693          	addi	a3,a3,1742 # ffffffffc0205650 <default_pmm_manager+0x900>
ffffffffc0202f8a:	00002617          	auipc	a2,0x2
ffffffffc0202f8e:	a1660613          	addi	a2,a2,-1514 # ffffffffc02049a0 <commands+0x838>
ffffffffc0202f92:	0e200593          	li	a1,226
ffffffffc0202f96:	00002517          	auipc	a0,0x2
ffffffffc0202f9a:	4d250513          	addi	a0,a0,1234 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc0202f9e:	cbcfd0ef          	jal	ra,ffffffffc020045a <__panic>
    return listelm->next;
ffffffffc0202fa2:	649c                	ld	a5,8(s1)
ffffffffc0202fa4:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202fa6:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202faa:	18f48363          	beq	s1,a5,ffffffffc0203130 <vmm_init+0x256>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202fae:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202fb2:	ffe70693          	addi	a3,a4,-2 # ffe <kern_entry-0xffffffffc01ff002>
ffffffffc0202fb6:	10d61d63          	bne	a2,a3,ffffffffc02030d0 <vmm_init+0x1f6>
ffffffffc0202fba:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202fbe:	10e69963          	bne	a3,a4,ffffffffc02030d0 <vmm_init+0x1f6>
    for (i = 1; i <= step2; i++)
ffffffffc0202fc2:	0715                	addi	a4,a4,5
ffffffffc0202fc4:	679c                	ld	a5,8(a5)
ffffffffc0202fc6:	feb712e3          	bne	a4,a1,ffffffffc0202faa <vmm_init+0xd0>
ffffffffc0202fca:	4a1d                	li	s4,7
ffffffffc0202fcc:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202fce:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202fd2:	85a2                	mv	a1,s0
ffffffffc0202fd4:	8526                	mv	a0,s1
ffffffffc0202fd6:	df5ff0ef          	jal	ra,ffffffffc0202dca <find_vma>
ffffffffc0202fda:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0202fdc:	18050a63          	beqz	a0,ffffffffc0203170 <vmm_init+0x296>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202fe0:	00140593          	addi	a1,s0,1
ffffffffc0202fe4:	8526                	mv	a0,s1
ffffffffc0202fe6:	de5ff0ef          	jal	ra,ffffffffc0202dca <find_vma>
ffffffffc0202fea:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202fec:	16050263          	beqz	a0,ffffffffc0203150 <vmm_init+0x276>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202ff0:	85d2                	mv	a1,s4
ffffffffc0202ff2:	8526                	mv	a0,s1
ffffffffc0202ff4:	dd7ff0ef          	jal	ra,ffffffffc0202dca <find_vma>
        assert(vma3 == NULL);
ffffffffc0202ff8:	18051c63          	bnez	a0,ffffffffc0203190 <vmm_init+0x2b6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202ffc:	00340593          	addi	a1,s0,3
ffffffffc0203000:	8526                	mv	a0,s1
ffffffffc0203002:	dc9ff0ef          	jal	ra,ffffffffc0202dca <find_vma>
        assert(vma4 == NULL);
ffffffffc0203006:	1c051563          	bnez	a0,ffffffffc02031d0 <vmm_init+0x2f6>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc020300a:	00440593          	addi	a1,s0,4
ffffffffc020300e:	8526                	mv	a0,s1
ffffffffc0203010:	dbbff0ef          	jal	ra,ffffffffc0202dca <find_vma>
        assert(vma5 == NULL);
ffffffffc0203014:	18051e63          	bnez	a0,ffffffffc02031b0 <vmm_init+0x2d6>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203018:	00893783          	ld	a5,8(s2)
ffffffffc020301c:	0c879a63          	bne	a5,s0,ffffffffc02030f0 <vmm_init+0x216>
ffffffffc0203020:	01093783          	ld	a5,16(s2)
ffffffffc0203024:	0d479663          	bne	a5,s4,ffffffffc02030f0 <vmm_init+0x216>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203028:	0089b783          	ld	a5,8(s3)
ffffffffc020302c:	0e879263          	bne	a5,s0,ffffffffc0203110 <vmm_init+0x236>
ffffffffc0203030:	0109b783          	ld	a5,16(s3)
ffffffffc0203034:	0d479e63          	bne	a5,s4,ffffffffc0203110 <vmm_init+0x236>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203038:	0415                	addi	s0,s0,5
ffffffffc020303a:	0a15                	addi	s4,s4,5
ffffffffc020303c:	f9541be3          	bne	s0,s5,ffffffffc0202fd2 <vmm_init+0xf8>
ffffffffc0203040:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203042:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203044:	85a2                	mv	a1,s0
ffffffffc0203046:	8526                	mv	a0,s1
ffffffffc0203048:	d83ff0ef          	jal	ra,ffffffffc0202dca <find_vma>
ffffffffc020304c:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203050:	c90d                	beqz	a0,ffffffffc0203082 <vmm_init+0x1a8>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203052:	6914                	ld	a3,16(a0)
ffffffffc0203054:	6510                	ld	a2,8(a0)
ffffffffc0203056:	00002517          	auipc	a0,0x2
ffffffffc020305a:	58250513          	addi	a0,a0,1410 # ffffffffc02055d8 <default_pmm_manager+0x888>
ffffffffc020305e:	936fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203062:	00002697          	auipc	a3,0x2
ffffffffc0203066:	59e68693          	addi	a3,a3,1438 # ffffffffc0205600 <default_pmm_manager+0x8b0>
ffffffffc020306a:	00002617          	auipc	a2,0x2
ffffffffc020306e:	93660613          	addi	a2,a2,-1738 # ffffffffc02049a0 <commands+0x838>
ffffffffc0203072:	10800593          	li	a1,264
ffffffffc0203076:	00002517          	auipc	a0,0x2
ffffffffc020307a:	3f250513          	addi	a0,a0,1010 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc020307e:	bdcfd0ef          	jal	ra,ffffffffc020045a <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203082:	147d                	addi	s0,s0,-1
ffffffffc0203084:	fd2410e3          	bne	s0,s2,ffffffffc0203044 <vmm_init+0x16a>
ffffffffc0203088:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc020308a:	00a48c63          	beq	s1,a0,ffffffffc02030a2 <vmm_init+0x1c8>
    __list_del(listelm->prev, listelm->next);
ffffffffc020308e:	6118                	ld	a4,0(a0)
ffffffffc0203090:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203092:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203094:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203096:	e398                	sd	a4,0(a5)
ffffffffc0203098:	adbfe0ef          	jal	ra,ffffffffc0201b72 <kfree>
    return listelm->next;
ffffffffc020309c:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc020309e:	fea498e3          	bne	s1,a0,ffffffffc020308e <vmm_init+0x1b4>
    kfree(mm); // kfree mm
ffffffffc02030a2:	8526                	mv	a0,s1
ffffffffc02030a4:	acffe0ef          	jal	ra,ffffffffc0201b72 <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02030a8:	00002517          	auipc	a0,0x2
ffffffffc02030ac:	57050513          	addi	a0,a0,1392 # ffffffffc0205618 <default_pmm_manager+0x8c8>
ffffffffc02030b0:	8e4fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc02030b4:	7442                	ld	s0,48(sp)
ffffffffc02030b6:	70e2                	ld	ra,56(sp)
ffffffffc02030b8:	74a2                	ld	s1,40(sp)
ffffffffc02030ba:	7902                	ld	s2,32(sp)
ffffffffc02030bc:	69e2                	ld	s3,24(sp)
ffffffffc02030be:	6a42                	ld	s4,16(sp)
ffffffffc02030c0:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02030c2:	00002517          	auipc	a0,0x2
ffffffffc02030c6:	57650513          	addi	a0,a0,1398 # ffffffffc0205638 <default_pmm_manager+0x8e8>
}
ffffffffc02030ca:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02030cc:	8c8fd06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02030d0:	00002697          	auipc	a3,0x2
ffffffffc02030d4:	42068693          	addi	a3,a3,1056 # ffffffffc02054f0 <default_pmm_manager+0x7a0>
ffffffffc02030d8:	00002617          	auipc	a2,0x2
ffffffffc02030dc:	8c860613          	addi	a2,a2,-1848 # ffffffffc02049a0 <commands+0x838>
ffffffffc02030e0:	0ec00593          	li	a1,236
ffffffffc02030e4:	00002517          	auipc	a0,0x2
ffffffffc02030e8:	38450513          	addi	a0,a0,900 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc02030ec:	b6efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc02030f0:	00002697          	auipc	a3,0x2
ffffffffc02030f4:	48868693          	addi	a3,a3,1160 # ffffffffc0205578 <default_pmm_manager+0x828>
ffffffffc02030f8:	00002617          	auipc	a2,0x2
ffffffffc02030fc:	8a860613          	addi	a2,a2,-1880 # ffffffffc02049a0 <commands+0x838>
ffffffffc0203100:	0fd00593          	li	a1,253
ffffffffc0203104:	00002517          	auipc	a0,0x2
ffffffffc0203108:	36450513          	addi	a0,a0,868 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc020310c:	b4efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203110:	00002697          	auipc	a3,0x2
ffffffffc0203114:	49868693          	addi	a3,a3,1176 # ffffffffc02055a8 <default_pmm_manager+0x858>
ffffffffc0203118:	00002617          	auipc	a2,0x2
ffffffffc020311c:	88860613          	addi	a2,a2,-1912 # ffffffffc02049a0 <commands+0x838>
ffffffffc0203120:	0fe00593          	li	a1,254
ffffffffc0203124:	00002517          	auipc	a0,0x2
ffffffffc0203128:	34450513          	addi	a0,a0,836 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc020312c:	b2efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203130:	00002697          	auipc	a3,0x2
ffffffffc0203134:	3a868693          	addi	a3,a3,936 # ffffffffc02054d8 <default_pmm_manager+0x788>
ffffffffc0203138:	00002617          	auipc	a2,0x2
ffffffffc020313c:	86860613          	addi	a2,a2,-1944 # ffffffffc02049a0 <commands+0x838>
ffffffffc0203140:	0ea00593          	li	a1,234
ffffffffc0203144:	00002517          	auipc	a0,0x2
ffffffffc0203148:	32450513          	addi	a0,a0,804 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc020314c:	b0efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2 != NULL);
ffffffffc0203150:	00002697          	auipc	a3,0x2
ffffffffc0203154:	3e868693          	addi	a3,a3,1000 # ffffffffc0205538 <default_pmm_manager+0x7e8>
ffffffffc0203158:	00002617          	auipc	a2,0x2
ffffffffc020315c:	84860613          	addi	a2,a2,-1976 # ffffffffc02049a0 <commands+0x838>
ffffffffc0203160:	0f500593          	li	a1,245
ffffffffc0203164:	00002517          	auipc	a0,0x2
ffffffffc0203168:	30450513          	addi	a0,a0,772 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc020316c:	aeefd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1 != NULL);
ffffffffc0203170:	00002697          	auipc	a3,0x2
ffffffffc0203174:	3b868693          	addi	a3,a3,952 # ffffffffc0205528 <default_pmm_manager+0x7d8>
ffffffffc0203178:	00002617          	auipc	a2,0x2
ffffffffc020317c:	82860613          	addi	a2,a2,-2008 # ffffffffc02049a0 <commands+0x838>
ffffffffc0203180:	0f300593          	li	a1,243
ffffffffc0203184:	00002517          	auipc	a0,0x2
ffffffffc0203188:	2e450513          	addi	a0,a0,740 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc020318c:	acefd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma3 == NULL);
ffffffffc0203190:	00002697          	auipc	a3,0x2
ffffffffc0203194:	3b868693          	addi	a3,a3,952 # ffffffffc0205548 <default_pmm_manager+0x7f8>
ffffffffc0203198:	00002617          	auipc	a2,0x2
ffffffffc020319c:	80860613          	addi	a2,a2,-2040 # ffffffffc02049a0 <commands+0x838>
ffffffffc02031a0:	0f700593          	li	a1,247
ffffffffc02031a4:	00002517          	auipc	a0,0x2
ffffffffc02031a8:	2c450513          	addi	a0,a0,708 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc02031ac:	aaefd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma5 == NULL);
ffffffffc02031b0:	00002697          	auipc	a3,0x2
ffffffffc02031b4:	3b868693          	addi	a3,a3,952 # ffffffffc0205568 <default_pmm_manager+0x818>
ffffffffc02031b8:	00001617          	auipc	a2,0x1
ffffffffc02031bc:	7e860613          	addi	a2,a2,2024 # ffffffffc02049a0 <commands+0x838>
ffffffffc02031c0:	0fb00593          	li	a1,251
ffffffffc02031c4:	00002517          	auipc	a0,0x2
ffffffffc02031c8:	2a450513          	addi	a0,a0,676 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc02031cc:	a8efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma4 == NULL);
ffffffffc02031d0:	00002697          	auipc	a3,0x2
ffffffffc02031d4:	38868693          	addi	a3,a3,904 # ffffffffc0205558 <default_pmm_manager+0x808>
ffffffffc02031d8:	00001617          	auipc	a2,0x1
ffffffffc02031dc:	7c860613          	addi	a2,a2,1992 # ffffffffc02049a0 <commands+0x838>
ffffffffc02031e0:	0f900593          	li	a1,249
ffffffffc02031e4:	00002517          	auipc	a0,0x2
ffffffffc02031e8:	28450513          	addi	a0,a0,644 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc02031ec:	a6efd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(mm != NULL);
ffffffffc02031f0:	00002697          	auipc	a3,0x2
ffffffffc02031f4:	47068693          	addi	a3,a3,1136 # ffffffffc0205660 <default_pmm_manager+0x910>
ffffffffc02031f8:	00001617          	auipc	a2,0x1
ffffffffc02031fc:	7a860613          	addi	a2,a2,1960 # ffffffffc02049a0 <commands+0x838>
ffffffffc0203200:	0d300593          	li	a1,211
ffffffffc0203204:	00002517          	auipc	a0,0x2
ffffffffc0203208:	26450513          	addi	a0,a0,612 # ffffffffc0205468 <default_pmm_manager+0x718>
ffffffffc020320c:	a4efd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203210 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203210:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203212:	9402                	jalr	s0

	jal do_exit
ffffffffc0203214:	46e000ef          	jal	ra,ffffffffc0203682 <do_exit>

ffffffffc0203218 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203218:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020321a:	0e800513          	li	a0,232
{
ffffffffc020321e:	e022                	sd	s0,0(sp)
ffffffffc0203220:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203222:	8a1fe0ef          	jal	ra,ffffffffc0201ac2 <kmalloc>
ffffffffc0203226:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203228:	c12d                	beqz	a0,ffffffffc020328a <alloc_proc+0x72>
         *       uint32_t flags;               // 进程标志位
         *       char name[PROC_NAME_LEN + 1]; // 进程名
         */
        
        //清空整个结构（其实这里偷鸡一下，从打印初始化的条件可以直接看出每个值的处理），666
        memset(proc, 0, sizeof(struct proc_struct));
ffffffffc020322a:	0e800613          	li	a2,232
ffffffffc020322e:	4581                	li	a1,0
ffffffffc0203230:	47d000ef          	jal	ra,ffffffffc0203eac <memset>
        proc->state = PROC_UNINIT;
ffffffffc0203234:	57fd                	li	a5,-1
ffffffffc0203236:	1782                	slli	a5,a5,0x20
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&proc->context, 0, sizeof(proc->context));
ffffffffc0203238:	07000613          	li	a2,112
ffffffffc020323c:	4581                	li	a1,0
        proc->state = PROC_UNINIT;
ffffffffc020323e:	e01c                	sd	a5,0(s0)
        proc->runs = 0;
ffffffffc0203240:	00042423          	sw	zero,8(s0)
        proc->kstack = 0;
ffffffffc0203244:	00043823          	sd	zero,16(s0)
        proc->need_resched = 0;
ffffffffc0203248:	00042c23          	sw	zero,24(s0)
        proc->parent = NULL;
ffffffffc020324c:	02043023          	sd	zero,32(s0)
        proc->mm = NULL;
ffffffffc0203250:	02043423          	sd	zero,40(s0)
        memset(&proc->context, 0, sizeof(proc->context));
ffffffffc0203254:	03040513          	addi	a0,s0,48
ffffffffc0203258:	455000ef          	jal	ra,ffffffffc0203eac <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc020325c:	0000a797          	auipc	a5,0xa
ffffffffc0203260:	2447b783          	ld	a5,580(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
ffffffffc0203264:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;
ffffffffc0203266:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc020326a:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc020326e:	4641                	li	a2,16
ffffffffc0203270:	4581                	li	a1,0
ffffffffc0203272:	0b440513          	addi	a0,s0,180
ffffffffc0203276:	437000ef          	jal	ra,ffffffffc0203eac <memset>
        list_init(&proc->list_link);
ffffffffc020327a:	0c840713          	addi	a4,s0,200
        list_init(&proc->hash_link);
ffffffffc020327e:	0d840793          	addi	a5,s0,216
    elm->prev = elm->next = elm;
ffffffffc0203282:	e878                	sd	a4,208(s0)
ffffffffc0203284:	e478                	sd	a4,200(s0)
ffffffffc0203286:	f07c                	sd	a5,224(s0)
ffffffffc0203288:	ec7c                	sd	a5,216(s0)
    }
    return proc;
}
ffffffffc020328a:	60a2                	ld	ra,8(sp)
ffffffffc020328c:	8522                	mv	a0,s0
ffffffffc020328e:	6402                	ld	s0,0(sp)
ffffffffc0203290:	0141                	addi	sp,sp,16
ffffffffc0203292:	8082                	ret

ffffffffc0203294 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203294:	0000a797          	auipc	a5,0xa
ffffffffc0203298:	23c7b783          	ld	a5,572(a5) # ffffffffc020d4d0 <current>
ffffffffc020329c:	73c8                	ld	a0,160(a5)
ffffffffc020329e:	b43fd06f          	j	ffffffffc0200de0 <forkrets>

ffffffffc02032a2 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02032a2:	7179                	addi	sp,sp,-48
ffffffffc02032a4:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc02032a6:	0000a497          	auipc	s1,0xa
ffffffffc02032aa:	1a248493          	addi	s1,s1,418 # ffffffffc020d448 <name.2>
{
ffffffffc02032ae:	f022                	sd	s0,32(sp)
ffffffffc02032b0:	e84a                	sd	s2,16(sp)
ffffffffc02032b2:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032b4:	0000a917          	auipc	s2,0xa
ffffffffc02032b8:	21c93903          	ld	s2,540(s2) # ffffffffc020d4d0 <current>
    memset(name, 0, sizeof(name));
ffffffffc02032bc:	4641                	li	a2,16
ffffffffc02032be:	4581                	li	a1,0
ffffffffc02032c0:	8526                	mv	a0,s1
{
ffffffffc02032c2:	f406                	sd	ra,40(sp)
ffffffffc02032c4:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032c6:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));
ffffffffc02032ca:	3e3000ef          	jal	ra,ffffffffc0203eac <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc02032ce:	0b490593          	addi	a1,s2,180
ffffffffc02032d2:	463d                	li	a2,15
ffffffffc02032d4:	8526                	mv	a0,s1
ffffffffc02032d6:	3e9000ef          	jal	ra,ffffffffc0203ebe <memcpy>
ffffffffc02032da:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032dc:	85ce                	mv	a1,s3
ffffffffc02032de:	00002517          	auipc	a0,0x2
ffffffffc02032e2:	39250513          	addi	a0,a0,914 # ffffffffc0205670 <default_pmm_manager+0x920>
ffffffffc02032e6:	eaffc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc02032ea:	85a2                	mv	a1,s0
ffffffffc02032ec:	00002517          	auipc	a0,0x2
ffffffffc02032f0:	3ac50513          	addi	a0,a0,940 # ffffffffc0205698 <default_pmm_manager+0x948>
ffffffffc02032f4:	ea1fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc02032f8:	00002517          	auipc	a0,0x2
ffffffffc02032fc:	3b050513          	addi	a0,a0,944 # ffffffffc02056a8 <default_pmm_manager+0x958>
ffffffffc0203300:	e95fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0203304:	70a2                	ld	ra,40(sp)
ffffffffc0203306:	7402                	ld	s0,32(sp)
ffffffffc0203308:	64e2                	ld	s1,24(sp)
ffffffffc020330a:	6942                	ld	s2,16(sp)
ffffffffc020330c:	69a2                	ld	s3,8(sp)
ffffffffc020330e:	4501                	li	a0,0
ffffffffc0203310:	6145                	addi	sp,sp,48
ffffffffc0203312:	8082                	ret

ffffffffc0203314 <proc_run>:
{
ffffffffc0203314:	7179                	addi	sp,sp,-48
ffffffffc0203316:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203318:	0000a497          	auipc	s1,0xa
ffffffffc020331c:	1b848493          	addi	s1,s1,440 # ffffffffc020d4d0 <current>
ffffffffc0203320:	6098                	ld	a4,0(s1)
{
ffffffffc0203322:	f406                	sd	ra,40(sp)
ffffffffc0203324:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203326:	02a70863          	beq	a4,a0,ffffffffc0203356 <proc_run+0x42>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020332a:	100027f3          	csrr	a5,sstatus
ffffffffc020332e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203330:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203332:	ef8d                	bnez	a5,ffffffffc020336c <proc_run+0x58>
            lsatp(proc->pgdir);
ffffffffc0203334:	755c                	ld	a5,168(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203336:	800006b7          	lui	a3,0x80000
            current = proc;
ffffffffc020333a:	e088                	sd	a0,0(s1)
ffffffffc020333c:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc0203340:	8fd5                	or	a5,a5,a3
ffffffffc0203342:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(proc->context));
ffffffffc0203346:	03050593          	addi	a1,a0,48
ffffffffc020334a:	03070513          	addi	a0,a4,48
ffffffffc020334e:	5ba000ef          	jal	ra,ffffffffc0203908 <switch_to>
    if (flag) {
ffffffffc0203352:	00091763          	bnez	s2,ffffffffc0203360 <proc_run+0x4c>
}
ffffffffc0203356:	70a2                	ld	ra,40(sp)
ffffffffc0203358:	7482                	ld	s1,32(sp)
ffffffffc020335a:	6962                	ld	s2,24(sp)
ffffffffc020335c:	6145                	addi	sp,sp,48
ffffffffc020335e:	8082                	ret
ffffffffc0203360:	70a2                	ld	ra,40(sp)
ffffffffc0203362:	7482                	ld	s1,32(sp)
ffffffffc0203364:	6962                	ld	s2,24(sp)
ffffffffc0203366:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203368:	dc2fd06f          	j	ffffffffc020092a <intr_enable>
ffffffffc020336c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020336e:	dc2fd0ef          	jal	ra,ffffffffc0200930 <intr_disable>
            struct proc_struct *prev = current;
ffffffffc0203372:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0203374:	6522                	ld	a0,8(sp)
ffffffffc0203376:	4905                	li	s2,1
ffffffffc0203378:	bf75                	j	ffffffffc0203334 <proc_run+0x20>

ffffffffc020337a <do_fork>:
{
ffffffffc020337a:	7179                	addi	sp,sp,-48
ffffffffc020337c:	ec26                	sd	s1,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020337e:	0000a497          	auipc	s1,0xa
ffffffffc0203382:	16a48493          	addi	s1,s1,362 # ffffffffc020d4e8 <nr_process>
ffffffffc0203386:	4098                	lw	a4,0(s1)
{
ffffffffc0203388:	f406                	sd	ra,40(sp)
ffffffffc020338a:	f022                	sd	s0,32(sp)
ffffffffc020338c:	e84a                	sd	s2,16(sp)
ffffffffc020338e:	e44e                	sd	s3,8(sp)
ffffffffc0203390:	e052                	sd	s4,0(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203392:	6785                	lui	a5,0x1
ffffffffc0203394:	24f75c63          	bge	a4,a5,ffffffffc02035ec <do_fork+0x272>
ffffffffc0203398:	892e                	mv	s2,a1
ffffffffc020339a:	8432                	mv	s0,a2
    proc = alloc_proc();
ffffffffc020339c:	e7dff0ef          	jal	ra,ffffffffc0203218 <alloc_proc>
ffffffffc02033a0:	89aa                	mv	s3,a0
    if(proc == NULL)
ffffffffc02033a2:	24050a63          	beqz	a0,ffffffffc02035f6 <do_fork+0x27c>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02033a6:	4509                	li	a0,2
ffffffffc02033a8:	8f9fe0ef          	jal	ra,ffffffffc0201ca0 <alloc_pages>
    if (page != NULL)
ffffffffc02033ac:	22050b63          	beqz	a0,ffffffffc02035e2 <do_fork+0x268>
    return page - pages + nbase;
ffffffffc02033b0:	0000a697          	auipc	a3,0xa
ffffffffc02033b4:	1086b683          	ld	a3,264(a3) # ffffffffc020d4b8 <pages>
ffffffffc02033b8:	40d506b3          	sub	a3,a0,a3
ffffffffc02033bc:	8699                	srai	a3,a3,0x6
ffffffffc02033be:	00002517          	auipc	a0,0x2
ffffffffc02033c2:	65253503          	ld	a0,1618(a0) # ffffffffc0205a10 <nbase>
ffffffffc02033c6:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc02033c8:	00c69793          	slli	a5,a3,0xc
ffffffffc02033cc:	83b1                	srli	a5,a5,0xc
ffffffffc02033ce:	0000a717          	auipc	a4,0xa
ffffffffc02033d2:	0e273703          	ld	a4,226(a4) # ffffffffc020d4b0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02033d6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02033d8:	24e7f163          	bgeu	a5,a4,ffffffffc020361a <do_fork+0x2a0>
    assert(current->mm == NULL);
ffffffffc02033dc:	0000aa17          	auipc	s4,0xa
ffffffffc02033e0:	0f4a0a13          	addi	s4,s4,244 # ffffffffc020d4d0 <current>
ffffffffc02033e4:	000a3303          	ld	t1,0(s4)
ffffffffc02033e8:	0000a797          	auipc	a5,0xa
ffffffffc02033ec:	0e07b783          	ld	a5,224(a5) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc02033f0:	96be                	add	a3,a3,a5
ffffffffc02033f2:	02833783          	ld	a5,40(t1)
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02033f6:	00d9b823          	sd	a3,16(s3)
    assert(current->mm == NULL);
ffffffffc02033fa:	20079063          	bnez	a5,ffffffffc02035fa <do_fork+0x280>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033fe:	6789                	lui	a5,0x2
ffffffffc0203400:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc0203404:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0203406:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0203408:	0ad9b023          	sd	a3,160(s3)
    *(proc->tf) = *tf;
ffffffffc020340c:	87b6                	mv	a5,a3
ffffffffc020340e:	12040893          	addi	a7,s0,288
ffffffffc0203412:	00063803          	ld	a6,0(a2)
ffffffffc0203416:	6608                	ld	a0,8(a2)
ffffffffc0203418:	6a0c                	ld	a1,16(a2)
ffffffffc020341a:	6e18                	ld	a4,24(a2)
ffffffffc020341c:	0107b023          	sd	a6,0(a5)
ffffffffc0203420:	e788                	sd	a0,8(a5)
ffffffffc0203422:	eb8c                	sd	a1,16(a5)
ffffffffc0203424:	ef98                	sd	a4,24(a5)
ffffffffc0203426:	02060613          	addi	a2,a2,32
ffffffffc020342a:	02078793          	addi	a5,a5,32
ffffffffc020342e:	ff1612e3          	bne	a2,a7,ffffffffc0203412 <do_fork+0x98>
    proc->tf->gpr.a0 = 0;
ffffffffc0203432:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203436:	10090f63          	beqz	s2,ffffffffc0203554 <do_fork+0x1da>
ffffffffc020343a:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020343e:	00000797          	auipc	a5,0x0
ffffffffc0203442:	e5678793          	addi	a5,a5,-426 # ffffffffc0203294 <forkret>
ffffffffc0203446:	02f9b823          	sd	a5,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020344a:	02d9bc23          	sd	a3,56(s3)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020344e:	100027f3          	csrr	a5,sstatus
ffffffffc0203452:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203454:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203456:	12079063          	bnez	a5,ffffffffc0203576 <do_fork+0x1fc>
    if (++last_pid >= MAX_PID)
ffffffffc020345a:	00006817          	auipc	a6,0x6
ffffffffc020345e:	bce80813          	addi	a6,a6,-1074 # ffffffffc0209028 <last_pid.1>
ffffffffc0203462:	00082783          	lw	a5,0(a6)
        proc->parent = current;
ffffffffc0203466:	0269b023          	sd	t1,32(s3)
    if (++last_pid >= MAX_PID)
ffffffffc020346a:	6709                	lui	a4,0x2
ffffffffc020346c:	0017851b          	addiw	a0,a5,1
ffffffffc0203470:	00a82023          	sw	a0,0(a6)
ffffffffc0203474:	12e55563          	bge	a0,a4,ffffffffc020359e <do_fork+0x224>
    if (last_pid >= next_safe)
ffffffffc0203478:	00006317          	auipc	t1,0x6
ffffffffc020347c:	bb430313          	addi	t1,t1,-1100 # ffffffffc020902c <next_safe.0>
ffffffffc0203480:	00032783          	lw	a5,0(t1)
ffffffffc0203484:	0000a417          	auipc	s0,0xa
ffffffffc0203488:	fd440413          	addi	s0,s0,-44 # ffffffffc020d458 <proc_list>
ffffffffc020348c:	06f54063          	blt	a0,a5,ffffffffc02034ec <do_fork+0x172>
    return listelm->next;
ffffffffc0203490:	0000a417          	auipc	s0,0xa
ffffffffc0203494:	fc840413          	addi	s0,s0,-56 # ffffffffc020d458 <proc_list>
ffffffffc0203498:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc020349c:	6789                	lui	a5,0x2
ffffffffc020349e:	00f32023          	sw	a5,0(t1)
ffffffffc02034a2:	86aa                	mv	a3,a0
ffffffffc02034a4:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02034a6:	6e89                	lui	t4,0x2
ffffffffc02034a8:	128e0863          	beq	t3,s0,ffffffffc02035d8 <do_fork+0x25e>
ffffffffc02034ac:	88ae                	mv	a7,a1
ffffffffc02034ae:	87f2                	mv	a5,t3
ffffffffc02034b0:	6609                	lui	a2,0x2
ffffffffc02034b2:	a811                	j	ffffffffc02034c6 <do_fork+0x14c>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02034b4:	00e6d663          	bge	a3,a4,ffffffffc02034c0 <do_fork+0x146>
ffffffffc02034b8:	00c75463          	bge	a4,a2,ffffffffc02034c0 <do_fork+0x146>
ffffffffc02034bc:	863a                	mv	a2,a4
ffffffffc02034be:	4885                	li	a7,1
ffffffffc02034c0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02034c2:	00878d63          	beq	a5,s0,ffffffffc02034dc <do_fork+0x162>
            if (proc->pid == last_pid)
ffffffffc02034c6:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc02034ca:	fed715e3          	bne	a4,a3,ffffffffc02034b4 <do_fork+0x13a>
                if (++last_pid >= next_safe)
ffffffffc02034ce:	2685                	addiw	a3,a3,1
ffffffffc02034d0:	0ec6df63          	bge	a3,a2,ffffffffc02035ce <do_fork+0x254>
ffffffffc02034d4:	679c                	ld	a5,8(a5)
ffffffffc02034d6:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02034d8:	fe8797e3          	bne	a5,s0,ffffffffc02034c6 <do_fork+0x14c>
ffffffffc02034dc:	c581                	beqz	a1,ffffffffc02034e4 <do_fork+0x16a>
ffffffffc02034de:	00d82023          	sw	a3,0(a6)
ffffffffc02034e2:	8536                	mv	a0,a3
ffffffffc02034e4:	00088463          	beqz	a7,ffffffffc02034ec <do_fork+0x172>
ffffffffc02034e8:	00c32023          	sw	a2,0(t1)
        proc->pid = get_pid();
ffffffffc02034ec:	00a9a223          	sw	a0,4(s3)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02034f0:	45a9                	li	a1,10
ffffffffc02034f2:	2501                	sext.w	a0,a0
ffffffffc02034f4:	512000ef          	jal	ra,ffffffffc0203a06 <hash32>
ffffffffc02034f8:	02051793          	slli	a5,a0,0x20
ffffffffc02034fc:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0203500:	00006797          	auipc	a5,0x6
ffffffffc0203504:	f4878793          	addi	a5,a5,-184 # ffffffffc0209448 <hash_list>
ffffffffc0203508:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc020350a:	6510                	ld	a2,8(a0)
ffffffffc020350c:	0d898793          	addi	a5,s3,216
ffffffffc0203510:	6414                	ld	a3,8(s0)
    prev->next = next->prev = elm;
ffffffffc0203512:	e21c                	sd	a5,0(a2)
ffffffffc0203514:	e51c                	sd	a5,8(a0)
        nr_process++;
ffffffffc0203516:	4098                	lw	a4,0(s1)
        list_add(&proc_list, &proc->list_link);
ffffffffc0203518:	0c898793          	addi	a5,s3,200
    elm->next = next;
ffffffffc020351c:	0ec9b023          	sd	a2,224(s3)
    elm->prev = prev;
ffffffffc0203520:	0ca9bc23          	sd	a0,216(s3)
    prev->next = next->prev = elm;
ffffffffc0203524:	e29c                	sd	a5,0(a3)
ffffffffc0203526:	e41c                	sd	a5,8(s0)
        nr_process++;
ffffffffc0203528:	0017079b          	addiw	a5,a4,1
ffffffffc020352c:	c09c                	sw	a5,0(s1)
        proc->state = PROC_RUNNABLE;
ffffffffc020352e:	4789                	li	a5,2
    elm->next = next;
ffffffffc0203530:	0cd9b823          	sd	a3,208(s3)
    elm->prev = prev;
ffffffffc0203534:	0c89b423          	sd	s0,200(s3)
ffffffffc0203538:	00f9a023          	sw	a5,0(s3)
    if (flag) {
ffffffffc020353c:	08091663          	bnez	s2,ffffffffc02035c8 <do_fork+0x24e>
    ret = proc->pid;
ffffffffc0203540:	0049a503          	lw	a0,4(s3)
}
ffffffffc0203544:	70a2                	ld	ra,40(sp)
ffffffffc0203546:	7402                	ld	s0,32(sp)
ffffffffc0203548:	64e2                	ld	s1,24(sp)
ffffffffc020354a:	6942                	ld	s2,16(sp)
ffffffffc020354c:	69a2                	ld	s3,8(sp)
ffffffffc020354e:	6a02                	ld	s4,0(sp)
ffffffffc0203550:	6145                	addi	sp,sp,48
ffffffffc0203552:	8082                	ret
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203554:	8936                	mv	s2,a3
ffffffffc0203556:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020355a:	00000797          	auipc	a5,0x0
ffffffffc020355e:	d3a78793          	addi	a5,a5,-710 # ffffffffc0203294 <forkret>
ffffffffc0203562:	02f9b823          	sd	a5,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203566:	02d9bc23          	sd	a3,56(s3)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020356a:	100027f3          	csrr	a5,sstatus
ffffffffc020356e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203570:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203572:	ee0784e3          	beqz	a5,ffffffffc020345a <do_fork+0xe0>
        intr_disable();
ffffffffc0203576:	bbafd0ef          	jal	ra,ffffffffc0200930 <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc020357a:	00006817          	auipc	a6,0x6
ffffffffc020357e:	aae80813          	addi	a6,a6,-1362 # ffffffffc0209028 <last_pid.1>
ffffffffc0203582:	00082783          	lw	a5,0(a6)
        proc->parent = current;
ffffffffc0203586:	000a3303          	ld	t1,0(s4)
    if (++last_pid >= MAX_PID)
ffffffffc020358a:	6709                	lui	a4,0x2
ffffffffc020358c:	0017851b          	addiw	a0,a5,1
        proc->parent = current;
ffffffffc0203590:	0269b023          	sd	t1,32(s3)
    if (++last_pid >= MAX_PID)
ffffffffc0203594:	00a82023          	sw	a0,0(a6)
        return 1;
ffffffffc0203598:	4905                	li	s2,1
ffffffffc020359a:	ece54fe3          	blt	a0,a4,ffffffffc0203478 <do_fork+0xfe>
        last_pid = 1;
ffffffffc020359e:	4785                	li	a5,1
ffffffffc02035a0:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02035a4:	4505                	li	a0,1
ffffffffc02035a6:	00006317          	auipc	t1,0x6
ffffffffc02035aa:	a8630313          	addi	t1,t1,-1402 # ffffffffc020902c <next_safe.0>
    return listelm->next;
ffffffffc02035ae:	0000a417          	auipc	s0,0xa
ffffffffc02035b2:	eaa40413          	addi	s0,s0,-342 # ffffffffc020d458 <proc_list>
        next_safe = MAX_PID;
ffffffffc02035b6:	6789                	lui	a5,0x2
ffffffffc02035b8:	00843e03          	ld	t3,8(s0)
ffffffffc02035bc:	00f32023          	sw	a5,0(t1)
ffffffffc02035c0:	86aa                	mv	a3,a0
ffffffffc02035c2:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02035c4:	6e89                	lui	t4,0x2
ffffffffc02035c6:	b5cd                	j	ffffffffc02034a8 <do_fork+0x12e>
        intr_enable();
ffffffffc02035c8:	b62fd0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02035cc:	bf95                	j	ffffffffc0203540 <do_fork+0x1c6>
                    if (last_pid >= MAX_PID)
ffffffffc02035ce:	01d6c363          	blt	a3,t4,ffffffffc02035d4 <do_fork+0x25a>
                        last_pid = 1;
ffffffffc02035d2:	4685                	li	a3,1
                    goto repeat;
ffffffffc02035d4:	4585                	li	a1,1
ffffffffc02035d6:	bdc9                	j	ffffffffc02034a8 <do_fork+0x12e>
ffffffffc02035d8:	cd81                	beqz	a1,ffffffffc02035f0 <do_fork+0x276>
ffffffffc02035da:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02035de:	8536                	mv	a0,a3
ffffffffc02035e0:	b731                	j	ffffffffc02034ec <do_fork+0x172>
    kfree(proc);
ffffffffc02035e2:	854e                	mv	a0,s3
ffffffffc02035e4:	d8efe0ef          	jal	ra,ffffffffc0201b72 <kfree>
    ret = -E_NO_MEM;
ffffffffc02035e8:	5571                	li	a0,-4
    goto fork_out;
ffffffffc02035ea:	bfa9                	j	ffffffffc0203544 <do_fork+0x1ca>
    int ret = -E_NO_FREE_PROC;
ffffffffc02035ec:	556d                	li	a0,-5
ffffffffc02035ee:	bf99                	j	ffffffffc0203544 <do_fork+0x1ca>
    return last_pid;
ffffffffc02035f0:	00082503          	lw	a0,0(a6)
ffffffffc02035f4:	bde5                	j	ffffffffc02034ec <do_fork+0x172>
    ret = -E_NO_MEM;
ffffffffc02035f6:	5571                	li	a0,-4
    return ret;
ffffffffc02035f8:	b7b1                	j	ffffffffc0203544 <do_fork+0x1ca>
    assert(current->mm == NULL);
ffffffffc02035fa:	00002697          	auipc	a3,0x2
ffffffffc02035fe:	0ce68693          	addi	a3,a3,206 # ffffffffc02056c8 <default_pmm_manager+0x978>
ffffffffc0203602:	00001617          	auipc	a2,0x1
ffffffffc0203606:	39e60613          	addi	a2,a2,926 # ffffffffc02049a0 <commands+0x838>
ffffffffc020360a:	14900593          	li	a1,329
ffffffffc020360e:	00002517          	auipc	a0,0x2
ffffffffc0203612:	0d250513          	addi	a0,a0,210 # ffffffffc02056e0 <default_pmm_manager+0x990>
ffffffffc0203616:	e45fc0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc020361a:	00001617          	auipc	a2,0x1
ffffffffc020361e:	76e60613          	addi	a2,a2,1902 # ffffffffc0204d88 <default_pmm_manager+0x38>
ffffffffc0203622:	07100593          	li	a1,113
ffffffffc0203626:	00001517          	auipc	a0,0x1
ffffffffc020362a:	78a50513          	addi	a0,a0,1930 # ffffffffc0204db0 <default_pmm_manager+0x60>
ffffffffc020362e:	e2dfc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203632 <kernel_thread>:
{
ffffffffc0203632:	7129                	addi	sp,sp,-320
ffffffffc0203634:	fa22                	sd	s0,304(sp)
ffffffffc0203636:	f626                	sd	s1,296(sp)
ffffffffc0203638:	f24a                	sd	s2,288(sp)
ffffffffc020363a:	84ae                	mv	s1,a1
ffffffffc020363c:	892a                	mv	s2,a0
ffffffffc020363e:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0203640:	4581                	li	a1,0
ffffffffc0203642:	12000613          	li	a2,288
ffffffffc0203646:	850a                	mv	a0,sp
{
ffffffffc0203648:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020364a:	063000ef          	jal	ra,ffffffffc0203eac <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020364e:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0203650:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0203652:	100027f3          	csrr	a5,sstatus
ffffffffc0203656:	edd7f793          	andi	a5,a5,-291
ffffffffc020365a:	1207e793          	ori	a5,a5,288
ffffffffc020365e:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203660:	860a                	mv	a2,sp
ffffffffc0203662:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0203666:	00000797          	auipc	a5,0x0
ffffffffc020366a:	baa78793          	addi	a5,a5,-1110 # ffffffffc0203210 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020366e:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0203670:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203672:	d09ff0ef          	jal	ra,ffffffffc020337a <do_fork>
}
ffffffffc0203676:	70f2                	ld	ra,312(sp)
ffffffffc0203678:	7452                	ld	s0,304(sp)
ffffffffc020367a:	74b2                	ld	s1,296(sp)
ffffffffc020367c:	7912                	ld	s2,288(sp)
ffffffffc020367e:	6131                	addi	sp,sp,320
ffffffffc0203680:	8082                	ret

ffffffffc0203682 <do_exit>:
{
ffffffffc0203682:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc0203684:	00002617          	auipc	a2,0x2
ffffffffc0203688:	07460613          	addi	a2,a2,116 # ffffffffc02056f8 <default_pmm_manager+0x9a8>
ffffffffc020368c:	1bf00593          	li	a1,447
ffffffffc0203690:	00002517          	auipc	a0,0x2
ffffffffc0203694:	05050513          	addi	a0,a0,80 # ffffffffc02056e0 <default_pmm_manager+0x990>
{
ffffffffc0203698:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc020369a:	dc1fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc020369e <proc_init>:
//           - create the second kernel thread init_main
// 初始化0号进程和1号进程
// idleproc 是第0号进程，用来空闲时运行，占位
// initproc 是第1号进程，输出 “Hello World”，以验证内核线程的创建与调度机制是否正确
void proc_init(void)
{
ffffffffc020369e:	7179                	addi	sp,sp,-48
ffffffffc02036a0:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc02036a2:	0000a797          	auipc	a5,0xa
ffffffffc02036a6:	db678793          	addi	a5,a5,-586 # ffffffffc020d458 <proc_list>
ffffffffc02036aa:	f406                	sd	ra,40(sp)
ffffffffc02036ac:	f022                	sd	s0,32(sp)
ffffffffc02036ae:	e84a                	sd	s2,16(sp)
ffffffffc02036b0:	e44e                	sd	s3,8(sp)
ffffffffc02036b2:	00006497          	auipc	s1,0x6
ffffffffc02036b6:	d9648493          	addi	s1,s1,-618 # ffffffffc0209448 <hash_list>
ffffffffc02036ba:	e79c                	sd	a5,8(a5)
ffffffffc02036bc:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    // 初始化哈希列表
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc02036be:	0000a717          	auipc	a4,0xa
ffffffffc02036c2:	d8a70713          	addi	a4,a4,-630 # ffffffffc020d448 <name.2>
ffffffffc02036c6:	87a6                	mv	a5,s1
ffffffffc02036c8:	e79c                	sd	a5,8(a5)
ffffffffc02036ca:	e39c                	sd	a5,0(a5)
ffffffffc02036cc:	07c1                	addi	a5,a5,16
ffffffffc02036ce:	fef71de3          	bne	a4,a5,ffffffffc02036c8 <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    // 给0号进程分配 proc_struct
    if ((idleproc = alloc_proc()) == NULL)
ffffffffc02036d2:	b47ff0ef          	jal	ra,ffffffffc0203218 <alloc_proc>
ffffffffc02036d6:	0000a917          	auipc	s2,0xa
ffffffffc02036da:	e0290913          	addi	s2,s2,-510 # ffffffffc020d4d8 <idleproc>
ffffffffc02036de:	00a93023          	sd	a0,0(s2)
ffffffffc02036e2:	18050d63          	beqz	a0,ffffffffc020387c <proc_init+0x1de>
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    //初始化0号进程的各个字段，并检查 alloc_proc 是否正确初始化了这些字段
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc02036e6:	07000513          	li	a0,112
ffffffffc02036ea:	bd8fe0ef          	jal	ra,ffffffffc0201ac2 <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc02036ee:	07000613          	li	a2,112
ffffffffc02036f2:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc02036f4:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc02036f6:	7b6000ef          	jal	ra,ffffffffc0203eac <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc02036fa:	00093503          	ld	a0,0(s2)
ffffffffc02036fe:	85a2                	mv	a1,s0
ffffffffc0203700:	07000613          	li	a2,112
ffffffffc0203704:	03050513          	addi	a0,a0,48
ffffffffc0203708:	7ce000ef          	jal	ra,ffffffffc0203ed6 <memcmp>
ffffffffc020370c:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc020370e:	453d                	li	a0,15
ffffffffc0203710:	bb2fe0ef          	jal	ra,ffffffffc0201ac2 <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0203714:	463d                	li	a2,15
ffffffffc0203716:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc0203718:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc020371a:	792000ef          	jal	ra,ffffffffc0203eac <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc020371e:	00093503          	ld	a0,0(s2)
ffffffffc0203722:	463d                	li	a2,15
ffffffffc0203724:	85a2                	mv	a1,s0
ffffffffc0203726:	0b450513          	addi	a0,a0,180
ffffffffc020372a:	7ac000ef          	jal	ra,ffffffffc0203ed6 <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc020372e:	00093783          	ld	a5,0(s2)
ffffffffc0203732:	0000a717          	auipc	a4,0xa
ffffffffc0203736:	d6e73703          	ld	a4,-658(a4) # ffffffffc020d4a0 <boot_pgdir_pa>
ffffffffc020373a:	77d4                	ld	a3,168(a5)
ffffffffc020373c:	0ee68463          	beq	a3,a4,ffffffffc0203824 <proc_init+0x186>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0203740:	4709                	li	a4,2
ffffffffc0203742:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0203744:	00003717          	auipc	a4,0x3
ffffffffc0203748:	8bc70713          	addi	a4,a4,-1860 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020374c:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0203750:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc0203752:	4705                	li	a4,1
ffffffffc0203754:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203756:	4641                	li	a2,16
ffffffffc0203758:	4581                	li	a1,0
ffffffffc020375a:	8522                	mv	a0,s0
ffffffffc020375c:	750000ef          	jal	ra,ffffffffc0203eac <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203760:	463d                	li	a2,15
ffffffffc0203762:	00002597          	auipc	a1,0x2
ffffffffc0203766:	fde58593          	addi	a1,a1,-34 # ffffffffc0205740 <default_pmm_manager+0x9f0>
ffffffffc020376a:	8522                	mv	a0,s0
ffffffffc020376c:	752000ef          	jal	ra,ffffffffc0203ebe <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0203770:	0000a717          	auipc	a4,0xa
ffffffffc0203774:	d7870713          	addi	a4,a4,-648 # ffffffffc020d4e8 <nr_process>
ffffffffc0203778:	431c                	lw	a5,0(a4)
    
    current = idleproc;
ffffffffc020377a:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020377e:	4601                	li	a2,0
    nr_process++;
ffffffffc0203780:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203782:	00002597          	auipc	a1,0x2
ffffffffc0203786:	fc658593          	addi	a1,a1,-58 # ffffffffc0205748 <default_pmm_manager+0x9f8>
ffffffffc020378a:	00000517          	auipc	a0,0x0
ffffffffc020378e:	b1850513          	addi	a0,a0,-1256 # ffffffffc02032a2 <init_main>
    nr_process++;
ffffffffc0203792:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0203794:	0000a797          	auipc	a5,0xa
ffffffffc0203798:	d2d7be23          	sd	a3,-708(a5) # ffffffffc020d4d0 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020379c:	e97ff0ef          	jal	ra,ffffffffc0203632 <kernel_thread>
ffffffffc02037a0:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc02037a2:	0ea05963          	blez	a0,ffffffffc0203894 <proc_init+0x1f6>
    if (0 < pid && pid < MAX_PID)
ffffffffc02037a6:	6789                	lui	a5,0x2
ffffffffc02037a8:	fff5071b          	addiw	a4,a0,-1
ffffffffc02037ac:	17f9                	addi	a5,a5,-2
ffffffffc02037ae:	2501                	sext.w	a0,a0
ffffffffc02037b0:	02e7e363          	bltu	a5,a4,ffffffffc02037d6 <proc_init+0x138>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02037b4:	45a9                	li	a1,10
ffffffffc02037b6:	250000ef          	jal	ra,ffffffffc0203a06 <hash32>
ffffffffc02037ba:	02051793          	slli	a5,a0,0x20
ffffffffc02037be:	01c7d693          	srli	a3,a5,0x1c
ffffffffc02037c2:	96a6                	add	a3,a3,s1
ffffffffc02037c4:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02037c6:	a029                	j	ffffffffc02037d0 <proc_init+0x132>
            if (proc->pid == pid)
ffffffffc02037c8:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc02037cc:	0a870563          	beq	a4,s0,ffffffffc0203876 <proc_init+0x1d8>
    return listelm->next;
ffffffffc02037d0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02037d2:	fef69be3          	bne	a3,a5,ffffffffc02037c8 <proc_init+0x12a>
    return NULL;
ffffffffc02037d6:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02037d8:	0b478493          	addi	s1,a5,180
ffffffffc02037dc:	4641                	li	a2,16
ffffffffc02037de:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc02037e0:	0000a417          	auipc	s0,0xa
ffffffffc02037e4:	d0040413          	addi	s0,s0,-768 # ffffffffc020d4e0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02037e8:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc02037ea:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02037ec:	6c0000ef          	jal	ra,ffffffffc0203eac <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02037f0:	463d                	li	a2,15
ffffffffc02037f2:	00002597          	auipc	a1,0x2
ffffffffc02037f6:	f8658593          	addi	a1,a1,-122 # ffffffffc0205778 <default_pmm_manager+0xa28>
ffffffffc02037fa:	8526                	mv	a0,s1
ffffffffc02037fc:	6c2000ef          	jal	ra,ffffffffc0203ebe <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203800:	00093783          	ld	a5,0(s2)
ffffffffc0203804:	c7e1                	beqz	a5,ffffffffc02038cc <proc_init+0x22e>
ffffffffc0203806:	43dc                	lw	a5,4(a5)
ffffffffc0203808:	e3f1                	bnez	a5,ffffffffc02038cc <proc_init+0x22e>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020380a:	601c                	ld	a5,0(s0)
ffffffffc020380c:	c3c5                	beqz	a5,ffffffffc02038ac <proc_init+0x20e>
ffffffffc020380e:	43d8                	lw	a4,4(a5)
ffffffffc0203810:	4785                	li	a5,1
ffffffffc0203812:	08f71d63          	bne	a4,a5,ffffffffc02038ac <proc_init+0x20e>
}
ffffffffc0203816:	70a2                	ld	ra,40(sp)
ffffffffc0203818:	7402                	ld	s0,32(sp)
ffffffffc020381a:	64e2                	ld	s1,24(sp)
ffffffffc020381c:	6942                	ld	s2,16(sp)
ffffffffc020381e:	69a2                	ld	s3,8(sp)
ffffffffc0203820:	6145                	addi	sp,sp,48
ffffffffc0203822:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc0203824:	73d8                	ld	a4,160(a5)
ffffffffc0203826:	ff09                	bnez	a4,ffffffffc0203740 <proc_init+0xa2>
ffffffffc0203828:	f0099ce3          	bnez	s3,ffffffffc0203740 <proc_init+0xa2>
ffffffffc020382c:	6394                	ld	a3,0(a5)
ffffffffc020382e:	577d                	li	a4,-1
ffffffffc0203830:	1702                	slli	a4,a4,0x20
ffffffffc0203832:	f0e697e3          	bne	a3,a4,ffffffffc0203740 <proc_init+0xa2>
ffffffffc0203836:	4798                	lw	a4,8(a5)
ffffffffc0203838:	f00714e3          	bnez	a4,ffffffffc0203740 <proc_init+0xa2>
ffffffffc020383c:	6b98                	ld	a4,16(a5)
ffffffffc020383e:	f00711e3          	bnez	a4,ffffffffc0203740 <proc_init+0xa2>
ffffffffc0203842:	4f98                	lw	a4,24(a5)
ffffffffc0203844:	2701                	sext.w	a4,a4
ffffffffc0203846:	ee071de3          	bnez	a4,ffffffffc0203740 <proc_init+0xa2>
ffffffffc020384a:	7398                	ld	a4,32(a5)
ffffffffc020384c:	ee071ae3          	bnez	a4,ffffffffc0203740 <proc_init+0xa2>
ffffffffc0203850:	7798                	ld	a4,40(a5)
ffffffffc0203852:	ee0717e3          	bnez	a4,ffffffffc0203740 <proc_init+0xa2>
ffffffffc0203856:	0b07a703          	lw	a4,176(a5)
ffffffffc020385a:	8d59                	or	a0,a0,a4
ffffffffc020385c:	0005071b          	sext.w	a4,a0
ffffffffc0203860:	ee0710e3          	bnez	a4,ffffffffc0203740 <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc0203864:	00002517          	auipc	a0,0x2
ffffffffc0203868:	ec450513          	addi	a0,a0,-316 # ffffffffc0205728 <default_pmm_manager+0x9d8>
ffffffffc020386c:	929fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    idleproc->pid = 0;
ffffffffc0203870:	00093783          	ld	a5,0(s2)
ffffffffc0203874:	b5f1                	j	ffffffffc0203740 <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0203876:	f2878793          	addi	a5,a5,-216
ffffffffc020387a:	bfb9                	j	ffffffffc02037d8 <proc_init+0x13a>
        panic("cannot alloc idleproc.\n");
ffffffffc020387c:	00002617          	auipc	a2,0x2
ffffffffc0203880:	e9460613          	addi	a2,a2,-364 # ffffffffc0205710 <default_pmm_manager+0x9c0>
ffffffffc0203884:	1ec00593          	li	a1,492
ffffffffc0203888:	00002517          	auipc	a0,0x2
ffffffffc020388c:	e5850513          	addi	a0,a0,-424 # ffffffffc02056e0 <default_pmm_manager+0x990>
ffffffffc0203890:	bcbfc0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("create init_main failed.\n");
ffffffffc0203894:	00002617          	auipc	a2,0x2
ffffffffc0203898:	ec460613          	addi	a2,a2,-316 # ffffffffc0205758 <default_pmm_manager+0xa08>
ffffffffc020389c:	20a00593          	li	a1,522
ffffffffc02038a0:	00002517          	auipc	a0,0x2
ffffffffc02038a4:	e4050513          	addi	a0,a0,-448 # ffffffffc02056e0 <default_pmm_manager+0x990>
ffffffffc02038a8:	bb3fc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02038ac:	00002697          	auipc	a3,0x2
ffffffffc02038b0:	efc68693          	addi	a3,a3,-260 # ffffffffc02057a8 <default_pmm_manager+0xa58>
ffffffffc02038b4:	00001617          	auipc	a2,0x1
ffffffffc02038b8:	0ec60613          	addi	a2,a2,236 # ffffffffc02049a0 <commands+0x838>
ffffffffc02038bc:	21100593          	li	a1,529
ffffffffc02038c0:	00002517          	auipc	a0,0x2
ffffffffc02038c4:	e2050513          	addi	a0,a0,-480 # ffffffffc02056e0 <default_pmm_manager+0x990>
ffffffffc02038c8:	b93fc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02038cc:	00002697          	auipc	a3,0x2
ffffffffc02038d0:	eb468693          	addi	a3,a3,-332 # ffffffffc0205780 <default_pmm_manager+0xa30>
ffffffffc02038d4:	00001617          	auipc	a2,0x1
ffffffffc02038d8:	0cc60613          	addi	a2,a2,204 # ffffffffc02049a0 <commands+0x838>
ffffffffc02038dc:	21000593          	li	a1,528
ffffffffc02038e0:	00002517          	auipc	a0,0x2
ffffffffc02038e4:	e0050513          	addi	a0,a0,-512 # ffffffffc02056e0 <default_pmm_manager+0x990>
ffffffffc02038e8:	b73fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02038ec <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
// 在 kern_init 结束时，第一条内核线程 idleproc 会执行后面列出的工作（即进入 cpu_idle 循环，根据 need_resched 调度其他进程）。
void cpu_idle(void)
{
ffffffffc02038ec:	1141                	addi	sp,sp,-16
ffffffffc02038ee:	e022                	sd	s0,0(sp)
ffffffffc02038f0:	e406                	sd	ra,8(sp)
ffffffffc02038f2:	0000a417          	auipc	s0,0xa
ffffffffc02038f6:	bde40413          	addi	s0,s0,-1058 # ffffffffc020d4d0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02038fa:	6018                	ld	a4,0(s0)
ffffffffc02038fc:	4f1c                	lw	a5,24(a4)
ffffffffc02038fe:	2781                	sext.w	a5,a5
ffffffffc0203900:	dff5                	beqz	a5,ffffffffc02038fc <cpu_idle+0x10>
        {
            schedule();
ffffffffc0203902:	070000ef          	jal	ra,ffffffffc0203972 <schedule>
ffffffffc0203906:	bfd5                	j	ffffffffc02038fa <cpu_idle+0xe>

ffffffffc0203908 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0203908:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc020390c:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0203910:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0203912:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0203914:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0203918:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc020391c:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0203920:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0203924:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0203928:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc020392c:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0203930:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0203934:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0203938:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc020393c:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0203940:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0203944:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0203946:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0203948:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc020394c:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0203950:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0203954:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0203958:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc020395c:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0203960:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0203964:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0203968:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc020396c:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0203970:	8082                	ret

ffffffffc0203972 <schedule>:
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
    proc->state = PROC_RUNNABLE;
}

void
schedule(void) {
ffffffffc0203972:	1141                	addi	sp,sp,-16
ffffffffc0203974:	e406                	sd	ra,8(sp)
ffffffffc0203976:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203978:	100027f3          	csrr	a5,sstatus
ffffffffc020397c:	8b89                	andi	a5,a5,2
ffffffffc020397e:	4401                	li	s0,0
ffffffffc0203980:	efbd                	bnez	a5,ffffffffc02039fe <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0203982:	0000a897          	auipc	a7,0xa
ffffffffc0203986:	b4e8b883          	ld	a7,-1202(a7) # ffffffffc020d4d0 <current>
ffffffffc020398a:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020398e:	0000a517          	auipc	a0,0xa
ffffffffc0203992:	b4a53503          	ld	a0,-1206(a0) # ffffffffc020d4d8 <idleproc>
ffffffffc0203996:	04a88e63          	beq	a7,a0,ffffffffc02039f2 <schedule+0x80>
ffffffffc020399a:	0c888693          	addi	a3,a7,200
ffffffffc020399e:	0000a617          	auipc	a2,0xa
ffffffffc02039a2:	aba60613          	addi	a2,a2,-1350 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc02039a6:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02039a8:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc02039aa:	4809                	li	a6,2
ffffffffc02039ac:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc02039ae:	00c78863          	beq	a5,a2,ffffffffc02039be <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc02039b2:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02039b6:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc02039ba:	03070163          	beq	a4,a6,ffffffffc02039dc <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc02039be:	fef697e3          	bne	a3,a5,ffffffffc02039ac <schedule+0x3a>
        // 没有下一个可运行的进程，就运行 idleproc
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02039c2:	ed89                	bnez	a1,ffffffffc02039dc <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc02039c4:	451c                	lw	a5,8(a0)
ffffffffc02039c6:	2785                	addiw	a5,a5,1
ffffffffc02039c8:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc02039ca:	00a88463          	beq	a7,a0,ffffffffc02039d2 <schedule+0x60>
            proc_run(next);
ffffffffc02039ce:	947ff0ef          	jal	ra,ffffffffc0203314 <proc_run>
    if (flag) {
ffffffffc02039d2:	e819                	bnez	s0,ffffffffc02039e8 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02039d4:	60a2                	ld	ra,8(sp)
ffffffffc02039d6:	6402                	ld	s0,0(sp)
ffffffffc02039d8:	0141                	addi	sp,sp,16
ffffffffc02039da:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02039dc:	4198                	lw	a4,0(a1)
ffffffffc02039de:	4789                	li	a5,2
ffffffffc02039e0:	fef712e3          	bne	a4,a5,ffffffffc02039c4 <schedule+0x52>
ffffffffc02039e4:	852e                	mv	a0,a1
ffffffffc02039e6:	bff9                	j	ffffffffc02039c4 <schedule+0x52>
}
ffffffffc02039e8:	6402                	ld	s0,0(sp)
ffffffffc02039ea:	60a2                	ld	ra,8(sp)
ffffffffc02039ec:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02039ee:	f3dfc06f          	j	ffffffffc020092a <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02039f2:	0000a617          	auipc	a2,0xa
ffffffffc02039f6:	a6660613          	addi	a2,a2,-1434 # ffffffffc020d458 <proc_list>
ffffffffc02039fa:	86b2                	mv	a3,a2
ffffffffc02039fc:	b76d                	j	ffffffffc02039a6 <schedule+0x34>
        intr_disable();
ffffffffc02039fe:	f33fc0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0203a02:	4405                	li	s0,1
ffffffffc0203a04:	bfbd                	j	ffffffffc0203982 <schedule+0x10>

ffffffffc0203a06 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0203a06:	9e3707b7          	lui	a5,0x9e370
ffffffffc0203a0a:	2785                	addiw	a5,a5,1
ffffffffc0203a0c:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0203a10:	02000793          	li	a5,32
ffffffffc0203a14:	9f8d                	subw	a5,a5,a1
}
ffffffffc0203a16:	00f5553b          	srlw	a0,a0,a5
ffffffffc0203a1a:	8082                	ret

ffffffffc0203a1c <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203a1c:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a20:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203a22:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a26:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203a28:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a2c:	f022                	sd	s0,32(sp)
ffffffffc0203a2e:	ec26                	sd	s1,24(sp)
ffffffffc0203a30:	e84a                	sd	s2,16(sp)
ffffffffc0203a32:	f406                	sd	ra,40(sp)
ffffffffc0203a34:	e44e                	sd	s3,8(sp)
ffffffffc0203a36:	84aa                	mv	s1,a0
ffffffffc0203a38:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203a3a:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203a3e:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0203a40:	03067e63          	bgeu	a2,a6,ffffffffc0203a7c <printnum+0x60>
ffffffffc0203a44:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203a46:	00805763          	blez	s0,ffffffffc0203a54 <printnum+0x38>
ffffffffc0203a4a:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203a4c:	85ca                	mv	a1,s2
ffffffffc0203a4e:	854e                	mv	a0,s3
ffffffffc0203a50:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203a52:	fc65                	bnez	s0,ffffffffc0203a4a <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a54:	1a02                	slli	s4,s4,0x20
ffffffffc0203a56:	00002797          	auipc	a5,0x2
ffffffffc0203a5a:	d7a78793          	addi	a5,a5,-646 # ffffffffc02057d0 <default_pmm_manager+0xa80>
ffffffffc0203a5e:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203a62:	9a3e                	add	s4,s4,a5
}
ffffffffc0203a64:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a66:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203a6a:	70a2                	ld	ra,40(sp)
ffffffffc0203a6c:	69a2                	ld	s3,8(sp)
ffffffffc0203a6e:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a70:	85ca                	mv	a1,s2
ffffffffc0203a72:	87a6                	mv	a5,s1
}
ffffffffc0203a74:	6942                	ld	s2,16(sp)
ffffffffc0203a76:	64e2                	ld	s1,24(sp)
ffffffffc0203a78:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a7a:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203a7c:	03065633          	divu	a2,a2,a6
ffffffffc0203a80:	8722                	mv	a4,s0
ffffffffc0203a82:	f9bff0ef          	jal	ra,ffffffffc0203a1c <printnum>
ffffffffc0203a86:	b7f9                	j	ffffffffc0203a54 <printnum+0x38>

ffffffffc0203a88 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203a88:	7119                	addi	sp,sp,-128
ffffffffc0203a8a:	f4a6                	sd	s1,104(sp)
ffffffffc0203a8c:	f0ca                	sd	s2,96(sp)
ffffffffc0203a8e:	ecce                	sd	s3,88(sp)
ffffffffc0203a90:	e8d2                	sd	s4,80(sp)
ffffffffc0203a92:	e4d6                	sd	s5,72(sp)
ffffffffc0203a94:	e0da                	sd	s6,64(sp)
ffffffffc0203a96:	fc5e                	sd	s7,56(sp)
ffffffffc0203a98:	f06a                	sd	s10,32(sp)
ffffffffc0203a9a:	fc86                	sd	ra,120(sp)
ffffffffc0203a9c:	f8a2                	sd	s0,112(sp)
ffffffffc0203a9e:	f862                	sd	s8,48(sp)
ffffffffc0203aa0:	f466                	sd	s9,40(sp)
ffffffffc0203aa2:	ec6e                	sd	s11,24(sp)
ffffffffc0203aa4:	892a                	mv	s2,a0
ffffffffc0203aa6:	84ae                	mv	s1,a1
ffffffffc0203aa8:	8d32                	mv	s10,a2
ffffffffc0203aaa:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203aac:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203ab0:	5b7d                	li	s6,-1
ffffffffc0203ab2:	00002a97          	auipc	s5,0x2
ffffffffc0203ab6:	d4aa8a93          	addi	s5,s5,-694 # ffffffffc02057fc <default_pmm_manager+0xaac>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203aba:	00002b97          	auipc	s7,0x2
ffffffffc0203abe:	f1eb8b93          	addi	s7,s7,-226 # ffffffffc02059d8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ac2:	000d4503          	lbu	a0,0(s10)
ffffffffc0203ac6:	001d0413          	addi	s0,s10,1
ffffffffc0203aca:	01350a63          	beq	a0,s3,ffffffffc0203ade <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0203ace:	c121                	beqz	a0,ffffffffc0203b0e <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0203ad0:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ad2:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203ad4:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ad6:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203ada:	ff351ae3          	bne	a0,s3,ffffffffc0203ace <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ade:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203ae2:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203ae6:	4c81                	li	s9,0
ffffffffc0203ae8:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0203aea:	5c7d                	li	s8,-1
ffffffffc0203aec:	5dfd                	li	s11,-1
ffffffffc0203aee:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0203af2:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203af4:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203af8:	0ff5f593          	zext.b	a1,a1
ffffffffc0203afc:	00140d13          	addi	s10,s0,1
ffffffffc0203b00:	04b56263          	bltu	a0,a1,ffffffffc0203b44 <vprintfmt+0xbc>
ffffffffc0203b04:	058a                	slli	a1,a1,0x2
ffffffffc0203b06:	95d6                	add	a1,a1,s5
ffffffffc0203b08:	4194                	lw	a3,0(a1)
ffffffffc0203b0a:	96d6                	add	a3,a3,s5
ffffffffc0203b0c:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203b0e:	70e6                	ld	ra,120(sp)
ffffffffc0203b10:	7446                	ld	s0,112(sp)
ffffffffc0203b12:	74a6                	ld	s1,104(sp)
ffffffffc0203b14:	7906                	ld	s2,96(sp)
ffffffffc0203b16:	69e6                	ld	s3,88(sp)
ffffffffc0203b18:	6a46                	ld	s4,80(sp)
ffffffffc0203b1a:	6aa6                	ld	s5,72(sp)
ffffffffc0203b1c:	6b06                	ld	s6,64(sp)
ffffffffc0203b1e:	7be2                	ld	s7,56(sp)
ffffffffc0203b20:	7c42                	ld	s8,48(sp)
ffffffffc0203b22:	7ca2                	ld	s9,40(sp)
ffffffffc0203b24:	7d02                	ld	s10,32(sp)
ffffffffc0203b26:	6de2                	ld	s11,24(sp)
ffffffffc0203b28:	6109                	addi	sp,sp,128
ffffffffc0203b2a:	8082                	ret
            padc = '0';
ffffffffc0203b2c:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0203b2e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b32:	846a                	mv	s0,s10
ffffffffc0203b34:	00140d13          	addi	s10,s0,1
ffffffffc0203b38:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203b3c:	0ff5f593          	zext.b	a1,a1
ffffffffc0203b40:	fcb572e3          	bgeu	a0,a1,ffffffffc0203b04 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0203b44:	85a6                	mv	a1,s1
ffffffffc0203b46:	02500513          	li	a0,37
ffffffffc0203b4a:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203b4c:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203b50:	8d22                	mv	s10,s0
ffffffffc0203b52:	f73788e3          	beq	a5,s3,ffffffffc0203ac2 <vprintfmt+0x3a>
ffffffffc0203b56:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0203b5a:	1d7d                	addi	s10,s10,-1
ffffffffc0203b5c:	ff379de3          	bne	a5,s3,ffffffffc0203b56 <vprintfmt+0xce>
ffffffffc0203b60:	b78d                	j	ffffffffc0203ac2 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0203b62:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0203b66:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b6a:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0203b6c:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0203b70:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b74:	02d86463          	bltu	a6,a3,ffffffffc0203b9c <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0203b78:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203b7c:	002c169b          	slliw	a3,s8,0x2
ffffffffc0203b80:	0186873b          	addw	a4,a3,s8
ffffffffc0203b84:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203b88:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0203b8a:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203b8e:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203b90:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0203b94:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b98:	fed870e3          	bgeu	a6,a3,ffffffffc0203b78 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0203b9c:	f40ddce3          	bgez	s11,ffffffffc0203af4 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0203ba0:	8de2                	mv	s11,s8
ffffffffc0203ba2:	5c7d                	li	s8,-1
ffffffffc0203ba4:	bf81                	j	ffffffffc0203af4 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0203ba6:	fffdc693          	not	a3,s11
ffffffffc0203baa:	96fd                	srai	a3,a3,0x3f
ffffffffc0203bac:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bb0:	00144603          	lbu	a2,1(s0)
ffffffffc0203bb4:	2d81                	sext.w	s11,s11
ffffffffc0203bb6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203bb8:	bf35                	j	ffffffffc0203af4 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0203bba:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bbe:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0203bc2:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bc4:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0203bc6:	bfd9                	j	ffffffffc0203b9c <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0203bc8:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203bca:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203bce:	01174463          	blt	a4,a7,ffffffffc0203bd6 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0203bd2:	1a088e63          	beqz	a7,ffffffffc0203d8e <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0203bd6:	000a3603          	ld	a2,0(s4)
ffffffffc0203bda:	46c1                	li	a3,16
ffffffffc0203bdc:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203bde:	2781                	sext.w	a5,a5
ffffffffc0203be0:	876e                	mv	a4,s11
ffffffffc0203be2:	85a6                	mv	a1,s1
ffffffffc0203be4:	854a                	mv	a0,s2
ffffffffc0203be6:	e37ff0ef          	jal	ra,ffffffffc0203a1c <printnum>
            break;
ffffffffc0203bea:	bde1                	j	ffffffffc0203ac2 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0203bec:	000a2503          	lw	a0,0(s4)
ffffffffc0203bf0:	85a6                	mv	a1,s1
ffffffffc0203bf2:	0a21                	addi	s4,s4,8
ffffffffc0203bf4:	9902                	jalr	s2
            break;
ffffffffc0203bf6:	b5f1                	j	ffffffffc0203ac2 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203bf8:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203bfa:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203bfe:	01174463          	blt	a4,a7,ffffffffc0203c06 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0203c02:	18088163          	beqz	a7,ffffffffc0203d84 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0203c06:	000a3603          	ld	a2,0(s4)
ffffffffc0203c0a:	46a9                	li	a3,10
ffffffffc0203c0c:	8a2e                	mv	s4,a1
ffffffffc0203c0e:	bfc1                	j	ffffffffc0203bde <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c10:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0203c14:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c16:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203c18:	bdf1                	j	ffffffffc0203af4 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0203c1a:	85a6                	mv	a1,s1
ffffffffc0203c1c:	02500513          	li	a0,37
ffffffffc0203c20:	9902                	jalr	s2
            break;
ffffffffc0203c22:	b545                	j	ffffffffc0203ac2 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c24:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0203c28:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c2a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203c2c:	b5e1                	j	ffffffffc0203af4 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0203c2e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c30:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203c34:	01174463          	blt	a4,a7,ffffffffc0203c3c <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0203c38:	14088163          	beqz	a7,ffffffffc0203d7a <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0203c3c:	000a3603          	ld	a2,0(s4)
ffffffffc0203c40:	46a1                	li	a3,8
ffffffffc0203c42:	8a2e                	mv	s4,a1
ffffffffc0203c44:	bf69                	j	ffffffffc0203bde <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0203c46:	03000513          	li	a0,48
ffffffffc0203c4a:	85a6                	mv	a1,s1
ffffffffc0203c4c:	e03e                	sd	a5,0(sp)
ffffffffc0203c4e:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203c50:	85a6                	mv	a1,s1
ffffffffc0203c52:	07800513          	li	a0,120
ffffffffc0203c56:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203c58:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203c5a:	6782                	ld	a5,0(sp)
ffffffffc0203c5c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203c5e:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0203c62:	bfb5                	j	ffffffffc0203bde <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c64:	000a3403          	ld	s0,0(s4)
ffffffffc0203c68:	008a0713          	addi	a4,s4,8
ffffffffc0203c6c:	e03a                	sd	a4,0(sp)
ffffffffc0203c6e:	14040263          	beqz	s0,ffffffffc0203db2 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0203c72:	0fb05763          	blez	s11,ffffffffc0203d60 <vprintfmt+0x2d8>
ffffffffc0203c76:	02d00693          	li	a3,45
ffffffffc0203c7a:	0cd79163          	bne	a5,a3,ffffffffc0203d3c <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c7e:	00044783          	lbu	a5,0(s0)
ffffffffc0203c82:	0007851b          	sext.w	a0,a5
ffffffffc0203c86:	cf85                	beqz	a5,ffffffffc0203cbe <vprintfmt+0x236>
ffffffffc0203c88:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c8c:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c90:	000c4563          	bltz	s8,ffffffffc0203c9a <vprintfmt+0x212>
ffffffffc0203c94:	3c7d                	addiw	s8,s8,-1
ffffffffc0203c96:	036c0263          	beq	s8,s6,ffffffffc0203cba <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0203c9a:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c9c:	0e0c8e63          	beqz	s9,ffffffffc0203d98 <vprintfmt+0x310>
ffffffffc0203ca0:	3781                	addiw	a5,a5,-32
ffffffffc0203ca2:	0ef47b63          	bgeu	s0,a5,ffffffffc0203d98 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0203ca6:	03f00513          	li	a0,63
ffffffffc0203caa:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203cac:	000a4783          	lbu	a5,0(s4)
ffffffffc0203cb0:	3dfd                	addiw	s11,s11,-1
ffffffffc0203cb2:	0a05                	addi	s4,s4,1
ffffffffc0203cb4:	0007851b          	sext.w	a0,a5
ffffffffc0203cb8:	ffe1                	bnez	a5,ffffffffc0203c90 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0203cba:	01b05963          	blez	s11,ffffffffc0203ccc <vprintfmt+0x244>
ffffffffc0203cbe:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0203cc0:	85a6                	mv	a1,s1
ffffffffc0203cc2:	02000513          	li	a0,32
ffffffffc0203cc6:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0203cc8:	fe0d9be3          	bnez	s11,ffffffffc0203cbe <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203ccc:	6a02                	ld	s4,0(sp)
ffffffffc0203cce:	bbd5                	j	ffffffffc0203ac2 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203cd0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203cd2:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0203cd6:	01174463          	blt	a4,a7,ffffffffc0203cde <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0203cda:	08088d63          	beqz	a7,ffffffffc0203d74 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0203cde:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203ce2:	0a044d63          	bltz	s0,ffffffffc0203d9c <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0203ce6:	8622                	mv	a2,s0
ffffffffc0203ce8:	8a66                	mv	s4,s9
ffffffffc0203cea:	46a9                	li	a3,10
ffffffffc0203cec:	bdcd                	j	ffffffffc0203bde <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0203cee:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203cf2:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0203cf4:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203cf6:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0203cfa:	8fb5                	xor	a5,a5,a3
ffffffffc0203cfc:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203d00:	02d74163          	blt	a4,a3,ffffffffc0203d22 <vprintfmt+0x29a>
ffffffffc0203d04:	00369793          	slli	a5,a3,0x3
ffffffffc0203d08:	97de                	add	a5,a5,s7
ffffffffc0203d0a:	639c                	ld	a5,0(a5)
ffffffffc0203d0c:	cb99                	beqz	a5,ffffffffc0203d22 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203d0e:	86be                	mv	a3,a5
ffffffffc0203d10:	00000617          	auipc	a2,0x0
ffffffffc0203d14:	21860613          	addi	a2,a2,536 # ffffffffc0203f28 <etext+0x2e>
ffffffffc0203d18:	85a6                	mv	a1,s1
ffffffffc0203d1a:	854a                	mv	a0,s2
ffffffffc0203d1c:	0ce000ef          	jal	ra,ffffffffc0203dea <printfmt>
ffffffffc0203d20:	b34d                	j	ffffffffc0203ac2 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203d22:	00002617          	auipc	a2,0x2
ffffffffc0203d26:	ace60613          	addi	a2,a2,-1330 # ffffffffc02057f0 <default_pmm_manager+0xaa0>
ffffffffc0203d2a:	85a6                	mv	a1,s1
ffffffffc0203d2c:	854a                	mv	a0,s2
ffffffffc0203d2e:	0bc000ef          	jal	ra,ffffffffc0203dea <printfmt>
ffffffffc0203d32:	bb41                	j	ffffffffc0203ac2 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0203d34:	00002417          	auipc	s0,0x2
ffffffffc0203d38:	ab440413          	addi	s0,s0,-1356 # ffffffffc02057e8 <default_pmm_manager+0xa98>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d3c:	85e2                	mv	a1,s8
ffffffffc0203d3e:	8522                	mv	a0,s0
ffffffffc0203d40:	e43e                	sd	a5,8(sp)
ffffffffc0203d42:	0e2000ef          	jal	ra,ffffffffc0203e24 <strnlen>
ffffffffc0203d46:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0203d4a:	01b05b63          	blez	s11,ffffffffc0203d60 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0203d4e:	67a2                	ld	a5,8(sp)
ffffffffc0203d50:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d54:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0203d56:	85a6                	mv	a1,s1
ffffffffc0203d58:	8552                	mv	a0,s4
ffffffffc0203d5a:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d5c:	fe0d9ce3          	bnez	s11,ffffffffc0203d54 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d60:	00044783          	lbu	a5,0(s0)
ffffffffc0203d64:	00140a13          	addi	s4,s0,1
ffffffffc0203d68:	0007851b          	sext.w	a0,a5
ffffffffc0203d6c:	d3a5                	beqz	a5,ffffffffc0203ccc <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203d6e:	05e00413          	li	s0,94
ffffffffc0203d72:	bf39                	j	ffffffffc0203c90 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0203d74:	000a2403          	lw	s0,0(s4)
ffffffffc0203d78:	b7ad                	j	ffffffffc0203ce2 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0203d7a:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d7e:	46a1                	li	a3,8
ffffffffc0203d80:	8a2e                	mv	s4,a1
ffffffffc0203d82:	bdb1                	j	ffffffffc0203bde <vprintfmt+0x156>
ffffffffc0203d84:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d88:	46a9                	li	a3,10
ffffffffc0203d8a:	8a2e                	mv	s4,a1
ffffffffc0203d8c:	bd89                	j	ffffffffc0203bde <vprintfmt+0x156>
ffffffffc0203d8e:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d92:	46c1                	li	a3,16
ffffffffc0203d94:	8a2e                	mv	s4,a1
ffffffffc0203d96:	b5a1                	j	ffffffffc0203bde <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0203d98:	9902                	jalr	s2
ffffffffc0203d9a:	bf09                	j	ffffffffc0203cac <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0203d9c:	85a6                	mv	a1,s1
ffffffffc0203d9e:	02d00513          	li	a0,45
ffffffffc0203da2:	e03e                	sd	a5,0(sp)
ffffffffc0203da4:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0203da6:	6782                	ld	a5,0(sp)
ffffffffc0203da8:	8a66                	mv	s4,s9
ffffffffc0203daa:	40800633          	neg	a2,s0
ffffffffc0203dae:	46a9                	li	a3,10
ffffffffc0203db0:	b53d                	j	ffffffffc0203bde <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0203db2:	03b05163          	blez	s11,ffffffffc0203dd4 <vprintfmt+0x34c>
ffffffffc0203db6:	02d00693          	li	a3,45
ffffffffc0203dba:	f6d79de3          	bne	a5,a3,ffffffffc0203d34 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0203dbe:	00002417          	auipc	s0,0x2
ffffffffc0203dc2:	a2a40413          	addi	s0,s0,-1494 # ffffffffc02057e8 <default_pmm_manager+0xa98>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203dc6:	02800793          	li	a5,40
ffffffffc0203dca:	02800513          	li	a0,40
ffffffffc0203dce:	00140a13          	addi	s4,s0,1
ffffffffc0203dd2:	bd6d                	j	ffffffffc0203c8c <vprintfmt+0x204>
ffffffffc0203dd4:	00002a17          	auipc	s4,0x2
ffffffffc0203dd8:	a15a0a13          	addi	s4,s4,-1515 # ffffffffc02057e9 <default_pmm_manager+0xa99>
ffffffffc0203ddc:	02800513          	li	a0,40
ffffffffc0203de0:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203de4:	05e00413          	li	s0,94
ffffffffc0203de8:	b565                	j	ffffffffc0203c90 <vprintfmt+0x208>

ffffffffc0203dea <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203dea:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203dec:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203df0:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203df2:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203df4:	ec06                	sd	ra,24(sp)
ffffffffc0203df6:	f83a                	sd	a4,48(sp)
ffffffffc0203df8:	fc3e                	sd	a5,56(sp)
ffffffffc0203dfa:	e0c2                	sd	a6,64(sp)
ffffffffc0203dfc:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203dfe:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203e00:	c89ff0ef          	jal	ra,ffffffffc0203a88 <vprintfmt>
}
ffffffffc0203e04:	60e2                	ld	ra,24(sp)
ffffffffc0203e06:	6161                	addi	sp,sp,80
ffffffffc0203e08:	8082                	ret

ffffffffc0203e0a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203e0a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0203e0e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0203e10:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0203e12:	cb81                	beqz	a5,ffffffffc0203e22 <strlen+0x18>
        cnt ++;
ffffffffc0203e14:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0203e16:	00a707b3          	add	a5,a4,a0
ffffffffc0203e1a:	0007c783          	lbu	a5,0(a5)
ffffffffc0203e1e:	fbfd                	bnez	a5,ffffffffc0203e14 <strlen+0xa>
ffffffffc0203e20:	8082                	ret
    }
    return cnt;
}
ffffffffc0203e22:	8082                	ret

ffffffffc0203e24 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203e24:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e26:	e589                	bnez	a1,ffffffffc0203e30 <strnlen+0xc>
ffffffffc0203e28:	a811                	j	ffffffffc0203e3c <strnlen+0x18>
        cnt ++;
ffffffffc0203e2a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e2c:	00f58863          	beq	a1,a5,ffffffffc0203e3c <strnlen+0x18>
ffffffffc0203e30:	00f50733          	add	a4,a0,a5
ffffffffc0203e34:	00074703          	lbu	a4,0(a4)
ffffffffc0203e38:	fb6d                	bnez	a4,ffffffffc0203e2a <strnlen+0x6>
ffffffffc0203e3a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203e3c:	852e                	mv	a0,a1
ffffffffc0203e3e:	8082                	ret

ffffffffc0203e40 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203e40:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203e42:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e46:	0785                	addi	a5,a5,1
ffffffffc0203e48:	0585                	addi	a1,a1,1
ffffffffc0203e4a:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203e4e:	fb75                	bnez	a4,ffffffffc0203e42 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203e50:	8082                	ret

ffffffffc0203e52 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e52:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e56:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e5a:	cb89                	beqz	a5,ffffffffc0203e6c <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0203e5c:	0505                	addi	a0,a0,1
ffffffffc0203e5e:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e60:	fee789e3          	beq	a5,a4,ffffffffc0203e52 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e64:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203e68:	9d19                	subw	a0,a0,a4
ffffffffc0203e6a:	8082                	ret
ffffffffc0203e6c:	4501                	li	a0,0
ffffffffc0203e6e:	bfed                	j	ffffffffc0203e68 <strcmp+0x16>

ffffffffc0203e70 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e70:	c20d                	beqz	a2,ffffffffc0203e92 <strncmp+0x22>
ffffffffc0203e72:	962e                	add	a2,a2,a1
ffffffffc0203e74:	a031                	j	ffffffffc0203e80 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0203e76:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e78:	00e79a63          	bne	a5,a4,ffffffffc0203e8c <strncmp+0x1c>
ffffffffc0203e7c:	00b60b63          	beq	a2,a1,ffffffffc0203e92 <strncmp+0x22>
ffffffffc0203e80:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203e84:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e86:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203e8a:	f7f5                	bnez	a5,ffffffffc0203e76 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e8c:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0203e90:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e92:	4501                	li	a0,0
ffffffffc0203e94:	8082                	ret

ffffffffc0203e96 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203e96:	00054783          	lbu	a5,0(a0)
ffffffffc0203e9a:	c799                	beqz	a5,ffffffffc0203ea8 <strchr+0x12>
        if (*s == c) {
ffffffffc0203e9c:	00f58763          	beq	a1,a5,ffffffffc0203eaa <strchr+0x14>
    while (*s != '\0') {
ffffffffc0203ea0:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0203ea4:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203ea6:	fbfd                	bnez	a5,ffffffffc0203e9c <strchr+0x6>
    }
    return NULL;
ffffffffc0203ea8:	4501                	li	a0,0
}
ffffffffc0203eaa:	8082                	ret

ffffffffc0203eac <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203eac:	ca01                	beqz	a2,ffffffffc0203ebc <memset+0x10>
ffffffffc0203eae:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203eb0:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203eb2:	0785                	addi	a5,a5,1
ffffffffc0203eb4:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203eb8:	fec79de3          	bne	a5,a2,ffffffffc0203eb2 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203ebc:	8082                	ret

ffffffffc0203ebe <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203ebe:	ca19                	beqz	a2,ffffffffc0203ed4 <memcpy+0x16>
ffffffffc0203ec0:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203ec2:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203ec4:	0005c703          	lbu	a4,0(a1)
ffffffffc0203ec8:	0585                	addi	a1,a1,1
ffffffffc0203eca:	0785                	addi	a5,a5,1
ffffffffc0203ecc:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203ed0:	fec59ae3          	bne	a1,a2,ffffffffc0203ec4 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203ed4:	8082                	ret

ffffffffc0203ed6 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203ed6:	c205                	beqz	a2,ffffffffc0203ef6 <memcmp+0x20>
ffffffffc0203ed8:	962e                	add	a2,a2,a1
ffffffffc0203eda:	a019                	j	ffffffffc0203ee0 <memcmp+0xa>
ffffffffc0203edc:	00c58d63          	beq	a1,a2,ffffffffc0203ef6 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203ee0:	00054783          	lbu	a5,0(a0)
ffffffffc0203ee4:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203ee8:	0505                	addi	a0,a0,1
ffffffffc0203eea:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203eec:	fee788e3          	beq	a5,a4,ffffffffc0203edc <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203ef0:	40e7853b          	subw	a0,a5,a4
ffffffffc0203ef4:	8082                	ret
    }
    return 0;
ffffffffc0203ef6:	4501                	li	a0,0
}
ffffffffc0203ef8:	8082                	ret
