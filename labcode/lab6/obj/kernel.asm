
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
ffffffffc020004a:	000c2517          	auipc	a0,0xc2
ffffffffc020004e:	6d650513          	addi	a0,a0,1750 # ffffffffc02c2720 <buf>
ffffffffc0200052:	000c7617          	auipc	a2,0xc7
ffffffffc0200056:	bbe60613          	addi	a2,a2,-1090 # ffffffffc02c6c10 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	58f050ef          	jal	ra,ffffffffc0205df0 <memset>
    cons_init(); // init the console
ffffffffc0200066:	520000ef          	jal	ra,ffffffffc0200586 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006a:	00006597          	auipc	a1,0x6
ffffffffc020006e:	db658593          	addi	a1,a1,-586 # ffffffffc0205e20 <etext+0x6>
ffffffffc0200072:	00006517          	auipc	a0,0x6
ffffffffc0200076:	dce50513          	addi	a0,a0,-562 # ffffffffc0205e40 <etext+0x26>
ffffffffc020007a:	11e000ef          	jal	ra,ffffffffc0200198 <cprintf>

    print_kerninfo();
ffffffffc020007e:	1a2000ef          	jal	ra,ffffffffc0200220 <print_kerninfo>

    // grade_backtrace();

    dtb_init(); // init dtb
ffffffffc0200082:	576000ef          	jal	ra,ffffffffc02005f8 <dtb_init>

    pmm_init(); // init physical memory management
ffffffffc0200086:	674020ef          	jal	ra,ffffffffc02026fa <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	12b000ef          	jal	ra,ffffffffc02009b4 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	129000ef          	jal	ra,ffffffffc02009b6 <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc0200092:	077030ef          	jal	ra,ffffffffc0203908 <vmm_init>
    sched_init();
ffffffffc0200096:	5f0050ef          	jal	ra,ffffffffc0205686 <sched_init>
    proc_init(); // init process table
ffffffffc020009a:	67d040ef          	jal	ra,ffffffffc0204f16 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009e:	4a0000ef          	jal	ra,ffffffffc020053e <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000a2:	107000ef          	jal	ra,ffffffffc02009a8 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a6:	008050ef          	jal	ra,ffffffffc02050ae <cpu_idle>

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
ffffffffc02000c4:	d8850513          	addi	a0,a0,-632 # ffffffffc0205e48 <etext+0x2e>
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
ffffffffc02000d6:	000c2b97          	auipc	s7,0xc2
ffffffffc02000da:	64ab8b93          	addi	s7,s7,1610 # ffffffffc02c2720 <buf>
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
ffffffffc0200132:	000c2517          	auipc	a0,0xc2
ffffffffc0200136:	5ee50513          	addi	a0,a0,1518 # ffffffffc02c2720 <buf>
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
ffffffffc020018c:	041050ef          	jal	ra,ffffffffc02059cc <vprintfmt>
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
ffffffffc02001c2:	00b050ef          	jal	ra,ffffffffc02059cc <vprintfmt>
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
ffffffffc0200226:	c2e50513          	addi	a0,a0,-978 # ffffffffc0205e50 <etext+0x36>
void print_kerninfo(void) {
ffffffffc020022a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020022c:	f6dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200230:	00000597          	auipc	a1,0x0
ffffffffc0200234:	e1a58593          	addi	a1,a1,-486 # ffffffffc020004a <kern_init>
ffffffffc0200238:	00006517          	auipc	a0,0x6
ffffffffc020023c:	c3850513          	addi	a0,a0,-968 # ffffffffc0205e70 <etext+0x56>
ffffffffc0200240:	f59ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200244:	00006597          	auipc	a1,0x6
ffffffffc0200248:	bd658593          	addi	a1,a1,-1066 # ffffffffc0205e1a <etext>
ffffffffc020024c:	00006517          	auipc	a0,0x6
ffffffffc0200250:	c4450513          	addi	a0,a0,-956 # ffffffffc0205e90 <etext+0x76>
ffffffffc0200254:	f45ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200258:	000c2597          	auipc	a1,0xc2
ffffffffc020025c:	4c858593          	addi	a1,a1,1224 # ffffffffc02c2720 <buf>
ffffffffc0200260:	00006517          	auipc	a0,0x6
ffffffffc0200264:	c5050513          	addi	a0,a0,-944 # ffffffffc0205eb0 <etext+0x96>
ffffffffc0200268:	f31ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc020026c:	000c7597          	auipc	a1,0xc7
ffffffffc0200270:	9a458593          	addi	a1,a1,-1628 # ffffffffc02c6c10 <end>
ffffffffc0200274:	00006517          	auipc	a0,0x6
ffffffffc0200278:	c5c50513          	addi	a0,a0,-932 # ffffffffc0205ed0 <etext+0xb6>
ffffffffc020027c:	f1dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200280:	000c7597          	auipc	a1,0xc7
ffffffffc0200284:	d8f58593          	addi	a1,a1,-625 # ffffffffc02c700f <end+0x3ff>
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
ffffffffc02002a6:	c4e50513          	addi	a0,a0,-946 # ffffffffc0205ef0 <etext+0xd6>
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
ffffffffc02002b4:	c7060613          	addi	a2,a2,-912 # ffffffffc0205f20 <etext+0x106>
ffffffffc02002b8:	04d00593          	li	a1,77
ffffffffc02002bc:	00006517          	auipc	a0,0x6
ffffffffc02002c0:	c7c50513          	addi	a0,a0,-900 # ffffffffc0205f38 <etext+0x11e>
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
ffffffffc02002d0:	c8460613          	addi	a2,a2,-892 # ffffffffc0205f50 <etext+0x136>
ffffffffc02002d4:	00006597          	auipc	a1,0x6
ffffffffc02002d8:	c9c58593          	addi	a1,a1,-868 # ffffffffc0205f70 <etext+0x156>
ffffffffc02002dc:	00006517          	auipc	a0,0x6
ffffffffc02002e0:	c9c50513          	addi	a0,a0,-868 # ffffffffc0205f78 <etext+0x15e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e4:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	eb3ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc02002ea:	00006617          	auipc	a2,0x6
ffffffffc02002ee:	c9e60613          	addi	a2,a2,-866 # ffffffffc0205f88 <etext+0x16e>
ffffffffc02002f2:	00006597          	auipc	a1,0x6
ffffffffc02002f6:	cbe58593          	addi	a1,a1,-834 # ffffffffc0205fb0 <etext+0x196>
ffffffffc02002fa:	00006517          	auipc	a0,0x6
ffffffffc02002fe:	c7e50513          	addi	a0,a0,-898 # ffffffffc0205f78 <etext+0x15e>
ffffffffc0200302:	e97ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0200306:	00006617          	auipc	a2,0x6
ffffffffc020030a:	cba60613          	addi	a2,a2,-838 # ffffffffc0205fc0 <etext+0x1a6>
ffffffffc020030e:	00006597          	auipc	a1,0x6
ffffffffc0200312:	cd258593          	addi	a1,a1,-814 # ffffffffc0205fe0 <etext+0x1c6>
ffffffffc0200316:	00006517          	auipc	a0,0x6
ffffffffc020031a:	c6250513          	addi	a0,a0,-926 # ffffffffc0205f78 <etext+0x15e>
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
ffffffffc0200354:	ca050513          	addi	a0,a0,-864 # ffffffffc0205ff0 <etext+0x1d6>
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
ffffffffc0200376:	ca650513          	addi	a0,a0,-858 # ffffffffc0206018 <etext+0x1fe>
ffffffffc020037a:	e1fff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (tf != NULL) {
ffffffffc020037e:	000b8563          	beqz	s7,ffffffffc0200388 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200382:	855e                	mv	a0,s7
ffffffffc0200384:	01b000ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
ffffffffc0200388:	00006c17          	auipc	s8,0x6
ffffffffc020038c:	d00c0c13          	addi	s8,s8,-768 # ffffffffc0206088 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200390:	00006917          	auipc	s2,0x6
ffffffffc0200394:	cb090913          	addi	s2,s2,-848 # ffffffffc0206040 <etext+0x226>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200398:	00006497          	auipc	s1,0x6
ffffffffc020039c:	cb048493          	addi	s1,s1,-848 # ffffffffc0206048 <etext+0x22e>
        if (argc == MAXARGS - 1) {
ffffffffc02003a0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003a2:	00006b17          	auipc	s6,0x6
ffffffffc02003a6:	caeb0b13          	addi	s6,s6,-850 # ffffffffc0206050 <etext+0x236>
        argv[argc ++] = buf;
ffffffffc02003aa:	00006a17          	auipc	s4,0x6
ffffffffc02003ae:	bc6a0a13          	addi	s4,s4,-1082 # ffffffffc0205f70 <etext+0x156>
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
ffffffffc02003d0:	cbcd0d13          	addi	s10,s10,-836 # ffffffffc0206088 <commands>
        argv[argc ++] = buf;
ffffffffc02003d4:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d6:	4401                	li	s0,0
ffffffffc02003d8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003da:	1bd050ef          	jal	ra,ffffffffc0205d96 <strcmp>
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
ffffffffc02003ee:	1a9050ef          	jal	ra,ffffffffc0205d96 <strcmp>
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
ffffffffc020042c:	1af050ef          	jal	ra,ffffffffc0205dda <strchr>
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
ffffffffc020046a:	171050ef          	jal	ra,ffffffffc0205dda <strchr>
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
ffffffffc0200488:	bec50513          	addi	a0,a0,-1044 # ffffffffc0206070 <etext+0x256>
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
ffffffffc0200492:	000c6317          	auipc	t1,0xc6
ffffffffc0200496:	6e630313          	addi	t1,t1,1766 # ffffffffc02c6b78 <is_panic>
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
ffffffffc02004c4:	c1050513          	addi	a0,a0,-1008 # ffffffffc02060d0 <commands+0x48>
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
ffffffffc02004da:	d4250513          	addi	a0,a0,-702 # ffffffffc0207218 <default_pmm_manager+0x578>
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
ffffffffc020050e:	be650513          	addi	a0,a0,-1050 # ffffffffc02060f0 <commands+0x68>
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
ffffffffc020052e:	cee50513          	addi	a0,a0,-786 # ffffffffc0207218 <default_pmm_manager+0x578>
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
ffffffffc0200560:	bb450513          	addi	a0,a0,-1100 # ffffffffc0206110 <commands+0x88>
    ticks = 0;
ffffffffc0200564:	000c6797          	auipc	a5,0xc6
ffffffffc0200568:	6007be23          	sd	zero,1564(a5) # ffffffffc02c6b80 <ticks>
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
ffffffffc02005fe:	b3650513          	addi	a0,a0,-1226 # ffffffffc0206130 <commands+0xa8>
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
ffffffffc020062c:	b1850513          	addi	a0,a0,-1256 # ffffffffc0206140 <commands+0xb8>
ffffffffc0200630:	b69ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200634:	0000c417          	auipc	s0,0xc
ffffffffc0200638:	9d440413          	addi	s0,s0,-1580 # ffffffffc020c008 <boot_dtb>
ffffffffc020063c:	600c                	ld	a1,0(s0)
ffffffffc020063e:	00006517          	auipc	a0,0x6
ffffffffc0200642:	b1250513          	addi	a0,a0,-1262 # ffffffffc0206150 <commands+0xc8>
ffffffffc0200646:	b53ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020064a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020064e:	00006517          	auipc	a0,0x6
ffffffffc0200652:	b1a50513          	addi	a0,a0,-1254 # ffffffffc0206168 <commands+0xe0>
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
ffffffffc0200696:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe192dd>
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
ffffffffc020070c:	ab090913          	addi	s2,s2,-1360 # ffffffffc02061b8 <commands+0x130>
ffffffffc0200710:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200712:	4d91                	li	s11,4
ffffffffc0200714:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200716:	00006497          	auipc	s1,0x6
ffffffffc020071a:	a9a48493          	addi	s1,s1,-1382 # ffffffffc02061b0 <commands+0x128>
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
ffffffffc020076e:	ac650513          	addi	a0,a0,-1338 # ffffffffc0206230 <commands+0x1a8>
ffffffffc0200772:	a27ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200776:	00006517          	auipc	a0,0x6
ffffffffc020077a:	af250513          	addi	a0,a0,-1294 # ffffffffc0206268 <commands+0x1e0>
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
ffffffffc02007ba:	9d250513          	addi	a0,a0,-1582 # ffffffffc0206188 <commands+0x100>
}
ffffffffc02007be:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c0:	bae1                	j	ffffffffc0200198 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c2:	8556                	mv	a0,s5
ffffffffc02007c4:	58a050ef          	jal	ra,ffffffffc0205d4e <strlen>
ffffffffc02007c8:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007ca:	4619                	li	a2,6
ffffffffc02007cc:	85a6                	mv	a1,s1
ffffffffc02007ce:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d0:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d2:	5e2050ef          	jal	ra,ffffffffc0205db4 <strncmp>
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
ffffffffc0200868:	52e050ef          	jal	ra,ffffffffc0205d96 <strcmp>
ffffffffc020086c:	66a2                	ld	a3,8(sp)
ffffffffc020086e:	f94d                	bnez	a0,ffffffffc0200820 <dtb_init+0x228>
ffffffffc0200870:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200820 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200874:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200878:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020087c:	00006517          	auipc	a0,0x6
ffffffffc0200880:	94450513          	addi	a0,a0,-1724 # ffffffffc02061c0 <commands+0x138>
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
ffffffffc020094e:	89650513          	addi	a0,a0,-1898 # ffffffffc02061e0 <commands+0x158>
ffffffffc0200952:	847ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200956:	014b5613          	srli	a2,s6,0x14
ffffffffc020095a:	85da                	mv	a1,s6
ffffffffc020095c:	00006517          	auipc	a0,0x6
ffffffffc0200960:	89c50513          	addi	a0,a0,-1892 # ffffffffc02061f8 <commands+0x170>
ffffffffc0200964:	835ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200968:	008b05b3          	add	a1,s6,s0
ffffffffc020096c:	15fd                	addi	a1,a1,-1
ffffffffc020096e:	00006517          	auipc	a0,0x6
ffffffffc0200972:	8aa50513          	addi	a0,a0,-1878 # ffffffffc0206218 <commands+0x190>
ffffffffc0200976:	823ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc020097a:	00006517          	auipc	a0,0x6
ffffffffc020097e:	8ee50513          	addi	a0,a0,-1810 # ffffffffc0206268 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200982:	000c6797          	auipc	a5,0xc6
ffffffffc0200986:	2087b323          	sd	s0,518(a5) # ffffffffc02c6b88 <memory_base>
        memory_size = mem_size;
ffffffffc020098a:	000c6797          	auipc	a5,0xc6
ffffffffc020098e:	2167b323          	sd	s6,518(a5) # ffffffffc02c6b90 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200992:	b3f5                	j	ffffffffc020077e <dtb_init+0x186>

ffffffffc0200994 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200994:	000c6517          	auipc	a0,0xc6
ffffffffc0200998:	1f453503          	ld	a0,500(a0) # ffffffffc02c6b88 <memory_base>
ffffffffc020099c:	8082                	ret

ffffffffc020099e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020099e:	000c6517          	auipc	a0,0xc6
ffffffffc02009a2:	1f253503          	ld	a0,498(a0) # ffffffffc02c6b90 <memory_size>
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
ffffffffc02009be:	51678793          	addi	a5,a5,1302 # ffffffffc0200ed0 <__alltraps>
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
ffffffffc02009dc:	8a850513          	addi	a0,a0,-1880 # ffffffffc0206280 <commands+0x1f8>
{
ffffffffc02009e0:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e2:	fb6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009e6:	640c                	ld	a1,8(s0)
ffffffffc02009e8:	00006517          	auipc	a0,0x6
ffffffffc02009ec:	8b050513          	addi	a0,a0,-1872 # ffffffffc0206298 <commands+0x210>
ffffffffc02009f0:	fa8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009f4:	680c                	ld	a1,16(s0)
ffffffffc02009f6:	00006517          	auipc	a0,0x6
ffffffffc02009fa:	8ba50513          	addi	a0,a0,-1862 # ffffffffc02062b0 <commands+0x228>
ffffffffc02009fe:	f9aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a02:	6c0c                	ld	a1,24(s0)
ffffffffc0200a04:	00006517          	auipc	a0,0x6
ffffffffc0200a08:	8c450513          	addi	a0,a0,-1852 # ffffffffc02062c8 <commands+0x240>
ffffffffc0200a0c:	f8cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a10:	700c                	ld	a1,32(s0)
ffffffffc0200a12:	00006517          	auipc	a0,0x6
ffffffffc0200a16:	8ce50513          	addi	a0,a0,-1842 # ffffffffc02062e0 <commands+0x258>
ffffffffc0200a1a:	f7eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a1e:	740c                	ld	a1,40(s0)
ffffffffc0200a20:	00006517          	auipc	a0,0x6
ffffffffc0200a24:	8d850513          	addi	a0,a0,-1832 # ffffffffc02062f8 <commands+0x270>
ffffffffc0200a28:	f70ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a2c:	780c                	ld	a1,48(s0)
ffffffffc0200a2e:	00006517          	auipc	a0,0x6
ffffffffc0200a32:	8e250513          	addi	a0,a0,-1822 # ffffffffc0206310 <commands+0x288>
ffffffffc0200a36:	f62ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a3a:	7c0c                	ld	a1,56(s0)
ffffffffc0200a3c:	00006517          	auipc	a0,0x6
ffffffffc0200a40:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0206328 <commands+0x2a0>
ffffffffc0200a44:	f54ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a48:	602c                	ld	a1,64(s0)
ffffffffc0200a4a:	00006517          	auipc	a0,0x6
ffffffffc0200a4e:	8f650513          	addi	a0,a0,-1802 # ffffffffc0206340 <commands+0x2b8>
ffffffffc0200a52:	f46ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a56:	642c                	ld	a1,72(s0)
ffffffffc0200a58:	00006517          	auipc	a0,0x6
ffffffffc0200a5c:	90050513          	addi	a0,a0,-1792 # ffffffffc0206358 <commands+0x2d0>
ffffffffc0200a60:	f38ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a64:	682c                	ld	a1,80(s0)
ffffffffc0200a66:	00006517          	auipc	a0,0x6
ffffffffc0200a6a:	90a50513          	addi	a0,a0,-1782 # ffffffffc0206370 <commands+0x2e8>
ffffffffc0200a6e:	f2aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a72:	6c2c                	ld	a1,88(s0)
ffffffffc0200a74:	00006517          	auipc	a0,0x6
ffffffffc0200a78:	91450513          	addi	a0,a0,-1772 # ffffffffc0206388 <commands+0x300>
ffffffffc0200a7c:	f1cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a80:	702c                	ld	a1,96(s0)
ffffffffc0200a82:	00006517          	auipc	a0,0x6
ffffffffc0200a86:	91e50513          	addi	a0,a0,-1762 # ffffffffc02063a0 <commands+0x318>
ffffffffc0200a8a:	f0eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a8e:	742c                	ld	a1,104(s0)
ffffffffc0200a90:	00006517          	auipc	a0,0x6
ffffffffc0200a94:	92850513          	addi	a0,a0,-1752 # ffffffffc02063b8 <commands+0x330>
ffffffffc0200a98:	f00ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a9c:	782c                	ld	a1,112(s0)
ffffffffc0200a9e:	00006517          	auipc	a0,0x6
ffffffffc0200aa2:	93250513          	addi	a0,a0,-1742 # ffffffffc02063d0 <commands+0x348>
ffffffffc0200aa6:	ef2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200aaa:	7c2c                	ld	a1,120(s0)
ffffffffc0200aac:	00006517          	auipc	a0,0x6
ffffffffc0200ab0:	93c50513          	addi	a0,a0,-1732 # ffffffffc02063e8 <commands+0x360>
ffffffffc0200ab4:	ee4ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200ab8:	604c                	ld	a1,128(s0)
ffffffffc0200aba:	00006517          	auipc	a0,0x6
ffffffffc0200abe:	94650513          	addi	a0,a0,-1722 # ffffffffc0206400 <commands+0x378>
ffffffffc0200ac2:	ed6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200ac6:	644c                	ld	a1,136(s0)
ffffffffc0200ac8:	00006517          	auipc	a0,0x6
ffffffffc0200acc:	95050513          	addi	a0,a0,-1712 # ffffffffc0206418 <commands+0x390>
ffffffffc0200ad0:	ec8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ad4:	684c                	ld	a1,144(s0)
ffffffffc0200ad6:	00006517          	auipc	a0,0x6
ffffffffc0200ada:	95a50513          	addi	a0,a0,-1702 # ffffffffc0206430 <commands+0x3a8>
ffffffffc0200ade:	ebaff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae2:	6c4c                	ld	a1,152(s0)
ffffffffc0200ae4:	00006517          	auipc	a0,0x6
ffffffffc0200ae8:	96450513          	addi	a0,a0,-1692 # ffffffffc0206448 <commands+0x3c0>
ffffffffc0200aec:	eacff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af0:	704c                	ld	a1,160(s0)
ffffffffc0200af2:	00006517          	auipc	a0,0x6
ffffffffc0200af6:	96e50513          	addi	a0,a0,-1682 # ffffffffc0206460 <commands+0x3d8>
ffffffffc0200afa:	e9eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200afe:	744c                	ld	a1,168(s0)
ffffffffc0200b00:	00006517          	auipc	a0,0x6
ffffffffc0200b04:	97850513          	addi	a0,a0,-1672 # ffffffffc0206478 <commands+0x3f0>
ffffffffc0200b08:	e90ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b0c:	784c                	ld	a1,176(s0)
ffffffffc0200b0e:	00006517          	auipc	a0,0x6
ffffffffc0200b12:	98250513          	addi	a0,a0,-1662 # ffffffffc0206490 <commands+0x408>
ffffffffc0200b16:	e82ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b1a:	7c4c                	ld	a1,184(s0)
ffffffffc0200b1c:	00006517          	auipc	a0,0x6
ffffffffc0200b20:	98c50513          	addi	a0,a0,-1652 # ffffffffc02064a8 <commands+0x420>
ffffffffc0200b24:	e74ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b28:	606c                	ld	a1,192(s0)
ffffffffc0200b2a:	00006517          	auipc	a0,0x6
ffffffffc0200b2e:	99650513          	addi	a0,a0,-1642 # ffffffffc02064c0 <commands+0x438>
ffffffffc0200b32:	e66ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b36:	646c                	ld	a1,200(s0)
ffffffffc0200b38:	00006517          	auipc	a0,0x6
ffffffffc0200b3c:	9a050513          	addi	a0,a0,-1632 # ffffffffc02064d8 <commands+0x450>
ffffffffc0200b40:	e58ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b44:	686c                	ld	a1,208(s0)
ffffffffc0200b46:	00006517          	auipc	a0,0x6
ffffffffc0200b4a:	9aa50513          	addi	a0,a0,-1622 # ffffffffc02064f0 <commands+0x468>
ffffffffc0200b4e:	e4aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b52:	6c6c                	ld	a1,216(s0)
ffffffffc0200b54:	00006517          	auipc	a0,0x6
ffffffffc0200b58:	9b450513          	addi	a0,a0,-1612 # ffffffffc0206508 <commands+0x480>
ffffffffc0200b5c:	e3cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b60:	706c                	ld	a1,224(s0)
ffffffffc0200b62:	00006517          	auipc	a0,0x6
ffffffffc0200b66:	9be50513          	addi	a0,a0,-1602 # ffffffffc0206520 <commands+0x498>
ffffffffc0200b6a:	e2eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b6e:	746c                	ld	a1,232(s0)
ffffffffc0200b70:	00006517          	auipc	a0,0x6
ffffffffc0200b74:	9c850513          	addi	a0,a0,-1592 # ffffffffc0206538 <commands+0x4b0>
ffffffffc0200b78:	e20ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b7c:	786c                	ld	a1,240(s0)
ffffffffc0200b7e:	00006517          	auipc	a0,0x6
ffffffffc0200b82:	9d250513          	addi	a0,a0,-1582 # ffffffffc0206550 <commands+0x4c8>
ffffffffc0200b86:	e12ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b8a:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b8c:	6402                	ld	s0,0(sp)
ffffffffc0200b8e:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	00006517          	auipc	a0,0x6
ffffffffc0200b94:	9d850513          	addi	a0,a0,-1576 # ffffffffc0206568 <commands+0x4e0>
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
ffffffffc0200baa:	9da50513          	addi	a0,a0,-1574 # ffffffffc0206580 <commands+0x4f8>
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
ffffffffc0200bc2:	9da50513          	addi	a0,a0,-1574 # ffffffffc0206598 <commands+0x510>
ffffffffc0200bc6:	dd2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bca:	10843583          	ld	a1,264(s0)
ffffffffc0200bce:	00006517          	auipc	a0,0x6
ffffffffc0200bd2:	9e250513          	addi	a0,a0,-1566 # ffffffffc02065b0 <commands+0x528>
ffffffffc0200bd6:	dc2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200bda:	11043583          	ld	a1,272(s0)
ffffffffc0200bde:	00006517          	auipc	a0,0x6
ffffffffc0200be2:	9ea50513          	addi	a0,a0,-1558 # ffffffffc02065c8 <commands+0x540>
ffffffffc0200be6:	db2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bea:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bee:	6402                	ld	s0,0(sp)
ffffffffc0200bf0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf2:	00006517          	auipc	a0,0x6
ffffffffc0200bf6:	9e650513          	addi	a0,a0,-1562 # ffffffffc02065d8 <commands+0x550>
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
ffffffffc0200c0a:	08f76d63          	bltu	a4,a5,ffffffffc0200ca4 <interrupt_handler+0xa4>
ffffffffc0200c0e:	00006717          	auipc	a4,0x6
ffffffffc0200c12:	ab270713          	addi	a4,a4,-1358 # ffffffffc02066c0 <commands+0x638>
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
ffffffffc0200c24:	a3050513          	addi	a0,a0,-1488 # ffffffffc0206650 <commands+0x5c8>
ffffffffc0200c28:	d70ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c2c:	00006517          	auipc	a0,0x6
ffffffffc0200c30:	a0450513          	addi	a0,a0,-1532 # ffffffffc0206630 <commands+0x5a8>
ffffffffc0200c34:	d64ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c38:	00006517          	auipc	a0,0x6
ffffffffc0200c3c:	9b850513          	addi	a0,a0,-1608 # ffffffffc02065f0 <commands+0x568>
ffffffffc0200c40:	d58ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c44:	00006517          	auipc	a0,0x6
ffffffffc0200c48:	9cc50513          	addi	a0,a0,-1588 # ffffffffc0206610 <commands+0x588>
ffffffffc0200c4c:	d4cff06f          	j	ffffffffc0200198 <cprintf>
{
ffffffffc0200c50:	1141                	addi	sp,sp,-16
ffffffffc0200c52:	e022                	sd	s0,0(sp)
ffffffffc0200c54:	e406                	sd	ra,8(sp)
         *(2)计数器（ticks）加一
         *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
         * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
         */

        clock_set_next_event();
ffffffffc0200c56:	919ff0ef          	jal	ra,ffffffffc020056e <clock_set_next_event>
        if (++ticks % TICK_NUM == 0)
ffffffffc0200c5a:	000c6697          	auipc	a3,0xc6
ffffffffc0200c5e:	f2668693          	addi	a3,a3,-218 # ffffffffc02c6b80 <ticks>
ffffffffc0200c62:	629c                	ld	a5,0(a3)
ffffffffc0200c64:	06400713          	li	a4,100
ffffffffc0200c68:	000c6417          	auipc	s0,0xc6
ffffffffc0200c6c:	f3040413          	addi	s0,s0,-208 # ffffffffc02c6b98 <print_num>
ffffffffc0200c70:	0785                	addi	a5,a5,1
ffffffffc0200c72:	02e7f733          	remu	a4,a5,a4
ffffffffc0200c76:	e29c                	sd	a5,0(a3)
ffffffffc0200c78:	c71d                	beqz	a4,ffffffffc0200ca6 <interrupt_handler+0xa6>
        {
            print_num++;
            print_ticks();
        }
        if (current != NULL)
ffffffffc0200c7a:	000c6517          	auipc	a0,0xc6
ffffffffc0200c7e:	f6653503          	ld	a0,-154(a0) # ffffffffc02c6be0 <current>
ffffffffc0200c82:	c119                	beqz	a0,ffffffffc0200c88 <interrupt_handler+0x88>
        {
            sched_class_proc_tick(current);
ffffffffc0200c84:	1db040ef          	jal	ra,ffffffffc020565e <sched_class_proc_tick>
        }
        if (print_num == 10)
ffffffffc0200c88:	4018                	lw	a4,0(s0)
ffffffffc0200c8a:	47a9                	li	a5,10
ffffffffc0200c8c:	02f70963          	beq	a4,a5,ffffffffc0200cbe <interrupt_handler+0xbe>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c90:	60a2                	ld	ra,8(sp)
ffffffffc0200c92:	6402                	ld	s0,0(sp)
ffffffffc0200c94:	0141                	addi	sp,sp,16
ffffffffc0200c96:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c98:	00006517          	auipc	a0,0x6
ffffffffc0200c9c:	a0850513          	addi	a0,a0,-1528 # ffffffffc02066a0 <commands+0x618>
ffffffffc0200ca0:	cf8ff06f          	j	ffffffffc0200198 <cprintf>
        print_trapframe(tf);
ffffffffc0200ca4:	bded                	j	ffffffffc0200b9e <print_trapframe>
            print_num++;
ffffffffc0200ca6:	401c                	lw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200ca8:	06400593          	li	a1,100
ffffffffc0200cac:	00006517          	auipc	a0,0x6
ffffffffc0200cb0:	9c450513          	addi	a0,a0,-1596 # ffffffffc0206670 <commands+0x5e8>
            print_num++;
ffffffffc0200cb4:	2785                	addiw	a5,a5,1
ffffffffc0200cb6:	c01c                	sw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200cb8:	ce0ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0200cbc:	bf7d                	j	ffffffffc0200c7a <interrupt_handler+0x7a>
            cprintf("Calling SBI shutdown...\n");
ffffffffc0200cbe:	00006517          	auipc	a0,0x6
ffffffffc0200cc2:	9c250513          	addi	a0,a0,-1598 # ffffffffc0206680 <commands+0x5f8>
ffffffffc0200cc6:	cd2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200cca:	4501                	li	a0,0
ffffffffc0200ccc:	4581                	li	a1,0
ffffffffc0200cce:	4601                	li	a2,0
ffffffffc0200cd0:	48a1                	li	a7,8
ffffffffc0200cd2:	00000073          	ecall
}
ffffffffc0200cd6:	bf6d                	j	ffffffffc0200c90 <interrupt_handler+0x90>

ffffffffc0200cd8 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200cd8:	11853783          	ld	a5,280(a0)
{
ffffffffc0200cdc:	1141                	addi	sp,sp,-16
ffffffffc0200cde:	e022                	sd	s0,0(sp)
ffffffffc0200ce0:	e406                	sd	ra,8(sp)
ffffffffc0200ce2:	473d                	li	a4,15
ffffffffc0200ce4:	842a                	mv	s0,a0
ffffffffc0200ce6:	10f76f63          	bltu	a4,a5,ffffffffc0200e04 <exception_handler+0x12c>
ffffffffc0200cea:	00006717          	auipc	a4,0x6
ffffffffc0200cee:	bb270713          	addi	a4,a4,-1102 # ffffffffc020689c <commands+0x814>
ffffffffc0200cf2:	078a                	slli	a5,a5,0x2
ffffffffc0200cf4:	97ba                	add	a5,a5,a4
ffffffffc0200cf6:	439c                	lw	a5,0(a5)
ffffffffc0200cf8:	97ba                	add	a5,a5,a4
ffffffffc0200cfa:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200cfc:	00006517          	auipc	a0,0x6
ffffffffc0200d00:	adc50513          	addi	a0,a0,-1316 # ffffffffc02067d8 <commands+0x750>
ffffffffc0200d04:	c94ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        tf->epc += 4;
ffffffffc0200d08:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200d0c:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200d0e:	0791                	addi	a5,a5,4
ffffffffc0200d10:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200d14:	6402                	ld	s0,0(sp)
ffffffffc0200d16:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200d18:	3b10406f          	j	ffffffffc02058c8 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200d1c:	00006517          	auipc	a0,0x6
ffffffffc0200d20:	adc50513          	addi	a0,a0,-1316 # ffffffffc02067f8 <commands+0x770>
}
ffffffffc0200d24:	6402                	ld	s0,0(sp)
ffffffffc0200d26:	60a2                	ld	ra,8(sp)
ffffffffc0200d28:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200d2a:	c6eff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d2e:	00006517          	auipc	a0,0x6
ffffffffc0200d32:	aea50513          	addi	a0,a0,-1302 # ffffffffc0206818 <commands+0x790>
ffffffffc0200d36:	b7fd                	j	ffffffffc0200d24 <exception_handler+0x4c>
        if (do_pgfault(current->mm, 0, tf->tval) != 0)
ffffffffc0200d38:	000c6797          	auipc	a5,0xc6
ffffffffc0200d3c:	ea87b783          	ld	a5,-344(a5) # ffffffffc02c6be0 <current>
ffffffffc0200d40:	11053603          	ld	a2,272(a0)
ffffffffc0200d44:	7788                	ld	a0,40(a5)
ffffffffc0200d46:	4581                	li	a1,0
ffffffffc0200d48:	6e5020ef          	jal	ra,ffffffffc0203c2c <do_pgfault>
ffffffffc0200d4c:	ed69                	bnez	a0,ffffffffc0200e26 <exception_handler+0x14e>
}
ffffffffc0200d4e:	60a2                	ld	ra,8(sp)
ffffffffc0200d50:	6402                	ld	s0,0(sp)
ffffffffc0200d52:	0141                	addi	sp,sp,16
ffffffffc0200d54:	8082                	ret
        if (do_pgfault(current->mm, 0, tf->tval) != 0)
ffffffffc0200d56:	000c6797          	auipc	a5,0xc6
ffffffffc0200d5a:	e8a7b783          	ld	a5,-374(a5) # ffffffffc02c6be0 <current>
ffffffffc0200d5e:	11053603          	ld	a2,272(a0)
ffffffffc0200d62:	7788                	ld	a0,40(a5)
ffffffffc0200d64:	4581                	li	a1,0
ffffffffc0200d66:	6c7020ef          	jal	ra,ffffffffc0203c2c <do_pgfault>
ffffffffc0200d6a:	d175                	beqz	a0,ffffffffc0200d4e <exception_handler+0x76>
            print_trapframe(tf);
ffffffffc0200d6c:	8522                	mv	a0,s0
ffffffffc0200d6e:	e31ff0ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
            panic("unhandled load page fault\n");
ffffffffc0200d72:	00006617          	auipc	a2,0x6
ffffffffc0200d76:	aee60613          	addi	a2,a2,-1298 # ffffffffc0206860 <commands+0x7d8>
ffffffffc0200d7a:	0e600593          	li	a1,230
ffffffffc0200d7e:	00006517          	auipc	a0,0x6
ffffffffc0200d82:	a2a50513          	addi	a0,a0,-1494 # ffffffffc02067a8 <commands+0x720>
ffffffffc0200d86:	f0cff0ef          	jal	ra,ffffffffc0200492 <__panic>
        if (do_pgfault(current->mm, 0x2, tf->tval) != 0)
ffffffffc0200d8a:	000c6797          	auipc	a5,0xc6
ffffffffc0200d8e:	e567b783          	ld	a5,-426(a5) # ffffffffc02c6be0 <current>
ffffffffc0200d92:	11053603          	ld	a2,272(a0)
ffffffffc0200d96:	7788                	ld	a0,40(a5)
ffffffffc0200d98:	4589                	li	a1,2
ffffffffc0200d9a:	693020ef          	jal	ra,ffffffffc0203c2c <do_pgfault>
ffffffffc0200d9e:	d945                	beqz	a0,ffffffffc0200d4e <exception_handler+0x76>
            print_trapframe(tf);
ffffffffc0200da0:	8522                	mv	a0,s0
ffffffffc0200da2:	dfdff0ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
            panic("unhandled store page fault\n");
ffffffffc0200da6:	00006617          	auipc	a2,0x6
ffffffffc0200daa:	ada60613          	addi	a2,a2,-1318 # ffffffffc0206880 <commands+0x7f8>
ffffffffc0200dae:	0ed00593          	li	a1,237
ffffffffc0200db2:	00006517          	auipc	a0,0x6
ffffffffc0200db6:	9f650513          	addi	a0,a0,-1546 # ffffffffc02067a8 <commands+0x720>
ffffffffc0200dba:	ed8ff0ef          	jal	ra,ffffffffc0200492 <__panic>
        cprintf("Instruction address misaligned\n");
ffffffffc0200dbe:	00006517          	auipc	a0,0x6
ffffffffc0200dc2:	93250513          	addi	a0,a0,-1742 # ffffffffc02066f0 <commands+0x668>
ffffffffc0200dc6:	bfb9                	j	ffffffffc0200d24 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200dc8:	00006517          	auipc	a0,0x6
ffffffffc0200dcc:	94850513          	addi	a0,a0,-1720 # ffffffffc0206710 <commands+0x688>
ffffffffc0200dd0:	bf91                	j	ffffffffc0200d24 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200dd2:	00006517          	auipc	a0,0x6
ffffffffc0200dd6:	95e50513          	addi	a0,a0,-1698 # ffffffffc0206730 <commands+0x6a8>
ffffffffc0200dda:	b7a9                	j	ffffffffc0200d24 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200ddc:	00006517          	auipc	a0,0x6
ffffffffc0200de0:	96c50513          	addi	a0,a0,-1684 # ffffffffc0206748 <commands+0x6c0>
ffffffffc0200de4:	b781                	j	ffffffffc0200d24 <exception_handler+0x4c>
        cprintf("Load address misaligned\n");
ffffffffc0200de6:	00006517          	auipc	a0,0x6
ffffffffc0200dea:	97250513          	addi	a0,a0,-1678 # ffffffffc0206758 <commands+0x6d0>
ffffffffc0200dee:	bf1d                	j	ffffffffc0200d24 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200df0:	00006517          	auipc	a0,0x6
ffffffffc0200df4:	98850513          	addi	a0,a0,-1656 # ffffffffc0206778 <commands+0x6f0>
ffffffffc0200df8:	b735                	j	ffffffffc0200d24 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200dfa:	00006517          	auipc	a0,0x6
ffffffffc0200dfe:	9c650513          	addi	a0,a0,-1594 # ffffffffc02067c0 <commands+0x738>
ffffffffc0200e02:	b70d                	j	ffffffffc0200d24 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200e04:	8522                	mv	a0,s0
}
ffffffffc0200e06:	6402                	ld	s0,0(sp)
ffffffffc0200e08:	60a2                	ld	ra,8(sp)
ffffffffc0200e0a:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200e0c:	bb49                	j	ffffffffc0200b9e <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200e0e:	00006617          	auipc	a2,0x6
ffffffffc0200e12:	98260613          	addi	a2,a2,-1662 # ffffffffc0206790 <commands+0x708>
ffffffffc0200e16:	0c600593          	li	a1,198
ffffffffc0200e1a:	00006517          	auipc	a0,0x6
ffffffffc0200e1e:	98e50513          	addi	a0,a0,-1650 # ffffffffc02067a8 <commands+0x720>
ffffffffc0200e22:	e70ff0ef          	jal	ra,ffffffffc0200492 <__panic>
            print_trapframe(tf);
ffffffffc0200e26:	8522                	mv	a0,s0
ffffffffc0200e28:	d77ff0ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
            panic("unhandled instruction page fault\n");
ffffffffc0200e2c:	00006617          	auipc	a2,0x6
ffffffffc0200e30:	a0c60613          	addi	a2,a2,-1524 # ffffffffc0206838 <commands+0x7b0>
ffffffffc0200e34:	0df00593          	li	a1,223
ffffffffc0200e38:	00006517          	auipc	a0,0x6
ffffffffc0200e3c:	97050513          	addi	a0,a0,-1680 # ffffffffc02067a8 <commands+0x720>
ffffffffc0200e40:	e52ff0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0200e44 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200e44:	1101                	addi	sp,sp,-32
ffffffffc0200e46:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200e48:	000c6417          	auipc	s0,0xc6
ffffffffc0200e4c:	d9840413          	addi	s0,s0,-616 # ffffffffc02c6be0 <current>
ffffffffc0200e50:	6018                	ld	a4,0(s0)
{
ffffffffc0200e52:	ec06                	sd	ra,24(sp)
ffffffffc0200e54:	e426                	sd	s1,8(sp)
ffffffffc0200e56:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e58:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200e5c:	cf1d                	beqz	a4,ffffffffc0200e9a <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e5e:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200e62:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200e66:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e68:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e6c:	0206c463          	bltz	a3,ffffffffc0200e94 <trap+0x50>
        exception_handler(tf);
ffffffffc0200e70:	e69ff0ef          	jal	ra,ffffffffc0200cd8 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200e74:	601c                	ld	a5,0(s0)
ffffffffc0200e76:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200e7a:	e499                	bnez	s1,ffffffffc0200e88 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200e7c:	0b07a703          	lw	a4,176(a5)
ffffffffc0200e80:	8b05                	andi	a4,a4,1
ffffffffc0200e82:	e329                	bnez	a4,ffffffffc0200ec4 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200e84:	6f9c                	ld	a5,24(a5)
ffffffffc0200e86:	eb85                	bnez	a5,ffffffffc0200eb6 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200e88:	60e2                	ld	ra,24(sp)
ffffffffc0200e8a:	6442                	ld	s0,16(sp)
ffffffffc0200e8c:	64a2                	ld	s1,8(sp)
ffffffffc0200e8e:	6902                	ld	s2,0(sp)
ffffffffc0200e90:	6105                	addi	sp,sp,32
ffffffffc0200e92:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200e94:	d6dff0ef          	jal	ra,ffffffffc0200c00 <interrupt_handler>
ffffffffc0200e98:	bff1                	j	ffffffffc0200e74 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e9a:	0006c863          	bltz	a3,ffffffffc0200eaa <trap+0x66>
}
ffffffffc0200e9e:	6442                	ld	s0,16(sp)
ffffffffc0200ea0:	60e2                	ld	ra,24(sp)
ffffffffc0200ea2:	64a2                	ld	s1,8(sp)
ffffffffc0200ea4:	6902                	ld	s2,0(sp)
ffffffffc0200ea6:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200ea8:	bd05                	j	ffffffffc0200cd8 <exception_handler>
}
ffffffffc0200eaa:	6442                	ld	s0,16(sp)
ffffffffc0200eac:	60e2                	ld	ra,24(sp)
ffffffffc0200eae:	64a2                	ld	s1,8(sp)
ffffffffc0200eb0:	6902                	ld	s2,0(sp)
ffffffffc0200eb2:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200eb4:	b3b1                	j	ffffffffc0200c00 <interrupt_handler>
}
ffffffffc0200eb6:	6442                	ld	s0,16(sp)
ffffffffc0200eb8:	60e2                	ld	ra,24(sp)
ffffffffc0200eba:	64a2                	ld	s1,8(sp)
ffffffffc0200ebc:	6902                	ld	s2,0(sp)
ffffffffc0200ebe:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200ec0:	0cb0406f          	j	ffffffffc020578a <schedule>
                do_exit(-E_KILLED);
ffffffffc0200ec4:	555d                	li	a0,-9
ffffffffc0200ec6:	59c030ef          	jal	ra,ffffffffc0204462 <do_exit>
            if (current->need_resched)
ffffffffc0200eca:	601c                	ld	a5,0(s0)
ffffffffc0200ecc:	bf65                	j	ffffffffc0200e84 <trap+0x40>
	...

ffffffffc0200ed0 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ed0:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200ed4:	00011463          	bnez	sp,ffffffffc0200edc <__alltraps+0xc>
ffffffffc0200ed8:	14002173          	csrr	sp,sscratch
ffffffffc0200edc:	712d                	addi	sp,sp,-288
ffffffffc0200ede:	e002                	sd	zero,0(sp)
ffffffffc0200ee0:	e406                	sd	ra,8(sp)
ffffffffc0200ee2:	ec0e                	sd	gp,24(sp)
ffffffffc0200ee4:	f012                	sd	tp,32(sp)
ffffffffc0200ee6:	f416                	sd	t0,40(sp)
ffffffffc0200ee8:	f81a                	sd	t1,48(sp)
ffffffffc0200eea:	fc1e                	sd	t2,56(sp)
ffffffffc0200eec:	e0a2                	sd	s0,64(sp)
ffffffffc0200eee:	e4a6                	sd	s1,72(sp)
ffffffffc0200ef0:	e8aa                	sd	a0,80(sp)
ffffffffc0200ef2:	ecae                	sd	a1,88(sp)
ffffffffc0200ef4:	f0b2                	sd	a2,96(sp)
ffffffffc0200ef6:	f4b6                	sd	a3,104(sp)
ffffffffc0200ef8:	f8ba                	sd	a4,112(sp)
ffffffffc0200efa:	fcbe                	sd	a5,120(sp)
ffffffffc0200efc:	e142                	sd	a6,128(sp)
ffffffffc0200efe:	e546                	sd	a7,136(sp)
ffffffffc0200f00:	e94a                	sd	s2,144(sp)
ffffffffc0200f02:	ed4e                	sd	s3,152(sp)
ffffffffc0200f04:	f152                	sd	s4,160(sp)
ffffffffc0200f06:	f556                	sd	s5,168(sp)
ffffffffc0200f08:	f95a                	sd	s6,176(sp)
ffffffffc0200f0a:	fd5e                	sd	s7,184(sp)
ffffffffc0200f0c:	e1e2                	sd	s8,192(sp)
ffffffffc0200f0e:	e5e6                	sd	s9,200(sp)
ffffffffc0200f10:	e9ea                	sd	s10,208(sp)
ffffffffc0200f12:	edee                	sd	s11,216(sp)
ffffffffc0200f14:	f1f2                	sd	t3,224(sp)
ffffffffc0200f16:	f5f6                	sd	t4,232(sp)
ffffffffc0200f18:	f9fa                	sd	t5,240(sp)
ffffffffc0200f1a:	fdfe                	sd	t6,248(sp)
ffffffffc0200f1c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200f20:	100024f3          	csrr	s1,sstatus
ffffffffc0200f24:	14102973          	csrr	s2,sepc
ffffffffc0200f28:	143029f3          	csrr	s3,stval
ffffffffc0200f2c:	14202a73          	csrr	s4,scause
ffffffffc0200f30:	e822                	sd	s0,16(sp)
ffffffffc0200f32:	e226                	sd	s1,256(sp)
ffffffffc0200f34:	e64a                	sd	s2,264(sp)
ffffffffc0200f36:	ea4e                	sd	s3,272(sp)
ffffffffc0200f38:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200f3a:	850a                	mv	a0,sp
    jal trap
ffffffffc0200f3c:	f09ff0ef          	jal	ra,ffffffffc0200e44 <trap>

ffffffffc0200f40 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200f40:	6492                	ld	s1,256(sp)
ffffffffc0200f42:	6932                	ld	s2,264(sp)
ffffffffc0200f44:	1004f413          	andi	s0,s1,256
ffffffffc0200f48:	e401                	bnez	s0,ffffffffc0200f50 <__trapret+0x10>
ffffffffc0200f4a:	1200                	addi	s0,sp,288
ffffffffc0200f4c:	14041073          	csrw	sscratch,s0
ffffffffc0200f50:	10049073          	csrw	sstatus,s1
ffffffffc0200f54:	14191073          	csrw	sepc,s2
ffffffffc0200f58:	60a2                	ld	ra,8(sp)
ffffffffc0200f5a:	61e2                	ld	gp,24(sp)
ffffffffc0200f5c:	7202                	ld	tp,32(sp)
ffffffffc0200f5e:	72a2                	ld	t0,40(sp)
ffffffffc0200f60:	7342                	ld	t1,48(sp)
ffffffffc0200f62:	73e2                	ld	t2,56(sp)
ffffffffc0200f64:	6406                	ld	s0,64(sp)
ffffffffc0200f66:	64a6                	ld	s1,72(sp)
ffffffffc0200f68:	6546                	ld	a0,80(sp)
ffffffffc0200f6a:	65e6                	ld	a1,88(sp)
ffffffffc0200f6c:	7606                	ld	a2,96(sp)
ffffffffc0200f6e:	76a6                	ld	a3,104(sp)
ffffffffc0200f70:	7746                	ld	a4,112(sp)
ffffffffc0200f72:	77e6                	ld	a5,120(sp)
ffffffffc0200f74:	680a                	ld	a6,128(sp)
ffffffffc0200f76:	68aa                	ld	a7,136(sp)
ffffffffc0200f78:	694a                	ld	s2,144(sp)
ffffffffc0200f7a:	69ea                	ld	s3,152(sp)
ffffffffc0200f7c:	7a0a                	ld	s4,160(sp)
ffffffffc0200f7e:	7aaa                	ld	s5,168(sp)
ffffffffc0200f80:	7b4a                	ld	s6,176(sp)
ffffffffc0200f82:	7bea                	ld	s7,184(sp)
ffffffffc0200f84:	6c0e                	ld	s8,192(sp)
ffffffffc0200f86:	6cae                	ld	s9,200(sp)
ffffffffc0200f88:	6d4e                	ld	s10,208(sp)
ffffffffc0200f8a:	6dee                	ld	s11,216(sp)
ffffffffc0200f8c:	7e0e                	ld	t3,224(sp)
ffffffffc0200f8e:	7eae                	ld	t4,232(sp)
ffffffffc0200f90:	7f4e                	ld	t5,240(sp)
ffffffffc0200f92:	7fee                	ld	t6,248(sp)
ffffffffc0200f94:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200f96:	10200073          	sret

ffffffffc0200f9a <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200f9a:	812a                	mv	sp,a0
ffffffffc0200f9c:	b755                	j	ffffffffc0200f40 <__trapret>

ffffffffc0200f9e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200f9e:	000c2797          	auipc	a5,0xc2
ffffffffc0200fa2:	b8278793          	addi	a5,a5,-1150 # ffffffffc02c2b20 <free_area>
ffffffffc0200fa6:	e79c                	sd	a5,8(a5)
ffffffffc0200fa8:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200faa:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200fae:	8082                	ret

ffffffffc0200fb0 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200fb0:	000c2517          	auipc	a0,0xc2
ffffffffc0200fb4:	b8056503          	lwu	a0,-1152(a0) # ffffffffc02c2b30 <free_area+0x10>
ffffffffc0200fb8:	8082                	ret

ffffffffc0200fba <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200fba:	715d                	addi	sp,sp,-80
ffffffffc0200fbc:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200fbe:	000c2417          	auipc	s0,0xc2
ffffffffc0200fc2:	b6240413          	addi	s0,s0,-1182 # ffffffffc02c2b20 <free_area>
ffffffffc0200fc6:	641c                	ld	a5,8(s0)
ffffffffc0200fc8:	e486                	sd	ra,72(sp)
ffffffffc0200fca:	fc26                	sd	s1,56(sp)
ffffffffc0200fcc:	f84a                	sd	s2,48(sp)
ffffffffc0200fce:	f44e                	sd	s3,40(sp)
ffffffffc0200fd0:	f052                	sd	s4,32(sp)
ffffffffc0200fd2:	ec56                	sd	s5,24(sp)
ffffffffc0200fd4:	e85a                	sd	s6,16(sp)
ffffffffc0200fd6:	e45e                	sd	s7,8(sp)
ffffffffc0200fd8:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200fda:	2a878d63          	beq	a5,s0,ffffffffc0201294 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200fde:	4481                	li	s1,0
ffffffffc0200fe0:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200fe2:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200fe6:	8b09                	andi	a4,a4,2
ffffffffc0200fe8:	2a070a63          	beqz	a4,ffffffffc020129c <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0200fec:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ff0:	679c                	ld	a5,8(a5)
ffffffffc0200ff2:	2905                	addiw	s2,s2,1
ffffffffc0200ff4:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200ff6:	fe8796e3          	bne	a5,s0,ffffffffc0200fe2 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200ffa:	89a6                	mv	s3,s1
ffffffffc0200ffc:	6df000ef          	jal	ra,ffffffffc0201eda <nr_free_pages>
ffffffffc0201000:	6f351e63          	bne	a0,s3,ffffffffc02016fc <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201004:	4505                	li	a0,1
ffffffffc0201006:	657000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc020100a:	8aaa                	mv	s5,a0
ffffffffc020100c:	42050863          	beqz	a0,ffffffffc020143c <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201010:	4505                	li	a0,1
ffffffffc0201012:	64b000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201016:	89aa                	mv	s3,a0
ffffffffc0201018:	70050263          	beqz	a0,ffffffffc020171c <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020101c:	4505                	li	a0,1
ffffffffc020101e:	63f000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201022:	8a2a                	mv	s4,a0
ffffffffc0201024:	48050c63          	beqz	a0,ffffffffc02014bc <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201028:	293a8a63          	beq	s5,s3,ffffffffc02012bc <default_check+0x302>
ffffffffc020102c:	28aa8863          	beq	s5,a0,ffffffffc02012bc <default_check+0x302>
ffffffffc0201030:	28a98663          	beq	s3,a0,ffffffffc02012bc <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201034:	000aa783          	lw	a5,0(s5)
ffffffffc0201038:	2a079263          	bnez	a5,ffffffffc02012dc <default_check+0x322>
ffffffffc020103c:	0009a783          	lw	a5,0(s3)
ffffffffc0201040:	28079e63          	bnez	a5,ffffffffc02012dc <default_check+0x322>
ffffffffc0201044:	411c                	lw	a5,0(a0)
ffffffffc0201046:	28079b63          	bnez	a5,ffffffffc02012dc <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc020104a:	000c6797          	auipc	a5,0xc6
ffffffffc020104e:	b767b783          	ld	a5,-1162(a5) # ffffffffc02c6bc0 <pages>
ffffffffc0201052:	40fa8733          	sub	a4,s5,a5
ffffffffc0201056:	00007617          	auipc	a2,0x7
ffffffffc020105a:	66a63603          	ld	a2,1642(a2) # ffffffffc02086c0 <nbase>
ffffffffc020105e:	8719                	srai	a4,a4,0x6
ffffffffc0201060:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201062:	000c6697          	auipc	a3,0xc6
ffffffffc0201066:	b566b683          	ld	a3,-1194(a3) # ffffffffc02c6bb8 <npage>
ffffffffc020106a:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc020106c:	0732                	slli	a4,a4,0xc
ffffffffc020106e:	28d77763          	bgeu	a4,a3,ffffffffc02012fc <default_check+0x342>
    return page - pages + nbase;
ffffffffc0201072:	40f98733          	sub	a4,s3,a5
ffffffffc0201076:	8719                	srai	a4,a4,0x6
ffffffffc0201078:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020107a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020107c:	4cd77063          	bgeu	a4,a3,ffffffffc020153c <default_check+0x582>
    return page - pages + nbase;
ffffffffc0201080:	40f507b3          	sub	a5,a0,a5
ffffffffc0201084:	8799                	srai	a5,a5,0x6
ffffffffc0201086:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201088:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020108a:	30d7f963          	bgeu	a5,a3,ffffffffc020139c <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc020108e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201090:	00043c03          	ld	s8,0(s0)
ffffffffc0201094:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201098:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020109c:	e400                	sd	s0,8(s0)
ffffffffc020109e:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02010a0:	000c2797          	auipc	a5,0xc2
ffffffffc02010a4:	a807a823          	sw	zero,-1392(a5) # ffffffffc02c2b30 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02010a8:	5b5000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02010ac:	2c051863          	bnez	a0,ffffffffc020137c <default_check+0x3c2>
    free_page(p0);
ffffffffc02010b0:	4585                	li	a1,1
ffffffffc02010b2:	8556                	mv	a0,s5
ffffffffc02010b4:	5e7000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    free_page(p1);
ffffffffc02010b8:	4585                	li	a1,1
ffffffffc02010ba:	854e                	mv	a0,s3
ffffffffc02010bc:	5df000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    free_page(p2);
ffffffffc02010c0:	4585                	li	a1,1
ffffffffc02010c2:	8552                	mv	a0,s4
ffffffffc02010c4:	5d7000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    assert(nr_free == 3);
ffffffffc02010c8:	4818                	lw	a4,16(s0)
ffffffffc02010ca:	478d                	li	a5,3
ffffffffc02010cc:	28f71863          	bne	a4,a5,ffffffffc020135c <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010d0:	4505                	li	a0,1
ffffffffc02010d2:	58b000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02010d6:	89aa                	mv	s3,a0
ffffffffc02010d8:	26050263          	beqz	a0,ffffffffc020133c <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010dc:	4505                	li	a0,1
ffffffffc02010de:	57f000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02010e2:	8aaa                	mv	s5,a0
ffffffffc02010e4:	3a050c63          	beqz	a0,ffffffffc020149c <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010e8:	4505                	li	a0,1
ffffffffc02010ea:	573000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02010ee:	8a2a                	mv	s4,a0
ffffffffc02010f0:	38050663          	beqz	a0,ffffffffc020147c <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc02010f4:	4505                	li	a0,1
ffffffffc02010f6:	567000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02010fa:	36051163          	bnez	a0,ffffffffc020145c <default_check+0x4a2>
    free_page(p0);
ffffffffc02010fe:	4585                	li	a1,1
ffffffffc0201100:	854e                	mv	a0,s3
ffffffffc0201102:	599000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201106:	641c                	ld	a5,8(s0)
ffffffffc0201108:	20878a63          	beq	a5,s0,ffffffffc020131c <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc020110c:	4505                	li	a0,1
ffffffffc020110e:	54f000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201112:	30a99563          	bne	s3,a0,ffffffffc020141c <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201116:	4505                	li	a0,1
ffffffffc0201118:	545000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc020111c:	2e051063          	bnez	a0,ffffffffc02013fc <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0201120:	481c                	lw	a5,16(s0)
ffffffffc0201122:	2a079d63          	bnez	a5,ffffffffc02013dc <default_check+0x422>
    free_page(p);
ffffffffc0201126:	854e                	mv	a0,s3
ffffffffc0201128:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020112a:	01843023          	sd	s8,0(s0)
ffffffffc020112e:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201132:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201136:	565000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    free_page(p1);
ffffffffc020113a:	4585                	li	a1,1
ffffffffc020113c:	8556                	mv	a0,s5
ffffffffc020113e:	55d000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    free_page(p2);
ffffffffc0201142:	4585                	li	a1,1
ffffffffc0201144:	8552                	mv	a0,s4
ffffffffc0201146:	555000ef          	jal	ra,ffffffffc0201e9a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020114a:	4515                	li	a0,5
ffffffffc020114c:	511000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201150:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201152:	26050563          	beqz	a0,ffffffffc02013bc <default_check+0x402>
ffffffffc0201156:	651c                	ld	a5,8(a0)
ffffffffc0201158:	8385                	srli	a5,a5,0x1
ffffffffc020115a:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc020115c:	54079063          	bnez	a5,ffffffffc020169c <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201160:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201162:	00043b03          	ld	s6,0(s0)
ffffffffc0201166:	00843a83          	ld	s5,8(s0)
ffffffffc020116a:	e000                	sd	s0,0(s0)
ffffffffc020116c:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020116e:	4ef000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201172:	50051563          	bnez	a0,ffffffffc020167c <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201176:	08098a13          	addi	s4,s3,128
ffffffffc020117a:	8552                	mv	a0,s4
ffffffffc020117c:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020117e:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0201182:	000c2797          	auipc	a5,0xc2
ffffffffc0201186:	9a07a723          	sw	zero,-1618(a5) # ffffffffc02c2b30 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020118a:	511000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020118e:	4511                	li	a0,4
ffffffffc0201190:	4cd000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201194:	4c051463          	bnez	a0,ffffffffc020165c <default_check+0x6a2>
ffffffffc0201198:	0889b783          	ld	a5,136(s3)
ffffffffc020119c:	8385                	srli	a5,a5,0x1
ffffffffc020119e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02011a0:	48078e63          	beqz	a5,ffffffffc020163c <default_check+0x682>
ffffffffc02011a4:	0909a703          	lw	a4,144(s3)
ffffffffc02011a8:	478d                	li	a5,3
ffffffffc02011aa:	48f71963          	bne	a4,a5,ffffffffc020163c <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011ae:	450d                	li	a0,3
ffffffffc02011b0:	4ad000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02011b4:	8c2a                	mv	s8,a0
ffffffffc02011b6:	46050363          	beqz	a0,ffffffffc020161c <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02011ba:	4505                	li	a0,1
ffffffffc02011bc:	4a1000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02011c0:	42051e63          	bnez	a0,ffffffffc02015fc <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02011c4:	418a1c63          	bne	s4,s8,ffffffffc02015dc <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02011c8:	4585                	li	a1,1
ffffffffc02011ca:	854e                	mv	a0,s3
ffffffffc02011cc:	4cf000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    free_pages(p1, 3);
ffffffffc02011d0:	458d                	li	a1,3
ffffffffc02011d2:	8552                	mv	a0,s4
ffffffffc02011d4:	4c7000ef          	jal	ra,ffffffffc0201e9a <free_pages>
ffffffffc02011d8:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02011dc:	04098c13          	addi	s8,s3,64
ffffffffc02011e0:	8385                	srli	a5,a5,0x1
ffffffffc02011e2:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02011e4:	3c078c63          	beqz	a5,ffffffffc02015bc <default_check+0x602>
ffffffffc02011e8:	0109a703          	lw	a4,16(s3)
ffffffffc02011ec:	4785                	li	a5,1
ffffffffc02011ee:	3cf71763          	bne	a4,a5,ffffffffc02015bc <default_check+0x602>
ffffffffc02011f2:	008a3783          	ld	a5,8(s4)
ffffffffc02011f6:	8385                	srli	a5,a5,0x1
ffffffffc02011f8:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02011fa:	3a078163          	beqz	a5,ffffffffc020159c <default_check+0x5e2>
ffffffffc02011fe:	010a2703          	lw	a4,16(s4)
ffffffffc0201202:	478d                	li	a5,3
ffffffffc0201204:	38f71c63          	bne	a4,a5,ffffffffc020159c <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201208:	4505                	li	a0,1
ffffffffc020120a:	453000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc020120e:	36a99763          	bne	s3,a0,ffffffffc020157c <default_check+0x5c2>
    free_page(p0);
ffffffffc0201212:	4585                	li	a1,1
ffffffffc0201214:	487000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201218:	4509                	li	a0,2
ffffffffc020121a:	443000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc020121e:	32aa1f63          	bne	s4,a0,ffffffffc020155c <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0201222:	4589                	li	a1,2
ffffffffc0201224:	477000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    free_page(p2);
ffffffffc0201228:	4585                	li	a1,1
ffffffffc020122a:	8562                	mv	a0,s8
ffffffffc020122c:	46f000ef          	jal	ra,ffffffffc0201e9a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201230:	4515                	li	a0,5
ffffffffc0201232:	42b000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201236:	89aa                	mv	s3,a0
ffffffffc0201238:	48050263          	beqz	a0,ffffffffc02016bc <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc020123c:	4505                	li	a0,1
ffffffffc020123e:	41f000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201242:	2c051d63          	bnez	a0,ffffffffc020151c <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201246:	481c                	lw	a5,16(s0)
ffffffffc0201248:	2a079a63          	bnez	a5,ffffffffc02014fc <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020124c:	4595                	li	a1,5
ffffffffc020124e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201250:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201254:	01643023          	sd	s6,0(s0)
ffffffffc0201258:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020125c:	43f000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    return listelm->next;
ffffffffc0201260:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201262:	00878963          	beq	a5,s0,ffffffffc0201274 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201266:	ff87a703          	lw	a4,-8(a5)
ffffffffc020126a:	679c                	ld	a5,8(a5)
ffffffffc020126c:	397d                	addiw	s2,s2,-1
ffffffffc020126e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201270:	fe879be3          	bne	a5,s0,ffffffffc0201266 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201274:	26091463          	bnez	s2,ffffffffc02014dc <default_check+0x522>
    assert(total == 0);
ffffffffc0201278:	46049263          	bnez	s1,ffffffffc02016dc <default_check+0x722>
}
ffffffffc020127c:	60a6                	ld	ra,72(sp)
ffffffffc020127e:	6406                	ld	s0,64(sp)
ffffffffc0201280:	74e2                	ld	s1,56(sp)
ffffffffc0201282:	7942                	ld	s2,48(sp)
ffffffffc0201284:	79a2                	ld	s3,40(sp)
ffffffffc0201286:	7a02                	ld	s4,32(sp)
ffffffffc0201288:	6ae2                	ld	s5,24(sp)
ffffffffc020128a:	6b42                	ld	s6,16(sp)
ffffffffc020128c:	6ba2                	ld	s7,8(sp)
ffffffffc020128e:	6c02                	ld	s8,0(sp)
ffffffffc0201290:	6161                	addi	sp,sp,80
ffffffffc0201292:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201294:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201296:	4481                	li	s1,0
ffffffffc0201298:	4901                	li	s2,0
ffffffffc020129a:	b38d                	j	ffffffffc0200ffc <default_check+0x42>
        assert(PageProperty(p));
ffffffffc020129c:	00005697          	auipc	a3,0x5
ffffffffc02012a0:	64468693          	addi	a3,a3,1604 # ffffffffc02068e0 <commands+0x858>
ffffffffc02012a4:	00005617          	auipc	a2,0x5
ffffffffc02012a8:	64c60613          	addi	a2,a2,1612 # ffffffffc02068f0 <commands+0x868>
ffffffffc02012ac:	11000593          	li	a1,272
ffffffffc02012b0:	00005517          	auipc	a0,0x5
ffffffffc02012b4:	65850513          	addi	a0,a0,1624 # ffffffffc0206908 <commands+0x880>
ffffffffc02012b8:	9daff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02012bc:	00005697          	auipc	a3,0x5
ffffffffc02012c0:	6e468693          	addi	a3,a3,1764 # ffffffffc02069a0 <commands+0x918>
ffffffffc02012c4:	00005617          	auipc	a2,0x5
ffffffffc02012c8:	62c60613          	addi	a2,a2,1580 # ffffffffc02068f0 <commands+0x868>
ffffffffc02012cc:	0db00593          	li	a1,219
ffffffffc02012d0:	00005517          	auipc	a0,0x5
ffffffffc02012d4:	63850513          	addi	a0,a0,1592 # ffffffffc0206908 <commands+0x880>
ffffffffc02012d8:	9baff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02012dc:	00005697          	auipc	a3,0x5
ffffffffc02012e0:	6ec68693          	addi	a3,a3,1772 # ffffffffc02069c8 <commands+0x940>
ffffffffc02012e4:	00005617          	auipc	a2,0x5
ffffffffc02012e8:	60c60613          	addi	a2,a2,1548 # ffffffffc02068f0 <commands+0x868>
ffffffffc02012ec:	0dc00593          	li	a1,220
ffffffffc02012f0:	00005517          	auipc	a0,0x5
ffffffffc02012f4:	61850513          	addi	a0,a0,1560 # ffffffffc0206908 <commands+0x880>
ffffffffc02012f8:	99aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02012fc:	00005697          	auipc	a3,0x5
ffffffffc0201300:	70c68693          	addi	a3,a3,1804 # ffffffffc0206a08 <commands+0x980>
ffffffffc0201304:	00005617          	auipc	a2,0x5
ffffffffc0201308:	5ec60613          	addi	a2,a2,1516 # ffffffffc02068f0 <commands+0x868>
ffffffffc020130c:	0de00593          	li	a1,222
ffffffffc0201310:	00005517          	auipc	a0,0x5
ffffffffc0201314:	5f850513          	addi	a0,a0,1528 # ffffffffc0206908 <commands+0x880>
ffffffffc0201318:	97aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!list_empty(&free_list));
ffffffffc020131c:	00005697          	auipc	a3,0x5
ffffffffc0201320:	77468693          	addi	a3,a3,1908 # ffffffffc0206a90 <commands+0xa08>
ffffffffc0201324:	00005617          	auipc	a2,0x5
ffffffffc0201328:	5cc60613          	addi	a2,a2,1484 # ffffffffc02068f0 <commands+0x868>
ffffffffc020132c:	0f700593          	li	a1,247
ffffffffc0201330:	00005517          	auipc	a0,0x5
ffffffffc0201334:	5d850513          	addi	a0,a0,1496 # ffffffffc0206908 <commands+0x880>
ffffffffc0201338:	95aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020133c:	00005697          	auipc	a3,0x5
ffffffffc0201340:	60468693          	addi	a3,a3,1540 # ffffffffc0206940 <commands+0x8b8>
ffffffffc0201344:	00005617          	auipc	a2,0x5
ffffffffc0201348:	5ac60613          	addi	a2,a2,1452 # ffffffffc02068f0 <commands+0x868>
ffffffffc020134c:	0f000593          	li	a1,240
ffffffffc0201350:	00005517          	auipc	a0,0x5
ffffffffc0201354:	5b850513          	addi	a0,a0,1464 # ffffffffc0206908 <commands+0x880>
ffffffffc0201358:	93aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 3);
ffffffffc020135c:	00005697          	auipc	a3,0x5
ffffffffc0201360:	72468693          	addi	a3,a3,1828 # ffffffffc0206a80 <commands+0x9f8>
ffffffffc0201364:	00005617          	auipc	a2,0x5
ffffffffc0201368:	58c60613          	addi	a2,a2,1420 # ffffffffc02068f0 <commands+0x868>
ffffffffc020136c:	0ee00593          	li	a1,238
ffffffffc0201370:	00005517          	auipc	a0,0x5
ffffffffc0201374:	59850513          	addi	a0,a0,1432 # ffffffffc0206908 <commands+0x880>
ffffffffc0201378:	91aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020137c:	00005697          	auipc	a3,0x5
ffffffffc0201380:	6ec68693          	addi	a3,a3,1772 # ffffffffc0206a68 <commands+0x9e0>
ffffffffc0201384:	00005617          	auipc	a2,0x5
ffffffffc0201388:	56c60613          	addi	a2,a2,1388 # ffffffffc02068f0 <commands+0x868>
ffffffffc020138c:	0e900593          	li	a1,233
ffffffffc0201390:	00005517          	auipc	a0,0x5
ffffffffc0201394:	57850513          	addi	a0,a0,1400 # ffffffffc0206908 <commands+0x880>
ffffffffc0201398:	8faff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020139c:	00005697          	auipc	a3,0x5
ffffffffc02013a0:	6ac68693          	addi	a3,a3,1708 # ffffffffc0206a48 <commands+0x9c0>
ffffffffc02013a4:	00005617          	auipc	a2,0x5
ffffffffc02013a8:	54c60613          	addi	a2,a2,1356 # ffffffffc02068f0 <commands+0x868>
ffffffffc02013ac:	0e000593          	li	a1,224
ffffffffc02013b0:	00005517          	auipc	a0,0x5
ffffffffc02013b4:	55850513          	addi	a0,a0,1368 # ffffffffc0206908 <commands+0x880>
ffffffffc02013b8:	8daff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != NULL);
ffffffffc02013bc:	00005697          	auipc	a3,0x5
ffffffffc02013c0:	71c68693          	addi	a3,a3,1820 # ffffffffc0206ad8 <commands+0xa50>
ffffffffc02013c4:	00005617          	auipc	a2,0x5
ffffffffc02013c8:	52c60613          	addi	a2,a2,1324 # ffffffffc02068f0 <commands+0x868>
ffffffffc02013cc:	11800593          	li	a1,280
ffffffffc02013d0:	00005517          	auipc	a0,0x5
ffffffffc02013d4:	53850513          	addi	a0,a0,1336 # ffffffffc0206908 <commands+0x880>
ffffffffc02013d8:	8baff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc02013dc:	00005697          	auipc	a3,0x5
ffffffffc02013e0:	6ec68693          	addi	a3,a3,1772 # ffffffffc0206ac8 <commands+0xa40>
ffffffffc02013e4:	00005617          	auipc	a2,0x5
ffffffffc02013e8:	50c60613          	addi	a2,a2,1292 # ffffffffc02068f0 <commands+0x868>
ffffffffc02013ec:	0fd00593          	li	a1,253
ffffffffc02013f0:	00005517          	auipc	a0,0x5
ffffffffc02013f4:	51850513          	addi	a0,a0,1304 # ffffffffc0206908 <commands+0x880>
ffffffffc02013f8:	89aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013fc:	00005697          	auipc	a3,0x5
ffffffffc0201400:	66c68693          	addi	a3,a3,1644 # ffffffffc0206a68 <commands+0x9e0>
ffffffffc0201404:	00005617          	auipc	a2,0x5
ffffffffc0201408:	4ec60613          	addi	a2,a2,1260 # ffffffffc02068f0 <commands+0x868>
ffffffffc020140c:	0fb00593          	li	a1,251
ffffffffc0201410:	00005517          	auipc	a0,0x5
ffffffffc0201414:	4f850513          	addi	a0,a0,1272 # ffffffffc0206908 <commands+0x880>
ffffffffc0201418:	87aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020141c:	00005697          	auipc	a3,0x5
ffffffffc0201420:	68c68693          	addi	a3,a3,1676 # ffffffffc0206aa8 <commands+0xa20>
ffffffffc0201424:	00005617          	auipc	a2,0x5
ffffffffc0201428:	4cc60613          	addi	a2,a2,1228 # ffffffffc02068f0 <commands+0x868>
ffffffffc020142c:	0fa00593          	li	a1,250
ffffffffc0201430:	00005517          	auipc	a0,0x5
ffffffffc0201434:	4d850513          	addi	a0,a0,1240 # ffffffffc0206908 <commands+0x880>
ffffffffc0201438:	85aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020143c:	00005697          	auipc	a3,0x5
ffffffffc0201440:	50468693          	addi	a3,a3,1284 # ffffffffc0206940 <commands+0x8b8>
ffffffffc0201444:	00005617          	auipc	a2,0x5
ffffffffc0201448:	4ac60613          	addi	a2,a2,1196 # ffffffffc02068f0 <commands+0x868>
ffffffffc020144c:	0d700593          	li	a1,215
ffffffffc0201450:	00005517          	auipc	a0,0x5
ffffffffc0201454:	4b850513          	addi	a0,a0,1208 # ffffffffc0206908 <commands+0x880>
ffffffffc0201458:	83aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020145c:	00005697          	auipc	a3,0x5
ffffffffc0201460:	60c68693          	addi	a3,a3,1548 # ffffffffc0206a68 <commands+0x9e0>
ffffffffc0201464:	00005617          	auipc	a2,0x5
ffffffffc0201468:	48c60613          	addi	a2,a2,1164 # ffffffffc02068f0 <commands+0x868>
ffffffffc020146c:	0f400593          	li	a1,244
ffffffffc0201470:	00005517          	auipc	a0,0x5
ffffffffc0201474:	49850513          	addi	a0,a0,1176 # ffffffffc0206908 <commands+0x880>
ffffffffc0201478:	81aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020147c:	00005697          	auipc	a3,0x5
ffffffffc0201480:	50468693          	addi	a3,a3,1284 # ffffffffc0206980 <commands+0x8f8>
ffffffffc0201484:	00005617          	auipc	a2,0x5
ffffffffc0201488:	46c60613          	addi	a2,a2,1132 # ffffffffc02068f0 <commands+0x868>
ffffffffc020148c:	0f200593          	li	a1,242
ffffffffc0201490:	00005517          	auipc	a0,0x5
ffffffffc0201494:	47850513          	addi	a0,a0,1144 # ffffffffc0206908 <commands+0x880>
ffffffffc0201498:	ffbfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020149c:	00005697          	auipc	a3,0x5
ffffffffc02014a0:	4c468693          	addi	a3,a3,1220 # ffffffffc0206960 <commands+0x8d8>
ffffffffc02014a4:	00005617          	auipc	a2,0x5
ffffffffc02014a8:	44c60613          	addi	a2,a2,1100 # ffffffffc02068f0 <commands+0x868>
ffffffffc02014ac:	0f100593          	li	a1,241
ffffffffc02014b0:	00005517          	auipc	a0,0x5
ffffffffc02014b4:	45850513          	addi	a0,a0,1112 # ffffffffc0206908 <commands+0x880>
ffffffffc02014b8:	fdbfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014bc:	00005697          	auipc	a3,0x5
ffffffffc02014c0:	4c468693          	addi	a3,a3,1220 # ffffffffc0206980 <commands+0x8f8>
ffffffffc02014c4:	00005617          	auipc	a2,0x5
ffffffffc02014c8:	42c60613          	addi	a2,a2,1068 # ffffffffc02068f0 <commands+0x868>
ffffffffc02014cc:	0d900593          	li	a1,217
ffffffffc02014d0:	00005517          	auipc	a0,0x5
ffffffffc02014d4:	43850513          	addi	a0,a0,1080 # ffffffffc0206908 <commands+0x880>
ffffffffc02014d8:	fbbfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(count == 0);
ffffffffc02014dc:	00005697          	auipc	a3,0x5
ffffffffc02014e0:	74c68693          	addi	a3,a3,1868 # ffffffffc0206c28 <commands+0xba0>
ffffffffc02014e4:	00005617          	auipc	a2,0x5
ffffffffc02014e8:	40c60613          	addi	a2,a2,1036 # ffffffffc02068f0 <commands+0x868>
ffffffffc02014ec:	14600593          	li	a1,326
ffffffffc02014f0:	00005517          	auipc	a0,0x5
ffffffffc02014f4:	41850513          	addi	a0,a0,1048 # ffffffffc0206908 <commands+0x880>
ffffffffc02014f8:	f9bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc02014fc:	00005697          	auipc	a3,0x5
ffffffffc0201500:	5cc68693          	addi	a3,a3,1484 # ffffffffc0206ac8 <commands+0xa40>
ffffffffc0201504:	00005617          	auipc	a2,0x5
ffffffffc0201508:	3ec60613          	addi	a2,a2,1004 # ffffffffc02068f0 <commands+0x868>
ffffffffc020150c:	13a00593          	li	a1,314
ffffffffc0201510:	00005517          	auipc	a0,0x5
ffffffffc0201514:	3f850513          	addi	a0,a0,1016 # ffffffffc0206908 <commands+0x880>
ffffffffc0201518:	f7bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020151c:	00005697          	auipc	a3,0x5
ffffffffc0201520:	54c68693          	addi	a3,a3,1356 # ffffffffc0206a68 <commands+0x9e0>
ffffffffc0201524:	00005617          	auipc	a2,0x5
ffffffffc0201528:	3cc60613          	addi	a2,a2,972 # ffffffffc02068f0 <commands+0x868>
ffffffffc020152c:	13800593          	li	a1,312
ffffffffc0201530:	00005517          	auipc	a0,0x5
ffffffffc0201534:	3d850513          	addi	a0,a0,984 # ffffffffc0206908 <commands+0x880>
ffffffffc0201538:	f5bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020153c:	00005697          	auipc	a3,0x5
ffffffffc0201540:	4ec68693          	addi	a3,a3,1260 # ffffffffc0206a28 <commands+0x9a0>
ffffffffc0201544:	00005617          	auipc	a2,0x5
ffffffffc0201548:	3ac60613          	addi	a2,a2,940 # ffffffffc02068f0 <commands+0x868>
ffffffffc020154c:	0df00593          	li	a1,223
ffffffffc0201550:	00005517          	auipc	a0,0x5
ffffffffc0201554:	3b850513          	addi	a0,a0,952 # ffffffffc0206908 <commands+0x880>
ffffffffc0201558:	f3bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020155c:	00005697          	auipc	a3,0x5
ffffffffc0201560:	68c68693          	addi	a3,a3,1676 # ffffffffc0206be8 <commands+0xb60>
ffffffffc0201564:	00005617          	auipc	a2,0x5
ffffffffc0201568:	38c60613          	addi	a2,a2,908 # ffffffffc02068f0 <commands+0x868>
ffffffffc020156c:	13200593          	li	a1,306
ffffffffc0201570:	00005517          	auipc	a0,0x5
ffffffffc0201574:	39850513          	addi	a0,a0,920 # ffffffffc0206908 <commands+0x880>
ffffffffc0201578:	f1bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020157c:	00005697          	auipc	a3,0x5
ffffffffc0201580:	64c68693          	addi	a3,a3,1612 # ffffffffc0206bc8 <commands+0xb40>
ffffffffc0201584:	00005617          	auipc	a2,0x5
ffffffffc0201588:	36c60613          	addi	a2,a2,876 # ffffffffc02068f0 <commands+0x868>
ffffffffc020158c:	13000593          	li	a1,304
ffffffffc0201590:	00005517          	auipc	a0,0x5
ffffffffc0201594:	37850513          	addi	a0,a0,888 # ffffffffc0206908 <commands+0x880>
ffffffffc0201598:	efbfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020159c:	00005697          	auipc	a3,0x5
ffffffffc02015a0:	60468693          	addi	a3,a3,1540 # ffffffffc0206ba0 <commands+0xb18>
ffffffffc02015a4:	00005617          	auipc	a2,0x5
ffffffffc02015a8:	34c60613          	addi	a2,a2,844 # ffffffffc02068f0 <commands+0x868>
ffffffffc02015ac:	12e00593          	li	a1,302
ffffffffc02015b0:	00005517          	auipc	a0,0x5
ffffffffc02015b4:	35850513          	addi	a0,a0,856 # ffffffffc0206908 <commands+0x880>
ffffffffc02015b8:	edbfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02015bc:	00005697          	auipc	a3,0x5
ffffffffc02015c0:	5bc68693          	addi	a3,a3,1468 # ffffffffc0206b78 <commands+0xaf0>
ffffffffc02015c4:	00005617          	auipc	a2,0x5
ffffffffc02015c8:	32c60613          	addi	a2,a2,812 # ffffffffc02068f0 <commands+0x868>
ffffffffc02015cc:	12d00593          	li	a1,301
ffffffffc02015d0:	00005517          	auipc	a0,0x5
ffffffffc02015d4:	33850513          	addi	a0,a0,824 # ffffffffc0206908 <commands+0x880>
ffffffffc02015d8:	ebbfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02015dc:	00005697          	auipc	a3,0x5
ffffffffc02015e0:	58c68693          	addi	a3,a3,1420 # ffffffffc0206b68 <commands+0xae0>
ffffffffc02015e4:	00005617          	auipc	a2,0x5
ffffffffc02015e8:	30c60613          	addi	a2,a2,780 # ffffffffc02068f0 <commands+0x868>
ffffffffc02015ec:	12800593          	li	a1,296
ffffffffc02015f0:	00005517          	auipc	a0,0x5
ffffffffc02015f4:	31850513          	addi	a0,a0,792 # ffffffffc0206908 <commands+0x880>
ffffffffc02015f8:	e9bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015fc:	00005697          	auipc	a3,0x5
ffffffffc0201600:	46c68693          	addi	a3,a3,1132 # ffffffffc0206a68 <commands+0x9e0>
ffffffffc0201604:	00005617          	auipc	a2,0x5
ffffffffc0201608:	2ec60613          	addi	a2,a2,748 # ffffffffc02068f0 <commands+0x868>
ffffffffc020160c:	12700593          	li	a1,295
ffffffffc0201610:	00005517          	auipc	a0,0x5
ffffffffc0201614:	2f850513          	addi	a0,a0,760 # ffffffffc0206908 <commands+0x880>
ffffffffc0201618:	e7bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020161c:	00005697          	auipc	a3,0x5
ffffffffc0201620:	52c68693          	addi	a3,a3,1324 # ffffffffc0206b48 <commands+0xac0>
ffffffffc0201624:	00005617          	auipc	a2,0x5
ffffffffc0201628:	2cc60613          	addi	a2,a2,716 # ffffffffc02068f0 <commands+0x868>
ffffffffc020162c:	12600593          	li	a1,294
ffffffffc0201630:	00005517          	auipc	a0,0x5
ffffffffc0201634:	2d850513          	addi	a0,a0,728 # ffffffffc0206908 <commands+0x880>
ffffffffc0201638:	e5bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020163c:	00005697          	auipc	a3,0x5
ffffffffc0201640:	4dc68693          	addi	a3,a3,1244 # ffffffffc0206b18 <commands+0xa90>
ffffffffc0201644:	00005617          	auipc	a2,0x5
ffffffffc0201648:	2ac60613          	addi	a2,a2,684 # ffffffffc02068f0 <commands+0x868>
ffffffffc020164c:	12500593          	li	a1,293
ffffffffc0201650:	00005517          	auipc	a0,0x5
ffffffffc0201654:	2b850513          	addi	a0,a0,696 # ffffffffc0206908 <commands+0x880>
ffffffffc0201658:	e3bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020165c:	00005697          	auipc	a3,0x5
ffffffffc0201660:	4a468693          	addi	a3,a3,1188 # ffffffffc0206b00 <commands+0xa78>
ffffffffc0201664:	00005617          	auipc	a2,0x5
ffffffffc0201668:	28c60613          	addi	a2,a2,652 # ffffffffc02068f0 <commands+0x868>
ffffffffc020166c:	12400593          	li	a1,292
ffffffffc0201670:	00005517          	auipc	a0,0x5
ffffffffc0201674:	29850513          	addi	a0,a0,664 # ffffffffc0206908 <commands+0x880>
ffffffffc0201678:	e1bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020167c:	00005697          	auipc	a3,0x5
ffffffffc0201680:	3ec68693          	addi	a3,a3,1004 # ffffffffc0206a68 <commands+0x9e0>
ffffffffc0201684:	00005617          	auipc	a2,0x5
ffffffffc0201688:	26c60613          	addi	a2,a2,620 # ffffffffc02068f0 <commands+0x868>
ffffffffc020168c:	11e00593          	li	a1,286
ffffffffc0201690:	00005517          	auipc	a0,0x5
ffffffffc0201694:	27850513          	addi	a0,a0,632 # ffffffffc0206908 <commands+0x880>
ffffffffc0201698:	dfbfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!PageProperty(p0));
ffffffffc020169c:	00005697          	auipc	a3,0x5
ffffffffc02016a0:	44c68693          	addi	a3,a3,1100 # ffffffffc0206ae8 <commands+0xa60>
ffffffffc02016a4:	00005617          	auipc	a2,0x5
ffffffffc02016a8:	24c60613          	addi	a2,a2,588 # ffffffffc02068f0 <commands+0x868>
ffffffffc02016ac:	11900593          	li	a1,281
ffffffffc02016b0:	00005517          	auipc	a0,0x5
ffffffffc02016b4:	25850513          	addi	a0,a0,600 # ffffffffc0206908 <commands+0x880>
ffffffffc02016b8:	ddbfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02016bc:	00005697          	auipc	a3,0x5
ffffffffc02016c0:	54c68693          	addi	a3,a3,1356 # ffffffffc0206c08 <commands+0xb80>
ffffffffc02016c4:	00005617          	auipc	a2,0x5
ffffffffc02016c8:	22c60613          	addi	a2,a2,556 # ffffffffc02068f0 <commands+0x868>
ffffffffc02016cc:	13700593          	li	a1,311
ffffffffc02016d0:	00005517          	auipc	a0,0x5
ffffffffc02016d4:	23850513          	addi	a0,a0,568 # ffffffffc0206908 <commands+0x880>
ffffffffc02016d8:	dbbfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == 0);
ffffffffc02016dc:	00005697          	auipc	a3,0x5
ffffffffc02016e0:	55c68693          	addi	a3,a3,1372 # ffffffffc0206c38 <commands+0xbb0>
ffffffffc02016e4:	00005617          	auipc	a2,0x5
ffffffffc02016e8:	20c60613          	addi	a2,a2,524 # ffffffffc02068f0 <commands+0x868>
ffffffffc02016ec:	14700593          	li	a1,327
ffffffffc02016f0:	00005517          	auipc	a0,0x5
ffffffffc02016f4:	21850513          	addi	a0,a0,536 # ffffffffc0206908 <commands+0x880>
ffffffffc02016f8:	d9bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == nr_free_pages());
ffffffffc02016fc:	00005697          	auipc	a3,0x5
ffffffffc0201700:	22468693          	addi	a3,a3,548 # ffffffffc0206920 <commands+0x898>
ffffffffc0201704:	00005617          	auipc	a2,0x5
ffffffffc0201708:	1ec60613          	addi	a2,a2,492 # ffffffffc02068f0 <commands+0x868>
ffffffffc020170c:	11300593          	li	a1,275
ffffffffc0201710:	00005517          	auipc	a0,0x5
ffffffffc0201714:	1f850513          	addi	a0,a0,504 # ffffffffc0206908 <commands+0x880>
ffffffffc0201718:	d7bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020171c:	00005697          	auipc	a3,0x5
ffffffffc0201720:	24468693          	addi	a3,a3,580 # ffffffffc0206960 <commands+0x8d8>
ffffffffc0201724:	00005617          	auipc	a2,0x5
ffffffffc0201728:	1cc60613          	addi	a2,a2,460 # ffffffffc02068f0 <commands+0x868>
ffffffffc020172c:	0d800593          	li	a1,216
ffffffffc0201730:	00005517          	auipc	a0,0x5
ffffffffc0201734:	1d850513          	addi	a0,a0,472 # ffffffffc0206908 <commands+0x880>
ffffffffc0201738:	d5bfe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020173c <default_free_pages>:
{
ffffffffc020173c:	1141                	addi	sp,sp,-16
ffffffffc020173e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201740:	14058463          	beqz	a1,ffffffffc0201888 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201744:	00659693          	slli	a3,a1,0x6
ffffffffc0201748:	96aa                	add	a3,a3,a0
ffffffffc020174a:	87aa                	mv	a5,a0
ffffffffc020174c:	02d50263          	beq	a0,a3,ffffffffc0201770 <default_free_pages+0x34>
ffffffffc0201750:	6798                	ld	a4,8(a5)
ffffffffc0201752:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201754:	10071a63          	bnez	a4,ffffffffc0201868 <default_free_pages+0x12c>
ffffffffc0201758:	6798                	ld	a4,8(a5)
ffffffffc020175a:	8b09                	andi	a4,a4,2
ffffffffc020175c:	10071663          	bnez	a4,ffffffffc0201868 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201760:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201764:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201768:	04078793          	addi	a5,a5,64
ffffffffc020176c:	fed792e3          	bne	a5,a3,ffffffffc0201750 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201770:	2581                	sext.w	a1,a1
ffffffffc0201772:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201774:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201778:	4789                	li	a5,2
ffffffffc020177a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020177e:	000c1697          	auipc	a3,0xc1
ffffffffc0201782:	3a268693          	addi	a3,a3,930 # ffffffffc02c2b20 <free_area>
ffffffffc0201786:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201788:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020178a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020178e:	9db9                	addw	a1,a1,a4
ffffffffc0201790:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201792:	0ad78463          	beq	a5,a3,ffffffffc020183a <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc0201796:	fe878713          	addi	a4,a5,-24
ffffffffc020179a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc020179e:	4581                	li	a1,0
            if (base < page)
ffffffffc02017a0:	00e56a63          	bltu	a0,a4,ffffffffc02017b4 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02017a4:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02017a6:	04d70c63          	beq	a4,a3,ffffffffc02017fe <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc02017aa:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02017ac:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02017b0:	fee57ae3          	bgeu	a0,a4,ffffffffc02017a4 <default_free_pages+0x68>
ffffffffc02017b4:	c199                	beqz	a1,ffffffffc02017ba <default_free_pages+0x7e>
ffffffffc02017b6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017ba:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02017bc:	e390                	sd	a2,0(a5)
ffffffffc02017be:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02017c0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017c2:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02017c4:	00d70d63          	beq	a4,a3,ffffffffc02017de <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02017c8:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02017cc:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02017d0:	02059813          	slli	a6,a1,0x20
ffffffffc02017d4:	01a85793          	srli	a5,a6,0x1a
ffffffffc02017d8:	97b2                	add	a5,a5,a2
ffffffffc02017da:	02f50c63          	beq	a0,a5,ffffffffc0201812 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02017de:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02017e0:	00d78c63          	beq	a5,a3,ffffffffc02017f8 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02017e4:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02017e6:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02017ea:	02061593          	slli	a1,a2,0x20
ffffffffc02017ee:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02017f2:	972a                	add	a4,a4,a0
ffffffffc02017f4:	04e68a63          	beq	a3,a4,ffffffffc0201848 <default_free_pages+0x10c>
}
ffffffffc02017f8:	60a2                	ld	ra,8(sp)
ffffffffc02017fa:	0141                	addi	sp,sp,16
ffffffffc02017fc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017fe:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201800:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201802:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201804:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201806:	02d70763          	beq	a4,a3,ffffffffc0201834 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc020180a:	8832                	mv	a6,a2
ffffffffc020180c:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc020180e:	87ba                	mv	a5,a4
ffffffffc0201810:	bf71                	j	ffffffffc02017ac <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201812:	491c                	lw	a5,16(a0)
ffffffffc0201814:	9dbd                	addw	a1,a1,a5
ffffffffc0201816:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020181a:	57f5                	li	a5,-3
ffffffffc020181c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201820:	01853803          	ld	a6,24(a0)
ffffffffc0201824:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201826:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201828:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc020182c:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020182e:	0105b023          	sd	a6,0(a1)
ffffffffc0201832:	b77d                	j	ffffffffc02017e0 <default_free_pages+0xa4>
ffffffffc0201834:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201836:	873e                	mv	a4,a5
ffffffffc0201838:	bf41                	j	ffffffffc02017c8 <default_free_pages+0x8c>
}
ffffffffc020183a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020183c:	e390                	sd	a2,0(a5)
ffffffffc020183e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201840:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201842:	ed1c                	sd	a5,24(a0)
ffffffffc0201844:	0141                	addi	sp,sp,16
ffffffffc0201846:	8082                	ret
            base->property += p->property;
ffffffffc0201848:	ff87a703          	lw	a4,-8(a5)
ffffffffc020184c:	ff078693          	addi	a3,a5,-16
ffffffffc0201850:	9e39                	addw	a2,a2,a4
ffffffffc0201852:	c910                	sw	a2,16(a0)
ffffffffc0201854:	5775                	li	a4,-3
ffffffffc0201856:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020185a:	6398                	ld	a4,0(a5)
ffffffffc020185c:	679c                	ld	a5,8(a5)
}
ffffffffc020185e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201860:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201862:	e398                	sd	a4,0(a5)
ffffffffc0201864:	0141                	addi	sp,sp,16
ffffffffc0201866:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201868:	00005697          	auipc	a3,0x5
ffffffffc020186c:	3e868693          	addi	a3,a3,1000 # ffffffffc0206c50 <commands+0xbc8>
ffffffffc0201870:	00005617          	auipc	a2,0x5
ffffffffc0201874:	08060613          	addi	a2,a2,128 # ffffffffc02068f0 <commands+0x868>
ffffffffc0201878:	09400593          	li	a1,148
ffffffffc020187c:	00005517          	auipc	a0,0x5
ffffffffc0201880:	08c50513          	addi	a0,a0,140 # ffffffffc0206908 <commands+0x880>
ffffffffc0201884:	c0ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc0201888:	00005697          	auipc	a3,0x5
ffffffffc020188c:	3c068693          	addi	a3,a3,960 # ffffffffc0206c48 <commands+0xbc0>
ffffffffc0201890:	00005617          	auipc	a2,0x5
ffffffffc0201894:	06060613          	addi	a2,a2,96 # ffffffffc02068f0 <commands+0x868>
ffffffffc0201898:	09000593          	li	a1,144
ffffffffc020189c:	00005517          	auipc	a0,0x5
ffffffffc02018a0:	06c50513          	addi	a0,a0,108 # ffffffffc0206908 <commands+0x880>
ffffffffc02018a4:	beffe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02018a8 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02018a8:	c941                	beqz	a0,ffffffffc0201938 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc02018aa:	000c1597          	auipc	a1,0xc1
ffffffffc02018ae:	27658593          	addi	a1,a1,630 # ffffffffc02c2b20 <free_area>
ffffffffc02018b2:	0105a803          	lw	a6,16(a1)
ffffffffc02018b6:	872a                	mv	a4,a0
ffffffffc02018b8:	02081793          	slli	a5,a6,0x20
ffffffffc02018bc:	9381                	srli	a5,a5,0x20
ffffffffc02018be:	00a7ee63          	bltu	a5,a0,ffffffffc02018da <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02018c2:	87ae                	mv	a5,a1
ffffffffc02018c4:	a801                	j	ffffffffc02018d4 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc02018c6:	ff87a683          	lw	a3,-8(a5)
ffffffffc02018ca:	02069613          	slli	a2,a3,0x20
ffffffffc02018ce:	9201                	srli	a2,a2,0x20
ffffffffc02018d0:	00e67763          	bgeu	a2,a4,ffffffffc02018de <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02018d4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02018d6:	feb798e3          	bne	a5,a1,ffffffffc02018c6 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02018da:	4501                	li	a0,0
}
ffffffffc02018dc:	8082                	ret
    return listelm->prev;
ffffffffc02018de:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018e2:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02018e6:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02018ea:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02018ee:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02018f2:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc02018f6:	02c77863          	bgeu	a4,a2,ffffffffc0201926 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02018fa:	071a                	slli	a4,a4,0x6
ffffffffc02018fc:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02018fe:	41c686bb          	subw	a3,a3,t3
ffffffffc0201902:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201904:	00870613          	addi	a2,a4,8
ffffffffc0201908:	4689                	li	a3,2
ffffffffc020190a:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020190e:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201912:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201916:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020191a:	e290                	sd	a2,0(a3)
ffffffffc020191c:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201920:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201922:	01173c23          	sd	a7,24(a4)
ffffffffc0201926:	41c8083b          	subw	a6,a6,t3
ffffffffc020192a:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020192e:	5775                	li	a4,-3
ffffffffc0201930:	17c1                	addi	a5,a5,-16
ffffffffc0201932:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201936:	8082                	ret
{
ffffffffc0201938:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020193a:	00005697          	auipc	a3,0x5
ffffffffc020193e:	30e68693          	addi	a3,a3,782 # ffffffffc0206c48 <commands+0xbc0>
ffffffffc0201942:	00005617          	auipc	a2,0x5
ffffffffc0201946:	fae60613          	addi	a2,a2,-82 # ffffffffc02068f0 <commands+0x868>
ffffffffc020194a:	06c00593          	li	a1,108
ffffffffc020194e:	00005517          	auipc	a0,0x5
ffffffffc0201952:	fba50513          	addi	a0,a0,-70 # ffffffffc0206908 <commands+0x880>
{
ffffffffc0201956:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201958:	b3bfe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020195c <default_init_memmap>:
{
ffffffffc020195c:	1141                	addi	sp,sp,-16
ffffffffc020195e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201960:	c5f1                	beqz	a1,ffffffffc0201a2c <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201962:	00659693          	slli	a3,a1,0x6
ffffffffc0201966:	96aa                	add	a3,a3,a0
ffffffffc0201968:	87aa                	mv	a5,a0
ffffffffc020196a:	00d50f63          	beq	a0,a3,ffffffffc0201988 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020196e:	6798                	ld	a4,8(a5)
ffffffffc0201970:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201972:	cf49                	beqz	a4,ffffffffc0201a0c <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201974:	0007a823          	sw	zero,16(a5)
ffffffffc0201978:	0007b423          	sd	zero,8(a5)
ffffffffc020197c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201980:	04078793          	addi	a5,a5,64
ffffffffc0201984:	fed795e3          	bne	a5,a3,ffffffffc020196e <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201988:	2581                	sext.w	a1,a1
ffffffffc020198a:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020198c:	4789                	li	a5,2
ffffffffc020198e:	00850713          	addi	a4,a0,8
ffffffffc0201992:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201996:	000c1697          	auipc	a3,0xc1
ffffffffc020199a:	18a68693          	addi	a3,a3,394 # ffffffffc02c2b20 <free_area>
ffffffffc020199e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02019a0:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02019a2:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02019a6:	9db9                	addw	a1,a1,a4
ffffffffc02019a8:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02019aa:	04d78a63          	beq	a5,a3,ffffffffc02019fe <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc02019ae:	fe878713          	addi	a4,a5,-24
ffffffffc02019b2:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02019b6:	4581                	li	a1,0
            if (base < page)
ffffffffc02019b8:	00e56a63          	bltu	a0,a4,ffffffffc02019cc <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02019bc:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02019be:	02d70263          	beq	a4,a3,ffffffffc02019e2 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc02019c2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02019c4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02019c8:	fee57ae3          	bgeu	a0,a4,ffffffffc02019bc <default_init_memmap+0x60>
ffffffffc02019cc:	c199                	beqz	a1,ffffffffc02019d2 <default_init_memmap+0x76>
ffffffffc02019ce:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02019d2:	6398                	ld	a4,0(a5)
}
ffffffffc02019d4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02019d6:	e390                	sd	a2,0(a5)
ffffffffc02019d8:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02019da:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02019dc:	ed18                	sd	a4,24(a0)
ffffffffc02019de:	0141                	addi	sp,sp,16
ffffffffc02019e0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02019e2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02019e4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02019e6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02019e8:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc02019ea:	00d70663          	beq	a4,a3,ffffffffc02019f6 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc02019ee:	8832                	mv	a6,a2
ffffffffc02019f0:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc02019f2:	87ba                	mv	a5,a4
ffffffffc02019f4:	bfc1                	j	ffffffffc02019c4 <default_init_memmap+0x68>
}
ffffffffc02019f6:	60a2                	ld	ra,8(sp)
ffffffffc02019f8:	e290                	sd	a2,0(a3)
ffffffffc02019fa:	0141                	addi	sp,sp,16
ffffffffc02019fc:	8082                	ret
ffffffffc02019fe:	60a2                	ld	ra,8(sp)
ffffffffc0201a00:	e390                	sd	a2,0(a5)
ffffffffc0201a02:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a04:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a06:	ed1c                	sd	a5,24(a0)
ffffffffc0201a08:	0141                	addi	sp,sp,16
ffffffffc0201a0a:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a0c:	00005697          	auipc	a3,0x5
ffffffffc0201a10:	26c68693          	addi	a3,a3,620 # ffffffffc0206c78 <commands+0xbf0>
ffffffffc0201a14:	00005617          	auipc	a2,0x5
ffffffffc0201a18:	edc60613          	addi	a2,a2,-292 # ffffffffc02068f0 <commands+0x868>
ffffffffc0201a1c:	04b00593          	li	a1,75
ffffffffc0201a20:	00005517          	auipc	a0,0x5
ffffffffc0201a24:	ee850513          	addi	a0,a0,-280 # ffffffffc0206908 <commands+0x880>
ffffffffc0201a28:	a6bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc0201a2c:	00005697          	auipc	a3,0x5
ffffffffc0201a30:	21c68693          	addi	a3,a3,540 # ffffffffc0206c48 <commands+0xbc0>
ffffffffc0201a34:	00005617          	auipc	a2,0x5
ffffffffc0201a38:	ebc60613          	addi	a2,a2,-324 # ffffffffc02068f0 <commands+0x868>
ffffffffc0201a3c:	04700593          	li	a1,71
ffffffffc0201a40:	00005517          	auipc	a0,0x5
ffffffffc0201a44:	ec850513          	addi	a0,a0,-312 # ffffffffc0206908 <commands+0x880>
ffffffffc0201a48:	a4bfe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201a4c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201a4c:	c94d                	beqz	a0,ffffffffc0201afe <slob_free+0xb2>
{
ffffffffc0201a4e:	1141                	addi	sp,sp,-16
ffffffffc0201a50:	e022                	sd	s0,0(sp)
ffffffffc0201a52:	e406                	sd	ra,8(sp)
ffffffffc0201a54:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201a56:	e9c1                	bnez	a1,ffffffffc0201ae6 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a58:	100027f3          	csrr	a5,sstatus
ffffffffc0201a5c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a5e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a60:	ebd9                	bnez	a5,ffffffffc0201af6 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a62:	000c1617          	auipc	a2,0xc1
ffffffffc0201a66:	cae60613          	addi	a2,a2,-850 # ffffffffc02c2710 <slobfree>
ffffffffc0201a6a:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a6c:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a6e:	679c                	ld	a5,8(a5)
ffffffffc0201a70:	02877a63          	bgeu	a4,s0,ffffffffc0201aa4 <slob_free+0x58>
ffffffffc0201a74:	00f46463          	bltu	s0,a5,ffffffffc0201a7c <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a78:	fef76ae3          	bltu	a4,a5,ffffffffc0201a6c <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201a7c:	400c                	lw	a1,0(s0)
ffffffffc0201a7e:	00459693          	slli	a3,a1,0x4
ffffffffc0201a82:	96a2                	add	a3,a3,s0
ffffffffc0201a84:	02d78a63          	beq	a5,a3,ffffffffc0201ab8 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201a88:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201a8a:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201a8c:	00469793          	slli	a5,a3,0x4
ffffffffc0201a90:	97ba                	add	a5,a5,a4
ffffffffc0201a92:	02f40e63          	beq	s0,a5,ffffffffc0201ace <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201a96:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201a98:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201a9a:	e129                	bnez	a0,ffffffffc0201adc <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201a9c:	60a2                	ld	ra,8(sp)
ffffffffc0201a9e:	6402                	ld	s0,0(sp)
ffffffffc0201aa0:	0141                	addi	sp,sp,16
ffffffffc0201aa2:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201aa4:	fcf764e3          	bltu	a4,a5,ffffffffc0201a6c <slob_free+0x20>
ffffffffc0201aa8:	fcf472e3          	bgeu	s0,a5,ffffffffc0201a6c <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201aac:	400c                	lw	a1,0(s0)
ffffffffc0201aae:	00459693          	slli	a3,a1,0x4
ffffffffc0201ab2:	96a2                	add	a3,a3,s0
ffffffffc0201ab4:	fcd79ae3          	bne	a5,a3,ffffffffc0201a88 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201ab8:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201aba:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201abc:	9db5                	addw	a1,a1,a3
ffffffffc0201abe:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201ac0:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201ac2:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201ac4:	00469793          	slli	a5,a3,0x4
ffffffffc0201ac8:	97ba                	add	a5,a5,a4
ffffffffc0201aca:	fcf416e3          	bne	s0,a5,ffffffffc0201a96 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201ace:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201ad0:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201ad2:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201ad4:	9ebd                	addw	a3,a3,a5
ffffffffc0201ad6:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201ad8:	e70c                	sd	a1,8(a4)
ffffffffc0201ada:	d169                	beqz	a0,ffffffffc0201a9c <slob_free+0x50>
}
ffffffffc0201adc:	6402                	ld	s0,0(sp)
ffffffffc0201ade:	60a2                	ld	ra,8(sp)
ffffffffc0201ae0:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201ae2:	ec7fe06f          	j	ffffffffc02009a8 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201ae6:	25bd                	addiw	a1,a1,15
ffffffffc0201ae8:	8191                	srli	a1,a1,0x4
ffffffffc0201aea:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201aec:	100027f3          	csrr	a5,sstatus
ffffffffc0201af0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201af2:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201af4:	d7bd                	beqz	a5,ffffffffc0201a62 <slob_free+0x16>
        intr_disable();
ffffffffc0201af6:	eb9fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0201afa:	4505                	li	a0,1
ffffffffc0201afc:	b79d                	j	ffffffffc0201a62 <slob_free+0x16>
ffffffffc0201afe:	8082                	ret

ffffffffc0201b00 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b00:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b02:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b04:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b08:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b0a:	352000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
	if (!page)
ffffffffc0201b0e:	c91d                	beqz	a0,ffffffffc0201b44 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b10:	000c5697          	auipc	a3,0xc5
ffffffffc0201b14:	0b06b683          	ld	a3,176(a3) # ffffffffc02c6bc0 <pages>
ffffffffc0201b18:	8d15                	sub	a0,a0,a3
ffffffffc0201b1a:	8519                	srai	a0,a0,0x6
ffffffffc0201b1c:	00007697          	auipc	a3,0x7
ffffffffc0201b20:	ba46b683          	ld	a3,-1116(a3) # ffffffffc02086c0 <nbase>
ffffffffc0201b24:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201b26:	00c51793          	slli	a5,a0,0xc
ffffffffc0201b2a:	83b1                	srli	a5,a5,0xc
ffffffffc0201b2c:	000c5717          	auipc	a4,0xc5
ffffffffc0201b30:	08c73703          	ld	a4,140(a4) # ffffffffc02c6bb8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b34:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201b36:	00e7fa63          	bgeu	a5,a4,ffffffffc0201b4a <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201b3a:	000c5697          	auipc	a3,0xc5
ffffffffc0201b3e:	0966b683          	ld	a3,150(a3) # ffffffffc02c6bd0 <va_pa_offset>
ffffffffc0201b42:	9536                	add	a0,a0,a3
}
ffffffffc0201b44:	60a2                	ld	ra,8(sp)
ffffffffc0201b46:	0141                	addi	sp,sp,16
ffffffffc0201b48:	8082                	ret
ffffffffc0201b4a:	86aa                	mv	a3,a0
ffffffffc0201b4c:	00005617          	auipc	a2,0x5
ffffffffc0201b50:	18c60613          	addi	a2,a2,396 # ffffffffc0206cd8 <default_pmm_manager+0x38>
ffffffffc0201b54:	07100593          	li	a1,113
ffffffffc0201b58:	00005517          	auipc	a0,0x5
ffffffffc0201b5c:	1a850513          	addi	a0,a0,424 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc0201b60:	933fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201b64 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201b64:	1101                	addi	sp,sp,-32
ffffffffc0201b66:	ec06                	sd	ra,24(sp)
ffffffffc0201b68:	e822                	sd	s0,16(sp)
ffffffffc0201b6a:	e426                	sd	s1,8(sp)
ffffffffc0201b6c:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201b6e:	01050713          	addi	a4,a0,16
ffffffffc0201b72:	6785                	lui	a5,0x1
ffffffffc0201b74:	0cf77363          	bgeu	a4,a5,ffffffffc0201c3a <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201b78:	00f50493          	addi	s1,a0,15
ffffffffc0201b7c:	8091                	srli	s1,s1,0x4
ffffffffc0201b7e:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b80:	10002673          	csrr	a2,sstatus
ffffffffc0201b84:	8a09                	andi	a2,a2,2
ffffffffc0201b86:	e25d                	bnez	a2,ffffffffc0201c2c <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201b88:	000c1917          	auipc	s2,0xc1
ffffffffc0201b8c:	b8890913          	addi	s2,s2,-1144 # ffffffffc02c2710 <slobfree>
ffffffffc0201b90:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b94:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201b96:	4398                	lw	a4,0(a5)
ffffffffc0201b98:	08975e63          	bge	a4,s1,ffffffffc0201c34 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201b9c:	00f68b63          	beq	a3,a5,ffffffffc0201bb2 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ba0:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201ba2:	4018                	lw	a4,0(s0)
ffffffffc0201ba4:	02975a63          	bge	a4,s1,ffffffffc0201bd8 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201ba8:	00093683          	ld	a3,0(s2)
ffffffffc0201bac:	87a2                	mv	a5,s0
ffffffffc0201bae:	fef699e3          	bne	a3,a5,ffffffffc0201ba0 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201bb2:	ee31                	bnez	a2,ffffffffc0201c0e <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201bb4:	4501                	li	a0,0
ffffffffc0201bb6:	f4bff0ef          	jal	ra,ffffffffc0201b00 <__slob_get_free_pages.constprop.0>
ffffffffc0201bba:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201bbc:	cd05                	beqz	a0,ffffffffc0201bf4 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201bbe:	6585                	lui	a1,0x1
ffffffffc0201bc0:	e8dff0ef          	jal	ra,ffffffffc0201a4c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bc4:	10002673          	csrr	a2,sstatus
ffffffffc0201bc8:	8a09                	andi	a2,a2,2
ffffffffc0201bca:	ee05                	bnez	a2,ffffffffc0201c02 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201bcc:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bd0:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201bd2:	4018                	lw	a4,0(s0)
ffffffffc0201bd4:	fc974ae3          	blt	a4,s1,ffffffffc0201ba8 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201bd8:	04e48763          	beq	s1,a4,ffffffffc0201c26 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201bdc:	00449693          	slli	a3,s1,0x4
ffffffffc0201be0:	96a2                	add	a3,a3,s0
ffffffffc0201be2:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201be4:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201be6:	9f05                	subw	a4,a4,s1
ffffffffc0201be8:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201bea:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201bec:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201bee:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201bf2:	e20d                	bnez	a2,ffffffffc0201c14 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201bf4:	60e2                	ld	ra,24(sp)
ffffffffc0201bf6:	8522                	mv	a0,s0
ffffffffc0201bf8:	6442                	ld	s0,16(sp)
ffffffffc0201bfa:	64a2                	ld	s1,8(sp)
ffffffffc0201bfc:	6902                	ld	s2,0(sp)
ffffffffc0201bfe:	6105                	addi	sp,sp,32
ffffffffc0201c00:	8082                	ret
        intr_disable();
ffffffffc0201c02:	dadfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
			cur = slobfree;
ffffffffc0201c06:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201c0a:	4605                	li	a2,1
ffffffffc0201c0c:	b7d1                	j	ffffffffc0201bd0 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201c0e:	d9bfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201c12:	b74d                	j	ffffffffc0201bb4 <slob_alloc.constprop.0+0x50>
ffffffffc0201c14:	d95fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
}
ffffffffc0201c18:	60e2                	ld	ra,24(sp)
ffffffffc0201c1a:	8522                	mv	a0,s0
ffffffffc0201c1c:	6442                	ld	s0,16(sp)
ffffffffc0201c1e:	64a2                	ld	s1,8(sp)
ffffffffc0201c20:	6902                	ld	s2,0(sp)
ffffffffc0201c22:	6105                	addi	sp,sp,32
ffffffffc0201c24:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201c26:	6418                	ld	a4,8(s0)
ffffffffc0201c28:	e798                	sd	a4,8(a5)
ffffffffc0201c2a:	b7d1                	j	ffffffffc0201bee <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201c2c:	d83fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0201c30:	4605                	li	a2,1
ffffffffc0201c32:	bf99                	j	ffffffffc0201b88 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201c34:	843e                	mv	s0,a5
ffffffffc0201c36:	87b6                	mv	a5,a3
ffffffffc0201c38:	b745                	j	ffffffffc0201bd8 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c3a:	00005697          	auipc	a3,0x5
ffffffffc0201c3e:	0d668693          	addi	a3,a3,214 # ffffffffc0206d10 <default_pmm_manager+0x70>
ffffffffc0201c42:	00005617          	auipc	a2,0x5
ffffffffc0201c46:	cae60613          	addi	a2,a2,-850 # ffffffffc02068f0 <commands+0x868>
ffffffffc0201c4a:	06300593          	li	a1,99
ffffffffc0201c4e:	00005517          	auipc	a0,0x5
ffffffffc0201c52:	0e250513          	addi	a0,a0,226 # ffffffffc0206d30 <default_pmm_manager+0x90>
ffffffffc0201c56:	83dfe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201c5a <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201c5a:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201c5c:	00005517          	auipc	a0,0x5
ffffffffc0201c60:	0ec50513          	addi	a0,a0,236 # ffffffffc0206d48 <default_pmm_manager+0xa8>
{
ffffffffc0201c64:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201c66:	d32fe0ef          	jal	ra,ffffffffc0200198 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201c6a:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c6c:	00005517          	auipc	a0,0x5
ffffffffc0201c70:	0f450513          	addi	a0,a0,244 # ffffffffc0206d60 <default_pmm_manager+0xc0>
}
ffffffffc0201c74:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c76:	d22fe06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0201c7a <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201c7a:	4501                	li	a0,0
ffffffffc0201c7c:	8082                	ret

ffffffffc0201c7e <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201c7e:	1101                	addi	sp,sp,-32
ffffffffc0201c80:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201c82:	6905                	lui	s2,0x1
{
ffffffffc0201c84:	e822                	sd	s0,16(sp)
ffffffffc0201c86:	ec06                	sd	ra,24(sp)
ffffffffc0201c88:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201c8a:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8f51>
{
ffffffffc0201c8e:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201c90:	04a7f963          	bgeu	a5,a0,ffffffffc0201ce2 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201c94:	4561                	li	a0,24
ffffffffc0201c96:	ecfff0ef          	jal	ra,ffffffffc0201b64 <slob_alloc.constprop.0>
ffffffffc0201c9a:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201c9c:	c929                	beqz	a0,ffffffffc0201cee <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201c9e:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201ca2:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201ca4:	00f95763          	bge	s2,a5,ffffffffc0201cb2 <kmalloc+0x34>
ffffffffc0201ca8:	6705                	lui	a4,0x1
ffffffffc0201caa:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201cac:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201cae:	fef74ee3          	blt	a4,a5,ffffffffc0201caa <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201cb2:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201cb4:	e4dff0ef          	jal	ra,ffffffffc0201b00 <__slob_get_free_pages.constprop.0>
ffffffffc0201cb8:	e488                	sd	a0,8(s1)
ffffffffc0201cba:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201cbc:	c525                	beqz	a0,ffffffffc0201d24 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201cbe:	100027f3          	csrr	a5,sstatus
ffffffffc0201cc2:	8b89                	andi	a5,a5,2
ffffffffc0201cc4:	ef8d                	bnez	a5,ffffffffc0201cfe <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201cc6:	000c5797          	auipc	a5,0xc5
ffffffffc0201cca:	eda78793          	addi	a5,a5,-294 # ffffffffc02c6ba0 <bigblocks>
ffffffffc0201cce:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201cd0:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201cd2:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201cd4:	60e2                	ld	ra,24(sp)
ffffffffc0201cd6:	8522                	mv	a0,s0
ffffffffc0201cd8:	6442                	ld	s0,16(sp)
ffffffffc0201cda:	64a2                	ld	s1,8(sp)
ffffffffc0201cdc:	6902                	ld	s2,0(sp)
ffffffffc0201cde:	6105                	addi	sp,sp,32
ffffffffc0201ce0:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201ce2:	0541                	addi	a0,a0,16
ffffffffc0201ce4:	e81ff0ef          	jal	ra,ffffffffc0201b64 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201ce8:	01050413          	addi	s0,a0,16
ffffffffc0201cec:	f565                	bnez	a0,ffffffffc0201cd4 <kmalloc+0x56>
ffffffffc0201cee:	4401                	li	s0,0
}
ffffffffc0201cf0:	60e2                	ld	ra,24(sp)
ffffffffc0201cf2:	8522                	mv	a0,s0
ffffffffc0201cf4:	6442                	ld	s0,16(sp)
ffffffffc0201cf6:	64a2                	ld	s1,8(sp)
ffffffffc0201cf8:	6902                	ld	s2,0(sp)
ffffffffc0201cfa:	6105                	addi	sp,sp,32
ffffffffc0201cfc:	8082                	ret
        intr_disable();
ffffffffc0201cfe:	cb1fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d02:	000c5797          	auipc	a5,0xc5
ffffffffc0201d06:	e9e78793          	addi	a5,a5,-354 # ffffffffc02c6ba0 <bigblocks>
ffffffffc0201d0a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d0c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d0e:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201d10:	c99fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
		return bb->pages;
ffffffffc0201d14:	6480                	ld	s0,8(s1)
}
ffffffffc0201d16:	60e2                	ld	ra,24(sp)
ffffffffc0201d18:	64a2                	ld	s1,8(sp)
ffffffffc0201d1a:	8522                	mv	a0,s0
ffffffffc0201d1c:	6442                	ld	s0,16(sp)
ffffffffc0201d1e:	6902                	ld	s2,0(sp)
ffffffffc0201d20:	6105                	addi	sp,sp,32
ffffffffc0201d22:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d24:	45e1                	li	a1,24
ffffffffc0201d26:	8526                	mv	a0,s1
ffffffffc0201d28:	d25ff0ef          	jal	ra,ffffffffc0201a4c <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201d2c:	b765                	j	ffffffffc0201cd4 <kmalloc+0x56>

ffffffffc0201d2e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d2e:	c169                	beqz	a0,ffffffffc0201df0 <kfree+0xc2>
{
ffffffffc0201d30:	1101                	addi	sp,sp,-32
ffffffffc0201d32:	e822                	sd	s0,16(sp)
ffffffffc0201d34:	ec06                	sd	ra,24(sp)
ffffffffc0201d36:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201d38:	03451793          	slli	a5,a0,0x34
ffffffffc0201d3c:	842a                	mv	s0,a0
ffffffffc0201d3e:	e3d9                	bnez	a5,ffffffffc0201dc4 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d40:	100027f3          	csrr	a5,sstatus
ffffffffc0201d44:	8b89                	andi	a5,a5,2
ffffffffc0201d46:	e7d9                	bnez	a5,ffffffffc0201dd4 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d48:	000c5797          	auipc	a5,0xc5
ffffffffc0201d4c:	e587b783          	ld	a5,-424(a5) # ffffffffc02c6ba0 <bigblocks>
    return 0;
ffffffffc0201d50:	4601                	li	a2,0
ffffffffc0201d52:	cbad                	beqz	a5,ffffffffc0201dc4 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201d54:	000c5697          	auipc	a3,0xc5
ffffffffc0201d58:	e4c68693          	addi	a3,a3,-436 # ffffffffc02c6ba0 <bigblocks>
ffffffffc0201d5c:	a021                	j	ffffffffc0201d64 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d5e:	01048693          	addi	a3,s1,16
ffffffffc0201d62:	c3a5                	beqz	a5,ffffffffc0201dc2 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201d64:	6798                	ld	a4,8(a5)
ffffffffc0201d66:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201d68:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201d6a:	fe871ae3          	bne	a4,s0,ffffffffc0201d5e <kfree+0x30>
				*last = bb->next;
ffffffffc0201d6e:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201d70:	ee2d                	bnez	a2,ffffffffc0201dea <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201d72:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201d76:	4098                	lw	a4,0(s1)
ffffffffc0201d78:	08f46963          	bltu	s0,a5,ffffffffc0201e0a <kfree+0xdc>
ffffffffc0201d7c:	000c5697          	auipc	a3,0xc5
ffffffffc0201d80:	e546b683          	ld	a3,-428(a3) # ffffffffc02c6bd0 <va_pa_offset>
ffffffffc0201d84:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201d86:	8031                	srli	s0,s0,0xc
ffffffffc0201d88:	000c5797          	auipc	a5,0xc5
ffffffffc0201d8c:	e307b783          	ld	a5,-464(a5) # ffffffffc02c6bb8 <npage>
ffffffffc0201d90:	06f47163          	bgeu	s0,a5,ffffffffc0201df2 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d94:	00007517          	auipc	a0,0x7
ffffffffc0201d98:	92c53503          	ld	a0,-1748(a0) # ffffffffc02086c0 <nbase>
ffffffffc0201d9c:	8c09                	sub	s0,s0,a0
ffffffffc0201d9e:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201da0:	000c5517          	auipc	a0,0xc5
ffffffffc0201da4:	e2053503          	ld	a0,-480(a0) # ffffffffc02c6bc0 <pages>
ffffffffc0201da8:	4585                	li	a1,1
ffffffffc0201daa:	9522                	add	a0,a0,s0
ffffffffc0201dac:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201db0:	0ea000ef          	jal	ra,ffffffffc0201e9a <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201db4:	6442                	ld	s0,16(sp)
ffffffffc0201db6:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201db8:	8526                	mv	a0,s1
}
ffffffffc0201dba:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dbc:	45e1                	li	a1,24
}
ffffffffc0201dbe:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dc0:	b171                	j	ffffffffc0201a4c <slob_free>
ffffffffc0201dc2:	e20d                	bnez	a2,ffffffffc0201de4 <kfree+0xb6>
ffffffffc0201dc4:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201dc8:	6442                	ld	s0,16(sp)
ffffffffc0201dca:	60e2                	ld	ra,24(sp)
ffffffffc0201dcc:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dce:	4581                	li	a1,0
}
ffffffffc0201dd0:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dd2:	b9ad                	j	ffffffffc0201a4c <slob_free>
        intr_disable();
ffffffffc0201dd4:	bdbfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201dd8:	000c5797          	auipc	a5,0xc5
ffffffffc0201ddc:	dc87b783          	ld	a5,-568(a5) # ffffffffc02c6ba0 <bigblocks>
        return 1;
ffffffffc0201de0:	4605                	li	a2,1
ffffffffc0201de2:	fbad                	bnez	a5,ffffffffc0201d54 <kfree+0x26>
        intr_enable();
ffffffffc0201de4:	bc5fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201de8:	bff1                	j	ffffffffc0201dc4 <kfree+0x96>
ffffffffc0201dea:	bbffe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201dee:	b751                	j	ffffffffc0201d72 <kfree+0x44>
ffffffffc0201df0:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201df2:	00005617          	auipc	a2,0x5
ffffffffc0201df6:	fb660613          	addi	a2,a2,-74 # ffffffffc0206da8 <default_pmm_manager+0x108>
ffffffffc0201dfa:	06900593          	li	a1,105
ffffffffc0201dfe:	00005517          	auipc	a0,0x5
ffffffffc0201e02:	f0250513          	addi	a0,a0,-254 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc0201e06:	e8cfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e0a:	86a2                	mv	a3,s0
ffffffffc0201e0c:	00005617          	auipc	a2,0x5
ffffffffc0201e10:	f7460613          	addi	a2,a2,-140 # ffffffffc0206d80 <default_pmm_manager+0xe0>
ffffffffc0201e14:	07700593          	li	a1,119
ffffffffc0201e18:	00005517          	auipc	a0,0x5
ffffffffc0201e1c:	ee850513          	addi	a0,a0,-280 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc0201e20:	e72fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201e24 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201e24:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e26:	00005617          	auipc	a2,0x5
ffffffffc0201e2a:	f8260613          	addi	a2,a2,-126 # ffffffffc0206da8 <default_pmm_manager+0x108>
ffffffffc0201e2e:	06900593          	li	a1,105
ffffffffc0201e32:	00005517          	auipc	a0,0x5
ffffffffc0201e36:	ece50513          	addi	a0,a0,-306 # ffffffffc0206d00 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201e3a:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e3c:	e56fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201e40 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201e40:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201e42:	00005617          	auipc	a2,0x5
ffffffffc0201e46:	f8660613          	addi	a2,a2,-122 # ffffffffc0206dc8 <default_pmm_manager+0x128>
ffffffffc0201e4a:	07f00593          	li	a1,127
ffffffffc0201e4e:	00005517          	auipc	a0,0x5
ffffffffc0201e52:	eb250513          	addi	a0,a0,-334 # ffffffffc0206d00 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201e56:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201e58:	e3afe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201e5c <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e5c:	100027f3          	csrr	a5,sstatus
ffffffffc0201e60:	8b89                	andi	a5,a5,2
ffffffffc0201e62:	e799                	bnez	a5,ffffffffc0201e70 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e64:	000c5797          	auipc	a5,0xc5
ffffffffc0201e68:	d647b783          	ld	a5,-668(a5) # ffffffffc02c6bc8 <pmm_manager>
ffffffffc0201e6c:	6f9c                	ld	a5,24(a5)
ffffffffc0201e6e:	8782                	jr	a5
{
ffffffffc0201e70:	1141                	addi	sp,sp,-16
ffffffffc0201e72:	e406                	sd	ra,8(sp)
ffffffffc0201e74:	e022                	sd	s0,0(sp)
ffffffffc0201e76:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201e78:	b37fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e7c:	000c5797          	auipc	a5,0xc5
ffffffffc0201e80:	d4c7b783          	ld	a5,-692(a5) # ffffffffc02c6bc8 <pmm_manager>
ffffffffc0201e84:	6f9c                	ld	a5,24(a5)
ffffffffc0201e86:	8522                	mv	a0,s0
ffffffffc0201e88:	9782                	jalr	a5
ffffffffc0201e8a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201e8c:	b1dfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201e90:	60a2                	ld	ra,8(sp)
ffffffffc0201e92:	8522                	mv	a0,s0
ffffffffc0201e94:	6402                	ld	s0,0(sp)
ffffffffc0201e96:	0141                	addi	sp,sp,16
ffffffffc0201e98:	8082                	ret

ffffffffc0201e9a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e9a:	100027f3          	csrr	a5,sstatus
ffffffffc0201e9e:	8b89                	andi	a5,a5,2
ffffffffc0201ea0:	e799                	bnez	a5,ffffffffc0201eae <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ea2:	000c5797          	auipc	a5,0xc5
ffffffffc0201ea6:	d267b783          	ld	a5,-730(a5) # ffffffffc02c6bc8 <pmm_manager>
ffffffffc0201eaa:	739c                	ld	a5,32(a5)
ffffffffc0201eac:	8782                	jr	a5
{
ffffffffc0201eae:	1101                	addi	sp,sp,-32
ffffffffc0201eb0:	ec06                	sd	ra,24(sp)
ffffffffc0201eb2:	e822                	sd	s0,16(sp)
ffffffffc0201eb4:	e426                	sd	s1,8(sp)
ffffffffc0201eb6:	842a                	mv	s0,a0
ffffffffc0201eb8:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201eba:	af5fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201ebe:	000c5797          	auipc	a5,0xc5
ffffffffc0201ec2:	d0a7b783          	ld	a5,-758(a5) # ffffffffc02c6bc8 <pmm_manager>
ffffffffc0201ec6:	739c                	ld	a5,32(a5)
ffffffffc0201ec8:	85a6                	mv	a1,s1
ffffffffc0201eca:	8522                	mv	a0,s0
ffffffffc0201ecc:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201ece:	6442                	ld	s0,16(sp)
ffffffffc0201ed0:	60e2                	ld	ra,24(sp)
ffffffffc0201ed2:	64a2                	ld	s1,8(sp)
ffffffffc0201ed4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201ed6:	ad3fe06f          	j	ffffffffc02009a8 <intr_enable>

ffffffffc0201eda <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201eda:	100027f3          	csrr	a5,sstatus
ffffffffc0201ede:	8b89                	andi	a5,a5,2
ffffffffc0201ee0:	e799                	bnez	a5,ffffffffc0201eee <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201ee2:	000c5797          	auipc	a5,0xc5
ffffffffc0201ee6:	ce67b783          	ld	a5,-794(a5) # ffffffffc02c6bc8 <pmm_manager>
ffffffffc0201eea:	779c                	ld	a5,40(a5)
ffffffffc0201eec:	8782                	jr	a5
{
ffffffffc0201eee:	1141                	addi	sp,sp,-16
ffffffffc0201ef0:	e406                	sd	ra,8(sp)
ffffffffc0201ef2:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201ef4:	abbfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201ef8:	000c5797          	auipc	a5,0xc5
ffffffffc0201efc:	cd07b783          	ld	a5,-816(a5) # ffffffffc02c6bc8 <pmm_manager>
ffffffffc0201f00:	779c                	ld	a5,40(a5)
ffffffffc0201f02:	9782                	jalr	a5
ffffffffc0201f04:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f06:	aa3fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f0a:	60a2                	ld	ra,8(sp)
ffffffffc0201f0c:	8522                	mv	a0,s0
ffffffffc0201f0e:	6402                	ld	s0,0(sp)
ffffffffc0201f10:	0141                	addi	sp,sp,16
ffffffffc0201f12:	8082                	ret

ffffffffc0201f14 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f14:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f18:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201f1c:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f1e:	078e                	slli	a5,a5,0x3
{
ffffffffc0201f20:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f22:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201f26:	6094                	ld	a3,0(s1)
{
ffffffffc0201f28:	f04a                	sd	s2,32(sp)
ffffffffc0201f2a:	ec4e                	sd	s3,24(sp)
ffffffffc0201f2c:	e852                	sd	s4,16(sp)
ffffffffc0201f2e:	fc06                	sd	ra,56(sp)
ffffffffc0201f30:	f822                	sd	s0,48(sp)
ffffffffc0201f32:	e456                	sd	s5,8(sp)
ffffffffc0201f34:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201f36:	0016f793          	andi	a5,a3,1
{
ffffffffc0201f3a:	892e                	mv	s2,a1
ffffffffc0201f3c:	8a32                	mv	s4,a2
ffffffffc0201f3e:	000c5997          	auipc	s3,0xc5
ffffffffc0201f42:	c7a98993          	addi	s3,s3,-902 # ffffffffc02c6bb8 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201f46:	efbd                	bnez	a5,ffffffffc0201fc4 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f48:	14060c63          	beqz	a2,ffffffffc02020a0 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f4c:	100027f3          	csrr	a5,sstatus
ffffffffc0201f50:	8b89                	andi	a5,a5,2
ffffffffc0201f52:	14079963          	bnez	a5,ffffffffc02020a4 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f56:	000c5797          	auipc	a5,0xc5
ffffffffc0201f5a:	c727b783          	ld	a5,-910(a5) # ffffffffc02c6bc8 <pmm_manager>
ffffffffc0201f5e:	6f9c                	ld	a5,24(a5)
ffffffffc0201f60:	4505                	li	a0,1
ffffffffc0201f62:	9782                	jalr	a5
ffffffffc0201f64:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f66:	12040d63          	beqz	s0,ffffffffc02020a0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201f6a:	000c5b17          	auipc	s6,0xc5
ffffffffc0201f6e:	c56b0b13          	addi	s6,s6,-938 # ffffffffc02c6bc0 <pages>
ffffffffc0201f72:	000b3503          	ld	a0,0(s6)
ffffffffc0201f76:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f7a:	000c5997          	auipc	s3,0xc5
ffffffffc0201f7e:	c3e98993          	addi	s3,s3,-962 # ffffffffc02c6bb8 <npage>
ffffffffc0201f82:	40a40533          	sub	a0,s0,a0
ffffffffc0201f86:	8519                	srai	a0,a0,0x6
ffffffffc0201f88:	9556                	add	a0,a0,s5
ffffffffc0201f8a:	0009b703          	ld	a4,0(s3)
ffffffffc0201f8e:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201f92:	4685                	li	a3,1
ffffffffc0201f94:	c014                	sw	a3,0(s0)
ffffffffc0201f96:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f98:	0532                	slli	a0,a0,0xc
ffffffffc0201f9a:	16e7f763          	bgeu	a5,a4,ffffffffc0202108 <get_pte+0x1f4>
ffffffffc0201f9e:	000c5797          	auipc	a5,0xc5
ffffffffc0201fa2:	c327b783          	ld	a5,-974(a5) # ffffffffc02c6bd0 <va_pa_offset>
ffffffffc0201fa6:	6605                	lui	a2,0x1
ffffffffc0201fa8:	4581                	li	a1,0
ffffffffc0201faa:	953e                	add	a0,a0,a5
ffffffffc0201fac:	645030ef          	jal	ra,ffffffffc0205df0 <memset>
    return page - pages + nbase;
ffffffffc0201fb0:	000b3683          	ld	a3,0(s6)
ffffffffc0201fb4:	40d406b3          	sub	a3,s0,a3
ffffffffc0201fb8:	8699                	srai	a3,a3,0x6
ffffffffc0201fba:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201fbc:	06aa                	slli	a3,a3,0xa
ffffffffc0201fbe:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201fc2:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201fc4:	77fd                	lui	a5,0xfffff
ffffffffc0201fc6:	068a                	slli	a3,a3,0x2
ffffffffc0201fc8:	0009b703          	ld	a4,0(s3)
ffffffffc0201fcc:	8efd                	and	a3,a3,a5
ffffffffc0201fce:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201fd2:	10e7ff63          	bgeu	a5,a4,ffffffffc02020f0 <get_pte+0x1dc>
ffffffffc0201fd6:	000c5a97          	auipc	s5,0xc5
ffffffffc0201fda:	bfaa8a93          	addi	s5,s5,-1030 # ffffffffc02c6bd0 <va_pa_offset>
ffffffffc0201fde:	000ab403          	ld	s0,0(s5)
ffffffffc0201fe2:	01595793          	srli	a5,s2,0x15
ffffffffc0201fe6:	1ff7f793          	andi	a5,a5,511
ffffffffc0201fea:	96a2                	add	a3,a3,s0
ffffffffc0201fec:	00379413          	slli	s0,a5,0x3
ffffffffc0201ff0:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201ff2:	6014                	ld	a3,0(s0)
ffffffffc0201ff4:	0016f793          	andi	a5,a3,1
ffffffffc0201ff8:	ebad                	bnez	a5,ffffffffc020206a <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201ffa:	0a0a0363          	beqz	s4,ffffffffc02020a0 <get_pte+0x18c>
ffffffffc0201ffe:	100027f3          	csrr	a5,sstatus
ffffffffc0202002:	8b89                	andi	a5,a5,2
ffffffffc0202004:	efcd                	bnez	a5,ffffffffc02020be <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202006:	000c5797          	auipc	a5,0xc5
ffffffffc020200a:	bc27b783          	ld	a5,-1086(a5) # ffffffffc02c6bc8 <pmm_manager>
ffffffffc020200e:	6f9c                	ld	a5,24(a5)
ffffffffc0202010:	4505                	li	a0,1
ffffffffc0202012:	9782                	jalr	a5
ffffffffc0202014:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202016:	c4c9                	beqz	s1,ffffffffc02020a0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0202018:	000c5b17          	auipc	s6,0xc5
ffffffffc020201c:	ba8b0b13          	addi	s6,s6,-1112 # ffffffffc02c6bc0 <pages>
ffffffffc0202020:	000b3503          	ld	a0,0(s6)
ffffffffc0202024:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202028:	0009b703          	ld	a4,0(s3)
ffffffffc020202c:	40a48533          	sub	a0,s1,a0
ffffffffc0202030:	8519                	srai	a0,a0,0x6
ffffffffc0202032:	9552                	add	a0,a0,s4
ffffffffc0202034:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202038:	4685                	li	a3,1
ffffffffc020203a:	c094                	sw	a3,0(s1)
ffffffffc020203c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020203e:	0532                	slli	a0,a0,0xc
ffffffffc0202040:	0ee7f163          	bgeu	a5,a4,ffffffffc0202122 <get_pte+0x20e>
ffffffffc0202044:	000ab783          	ld	a5,0(s5)
ffffffffc0202048:	6605                	lui	a2,0x1
ffffffffc020204a:	4581                	li	a1,0
ffffffffc020204c:	953e                	add	a0,a0,a5
ffffffffc020204e:	5a3030ef          	jal	ra,ffffffffc0205df0 <memset>
    return page - pages + nbase;
ffffffffc0202052:	000b3683          	ld	a3,0(s6)
ffffffffc0202056:	40d486b3          	sub	a3,s1,a3
ffffffffc020205a:	8699                	srai	a3,a3,0x6
ffffffffc020205c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020205e:	06aa                	slli	a3,a3,0xa
ffffffffc0202060:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202064:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202066:	0009b703          	ld	a4,0(s3)
ffffffffc020206a:	068a                	slli	a3,a3,0x2
ffffffffc020206c:	757d                	lui	a0,0xfffff
ffffffffc020206e:	8ee9                	and	a3,a3,a0
ffffffffc0202070:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202074:	06e7f263          	bgeu	a5,a4,ffffffffc02020d8 <get_pte+0x1c4>
ffffffffc0202078:	000ab503          	ld	a0,0(s5)
ffffffffc020207c:	00c95913          	srli	s2,s2,0xc
ffffffffc0202080:	1ff97913          	andi	s2,s2,511
ffffffffc0202084:	96aa                	add	a3,a3,a0
ffffffffc0202086:	00391513          	slli	a0,s2,0x3
ffffffffc020208a:	9536                	add	a0,a0,a3
}
ffffffffc020208c:	70e2                	ld	ra,56(sp)
ffffffffc020208e:	7442                	ld	s0,48(sp)
ffffffffc0202090:	74a2                	ld	s1,40(sp)
ffffffffc0202092:	7902                	ld	s2,32(sp)
ffffffffc0202094:	69e2                	ld	s3,24(sp)
ffffffffc0202096:	6a42                	ld	s4,16(sp)
ffffffffc0202098:	6aa2                	ld	s5,8(sp)
ffffffffc020209a:	6b02                	ld	s6,0(sp)
ffffffffc020209c:	6121                	addi	sp,sp,64
ffffffffc020209e:	8082                	ret
            return NULL;
ffffffffc02020a0:	4501                	li	a0,0
ffffffffc02020a2:	b7ed                	j	ffffffffc020208c <get_pte+0x178>
        intr_disable();
ffffffffc02020a4:	90bfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020a8:	000c5797          	auipc	a5,0xc5
ffffffffc02020ac:	b207b783          	ld	a5,-1248(a5) # ffffffffc02c6bc8 <pmm_manager>
ffffffffc02020b0:	6f9c                	ld	a5,24(a5)
ffffffffc02020b2:	4505                	li	a0,1
ffffffffc02020b4:	9782                	jalr	a5
ffffffffc02020b6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02020b8:	8f1fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02020bc:	b56d                	j	ffffffffc0201f66 <get_pte+0x52>
        intr_disable();
ffffffffc02020be:	8f1fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02020c2:	000c5797          	auipc	a5,0xc5
ffffffffc02020c6:	b067b783          	ld	a5,-1274(a5) # ffffffffc02c6bc8 <pmm_manager>
ffffffffc02020ca:	6f9c                	ld	a5,24(a5)
ffffffffc02020cc:	4505                	li	a0,1
ffffffffc02020ce:	9782                	jalr	a5
ffffffffc02020d0:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc02020d2:	8d7fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02020d6:	b781                	j	ffffffffc0202016 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020d8:	00005617          	auipc	a2,0x5
ffffffffc02020dc:	c0060613          	addi	a2,a2,-1024 # ffffffffc0206cd8 <default_pmm_manager+0x38>
ffffffffc02020e0:	0fa00593          	li	a1,250
ffffffffc02020e4:	00005517          	auipc	a0,0x5
ffffffffc02020e8:	d0c50513          	addi	a0,a0,-756 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc02020ec:	ba6fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02020f0:	00005617          	auipc	a2,0x5
ffffffffc02020f4:	be860613          	addi	a2,a2,-1048 # ffffffffc0206cd8 <default_pmm_manager+0x38>
ffffffffc02020f8:	0ed00593          	li	a1,237
ffffffffc02020fc:	00005517          	auipc	a0,0x5
ffffffffc0202100:	cf450513          	addi	a0,a0,-780 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202104:	b8efe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202108:	86aa                	mv	a3,a0
ffffffffc020210a:	00005617          	auipc	a2,0x5
ffffffffc020210e:	bce60613          	addi	a2,a2,-1074 # ffffffffc0206cd8 <default_pmm_manager+0x38>
ffffffffc0202112:	0e900593          	li	a1,233
ffffffffc0202116:	00005517          	auipc	a0,0x5
ffffffffc020211a:	cda50513          	addi	a0,a0,-806 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc020211e:	b74fe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202122:	86aa                	mv	a3,a0
ffffffffc0202124:	00005617          	auipc	a2,0x5
ffffffffc0202128:	bb460613          	addi	a2,a2,-1100 # ffffffffc0206cd8 <default_pmm_manager+0x38>
ffffffffc020212c:	0f700593          	li	a1,247
ffffffffc0202130:	00005517          	auipc	a0,0x5
ffffffffc0202134:	cc050513          	addi	a0,a0,-832 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202138:	b5afe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020213c <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc020213c:	1141                	addi	sp,sp,-16
ffffffffc020213e:	e022                	sd	s0,0(sp)
ffffffffc0202140:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202142:	4601                	li	a2,0
{
ffffffffc0202144:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202146:	dcfff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
    if (ptep_store != NULL)
ffffffffc020214a:	c011                	beqz	s0,ffffffffc020214e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc020214c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020214e:	c511                	beqz	a0,ffffffffc020215a <get_page+0x1e>
ffffffffc0202150:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202152:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202154:	0017f713          	andi	a4,a5,1
ffffffffc0202158:	e709                	bnez	a4,ffffffffc0202162 <get_page+0x26>
}
ffffffffc020215a:	60a2                	ld	ra,8(sp)
ffffffffc020215c:	6402                	ld	s0,0(sp)
ffffffffc020215e:	0141                	addi	sp,sp,16
ffffffffc0202160:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202162:	078a                	slli	a5,a5,0x2
ffffffffc0202164:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202166:	000c5717          	auipc	a4,0xc5
ffffffffc020216a:	a5273703          	ld	a4,-1454(a4) # ffffffffc02c6bb8 <npage>
ffffffffc020216e:	00e7ff63          	bgeu	a5,a4,ffffffffc020218c <get_page+0x50>
ffffffffc0202172:	60a2                	ld	ra,8(sp)
ffffffffc0202174:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0202176:	fff80537          	lui	a0,0xfff80
ffffffffc020217a:	97aa                	add	a5,a5,a0
ffffffffc020217c:	079a                	slli	a5,a5,0x6
ffffffffc020217e:	000c5517          	auipc	a0,0xc5
ffffffffc0202182:	a4253503          	ld	a0,-1470(a0) # ffffffffc02c6bc0 <pages>
ffffffffc0202186:	953e                	add	a0,a0,a5
ffffffffc0202188:	0141                	addi	sp,sp,16
ffffffffc020218a:	8082                	ret
ffffffffc020218c:	c99ff0ef          	jal	ra,ffffffffc0201e24 <pa2page.part.0>

ffffffffc0202190 <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202190:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202192:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202196:	f486                	sd	ra,104(sp)
ffffffffc0202198:	f0a2                	sd	s0,96(sp)
ffffffffc020219a:	eca6                	sd	s1,88(sp)
ffffffffc020219c:	e8ca                	sd	s2,80(sp)
ffffffffc020219e:	e4ce                	sd	s3,72(sp)
ffffffffc02021a0:	e0d2                	sd	s4,64(sp)
ffffffffc02021a2:	fc56                	sd	s5,56(sp)
ffffffffc02021a4:	f85a                	sd	s6,48(sp)
ffffffffc02021a6:	f45e                	sd	s7,40(sp)
ffffffffc02021a8:	f062                	sd	s8,32(sp)
ffffffffc02021aa:	ec66                	sd	s9,24(sp)
ffffffffc02021ac:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021ae:	17d2                	slli	a5,a5,0x34
ffffffffc02021b0:	e3ed                	bnez	a5,ffffffffc0202292 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc02021b2:	002007b7          	lui	a5,0x200
ffffffffc02021b6:	842e                	mv	s0,a1
ffffffffc02021b8:	0ef5ed63          	bltu	a1,a5,ffffffffc02022b2 <unmap_range+0x122>
ffffffffc02021bc:	8932                	mv	s2,a2
ffffffffc02021be:	0ec5fa63          	bgeu	a1,a2,ffffffffc02022b2 <unmap_range+0x122>
ffffffffc02021c2:	4785                	li	a5,1
ffffffffc02021c4:	07fe                	slli	a5,a5,0x1f
ffffffffc02021c6:	0ec7e663          	bltu	a5,a2,ffffffffc02022b2 <unmap_range+0x122>
ffffffffc02021ca:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02021cc:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02021ce:	000c5c97          	auipc	s9,0xc5
ffffffffc02021d2:	9eac8c93          	addi	s9,s9,-1558 # ffffffffc02c6bb8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02021d6:	000c5c17          	auipc	s8,0xc5
ffffffffc02021da:	9eac0c13          	addi	s8,s8,-1558 # ffffffffc02c6bc0 <pages>
ffffffffc02021de:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02021e2:	000c5d17          	auipc	s10,0xc5
ffffffffc02021e6:	9e6d0d13          	addi	s10,s10,-1562 # ffffffffc02c6bc8 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02021ea:	00200b37          	lui	s6,0x200
ffffffffc02021ee:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02021f2:	4601                	li	a2,0
ffffffffc02021f4:	85a2                	mv	a1,s0
ffffffffc02021f6:	854e                	mv	a0,s3
ffffffffc02021f8:	d1dff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc02021fc:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02021fe:	cd29                	beqz	a0,ffffffffc0202258 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc0202200:	611c                	ld	a5,0(a0)
ffffffffc0202202:	e395                	bnez	a5,ffffffffc0202226 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202204:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202206:	ff2466e3          	bltu	s0,s2,ffffffffc02021f2 <unmap_range+0x62>
}
ffffffffc020220a:	70a6                	ld	ra,104(sp)
ffffffffc020220c:	7406                	ld	s0,96(sp)
ffffffffc020220e:	64e6                	ld	s1,88(sp)
ffffffffc0202210:	6946                	ld	s2,80(sp)
ffffffffc0202212:	69a6                	ld	s3,72(sp)
ffffffffc0202214:	6a06                	ld	s4,64(sp)
ffffffffc0202216:	7ae2                	ld	s5,56(sp)
ffffffffc0202218:	7b42                	ld	s6,48(sp)
ffffffffc020221a:	7ba2                	ld	s7,40(sp)
ffffffffc020221c:	7c02                	ld	s8,32(sp)
ffffffffc020221e:	6ce2                	ld	s9,24(sp)
ffffffffc0202220:	6d42                	ld	s10,16(sp)
ffffffffc0202222:	6165                	addi	sp,sp,112
ffffffffc0202224:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202226:	0017f713          	andi	a4,a5,1
ffffffffc020222a:	df69                	beqz	a4,ffffffffc0202204 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc020222c:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202230:	078a                	slli	a5,a5,0x2
ffffffffc0202232:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202234:	08e7ff63          	bgeu	a5,a4,ffffffffc02022d2 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202238:	000c3503          	ld	a0,0(s8)
ffffffffc020223c:	97de                	add	a5,a5,s7
ffffffffc020223e:	079a                	slli	a5,a5,0x6
ffffffffc0202240:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202242:	411c                	lw	a5,0(a0)
ffffffffc0202244:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202248:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020224a:	cf11                	beqz	a4,ffffffffc0202266 <unmap_range+0xd6>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc020224c:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202250:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202254:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202256:	bf45                	j	ffffffffc0202206 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202258:	945a                	add	s0,s0,s6
ffffffffc020225a:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020225e:	d455                	beqz	s0,ffffffffc020220a <unmap_range+0x7a>
ffffffffc0202260:	f92469e3          	bltu	s0,s2,ffffffffc02021f2 <unmap_range+0x62>
ffffffffc0202264:	b75d                	j	ffffffffc020220a <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202266:	100027f3          	csrr	a5,sstatus
ffffffffc020226a:	8b89                	andi	a5,a5,2
ffffffffc020226c:	e799                	bnez	a5,ffffffffc020227a <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020226e:	000d3783          	ld	a5,0(s10)
ffffffffc0202272:	4585                	li	a1,1
ffffffffc0202274:	739c                	ld	a5,32(a5)
ffffffffc0202276:	9782                	jalr	a5
    if (flag)
ffffffffc0202278:	bfd1                	j	ffffffffc020224c <unmap_range+0xbc>
ffffffffc020227a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020227c:	f32fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202280:	000d3783          	ld	a5,0(s10)
ffffffffc0202284:	6522                	ld	a0,8(sp)
ffffffffc0202286:	4585                	li	a1,1
ffffffffc0202288:	739c                	ld	a5,32(a5)
ffffffffc020228a:	9782                	jalr	a5
        intr_enable();
ffffffffc020228c:	f1cfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202290:	bf75                	j	ffffffffc020224c <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202292:	00005697          	auipc	a3,0x5
ffffffffc0202296:	b6e68693          	addi	a3,a3,-1170 # ffffffffc0206e00 <default_pmm_manager+0x160>
ffffffffc020229a:	00004617          	auipc	a2,0x4
ffffffffc020229e:	65660613          	addi	a2,a2,1622 # ffffffffc02068f0 <commands+0x868>
ffffffffc02022a2:	12200593          	li	a1,290
ffffffffc02022a6:	00005517          	auipc	a0,0x5
ffffffffc02022aa:	b4a50513          	addi	a0,a0,-1206 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc02022ae:	9e4fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02022b2:	00005697          	auipc	a3,0x5
ffffffffc02022b6:	b7e68693          	addi	a3,a3,-1154 # ffffffffc0206e30 <default_pmm_manager+0x190>
ffffffffc02022ba:	00004617          	auipc	a2,0x4
ffffffffc02022be:	63660613          	addi	a2,a2,1590 # ffffffffc02068f0 <commands+0x868>
ffffffffc02022c2:	12300593          	li	a1,291
ffffffffc02022c6:	00005517          	auipc	a0,0x5
ffffffffc02022ca:	b2a50513          	addi	a0,a0,-1238 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc02022ce:	9c4fe0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc02022d2:	b53ff0ef          	jal	ra,ffffffffc0201e24 <pa2page.part.0>

ffffffffc02022d6 <exit_range>:
{
ffffffffc02022d6:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022d8:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02022dc:	fc86                	sd	ra,120(sp)
ffffffffc02022de:	f8a2                	sd	s0,112(sp)
ffffffffc02022e0:	f4a6                	sd	s1,104(sp)
ffffffffc02022e2:	f0ca                	sd	s2,96(sp)
ffffffffc02022e4:	ecce                	sd	s3,88(sp)
ffffffffc02022e6:	e8d2                	sd	s4,80(sp)
ffffffffc02022e8:	e4d6                	sd	s5,72(sp)
ffffffffc02022ea:	e0da                	sd	s6,64(sp)
ffffffffc02022ec:	fc5e                	sd	s7,56(sp)
ffffffffc02022ee:	f862                	sd	s8,48(sp)
ffffffffc02022f0:	f466                	sd	s9,40(sp)
ffffffffc02022f2:	f06a                	sd	s10,32(sp)
ffffffffc02022f4:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022f6:	17d2                	slli	a5,a5,0x34
ffffffffc02022f8:	20079a63          	bnez	a5,ffffffffc020250c <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02022fc:	002007b7          	lui	a5,0x200
ffffffffc0202300:	24f5e463          	bltu	a1,a5,ffffffffc0202548 <exit_range+0x272>
ffffffffc0202304:	8ab2                	mv	s5,a2
ffffffffc0202306:	24c5f163          	bgeu	a1,a2,ffffffffc0202548 <exit_range+0x272>
ffffffffc020230a:	4785                	li	a5,1
ffffffffc020230c:	07fe                	slli	a5,a5,0x1f
ffffffffc020230e:	22c7ed63          	bltu	a5,a2,ffffffffc0202548 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202312:	c00009b7          	lui	s3,0xc0000
ffffffffc0202316:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020231a:	ffe00937          	lui	s2,0xffe00
ffffffffc020231e:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc0202322:	5cfd                	li	s9,-1
ffffffffc0202324:	8c2a                	mv	s8,a0
ffffffffc0202326:	0125f933          	and	s2,a1,s2
ffffffffc020232a:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc020232c:	000c5d17          	auipc	s10,0xc5
ffffffffc0202330:	88cd0d13          	addi	s10,s10,-1908 # ffffffffc02c6bb8 <npage>
    return KADDR(page2pa(page));
ffffffffc0202334:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202338:	000c5717          	auipc	a4,0xc5
ffffffffc020233c:	88870713          	addi	a4,a4,-1912 # ffffffffc02c6bc0 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202340:	000c5d97          	auipc	s11,0xc5
ffffffffc0202344:	888d8d93          	addi	s11,s11,-1912 # ffffffffc02c6bc8 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202348:	c0000437          	lui	s0,0xc0000
ffffffffc020234c:	944e                	add	s0,s0,s3
ffffffffc020234e:	8079                	srli	s0,s0,0x1e
ffffffffc0202350:	1ff47413          	andi	s0,s0,511
ffffffffc0202354:	040e                	slli	s0,s0,0x3
ffffffffc0202356:	9462                	add	s0,s0,s8
ffffffffc0202358:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff38f0>
        if (pde1 & PTE_V)
ffffffffc020235c:	001a7793          	andi	a5,s4,1
ffffffffc0202360:	eb99                	bnez	a5,ffffffffc0202376 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202362:	12098463          	beqz	s3,ffffffffc020248a <exit_range+0x1b4>
ffffffffc0202366:	400007b7          	lui	a5,0x40000
ffffffffc020236a:	97ce                	add	a5,a5,s3
ffffffffc020236c:	894e                	mv	s2,s3
ffffffffc020236e:	1159fe63          	bgeu	s3,s5,ffffffffc020248a <exit_range+0x1b4>
ffffffffc0202372:	89be                	mv	s3,a5
ffffffffc0202374:	bfd1                	j	ffffffffc0202348 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc0202376:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020237a:	0a0a                	slli	s4,s4,0x2
ffffffffc020237c:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202380:	1cfa7263          	bgeu	s4,a5,ffffffffc0202544 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202384:	fff80637          	lui	a2,0xfff80
ffffffffc0202388:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc020238a:	000806b7          	lui	a3,0x80
ffffffffc020238e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202390:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202394:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202396:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202398:	18f5fa63          	bgeu	a1,a5,ffffffffc020252c <exit_range+0x256>
ffffffffc020239c:	000c5817          	auipc	a6,0xc5
ffffffffc02023a0:	83480813          	addi	a6,a6,-1996 # ffffffffc02c6bd0 <va_pa_offset>
ffffffffc02023a4:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02023a8:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02023aa:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02023ae:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02023b0:	00080337          	lui	t1,0x80
ffffffffc02023b4:	6885                	lui	a7,0x1
ffffffffc02023b6:	a819                	j	ffffffffc02023cc <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02023b8:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02023ba:	002007b7          	lui	a5,0x200
ffffffffc02023be:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023c0:	08090c63          	beqz	s2,ffffffffc0202458 <exit_range+0x182>
ffffffffc02023c4:	09397a63          	bgeu	s2,s3,ffffffffc0202458 <exit_range+0x182>
ffffffffc02023c8:	0f597063          	bgeu	s2,s5,ffffffffc02024a8 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023cc:	01595493          	srli	s1,s2,0x15
ffffffffc02023d0:	1ff4f493          	andi	s1,s1,511
ffffffffc02023d4:	048e                	slli	s1,s1,0x3
ffffffffc02023d6:	94da                	add	s1,s1,s6
ffffffffc02023d8:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02023da:	0017f693          	andi	a3,a5,1
ffffffffc02023de:	dee9                	beqz	a3,ffffffffc02023b8 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc02023e0:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023e4:	078a                	slli	a5,a5,0x2
ffffffffc02023e6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02023e8:	14b7fe63          	bgeu	a5,a1,ffffffffc0202544 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02023ec:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02023ee:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02023f2:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02023f6:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02023fa:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02023fc:	12bef863          	bgeu	t4,a1,ffffffffc020252c <exit_range+0x256>
ffffffffc0202400:	00083783          	ld	a5,0(a6)
ffffffffc0202404:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202406:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc020240a:	629c                	ld	a5,0(a3)
ffffffffc020240c:	8b85                	andi	a5,a5,1
ffffffffc020240e:	f7d5                	bnez	a5,ffffffffc02023ba <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202410:	06a1                	addi	a3,a3,8
ffffffffc0202412:	fed59ce3          	bne	a1,a3,ffffffffc020240a <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202416:	631c                	ld	a5,0(a4)
ffffffffc0202418:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020241a:	100027f3          	csrr	a5,sstatus
ffffffffc020241e:	8b89                	andi	a5,a5,2
ffffffffc0202420:	e7d9                	bnez	a5,ffffffffc02024ae <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc0202422:	000db783          	ld	a5,0(s11)
ffffffffc0202426:	4585                	li	a1,1
ffffffffc0202428:	e032                	sd	a2,0(sp)
ffffffffc020242a:	739c                	ld	a5,32(a5)
ffffffffc020242c:	9782                	jalr	a5
    if (flag)
ffffffffc020242e:	6602                	ld	a2,0(sp)
ffffffffc0202430:	000c4817          	auipc	a6,0xc4
ffffffffc0202434:	7a080813          	addi	a6,a6,1952 # ffffffffc02c6bd0 <va_pa_offset>
ffffffffc0202438:	fff80e37          	lui	t3,0xfff80
ffffffffc020243c:	00080337          	lui	t1,0x80
ffffffffc0202440:	6885                	lui	a7,0x1
ffffffffc0202442:	000c4717          	auipc	a4,0xc4
ffffffffc0202446:	77e70713          	addi	a4,a4,1918 # ffffffffc02c6bc0 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020244a:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020244e:	002007b7          	lui	a5,0x200
ffffffffc0202452:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202454:	f60918e3          	bnez	s2,ffffffffc02023c4 <exit_range+0xee>
            if (free_pd0)
ffffffffc0202458:	f00b85e3          	beqz	s7,ffffffffc0202362 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc020245c:	000d3783          	ld	a5,0(s10)
ffffffffc0202460:	0efa7263          	bgeu	s4,a5,ffffffffc0202544 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202464:	6308                	ld	a0,0(a4)
ffffffffc0202466:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202468:	100027f3          	csrr	a5,sstatus
ffffffffc020246c:	8b89                	andi	a5,a5,2
ffffffffc020246e:	efad                	bnez	a5,ffffffffc02024e8 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0202470:	000db783          	ld	a5,0(s11)
ffffffffc0202474:	4585                	li	a1,1
ffffffffc0202476:	739c                	ld	a5,32(a5)
ffffffffc0202478:	9782                	jalr	a5
ffffffffc020247a:	000c4717          	auipc	a4,0xc4
ffffffffc020247e:	74670713          	addi	a4,a4,1862 # ffffffffc02c6bc0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202482:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc0202486:	ee0990e3          	bnez	s3,ffffffffc0202366 <exit_range+0x90>
}
ffffffffc020248a:	70e6                	ld	ra,120(sp)
ffffffffc020248c:	7446                	ld	s0,112(sp)
ffffffffc020248e:	74a6                	ld	s1,104(sp)
ffffffffc0202490:	7906                	ld	s2,96(sp)
ffffffffc0202492:	69e6                	ld	s3,88(sp)
ffffffffc0202494:	6a46                	ld	s4,80(sp)
ffffffffc0202496:	6aa6                	ld	s5,72(sp)
ffffffffc0202498:	6b06                	ld	s6,64(sp)
ffffffffc020249a:	7be2                	ld	s7,56(sp)
ffffffffc020249c:	7c42                	ld	s8,48(sp)
ffffffffc020249e:	7ca2                	ld	s9,40(sp)
ffffffffc02024a0:	7d02                	ld	s10,32(sp)
ffffffffc02024a2:	6de2                	ld	s11,24(sp)
ffffffffc02024a4:	6109                	addi	sp,sp,128
ffffffffc02024a6:	8082                	ret
            if (free_pd0)
ffffffffc02024a8:	ea0b8fe3          	beqz	s7,ffffffffc0202366 <exit_range+0x90>
ffffffffc02024ac:	bf45                	j	ffffffffc020245c <exit_range+0x186>
ffffffffc02024ae:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02024b0:	e42a                	sd	a0,8(sp)
ffffffffc02024b2:	cfcfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02024b6:	000db783          	ld	a5,0(s11)
ffffffffc02024ba:	6522                	ld	a0,8(sp)
ffffffffc02024bc:	4585                	li	a1,1
ffffffffc02024be:	739c                	ld	a5,32(a5)
ffffffffc02024c0:	9782                	jalr	a5
        intr_enable();
ffffffffc02024c2:	ce6fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02024c6:	6602                	ld	a2,0(sp)
ffffffffc02024c8:	000c4717          	auipc	a4,0xc4
ffffffffc02024cc:	6f870713          	addi	a4,a4,1784 # ffffffffc02c6bc0 <pages>
ffffffffc02024d0:	6885                	lui	a7,0x1
ffffffffc02024d2:	00080337          	lui	t1,0x80
ffffffffc02024d6:	fff80e37          	lui	t3,0xfff80
ffffffffc02024da:	000c4817          	auipc	a6,0xc4
ffffffffc02024de:	6f680813          	addi	a6,a6,1782 # ffffffffc02c6bd0 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02024e2:	0004b023          	sd	zero,0(s1)
ffffffffc02024e6:	b7a5                	j	ffffffffc020244e <exit_range+0x178>
ffffffffc02024e8:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02024ea:	cc4fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02024ee:	000db783          	ld	a5,0(s11)
ffffffffc02024f2:	6502                	ld	a0,0(sp)
ffffffffc02024f4:	4585                	li	a1,1
ffffffffc02024f6:	739c                	ld	a5,32(a5)
ffffffffc02024f8:	9782                	jalr	a5
        intr_enable();
ffffffffc02024fa:	caefe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02024fe:	000c4717          	auipc	a4,0xc4
ffffffffc0202502:	6c270713          	addi	a4,a4,1730 # ffffffffc02c6bc0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202506:	00043023          	sd	zero,0(s0)
ffffffffc020250a:	bfb5                	j	ffffffffc0202486 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020250c:	00005697          	auipc	a3,0x5
ffffffffc0202510:	8f468693          	addi	a3,a3,-1804 # ffffffffc0206e00 <default_pmm_manager+0x160>
ffffffffc0202514:	00004617          	auipc	a2,0x4
ffffffffc0202518:	3dc60613          	addi	a2,a2,988 # ffffffffc02068f0 <commands+0x868>
ffffffffc020251c:	13700593          	li	a1,311
ffffffffc0202520:	00005517          	auipc	a0,0x5
ffffffffc0202524:	8d050513          	addi	a0,a0,-1840 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202528:	f6bfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc020252c:	00004617          	auipc	a2,0x4
ffffffffc0202530:	7ac60613          	addi	a2,a2,1964 # ffffffffc0206cd8 <default_pmm_manager+0x38>
ffffffffc0202534:	07100593          	li	a1,113
ffffffffc0202538:	00004517          	auipc	a0,0x4
ffffffffc020253c:	7c850513          	addi	a0,a0,1992 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc0202540:	f53fd0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202544:	8e1ff0ef          	jal	ra,ffffffffc0201e24 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202548:	00005697          	auipc	a3,0x5
ffffffffc020254c:	8e868693          	addi	a3,a3,-1816 # ffffffffc0206e30 <default_pmm_manager+0x190>
ffffffffc0202550:	00004617          	auipc	a2,0x4
ffffffffc0202554:	3a060613          	addi	a2,a2,928 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202558:	13800593          	li	a1,312
ffffffffc020255c:	00005517          	auipc	a0,0x5
ffffffffc0202560:	89450513          	addi	a0,a0,-1900 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202564:	f2ffd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0202568 <page_remove>:
{
ffffffffc0202568:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020256a:	4601                	li	a2,0
{
ffffffffc020256c:	ec26                	sd	s1,24(sp)
ffffffffc020256e:	f406                	sd	ra,40(sp)
ffffffffc0202570:	f022                	sd	s0,32(sp)
ffffffffc0202572:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202574:	9a1ff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
    if (ptep != NULL)
ffffffffc0202578:	c511                	beqz	a0,ffffffffc0202584 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc020257a:	611c                	ld	a5,0(a0)
ffffffffc020257c:	842a                	mv	s0,a0
ffffffffc020257e:	0017f713          	andi	a4,a5,1
ffffffffc0202582:	e711                	bnez	a4,ffffffffc020258e <page_remove+0x26>
}
ffffffffc0202584:	70a2                	ld	ra,40(sp)
ffffffffc0202586:	7402                	ld	s0,32(sp)
ffffffffc0202588:	64e2                	ld	s1,24(sp)
ffffffffc020258a:	6145                	addi	sp,sp,48
ffffffffc020258c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020258e:	078a                	slli	a5,a5,0x2
ffffffffc0202590:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202592:	000c4717          	auipc	a4,0xc4
ffffffffc0202596:	62673703          	ld	a4,1574(a4) # ffffffffc02c6bb8 <npage>
ffffffffc020259a:	06e7f363          	bgeu	a5,a4,ffffffffc0202600 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020259e:	fff80537          	lui	a0,0xfff80
ffffffffc02025a2:	97aa                	add	a5,a5,a0
ffffffffc02025a4:	079a                	slli	a5,a5,0x6
ffffffffc02025a6:	000c4517          	auipc	a0,0xc4
ffffffffc02025aa:	61a53503          	ld	a0,1562(a0) # ffffffffc02c6bc0 <pages>
ffffffffc02025ae:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02025b0:	411c                	lw	a5,0(a0)
ffffffffc02025b2:	fff7871b          	addiw	a4,a5,-1
ffffffffc02025b6:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02025b8:	cb11                	beqz	a4,ffffffffc02025cc <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc02025ba:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025be:	12048073          	sfence.vma	s1
}
ffffffffc02025c2:	70a2                	ld	ra,40(sp)
ffffffffc02025c4:	7402                	ld	s0,32(sp)
ffffffffc02025c6:	64e2                	ld	s1,24(sp)
ffffffffc02025c8:	6145                	addi	sp,sp,48
ffffffffc02025ca:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02025cc:	100027f3          	csrr	a5,sstatus
ffffffffc02025d0:	8b89                	andi	a5,a5,2
ffffffffc02025d2:	eb89                	bnez	a5,ffffffffc02025e4 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02025d4:	000c4797          	auipc	a5,0xc4
ffffffffc02025d8:	5f47b783          	ld	a5,1524(a5) # ffffffffc02c6bc8 <pmm_manager>
ffffffffc02025dc:	739c                	ld	a5,32(a5)
ffffffffc02025de:	4585                	li	a1,1
ffffffffc02025e0:	9782                	jalr	a5
    if (flag)
ffffffffc02025e2:	bfe1                	j	ffffffffc02025ba <page_remove+0x52>
        intr_disable();
ffffffffc02025e4:	e42a                	sd	a0,8(sp)
ffffffffc02025e6:	bc8fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02025ea:	000c4797          	auipc	a5,0xc4
ffffffffc02025ee:	5de7b783          	ld	a5,1502(a5) # ffffffffc02c6bc8 <pmm_manager>
ffffffffc02025f2:	739c                	ld	a5,32(a5)
ffffffffc02025f4:	6522                	ld	a0,8(sp)
ffffffffc02025f6:	4585                	li	a1,1
ffffffffc02025f8:	9782                	jalr	a5
        intr_enable();
ffffffffc02025fa:	baefe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02025fe:	bf75                	j	ffffffffc02025ba <page_remove+0x52>
ffffffffc0202600:	825ff0ef          	jal	ra,ffffffffc0201e24 <pa2page.part.0>

ffffffffc0202604 <page_insert>:
{
ffffffffc0202604:	7139                	addi	sp,sp,-64
ffffffffc0202606:	e852                	sd	s4,16(sp)
ffffffffc0202608:	8a32                	mv	s4,a2
ffffffffc020260a:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020260c:	4605                	li	a2,1
{
ffffffffc020260e:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202610:	85d2                	mv	a1,s4
{
ffffffffc0202612:	f426                	sd	s1,40(sp)
ffffffffc0202614:	fc06                	sd	ra,56(sp)
ffffffffc0202616:	f04a                	sd	s2,32(sp)
ffffffffc0202618:	ec4e                	sd	s3,24(sp)
ffffffffc020261a:	e456                	sd	s5,8(sp)
ffffffffc020261c:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020261e:	8f7ff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
    if (ptep == NULL)
ffffffffc0202622:	c961                	beqz	a0,ffffffffc02026f2 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202624:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202626:	611c                	ld	a5,0(a0)
ffffffffc0202628:	89aa                	mv	s3,a0
ffffffffc020262a:	0016871b          	addiw	a4,a3,1
ffffffffc020262e:	c018                	sw	a4,0(s0)
ffffffffc0202630:	0017f713          	andi	a4,a5,1
ffffffffc0202634:	ef05                	bnez	a4,ffffffffc020266c <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202636:	000c4717          	auipc	a4,0xc4
ffffffffc020263a:	58a73703          	ld	a4,1418(a4) # ffffffffc02c6bc0 <pages>
ffffffffc020263e:	8c19                	sub	s0,s0,a4
ffffffffc0202640:	000807b7          	lui	a5,0x80
ffffffffc0202644:	8419                	srai	s0,s0,0x6
ffffffffc0202646:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202648:	042a                	slli	s0,s0,0xa
ffffffffc020264a:	8cc1                	or	s1,s1,s0
ffffffffc020264c:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202650:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff38f0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202654:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202658:	4501                	li	a0,0
}
ffffffffc020265a:	70e2                	ld	ra,56(sp)
ffffffffc020265c:	7442                	ld	s0,48(sp)
ffffffffc020265e:	74a2                	ld	s1,40(sp)
ffffffffc0202660:	7902                	ld	s2,32(sp)
ffffffffc0202662:	69e2                	ld	s3,24(sp)
ffffffffc0202664:	6a42                	ld	s4,16(sp)
ffffffffc0202666:	6aa2                	ld	s5,8(sp)
ffffffffc0202668:	6121                	addi	sp,sp,64
ffffffffc020266a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020266c:	078a                	slli	a5,a5,0x2
ffffffffc020266e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202670:	000c4717          	auipc	a4,0xc4
ffffffffc0202674:	54873703          	ld	a4,1352(a4) # ffffffffc02c6bb8 <npage>
ffffffffc0202678:	06e7ff63          	bgeu	a5,a4,ffffffffc02026f6 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc020267c:	000c4a97          	auipc	s5,0xc4
ffffffffc0202680:	544a8a93          	addi	s5,s5,1348 # ffffffffc02c6bc0 <pages>
ffffffffc0202684:	000ab703          	ld	a4,0(s5)
ffffffffc0202688:	fff80937          	lui	s2,0xfff80
ffffffffc020268c:	993e                	add	s2,s2,a5
ffffffffc020268e:	091a                	slli	s2,s2,0x6
ffffffffc0202690:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0202692:	01240c63          	beq	s0,s2,ffffffffc02026aa <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202696:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcb93f0>
ffffffffc020269a:	fff7869b          	addiw	a3,a5,-1
ffffffffc020269e:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc02026a2:	c691                	beqz	a3,ffffffffc02026ae <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026a4:	120a0073          	sfence.vma	s4
}
ffffffffc02026a8:	bf59                	j	ffffffffc020263e <page_insert+0x3a>
ffffffffc02026aa:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02026ac:	bf49                	j	ffffffffc020263e <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02026ae:	100027f3          	csrr	a5,sstatus
ffffffffc02026b2:	8b89                	andi	a5,a5,2
ffffffffc02026b4:	ef91                	bnez	a5,ffffffffc02026d0 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02026b6:	000c4797          	auipc	a5,0xc4
ffffffffc02026ba:	5127b783          	ld	a5,1298(a5) # ffffffffc02c6bc8 <pmm_manager>
ffffffffc02026be:	739c                	ld	a5,32(a5)
ffffffffc02026c0:	4585                	li	a1,1
ffffffffc02026c2:	854a                	mv	a0,s2
ffffffffc02026c4:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02026c6:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026ca:	120a0073          	sfence.vma	s4
ffffffffc02026ce:	bf85                	j	ffffffffc020263e <page_insert+0x3a>
        intr_disable();
ffffffffc02026d0:	adefe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02026d4:	000c4797          	auipc	a5,0xc4
ffffffffc02026d8:	4f47b783          	ld	a5,1268(a5) # ffffffffc02c6bc8 <pmm_manager>
ffffffffc02026dc:	739c                	ld	a5,32(a5)
ffffffffc02026de:	4585                	li	a1,1
ffffffffc02026e0:	854a                	mv	a0,s2
ffffffffc02026e2:	9782                	jalr	a5
        intr_enable();
ffffffffc02026e4:	ac4fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02026e8:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026ec:	120a0073          	sfence.vma	s4
ffffffffc02026f0:	b7b9                	j	ffffffffc020263e <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02026f2:	5571                	li	a0,-4
ffffffffc02026f4:	b79d                	j	ffffffffc020265a <page_insert+0x56>
ffffffffc02026f6:	f2eff0ef          	jal	ra,ffffffffc0201e24 <pa2page.part.0>

ffffffffc02026fa <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02026fa:	00004797          	auipc	a5,0x4
ffffffffc02026fe:	5a678793          	addi	a5,a5,1446 # ffffffffc0206ca0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202702:	638c                	ld	a1,0(a5)
{
ffffffffc0202704:	7159                	addi	sp,sp,-112
ffffffffc0202706:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202708:	00004517          	auipc	a0,0x4
ffffffffc020270c:	74050513          	addi	a0,a0,1856 # ffffffffc0206e48 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc0202710:	000c4b17          	auipc	s6,0xc4
ffffffffc0202714:	4b8b0b13          	addi	s6,s6,1208 # ffffffffc02c6bc8 <pmm_manager>
{
ffffffffc0202718:	f486                	sd	ra,104(sp)
ffffffffc020271a:	e8ca                	sd	s2,80(sp)
ffffffffc020271c:	e4ce                	sd	s3,72(sp)
ffffffffc020271e:	f0a2                	sd	s0,96(sp)
ffffffffc0202720:	eca6                	sd	s1,88(sp)
ffffffffc0202722:	e0d2                	sd	s4,64(sp)
ffffffffc0202724:	fc56                	sd	s5,56(sp)
ffffffffc0202726:	f45e                	sd	s7,40(sp)
ffffffffc0202728:	f062                	sd	s8,32(sp)
ffffffffc020272a:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020272c:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202730:	a69fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    pmm_manager->init();
ffffffffc0202734:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202738:	000c4997          	auipc	s3,0xc4
ffffffffc020273c:	49898993          	addi	s3,s3,1176 # ffffffffc02c6bd0 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202740:	679c                	ld	a5,8(a5)
ffffffffc0202742:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202744:	57f5                	li	a5,-3
ffffffffc0202746:	07fa                	slli	a5,a5,0x1e
ffffffffc0202748:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc020274c:	a48fe0ef          	jal	ra,ffffffffc0200994 <get_memory_base>
ffffffffc0202750:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202752:	a4cfe0ef          	jal	ra,ffffffffc020099e <get_memory_size>
    if (mem_size == 0)
ffffffffc0202756:	200505e3          	beqz	a0,ffffffffc0203160 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020275a:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc020275c:	00004517          	auipc	a0,0x4
ffffffffc0202760:	72450513          	addi	a0,a0,1828 # ffffffffc0206e80 <default_pmm_manager+0x1e0>
ffffffffc0202764:	a35fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202768:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020276c:	fff40693          	addi	a3,s0,-1
ffffffffc0202770:	864a                	mv	a2,s2
ffffffffc0202772:	85a6                	mv	a1,s1
ffffffffc0202774:	00004517          	auipc	a0,0x4
ffffffffc0202778:	72450513          	addi	a0,a0,1828 # ffffffffc0206e98 <default_pmm_manager+0x1f8>
ffffffffc020277c:	a1dfd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202780:	c8000737          	lui	a4,0xc8000
ffffffffc0202784:	87a2                	mv	a5,s0
ffffffffc0202786:	54876163          	bltu	a4,s0,ffffffffc0202cc8 <pmm_init+0x5ce>
ffffffffc020278a:	757d                	lui	a0,0xfffff
ffffffffc020278c:	000c5617          	auipc	a2,0xc5
ffffffffc0202790:	48360613          	addi	a2,a2,1155 # ffffffffc02c7c0f <end+0xfff>
ffffffffc0202794:	8e69                	and	a2,a2,a0
ffffffffc0202796:	000c4497          	auipc	s1,0xc4
ffffffffc020279a:	42248493          	addi	s1,s1,1058 # ffffffffc02c6bb8 <npage>
ffffffffc020279e:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027a2:	000c4b97          	auipc	s7,0xc4
ffffffffc02027a6:	41eb8b93          	addi	s7,s7,1054 # ffffffffc02c6bc0 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02027aa:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027ac:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027b0:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027b4:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027b6:	02f50863          	beq	a0,a5,ffffffffc02027e6 <pmm_init+0xec>
ffffffffc02027ba:	4781                	li	a5,0
ffffffffc02027bc:	4585                	li	a1,1
ffffffffc02027be:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02027c2:	00679513          	slli	a0,a5,0x6
ffffffffc02027c6:	9532                	add	a0,a0,a2
ffffffffc02027c8:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd383f8>
ffffffffc02027cc:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027d0:	6088                	ld	a0,0(s1)
ffffffffc02027d2:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02027d4:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027d8:	00d50733          	add	a4,a0,a3
ffffffffc02027dc:	fee7e3e3          	bltu	a5,a4,ffffffffc02027c2 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02027e0:	071a                	slli	a4,a4,0x6
ffffffffc02027e2:	00e606b3          	add	a3,a2,a4
ffffffffc02027e6:	c02007b7          	lui	a5,0xc0200
ffffffffc02027ea:	2ef6ece3          	bltu	a3,a5,ffffffffc02032e2 <pmm_init+0xbe8>
ffffffffc02027ee:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02027f2:	77fd                	lui	a5,0xfffff
ffffffffc02027f4:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02027f6:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02027f8:	5086eb63          	bltu	a3,s0,ffffffffc0202d0e <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02027fc:	00004517          	auipc	a0,0x4
ffffffffc0202800:	6c450513          	addi	a0,a0,1732 # ffffffffc0206ec0 <default_pmm_manager+0x220>
ffffffffc0202804:	995fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202808:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020280c:	000c4917          	auipc	s2,0xc4
ffffffffc0202810:	3a490913          	addi	s2,s2,932 # ffffffffc02c6bb0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202814:	7b9c                	ld	a5,48(a5)
ffffffffc0202816:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202818:	00004517          	auipc	a0,0x4
ffffffffc020281c:	6c050513          	addi	a0,a0,1728 # ffffffffc0206ed8 <default_pmm_manager+0x238>
ffffffffc0202820:	979fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202824:	00008697          	auipc	a3,0x8
ffffffffc0202828:	7dc68693          	addi	a3,a3,2012 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc020282c:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202830:	c02007b7          	lui	a5,0xc0200
ffffffffc0202834:	28f6ebe3          	bltu	a3,a5,ffffffffc02032ca <pmm_init+0xbd0>
ffffffffc0202838:	0009b783          	ld	a5,0(s3)
ffffffffc020283c:	8e9d                	sub	a3,a3,a5
ffffffffc020283e:	000c4797          	auipc	a5,0xc4
ffffffffc0202842:	36d7b523          	sd	a3,874(a5) # ffffffffc02c6ba8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202846:	100027f3          	csrr	a5,sstatus
ffffffffc020284a:	8b89                	andi	a5,a5,2
ffffffffc020284c:	4a079763          	bnez	a5,ffffffffc0202cfa <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202850:	000b3783          	ld	a5,0(s6)
ffffffffc0202854:	779c                	ld	a5,40(a5)
ffffffffc0202856:	9782                	jalr	a5
ffffffffc0202858:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020285a:	6098                	ld	a4,0(s1)
ffffffffc020285c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202860:	83b1                	srli	a5,a5,0xc
ffffffffc0202862:	66e7e363          	bltu	a5,a4,ffffffffc0202ec8 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202866:	00093503          	ld	a0,0(s2)
ffffffffc020286a:	62050f63          	beqz	a0,ffffffffc0202ea8 <pmm_init+0x7ae>
ffffffffc020286e:	03451793          	slli	a5,a0,0x34
ffffffffc0202872:	62079b63          	bnez	a5,ffffffffc0202ea8 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202876:	4601                	li	a2,0
ffffffffc0202878:	4581                	li	a1,0
ffffffffc020287a:	8c3ff0ef          	jal	ra,ffffffffc020213c <get_page>
ffffffffc020287e:	60051563          	bnez	a0,ffffffffc0202e88 <pmm_init+0x78e>
ffffffffc0202882:	100027f3          	csrr	a5,sstatus
ffffffffc0202886:	8b89                	andi	a5,a5,2
ffffffffc0202888:	44079e63          	bnez	a5,ffffffffc0202ce4 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc020288c:	000b3783          	ld	a5,0(s6)
ffffffffc0202890:	4505                	li	a0,1
ffffffffc0202892:	6f9c                	ld	a5,24(a5)
ffffffffc0202894:	9782                	jalr	a5
ffffffffc0202896:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202898:	00093503          	ld	a0,0(s2)
ffffffffc020289c:	4681                	li	a3,0
ffffffffc020289e:	4601                	li	a2,0
ffffffffc02028a0:	85d2                	mv	a1,s4
ffffffffc02028a2:	d63ff0ef          	jal	ra,ffffffffc0202604 <page_insert>
ffffffffc02028a6:	26051ae3          	bnez	a0,ffffffffc020331a <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02028aa:	00093503          	ld	a0,0(s2)
ffffffffc02028ae:	4601                	li	a2,0
ffffffffc02028b0:	4581                	li	a1,0
ffffffffc02028b2:	e62ff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc02028b6:	240502e3          	beqz	a0,ffffffffc02032fa <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc02028ba:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02028bc:	0017f713          	andi	a4,a5,1
ffffffffc02028c0:	5a070263          	beqz	a4,ffffffffc0202e64 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02028c4:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028c6:	078a                	slli	a5,a5,0x2
ffffffffc02028c8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02028ca:	58e7fb63          	bgeu	a5,a4,ffffffffc0202e60 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02028ce:	000bb683          	ld	a3,0(s7)
ffffffffc02028d2:	fff80637          	lui	a2,0xfff80
ffffffffc02028d6:	97b2                	add	a5,a5,a2
ffffffffc02028d8:	079a                	slli	a5,a5,0x6
ffffffffc02028da:	97b6                	add	a5,a5,a3
ffffffffc02028dc:	14fa17e3          	bne	s4,a5,ffffffffc020322a <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc02028e0:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f40>
ffffffffc02028e4:	4785                	li	a5,1
ffffffffc02028e6:	12f692e3          	bne	a3,a5,ffffffffc020320a <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02028ea:	00093503          	ld	a0,0(s2)
ffffffffc02028ee:	77fd                	lui	a5,0xfffff
ffffffffc02028f0:	6114                	ld	a3,0(a0)
ffffffffc02028f2:	068a                	slli	a3,a3,0x2
ffffffffc02028f4:	8efd                	and	a3,a3,a5
ffffffffc02028f6:	00c6d613          	srli	a2,a3,0xc
ffffffffc02028fa:	0ee67ce3          	bgeu	a2,a4,ffffffffc02031f2 <pmm_init+0xaf8>
ffffffffc02028fe:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202902:	96e2                	add	a3,a3,s8
ffffffffc0202904:	0006ba83          	ld	s5,0(a3)
ffffffffc0202908:	0a8a                	slli	s5,s5,0x2
ffffffffc020290a:	00fafab3          	and	s5,s5,a5
ffffffffc020290e:	00cad793          	srli	a5,s5,0xc
ffffffffc0202912:	0ce7f3e3          	bgeu	a5,a4,ffffffffc02031d8 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202916:	4601                	li	a2,0
ffffffffc0202918:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020291a:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020291c:	df8ff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202920:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202922:	55551363          	bne	a0,s5,ffffffffc0202e68 <pmm_init+0x76e>
ffffffffc0202926:	100027f3          	csrr	a5,sstatus
ffffffffc020292a:	8b89                	andi	a5,a5,2
ffffffffc020292c:	3a079163          	bnez	a5,ffffffffc0202cce <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202930:	000b3783          	ld	a5,0(s6)
ffffffffc0202934:	4505                	li	a0,1
ffffffffc0202936:	6f9c                	ld	a5,24(a5)
ffffffffc0202938:	9782                	jalr	a5
ffffffffc020293a:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020293c:	00093503          	ld	a0,0(s2)
ffffffffc0202940:	46d1                	li	a3,20
ffffffffc0202942:	6605                	lui	a2,0x1
ffffffffc0202944:	85e2                	mv	a1,s8
ffffffffc0202946:	cbfff0ef          	jal	ra,ffffffffc0202604 <page_insert>
ffffffffc020294a:	060517e3          	bnez	a0,ffffffffc02031b8 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020294e:	00093503          	ld	a0,0(s2)
ffffffffc0202952:	4601                	li	a2,0
ffffffffc0202954:	6585                	lui	a1,0x1
ffffffffc0202956:	dbeff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc020295a:	02050fe3          	beqz	a0,ffffffffc0203198 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc020295e:	611c                	ld	a5,0(a0)
ffffffffc0202960:	0107f713          	andi	a4,a5,16
ffffffffc0202964:	7c070e63          	beqz	a4,ffffffffc0203140 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202968:	8b91                	andi	a5,a5,4
ffffffffc020296a:	7a078b63          	beqz	a5,ffffffffc0203120 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020296e:	00093503          	ld	a0,0(s2)
ffffffffc0202972:	611c                	ld	a5,0(a0)
ffffffffc0202974:	8bc1                	andi	a5,a5,16
ffffffffc0202976:	78078563          	beqz	a5,ffffffffc0203100 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc020297a:	000c2703          	lw	a4,0(s8)
ffffffffc020297e:	4785                	li	a5,1
ffffffffc0202980:	76f71063          	bne	a4,a5,ffffffffc02030e0 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202984:	4681                	li	a3,0
ffffffffc0202986:	6605                	lui	a2,0x1
ffffffffc0202988:	85d2                	mv	a1,s4
ffffffffc020298a:	c7bff0ef          	jal	ra,ffffffffc0202604 <page_insert>
ffffffffc020298e:	72051963          	bnez	a0,ffffffffc02030c0 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202992:	000a2703          	lw	a4,0(s4)
ffffffffc0202996:	4789                	li	a5,2
ffffffffc0202998:	70f71463          	bne	a4,a5,ffffffffc02030a0 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc020299c:	000c2783          	lw	a5,0(s8)
ffffffffc02029a0:	6e079063          	bnez	a5,ffffffffc0203080 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029a4:	00093503          	ld	a0,0(s2)
ffffffffc02029a8:	4601                	li	a2,0
ffffffffc02029aa:	6585                	lui	a1,0x1
ffffffffc02029ac:	d68ff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc02029b0:	6a050863          	beqz	a0,ffffffffc0203060 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc02029b4:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc02029b6:	00177793          	andi	a5,a4,1
ffffffffc02029ba:	4a078563          	beqz	a5,ffffffffc0202e64 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02029be:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02029c0:	00271793          	slli	a5,a4,0x2
ffffffffc02029c4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029c6:	48d7fd63          	bgeu	a5,a3,ffffffffc0202e60 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029ca:	000bb683          	ld	a3,0(s7)
ffffffffc02029ce:	fff80ab7          	lui	s5,0xfff80
ffffffffc02029d2:	97d6                	add	a5,a5,s5
ffffffffc02029d4:	079a                	slli	a5,a5,0x6
ffffffffc02029d6:	97b6                	add	a5,a5,a3
ffffffffc02029d8:	66fa1463          	bne	s4,a5,ffffffffc0203040 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc02029dc:	8b41                	andi	a4,a4,16
ffffffffc02029de:	64071163          	bnez	a4,ffffffffc0203020 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc02029e2:	00093503          	ld	a0,0(s2)
ffffffffc02029e6:	4581                	li	a1,0
ffffffffc02029e8:	b81ff0ef          	jal	ra,ffffffffc0202568 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc02029ec:	000a2c83          	lw	s9,0(s4)
ffffffffc02029f0:	4785                	li	a5,1
ffffffffc02029f2:	60fc9763          	bne	s9,a5,ffffffffc0203000 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc02029f6:	000c2783          	lw	a5,0(s8)
ffffffffc02029fa:	5e079363          	bnez	a5,ffffffffc0202fe0 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc02029fe:	00093503          	ld	a0,0(s2)
ffffffffc0202a02:	6585                	lui	a1,0x1
ffffffffc0202a04:	b65ff0ef          	jal	ra,ffffffffc0202568 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a08:	000a2783          	lw	a5,0(s4)
ffffffffc0202a0c:	52079a63          	bnez	a5,ffffffffc0202f40 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202a10:	000c2783          	lw	a5,0(s8)
ffffffffc0202a14:	50079663          	bnez	a5,ffffffffc0202f20 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a18:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202a1c:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a1e:	000a3683          	ld	a3,0(s4)
ffffffffc0202a22:	068a                	slli	a3,a3,0x2
ffffffffc0202a24:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a26:	42b6fd63          	bgeu	a3,a1,ffffffffc0202e60 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a2a:	000bb503          	ld	a0,0(s7)
ffffffffc0202a2e:	96d6                	add	a3,a3,s5
ffffffffc0202a30:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202a32:	00d507b3          	add	a5,a0,a3
ffffffffc0202a36:	439c                	lw	a5,0(a5)
ffffffffc0202a38:	4d979463          	bne	a5,s9,ffffffffc0202f00 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202a3c:	8699                	srai	a3,a3,0x6
ffffffffc0202a3e:	00080637          	lui	a2,0x80
ffffffffc0202a42:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202a44:	00c69713          	slli	a4,a3,0xc
ffffffffc0202a48:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a4a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202a4c:	48b77e63          	bgeu	a4,a1,ffffffffc0202ee8 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202a50:	0009b703          	ld	a4,0(s3)
ffffffffc0202a54:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a56:	629c                	ld	a5,0(a3)
ffffffffc0202a58:	078a                	slli	a5,a5,0x2
ffffffffc0202a5a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a5c:	40b7f263          	bgeu	a5,a1,ffffffffc0202e60 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a60:	8f91                	sub	a5,a5,a2
ffffffffc0202a62:	079a                	slli	a5,a5,0x6
ffffffffc0202a64:	953e                	add	a0,a0,a5
ffffffffc0202a66:	100027f3          	csrr	a5,sstatus
ffffffffc0202a6a:	8b89                	andi	a5,a5,2
ffffffffc0202a6c:	30079963          	bnez	a5,ffffffffc0202d7e <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202a70:	000b3783          	ld	a5,0(s6)
ffffffffc0202a74:	4585                	li	a1,1
ffffffffc0202a76:	739c                	ld	a5,32(a5)
ffffffffc0202a78:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a7a:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202a7e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a80:	078a                	slli	a5,a5,0x2
ffffffffc0202a82:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a84:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202e60 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a88:	000bb503          	ld	a0,0(s7)
ffffffffc0202a8c:	fff80737          	lui	a4,0xfff80
ffffffffc0202a90:	97ba                	add	a5,a5,a4
ffffffffc0202a92:	079a                	slli	a5,a5,0x6
ffffffffc0202a94:	953e                	add	a0,a0,a5
ffffffffc0202a96:	100027f3          	csrr	a5,sstatus
ffffffffc0202a9a:	8b89                	andi	a5,a5,2
ffffffffc0202a9c:	2c079563          	bnez	a5,ffffffffc0202d66 <pmm_init+0x66c>
ffffffffc0202aa0:	000b3783          	ld	a5,0(s6)
ffffffffc0202aa4:	4585                	li	a1,1
ffffffffc0202aa6:	739c                	ld	a5,32(a5)
ffffffffc0202aa8:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202aaa:	00093783          	ld	a5,0(s2)
ffffffffc0202aae:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd383f0>
    asm volatile("sfence.vma");
ffffffffc0202ab2:	12000073          	sfence.vma
ffffffffc0202ab6:	100027f3          	csrr	a5,sstatus
ffffffffc0202aba:	8b89                	andi	a5,a5,2
ffffffffc0202abc:	28079b63          	bnez	a5,ffffffffc0202d52 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ac0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ac4:	779c                	ld	a5,40(a5)
ffffffffc0202ac6:	9782                	jalr	a5
ffffffffc0202ac8:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202aca:	4b441b63          	bne	s0,s4,ffffffffc0202f80 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202ace:	00004517          	auipc	a0,0x4
ffffffffc0202ad2:	73250513          	addi	a0,a0,1842 # ffffffffc0207200 <default_pmm_manager+0x560>
ffffffffc0202ad6:	ec2fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0202ada:	100027f3          	csrr	a5,sstatus
ffffffffc0202ade:	8b89                	andi	a5,a5,2
ffffffffc0202ae0:	24079f63          	bnez	a5,ffffffffc0202d3e <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ae4:	000b3783          	ld	a5,0(s6)
ffffffffc0202ae8:	779c                	ld	a5,40(a5)
ffffffffc0202aea:	9782                	jalr	a5
ffffffffc0202aec:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202aee:	6098                	ld	a4,0(s1)
ffffffffc0202af0:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202af4:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202af6:	00c71793          	slli	a5,a4,0xc
ffffffffc0202afa:	6a05                	lui	s4,0x1
ffffffffc0202afc:	02f47c63          	bgeu	s0,a5,ffffffffc0202b34 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b00:	00c45793          	srli	a5,s0,0xc
ffffffffc0202b04:	00093503          	ld	a0,0(s2)
ffffffffc0202b08:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202e06 <pmm_init+0x70c>
ffffffffc0202b0c:	0009b583          	ld	a1,0(s3)
ffffffffc0202b10:	4601                	li	a2,0
ffffffffc0202b12:	95a2                	add	a1,a1,s0
ffffffffc0202b14:	c00ff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc0202b18:	32050463          	beqz	a0,ffffffffc0202e40 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b1c:	611c                	ld	a5,0(a0)
ffffffffc0202b1e:	078a                	slli	a5,a5,0x2
ffffffffc0202b20:	0157f7b3          	and	a5,a5,s5
ffffffffc0202b24:	2e879e63          	bne	a5,s0,ffffffffc0202e20 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b28:	6098                	ld	a4,0(s1)
ffffffffc0202b2a:	9452                	add	s0,s0,s4
ffffffffc0202b2c:	00c71793          	slli	a5,a4,0xc
ffffffffc0202b30:	fcf468e3          	bltu	s0,a5,ffffffffc0202b00 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202b34:	00093783          	ld	a5,0(s2)
ffffffffc0202b38:	639c                	ld	a5,0(a5)
ffffffffc0202b3a:	42079363          	bnez	a5,ffffffffc0202f60 <pmm_init+0x866>
ffffffffc0202b3e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b42:	8b89                	andi	a5,a5,2
ffffffffc0202b44:	24079963          	bnez	a5,ffffffffc0202d96 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202b48:	000b3783          	ld	a5,0(s6)
ffffffffc0202b4c:	4505                	li	a0,1
ffffffffc0202b4e:	6f9c                	ld	a5,24(a5)
ffffffffc0202b50:	9782                	jalr	a5
ffffffffc0202b52:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202b54:	00093503          	ld	a0,0(s2)
ffffffffc0202b58:	4699                	li	a3,6
ffffffffc0202b5a:	10000613          	li	a2,256
ffffffffc0202b5e:	85d2                	mv	a1,s4
ffffffffc0202b60:	aa5ff0ef          	jal	ra,ffffffffc0202604 <page_insert>
ffffffffc0202b64:	44051e63          	bnez	a0,ffffffffc0202fc0 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202b68:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f40>
ffffffffc0202b6c:	4785                	li	a5,1
ffffffffc0202b6e:	42f71963          	bne	a4,a5,ffffffffc0202fa0 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202b72:	00093503          	ld	a0,0(s2)
ffffffffc0202b76:	6405                	lui	s0,0x1
ffffffffc0202b78:	4699                	li	a3,6
ffffffffc0202b7a:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8e40>
ffffffffc0202b7e:	85d2                	mv	a1,s4
ffffffffc0202b80:	a85ff0ef          	jal	ra,ffffffffc0202604 <page_insert>
ffffffffc0202b84:	72051363          	bnez	a0,ffffffffc02032aa <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202b88:	000a2703          	lw	a4,0(s4)
ffffffffc0202b8c:	4789                	li	a5,2
ffffffffc0202b8e:	6ef71e63          	bne	a4,a5,ffffffffc020328a <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202b92:	00004597          	auipc	a1,0x4
ffffffffc0202b96:	7b658593          	addi	a1,a1,1974 # ffffffffc0207348 <default_pmm_manager+0x6a8>
ffffffffc0202b9a:	10000513          	li	a0,256
ffffffffc0202b9e:	1e6030ef          	jal	ra,ffffffffc0205d84 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202ba2:	10040593          	addi	a1,s0,256
ffffffffc0202ba6:	10000513          	li	a0,256
ffffffffc0202baa:	1ec030ef          	jal	ra,ffffffffc0205d96 <strcmp>
ffffffffc0202bae:	6a051e63          	bnez	a0,ffffffffc020326a <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202bb2:	000bb683          	ld	a3,0(s7)
ffffffffc0202bb6:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202bba:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202bbc:	40da06b3          	sub	a3,s4,a3
ffffffffc0202bc0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202bc2:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202bc4:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202bc6:	8031                	srli	s0,s0,0xc
ffffffffc0202bc8:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202bcc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202bce:	30f77d63          	bgeu	a4,a5,ffffffffc0202ee8 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202bd2:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202bd6:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202bda:	96be                	add	a3,a3,a5
ffffffffc0202bdc:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202be0:	16e030ef          	jal	ra,ffffffffc0205d4e <strlen>
ffffffffc0202be4:	66051363          	bnez	a0,ffffffffc020324a <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202be8:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202bec:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bee:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd383f0>
ffffffffc0202bf2:	068a                	slli	a3,a3,0x2
ffffffffc0202bf4:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bf6:	26f6f563          	bgeu	a3,a5,ffffffffc0202e60 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202bfa:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202bfc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202bfe:	2ef47563          	bgeu	s0,a5,ffffffffc0202ee8 <pmm_init+0x7ee>
ffffffffc0202c02:	0009b403          	ld	s0,0(s3)
ffffffffc0202c06:	9436                	add	s0,s0,a3
ffffffffc0202c08:	100027f3          	csrr	a5,sstatus
ffffffffc0202c0c:	8b89                	andi	a5,a5,2
ffffffffc0202c0e:	1e079163          	bnez	a5,ffffffffc0202df0 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202c12:	000b3783          	ld	a5,0(s6)
ffffffffc0202c16:	4585                	li	a1,1
ffffffffc0202c18:	8552                	mv	a0,s4
ffffffffc0202c1a:	739c                	ld	a5,32(a5)
ffffffffc0202c1c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c1e:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202c20:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c22:	078a                	slli	a5,a5,0x2
ffffffffc0202c24:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c26:	22e7fd63          	bgeu	a5,a4,ffffffffc0202e60 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c2a:	000bb503          	ld	a0,0(s7)
ffffffffc0202c2e:	fff80737          	lui	a4,0xfff80
ffffffffc0202c32:	97ba                	add	a5,a5,a4
ffffffffc0202c34:	079a                	slli	a5,a5,0x6
ffffffffc0202c36:	953e                	add	a0,a0,a5
ffffffffc0202c38:	100027f3          	csrr	a5,sstatus
ffffffffc0202c3c:	8b89                	andi	a5,a5,2
ffffffffc0202c3e:	18079d63          	bnez	a5,ffffffffc0202dd8 <pmm_init+0x6de>
ffffffffc0202c42:	000b3783          	ld	a5,0(s6)
ffffffffc0202c46:	4585                	li	a1,1
ffffffffc0202c48:	739c                	ld	a5,32(a5)
ffffffffc0202c4a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c4c:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202c50:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c52:	078a                	slli	a5,a5,0x2
ffffffffc0202c54:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c56:	20e7f563          	bgeu	a5,a4,ffffffffc0202e60 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c5a:	000bb503          	ld	a0,0(s7)
ffffffffc0202c5e:	fff80737          	lui	a4,0xfff80
ffffffffc0202c62:	97ba                	add	a5,a5,a4
ffffffffc0202c64:	079a                	slli	a5,a5,0x6
ffffffffc0202c66:	953e                	add	a0,a0,a5
ffffffffc0202c68:	100027f3          	csrr	a5,sstatus
ffffffffc0202c6c:	8b89                	andi	a5,a5,2
ffffffffc0202c6e:	14079963          	bnez	a5,ffffffffc0202dc0 <pmm_init+0x6c6>
ffffffffc0202c72:	000b3783          	ld	a5,0(s6)
ffffffffc0202c76:	4585                	li	a1,1
ffffffffc0202c78:	739c                	ld	a5,32(a5)
ffffffffc0202c7a:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202c7c:	00093783          	ld	a5,0(s2)
ffffffffc0202c80:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202c84:	12000073          	sfence.vma
ffffffffc0202c88:	100027f3          	csrr	a5,sstatus
ffffffffc0202c8c:	8b89                	andi	a5,a5,2
ffffffffc0202c8e:	10079f63          	bnez	a5,ffffffffc0202dac <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c92:	000b3783          	ld	a5,0(s6)
ffffffffc0202c96:	779c                	ld	a5,40(a5)
ffffffffc0202c98:	9782                	jalr	a5
ffffffffc0202c9a:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202c9c:	4c8c1e63          	bne	s8,s0,ffffffffc0203178 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202ca0:	00004517          	auipc	a0,0x4
ffffffffc0202ca4:	72050513          	addi	a0,a0,1824 # ffffffffc02073c0 <default_pmm_manager+0x720>
ffffffffc0202ca8:	cf0fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0202cac:	7406                	ld	s0,96(sp)
ffffffffc0202cae:	70a6                	ld	ra,104(sp)
ffffffffc0202cb0:	64e6                	ld	s1,88(sp)
ffffffffc0202cb2:	6946                	ld	s2,80(sp)
ffffffffc0202cb4:	69a6                	ld	s3,72(sp)
ffffffffc0202cb6:	6a06                	ld	s4,64(sp)
ffffffffc0202cb8:	7ae2                	ld	s5,56(sp)
ffffffffc0202cba:	7b42                	ld	s6,48(sp)
ffffffffc0202cbc:	7ba2                	ld	s7,40(sp)
ffffffffc0202cbe:	7c02                	ld	s8,32(sp)
ffffffffc0202cc0:	6ce2                	ld	s9,24(sp)
ffffffffc0202cc2:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202cc4:	f97fe06f          	j	ffffffffc0201c5a <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202cc8:	c80007b7          	lui	a5,0xc8000
ffffffffc0202ccc:	bc7d                	j	ffffffffc020278a <pmm_init+0x90>
        intr_disable();
ffffffffc0202cce:	ce1fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202cd2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cd6:	4505                	li	a0,1
ffffffffc0202cd8:	6f9c                	ld	a5,24(a5)
ffffffffc0202cda:	9782                	jalr	a5
ffffffffc0202cdc:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202cde:	ccbfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202ce2:	b9a9                	j	ffffffffc020293c <pmm_init+0x242>
        intr_disable();
ffffffffc0202ce4:	ccbfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202ce8:	000b3783          	ld	a5,0(s6)
ffffffffc0202cec:	4505                	li	a0,1
ffffffffc0202cee:	6f9c                	ld	a5,24(a5)
ffffffffc0202cf0:	9782                	jalr	a5
ffffffffc0202cf2:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202cf4:	cb5fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cf8:	b645                	j	ffffffffc0202898 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202cfa:	cb5fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cfe:	000b3783          	ld	a5,0(s6)
ffffffffc0202d02:	779c                	ld	a5,40(a5)
ffffffffc0202d04:	9782                	jalr	a5
ffffffffc0202d06:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d08:	ca1fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d0c:	b6b9                	j	ffffffffc020285a <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d0e:	6705                	lui	a4,0x1
ffffffffc0202d10:	177d                	addi	a4,a4,-1
ffffffffc0202d12:	96ba                	add	a3,a3,a4
ffffffffc0202d14:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d16:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202d1a:	14a77363          	bgeu	a4,a0,ffffffffc0202e60 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202d1e:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202d22:	fff80537          	lui	a0,0xfff80
ffffffffc0202d26:	972a                	add	a4,a4,a0
ffffffffc0202d28:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202d2a:	8c1d                	sub	s0,s0,a5
ffffffffc0202d2c:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202d30:	00c45593          	srli	a1,s0,0xc
ffffffffc0202d34:	9532                	add	a0,a0,a2
ffffffffc0202d36:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202d38:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202d3c:	b4c1                	j	ffffffffc02027fc <pmm_init+0x102>
        intr_disable();
ffffffffc0202d3e:	c71fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d42:	000b3783          	ld	a5,0(s6)
ffffffffc0202d46:	779c                	ld	a5,40(a5)
ffffffffc0202d48:	9782                	jalr	a5
ffffffffc0202d4a:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d4c:	c5dfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d50:	bb79                	j	ffffffffc0202aee <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202d52:	c5dfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202d56:	000b3783          	ld	a5,0(s6)
ffffffffc0202d5a:	779c                	ld	a5,40(a5)
ffffffffc0202d5c:	9782                	jalr	a5
ffffffffc0202d5e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d60:	c49fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d64:	b39d                	j	ffffffffc0202aca <pmm_init+0x3d0>
ffffffffc0202d66:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d68:	c47fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202d6c:	000b3783          	ld	a5,0(s6)
ffffffffc0202d70:	6522                	ld	a0,8(sp)
ffffffffc0202d72:	4585                	li	a1,1
ffffffffc0202d74:	739c                	ld	a5,32(a5)
ffffffffc0202d76:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d78:	c31fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d7c:	b33d                	j	ffffffffc0202aaa <pmm_init+0x3b0>
ffffffffc0202d7e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d80:	c2ffd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202d84:	000b3783          	ld	a5,0(s6)
ffffffffc0202d88:	6522                	ld	a0,8(sp)
ffffffffc0202d8a:	4585                	li	a1,1
ffffffffc0202d8c:	739c                	ld	a5,32(a5)
ffffffffc0202d8e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d90:	c19fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d94:	b1dd                	j	ffffffffc0202a7a <pmm_init+0x380>
        intr_disable();
ffffffffc0202d96:	c19fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d9a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d9e:	4505                	li	a0,1
ffffffffc0202da0:	6f9c                	ld	a5,24(a5)
ffffffffc0202da2:	9782                	jalr	a5
ffffffffc0202da4:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202da6:	c03fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202daa:	b36d                	j	ffffffffc0202b54 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202dac:	c03fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202db0:	000b3783          	ld	a5,0(s6)
ffffffffc0202db4:	779c                	ld	a5,40(a5)
ffffffffc0202db6:	9782                	jalr	a5
ffffffffc0202db8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202dba:	beffd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202dbe:	bdf9                	j	ffffffffc0202c9c <pmm_init+0x5a2>
ffffffffc0202dc0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dc2:	bedfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202dc6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dca:	6522                	ld	a0,8(sp)
ffffffffc0202dcc:	4585                	li	a1,1
ffffffffc0202dce:	739c                	ld	a5,32(a5)
ffffffffc0202dd0:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dd2:	bd7fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202dd6:	b55d                	j	ffffffffc0202c7c <pmm_init+0x582>
ffffffffc0202dd8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dda:	bd5fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202dde:	000b3783          	ld	a5,0(s6)
ffffffffc0202de2:	6522                	ld	a0,8(sp)
ffffffffc0202de4:	4585                	li	a1,1
ffffffffc0202de6:	739c                	ld	a5,32(a5)
ffffffffc0202de8:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dea:	bbffd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202dee:	bdb9                	j	ffffffffc0202c4c <pmm_init+0x552>
        intr_disable();
ffffffffc0202df0:	bbffd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202df4:	000b3783          	ld	a5,0(s6)
ffffffffc0202df8:	4585                	li	a1,1
ffffffffc0202dfa:	8552                	mv	a0,s4
ffffffffc0202dfc:	739c                	ld	a5,32(a5)
ffffffffc0202dfe:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e00:	ba9fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202e04:	bd29                	j	ffffffffc0202c1e <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e06:	86a2                	mv	a3,s0
ffffffffc0202e08:	00004617          	auipc	a2,0x4
ffffffffc0202e0c:	ed060613          	addi	a2,a2,-304 # ffffffffc0206cd8 <default_pmm_manager+0x38>
ffffffffc0202e10:	23c00593          	li	a1,572
ffffffffc0202e14:	00004517          	auipc	a0,0x4
ffffffffc0202e18:	fdc50513          	addi	a0,a0,-36 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202e1c:	e76fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202e20:	00004697          	auipc	a3,0x4
ffffffffc0202e24:	44068693          	addi	a3,a3,1088 # ffffffffc0207260 <default_pmm_manager+0x5c0>
ffffffffc0202e28:	00004617          	auipc	a2,0x4
ffffffffc0202e2c:	ac860613          	addi	a2,a2,-1336 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202e30:	23d00593          	li	a1,573
ffffffffc0202e34:	00004517          	auipc	a0,0x4
ffffffffc0202e38:	fbc50513          	addi	a0,a0,-68 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202e3c:	e56fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e40:	00004697          	auipc	a3,0x4
ffffffffc0202e44:	3e068693          	addi	a3,a3,992 # ffffffffc0207220 <default_pmm_manager+0x580>
ffffffffc0202e48:	00004617          	auipc	a2,0x4
ffffffffc0202e4c:	aa860613          	addi	a2,a2,-1368 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202e50:	23c00593          	li	a1,572
ffffffffc0202e54:	00004517          	auipc	a0,0x4
ffffffffc0202e58:	f9c50513          	addi	a0,a0,-100 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202e5c:	e36fd0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202e60:	fc5fe0ef          	jal	ra,ffffffffc0201e24 <pa2page.part.0>
ffffffffc0202e64:	fddfe0ef          	jal	ra,ffffffffc0201e40 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202e68:	00004697          	auipc	a3,0x4
ffffffffc0202e6c:	1b068693          	addi	a3,a3,432 # ffffffffc0207018 <default_pmm_manager+0x378>
ffffffffc0202e70:	00004617          	auipc	a2,0x4
ffffffffc0202e74:	a8060613          	addi	a2,a2,-1408 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202e78:	20c00593          	li	a1,524
ffffffffc0202e7c:	00004517          	auipc	a0,0x4
ffffffffc0202e80:	f7450513          	addi	a0,a0,-140 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202e84:	e0efd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202e88:	00004697          	auipc	a3,0x4
ffffffffc0202e8c:	0d068693          	addi	a3,a3,208 # ffffffffc0206f58 <default_pmm_manager+0x2b8>
ffffffffc0202e90:	00004617          	auipc	a2,0x4
ffffffffc0202e94:	a6060613          	addi	a2,a2,-1440 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202e98:	1ff00593          	li	a1,511
ffffffffc0202e9c:	00004517          	auipc	a0,0x4
ffffffffc0202ea0:	f5450513          	addi	a0,a0,-172 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202ea4:	deefd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202ea8:	00004697          	auipc	a3,0x4
ffffffffc0202eac:	07068693          	addi	a3,a3,112 # ffffffffc0206f18 <default_pmm_manager+0x278>
ffffffffc0202eb0:	00004617          	auipc	a2,0x4
ffffffffc0202eb4:	a4060613          	addi	a2,a2,-1472 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202eb8:	1fe00593          	li	a1,510
ffffffffc0202ebc:	00004517          	auipc	a0,0x4
ffffffffc0202ec0:	f3450513          	addi	a0,a0,-204 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202ec4:	dcefd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202ec8:	00004697          	auipc	a3,0x4
ffffffffc0202ecc:	03068693          	addi	a3,a3,48 # ffffffffc0206ef8 <default_pmm_manager+0x258>
ffffffffc0202ed0:	00004617          	auipc	a2,0x4
ffffffffc0202ed4:	a2060613          	addi	a2,a2,-1504 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202ed8:	1fd00593          	li	a1,509
ffffffffc0202edc:	00004517          	auipc	a0,0x4
ffffffffc0202ee0:	f1450513          	addi	a0,a0,-236 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202ee4:	daefd0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202ee8:	00004617          	auipc	a2,0x4
ffffffffc0202eec:	df060613          	addi	a2,a2,-528 # ffffffffc0206cd8 <default_pmm_manager+0x38>
ffffffffc0202ef0:	07100593          	li	a1,113
ffffffffc0202ef4:	00004517          	auipc	a0,0x4
ffffffffc0202ef8:	e0c50513          	addi	a0,a0,-500 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc0202efc:	d96fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f00:	00004697          	auipc	a3,0x4
ffffffffc0202f04:	2a868693          	addi	a3,a3,680 # ffffffffc02071a8 <default_pmm_manager+0x508>
ffffffffc0202f08:	00004617          	auipc	a2,0x4
ffffffffc0202f0c:	9e860613          	addi	a2,a2,-1560 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202f10:	22500593          	li	a1,549
ffffffffc0202f14:	00004517          	auipc	a0,0x4
ffffffffc0202f18:	edc50513          	addi	a0,a0,-292 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202f1c:	d76fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f20:	00004697          	auipc	a3,0x4
ffffffffc0202f24:	24068693          	addi	a3,a3,576 # ffffffffc0207160 <default_pmm_manager+0x4c0>
ffffffffc0202f28:	00004617          	auipc	a2,0x4
ffffffffc0202f2c:	9c860613          	addi	a2,a2,-1592 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202f30:	22300593          	li	a1,547
ffffffffc0202f34:	00004517          	auipc	a0,0x4
ffffffffc0202f38:	ebc50513          	addi	a0,a0,-324 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202f3c:	d56fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202f40:	00004697          	auipc	a3,0x4
ffffffffc0202f44:	25068693          	addi	a3,a3,592 # ffffffffc0207190 <default_pmm_manager+0x4f0>
ffffffffc0202f48:	00004617          	auipc	a2,0x4
ffffffffc0202f4c:	9a860613          	addi	a2,a2,-1624 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202f50:	22200593          	li	a1,546
ffffffffc0202f54:	00004517          	auipc	a0,0x4
ffffffffc0202f58:	e9c50513          	addi	a0,a0,-356 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202f5c:	d36fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202f60:	00004697          	auipc	a3,0x4
ffffffffc0202f64:	31868693          	addi	a3,a3,792 # ffffffffc0207278 <default_pmm_manager+0x5d8>
ffffffffc0202f68:	00004617          	auipc	a2,0x4
ffffffffc0202f6c:	98860613          	addi	a2,a2,-1656 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202f70:	24000593          	li	a1,576
ffffffffc0202f74:	00004517          	auipc	a0,0x4
ffffffffc0202f78:	e7c50513          	addi	a0,a0,-388 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202f7c:	d16fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202f80:	00004697          	auipc	a3,0x4
ffffffffc0202f84:	25868693          	addi	a3,a3,600 # ffffffffc02071d8 <default_pmm_manager+0x538>
ffffffffc0202f88:	00004617          	auipc	a2,0x4
ffffffffc0202f8c:	96860613          	addi	a2,a2,-1688 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202f90:	22d00593          	li	a1,557
ffffffffc0202f94:	00004517          	auipc	a0,0x4
ffffffffc0202f98:	e5c50513          	addi	a0,a0,-420 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202f9c:	cf6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202fa0:	00004697          	auipc	a3,0x4
ffffffffc0202fa4:	33068693          	addi	a3,a3,816 # ffffffffc02072d0 <default_pmm_manager+0x630>
ffffffffc0202fa8:	00004617          	auipc	a2,0x4
ffffffffc0202fac:	94860613          	addi	a2,a2,-1720 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202fb0:	24500593          	li	a1,581
ffffffffc0202fb4:	00004517          	auipc	a0,0x4
ffffffffc0202fb8:	e3c50513          	addi	a0,a0,-452 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202fbc:	cd6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202fc0:	00004697          	auipc	a3,0x4
ffffffffc0202fc4:	2d068693          	addi	a3,a3,720 # ffffffffc0207290 <default_pmm_manager+0x5f0>
ffffffffc0202fc8:	00004617          	auipc	a2,0x4
ffffffffc0202fcc:	92860613          	addi	a2,a2,-1752 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202fd0:	24400593          	li	a1,580
ffffffffc0202fd4:	00004517          	auipc	a0,0x4
ffffffffc0202fd8:	e1c50513          	addi	a0,a0,-484 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202fdc:	cb6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fe0:	00004697          	auipc	a3,0x4
ffffffffc0202fe4:	18068693          	addi	a3,a3,384 # ffffffffc0207160 <default_pmm_manager+0x4c0>
ffffffffc0202fe8:	00004617          	auipc	a2,0x4
ffffffffc0202fec:	90860613          	addi	a2,a2,-1784 # ffffffffc02068f0 <commands+0x868>
ffffffffc0202ff0:	21f00593          	li	a1,543
ffffffffc0202ff4:	00004517          	auipc	a0,0x4
ffffffffc0202ff8:	dfc50513          	addi	a0,a0,-516 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0202ffc:	c96fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203000:	00004697          	auipc	a3,0x4
ffffffffc0203004:	00068693          	mv	a3,a3
ffffffffc0203008:	00004617          	auipc	a2,0x4
ffffffffc020300c:	8e860613          	addi	a2,a2,-1816 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203010:	21e00593          	li	a1,542
ffffffffc0203014:	00004517          	auipc	a0,0x4
ffffffffc0203018:	ddc50513          	addi	a0,a0,-548 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc020301c:	c76fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203020:	00004697          	auipc	a3,0x4
ffffffffc0203024:	15868693          	addi	a3,a3,344 # ffffffffc0207178 <default_pmm_manager+0x4d8>
ffffffffc0203028:	00004617          	auipc	a2,0x4
ffffffffc020302c:	8c860613          	addi	a2,a2,-1848 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203030:	21b00593          	li	a1,539
ffffffffc0203034:	00004517          	auipc	a0,0x4
ffffffffc0203038:	dbc50513          	addi	a0,a0,-580 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc020303c:	c56fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203040:	00004697          	auipc	a3,0x4
ffffffffc0203044:	fa868693          	addi	a3,a3,-88 # ffffffffc0206fe8 <default_pmm_manager+0x348>
ffffffffc0203048:	00004617          	auipc	a2,0x4
ffffffffc020304c:	8a860613          	addi	a2,a2,-1880 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203050:	21a00593          	li	a1,538
ffffffffc0203054:	00004517          	auipc	a0,0x4
ffffffffc0203058:	d9c50513          	addi	a0,a0,-612 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc020305c:	c36fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203060:	00004697          	auipc	a3,0x4
ffffffffc0203064:	02868693          	addi	a3,a3,40 # ffffffffc0207088 <default_pmm_manager+0x3e8>
ffffffffc0203068:	00004617          	auipc	a2,0x4
ffffffffc020306c:	88860613          	addi	a2,a2,-1912 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203070:	21900593          	li	a1,537
ffffffffc0203074:	00004517          	auipc	a0,0x4
ffffffffc0203078:	d7c50513          	addi	a0,a0,-644 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc020307c:	c16fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203080:	00004697          	auipc	a3,0x4
ffffffffc0203084:	0e068693          	addi	a3,a3,224 # ffffffffc0207160 <default_pmm_manager+0x4c0>
ffffffffc0203088:	00004617          	auipc	a2,0x4
ffffffffc020308c:	86860613          	addi	a2,a2,-1944 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203090:	21800593          	li	a1,536
ffffffffc0203094:	00004517          	auipc	a0,0x4
ffffffffc0203098:	d5c50513          	addi	a0,a0,-676 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc020309c:	bf6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02030a0:	00004697          	auipc	a3,0x4
ffffffffc02030a4:	0a868693          	addi	a3,a3,168 # ffffffffc0207148 <default_pmm_manager+0x4a8>
ffffffffc02030a8:	00004617          	auipc	a2,0x4
ffffffffc02030ac:	84860613          	addi	a2,a2,-1976 # ffffffffc02068f0 <commands+0x868>
ffffffffc02030b0:	21700593          	li	a1,535
ffffffffc02030b4:	00004517          	auipc	a0,0x4
ffffffffc02030b8:	d3c50513          	addi	a0,a0,-708 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc02030bc:	bd6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02030c0:	00004697          	auipc	a3,0x4
ffffffffc02030c4:	05868693          	addi	a3,a3,88 # ffffffffc0207118 <default_pmm_manager+0x478>
ffffffffc02030c8:	00004617          	auipc	a2,0x4
ffffffffc02030cc:	82860613          	addi	a2,a2,-2008 # ffffffffc02068f0 <commands+0x868>
ffffffffc02030d0:	21600593          	li	a1,534
ffffffffc02030d4:	00004517          	auipc	a0,0x4
ffffffffc02030d8:	d1c50513          	addi	a0,a0,-740 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc02030dc:	bb6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02030e0:	00004697          	auipc	a3,0x4
ffffffffc02030e4:	02068693          	addi	a3,a3,32 # ffffffffc0207100 <default_pmm_manager+0x460>
ffffffffc02030e8:	00004617          	auipc	a2,0x4
ffffffffc02030ec:	80860613          	addi	a2,a2,-2040 # ffffffffc02068f0 <commands+0x868>
ffffffffc02030f0:	21400593          	li	a1,532
ffffffffc02030f4:	00004517          	auipc	a0,0x4
ffffffffc02030f8:	cfc50513          	addi	a0,a0,-772 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc02030fc:	b96fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203100:	00004697          	auipc	a3,0x4
ffffffffc0203104:	fe068693          	addi	a3,a3,-32 # ffffffffc02070e0 <default_pmm_manager+0x440>
ffffffffc0203108:	00003617          	auipc	a2,0x3
ffffffffc020310c:	7e860613          	addi	a2,a2,2024 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203110:	21300593          	li	a1,531
ffffffffc0203114:	00004517          	auipc	a0,0x4
ffffffffc0203118:	cdc50513          	addi	a0,a0,-804 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc020311c:	b76fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203120:	00004697          	auipc	a3,0x4
ffffffffc0203124:	fb068693          	addi	a3,a3,-80 # ffffffffc02070d0 <default_pmm_manager+0x430>
ffffffffc0203128:	00003617          	auipc	a2,0x3
ffffffffc020312c:	7c860613          	addi	a2,a2,1992 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203130:	21200593          	li	a1,530
ffffffffc0203134:	00004517          	auipc	a0,0x4
ffffffffc0203138:	cbc50513          	addi	a0,a0,-836 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc020313c:	b56fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203140:	00004697          	auipc	a3,0x4
ffffffffc0203144:	f8068693          	addi	a3,a3,-128 # ffffffffc02070c0 <default_pmm_manager+0x420>
ffffffffc0203148:	00003617          	auipc	a2,0x3
ffffffffc020314c:	7a860613          	addi	a2,a2,1960 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203150:	21100593          	li	a1,529
ffffffffc0203154:	00004517          	auipc	a0,0x4
ffffffffc0203158:	c9c50513          	addi	a0,a0,-868 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc020315c:	b36fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("DTB memory info not available");
ffffffffc0203160:	00004617          	auipc	a2,0x4
ffffffffc0203164:	d0060613          	addi	a2,a2,-768 # ffffffffc0206e60 <default_pmm_manager+0x1c0>
ffffffffc0203168:	06500593          	li	a1,101
ffffffffc020316c:	00004517          	auipc	a0,0x4
ffffffffc0203170:	c8450513          	addi	a0,a0,-892 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0203174:	b1efd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203178:	00004697          	auipc	a3,0x4
ffffffffc020317c:	06068693          	addi	a3,a3,96 # ffffffffc02071d8 <default_pmm_manager+0x538>
ffffffffc0203180:	00003617          	auipc	a2,0x3
ffffffffc0203184:	77060613          	addi	a2,a2,1904 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203188:	25700593          	li	a1,599
ffffffffc020318c:	00004517          	auipc	a0,0x4
ffffffffc0203190:	c6450513          	addi	a0,a0,-924 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0203194:	afefd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203198:	00004697          	auipc	a3,0x4
ffffffffc020319c:	ef068693          	addi	a3,a3,-272 # ffffffffc0207088 <default_pmm_manager+0x3e8>
ffffffffc02031a0:	00003617          	auipc	a2,0x3
ffffffffc02031a4:	75060613          	addi	a2,a2,1872 # ffffffffc02068f0 <commands+0x868>
ffffffffc02031a8:	21000593          	li	a1,528
ffffffffc02031ac:	00004517          	auipc	a0,0x4
ffffffffc02031b0:	c4450513          	addi	a0,a0,-956 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc02031b4:	adefd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02031b8:	00004697          	auipc	a3,0x4
ffffffffc02031bc:	e9068693          	addi	a3,a3,-368 # ffffffffc0207048 <default_pmm_manager+0x3a8>
ffffffffc02031c0:	00003617          	auipc	a2,0x3
ffffffffc02031c4:	73060613          	addi	a2,a2,1840 # ffffffffc02068f0 <commands+0x868>
ffffffffc02031c8:	20f00593          	li	a1,527
ffffffffc02031cc:	00004517          	auipc	a0,0x4
ffffffffc02031d0:	c2450513          	addi	a0,a0,-988 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc02031d4:	abefd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02031d8:	86d6                	mv	a3,s5
ffffffffc02031da:	00004617          	auipc	a2,0x4
ffffffffc02031de:	afe60613          	addi	a2,a2,-1282 # ffffffffc0206cd8 <default_pmm_manager+0x38>
ffffffffc02031e2:	20b00593          	li	a1,523
ffffffffc02031e6:	00004517          	auipc	a0,0x4
ffffffffc02031ea:	c0a50513          	addi	a0,a0,-1014 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc02031ee:	aa4fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02031f2:	00004617          	auipc	a2,0x4
ffffffffc02031f6:	ae660613          	addi	a2,a2,-1306 # ffffffffc0206cd8 <default_pmm_manager+0x38>
ffffffffc02031fa:	20a00593          	li	a1,522
ffffffffc02031fe:	00004517          	auipc	a0,0x4
ffffffffc0203202:	bf250513          	addi	a0,a0,-1038 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0203206:	a8cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020320a:	00004697          	auipc	a3,0x4
ffffffffc020320e:	df668693          	addi	a3,a3,-522 # ffffffffc0207000 <default_pmm_manager+0x360>
ffffffffc0203212:	00003617          	auipc	a2,0x3
ffffffffc0203216:	6de60613          	addi	a2,a2,1758 # ffffffffc02068f0 <commands+0x868>
ffffffffc020321a:	20800593          	li	a1,520
ffffffffc020321e:	00004517          	auipc	a0,0x4
ffffffffc0203222:	bd250513          	addi	a0,a0,-1070 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0203226:	a6cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020322a:	00004697          	auipc	a3,0x4
ffffffffc020322e:	dbe68693          	addi	a3,a3,-578 # ffffffffc0206fe8 <default_pmm_manager+0x348>
ffffffffc0203232:	00003617          	auipc	a2,0x3
ffffffffc0203236:	6be60613          	addi	a2,a2,1726 # ffffffffc02068f0 <commands+0x868>
ffffffffc020323a:	20700593          	li	a1,519
ffffffffc020323e:	00004517          	auipc	a0,0x4
ffffffffc0203242:	bb250513          	addi	a0,a0,-1102 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0203246:	a4cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020324a:	00004697          	auipc	a3,0x4
ffffffffc020324e:	14e68693          	addi	a3,a3,334 # ffffffffc0207398 <default_pmm_manager+0x6f8>
ffffffffc0203252:	00003617          	auipc	a2,0x3
ffffffffc0203256:	69e60613          	addi	a2,a2,1694 # ffffffffc02068f0 <commands+0x868>
ffffffffc020325a:	24e00593          	li	a1,590
ffffffffc020325e:	00004517          	auipc	a0,0x4
ffffffffc0203262:	b9250513          	addi	a0,a0,-1134 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0203266:	a2cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020326a:	00004697          	auipc	a3,0x4
ffffffffc020326e:	0f668693          	addi	a3,a3,246 # ffffffffc0207360 <default_pmm_manager+0x6c0>
ffffffffc0203272:	00003617          	auipc	a2,0x3
ffffffffc0203276:	67e60613          	addi	a2,a2,1662 # ffffffffc02068f0 <commands+0x868>
ffffffffc020327a:	24b00593          	li	a1,587
ffffffffc020327e:	00004517          	auipc	a0,0x4
ffffffffc0203282:	b7250513          	addi	a0,a0,-1166 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0203286:	a0cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 2);
ffffffffc020328a:	00004697          	auipc	a3,0x4
ffffffffc020328e:	0a668693          	addi	a3,a3,166 # ffffffffc0207330 <default_pmm_manager+0x690>
ffffffffc0203292:	00003617          	auipc	a2,0x3
ffffffffc0203296:	65e60613          	addi	a2,a2,1630 # ffffffffc02068f0 <commands+0x868>
ffffffffc020329a:	24700593          	li	a1,583
ffffffffc020329e:	00004517          	auipc	a0,0x4
ffffffffc02032a2:	b5250513          	addi	a0,a0,-1198 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc02032a6:	9ecfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02032aa:	00004697          	auipc	a3,0x4
ffffffffc02032ae:	03e68693          	addi	a3,a3,62 # ffffffffc02072e8 <default_pmm_manager+0x648>
ffffffffc02032b2:	00003617          	auipc	a2,0x3
ffffffffc02032b6:	63e60613          	addi	a2,a2,1598 # ffffffffc02068f0 <commands+0x868>
ffffffffc02032ba:	24600593          	li	a1,582
ffffffffc02032be:	00004517          	auipc	a0,0x4
ffffffffc02032c2:	b3250513          	addi	a0,a0,-1230 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc02032c6:	9ccfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02032ca:	00004617          	auipc	a2,0x4
ffffffffc02032ce:	ab660613          	addi	a2,a2,-1354 # ffffffffc0206d80 <default_pmm_manager+0xe0>
ffffffffc02032d2:	0c900593          	li	a1,201
ffffffffc02032d6:	00004517          	auipc	a0,0x4
ffffffffc02032da:	b1a50513          	addi	a0,a0,-1254 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc02032de:	9b4fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02032e2:	00004617          	auipc	a2,0x4
ffffffffc02032e6:	a9e60613          	addi	a2,a2,-1378 # ffffffffc0206d80 <default_pmm_manager+0xe0>
ffffffffc02032ea:	08100593          	li	a1,129
ffffffffc02032ee:	00004517          	auipc	a0,0x4
ffffffffc02032f2:	b0250513          	addi	a0,a0,-1278 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc02032f6:	99cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02032fa:	00004697          	auipc	a3,0x4
ffffffffc02032fe:	cbe68693          	addi	a3,a3,-834 # ffffffffc0206fb8 <default_pmm_manager+0x318>
ffffffffc0203302:	00003617          	auipc	a2,0x3
ffffffffc0203306:	5ee60613          	addi	a2,a2,1518 # ffffffffc02068f0 <commands+0x868>
ffffffffc020330a:	20600593          	li	a1,518
ffffffffc020330e:	00004517          	auipc	a0,0x4
ffffffffc0203312:	ae250513          	addi	a0,a0,-1310 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0203316:	97cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020331a:	00004697          	auipc	a3,0x4
ffffffffc020331e:	c6e68693          	addi	a3,a3,-914 # ffffffffc0206f88 <default_pmm_manager+0x2e8>
ffffffffc0203322:	00003617          	auipc	a2,0x3
ffffffffc0203326:	5ce60613          	addi	a2,a2,1486 # ffffffffc02068f0 <commands+0x868>
ffffffffc020332a:	20300593          	li	a1,515
ffffffffc020332e:	00004517          	auipc	a0,0x4
ffffffffc0203332:	ac250513          	addi	a0,a0,-1342 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc0203336:	95cfd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020333a <copy_range>:
{
ffffffffc020333a:	711d                	addi	sp,sp,-96
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020333c:	00d667b3          	or	a5,a2,a3
{
ffffffffc0203340:	ec86                	sd	ra,88(sp)
ffffffffc0203342:	e8a2                	sd	s0,80(sp)
ffffffffc0203344:	e4a6                	sd	s1,72(sp)
ffffffffc0203346:	e0ca                	sd	s2,64(sp)
ffffffffc0203348:	fc4e                	sd	s3,56(sp)
ffffffffc020334a:	f852                	sd	s4,48(sp)
ffffffffc020334c:	f456                	sd	s5,40(sp)
ffffffffc020334e:	f05a                	sd	s6,32(sp)
ffffffffc0203350:	ec5e                	sd	s7,24(sp)
ffffffffc0203352:	e862                	sd	s8,16(sp)
ffffffffc0203354:	e466                	sd	s9,8(sp)
ffffffffc0203356:	e06a                	sd	s10,0(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203358:	17d2                	slli	a5,a5,0x34
ffffffffc020335a:	14079863          	bnez	a5,ffffffffc02034aa <copy_range+0x170>
    assert(USER_ACCESS(start, end));
ffffffffc020335e:	002007b7          	lui	a5,0x200
ffffffffc0203362:	8432                	mv	s0,a2
ffffffffc0203364:	10f66763          	bltu	a2,a5,ffffffffc0203472 <copy_range+0x138>
ffffffffc0203368:	8936                	mv	s2,a3
ffffffffc020336a:	10d67463          	bgeu	a2,a3,ffffffffc0203472 <copy_range+0x138>
ffffffffc020336e:	4785                	li	a5,1
ffffffffc0203370:	07fe                	slli	a5,a5,0x1f
ffffffffc0203372:	10d7e063          	bltu	a5,a3,ffffffffc0203472 <copy_range+0x138>
ffffffffc0203376:	8aaa                	mv	s5,a0
ffffffffc0203378:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc020337a:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020337c:	000c4c17          	auipc	s8,0xc4
ffffffffc0203380:	83cc0c13          	addi	s8,s8,-1988 # ffffffffc02c6bb8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203384:	000c4b97          	auipc	s7,0xc4
ffffffffc0203388:	83cb8b93          	addi	s7,s7,-1988 # ffffffffc02c6bc0 <pages>
ffffffffc020338c:	fff80b37          	lui	s6,0xfff80
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203390:	00200d37          	lui	s10,0x200
ffffffffc0203394:	ffe00cb7          	lui	s9,0xffe00
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203398:	4601                	li	a2,0
ffffffffc020339a:	85a2                	mv	a1,s0
ffffffffc020339c:	854e                	mv	a0,s3
ffffffffc020339e:	b77fe0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc02033a2:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02033a4:	c559                	beqz	a0,ffffffffc0203432 <copy_range+0xf8>
        if (*ptep & PTE_V)
ffffffffc02033a6:	611c                	ld	a5,0(a0)
ffffffffc02033a8:	8b85                	andi	a5,a5,1
ffffffffc02033aa:	e39d                	bnez	a5,ffffffffc02033d0 <copy_range+0x96>
        start += PGSIZE;
ffffffffc02033ac:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02033ae:	ff2465e3          	bltu	s0,s2,ffffffffc0203398 <copy_range+0x5e>
    return 0;
ffffffffc02033b2:	4501                	li	a0,0
}
ffffffffc02033b4:	60e6                	ld	ra,88(sp)
ffffffffc02033b6:	6446                	ld	s0,80(sp)
ffffffffc02033b8:	64a6                	ld	s1,72(sp)
ffffffffc02033ba:	6906                	ld	s2,64(sp)
ffffffffc02033bc:	79e2                	ld	s3,56(sp)
ffffffffc02033be:	7a42                	ld	s4,48(sp)
ffffffffc02033c0:	7aa2                	ld	s5,40(sp)
ffffffffc02033c2:	7b02                	ld	s6,32(sp)
ffffffffc02033c4:	6be2                	ld	s7,24(sp)
ffffffffc02033c6:	6c42                	ld	s8,16(sp)
ffffffffc02033c8:	6ca2                	ld	s9,8(sp)
ffffffffc02033ca:	6d02                	ld	s10,0(sp)
ffffffffc02033cc:	6125                	addi	sp,sp,96
ffffffffc02033ce:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02033d0:	4605                	li	a2,1
ffffffffc02033d2:	85a2                	mv	a1,s0
ffffffffc02033d4:	8556                	mv	a0,s5
ffffffffc02033d6:	b3ffe0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc02033da:	cd35                	beqz	a0,ffffffffc0203456 <copy_range+0x11c>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02033dc:	6098                	ld	a4,0(s1)
    if (!(pte & PTE_V))
ffffffffc02033de:	00177793          	andi	a5,a4,1
ffffffffc02033e2:	0007069b          	sext.w	a3,a4
ffffffffc02033e6:	cbb5                	beqz	a5,ffffffffc020345a <copy_range+0x120>
    if (PPN(pa) >= npage)
ffffffffc02033e8:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc02033ec:	00271793          	slli	a5,a4,0x2
ffffffffc02033f0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02033f2:	0ac7f063          	bgeu	a5,a2,ffffffffc0203492 <copy_range+0x158>
    return &pages[PPN(pa) - nbase];
ffffffffc02033f6:	000bb583          	ld	a1,0(s7)
ffffffffc02033fa:	97da                	add	a5,a5,s6
ffffffffc02033fc:	079a                	slli	a5,a5,0x6
            if (perm & PTE_W)
ffffffffc02033fe:	0046f613          	andi	a2,a3,4
ffffffffc0203402:	95be                	add	a1,a1,a5
ffffffffc0203404:	ee15                	bnez	a2,ffffffffc0203440 <copy_range+0x106>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203406:	8afd                	andi	a3,a3,31
            int ret = page_insert(to, page, start, perm);
ffffffffc0203408:	8622                	mv	a2,s0
ffffffffc020340a:	8556                	mv	a0,s5
ffffffffc020340c:	9f8ff0ef          	jal	ra,ffffffffc0202604 <page_insert>
            assert(ret == 0);
ffffffffc0203410:	dd51                	beqz	a0,ffffffffc02033ac <copy_range+0x72>
ffffffffc0203412:	00004697          	auipc	a3,0x4
ffffffffc0203416:	fce68693          	addi	a3,a3,-50 # ffffffffc02073e0 <default_pmm_manager+0x740>
ffffffffc020341a:	00003617          	auipc	a2,0x3
ffffffffc020341e:	4d660613          	addi	a2,a2,1238 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203422:	19b00593          	li	a1,411
ffffffffc0203426:	00004517          	auipc	a0,0x4
ffffffffc020342a:	9ca50513          	addi	a0,a0,-1590 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc020342e:	864fd0ef          	jal	ra,ffffffffc0200492 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203432:	946a                	add	s0,s0,s10
ffffffffc0203434:	01947433          	and	s0,s0,s9
    } while (start != 0 && start < end);
ffffffffc0203438:	dc2d                	beqz	s0,ffffffffc02033b2 <copy_range+0x78>
ffffffffc020343a:	f5246fe3          	bltu	s0,s2,ffffffffc0203398 <copy_range+0x5e>
ffffffffc020343e:	bf95                	j	ffffffffc02033b2 <copy_range+0x78>
                *ptep = (*ptep & ~PTE_W) | PTE_COW;
ffffffffc0203440:	efb77713          	andi	a4,a4,-261
ffffffffc0203444:	10076713          	ori	a4,a4,256
                perm = (perm & ~PTE_W) | PTE_COW;
ffffffffc0203448:	8aed                	andi	a3,a3,27
ffffffffc020344a:	1006e693          	ori	a3,a3,256
                *ptep = (*ptep & ~PTE_W) | PTE_COW;
ffffffffc020344e:	e098                	sd	a4,0(s1)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203450:	12040073          	sfence.vma	s0
}
ffffffffc0203454:	bf55                	j	ffffffffc0203408 <copy_range+0xce>
                return -E_NO_MEM;
ffffffffc0203456:	5571                	li	a0,-4
ffffffffc0203458:	bfb1                	j	ffffffffc02033b4 <copy_range+0x7a>
        panic("pte2page called with invalid pte");
ffffffffc020345a:	00004617          	auipc	a2,0x4
ffffffffc020345e:	96e60613          	addi	a2,a2,-1682 # ffffffffc0206dc8 <default_pmm_manager+0x128>
ffffffffc0203462:	07f00593          	li	a1,127
ffffffffc0203466:	00004517          	auipc	a0,0x4
ffffffffc020346a:	89a50513          	addi	a0,a0,-1894 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc020346e:	824fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203472:	00004697          	auipc	a3,0x4
ffffffffc0203476:	9be68693          	addi	a3,a3,-1602 # ffffffffc0206e30 <default_pmm_manager+0x190>
ffffffffc020347a:	00003617          	auipc	a2,0x3
ffffffffc020347e:	47660613          	addi	a2,a2,1142 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203482:	17e00593          	li	a1,382
ffffffffc0203486:	00004517          	auipc	a0,0x4
ffffffffc020348a:	96a50513          	addi	a0,a0,-1686 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc020348e:	804fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203492:	00004617          	auipc	a2,0x4
ffffffffc0203496:	91660613          	addi	a2,a2,-1770 # ffffffffc0206da8 <default_pmm_manager+0x108>
ffffffffc020349a:	06900593          	li	a1,105
ffffffffc020349e:	00004517          	auipc	a0,0x4
ffffffffc02034a2:	86250513          	addi	a0,a0,-1950 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc02034a6:	fedfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02034aa:	00004697          	auipc	a3,0x4
ffffffffc02034ae:	95668693          	addi	a3,a3,-1706 # ffffffffc0206e00 <default_pmm_manager+0x160>
ffffffffc02034b2:	00003617          	auipc	a2,0x3
ffffffffc02034b6:	43e60613          	addi	a2,a2,1086 # ffffffffc02068f0 <commands+0x868>
ffffffffc02034ba:	17d00593          	li	a1,381
ffffffffc02034be:	00004517          	auipc	a0,0x4
ffffffffc02034c2:	93250513          	addi	a0,a0,-1742 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc02034c6:	fcdfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02034ca <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02034ca:	12058073          	sfence.vma	a1
}
ffffffffc02034ce:	8082                	ret

ffffffffc02034d0 <pgdir_alloc_page>:
{
ffffffffc02034d0:	7179                	addi	sp,sp,-48
ffffffffc02034d2:	ec26                	sd	s1,24(sp)
ffffffffc02034d4:	e84a                	sd	s2,16(sp)
ffffffffc02034d6:	e052                	sd	s4,0(sp)
ffffffffc02034d8:	f406                	sd	ra,40(sp)
ffffffffc02034da:	f022                	sd	s0,32(sp)
ffffffffc02034dc:	e44e                	sd	s3,8(sp)
ffffffffc02034de:	8a2a                	mv	s4,a0
ffffffffc02034e0:	84ae                	mv	s1,a1
ffffffffc02034e2:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02034e4:	100027f3          	csrr	a5,sstatus
ffffffffc02034e8:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02034ea:	000c3997          	auipc	s3,0xc3
ffffffffc02034ee:	6de98993          	addi	s3,s3,1758 # ffffffffc02c6bc8 <pmm_manager>
ffffffffc02034f2:	ef8d                	bnez	a5,ffffffffc020352c <pgdir_alloc_page+0x5c>
ffffffffc02034f4:	0009b783          	ld	a5,0(s3)
ffffffffc02034f8:	4505                	li	a0,1
ffffffffc02034fa:	6f9c                	ld	a5,24(a5)
ffffffffc02034fc:	9782                	jalr	a5
ffffffffc02034fe:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0203500:	cc09                	beqz	s0,ffffffffc020351a <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203502:	86ca                	mv	a3,s2
ffffffffc0203504:	8626                	mv	a2,s1
ffffffffc0203506:	85a2                	mv	a1,s0
ffffffffc0203508:	8552                	mv	a0,s4
ffffffffc020350a:	8faff0ef          	jal	ra,ffffffffc0202604 <page_insert>
ffffffffc020350e:	e915                	bnez	a0,ffffffffc0203542 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0203510:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc0203512:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc0203514:	4785                	li	a5,1
ffffffffc0203516:	04f71e63          	bne	a4,a5,ffffffffc0203572 <pgdir_alloc_page+0xa2>
}
ffffffffc020351a:	70a2                	ld	ra,40(sp)
ffffffffc020351c:	8522                	mv	a0,s0
ffffffffc020351e:	7402                	ld	s0,32(sp)
ffffffffc0203520:	64e2                	ld	s1,24(sp)
ffffffffc0203522:	6942                	ld	s2,16(sp)
ffffffffc0203524:	69a2                	ld	s3,8(sp)
ffffffffc0203526:	6a02                	ld	s4,0(sp)
ffffffffc0203528:	6145                	addi	sp,sp,48
ffffffffc020352a:	8082                	ret
        intr_disable();
ffffffffc020352c:	c82fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203530:	0009b783          	ld	a5,0(s3)
ffffffffc0203534:	4505                	li	a0,1
ffffffffc0203536:	6f9c                	ld	a5,24(a5)
ffffffffc0203538:	9782                	jalr	a5
ffffffffc020353a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020353c:	c6cfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0203540:	b7c1                	j	ffffffffc0203500 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203542:	100027f3          	csrr	a5,sstatus
ffffffffc0203546:	8b89                	andi	a5,a5,2
ffffffffc0203548:	eb89                	bnez	a5,ffffffffc020355a <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc020354a:	0009b783          	ld	a5,0(s3)
ffffffffc020354e:	8522                	mv	a0,s0
ffffffffc0203550:	4585                	li	a1,1
ffffffffc0203552:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203554:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203556:	9782                	jalr	a5
    if (flag)
ffffffffc0203558:	b7c9                	j	ffffffffc020351a <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc020355a:	c54fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc020355e:	0009b783          	ld	a5,0(s3)
ffffffffc0203562:	8522                	mv	a0,s0
ffffffffc0203564:	4585                	li	a1,1
ffffffffc0203566:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203568:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020356a:	9782                	jalr	a5
        intr_enable();
ffffffffc020356c:	c3cfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0203570:	b76d                	j	ffffffffc020351a <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203572:	00004697          	auipc	a3,0x4
ffffffffc0203576:	e7e68693          	addi	a3,a3,-386 # ffffffffc02073f0 <default_pmm_manager+0x750>
ffffffffc020357a:	00003617          	auipc	a2,0x3
ffffffffc020357e:	37660613          	addi	a2,a2,886 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203582:	1e400593          	li	a1,484
ffffffffc0203586:	00004517          	auipc	a0,0x4
ffffffffc020358a:	86a50513          	addi	a0,a0,-1942 # ffffffffc0206df0 <default_pmm_manager+0x150>
ffffffffc020358e:	f05fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203592 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203592:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203594:	00004697          	auipc	a3,0x4
ffffffffc0203598:	e7468693          	addi	a3,a3,-396 # ffffffffc0207408 <default_pmm_manager+0x768>
ffffffffc020359c:	00003617          	auipc	a2,0x3
ffffffffc02035a0:	35460613          	addi	a2,a2,852 # ffffffffc02068f0 <commands+0x868>
ffffffffc02035a4:	08300593          	li	a1,131
ffffffffc02035a8:	00004517          	auipc	a0,0x4
ffffffffc02035ac:	e8050513          	addi	a0,a0,-384 # ffffffffc0207428 <default_pmm_manager+0x788>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02035b0:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02035b2:	ee1fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02035b6 <mm_create>:
{
ffffffffc02035b6:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02035b8:	04000513          	li	a0,64
{
ffffffffc02035bc:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02035be:	ec0fe0ef          	jal	ra,ffffffffc0201c7e <kmalloc>
    if (mm != NULL)
ffffffffc02035c2:	cd19                	beqz	a0,ffffffffc02035e0 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02035c4:	e508                	sd	a0,8(a0)
ffffffffc02035c6:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02035c8:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02035cc:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02035d0:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02035d4:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02035d8:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02035dc:	02053c23          	sd	zero,56(a0)
}
ffffffffc02035e0:	60a2                	ld	ra,8(sp)
ffffffffc02035e2:	0141                	addi	sp,sp,16
ffffffffc02035e4:	8082                	ret

ffffffffc02035e6 <find_vma>:
{
ffffffffc02035e6:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02035e8:	c505                	beqz	a0,ffffffffc0203610 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02035ea:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02035ec:	c501                	beqz	a0,ffffffffc02035f4 <find_vma+0xe>
ffffffffc02035ee:	651c                	ld	a5,8(a0)
ffffffffc02035f0:	02f5f263          	bgeu	a1,a5,ffffffffc0203614 <find_vma+0x2e>
    return listelm->next;
ffffffffc02035f4:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02035f6:	00f68d63          	beq	a3,a5,ffffffffc0203610 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02035fa:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_matrix_out_size+0x1f38d8>
ffffffffc02035fe:	00e5e663          	bltu	a1,a4,ffffffffc020360a <find_vma+0x24>
ffffffffc0203602:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203606:	00e5ec63          	bltu	a1,a4,ffffffffc020361e <find_vma+0x38>
ffffffffc020360a:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc020360c:	fef697e3          	bne	a3,a5,ffffffffc02035fa <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203610:	4501                	li	a0,0
}
ffffffffc0203612:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203614:	691c                	ld	a5,16(a0)
ffffffffc0203616:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02035f4 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc020361a:	ea88                	sd	a0,16(a3)
ffffffffc020361c:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc020361e:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203622:	ea88                	sd	a0,16(a3)
ffffffffc0203624:	8082                	ret

ffffffffc0203626 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203626:	6590                	ld	a2,8(a1)
ffffffffc0203628:	0105b803          	ld	a6,16(a1)
{
ffffffffc020362c:	1141                	addi	sp,sp,-16
ffffffffc020362e:	e406                	sd	ra,8(sp)
ffffffffc0203630:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203632:	01066763          	bltu	a2,a6,ffffffffc0203640 <insert_vma_struct+0x1a>
ffffffffc0203636:	a085                	j	ffffffffc0203696 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203638:	fe87b703          	ld	a4,-24(a5)
ffffffffc020363c:	04e66863          	bltu	a2,a4,ffffffffc020368c <insert_vma_struct+0x66>
ffffffffc0203640:	86be                	mv	a3,a5
ffffffffc0203642:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203644:	fef51ae3          	bne	a0,a5,ffffffffc0203638 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203648:	02a68463          	beq	a3,a0,ffffffffc0203670 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020364c:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203650:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203654:	08e8f163          	bgeu	a7,a4,ffffffffc02036d6 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203658:	04e66f63          	bltu	a2,a4,ffffffffc02036b6 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc020365c:	00f50a63          	beq	a0,a5,ffffffffc0203670 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203660:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203664:	05076963          	bltu	a4,a6,ffffffffc02036b6 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203668:	ff07b603          	ld	a2,-16(a5)
ffffffffc020366c:	02c77363          	bgeu	a4,a2,ffffffffc0203692 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203670:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203672:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203674:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203678:	e390                	sd	a2,0(a5)
ffffffffc020367a:	e690                	sd	a2,8(a3)
}
ffffffffc020367c:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020367e:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203680:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203682:	0017079b          	addiw	a5,a4,1
ffffffffc0203686:	d11c                	sw	a5,32(a0)
}
ffffffffc0203688:	0141                	addi	sp,sp,16
ffffffffc020368a:	8082                	ret
    if (le_prev != list)
ffffffffc020368c:	fca690e3          	bne	a3,a0,ffffffffc020364c <insert_vma_struct+0x26>
ffffffffc0203690:	bfd1                	j	ffffffffc0203664 <insert_vma_struct+0x3e>
ffffffffc0203692:	f01ff0ef          	jal	ra,ffffffffc0203592 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203696:	00004697          	auipc	a3,0x4
ffffffffc020369a:	da268693          	addi	a3,a3,-606 # ffffffffc0207438 <default_pmm_manager+0x798>
ffffffffc020369e:	00003617          	auipc	a2,0x3
ffffffffc02036a2:	25260613          	addi	a2,a2,594 # ffffffffc02068f0 <commands+0x868>
ffffffffc02036a6:	08900593          	li	a1,137
ffffffffc02036aa:	00004517          	auipc	a0,0x4
ffffffffc02036ae:	d7e50513          	addi	a0,a0,-642 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc02036b2:	de1fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02036b6:	00004697          	auipc	a3,0x4
ffffffffc02036ba:	dc268693          	addi	a3,a3,-574 # ffffffffc0207478 <default_pmm_manager+0x7d8>
ffffffffc02036be:	00003617          	auipc	a2,0x3
ffffffffc02036c2:	23260613          	addi	a2,a2,562 # ffffffffc02068f0 <commands+0x868>
ffffffffc02036c6:	08200593          	li	a1,130
ffffffffc02036ca:	00004517          	auipc	a0,0x4
ffffffffc02036ce:	d5e50513          	addi	a0,a0,-674 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc02036d2:	dc1fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02036d6:	00004697          	auipc	a3,0x4
ffffffffc02036da:	d8268693          	addi	a3,a3,-638 # ffffffffc0207458 <default_pmm_manager+0x7b8>
ffffffffc02036de:	00003617          	auipc	a2,0x3
ffffffffc02036e2:	21260613          	addi	a2,a2,530 # ffffffffc02068f0 <commands+0x868>
ffffffffc02036e6:	08100593          	li	a1,129
ffffffffc02036ea:	00004517          	auipc	a0,0x4
ffffffffc02036ee:	d3e50513          	addi	a0,a0,-706 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc02036f2:	da1fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02036f6 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02036f6:	591c                	lw	a5,48(a0)
{
ffffffffc02036f8:	1141                	addi	sp,sp,-16
ffffffffc02036fa:	e406                	sd	ra,8(sp)
ffffffffc02036fc:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02036fe:	e78d                	bnez	a5,ffffffffc0203728 <mm_destroy+0x32>
ffffffffc0203700:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203702:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203704:	00a40c63          	beq	s0,a0,ffffffffc020371c <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203708:	6118                	ld	a4,0(a0)
ffffffffc020370a:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020370c:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc020370e:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203710:	e398                	sd	a4,0(a5)
ffffffffc0203712:	e1cfe0ef          	jal	ra,ffffffffc0201d2e <kfree>
    return listelm->next;
ffffffffc0203716:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203718:	fea418e3          	bne	s0,a0,ffffffffc0203708 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc020371c:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc020371e:	6402                	ld	s0,0(sp)
ffffffffc0203720:	60a2                	ld	ra,8(sp)
ffffffffc0203722:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203724:	e0afe06f          	j	ffffffffc0201d2e <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203728:	00004697          	auipc	a3,0x4
ffffffffc020372c:	d7068693          	addi	a3,a3,-656 # ffffffffc0207498 <default_pmm_manager+0x7f8>
ffffffffc0203730:	00003617          	auipc	a2,0x3
ffffffffc0203734:	1c060613          	addi	a2,a2,448 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203738:	0ad00593          	li	a1,173
ffffffffc020373c:	00004517          	auipc	a0,0x4
ffffffffc0203740:	cec50513          	addi	a0,a0,-788 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc0203744:	d4ffc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203748 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203748:	7139                	addi	sp,sp,-64
ffffffffc020374a:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020374c:	6405                	lui	s0,0x1
ffffffffc020374e:	147d                	addi	s0,s0,-1
ffffffffc0203750:	77fd                	lui	a5,0xfffff
ffffffffc0203752:	9622                	add	a2,a2,s0
ffffffffc0203754:	962e                	add	a2,a2,a1
{
ffffffffc0203756:	f426                	sd	s1,40(sp)
ffffffffc0203758:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020375a:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc020375e:	f04a                	sd	s2,32(sp)
ffffffffc0203760:	ec4e                	sd	s3,24(sp)
ffffffffc0203762:	e852                	sd	s4,16(sp)
ffffffffc0203764:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203766:	002005b7          	lui	a1,0x200
ffffffffc020376a:	00f67433          	and	s0,a2,a5
ffffffffc020376e:	06b4e363          	bltu	s1,a1,ffffffffc02037d4 <mm_map+0x8c>
ffffffffc0203772:	0684f163          	bgeu	s1,s0,ffffffffc02037d4 <mm_map+0x8c>
ffffffffc0203776:	4785                	li	a5,1
ffffffffc0203778:	07fe                	slli	a5,a5,0x1f
ffffffffc020377a:	0487ed63          	bltu	a5,s0,ffffffffc02037d4 <mm_map+0x8c>
ffffffffc020377e:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203780:	cd21                	beqz	a0,ffffffffc02037d8 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203782:	85a6                	mv	a1,s1
ffffffffc0203784:	8ab6                	mv	s5,a3
ffffffffc0203786:	8a3a                	mv	s4,a4
ffffffffc0203788:	e5fff0ef          	jal	ra,ffffffffc02035e6 <find_vma>
ffffffffc020378c:	c501                	beqz	a0,ffffffffc0203794 <mm_map+0x4c>
ffffffffc020378e:	651c                	ld	a5,8(a0)
ffffffffc0203790:	0487e263          	bltu	a5,s0,ffffffffc02037d4 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203794:	03000513          	li	a0,48
ffffffffc0203798:	ce6fe0ef          	jal	ra,ffffffffc0201c7e <kmalloc>
ffffffffc020379c:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc020379e:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc02037a0:	02090163          	beqz	s2,ffffffffc02037c2 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02037a4:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02037a6:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc02037aa:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02037ae:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02037b2:	85ca                	mv	a1,s2
ffffffffc02037b4:	e73ff0ef          	jal	ra,ffffffffc0203626 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc02037b8:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc02037ba:	000a0463          	beqz	s4,ffffffffc02037c2 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02037be:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f40>

out:
    return ret;
}
ffffffffc02037c2:	70e2                	ld	ra,56(sp)
ffffffffc02037c4:	7442                	ld	s0,48(sp)
ffffffffc02037c6:	74a2                	ld	s1,40(sp)
ffffffffc02037c8:	7902                	ld	s2,32(sp)
ffffffffc02037ca:	69e2                	ld	s3,24(sp)
ffffffffc02037cc:	6a42                	ld	s4,16(sp)
ffffffffc02037ce:	6aa2                	ld	s5,8(sp)
ffffffffc02037d0:	6121                	addi	sp,sp,64
ffffffffc02037d2:	8082                	ret
        return -E_INVAL;
ffffffffc02037d4:	5575                	li	a0,-3
ffffffffc02037d6:	b7f5                	j	ffffffffc02037c2 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02037d8:	00004697          	auipc	a3,0x4
ffffffffc02037dc:	cd868693          	addi	a3,a3,-808 # ffffffffc02074b0 <default_pmm_manager+0x810>
ffffffffc02037e0:	00003617          	auipc	a2,0x3
ffffffffc02037e4:	11060613          	addi	a2,a2,272 # ffffffffc02068f0 <commands+0x868>
ffffffffc02037e8:	0c200593          	li	a1,194
ffffffffc02037ec:	00004517          	auipc	a0,0x4
ffffffffc02037f0:	c3c50513          	addi	a0,a0,-964 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc02037f4:	c9ffc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02037f8 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02037f8:	7139                	addi	sp,sp,-64
ffffffffc02037fa:	fc06                	sd	ra,56(sp)
ffffffffc02037fc:	f822                	sd	s0,48(sp)
ffffffffc02037fe:	f426                	sd	s1,40(sp)
ffffffffc0203800:	f04a                	sd	s2,32(sp)
ffffffffc0203802:	ec4e                	sd	s3,24(sp)
ffffffffc0203804:	e852                	sd	s4,16(sp)
ffffffffc0203806:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203808:	c52d                	beqz	a0,ffffffffc0203872 <dup_mmap+0x7a>
ffffffffc020380a:	892a                	mv	s2,a0
ffffffffc020380c:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc020380e:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203810:	e595                	bnez	a1,ffffffffc020383c <dup_mmap+0x44>
ffffffffc0203812:	a085                	j	ffffffffc0203872 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203814:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203816:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_matrix_out_size+0x1f38f8>
        vma->vm_end = vm_end;
ffffffffc020381a:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc020381e:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203822:	e05ff0ef          	jal	ra,ffffffffc0203626 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203826:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8f50>
ffffffffc020382a:	fe843603          	ld	a2,-24(s0)
ffffffffc020382e:	6c8c                	ld	a1,24(s1)
ffffffffc0203830:	01893503          	ld	a0,24(s2)
ffffffffc0203834:	4701                	li	a4,0
ffffffffc0203836:	b05ff0ef          	jal	ra,ffffffffc020333a <copy_range>
ffffffffc020383a:	e105                	bnez	a0,ffffffffc020385a <dup_mmap+0x62>
    return listelm->prev;
ffffffffc020383c:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc020383e:	02848863          	beq	s1,s0,ffffffffc020386e <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203842:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203846:	fe843a83          	ld	s5,-24(s0)
ffffffffc020384a:	ff043a03          	ld	s4,-16(s0)
ffffffffc020384e:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203852:	c2cfe0ef          	jal	ra,ffffffffc0201c7e <kmalloc>
ffffffffc0203856:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203858:	fd55                	bnez	a0,ffffffffc0203814 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc020385a:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc020385c:	70e2                	ld	ra,56(sp)
ffffffffc020385e:	7442                	ld	s0,48(sp)
ffffffffc0203860:	74a2                	ld	s1,40(sp)
ffffffffc0203862:	7902                	ld	s2,32(sp)
ffffffffc0203864:	69e2                	ld	s3,24(sp)
ffffffffc0203866:	6a42                	ld	s4,16(sp)
ffffffffc0203868:	6aa2                	ld	s5,8(sp)
ffffffffc020386a:	6121                	addi	sp,sp,64
ffffffffc020386c:	8082                	ret
    return 0;
ffffffffc020386e:	4501                	li	a0,0
ffffffffc0203870:	b7f5                	j	ffffffffc020385c <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203872:	00004697          	auipc	a3,0x4
ffffffffc0203876:	c4e68693          	addi	a3,a3,-946 # ffffffffc02074c0 <default_pmm_manager+0x820>
ffffffffc020387a:	00003617          	auipc	a2,0x3
ffffffffc020387e:	07660613          	addi	a2,a2,118 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203882:	0de00593          	li	a1,222
ffffffffc0203886:	00004517          	auipc	a0,0x4
ffffffffc020388a:	ba250513          	addi	a0,a0,-1118 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc020388e:	c05fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203892 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203892:	1101                	addi	sp,sp,-32
ffffffffc0203894:	ec06                	sd	ra,24(sp)
ffffffffc0203896:	e822                	sd	s0,16(sp)
ffffffffc0203898:	e426                	sd	s1,8(sp)
ffffffffc020389a:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc020389c:	c531                	beqz	a0,ffffffffc02038e8 <exit_mmap+0x56>
ffffffffc020389e:	591c                	lw	a5,48(a0)
ffffffffc02038a0:	84aa                	mv	s1,a0
ffffffffc02038a2:	e3b9                	bnez	a5,ffffffffc02038e8 <exit_mmap+0x56>
    return listelm->next;
ffffffffc02038a4:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02038a6:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc02038aa:	02850663          	beq	a0,s0,ffffffffc02038d6 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02038ae:	ff043603          	ld	a2,-16(s0)
ffffffffc02038b2:	fe843583          	ld	a1,-24(s0)
ffffffffc02038b6:	854a                	mv	a0,s2
ffffffffc02038b8:	8d9fe0ef          	jal	ra,ffffffffc0202190 <unmap_range>
ffffffffc02038bc:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02038be:	fe8498e3          	bne	s1,s0,ffffffffc02038ae <exit_mmap+0x1c>
ffffffffc02038c2:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02038c4:	00848c63          	beq	s1,s0,ffffffffc02038dc <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02038c8:	ff043603          	ld	a2,-16(s0)
ffffffffc02038cc:	fe843583          	ld	a1,-24(s0)
ffffffffc02038d0:	854a                	mv	a0,s2
ffffffffc02038d2:	a05fe0ef          	jal	ra,ffffffffc02022d6 <exit_range>
ffffffffc02038d6:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02038d8:	fe8498e3          	bne	s1,s0,ffffffffc02038c8 <exit_mmap+0x36>
    }
}
ffffffffc02038dc:	60e2                	ld	ra,24(sp)
ffffffffc02038de:	6442                	ld	s0,16(sp)
ffffffffc02038e0:	64a2                	ld	s1,8(sp)
ffffffffc02038e2:	6902                	ld	s2,0(sp)
ffffffffc02038e4:	6105                	addi	sp,sp,32
ffffffffc02038e6:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02038e8:	00004697          	auipc	a3,0x4
ffffffffc02038ec:	bf868693          	addi	a3,a3,-1032 # ffffffffc02074e0 <default_pmm_manager+0x840>
ffffffffc02038f0:	00003617          	auipc	a2,0x3
ffffffffc02038f4:	00060613          	mv	a2,a2
ffffffffc02038f8:	0f700593          	li	a1,247
ffffffffc02038fc:	00004517          	auipc	a0,0x4
ffffffffc0203900:	b2c50513          	addi	a0,a0,-1236 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc0203904:	b8ffc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203908 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203908:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020390a:	04000513          	li	a0,64
{
ffffffffc020390e:	fc06                	sd	ra,56(sp)
ffffffffc0203910:	f822                	sd	s0,48(sp)
ffffffffc0203912:	f426                	sd	s1,40(sp)
ffffffffc0203914:	f04a                	sd	s2,32(sp)
ffffffffc0203916:	ec4e                	sd	s3,24(sp)
ffffffffc0203918:	e852                	sd	s4,16(sp)
ffffffffc020391a:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020391c:	b62fe0ef          	jal	ra,ffffffffc0201c7e <kmalloc>
    if (mm != NULL)
ffffffffc0203920:	2e050663          	beqz	a0,ffffffffc0203c0c <vmm_init+0x304>
ffffffffc0203924:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203926:	e508                	sd	a0,8(a0)
ffffffffc0203928:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020392a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020392e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203932:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203936:	02053423          	sd	zero,40(a0)
ffffffffc020393a:	02052823          	sw	zero,48(a0)
ffffffffc020393e:	02053c23          	sd	zero,56(a0)
ffffffffc0203942:	03200413          	li	s0,50
ffffffffc0203946:	a811                	j	ffffffffc020395a <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203948:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc020394a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020394c:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203950:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203952:	8526                	mv	a0,s1
ffffffffc0203954:	cd3ff0ef          	jal	ra,ffffffffc0203626 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203958:	c80d                	beqz	s0,ffffffffc020398a <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020395a:	03000513          	li	a0,48
ffffffffc020395e:	b20fe0ef          	jal	ra,ffffffffc0201c7e <kmalloc>
ffffffffc0203962:	85aa                	mv	a1,a0
ffffffffc0203964:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203968:	f165                	bnez	a0,ffffffffc0203948 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc020396a:	00004697          	auipc	a3,0x4
ffffffffc020396e:	d0e68693          	addi	a3,a3,-754 # ffffffffc0207678 <default_pmm_manager+0x9d8>
ffffffffc0203972:	00003617          	auipc	a2,0x3
ffffffffc0203976:	f7e60613          	addi	a2,a2,-130 # ffffffffc02068f0 <commands+0x868>
ffffffffc020397a:	13b00593          	li	a1,315
ffffffffc020397e:	00004517          	auipc	a0,0x4
ffffffffc0203982:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc0203986:	b0dfc0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc020398a:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc020398e:	1f900913          	li	s2,505
ffffffffc0203992:	a819                	j	ffffffffc02039a8 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203994:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203996:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203998:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc020399c:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020399e:	8526                	mv	a0,s1
ffffffffc02039a0:	c87ff0ef          	jal	ra,ffffffffc0203626 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02039a4:	03240a63          	beq	s0,s2,ffffffffc02039d8 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02039a8:	03000513          	li	a0,48
ffffffffc02039ac:	ad2fe0ef          	jal	ra,ffffffffc0201c7e <kmalloc>
ffffffffc02039b0:	85aa                	mv	a1,a0
ffffffffc02039b2:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc02039b6:	fd79                	bnez	a0,ffffffffc0203994 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc02039b8:	00004697          	auipc	a3,0x4
ffffffffc02039bc:	cc068693          	addi	a3,a3,-832 # ffffffffc0207678 <default_pmm_manager+0x9d8>
ffffffffc02039c0:	00003617          	auipc	a2,0x3
ffffffffc02039c4:	f3060613          	addi	a2,a2,-208 # ffffffffc02068f0 <commands+0x868>
ffffffffc02039c8:	14200593          	li	a1,322
ffffffffc02039cc:	00004517          	auipc	a0,0x4
ffffffffc02039d0:	a5c50513          	addi	a0,a0,-1444 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc02039d4:	abffc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return listelm->next;
ffffffffc02039d8:	649c                	ld	a5,8(s1)
ffffffffc02039da:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc02039dc:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc02039e0:	16f48663          	beq	s1,a5,ffffffffc0203b4c <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02039e4:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd383d8>
ffffffffc02039e8:	ffe70693          	addi	a3,a4,-2 # ffe <_binary_obj___user_faultread_out_size-0x8f42>
ffffffffc02039ec:	10d61063          	bne	a2,a3,ffffffffc0203aec <vmm_init+0x1e4>
ffffffffc02039f0:	ff07b683          	ld	a3,-16(a5)
ffffffffc02039f4:	0ed71c63          	bne	a4,a3,ffffffffc0203aec <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc02039f8:	0715                	addi	a4,a4,5
ffffffffc02039fa:	679c                	ld	a5,8(a5)
ffffffffc02039fc:	feb712e3          	bne	a4,a1,ffffffffc02039e0 <vmm_init+0xd8>
ffffffffc0203a00:	4a1d                	li	s4,7
ffffffffc0203a02:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203a04:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203a08:	85a2                	mv	a1,s0
ffffffffc0203a0a:	8526                	mv	a0,s1
ffffffffc0203a0c:	bdbff0ef          	jal	ra,ffffffffc02035e6 <find_vma>
ffffffffc0203a10:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203a12:	16050d63          	beqz	a0,ffffffffc0203b8c <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203a16:	00140593          	addi	a1,s0,1
ffffffffc0203a1a:	8526                	mv	a0,s1
ffffffffc0203a1c:	bcbff0ef          	jal	ra,ffffffffc02035e6 <find_vma>
ffffffffc0203a20:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203a22:	14050563          	beqz	a0,ffffffffc0203b6c <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203a26:	85d2                	mv	a1,s4
ffffffffc0203a28:	8526                	mv	a0,s1
ffffffffc0203a2a:	bbdff0ef          	jal	ra,ffffffffc02035e6 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203a2e:	16051f63          	bnez	a0,ffffffffc0203bac <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203a32:	00340593          	addi	a1,s0,3
ffffffffc0203a36:	8526                	mv	a0,s1
ffffffffc0203a38:	bafff0ef          	jal	ra,ffffffffc02035e6 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203a3c:	1a051863          	bnez	a0,ffffffffc0203bec <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203a40:	00440593          	addi	a1,s0,4
ffffffffc0203a44:	8526                	mv	a0,s1
ffffffffc0203a46:	ba1ff0ef          	jal	ra,ffffffffc02035e6 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203a4a:	18051163          	bnez	a0,ffffffffc0203bcc <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203a4e:	00893783          	ld	a5,8(s2)
ffffffffc0203a52:	0a879d63          	bne	a5,s0,ffffffffc0203b0c <vmm_init+0x204>
ffffffffc0203a56:	01093783          	ld	a5,16(s2)
ffffffffc0203a5a:	0b479963          	bne	a5,s4,ffffffffc0203b0c <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203a5e:	0089b783          	ld	a5,8(s3)
ffffffffc0203a62:	0c879563          	bne	a5,s0,ffffffffc0203b2c <vmm_init+0x224>
ffffffffc0203a66:	0109b783          	ld	a5,16(s3)
ffffffffc0203a6a:	0d479163          	bne	a5,s4,ffffffffc0203b2c <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203a6e:	0415                	addi	s0,s0,5
ffffffffc0203a70:	0a15                	addi	s4,s4,5
ffffffffc0203a72:	f9541be3          	bne	s0,s5,ffffffffc0203a08 <vmm_init+0x100>
ffffffffc0203a76:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203a78:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203a7a:	85a2                	mv	a1,s0
ffffffffc0203a7c:	8526                	mv	a0,s1
ffffffffc0203a7e:	b69ff0ef          	jal	ra,ffffffffc02035e6 <find_vma>
ffffffffc0203a82:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203a86:	c90d                	beqz	a0,ffffffffc0203ab8 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203a88:	6914                	ld	a3,16(a0)
ffffffffc0203a8a:	6510                	ld	a2,8(a0)
ffffffffc0203a8c:	00004517          	auipc	a0,0x4
ffffffffc0203a90:	b7450513          	addi	a0,a0,-1164 # ffffffffc0207600 <default_pmm_manager+0x960>
ffffffffc0203a94:	f04fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203a98:	00004697          	auipc	a3,0x4
ffffffffc0203a9c:	b9068693          	addi	a3,a3,-1136 # ffffffffc0207628 <default_pmm_manager+0x988>
ffffffffc0203aa0:	00003617          	auipc	a2,0x3
ffffffffc0203aa4:	e5060613          	addi	a2,a2,-432 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203aa8:	16800593          	li	a1,360
ffffffffc0203aac:	00004517          	auipc	a0,0x4
ffffffffc0203ab0:	97c50513          	addi	a0,a0,-1668 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc0203ab4:	9dffc0ef          	jal	ra,ffffffffc0200492 <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203ab8:	147d                	addi	s0,s0,-1
ffffffffc0203aba:	fd2410e3          	bne	s0,s2,ffffffffc0203a7a <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203abe:	8526                	mv	a0,s1
ffffffffc0203ac0:	c37ff0ef          	jal	ra,ffffffffc02036f6 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203ac4:	00004517          	auipc	a0,0x4
ffffffffc0203ac8:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0207640 <default_pmm_manager+0x9a0>
ffffffffc0203acc:	eccfc0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0203ad0:	7442                	ld	s0,48(sp)
ffffffffc0203ad2:	70e2                	ld	ra,56(sp)
ffffffffc0203ad4:	74a2                	ld	s1,40(sp)
ffffffffc0203ad6:	7902                	ld	s2,32(sp)
ffffffffc0203ad8:	69e2                	ld	s3,24(sp)
ffffffffc0203ada:	6a42                	ld	s4,16(sp)
ffffffffc0203adc:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203ade:	00004517          	auipc	a0,0x4
ffffffffc0203ae2:	b8250513          	addi	a0,a0,-1150 # ffffffffc0207660 <default_pmm_manager+0x9c0>
}
ffffffffc0203ae6:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203ae8:	eb0fc06f          	j	ffffffffc0200198 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203aec:	00004697          	auipc	a3,0x4
ffffffffc0203af0:	a2c68693          	addi	a3,a3,-1492 # ffffffffc0207518 <default_pmm_manager+0x878>
ffffffffc0203af4:	00003617          	auipc	a2,0x3
ffffffffc0203af8:	dfc60613          	addi	a2,a2,-516 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203afc:	14c00593          	li	a1,332
ffffffffc0203b00:	00004517          	auipc	a0,0x4
ffffffffc0203b04:	92850513          	addi	a0,a0,-1752 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc0203b08:	98bfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b0c:	00004697          	auipc	a3,0x4
ffffffffc0203b10:	a9468693          	addi	a3,a3,-1388 # ffffffffc02075a0 <default_pmm_manager+0x900>
ffffffffc0203b14:	00003617          	auipc	a2,0x3
ffffffffc0203b18:	ddc60613          	addi	a2,a2,-548 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203b1c:	15d00593          	li	a1,349
ffffffffc0203b20:	00004517          	auipc	a0,0x4
ffffffffc0203b24:	90850513          	addi	a0,a0,-1784 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc0203b28:	96bfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b2c:	00004697          	auipc	a3,0x4
ffffffffc0203b30:	aa468693          	addi	a3,a3,-1372 # ffffffffc02075d0 <default_pmm_manager+0x930>
ffffffffc0203b34:	00003617          	auipc	a2,0x3
ffffffffc0203b38:	dbc60613          	addi	a2,a2,-580 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203b3c:	15e00593          	li	a1,350
ffffffffc0203b40:	00004517          	auipc	a0,0x4
ffffffffc0203b44:	8e850513          	addi	a0,a0,-1816 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc0203b48:	94bfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203b4c:	00004697          	auipc	a3,0x4
ffffffffc0203b50:	9b468693          	addi	a3,a3,-1612 # ffffffffc0207500 <default_pmm_manager+0x860>
ffffffffc0203b54:	00003617          	auipc	a2,0x3
ffffffffc0203b58:	d9c60613          	addi	a2,a2,-612 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203b5c:	14a00593          	li	a1,330
ffffffffc0203b60:	00004517          	auipc	a0,0x4
ffffffffc0203b64:	8c850513          	addi	a0,a0,-1848 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc0203b68:	92bfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2 != NULL);
ffffffffc0203b6c:	00004697          	auipc	a3,0x4
ffffffffc0203b70:	9f468693          	addi	a3,a3,-1548 # ffffffffc0207560 <default_pmm_manager+0x8c0>
ffffffffc0203b74:	00003617          	auipc	a2,0x3
ffffffffc0203b78:	d7c60613          	addi	a2,a2,-644 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203b7c:	15500593          	li	a1,341
ffffffffc0203b80:	00004517          	auipc	a0,0x4
ffffffffc0203b84:	8a850513          	addi	a0,a0,-1880 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc0203b88:	90bfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1 != NULL);
ffffffffc0203b8c:	00004697          	auipc	a3,0x4
ffffffffc0203b90:	9c468693          	addi	a3,a3,-1596 # ffffffffc0207550 <default_pmm_manager+0x8b0>
ffffffffc0203b94:	00003617          	auipc	a2,0x3
ffffffffc0203b98:	d5c60613          	addi	a2,a2,-676 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203b9c:	15300593          	li	a1,339
ffffffffc0203ba0:	00004517          	auipc	a0,0x4
ffffffffc0203ba4:	88850513          	addi	a0,a0,-1912 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc0203ba8:	8ebfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma3 == NULL);
ffffffffc0203bac:	00004697          	auipc	a3,0x4
ffffffffc0203bb0:	9c468693          	addi	a3,a3,-1596 # ffffffffc0207570 <default_pmm_manager+0x8d0>
ffffffffc0203bb4:	00003617          	auipc	a2,0x3
ffffffffc0203bb8:	d3c60613          	addi	a2,a2,-708 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203bbc:	15700593          	li	a1,343
ffffffffc0203bc0:	00004517          	auipc	a0,0x4
ffffffffc0203bc4:	86850513          	addi	a0,a0,-1944 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc0203bc8:	8cbfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma5 == NULL);
ffffffffc0203bcc:	00004697          	auipc	a3,0x4
ffffffffc0203bd0:	9c468693          	addi	a3,a3,-1596 # ffffffffc0207590 <default_pmm_manager+0x8f0>
ffffffffc0203bd4:	00003617          	auipc	a2,0x3
ffffffffc0203bd8:	d1c60613          	addi	a2,a2,-740 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203bdc:	15b00593          	li	a1,347
ffffffffc0203be0:	00004517          	auipc	a0,0x4
ffffffffc0203be4:	84850513          	addi	a0,a0,-1976 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc0203be8:	8abfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma4 == NULL);
ffffffffc0203bec:	00004697          	auipc	a3,0x4
ffffffffc0203bf0:	99468693          	addi	a3,a3,-1644 # ffffffffc0207580 <default_pmm_manager+0x8e0>
ffffffffc0203bf4:	00003617          	auipc	a2,0x3
ffffffffc0203bf8:	cfc60613          	addi	a2,a2,-772 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203bfc:	15900593          	li	a1,345
ffffffffc0203c00:	00004517          	auipc	a0,0x4
ffffffffc0203c04:	82850513          	addi	a0,a0,-2008 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc0203c08:	88bfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(mm != NULL);
ffffffffc0203c0c:	00004697          	auipc	a3,0x4
ffffffffc0203c10:	8a468693          	addi	a3,a3,-1884 # ffffffffc02074b0 <default_pmm_manager+0x810>
ffffffffc0203c14:	00003617          	auipc	a2,0x3
ffffffffc0203c18:	cdc60613          	addi	a2,a2,-804 # ffffffffc02068f0 <commands+0x868>
ffffffffc0203c1c:	13300593          	li	a1,307
ffffffffc0203c20:	00004517          	auipc	a0,0x4
ffffffffc0203c24:	80850513          	addi	a0,a0,-2040 # ffffffffc0207428 <default_pmm_manager+0x788>
ffffffffc0203c28:	86bfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203c2c <do_pgfault>:
}

// do_pgfault - handler of page fault, including demand allocation and COW
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
    pgfault_num++;
ffffffffc0203c2c:	000c3797          	auipc	a5,0xc3
ffffffffc0203c30:	fac7a783          	lw	a5,-84(a5) # ffffffffc02c6bd8 <pgfault_num>
ffffffffc0203c34:	2785                	addiw	a5,a5,1
ffffffffc0203c36:	000c3717          	auipc	a4,0xc3
ffffffffc0203c3a:	faf72123          	sw	a5,-94(a4) # ffffffffc02c6bd8 <pgfault_num>

    if (mm == NULL)
ffffffffc0203c3e:	16050663          	beqz	a0,ffffffffc0203daa <do_pgfault+0x17e>
{
ffffffffc0203c42:	715d                	addi	sp,sp,-80
ffffffffc0203c44:	f44e                	sd	s3,40(sp)
ffffffffc0203c46:	89ae                	mv	s3,a1
    {
        return -E_INVAL;
    }

    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203c48:	85b2                	mv	a1,a2
{
ffffffffc0203c4a:	e0a2                	sd	s0,64(sp)
ffffffffc0203c4c:	fc26                	sd	s1,56(sp)
ffffffffc0203c4e:	f84a                	sd	s2,48(sp)
ffffffffc0203c50:	e486                	sd	ra,72(sp)
ffffffffc0203c52:	f052                	sd	s4,32(sp)
ffffffffc0203c54:	ec56                	sd	s5,24(sp)
ffffffffc0203c56:	e85a                	sd	s6,16(sp)
ffffffffc0203c58:	e45e                	sd	s7,8(sp)
ffffffffc0203c5a:	84aa                	mv	s1,a0
ffffffffc0203c5c:	8432                	mv	s0,a2
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203c5e:	989ff0ef          	jal	ra,ffffffffc02035e6 <find_vma>
ffffffffc0203c62:	892a                	mv	s2,a0
    if (vma == NULL || addr < vma->vm_start)
ffffffffc0203c64:	12050f63          	beqz	a0,ffffffffc0203da2 <do_pgfault+0x176>
ffffffffc0203c68:	651c                	ld	a5,8(a0)
ffffffffc0203c6a:	12f46c63          	bltu	s0,a5,ffffffffc0203da2 <do_pgfault+0x176>
    {
        return -E_INVAL;
    }

    bool write = (error_code & 0x2) != 0;
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203c6e:	75fd                	lui	a1,0xfffff
    pte_t *ptep = get_pte(mm->pgdir, la, 0);
ffffffffc0203c70:	6c88                	ld	a0,24(s1)
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203c72:	8c6d                	and	s0,s0,a1
    pte_t *ptep = get_pte(mm->pgdir, la, 0);
ffffffffc0203c74:	4601                	li	a2,0
ffffffffc0203c76:	85a2                	mv	a1,s0
ffffffffc0203c78:	a9cfe0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc0203c7c:	87aa                	mv	a5,a0

    if (ptep == NULL || !(*ptep & PTE_V))
ffffffffc0203c7e:	c569                	beqz	a0,ffffffffc0203d48 <do_pgfault+0x11c>
ffffffffc0203c80:	00053a03          	ld	s4,0(a0)
ffffffffc0203c84:	001a7713          	andi	a4,s4,1
ffffffffc0203c88:	c361                	beqz	a4,ffffffffc0203d48 <do_pgfault+0x11c>
            return -E_NO_MEM;
        }
        return 0;
    }

    if (write && (*ptep & PTE_COW))
ffffffffc0203c8a:	0029f593          	andi	a1,s3,2
ffffffffc0203c8e:	10058a63          	beqz	a1,ffffffffc0203da2 <do_pgfault+0x176>
ffffffffc0203c92:	100a7713          	andi	a4,s4,256
ffffffffc0203c96:	10070663          	beqz	a4,ffffffffc0203da2 <do_pgfault+0x176>
    if (PPN(pa) >= npage)
ffffffffc0203c9a:	000c3b17          	auipc	s6,0xc3
ffffffffc0203c9e:	f1eb0b13          	addi	s6,s6,-226 # ffffffffc02c6bb8 <npage>
ffffffffc0203ca2:	000b3683          	ld	a3,0(s6)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203ca6:	002a1713          	slli	a4,s4,0x2
ffffffffc0203caa:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0203cac:	10d77163          	bgeu	a4,a3,ffffffffc0203dae <do_pgfault+0x182>
    return &pages[PPN(pa) - nbase];
ffffffffc0203cb0:	000c3b97          	auipc	s7,0xc3
ffffffffc0203cb4:	f10b8b93          	addi	s7,s7,-240 # ffffffffc02c6bc0 <pages>
ffffffffc0203cb8:	000bb903          	ld	s2,0(s7)
ffffffffc0203cbc:	00005a97          	auipc	s5,0x5
ffffffffc0203cc0:	a04aba83          	ld	s5,-1532(s5) # ffffffffc02086c0 <nbase>
ffffffffc0203cc4:	41570733          	sub	a4,a4,s5
ffffffffc0203cc8:	071a                	slli	a4,a4,0x6
ffffffffc0203cca:	993a                	add	s2,s2,a4
    {
        uint32_t perm = (*ptep & PTE_USER);
        struct Page *page = pte2page(*ptep);

        if (page_ref(page) > 1)
ffffffffc0203ccc:	00092683          	lw	a3,0(s2)
ffffffffc0203cd0:	4705                	li	a4,1
ffffffffc0203cd2:	0ad75d63          	bge	a4,a3,ffffffffc0203d8c <do_pgfault+0x160>
        {
            struct Page *npage = alloc_page();
ffffffffc0203cd6:	4505                	li	a0,1
ffffffffc0203cd8:	984fe0ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0203cdc:	89aa                	mv	s3,a0
            if (npage == NULL)
ffffffffc0203cde:	c561                	beqz	a0,ffffffffc0203da6 <do_pgfault+0x17a>
    return page - pages + nbase;
ffffffffc0203ce0:	000bb683          	ld	a3,0(s7)
    return KADDR(page2pa(page));
ffffffffc0203ce4:	577d                	li	a4,-1
ffffffffc0203ce6:	000b3603          	ld	a2,0(s6)
    return page - pages + nbase;
ffffffffc0203cea:	40d507b3          	sub	a5,a0,a3
ffffffffc0203cee:	8799                	srai	a5,a5,0x6
ffffffffc0203cf0:	97d6                	add	a5,a5,s5
    return KADDR(page2pa(page));
ffffffffc0203cf2:	8331                	srli	a4,a4,0xc
ffffffffc0203cf4:	00e7f5b3          	and	a1,a5,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0203cf8:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203cfa:	0cc5f663          	bgeu	a1,a2,ffffffffc0203dc6 <do_pgfault+0x19a>
    return page - pages + nbase;
ffffffffc0203cfe:	40d906b3          	sub	a3,s2,a3
ffffffffc0203d02:	8699                	srai	a3,a3,0x6
ffffffffc0203d04:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc0203d06:	000c3597          	auipc	a1,0xc3
ffffffffc0203d0a:	eca5b583          	ld	a1,-310(a1) # ffffffffc02c6bd0 <va_pa_offset>
ffffffffc0203d0e:	8f75                	and	a4,a4,a3
ffffffffc0203d10:	00b78533          	add	a0,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0203d14:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203d16:	0cc77563          	bgeu	a4,a2,ffffffffc0203de0 <do_pgfault+0x1b4>
            {
                return -E_NO_MEM;
            }
            memcpy(page2kva(npage), page2kva(page), PGSIZE);
ffffffffc0203d1a:	95b6                	add	a1,a1,a3
ffffffffc0203d1c:	6605                	lui	a2,0x1
ffffffffc0203d1e:	0e4020ef          	jal	ra,ffffffffc0205e02 <memcpy>
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203d22:	8622                	mv	a2,s0
        tlb_invalidate(mm->pgdir, la);
        return 0;
    }

    return -E_INVAL;
}
ffffffffc0203d24:	6406                	ld	s0,64(sp)
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203d26:	6c88                	ld	a0,24(s1)
}
ffffffffc0203d28:	60a6                	ld	ra,72(sp)
ffffffffc0203d2a:	74e2                	ld	s1,56(sp)
ffffffffc0203d2c:	7942                	ld	s2,48(sp)
ffffffffc0203d2e:	6ae2                	ld	s5,24(sp)
ffffffffc0203d30:	6b42                	ld	s6,16(sp)
ffffffffc0203d32:	6ba2                	ld	s7,8(sp)
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203d34:	01ba7693          	andi	a3,s4,27
ffffffffc0203d38:	85ce                	mv	a1,s3
}
ffffffffc0203d3a:	7a02                	ld	s4,32(sp)
ffffffffc0203d3c:	79a2                	ld	s3,40(sp)
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203d3e:	0046e693          	ori	a3,a3,4
}
ffffffffc0203d42:	6161                	addi	sp,sp,80
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203d44:	8c1fe06f          	j	ffffffffc0202604 <page_insert>
        uint32_t perm = perm_from_flags(vma->vm_flags);
ffffffffc0203d48:	01892783          	lw	a5,24(s2)
    uint32_t perm = PTE_U;
ffffffffc0203d4c:	4641                	li	a2,16
    if (vm_flags & VM_READ)
ffffffffc0203d4e:	0017f713          	andi	a4,a5,1
ffffffffc0203d52:	c311                	beqz	a4,ffffffffc0203d56 <do_pgfault+0x12a>
        perm |= PTE_R;
ffffffffc0203d54:	4649                	li	a2,18
    if (vm_flags & VM_WRITE)
ffffffffc0203d56:	0027f713          	andi	a4,a5,2
ffffffffc0203d5a:	c311                	beqz	a4,ffffffffc0203d5e <do_pgfault+0x132>
        perm |= PTE_W | PTE_R;
ffffffffc0203d5c:	4659                	li	a2,22
    if (vm_flags & VM_EXEC)
ffffffffc0203d5e:	8b91                	andi	a5,a5,4
ffffffffc0203d60:	e39d                	bnez	a5,ffffffffc0203d86 <do_pgfault+0x15a>
        if (pgdir_alloc_page(mm->pgdir, la, perm) == NULL)
ffffffffc0203d62:	6c88                	ld	a0,24(s1)
ffffffffc0203d64:	85a2                	mv	a1,s0
ffffffffc0203d66:	f6aff0ef          	jal	ra,ffffffffc02034d0 <pgdir_alloc_page>
ffffffffc0203d6a:	87aa                	mv	a5,a0
        return 0;
ffffffffc0203d6c:	4501                	li	a0,0
        if (pgdir_alloc_page(mm->pgdir, la, perm) == NULL)
ffffffffc0203d6e:	cf85                	beqz	a5,ffffffffc0203da6 <do_pgfault+0x17a>
}
ffffffffc0203d70:	60a6                	ld	ra,72(sp)
ffffffffc0203d72:	6406                	ld	s0,64(sp)
ffffffffc0203d74:	74e2                	ld	s1,56(sp)
ffffffffc0203d76:	7942                	ld	s2,48(sp)
ffffffffc0203d78:	79a2                	ld	s3,40(sp)
ffffffffc0203d7a:	7a02                	ld	s4,32(sp)
ffffffffc0203d7c:	6ae2                	ld	s5,24(sp)
ffffffffc0203d7e:	6b42                	ld	s6,16(sp)
ffffffffc0203d80:	6ba2                	ld	s7,8(sp)
ffffffffc0203d82:	6161                	addi	sp,sp,80
ffffffffc0203d84:	8082                	ret
        perm |= PTE_X;
ffffffffc0203d86:	00866613          	ori	a2,a2,8
ffffffffc0203d8a:	bfe1                	j	ffffffffc0203d62 <do_pgfault+0x136>
        tlb_invalidate(mm->pgdir, la);
ffffffffc0203d8c:	6c88                	ld	a0,24(s1)
        *ptep = (*ptep | PTE_W) & ~PTE_COW;
ffffffffc0203d8e:	efba7713          	andi	a4,s4,-261
ffffffffc0203d92:	00476713          	ori	a4,a4,4
ffffffffc0203d96:	e398                	sd	a4,0(a5)
        tlb_invalidate(mm->pgdir, la);
ffffffffc0203d98:	85a2                	mv	a1,s0
ffffffffc0203d9a:	f30ff0ef          	jal	ra,ffffffffc02034ca <tlb_invalidate>
        return 0;
ffffffffc0203d9e:	4501                	li	a0,0
ffffffffc0203da0:	bfc1                	j	ffffffffc0203d70 <do_pgfault+0x144>
        return -E_INVAL;
ffffffffc0203da2:	5575                	li	a0,-3
ffffffffc0203da4:	b7f1                	j	ffffffffc0203d70 <do_pgfault+0x144>
            return -E_NO_MEM;
ffffffffc0203da6:	5571                	li	a0,-4
ffffffffc0203da8:	b7e1                	j	ffffffffc0203d70 <do_pgfault+0x144>
        return -E_INVAL;
ffffffffc0203daa:	5575                	li	a0,-3
}
ffffffffc0203dac:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0203dae:	00003617          	auipc	a2,0x3
ffffffffc0203db2:	ffa60613          	addi	a2,a2,-6 # ffffffffc0206da8 <default_pmm_manager+0x108>
ffffffffc0203db6:	06900593          	li	a1,105
ffffffffc0203dba:	00003517          	auipc	a0,0x3
ffffffffc0203dbe:	f4650513          	addi	a0,a0,-186 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc0203dc2:	ed0fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203dc6:	86be                	mv	a3,a5
ffffffffc0203dc8:	00003617          	auipc	a2,0x3
ffffffffc0203dcc:	f1060613          	addi	a2,a2,-240 # ffffffffc0206cd8 <default_pmm_manager+0x38>
ffffffffc0203dd0:	07100593          	li	a1,113
ffffffffc0203dd4:	00003517          	auipc	a0,0x3
ffffffffc0203dd8:	f2c50513          	addi	a0,a0,-212 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc0203ddc:	eb6fc0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0203de0:	00003617          	auipc	a2,0x3
ffffffffc0203de4:	ef860613          	addi	a2,a2,-264 # ffffffffc0206cd8 <default_pmm_manager+0x38>
ffffffffc0203de8:	07100593          	li	a1,113
ffffffffc0203dec:	00003517          	auipc	a0,0x3
ffffffffc0203df0:	f1450513          	addi	a0,a0,-236 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc0203df4:	e9efc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203df8 <user_mem_check>:
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203df8:	7179                	addi	sp,sp,-48
ffffffffc0203dfa:	f022                	sd	s0,32(sp)
ffffffffc0203dfc:	f406                	sd	ra,40(sp)
ffffffffc0203dfe:	ec26                	sd	s1,24(sp)
ffffffffc0203e00:	e84a                	sd	s2,16(sp)
ffffffffc0203e02:	e44e                	sd	s3,8(sp)
ffffffffc0203e04:	e052                	sd	s4,0(sp)
ffffffffc0203e06:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203e08:	c135                	beqz	a0,ffffffffc0203e6c <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203e0a:	002007b7          	lui	a5,0x200
ffffffffc0203e0e:	04f5e663          	bltu	a1,a5,ffffffffc0203e5a <user_mem_check+0x62>
ffffffffc0203e12:	00c584b3          	add	s1,a1,a2
ffffffffc0203e16:	0495f263          	bgeu	a1,s1,ffffffffc0203e5a <user_mem_check+0x62>
ffffffffc0203e1a:	4785                	li	a5,1
ffffffffc0203e1c:	07fe                	slli	a5,a5,0x1f
ffffffffc0203e1e:	0297ee63          	bltu	a5,s1,ffffffffc0203e5a <user_mem_check+0x62>
ffffffffc0203e22:	892a                	mv	s2,a0
ffffffffc0203e24:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e26:	6a05                	lui	s4,0x1
ffffffffc0203e28:	a821                	j	ffffffffc0203e40 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e2a:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e2e:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203e30:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e32:	c685                	beqz	a3,ffffffffc0203e5a <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203e34:	c399                	beqz	a5,ffffffffc0203e3a <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e36:	02e46263          	bltu	s0,a4,ffffffffc0203e5a <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203e3a:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203e3c:	04947663          	bgeu	s0,s1,ffffffffc0203e88 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203e40:	85a2                	mv	a1,s0
ffffffffc0203e42:	854a                	mv	a0,s2
ffffffffc0203e44:	fa2ff0ef          	jal	ra,ffffffffc02035e6 <find_vma>
ffffffffc0203e48:	c909                	beqz	a0,ffffffffc0203e5a <user_mem_check+0x62>
ffffffffc0203e4a:	6518                	ld	a4,8(a0)
ffffffffc0203e4c:	00e46763          	bltu	s0,a4,ffffffffc0203e5a <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e50:	4d1c                	lw	a5,24(a0)
ffffffffc0203e52:	fc099ce3          	bnez	s3,ffffffffc0203e2a <user_mem_check+0x32>
ffffffffc0203e56:	8b85                	andi	a5,a5,1
ffffffffc0203e58:	f3ed                	bnez	a5,ffffffffc0203e3a <user_mem_check+0x42>
            return 0;
ffffffffc0203e5a:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203e5c:	70a2                	ld	ra,40(sp)
ffffffffc0203e5e:	7402                	ld	s0,32(sp)
ffffffffc0203e60:	64e2                	ld	s1,24(sp)
ffffffffc0203e62:	6942                	ld	s2,16(sp)
ffffffffc0203e64:	69a2                	ld	s3,8(sp)
ffffffffc0203e66:	6a02                	ld	s4,0(sp)
ffffffffc0203e68:	6145                	addi	sp,sp,48
ffffffffc0203e6a:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e6c:	c02007b7          	lui	a5,0xc0200
ffffffffc0203e70:	4501                	li	a0,0
ffffffffc0203e72:	fef5e5e3          	bltu	a1,a5,ffffffffc0203e5c <user_mem_check+0x64>
ffffffffc0203e76:	962e                	add	a2,a2,a1
ffffffffc0203e78:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203e5c <user_mem_check+0x64>
ffffffffc0203e7c:	c8000537          	lui	a0,0xc8000
ffffffffc0203e80:	0505                	addi	a0,a0,1
ffffffffc0203e82:	00a63533          	sltu	a0,a2,a0
ffffffffc0203e86:	bfd9                	j	ffffffffc0203e5c <user_mem_check+0x64>
        return 1;
ffffffffc0203e88:	4505                	li	a0,1
ffffffffc0203e8a:	bfc9                	j	ffffffffc0203e5c <user_mem_check+0x64>

ffffffffc0203e8c <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203e8c:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203e8e:	9402                	jalr	s0

	jal do_exit
ffffffffc0203e90:	5d2000ef          	jal	ra,ffffffffc0204462 <do_exit>

ffffffffc0203e94 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203e94:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e96:	14800513          	li	a0,328
{
ffffffffc0203e9a:	e022                	sd	s0,0(sp)
ffffffffc0203e9c:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e9e:	de1fd0ef          	jal	ra,ffffffffc0201c7e <kmalloc>
ffffffffc0203ea2:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203ea4:	cd49                	beqz	a0,ffffffffc0203f3e <alloc_proc+0xaa>
    {
        memset(proc, 0, sizeof(struct proc_struct));
ffffffffc0203ea6:	14800613          	li	a2,328
ffffffffc0203eaa:	4581                	li	a1,0
ffffffffc0203eac:	745010ef          	jal	ra,ffffffffc0205df0 <memset>
        proc->state = PROC_UNINIT;
ffffffffc0203eb0:	57fd                	li	a5,-1
ffffffffc0203eb2:	1782                	slli	a5,a5,0x20
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&proc->context, 0, sizeof(proc->context));
ffffffffc0203eb4:	07000613          	li	a2,112
ffffffffc0203eb8:	4581                	li	a1,0
        proc->state = PROC_UNINIT;
ffffffffc0203eba:	e01c                	sd	a5,0(s0)
        proc->runs = 0;
ffffffffc0203ebc:	00042423          	sw	zero,8(s0)
        proc->kstack = 0;
ffffffffc0203ec0:	00043823          	sd	zero,16(s0)
        proc->need_resched = 0;
ffffffffc0203ec4:	00043c23          	sd	zero,24(s0)
        proc->parent = NULL;
ffffffffc0203ec8:	02043023          	sd	zero,32(s0)
        proc->mm = NULL;
ffffffffc0203ecc:	02043423          	sd	zero,40(s0)
        memset(&proc->context, 0, sizeof(proc->context));
ffffffffc0203ed0:	03040513          	addi	a0,s0,48
ffffffffc0203ed4:	71d010ef          	jal	ra,ffffffffc0205df0 <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203ed8:	000c3797          	auipc	a5,0xc3
ffffffffc0203edc:	cd07b783          	ld	a5,-816(a5) # ffffffffc02c6ba8 <boot_pgdir_pa>
ffffffffc0203ee0:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;
ffffffffc0203ee2:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc0203ee6:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203eea:	4641                	li	a2,16
ffffffffc0203eec:	4581                	li	a1,0
ffffffffc0203eee:	0b440513          	addi	a0,s0,180
ffffffffc0203ef2:	6ff010ef          	jal	ra,ffffffffc0205df0 <memset>

        proc->wait_state = 0;
        proc->cptr = proc->yptr = proc->optr = NULL;

        proc->rq = NULL;
        list_init(&(proc->run_link));
ffffffffc0203ef6:	11040793          	addi	a5,s0,272
    elm->prev = elm->next = elm;
ffffffffc0203efa:	10f43c23          	sd	a5,280(s0)
ffffffffc0203efe:	10f43823          	sd	a5,272(s0)
        proc->time_slice = 0;
        skew_heap_init(&(proc->lab6_run_pool));
        proc->lab6_stride = 0;
ffffffffc0203f02:	4785                	li	a5,1
        list_init(&proc->list_link);
ffffffffc0203f04:	0c840693          	addi	a3,s0,200
        list_init(&proc->hash_link);
ffffffffc0203f08:	0d840713          	addi	a4,s0,216
        proc->lab6_stride = 0;
ffffffffc0203f0c:	1782                	slli	a5,a5,0x20
ffffffffc0203f0e:	e874                	sd	a3,208(s0)
ffffffffc0203f10:	e474                	sd	a3,200(s0)
ffffffffc0203f12:	f078                	sd	a4,224(s0)
ffffffffc0203f14:	ec78                	sd	a4,216(s0)
        proc->wait_state = 0;
ffffffffc0203f16:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc0203f1a:	10043023          	sd	zero,256(s0)
ffffffffc0203f1e:	0e043c23          	sd	zero,248(s0)
ffffffffc0203f22:	0e043823          	sd	zero,240(s0)
        proc->rq = NULL;
ffffffffc0203f26:	10043423          	sd	zero,264(s0)
        proc->time_slice = 0;
ffffffffc0203f2a:	12042023          	sw	zero,288(s0)
     compare_f comp) __attribute__((always_inline));

static inline void
skew_heap_init(skew_heap_entry_t *a)
{
     a->left = a->right = a->parent = NULL;
ffffffffc0203f2e:	12043423          	sd	zero,296(s0)
ffffffffc0203f32:	12043823          	sd	zero,304(s0)
ffffffffc0203f36:	12043c23          	sd	zero,312(s0)
        proc->lab6_stride = 0;
ffffffffc0203f3a:	14f43023          	sd	a5,320(s0)
        proc->lab6_priority = 1;
    }
    return proc;
}
ffffffffc0203f3e:	60a2                	ld	ra,8(sp)
ffffffffc0203f40:	8522                	mv	a0,s0
ffffffffc0203f42:	6402                	ld	s0,0(sp)
ffffffffc0203f44:	0141                	addi	sp,sp,16
ffffffffc0203f46:	8082                	ret

ffffffffc0203f48 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203f48:	000c3797          	auipc	a5,0xc3
ffffffffc0203f4c:	c987b783          	ld	a5,-872(a5) # ffffffffc02c6be0 <current>
ffffffffc0203f50:	73c8                	ld	a0,160(a5)
ffffffffc0203f52:	848fd06f          	j	ffffffffc0200f9a <forkrets>

ffffffffc0203f56 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203f56:	6d14                	ld	a3,24(a0)
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm)
{
ffffffffc0203f58:	1141                	addi	sp,sp,-16
ffffffffc0203f5a:	e406                	sd	ra,8(sp)
ffffffffc0203f5c:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f60:	02f6ee63          	bltu	a3,a5,ffffffffc0203f9c <put_pgdir+0x46>
ffffffffc0203f64:	000c3517          	auipc	a0,0xc3
ffffffffc0203f68:	c6c53503          	ld	a0,-916(a0) # ffffffffc02c6bd0 <va_pa_offset>
ffffffffc0203f6c:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0203f6e:	82b1                	srli	a3,a3,0xc
ffffffffc0203f70:	000c3797          	auipc	a5,0xc3
ffffffffc0203f74:	c487b783          	ld	a5,-952(a5) # ffffffffc02c6bb8 <npage>
ffffffffc0203f78:	02f6fe63          	bgeu	a3,a5,ffffffffc0203fb4 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203f7c:	00004517          	auipc	a0,0x4
ffffffffc0203f80:	74453503          	ld	a0,1860(a0) # ffffffffc02086c0 <nbase>
    free_page(kva2page(mm->pgdir));
}
ffffffffc0203f84:	60a2                	ld	ra,8(sp)
ffffffffc0203f86:	8e89                	sub	a3,a3,a0
ffffffffc0203f88:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203f8a:	000c3517          	auipc	a0,0xc3
ffffffffc0203f8e:	c3653503          	ld	a0,-970(a0) # ffffffffc02c6bc0 <pages>
ffffffffc0203f92:	4585                	li	a1,1
ffffffffc0203f94:	9536                	add	a0,a0,a3
}
ffffffffc0203f96:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203f98:	f03fd06f          	j	ffffffffc0201e9a <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203f9c:	00003617          	auipc	a2,0x3
ffffffffc0203fa0:	de460613          	addi	a2,a2,-540 # ffffffffc0206d80 <default_pmm_manager+0xe0>
ffffffffc0203fa4:	07700593          	li	a1,119
ffffffffc0203fa8:	00003517          	auipc	a0,0x3
ffffffffc0203fac:	d5850513          	addi	a0,a0,-680 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc0203fb0:	ce2fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203fb4:	00003617          	auipc	a2,0x3
ffffffffc0203fb8:	df460613          	addi	a2,a2,-524 # ffffffffc0206da8 <default_pmm_manager+0x108>
ffffffffc0203fbc:	06900593          	li	a1,105
ffffffffc0203fc0:	00003517          	auipc	a0,0x3
ffffffffc0203fc4:	d4050513          	addi	a0,a0,-704 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc0203fc8:	ccafc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203fcc <proc_run>:
{
ffffffffc0203fcc:	7179                	addi	sp,sp,-48
ffffffffc0203fce:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203fd0:	000c3497          	auipc	s1,0xc3
ffffffffc0203fd4:	c1048493          	addi	s1,s1,-1008 # ffffffffc02c6be0 <current>
ffffffffc0203fd8:	6098                	ld	a4,0(s1)
{
ffffffffc0203fda:	f406                	sd	ra,40(sp)
ffffffffc0203fdc:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203fde:	02a70763          	beq	a4,a0,ffffffffc020400c <proc_run+0x40>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fe2:	100027f3          	csrr	a5,sstatus
ffffffffc0203fe6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203fe8:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fea:	ef85                	bnez	a5,ffffffffc0204022 <proc_run+0x56>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203fec:	755c                	ld	a5,168(a0)
ffffffffc0203fee:	56fd                	li	a3,-1
ffffffffc0203ff0:	16fe                	slli	a3,a3,0x3f
ffffffffc0203ff2:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0203ff4:	e088                	sd	a0,0(s1)
ffffffffc0203ff6:	8fd5                	or	a5,a5,a3
ffffffffc0203ff8:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(proc->context));
ffffffffc0203ffc:	03050593          	addi	a1,a0,48
ffffffffc0204000:	03070513          	addi	a0,a4,48
ffffffffc0204004:	0fe010ef          	jal	ra,ffffffffc0205102 <switch_to>
    if (flag)
ffffffffc0204008:	00091763          	bnez	s2,ffffffffc0204016 <proc_run+0x4a>
}
ffffffffc020400c:	70a2                	ld	ra,40(sp)
ffffffffc020400e:	7482                	ld	s1,32(sp)
ffffffffc0204010:	6962                	ld	s2,24(sp)
ffffffffc0204012:	6145                	addi	sp,sp,48
ffffffffc0204014:	8082                	ret
ffffffffc0204016:	70a2                	ld	ra,40(sp)
ffffffffc0204018:	7482                	ld	s1,32(sp)
ffffffffc020401a:	6962                	ld	s2,24(sp)
ffffffffc020401c:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc020401e:	98bfc06f          	j	ffffffffc02009a8 <intr_enable>
ffffffffc0204022:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204024:	98bfc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
            struct proc_struct *prev = current;
ffffffffc0204028:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc020402a:	6522                	ld	a0,8(sp)
ffffffffc020402c:	4905                	li	s2,1
ffffffffc020402e:	bf7d                	j	ffffffffc0203fec <proc_run+0x20>

ffffffffc0204030 <do_fork>:
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
ffffffffc0204030:	7119                	addi	sp,sp,-128
ffffffffc0204032:	f0ca                	sd	s2,96(sp)
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
ffffffffc0204034:	000c3917          	auipc	s2,0xc3
ffffffffc0204038:	bc490913          	addi	s2,s2,-1084 # ffffffffc02c6bf8 <nr_process>
ffffffffc020403c:	00092703          	lw	a4,0(s2)
{
ffffffffc0204040:	fc86                	sd	ra,120(sp)
ffffffffc0204042:	f8a2                	sd	s0,112(sp)
ffffffffc0204044:	f4a6                	sd	s1,104(sp)
ffffffffc0204046:	ecce                	sd	s3,88(sp)
ffffffffc0204048:	e8d2                	sd	s4,80(sp)
ffffffffc020404a:	e4d6                	sd	s5,72(sp)
ffffffffc020404c:	e0da                	sd	s6,64(sp)
ffffffffc020404e:	fc5e                	sd	s7,56(sp)
ffffffffc0204050:	f862                	sd	s8,48(sp)
ffffffffc0204052:	f466                	sd	s9,40(sp)
ffffffffc0204054:	f06a                	sd	s10,32(sp)
ffffffffc0204056:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204058:	6785                	lui	a5,0x1
ffffffffc020405a:	32f75a63          	bge	a4,a5,ffffffffc020438e <do_fork+0x35e>
ffffffffc020405e:	8a2a                	mv	s4,a0
ffffffffc0204060:	89ae                	mv	s3,a1
ffffffffc0204062:	8432                	mv	s0,a2
     *    set_links:  set the relation links of process.  ALSO SEE: remove_links:  lean the relation links of process
     *    -------------------
     *    update step 1: set child proc's parent to current process, make sure current process's wait_state is 0
     *    update step 5: insert proc_struct into hash_list && proc_list, set the relation links of process
     */
    proc = alloc_proc();
ffffffffc0204064:	e31ff0ef          	jal	ra,ffffffffc0203e94 <alloc_proc>
ffffffffc0204068:	84aa                	mv	s1,a0
    if (proc == NULL)
ffffffffc020406a:	30050363          	beqz	a0,ffffffffc0204370 <do_fork+0x340>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020406e:	4509                	li	a0,2
ffffffffc0204070:	dedfd0ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
    if (page != NULL)
ffffffffc0204074:	2e050b63          	beqz	a0,ffffffffc020436a <do_fork+0x33a>
    return page - pages + nbase;
ffffffffc0204078:	000c3b17          	auipc	s6,0xc3
ffffffffc020407c:	b48b0b13          	addi	s6,s6,-1208 # ffffffffc02c6bc0 <pages>
ffffffffc0204080:	000b3683          	ld	a3,0(s6)
ffffffffc0204084:	00004797          	auipc	a5,0x4
ffffffffc0204088:	63c78793          	addi	a5,a5,1596 # ffffffffc02086c0 <nbase>
ffffffffc020408c:	6398                	ld	a4,0(a5)
ffffffffc020408e:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204092:	000c3c17          	auipc	s8,0xc3
ffffffffc0204096:	b26c0c13          	addi	s8,s8,-1242 # ffffffffc02c6bb8 <npage>
    return page - pages + nbase;
ffffffffc020409a:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020409c:	57fd                	li	a5,-1
ffffffffc020409e:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02040a2:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02040a4:	00c7db93          	srli	s7,a5,0xc
ffffffffc02040a8:	0176f5b3          	and	a1,a3,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc02040ac:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02040ae:	34c5f663          	bgeu	a1,a2,ffffffffc02043fa <do_fork+0x3ca>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02040b2:	000c3a97          	auipc	s5,0xc3
ffffffffc02040b6:	b2ea8a93          	addi	s5,s5,-1234 # ffffffffc02c6be0 <current>
ffffffffc02040ba:	000ab583          	ld	a1,0(s5)
ffffffffc02040be:	000c3c97          	auipc	s9,0xc3
ffffffffc02040c2:	b12c8c93          	addi	s9,s9,-1262 # ffffffffc02c6bd0 <va_pa_offset>
ffffffffc02040c6:	000cb603          	ld	a2,0(s9)
ffffffffc02040ca:	0285bd83          	ld	s11,40(a1)
ffffffffc02040ce:	e43a                	sd	a4,8(sp)
ffffffffc02040d0:	96b2                	add	a3,a3,a2
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02040d2:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc02040d4:	020d8863          	beqz	s11,ffffffffc0204104 <do_fork+0xd4>
    if (clone_flags & CLONE_VM)
ffffffffc02040d8:	100a7a13          	andi	s4,s4,256
ffffffffc02040dc:	1c0a0663          	beqz	s4,ffffffffc02042a8 <do_fork+0x278>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc02040e0:	030da703          	lw	a4,48(s11)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040e4:	018db783          	ld	a5,24(s11)
ffffffffc02040e8:	c02006b7          	lui	a3,0xc0200
ffffffffc02040ec:	2705                	addiw	a4,a4,1
ffffffffc02040ee:	02eda823          	sw	a4,48(s11)
    proc->mm = mm;
ffffffffc02040f2:	03b4b423          	sd	s11,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040f6:	2cd7e963          	bltu	a5,a3,ffffffffc02043c8 <do_fork+0x398>
ffffffffc02040fa:	000cb703          	ld	a4,0(s9)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040fe:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204100:	8f99                	sub	a5,a5,a4
ffffffffc0204102:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204104:	6789                	lui	a5,0x2
ffffffffc0204106:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8060>
ffffffffc020410a:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc020410c:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020410e:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc0204110:	87b6                	mv	a5,a3
ffffffffc0204112:	12040893          	addi	a7,s0,288
ffffffffc0204116:	00063803          	ld	a6,0(a2)
ffffffffc020411a:	6608                	ld	a0,8(a2)
ffffffffc020411c:	6a0c                	ld	a1,16(a2)
ffffffffc020411e:	6e18                	ld	a4,24(a2)
ffffffffc0204120:	0107b023          	sd	a6,0(a5)
ffffffffc0204124:	e788                	sd	a0,8(a5)
ffffffffc0204126:	eb8c                	sd	a1,16(a5)
ffffffffc0204128:	ef98                	sd	a4,24(a5)
ffffffffc020412a:	02060613          	addi	a2,a2,32
ffffffffc020412e:	02078793          	addi	a5,a5,32
ffffffffc0204132:	ff1612e3          	bne	a2,a7,ffffffffc0204116 <do_fork+0xe6>
    proc->tf->gpr.a0 = 0;
ffffffffc0204136:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020413a:	14098463          	beqz	s3,ffffffffc0204282 <do_fork+0x252>
ffffffffc020413e:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204142:	00000797          	auipc	a5,0x0
ffffffffc0204146:	e0678793          	addi	a5,a5,-506 # ffffffffc0203f48 <forkret>
ffffffffc020414a:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020414c:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020414e:	100027f3          	csrr	a5,sstatus
ffffffffc0204152:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204154:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204156:	14079563          	bnez	a5,ffffffffc02042a0 <do_fork+0x270>
    if (++last_pid >= MAX_PID)
ffffffffc020415a:	000be817          	auipc	a6,0xbe
ffffffffc020415e:	5be80813          	addi	a6,a6,1470 # ffffffffc02c2718 <last_pid.1>
    copy_thread(proc, stack, tf);

    bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->parent = current;
ffffffffc0204162:	000ab703          	ld	a4,0(s5)
    if (++last_pid >= MAX_PID)
ffffffffc0204166:	00082783          	lw	a5,0(a6)
ffffffffc020416a:	6689                	lui	a3,0x2
        proc->parent = current;
ffffffffc020416c:	f098                	sd	a4,32(s1)
    if (++last_pid >= MAX_PID)
ffffffffc020416e:	0017851b          	addiw	a0,a5,1
        current->wait_state = 0;
ffffffffc0204172:	0e072623          	sw	zero,236(a4)
    if (++last_pid >= MAX_PID)
ffffffffc0204176:	00a82023          	sw	a0,0(a6)
ffffffffc020417a:	08d55d63          	bge	a0,a3,ffffffffc0204214 <do_fork+0x1e4>
    if (last_pid >= next_safe)
ffffffffc020417e:	000be317          	auipc	t1,0xbe
ffffffffc0204182:	59e30313          	addi	t1,t1,1438 # ffffffffc02c271c <next_safe.0>
ffffffffc0204186:	00032783          	lw	a5,0(t1)
ffffffffc020418a:	000c3417          	auipc	s0,0xc3
ffffffffc020418e:	9ae40413          	addi	s0,s0,-1618 # ffffffffc02c6b38 <proc_list>
ffffffffc0204192:	08f55963          	bge	a0,a5,ffffffffc0204224 <do_fork+0x1f4>

        proc->pid = get_pid();
ffffffffc0204196:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204198:	45a9                	li	a1,10
ffffffffc020419a:	2501                	sext.w	a0,a0
ffffffffc020419c:	7ae010ef          	jal	ra,ffffffffc020594a <hash32>
ffffffffc02041a0:	02051793          	slli	a5,a0,0x20
ffffffffc02041a4:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02041a8:	000bf797          	auipc	a5,0xbf
ffffffffc02041ac:	99078793          	addi	a5,a5,-1648 # ffffffffc02c2b38 <hash_list>
ffffffffc02041b0:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02041b2:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02041b4:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02041b6:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc02041ba:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02041bc:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc02041be:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02041c0:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02041c2:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc02041c6:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc02041c8:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc02041ca:	e21c                	sd	a5,0(a2)
ffffffffc02041cc:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc02041ce:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc02041d0:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc02041d2:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02041d6:	10e4b023          	sd	a4,256(s1)
ffffffffc02041da:	c311                	beqz	a4,ffffffffc02041de <do_fork+0x1ae>
        proc->optr->yptr = proc;
ffffffffc02041dc:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc02041de:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc02041e2:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc02041e4:	2785                	addiw	a5,a5,1
ffffffffc02041e6:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc02041ea:	18099563          	bnez	s3,ffffffffc0204374 <do_fork+0x344>
        hash_proc(proc);
        set_links(proc);
    }
    local_intr_restore(intr_flag);

    wakeup_proc(proc);
ffffffffc02041ee:	8526                	mv	a0,s1
ffffffffc02041f0:	4e8010ef          	jal	ra,ffffffffc02056d8 <wakeup_proc>
    ret = proc->pid;
ffffffffc02041f4:	40c8                	lw	a0,4(s1)
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
ffffffffc02041f6:	70e6                	ld	ra,120(sp)
ffffffffc02041f8:	7446                	ld	s0,112(sp)
ffffffffc02041fa:	74a6                	ld	s1,104(sp)
ffffffffc02041fc:	7906                	ld	s2,96(sp)
ffffffffc02041fe:	69e6                	ld	s3,88(sp)
ffffffffc0204200:	6a46                	ld	s4,80(sp)
ffffffffc0204202:	6aa6                	ld	s5,72(sp)
ffffffffc0204204:	6b06                	ld	s6,64(sp)
ffffffffc0204206:	7be2                	ld	s7,56(sp)
ffffffffc0204208:	7c42                	ld	s8,48(sp)
ffffffffc020420a:	7ca2                	ld	s9,40(sp)
ffffffffc020420c:	7d02                	ld	s10,32(sp)
ffffffffc020420e:	6de2                	ld	s11,24(sp)
ffffffffc0204210:	6109                	addi	sp,sp,128
ffffffffc0204212:	8082                	ret
        last_pid = 1;
ffffffffc0204214:	4785                	li	a5,1
ffffffffc0204216:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020421a:	4505                	li	a0,1
ffffffffc020421c:	000be317          	auipc	t1,0xbe
ffffffffc0204220:	50030313          	addi	t1,t1,1280 # ffffffffc02c271c <next_safe.0>
    return listelm->next;
ffffffffc0204224:	000c3417          	auipc	s0,0xc3
ffffffffc0204228:	91440413          	addi	s0,s0,-1772 # ffffffffc02c6b38 <proc_list>
ffffffffc020422c:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0204230:	6789                	lui	a5,0x2
ffffffffc0204232:	00f32023          	sw	a5,0(t1)
ffffffffc0204236:	86aa                	mv	a3,a0
ffffffffc0204238:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020423a:	6e89                	lui	t4,0x2
ffffffffc020423c:	148e0463          	beq	t3,s0,ffffffffc0204384 <do_fork+0x354>
ffffffffc0204240:	88ae                	mv	a7,a1
ffffffffc0204242:	87f2                	mv	a5,t3
ffffffffc0204244:	6609                	lui	a2,0x2
ffffffffc0204246:	a811                	j	ffffffffc020425a <do_fork+0x22a>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204248:	00e6d663          	bge	a3,a4,ffffffffc0204254 <do_fork+0x224>
ffffffffc020424c:	00c75463          	bge	a4,a2,ffffffffc0204254 <do_fork+0x224>
ffffffffc0204250:	863a                	mv	a2,a4
ffffffffc0204252:	4885                	li	a7,1
ffffffffc0204254:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204256:	00878d63          	beq	a5,s0,ffffffffc0204270 <do_fork+0x240>
            if (proc->pid == last_pid)
ffffffffc020425a:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x8004>
ffffffffc020425e:	fed715e3          	bne	a4,a3,ffffffffc0204248 <do_fork+0x218>
                if (++last_pid >= next_safe)
ffffffffc0204262:	2685                	addiw	a3,a3,1
ffffffffc0204264:	10c6db63          	bge	a3,a2,ffffffffc020437a <do_fork+0x34a>
ffffffffc0204268:	679c                	ld	a5,8(a5)
ffffffffc020426a:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc020426c:	fe8797e3          	bne	a5,s0,ffffffffc020425a <do_fork+0x22a>
ffffffffc0204270:	c581                	beqz	a1,ffffffffc0204278 <do_fork+0x248>
ffffffffc0204272:	00d82023          	sw	a3,0(a6)
ffffffffc0204276:	8536                	mv	a0,a3
ffffffffc0204278:	f0088fe3          	beqz	a7,ffffffffc0204196 <do_fork+0x166>
ffffffffc020427c:	00c32023          	sw	a2,0(t1)
ffffffffc0204280:	bf19                	j	ffffffffc0204196 <do_fork+0x166>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204282:	89b6                	mv	s3,a3
ffffffffc0204284:	0136b823          	sd	s3,16(a3) # 2010 <_binary_obj___user_faultread_out_size-0x7f30>
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204288:	00000797          	auipc	a5,0x0
ffffffffc020428c:	cc078793          	addi	a5,a5,-832 # ffffffffc0203f48 <forkret>
ffffffffc0204290:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204292:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204294:	100027f3          	csrr	a5,sstatus
ffffffffc0204298:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020429a:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020429c:	ea078fe3          	beqz	a5,ffffffffc020415a <do_fork+0x12a>
        intr_disable();
ffffffffc02042a0:	f0efc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc02042a4:	4985                	li	s3,1
ffffffffc02042a6:	bd55                	j	ffffffffc020415a <do_fork+0x12a>
    if ((mm = mm_create()) == NULL)
ffffffffc02042a8:	b0eff0ef          	jal	ra,ffffffffc02035b6 <mm_create>
ffffffffc02042ac:	8d2a                	mv	s10,a0
ffffffffc02042ae:	c159                	beqz	a0,ffffffffc0204334 <do_fork+0x304>
    if ((page = alloc_page()) == NULL)
ffffffffc02042b0:	4505                	li	a0,1
ffffffffc02042b2:	babfd0ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02042b6:	cd25                	beqz	a0,ffffffffc020432e <do_fork+0x2fe>
    return page - pages + nbase;
ffffffffc02042b8:	000b3683          	ld	a3,0(s6)
ffffffffc02042bc:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc02042be:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02042c2:	40d506b3          	sub	a3,a0,a3
ffffffffc02042c6:	8699                	srai	a3,a3,0x6
ffffffffc02042c8:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02042ca:	0176f7b3          	and	a5,a3,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc02042ce:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02042d0:	12c7f563          	bgeu	a5,a2,ffffffffc02043fa <do_fork+0x3ca>
ffffffffc02042d4:	000cba03          	ld	s4,0(s9)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02042d8:	6605                	lui	a2,0x1
ffffffffc02042da:	000c3597          	auipc	a1,0xc3
ffffffffc02042de:	8d65b583          	ld	a1,-1834(a1) # ffffffffc02c6bb0 <boot_pgdir_va>
ffffffffc02042e2:	9a36                	add	s4,s4,a3
ffffffffc02042e4:	8552                	mv	a0,s4
ffffffffc02042e6:	31d010ef          	jal	ra,ffffffffc0205e02 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02042ea:	038d8b93          	addi	s7,s11,56
    mm->pgdir = pgdir;
ffffffffc02042ee:	014d3c23          	sd	s4,24(s10) # 200018 <_binary_obj___user_matrix_out_size+0x1f3908>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02042f2:	4785                	li	a5,1
ffffffffc02042f4:	40fbb7af          	amoor.d	a5,a5,(s7)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02042f8:	8b85                	andi	a5,a5,1
ffffffffc02042fa:	4a05                	li	s4,1
ffffffffc02042fc:	c799                	beqz	a5,ffffffffc020430a <do_fork+0x2da>
    {
        schedule();
ffffffffc02042fe:	48c010ef          	jal	ra,ffffffffc020578a <schedule>
ffffffffc0204302:	414bb7af          	amoor.d	a5,s4,(s7)
    while (!try_lock(lock))
ffffffffc0204306:	8b85                	andi	a5,a5,1
ffffffffc0204308:	fbfd                	bnez	a5,ffffffffc02042fe <do_fork+0x2ce>
        ret = dup_mmap(mm, oldmm);
ffffffffc020430a:	85ee                	mv	a1,s11
ffffffffc020430c:	856a                	mv	a0,s10
ffffffffc020430e:	ceaff0ef          	jal	ra,ffffffffc02037f8 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204312:	57f9                	li	a5,-2
ffffffffc0204314:	60fbb7af          	amoand.d	a5,a5,(s7)
ffffffffc0204318:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020431a:	cfbd                	beqz	a5,ffffffffc0204398 <do_fork+0x368>
good_mm:
ffffffffc020431c:	8dea                	mv	s11,s10
    if (ret != 0)
ffffffffc020431e:	dc0501e3          	beqz	a0,ffffffffc02040e0 <do_fork+0xb0>
    exit_mmap(mm);
ffffffffc0204322:	856a                	mv	a0,s10
ffffffffc0204324:	d6eff0ef          	jal	ra,ffffffffc0203892 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204328:	856a                	mv	a0,s10
ffffffffc020432a:	c2dff0ef          	jal	ra,ffffffffc0203f56 <put_pgdir>
    mm_destroy(mm);
ffffffffc020432e:	856a                	mv	a0,s10
ffffffffc0204330:	bc6ff0ef          	jal	ra,ffffffffc02036f6 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204334:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc0204336:	c02007b7          	lui	a5,0xc0200
ffffffffc020433a:	0af6e463          	bltu	a3,a5,ffffffffc02043e2 <do_fork+0x3b2>
ffffffffc020433e:	000cb783          	ld	a5,0(s9)
    if (PPN(pa) >= npage)
ffffffffc0204342:	000c3703          	ld	a4,0(s8)
    return pa2page(PADDR(kva));
ffffffffc0204346:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020434a:	83b1                	srli	a5,a5,0xc
ffffffffc020434c:	06e7f263          	bgeu	a5,a4,ffffffffc02043b0 <do_fork+0x380>
    return &pages[PPN(pa) - nbase];
ffffffffc0204350:	00004717          	auipc	a4,0x4
ffffffffc0204354:	37070713          	addi	a4,a4,880 # ffffffffc02086c0 <nbase>
ffffffffc0204358:	6318                	ld	a4,0(a4)
ffffffffc020435a:	000b3503          	ld	a0,0(s6)
ffffffffc020435e:	4589                	li	a1,2
ffffffffc0204360:	8f99                	sub	a5,a5,a4
ffffffffc0204362:	079a                	slli	a5,a5,0x6
ffffffffc0204364:	953e                	add	a0,a0,a5
ffffffffc0204366:	b35fd0ef          	jal	ra,ffffffffc0201e9a <free_pages>
    kfree(proc);
ffffffffc020436a:	8526                	mv	a0,s1
ffffffffc020436c:	9c3fd0ef          	jal	ra,ffffffffc0201d2e <kfree>
    ret = -E_NO_MEM;
ffffffffc0204370:	5571                	li	a0,-4
    return ret;
ffffffffc0204372:	b551                	j	ffffffffc02041f6 <do_fork+0x1c6>
        intr_enable();
ffffffffc0204374:	e34fc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0204378:	bd9d                	j	ffffffffc02041ee <do_fork+0x1be>
                    if (last_pid >= MAX_PID)
ffffffffc020437a:	01d6c363          	blt	a3,t4,ffffffffc0204380 <do_fork+0x350>
                        last_pid = 1;
ffffffffc020437e:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204380:	4585                	li	a1,1
ffffffffc0204382:	bd6d                	j	ffffffffc020423c <do_fork+0x20c>
ffffffffc0204384:	c599                	beqz	a1,ffffffffc0204392 <do_fork+0x362>
ffffffffc0204386:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc020438a:	8536                	mv	a0,a3
ffffffffc020438c:	b529                	j	ffffffffc0204196 <do_fork+0x166>
    int ret = -E_NO_FREE_PROC;
ffffffffc020438e:	556d                	li	a0,-5
ffffffffc0204390:	b59d                	j	ffffffffc02041f6 <do_fork+0x1c6>
    return last_pid;
ffffffffc0204392:	00082503          	lw	a0,0(a6)
ffffffffc0204396:	b501                	j	ffffffffc0204196 <do_fork+0x166>
    {
        panic("Unlock failed.\n");
ffffffffc0204398:	00003617          	auipc	a2,0x3
ffffffffc020439c:	2f060613          	addi	a2,a2,752 # ffffffffc0207688 <default_pmm_manager+0x9e8>
ffffffffc02043a0:	04000593          	li	a1,64
ffffffffc02043a4:	00003517          	auipc	a0,0x3
ffffffffc02043a8:	2f450513          	addi	a0,a0,756 # ffffffffc0207698 <default_pmm_manager+0x9f8>
ffffffffc02043ac:	8e6fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02043b0:	00003617          	auipc	a2,0x3
ffffffffc02043b4:	9f860613          	addi	a2,a2,-1544 # ffffffffc0206da8 <default_pmm_manager+0x108>
ffffffffc02043b8:	06900593          	li	a1,105
ffffffffc02043bc:	00003517          	auipc	a0,0x3
ffffffffc02043c0:	94450513          	addi	a0,a0,-1724 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc02043c4:	8cefc0ef          	jal	ra,ffffffffc0200492 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02043c8:	86be                	mv	a3,a5
ffffffffc02043ca:	00003617          	auipc	a2,0x3
ffffffffc02043ce:	9b660613          	addi	a2,a2,-1610 # ffffffffc0206d80 <default_pmm_manager+0xe0>
ffffffffc02043d2:	17400593          	li	a1,372
ffffffffc02043d6:	00003517          	auipc	a0,0x3
ffffffffc02043da:	2da50513          	addi	a0,a0,730 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc02043de:	8b4fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02043e2:	00003617          	auipc	a2,0x3
ffffffffc02043e6:	99e60613          	addi	a2,a2,-1634 # ffffffffc0206d80 <default_pmm_manager+0xe0>
ffffffffc02043ea:	07700593          	li	a1,119
ffffffffc02043ee:	00003517          	auipc	a0,0x3
ffffffffc02043f2:	91250513          	addi	a0,a0,-1774 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc02043f6:	89cfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc02043fa:	00003617          	auipc	a2,0x3
ffffffffc02043fe:	8de60613          	addi	a2,a2,-1826 # ffffffffc0206cd8 <default_pmm_manager+0x38>
ffffffffc0204402:	07100593          	li	a1,113
ffffffffc0204406:	00003517          	auipc	a0,0x3
ffffffffc020440a:	8fa50513          	addi	a0,a0,-1798 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc020440e:	884fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204412 <kernel_thread>:
{
ffffffffc0204412:	7129                	addi	sp,sp,-320
ffffffffc0204414:	fa22                	sd	s0,304(sp)
ffffffffc0204416:	f626                	sd	s1,296(sp)
ffffffffc0204418:	f24a                	sd	s2,288(sp)
ffffffffc020441a:	84ae                	mv	s1,a1
ffffffffc020441c:	892a                	mv	s2,a0
ffffffffc020441e:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204420:	4581                	li	a1,0
ffffffffc0204422:	12000613          	li	a2,288
ffffffffc0204426:	850a                	mv	a0,sp
{
ffffffffc0204428:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020442a:	1c7010ef          	jal	ra,ffffffffc0205df0 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020442e:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204430:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204432:	100027f3          	csrr	a5,sstatus
ffffffffc0204436:	edd7f793          	andi	a5,a5,-291
ffffffffc020443a:	1207e793          	ori	a5,a5,288
ffffffffc020443e:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204440:	860a                	mv	a2,sp
ffffffffc0204442:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204446:	00000797          	auipc	a5,0x0
ffffffffc020444a:	a4678793          	addi	a5,a5,-1466 # ffffffffc0203e8c <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020444e:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204450:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204452:	bdfff0ef          	jal	ra,ffffffffc0204030 <do_fork>
}
ffffffffc0204456:	70f2                	ld	ra,312(sp)
ffffffffc0204458:	7452                	ld	s0,304(sp)
ffffffffc020445a:	74b2                	ld	s1,296(sp)
ffffffffc020445c:	7912                	ld	s2,288(sp)
ffffffffc020445e:	6131                	addi	sp,sp,320
ffffffffc0204460:	8082                	ret

ffffffffc0204462 <do_exit>:
// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
ffffffffc0204462:	7179                	addi	sp,sp,-48
ffffffffc0204464:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204466:	000c2417          	auipc	s0,0xc2
ffffffffc020446a:	77a40413          	addi	s0,s0,1914 # ffffffffc02c6be0 <current>
ffffffffc020446e:	601c                	ld	a5,0(s0)
{
ffffffffc0204470:	f406                	sd	ra,40(sp)
ffffffffc0204472:	ec26                	sd	s1,24(sp)
ffffffffc0204474:	e84a                	sd	s2,16(sp)
ffffffffc0204476:	e44e                	sd	s3,8(sp)
ffffffffc0204478:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc020447a:	000c2717          	auipc	a4,0xc2
ffffffffc020447e:	76e73703          	ld	a4,1902(a4) # ffffffffc02c6be8 <idleproc>
ffffffffc0204482:	0ce78c63          	beq	a5,a4,ffffffffc020455a <do_exit+0xf8>
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
ffffffffc0204486:	000c2497          	auipc	s1,0xc2
ffffffffc020448a:	76a48493          	addi	s1,s1,1898 # ffffffffc02c6bf0 <initproc>
ffffffffc020448e:	6098                	ld	a4,0(s1)
ffffffffc0204490:	0ee78b63          	beq	a5,a4,ffffffffc0204586 <do_exit+0x124>
    {
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm;
ffffffffc0204494:	0287b983          	ld	s3,40(a5)
ffffffffc0204498:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc020449a:	02098663          	beqz	s3,ffffffffc02044c6 <do_exit+0x64>
ffffffffc020449e:	000c2797          	auipc	a5,0xc2
ffffffffc02044a2:	70a7b783          	ld	a5,1802(a5) # ffffffffc02c6ba8 <boot_pgdir_pa>
ffffffffc02044a6:	577d                	li	a4,-1
ffffffffc02044a8:	177e                	slli	a4,a4,0x3f
ffffffffc02044aa:	83b1                	srli	a5,a5,0xc
ffffffffc02044ac:	8fd9                	or	a5,a5,a4
ffffffffc02044ae:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02044b2:	0309a783          	lw	a5,48(s3)
ffffffffc02044b6:	fff7871b          	addiw	a4,a5,-1
ffffffffc02044ba:	02e9a823          	sw	a4,48(s3)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
ffffffffc02044be:	cb55                	beqz	a4,ffffffffc0204572 <do_exit+0x110>
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
ffffffffc02044c0:	601c                	ld	a5,0(s0)
ffffffffc02044c2:	0207b423          	sd	zero,40(a5)
    }
    current->state = PROC_ZOMBIE;
ffffffffc02044c6:	601c                	ld	a5,0(s0)
ffffffffc02044c8:	470d                	li	a4,3
ffffffffc02044ca:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02044cc:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02044d0:	100027f3          	csrr	a5,sstatus
ffffffffc02044d4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02044d6:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02044d8:	e3f9                	bnez	a5,ffffffffc020459e <do_exit+0x13c>
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        proc = current->parent;
ffffffffc02044da:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc02044dc:	800007b7          	lui	a5,0x80000
ffffffffc02044e0:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc02044e2:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc02044e4:	0ec52703          	lw	a4,236(a0)
ffffffffc02044e8:	0af70f63          	beq	a4,a5,ffffffffc02045a6 <do_exit+0x144>
        {
            wakeup_proc(proc);
        }
        while (current->cptr != NULL)
ffffffffc02044ec:	6018                	ld	a4,0(s0)
ffffffffc02044ee:	7b7c                	ld	a5,240(a4)
ffffffffc02044f0:	c3a1                	beqz	a5,ffffffffc0204530 <do_exit+0xce>
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            if (proc->state == PROC_ZOMBIE)
            {
                if (initproc->wait_state == WT_CHILD)
ffffffffc02044f2:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044f6:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc02044f8:	0985                	addi	s3,s3,1
ffffffffc02044fa:	a021                	j	ffffffffc0204502 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc02044fc:	6018                	ld	a4,0(s0)
ffffffffc02044fe:	7b7c                	ld	a5,240(a4)
ffffffffc0204500:	cb85                	beqz	a5,ffffffffc0204530 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204502:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_matrix_out_size+0xffffffff7fff39f0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204506:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204508:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020450a:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc020450c:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204510:	10e7b023          	sd	a4,256(a5)
ffffffffc0204514:	c311                	beqz	a4,ffffffffc0204518 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204516:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204518:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020451a:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020451c:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020451e:	fd271fe3          	bne	a4,s2,ffffffffc02044fc <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204522:	0ec52783          	lw	a5,236(a0)
ffffffffc0204526:	fd379be3          	bne	a5,s3,ffffffffc02044fc <do_exit+0x9a>
                {
                    wakeup_proc(initproc);
ffffffffc020452a:	1ae010ef          	jal	ra,ffffffffc02056d8 <wakeup_proc>
ffffffffc020452e:	b7f9                	j	ffffffffc02044fc <do_exit+0x9a>
    if (flag)
ffffffffc0204530:	020a1263          	bnez	s4,ffffffffc0204554 <do_exit+0xf2>
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    schedule();
ffffffffc0204534:	256010ef          	jal	ra,ffffffffc020578a <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204538:	601c                	ld	a5,0(s0)
ffffffffc020453a:	00003617          	auipc	a2,0x3
ffffffffc020453e:	1ae60613          	addi	a2,a2,430 # ffffffffc02076e8 <default_pmm_manager+0xa48>
ffffffffc0204542:	22500593          	li	a1,549
ffffffffc0204546:	43d4                	lw	a3,4(a5)
ffffffffc0204548:	00003517          	auipc	a0,0x3
ffffffffc020454c:	16850513          	addi	a0,a0,360 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc0204550:	f43fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_enable();
ffffffffc0204554:	c54fc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0204558:	bff1                	j	ffffffffc0204534 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc020455a:	00003617          	auipc	a2,0x3
ffffffffc020455e:	16e60613          	addi	a2,a2,366 # ffffffffc02076c8 <default_pmm_manager+0xa28>
ffffffffc0204562:	1f100593          	li	a1,497
ffffffffc0204566:	00003517          	auipc	a0,0x3
ffffffffc020456a:	14a50513          	addi	a0,a0,330 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc020456e:	f25fb0ef          	jal	ra,ffffffffc0200492 <__panic>
            exit_mmap(mm);
ffffffffc0204572:	854e                	mv	a0,s3
ffffffffc0204574:	b1eff0ef          	jal	ra,ffffffffc0203892 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204578:	854e                	mv	a0,s3
ffffffffc020457a:	9ddff0ef          	jal	ra,ffffffffc0203f56 <put_pgdir>
            mm_destroy(mm);
ffffffffc020457e:	854e                	mv	a0,s3
ffffffffc0204580:	976ff0ef          	jal	ra,ffffffffc02036f6 <mm_destroy>
ffffffffc0204584:	bf35                	j	ffffffffc02044c0 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0204586:	00003617          	auipc	a2,0x3
ffffffffc020458a:	15260613          	addi	a2,a2,338 # ffffffffc02076d8 <default_pmm_manager+0xa38>
ffffffffc020458e:	1f500593          	li	a1,501
ffffffffc0204592:	00003517          	auipc	a0,0x3
ffffffffc0204596:	11e50513          	addi	a0,a0,286 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc020459a:	ef9fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_disable();
ffffffffc020459e:	c10fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc02045a2:	4a05                	li	s4,1
ffffffffc02045a4:	bf1d                	j	ffffffffc02044da <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc02045a6:	132010ef          	jal	ra,ffffffffc02056d8 <wakeup_proc>
ffffffffc02045aa:	b789                	j	ffffffffc02044ec <do_exit+0x8a>

ffffffffc02045ac <do_wait.part.0>:
}

// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
int do_wait(int pid, int *code_store)
ffffffffc02045ac:	715d                	addi	sp,sp,-80
ffffffffc02045ae:	f84a                	sd	s2,48(sp)
ffffffffc02045b0:	f44e                	sd	s3,40(sp)
        }
    }
    if (haskid)
    {
        current->state = PROC_SLEEPING;
        current->wait_state = WT_CHILD;
ffffffffc02045b2:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc02045b6:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc02045b8:	fc26                	sd	s1,56(sp)
ffffffffc02045ba:	f052                	sd	s4,32(sp)
ffffffffc02045bc:	ec56                	sd	s5,24(sp)
ffffffffc02045be:	e85a                	sd	s6,16(sp)
ffffffffc02045c0:	e45e                	sd	s7,8(sp)
ffffffffc02045c2:	e486                	sd	ra,72(sp)
ffffffffc02045c4:	e0a2                	sd	s0,64(sp)
ffffffffc02045c6:	84aa                	mv	s1,a0
ffffffffc02045c8:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc02045ca:	000c2b97          	auipc	s7,0xc2
ffffffffc02045ce:	616b8b93          	addi	s7,s7,1558 # ffffffffc02c6be0 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc02045d2:	00050b1b          	sext.w	s6,a0
ffffffffc02045d6:	fff50a9b          	addiw	s5,a0,-1
ffffffffc02045da:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc02045dc:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc02045de:	ccbd                	beqz	s1,ffffffffc020465c <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc02045e0:	0359e863          	bltu	s3,s5,ffffffffc0204610 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02045e4:	45a9                	li	a1,10
ffffffffc02045e6:	855a                	mv	a0,s6
ffffffffc02045e8:	362010ef          	jal	ra,ffffffffc020594a <hash32>
ffffffffc02045ec:	02051793          	slli	a5,a0,0x20
ffffffffc02045f0:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02045f4:	000be797          	auipc	a5,0xbe
ffffffffc02045f8:	54478793          	addi	a5,a5,1348 # ffffffffc02c2b38 <hash_list>
ffffffffc02045fc:	953e                	add	a0,a0,a5
ffffffffc02045fe:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204600:	a029                	j	ffffffffc020460a <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204602:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204606:	02978163          	beq	a5,s1,ffffffffc0204628 <do_wait.part.0+0x7c>
ffffffffc020460a:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc020460c:	fe851be3          	bne	a0,s0,ffffffffc0204602 <do_wait.part.0+0x56>
        {
            do_exit(-E_KILLED);
        }
        goto repeat;
    }
    return -E_BAD_PROC;
ffffffffc0204610:	5579                	li	a0,-2
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}
ffffffffc0204612:	60a6                	ld	ra,72(sp)
ffffffffc0204614:	6406                	ld	s0,64(sp)
ffffffffc0204616:	74e2                	ld	s1,56(sp)
ffffffffc0204618:	7942                	ld	s2,48(sp)
ffffffffc020461a:	79a2                	ld	s3,40(sp)
ffffffffc020461c:	7a02                	ld	s4,32(sp)
ffffffffc020461e:	6ae2                	ld	s5,24(sp)
ffffffffc0204620:	6b42                	ld	s6,16(sp)
ffffffffc0204622:	6ba2                	ld	s7,8(sp)
ffffffffc0204624:	6161                	addi	sp,sp,80
ffffffffc0204626:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204628:	000bb683          	ld	a3,0(s7)
ffffffffc020462c:	f4843783          	ld	a5,-184(s0)
ffffffffc0204630:	fed790e3          	bne	a5,a3,ffffffffc0204610 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204634:	f2842703          	lw	a4,-216(s0)
ffffffffc0204638:	478d                	li	a5,3
ffffffffc020463a:	0ef70b63          	beq	a4,a5,ffffffffc0204730 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc020463e:	4785                	li	a5,1
ffffffffc0204640:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204642:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204646:	144010ef          	jal	ra,ffffffffc020578a <schedule>
        if (current->flags & PF_EXITING)
ffffffffc020464a:	000bb783          	ld	a5,0(s7)
ffffffffc020464e:	0b07a783          	lw	a5,176(a5)
ffffffffc0204652:	8b85                	andi	a5,a5,1
ffffffffc0204654:	d7c9                	beqz	a5,ffffffffc02045de <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc0204656:	555d                	li	a0,-9
ffffffffc0204658:	e0bff0ef          	jal	ra,ffffffffc0204462 <do_exit>
        proc = current->cptr;
ffffffffc020465c:	000bb683          	ld	a3,0(s7)
ffffffffc0204660:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204662:	d45d                	beqz	s0,ffffffffc0204610 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204664:	470d                	li	a4,3
ffffffffc0204666:	a021                	j	ffffffffc020466e <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204668:	10043403          	ld	s0,256(s0)
ffffffffc020466c:	d869                	beqz	s0,ffffffffc020463e <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020466e:	401c                	lw	a5,0(s0)
ffffffffc0204670:	fee79ce3          	bne	a5,a4,ffffffffc0204668 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0204674:	000c2797          	auipc	a5,0xc2
ffffffffc0204678:	5747b783          	ld	a5,1396(a5) # ffffffffc02c6be8 <idleproc>
ffffffffc020467c:	0c878963          	beq	a5,s0,ffffffffc020474e <do_wait.part.0+0x1a2>
ffffffffc0204680:	000c2797          	auipc	a5,0xc2
ffffffffc0204684:	5707b783          	ld	a5,1392(a5) # ffffffffc02c6bf0 <initproc>
ffffffffc0204688:	0cf40363          	beq	s0,a5,ffffffffc020474e <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc020468c:	000a0663          	beqz	s4,ffffffffc0204698 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204690:	0e842783          	lw	a5,232(s0)
ffffffffc0204694:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f40>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204698:	100027f3          	csrr	a5,sstatus
ffffffffc020469c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020469e:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02046a0:	e7c1                	bnez	a5,ffffffffc0204728 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02046a2:	6c70                	ld	a2,216(s0)
ffffffffc02046a4:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc02046a6:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc02046aa:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02046ac:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02046ae:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02046b0:	6470                	ld	a2,200(s0)
ffffffffc02046b2:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02046b4:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02046b6:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc02046b8:	c319                	beqz	a4,ffffffffc02046be <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc02046ba:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc02046bc:	7c7c                	ld	a5,248(s0)
ffffffffc02046be:	c3b5                	beqz	a5,ffffffffc0204722 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc02046c0:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc02046c4:	000c2717          	auipc	a4,0xc2
ffffffffc02046c8:	53470713          	addi	a4,a4,1332 # ffffffffc02c6bf8 <nr_process>
ffffffffc02046cc:	431c                	lw	a5,0(a4)
ffffffffc02046ce:	37fd                	addiw	a5,a5,-1
ffffffffc02046d0:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc02046d2:	e5a9                	bnez	a1,ffffffffc020471c <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02046d4:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02046d6:	c02007b7          	lui	a5,0xc0200
ffffffffc02046da:	04f6ee63          	bltu	a3,a5,ffffffffc0204736 <do_wait.part.0+0x18a>
ffffffffc02046de:	000c2797          	auipc	a5,0xc2
ffffffffc02046e2:	4f27b783          	ld	a5,1266(a5) # ffffffffc02c6bd0 <va_pa_offset>
ffffffffc02046e6:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02046e8:	82b1                	srli	a3,a3,0xc
ffffffffc02046ea:	000c2797          	auipc	a5,0xc2
ffffffffc02046ee:	4ce7b783          	ld	a5,1230(a5) # ffffffffc02c6bb8 <npage>
ffffffffc02046f2:	06f6fa63          	bgeu	a3,a5,ffffffffc0204766 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc02046f6:	00004517          	auipc	a0,0x4
ffffffffc02046fa:	fca53503          	ld	a0,-54(a0) # ffffffffc02086c0 <nbase>
ffffffffc02046fe:	8e89                	sub	a3,a3,a0
ffffffffc0204700:	069a                	slli	a3,a3,0x6
ffffffffc0204702:	000c2517          	auipc	a0,0xc2
ffffffffc0204706:	4be53503          	ld	a0,1214(a0) # ffffffffc02c6bc0 <pages>
ffffffffc020470a:	9536                	add	a0,a0,a3
ffffffffc020470c:	4589                	li	a1,2
ffffffffc020470e:	f8cfd0ef          	jal	ra,ffffffffc0201e9a <free_pages>
    kfree(proc);
ffffffffc0204712:	8522                	mv	a0,s0
ffffffffc0204714:	e1afd0ef          	jal	ra,ffffffffc0201d2e <kfree>
    return 0;
ffffffffc0204718:	4501                	li	a0,0
ffffffffc020471a:	bde5                	j	ffffffffc0204612 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc020471c:	a8cfc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0204720:	bf55                	j	ffffffffc02046d4 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204722:	701c                	ld	a5,32(s0)
ffffffffc0204724:	fbf8                	sd	a4,240(a5)
ffffffffc0204726:	bf79                	j	ffffffffc02046c4 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204728:	a86fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc020472c:	4585                	li	a1,1
ffffffffc020472e:	bf95                	j	ffffffffc02046a2 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204730:	f2840413          	addi	s0,s0,-216
ffffffffc0204734:	b781                	j	ffffffffc0204674 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204736:	00002617          	auipc	a2,0x2
ffffffffc020473a:	64a60613          	addi	a2,a2,1610 # ffffffffc0206d80 <default_pmm_manager+0xe0>
ffffffffc020473e:	07700593          	li	a1,119
ffffffffc0204742:	00002517          	auipc	a0,0x2
ffffffffc0204746:	5be50513          	addi	a0,a0,1470 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc020474a:	d49fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc020474e:	00003617          	auipc	a2,0x3
ffffffffc0204752:	fba60613          	addi	a2,a2,-70 # ffffffffc0207708 <default_pmm_manager+0xa68>
ffffffffc0204756:	34700593          	li	a1,839
ffffffffc020475a:	00003517          	auipc	a0,0x3
ffffffffc020475e:	f5650513          	addi	a0,a0,-170 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc0204762:	d31fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204766:	00002617          	auipc	a2,0x2
ffffffffc020476a:	64260613          	addi	a2,a2,1602 # ffffffffc0206da8 <default_pmm_manager+0x108>
ffffffffc020476e:	06900593          	li	a1,105
ffffffffc0204772:	00002517          	auipc	a0,0x2
ffffffffc0204776:	58e50513          	addi	a0,a0,1422 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc020477a:	d19fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020477e <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc020477e:	1141                	addi	sp,sp,-16
ffffffffc0204780:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204782:	f58fd0ef          	jal	ra,ffffffffc0201eda <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204786:	cf4fd0ef          	jal	ra,ffffffffc0201c7a <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc020478a:	4601                	li	a2,0
ffffffffc020478c:	4581                	li	a1,0
ffffffffc020478e:	00000517          	auipc	a0,0x0
ffffffffc0204792:	62850513          	addi	a0,a0,1576 # ffffffffc0204db6 <user_main>
ffffffffc0204796:	c7dff0ef          	jal	ra,ffffffffc0204412 <kernel_thread>
    if (pid <= 0)
ffffffffc020479a:	00a04563          	bgtz	a0,ffffffffc02047a4 <init_main+0x26>
ffffffffc020479e:	a071                	j	ffffffffc020482a <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02047a0:	7eb000ef          	jal	ra,ffffffffc020578a <schedule>
    if (code_store != NULL)
ffffffffc02047a4:	4581                	li	a1,0
ffffffffc02047a6:	4501                	li	a0,0
ffffffffc02047a8:	e05ff0ef          	jal	ra,ffffffffc02045ac <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02047ac:	d975                	beqz	a0,ffffffffc02047a0 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02047ae:	00003517          	auipc	a0,0x3
ffffffffc02047b2:	f9a50513          	addi	a0,a0,-102 # ffffffffc0207748 <default_pmm_manager+0xaa8>
ffffffffc02047b6:	9e3fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02047ba:	000c2797          	auipc	a5,0xc2
ffffffffc02047be:	4367b783          	ld	a5,1078(a5) # ffffffffc02c6bf0 <initproc>
ffffffffc02047c2:	7bf8                	ld	a4,240(a5)
ffffffffc02047c4:	e339                	bnez	a4,ffffffffc020480a <init_main+0x8c>
ffffffffc02047c6:	7ff8                	ld	a4,248(a5)
ffffffffc02047c8:	e329                	bnez	a4,ffffffffc020480a <init_main+0x8c>
ffffffffc02047ca:	1007b703          	ld	a4,256(a5)
ffffffffc02047ce:	ef15                	bnez	a4,ffffffffc020480a <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc02047d0:	000c2697          	auipc	a3,0xc2
ffffffffc02047d4:	4286a683          	lw	a3,1064(a3) # ffffffffc02c6bf8 <nr_process>
ffffffffc02047d8:	4709                	li	a4,2
ffffffffc02047da:	0ae69463          	bne	a3,a4,ffffffffc0204882 <init_main+0x104>
    return listelm->next;
ffffffffc02047de:	000c2697          	auipc	a3,0xc2
ffffffffc02047e2:	35a68693          	addi	a3,a3,858 # ffffffffc02c6b38 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02047e6:	6698                	ld	a4,8(a3)
ffffffffc02047e8:	0c878793          	addi	a5,a5,200
ffffffffc02047ec:	06f71b63          	bne	a4,a5,ffffffffc0204862 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02047f0:	629c                	ld	a5,0(a3)
ffffffffc02047f2:	04f71863          	bne	a4,a5,ffffffffc0204842 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc02047f6:	00003517          	auipc	a0,0x3
ffffffffc02047fa:	03a50513          	addi	a0,a0,58 # ffffffffc0207830 <default_pmm_manager+0xb90>
ffffffffc02047fe:	99bfb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;
}
ffffffffc0204802:	60a2                	ld	ra,8(sp)
ffffffffc0204804:	4501                	li	a0,0
ffffffffc0204806:	0141                	addi	sp,sp,16
ffffffffc0204808:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020480a:	00003697          	auipc	a3,0x3
ffffffffc020480e:	f6668693          	addi	a3,a3,-154 # ffffffffc0207770 <default_pmm_manager+0xad0>
ffffffffc0204812:	00002617          	auipc	a2,0x2
ffffffffc0204816:	0de60613          	addi	a2,a2,222 # ffffffffc02068f0 <commands+0x868>
ffffffffc020481a:	3b300593          	li	a1,947
ffffffffc020481e:	00003517          	auipc	a0,0x3
ffffffffc0204822:	e9250513          	addi	a0,a0,-366 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc0204826:	c6dfb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("create user_main failed.\n");
ffffffffc020482a:	00003617          	auipc	a2,0x3
ffffffffc020482e:	efe60613          	addi	a2,a2,-258 # ffffffffc0207728 <default_pmm_manager+0xa88>
ffffffffc0204832:	3aa00593          	li	a1,938
ffffffffc0204836:	00003517          	auipc	a0,0x3
ffffffffc020483a:	e7a50513          	addi	a0,a0,-390 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc020483e:	c55fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204842:	00003697          	auipc	a3,0x3
ffffffffc0204846:	fbe68693          	addi	a3,a3,-66 # ffffffffc0207800 <default_pmm_manager+0xb60>
ffffffffc020484a:	00002617          	auipc	a2,0x2
ffffffffc020484e:	0a660613          	addi	a2,a2,166 # ffffffffc02068f0 <commands+0x868>
ffffffffc0204852:	3b600593          	li	a1,950
ffffffffc0204856:	00003517          	auipc	a0,0x3
ffffffffc020485a:	e5a50513          	addi	a0,a0,-422 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc020485e:	c35fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204862:	00003697          	auipc	a3,0x3
ffffffffc0204866:	f6e68693          	addi	a3,a3,-146 # ffffffffc02077d0 <default_pmm_manager+0xb30>
ffffffffc020486a:	00002617          	auipc	a2,0x2
ffffffffc020486e:	08660613          	addi	a2,a2,134 # ffffffffc02068f0 <commands+0x868>
ffffffffc0204872:	3b500593          	li	a1,949
ffffffffc0204876:	00003517          	auipc	a0,0x3
ffffffffc020487a:	e3a50513          	addi	a0,a0,-454 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc020487e:	c15fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_process == 2);
ffffffffc0204882:	00003697          	auipc	a3,0x3
ffffffffc0204886:	f3e68693          	addi	a3,a3,-194 # ffffffffc02077c0 <default_pmm_manager+0xb20>
ffffffffc020488a:	00002617          	auipc	a2,0x2
ffffffffc020488e:	06660613          	addi	a2,a2,102 # ffffffffc02068f0 <commands+0x868>
ffffffffc0204892:	3b400593          	li	a1,948
ffffffffc0204896:	00003517          	auipc	a0,0x3
ffffffffc020489a:	e1a50513          	addi	a0,a0,-486 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc020489e:	bf5fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02048a2 <do_execve>:
{
ffffffffc02048a2:	7171                	addi	sp,sp,-176
ffffffffc02048a4:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02048a6:	000c2d97          	auipc	s11,0xc2
ffffffffc02048aa:	33ad8d93          	addi	s11,s11,826 # ffffffffc02c6be0 <current>
ffffffffc02048ae:	000db783          	ld	a5,0(s11)
{
ffffffffc02048b2:	e54e                	sd	s3,136(sp)
ffffffffc02048b4:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02048b6:	0287b983          	ld	s3,40(a5)
{
ffffffffc02048ba:	e94a                	sd	s2,144(sp)
ffffffffc02048bc:	f4de                	sd	s7,104(sp)
ffffffffc02048be:	892a                	mv	s2,a0
ffffffffc02048c0:	8bb2                	mv	s7,a2
ffffffffc02048c2:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02048c4:	862e                	mv	a2,a1
ffffffffc02048c6:	4681                	li	a3,0
ffffffffc02048c8:	85aa                	mv	a1,a0
ffffffffc02048ca:	854e                	mv	a0,s3
{
ffffffffc02048cc:	f506                	sd	ra,168(sp)
ffffffffc02048ce:	f122                	sd	s0,160(sp)
ffffffffc02048d0:	e152                	sd	s4,128(sp)
ffffffffc02048d2:	fcd6                	sd	s5,120(sp)
ffffffffc02048d4:	f8da                	sd	s6,112(sp)
ffffffffc02048d6:	f0e2                	sd	s8,96(sp)
ffffffffc02048d8:	ece6                	sd	s9,88(sp)
ffffffffc02048da:	e8ea                	sd	s10,80(sp)
ffffffffc02048dc:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02048de:	d1aff0ef          	jal	ra,ffffffffc0203df8 <user_mem_check>
ffffffffc02048e2:	40050a63          	beqz	a0,ffffffffc0204cf6 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02048e6:	4641                	li	a2,16
ffffffffc02048e8:	4581                	li	a1,0
ffffffffc02048ea:	1808                	addi	a0,sp,48
ffffffffc02048ec:	504010ef          	jal	ra,ffffffffc0205df0 <memset>
    memcpy(local_name, name, len);
ffffffffc02048f0:	47bd                	li	a5,15
ffffffffc02048f2:	8626                	mv	a2,s1
ffffffffc02048f4:	1e97e263          	bltu	a5,s1,ffffffffc0204ad8 <do_execve+0x236>
ffffffffc02048f8:	85ca                	mv	a1,s2
ffffffffc02048fa:	1808                	addi	a0,sp,48
ffffffffc02048fc:	506010ef          	jal	ra,ffffffffc0205e02 <memcpy>
    if (mm != NULL)
ffffffffc0204900:	1e098363          	beqz	s3,ffffffffc0204ae6 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0204904:	00003517          	auipc	a0,0x3
ffffffffc0204908:	bac50513          	addi	a0,a0,-1108 # ffffffffc02074b0 <default_pmm_manager+0x810>
ffffffffc020490c:	8c5fb0ef          	jal	ra,ffffffffc02001d0 <cputs>
ffffffffc0204910:	000c2797          	auipc	a5,0xc2
ffffffffc0204914:	2987b783          	ld	a5,664(a5) # ffffffffc02c6ba8 <boot_pgdir_pa>
ffffffffc0204918:	577d                	li	a4,-1
ffffffffc020491a:	177e                	slli	a4,a4,0x3f
ffffffffc020491c:	83b1                	srli	a5,a5,0xc
ffffffffc020491e:	8fd9                	or	a5,a5,a4
ffffffffc0204920:	18079073          	csrw	satp,a5
ffffffffc0204924:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7f10>
ffffffffc0204928:	fff7871b          	addiw	a4,a5,-1
ffffffffc020492c:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204930:	2c070463          	beqz	a4,ffffffffc0204bf8 <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204934:	000db783          	ld	a5,0(s11)
ffffffffc0204938:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc020493c:	c7bfe0ef          	jal	ra,ffffffffc02035b6 <mm_create>
ffffffffc0204940:	84aa                	mv	s1,a0
ffffffffc0204942:	1c050d63          	beqz	a0,ffffffffc0204b1c <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204946:	4505                	li	a0,1
ffffffffc0204948:	d14fd0ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc020494c:	3a050963          	beqz	a0,ffffffffc0204cfe <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0204950:	000c2c97          	auipc	s9,0xc2
ffffffffc0204954:	270c8c93          	addi	s9,s9,624 # ffffffffc02c6bc0 <pages>
ffffffffc0204958:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc020495c:	000c2c17          	auipc	s8,0xc2
ffffffffc0204960:	25cc0c13          	addi	s8,s8,604 # ffffffffc02c6bb8 <npage>
    return page - pages + nbase;
ffffffffc0204964:	00004717          	auipc	a4,0x4
ffffffffc0204968:	d5c73703          	ld	a4,-676(a4) # ffffffffc02086c0 <nbase>
ffffffffc020496c:	40d506b3          	sub	a3,a0,a3
ffffffffc0204970:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204972:	5afd                	li	s5,-1
ffffffffc0204974:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204978:	96ba                	add	a3,a3,a4
ffffffffc020497a:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc020497c:	00cad713          	srli	a4,s5,0xc
ffffffffc0204980:	ec3a                	sd	a4,24(sp)
ffffffffc0204982:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204984:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204986:	38f77063          	bgeu	a4,a5,ffffffffc0204d06 <do_execve+0x464>
ffffffffc020498a:	000c2b17          	auipc	s6,0xc2
ffffffffc020498e:	246b0b13          	addi	s6,s6,582 # ffffffffc02c6bd0 <va_pa_offset>
ffffffffc0204992:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204996:	6605                	lui	a2,0x1
ffffffffc0204998:	000c2597          	auipc	a1,0xc2
ffffffffc020499c:	2185b583          	ld	a1,536(a1) # ffffffffc02c6bb0 <boot_pgdir_va>
ffffffffc02049a0:	9936                	add	s2,s2,a3
ffffffffc02049a2:	854a                	mv	a0,s2
ffffffffc02049a4:	45e010ef          	jal	ra,ffffffffc0205e02 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02049a8:	7782                	ld	a5,32(sp)
ffffffffc02049aa:	4398                	lw	a4,0(a5)
ffffffffc02049ac:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc02049b0:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02049b4:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_matrix_out_size+0x464b7e6f>
ffffffffc02049b8:	14f71863          	bne	a4,a5,ffffffffc0204b08 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02049bc:	7682                	ld	a3,32(sp)
ffffffffc02049be:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02049c2:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02049c6:	00371793          	slli	a5,a4,0x3
ffffffffc02049ca:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02049cc:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02049ce:	078e                	slli	a5,a5,0x3
ffffffffc02049d0:	97ce                	add	a5,a5,s3
ffffffffc02049d2:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc02049d4:	00f9fc63          	bgeu	s3,a5,ffffffffc02049ec <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc02049d8:	0009a783          	lw	a5,0(s3)
ffffffffc02049dc:	4705                	li	a4,1
ffffffffc02049de:	14e78163          	beq	a5,a4,ffffffffc0204b20 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc02049e2:	77a2                	ld	a5,40(sp)
ffffffffc02049e4:	03898993          	addi	s3,s3,56
ffffffffc02049e8:	fef9e8e3          	bltu	s3,a5,ffffffffc02049d8 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc02049ec:	4701                	li	a4,0
ffffffffc02049ee:	46ad                	li	a3,11
ffffffffc02049f0:	00100637          	lui	a2,0x100
ffffffffc02049f4:	7ff005b7          	lui	a1,0x7ff00
ffffffffc02049f8:	8526                	mv	a0,s1
ffffffffc02049fa:	d4ffe0ef          	jal	ra,ffffffffc0203748 <mm_map>
ffffffffc02049fe:	8a2a                	mv	s4,a0
ffffffffc0204a00:	1e051263          	bnez	a0,ffffffffc0204be4 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204a04:	6c88                	ld	a0,24(s1)
ffffffffc0204a06:	467d                	li	a2,31
ffffffffc0204a08:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204a0c:	ac5fe0ef          	jal	ra,ffffffffc02034d0 <pgdir_alloc_page>
ffffffffc0204a10:	38050363          	beqz	a0,ffffffffc0204d96 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a14:	6c88                	ld	a0,24(s1)
ffffffffc0204a16:	467d                	li	a2,31
ffffffffc0204a18:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204a1c:	ab5fe0ef          	jal	ra,ffffffffc02034d0 <pgdir_alloc_page>
ffffffffc0204a20:	34050b63          	beqz	a0,ffffffffc0204d76 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a24:	6c88                	ld	a0,24(s1)
ffffffffc0204a26:	467d                	li	a2,31
ffffffffc0204a28:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204a2c:	aa5fe0ef          	jal	ra,ffffffffc02034d0 <pgdir_alloc_page>
ffffffffc0204a30:	32050363          	beqz	a0,ffffffffc0204d56 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a34:	6c88                	ld	a0,24(s1)
ffffffffc0204a36:	467d                	li	a2,31
ffffffffc0204a38:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204a3c:	a95fe0ef          	jal	ra,ffffffffc02034d0 <pgdir_alloc_page>
ffffffffc0204a40:	2e050b63          	beqz	a0,ffffffffc0204d36 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204a44:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204a46:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204a4a:	6c94                	ld	a3,24(s1)
ffffffffc0204a4c:	2785                	addiw	a5,a5,1
ffffffffc0204a4e:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0204a50:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204a52:	c02007b7          	lui	a5,0xc0200
ffffffffc0204a56:	2cf6e463          	bltu	a3,a5,ffffffffc0204d1e <do_execve+0x47c>
ffffffffc0204a5a:	000b3783          	ld	a5,0(s6)
ffffffffc0204a5e:	577d                	li	a4,-1
ffffffffc0204a60:	177e                	slli	a4,a4,0x3f
ffffffffc0204a62:	8e9d                	sub	a3,a3,a5
ffffffffc0204a64:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204a68:	f654                	sd	a3,168(a2)
ffffffffc0204a6a:	8fd9                	or	a5,a5,a4
ffffffffc0204a6c:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204a70:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204a72:	4581                	li	a1,0
ffffffffc0204a74:	12000613          	li	a2,288
ffffffffc0204a78:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204a7a:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204a7e:	372010ef          	jal	ra,ffffffffc0205df0 <memset>
    tf->epc = elf->e_entry;
ffffffffc0204a82:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a84:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE;
ffffffffc0204a88:	edd4f493          	andi	s1,s1,-291
    tf->epc = elf->e_entry;
ffffffffc0204a8c:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204a8e:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a90:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_matrix_out_size+0xffffffff7fff39a4>
    tf->gpr.sp = USTACKTOP;
ffffffffc0204a94:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE;
ffffffffc0204a96:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a9a:	4641                	li	a2,16
ffffffffc0204a9c:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc0204a9e:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0204aa0:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE;
ffffffffc0204aa4:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204aa8:	854a                	mv	a0,s2
ffffffffc0204aaa:	346010ef          	jal	ra,ffffffffc0205df0 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204aae:	463d                	li	a2,15
ffffffffc0204ab0:	180c                	addi	a1,sp,48
ffffffffc0204ab2:	854a                	mv	a0,s2
ffffffffc0204ab4:	34e010ef          	jal	ra,ffffffffc0205e02 <memcpy>
}
ffffffffc0204ab8:	70aa                	ld	ra,168(sp)
ffffffffc0204aba:	740a                	ld	s0,160(sp)
ffffffffc0204abc:	64ea                	ld	s1,152(sp)
ffffffffc0204abe:	694a                	ld	s2,144(sp)
ffffffffc0204ac0:	69aa                	ld	s3,136(sp)
ffffffffc0204ac2:	7ae6                	ld	s5,120(sp)
ffffffffc0204ac4:	7b46                	ld	s6,112(sp)
ffffffffc0204ac6:	7ba6                	ld	s7,104(sp)
ffffffffc0204ac8:	7c06                	ld	s8,96(sp)
ffffffffc0204aca:	6ce6                	ld	s9,88(sp)
ffffffffc0204acc:	6d46                	ld	s10,80(sp)
ffffffffc0204ace:	6da6                	ld	s11,72(sp)
ffffffffc0204ad0:	8552                	mv	a0,s4
ffffffffc0204ad2:	6a0a                	ld	s4,128(sp)
ffffffffc0204ad4:	614d                	addi	sp,sp,176
ffffffffc0204ad6:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204ad8:	463d                	li	a2,15
ffffffffc0204ada:	85ca                	mv	a1,s2
ffffffffc0204adc:	1808                	addi	a0,sp,48
ffffffffc0204ade:	324010ef          	jal	ra,ffffffffc0205e02 <memcpy>
    if (mm != NULL)
ffffffffc0204ae2:	e20991e3          	bnez	s3,ffffffffc0204904 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204ae6:	000db783          	ld	a5,0(s11)
ffffffffc0204aea:	779c                	ld	a5,40(a5)
ffffffffc0204aec:	e40788e3          	beqz	a5,ffffffffc020493c <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204af0:	00003617          	auipc	a2,0x3
ffffffffc0204af4:	d6060613          	addi	a2,a2,-672 # ffffffffc0207850 <default_pmm_manager+0xbb0>
ffffffffc0204af8:	23100593          	li	a1,561
ffffffffc0204afc:	00003517          	auipc	a0,0x3
ffffffffc0204b00:	bb450513          	addi	a0,a0,-1100 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc0204b04:	98ffb0ef          	jal	ra,ffffffffc0200492 <__panic>
    put_pgdir(mm);
ffffffffc0204b08:	8526                	mv	a0,s1
ffffffffc0204b0a:	c4cff0ef          	jal	ra,ffffffffc0203f56 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204b0e:	8526                	mv	a0,s1
ffffffffc0204b10:	be7fe0ef          	jal	ra,ffffffffc02036f6 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204b14:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0204b16:	8552                	mv	a0,s4
ffffffffc0204b18:	94bff0ef          	jal	ra,ffffffffc0204462 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204b1c:	5a71                	li	s4,-4
ffffffffc0204b1e:	bfe5                	j	ffffffffc0204b16 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204b20:	0289b603          	ld	a2,40(s3)
ffffffffc0204b24:	0209b783          	ld	a5,32(s3)
ffffffffc0204b28:	1cf66d63          	bltu	a2,a5,ffffffffc0204d02 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204b2c:	0049a783          	lw	a5,4(s3)
ffffffffc0204b30:	0017f693          	andi	a3,a5,1
ffffffffc0204b34:	c291                	beqz	a3,ffffffffc0204b38 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204b36:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204b38:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b3c:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204b3e:	e779                	bnez	a4,ffffffffc0204c0c <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204b40:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b42:	c781                	beqz	a5,ffffffffc0204b4a <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204b44:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204b48:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204b4a:	0026f793          	andi	a5,a3,2
ffffffffc0204b4e:	e3f1                	bnez	a5,ffffffffc0204c12 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204b50:	0046f793          	andi	a5,a3,4
ffffffffc0204b54:	c399                	beqz	a5,ffffffffc0204b5a <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204b56:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204b5a:	0109b583          	ld	a1,16(s3)
ffffffffc0204b5e:	4701                	li	a4,0
ffffffffc0204b60:	8526                	mv	a0,s1
ffffffffc0204b62:	be7fe0ef          	jal	ra,ffffffffc0203748 <mm_map>
ffffffffc0204b66:	8a2a                	mv	s4,a0
ffffffffc0204b68:	ed35                	bnez	a0,ffffffffc0204be4 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b6a:	0109bb83          	ld	s7,16(s3)
ffffffffc0204b6e:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204b70:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b74:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b78:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b7c:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204b7e:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b80:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204b82:	054be963          	bltu	s7,s4,ffffffffc0204bd4 <do_execve+0x332>
ffffffffc0204b86:	aa95                	j	ffffffffc0204cfa <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b88:	6785                	lui	a5,0x1
ffffffffc0204b8a:	415b8533          	sub	a0,s7,s5
ffffffffc0204b8e:	9abe                	add	s5,s5,a5
ffffffffc0204b90:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204b94:	015a7463          	bgeu	s4,s5,ffffffffc0204b9c <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204b98:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204b9c:	000cb683          	ld	a3,0(s9)
ffffffffc0204ba0:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204ba2:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204ba6:	40d406b3          	sub	a3,s0,a3
ffffffffc0204baa:	8699                	srai	a3,a3,0x6
ffffffffc0204bac:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204bae:	67e2                	ld	a5,24(sp)
ffffffffc0204bb0:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204bb4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204bb6:	14b87863          	bgeu	a6,a1,ffffffffc0204d06 <do_execve+0x464>
ffffffffc0204bba:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204bbe:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204bc0:	9bb2                	add	s7,s7,a2
ffffffffc0204bc2:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204bc4:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204bc6:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204bc8:	23a010ef          	jal	ra,ffffffffc0205e02 <memcpy>
            start += size, from += size;
ffffffffc0204bcc:	6622                	ld	a2,8(sp)
ffffffffc0204bce:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204bd0:	054bf363          	bgeu	s7,s4,ffffffffc0204c16 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204bd4:	6c88                	ld	a0,24(s1)
ffffffffc0204bd6:	866a                	mv	a2,s10
ffffffffc0204bd8:	85d6                	mv	a1,s5
ffffffffc0204bda:	8f7fe0ef          	jal	ra,ffffffffc02034d0 <pgdir_alloc_page>
ffffffffc0204bde:	842a                	mv	s0,a0
ffffffffc0204be0:	f545                	bnez	a0,ffffffffc0204b88 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204be2:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204be4:	8526                	mv	a0,s1
ffffffffc0204be6:	cadfe0ef          	jal	ra,ffffffffc0203892 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204bea:	8526                	mv	a0,s1
ffffffffc0204bec:	b6aff0ef          	jal	ra,ffffffffc0203f56 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204bf0:	8526                	mv	a0,s1
ffffffffc0204bf2:	b05fe0ef          	jal	ra,ffffffffc02036f6 <mm_destroy>
    return ret;
ffffffffc0204bf6:	b705                	j	ffffffffc0204b16 <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204bf8:	854e                	mv	a0,s3
ffffffffc0204bfa:	c99fe0ef          	jal	ra,ffffffffc0203892 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204bfe:	854e                	mv	a0,s3
ffffffffc0204c00:	b56ff0ef          	jal	ra,ffffffffc0203f56 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204c04:	854e                	mv	a0,s3
ffffffffc0204c06:	af1fe0ef          	jal	ra,ffffffffc02036f6 <mm_destroy>
ffffffffc0204c0a:	b32d                	j	ffffffffc0204934 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204c0c:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c10:	fb95                	bnez	a5,ffffffffc0204b44 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204c12:	4d5d                	li	s10,23
ffffffffc0204c14:	bf35                	j	ffffffffc0204b50 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204c16:	0109b683          	ld	a3,16(s3)
ffffffffc0204c1a:	0289b903          	ld	s2,40(s3)
ffffffffc0204c1e:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204c20:	075bfd63          	bgeu	s7,s5,ffffffffc0204c9a <do_execve+0x3f8>
            if (start == end)
ffffffffc0204c24:	db790fe3          	beq	s2,s7,ffffffffc02049e2 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204c28:	6785                	lui	a5,0x1
ffffffffc0204c2a:	00fb8533          	add	a0,s7,a5
ffffffffc0204c2e:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204c32:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204c36:	0b597d63          	bgeu	s2,s5,ffffffffc0204cf0 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204c3a:	000cb683          	ld	a3,0(s9)
ffffffffc0204c3e:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204c40:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204c44:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c48:	8699                	srai	a3,a3,0x6
ffffffffc0204c4a:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204c4c:	67e2                	ld	a5,24(sp)
ffffffffc0204c4e:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c52:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c54:	0ac5f963          	bgeu	a1,a2,ffffffffc0204d06 <do_execve+0x464>
ffffffffc0204c58:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c5c:	8652                	mv	a2,s4
ffffffffc0204c5e:	4581                	li	a1,0
ffffffffc0204c60:	96c2                	add	a3,a3,a6
ffffffffc0204c62:	9536                	add	a0,a0,a3
ffffffffc0204c64:	18c010ef          	jal	ra,ffffffffc0205df0 <memset>
            start += size;
ffffffffc0204c68:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204c6c:	03597463          	bgeu	s2,s5,ffffffffc0204c94 <do_execve+0x3f2>
ffffffffc0204c70:	d6e909e3          	beq	s2,a4,ffffffffc02049e2 <do_execve+0x140>
ffffffffc0204c74:	00003697          	auipc	a3,0x3
ffffffffc0204c78:	c0468693          	addi	a3,a3,-1020 # ffffffffc0207878 <default_pmm_manager+0xbd8>
ffffffffc0204c7c:	00002617          	auipc	a2,0x2
ffffffffc0204c80:	c7460613          	addi	a2,a2,-908 # ffffffffc02068f0 <commands+0x868>
ffffffffc0204c84:	29a00593          	li	a1,666
ffffffffc0204c88:	00003517          	auipc	a0,0x3
ffffffffc0204c8c:	a2850513          	addi	a0,a0,-1496 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc0204c90:	803fb0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0204c94:	ff5710e3          	bne	a4,s5,ffffffffc0204c74 <do_execve+0x3d2>
ffffffffc0204c98:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204c9a:	d52bf4e3          	bgeu	s7,s2,ffffffffc02049e2 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204c9e:	6c88                	ld	a0,24(s1)
ffffffffc0204ca0:	866a                	mv	a2,s10
ffffffffc0204ca2:	85d6                	mv	a1,s5
ffffffffc0204ca4:	82dfe0ef          	jal	ra,ffffffffc02034d0 <pgdir_alloc_page>
ffffffffc0204ca8:	842a                	mv	s0,a0
ffffffffc0204caa:	dd05                	beqz	a0,ffffffffc0204be2 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204cac:	6785                	lui	a5,0x1
ffffffffc0204cae:	415b8533          	sub	a0,s7,s5
ffffffffc0204cb2:	9abe                	add	s5,s5,a5
ffffffffc0204cb4:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204cb8:	01597463          	bgeu	s2,s5,ffffffffc0204cc0 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204cbc:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204cc0:	000cb683          	ld	a3,0(s9)
ffffffffc0204cc4:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204cc6:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204cca:	40d406b3          	sub	a3,s0,a3
ffffffffc0204cce:	8699                	srai	a3,a3,0x6
ffffffffc0204cd0:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204cd2:	67e2                	ld	a5,24(sp)
ffffffffc0204cd4:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204cd8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204cda:	02b87663          	bgeu	a6,a1,ffffffffc0204d06 <do_execve+0x464>
ffffffffc0204cde:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204ce2:	4581                	li	a1,0
            start += size;
ffffffffc0204ce4:	9bb2                	add	s7,s7,a2
ffffffffc0204ce6:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204ce8:	9536                	add	a0,a0,a3
ffffffffc0204cea:	106010ef          	jal	ra,ffffffffc0205df0 <memset>
ffffffffc0204cee:	b775                	j	ffffffffc0204c9a <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204cf0:	417a8a33          	sub	s4,s5,s7
ffffffffc0204cf4:	b799                	j	ffffffffc0204c3a <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204cf6:	5a75                	li	s4,-3
ffffffffc0204cf8:	b3c1                	j	ffffffffc0204ab8 <do_execve+0x216>
        while (start < end)
ffffffffc0204cfa:	86de                	mv	a3,s7
ffffffffc0204cfc:	bf39                	j	ffffffffc0204c1a <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204cfe:	5a71                	li	s4,-4
ffffffffc0204d00:	bdc5                	j	ffffffffc0204bf0 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204d02:	5a61                	li	s4,-8
ffffffffc0204d04:	b5c5                	j	ffffffffc0204be4 <do_execve+0x342>
ffffffffc0204d06:	00002617          	auipc	a2,0x2
ffffffffc0204d0a:	fd260613          	addi	a2,a2,-46 # ffffffffc0206cd8 <default_pmm_manager+0x38>
ffffffffc0204d0e:	07100593          	li	a1,113
ffffffffc0204d12:	00002517          	auipc	a0,0x2
ffffffffc0204d16:	fee50513          	addi	a0,a0,-18 # ffffffffc0206d00 <default_pmm_manager+0x60>
ffffffffc0204d1a:	f78fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204d1e:	00002617          	auipc	a2,0x2
ffffffffc0204d22:	06260613          	addi	a2,a2,98 # ffffffffc0206d80 <default_pmm_manager+0xe0>
ffffffffc0204d26:	2b900593          	li	a1,697
ffffffffc0204d2a:	00003517          	auipc	a0,0x3
ffffffffc0204d2e:	98650513          	addi	a0,a0,-1658 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc0204d32:	f60fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d36:	00003697          	auipc	a3,0x3
ffffffffc0204d3a:	c5a68693          	addi	a3,a3,-934 # ffffffffc0207990 <default_pmm_manager+0xcf0>
ffffffffc0204d3e:	00002617          	auipc	a2,0x2
ffffffffc0204d42:	bb260613          	addi	a2,a2,-1102 # ffffffffc02068f0 <commands+0x868>
ffffffffc0204d46:	2b400593          	li	a1,692
ffffffffc0204d4a:	00003517          	auipc	a0,0x3
ffffffffc0204d4e:	96650513          	addi	a0,a0,-1690 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc0204d52:	f40fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d56:	00003697          	auipc	a3,0x3
ffffffffc0204d5a:	bf268693          	addi	a3,a3,-1038 # ffffffffc0207948 <default_pmm_manager+0xca8>
ffffffffc0204d5e:	00002617          	auipc	a2,0x2
ffffffffc0204d62:	b9260613          	addi	a2,a2,-1134 # ffffffffc02068f0 <commands+0x868>
ffffffffc0204d66:	2b300593          	li	a1,691
ffffffffc0204d6a:	00003517          	auipc	a0,0x3
ffffffffc0204d6e:	94650513          	addi	a0,a0,-1722 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc0204d72:	f20fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d76:	00003697          	auipc	a3,0x3
ffffffffc0204d7a:	b8a68693          	addi	a3,a3,-1142 # ffffffffc0207900 <default_pmm_manager+0xc60>
ffffffffc0204d7e:	00002617          	auipc	a2,0x2
ffffffffc0204d82:	b7260613          	addi	a2,a2,-1166 # ffffffffc02068f0 <commands+0x868>
ffffffffc0204d86:	2b200593          	li	a1,690
ffffffffc0204d8a:	00003517          	auipc	a0,0x3
ffffffffc0204d8e:	92650513          	addi	a0,a0,-1754 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc0204d92:	f00fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204d96:	00003697          	auipc	a3,0x3
ffffffffc0204d9a:	b2268693          	addi	a3,a3,-1246 # ffffffffc02078b8 <default_pmm_manager+0xc18>
ffffffffc0204d9e:	00002617          	auipc	a2,0x2
ffffffffc0204da2:	b5260613          	addi	a2,a2,-1198 # ffffffffc02068f0 <commands+0x868>
ffffffffc0204da6:	2b100593          	li	a1,689
ffffffffc0204daa:	00003517          	auipc	a0,0x3
ffffffffc0204dae:	90650513          	addi	a0,a0,-1786 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc0204db2:	ee0fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204db6 <user_main>:
{
ffffffffc0204db6:	1101                	addi	sp,sp,-32
ffffffffc0204db8:	e04a                	sd	s2,0(sp)
    KERNEL_EXECVE(priority);
ffffffffc0204dba:	000c2917          	auipc	s2,0xc2
ffffffffc0204dbe:	e2690913          	addi	s2,s2,-474 # ffffffffc02c6be0 <current>
ffffffffc0204dc2:	00093783          	ld	a5,0(s2)
ffffffffc0204dc6:	00003617          	auipc	a2,0x3
ffffffffc0204dca:	c1260613          	addi	a2,a2,-1006 # ffffffffc02079d8 <default_pmm_manager+0xd38>
ffffffffc0204dce:	00003517          	auipc	a0,0x3
ffffffffc0204dd2:	c1a50513          	addi	a0,a0,-998 # ffffffffc02079e8 <default_pmm_manager+0xd48>
ffffffffc0204dd6:	43cc                	lw	a1,4(a5)
{
ffffffffc0204dd8:	ec06                	sd	ra,24(sp)
ffffffffc0204dda:	e822                	sd	s0,16(sp)
ffffffffc0204ddc:	e426                	sd	s1,8(sp)
    KERNEL_EXECVE(priority);
ffffffffc0204dde:	bbafb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    size_t len = strlen(name);
ffffffffc0204de2:	00003517          	auipc	a0,0x3
ffffffffc0204de6:	bf650513          	addi	a0,a0,-1034 # ffffffffc02079d8 <default_pmm_manager+0xd38>
ffffffffc0204dea:	765000ef          	jal	ra,ffffffffc0205d4e <strlen>
    struct trapframe *old_tf = current->tf;
ffffffffc0204dee:	00093783          	ld	a5,0(s2)
    size_t len = strlen(name);
ffffffffc0204df2:	84aa                	mv	s1,a0
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204df4:	12000613          	li	a2,288
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204df8:	6b80                	ld	s0,16(a5)
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204dfa:	73cc                	ld	a1,160(a5)
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204dfc:	6789                	lui	a5,0x2
ffffffffc0204dfe:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8060>
ffffffffc0204e02:	943e                	add	s0,s0,a5
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204e04:	8522                	mv	a0,s0
ffffffffc0204e06:	7fd000ef          	jal	ra,ffffffffc0205e02 <memcpy>
    current->tf = new_tf;
ffffffffc0204e0a:	00093783          	ld	a5,0(s2)
    ret = do_execve(name, len, binary, size);
ffffffffc0204e0e:	3fe07697          	auipc	a3,0x3fe07
ffffffffc0204e12:	93268693          	addi	a3,a3,-1742 # b740 <_binary_obj___user_priority_out_size>
ffffffffc0204e16:	0007d617          	auipc	a2,0x7d
ffffffffc0204e1a:	f0260613          	addi	a2,a2,-254 # ffffffffc0281d18 <_binary_obj___user_priority_out_start>
    current->tf = new_tf;
ffffffffc0204e1e:	f3c0                	sd	s0,160(a5)
    ret = do_execve(name, len, binary, size);
ffffffffc0204e20:	85a6                	mv	a1,s1
ffffffffc0204e22:	00003517          	auipc	a0,0x3
ffffffffc0204e26:	bb650513          	addi	a0,a0,-1098 # ffffffffc02079d8 <default_pmm_manager+0xd38>
ffffffffc0204e2a:	a79ff0ef          	jal	ra,ffffffffc02048a2 <do_execve>
    asm volatile(
ffffffffc0204e2e:	8122                	mv	sp,s0
ffffffffc0204e30:	910fc06f          	j	ffffffffc0200f40 <__trapret>
    panic("user_main execve failed.\n");
ffffffffc0204e34:	00003617          	auipc	a2,0x3
ffffffffc0204e38:	bdc60613          	addi	a2,a2,-1060 # ffffffffc0207a10 <default_pmm_manager+0xd70>
ffffffffc0204e3c:	39d00593          	li	a1,925
ffffffffc0204e40:	00003517          	auipc	a0,0x3
ffffffffc0204e44:	87050513          	addi	a0,a0,-1936 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc0204e48:	e4afb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204e4c <do_yield>:
    current->need_resched = 1;
ffffffffc0204e4c:	000c2797          	auipc	a5,0xc2
ffffffffc0204e50:	d947b783          	ld	a5,-620(a5) # ffffffffc02c6be0 <current>
ffffffffc0204e54:	4705                	li	a4,1
ffffffffc0204e56:	ef98                	sd	a4,24(a5)
}
ffffffffc0204e58:	4501                	li	a0,0
ffffffffc0204e5a:	8082                	ret

ffffffffc0204e5c <do_wait>:
{
ffffffffc0204e5c:	1101                	addi	sp,sp,-32
ffffffffc0204e5e:	e822                	sd	s0,16(sp)
ffffffffc0204e60:	e426                	sd	s1,8(sp)
ffffffffc0204e62:	ec06                	sd	ra,24(sp)
ffffffffc0204e64:	842e                	mv	s0,a1
ffffffffc0204e66:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204e68:	c999                	beqz	a1,ffffffffc0204e7e <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204e6a:	000c2797          	auipc	a5,0xc2
ffffffffc0204e6e:	d767b783          	ld	a5,-650(a5) # ffffffffc02c6be0 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204e72:	7788                	ld	a0,40(a5)
ffffffffc0204e74:	4685                	li	a3,1
ffffffffc0204e76:	4611                	li	a2,4
ffffffffc0204e78:	f81fe0ef          	jal	ra,ffffffffc0203df8 <user_mem_check>
ffffffffc0204e7c:	c909                	beqz	a0,ffffffffc0204e8e <do_wait+0x32>
ffffffffc0204e7e:	85a2                	mv	a1,s0
}
ffffffffc0204e80:	6442                	ld	s0,16(sp)
ffffffffc0204e82:	60e2                	ld	ra,24(sp)
ffffffffc0204e84:	8526                	mv	a0,s1
ffffffffc0204e86:	64a2                	ld	s1,8(sp)
ffffffffc0204e88:	6105                	addi	sp,sp,32
ffffffffc0204e8a:	f22ff06f          	j	ffffffffc02045ac <do_wait.part.0>
ffffffffc0204e8e:	60e2                	ld	ra,24(sp)
ffffffffc0204e90:	6442                	ld	s0,16(sp)
ffffffffc0204e92:	64a2                	ld	s1,8(sp)
ffffffffc0204e94:	5575                	li	a0,-3
ffffffffc0204e96:	6105                	addi	sp,sp,32
ffffffffc0204e98:	8082                	ret

ffffffffc0204e9a <do_kill>:
{
ffffffffc0204e9a:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e9c:	6789                	lui	a5,0x2
{
ffffffffc0204e9e:	e406                	sd	ra,8(sp)
ffffffffc0204ea0:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204ea2:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204ea6:	17f9                	addi	a5,a5,-2
ffffffffc0204ea8:	02e7e963          	bltu	a5,a4,ffffffffc0204eda <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204eac:	842a                	mv	s0,a0
ffffffffc0204eae:	45a9                	li	a1,10
ffffffffc0204eb0:	2501                	sext.w	a0,a0
ffffffffc0204eb2:	299000ef          	jal	ra,ffffffffc020594a <hash32>
ffffffffc0204eb6:	02051793          	slli	a5,a0,0x20
ffffffffc0204eba:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204ebe:	000be797          	auipc	a5,0xbe
ffffffffc0204ec2:	c7a78793          	addi	a5,a5,-902 # ffffffffc02c2b38 <hash_list>
ffffffffc0204ec6:	953e                	add	a0,a0,a5
ffffffffc0204ec8:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204eca:	a029                	j	ffffffffc0204ed4 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204ecc:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204ed0:	00870b63          	beq	a4,s0,ffffffffc0204ee6 <do_kill+0x4c>
ffffffffc0204ed4:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204ed6:	fef51be3          	bne	a0,a5,ffffffffc0204ecc <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204eda:	5475                	li	s0,-3
}
ffffffffc0204edc:	60a2                	ld	ra,8(sp)
ffffffffc0204ede:	8522                	mv	a0,s0
ffffffffc0204ee0:	6402                	ld	s0,0(sp)
ffffffffc0204ee2:	0141                	addi	sp,sp,16
ffffffffc0204ee4:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204ee6:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204eea:	00177693          	andi	a3,a4,1
ffffffffc0204eee:	e295                	bnez	a3,ffffffffc0204f12 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204ef0:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204ef2:	00176713          	ori	a4,a4,1
ffffffffc0204ef6:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204efa:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204efc:	fe06d0e3          	bgez	a3,ffffffffc0204edc <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204f00:	f2878513          	addi	a0,a5,-216
ffffffffc0204f04:	7d4000ef          	jal	ra,ffffffffc02056d8 <wakeup_proc>
}
ffffffffc0204f08:	60a2                	ld	ra,8(sp)
ffffffffc0204f0a:	8522                	mv	a0,s0
ffffffffc0204f0c:	6402                	ld	s0,0(sp)
ffffffffc0204f0e:	0141                	addi	sp,sp,16
ffffffffc0204f10:	8082                	ret
        return -E_KILLED;
ffffffffc0204f12:	545d                	li	s0,-9
ffffffffc0204f14:	b7e1                	j	ffffffffc0204edc <do_kill+0x42>

ffffffffc0204f16 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204f16:	1101                	addi	sp,sp,-32
ffffffffc0204f18:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204f1a:	000c2797          	auipc	a5,0xc2
ffffffffc0204f1e:	c1e78793          	addi	a5,a5,-994 # ffffffffc02c6b38 <proc_list>
ffffffffc0204f22:	ec06                	sd	ra,24(sp)
ffffffffc0204f24:	e822                	sd	s0,16(sp)
ffffffffc0204f26:	e04a                	sd	s2,0(sp)
ffffffffc0204f28:	000be497          	auipc	s1,0xbe
ffffffffc0204f2c:	c1048493          	addi	s1,s1,-1008 # ffffffffc02c2b38 <hash_list>
ffffffffc0204f30:	e79c                	sd	a5,8(a5)
ffffffffc0204f32:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204f34:	000c2717          	auipc	a4,0xc2
ffffffffc0204f38:	c0470713          	addi	a4,a4,-1020 # ffffffffc02c6b38 <proc_list>
ffffffffc0204f3c:	87a6                	mv	a5,s1
ffffffffc0204f3e:	e79c                	sd	a5,8(a5)
ffffffffc0204f40:	e39c                	sd	a5,0(a5)
ffffffffc0204f42:	07c1                	addi	a5,a5,16
ffffffffc0204f44:	fef71de3          	bne	a4,a5,ffffffffc0204f3e <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204f48:	f4dfe0ef          	jal	ra,ffffffffc0203e94 <alloc_proc>
ffffffffc0204f4c:	000c2917          	auipc	s2,0xc2
ffffffffc0204f50:	c9c90913          	addi	s2,s2,-868 # ffffffffc02c6be8 <idleproc>
ffffffffc0204f54:	00a93023          	sd	a0,0(s2)
ffffffffc0204f58:	0e050f63          	beqz	a0,ffffffffc0205056 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204f5c:	4789                	li	a5,2
ffffffffc0204f5e:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204f60:	00004797          	auipc	a5,0x4
ffffffffc0204f64:	0a078793          	addi	a5,a5,160 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f68:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204f6c:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204f6e:	4785                	li	a5,1
ffffffffc0204f70:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f72:	4641                	li	a2,16
ffffffffc0204f74:	4581                	li	a1,0
ffffffffc0204f76:	8522                	mv	a0,s0
ffffffffc0204f78:	679000ef          	jal	ra,ffffffffc0205df0 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204f7c:	463d                	li	a2,15
ffffffffc0204f7e:	00003597          	auipc	a1,0x3
ffffffffc0204f82:	aca58593          	addi	a1,a1,-1334 # ffffffffc0207a48 <default_pmm_manager+0xda8>
ffffffffc0204f86:	8522                	mv	a0,s0
ffffffffc0204f88:	67b000ef          	jal	ra,ffffffffc0205e02 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204f8c:	000c2717          	auipc	a4,0xc2
ffffffffc0204f90:	c6c70713          	addi	a4,a4,-916 # ffffffffc02c6bf8 <nr_process>
ffffffffc0204f94:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204f96:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f9a:	4601                	li	a2,0
    nr_process++;
ffffffffc0204f9c:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f9e:	4581                	li	a1,0
ffffffffc0204fa0:	fffff517          	auipc	a0,0xfffff
ffffffffc0204fa4:	7de50513          	addi	a0,a0,2014 # ffffffffc020477e <init_main>
    nr_process++;
ffffffffc0204fa8:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204faa:	000c2797          	auipc	a5,0xc2
ffffffffc0204fae:	c2d7bb23          	sd	a3,-970(a5) # ffffffffc02c6be0 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204fb2:	c60ff0ef          	jal	ra,ffffffffc0204412 <kernel_thread>
ffffffffc0204fb6:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204fb8:	08a05363          	blez	a0,ffffffffc020503e <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204fbc:	6789                	lui	a5,0x2
ffffffffc0204fbe:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204fc2:	17f9                	addi	a5,a5,-2
ffffffffc0204fc4:	2501                	sext.w	a0,a0
ffffffffc0204fc6:	02e7e363          	bltu	a5,a4,ffffffffc0204fec <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204fca:	45a9                	li	a1,10
ffffffffc0204fcc:	17f000ef          	jal	ra,ffffffffc020594a <hash32>
ffffffffc0204fd0:	02051793          	slli	a5,a0,0x20
ffffffffc0204fd4:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204fd8:	96a6                	add	a3,a3,s1
ffffffffc0204fda:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204fdc:	a029                	j	ffffffffc0204fe6 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0204fde:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x8014>
ffffffffc0204fe2:	04870b63          	beq	a4,s0,ffffffffc0205038 <proc_init+0x122>
    return listelm->next;
ffffffffc0204fe6:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204fe8:	fef69be3          	bne	a3,a5,ffffffffc0204fde <proc_init+0xc8>
    return NULL;
ffffffffc0204fec:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fee:	0b478493          	addi	s1,a5,180
ffffffffc0204ff2:	4641                	li	a2,16
ffffffffc0204ff4:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204ff6:	000c2417          	auipc	s0,0xc2
ffffffffc0204ffa:	bfa40413          	addi	s0,s0,-1030 # ffffffffc02c6bf0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ffe:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0205000:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205002:	5ef000ef          	jal	ra,ffffffffc0205df0 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205006:	463d                	li	a2,15
ffffffffc0205008:	00003597          	auipc	a1,0x3
ffffffffc020500c:	a6858593          	addi	a1,a1,-1432 # ffffffffc0207a70 <default_pmm_manager+0xdd0>
ffffffffc0205010:	8526                	mv	a0,s1
ffffffffc0205012:	5f1000ef          	jal	ra,ffffffffc0205e02 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205016:	00093783          	ld	a5,0(s2)
ffffffffc020501a:	cbb5                	beqz	a5,ffffffffc020508e <proc_init+0x178>
ffffffffc020501c:	43dc                	lw	a5,4(a5)
ffffffffc020501e:	eba5                	bnez	a5,ffffffffc020508e <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205020:	601c                	ld	a5,0(s0)
ffffffffc0205022:	c7b1                	beqz	a5,ffffffffc020506e <proc_init+0x158>
ffffffffc0205024:	43d8                	lw	a4,4(a5)
ffffffffc0205026:	4785                	li	a5,1
ffffffffc0205028:	04f71363          	bne	a4,a5,ffffffffc020506e <proc_init+0x158>
}
ffffffffc020502c:	60e2                	ld	ra,24(sp)
ffffffffc020502e:	6442                	ld	s0,16(sp)
ffffffffc0205030:	64a2                	ld	s1,8(sp)
ffffffffc0205032:	6902                	ld	s2,0(sp)
ffffffffc0205034:	6105                	addi	sp,sp,32
ffffffffc0205036:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205038:	f2878793          	addi	a5,a5,-216
ffffffffc020503c:	bf4d                	j	ffffffffc0204fee <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc020503e:	00003617          	auipc	a2,0x3
ffffffffc0205042:	a1260613          	addi	a2,a2,-1518 # ffffffffc0207a50 <default_pmm_manager+0xdb0>
ffffffffc0205046:	3d900593          	li	a1,985
ffffffffc020504a:	00002517          	auipc	a0,0x2
ffffffffc020504e:	66650513          	addi	a0,a0,1638 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc0205052:	c40fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205056:	00003617          	auipc	a2,0x3
ffffffffc020505a:	9da60613          	addi	a2,a2,-1574 # ffffffffc0207a30 <default_pmm_manager+0xd90>
ffffffffc020505e:	3ca00593          	li	a1,970
ffffffffc0205062:	00002517          	auipc	a0,0x2
ffffffffc0205066:	64e50513          	addi	a0,a0,1614 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc020506a:	c28fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020506e:	00003697          	auipc	a3,0x3
ffffffffc0205072:	a3268693          	addi	a3,a3,-1486 # ffffffffc0207aa0 <default_pmm_manager+0xe00>
ffffffffc0205076:	00002617          	auipc	a2,0x2
ffffffffc020507a:	87a60613          	addi	a2,a2,-1926 # ffffffffc02068f0 <commands+0x868>
ffffffffc020507e:	3e000593          	li	a1,992
ffffffffc0205082:	00002517          	auipc	a0,0x2
ffffffffc0205086:	62e50513          	addi	a0,a0,1582 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc020508a:	c08fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020508e:	00003697          	auipc	a3,0x3
ffffffffc0205092:	9ea68693          	addi	a3,a3,-1558 # ffffffffc0207a78 <default_pmm_manager+0xdd8>
ffffffffc0205096:	00002617          	auipc	a2,0x2
ffffffffc020509a:	85a60613          	addi	a2,a2,-1958 # ffffffffc02068f0 <commands+0x868>
ffffffffc020509e:	3df00593          	li	a1,991
ffffffffc02050a2:	00002517          	auipc	a0,0x2
ffffffffc02050a6:	60e50513          	addi	a0,a0,1550 # ffffffffc02076b0 <default_pmm_manager+0xa10>
ffffffffc02050aa:	be8fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02050ae <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc02050ae:	1141                	addi	sp,sp,-16
ffffffffc02050b0:	e022                	sd	s0,0(sp)
ffffffffc02050b2:	e406                	sd	ra,8(sp)
ffffffffc02050b4:	000c2417          	auipc	s0,0xc2
ffffffffc02050b8:	b2c40413          	addi	s0,s0,-1236 # ffffffffc02c6be0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02050bc:	6018                	ld	a4,0(s0)
ffffffffc02050be:	6f1c                	ld	a5,24(a4)
ffffffffc02050c0:	dffd                	beqz	a5,ffffffffc02050be <cpu_idle+0x10>
        {
            schedule();
ffffffffc02050c2:	6c8000ef          	jal	ra,ffffffffc020578a <schedule>
ffffffffc02050c6:	bfdd                	j	ffffffffc02050bc <cpu_idle+0xe>

ffffffffc02050c8 <lab6_set_priority>:
        }
    }
}
// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority)
{
ffffffffc02050c8:	1141                	addi	sp,sp,-16
ffffffffc02050ca:	e022                	sd	s0,0(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc02050cc:	85aa                	mv	a1,a0
{
ffffffffc02050ce:	842a                	mv	s0,a0
    cprintf("set priority to %d\n", priority);
ffffffffc02050d0:	00003517          	auipc	a0,0x3
ffffffffc02050d4:	9f850513          	addi	a0,a0,-1544 # ffffffffc0207ac8 <default_pmm_manager+0xe28>
{
ffffffffc02050d8:	e406                	sd	ra,8(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc02050da:	8befb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (priority == 0)
        current->lab6_priority = 1;
ffffffffc02050de:	000c2797          	auipc	a5,0xc2
ffffffffc02050e2:	b027b783          	ld	a5,-1278(a5) # ffffffffc02c6be0 <current>
    if (priority == 0)
ffffffffc02050e6:	e801                	bnez	s0,ffffffffc02050f6 <lab6_set_priority+0x2e>
    else
        current->lab6_priority = priority;
}
ffffffffc02050e8:	60a2                	ld	ra,8(sp)
ffffffffc02050ea:	6402                	ld	s0,0(sp)
        current->lab6_priority = 1;
ffffffffc02050ec:	4705                	li	a4,1
ffffffffc02050ee:	14e7a223          	sw	a4,324(a5)
}
ffffffffc02050f2:	0141                	addi	sp,sp,16
ffffffffc02050f4:	8082                	ret
ffffffffc02050f6:	60a2                	ld	ra,8(sp)
        current->lab6_priority = priority;
ffffffffc02050f8:	1487a223          	sw	s0,324(a5)
}
ffffffffc02050fc:	6402                	ld	s0,0(sp)
ffffffffc02050fe:	0141                	addi	sp,sp,16
ffffffffc0205100:	8082                	ret

ffffffffc0205102 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205102:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205106:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc020510a:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020510c:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020510e:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205112:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205116:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc020511a:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020511e:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205122:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205126:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc020512a:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020512e:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205132:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205136:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020513a:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020513e:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205140:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205142:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205146:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc020514a:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020514e:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205152:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205156:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020515a:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020515e:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205162:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205166:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc020516a:	8082                	ret

ffffffffc020516c <stride_init>:
    elm->prev = elm->next = elm;
ffffffffc020516c:	e508                	sd	a0,8(a0)
ffffffffc020516e:	e108                	sd	a0,0(a0)
      * (1) init the ready process list: rq->run_list
      * (2) init the run pool: rq->lab6_run_pool
      * (3) set number of process: rq->proc_num to 0
      */
     list_init(&(rq->run_list));
     rq->lab6_run_pool = NULL;
ffffffffc0205170:	00053c23          	sd	zero,24(a0)
     rq->proc_num = 0;
ffffffffc0205174:	00052823          	sw	zero,16(a0)
}
ffffffffc0205178:	8082                	ret

ffffffffc020517a <stride_pick_next>:
             (1.1) If using skew_heap, we can use le2proc get the p from rq->lab6_run_pol
             (1.2) If using list, we have to search list to find the p with minimum stride value
      * (2) update p;s stride value: p->lab6_stride
      * (3) return p
      */
     if (rq->lab6_run_pool == NULL)
ffffffffc020517a:	6d1c                	ld	a5,24(a0)
ffffffffc020517c:	cf91                	beqz	a5,ffffffffc0205198 <stride_pick_next+0x1e>
     {
          return NULL;
     }
     struct proc_struct *p = le2proc(rq->lab6_run_pool, lab6_run_pool);
     p->lab6_stride += BIG_STRIDE / p->lab6_priority;
ffffffffc020517e:	4fd4                	lw	a3,28(a5)
ffffffffc0205180:	80000737          	lui	a4,0x80000
ffffffffc0205184:	fff74713          	not	a4,a4
ffffffffc0205188:	02d7573b          	divuw	a4,a4,a3
ffffffffc020518c:	4f94                	lw	a3,24(a5)
     struct proc_struct *p = le2proc(rq->lab6_run_pool, lab6_run_pool);
ffffffffc020518e:	ed878513          	addi	a0,a5,-296
     p->lab6_stride += BIG_STRIDE / p->lab6_priority;
ffffffffc0205192:	9f35                	addw	a4,a4,a3
ffffffffc0205194:	cf98                	sw	a4,24(a5)
     return p;
ffffffffc0205196:	8082                	ret
          return NULL;
ffffffffc0205198:	4501                	li	a0,0
}
ffffffffc020519a:	8082                	ret

ffffffffc020519c <stride_proc_tick>:
 */
static void
stride_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: YOUR CODE */
     if (proc->time_slice > 0)
ffffffffc020519c:	1205a783          	lw	a5,288(a1)
ffffffffc02051a0:	00f05563          	blez	a5,ffffffffc02051aa <stride_proc_tick+0xe>
     {
          proc->time_slice--;
ffffffffc02051a4:	37fd                	addiw	a5,a5,-1
ffffffffc02051a6:	12f5a023          	sw	a5,288(a1)
     }
     if (proc->time_slice == 0)
ffffffffc02051aa:	e399                	bnez	a5,ffffffffc02051b0 <stride_proc_tick+0x14>
     {
          proc->need_resched = 1;
ffffffffc02051ac:	4785                	li	a5,1
ffffffffc02051ae:	ed9c                	sd	a5,24(a1)
     }
}
ffffffffc02051b0:	8082                	ret

ffffffffc02051b2 <skew_heap_merge.constprop.0>:
}

static inline skew_heap_entry_t *
skew_heap_merge(skew_heap_entry_t *a, skew_heap_entry_t *b,
ffffffffc02051b2:	7139                	addi	sp,sp,-64
ffffffffc02051b4:	f822                	sd	s0,48(sp)
ffffffffc02051b6:	fc06                	sd	ra,56(sp)
ffffffffc02051b8:	f426                	sd	s1,40(sp)
ffffffffc02051ba:	f04a                	sd	s2,32(sp)
ffffffffc02051bc:	ec4e                	sd	s3,24(sp)
ffffffffc02051be:	e852                	sd	s4,16(sp)
ffffffffc02051c0:	e456                	sd	s5,8(sp)
ffffffffc02051c2:	e05a                	sd	s6,0(sp)
ffffffffc02051c4:	842e                	mv	s0,a1
                compare_f comp)
{
     if (a == NULL) return b;
ffffffffc02051c6:	c925                	beqz	a0,ffffffffc0205236 <skew_heap_merge.constprop.0+0x84>
ffffffffc02051c8:	84aa                	mv	s1,a0
     else if (b == NULL) return a;
ffffffffc02051ca:	c1ed                	beqz	a1,ffffffffc02052ac <skew_heap_merge.constprop.0+0xfa>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02051cc:	4d1c                	lw	a5,24(a0)
ffffffffc02051ce:	4d98                	lw	a4,24(a1)
     else if (c == 0)
ffffffffc02051d0:	40e786bb          	subw	a3,a5,a4
ffffffffc02051d4:	0606cc63          	bltz	a3,ffffffffc020524c <skew_heap_merge.constprop.0+0x9a>
          return a;
     }
     else
     {
          r = b->left;
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02051d8:	0105b903          	ld	s2,16(a1)
          r = b->left;
ffffffffc02051dc:	0085ba03          	ld	s4,8(a1)
     else if (b == NULL) return a;
ffffffffc02051e0:	04090763          	beqz	s2,ffffffffc020522e <skew_heap_merge.constprop.0+0x7c>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02051e4:	01892703          	lw	a4,24(s2)
     else if (c == 0)
ffffffffc02051e8:	40e786bb          	subw	a3,a5,a4
ffffffffc02051ec:	0c06c263          	bltz	a3,ffffffffc02052b0 <skew_heap_merge.constprop.0+0xfe>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02051f0:	01093983          	ld	s3,16(s2)
          r = b->left;
ffffffffc02051f4:	00893a83          	ld	s5,8(s2)
     else if (b == NULL) return a;
ffffffffc02051f8:	10098c63          	beqz	s3,ffffffffc0205310 <skew_heap_merge.constprop.0+0x15e>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02051fc:	0189a703          	lw	a4,24(s3)
     else if (c == 0)
ffffffffc0205200:	9f99                	subw	a5,a5,a4
ffffffffc0205202:	1407c863          	bltz	a5,ffffffffc0205352 <skew_heap_merge.constprop.0+0x1a0>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205206:	0109b583          	ld	a1,16(s3)
          r = b->left;
ffffffffc020520a:	0089b483          	ld	s1,8(s3)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc020520e:	fa5ff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          
          b->left = l;
ffffffffc0205212:	00a9b423          	sd	a0,8(s3)
          b->right = r;
ffffffffc0205216:	0099b823          	sd	s1,16(s3)
          if (l) l->parent = b;
ffffffffc020521a:	c119                	beqz	a0,ffffffffc0205220 <skew_heap_merge.constprop.0+0x6e>
ffffffffc020521c:	01353023          	sd	s3,0(a0)
          b->left = l;
ffffffffc0205220:	01393423          	sd	s3,8(s2)
          b->right = r;
ffffffffc0205224:	01593823          	sd	s5,16(s2)
          if (l) l->parent = b;
ffffffffc0205228:	0129b023          	sd	s2,0(s3)
ffffffffc020522c:	84ca                	mv	s1,s2
          b->left = l;
ffffffffc020522e:	e404                	sd	s1,8(s0)
          b->right = r;
ffffffffc0205230:	01443823          	sd	s4,16(s0)
          if (l) l->parent = b;
ffffffffc0205234:	e080                	sd	s0,0(s1)
ffffffffc0205236:	8522                	mv	a0,s0

          return b;
     }
}
ffffffffc0205238:	70e2                	ld	ra,56(sp)
ffffffffc020523a:	7442                	ld	s0,48(sp)
ffffffffc020523c:	74a2                	ld	s1,40(sp)
ffffffffc020523e:	7902                	ld	s2,32(sp)
ffffffffc0205240:	69e2                	ld	s3,24(sp)
ffffffffc0205242:	6a42                	ld	s4,16(sp)
ffffffffc0205244:	6aa2                	ld	s5,8(sp)
ffffffffc0205246:	6b02                	ld	s6,0(sp)
ffffffffc0205248:	6121                	addi	sp,sp,64
ffffffffc020524a:	8082                	ret
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020524c:	01053903          	ld	s2,16(a0)
          r = a->left;
ffffffffc0205250:	00853a03          	ld	s4,8(a0)
     if (a == NULL) return b;
ffffffffc0205254:	04090863          	beqz	s2,ffffffffc02052a4 <skew_heap_merge.constprop.0+0xf2>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc0205258:	01892783          	lw	a5,24(s2)
     else if (c == 0)
ffffffffc020525c:	40e7873b          	subw	a4,a5,a4
ffffffffc0205260:	08074963          	bltz	a4,ffffffffc02052f2 <skew_heap_merge.constprop.0+0x140>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205264:	0105b983          	ld	s3,16(a1)
          r = b->left;
ffffffffc0205268:	0085ba83          	ld	s5,8(a1)
     else if (b == NULL) return a;
ffffffffc020526c:	02098663          	beqz	s3,ffffffffc0205298 <skew_heap_merge.constprop.0+0xe6>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc0205270:	0189a703          	lw	a4,24(s3)
     else if (c == 0)
ffffffffc0205274:	9f99                	subw	a5,a5,a4
ffffffffc0205276:	0a07cf63          	bltz	a5,ffffffffc0205334 <skew_heap_merge.constprop.0+0x182>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc020527a:	0109b583          	ld	a1,16(s3)
          r = b->left;
ffffffffc020527e:	0089bb03          	ld	s6,8(s3)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205282:	854a                	mv	a0,s2
ffffffffc0205284:	f2fff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc0205288:	00a9b423          	sd	a0,8(s3)
          b->right = r;
ffffffffc020528c:	0169b823          	sd	s6,16(s3)
          if (l) l->parent = b;
ffffffffc0205290:	894e                	mv	s2,s3
ffffffffc0205292:	c119                	beqz	a0,ffffffffc0205298 <skew_heap_merge.constprop.0+0xe6>
ffffffffc0205294:	01253023          	sd	s2,0(a0)
          b->left = l;
ffffffffc0205298:	01243423          	sd	s2,8(s0)
          b->right = r;
ffffffffc020529c:	01543823          	sd	s5,16(s0)
          if (l) l->parent = b;
ffffffffc02052a0:	00893023          	sd	s0,0(s2)
          a->left = l;
ffffffffc02052a4:	e480                	sd	s0,8(s1)
          a->right = r;
ffffffffc02052a6:	0144b823          	sd	s4,16(s1)
          if (l) l->parent = a;
ffffffffc02052aa:	e004                	sd	s1,0(s0)
ffffffffc02052ac:	8526                	mv	a0,s1
ffffffffc02052ae:	b769                	j	ffffffffc0205238 <skew_heap_merge.constprop.0+0x86>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02052b0:	01053983          	ld	s3,16(a0)
          r = a->left;
ffffffffc02052b4:	00853a83          	ld	s5,8(a0)
     if (a == NULL) return b;
ffffffffc02052b8:	02098663          	beqz	s3,ffffffffc02052e4 <skew_heap_merge.constprop.0+0x132>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02052bc:	0189a783          	lw	a5,24(s3)
     else if (c == 0)
ffffffffc02052c0:	40e7873b          	subw	a4,a5,a4
ffffffffc02052c4:	04074863          	bltz	a4,ffffffffc0205314 <skew_heap_merge.constprop.0+0x162>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02052c8:	01093583          	ld	a1,16(s2)
          r = b->left;
ffffffffc02052cc:	00893b03          	ld	s6,8(s2)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02052d0:	854e                	mv	a0,s3
ffffffffc02052d2:	ee1ff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc02052d6:	00a93423          	sd	a0,8(s2)
          b->right = r;
ffffffffc02052da:	01693823          	sd	s6,16(s2)
          if (l) l->parent = b;
ffffffffc02052de:	c119                	beqz	a0,ffffffffc02052e4 <skew_heap_merge.constprop.0+0x132>
ffffffffc02052e0:	01253023          	sd	s2,0(a0)
          a->left = l;
ffffffffc02052e4:	0124b423          	sd	s2,8(s1)
          a->right = r;
ffffffffc02052e8:	0154b823          	sd	s5,16(s1)
          if (l) l->parent = a;
ffffffffc02052ec:	00993023          	sd	s1,0(s2)
ffffffffc02052f0:	bf3d                	j	ffffffffc020522e <skew_heap_merge.constprop.0+0x7c>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02052f2:	01093503          	ld	a0,16(s2)
          r = a->left;
ffffffffc02052f6:	00893983          	ld	s3,8(s2)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02052fa:	844a                	mv	s0,s2
ffffffffc02052fc:	eb7ff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205300:	00a93423          	sd	a0,8(s2)
          a->right = r;
ffffffffc0205304:	01393823          	sd	s3,16(s2)
          if (l) l->parent = a;
ffffffffc0205308:	dd51                	beqz	a0,ffffffffc02052a4 <skew_heap_merge.constprop.0+0xf2>
ffffffffc020530a:	01253023          	sd	s2,0(a0)
ffffffffc020530e:	bf59                	j	ffffffffc02052a4 <skew_heap_merge.constprop.0+0xf2>
          if (l) l->parent = b;
ffffffffc0205310:	89a6                	mv	s3,s1
ffffffffc0205312:	b739                	j	ffffffffc0205220 <skew_heap_merge.constprop.0+0x6e>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205314:	0109b503          	ld	a0,16(s3)
          r = a->left;
ffffffffc0205318:	0089bb03          	ld	s6,8(s3)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020531c:	85ca                	mv	a1,s2
ffffffffc020531e:	e95ff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205322:	00a9b423          	sd	a0,8(s3)
          a->right = r;
ffffffffc0205326:	0169b823          	sd	s6,16(s3)
          if (l) l->parent = a;
ffffffffc020532a:	894e                	mv	s2,s3
ffffffffc020532c:	dd45                	beqz	a0,ffffffffc02052e4 <skew_heap_merge.constprop.0+0x132>
          if (l) l->parent = b;
ffffffffc020532e:	01253023          	sd	s2,0(a0)
ffffffffc0205332:	bf4d                	j	ffffffffc02052e4 <skew_heap_merge.constprop.0+0x132>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205334:	01093503          	ld	a0,16(s2)
          r = a->left;
ffffffffc0205338:	00893b03          	ld	s6,8(s2)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020533c:	85ce                	mv	a1,s3
ffffffffc020533e:	e75ff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205342:	00a93423          	sd	a0,8(s2)
          a->right = r;
ffffffffc0205346:	01693823          	sd	s6,16(s2)
          if (l) l->parent = a;
ffffffffc020534a:	d539                	beqz	a0,ffffffffc0205298 <skew_heap_merge.constprop.0+0xe6>
          if (l) l->parent = b;
ffffffffc020534c:	01253023          	sd	s2,0(a0)
ffffffffc0205350:	b7a1                	j	ffffffffc0205298 <skew_heap_merge.constprop.0+0xe6>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205352:	6908                	ld	a0,16(a0)
          r = a->left;
ffffffffc0205354:	0084bb03          	ld	s6,8(s1)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205358:	85ce                	mv	a1,s3
ffffffffc020535a:	e59ff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc020535e:	e488                	sd	a0,8(s1)
          a->right = r;
ffffffffc0205360:	0164b823          	sd	s6,16(s1)
          if (l) l->parent = a;
ffffffffc0205364:	d555                	beqz	a0,ffffffffc0205310 <skew_heap_merge.constprop.0+0x15e>
ffffffffc0205366:	e104                	sd	s1,0(a0)
ffffffffc0205368:	89a6                	mv	s3,s1
ffffffffc020536a:	bd5d                	j	ffffffffc0205220 <skew_heap_merge.constprop.0+0x6e>

ffffffffc020536c <stride_dequeue>:
{
ffffffffc020536c:	711d                	addi	sp,sp,-96
ffffffffc020536e:	fc4e                	sd	s3,56(sp)
static inline skew_heap_entry_t *
skew_heap_remove(skew_heap_entry_t *a, skew_heap_entry_t *b,
                 compare_f comp)
{
     skew_heap_entry_t *p   = b->parent;
     skew_heap_entry_t *rep = skew_heap_merge(b->left, b->right, comp);
ffffffffc0205370:	1305b983          	ld	s3,304(a1)
ffffffffc0205374:	e8a2                	sd	s0,80(sp)
ffffffffc0205376:	e4a6                	sd	s1,72(sp)
ffffffffc0205378:	e0ca                	sd	s2,64(sp)
ffffffffc020537a:	f852                	sd	s4,48(sp)
ffffffffc020537c:	f05a                	sd	s6,32(sp)
ffffffffc020537e:	ec86                	sd	ra,88(sp)
ffffffffc0205380:	f456                	sd	s5,40(sp)
ffffffffc0205382:	ec5e                	sd	s7,24(sp)
ffffffffc0205384:	e862                	sd	s8,16(sp)
ffffffffc0205386:	e466                	sd	s9,8(sp)
ffffffffc0205388:	e06a                	sd	s10,0(sp)
     rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc020538a:	01853b03          	ld	s6,24(a0)
     skew_heap_entry_t *p   = b->parent;
ffffffffc020538e:	1285ba03          	ld	s4,296(a1)
     skew_heap_entry_t *rep = skew_heap_merge(b->left, b->right, comp);
ffffffffc0205392:	1385b483          	ld	s1,312(a1)
{
ffffffffc0205396:	842e                	mv	s0,a1
ffffffffc0205398:	892a                	mv	s2,a0
     if (a == NULL) return b;
ffffffffc020539a:	12098a63          	beqz	s3,ffffffffc02054ce <stride_dequeue+0x162>
     else if (b == NULL) return a;
ffffffffc020539e:	12048f63          	beqz	s1,ffffffffc02054dc <stride_dequeue+0x170>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02053a2:	0189a783          	lw	a5,24(s3)
ffffffffc02053a6:	4c98                	lw	a4,24(s1)
     else if (c == 0)
ffffffffc02053a8:	40e786bb          	subw	a3,a5,a4
ffffffffc02053ac:	0a06c963          	bltz	a3,ffffffffc020545e <stride_dequeue+0xf2>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02053b0:	0104ba83          	ld	s5,16(s1)
          r = b->left;
ffffffffc02053b4:	0084bc03          	ld	s8,8(s1)
     else if (b == NULL) return a;
ffffffffc02053b8:	040a8963          	beqz	s5,ffffffffc020540a <stride_dequeue+0x9e>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02053bc:	018aa703          	lw	a4,24(s5)
     else if (c == 0)
ffffffffc02053c0:	40e786bb          	subw	a3,a5,a4
ffffffffc02053c4:	1206c063          	bltz	a3,ffffffffc02054e4 <stride_dequeue+0x178>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02053c8:	010abb83          	ld	s7,16(s5)
          r = b->left;
ffffffffc02053cc:	008abc83          	ld	s9,8(s5)
     else if (b == NULL) return a;
ffffffffc02053d0:	020b8663          	beqz	s7,ffffffffc02053fc <stride_dequeue+0x90>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02053d4:	018ba703          	lw	a4,24(s7)
     else if (c == 0)
ffffffffc02053d8:	9f99                	subw	a5,a5,a4
ffffffffc02053da:	1a07c563          	bltz	a5,ffffffffc0205584 <stride_dequeue+0x218>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02053de:	010bb583          	ld	a1,16(s7)
          r = b->left;
ffffffffc02053e2:	008bbd03          	ld	s10,8(s7)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02053e6:	854e                	mv	a0,s3
ffffffffc02053e8:	dcbff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc02053ec:	00abb423          	sd	a0,8(s7)
          b->right = r;
ffffffffc02053f0:	01abb823          	sd	s10,16(s7)
          if (l) l->parent = b;
ffffffffc02053f4:	89de                	mv	s3,s7
ffffffffc02053f6:	c119                	beqz	a0,ffffffffc02053fc <stride_dequeue+0x90>
ffffffffc02053f8:	01353023          	sd	s3,0(a0)
          b->left = l;
ffffffffc02053fc:	013ab423          	sd	s3,8(s5)
          b->right = r;
ffffffffc0205400:	019ab823          	sd	s9,16(s5)
          if (l) l->parent = b;
ffffffffc0205404:	0159b023          	sd	s5,0(s3)
ffffffffc0205408:	89d6                	mv	s3,s5
          b->left = l;
ffffffffc020540a:	0134b423          	sd	s3,8(s1)
          b->right = r;
ffffffffc020540e:	0184b823          	sd	s8,16(s1)
          if (l) l->parent = b;
ffffffffc0205412:	0099b023          	sd	s1,0(s3)
     if (rep) rep->parent = p;
ffffffffc0205416:	0144b023          	sd	s4,0(s1)
     
     if (p)
ffffffffc020541a:	0a0a0863          	beqz	s4,ffffffffc02054ca <stride_dequeue+0x15e>
     {
          if (p->left == b)
ffffffffc020541e:	008a3703          	ld	a4,8(s4)
     rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc0205422:	12840793          	addi	a5,s0,296
ffffffffc0205426:	0af70863          	beq	a4,a5,ffffffffc02054d6 <stride_dequeue+0x16a>
               p->left = rep;
          else p->right = rep;
ffffffffc020542a:	009a3823          	sd	s1,16(s4)
     if (rq->proc_num > 0)
ffffffffc020542e:	01092783          	lw	a5,16(s2)
     rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc0205432:	01693c23          	sd	s6,24(s2)
     proc->rq = NULL;
ffffffffc0205436:	10043423          	sd	zero,264(s0)
     if (rq->proc_num > 0)
ffffffffc020543a:	c781                	beqz	a5,ffffffffc0205442 <stride_dequeue+0xd6>
          rq->proc_num--;
ffffffffc020543c:	37fd                	addiw	a5,a5,-1
ffffffffc020543e:	00f92823          	sw	a5,16(s2)
}
ffffffffc0205442:	60e6                	ld	ra,88(sp)
ffffffffc0205444:	6446                	ld	s0,80(sp)
ffffffffc0205446:	64a6                	ld	s1,72(sp)
ffffffffc0205448:	6906                	ld	s2,64(sp)
ffffffffc020544a:	79e2                	ld	s3,56(sp)
ffffffffc020544c:	7a42                	ld	s4,48(sp)
ffffffffc020544e:	7aa2                	ld	s5,40(sp)
ffffffffc0205450:	7b02                	ld	s6,32(sp)
ffffffffc0205452:	6be2                	ld	s7,24(sp)
ffffffffc0205454:	6c42                	ld	s8,16(sp)
ffffffffc0205456:	6ca2                	ld	s9,8(sp)
ffffffffc0205458:	6d02                	ld	s10,0(sp)
ffffffffc020545a:	6125                	addi	sp,sp,96
ffffffffc020545c:	8082                	ret
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020545e:	0109ba83          	ld	s5,16(s3)
          r = a->left;
ffffffffc0205462:	0089bc03          	ld	s8,8(s3)
     if (a == NULL) return b;
ffffffffc0205466:	040a8863          	beqz	s5,ffffffffc02054b6 <stride_dequeue+0x14a>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc020546a:	018aa783          	lw	a5,24(s5)
     else if (c == 0)
ffffffffc020546e:	40e7873b          	subw	a4,a5,a4
ffffffffc0205472:	0a074a63          	bltz	a4,ffffffffc0205526 <stride_dequeue+0x1ba>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205476:	0104bb83          	ld	s7,16(s1)
          r = b->left;
ffffffffc020547a:	0084bc83          	ld	s9,8(s1)
     else if (b == NULL) return a;
ffffffffc020547e:	020b8663          	beqz	s7,ffffffffc02054aa <stride_dequeue+0x13e>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc0205482:	018ba703          	lw	a4,24(s7)
     else if (c == 0)
ffffffffc0205486:	9f99                	subw	a5,a5,a4
ffffffffc0205488:	0c07cf63          	bltz	a5,ffffffffc0205566 <stride_dequeue+0x1fa>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc020548c:	010bb583          	ld	a1,16(s7)
          r = b->left;
ffffffffc0205490:	008bbd03          	ld	s10,8(s7)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205494:	8556                	mv	a0,s5
ffffffffc0205496:	d1dff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc020549a:	00abb423          	sd	a0,8(s7)
          b->right = r;
ffffffffc020549e:	01abb823          	sd	s10,16(s7)
          if (l) l->parent = b;
ffffffffc02054a2:	8ade                	mv	s5,s7
ffffffffc02054a4:	c119                	beqz	a0,ffffffffc02054aa <stride_dequeue+0x13e>
ffffffffc02054a6:	01553023          	sd	s5,0(a0)
          b->left = l;
ffffffffc02054aa:	0154b423          	sd	s5,8(s1)
          b->right = r;
ffffffffc02054ae:	0194b823          	sd	s9,16(s1)
          if (l) l->parent = b;
ffffffffc02054b2:	009ab023          	sd	s1,0(s5)
          a->left = l;
ffffffffc02054b6:	0099b423          	sd	s1,8(s3)
          a->right = r;
ffffffffc02054ba:	0189b823          	sd	s8,16(s3)
          if (l) l->parent = a;
ffffffffc02054be:	0134b023          	sd	s3,0(s1)
ffffffffc02054c2:	84ce                	mv	s1,s3
     if (rep) rep->parent = p;
ffffffffc02054c4:	0144b023          	sd	s4,0(s1)
ffffffffc02054c8:	bf89                	j	ffffffffc020541a <stride_dequeue+0xae>
ffffffffc02054ca:	8b26                	mv	s6,s1
ffffffffc02054cc:	b78d                	j	ffffffffc020542e <stride_dequeue+0xc2>
ffffffffc02054ce:	d4b1                	beqz	s1,ffffffffc020541a <stride_dequeue+0xae>
ffffffffc02054d0:	0144b023          	sd	s4,0(s1)
ffffffffc02054d4:	b799                	j	ffffffffc020541a <stride_dequeue+0xae>
               p->left = rep;
ffffffffc02054d6:	009a3423          	sd	s1,8(s4)
ffffffffc02054da:	bf91                	j	ffffffffc020542e <stride_dequeue+0xc2>
ffffffffc02054dc:	84ce                	mv	s1,s3
     if (rep) rep->parent = p;
ffffffffc02054de:	0144b023          	sd	s4,0(s1)
ffffffffc02054e2:	bf25                	j	ffffffffc020541a <stride_dequeue+0xae>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02054e4:	0109bb83          	ld	s7,16(s3)
          r = a->left;
ffffffffc02054e8:	0089bc83          	ld	s9,8(s3)
     if (a == NULL) return b;
ffffffffc02054ec:	020b8663          	beqz	s7,ffffffffc0205518 <stride_dequeue+0x1ac>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02054f0:	018ba783          	lw	a5,24(s7)
     else if (c == 0)
ffffffffc02054f4:	40e7873b          	subw	a4,a5,a4
ffffffffc02054f8:	04074763          	bltz	a4,ffffffffc0205546 <stride_dequeue+0x1da>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02054fc:	010ab583          	ld	a1,16(s5)
          r = b->left;
ffffffffc0205500:	008abd03          	ld	s10,8(s5)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205504:	855e                	mv	a0,s7
ffffffffc0205506:	cadff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc020550a:	00aab423          	sd	a0,8(s5)
          b->right = r;
ffffffffc020550e:	01aab823          	sd	s10,16(s5)
          if (l) l->parent = b;
ffffffffc0205512:	c119                	beqz	a0,ffffffffc0205518 <stride_dequeue+0x1ac>
ffffffffc0205514:	01553023          	sd	s5,0(a0)
          a->left = l;
ffffffffc0205518:	0159b423          	sd	s5,8(s3)
          a->right = r;
ffffffffc020551c:	0199b823          	sd	s9,16(s3)
          if (l) l->parent = a;
ffffffffc0205520:	013ab023          	sd	s3,0(s5)
ffffffffc0205524:	b5dd                	j	ffffffffc020540a <stride_dequeue+0x9e>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205526:	010ab503          	ld	a0,16(s5)
          r = a->left;
ffffffffc020552a:	008abb83          	ld	s7,8(s5)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020552e:	85a6                	mv	a1,s1
ffffffffc0205530:	c83ff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205534:	00aab423          	sd	a0,8(s5)
          a->right = r;
ffffffffc0205538:	017ab823          	sd	s7,16(s5)
          if (l) l->parent = a;
ffffffffc020553c:	84d6                	mv	s1,s5
ffffffffc020553e:	dd25                	beqz	a0,ffffffffc02054b6 <stride_dequeue+0x14a>
ffffffffc0205540:	01553023          	sd	s5,0(a0)
ffffffffc0205544:	bf8d                	j	ffffffffc02054b6 <stride_dequeue+0x14a>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205546:	010bb503          	ld	a0,16(s7)
          r = a->left;
ffffffffc020554a:	008bbd03          	ld	s10,8(s7)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020554e:	85d6                	mv	a1,s5
ffffffffc0205550:	c63ff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205554:	00abb423          	sd	a0,8(s7)
          a->right = r;
ffffffffc0205558:	01abb823          	sd	s10,16(s7)
          if (l) l->parent = a;
ffffffffc020555c:	8ade                	mv	s5,s7
ffffffffc020555e:	dd4d                	beqz	a0,ffffffffc0205518 <stride_dequeue+0x1ac>
          if (l) l->parent = b;
ffffffffc0205560:	01553023          	sd	s5,0(a0)
ffffffffc0205564:	bf55                	j	ffffffffc0205518 <stride_dequeue+0x1ac>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205566:	010ab503          	ld	a0,16(s5)
          r = a->left;
ffffffffc020556a:	008abd03          	ld	s10,8(s5)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020556e:	85de                	mv	a1,s7
ffffffffc0205570:	c43ff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205574:	00aab423          	sd	a0,8(s5)
          a->right = r;
ffffffffc0205578:	01aab823          	sd	s10,16(s5)
          if (l) l->parent = a;
ffffffffc020557c:	d51d                	beqz	a0,ffffffffc02054aa <stride_dequeue+0x13e>
          if (l) l->parent = b;
ffffffffc020557e:	01553023          	sd	s5,0(a0)
ffffffffc0205582:	b725                	j	ffffffffc02054aa <stride_dequeue+0x13e>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205584:	0109b503          	ld	a0,16(s3)
          r = a->left;
ffffffffc0205588:	0089bd03          	ld	s10,8(s3)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020558c:	85de                	mv	a1,s7
ffffffffc020558e:	c25ff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205592:	00a9b423          	sd	a0,8(s3)
          a->right = r;
ffffffffc0205596:	01a9b823          	sd	s10,16(s3)
          if (l) l->parent = a;
ffffffffc020559a:	e4051fe3          	bnez	a0,ffffffffc02053f8 <stride_dequeue+0x8c>
ffffffffc020559e:	bdb9                	j	ffffffffc02053fc <stride_dequeue+0x90>

ffffffffc02055a0 <stride_enqueue>:
     if (proc->lab6_priority == 0)
ffffffffc02055a0:	1445a783          	lw	a5,324(a1)
{
ffffffffc02055a4:	7179                	addi	sp,sp,-48
ffffffffc02055a6:	f022                	sd	s0,32(sp)
ffffffffc02055a8:	f406                	sd	ra,40(sp)
ffffffffc02055aa:	ec26                	sd	s1,24(sp)
ffffffffc02055ac:	e84a                	sd	s2,16(sp)
ffffffffc02055ae:	e44e                	sd	s3,8(sp)
ffffffffc02055b0:	e052                	sd	s4,0(sp)
ffffffffc02055b2:	842a                	mv	s0,a0
     if (proc->lab6_priority == 0)
ffffffffc02055b4:	e781                	bnez	a5,ffffffffc02055bc <stride_enqueue+0x1c>
          proc->lab6_priority = 1;
ffffffffc02055b6:	4785                	li	a5,1
ffffffffc02055b8:	14f5a223          	sw	a5,324(a1)
     if (proc->time_slice <= 0 || proc->time_slice > rq->max_time_slice)
ffffffffc02055bc:	1205a783          	lw	a5,288(a1)
ffffffffc02055c0:	4858                	lw	a4,20(s0)
ffffffffc02055c2:	04f05563          	blez	a5,ffffffffc020560c <stride_enqueue+0x6c>
ffffffffc02055c6:	04f74363          	blt	a4,a5,ffffffffc020560c <stride_enqueue+0x6c>
     rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc02055ca:	6c04                	ld	s1,24(s0)
     proc->rq = rq;
ffffffffc02055cc:	1085b423          	sd	s0,264(a1)
     a->left = a->right = a->parent = NULL;
ffffffffc02055d0:	1205b423          	sd	zero,296(a1)
ffffffffc02055d4:	1205bc23          	sd	zero,312(a1)
ffffffffc02055d8:	1205b823          	sd	zero,304(a1)
     rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc02055dc:	12858713          	addi	a4,a1,296
     if (a == NULL) return b;
ffffffffc02055e0:	c891                	beqz	s1,ffffffffc02055f4 <stride_enqueue+0x54>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02055e2:	1405a683          	lw	a3,320(a1)
ffffffffc02055e6:	4c9c                	lw	a5,24(s1)
     else if (c == 0)
ffffffffc02055e8:	9f95                	subw	a5,a5,a3
ffffffffc02055ea:	0207c463          	bltz	a5,ffffffffc0205612 <stride_enqueue+0x72>
          b->left = l;
ffffffffc02055ee:	1295b823          	sd	s1,304(a1)
          if (l) l->parent = b;
ffffffffc02055f2:	e098                	sd	a4,0(s1)
     rq->proc_num++;
ffffffffc02055f4:	481c                	lw	a5,16(s0)
}
ffffffffc02055f6:	70a2                	ld	ra,40(sp)
     rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc02055f8:	ec18                	sd	a4,24(s0)
     rq->proc_num++;
ffffffffc02055fa:	2785                	addiw	a5,a5,1
ffffffffc02055fc:	c81c                	sw	a5,16(s0)
}
ffffffffc02055fe:	7402                	ld	s0,32(sp)
ffffffffc0205600:	64e2                	ld	s1,24(sp)
ffffffffc0205602:	6942                	ld	s2,16(sp)
ffffffffc0205604:	69a2                	ld	s3,8(sp)
ffffffffc0205606:	6a02                	ld	s4,0(sp)
ffffffffc0205608:	6145                	addi	sp,sp,48
ffffffffc020560a:	8082                	ret
          proc->time_slice = rq->max_time_slice;
ffffffffc020560c:	12e5a023          	sw	a4,288(a1)
ffffffffc0205610:	bf6d                	j	ffffffffc02055ca <stride_enqueue+0x2a>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205612:	0104b903          	ld	s2,16(s1)
          r = a->left;
ffffffffc0205616:	0084b983          	ld	s3,8(s1)
     if (a == NULL) return b;
ffffffffc020561a:	00090c63          	beqz	s2,ffffffffc0205632 <stride_enqueue+0x92>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc020561e:	01892783          	lw	a5,24(s2)
     else if (c == 0)
ffffffffc0205622:	40d786bb          	subw	a3,a5,a3
ffffffffc0205626:	0006cc63          	bltz	a3,ffffffffc020563e <stride_enqueue+0x9e>
          b->left = l;
ffffffffc020562a:	1325b823          	sd	s2,304(a1)
          if (l) l->parent = b;
ffffffffc020562e:	00e93023          	sd	a4,0(s2)
          a->left = l;
ffffffffc0205632:	e498                	sd	a4,8(s1)
          a->right = r;
ffffffffc0205634:	0134b823          	sd	s3,16(s1)
          if (l) l->parent = a;
ffffffffc0205638:	e304                	sd	s1,0(a4)
ffffffffc020563a:	8726                	mv	a4,s1
ffffffffc020563c:	bf65                	j	ffffffffc02055f4 <stride_enqueue+0x54>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020563e:	01093503          	ld	a0,16(s2)
          r = a->left;
ffffffffc0205642:	00893a03          	ld	s4,8(s2)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205646:	85ba                	mv	a1,a4
ffffffffc0205648:	b6bff0ef          	jal	ra,ffffffffc02051b2 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc020564c:	00a93423          	sd	a0,8(s2)
          a->right = r;
ffffffffc0205650:	01493823          	sd	s4,16(s2)
          if (l) l->parent = a;
ffffffffc0205654:	874a                	mv	a4,s2
ffffffffc0205656:	dd71                	beqz	a0,ffffffffc0205632 <stride_enqueue+0x92>
ffffffffc0205658:	01253023          	sd	s2,0(a0)
ffffffffc020565c:	bfd9                	j	ffffffffc0205632 <stride_enqueue+0x92>

ffffffffc020565e <sched_class_proc_tick>:
    return sched_class->pick_next(rq);
}

void sched_class_proc_tick(struct proc_struct *proc)
{
    if (proc != idleproc)
ffffffffc020565e:	000c1797          	auipc	a5,0xc1
ffffffffc0205662:	58a7b783          	ld	a5,1418(a5) # ffffffffc02c6be8 <idleproc>
{
ffffffffc0205666:	85aa                	mv	a1,a0
    if (proc != idleproc)
ffffffffc0205668:	00a78c63          	beq	a5,a0,ffffffffc0205680 <sched_class_proc_tick+0x22>
    {
        sched_class->proc_tick(rq, proc);
ffffffffc020566c:	000c1797          	auipc	a5,0xc1
ffffffffc0205670:	59c7b783          	ld	a5,1436(a5) # ffffffffc02c6c08 <sched_class>
ffffffffc0205674:	779c                	ld	a5,40(a5)
ffffffffc0205676:	000c1517          	auipc	a0,0xc1
ffffffffc020567a:	58a53503          	ld	a0,1418(a0) # ffffffffc02c6c00 <rq>
ffffffffc020567e:	8782                	jr	a5
    }
    else
    {
        proc->need_resched = 1;
ffffffffc0205680:	4705                	li	a4,1
ffffffffc0205682:	ef98                	sd	a4,24(a5)
    }
}
ffffffffc0205684:	8082                	ret

ffffffffc0205686 <sched_init>:

static struct run_queue __rq;

void sched_init(void)
{
ffffffffc0205686:	1141                	addi	sp,sp,-16
    list_init(&timer_list);

    sched_class = &stride_sched_class;
ffffffffc0205688:	000bd717          	auipc	a4,0xbd
ffffffffc020568c:	05870713          	addi	a4,a4,88 # ffffffffc02c26e0 <stride_sched_class>
{
ffffffffc0205690:	e022                	sd	s0,0(sp)
ffffffffc0205692:	e406                	sd	ra,8(sp)
ffffffffc0205694:	000c1797          	auipc	a5,0xc1
ffffffffc0205698:	4d478793          	addi	a5,a5,1236 # ffffffffc02c6b68 <timer_list>

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);
ffffffffc020569c:	6714                	ld	a3,8(a4)
    rq = &__rq;
ffffffffc020569e:	000c1517          	auipc	a0,0xc1
ffffffffc02056a2:	4aa50513          	addi	a0,a0,1194 # ffffffffc02c6b48 <__rq>
ffffffffc02056a6:	e79c                	sd	a5,8(a5)
ffffffffc02056a8:	e39c                	sd	a5,0(a5)
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc02056aa:	4795                	li	a5,5
ffffffffc02056ac:	c95c                	sw	a5,20(a0)
    sched_class = &stride_sched_class;
ffffffffc02056ae:	000c1417          	auipc	s0,0xc1
ffffffffc02056b2:	55a40413          	addi	s0,s0,1370 # ffffffffc02c6c08 <sched_class>
    rq = &__rq;
ffffffffc02056b6:	000c1797          	auipc	a5,0xc1
ffffffffc02056ba:	54a7b523          	sd	a0,1354(a5) # ffffffffc02c6c00 <rq>
    sched_class = &stride_sched_class;
ffffffffc02056be:	e018                	sd	a4,0(s0)
    sched_class->init(rq);
ffffffffc02056c0:	9682                	jalr	a3

    cprintf("sched class: %s\n", sched_class->name);
ffffffffc02056c2:	601c                	ld	a5,0(s0)
}
ffffffffc02056c4:	6402                	ld	s0,0(sp)
ffffffffc02056c6:	60a2                	ld	ra,8(sp)
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc02056c8:	638c                	ld	a1,0(a5)
ffffffffc02056ca:	00002517          	auipc	a0,0x2
ffffffffc02056ce:	42e50513          	addi	a0,a0,1070 # ffffffffc0207af8 <default_pmm_manager+0xe58>
}
ffffffffc02056d2:	0141                	addi	sp,sp,16
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc02056d4:	ac5fa06f          	j	ffffffffc0200198 <cprintf>

ffffffffc02056d8 <wakeup_proc>:

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02056d8:	4118                	lw	a4,0(a0)
{
ffffffffc02056da:	1101                	addi	sp,sp,-32
ffffffffc02056dc:	ec06                	sd	ra,24(sp)
ffffffffc02056de:	e822                	sd	s0,16(sp)
ffffffffc02056e0:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02056e2:	478d                	li	a5,3
ffffffffc02056e4:	08f70363          	beq	a4,a5,ffffffffc020576a <wakeup_proc+0x92>
ffffffffc02056e8:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02056ea:	100027f3          	csrr	a5,sstatus
ffffffffc02056ee:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02056f0:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02056f2:	e7bd                	bnez	a5,ffffffffc0205760 <wakeup_proc+0x88>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02056f4:	4789                	li	a5,2
ffffffffc02056f6:	04f70863          	beq	a4,a5,ffffffffc0205746 <wakeup_proc+0x6e>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc02056fa:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc02056fc:	0e042623          	sw	zero,236(s0)
            if (proc != current)
ffffffffc0205700:	000c1797          	auipc	a5,0xc1
ffffffffc0205704:	4e07b783          	ld	a5,1248(a5) # ffffffffc02c6be0 <current>
ffffffffc0205708:	02878363          	beq	a5,s0,ffffffffc020572e <wakeup_proc+0x56>
    if (proc != idleproc)
ffffffffc020570c:	000c1797          	auipc	a5,0xc1
ffffffffc0205710:	4dc7b783          	ld	a5,1244(a5) # ffffffffc02c6be8 <idleproc>
ffffffffc0205714:	00f40d63          	beq	s0,a5,ffffffffc020572e <wakeup_proc+0x56>
        sched_class->enqueue(rq, proc);
ffffffffc0205718:	000c1797          	auipc	a5,0xc1
ffffffffc020571c:	4f07b783          	ld	a5,1264(a5) # ffffffffc02c6c08 <sched_class>
ffffffffc0205720:	6b9c                	ld	a5,16(a5)
ffffffffc0205722:	85a2                	mv	a1,s0
ffffffffc0205724:	000c1517          	auipc	a0,0xc1
ffffffffc0205728:	4dc53503          	ld	a0,1244(a0) # ffffffffc02c6c00 <rq>
ffffffffc020572c:	9782                	jalr	a5
    if (flag)
ffffffffc020572e:	e491                	bnez	s1,ffffffffc020573a <wakeup_proc+0x62>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205730:	60e2                	ld	ra,24(sp)
ffffffffc0205732:	6442                	ld	s0,16(sp)
ffffffffc0205734:	64a2                	ld	s1,8(sp)
ffffffffc0205736:	6105                	addi	sp,sp,32
ffffffffc0205738:	8082                	ret
ffffffffc020573a:	6442                	ld	s0,16(sp)
ffffffffc020573c:	60e2                	ld	ra,24(sp)
ffffffffc020573e:	64a2                	ld	s1,8(sp)
ffffffffc0205740:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205742:	a66fb06f          	j	ffffffffc02009a8 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205746:	00002617          	auipc	a2,0x2
ffffffffc020574a:	40260613          	addi	a2,a2,1026 # ffffffffc0207b48 <default_pmm_manager+0xea8>
ffffffffc020574e:	05100593          	li	a1,81
ffffffffc0205752:	00002517          	auipc	a0,0x2
ffffffffc0205756:	3de50513          	addi	a0,a0,990 # ffffffffc0207b30 <default_pmm_manager+0xe90>
ffffffffc020575a:	da1fa0ef          	jal	ra,ffffffffc02004fa <__warn>
ffffffffc020575e:	bfc1                	j	ffffffffc020572e <wakeup_proc+0x56>
        intr_disable();
ffffffffc0205760:	a4efb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205764:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205766:	4485                	li	s1,1
ffffffffc0205768:	b771                	j	ffffffffc02056f4 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020576a:	00002697          	auipc	a3,0x2
ffffffffc020576e:	3a668693          	addi	a3,a3,934 # ffffffffc0207b10 <default_pmm_manager+0xe70>
ffffffffc0205772:	00001617          	auipc	a2,0x1
ffffffffc0205776:	17e60613          	addi	a2,a2,382 # ffffffffc02068f0 <commands+0x868>
ffffffffc020577a:	04200593          	li	a1,66
ffffffffc020577e:	00002517          	auipc	a0,0x2
ffffffffc0205782:	3b250513          	addi	a0,a0,946 # ffffffffc0207b30 <default_pmm_manager+0xe90>
ffffffffc0205786:	d0dfa0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020578a <schedule>:

void schedule(void)
{
ffffffffc020578a:	7179                	addi	sp,sp,-48
ffffffffc020578c:	f406                	sd	ra,40(sp)
ffffffffc020578e:	f022                	sd	s0,32(sp)
ffffffffc0205790:	ec26                	sd	s1,24(sp)
ffffffffc0205792:	e84a                	sd	s2,16(sp)
ffffffffc0205794:	e44e                	sd	s3,8(sp)
ffffffffc0205796:	e052                	sd	s4,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205798:	100027f3          	csrr	a5,sstatus
ffffffffc020579c:	8b89                	andi	a5,a5,2
ffffffffc020579e:	4a01                	li	s4,0
ffffffffc02057a0:	e3cd                	bnez	a5,ffffffffc0205842 <schedule+0xb8>
    bool intr_flag;
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02057a2:	000c1497          	auipc	s1,0xc1
ffffffffc02057a6:	43e48493          	addi	s1,s1,1086 # ffffffffc02c6be0 <current>
ffffffffc02057aa:	608c                	ld	a1,0(s1)
        sched_class->enqueue(rq, proc);
ffffffffc02057ac:	000c1997          	auipc	s3,0xc1
ffffffffc02057b0:	45c98993          	addi	s3,s3,1116 # ffffffffc02c6c08 <sched_class>
ffffffffc02057b4:	000c1917          	auipc	s2,0xc1
ffffffffc02057b8:	44c90913          	addi	s2,s2,1100 # ffffffffc02c6c00 <rq>
        if (current->state == PROC_RUNNABLE)
ffffffffc02057bc:	4194                	lw	a3,0(a1)
        current->need_resched = 0;
ffffffffc02057be:	0005bc23          	sd	zero,24(a1)
        if (current->state == PROC_RUNNABLE)
ffffffffc02057c2:	4709                	li	a4,2
        sched_class->enqueue(rq, proc);
ffffffffc02057c4:	0009b783          	ld	a5,0(s3)
ffffffffc02057c8:	00093503          	ld	a0,0(s2)
        if (current->state == PROC_RUNNABLE)
ffffffffc02057cc:	04e68e63          	beq	a3,a4,ffffffffc0205828 <schedule+0x9e>
    return sched_class->pick_next(rq);
ffffffffc02057d0:	739c                	ld	a5,32(a5)
ffffffffc02057d2:	9782                	jalr	a5
ffffffffc02057d4:	842a                	mv	s0,a0
        {
            sched_class_enqueue(current);
        }
        if ((next = sched_class_pick_next()) != NULL)
ffffffffc02057d6:	c521                	beqz	a0,ffffffffc020581e <schedule+0x94>
    sched_class->dequeue(rq, proc);
ffffffffc02057d8:	0009b783          	ld	a5,0(s3)
ffffffffc02057dc:	00093503          	ld	a0,0(s2)
ffffffffc02057e0:	85a2                	mv	a1,s0
ffffffffc02057e2:	6f9c                	ld	a5,24(a5)
ffffffffc02057e4:	9782                	jalr	a5
        }
        if (next == NULL)
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02057e6:	441c                	lw	a5,8(s0)
        if (next != current)
ffffffffc02057e8:	6098                	ld	a4,0(s1)
        next->runs++;
ffffffffc02057ea:	2785                	addiw	a5,a5,1
ffffffffc02057ec:	c41c                	sw	a5,8(s0)
        if (next != current)
ffffffffc02057ee:	00870563          	beq	a4,s0,ffffffffc02057f8 <schedule+0x6e>
        {
            proc_run(next);
ffffffffc02057f2:	8522                	mv	a0,s0
ffffffffc02057f4:	fd8fe0ef          	jal	ra,ffffffffc0203fcc <proc_run>
    if (flag)
ffffffffc02057f8:	000a1a63          	bnez	s4,ffffffffc020580c <schedule+0x82>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02057fc:	70a2                	ld	ra,40(sp)
ffffffffc02057fe:	7402                	ld	s0,32(sp)
ffffffffc0205800:	64e2                	ld	s1,24(sp)
ffffffffc0205802:	6942                	ld	s2,16(sp)
ffffffffc0205804:	69a2                	ld	s3,8(sp)
ffffffffc0205806:	6a02                	ld	s4,0(sp)
ffffffffc0205808:	6145                	addi	sp,sp,48
ffffffffc020580a:	8082                	ret
ffffffffc020580c:	7402                	ld	s0,32(sp)
ffffffffc020580e:	70a2                	ld	ra,40(sp)
ffffffffc0205810:	64e2                	ld	s1,24(sp)
ffffffffc0205812:	6942                	ld	s2,16(sp)
ffffffffc0205814:	69a2                	ld	s3,8(sp)
ffffffffc0205816:	6a02                	ld	s4,0(sp)
ffffffffc0205818:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc020581a:	98efb06f          	j	ffffffffc02009a8 <intr_enable>
            next = idleproc;
ffffffffc020581e:	000c1417          	auipc	s0,0xc1
ffffffffc0205822:	3ca43403          	ld	s0,970(s0) # ffffffffc02c6be8 <idleproc>
ffffffffc0205826:	b7c1                	j	ffffffffc02057e6 <schedule+0x5c>
    if (proc != idleproc)
ffffffffc0205828:	000c1717          	auipc	a4,0xc1
ffffffffc020582c:	3c073703          	ld	a4,960(a4) # ffffffffc02c6be8 <idleproc>
ffffffffc0205830:	fae580e3          	beq	a1,a4,ffffffffc02057d0 <schedule+0x46>
        sched_class->enqueue(rq, proc);
ffffffffc0205834:	6b9c                	ld	a5,16(a5)
ffffffffc0205836:	9782                	jalr	a5
    return sched_class->pick_next(rq);
ffffffffc0205838:	0009b783          	ld	a5,0(s3)
ffffffffc020583c:	00093503          	ld	a0,0(s2)
ffffffffc0205840:	bf41                	j	ffffffffc02057d0 <schedule+0x46>
        intr_disable();
ffffffffc0205842:	96cfb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0205846:	4a05                	li	s4,1
ffffffffc0205848:	bfa9                	j	ffffffffc02057a2 <schedule+0x18>

ffffffffc020584a <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc020584a:	000c1797          	auipc	a5,0xc1
ffffffffc020584e:	3967b783          	ld	a5,918(a5) # ffffffffc02c6be0 <current>
}
ffffffffc0205852:	43c8                	lw	a0,4(a5)
ffffffffc0205854:	8082                	ret

ffffffffc0205856 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205856:	4501                	li	a0,0
ffffffffc0205858:	8082                	ret

ffffffffc020585a <sys_gettime>:
static int sys_gettime(uint64_t arg[]){
    return (int)ticks*10;
ffffffffc020585a:	000c1797          	auipc	a5,0xc1
ffffffffc020585e:	3267b783          	ld	a5,806(a5) # ffffffffc02c6b80 <ticks>
ffffffffc0205862:	0027951b          	slliw	a0,a5,0x2
ffffffffc0205866:	9d3d                	addw	a0,a0,a5
}
ffffffffc0205868:	0015151b          	slliw	a0,a0,0x1
ffffffffc020586c:	8082                	ret

ffffffffc020586e <sys_lab6_set_priority>:
static int sys_lab6_set_priority(uint64_t arg[]){
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
ffffffffc020586e:	4108                	lw	a0,0(a0)
static int sys_lab6_set_priority(uint64_t arg[]){
ffffffffc0205870:	1141                	addi	sp,sp,-16
ffffffffc0205872:	e406                	sd	ra,8(sp)
    lab6_set_priority(priority);
ffffffffc0205874:	855ff0ef          	jal	ra,ffffffffc02050c8 <lab6_set_priority>
    return 0;
}
ffffffffc0205878:	60a2                	ld	ra,8(sp)
ffffffffc020587a:	4501                	li	a0,0
ffffffffc020587c:	0141                	addi	sp,sp,16
ffffffffc020587e:	8082                	ret

ffffffffc0205880 <sys_putc>:
    cputchar(c);
ffffffffc0205880:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205882:	1141                	addi	sp,sp,-16
ffffffffc0205884:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205886:	949fa0ef          	jal	ra,ffffffffc02001ce <cputchar>
}
ffffffffc020588a:	60a2                	ld	ra,8(sp)
ffffffffc020588c:	4501                	li	a0,0
ffffffffc020588e:	0141                	addi	sp,sp,16
ffffffffc0205890:	8082                	ret

ffffffffc0205892 <sys_kill>:
    return do_kill(pid);
ffffffffc0205892:	4108                	lw	a0,0(a0)
ffffffffc0205894:	e06ff06f          	j	ffffffffc0204e9a <do_kill>

ffffffffc0205898 <sys_yield>:
    return do_yield();
ffffffffc0205898:	db4ff06f          	j	ffffffffc0204e4c <do_yield>

ffffffffc020589c <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc020589c:	6d14                	ld	a3,24(a0)
ffffffffc020589e:	6910                	ld	a2,16(a0)
ffffffffc02058a0:	650c                	ld	a1,8(a0)
ffffffffc02058a2:	6108                	ld	a0,0(a0)
ffffffffc02058a4:	ffffe06f          	j	ffffffffc02048a2 <do_execve>

ffffffffc02058a8 <sys_wait>:
    return do_wait(pid, store);
ffffffffc02058a8:	650c                	ld	a1,8(a0)
ffffffffc02058aa:	4108                	lw	a0,0(a0)
ffffffffc02058ac:	db0ff06f          	j	ffffffffc0204e5c <do_wait>

ffffffffc02058b0 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02058b0:	000c1797          	auipc	a5,0xc1
ffffffffc02058b4:	3307b783          	ld	a5,816(a5) # ffffffffc02c6be0 <current>
ffffffffc02058b8:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02058ba:	4501                	li	a0,0
ffffffffc02058bc:	6a0c                	ld	a1,16(a2)
ffffffffc02058be:	f72fe06f          	j	ffffffffc0204030 <do_fork>

ffffffffc02058c2 <sys_exit>:
    return do_exit(error_code);
ffffffffc02058c2:	4108                	lw	a0,0(a0)
ffffffffc02058c4:	b9ffe06f          	j	ffffffffc0204462 <do_exit>

ffffffffc02058c8 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02058c8:	715d                	addi	sp,sp,-80
ffffffffc02058ca:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02058cc:	000c1497          	auipc	s1,0xc1
ffffffffc02058d0:	31448493          	addi	s1,s1,788 # ffffffffc02c6be0 <current>
ffffffffc02058d4:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02058d6:	e0a2                	sd	s0,64(sp)
ffffffffc02058d8:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02058da:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02058dc:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02058de:	0ff00793          	li	a5,255
    int num = tf->gpr.a0;
ffffffffc02058e2:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02058e6:	0327ee63          	bltu	a5,s2,ffffffffc0205922 <syscall+0x5a>
        if (syscalls[num] != NULL) {
ffffffffc02058ea:	00391713          	slli	a4,s2,0x3
ffffffffc02058ee:	00002797          	auipc	a5,0x2
ffffffffc02058f2:	2c278793          	addi	a5,a5,706 # ffffffffc0207bb0 <syscalls>
ffffffffc02058f6:	97ba                	add	a5,a5,a4
ffffffffc02058f8:	639c                	ld	a5,0(a5)
ffffffffc02058fa:	c785                	beqz	a5,ffffffffc0205922 <syscall+0x5a>
            arg[0] = tf->gpr.a1;
ffffffffc02058fc:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02058fe:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205900:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205902:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205904:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205906:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205908:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc020590a:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc020590c:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc020590e:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205910:	0028                	addi	a0,sp,8
ffffffffc0205912:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205914:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205916:	e828                	sd	a0,80(s0)
}
ffffffffc0205918:	6406                	ld	s0,64(sp)
ffffffffc020591a:	74e2                	ld	s1,56(sp)
ffffffffc020591c:	7942                	ld	s2,48(sp)
ffffffffc020591e:	6161                	addi	sp,sp,80
ffffffffc0205920:	8082                	ret
    print_trapframe(tf);
ffffffffc0205922:	8522                	mv	a0,s0
ffffffffc0205924:	a7afb0ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205928:	609c                	ld	a5,0(s1)
ffffffffc020592a:	86ca                	mv	a3,s2
ffffffffc020592c:	00002617          	auipc	a2,0x2
ffffffffc0205930:	23c60613          	addi	a2,a2,572 # ffffffffc0207b68 <default_pmm_manager+0xec8>
ffffffffc0205934:	43d8                	lw	a4,4(a5)
ffffffffc0205936:	06c00593          	li	a1,108
ffffffffc020593a:	0b478793          	addi	a5,a5,180
ffffffffc020593e:	00002517          	auipc	a0,0x2
ffffffffc0205942:	25a50513          	addi	a0,a0,602 # ffffffffc0207b98 <default_pmm_manager+0xef8>
ffffffffc0205946:	b4dfa0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020594a <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc020594a:	9e3707b7          	lui	a5,0x9e370
ffffffffc020594e:	2785                	addiw	a5,a5,1
ffffffffc0205950:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205954:	02000793          	li	a5,32
ffffffffc0205958:	9f8d                	subw	a5,a5,a1
}
ffffffffc020595a:	00f5553b          	srlw	a0,a0,a5
ffffffffc020595e:	8082                	ret

ffffffffc0205960 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205960:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205964:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0205966:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020596a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020596c:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205970:	f022                	sd	s0,32(sp)
ffffffffc0205972:	ec26                	sd	s1,24(sp)
ffffffffc0205974:	e84a                	sd	s2,16(sp)
ffffffffc0205976:	f406                	sd	ra,40(sp)
ffffffffc0205978:	e44e                	sd	s3,8(sp)
ffffffffc020597a:	84aa                	mv	s1,a0
ffffffffc020597c:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020597e:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0205982:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0205984:	03067e63          	bgeu	a2,a6,ffffffffc02059c0 <printnum+0x60>
ffffffffc0205988:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020598a:	00805763          	blez	s0,ffffffffc0205998 <printnum+0x38>
ffffffffc020598e:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205990:	85ca                	mv	a1,s2
ffffffffc0205992:	854e                	mv	a0,s3
ffffffffc0205994:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205996:	fc65                	bnez	s0,ffffffffc020598e <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205998:	1a02                	slli	s4,s4,0x20
ffffffffc020599a:	00003797          	auipc	a5,0x3
ffffffffc020599e:	a1678793          	addi	a5,a5,-1514 # ffffffffc02083b0 <syscalls+0x800>
ffffffffc02059a2:	020a5a13          	srli	s4,s4,0x20
ffffffffc02059a6:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02059a8:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02059aa:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02059ae:	70a2                	ld	ra,40(sp)
ffffffffc02059b0:	69a2                	ld	s3,8(sp)
ffffffffc02059b2:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02059b4:	85ca                	mv	a1,s2
ffffffffc02059b6:	87a6                	mv	a5,s1
}
ffffffffc02059b8:	6942                	ld	s2,16(sp)
ffffffffc02059ba:	64e2                	ld	s1,24(sp)
ffffffffc02059bc:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02059be:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02059c0:	03065633          	divu	a2,a2,a6
ffffffffc02059c4:	8722                	mv	a4,s0
ffffffffc02059c6:	f9bff0ef          	jal	ra,ffffffffc0205960 <printnum>
ffffffffc02059ca:	b7f9                	j	ffffffffc0205998 <printnum+0x38>

ffffffffc02059cc <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02059cc:	7119                	addi	sp,sp,-128
ffffffffc02059ce:	f4a6                	sd	s1,104(sp)
ffffffffc02059d0:	f0ca                	sd	s2,96(sp)
ffffffffc02059d2:	ecce                	sd	s3,88(sp)
ffffffffc02059d4:	e8d2                	sd	s4,80(sp)
ffffffffc02059d6:	e4d6                	sd	s5,72(sp)
ffffffffc02059d8:	e0da                	sd	s6,64(sp)
ffffffffc02059da:	fc5e                	sd	s7,56(sp)
ffffffffc02059dc:	f06a                	sd	s10,32(sp)
ffffffffc02059de:	fc86                	sd	ra,120(sp)
ffffffffc02059e0:	f8a2                	sd	s0,112(sp)
ffffffffc02059e2:	f862                	sd	s8,48(sp)
ffffffffc02059e4:	f466                	sd	s9,40(sp)
ffffffffc02059e6:	ec6e                	sd	s11,24(sp)
ffffffffc02059e8:	892a                	mv	s2,a0
ffffffffc02059ea:	84ae                	mv	s1,a1
ffffffffc02059ec:	8d32                	mv	s10,a2
ffffffffc02059ee:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02059f0:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02059f4:	5b7d                	li	s6,-1
ffffffffc02059f6:	00003a97          	auipc	s5,0x3
ffffffffc02059fa:	9e6a8a93          	addi	s5,s5,-1562 # ffffffffc02083dc <syscalls+0x82c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02059fe:	00003b97          	auipc	s7,0x3
ffffffffc0205a02:	bfab8b93          	addi	s7,s7,-1030 # ffffffffc02085f8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205a06:	000d4503          	lbu	a0,0(s10)
ffffffffc0205a0a:	001d0413          	addi	s0,s10,1
ffffffffc0205a0e:	01350a63          	beq	a0,s3,ffffffffc0205a22 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0205a12:	c121                	beqz	a0,ffffffffc0205a52 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205a14:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205a16:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0205a18:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205a1a:	fff44503          	lbu	a0,-1(s0)
ffffffffc0205a1e:	ff351ae3          	bne	a0,s3,ffffffffc0205a12 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a22:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205a26:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0205a2a:	4c81                	li	s9,0
ffffffffc0205a2c:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0205a2e:	5c7d                	li	s8,-1
ffffffffc0205a30:	5dfd                	li	s11,-1
ffffffffc0205a32:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205a36:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a38:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205a3c:	0ff5f593          	zext.b	a1,a1
ffffffffc0205a40:	00140d13          	addi	s10,s0,1
ffffffffc0205a44:	04b56263          	bltu	a0,a1,ffffffffc0205a88 <vprintfmt+0xbc>
ffffffffc0205a48:	058a                	slli	a1,a1,0x2
ffffffffc0205a4a:	95d6                	add	a1,a1,s5
ffffffffc0205a4c:	4194                	lw	a3,0(a1)
ffffffffc0205a4e:	96d6                	add	a3,a3,s5
ffffffffc0205a50:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205a52:	70e6                	ld	ra,120(sp)
ffffffffc0205a54:	7446                	ld	s0,112(sp)
ffffffffc0205a56:	74a6                	ld	s1,104(sp)
ffffffffc0205a58:	7906                	ld	s2,96(sp)
ffffffffc0205a5a:	69e6                	ld	s3,88(sp)
ffffffffc0205a5c:	6a46                	ld	s4,80(sp)
ffffffffc0205a5e:	6aa6                	ld	s5,72(sp)
ffffffffc0205a60:	6b06                	ld	s6,64(sp)
ffffffffc0205a62:	7be2                	ld	s7,56(sp)
ffffffffc0205a64:	7c42                	ld	s8,48(sp)
ffffffffc0205a66:	7ca2                	ld	s9,40(sp)
ffffffffc0205a68:	7d02                	ld	s10,32(sp)
ffffffffc0205a6a:	6de2                	ld	s11,24(sp)
ffffffffc0205a6c:	6109                	addi	sp,sp,128
ffffffffc0205a6e:	8082                	ret
            padc = '0';
ffffffffc0205a70:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0205a72:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a76:	846a                	mv	s0,s10
ffffffffc0205a78:	00140d13          	addi	s10,s0,1
ffffffffc0205a7c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205a80:	0ff5f593          	zext.b	a1,a1
ffffffffc0205a84:	fcb572e3          	bgeu	a0,a1,ffffffffc0205a48 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0205a88:	85a6                	mv	a1,s1
ffffffffc0205a8a:	02500513          	li	a0,37
ffffffffc0205a8e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205a90:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205a94:	8d22                	mv	s10,s0
ffffffffc0205a96:	f73788e3          	beq	a5,s3,ffffffffc0205a06 <vprintfmt+0x3a>
ffffffffc0205a9a:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0205a9e:	1d7d                	addi	s10,s10,-1
ffffffffc0205aa0:	ff379de3          	bne	a5,s3,ffffffffc0205a9a <vprintfmt+0xce>
ffffffffc0205aa4:	b78d                	j	ffffffffc0205a06 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205aa6:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205aaa:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205aae:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205ab0:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205ab4:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205ab8:	02d86463          	bltu	a6,a3,ffffffffc0205ae0 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0205abc:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205ac0:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205ac4:	0186873b          	addw	a4,a3,s8
ffffffffc0205ac8:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205acc:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205ace:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205ad2:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205ad4:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205ad8:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205adc:	fed870e3          	bgeu	a6,a3,ffffffffc0205abc <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205ae0:	f40ddce3          	bgez	s11,ffffffffc0205a38 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205ae4:	8de2                	mv	s11,s8
ffffffffc0205ae6:	5c7d                	li	s8,-1
ffffffffc0205ae8:	bf81                	j	ffffffffc0205a38 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205aea:	fffdc693          	not	a3,s11
ffffffffc0205aee:	96fd                	srai	a3,a3,0x3f
ffffffffc0205af0:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205af4:	00144603          	lbu	a2,1(s0)
ffffffffc0205af8:	2d81                	sext.w	s11,s11
ffffffffc0205afa:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205afc:	bf35                	j	ffffffffc0205a38 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205afe:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205b02:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205b06:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205b08:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205b0a:	bfd9                	j	ffffffffc0205ae0 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0205b0c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205b0e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205b12:	01174463          	blt	a4,a7,ffffffffc0205b1a <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205b16:	1a088e63          	beqz	a7,ffffffffc0205cd2 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0205b1a:	000a3603          	ld	a2,0(s4)
ffffffffc0205b1e:	46c1                	li	a3,16
ffffffffc0205b20:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205b22:	2781                	sext.w	a5,a5
ffffffffc0205b24:	876e                	mv	a4,s11
ffffffffc0205b26:	85a6                	mv	a1,s1
ffffffffc0205b28:	854a                	mv	a0,s2
ffffffffc0205b2a:	e37ff0ef          	jal	ra,ffffffffc0205960 <printnum>
            break;
ffffffffc0205b2e:	bde1                	j	ffffffffc0205a06 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0205b30:	000a2503          	lw	a0,0(s4)
ffffffffc0205b34:	85a6                	mv	a1,s1
ffffffffc0205b36:	0a21                	addi	s4,s4,8
ffffffffc0205b38:	9902                	jalr	s2
            break;
ffffffffc0205b3a:	b5f1                	j	ffffffffc0205a06 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205b3c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205b3e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205b42:	01174463          	blt	a4,a7,ffffffffc0205b4a <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205b46:	18088163          	beqz	a7,ffffffffc0205cc8 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0205b4a:	000a3603          	ld	a2,0(s4)
ffffffffc0205b4e:	46a9                	li	a3,10
ffffffffc0205b50:	8a2e                	mv	s4,a1
ffffffffc0205b52:	bfc1                	j	ffffffffc0205b22 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205b54:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0205b58:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205b5a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205b5c:	bdf1                	j	ffffffffc0205a38 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0205b5e:	85a6                	mv	a1,s1
ffffffffc0205b60:	02500513          	li	a0,37
ffffffffc0205b64:	9902                	jalr	s2
            break;
ffffffffc0205b66:	b545                	j	ffffffffc0205a06 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205b68:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0205b6c:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205b6e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205b70:	b5e1                	j	ffffffffc0205a38 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205b72:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205b74:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205b78:	01174463          	blt	a4,a7,ffffffffc0205b80 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0205b7c:	14088163          	beqz	a7,ffffffffc0205cbe <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0205b80:	000a3603          	ld	a2,0(s4)
ffffffffc0205b84:	46a1                	li	a3,8
ffffffffc0205b86:	8a2e                	mv	s4,a1
ffffffffc0205b88:	bf69                	j	ffffffffc0205b22 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0205b8a:	03000513          	li	a0,48
ffffffffc0205b8e:	85a6                	mv	a1,s1
ffffffffc0205b90:	e03e                	sd	a5,0(sp)
ffffffffc0205b92:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205b94:	85a6                	mv	a1,s1
ffffffffc0205b96:	07800513          	li	a0,120
ffffffffc0205b9a:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205b9c:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205b9e:	6782                	ld	a5,0(sp)
ffffffffc0205ba0:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205ba2:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205ba6:	bfb5                	j	ffffffffc0205b22 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205ba8:	000a3403          	ld	s0,0(s4)
ffffffffc0205bac:	008a0713          	addi	a4,s4,8
ffffffffc0205bb0:	e03a                	sd	a4,0(sp)
ffffffffc0205bb2:	14040263          	beqz	s0,ffffffffc0205cf6 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205bb6:	0fb05763          	blez	s11,ffffffffc0205ca4 <vprintfmt+0x2d8>
ffffffffc0205bba:	02d00693          	li	a3,45
ffffffffc0205bbe:	0cd79163          	bne	a5,a3,ffffffffc0205c80 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205bc2:	00044783          	lbu	a5,0(s0)
ffffffffc0205bc6:	0007851b          	sext.w	a0,a5
ffffffffc0205bca:	cf85                	beqz	a5,ffffffffc0205c02 <vprintfmt+0x236>
ffffffffc0205bcc:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205bd0:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205bd4:	000c4563          	bltz	s8,ffffffffc0205bde <vprintfmt+0x212>
ffffffffc0205bd8:	3c7d                	addiw	s8,s8,-1
ffffffffc0205bda:	036c0263          	beq	s8,s6,ffffffffc0205bfe <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205bde:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205be0:	0e0c8e63          	beqz	s9,ffffffffc0205cdc <vprintfmt+0x310>
ffffffffc0205be4:	3781                	addiw	a5,a5,-32
ffffffffc0205be6:	0ef47b63          	bgeu	s0,a5,ffffffffc0205cdc <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205bea:	03f00513          	li	a0,63
ffffffffc0205bee:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205bf0:	000a4783          	lbu	a5,0(s4)
ffffffffc0205bf4:	3dfd                	addiw	s11,s11,-1
ffffffffc0205bf6:	0a05                	addi	s4,s4,1
ffffffffc0205bf8:	0007851b          	sext.w	a0,a5
ffffffffc0205bfc:	ffe1                	bnez	a5,ffffffffc0205bd4 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205bfe:	01b05963          	blez	s11,ffffffffc0205c10 <vprintfmt+0x244>
ffffffffc0205c02:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205c04:	85a6                	mv	a1,s1
ffffffffc0205c06:	02000513          	li	a0,32
ffffffffc0205c0a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205c0c:	fe0d9be3          	bnez	s11,ffffffffc0205c02 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205c10:	6a02                	ld	s4,0(sp)
ffffffffc0205c12:	bbd5                	j	ffffffffc0205a06 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205c14:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205c16:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0205c1a:	01174463          	blt	a4,a7,ffffffffc0205c22 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205c1e:	08088d63          	beqz	a7,ffffffffc0205cb8 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205c22:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205c26:	0a044d63          	bltz	s0,ffffffffc0205ce0 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205c2a:	8622                	mv	a2,s0
ffffffffc0205c2c:	8a66                	mv	s4,s9
ffffffffc0205c2e:	46a9                	li	a3,10
ffffffffc0205c30:	bdcd                	j	ffffffffc0205b22 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205c32:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205c36:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205c38:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205c3a:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0205c3e:	8fb5                	xor	a5,a5,a3
ffffffffc0205c40:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205c44:	02d74163          	blt	a4,a3,ffffffffc0205c66 <vprintfmt+0x29a>
ffffffffc0205c48:	00369793          	slli	a5,a3,0x3
ffffffffc0205c4c:	97de                	add	a5,a5,s7
ffffffffc0205c4e:	639c                	ld	a5,0(a5)
ffffffffc0205c50:	cb99                	beqz	a5,ffffffffc0205c66 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205c52:	86be                	mv	a3,a5
ffffffffc0205c54:	00000617          	auipc	a2,0x0
ffffffffc0205c58:	1f460613          	addi	a2,a2,500 # ffffffffc0205e48 <etext+0x2e>
ffffffffc0205c5c:	85a6                	mv	a1,s1
ffffffffc0205c5e:	854a                	mv	a0,s2
ffffffffc0205c60:	0ce000ef          	jal	ra,ffffffffc0205d2e <printfmt>
ffffffffc0205c64:	b34d                	j	ffffffffc0205a06 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205c66:	00002617          	auipc	a2,0x2
ffffffffc0205c6a:	76a60613          	addi	a2,a2,1898 # ffffffffc02083d0 <syscalls+0x820>
ffffffffc0205c6e:	85a6                	mv	a1,s1
ffffffffc0205c70:	854a                	mv	a0,s2
ffffffffc0205c72:	0bc000ef          	jal	ra,ffffffffc0205d2e <printfmt>
ffffffffc0205c76:	bb41                	j	ffffffffc0205a06 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205c78:	00002417          	auipc	s0,0x2
ffffffffc0205c7c:	75040413          	addi	s0,s0,1872 # ffffffffc02083c8 <syscalls+0x818>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205c80:	85e2                	mv	a1,s8
ffffffffc0205c82:	8522                	mv	a0,s0
ffffffffc0205c84:	e43e                	sd	a5,8(sp)
ffffffffc0205c86:	0e2000ef          	jal	ra,ffffffffc0205d68 <strnlen>
ffffffffc0205c8a:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0205c8e:	01b05b63          	blez	s11,ffffffffc0205ca4 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205c92:	67a2                	ld	a5,8(sp)
ffffffffc0205c94:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205c98:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205c9a:	85a6                	mv	a1,s1
ffffffffc0205c9c:	8552                	mv	a0,s4
ffffffffc0205c9e:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205ca0:	fe0d9ce3          	bnez	s11,ffffffffc0205c98 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205ca4:	00044783          	lbu	a5,0(s0)
ffffffffc0205ca8:	00140a13          	addi	s4,s0,1
ffffffffc0205cac:	0007851b          	sext.w	a0,a5
ffffffffc0205cb0:	d3a5                	beqz	a5,ffffffffc0205c10 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205cb2:	05e00413          	li	s0,94
ffffffffc0205cb6:	bf39                	j	ffffffffc0205bd4 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205cb8:	000a2403          	lw	s0,0(s4)
ffffffffc0205cbc:	b7ad                	j	ffffffffc0205c26 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205cbe:	000a6603          	lwu	a2,0(s4)
ffffffffc0205cc2:	46a1                	li	a3,8
ffffffffc0205cc4:	8a2e                	mv	s4,a1
ffffffffc0205cc6:	bdb1                	j	ffffffffc0205b22 <vprintfmt+0x156>
ffffffffc0205cc8:	000a6603          	lwu	a2,0(s4)
ffffffffc0205ccc:	46a9                	li	a3,10
ffffffffc0205cce:	8a2e                	mv	s4,a1
ffffffffc0205cd0:	bd89                	j	ffffffffc0205b22 <vprintfmt+0x156>
ffffffffc0205cd2:	000a6603          	lwu	a2,0(s4)
ffffffffc0205cd6:	46c1                	li	a3,16
ffffffffc0205cd8:	8a2e                	mv	s4,a1
ffffffffc0205cda:	b5a1                	j	ffffffffc0205b22 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205cdc:	9902                	jalr	s2
ffffffffc0205cde:	bf09                	j	ffffffffc0205bf0 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205ce0:	85a6                	mv	a1,s1
ffffffffc0205ce2:	02d00513          	li	a0,45
ffffffffc0205ce6:	e03e                	sd	a5,0(sp)
ffffffffc0205ce8:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205cea:	6782                	ld	a5,0(sp)
ffffffffc0205cec:	8a66                	mv	s4,s9
ffffffffc0205cee:	40800633          	neg	a2,s0
ffffffffc0205cf2:	46a9                	li	a3,10
ffffffffc0205cf4:	b53d                	j	ffffffffc0205b22 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205cf6:	03b05163          	blez	s11,ffffffffc0205d18 <vprintfmt+0x34c>
ffffffffc0205cfa:	02d00693          	li	a3,45
ffffffffc0205cfe:	f6d79de3          	bne	a5,a3,ffffffffc0205c78 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205d02:	00002417          	auipc	s0,0x2
ffffffffc0205d06:	6c640413          	addi	s0,s0,1734 # ffffffffc02083c8 <syscalls+0x818>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205d0a:	02800793          	li	a5,40
ffffffffc0205d0e:	02800513          	li	a0,40
ffffffffc0205d12:	00140a13          	addi	s4,s0,1
ffffffffc0205d16:	bd6d                	j	ffffffffc0205bd0 <vprintfmt+0x204>
ffffffffc0205d18:	00002a17          	auipc	s4,0x2
ffffffffc0205d1c:	6b1a0a13          	addi	s4,s4,1713 # ffffffffc02083c9 <syscalls+0x819>
ffffffffc0205d20:	02800513          	li	a0,40
ffffffffc0205d24:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205d28:	05e00413          	li	s0,94
ffffffffc0205d2c:	b565                	j	ffffffffc0205bd4 <vprintfmt+0x208>

ffffffffc0205d2e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205d2e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205d30:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205d34:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205d36:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205d38:	ec06                	sd	ra,24(sp)
ffffffffc0205d3a:	f83a                	sd	a4,48(sp)
ffffffffc0205d3c:	fc3e                	sd	a5,56(sp)
ffffffffc0205d3e:	e0c2                	sd	a6,64(sp)
ffffffffc0205d40:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205d42:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205d44:	c89ff0ef          	jal	ra,ffffffffc02059cc <vprintfmt>
}
ffffffffc0205d48:	60e2                	ld	ra,24(sp)
ffffffffc0205d4a:	6161                	addi	sp,sp,80
ffffffffc0205d4c:	8082                	ret

ffffffffc0205d4e <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205d4e:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205d52:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205d54:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205d56:	cb81                	beqz	a5,ffffffffc0205d66 <strlen+0x18>
        cnt ++;
ffffffffc0205d58:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0205d5a:	00a707b3          	add	a5,a4,a0
ffffffffc0205d5e:	0007c783          	lbu	a5,0(a5)
ffffffffc0205d62:	fbfd                	bnez	a5,ffffffffc0205d58 <strlen+0xa>
ffffffffc0205d64:	8082                	ret
    }
    return cnt;
}
ffffffffc0205d66:	8082                	ret

ffffffffc0205d68 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205d68:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205d6a:	e589                	bnez	a1,ffffffffc0205d74 <strnlen+0xc>
ffffffffc0205d6c:	a811                	j	ffffffffc0205d80 <strnlen+0x18>
        cnt ++;
ffffffffc0205d6e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205d70:	00f58863          	beq	a1,a5,ffffffffc0205d80 <strnlen+0x18>
ffffffffc0205d74:	00f50733          	add	a4,a0,a5
ffffffffc0205d78:	00074703          	lbu	a4,0(a4)
ffffffffc0205d7c:	fb6d                	bnez	a4,ffffffffc0205d6e <strnlen+0x6>
ffffffffc0205d7e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205d80:	852e                	mv	a0,a1
ffffffffc0205d82:	8082                	ret

ffffffffc0205d84 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205d84:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205d86:	0005c703          	lbu	a4,0(a1)
ffffffffc0205d8a:	0785                	addi	a5,a5,1
ffffffffc0205d8c:	0585                	addi	a1,a1,1
ffffffffc0205d8e:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205d92:	fb75                	bnez	a4,ffffffffc0205d86 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205d94:	8082                	ret

ffffffffc0205d96 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205d96:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205d9a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205d9e:	cb89                	beqz	a5,ffffffffc0205db0 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205da0:	0505                	addi	a0,a0,1
ffffffffc0205da2:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205da4:	fee789e3          	beq	a5,a4,ffffffffc0205d96 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205da8:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205dac:	9d19                	subw	a0,a0,a4
ffffffffc0205dae:	8082                	ret
ffffffffc0205db0:	4501                	li	a0,0
ffffffffc0205db2:	bfed                	j	ffffffffc0205dac <strcmp+0x16>

ffffffffc0205db4 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205db4:	c20d                	beqz	a2,ffffffffc0205dd6 <strncmp+0x22>
ffffffffc0205db6:	962e                	add	a2,a2,a1
ffffffffc0205db8:	a031                	j	ffffffffc0205dc4 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205dba:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205dbc:	00e79a63          	bne	a5,a4,ffffffffc0205dd0 <strncmp+0x1c>
ffffffffc0205dc0:	00b60b63          	beq	a2,a1,ffffffffc0205dd6 <strncmp+0x22>
ffffffffc0205dc4:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205dc8:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205dca:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205dce:	f7f5                	bnez	a5,ffffffffc0205dba <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205dd0:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205dd4:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205dd6:	4501                	li	a0,0
ffffffffc0205dd8:	8082                	ret

ffffffffc0205dda <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205dda:	00054783          	lbu	a5,0(a0)
ffffffffc0205dde:	c799                	beqz	a5,ffffffffc0205dec <strchr+0x12>
        if (*s == c) {
ffffffffc0205de0:	00f58763          	beq	a1,a5,ffffffffc0205dee <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205de4:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205de8:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205dea:	fbfd                	bnez	a5,ffffffffc0205de0 <strchr+0x6>
    }
    return NULL;
ffffffffc0205dec:	4501                	li	a0,0
}
ffffffffc0205dee:	8082                	ret

ffffffffc0205df0 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205df0:	ca01                	beqz	a2,ffffffffc0205e00 <memset+0x10>
ffffffffc0205df2:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205df4:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205df6:	0785                	addi	a5,a5,1
ffffffffc0205df8:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205dfc:	fec79de3          	bne	a5,a2,ffffffffc0205df6 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205e00:	8082                	ret

ffffffffc0205e02 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205e02:	ca19                	beqz	a2,ffffffffc0205e18 <memcpy+0x16>
ffffffffc0205e04:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205e06:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205e08:	0005c703          	lbu	a4,0(a1)
ffffffffc0205e0c:	0585                	addi	a1,a1,1
ffffffffc0205e0e:	0785                	addi	a5,a5,1
ffffffffc0205e10:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205e14:	fec59ae3          	bne	a1,a2,ffffffffc0205e08 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205e18:	8082                	ret
