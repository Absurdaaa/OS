
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
ffffffffc020004e:	fde50513          	addi	a0,a0,-34 # ffffffffc0209028 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49260613          	addi	a2,a2,1170 # ffffffffc020d4e4 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	668030ef          	jal	ra,ffffffffc02036ca <memset>
    dtb_init();
ffffffffc0200066:	452000ef          	jal	ra,ffffffffc02004b8 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	053000ef          	jal	ra,ffffffffc02008bc <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	ab258593          	addi	a1,a1,-1358 # ffffffffc0203b20 <etext+0x4>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	aca50513          	addi	a0,a0,-1334 # ffffffffc0203b40 <etext+0x24>
ffffffffc020007e:	062000ef          	jal	ra,ffffffffc02000e0 <cprintf>

    print_kerninfo();
ffffffffc0200082:	1b8000ef          	jal	ra,ffffffffc020023a <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	260010ef          	jal	ra,ffffffffc02012e6 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	0a5000ef          	jal	ra,ffffffffc020092e <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	0af000ef          	jal	ra,ffffffffc020093c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	7c9010ef          	jal	ra,ffffffffc020205a <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	21e030ef          	jal	ra,ffffffffc02032b4 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	7ce000ef          	jal	ra,ffffffffc0200868 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	093000ef          	jal	ra,ffffffffc0200930 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	4d6030ef          	jal	ra,ffffffffc0203578 <cpu_idle>

ffffffffc02000a6 <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc02000a6:	1141                	addi	sp,sp,-16
ffffffffc02000a8:	e022                	sd	s0,0(sp)
ffffffffc02000aa:	e406                	sd	ra,8(sp)
ffffffffc02000ac:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000ae:	011000ef          	jal	ra,ffffffffc02008be <cons_putc>
    (*cnt)++;
ffffffffc02000b2:	401c                	lw	a5,0(s0)
}
ffffffffc02000b4:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc02000b6:	2785                	addiw	a5,a5,1
ffffffffc02000b8:	c01c                	sw	a5,0(s0)
}
ffffffffc02000ba:	6402                	ld	s0,0(sp)
ffffffffc02000bc:	0141                	addi	sp,sp,16
ffffffffc02000be:	8082                	ret

ffffffffc02000c0 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc02000c0:	1101                	addi	sp,sp,-32
ffffffffc02000c2:	862a                	mv	a2,a0
ffffffffc02000c4:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000c6:	00000517          	auipc	a0,0x0
ffffffffc02000ca:	fe050513          	addi	a0,a0,-32 # ffffffffc02000a6 <cputch>
ffffffffc02000ce:	006c                	addi	a1,sp,12
{
ffffffffc02000d0:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000d2:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000d4:	6b0030ef          	jal	ra,ffffffffc0203784 <vprintfmt>
    return cnt;
}
ffffffffc02000d8:	60e2                	ld	ra,24(sp)
ffffffffc02000da:	4532                	lw	a0,12(sp)
ffffffffc02000dc:	6105                	addi	sp,sp,32
ffffffffc02000de:	8082                	ret

ffffffffc02000e0 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc02000e0:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000e2:	02810313          	addi	t1,sp,40 # ffffffffc0208028 <boot_page_table_sv39+0x28>
{
ffffffffc02000e6:	8e2a                	mv	t3,a0
ffffffffc02000e8:	f42e                	sd	a1,40(sp)
ffffffffc02000ea:	f832                	sd	a2,48(sp)
ffffffffc02000ec:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000ee:	00000517          	auipc	a0,0x0
ffffffffc02000f2:	fb850513          	addi	a0,a0,-72 # ffffffffc02000a6 <cputch>
ffffffffc02000f6:	004c                	addi	a1,sp,4
ffffffffc02000f8:	869a                	mv	a3,t1
ffffffffc02000fa:	8672                	mv	a2,t3
{
ffffffffc02000fc:	ec06                	sd	ra,24(sp)
ffffffffc02000fe:	e0ba                	sd	a4,64(sp)
ffffffffc0200100:	e4be                	sd	a5,72(sp)
ffffffffc0200102:	e8c2                	sd	a6,80(sp)
ffffffffc0200104:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200106:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200108:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020010a:	67a030ef          	jal	ra,ffffffffc0203784 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020010e:	60e2                	ld	ra,24(sp)
ffffffffc0200110:	4512                	lw	a0,4(sp)
ffffffffc0200112:	6125                	addi	sp,sp,96
ffffffffc0200114:	8082                	ret

ffffffffc0200116 <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc0200116:	7a80006f          	j	ffffffffc02008be <cons_putc>

ffffffffc020011a <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020011a:	1141                	addi	sp,sp,-16
ffffffffc020011c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020011e:	7d4000ef          	jal	ra,ffffffffc02008f2 <cons_getc>
ffffffffc0200122:	dd75                	beqz	a0,ffffffffc020011e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200124:	60a2                	ld	ra,8(sp)
ffffffffc0200126:	0141                	addi	sp,sp,16
ffffffffc0200128:	8082                	ret

ffffffffc020012a <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc020012a:	715d                	addi	sp,sp,-80
ffffffffc020012c:	e486                	sd	ra,72(sp)
ffffffffc020012e:	e0a6                	sd	s1,64(sp)
ffffffffc0200130:	fc4a                	sd	s2,56(sp)
ffffffffc0200132:	f84e                	sd	s3,48(sp)
ffffffffc0200134:	f452                	sd	s4,40(sp)
ffffffffc0200136:	f056                	sd	s5,32(sp)
ffffffffc0200138:	ec5a                	sd	s6,24(sp)
ffffffffc020013a:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc020013c:	c901                	beqz	a0,ffffffffc020014c <readline+0x22>
ffffffffc020013e:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0200140:	00004517          	auipc	a0,0x4
ffffffffc0200144:	a0850513          	addi	a0,a0,-1528 # ffffffffc0203b48 <etext+0x2c>
ffffffffc0200148:	f99ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
readline(const char *prompt) {
ffffffffc020014c:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020014e:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0200150:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0200152:	4aa9                	li	s5,10
ffffffffc0200154:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0200156:	00009b97          	auipc	s7,0x9
ffffffffc020015a:	ed2b8b93          	addi	s7,s7,-302 # ffffffffc0209028 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020015e:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0200162:	fb9ff0ef          	jal	ra,ffffffffc020011a <getchar>
        if (c < 0) {
ffffffffc0200166:	00054a63          	bltz	a0,ffffffffc020017a <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020016a:	00a95a63          	bge	s2,a0,ffffffffc020017e <readline+0x54>
ffffffffc020016e:	029a5263          	bge	s4,s1,ffffffffc0200192 <readline+0x68>
        c = getchar();
ffffffffc0200172:	fa9ff0ef          	jal	ra,ffffffffc020011a <getchar>
        if (c < 0) {
ffffffffc0200176:	fe055ae3          	bgez	a0,ffffffffc020016a <readline+0x40>
            return NULL;
ffffffffc020017a:	4501                	li	a0,0
ffffffffc020017c:	a091                	j	ffffffffc02001c0 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc020017e:	03351463          	bne	a0,s3,ffffffffc02001a6 <readline+0x7c>
ffffffffc0200182:	e8a9                	bnez	s1,ffffffffc02001d4 <readline+0xaa>
        c = getchar();
ffffffffc0200184:	f97ff0ef          	jal	ra,ffffffffc020011a <getchar>
        if (c < 0) {
ffffffffc0200188:	fe0549e3          	bltz	a0,ffffffffc020017a <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020018c:	fea959e3          	bge	s2,a0,ffffffffc020017e <readline+0x54>
ffffffffc0200190:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200192:	e42a                	sd	a0,8(sp)
ffffffffc0200194:	f83ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            buf[i ++] = c;
ffffffffc0200198:	6522                	ld	a0,8(sp)
ffffffffc020019a:	009b87b3          	add	a5,s7,s1
ffffffffc020019e:	2485                	addiw	s1,s1,1
ffffffffc02001a0:	00a78023          	sb	a0,0(a5)
ffffffffc02001a4:	bf7d                	j	ffffffffc0200162 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02001a6:	01550463          	beq	a0,s5,ffffffffc02001ae <readline+0x84>
ffffffffc02001aa:	fb651ce3          	bne	a0,s6,ffffffffc0200162 <readline+0x38>
            cputchar(c);
ffffffffc02001ae:	f69ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            buf[i] = '\0';
ffffffffc02001b2:	00009517          	auipc	a0,0x9
ffffffffc02001b6:	e7650513          	addi	a0,a0,-394 # ffffffffc0209028 <buf>
ffffffffc02001ba:	94aa                	add	s1,s1,a0
ffffffffc02001bc:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02001c0:	60a6                	ld	ra,72(sp)
ffffffffc02001c2:	6486                	ld	s1,64(sp)
ffffffffc02001c4:	7962                	ld	s2,56(sp)
ffffffffc02001c6:	79c2                	ld	s3,48(sp)
ffffffffc02001c8:	7a22                	ld	s4,40(sp)
ffffffffc02001ca:	7a82                	ld	s5,32(sp)
ffffffffc02001cc:	6b62                	ld	s6,24(sp)
ffffffffc02001ce:	6bc2                	ld	s7,16(sp)
ffffffffc02001d0:	6161                	addi	sp,sp,80
ffffffffc02001d2:	8082                	ret
            cputchar(c);
ffffffffc02001d4:	4521                	li	a0,8
ffffffffc02001d6:	f41ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            i --;
ffffffffc02001da:	34fd                	addiw	s1,s1,-1
ffffffffc02001dc:	b759                	j	ffffffffc0200162 <readline+0x38>

ffffffffc02001de <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001de:	0000d317          	auipc	t1,0xd
ffffffffc02001e2:	28230313          	addi	t1,t1,642 # ffffffffc020d460 <is_panic>
ffffffffc02001e6:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ea:	715d                	addi	sp,sp,-80
ffffffffc02001ec:	ec06                	sd	ra,24(sp)
ffffffffc02001ee:	e822                	sd	s0,16(sp)
ffffffffc02001f0:	f436                	sd	a3,40(sp)
ffffffffc02001f2:	f83a                	sd	a4,48(sp)
ffffffffc02001f4:	fc3e                	sd	a5,56(sp)
ffffffffc02001f6:	e0c2                	sd	a6,64(sp)
ffffffffc02001f8:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001fa:	020e1a63          	bnez	t3,ffffffffc020022e <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02001fe:	4785                	li	a5,1
ffffffffc0200200:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200204:	8432                	mv	s0,a2
ffffffffc0200206:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200208:	862e                	mv	a2,a1
ffffffffc020020a:	85aa                	mv	a1,a0
ffffffffc020020c:	00004517          	auipc	a0,0x4
ffffffffc0200210:	94450513          	addi	a0,a0,-1724 # ffffffffc0203b50 <etext+0x34>
    va_start(ap, fmt);
ffffffffc0200214:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200216:	ecbff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020021a:	65a2                	ld	a1,8(sp)
ffffffffc020021c:	8522                	mv	a0,s0
ffffffffc020021e:	ea3ff0ef          	jal	ra,ffffffffc02000c0 <vcprintf>
    cprintf("\n");
ffffffffc0200222:	00005517          	auipc	a0,0x5
ffffffffc0200226:	82e50513          	addi	a0,a0,-2002 # ffffffffc0204a50 <commands+0xca8>
ffffffffc020022a:	eb7ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020022e:	708000ef          	jal	ra,ffffffffc0200936 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200232:	4501                	li	a0,0
ffffffffc0200234:	130000ef          	jal	ra,ffffffffc0200364 <kmonitor>
    while (1) {
ffffffffc0200238:	bfed                	j	ffffffffc0200232 <__panic+0x54>

ffffffffc020023a <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020023a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020023c:	00004517          	auipc	a0,0x4
ffffffffc0200240:	93450513          	addi	a0,a0,-1740 # ffffffffc0203b70 <etext+0x54>
{
ffffffffc0200244:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200246:	e9bff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020024a:	00000597          	auipc	a1,0x0
ffffffffc020024e:	e0058593          	addi	a1,a1,-512 # ffffffffc020004a <kern_init>
ffffffffc0200252:	00004517          	auipc	a0,0x4
ffffffffc0200256:	93e50513          	addi	a0,a0,-1730 # ffffffffc0203b90 <etext+0x74>
ffffffffc020025a:	e87ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020025e:	00004597          	auipc	a1,0x4
ffffffffc0200262:	8be58593          	addi	a1,a1,-1858 # ffffffffc0203b1c <etext>
ffffffffc0200266:	00004517          	auipc	a0,0x4
ffffffffc020026a:	94a50513          	addi	a0,a0,-1718 # ffffffffc0203bb0 <etext+0x94>
ffffffffc020026e:	e73ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200272:	00009597          	auipc	a1,0x9
ffffffffc0200276:	db658593          	addi	a1,a1,-586 # ffffffffc0209028 <buf>
ffffffffc020027a:	00004517          	auipc	a0,0x4
ffffffffc020027e:	95650513          	addi	a0,a0,-1706 # ffffffffc0203bd0 <etext+0xb4>
ffffffffc0200282:	e5fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200286:	0000d597          	auipc	a1,0xd
ffffffffc020028a:	25e58593          	addi	a1,a1,606 # ffffffffc020d4e4 <end>
ffffffffc020028e:	00004517          	auipc	a0,0x4
ffffffffc0200292:	96250513          	addi	a0,a0,-1694 # ffffffffc0203bf0 <etext+0xd4>
ffffffffc0200296:	e4bff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020029a:	0000d597          	auipc	a1,0xd
ffffffffc020029e:	64958593          	addi	a1,a1,1609 # ffffffffc020d8e3 <end+0x3ff>
ffffffffc02002a2:	00000797          	auipc	a5,0x0
ffffffffc02002a6:	da878793          	addi	a5,a5,-600 # ffffffffc020004a <kern_init>
ffffffffc02002aa:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002ae:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02002b2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002b8:	95be                	add	a1,a1,a5
ffffffffc02002ba:	85a9                	srai	a1,a1,0xa
ffffffffc02002bc:	00004517          	auipc	a0,0x4
ffffffffc02002c0:	95450513          	addi	a0,a0,-1708 # ffffffffc0203c10 <etext+0xf4>
}
ffffffffc02002c4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002c6:	bd29                	j	ffffffffc02000e0 <cprintf>

ffffffffc02002c8 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002c8:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ca:	00004617          	auipc	a2,0x4
ffffffffc02002ce:	97660613          	addi	a2,a2,-1674 # ffffffffc0203c40 <etext+0x124>
ffffffffc02002d2:	04900593          	li	a1,73
ffffffffc02002d6:	00004517          	auipc	a0,0x4
ffffffffc02002da:	98250513          	addi	a0,a0,-1662 # ffffffffc0203c58 <etext+0x13c>
{
ffffffffc02002de:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002e0:	effff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc02002e4 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e4:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	00004617          	auipc	a2,0x4
ffffffffc02002ea:	98a60613          	addi	a2,a2,-1654 # ffffffffc0203c70 <etext+0x154>
ffffffffc02002ee:	00004597          	auipc	a1,0x4
ffffffffc02002f2:	9a258593          	addi	a1,a1,-1630 # ffffffffc0203c90 <etext+0x174>
ffffffffc02002f6:	00004517          	auipc	a0,0x4
ffffffffc02002fa:	9a250513          	addi	a0,a0,-1630 # ffffffffc0203c98 <etext+0x17c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002fe:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200300:	de1ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc0200304:	00004617          	auipc	a2,0x4
ffffffffc0200308:	9a460613          	addi	a2,a2,-1628 # ffffffffc0203ca8 <etext+0x18c>
ffffffffc020030c:	00004597          	auipc	a1,0x4
ffffffffc0200310:	9c458593          	addi	a1,a1,-1596 # ffffffffc0203cd0 <etext+0x1b4>
ffffffffc0200314:	00004517          	auipc	a0,0x4
ffffffffc0200318:	98450513          	addi	a0,a0,-1660 # ffffffffc0203c98 <etext+0x17c>
ffffffffc020031c:	dc5ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc0200320:	00004617          	auipc	a2,0x4
ffffffffc0200324:	9c060613          	addi	a2,a2,-1600 # ffffffffc0203ce0 <etext+0x1c4>
ffffffffc0200328:	00004597          	auipc	a1,0x4
ffffffffc020032c:	9d858593          	addi	a1,a1,-1576 # ffffffffc0203d00 <etext+0x1e4>
ffffffffc0200330:	00004517          	auipc	a0,0x4
ffffffffc0200334:	96850513          	addi	a0,a0,-1688 # ffffffffc0203c98 <etext+0x17c>
ffffffffc0200338:	da9ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    }
    return 0;
}
ffffffffc020033c:	60a2                	ld	ra,8(sp)
ffffffffc020033e:	4501                	li	a0,0
ffffffffc0200340:	0141                	addi	sp,sp,16
ffffffffc0200342:	8082                	ret

ffffffffc0200344 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200344:	1141                	addi	sp,sp,-16
ffffffffc0200346:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200348:	ef3ff0ef          	jal	ra,ffffffffc020023a <print_kerninfo>
    return 0;
}
ffffffffc020034c:	60a2                	ld	ra,8(sp)
ffffffffc020034e:	4501                	li	a0,0
ffffffffc0200350:	0141                	addi	sp,sp,16
ffffffffc0200352:	8082                	ret

ffffffffc0200354 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200354:	1141                	addi	sp,sp,-16
ffffffffc0200356:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200358:	f71ff0ef          	jal	ra,ffffffffc02002c8 <print_stackframe>
    return 0;
}
ffffffffc020035c:	60a2                	ld	ra,8(sp)
ffffffffc020035e:	4501                	li	a0,0
ffffffffc0200360:	0141                	addi	sp,sp,16
ffffffffc0200362:	8082                	ret

ffffffffc0200364 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200364:	7115                	addi	sp,sp,-224
ffffffffc0200366:	ed5e                	sd	s7,152(sp)
ffffffffc0200368:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	00004517          	auipc	a0,0x4
ffffffffc020036e:	9a650513          	addi	a0,a0,-1626 # ffffffffc0203d10 <etext+0x1f4>
kmonitor(struct trapframe *tf) {
ffffffffc0200372:	ed86                	sd	ra,216(sp)
ffffffffc0200374:	e9a2                	sd	s0,208(sp)
ffffffffc0200376:	e5a6                	sd	s1,200(sp)
ffffffffc0200378:	e1ca                	sd	s2,192(sp)
ffffffffc020037a:	fd4e                	sd	s3,184(sp)
ffffffffc020037c:	f952                	sd	s4,176(sp)
ffffffffc020037e:	f556                	sd	s5,168(sp)
ffffffffc0200380:	f15a                	sd	s6,160(sp)
ffffffffc0200382:	e962                	sd	s8,144(sp)
ffffffffc0200384:	e566                	sd	s9,136(sp)
ffffffffc0200386:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200388:	d59ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020038c:	00004517          	auipc	a0,0x4
ffffffffc0200390:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0203d38 <etext+0x21c>
ffffffffc0200394:	d4dff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    if (tf != NULL) {
ffffffffc0200398:	000b8563          	beqz	s7,ffffffffc02003a2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020039c:	855e                	mv	a0,s7
ffffffffc020039e:	786000ef          	jal	ra,ffffffffc0200b24 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02003a2:	4501                	li	a0,0
ffffffffc02003a4:	4581                	li	a1,0
ffffffffc02003a6:	4601                	li	a2,0
ffffffffc02003a8:	48a1                	li	a7,8
ffffffffc02003aa:	00000073          	ecall
ffffffffc02003ae:	00004c17          	auipc	s8,0x4
ffffffffc02003b2:	9fac0c13          	addi	s8,s8,-1542 # ffffffffc0203da8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003b6:	00004917          	auipc	s2,0x4
ffffffffc02003ba:	9aa90913          	addi	s2,s2,-1622 # ffffffffc0203d60 <etext+0x244>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003be:	00004497          	auipc	s1,0x4
ffffffffc02003c2:	9aa48493          	addi	s1,s1,-1622 # ffffffffc0203d68 <etext+0x24c>
        if (argc == MAXARGS - 1) {
ffffffffc02003c6:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003c8:	00004b17          	auipc	s6,0x4
ffffffffc02003cc:	9a8b0b13          	addi	s6,s6,-1624 # ffffffffc0203d70 <etext+0x254>
        argv[argc ++] = buf;
ffffffffc02003d0:	00004a17          	auipc	s4,0x4
ffffffffc02003d4:	8c0a0a13          	addi	s4,s4,-1856 # ffffffffc0203c90 <etext+0x174>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d8:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003da:	854a                	mv	a0,s2
ffffffffc02003dc:	d4fff0ef          	jal	ra,ffffffffc020012a <readline>
ffffffffc02003e0:	842a                	mv	s0,a0
ffffffffc02003e2:	dd65                	beqz	a0,ffffffffc02003da <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003e4:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003e8:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ea:	e1bd                	bnez	a1,ffffffffc0200450 <kmonitor+0xec>
    if (argc == 0) {
ffffffffc02003ec:	fe0c87e3          	beqz	s9,ffffffffc02003da <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003f0:	6582                	ld	a1,0(sp)
ffffffffc02003f2:	00004d17          	auipc	s10,0x4
ffffffffc02003f6:	9b6d0d13          	addi	s10,s10,-1610 # ffffffffc0203da8 <commands>
        argv[argc ++] = buf;
ffffffffc02003fa:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003fc:	4401                	li	s0,0
ffffffffc02003fe:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200400:	270030ef          	jal	ra,ffffffffc0203670 <strcmp>
ffffffffc0200404:	c919                	beqz	a0,ffffffffc020041a <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200406:	2405                	addiw	s0,s0,1
ffffffffc0200408:	0b540063          	beq	s0,s5,ffffffffc02004a8 <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020040c:	000d3503          	ld	a0,0(s10)
ffffffffc0200410:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200412:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200414:	25c030ef          	jal	ra,ffffffffc0203670 <strcmp>
ffffffffc0200418:	f57d                	bnez	a0,ffffffffc0200406 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020041a:	00141793          	slli	a5,s0,0x1
ffffffffc020041e:	97a2                	add	a5,a5,s0
ffffffffc0200420:	078e                	slli	a5,a5,0x3
ffffffffc0200422:	97e2                	add	a5,a5,s8
ffffffffc0200424:	6b9c                	ld	a5,16(a5)
ffffffffc0200426:	865e                	mv	a2,s7
ffffffffc0200428:	002c                	addi	a1,sp,8
ffffffffc020042a:	fffc851b          	addiw	a0,s9,-1
ffffffffc020042e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200430:	fa0555e3          	bgez	a0,ffffffffc02003da <kmonitor+0x76>
}
ffffffffc0200434:	60ee                	ld	ra,216(sp)
ffffffffc0200436:	644e                	ld	s0,208(sp)
ffffffffc0200438:	64ae                	ld	s1,200(sp)
ffffffffc020043a:	690e                	ld	s2,192(sp)
ffffffffc020043c:	79ea                	ld	s3,184(sp)
ffffffffc020043e:	7a4a                	ld	s4,176(sp)
ffffffffc0200440:	7aaa                	ld	s5,168(sp)
ffffffffc0200442:	7b0a                	ld	s6,160(sp)
ffffffffc0200444:	6bea                	ld	s7,152(sp)
ffffffffc0200446:	6c4a                	ld	s8,144(sp)
ffffffffc0200448:	6caa                	ld	s9,136(sp)
ffffffffc020044a:	6d0a                	ld	s10,128(sp)
ffffffffc020044c:	612d                	addi	sp,sp,224
ffffffffc020044e:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200450:	8526                	mv	a0,s1
ffffffffc0200452:	262030ef          	jal	ra,ffffffffc02036b4 <strchr>
ffffffffc0200456:	c901                	beqz	a0,ffffffffc0200466 <kmonitor+0x102>
ffffffffc0200458:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc020045c:	00040023          	sb	zero,0(s0)
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200462:	d5c9                	beqz	a1,ffffffffc02003ec <kmonitor+0x88>
ffffffffc0200464:	b7f5                	j	ffffffffc0200450 <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200466:	00044783          	lbu	a5,0(s0)
ffffffffc020046a:	d3c9                	beqz	a5,ffffffffc02003ec <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc020046c:	033c8963          	beq	s9,s3,ffffffffc020049e <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc0200470:	003c9793          	slli	a5,s9,0x3
ffffffffc0200474:	0118                	addi	a4,sp,128
ffffffffc0200476:	97ba                	add	a5,a5,a4
ffffffffc0200478:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020047c:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200480:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200482:	e591                	bnez	a1,ffffffffc020048e <kmonitor+0x12a>
ffffffffc0200484:	b7b5                	j	ffffffffc02003f0 <kmonitor+0x8c>
ffffffffc0200486:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020048a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020048c:	d1a5                	beqz	a1,ffffffffc02003ec <kmonitor+0x88>
ffffffffc020048e:	8526                	mv	a0,s1
ffffffffc0200490:	224030ef          	jal	ra,ffffffffc02036b4 <strchr>
ffffffffc0200494:	d96d                	beqz	a0,ffffffffc0200486 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200496:	00044583          	lbu	a1,0(s0)
ffffffffc020049a:	d9a9                	beqz	a1,ffffffffc02003ec <kmonitor+0x88>
ffffffffc020049c:	bf55                	j	ffffffffc0200450 <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020049e:	45c1                	li	a1,16
ffffffffc02004a0:	855a                	mv	a0,s6
ffffffffc02004a2:	c3fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc02004a6:	b7e9                	j	ffffffffc0200470 <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02004a8:	6582                	ld	a1,0(sp)
ffffffffc02004aa:	00004517          	auipc	a0,0x4
ffffffffc02004ae:	8e650513          	addi	a0,a0,-1818 # ffffffffc0203d90 <etext+0x274>
ffffffffc02004b2:	c2fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    return 0;
ffffffffc02004b6:	b715                	j	ffffffffc02003da <kmonitor+0x76>

ffffffffc02004b8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02004b8:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02004ba:	00004517          	auipc	a0,0x4
ffffffffc02004be:	93650513          	addi	a0,a0,-1738 # ffffffffc0203df0 <commands+0x48>
void dtb_init(void) {
ffffffffc02004c2:	fc86                	sd	ra,120(sp)
ffffffffc02004c4:	f8a2                	sd	s0,112(sp)
ffffffffc02004c6:	e8d2                	sd	s4,80(sp)
ffffffffc02004c8:	f4a6                	sd	s1,104(sp)
ffffffffc02004ca:	f0ca                	sd	s2,96(sp)
ffffffffc02004cc:	ecce                	sd	s3,88(sp)
ffffffffc02004ce:	e4d6                	sd	s5,72(sp)
ffffffffc02004d0:	e0da                	sd	s6,64(sp)
ffffffffc02004d2:	fc5e                	sd	s7,56(sp)
ffffffffc02004d4:	f862                	sd	s8,48(sp)
ffffffffc02004d6:	f466                	sd	s9,40(sp)
ffffffffc02004d8:	f06a                	sd	s10,32(sp)
ffffffffc02004da:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004dc:	c05ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004e0:	00009597          	auipc	a1,0x9
ffffffffc02004e4:	b205b583          	ld	a1,-1248(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc02004e8:	00004517          	auipc	a0,0x4
ffffffffc02004ec:	91850513          	addi	a0,a0,-1768 # ffffffffc0203e00 <commands+0x58>
ffffffffc02004f0:	bf1ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004f4:	00009417          	auipc	s0,0x9
ffffffffc02004f8:	b1440413          	addi	s0,s0,-1260 # ffffffffc0209008 <boot_dtb>
ffffffffc02004fc:	600c                	ld	a1,0(s0)
ffffffffc02004fe:	00004517          	auipc	a0,0x4
ffffffffc0200502:	91250513          	addi	a0,a0,-1774 # ffffffffc0203e10 <commands+0x68>
ffffffffc0200506:	bdbff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020050a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020050e:	00004517          	auipc	a0,0x4
ffffffffc0200512:	91a50513          	addi	a0,a0,-1766 # ffffffffc0203e28 <commands+0x80>
    if (boot_dtb == 0) {
ffffffffc0200516:	120a0463          	beqz	s4,ffffffffc020063e <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020051a:	57f5                	li	a5,-3
ffffffffc020051c:	07fa                	slli	a5,a5,0x1e
ffffffffc020051e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200522:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200524:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200528:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020052e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200532:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200536:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053e:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200540:	8ec9                	or	a3,a3,a0
ffffffffc0200542:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200546:	1b7d                	addi	s6,s6,-1
ffffffffc0200548:	0167f7b3          	and	a5,a5,s6
ffffffffc020054c:	8dd5                	or	a1,a1,a3
ffffffffc020054e:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200550:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200554:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200556:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed2a09>
ffffffffc020055a:	10f59163          	bne	a1,a5,ffffffffc020065c <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020055e:	471c                	lw	a5,8(a4)
ffffffffc0200560:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200562:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200564:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200568:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020056c:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200570:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200574:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200578:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020057c:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200580:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200584:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200588:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020058c:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058e:	01146433          	or	s0,s0,a7
ffffffffc0200592:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200596:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020059a:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020059c:	0087979b          	slliw	a5,a5,0x8
ffffffffc02005a0:	8c49                	or	s0,s0,a0
ffffffffc02005a2:	0166f6b3          	and	a3,a3,s6
ffffffffc02005a6:	00ca6a33          	or	s4,s4,a2
ffffffffc02005aa:	0167f7b3          	and	a5,a5,s6
ffffffffc02005ae:	8c55                	or	s0,s0,a3
ffffffffc02005b0:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b4:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005b6:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b8:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005ba:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005be:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005c0:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c2:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc02005c6:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005c8:	00004917          	auipc	s2,0x4
ffffffffc02005cc:	8b090913          	addi	s2,s2,-1872 # ffffffffc0203e78 <commands+0xd0>
ffffffffc02005d0:	49bd                	li	s3,15
        switch (token) {
ffffffffc02005d2:	4d91                	li	s11,4
ffffffffc02005d4:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005d6:	00004497          	auipc	s1,0x4
ffffffffc02005da:	89a48493          	addi	s1,s1,-1894 # ffffffffc0203e70 <commands+0xc8>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005de:	000a2703          	lw	a4,0(s4)
ffffffffc02005e2:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e6:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005ea:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ee:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f2:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f6:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005fa:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005fc:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200600:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200604:	8fd5                	or	a5,a5,a3
ffffffffc0200606:	00eb7733          	and	a4,s6,a4
ffffffffc020060a:	8fd9                	or	a5,a5,a4
ffffffffc020060c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020060e:	09778c63          	beq	a5,s7,ffffffffc02006a6 <dtb_init+0x1ee>
ffffffffc0200612:	00fbea63          	bltu	s7,a5,ffffffffc0200626 <dtb_init+0x16e>
ffffffffc0200616:	07a78663          	beq	a5,s10,ffffffffc0200682 <dtb_init+0x1ca>
ffffffffc020061a:	4709                	li	a4,2
ffffffffc020061c:	00e79763          	bne	a5,a4,ffffffffc020062a <dtb_init+0x172>
ffffffffc0200620:	4c81                	li	s9,0
ffffffffc0200622:	8a56                	mv	s4,s5
ffffffffc0200624:	bf6d                	j	ffffffffc02005de <dtb_init+0x126>
ffffffffc0200626:	ffb78ee3          	beq	a5,s11,ffffffffc0200622 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020062a:	00004517          	auipc	a0,0x4
ffffffffc020062e:	8c650513          	addi	a0,a0,-1850 # ffffffffc0203ef0 <commands+0x148>
ffffffffc0200632:	aafff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200636:	00004517          	auipc	a0,0x4
ffffffffc020063a:	8f250513          	addi	a0,a0,-1806 # ffffffffc0203f28 <commands+0x180>
}
ffffffffc020063e:	7446                	ld	s0,112(sp)
ffffffffc0200640:	70e6                	ld	ra,120(sp)
ffffffffc0200642:	74a6                	ld	s1,104(sp)
ffffffffc0200644:	7906                	ld	s2,96(sp)
ffffffffc0200646:	69e6                	ld	s3,88(sp)
ffffffffc0200648:	6a46                	ld	s4,80(sp)
ffffffffc020064a:	6aa6                	ld	s5,72(sp)
ffffffffc020064c:	6b06                	ld	s6,64(sp)
ffffffffc020064e:	7be2                	ld	s7,56(sp)
ffffffffc0200650:	7c42                	ld	s8,48(sp)
ffffffffc0200652:	7ca2                	ld	s9,40(sp)
ffffffffc0200654:	7d02                	ld	s10,32(sp)
ffffffffc0200656:	6de2                	ld	s11,24(sp)
ffffffffc0200658:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020065a:	b459                	j	ffffffffc02000e0 <cprintf>
}
ffffffffc020065c:	7446                	ld	s0,112(sp)
ffffffffc020065e:	70e6                	ld	ra,120(sp)
ffffffffc0200660:	74a6                	ld	s1,104(sp)
ffffffffc0200662:	7906                	ld	s2,96(sp)
ffffffffc0200664:	69e6                	ld	s3,88(sp)
ffffffffc0200666:	6a46                	ld	s4,80(sp)
ffffffffc0200668:	6aa6                	ld	s5,72(sp)
ffffffffc020066a:	6b06                	ld	s6,64(sp)
ffffffffc020066c:	7be2                	ld	s7,56(sp)
ffffffffc020066e:	7c42                	ld	s8,48(sp)
ffffffffc0200670:	7ca2                	ld	s9,40(sp)
ffffffffc0200672:	7d02                	ld	s10,32(sp)
ffffffffc0200674:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200676:	00003517          	auipc	a0,0x3
ffffffffc020067a:	7d250513          	addi	a0,a0,2002 # ffffffffc0203e48 <commands+0xa0>
}
ffffffffc020067e:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200680:	b485                	j	ffffffffc02000e0 <cprintf>
                int name_len = strlen(name);
ffffffffc0200682:	8556                	mv	a0,s5
ffffffffc0200684:	7a5020ef          	jal	ra,ffffffffc0203628 <strlen>
ffffffffc0200688:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020068a:	4619                	li	a2,6
ffffffffc020068c:	85a6                	mv	a1,s1
ffffffffc020068e:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200690:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200692:	7fd020ef          	jal	ra,ffffffffc020368e <strncmp>
ffffffffc0200696:	e111                	bnez	a0,ffffffffc020069a <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200698:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020069a:	0a91                	addi	s5,s5,4
ffffffffc020069c:	9ad2                	add	s5,s5,s4
ffffffffc020069e:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006a2:	8a56                	mv	s4,s5
ffffffffc02006a4:	bf2d                	j	ffffffffc02005de <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a6:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006aa:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ae:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02006b2:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006c2:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c6:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ca:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006ce:	00eaeab3          	or	s5,s5,a4
ffffffffc02006d2:	00fb77b3          	and	a5,s6,a5
ffffffffc02006d6:	00faeab3          	or	s5,s5,a5
ffffffffc02006da:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006dc:	000c9c63          	bnez	s9,ffffffffc02006f4 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006e0:	1a82                	slli	s5,s5,0x20
ffffffffc02006e2:	00368793          	addi	a5,a3,3
ffffffffc02006e6:	020ada93          	srli	s5,s5,0x20
ffffffffc02006ea:	9abe                	add	s5,s5,a5
ffffffffc02006ec:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006f0:	8a56                	mv	s4,s5
ffffffffc02006f2:	b5f5                	j	ffffffffc02005de <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006f4:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f8:	85ca                	mv	a1,s2
ffffffffc02006fa:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fc:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200700:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200704:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200708:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020070c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200710:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200712:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200716:	0087979b          	slliw	a5,a5,0x8
ffffffffc020071a:	8d59                	or	a0,a0,a4
ffffffffc020071c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200720:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200722:	1502                	slli	a0,a0,0x20
ffffffffc0200724:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200726:	9522                	add	a0,a0,s0
ffffffffc0200728:	749020ef          	jal	ra,ffffffffc0203670 <strcmp>
ffffffffc020072c:	66a2                	ld	a3,8(sp)
ffffffffc020072e:	f94d                	bnez	a0,ffffffffc02006e0 <dtb_init+0x228>
ffffffffc0200730:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006e0 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200734:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200738:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020073c:	00003517          	auipc	a0,0x3
ffffffffc0200740:	74450513          	addi	a0,a0,1860 # ffffffffc0203e80 <commands+0xd8>
           fdt32_to_cpu(x >> 32);
ffffffffc0200744:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200748:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020074c:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200750:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200754:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200758:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020075c:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200760:	0187d693          	srli	a3,a5,0x18
ffffffffc0200764:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200768:	0087579b          	srliw	a5,a4,0x8
ffffffffc020076c:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200770:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200774:	010f6f33          	or	t5,t5,a6
ffffffffc0200778:	0187529b          	srliw	t0,a4,0x18
ffffffffc020077c:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200780:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200784:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	0186f6b3          	and	a3,a3,s8
ffffffffc020078c:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200790:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200794:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200798:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020079c:	8361                	srli	a4,a4,0x18
ffffffffc020079e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02007a6:	01e6e6b3          	or	a3,a3,t5
ffffffffc02007aa:	00cb7633          	and	a2,s6,a2
ffffffffc02007ae:	0088181b          	slliw	a6,a6,0x8
ffffffffc02007b2:	0085959b          	slliw	a1,a1,0x8
ffffffffc02007b6:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ba:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007be:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c2:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c6:	0088989b          	slliw	a7,a7,0x8
ffffffffc02007ca:	011b78b3          	and	a7,s6,a7
ffffffffc02007ce:	005eeeb3          	or	t4,t4,t0
ffffffffc02007d2:	00c6e733          	or	a4,a3,a2
ffffffffc02007d6:	006c6c33          	or	s8,s8,t1
ffffffffc02007da:	010b76b3          	and	a3,s6,a6
ffffffffc02007de:	00bb7b33          	and	s6,s6,a1
ffffffffc02007e2:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007e6:	016c6b33          	or	s6,s8,s6
ffffffffc02007ea:	01146433          	or	s0,s0,a7
ffffffffc02007ee:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007f0:	1702                	slli	a4,a4,0x20
ffffffffc02007f2:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007f4:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007f6:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007f8:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007fa:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007fe:	0167eb33          	or	s6,a5,s6
ffffffffc0200802:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200804:	8ddff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200808:	85a2                	mv	a1,s0
ffffffffc020080a:	00003517          	auipc	a0,0x3
ffffffffc020080e:	69650513          	addi	a0,a0,1686 # ffffffffc0203ea0 <commands+0xf8>
ffffffffc0200812:	8cfff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200816:	014b5613          	srli	a2,s6,0x14
ffffffffc020081a:	85da                	mv	a1,s6
ffffffffc020081c:	00003517          	auipc	a0,0x3
ffffffffc0200820:	69c50513          	addi	a0,a0,1692 # ffffffffc0203eb8 <commands+0x110>
ffffffffc0200824:	8bdff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200828:	008b05b3          	add	a1,s6,s0
ffffffffc020082c:	15fd                	addi	a1,a1,-1
ffffffffc020082e:	00003517          	auipc	a0,0x3
ffffffffc0200832:	6aa50513          	addi	a0,a0,1706 # ffffffffc0203ed8 <commands+0x130>
ffffffffc0200836:	8abff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc020083a:	00003517          	auipc	a0,0x3
ffffffffc020083e:	6ee50513          	addi	a0,a0,1774 # ffffffffc0203f28 <commands+0x180>
        memory_base = mem_base;
ffffffffc0200842:	0000d797          	auipc	a5,0xd
ffffffffc0200846:	c287b323          	sd	s0,-986(a5) # ffffffffc020d468 <memory_base>
        memory_size = mem_size;
ffffffffc020084a:	0000d797          	auipc	a5,0xd
ffffffffc020084e:	c367b323          	sd	s6,-986(a5) # ffffffffc020d470 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200852:	b3f5                	j	ffffffffc020063e <dtb_init+0x186>

ffffffffc0200854 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200854:	0000d517          	auipc	a0,0xd
ffffffffc0200858:	c1453503          	ld	a0,-1004(a0) # ffffffffc020d468 <memory_base>
ffffffffc020085c:	8082                	ret

ffffffffc020085e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc020085e:	0000d517          	auipc	a0,0xd
ffffffffc0200862:	c1253503          	ld	a0,-1006(a0) # ffffffffc020d470 <memory_size>
ffffffffc0200866:	8082                	ret

ffffffffc0200868 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200868:	67e1                	lui	a5,0x18
ffffffffc020086a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020086e:	0000d717          	auipc	a4,0xd
ffffffffc0200872:	c0f73923          	sd	a5,-1006(a4) # ffffffffc020d480 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200876:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020087a:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020087c:	953e                	add	a0,a0,a5
ffffffffc020087e:	4601                	li	a2,0
ffffffffc0200880:	4881                	li	a7,0
ffffffffc0200882:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200886:	02000793          	li	a5,32
ffffffffc020088a:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020088e:	00003517          	auipc	a0,0x3
ffffffffc0200892:	6b250513          	addi	a0,a0,1714 # ffffffffc0203f40 <commands+0x198>
    ticks = 0;
ffffffffc0200896:	0000d797          	auipc	a5,0xd
ffffffffc020089a:	be07b123          	sd	zero,-1054(a5) # ffffffffc020d478 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020089e:	843ff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc02008a2 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02008a2:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02008a6:	0000d797          	auipc	a5,0xd
ffffffffc02008aa:	bda7b783          	ld	a5,-1062(a5) # ffffffffc020d480 <timebase>
ffffffffc02008ae:	953e                	add	a0,a0,a5
ffffffffc02008b0:	4581                	li	a1,0
ffffffffc02008b2:	4601                	li	a2,0
ffffffffc02008b4:	4881                	li	a7,0
ffffffffc02008b6:	00000073          	ecall
ffffffffc02008ba:	8082                	ret

ffffffffc02008bc <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02008bc:	8082                	ret

ffffffffc02008be <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02008be:	100027f3          	csrr	a5,sstatus
ffffffffc02008c2:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02008c4:	0ff57513          	zext.b	a0,a0
ffffffffc02008c8:	e799                	bnez	a5,ffffffffc02008d6 <cons_putc+0x18>
ffffffffc02008ca:	4581                	li	a1,0
ffffffffc02008cc:	4601                	li	a2,0
ffffffffc02008ce:	4885                	li	a7,1
ffffffffc02008d0:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02008d4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02008d6:	1101                	addi	sp,sp,-32
ffffffffc02008d8:	ec06                	sd	ra,24(sp)
ffffffffc02008da:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02008dc:	05a000ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc02008e0:	6522                	ld	a0,8(sp)
ffffffffc02008e2:	4581                	li	a1,0
ffffffffc02008e4:	4601                	li	a2,0
ffffffffc02008e6:	4885                	li	a7,1
ffffffffc02008e8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02008ec:	60e2                	ld	ra,24(sp)
ffffffffc02008ee:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02008f0:	a081                	j	ffffffffc0200930 <intr_enable>

ffffffffc02008f2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02008f2:	100027f3          	csrr	a5,sstatus
ffffffffc02008f6:	8b89                	andi	a5,a5,2
ffffffffc02008f8:	eb89                	bnez	a5,ffffffffc020090a <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02008fa:	4501                	li	a0,0
ffffffffc02008fc:	4581                	li	a1,0
ffffffffc02008fe:	4601                	li	a2,0
ffffffffc0200900:	4889                	li	a7,2
ffffffffc0200902:	00000073          	ecall
ffffffffc0200906:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200908:	8082                	ret
int cons_getc(void) {
ffffffffc020090a:	1101                	addi	sp,sp,-32
ffffffffc020090c:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020090e:	028000ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc0200912:	4501                	li	a0,0
ffffffffc0200914:	4581                	li	a1,0
ffffffffc0200916:	4601                	li	a2,0
ffffffffc0200918:	4889                	li	a7,2
ffffffffc020091a:	00000073          	ecall
ffffffffc020091e:	2501                	sext.w	a0,a0
ffffffffc0200920:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200922:	00e000ef          	jal	ra,ffffffffc0200930 <intr_enable>
}
ffffffffc0200926:	60e2                	ld	ra,24(sp)
ffffffffc0200928:	6522                	ld	a0,8(sp)
ffffffffc020092a:	6105                	addi	sp,sp,32
ffffffffc020092c:	8082                	ret

ffffffffc020092e <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020092e:	8082                	ret

ffffffffc0200930 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200930:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200934:	8082                	ret

ffffffffc0200936 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200936:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020093a:	8082                	ret

ffffffffc020093c <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020093c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200940:	00000797          	auipc	a5,0x0
ffffffffc0200944:	3f078793          	addi	a5,a5,1008 # ffffffffc0200d30 <__alltraps>
ffffffffc0200948:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020094c:	000407b7          	lui	a5,0x40
ffffffffc0200950:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200954:	8082                	ret

ffffffffc0200956 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200956:	610c                	ld	a1,0(a0)
{
ffffffffc0200958:	1141                	addi	sp,sp,-16
ffffffffc020095a:	e022                	sd	s0,0(sp)
ffffffffc020095c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020095e:	00003517          	auipc	a0,0x3
ffffffffc0200962:	60250513          	addi	a0,a0,1538 # ffffffffc0203f60 <commands+0x1b8>
{
ffffffffc0200966:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200968:	f78ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020096c:	640c                	ld	a1,8(s0)
ffffffffc020096e:	00003517          	auipc	a0,0x3
ffffffffc0200972:	60a50513          	addi	a0,a0,1546 # ffffffffc0203f78 <commands+0x1d0>
ffffffffc0200976:	f6aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020097a:	680c                	ld	a1,16(s0)
ffffffffc020097c:	00003517          	auipc	a0,0x3
ffffffffc0200980:	61450513          	addi	a0,a0,1556 # ffffffffc0203f90 <commands+0x1e8>
ffffffffc0200984:	f5cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200988:	6c0c                	ld	a1,24(s0)
ffffffffc020098a:	00003517          	auipc	a0,0x3
ffffffffc020098e:	61e50513          	addi	a0,a0,1566 # ffffffffc0203fa8 <commands+0x200>
ffffffffc0200992:	f4eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200996:	700c                	ld	a1,32(s0)
ffffffffc0200998:	00003517          	auipc	a0,0x3
ffffffffc020099c:	62850513          	addi	a0,a0,1576 # ffffffffc0203fc0 <commands+0x218>
ffffffffc02009a0:	f40ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02009a4:	740c                	ld	a1,40(s0)
ffffffffc02009a6:	00003517          	auipc	a0,0x3
ffffffffc02009aa:	63250513          	addi	a0,a0,1586 # ffffffffc0203fd8 <commands+0x230>
ffffffffc02009ae:	f32ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02009b2:	780c                	ld	a1,48(s0)
ffffffffc02009b4:	00003517          	auipc	a0,0x3
ffffffffc02009b8:	63c50513          	addi	a0,a0,1596 # ffffffffc0203ff0 <commands+0x248>
ffffffffc02009bc:	f24ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02009c0:	7c0c                	ld	a1,56(s0)
ffffffffc02009c2:	00003517          	auipc	a0,0x3
ffffffffc02009c6:	64650513          	addi	a0,a0,1606 # ffffffffc0204008 <commands+0x260>
ffffffffc02009ca:	f16ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02009ce:	602c                	ld	a1,64(s0)
ffffffffc02009d0:	00003517          	auipc	a0,0x3
ffffffffc02009d4:	65050513          	addi	a0,a0,1616 # ffffffffc0204020 <commands+0x278>
ffffffffc02009d8:	f08ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009dc:	642c                	ld	a1,72(s0)
ffffffffc02009de:	00003517          	auipc	a0,0x3
ffffffffc02009e2:	65a50513          	addi	a0,a0,1626 # ffffffffc0204038 <commands+0x290>
ffffffffc02009e6:	efaff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009ea:	682c                	ld	a1,80(s0)
ffffffffc02009ec:	00003517          	auipc	a0,0x3
ffffffffc02009f0:	66450513          	addi	a0,a0,1636 # ffffffffc0204050 <commands+0x2a8>
ffffffffc02009f4:	eecff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009f8:	6c2c                	ld	a1,88(s0)
ffffffffc02009fa:	00003517          	auipc	a0,0x3
ffffffffc02009fe:	66e50513          	addi	a0,a0,1646 # ffffffffc0204068 <commands+0x2c0>
ffffffffc0200a02:	edeff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a06:	702c                	ld	a1,96(s0)
ffffffffc0200a08:	00003517          	auipc	a0,0x3
ffffffffc0200a0c:	67850513          	addi	a0,a0,1656 # ffffffffc0204080 <commands+0x2d8>
ffffffffc0200a10:	ed0ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a14:	742c                	ld	a1,104(s0)
ffffffffc0200a16:	00003517          	auipc	a0,0x3
ffffffffc0200a1a:	68250513          	addi	a0,a0,1666 # ffffffffc0204098 <commands+0x2f0>
ffffffffc0200a1e:	ec2ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a22:	782c                	ld	a1,112(s0)
ffffffffc0200a24:	00003517          	auipc	a0,0x3
ffffffffc0200a28:	68c50513          	addi	a0,a0,1676 # ffffffffc02040b0 <commands+0x308>
ffffffffc0200a2c:	eb4ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a30:	7c2c                	ld	a1,120(s0)
ffffffffc0200a32:	00003517          	auipc	a0,0x3
ffffffffc0200a36:	69650513          	addi	a0,a0,1686 # ffffffffc02040c8 <commands+0x320>
ffffffffc0200a3a:	ea6ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a3e:	604c                	ld	a1,128(s0)
ffffffffc0200a40:	00003517          	auipc	a0,0x3
ffffffffc0200a44:	6a050513          	addi	a0,a0,1696 # ffffffffc02040e0 <commands+0x338>
ffffffffc0200a48:	e98ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a4c:	644c                	ld	a1,136(s0)
ffffffffc0200a4e:	00003517          	auipc	a0,0x3
ffffffffc0200a52:	6aa50513          	addi	a0,a0,1706 # ffffffffc02040f8 <commands+0x350>
ffffffffc0200a56:	e8aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a5a:	684c                	ld	a1,144(s0)
ffffffffc0200a5c:	00003517          	auipc	a0,0x3
ffffffffc0200a60:	6b450513          	addi	a0,a0,1716 # ffffffffc0204110 <commands+0x368>
ffffffffc0200a64:	e7cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a68:	6c4c                	ld	a1,152(s0)
ffffffffc0200a6a:	00003517          	auipc	a0,0x3
ffffffffc0200a6e:	6be50513          	addi	a0,a0,1726 # ffffffffc0204128 <commands+0x380>
ffffffffc0200a72:	e6eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a76:	704c                	ld	a1,160(s0)
ffffffffc0200a78:	00003517          	auipc	a0,0x3
ffffffffc0200a7c:	6c850513          	addi	a0,a0,1736 # ffffffffc0204140 <commands+0x398>
ffffffffc0200a80:	e60ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a84:	744c                	ld	a1,168(s0)
ffffffffc0200a86:	00003517          	auipc	a0,0x3
ffffffffc0200a8a:	6d250513          	addi	a0,a0,1746 # ffffffffc0204158 <commands+0x3b0>
ffffffffc0200a8e:	e52ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a92:	784c                	ld	a1,176(s0)
ffffffffc0200a94:	00003517          	auipc	a0,0x3
ffffffffc0200a98:	6dc50513          	addi	a0,a0,1756 # ffffffffc0204170 <commands+0x3c8>
ffffffffc0200a9c:	e44ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200aa0:	7c4c                	ld	a1,184(s0)
ffffffffc0200aa2:	00003517          	auipc	a0,0x3
ffffffffc0200aa6:	6e650513          	addi	a0,a0,1766 # ffffffffc0204188 <commands+0x3e0>
ffffffffc0200aaa:	e36ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200aae:	606c                	ld	a1,192(s0)
ffffffffc0200ab0:	00003517          	auipc	a0,0x3
ffffffffc0200ab4:	6f050513          	addi	a0,a0,1776 # ffffffffc02041a0 <commands+0x3f8>
ffffffffc0200ab8:	e28ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200abc:	646c                	ld	a1,200(s0)
ffffffffc0200abe:	00003517          	auipc	a0,0x3
ffffffffc0200ac2:	6fa50513          	addi	a0,a0,1786 # ffffffffc02041b8 <commands+0x410>
ffffffffc0200ac6:	e1aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200aca:	686c                	ld	a1,208(s0)
ffffffffc0200acc:	00003517          	auipc	a0,0x3
ffffffffc0200ad0:	70450513          	addi	a0,a0,1796 # ffffffffc02041d0 <commands+0x428>
ffffffffc0200ad4:	e0cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200ad8:	6c6c                	ld	a1,216(s0)
ffffffffc0200ada:	00003517          	auipc	a0,0x3
ffffffffc0200ade:	70e50513          	addi	a0,a0,1806 # ffffffffc02041e8 <commands+0x440>
ffffffffc0200ae2:	dfeff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ae6:	706c                	ld	a1,224(s0)
ffffffffc0200ae8:	00003517          	auipc	a0,0x3
ffffffffc0200aec:	71850513          	addi	a0,a0,1816 # ffffffffc0204200 <commands+0x458>
ffffffffc0200af0:	df0ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200af4:	746c                	ld	a1,232(s0)
ffffffffc0200af6:	00003517          	auipc	a0,0x3
ffffffffc0200afa:	72250513          	addi	a0,a0,1826 # ffffffffc0204218 <commands+0x470>
ffffffffc0200afe:	de2ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b02:	786c                	ld	a1,240(s0)
ffffffffc0200b04:	00003517          	auipc	a0,0x3
ffffffffc0200b08:	72c50513          	addi	a0,a0,1836 # ffffffffc0204230 <commands+0x488>
ffffffffc0200b0c:	dd4ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b10:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b12:	6402                	ld	s0,0(sp)
ffffffffc0200b14:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b16:	00003517          	auipc	a0,0x3
ffffffffc0200b1a:	73250513          	addi	a0,a0,1842 # ffffffffc0204248 <commands+0x4a0>
}
ffffffffc0200b1e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b20:	dc0ff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc0200b24 <print_trapframe>:
{
ffffffffc0200b24:	1141                	addi	sp,sp,-16
ffffffffc0200b26:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b28:	85aa                	mv	a1,a0
{
ffffffffc0200b2a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b2c:	00003517          	auipc	a0,0x3
ffffffffc0200b30:	73450513          	addi	a0,a0,1844 # ffffffffc0204260 <commands+0x4b8>
{
ffffffffc0200b34:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b36:	daaff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b3a:	8522                	mv	a0,s0
ffffffffc0200b3c:	e1bff0ef          	jal	ra,ffffffffc0200956 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b40:	10043583          	ld	a1,256(s0)
ffffffffc0200b44:	00003517          	auipc	a0,0x3
ffffffffc0200b48:	73450513          	addi	a0,a0,1844 # ffffffffc0204278 <commands+0x4d0>
ffffffffc0200b4c:	d94ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b50:	10843583          	ld	a1,264(s0)
ffffffffc0200b54:	00003517          	auipc	a0,0x3
ffffffffc0200b58:	73c50513          	addi	a0,a0,1852 # ffffffffc0204290 <commands+0x4e8>
ffffffffc0200b5c:	d84ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b60:	11043583          	ld	a1,272(s0)
ffffffffc0200b64:	00003517          	auipc	a0,0x3
ffffffffc0200b68:	74450513          	addi	a0,a0,1860 # ffffffffc02042a8 <commands+0x500>
ffffffffc0200b6c:	d74ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b70:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b74:	6402                	ld	s0,0(sp)
ffffffffc0200b76:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b78:	00003517          	auipc	a0,0x3
ffffffffc0200b7c:	74850513          	addi	a0,a0,1864 # ffffffffc02042c0 <commands+0x518>
}
ffffffffc0200b80:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b82:	d5eff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc0200b86 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200b86:	11853783          	ld	a5,280(a0)
ffffffffc0200b8a:	472d                	li	a4,11
ffffffffc0200b8c:	0786                	slli	a5,a5,0x1
ffffffffc0200b8e:	8385                	srli	a5,a5,0x1
ffffffffc0200b90:	08f76663          	bltu	a4,a5,ffffffffc0200c1c <interrupt_handler+0x96>
ffffffffc0200b94:	00004717          	auipc	a4,0x4
ffffffffc0200b98:	81470713          	addi	a4,a4,-2028 # ffffffffc02043a8 <commands+0x600>
ffffffffc0200b9c:	078a                	slli	a5,a5,0x2
ffffffffc0200b9e:	97ba                	add	a5,a5,a4
ffffffffc0200ba0:	439c                	lw	a5,0(a5)
ffffffffc0200ba2:	97ba                	add	a5,a5,a4
ffffffffc0200ba4:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200ba6:	00003517          	auipc	a0,0x3
ffffffffc0200baa:	79250513          	addi	a0,a0,1938 # ffffffffc0204338 <commands+0x590>
ffffffffc0200bae:	d32ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200bb2:	00003517          	auipc	a0,0x3
ffffffffc0200bb6:	76650513          	addi	a0,a0,1894 # ffffffffc0204318 <commands+0x570>
ffffffffc0200bba:	d26ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200bbe:	00003517          	auipc	a0,0x3
ffffffffc0200bc2:	71a50513          	addi	a0,a0,1818 # ffffffffc02042d8 <commands+0x530>
ffffffffc0200bc6:	d1aff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200bca:	00003517          	auipc	a0,0x3
ffffffffc0200bce:	72e50513          	addi	a0,a0,1838 # ffffffffc02042f8 <commands+0x550>
ffffffffc0200bd2:	d0eff06f          	j	ffffffffc02000e0 <cprintf>
{
ffffffffc0200bd6:	1141                	addi	sp,sp,-16
ffffffffc0200bd8:	e022                	sd	s0,0(sp)
ffffffffc0200bda:	e406                	sd	ra,8(sp)
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        /*LAB3 请补充你在lab3中的代码 */ 
        clock_set_next_event(); // 发生这次时钟中断的时候，我们要设置下一次时钟中断
ffffffffc0200bdc:	cc7ff0ef          	jal	ra,ffffffffc02008a2 <clock_set_next_event>
        if (++ticks % TICK_NUM == 0)
ffffffffc0200be0:	0000d697          	auipc	a3,0xd
ffffffffc0200be4:	89868693          	addi	a3,a3,-1896 # ffffffffc020d478 <ticks>
ffffffffc0200be8:	629c                	ld	a5,0(a3)
ffffffffc0200bea:	06400713          	li	a4,100
ffffffffc0200bee:	0000d417          	auipc	s0,0xd
ffffffffc0200bf2:	89a40413          	addi	s0,s0,-1894 # ffffffffc020d488 <print_num>
ffffffffc0200bf6:	0785                	addi	a5,a5,1
ffffffffc0200bf8:	02e7f733          	remu	a4,a5,a4
ffffffffc0200bfc:	e29c                	sd	a5,0(a3)
ffffffffc0200bfe:	c305                	beqz	a4,ffffffffc0200c1e <interrupt_handler+0x98>
        {
            print_num++;
            print_ticks();
        }
        if (print_num == 10)
ffffffffc0200c00:	4018                	lw	a4,0(s0)
ffffffffc0200c02:	47a9                	li	a5,10
ffffffffc0200c04:	02f70963          	beq	a4,a5,ffffffffc0200c36 <interrupt_handler+0xb0>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c08:	60a2                	ld	ra,8(sp)
ffffffffc0200c0a:	6402                	ld	s0,0(sp)
ffffffffc0200c0c:	0141                	addi	sp,sp,16
ffffffffc0200c0e:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c10:	00003517          	auipc	a0,0x3
ffffffffc0200c14:	77850513          	addi	a0,a0,1912 # ffffffffc0204388 <commands+0x5e0>
ffffffffc0200c18:	cc8ff06f          	j	ffffffffc02000e0 <cprintf>
        print_trapframe(tf);
ffffffffc0200c1c:	b721                	j	ffffffffc0200b24 <print_trapframe>
            print_num++;
ffffffffc0200c1e:	401c                	lw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c20:	06400593          	li	a1,100
ffffffffc0200c24:	00003517          	auipc	a0,0x3
ffffffffc0200c28:	73450513          	addi	a0,a0,1844 # ffffffffc0204358 <commands+0x5b0>
            print_num++;
ffffffffc0200c2c:	2785                	addiw	a5,a5,1
ffffffffc0200c2e:	c01c                	sw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c30:	cb0ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}
ffffffffc0200c34:	b7f1                	j	ffffffffc0200c00 <interrupt_handler+0x7a>
            cprintf("Calling SBI shutdown...\n");
ffffffffc0200c36:	00003517          	auipc	a0,0x3
ffffffffc0200c3a:	73250513          	addi	a0,a0,1842 # ffffffffc0204368 <commands+0x5c0>
ffffffffc0200c3e:	ca2ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200c42:	4501                	li	a0,0
ffffffffc0200c44:	4581                	li	a1,0
ffffffffc0200c46:	4601                	li	a2,0
ffffffffc0200c48:	48a1                	li	a7,8
ffffffffc0200c4a:	00000073          	ecall
}
ffffffffc0200c4e:	bf6d                	j	ffffffffc0200c08 <interrupt_handler+0x82>

ffffffffc0200c50 <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c50:	11853783          	ld	a5,280(a0)
ffffffffc0200c54:	473d                	li	a4,15
ffffffffc0200c56:	0cf76563          	bltu	a4,a5,ffffffffc0200d20 <exception_handler+0xd0>
ffffffffc0200c5a:	00004717          	auipc	a4,0x4
ffffffffc0200c5e:	91670713          	addi	a4,a4,-1770 # ffffffffc0204570 <commands+0x7c8>
ffffffffc0200c62:	078a                	slli	a5,a5,0x2
ffffffffc0200c64:	97ba                	add	a5,a5,a4
ffffffffc0200c66:	439c                	lw	a5,0(a5)
ffffffffc0200c68:	97ba                	add	a5,a5,a4
ffffffffc0200c6a:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200c6c:	00004517          	auipc	a0,0x4
ffffffffc0200c70:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0204558 <commands+0x7b0>
ffffffffc0200c74:	c6cff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200c78:	00003517          	auipc	a0,0x3
ffffffffc0200c7c:	76050513          	addi	a0,a0,1888 # ffffffffc02043d8 <commands+0x630>
ffffffffc0200c80:	c60ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200c84:	00003517          	auipc	a0,0x3
ffffffffc0200c88:	77450513          	addi	a0,a0,1908 # ffffffffc02043f8 <commands+0x650>
ffffffffc0200c8c:	c54ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200c90:	00003517          	auipc	a0,0x3
ffffffffc0200c94:	78850513          	addi	a0,a0,1928 # ffffffffc0204418 <commands+0x670>
ffffffffc0200c98:	c48ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200c9c:	00003517          	auipc	a0,0x3
ffffffffc0200ca0:	79450513          	addi	a0,a0,1940 # ffffffffc0204430 <commands+0x688>
ffffffffc0200ca4:	c3cff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200ca8:	00003517          	auipc	a0,0x3
ffffffffc0200cac:	79850513          	addi	a0,a0,1944 # ffffffffc0204440 <commands+0x698>
ffffffffc0200cb0:	c30ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200cb4:	00003517          	auipc	a0,0x3
ffffffffc0200cb8:	7ac50513          	addi	a0,a0,1964 # ffffffffc0204460 <commands+0x6b8>
ffffffffc0200cbc:	c24ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200cc0:	00003517          	auipc	a0,0x3
ffffffffc0200cc4:	7b850513          	addi	a0,a0,1976 # ffffffffc0204478 <commands+0x6d0>
ffffffffc0200cc8:	c18ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200ccc:	00003517          	auipc	a0,0x3
ffffffffc0200cd0:	7c450513          	addi	a0,a0,1988 # ffffffffc0204490 <commands+0x6e8>
ffffffffc0200cd4:	c0cff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200cd8:	00003517          	auipc	a0,0x3
ffffffffc0200cdc:	7d050513          	addi	a0,a0,2000 # ffffffffc02044a8 <commands+0x700>
ffffffffc0200ce0:	c00ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200ce4:	00003517          	auipc	a0,0x3
ffffffffc0200ce8:	7e450513          	addi	a0,a0,2020 # ffffffffc02044c8 <commands+0x720>
ffffffffc0200cec:	bf4ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cf0:	00003517          	auipc	a0,0x3
ffffffffc0200cf4:	7f850513          	addi	a0,a0,2040 # ffffffffc02044e8 <commands+0x740>
ffffffffc0200cf8:	be8ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200cfc:	00004517          	auipc	a0,0x4
ffffffffc0200d00:	80c50513          	addi	a0,a0,-2036 # ffffffffc0204508 <commands+0x760>
ffffffffc0200d04:	bdcff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200d08:	00004517          	auipc	a0,0x4
ffffffffc0200d0c:	82050513          	addi	a0,a0,-2016 # ffffffffc0204528 <commands+0x780>
ffffffffc0200d10:	bd0ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200d14:	00004517          	auipc	a0,0x4
ffffffffc0200d18:	82c50513          	addi	a0,a0,-2004 # ffffffffc0204540 <commands+0x798>
ffffffffc0200d1c:	bc4ff06f          	j	ffffffffc02000e0 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200d20:	b511                	j	ffffffffc0200b24 <print_trapframe>

ffffffffc0200d22 <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d22:	11853783          	ld	a5,280(a0)
ffffffffc0200d26:	0007c363          	bltz	a5,ffffffffc0200d2c <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200d2a:	b71d                	j	ffffffffc0200c50 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200d2c:	bda9                	j	ffffffffc0200b86 <interrupt_handler>
	...

ffffffffc0200d30 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200d30:	14011073          	csrw	sscratch,sp
ffffffffc0200d34:	712d                	addi	sp,sp,-288
ffffffffc0200d36:	e406                	sd	ra,8(sp)
ffffffffc0200d38:	ec0e                	sd	gp,24(sp)
ffffffffc0200d3a:	f012                	sd	tp,32(sp)
ffffffffc0200d3c:	f416                	sd	t0,40(sp)
ffffffffc0200d3e:	f81a                	sd	t1,48(sp)
ffffffffc0200d40:	fc1e                	sd	t2,56(sp)
ffffffffc0200d42:	e0a2                	sd	s0,64(sp)
ffffffffc0200d44:	e4a6                	sd	s1,72(sp)
ffffffffc0200d46:	e8aa                	sd	a0,80(sp)
ffffffffc0200d48:	ecae                	sd	a1,88(sp)
ffffffffc0200d4a:	f0b2                	sd	a2,96(sp)
ffffffffc0200d4c:	f4b6                	sd	a3,104(sp)
ffffffffc0200d4e:	f8ba                	sd	a4,112(sp)
ffffffffc0200d50:	fcbe                	sd	a5,120(sp)
ffffffffc0200d52:	e142                	sd	a6,128(sp)
ffffffffc0200d54:	e546                	sd	a7,136(sp)
ffffffffc0200d56:	e94a                	sd	s2,144(sp)
ffffffffc0200d58:	ed4e                	sd	s3,152(sp)
ffffffffc0200d5a:	f152                	sd	s4,160(sp)
ffffffffc0200d5c:	f556                	sd	s5,168(sp)
ffffffffc0200d5e:	f95a                	sd	s6,176(sp)
ffffffffc0200d60:	fd5e                	sd	s7,184(sp)
ffffffffc0200d62:	e1e2                	sd	s8,192(sp)
ffffffffc0200d64:	e5e6                	sd	s9,200(sp)
ffffffffc0200d66:	e9ea                	sd	s10,208(sp)
ffffffffc0200d68:	edee                	sd	s11,216(sp)
ffffffffc0200d6a:	f1f2                	sd	t3,224(sp)
ffffffffc0200d6c:	f5f6                	sd	t4,232(sp)
ffffffffc0200d6e:	f9fa                	sd	t5,240(sp)
ffffffffc0200d70:	fdfe                	sd	t6,248(sp)
ffffffffc0200d72:	14002473          	csrr	s0,sscratch
ffffffffc0200d76:	100024f3          	csrr	s1,sstatus
ffffffffc0200d7a:	14102973          	csrr	s2,sepc
ffffffffc0200d7e:	143029f3          	csrr	s3,stval
ffffffffc0200d82:	14202a73          	csrr	s4,scause
ffffffffc0200d86:	e822                	sd	s0,16(sp)
ffffffffc0200d88:	e226                	sd	s1,256(sp)
ffffffffc0200d8a:	e64a                	sd	s2,264(sp)
ffffffffc0200d8c:	ea4e                	sd	s3,272(sp)
ffffffffc0200d8e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d90:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d92:	f91ff0ef          	jal	ra,ffffffffc0200d22 <trap>

ffffffffc0200d96 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d96:	6492                	ld	s1,256(sp)
ffffffffc0200d98:	6932                	ld	s2,264(sp)
ffffffffc0200d9a:	10049073          	csrw	sstatus,s1
ffffffffc0200d9e:	14191073          	csrw	sepc,s2
ffffffffc0200da2:	60a2                	ld	ra,8(sp)
ffffffffc0200da4:	61e2                	ld	gp,24(sp)
ffffffffc0200da6:	7202                	ld	tp,32(sp)
ffffffffc0200da8:	72a2                	ld	t0,40(sp)
ffffffffc0200daa:	7342                	ld	t1,48(sp)
ffffffffc0200dac:	73e2                	ld	t2,56(sp)
ffffffffc0200dae:	6406                	ld	s0,64(sp)
ffffffffc0200db0:	64a6                	ld	s1,72(sp)
ffffffffc0200db2:	6546                	ld	a0,80(sp)
ffffffffc0200db4:	65e6                	ld	a1,88(sp)
ffffffffc0200db6:	7606                	ld	a2,96(sp)
ffffffffc0200db8:	76a6                	ld	a3,104(sp)
ffffffffc0200dba:	7746                	ld	a4,112(sp)
ffffffffc0200dbc:	77e6                	ld	a5,120(sp)
ffffffffc0200dbe:	680a                	ld	a6,128(sp)
ffffffffc0200dc0:	68aa                	ld	a7,136(sp)
ffffffffc0200dc2:	694a                	ld	s2,144(sp)
ffffffffc0200dc4:	69ea                	ld	s3,152(sp)
ffffffffc0200dc6:	7a0a                	ld	s4,160(sp)
ffffffffc0200dc8:	7aaa                	ld	s5,168(sp)
ffffffffc0200dca:	7b4a                	ld	s6,176(sp)
ffffffffc0200dcc:	7bea                	ld	s7,184(sp)
ffffffffc0200dce:	6c0e                	ld	s8,192(sp)
ffffffffc0200dd0:	6cae                	ld	s9,200(sp)
ffffffffc0200dd2:	6d4e                	ld	s10,208(sp)
ffffffffc0200dd4:	6dee                	ld	s11,216(sp)
ffffffffc0200dd6:	7e0e                	ld	t3,224(sp)
ffffffffc0200dd8:	7eae                	ld	t4,232(sp)
ffffffffc0200dda:	7f4e                	ld	t5,240(sp)
ffffffffc0200ddc:	7fee                	ld	t6,248(sp)
ffffffffc0200dde:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200de0:	10200073          	sret

ffffffffc0200de4 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200de4:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200de6:	bf45                	j	ffffffffc0200d96 <__trapret>
	...

ffffffffc0200dea <pa2page.part.0>:
{
    return page2ppn(page) << PGSHIFT;
}

static inline struct Page *
pa2page(uintptr_t pa)
ffffffffc0200dea:	1141                	addi	sp,sp,-16
{
    if (PPN(pa) >= npage)
    {
        panic("pa2page called with invalid pa");
ffffffffc0200dec:	00003617          	auipc	a2,0x3
ffffffffc0200df0:	7c460613          	addi	a2,a2,1988 # ffffffffc02045b0 <commands+0x808>
ffffffffc0200df4:	06900593          	li	a1,105
ffffffffc0200df8:	00003517          	auipc	a0,0x3
ffffffffc0200dfc:	7d850513          	addi	a0,a0,2008 # ffffffffc02045d0 <commands+0x828>
pa2page(uintptr_t pa)
ffffffffc0200e00:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200e02:	bdcff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0200e06 <pte2page.part.0>:
{
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte)
ffffffffc0200e06:	1141                	addi	sp,sp,-16
{
    if (!(pte & PTE_V))
    {
        panic("pte2page called with invalid pte");
ffffffffc0200e08:	00003617          	auipc	a2,0x3
ffffffffc0200e0c:	7d860613          	addi	a2,a2,2008 # ffffffffc02045e0 <commands+0x838>
ffffffffc0200e10:	07f00593          	li	a1,127
ffffffffc0200e14:	00003517          	auipc	a0,0x3
ffffffffc0200e18:	7bc50513          	addi	a0,a0,1980 # ffffffffc02045d0 <commands+0x828>
pte2page(pte_t pte)
ffffffffc0200e1c:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0200e1e:	bc0ff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0200e22 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200e22:	100027f3          	csrr	a5,sstatus
ffffffffc0200e26:	8b89                	andi	a5,a5,2
ffffffffc0200e28:	e799                	bnez	a5,ffffffffc0200e36 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200e2a:	0000c797          	auipc	a5,0xc
ffffffffc0200e2e:	6867b783          	ld	a5,1670(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200e32:	6f9c                	ld	a5,24(a5)
ffffffffc0200e34:	8782                	jr	a5
{
ffffffffc0200e36:	1141                	addi	sp,sp,-16
ffffffffc0200e38:	e406                	sd	ra,8(sp)
ffffffffc0200e3a:	e022                	sd	s0,0(sp)
ffffffffc0200e3c:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200e3e:	af9ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200e42:	0000c797          	auipc	a5,0xc
ffffffffc0200e46:	66e7b783          	ld	a5,1646(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200e4a:	6f9c                	ld	a5,24(a5)
ffffffffc0200e4c:	8522                	mv	a0,s0
ffffffffc0200e4e:	9782                	jalr	a5
ffffffffc0200e50:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200e52:	adfff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200e56:	60a2                	ld	ra,8(sp)
ffffffffc0200e58:	8522                	mv	a0,s0
ffffffffc0200e5a:	6402                	ld	s0,0(sp)
ffffffffc0200e5c:	0141                	addi	sp,sp,16
ffffffffc0200e5e:	8082                	ret

ffffffffc0200e60 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200e60:	100027f3          	csrr	a5,sstatus
ffffffffc0200e64:	8b89                	andi	a5,a5,2
ffffffffc0200e66:	e799                	bnez	a5,ffffffffc0200e74 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200e68:	0000c797          	auipc	a5,0xc
ffffffffc0200e6c:	6487b783          	ld	a5,1608(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200e70:	739c                	ld	a5,32(a5)
ffffffffc0200e72:	8782                	jr	a5
{
ffffffffc0200e74:	1101                	addi	sp,sp,-32
ffffffffc0200e76:	ec06                	sd	ra,24(sp)
ffffffffc0200e78:	e822                	sd	s0,16(sp)
ffffffffc0200e7a:	e426                	sd	s1,8(sp)
ffffffffc0200e7c:	842a                	mv	s0,a0
ffffffffc0200e7e:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200e80:	ab7ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200e84:	0000c797          	auipc	a5,0xc
ffffffffc0200e88:	62c7b783          	ld	a5,1580(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200e8c:	739c                	ld	a5,32(a5)
ffffffffc0200e8e:	85a6                	mv	a1,s1
ffffffffc0200e90:	8522                	mv	a0,s0
ffffffffc0200e92:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200e94:	6442                	ld	s0,16(sp)
ffffffffc0200e96:	60e2                	ld	ra,24(sp)
ffffffffc0200e98:	64a2                	ld	s1,8(sp)
ffffffffc0200e9a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200e9c:	bc51                	j	ffffffffc0200930 <intr_enable>

ffffffffc0200e9e <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200e9e:	100027f3          	csrr	a5,sstatus
ffffffffc0200ea2:	8b89                	andi	a5,a5,2
ffffffffc0200ea4:	e799                	bnez	a5,ffffffffc0200eb2 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200ea6:	0000c797          	auipc	a5,0xc
ffffffffc0200eaa:	60a7b783          	ld	a5,1546(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200eae:	779c                	ld	a5,40(a5)
ffffffffc0200eb0:	8782                	jr	a5
{
ffffffffc0200eb2:	1141                	addi	sp,sp,-16
ffffffffc0200eb4:	e406                	sd	ra,8(sp)
ffffffffc0200eb6:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200eb8:	a7fff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200ebc:	0000c797          	auipc	a5,0xc
ffffffffc0200ec0:	5f47b783          	ld	a5,1524(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200ec4:	779c                	ld	a5,40(a5)
ffffffffc0200ec6:	9782                	jalr	a5
ffffffffc0200ec8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200eca:	a67ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200ece:	60a2                	ld	ra,8(sp)
ffffffffc0200ed0:	8522                	mv	a0,s0
ffffffffc0200ed2:	6402                	ld	s0,0(sp)
ffffffffc0200ed4:	0141                	addi	sp,sp,16
ffffffffc0200ed6:	8082                	ret

ffffffffc0200ed8 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200ed8:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0200edc:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0200ee0:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200ee2:	078e                	slli	a5,a5,0x3
{
ffffffffc0200ee4:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200ee6:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0200eea:	6094                	ld	a3,0(s1)
{
ffffffffc0200eec:	f04a                	sd	s2,32(sp)
ffffffffc0200eee:	ec4e                	sd	s3,24(sp)
ffffffffc0200ef0:	e852                	sd	s4,16(sp)
ffffffffc0200ef2:	fc06                	sd	ra,56(sp)
ffffffffc0200ef4:	f822                	sd	s0,48(sp)
ffffffffc0200ef6:	e456                	sd	s5,8(sp)
ffffffffc0200ef8:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0200efa:	0016f793          	andi	a5,a3,1
{
ffffffffc0200efe:	892e                	mv	s2,a1
ffffffffc0200f00:	8a32                	mv	s4,a2
ffffffffc0200f02:	0000c997          	auipc	s3,0xc
ffffffffc0200f06:	59e98993          	addi	s3,s3,1438 # ffffffffc020d4a0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0200f0a:	efbd                	bnez	a5,ffffffffc0200f88 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200f0c:	14060c63          	beqz	a2,ffffffffc0201064 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200f10:	100027f3          	csrr	a5,sstatus
ffffffffc0200f14:	8b89                	andi	a5,a5,2
ffffffffc0200f16:	14079963          	bnez	a5,ffffffffc0201068 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200f1a:	0000c797          	auipc	a5,0xc
ffffffffc0200f1e:	5967b783          	ld	a5,1430(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200f22:	6f9c                	ld	a5,24(a5)
ffffffffc0200f24:	4505                	li	a0,1
ffffffffc0200f26:	9782                	jalr	a5
ffffffffc0200f28:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200f2a:	12040d63          	beqz	s0,ffffffffc0201064 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0200f2e:	0000cb17          	auipc	s6,0xc
ffffffffc0200f32:	57ab0b13          	addi	s6,s6,1402 # ffffffffc020d4a8 <pages>
ffffffffc0200f36:	000b3503          	ld	a0,0(s6)
ffffffffc0200f3a:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200f3e:	0000c997          	auipc	s3,0xc
ffffffffc0200f42:	56298993          	addi	s3,s3,1378 # ffffffffc020d4a0 <npage>
ffffffffc0200f46:	40a40533          	sub	a0,s0,a0
ffffffffc0200f4a:	8519                	srai	a0,a0,0x6
ffffffffc0200f4c:	9556                	add	a0,a0,s5
ffffffffc0200f4e:	0009b703          	ld	a4,0(s3)
ffffffffc0200f52:	00c51793          	slli	a5,a0,0xc
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0200f56:	4685                	li	a3,1
ffffffffc0200f58:	c014                	sw	a3,0(s0)
ffffffffc0200f5a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f5c:	0532                	slli	a0,a0,0xc
ffffffffc0200f5e:	16e7f763          	bgeu	a5,a4,ffffffffc02010cc <get_pte+0x1f4>
ffffffffc0200f62:	0000c797          	auipc	a5,0xc
ffffffffc0200f66:	5567b783          	ld	a5,1366(a5) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0200f6a:	6605                	lui	a2,0x1
ffffffffc0200f6c:	4581                	li	a1,0
ffffffffc0200f6e:	953e                	add	a0,a0,a5
ffffffffc0200f70:	75a020ef          	jal	ra,ffffffffc02036ca <memset>
    return page - pages + nbase;
ffffffffc0200f74:	000b3683          	ld	a3,0(s6)
ffffffffc0200f78:	40d406b3          	sub	a3,s0,a3
ffffffffc0200f7c:	8699                	srai	a3,a3,0x6
ffffffffc0200f7e:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200f80:	06aa                	slli	a3,a3,0xa
ffffffffc0200f82:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0200f86:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0200f88:	77fd                	lui	a5,0xfffff
ffffffffc0200f8a:	068a                	slli	a3,a3,0x2
ffffffffc0200f8c:	0009b703          	ld	a4,0(s3)
ffffffffc0200f90:	8efd                	and	a3,a3,a5
ffffffffc0200f92:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200f96:	10e7ff63          	bgeu	a5,a4,ffffffffc02010b4 <get_pte+0x1dc>
ffffffffc0200f9a:	0000ca97          	auipc	s5,0xc
ffffffffc0200f9e:	51ea8a93          	addi	s5,s5,1310 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0200fa2:	000ab403          	ld	s0,0(s5)
ffffffffc0200fa6:	01595793          	srli	a5,s2,0x15
ffffffffc0200faa:	1ff7f793          	andi	a5,a5,511
ffffffffc0200fae:	96a2                	add	a3,a3,s0
ffffffffc0200fb0:	00379413          	slli	s0,a5,0x3
ffffffffc0200fb4:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0200fb6:	6014                	ld	a3,0(s0)
ffffffffc0200fb8:	0016f793          	andi	a5,a3,1
ffffffffc0200fbc:	ebad                	bnez	a5,ffffffffc020102e <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200fbe:	0a0a0363          	beqz	s4,ffffffffc0201064 <get_pte+0x18c>
ffffffffc0200fc2:	100027f3          	csrr	a5,sstatus
ffffffffc0200fc6:	8b89                	andi	a5,a5,2
ffffffffc0200fc8:	efcd                	bnez	a5,ffffffffc0201082 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200fca:	0000c797          	auipc	a5,0xc
ffffffffc0200fce:	4e67b783          	ld	a5,1254(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200fd2:	6f9c                	ld	a5,24(a5)
ffffffffc0200fd4:	4505                	li	a0,1
ffffffffc0200fd6:	9782                	jalr	a5
ffffffffc0200fd8:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200fda:	c4c9                	beqz	s1,ffffffffc0201064 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0200fdc:	0000cb17          	auipc	s6,0xc
ffffffffc0200fe0:	4ccb0b13          	addi	s6,s6,1228 # ffffffffc020d4a8 <pages>
ffffffffc0200fe4:	000b3503          	ld	a0,0(s6)
ffffffffc0200fe8:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200fec:	0009b703          	ld	a4,0(s3)
ffffffffc0200ff0:	40a48533          	sub	a0,s1,a0
ffffffffc0200ff4:	8519                	srai	a0,a0,0x6
ffffffffc0200ff6:	9552                	add	a0,a0,s4
ffffffffc0200ff8:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0200ffc:	4685                	li	a3,1
ffffffffc0200ffe:	c094                	sw	a3,0(s1)
ffffffffc0201000:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201002:	0532                	slli	a0,a0,0xc
ffffffffc0201004:	0ee7f163          	bgeu	a5,a4,ffffffffc02010e6 <get_pte+0x20e>
ffffffffc0201008:	000ab783          	ld	a5,0(s5)
ffffffffc020100c:	6605                	lui	a2,0x1
ffffffffc020100e:	4581                	li	a1,0
ffffffffc0201010:	953e                	add	a0,a0,a5
ffffffffc0201012:	6b8020ef          	jal	ra,ffffffffc02036ca <memset>
    return page - pages + nbase;
ffffffffc0201016:	000b3683          	ld	a3,0(s6)
ffffffffc020101a:	40d486b3          	sub	a3,s1,a3
ffffffffc020101e:	8699                	srai	a3,a3,0x6
ffffffffc0201020:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201022:	06aa                	slli	a3,a3,0xa
ffffffffc0201024:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201028:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020102a:	0009b703          	ld	a4,0(s3)
ffffffffc020102e:	068a                	slli	a3,a3,0x2
ffffffffc0201030:	757d                	lui	a0,0xfffff
ffffffffc0201032:	8ee9                	and	a3,a3,a0
ffffffffc0201034:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201038:	06e7f263          	bgeu	a5,a4,ffffffffc020109c <get_pte+0x1c4>
ffffffffc020103c:	000ab503          	ld	a0,0(s5)
ffffffffc0201040:	00c95913          	srli	s2,s2,0xc
ffffffffc0201044:	1ff97913          	andi	s2,s2,511
ffffffffc0201048:	96aa                	add	a3,a3,a0
ffffffffc020104a:	00391513          	slli	a0,s2,0x3
ffffffffc020104e:	9536                	add	a0,a0,a3
}
ffffffffc0201050:	70e2                	ld	ra,56(sp)
ffffffffc0201052:	7442                	ld	s0,48(sp)
ffffffffc0201054:	74a2                	ld	s1,40(sp)
ffffffffc0201056:	7902                	ld	s2,32(sp)
ffffffffc0201058:	69e2                	ld	s3,24(sp)
ffffffffc020105a:	6a42                	ld	s4,16(sp)
ffffffffc020105c:	6aa2                	ld	s5,8(sp)
ffffffffc020105e:	6b02                	ld	s6,0(sp)
ffffffffc0201060:	6121                	addi	sp,sp,64
ffffffffc0201062:	8082                	ret
            return NULL;
ffffffffc0201064:	4501                	li	a0,0
ffffffffc0201066:	b7ed                	j	ffffffffc0201050 <get_pte+0x178>
        intr_disable();
ffffffffc0201068:	8cfff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020106c:	0000c797          	auipc	a5,0xc
ffffffffc0201070:	4447b783          	ld	a5,1092(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0201074:	6f9c                	ld	a5,24(a5)
ffffffffc0201076:	4505                	li	a0,1
ffffffffc0201078:	9782                	jalr	a5
ffffffffc020107a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020107c:	8b5ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201080:	b56d                	j	ffffffffc0200f2a <get_pte+0x52>
        intr_disable();
ffffffffc0201082:	8b5ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc0201086:	0000c797          	auipc	a5,0xc
ffffffffc020108a:	42a7b783          	ld	a5,1066(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc020108e:	6f9c                	ld	a5,24(a5)
ffffffffc0201090:	4505                	li	a0,1
ffffffffc0201092:	9782                	jalr	a5
ffffffffc0201094:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201096:	89bff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc020109a:	b781                	j	ffffffffc0200fda <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020109c:	00003617          	auipc	a2,0x3
ffffffffc02010a0:	56c60613          	addi	a2,a2,1388 # ffffffffc0204608 <commands+0x860>
ffffffffc02010a4:	0fb00593          	li	a1,251
ffffffffc02010a8:	00003517          	auipc	a0,0x3
ffffffffc02010ac:	58850513          	addi	a0,a0,1416 # ffffffffc0204630 <commands+0x888>
ffffffffc02010b0:	92eff0ef          	jal	ra,ffffffffc02001de <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02010b4:	00003617          	auipc	a2,0x3
ffffffffc02010b8:	55460613          	addi	a2,a2,1364 # ffffffffc0204608 <commands+0x860>
ffffffffc02010bc:	0ee00593          	li	a1,238
ffffffffc02010c0:	00003517          	auipc	a0,0x3
ffffffffc02010c4:	57050513          	addi	a0,a0,1392 # ffffffffc0204630 <commands+0x888>
ffffffffc02010c8:	916ff0ef          	jal	ra,ffffffffc02001de <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02010cc:	86aa                	mv	a3,a0
ffffffffc02010ce:	00003617          	auipc	a2,0x3
ffffffffc02010d2:	53a60613          	addi	a2,a2,1338 # ffffffffc0204608 <commands+0x860>
ffffffffc02010d6:	0eb00593          	li	a1,235
ffffffffc02010da:	00003517          	auipc	a0,0x3
ffffffffc02010de:	55650513          	addi	a0,a0,1366 # ffffffffc0204630 <commands+0x888>
ffffffffc02010e2:	8fcff0ef          	jal	ra,ffffffffc02001de <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02010e6:	86aa                	mv	a3,a0
ffffffffc02010e8:	00003617          	auipc	a2,0x3
ffffffffc02010ec:	52060613          	addi	a2,a2,1312 # ffffffffc0204608 <commands+0x860>
ffffffffc02010f0:	0f800593          	li	a1,248
ffffffffc02010f4:	00003517          	auipc	a0,0x3
ffffffffc02010f8:	53c50513          	addi	a0,a0,1340 # ffffffffc0204630 <commands+0x888>
ffffffffc02010fc:	8e2ff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0201100 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201100:	1141                	addi	sp,sp,-16
ffffffffc0201102:	e022                	sd	s0,0(sp)
ffffffffc0201104:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201106:	4601                	li	a2,0
{
ffffffffc0201108:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020110a:	dcfff0ef          	jal	ra,ffffffffc0200ed8 <get_pte>
    if (ptep_store != NULL)
ffffffffc020110e:	c011                	beqz	s0,ffffffffc0201112 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201110:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201112:	c511                	beqz	a0,ffffffffc020111e <get_page+0x1e>
ffffffffc0201114:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201116:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201118:	0017f713          	andi	a4,a5,1
ffffffffc020111c:	e709                	bnez	a4,ffffffffc0201126 <get_page+0x26>
}
ffffffffc020111e:	60a2                	ld	ra,8(sp)
ffffffffc0201120:	6402                	ld	s0,0(sp)
ffffffffc0201122:	0141                	addi	sp,sp,16
ffffffffc0201124:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201126:	078a                	slli	a5,a5,0x2
ffffffffc0201128:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020112a:	0000c717          	auipc	a4,0xc
ffffffffc020112e:	37673703          	ld	a4,886(a4) # ffffffffc020d4a0 <npage>
ffffffffc0201132:	00e7ff63          	bgeu	a5,a4,ffffffffc0201150 <get_page+0x50>
ffffffffc0201136:	60a2                	ld	ra,8(sp)
ffffffffc0201138:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc020113a:	fff80537          	lui	a0,0xfff80
ffffffffc020113e:	97aa                	add	a5,a5,a0
ffffffffc0201140:	079a                	slli	a5,a5,0x6
ffffffffc0201142:	0000c517          	auipc	a0,0xc
ffffffffc0201146:	36653503          	ld	a0,870(a0) # ffffffffc020d4a8 <pages>
ffffffffc020114a:	953e                	add	a0,a0,a5
ffffffffc020114c:	0141                	addi	sp,sp,16
ffffffffc020114e:	8082                	ret
ffffffffc0201150:	c9bff0ef          	jal	ra,ffffffffc0200dea <pa2page.part.0>

ffffffffc0201154 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201154:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201156:	4601                	li	a2,0
{
ffffffffc0201158:	ec26                	sd	s1,24(sp)
ffffffffc020115a:	f406                	sd	ra,40(sp)
ffffffffc020115c:	f022                	sd	s0,32(sp)
ffffffffc020115e:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201160:	d79ff0ef          	jal	ra,ffffffffc0200ed8 <get_pte>
    if (ptep != NULL)
ffffffffc0201164:	c511                	beqz	a0,ffffffffc0201170 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0201166:	611c                	ld	a5,0(a0)
ffffffffc0201168:	842a                	mv	s0,a0
ffffffffc020116a:	0017f713          	andi	a4,a5,1
ffffffffc020116e:	e711                	bnez	a4,ffffffffc020117a <page_remove+0x26>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201170:	70a2                	ld	ra,40(sp)
ffffffffc0201172:	7402                	ld	s0,32(sp)
ffffffffc0201174:	64e2                	ld	s1,24(sp)
ffffffffc0201176:	6145                	addi	sp,sp,48
ffffffffc0201178:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020117a:	078a                	slli	a5,a5,0x2
ffffffffc020117c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020117e:	0000c717          	auipc	a4,0xc
ffffffffc0201182:	32273703          	ld	a4,802(a4) # ffffffffc020d4a0 <npage>
ffffffffc0201186:	06e7f363          	bgeu	a5,a4,ffffffffc02011ec <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020118a:	fff80537          	lui	a0,0xfff80
ffffffffc020118e:	97aa                	add	a5,a5,a0
ffffffffc0201190:	079a                	slli	a5,a5,0x6
ffffffffc0201192:	0000c517          	auipc	a0,0xc
ffffffffc0201196:	31653503          	ld	a0,790(a0) # ffffffffc020d4a8 <pages>
ffffffffc020119a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020119c:	411c                	lw	a5,0(a0)
ffffffffc020119e:	fff7871b          	addiw	a4,a5,-1
ffffffffc02011a2:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02011a4:	cb11                	beqz	a4,ffffffffc02011b8 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc02011a6:	00043023          	sd	zero,0(s0)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02011aa:	12048073          	sfence.vma	s1
}
ffffffffc02011ae:	70a2                	ld	ra,40(sp)
ffffffffc02011b0:	7402                	ld	s0,32(sp)
ffffffffc02011b2:	64e2                	ld	s1,24(sp)
ffffffffc02011b4:	6145                	addi	sp,sp,48
ffffffffc02011b6:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02011b8:	100027f3          	csrr	a5,sstatus
ffffffffc02011bc:	8b89                	andi	a5,a5,2
ffffffffc02011be:	eb89                	bnez	a5,ffffffffc02011d0 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02011c0:	0000c797          	auipc	a5,0xc
ffffffffc02011c4:	2f07b783          	ld	a5,752(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc02011c8:	739c                	ld	a5,32(a5)
ffffffffc02011ca:	4585                	li	a1,1
ffffffffc02011cc:	9782                	jalr	a5
    if (flag) {
ffffffffc02011ce:	bfe1                	j	ffffffffc02011a6 <page_remove+0x52>
        intr_disable();
ffffffffc02011d0:	e42a                	sd	a0,8(sp)
ffffffffc02011d2:	f64ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc02011d6:	0000c797          	auipc	a5,0xc
ffffffffc02011da:	2da7b783          	ld	a5,730(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc02011de:	739c                	ld	a5,32(a5)
ffffffffc02011e0:	6522                	ld	a0,8(sp)
ffffffffc02011e2:	4585                	li	a1,1
ffffffffc02011e4:	9782                	jalr	a5
        intr_enable();
ffffffffc02011e6:	f4aff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02011ea:	bf75                	j	ffffffffc02011a6 <page_remove+0x52>
ffffffffc02011ec:	bffff0ef          	jal	ra,ffffffffc0200dea <pa2page.part.0>

ffffffffc02011f0 <page_insert>:
{
ffffffffc02011f0:	7139                	addi	sp,sp,-64
ffffffffc02011f2:	e852                	sd	s4,16(sp)
ffffffffc02011f4:	8a32                	mv	s4,a2
ffffffffc02011f6:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02011f8:	4605                	li	a2,1
{
ffffffffc02011fa:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02011fc:	85d2                	mv	a1,s4
{
ffffffffc02011fe:	f426                	sd	s1,40(sp)
ffffffffc0201200:	fc06                	sd	ra,56(sp)
ffffffffc0201202:	f04a                	sd	s2,32(sp)
ffffffffc0201204:	ec4e                	sd	s3,24(sp)
ffffffffc0201206:	e456                	sd	s5,8(sp)
ffffffffc0201208:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020120a:	ccfff0ef          	jal	ra,ffffffffc0200ed8 <get_pte>
    if (ptep == NULL)
ffffffffc020120e:	c961                	beqz	a0,ffffffffc02012de <page_insert+0xee>
    page->ref += 1;
ffffffffc0201210:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0201212:	611c                	ld	a5,0(a0)
ffffffffc0201214:	89aa                	mv	s3,a0
ffffffffc0201216:	0016871b          	addiw	a4,a3,1
ffffffffc020121a:	c018                	sw	a4,0(s0)
ffffffffc020121c:	0017f713          	andi	a4,a5,1
ffffffffc0201220:	ef05                	bnez	a4,ffffffffc0201258 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0201222:	0000c717          	auipc	a4,0xc
ffffffffc0201226:	28673703          	ld	a4,646(a4) # ffffffffc020d4a8 <pages>
ffffffffc020122a:	8c19                	sub	s0,s0,a4
ffffffffc020122c:	000807b7          	lui	a5,0x80
ffffffffc0201230:	8419                	srai	s0,s0,0x6
ffffffffc0201232:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201234:	042a                	slli	s0,s0,0xa
ffffffffc0201236:	8cc1                	or	s1,s1,s0
ffffffffc0201238:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020123c:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201240:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0201244:	4501                	li	a0,0
}
ffffffffc0201246:	70e2                	ld	ra,56(sp)
ffffffffc0201248:	7442                	ld	s0,48(sp)
ffffffffc020124a:	74a2                	ld	s1,40(sp)
ffffffffc020124c:	7902                	ld	s2,32(sp)
ffffffffc020124e:	69e2                	ld	s3,24(sp)
ffffffffc0201250:	6a42                	ld	s4,16(sp)
ffffffffc0201252:	6aa2                	ld	s5,8(sp)
ffffffffc0201254:	6121                	addi	sp,sp,64
ffffffffc0201256:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201258:	078a                	slli	a5,a5,0x2
ffffffffc020125a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020125c:	0000c717          	auipc	a4,0xc
ffffffffc0201260:	24473703          	ld	a4,580(a4) # ffffffffc020d4a0 <npage>
ffffffffc0201264:	06e7ff63          	bgeu	a5,a4,ffffffffc02012e2 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0201268:	0000ca97          	auipc	s5,0xc
ffffffffc020126c:	240a8a93          	addi	s5,s5,576 # ffffffffc020d4a8 <pages>
ffffffffc0201270:	000ab703          	ld	a4,0(s5)
ffffffffc0201274:	fff80937          	lui	s2,0xfff80
ffffffffc0201278:	993e                	add	s2,s2,a5
ffffffffc020127a:	091a                	slli	s2,s2,0x6
ffffffffc020127c:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc020127e:	01240c63          	beq	s0,s2,ffffffffc0201296 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0201282:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd72b1c>
ffffffffc0201286:	fff7869b          	addiw	a3,a5,-1
ffffffffc020128a:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc020128e:	c691                	beqz	a3,ffffffffc020129a <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201290:	120a0073          	sfence.vma	s4
}
ffffffffc0201294:	bf59                	j	ffffffffc020122a <page_insert+0x3a>
ffffffffc0201296:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201298:	bf49                	j	ffffffffc020122a <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020129a:	100027f3          	csrr	a5,sstatus
ffffffffc020129e:	8b89                	andi	a5,a5,2
ffffffffc02012a0:	ef91                	bnez	a5,ffffffffc02012bc <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02012a2:	0000c797          	auipc	a5,0xc
ffffffffc02012a6:	20e7b783          	ld	a5,526(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc02012aa:	739c                	ld	a5,32(a5)
ffffffffc02012ac:	4585                	li	a1,1
ffffffffc02012ae:	854a                	mv	a0,s2
ffffffffc02012b0:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02012b2:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02012b6:	120a0073          	sfence.vma	s4
ffffffffc02012ba:	bf85                	j	ffffffffc020122a <page_insert+0x3a>
        intr_disable();
ffffffffc02012bc:	e7aff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02012c0:	0000c797          	auipc	a5,0xc
ffffffffc02012c4:	1f07b783          	ld	a5,496(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc02012c8:	739c                	ld	a5,32(a5)
ffffffffc02012ca:	4585                	li	a1,1
ffffffffc02012cc:	854a                	mv	a0,s2
ffffffffc02012ce:	9782                	jalr	a5
        intr_enable();
ffffffffc02012d0:	e60ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02012d4:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02012d8:	120a0073          	sfence.vma	s4
ffffffffc02012dc:	b7b9                	j	ffffffffc020122a <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02012de:	5571                	li	a0,-4
ffffffffc02012e0:	b79d                	j	ffffffffc0201246 <page_insert+0x56>
ffffffffc02012e2:	b09ff0ef          	jal	ra,ffffffffc0200dea <pa2page.part.0>

ffffffffc02012e6 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02012e6:	00004797          	auipc	a5,0x4
ffffffffc02012ea:	f7278793          	addi	a5,a5,-142 # ffffffffc0205258 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012ee:	638c                	ld	a1,0(a5)
{
ffffffffc02012f0:	7159                	addi	sp,sp,-112
ffffffffc02012f2:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012f4:	00003517          	auipc	a0,0x3
ffffffffc02012f8:	34c50513          	addi	a0,a0,844 # ffffffffc0204640 <commands+0x898>
    pmm_manager = &default_pmm_manager;
ffffffffc02012fc:	0000cb17          	auipc	s6,0xc
ffffffffc0201300:	1b4b0b13          	addi	s6,s6,436 # ffffffffc020d4b0 <pmm_manager>
{
ffffffffc0201304:	f486                	sd	ra,104(sp)
ffffffffc0201306:	e8ca                	sd	s2,80(sp)
ffffffffc0201308:	e4ce                	sd	s3,72(sp)
ffffffffc020130a:	f0a2                	sd	s0,96(sp)
ffffffffc020130c:	eca6                	sd	s1,88(sp)
ffffffffc020130e:	e0d2                	sd	s4,64(sp)
ffffffffc0201310:	fc56                	sd	s5,56(sp)
ffffffffc0201312:	f45e                	sd	s7,40(sp)
ffffffffc0201314:	f062                	sd	s8,32(sp)
ffffffffc0201316:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201318:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020131c:	dc5fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    pmm_manager->init();
ffffffffc0201320:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201324:	0000c997          	auipc	s3,0xc
ffffffffc0201328:	19498993          	addi	s3,s3,404 # ffffffffc020d4b8 <va_pa_offset>
    pmm_manager->init();
ffffffffc020132c:	679c                	ld	a5,8(a5)
ffffffffc020132e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201330:	57f5                	li	a5,-3
ffffffffc0201332:	07fa                	slli	a5,a5,0x1e
ffffffffc0201334:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201338:	d1cff0ef          	jal	ra,ffffffffc0200854 <get_memory_base>
ffffffffc020133c:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020133e:	d20ff0ef          	jal	ra,ffffffffc020085e <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201342:	200505e3          	beqz	a0,ffffffffc0201d4c <pmm_init+0xa66>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201346:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0201348:	00003517          	auipc	a0,0x3
ffffffffc020134c:	33050513          	addi	a0,a0,816 # ffffffffc0204678 <commands+0x8d0>
ffffffffc0201350:	d91fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201354:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201358:	fff40693          	addi	a3,s0,-1
ffffffffc020135c:	864a                	mv	a2,s2
ffffffffc020135e:	85a6                	mv	a1,s1
ffffffffc0201360:	00003517          	auipc	a0,0x3
ffffffffc0201364:	33050513          	addi	a0,a0,816 # ffffffffc0204690 <commands+0x8e8>
ffffffffc0201368:	d79fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020136c:	c8000737          	lui	a4,0xc8000
ffffffffc0201370:	87a2                	mv	a5,s0
ffffffffc0201372:	54876163          	bltu	a4,s0,ffffffffc02018b4 <pmm_init+0x5ce>
ffffffffc0201376:	757d                	lui	a0,0xfffff
ffffffffc0201378:	0000d617          	auipc	a2,0xd
ffffffffc020137c:	16b60613          	addi	a2,a2,363 # ffffffffc020e4e3 <end+0xfff>
ffffffffc0201380:	8e69                	and	a2,a2,a0
ffffffffc0201382:	0000c497          	auipc	s1,0xc
ffffffffc0201386:	11e48493          	addi	s1,s1,286 # ffffffffc020d4a0 <npage>
ffffffffc020138a:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020138e:	0000cb97          	auipc	s7,0xc
ffffffffc0201392:	11ab8b93          	addi	s7,s7,282 # ffffffffc020d4a8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201396:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201398:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020139c:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02013a0:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02013a2:	02f50863          	beq	a0,a5,ffffffffc02013d2 <pmm_init+0xec>
ffffffffc02013a6:	4781                	li	a5,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02013a8:	4585                	li	a1,1
ffffffffc02013aa:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02013ae:	00679513          	slli	a0,a5,0x6
ffffffffc02013b2:	9532                	add	a0,a0,a2
ffffffffc02013b4:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fdf1b24>
ffffffffc02013b8:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02013bc:	6088                	ld	a0,0(s1)
ffffffffc02013be:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02013c0:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02013c4:	00d50733          	add	a4,a0,a3
ffffffffc02013c8:	fee7e3e3          	bltu	a5,a4,ffffffffc02013ae <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02013cc:	071a                	slli	a4,a4,0x6
ffffffffc02013ce:	00e606b3          	add	a3,a2,a4
ffffffffc02013d2:	c02007b7          	lui	a5,0xc0200
ffffffffc02013d6:	2ef6ece3          	bltu	a3,a5,ffffffffc0201ece <pmm_init+0xbe8>
ffffffffc02013da:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02013de:	77fd                	lui	a5,0xfffff
ffffffffc02013e0:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02013e2:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02013e4:	5086eb63          	bltu	a3,s0,ffffffffc02018fa <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02013e8:	00003517          	auipc	a0,0x3
ffffffffc02013ec:	2f850513          	addi	a0,a0,760 # ffffffffc02046e0 <commands+0x938>
ffffffffc02013f0:	cf1fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02013f4:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02013f8:	0000c917          	auipc	s2,0xc
ffffffffc02013fc:	0a090913          	addi	s2,s2,160 # ffffffffc020d498 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0201400:	7b9c                	ld	a5,48(a5)
ffffffffc0201402:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201404:	00003517          	auipc	a0,0x3
ffffffffc0201408:	2f450513          	addi	a0,a0,756 # ffffffffc02046f8 <commands+0x950>
ffffffffc020140c:	cd5fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0201410:	00007697          	auipc	a3,0x7
ffffffffc0201414:	bf068693          	addi	a3,a3,-1040 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0201418:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020141c:	c02007b7          	lui	a5,0xc0200
ffffffffc0201420:	28f6ebe3          	bltu	a3,a5,ffffffffc0201eb6 <pmm_init+0xbd0>
ffffffffc0201424:	0009b783          	ld	a5,0(s3)
ffffffffc0201428:	8e9d                	sub	a3,a3,a5
ffffffffc020142a:	0000c797          	auipc	a5,0xc
ffffffffc020142e:	06d7b323          	sd	a3,102(a5) # ffffffffc020d490 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201432:	100027f3          	csrr	a5,sstatus
ffffffffc0201436:	8b89                	andi	a5,a5,2
ffffffffc0201438:	4a079763          	bnez	a5,ffffffffc02018e6 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc020143c:	000b3783          	ld	a5,0(s6)
ffffffffc0201440:	779c                	ld	a5,40(a5)
ffffffffc0201442:	9782                	jalr	a5
ffffffffc0201444:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201446:	6098                	ld	a4,0(s1)
ffffffffc0201448:	c80007b7          	lui	a5,0xc8000
ffffffffc020144c:	83b1                	srli	a5,a5,0xc
ffffffffc020144e:	66e7e363          	bltu	a5,a4,ffffffffc0201ab4 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0201452:	00093503          	ld	a0,0(s2)
ffffffffc0201456:	62050f63          	beqz	a0,ffffffffc0201a94 <pmm_init+0x7ae>
ffffffffc020145a:	03451793          	slli	a5,a0,0x34
ffffffffc020145e:	62079b63          	bnez	a5,ffffffffc0201a94 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0201462:	4601                	li	a2,0
ffffffffc0201464:	4581                	li	a1,0
ffffffffc0201466:	c9bff0ef          	jal	ra,ffffffffc0201100 <get_page>
ffffffffc020146a:	60051563          	bnez	a0,ffffffffc0201a74 <pmm_init+0x78e>
ffffffffc020146e:	100027f3          	csrr	a5,sstatus
ffffffffc0201472:	8b89                	andi	a5,a5,2
ffffffffc0201474:	44079e63          	bnez	a5,ffffffffc02018d0 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201478:	000b3783          	ld	a5,0(s6)
ffffffffc020147c:	4505                	li	a0,1
ffffffffc020147e:	6f9c                	ld	a5,24(a5)
ffffffffc0201480:	9782                	jalr	a5
ffffffffc0201482:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0201484:	00093503          	ld	a0,0(s2)
ffffffffc0201488:	4681                	li	a3,0
ffffffffc020148a:	4601                	li	a2,0
ffffffffc020148c:	85d2                	mv	a1,s4
ffffffffc020148e:	d63ff0ef          	jal	ra,ffffffffc02011f0 <page_insert>
ffffffffc0201492:	26051ae3          	bnez	a0,ffffffffc0201f06 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0201496:	00093503          	ld	a0,0(s2)
ffffffffc020149a:	4601                	li	a2,0
ffffffffc020149c:	4581                	li	a1,0
ffffffffc020149e:	a3bff0ef          	jal	ra,ffffffffc0200ed8 <get_pte>
ffffffffc02014a2:	240502e3          	beqz	a0,ffffffffc0201ee6 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc02014a6:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02014a8:	0017f713          	andi	a4,a5,1
ffffffffc02014ac:	5a070263          	beqz	a4,ffffffffc0201a50 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02014b0:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02014b2:	078a                	slli	a5,a5,0x2
ffffffffc02014b4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02014b6:	58e7fb63          	bgeu	a5,a4,ffffffffc0201a4c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02014ba:	000bb683          	ld	a3,0(s7)
ffffffffc02014be:	fff80637          	lui	a2,0xfff80
ffffffffc02014c2:	97b2                	add	a5,a5,a2
ffffffffc02014c4:	079a                	slli	a5,a5,0x6
ffffffffc02014c6:	97b6                	add	a5,a5,a3
ffffffffc02014c8:	14fa17e3          	bne	s4,a5,ffffffffc0201e16 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc02014cc:	000a2683          	lw	a3,0(s4) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc02014d0:	4785                	li	a5,1
ffffffffc02014d2:	12f692e3          	bne	a3,a5,ffffffffc0201df6 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02014d6:	00093503          	ld	a0,0(s2)
ffffffffc02014da:	77fd                	lui	a5,0xfffff
ffffffffc02014dc:	6114                	ld	a3,0(a0)
ffffffffc02014de:	068a                	slli	a3,a3,0x2
ffffffffc02014e0:	8efd                	and	a3,a3,a5
ffffffffc02014e2:	00c6d613          	srli	a2,a3,0xc
ffffffffc02014e6:	0ee67ce3          	bgeu	a2,a4,ffffffffc0201dde <pmm_init+0xaf8>
ffffffffc02014ea:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02014ee:	96e2                	add	a3,a3,s8
ffffffffc02014f0:	0006ba83          	ld	s5,0(a3)
ffffffffc02014f4:	0a8a                	slli	s5,s5,0x2
ffffffffc02014f6:	00fafab3          	and	s5,s5,a5
ffffffffc02014fa:	00cad793          	srli	a5,s5,0xc
ffffffffc02014fe:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0201dc4 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0201502:	4601                	li	a2,0
ffffffffc0201504:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201506:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0201508:	9d1ff0ef          	jal	ra,ffffffffc0200ed8 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020150c:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020150e:	55551363          	bne	a0,s5,ffffffffc0201a54 <pmm_init+0x76e>
ffffffffc0201512:	100027f3          	csrr	a5,sstatus
ffffffffc0201516:	8b89                	andi	a5,a5,2
ffffffffc0201518:	3a079163          	bnez	a5,ffffffffc02018ba <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc020151c:	000b3783          	ld	a5,0(s6)
ffffffffc0201520:	4505                	li	a0,1
ffffffffc0201522:	6f9c                	ld	a5,24(a5)
ffffffffc0201524:	9782                	jalr	a5
ffffffffc0201526:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201528:	00093503          	ld	a0,0(s2)
ffffffffc020152c:	46d1                	li	a3,20
ffffffffc020152e:	6605                	lui	a2,0x1
ffffffffc0201530:	85e2                	mv	a1,s8
ffffffffc0201532:	cbfff0ef          	jal	ra,ffffffffc02011f0 <page_insert>
ffffffffc0201536:	060517e3          	bnez	a0,ffffffffc0201da4 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020153a:	00093503          	ld	a0,0(s2)
ffffffffc020153e:	4601                	li	a2,0
ffffffffc0201540:	6585                	lui	a1,0x1
ffffffffc0201542:	997ff0ef          	jal	ra,ffffffffc0200ed8 <get_pte>
ffffffffc0201546:	02050fe3          	beqz	a0,ffffffffc0201d84 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc020154a:	611c                	ld	a5,0(a0)
ffffffffc020154c:	0107f713          	andi	a4,a5,16
ffffffffc0201550:	7c070e63          	beqz	a4,ffffffffc0201d2c <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0201554:	8b91                	andi	a5,a5,4
ffffffffc0201556:	7a078b63          	beqz	a5,ffffffffc0201d0c <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020155a:	00093503          	ld	a0,0(s2)
ffffffffc020155e:	611c                	ld	a5,0(a0)
ffffffffc0201560:	8bc1                	andi	a5,a5,16
ffffffffc0201562:	78078563          	beqz	a5,ffffffffc0201cec <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0201566:	000c2703          	lw	a4,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc020156a:	4785                	li	a5,1
ffffffffc020156c:	76f71063          	bne	a4,a5,ffffffffc0201ccc <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0201570:	4681                	li	a3,0
ffffffffc0201572:	6605                	lui	a2,0x1
ffffffffc0201574:	85d2                	mv	a1,s4
ffffffffc0201576:	c7bff0ef          	jal	ra,ffffffffc02011f0 <page_insert>
ffffffffc020157a:	72051963          	bnez	a0,ffffffffc0201cac <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc020157e:	000a2703          	lw	a4,0(s4)
ffffffffc0201582:	4789                	li	a5,2
ffffffffc0201584:	70f71463          	bne	a4,a5,ffffffffc0201c8c <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0201588:	000c2783          	lw	a5,0(s8)
ffffffffc020158c:	6e079063          	bnez	a5,ffffffffc0201c6c <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201590:	00093503          	ld	a0,0(s2)
ffffffffc0201594:	4601                	li	a2,0
ffffffffc0201596:	6585                	lui	a1,0x1
ffffffffc0201598:	941ff0ef          	jal	ra,ffffffffc0200ed8 <get_pte>
ffffffffc020159c:	6a050863          	beqz	a0,ffffffffc0201c4c <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc02015a0:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc02015a2:	00177793          	andi	a5,a4,1
ffffffffc02015a6:	4a078563          	beqz	a5,ffffffffc0201a50 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02015aa:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02015ac:	00271793          	slli	a5,a4,0x2
ffffffffc02015b0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02015b2:	48d7fd63          	bgeu	a5,a3,ffffffffc0201a4c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02015b6:	000bb683          	ld	a3,0(s7)
ffffffffc02015ba:	fff80ab7          	lui	s5,0xfff80
ffffffffc02015be:	97d6                	add	a5,a5,s5
ffffffffc02015c0:	079a                	slli	a5,a5,0x6
ffffffffc02015c2:	97b6                	add	a5,a5,a3
ffffffffc02015c4:	66fa1463          	bne	s4,a5,ffffffffc0201c2c <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc02015c8:	8b41                	andi	a4,a4,16
ffffffffc02015ca:	64071163          	bnez	a4,ffffffffc0201c0c <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc02015ce:	00093503          	ld	a0,0(s2)
ffffffffc02015d2:	4581                	li	a1,0
ffffffffc02015d4:	b81ff0ef          	jal	ra,ffffffffc0201154 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc02015d8:	000a2c83          	lw	s9,0(s4)
ffffffffc02015dc:	4785                	li	a5,1
ffffffffc02015de:	60fc9763          	bne	s9,a5,ffffffffc0201bec <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc02015e2:	000c2783          	lw	a5,0(s8)
ffffffffc02015e6:	5e079363          	bnez	a5,ffffffffc0201bcc <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc02015ea:	00093503          	ld	a0,0(s2)
ffffffffc02015ee:	6585                	lui	a1,0x1
ffffffffc02015f0:	b65ff0ef          	jal	ra,ffffffffc0201154 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc02015f4:	000a2783          	lw	a5,0(s4)
ffffffffc02015f8:	52079a63          	bnez	a5,ffffffffc0201b2c <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc02015fc:	000c2783          	lw	a5,0(s8)
ffffffffc0201600:	50079663          	bnez	a5,ffffffffc0201b0c <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0201604:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0201608:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020160a:	000a3683          	ld	a3,0(s4)
ffffffffc020160e:	068a                	slli	a3,a3,0x2
ffffffffc0201610:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0201612:	42b6fd63          	bgeu	a3,a1,ffffffffc0201a4c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201616:	000bb503          	ld	a0,0(s7)
ffffffffc020161a:	96d6                	add	a3,a3,s5
ffffffffc020161c:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020161e:	00d507b3          	add	a5,a0,a3
ffffffffc0201622:	439c                	lw	a5,0(a5)
ffffffffc0201624:	4d979463          	bne	a5,s9,ffffffffc0201aec <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0201628:	8699                	srai	a3,a3,0x6
ffffffffc020162a:	00080637          	lui	a2,0x80
ffffffffc020162e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0201630:	00c69713          	slli	a4,a3,0xc
ffffffffc0201634:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201636:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201638:	48b77e63          	bgeu	a4,a1,ffffffffc0201ad4 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc020163c:	0009b703          	ld	a4,0(s3)
ffffffffc0201640:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0201642:	629c                	ld	a5,0(a3)
ffffffffc0201644:	078a                	slli	a5,a5,0x2
ffffffffc0201646:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201648:	40b7f263          	bgeu	a5,a1,ffffffffc0201a4c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020164c:	8f91                	sub	a5,a5,a2
ffffffffc020164e:	079a                	slli	a5,a5,0x6
ffffffffc0201650:	953e                	add	a0,a0,a5
ffffffffc0201652:	100027f3          	csrr	a5,sstatus
ffffffffc0201656:	8b89                	andi	a5,a5,2
ffffffffc0201658:	30079963          	bnez	a5,ffffffffc020196a <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc020165c:	000b3783          	ld	a5,0(s6)
ffffffffc0201660:	4585                	li	a1,1
ffffffffc0201662:	739c                	ld	a5,32(a5)
ffffffffc0201664:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201666:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc020166a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020166c:	078a                	slli	a5,a5,0x2
ffffffffc020166e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201670:	3ce7fe63          	bgeu	a5,a4,ffffffffc0201a4c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201674:	000bb503          	ld	a0,0(s7)
ffffffffc0201678:	fff80737          	lui	a4,0xfff80
ffffffffc020167c:	97ba                	add	a5,a5,a4
ffffffffc020167e:	079a                	slli	a5,a5,0x6
ffffffffc0201680:	953e                	add	a0,a0,a5
ffffffffc0201682:	100027f3          	csrr	a5,sstatus
ffffffffc0201686:	8b89                	andi	a5,a5,2
ffffffffc0201688:	2c079563          	bnez	a5,ffffffffc0201952 <pmm_init+0x66c>
ffffffffc020168c:	000b3783          	ld	a5,0(s6)
ffffffffc0201690:	4585                	li	a1,1
ffffffffc0201692:	739c                	ld	a5,32(a5)
ffffffffc0201694:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0201696:	00093783          	ld	a5,0(s2)
ffffffffc020169a:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b1c>
    asm volatile("sfence.vma");
ffffffffc020169e:	12000073          	sfence.vma
ffffffffc02016a2:	100027f3          	csrr	a5,sstatus
ffffffffc02016a6:	8b89                	andi	a5,a5,2
ffffffffc02016a8:	28079b63          	bnez	a5,ffffffffc020193e <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc02016ac:	000b3783          	ld	a5,0(s6)
ffffffffc02016b0:	779c                	ld	a5,40(a5)
ffffffffc02016b2:	9782                	jalr	a5
ffffffffc02016b4:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02016b6:	4b441b63          	bne	s0,s4,ffffffffc0201b6c <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02016ba:	00003517          	auipc	a0,0x3
ffffffffc02016be:	37e50513          	addi	a0,a0,894 # ffffffffc0204a38 <commands+0xc90>
ffffffffc02016c2:	a1ffe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc02016c6:	100027f3          	csrr	a5,sstatus
ffffffffc02016ca:	8b89                	andi	a5,a5,2
ffffffffc02016cc:	24079f63          	bnez	a5,ffffffffc020192a <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc02016d0:	000b3783          	ld	a5,0(s6)
ffffffffc02016d4:	779c                	ld	a5,40(a5)
ffffffffc02016d6:	9782                	jalr	a5
ffffffffc02016d8:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02016da:	6098                	ld	a4,0(s1)
ffffffffc02016dc:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02016e0:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02016e2:	00c71793          	slli	a5,a4,0xc
ffffffffc02016e6:	6a05                	lui	s4,0x1
ffffffffc02016e8:	02f47c63          	bgeu	s0,a5,ffffffffc0201720 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02016ec:	00c45793          	srli	a5,s0,0xc
ffffffffc02016f0:	00093503          	ld	a0,0(s2)
ffffffffc02016f4:	2ee7ff63          	bgeu	a5,a4,ffffffffc02019f2 <pmm_init+0x70c>
ffffffffc02016f8:	0009b583          	ld	a1,0(s3)
ffffffffc02016fc:	4601                	li	a2,0
ffffffffc02016fe:	95a2                	add	a1,a1,s0
ffffffffc0201700:	fd8ff0ef          	jal	ra,ffffffffc0200ed8 <get_pte>
ffffffffc0201704:	32050463          	beqz	a0,ffffffffc0201a2c <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201708:	611c                	ld	a5,0(a0)
ffffffffc020170a:	078a                	slli	a5,a5,0x2
ffffffffc020170c:	0157f7b3          	and	a5,a5,s5
ffffffffc0201710:	2e879e63          	bne	a5,s0,ffffffffc0201a0c <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201714:	6098                	ld	a4,0(s1)
ffffffffc0201716:	9452                	add	s0,s0,s4
ffffffffc0201718:	00c71793          	slli	a5,a4,0xc
ffffffffc020171c:	fcf468e3          	bltu	s0,a5,ffffffffc02016ec <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0201720:	00093783          	ld	a5,0(s2)
ffffffffc0201724:	639c                	ld	a5,0(a5)
ffffffffc0201726:	42079363          	bnez	a5,ffffffffc0201b4c <pmm_init+0x866>
ffffffffc020172a:	100027f3          	csrr	a5,sstatus
ffffffffc020172e:	8b89                	andi	a5,a5,2
ffffffffc0201730:	24079963          	bnez	a5,ffffffffc0201982 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201734:	000b3783          	ld	a5,0(s6)
ffffffffc0201738:	4505                	li	a0,1
ffffffffc020173a:	6f9c                	ld	a5,24(a5)
ffffffffc020173c:	9782                	jalr	a5
ffffffffc020173e:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201740:	00093503          	ld	a0,0(s2)
ffffffffc0201744:	4699                	li	a3,6
ffffffffc0201746:	10000613          	li	a2,256
ffffffffc020174a:	85d2                	mv	a1,s4
ffffffffc020174c:	aa5ff0ef          	jal	ra,ffffffffc02011f0 <page_insert>
ffffffffc0201750:	44051e63          	bnez	a0,ffffffffc0201bac <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0201754:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0201758:	4785                	li	a5,1
ffffffffc020175a:	42f71963          	bne	a4,a5,ffffffffc0201b8c <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020175e:	00093503          	ld	a0,0(s2)
ffffffffc0201762:	6405                	lui	s0,0x1
ffffffffc0201764:	4699                	li	a3,6
ffffffffc0201766:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc020176a:	85d2                	mv	a1,s4
ffffffffc020176c:	a85ff0ef          	jal	ra,ffffffffc02011f0 <page_insert>
ffffffffc0201770:	72051363          	bnez	a0,ffffffffc0201e96 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0201774:	000a2703          	lw	a4,0(s4)
ffffffffc0201778:	4789                	li	a5,2
ffffffffc020177a:	6ef71e63          	bne	a4,a5,ffffffffc0201e76 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc020177e:	00003597          	auipc	a1,0x3
ffffffffc0201782:	40258593          	addi	a1,a1,1026 # ffffffffc0204b80 <commands+0xdd8>
ffffffffc0201786:	10000513          	li	a0,256
ffffffffc020178a:	6d5010ef          	jal	ra,ffffffffc020365e <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020178e:	10040593          	addi	a1,s0,256
ffffffffc0201792:	10000513          	li	a0,256
ffffffffc0201796:	6db010ef          	jal	ra,ffffffffc0203670 <strcmp>
ffffffffc020179a:	6a051e63          	bnez	a0,ffffffffc0201e56 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc020179e:	000bb683          	ld	a3,0(s7)
ffffffffc02017a2:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc02017a6:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc02017a8:	40da06b3          	sub	a3,s4,a3
ffffffffc02017ac:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02017ae:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc02017b0:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02017b2:	8031                	srli	s0,s0,0xc
ffffffffc02017b4:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc02017b8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02017ba:	30f77d63          	bgeu	a4,a5,ffffffffc0201ad4 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02017be:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02017c2:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02017c6:	96be                	add	a3,a3,a5
ffffffffc02017c8:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02017cc:	65d010ef          	jal	ra,ffffffffc0203628 <strlen>
ffffffffc02017d0:	66051363          	bnez	a0,ffffffffc0201e36 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc02017d4:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc02017d8:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02017da:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fdf1b1c>
ffffffffc02017de:	068a                	slli	a3,a3,0x2
ffffffffc02017e0:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc02017e2:	26f6f563          	bgeu	a3,a5,ffffffffc0201a4c <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc02017e6:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02017e8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02017ea:	2ef47563          	bgeu	s0,a5,ffffffffc0201ad4 <pmm_init+0x7ee>
ffffffffc02017ee:	0009b403          	ld	s0,0(s3)
ffffffffc02017f2:	9436                	add	s0,s0,a3
ffffffffc02017f4:	100027f3          	csrr	a5,sstatus
ffffffffc02017f8:	8b89                	andi	a5,a5,2
ffffffffc02017fa:	1e079163          	bnez	a5,ffffffffc02019dc <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc02017fe:	000b3783          	ld	a5,0(s6)
ffffffffc0201802:	4585                	li	a1,1
ffffffffc0201804:	8552                	mv	a0,s4
ffffffffc0201806:	739c                	ld	a5,32(a5)
ffffffffc0201808:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020180a:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc020180c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020180e:	078a                	slli	a5,a5,0x2
ffffffffc0201810:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201812:	22e7fd63          	bgeu	a5,a4,ffffffffc0201a4c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201816:	000bb503          	ld	a0,0(s7)
ffffffffc020181a:	fff80737          	lui	a4,0xfff80
ffffffffc020181e:	97ba                	add	a5,a5,a4
ffffffffc0201820:	079a                	slli	a5,a5,0x6
ffffffffc0201822:	953e                	add	a0,a0,a5
ffffffffc0201824:	100027f3          	csrr	a5,sstatus
ffffffffc0201828:	8b89                	andi	a5,a5,2
ffffffffc020182a:	18079d63          	bnez	a5,ffffffffc02019c4 <pmm_init+0x6de>
ffffffffc020182e:	000b3783          	ld	a5,0(s6)
ffffffffc0201832:	4585                	li	a1,1
ffffffffc0201834:	739c                	ld	a5,32(a5)
ffffffffc0201836:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201838:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc020183c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020183e:	078a                	slli	a5,a5,0x2
ffffffffc0201840:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201842:	20e7f563          	bgeu	a5,a4,ffffffffc0201a4c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201846:	000bb503          	ld	a0,0(s7)
ffffffffc020184a:	fff80737          	lui	a4,0xfff80
ffffffffc020184e:	97ba                	add	a5,a5,a4
ffffffffc0201850:	079a                	slli	a5,a5,0x6
ffffffffc0201852:	953e                	add	a0,a0,a5
ffffffffc0201854:	100027f3          	csrr	a5,sstatus
ffffffffc0201858:	8b89                	andi	a5,a5,2
ffffffffc020185a:	14079963          	bnez	a5,ffffffffc02019ac <pmm_init+0x6c6>
ffffffffc020185e:	000b3783          	ld	a5,0(s6)
ffffffffc0201862:	4585                	li	a1,1
ffffffffc0201864:	739c                	ld	a5,32(a5)
ffffffffc0201866:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0201868:	00093783          	ld	a5,0(s2)
ffffffffc020186c:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0201870:	12000073          	sfence.vma
ffffffffc0201874:	100027f3          	csrr	a5,sstatus
ffffffffc0201878:	8b89                	andi	a5,a5,2
ffffffffc020187a:	10079f63          	bnez	a5,ffffffffc0201998 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc020187e:	000b3783          	ld	a5,0(s6)
ffffffffc0201882:	779c                	ld	a5,40(a5)
ffffffffc0201884:	9782                	jalr	a5
ffffffffc0201886:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0201888:	4c8c1e63          	bne	s8,s0,ffffffffc0201d64 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc020188c:	00003517          	auipc	a0,0x3
ffffffffc0201890:	36c50513          	addi	a0,a0,876 # ffffffffc0204bf8 <commands+0xe50>
ffffffffc0201894:	84dfe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}
ffffffffc0201898:	7406                	ld	s0,96(sp)
ffffffffc020189a:	70a6                	ld	ra,104(sp)
ffffffffc020189c:	64e6                	ld	s1,88(sp)
ffffffffc020189e:	6946                	ld	s2,80(sp)
ffffffffc02018a0:	69a6                	ld	s3,72(sp)
ffffffffc02018a2:	6a06                	ld	s4,64(sp)
ffffffffc02018a4:	7ae2                	ld	s5,56(sp)
ffffffffc02018a6:	7b42                	ld	s6,48(sp)
ffffffffc02018a8:	7ba2                	ld	s7,40(sp)
ffffffffc02018aa:	7c02                	ld	s8,32(sp)
ffffffffc02018ac:	6ce2                	ld	s9,24(sp)
ffffffffc02018ae:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc02018b0:	4ef0006f          	j	ffffffffc020259e <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc02018b4:	c80007b7          	lui	a5,0xc8000
ffffffffc02018b8:	bc7d                	j	ffffffffc0201376 <pmm_init+0x90>
        intr_disable();
ffffffffc02018ba:	87cff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02018be:	000b3783          	ld	a5,0(s6)
ffffffffc02018c2:	4505                	li	a0,1
ffffffffc02018c4:	6f9c                	ld	a5,24(a5)
ffffffffc02018c6:	9782                	jalr	a5
ffffffffc02018c8:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02018ca:	866ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02018ce:	b9a9                	j	ffffffffc0201528 <pmm_init+0x242>
        intr_disable();
ffffffffc02018d0:	866ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc02018d4:	000b3783          	ld	a5,0(s6)
ffffffffc02018d8:	4505                	li	a0,1
ffffffffc02018da:	6f9c                	ld	a5,24(a5)
ffffffffc02018dc:	9782                	jalr	a5
ffffffffc02018de:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02018e0:	850ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02018e4:	b645                	j	ffffffffc0201484 <pmm_init+0x19e>
        intr_disable();
ffffffffc02018e6:	850ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02018ea:	000b3783          	ld	a5,0(s6)
ffffffffc02018ee:	779c                	ld	a5,40(a5)
ffffffffc02018f0:	9782                	jalr	a5
ffffffffc02018f2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02018f4:	83cff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02018f8:	b6b9                	j	ffffffffc0201446 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02018fa:	6705                	lui	a4,0x1
ffffffffc02018fc:	177d                	addi	a4,a4,-1
ffffffffc02018fe:	96ba                	add	a3,a3,a4
ffffffffc0201900:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0201902:	00c7d713          	srli	a4,a5,0xc
ffffffffc0201906:	14a77363          	bgeu	a4,a0,ffffffffc0201a4c <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc020190a:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc020190e:	fff80537          	lui	a0,0xfff80
ffffffffc0201912:	972a                	add	a4,a4,a0
ffffffffc0201914:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201916:	8c1d                	sub	s0,s0,a5
ffffffffc0201918:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc020191c:	00c45593          	srli	a1,s0,0xc
ffffffffc0201920:	9532                	add	a0,a0,a2
ffffffffc0201922:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0201924:	0009b583          	ld	a1,0(s3)
}
ffffffffc0201928:	b4c1                	j	ffffffffc02013e8 <pmm_init+0x102>
        intr_disable();
ffffffffc020192a:	80cff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020192e:	000b3783          	ld	a5,0(s6)
ffffffffc0201932:	779c                	ld	a5,40(a5)
ffffffffc0201934:	9782                	jalr	a5
ffffffffc0201936:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0201938:	ff9fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc020193c:	bb79                	j	ffffffffc02016da <pmm_init+0x3f4>
        intr_disable();
ffffffffc020193e:	ff9fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc0201942:	000b3783          	ld	a5,0(s6)
ffffffffc0201946:	779c                	ld	a5,40(a5)
ffffffffc0201948:	9782                	jalr	a5
ffffffffc020194a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020194c:	fe5fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201950:	b39d                	j	ffffffffc02016b6 <pmm_init+0x3d0>
ffffffffc0201952:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201954:	fe3fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201958:	000b3783          	ld	a5,0(s6)
ffffffffc020195c:	6522                	ld	a0,8(sp)
ffffffffc020195e:	4585                	li	a1,1
ffffffffc0201960:	739c                	ld	a5,32(a5)
ffffffffc0201962:	9782                	jalr	a5
        intr_enable();
ffffffffc0201964:	fcdfe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201968:	b33d                	j	ffffffffc0201696 <pmm_init+0x3b0>
ffffffffc020196a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020196c:	fcbfe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc0201970:	000b3783          	ld	a5,0(s6)
ffffffffc0201974:	6522                	ld	a0,8(sp)
ffffffffc0201976:	4585                	li	a1,1
ffffffffc0201978:	739c                	ld	a5,32(a5)
ffffffffc020197a:	9782                	jalr	a5
        intr_enable();
ffffffffc020197c:	fb5fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201980:	b1dd                	j	ffffffffc0201666 <pmm_init+0x380>
        intr_disable();
ffffffffc0201982:	fb5fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201986:	000b3783          	ld	a5,0(s6)
ffffffffc020198a:	4505                	li	a0,1
ffffffffc020198c:	6f9c                	ld	a5,24(a5)
ffffffffc020198e:	9782                	jalr	a5
ffffffffc0201990:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0201992:	f9ffe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201996:	b36d                	j	ffffffffc0201740 <pmm_init+0x45a>
        intr_disable();
ffffffffc0201998:	f9ffe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020199c:	000b3783          	ld	a5,0(s6)
ffffffffc02019a0:	779c                	ld	a5,40(a5)
ffffffffc02019a2:	9782                	jalr	a5
ffffffffc02019a4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02019a6:	f8bfe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02019aa:	bdf9                	j	ffffffffc0201888 <pmm_init+0x5a2>
ffffffffc02019ac:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02019ae:	f89fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02019b2:	000b3783          	ld	a5,0(s6)
ffffffffc02019b6:	6522                	ld	a0,8(sp)
ffffffffc02019b8:	4585                	li	a1,1
ffffffffc02019ba:	739c                	ld	a5,32(a5)
ffffffffc02019bc:	9782                	jalr	a5
        intr_enable();
ffffffffc02019be:	f73fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02019c2:	b55d                	j	ffffffffc0201868 <pmm_init+0x582>
ffffffffc02019c4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02019c6:	f71fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc02019ca:	000b3783          	ld	a5,0(s6)
ffffffffc02019ce:	6522                	ld	a0,8(sp)
ffffffffc02019d0:	4585                	li	a1,1
ffffffffc02019d2:	739c                	ld	a5,32(a5)
ffffffffc02019d4:	9782                	jalr	a5
        intr_enable();
ffffffffc02019d6:	f5bfe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02019da:	bdb9                	j	ffffffffc0201838 <pmm_init+0x552>
        intr_disable();
ffffffffc02019dc:	f5bfe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc02019e0:	000b3783          	ld	a5,0(s6)
ffffffffc02019e4:	4585                	li	a1,1
ffffffffc02019e6:	8552                	mv	a0,s4
ffffffffc02019e8:	739c                	ld	a5,32(a5)
ffffffffc02019ea:	9782                	jalr	a5
        intr_enable();
ffffffffc02019ec:	f45fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02019f0:	bd29                	j	ffffffffc020180a <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02019f2:	86a2                	mv	a3,s0
ffffffffc02019f4:	00003617          	auipc	a2,0x3
ffffffffc02019f8:	c1460613          	addi	a2,a2,-1004 # ffffffffc0204608 <commands+0x860>
ffffffffc02019fc:	1a400593          	li	a1,420
ffffffffc0201a00:	00003517          	auipc	a0,0x3
ffffffffc0201a04:	c3050513          	addi	a0,a0,-976 # ffffffffc0204630 <commands+0x888>
ffffffffc0201a08:	fd6fe0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201a0c:	00003697          	auipc	a3,0x3
ffffffffc0201a10:	08c68693          	addi	a3,a3,140 # ffffffffc0204a98 <commands+0xcf0>
ffffffffc0201a14:	00003617          	auipc	a2,0x3
ffffffffc0201a18:	d2460613          	addi	a2,a2,-732 # ffffffffc0204738 <commands+0x990>
ffffffffc0201a1c:	1a500593          	li	a1,421
ffffffffc0201a20:	00003517          	auipc	a0,0x3
ffffffffc0201a24:	c1050513          	addi	a0,a0,-1008 # ffffffffc0204630 <commands+0x888>
ffffffffc0201a28:	fb6fe0ef          	jal	ra,ffffffffc02001de <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201a2c:	00003697          	auipc	a3,0x3
ffffffffc0201a30:	02c68693          	addi	a3,a3,44 # ffffffffc0204a58 <commands+0xcb0>
ffffffffc0201a34:	00003617          	auipc	a2,0x3
ffffffffc0201a38:	d0460613          	addi	a2,a2,-764 # ffffffffc0204738 <commands+0x990>
ffffffffc0201a3c:	1a400593          	li	a1,420
ffffffffc0201a40:	00003517          	auipc	a0,0x3
ffffffffc0201a44:	bf050513          	addi	a0,a0,-1040 # ffffffffc0204630 <commands+0x888>
ffffffffc0201a48:	f96fe0ef          	jal	ra,ffffffffc02001de <__panic>
ffffffffc0201a4c:	b9eff0ef          	jal	ra,ffffffffc0200dea <pa2page.part.0>
ffffffffc0201a50:	bb6ff0ef          	jal	ra,ffffffffc0200e06 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0201a54:	00003697          	auipc	a3,0x3
ffffffffc0201a58:	dfc68693          	addi	a3,a3,-516 # ffffffffc0204850 <commands+0xaa8>
ffffffffc0201a5c:	00003617          	auipc	a2,0x3
ffffffffc0201a60:	cdc60613          	addi	a2,a2,-804 # ffffffffc0204738 <commands+0x990>
ffffffffc0201a64:	17400593          	li	a1,372
ffffffffc0201a68:	00003517          	auipc	a0,0x3
ffffffffc0201a6c:	bc850513          	addi	a0,a0,-1080 # ffffffffc0204630 <commands+0x888>
ffffffffc0201a70:	f6efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0201a74:	00003697          	auipc	a3,0x3
ffffffffc0201a78:	d1c68693          	addi	a3,a3,-740 # ffffffffc0204790 <commands+0x9e8>
ffffffffc0201a7c:	00003617          	auipc	a2,0x3
ffffffffc0201a80:	cbc60613          	addi	a2,a2,-836 # ffffffffc0204738 <commands+0x990>
ffffffffc0201a84:	16700593          	li	a1,359
ffffffffc0201a88:	00003517          	auipc	a0,0x3
ffffffffc0201a8c:	ba850513          	addi	a0,a0,-1112 # ffffffffc0204630 <commands+0x888>
ffffffffc0201a90:	f4efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0201a94:	00003697          	auipc	a3,0x3
ffffffffc0201a98:	cbc68693          	addi	a3,a3,-836 # ffffffffc0204750 <commands+0x9a8>
ffffffffc0201a9c:	00003617          	auipc	a2,0x3
ffffffffc0201aa0:	c9c60613          	addi	a2,a2,-868 # ffffffffc0204738 <commands+0x990>
ffffffffc0201aa4:	16600593          	li	a1,358
ffffffffc0201aa8:	00003517          	auipc	a0,0x3
ffffffffc0201aac:	b8850513          	addi	a0,a0,-1144 # ffffffffc0204630 <commands+0x888>
ffffffffc0201ab0:	f2efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201ab4:	00003697          	auipc	a3,0x3
ffffffffc0201ab8:	c6468693          	addi	a3,a3,-924 # ffffffffc0204718 <commands+0x970>
ffffffffc0201abc:	00003617          	auipc	a2,0x3
ffffffffc0201ac0:	c7c60613          	addi	a2,a2,-900 # ffffffffc0204738 <commands+0x990>
ffffffffc0201ac4:	16500593          	li	a1,357
ffffffffc0201ac8:	00003517          	auipc	a0,0x3
ffffffffc0201acc:	b6850513          	addi	a0,a0,-1176 # ffffffffc0204630 <commands+0x888>
ffffffffc0201ad0:	f0efe0ef          	jal	ra,ffffffffc02001de <__panic>
    return KADDR(page2pa(page));
ffffffffc0201ad4:	00003617          	auipc	a2,0x3
ffffffffc0201ad8:	b3460613          	addi	a2,a2,-1228 # ffffffffc0204608 <commands+0x860>
ffffffffc0201adc:	07100593          	li	a1,113
ffffffffc0201ae0:	00003517          	auipc	a0,0x3
ffffffffc0201ae4:	af050513          	addi	a0,a0,-1296 # ffffffffc02045d0 <commands+0x828>
ffffffffc0201ae8:	ef6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0201aec:	00003697          	auipc	a3,0x3
ffffffffc0201af0:	ef468693          	addi	a3,a3,-268 # ffffffffc02049e0 <commands+0xc38>
ffffffffc0201af4:	00003617          	auipc	a2,0x3
ffffffffc0201af8:	c4460613          	addi	a2,a2,-956 # ffffffffc0204738 <commands+0x990>
ffffffffc0201afc:	18d00593          	li	a1,397
ffffffffc0201b00:	00003517          	auipc	a0,0x3
ffffffffc0201b04:	b3050513          	addi	a0,a0,-1232 # ffffffffc0204630 <commands+0x888>
ffffffffc0201b08:	ed6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201b0c:	00003697          	auipc	a3,0x3
ffffffffc0201b10:	e8c68693          	addi	a3,a3,-372 # ffffffffc0204998 <commands+0xbf0>
ffffffffc0201b14:	00003617          	auipc	a2,0x3
ffffffffc0201b18:	c2460613          	addi	a2,a2,-988 # ffffffffc0204738 <commands+0x990>
ffffffffc0201b1c:	18b00593          	li	a1,395
ffffffffc0201b20:	00003517          	auipc	a0,0x3
ffffffffc0201b24:	b1050513          	addi	a0,a0,-1264 # ffffffffc0204630 <commands+0x888>
ffffffffc0201b28:	eb6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0201b2c:	00003697          	auipc	a3,0x3
ffffffffc0201b30:	e9c68693          	addi	a3,a3,-356 # ffffffffc02049c8 <commands+0xc20>
ffffffffc0201b34:	00003617          	auipc	a2,0x3
ffffffffc0201b38:	c0460613          	addi	a2,a2,-1020 # ffffffffc0204738 <commands+0x990>
ffffffffc0201b3c:	18a00593          	li	a1,394
ffffffffc0201b40:	00003517          	auipc	a0,0x3
ffffffffc0201b44:	af050513          	addi	a0,a0,-1296 # ffffffffc0204630 <commands+0x888>
ffffffffc0201b48:	e96fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0201b4c:	00003697          	auipc	a3,0x3
ffffffffc0201b50:	f6468693          	addi	a3,a3,-156 # ffffffffc0204ab0 <commands+0xd08>
ffffffffc0201b54:	00003617          	auipc	a2,0x3
ffffffffc0201b58:	be460613          	addi	a2,a2,-1052 # ffffffffc0204738 <commands+0x990>
ffffffffc0201b5c:	1a800593          	li	a1,424
ffffffffc0201b60:	00003517          	auipc	a0,0x3
ffffffffc0201b64:	ad050513          	addi	a0,a0,-1328 # ffffffffc0204630 <commands+0x888>
ffffffffc0201b68:	e76fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0201b6c:	00003697          	auipc	a3,0x3
ffffffffc0201b70:	ea468693          	addi	a3,a3,-348 # ffffffffc0204a10 <commands+0xc68>
ffffffffc0201b74:	00003617          	auipc	a2,0x3
ffffffffc0201b78:	bc460613          	addi	a2,a2,-1084 # ffffffffc0204738 <commands+0x990>
ffffffffc0201b7c:	19500593          	li	a1,405
ffffffffc0201b80:	00003517          	auipc	a0,0x3
ffffffffc0201b84:	ab050513          	addi	a0,a0,-1360 # ffffffffc0204630 <commands+0x888>
ffffffffc0201b88:	e56fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p) == 1);
ffffffffc0201b8c:	00003697          	auipc	a3,0x3
ffffffffc0201b90:	f7c68693          	addi	a3,a3,-132 # ffffffffc0204b08 <commands+0xd60>
ffffffffc0201b94:	00003617          	auipc	a2,0x3
ffffffffc0201b98:	ba460613          	addi	a2,a2,-1116 # ffffffffc0204738 <commands+0x990>
ffffffffc0201b9c:	1ad00593          	li	a1,429
ffffffffc0201ba0:	00003517          	auipc	a0,0x3
ffffffffc0201ba4:	a9050513          	addi	a0,a0,-1392 # ffffffffc0204630 <commands+0x888>
ffffffffc0201ba8:	e36fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201bac:	00003697          	auipc	a3,0x3
ffffffffc0201bb0:	f1c68693          	addi	a3,a3,-228 # ffffffffc0204ac8 <commands+0xd20>
ffffffffc0201bb4:	00003617          	auipc	a2,0x3
ffffffffc0201bb8:	b8460613          	addi	a2,a2,-1148 # ffffffffc0204738 <commands+0x990>
ffffffffc0201bbc:	1ac00593          	li	a1,428
ffffffffc0201bc0:	00003517          	auipc	a0,0x3
ffffffffc0201bc4:	a7050513          	addi	a0,a0,-1424 # ffffffffc0204630 <commands+0x888>
ffffffffc0201bc8:	e16fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201bcc:	00003697          	auipc	a3,0x3
ffffffffc0201bd0:	dcc68693          	addi	a3,a3,-564 # ffffffffc0204998 <commands+0xbf0>
ffffffffc0201bd4:	00003617          	auipc	a2,0x3
ffffffffc0201bd8:	b6460613          	addi	a2,a2,-1180 # ffffffffc0204738 <commands+0x990>
ffffffffc0201bdc:	18700593          	li	a1,391
ffffffffc0201be0:	00003517          	auipc	a0,0x3
ffffffffc0201be4:	a5050513          	addi	a0,a0,-1456 # ffffffffc0204630 <commands+0x888>
ffffffffc0201be8:	df6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201bec:	00003697          	auipc	a3,0x3
ffffffffc0201bf0:	c4c68693          	addi	a3,a3,-948 # ffffffffc0204838 <commands+0xa90>
ffffffffc0201bf4:	00003617          	auipc	a2,0x3
ffffffffc0201bf8:	b4460613          	addi	a2,a2,-1212 # ffffffffc0204738 <commands+0x990>
ffffffffc0201bfc:	18600593          	li	a1,390
ffffffffc0201c00:	00003517          	auipc	a0,0x3
ffffffffc0201c04:	a3050513          	addi	a0,a0,-1488 # ffffffffc0204630 <commands+0x888>
ffffffffc0201c08:	dd6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201c0c:	00003697          	auipc	a3,0x3
ffffffffc0201c10:	da468693          	addi	a3,a3,-604 # ffffffffc02049b0 <commands+0xc08>
ffffffffc0201c14:	00003617          	auipc	a2,0x3
ffffffffc0201c18:	b2460613          	addi	a2,a2,-1244 # ffffffffc0204738 <commands+0x990>
ffffffffc0201c1c:	18300593          	li	a1,387
ffffffffc0201c20:	00003517          	auipc	a0,0x3
ffffffffc0201c24:	a1050513          	addi	a0,a0,-1520 # ffffffffc0204630 <commands+0x888>
ffffffffc0201c28:	db6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201c2c:	00003697          	auipc	a3,0x3
ffffffffc0201c30:	bf468693          	addi	a3,a3,-1036 # ffffffffc0204820 <commands+0xa78>
ffffffffc0201c34:	00003617          	auipc	a2,0x3
ffffffffc0201c38:	b0460613          	addi	a2,a2,-1276 # ffffffffc0204738 <commands+0x990>
ffffffffc0201c3c:	18200593          	li	a1,386
ffffffffc0201c40:	00003517          	auipc	a0,0x3
ffffffffc0201c44:	9f050513          	addi	a0,a0,-1552 # ffffffffc0204630 <commands+0x888>
ffffffffc0201c48:	d96fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201c4c:	00003697          	auipc	a3,0x3
ffffffffc0201c50:	c7468693          	addi	a3,a3,-908 # ffffffffc02048c0 <commands+0xb18>
ffffffffc0201c54:	00003617          	auipc	a2,0x3
ffffffffc0201c58:	ae460613          	addi	a2,a2,-1308 # ffffffffc0204738 <commands+0x990>
ffffffffc0201c5c:	18100593          	li	a1,385
ffffffffc0201c60:	00003517          	auipc	a0,0x3
ffffffffc0201c64:	9d050513          	addi	a0,a0,-1584 # ffffffffc0204630 <commands+0x888>
ffffffffc0201c68:	d76fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201c6c:	00003697          	auipc	a3,0x3
ffffffffc0201c70:	d2c68693          	addi	a3,a3,-724 # ffffffffc0204998 <commands+0xbf0>
ffffffffc0201c74:	00003617          	auipc	a2,0x3
ffffffffc0201c78:	ac460613          	addi	a2,a2,-1340 # ffffffffc0204738 <commands+0x990>
ffffffffc0201c7c:	18000593          	li	a1,384
ffffffffc0201c80:	00003517          	auipc	a0,0x3
ffffffffc0201c84:	9b050513          	addi	a0,a0,-1616 # ffffffffc0204630 <commands+0x888>
ffffffffc0201c88:	d56fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0201c8c:	00003697          	auipc	a3,0x3
ffffffffc0201c90:	cf468693          	addi	a3,a3,-780 # ffffffffc0204980 <commands+0xbd8>
ffffffffc0201c94:	00003617          	auipc	a2,0x3
ffffffffc0201c98:	aa460613          	addi	a2,a2,-1372 # ffffffffc0204738 <commands+0x990>
ffffffffc0201c9c:	17f00593          	li	a1,383
ffffffffc0201ca0:	00003517          	auipc	a0,0x3
ffffffffc0201ca4:	99050513          	addi	a0,a0,-1648 # ffffffffc0204630 <commands+0x888>
ffffffffc0201ca8:	d36fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0201cac:	00003697          	auipc	a3,0x3
ffffffffc0201cb0:	ca468693          	addi	a3,a3,-860 # ffffffffc0204950 <commands+0xba8>
ffffffffc0201cb4:	00003617          	auipc	a2,0x3
ffffffffc0201cb8:	a8460613          	addi	a2,a2,-1404 # ffffffffc0204738 <commands+0x990>
ffffffffc0201cbc:	17e00593          	li	a1,382
ffffffffc0201cc0:	00003517          	auipc	a0,0x3
ffffffffc0201cc4:	97050513          	addi	a0,a0,-1680 # ffffffffc0204630 <commands+0x888>
ffffffffc0201cc8:	d16fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0201ccc:	00003697          	auipc	a3,0x3
ffffffffc0201cd0:	c6c68693          	addi	a3,a3,-916 # ffffffffc0204938 <commands+0xb90>
ffffffffc0201cd4:	00003617          	auipc	a2,0x3
ffffffffc0201cd8:	a6460613          	addi	a2,a2,-1436 # ffffffffc0204738 <commands+0x990>
ffffffffc0201cdc:	17c00593          	li	a1,380
ffffffffc0201ce0:	00003517          	auipc	a0,0x3
ffffffffc0201ce4:	95050513          	addi	a0,a0,-1712 # ffffffffc0204630 <commands+0x888>
ffffffffc0201ce8:	cf6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0201cec:	00003697          	auipc	a3,0x3
ffffffffc0201cf0:	c2c68693          	addi	a3,a3,-980 # ffffffffc0204918 <commands+0xb70>
ffffffffc0201cf4:	00003617          	auipc	a2,0x3
ffffffffc0201cf8:	a4460613          	addi	a2,a2,-1468 # ffffffffc0204738 <commands+0x990>
ffffffffc0201cfc:	17b00593          	li	a1,379
ffffffffc0201d00:	00003517          	auipc	a0,0x3
ffffffffc0201d04:	93050513          	addi	a0,a0,-1744 # ffffffffc0204630 <commands+0x888>
ffffffffc0201d08:	cd6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(*ptep & PTE_W);
ffffffffc0201d0c:	00003697          	auipc	a3,0x3
ffffffffc0201d10:	bfc68693          	addi	a3,a3,-1028 # ffffffffc0204908 <commands+0xb60>
ffffffffc0201d14:	00003617          	auipc	a2,0x3
ffffffffc0201d18:	a2460613          	addi	a2,a2,-1500 # ffffffffc0204738 <commands+0x990>
ffffffffc0201d1c:	17a00593          	li	a1,378
ffffffffc0201d20:	00003517          	auipc	a0,0x3
ffffffffc0201d24:	91050513          	addi	a0,a0,-1776 # ffffffffc0204630 <commands+0x888>
ffffffffc0201d28:	cb6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(*ptep & PTE_U);
ffffffffc0201d2c:	00003697          	auipc	a3,0x3
ffffffffc0201d30:	bcc68693          	addi	a3,a3,-1076 # ffffffffc02048f8 <commands+0xb50>
ffffffffc0201d34:	00003617          	auipc	a2,0x3
ffffffffc0201d38:	a0460613          	addi	a2,a2,-1532 # ffffffffc0204738 <commands+0x990>
ffffffffc0201d3c:	17900593          	li	a1,377
ffffffffc0201d40:	00003517          	auipc	a0,0x3
ffffffffc0201d44:	8f050513          	addi	a0,a0,-1808 # ffffffffc0204630 <commands+0x888>
ffffffffc0201d48:	c96fe0ef          	jal	ra,ffffffffc02001de <__panic>
        panic("DTB memory info not available");
ffffffffc0201d4c:	00003617          	auipc	a2,0x3
ffffffffc0201d50:	90c60613          	addi	a2,a2,-1780 # ffffffffc0204658 <commands+0x8b0>
ffffffffc0201d54:	06400593          	li	a1,100
ffffffffc0201d58:	00003517          	auipc	a0,0x3
ffffffffc0201d5c:	8d850513          	addi	a0,a0,-1832 # ffffffffc0204630 <commands+0x888>
ffffffffc0201d60:	c7efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0201d64:	00003697          	auipc	a3,0x3
ffffffffc0201d68:	cac68693          	addi	a3,a3,-852 # ffffffffc0204a10 <commands+0xc68>
ffffffffc0201d6c:	00003617          	auipc	a2,0x3
ffffffffc0201d70:	9cc60613          	addi	a2,a2,-1588 # ffffffffc0204738 <commands+0x990>
ffffffffc0201d74:	1bf00593          	li	a1,447
ffffffffc0201d78:	00003517          	auipc	a0,0x3
ffffffffc0201d7c:	8b850513          	addi	a0,a0,-1864 # ffffffffc0204630 <commands+0x888>
ffffffffc0201d80:	c5efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201d84:	00003697          	auipc	a3,0x3
ffffffffc0201d88:	b3c68693          	addi	a3,a3,-1220 # ffffffffc02048c0 <commands+0xb18>
ffffffffc0201d8c:	00003617          	auipc	a2,0x3
ffffffffc0201d90:	9ac60613          	addi	a2,a2,-1620 # ffffffffc0204738 <commands+0x990>
ffffffffc0201d94:	17800593          	li	a1,376
ffffffffc0201d98:	00003517          	auipc	a0,0x3
ffffffffc0201d9c:	89850513          	addi	a0,a0,-1896 # ffffffffc0204630 <commands+0x888>
ffffffffc0201da0:	c3efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201da4:	00003697          	auipc	a3,0x3
ffffffffc0201da8:	adc68693          	addi	a3,a3,-1316 # ffffffffc0204880 <commands+0xad8>
ffffffffc0201dac:	00003617          	auipc	a2,0x3
ffffffffc0201db0:	98c60613          	addi	a2,a2,-1652 # ffffffffc0204738 <commands+0x990>
ffffffffc0201db4:	17700593          	li	a1,375
ffffffffc0201db8:	00003517          	auipc	a0,0x3
ffffffffc0201dbc:	87850513          	addi	a0,a0,-1928 # ffffffffc0204630 <commands+0x888>
ffffffffc0201dc0:	c1efe0ef          	jal	ra,ffffffffc02001de <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201dc4:	86d6                	mv	a3,s5
ffffffffc0201dc6:	00003617          	auipc	a2,0x3
ffffffffc0201dca:	84260613          	addi	a2,a2,-1982 # ffffffffc0204608 <commands+0x860>
ffffffffc0201dce:	17300593          	li	a1,371
ffffffffc0201dd2:	00003517          	auipc	a0,0x3
ffffffffc0201dd6:	85e50513          	addi	a0,a0,-1954 # ffffffffc0204630 <commands+0x888>
ffffffffc0201dda:	c04fe0ef          	jal	ra,ffffffffc02001de <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0201dde:	00003617          	auipc	a2,0x3
ffffffffc0201de2:	82a60613          	addi	a2,a2,-2006 # ffffffffc0204608 <commands+0x860>
ffffffffc0201de6:	17200593          	li	a1,370
ffffffffc0201dea:	00003517          	auipc	a0,0x3
ffffffffc0201dee:	84650513          	addi	a0,a0,-1978 # ffffffffc0204630 <commands+0x888>
ffffffffc0201df2:	becfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201df6:	00003697          	auipc	a3,0x3
ffffffffc0201dfa:	a4268693          	addi	a3,a3,-1470 # ffffffffc0204838 <commands+0xa90>
ffffffffc0201dfe:	00003617          	auipc	a2,0x3
ffffffffc0201e02:	93a60613          	addi	a2,a2,-1734 # ffffffffc0204738 <commands+0x990>
ffffffffc0201e06:	17000593          	li	a1,368
ffffffffc0201e0a:	00003517          	auipc	a0,0x3
ffffffffc0201e0e:	82650513          	addi	a0,a0,-2010 # ffffffffc0204630 <commands+0x888>
ffffffffc0201e12:	bccfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201e16:	00003697          	auipc	a3,0x3
ffffffffc0201e1a:	a0a68693          	addi	a3,a3,-1526 # ffffffffc0204820 <commands+0xa78>
ffffffffc0201e1e:	00003617          	auipc	a2,0x3
ffffffffc0201e22:	91a60613          	addi	a2,a2,-1766 # ffffffffc0204738 <commands+0x990>
ffffffffc0201e26:	16f00593          	li	a1,367
ffffffffc0201e2a:	00003517          	auipc	a0,0x3
ffffffffc0201e2e:	80650513          	addi	a0,a0,-2042 # ffffffffc0204630 <commands+0x888>
ffffffffc0201e32:	bacfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201e36:	00003697          	auipc	a3,0x3
ffffffffc0201e3a:	d9a68693          	addi	a3,a3,-614 # ffffffffc0204bd0 <commands+0xe28>
ffffffffc0201e3e:	00003617          	auipc	a2,0x3
ffffffffc0201e42:	8fa60613          	addi	a2,a2,-1798 # ffffffffc0204738 <commands+0x990>
ffffffffc0201e46:	1b600593          	li	a1,438
ffffffffc0201e4a:	00002517          	auipc	a0,0x2
ffffffffc0201e4e:	7e650513          	addi	a0,a0,2022 # ffffffffc0204630 <commands+0x888>
ffffffffc0201e52:	b8cfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201e56:	00003697          	auipc	a3,0x3
ffffffffc0201e5a:	d4268693          	addi	a3,a3,-702 # ffffffffc0204b98 <commands+0xdf0>
ffffffffc0201e5e:	00003617          	auipc	a2,0x3
ffffffffc0201e62:	8da60613          	addi	a2,a2,-1830 # ffffffffc0204738 <commands+0x990>
ffffffffc0201e66:	1b300593          	li	a1,435
ffffffffc0201e6a:	00002517          	auipc	a0,0x2
ffffffffc0201e6e:	7c650513          	addi	a0,a0,1990 # ffffffffc0204630 <commands+0x888>
ffffffffc0201e72:	b6cfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p) == 2);
ffffffffc0201e76:	00003697          	auipc	a3,0x3
ffffffffc0201e7a:	cf268693          	addi	a3,a3,-782 # ffffffffc0204b68 <commands+0xdc0>
ffffffffc0201e7e:	00003617          	auipc	a2,0x3
ffffffffc0201e82:	8ba60613          	addi	a2,a2,-1862 # ffffffffc0204738 <commands+0x990>
ffffffffc0201e86:	1af00593          	li	a1,431
ffffffffc0201e8a:	00002517          	auipc	a0,0x2
ffffffffc0201e8e:	7a650513          	addi	a0,a0,1958 # ffffffffc0204630 <commands+0x888>
ffffffffc0201e92:	b4cfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201e96:	00003697          	auipc	a3,0x3
ffffffffc0201e9a:	c8a68693          	addi	a3,a3,-886 # ffffffffc0204b20 <commands+0xd78>
ffffffffc0201e9e:	00003617          	auipc	a2,0x3
ffffffffc0201ea2:	89a60613          	addi	a2,a2,-1894 # ffffffffc0204738 <commands+0x990>
ffffffffc0201ea6:	1ae00593          	li	a1,430
ffffffffc0201eaa:	00002517          	auipc	a0,0x2
ffffffffc0201eae:	78650513          	addi	a0,a0,1926 # ffffffffc0204630 <commands+0x888>
ffffffffc0201eb2:	b2cfe0ef          	jal	ra,ffffffffc02001de <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0201eb6:	00003617          	auipc	a2,0x3
ffffffffc0201eba:	80260613          	addi	a2,a2,-2046 # ffffffffc02046b8 <commands+0x910>
ffffffffc0201ebe:	0cb00593          	li	a1,203
ffffffffc0201ec2:	00002517          	auipc	a0,0x2
ffffffffc0201ec6:	76e50513          	addi	a0,a0,1902 # ffffffffc0204630 <commands+0x888>
ffffffffc0201eca:	b14fe0ef          	jal	ra,ffffffffc02001de <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201ece:	00002617          	auipc	a2,0x2
ffffffffc0201ed2:	7ea60613          	addi	a2,a2,2026 # ffffffffc02046b8 <commands+0x910>
ffffffffc0201ed6:	08000593          	li	a1,128
ffffffffc0201eda:	00002517          	auipc	a0,0x2
ffffffffc0201ede:	75650513          	addi	a0,a0,1878 # ffffffffc0204630 <commands+0x888>
ffffffffc0201ee2:	afcfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0201ee6:	00003697          	auipc	a3,0x3
ffffffffc0201eea:	90a68693          	addi	a3,a3,-1782 # ffffffffc02047f0 <commands+0xa48>
ffffffffc0201eee:	00003617          	auipc	a2,0x3
ffffffffc0201ef2:	84a60613          	addi	a2,a2,-1974 # ffffffffc0204738 <commands+0x990>
ffffffffc0201ef6:	16e00593          	li	a1,366
ffffffffc0201efa:	00002517          	auipc	a0,0x2
ffffffffc0201efe:	73650513          	addi	a0,a0,1846 # ffffffffc0204630 <commands+0x888>
ffffffffc0201f02:	adcfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0201f06:	00003697          	auipc	a3,0x3
ffffffffc0201f0a:	8ba68693          	addi	a3,a3,-1862 # ffffffffc02047c0 <commands+0xa18>
ffffffffc0201f0e:	00003617          	auipc	a2,0x3
ffffffffc0201f12:	82a60613          	addi	a2,a2,-2006 # ffffffffc0204738 <commands+0x990>
ffffffffc0201f16:	16b00593          	li	a1,363
ffffffffc0201f1a:	00002517          	auipc	a0,0x2
ffffffffc0201f1e:	71650513          	addi	a0,a0,1814 # ffffffffc0204630 <commands+0x888>
ffffffffc0201f22:	abcfe0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0201f26 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0201f26:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0201f28:	00003697          	auipc	a3,0x3
ffffffffc0201f2c:	cf068693          	addi	a3,a3,-784 # ffffffffc0204c18 <commands+0xe70>
ffffffffc0201f30:	00003617          	auipc	a2,0x3
ffffffffc0201f34:	80860613          	addi	a2,a2,-2040 # ffffffffc0204738 <commands+0x990>
ffffffffc0201f38:	08800593          	li	a1,136
ffffffffc0201f3c:	00003517          	auipc	a0,0x3
ffffffffc0201f40:	cfc50513          	addi	a0,a0,-772 # ffffffffc0204c38 <commands+0xe90>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0201f44:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0201f46:	a98fe0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0201f4a <find_vma>:
{
ffffffffc0201f4a:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0201f4c:	c505                	beqz	a0,ffffffffc0201f74 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0201f4e:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0201f50:	c501                	beqz	a0,ffffffffc0201f58 <find_vma+0xe>
ffffffffc0201f52:	651c                	ld	a5,8(a0)
ffffffffc0201f54:	02f5f263          	bgeu	a1,a5,ffffffffc0201f78 <find_vma+0x2e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0201f58:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0201f5a:	00f68d63          	beq	a3,a5,ffffffffc0201f74 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0201f5e:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7df2b04>
ffffffffc0201f62:	00e5e663          	bltu	a1,a4,ffffffffc0201f6e <find_vma+0x24>
ffffffffc0201f66:	ff07b703          	ld	a4,-16(a5)
ffffffffc0201f6a:	00e5ec63          	bltu	a1,a4,ffffffffc0201f82 <find_vma+0x38>
ffffffffc0201f6e:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0201f70:	fef697e3          	bne	a3,a5,ffffffffc0201f5e <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0201f74:	4501                	li	a0,0
}
ffffffffc0201f76:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0201f78:	691c                	ld	a5,16(a0)
ffffffffc0201f7a:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0201f58 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0201f7e:	ea88                	sd	a0,16(a3)
ffffffffc0201f80:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0201f82:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0201f86:	ea88                	sd	a0,16(a3)
ffffffffc0201f88:	8082                	ret

ffffffffc0201f8a <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201f8a:	6590                	ld	a2,8(a1)
ffffffffc0201f8c:	0105b803          	ld	a6,16(a1)
{
ffffffffc0201f90:	1141                	addi	sp,sp,-16
ffffffffc0201f92:	e406                	sd	ra,8(sp)
ffffffffc0201f94:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201f96:	01066763          	bltu	a2,a6,ffffffffc0201fa4 <insert_vma_struct+0x1a>
ffffffffc0201f9a:	a085                	j	ffffffffc0201ffa <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0201f9c:	fe87b703          	ld	a4,-24(a5)
ffffffffc0201fa0:	04e66863          	bltu	a2,a4,ffffffffc0201ff0 <insert_vma_struct+0x66>
ffffffffc0201fa4:	86be                	mv	a3,a5
ffffffffc0201fa6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0201fa8:	fef51ae3          	bne	a0,a5,ffffffffc0201f9c <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0201fac:	02a68463          	beq	a3,a0,ffffffffc0201fd4 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0201fb0:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0201fb4:	fe86b883          	ld	a7,-24(a3)
ffffffffc0201fb8:	08e8f163          	bgeu	a7,a4,ffffffffc020203a <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201fbc:	04e66f63          	bltu	a2,a4,ffffffffc020201a <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0201fc0:	00f50a63          	beq	a0,a5,ffffffffc0201fd4 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0201fc4:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201fc8:	05076963          	bltu	a4,a6,ffffffffc020201a <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0201fcc:	ff07b603          	ld	a2,-16(a5)
ffffffffc0201fd0:	02c77363          	bgeu	a4,a2,ffffffffc0201ff6 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0201fd4:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0201fd6:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0201fd8:	02058613          	addi	a2,a1,32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201fdc:	e390                	sd	a2,0(a5)
ffffffffc0201fde:	e690                	sd	a2,8(a3)
}
ffffffffc0201fe0:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0201fe2:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0201fe4:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0201fe6:	0017079b          	addiw	a5,a4,1
ffffffffc0201fea:	d11c                	sw	a5,32(a0)
}
ffffffffc0201fec:	0141                	addi	sp,sp,16
ffffffffc0201fee:	8082                	ret
    if (le_prev != list)
ffffffffc0201ff0:	fca690e3          	bne	a3,a0,ffffffffc0201fb0 <insert_vma_struct+0x26>
ffffffffc0201ff4:	bfd1                	j	ffffffffc0201fc8 <insert_vma_struct+0x3e>
ffffffffc0201ff6:	f31ff0ef          	jal	ra,ffffffffc0201f26 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201ffa:	00003697          	auipc	a3,0x3
ffffffffc0201ffe:	c4e68693          	addi	a3,a3,-946 # ffffffffc0204c48 <commands+0xea0>
ffffffffc0202002:	00002617          	auipc	a2,0x2
ffffffffc0202006:	73660613          	addi	a2,a2,1846 # ffffffffc0204738 <commands+0x990>
ffffffffc020200a:	08e00593          	li	a1,142
ffffffffc020200e:	00003517          	auipc	a0,0x3
ffffffffc0202012:	c2a50513          	addi	a0,a0,-982 # ffffffffc0204c38 <commands+0xe90>
ffffffffc0202016:	9c8fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020201a:	00003697          	auipc	a3,0x3
ffffffffc020201e:	c6e68693          	addi	a3,a3,-914 # ffffffffc0204c88 <commands+0xee0>
ffffffffc0202022:	00002617          	auipc	a2,0x2
ffffffffc0202026:	71660613          	addi	a2,a2,1814 # ffffffffc0204738 <commands+0x990>
ffffffffc020202a:	08700593          	li	a1,135
ffffffffc020202e:	00003517          	auipc	a0,0x3
ffffffffc0202032:	c0a50513          	addi	a0,a0,-1014 # ffffffffc0204c38 <commands+0xe90>
ffffffffc0202036:	9a8fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020203a:	00003697          	auipc	a3,0x3
ffffffffc020203e:	c2e68693          	addi	a3,a3,-978 # ffffffffc0204c68 <commands+0xec0>
ffffffffc0202042:	00002617          	auipc	a2,0x2
ffffffffc0202046:	6f660613          	addi	a2,a2,1782 # ffffffffc0204738 <commands+0x990>
ffffffffc020204a:	08600593          	li	a1,134
ffffffffc020204e:	00003517          	auipc	a0,0x3
ffffffffc0202052:	bea50513          	addi	a0,a0,-1046 # ffffffffc0204c38 <commands+0xe90>
ffffffffc0202056:	988fe0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc020205a <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc020205a:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020205c:	03000513          	li	a0,48
{
ffffffffc0202060:	fc06                	sd	ra,56(sp)
ffffffffc0202062:	f822                	sd	s0,48(sp)
ffffffffc0202064:	f426                	sd	s1,40(sp)
ffffffffc0202066:	f04a                	sd	s2,32(sp)
ffffffffc0202068:	ec4e                	sd	s3,24(sp)
ffffffffc020206a:	e852                	sd	s4,16(sp)
ffffffffc020206c:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020206e:	550000ef          	jal	ra,ffffffffc02025be <kmalloc>
    if (mm != NULL)
ffffffffc0202072:	2e050f63          	beqz	a0,ffffffffc0202370 <vmm_init+0x316>
ffffffffc0202076:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0202078:	e508                	sd	a0,8(a0)
ffffffffc020207a:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020207c:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202080:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202084:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202088:	02053423          	sd	zero,40(a0)
ffffffffc020208c:	03200413          	li	s0,50
ffffffffc0202090:	a811                	j	ffffffffc02020a4 <vmm_init+0x4a>
        vma->vm_start = vm_start;
ffffffffc0202092:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202094:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202096:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc020209a:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020209c:	8526                	mv	a0,s1
ffffffffc020209e:	eedff0ef          	jal	ra,ffffffffc0201f8a <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc02020a2:	c80d                	beqz	s0,ffffffffc02020d4 <vmm_init+0x7a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02020a4:	03000513          	li	a0,48
ffffffffc02020a8:	516000ef          	jal	ra,ffffffffc02025be <kmalloc>
ffffffffc02020ac:	85aa                	mv	a1,a0
ffffffffc02020ae:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc02020b2:	f165                	bnez	a0,ffffffffc0202092 <vmm_init+0x38>
        assert(vma != NULL);
ffffffffc02020b4:	00003697          	auipc	a3,0x3
ffffffffc02020b8:	d6c68693          	addi	a3,a3,-660 # ffffffffc0204e20 <commands+0x1078>
ffffffffc02020bc:	00002617          	auipc	a2,0x2
ffffffffc02020c0:	67c60613          	addi	a2,a2,1660 # ffffffffc0204738 <commands+0x990>
ffffffffc02020c4:	0da00593          	li	a1,218
ffffffffc02020c8:	00003517          	auipc	a0,0x3
ffffffffc02020cc:	b7050513          	addi	a0,a0,-1168 # ffffffffc0204c38 <commands+0xe90>
ffffffffc02020d0:	90efe0ef          	jal	ra,ffffffffc02001de <__panic>
ffffffffc02020d4:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc02020d8:	1f900913          	li	s2,505
ffffffffc02020dc:	a819                	j	ffffffffc02020f2 <vmm_init+0x98>
        vma->vm_start = vm_start;
ffffffffc02020de:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc02020e0:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02020e2:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02020e6:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02020e8:	8526                	mv	a0,s1
ffffffffc02020ea:	ea1ff0ef          	jal	ra,ffffffffc0201f8a <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02020ee:	03240a63          	beq	s0,s2,ffffffffc0202122 <vmm_init+0xc8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02020f2:	03000513          	li	a0,48
ffffffffc02020f6:	4c8000ef          	jal	ra,ffffffffc02025be <kmalloc>
ffffffffc02020fa:	85aa                	mv	a1,a0
ffffffffc02020fc:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202100:	fd79                	bnez	a0,ffffffffc02020de <vmm_init+0x84>
        assert(vma != NULL);
ffffffffc0202102:	00003697          	auipc	a3,0x3
ffffffffc0202106:	d1e68693          	addi	a3,a3,-738 # ffffffffc0204e20 <commands+0x1078>
ffffffffc020210a:	00002617          	auipc	a2,0x2
ffffffffc020210e:	62e60613          	addi	a2,a2,1582 # ffffffffc0204738 <commands+0x990>
ffffffffc0202112:	0e100593          	li	a1,225
ffffffffc0202116:	00003517          	auipc	a0,0x3
ffffffffc020211a:	b2250513          	addi	a0,a0,-1246 # ffffffffc0204c38 <commands+0xe90>
ffffffffc020211e:	8c0fe0ef          	jal	ra,ffffffffc02001de <__panic>
    return listelm->next;
ffffffffc0202122:	649c                	ld	a5,8(s1)
ffffffffc0202124:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202126:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc020212a:	18f48363          	beq	s1,a5,ffffffffc02022b0 <vmm_init+0x256>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020212e:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202132:	ffe70693          	addi	a3,a4,-2 # ffe <kern_entry-0xffffffffc01ff002>
ffffffffc0202136:	10d61d63          	bne	a2,a3,ffffffffc0202250 <vmm_init+0x1f6>
ffffffffc020213a:	ff07b683          	ld	a3,-16(a5)
ffffffffc020213e:	10e69963          	bne	a3,a4,ffffffffc0202250 <vmm_init+0x1f6>
    for (i = 1; i <= step2; i++)
ffffffffc0202142:	0715                	addi	a4,a4,5
ffffffffc0202144:	679c                	ld	a5,8(a5)
ffffffffc0202146:	feb712e3          	bne	a4,a1,ffffffffc020212a <vmm_init+0xd0>
ffffffffc020214a:	4a1d                	li	s4,7
ffffffffc020214c:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc020214e:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202152:	85a2                	mv	a1,s0
ffffffffc0202154:	8526                	mv	a0,s1
ffffffffc0202156:	df5ff0ef          	jal	ra,ffffffffc0201f4a <find_vma>
ffffffffc020215a:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc020215c:	18050a63          	beqz	a0,ffffffffc02022f0 <vmm_init+0x296>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202160:	00140593          	addi	a1,s0,1
ffffffffc0202164:	8526                	mv	a0,s1
ffffffffc0202166:	de5ff0ef          	jal	ra,ffffffffc0201f4a <find_vma>
ffffffffc020216a:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc020216c:	16050263          	beqz	a0,ffffffffc02022d0 <vmm_init+0x276>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202170:	85d2                	mv	a1,s4
ffffffffc0202172:	8526                	mv	a0,s1
ffffffffc0202174:	dd7ff0ef          	jal	ra,ffffffffc0201f4a <find_vma>
        assert(vma3 == NULL);
ffffffffc0202178:	18051c63          	bnez	a0,ffffffffc0202310 <vmm_init+0x2b6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc020217c:	00340593          	addi	a1,s0,3
ffffffffc0202180:	8526                	mv	a0,s1
ffffffffc0202182:	dc9ff0ef          	jal	ra,ffffffffc0201f4a <find_vma>
        assert(vma4 == NULL);
ffffffffc0202186:	1c051563          	bnez	a0,ffffffffc0202350 <vmm_init+0x2f6>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc020218a:	00440593          	addi	a1,s0,4
ffffffffc020218e:	8526                	mv	a0,s1
ffffffffc0202190:	dbbff0ef          	jal	ra,ffffffffc0201f4a <find_vma>
        assert(vma5 == NULL);
ffffffffc0202194:	18051e63          	bnez	a0,ffffffffc0202330 <vmm_init+0x2d6>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202198:	00893783          	ld	a5,8(s2)
ffffffffc020219c:	0c879a63          	bne	a5,s0,ffffffffc0202270 <vmm_init+0x216>
ffffffffc02021a0:	01093783          	ld	a5,16(s2)
ffffffffc02021a4:	0d479663          	bne	a5,s4,ffffffffc0202270 <vmm_init+0x216>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc02021a8:	0089b783          	ld	a5,8(s3)
ffffffffc02021ac:	0e879263          	bne	a5,s0,ffffffffc0202290 <vmm_init+0x236>
ffffffffc02021b0:	0109b783          	ld	a5,16(s3)
ffffffffc02021b4:	0d479e63          	bne	a5,s4,ffffffffc0202290 <vmm_init+0x236>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc02021b8:	0415                	addi	s0,s0,5
ffffffffc02021ba:	0a15                	addi	s4,s4,5
ffffffffc02021bc:	f9541be3          	bne	s0,s5,ffffffffc0202152 <vmm_init+0xf8>
ffffffffc02021c0:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc02021c2:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc02021c4:	85a2                	mv	a1,s0
ffffffffc02021c6:	8526                	mv	a0,s1
ffffffffc02021c8:	d83ff0ef          	jal	ra,ffffffffc0201f4a <find_vma>
ffffffffc02021cc:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc02021d0:	c90d                	beqz	a0,ffffffffc0202202 <vmm_init+0x1a8>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc02021d2:	6914                	ld	a3,16(a0)
ffffffffc02021d4:	6510                	ld	a2,8(a0)
ffffffffc02021d6:	00003517          	auipc	a0,0x3
ffffffffc02021da:	bd250513          	addi	a0,a0,-1070 # ffffffffc0204da8 <commands+0x1000>
ffffffffc02021de:	f03fd0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc02021e2:	00003697          	auipc	a3,0x3
ffffffffc02021e6:	bee68693          	addi	a3,a3,-1042 # ffffffffc0204dd0 <commands+0x1028>
ffffffffc02021ea:	00002617          	auipc	a2,0x2
ffffffffc02021ee:	54e60613          	addi	a2,a2,1358 # ffffffffc0204738 <commands+0x990>
ffffffffc02021f2:	10700593          	li	a1,263
ffffffffc02021f6:	00003517          	auipc	a0,0x3
ffffffffc02021fa:	a4250513          	addi	a0,a0,-1470 # ffffffffc0204c38 <commands+0xe90>
ffffffffc02021fe:	fe1fd0ef          	jal	ra,ffffffffc02001de <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0202202:	147d                	addi	s0,s0,-1
ffffffffc0202204:	fd2410e3          	bne	s0,s2,ffffffffc02021c4 <vmm_init+0x16a>
ffffffffc0202208:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc020220a:	00a48c63          	beq	s1,a0,ffffffffc0202222 <vmm_init+0x1c8>
    __list_del(listelm->prev, listelm->next);
ffffffffc020220e:	6118                	ld	a4,0(a0)
ffffffffc0202210:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0202212:	1501                	addi	a0,a0,-32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0202214:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202216:	e398                	sd	a4,0(a5)
ffffffffc0202218:	456000ef          	jal	ra,ffffffffc020266e <kfree>
    return listelm->next;
ffffffffc020221c:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc020221e:	fea498e3          	bne	s1,a0,ffffffffc020220e <vmm_init+0x1b4>
    kfree(mm); // kfree mm
ffffffffc0202222:	8526                	mv	a0,s1
ffffffffc0202224:	44a000ef          	jal	ra,ffffffffc020266e <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0202228:	00003517          	auipc	a0,0x3
ffffffffc020222c:	bc050513          	addi	a0,a0,-1088 # ffffffffc0204de8 <commands+0x1040>
ffffffffc0202230:	eb1fd0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}
ffffffffc0202234:	7442                	ld	s0,48(sp)
ffffffffc0202236:	70e2                	ld	ra,56(sp)
ffffffffc0202238:	74a2                	ld	s1,40(sp)
ffffffffc020223a:	7902                	ld	s2,32(sp)
ffffffffc020223c:	69e2                	ld	s3,24(sp)
ffffffffc020223e:	6a42                	ld	s4,16(sp)
ffffffffc0202240:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202242:	00003517          	auipc	a0,0x3
ffffffffc0202246:	bc650513          	addi	a0,a0,-1082 # ffffffffc0204e08 <commands+0x1060>
}
ffffffffc020224a:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc020224c:	e95fd06f          	j	ffffffffc02000e0 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202250:	00003697          	auipc	a3,0x3
ffffffffc0202254:	a7068693          	addi	a3,a3,-1424 # ffffffffc0204cc0 <commands+0xf18>
ffffffffc0202258:	00002617          	auipc	a2,0x2
ffffffffc020225c:	4e060613          	addi	a2,a2,1248 # ffffffffc0204738 <commands+0x990>
ffffffffc0202260:	0eb00593          	li	a1,235
ffffffffc0202264:	00003517          	auipc	a0,0x3
ffffffffc0202268:	9d450513          	addi	a0,a0,-1580 # ffffffffc0204c38 <commands+0xe90>
ffffffffc020226c:	f73fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202270:	00003697          	auipc	a3,0x3
ffffffffc0202274:	ad868693          	addi	a3,a3,-1320 # ffffffffc0204d48 <commands+0xfa0>
ffffffffc0202278:	00002617          	auipc	a2,0x2
ffffffffc020227c:	4c060613          	addi	a2,a2,1216 # ffffffffc0204738 <commands+0x990>
ffffffffc0202280:	0fc00593          	li	a1,252
ffffffffc0202284:	00003517          	auipc	a0,0x3
ffffffffc0202288:	9b450513          	addi	a0,a0,-1612 # ffffffffc0204c38 <commands+0xe90>
ffffffffc020228c:	f53fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202290:	00003697          	auipc	a3,0x3
ffffffffc0202294:	ae868693          	addi	a3,a3,-1304 # ffffffffc0204d78 <commands+0xfd0>
ffffffffc0202298:	00002617          	auipc	a2,0x2
ffffffffc020229c:	4a060613          	addi	a2,a2,1184 # ffffffffc0204738 <commands+0x990>
ffffffffc02022a0:	0fd00593          	li	a1,253
ffffffffc02022a4:	00003517          	auipc	a0,0x3
ffffffffc02022a8:	99450513          	addi	a0,a0,-1644 # ffffffffc0204c38 <commands+0xe90>
ffffffffc02022ac:	f33fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02022b0:	00003697          	auipc	a3,0x3
ffffffffc02022b4:	9f868693          	addi	a3,a3,-1544 # ffffffffc0204ca8 <commands+0xf00>
ffffffffc02022b8:	00002617          	auipc	a2,0x2
ffffffffc02022bc:	48060613          	addi	a2,a2,1152 # ffffffffc0204738 <commands+0x990>
ffffffffc02022c0:	0e900593          	li	a1,233
ffffffffc02022c4:	00003517          	auipc	a0,0x3
ffffffffc02022c8:	97450513          	addi	a0,a0,-1676 # ffffffffc0204c38 <commands+0xe90>
ffffffffc02022cc:	f13fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma2 != NULL);
ffffffffc02022d0:	00003697          	auipc	a3,0x3
ffffffffc02022d4:	a3868693          	addi	a3,a3,-1480 # ffffffffc0204d08 <commands+0xf60>
ffffffffc02022d8:	00002617          	auipc	a2,0x2
ffffffffc02022dc:	46060613          	addi	a2,a2,1120 # ffffffffc0204738 <commands+0x990>
ffffffffc02022e0:	0f400593          	li	a1,244
ffffffffc02022e4:	00003517          	auipc	a0,0x3
ffffffffc02022e8:	95450513          	addi	a0,a0,-1708 # ffffffffc0204c38 <commands+0xe90>
ffffffffc02022ec:	ef3fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma1 != NULL);
ffffffffc02022f0:	00003697          	auipc	a3,0x3
ffffffffc02022f4:	a0868693          	addi	a3,a3,-1528 # ffffffffc0204cf8 <commands+0xf50>
ffffffffc02022f8:	00002617          	auipc	a2,0x2
ffffffffc02022fc:	44060613          	addi	a2,a2,1088 # ffffffffc0204738 <commands+0x990>
ffffffffc0202300:	0f200593          	li	a1,242
ffffffffc0202304:	00003517          	auipc	a0,0x3
ffffffffc0202308:	93450513          	addi	a0,a0,-1740 # ffffffffc0204c38 <commands+0xe90>
ffffffffc020230c:	ed3fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma3 == NULL);
ffffffffc0202310:	00003697          	auipc	a3,0x3
ffffffffc0202314:	a0868693          	addi	a3,a3,-1528 # ffffffffc0204d18 <commands+0xf70>
ffffffffc0202318:	00002617          	auipc	a2,0x2
ffffffffc020231c:	42060613          	addi	a2,a2,1056 # ffffffffc0204738 <commands+0x990>
ffffffffc0202320:	0f600593          	li	a1,246
ffffffffc0202324:	00003517          	auipc	a0,0x3
ffffffffc0202328:	91450513          	addi	a0,a0,-1772 # ffffffffc0204c38 <commands+0xe90>
ffffffffc020232c:	eb3fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma5 == NULL);
ffffffffc0202330:	00003697          	auipc	a3,0x3
ffffffffc0202334:	a0868693          	addi	a3,a3,-1528 # ffffffffc0204d38 <commands+0xf90>
ffffffffc0202338:	00002617          	auipc	a2,0x2
ffffffffc020233c:	40060613          	addi	a2,a2,1024 # ffffffffc0204738 <commands+0x990>
ffffffffc0202340:	0fa00593          	li	a1,250
ffffffffc0202344:	00003517          	auipc	a0,0x3
ffffffffc0202348:	8f450513          	addi	a0,a0,-1804 # ffffffffc0204c38 <commands+0xe90>
ffffffffc020234c:	e93fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma4 == NULL);
ffffffffc0202350:	00003697          	auipc	a3,0x3
ffffffffc0202354:	9d868693          	addi	a3,a3,-1576 # ffffffffc0204d28 <commands+0xf80>
ffffffffc0202358:	00002617          	auipc	a2,0x2
ffffffffc020235c:	3e060613          	addi	a2,a2,992 # ffffffffc0204738 <commands+0x990>
ffffffffc0202360:	0f800593          	li	a1,248
ffffffffc0202364:	00003517          	auipc	a0,0x3
ffffffffc0202368:	8d450513          	addi	a0,a0,-1836 # ffffffffc0204c38 <commands+0xe90>
ffffffffc020236c:	e73fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(mm != NULL);
ffffffffc0202370:	00003697          	auipc	a3,0x3
ffffffffc0202374:	ac068693          	addi	a3,a3,-1344 # ffffffffc0204e30 <commands+0x1088>
ffffffffc0202378:	00002617          	auipc	a2,0x2
ffffffffc020237c:	3c060613          	addi	a2,a2,960 # ffffffffc0204738 <commands+0x990>
ffffffffc0202380:	0d200593          	li	a1,210
ffffffffc0202384:	00003517          	auipc	a0,0x3
ffffffffc0202388:	8b450513          	addi	a0,a0,-1868 # ffffffffc0204c38 <commands+0xe90>
ffffffffc020238c:	e53fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202390 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0202390:	c94d                	beqz	a0,ffffffffc0202442 <slob_free+0xb2>
{
ffffffffc0202392:	1141                	addi	sp,sp,-16
ffffffffc0202394:	e022                	sd	s0,0(sp)
ffffffffc0202396:	e406                	sd	ra,8(sp)
ffffffffc0202398:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc020239a:	e9c1                	bnez	a1,ffffffffc020242a <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020239c:	100027f3          	csrr	a5,sstatus
ffffffffc02023a0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02023a2:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02023a4:	ebd9                	bnez	a5,ffffffffc020243a <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02023a6:	00007617          	auipc	a2,0x7
ffffffffc02023aa:	c7a60613          	addi	a2,a2,-902 # ffffffffc0209020 <slobfree>
ffffffffc02023ae:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02023b0:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02023b2:	679c                	ld	a5,8(a5)
ffffffffc02023b4:	02877a63          	bgeu	a4,s0,ffffffffc02023e8 <slob_free+0x58>
ffffffffc02023b8:	00f46463          	bltu	s0,a5,ffffffffc02023c0 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02023bc:	fef76ae3          	bltu	a4,a5,ffffffffc02023b0 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc02023c0:	400c                	lw	a1,0(s0)
ffffffffc02023c2:	00459693          	slli	a3,a1,0x4
ffffffffc02023c6:	96a2                	add	a3,a3,s0
ffffffffc02023c8:	02d78a63          	beq	a5,a3,ffffffffc02023fc <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02023cc:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc02023ce:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02023d0:	00469793          	slli	a5,a3,0x4
ffffffffc02023d4:	97ba                	add	a5,a5,a4
ffffffffc02023d6:	02f40e63          	beq	s0,a5,ffffffffc0202412 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc02023da:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc02023dc:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc02023de:	e129                	bnez	a0,ffffffffc0202420 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02023e0:	60a2                	ld	ra,8(sp)
ffffffffc02023e2:	6402                	ld	s0,0(sp)
ffffffffc02023e4:	0141                	addi	sp,sp,16
ffffffffc02023e6:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02023e8:	fcf764e3          	bltu	a4,a5,ffffffffc02023b0 <slob_free+0x20>
ffffffffc02023ec:	fcf472e3          	bgeu	s0,a5,ffffffffc02023b0 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc02023f0:	400c                	lw	a1,0(s0)
ffffffffc02023f2:	00459693          	slli	a3,a1,0x4
ffffffffc02023f6:	96a2                	add	a3,a3,s0
ffffffffc02023f8:	fcd79ae3          	bne	a5,a3,ffffffffc02023cc <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc02023fc:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02023fe:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0202400:	9db5                	addw	a1,a1,a3
ffffffffc0202402:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0202404:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0202406:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0202408:	00469793          	slli	a5,a3,0x4
ffffffffc020240c:	97ba                	add	a5,a5,a4
ffffffffc020240e:	fcf416e3          	bne	s0,a5,ffffffffc02023da <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0202412:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0202414:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0202416:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0202418:	9ebd                	addw	a3,a3,a5
ffffffffc020241a:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc020241c:	e70c                	sd	a1,8(a4)
ffffffffc020241e:	d169                	beqz	a0,ffffffffc02023e0 <slob_free+0x50>
}
ffffffffc0202420:	6402                	ld	s0,0(sp)
ffffffffc0202422:	60a2                	ld	ra,8(sp)
ffffffffc0202424:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0202426:	d0afe06f          	j	ffffffffc0200930 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc020242a:	25bd                	addiw	a1,a1,15
ffffffffc020242c:	8191                	srli	a1,a1,0x4
ffffffffc020242e:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202430:	100027f3          	csrr	a5,sstatus
ffffffffc0202434:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0202436:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202438:	d7bd                	beqz	a5,ffffffffc02023a6 <slob_free+0x16>
        intr_disable();
ffffffffc020243a:	cfcfe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        return 1;
ffffffffc020243e:	4505                	li	a0,1
ffffffffc0202440:	b79d                	j	ffffffffc02023a6 <slob_free+0x16>
ffffffffc0202442:	8082                	ret

ffffffffc0202444 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0202444:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0202446:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0202448:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020244c:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc020244e:	9d5fe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
	if (!page)
ffffffffc0202452:	c91d                	beqz	a0,ffffffffc0202488 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0202454:	0000b697          	auipc	a3,0xb
ffffffffc0202458:	0546b683          	ld	a3,84(a3) # ffffffffc020d4a8 <pages>
ffffffffc020245c:	8d15                	sub	a0,a0,a3
ffffffffc020245e:	8519                	srai	a0,a0,0x6
ffffffffc0202460:	00003697          	auipc	a3,0x3
ffffffffc0202464:	1b86b683          	ld	a3,440(a3) # ffffffffc0205618 <nbase>
ffffffffc0202468:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc020246a:	00c51793          	slli	a5,a0,0xc
ffffffffc020246e:	83b1                	srli	a5,a5,0xc
ffffffffc0202470:	0000b717          	auipc	a4,0xb
ffffffffc0202474:	03073703          	ld	a4,48(a4) # ffffffffc020d4a0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202478:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc020247a:	00e7fa63          	bgeu	a5,a4,ffffffffc020248e <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc020247e:	0000b697          	auipc	a3,0xb
ffffffffc0202482:	03a6b683          	ld	a3,58(a3) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0202486:	9536                	add	a0,a0,a3
}
ffffffffc0202488:	60a2                	ld	ra,8(sp)
ffffffffc020248a:	0141                	addi	sp,sp,16
ffffffffc020248c:	8082                	ret
ffffffffc020248e:	86aa                	mv	a3,a0
ffffffffc0202490:	00002617          	auipc	a2,0x2
ffffffffc0202494:	17860613          	addi	a2,a2,376 # ffffffffc0204608 <commands+0x860>
ffffffffc0202498:	07100593          	li	a1,113
ffffffffc020249c:	00002517          	auipc	a0,0x2
ffffffffc02024a0:	13450513          	addi	a0,a0,308 # ffffffffc02045d0 <commands+0x828>
ffffffffc02024a4:	d3bfd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc02024a8 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc02024a8:	1101                	addi	sp,sp,-32
ffffffffc02024aa:	ec06                	sd	ra,24(sp)
ffffffffc02024ac:	e822                	sd	s0,16(sp)
ffffffffc02024ae:	e426                	sd	s1,8(sp)
ffffffffc02024b0:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc02024b2:	01050713          	addi	a4,a0,16
ffffffffc02024b6:	6785                	lui	a5,0x1
ffffffffc02024b8:	0cf77363          	bgeu	a4,a5,ffffffffc020257e <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02024bc:	00f50493          	addi	s1,a0,15
ffffffffc02024c0:	8091                	srli	s1,s1,0x4
ffffffffc02024c2:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02024c4:	10002673          	csrr	a2,sstatus
ffffffffc02024c8:	8a09                	andi	a2,a2,2
ffffffffc02024ca:	e25d                	bnez	a2,ffffffffc0202570 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc02024cc:	00007917          	auipc	s2,0x7
ffffffffc02024d0:	b5490913          	addi	s2,s2,-1196 # ffffffffc0209020 <slobfree>
ffffffffc02024d4:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02024d8:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc02024da:	4398                	lw	a4,0(a5)
ffffffffc02024dc:	08975e63          	bge	a4,s1,ffffffffc0202578 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc02024e0:	00d78b63          	beq	a5,a3,ffffffffc02024f6 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02024e4:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc02024e6:	4018                	lw	a4,0(s0)
ffffffffc02024e8:	02975a63          	bge	a4,s1,ffffffffc020251c <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc02024ec:	00093683          	ld	a3,0(s2)
ffffffffc02024f0:	87a2                	mv	a5,s0
ffffffffc02024f2:	fed799e3          	bne	a5,a3,ffffffffc02024e4 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc02024f6:	ee31                	bnez	a2,ffffffffc0202552 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02024f8:	4501                	li	a0,0
ffffffffc02024fa:	f4bff0ef          	jal	ra,ffffffffc0202444 <__slob_get_free_pages.constprop.0>
ffffffffc02024fe:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0202500:	cd05                	beqz	a0,ffffffffc0202538 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0202502:	6585                	lui	a1,0x1
ffffffffc0202504:	e8dff0ef          	jal	ra,ffffffffc0202390 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202508:	10002673          	csrr	a2,sstatus
ffffffffc020250c:	8a09                	andi	a2,a2,2
ffffffffc020250e:	ee05                	bnez	a2,ffffffffc0202546 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0202510:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0202514:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0202516:	4018                	lw	a4,0(s0)
ffffffffc0202518:	fc974ae3          	blt	a4,s1,ffffffffc02024ec <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc020251c:	04e48763          	beq	s1,a4,ffffffffc020256a <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0202520:	00449693          	slli	a3,s1,0x4
ffffffffc0202524:	96a2                	add	a3,a3,s0
ffffffffc0202526:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0202528:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc020252a:	9f05                	subw	a4,a4,s1
ffffffffc020252c:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc020252e:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0202530:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0202532:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0202536:	e20d                	bnez	a2,ffffffffc0202558 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0202538:	60e2                	ld	ra,24(sp)
ffffffffc020253a:	8522                	mv	a0,s0
ffffffffc020253c:	6442                	ld	s0,16(sp)
ffffffffc020253e:	64a2                	ld	s1,8(sp)
ffffffffc0202540:	6902                	ld	s2,0(sp)
ffffffffc0202542:	6105                	addi	sp,sp,32
ffffffffc0202544:	8082                	ret
        intr_disable();
ffffffffc0202546:	bf0fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
			cur = slobfree;
ffffffffc020254a:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc020254e:	4605                	li	a2,1
ffffffffc0202550:	b7d1                	j	ffffffffc0202514 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0202552:	bdefe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0202556:	b74d                	j	ffffffffc02024f8 <slob_alloc.constprop.0+0x50>
ffffffffc0202558:	bd8fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
}
ffffffffc020255c:	60e2                	ld	ra,24(sp)
ffffffffc020255e:	8522                	mv	a0,s0
ffffffffc0202560:	6442                	ld	s0,16(sp)
ffffffffc0202562:	64a2                	ld	s1,8(sp)
ffffffffc0202564:	6902                	ld	s2,0(sp)
ffffffffc0202566:	6105                	addi	sp,sp,32
ffffffffc0202568:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc020256a:	6418                	ld	a4,8(s0)
ffffffffc020256c:	e798                	sd	a4,8(a5)
ffffffffc020256e:	b7d1                	j	ffffffffc0202532 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0202570:	bc6fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        return 1;
ffffffffc0202574:	4605                	li	a2,1
ffffffffc0202576:	bf99                	j	ffffffffc02024cc <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0202578:	843e                	mv	s0,a5
ffffffffc020257a:	87b6                	mv	a5,a3
ffffffffc020257c:	b745                	j	ffffffffc020251c <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc020257e:	00003697          	auipc	a3,0x3
ffffffffc0202582:	8c268693          	addi	a3,a3,-1854 # ffffffffc0204e40 <commands+0x1098>
ffffffffc0202586:	00002617          	auipc	a2,0x2
ffffffffc020258a:	1b260613          	addi	a2,a2,434 # ffffffffc0204738 <commands+0x990>
ffffffffc020258e:	06300593          	li	a1,99
ffffffffc0202592:	00003517          	auipc	a0,0x3
ffffffffc0202596:	8ce50513          	addi	a0,a0,-1842 # ffffffffc0204e60 <commands+0x10b8>
ffffffffc020259a:	c45fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc020259e <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc020259e:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc02025a0:	00003517          	auipc	a0,0x3
ffffffffc02025a4:	8d850513          	addi	a0,a0,-1832 # ffffffffc0204e78 <commands+0x10d0>
{
ffffffffc02025a8:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc02025aa:	b37fd0ef          	jal	ra,ffffffffc02000e0 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc02025ae:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc02025b0:	00003517          	auipc	a0,0x3
ffffffffc02025b4:	8e050513          	addi	a0,a0,-1824 # ffffffffc0204e90 <commands+0x10e8>
}
ffffffffc02025b8:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc02025ba:	b27fd06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc02025be <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc02025be:	1101                	addi	sp,sp,-32
ffffffffc02025c0:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc02025c2:	6905                	lui	s2,0x1
{
ffffffffc02025c4:	e822                	sd	s0,16(sp)
ffffffffc02025c6:	ec06                	sd	ra,24(sp)
ffffffffc02025c8:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc02025ca:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc02025ce:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc02025d0:	04a7f963          	bgeu	a5,a0,ffffffffc0202622 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc02025d4:	4561                	li	a0,24
ffffffffc02025d6:	ed3ff0ef          	jal	ra,ffffffffc02024a8 <slob_alloc.constprop.0>
ffffffffc02025da:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc02025dc:	c929                	beqz	a0,ffffffffc020262e <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc02025de:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc02025e2:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc02025e4:	00f95763          	bge	s2,a5,ffffffffc02025f2 <kmalloc+0x34>
ffffffffc02025e8:	6705                	lui	a4,0x1
ffffffffc02025ea:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc02025ec:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc02025ee:	fef74ee3          	blt	a4,a5,ffffffffc02025ea <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc02025f2:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc02025f4:	e51ff0ef          	jal	ra,ffffffffc0202444 <__slob_get_free_pages.constprop.0>
ffffffffc02025f8:	e488                	sd	a0,8(s1)
ffffffffc02025fa:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc02025fc:	c525                	beqz	a0,ffffffffc0202664 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02025fe:	100027f3          	csrr	a5,sstatus
ffffffffc0202602:	8b89                	andi	a5,a5,2
ffffffffc0202604:	ef8d                	bnez	a5,ffffffffc020263e <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0202606:	0000b797          	auipc	a5,0xb
ffffffffc020260a:	eba78793          	addi	a5,a5,-326 # ffffffffc020d4c0 <bigblocks>
ffffffffc020260e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0202610:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0202612:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0202614:	60e2                	ld	ra,24(sp)
ffffffffc0202616:	8522                	mv	a0,s0
ffffffffc0202618:	6442                	ld	s0,16(sp)
ffffffffc020261a:	64a2                	ld	s1,8(sp)
ffffffffc020261c:	6902                	ld	s2,0(sp)
ffffffffc020261e:	6105                	addi	sp,sp,32
ffffffffc0202620:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0202622:	0541                	addi	a0,a0,16
ffffffffc0202624:	e85ff0ef          	jal	ra,ffffffffc02024a8 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0202628:	01050413          	addi	s0,a0,16
ffffffffc020262c:	f565                	bnez	a0,ffffffffc0202614 <kmalloc+0x56>
ffffffffc020262e:	4401                	li	s0,0
}
ffffffffc0202630:	60e2                	ld	ra,24(sp)
ffffffffc0202632:	8522                	mv	a0,s0
ffffffffc0202634:	6442                	ld	s0,16(sp)
ffffffffc0202636:	64a2                	ld	s1,8(sp)
ffffffffc0202638:	6902                	ld	s2,0(sp)
ffffffffc020263a:	6105                	addi	sp,sp,32
ffffffffc020263c:	8082                	ret
        intr_disable();
ffffffffc020263e:	af8fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
		bb->next = bigblocks;
ffffffffc0202642:	0000b797          	auipc	a5,0xb
ffffffffc0202646:	e7e78793          	addi	a5,a5,-386 # ffffffffc020d4c0 <bigblocks>
ffffffffc020264a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc020264c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc020264e:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0202650:	ae0fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
		return bb->pages;
ffffffffc0202654:	6480                	ld	s0,8(s1)
}
ffffffffc0202656:	60e2                	ld	ra,24(sp)
ffffffffc0202658:	64a2                	ld	s1,8(sp)
ffffffffc020265a:	8522                	mv	a0,s0
ffffffffc020265c:	6442                	ld	s0,16(sp)
ffffffffc020265e:	6902                	ld	s2,0(sp)
ffffffffc0202660:	6105                	addi	sp,sp,32
ffffffffc0202662:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0202664:	45e1                	li	a1,24
ffffffffc0202666:	8526                	mv	a0,s1
ffffffffc0202668:	d29ff0ef          	jal	ra,ffffffffc0202390 <slob_free>
	return __kmalloc(size, 0);
ffffffffc020266c:	b765                	j	ffffffffc0202614 <kmalloc+0x56>

ffffffffc020266e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc020266e:	c179                	beqz	a0,ffffffffc0202734 <kfree+0xc6>
{
ffffffffc0202670:	1101                	addi	sp,sp,-32
ffffffffc0202672:	e822                	sd	s0,16(sp)
ffffffffc0202674:	ec06                	sd	ra,24(sp)
ffffffffc0202676:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0202678:	03451793          	slli	a5,a0,0x34
ffffffffc020267c:	842a                	mv	s0,a0
ffffffffc020267e:	e7c1                	bnez	a5,ffffffffc0202706 <kfree+0x98>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202680:	100027f3          	csrr	a5,sstatus
ffffffffc0202684:	8b89                	andi	a5,a5,2
ffffffffc0202686:	ebc9                	bnez	a5,ffffffffc0202718 <kfree+0xaa>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0202688:	0000b797          	auipc	a5,0xb
ffffffffc020268c:	e387b783          	ld	a5,-456(a5) # ffffffffc020d4c0 <bigblocks>
    return 0;
ffffffffc0202690:	4601                	li	a2,0
ffffffffc0202692:	cbb5                	beqz	a5,ffffffffc0202706 <kfree+0x98>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0202694:	0000b697          	auipc	a3,0xb
ffffffffc0202698:	e2c68693          	addi	a3,a3,-468 # ffffffffc020d4c0 <bigblocks>
ffffffffc020269c:	a021                	j	ffffffffc02026a4 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc020269e:	01048693          	addi	a3,s1,16
ffffffffc02026a2:	c3ad                	beqz	a5,ffffffffc0202704 <kfree+0x96>
		{
			if (bb->pages == block)
ffffffffc02026a4:	6798                	ld	a4,8(a5)
ffffffffc02026a6:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc02026a8:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc02026aa:	fe871ae3          	bne	a4,s0,ffffffffc020269e <kfree+0x30>
				*last = bb->next;
ffffffffc02026ae:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc02026b0:	ee3d                	bnez	a2,ffffffffc020272e <kfree+0xc0>
    return pa2page(PADDR(kva));
ffffffffc02026b2:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc02026b6:	4098                	lw	a4,0(s1)
ffffffffc02026b8:	08f46b63          	bltu	s0,a5,ffffffffc020274e <kfree+0xe0>
ffffffffc02026bc:	0000b697          	auipc	a3,0xb
ffffffffc02026c0:	dfc6b683          	ld	a3,-516(a3) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc02026c4:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc02026c6:	8031                	srli	s0,s0,0xc
ffffffffc02026c8:	0000b797          	auipc	a5,0xb
ffffffffc02026cc:	dd87b783          	ld	a5,-552(a5) # ffffffffc020d4a0 <npage>
ffffffffc02026d0:	06f47363          	bgeu	s0,a5,ffffffffc0202736 <kfree+0xc8>
    return &pages[PPN(pa) - nbase];
ffffffffc02026d4:	00003517          	auipc	a0,0x3
ffffffffc02026d8:	f4453503          	ld	a0,-188(a0) # ffffffffc0205618 <nbase>
ffffffffc02026dc:	8c09                	sub	s0,s0,a0
ffffffffc02026de:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc02026e0:	0000b517          	auipc	a0,0xb
ffffffffc02026e4:	dc853503          	ld	a0,-568(a0) # ffffffffc020d4a8 <pages>
ffffffffc02026e8:	4585                	li	a1,1
ffffffffc02026ea:	9522                	add	a0,a0,s0
ffffffffc02026ec:	00e595bb          	sllw	a1,a1,a4
ffffffffc02026f0:	f70fe0ef          	jal	ra,ffffffffc0200e60 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc02026f4:	6442                	ld	s0,16(sp)
ffffffffc02026f6:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc02026f8:	8526                	mv	a0,s1
}
ffffffffc02026fa:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc02026fc:	45e1                	li	a1,24
}
ffffffffc02026fe:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202700:	c91ff06f          	j	ffffffffc0202390 <slob_free>
ffffffffc0202704:	e215                	bnez	a2,ffffffffc0202728 <kfree+0xba>
ffffffffc0202706:	ff040513          	addi	a0,s0,-16
}
ffffffffc020270a:	6442                	ld	s0,16(sp)
ffffffffc020270c:	60e2                	ld	ra,24(sp)
ffffffffc020270e:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202710:	4581                	li	a1,0
}
ffffffffc0202712:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202714:	c7dff06f          	j	ffffffffc0202390 <slob_free>
        intr_disable();
ffffffffc0202718:	a1efe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc020271c:	0000b797          	auipc	a5,0xb
ffffffffc0202720:	da47b783          	ld	a5,-604(a5) # ffffffffc020d4c0 <bigblocks>
        return 1;
ffffffffc0202724:	4605                	li	a2,1
ffffffffc0202726:	f7bd                	bnez	a5,ffffffffc0202694 <kfree+0x26>
        intr_enable();
ffffffffc0202728:	a08fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc020272c:	bfe9                	j	ffffffffc0202706 <kfree+0x98>
ffffffffc020272e:	a02fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0202732:	b741                	j	ffffffffc02026b2 <kfree+0x44>
ffffffffc0202734:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0202736:	00002617          	auipc	a2,0x2
ffffffffc020273a:	e7a60613          	addi	a2,a2,-390 # ffffffffc02045b0 <commands+0x808>
ffffffffc020273e:	06900593          	li	a1,105
ffffffffc0202742:	00002517          	auipc	a0,0x2
ffffffffc0202746:	e8e50513          	addi	a0,a0,-370 # ffffffffc02045d0 <commands+0x828>
ffffffffc020274a:	a95fd0ef          	jal	ra,ffffffffc02001de <__panic>
    return pa2page(PADDR(kva));
ffffffffc020274e:	86a2                	mv	a3,s0
ffffffffc0202750:	00002617          	auipc	a2,0x2
ffffffffc0202754:	f6860613          	addi	a2,a2,-152 # ffffffffc02046b8 <commands+0x910>
ffffffffc0202758:	07700593          	li	a1,119
ffffffffc020275c:	00002517          	auipc	a0,0x2
ffffffffc0202760:	e7450513          	addi	a0,a0,-396 # ffffffffc02045d0 <commands+0x828>
ffffffffc0202764:	a7bfd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202768 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc0202768:	00007797          	auipc	a5,0x7
ffffffffc020276c:	cc078793          	addi	a5,a5,-832 # ffffffffc0209428 <free_area>
ffffffffc0202770:	e79c                	sd	a5,8(a5)
ffffffffc0202772:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0202774:	0007a823          	sw	zero,16(a5)
}
ffffffffc0202778:	8082                	ret

ffffffffc020277a <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc020277a:	00007517          	auipc	a0,0x7
ffffffffc020277e:	cbe56503          	lwu	a0,-834(a0) # ffffffffc0209438 <free_area+0x10>
ffffffffc0202782:	8082                	ret

ffffffffc0202784 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0202784:	715d                	addi	sp,sp,-80
ffffffffc0202786:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0202788:	00007417          	auipc	s0,0x7
ffffffffc020278c:	ca040413          	addi	s0,s0,-864 # ffffffffc0209428 <free_area>
ffffffffc0202790:	641c                	ld	a5,8(s0)
ffffffffc0202792:	e486                	sd	ra,72(sp)
ffffffffc0202794:	fc26                	sd	s1,56(sp)
ffffffffc0202796:	f84a                	sd	s2,48(sp)
ffffffffc0202798:	f44e                	sd	s3,40(sp)
ffffffffc020279a:	f052                	sd	s4,32(sp)
ffffffffc020279c:	ec56                	sd	s5,24(sp)
ffffffffc020279e:	e85a                	sd	s6,16(sp)
ffffffffc02027a0:	e45e                	sd	s7,8(sp)
ffffffffc02027a2:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02027a4:	2a878d63          	beq	a5,s0,ffffffffc0202a5e <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc02027a8:	4481                	li	s1,0
ffffffffc02027aa:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02027ac:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02027b0:	8b09                	andi	a4,a4,2
ffffffffc02027b2:	2a070a63          	beqz	a4,ffffffffc0202a66 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc02027b6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02027ba:	679c                	ld	a5,8(a5)
ffffffffc02027bc:	2905                	addiw	s2,s2,1
ffffffffc02027be:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02027c0:	fe8796e3          	bne	a5,s0,ffffffffc02027ac <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02027c4:	89a6                	mv	s3,s1
ffffffffc02027c6:	ed8fe0ef          	jal	ra,ffffffffc0200e9e <nr_free_pages>
ffffffffc02027ca:	6f351e63          	bne	a0,s3,ffffffffc0202ec6 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02027ce:	4505                	li	a0,1
ffffffffc02027d0:	e52fe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc02027d4:	8aaa                	mv	s5,a0
ffffffffc02027d6:	42050863          	beqz	a0,ffffffffc0202c06 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02027da:	4505                	li	a0,1
ffffffffc02027dc:	e46fe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc02027e0:	89aa                	mv	s3,a0
ffffffffc02027e2:	70050263          	beqz	a0,ffffffffc0202ee6 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02027e6:	4505                	li	a0,1
ffffffffc02027e8:	e3afe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc02027ec:	8a2a                	mv	s4,a0
ffffffffc02027ee:	48050c63          	beqz	a0,ffffffffc0202c86 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02027f2:	293a8a63          	beq	s5,s3,ffffffffc0202a86 <default_check+0x302>
ffffffffc02027f6:	28aa8863          	beq	s5,a0,ffffffffc0202a86 <default_check+0x302>
ffffffffc02027fa:	28a98663          	beq	s3,a0,ffffffffc0202a86 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02027fe:	000aa783          	lw	a5,0(s5)
ffffffffc0202802:	2a079263          	bnez	a5,ffffffffc0202aa6 <default_check+0x322>
ffffffffc0202806:	0009a783          	lw	a5,0(s3)
ffffffffc020280a:	28079e63          	bnez	a5,ffffffffc0202aa6 <default_check+0x322>
ffffffffc020280e:	411c                	lw	a5,0(a0)
ffffffffc0202810:	28079b63          	bnez	a5,ffffffffc0202aa6 <default_check+0x322>
    return page - pages + nbase;
ffffffffc0202814:	0000b797          	auipc	a5,0xb
ffffffffc0202818:	c947b783          	ld	a5,-876(a5) # ffffffffc020d4a8 <pages>
ffffffffc020281c:	40fa8733          	sub	a4,s5,a5
ffffffffc0202820:	00003617          	auipc	a2,0x3
ffffffffc0202824:	df863603          	ld	a2,-520(a2) # ffffffffc0205618 <nbase>
ffffffffc0202828:	8719                	srai	a4,a4,0x6
ffffffffc020282a:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020282c:	0000b697          	auipc	a3,0xb
ffffffffc0202830:	c746b683          	ld	a3,-908(a3) # ffffffffc020d4a0 <npage>
ffffffffc0202834:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202836:	0732                	slli	a4,a4,0xc
ffffffffc0202838:	28d77763          	bgeu	a4,a3,ffffffffc0202ac6 <default_check+0x342>
    return page - pages + nbase;
ffffffffc020283c:	40f98733          	sub	a4,s3,a5
ffffffffc0202840:	8719                	srai	a4,a4,0x6
ffffffffc0202842:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202844:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0202846:	4cd77063          	bgeu	a4,a3,ffffffffc0202d06 <default_check+0x582>
    return page - pages + nbase;
ffffffffc020284a:	40f507b3          	sub	a5,a0,a5
ffffffffc020284e:	8799                	srai	a5,a5,0x6
ffffffffc0202850:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202852:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0202854:	30d7f963          	bgeu	a5,a3,ffffffffc0202b66 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0202858:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020285a:	00043c03          	ld	s8,0(s0)
ffffffffc020285e:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0202862:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0202866:	e400                	sd	s0,8(s0)
ffffffffc0202868:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc020286a:	00007797          	auipc	a5,0x7
ffffffffc020286e:	bc07a723          	sw	zero,-1074(a5) # ffffffffc0209438 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0202872:	db0fe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc0202876:	2c051863          	bnez	a0,ffffffffc0202b46 <default_check+0x3c2>
    free_page(p0);
ffffffffc020287a:	4585                	li	a1,1
ffffffffc020287c:	8556                	mv	a0,s5
ffffffffc020287e:	de2fe0ef          	jal	ra,ffffffffc0200e60 <free_pages>
    free_page(p1);
ffffffffc0202882:	4585                	li	a1,1
ffffffffc0202884:	854e                	mv	a0,s3
ffffffffc0202886:	ddafe0ef          	jal	ra,ffffffffc0200e60 <free_pages>
    free_page(p2);
ffffffffc020288a:	4585                	li	a1,1
ffffffffc020288c:	8552                	mv	a0,s4
ffffffffc020288e:	dd2fe0ef          	jal	ra,ffffffffc0200e60 <free_pages>
    assert(nr_free == 3);
ffffffffc0202892:	4818                	lw	a4,16(s0)
ffffffffc0202894:	478d                	li	a5,3
ffffffffc0202896:	28f71863          	bne	a4,a5,ffffffffc0202b26 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020289a:	4505                	li	a0,1
ffffffffc020289c:	d86fe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc02028a0:	89aa                	mv	s3,a0
ffffffffc02028a2:	26050263          	beqz	a0,ffffffffc0202b06 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02028a6:	4505                	li	a0,1
ffffffffc02028a8:	d7afe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc02028ac:	8aaa                	mv	s5,a0
ffffffffc02028ae:	3a050c63          	beqz	a0,ffffffffc0202c66 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02028b2:	4505                	li	a0,1
ffffffffc02028b4:	d6efe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc02028b8:	8a2a                	mv	s4,a0
ffffffffc02028ba:	38050663          	beqz	a0,ffffffffc0202c46 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc02028be:	4505                	li	a0,1
ffffffffc02028c0:	d62fe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc02028c4:	36051163          	bnez	a0,ffffffffc0202c26 <default_check+0x4a2>
    free_page(p0);
ffffffffc02028c8:	4585                	li	a1,1
ffffffffc02028ca:	854e                	mv	a0,s3
ffffffffc02028cc:	d94fe0ef          	jal	ra,ffffffffc0200e60 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02028d0:	641c                	ld	a5,8(s0)
ffffffffc02028d2:	20878a63          	beq	a5,s0,ffffffffc0202ae6 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc02028d6:	4505                	li	a0,1
ffffffffc02028d8:	d4afe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc02028dc:	30a99563          	bne	s3,a0,ffffffffc0202be6 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc02028e0:	4505                	li	a0,1
ffffffffc02028e2:	d40fe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc02028e6:	2e051063          	bnez	a0,ffffffffc0202bc6 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc02028ea:	481c                	lw	a5,16(s0)
ffffffffc02028ec:	2a079d63          	bnez	a5,ffffffffc0202ba6 <default_check+0x422>
    free_page(p);
ffffffffc02028f0:	854e                	mv	a0,s3
ffffffffc02028f2:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02028f4:	01843023          	sd	s8,0(s0)
ffffffffc02028f8:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02028fc:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0202900:	d60fe0ef          	jal	ra,ffffffffc0200e60 <free_pages>
    free_page(p1);
ffffffffc0202904:	4585                	li	a1,1
ffffffffc0202906:	8556                	mv	a0,s5
ffffffffc0202908:	d58fe0ef          	jal	ra,ffffffffc0200e60 <free_pages>
    free_page(p2);
ffffffffc020290c:	4585                	li	a1,1
ffffffffc020290e:	8552                	mv	a0,s4
ffffffffc0202910:	d50fe0ef          	jal	ra,ffffffffc0200e60 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0202914:	4515                	li	a0,5
ffffffffc0202916:	d0cfe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc020291a:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020291c:	26050563          	beqz	a0,ffffffffc0202b86 <default_check+0x402>
ffffffffc0202920:	651c                	ld	a5,8(a0)
ffffffffc0202922:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0202924:	8b85                	andi	a5,a5,1
ffffffffc0202926:	54079063          	bnez	a5,ffffffffc0202e66 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020292a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020292c:	00043b03          	ld	s6,0(s0)
ffffffffc0202930:	00843a83          	ld	s5,8(s0)
ffffffffc0202934:	e000                	sd	s0,0(s0)
ffffffffc0202936:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0202938:	ceafe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc020293c:	50051563          	bnez	a0,ffffffffc0202e46 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0202940:	08098a13          	addi	s4,s3,128
ffffffffc0202944:	8552                	mv	a0,s4
ffffffffc0202946:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0202948:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc020294c:	00007797          	auipc	a5,0x7
ffffffffc0202950:	ae07a623          	sw	zero,-1300(a5) # ffffffffc0209438 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0202954:	d0cfe0ef          	jal	ra,ffffffffc0200e60 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0202958:	4511                	li	a0,4
ffffffffc020295a:	cc8fe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc020295e:	4c051463          	bnez	a0,ffffffffc0202e26 <default_check+0x6a2>
ffffffffc0202962:	0889b783          	ld	a5,136(s3)
ffffffffc0202966:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0202968:	8b85                	andi	a5,a5,1
ffffffffc020296a:	48078e63          	beqz	a5,ffffffffc0202e06 <default_check+0x682>
ffffffffc020296e:	0909a703          	lw	a4,144(s3)
ffffffffc0202972:	478d                	li	a5,3
ffffffffc0202974:	48f71963          	bne	a4,a5,ffffffffc0202e06 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0202978:	450d                	li	a0,3
ffffffffc020297a:	ca8fe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc020297e:	8c2a                	mv	s8,a0
ffffffffc0202980:	46050363          	beqz	a0,ffffffffc0202de6 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0202984:	4505                	li	a0,1
ffffffffc0202986:	c9cfe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc020298a:	42051e63          	bnez	a0,ffffffffc0202dc6 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc020298e:	418a1c63          	bne	s4,s8,ffffffffc0202da6 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0202992:	4585                	li	a1,1
ffffffffc0202994:	854e                	mv	a0,s3
ffffffffc0202996:	ccafe0ef          	jal	ra,ffffffffc0200e60 <free_pages>
    free_pages(p1, 3);
ffffffffc020299a:	458d                	li	a1,3
ffffffffc020299c:	8552                	mv	a0,s4
ffffffffc020299e:	cc2fe0ef          	jal	ra,ffffffffc0200e60 <free_pages>
ffffffffc02029a2:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02029a6:	04098c13          	addi	s8,s3,64
ffffffffc02029aa:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02029ac:	8b85                	andi	a5,a5,1
ffffffffc02029ae:	3c078c63          	beqz	a5,ffffffffc0202d86 <default_check+0x602>
ffffffffc02029b2:	0109a703          	lw	a4,16(s3)
ffffffffc02029b6:	4785                	li	a5,1
ffffffffc02029b8:	3cf71763          	bne	a4,a5,ffffffffc0202d86 <default_check+0x602>
ffffffffc02029bc:	008a3783          	ld	a5,8(s4)
ffffffffc02029c0:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02029c2:	8b85                	andi	a5,a5,1
ffffffffc02029c4:	3a078163          	beqz	a5,ffffffffc0202d66 <default_check+0x5e2>
ffffffffc02029c8:	010a2703          	lw	a4,16(s4)
ffffffffc02029cc:	478d                	li	a5,3
ffffffffc02029ce:	38f71c63          	bne	a4,a5,ffffffffc0202d66 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02029d2:	4505                	li	a0,1
ffffffffc02029d4:	c4efe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc02029d8:	36a99763          	bne	s3,a0,ffffffffc0202d46 <default_check+0x5c2>
    free_page(p0);
ffffffffc02029dc:	4585                	li	a1,1
ffffffffc02029de:	c82fe0ef          	jal	ra,ffffffffc0200e60 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02029e2:	4509                	li	a0,2
ffffffffc02029e4:	c3efe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc02029e8:	32aa1f63          	bne	s4,a0,ffffffffc0202d26 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc02029ec:	4589                	li	a1,2
ffffffffc02029ee:	c72fe0ef          	jal	ra,ffffffffc0200e60 <free_pages>
    free_page(p2);
ffffffffc02029f2:	4585                	li	a1,1
ffffffffc02029f4:	8562                	mv	a0,s8
ffffffffc02029f6:	c6afe0ef          	jal	ra,ffffffffc0200e60 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02029fa:	4515                	li	a0,5
ffffffffc02029fc:	c26fe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc0202a00:	89aa                	mv	s3,a0
ffffffffc0202a02:	48050263          	beqz	a0,ffffffffc0202e86 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0202a06:	4505                	li	a0,1
ffffffffc0202a08:	c1afe0ef          	jal	ra,ffffffffc0200e22 <alloc_pages>
ffffffffc0202a0c:	2c051d63          	bnez	a0,ffffffffc0202ce6 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0202a10:	481c                	lw	a5,16(s0)
ffffffffc0202a12:	2a079a63          	bnez	a5,ffffffffc0202cc6 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0202a16:	4595                	li	a1,5
ffffffffc0202a18:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0202a1a:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0202a1e:	01643023          	sd	s6,0(s0)
ffffffffc0202a22:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0202a26:	c3afe0ef          	jal	ra,ffffffffc0200e60 <free_pages>
    return listelm->next;
ffffffffc0202a2a:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202a2c:	00878963          	beq	a5,s0,ffffffffc0202a3e <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0202a30:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202a34:	679c                	ld	a5,8(a5)
ffffffffc0202a36:	397d                	addiw	s2,s2,-1
ffffffffc0202a38:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202a3a:	fe879be3          	bne	a5,s0,ffffffffc0202a30 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0202a3e:	26091463          	bnez	s2,ffffffffc0202ca6 <default_check+0x522>
    assert(total == 0);
ffffffffc0202a42:	46049263          	bnez	s1,ffffffffc0202ea6 <default_check+0x722>
}
ffffffffc0202a46:	60a6                	ld	ra,72(sp)
ffffffffc0202a48:	6406                	ld	s0,64(sp)
ffffffffc0202a4a:	74e2                	ld	s1,56(sp)
ffffffffc0202a4c:	7942                	ld	s2,48(sp)
ffffffffc0202a4e:	79a2                	ld	s3,40(sp)
ffffffffc0202a50:	7a02                	ld	s4,32(sp)
ffffffffc0202a52:	6ae2                	ld	s5,24(sp)
ffffffffc0202a54:	6b42                	ld	s6,16(sp)
ffffffffc0202a56:	6ba2                	ld	s7,8(sp)
ffffffffc0202a58:	6c02                	ld	s8,0(sp)
ffffffffc0202a5a:	6161                	addi	sp,sp,80
ffffffffc0202a5c:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202a5e:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0202a60:	4481                	li	s1,0
ffffffffc0202a62:	4901                	li	s2,0
ffffffffc0202a64:	b38d                	j	ffffffffc02027c6 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0202a66:	00002697          	auipc	a3,0x2
ffffffffc0202a6a:	44a68693          	addi	a3,a3,1098 # ffffffffc0204eb0 <commands+0x1108>
ffffffffc0202a6e:	00002617          	auipc	a2,0x2
ffffffffc0202a72:	cca60613          	addi	a2,a2,-822 # ffffffffc0204738 <commands+0x990>
ffffffffc0202a76:	0f000593          	li	a1,240
ffffffffc0202a7a:	00002517          	auipc	a0,0x2
ffffffffc0202a7e:	44650513          	addi	a0,a0,1094 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202a82:	f5cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0202a86:	00002697          	auipc	a3,0x2
ffffffffc0202a8a:	4d268693          	addi	a3,a3,1234 # ffffffffc0204f58 <commands+0x11b0>
ffffffffc0202a8e:	00002617          	auipc	a2,0x2
ffffffffc0202a92:	caa60613          	addi	a2,a2,-854 # ffffffffc0204738 <commands+0x990>
ffffffffc0202a96:	0bd00593          	li	a1,189
ffffffffc0202a9a:	00002517          	auipc	a0,0x2
ffffffffc0202a9e:	42650513          	addi	a0,a0,1062 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202aa2:	f3cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0202aa6:	00002697          	auipc	a3,0x2
ffffffffc0202aaa:	4da68693          	addi	a3,a3,1242 # ffffffffc0204f80 <commands+0x11d8>
ffffffffc0202aae:	00002617          	auipc	a2,0x2
ffffffffc0202ab2:	c8a60613          	addi	a2,a2,-886 # ffffffffc0204738 <commands+0x990>
ffffffffc0202ab6:	0be00593          	li	a1,190
ffffffffc0202aba:	00002517          	auipc	a0,0x2
ffffffffc0202abe:	40650513          	addi	a0,a0,1030 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202ac2:	f1cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0202ac6:	00002697          	auipc	a3,0x2
ffffffffc0202aca:	4fa68693          	addi	a3,a3,1274 # ffffffffc0204fc0 <commands+0x1218>
ffffffffc0202ace:	00002617          	auipc	a2,0x2
ffffffffc0202ad2:	c6a60613          	addi	a2,a2,-918 # ffffffffc0204738 <commands+0x990>
ffffffffc0202ad6:	0c000593          	li	a1,192
ffffffffc0202ada:	00002517          	auipc	a0,0x2
ffffffffc0202ade:	3e650513          	addi	a0,a0,998 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202ae2:	efcfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(!list_empty(&free_list));
ffffffffc0202ae6:	00002697          	auipc	a3,0x2
ffffffffc0202aea:	56268693          	addi	a3,a3,1378 # ffffffffc0205048 <commands+0x12a0>
ffffffffc0202aee:	00002617          	auipc	a2,0x2
ffffffffc0202af2:	c4a60613          	addi	a2,a2,-950 # ffffffffc0204738 <commands+0x990>
ffffffffc0202af6:	0d900593          	li	a1,217
ffffffffc0202afa:	00002517          	auipc	a0,0x2
ffffffffc0202afe:	3c650513          	addi	a0,a0,966 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202b02:	edcfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202b06:	00002697          	auipc	a3,0x2
ffffffffc0202b0a:	3f268693          	addi	a3,a3,1010 # ffffffffc0204ef8 <commands+0x1150>
ffffffffc0202b0e:	00002617          	auipc	a2,0x2
ffffffffc0202b12:	c2a60613          	addi	a2,a2,-982 # ffffffffc0204738 <commands+0x990>
ffffffffc0202b16:	0d200593          	li	a1,210
ffffffffc0202b1a:	00002517          	auipc	a0,0x2
ffffffffc0202b1e:	3a650513          	addi	a0,a0,934 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202b22:	ebcfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free == 3);
ffffffffc0202b26:	00002697          	auipc	a3,0x2
ffffffffc0202b2a:	51268693          	addi	a3,a3,1298 # ffffffffc0205038 <commands+0x1290>
ffffffffc0202b2e:	00002617          	auipc	a2,0x2
ffffffffc0202b32:	c0a60613          	addi	a2,a2,-1014 # ffffffffc0204738 <commands+0x990>
ffffffffc0202b36:	0d000593          	li	a1,208
ffffffffc0202b3a:	00002517          	auipc	a0,0x2
ffffffffc0202b3e:	38650513          	addi	a0,a0,902 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202b42:	e9cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202b46:	00002697          	auipc	a3,0x2
ffffffffc0202b4a:	4da68693          	addi	a3,a3,1242 # ffffffffc0205020 <commands+0x1278>
ffffffffc0202b4e:	00002617          	auipc	a2,0x2
ffffffffc0202b52:	bea60613          	addi	a2,a2,-1046 # ffffffffc0204738 <commands+0x990>
ffffffffc0202b56:	0cb00593          	li	a1,203
ffffffffc0202b5a:	00002517          	auipc	a0,0x2
ffffffffc0202b5e:	36650513          	addi	a0,a0,870 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202b62:	e7cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0202b66:	00002697          	auipc	a3,0x2
ffffffffc0202b6a:	49a68693          	addi	a3,a3,1178 # ffffffffc0205000 <commands+0x1258>
ffffffffc0202b6e:	00002617          	auipc	a2,0x2
ffffffffc0202b72:	bca60613          	addi	a2,a2,-1078 # ffffffffc0204738 <commands+0x990>
ffffffffc0202b76:	0c200593          	li	a1,194
ffffffffc0202b7a:	00002517          	auipc	a0,0x2
ffffffffc0202b7e:	34650513          	addi	a0,a0,838 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202b82:	e5cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(p0 != NULL);
ffffffffc0202b86:	00002697          	auipc	a3,0x2
ffffffffc0202b8a:	50a68693          	addi	a3,a3,1290 # ffffffffc0205090 <commands+0x12e8>
ffffffffc0202b8e:	00002617          	auipc	a2,0x2
ffffffffc0202b92:	baa60613          	addi	a2,a2,-1110 # ffffffffc0204738 <commands+0x990>
ffffffffc0202b96:	0f800593          	li	a1,248
ffffffffc0202b9a:	00002517          	auipc	a0,0x2
ffffffffc0202b9e:	32650513          	addi	a0,a0,806 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202ba2:	e3cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free == 0);
ffffffffc0202ba6:	00002697          	auipc	a3,0x2
ffffffffc0202baa:	4da68693          	addi	a3,a3,1242 # ffffffffc0205080 <commands+0x12d8>
ffffffffc0202bae:	00002617          	auipc	a2,0x2
ffffffffc0202bb2:	b8a60613          	addi	a2,a2,-1142 # ffffffffc0204738 <commands+0x990>
ffffffffc0202bb6:	0df00593          	li	a1,223
ffffffffc0202bba:	00002517          	auipc	a0,0x2
ffffffffc0202bbe:	30650513          	addi	a0,a0,774 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202bc2:	e1cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202bc6:	00002697          	auipc	a3,0x2
ffffffffc0202bca:	45a68693          	addi	a3,a3,1114 # ffffffffc0205020 <commands+0x1278>
ffffffffc0202bce:	00002617          	auipc	a2,0x2
ffffffffc0202bd2:	b6a60613          	addi	a2,a2,-1174 # ffffffffc0204738 <commands+0x990>
ffffffffc0202bd6:	0dd00593          	li	a1,221
ffffffffc0202bda:	00002517          	auipc	a0,0x2
ffffffffc0202bde:	2e650513          	addi	a0,a0,742 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202be2:	dfcfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0202be6:	00002697          	auipc	a3,0x2
ffffffffc0202bea:	47a68693          	addi	a3,a3,1146 # ffffffffc0205060 <commands+0x12b8>
ffffffffc0202bee:	00002617          	auipc	a2,0x2
ffffffffc0202bf2:	b4a60613          	addi	a2,a2,-1206 # ffffffffc0204738 <commands+0x990>
ffffffffc0202bf6:	0dc00593          	li	a1,220
ffffffffc0202bfa:	00002517          	auipc	a0,0x2
ffffffffc0202bfe:	2c650513          	addi	a0,a0,710 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202c02:	ddcfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202c06:	00002697          	auipc	a3,0x2
ffffffffc0202c0a:	2f268693          	addi	a3,a3,754 # ffffffffc0204ef8 <commands+0x1150>
ffffffffc0202c0e:	00002617          	auipc	a2,0x2
ffffffffc0202c12:	b2a60613          	addi	a2,a2,-1238 # ffffffffc0204738 <commands+0x990>
ffffffffc0202c16:	0b900593          	li	a1,185
ffffffffc0202c1a:	00002517          	auipc	a0,0x2
ffffffffc0202c1e:	2a650513          	addi	a0,a0,678 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202c22:	dbcfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202c26:	00002697          	auipc	a3,0x2
ffffffffc0202c2a:	3fa68693          	addi	a3,a3,1018 # ffffffffc0205020 <commands+0x1278>
ffffffffc0202c2e:	00002617          	auipc	a2,0x2
ffffffffc0202c32:	b0a60613          	addi	a2,a2,-1270 # ffffffffc0204738 <commands+0x990>
ffffffffc0202c36:	0d600593          	li	a1,214
ffffffffc0202c3a:	00002517          	auipc	a0,0x2
ffffffffc0202c3e:	28650513          	addi	a0,a0,646 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202c42:	d9cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202c46:	00002697          	auipc	a3,0x2
ffffffffc0202c4a:	2f268693          	addi	a3,a3,754 # ffffffffc0204f38 <commands+0x1190>
ffffffffc0202c4e:	00002617          	auipc	a2,0x2
ffffffffc0202c52:	aea60613          	addi	a2,a2,-1302 # ffffffffc0204738 <commands+0x990>
ffffffffc0202c56:	0d400593          	li	a1,212
ffffffffc0202c5a:	00002517          	auipc	a0,0x2
ffffffffc0202c5e:	26650513          	addi	a0,a0,614 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202c62:	d7cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202c66:	00002697          	auipc	a3,0x2
ffffffffc0202c6a:	2b268693          	addi	a3,a3,690 # ffffffffc0204f18 <commands+0x1170>
ffffffffc0202c6e:	00002617          	auipc	a2,0x2
ffffffffc0202c72:	aca60613          	addi	a2,a2,-1334 # ffffffffc0204738 <commands+0x990>
ffffffffc0202c76:	0d300593          	li	a1,211
ffffffffc0202c7a:	00002517          	auipc	a0,0x2
ffffffffc0202c7e:	24650513          	addi	a0,a0,582 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202c82:	d5cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202c86:	00002697          	auipc	a3,0x2
ffffffffc0202c8a:	2b268693          	addi	a3,a3,690 # ffffffffc0204f38 <commands+0x1190>
ffffffffc0202c8e:	00002617          	auipc	a2,0x2
ffffffffc0202c92:	aaa60613          	addi	a2,a2,-1366 # ffffffffc0204738 <commands+0x990>
ffffffffc0202c96:	0bb00593          	li	a1,187
ffffffffc0202c9a:	00002517          	auipc	a0,0x2
ffffffffc0202c9e:	22650513          	addi	a0,a0,550 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202ca2:	d3cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(count == 0);
ffffffffc0202ca6:	00002697          	auipc	a3,0x2
ffffffffc0202caa:	53a68693          	addi	a3,a3,1338 # ffffffffc02051e0 <commands+0x1438>
ffffffffc0202cae:	00002617          	auipc	a2,0x2
ffffffffc0202cb2:	a8a60613          	addi	a2,a2,-1398 # ffffffffc0204738 <commands+0x990>
ffffffffc0202cb6:	12500593          	li	a1,293
ffffffffc0202cba:	00002517          	auipc	a0,0x2
ffffffffc0202cbe:	20650513          	addi	a0,a0,518 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202cc2:	d1cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free == 0);
ffffffffc0202cc6:	00002697          	auipc	a3,0x2
ffffffffc0202cca:	3ba68693          	addi	a3,a3,954 # ffffffffc0205080 <commands+0x12d8>
ffffffffc0202cce:	00002617          	auipc	a2,0x2
ffffffffc0202cd2:	a6a60613          	addi	a2,a2,-1430 # ffffffffc0204738 <commands+0x990>
ffffffffc0202cd6:	11a00593          	li	a1,282
ffffffffc0202cda:	00002517          	auipc	a0,0x2
ffffffffc0202cde:	1e650513          	addi	a0,a0,486 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202ce2:	cfcfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202ce6:	00002697          	auipc	a3,0x2
ffffffffc0202cea:	33a68693          	addi	a3,a3,826 # ffffffffc0205020 <commands+0x1278>
ffffffffc0202cee:	00002617          	auipc	a2,0x2
ffffffffc0202cf2:	a4a60613          	addi	a2,a2,-1462 # ffffffffc0204738 <commands+0x990>
ffffffffc0202cf6:	11800593          	li	a1,280
ffffffffc0202cfa:	00002517          	auipc	a0,0x2
ffffffffc0202cfe:	1c650513          	addi	a0,a0,454 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202d02:	cdcfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0202d06:	00002697          	auipc	a3,0x2
ffffffffc0202d0a:	2da68693          	addi	a3,a3,730 # ffffffffc0204fe0 <commands+0x1238>
ffffffffc0202d0e:	00002617          	auipc	a2,0x2
ffffffffc0202d12:	a2a60613          	addi	a2,a2,-1494 # ffffffffc0204738 <commands+0x990>
ffffffffc0202d16:	0c100593          	li	a1,193
ffffffffc0202d1a:	00002517          	auipc	a0,0x2
ffffffffc0202d1e:	1a650513          	addi	a0,a0,422 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202d22:	cbcfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0202d26:	00002697          	auipc	a3,0x2
ffffffffc0202d2a:	47a68693          	addi	a3,a3,1146 # ffffffffc02051a0 <commands+0x13f8>
ffffffffc0202d2e:	00002617          	auipc	a2,0x2
ffffffffc0202d32:	a0a60613          	addi	a2,a2,-1526 # ffffffffc0204738 <commands+0x990>
ffffffffc0202d36:	11200593          	li	a1,274
ffffffffc0202d3a:	00002517          	auipc	a0,0x2
ffffffffc0202d3e:	18650513          	addi	a0,a0,390 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202d42:	c9cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0202d46:	00002697          	auipc	a3,0x2
ffffffffc0202d4a:	43a68693          	addi	a3,a3,1082 # ffffffffc0205180 <commands+0x13d8>
ffffffffc0202d4e:	00002617          	auipc	a2,0x2
ffffffffc0202d52:	9ea60613          	addi	a2,a2,-1558 # ffffffffc0204738 <commands+0x990>
ffffffffc0202d56:	11000593          	li	a1,272
ffffffffc0202d5a:	00002517          	auipc	a0,0x2
ffffffffc0202d5e:	16650513          	addi	a0,a0,358 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202d62:	c7cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0202d66:	00002697          	auipc	a3,0x2
ffffffffc0202d6a:	3f268693          	addi	a3,a3,1010 # ffffffffc0205158 <commands+0x13b0>
ffffffffc0202d6e:	00002617          	auipc	a2,0x2
ffffffffc0202d72:	9ca60613          	addi	a2,a2,-1590 # ffffffffc0204738 <commands+0x990>
ffffffffc0202d76:	10e00593          	li	a1,270
ffffffffc0202d7a:	00002517          	auipc	a0,0x2
ffffffffc0202d7e:	14650513          	addi	a0,a0,326 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202d82:	c5cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0202d86:	00002697          	auipc	a3,0x2
ffffffffc0202d8a:	3aa68693          	addi	a3,a3,938 # ffffffffc0205130 <commands+0x1388>
ffffffffc0202d8e:	00002617          	auipc	a2,0x2
ffffffffc0202d92:	9aa60613          	addi	a2,a2,-1622 # ffffffffc0204738 <commands+0x990>
ffffffffc0202d96:	10d00593          	li	a1,269
ffffffffc0202d9a:	00002517          	auipc	a0,0x2
ffffffffc0202d9e:	12650513          	addi	a0,a0,294 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202da2:	c3cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(p0 + 2 == p1);
ffffffffc0202da6:	00002697          	auipc	a3,0x2
ffffffffc0202daa:	37a68693          	addi	a3,a3,890 # ffffffffc0205120 <commands+0x1378>
ffffffffc0202dae:	00002617          	auipc	a2,0x2
ffffffffc0202db2:	98a60613          	addi	a2,a2,-1654 # ffffffffc0204738 <commands+0x990>
ffffffffc0202db6:	10800593          	li	a1,264
ffffffffc0202dba:	00002517          	auipc	a0,0x2
ffffffffc0202dbe:	10650513          	addi	a0,a0,262 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202dc2:	c1cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202dc6:	00002697          	auipc	a3,0x2
ffffffffc0202dca:	25a68693          	addi	a3,a3,602 # ffffffffc0205020 <commands+0x1278>
ffffffffc0202dce:	00002617          	auipc	a2,0x2
ffffffffc0202dd2:	96a60613          	addi	a2,a2,-1686 # ffffffffc0204738 <commands+0x990>
ffffffffc0202dd6:	10700593          	li	a1,263
ffffffffc0202dda:	00002517          	auipc	a0,0x2
ffffffffc0202dde:	0e650513          	addi	a0,a0,230 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202de2:	bfcfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0202de6:	00002697          	auipc	a3,0x2
ffffffffc0202dea:	31a68693          	addi	a3,a3,794 # ffffffffc0205100 <commands+0x1358>
ffffffffc0202dee:	00002617          	auipc	a2,0x2
ffffffffc0202df2:	94a60613          	addi	a2,a2,-1718 # ffffffffc0204738 <commands+0x990>
ffffffffc0202df6:	10600593          	li	a1,262
ffffffffc0202dfa:	00002517          	auipc	a0,0x2
ffffffffc0202dfe:	0c650513          	addi	a0,a0,198 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202e02:	bdcfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0202e06:	00002697          	auipc	a3,0x2
ffffffffc0202e0a:	2ca68693          	addi	a3,a3,714 # ffffffffc02050d0 <commands+0x1328>
ffffffffc0202e0e:	00002617          	auipc	a2,0x2
ffffffffc0202e12:	92a60613          	addi	a2,a2,-1750 # ffffffffc0204738 <commands+0x990>
ffffffffc0202e16:	10500593          	li	a1,261
ffffffffc0202e1a:	00002517          	auipc	a0,0x2
ffffffffc0202e1e:	0a650513          	addi	a0,a0,166 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202e22:	bbcfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0202e26:	00002697          	auipc	a3,0x2
ffffffffc0202e2a:	29268693          	addi	a3,a3,658 # ffffffffc02050b8 <commands+0x1310>
ffffffffc0202e2e:	00002617          	auipc	a2,0x2
ffffffffc0202e32:	90a60613          	addi	a2,a2,-1782 # ffffffffc0204738 <commands+0x990>
ffffffffc0202e36:	10400593          	li	a1,260
ffffffffc0202e3a:	00002517          	auipc	a0,0x2
ffffffffc0202e3e:	08650513          	addi	a0,a0,134 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202e42:	b9cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202e46:	00002697          	auipc	a3,0x2
ffffffffc0202e4a:	1da68693          	addi	a3,a3,474 # ffffffffc0205020 <commands+0x1278>
ffffffffc0202e4e:	00002617          	auipc	a2,0x2
ffffffffc0202e52:	8ea60613          	addi	a2,a2,-1814 # ffffffffc0204738 <commands+0x990>
ffffffffc0202e56:	0fe00593          	li	a1,254
ffffffffc0202e5a:	00002517          	auipc	a0,0x2
ffffffffc0202e5e:	06650513          	addi	a0,a0,102 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202e62:	b7cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(!PageProperty(p0));
ffffffffc0202e66:	00002697          	auipc	a3,0x2
ffffffffc0202e6a:	23a68693          	addi	a3,a3,570 # ffffffffc02050a0 <commands+0x12f8>
ffffffffc0202e6e:	00002617          	auipc	a2,0x2
ffffffffc0202e72:	8ca60613          	addi	a2,a2,-1846 # ffffffffc0204738 <commands+0x990>
ffffffffc0202e76:	0f900593          	li	a1,249
ffffffffc0202e7a:	00002517          	auipc	a0,0x2
ffffffffc0202e7e:	04650513          	addi	a0,a0,70 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202e82:	b5cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0202e86:	00002697          	auipc	a3,0x2
ffffffffc0202e8a:	33a68693          	addi	a3,a3,826 # ffffffffc02051c0 <commands+0x1418>
ffffffffc0202e8e:	00002617          	auipc	a2,0x2
ffffffffc0202e92:	8aa60613          	addi	a2,a2,-1878 # ffffffffc0204738 <commands+0x990>
ffffffffc0202e96:	11700593          	li	a1,279
ffffffffc0202e9a:	00002517          	auipc	a0,0x2
ffffffffc0202e9e:	02650513          	addi	a0,a0,38 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202ea2:	b3cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(total == 0);
ffffffffc0202ea6:	00002697          	auipc	a3,0x2
ffffffffc0202eaa:	34a68693          	addi	a3,a3,842 # ffffffffc02051f0 <commands+0x1448>
ffffffffc0202eae:	00002617          	auipc	a2,0x2
ffffffffc0202eb2:	88a60613          	addi	a2,a2,-1910 # ffffffffc0204738 <commands+0x990>
ffffffffc0202eb6:	12600593          	li	a1,294
ffffffffc0202eba:	00002517          	auipc	a0,0x2
ffffffffc0202ebe:	00650513          	addi	a0,a0,6 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202ec2:	b1cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(total == nr_free_pages());
ffffffffc0202ec6:	00002697          	auipc	a3,0x2
ffffffffc0202eca:	01268693          	addi	a3,a3,18 # ffffffffc0204ed8 <commands+0x1130>
ffffffffc0202ece:	00002617          	auipc	a2,0x2
ffffffffc0202ed2:	86a60613          	addi	a2,a2,-1942 # ffffffffc0204738 <commands+0x990>
ffffffffc0202ed6:	0f300593          	li	a1,243
ffffffffc0202eda:	00002517          	auipc	a0,0x2
ffffffffc0202ede:	fe650513          	addi	a0,a0,-26 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202ee2:	afcfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202ee6:	00002697          	auipc	a3,0x2
ffffffffc0202eea:	03268693          	addi	a3,a3,50 # ffffffffc0204f18 <commands+0x1170>
ffffffffc0202eee:	00002617          	auipc	a2,0x2
ffffffffc0202ef2:	84a60613          	addi	a2,a2,-1974 # ffffffffc0204738 <commands+0x990>
ffffffffc0202ef6:	0ba00593          	li	a1,186
ffffffffc0202efa:	00002517          	auipc	a0,0x2
ffffffffc0202efe:	fc650513          	addi	a0,a0,-58 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0202f02:	adcfd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202f06 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0202f06:	1141                	addi	sp,sp,-16
ffffffffc0202f08:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202f0a:	14058463          	beqz	a1,ffffffffc0203052 <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc0202f0e:	00659693          	slli	a3,a1,0x6
ffffffffc0202f12:	96aa                	add	a3,a3,a0
ffffffffc0202f14:	87aa                	mv	a5,a0
ffffffffc0202f16:	02d50263          	beq	a0,a3,ffffffffc0202f3a <default_free_pages+0x34>
ffffffffc0202f1a:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0202f1c:	8b05                	andi	a4,a4,1
ffffffffc0202f1e:	10071a63          	bnez	a4,ffffffffc0203032 <default_free_pages+0x12c>
ffffffffc0202f22:	6798                	ld	a4,8(a5)
ffffffffc0202f24:	8b09                	andi	a4,a4,2
ffffffffc0202f26:	10071663          	bnez	a4,ffffffffc0203032 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0202f2a:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc0202f2e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0202f32:	04078793          	addi	a5,a5,64
ffffffffc0202f36:	fed792e3          	bne	a5,a3,ffffffffc0202f1a <default_free_pages+0x14>
    base->property = n;
ffffffffc0202f3a:	2581                	sext.w	a1,a1
ffffffffc0202f3c:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0202f3e:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0202f42:	4789                	li	a5,2
ffffffffc0202f44:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0202f48:	00006697          	auipc	a3,0x6
ffffffffc0202f4c:	4e068693          	addi	a3,a3,1248 # ffffffffc0209428 <free_area>
ffffffffc0202f50:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0202f52:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0202f54:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0202f58:	9db9                	addw	a1,a1,a4
ffffffffc0202f5a:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0202f5c:	0ad78463          	beq	a5,a3,ffffffffc0203004 <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc0202f60:	fe878713          	addi	a4,a5,-24
ffffffffc0202f64:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0202f68:	4581                	li	a1,0
            if (base < page) {
ffffffffc0202f6a:	00e56a63          	bltu	a0,a4,ffffffffc0202f7e <default_free_pages+0x78>
    return listelm->next;
ffffffffc0202f6e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0202f70:	04d70c63          	beq	a4,a3,ffffffffc0202fc8 <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc0202f74:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0202f76:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0202f7a:	fee57ae3          	bgeu	a0,a4,ffffffffc0202f6e <default_free_pages+0x68>
ffffffffc0202f7e:	c199                	beqz	a1,ffffffffc0202f84 <default_free_pages+0x7e>
ffffffffc0202f80:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0202f84:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0202f86:	e390                	sd	a2,0(a5)
ffffffffc0202f88:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0202f8a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202f8c:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0202f8e:	00d70d63          	beq	a4,a3,ffffffffc0202fa8 <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0202f92:	ff872583          	lw	a1,-8(a4) # ff8 <kern_entry-0xffffffffc01ff008>
        p = le2page(le, page_link);
ffffffffc0202f96:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0202f9a:	02059813          	slli	a6,a1,0x20
ffffffffc0202f9e:	01a85793          	srli	a5,a6,0x1a
ffffffffc0202fa2:	97b2                	add	a5,a5,a2
ffffffffc0202fa4:	02f50c63          	beq	a0,a5,ffffffffc0202fdc <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0202fa8:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0202faa:	00d78c63          	beq	a5,a3,ffffffffc0202fc2 <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc0202fae:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0202fb0:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0202fb4:	02061593          	slli	a1,a2,0x20
ffffffffc0202fb8:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0202fbc:	972a                	add	a4,a4,a0
ffffffffc0202fbe:	04e68a63          	beq	a3,a4,ffffffffc0203012 <default_free_pages+0x10c>
}
ffffffffc0202fc2:	60a2                	ld	ra,8(sp)
ffffffffc0202fc4:	0141                	addi	sp,sp,16
ffffffffc0202fc6:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0202fc8:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202fca:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0202fcc:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0202fce:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202fd0:	02d70763          	beq	a4,a3,ffffffffc0202ffe <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0202fd4:	8832                	mv	a6,a2
ffffffffc0202fd6:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0202fd8:	87ba                	mv	a5,a4
ffffffffc0202fda:	bf71                	j	ffffffffc0202f76 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0202fdc:	491c                	lw	a5,16(a0)
ffffffffc0202fde:	9dbd                	addw	a1,a1,a5
ffffffffc0202fe0:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0202fe4:	57f5                	li	a5,-3
ffffffffc0202fe6:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202fea:	01853803          	ld	a6,24(a0)
ffffffffc0202fee:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0202ff0:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc0202ff2:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0202ff6:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0202ff8:	0105b023          	sd	a6,0(a1) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0202ffc:	b77d                	j	ffffffffc0202faa <default_free_pages+0xa4>
ffffffffc0202ffe:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0203000:	873e                	mv	a4,a5
ffffffffc0203002:	bf41                	j	ffffffffc0202f92 <default_free_pages+0x8c>
}
ffffffffc0203004:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0203006:	e390                	sd	a2,0(a5)
ffffffffc0203008:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020300a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020300c:	ed1c                	sd	a5,24(a0)
ffffffffc020300e:	0141                	addi	sp,sp,16
ffffffffc0203010:	8082                	ret
            base->property += p->property;
ffffffffc0203012:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203016:	ff078693          	addi	a3,a5,-16
ffffffffc020301a:	9e39                	addw	a2,a2,a4
ffffffffc020301c:	c910                	sw	a2,16(a0)
ffffffffc020301e:	5775                	li	a4,-3
ffffffffc0203020:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203024:	6398                	ld	a4,0(a5)
ffffffffc0203026:	679c                	ld	a5,8(a5)
}
ffffffffc0203028:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020302a:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020302c:	e398                	sd	a4,0(a5)
ffffffffc020302e:	0141                	addi	sp,sp,16
ffffffffc0203030:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0203032:	00002697          	auipc	a3,0x2
ffffffffc0203036:	1d668693          	addi	a3,a3,470 # ffffffffc0205208 <commands+0x1460>
ffffffffc020303a:	00001617          	auipc	a2,0x1
ffffffffc020303e:	6fe60613          	addi	a2,a2,1790 # ffffffffc0204738 <commands+0x990>
ffffffffc0203042:	08300593          	li	a1,131
ffffffffc0203046:	00002517          	auipc	a0,0x2
ffffffffc020304a:	e7a50513          	addi	a0,a0,-390 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc020304e:	990fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(n > 0);
ffffffffc0203052:	00002697          	auipc	a3,0x2
ffffffffc0203056:	1ae68693          	addi	a3,a3,430 # ffffffffc0205200 <commands+0x1458>
ffffffffc020305a:	00001617          	auipc	a2,0x1
ffffffffc020305e:	6de60613          	addi	a2,a2,1758 # ffffffffc0204738 <commands+0x990>
ffffffffc0203062:	08000593          	li	a1,128
ffffffffc0203066:	00002517          	auipc	a0,0x2
ffffffffc020306a:	e5a50513          	addi	a0,a0,-422 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc020306e:	970fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0203072 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0203072:	c941                	beqz	a0,ffffffffc0203102 <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc0203074:	00006597          	auipc	a1,0x6
ffffffffc0203078:	3b458593          	addi	a1,a1,948 # ffffffffc0209428 <free_area>
ffffffffc020307c:	0105a803          	lw	a6,16(a1)
ffffffffc0203080:	872a                	mv	a4,a0
ffffffffc0203082:	02081793          	slli	a5,a6,0x20
ffffffffc0203086:	9381                	srli	a5,a5,0x20
ffffffffc0203088:	00a7ee63          	bltu	a5,a0,ffffffffc02030a4 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020308c:	87ae                	mv	a5,a1
ffffffffc020308e:	a801                	j	ffffffffc020309e <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0203090:	ff87a683          	lw	a3,-8(a5)
ffffffffc0203094:	02069613          	slli	a2,a3,0x20
ffffffffc0203098:	9201                	srli	a2,a2,0x20
ffffffffc020309a:	00e67763          	bgeu	a2,a4,ffffffffc02030a8 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc020309e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02030a0:	feb798e3          	bne	a5,a1,ffffffffc0203090 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02030a4:	4501                	li	a0,0
}
ffffffffc02030a6:	8082                	ret
    return listelm->prev;
ffffffffc02030a8:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02030ac:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02030b0:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02030b4:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02030b8:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02030bc:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02030c0:	02c77863          	bgeu	a4,a2,ffffffffc02030f0 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02030c4:	071a                	slli	a4,a4,0x6
ffffffffc02030c6:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02030c8:	41c686bb          	subw	a3,a3,t3
ffffffffc02030cc:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02030ce:	00870613          	addi	a2,a4,8
ffffffffc02030d2:	4689                	li	a3,2
ffffffffc02030d4:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02030d8:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02030dc:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc02030e0:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02030e4:	e290                	sd	a2,0(a3)
ffffffffc02030e6:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02030ea:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc02030ec:	01173c23          	sd	a7,24(a4)
ffffffffc02030f0:	41c8083b          	subw	a6,a6,t3
ffffffffc02030f4:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02030f8:	5775                	li	a4,-3
ffffffffc02030fa:	17c1                	addi	a5,a5,-16
ffffffffc02030fc:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0203100:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0203102:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0203104:	00002697          	auipc	a3,0x2
ffffffffc0203108:	0fc68693          	addi	a3,a3,252 # ffffffffc0205200 <commands+0x1458>
ffffffffc020310c:	00001617          	auipc	a2,0x1
ffffffffc0203110:	62c60613          	addi	a2,a2,1580 # ffffffffc0204738 <commands+0x990>
ffffffffc0203114:	06200593          	li	a1,98
ffffffffc0203118:	00002517          	auipc	a0,0x2
ffffffffc020311c:	da850513          	addi	a0,a0,-600 # ffffffffc0204ec0 <commands+0x1118>
default_alloc_pages(size_t n) {
ffffffffc0203120:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203122:	8bcfd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0203126 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0203126:	1141                	addi	sp,sp,-16
ffffffffc0203128:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020312a:	c5f1                	beqz	a1,ffffffffc02031f6 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc020312c:	00659693          	slli	a3,a1,0x6
ffffffffc0203130:	96aa                	add	a3,a3,a0
ffffffffc0203132:	87aa                	mv	a5,a0
ffffffffc0203134:	00d50f63          	beq	a0,a3,ffffffffc0203152 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203138:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020313a:	8b05                	andi	a4,a4,1
ffffffffc020313c:	cf49                	beqz	a4,ffffffffc02031d6 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc020313e:	0007a823          	sw	zero,16(a5)
ffffffffc0203142:	0007b423          	sd	zero,8(a5)
ffffffffc0203146:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020314a:	04078793          	addi	a5,a5,64
ffffffffc020314e:	fed795e3          	bne	a5,a3,ffffffffc0203138 <default_init_memmap+0x12>
    base->property = n;
ffffffffc0203152:	2581                	sext.w	a1,a1
ffffffffc0203154:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203156:	4789                	li	a5,2
ffffffffc0203158:	00850713          	addi	a4,a0,8
ffffffffc020315c:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0203160:	00006697          	auipc	a3,0x6
ffffffffc0203164:	2c868693          	addi	a3,a3,712 # ffffffffc0209428 <free_area>
ffffffffc0203168:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020316a:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020316c:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0203170:	9db9                	addw	a1,a1,a4
ffffffffc0203172:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0203174:	04d78a63          	beq	a5,a3,ffffffffc02031c8 <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc0203178:	fe878713          	addi	a4,a5,-24
ffffffffc020317c:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0203180:	4581                	li	a1,0
            if (base < page) {
ffffffffc0203182:	00e56a63          	bltu	a0,a4,ffffffffc0203196 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0203186:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0203188:	02d70263          	beq	a4,a3,ffffffffc02031ac <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc020318c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020318e:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0203192:	fee57ae3          	bgeu	a0,a4,ffffffffc0203186 <default_init_memmap+0x60>
ffffffffc0203196:	c199                	beqz	a1,ffffffffc020319c <default_init_memmap+0x76>
ffffffffc0203198:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020319c:	6398                	ld	a4,0(a5)
}
ffffffffc020319e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02031a0:	e390                	sd	a2,0(a5)
ffffffffc02031a2:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02031a4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02031a6:	ed18                	sd	a4,24(a0)
ffffffffc02031a8:	0141                	addi	sp,sp,16
ffffffffc02031aa:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02031ac:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02031ae:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02031b0:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02031b2:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02031b4:	00d70663          	beq	a4,a3,ffffffffc02031c0 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc02031b8:	8832                	mv	a6,a2
ffffffffc02031ba:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02031bc:	87ba                	mv	a5,a4
ffffffffc02031be:	bfc1                	j	ffffffffc020318e <default_init_memmap+0x68>
}
ffffffffc02031c0:	60a2                	ld	ra,8(sp)
ffffffffc02031c2:	e290                	sd	a2,0(a3)
ffffffffc02031c4:	0141                	addi	sp,sp,16
ffffffffc02031c6:	8082                	ret
ffffffffc02031c8:	60a2                	ld	ra,8(sp)
ffffffffc02031ca:	e390                	sd	a2,0(a5)
ffffffffc02031cc:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02031ce:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02031d0:	ed1c                	sd	a5,24(a0)
ffffffffc02031d2:	0141                	addi	sp,sp,16
ffffffffc02031d4:	8082                	ret
        assert(PageReserved(p));
ffffffffc02031d6:	00002697          	auipc	a3,0x2
ffffffffc02031da:	05a68693          	addi	a3,a3,90 # ffffffffc0205230 <commands+0x1488>
ffffffffc02031de:	00001617          	auipc	a2,0x1
ffffffffc02031e2:	55a60613          	addi	a2,a2,1370 # ffffffffc0204738 <commands+0x990>
ffffffffc02031e6:	04900593          	li	a1,73
ffffffffc02031ea:	00002517          	auipc	a0,0x2
ffffffffc02031ee:	cd650513          	addi	a0,a0,-810 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc02031f2:	fedfc0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(n > 0);
ffffffffc02031f6:	00002697          	auipc	a3,0x2
ffffffffc02031fa:	00a68693          	addi	a3,a3,10 # ffffffffc0205200 <commands+0x1458>
ffffffffc02031fe:	00001617          	auipc	a2,0x1
ffffffffc0203202:	53a60613          	addi	a2,a2,1338 # ffffffffc0204738 <commands+0x990>
ffffffffc0203206:	04600593          	li	a1,70
ffffffffc020320a:	00002517          	auipc	a0,0x2
ffffffffc020320e:	cb650513          	addi	a0,a0,-842 # ffffffffc0204ec0 <commands+0x1118>
ffffffffc0203212:	fcdfc0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0203216 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0203216:	7179                	addi	sp,sp,-48
ffffffffc0203218:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc020321a:	0000a497          	auipc	s1,0xa
ffffffffc020321e:	22648493          	addi	s1,s1,550 # ffffffffc020d440 <name.0>
{
ffffffffc0203222:	f022                	sd	s0,32(sp)
ffffffffc0203224:	e84a                	sd	s2,16(sp)
ffffffffc0203226:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203228:	0000a917          	auipc	s2,0xa
ffffffffc020322c:	2a093903          	ld	s2,672(s2) # ffffffffc020d4c8 <current>
    memset(name, 0, sizeof(name));
ffffffffc0203230:	4641                	li	a2,16
ffffffffc0203232:	4581                	li	a1,0
ffffffffc0203234:	8526                	mv	a0,s1
{
ffffffffc0203236:	f406                	sd	ra,40(sp)
ffffffffc0203238:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020323a:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));
ffffffffc020323e:	48c000ef          	jal	ra,ffffffffc02036ca <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc0203242:	0b490593          	addi	a1,s2,180
ffffffffc0203246:	463d                	li	a2,15
ffffffffc0203248:	8526                	mv	a0,s1
ffffffffc020324a:	492000ef          	jal	ra,ffffffffc02036dc <memcpy>
ffffffffc020324e:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203250:	85ce                	mv	a1,s3
ffffffffc0203252:	00002517          	auipc	a0,0x2
ffffffffc0203256:	03e50513          	addi	a0,a0,62 # ffffffffc0205290 <default_pmm_manager+0x38>
ffffffffc020325a:	e87fc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc020325e:	85a2                	mv	a1,s0
ffffffffc0203260:	00002517          	auipc	a0,0x2
ffffffffc0203264:	05850513          	addi	a0,a0,88 # ffffffffc02052b8 <default_pmm_manager+0x60>
ffffffffc0203268:	e79fc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc020326c:	00002517          	auipc	a0,0x2
ffffffffc0203270:	05c50513          	addi	a0,a0,92 # ffffffffc02052c8 <default_pmm_manager+0x70>
ffffffffc0203274:	e6dfc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    return 0;
}
ffffffffc0203278:	70a2                	ld	ra,40(sp)
ffffffffc020327a:	7402                	ld	s0,32(sp)
ffffffffc020327c:	64e2                	ld	s1,24(sp)
ffffffffc020327e:	6942                	ld	s2,16(sp)
ffffffffc0203280:	69a2                	ld	s3,8(sp)
ffffffffc0203282:	4501                	li	a0,0
ffffffffc0203284:	6145                	addi	sp,sp,48
ffffffffc0203286:	8082                	ret

ffffffffc0203288 <proc_run>:
}
ffffffffc0203288:	8082                	ret

ffffffffc020328a <kernel_thread>:
{
ffffffffc020328a:	7169                	addi	sp,sp,-304
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020328c:	12000613          	li	a2,288
ffffffffc0203290:	4581                	li	a1,0
ffffffffc0203292:	850a                	mv	a0,sp
{
ffffffffc0203294:	f606                	sd	ra,296(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0203296:	434000ef          	jal	ra,ffffffffc02036ca <memset>
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020329a:	100027f3          	csrr	a5,sstatus
}
ffffffffc020329e:	70b2                	ld	ra,296(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02032a0:	0000a517          	auipc	a0,0xa
ffffffffc02032a4:	24052503          	lw	a0,576(a0) # ffffffffc020d4e0 <nr_process>
ffffffffc02032a8:	6785                	lui	a5,0x1
    int ret = -E_NO_FREE_PROC;
ffffffffc02032aa:	00f52533          	slt	a0,a0,a5
}
ffffffffc02032ae:	156d                	addi	a0,a0,-5
ffffffffc02032b0:	6155                	addi	sp,sp,304
ffffffffc02032b2:	8082                	ret

ffffffffc02032b4 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc02032b4:	7139                	addi	sp,sp,-64
ffffffffc02032b6:	f426                	sd	s1,40(sp)
    elm->prev = elm->next = elm;
ffffffffc02032b8:	0000a797          	auipc	a5,0xa
ffffffffc02032bc:	19878793          	addi	a5,a5,408 # ffffffffc020d450 <proc_list>
ffffffffc02032c0:	fc06                	sd	ra,56(sp)
ffffffffc02032c2:	f822                	sd	s0,48(sp)
ffffffffc02032c4:	f04a                	sd	s2,32(sp)
ffffffffc02032c6:	ec4e                	sd	s3,24(sp)
ffffffffc02032c8:	e852                	sd	s4,16(sp)
ffffffffc02032ca:	e456                	sd	s5,8(sp)
ffffffffc02032cc:	00006497          	auipc	s1,0x6
ffffffffc02032d0:	17448493          	addi	s1,s1,372 # ffffffffc0209440 <hash_list>
ffffffffc02032d4:	e79c                	sd	a5,8(a5)
ffffffffc02032d6:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc02032d8:	0000a717          	auipc	a4,0xa
ffffffffc02032dc:	16870713          	addi	a4,a4,360 # ffffffffc020d440 <name.0>
ffffffffc02032e0:	87a6                	mv	a5,s1
ffffffffc02032e2:	e79c                	sd	a5,8(a5)
ffffffffc02032e4:	e39c                	sd	a5,0(a5)
ffffffffc02032e6:	07c1                	addi	a5,a5,16
ffffffffc02032e8:	fef71de3          	bne	a4,a5,ffffffffc02032e2 <proc_init+0x2e>
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02032ec:	0e800513          	li	a0,232
ffffffffc02032f0:	aceff0ef          	jal	ra,ffffffffc02025be <kmalloc>
ffffffffc02032f4:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc02032f6:	20050563          	beqz	a0,ffffffffc0203500 <proc_init+0x24c>
        memset(proc, 0, sizeof(struct proc_struct));
ffffffffc02032fa:	0e800613          	li	a2,232
ffffffffc02032fe:	4581                	li	a1,0
        proc->state = PROC_UNINIT;
ffffffffc0203300:	59fd                	li	s3,-1
        memset(proc, 0, sizeof(struct proc_struct));
ffffffffc0203302:	3c8000ef          	jal	ra,ffffffffc02036ca <memset>
        proc->state = PROC_UNINIT;
ffffffffc0203306:	1982                	slli	s3,s3,0x20
        memset(&proc->context, 0, sizeof(proc->context));
ffffffffc0203308:	07000613          	li	a2,112
ffffffffc020330c:	4581                	li	a1,0
        proc->state = PROC_UNINIT;
ffffffffc020330e:	01343023          	sd	s3,0(s0)
        proc->runs = 0;
ffffffffc0203312:	00042423          	sw	zero,8(s0)
        proc->kstack = 0;
ffffffffc0203316:	00043823          	sd	zero,16(s0)
        proc->need_resched = 0;
ffffffffc020331a:	00042c23          	sw	zero,24(s0)
        proc->parent = NULL;
ffffffffc020331e:	02043023          	sd	zero,32(s0)
        proc->mm = NULL;
ffffffffc0203322:	02043423          	sd	zero,40(s0)
        memset(&proc->context, 0, sizeof(proc->context));
ffffffffc0203326:	03040513          	addi	a0,s0,48
ffffffffc020332a:	3a0000ef          	jal	ra,ffffffffc02036ca <memset>
        proc->pgdir = boot_pgdir_pa;
ffffffffc020332e:	0000aa97          	auipc	s5,0xa
ffffffffc0203332:	162a8a93          	addi	s5,s5,354 # ffffffffc020d490 <boot_pgdir_pa>
ffffffffc0203336:	000ab783          	ld	a5,0(s5)
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc020333a:	4641                	li	a2,16
ffffffffc020333c:	4581                	li	a1,0
        proc->pgdir = boot_pgdir_pa;
ffffffffc020333e:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;
ffffffffc0203340:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc0203344:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203348:	0b440513          	addi	a0,s0,180
ffffffffc020334c:	37e000ef          	jal	ra,ffffffffc02036ca <memset>
        list_init(&proc->list_link);
ffffffffc0203350:	0c840713          	addi	a4,s0,200
        list_init(&proc->hash_link);
ffffffffc0203354:	0d840793          	addi	a5,s0,216
ffffffffc0203358:	e878                	sd	a4,208(s0)
ffffffffc020335a:	e478                	sd	a4,200(s0)
ffffffffc020335c:	f07c                	sd	a5,224(s0)
ffffffffc020335e:	ec7c                	sd	a5,216(s0)
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0203360:	0000a917          	auipc	s2,0xa
ffffffffc0203364:	17090913          	addi	s2,s2,368 # ffffffffc020d4d0 <idleproc>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0203368:	07000513          	li	a0,112
    if ((idleproc = alloc_proc()) == NULL)
ffffffffc020336c:	00893023          	sd	s0,0(s2)
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0203370:	a4eff0ef          	jal	ra,ffffffffc02025be <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0203374:	07000613          	li	a2,112
ffffffffc0203378:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc020337a:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc020337c:	34e000ef          	jal	ra,ffffffffc02036ca <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc0203380:	00093503          	ld	a0,0(s2)
ffffffffc0203384:	85a2                	mv	a1,s0
ffffffffc0203386:	07000613          	li	a2,112
ffffffffc020338a:	03050513          	addi	a0,a0,48
ffffffffc020338e:	366000ef          	jal	ra,ffffffffc02036f4 <memcmp>
ffffffffc0203392:	8a2a                	mv	s4,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc0203394:	453d                	li	a0,15
ffffffffc0203396:	a28ff0ef          	jal	ra,ffffffffc02025be <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc020339a:	463d                	li	a2,15
ffffffffc020339c:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc020339e:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02033a0:	32a000ef          	jal	ra,ffffffffc02036ca <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc02033a4:	00093503          	ld	a0,0(s2)
ffffffffc02033a8:	463d                	li	a2,15
ffffffffc02033aa:	85a2                	mv	a1,s0
ffffffffc02033ac:	0b450513          	addi	a0,a0,180
ffffffffc02033b0:	344000ef          	jal	ra,ffffffffc02036f4 <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02033b4:	00093783          	ld	a5,0(s2)
ffffffffc02033b8:	000ab703          	ld	a4,0(s5)
ffffffffc02033bc:	77d4                	ld	a3,168(a5)
ffffffffc02033be:	0ee68663          	beq	a3,a4,ffffffffc02034aa <proc_init+0x1f6>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02033c2:	4709                	li	a4,2
ffffffffc02033c4:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02033c6:	00003717          	auipc	a4,0x3
ffffffffc02033ca:	c3a70713          	addi	a4,a4,-966 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02033ce:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02033d2:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc02033d4:	4705                	li	a4,1
ffffffffc02033d6:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02033d8:	4641                	li	a2,16
ffffffffc02033da:	4581                	li	a1,0
ffffffffc02033dc:	8522                	mv	a0,s0
ffffffffc02033de:	2ec000ef          	jal	ra,ffffffffc02036ca <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02033e2:	463d                	li	a2,15
ffffffffc02033e4:	00002597          	auipc	a1,0x2
ffffffffc02033e8:	f4c58593          	addi	a1,a1,-180 # ffffffffc0205330 <default_pmm_manager+0xd8>
ffffffffc02033ec:	8522                	mv	a0,s0
ffffffffc02033ee:	2ee000ef          	jal	ra,ffffffffc02036dc <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc02033f2:	0000a717          	auipc	a4,0xa
ffffffffc02033f6:	0ee70713          	addi	a4,a4,238 # ffffffffc020d4e0 <nr_process>
ffffffffc02033fa:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc02033fc:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203400:	4601                	li	a2,0
    nr_process++;
ffffffffc0203402:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203404:	00002597          	auipc	a1,0x2
ffffffffc0203408:	f3458593          	addi	a1,a1,-204 # ffffffffc0205338 <default_pmm_manager+0xe0>
ffffffffc020340c:	00000517          	auipc	a0,0x0
ffffffffc0203410:	e0a50513          	addi	a0,a0,-502 # ffffffffc0203216 <init_main>
    nr_process++;
ffffffffc0203414:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0203416:	0000a797          	auipc	a5,0xa
ffffffffc020341a:	0ad7b923          	sd	a3,178(a5) # ffffffffc020d4c8 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020341e:	e6dff0ef          	jal	ra,ffffffffc020328a <kernel_thread>
ffffffffc0203422:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0203424:	0ea05e63          	blez	a0,ffffffffc0203520 <proc_init+0x26c>
    if (0 < pid && pid < MAX_PID)
ffffffffc0203428:	6789                	lui	a5,0x2
ffffffffc020342a:	fff5071b          	addiw	a4,a0,-1
ffffffffc020342e:	17f9                	addi	a5,a5,-2
ffffffffc0203430:	2501                	sext.w	a0,a0
ffffffffc0203432:	02e7e363          	bltu	a5,a4,ffffffffc0203458 <proc_init+0x1a4>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0203436:	45a9                	li	a1,10
ffffffffc0203438:	6ce000ef          	jal	ra,ffffffffc0203b06 <hash32>
ffffffffc020343c:	02051793          	slli	a5,a0,0x20
ffffffffc0203440:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0203444:	96a6                	add	a3,a3,s1
ffffffffc0203446:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0203448:	a029                	j	ffffffffc0203452 <proc_init+0x19e>
            if (proc->pid == pid)
ffffffffc020344a:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc020344e:	0a870663          	beq	a4,s0,ffffffffc02034fa <proc_init+0x246>
    return listelm->next;
ffffffffc0203452:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203454:	fef69be3          	bne	a3,a5,ffffffffc020344a <proc_init+0x196>
    return NULL;
ffffffffc0203458:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020345a:	0b478493          	addi	s1,a5,180
ffffffffc020345e:	4641                	li	a2,16
ffffffffc0203460:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0203462:	0000a417          	auipc	s0,0xa
ffffffffc0203466:	07640413          	addi	s0,s0,118 # ffffffffc020d4d8 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020346a:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc020346c:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020346e:	25c000ef          	jal	ra,ffffffffc02036ca <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203472:	463d                	li	a2,15
ffffffffc0203474:	00002597          	auipc	a1,0x2
ffffffffc0203478:	ef458593          	addi	a1,a1,-268 # ffffffffc0205368 <default_pmm_manager+0x110>
ffffffffc020347c:	8526                	mv	a0,s1
ffffffffc020347e:	25e000ef          	jal	ra,ffffffffc02036dc <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203482:	00093783          	ld	a5,0(s2)
ffffffffc0203486:	cbe9                	beqz	a5,ffffffffc0203558 <proc_init+0x2a4>
ffffffffc0203488:	43dc                	lw	a5,4(a5)
ffffffffc020348a:	e7f9                	bnez	a5,ffffffffc0203558 <proc_init+0x2a4>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020348c:	601c                	ld	a5,0(s0)
ffffffffc020348e:	c7cd                	beqz	a5,ffffffffc0203538 <proc_init+0x284>
ffffffffc0203490:	43d8                	lw	a4,4(a5)
ffffffffc0203492:	4785                	li	a5,1
ffffffffc0203494:	0af71263          	bne	a4,a5,ffffffffc0203538 <proc_init+0x284>
}
ffffffffc0203498:	70e2                	ld	ra,56(sp)
ffffffffc020349a:	7442                	ld	s0,48(sp)
ffffffffc020349c:	74a2                	ld	s1,40(sp)
ffffffffc020349e:	7902                	ld	s2,32(sp)
ffffffffc02034a0:	69e2                	ld	s3,24(sp)
ffffffffc02034a2:	6a42                	ld	s4,16(sp)
ffffffffc02034a4:	6aa2                	ld	s5,8(sp)
ffffffffc02034a6:	6121                	addi	sp,sp,64
ffffffffc02034a8:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02034aa:	73d8                	ld	a4,160(a5)
ffffffffc02034ac:	f0071be3          	bnez	a4,ffffffffc02033c2 <proc_init+0x10e>
ffffffffc02034b0:	f00a19e3          	bnez	s4,ffffffffc02033c2 <proc_init+0x10e>
ffffffffc02034b4:	6398                	ld	a4,0(a5)
ffffffffc02034b6:	f13716e3          	bne	a4,s3,ffffffffc02033c2 <proc_init+0x10e>
ffffffffc02034ba:	4798                	lw	a4,8(a5)
ffffffffc02034bc:	f00713e3          	bnez	a4,ffffffffc02033c2 <proc_init+0x10e>
ffffffffc02034c0:	6b98                	ld	a4,16(a5)
ffffffffc02034c2:	f00710e3          	bnez	a4,ffffffffc02033c2 <proc_init+0x10e>
ffffffffc02034c6:	4f98                	lw	a4,24(a5)
ffffffffc02034c8:	2701                	sext.w	a4,a4
ffffffffc02034ca:	ee071ce3          	bnez	a4,ffffffffc02033c2 <proc_init+0x10e>
ffffffffc02034ce:	7398                	ld	a4,32(a5)
ffffffffc02034d0:	ee0719e3          	bnez	a4,ffffffffc02033c2 <proc_init+0x10e>
ffffffffc02034d4:	7798                	ld	a4,40(a5)
ffffffffc02034d6:	ee0716e3          	bnez	a4,ffffffffc02033c2 <proc_init+0x10e>
ffffffffc02034da:	0b07a703          	lw	a4,176(a5)
ffffffffc02034de:	8d59                	or	a0,a0,a4
ffffffffc02034e0:	0005071b          	sext.w	a4,a0
ffffffffc02034e4:	ec071fe3          	bnez	a4,ffffffffc02033c2 <proc_init+0x10e>
        cprintf("alloc_proc() correct!\n");
ffffffffc02034e8:	00002517          	auipc	a0,0x2
ffffffffc02034ec:	e3050513          	addi	a0,a0,-464 # ffffffffc0205318 <default_pmm_manager+0xc0>
ffffffffc02034f0:	bf1fc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    idleproc->pid = 0;
ffffffffc02034f4:	00093783          	ld	a5,0(s2)
ffffffffc02034f8:	b5e9                	j	ffffffffc02033c2 <proc_init+0x10e>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02034fa:	f2878793          	addi	a5,a5,-216
ffffffffc02034fe:	bfb1                	j	ffffffffc020345a <proc_init+0x1a6>
        panic("cannot alloc idleproc.\n");
ffffffffc0203500:	00002617          	auipc	a2,0x2
ffffffffc0203504:	ec060613          	addi	a2,a2,-320 # ffffffffc02053c0 <default_pmm_manager+0x168>
ffffffffc0203508:	19100593          	li	a1,401
ffffffffc020350c:	00002517          	auipc	a0,0x2
ffffffffc0203510:	df450513          	addi	a0,a0,-524 # ffffffffc0205300 <default_pmm_manager+0xa8>
    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0203514:	0000a797          	auipc	a5,0xa
ffffffffc0203518:	fa07be23          	sd	zero,-68(a5) # ffffffffc020d4d0 <idleproc>
        panic("cannot alloc idleproc.\n");
ffffffffc020351c:	cc3fc0ef          	jal	ra,ffffffffc02001de <__panic>
        panic("create init_main failed.\n");
ffffffffc0203520:	00002617          	auipc	a2,0x2
ffffffffc0203524:	e2860613          	addi	a2,a2,-472 # ffffffffc0205348 <default_pmm_manager+0xf0>
ffffffffc0203528:	1ae00593          	li	a1,430
ffffffffc020352c:	00002517          	auipc	a0,0x2
ffffffffc0203530:	dd450513          	addi	a0,a0,-556 # ffffffffc0205300 <default_pmm_manager+0xa8>
ffffffffc0203534:	cabfc0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0203538:	00002697          	auipc	a3,0x2
ffffffffc020353c:	e6068693          	addi	a3,a3,-416 # ffffffffc0205398 <default_pmm_manager+0x140>
ffffffffc0203540:	00001617          	auipc	a2,0x1
ffffffffc0203544:	1f860613          	addi	a2,a2,504 # ffffffffc0204738 <commands+0x990>
ffffffffc0203548:	1b500593          	li	a1,437
ffffffffc020354c:	00002517          	auipc	a0,0x2
ffffffffc0203550:	db450513          	addi	a0,a0,-588 # ffffffffc0205300 <default_pmm_manager+0xa8>
ffffffffc0203554:	c8bfc0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203558:	00002697          	auipc	a3,0x2
ffffffffc020355c:	e1868693          	addi	a3,a3,-488 # ffffffffc0205370 <default_pmm_manager+0x118>
ffffffffc0203560:	00001617          	auipc	a2,0x1
ffffffffc0203564:	1d860613          	addi	a2,a2,472 # ffffffffc0204738 <commands+0x990>
ffffffffc0203568:	1b400593          	li	a1,436
ffffffffc020356c:	00002517          	auipc	a0,0x2
ffffffffc0203570:	d9450513          	addi	a0,a0,-620 # ffffffffc0205300 <default_pmm_manager+0xa8>
ffffffffc0203574:	c6bfc0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0203578 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0203578:	1141                	addi	sp,sp,-16
ffffffffc020357a:	e022                	sd	s0,0(sp)
ffffffffc020357c:	e406                	sd	ra,8(sp)
ffffffffc020357e:	0000a417          	auipc	s0,0xa
ffffffffc0203582:	f4a40413          	addi	s0,s0,-182 # ffffffffc020d4c8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0203586:	6018                	ld	a4,0(s0)
ffffffffc0203588:	4f1c                	lw	a5,24(a4)
ffffffffc020358a:	2781                	sext.w	a5,a5
ffffffffc020358c:	dff5                	beqz	a5,ffffffffc0203588 <cpu_idle+0x10>
        {
            schedule();
ffffffffc020358e:	006000ef          	jal	ra,ffffffffc0203594 <schedule>
ffffffffc0203592:	bfd5                	j	ffffffffc0203586 <cpu_idle+0xe>

ffffffffc0203594 <schedule>:
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
    proc->state = PROC_RUNNABLE;
}

void
schedule(void) {
ffffffffc0203594:	1141                	addi	sp,sp,-16
ffffffffc0203596:	e406                	sd	ra,8(sp)
ffffffffc0203598:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020359a:	100027f3          	csrr	a5,sstatus
ffffffffc020359e:	8b89                	andi	a5,a5,2
ffffffffc02035a0:	4401                	li	s0,0
ffffffffc02035a2:	efbd                	bnez	a5,ffffffffc0203620 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02035a4:	0000a897          	auipc	a7,0xa
ffffffffc02035a8:	f248b883          	ld	a7,-220(a7) # ffffffffc020d4c8 <current>
ffffffffc02035ac:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02035b0:	0000a517          	auipc	a0,0xa
ffffffffc02035b4:	f2053503          	ld	a0,-224(a0) # ffffffffc020d4d0 <idleproc>
ffffffffc02035b8:	04a88e63          	beq	a7,a0,ffffffffc0203614 <schedule+0x80>
ffffffffc02035bc:	0c888693          	addi	a3,a7,200
ffffffffc02035c0:	0000a617          	auipc	a2,0xa
ffffffffc02035c4:	e9060613          	addi	a2,a2,-368 # ffffffffc020d450 <proc_list>
        le = last;
ffffffffc02035c8:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02035ca:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc02035cc:	4809                	li	a6,2
ffffffffc02035ce:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc02035d0:	00c78863          	beq	a5,a2,ffffffffc02035e0 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc02035d4:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02035d8:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc02035dc:	03070163          	beq	a4,a6,ffffffffc02035fe <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc02035e0:	fef697e3          	bne	a3,a5,ffffffffc02035ce <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02035e4:	ed89                	bnez	a1,ffffffffc02035fe <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc02035e6:	451c                	lw	a5,8(a0)
ffffffffc02035e8:	2785                	addiw	a5,a5,1
ffffffffc02035ea:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc02035ec:	00a88463          	beq	a7,a0,ffffffffc02035f4 <schedule+0x60>
            proc_run(next);
ffffffffc02035f0:	c99ff0ef          	jal	ra,ffffffffc0203288 <proc_run>
    if (flag) {
ffffffffc02035f4:	e819                	bnez	s0,ffffffffc020360a <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02035f6:	60a2                	ld	ra,8(sp)
ffffffffc02035f8:	6402                	ld	s0,0(sp)
ffffffffc02035fa:	0141                	addi	sp,sp,16
ffffffffc02035fc:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02035fe:	4198                	lw	a4,0(a1)
ffffffffc0203600:	4789                	li	a5,2
ffffffffc0203602:	fef712e3          	bne	a4,a5,ffffffffc02035e6 <schedule+0x52>
ffffffffc0203606:	852e                	mv	a0,a1
ffffffffc0203608:	bff9                	j	ffffffffc02035e6 <schedule+0x52>
}
ffffffffc020360a:	6402                	ld	s0,0(sp)
ffffffffc020360c:	60a2                	ld	ra,8(sp)
ffffffffc020360e:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0203610:	b20fd06f          	j	ffffffffc0200930 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203614:	0000a617          	auipc	a2,0xa
ffffffffc0203618:	e3c60613          	addi	a2,a2,-452 # ffffffffc020d450 <proc_list>
ffffffffc020361c:	86b2                	mv	a3,a2
ffffffffc020361e:	b76d                	j	ffffffffc02035c8 <schedule+0x34>
        intr_disable();
ffffffffc0203620:	b16fd0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        return 1;
ffffffffc0203624:	4405                	li	s0,1
ffffffffc0203626:	bfbd                	j	ffffffffc02035a4 <schedule+0x10>

ffffffffc0203628 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203628:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020362c:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc020362e:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0203630:	cb81                	beqz	a5,ffffffffc0203640 <strlen+0x18>
        cnt ++;
ffffffffc0203632:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0203634:	00a707b3          	add	a5,a4,a0
ffffffffc0203638:	0007c783          	lbu	a5,0(a5)
ffffffffc020363c:	fbfd                	bnez	a5,ffffffffc0203632 <strlen+0xa>
ffffffffc020363e:	8082                	ret
    }
    return cnt;
}
ffffffffc0203640:	8082                	ret

ffffffffc0203642 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203642:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203644:	e589                	bnez	a1,ffffffffc020364e <strnlen+0xc>
ffffffffc0203646:	a811                	j	ffffffffc020365a <strnlen+0x18>
        cnt ++;
ffffffffc0203648:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020364a:	00f58863          	beq	a1,a5,ffffffffc020365a <strnlen+0x18>
ffffffffc020364e:	00f50733          	add	a4,a0,a5
ffffffffc0203652:	00074703          	lbu	a4,0(a4)
ffffffffc0203656:	fb6d                	bnez	a4,ffffffffc0203648 <strnlen+0x6>
ffffffffc0203658:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020365a:	852e                	mv	a0,a1
ffffffffc020365c:	8082                	ret

ffffffffc020365e <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc020365e:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203660:	0005c703          	lbu	a4,0(a1)
ffffffffc0203664:	0785                	addi	a5,a5,1
ffffffffc0203666:	0585                	addi	a1,a1,1
ffffffffc0203668:	fee78fa3          	sb	a4,-1(a5)
ffffffffc020366c:	fb75                	bnez	a4,ffffffffc0203660 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc020366e:	8082                	ret

ffffffffc0203670 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203670:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203674:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203678:	cb89                	beqz	a5,ffffffffc020368a <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020367a:	0505                	addi	a0,a0,1
ffffffffc020367c:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020367e:	fee789e3          	beq	a5,a4,ffffffffc0203670 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203682:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203686:	9d19                	subw	a0,a0,a4
ffffffffc0203688:	8082                	ret
ffffffffc020368a:	4501                	li	a0,0
ffffffffc020368c:	bfed                	j	ffffffffc0203686 <strcmp+0x16>

ffffffffc020368e <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020368e:	c20d                	beqz	a2,ffffffffc02036b0 <strncmp+0x22>
ffffffffc0203690:	962e                	add	a2,a2,a1
ffffffffc0203692:	a031                	j	ffffffffc020369e <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0203694:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203696:	00e79a63          	bne	a5,a4,ffffffffc02036aa <strncmp+0x1c>
ffffffffc020369a:	00b60b63          	beq	a2,a1,ffffffffc02036b0 <strncmp+0x22>
ffffffffc020369e:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02036a2:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02036a4:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02036a8:	f7f5                	bnez	a5,ffffffffc0203694 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02036aa:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02036ae:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02036b0:	4501                	li	a0,0
ffffffffc02036b2:	8082                	ret

ffffffffc02036b4 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02036b4:	00054783          	lbu	a5,0(a0)
ffffffffc02036b8:	c799                	beqz	a5,ffffffffc02036c6 <strchr+0x12>
        if (*s == c) {
ffffffffc02036ba:	00f58763          	beq	a1,a5,ffffffffc02036c8 <strchr+0x14>
    while (*s != '\0') {
ffffffffc02036be:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02036c2:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02036c4:	fbfd                	bnez	a5,ffffffffc02036ba <strchr+0x6>
    }
    return NULL;
ffffffffc02036c6:	4501                	li	a0,0
}
ffffffffc02036c8:	8082                	ret

ffffffffc02036ca <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02036ca:	ca01                	beqz	a2,ffffffffc02036da <memset+0x10>
ffffffffc02036cc:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02036ce:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02036d0:	0785                	addi	a5,a5,1
ffffffffc02036d2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02036d6:	fec79de3          	bne	a5,a2,ffffffffc02036d0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02036da:	8082                	ret

ffffffffc02036dc <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02036dc:	ca19                	beqz	a2,ffffffffc02036f2 <memcpy+0x16>
ffffffffc02036de:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02036e0:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02036e2:	0005c703          	lbu	a4,0(a1)
ffffffffc02036e6:	0585                	addi	a1,a1,1
ffffffffc02036e8:	0785                	addi	a5,a5,1
ffffffffc02036ea:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02036ee:	fec59ae3          	bne	a1,a2,ffffffffc02036e2 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02036f2:	8082                	ret

ffffffffc02036f4 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc02036f4:	c205                	beqz	a2,ffffffffc0203714 <memcmp+0x20>
ffffffffc02036f6:	962e                	add	a2,a2,a1
ffffffffc02036f8:	a019                	j	ffffffffc02036fe <memcmp+0xa>
ffffffffc02036fa:	00c58d63          	beq	a1,a2,ffffffffc0203714 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc02036fe:	00054783          	lbu	a5,0(a0)
ffffffffc0203702:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203706:	0505                	addi	a0,a0,1
ffffffffc0203708:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc020370a:	fee788e3          	beq	a5,a4,ffffffffc02036fa <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020370e:	40e7853b          	subw	a0,a5,a4
ffffffffc0203712:	8082                	ret
    }
    return 0;
ffffffffc0203714:	4501                	li	a0,0
}
ffffffffc0203716:	8082                	ret

ffffffffc0203718 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203718:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020371c:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020371e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203722:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203724:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203728:	f022                	sd	s0,32(sp)
ffffffffc020372a:	ec26                	sd	s1,24(sp)
ffffffffc020372c:	e84a                	sd	s2,16(sp)
ffffffffc020372e:	f406                	sd	ra,40(sp)
ffffffffc0203730:	e44e                	sd	s3,8(sp)
ffffffffc0203732:	84aa                	mv	s1,a0
ffffffffc0203734:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203736:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020373a:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020373c:	03067e63          	bgeu	a2,a6,ffffffffc0203778 <printnum+0x60>
ffffffffc0203740:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203742:	00805763          	blez	s0,ffffffffc0203750 <printnum+0x38>
ffffffffc0203746:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203748:	85ca                	mv	a1,s2
ffffffffc020374a:	854e                	mv	a0,s3
ffffffffc020374c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020374e:	fc65                	bnez	s0,ffffffffc0203746 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203750:	1a02                	slli	s4,s4,0x20
ffffffffc0203752:	00002797          	auipc	a5,0x2
ffffffffc0203756:	c8678793          	addi	a5,a5,-890 # ffffffffc02053d8 <default_pmm_manager+0x180>
ffffffffc020375a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020375e:	9a3e                	add	s4,s4,a5
}
ffffffffc0203760:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203762:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203766:	70a2                	ld	ra,40(sp)
ffffffffc0203768:	69a2                	ld	s3,8(sp)
ffffffffc020376a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020376c:	85ca                	mv	a1,s2
ffffffffc020376e:	87a6                	mv	a5,s1
}
ffffffffc0203770:	6942                	ld	s2,16(sp)
ffffffffc0203772:	64e2                	ld	s1,24(sp)
ffffffffc0203774:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203776:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203778:	03065633          	divu	a2,a2,a6
ffffffffc020377c:	8722                	mv	a4,s0
ffffffffc020377e:	f9bff0ef          	jal	ra,ffffffffc0203718 <printnum>
ffffffffc0203782:	b7f9                	j	ffffffffc0203750 <printnum+0x38>

ffffffffc0203784 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203784:	7119                	addi	sp,sp,-128
ffffffffc0203786:	f4a6                	sd	s1,104(sp)
ffffffffc0203788:	f0ca                	sd	s2,96(sp)
ffffffffc020378a:	ecce                	sd	s3,88(sp)
ffffffffc020378c:	e8d2                	sd	s4,80(sp)
ffffffffc020378e:	e4d6                	sd	s5,72(sp)
ffffffffc0203790:	e0da                	sd	s6,64(sp)
ffffffffc0203792:	fc5e                	sd	s7,56(sp)
ffffffffc0203794:	f06a                	sd	s10,32(sp)
ffffffffc0203796:	fc86                	sd	ra,120(sp)
ffffffffc0203798:	f8a2                	sd	s0,112(sp)
ffffffffc020379a:	f862                	sd	s8,48(sp)
ffffffffc020379c:	f466                	sd	s9,40(sp)
ffffffffc020379e:	ec6e                	sd	s11,24(sp)
ffffffffc02037a0:	892a                	mv	s2,a0
ffffffffc02037a2:	84ae                	mv	s1,a1
ffffffffc02037a4:	8d32                	mv	s10,a2
ffffffffc02037a6:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02037a8:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02037ac:	5b7d                	li	s6,-1
ffffffffc02037ae:	00002a97          	auipc	s5,0x2
ffffffffc02037b2:	c56a8a93          	addi	s5,s5,-938 # ffffffffc0205404 <default_pmm_manager+0x1ac>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02037b6:	00002b97          	auipc	s7,0x2
ffffffffc02037ba:	e2ab8b93          	addi	s7,s7,-470 # ffffffffc02055e0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02037be:	000d4503          	lbu	a0,0(s10)
ffffffffc02037c2:	001d0413          	addi	s0,s10,1
ffffffffc02037c6:	01350a63          	beq	a0,s3,ffffffffc02037da <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02037ca:	c121                	beqz	a0,ffffffffc020380a <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02037cc:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02037ce:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02037d0:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02037d2:	fff44503          	lbu	a0,-1(s0)
ffffffffc02037d6:	ff351ae3          	bne	a0,s3,ffffffffc02037ca <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02037da:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02037de:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02037e2:	4c81                	li	s9,0
ffffffffc02037e4:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02037e6:	5c7d                	li	s8,-1
ffffffffc02037e8:	5dfd                	li	s11,-1
ffffffffc02037ea:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02037ee:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02037f0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02037f4:	0ff5f593          	zext.b	a1,a1
ffffffffc02037f8:	00140d13          	addi	s10,s0,1
ffffffffc02037fc:	04b56263          	bltu	a0,a1,ffffffffc0203840 <vprintfmt+0xbc>
ffffffffc0203800:	058a                	slli	a1,a1,0x2
ffffffffc0203802:	95d6                	add	a1,a1,s5
ffffffffc0203804:	4194                	lw	a3,0(a1)
ffffffffc0203806:	96d6                	add	a3,a3,s5
ffffffffc0203808:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020380a:	70e6                	ld	ra,120(sp)
ffffffffc020380c:	7446                	ld	s0,112(sp)
ffffffffc020380e:	74a6                	ld	s1,104(sp)
ffffffffc0203810:	7906                	ld	s2,96(sp)
ffffffffc0203812:	69e6                	ld	s3,88(sp)
ffffffffc0203814:	6a46                	ld	s4,80(sp)
ffffffffc0203816:	6aa6                	ld	s5,72(sp)
ffffffffc0203818:	6b06                	ld	s6,64(sp)
ffffffffc020381a:	7be2                	ld	s7,56(sp)
ffffffffc020381c:	7c42                	ld	s8,48(sp)
ffffffffc020381e:	7ca2                	ld	s9,40(sp)
ffffffffc0203820:	7d02                	ld	s10,32(sp)
ffffffffc0203822:	6de2                	ld	s11,24(sp)
ffffffffc0203824:	6109                	addi	sp,sp,128
ffffffffc0203826:	8082                	ret
            padc = '0';
ffffffffc0203828:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc020382a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020382e:	846a                	mv	s0,s10
ffffffffc0203830:	00140d13          	addi	s10,s0,1
ffffffffc0203834:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203838:	0ff5f593          	zext.b	a1,a1
ffffffffc020383c:	fcb572e3          	bgeu	a0,a1,ffffffffc0203800 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0203840:	85a6                	mv	a1,s1
ffffffffc0203842:	02500513          	li	a0,37
ffffffffc0203846:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203848:	fff44783          	lbu	a5,-1(s0)
ffffffffc020384c:	8d22                	mv	s10,s0
ffffffffc020384e:	f73788e3          	beq	a5,s3,ffffffffc02037be <vprintfmt+0x3a>
ffffffffc0203852:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0203856:	1d7d                	addi	s10,s10,-1
ffffffffc0203858:	ff379de3          	bne	a5,s3,ffffffffc0203852 <vprintfmt+0xce>
ffffffffc020385c:	b78d                	j	ffffffffc02037be <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020385e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0203862:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203866:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0203868:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020386c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203870:	02d86463          	bltu	a6,a3,ffffffffc0203898 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0203874:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203878:	002c169b          	slliw	a3,s8,0x2
ffffffffc020387c:	0186873b          	addw	a4,a3,s8
ffffffffc0203880:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203884:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0203886:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020388a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020388c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0203890:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203894:	fed870e3          	bgeu	a6,a3,ffffffffc0203874 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0203898:	f40ddce3          	bgez	s11,ffffffffc02037f0 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020389c:	8de2                	mv	s11,s8
ffffffffc020389e:	5c7d                	li	s8,-1
ffffffffc02038a0:	bf81                	j	ffffffffc02037f0 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02038a2:	fffdc693          	not	a3,s11
ffffffffc02038a6:	96fd                	srai	a3,a3,0x3f
ffffffffc02038a8:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02038ac:	00144603          	lbu	a2,1(s0)
ffffffffc02038b0:	2d81                	sext.w	s11,s11
ffffffffc02038b2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02038b4:	bf35                	j	ffffffffc02037f0 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02038b6:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02038ba:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02038be:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02038c0:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02038c2:	bfd9                	j	ffffffffc0203898 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02038c4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02038c6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02038ca:	01174463          	blt	a4,a7,ffffffffc02038d2 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02038ce:	1a088e63          	beqz	a7,ffffffffc0203a8a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02038d2:	000a3603          	ld	a2,0(s4)
ffffffffc02038d6:	46c1                	li	a3,16
ffffffffc02038d8:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02038da:	2781                	sext.w	a5,a5
ffffffffc02038dc:	876e                	mv	a4,s11
ffffffffc02038de:	85a6                	mv	a1,s1
ffffffffc02038e0:	854a                	mv	a0,s2
ffffffffc02038e2:	e37ff0ef          	jal	ra,ffffffffc0203718 <printnum>
            break;
ffffffffc02038e6:	bde1                	j	ffffffffc02037be <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02038e8:	000a2503          	lw	a0,0(s4)
ffffffffc02038ec:	85a6                	mv	a1,s1
ffffffffc02038ee:	0a21                	addi	s4,s4,8
ffffffffc02038f0:	9902                	jalr	s2
            break;
ffffffffc02038f2:	b5f1                	j	ffffffffc02037be <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02038f4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02038f6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02038fa:	01174463          	blt	a4,a7,ffffffffc0203902 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02038fe:	18088163          	beqz	a7,ffffffffc0203a80 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0203902:	000a3603          	ld	a2,0(s4)
ffffffffc0203906:	46a9                	li	a3,10
ffffffffc0203908:	8a2e                	mv	s4,a1
ffffffffc020390a:	bfc1                	j	ffffffffc02038da <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020390c:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0203910:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203912:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203914:	bdf1                	j	ffffffffc02037f0 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0203916:	85a6                	mv	a1,s1
ffffffffc0203918:	02500513          	li	a0,37
ffffffffc020391c:	9902                	jalr	s2
            break;
ffffffffc020391e:	b545                	j	ffffffffc02037be <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203920:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0203924:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203926:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203928:	b5e1                	j	ffffffffc02037f0 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc020392a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020392c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203930:	01174463          	blt	a4,a7,ffffffffc0203938 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0203934:	14088163          	beqz	a7,ffffffffc0203a76 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0203938:	000a3603          	ld	a2,0(s4)
ffffffffc020393c:	46a1                	li	a3,8
ffffffffc020393e:	8a2e                	mv	s4,a1
ffffffffc0203940:	bf69                	j	ffffffffc02038da <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0203942:	03000513          	li	a0,48
ffffffffc0203946:	85a6                	mv	a1,s1
ffffffffc0203948:	e03e                	sd	a5,0(sp)
ffffffffc020394a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020394c:	85a6                	mv	a1,s1
ffffffffc020394e:	07800513          	li	a0,120
ffffffffc0203952:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203954:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203956:	6782                	ld	a5,0(sp)
ffffffffc0203958:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020395a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020395e:	bfb5                	j	ffffffffc02038da <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203960:	000a3403          	ld	s0,0(s4)
ffffffffc0203964:	008a0713          	addi	a4,s4,8
ffffffffc0203968:	e03a                	sd	a4,0(sp)
ffffffffc020396a:	14040263          	beqz	s0,ffffffffc0203aae <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020396e:	0fb05763          	blez	s11,ffffffffc0203a5c <vprintfmt+0x2d8>
ffffffffc0203972:	02d00693          	li	a3,45
ffffffffc0203976:	0cd79163          	bne	a5,a3,ffffffffc0203a38 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020397a:	00044783          	lbu	a5,0(s0)
ffffffffc020397e:	0007851b          	sext.w	a0,a5
ffffffffc0203982:	cf85                	beqz	a5,ffffffffc02039ba <vprintfmt+0x236>
ffffffffc0203984:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203988:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020398c:	000c4563          	bltz	s8,ffffffffc0203996 <vprintfmt+0x212>
ffffffffc0203990:	3c7d                	addiw	s8,s8,-1
ffffffffc0203992:	036c0263          	beq	s8,s6,ffffffffc02039b6 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0203996:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203998:	0e0c8e63          	beqz	s9,ffffffffc0203a94 <vprintfmt+0x310>
ffffffffc020399c:	3781                	addiw	a5,a5,-32
ffffffffc020399e:	0ef47b63          	bgeu	s0,a5,ffffffffc0203a94 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02039a2:	03f00513          	li	a0,63
ffffffffc02039a6:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02039a8:	000a4783          	lbu	a5,0(s4)
ffffffffc02039ac:	3dfd                	addiw	s11,s11,-1
ffffffffc02039ae:	0a05                	addi	s4,s4,1
ffffffffc02039b0:	0007851b          	sext.w	a0,a5
ffffffffc02039b4:	ffe1                	bnez	a5,ffffffffc020398c <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02039b6:	01b05963          	blez	s11,ffffffffc02039c8 <vprintfmt+0x244>
ffffffffc02039ba:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02039bc:	85a6                	mv	a1,s1
ffffffffc02039be:	02000513          	li	a0,32
ffffffffc02039c2:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02039c4:	fe0d9be3          	bnez	s11,ffffffffc02039ba <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02039c8:	6a02                	ld	s4,0(sp)
ffffffffc02039ca:	bbd5                	j	ffffffffc02037be <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02039cc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02039ce:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02039d2:	01174463          	blt	a4,a7,ffffffffc02039da <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02039d6:	08088d63          	beqz	a7,ffffffffc0203a70 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02039da:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02039de:	0a044d63          	bltz	s0,ffffffffc0203a98 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02039e2:	8622                	mv	a2,s0
ffffffffc02039e4:	8a66                	mv	s4,s9
ffffffffc02039e6:	46a9                	li	a3,10
ffffffffc02039e8:	bdcd                	j	ffffffffc02038da <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02039ea:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02039ee:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02039f0:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02039f2:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02039f6:	8fb5                	xor	a5,a5,a3
ffffffffc02039f8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02039fc:	02d74163          	blt	a4,a3,ffffffffc0203a1e <vprintfmt+0x29a>
ffffffffc0203a00:	00369793          	slli	a5,a3,0x3
ffffffffc0203a04:	97de                	add	a5,a5,s7
ffffffffc0203a06:	639c                	ld	a5,0(a5)
ffffffffc0203a08:	cb99                	beqz	a5,ffffffffc0203a1e <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203a0a:	86be                	mv	a3,a5
ffffffffc0203a0c:	00000617          	auipc	a2,0x0
ffffffffc0203a10:	13c60613          	addi	a2,a2,316 # ffffffffc0203b48 <etext+0x2c>
ffffffffc0203a14:	85a6                	mv	a1,s1
ffffffffc0203a16:	854a                	mv	a0,s2
ffffffffc0203a18:	0ce000ef          	jal	ra,ffffffffc0203ae6 <printfmt>
ffffffffc0203a1c:	b34d                	j	ffffffffc02037be <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203a1e:	00002617          	auipc	a2,0x2
ffffffffc0203a22:	9da60613          	addi	a2,a2,-1574 # ffffffffc02053f8 <default_pmm_manager+0x1a0>
ffffffffc0203a26:	85a6                	mv	a1,s1
ffffffffc0203a28:	854a                	mv	a0,s2
ffffffffc0203a2a:	0bc000ef          	jal	ra,ffffffffc0203ae6 <printfmt>
ffffffffc0203a2e:	bb41                	j	ffffffffc02037be <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0203a30:	00002417          	auipc	s0,0x2
ffffffffc0203a34:	9c040413          	addi	s0,s0,-1600 # ffffffffc02053f0 <default_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203a38:	85e2                	mv	a1,s8
ffffffffc0203a3a:	8522                	mv	a0,s0
ffffffffc0203a3c:	e43e                	sd	a5,8(sp)
ffffffffc0203a3e:	c05ff0ef          	jal	ra,ffffffffc0203642 <strnlen>
ffffffffc0203a42:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0203a46:	01b05b63          	blez	s11,ffffffffc0203a5c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0203a4a:	67a2                	ld	a5,8(sp)
ffffffffc0203a4c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203a50:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0203a52:	85a6                	mv	a1,s1
ffffffffc0203a54:	8552                	mv	a0,s4
ffffffffc0203a56:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203a58:	fe0d9ce3          	bnez	s11,ffffffffc0203a50 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203a5c:	00044783          	lbu	a5,0(s0)
ffffffffc0203a60:	00140a13          	addi	s4,s0,1
ffffffffc0203a64:	0007851b          	sext.w	a0,a5
ffffffffc0203a68:	d3a5                	beqz	a5,ffffffffc02039c8 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203a6a:	05e00413          	li	s0,94
ffffffffc0203a6e:	bf39                	j	ffffffffc020398c <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0203a70:	000a2403          	lw	s0,0(s4)
ffffffffc0203a74:	b7ad                	j	ffffffffc02039de <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0203a76:	000a6603          	lwu	a2,0(s4)
ffffffffc0203a7a:	46a1                	li	a3,8
ffffffffc0203a7c:	8a2e                	mv	s4,a1
ffffffffc0203a7e:	bdb1                	j	ffffffffc02038da <vprintfmt+0x156>
ffffffffc0203a80:	000a6603          	lwu	a2,0(s4)
ffffffffc0203a84:	46a9                	li	a3,10
ffffffffc0203a86:	8a2e                	mv	s4,a1
ffffffffc0203a88:	bd89                	j	ffffffffc02038da <vprintfmt+0x156>
ffffffffc0203a8a:	000a6603          	lwu	a2,0(s4)
ffffffffc0203a8e:	46c1                	li	a3,16
ffffffffc0203a90:	8a2e                	mv	s4,a1
ffffffffc0203a92:	b5a1                	j	ffffffffc02038da <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0203a94:	9902                	jalr	s2
ffffffffc0203a96:	bf09                	j	ffffffffc02039a8 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0203a98:	85a6                	mv	a1,s1
ffffffffc0203a9a:	02d00513          	li	a0,45
ffffffffc0203a9e:	e03e                	sd	a5,0(sp)
ffffffffc0203aa0:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0203aa2:	6782                	ld	a5,0(sp)
ffffffffc0203aa4:	8a66                	mv	s4,s9
ffffffffc0203aa6:	40800633          	neg	a2,s0
ffffffffc0203aaa:	46a9                	li	a3,10
ffffffffc0203aac:	b53d                	j	ffffffffc02038da <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0203aae:	03b05163          	blez	s11,ffffffffc0203ad0 <vprintfmt+0x34c>
ffffffffc0203ab2:	02d00693          	li	a3,45
ffffffffc0203ab6:	f6d79de3          	bne	a5,a3,ffffffffc0203a30 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0203aba:	00002417          	auipc	s0,0x2
ffffffffc0203abe:	93640413          	addi	s0,s0,-1738 # ffffffffc02053f0 <default_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203ac2:	02800793          	li	a5,40
ffffffffc0203ac6:	02800513          	li	a0,40
ffffffffc0203aca:	00140a13          	addi	s4,s0,1
ffffffffc0203ace:	bd6d                	j	ffffffffc0203988 <vprintfmt+0x204>
ffffffffc0203ad0:	00002a17          	auipc	s4,0x2
ffffffffc0203ad4:	921a0a13          	addi	s4,s4,-1759 # ffffffffc02053f1 <default_pmm_manager+0x199>
ffffffffc0203ad8:	02800513          	li	a0,40
ffffffffc0203adc:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203ae0:	05e00413          	li	s0,94
ffffffffc0203ae4:	b565                	j	ffffffffc020398c <vprintfmt+0x208>

ffffffffc0203ae6 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203ae6:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203ae8:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203aec:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203aee:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203af0:	ec06                	sd	ra,24(sp)
ffffffffc0203af2:	f83a                	sd	a4,48(sp)
ffffffffc0203af4:	fc3e                	sd	a5,56(sp)
ffffffffc0203af6:	e0c2                	sd	a6,64(sp)
ffffffffc0203af8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203afa:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203afc:	c89ff0ef          	jal	ra,ffffffffc0203784 <vprintfmt>
}
ffffffffc0203b00:	60e2                	ld	ra,24(sp)
ffffffffc0203b02:	6161                	addi	sp,sp,80
ffffffffc0203b04:	8082                	ret

ffffffffc0203b06 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0203b06:	9e3707b7          	lui	a5,0x9e370
ffffffffc0203b0a:	2785                	addiw	a5,a5,1
ffffffffc0203b0c:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0203b10:	02000793          	li	a5,32
ffffffffc0203b14:	9f8d                	subw	a5,a5,a1
}
ffffffffc0203b16:	00f5553b          	srlw	a0,a0,a5
ffffffffc0203b1a:	8082                	ret
