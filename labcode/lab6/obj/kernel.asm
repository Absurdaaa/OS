
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000c297          	auipc	t0,0xc
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020c000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000c297          	auipc	t0,0xc
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020c008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020b2b7          	lui	t0,0xc020b
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
ffffffffc020003c:	c020b137          	lui	sp,0xc020b

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
ffffffffc020004a:	000cd517          	auipc	a0,0xcd
ffffffffc020004e:	77650513          	addi	a0,a0,1910 # ffffffffc02cd7c0 <buf>
ffffffffc0200052:	000d2617          	auipc	a2,0xd2
ffffffffc0200056:	c5660613          	addi	a2,a2,-938 # ffffffffc02d1ca8 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	555050ef          	jal	ra,ffffffffc0205db6 <memset>
    cons_init(); // init the console
ffffffffc0200066:	520000ef          	jal	ra,ffffffffc0200586 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006a:	00006597          	auipc	a1,0x6
ffffffffc020006e:	d7658593          	addi	a1,a1,-650 # ffffffffc0205de0 <etext>
ffffffffc0200072:	00006517          	auipc	a0,0x6
ffffffffc0200076:	d8e50513          	addi	a0,a0,-626 # ffffffffc0205e00 <etext+0x20>
ffffffffc020007a:	11e000ef          	jal	ra,ffffffffc0200198 <cprintf>

    print_kerninfo();
ffffffffc020007e:	1a2000ef          	jal	ra,ffffffffc0200220 <print_kerninfo>

    // grade_backtrace();

    dtb_init(); // init dtb
ffffffffc0200082:	576000ef          	jal	ra,ffffffffc02005f8 <dtb_init>

    pmm_init(); // init physical memory management
ffffffffc0200086:	628020ef          	jal	ra,ffffffffc02026ae <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	12b000ef          	jal	ra,ffffffffc02009b4 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	129000ef          	jal	ra,ffffffffc02009b6 <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc0200092:	02b030ef          	jal	ra,ffffffffc02038bc <vmm_init>
    sched_init();
ffffffffc0200096:	5b6050ef          	jal	ra,ffffffffc020564c <sched_init>
    proc_init(); // init process table
ffffffffc020009a:	643040ef          	jal	ra,ffffffffc0204edc <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009e:	4a0000ef          	jal	ra,ffffffffc020053e <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000a2:	107000ef          	jal	ra,ffffffffc02009a8 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a6:	7cf040ef          	jal	ra,ffffffffc0205074 <cpu_idle>

ffffffffc02000aa <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000aa:	715d                	addi	sp,sp,-80
ffffffffc02000ac:	e486                	sd	ra,72(sp)
ffffffffc02000ae:	e0a6                	sd	s1,64(sp)
ffffffffc02000b0:	fc4a                	sd	s2,56(sp)
ffffffffc02000b2:	f84e                	sd	s3,48(sp)
ffffffffc02000b4:	f452                	sd	s4,40(sp)
ffffffffc02000b6:	f056                	sd	s5,32(sp)
ffffffffc02000b8:	ec5a                	sd	s6,24(sp)
ffffffffc02000ba:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000bc:	c901                	beqz	a0,ffffffffc02000cc <readline+0x22>
ffffffffc02000be:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000c0:	00006517          	auipc	a0,0x6
ffffffffc02000c4:	d4850513          	addi	a0,a0,-696 # ffffffffc0205e08 <etext+0x28>
ffffffffc02000c8:	0d0000ef          	jal	ra,ffffffffc0200198 <cprintf>
readline(const char *prompt) {
ffffffffc02000cc:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ce:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d0:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000d2:	4aa9                	li	s5,10
ffffffffc02000d4:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d6:	000cdb97          	auipc	s7,0xcd
ffffffffc02000da:	6eab8b93          	addi	s7,s7,1770 # ffffffffc02cd7c0 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000de:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000e2:	12e000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc02000e6:	00054a63          	bltz	a0,ffffffffc02000fa <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ea:	00a95a63          	bge	s2,a0,ffffffffc02000fe <readline+0x54>
ffffffffc02000ee:	029a5263          	bge	s4,s1,ffffffffc0200112 <readline+0x68>
        c = getchar();
ffffffffc02000f2:	11e000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc02000f6:	fe055ae3          	bgez	a0,ffffffffc02000ea <readline+0x40>
            return NULL;
ffffffffc02000fa:	4501                	li	a0,0
ffffffffc02000fc:	a091                	j	ffffffffc0200140 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fe:	03351463          	bne	a0,s3,ffffffffc0200126 <readline+0x7c>
ffffffffc0200102:	e8a9                	bnez	s1,ffffffffc0200154 <readline+0xaa>
        c = getchar();
ffffffffc0200104:	10c000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc0200108:	fe0549e3          	bltz	a0,ffffffffc02000fa <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020010c:	fea959e3          	bge	s2,a0,ffffffffc02000fe <readline+0x54>
ffffffffc0200110:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200112:	e42a                	sd	a0,8(sp)
ffffffffc0200114:	0ba000ef          	jal	ra,ffffffffc02001ce <cputchar>
            buf[i ++] = c;
ffffffffc0200118:	6522                	ld	a0,8(sp)
ffffffffc020011a:	009b87b3          	add	a5,s7,s1
ffffffffc020011e:	2485                	addiw	s1,s1,1
ffffffffc0200120:	00a78023          	sb	a0,0(a5)
ffffffffc0200124:	bf7d                	j	ffffffffc02000e2 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200126:	01550463          	beq	a0,s5,ffffffffc020012e <readline+0x84>
ffffffffc020012a:	fb651ce3          	bne	a0,s6,ffffffffc02000e2 <readline+0x38>
            cputchar(c);
ffffffffc020012e:	0a0000ef          	jal	ra,ffffffffc02001ce <cputchar>
            buf[i] = '\0';
ffffffffc0200132:	000cd517          	auipc	a0,0xcd
ffffffffc0200136:	68e50513          	addi	a0,a0,1678 # ffffffffc02cd7c0 <buf>
ffffffffc020013a:	94aa                	add	s1,s1,a0
ffffffffc020013c:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200140:	60a6                	ld	ra,72(sp)
ffffffffc0200142:	6486                	ld	s1,64(sp)
ffffffffc0200144:	7962                	ld	s2,56(sp)
ffffffffc0200146:	79c2                	ld	s3,48(sp)
ffffffffc0200148:	7a22                	ld	s4,40(sp)
ffffffffc020014a:	7a82                	ld	s5,32(sp)
ffffffffc020014c:	6b62                	ld	s6,24(sp)
ffffffffc020014e:	6bc2                	ld	s7,16(sp)
ffffffffc0200150:	6161                	addi	sp,sp,80
ffffffffc0200152:	8082                	ret
            cputchar(c);
ffffffffc0200154:	4521                	li	a0,8
ffffffffc0200156:	078000ef          	jal	ra,ffffffffc02001ce <cputchar>
            i --;
ffffffffc020015a:	34fd                	addiw	s1,s1,-1
ffffffffc020015c:	b759                	j	ffffffffc02000e2 <readline+0x38>

ffffffffc020015e <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015e:	1141                	addi	sp,sp,-16
ffffffffc0200160:	e022                	sd	s0,0(sp)
ffffffffc0200162:	e406                	sd	ra,8(sp)
ffffffffc0200164:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200166:	422000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    (*cnt)++;
ffffffffc020016a:	401c                	lw	a5,0(s0)
}
ffffffffc020016c:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016e:	2785                	addiw	a5,a5,1
ffffffffc0200170:	c01c                	sw	a5,0(s0)
}
ffffffffc0200172:	6402                	ld	s0,0(sp)
ffffffffc0200174:	0141                	addi	sp,sp,16
ffffffffc0200176:	8082                	ret

ffffffffc0200178 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200178:	1101                	addi	sp,sp,-32
ffffffffc020017a:	862a                	mv	a2,a0
ffffffffc020017c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017e:	00000517          	auipc	a0,0x0
ffffffffc0200182:	fe050513          	addi	a0,a0,-32 # ffffffffc020015e <cputch>
ffffffffc0200186:	006c                	addi	a1,sp,12
{
ffffffffc0200188:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020018a:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020018c:	007050ef          	jal	ra,ffffffffc0205992 <vprintfmt>
    return cnt;
}
ffffffffc0200190:	60e2                	ld	ra,24(sp)
ffffffffc0200192:	4532                	lw	a0,12(sp)
ffffffffc0200194:	6105                	addi	sp,sp,32
ffffffffc0200196:	8082                	ret

ffffffffc0200198 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200198:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020019a:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
{
ffffffffc020019e:	8e2a                	mv	t3,a0
ffffffffc02001a0:	f42e                	sd	a1,40(sp)
ffffffffc02001a2:	f832                	sd	a2,48(sp)
ffffffffc02001a4:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a6:	00000517          	auipc	a0,0x0
ffffffffc02001aa:	fb850513          	addi	a0,a0,-72 # ffffffffc020015e <cputch>
ffffffffc02001ae:	004c                	addi	a1,sp,4
ffffffffc02001b0:	869a                	mv	a3,t1
ffffffffc02001b2:	8672                	mv	a2,t3
{
ffffffffc02001b4:	ec06                	sd	ra,24(sp)
ffffffffc02001b6:	e0ba                	sd	a4,64(sp)
ffffffffc02001b8:	e4be                	sd	a5,72(sp)
ffffffffc02001ba:	e8c2                	sd	a6,80(sp)
ffffffffc02001bc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001be:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001c0:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001c2:	7d0050ef          	jal	ra,ffffffffc0205992 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c6:	60e2                	ld	ra,24(sp)
ffffffffc02001c8:	4512                	lw	a0,4(sp)
ffffffffc02001ca:	6125                	addi	sp,sp,96
ffffffffc02001cc:	8082                	ret

ffffffffc02001ce <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ce:	ae6d                	j	ffffffffc0200588 <cons_putc>

ffffffffc02001d0 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001d0:	1101                	addi	sp,sp,-32
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	ec06                	sd	ra,24(sp)
ffffffffc02001d6:	e426                	sd	s1,8(sp)
ffffffffc02001d8:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001da:	00054503          	lbu	a0,0(a0)
ffffffffc02001de:	c51d                	beqz	a0,ffffffffc020020c <cputs+0x3c>
ffffffffc02001e0:	0405                	addi	s0,s0,1
ffffffffc02001e2:	4485                	li	s1,1
ffffffffc02001e4:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e6:	3a2000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001ea:	00044503          	lbu	a0,0(s0)
ffffffffc02001ee:	008487bb          	addw	a5,s1,s0
ffffffffc02001f2:	0405                	addi	s0,s0,1
ffffffffc02001f4:	f96d                	bnez	a0,ffffffffc02001e6 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f6:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001fa:	4529                	li	a0,10
ffffffffc02001fc:	38c000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200200:	60e2                	ld	ra,24(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	6442                	ld	s0,16(sp)
ffffffffc0200206:	64a2                	ld	s1,8(sp)
ffffffffc0200208:	6105                	addi	sp,sp,32
ffffffffc020020a:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc020020c:	4405                	li	s0,1
ffffffffc020020e:	b7f5                	j	ffffffffc02001fa <cputs+0x2a>

ffffffffc0200210 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc0200210:	1141                	addi	sp,sp,-16
ffffffffc0200212:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200214:	3a8000ef          	jal	ra,ffffffffc02005bc <cons_getc>
ffffffffc0200218:	dd75                	beqz	a0,ffffffffc0200214 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020021a:	60a2                	ld	ra,8(sp)
ffffffffc020021c:	0141                	addi	sp,sp,16
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200220:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200222:	00006517          	auipc	a0,0x6
ffffffffc0200226:	bee50513          	addi	a0,a0,-1042 # ffffffffc0205e10 <etext+0x30>
void print_kerninfo(void) {
ffffffffc020022a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020022c:	f6dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200230:	00000597          	auipc	a1,0x0
ffffffffc0200234:	e1a58593          	addi	a1,a1,-486 # ffffffffc020004a <kern_init>
ffffffffc0200238:	00006517          	auipc	a0,0x6
ffffffffc020023c:	bf850513          	addi	a0,a0,-1032 # ffffffffc0205e30 <etext+0x50>
ffffffffc0200240:	f59ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200244:	00006597          	auipc	a1,0x6
ffffffffc0200248:	b9c58593          	addi	a1,a1,-1124 # ffffffffc0205de0 <etext>
ffffffffc020024c:	00006517          	auipc	a0,0x6
ffffffffc0200250:	c0450513          	addi	a0,a0,-1020 # ffffffffc0205e50 <etext+0x70>
ffffffffc0200254:	f45ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200258:	000cd597          	auipc	a1,0xcd
ffffffffc020025c:	56858593          	addi	a1,a1,1384 # ffffffffc02cd7c0 <buf>
ffffffffc0200260:	00006517          	auipc	a0,0x6
ffffffffc0200264:	c1050513          	addi	a0,a0,-1008 # ffffffffc0205e70 <etext+0x90>
ffffffffc0200268:	f31ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc020026c:	000d2597          	auipc	a1,0xd2
ffffffffc0200270:	a3c58593          	addi	a1,a1,-1476 # ffffffffc02d1ca8 <end>
ffffffffc0200274:	00006517          	auipc	a0,0x6
ffffffffc0200278:	c1c50513          	addi	a0,a0,-996 # ffffffffc0205e90 <etext+0xb0>
ffffffffc020027c:	f1dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200280:	000d2597          	auipc	a1,0xd2
ffffffffc0200284:	e2758593          	addi	a1,a1,-473 # ffffffffc02d20a7 <end+0x3ff>
ffffffffc0200288:	00000797          	auipc	a5,0x0
ffffffffc020028c:	dc278793          	addi	a5,a5,-574 # ffffffffc020004a <kern_init>
ffffffffc0200290:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200294:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200298:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029a:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029e:	95be                	add	a1,a1,a5
ffffffffc02002a0:	85a9                	srai	a1,a1,0xa
ffffffffc02002a2:	00006517          	auipc	a0,0x6
ffffffffc02002a6:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0205eb0 <etext+0xd0>
}
ffffffffc02002aa:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002ac:	b5f5                	j	ffffffffc0200198 <cprintf>

ffffffffc02002ae <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002ae:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b0:	00006617          	auipc	a2,0x6
ffffffffc02002b4:	c3060613          	addi	a2,a2,-976 # ffffffffc0205ee0 <etext+0x100>
ffffffffc02002b8:	04d00593          	li	a1,77
ffffffffc02002bc:	00006517          	auipc	a0,0x6
ffffffffc02002c0:	c3c50513          	addi	a0,a0,-964 # ffffffffc0205ef8 <etext+0x118>
void print_stackframe(void) {
ffffffffc02002c4:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c6:	1cc000ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02002ca <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002ca:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002cc:	00006617          	auipc	a2,0x6
ffffffffc02002d0:	c4460613          	addi	a2,a2,-956 # ffffffffc0205f10 <etext+0x130>
ffffffffc02002d4:	00006597          	auipc	a1,0x6
ffffffffc02002d8:	c5c58593          	addi	a1,a1,-932 # ffffffffc0205f30 <etext+0x150>
ffffffffc02002dc:	00006517          	auipc	a0,0x6
ffffffffc02002e0:	c5c50513          	addi	a0,a0,-932 # ffffffffc0205f38 <etext+0x158>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e4:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	eb3ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc02002ea:	00006617          	auipc	a2,0x6
ffffffffc02002ee:	c5e60613          	addi	a2,a2,-930 # ffffffffc0205f48 <etext+0x168>
ffffffffc02002f2:	00006597          	auipc	a1,0x6
ffffffffc02002f6:	c7e58593          	addi	a1,a1,-898 # ffffffffc0205f70 <etext+0x190>
ffffffffc02002fa:	00006517          	auipc	a0,0x6
ffffffffc02002fe:	c3e50513          	addi	a0,a0,-962 # ffffffffc0205f38 <etext+0x158>
ffffffffc0200302:	e97ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0200306:	00006617          	auipc	a2,0x6
ffffffffc020030a:	c7a60613          	addi	a2,a2,-902 # ffffffffc0205f80 <etext+0x1a0>
ffffffffc020030e:	00006597          	auipc	a1,0x6
ffffffffc0200312:	c9258593          	addi	a1,a1,-878 # ffffffffc0205fa0 <etext+0x1c0>
ffffffffc0200316:	00006517          	auipc	a0,0x6
ffffffffc020031a:	c2250513          	addi	a0,a0,-990 # ffffffffc0205f38 <etext+0x158>
ffffffffc020031e:	e7bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    }
    return 0;
}
ffffffffc0200322:	60a2                	ld	ra,8(sp)
ffffffffc0200324:	4501                	li	a0,0
ffffffffc0200326:	0141                	addi	sp,sp,16
ffffffffc0200328:	8082                	ret

ffffffffc020032a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020032a:	1141                	addi	sp,sp,-16
ffffffffc020032c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032e:	ef3ff0ef          	jal	ra,ffffffffc0200220 <print_kerninfo>
    return 0;
}
ffffffffc0200332:	60a2                	ld	ra,8(sp)
ffffffffc0200334:	4501                	li	a0,0
ffffffffc0200336:	0141                	addi	sp,sp,16
ffffffffc0200338:	8082                	ret

ffffffffc020033a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020033a:	1141                	addi	sp,sp,-16
ffffffffc020033c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033e:	f71ff0ef          	jal	ra,ffffffffc02002ae <print_stackframe>
    return 0;
}
ffffffffc0200342:	60a2                	ld	ra,8(sp)
ffffffffc0200344:	4501                	li	a0,0
ffffffffc0200346:	0141                	addi	sp,sp,16
ffffffffc0200348:	8082                	ret

ffffffffc020034a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020034a:	7115                	addi	sp,sp,-224
ffffffffc020034c:	ed5e                	sd	s7,152(sp)
ffffffffc020034e:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200350:	00006517          	auipc	a0,0x6
ffffffffc0200354:	c6050513          	addi	a0,a0,-928 # ffffffffc0205fb0 <etext+0x1d0>
kmonitor(struct trapframe *tf) {
ffffffffc0200358:	ed86                	sd	ra,216(sp)
ffffffffc020035a:	e9a2                	sd	s0,208(sp)
ffffffffc020035c:	e5a6                	sd	s1,200(sp)
ffffffffc020035e:	e1ca                	sd	s2,192(sp)
ffffffffc0200360:	fd4e                	sd	s3,184(sp)
ffffffffc0200362:	f952                	sd	s4,176(sp)
ffffffffc0200364:	f556                	sd	s5,168(sp)
ffffffffc0200366:	f15a                	sd	s6,160(sp)
ffffffffc0200368:	e962                	sd	s8,144(sp)
ffffffffc020036a:	e566                	sd	s9,136(sp)
ffffffffc020036c:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036e:	e2bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200372:	00006517          	auipc	a0,0x6
ffffffffc0200376:	c6650513          	addi	a0,a0,-922 # ffffffffc0205fd8 <etext+0x1f8>
ffffffffc020037a:	e1fff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (tf != NULL) {
ffffffffc020037e:	000b8563          	beqz	s7,ffffffffc0200388 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200382:	855e                	mv	a0,s7
ffffffffc0200384:	01b000ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
ffffffffc0200388:	00006c17          	auipc	s8,0x6
ffffffffc020038c:	cc0c0c13          	addi	s8,s8,-832 # ffffffffc0206048 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200390:	00006917          	auipc	s2,0x6
ffffffffc0200394:	c7090913          	addi	s2,s2,-912 # ffffffffc0206000 <etext+0x220>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200398:	00006497          	auipc	s1,0x6
ffffffffc020039c:	c7048493          	addi	s1,s1,-912 # ffffffffc0206008 <etext+0x228>
        if (argc == MAXARGS - 1) {
ffffffffc02003a0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003a2:	00006b17          	auipc	s6,0x6
ffffffffc02003a6:	c6eb0b13          	addi	s6,s6,-914 # ffffffffc0206010 <etext+0x230>
        argv[argc ++] = buf;
ffffffffc02003aa:	00006a17          	auipc	s4,0x6
ffffffffc02003ae:	b86a0a13          	addi	s4,s4,-1146 # ffffffffc0205f30 <etext+0x150>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b2:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003b4:	854a                	mv	a0,s2
ffffffffc02003b6:	cf5ff0ef          	jal	ra,ffffffffc02000aa <readline>
ffffffffc02003ba:	842a                	mv	s0,a0
ffffffffc02003bc:	dd65                	beqz	a0,ffffffffc02003b4 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003be:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003c2:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c4:	e1bd                	bnez	a1,ffffffffc020042a <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02003c6:	fe0c87e3          	beqz	s9,ffffffffc02003b4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ca:	6582                	ld	a1,0(sp)
ffffffffc02003cc:	00006d17          	auipc	s10,0x6
ffffffffc02003d0:	c7cd0d13          	addi	s10,s10,-900 # ffffffffc0206048 <commands>
        argv[argc ++] = buf;
ffffffffc02003d4:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d6:	4401                	li	s0,0
ffffffffc02003d8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003da:	183050ef          	jal	ra,ffffffffc0205d5c <strcmp>
ffffffffc02003de:	c919                	beqz	a0,ffffffffc02003f4 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003e0:	2405                	addiw	s0,s0,1
ffffffffc02003e2:	0b540063          	beq	s0,s5,ffffffffc0200482 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003e6:	000d3503          	ld	a0,0(s10)
ffffffffc02003ea:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003ec:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ee:	16f050ef          	jal	ra,ffffffffc0205d5c <strcmp>
ffffffffc02003f2:	f57d                	bnez	a0,ffffffffc02003e0 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f4:	00141793          	slli	a5,s0,0x1
ffffffffc02003f8:	97a2                	add	a5,a5,s0
ffffffffc02003fa:	078e                	slli	a5,a5,0x3
ffffffffc02003fc:	97e2                	add	a5,a5,s8
ffffffffc02003fe:	6b9c                	ld	a5,16(a5)
ffffffffc0200400:	865e                	mv	a2,s7
ffffffffc0200402:	002c                	addi	a1,sp,8
ffffffffc0200404:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200408:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020040a:	fa0555e3          	bgez	a0,ffffffffc02003b4 <kmonitor+0x6a>
}
ffffffffc020040e:	60ee                	ld	ra,216(sp)
ffffffffc0200410:	644e                	ld	s0,208(sp)
ffffffffc0200412:	64ae                	ld	s1,200(sp)
ffffffffc0200414:	690e                	ld	s2,192(sp)
ffffffffc0200416:	79ea                	ld	s3,184(sp)
ffffffffc0200418:	7a4a                	ld	s4,176(sp)
ffffffffc020041a:	7aaa                	ld	s5,168(sp)
ffffffffc020041c:	7b0a                	ld	s6,160(sp)
ffffffffc020041e:	6bea                	ld	s7,152(sp)
ffffffffc0200420:	6c4a                	ld	s8,144(sp)
ffffffffc0200422:	6caa                	ld	s9,136(sp)
ffffffffc0200424:	6d0a                	ld	s10,128(sp)
ffffffffc0200426:	612d                	addi	sp,sp,224
ffffffffc0200428:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020042a:	8526                	mv	a0,s1
ffffffffc020042c:	175050ef          	jal	ra,ffffffffc0205da0 <strchr>
ffffffffc0200430:	c901                	beqz	a0,ffffffffc0200440 <kmonitor+0xf6>
ffffffffc0200432:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200436:	00040023          	sb	zero,0(s0)
ffffffffc020043a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020043c:	d5c9                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc020043e:	b7f5                	j	ffffffffc020042a <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200440:	00044783          	lbu	a5,0(s0)
ffffffffc0200444:	d3c9                	beqz	a5,ffffffffc02003c6 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200446:	033c8963          	beq	s9,s3,ffffffffc0200478 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc020044a:	003c9793          	slli	a5,s9,0x3
ffffffffc020044e:	0118                	addi	a4,sp,128
ffffffffc0200450:	97ba                	add	a5,a5,a4
ffffffffc0200452:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200456:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020045a:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020045c:	e591                	bnez	a1,ffffffffc0200468 <kmonitor+0x11e>
ffffffffc020045e:	b7b5                	j	ffffffffc02003ca <kmonitor+0x80>
ffffffffc0200460:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200464:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200466:	d1a5                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc0200468:	8526                	mv	a0,s1
ffffffffc020046a:	137050ef          	jal	ra,ffffffffc0205da0 <strchr>
ffffffffc020046e:	d96d                	beqz	a0,ffffffffc0200460 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200470:	00044583          	lbu	a1,0(s0)
ffffffffc0200474:	d9a9                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc0200476:	bf55                	j	ffffffffc020042a <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200478:	45c1                	li	a1,16
ffffffffc020047a:	855a                	mv	a0,s6
ffffffffc020047c:	d1dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0200480:	b7e9                	j	ffffffffc020044a <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200482:	6582                	ld	a1,0(sp)
ffffffffc0200484:	00006517          	auipc	a0,0x6
ffffffffc0200488:	bac50513          	addi	a0,a0,-1108 # ffffffffc0206030 <etext+0x250>
ffffffffc020048c:	d0dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;
ffffffffc0200490:	b715                	j	ffffffffc02003b4 <kmonitor+0x6a>

ffffffffc0200492 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200492:	000d1317          	auipc	t1,0xd1
ffffffffc0200496:	78630313          	addi	t1,t1,1926 # ffffffffc02d1c18 <is_panic>
ffffffffc020049a:	00033e03          	ld	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020049e:	715d                	addi	sp,sp,-80
ffffffffc02004a0:	ec06                	sd	ra,24(sp)
ffffffffc02004a2:	e822                	sd	s0,16(sp)
ffffffffc02004a4:	f436                	sd	a3,40(sp)
ffffffffc02004a6:	f83a                	sd	a4,48(sp)
ffffffffc02004a8:	fc3e                	sd	a5,56(sp)
ffffffffc02004aa:	e0c2                	sd	a6,64(sp)
ffffffffc02004ac:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02004ae:	020e1a63          	bnez	t3,ffffffffc02004e2 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004b2:	4785                	li	a5,1
ffffffffc02004b4:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b8:	8432                	mv	s0,a2
ffffffffc02004ba:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004bc:	862e                	mv	a2,a1
ffffffffc02004be:	85aa                	mv	a1,a0
ffffffffc02004c0:	00006517          	auipc	a0,0x6
ffffffffc02004c4:	bd050513          	addi	a0,a0,-1072 # ffffffffc0206090 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c8:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004ca:	ccfff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ce:	65a2                	ld	a1,8(sp)
ffffffffc02004d0:	8522                	mv	a0,s0
ffffffffc02004d2:	ca7ff0ef          	jal	ra,ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc02004d6:	00007517          	auipc	a0,0x7
ffffffffc02004da:	cd250513          	addi	a0,a0,-814 # ffffffffc02071a8 <default_pmm_manager+0x578>
ffffffffc02004de:	cbbff0ef          	jal	ra,ffffffffc0200198 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004e2:	4501                	li	a0,0
ffffffffc02004e4:	4581                	li	a1,0
ffffffffc02004e6:	4601                	li	a2,0
ffffffffc02004e8:	48a1                	li	a7,8
ffffffffc02004ea:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ee:	4c0000ef          	jal	ra,ffffffffc02009ae <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004f2:	4501                	li	a0,0
ffffffffc02004f4:	e57ff0ef          	jal	ra,ffffffffc020034a <kmonitor>
    while (1) {
ffffffffc02004f8:	bfed                	j	ffffffffc02004f2 <__panic+0x60>

ffffffffc02004fa <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004fa:	715d                	addi	sp,sp,-80
ffffffffc02004fc:	832e                	mv	t1,a1
ffffffffc02004fe:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200500:	85aa                	mv	a1,a0
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200502:	8432                	mv	s0,a2
ffffffffc0200504:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200508:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020050a:	00006517          	auipc	a0,0x6
ffffffffc020050e:	ba650513          	addi	a0,a0,-1114 # ffffffffc02060b0 <commands+0x68>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200512:	ec06                	sd	ra,24(sp)
ffffffffc0200514:	f436                	sd	a3,40(sp)
ffffffffc0200516:	f83a                	sd	a4,48(sp)
ffffffffc0200518:	e0c2                	sd	a6,64(sp)
ffffffffc020051a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020051c:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051e:	c7bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200522:	65a2                	ld	a1,8(sp)
ffffffffc0200524:	8522                	mv	a0,s0
ffffffffc0200526:	c53ff0ef          	jal	ra,ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc020052a:	00007517          	auipc	a0,0x7
ffffffffc020052e:	c7e50513          	addi	a0,a0,-898 # ffffffffc02071a8 <default_pmm_manager+0x578>
ffffffffc0200532:	c67ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    va_end(ap);
}
ffffffffc0200536:	60e2                	ld	ra,24(sp)
ffffffffc0200538:	6442                	ld	s0,16(sp)
ffffffffc020053a:	6161                	addi	sp,sp,80
ffffffffc020053c:	8082                	ret

ffffffffc020053e <clock_init>:
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void)
{
    set_csr(sie, MIP_STIP);
ffffffffc020053e:	02000793          	li	a5,32
ffffffffc0200542:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200546:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054a:	67e1                	lui	a5,0x18
ffffffffc020054c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbf90>
ffffffffc0200550:	953e                	add	a0,a0,a5
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200552:	4581                	li	a1,0
ffffffffc0200554:	4601                	li	a2,0
ffffffffc0200556:	4881                	li	a7,0
ffffffffc0200558:	00000073          	ecall
    cprintf("++ setup timer interrupts\n");
ffffffffc020055c:	00006517          	auipc	a0,0x6
ffffffffc0200560:	b7450513          	addi	a0,a0,-1164 # ffffffffc02060d0 <commands+0x88>
    ticks = 0;
ffffffffc0200564:	000d1797          	auipc	a5,0xd1
ffffffffc0200568:	6a07be23          	sd	zero,1724(a5) # ffffffffc02d1c20 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020056c:	b135                	j	ffffffffc0200198 <cprintf>

ffffffffc020056e <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020056e:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200572:	67e1                	lui	a5,0x18
ffffffffc0200574:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbf90>
ffffffffc0200578:	953e                	add	a0,a0,a5
ffffffffc020057a:	4581                	li	a1,0
ffffffffc020057c:	4601                	li	a2,0
ffffffffc020057e:	4881                	li	a7,0
ffffffffc0200580:	00000073          	ecall
ffffffffc0200584:	8082                	ret

ffffffffc0200586 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200586:	8082                	ret

ffffffffc0200588 <cons_putc>:
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200588:	100027f3          	csrr	a5,sstatus
ffffffffc020058c:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020058e:	0ff57513          	zext.b	a0,a0
ffffffffc0200592:	e799                	bnez	a5,ffffffffc02005a0 <cons_putc+0x18>
ffffffffc0200594:	4581                	li	a1,0
ffffffffc0200596:	4601                	li	a2,0
ffffffffc0200598:	4885                	li	a7,1
ffffffffc020059a:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc020059e:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a0:	1101                	addi	sp,sp,-32
ffffffffc02005a2:	ec06                	sd	ra,24(sp)
ffffffffc02005a4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005a6:	408000ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02005aa:	6522                	ld	a0,8(sp)
ffffffffc02005ac:	4581                	li	a1,0
ffffffffc02005ae:	4601                	li	a2,0
ffffffffc02005b0:	4885                	li	a7,1
ffffffffc02005b2:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005b6:	60e2                	ld	ra,24(sp)
ffffffffc02005b8:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005ba:	a6fd                	j	ffffffffc02009a8 <intr_enable>

ffffffffc02005bc <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005bc:	100027f3          	csrr	a5,sstatus
ffffffffc02005c0:	8b89                	andi	a5,a5,2
ffffffffc02005c2:	eb89                	bnez	a5,ffffffffc02005d4 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005c4:	4501                	li	a0,0
ffffffffc02005c6:	4581                	li	a1,0
ffffffffc02005c8:	4601                	li	a2,0
ffffffffc02005ca:	4889                	li	a7,2
ffffffffc02005cc:	00000073          	ecall
ffffffffc02005d0:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d2:	8082                	ret
int cons_getc(void) {
ffffffffc02005d4:	1101                	addi	sp,sp,-32
ffffffffc02005d6:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005d8:	3d6000ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02005dc:	4501                	li	a0,0
ffffffffc02005de:	4581                	li	a1,0
ffffffffc02005e0:	4601                	li	a2,0
ffffffffc02005e2:	4889                	li	a7,2
ffffffffc02005e4:	00000073          	ecall
ffffffffc02005e8:	2501                	sext.w	a0,a0
ffffffffc02005ea:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005ec:	3bc000ef          	jal	ra,ffffffffc02009a8 <intr_enable>
}
ffffffffc02005f0:	60e2                	ld	ra,24(sp)
ffffffffc02005f2:	6522                	ld	a0,8(sp)
ffffffffc02005f4:	6105                	addi	sp,sp,32
ffffffffc02005f6:	8082                	ret

ffffffffc02005f8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005f8:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02005fa:	00006517          	auipc	a0,0x6
ffffffffc02005fe:	af650513          	addi	a0,a0,-1290 # ffffffffc02060f0 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200602:	fc86                	sd	ra,120(sp)
ffffffffc0200604:	f8a2                	sd	s0,112(sp)
ffffffffc0200606:	e8d2                	sd	s4,80(sp)
ffffffffc0200608:	f4a6                	sd	s1,104(sp)
ffffffffc020060a:	f0ca                	sd	s2,96(sp)
ffffffffc020060c:	ecce                	sd	s3,88(sp)
ffffffffc020060e:	e4d6                	sd	s5,72(sp)
ffffffffc0200610:	e0da                	sd	s6,64(sp)
ffffffffc0200612:	fc5e                	sd	s7,56(sp)
ffffffffc0200614:	f862                	sd	s8,48(sp)
ffffffffc0200616:	f466                	sd	s9,40(sp)
ffffffffc0200618:	f06a                	sd	s10,32(sp)
ffffffffc020061a:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020061c:	b7dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200620:	0000c597          	auipc	a1,0xc
ffffffffc0200624:	9e05b583          	ld	a1,-1568(a1) # ffffffffc020c000 <boot_hartid>
ffffffffc0200628:	00006517          	auipc	a0,0x6
ffffffffc020062c:	ad850513          	addi	a0,a0,-1320 # ffffffffc0206100 <commands+0xb8>
ffffffffc0200630:	b69ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200634:	0000c417          	auipc	s0,0xc
ffffffffc0200638:	9d440413          	addi	s0,s0,-1580 # ffffffffc020c008 <boot_dtb>
ffffffffc020063c:	600c                	ld	a1,0(s0)
ffffffffc020063e:	00006517          	auipc	a0,0x6
ffffffffc0200642:	ad250513          	addi	a0,a0,-1326 # ffffffffc0206110 <commands+0xc8>
ffffffffc0200646:	b53ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020064a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020064e:	00006517          	auipc	a0,0x6
ffffffffc0200652:	ada50513          	addi	a0,a0,-1318 # ffffffffc0206128 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc0200656:	120a0463          	beqz	s4,ffffffffc020077e <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020065a:	57f5                	li	a5,-3
ffffffffc020065c:	07fa                	slli	a5,a5,0x1e
ffffffffc020065e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200662:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200664:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200668:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020066e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200672:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200676:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067e:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	8ec9                	or	a3,a3,a0
ffffffffc0200682:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200686:	1b7d                	addi	s6,s6,-1
ffffffffc0200688:	0167f7b3          	and	a5,a5,s6
ffffffffc020068c:	8dd5                	or	a1,a1,a3
ffffffffc020068e:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200690:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200694:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe0e245>
ffffffffc020069a:	10f59163          	bne	a1,a5,ffffffffc020079c <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020069e:	471c                	lw	a5,8(a4)
ffffffffc02006a0:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a2:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a4:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006a8:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006ac:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006bc:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c0:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c4:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c8:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006cc:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	01146433          	or	s0,s0,a7
ffffffffc02006d2:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006d6:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006da:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006dc:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e0:	8c49                	or	s0,s0,a0
ffffffffc02006e2:	0166f6b3          	and	a3,a3,s6
ffffffffc02006e6:	00ca6a33          	or	s4,s4,a2
ffffffffc02006ea:	0167f7b3          	and	a5,a5,s6
ffffffffc02006ee:	8c55                	or	s0,s0,a3
ffffffffc02006f0:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006f4:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006f6:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006f8:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fa:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200702:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200706:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200708:	00006917          	auipc	s2,0x6
ffffffffc020070c:	a7090913          	addi	s2,s2,-1424 # ffffffffc0206178 <commands+0x130>
ffffffffc0200710:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200712:	4d91                	li	s11,4
ffffffffc0200714:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200716:	00006497          	auipc	s1,0x6
ffffffffc020071a:	a5a48493          	addi	s1,s1,-1446 # ffffffffc0206170 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020071e:	000a2703          	lw	a4,0(s4)
ffffffffc0200722:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0087569b          	srliw	a3,a4,0x8
ffffffffc020072a:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200732:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200736:	0107571b          	srliw	a4,a4,0x10
ffffffffc020073a:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073c:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200740:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200744:	8fd5                	or	a5,a5,a3
ffffffffc0200746:	00eb7733          	and	a4,s6,a4
ffffffffc020074a:	8fd9                	or	a5,a5,a4
ffffffffc020074c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020074e:	09778c63          	beq	a5,s7,ffffffffc02007e6 <dtb_init+0x1ee>
ffffffffc0200752:	00fbea63          	bltu	s7,a5,ffffffffc0200766 <dtb_init+0x16e>
ffffffffc0200756:	07a78663          	beq	a5,s10,ffffffffc02007c2 <dtb_init+0x1ca>
ffffffffc020075a:	4709                	li	a4,2
ffffffffc020075c:	00e79763          	bne	a5,a4,ffffffffc020076a <dtb_init+0x172>
ffffffffc0200760:	4c81                	li	s9,0
ffffffffc0200762:	8a56                	mv	s4,s5
ffffffffc0200764:	bf6d                	j	ffffffffc020071e <dtb_init+0x126>
ffffffffc0200766:	ffb78ee3          	beq	a5,s11,ffffffffc0200762 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020076a:	00006517          	auipc	a0,0x6
ffffffffc020076e:	a8650513          	addi	a0,a0,-1402 # ffffffffc02061f0 <commands+0x1a8>
ffffffffc0200772:	a27ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200776:	00006517          	auipc	a0,0x6
ffffffffc020077a:	ab250513          	addi	a0,a0,-1358 # ffffffffc0206228 <commands+0x1e0>
}
ffffffffc020077e:	7446                	ld	s0,112(sp)
ffffffffc0200780:	70e6                	ld	ra,120(sp)
ffffffffc0200782:	74a6                	ld	s1,104(sp)
ffffffffc0200784:	7906                	ld	s2,96(sp)
ffffffffc0200786:	69e6                	ld	s3,88(sp)
ffffffffc0200788:	6a46                	ld	s4,80(sp)
ffffffffc020078a:	6aa6                	ld	s5,72(sp)
ffffffffc020078c:	6b06                	ld	s6,64(sp)
ffffffffc020078e:	7be2                	ld	s7,56(sp)
ffffffffc0200790:	7c42                	ld	s8,48(sp)
ffffffffc0200792:	7ca2                	ld	s9,40(sp)
ffffffffc0200794:	7d02                	ld	s10,32(sp)
ffffffffc0200796:	6de2                	ld	s11,24(sp)
ffffffffc0200798:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020079a:	bafd                	j	ffffffffc0200198 <cprintf>
}
ffffffffc020079c:	7446                	ld	s0,112(sp)
ffffffffc020079e:	70e6                	ld	ra,120(sp)
ffffffffc02007a0:	74a6                	ld	s1,104(sp)
ffffffffc02007a2:	7906                	ld	s2,96(sp)
ffffffffc02007a4:	69e6                	ld	s3,88(sp)
ffffffffc02007a6:	6a46                	ld	s4,80(sp)
ffffffffc02007a8:	6aa6                	ld	s5,72(sp)
ffffffffc02007aa:	6b06                	ld	s6,64(sp)
ffffffffc02007ac:	7be2                	ld	s7,56(sp)
ffffffffc02007ae:	7c42                	ld	s8,48(sp)
ffffffffc02007b0:	7ca2                	ld	s9,40(sp)
ffffffffc02007b2:	7d02                	ld	s10,32(sp)
ffffffffc02007b4:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007b6:	00006517          	auipc	a0,0x6
ffffffffc02007ba:	99250513          	addi	a0,a0,-1646 # ffffffffc0206148 <commands+0x100>
}
ffffffffc02007be:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c0:	bae1                	j	ffffffffc0200198 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c2:	8556                	mv	a0,s5
ffffffffc02007c4:	550050ef          	jal	ra,ffffffffc0205d14 <strlen>
ffffffffc02007c8:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007ca:	4619                	li	a2,6
ffffffffc02007cc:	85a6                	mv	a1,s1
ffffffffc02007ce:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d0:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d2:	5a8050ef          	jal	ra,ffffffffc0205d7a <strncmp>
ffffffffc02007d6:	e111                	bnez	a0,ffffffffc02007da <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007d8:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007da:	0a91                	addi	s5,s5,4
ffffffffc02007dc:	9ad2                	add	s5,s5,s4
ffffffffc02007de:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e2:	8a56                	mv	s4,s5
ffffffffc02007e4:	bf2d                	j	ffffffffc020071e <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007e6:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ea:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ee:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f2:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007fa:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fe:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200802:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200806:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020080a:	0087979b          	slliw	a5,a5,0x8
ffffffffc020080e:	00eaeab3          	or	s5,s5,a4
ffffffffc0200812:	00fb77b3          	and	a5,s6,a5
ffffffffc0200816:	00faeab3          	or	s5,s5,a5
ffffffffc020081a:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020081c:	000c9c63          	bnez	s9,ffffffffc0200834 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200820:	1a82                	slli	s5,s5,0x20
ffffffffc0200822:	00368793          	addi	a5,a3,3
ffffffffc0200826:	020ada93          	srli	s5,s5,0x20
ffffffffc020082a:	9abe                	add	s5,s5,a5
ffffffffc020082c:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200830:	8a56                	mv	s4,s5
ffffffffc0200832:	b5f5                	j	ffffffffc020071e <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200834:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200838:	85ca                	mv	a1,s2
ffffffffc020083a:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020083c:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200840:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200844:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200848:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020084c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200850:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200852:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0087979b          	slliw	a5,a5,0x8
ffffffffc020085a:	8d59                	or	a0,a0,a4
ffffffffc020085c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200860:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200862:	1502                	slli	a0,a0,0x20
ffffffffc0200864:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200866:	9522                	add	a0,a0,s0
ffffffffc0200868:	4f4050ef          	jal	ra,ffffffffc0205d5c <strcmp>
ffffffffc020086c:	66a2                	ld	a3,8(sp)
ffffffffc020086e:	f94d                	bnez	a0,ffffffffc0200820 <dtb_init+0x228>
ffffffffc0200870:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200820 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200874:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200878:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020087c:	00006517          	auipc	a0,0x6
ffffffffc0200880:	90450513          	addi	a0,a0,-1788 # ffffffffc0206180 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc0200884:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200888:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020088c:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200890:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200894:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200898:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020089c:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a0:	0187d693          	srli	a3,a5,0x18
ffffffffc02008a4:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008a8:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008ac:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b0:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008b4:	010f6f33          	or	t5,t5,a6
ffffffffc02008b8:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008bc:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c0:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008c4:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c8:	0186f6b3          	and	a3,a3,s8
ffffffffc02008cc:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d0:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008d4:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008d8:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008dc:	8361                	srli	a4,a4,0x18
ffffffffc02008de:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e2:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008e6:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008ea:	00cb7633          	and	a2,s6,a2
ffffffffc02008ee:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f2:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008f6:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008fa:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008fe:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200902:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200906:	0088989b          	slliw	a7,a7,0x8
ffffffffc020090a:	011b78b3          	and	a7,s6,a7
ffffffffc020090e:	005eeeb3          	or	t4,t4,t0
ffffffffc0200912:	00c6e733          	or	a4,a3,a2
ffffffffc0200916:	006c6c33          	or	s8,s8,t1
ffffffffc020091a:	010b76b3          	and	a3,s6,a6
ffffffffc020091e:	00bb7b33          	and	s6,s6,a1
ffffffffc0200922:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200926:	016c6b33          	or	s6,s8,s6
ffffffffc020092a:	01146433          	or	s0,s0,a7
ffffffffc020092e:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200930:	1702                	slli	a4,a4,0x20
ffffffffc0200932:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200934:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200938:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093a:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	0167eb33          	or	s6,a5,s6
ffffffffc0200942:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200944:	855ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200948:	85a2                	mv	a1,s0
ffffffffc020094a:	00006517          	auipc	a0,0x6
ffffffffc020094e:	85650513          	addi	a0,a0,-1962 # ffffffffc02061a0 <commands+0x158>
ffffffffc0200952:	847ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200956:	014b5613          	srli	a2,s6,0x14
ffffffffc020095a:	85da                	mv	a1,s6
ffffffffc020095c:	00006517          	auipc	a0,0x6
ffffffffc0200960:	85c50513          	addi	a0,a0,-1956 # ffffffffc02061b8 <commands+0x170>
ffffffffc0200964:	835ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200968:	008b05b3          	add	a1,s6,s0
ffffffffc020096c:	15fd                	addi	a1,a1,-1
ffffffffc020096e:	00006517          	auipc	a0,0x6
ffffffffc0200972:	86a50513          	addi	a0,a0,-1942 # ffffffffc02061d8 <commands+0x190>
ffffffffc0200976:	823ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc020097a:	00006517          	auipc	a0,0x6
ffffffffc020097e:	8ae50513          	addi	a0,a0,-1874 # ffffffffc0206228 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200982:	000d1797          	auipc	a5,0xd1
ffffffffc0200986:	2a87b323          	sd	s0,678(a5) # ffffffffc02d1c28 <memory_base>
        memory_size = mem_size;
ffffffffc020098a:	000d1797          	auipc	a5,0xd1
ffffffffc020098e:	2b67b323          	sd	s6,678(a5) # ffffffffc02d1c30 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200992:	b3f5                	j	ffffffffc020077e <dtb_init+0x186>

ffffffffc0200994 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200994:	000d1517          	auipc	a0,0xd1
ffffffffc0200998:	29453503          	ld	a0,660(a0) # ffffffffc02d1c28 <memory_base>
ffffffffc020099c:	8082                	ret

ffffffffc020099e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020099e:	000d1517          	auipc	a0,0xd1
ffffffffc02009a2:	29253503          	ld	a0,658(a0) # ffffffffc02d1c30 <memory_size>
ffffffffc02009a6:	8082                	ret

ffffffffc02009a8 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009a8:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009b4:	8082                	ret

ffffffffc02009b6 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009b6:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009ba:	00000797          	auipc	a5,0x0
ffffffffc02009be:	4ca78793          	addi	a5,a5,1226 # ffffffffc0200e84 <__alltraps>
ffffffffc02009c2:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009c6:	000407b7          	lui	a5,0x40
ffffffffc02009ca:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009ce:	8082                	ret

ffffffffc02009d0 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d0:	610c                	ld	a1,0(a0)
{
ffffffffc02009d2:	1141                	addi	sp,sp,-16
ffffffffc02009d4:	e022                	sd	s0,0(sp)
ffffffffc02009d6:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d8:	00006517          	auipc	a0,0x6
ffffffffc02009dc:	86850513          	addi	a0,a0,-1944 # ffffffffc0206240 <commands+0x1f8>
{
ffffffffc02009e0:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e2:	fb6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009e6:	640c                	ld	a1,8(s0)
ffffffffc02009e8:	00006517          	auipc	a0,0x6
ffffffffc02009ec:	87050513          	addi	a0,a0,-1936 # ffffffffc0206258 <commands+0x210>
ffffffffc02009f0:	fa8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009f4:	680c                	ld	a1,16(s0)
ffffffffc02009f6:	00006517          	auipc	a0,0x6
ffffffffc02009fa:	87a50513          	addi	a0,a0,-1926 # ffffffffc0206270 <commands+0x228>
ffffffffc02009fe:	f9aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a02:	6c0c                	ld	a1,24(s0)
ffffffffc0200a04:	00006517          	auipc	a0,0x6
ffffffffc0200a08:	88450513          	addi	a0,a0,-1916 # ffffffffc0206288 <commands+0x240>
ffffffffc0200a0c:	f8cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a10:	700c                	ld	a1,32(s0)
ffffffffc0200a12:	00006517          	auipc	a0,0x6
ffffffffc0200a16:	88e50513          	addi	a0,a0,-1906 # ffffffffc02062a0 <commands+0x258>
ffffffffc0200a1a:	f7eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a1e:	740c                	ld	a1,40(s0)
ffffffffc0200a20:	00006517          	auipc	a0,0x6
ffffffffc0200a24:	89850513          	addi	a0,a0,-1896 # ffffffffc02062b8 <commands+0x270>
ffffffffc0200a28:	f70ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a2c:	780c                	ld	a1,48(s0)
ffffffffc0200a2e:	00006517          	auipc	a0,0x6
ffffffffc0200a32:	8a250513          	addi	a0,a0,-1886 # ffffffffc02062d0 <commands+0x288>
ffffffffc0200a36:	f62ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a3a:	7c0c                	ld	a1,56(s0)
ffffffffc0200a3c:	00006517          	auipc	a0,0x6
ffffffffc0200a40:	8ac50513          	addi	a0,a0,-1876 # ffffffffc02062e8 <commands+0x2a0>
ffffffffc0200a44:	f54ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a48:	602c                	ld	a1,64(s0)
ffffffffc0200a4a:	00006517          	auipc	a0,0x6
ffffffffc0200a4e:	8b650513          	addi	a0,a0,-1866 # ffffffffc0206300 <commands+0x2b8>
ffffffffc0200a52:	f46ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a56:	642c                	ld	a1,72(s0)
ffffffffc0200a58:	00006517          	auipc	a0,0x6
ffffffffc0200a5c:	8c050513          	addi	a0,a0,-1856 # ffffffffc0206318 <commands+0x2d0>
ffffffffc0200a60:	f38ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a64:	682c                	ld	a1,80(s0)
ffffffffc0200a66:	00006517          	auipc	a0,0x6
ffffffffc0200a6a:	8ca50513          	addi	a0,a0,-1846 # ffffffffc0206330 <commands+0x2e8>
ffffffffc0200a6e:	f2aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a72:	6c2c                	ld	a1,88(s0)
ffffffffc0200a74:	00006517          	auipc	a0,0x6
ffffffffc0200a78:	8d450513          	addi	a0,a0,-1836 # ffffffffc0206348 <commands+0x300>
ffffffffc0200a7c:	f1cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a80:	702c                	ld	a1,96(s0)
ffffffffc0200a82:	00006517          	auipc	a0,0x6
ffffffffc0200a86:	8de50513          	addi	a0,a0,-1826 # ffffffffc0206360 <commands+0x318>
ffffffffc0200a8a:	f0eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a8e:	742c                	ld	a1,104(s0)
ffffffffc0200a90:	00006517          	auipc	a0,0x6
ffffffffc0200a94:	8e850513          	addi	a0,a0,-1816 # ffffffffc0206378 <commands+0x330>
ffffffffc0200a98:	f00ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a9c:	782c                	ld	a1,112(s0)
ffffffffc0200a9e:	00006517          	auipc	a0,0x6
ffffffffc0200aa2:	8f250513          	addi	a0,a0,-1806 # ffffffffc0206390 <commands+0x348>
ffffffffc0200aa6:	ef2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200aaa:	7c2c                	ld	a1,120(s0)
ffffffffc0200aac:	00006517          	auipc	a0,0x6
ffffffffc0200ab0:	8fc50513          	addi	a0,a0,-1796 # ffffffffc02063a8 <commands+0x360>
ffffffffc0200ab4:	ee4ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200ab8:	604c                	ld	a1,128(s0)
ffffffffc0200aba:	00006517          	auipc	a0,0x6
ffffffffc0200abe:	90650513          	addi	a0,a0,-1786 # ffffffffc02063c0 <commands+0x378>
ffffffffc0200ac2:	ed6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200ac6:	644c                	ld	a1,136(s0)
ffffffffc0200ac8:	00006517          	auipc	a0,0x6
ffffffffc0200acc:	91050513          	addi	a0,a0,-1776 # ffffffffc02063d8 <commands+0x390>
ffffffffc0200ad0:	ec8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ad4:	684c                	ld	a1,144(s0)
ffffffffc0200ad6:	00006517          	auipc	a0,0x6
ffffffffc0200ada:	91a50513          	addi	a0,a0,-1766 # ffffffffc02063f0 <commands+0x3a8>
ffffffffc0200ade:	ebaff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae2:	6c4c                	ld	a1,152(s0)
ffffffffc0200ae4:	00006517          	auipc	a0,0x6
ffffffffc0200ae8:	92450513          	addi	a0,a0,-1756 # ffffffffc0206408 <commands+0x3c0>
ffffffffc0200aec:	eacff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af0:	704c                	ld	a1,160(s0)
ffffffffc0200af2:	00006517          	auipc	a0,0x6
ffffffffc0200af6:	92e50513          	addi	a0,a0,-1746 # ffffffffc0206420 <commands+0x3d8>
ffffffffc0200afa:	e9eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200afe:	744c                	ld	a1,168(s0)
ffffffffc0200b00:	00006517          	auipc	a0,0x6
ffffffffc0200b04:	93850513          	addi	a0,a0,-1736 # ffffffffc0206438 <commands+0x3f0>
ffffffffc0200b08:	e90ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b0c:	784c                	ld	a1,176(s0)
ffffffffc0200b0e:	00006517          	auipc	a0,0x6
ffffffffc0200b12:	94250513          	addi	a0,a0,-1726 # ffffffffc0206450 <commands+0x408>
ffffffffc0200b16:	e82ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b1a:	7c4c                	ld	a1,184(s0)
ffffffffc0200b1c:	00006517          	auipc	a0,0x6
ffffffffc0200b20:	94c50513          	addi	a0,a0,-1716 # ffffffffc0206468 <commands+0x420>
ffffffffc0200b24:	e74ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b28:	606c                	ld	a1,192(s0)
ffffffffc0200b2a:	00006517          	auipc	a0,0x6
ffffffffc0200b2e:	95650513          	addi	a0,a0,-1706 # ffffffffc0206480 <commands+0x438>
ffffffffc0200b32:	e66ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b36:	646c                	ld	a1,200(s0)
ffffffffc0200b38:	00006517          	auipc	a0,0x6
ffffffffc0200b3c:	96050513          	addi	a0,a0,-1696 # ffffffffc0206498 <commands+0x450>
ffffffffc0200b40:	e58ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b44:	686c                	ld	a1,208(s0)
ffffffffc0200b46:	00006517          	auipc	a0,0x6
ffffffffc0200b4a:	96a50513          	addi	a0,a0,-1686 # ffffffffc02064b0 <commands+0x468>
ffffffffc0200b4e:	e4aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b52:	6c6c                	ld	a1,216(s0)
ffffffffc0200b54:	00006517          	auipc	a0,0x6
ffffffffc0200b58:	97450513          	addi	a0,a0,-1676 # ffffffffc02064c8 <commands+0x480>
ffffffffc0200b5c:	e3cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b60:	706c                	ld	a1,224(s0)
ffffffffc0200b62:	00006517          	auipc	a0,0x6
ffffffffc0200b66:	97e50513          	addi	a0,a0,-1666 # ffffffffc02064e0 <commands+0x498>
ffffffffc0200b6a:	e2eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b6e:	746c                	ld	a1,232(s0)
ffffffffc0200b70:	00006517          	auipc	a0,0x6
ffffffffc0200b74:	98850513          	addi	a0,a0,-1656 # ffffffffc02064f8 <commands+0x4b0>
ffffffffc0200b78:	e20ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b7c:	786c                	ld	a1,240(s0)
ffffffffc0200b7e:	00006517          	auipc	a0,0x6
ffffffffc0200b82:	99250513          	addi	a0,a0,-1646 # ffffffffc0206510 <commands+0x4c8>
ffffffffc0200b86:	e12ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b8a:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b8c:	6402                	ld	s0,0(sp)
ffffffffc0200b8e:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	00006517          	auipc	a0,0x6
ffffffffc0200b94:	99850513          	addi	a0,a0,-1640 # ffffffffc0206528 <commands+0x4e0>
}
ffffffffc0200b98:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b9a:	dfeff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200b9e <print_trapframe>:
{
ffffffffc0200b9e:	1141                	addi	sp,sp,-16
ffffffffc0200ba0:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba2:	85aa                	mv	a1,a0
{
ffffffffc0200ba4:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba6:	00006517          	auipc	a0,0x6
ffffffffc0200baa:	99a50513          	addi	a0,a0,-1638 # ffffffffc0206540 <commands+0x4f8>
{
ffffffffc0200bae:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb0:	de8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bb4:	8522                	mv	a0,s0
ffffffffc0200bb6:	e1bff0ef          	jal	ra,ffffffffc02009d0 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bba:	10043583          	ld	a1,256(s0)
ffffffffc0200bbe:	00006517          	auipc	a0,0x6
ffffffffc0200bc2:	99a50513          	addi	a0,a0,-1638 # ffffffffc0206558 <commands+0x510>
ffffffffc0200bc6:	dd2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bca:	10843583          	ld	a1,264(s0)
ffffffffc0200bce:	00006517          	auipc	a0,0x6
ffffffffc0200bd2:	9a250513          	addi	a0,a0,-1630 # ffffffffc0206570 <commands+0x528>
ffffffffc0200bd6:	dc2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200bda:	11043583          	ld	a1,272(s0)
ffffffffc0200bde:	00006517          	auipc	a0,0x6
ffffffffc0200be2:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0206588 <commands+0x540>
ffffffffc0200be6:	db2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bea:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bee:	6402                	ld	s0,0(sp)
ffffffffc0200bf0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf2:	00006517          	auipc	a0,0x6
ffffffffc0200bf6:	9a650513          	addi	a0,a0,-1626 # ffffffffc0206598 <commands+0x550>
}
ffffffffc0200bfa:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bfc:	d9cff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200c00 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c00:	11853783          	ld	a5,280(a0)
ffffffffc0200c04:	472d                	li	a4,11
ffffffffc0200c06:	0786                	slli	a5,a5,0x1
ffffffffc0200c08:	8385                	srli	a5,a5,0x1
ffffffffc0200c0a:	06f76d63          	bltu	a4,a5,ffffffffc0200c84 <interrupt_handler+0x84>
ffffffffc0200c0e:	00006717          	auipc	a4,0x6
ffffffffc0200c12:	a4270713          	addi	a4,a4,-1470 # ffffffffc0206650 <commands+0x608>
ffffffffc0200c16:	078a                	slli	a5,a5,0x2
ffffffffc0200c18:	97ba                	add	a5,a5,a4
ffffffffc0200c1a:	439c                	lw	a5,0(a5)
ffffffffc0200c1c:	97ba                	add	a5,a5,a4
ffffffffc0200c1e:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c20:	00006517          	auipc	a0,0x6
ffffffffc0200c24:	9f050513          	addi	a0,a0,-1552 # ffffffffc0206610 <commands+0x5c8>
ffffffffc0200c28:	d70ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c2c:	00006517          	auipc	a0,0x6
ffffffffc0200c30:	9c450513          	addi	a0,a0,-1596 # ffffffffc02065f0 <commands+0x5a8>
ffffffffc0200c34:	d64ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c38:	00006517          	auipc	a0,0x6
ffffffffc0200c3c:	97850513          	addi	a0,a0,-1672 # ffffffffc02065b0 <commands+0x568>
ffffffffc0200c40:	d58ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c44:	00006517          	auipc	a0,0x6
ffffffffc0200c48:	98c50513          	addi	a0,a0,-1652 # ffffffffc02065d0 <commands+0x588>
ffffffffc0200c4c:	d4cff06f          	j	ffffffffc0200198 <cprintf>
{
ffffffffc0200c50:	1141                	addi	sp,sp,-16
ffffffffc0200c52:	e406                	sd	ra,8(sp)
         *(2)计数器（ticks）加一
         *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
         * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
         */

        clock_set_next_event();
ffffffffc0200c54:	91bff0ef          	jal	ra,ffffffffc020056e <clock_set_next_event>
        ticks++;
ffffffffc0200c58:	000d1717          	auipc	a4,0xd1
ffffffffc0200c5c:	fc870713          	addi	a4,a4,-56 # ffffffffc02d1c20 <ticks>
ffffffffc0200c60:	631c                	ld	a5,0(a4)
        if (current != NULL)
ffffffffc0200c62:	000d1517          	auipc	a0,0xd1
ffffffffc0200c66:	01653503          	ld	a0,22(a0) # ffffffffc02d1c78 <current>
        ticks++;
ffffffffc0200c6a:	0785                	addi	a5,a5,1
ffffffffc0200c6c:	e31c                	sd	a5,0(a4)
        if (current != NULL)
ffffffffc0200c6e:	cd01                	beqz	a0,ffffffffc0200c86 <interrupt_handler+0x86>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c70:	60a2                	ld	ra,8(sp)
ffffffffc0200c72:	0141                	addi	sp,sp,16
            sched_class_proc_tick(current);
ffffffffc0200c74:	1b10406f          	j	ffffffffc0205624 <sched_class_proc_tick>
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c78:	00006517          	auipc	a0,0x6
ffffffffc0200c7c:	9b850513          	addi	a0,a0,-1608 # ffffffffc0206630 <commands+0x5e8>
ffffffffc0200c80:	d18ff06f          	j	ffffffffc0200198 <cprintf>
        print_trapframe(tf);
ffffffffc0200c84:	bf29                	j	ffffffffc0200b9e <print_trapframe>
}
ffffffffc0200c86:	60a2                	ld	ra,8(sp)
ffffffffc0200c88:	0141                	addi	sp,sp,16
ffffffffc0200c8a:	8082                	ret

ffffffffc0200c8c <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c8c:	11853783          	ld	a5,280(a0)
{
ffffffffc0200c90:	1141                	addi	sp,sp,-16
ffffffffc0200c92:	e022                	sd	s0,0(sp)
ffffffffc0200c94:	e406                	sd	ra,8(sp)
ffffffffc0200c96:	473d                	li	a4,15
ffffffffc0200c98:	842a                	mv	s0,a0
ffffffffc0200c9a:	10f76f63          	bltu	a4,a5,ffffffffc0200db8 <exception_handler+0x12c>
ffffffffc0200c9e:	00006717          	auipc	a4,0x6
ffffffffc0200ca2:	b8e70713          	addi	a4,a4,-1138 # ffffffffc020682c <commands+0x7e4>
ffffffffc0200ca6:	078a                	slli	a5,a5,0x2
ffffffffc0200ca8:	97ba                	add	a5,a5,a4
ffffffffc0200caa:	439c                	lw	a5,0(a5)
ffffffffc0200cac:	97ba                	add	a5,a5,a4
ffffffffc0200cae:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200cb0:	00006517          	auipc	a0,0x6
ffffffffc0200cb4:	ab850513          	addi	a0,a0,-1352 # ffffffffc0206768 <commands+0x720>
ffffffffc0200cb8:	ce0ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        tf->epc += 4;
ffffffffc0200cbc:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cc0:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200cc2:	0791                	addi	a5,a5,4
ffffffffc0200cc4:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200cc8:	6402                	ld	s0,0(sp)
ffffffffc0200cca:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200ccc:	3c30406f          	j	ffffffffc020588e <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cd0:	00006517          	auipc	a0,0x6
ffffffffc0200cd4:	ab850513          	addi	a0,a0,-1352 # ffffffffc0206788 <commands+0x740>
}
ffffffffc0200cd8:	6402                	ld	s0,0(sp)
ffffffffc0200cda:	60a2                	ld	ra,8(sp)
ffffffffc0200cdc:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200cde:	cbaff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200ce2:	00006517          	auipc	a0,0x6
ffffffffc0200ce6:	ac650513          	addi	a0,a0,-1338 # ffffffffc02067a8 <commands+0x760>
ffffffffc0200cea:	b7fd                	j	ffffffffc0200cd8 <exception_handler+0x4c>
        if (do_pgfault(current->mm, 0, tf->tval) != 0)
ffffffffc0200cec:	000d1797          	auipc	a5,0xd1
ffffffffc0200cf0:	f8c7b783          	ld	a5,-116(a5) # ffffffffc02d1c78 <current>
ffffffffc0200cf4:	11053603          	ld	a2,272(a0)
ffffffffc0200cf8:	7788                	ld	a0,40(a5)
ffffffffc0200cfa:	4581                	li	a1,0
ffffffffc0200cfc:	6e5020ef          	jal	ra,ffffffffc0203be0 <do_pgfault>
ffffffffc0200d00:	ed69                	bnez	a0,ffffffffc0200dda <exception_handler+0x14e>
}
ffffffffc0200d02:	60a2                	ld	ra,8(sp)
ffffffffc0200d04:	6402                	ld	s0,0(sp)
ffffffffc0200d06:	0141                	addi	sp,sp,16
ffffffffc0200d08:	8082                	ret
        if (do_pgfault(current->mm, 0, tf->tval) != 0)
ffffffffc0200d0a:	000d1797          	auipc	a5,0xd1
ffffffffc0200d0e:	f6e7b783          	ld	a5,-146(a5) # ffffffffc02d1c78 <current>
ffffffffc0200d12:	11053603          	ld	a2,272(a0)
ffffffffc0200d16:	7788                	ld	a0,40(a5)
ffffffffc0200d18:	4581                	li	a1,0
ffffffffc0200d1a:	6c7020ef          	jal	ra,ffffffffc0203be0 <do_pgfault>
ffffffffc0200d1e:	d175                	beqz	a0,ffffffffc0200d02 <exception_handler+0x76>
            print_trapframe(tf);
ffffffffc0200d20:	8522                	mv	a0,s0
ffffffffc0200d22:	e7dff0ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
            panic("unhandled load page fault\n");
ffffffffc0200d26:	00006617          	auipc	a2,0x6
ffffffffc0200d2a:	aca60613          	addi	a2,a2,-1334 # ffffffffc02067f0 <commands+0x7a8>
ffffffffc0200d2e:	0d900593          	li	a1,217
ffffffffc0200d32:	00006517          	auipc	a0,0x6
ffffffffc0200d36:	a0650513          	addi	a0,a0,-1530 # ffffffffc0206738 <commands+0x6f0>
ffffffffc0200d3a:	f58ff0ef          	jal	ra,ffffffffc0200492 <__panic>
        if (do_pgfault(current->mm, 0x2, tf->tval) != 0)
ffffffffc0200d3e:	000d1797          	auipc	a5,0xd1
ffffffffc0200d42:	f3a7b783          	ld	a5,-198(a5) # ffffffffc02d1c78 <current>
ffffffffc0200d46:	11053603          	ld	a2,272(a0)
ffffffffc0200d4a:	7788                	ld	a0,40(a5)
ffffffffc0200d4c:	4589                	li	a1,2
ffffffffc0200d4e:	693020ef          	jal	ra,ffffffffc0203be0 <do_pgfault>
ffffffffc0200d52:	d945                	beqz	a0,ffffffffc0200d02 <exception_handler+0x76>
            print_trapframe(tf);
ffffffffc0200d54:	8522                	mv	a0,s0
ffffffffc0200d56:	e49ff0ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
            panic("unhandled store page fault\n");
ffffffffc0200d5a:	00006617          	auipc	a2,0x6
ffffffffc0200d5e:	ab660613          	addi	a2,a2,-1354 # ffffffffc0206810 <commands+0x7c8>
ffffffffc0200d62:	0e000593          	li	a1,224
ffffffffc0200d66:	00006517          	auipc	a0,0x6
ffffffffc0200d6a:	9d250513          	addi	a0,a0,-1582 # ffffffffc0206738 <commands+0x6f0>
ffffffffc0200d6e:	f24ff0ef          	jal	ra,ffffffffc0200492 <__panic>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d72:	00006517          	auipc	a0,0x6
ffffffffc0200d76:	90e50513          	addi	a0,a0,-1778 # ffffffffc0206680 <commands+0x638>
ffffffffc0200d7a:	bfb9                	j	ffffffffc0200cd8 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d7c:	00006517          	auipc	a0,0x6
ffffffffc0200d80:	92450513          	addi	a0,a0,-1756 # ffffffffc02066a0 <commands+0x658>
ffffffffc0200d84:	bf91                	j	ffffffffc0200cd8 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d86:	00006517          	auipc	a0,0x6
ffffffffc0200d8a:	93a50513          	addi	a0,a0,-1734 # ffffffffc02066c0 <commands+0x678>
ffffffffc0200d8e:	b7a9                	j	ffffffffc0200cd8 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d90:	00006517          	auipc	a0,0x6
ffffffffc0200d94:	94850513          	addi	a0,a0,-1720 # ffffffffc02066d8 <commands+0x690>
ffffffffc0200d98:	b781                	j	ffffffffc0200cd8 <exception_handler+0x4c>
        cprintf("Load address misaligned\n");
ffffffffc0200d9a:	00006517          	auipc	a0,0x6
ffffffffc0200d9e:	94e50513          	addi	a0,a0,-1714 # ffffffffc02066e8 <commands+0x6a0>
ffffffffc0200da2:	bf1d                	j	ffffffffc0200cd8 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200da4:	00006517          	auipc	a0,0x6
ffffffffc0200da8:	96450513          	addi	a0,a0,-1692 # ffffffffc0206708 <commands+0x6c0>
ffffffffc0200dac:	b735                	j	ffffffffc0200cd8 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200dae:	00006517          	auipc	a0,0x6
ffffffffc0200db2:	9a250513          	addi	a0,a0,-1630 # ffffffffc0206750 <commands+0x708>
ffffffffc0200db6:	b70d                	j	ffffffffc0200cd8 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200db8:	8522                	mv	a0,s0
}
ffffffffc0200dba:	6402                	ld	s0,0(sp)
ffffffffc0200dbc:	60a2                	ld	ra,8(sp)
ffffffffc0200dbe:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200dc0:	bbf9                	j	ffffffffc0200b9e <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200dc2:	00006617          	auipc	a2,0x6
ffffffffc0200dc6:	95e60613          	addi	a2,a2,-1698 # ffffffffc0206720 <commands+0x6d8>
ffffffffc0200dca:	0b900593          	li	a1,185
ffffffffc0200dce:	00006517          	auipc	a0,0x6
ffffffffc0200dd2:	96a50513          	addi	a0,a0,-1686 # ffffffffc0206738 <commands+0x6f0>
ffffffffc0200dd6:	ebcff0ef          	jal	ra,ffffffffc0200492 <__panic>
            print_trapframe(tf);
ffffffffc0200dda:	8522                	mv	a0,s0
ffffffffc0200ddc:	dc3ff0ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
            panic("unhandled instruction page fault\n");
ffffffffc0200de0:	00006617          	auipc	a2,0x6
ffffffffc0200de4:	9e860613          	addi	a2,a2,-1560 # ffffffffc02067c8 <commands+0x780>
ffffffffc0200de8:	0d200593          	li	a1,210
ffffffffc0200dec:	00006517          	auipc	a0,0x6
ffffffffc0200df0:	94c50513          	addi	a0,a0,-1716 # ffffffffc0206738 <commands+0x6f0>
ffffffffc0200df4:	e9eff0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0200df8 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200df8:	1101                	addi	sp,sp,-32
ffffffffc0200dfa:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200dfc:	000d1417          	auipc	s0,0xd1
ffffffffc0200e00:	e7c40413          	addi	s0,s0,-388 # ffffffffc02d1c78 <current>
ffffffffc0200e04:	6018                	ld	a4,0(s0)
{
ffffffffc0200e06:	ec06                	sd	ra,24(sp)
ffffffffc0200e08:	e426                	sd	s1,8(sp)
ffffffffc0200e0a:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e0c:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200e10:	cf1d                	beqz	a4,ffffffffc0200e4e <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e12:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200e16:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200e1a:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e1c:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e20:	0206c463          	bltz	a3,ffffffffc0200e48 <trap+0x50>
        exception_handler(tf);
ffffffffc0200e24:	e69ff0ef          	jal	ra,ffffffffc0200c8c <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200e28:	601c                	ld	a5,0(s0)
ffffffffc0200e2a:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200e2e:	e499                	bnez	s1,ffffffffc0200e3c <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200e30:	0b07a703          	lw	a4,176(a5)
ffffffffc0200e34:	8b05                	andi	a4,a4,1
ffffffffc0200e36:	e329                	bnez	a4,ffffffffc0200e78 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200e38:	6f9c                	ld	a5,24(a5)
ffffffffc0200e3a:	eb85                	bnez	a5,ffffffffc0200e6a <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200e3c:	60e2                	ld	ra,24(sp)
ffffffffc0200e3e:	6442                	ld	s0,16(sp)
ffffffffc0200e40:	64a2                	ld	s1,8(sp)
ffffffffc0200e42:	6902                	ld	s2,0(sp)
ffffffffc0200e44:	6105                	addi	sp,sp,32
ffffffffc0200e46:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200e48:	db9ff0ef          	jal	ra,ffffffffc0200c00 <interrupt_handler>
ffffffffc0200e4c:	bff1                	j	ffffffffc0200e28 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e4e:	0006c863          	bltz	a3,ffffffffc0200e5e <trap+0x66>
}
ffffffffc0200e52:	6442                	ld	s0,16(sp)
ffffffffc0200e54:	60e2                	ld	ra,24(sp)
ffffffffc0200e56:	64a2                	ld	s1,8(sp)
ffffffffc0200e58:	6902                	ld	s2,0(sp)
ffffffffc0200e5a:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200e5c:	bd05                	j	ffffffffc0200c8c <exception_handler>
}
ffffffffc0200e5e:	6442                	ld	s0,16(sp)
ffffffffc0200e60:	60e2                	ld	ra,24(sp)
ffffffffc0200e62:	64a2                	ld	s1,8(sp)
ffffffffc0200e64:	6902                	ld	s2,0(sp)
ffffffffc0200e66:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200e68:	bb61                	j	ffffffffc0200c00 <interrupt_handler>
}
ffffffffc0200e6a:	6442                	ld	s0,16(sp)
ffffffffc0200e6c:	60e2                	ld	ra,24(sp)
ffffffffc0200e6e:	64a2                	ld	s1,8(sp)
ffffffffc0200e70:	6902                	ld	s2,0(sp)
ffffffffc0200e72:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e74:	0dd0406f          	j	ffffffffc0205750 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e78:	555d                	li	a0,-9
ffffffffc0200e7a:	5ae030ef          	jal	ra,ffffffffc0204428 <do_exit>
            if (current->need_resched)
ffffffffc0200e7e:	601c                	ld	a5,0(s0)
ffffffffc0200e80:	bf65                	j	ffffffffc0200e38 <trap+0x40>
	...

ffffffffc0200e84 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e84:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e88:	00011463          	bnez	sp,ffffffffc0200e90 <__alltraps+0xc>
ffffffffc0200e8c:	14002173          	csrr	sp,sscratch
ffffffffc0200e90:	712d                	addi	sp,sp,-288
ffffffffc0200e92:	e002                	sd	zero,0(sp)
ffffffffc0200e94:	e406                	sd	ra,8(sp)
ffffffffc0200e96:	ec0e                	sd	gp,24(sp)
ffffffffc0200e98:	f012                	sd	tp,32(sp)
ffffffffc0200e9a:	f416                	sd	t0,40(sp)
ffffffffc0200e9c:	f81a                	sd	t1,48(sp)
ffffffffc0200e9e:	fc1e                	sd	t2,56(sp)
ffffffffc0200ea0:	e0a2                	sd	s0,64(sp)
ffffffffc0200ea2:	e4a6                	sd	s1,72(sp)
ffffffffc0200ea4:	e8aa                	sd	a0,80(sp)
ffffffffc0200ea6:	ecae                	sd	a1,88(sp)
ffffffffc0200ea8:	f0b2                	sd	a2,96(sp)
ffffffffc0200eaa:	f4b6                	sd	a3,104(sp)
ffffffffc0200eac:	f8ba                	sd	a4,112(sp)
ffffffffc0200eae:	fcbe                	sd	a5,120(sp)
ffffffffc0200eb0:	e142                	sd	a6,128(sp)
ffffffffc0200eb2:	e546                	sd	a7,136(sp)
ffffffffc0200eb4:	e94a                	sd	s2,144(sp)
ffffffffc0200eb6:	ed4e                	sd	s3,152(sp)
ffffffffc0200eb8:	f152                	sd	s4,160(sp)
ffffffffc0200eba:	f556                	sd	s5,168(sp)
ffffffffc0200ebc:	f95a                	sd	s6,176(sp)
ffffffffc0200ebe:	fd5e                	sd	s7,184(sp)
ffffffffc0200ec0:	e1e2                	sd	s8,192(sp)
ffffffffc0200ec2:	e5e6                	sd	s9,200(sp)
ffffffffc0200ec4:	e9ea                	sd	s10,208(sp)
ffffffffc0200ec6:	edee                	sd	s11,216(sp)
ffffffffc0200ec8:	f1f2                	sd	t3,224(sp)
ffffffffc0200eca:	f5f6                	sd	t4,232(sp)
ffffffffc0200ecc:	f9fa                	sd	t5,240(sp)
ffffffffc0200ece:	fdfe                	sd	t6,248(sp)
ffffffffc0200ed0:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200ed4:	100024f3          	csrr	s1,sstatus
ffffffffc0200ed8:	14102973          	csrr	s2,sepc
ffffffffc0200edc:	143029f3          	csrr	s3,stval
ffffffffc0200ee0:	14202a73          	csrr	s4,scause
ffffffffc0200ee4:	e822                	sd	s0,16(sp)
ffffffffc0200ee6:	e226                	sd	s1,256(sp)
ffffffffc0200ee8:	e64a                	sd	s2,264(sp)
ffffffffc0200eea:	ea4e                	sd	s3,272(sp)
ffffffffc0200eec:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200eee:	850a                	mv	a0,sp
    jal trap
ffffffffc0200ef0:	f09ff0ef          	jal	ra,ffffffffc0200df8 <trap>

ffffffffc0200ef4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200ef4:	6492                	ld	s1,256(sp)
ffffffffc0200ef6:	6932                	ld	s2,264(sp)
ffffffffc0200ef8:	1004f413          	andi	s0,s1,256
ffffffffc0200efc:	e401                	bnez	s0,ffffffffc0200f04 <__trapret+0x10>
ffffffffc0200efe:	1200                	addi	s0,sp,288
ffffffffc0200f00:	14041073          	csrw	sscratch,s0
ffffffffc0200f04:	10049073          	csrw	sstatus,s1
ffffffffc0200f08:	14191073          	csrw	sepc,s2
ffffffffc0200f0c:	60a2                	ld	ra,8(sp)
ffffffffc0200f0e:	61e2                	ld	gp,24(sp)
ffffffffc0200f10:	7202                	ld	tp,32(sp)
ffffffffc0200f12:	72a2                	ld	t0,40(sp)
ffffffffc0200f14:	7342                	ld	t1,48(sp)
ffffffffc0200f16:	73e2                	ld	t2,56(sp)
ffffffffc0200f18:	6406                	ld	s0,64(sp)
ffffffffc0200f1a:	64a6                	ld	s1,72(sp)
ffffffffc0200f1c:	6546                	ld	a0,80(sp)
ffffffffc0200f1e:	65e6                	ld	a1,88(sp)
ffffffffc0200f20:	7606                	ld	a2,96(sp)
ffffffffc0200f22:	76a6                	ld	a3,104(sp)
ffffffffc0200f24:	7746                	ld	a4,112(sp)
ffffffffc0200f26:	77e6                	ld	a5,120(sp)
ffffffffc0200f28:	680a                	ld	a6,128(sp)
ffffffffc0200f2a:	68aa                	ld	a7,136(sp)
ffffffffc0200f2c:	694a                	ld	s2,144(sp)
ffffffffc0200f2e:	69ea                	ld	s3,152(sp)
ffffffffc0200f30:	7a0a                	ld	s4,160(sp)
ffffffffc0200f32:	7aaa                	ld	s5,168(sp)
ffffffffc0200f34:	7b4a                	ld	s6,176(sp)
ffffffffc0200f36:	7bea                	ld	s7,184(sp)
ffffffffc0200f38:	6c0e                	ld	s8,192(sp)
ffffffffc0200f3a:	6cae                	ld	s9,200(sp)
ffffffffc0200f3c:	6d4e                	ld	s10,208(sp)
ffffffffc0200f3e:	6dee                	ld	s11,216(sp)
ffffffffc0200f40:	7e0e                	ld	t3,224(sp)
ffffffffc0200f42:	7eae                	ld	t4,232(sp)
ffffffffc0200f44:	7f4e                	ld	t5,240(sp)
ffffffffc0200f46:	7fee                	ld	t6,248(sp)
ffffffffc0200f48:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200f4a:	10200073          	sret

ffffffffc0200f4e <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200f4e:	812a                	mv	sp,a0
ffffffffc0200f50:	b755                	j	ffffffffc0200ef4 <__trapret>

ffffffffc0200f52 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200f52:	000cd797          	auipc	a5,0xcd
ffffffffc0200f56:	c6e78793          	addi	a5,a5,-914 # ffffffffc02cdbc0 <free_area>
ffffffffc0200f5a:	e79c                	sd	a5,8(a5)
ffffffffc0200f5c:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200f5e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200f62:	8082                	ret

ffffffffc0200f64 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200f64:	000cd517          	auipc	a0,0xcd
ffffffffc0200f68:	c6c56503          	lwu	a0,-916(a0) # ffffffffc02cdbd0 <free_area+0x10>
ffffffffc0200f6c:	8082                	ret

ffffffffc0200f6e <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200f6e:	715d                	addi	sp,sp,-80
ffffffffc0200f70:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200f72:	000cd417          	auipc	s0,0xcd
ffffffffc0200f76:	c4e40413          	addi	s0,s0,-946 # ffffffffc02cdbc0 <free_area>
ffffffffc0200f7a:	641c                	ld	a5,8(s0)
ffffffffc0200f7c:	e486                	sd	ra,72(sp)
ffffffffc0200f7e:	fc26                	sd	s1,56(sp)
ffffffffc0200f80:	f84a                	sd	s2,48(sp)
ffffffffc0200f82:	f44e                	sd	s3,40(sp)
ffffffffc0200f84:	f052                	sd	s4,32(sp)
ffffffffc0200f86:	ec56                	sd	s5,24(sp)
ffffffffc0200f88:	e85a                	sd	s6,16(sp)
ffffffffc0200f8a:	e45e                	sd	s7,8(sp)
ffffffffc0200f8c:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200f8e:	2a878d63          	beq	a5,s0,ffffffffc0201248 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200f92:	4481                	li	s1,0
ffffffffc0200f94:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200f96:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200f9a:	8b09                	andi	a4,a4,2
ffffffffc0200f9c:	2a070a63          	beqz	a4,ffffffffc0201250 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0200fa0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fa4:	679c                	ld	a5,8(a5)
ffffffffc0200fa6:	2905                	addiw	s2,s2,1
ffffffffc0200fa8:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200faa:	fe8796e3          	bne	a5,s0,ffffffffc0200f96 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200fae:	89a6                	mv	s3,s1
ffffffffc0200fb0:	6df000ef          	jal	ra,ffffffffc0201e8e <nr_free_pages>
ffffffffc0200fb4:	6f351e63          	bne	a0,s3,ffffffffc02016b0 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fb8:	4505                	li	a0,1
ffffffffc0200fba:	657000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc0200fbe:	8aaa                	mv	s5,a0
ffffffffc0200fc0:	42050863          	beqz	a0,ffffffffc02013f0 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fc4:	4505                	li	a0,1
ffffffffc0200fc6:	64b000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc0200fca:	89aa                	mv	s3,a0
ffffffffc0200fcc:	70050263          	beqz	a0,ffffffffc02016d0 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fd0:	4505                	li	a0,1
ffffffffc0200fd2:	63f000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc0200fd6:	8a2a                	mv	s4,a0
ffffffffc0200fd8:	48050c63          	beqz	a0,ffffffffc0201470 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200fdc:	293a8a63          	beq	s5,s3,ffffffffc0201270 <default_check+0x302>
ffffffffc0200fe0:	28aa8863          	beq	s5,a0,ffffffffc0201270 <default_check+0x302>
ffffffffc0200fe4:	28a98663          	beq	s3,a0,ffffffffc0201270 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200fe8:	000aa783          	lw	a5,0(s5)
ffffffffc0200fec:	2a079263          	bnez	a5,ffffffffc0201290 <default_check+0x322>
ffffffffc0200ff0:	0009a783          	lw	a5,0(s3)
ffffffffc0200ff4:	28079e63          	bnez	a5,ffffffffc0201290 <default_check+0x322>
ffffffffc0200ff8:	411c                	lw	a5,0(a0)
ffffffffc0200ffa:	28079b63          	bnez	a5,ffffffffc0201290 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200ffe:	000d1797          	auipc	a5,0xd1
ffffffffc0201002:	c5a7b783          	ld	a5,-934(a5) # ffffffffc02d1c58 <pages>
ffffffffc0201006:	40fa8733          	sub	a4,s5,a5
ffffffffc020100a:	00007617          	auipc	a2,0x7
ffffffffc020100e:	64663603          	ld	a2,1606(a2) # ffffffffc0208650 <nbase>
ffffffffc0201012:	8719                	srai	a4,a4,0x6
ffffffffc0201014:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201016:	000d1697          	auipc	a3,0xd1
ffffffffc020101a:	c3a6b683          	ld	a3,-966(a3) # ffffffffc02d1c50 <npage>
ffffffffc020101e:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0201020:	0732                	slli	a4,a4,0xc
ffffffffc0201022:	28d77763          	bgeu	a4,a3,ffffffffc02012b0 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0201026:	40f98733          	sub	a4,s3,a5
ffffffffc020102a:	8719                	srai	a4,a4,0x6
ffffffffc020102c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020102e:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201030:	4cd77063          	bgeu	a4,a3,ffffffffc02014f0 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0201034:	40f507b3          	sub	a5,a0,a5
ffffffffc0201038:	8799                	srai	a5,a5,0x6
ffffffffc020103a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020103c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020103e:	30d7f963          	bgeu	a5,a3,ffffffffc0201350 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0201042:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201044:	00043c03          	ld	s8,0(s0)
ffffffffc0201048:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc020104c:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0201050:	e400                	sd	s0,8(s0)
ffffffffc0201052:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0201054:	000cd797          	auipc	a5,0xcd
ffffffffc0201058:	b607ae23          	sw	zero,-1156(a5) # ffffffffc02cdbd0 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc020105c:	5b5000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc0201060:	2c051863          	bnez	a0,ffffffffc0201330 <default_check+0x3c2>
    free_page(p0);
ffffffffc0201064:	4585                	li	a1,1
ffffffffc0201066:	8556                	mv	a0,s5
ffffffffc0201068:	5e7000ef          	jal	ra,ffffffffc0201e4e <free_pages>
    free_page(p1);
ffffffffc020106c:	4585                	li	a1,1
ffffffffc020106e:	854e                	mv	a0,s3
ffffffffc0201070:	5df000ef          	jal	ra,ffffffffc0201e4e <free_pages>
    free_page(p2);
ffffffffc0201074:	4585                	li	a1,1
ffffffffc0201076:	8552                	mv	a0,s4
ffffffffc0201078:	5d7000ef          	jal	ra,ffffffffc0201e4e <free_pages>
    assert(nr_free == 3);
ffffffffc020107c:	4818                	lw	a4,16(s0)
ffffffffc020107e:	478d                	li	a5,3
ffffffffc0201080:	28f71863          	bne	a4,a5,ffffffffc0201310 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201084:	4505                	li	a0,1
ffffffffc0201086:	58b000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc020108a:	89aa                	mv	s3,a0
ffffffffc020108c:	26050263          	beqz	a0,ffffffffc02012f0 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201090:	4505                	li	a0,1
ffffffffc0201092:	57f000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc0201096:	8aaa                	mv	s5,a0
ffffffffc0201098:	3a050c63          	beqz	a0,ffffffffc0201450 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020109c:	4505                	li	a0,1
ffffffffc020109e:	573000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc02010a2:	8a2a                	mv	s4,a0
ffffffffc02010a4:	38050663          	beqz	a0,ffffffffc0201430 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc02010a8:	4505                	li	a0,1
ffffffffc02010aa:	567000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc02010ae:	36051163          	bnez	a0,ffffffffc0201410 <default_check+0x4a2>
    free_page(p0);
ffffffffc02010b2:	4585                	li	a1,1
ffffffffc02010b4:	854e                	mv	a0,s3
ffffffffc02010b6:	599000ef          	jal	ra,ffffffffc0201e4e <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02010ba:	641c                	ld	a5,8(s0)
ffffffffc02010bc:	20878a63          	beq	a5,s0,ffffffffc02012d0 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc02010c0:	4505                	li	a0,1
ffffffffc02010c2:	54f000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc02010c6:	30a99563          	bne	s3,a0,ffffffffc02013d0 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc02010ca:	4505                	li	a0,1
ffffffffc02010cc:	545000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc02010d0:	2e051063          	bnez	a0,ffffffffc02013b0 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc02010d4:	481c                	lw	a5,16(s0)
ffffffffc02010d6:	2a079d63          	bnez	a5,ffffffffc0201390 <default_check+0x422>
    free_page(p);
ffffffffc02010da:	854e                	mv	a0,s3
ffffffffc02010dc:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02010de:	01843023          	sd	s8,0(s0)
ffffffffc02010e2:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02010e6:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc02010ea:	565000ef          	jal	ra,ffffffffc0201e4e <free_pages>
    free_page(p1);
ffffffffc02010ee:	4585                	li	a1,1
ffffffffc02010f0:	8556                	mv	a0,s5
ffffffffc02010f2:	55d000ef          	jal	ra,ffffffffc0201e4e <free_pages>
    free_page(p2);
ffffffffc02010f6:	4585                	li	a1,1
ffffffffc02010f8:	8552                	mv	a0,s4
ffffffffc02010fa:	555000ef          	jal	ra,ffffffffc0201e4e <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02010fe:	4515                	li	a0,5
ffffffffc0201100:	511000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc0201104:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201106:	26050563          	beqz	a0,ffffffffc0201370 <default_check+0x402>
ffffffffc020110a:	651c                	ld	a5,8(a0)
ffffffffc020110c:	8385                	srli	a5,a5,0x1
ffffffffc020110e:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201110:	54079063          	bnez	a5,ffffffffc0201650 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201114:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201116:	00043b03          	ld	s6,0(s0)
ffffffffc020111a:	00843a83          	ld	s5,8(s0)
ffffffffc020111e:	e000                	sd	s0,0(s0)
ffffffffc0201120:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0201122:	4ef000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc0201126:	50051563          	bnez	a0,ffffffffc0201630 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020112a:	08098a13          	addi	s4,s3,128
ffffffffc020112e:	8552                	mv	a0,s4
ffffffffc0201130:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201132:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0201136:	000cd797          	auipc	a5,0xcd
ffffffffc020113a:	a807ad23          	sw	zero,-1382(a5) # ffffffffc02cdbd0 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020113e:	511000ef          	jal	ra,ffffffffc0201e4e <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201142:	4511                	li	a0,4
ffffffffc0201144:	4cd000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc0201148:	4c051463          	bnez	a0,ffffffffc0201610 <default_check+0x6a2>
ffffffffc020114c:	0889b783          	ld	a5,136(s3)
ffffffffc0201150:	8385                	srli	a5,a5,0x1
ffffffffc0201152:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201154:	48078e63          	beqz	a5,ffffffffc02015f0 <default_check+0x682>
ffffffffc0201158:	0909a703          	lw	a4,144(s3)
ffffffffc020115c:	478d                	li	a5,3
ffffffffc020115e:	48f71963          	bne	a4,a5,ffffffffc02015f0 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201162:	450d                	li	a0,3
ffffffffc0201164:	4ad000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc0201168:	8c2a                	mv	s8,a0
ffffffffc020116a:	46050363          	beqz	a0,ffffffffc02015d0 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc020116e:	4505                	li	a0,1
ffffffffc0201170:	4a1000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc0201174:	42051e63          	bnez	a0,ffffffffc02015b0 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201178:	418a1c63          	bne	s4,s8,ffffffffc0201590 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc020117c:	4585                	li	a1,1
ffffffffc020117e:	854e                	mv	a0,s3
ffffffffc0201180:	4cf000ef          	jal	ra,ffffffffc0201e4e <free_pages>
    free_pages(p1, 3);
ffffffffc0201184:	458d                	li	a1,3
ffffffffc0201186:	8552                	mv	a0,s4
ffffffffc0201188:	4c7000ef          	jal	ra,ffffffffc0201e4e <free_pages>
ffffffffc020118c:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201190:	04098c13          	addi	s8,s3,64
ffffffffc0201194:	8385                	srli	a5,a5,0x1
ffffffffc0201196:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201198:	3c078c63          	beqz	a5,ffffffffc0201570 <default_check+0x602>
ffffffffc020119c:	0109a703          	lw	a4,16(s3)
ffffffffc02011a0:	4785                	li	a5,1
ffffffffc02011a2:	3cf71763          	bne	a4,a5,ffffffffc0201570 <default_check+0x602>
ffffffffc02011a6:	008a3783          	ld	a5,8(s4)
ffffffffc02011aa:	8385                	srli	a5,a5,0x1
ffffffffc02011ac:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02011ae:	3a078163          	beqz	a5,ffffffffc0201550 <default_check+0x5e2>
ffffffffc02011b2:	010a2703          	lw	a4,16(s4)
ffffffffc02011b6:	478d                	li	a5,3
ffffffffc02011b8:	38f71c63          	bne	a4,a5,ffffffffc0201550 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02011bc:	4505                	li	a0,1
ffffffffc02011be:	453000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc02011c2:	36a99763          	bne	s3,a0,ffffffffc0201530 <default_check+0x5c2>
    free_page(p0);
ffffffffc02011c6:	4585                	li	a1,1
ffffffffc02011c8:	487000ef          	jal	ra,ffffffffc0201e4e <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02011cc:	4509                	li	a0,2
ffffffffc02011ce:	443000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc02011d2:	32aa1f63          	bne	s4,a0,ffffffffc0201510 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc02011d6:	4589                	li	a1,2
ffffffffc02011d8:	477000ef          	jal	ra,ffffffffc0201e4e <free_pages>
    free_page(p2);
ffffffffc02011dc:	4585                	li	a1,1
ffffffffc02011de:	8562                	mv	a0,s8
ffffffffc02011e0:	46f000ef          	jal	ra,ffffffffc0201e4e <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02011e4:	4515                	li	a0,5
ffffffffc02011e6:	42b000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc02011ea:	89aa                	mv	s3,a0
ffffffffc02011ec:	48050263          	beqz	a0,ffffffffc0201670 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc02011f0:	4505                	li	a0,1
ffffffffc02011f2:	41f000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc02011f6:	2c051d63          	bnez	a0,ffffffffc02014d0 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc02011fa:	481c                	lw	a5,16(s0)
ffffffffc02011fc:	2a079a63          	bnez	a5,ffffffffc02014b0 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201200:	4595                	li	a1,5
ffffffffc0201202:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201204:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201208:	01643023          	sd	s6,0(s0)
ffffffffc020120c:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201210:	43f000ef          	jal	ra,ffffffffc0201e4e <free_pages>
    return listelm->next;
ffffffffc0201214:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201216:	00878963          	beq	a5,s0,ffffffffc0201228 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc020121a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020121e:	679c                	ld	a5,8(a5)
ffffffffc0201220:	397d                	addiw	s2,s2,-1
ffffffffc0201222:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201224:	fe879be3          	bne	a5,s0,ffffffffc020121a <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201228:	26091463          	bnez	s2,ffffffffc0201490 <default_check+0x522>
    assert(total == 0);
ffffffffc020122c:	46049263          	bnez	s1,ffffffffc0201690 <default_check+0x722>
}
ffffffffc0201230:	60a6                	ld	ra,72(sp)
ffffffffc0201232:	6406                	ld	s0,64(sp)
ffffffffc0201234:	74e2                	ld	s1,56(sp)
ffffffffc0201236:	7942                	ld	s2,48(sp)
ffffffffc0201238:	79a2                	ld	s3,40(sp)
ffffffffc020123a:	7a02                	ld	s4,32(sp)
ffffffffc020123c:	6ae2                	ld	s5,24(sp)
ffffffffc020123e:	6b42                	ld	s6,16(sp)
ffffffffc0201240:	6ba2                	ld	s7,8(sp)
ffffffffc0201242:	6c02                	ld	s8,0(sp)
ffffffffc0201244:	6161                	addi	sp,sp,80
ffffffffc0201246:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201248:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020124a:	4481                	li	s1,0
ffffffffc020124c:	4901                	li	s2,0
ffffffffc020124e:	b38d                	j	ffffffffc0200fb0 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201250:	00005697          	auipc	a3,0x5
ffffffffc0201254:	62068693          	addi	a3,a3,1568 # ffffffffc0206870 <commands+0x828>
ffffffffc0201258:	00005617          	auipc	a2,0x5
ffffffffc020125c:	62860613          	addi	a2,a2,1576 # ffffffffc0206880 <commands+0x838>
ffffffffc0201260:	11000593          	li	a1,272
ffffffffc0201264:	00005517          	auipc	a0,0x5
ffffffffc0201268:	63450513          	addi	a0,a0,1588 # ffffffffc0206898 <commands+0x850>
ffffffffc020126c:	a26ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201270:	00005697          	auipc	a3,0x5
ffffffffc0201274:	6c068693          	addi	a3,a3,1728 # ffffffffc0206930 <commands+0x8e8>
ffffffffc0201278:	00005617          	auipc	a2,0x5
ffffffffc020127c:	60860613          	addi	a2,a2,1544 # ffffffffc0206880 <commands+0x838>
ffffffffc0201280:	0db00593          	li	a1,219
ffffffffc0201284:	00005517          	auipc	a0,0x5
ffffffffc0201288:	61450513          	addi	a0,a0,1556 # ffffffffc0206898 <commands+0x850>
ffffffffc020128c:	a06ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201290:	00005697          	auipc	a3,0x5
ffffffffc0201294:	6c868693          	addi	a3,a3,1736 # ffffffffc0206958 <commands+0x910>
ffffffffc0201298:	00005617          	auipc	a2,0x5
ffffffffc020129c:	5e860613          	addi	a2,a2,1512 # ffffffffc0206880 <commands+0x838>
ffffffffc02012a0:	0dc00593          	li	a1,220
ffffffffc02012a4:	00005517          	auipc	a0,0x5
ffffffffc02012a8:	5f450513          	addi	a0,a0,1524 # ffffffffc0206898 <commands+0x850>
ffffffffc02012ac:	9e6ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02012b0:	00005697          	auipc	a3,0x5
ffffffffc02012b4:	6e868693          	addi	a3,a3,1768 # ffffffffc0206998 <commands+0x950>
ffffffffc02012b8:	00005617          	auipc	a2,0x5
ffffffffc02012bc:	5c860613          	addi	a2,a2,1480 # ffffffffc0206880 <commands+0x838>
ffffffffc02012c0:	0de00593          	li	a1,222
ffffffffc02012c4:	00005517          	auipc	a0,0x5
ffffffffc02012c8:	5d450513          	addi	a0,a0,1492 # ffffffffc0206898 <commands+0x850>
ffffffffc02012cc:	9c6ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02012d0:	00005697          	auipc	a3,0x5
ffffffffc02012d4:	75068693          	addi	a3,a3,1872 # ffffffffc0206a20 <commands+0x9d8>
ffffffffc02012d8:	00005617          	auipc	a2,0x5
ffffffffc02012dc:	5a860613          	addi	a2,a2,1448 # ffffffffc0206880 <commands+0x838>
ffffffffc02012e0:	0f700593          	li	a1,247
ffffffffc02012e4:	00005517          	auipc	a0,0x5
ffffffffc02012e8:	5b450513          	addi	a0,a0,1460 # ffffffffc0206898 <commands+0x850>
ffffffffc02012ec:	9a6ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02012f0:	00005697          	auipc	a3,0x5
ffffffffc02012f4:	5e068693          	addi	a3,a3,1504 # ffffffffc02068d0 <commands+0x888>
ffffffffc02012f8:	00005617          	auipc	a2,0x5
ffffffffc02012fc:	58860613          	addi	a2,a2,1416 # ffffffffc0206880 <commands+0x838>
ffffffffc0201300:	0f000593          	li	a1,240
ffffffffc0201304:	00005517          	auipc	a0,0x5
ffffffffc0201308:	59450513          	addi	a0,a0,1428 # ffffffffc0206898 <commands+0x850>
ffffffffc020130c:	986ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 3);
ffffffffc0201310:	00005697          	auipc	a3,0x5
ffffffffc0201314:	70068693          	addi	a3,a3,1792 # ffffffffc0206a10 <commands+0x9c8>
ffffffffc0201318:	00005617          	auipc	a2,0x5
ffffffffc020131c:	56860613          	addi	a2,a2,1384 # ffffffffc0206880 <commands+0x838>
ffffffffc0201320:	0ee00593          	li	a1,238
ffffffffc0201324:	00005517          	auipc	a0,0x5
ffffffffc0201328:	57450513          	addi	a0,a0,1396 # ffffffffc0206898 <commands+0x850>
ffffffffc020132c:	966ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201330:	00005697          	auipc	a3,0x5
ffffffffc0201334:	6c868693          	addi	a3,a3,1736 # ffffffffc02069f8 <commands+0x9b0>
ffffffffc0201338:	00005617          	auipc	a2,0x5
ffffffffc020133c:	54860613          	addi	a2,a2,1352 # ffffffffc0206880 <commands+0x838>
ffffffffc0201340:	0e900593          	li	a1,233
ffffffffc0201344:	00005517          	auipc	a0,0x5
ffffffffc0201348:	55450513          	addi	a0,a0,1364 # ffffffffc0206898 <commands+0x850>
ffffffffc020134c:	946ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201350:	00005697          	auipc	a3,0x5
ffffffffc0201354:	68868693          	addi	a3,a3,1672 # ffffffffc02069d8 <commands+0x990>
ffffffffc0201358:	00005617          	auipc	a2,0x5
ffffffffc020135c:	52860613          	addi	a2,a2,1320 # ffffffffc0206880 <commands+0x838>
ffffffffc0201360:	0e000593          	li	a1,224
ffffffffc0201364:	00005517          	auipc	a0,0x5
ffffffffc0201368:	53450513          	addi	a0,a0,1332 # ffffffffc0206898 <commands+0x850>
ffffffffc020136c:	926ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != NULL);
ffffffffc0201370:	00005697          	auipc	a3,0x5
ffffffffc0201374:	6f868693          	addi	a3,a3,1784 # ffffffffc0206a68 <commands+0xa20>
ffffffffc0201378:	00005617          	auipc	a2,0x5
ffffffffc020137c:	50860613          	addi	a2,a2,1288 # ffffffffc0206880 <commands+0x838>
ffffffffc0201380:	11800593          	li	a1,280
ffffffffc0201384:	00005517          	auipc	a0,0x5
ffffffffc0201388:	51450513          	addi	a0,a0,1300 # ffffffffc0206898 <commands+0x850>
ffffffffc020138c:	906ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc0201390:	00005697          	auipc	a3,0x5
ffffffffc0201394:	6c868693          	addi	a3,a3,1736 # ffffffffc0206a58 <commands+0xa10>
ffffffffc0201398:	00005617          	auipc	a2,0x5
ffffffffc020139c:	4e860613          	addi	a2,a2,1256 # ffffffffc0206880 <commands+0x838>
ffffffffc02013a0:	0fd00593          	li	a1,253
ffffffffc02013a4:	00005517          	auipc	a0,0x5
ffffffffc02013a8:	4f450513          	addi	a0,a0,1268 # ffffffffc0206898 <commands+0x850>
ffffffffc02013ac:	8e6ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013b0:	00005697          	auipc	a3,0x5
ffffffffc02013b4:	64868693          	addi	a3,a3,1608 # ffffffffc02069f8 <commands+0x9b0>
ffffffffc02013b8:	00005617          	auipc	a2,0x5
ffffffffc02013bc:	4c860613          	addi	a2,a2,1224 # ffffffffc0206880 <commands+0x838>
ffffffffc02013c0:	0fb00593          	li	a1,251
ffffffffc02013c4:	00005517          	auipc	a0,0x5
ffffffffc02013c8:	4d450513          	addi	a0,a0,1236 # ffffffffc0206898 <commands+0x850>
ffffffffc02013cc:	8c6ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02013d0:	00005697          	auipc	a3,0x5
ffffffffc02013d4:	66868693          	addi	a3,a3,1640 # ffffffffc0206a38 <commands+0x9f0>
ffffffffc02013d8:	00005617          	auipc	a2,0x5
ffffffffc02013dc:	4a860613          	addi	a2,a2,1192 # ffffffffc0206880 <commands+0x838>
ffffffffc02013e0:	0fa00593          	li	a1,250
ffffffffc02013e4:	00005517          	auipc	a0,0x5
ffffffffc02013e8:	4b450513          	addi	a0,a0,1204 # ffffffffc0206898 <commands+0x850>
ffffffffc02013ec:	8a6ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02013f0:	00005697          	auipc	a3,0x5
ffffffffc02013f4:	4e068693          	addi	a3,a3,1248 # ffffffffc02068d0 <commands+0x888>
ffffffffc02013f8:	00005617          	auipc	a2,0x5
ffffffffc02013fc:	48860613          	addi	a2,a2,1160 # ffffffffc0206880 <commands+0x838>
ffffffffc0201400:	0d700593          	li	a1,215
ffffffffc0201404:	00005517          	auipc	a0,0x5
ffffffffc0201408:	49450513          	addi	a0,a0,1172 # ffffffffc0206898 <commands+0x850>
ffffffffc020140c:	886ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201410:	00005697          	auipc	a3,0x5
ffffffffc0201414:	5e868693          	addi	a3,a3,1512 # ffffffffc02069f8 <commands+0x9b0>
ffffffffc0201418:	00005617          	auipc	a2,0x5
ffffffffc020141c:	46860613          	addi	a2,a2,1128 # ffffffffc0206880 <commands+0x838>
ffffffffc0201420:	0f400593          	li	a1,244
ffffffffc0201424:	00005517          	auipc	a0,0x5
ffffffffc0201428:	47450513          	addi	a0,a0,1140 # ffffffffc0206898 <commands+0x850>
ffffffffc020142c:	866ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201430:	00005697          	auipc	a3,0x5
ffffffffc0201434:	4e068693          	addi	a3,a3,1248 # ffffffffc0206910 <commands+0x8c8>
ffffffffc0201438:	00005617          	auipc	a2,0x5
ffffffffc020143c:	44860613          	addi	a2,a2,1096 # ffffffffc0206880 <commands+0x838>
ffffffffc0201440:	0f200593          	li	a1,242
ffffffffc0201444:	00005517          	auipc	a0,0x5
ffffffffc0201448:	45450513          	addi	a0,a0,1108 # ffffffffc0206898 <commands+0x850>
ffffffffc020144c:	846ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201450:	00005697          	auipc	a3,0x5
ffffffffc0201454:	4a068693          	addi	a3,a3,1184 # ffffffffc02068f0 <commands+0x8a8>
ffffffffc0201458:	00005617          	auipc	a2,0x5
ffffffffc020145c:	42860613          	addi	a2,a2,1064 # ffffffffc0206880 <commands+0x838>
ffffffffc0201460:	0f100593          	li	a1,241
ffffffffc0201464:	00005517          	auipc	a0,0x5
ffffffffc0201468:	43450513          	addi	a0,a0,1076 # ffffffffc0206898 <commands+0x850>
ffffffffc020146c:	826ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201470:	00005697          	auipc	a3,0x5
ffffffffc0201474:	4a068693          	addi	a3,a3,1184 # ffffffffc0206910 <commands+0x8c8>
ffffffffc0201478:	00005617          	auipc	a2,0x5
ffffffffc020147c:	40860613          	addi	a2,a2,1032 # ffffffffc0206880 <commands+0x838>
ffffffffc0201480:	0d900593          	li	a1,217
ffffffffc0201484:	00005517          	auipc	a0,0x5
ffffffffc0201488:	41450513          	addi	a0,a0,1044 # ffffffffc0206898 <commands+0x850>
ffffffffc020148c:	806ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(count == 0);
ffffffffc0201490:	00005697          	auipc	a3,0x5
ffffffffc0201494:	72868693          	addi	a3,a3,1832 # ffffffffc0206bb8 <commands+0xb70>
ffffffffc0201498:	00005617          	auipc	a2,0x5
ffffffffc020149c:	3e860613          	addi	a2,a2,1000 # ffffffffc0206880 <commands+0x838>
ffffffffc02014a0:	14600593          	li	a1,326
ffffffffc02014a4:	00005517          	auipc	a0,0x5
ffffffffc02014a8:	3f450513          	addi	a0,a0,1012 # ffffffffc0206898 <commands+0x850>
ffffffffc02014ac:	fe7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc02014b0:	00005697          	auipc	a3,0x5
ffffffffc02014b4:	5a868693          	addi	a3,a3,1448 # ffffffffc0206a58 <commands+0xa10>
ffffffffc02014b8:	00005617          	auipc	a2,0x5
ffffffffc02014bc:	3c860613          	addi	a2,a2,968 # ffffffffc0206880 <commands+0x838>
ffffffffc02014c0:	13a00593          	li	a1,314
ffffffffc02014c4:	00005517          	auipc	a0,0x5
ffffffffc02014c8:	3d450513          	addi	a0,a0,980 # ffffffffc0206898 <commands+0x850>
ffffffffc02014cc:	fc7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014d0:	00005697          	auipc	a3,0x5
ffffffffc02014d4:	52868693          	addi	a3,a3,1320 # ffffffffc02069f8 <commands+0x9b0>
ffffffffc02014d8:	00005617          	auipc	a2,0x5
ffffffffc02014dc:	3a860613          	addi	a2,a2,936 # ffffffffc0206880 <commands+0x838>
ffffffffc02014e0:	13800593          	li	a1,312
ffffffffc02014e4:	00005517          	auipc	a0,0x5
ffffffffc02014e8:	3b450513          	addi	a0,a0,948 # ffffffffc0206898 <commands+0x850>
ffffffffc02014ec:	fa7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02014f0:	00005697          	auipc	a3,0x5
ffffffffc02014f4:	4c868693          	addi	a3,a3,1224 # ffffffffc02069b8 <commands+0x970>
ffffffffc02014f8:	00005617          	auipc	a2,0x5
ffffffffc02014fc:	38860613          	addi	a2,a2,904 # ffffffffc0206880 <commands+0x838>
ffffffffc0201500:	0df00593          	li	a1,223
ffffffffc0201504:	00005517          	auipc	a0,0x5
ffffffffc0201508:	39450513          	addi	a0,a0,916 # ffffffffc0206898 <commands+0x850>
ffffffffc020150c:	f87fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201510:	00005697          	auipc	a3,0x5
ffffffffc0201514:	66868693          	addi	a3,a3,1640 # ffffffffc0206b78 <commands+0xb30>
ffffffffc0201518:	00005617          	auipc	a2,0x5
ffffffffc020151c:	36860613          	addi	a2,a2,872 # ffffffffc0206880 <commands+0x838>
ffffffffc0201520:	13200593          	li	a1,306
ffffffffc0201524:	00005517          	auipc	a0,0x5
ffffffffc0201528:	37450513          	addi	a0,a0,884 # ffffffffc0206898 <commands+0x850>
ffffffffc020152c:	f67fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201530:	00005697          	auipc	a3,0x5
ffffffffc0201534:	62868693          	addi	a3,a3,1576 # ffffffffc0206b58 <commands+0xb10>
ffffffffc0201538:	00005617          	auipc	a2,0x5
ffffffffc020153c:	34860613          	addi	a2,a2,840 # ffffffffc0206880 <commands+0x838>
ffffffffc0201540:	13000593          	li	a1,304
ffffffffc0201544:	00005517          	auipc	a0,0x5
ffffffffc0201548:	35450513          	addi	a0,a0,852 # ffffffffc0206898 <commands+0x850>
ffffffffc020154c:	f47fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201550:	00005697          	auipc	a3,0x5
ffffffffc0201554:	5e068693          	addi	a3,a3,1504 # ffffffffc0206b30 <commands+0xae8>
ffffffffc0201558:	00005617          	auipc	a2,0x5
ffffffffc020155c:	32860613          	addi	a2,a2,808 # ffffffffc0206880 <commands+0x838>
ffffffffc0201560:	12e00593          	li	a1,302
ffffffffc0201564:	00005517          	auipc	a0,0x5
ffffffffc0201568:	33450513          	addi	a0,a0,820 # ffffffffc0206898 <commands+0x850>
ffffffffc020156c:	f27fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201570:	00005697          	auipc	a3,0x5
ffffffffc0201574:	59868693          	addi	a3,a3,1432 # ffffffffc0206b08 <commands+0xac0>
ffffffffc0201578:	00005617          	auipc	a2,0x5
ffffffffc020157c:	30860613          	addi	a2,a2,776 # ffffffffc0206880 <commands+0x838>
ffffffffc0201580:	12d00593          	li	a1,301
ffffffffc0201584:	00005517          	auipc	a0,0x5
ffffffffc0201588:	31450513          	addi	a0,a0,788 # ffffffffc0206898 <commands+0x850>
ffffffffc020158c:	f07fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201590:	00005697          	auipc	a3,0x5
ffffffffc0201594:	56868693          	addi	a3,a3,1384 # ffffffffc0206af8 <commands+0xab0>
ffffffffc0201598:	00005617          	auipc	a2,0x5
ffffffffc020159c:	2e860613          	addi	a2,a2,744 # ffffffffc0206880 <commands+0x838>
ffffffffc02015a0:	12800593          	li	a1,296
ffffffffc02015a4:	00005517          	auipc	a0,0x5
ffffffffc02015a8:	2f450513          	addi	a0,a0,756 # ffffffffc0206898 <commands+0x850>
ffffffffc02015ac:	ee7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015b0:	00005697          	auipc	a3,0x5
ffffffffc02015b4:	44868693          	addi	a3,a3,1096 # ffffffffc02069f8 <commands+0x9b0>
ffffffffc02015b8:	00005617          	auipc	a2,0x5
ffffffffc02015bc:	2c860613          	addi	a2,a2,712 # ffffffffc0206880 <commands+0x838>
ffffffffc02015c0:	12700593          	li	a1,295
ffffffffc02015c4:	00005517          	auipc	a0,0x5
ffffffffc02015c8:	2d450513          	addi	a0,a0,724 # ffffffffc0206898 <commands+0x850>
ffffffffc02015cc:	ec7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02015d0:	00005697          	auipc	a3,0x5
ffffffffc02015d4:	50868693          	addi	a3,a3,1288 # ffffffffc0206ad8 <commands+0xa90>
ffffffffc02015d8:	00005617          	auipc	a2,0x5
ffffffffc02015dc:	2a860613          	addi	a2,a2,680 # ffffffffc0206880 <commands+0x838>
ffffffffc02015e0:	12600593          	li	a1,294
ffffffffc02015e4:	00005517          	auipc	a0,0x5
ffffffffc02015e8:	2b450513          	addi	a0,a0,692 # ffffffffc0206898 <commands+0x850>
ffffffffc02015ec:	ea7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02015f0:	00005697          	auipc	a3,0x5
ffffffffc02015f4:	4b868693          	addi	a3,a3,1208 # ffffffffc0206aa8 <commands+0xa60>
ffffffffc02015f8:	00005617          	auipc	a2,0x5
ffffffffc02015fc:	28860613          	addi	a2,a2,648 # ffffffffc0206880 <commands+0x838>
ffffffffc0201600:	12500593          	li	a1,293
ffffffffc0201604:	00005517          	auipc	a0,0x5
ffffffffc0201608:	29450513          	addi	a0,a0,660 # ffffffffc0206898 <commands+0x850>
ffffffffc020160c:	e87fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201610:	00005697          	auipc	a3,0x5
ffffffffc0201614:	48068693          	addi	a3,a3,1152 # ffffffffc0206a90 <commands+0xa48>
ffffffffc0201618:	00005617          	auipc	a2,0x5
ffffffffc020161c:	26860613          	addi	a2,a2,616 # ffffffffc0206880 <commands+0x838>
ffffffffc0201620:	12400593          	li	a1,292
ffffffffc0201624:	00005517          	auipc	a0,0x5
ffffffffc0201628:	27450513          	addi	a0,a0,628 # ffffffffc0206898 <commands+0x850>
ffffffffc020162c:	e67fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201630:	00005697          	auipc	a3,0x5
ffffffffc0201634:	3c868693          	addi	a3,a3,968 # ffffffffc02069f8 <commands+0x9b0>
ffffffffc0201638:	00005617          	auipc	a2,0x5
ffffffffc020163c:	24860613          	addi	a2,a2,584 # ffffffffc0206880 <commands+0x838>
ffffffffc0201640:	11e00593          	li	a1,286
ffffffffc0201644:	00005517          	auipc	a0,0x5
ffffffffc0201648:	25450513          	addi	a0,a0,596 # ffffffffc0206898 <commands+0x850>
ffffffffc020164c:	e47fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201650:	00005697          	auipc	a3,0x5
ffffffffc0201654:	42868693          	addi	a3,a3,1064 # ffffffffc0206a78 <commands+0xa30>
ffffffffc0201658:	00005617          	auipc	a2,0x5
ffffffffc020165c:	22860613          	addi	a2,a2,552 # ffffffffc0206880 <commands+0x838>
ffffffffc0201660:	11900593          	li	a1,281
ffffffffc0201664:	00005517          	auipc	a0,0x5
ffffffffc0201668:	23450513          	addi	a0,a0,564 # ffffffffc0206898 <commands+0x850>
ffffffffc020166c:	e27fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201670:	00005697          	auipc	a3,0x5
ffffffffc0201674:	52868693          	addi	a3,a3,1320 # ffffffffc0206b98 <commands+0xb50>
ffffffffc0201678:	00005617          	auipc	a2,0x5
ffffffffc020167c:	20860613          	addi	a2,a2,520 # ffffffffc0206880 <commands+0x838>
ffffffffc0201680:	13700593          	li	a1,311
ffffffffc0201684:	00005517          	auipc	a0,0x5
ffffffffc0201688:	21450513          	addi	a0,a0,532 # ffffffffc0206898 <commands+0x850>
ffffffffc020168c:	e07fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == 0);
ffffffffc0201690:	00005697          	auipc	a3,0x5
ffffffffc0201694:	53868693          	addi	a3,a3,1336 # ffffffffc0206bc8 <commands+0xb80>
ffffffffc0201698:	00005617          	auipc	a2,0x5
ffffffffc020169c:	1e860613          	addi	a2,a2,488 # ffffffffc0206880 <commands+0x838>
ffffffffc02016a0:	14700593          	li	a1,327
ffffffffc02016a4:	00005517          	auipc	a0,0x5
ffffffffc02016a8:	1f450513          	addi	a0,a0,500 # ffffffffc0206898 <commands+0x850>
ffffffffc02016ac:	de7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == nr_free_pages());
ffffffffc02016b0:	00005697          	auipc	a3,0x5
ffffffffc02016b4:	20068693          	addi	a3,a3,512 # ffffffffc02068b0 <commands+0x868>
ffffffffc02016b8:	00005617          	auipc	a2,0x5
ffffffffc02016bc:	1c860613          	addi	a2,a2,456 # ffffffffc0206880 <commands+0x838>
ffffffffc02016c0:	11300593          	li	a1,275
ffffffffc02016c4:	00005517          	auipc	a0,0x5
ffffffffc02016c8:	1d450513          	addi	a0,a0,468 # ffffffffc0206898 <commands+0x850>
ffffffffc02016cc:	dc7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02016d0:	00005697          	auipc	a3,0x5
ffffffffc02016d4:	22068693          	addi	a3,a3,544 # ffffffffc02068f0 <commands+0x8a8>
ffffffffc02016d8:	00005617          	auipc	a2,0x5
ffffffffc02016dc:	1a860613          	addi	a2,a2,424 # ffffffffc0206880 <commands+0x838>
ffffffffc02016e0:	0d800593          	li	a1,216
ffffffffc02016e4:	00005517          	auipc	a0,0x5
ffffffffc02016e8:	1b450513          	addi	a0,a0,436 # ffffffffc0206898 <commands+0x850>
ffffffffc02016ec:	da7fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02016f0 <default_free_pages>:
{
ffffffffc02016f0:	1141                	addi	sp,sp,-16
ffffffffc02016f2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016f4:	14058463          	beqz	a1,ffffffffc020183c <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc02016f8:	00659693          	slli	a3,a1,0x6
ffffffffc02016fc:	96aa                	add	a3,a3,a0
ffffffffc02016fe:	87aa                	mv	a5,a0
ffffffffc0201700:	02d50263          	beq	a0,a3,ffffffffc0201724 <default_free_pages+0x34>
ffffffffc0201704:	6798                	ld	a4,8(a5)
ffffffffc0201706:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201708:	10071a63          	bnez	a4,ffffffffc020181c <default_free_pages+0x12c>
ffffffffc020170c:	6798                	ld	a4,8(a5)
ffffffffc020170e:	8b09                	andi	a4,a4,2
ffffffffc0201710:	10071663          	bnez	a4,ffffffffc020181c <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201714:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201718:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc020171c:	04078793          	addi	a5,a5,64
ffffffffc0201720:	fed792e3          	bne	a5,a3,ffffffffc0201704 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201724:	2581                	sext.w	a1,a1
ffffffffc0201726:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201728:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020172c:	4789                	li	a5,2
ffffffffc020172e:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201732:	000cc697          	auipc	a3,0xcc
ffffffffc0201736:	48e68693          	addi	a3,a3,1166 # ffffffffc02cdbc0 <free_area>
ffffffffc020173a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020173c:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020173e:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201742:	9db9                	addw	a1,a1,a4
ffffffffc0201744:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201746:	0ad78463          	beq	a5,a3,ffffffffc02017ee <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc020174a:	fe878713          	addi	a4,a5,-24
ffffffffc020174e:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201752:	4581                	li	a1,0
            if (base < page)
ffffffffc0201754:	00e56a63          	bltu	a0,a4,ffffffffc0201768 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201758:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020175a:	04d70c63          	beq	a4,a3,ffffffffc02017b2 <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc020175e:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201760:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201764:	fee57ae3          	bgeu	a0,a4,ffffffffc0201758 <default_free_pages+0x68>
ffffffffc0201768:	c199                	beqz	a1,ffffffffc020176e <default_free_pages+0x7e>
ffffffffc020176a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020176e:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201770:	e390                	sd	a2,0(a5)
ffffffffc0201772:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201774:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201776:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc0201778:	00d70d63          	beq	a4,a3,ffffffffc0201792 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc020177c:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201780:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201784:	02059813          	slli	a6,a1,0x20
ffffffffc0201788:	01a85793          	srli	a5,a6,0x1a
ffffffffc020178c:	97b2                	add	a5,a5,a2
ffffffffc020178e:	02f50c63          	beq	a0,a5,ffffffffc02017c6 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201792:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201794:	00d78c63          	beq	a5,a3,ffffffffc02017ac <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201798:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc020179a:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc020179e:	02061593          	slli	a1,a2,0x20
ffffffffc02017a2:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02017a6:	972a                	add	a4,a4,a0
ffffffffc02017a8:	04e68a63          	beq	a3,a4,ffffffffc02017fc <default_free_pages+0x10c>
}
ffffffffc02017ac:	60a2                	ld	ra,8(sp)
ffffffffc02017ae:	0141                	addi	sp,sp,16
ffffffffc02017b0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017b2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017b4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02017b6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02017b8:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc02017ba:	02d70763          	beq	a4,a3,ffffffffc02017e8 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc02017be:	8832                	mv	a6,a2
ffffffffc02017c0:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc02017c2:	87ba                	mv	a5,a4
ffffffffc02017c4:	bf71                	j	ffffffffc0201760 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02017c6:	491c                	lw	a5,16(a0)
ffffffffc02017c8:	9dbd                	addw	a1,a1,a5
ffffffffc02017ca:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02017ce:	57f5                	li	a5,-3
ffffffffc02017d0:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02017d4:	01853803          	ld	a6,24(a0)
ffffffffc02017d8:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc02017da:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02017dc:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc02017e0:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc02017e2:	0105b023          	sd	a6,0(a1)
ffffffffc02017e6:	b77d                	j	ffffffffc0201794 <default_free_pages+0xa4>
ffffffffc02017e8:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc02017ea:	873e                	mv	a4,a5
ffffffffc02017ec:	bf41                	j	ffffffffc020177c <default_free_pages+0x8c>
}
ffffffffc02017ee:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02017f0:	e390                	sd	a2,0(a5)
ffffffffc02017f2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017f4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017f6:	ed1c                	sd	a5,24(a0)
ffffffffc02017f8:	0141                	addi	sp,sp,16
ffffffffc02017fa:	8082                	ret
            base->property += p->property;
ffffffffc02017fc:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201800:	ff078693          	addi	a3,a5,-16
ffffffffc0201804:	9e39                	addw	a2,a2,a4
ffffffffc0201806:	c910                	sw	a2,16(a0)
ffffffffc0201808:	5775                	li	a4,-3
ffffffffc020180a:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020180e:	6398                	ld	a4,0(a5)
ffffffffc0201810:	679c                	ld	a5,8(a5)
}
ffffffffc0201812:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201814:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201816:	e398                	sd	a4,0(a5)
ffffffffc0201818:	0141                	addi	sp,sp,16
ffffffffc020181a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020181c:	00005697          	auipc	a3,0x5
ffffffffc0201820:	3c468693          	addi	a3,a3,964 # ffffffffc0206be0 <commands+0xb98>
ffffffffc0201824:	00005617          	auipc	a2,0x5
ffffffffc0201828:	05c60613          	addi	a2,a2,92 # ffffffffc0206880 <commands+0x838>
ffffffffc020182c:	09400593          	li	a1,148
ffffffffc0201830:	00005517          	auipc	a0,0x5
ffffffffc0201834:	06850513          	addi	a0,a0,104 # ffffffffc0206898 <commands+0x850>
ffffffffc0201838:	c5bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc020183c:	00005697          	auipc	a3,0x5
ffffffffc0201840:	39c68693          	addi	a3,a3,924 # ffffffffc0206bd8 <commands+0xb90>
ffffffffc0201844:	00005617          	auipc	a2,0x5
ffffffffc0201848:	03c60613          	addi	a2,a2,60 # ffffffffc0206880 <commands+0x838>
ffffffffc020184c:	09000593          	li	a1,144
ffffffffc0201850:	00005517          	auipc	a0,0x5
ffffffffc0201854:	04850513          	addi	a0,a0,72 # ffffffffc0206898 <commands+0x850>
ffffffffc0201858:	c3bfe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020185c <default_alloc_pages>:
    assert(n > 0);
ffffffffc020185c:	c941                	beqz	a0,ffffffffc02018ec <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc020185e:	000cc597          	auipc	a1,0xcc
ffffffffc0201862:	36258593          	addi	a1,a1,866 # ffffffffc02cdbc0 <free_area>
ffffffffc0201866:	0105a803          	lw	a6,16(a1)
ffffffffc020186a:	872a                	mv	a4,a0
ffffffffc020186c:	02081793          	slli	a5,a6,0x20
ffffffffc0201870:	9381                	srli	a5,a5,0x20
ffffffffc0201872:	00a7ee63          	bltu	a5,a0,ffffffffc020188e <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201876:	87ae                	mv	a5,a1
ffffffffc0201878:	a801                	j	ffffffffc0201888 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc020187a:	ff87a683          	lw	a3,-8(a5)
ffffffffc020187e:	02069613          	slli	a2,a3,0x20
ffffffffc0201882:	9201                	srli	a2,a2,0x20
ffffffffc0201884:	00e67763          	bgeu	a2,a4,ffffffffc0201892 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201888:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc020188a:	feb798e3          	bne	a5,a1,ffffffffc020187a <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020188e:	4501                	li	a0,0
}
ffffffffc0201890:	8082                	ret
    return listelm->prev;
ffffffffc0201892:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201896:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc020189a:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020189e:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02018a2:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02018a6:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc02018aa:	02c77863          	bgeu	a4,a2,ffffffffc02018da <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02018ae:	071a                	slli	a4,a4,0x6
ffffffffc02018b0:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02018b2:	41c686bb          	subw	a3,a3,t3
ffffffffc02018b6:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018b8:	00870613          	addi	a2,a4,8
ffffffffc02018bc:	4689                	li	a3,2
ffffffffc02018be:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02018c2:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02018c6:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc02018ca:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02018ce:	e290                	sd	a2,0(a3)
ffffffffc02018d0:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02018d4:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc02018d6:	01173c23          	sd	a7,24(a4)
ffffffffc02018da:	41c8083b          	subw	a6,a6,t3
ffffffffc02018de:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02018e2:	5775                	li	a4,-3
ffffffffc02018e4:	17c1                	addi	a5,a5,-16
ffffffffc02018e6:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02018ea:	8082                	ret
{
ffffffffc02018ec:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02018ee:	00005697          	auipc	a3,0x5
ffffffffc02018f2:	2ea68693          	addi	a3,a3,746 # ffffffffc0206bd8 <commands+0xb90>
ffffffffc02018f6:	00005617          	auipc	a2,0x5
ffffffffc02018fa:	f8a60613          	addi	a2,a2,-118 # ffffffffc0206880 <commands+0x838>
ffffffffc02018fe:	06c00593          	li	a1,108
ffffffffc0201902:	00005517          	auipc	a0,0x5
ffffffffc0201906:	f9650513          	addi	a0,a0,-106 # ffffffffc0206898 <commands+0x850>
{
ffffffffc020190a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020190c:	b87fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201910 <default_init_memmap>:
{
ffffffffc0201910:	1141                	addi	sp,sp,-16
ffffffffc0201912:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201914:	c5f1                	beqz	a1,ffffffffc02019e0 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201916:	00659693          	slli	a3,a1,0x6
ffffffffc020191a:	96aa                	add	a3,a3,a0
ffffffffc020191c:	87aa                	mv	a5,a0
ffffffffc020191e:	00d50f63          	beq	a0,a3,ffffffffc020193c <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201922:	6798                	ld	a4,8(a5)
ffffffffc0201924:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201926:	cf49                	beqz	a4,ffffffffc02019c0 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201928:	0007a823          	sw	zero,16(a5)
ffffffffc020192c:	0007b423          	sd	zero,8(a5)
ffffffffc0201930:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201934:	04078793          	addi	a5,a5,64
ffffffffc0201938:	fed795e3          	bne	a5,a3,ffffffffc0201922 <default_init_memmap+0x12>
    base->property = n;
ffffffffc020193c:	2581                	sext.w	a1,a1
ffffffffc020193e:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201940:	4789                	li	a5,2
ffffffffc0201942:	00850713          	addi	a4,a0,8
ffffffffc0201946:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020194a:	000cc697          	auipc	a3,0xcc
ffffffffc020194e:	27668693          	addi	a3,a3,630 # ffffffffc02cdbc0 <free_area>
ffffffffc0201952:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201954:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201956:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020195a:	9db9                	addw	a1,a1,a4
ffffffffc020195c:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc020195e:	04d78a63          	beq	a5,a3,ffffffffc02019b2 <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201962:	fe878713          	addi	a4,a5,-24
ffffffffc0201966:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc020196a:	4581                	li	a1,0
            if (base < page)
ffffffffc020196c:	00e56a63          	bltu	a0,a4,ffffffffc0201980 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201970:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201972:	02d70263          	beq	a4,a3,ffffffffc0201996 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201976:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201978:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc020197c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201970 <default_init_memmap+0x60>
ffffffffc0201980:	c199                	beqz	a1,ffffffffc0201986 <default_init_memmap+0x76>
ffffffffc0201982:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201986:	6398                	ld	a4,0(a5)
}
ffffffffc0201988:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020198a:	e390                	sd	a2,0(a5)
ffffffffc020198c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020198e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201990:	ed18                	sd	a4,24(a0)
ffffffffc0201992:	0141                	addi	sp,sp,16
ffffffffc0201994:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201996:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201998:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020199a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020199c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc020199e:	00d70663          	beq	a4,a3,ffffffffc02019aa <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc02019a2:	8832                	mv	a6,a2
ffffffffc02019a4:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc02019a6:	87ba                	mv	a5,a4
ffffffffc02019a8:	bfc1                	j	ffffffffc0201978 <default_init_memmap+0x68>
}
ffffffffc02019aa:	60a2                	ld	ra,8(sp)
ffffffffc02019ac:	e290                	sd	a2,0(a3)
ffffffffc02019ae:	0141                	addi	sp,sp,16
ffffffffc02019b0:	8082                	ret
ffffffffc02019b2:	60a2                	ld	ra,8(sp)
ffffffffc02019b4:	e390                	sd	a2,0(a5)
ffffffffc02019b6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02019b8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02019ba:	ed1c                	sd	a5,24(a0)
ffffffffc02019bc:	0141                	addi	sp,sp,16
ffffffffc02019be:	8082                	ret
        assert(PageReserved(p));
ffffffffc02019c0:	00005697          	auipc	a3,0x5
ffffffffc02019c4:	24868693          	addi	a3,a3,584 # ffffffffc0206c08 <commands+0xbc0>
ffffffffc02019c8:	00005617          	auipc	a2,0x5
ffffffffc02019cc:	eb860613          	addi	a2,a2,-328 # ffffffffc0206880 <commands+0x838>
ffffffffc02019d0:	04b00593          	li	a1,75
ffffffffc02019d4:	00005517          	auipc	a0,0x5
ffffffffc02019d8:	ec450513          	addi	a0,a0,-316 # ffffffffc0206898 <commands+0x850>
ffffffffc02019dc:	ab7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc02019e0:	00005697          	auipc	a3,0x5
ffffffffc02019e4:	1f868693          	addi	a3,a3,504 # ffffffffc0206bd8 <commands+0xb90>
ffffffffc02019e8:	00005617          	auipc	a2,0x5
ffffffffc02019ec:	e9860613          	addi	a2,a2,-360 # ffffffffc0206880 <commands+0x838>
ffffffffc02019f0:	04700593          	li	a1,71
ffffffffc02019f4:	00005517          	auipc	a0,0x5
ffffffffc02019f8:	ea450513          	addi	a0,a0,-348 # ffffffffc0206898 <commands+0x850>
ffffffffc02019fc:	a97fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201a00 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201a00:	c94d                	beqz	a0,ffffffffc0201ab2 <slob_free+0xb2>
{
ffffffffc0201a02:	1141                	addi	sp,sp,-16
ffffffffc0201a04:	e022                	sd	s0,0(sp)
ffffffffc0201a06:	e406                	sd	ra,8(sp)
ffffffffc0201a08:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201a0a:	e9c1                	bnez	a1,ffffffffc0201a9a <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a0c:	100027f3          	csrr	a5,sstatus
ffffffffc0201a10:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a12:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a14:	ebd9                	bnez	a5,ffffffffc0201aaa <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a16:	000cc617          	auipc	a2,0xcc
ffffffffc0201a1a:	d9a60613          	addi	a2,a2,-614 # ffffffffc02cd7b0 <slobfree>
ffffffffc0201a1e:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a20:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a22:	679c                	ld	a5,8(a5)
ffffffffc0201a24:	02877a63          	bgeu	a4,s0,ffffffffc0201a58 <slob_free+0x58>
ffffffffc0201a28:	00f46463          	bltu	s0,a5,ffffffffc0201a30 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a2c:	fef76ae3          	bltu	a4,a5,ffffffffc0201a20 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201a30:	400c                	lw	a1,0(s0)
ffffffffc0201a32:	00459693          	slli	a3,a1,0x4
ffffffffc0201a36:	96a2                	add	a3,a3,s0
ffffffffc0201a38:	02d78a63          	beq	a5,a3,ffffffffc0201a6c <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201a3c:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201a3e:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201a40:	00469793          	slli	a5,a3,0x4
ffffffffc0201a44:	97ba                	add	a5,a5,a4
ffffffffc0201a46:	02f40e63          	beq	s0,a5,ffffffffc0201a82 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201a4a:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201a4c:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201a4e:	e129                	bnez	a0,ffffffffc0201a90 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201a50:	60a2                	ld	ra,8(sp)
ffffffffc0201a52:	6402                	ld	s0,0(sp)
ffffffffc0201a54:	0141                	addi	sp,sp,16
ffffffffc0201a56:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a58:	fcf764e3          	bltu	a4,a5,ffffffffc0201a20 <slob_free+0x20>
ffffffffc0201a5c:	fcf472e3          	bgeu	s0,a5,ffffffffc0201a20 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201a60:	400c                	lw	a1,0(s0)
ffffffffc0201a62:	00459693          	slli	a3,a1,0x4
ffffffffc0201a66:	96a2                	add	a3,a3,s0
ffffffffc0201a68:	fcd79ae3          	bne	a5,a3,ffffffffc0201a3c <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201a6c:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201a6e:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201a70:	9db5                	addw	a1,a1,a3
ffffffffc0201a72:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201a74:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201a76:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201a78:	00469793          	slli	a5,a3,0x4
ffffffffc0201a7c:	97ba                	add	a5,a5,a4
ffffffffc0201a7e:	fcf416e3          	bne	s0,a5,ffffffffc0201a4a <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201a82:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201a84:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201a86:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201a88:	9ebd                	addw	a3,a3,a5
ffffffffc0201a8a:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201a8c:	e70c                	sd	a1,8(a4)
ffffffffc0201a8e:	d169                	beqz	a0,ffffffffc0201a50 <slob_free+0x50>
}
ffffffffc0201a90:	6402                	ld	s0,0(sp)
ffffffffc0201a92:	60a2                	ld	ra,8(sp)
ffffffffc0201a94:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201a96:	f13fe06f          	j	ffffffffc02009a8 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201a9a:	25bd                	addiw	a1,a1,15
ffffffffc0201a9c:	8191                	srli	a1,a1,0x4
ffffffffc0201a9e:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201aa0:	100027f3          	csrr	a5,sstatus
ffffffffc0201aa4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201aa6:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201aa8:	d7bd                	beqz	a5,ffffffffc0201a16 <slob_free+0x16>
        intr_disable();
ffffffffc0201aaa:	f05fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0201aae:	4505                	li	a0,1
ffffffffc0201ab0:	b79d                	j	ffffffffc0201a16 <slob_free+0x16>
ffffffffc0201ab2:	8082                	ret

ffffffffc0201ab4 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201ab4:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201ab6:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201ab8:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201abc:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201abe:	352000ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
	if (!page)
ffffffffc0201ac2:	c91d                	beqz	a0,ffffffffc0201af8 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201ac4:	000d0697          	auipc	a3,0xd0
ffffffffc0201ac8:	1946b683          	ld	a3,404(a3) # ffffffffc02d1c58 <pages>
ffffffffc0201acc:	8d15                	sub	a0,a0,a3
ffffffffc0201ace:	8519                	srai	a0,a0,0x6
ffffffffc0201ad0:	00007697          	auipc	a3,0x7
ffffffffc0201ad4:	b806b683          	ld	a3,-1152(a3) # ffffffffc0208650 <nbase>
ffffffffc0201ad8:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201ada:	00c51793          	slli	a5,a0,0xc
ffffffffc0201ade:	83b1                	srli	a5,a5,0xc
ffffffffc0201ae0:	000d0717          	auipc	a4,0xd0
ffffffffc0201ae4:	17073703          	ld	a4,368(a4) # ffffffffc02d1c50 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ae8:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201aea:	00e7fa63          	bgeu	a5,a4,ffffffffc0201afe <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201aee:	000d0697          	auipc	a3,0xd0
ffffffffc0201af2:	17a6b683          	ld	a3,378(a3) # ffffffffc02d1c68 <va_pa_offset>
ffffffffc0201af6:	9536                	add	a0,a0,a3
}
ffffffffc0201af8:	60a2                	ld	ra,8(sp)
ffffffffc0201afa:	0141                	addi	sp,sp,16
ffffffffc0201afc:	8082                	ret
ffffffffc0201afe:	86aa                	mv	a3,a0
ffffffffc0201b00:	00005617          	auipc	a2,0x5
ffffffffc0201b04:	16860613          	addi	a2,a2,360 # ffffffffc0206c68 <default_pmm_manager+0x38>
ffffffffc0201b08:	07100593          	li	a1,113
ffffffffc0201b0c:	00005517          	auipc	a0,0x5
ffffffffc0201b10:	18450513          	addi	a0,a0,388 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc0201b14:	97ffe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201b18 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201b18:	1101                	addi	sp,sp,-32
ffffffffc0201b1a:	ec06                	sd	ra,24(sp)
ffffffffc0201b1c:	e822                	sd	s0,16(sp)
ffffffffc0201b1e:	e426                	sd	s1,8(sp)
ffffffffc0201b20:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201b22:	01050713          	addi	a4,a0,16
ffffffffc0201b26:	6785                	lui	a5,0x1
ffffffffc0201b28:	0cf77363          	bgeu	a4,a5,ffffffffc0201bee <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201b2c:	00f50493          	addi	s1,a0,15
ffffffffc0201b30:	8091                	srli	s1,s1,0x4
ffffffffc0201b32:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b34:	10002673          	csrr	a2,sstatus
ffffffffc0201b38:	8a09                	andi	a2,a2,2
ffffffffc0201b3a:	e25d                	bnez	a2,ffffffffc0201be0 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201b3c:	000cc917          	auipc	s2,0xcc
ffffffffc0201b40:	c7490913          	addi	s2,s2,-908 # ffffffffc02cd7b0 <slobfree>
ffffffffc0201b44:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b48:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201b4a:	4398                	lw	a4,0(a5)
ffffffffc0201b4c:	08975e63          	bge	a4,s1,ffffffffc0201be8 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201b50:	00f68b63          	beq	a3,a5,ffffffffc0201b66 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b54:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201b56:	4018                	lw	a4,0(s0)
ffffffffc0201b58:	02975a63          	bge	a4,s1,ffffffffc0201b8c <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201b5c:	00093683          	ld	a3,0(s2)
ffffffffc0201b60:	87a2                	mv	a5,s0
ffffffffc0201b62:	fef699e3          	bne	a3,a5,ffffffffc0201b54 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201b66:	ee31                	bnez	a2,ffffffffc0201bc2 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201b68:	4501                	li	a0,0
ffffffffc0201b6a:	f4bff0ef          	jal	ra,ffffffffc0201ab4 <__slob_get_free_pages.constprop.0>
ffffffffc0201b6e:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201b70:	cd05                	beqz	a0,ffffffffc0201ba8 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201b72:	6585                	lui	a1,0x1
ffffffffc0201b74:	e8dff0ef          	jal	ra,ffffffffc0201a00 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b78:	10002673          	csrr	a2,sstatus
ffffffffc0201b7c:	8a09                	andi	a2,a2,2
ffffffffc0201b7e:	ee05                	bnez	a2,ffffffffc0201bb6 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201b80:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b84:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201b86:	4018                	lw	a4,0(s0)
ffffffffc0201b88:	fc974ae3          	blt	a4,s1,ffffffffc0201b5c <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201b8c:	04e48763          	beq	s1,a4,ffffffffc0201bda <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201b90:	00449693          	slli	a3,s1,0x4
ffffffffc0201b94:	96a2                	add	a3,a3,s0
ffffffffc0201b96:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201b98:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201b9a:	9f05                	subw	a4,a4,s1
ffffffffc0201b9c:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201b9e:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201ba0:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201ba2:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201ba6:	e20d                	bnez	a2,ffffffffc0201bc8 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201ba8:	60e2                	ld	ra,24(sp)
ffffffffc0201baa:	8522                	mv	a0,s0
ffffffffc0201bac:	6442                	ld	s0,16(sp)
ffffffffc0201bae:	64a2                	ld	s1,8(sp)
ffffffffc0201bb0:	6902                	ld	s2,0(sp)
ffffffffc0201bb2:	6105                	addi	sp,sp,32
ffffffffc0201bb4:	8082                	ret
        intr_disable();
ffffffffc0201bb6:	df9fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
			cur = slobfree;
ffffffffc0201bba:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201bbe:	4605                	li	a2,1
ffffffffc0201bc0:	b7d1                	j	ffffffffc0201b84 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201bc2:	de7fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201bc6:	b74d                	j	ffffffffc0201b68 <slob_alloc.constprop.0+0x50>
ffffffffc0201bc8:	de1fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
}
ffffffffc0201bcc:	60e2                	ld	ra,24(sp)
ffffffffc0201bce:	8522                	mv	a0,s0
ffffffffc0201bd0:	6442                	ld	s0,16(sp)
ffffffffc0201bd2:	64a2                	ld	s1,8(sp)
ffffffffc0201bd4:	6902                	ld	s2,0(sp)
ffffffffc0201bd6:	6105                	addi	sp,sp,32
ffffffffc0201bd8:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201bda:	6418                	ld	a4,8(s0)
ffffffffc0201bdc:	e798                	sd	a4,8(a5)
ffffffffc0201bde:	b7d1                	j	ffffffffc0201ba2 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201be0:	dcffe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0201be4:	4605                	li	a2,1
ffffffffc0201be6:	bf99                	j	ffffffffc0201b3c <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201be8:	843e                	mv	s0,a5
ffffffffc0201bea:	87b6                	mv	a5,a3
ffffffffc0201bec:	b745                	j	ffffffffc0201b8c <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201bee:	00005697          	auipc	a3,0x5
ffffffffc0201bf2:	0b268693          	addi	a3,a3,178 # ffffffffc0206ca0 <default_pmm_manager+0x70>
ffffffffc0201bf6:	00005617          	auipc	a2,0x5
ffffffffc0201bfa:	c8a60613          	addi	a2,a2,-886 # ffffffffc0206880 <commands+0x838>
ffffffffc0201bfe:	06300593          	li	a1,99
ffffffffc0201c02:	00005517          	auipc	a0,0x5
ffffffffc0201c06:	0be50513          	addi	a0,a0,190 # ffffffffc0206cc0 <default_pmm_manager+0x90>
ffffffffc0201c0a:	889fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201c0e <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201c0e:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201c10:	00005517          	auipc	a0,0x5
ffffffffc0201c14:	0c850513          	addi	a0,a0,200 # ffffffffc0206cd8 <default_pmm_manager+0xa8>
{
ffffffffc0201c18:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201c1a:	d7efe0ef          	jal	ra,ffffffffc0200198 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201c1e:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c20:	00005517          	auipc	a0,0x5
ffffffffc0201c24:	0d050513          	addi	a0,a0,208 # ffffffffc0206cf0 <default_pmm_manager+0xc0>
}
ffffffffc0201c28:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c2a:	d6efe06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0201c2e <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201c2e:	4501                	li	a0,0
ffffffffc0201c30:	8082                	ret

ffffffffc0201c32 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201c32:	1101                	addi	sp,sp,-32
ffffffffc0201c34:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201c36:	6905                	lui	s2,0x1
{
ffffffffc0201c38:	e822                	sd	s0,16(sp)
ffffffffc0201c3a:	ec06                	sd	ra,24(sp)
ffffffffc0201c3c:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201c3e:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8f51>
{
ffffffffc0201c42:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201c44:	04a7f963          	bgeu	a5,a0,ffffffffc0201c96 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201c48:	4561                	li	a0,24
ffffffffc0201c4a:	ecfff0ef          	jal	ra,ffffffffc0201b18 <slob_alloc.constprop.0>
ffffffffc0201c4e:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201c50:	c929                	beqz	a0,ffffffffc0201ca2 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201c52:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201c56:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201c58:	00f95763          	bge	s2,a5,ffffffffc0201c66 <kmalloc+0x34>
ffffffffc0201c5c:	6705                	lui	a4,0x1
ffffffffc0201c5e:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201c60:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201c62:	fef74ee3          	blt	a4,a5,ffffffffc0201c5e <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201c66:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201c68:	e4dff0ef          	jal	ra,ffffffffc0201ab4 <__slob_get_free_pages.constprop.0>
ffffffffc0201c6c:	e488                	sd	a0,8(s1)
ffffffffc0201c6e:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201c70:	c525                	beqz	a0,ffffffffc0201cd8 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c72:	100027f3          	csrr	a5,sstatus
ffffffffc0201c76:	8b89                	andi	a5,a5,2
ffffffffc0201c78:	ef8d                	bnez	a5,ffffffffc0201cb2 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201c7a:	000d0797          	auipc	a5,0xd0
ffffffffc0201c7e:	fbe78793          	addi	a5,a5,-66 # ffffffffc02d1c38 <bigblocks>
ffffffffc0201c82:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201c84:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201c86:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201c88:	60e2                	ld	ra,24(sp)
ffffffffc0201c8a:	8522                	mv	a0,s0
ffffffffc0201c8c:	6442                	ld	s0,16(sp)
ffffffffc0201c8e:	64a2                	ld	s1,8(sp)
ffffffffc0201c90:	6902                	ld	s2,0(sp)
ffffffffc0201c92:	6105                	addi	sp,sp,32
ffffffffc0201c94:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201c96:	0541                	addi	a0,a0,16
ffffffffc0201c98:	e81ff0ef          	jal	ra,ffffffffc0201b18 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201c9c:	01050413          	addi	s0,a0,16
ffffffffc0201ca0:	f565                	bnez	a0,ffffffffc0201c88 <kmalloc+0x56>
ffffffffc0201ca2:	4401                	li	s0,0
}
ffffffffc0201ca4:	60e2                	ld	ra,24(sp)
ffffffffc0201ca6:	8522                	mv	a0,s0
ffffffffc0201ca8:	6442                	ld	s0,16(sp)
ffffffffc0201caa:	64a2                	ld	s1,8(sp)
ffffffffc0201cac:	6902                	ld	s2,0(sp)
ffffffffc0201cae:	6105                	addi	sp,sp,32
ffffffffc0201cb0:	8082                	ret
        intr_disable();
ffffffffc0201cb2:	cfdfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
		bb->next = bigblocks;
ffffffffc0201cb6:	000d0797          	auipc	a5,0xd0
ffffffffc0201cba:	f8278793          	addi	a5,a5,-126 # ffffffffc02d1c38 <bigblocks>
ffffffffc0201cbe:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201cc0:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201cc2:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201cc4:	ce5fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
		return bb->pages;
ffffffffc0201cc8:	6480                	ld	s0,8(s1)
}
ffffffffc0201cca:	60e2                	ld	ra,24(sp)
ffffffffc0201ccc:	64a2                	ld	s1,8(sp)
ffffffffc0201cce:	8522                	mv	a0,s0
ffffffffc0201cd0:	6442                	ld	s0,16(sp)
ffffffffc0201cd2:	6902                	ld	s2,0(sp)
ffffffffc0201cd4:	6105                	addi	sp,sp,32
ffffffffc0201cd6:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201cd8:	45e1                	li	a1,24
ffffffffc0201cda:	8526                	mv	a0,s1
ffffffffc0201cdc:	d25ff0ef          	jal	ra,ffffffffc0201a00 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201ce0:	b765                	j	ffffffffc0201c88 <kmalloc+0x56>

ffffffffc0201ce2 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201ce2:	c169                	beqz	a0,ffffffffc0201da4 <kfree+0xc2>
{
ffffffffc0201ce4:	1101                	addi	sp,sp,-32
ffffffffc0201ce6:	e822                	sd	s0,16(sp)
ffffffffc0201ce8:	ec06                	sd	ra,24(sp)
ffffffffc0201cea:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201cec:	03451793          	slli	a5,a0,0x34
ffffffffc0201cf0:	842a                	mv	s0,a0
ffffffffc0201cf2:	e3d9                	bnez	a5,ffffffffc0201d78 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201cf4:	100027f3          	csrr	a5,sstatus
ffffffffc0201cf8:	8b89                	andi	a5,a5,2
ffffffffc0201cfa:	e7d9                	bnez	a5,ffffffffc0201d88 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201cfc:	000d0797          	auipc	a5,0xd0
ffffffffc0201d00:	f3c7b783          	ld	a5,-196(a5) # ffffffffc02d1c38 <bigblocks>
    return 0;
ffffffffc0201d04:	4601                	li	a2,0
ffffffffc0201d06:	cbad                	beqz	a5,ffffffffc0201d78 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201d08:	000d0697          	auipc	a3,0xd0
ffffffffc0201d0c:	f3068693          	addi	a3,a3,-208 # ffffffffc02d1c38 <bigblocks>
ffffffffc0201d10:	a021                	j	ffffffffc0201d18 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d12:	01048693          	addi	a3,s1,16
ffffffffc0201d16:	c3a5                	beqz	a5,ffffffffc0201d76 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201d18:	6798                	ld	a4,8(a5)
ffffffffc0201d1a:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201d1c:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201d1e:	fe871ae3          	bne	a4,s0,ffffffffc0201d12 <kfree+0x30>
				*last = bb->next;
ffffffffc0201d22:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201d24:	ee2d                	bnez	a2,ffffffffc0201d9e <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201d26:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201d2a:	4098                	lw	a4,0(s1)
ffffffffc0201d2c:	08f46963          	bltu	s0,a5,ffffffffc0201dbe <kfree+0xdc>
ffffffffc0201d30:	000d0697          	auipc	a3,0xd0
ffffffffc0201d34:	f386b683          	ld	a3,-200(a3) # ffffffffc02d1c68 <va_pa_offset>
ffffffffc0201d38:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201d3a:	8031                	srli	s0,s0,0xc
ffffffffc0201d3c:	000d0797          	auipc	a5,0xd0
ffffffffc0201d40:	f147b783          	ld	a5,-236(a5) # ffffffffc02d1c50 <npage>
ffffffffc0201d44:	06f47163          	bgeu	s0,a5,ffffffffc0201da6 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d48:	00007517          	auipc	a0,0x7
ffffffffc0201d4c:	90853503          	ld	a0,-1784(a0) # ffffffffc0208650 <nbase>
ffffffffc0201d50:	8c09                	sub	s0,s0,a0
ffffffffc0201d52:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201d54:	000d0517          	auipc	a0,0xd0
ffffffffc0201d58:	f0453503          	ld	a0,-252(a0) # ffffffffc02d1c58 <pages>
ffffffffc0201d5c:	4585                	li	a1,1
ffffffffc0201d5e:	9522                	add	a0,a0,s0
ffffffffc0201d60:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201d64:	0ea000ef          	jal	ra,ffffffffc0201e4e <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201d68:	6442                	ld	s0,16(sp)
ffffffffc0201d6a:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d6c:	8526                	mv	a0,s1
}
ffffffffc0201d6e:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d70:	45e1                	li	a1,24
}
ffffffffc0201d72:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d74:	b171                	j	ffffffffc0201a00 <slob_free>
ffffffffc0201d76:	e20d                	bnez	a2,ffffffffc0201d98 <kfree+0xb6>
ffffffffc0201d78:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201d7c:	6442                	ld	s0,16(sp)
ffffffffc0201d7e:	60e2                	ld	ra,24(sp)
ffffffffc0201d80:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d82:	4581                	li	a1,0
}
ffffffffc0201d84:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d86:	b9ad                	j	ffffffffc0201a00 <slob_free>
        intr_disable();
ffffffffc0201d88:	c27fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d8c:	000d0797          	auipc	a5,0xd0
ffffffffc0201d90:	eac7b783          	ld	a5,-340(a5) # ffffffffc02d1c38 <bigblocks>
        return 1;
ffffffffc0201d94:	4605                	li	a2,1
ffffffffc0201d96:	fbad                	bnez	a5,ffffffffc0201d08 <kfree+0x26>
        intr_enable();
ffffffffc0201d98:	c11fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201d9c:	bff1                	j	ffffffffc0201d78 <kfree+0x96>
ffffffffc0201d9e:	c0bfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201da2:	b751                	j	ffffffffc0201d26 <kfree+0x44>
ffffffffc0201da4:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201da6:	00005617          	auipc	a2,0x5
ffffffffc0201daa:	f9260613          	addi	a2,a2,-110 # ffffffffc0206d38 <default_pmm_manager+0x108>
ffffffffc0201dae:	06900593          	li	a1,105
ffffffffc0201db2:	00005517          	auipc	a0,0x5
ffffffffc0201db6:	ede50513          	addi	a0,a0,-290 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc0201dba:	ed8fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201dbe:	86a2                	mv	a3,s0
ffffffffc0201dc0:	00005617          	auipc	a2,0x5
ffffffffc0201dc4:	f5060613          	addi	a2,a2,-176 # ffffffffc0206d10 <default_pmm_manager+0xe0>
ffffffffc0201dc8:	07700593          	li	a1,119
ffffffffc0201dcc:	00005517          	auipc	a0,0x5
ffffffffc0201dd0:	ec450513          	addi	a0,a0,-316 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc0201dd4:	ebefe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201dd8 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201dd8:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201dda:	00005617          	auipc	a2,0x5
ffffffffc0201dde:	f5e60613          	addi	a2,a2,-162 # ffffffffc0206d38 <default_pmm_manager+0x108>
ffffffffc0201de2:	06900593          	li	a1,105
ffffffffc0201de6:	00005517          	auipc	a0,0x5
ffffffffc0201dea:	eaa50513          	addi	a0,a0,-342 # ffffffffc0206c90 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201dee:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201df0:	ea2fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201df4 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201df4:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201df6:	00005617          	auipc	a2,0x5
ffffffffc0201dfa:	f6260613          	addi	a2,a2,-158 # ffffffffc0206d58 <default_pmm_manager+0x128>
ffffffffc0201dfe:	07f00593          	li	a1,127
ffffffffc0201e02:	00005517          	auipc	a0,0x5
ffffffffc0201e06:	e8e50513          	addi	a0,a0,-370 # ffffffffc0206c90 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201e0a:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201e0c:	e86fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201e10 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e10:	100027f3          	csrr	a5,sstatus
ffffffffc0201e14:	8b89                	andi	a5,a5,2
ffffffffc0201e16:	e799                	bnez	a5,ffffffffc0201e24 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e18:	000d0797          	auipc	a5,0xd0
ffffffffc0201e1c:	e487b783          	ld	a5,-440(a5) # ffffffffc02d1c60 <pmm_manager>
ffffffffc0201e20:	6f9c                	ld	a5,24(a5)
ffffffffc0201e22:	8782                	jr	a5
{
ffffffffc0201e24:	1141                	addi	sp,sp,-16
ffffffffc0201e26:	e406                	sd	ra,8(sp)
ffffffffc0201e28:	e022                	sd	s0,0(sp)
ffffffffc0201e2a:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201e2c:	b83fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e30:	000d0797          	auipc	a5,0xd0
ffffffffc0201e34:	e307b783          	ld	a5,-464(a5) # ffffffffc02d1c60 <pmm_manager>
ffffffffc0201e38:	6f9c                	ld	a5,24(a5)
ffffffffc0201e3a:	8522                	mv	a0,s0
ffffffffc0201e3c:	9782                	jalr	a5
ffffffffc0201e3e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201e40:	b69fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201e44:	60a2                	ld	ra,8(sp)
ffffffffc0201e46:	8522                	mv	a0,s0
ffffffffc0201e48:	6402                	ld	s0,0(sp)
ffffffffc0201e4a:	0141                	addi	sp,sp,16
ffffffffc0201e4c:	8082                	ret

ffffffffc0201e4e <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e4e:	100027f3          	csrr	a5,sstatus
ffffffffc0201e52:	8b89                	andi	a5,a5,2
ffffffffc0201e54:	e799                	bnez	a5,ffffffffc0201e62 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201e56:	000d0797          	auipc	a5,0xd0
ffffffffc0201e5a:	e0a7b783          	ld	a5,-502(a5) # ffffffffc02d1c60 <pmm_manager>
ffffffffc0201e5e:	739c                	ld	a5,32(a5)
ffffffffc0201e60:	8782                	jr	a5
{
ffffffffc0201e62:	1101                	addi	sp,sp,-32
ffffffffc0201e64:	ec06                	sd	ra,24(sp)
ffffffffc0201e66:	e822                	sd	s0,16(sp)
ffffffffc0201e68:	e426                	sd	s1,8(sp)
ffffffffc0201e6a:	842a                	mv	s0,a0
ffffffffc0201e6c:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201e6e:	b41fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201e72:	000d0797          	auipc	a5,0xd0
ffffffffc0201e76:	dee7b783          	ld	a5,-530(a5) # ffffffffc02d1c60 <pmm_manager>
ffffffffc0201e7a:	739c                	ld	a5,32(a5)
ffffffffc0201e7c:	85a6                	mv	a1,s1
ffffffffc0201e7e:	8522                	mv	a0,s0
ffffffffc0201e80:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201e82:	6442                	ld	s0,16(sp)
ffffffffc0201e84:	60e2                	ld	ra,24(sp)
ffffffffc0201e86:	64a2                	ld	s1,8(sp)
ffffffffc0201e88:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201e8a:	b1ffe06f          	j	ffffffffc02009a8 <intr_enable>

ffffffffc0201e8e <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e8e:	100027f3          	csrr	a5,sstatus
ffffffffc0201e92:	8b89                	andi	a5,a5,2
ffffffffc0201e94:	e799                	bnez	a5,ffffffffc0201ea2 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e96:	000d0797          	auipc	a5,0xd0
ffffffffc0201e9a:	dca7b783          	ld	a5,-566(a5) # ffffffffc02d1c60 <pmm_manager>
ffffffffc0201e9e:	779c                	ld	a5,40(a5)
ffffffffc0201ea0:	8782                	jr	a5
{
ffffffffc0201ea2:	1141                	addi	sp,sp,-16
ffffffffc0201ea4:	e406                	sd	ra,8(sp)
ffffffffc0201ea6:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201ea8:	b07fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201eac:	000d0797          	auipc	a5,0xd0
ffffffffc0201eb0:	db47b783          	ld	a5,-588(a5) # ffffffffc02d1c60 <pmm_manager>
ffffffffc0201eb4:	779c                	ld	a5,40(a5)
ffffffffc0201eb6:	9782                	jalr	a5
ffffffffc0201eb8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201eba:	aeffe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201ebe:	60a2                	ld	ra,8(sp)
ffffffffc0201ec0:	8522                	mv	a0,s0
ffffffffc0201ec2:	6402                	ld	s0,0(sp)
ffffffffc0201ec4:	0141                	addi	sp,sp,16
ffffffffc0201ec6:	8082                	ret

ffffffffc0201ec8 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201ec8:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201ecc:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201ed0:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201ed2:	078e                	slli	a5,a5,0x3
{
ffffffffc0201ed4:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201ed6:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201eda:	6094                	ld	a3,0(s1)
{
ffffffffc0201edc:	f04a                	sd	s2,32(sp)
ffffffffc0201ede:	ec4e                	sd	s3,24(sp)
ffffffffc0201ee0:	e852                	sd	s4,16(sp)
ffffffffc0201ee2:	fc06                	sd	ra,56(sp)
ffffffffc0201ee4:	f822                	sd	s0,48(sp)
ffffffffc0201ee6:	e456                	sd	s5,8(sp)
ffffffffc0201ee8:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201eea:	0016f793          	andi	a5,a3,1
{
ffffffffc0201eee:	892e                	mv	s2,a1
ffffffffc0201ef0:	8a32                	mv	s4,a2
ffffffffc0201ef2:	000d0997          	auipc	s3,0xd0
ffffffffc0201ef6:	d5e98993          	addi	s3,s3,-674 # ffffffffc02d1c50 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201efa:	efbd                	bnez	a5,ffffffffc0201f78 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201efc:	14060c63          	beqz	a2,ffffffffc0202054 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f00:	100027f3          	csrr	a5,sstatus
ffffffffc0201f04:	8b89                	andi	a5,a5,2
ffffffffc0201f06:	14079963          	bnez	a5,ffffffffc0202058 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f0a:	000d0797          	auipc	a5,0xd0
ffffffffc0201f0e:	d567b783          	ld	a5,-682(a5) # ffffffffc02d1c60 <pmm_manager>
ffffffffc0201f12:	6f9c                	ld	a5,24(a5)
ffffffffc0201f14:	4505                	li	a0,1
ffffffffc0201f16:	9782                	jalr	a5
ffffffffc0201f18:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f1a:	12040d63          	beqz	s0,ffffffffc0202054 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201f1e:	000d0b17          	auipc	s6,0xd0
ffffffffc0201f22:	d3ab0b13          	addi	s6,s6,-710 # ffffffffc02d1c58 <pages>
ffffffffc0201f26:	000b3503          	ld	a0,0(s6)
ffffffffc0201f2a:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f2e:	000d0997          	auipc	s3,0xd0
ffffffffc0201f32:	d2298993          	addi	s3,s3,-734 # ffffffffc02d1c50 <npage>
ffffffffc0201f36:	40a40533          	sub	a0,s0,a0
ffffffffc0201f3a:	8519                	srai	a0,a0,0x6
ffffffffc0201f3c:	9556                	add	a0,a0,s5
ffffffffc0201f3e:	0009b703          	ld	a4,0(s3)
ffffffffc0201f42:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201f46:	4685                	li	a3,1
ffffffffc0201f48:	c014                	sw	a3,0(s0)
ffffffffc0201f4a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f4c:	0532                	slli	a0,a0,0xc
ffffffffc0201f4e:	16e7f763          	bgeu	a5,a4,ffffffffc02020bc <get_pte+0x1f4>
ffffffffc0201f52:	000d0797          	auipc	a5,0xd0
ffffffffc0201f56:	d167b783          	ld	a5,-746(a5) # ffffffffc02d1c68 <va_pa_offset>
ffffffffc0201f5a:	6605                	lui	a2,0x1
ffffffffc0201f5c:	4581                	li	a1,0
ffffffffc0201f5e:	953e                	add	a0,a0,a5
ffffffffc0201f60:	657030ef          	jal	ra,ffffffffc0205db6 <memset>
    return page - pages + nbase;
ffffffffc0201f64:	000b3683          	ld	a3,0(s6)
ffffffffc0201f68:	40d406b3          	sub	a3,s0,a3
ffffffffc0201f6c:	8699                	srai	a3,a3,0x6
ffffffffc0201f6e:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201f70:	06aa                	slli	a3,a3,0xa
ffffffffc0201f72:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201f76:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f78:	77fd                	lui	a5,0xfffff
ffffffffc0201f7a:	068a                	slli	a3,a3,0x2
ffffffffc0201f7c:	0009b703          	ld	a4,0(s3)
ffffffffc0201f80:	8efd                	and	a3,a3,a5
ffffffffc0201f82:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201f86:	10e7ff63          	bgeu	a5,a4,ffffffffc02020a4 <get_pte+0x1dc>
ffffffffc0201f8a:	000d0a97          	auipc	s5,0xd0
ffffffffc0201f8e:	cdea8a93          	addi	s5,s5,-802 # ffffffffc02d1c68 <va_pa_offset>
ffffffffc0201f92:	000ab403          	ld	s0,0(s5)
ffffffffc0201f96:	01595793          	srli	a5,s2,0x15
ffffffffc0201f9a:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f9e:	96a2                	add	a3,a3,s0
ffffffffc0201fa0:	00379413          	slli	s0,a5,0x3
ffffffffc0201fa4:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201fa6:	6014                	ld	a3,0(s0)
ffffffffc0201fa8:	0016f793          	andi	a5,a3,1
ffffffffc0201fac:	ebad                	bnez	a5,ffffffffc020201e <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fae:	0a0a0363          	beqz	s4,ffffffffc0202054 <get_pte+0x18c>
ffffffffc0201fb2:	100027f3          	csrr	a5,sstatus
ffffffffc0201fb6:	8b89                	andi	a5,a5,2
ffffffffc0201fb8:	efcd                	bnez	a5,ffffffffc0202072 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201fba:	000d0797          	auipc	a5,0xd0
ffffffffc0201fbe:	ca67b783          	ld	a5,-858(a5) # ffffffffc02d1c60 <pmm_manager>
ffffffffc0201fc2:	6f9c                	ld	a5,24(a5)
ffffffffc0201fc4:	4505                	li	a0,1
ffffffffc0201fc6:	9782                	jalr	a5
ffffffffc0201fc8:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fca:	c4c9                	beqz	s1,ffffffffc0202054 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201fcc:	000d0b17          	auipc	s6,0xd0
ffffffffc0201fd0:	c8cb0b13          	addi	s6,s6,-884 # ffffffffc02d1c58 <pages>
ffffffffc0201fd4:	000b3503          	ld	a0,0(s6)
ffffffffc0201fd8:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201fdc:	0009b703          	ld	a4,0(s3)
ffffffffc0201fe0:	40a48533          	sub	a0,s1,a0
ffffffffc0201fe4:	8519                	srai	a0,a0,0x6
ffffffffc0201fe6:	9552                	add	a0,a0,s4
ffffffffc0201fe8:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201fec:	4685                	li	a3,1
ffffffffc0201fee:	c094                	sw	a3,0(s1)
ffffffffc0201ff0:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ff2:	0532                	slli	a0,a0,0xc
ffffffffc0201ff4:	0ee7f163          	bgeu	a5,a4,ffffffffc02020d6 <get_pte+0x20e>
ffffffffc0201ff8:	000ab783          	ld	a5,0(s5)
ffffffffc0201ffc:	6605                	lui	a2,0x1
ffffffffc0201ffe:	4581                	li	a1,0
ffffffffc0202000:	953e                	add	a0,a0,a5
ffffffffc0202002:	5b5030ef          	jal	ra,ffffffffc0205db6 <memset>
    return page - pages + nbase;
ffffffffc0202006:	000b3683          	ld	a3,0(s6)
ffffffffc020200a:	40d486b3          	sub	a3,s1,a3
ffffffffc020200e:	8699                	srai	a3,a3,0x6
ffffffffc0202010:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202012:	06aa                	slli	a3,a3,0xa
ffffffffc0202014:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202018:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020201a:	0009b703          	ld	a4,0(s3)
ffffffffc020201e:	068a                	slli	a3,a3,0x2
ffffffffc0202020:	757d                	lui	a0,0xfffff
ffffffffc0202022:	8ee9                	and	a3,a3,a0
ffffffffc0202024:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202028:	06e7f263          	bgeu	a5,a4,ffffffffc020208c <get_pte+0x1c4>
ffffffffc020202c:	000ab503          	ld	a0,0(s5)
ffffffffc0202030:	00c95913          	srli	s2,s2,0xc
ffffffffc0202034:	1ff97913          	andi	s2,s2,511
ffffffffc0202038:	96aa                	add	a3,a3,a0
ffffffffc020203a:	00391513          	slli	a0,s2,0x3
ffffffffc020203e:	9536                	add	a0,a0,a3
}
ffffffffc0202040:	70e2                	ld	ra,56(sp)
ffffffffc0202042:	7442                	ld	s0,48(sp)
ffffffffc0202044:	74a2                	ld	s1,40(sp)
ffffffffc0202046:	7902                	ld	s2,32(sp)
ffffffffc0202048:	69e2                	ld	s3,24(sp)
ffffffffc020204a:	6a42                	ld	s4,16(sp)
ffffffffc020204c:	6aa2                	ld	s5,8(sp)
ffffffffc020204e:	6b02                	ld	s6,0(sp)
ffffffffc0202050:	6121                	addi	sp,sp,64
ffffffffc0202052:	8082                	ret
            return NULL;
ffffffffc0202054:	4501                	li	a0,0
ffffffffc0202056:	b7ed                	j	ffffffffc0202040 <get_pte+0x178>
        intr_disable();
ffffffffc0202058:	957fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020205c:	000d0797          	auipc	a5,0xd0
ffffffffc0202060:	c047b783          	ld	a5,-1020(a5) # ffffffffc02d1c60 <pmm_manager>
ffffffffc0202064:	6f9c                	ld	a5,24(a5)
ffffffffc0202066:	4505                	li	a0,1
ffffffffc0202068:	9782                	jalr	a5
ffffffffc020206a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020206c:	93dfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202070:	b56d                	j	ffffffffc0201f1a <get_pte+0x52>
        intr_disable();
ffffffffc0202072:	93dfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202076:	000d0797          	auipc	a5,0xd0
ffffffffc020207a:	bea7b783          	ld	a5,-1046(a5) # ffffffffc02d1c60 <pmm_manager>
ffffffffc020207e:	6f9c                	ld	a5,24(a5)
ffffffffc0202080:	4505                	li	a0,1
ffffffffc0202082:	9782                	jalr	a5
ffffffffc0202084:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0202086:	923fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020208a:	b781                	j	ffffffffc0201fca <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020208c:	00005617          	auipc	a2,0x5
ffffffffc0202090:	bdc60613          	addi	a2,a2,-1060 # ffffffffc0206c68 <default_pmm_manager+0x38>
ffffffffc0202094:	0fa00593          	li	a1,250
ffffffffc0202098:	00005517          	auipc	a0,0x5
ffffffffc020209c:	ce850513          	addi	a0,a0,-792 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02020a0:	bf2fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02020a4:	00005617          	auipc	a2,0x5
ffffffffc02020a8:	bc460613          	addi	a2,a2,-1084 # ffffffffc0206c68 <default_pmm_manager+0x38>
ffffffffc02020ac:	0ed00593          	li	a1,237
ffffffffc02020b0:	00005517          	auipc	a0,0x5
ffffffffc02020b4:	cd050513          	addi	a0,a0,-816 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02020b8:	bdafe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020bc:	86aa                	mv	a3,a0
ffffffffc02020be:	00005617          	auipc	a2,0x5
ffffffffc02020c2:	baa60613          	addi	a2,a2,-1110 # ffffffffc0206c68 <default_pmm_manager+0x38>
ffffffffc02020c6:	0e900593          	li	a1,233
ffffffffc02020ca:	00005517          	auipc	a0,0x5
ffffffffc02020ce:	cb650513          	addi	a0,a0,-842 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02020d2:	bc0fe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020d6:	86aa                	mv	a3,a0
ffffffffc02020d8:	00005617          	auipc	a2,0x5
ffffffffc02020dc:	b9060613          	addi	a2,a2,-1136 # ffffffffc0206c68 <default_pmm_manager+0x38>
ffffffffc02020e0:	0f700593          	li	a1,247
ffffffffc02020e4:	00005517          	auipc	a0,0x5
ffffffffc02020e8:	c9c50513          	addi	a0,a0,-868 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02020ec:	ba6fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02020f0 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02020f0:	1141                	addi	sp,sp,-16
ffffffffc02020f2:	e022                	sd	s0,0(sp)
ffffffffc02020f4:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02020f6:	4601                	li	a2,0
{
ffffffffc02020f8:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02020fa:	dcfff0ef          	jal	ra,ffffffffc0201ec8 <get_pte>
    if (ptep_store != NULL)
ffffffffc02020fe:	c011                	beqz	s0,ffffffffc0202102 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202100:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202102:	c511                	beqz	a0,ffffffffc020210e <get_page+0x1e>
ffffffffc0202104:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202106:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202108:	0017f713          	andi	a4,a5,1
ffffffffc020210c:	e709                	bnez	a4,ffffffffc0202116 <get_page+0x26>
}
ffffffffc020210e:	60a2                	ld	ra,8(sp)
ffffffffc0202110:	6402                	ld	s0,0(sp)
ffffffffc0202112:	0141                	addi	sp,sp,16
ffffffffc0202114:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202116:	078a                	slli	a5,a5,0x2
ffffffffc0202118:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020211a:	000d0717          	auipc	a4,0xd0
ffffffffc020211e:	b3673703          	ld	a4,-1226(a4) # ffffffffc02d1c50 <npage>
ffffffffc0202122:	00e7ff63          	bgeu	a5,a4,ffffffffc0202140 <get_page+0x50>
ffffffffc0202126:	60a2                	ld	ra,8(sp)
ffffffffc0202128:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc020212a:	fff80537          	lui	a0,0xfff80
ffffffffc020212e:	97aa                	add	a5,a5,a0
ffffffffc0202130:	079a                	slli	a5,a5,0x6
ffffffffc0202132:	000d0517          	auipc	a0,0xd0
ffffffffc0202136:	b2653503          	ld	a0,-1242(a0) # ffffffffc02d1c58 <pages>
ffffffffc020213a:	953e                	add	a0,a0,a5
ffffffffc020213c:	0141                	addi	sp,sp,16
ffffffffc020213e:	8082                	ret
ffffffffc0202140:	c99ff0ef          	jal	ra,ffffffffc0201dd8 <pa2page.part.0>

ffffffffc0202144 <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202144:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202146:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020214a:	f486                	sd	ra,104(sp)
ffffffffc020214c:	f0a2                	sd	s0,96(sp)
ffffffffc020214e:	eca6                	sd	s1,88(sp)
ffffffffc0202150:	e8ca                	sd	s2,80(sp)
ffffffffc0202152:	e4ce                	sd	s3,72(sp)
ffffffffc0202154:	e0d2                	sd	s4,64(sp)
ffffffffc0202156:	fc56                	sd	s5,56(sp)
ffffffffc0202158:	f85a                	sd	s6,48(sp)
ffffffffc020215a:	f45e                	sd	s7,40(sp)
ffffffffc020215c:	f062                	sd	s8,32(sp)
ffffffffc020215e:	ec66                	sd	s9,24(sp)
ffffffffc0202160:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202162:	17d2                	slli	a5,a5,0x34
ffffffffc0202164:	e3ed                	bnez	a5,ffffffffc0202246 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc0202166:	002007b7          	lui	a5,0x200
ffffffffc020216a:	842e                	mv	s0,a1
ffffffffc020216c:	0ef5ed63          	bltu	a1,a5,ffffffffc0202266 <unmap_range+0x122>
ffffffffc0202170:	8932                	mv	s2,a2
ffffffffc0202172:	0ec5fa63          	bgeu	a1,a2,ffffffffc0202266 <unmap_range+0x122>
ffffffffc0202176:	4785                	li	a5,1
ffffffffc0202178:	07fe                	slli	a5,a5,0x1f
ffffffffc020217a:	0ec7e663          	bltu	a5,a2,ffffffffc0202266 <unmap_range+0x122>
ffffffffc020217e:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc0202180:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc0202182:	000d0c97          	auipc	s9,0xd0
ffffffffc0202186:	acec8c93          	addi	s9,s9,-1330 # ffffffffc02d1c50 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020218a:	000d0c17          	auipc	s8,0xd0
ffffffffc020218e:	acec0c13          	addi	s8,s8,-1330 # ffffffffc02d1c58 <pages>
ffffffffc0202192:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc0202196:	000d0d17          	auipc	s10,0xd0
ffffffffc020219a:	acad0d13          	addi	s10,s10,-1334 # ffffffffc02d1c60 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020219e:	00200b37          	lui	s6,0x200
ffffffffc02021a2:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02021a6:	4601                	li	a2,0
ffffffffc02021a8:	85a2                	mv	a1,s0
ffffffffc02021aa:	854e                	mv	a0,s3
ffffffffc02021ac:	d1dff0ef          	jal	ra,ffffffffc0201ec8 <get_pte>
ffffffffc02021b0:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02021b2:	cd29                	beqz	a0,ffffffffc020220c <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc02021b4:	611c                	ld	a5,0(a0)
ffffffffc02021b6:	e395                	bnez	a5,ffffffffc02021da <unmap_range+0x96>
        start += PGSIZE;
ffffffffc02021b8:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02021ba:	ff2466e3          	bltu	s0,s2,ffffffffc02021a6 <unmap_range+0x62>
}
ffffffffc02021be:	70a6                	ld	ra,104(sp)
ffffffffc02021c0:	7406                	ld	s0,96(sp)
ffffffffc02021c2:	64e6                	ld	s1,88(sp)
ffffffffc02021c4:	6946                	ld	s2,80(sp)
ffffffffc02021c6:	69a6                	ld	s3,72(sp)
ffffffffc02021c8:	6a06                	ld	s4,64(sp)
ffffffffc02021ca:	7ae2                	ld	s5,56(sp)
ffffffffc02021cc:	7b42                	ld	s6,48(sp)
ffffffffc02021ce:	7ba2                	ld	s7,40(sp)
ffffffffc02021d0:	7c02                	ld	s8,32(sp)
ffffffffc02021d2:	6ce2                	ld	s9,24(sp)
ffffffffc02021d4:	6d42                	ld	s10,16(sp)
ffffffffc02021d6:	6165                	addi	sp,sp,112
ffffffffc02021d8:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc02021da:	0017f713          	andi	a4,a5,1
ffffffffc02021de:	df69                	beqz	a4,ffffffffc02021b8 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc02021e0:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02021e4:	078a                	slli	a5,a5,0x2
ffffffffc02021e6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02021e8:	08e7ff63          	bgeu	a5,a4,ffffffffc0202286 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc02021ec:	000c3503          	ld	a0,0(s8)
ffffffffc02021f0:	97de                	add	a5,a5,s7
ffffffffc02021f2:	079a                	slli	a5,a5,0x6
ffffffffc02021f4:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02021f6:	411c                	lw	a5,0(a0)
ffffffffc02021f8:	fff7871b          	addiw	a4,a5,-1
ffffffffc02021fc:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02021fe:	cf11                	beqz	a4,ffffffffc020221a <unmap_range+0xd6>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202200:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202204:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202208:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020220a:	bf45                	j	ffffffffc02021ba <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020220c:	945a                	add	s0,s0,s6
ffffffffc020220e:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0202212:	d455                	beqz	s0,ffffffffc02021be <unmap_range+0x7a>
ffffffffc0202214:	f92469e3          	bltu	s0,s2,ffffffffc02021a6 <unmap_range+0x62>
ffffffffc0202218:	b75d                	j	ffffffffc02021be <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020221a:	100027f3          	csrr	a5,sstatus
ffffffffc020221e:	8b89                	andi	a5,a5,2
ffffffffc0202220:	e799                	bnez	a5,ffffffffc020222e <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc0202222:	000d3783          	ld	a5,0(s10)
ffffffffc0202226:	4585                	li	a1,1
ffffffffc0202228:	739c                	ld	a5,32(a5)
ffffffffc020222a:	9782                	jalr	a5
    if (flag)
ffffffffc020222c:	bfd1                	j	ffffffffc0202200 <unmap_range+0xbc>
ffffffffc020222e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202230:	f7efe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202234:	000d3783          	ld	a5,0(s10)
ffffffffc0202238:	6522                	ld	a0,8(sp)
ffffffffc020223a:	4585                	li	a1,1
ffffffffc020223c:	739c                	ld	a5,32(a5)
ffffffffc020223e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202240:	f68fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202244:	bf75                	j	ffffffffc0202200 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202246:	00005697          	auipc	a3,0x5
ffffffffc020224a:	b4a68693          	addi	a3,a3,-1206 # ffffffffc0206d90 <default_pmm_manager+0x160>
ffffffffc020224e:	00004617          	auipc	a2,0x4
ffffffffc0202252:	63260613          	addi	a2,a2,1586 # ffffffffc0206880 <commands+0x838>
ffffffffc0202256:	12200593          	li	a1,290
ffffffffc020225a:	00005517          	auipc	a0,0x5
ffffffffc020225e:	b2650513          	addi	a0,a0,-1242 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202262:	a30fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202266:	00005697          	auipc	a3,0x5
ffffffffc020226a:	b5a68693          	addi	a3,a3,-1190 # ffffffffc0206dc0 <default_pmm_manager+0x190>
ffffffffc020226e:	00004617          	auipc	a2,0x4
ffffffffc0202272:	61260613          	addi	a2,a2,1554 # ffffffffc0206880 <commands+0x838>
ffffffffc0202276:	12300593          	li	a1,291
ffffffffc020227a:	00005517          	auipc	a0,0x5
ffffffffc020227e:	b0650513          	addi	a0,a0,-1274 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202282:	a10fe0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202286:	b53ff0ef          	jal	ra,ffffffffc0201dd8 <pa2page.part.0>

ffffffffc020228a <exit_range>:
{
ffffffffc020228a:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020228c:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202290:	fc86                	sd	ra,120(sp)
ffffffffc0202292:	f8a2                	sd	s0,112(sp)
ffffffffc0202294:	f4a6                	sd	s1,104(sp)
ffffffffc0202296:	f0ca                	sd	s2,96(sp)
ffffffffc0202298:	ecce                	sd	s3,88(sp)
ffffffffc020229a:	e8d2                	sd	s4,80(sp)
ffffffffc020229c:	e4d6                	sd	s5,72(sp)
ffffffffc020229e:	e0da                	sd	s6,64(sp)
ffffffffc02022a0:	fc5e                	sd	s7,56(sp)
ffffffffc02022a2:	f862                	sd	s8,48(sp)
ffffffffc02022a4:	f466                	sd	s9,40(sp)
ffffffffc02022a6:	f06a                	sd	s10,32(sp)
ffffffffc02022a8:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022aa:	17d2                	slli	a5,a5,0x34
ffffffffc02022ac:	20079a63          	bnez	a5,ffffffffc02024c0 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02022b0:	002007b7          	lui	a5,0x200
ffffffffc02022b4:	24f5e463          	bltu	a1,a5,ffffffffc02024fc <exit_range+0x272>
ffffffffc02022b8:	8ab2                	mv	s5,a2
ffffffffc02022ba:	24c5f163          	bgeu	a1,a2,ffffffffc02024fc <exit_range+0x272>
ffffffffc02022be:	4785                	li	a5,1
ffffffffc02022c0:	07fe                	slli	a5,a5,0x1f
ffffffffc02022c2:	22c7ed63          	bltu	a5,a2,ffffffffc02024fc <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02022c6:	c00009b7          	lui	s3,0xc0000
ffffffffc02022ca:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02022ce:	ffe00937          	lui	s2,0xffe00
ffffffffc02022d2:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc02022d6:	5cfd                	li	s9,-1
ffffffffc02022d8:	8c2a                	mv	s8,a0
ffffffffc02022da:	0125f933          	and	s2,a1,s2
ffffffffc02022de:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc02022e0:	000d0d17          	auipc	s10,0xd0
ffffffffc02022e4:	970d0d13          	addi	s10,s10,-1680 # ffffffffc02d1c50 <npage>
    return KADDR(page2pa(page));
ffffffffc02022e8:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02022ec:	000d0717          	auipc	a4,0xd0
ffffffffc02022f0:	96c70713          	addi	a4,a4,-1684 # ffffffffc02d1c58 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc02022f4:	000d0d97          	auipc	s11,0xd0
ffffffffc02022f8:	96cd8d93          	addi	s11,s11,-1684 # ffffffffc02d1c60 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02022fc:	c0000437          	lui	s0,0xc0000
ffffffffc0202300:	944e                	add	s0,s0,s3
ffffffffc0202302:	8079                	srli	s0,s0,0x1e
ffffffffc0202304:	1ff47413          	andi	s0,s0,511
ffffffffc0202308:	040e                	slli	s0,s0,0x3
ffffffffc020230a:	9462                	add	s0,s0,s8
ffffffffc020230c:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff38f0>
        if (pde1 & PTE_V)
ffffffffc0202310:	001a7793          	andi	a5,s4,1
ffffffffc0202314:	eb99                	bnez	a5,ffffffffc020232a <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202316:	12098463          	beqz	s3,ffffffffc020243e <exit_range+0x1b4>
ffffffffc020231a:	400007b7          	lui	a5,0x40000
ffffffffc020231e:	97ce                	add	a5,a5,s3
ffffffffc0202320:	894e                	mv	s2,s3
ffffffffc0202322:	1159fe63          	bgeu	s3,s5,ffffffffc020243e <exit_range+0x1b4>
ffffffffc0202326:	89be                	mv	s3,a5
ffffffffc0202328:	bfd1                	j	ffffffffc02022fc <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc020232a:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020232e:	0a0a                	slli	s4,s4,0x2
ffffffffc0202330:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202334:	1cfa7263          	bgeu	s4,a5,ffffffffc02024f8 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202338:	fff80637          	lui	a2,0xfff80
ffffffffc020233c:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc020233e:	000806b7          	lui	a3,0x80
ffffffffc0202342:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202344:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202348:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020234a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020234c:	18f5fa63          	bgeu	a1,a5,ffffffffc02024e0 <exit_range+0x256>
ffffffffc0202350:	000d0817          	auipc	a6,0xd0
ffffffffc0202354:	91880813          	addi	a6,a6,-1768 # ffffffffc02d1c68 <va_pa_offset>
ffffffffc0202358:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc020235c:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc020235e:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc0202362:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202364:	00080337          	lui	t1,0x80
ffffffffc0202368:	6885                	lui	a7,0x1
ffffffffc020236a:	a819                	j	ffffffffc0202380 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc020236c:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc020236e:	002007b7          	lui	a5,0x200
ffffffffc0202372:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202374:	08090c63          	beqz	s2,ffffffffc020240c <exit_range+0x182>
ffffffffc0202378:	09397a63          	bgeu	s2,s3,ffffffffc020240c <exit_range+0x182>
ffffffffc020237c:	0f597063          	bgeu	s2,s5,ffffffffc020245c <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc0202380:	01595493          	srli	s1,s2,0x15
ffffffffc0202384:	1ff4f493          	andi	s1,s1,511
ffffffffc0202388:	048e                	slli	s1,s1,0x3
ffffffffc020238a:	94da                	add	s1,s1,s6
ffffffffc020238c:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc020238e:	0017f693          	andi	a3,a5,1
ffffffffc0202392:	dee9                	beqz	a3,ffffffffc020236c <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc0202394:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202398:	078a                	slli	a5,a5,0x2
ffffffffc020239a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020239c:	14b7fe63          	bgeu	a5,a1,ffffffffc02024f8 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02023a0:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02023a2:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02023a6:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02023aa:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02023ae:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02023b0:	12bef863          	bgeu	t4,a1,ffffffffc02024e0 <exit_range+0x256>
ffffffffc02023b4:	00083783          	ld	a5,0(a6)
ffffffffc02023b8:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02023ba:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc02023be:	629c                	ld	a5,0(a3)
ffffffffc02023c0:	8b85                	andi	a5,a5,1
ffffffffc02023c2:	f7d5                	bnez	a5,ffffffffc020236e <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02023c4:	06a1                	addi	a3,a3,8
ffffffffc02023c6:	fed59ce3          	bne	a1,a3,ffffffffc02023be <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc02023ca:	631c                	ld	a5,0(a4)
ffffffffc02023cc:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02023ce:	100027f3          	csrr	a5,sstatus
ffffffffc02023d2:	8b89                	andi	a5,a5,2
ffffffffc02023d4:	e7d9                	bnez	a5,ffffffffc0202462 <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc02023d6:	000db783          	ld	a5,0(s11)
ffffffffc02023da:	4585                	li	a1,1
ffffffffc02023dc:	e032                	sd	a2,0(sp)
ffffffffc02023de:	739c                	ld	a5,32(a5)
ffffffffc02023e0:	9782                	jalr	a5
    if (flag)
ffffffffc02023e2:	6602                	ld	a2,0(sp)
ffffffffc02023e4:	000d0817          	auipc	a6,0xd0
ffffffffc02023e8:	88480813          	addi	a6,a6,-1916 # ffffffffc02d1c68 <va_pa_offset>
ffffffffc02023ec:	fff80e37          	lui	t3,0xfff80
ffffffffc02023f0:	00080337          	lui	t1,0x80
ffffffffc02023f4:	6885                	lui	a7,0x1
ffffffffc02023f6:	000d0717          	auipc	a4,0xd0
ffffffffc02023fa:	86270713          	addi	a4,a4,-1950 # ffffffffc02d1c58 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02023fe:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc0202402:	002007b7          	lui	a5,0x200
ffffffffc0202406:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202408:	f60918e3          	bnez	s2,ffffffffc0202378 <exit_range+0xee>
            if (free_pd0)
ffffffffc020240c:	f00b85e3          	beqz	s7,ffffffffc0202316 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc0202410:	000d3783          	ld	a5,0(s10)
ffffffffc0202414:	0efa7263          	bgeu	s4,a5,ffffffffc02024f8 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202418:	6308                	ld	a0,0(a4)
ffffffffc020241a:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020241c:	100027f3          	csrr	a5,sstatus
ffffffffc0202420:	8b89                	andi	a5,a5,2
ffffffffc0202422:	efad                	bnez	a5,ffffffffc020249c <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0202424:	000db783          	ld	a5,0(s11)
ffffffffc0202428:	4585                	li	a1,1
ffffffffc020242a:	739c                	ld	a5,32(a5)
ffffffffc020242c:	9782                	jalr	a5
ffffffffc020242e:	000d0717          	auipc	a4,0xd0
ffffffffc0202432:	82a70713          	addi	a4,a4,-2006 # ffffffffc02d1c58 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202436:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc020243a:	ee0990e3          	bnez	s3,ffffffffc020231a <exit_range+0x90>
}
ffffffffc020243e:	70e6                	ld	ra,120(sp)
ffffffffc0202440:	7446                	ld	s0,112(sp)
ffffffffc0202442:	74a6                	ld	s1,104(sp)
ffffffffc0202444:	7906                	ld	s2,96(sp)
ffffffffc0202446:	69e6                	ld	s3,88(sp)
ffffffffc0202448:	6a46                	ld	s4,80(sp)
ffffffffc020244a:	6aa6                	ld	s5,72(sp)
ffffffffc020244c:	6b06                	ld	s6,64(sp)
ffffffffc020244e:	7be2                	ld	s7,56(sp)
ffffffffc0202450:	7c42                	ld	s8,48(sp)
ffffffffc0202452:	7ca2                	ld	s9,40(sp)
ffffffffc0202454:	7d02                	ld	s10,32(sp)
ffffffffc0202456:	6de2                	ld	s11,24(sp)
ffffffffc0202458:	6109                	addi	sp,sp,128
ffffffffc020245a:	8082                	ret
            if (free_pd0)
ffffffffc020245c:	ea0b8fe3          	beqz	s7,ffffffffc020231a <exit_range+0x90>
ffffffffc0202460:	bf45                	j	ffffffffc0202410 <exit_range+0x186>
ffffffffc0202462:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202464:	e42a                	sd	a0,8(sp)
ffffffffc0202466:	d48fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020246a:	000db783          	ld	a5,0(s11)
ffffffffc020246e:	6522                	ld	a0,8(sp)
ffffffffc0202470:	4585                	li	a1,1
ffffffffc0202472:	739c                	ld	a5,32(a5)
ffffffffc0202474:	9782                	jalr	a5
        intr_enable();
ffffffffc0202476:	d32fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020247a:	6602                	ld	a2,0(sp)
ffffffffc020247c:	000cf717          	auipc	a4,0xcf
ffffffffc0202480:	7dc70713          	addi	a4,a4,2012 # ffffffffc02d1c58 <pages>
ffffffffc0202484:	6885                	lui	a7,0x1
ffffffffc0202486:	00080337          	lui	t1,0x80
ffffffffc020248a:	fff80e37          	lui	t3,0xfff80
ffffffffc020248e:	000cf817          	auipc	a6,0xcf
ffffffffc0202492:	7da80813          	addi	a6,a6,2010 # ffffffffc02d1c68 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202496:	0004b023          	sd	zero,0(s1)
ffffffffc020249a:	b7a5                	j	ffffffffc0202402 <exit_range+0x178>
ffffffffc020249c:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc020249e:	d10fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02024a2:	000db783          	ld	a5,0(s11)
ffffffffc02024a6:	6502                	ld	a0,0(sp)
ffffffffc02024a8:	4585                	li	a1,1
ffffffffc02024aa:	739c                	ld	a5,32(a5)
ffffffffc02024ac:	9782                	jalr	a5
        intr_enable();
ffffffffc02024ae:	cfafe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02024b2:	000cf717          	auipc	a4,0xcf
ffffffffc02024b6:	7a670713          	addi	a4,a4,1958 # ffffffffc02d1c58 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02024ba:	00043023          	sd	zero,0(s0)
ffffffffc02024be:	bfb5                	j	ffffffffc020243a <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02024c0:	00005697          	auipc	a3,0x5
ffffffffc02024c4:	8d068693          	addi	a3,a3,-1840 # ffffffffc0206d90 <default_pmm_manager+0x160>
ffffffffc02024c8:	00004617          	auipc	a2,0x4
ffffffffc02024cc:	3b860613          	addi	a2,a2,952 # ffffffffc0206880 <commands+0x838>
ffffffffc02024d0:	13700593          	li	a1,311
ffffffffc02024d4:	00005517          	auipc	a0,0x5
ffffffffc02024d8:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02024dc:	fb7fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc02024e0:	00004617          	auipc	a2,0x4
ffffffffc02024e4:	78860613          	addi	a2,a2,1928 # ffffffffc0206c68 <default_pmm_manager+0x38>
ffffffffc02024e8:	07100593          	li	a1,113
ffffffffc02024ec:	00004517          	auipc	a0,0x4
ffffffffc02024f0:	7a450513          	addi	a0,a0,1956 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc02024f4:	f9ffd0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc02024f8:	8e1ff0ef          	jal	ra,ffffffffc0201dd8 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02024fc:	00005697          	auipc	a3,0x5
ffffffffc0202500:	8c468693          	addi	a3,a3,-1852 # ffffffffc0206dc0 <default_pmm_manager+0x190>
ffffffffc0202504:	00004617          	auipc	a2,0x4
ffffffffc0202508:	37c60613          	addi	a2,a2,892 # ffffffffc0206880 <commands+0x838>
ffffffffc020250c:	13800593          	li	a1,312
ffffffffc0202510:	00005517          	auipc	a0,0x5
ffffffffc0202514:	87050513          	addi	a0,a0,-1936 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202518:	f7bfd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020251c <page_remove>:
{
ffffffffc020251c:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020251e:	4601                	li	a2,0
{
ffffffffc0202520:	ec26                	sd	s1,24(sp)
ffffffffc0202522:	f406                	sd	ra,40(sp)
ffffffffc0202524:	f022                	sd	s0,32(sp)
ffffffffc0202526:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202528:	9a1ff0ef          	jal	ra,ffffffffc0201ec8 <get_pte>
    if (ptep != NULL)
ffffffffc020252c:	c511                	beqz	a0,ffffffffc0202538 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc020252e:	611c                	ld	a5,0(a0)
ffffffffc0202530:	842a                	mv	s0,a0
ffffffffc0202532:	0017f713          	andi	a4,a5,1
ffffffffc0202536:	e711                	bnez	a4,ffffffffc0202542 <page_remove+0x26>
}
ffffffffc0202538:	70a2                	ld	ra,40(sp)
ffffffffc020253a:	7402                	ld	s0,32(sp)
ffffffffc020253c:	64e2                	ld	s1,24(sp)
ffffffffc020253e:	6145                	addi	sp,sp,48
ffffffffc0202540:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202542:	078a                	slli	a5,a5,0x2
ffffffffc0202544:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202546:	000cf717          	auipc	a4,0xcf
ffffffffc020254a:	70a73703          	ld	a4,1802(a4) # ffffffffc02d1c50 <npage>
ffffffffc020254e:	06e7f363          	bgeu	a5,a4,ffffffffc02025b4 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202552:	fff80537          	lui	a0,0xfff80
ffffffffc0202556:	97aa                	add	a5,a5,a0
ffffffffc0202558:	079a                	slli	a5,a5,0x6
ffffffffc020255a:	000cf517          	auipc	a0,0xcf
ffffffffc020255e:	6fe53503          	ld	a0,1790(a0) # ffffffffc02d1c58 <pages>
ffffffffc0202562:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202564:	411c                	lw	a5,0(a0)
ffffffffc0202566:	fff7871b          	addiw	a4,a5,-1
ffffffffc020256a:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020256c:	cb11                	beqz	a4,ffffffffc0202580 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc020256e:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202572:	12048073          	sfence.vma	s1
}
ffffffffc0202576:	70a2                	ld	ra,40(sp)
ffffffffc0202578:	7402                	ld	s0,32(sp)
ffffffffc020257a:	64e2                	ld	s1,24(sp)
ffffffffc020257c:	6145                	addi	sp,sp,48
ffffffffc020257e:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202580:	100027f3          	csrr	a5,sstatus
ffffffffc0202584:	8b89                	andi	a5,a5,2
ffffffffc0202586:	eb89                	bnez	a5,ffffffffc0202598 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202588:	000cf797          	auipc	a5,0xcf
ffffffffc020258c:	6d87b783          	ld	a5,1752(a5) # ffffffffc02d1c60 <pmm_manager>
ffffffffc0202590:	739c                	ld	a5,32(a5)
ffffffffc0202592:	4585                	li	a1,1
ffffffffc0202594:	9782                	jalr	a5
    if (flag)
ffffffffc0202596:	bfe1                	j	ffffffffc020256e <page_remove+0x52>
        intr_disable();
ffffffffc0202598:	e42a                	sd	a0,8(sp)
ffffffffc020259a:	c14fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc020259e:	000cf797          	auipc	a5,0xcf
ffffffffc02025a2:	6c27b783          	ld	a5,1730(a5) # ffffffffc02d1c60 <pmm_manager>
ffffffffc02025a6:	739c                	ld	a5,32(a5)
ffffffffc02025a8:	6522                	ld	a0,8(sp)
ffffffffc02025aa:	4585                	li	a1,1
ffffffffc02025ac:	9782                	jalr	a5
        intr_enable();
ffffffffc02025ae:	bfafe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02025b2:	bf75                	j	ffffffffc020256e <page_remove+0x52>
ffffffffc02025b4:	825ff0ef          	jal	ra,ffffffffc0201dd8 <pa2page.part.0>

ffffffffc02025b8 <page_insert>:
{
ffffffffc02025b8:	7139                	addi	sp,sp,-64
ffffffffc02025ba:	e852                	sd	s4,16(sp)
ffffffffc02025bc:	8a32                	mv	s4,a2
ffffffffc02025be:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02025c0:	4605                	li	a2,1
{
ffffffffc02025c2:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02025c4:	85d2                	mv	a1,s4
{
ffffffffc02025c6:	f426                	sd	s1,40(sp)
ffffffffc02025c8:	fc06                	sd	ra,56(sp)
ffffffffc02025ca:	f04a                	sd	s2,32(sp)
ffffffffc02025cc:	ec4e                	sd	s3,24(sp)
ffffffffc02025ce:	e456                	sd	s5,8(sp)
ffffffffc02025d0:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02025d2:	8f7ff0ef          	jal	ra,ffffffffc0201ec8 <get_pte>
    if (ptep == NULL)
ffffffffc02025d6:	c961                	beqz	a0,ffffffffc02026a6 <page_insert+0xee>
    page->ref += 1;
ffffffffc02025d8:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc02025da:	611c                	ld	a5,0(a0)
ffffffffc02025dc:	89aa                	mv	s3,a0
ffffffffc02025de:	0016871b          	addiw	a4,a3,1
ffffffffc02025e2:	c018                	sw	a4,0(s0)
ffffffffc02025e4:	0017f713          	andi	a4,a5,1
ffffffffc02025e8:	ef05                	bnez	a4,ffffffffc0202620 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc02025ea:	000cf717          	auipc	a4,0xcf
ffffffffc02025ee:	66e73703          	ld	a4,1646(a4) # ffffffffc02d1c58 <pages>
ffffffffc02025f2:	8c19                	sub	s0,s0,a4
ffffffffc02025f4:	000807b7          	lui	a5,0x80
ffffffffc02025f8:	8419                	srai	s0,s0,0x6
ffffffffc02025fa:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02025fc:	042a                	slli	s0,s0,0xa
ffffffffc02025fe:	8cc1                	or	s1,s1,s0
ffffffffc0202600:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202604:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff38f0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202608:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc020260c:	4501                	li	a0,0
}
ffffffffc020260e:	70e2                	ld	ra,56(sp)
ffffffffc0202610:	7442                	ld	s0,48(sp)
ffffffffc0202612:	74a2                	ld	s1,40(sp)
ffffffffc0202614:	7902                	ld	s2,32(sp)
ffffffffc0202616:	69e2                	ld	s3,24(sp)
ffffffffc0202618:	6a42                	ld	s4,16(sp)
ffffffffc020261a:	6aa2                	ld	s5,8(sp)
ffffffffc020261c:	6121                	addi	sp,sp,64
ffffffffc020261e:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202620:	078a                	slli	a5,a5,0x2
ffffffffc0202622:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202624:	000cf717          	auipc	a4,0xcf
ffffffffc0202628:	62c73703          	ld	a4,1580(a4) # ffffffffc02d1c50 <npage>
ffffffffc020262c:	06e7ff63          	bgeu	a5,a4,ffffffffc02026aa <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202630:	000cfa97          	auipc	s5,0xcf
ffffffffc0202634:	628a8a93          	addi	s5,s5,1576 # ffffffffc02d1c58 <pages>
ffffffffc0202638:	000ab703          	ld	a4,0(s5)
ffffffffc020263c:	fff80937          	lui	s2,0xfff80
ffffffffc0202640:	993e                	add	s2,s2,a5
ffffffffc0202642:	091a                	slli	s2,s2,0x6
ffffffffc0202644:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0202646:	01240c63          	beq	s0,s2,ffffffffc020265e <page_insert+0xa6>
    page->ref -= 1;
ffffffffc020264a:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcae358>
ffffffffc020264e:	fff7869b          	addiw	a3,a5,-1
ffffffffc0202652:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc0202656:	c691                	beqz	a3,ffffffffc0202662 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202658:	120a0073          	sfence.vma	s4
}
ffffffffc020265c:	bf59                	j	ffffffffc02025f2 <page_insert+0x3a>
ffffffffc020265e:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202660:	bf49                	j	ffffffffc02025f2 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202662:	100027f3          	csrr	a5,sstatus
ffffffffc0202666:	8b89                	andi	a5,a5,2
ffffffffc0202668:	ef91                	bnez	a5,ffffffffc0202684 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc020266a:	000cf797          	auipc	a5,0xcf
ffffffffc020266e:	5f67b783          	ld	a5,1526(a5) # ffffffffc02d1c60 <pmm_manager>
ffffffffc0202672:	739c                	ld	a5,32(a5)
ffffffffc0202674:	4585                	li	a1,1
ffffffffc0202676:	854a                	mv	a0,s2
ffffffffc0202678:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020267a:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020267e:	120a0073          	sfence.vma	s4
ffffffffc0202682:	bf85                	j	ffffffffc02025f2 <page_insert+0x3a>
        intr_disable();
ffffffffc0202684:	b2afe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202688:	000cf797          	auipc	a5,0xcf
ffffffffc020268c:	5d87b783          	ld	a5,1496(a5) # ffffffffc02d1c60 <pmm_manager>
ffffffffc0202690:	739c                	ld	a5,32(a5)
ffffffffc0202692:	4585                	li	a1,1
ffffffffc0202694:	854a                	mv	a0,s2
ffffffffc0202696:	9782                	jalr	a5
        intr_enable();
ffffffffc0202698:	b10fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020269c:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026a0:	120a0073          	sfence.vma	s4
ffffffffc02026a4:	b7b9                	j	ffffffffc02025f2 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02026a6:	5571                	li	a0,-4
ffffffffc02026a8:	b79d                	j	ffffffffc020260e <page_insert+0x56>
ffffffffc02026aa:	f2eff0ef          	jal	ra,ffffffffc0201dd8 <pa2page.part.0>

ffffffffc02026ae <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02026ae:	00004797          	auipc	a5,0x4
ffffffffc02026b2:	58278793          	addi	a5,a5,1410 # ffffffffc0206c30 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02026b6:	638c                	ld	a1,0(a5)
{
ffffffffc02026b8:	7159                	addi	sp,sp,-112
ffffffffc02026ba:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02026bc:	00004517          	auipc	a0,0x4
ffffffffc02026c0:	71c50513          	addi	a0,a0,1820 # ffffffffc0206dd8 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc02026c4:	000cfb17          	auipc	s6,0xcf
ffffffffc02026c8:	59cb0b13          	addi	s6,s6,1436 # ffffffffc02d1c60 <pmm_manager>
{
ffffffffc02026cc:	f486                	sd	ra,104(sp)
ffffffffc02026ce:	e8ca                	sd	s2,80(sp)
ffffffffc02026d0:	e4ce                	sd	s3,72(sp)
ffffffffc02026d2:	f0a2                	sd	s0,96(sp)
ffffffffc02026d4:	eca6                	sd	s1,88(sp)
ffffffffc02026d6:	e0d2                	sd	s4,64(sp)
ffffffffc02026d8:	fc56                	sd	s5,56(sp)
ffffffffc02026da:	f45e                	sd	s7,40(sp)
ffffffffc02026dc:	f062                	sd	s8,32(sp)
ffffffffc02026de:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02026e0:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02026e4:	ab5fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    pmm_manager->init();
ffffffffc02026e8:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02026ec:	000cf997          	auipc	s3,0xcf
ffffffffc02026f0:	57c98993          	addi	s3,s3,1404 # ffffffffc02d1c68 <va_pa_offset>
    pmm_manager->init();
ffffffffc02026f4:	679c                	ld	a5,8(a5)
ffffffffc02026f6:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02026f8:	57f5                	li	a5,-3
ffffffffc02026fa:	07fa                	slli	a5,a5,0x1e
ffffffffc02026fc:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202700:	a94fe0ef          	jal	ra,ffffffffc0200994 <get_memory_base>
ffffffffc0202704:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202706:	a98fe0ef          	jal	ra,ffffffffc020099e <get_memory_size>
    if (mem_size == 0)
ffffffffc020270a:	200505e3          	beqz	a0,ffffffffc0203114 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020270e:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202710:	00004517          	auipc	a0,0x4
ffffffffc0202714:	70050513          	addi	a0,a0,1792 # ffffffffc0206e10 <default_pmm_manager+0x1e0>
ffffffffc0202718:	a81fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020271c:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202720:	fff40693          	addi	a3,s0,-1
ffffffffc0202724:	864a                	mv	a2,s2
ffffffffc0202726:	85a6                	mv	a1,s1
ffffffffc0202728:	00004517          	auipc	a0,0x4
ffffffffc020272c:	70050513          	addi	a0,a0,1792 # ffffffffc0206e28 <default_pmm_manager+0x1f8>
ffffffffc0202730:	a69fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202734:	c8000737          	lui	a4,0xc8000
ffffffffc0202738:	87a2                	mv	a5,s0
ffffffffc020273a:	54876163          	bltu	a4,s0,ffffffffc0202c7c <pmm_init+0x5ce>
ffffffffc020273e:	757d                	lui	a0,0xfffff
ffffffffc0202740:	000d0617          	auipc	a2,0xd0
ffffffffc0202744:	56760613          	addi	a2,a2,1383 # ffffffffc02d2ca7 <end+0xfff>
ffffffffc0202748:	8e69                	and	a2,a2,a0
ffffffffc020274a:	000cf497          	auipc	s1,0xcf
ffffffffc020274e:	50648493          	addi	s1,s1,1286 # ffffffffc02d1c50 <npage>
ffffffffc0202752:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202756:	000cfb97          	auipc	s7,0xcf
ffffffffc020275a:	502b8b93          	addi	s7,s7,1282 # ffffffffc02d1c58 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020275e:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202760:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202764:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202768:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020276a:	02f50863          	beq	a0,a5,ffffffffc020279a <pmm_init+0xec>
ffffffffc020276e:	4781                	li	a5,0
ffffffffc0202770:	4585                	li	a1,1
ffffffffc0202772:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202776:	00679513          	slli	a0,a5,0x6
ffffffffc020277a:	9532                	add	a0,a0,a2
ffffffffc020277c:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd2d360>
ffffffffc0202780:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202784:	6088                	ld	a0,0(s1)
ffffffffc0202786:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202788:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020278c:	00d50733          	add	a4,a0,a3
ffffffffc0202790:	fee7e3e3          	bltu	a5,a4,ffffffffc0202776 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202794:	071a                	slli	a4,a4,0x6
ffffffffc0202796:	00e606b3          	add	a3,a2,a4
ffffffffc020279a:	c02007b7          	lui	a5,0xc0200
ffffffffc020279e:	2ef6ece3          	bltu	a3,a5,ffffffffc0203296 <pmm_init+0xbe8>
ffffffffc02027a2:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02027a6:	77fd                	lui	a5,0xfffff
ffffffffc02027a8:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02027aa:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02027ac:	5086eb63          	bltu	a3,s0,ffffffffc0202cc2 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02027b0:	00004517          	auipc	a0,0x4
ffffffffc02027b4:	6a050513          	addi	a0,a0,1696 # ffffffffc0206e50 <default_pmm_manager+0x220>
ffffffffc02027b8:	9e1fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02027bc:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02027c0:	000cf917          	auipc	s2,0xcf
ffffffffc02027c4:	48890913          	addi	s2,s2,1160 # ffffffffc02d1c48 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02027c8:	7b9c                	ld	a5,48(a5)
ffffffffc02027ca:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02027cc:	00004517          	auipc	a0,0x4
ffffffffc02027d0:	69c50513          	addi	a0,a0,1692 # ffffffffc0206e68 <default_pmm_manager+0x238>
ffffffffc02027d4:	9c5fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02027d8:	00009697          	auipc	a3,0x9
ffffffffc02027dc:	82868693          	addi	a3,a3,-2008 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc02027e0:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02027e4:	c02007b7          	lui	a5,0xc0200
ffffffffc02027e8:	28f6ebe3          	bltu	a3,a5,ffffffffc020327e <pmm_init+0xbd0>
ffffffffc02027ec:	0009b783          	ld	a5,0(s3)
ffffffffc02027f0:	8e9d                	sub	a3,a3,a5
ffffffffc02027f2:	000cf797          	auipc	a5,0xcf
ffffffffc02027f6:	44d7b723          	sd	a3,1102(a5) # ffffffffc02d1c40 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02027fa:	100027f3          	csrr	a5,sstatus
ffffffffc02027fe:	8b89                	andi	a5,a5,2
ffffffffc0202800:	4a079763          	bnez	a5,ffffffffc0202cae <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202804:	000b3783          	ld	a5,0(s6)
ffffffffc0202808:	779c                	ld	a5,40(a5)
ffffffffc020280a:	9782                	jalr	a5
ffffffffc020280c:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020280e:	6098                	ld	a4,0(s1)
ffffffffc0202810:	c80007b7          	lui	a5,0xc8000
ffffffffc0202814:	83b1                	srli	a5,a5,0xc
ffffffffc0202816:	66e7e363          	bltu	a5,a4,ffffffffc0202e7c <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc020281a:	00093503          	ld	a0,0(s2)
ffffffffc020281e:	62050f63          	beqz	a0,ffffffffc0202e5c <pmm_init+0x7ae>
ffffffffc0202822:	03451793          	slli	a5,a0,0x34
ffffffffc0202826:	62079b63          	bnez	a5,ffffffffc0202e5c <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020282a:	4601                	li	a2,0
ffffffffc020282c:	4581                	li	a1,0
ffffffffc020282e:	8c3ff0ef          	jal	ra,ffffffffc02020f0 <get_page>
ffffffffc0202832:	60051563          	bnez	a0,ffffffffc0202e3c <pmm_init+0x78e>
ffffffffc0202836:	100027f3          	csrr	a5,sstatus
ffffffffc020283a:	8b89                	andi	a5,a5,2
ffffffffc020283c:	44079e63          	bnez	a5,ffffffffc0202c98 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202840:	000b3783          	ld	a5,0(s6)
ffffffffc0202844:	4505                	li	a0,1
ffffffffc0202846:	6f9c                	ld	a5,24(a5)
ffffffffc0202848:	9782                	jalr	a5
ffffffffc020284a:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020284c:	00093503          	ld	a0,0(s2)
ffffffffc0202850:	4681                	li	a3,0
ffffffffc0202852:	4601                	li	a2,0
ffffffffc0202854:	85d2                	mv	a1,s4
ffffffffc0202856:	d63ff0ef          	jal	ra,ffffffffc02025b8 <page_insert>
ffffffffc020285a:	26051ae3          	bnez	a0,ffffffffc02032ce <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020285e:	00093503          	ld	a0,0(s2)
ffffffffc0202862:	4601                	li	a2,0
ffffffffc0202864:	4581                	li	a1,0
ffffffffc0202866:	e62ff0ef          	jal	ra,ffffffffc0201ec8 <get_pte>
ffffffffc020286a:	240502e3          	beqz	a0,ffffffffc02032ae <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc020286e:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202870:	0017f713          	andi	a4,a5,1
ffffffffc0202874:	5a070263          	beqz	a4,ffffffffc0202e18 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202878:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020287a:	078a                	slli	a5,a5,0x2
ffffffffc020287c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020287e:	58e7fb63          	bgeu	a5,a4,ffffffffc0202e14 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202882:	000bb683          	ld	a3,0(s7)
ffffffffc0202886:	fff80637          	lui	a2,0xfff80
ffffffffc020288a:	97b2                	add	a5,a5,a2
ffffffffc020288c:	079a                	slli	a5,a5,0x6
ffffffffc020288e:	97b6                	add	a5,a5,a3
ffffffffc0202890:	14fa17e3          	bne	s4,a5,ffffffffc02031de <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202894:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f40>
ffffffffc0202898:	4785                	li	a5,1
ffffffffc020289a:	12f692e3          	bne	a3,a5,ffffffffc02031be <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020289e:	00093503          	ld	a0,0(s2)
ffffffffc02028a2:	77fd                	lui	a5,0xfffff
ffffffffc02028a4:	6114                	ld	a3,0(a0)
ffffffffc02028a6:	068a                	slli	a3,a3,0x2
ffffffffc02028a8:	8efd                	and	a3,a3,a5
ffffffffc02028aa:	00c6d613          	srli	a2,a3,0xc
ffffffffc02028ae:	0ee67ce3          	bgeu	a2,a4,ffffffffc02031a6 <pmm_init+0xaf8>
ffffffffc02028b2:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02028b6:	96e2                	add	a3,a3,s8
ffffffffc02028b8:	0006ba83          	ld	s5,0(a3)
ffffffffc02028bc:	0a8a                	slli	s5,s5,0x2
ffffffffc02028be:	00fafab3          	and	s5,s5,a5
ffffffffc02028c2:	00cad793          	srli	a5,s5,0xc
ffffffffc02028c6:	0ce7f3e3          	bgeu	a5,a4,ffffffffc020318c <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028ca:	4601                	li	a2,0
ffffffffc02028cc:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02028ce:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028d0:	df8ff0ef          	jal	ra,ffffffffc0201ec8 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02028d4:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028d6:	55551363          	bne	a0,s5,ffffffffc0202e1c <pmm_init+0x76e>
ffffffffc02028da:	100027f3          	csrr	a5,sstatus
ffffffffc02028de:	8b89                	andi	a5,a5,2
ffffffffc02028e0:	3a079163          	bnez	a5,ffffffffc0202c82 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc02028e4:	000b3783          	ld	a5,0(s6)
ffffffffc02028e8:	4505                	li	a0,1
ffffffffc02028ea:	6f9c                	ld	a5,24(a5)
ffffffffc02028ec:	9782                	jalr	a5
ffffffffc02028ee:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02028f0:	00093503          	ld	a0,0(s2)
ffffffffc02028f4:	46d1                	li	a3,20
ffffffffc02028f6:	6605                	lui	a2,0x1
ffffffffc02028f8:	85e2                	mv	a1,s8
ffffffffc02028fa:	cbfff0ef          	jal	ra,ffffffffc02025b8 <page_insert>
ffffffffc02028fe:	060517e3          	bnez	a0,ffffffffc020316c <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202902:	00093503          	ld	a0,0(s2)
ffffffffc0202906:	4601                	li	a2,0
ffffffffc0202908:	6585                	lui	a1,0x1
ffffffffc020290a:	dbeff0ef          	jal	ra,ffffffffc0201ec8 <get_pte>
ffffffffc020290e:	02050fe3          	beqz	a0,ffffffffc020314c <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202912:	611c                	ld	a5,0(a0)
ffffffffc0202914:	0107f713          	andi	a4,a5,16
ffffffffc0202918:	7c070e63          	beqz	a4,ffffffffc02030f4 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc020291c:	8b91                	andi	a5,a5,4
ffffffffc020291e:	7a078b63          	beqz	a5,ffffffffc02030d4 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202922:	00093503          	ld	a0,0(s2)
ffffffffc0202926:	611c                	ld	a5,0(a0)
ffffffffc0202928:	8bc1                	andi	a5,a5,16
ffffffffc020292a:	78078563          	beqz	a5,ffffffffc02030b4 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc020292e:	000c2703          	lw	a4,0(s8)
ffffffffc0202932:	4785                	li	a5,1
ffffffffc0202934:	76f71063          	bne	a4,a5,ffffffffc0203094 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202938:	4681                	li	a3,0
ffffffffc020293a:	6605                	lui	a2,0x1
ffffffffc020293c:	85d2                	mv	a1,s4
ffffffffc020293e:	c7bff0ef          	jal	ra,ffffffffc02025b8 <page_insert>
ffffffffc0202942:	72051963          	bnez	a0,ffffffffc0203074 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202946:	000a2703          	lw	a4,0(s4)
ffffffffc020294a:	4789                	li	a5,2
ffffffffc020294c:	70f71463          	bne	a4,a5,ffffffffc0203054 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202950:	000c2783          	lw	a5,0(s8)
ffffffffc0202954:	6e079063          	bnez	a5,ffffffffc0203034 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202958:	00093503          	ld	a0,0(s2)
ffffffffc020295c:	4601                	li	a2,0
ffffffffc020295e:	6585                	lui	a1,0x1
ffffffffc0202960:	d68ff0ef          	jal	ra,ffffffffc0201ec8 <get_pte>
ffffffffc0202964:	6a050863          	beqz	a0,ffffffffc0203014 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202968:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc020296a:	00177793          	andi	a5,a4,1
ffffffffc020296e:	4a078563          	beqz	a5,ffffffffc0202e18 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202972:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202974:	00271793          	slli	a5,a4,0x2
ffffffffc0202978:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020297a:	48d7fd63          	bgeu	a5,a3,ffffffffc0202e14 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020297e:	000bb683          	ld	a3,0(s7)
ffffffffc0202982:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202986:	97d6                	add	a5,a5,s5
ffffffffc0202988:	079a                	slli	a5,a5,0x6
ffffffffc020298a:	97b6                	add	a5,a5,a3
ffffffffc020298c:	66fa1463          	bne	s4,a5,ffffffffc0202ff4 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202990:	8b41                	andi	a4,a4,16
ffffffffc0202992:	64071163          	bnez	a4,ffffffffc0202fd4 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202996:	00093503          	ld	a0,0(s2)
ffffffffc020299a:	4581                	li	a1,0
ffffffffc020299c:	b81ff0ef          	jal	ra,ffffffffc020251c <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc02029a0:	000a2c83          	lw	s9,0(s4)
ffffffffc02029a4:	4785                	li	a5,1
ffffffffc02029a6:	60fc9763          	bne	s9,a5,ffffffffc0202fb4 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc02029aa:	000c2783          	lw	a5,0(s8)
ffffffffc02029ae:	5e079363          	bnez	a5,ffffffffc0202f94 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc02029b2:	00093503          	ld	a0,0(s2)
ffffffffc02029b6:	6585                	lui	a1,0x1
ffffffffc02029b8:	b65ff0ef          	jal	ra,ffffffffc020251c <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc02029bc:	000a2783          	lw	a5,0(s4)
ffffffffc02029c0:	52079a63          	bnez	a5,ffffffffc0202ef4 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc02029c4:	000c2783          	lw	a5,0(s8)
ffffffffc02029c8:	50079663          	bnez	a5,ffffffffc0202ed4 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc02029cc:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc02029d0:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02029d2:	000a3683          	ld	a3,0(s4)
ffffffffc02029d6:	068a                	slli	a3,a3,0x2
ffffffffc02029d8:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc02029da:	42b6fd63          	bgeu	a3,a1,ffffffffc0202e14 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029de:	000bb503          	ld	a0,0(s7)
ffffffffc02029e2:	96d6                	add	a3,a3,s5
ffffffffc02029e4:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc02029e6:	00d507b3          	add	a5,a0,a3
ffffffffc02029ea:	439c                	lw	a5,0(a5)
ffffffffc02029ec:	4d979463          	bne	a5,s9,ffffffffc0202eb4 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc02029f0:	8699                	srai	a3,a3,0x6
ffffffffc02029f2:	00080637          	lui	a2,0x80
ffffffffc02029f6:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02029f8:	00c69713          	slli	a4,a3,0xc
ffffffffc02029fc:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02029fe:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202a00:	48b77e63          	bgeu	a4,a1,ffffffffc0202e9c <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202a04:	0009b703          	ld	a4,0(s3)
ffffffffc0202a08:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a0a:	629c                	ld	a5,0(a3)
ffffffffc0202a0c:	078a                	slli	a5,a5,0x2
ffffffffc0202a0e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a10:	40b7f263          	bgeu	a5,a1,ffffffffc0202e14 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a14:	8f91                	sub	a5,a5,a2
ffffffffc0202a16:	079a                	slli	a5,a5,0x6
ffffffffc0202a18:	953e                	add	a0,a0,a5
ffffffffc0202a1a:	100027f3          	csrr	a5,sstatus
ffffffffc0202a1e:	8b89                	andi	a5,a5,2
ffffffffc0202a20:	30079963          	bnez	a5,ffffffffc0202d32 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202a24:	000b3783          	ld	a5,0(s6)
ffffffffc0202a28:	4585                	li	a1,1
ffffffffc0202a2a:	739c                	ld	a5,32(a5)
ffffffffc0202a2c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a2e:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202a32:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a34:	078a                	slli	a5,a5,0x2
ffffffffc0202a36:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a38:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202e14 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a3c:	000bb503          	ld	a0,0(s7)
ffffffffc0202a40:	fff80737          	lui	a4,0xfff80
ffffffffc0202a44:	97ba                	add	a5,a5,a4
ffffffffc0202a46:	079a                	slli	a5,a5,0x6
ffffffffc0202a48:	953e                	add	a0,a0,a5
ffffffffc0202a4a:	100027f3          	csrr	a5,sstatus
ffffffffc0202a4e:	8b89                	andi	a5,a5,2
ffffffffc0202a50:	2c079563          	bnez	a5,ffffffffc0202d1a <pmm_init+0x66c>
ffffffffc0202a54:	000b3783          	ld	a5,0(s6)
ffffffffc0202a58:	4585                	li	a1,1
ffffffffc0202a5a:	739c                	ld	a5,32(a5)
ffffffffc0202a5c:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202a5e:	00093783          	ld	a5,0(s2)
ffffffffc0202a62:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd2d358>
    asm volatile("sfence.vma");
ffffffffc0202a66:	12000073          	sfence.vma
ffffffffc0202a6a:	100027f3          	csrr	a5,sstatus
ffffffffc0202a6e:	8b89                	andi	a5,a5,2
ffffffffc0202a70:	28079b63          	bnez	a5,ffffffffc0202d06 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202a74:	000b3783          	ld	a5,0(s6)
ffffffffc0202a78:	779c                	ld	a5,40(a5)
ffffffffc0202a7a:	9782                	jalr	a5
ffffffffc0202a7c:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202a7e:	4b441b63          	bne	s0,s4,ffffffffc0202f34 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202a82:	00004517          	auipc	a0,0x4
ffffffffc0202a86:	70e50513          	addi	a0,a0,1806 # ffffffffc0207190 <default_pmm_manager+0x560>
ffffffffc0202a8a:	f0efd0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0202a8e:	100027f3          	csrr	a5,sstatus
ffffffffc0202a92:	8b89                	andi	a5,a5,2
ffffffffc0202a94:	24079f63          	bnez	a5,ffffffffc0202cf2 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202a98:	000b3783          	ld	a5,0(s6)
ffffffffc0202a9c:	779c                	ld	a5,40(a5)
ffffffffc0202a9e:	9782                	jalr	a5
ffffffffc0202aa0:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202aa2:	6098                	ld	a4,0(s1)
ffffffffc0202aa4:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202aa8:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202aaa:	00c71793          	slli	a5,a4,0xc
ffffffffc0202aae:	6a05                	lui	s4,0x1
ffffffffc0202ab0:	02f47c63          	bgeu	s0,a5,ffffffffc0202ae8 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ab4:	00c45793          	srli	a5,s0,0xc
ffffffffc0202ab8:	00093503          	ld	a0,0(s2)
ffffffffc0202abc:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202dba <pmm_init+0x70c>
ffffffffc0202ac0:	0009b583          	ld	a1,0(s3)
ffffffffc0202ac4:	4601                	li	a2,0
ffffffffc0202ac6:	95a2                	add	a1,a1,s0
ffffffffc0202ac8:	c00ff0ef          	jal	ra,ffffffffc0201ec8 <get_pte>
ffffffffc0202acc:	32050463          	beqz	a0,ffffffffc0202df4 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202ad0:	611c                	ld	a5,0(a0)
ffffffffc0202ad2:	078a                	slli	a5,a5,0x2
ffffffffc0202ad4:	0157f7b3          	and	a5,a5,s5
ffffffffc0202ad8:	2e879e63          	bne	a5,s0,ffffffffc0202dd4 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202adc:	6098                	ld	a4,0(s1)
ffffffffc0202ade:	9452                	add	s0,s0,s4
ffffffffc0202ae0:	00c71793          	slli	a5,a4,0xc
ffffffffc0202ae4:	fcf468e3          	bltu	s0,a5,ffffffffc0202ab4 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202ae8:	00093783          	ld	a5,0(s2)
ffffffffc0202aec:	639c                	ld	a5,0(a5)
ffffffffc0202aee:	42079363          	bnez	a5,ffffffffc0202f14 <pmm_init+0x866>
ffffffffc0202af2:	100027f3          	csrr	a5,sstatus
ffffffffc0202af6:	8b89                	andi	a5,a5,2
ffffffffc0202af8:	24079963          	bnez	a5,ffffffffc0202d4a <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202afc:	000b3783          	ld	a5,0(s6)
ffffffffc0202b00:	4505                	li	a0,1
ffffffffc0202b02:	6f9c                	ld	a5,24(a5)
ffffffffc0202b04:	9782                	jalr	a5
ffffffffc0202b06:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202b08:	00093503          	ld	a0,0(s2)
ffffffffc0202b0c:	4699                	li	a3,6
ffffffffc0202b0e:	10000613          	li	a2,256
ffffffffc0202b12:	85d2                	mv	a1,s4
ffffffffc0202b14:	aa5ff0ef          	jal	ra,ffffffffc02025b8 <page_insert>
ffffffffc0202b18:	44051e63          	bnez	a0,ffffffffc0202f74 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202b1c:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f40>
ffffffffc0202b20:	4785                	li	a5,1
ffffffffc0202b22:	42f71963          	bne	a4,a5,ffffffffc0202f54 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202b26:	00093503          	ld	a0,0(s2)
ffffffffc0202b2a:	6405                	lui	s0,0x1
ffffffffc0202b2c:	4699                	li	a3,6
ffffffffc0202b2e:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8e40>
ffffffffc0202b32:	85d2                	mv	a1,s4
ffffffffc0202b34:	a85ff0ef          	jal	ra,ffffffffc02025b8 <page_insert>
ffffffffc0202b38:	72051363          	bnez	a0,ffffffffc020325e <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202b3c:	000a2703          	lw	a4,0(s4)
ffffffffc0202b40:	4789                	li	a5,2
ffffffffc0202b42:	6ef71e63          	bne	a4,a5,ffffffffc020323e <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202b46:	00004597          	auipc	a1,0x4
ffffffffc0202b4a:	79258593          	addi	a1,a1,1938 # ffffffffc02072d8 <default_pmm_manager+0x6a8>
ffffffffc0202b4e:	10000513          	li	a0,256
ffffffffc0202b52:	1f8030ef          	jal	ra,ffffffffc0205d4a <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202b56:	10040593          	addi	a1,s0,256
ffffffffc0202b5a:	10000513          	li	a0,256
ffffffffc0202b5e:	1fe030ef          	jal	ra,ffffffffc0205d5c <strcmp>
ffffffffc0202b62:	6a051e63          	bnez	a0,ffffffffc020321e <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202b66:	000bb683          	ld	a3,0(s7)
ffffffffc0202b6a:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202b6e:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202b70:	40da06b3          	sub	a3,s4,a3
ffffffffc0202b74:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202b76:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202b78:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202b7a:	8031                	srli	s0,s0,0xc
ffffffffc0202b7c:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b80:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b82:	30f77d63          	bgeu	a4,a5,ffffffffc0202e9c <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202b86:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202b8a:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202b8e:	96be                	add	a3,a3,a5
ffffffffc0202b90:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202b94:	180030ef          	jal	ra,ffffffffc0205d14 <strlen>
ffffffffc0202b98:	66051363          	bnez	a0,ffffffffc02031fe <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202b9c:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202ba0:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ba2:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd2d358>
ffffffffc0202ba6:	068a                	slli	a3,a3,0x2
ffffffffc0202ba8:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202baa:	26f6f563          	bgeu	a3,a5,ffffffffc0202e14 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202bae:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202bb0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202bb2:	2ef47563          	bgeu	s0,a5,ffffffffc0202e9c <pmm_init+0x7ee>
ffffffffc0202bb6:	0009b403          	ld	s0,0(s3)
ffffffffc0202bba:	9436                	add	s0,s0,a3
ffffffffc0202bbc:	100027f3          	csrr	a5,sstatus
ffffffffc0202bc0:	8b89                	andi	a5,a5,2
ffffffffc0202bc2:	1e079163          	bnez	a5,ffffffffc0202da4 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202bc6:	000b3783          	ld	a5,0(s6)
ffffffffc0202bca:	4585                	li	a1,1
ffffffffc0202bcc:	8552                	mv	a0,s4
ffffffffc0202bce:	739c                	ld	a5,32(a5)
ffffffffc0202bd0:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bd2:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202bd4:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bd6:	078a                	slli	a5,a5,0x2
ffffffffc0202bd8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bda:	22e7fd63          	bgeu	a5,a4,ffffffffc0202e14 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202bde:	000bb503          	ld	a0,0(s7)
ffffffffc0202be2:	fff80737          	lui	a4,0xfff80
ffffffffc0202be6:	97ba                	add	a5,a5,a4
ffffffffc0202be8:	079a                	slli	a5,a5,0x6
ffffffffc0202bea:	953e                	add	a0,a0,a5
ffffffffc0202bec:	100027f3          	csrr	a5,sstatus
ffffffffc0202bf0:	8b89                	andi	a5,a5,2
ffffffffc0202bf2:	18079d63          	bnez	a5,ffffffffc0202d8c <pmm_init+0x6de>
ffffffffc0202bf6:	000b3783          	ld	a5,0(s6)
ffffffffc0202bfa:	4585                	li	a1,1
ffffffffc0202bfc:	739c                	ld	a5,32(a5)
ffffffffc0202bfe:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c00:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202c04:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c06:	078a                	slli	a5,a5,0x2
ffffffffc0202c08:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c0a:	20e7f563          	bgeu	a5,a4,ffffffffc0202e14 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c0e:	000bb503          	ld	a0,0(s7)
ffffffffc0202c12:	fff80737          	lui	a4,0xfff80
ffffffffc0202c16:	97ba                	add	a5,a5,a4
ffffffffc0202c18:	079a                	slli	a5,a5,0x6
ffffffffc0202c1a:	953e                	add	a0,a0,a5
ffffffffc0202c1c:	100027f3          	csrr	a5,sstatus
ffffffffc0202c20:	8b89                	andi	a5,a5,2
ffffffffc0202c22:	14079963          	bnez	a5,ffffffffc0202d74 <pmm_init+0x6c6>
ffffffffc0202c26:	000b3783          	ld	a5,0(s6)
ffffffffc0202c2a:	4585                	li	a1,1
ffffffffc0202c2c:	739c                	ld	a5,32(a5)
ffffffffc0202c2e:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202c30:	00093783          	ld	a5,0(s2)
ffffffffc0202c34:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202c38:	12000073          	sfence.vma
ffffffffc0202c3c:	100027f3          	csrr	a5,sstatus
ffffffffc0202c40:	8b89                	andi	a5,a5,2
ffffffffc0202c42:	10079f63          	bnez	a5,ffffffffc0202d60 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c46:	000b3783          	ld	a5,0(s6)
ffffffffc0202c4a:	779c                	ld	a5,40(a5)
ffffffffc0202c4c:	9782                	jalr	a5
ffffffffc0202c4e:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202c50:	4c8c1e63          	bne	s8,s0,ffffffffc020312c <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202c54:	00004517          	auipc	a0,0x4
ffffffffc0202c58:	6fc50513          	addi	a0,a0,1788 # ffffffffc0207350 <default_pmm_manager+0x720>
ffffffffc0202c5c:	d3cfd0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0202c60:	7406                	ld	s0,96(sp)
ffffffffc0202c62:	70a6                	ld	ra,104(sp)
ffffffffc0202c64:	64e6                	ld	s1,88(sp)
ffffffffc0202c66:	6946                	ld	s2,80(sp)
ffffffffc0202c68:	69a6                	ld	s3,72(sp)
ffffffffc0202c6a:	6a06                	ld	s4,64(sp)
ffffffffc0202c6c:	7ae2                	ld	s5,56(sp)
ffffffffc0202c6e:	7b42                	ld	s6,48(sp)
ffffffffc0202c70:	7ba2                	ld	s7,40(sp)
ffffffffc0202c72:	7c02                	ld	s8,32(sp)
ffffffffc0202c74:	6ce2                	ld	s9,24(sp)
ffffffffc0202c76:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202c78:	f97fe06f          	j	ffffffffc0201c0e <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202c7c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202c80:	bc7d                	j	ffffffffc020273e <pmm_init+0x90>
        intr_disable();
ffffffffc0202c82:	d2dfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c86:	000b3783          	ld	a5,0(s6)
ffffffffc0202c8a:	4505                	li	a0,1
ffffffffc0202c8c:	6f9c                	ld	a5,24(a5)
ffffffffc0202c8e:	9782                	jalr	a5
ffffffffc0202c90:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202c92:	d17fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c96:	b9a9                	j	ffffffffc02028f0 <pmm_init+0x242>
        intr_disable();
ffffffffc0202c98:	d17fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202c9c:	000b3783          	ld	a5,0(s6)
ffffffffc0202ca0:	4505                	li	a0,1
ffffffffc0202ca2:	6f9c                	ld	a5,24(a5)
ffffffffc0202ca4:	9782                	jalr	a5
ffffffffc0202ca6:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202ca8:	d01fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cac:	b645                	j	ffffffffc020284c <pmm_init+0x19e>
        intr_disable();
ffffffffc0202cae:	d01fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cb2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cb6:	779c                	ld	a5,40(a5)
ffffffffc0202cb8:	9782                	jalr	a5
ffffffffc0202cba:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202cbc:	cedfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cc0:	b6b9                	j	ffffffffc020280e <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202cc2:	6705                	lui	a4,0x1
ffffffffc0202cc4:	177d                	addi	a4,a4,-1
ffffffffc0202cc6:	96ba                	add	a3,a3,a4
ffffffffc0202cc8:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202cca:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202cce:	14a77363          	bgeu	a4,a0,ffffffffc0202e14 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202cd2:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202cd6:	fff80537          	lui	a0,0xfff80
ffffffffc0202cda:	972a                	add	a4,a4,a0
ffffffffc0202cdc:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202cde:	8c1d                	sub	s0,s0,a5
ffffffffc0202ce0:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202ce4:	00c45593          	srli	a1,s0,0xc
ffffffffc0202ce8:	9532                	add	a0,a0,a2
ffffffffc0202cea:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202cec:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202cf0:	b4c1                	j	ffffffffc02027b0 <pmm_init+0x102>
        intr_disable();
ffffffffc0202cf2:	cbdfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cf6:	000b3783          	ld	a5,0(s6)
ffffffffc0202cfa:	779c                	ld	a5,40(a5)
ffffffffc0202cfc:	9782                	jalr	a5
ffffffffc0202cfe:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d00:	ca9fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d04:	bb79                	j	ffffffffc0202aa2 <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202d06:	ca9fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202d0a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d0e:	779c                	ld	a5,40(a5)
ffffffffc0202d10:	9782                	jalr	a5
ffffffffc0202d12:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d14:	c95fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d18:	b39d                	j	ffffffffc0202a7e <pmm_init+0x3d0>
ffffffffc0202d1a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d1c:	c93fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202d20:	000b3783          	ld	a5,0(s6)
ffffffffc0202d24:	6522                	ld	a0,8(sp)
ffffffffc0202d26:	4585                	li	a1,1
ffffffffc0202d28:	739c                	ld	a5,32(a5)
ffffffffc0202d2a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d2c:	c7dfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d30:	b33d                	j	ffffffffc0202a5e <pmm_init+0x3b0>
ffffffffc0202d32:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d34:	c7bfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202d38:	000b3783          	ld	a5,0(s6)
ffffffffc0202d3c:	6522                	ld	a0,8(sp)
ffffffffc0202d3e:	4585                	li	a1,1
ffffffffc0202d40:	739c                	ld	a5,32(a5)
ffffffffc0202d42:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d44:	c65fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d48:	b1dd                	j	ffffffffc0202a2e <pmm_init+0x380>
        intr_disable();
ffffffffc0202d4a:	c65fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d4e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d52:	4505                	li	a0,1
ffffffffc0202d54:	6f9c                	ld	a5,24(a5)
ffffffffc0202d56:	9782                	jalr	a5
ffffffffc0202d58:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d5a:	c4ffd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d5e:	b36d                	j	ffffffffc0202b08 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202d60:	c4ffd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d64:	000b3783          	ld	a5,0(s6)
ffffffffc0202d68:	779c                	ld	a5,40(a5)
ffffffffc0202d6a:	9782                	jalr	a5
ffffffffc0202d6c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d6e:	c3bfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d72:	bdf9                	j	ffffffffc0202c50 <pmm_init+0x5a2>
ffffffffc0202d74:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d76:	c39fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202d7a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d7e:	6522                	ld	a0,8(sp)
ffffffffc0202d80:	4585                	li	a1,1
ffffffffc0202d82:	739c                	ld	a5,32(a5)
ffffffffc0202d84:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d86:	c23fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d8a:	b55d                	j	ffffffffc0202c30 <pmm_init+0x582>
ffffffffc0202d8c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d8e:	c21fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202d92:	000b3783          	ld	a5,0(s6)
ffffffffc0202d96:	6522                	ld	a0,8(sp)
ffffffffc0202d98:	4585                	li	a1,1
ffffffffc0202d9a:	739c                	ld	a5,32(a5)
ffffffffc0202d9c:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d9e:	c0bfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202da2:	bdb9                	j	ffffffffc0202c00 <pmm_init+0x552>
        intr_disable();
ffffffffc0202da4:	c0bfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202da8:	000b3783          	ld	a5,0(s6)
ffffffffc0202dac:	4585                	li	a1,1
ffffffffc0202dae:	8552                	mv	a0,s4
ffffffffc0202db0:	739c                	ld	a5,32(a5)
ffffffffc0202db2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202db4:	bf5fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202db8:	bd29                	j	ffffffffc0202bd2 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202dba:	86a2                	mv	a3,s0
ffffffffc0202dbc:	00004617          	auipc	a2,0x4
ffffffffc0202dc0:	eac60613          	addi	a2,a2,-340 # ffffffffc0206c68 <default_pmm_manager+0x38>
ffffffffc0202dc4:	23c00593          	li	a1,572
ffffffffc0202dc8:	00004517          	auipc	a0,0x4
ffffffffc0202dcc:	fb850513          	addi	a0,a0,-72 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202dd0:	ec2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202dd4:	00004697          	auipc	a3,0x4
ffffffffc0202dd8:	41c68693          	addi	a3,a3,1052 # ffffffffc02071f0 <default_pmm_manager+0x5c0>
ffffffffc0202ddc:	00004617          	auipc	a2,0x4
ffffffffc0202de0:	aa460613          	addi	a2,a2,-1372 # ffffffffc0206880 <commands+0x838>
ffffffffc0202de4:	23d00593          	li	a1,573
ffffffffc0202de8:	00004517          	auipc	a0,0x4
ffffffffc0202dec:	f9850513          	addi	a0,a0,-104 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202df0:	ea2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202df4:	00004697          	auipc	a3,0x4
ffffffffc0202df8:	3bc68693          	addi	a3,a3,956 # ffffffffc02071b0 <default_pmm_manager+0x580>
ffffffffc0202dfc:	00004617          	auipc	a2,0x4
ffffffffc0202e00:	a8460613          	addi	a2,a2,-1404 # ffffffffc0206880 <commands+0x838>
ffffffffc0202e04:	23c00593          	li	a1,572
ffffffffc0202e08:	00004517          	auipc	a0,0x4
ffffffffc0202e0c:	f7850513          	addi	a0,a0,-136 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202e10:	e82fd0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202e14:	fc5fe0ef          	jal	ra,ffffffffc0201dd8 <pa2page.part.0>
ffffffffc0202e18:	fddfe0ef          	jal	ra,ffffffffc0201df4 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202e1c:	00004697          	auipc	a3,0x4
ffffffffc0202e20:	18c68693          	addi	a3,a3,396 # ffffffffc0206fa8 <default_pmm_manager+0x378>
ffffffffc0202e24:	00004617          	auipc	a2,0x4
ffffffffc0202e28:	a5c60613          	addi	a2,a2,-1444 # ffffffffc0206880 <commands+0x838>
ffffffffc0202e2c:	20c00593          	li	a1,524
ffffffffc0202e30:	00004517          	auipc	a0,0x4
ffffffffc0202e34:	f5050513          	addi	a0,a0,-176 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202e38:	e5afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202e3c:	00004697          	auipc	a3,0x4
ffffffffc0202e40:	0ac68693          	addi	a3,a3,172 # ffffffffc0206ee8 <default_pmm_manager+0x2b8>
ffffffffc0202e44:	00004617          	auipc	a2,0x4
ffffffffc0202e48:	a3c60613          	addi	a2,a2,-1476 # ffffffffc0206880 <commands+0x838>
ffffffffc0202e4c:	1ff00593          	li	a1,511
ffffffffc0202e50:	00004517          	auipc	a0,0x4
ffffffffc0202e54:	f3050513          	addi	a0,a0,-208 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202e58:	e3afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202e5c:	00004697          	auipc	a3,0x4
ffffffffc0202e60:	04c68693          	addi	a3,a3,76 # ffffffffc0206ea8 <default_pmm_manager+0x278>
ffffffffc0202e64:	00004617          	auipc	a2,0x4
ffffffffc0202e68:	a1c60613          	addi	a2,a2,-1508 # ffffffffc0206880 <commands+0x838>
ffffffffc0202e6c:	1fe00593          	li	a1,510
ffffffffc0202e70:	00004517          	auipc	a0,0x4
ffffffffc0202e74:	f1050513          	addi	a0,a0,-240 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202e78:	e1afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202e7c:	00004697          	auipc	a3,0x4
ffffffffc0202e80:	00c68693          	addi	a3,a3,12 # ffffffffc0206e88 <default_pmm_manager+0x258>
ffffffffc0202e84:	00004617          	auipc	a2,0x4
ffffffffc0202e88:	9fc60613          	addi	a2,a2,-1540 # ffffffffc0206880 <commands+0x838>
ffffffffc0202e8c:	1fd00593          	li	a1,509
ffffffffc0202e90:	00004517          	auipc	a0,0x4
ffffffffc0202e94:	ef050513          	addi	a0,a0,-272 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202e98:	dfafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202e9c:	00004617          	auipc	a2,0x4
ffffffffc0202ea0:	dcc60613          	addi	a2,a2,-564 # ffffffffc0206c68 <default_pmm_manager+0x38>
ffffffffc0202ea4:	07100593          	li	a1,113
ffffffffc0202ea8:	00004517          	auipc	a0,0x4
ffffffffc0202eac:	de850513          	addi	a0,a0,-536 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc0202eb0:	de2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202eb4:	00004697          	auipc	a3,0x4
ffffffffc0202eb8:	28468693          	addi	a3,a3,644 # ffffffffc0207138 <default_pmm_manager+0x508>
ffffffffc0202ebc:	00004617          	auipc	a2,0x4
ffffffffc0202ec0:	9c460613          	addi	a2,a2,-1596 # ffffffffc0206880 <commands+0x838>
ffffffffc0202ec4:	22500593          	li	a1,549
ffffffffc0202ec8:	00004517          	auipc	a0,0x4
ffffffffc0202ecc:	eb850513          	addi	a0,a0,-328 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202ed0:	dc2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202ed4:	00004697          	auipc	a3,0x4
ffffffffc0202ed8:	21c68693          	addi	a3,a3,540 # ffffffffc02070f0 <default_pmm_manager+0x4c0>
ffffffffc0202edc:	00004617          	auipc	a2,0x4
ffffffffc0202ee0:	9a460613          	addi	a2,a2,-1628 # ffffffffc0206880 <commands+0x838>
ffffffffc0202ee4:	22300593          	li	a1,547
ffffffffc0202ee8:	00004517          	auipc	a0,0x4
ffffffffc0202eec:	e9850513          	addi	a0,a0,-360 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202ef0:	da2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202ef4:	00004697          	auipc	a3,0x4
ffffffffc0202ef8:	22c68693          	addi	a3,a3,556 # ffffffffc0207120 <default_pmm_manager+0x4f0>
ffffffffc0202efc:	00004617          	auipc	a2,0x4
ffffffffc0202f00:	98460613          	addi	a2,a2,-1660 # ffffffffc0206880 <commands+0x838>
ffffffffc0202f04:	22200593          	li	a1,546
ffffffffc0202f08:	00004517          	auipc	a0,0x4
ffffffffc0202f0c:	e7850513          	addi	a0,a0,-392 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202f10:	d82fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202f14:	00004697          	auipc	a3,0x4
ffffffffc0202f18:	2f468693          	addi	a3,a3,756 # ffffffffc0207208 <default_pmm_manager+0x5d8>
ffffffffc0202f1c:	00004617          	auipc	a2,0x4
ffffffffc0202f20:	96460613          	addi	a2,a2,-1692 # ffffffffc0206880 <commands+0x838>
ffffffffc0202f24:	24000593          	li	a1,576
ffffffffc0202f28:	00004517          	auipc	a0,0x4
ffffffffc0202f2c:	e5850513          	addi	a0,a0,-424 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202f30:	d62fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202f34:	00004697          	auipc	a3,0x4
ffffffffc0202f38:	23468693          	addi	a3,a3,564 # ffffffffc0207168 <default_pmm_manager+0x538>
ffffffffc0202f3c:	00004617          	auipc	a2,0x4
ffffffffc0202f40:	94460613          	addi	a2,a2,-1724 # ffffffffc0206880 <commands+0x838>
ffffffffc0202f44:	22d00593          	li	a1,557
ffffffffc0202f48:	00004517          	auipc	a0,0x4
ffffffffc0202f4c:	e3850513          	addi	a0,a0,-456 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202f50:	d42fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202f54:	00004697          	auipc	a3,0x4
ffffffffc0202f58:	30c68693          	addi	a3,a3,780 # ffffffffc0207260 <default_pmm_manager+0x630>
ffffffffc0202f5c:	00004617          	auipc	a2,0x4
ffffffffc0202f60:	92460613          	addi	a2,a2,-1756 # ffffffffc0206880 <commands+0x838>
ffffffffc0202f64:	24500593          	li	a1,581
ffffffffc0202f68:	00004517          	auipc	a0,0x4
ffffffffc0202f6c:	e1850513          	addi	a0,a0,-488 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202f70:	d22fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202f74:	00004697          	auipc	a3,0x4
ffffffffc0202f78:	2ac68693          	addi	a3,a3,684 # ffffffffc0207220 <default_pmm_manager+0x5f0>
ffffffffc0202f7c:	00004617          	auipc	a2,0x4
ffffffffc0202f80:	90460613          	addi	a2,a2,-1788 # ffffffffc0206880 <commands+0x838>
ffffffffc0202f84:	24400593          	li	a1,580
ffffffffc0202f88:	00004517          	auipc	a0,0x4
ffffffffc0202f8c:	df850513          	addi	a0,a0,-520 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202f90:	d02fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f94:	00004697          	auipc	a3,0x4
ffffffffc0202f98:	15c68693          	addi	a3,a3,348 # ffffffffc02070f0 <default_pmm_manager+0x4c0>
ffffffffc0202f9c:	00004617          	auipc	a2,0x4
ffffffffc0202fa0:	8e460613          	addi	a2,a2,-1820 # ffffffffc0206880 <commands+0x838>
ffffffffc0202fa4:	21f00593          	li	a1,543
ffffffffc0202fa8:	00004517          	auipc	a0,0x4
ffffffffc0202fac:	dd850513          	addi	a0,a0,-552 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202fb0:	ce2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202fb4:	00004697          	auipc	a3,0x4
ffffffffc0202fb8:	fdc68693          	addi	a3,a3,-36 # ffffffffc0206f90 <default_pmm_manager+0x360>
ffffffffc0202fbc:	00004617          	auipc	a2,0x4
ffffffffc0202fc0:	8c460613          	addi	a2,a2,-1852 # ffffffffc0206880 <commands+0x838>
ffffffffc0202fc4:	21e00593          	li	a1,542
ffffffffc0202fc8:	00004517          	auipc	a0,0x4
ffffffffc0202fcc:	db850513          	addi	a0,a0,-584 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202fd0:	cc2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202fd4:	00004697          	auipc	a3,0x4
ffffffffc0202fd8:	13468693          	addi	a3,a3,308 # ffffffffc0207108 <default_pmm_manager+0x4d8>
ffffffffc0202fdc:	00004617          	auipc	a2,0x4
ffffffffc0202fe0:	8a460613          	addi	a2,a2,-1884 # ffffffffc0206880 <commands+0x838>
ffffffffc0202fe4:	21b00593          	li	a1,539
ffffffffc0202fe8:	00004517          	auipc	a0,0x4
ffffffffc0202fec:	d9850513          	addi	a0,a0,-616 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0202ff0:	ca2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202ff4:	00004697          	auipc	a3,0x4
ffffffffc0202ff8:	f8468693          	addi	a3,a3,-124 # ffffffffc0206f78 <default_pmm_manager+0x348>
ffffffffc0202ffc:	00004617          	auipc	a2,0x4
ffffffffc0203000:	88460613          	addi	a2,a2,-1916 # ffffffffc0206880 <commands+0x838>
ffffffffc0203004:	21a00593          	li	a1,538
ffffffffc0203008:	00004517          	auipc	a0,0x4
ffffffffc020300c:	d7850513          	addi	a0,a0,-648 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0203010:	c82fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203014:	00004697          	auipc	a3,0x4
ffffffffc0203018:	00468693          	addi	a3,a3,4 # ffffffffc0207018 <default_pmm_manager+0x3e8>
ffffffffc020301c:	00004617          	auipc	a2,0x4
ffffffffc0203020:	86460613          	addi	a2,a2,-1948 # ffffffffc0206880 <commands+0x838>
ffffffffc0203024:	21900593          	li	a1,537
ffffffffc0203028:	00004517          	auipc	a0,0x4
ffffffffc020302c:	d5850513          	addi	a0,a0,-680 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0203030:	c62fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203034:	00004697          	auipc	a3,0x4
ffffffffc0203038:	0bc68693          	addi	a3,a3,188 # ffffffffc02070f0 <default_pmm_manager+0x4c0>
ffffffffc020303c:	00004617          	auipc	a2,0x4
ffffffffc0203040:	84460613          	addi	a2,a2,-1980 # ffffffffc0206880 <commands+0x838>
ffffffffc0203044:	21800593          	li	a1,536
ffffffffc0203048:	00004517          	auipc	a0,0x4
ffffffffc020304c:	d3850513          	addi	a0,a0,-712 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0203050:	c42fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203054:	00004697          	auipc	a3,0x4
ffffffffc0203058:	08468693          	addi	a3,a3,132 # ffffffffc02070d8 <default_pmm_manager+0x4a8>
ffffffffc020305c:	00004617          	auipc	a2,0x4
ffffffffc0203060:	82460613          	addi	a2,a2,-2012 # ffffffffc0206880 <commands+0x838>
ffffffffc0203064:	21700593          	li	a1,535
ffffffffc0203068:	00004517          	auipc	a0,0x4
ffffffffc020306c:	d1850513          	addi	a0,a0,-744 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0203070:	c22fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203074:	00004697          	auipc	a3,0x4
ffffffffc0203078:	03468693          	addi	a3,a3,52 # ffffffffc02070a8 <default_pmm_manager+0x478>
ffffffffc020307c:	00004617          	auipc	a2,0x4
ffffffffc0203080:	80460613          	addi	a2,a2,-2044 # ffffffffc0206880 <commands+0x838>
ffffffffc0203084:	21600593          	li	a1,534
ffffffffc0203088:	00004517          	auipc	a0,0x4
ffffffffc020308c:	cf850513          	addi	a0,a0,-776 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0203090:	c02fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203094:	00004697          	auipc	a3,0x4
ffffffffc0203098:	ffc68693          	addi	a3,a3,-4 # ffffffffc0207090 <default_pmm_manager+0x460>
ffffffffc020309c:	00003617          	auipc	a2,0x3
ffffffffc02030a0:	7e460613          	addi	a2,a2,2020 # ffffffffc0206880 <commands+0x838>
ffffffffc02030a4:	21400593          	li	a1,532
ffffffffc02030a8:	00004517          	auipc	a0,0x4
ffffffffc02030ac:	cd850513          	addi	a0,a0,-808 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02030b0:	be2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02030b4:	00004697          	auipc	a3,0x4
ffffffffc02030b8:	fbc68693          	addi	a3,a3,-68 # ffffffffc0207070 <default_pmm_manager+0x440>
ffffffffc02030bc:	00003617          	auipc	a2,0x3
ffffffffc02030c0:	7c460613          	addi	a2,a2,1988 # ffffffffc0206880 <commands+0x838>
ffffffffc02030c4:	21300593          	li	a1,531
ffffffffc02030c8:	00004517          	auipc	a0,0x4
ffffffffc02030cc:	cb850513          	addi	a0,a0,-840 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02030d0:	bc2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_W);
ffffffffc02030d4:	00004697          	auipc	a3,0x4
ffffffffc02030d8:	f8c68693          	addi	a3,a3,-116 # ffffffffc0207060 <default_pmm_manager+0x430>
ffffffffc02030dc:	00003617          	auipc	a2,0x3
ffffffffc02030e0:	7a460613          	addi	a2,a2,1956 # ffffffffc0206880 <commands+0x838>
ffffffffc02030e4:	21200593          	li	a1,530
ffffffffc02030e8:	00004517          	auipc	a0,0x4
ffffffffc02030ec:	c9850513          	addi	a0,a0,-872 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02030f0:	ba2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_U);
ffffffffc02030f4:	00004697          	auipc	a3,0x4
ffffffffc02030f8:	f5c68693          	addi	a3,a3,-164 # ffffffffc0207050 <default_pmm_manager+0x420>
ffffffffc02030fc:	00003617          	auipc	a2,0x3
ffffffffc0203100:	78460613          	addi	a2,a2,1924 # ffffffffc0206880 <commands+0x838>
ffffffffc0203104:	21100593          	li	a1,529
ffffffffc0203108:	00004517          	auipc	a0,0x4
ffffffffc020310c:	c7850513          	addi	a0,a0,-904 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0203110:	b82fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("DTB memory info not available");
ffffffffc0203114:	00004617          	auipc	a2,0x4
ffffffffc0203118:	cdc60613          	addi	a2,a2,-804 # ffffffffc0206df0 <default_pmm_manager+0x1c0>
ffffffffc020311c:	06500593          	li	a1,101
ffffffffc0203120:	00004517          	auipc	a0,0x4
ffffffffc0203124:	c6050513          	addi	a0,a0,-928 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0203128:	b6afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020312c:	00004697          	auipc	a3,0x4
ffffffffc0203130:	03c68693          	addi	a3,a3,60 # ffffffffc0207168 <default_pmm_manager+0x538>
ffffffffc0203134:	00003617          	auipc	a2,0x3
ffffffffc0203138:	74c60613          	addi	a2,a2,1868 # ffffffffc0206880 <commands+0x838>
ffffffffc020313c:	25700593          	li	a1,599
ffffffffc0203140:	00004517          	auipc	a0,0x4
ffffffffc0203144:	c4050513          	addi	a0,a0,-960 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0203148:	b4afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020314c:	00004697          	auipc	a3,0x4
ffffffffc0203150:	ecc68693          	addi	a3,a3,-308 # ffffffffc0207018 <default_pmm_manager+0x3e8>
ffffffffc0203154:	00003617          	auipc	a2,0x3
ffffffffc0203158:	72c60613          	addi	a2,a2,1836 # ffffffffc0206880 <commands+0x838>
ffffffffc020315c:	21000593          	li	a1,528
ffffffffc0203160:	00004517          	auipc	a0,0x4
ffffffffc0203164:	c2050513          	addi	a0,a0,-992 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0203168:	b2afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020316c:	00004697          	auipc	a3,0x4
ffffffffc0203170:	e6c68693          	addi	a3,a3,-404 # ffffffffc0206fd8 <default_pmm_manager+0x3a8>
ffffffffc0203174:	00003617          	auipc	a2,0x3
ffffffffc0203178:	70c60613          	addi	a2,a2,1804 # ffffffffc0206880 <commands+0x838>
ffffffffc020317c:	20f00593          	li	a1,527
ffffffffc0203180:	00004517          	auipc	a0,0x4
ffffffffc0203184:	c0050513          	addi	a0,a0,-1024 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0203188:	b0afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020318c:	86d6                	mv	a3,s5
ffffffffc020318e:	00004617          	auipc	a2,0x4
ffffffffc0203192:	ada60613          	addi	a2,a2,-1318 # ffffffffc0206c68 <default_pmm_manager+0x38>
ffffffffc0203196:	20b00593          	li	a1,523
ffffffffc020319a:	00004517          	auipc	a0,0x4
ffffffffc020319e:	be650513          	addi	a0,a0,-1050 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02031a2:	af0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02031a6:	00004617          	auipc	a2,0x4
ffffffffc02031aa:	ac260613          	addi	a2,a2,-1342 # ffffffffc0206c68 <default_pmm_manager+0x38>
ffffffffc02031ae:	20a00593          	li	a1,522
ffffffffc02031b2:	00004517          	auipc	a0,0x4
ffffffffc02031b6:	bce50513          	addi	a0,a0,-1074 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02031ba:	ad8fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02031be:	00004697          	auipc	a3,0x4
ffffffffc02031c2:	dd268693          	addi	a3,a3,-558 # ffffffffc0206f90 <default_pmm_manager+0x360>
ffffffffc02031c6:	00003617          	auipc	a2,0x3
ffffffffc02031ca:	6ba60613          	addi	a2,a2,1722 # ffffffffc0206880 <commands+0x838>
ffffffffc02031ce:	20800593          	li	a1,520
ffffffffc02031d2:	00004517          	auipc	a0,0x4
ffffffffc02031d6:	bae50513          	addi	a0,a0,-1106 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02031da:	ab8fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02031de:	00004697          	auipc	a3,0x4
ffffffffc02031e2:	d9a68693          	addi	a3,a3,-614 # ffffffffc0206f78 <default_pmm_manager+0x348>
ffffffffc02031e6:	00003617          	auipc	a2,0x3
ffffffffc02031ea:	69a60613          	addi	a2,a2,1690 # ffffffffc0206880 <commands+0x838>
ffffffffc02031ee:	20700593          	li	a1,519
ffffffffc02031f2:	00004517          	auipc	a0,0x4
ffffffffc02031f6:	b8e50513          	addi	a0,a0,-1138 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02031fa:	a98fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02031fe:	00004697          	auipc	a3,0x4
ffffffffc0203202:	12a68693          	addi	a3,a3,298 # ffffffffc0207328 <default_pmm_manager+0x6f8>
ffffffffc0203206:	00003617          	auipc	a2,0x3
ffffffffc020320a:	67a60613          	addi	a2,a2,1658 # ffffffffc0206880 <commands+0x838>
ffffffffc020320e:	24e00593          	li	a1,590
ffffffffc0203212:	00004517          	auipc	a0,0x4
ffffffffc0203216:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc020321a:	a78fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020321e:	00004697          	auipc	a3,0x4
ffffffffc0203222:	0d268693          	addi	a3,a3,210 # ffffffffc02072f0 <default_pmm_manager+0x6c0>
ffffffffc0203226:	00003617          	auipc	a2,0x3
ffffffffc020322a:	65a60613          	addi	a2,a2,1626 # ffffffffc0206880 <commands+0x838>
ffffffffc020322e:	24b00593          	li	a1,587
ffffffffc0203232:	00004517          	auipc	a0,0x4
ffffffffc0203236:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc020323a:	a58fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 2);
ffffffffc020323e:	00004697          	auipc	a3,0x4
ffffffffc0203242:	08268693          	addi	a3,a3,130 # ffffffffc02072c0 <default_pmm_manager+0x690>
ffffffffc0203246:	00003617          	auipc	a2,0x3
ffffffffc020324a:	63a60613          	addi	a2,a2,1594 # ffffffffc0206880 <commands+0x838>
ffffffffc020324e:	24700593          	li	a1,583
ffffffffc0203252:	00004517          	auipc	a0,0x4
ffffffffc0203256:	b2e50513          	addi	a0,a0,-1234 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc020325a:	a38fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020325e:	00004697          	auipc	a3,0x4
ffffffffc0203262:	01a68693          	addi	a3,a3,26 # ffffffffc0207278 <default_pmm_manager+0x648>
ffffffffc0203266:	00003617          	auipc	a2,0x3
ffffffffc020326a:	61a60613          	addi	a2,a2,1562 # ffffffffc0206880 <commands+0x838>
ffffffffc020326e:	24600593          	li	a1,582
ffffffffc0203272:	00004517          	auipc	a0,0x4
ffffffffc0203276:	b0e50513          	addi	a0,a0,-1266 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc020327a:	a18fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020327e:	00004617          	auipc	a2,0x4
ffffffffc0203282:	a9260613          	addi	a2,a2,-1390 # ffffffffc0206d10 <default_pmm_manager+0xe0>
ffffffffc0203286:	0c900593          	li	a1,201
ffffffffc020328a:	00004517          	auipc	a0,0x4
ffffffffc020328e:	af650513          	addi	a0,a0,-1290 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0203292:	a00fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203296:	00004617          	auipc	a2,0x4
ffffffffc020329a:	a7a60613          	addi	a2,a2,-1414 # ffffffffc0206d10 <default_pmm_manager+0xe0>
ffffffffc020329e:	08100593          	li	a1,129
ffffffffc02032a2:	00004517          	auipc	a0,0x4
ffffffffc02032a6:	ade50513          	addi	a0,a0,-1314 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02032aa:	9e8fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02032ae:	00004697          	auipc	a3,0x4
ffffffffc02032b2:	c9a68693          	addi	a3,a3,-870 # ffffffffc0206f48 <default_pmm_manager+0x318>
ffffffffc02032b6:	00003617          	auipc	a2,0x3
ffffffffc02032ba:	5ca60613          	addi	a2,a2,1482 # ffffffffc0206880 <commands+0x838>
ffffffffc02032be:	20600593          	li	a1,518
ffffffffc02032c2:	00004517          	auipc	a0,0x4
ffffffffc02032c6:	abe50513          	addi	a0,a0,-1346 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02032ca:	9c8fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02032ce:	00004697          	auipc	a3,0x4
ffffffffc02032d2:	c4a68693          	addi	a3,a3,-950 # ffffffffc0206f18 <default_pmm_manager+0x2e8>
ffffffffc02032d6:	00003617          	auipc	a2,0x3
ffffffffc02032da:	5aa60613          	addi	a2,a2,1450 # ffffffffc0206880 <commands+0x838>
ffffffffc02032de:	20300593          	li	a1,515
ffffffffc02032e2:	00004517          	auipc	a0,0x4
ffffffffc02032e6:	a9e50513          	addi	a0,a0,-1378 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02032ea:	9a8fd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02032ee <copy_range>:
{
ffffffffc02032ee:	711d                	addi	sp,sp,-96
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02032f0:	00d667b3          	or	a5,a2,a3
{
ffffffffc02032f4:	ec86                	sd	ra,88(sp)
ffffffffc02032f6:	e8a2                	sd	s0,80(sp)
ffffffffc02032f8:	e4a6                	sd	s1,72(sp)
ffffffffc02032fa:	e0ca                	sd	s2,64(sp)
ffffffffc02032fc:	fc4e                	sd	s3,56(sp)
ffffffffc02032fe:	f852                	sd	s4,48(sp)
ffffffffc0203300:	f456                	sd	s5,40(sp)
ffffffffc0203302:	f05a                	sd	s6,32(sp)
ffffffffc0203304:	ec5e                	sd	s7,24(sp)
ffffffffc0203306:	e862                	sd	s8,16(sp)
ffffffffc0203308:	e466                	sd	s9,8(sp)
ffffffffc020330a:	e06a                	sd	s10,0(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020330c:	17d2                	slli	a5,a5,0x34
ffffffffc020330e:	14079863          	bnez	a5,ffffffffc020345e <copy_range+0x170>
    assert(USER_ACCESS(start, end));
ffffffffc0203312:	002007b7          	lui	a5,0x200
ffffffffc0203316:	8432                	mv	s0,a2
ffffffffc0203318:	10f66763          	bltu	a2,a5,ffffffffc0203426 <copy_range+0x138>
ffffffffc020331c:	8936                	mv	s2,a3
ffffffffc020331e:	10d67463          	bgeu	a2,a3,ffffffffc0203426 <copy_range+0x138>
ffffffffc0203322:	4785                	li	a5,1
ffffffffc0203324:	07fe                	slli	a5,a5,0x1f
ffffffffc0203326:	10d7e063          	bltu	a5,a3,ffffffffc0203426 <copy_range+0x138>
ffffffffc020332a:	8aaa                	mv	s5,a0
ffffffffc020332c:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc020332e:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc0203330:	000cfc17          	auipc	s8,0xcf
ffffffffc0203334:	920c0c13          	addi	s8,s8,-1760 # ffffffffc02d1c50 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203338:	000cfb97          	auipc	s7,0xcf
ffffffffc020333c:	920b8b93          	addi	s7,s7,-1760 # ffffffffc02d1c58 <pages>
ffffffffc0203340:	fff80b37          	lui	s6,0xfff80
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203344:	00200d37          	lui	s10,0x200
ffffffffc0203348:	ffe00cb7          	lui	s9,0xffe00
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020334c:	4601                	li	a2,0
ffffffffc020334e:	85a2                	mv	a1,s0
ffffffffc0203350:	854e                	mv	a0,s3
ffffffffc0203352:	b77fe0ef          	jal	ra,ffffffffc0201ec8 <get_pte>
ffffffffc0203356:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc0203358:	c559                	beqz	a0,ffffffffc02033e6 <copy_range+0xf8>
        if (*ptep & PTE_V)
ffffffffc020335a:	611c                	ld	a5,0(a0)
ffffffffc020335c:	8b85                	andi	a5,a5,1
ffffffffc020335e:	e39d                	bnez	a5,ffffffffc0203384 <copy_range+0x96>
        start += PGSIZE;
ffffffffc0203360:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0203362:	ff2465e3          	bltu	s0,s2,ffffffffc020334c <copy_range+0x5e>
    return 0;
ffffffffc0203366:	4501                	li	a0,0
}
ffffffffc0203368:	60e6                	ld	ra,88(sp)
ffffffffc020336a:	6446                	ld	s0,80(sp)
ffffffffc020336c:	64a6                	ld	s1,72(sp)
ffffffffc020336e:	6906                	ld	s2,64(sp)
ffffffffc0203370:	79e2                	ld	s3,56(sp)
ffffffffc0203372:	7a42                	ld	s4,48(sp)
ffffffffc0203374:	7aa2                	ld	s5,40(sp)
ffffffffc0203376:	7b02                	ld	s6,32(sp)
ffffffffc0203378:	6be2                	ld	s7,24(sp)
ffffffffc020337a:	6c42                	ld	s8,16(sp)
ffffffffc020337c:	6ca2                	ld	s9,8(sp)
ffffffffc020337e:	6d02                	ld	s10,0(sp)
ffffffffc0203380:	6125                	addi	sp,sp,96
ffffffffc0203382:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc0203384:	4605                	li	a2,1
ffffffffc0203386:	85a2                	mv	a1,s0
ffffffffc0203388:	8556                	mv	a0,s5
ffffffffc020338a:	b3ffe0ef          	jal	ra,ffffffffc0201ec8 <get_pte>
ffffffffc020338e:	cd35                	beqz	a0,ffffffffc020340a <copy_range+0x11c>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203390:	6098                	ld	a4,0(s1)
    if (!(pte & PTE_V))
ffffffffc0203392:	00177793          	andi	a5,a4,1
ffffffffc0203396:	0007069b          	sext.w	a3,a4
ffffffffc020339a:	cbb5                	beqz	a5,ffffffffc020340e <copy_range+0x120>
    if (PPN(pa) >= npage)
ffffffffc020339c:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc02033a0:	00271793          	slli	a5,a4,0x2
ffffffffc02033a4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02033a6:	0ac7f063          	bgeu	a5,a2,ffffffffc0203446 <copy_range+0x158>
    return &pages[PPN(pa) - nbase];
ffffffffc02033aa:	000bb583          	ld	a1,0(s7)
ffffffffc02033ae:	97da                	add	a5,a5,s6
ffffffffc02033b0:	079a                	slli	a5,a5,0x6
            if (perm & PTE_W)
ffffffffc02033b2:	0046f613          	andi	a2,a3,4
ffffffffc02033b6:	95be                	add	a1,a1,a5
ffffffffc02033b8:	ee15                	bnez	a2,ffffffffc02033f4 <copy_range+0x106>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02033ba:	8afd                	andi	a3,a3,31
            int ret = page_insert(to, page, start, perm);
ffffffffc02033bc:	8622                	mv	a2,s0
ffffffffc02033be:	8556                	mv	a0,s5
ffffffffc02033c0:	9f8ff0ef          	jal	ra,ffffffffc02025b8 <page_insert>
            assert(ret == 0);
ffffffffc02033c4:	dd51                	beqz	a0,ffffffffc0203360 <copy_range+0x72>
ffffffffc02033c6:	00004697          	auipc	a3,0x4
ffffffffc02033ca:	faa68693          	addi	a3,a3,-86 # ffffffffc0207370 <default_pmm_manager+0x740>
ffffffffc02033ce:	00003617          	auipc	a2,0x3
ffffffffc02033d2:	4b260613          	addi	a2,a2,1202 # ffffffffc0206880 <commands+0x838>
ffffffffc02033d6:	19b00593          	li	a1,411
ffffffffc02033da:	00004517          	auipc	a0,0x4
ffffffffc02033de:	9a650513          	addi	a0,a0,-1626 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc02033e2:	8b0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02033e6:	946a                	add	s0,s0,s10
ffffffffc02033e8:	01947433          	and	s0,s0,s9
    } while (start != 0 && start < end);
ffffffffc02033ec:	dc2d                	beqz	s0,ffffffffc0203366 <copy_range+0x78>
ffffffffc02033ee:	f5246fe3          	bltu	s0,s2,ffffffffc020334c <copy_range+0x5e>
ffffffffc02033f2:	bf95                	j	ffffffffc0203366 <copy_range+0x78>
                *ptep = (*ptep & ~PTE_W) | PTE_COW;
ffffffffc02033f4:	efb77713          	andi	a4,a4,-261
ffffffffc02033f8:	10076713          	ori	a4,a4,256
                perm = (perm & ~PTE_W) | PTE_COW;
ffffffffc02033fc:	8aed                	andi	a3,a3,27
ffffffffc02033fe:	1006e693          	ori	a3,a3,256
                *ptep = (*ptep & ~PTE_W) | PTE_COW;
ffffffffc0203402:	e098                	sd	a4,0(s1)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203404:	12040073          	sfence.vma	s0
}
ffffffffc0203408:	bf55                	j	ffffffffc02033bc <copy_range+0xce>
                return -E_NO_MEM;
ffffffffc020340a:	5571                	li	a0,-4
ffffffffc020340c:	bfb1                	j	ffffffffc0203368 <copy_range+0x7a>
        panic("pte2page called with invalid pte");
ffffffffc020340e:	00004617          	auipc	a2,0x4
ffffffffc0203412:	94a60613          	addi	a2,a2,-1718 # ffffffffc0206d58 <default_pmm_manager+0x128>
ffffffffc0203416:	07f00593          	li	a1,127
ffffffffc020341a:	00004517          	auipc	a0,0x4
ffffffffc020341e:	87650513          	addi	a0,a0,-1930 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc0203422:	870fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203426:	00004697          	auipc	a3,0x4
ffffffffc020342a:	99a68693          	addi	a3,a3,-1638 # ffffffffc0206dc0 <default_pmm_manager+0x190>
ffffffffc020342e:	00003617          	auipc	a2,0x3
ffffffffc0203432:	45260613          	addi	a2,a2,1106 # ffffffffc0206880 <commands+0x838>
ffffffffc0203436:	17e00593          	li	a1,382
ffffffffc020343a:	00004517          	auipc	a0,0x4
ffffffffc020343e:	94650513          	addi	a0,a0,-1722 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0203442:	850fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203446:	00004617          	auipc	a2,0x4
ffffffffc020344a:	8f260613          	addi	a2,a2,-1806 # ffffffffc0206d38 <default_pmm_manager+0x108>
ffffffffc020344e:	06900593          	li	a1,105
ffffffffc0203452:	00004517          	auipc	a0,0x4
ffffffffc0203456:	83e50513          	addi	a0,a0,-1986 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc020345a:	838fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020345e:	00004697          	auipc	a3,0x4
ffffffffc0203462:	93268693          	addi	a3,a3,-1742 # ffffffffc0206d90 <default_pmm_manager+0x160>
ffffffffc0203466:	00003617          	auipc	a2,0x3
ffffffffc020346a:	41a60613          	addi	a2,a2,1050 # ffffffffc0206880 <commands+0x838>
ffffffffc020346e:	17d00593          	li	a1,381
ffffffffc0203472:	00004517          	auipc	a0,0x4
ffffffffc0203476:	90e50513          	addi	a0,a0,-1778 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc020347a:	818fd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020347e <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020347e:	12058073          	sfence.vma	a1
}
ffffffffc0203482:	8082                	ret

ffffffffc0203484 <pgdir_alloc_page>:
{
ffffffffc0203484:	7179                	addi	sp,sp,-48
ffffffffc0203486:	ec26                	sd	s1,24(sp)
ffffffffc0203488:	e84a                	sd	s2,16(sp)
ffffffffc020348a:	e052                	sd	s4,0(sp)
ffffffffc020348c:	f406                	sd	ra,40(sp)
ffffffffc020348e:	f022                	sd	s0,32(sp)
ffffffffc0203490:	e44e                	sd	s3,8(sp)
ffffffffc0203492:	8a2a                	mv	s4,a0
ffffffffc0203494:	84ae                	mv	s1,a1
ffffffffc0203496:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203498:	100027f3          	csrr	a5,sstatus
ffffffffc020349c:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc020349e:	000ce997          	auipc	s3,0xce
ffffffffc02034a2:	7c298993          	addi	s3,s3,1986 # ffffffffc02d1c60 <pmm_manager>
ffffffffc02034a6:	ef8d                	bnez	a5,ffffffffc02034e0 <pgdir_alloc_page+0x5c>
ffffffffc02034a8:	0009b783          	ld	a5,0(s3)
ffffffffc02034ac:	4505                	li	a0,1
ffffffffc02034ae:	6f9c                	ld	a5,24(a5)
ffffffffc02034b0:	9782                	jalr	a5
ffffffffc02034b2:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02034b4:	cc09                	beqz	s0,ffffffffc02034ce <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02034b6:	86ca                	mv	a3,s2
ffffffffc02034b8:	8626                	mv	a2,s1
ffffffffc02034ba:	85a2                	mv	a1,s0
ffffffffc02034bc:	8552                	mv	a0,s4
ffffffffc02034be:	8faff0ef          	jal	ra,ffffffffc02025b8 <page_insert>
ffffffffc02034c2:	e915                	bnez	a0,ffffffffc02034f6 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc02034c4:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc02034c6:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc02034c8:	4785                	li	a5,1
ffffffffc02034ca:	04f71e63          	bne	a4,a5,ffffffffc0203526 <pgdir_alloc_page+0xa2>
}
ffffffffc02034ce:	70a2                	ld	ra,40(sp)
ffffffffc02034d0:	8522                	mv	a0,s0
ffffffffc02034d2:	7402                	ld	s0,32(sp)
ffffffffc02034d4:	64e2                	ld	s1,24(sp)
ffffffffc02034d6:	6942                	ld	s2,16(sp)
ffffffffc02034d8:	69a2                	ld	s3,8(sp)
ffffffffc02034da:	6a02                	ld	s4,0(sp)
ffffffffc02034dc:	6145                	addi	sp,sp,48
ffffffffc02034de:	8082                	ret
        intr_disable();
ffffffffc02034e0:	ccefd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02034e4:	0009b783          	ld	a5,0(s3)
ffffffffc02034e8:	4505                	li	a0,1
ffffffffc02034ea:	6f9c                	ld	a5,24(a5)
ffffffffc02034ec:	9782                	jalr	a5
ffffffffc02034ee:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02034f0:	cb8fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02034f4:	b7c1                	j	ffffffffc02034b4 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02034f6:	100027f3          	csrr	a5,sstatus
ffffffffc02034fa:	8b89                	andi	a5,a5,2
ffffffffc02034fc:	eb89                	bnez	a5,ffffffffc020350e <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc02034fe:	0009b783          	ld	a5,0(s3)
ffffffffc0203502:	8522                	mv	a0,s0
ffffffffc0203504:	4585                	li	a1,1
ffffffffc0203506:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203508:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020350a:	9782                	jalr	a5
    if (flag)
ffffffffc020350c:	b7c9                	j	ffffffffc02034ce <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc020350e:	ca0fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0203512:	0009b783          	ld	a5,0(s3)
ffffffffc0203516:	8522                	mv	a0,s0
ffffffffc0203518:	4585                	li	a1,1
ffffffffc020351a:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020351c:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020351e:	9782                	jalr	a5
        intr_enable();
ffffffffc0203520:	c88fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0203524:	b76d                	j	ffffffffc02034ce <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203526:	00004697          	auipc	a3,0x4
ffffffffc020352a:	e5a68693          	addi	a3,a3,-422 # ffffffffc0207380 <default_pmm_manager+0x750>
ffffffffc020352e:	00003617          	auipc	a2,0x3
ffffffffc0203532:	35260613          	addi	a2,a2,850 # ffffffffc0206880 <commands+0x838>
ffffffffc0203536:	1e400593          	li	a1,484
ffffffffc020353a:	00004517          	auipc	a0,0x4
ffffffffc020353e:	84650513          	addi	a0,a0,-1978 # ffffffffc0206d80 <default_pmm_manager+0x150>
ffffffffc0203542:	f51fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203546 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203546:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203548:	00004697          	auipc	a3,0x4
ffffffffc020354c:	e5068693          	addi	a3,a3,-432 # ffffffffc0207398 <default_pmm_manager+0x768>
ffffffffc0203550:	00003617          	auipc	a2,0x3
ffffffffc0203554:	33060613          	addi	a2,a2,816 # ffffffffc0206880 <commands+0x838>
ffffffffc0203558:	08300593          	li	a1,131
ffffffffc020355c:	00004517          	auipc	a0,0x4
ffffffffc0203560:	e5c50513          	addi	a0,a0,-420 # ffffffffc02073b8 <default_pmm_manager+0x788>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203564:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203566:	f2dfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020356a <mm_create>:
{
ffffffffc020356a:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020356c:	04000513          	li	a0,64
{
ffffffffc0203570:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203572:	ec0fe0ef          	jal	ra,ffffffffc0201c32 <kmalloc>
    if (mm != NULL)
ffffffffc0203576:	cd19                	beqz	a0,ffffffffc0203594 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203578:	e508                	sd	a0,8(a0)
ffffffffc020357a:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020357c:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203580:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203584:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203588:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc020358c:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc0203590:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203594:	60a2                	ld	ra,8(sp)
ffffffffc0203596:	0141                	addi	sp,sp,16
ffffffffc0203598:	8082                	ret

ffffffffc020359a <find_vma>:
{
ffffffffc020359a:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc020359c:	c505                	beqz	a0,ffffffffc02035c4 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc020359e:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02035a0:	c501                	beqz	a0,ffffffffc02035a8 <find_vma+0xe>
ffffffffc02035a2:	651c                	ld	a5,8(a0)
ffffffffc02035a4:	02f5f263          	bgeu	a1,a5,ffffffffc02035c8 <find_vma+0x2e>
    return listelm->next;
ffffffffc02035a8:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02035aa:	00f68d63          	beq	a3,a5,ffffffffc02035c4 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02035ae:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_matrix_out_size+0x1f38d8>
ffffffffc02035b2:	00e5e663          	bltu	a1,a4,ffffffffc02035be <find_vma+0x24>
ffffffffc02035b6:	ff07b703          	ld	a4,-16(a5)
ffffffffc02035ba:	00e5ec63          	bltu	a1,a4,ffffffffc02035d2 <find_vma+0x38>
ffffffffc02035be:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02035c0:	fef697e3          	bne	a3,a5,ffffffffc02035ae <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02035c4:	4501                	li	a0,0
}
ffffffffc02035c6:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02035c8:	691c                	ld	a5,16(a0)
ffffffffc02035ca:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02035a8 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02035ce:	ea88                	sd	a0,16(a3)
ffffffffc02035d0:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02035d2:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02035d6:	ea88                	sd	a0,16(a3)
ffffffffc02035d8:	8082                	ret

ffffffffc02035da <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02035da:	6590                	ld	a2,8(a1)
ffffffffc02035dc:	0105b803          	ld	a6,16(a1)
{
ffffffffc02035e0:	1141                	addi	sp,sp,-16
ffffffffc02035e2:	e406                	sd	ra,8(sp)
ffffffffc02035e4:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02035e6:	01066763          	bltu	a2,a6,ffffffffc02035f4 <insert_vma_struct+0x1a>
ffffffffc02035ea:	a085                	j	ffffffffc020364a <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc02035ec:	fe87b703          	ld	a4,-24(a5)
ffffffffc02035f0:	04e66863          	bltu	a2,a4,ffffffffc0203640 <insert_vma_struct+0x66>
ffffffffc02035f4:	86be                	mv	a3,a5
ffffffffc02035f6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc02035f8:	fef51ae3          	bne	a0,a5,ffffffffc02035ec <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc02035fc:	02a68463          	beq	a3,a0,ffffffffc0203624 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203600:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203604:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203608:	08e8f163          	bgeu	a7,a4,ffffffffc020368a <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020360c:	04e66f63          	bltu	a2,a4,ffffffffc020366a <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203610:	00f50a63          	beq	a0,a5,ffffffffc0203624 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203614:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203618:	05076963          	bltu	a4,a6,ffffffffc020366a <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020361c:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203620:	02c77363          	bgeu	a4,a2,ffffffffc0203646 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203624:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203626:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203628:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020362c:	e390                	sd	a2,0(a5)
ffffffffc020362e:	e690                	sd	a2,8(a3)
}
ffffffffc0203630:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203632:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203634:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203636:	0017079b          	addiw	a5,a4,1
ffffffffc020363a:	d11c                	sw	a5,32(a0)
}
ffffffffc020363c:	0141                	addi	sp,sp,16
ffffffffc020363e:	8082                	ret
    if (le_prev != list)
ffffffffc0203640:	fca690e3          	bne	a3,a0,ffffffffc0203600 <insert_vma_struct+0x26>
ffffffffc0203644:	bfd1                	j	ffffffffc0203618 <insert_vma_struct+0x3e>
ffffffffc0203646:	f01ff0ef          	jal	ra,ffffffffc0203546 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc020364a:	00004697          	auipc	a3,0x4
ffffffffc020364e:	d7e68693          	addi	a3,a3,-642 # ffffffffc02073c8 <default_pmm_manager+0x798>
ffffffffc0203652:	00003617          	auipc	a2,0x3
ffffffffc0203656:	22e60613          	addi	a2,a2,558 # ffffffffc0206880 <commands+0x838>
ffffffffc020365a:	08900593          	li	a1,137
ffffffffc020365e:	00004517          	auipc	a0,0x4
ffffffffc0203662:	d5a50513          	addi	a0,a0,-678 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203666:	e2dfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020366a:	00004697          	auipc	a3,0x4
ffffffffc020366e:	d9e68693          	addi	a3,a3,-610 # ffffffffc0207408 <default_pmm_manager+0x7d8>
ffffffffc0203672:	00003617          	auipc	a2,0x3
ffffffffc0203676:	20e60613          	addi	a2,a2,526 # ffffffffc0206880 <commands+0x838>
ffffffffc020367a:	08200593          	li	a1,130
ffffffffc020367e:	00004517          	auipc	a0,0x4
ffffffffc0203682:	d3a50513          	addi	a0,a0,-710 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203686:	e0dfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020368a:	00004697          	auipc	a3,0x4
ffffffffc020368e:	d5e68693          	addi	a3,a3,-674 # ffffffffc02073e8 <default_pmm_manager+0x7b8>
ffffffffc0203692:	00003617          	auipc	a2,0x3
ffffffffc0203696:	1ee60613          	addi	a2,a2,494 # ffffffffc0206880 <commands+0x838>
ffffffffc020369a:	08100593          	li	a1,129
ffffffffc020369e:	00004517          	auipc	a0,0x4
ffffffffc02036a2:	d1a50513          	addi	a0,a0,-742 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc02036a6:	dedfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02036aa <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02036aa:	591c                	lw	a5,48(a0)
{
ffffffffc02036ac:	1141                	addi	sp,sp,-16
ffffffffc02036ae:	e406                	sd	ra,8(sp)
ffffffffc02036b0:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02036b2:	e78d                	bnez	a5,ffffffffc02036dc <mm_destroy+0x32>
ffffffffc02036b4:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02036b6:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02036b8:	00a40c63          	beq	s0,a0,ffffffffc02036d0 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02036bc:	6118                	ld	a4,0(a0)
ffffffffc02036be:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02036c0:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02036c2:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02036c4:	e398                	sd	a4,0(a5)
ffffffffc02036c6:	e1cfe0ef          	jal	ra,ffffffffc0201ce2 <kfree>
    return listelm->next;
ffffffffc02036ca:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02036cc:	fea418e3          	bne	s0,a0,ffffffffc02036bc <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02036d0:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02036d2:	6402                	ld	s0,0(sp)
ffffffffc02036d4:	60a2                	ld	ra,8(sp)
ffffffffc02036d6:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02036d8:	e0afe06f          	j	ffffffffc0201ce2 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02036dc:	00004697          	auipc	a3,0x4
ffffffffc02036e0:	d4c68693          	addi	a3,a3,-692 # ffffffffc0207428 <default_pmm_manager+0x7f8>
ffffffffc02036e4:	00003617          	auipc	a2,0x3
ffffffffc02036e8:	19c60613          	addi	a2,a2,412 # ffffffffc0206880 <commands+0x838>
ffffffffc02036ec:	0ad00593          	li	a1,173
ffffffffc02036f0:	00004517          	auipc	a0,0x4
ffffffffc02036f4:	cc850513          	addi	a0,a0,-824 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc02036f8:	d9bfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02036fc <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc02036fc:	7139                	addi	sp,sp,-64
ffffffffc02036fe:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203700:	6405                	lui	s0,0x1
ffffffffc0203702:	147d                	addi	s0,s0,-1
ffffffffc0203704:	77fd                	lui	a5,0xfffff
ffffffffc0203706:	9622                	add	a2,a2,s0
ffffffffc0203708:	962e                	add	a2,a2,a1
{
ffffffffc020370a:	f426                	sd	s1,40(sp)
ffffffffc020370c:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020370e:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203712:	f04a                	sd	s2,32(sp)
ffffffffc0203714:	ec4e                	sd	s3,24(sp)
ffffffffc0203716:	e852                	sd	s4,16(sp)
ffffffffc0203718:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc020371a:	002005b7          	lui	a1,0x200
ffffffffc020371e:	00f67433          	and	s0,a2,a5
ffffffffc0203722:	06b4e363          	bltu	s1,a1,ffffffffc0203788 <mm_map+0x8c>
ffffffffc0203726:	0684f163          	bgeu	s1,s0,ffffffffc0203788 <mm_map+0x8c>
ffffffffc020372a:	4785                	li	a5,1
ffffffffc020372c:	07fe                	slli	a5,a5,0x1f
ffffffffc020372e:	0487ed63          	bltu	a5,s0,ffffffffc0203788 <mm_map+0x8c>
ffffffffc0203732:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203734:	cd21                	beqz	a0,ffffffffc020378c <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203736:	85a6                	mv	a1,s1
ffffffffc0203738:	8ab6                	mv	s5,a3
ffffffffc020373a:	8a3a                	mv	s4,a4
ffffffffc020373c:	e5fff0ef          	jal	ra,ffffffffc020359a <find_vma>
ffffffffc0203740:	c501                	beqz	a0,ffffffffc0203748 <mm_map+0x4c>
ffffffffc0203742:	651c                	ld	a5,8(a0)
ffffffffc0203744:	0487e263          	bltu	a5,s0,ffffffffc0203788 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203748:	03000513          	li	a0,48
ffffffffc020374c:	ce6fe0ef          	jal	ra,ffffffffc0201c32 <kmalloc>
ffffffffc0203750:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203752:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203754:	02090163          	beqz	s2,ffffffffc0203776 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203758:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc020375a:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc020375e:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203762:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0203766:	85ca                	mv	a1,s2
ffffffffc0203768:	e73ff0ef          	jal	ra,ffffffffc02035da <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc020376c:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc020376e:	000a0463          	beqz	s4,ffffffffc0203776 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0203772:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f40>

out:
    return ret;
}
ffffffffc0203776:	70e2                	ld	ra,56(sp)
ffffffffc0203778:	7442                	ld	s0,48(sp)
ffffffffc020377a:	74a2                	ld	s1,40(sp)
ffffffffc020377c:	7902                	ld	s2,32(sp)
ffffffffc020377e:	69e2                	ld	s3,24(sp)
ffffffffc0203780:	6a42                	ld	s4,16(sp)
ffffffffc0203782:	6aa2                	ld	s5,8(sp)
ffffffffc0203784:	6121                	addi	sp,sp,64
ffffffffc0203786:	8082                	ret
        return -E_INVAL;
ffffffffc0203788:	5575                	li	a0,-3
ffffffffc020378a:	b7f5                	j	ffffffffc0203776 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc020378c:	00004697          	auipc	a3,0x4
ffffffffc0203790:	cb468693          	addi	a3,a3,-844 # ffffffffc0207440 <default_pmm_manager+0x810>
ffffffffc0203794:	00003617          	auipc	a2,0x3
ffffffffc0203798:	0ec60613          	addi	a2,a2,236 # ffffffffc0206880 <commands+0x838>
ffffffffc020379c:	0c200593          	li	a1,194
ffffffffc02037a0:	00004517          	auipc	a0,0x4
ffffffffc02037a4:	c1850513          	addi	a0,a0,-1000 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc02037a8:	cebfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02037ac <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02037ac:	7139                	addi	sp,sp,-64
ffffffffc02037ae:	fc06                	sd	ra,56(sp)
ffffffffc02037b0:	f822                	sd	s0,48(sp)
ffffffffc02037b2:	f426                	sd	s1,40(sp)
ffffffffc02037b4:	f04a                	sd	s2,32(sp)
ffffffffc02037b6:	ec4e                	sd	s3,24(sp)
ffffffffc02037b8:	e852                	sd	s4,16(sp)
ffffffffc02037ba:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02037bc:	c52d                	beqz	a0,ffffffffc0203826 <dup_mmap+0x7a>
ffffffffc02037be:	892a                	mv	s2,a0
ffffffffc02037c0:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02037c2:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02037c4:	e595                	bnez	a1,ffffffffc02037f0 <dup_mmap+0x44>
ffffffffc02037c6:	a085                	j	ffffffffc0203826 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02037c8:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc02037ca:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_matrix_out_size+0x1f38f8>
        vma->vm_end = vm_end;
ffffffffc02037ce:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02037d2:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc02037d6:	e05ff0ef          	jal	ra,ffffffffc02035da <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc02037da:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8f50>
ffffffffc02037de:	fe843603          	ld	a2,-24(s0)
ffffffffc02037e2:	6c8c                	ld	a1,24(s1)
ffffffffc02037e4:	01893503          	ld	a0,24(s2)
ffffffffc02037e8:	4701                	li	a4,0
ffffffffc02037ea:	b05ff0ef          	jal	ra,ffffffffc02032ee <copy_range>
ffffffffc02037ee:	e105                	bnez	a0,ffffffffc020380e <dup_mmap+0x62>
    return listelm->prev;
ffffffffc02037f0:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc02037f2:	02848863          	beq	s1,s0,ffffffffc0203822 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02037f6:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc02037fa:	fe843a83          	ld	s5,-24(s0)
ffffffffc02037fe:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203802:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203806:	c2cfe0ef          	jal	ra,ffffffffc0201c32 <kmalloc>
ffffffffc020380a:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc020380c:	fd55                	bnez	a0,ffffffffc02037c8 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc020380e:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203810:	70e2                	ld	ra,56(sp)
ffffffffc0203812:	7442                	ld	s0,48(sp)
ffffffffc0203814:	74a2                	ld	s1,40(sp)
ffffffffc0203816:	7902                	ld	s2,32(sp)
ffffffffc0203818:	69e2                	ld	s3,24(sp)
ffffffffc020381a:	6a42                	ld	s4,16(sp)
ffffffffc020381c:	6aa2                	ld	s5,8(sp)
ffffffffc020381e:	6121                	addi	sp,sp,64
ffffffffc0203820:	8082                	ret
    return 0;
ffffffffc0203822:	4501                	li	a0,0
ffffffffc0203824:	b7f5                	j	ffffffffc0203810 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203826:	00004697          	auipc	a3,0x4
ffffffffc020382a:	c2a68693          	addi	a3,a3,-982 # ffffffffc0207450 <default_pmm_manager+0x820>
ffffffffc020382e:	00003617          	auipc	a2,0x3
ffffffffc0203832:	05260613          	addi	a2,a2,82 # ffffffffc0206880 <commands+0x838>
ffffffffc0203836:	0de00593          	li	a1,222
ffffffffc020383a:	00004517          	auipc	a0,0x4
ffffffffc020383e:	b7e50513          	addi	a0,a0,-1154 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203842:	c51fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203846 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203846:	1101                	addi	sp,sp,-32
ffffffffc0203848:	ec06                	sd	ra,24(sp)
ffffffffc020384a:	e822                	sd	s0,16(sp)
ffffffffc020384c:	e426                	sd	s1,8(sp)
ffffffffc020384e:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203850:	c531                	beqz	a0,ffffffffc020389c <exit_mmap+0x56>
ffffffffc0203852:	591c                	lw	a5,48(a0)
ffffffffc0203854:	84aa                	mv	s1,a0
ffffffffc0203856:	e3b9                	bnez	a5,ffffffffc020389c <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203858:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc020385a:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc020385e:	02850663          	beq	a0,s0,ffffffffc020388a <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203862:	ff043603          	ld	a2,-16(s0)
ffffffffc0203866:	fe843583          	ld	a1,-24(s0)
ffffffffc020386a:	854a                	mv	a0,s2
ffffffffc020386c:	8d9fe0ef          	jal	ra,ffffffffc0202144 <unmap_range>
ffffffffc0203870:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203872:	fe8498e3          	bne	s1,s0,ffffffffc0203862 <exit_mmap+0x1c>
ffffffffc0203876:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203878:	00848c63          	beq	s1,s0,ffffffffc0203890 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc020387c:	ff043603          	ld	a2,-16(s0)
ffffffffc0203880:	fe843583          	ld	a1,-24(s0)
ffffffffc0203884:	854a                	mv	a0,s2
ffffffffc0203886:	a05fe0ef          	jal	ra,ffffffffc020228a <exit_range>
ffffffffc020388a:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc020388c:	fe8498e3          	bne	s1,s0,ffffffffc020387c <exit_mmap+0x36>
    }
}
ffffffffc0203890:	60e2                	ld	ra,24(sp)
ffffffffc0203892:	6442                	ld	s0,16(sp)
ffffffffc0203894:	64a2                	ld	s1,8(sp)
ffffffffc0203896:	6902                	ld	s2,0(sp)
ffffffffc0203898:	6105                	addi	sp,sp,32
ffffffffc020389a:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc020389c:	00004697          	auipc	a3,0x4
ffffffffc02038a0:	bd468693          	addi	a3,a3,-1068 # ffffffffc0207470 <default_pmm_manager+0x840>
ffffffffc02038a4:	00003617          	auipc	a2,0x3
ffffffffc02038a8:	fdc60613          	addi	a2,a2,-36 # ffffffffc0206880 <commands+0x838>
ffffffffc02038ac:	0f700593          	li	a1,247
ffffffffc02038b0:	00004517          	auipc	a0,0x4
ffffffffc02038b4:	b0850513          	addi	a0,a0,-1272 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc02038b8:	bdbfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02038bc <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc02038bc:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02038be:	04000513          	li	a0,64
{
ffffffffc02038c2:	fc06                	sd	ra,56(sp)
ffffffffc02038c4:	f822                	sd	s0,48(sp)
ffffffffc02038c6:	f426                	sd	s1,40(sp)
ffffffffc02038c8:	f04a                	sd	s2,32(sp)
ffffffffc02038ca:	ec4e                	sd	s3,24(sp)
ffffffffc02038cc:	e852                	sd	s4,16(sp)
ffffffffc02038ce:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02038d0:	b62fe0ef          	jal	ra,ffffffffc0201c32 <kmalloc>
    if (mm != NULL)
ffffffffc02038d4:	2e050663          	beqz	a0,ffffffffc0203bc0 <vmm_init+0x304>
ffffffffc02038d8:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc02038da:	e508                	sd	a0,8(a0)
ffffffffc02038dc:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02038de:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02038e2:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02038e6:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02038ea:	02053423          	sd	zero,40(a0)
ffffffffc02038ee:	02052823          	sw	zero,48(a0)
ffffffffc02038f2:	02053c23          	sd	zero,56(a0)
ffffffffc02038f6:	03200413          	li	s0,50
ffffffffc02038fa:	a811                	j	ffffffffc020390e <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc02038fc:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc02038fe:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203900:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203904:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203906:	8526                	mv	a0,s1
ffffffffc0203908:	cd3ff0ef          	jal	ra,ffffffffc02035da <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc020390c:	c80d                	beqz	s0,ffffffffc020393e <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020390e:	03000513          	li	a0,48
ffffffffc0203912:	b20fe0ef          	jal	ra,ffffffffc0201c32 <kmalloc>
ffffffffc0203916:	85aa                	mv	a1,a0
ffffffffc0203918:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc020391c:	f165                	bnez	a0,ffffffffc02038fc <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc020391e:	00004697          	auipc	a3,0x4
ffffffffc0203922:	cea68693          	addi	a3,a3,-790 # ffffffffc0207608 <default_pmm_manager+0x9d8>
ffffffffc0203926:	00003617          	auipc	a2,0x3
ffffffffc020392a:	f5a60613          	addi	a2,a2,-166 # ffffffffc0206880 <commands+0x838>
ffffffffc020392e:	13b00593          	li	a1,315
ffffffffc0203932:	00004517          	auipc	a0,0x4
ffffffffc0203936:	a8650513          	addi	a0,a0,-1402 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc020393a:	b59fc0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc020393e:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203942:	1f900913          	li	s2,505
ffffffffc0203946:	a819                	j	ffffffffc020395c <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203948:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc020394a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020394c:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203950:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203952:	8526                	mv	a0,s1
ffffffffc0203954:	c87ff0ef          	jal	ra,ffffffffc02035da <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203958:	03240a63          	beq	s0,s2,ffffffffc020398c <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020395c:	03000513          	li	a0,48
ffffffffc0203960:	ad2fe0ef          	jal	ra,ffffffffc0201c32 <kmalloc>
ffffffffc0203964:	85aa                	mv	a1,a0
ffffffffc0203966:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc020396a:	fd79                	bnez	a0,ffffffffc0203948 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc020396c:	00004697          	auipc	a3,0x4
ffffffffc0203970:	c9c68693          	addi	a3,a3,-868 # ffffffffc0207608 <default_pmm_manager+0x9d8>
ffffffffc0203974:	00003617          	auipc	a2,0x3
ffffffffc0203978:	f0c60613          	addi	a2,a2,-244 # ffffffffc0206880 <commands+0x838>
ffffffffc020397c:	14200593          	li	a1,322
ffffffffc0203980:	00004517          	auipc	a0,0x4
ffffffffc0203984:	a3850513          	addi	a0,a0,-1480 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203988:	b0bfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return listelm->next;
ffffffffc020398c:	649c                	ld	a5,8(s1)
ffffffffc020398e:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203990:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203994:	16f48663          	beq	s1,a5,ffffffffc0203b00 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203998:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd2d340>
ffffffffc020399c:	ffe70693          	addi	a3,a4,-2 # ffe <_binary_obj___user_faultread_out_size-0x8f42>
ffffffffc02039a0:	10d61063          	bne	a2,a3,ffffffffc0203aa0 <vmm_init+0x1e4>
ffffffffc02039a4:	ff07b683          	ld	a3,-16(a5)
ffffffffc02039a8:	0ed71c63          	bne	a4,a3,ffffffffc0203aa0 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc02039ac:	0715                	addi	a4,a4,5
ffffffffc02039ae:	679c                	ld	a5,8(a5)
ffffffffc02039b0:	feb712e3          	bne	a4,a1,ffffffffc0203994 <vmm_init+0xd8>
ffffffffc02039b4:	4a1d                	li	s4,7
ffffffffc02039b6:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc02039b8:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc02039bc:	85a2                	mv	a1,s0
ffffffffc02039be:	8526                	mv	a0,s1
ffffffffc02039c0:	bdbff0ef          	jal	ra,ffffffffc020359a <find_vma>
ffffffffc02039c4:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc02039c6:	16050d63          	beqz	a0,ffffffffc0203b40 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc02039ca:	00140593          	addi	a1,s0,1
ffffffffc02039ce:	8526                	mv	a0,s1
ffffffffc02039d0:	bcbff0ef          	jal	ra,ffffffffc020359a <find_vma>
ffffffffc02039d4:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc02039d6:	14050563          	beqz	a0,ffffffffc0203b20 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc02039da:	85d2                	mv	a1,s4
ffffffffc02039dc:	8526                	mv	a0,s1
ffffffffc02039de:	bbdff0ef          	jal	ra,ffffffffc020359a <find_vma>
        assert(vma3 == NULL);
ffffffffc02039e2:	16051f63          	bnez	a0,ffffffffc0203b60 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc02039e6:	00340593          	addi	a1,s0,3
ffffffffc02039ea:	8526                	mv	a0,s1
ffffffffc02039ec:	bafff0ef          	jal	ra,ffffffffc020359a <find_vma>
        assert(vma4 == NULL);
ffffffffc02039f0:	1a051863          	bnez	a0,ffffffffc0203ba0 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc02039f4:	00440593          	addi	a1,s0,4
ffffffffc02039f8:	8526                	mv	a0,s1
ffffffffc02039fa:	ba1ff0ef          	jal	ra,ffffffffc020359a <find_vma>
        assert(vma5 == NULL);
ffffffffc02039fe:	18051163          	bnez	a0,ffffffffc0203b80 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203a02:	00893783          	ld	a5,8(s2)
ffffffffc0203a06:	0a879d63          	bne	a5,s0,ffffffffc0203ac0 <vmm_init+0x204>
ffffffffc0203a0a:	01093783          	ld	a5,16(s2)
ffffffffc0203a0e:	0b479963          	bne	a5,s4,ffffffffc0203ac0 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203a12:	0089b783          	ld	a5,8(s3)
ffffffffc0203a16:	0c879563          	bne	a5,s0,ffffffffc0203ae0 <vmm_init+0x224>
ffffffffc0203a1a:	0109b783          	ld	a5,16(s3)
ffffffffc0203a1e:	0d479163          	bne	a5,s4,ffffffffc0203ae0 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203a22:	0415                	addi	s0,s0,5
ffffffffc0203a24:	0a15                	addi	s4,s4,5
ffffffffc0203a26:	f9541be3          	bne	s0,s5,ffffffffc02039bc <vmm_init+0x100>
ffffffffc0203a2a:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203a2c:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203a2e:	85a2                	mv	a1,s0
ffffffffc0203a30:	8526                	mv	a0,s1
ffffffffc0203a32:	b69ff0ef          	jal	ra,ffffffffc020359a <find_vma>
ffffffffc0203a36:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203a3a:	c90d                	beqz	a0,ffffffffc0203a6c <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203a3c:	6914                	ld	a3,16(a0)
ffffffffc0203a3e:	6510                	ld	a2,8(a0)
ffffffffc0203a40:	00004517          	auipc	a0,0x4
ffffffffc0203a44:	b5050513          	addi	a0,a0,-1200 # ffffffffc0207590 <default_pmm_manager+0x960>
ffffffffc0203a48:	f50fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203a4c:	00004697          	auipc	a3,0x4
ffffffffc0203a50:	b6c68693          	addi	a3,a3,-1172 # ffffffffc02075b8 <default_pmm_manager+0x988>
ffffffffc0203a54:	00003617          	auipc	a2,0x3
ffffffffc0203a58:	e2c60613          	addi	a2,a2,-468 # ffffffffc0206880 <commands+0x838>
ffffffffc0203a5c:	16800593          	li	a1,360
ffffffffc0203a60:	00004517          	auipc	a0,0x4
ffffffffc0203a64:	95850513          	addi	a0,a0,-1704 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203a68:	a2bfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203a6c:	147d                	addi	s0,s0,-1
ffffffffc0203a6e:	fd2410e3          	bne	s0,s2,ffffffffc0203a2e <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203a72:	8526                	mv	a0,s1
ffffffffc0203a74:	c37ff0ef          	jal	ra,ffffffffc02036aa <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203a78:	00004517          	auipc	a0,0x4
ffffffffc0203a7c:	b5850513          	addi	a0,a0,-1192 # ffffffffc02075d0 <default_pmm_manager+0x9a0>
ffffffffc0203a80:	f18fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0203a84:	7442                	ld	s0,48(sp)
ffffffffc0203a86:	70e2                	ld	ra,56(sp)
ffffffffc0203a88:	74a2                	ld	s1,40(sp)
ffffffffc0203a8a:	7902                	ld	s2,32(sp)
ffffffffc0203a8c:	69e2                	ld	s3,24(sp)
ffffffffc0203a8e:	6a42                	ld	s4,16(sp)
ffffffffc0203a90:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203a92:	00004517          	auipc	a0,0x4
ffffffffc0203a96:	b5e50513          	addi	a0,a0,-1186 # ffffffffc02075f0 <default_pmm_manager+0x9c0>
}
ffffffffc0203a9a:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203a9c:	efcfc06f          	j	ffffffffc0200198 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203aa0:	00004697          	auipc	a3,0x4
ffffffffc0203aa4:	a0868693          	addi	a3,a3,-1528 # ffffffffc02074a8 <default_pmm_manager+0x878>
ffffffffc0203aa8:	00003617          	auipc	a2,0x3
ffffffffc0203aac:	dd860613          	addi	a2,a2,-552 # ffffffffc0206880 <commands+0x838>
ffffffffc0203ab0:	14c00593          	li	a1,332
ffffffffc0203ab4:	00004517          	auipc	a0,0x4
ffffffffc0203ab8:	90450513          	addi	a0,a0,-1788 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203abc:	9d7fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203ac0:	00004697          	auipc	a3,0x4
ffffffffc0203ac4:	a7068693          	addi	a3,a3,-1424 # ffffffffc0207530 <default_pmm_manager+0x900>
ffffffffc0203ac8:	00003617          	auipc	a2,0x3
ffffffffc0203acc:	db860613          	addi	a2,a2,-584 # ffffffffc0206880 <commands+0x838>
ffffffffc0203ad0:	15d00593          	li	a1,349
ffffffffc0203ad4:	00004517          	auipc	a0,0x4
ffffffffc0203ad8:	8e450513          	addi	a0,a0,-1820 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203adc:	9b7fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203ae0:	00004697          	auipc	a3,0x4
ffffffffc0203ae4:	a8068693          	addi	a3,a3,-1408 # ffffffffc0207560 <default_pmm_manager+0x930>
ffffffffc0203ae8:	00003617          	auipc	a2,0x3
ffffffffc0203aec:	d9860613          	addi	a2,a2,-616 # ffffffffc0206880 <commands+0x838>
ffffffffc0203af0:	15e00593          	li	a1,350
ffffffffc0203af4:	00004517          	auipc	a0,0x4
ffffffffc0203af8:	8c450513          	addi	a0,a0,-1852 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203afc:	997fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203b00:	00004697          	auipc	a3,0x4
ffffffffc0203b04:	99068693          	addi	a3,a3,-1648 # ffffffffc0207490 <default_pmm_manager+0x860>
ffffffffc0203b08:	00003617          	auipc	a2,0x3
ffffffffc0203b0c:	d7860613          	addi	a2,a2,-648 # ffffffffc0206880 <commands+0x838>
ffffffffc0203b10:	14a00593          	li	a1,330
ffffffffc0203b14:	00004517          	auipc	a0,0x4
ffffffffc0203b18:	8a450513          	addi	a0,a0,-1884 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203b1c:	977fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2 != NULL);
ffffffffc0203b20:	00004697          	auipc	a3,0x4
ffffffffc0203b24:	9d068693          	addi	a3,a3,-1584 # ffffffffc02074f0 <default_pmm_manager+0x8c0>
ffffffffc0203b28:	00003617          	auipc	a2,0x3
ffffffffc0203b2c:	d5860613          	addi	a2,a2,-680 # ffffffffc0206880 <commands+0x838>
ffffffffc0203b30:	15500593          	li	a1,341
ffffffffc0203b34:	00004517          	auipc	a0,0x4
ffffffffc0203b38:	88450513          	addi	a0,a0,-1916 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203b3c:	957fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1 != NULL);
ffffffffc0203b40:	00004697          	auipc	a3,0x4
ffffffffc0203b44:	9a068693          	addi	a3,a3,-1632 # ffffffffc02074e0 <default_pmm_manager+0x8b0>
ffffffffc0203b48:	00003617          	auipc	a2,0x3
ffffffffc0203b4c:	d3860613          	addi	a2,a2,-712 # ffffffffc0206880 <commands+0x838>
ffffffffc0203b50:	15300593          	li	a1,339
ffffffffc0203b54:	00004517          	auipc	a0,0x4
ffffffffc0203b58:	86450513          	addi	a0,a0,-1948 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203b5c:	937fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma3 == NULL);
ffffffffc0203b60:	00004697          	auipc	a3,0x4
ffffffffc0203b64:	9a068693          	addi	a3,a3,-1632 # ffffffffc0207500 <default_pmm_manager+0x8d0>
ffffffffc0203b68:	00003617          	auipc	a2,0x3
ffffffffc0203b6c:	d1860613          	addi	a2,a2,-744 # ffffffffc0206880 <commands+0x838>
ffffffffc0203b70:	15700593          	li	a1,343
ffffffffc0203b74:	00004517          	auipc	a0,0x4
ffffffffc0203b78:	84450513          	addi	a0,a0,-1980 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203b7c:	917fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma5 == NULL);
ffffffffc0203b80:	00004697          	auipc	a3,0x4
ffffffffc0203b84:	9a068693          	addi	a3,a3,-1632 # ffffffffc0207520 <default_pmm_manager+0x8f0>
ffffffffc0203b88:	00003617          	auipc	a2,0x3
ffffffffc0203b8c:	cf860613          	addi	a2,a2,-776 # ffffffffc0206880 <commands+0x838>
ffffffffc0203b90:	15b00593          	li	a1,347
ffffffffc0203b94:	00004517          	auipc	a0,0x4
ffffffffc0203b98:	82450513          	addi	a0,a0,-2012 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203b9c:	8f7fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma4 == NULL);
ffffffffc0203ba0:	00004697          	auipc	a3,0x4
ffffffffc0203ba4:	97068693          	addi	a3,a3,-1680 # ffffffffc0207510 <default_pmm_manager+0x8e0>
ffffffffc0203ba8:	00003617          	auipc	a2,0x3
ffffffffc0203bac:	cd860613          	addi	a2,a2,-808 # ffffffffc0206880 <commands+0x838>
ffffffffc0203bb0:	15900593          	li	a1,345
ffffffffc0203bb4:	00004517          	auipc	a0,0x4
ffffffffc0203bb8:	80450513          	addi	a0,a0,-2044 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203bbc:	8d7fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(mm != NULL);
ffffffffc0203bc0:	00004697          	auipc	a3,0x4
ffffffffc0203bc4:	88068693          	addi	a3,a3,-1920 # ffffffffc0207440 <default_pmm_manager+0x810>
ffffffffc0203bc8:	00003617          	auipc	a2,0x3
ffffffffc0203bcc:	cb860613          	addi	a2,a2,-840 # ffffffffc0206880 <commands+0x838>
ffffffffc0203bd0:	13300593          	li	a1,307
ffffffffc0203bd4:	00003517          	auipc	a0,0x3
ffffffffc0203bd8:	7e450513          	addi	a0,a0,2020 # ffffffffc02073b8 <default_pmm_manager+0x788>
ffffffffc0203bdc:	8b7fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203be0 <do_pgfault>:
}

// do_pgfault - handler of page fault, including demand allocation and COW
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
    pgfault_num++;
ffffffffc0203be0:	000ce797          	auipc	a5,0xce
ffffffffc0203be4:	0907a783          	lw	a5,144(a5) # ffffffffc02d1c70 <pgfault_num>
ffffffffc0203be8:	2785                	addiw	a5,a5,1
ffffffffc0203bea:	000ce717          	auipc	a4,0xce
ffffffffc0203bee:	08f72323          	sw	a5,134(a4) # ffffffffc02d1c70 <pgfault_num>

    if (mm == NULL)
ffffffffc0203bf2:	16050663          	beqz	a0,ffffffffc0203d5e <do_pgfault+0x17e>
{
ffffffffc0203bf6:	715d                	addi	sp,sp,-80
ffffffffc0203bf8:	f44e                	sd	s3,40(sp)
ffffffffc0203bfa:	89ae                	mv	s3,a1
    {
        return -E_INVAL;
    }

    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203bfc:	85b2                	mv	a1,a2
{
ffffffffc0203bfe:	e0a2                	sd	s0,64(sp)
ffffffffc0203c00:	fc26                	sd	s1,56(sp)
ffffffffc0203c02:	f84a                	sd	s2,48(sp)
ffffffffc0203c04:	e486                	sd	ra,72(sp)
ffffffffc0203c06:	f052                	sd	s4,32(sp)
ffffffffc0203c08:	ec56                	sd	s5,24(sp)
ffffffffc0203c0a:	e85a                	sd	s6,16(sp)
ffffffffc0203c0c:	e45e                	sd	s7,8(sp)
ffffffffc0203c0e:	84aa                	mv	s1,a0
ffffffffc0203c10:	8432                	mv	s0,a2
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203c12:	989ff0ef          	jal	ra,ffffffffc020359a <find_vma>
ffffffffc0203c16:	892a                	mv	s2,a0
    if (vma == NULL || addr < vma->vm_start)
ffffffffc0203c18:	12050f63          	beqz	a0,ffffffffc0203d56 <do_pgfault+0x176>
ffffffffc0203c1c:	651c                	ld	a5,8(a0)
ffffffffc0203c1e:	12f46c63          	bltu	s0,a5,ffffffffc0203d56 <do_pgfault+0x176>
    {
        return -E_INVAL;
    }

    bool write = (error_code & 0x2) != 0;
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203c22:	75fd                	lui	a1,0xfffff
    pte_t *ptep = get_pte(mm->pgdir, la, 0);
ffffffffc0203c24:	6c88                	ld	a0,24(s1)
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203c26:	8c6d                	and	s0,s0,a1
    pte_t *ptep = get_pte(mm->pgdir, la, 0);
ffffffffc0203c28:	4601                	li	a2,0
ffffffffc0203c2a:	85a2                	mv	a1,s0
ffffffffc0203c2c:	a9cfe0ef          	jal	ra,ffffffffc0201ec8 <get_pte>
ffffffffc0203c30:	87aa                	mv	a5,a0

    if (ptep == NULL || !(*ptep & PTE_V))
ffffffffc0203c32:	c569                	beqz	a0,ffffffffc0203cfc <do_pgfault+0x11c>
ffffffffc0203c34:	00053a03          	ld	s4,0(a0)
ffffffffc0203c38:	001a7713          	andi	a4,s4,1
ffffffffc0203c3c:	c361                	beqz	a4,ffffffffc0203cfc <do_pgfault+0x11c>
            return -E_NO_MEM;
        }
        return 0;
    }

    if (write && (*ptep & PTE_COW))
ffffffffc0203c3e:	0029f593          	andi	a1,s3,2
ffffffffc0203c42:	10058a63          	beqz	a1,ffffffffc0203d56 <do_pgfault+0x176>
ffffffffc0203c46:	100a7713          	andi	a4,s4,256
ffffffffc0203c4a:	10070663          	beqz	a4,ffffffffc0203d56 <do_pgfault+0x176>
    if (PPN(pa) >= npage)
ffffffffc0203c4e:	000ceb17          	auipc	s6,0xce
ffffffffc0203c52:	002b0b13          	addi	s6,s6,2 # ffffffffc02d1c50 <npage>
ffffffffc0203c56:	000b3683          	ld	a3,0(s6)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203c5a:	002a1713          	slli	a4,s4,0x2
ffffffffc0203c5e:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0203c60:	10d77163          	bgeu	a4,a3,ffffffffc0203d62 <do_pgfault+0x182>
    return &pages[PPN(pa) - nbase];
ffffffffc0203c64:	000ceb97          	auipc	s7,0xce
ffffffffc0203c68:	ff4b8b93          	addi	s7,s7,-12 # ffffffffc02d1c58 <pages>
ffffffffc0203c6c:	000bb903          	ld	s2,0(s7)
ffffffffc0203c70:	00005a97          	auipc	s5,0x5
ffffffffc0203c74:	9e0aba83          	ld	s5,-1568(s5) # ffffffffc0208650 <nbase>
ffffffffc0203c78:	41570733          	sub	a4,a4,s5
ffffffffc0203c7c:	071a                	slli	a4,a4,0x6
ffffffffc0203c7e:	993a                	add	s2,s2,a4
    {
        uint32_t perm = (*ptep & PTE_USER);
        struct Page *page = pte2page(*ptep);

        if (page_ref(page) > 1)
ffffffffc0203c80:	00092683          	lw	a3,0(s2)
ffffffffc0203c84:	4705                	li	a4,1
ffffffffc0203c86:	0ad75d63          	bge	a4,a3,ffffffffc0203d40 <do_pgfault+0x160>
        {
            struct Page *npage = alloc_page();
ffffffffc0203c8a:	4505                	li	a0,1
ffffffffc0203c8c:	984fe0ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc0203c90:	89aa                	mv	s3,a0
            if (npage == NULL)
ffffffffc0203c92:	c561                	beqz	a0,ffffffffc0203d5a <do_pgfault+0x17a>
    return page - pages + nbase;
ffffffffc0203c94:	000bb683          	ld	a3,0(s7)
    return KADDR(page2pa(page));
ffffffffc0203c98:	577d                	li	a4,-1
ffffffffc0203c9a:	000b3603          	ld	a2,0(s6)
    return page - pages + nbase;
ffffffffc0203c9e:	40d507b3          	sub	a5,a0,a3
ffffffffc0203ca2:	8799                	srai	a5,a5,0x6
ffffffffc0203ca4:	97d6                	add	a5,a5,s5
    return KADDR(page2pa(page));
ffffffffc0203ca6:	8331                	srli	a4,a4,0xc
ffffffffc0203ca8:	00e7f5b3          	and	a1,a5,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0203cac:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203cae:	0cc5f663          	bgeu	a1,a2,ffffffffc0203d7a <do_pgfault+0x19a>
    return page - pages + nbase;
ffffffffc0203cb2:	40d906b3          	sub	a3,s2,a3
ffffffffc0203cb6:	8699                	srai	a3,a3,0x6
ffffffffc0203cb8:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc0203cba:	000ce597          	auipc	a1,0xce
ffffffffc0203cbe:	fae5b583          	ld	a1,-82(a1) # ffffffffc02d1c68 <va_pa_offset>
ffffffffc0203cc2:	8f75                	and	a4,a4,a3
ffffffffc0203cc4:	00b78533          	add	a0,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0203cc8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203cca:	0cc77563          	bgeu	a4,a2,ffffffffc0203d94 <do_pgfault+0x1b4>
            {
                return -E_NO_MEM;
            }
            memcpy(page2kva(npage), page2kva(page), PGSIZE);
ffffffffc0203cce:	95b6                	add	a1,a1,a3
ffffffffc0203cd0:	6605                	lui	a2,0x1
ffffffffc0203cd2:	0f6020ef          	jal	ra,ffffffffc0205dc8 <memcpy>
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203cd6:	8622                	mv	a2,s0
        tlb_invalidate(mm->pgdir, la);
        return 0;
    }

    return -E_INVAL;
}
ffffffffc0203cd8:	6406                	ld	s0,64(sp)
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203cda:	6c88                	ld	a0,24(s1)
}
ffffffffc0203cdc:	60a6                	ld	ra,72(sp)
ffffffffc0203cde:	74e2                	ld	s1,56(sp)
ffffffffc0203ce0:	7942                	ld	s2,48(sp)
ffffffffc0203ce2:	6ae2                	ld	s5,24(sp)
ffffffffc0203ce4:	6b42                	ld	s6,16(sp)
ffffffffc0203ce6:	6ba2                	ld	s7,8(sp)
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203ce8:	01ba7693          	andi	a3,s4,27
ffffffffc0203cec:	85ce                	mv	a1,s3
}
ffffffffc0203cee:	7a02                	ld	s4,32(sp)
ffffffffc0203cf0:	79a2                	ld	s3,40(sp)
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203cf2:	0046e693          	ori	a3,a3,4
}
ffffffffc0203cf6:	6161                	addi	sp,sp,80
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203cf8:	8c1fe06f          	j	ffffffffc02025b8 <page_insert>
        uint32_t perm = perm_from_flags(vma->vm_flags);
ffffffffc0203cfc:	01892783          	lw	a5,24(s2)
    uint32_t perm = PTE_U;
ffffffffc0203d00:	4641                	li	a2,16
    if (vm_flags & VM_READ)
ffffffffc0203d02:	0017f713          	andi	a4,a5,1
ffffffffc0203d06:	c311                	beqz	a4,ffffffffc0203d0a <do_pgfault+0x12a>
        perm |= PTE_R;
ffffffffc0203d08:	4649                	li	a2,18
    if (vm_flags & VM_WRITE)
ffffffffc0203d0a:	0027f713          	andi	a4,a5,2
ffffffffc0203d0e:	c311                	beqz	a4,ffffffffc0203d12 <do_pgfault+0x132>
        perm |= PTE_W | PTE_R;
ffffffffc0203d10:	4659                	li	a2,22
    if (vm_flags & VM_EXEC)
ffffffffc0203d12:	8b91                	andi	a5,a5,4
ffffffffc0203d14:	e39d                	bnez	a5,ffffffffc0203d3a <do_pgfault+0x15a>
        if (pgdir_alloc_page(mm->pgdir, la, perm) == NULL)
ffffffffc0203d16:	6c88                	ld	a0,24(s1)
ffffffffc0203d18:	85a2                	mv	a1,s0
ffffffffc0203d1a:	f6aff0ef          	jal	ra,ffffffffc0203484 <pgdir_alloc_page>
ffffffffc0203d1e:	87aa                	mv	a5,a0
        return 0;
ffffffffc0203d20:	4501                	li	a0,0
        if (pgdir_alloc_page(mm->pgdir, la, perm) == NULL)
ffffffffc0203d22:	cf85                	beqz	a5,ffffffffc0203d5a <do_pgfault+0x17a>
}
ffffffffc0203d24:	60a6                	ld	ra,72(sp)
ffffffffc0203d26:	6406                	ld	s0,64(sp)
ffffffffc0203d28:	74e2                	ld	s1,56(sp)
ffffffffc0203d2a:	7942                	ld	s2,48(sp)
ffffffffc0203d2c:	79a2                	ld	s3,40(sp)
ffffffffc0203d2e:	7a02                	ld	s4,32(sp)
ffffffffc0203d30:	6ae2                	ld	s5,24(sp)
ffffffffc0203d32:	6b42                	ld	s6,16(sp)
ffffffffc0203d34:	6ba2                	ld	s7,8(sp)
ffffffffc0203d36:	6161                	addi	sp,sp,80
ffffffffc0203d38:	8082                	ret
        perm |= PTE_X;
ffffffffc0203d3a:	00866613          	ori	a2,a2,8
ffffffffc0203d3e:	bfe1                	j	ffffffffc0203d16 <do_pgfault+0x136>
        tlb_invalidate(mm->pgdir, la);
ffffffffc0203d40:	6c88                	ld	a0,24(s1)
        *ptep = (*ptep | PTE_W) & ~PTE_COW;
ffffffffc0203d42:	efba7713          	andi	a4,s4,-261
ffffffffc0203d46:	00476713          	ori	a4,a4,4
ffffffffc0203d4a:	e398                	sd	a4,0(a5)
        tlb_invalidate(mm->pgdir, la);
ffffffffc0203d4c:	85a2                	mv	a1,s0
ffffffffc0203d4e:	f30ff0ef          	jal	ra,ffffffffc020347e <tlb_invalidate>
        return 0;
ffffffffc0203d52:	4501                	li	a0,0
ffffffffc0203d54:	bfc1                	j	ffffffffc0203d24 <do_pgfault+0x144>
        return -E_INVAL;
ffffffffc0203d56:	5575                	li	a0,-3
ffffffffc0203d58:	b7f1                	j	ffffffffc0203d24 <do_pgfault+0x144>
            return -E_NO_MEM;
ffffffffc0203d5a:	5571                	li	a0,-4
ffffffffc0203d5c:	b7e1                	j	ffffffffc0203d24 <do_pgfault+0x144>
        return -E_INVAL;
ffffffffc0203d5e:	5575                	li	a0,-3
}
ffffffffc0203d60:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0203d62:	00003617          	auipc	a2,0x3
ffffffffc0203d66:	fd660613          	addi	a2,a2,-42 # ffffffffc0206d38 <default_pmm_manager+0x108>
ffffffffc0203d6a:	06900593          	li	a1,105
ffffffffc0203d6e:	00003517          	auipc	a0,0x3
ffffffffc0203d72:	f2250513          	addi	a0,a0,-222 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc0203d76:	f1cfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203d7a:	86be                	mv	a3,a5
ffffffffc0203d7c:	00003617          	auipc	a2,0x3
ffffffffc0203d80:	eec60613          	addi	a2,a2,-276 # ffffffffc0206c68 <default_pmm_manager+0x38>
ffffffffc0203d84:	07100593          	li	a1,113
ffffffffc0203d88:	00003517          	auipc	a0,0x3
ffffffffc0203d8c:	f0850513          	addi	a0,a0,-248 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc0203d90:	f02fc0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0203d94:	00003617          	auipc	a2,0x3
ffffffffc0203d98:	ed460613          	addi	a2,a2,-300 # ffffffffc0206c68 <default_pmm_manager+0x38>
ffffffffc0203d9c:	07100593          	li	a1,113
ffffffffc0203da0:	00003517          	auipc	a0,0x3
ffffffffc0203da4:	ef050513          	addi	a0,a0,-272 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc0203da8:	eeafc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203dac <user_mem_check>:
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203dac:	7179                	addi	sp,sp,-48
ffffffffc0203dae:	f022                	sd	s0,32(sp)
ffffffffc0203db0:	f406                	sd	ra,40(sp)
ffffffffc0203db2:	ec26                	sd	s1,24(sp)
ffffffffc0203db4:	e84a                	sd	s2,16(sp)
ffffffffc0203db6:	e44e                	sd	s3,8(sp)
ffffffffc0203db8:	e052                	sd	s4,0(sp)
ffffffffc0203dba:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203dbc:	c135                	beqz	a0,ffffffffc0203e20 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203dbe:	002007b7          	lui	a5,0x200
ffffffffc0203dc2:	04f5e663          	bltu	a1,a5,ffffffffc0203e0e <user_mem_check+0x62>
ffffffffc0203dc6:	00c584b3          	add	s1,a1,a2
ffffffffc0203dca:	0495f263          	bgeu	a1,s1,ffffffffc0203e0e <user_mem_check+0x62>
ffffffffc0203dce:	4785                	li	a5,1
ffffffffc0203dd0:	07fe                	slli	a5,a5,0x1f
ffffffffc0203dd2:	0297ee63          	bltu	a5,s1,ffffffffc0203e0e <user_mem_check+0x62>
ffffffffc0203dd6:	892a                	mv	s2,a0
ffffffffc0203dd8:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203dda:	6a05                	lui	s4,0x1
ffffffffc0203ddc:	a821                	j	ffffffffc0203df4 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203dde:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203de2:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203de4:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203de6:	c685                	beqz	a3,ffffffffc0203e0e <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203de8:	c399                	beqz	a5,ffffffffc0203dee <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203dea:	02e46263          	bltu	s0,a4,ffffffffc0203e0e <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203dee:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203df0:	04947663          	bgeu	s0,s1,ffffffffc0203e3c <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203df4:	85a2                	mv	a1,s0
ffffffffc0203df6:	854a                	mv	a0,s2
ffffffffc0203df8:	fa2ff0ef          	jal	ra,ffffffffc020359a <find_vma>
ffffffffc0203dfc:	c909                	beqz	a0,ffffffffc0203e0e <user_mem_check+0x62>
ffffffffc0203dfe:	6518                	ld	a4,8(a0)
ffffffffc0203e00:	00e46763          	bltu	s0,a4,ffffffffc0203e0e <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e04:	4d1c                	lw	a5,24(a0)
ffffffffc0203e06:	fc099ce3          	bnez	s3,ffffffffc0203dde <user_mem_check+0x32>
ffffffffc0203e0a:	8b85                	andi	a5,a5,1
ffffffffc0203e0c:	f3ed                	bnez	a5,ffffffffc0203dee <user_mem_check+0x42>
            return 0;
ffffffffc0203e0e:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203e10:	70a2                	ld	ra,40(sp)
ffffffffc0203e12:	7402                	ld	s0,32(sp)
ffffffffc0203e14:	64e2                	ld	s1,24(sp)
ffffffffc0203e16:	6942                	ld	s2,16(sp)
ffffffffc0203e18:	69a2                	ld	s3,8(sp)
ffffffffc0203e1a:	6a02                	ld	s4,0(sp)
ffffffffc0203e1c:	6145                	addi	sp,sp,48
ffffffffc0203e1e:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e20:	c02007b7          	lui	a5,0xc0200
ffffffffc0203e24:	4501                	li	a0,0
ffffffffc0203e26:	fef5e5e3          	bltu	a1,a5,ffffffffc0203e10 <user_mem_check+0x64>
ffffffffc0203e2a:	962e                	add	a2,a2,a1
ffffffffc0203e2c:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203e10 <user_mem_check+0x64>
ffffffffc0203e30:	c8000537          	lui	a0,0xc8000
ffffffffc0203e34:	0505                	addi	a0,a0,1
ffffffffc0203e36:	00a63533          	sltu	a0,a2,a0
ffffffffc0203e3a:	bfd9                	j	ffffffffc0203e10 <user_mem_check+0x64>
        return 1;
ffffffffc0203e3c:	4505                	li	a0,1
ffffffffc0203e3e:	bfc9                	j	ffffffffc0203e10 <user_mem_check+0x64>

ffffffffc0203e40 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203e40:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203e42:	9402                	jalr	s0

	jal do_exit
ffffffffc0203e44:	5e4000ef          	jal	ra,ffffffffc0204428 <do_exit>

ffffffffc0203e48 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203e48:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e4a:	14800513          	li	a0,328
{
ffffffffc0203e4e:	e022                	sd	s0,0(sp)
ffffffffc0203e50:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e52:	de1fd0ef          	jal	ra,ffffffffc0201c32 <kmalloc>
ffffffffc0203e56:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203e58:	cd49                	beqz	a0,ffffffffc0203ef2 <alloc_proc+0xaa>
    {
        memset(proc, 0, sizeof(struct proc_struct));
ffffffffc0203e5a:	14800613          	li	a2,328
ffffffffc0203e5e:	4581                	li	a1,0
ffffffffc0203e60:	757010ef          	jal	ra,ffffffffc0205db6 <memset>
        proc->state = PROC_UNINIT;
ffffffffc0203e64:	57fd                	li	a5,-1
ffffffffc0203e66:	1782                	slli	a5,a5,0x20
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&proc->context, 0, sizeof(proc->context));
ffffffffc0203e68:	07000613          	li	a2,112
ffffffffc0203e6c:	4581                	li	a1,0
        proc->state = PROC_UNINIT;
ffffffffc0203e6e:	e01c                	sd	a5,0(s0)
        proc->runs = 0;
ffffffffc0203e70:	00042423          	sw	zero,8(s0)
        proc->kstack = 0;
ffffffffc0203e74:	00043823          	sd	zero,16(s0)
        proc->need_resched = 0;
ffffffffc0203e78:	00043c23          	sd	zero,24(s0)
        proc->parent = NULL;
ffffffffc0203e7c:	02043023          	sd	zero,32(s0)
        proc->mm = NULL;
ffffffffc0203e80:	02043423          	sd	zero,40(s0)
        memset(&proc->context, 0, sizeof(proc->context));
ffffffffc0203e84:	03040513          	addi	a0,s0,48
ffffffffc0203e88:	72f010ef          	jal	ra,ffffffffc0205db6 <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203e8c:	000ce797          	auipc	a5,0xce
ffffffffc0203e90:	db47b783          	ld	a5,-588(a5) # ffffffffc02d1c40 <boot_pgdir_pa>
ffffffffc0203e94:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;
ffffffffc0203e96:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc0203e9a:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203e9e:	4641                	li	a2,16
ffffffffc0203ea0:	4581                	li	a1,0
ffffffffc0203ea2:	0b440513          	addi	a0,s0,180
ffffffffc0203ea6:	711010ef          	jal	ra,ffffffffc0205db6 <memset>

        proc->wait_state = 0;
        proc->cptr = proc->yptr = proc->optr = NULL;

        proc->rq = NULL;
        list_init(&(proc->run_link));
ffffffffc0203eaa:	11040793          	addi	a5,s0,272
    elm->prev = elm->next = elm;
ffffffffc0203eae:	10f43c23          	sd	a5,280(s0)
ffffffffc0203eb2:	10f43823          	sd	a5,272(s0)
        proc->time_slice = 0;
        skew_heap_init(&(proc->lab6_run_pool));
        proc->lab6_stride = 0;
ffffffffc0203eb6:	4785                	li	a5,1
        list_init(&proc->list_link);
ffffffffc0203eb8:	0c840693          	addi	a3,s0,200
        list_init(&proc->hash_link);
ffffffffc0203ebc:	0d840713          	addi	a4,s0,216
        proc->lab6_stride = 0;
ffffffffc0203ec0:	1782                	slli	a5,a5,0x20
ffffffffc0203ec2:	e874                	sd	a3,208(s0)
ffffffffc0203ec4:	e474                	sd	a3,200(s0)
ffffffffc0203ec6:	f078                	sd	a4,224(s0)
ffffffffc0203ec8:	ec78                	sd	a4,216(s0)
        proc->wait_state = 0;
ffffffffc0203eca:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc0203ece:	10043023          	sd	zero,256(s0)
ffffffffc0203ed2:	0e043c23          	sd	zero,248(s0)
ffffffffc0203ed6:	0e043823          	sd	zero,240(s0)
        proc->rq = NULL;
ffffffffc0203eda:	10043423          	sd	zero,264(s0)
        proc->time_slice = 0;
ffffffffc0203ede:	12042023          	sw	zero,288(s0)
     compare_f comp) __attribute__((always_inline));

static inline void
skew_heap_init(skew_heap_entry_t *a)
{
     a->left = a->right = a->parent = NULL;
ffffffffc0203ee2:	12043423          	sd	zero,296(s0)
ffffffffc0203ee6:	12043823          	sd	zero,304(s0)
ffffffffc0203eea:	12043c23          	sd	zero,312(s0)
        proc->lab6_stride = 0;
ffffffffc0203eee:	14f43023          	sd	a5,320(s0)
        proc->lab6_priority = 1;
    }
    return proc;
}
ffffffffc0203ef2:	60a2                	ld	ra,8(sp)
ffffffffc0203ef4:	8522                	mv	a0,s0
ffffffffc0203ef6:	6402                	ld	s0,0(sp)
ffffffffc0203ef8:	0141                	addi	sp,sp,16
ffffffffc0203efa:	8082                	ret

ffffffffc0203efc <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203efc:	000ce797          	auipc	a5,0xce
ffffffffc0203f00:	d7c7b783          	ld	a5,-644(a5) # ffffffffc02d1c78 <current>
ffffffffc0203f04:	73c8                	ld	a0,160(a5)
ffffffffc0203f06:	848fd06f          	j	ffffffffc0200f4e <forkrets>

ffffffffc0203f0a <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203f0a:	6d14                	ld	a3,24(a0)
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm)
{
ffffffffc0203f0c:	1141                	addi	sp,sp,-16
ffffffffc0203f0e:	e406                	sd	ra,8(sp)
ffffffffc0203f10:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f14:	02f6ee63          	bltu	a3,a5,ffffffffc0203f50 <put_pgdir+0x46>
ffffffffc0203f18:	000ce517          	auipc	a0,0xce
ffffffffc0203f1c:	d5053503          	ld	a0,-688(a0) # ffffffffc02d1c68 <va_pa_offset>
ffffffffc0203f20:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0203f22:	82b1                	srli	a3,a3,0xc
ffffffffc0203f24:	000ce797          	auipc	a5,0xce
ffffffffc0203f28:	d2c7b783          	ld	a5,-724(a5) # ffffffffc02d1c50 <npage>
ffffffffc0203f2c:	02f6fe63          	bgeu	a3,a5,ffffffffc0203f68 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203f30:	00004517          	auipc	a0,0x4
ffffffffc0203f34:	72053503          	ld	a0,1824(a0) # ffffffffc0208650 <nbase>
    free_page(kva2page(mm->pgdir));
}
ffffffffc0203f38:	60a2                	ld	ra,8(sp)
ffffffffc0203f3a:	8e89                	sub	a3,a3,a0
ffffffffc0203f3c:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203f3e:	000ce517          	auipc	a0,0xce
ffffffffc0203f42:	d1a53503          	ld	a0,-742(a0) # ffffffffc02d1c58 <pages>
ffffffffc0203f46:	4585                	li	a1,1
ffffffffc0203f48:	9536                	add	a0,a0,a3
}
ffffffffc0203f4a:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203f4c:	f03fd06f          	j	ffffffffc0201e4e <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203f50:	00003617          	auipc	a2,0x3
ffffffffc0203f54:	dc060613          	addi	a2,a2,-576 # ffffffffc0206d10 <default_pmm_manager+0xe0>
ffffffffc0203f58:	07700593          	li	a1,119
ffffffffc0203f5c:	00003517          	auipc	a0,0x3
ffffffffc0203f60:	d3450513          	addi	a0,a0,-716 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc0203f64:	d2efc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203f68:	00003617          	auipc	a2,0x3
ffffffffc0203f6c:	dd060613          	addi	a2,a2,-560 # ffffffffc0206d38 <default_pmm_manager+0x108>
ffffffffc0203f70:	06900593          	li	a1,105
ffffffffc0203f74:	00003517          	auipc	a0,0x3
ffffffffc0203f78:	d1c50513          	addi	a0,a0,-740 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc0203f7c:	d16fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203f80 <proc_run>:
{
ffffffffc0203f80:	7179                	addi	sp,sp,-48
ffffffffc0203f82:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203f84:	000ce497          	auipc	s1,0xce
ffffffffc0203f88:	cf448493          	addi	s1,s1,-780 # ffffffffc02d1c78 <current>
ffffffffc0203f8c:	6098                	ld	a4,0(s1)
{
ffffffffc0203f8e:	f406                	sd	ra,40(sp)
ffffffffc0203f90:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203f92:	02a70763          	beq	a4,a0,ffffffffc0203fc0 <proc_run+0x40>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f96:	100027f3          	csrr	a5,sstatus
ffffffffc0203f9a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203f9c:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f9e:	ef85                	bnez	a5,ffffffffc0203fd6 <proc_run+0x56>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203fa0:	755c                	ld	a5,168(a0)
ffffffffc0203fa2:	56fd                	li	a3,-1
ffffffffc0203fa4:	16fe                	slli	a3,a3,0x3f
ffffffffc0203fa6:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0203fa8:	e088                	sd	a0,0(s1)
ffffffffc0203faa:	8fd5                	or	a5,a5,a3
ffffffffc0203fac:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(proc->context));
ffffffffc0203fb0:	03050593          	addi	a1,a0,48
ffffffffc0203fb4:	03070513          	addi	a0,a4,48
ffffffffc0203fb8:	110010ef          	jal	ra,ffffffffc02050c8 <switch_to>
    if (flag)
ffffffffc0203fbc:	00091763          	bnez	s2,ffffffffc0203fca <proc_run+0x4a>
}
ffffffffc0203fc0:	70a2                	ld	ra,40(sp)
ffffffffc0203fc2:	7482                	ld	s1,32(sp)
ffffffffc0203fc4:	6962                	ld	s2,24(sp)
ffffffffc0203fc6:	6145                	addi	sp,sp,48
ffffffffc0203fc8:	8082                	ret
ffffffffc0203fca:	70a2                	ld	ra,40(sp)
ffffffffc0203fcc:	7482                	ld	s1,32(sp)
ffffffffc0203fce:	6962                	ld	s2,24(sp)
ffffffffc0203fd0:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203fd2:	9d7fc06f          	j	ffffffffc02009a8 <intr_enable>
ffffffffc0203fd6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203fd8:	9d7fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
            struct proc_struct *prev = current;
ffffffffc0203fdc:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0203fde:	6522                	ld	a0,8(sp)
ffffffffc0203fe0:	4905                	li	s2,1
ffffffffc0203fe2:	bf7d                	j	ffffffffc0203fa0 <proc_run+0x20>

ffffffffc0203fe4 <do_fork>:
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
ffffffffc0203fe4:	7119                	addi	sp,sp,-128
ffffffffc0203fe6:	f0ca                	sd	s2,96(sp)
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
ffffffffc0203fe8:	000ce917          	auipc	s2,0xce
ffffffffc0203fec:	ca890913          	addi	s2,s2,-856 # ffffffffc02d1c90 <nr_process>
ffffffffc0203ff0:	00092703          	lw	a4,0(s2)
{
ffffffffc0203ff4:	fc86                	sd	ra,120(sp)
ffffffffc0203ff6:	f8a2                	sd	s0,112(sp)
ffffffffc0203ff8:	f4a6                	sd	s1,104(sp)
ffffffffc0203ffa:	ecce                	sd	s3,88(sp)
ffffffffc0203ffc:	e8d2                	sd	s4,80(sp)
ffffffffc0203ffe:	e4d6                	sd	s5,72(sp)
ffffffffc0204000:	e0da                	sd	s6,64(sp)
ffffffffc0204002:	fc5e                	sd	s7,56(sp)
ffffffffc0204004:	f862                	sd	s8,48(sp)
ffffffffc0204006:	f466                	sd	s9,40(sp)
ffffffffc0204008:	f06a                	sd	s10,32(sp)
ffffffffc020400a:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020400c:	6785                	lui	a5,0x1
ffffffffc020400e:	34f75363          	bge	a4,a5,ffffffffc0204354 <do_fork+0x370>
ffffffffc0204012:	8a2a                	mv	s4,a0
ffffffffc0204014:	89ae                	mv	s3,a1
ffffffffc0204016:	8432                	mv	s0,a2
     *    -------------------
     *    update step 1: set child proc's parent to current process, make sure current process's wait_state is 0
     *    update step 5: insert proc_struct into hash_list && proc_list, set the relation links of process
     */

    proc = alloc_proc();
ffffffffc0204018:	e31ff0ef          	jal	ra,ffffffffc0203e48 <alloc_proc>
ffffffffc020401c:	84aa                	mv	s1,a0

    if(proc == NULL)
ffffffffc020401e:	32050463          	beqz	a0,ffffffffc0204346 <do_fork+0x362>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204022:	4509                	li	a0,2
ffffffffc0204024:	dedfd0ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
    if (page != NULL)
ffffffffc0204028:	30050c63          	beqz	a0,ffffffffc0204340 <do_fork+0x35c>
    return page - pages + nbase;
ffffffffc020402c:	000ceb17          	auipc	s6,0xce
ffffffffc0204030:	c2cb0b13          	addi	s6,s6,-980 # ffffffffc02d1c58 <pages>
ffffffffc0204034:	000b3683          	ld	a3,0(s6)
ffffffffc0204038:	00004797          	auipc	a5,0x4
ffffffffc020403c:	61878793          	addi	a5,a5,1560 # ffffffffc0208650 <nbase>
ffffffffc0204040:	6398                	ld	a4,0(a5)
ffffffffc0204042:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204046:	000cec17          	auipc	s8,0xce
ffffffffc020404a:	c0ac0c13          	addi	s8,s8,-1014 # ffffffffc02d1c50 <npage>
    return page - pages + nbase;
ffffffffc020404e:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204050:	57fd                	li	a5,-1
ffffffffc0204052:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204056:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0204058:	00c7db93          	srli	s7,a5,0xc
ffffffffc020405c:	0176f5b3          	and	a1,a3,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc0204060:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204062:	34c5ff63          	bgeu	a1,a2,ffffffffc02043c0 <do_fork+0x3dc>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204066:	000cea97          	auipc	s5,0xce
ffffffffc020406a:	c12a8a93          	addi	s5,s5,-1006 # ffffffffc02d1c78 <current>
ffffffffc020406e:	000ab583          	ld	a1,0(s5)
ffffffffc0204072:	000cec97          	auipc	s9,0xce
ffffffffc0204076:	bf6c8c93          	addi	s9,s9,-1034 # ffffffffc02d1c68 <va_pa_offset>
ffffffffc020407a:	000cb603          	ld	a2,0(s9)
ffffffffc020407e:	0285bd83          	ld	s11,40(a1)
ffffffffc0204082:	e43a                	sd	a4,8(sp)
ffffffffc0204084:	96b2                	add	a3,a3,a2
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204086:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc0204088:	020d8863          	beqz	s11,ffffffffc02040b8 <do_fork+0xd4>
    if (clone_flags & CLONE_VM)
ffffffffc020408c:	100a7a13          	andi	s4,s4,256
ffffffffc0204090:	1c0a0663          	beqz	s4,ffffffffc020425c <do_fork+0x278>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0204094:	030da703          	lw	a4,48(s11)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204098:	018db783          	ld	a5,24(s11)
ffffffffc020409c:	c02006b7          	lui	a3,0xc0200
ffffffffc02040a0:	2705                	addiw	a4,a4,1
ffffffffc02040a2:	02eda823          	sw	a4,48(s11)
    proc->mm = mm;
ffffffffc02040a6:	03b4b423          	sd	s11,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040aa:	2cd7e663          	bltu	a5,a3,ffffffffc0204376 <do_fork+0x392>
ffffffffc02040ae:	000cb703          	ld	a4,0(s9)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040b2:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040b4:	8f99                	sub	a5,a5,a4
ffffffffc02040b6:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040b8:	6789                	lui	a5,0x2
ffffffffc02040ba:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8060>
ffffffffc02040be:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc02040c0:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040c2:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc02040c4:	87b6                	mv	a5,a3
ffffffffc02040c6:	12040893          	addi	a7,s0,288
ffffffffc02040ca:	00063803          	ld	a6,0(a2)
ffffffffc02040ce:	6608                	ld	a0,8(a2)
ffffffffc02040d0:	6a0c                	ld	a1,16(a2)
ffffffffc02040d2:	6e18                	ld	a4,24(a2)
ffffffffc02040d4:	0107b023          	sd	a6,0(a5)
ffffffffc02040d8:	e788                	sd	a0,8(a5)
ffffffffc02040da:	eb8c                	sd	a1,16(a5)
ffffffffc02040dc:	ef98                	sd	a4,24(a5)
ffffffffc02040de:	02060613          	addi	a2,a2,32
ffffffffc02040e2:	02078793          	addi	a5,a5,32
ffffffffc02040e6:	ff1612e3          	bne	a2,a7,ffffffffc02040ca <do_fork+0xe6>
    proc->tf->gpr.a0 = 0;
ffffffffc02040ea:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02040ee:	14098463          	beqz	s3,ffffffffc0204236 <do_fork+0x252>
ffffffffc02040f2:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02040f6:	00000797          	auipc	a5,0x0
ffffffffc02040fa:	e0678793          	addi	a5,a5,-506 # ffffffffc0203efc <forkret>
ffffffffc02040fe:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204100:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204102:	100027f3          	csrr	a5,sstatus
ffffffffc0204106:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204108:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020410a:	14079563          	bnez	a5,ffffffffc0204254 <do_fork+0x270>
    if (++last_pid >= MAX_PID)
ffffffffc020410e:	000c9817          	auipc	a6,0xc9
ffffffffc0204112:	6aa80813          	addi	a6,a6,1706 # ffffffffc02cd7b8 <last_pid.1>

    bool intr_flag;
    local_intr_save(intr_flag);
    {
        // LAB5: set parent relation and reset parent's wait state
        proc->parent = current;
ffffffffc0204116:	000ab703          	ld	a4,0(s5)
    if (++last_pid >= MAX_PID)
ffffffffc020411a:	00082783          	lw	a5,0(a6)
ffffffffc020411e:	6689                	lui	a3,0x2
        proc->parent = current;
ffffffffc0204120:	f098                	sd	a4,32(s1)
    if (++last_pid >= MAX_PID)
ffffffffc0204122:	0017851b          	addiw	a0,a5,1
        current->wait_state = 0;
ffffffffc0204126:	0e072623          	sw	zero,236(a4)
    if (++last_pid >= MAX_PID)
ffffffffc020412a:	00a82023          	sw	a0,0(a6)
ffffffffc020412e:	08d55d63          	bge	a0,a3,ffffffffc02041c8 <do_fork+0x1e4>
    if (last_pid >= next_safe)
ffffffffc0204132:	000c9317          	auipc	t1,0xc9
ffffffffc0204136:	68a30313          	addi	t1,t1,1674 # ffffffffc02cd7bc <next_safe.0>
ffffffffc020413a:	00032783          	lw	a5,0(t1)
ffffffffc020413e:	000ce417          	auipc	s0,0xce
ffffffffc0204142:	a9a40413          	addi	s0,s0,-1382 # ffffffffc02d1bd8 <proc_list>
ffffffffc0204146:	08f55963          	bge	a0,a5,ffffffffc02041d8 <do_fork+0x1f4>

        proc->pid = get_pid();
ffffffffc020414a:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020414c:	45a9                	li	a1,10
ffffffffc020414e:	2501                	sext.w	a0,a0
ffffffffc0204150:	7c0010ef          	jal	ra,ffffffffc0205910 <hash32>
ffffffffc0204154:	02051793          	slli	a5,a0,0x20
ffffffffc0204158:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020415c:	000ca797          	auipc	a5,0xca
ffffffffc0204160:	a7c78793          	addi	a5,a5,-1412 # ffffffffc02cdbd8 <hash_list>
ffffffffc0204164:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204166:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204168:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020416a:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc020416e:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204170:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0204172:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204174:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204176:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc020417a:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc020417c:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc020417e:	e21c                	sd	a5,0(a2)
ffffffffc0204180:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0204182:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0204184:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0204186:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020418a:	10e4b023          	sd	a4,256(s1)
ffffffffc020418e:	c311                	beqz	a4,ffffffffc0204192 <do_fork+0x1ae>
        proc->optr->yptr = proc;
ffffffffc0204190:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc0204192:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0204196:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc0204198:	2785                	addiw	a5,a5,1
ffffffffc020419a:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc020419e:	14099b63          	bnez	s3,ffffffffc02042f4 <do_fork+0x310>
        // Insert into global lists and parent/child links
        set_links(proc);
    }
    local_intr_restore(intr_flag);

    wakeup_proc(proc);
ffffffffc02041a2:	8526                	mv	a0,s1
ffffffffc02041a4:	4fa010ef          	jal	ra,ffffffffc020569e <wakeup_proc>
    ret = proc->pid;
ffffffffc02041a8:	40c8                	lw	a0,4(s1)
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
ffffffffc02041aa:	70e6                	ld	ra,120(sp)
ffffffffc02041ac:	7446                	ld	s0,112(sp)
ffffffffc02041ae:	74a6                	ld	s1,104(sp)
ffffffffc02041b0:	7906                	ld	s2,96(sp)
ffffffffc02041b2:	69e6                	ld	s3,88(sp)
ffffffffc02041b4:	6a46                	ld	s4,80(sp)
ffffffffc02041b6:	6aa6                	ld	s5,72(sp)
ffffffffc02041b8:	6b06                	ld	s6,64(sp)
ffffffffc02041ba:	7be2                	ld	s7,56(sp)
ffffffffc02041bc:	7c42                	ld	s8,48(sp)
ffffffffc02041be:	7ca2                	ld	s9,40(sp)
ffffffffc02041c0:	7d02                	ld	s10,32(sp)
ffffffffc02041c2:	6de2                	ld	s11,24(sp)
ffffffffc02041c4:	6109                	addi	sp,sp,128
ffffffffc02041c6:	8082                	ret
        last_pid = 1;
ffffffffc02041c8:	4785                	li	a5,1
ffffffffc02041ca:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02041ce:	4505                	li	a0,1
ffffffffc02041d0:	000c9317          	auipc	t1,0xc9
ffffffffc02041d4:	5ec30313          	addi	t1,t1,1516 # ffffffffc02cd7bc <next_safe.0>
    return listelm->next;
ffffffffc02041d8:	000ce417          	auipc	s0,0xce
ffffffffc02041dc:	a0040413          	addi	s0,s0,-1536 # ffffffffc02d1bd8 <proc_list>
ffffffffc02041e0:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc02041e4:	6789                	lui	a5,0x2
ffffffffc02041e6:	00f32023          	sw	a5,0(t1)
ffffffffc02041ea:	86aa                	mv	a3,a0
ffffffffc02041ec:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02041ee:	6e89                	lui	t4,0x2
ffffffffc02041f0:	148e0d63          	beq	t3,s0,ffffffffc020434a <do_fork+0x366>
ffffffffc02041f4:	88ae                	mv	a7,a1
ffffffffc02041f6:	87f2                	mv	a5,t3
ffffffffc02041f8:	6609                	lui	a2,0x2
ffffffffc02041fa:	a811                	j	ffffffffc020420e <do_fork+0x22a>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041fc:	00e6d663          	bge	a3,a4,ffffffffc0204208 <do_fork+0x224>
ffffffffc0204200:	00c75463          	bge	a4,a2,ffffffffc0204208 <do_fork+0x224>
ffffffffc0204204:	863a                	mv	a2,a4
ffffffffc0204206:	4885                	li	a7,1
ffffffffc0204208:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020420a:	00878d63          	beq	a5,s0,ffffffffc0204224 <do_fork+0x240>
            if (proc->pid == last_pid)
ffffffffc020420e:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x8004>
ffffffffc0204212:	fed715e3          	bne	a4,a3,ffffffffc02041fc <do_fork+0x218>
                if (++last_pid >= next_safe)
ffffffffc0204216:	2685                	addiw	a3,a3,1
ffffffffc0204218:	0ec6d163          	bge	a3,a2,ffffffffc02042fa <do_fork+0x316>
ffffffffc020421c:	679c                	ld	a5,8(a5)
ffffffffc020421e:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204220:	fe8797e3          	bne	a5,s0,ffffffffc020420e <do_fork+0x22a>
ffffffffc0204224:	c581                	beqz	a1,ffffffffc020422c <do_fork+0x248>
ffffffffc0204226:	00d82023          	sw	a3,0(a6)
ffffffffc020422a:	8536                	mv	a0,a3
ffffffffc020422c:	f0088fe3          	beqz	a7,ffffffffc020414a <do_fork+0x166>
ffffffffc0204230:	00c32023          	sw	a2,0(t1)
ffffffffc0204234:	bf19                	j	ffffffffc020414a <do_fork+0x166>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204236:	89b6                	mv	s3,a3
ffffffffc0204238:	0136b823          	sd	s3,16(a3) # 2010 <_binary_obj___user_faultread_out_size-0x7f30>
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020423c:	00000797          	auipc	a5,0x0
ffffffffc0204240:	cc078793          	addi	a5,a5,-832 # ffffffffc0203efc <forkret>
ffffffffc0204244:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204246:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204248:	100027f3          	csrr	a5,sstatus
ffffffffc020424c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020424e:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204250:	ea078fe3          	beqz	a5,ffffffffc020410e <do_fork+0x12a>
        intr_disable();
ffffffffc0204254:	f5afc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0204258:	4985                	li	s3,1
ffffffffc020425a:	bd55                	j	ffffffffc020410e <do_fork+0x12a>
    if ((mm = mm_create()) == NULL)
ffffffffc020425c:	b0eff0ef          	jal	ra,ffffffffc020356a <mm_create>
ffffffffc0204260:	8d2a                	mv	s10,a0
ffffffffc0204262:	c545                	beqz	a0,ffffffffc020430a <do_fork+0x326>
    if ((page = alloc_page()) == NULL)
ffffffffc0204264:	4505                	li	a0,1
ffffffffc0204266:	babfd0ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc020426a:	cd49                	beqz	a0,ffffffffc0204304 <do_fork+0x320>
    return page - pages + nbase;
ffffffffc020426c:	000b3683          	ld	a3,0(s6)
ffffffffc0204270:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc0204272:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204276:	40d506b3          	sub	a3,a0,a3
ffffffffc020427a:	8699                	srai	a3,a3,0x6
ffffffffc020427c:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc020427e:	0176f7b3          	and	a5,a3,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc0204282:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204284:	12c7fe63          	bgeu	a5,a2,ffffffffc02043c0 <do_fork+0x3dc>
ffffffffc0204288:	000cba03          	ld	s4,0(s9)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020428c:	6605                	lui	a2,0x1
ffffffffc020428e:	000ce597          	auipc	a1,0xce
ffffffffc0204292:	9ba5b583          	ld	a1,-1606(a1) # ffffffffc02d1c48 <boot_pgdir_va>
ffffffffc0204296:	9a36                	add	s4,s4,a3
ffffffffc0204298:	8552                	mv	a0,s4
ffffffffc020429a:	32f010ef          	jal	ra,ffffffffc0205dc8 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc020429e:	038d8b93          	addi	s7,s11,56
    mm->pgdir = pgdir;
ffffffffc02042a2:	014d3c23          	sd	s4,24(s10) # 200018 <_binary_obj___user_matrix_out_size+0x1f3908>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02042a6:	4785                	li	a5,1
ffffffffc02042a8:	40fbb7af          	amoor.d	a5,a5,(s7)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02042ac:	8b85                	andi	a5,a5,1
ffffffffc02042ae:	4a05                	li	s4,1
ffffffffc02042b0:	c799                	beqz	a5,ffffffffc02042be <do_fork+0x2da>
    {
        schedule();
ffffffffc02042b2:	49e010ef          	jal	ra,ffffffffc0205750 <schedule>
ffffffffc02042b6:	414bb7af          	amoor.d	a5,s4,(s7)
    while (!try_lock(lock))
ffffffffc02042ba:	8b85                	andi	a5,a5,1
ffffffffc02042bc:	fbfd                	bnez	a5,ffffffffc02042b2 <do_fork+0x2ce>
        ret = dup_mmap(mm, oldmm);
ffffffffc02042be:	85ee                	mv	a1,s11
ffffffffc02042c0:	856a                	mv	a0,s10
ffffffffc02042c2:	ceaff0ef          	jal	ra,ffffffffc02037ac <dup_mmap>
ffffffffc02042c6:	8a2a                	mv	s4,a0
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02042c8:	57f9                	li	a5,-2
ffffffffc02042ca:	60fbb7af          	amoand.d	a5,a5,(s7)
ffffffffc02042ce:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc02042d0:	0c078c63          	beqz	a5,ffffffffc02043a8 <do_fork+0x3c4>
good_mm:
ffffffffc02042d4:	8dea                	mv	s11,s10
    if (ret != 0)
ffffffffc02042d6:	da050fe3          	beqz	a0,ffffffffc0204094 <do_fork+0xb0>
    exit_mmap(mm);
ffffffffc02042da:	856a                	mv	a0,s10
ffffffffc02042dc:	d6aff0ef          	jal	ra,ffffffffc0203846 <exit_mmap>
    put_pgdir(mm);
ffffffffc02042e0:	856a                	mv	a0,s10
ffffffffc02042e2:	c29ff0ef          	jal	ra,ffffffffc0203f0a <put_pgdir>
    mm_destroy(mm);
ffffffffc02042e6:	856a                	mv	a0,s10
ffffffffc02042e8:	bc2ff0ef          	jal	ra,ffffffffc02036aa <mm_destroy>
    if(copy_mm(clone_flags, proc) < 0)
ffffffffc02042ec:	000a4f63          	bltz	s4,ffffffffc020430a <do_fork+0x326>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02042f0:	6894                	ld	a3,16(s1)
ffffffffc02042f2:	b3d9                	j	ffffffffc02040b8 <do_fork+0xd4>
        intr_enable();
ffffffffc02042f4:	eb4fc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02042f8:	b56d                	j	ffffffffc02041a2 <do_fork+0x1be>
                    if (last_pid >= MAX_PID)
ffffffffc02042fa:	01d6c363          	blt	a3,t4,ffffffffc0204300 <do_fork+0x31c>
                        last_pid = 1;
ffffffffc02042fe:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204300:	4585                	li	a1,1
ffffffffc0204302:	b5fd                	j	ffffffffc02041f0 <do_fork+0x20c>
    mm_destroy(mm);
ffffffffc0204304:	856a                	mv	a0,s10
ffffffffc0204306:	ba4ff0ef          	jal	ra,ffffffffc02036aa <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020430a:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc020430c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204310:	08f6e063          	bltu	a3,a5,ffffffffc0204390 <do_fork+0x3ac>
ffffffffc0204314:	000cb783          	ld	a5,0(s9)
    if (PPN(pa) >= npage)
ffffffffc0204318:	000c3703          	ld	a4,0(s8)
    return pa2page(PADDR(kva));
ffffffffc020431c:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204320:	83b1                	srli	a5,a5,0xc
ffffffffc0204322:	02e7fe63          	bgeu	a5,a4,ffffffffc020435e <do_fork+0x37a>
    return &pages[PPN(pa) - nbase];
ffffffffc0204326:	00004717          	auipc	a4,0x4
ffffffffc020432a:	32a70713          	addi	a4,a4,810 # ffffffffc0208650 <nbase>
ffffffffc020432e:	6318                	ld	a4,0(a4)
ffffffffc0204330:	000b3503          	ld	a0,0(s6)
ffffffffc0204334:	4589                	li	a1,2
ffffffffc0204336:	8f99                	sub	a5,a5,a4
ffffffffc0204338:	079a                	slli	a5,a5,0x6
ffffffffc020433a:	953e                	add	a0,a0,a5
ffffffffc020433c:	b13fd0ef          	jal	ra,ffffffffc0201e4e <free_pages>
    kfree(proc);
ffffffffc0204340:	8526                	mv	a0,s1
ffffffffc0204342:	9a1fd0ef          	jal	ra,ffffffffc0201ce2 <kfree>
    ret = -E_NO_MEM;
ffffffffc0204346:	5571                	li	a0,-4
    return ret;
ffffffffc0204348:	b58d                	j	ffffffffc02041aa <do_fork+0x1c6>
ffffffffc020434a:	c599                	beqz	a1,ffffffffc0204358 <do_fork+0x374>
ffffffffc020434c:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0204350:	8536                	mv	a0,a3
ffffffffc0204352:	bbe5                	j	ffffffffc020414a <do_fork+0x166>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204354:	556d                	li	a0,-5
ffffffffc0204356:	bd91                	j	ffffffffc02041aa <do_fork+0x1c6>
    return last_pid;
ffffffffc0204358:	00082503          	lw	a0,0(a6)
ffffffffc020435c:	b3fd                	j	ffffffffc020414a <do_fork+0x166>
        panic("pa2page called with invalid pa");
ffffffffc020435e:	00003617          	auipc	a2,0x3
ffffffffc0204362:	9da60613          	addi	a2,a2,-1574 # ffffffffc0206d38 <default_pmm_manager+0x108>
ffffffffc0204366:	06900593          	li	a1,105
ffffffffc020436a:	00003517          	auipc	a0,0x3
ffffffffc020436e:	92650513          	addi	a0,a0,-1754 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc0204372:	920fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204376:	86be                	mv	a3,a5
ffffffffc0204378:	00003617          	auipc	a2,0x3
ffffffffc020437c:	99860613          	addi	a2,a2,-1640 # ffffffffc0206d10 <default_pmm_manager+0xe0>
ffffffffc0204380:	17400593          	li	a1,372
ffffffffc0204384:	00003517          	auipc	a0,0x3
ffffffffc0204388:	2bc50513          	addi	a0,a0,700 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc020438c:	906fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204390:	00003617          	auipc	a2,0x3
ffffffffc0204394:	98060613          	addi	a2,a2,-1664 # ffffffffc0206d10 <default_pmm_manager+0xe0>
ffffffffc0204398:	07700593          	li	a1,119
ffffffffc020439c:	00003517          	auipc	a0,0x3
ffffffffc02043a0:	8f450513          	addi	a0,a0,-1804 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc02043a4:	8eefc0ef          	jal	ra,ffffffffc0200492 <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc02043a8:	00003617          	auipc	a2,0x3
ffffffffc02043ac:	27060613          	addi	a2,a2,624 # ffffffffc0207618 <default_pmm_manager+0x9e8>
ffffffffc02043b0:	04000593          	li	a1,64
ffffffffc02043b4:	00003517          	auipc	a0,0x3
ffffffffc02043b8:	27450513          	addi	a0,a0,628 # ffffffffc0207628 <default_pmm_manager+0x9f8>
ffffffffc02043bc:	8d6fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc02043c0:	00003617          	auipc	a2,0x3
ffffffffc02043c4:	8a860613          	addi	a2,a2,-1880 # ffffffffc0206c68 <default_pmm_manager+0x38>
ffffffffc02043c8:	07100593          	li	a1,113
ffffffffc02043cc:	00003517          	auipc	a0,0x3
ffffffffc02043d0:	8c450513          	addi	a0,a0,-1852 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc02043d4:	8befc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02043d8 <kernel_thread>:
{
ffffffffc02043d8:	7129                	addi	sp,sp,-320
ffffffffc02043da:	fa22                	sd	s0,304(sp)
ffffffffc02043dc:	f626                	sd	s1,296(sp)
ffffffffc02043de:	f24a                	sd	s2,288(sp)
ffffffffc02043e0:	84ae                	mv	s1,a1
ffffffffc02043e2:	892a                	mv	s2,a0
ffffffffc02043e4:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02043e6:	4581                	li	a1,0
ffffffffc02043e8:	12000613          	li	a2,288
ffffffffc02043ec:	850a                	mv	a0,sp
{
ffffffffc02043ee:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02043f0:	1c7010ef          	jal	ra,ffffffffc0205db6 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02043f4:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02043f6:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02043f8:	100027f3          	csrr	a5,sstatus
ffffffffc02043fc:	edd7f793          	andi	a5,a5,-291
ffffffffc0204400:	1207e793          	ori	a5,a5,288
ffffffffc0204404:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204406:	860a                	mv	a2,sp
ffffffffc0204408:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020440c:	00000797          	auipc	a5,0x0
ffffffffc0204410:	a3478793          	addi	a5,a5,-1484 # ffffffffc0203e40 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204414:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204416:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204418:	bcdff0ef          	jal	ra,ffffffffc0203fe4 <do_fork>
}
ffffffffc020441c:	70f2                	ld	ra,312(sp)
ffffffffc020441e:	7452                	ld	s0,304(sp)
ffffffffc0204420:	74b2                	ld	s1,296(sp)
ffffffffc0204422:	7912                	ld	s2,288(sp)
ffffffffc0204424:	6131                	addi	sp,sp,320
ffffffffc0204426:	8082                	ret

ffffffffc0204428 <do_exit>:
// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
ffffffffc0204428:	7179                	addi	sp,sp,-48
ffffffffc020442a:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc020442c:	000ce417          	auipc	s0,0xce
ffffffffc0204430:	84c40413          	addi	s0,s0,-1972 # ffffffffc02d1c78 <current>
ffffffffc0204434:	601c                	ld	a5,0(s0)
{
ffffffffc0204436:	f406                	sd	ra,40(sp)
ffffffffc0204438:	ec26                	sd	s1,24(sp)
ffffffffc020443a:	e84a                	sd	s2,16(sp)
ffffffffc020443c:	e44e                	sd	s3,8(sp)
ffffffffc020443e:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc0204440:	000ce717          	auipc	a4,0xce
ffffffffc0204444:	84073703          	ld	a4,-1984(a4) # ffffffffc02d1c80 <idleproc>
ffffffffc0204448:	0ce78c63          	beq	a5,a4,ffffffffc0204520 <do_exit+0xf8>
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
ffffffffc020444c:	000ce497          	auipc	s1,0xce
ffffffffc0204450:	83c48493          	addi	s1,s1,-1988 # ffffffffc02d1c88 <initproc>
ffffffffc0204454:	6098                	ld	a4,0(s1)
ffffffffc0204456:	0ee78b63          	beq	a5,a4,ffffffffc020454c <do_exit+0x124>
    {
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm;
ffffffffc020445a:	0287b983          	ld	s3,40(a5)
ffffffffc020445e:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc0204460:	02098663          	beqz	s3,ffffffffc020448c <do_exit+0x64>
ffffffffc0204464:	000cd797          	auipc	a5,0xcd
ffffffffc0204468:	7dc7b783          	ld	a5,2012(a5) # ffffffffc02d1c40 <boot_pgdir_pa>
ffffffffc020446c:	577d                	li	a4,-1
ffffffffc020446e:	177e                	slli	a4,a4,0x3f
ffffffffc0204470:	83b1                	srli	a5,a5,0xc
ffffffffc0204472:	8fd9                	or	a5,a5,a4
ffffffffc0204474:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204478:	0309a783          	lw	a5,48(s3)
ffffffffc020447c:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204480:	02e9a823          	sw	a4,48(s3)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
ffffffffc0204484:	cb55                	beqz	a4,ffffffffc0204538 <do_exit+0x110>
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
ffffffffc0204486:	601c                	ld	a5,0(s0)
ffffffffc0204488:	0207b423          	sd	zero,40(a5)
    }
    current->state = PROC_ZOMBIE;
ffffffffc020448c:	601c                	ld	a5,0(s0)
ffffffffc020448e:	470d                	li	a4,3
ffffffffc0204490:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0204492:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204496:	100027f3          	csrr	a5,sstatus
ffffffffc020449a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020449c:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020449e:	e3f9                	bnez	a5,ffffffffc0204564 <do_exit+0x13c>
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        proc = current->parent;
ffffffffc02044a0:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc02044a2:	800007b7          	lui	a5,0x80000
ffffffffc02044a6:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc02044a8:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc02044aa:	0ec52703          	lw	a4,236(a0)
ffffffffc02044ae:	0af70f63          	beq	a4,a5,ffffffffc020456c <do_exit+0x144>
        {
            wakeup_proc(proc);
        }
        while (current->cptr != NULL)
ffffffffc02044b2:	6018                	ld	a4,0(s0)
ffffffffc02044b4:	7b7c                	ld	a5,240(a4)
ffffffffc02044b6:	c3a1                	beqz	a5,ffffffffc02044f6 <do_exit+0xce>
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            if (proc->state == PROC_ZOMBIE)
            {
                if (initproc->wait_state == WT_CHILD)
ffffffffc02044b8:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044bc:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc02044be:	0985                	addi	s3,s3,1
ffffffffc02044c0:	a021                	j	ffffffffc02044c8 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc02044c2:	6018                	ld	a4,0(s0)
ffffffffc02044c4:	7b7c                	ld	a5,240(a4)
ffffffffc02044c6:	cb85                	beqz	a5,ffffffffc02044f6 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc02044c8:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_matrix_out_size+0xffffffff7fff39f0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02044cc:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc02044ce:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02044d0:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc02044d2:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02044d6:	10e7b023          	sd	a4,256(a5)
ffffffffc02044da:	c311                	beqz	a4,ffffffffc02044de <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc02044dc:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044de:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02044e0:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02044e2:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044e4:	fd271fe3          	bne	a4,s2,ffffffffc02044c2 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02044e8:	0ec52783          	lw	a5,236(a0)
ffffffffc02044ec:	fd379be3          	bne	a5,s3,ffffffffc02044c2 <do_exit+0x9a>
                {
                    wakeup_proc(initproc);
ffffffffc02044f0:	1ae010ef          	jal	ra,ffffffffc020569e <wakeup_proc>
ffffffffc02044f4:	b7f9                	j	ffffffffc02044c2 <do_exit+0x9a>
    if (flag)
ffffffffc02044f6:	020a1263          	bnez	s4,ffffffffc020451a <do_exit+0xf2>
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    schedule();
ffffffffc02044fa:	256010ef          	jal	ra,ffffffffc0205750 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02044fe:	601c                	ld	a5,0(s0)
ffffffffc0204500:	00003617          	auipc	a2,0x3
ffffffffc0204504:	17860613          	addi	a2,a2,376 # ffffffffc0207678 <default_pmm_manager+0xa48>
ffffffffc0204508:	22900593          	li	a1,553
ffffffffc020450c:	43d4                	lw	a3,4(a5)
ffffffffc020450e:	00003517          	auipc	a0,0x3
ffffffffc0204512:	13250513          	addi	a0,a0,306 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204516:	f7dfb0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_enable();
ffffffffc020451a:	c8efc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020451e:	bff1                	j	ffffffffc02044fa <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0204520:	00003617          	auipc	a2,0x3
ffffffffc0204524:	13860613          	addi	a2,a2,312 # ffffffffc0207658 <default_pmm_manager+0xa28>
ffffffffc0204528:	1f500593          	li	a1,501
ffffffffc020452c:	00003517          	auipc	a0,0x3
ffffffffc0204530:	11450513          	addi	a0,a0,276 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204534:	f5ffb0ef          	jal	ra,ffffffffc0200492 <__panic>
            exit_mmap(mm);
ffffffffc0204538:	854e                	mv	a0,s3
ffffffffc020453a:	b0cff0ef          	jal	ra,ffffffffc0203846 <exit_mmap>
            put_pgdir(mm);
ffffffffc020453e:	854e                	mv	a0,s3
ffffffffc0204540:	9cbff0ef          	jal	ra,ffffffffc0203f0a <put_pgdir>
            mm_destroy(mm);
ffffffffc0204544:	854e                	mv	a0,s3
ffffffffc0204546:	964ff0ef          	jal	ra,ffffffffc02036aa <mm_destroy>
ffffffffc020454a:	bf35                	j	ffffffffc0204486 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc020454c:	00003617          	auipc	a2,0x3
ffffffffc0204550:	11c60613          	addi	a2,a2,284 # ffffffffc0207668 <default_pmm_manager+0xa38>
ffffffffc0204554:	1f900593          	li	a1,505
ffffffffc0204558:	00003517          	auipc	a0,0x3
ffffffffc020455c:	0e850513          	addi	a0,a0,232 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204560:	f33fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_disable();
ffffffffc0204564:	c4afc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0204568:	4a05                	li	s4,1
ffffffffc020456a:	bf1d                	j	ffffffffc02044a0 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc020456c:	132010ef          	jal	ra,ffffffffc020569e <wakeup_proc>
ffffffffc0204570:	b789                	j	ffffffffc02044b2 <do_exit+0x8a>

ffffffffc0204572 <do_wait.part.0>:
}

// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
int do_wait(int pid, int *code_store)
ffffffffc0204572:	715d                	addi	sp,sp,-80
ffffffffc0204574:	f84a                	sd	s2,48(sp)
ffffffffc0204576:	f44e                	sd	s3,40(sp)
        }
    }
    if (haskid)
    {
        current->state = PROC_SLEEPING;
        current->wait_state = WT_CHILD;
ffffffffc0204578:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc020457c:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc020457e:	fc26                	sd	s1,56(sp)
ffffffffc0204580:	f052                	sd	s4,32(sp)
ffffffffc0204582:	ec56                	sd	s5,24(sp)
ffffffffc0204584:	e85a                	sd	s6,16(sp)
ffffffffc0204586:	e45e                	sd	s7,8(sp)
ffffffffc0204588:	e486                	sd	ra,72(sp)
ffffffffc020458a:	e0a2                	sd	s0,64(sp)
ffffffffc020458c:	84aa                	mv	s1,a0
ffffffffc020458e:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204590:	000cdb97          	auipc	s7,0xcd
ffffffffc0204594:	6e8b8b93          	addi	s7,s7,1768 # ffffffffc02d1c78 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204598:	00050b1b          	sext.w	s6,a0
ffffffffc020459c:	fff50a9b          	addiw	s5,a0,-1
ffffffffc02045a0:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc02045a2:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc02045a4:	ccbd                	beqz	s1,ffffffffc0204622 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc02045a6:	0359e863          	bltu	s3,s5,ffffffffc02045d6 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02045aa:	45a9                	li	a1,10
ffffffffc02045ac:	855a                	mv	a0,s6
ffffffffc02045ae:	362010ef          	jal	ra,ffffffffc0205910 <hash32>
ffffffffc02045b2:	02051793          	slli	a5,a0,0x20
ffffffffc02045b6:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02045ba:	000c9797          	auipc	a5,0xc9
ffffffffc02045be:	61e78793          	addi	a5,a5,1566 # ffffffffc02cdbd8 <hash_list>
ffffffffc02045c2:	953e                	add	a0,a0,a5
ffffffffc02045c4:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc02045c6:	a029                	j	ffffffffc02045d0 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc02045c8:	f2c42783          	lw	a5,-212(s0)
ffffffffc02045cc:	02978163          	beq	a5,s1,ffffffffc02045ee <do_wait.part.0+0x7c>
ffffffffc02045d0:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc02045d2:	fe851be3          	bne	a0,s0,ffffffffc02045c8 <do_wait.part.0+0x56>
        {
            do_exit(-E_KILLED);
        }
        goto repeat;
    }
    return -E_BAD_PROC;
ffffffffc02045d6:	5579                	li	a0,-2
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}
ffffffffc02045d8:	60a6                	ld	ra,72(sp)
ffffffffc02045da:	6406                	ld	s0,64(sp)
ffffffffc02045dc:	74e2                	ld	s1,56(sp)
ffffffffc02045de:	7942                	ld	s2,48(sp)
ffffffffc02045e0:	79a2                	ld	s3,40(sp)
ffffffffc02045e2:	7a02                	ld	s4,32(sp)
ffffffffc02045e4:	6ae2                	ld	s5,24(sp)
ffffffffc02045e6:	6b42                	ld	s6,16(sp)
ffffffffc02045e8:	6ba2                	ld	s7,8(sp)
ffffffffc02045ea:	6161                	addi	sp,sp,80
ffffffffc02045ec:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc02045ee:	000bb683          	ld	a3,0(s7)
ffffffffc02045f2:	f4843783          	ld	a5,-184(s0)
ffffffffc02045f6:	fed790e3          	bne	a5,a3,ffffffffc02045d6 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045fa:	f2842703          	lw	a4,-216(s0)
ffffffffc02045fe:	478d                	li	a5,3
ffffffffc0204600:	0ef70b63          	beq	a4,a5,ffffffffc02046f6 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204604:	4785                	li	a5,1
ffffffffc0204606:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204608:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc020460c:	144010ef          	jal	ra,ffffffffc0205750 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204610:	000bb783          	ld	a5,0(s7)
ffffffffc0204614:	0b07a783          	lw	a5,176(a5)
ffffffffc0204618:	8b85                	andi	a5,a5,1
ffffffffc020461a:	d7c9                	beqz	a5,ffffffffc02045a4 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc020461c:	555d                	li	a0,-9
ffffffffc020461e:	e0bff0ef          	jal	ra,ffffffffc0204428 <do_exit>
        proc = current->cptr;
ffffffffc0204622:	000bb683          	ld	a3,0(s7)
ffffffffc0204626:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204628:	d45d                	beqz	s0,ffffffffc02045d6 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020462a:	470d                	li	a4,3
ffffffffc020462c:	a021                	j	ffffffffc0204634 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc020462e:	10043403          	ld	s0,256(s0)
ffffffffc0204632:	d869                	beqz	s0,ffffffffc0204604 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204634:	401c                	lw	a5,0(s0)
ffffffffc0204636:	fee79ce3          	bne	a5,a4,ffffffffc020462e <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc020463a:	000cd797          	auipc	a5,0xcd
ffffffffc020463e:	6467b783          	ld	a5,1606(a5) # ffffffffc02d1c80 <idleproc>
ffffffffc0204642:	0c878963          	beq	a5,s0,ffffffffc0204714 <do_wait.part.0+0x1a2>
ffffffffc0204646:	000cd797          	auipc	a5,0xcd
ffffffffc020464a:	6427b783          	ld	a5,1602(a5) # ffffffffc02d1c88 <initproc>
ffffffffc020464e:	0cf40363          	beq	s0,a5,ffffffffc0204714 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc0204652:	000a0663          	beqz	s4,ffffffffc020465e <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204656:	0e842783          	lw	a5,232(s0)
ffffffffc020465a:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f40>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020465e:	100027f3          	csrr	a5,sstatus
ffffffffc0204662:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204664:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204666:	e7c1                	bnez	a5,ffffffffc02046ee <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204668:	6c70                	ld	a2,216(s0)
ffffffffc020466a:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc020466c:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0204670:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204672:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204674:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204676:	6470                	ld	a2,200(s0)
ffffffffc0204678:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc020467a:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020467c:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc020467e:	c319                	beqz	a4,ffffffffc0204684 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0204680:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204682:	7c7c                	ld	a5,248(s0)
ffffffffc0204684:	c3b5                	beqz	a5,ffffffffc02046e8 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0204686:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc020468a:	000cd717          	auipc	a4,0xcd
ffffffffc020468e:	60670713          	addi	a4,a4,1542 # ffffffffc02d1c90 <nr_process>
ffffffffc0204692:	431c                	lw	a5,0(a4)
ffffffffc0204694:	37fd                	addiw	a5,a5,-1
ffffffffc0204696:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204698:	e5a9                	bnez	a1,ffffffffc02046e2 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020469a:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020469c:	c02007b7          	lui	a5,0xc0200
ffffffffc02046a0:	04f6ee63          	bltu	a3,a5,ffffffffc02046fc <do_wait.part.0+0x18a>
ffffffffc02046a4:	000cd797          	auipc	a5,0xcd
ffffffffc02046a8:	5c47b783          	ld	a5,1476(a5) # ffffffffc02d1c68 <va_pa_offset>
ffffffffc02046ac:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02046ae:	82b1                	srli	a3,a3,0xc
ffffffffc02046b0:	000cd797          	auipc	a5,0xcd
ffffffffc02046b4:	5a07b783          	ld	a5,1440(a5) # ffffffffc02d1c50 <npage>
ffffffffc02046b8:	06f6fa63          	bgeu	a3,a5,ffffffffc020472c <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc02046bc:	00004517          	auipc	a0,0x4
ffffffffc02046c0:	f9453503          	ld	a0,-108(a0) # ffffffffc0208650 <nbase>
ffffffffc02046c4:	8e89                	sub	a3,a3,a0
ffffffffc02046c6:	069a                	slli	a3,a3,0x6
ffffffffc02046c8:	000cd517          	auipc	a0,0xcd
ffffffffc02046cc:	59053503          	ld	a0,1424(a0) # ffffffffc02d1c58 <pages>
ffffffffc02046d0:	9536                	add	a0,a0,a3
ffffffffc02046d2:	4589                	li	a1,2
ffffffffc02046d4:	f7afd0ef          	jal	ra,ffffffffc0201e4e <free_pages>
    kfree(proc);
ffffffffc02046d8:	8522                	mv	a0,s0
ffffffffc02046da:	e08fd0ef          	jal	ra,ffffffffc0201ce2 <kfree>
    return 0;
ffffffffc02046de:	4501                	li	a0,0
ffffffffc02046e0:	bde5                	j	ffffffffc02045d8 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc02046e2:	ac6fc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02046e6:	bf55                	j	ffffffffc020469a <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc02046e8:	701c                	ld	a5,32(s0)
ffffffffc02046ea:	fbf8                	sd	a4,240(a5)
ffffffffc02046ec:	bf79                	j	ffffffffc020468a <do_wait.part.0+0x118>
        intr_disable();
ffffffffc02046ee:	ac0fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc02046f2:	4585                	li	a1,1
ffffffffc02046f4:	bf95                	j	ffffffffc0204668 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02046f6:	f2840413          	addi	s0,s0,-216
ffffffffc02046fa:	b781                	j	ffffffffc020463a <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc02046fc:	00002617          	auipc	a2,0x2
ffffffffc0204700:	61460613          	addi	a2,a2,1556 # ffffffffc0206d10 <default_pmm_manager+0xe0>
ffffffffc0204704:	07700593          	li	a1,119
ffffffffc0204708:	00002517          	auipc	a0,0x2
ffffffffc020470c:	58850513          	addi	a0,a0,1416 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc0204710:	d83fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204714:	00003617          	auipc	a2,0x3
ffffffffc0204718:	f8460613          	addi	a2,a2,-124 # ffffffffc0207698 <default_pmm_manager+0xa68>
ffffffffc020471c:	34b00593          	li	a1,843
ffffffffc0204720:	00003517          	auipc	a0,0x3
ffffffffc0204724:	f2050513          	addi	a0,a0,-224 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204728:	d6bfb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020472c:	00002617          	auipc	a2,0x2
ffffffffc0204730:	60c60613          	addi	a2,a2,1548 # ffffffffc0206d38 <default_pmm_manager+0x108>
ffffffffc0204734:	06900593          	li	a1,105
ffffffffc0204738:	00002517          	auipc	a0,0x2
ffffffffc020473c:	55850513          	addi	a0,a0,1368 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc0204740:	d53fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204744 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0204744:	1141                	addi	sp,sp,-16
ffffffffc0204746:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204748:	f46fd0ef          	jal	ra,ffffffffc0201e8e <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc020474c:	ce2fd0ef          	jal	ra,ffffffffc0201c2e <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204750:	4601                	li	a2,0
ffffffffc0204752:	4581                	li	a1,0
ffffffffc0204754:	00000517          	auipc	a0,0x0
ffffffffc0204758:	62850513          	addi	a0,a0,1576 # ffffffffc0204d7c <user_main>
ffffffffc020475c:	c7dff0ef          	jal	ra,ffffffffc02043d8 <kernel_thread>
    if (pid <= 0)
ffffffffc0204760:	00a04563          	bgtz	a0,ffffffffc020476a <init_main+0x26>
ffffffffc0204764:	a071                	j	ffffffffc02047f0 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204766:	7eb000ef          	jal	ra,ffffffffc0205750 <schedule>
    if (code_store != NULL)
ffffffffc020476a:	4581                	li	a1,0
ffffffffc020476c:	4501                	li	a0,0
ffffffffc020476e:	e05ff0ef          	jal	ra,ffffffffc0204572 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204772:	d975                	beqz	a0,ffffffffc0204766 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204774:	00003517          	auipc	a0,0x3
ffffffffc0204778:	f6450513          	addi	a0,a0,-156 # ffffffffc02076d8 <default_pmm_manager+0xaa8>
ffffffffc020477c:	a1dfb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204780:	000cd797          	auipc	a5,0xcd
ffffffffc0204784:	5087b783          	ld	a5,1288(a5) # ffffffffc02d1c88 <initproc>
ffffffffc0204788:	7bf8                	ld	a4,240(a5)
ffffffffc020478a:	e339                	bnez	a4,ffffffffc02047d0 <init_main+0x8c>
ffffffffc020478c:	7ff8                	ld	a4,248(a5)
ffffffffc020478e:	e329                	bnez	a4,ffffffffc02047d0 <init_main+0x8c>
ffffffffc0204790:	1007b703          	ld	a4,256(a5)
ffffffffc0204794:	ef15                	bnez	a4,ffffffffc02047d0 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204796:	000cd697          	auipc	a3,0xcd
ffffffffc020479a:	4fa6a683          	lw	a3,1274(a3) # ffffffffc02d1c90 <nr_process>
ffffffffc020479e:	4709                	li	a4,2
ffffffffc02047a0:	0ae69463          	bne	a3,a4,ffffffffc0204848 <init_main+0x104>
    return listelm->next;
ffffffffc02047a4:	000cd697          	auipc	a3,0xcd
ffffffffc02047a8:	43468693          	addi	a3,a3,1076 # ffffffffc02d1bd8 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02047ac:	6698                	ld	a4,8(a3)
ffffffffc02047ae:	0c878793          	addi	a5,a5,200
ffffffffc02047b2:	06f71b63          	bne	a4,a5,ffffffffc0204828 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02047b6:	629c                	ld	a5,0(a3)
ffffffffc02047b8:	04f71863          	bne	a4,a5,ffffffffc0204808 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc02047bc:	00003517          	auipc	a0,0x3
ffffffffc02047c0:	00450513          	addi	a0,a0,4 # ffffffffc02077c0 <default_pmm_manager+0xb90>
ffffffffc02047c4:	9d5fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;
}
ffffffffc02047c8:	60a2                	ld	ra,8(sp)
ffffffffc02047ca:	4501                	li	a0,0
ffffffffc02047cc:	0141                	addi	sp,sp,16
ffffffffc02047ce:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02047d0:	00003697          	auipc	a3,0x3
ffffffffc02047d4:	f3068693          	addi	a3,a3,-208 # ffffffffc0207700 <default_pmm_manager+0xad0>
ffffffffc02047d8:	00002617          	auipc	a2,0x2
ffffffffc02047dc:	0a860613          	addi	a2,a2,168 # ffffffffc0206880 <commands+0x838>
ffffffffc02047e0:	3b700593          	li	a1,951
ffffffffc02047e4:	00003517          	auipc	a0,0x3
ffffffffc02047e8:	e5c50513          	addi	a0,a0,-420 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc02047ec:	ca7fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("create user_main failed.\n");
ffffffffc02047f0:	00003617          	auipc	a2,0x3
ffffffffc02047f4:	ec860613          	addi	a2,a2,-312 # ffffffffc02076b8 <default_pmm_manager+0xa88>
ffffffffc02047f8:	3ae00593          	li	a1,942
ffffffffc02047fc:	00003517          	auipc	a0,0x3
ffffffffc0204800:	e4450513          	addi	a0,a0,-444 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204804:	c8ffb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204808:	00003697          	auipc	a3,0x3
ffffffffc020480c:	f8868693          	addi	a3,a3,-120 # ffffffffc0207790 <default_pmm_manager+0xb60>
ffffffffc0204810:	00002617          	auipc	a2,0x2
ffffffffc0204814:	07060613          	addi	a2,a2,112 # ffffffffc0206880 <commands+0x838>
ffffffffc0204818:	3ba00593          	li	a1,954
ffffffffc020481c:	00003517          	auipc	a0,0x3
ffffffffc0204820:	e2450513          	addi	a0,a0,-476 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204824:	c6ffb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204828:	00003697          	auipc	a3,0x3
ffffffffc020482c:	f3868693          	addi	a3,a3,-200 # ffffffffc0207760 <default_pmm_manager+0xb30>
ffffffffc0204830:	00002617          	auipc	a2,0x2
ffffffffc0204834:	05060613          	addi	a2,a2,80 # ffffffffc0206880 <commands+0x838>
ffffffffc0204838:	3b900593          	li	a1,953
ffffffffc020483c:	00003517          	auipc	a0,0x3
ffffffffc0204840:	e0450513          	addi	a0,a0,-508 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204844:	c4ffb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_process == 2);
ffffffffc0204848:	00003697          	auipc	a3,0x3
ffffffffc020484c:	f0868693          	addi	a3,a3,-248 # ffffffffc0207750 <default_pmm_manager+0xb20>
ffffffffc0204850:	00002617          	auipc	a2,0x2
ffffffffc0204854:	03060613          	addi	a2,a2,48 # ffffffffc0206880 <commands+0x838>
ffffffffc0204858:	3b800593          	li	a1,952
ffffffffc020485c:	00003517          	auipc	a0,0x3
ffffffffc0204860:	de450513          	addi	a0,a0,-540 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204864:	c2ffb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204868 <do_execve>:
{
ffffffffc0204868:	7171                	addi	sp,sp,-176
ffffffffc020486a:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020486c:	000cdd97          	auipc	s11,0xcd
ffffffffc0204870:	40cd8d93          	addi	s11,s11,1036 # ffffffffc02d1c78 <current>
ffffffffc0204874:	000db783          	ld	a5,0(s11)
{
ffffffffc0204878:	e54e                	sd	s3,136(sp)
ffffffffc020487a:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020487c:	0287b983          	ld	s3,40(a5)
{
ffffffffc0204880:	e94a                	sd	s2,144(sp)
ffffffffc0204882:	f4de                	sd	s7,104(sp)
ffffffffc0204884:	892a                	mv	s2,a0
ffffffffc0204886:	8bb2                	mv	s7,a2
ffffffffc0204888:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020488a:	862e                	mv	a2,a1
ffffffffc020488c:	4681                	li	a3,0
ffffffffc020488e:	85aa                	mv	a1,a0
ffffffffc0204890:	854e                	mv	a0,s3
{
ffffffffc0204892:	f506                	sd	ra,168(sp)
ffffffffc0204894:	f122                	sd	s0,160(sp)
ffffffffc0204896:	e152                	sd	s4,128(sp)
ffffffffc0204898:	fcd6                	sd	s5,120(sp)
ffffffffc020489a:	f8da                	sd	s6,112(sp)
ffffffffc020489c:	f0e2                	sd	s8,96(sp)
ffffffffc020489e:	ece6                	sd	s9,88(sp)
ffffffffc02048a0:	e8ea                	sd	s10,80(sp)
ffffffffc02048a2:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02048a4:	d08ff0ef          	jal	ra,ffffffffc0203dac <user_mem_check>
ffffffffc02048a8:	40050a63          	beqz	a0,ffffffffc0204cbc <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02048ac:	4641                	li	a2,16
ffffffffc02048ae:	4581                	li	a1,0
ffffffffc02048b0:	1808                	addi	a0,sp,48
ffffffffc02048b2:	504010ef          	jal	ra,ffffffffc0205db6 <memset>
    memcpy(local_name, name, len);
ffffffffc02048b6:	47bd                	li	a5,15
ffffffffc02048b8:	8626                	mv	a2,s1
ffffffffc02048ba:	1e97e263          	bltu	a5,s1,ffffffffc0204a9e <do_execve+0x236>
ffffffffc02048be:	85ca                	mv	a1,s2
ffffffffc02048c0:	1808                	addi	a0,sp,48
ffffffffc02048c2:	506010ef          	jal	ra,ffffffffc0205dc8 <memcpy>
    if (mm != NULL)
ffffffffc02048c6:	1e098363          	beqz	s3,ffffffffc0204aac <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc02048ca:	00003517          	auipc	a0,0x3
ffffffffc02048ce:	b7650513          	addi	a0,a0,-1162 # ffffffffc0207440 <default_pmm_manager+0x810>
ffffffffc02048d2:	8fffb0ef          	jal	ra,ffffffffc02001d0 <cputs>
ffffffffc02048d6:	000cd797          	auipc	a5,0xcd
ffffffffc02048da:	36a7b783          	ld	a5,874(a5) # ffffffffc02d1c40 <boot_pgdir_pa>
ffffffffc02048de:	577d                	li	a4,-1
ffffffffc02048e0:	177e                	slli	a4,a4,0x3f
ffffffffc02048e2:	83b1                	srli	a5,a5,0xc
ffffffffc02048e4:	8fd9                	or	a5,a5,a4
ffffffffc02048e6:	18079073          	csrw	satp,a5
ffffffffc02048ea:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7f10>
ffffffffc02048ee:	fff7871b          	addiw	a4,a5,-1
ffffffffc02048f2:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02048f6:	2c070463          	beqz	a4,ffffffffc0204bbe <do_execve+0x356>
        current->mm = NULL;
ffffffffc02048fa:	000db783          	ld	a5,0(s11)
ffffffffc02048fe:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204902:	c69fe0ef          	jal	ra,ffffffffc020356a <mm_create>
ffffffffc0204906:	84aa                	mv	s1,a0
ffffffffc0204908:	1c050d63          	beqz	a0,ffffffffc0204ae2 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc020490c:	4505                	li	a0,1
ffffffffc020490e:	d02fd0ef          	jal	ra,ffffffffc0201e10 <alloc_pages>
ffffffffc0204912:	3a050963          	beqz	a0,ffffffffc0204cc4 <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0204916:	000cdc97          	auipc	s9,0xcd
ffffffffc020491a:	342c8c93          	addi	s9,s9,834 # ffffffffc02d1c58 <pages>
ffffffffc020491e:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204922:	000cdc17          	auipc	s8,0xcd
ffffffffc0204926:	32ec0c13          	addi	s8,s8,814 # ffffffffc02d1c50 <npage>
    return page - pages + nbase;
ffffffffc020492a:	00004717          	auipc	a4,0x4
ffffffffc020492e:	d2673703          	ld	a4,-730(a4) # ffffffffc0208650 <nbase>
ffffffffc0204932:	40d506b3          	sub	a3,a0,a3
ffffffffc0204936:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204938:	5afd                	li	s5,-1
ffffffffc020493a:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc020493e:	96ba                	add	a3,a3,a4
ffffffffc0204940:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204942:	00cad713          	srli	a4,s5,0xc
ffffffffc0204946:	ec3a                	sd	a4,24(sp)
ffffffffc0204948:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020494a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020494c:	38f77063          	bgeu	a4,a5,ffffffffc0204ccc <do_execve+0x464>
ffffffffc0204950:	000cdb17          	auipc	s6,0xcd
ffffffffc0204954:	318b0b13          	addi	s6,s6,792 # ffffffffc02d1c68 <va_pa_offset>
ffffffffc0204958:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020495c:	6605                	lui	a2,0x1
ffffffffc020495e:	000cd597          	auipc	a1,0xcd
ffffffffc0204962:	2ea5b583          	ld	a1,746(a1) # ffffffffc02d1c48 <boot_pgdir_va>
ffffffffc0204966:	9936                	add	s2,s2,a3
ffffffffc0204968:	854a                	mv	a0,s2
ffffffffc020496a:	45e010ef          	jal	ra,ffffffffc0205dc8 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc020496e:	7782                	ld	a5,32(sp)
ffffffffc0204970:	4398                	lw	a4,0(a5)
ffffffffc0204972:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204976:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc020497a:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_matrix_out_size+0x464b7e6f>
ffffffffc020497e:	14f71863          	bne	a4,a5,ffffffffc0204ace <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204982:	7682                	ld	a3,32(sp)
ffffffffc0204984:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204988:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020498c:	00371793          	slli	a5,a4,0x3
ffffffffc0204990:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204992:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204994:	078e                	slli	a5,a5,0x3
ffffffffc0204996:	97ce                	add	a5,a5,s3
ffffffffc0204998:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc020499a:	00f9fc63          	bgeu	s3,a5,ffffffffc02049b2 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc020499e:	0009a783          	lw	a5,0(s3)
ffffffffc02049a2:	4705                	li	a4,1
ffffffffc02049a4:	14e78163          	beq	a5,a4,ffffffffc0204ae6 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc02049a8:	77a2                	ld	a5,40(sp)
ffffffffc02049aa:	03898993          	addi	s3,s3,56
ffffffffc02049ae:	fef9e8e3          	bltu	s3,a5,ffffffffc020499e <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc02049b2:	4701                	li	a4,0
ffffffffc02049b4:	46ad                	li	a3,11
ffffffffc02049b6:	00100637          	lui	a2,0x100
ffffffffc02049ba:	7ff005b7          	lui	a1,0x7ff00
ffffffffc02049be:	8526                	mv	a0,s1
ffffffffc02049c0:	d3dfe0ef          	jal	ra,ffffffffc02036fc <mm_map>
ffffffffc02049c4:	8a2a                	mv	s4,a0
ffffffffc02049c6:	1e051263          	bnez	a0,ffffffffc0204baa <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc02049ca:	6c88                	ld	a0,24(s1)
ffffffffc02049cc:	467d                	li	a2,31
ffffffffc02049ce:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc02049d2:	ab3fe0ef          	jal	ra,ffffffffc0203484 <pgdir_alloc_page>
ffffffffc02049d6:	38050363          	beqz	a0,ffffffffc0204d5c <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc02049da:	6c88                	ld	a0,24(s1)
ffffffffc02049dc:	467d                	li	a2,31
ffffffffc02049de:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc02049e2:	aa3fe0ef          	jal	ra,ffffffffc0203484 <pgdir_alloc_page>
ffffffffc02049e6:	34050b63          	beqz	a0,ffffffffc0204d3c <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc02049ea:	6c88                	ld	a0,24(s1)
ffffffffc02049ec:	467d                	li	a2,31
ffffffffc02049ee:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc02049f2:	a93fe0ef          	jal	ra,ffffffffc0203484 <pgdir_alloc_page>
ffffffffc02049f6:	32050363          	beqz	a0,ffffffffc0204d1c <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc02049fa:	6c88                	ld	a0,24(s1)
ffffffffc02049fc:	467d                	li	a2,31
ffffffffc02049fe:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204a02:	a83fe0ef          	jal	ra,ffffffffc0203484 <pgdir_alloc_page>
ffffffffc0204a06:	2e050b63          	beqz	a0,ffffffffc0204cfc <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204a0a:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204a0c:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204a10:	6c94                	ld	a3,24(s1)
ffffffffc0204a12:	2785                	addiw	a5,a5,1
ffffffffc0204a14:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0204a16:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204a18:	c02007b7          	lui	a5,0xc0200
ffffffffc0204a1c:	2cf6e463          	bltu	a3,a5,ffffffffc0204ce4 <do_execve+0x47c>
ffffffffc0204a20:	000b3783          	ld	a5,0(s6)
ffffffffc0204a24:	577d                	li	a4,-1
ffffffffc0204a26:	177e                	slli	a4,a4,0x3f
ffffffffc0204a28:	8e9d                	sub	a3,a3,a5
ffffffffc0204a2a:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204a2e:	f654                	sd	a3,168(a2)
ffffffffc0204a30:	8fd9                	or	a5,a5,a4
ffffffffc0204a32:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204a36:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204a38:	4581                	li	a1,0
ffffffffc0204a3a:	12000613          	li	a2,288
ffffffffc0204a3e:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204a40:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204a44:	372010ef          	jal	ra,ffffffffc0205db6 <memset>
    tf->epc = elf->e_entry;
ffffffffc0204a48:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a4a:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE;
ffffffffc0204a4e:	edd4f493          	andi	s1,s1,-291
    tf->epc = elf->e_entry;
ffffffffc0204a52:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204a54:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a56:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_matrix_out_size+0xffffffff7fff39a4>
    tf->gpr.sp = USTACKTOP;
ffffffffc0204a5a:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE;
ffffffffc0204a5c:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a60:	4641                	li	a2,16
ffffffffc0204a62:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc0204a64:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0204a66:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE;
ffffffffc0204a6a:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a6e:	854a                	mv	a0,s2
ffffffffc0204a70:	346010ef          	jal	ra,ffffffffc0205db6 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204a74:	463d                	li	a2,15
ffffffffc0204a76:	180c                	addi	a1,sp,48
ffffffffc0204a78:	854a                	mv	a0,s2
ffffffffc0204a7a:	34e010ef          	jal	ra,ffffffffc0205dc8 <memcpy>
}
ffffffffc0204a7e:	70aa                	ld	ra,168(sp)
ffffffffc0204a80:	740a                	ld	s0,160(sp)
ffffffffc0204a82:	64ea                	ld	s1,152(sp)
ffffffffc0204a84:	694a                	ld	s2,144(sp)
ffffffffc0204a86:	69aa                	ld	s3,136(sp)
ffffffffc0204a88:	7ae6                	ld	s5,120(sp)
ffffffffc0204a8a:	7b46                	ld	s6,112(sp)
ffffffffc0204a8c:	7ba6                	ld	s7,104(sp)
ffffffffc0204a8e:	7c06                	ld	s8,96(sp)
ffffffffc0204a90:	6ce6                	ld	s9,88(sp)
ffffffffc0204a92:	6d46                	ld	s10,80(sp)
ffffffffc0204a94:	6da6                	ld	s11,72(sp)
ffffffffc0204a96:	8552                	mv	a0,s4
ffffffffc0204a98:	6a0a                	ld	s4,128(sp)
ffffffffc0204a9a:	614d                	addi	sp,sp,176
ffffffffc0204a9c:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204a9e:	463d                	li	a2,15
ffffffffc0204aa0:	85ca                	mv	a1,s2
ffffffffc0204aa2:	1808                	addi	a0,sp,48
ffffffffc0204aa4:	324010ef          	jal	ra,ffffffffc0205dc8 <memcpy>
    if (mm != NULL)
ffffffffc0204aa8:	e20991e3          	bnez	s3,ffffffffc02048ca <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204aac:	000db783          	ld	a5,0(s11)
ffffffffc0204ab0:	779c                	ld	a5,40(a5)
ffffffffc0204ab2:	e40788e3          	beqz	a5,ffffffffc0204902 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204ab6:	00003617          	auipc	a2,0x3
ffffffffc0204aba:	d2a60613          	addi	a2,a2,-726 # ffffffffc02077e0 <default_pmm_manager+0xbb0>
ffffffffc0204abe:	23500593          	li	a1,565
ffffffffc0204ac2:	00003517          	auipc	a0,0x3
ffffffffc0204ac6:	b7e50513          	addi	a0,a0,-1154 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204aca:	9c9fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    put_pgdir(mm);
ffffffffc0204ace:	8526                	mv	a0,s1
ffffffffc0204ad0:	c3aff0ef          	jal	ra,ffffffffc0203f0a <put_pgdir>
    mm_destroy(mm);
ffffffffc0204ad4:	8526                	mv	a0,s1
ffffffffc0204ad6:	bd5fe0ef          	jal	ra,ffffffffc02036aa <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204ada:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0204adc:	8552                	mv	a0,s4
ffffffffc0204ade:	94bff0ef          	jal	ra,ffffffffc0204428 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204ae2:	5a71                	li	s4,-4
ffffffffc0204ae4:	bfe5                	j	ffffffffc0204adc <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204ae6:	0289b603          	ld	a2,40(s3)
ffffffffc0204aea:	0209b783          	ld	a5,32(s3)
ffffffffc0204aee:	1cf66d63          	bltu	a2,a5,ffffffffc0204cc8 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204af2:	0049a783          	lw	a5,4(s3)
ffffffffc0204af6:	0017f693          	andi	a3,a5,1
ffffffffc0204afa:	c291                	beqz	a3,ffffffffc0204afe <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204afc:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204afe:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b02:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204b04:	e779                	bnez	a4,ffffffffc0204bd2 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204b06:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b08:	c781                	beqz	a5,ffffffffc0204b10 <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204b0a:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204b0e:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204b10:	0026f793          	andi	a5,a3,2
ffffffffc0204b14:	e3f1                	bnez	a5,ffffffffc0204bd8 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204b16:	0046f793          	andi	a5,a3,4
ffffffffc0204b1a:	c399                	beqz	a5,ffffffffc0204b20 <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204b1c:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204b20:	0109b583          	ld	a1,16(s3)
ffffffffc0204b24:	4701                	li	a4,0
ffffffffc0204b26:	8526                	mv	a0,s1
ffffffffc0204b28:	bd5fe0ef          	jal	ra,ffffffffc02036fc <mm_map>
ffffffffc0204b2c:	8a2a                	mv	s4,a0
ffffffffc0204b2e:	ed35                	bnez	a0,ffffffffc0204baa <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b30:	0109bb83          	ld	s7,16(s3)
ffffffffc0204b34:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204b36:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b3a:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b3e:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b42:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204b44:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b46:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204b48:	054be963          	bltu	s7,s4,ffffffffc0204b9a <do_execve+0x332>
ffffffffc0204b4c:	aa95                	j	ffffffffc0204cc0 <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b4e:	6785                	lui	a5,0x1
ffffffffc0204b50:	415b8533          	sub	a0,s7,s5
ffffffffc0204b54:	9abe                	add	s5,s5,a5
ffffffffc0204b56:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204b5a:	015a7463          	bgeu	s4,s5,ffffffffc0204b62 <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204b5e:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204b62:	000cb683          	ld	a3,0(s9)
ffffffffc0204b66:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204b68:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204b6c:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b70:	8699                	srai	a3,a3,0x6
ffffffffc0204b72:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204b74:	67e2                	ld	a5,24(sp)
ffffffffc0204b76:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b7a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b7c:	14b87863          	bgeu	a6,a1,ffffffffc0204ccc <do_execve+0x464>
ffffffffc0204b80:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b84:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204b86:	9bb2                	add	s7,s7,a2
ffffffffc0204b88:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b8a:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204b8c:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b8e:	23a010ef          	jal	ra,ffffffffc0205dc8 <memcpy>
            start += size, from += size;
ffffffffc0204b92:	6622                	ld	a2,8(sp)
ffffffffc0204b94:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204b96:	054bf363          	bgeu	s7,s4,ffffffffc0204bdc <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204b9a:	6c88                	ld	a0,24(s1)
ffffffffc0204b9c:	866a                	mv	a2,s10
ffffffffc0204b9e:	85d6                	mv	a1,s5
ffffffffc0204ba0:	8e5fe0ef          	jal	ra,ffffffffc0203484 <pgdir_alloc_page>
ffffffffc0204ba4:	842a                	mv	s0,a0
ffffffffc0204ba6:	f545                	bnez	a0,ffffffffc0204b4e <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204ba8:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204baa:	8526                	mv	a0,s1
ffffffffc0204bac:	c9bfe0ef          	jal	ra,ffffffffc0203846 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204bb0:	8526                	mv	a0,s1
ffffffffc0204bb2:	b58ff0ef          	jal	ra,ffffffffc0203f0a <put_pgdir>
    mm_destroy(mm);
ffffffffc0204bb6:	8526                	mv	a0,s1
ffffffffc0204bb8:	af3fe0ef          	jal	ra,ffffffffc02036aa <mm_destroy>
    return ret;
ffffffffc0204bbc:	b705                	j	ffffffffc0204adc <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204bbe:	854e                	mv	a0,s3
ffffffffc0204bc0:	c87fe0ef          	jal	ra,ffffffffc0203846 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204bc4:	854e                	mv	a0,s3
ffffffffc0204bc6:	b44ff0ef          	jal	ra,ffffffffc0203f0a <put_pgdir>
            mm_destroy(mm);
ffffffffc0204bca:	854e                	mv	a0,s3
ffffffffc0204bcc:	adffe0ef          	jal	ra,ffffffffc02036aa <mm_destroy>
ffffffffc0204bd0:	b32d                	j	ffffffffc02048fa <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204bd2:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204bd6:	fb95                	bnez	a5,ffffffffc0204b0a <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204bd8:	4d5d                	li	s10,23
ffffffffc0204bda:	bf35                	j	ffffffffc0204b16 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204bdc:	0109b683          	ld	a3,16(s3)
ffffffffc0204be0:	0289b903          	ld	s2,40(s3)
ffffffffc0204be4:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204be6:	075bfd63          	bgeu	s7,s5,ffffffffc0204c60 <do_execve+0x3f8>
            if (start == end)
ffffffffc0204bea:	db790fe3          	beq	s2,s7,ffffffffc02049a8 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204bee:	6785                	lui	a5,0x1
ffffffffc0204bf0:	00fb8533          	add	a0,s7,a5
ffffffffc0204bf4:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204bf8:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204bfc:	0b597d63          	bgeu	s2,s5,ffffffffc0204cb6 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204c00:	000cb683          	ld	a3,0(s9)
ffffffffc0204c04:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204c06:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204c0a:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c0e:	8699                	srai	a3,a3,0x6
ffffffffc0204c10:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204c12:	67e2                	ld	a5,24(sp)
ffffffffc0204c14:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c18:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c1a:	0ac5f963          	bgeu	a1,a2,ffffffffc0204ccc <do_execve+0x464>
ffffffffc0204c1e:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c22:	8652                	mv	a2,s4
ffffffffc0204c24:	4581                	li	a1,0
ffffffffc0204c26:	96c2                	add	a3,a3,a6
ffffffffc0204c28:	9536                	add	a0,a0,a3
ffffffffc0204c2a:	18c010ef          	jal	ra,ffffffffc0205db6 <memset>
            start += size;
ffffffffc0204c2e:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204c32:	03597463          	bgeu	s2,s5,ffffffffc0204c5a <do_execve+0x3f2>
ffffffffc0204c36:	d6e909e3          	beq	s2,a4,ffffffffc02049a8 <do_execve+0x140>
ffffffffc0204c3a:	00003697          	auipc	a3,0x3
ffffffffc0204c3e:	bce68693          	addi	a3,a3,-1074 # ffffffffc0207808 <default_pmm_manager+0xbd8>
ffffffffc0204c42:	00002617          	auipc	a2,0x2
ffffffffc0204c46:	c3e60613          	addi	a2,a2,-962 # ffffffffc0206880 <commands+0x838>
ffffffffc0204c4a:	29e00593          	li	a1,670
ffffffffc0204c4e:	00003517          	auipc	a0,0x3
ffffffffc0204c52:	9f250513          	addi	a0,a0,-1550 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204c56:	83dfb0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0204c5a:	ff5710e3          	bne	a4,s5,ffffffffc0204c3a <do_execve+0x3d2>
ffffffffc0204c5e:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204c60:	d52bf4e3          	bgeu	s7,s2,ffffffffc02049a8 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204c64:	6c88                	ld	a0,24(s1)
ffffffffc0204c66:	866a                	mv	a2,s10
ffffffffc0204c68:	85d6                	mv	a1,s5
ffffffffc0204c6a:	81bfe0ef          	jal	ra,ffffffffc0203484 <pgdir_alloc_page>
ffffffffc0204c6e:	842a                	mv	s0,a0
ffffffffc0204c70:	dd05                	beqz	a0,ffffffffc0204ba8 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c72:	6785                	lui	a5,0x1
ffffffffc0204c74:	415b8533          	sub	a0,s7,s5
ffffffffc0204c78:	9abe                	add	s5,s5,a5
ffffffffc0204c7a:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204c7e:	01597463          	bgeu	s2,s5,ffffffffc0204c86 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204c82:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204c86:	000cb683          	ld	a3,0(s9)
ffffffffc0204c8a:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204c8c:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204c90:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c94:	8699                	srai	a3,a3,0x6
ffffffffc0204c96:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204c98:	67e2                	ld	a5,24(sp)
ffffffffc0204c9a:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c9e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204ca0:	02b87663          	bgeu	a6,a1,ffffffffc0204ccc <do_execve+0x464>
ffffffffc0204ca4:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204ca8:	4581                	li	a1,0
            start += size;
ffffffffc0204caa:	9bb2                	add	s7,s7,a2
ffffffffc0204cac:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204cae:	9536                	add	a0,a0,a3
ffffffffc0204cb0:	106010ef          	jal	ra,ffffffffc0205db6 <memset>
ffffffffc0204cb4:	b775                	j	ffffffffc0204c60 <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204cb6:	417a8a33          	sub	s4,s5,s7
ffffffffc0204cba:	b799                	j	ffffffffc0204c00 <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204cbc:	5a75                	li	s4,-3
ffffffffc0204cbe:	b3c1                	j	ffffffffc0204a7e <do_execve+0x216>
        while (start < end)
ffffffffc0204cc0:	86de                	mv	a3,s7
ffffffffc0204cc2:	bf39                	j	ffffffffc0204be0 <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204cc4:	5a71                	li	s4,-4
ffffffffc0204cc6:	bdc5                	j	ffffffffc0204bb6 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204cc8:	5a61                	li	s4,-8
ffffffffc0204cca:	b5c5                	j	ffffffffc0204baa <do_execve+0x342>
ffffffffc0204ccc:	00002617          	auipc	a2,0x2
ffffffffc0204cd0:	f9c60613          	addi	a2,a2,-100 # ffffffffc0206c68 <default_pmm_manager+0x38>
ffffffffc0204cd4:	07100593          	li	a1,113
ffffffffc0204cd8:	00002517          	auipc	a0,0x2
ffffffffc0204cdc:	fb850513          	addi	a0,a0,-72 # ffffffffc0206c90 <default_pmm_manager+0x60>
ffffffffc0204ce0:	fb2fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204ce4:	00002617          	auipc	a2,0x2
ffffffffc0204ce8:	02c60613          	addi	a2,a2,44 # ffffffffc0206d10 <default_pmm_manager+0xe0>
ffffffffc0204cec:	2bd00593          	li	a1,701
ffffffffc0204cf0:	00003517          	auipc	a0,0x3
ffffffffc0204cf4:	95050513          	addi	a0,a0,-1712 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204cf8:	f9afb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204cfc:	00003697          	auipc	a3,0x3
ffffffffc0204d00:	c2468693          	addi	a3,a3,-988 # ffffffffc0207920 <default_pmm_manager+0xcf0>
ffffffffc0204d04:	00002617          	auipc	a2,0x2
ffffffffc0204d08:	b7c60613          	addi	a2,a2,-1156 # ffffffffc0206880 <commands+0x838>
ffffffffc0204d0c:	2b800593          	li	a1,696
ffffffffc0204d10:	00003517          	auipc	a0,0x3
ffffffffc0204d14:	93050513          	addi	a0,a0,-1744 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204d18:	f7afb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d1c:	00003697          	auipc	a3,0x3
ffffffffc0204d20:	bbc68693          	addi	a3,a3,-1092 # ffffffffc02078d8 <default_pmm_manager+0xca8>
ffffffffc0204d24:	00002617          	auipc	a2,0x2
ffffffffc0204d28:	b5c60613          	addi	a2,a2,-1188 # ffffffffc0206880 <commands+0x838>
ffffffffc0204d2c:	2b700593          	li	a1,695
ffffffffc0204d30:	00003517          	auipc	a0,0x3
ffffffffc0204d34:	91050513          	addi	a0,a0,-1776 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204d38:	f5afb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d3c:	00003697          	auipc	a3,0x3
ffffffffc0204d40:	b5468693          	addi	a3,a3,-1196 # ffffffffc0207890 <default_pmm_manager+0xc60>
ffffffffc0204d44:	00002617          	auipc	a2,0x2
ffffffffc0204d48:	b3c60613          	addi	a2,a2,-1220 # ffffffffc0206880 <commands+0x838>
ffffffffc0204d4c:	2b600593          	li	a1,694
ffffffffc0204d50:	00003517          	auipc	a0,0x3
ffffffffc0204d54:	8f050513          	addi	a0,a0,-1808 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204d58:	f3afb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204d5c:	00003697          	auipc	a3,0x3
ffffffffc0204d60:	aec68693          	addi	a3,a3,-1300 # ffffffffc0207848 <default_pmm_manager+0xc18>
ffffffffc0204d64:	00002617          	auipc	a2,0x2
ffffffffc0204d68:	b1c60613          	addi	a2,a2,-1252 # ffffffffc0206880 <commands+0x838>
ffffffffc0204d6c:	2b500593          	li	a1,693
ffffffffc0204d70:	00003517          	auipc	a0,0x3
ffffffffc0204d74:	8d050513          	addi	a0,a0,-1840 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204d78:	f1afb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204d7c <user_main>:
{
ffffffffc0204d7c:	1101                	addi	sp,sp,-32
ffffffffc0204d7e:	e04a                	sd	s2,0(sp)
    KERNEL_EXECVE(priority);
ffffffffc0204d80:	000cd917          	auipc	s2,0xcd
ffffffffc0204d84:	ef890913          	addi	s2,s2,-264 # ffffffffc02d1c78 <current>
ffffffffc0204d88:	00093783          	ld	a5,0(s2)
ffffffffc0204d8c:	00003617          	auipc	a2,0x3
ffffffffc0204d90:	bdc60613          	addi	a2,a2,-1060 # ffffffffc0207968 <default_pmm_manager+0xd38>
ffffffffc0204d94:	00003517          	auipc	a0,0x3
ffffffffc0204d98:	be450513          	addi	a0,a0,-1052 # ffffffffc0207978 <default_pmm_manager+0xd48>
ffffffffc0204d9c:	43cc                	lw	a1,4(a5)
{
ffffffffc0204d9e:	ec06                	sd	ra,24(sp)
ffffffffc0204da0:	e822                	sd	s0,16(sp)
ffffffffc0204da2:	e426                	sd	s1,8(sp)
    KERNEL_EXECVE(priority);
ffffffffc0204da4:	bf4fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    size_t len = strlen(name);
ffffffffc0204da8:	00003517          	auipc	a0,0x3
ffffffffc0204dac:	bc050513          	addi	a0,a0,-1088 # ffffffffc0207968 <default_pmm_manager+0xd38>
ffffffffc0204db0:	765000ef          	jal	ra,ffffffffc0205d14 <strlen>
    struct trapframe *old_tf = current->tf;
ffffffffc0204db4:	00093783          	ld	a5,0(s2)
    size_t len = strlen(name);
ffffffffc0204db8:	84aa                	mv	s1,a0
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204dba:	12000613          	li	a2,288
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204dbe:	6b80                	ld	s0,16(a5)
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204dc0:	73cc                	ld	a1,160(a5)
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204dc2:	6789                	lui	a5,0x2
ffffffffc0204dc4:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8060>
ffffffffc0204dc8:	943e                	add	s0,s0,a5
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204dca:	8522                	mv	a0,s0
ffffffffc0204dcc:	7fd000ef          	jal	ra,ffffffffc0205dc8 <memcpy>
    current->tf = new_tf;
ffffffffc0204dd0:	00093783          	ld	a5,0(s2)
    ret = do_execve(name, len, binary, size);
ffffffffc0204dd4:	3fe07697          	auipc	a3,0x3fe07
ffffffffc0204dd8:	96c68693          	addi	a3,a3,-1684 # b740 <_binary_obj___user_priority_out_size>
ffffffffc0204ddc:	0007d617          	auipc	a2,0x7d
ffffffffc0204de0:	f3c60613          	addi	a2,a2,-196 # ffffffffc0281d18 <_binary_obj___user_priority_out_start>
    current->tf = new_tf;
ffffffffc0204de4:	f3c0                	sd	s0,160(a5)
    ret = do_execve(name, len, binary, size);
ffffffffc0204de6:	85a6                	mv	a1,s1
ffffffffc0204de8:	00003517          	auipc	a0,0x3
ffffffffc0204dec:	b8050513          	addi	a0,a0,-1152 # ffffffffc0207968 <default_pmm_manager+0xd38>
ffffffffc0204df0:	a79ff0ef          	jal	ra,ffffffffc0204868 <do_execve>
    asm volatile(
ffffffffc0204df4:	8122                	mv	sp,s0
ffffffffc0204df6:	8fefc06f          	j	ffffffffc0200ef4 <__trapret>
    panic("user_main execve failed.\n");
ffffffffc0204dfa:	00003617          	auipc	a2,0x3
ffffffffc0204dfe:	ba660613          	addi	a2,a2,-1114 # ffffffffc02079a0 <default_pmm_manager+0xd70>
ffffffffc0204e02:	3a100593          	li	a1,929
ffffffffc0204e06:	00003517          	auipc	a0,0x3
ffffffffc0204e0a:	83a50513          	addi	a0,a0,-1990 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0204e0e:	e84fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204e12 <do_yield>:
    current->need_resched = 1;
ffffffffc0204e12:	000cd797          	auipc	a5,0xcd
ffffffffc0204e16:	e667b783          	ld	a5,-410(a5) # ffffffffc02d1c78 <current>
ffffffffc0204e1a:	4705                	li	a4,1
ffffffffc0204e1c:	ef98                	sd	a4,24(a5)
}
ffffffffc0204e1e:	4501                	li	a0,0
ffffffffc0204e20:	8082                	ret

ffffffffc0204e22 <do_wait>:
{
ffffffffc0204e22:	1101                	addi	sp,sp,-32
ffffffffc0204e24:	e822                	sd	s0,16(sp)
ffffffffc0204e26:	e426                	sd	s1,8(sp)
ffffffffc0204e28:	ec06                	sd	ra,24(sp)
ffffffffc0204e2a:	842e                	mv	s0,a1
ffffffffc0204e2c:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204e2e:	c999                	beqz	a1,ffffffffc0204e44 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204e30:	000cd797          	auipc	a5,0xcd
ffffffffc0204e34:	e487b783          	ld	a5,-440(a5) # ffffffffc02d1c78 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204e38:	7788                	ld	a0,40(a5)
ffffffffc0204e3a:	4685                	li	a3,1
ffffffffc0204e3c:	4611                	li	a2,4
ffffffffc0204e3e:	f6ffe0ef          	jal	ra,ffffffffc0203dac <user_mem_check>
ffffffffc0204e42:	c909                	beqz	a0,ffffffffc0204e54 <do_wait+0x32>
ffffffffc0204e44:	85a2                	mv	a1,s0
}
ffffffffc0204e46:	6442                	ld	s0,16(sp)
ffffffffc0204e48:	60e2                	ld	ra,24(sp)
ffffffffc0204e4a:	8526                	mv	a0,s1
ffffffffc0204e4c:	64a2                	ld	s1,8(sp)
ffffffffc0204e4e:	6105                	addi	sp,sp,32
ffffffffc0204e50:	f22ff06f          	j	ffffffffc0204572 <do_wait.part.0>
ffffffffc0204e54:	60e2                	ld	ra,24(sp)
ffffffffc0204e56:	6442                	ld	s0,16(sp)
ffffffffc0204e58:	64a2                	ld	s1,8(sp)
ffffffffc0204e5a:	5575                	li	a0,-3
ffffffffc0204e5c:	6105                	addi	sp,sp,32
ffffffffc0204e5e:	8082                	ret

ffffffffc0204e60 <do_kill>:
{
ffffffffc0204e60:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e62:	6789                	lui	a5,0x2
{
ffffffffc0204e64:	e406                	sd	ra,8(sp)
ffffffffc0204e66:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e68:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204e6c:	17f9                	addi	a5,a5,-2
ffffffffc0204e6e:	02e7e963          	bltu	a5,a4,ffffffffc0204ea0 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e72:	842a                	mv	s0,a0
ffffffffc0204e74:	45a9                	li	a1,10
ffffffffc0204e76:	2501                	sext.w	a0,a0
ffffffffc0204e78:	299000ef          	jal	ra,ffffffffc0205910 <hash32>
ffffffffc0204e7c:	02051793          	slli	a5,a0,0x20
ffffffffc0204e80:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204e84:	000c9797          	auipc	a5,0xc9
ffffffffc0204e88:	d5478793          	addi	a5,a5,-684 # ffffffffc02cdbd8 <hash_list>
ffffffffc0204e8c:	953e                	add	a0,a0,a5
ffffffffc0204e8e:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204e90:	a029                	j	ffffffffc0204e9a <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204e92:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204e96:	00870b63          	beq	a4,s0,ffffffffc0204eac <do_kill+0x4c>
ffffffffc0204e9a:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204e9c:	fef51be3          	bne	a0,a5,ffffffffc0204e92 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204ea0:	5475                	li	s0,-3
}
ffffffffc0204ea2:	60a2                	ld	ra,8(sp)
ffffffffc0204ea4:	8522                	mv	a0,s0
ffffffffc0204ea6:	6402                	ld	s0,0(sp)
ffffffffc0204ea8:	0141                	addi	sp,sp,16
ffffffffc0204eaa:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204eac:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204eb0:	00177693          	andi	a3,a4,1
ffffffffc0204eb4:	e295                	bnez	a3,ffffffffc0204ed8 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204eb6:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204eb8:	00176713          	ori	a4,a4,1
ffffffffc0204ebc:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204ec0:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204ec2:	fe06d0e3          	bgez	a3,ffffffffc0204ea2 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204ec6:	f2878513          	addi	a0,a5,-216
ffffffffc0204eca:	7d4000ef          	jal	ra,ffffffffc020569e <wakeup_proc>
}
ffffffffc0204ece:	60a2                	ld	ra,8(sp)
ffffffffc0204ed0:	8522                	mv	a0,s0
ffffffffc0204ed2:	6402                	ld	s0,0(sp)
ffffffffc0204ed4:	0141                	addi	sp,sp,16
ffffffffc0204ed6:	8082                	ret
        return -E_KILLED;
ffffffffc0204ed8:	545d                	li	s0,-9
ffffffffc0204eda:	b7e1                	j	ffffffffc0204ea2 <do_kill+0x42>

ffffffffc0204edc <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204edc:	1101                	addi	sp,sp,-32
ffffffffc0204ede:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204ee0:	000cd797          	auipc	a5,0xcd
ffffffffc0204ee4:	cf878793          	addi	a5,a5,-776 # ffffffffc02d1bd8 <proc_list>
ffffffffc0204ee8:	ec06                	sd	ra,24(sp)
ffffffffc0204eea:	e822                	sd	s0,16(sp)
ffffffffc0204eec:	e04a                	sd	s2,0(sp)
ffffffffc0204eee:	000c9497          	auipc	s1,0xc9
ffffffffc0204ef2:	cea48493          	addi	s1,s1,-790 # ffffffffc02cdbd8 <hash_list>
ffffffffc0204ef6:	e79c                	sd	a5,8(a5)
ffffffffc0204ef8:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204efa:	000cd717          	auipc	a4,0xcd
ffffffffc0204efe:	cde70713          	addi	a4,a4,-802 # ffffffffc02d1bd8 <proc_list>
ffffffffc0204f02:	87a6                	mv	a5,s1
ffffffffc0204f04:	e79c                	sd	a5,8(a5)
ffffffffc0204f06:	e39c                	sd	a5,0(a5)
ffffffffc0204f08:	07c1                	addi	a5,a5,16
ffffffffc0204f0a:	fef71de3          	bne	a4,a5,ffffffffc0204f04 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204f0e:	f3bfe0ef          	jal	ra,ffffffffc0203e48 <alloc_proc>
ffffffffc0204f12:	000cd917          	auipc	s2,0xcd
ffffffffc0204f16:	d6e90913          	addi	s2,s2,-658 # ffffffffc02d1c80 <idleproc>
ffffffffc0204f1a:	00a93023          	sd	a0,0(s2)
ffffffffc0204f1e:	0e050f63          	beqz	a0,ffffffffc020501c <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204f22:	4789                	li	a5,2
ffffffffc0204f24:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204f26:	00004797          	auipc	a5,0x4
ffffffffc0204f2a:	0da78793          	addi	a5,a5,218 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f2e:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204f32:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204f34:	4785                	li	a5,1
ffffffffc0204f36:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f38:	4641                	li	a2,16
ffffffffc0204f3a:	4581                	li	a1,0
ffffffffc0204f3c:	8522                	mv	a0,s0
ffffffffc0204f3e:	679000ef          	jal	ra,ffffffffc0205db6 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204f42:	463d                	li	a2,15
ffffffffc0204f44:	00003597          	auipc	a1,0x3
ffffffffc0204f48:	a9458593          	addi	a1,a1,-1388 # ffffffffc02079d8 <default_pmm_manager+0xda8>
ffffffffc0204f4c:	8522                	mv	a0,s0
ffffffffc0204f4e:	67b000ef          	jal	ra,ffffffffc0205dc8 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204f52:	000cd717          	auipc	a4,0xcd
ffffffffc0204f56:	d3e70713          	addi	a4,a4,-706 # ffffffffc02d1c90 <nr_process>
ffffffffc0204f5a:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204f5c:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f60:	4601                	li	a2,0
    nr_process++;
ffffffffc0204f62:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f64:	4581                	li	a1,0
ffffffffc0204f66:	fffff517          	auipc	a0,0xfffff
ffffffffc0204f6a:	7de50513          	addi	a0,a0,2014 # ffffffffc0204744 <init_main>
    nr_process++;
ffffffffc0204f6e:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204f70:	000cd797          	auipc	a5,0xcd
ffffffffc0204f74:	d0d7b423          	sd	a3,-760(a5) # ffffffffc02d1c78 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f78:	c60ff0ef          	jal	ra,ffffffffc02043d8 <kernel_thread>
ffffffffc0204f7c:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204f7e:	08a05363          	blez	a0,ffffffffc0205004 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f82:	6789                	lui	a5,0x2
ffffffffc0204f84:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204f88:	17f9                	addi	a5,a5,-2
ffffffffc0204f8a:	2501                	sext.w	a0,a0
ffffffffc0204f8c:	02e7e363          	bltu	a5,a4,ffffffffc0204fb2 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f90:	45a9                	li	a1,10
ffffffffc0204f92:	17f000ef          	jal	ra,ffffffffc0205910 <hash32>
ffffffffc0204f96:	02051793          	slli	a5,a0,0x20
ffffffffc0204f9a:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204f9e:	96a6                	add	a3,a3,s1
ffffffffc0204fa0:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204fa2:	a029                	j	ffffffffc0204fac <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0204fa4:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x8014>
ffffffffc0204fa8:	04870b63          	beq	a4,s0,ffffffffc0204ffe <proc_init+0x122>
    return listelm->next;
ffffffffc0204fac:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204fae:	fef69be3          	bne	a3,a5,ffffffffc0204fa4 <proc_init+0xc8>
    return NULL;
ffffffffc0204fb2:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fb4:	0b478493          	addi	s1,a5,180
ffffffffc0204fb8:	4641                	li	a2,16
ffffffffc0204fba:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204fbc:	000cd417          	auipc	s0,0xcd
ffffffffc0204fc0:	ccc40413          	addi	s0,s0,-820 # ffffffffc02d1c88 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fc4:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204fc6:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fc8:	5ef000ef          	jal	ra,ffffffffc0205db6 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204fcc:	463d                	li	a2,15
ffffffffc0204fce:	00003597          	auipc	a1,0x3
ffffffffc0204fd2:	a3258593          	addi	a1,a1,-1486 # ffffffffc0207a00 <default_pmm_manager+0xdd0>
ffffffffc0204fd6:	8526                	mv	a0,s1
ffffffffc0204fd8:	5f1000ef          	jal	ra,ffffffffc0205dc8 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204fdc:	00093783          	ld	a5,0(s2)
ffffffffc0204fe0:	cbb5                	beqz	a5,ffffffffc0205054 <proc_init+0x178>
ffffffffc0204fe2:	43dc                	lw	a5,4(a5)
ffffffffc0204fe4:	eba5                	bnez	a5,ffffffffc0205054 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204fe6:	601c                	ld	a5,0(s0)
ffffffffc0204fe8:	c7b1                	beqz	a5,ffffffffc0205034 <proc_init+0x158>
ffffffffc0204fea:	43d8                	lw	a4,4(a5)
ffffffffc0204fec:	4785                	li	a5,1
ffffffffc0204fee:	04f71363          	bne	a4,a5,ffffffffc0205034 <proc_init+0x158>
}
ffffffffc0204ff2:	60e2                	ld	ra,24(sp)
ffffffffc0204ff4:	6442                	ld	s0,16(sp)
ffffffffc0204ff6:	64a2                	ld	s1,8(sp)
ffffffffc0204ff8:	6902                	ld	s2,0(sp)
ffffffffc0204ffa:	6105                	addi	sp,sp,32
ffffffffc0204ffc:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204ffe:	f2878793          	addi	a5,a5,-216
ffffffffc0205002:	bf4d                	j	ffffffffc0204fb4 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0205004:	00003617          	auipc	a2,0x3
ffffffffc0205008:	9dc60613          	addi	a2,a2,-1572 # ffffffffc02079e0 <default_pmm_manager+0xdb0>
ffffffffc020500c:	3dd00593          	li	a1,989
ffffffffc0205010:	00002517          	auipc	a0,0x2
ffffffffc0205014:	63050513          	addi	a0,a0,1584 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0205018:	c7afb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc020501c:	00003617          	auipc	a2,0x3
ffffffffc0205020:	9a460613          	addi	a2,a2,-1628 # ffffffffc02079c0 <default_pmm_manager+0xd90>
ffffffffc0205024:	3ce00593          	li	a1,974
ffffffffc0205028:	00002517          	auipc	a0,0x2
ffffffffc020502c:	61850513          	addi	a0,a0,1560 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0205030:	c62fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205034:	00003697          	auipc	a3,0x3
ffffffffc0205038:	9fc68693          	addi	a3,a3,-1540 # ffffffffc0207a30 <default_pmm_manager+0xe00>
ffffffffc020503c:	00002617          	auipc	a2,0x2
ffffffffc0205040:	84460613          	addi	a2,a2,-1980 # ffffffffc0206880 <commands+0x838>
ffffffffc0205044:	3e400593          	li	a1,996
ffffffffc0205048:	00002517          	auipc	a0,0x2
ffffffffc020504c:	5f850513          	addi	a0,a0,1528 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0205050:	c42fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205054:	00003697          	auipc	a3,0x3
ffffffffc0205058:	9b468693          	addi	a3,a3,-1612 # ffffffffc0207a08 <default_pmm_manager+0xdd8>
ffffffffc020505c:	00002617          	auipc	a2,0x2
ffffffffc0205060:	82460613          	addi	a2,a2,-2012 # ffffffffc0206880 <commands+0x838>
ffffffffc0205064:	3e300593          	li	a1,995
ffffffffc0205068:	00002517          	auipc	a0,0x2
ffffffffc020506c:	5d850513          	addi	a0,a0,1496 # ffffffffc0207640 <default_pmm_manager+0xa10>
ffffffffc0205070:	c22fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0205074 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205074:	1141                	addi	sp,sp,-16
ffffffffc0205076:	e022                	sd	s0,0(sp)
ffffffffc0205078:	e406                	sd	ra,8(sp)
ffffffffc020507a:	000cd417          	auipc	s0,0xcd
ffffffffc020507e:	bfe40413          	addi	s0,s0,-1026 # ffffffffc02d1c78 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205082:	6018                	ld	a4,0(s0)
ffffffffc0205084:	6f1c                	ld	a5,24(a4)
ffffffffc0205086:	dffd                	beqz	a5,ffffffffc0205084 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205088:	6c8000ef          	jal	ra,ffffffffc0205750 <schedule>
ffffffffc020508c:	bfdd                	j	ffffffffc0205082 <cpu_idle+0xe>

ffffffffc020508e <lab6_set_priority>:
        }
    }
}
// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority)
{
ffffffffc020508e:	1141                	addi	sp,sp,-16
ffffffffc0205090:	e022                	sd	s0,0(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0205092:	85aa                	mv	a1,a0
{
ffffffffc0205094:	842a                	mv	s0,a0
    cprintf("set priority to %d\n", priority);
ffffffffc0205096:	00003517          	auipc	a0,0x3
ffffffffc020509a:	9c250513          	addi	a0,a0,-1598 # ffffffffc0207a58 <default_pmm_manager+0xe28>
{
ffffffffc020509e:	e406                	sd	ra,8(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc02050a0:	8f8fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (priority == 0)
        current->lab6_priority = 1;
ffffffffc02050a4:	000cd797          	auipc	a5,0xcd
ffffffffc02050a8:	bd47b783          	ld	a5,-1068(a5) # ffffffffc02d1c78 <current>
    if (priority == 0)
ffffffffc02050ac:	e801                	bnez	s0,ffffffffc02050bc <lab6_set_priority+0x2e>
    else
        current->lab6_priority = priority;
}
ffffffffc02050ae:	60a2                	ld	ra,8(sp)
ffffffffc02050b0:	6402                	ld	s0,0(sp)
        current->lab6_priority = 1;
ffffffffc02050b2:	4705                	li	a4,1
ffffffffc02050b4:	14e7a223          	sw	a4,324(a5)
}
ffffffffc02050b8:	0141                	addi	sp,sp,16
ffffffffc02050ba:	8082                	ret
ffffffffc02050bc:	60a2                	ld	ra,8(sp)
        current->lab6_priority = priority;
ffffffffc02050be:	1487a223          	sw	s0,324(a5)
}
ffffffffc02050c2:	6402                	ld	s0,0(sp)
ffffffffc02050c4:	0141                	addi	sp,sp,16
ffffffffc02050c6:	8082                	ret

ffffffffc02050c8 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc02050c8:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc02050cc:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc02050d0:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02050d2:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02050d4:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02050d8:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02050dc:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02050e0:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02050e4:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02050e8:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02050ec:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02050f0:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02050f4:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02050f8:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02050fc:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0205100:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0205104:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205106:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205108:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc020510c:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205110:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0205114:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205118:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc020511c:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205120:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0205124:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205128:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc020512c:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0205130:	8082                	ret

ffffffffc0205132 <stride_init>:
    elm->prev = elm->next = elm;
ffffffffc0205132:	e508                	sd	a0,8(a0)
ffffffffc0205134:	e108                	sd	a0,0(a0)
      * (1) init the ready process list: rq->run_list
      * (2) init the run pool: rq->lab6_run_pool
      * (3) set number of process: rq->proc_num to 0
      */
     list_init(&(rq->run_list));
     rq->lab6_run_pool = NULL;
ffffffffc0205136:	00053c23          	sd	zero,24(a0)
     rq->proc_num = 0;
ffffffffc020513a:	00052823          	sw	zero,16(a0)
}
ffffffffc020513e:	8082                	ret

ffffffffc0205140 <stride_pick_next>:
             (1.1) If using skew_heap, we can use le2proc get the p from rq->lab6_run_pol
             (1.2) If using list, we have to search list to find the p with minimum stride value
      * (2) update p;s stride value: p->lab6_stride
      * (3) return p
      */
     if (rq->lab6_run_pool == NULL)
ffffffffc0205140:	6d1c                	ld	a5,24(a0)
ffffffffc0205142:	cf91                	beqz	a5,ffffffffc020515e <stride_pick_next+0x1e>
     {
          return NULL;
     }
     struct proc_struct *p = le2proc(rq->lab6_run_pool, lab6_run_pool);
     p->lab6_stride += BIG_STRIDE / p->lab6_priority;
ffffffffc0205144:	4fd4                	lw	a3,28(a5)
ffffffffc0205146:	80000737          	lui	a4,0x80000
ffffffffc020514a:	fff74713          	not	a4,a4
ffffffffc020514e:	02d7573b          	divuw	a4,a4,a3
ffffffffc0205152:	4f94                	lw	a3,24(a5)
     struct proc_struct *p = le2proc(rq->lab6_run_pool, lab6_run_pool);
ffffffffc0205154:	ed878513          	addi	a0,a5,-296
     p->lab6_stride += BIG_STRIDE / p->lab6_priority;
ffffffffc0205158:	9f35                	addw	a4,a4,a3
ffffffffc020515a:	cf98                	sw	a4,24(a5)
     return p;
ffffffffc020515c:	8082                	ret
          return NULL;
ffffffffc020515e:	4501                	li	a0,0
}
ffffffffc0205160:	8082                	ret

ffffffffc0205162 <stride_proc_tick>:
 */
static void
stride_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: YOUR CODE */
     if (proc->time_slice > 0)
ffffffffc0205162:	1205a783          	lw	a5,288(a1)
ffffffffc0205166:	00f05563          	blez	a5,ffffffffc0205170 <stride_proc_tick+0xe>
     {
          proc->time_slice--;
ffffffffc020516a:	37fd                	addiw	a5,a5,-1
ffffffffc020516c:	12f5a023          	sw	a5,288(a1)
     }
     if (proc->time_slice == 0)
ffffffffc0205170:	e399                	bnez	a5,ffffffffc0205176 <stride_proc_tick+0x14>
     {
          proc->need_resched = 1;
ffffffffc0205172:	4785                	li	a5,1
ffffffffc0205174:	ed9c                	sd	a5,24(a1)
     }
}
ffffffffc0205176:	8082                	ret

ffffffffc0205178 <skew_heap_merge.constprop.0>:
}

static inline skew_heap_entry_t *
skew_heap_merge(skew_heap_entry_t *a, skew_heap_entry_t *b,
ffffffffc0205178:	7139                	addi	sp,sp,-64
ffffffffc020517a:	f822                	sd	s0,48(sp)
ffffffffc020517c:	fc06                	sd	ra,56(sp)
ffffffffc020517e:	f426                	sd	s1,40(sp)
ffffffffc0205180:	f04a                	sd	s2,32(sp)
ffffffffc0205182:	ec4e                	sd	s3,24(sp)
ffffffffc0205184:	e852                	sd	s4,16(sp)
ffffffffc0205186:	e456                	sd	s5,8(sp)
ffffffffc0205188:	e05a                	sd	s6,0(sp)
ffffffffc020518a:	842e                	mv	s0,a1
                compare_f comp)
{
     if (a == NULL) return b;
ffffffffc020518c:	c925                	beqz	a0,ffffffffc02051fc <skew_heap_merge.constprop.0+0x84>
ffffffffc020518e:	84aa                	mv	s1,a0
     else if (b == NULL) return a;
ffffffffc0205190:	c1ed                	beqz	a1,ffffffffc0205272 <skew_heap_merge.constprop.0+0xfa>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc0205192:	4d1c                	lw	a5,24(a0)
ffffffffc0205194:	4d98                	lw	a4,24(a1)
     else if (c == 0)
ffffffffc0205196:	40e786bb          	subw	a3,a5,a4
ffffffffc020519a:	0606cc63          	bltz	a3,ffffffffc0205212 <skew_heap_merge.constprop.0+0x9a>
          return a;
     }
     else
     {
          r = b->left;
          l = skew_heap_merge(a, b->right, comp);
ffffffffc020519e:	0105b903          	ld	s2,16(a1)
          r = b->left;
ffffffffc02051a2:	0085ba03          	ld	s4,8(a1)
     else if (b == NULL) return a;
ffffffffc02051a6:	04090763          	beqz	s2,ffffffffc02051f4 <skew_heap_merge.constprop.0+0x7c>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02051aa:	01892703          	lw	a4,24(s2)
     else if (c == 0)
ffffffffc02051ae:	40e786bb          	subw	a3,a5,a4
ffffffffc02051b2:	0c06c263          	bltz	a3,ffffffffc0205276 <skew_heap_merge.constprop.0+0xfe>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02051b6:	01093983          	ld	s3,16(s2)
          r = b->left;
ffffffffc02051ba:	00893a83          	ld	s5,8(s2)
     else if (b == NULL) return a;
ffffffffc02051be:	10098c63          	beqz	s3,ffffffffc02052d6 <skew_heap_merge.constprop.0+0x15e>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02051c2:	0189a703          	lw	a4,24(s3)
     else if (c == 0)
ffffffffc02051c6:	9f99                	subw	a5,a5,a4
ffffffffc02051c8:	1407c863          	bltz	a5,ffffffffc0205318 <skew_heap_merge.constprop.0+0x1a0>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02051cc:	0109b583          	ld	a1,16(s3)
          r = b->left;
ffffffffc02051d0:	0089b483          	ld	s1,8(s3)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02051d4:	fa5ff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          
          b->left = l;
ffffffffc02051d8:	00a9b423          	sd	a0,8(s3)
          b->right = r;
ffffffffc02051dc:	0099b823          	sd	s1,16(s3)
          if (l) l->parent = b;
ffffffffc02051e0:	c119                	beqz	a0,ffffffffc02051e6 <skew_heap_merge.constprop.0+0x6e>
ffffffffc02051e2:	01353023          	sd	s3,0(a0)
          b->left = l;
ffffffffc02051e6:	01393423          	sd	s3,8(s2)
          b->right = r;
ffffffffc02051ea:	01593823          	sd	s5,16(s2)
          if (l) l->parent = b;
ffffffffc02051ee:	0129b023          	sd	s2,0(s3)
ffffffffc02051f2:	84ca                	mv	s1,s2
          b->left = l;
ffffffffc02051f4:	e404                	sd	s1,8(s0)
          b->right = r;
ffffffffc02051f6:	01443823          	sd	s4,16(s0)
          if (l) l->parent = b;
ffffffffc02051fa:	e080                	sd	s0,0(s1)
ffffffffc02051fc:	8522                	mv	a0,s0

          return b;
     }
}
ffffffffc02051fe:	70e2                	ld	ra,56(sp)
ffffffffc0205200:	7442                	ld	s0,48(sp)
ffffffffc0205202:	74a2                	ld	s1,40(sp)
ffffffffc0205204:	7902                	ld	s2,32(sp)
ffffffffc0205206:	69e2                	ld	s3,24(sp)
ffffffffc0205208:	6a42                	ld	s4,16(sp)
ffffffffc020520a:	6aa2                	ld	s5,8(sp)
ffffffffc020520c:	6b02                	ld	s6,0(sp)
ffffffffc020520e:	6121                	addi	sp,sp,64
ffffffffc0205210:	8082                	ret
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205212:	01053903          	ld	s2,16(a0)
          r = a->left;
ffffffffc0205216:	00853a03          	ld	s4,8(a0)
     if (a == NULL) return b;
ffffffffc020521a:	04090863          	beqz	s2,ffffffffc020526a <skew_heap_merge.constprop.0+0xf2>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc020521e:	01892783          	lw	a5,24(s2)
     else if (c == 0)
ffffffffc0205222:	40e7873b          	subw	a4,a5,a4
ffffffffc0205226:	08074963          	bltz	a4,ffffffffc02052b8 <skew_heap_merge.constprop.0+0x140>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc020522a:	0105b983          	ld	s3,16(a1)
          r = b->left;
ffffffffc020522e:	0085ba83          	ld	s5,8(a1)
     else if (b == NULL) return a;
ffffffffc0205232:	02098663          	beqz	s3,ffffffffc020525e <skew_heap_merge.constprop.0+0xe6>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc0205236:	0189a703          	lw	a4,24(s3)
     else if (c == 0)
ffffffffc020523a:	9f99                	subw	a5,a5,a4
ffffffffc020523c:	0a07cf63          	bltz	a5,ffffffffc02052fa <skew_heap_merge.constprop.0+0x182>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205240:	0109b583          	ld	a1,16(s3)
          r = b->left;
ffffffffc0205244:	0089bb03          	ld	s6,8(s3)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205248:	854a                	mv	a0,s2
ffffffffc020524a:	f2fff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc020524e:	00a9b423          	sd	a0,8(s3)
          b->right = r;
ffffffffc0205252:	0169b823          	sd	s6,16(s3)
          if (l) l->parent = b;
ffffffffc0205256:	894e                	mv	s2,s3
ffffffffc0205258:	c119                	beqz	a0,ffffffffc020525e <skew_heap_merge.constprop.0+0xe6>
ffffffffc020525a:	01253023          	sd	s2,0(a0)
          b->left = l;
ffffffffc020525e:	01243423          	sd	s2,8(s0)
          b->right = r;
ffffffffc0205262:	01543823          	sd	s5,16(s0)
          if (l) l->parent = b;
ffffffffc0205266:	00893023          	sd	s0,0(s2)
          a->left = l;
ffffffffc020526a:	e480                	sd	s0,8(s1)
          a->right = r;
ffffffffc020526c:	0144b823          	sd	s4,16(s1)
          if (l) l->parent = a;
ffffffffc0205270:	e004                	sd	s1,0(s0)
ffffffffc0205272:	8526                	mv	a0,s1
ffffffffc0205274:	b769                	j	ffffffffc02051fe <skew_heap_merge.constprop.0+0x86>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205276:	01053983          	ld	s3,16(a0)
          r = a->left;
ffffffffc020527a:	00853a83          	ld	s5,8(a0)
     if (a == NULL) return b;
ffffffffc020527e:	02098663          	beqz	s3,ffffffffc02052aa <skew_heap_merge.constprop.0+0x132>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc0205282:	0189a783          	lw	a5,24(s3)
     else if (c == 0)
ffffffffc0205286:	40e7873b          	subw	a4,a5,a4
ffffffffc020528a:	04074863          	bltz	a4,ffffffffc02052da <skew_heap_merge.constprop.0+0x162>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc020528e:	01093583          	ld	a1,16(s2)
          r = b->left;
ffffffffc0205292:	00893b03          	ld	s6,8(s2)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205296:	854e                	mv	a0,s3
ffffffffc0205298:	ee1ff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc020529c:	00a93423          	sd	a0,8(s2)
          b->right = r;
ffffffffc02052a0:	01693823          	sd	s6,16(s2)
          if (l) l->parent = b;
ffffffffc02052a4:	c119                	beqz	a0,ffffffffc02052aa <skew_heap_merge.constprop.0+0x132>
ffffffffc02052a6:	01253023          	sd	s2,0(a0)
          a->left = l;
ffffffffc02052aa:	0124b423          	sd	s2,8(s1)
          a->right = r;
ffffffffc02052ae:	0154b823          	sd	s5,16(s1)
          if (l) l->parent = a;
ffffffffc02052b2:	00993023          	sd	s1,0(s2)
ffffffffc02052b6:	bf3d                	j	ffffffffc02051f4 <skew_heap_merge.constprop.0+0x7c>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02052b8:	01093503          	ld	a0,16(s2)
          r = a->left;
ffffffffc02052bc:	00893983          	ld	s3,8(s2)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02052c0:	844a                	mv	s0,s2
ffffffffc02052c2:	eb7ff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc02052c6:	00a93423          	sd	a0,8(s2)
          a->right = r;
ffffffffc02052ca:	01393823          	sd	s3,16(s2)
          if (l) l->parent = a;
ffffffffc02052ce:	dd51                	beqz	a0,ffffffffc020526a <skew_heap_merge.constprop.0+0xf2>
ffffffffc02052d0:	01253023          	sd	s2,0(a0)
ffffffffc02052d4:	bf59                	j	ffffffffc020526a <skew_heap_merge.constprop.0+0xf2>
          if (l) l->parent = b;
ffffffffc02052d6:	89a6                	mv	s3,s1
ffffffffc02052d8:	b739                	j	ffffffffc02051e6 <skew_heap_merge.constprop.0+0x6e>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02052da:	0109b503          	ld	a0,16(s3)
          r = a->left;
ffffffffc02052de:	0089bb03          	ld	s6,8(s3)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02052e2:	85ca                	mv	a1,s2
ffffffffc02052e4:	e95ff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc02052e8:	00a9b423          	sd	a0,8(s3)
          a->right = r;
ffffffffc02052ec:	0169b823          	sd	s6,16(s3)
          if (l) l->parent = a;
ffffffffc02052f0:	894e                	mv	s2,s3
ffffffffc02052f2:	dd45                	beqz	a0,ffffffffc02052aa <skew_heap_merge.constprop.0+0x132>
          if (l) l->parent = b;
ffffffffc02052f4:	01253023          	sd	s2,0(a0)
ffffffffc02052f8:	bf4d                	j	ffffffffc02052aa <skew_heap_merge.constprop.0+0x132>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02052fa:	01093503          	ld	a0,16(s2)
          r = a->left;
ffffffffc02052fe:	00893b03          	ld	s6,8(s2)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205302:	85ce                	mv	a1,s3
ffffffffc0205304:	e75ff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205308:	00a93423          	sd	a0,8(s2)
          a->right = r;
ffffffffc020530c:	01693823          	sd	s6,16(s2)
          if (l) l->parent = a;
ffffffffc0205310:	d539                	beqz	a0,ffffffffc020525e <skew_heap_merge.constprop.0+0xe6>
          if (l) l->parent = b;
ffffffffc0205312:	01253023          	sd	s2,0(a0)
ffffffffc0205316:	b7a1                	j	ffffffffc020525e <skew_heap_merge.constprop.0+0xe6>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205318:	6908                	ld	a0,16(a0)
          r = a->left;
ffffffffc020531a:	0084bb03          	ld	s6,8(s1)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020531e:	85ce                	mv	a1,s3
ffffffffc0205320:	e59ff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205324:	e488                	sd	a0,8(s1)
          a->right = r;
ffffffffc0205326:	0164b823          	sd	s6,16(s1)
          if (l) l->parent = a;
ffffffffc020532a:	d555                	beqz	a0,ffffffffc02052d6 <skew_heap_merge.constprop.0+0x15e>
ffffffffc020532c:	e104                	sd	s1,0(a0)
ffffffffc020532e:	89a6                	mv	s3,s1
ffffffffc0205330:	bd5d                	j	ffffffffc02051e6 <skew_heap_merge.constprop.0+0x6e>

ffffffffc0205332 <stride_dequeue>:
{
ffffffffc0205332:	711d                	addi	sp,sp,-96
ffffffffc0205334:	fc4e                	sd	s3,56(sp)
static inline skew_heap_entry_t *
skew_heap_remove(skew_heap_entry_t *a, skew_heap_entry_t *b,
                 compare_f comp)
{
     skew_heap_entry_t *p   = b->parent;
     skew_heap_entry_t *rep = skew_heap_merge(b->left, b->right, comp);
ffffffffc0205336:	1305b983          	ld	s3,304(a1)
ffffffffc020533a:	e8a2                	sd	s0,80(sp)
ffffffffc020533c:	e4a6                	sd	s1,72(sp)
ffffffffc020533e:	e0ca                	sd	s2,64(sp)
ffffffffc0205340:	f852                	sd	s4,48(sp)
ffffffffc0205342:	f05a                	sd	s6,32(sp)
ffffffffc0205344:	ec86                	sd	ra,88(sp)
ffffffffc0205346:	f456                	sd	s5,40(sp)
ffffffffc0205348:	ec5e                	sd	s7,24(sp)
ffffffffc020534a:	e862                	sd	s8,16(sp)
ffffffffc020534c:	e466                	sd	s9,8(sp)
ffffffffc020534e:	e06a                	sd	s10,0(sp)
     rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc0205350:	01853b03          	ld	s6,24(a0)
     skew_heap_entry_t *p   = b->parent;
ffffffffc0205354:	1285ba03          	ld	s4,296(a1)
     skew_heap_entry_t *rep = skew_heap_merge(b->left, b->right, comp);
ffffffffc0205358:	1385b483          	ld	s1,312(a1)
{
ffffffffc020535c:	842e                	mv	s0,a1
ffffffffc020535e:	892a                	mv	s2,a0
     if (a == NULL) return b;
ffffffffc0205360:	12098a63          	beqz	s3,ffffffffc0205494 <stride_dequeue+0x162>
     else if (b == NULL) return a;
ffffffffc0205364:	12048f63          	beqz	s1,ffffffffc02054a2 <stride_dequeue+0x170>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc0205368:	0189a783          	lw	a5,24(s3)
ffffffffc020536c:	4c98                	lw	a4,24(s1)
     else if (c == 0)
ffffffffc020536e:	40e786bb          	subw	a3,a5,a4
ffffffffc0205372:	0a06c963          	bltz	a3,ffffffffc0205424 <stride_dequeue+0xf2>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205376:	0104ba83          	ld	s5,16(s1)
          r = b->left;
ffffffffc020537a:	0084bc03          	ld	s8,8(s1)
     else if (b == NULL) return a;
ffffffffc020537e:	040a8963          	beqz	s5,ffffffffc02053d0 <stride_dequeue+0x9e>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc0205382:	018aa703          	lw	a4,24(s5)
     else if (c == 0)
ffffffffc0205386:	40e786bb          	subw	a3,a5,a4
ffffffffc020538a:	1206c063          	bltz	a3,ffffffffc02054aa <stride_dequeue+0x178>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc020538e:	010abb83          	ld	s7,16(s5)
          r = b->left;
ffffffffc0205392:	008abc83          	ld	s9,8(s5)
     else if (b == NULL) return a;
ffffffffc0205396:	020b8663          	beqz	s7,ffffffffc02053c2 <stride_dequeue+0x90>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc020539a:	018ba703          	lw	a4,24(s7)
     else if (c == 0)
ffffffffc020539e:	9f99                	subw	a5,a5,a4
ffffffffc02053a0:	1a07c563          	bltz	a5,ffffffffc020554a <stride_dequeue+0x218>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02053a4:	010bb583          	ld	a1,16(s7)
          r = b->left;
ffffffffc02053a8:	008bbd03          	ld	s10,8(s7)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02053ac:	854e                	mv	a0,s3
ffffffffc02053ae:	dcbff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc02053b2:	00abb423          	sd	a0,8(s7)
          b->right = r;
ffffffffc02053b6:	01abb823          	sd	s10,16(s7)
          if (l) l->parent = b;
ffffffffc02053ba:	89de                	mv	s3,s7
ffffffffc02053bc:	c119                	beqz	a0,ffffffffc02053c2 <stride_dequeue+0x90>
ffffffffc02053be:	01353023          	sd	s3,0(a0)
          b->left = l;
ffffffffc02053c2:	013ab423          	sd	s3,8(s5)
          b->right = r;
ffffffffc02053c6:	019ab823          	sd	s9,16(s5)
          if (l) l->parent = b;
ffffffffc02053ca:	0159b023          	sd	s5,0(s3)
ffffffffc02053ce:	89d6                	mv	s3,s5
          b->left = l;
ffffffffc02053d0:	0134b423          	sd	s3,8(s1)
          b->right = r;
ffffffffc02053d4:	0184b823          	sd	s8,16(s1)
          if (l) l->parent = b;
ffffffffc02053d8:	0099b023          	sd	s1,0(s3)
     if (rep) rep->parent = p;
ffffffffc02053dc:	0144b023          	sd	s4,0(s1)
     
     if (p)
ffffffffc02053e0:	0a0a0863          	beqz	s4,ffffffffc0205490 <stride_dequeue+0x15e>
     {
          if (p->left == b)
ffffffffc02053e4:	008a3703          	ld	a4,8(s4)
     rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc02053e8:	12840793          	addi	a5,s0,296
ffffffffc02053ec:	0af70863          	beq	a4,a5,ffffffffc020549c <stride_dequeue+0x16a>
               p->left = rep;
          else p->right = rep;
ffffffffc02053f0:	009a3823          	sd	s1,16(s4)
     if (rq->proc_num > 0)
ffffffffc02053f4:	01092783          	lw	a5,16(s2)
     rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc02053f8:	01693c23          	sd	s6,24(s2)
     proc->rq = NULL;
ffffffffc02053fc:	10043423          	sd	zero,264(s0)
     if (rq->proc_num > 0)
ffffffffc0205400:	c781                	beqz	a5,ffffffffc0205408 <stride_dequeue+0xd6>
          rq->proc_num--;
ffffffffc0205402:	37fd                	addiw	a5,a5,-1
ffffffffc0205404:	00f92823          	sw	a5,16(s2)
}
ffffffffc0205408:	60e6                	ld	ra,88(sp)
ffffffffc020540a:	6446                	ld	s0,80(sp)
ffffffffc020540c:	64a6                	ld	s1,72(sp)
ffffffffc020540e:	6906                	ld	s2,64(sp)
ffffffffc0205410:	79e2                	ld	s3,56(sp)
ffffffffc0205412:	7a42                	ld	s4,48(sp)
ffffffffc0205414:	7aa2                	ld	s5,40(sp)
ffffffffc0205416:	7b02                	ld	s6,32(sp)
ffffffffc0205418:	6be2                	ld	s7,24(sp)
ffffffffc020541a:	6c42                	ld	s8,16(sp)
ffffffffc020541c:	6ca2                	ld	s9,8(sp)
ffffffffc020541e:	6d02                	ld	s10,0(sp)
ffffffffc0205420:	6125                	addi	sp,sp,96
ffffffffc0205422:	8082                	ret
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205424:	0109ba83          	ld	s5,16(s3)
          r = a->left;
ffffffffc0205428:	0089bc03          	ld	s8,8(s3)
     if (a == NULL) return b;
ffffffffc020542c:	040a8863          	beqz	s5,ffffffffc020547c <stride_dequeue+0x14a>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc0205430:	018aa783          	lw	a5,24(s5)
     else if (c == 0)
ffffffffc0205434:	40e7873b          	subw	a4,a5,a4
ffffffffc0205438:	0a074a63          	bltz	a4,ffffffffc02054ec <stride_dequeue+0x1ba>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc020543c:	0104bb83          	ld	s7,16(s1)
          r = b->left;
ffffffffc0205440:	0084bc83          	ld	s9,8(s1)
     else if (b == NULL) return a;
ffffffffc0205444:	020b8663          	beqz	s7,ffffffffc0205470 <stride_dequeue+0x13e>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc0205448:	018ba703          	lw	a4,24(s7)
     else if (c == 0)
ffffffffc020544c:	9f99                	subw	a5,a5,a4
ffffffffc020544e:	0c07cf63          	bltz	a5,ffffffffc020552c <stride_dequeue+0x1fa>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205452:	010bb583          	ld	a1,16(s7)
          r = b->left;
ffffffffc0205456:	008bbd03          	ld	s10,8(s7)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc020545a:	8556                	mv	a0,s5
ffffffffc020545c:	d1dff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc0205460:	00abb423          	sd	a0,8(s7)
          b->right = r;
ffffffffc0205464:	01abb823          	sd	s10,16(s7)
          if (l) l->parent = b;
ffffffffc0205468:	8ade                	mv	s5,s7
ffffffffc020546a:	c119                	beqz	a0,ffffffffc0205470 <stride_dequeue+0x13e>
ffffffffc020546c:	01553023          	sd	s5,0(a0)
          b->left = l;
ffffffffc0205470:	0154b423          	sd	s5,8(s1)
          b->right = r;
ffffffffc0205474:	0194b823          	sd	s9,16(s1)
          if (l) l->parent = b;
ffffffffc0205478:	009ab023          	sd	s1,0(s5)
          a->left = l;
ffffffffc020547c:	0099b423          	sd	s1,8(s3)
          a->right = r;
ffffffffc0205480:	0189b823          	sd	s8,16(s3)
          if (l) l->parent = a;
ffffffffc0205484:	0134b023          	sd	s3,0(s1)
ffffffffc0205488:	84ce                	mv	s1,s3
     if (rep) rep->parent = p;
ffffffffc020548a:	0144b023          	sd	s4,0(s1)
ffffffffc020548e:	bf89                	j	ffffffffc02053e0 <stride_dequeue+0xae>
ffffffffc0205490:	8b26                	mv	s6,s1
ffffffffc0205492:	b78d                	j	ffffffffc02053f4 <stride_dequeue+0xc2>
ffffffffc0205494:	d4b1                	beqz	s1,ffffffffc02053e0 <stride_dequeue+0xae>
ffffffffc0205496:	0144b023          	sd	s4,0(s1)
ffffffffc020549a:	b799                	j	ffffffffc02053e0 <stride_dequeue+0xae>
               p->left = rep;
ffffffffc020549c:	009a3423          	sd	s1,8(s4)
ffffffffc02054a0:	bf91                	j	ffffffffc02053f4 <stride_dequeue+0xc2>
ffffffffc02054a2:	84ce                	mv	s1,s3
     if (rep) rep->parent = p;
ffffffffc02054a4:	0144b023          	sd	s4,0(s1)
ffffffffc02054a8:	bf25                	j	ffffffffc02053e0 <stride_dequeue+0xae>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02054aa:	0109bb83          	ld	s7,16(s3)
          r = a->left;
ffffffffc02054ae:	0089bc83          	ld	s9,8(s3)
     if (a == NULL) return b;
ffffffffc02054b2:	020b8663          	beqz	s7,ffffffffc02054de <stride_dequeue+0x1ac>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02054b6:	018ba783          	lw	a5,24(s7)
     else if (c == 0)
ffffffffc02054ba:	40e7873b          	subw	a4,a5,a4
ffffffffc02054be:	04074763          	bltz	a4,ffffffffc020550c <stride_dequeue+0x1da>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02054c2:	010ab583          	ld	a1,16(s5)
          r = b->left;
ffffffffc02054c6:	008abd03          	ld	s10,8(s5)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02054ca:	855e                	mv	a0,s7
ffffffffc02054cc:	cadff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc02054d0:	00aab423          	sd	a0,8(s5)
          b->right = r;
ffffffffc02054d4:	01aab823          	sd	s10,16(s5)
          if (l) l->parent = b;
ffffffffc02054d8:	c119                	beqz	a0,ffffffffc02054de <stride_dequeue+0x1ac>
ffffffffc02054da:	01553023          	sd	s5,0(a0)
          a->left = l;
ffffffffc02054de:	0159b423          	sd	s5,8(s3)
          a->right = r;
ffffffffc02054e2:	0199b823          	sd	s9,16(s3)
          if (l) l->parent = a;
ffffffffc02054e6:	013ab023          	sd	s3,0(s5)
ffffffffc02054ea:	b5dd                	j	ffffffffc02053d0 <stride_dequeue+0x9e>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02054ec:	010ab503          	ld	a0,16(s5)
          r = a->left;
ffffffffc02054f0:	008abb83          	ld	s7,8(s5)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02054f4:	85a6                	mv	a1,s1
ffffffffc02054f6:	c83ff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc02054fa:	00aab423          	sd	a0,8(s5)
          a->right = r;
ffffffffc02054fe:	017ab823          	sd	s7,16(s5)
          if (l) l->parent = a;
ffffffffc0205502:	84d6                	mv	s1,s5
ffffffffc0205504:	dd25                	beqz	a0,ffffffffc020547c <stride_dequeue+0x14a>
ffffffffc0205506:	01553023          	sd	s5,0(a0)
ffffffffc020550a:	bf8d                	j	ffffffffc020547c <stride_dequeue+0x14a>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020550c:	010bb503          	ld	a0,16(s7)
          r = a->left;
ffffffffc0205510:	008bbd03          	ld	s10,8(s7)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205514:	85d6                	mv	a1,s5
ffffffffc0205516:	c63ff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc020551a:	00abb423          	sd	a0,8(s7)
          a->right = r;
ffffffffc020551e:	01abb823          	sd	s10,16(s7)
          if (l) l->parent = a;
ffffffffc0205522:	8ade                	mv	s5,s7
ffffffffc0205524:	dd4d                	beqz	a0,ffffffffc02054de <stride_dequeue+0x1ac>
          if (l) l->parent = b;
ffffffffc0205526:	01553023          	sd	s5,0(a0)
ffffffffc020552a:	bf55                	j	ffffffffc02054de <stride_dequeue+0x1ac>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020552c:	010ab503          	ld	a0,16(s5)
          r = a->left;
ffffffffc0205530:	008abd03          	ld	s10,8(s5)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205534:	85de                	mv	a1,s7
ffffffffc0205536:	c43ff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc020553a:	00aab423          	sd	a0,8(s5)
          a->right = r;
ffffffffc020553e:	01aab823          	sd	s10,16(s5)
          if (l) l->parent = a;
ffffffffc0205542:	d51d                	beqz	a0,ffffffffc0205470 <stride_dequeue+0x13e>
          if (l) l->parent = b;
ffffffffc0205544:	01553023          	sd	s5,0(a0)
ffffffffc0205548:	b725                	j	ffffffffc0205470 <stride_dequeue+0x13e>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020554a:	0109b503          	ld	a0,16(s3)
          r = a->left;
ffffffffc020554e:	0089bd03          	ld	s10,8(s3)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205552:	85de                	mv	a1,s7
ffffffffc0205554:	c25ff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205558:	00a9b423          	sd	a0,8(s3)
          a->right = r;
ffffffffc020555c:	01a9b823          	sd	s10,16(s3)
          if (l) l->parent = a;
ffffffffc0205560:	e4051fe3          	bnez	a0,ffffffffc02053be <stride_dequeue+0x8c>
ffffffffc0205564:	bdb9                	j	ffffffffc02053c2 <stride_dequeue+0x90>

ffffffffc0205566 <stride_enqueue>:
     if (proc->lab6_priority == 0)
ffffffffc0205566:	1445a783          	lw	a5,324(a1)
{
ffffffffc020556a:	7179                	addi	sp,sp,-48
ffffffffc020556c:	f022                	sd	s0,32(sp)
ffffffffc020556e:	f406                	sd	ra,40(sp)
ffffffffc0205570:	ec26                	sd	s1,24(sp)
ffffffffc0205572:	e84a                	sd	s2,16(sp)
ffffffffc0205574:	e44e                	sd	s3,8(sp)
ffffffffc0205576:	e052                	sd	s4,0(sp)
ffffffffc0205578:	842a                	mv	s0,a0
     if (proc->lab6_priority == 0)
ffffffffc020557a:	e781                	bnez	a5,ffffffffc0205582 <stride_enqueue+0x1c>
          proc->lab6_priority = 1;
ffffffffc020557c:	4785                	li	a5,1
ffffffffc020557e:	14f5a223          	sw	a5,324(a1)
     if (proc->time_slice <= 0 || proc->time_slice > rq->max_time_slice)
ffffffffc0205582:	1205a783          	lw	a5,288(a1)
ffffffffc0205586:	4858                	lw	a4,20(s0)
ffffffffc0205588:	04f05563          	blez	a5,ffffffffc02055d2 <stride_enqueue+0x6c>
ffffffffc020558c:	04f74363          	blt	a4,a5,ffffffffc02055d2 <stride_enqueue+0x6c>
     rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc0205590:	6c04                	ld	s1,24(s0)
     proc->rq = rq;
ffffffffc0205592:	1085b423          	sd	s0,264(a1)
     a->left = a->right = a->parent = NULL;
ffffffffc0205596:	1205b423          	sd	zero,296(a1)
ffffffffc020559a:	1205bc23          	sd	zero,312(a1)
ffffffffc020559e:	1205b823          	sd	zero,304(a1)
     rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc02055a2:	12858713          	addi	a4,a1,296
     if (a == NULL) return b;
ffffffffc02055a6:	c891                	beqz	s1,ffffffffc02055ba <stride_enqueue+0x54>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02055a8:	1405a683          	lw	a3,320(a1)
ffffffffc02055ac:	4c9c                	lw	a5,24(s1)
     else if (c == 0)
ffffffffc02055ae:	9f95                	subw	a5,a5,a3
ffffffffc02055b0:	0207c463          	bltz	a5,ffffffffc02055d8 <stride_enqueue+0x72>
          b->left = l;
ffffffffc02055b4:	1295b823          	sd	s1,304(a1)
          if (l) l->parent = b;
ffffffffc02055b8:	e098                	sd	a4,0(s1)
     rq->proc_num++;
ffffffffc02055ba:	481c                	lw	a5,16(s0)
}
ffffffffc02055bc:	70a2                	ld	ra,40(sp)
     rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc02055be:	ec18                	sd	a4,24(s0)
     rq->proc_num++;
ffffffffc02055c0:	2785                	addiw	a5,a5,1
ffffffffc02055c2:	c81c                	sw	a5,16(s0)
}
ffffffffc02055c4:	7402                	ld	s0,32(sp)
ffffffffc02055c6:	64e2                	ld	s1,24(sp)
ffffffffc02055c8:	6942                	ld	s2,16(sp)
ffffffffc02055ca:	69a2                	ld	s3,8(sp)
ffffffffc02055cc:	6a02                	ld	s4,0(sp)
ffffffffc02055ce:	6145                	addi	sp,sp,48
ffffffffc02055d0:	8082                	ret
          proc->time_slice = rq->max_time_slice;
ffffffffc02055d2:	12e5a023          	sw	a4,288(a1)
ffffffffc02055d6:	bf6d                	j	ffffffffc0205590 <stride_enqueue+0x2a>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02055d8:	0104b903          	ld	s2,16(s1)
          r = a->left;
ffffffffc02055dc:	0084b983          	ld	s3,8(s1)
     if (a == NULL) return b;
ffffffffc02055e0:	00090c63          	beqz	s2,ffffffffc02055f8 <stride_enqueue+0x92>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02055e4:	01892783          	lw	a5,24(s2)
     else if (c == 0)
ffffffffc02055e8:	40d786bb          	subw	a3,a5,a3
ffffffffc02055ec:	0006cc63          	bltz	a3,ffffffffc0205604 <stride_enqueue+0x9e>
          b->left = l;
ffffffffc02055f0:	1325b823          	sd	s2,304(a1)
          if (l) l->parent = b;
ffffffffc02055f4:	00e93023          	sd	a4,0(s2)
          a->left = l;
ffffffffc02055f8:	e498                	sd	a4,8(s1)
          a->right = r;
ffffffffc02055fa:	0134b823          	sd	s3,16(s1)
          if (l) l->parent = a;
ffffffffc02055fe:	e304                	sd	s1,0(a4)
ffffffffc0205600:	8726                	mv	a4,s1
ffffffffc0205602:	bf65                	j	ffffffffc02055ba <stride_enqueue+0x54>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205604:	01093503          	ld	a0,16(s2)
          r = a->left;
ffffffffc0205608:	00893a03          	ld	s4,8(s2)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020560c:	85ba                	mv	a1,a4
ffffffffc020560e:	b6bff0ef          	jal	ra,ffffffffc0205178 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205612:	00a93423          	sd	a0,8(s2)
          a->right = r;
ffffffffc0205616:	01493823          	sd	s4,16(s2)
          if (l) l->parent = a;
ffffffffc020561a:	874a                	mv	a4,s2
ffffffffc020561c:	dd71                	beqz	a0,ffffffffc02055f8 <stride_enqueue+0x92>
ffffffffc020561e:	01253023          	sd	s2,0(a0)
ffffffffc0205622:	bfd9                	j	ffffffffc02055f8 <stride_enqueue+0x92>

ffffffffc0205624 <sched_class_proc_tick>:
    return sched_class->pick_next(rq);
}

void sched_class_proc_tick(struct proc_struct *proc)
{
    if (proc != idleproc)
ffffffffc0205624:	000cc797          	auipc	a5,0xcc
ffffffffc0205628:	65c7b783          	ld	a5,1628(a5) # ffffffffc02d1c80 <idleproc>
{
ffffffffc020562c:	85aa                	mv	a1,a0
    if (proc != idleproc)
ffffffffc020562e:	00a78c63          	beq	a5,a0,ffffffffc0205646 <sched_class_proc_tick+0x22>
    {
        sched_class->proc_tick(rq, proc);
ffffffffc0205632:	000cc797          	auipc	a5,0xcc
ffffffffc0205636:	66e7b783          	ld	a5,1646(a5) # ffffffffc02d1ca0 <sched_class>
ffffffffc020563a:	779c                	ld	a5,40(a5)
ffffffffc020563c:	000cc517          	auipc	a0,0xcc
ffffffffc0205640:	65c53503          	ld	a0,1628(a0) # ffffffffc02d1c98 <rq>
ffffffffc0205644:	8782                	jr	a5
    }
    else
    {
        proc->need_resched = 1;
ffffffffc0205646:	4705                	li	a4,1
ffffffffc0205648:	ef98                	sd	a4,24(a5)
    }
}
ffffffffc020564a:	8082                	ret

ffffffffc020564c <sched_init>:

static struct run_queue __rq;

void sched_init(void)
{
ffffffffc020564c:	1141                	addi	sp,sp,-16
#elif defined(USE_SCHED_SJF)
    sched_class = &sjf_sched_class;
#elif defined(USE_SCHED_RR)
    sched_class = &default_sched_class;
#else
    sched_class = &stride_sched_class;
ffffffffc020564e:	000c8717          	auipc	a4,0xc8
ffffffffc0205652:	13270713          	addi	a4,a4,306 # ffffffffc02cd780 <stride_sched_class>
{
ffffffffc0205656:	e022                	sd	s0,0(sp)
ffffffffc0205658:	e406                	sd	ra,8(sp)
ffffffffc020565a:	000cc797          	auipc	a5,0xcc
ffffffffc020565e:	5ae78793          	addi	a5,a5,1454 # ffffffffc02d1c08 <timer_list>
#endif

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);
ffffffffc0205662:	6714                	ld	a3,8(a4)
    rq = &__rq;
ffffffffc0205664:	000cc517          	auipc	a0,0xcc
ffffffffc0205668:	58450513          	addi	a0,a0,1412 # ffffffffc02d1be8 <__rq>
ffffffffc020566c:	e79c                	sd	a5,8(a5)
ffffffffc020566e:	e39c                	sd	a5,0(a5)
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc0205670:	4795                	li	a5,5
ffffffffc0205672:	c95c                	sw	a5,20(a0)
    sched_class = &stride_sched_class;
ffffffffc0205674:	000cc417          	auipc	s0,0xcc
ffffffffc0205678:	62c40413          	addi	s0,s0,1580 # ffffffffc02d1ca0 <sched_class>
    rq = &__rq;
ffffffffc020567c:	000cc797          	auipc	a5,0xcc
ffffffffc0205680:	60a7be23          	sd	a0,1564(a5) # ffffffffc02d1c98 <rq>
    sched_class = &stride_sched_class;
ffffffffc0205684:	e018                	sd	a4,0(s0)
    sched_class->init(rq);
ffffffffc0205686:	9682                	jalr	a3

    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205688:	601c                	ld	a5,0(s0)
}
ffffffffc020568a:	6402                	ld	s0,0(sp)
ffffffffc020568c:	60a2                	ld	ra,8(sp)
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc020568e:	638c                	ld	a1,0(a5)
ffffffffc0205690:	00002517          	auipc	a0,0x2
ffffffffc0205694:	3f850513          	addi	a0,a0,1016 # ffffffffc0207a88 <default_pmm_manager+0xe58>
}
ffffffffc0205698:	0141                	addi	sp,sp,16
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc020569a:	afffa06f          	j	ffffffffc0200198 <cprintf>

ffffffffc020569e <wakeup_proc>:

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020569e:	4118                	lw	a4,0(a0)
{
ffffffffc02056a0:	1101                	addi	sp,sp,-32
ffffffffc02056a2:	ec06                	sd	ra,24(sp)
ffffffffc02056a4:	e822                	sd	s0,16(sp)
ffffffffc02056a6:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02056a8:	478d                	li	a5,3
ffffffffc02056aa:	08f70363          	beq	a4,a5,ffffffffc0205730 <wakeup_proc+0x92>
ffffffffc02056ae:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02056b0:	100027f3          	csrr	a5,sstatus
ffffffffc02056b4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02056b6:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02056b8:	e7bd                	bnez	a5,ffffffffc0205726 <wakeup_proc+0x88>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02056ba:	4789                	li	a5,2
ffffffffc02056bc:	04f70863          	beq	a4,a5,ffffffffc020570c <wakeup_proc+0x6e>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc02056c0:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc02056c2:	0e042623          	sw	zero,236(s0)
            if (proc != current)
ffffffffc02056c6:	000cc797          	auipc	a5,0xcc
ffffffffc02056ca:	5b27b783          	ld	a5,1458(a5) # ffffffffc02d1c78 <current>
ffffffffc02056ce:	02878363          	beq	a5,s0,ffffffffc02056f4 <wakeup_proc+0x56>
    if (proc != idleproc)
ffffffffc02056d2:	000cc797          	auipc	a5,0xcc
ffffffffc02056d6:	5ae7b783          	ld	a5,1454(a5) # ffffffffc02d1c80 <idleproc>
ffffffffc02056da:	00f40d63          	beq	s0,a5,ffffffffc02056f4 <wakeup_proc+0x56>
        sched_class->enqueue(rq, proc);
ffffffffc02056de:	000cc797          	auipc	a5,0xcc
ffffffffc02056e2:	5c27b783          	ld	a5,1474(a5) # ffffffffc02d1ca0 <sched_class>
ffffffffc02056e6:	6b9c                	ld	a5,16(a5)
ffffffffc02056e8:	85a2                	mv	a1,s0
ffffffffc02056ea:	000cc517          	auipc	a0,0xcc
ffffffffc02056ee:	5ae53503          	ld	a0,1454(a0) # ffffffffc02d1c98 <rq>
ffffffffc02056f2:	9782                	jalr	a5
    if (flag)
ffffffffc02056f4:	e491                	bnez	s1,ffffffffc0205700 <wakeup_proc+0x62>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02056f6:	60e2                	ld	ra,24(sp)
ffffffffc02056f8:	6442                	ld	s0,16(sp)
ffffffffc02056fa:	64a2                	ld	s1,8(sp)
ffffffffc02056fc:	6105                	addi	sp,sp,32
ffffffffc02056fe:	8082                	ret
ffffffffc0205700:	6442                	ld	s0,16(sp)
ffffffffc0205702:	60e2                	ld	ra,24(sp)
ffffffffc0205704:	64a2                	ld	s1,8(sp)
ffffffffc0205706:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205708:	aa0fb06f          	j	ffffffffc02009a8 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc020570c:	00002617          	auipc	a2,0x2
ffffffffc0205710:	3cc60613          	addi	a2,a2,972 # ffffffffc0207ad8 <default_pmm_manager+0xea8>
ffffffffc0205714:	05a00593          	li	a1,90
ffffffffc0205718:	00002517          	auipc	a0,0x2
ffffffffc020571c:	3a850513          	addi	a0,a0,936 # ffffffffc0207ac0 <default_pmm_manager+0xe90>
ffffffffc0205720:	ddbfa0ef          	jal	ra,ffffffffc02004fa <__warn>
ffffffffc0205724:	bfc1                	j	ffffffffc02056f4 <wakeup_proc+0x56>
        intr_disable();
ffffffffc0205726:	a88fb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc020572a:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc020572c:	4485                	li	s1,1
ffffffffc020572e:	b771                	j	ffffffffc02056ba <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205730:	00002697          	auipc	a3,0x2
ffffffffc0205734:	37068693          	addi	a3,a3,880 # ffffffffc0207aa0 <default_pmm_manager+0xe70>
ffffffffc0205738:	00001617          	auipc	a2,0x1
ffffffffc020573c:	14860613          	addi	a2,a2,328 # ffffffffc0206880 <commands+0x838>
ffffffffc0205740:	04b00593          	li	a1,75
ffffffffc0205744:	00002517          	auipc	a0,0x2
ffffffffc0205748:	37c50513          	addi	a0,a0,892 # ffffffffc0207ac0 <default_pmm_manager+0xe90>
ffffffffc020574c:	d47fa0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0205750 <schedule>:

void schedule(void)
{
ffffffffc0205750:	7179                	addi	sp,sp,-48
ffffffffc0205752:	f406                	sd	ra,40(sp)
ffffffffc0205754:	f022                	sd	s0,32(sp)
ffffffffc0205756:	ec26                	sd	s1,24(sp)
ffffffffc0205758:	e84a                	sd	s2,16(sp)
ffffffffc020575a:	e44e                	sd	s3,8(sp)
ffffffffc020575c:	e052                	sd	s4,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020575e:	100027f3          	csrr	a5,sstatus
ffffffffc0205762:	8b89                	andi	a5,a5,2
ffffffffc0205764:	4a01                	li	s4,0
ffffffffc0205766:	e3cd                	bnez	a5,ffffffffc0205808 <schedule+0xb8>
    bool intr_flag;
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205768:	000cc497          	auipc	s1,0xcc
ffffffffc020576c:	51048493          	addi	s1,s1,1296 # ffffffffc02d1c78 <current>
ffffffffc0205770:	608c                	ld	a1,0(s1)
        sched_class->enqueue(rq, proc);
ffffffffc0205772:	000cc997          	auipc	s3,0xcc
ffffffffc0205776:	52e98993          	addi	s3,s3,1326 # ffffffffc02d1ca0 <sched_class>
ffffffffc020577a:	000cc917          	auipc	s2,0xcc
ffffffffc020577e:	51e90913          	addi	s2,s2,1310 # ffffffffc02d1c98 <rq>
        if (current->state == PROC_RUNNABLE)
ffffffffc0205782:	4194                	lw	a3,0(a1)
        current->need_resched = 0;
ffffffffc0205784:	0005bc23          	sd	zero,24(a1)
        if (current->state == PROC_RUNNABLE)
ffffffffc0205788:	4709                	li	a4,2
        sched_class->enqueue(rq, proc);
ffffffffc020578a:	0009b783          	ld	a5,0(s3)
ffffffffc020578e:	00093503          	ld	a0,0(s2)
        if (current->state == PROC_RUNNABLE)
ffffffffc0205792:	04e68e63          	beq	a3,a4,ffffffffc02057ee <schedule+0x9e>
    return sched_class->pick_next(rq);
ffffffffc0205796:	739c                	ld	a5,32(a5)
ffffffffc0205798:	9782                	jalr	a5
ffffffffc020579a:	842a                	mv	s0,a0
        {
            sched_class_enqueue(current);
        }
        if ((next = sched_class_pick_next()) != NULL)
ffffffffc020579c:	c521                	beqz	a0,ffffffffc02057e4 <schedule+0x94>
    sched_class->dequeue(rq, proc);
ffffffffc020579e:	0009b783          	ld	a5,0(s3)
ffffffffc02057a2:	00093503          	ld	a0,0(s2)
ffffffffc02057a6:	85a2                	mv	a1,s0
ffffffffc02057a8:	6f9c                	ld	a5,24(a5)
ffffffffc02057aa:	9782                	jalr	a5
        }
        if (next == NULL)
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02057ac:	441c                	lw	a5,8(s0)
        if (next != current)
ffffffffc02057ae:	6098                	ld	a4,0(s1)
        next->runs++;
ffffffffc02057b0:	2785                	addiw	a5,a5,1
ffffffffc02057b2:	c41c                	sw	a5,8(s0)
        if (next != current)
ffffffffc02057b4:	00870563          	beq	a4,s0,ffffffffc02057be <schedule+0x6e>
        {
            proc_run(next);
ffffffffc02057b8:	8522                	mv	a0,s0
ffffffffc02057ba:	fc6fe0ef          	jal	ra,ffffffffc0203f80 <proc_run>
    if (flag)
ffffffffc02057be:	000a1a63          	bnez	s4,ffffffffc02057d2 <schedule+0x82>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02057c2:	70a2                	ld	ra,40(sp)
ffffffffc02057c4:	7402                	ld	s0,32(sp)
ffffffffc02057c6:	64e2                	ld	s1,24(sp)
ffffffffc02057c8:	6942                	ld	s2,16(sp)
ffffffffc02057ca:	69a2                	ld	s3,8(sp)
ffffffffc02057cc:	6a02                	ld	s4,0(sp)
ffffffffc02057ce:	6145                	addi	sp,sp,48
ffffffffc02057d0:	8082                	ret
ffffffffc02057d2:	7402                	ld	s0,32(sp)
ffffffffc02057d4:	70a2                	ld	ra,40(sp)
ffffffffc02057d6:	64e2                	ld	s1,24(sp)
ffffffffc02057d8:	6942                	ld	s2,16(sp)
ffffffffc02057da:	69a2                	ld	s3,8(sp)
ffffffffc02057dc:	6a02                	ld	s4,0(sp)
ffffffffc02057de:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc02057e0:	9c8fb06f          	j	ffffffffc02009a8 <intr_enable>
            next = idleproc;
ffffffffc02057e4:	000cc417          	auipc	s0,0xcc
ffffffffc02057e8:	49c43403          	ld	s0,1180(s0) # ffffffffc02d1c80 <idleproc>
ffffffffc02057ec:	b7c1                	j	ffffffffc02057ac <schedule+0x5c>
    if (proc != idleproc)
ffffffffc02057ee:	000cc717          	auipc	a4,0xcc
ffffffffc02057f2:	49273703          	ld	a4,1170(a4) # ffffffffc02d1c80 <idleproc>
ffffffffc02057f6:	fae580e3          	beq	a1,a4,ffffffffc0205796 <schedule+0x46>
        sched_class->enqueue(rq, proc);
ffffffffc02057fa:	6b9c                	ld	a5,16(a5)
ffffffffc02057fc:	9782                	jalr	a5
    return sched_class->pick_next(rq);
ffffffffc02057fe:	0009b783          	ld	a5,0(s3)
ffffffffc0205802:	00093503          	ld	a0,0(s2)
ffffffffc0205806:	bf41                	j	ffffffffc0205796 <schedule+0x46>
        intr_disable();
ffffffffc0205808:	9a6fb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc020580c:	4a05                	li	s4,1
ffffffffc020580e:	bfa9                	j	ffffffffc0205768 <schedule+0x18>

ffffffffc0205810 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205810:	000cc797          	auipc	a5,0xcc
ffffffffc0205814:	4687b783          	ld	a5,1128(a5) # ffffffffc02d1c78 <current>
}
ffffffffc0205818:	43c8                	lw	a0,4(a5)
ffffffffc020581a:	8082                	ret

ffffffffc020581c <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc020581c:	4501                	li	a0,0
ffffffffc020581e:	8082                	ret

ffffffffc0205820 <sys_gettime>:
static int sys_gettime(uint64_t arg[]){
    return (int)ticks*10;
ffffffffc0205820:	000cc797          	auipc	a5,0xcc
ffffffffc0205824:	4007b783          	ld	a5,1024(a5) # ffffffffc02d1c20 <ticks>
ffffffffc0205828:	0027951b          	slliw	a0,a5,0x2
ffffffffc020582c:	9d3d                	addw	a0,a0,a5
}
ffffffffc020582e:	0015151b          	slliw	a0,a0,0x1
ffffffffc0205832:	8082                	ret

ffffffffc0205834 <sys_lab6_set_priority>:
static int sys_lab6_set_priority(uint64_t arg[]){
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
ffffffffc0205834:	4108                	lw	a0,0(a0)
static int sys_lab6_set_priority(uint64_t arg[]){
ffffffffc0205836:	1141                	addi	sp,sp,-16
ffffffffc0205838:	e406                	sd	ra,8(sp)
    lab6_set_priority(priority);
ffffffffc020583a:	855ff0ef          	jal	ra,ffffffffc020508e <lab6_set_priority>
    return 0;
}
ffffffffc020583e:	60a2                	ld	ra,8(sp)
ffffffffc0205840:	4501                	li	a0,0
ffffffffc0205842:	0141                	addi	sp,sp,16
ffffffffc0205844:	8082                	ret

ffffffffc0205846 <sys_putc>:
    cputchar(c);
ffffffffc0205846:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205848:	1141                	addi	sp,sp,-16
ffffffffc020584a:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc020584c:	983fa0ef          	jal	ra,ffffffffc02001ce <cputchar>
}
ffffffffc0205850:	60a2                	ld	ra,8(sp)
ffffffffc0205852:	4501                	li	a0,0
ffffffffc0205854:	0141                	addi	sp,sp,16
ffffffffc0205856:	8082                	ret

ffffffffc0205858 <sys_kill>:
    return do_kill(pid);
ffffffffc0205858:	4108                	lw	a0,0(a0)
ffffffffc020585a:	e06ff06f          	j	ffffffffc0204e60 <do_kill>

ffffffffc020585e <sys_yield>:
    return do_yield();
ffffffffc020585e:	db4ff06f          	j	ffffffffc0204e12 <do_yield>

ffffffffc0205862 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205862:	6d14                	ld	a3,24(a0)
ffffffffc0205864:	6910                	ld	a2,16(a0)
ffffffffc0205866:	650c                	ld	a1,8(a0)
ffffffffc0205868:	6108                	ld	a0,0(a0)
ffffffffc020586a:	ffffe06f          	j	ffffffffc0204868 <do_execve>

ffffffffc020586e <sys_wait>:
    return do_wait(pid, store);
ffffffffc020586e:	650c                	ld	a1,8(a0)
ffffffffc0205870:	4108                	lw	a0,0(a0)
ffffffffc0205872:	db0ff06f          	j	ffffffffc0204e22 <do_wait>

ffffffffc0205876 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205876:	000cc797          	auipc	a5,0xcc
ffffffffc020587a:	4027b783          	ld	a5,1026(a5) # ffffffffc02d1c78 <current>
ffffffffc020587e:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205880:	4501                	li	a0,0
ffffffffc0205882:	6a0c                	ld	a1,16(a2)
ffffffffc0205884:	f60fe06f          	j	ffffffffc0203fe4 <do_fork>

ffffffffc0205888 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205888:	4108                	lw	a0,0(a0)
ffffffffc020588a:	b9ffe06f          	j	ffffffffc0204428 <do_exit>

ffffffffc020588e <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc020588e:	715d                	addi	sp,sp,-80
ffffffffc0205890:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205892:	000cc497          	auipc	s1,0xcc
ffffffffc0205896:	3e648493          	addi	s1,s1,998 # ffffffffc02d1c78 <current>
ffffffffc020589a:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc020589c:	e0a2                	sd	s0,64(sp)
ffffffffc020589e:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02058a0:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02058a2:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02058a4:	0ff00793          	li	a5,255
    int num = tf->gpr.a0;
ffffffffc02058a8:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02058ac:	0327ee63          	bltu	a5,s2,ffffffffc02058e8 <syscall+0x5a>
        if (syscalls[num] != NULL) {
ffffffffc02058b0:	00391713          	slli	a4,s2,0x3
ffffffffc02058b4:	00002797          	auipc	a5,0x2
ffffffffc02058b8:	28c78793          	addi	a5,a5,652 # ffffffffc0207b40 <syscalls>
ffffffffc02058bc:	97ba                	add	a5,a5,a4
ffffffffc02058be:	639c                	ld	a5,0(a5)
ffffffffc02058c0:	c785                	beqz	a5,ffffffffc02058e8 <syscall+0x5a>
            arg[0] = tf->gpr.a1;
ffffffffc02058c2:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02058c4:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc02058c6:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc02058c8:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc02058ca:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc02058cc:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02058ce:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc02058d0:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc02058d2:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc02058d4:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02058d6:	0028                	addi	a0,sp,8
ffffffffc02058d8:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02058da:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02058dc:	e828                	sd	a0,80(s0)
}
ffffffffc02058de:	6406                	ld	s0,64(sp)
ffffffffc02058e0:	74e2                	ld	s1,56(sp)
ffffffffc02058e2:	7942                	ld	s2,48(sp)
ffffffffc02058e4:	6161                	addi	sp,sp,80
ffffffffc02058e6:	8082                	ret
    print_trapframe(tf);
ffffffffc02058e8:	8522                	mv	a0,s0
ffffffffc02058ea:	ab4fb0ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02058ee:	609c                	ld	a5,0(s1)
ffffffffc02058f0:	86ca                	mv	a3,s2
ffffffffc02058f2:	00002617          	auipc	a2,0x2
ffffffffc02058f6:	20660613          	addi	a2,a2,518 # ffffffffc0207af8 <default_pmm_manager+0xec8>
ffffffffc02058fa:	43d8                	lw	a4,4(a5)
ffffffffc02058fc:	06c00593          	li	a1,108
ffffffffc0205900:	0b478793          	addi	a5,a5,180
ffffffffc0205904:	00002517          	auipc	a0,0x2
ffffffffc0205908:	22450513          	addi	a0,a0,548 # ffffffffc0207b28 <default_pmm_manager+0xef8>
ffffffffc020590c:	b87fa0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0205910 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205910:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205914:	2785                	addiw	a5,a5,1
ffffffffc0205916:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc020591a:	02000793          	li	a5,32
ffffffffc020591e:	9f8d                	subw	a5,a5,a1
}
ffffffffc0205920:	00f5553b          	srlw	a0,a0,a5
ffffffffc0205924:	8082                	ret

ffffffffc0205926 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205926:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020592a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020592c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205930:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205932:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205936:	f022                	sd	s0,32(sp)
ffffffffc0205938:	ec26                	sd	s1,24(sp)
ffffffffc020593a:	e84a                	sd	s2,16(sp)
ffffffffc020593c:	f406                	sd	ra,40(sp)
ffffffffc020593e:	e44e                	sd	s3,8(sp)
ffffffffc0205940:	84aa                	mv	s1,a0
ffffffffc0205942:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205944:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0205948:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020594a:	03067e63          	bgeu	a2,a6,ffffffffc0205986 <printnum+0x60>
ffffffffc020594e:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205950:	00805763          	blez	s0,ffffffffc020595e <printnum+0x38>
ffffffffc0205954:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205956:	85ca                	mv	a1,s2
ffffffffc0205958:	854e                	mv	a0,s3
ffffffffc020595a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020595c:	fc65                	bnez	s0,ffffffffc0205954 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020595e:	1a02                	slli	s4,s4,0x20
ffffffffc0205960:	00003797          	auipc	a5,0x3
ffffffffc0205964:	9e078793          	addi	a5,a5,-1568 # ffffffffc0208340 <syscalls+0x800>
ffffffffc0205968:	020a5a13          	srli	s4,s4,0x20
ffffffffc020596c:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020596e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205970:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0205974:	70a2                	ld	ra,40(sp)
ffffffffc0205976:	69a2                	ld	s3,8(sp)
ffffffffc0205978:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020597a:	85ca                	mv	a1,s2
ffffffffc020597c:	87a6                	mv	a5,s1
}
ffffffffc020597e:	6942                	ld	s2,16(sp)
ffffffffc0205980:	64e2                	ld	s1,24(sp)
ffffffffc0205982:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205984:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205986:	03065633          	divu	a2,a2,a6
ffffffffc020598a:	8722                	mv	a4,s0
ffffffffc020598c:	f9bff0ef          	jal	ra,ffffffffc0205926 <printnum>
ffffffffc0205990:	b7f9                	j	ffffffffc020595e <printnum+0x38>

ffffffffc0205992 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205992:	7119                	addi	sp,sp,-128
ffffffffc0205994:	f4a6                	sd	s1,104(sp)
ffffffffc0205996:	f0ca                	sd	s2,96(sp)
ffffffffc0205998:	ecce                	sd	s3,88(sp)
ffffffffc020599a:	e8d2                	sd	s4,80(sp)
ffffffffc020599c:	e4d6                	sd	s5,72(sp)
ffffffffc020599e:	e0da                	sd	s6,64(sp)
ffffffffc02059a0:	fc5e                	sd	s7,56(sp)
ffffffffc02059a2:	f06a                	sd	s10,32(sp)
ffffffffc02059a4:	fc86                	sd	ra,120(sp)
ffffffffc02059a6:	f8a2                	sd	s0,112(sp)
ffffffffc02059a8:	f862                	sd	s8,48(sp)
ffffffffc02059aa:	f466                	sd	s9,40(sp)
ffffffffc02059ac:	ec6e                	sd	s11,24(sp)
ffffffffc02059ae:	892a                	mv	s2,a0
ffffffffc02059b0:	84ae                	mv	s1,a1
ffffffffc02059b2:	8d32                	mv	s10,a2
ffffffffc02059b4:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02059b6:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02059ba:	5b7d                	li	s6,-1
ffffffffc02059bc:	00003a97          	auipc	s5,0x3
ffffffffc02059c0:	9b0a8a93          	addi	s5,s5,-1616 # ffffffffc020836c <syscalls+0x82c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02059c4:	00003b97          	auipc	s7,0x3
ffffffffc02059c8:	bc4b8b93          	addi	s7,s7,-1084 # ffffffffc0208588 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02059cc:	000d4503          	lbu	a0,0(s10)
ffffffffc02059d0:	001d0413          	addi	s0,s10,1
ffffffffc02059d4:	01350a63          	beq	a0,s3,ffffffffc02059e8 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02059d8:	c121                	beqz	a0,ffffffffc0205a18 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02059da:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02059dc:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02059de:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02059e0:	fff44503          	lbu	a0,-1(s0)
ffffffffc02059e4:	ff351ae3          	bne	a0,s3,ffffffffc02059d8 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059e8:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02059ec:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02059f0:	4c81                	li	s9,0
ffffffffc02059f2:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02059f4:	5c7d                	li	s8,-1
ffffffffc02059f6:	5dfd                	li	s11,-1
ffffffffc02059f8:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02059fc:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059fe:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205a02:	0ff5f593          	zext.b	a1,a1
ffffffffc0205a06:	00140d13          	addi	s10,s0,1
ffffffffc0205a0a:	04b56263          	bltu	a0,a1,ffffffffc0205a4e <vprintfmt+0xbc>
ffffffffc0205a0e:	058a                	slli	a1,a1,0x2
ffffffffc0205a10:	95d6                	add	a1,a1,s5
ffffffffc0205a12:	4194                	lw	a3,0(a1)
ffffffffc0205a14:	96d6                	add	a3,a3,s5
ffffffffc0205a16:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205a18:	70e6                	ld	ra,120(sp)
ffffffffc0205a1a:	7446                	ld	s0,112(sp)
ffffffffc0205a1c:	74a6                	ld	s1,104(sp)
ffffffffc0205a1e:	7906                	ld	s2,96(sp)
ffffffffc0205a20:	69e6                	ld	s3,88(sp)
ffffffffc0205a22:	6a46                	ld	s4,80(sp)
ffffffffc0205a24:	6aa6                	ld	s5,72(sp)
ffffffffc0205a26:	6b06                	ld	s6,64(sp)
ffffffffc0205a28:	7be2                	ld	s7,56(sp)
ffffffffc0205a2a:	7c42                	ld	s8,48(sp)
ffffffffc0205a2c:	7ca2                	ld	s9,40(sp)
ffffffffc0205a2e:	7d02                	ld	s10,32(sp)
ffffffffc0205a30:	6de2                	ld	s11,24(sp)
ffffffffc0205a32:	6109                	addi	sp,sp,128
ffffffffc0205a34:	8082                	ret
            padc = '0';
ffffffffc0205a36:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0205a38:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a3c:	846a                	mv	s0,s10
ffffffffc0205a3e:	00140d13          	addi	s10,s0,1
ffffffffc0205a42:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205a46:	0ff5f593          	zext.b	a1,a1
ffffffffc0205a4a:	fcb572e3          	bgeu	a0,a1,ffffffffc0205a0e <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0205a4e:	85a6                	mv	a1,s1
ffffffffc0205a50:	02500513          	li	a0,37
ffffffffc0205a54:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205a56:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205a5a:	8d22                	mv	s10,s0
ffffffffc0205a5c:	f73788e3          	beq	a5,s3,ffffffffc02059cc <vprintfmt+0x3a>
ffffffffc0205a60:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0205a64:	1d7d                	addi	s10,s10,-1
ffffffffc0205a66:	ff379de3          	bne	a5,s3,ffffffffc0205a60 <vprintfmt+0xce>
ffffffffc0205a6a:	b78d                	j	ffffffffc02059cc <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205a6c:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205a70:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a74:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205a76:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205a7a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205a7e:	02d86463          	bltu	a6,a3,ffffffffc0205aa6 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0205a82:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205a86:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205a8a:	0186873b          	addw	a4,a3,s8
ffffffffc0205a8e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205a92:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205a94:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205a98:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205a9a:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205a9e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205aa2:	fed870e3          	bgeu	a6,a3,ffffffffc0205a82 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205aa6:	f40ddce3          	bgez	s11,ffffffffc02059fe <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205aaa:	8de2                	mv	s11,s8
ffffffffc0205aac:	5c7d                	li	s8,-1
ffffffffc0205aae:	bf81                	j	ffffffffc02059fe <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205ab0:	fffdc693          	not	a3,s11
ffffffffc0205ab4:	96fd                	srai	a3,a3,0x3f
ffffffffc0205ab6:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205aba:	00144603          	lbu	a2,1(s0)
ffffffffc0205abe:	2d81                	sext.w	s11,s11
ffffffffc0205ac0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205ac2:	bf35                	j	ffffffffc02059fe <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205ac4:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205ac8:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205acc:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205ace:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205ad0:	bfd9                	j	ffffffffc0205aa6 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0205ad2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205ad4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205ad8:	01174463          	blt	a4,a7,ffffffffc0205ae0 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205adc:	1a088e63          	beqz	a7,ffffffffc0205c98 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0205ae0:	000a3603          	ld	a2,0(s4)
ffffffffc0205ae4:	46c1                	li	a3,16
ffffffffc0205ae6:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205ae8:	2781                	sext.w	a5,a5
ffffffffc0205aea:	876e                	mv	a4,s11
ffffffffc0205aec:	85a6                	mv	a1,s1
ffffffffc0205aee:	854a                	mv	a0,s2
ffffffffc0205af0:	e37ff0ef          	jal	ra,ffffffffc0205926 <printnum>
            break;
ffffffffc0205af4:	bde1                	j	ffffffffc02059cc <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0205af6:	000a2503          	lw	a0,0(s4)
ffffffffc0205afa:	85a6                	mv	a1,s1
ffffffffc0205afc:	0a21                	addi	s4,s4,8
ffffffffc0205afe:	9902                	jalr	s2
            break;
ffffffffc0205b00:	b5f1                	j	ffffffffc02059cc <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205b02:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205b04:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205b08:	01174463          	blt	a4,a7,ffffffffc0205b10 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205b0c:	18088163          	beqz	a7,ffffffffc0205c8e <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0205b10:	000a3603          	ld	a2,0(s4)
ffffffffc0205b14:	46a9                	li	a3,10
ffffffffc0205b16:	8a2e                	mv	s4,a1
ffffffffc0205b18:	bfc1                	j	ffffffffc0205ae8 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205b1a:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0205b1e:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205b20:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205b22:	bdf1                	j	ffffffffc02059fe <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0205b24:	85a6                	mv	a1,s1
ffffffffc0205b26:	02500513          	li	a0,37
ffffffffc0205b2a:	9902                	jalr	s2
            break;
ffffffffc0205b2c:	b545                	j	ffffffffc02059cc <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205b2e:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0205b32:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205b34:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205b36:	b5e1                	j	ffffffffc02059fe <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205b38:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205b3a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205b3e:	01174463          	blt	a4,a7,ffffffffc0205b46 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0205b42:	14088163          	beqz	a7,ffffffffc0205c84 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0205b46:	000a3603          	ld	a2,0(s4)
ffffffffc0205b4a:	46a1                	li	a3,8
ffffffffc0205b4c:	8a2e                	mv	s4,a1
ffffffffc0205b4e:	bf69                	j	ffffffffc0205ae8 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0205b50:	03000513          	li	a0,48
ffffffffc0205b54:	85a6                	mv	a1,s1
ffffffffc0205b56:	e03e                	sd	a5,0(sp)
ffffffffc0205b58:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205b5a:	85a6                	mv	a1,s1
ffffffffc0205b5c:	07800513          	li	a0,120
ffffffffc0205b60:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205b62:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205b64:	6782                	ld	a5,0(sp)
ffffffffc0205b66:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205b68:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205b6c:	bfb5                	j	ffffffffc0205ae8 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205b6e:	000a3403          	ld	s0,0(s4)
ffffffffc0205b72:	008a0713          	addi	a4,s4,8
ffffffffc0205b76:	e03a                	sd	a4,0(sp)
ffffffffc0205b78:	14040263          	beqz	s0,ffffffffc0205cbc <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205b7c:	0fb05763          	blez	s11,ffffffffc0205c6a <vprintfmt+0x2d8>
ffffffffc0205b80:	02d00693          	li	a3,45
ffffffffc0205b84:	0cd79163          	bne	a5,a3,ffffffffc0205c46 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205b88:	00044783          	lbu	a5,0(s0)
ffffffffc0205b8c:	0007851b          	sext.w	a0,a5
ffffffffc0205b90:	cf85                	beqz	a5,ffffffffc0205bc8 <vprintfmt+0x236>
ffffffffc0205b92:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205b96:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205b9a:	000c4563          	bltz	s8,ffffffffc0205ba4 <vprintfmt+0x212>
ffffffffc0205b9e:	3c7d                	addiw	s8,s8,-1
ffffffffc0205ba0:	036c0263          	beq	s8,s6,ffffffffc0205bc4 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205ba4:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205ba6:	0e0c8e63          	beqz	s9,ffffffffc0205ca2 <vprintfmt+0x310>
ffffffffc0205baa:	3781                	addiw	a5,a5,-32
ffffffffc0205bac:	0ef47b63          	bgeu	s0,a5,ffffffffc0205ca2 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205bb0:	03f00513          	li	a0,63
ffffffffc0205bb4:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205bb6:	000a4783          	lbu	a5,0(s4)
ffffffffc0205bba:	3dfd                	addiw	s11,s11,-1
ffffffffc0205bbc:	0a05                	addi	s4,s4,1
ffffffffc0205bbe:	0007851b          	sext.w	a0,a5
ffffffffc0205bc2:	ffe1                	bnez	a5,ffffffffc0205b9a <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205bc4:	01b05963          	blez	s11,ffffffffc0205bd6 <vprintfmt+0x244>
ffffffffc0205bc8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205bca:	85a6                	mv	a1,s1
ffffffffc0205bcc:	02000513          	li	a0,32
ffffffffc0205bd0:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205bd2:	fe0d9be3          	bnez	s11,ffffffffc0205bc8 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205bd6:	6a02                	ld	s4,0(sp)
ffffffffc0205bd8:	bbd5                	j	ffffffffc02059cc <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205bda:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205bdc:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0205be0:	01174463          	blt	a4,a7,ffffffffc0205be8 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205be4:	08088d63          	beqz	a7,ffffffffc0205c7e <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205be8:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205bec:	0a044d63          	bltz	s0,ffffffffc0205ca6 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205bf0:	8622                	mv	a2,s0
ffffffffc0205bf2:	8a66                	mv	s4,s9
ffffffffc0205bf4:	46a9                	li	a3,10
ffffffffc0205bf6:	bdcd                	j	ffffffffc0205ae8 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205bf8:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205bfc:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205bfe:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205c00:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0205c04:	8fb5                	xor	a5,a5,a3
ffffffffc0205c06:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205c0a:	02d74163          	blt	a4,a3,ffffffffc0205c2c <vprintfmt+0x29a>
ffffffffc0205c0e:	00369793          	slli	a5,a3,0x3
ffffffffc0205c12:	97de                	add	a5,a5,s7
ffffffffc0205c14:	639c                	ld	a5,0(a5)
ffffffffc0205c16:	cb99                	beqz	a5,ffffffffc0205c2c <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205c18:	86be                	mv	a3,a5
ffffffffc0205c1a:	00000617          	auipc	a2,0x0
ffffffffc0205c1e:	1ee60613          	addi	a2,a2,494 # ffffffffc0205e08 <etext+0x28>
ffffffffc0205c22:	85a6                	mv	a1,s1
ffffffffc0205c24:	854a                	mv	a0,s2
ffffffffc0205c26:	0ce000ef          	jal	ra,ffffffffc0205cf4 <printfmt>
ffffffffc0205c2a:	b34d                	j	ffffffffc02059cc <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205c2c:	00002617          	auipc	a2,0x2
ffffffffc0205c30:	73460613          	addi	a2,a2,1844 # ffffffffc0208360 <syscalls+0x820>
ffffffffc0205c34:	85a6                	mv	a1,s1
ffffffffc0205c36:	854a                	mv	a0,s2
ffffffffc0205c38:	0bc000ef          	jal	ra,ffffffffc0205cf4 <printfmt>
ffffffffc0205c3c:	bb41                	j	ffffffffc02059cc <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205c3e:	00002417          	auipc	s0,0x2
ffffffffc0205c42:	71a40413          	addi	s0,s0,1818 # ffffffffc0208358 <syscalls+0x818>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205c46:	85e2                	mv	a1,s8
ffffffffc0205c48:	8522                	mv	a0,s0
ffffffffc0205c4a:	e43e                	sd	a5,8(sp)
ffffffffc0205c4c:	0e2000ef          	jal	ra,ffffffffc0205d2e <strnlen>
ffffffffc0205c50:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0205c54:	01b05b63          	blez	s11,ffffffffc0205c6a <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205c58:	67a2                	ld	a5,8(sp)
ffffffffc0205c5a:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205c5e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205c60:	85a6                	mv	a1,s1
ffffffffc0205c62:	8552                	mv	a0,s4
ffffffffc0205c64:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205c66:	fe0d9ce3          	bnez	s11,ffffffffc0205c5e <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205c6a:	00044783          	lbu	a5,0(s0)
ffffffffc0205c6e:	00140a13          	addi	s4,s0,1
ffffffffc0205c72:	0007851b          	sext.w	a0,a5
ffffffffc0205c76:	d3a5                	beqz	a5,ffffffffc0205bd6 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205c78:	05e00413          	li	s0,94
ffffffffc0205c7c:	bf39                	j	ffffffffc0205b9a <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205c7e:	000a2403          	lw	s0,0(s4)
ffffffffc0205c82:	b7ad                	j	ffffffffc0205bec <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205c84:	000a6603          	lwu	a2,0(s4)
ffffffffc0205c88:	46a1                	li	a3,8
ffffffffc0205c8a:	8a2e                	mv	s4,a1
ffffffffc0205c8c:	bdb1                	j	ffffffffc0205ae8 <vprintfmt+0x156>
ffffffffc0205c8e:	000a6603          	lwu	a2,0(s4)
ffffffffc0205c92:	46a9                	li	a3,10
ffffffffc0205c94:	8a2e                	mv	s4,a1
ffffffffc0205c96:	bd89                	j	ffffffffc0205ae8 <vprintfmt+0x156>
ffffffffc0205c98:	000a6603          	lwu	a2,0(s4)
ffffffffc0205c9c:	46c1                	li	a3,16
ffffffffc0205c9e:	8a2e                	mv	s4,a1
ffffffffc0205ca0:	b5a1                	j	ffffffffc0205ae8 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205ca2:	9902                	jalr	s2
ffffffffc0205ca4:	bf09                	j	ffffffffc0205bb6 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205ca6:	85a6                	mv	a1,s1
ffffffffc0205ca8:	02d00513          	li	a0,45
ffffffffc0205cac:	e03e                	sd	a5,0(sp)
ffffffffc0205cae:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205cb0:	6782                	ld	a5,0(sp)
ffffffffc0205cb2:	8a66                	mv	s4,s9
ffffffffc0205cb4:	40800633          	neg	a2,s0
ffffffffc0205cb8:	46a9                	li	a3,10
ffffffffc0205cba:	b53d                	j	ffffffffc0205ae8 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205cbc:	03b05163          	blez	s11,ffffffffc0205cde <vprintfmt+0x34c>
ffffffffc0205cc0:	02d00693          	li	a3,45
ffffffffc0205cc4:	f6d79de3          	bne	a5,a3,ffffffffc0205c3e <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205cc8:	00002417          	auipc	s0,0x2
ffffffffc0205ccc:	69040413          	addi	s0,s0,1680 # ffffffffc0208358 <syscalls+0x818>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205cd0:	02800793          	li	a5,40
ffffffffc0205cd4:	02800513          	li	a0,40
ffffffffc0205cd8:	00140a13          	addi	s4,s0,1
ffffffffc0205cdc:	bd6d                	j	ffffffffc0205b96 <vprintfmt+0x204>
ffffffffc0205cde:	00002a17          	auipc	s4,0x2
ffffffffc0205ce2:	67ba0a13          	addi	s4,s4,1659 # ffffffffc0208359 <syscalls+0x819>
ffffffffc0205ce6:	02800513          	li	a0,40
ffffffffc0205cea:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205cee:	05e00413          	li	s0,94
ffffffffc0205cf2:	b565                	j	ffffffffc0205b9a <vprintfmt+0x208>

ffffffffc0205cf4 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205cf4:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205cf6:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205cfa:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205cfc:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205cfe:	ec06                	sd	ra,24(sp)
ffffffffc0205d00:	f83a                	sd	a4,48(sp)
ffffffffc0205d02:	fc3e                	sd	a5,56(sp)
ffffffffc0205d04:	e0c2                	sd	a6,64(sp)
ffffffffc0205d06:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205d08:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205d0a:	c89ff0ef          	jal	ra,ffffffffc0205992 <vprintfmt>
}
ffffffffc0205d0e:	60e2                	ld	ra,24(sp)
ffffffffc0205d10:	6161                	addi	sp,sp,80
ffffffffc0205d12:	8082                	ret

ffffffffc0205d14 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205d14:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205d18:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205d1a:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205d1c:	cb81                	beqz	a5,ffffffffc0205d2c <strlen+0x18>
        cnt ++;
ffffffffc0205d1e:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0205d20:	00a707b3          	add	a5,a4,a0
ffffffffc0205d24:	0007c783          	lbu	a5,0(a5)
ffffffffc0205d28:	fbfd                	bnez	a5,ffffffffc0205d1e <strlen+0xa>
ffffffffc0205d2a:	8082                	ret
    }
    return cnt;
}
ffffffffc0205d2c:	8082                	ret

ffffffffc0205d2e <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205d2e:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205d30:	e589                	bnez	a1,ffffffffc0205d3a <strnlen+0xc>
ffffffffc0205d32:	a811                	j	ffffffffc0205d46 <strnlen+0x18>
        cnt ++;
ffffffffc0205d34:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205d36:	00f58863          	beq	a1,a5,ffffffffc0205d46 <strnlen+0x18>
ffffffffc0205d3a:	00f50733          	add	a4,a0,a5
ffffffffc0205d3e:	00074703          	lbu	a4,0(a4)
ffffffffc0205d42:	fb6d                	bnez	a4,ffffffffc0205d34 <strnlen+0x6>
ffffffffc0205d44:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205d46:	852e                	mv	a0,a1
ffffffffc0205d48:	8082                	ret

ffffffffc0205d4a <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205d4a:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205d4c:	0005c703          	lbu	a4,0(a1)
ffffffffc0205d50:	0785                	addi	a5,a5,1
ffffffffc0205d52:	0585                	addi	a1,a1,1
ffffffffc0205d54:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205d58:	fb75                	bnez	a4,ffffffffc0205d4c <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205d5a:	8082                	ret

ffffffffc0205d5c <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205d5c:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205d60:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205d64:	cb89                	beqz	a5,ffffffffc0205d76 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205d66:	0505                	addi	a0,a0,1
ffffffffc0205d68:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205d6a:	fee789e3          	beq	a5,a4,ffffffffc0205d5c <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205d6e:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205d72:	9d19                	subw	a0,a0,a4
ffffffffc0205d74:	8082                	ret
ffffffffc0205d76:	4501                	li	a0,0
ffffffffc0205d78:	bfed                	j	ffffffffc0205d72 <strcmp+0x16>

ffffffffc0205d7a <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205d7a:	c20d                	beqz	a2,ffffffffc0205d9c <strncmp+0x22>
ffffffffc0205d7c:	962e                	add	a2,a2,a1
ffffffffc0205d7e:	a031                	j	ffffffffc0205d8a <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205d80:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205d82:	00e79a63          	bne	a5,a4,ffffffffc0205d96 <strncmp+0x1c>
ffffffffc0205d86:	00b60b63          	beq	a2,a1,ffffffffc0205d9c <strncmp+0x22>
ffffffffc0205d8a:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205d8e:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205d90:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205d94:	f7f5                	bnez	a5,ffffffffc0205d80 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205d96:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205d9a:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205d9c:	4501                	li	a0,0
ffffffffc0205d9e:	8082                	ret

ffffffffc0205da0 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205da0:	00054783          	lbu	a5,0(a0)
ffffffffc0205da4:	c799                	beqz	a5,ffffffffc0205db2 <strchr+0x12>
        if (*s == c) {
ffffffffc0205da6:	00f58763          	beq	a1,a5,ffffffffc0205db4 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205daa:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205dae:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205db0:	fbfd                	bnez	a5,ffffffffc0205da6 <strchr+0x6>
    }
    return NULL;
ffffffffc0205db2:	4501                	li	a0,0
}
ffffffffc0205db4:	8082                	ret

ffffffffc0205db6 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205db6:	ca01                	beqz	a2,ffffffffc0205dc6 <memset+0x10>
ffffffffc0205db8:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205dba:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205dbc:	0785                	addi	a5,a5,1
ffffffffc0205dbe:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205dc2:	fec79de3          	bne	a5,a2,ffffffffc0205dbc <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205dc6:	8082                	ret

ffffffffc0205dc8 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205dc8:	ca19                	beqz	a2,ffffffffc0205dde <memcpy+0x16>
ffffffffc0205dca:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205dcc:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205dce:	0005c703          	lbu	a4,0(a1)
ffffffffc0205dd2:	0585                	addi	a1,a1,1
ffffffffc0205dd4:	0785                	addi	a5,a5,1
ffffffffc0205dd6:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205dda:	fec59ae3          	bne	a1,a2,ffffffffc0205dce <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205dde:	8082                	ret
