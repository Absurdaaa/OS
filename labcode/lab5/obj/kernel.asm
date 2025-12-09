
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
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
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

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
ffffffffc020004a:	000a6517          	auipc	a0,0xa6
ffffffffc020004e:	29650513          	addi	a0,a0,662 # ffffffffc02a62e0 <buf>
ffffffffc0200052:	000aa617          	auipc	a2,0xaa
ffffffffc0200056:	74260613          	addi	a2,a2,1858 # ffffffffc02aa794 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	001050ef          	jal	ra,ffffffffc0205862 <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	82258593          	addi	a1,a1,-2014 # ffffffffc0205890 <etext+0x4>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	83a50513          	addi	a0,a0,-1990 # ffffffffc02058b0 <etext+0x24>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	754020ef          	jal	ra,ffffffffc02027da <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	157030ef          	jal	ra,ffffffffc02039e8 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	71f040ef          	jal	ra,ffffffffc0204fb4 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	0aa050ef          	jal	ra,ffffffffc020514c <cpu_idle>

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
ffffffffc02000bc:	00005517          	auipc	a0,0x5
ffffffffc02000c0:	7fc50513          	addi	a0,a0,2044 # ffffffffc02058b8 <etext+0x2c>
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
ffffffffc02000d2:	000a6b97          	auipc	s7,0xa6
ffffffffc02000d6:	20eb8b93          	addi	s7,s7,526 # ffffffffc02a62e0 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	12e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	11e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	10c000ef          	jal	ra,ffffffffc020020c <getchar>
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
ffffffffc020012e:	000a6517          	auipc	a0,0xa6
ffffffffc0200132:	1b250513          	addi	a0,a0,434 # ffffffffc02a62e0 <buf>
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
ffffffffc0200162:	42c000ef          	jal	ra,ffffffffc020058e <cons_putc>
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
ffffffffc0200188:	2b6050ef          	jal	ra,ffffffffc020543e <vprintfmt>
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
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
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
ffffffffc02001be:	280050ef          	jal	ra,ffffffffc020543e <vprintfmt>
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
ffffffffc02001ca:	a6d1                	j	ffffffffc020058e <cons_putc>

ffffffffc02001cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001cc:	1101                	addi	sp,sp,-32
ffffffffc02001ce:	e822                	sd	s0,16(sp)
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e426                	sd	s1,8(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3c>
ffffffffc02001dc:	0405                	addi	s0,s0,1
ffffffffc02001de:	4485                	li	s1,1
ffffffffc02001e0:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e2:	3ac000ef          	jal	ra,ffffffffc020058e <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	008487bb          	addw	a5,s1,s0
ffffffffc02001ee:	0405                	addi	s0,s0,1
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f2:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f6:	4529                	li	a0,10
ffffffffc02001f8:	396000ef          	jal	ra,ffffffffc020058e <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fc:	60e2                	ld	ra,24(sp)
ffffffffc02001fe:	8522                	mv	a0,s0
ffffffffc0200200:	6442                	ld	s0,16(sp)
ffffffffc0200202:	64a2                	ld	s1,8(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc0200208:	4405                	li	s0,1
ffffffffc020020a:	b7f5                	j	ffffffffc02001f6 <cputs+0x2a>

ffffffffc020020c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020020c:	1141                	addi	sp,sp,-16
ffffffffc020020e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200210:	3b2000ef          	jal	ra,ffffffffc02005c2 <cons_getc>
ffffffffc0200214:	dd75                	beqz	a0,ffffffffc0200210 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200216:	60a2                	ld	ra,8(sp)
ffffffffc0200218:	0141                	addi	sp,sp,16
ffffffffc020021a:	8082                	ret

ffffffffc020021c <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020021c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020021e:	00005517          	auipc	a0,0x5
ffffffffc0200222:	6a250513          	addi	a0,a0,1698 # ffffffffc02058c0 <etext+0x34>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	6ac50513          	addi	a0,a0,1708 # ffffffffc02058e0 <etext+0x54>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	64c58593          	addi	a1,a1,1612 # ffffffffc020588c <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	6b850513          	addi	a0,a0,1720 # ffffffffc0205900 <etext+0x74>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000a6597          	auipc	a1,0xa6
ffffffffc0200258:	08c58593          	addi	a1,a1,140 # ffffffffc02a62e0 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	6c450513          	addi	a0,a0,1732 # ffffffffc0205920 <etext+0x94>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000aa597          	auipc	a1,0xaa
ffffffffc020026c:	52c58593          	addi	a1,a1,1324 # ffffffffc02aa794 <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	6d050513          	addi	a0,a0,1744 # ffffffffc0205940 <etext+0xb4>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000ab597          	auipc	a1,0xab
ffffffffc0200280:	91758593          	addi	a1,a1,-1769 # ffffffffc02aab93 <end+0x3ff>
ffffffffc0200284:	00000797          	auipc	a5,0x0
ffffffffc0200288:	dc678793          	addi	a5,a5,-570 # ffffffffc020004a <kern_init>
ffffffffc020028c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200294:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200296:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029a:	95be                	add	a1,a1,a5
ffffffffc020029c:	85a9                	srai	a1,a1,0xa
ffffffffc020029e:	00005517          	auipc	a0,0x5
ffffffffc02002a2:	6c250513          	addi	a0,a0,1730 # ffffffffc0205960 <etext+0xd4>
}
ffffffffc02002a6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	b5f5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002aa <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002aa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ac:	00005617          	auipc	a2,0x5
ffffffffc02002b0:	6e460613          	addi	a2,a2,1764 # ffffffffc0205990 <etext+0x104>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	6f050513          	addi	a0,a0,1776 # ffffffffc02059a8 <etext+0x11c>
{
ffffffffc02002c0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c2:	1cc000ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02002c6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002c6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c8:	00005617          	auipc	a2,0x5
ffffffffc02002cc:	6f860613          	addi	a2,a2,1784 # ffffffffc02059c0 <etext+0x134>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	71058593          	addi	a1,a1,1808 # ffffffffc02059e0 <etext+0x154>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	71050513          	addi	a0,a0,1808 # ffffffffc02059e8 <etext+0x15c>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	71260613          	addi	a2,a2,1810 # ffffffffc02059f8 <etext+0x16c>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	73258593          	addi	a1,a1,1842 # ffffffffc0205a20 <etext+0x194>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	6f250513          	addi	a0,a0,1778 # ffffffffc02059e8 <etext+0x15c>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	72e60613          	addi	a2,a2,1838 # ffffffffc0205a30 <etext+0x1a4>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	74658593          	addi	a1,a1,1862 # ffffffffc0205a50 <etext+0x1c4>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	6d650513          	addi	a0,a0,1750 # ffffffffc02059e8 <etext+0x15c>
ffffffffc020031a:	e7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc020031e:	60a2                	ld	ra,8(sp)
ffffffffc0200320:	4501                	li	a0,0
ffffffffc0200322:	0141                	addi	sp,sp,16
ffffffffc0200324:	8082                	ret

ffffffffc0200326 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200326:	1141                	addi	sp,sp,-16
ffffffffc0200328:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032a:	ef3ff0ef          	jal	ra,ffffffffc020021c <print_kerninfo>
    return 0;
}
ffffffffc020032e:	60a2                	ld	ra,8(sp)
ffffffffc0200330:	4501                	li	a0,0
ffffffffc0200332:	0141                	addi	sp,sp,16
ffffffffc0200334:	8082                	ret

ffffffffc0200336 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200336:	1141                	addi	sp,sp,-16
ffffffffc0200338:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033a:	f71ff0ef          	jal	ra,ffffffffc02002aa <print_stackframe>
    return 0;
}
ffffffffc020033e:	60a2                	ld	ra,8(sp)
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	0141                	addi	sp,sp,16
ffffffffc0200344:	8082                	ret

ffffffffc0200346 <kmonitor>:
{
ffffffffc0200346:	7115                	addi	sp,sp,-224
ffffffffc0200348:	ed5e                	sd	s7,152(sp)
ffffffffc020034a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020034c:	00005517          	auipc	a0,0x5
ffffffffc0200350:	71450513          	addi	a0,a0,1812 # ffffffffc0205a60 <etext+0x1d4>
{
ffffffffc0200354:	ed86                	sd	ra,216(sp)
ffffffffc0200356:	e9a2                	sd	s0,208(sp)
ffffffffc0200358:	e5a6                	sd	s1,200(sp)
ffffffffc020035a:	e1ca                	sd	s2,192(sp)
ffffffffc020035c:	fd4e                	sd	s3,184(sp)
ffffffffc020035e:	f952                	sd	s4,176(sp)
ffffffffc0200360:	f556                	sd	s5,168(sp)
ffffffffc0200362:	f15a                	sd	s6,160(sp)
ffffffffc0200364:	e962                	sd	s8,144(sp)
ffffffffc0200366:	e566                	sd	s9,136(sp)
ffffffffc0200368:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	e2bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036e:	00005517          	auipc	a0,0x5
ffffffffc0200372:	71a50513          	addi	a0,a0,1818 # ffffffffc0205a88 <etext+0x1fc>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	774c0c13          	addi	s8,s8,1908 # ffffffffc0205af8 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	72490913          	addi	s2,s2,1828 # ffffffffc0205ab0 <etext+0x224>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	72448493          	addi	s1,s1,1828 # ffffffffc0205ab8 <etext+0x22c>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	722b0b13          	addi	s6,s6,1826 # ffffffffc0205ac0 <etext+0x234>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	63aa0a13          	addi	s4,s4,1594 # ffffffffc02059e0 <etext+0x154>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003ae:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL)
ffffffffc02003b0:	854a                	mv	a0,s2
ffffffffc02003b2:	cf5ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc02003b6:	842a                	mv	s0,a0
ffffffffc02003b8:	dd65                	beqz	a0,ffffffffc02003b0 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ba:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003be:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003c0:	e1bd                	bnez	a1,ffffffffc0200426 <kmonitor+0xe0>
    if (argc == 0)
ffffffffc02003c2:	fe0c87e3          	beqz	s9,ffffffffc02003b0 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003c6:	6582                	ld	a1,0(sp)
ffffffffc02003c8:	00005d17          	auipc	s10,0x5
ffffffffc02003cc:	730d0d13          	addi	s10,s10,1840 # ffffffffc0205af8 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	432050ef          	jal	ra,ffffffffc0205808 <strcmp>
ffffffffc02003da:	c919                	beqz	a0,ffffffffc02003f0 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003dc:	2405                	addiw	s0,s0,1
ffffffffc02003de:	0b540063          	beq	s0,s5,ffffffffc020047e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003e2:	000d3503          	ld	a0,0(s10)
ffffffffc02003e6:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003ea:	41e050ef          	jal	ra,ffffffffc0205808 <strcmp>
ffffffffc02003ee:	f57d                	bnez	a0,ffffffffc02003dc <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f0:	00141793          	slli	a5,s0,0x1
ffffffffc02003f4:	97a2                	add	a5,a5,s0
ffffffffc02003f6:	078e                	slli	a5,a5,0x3
ffffffffc02003f8:	97e2                	add	a5,a5,s8
ffffffffc02003fa:	6b9c                	ld	a5,16(a5)
ffffffffc02003fc:	865e                	mv	a2,s7
ffffffffc02003fe:	002c                	addi	a1,sp,8
ffffffffc0200400:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200404:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200406:	fa0555e3          	bgez	a0,ffffffffc02003b0 <kmonitor+0x6a>
}
ffffffffc020040a:	60ee                	ld	ra,216(sp)
ffffffffc020040c:	644e                	ld	s0,208(sp)
ffffffffc020040e:	64ae                	ld	s1,200(sp)
ffffffffc0200410:	690e                	ld	s2,192(sp)
ffffffffc0200412:	79ea                	ld	s3,184(sp)
ffffffffc0200414:	7a4a                	ld	s4,176(sp)
ffffffffc0200416:	7aaa                	ld	s5,168(sp)
ffffffffc0200418:	7b0a                	ld	s6,160(sp)
ffffffffc020041a:	6bea                	ld	s7,152(sp)
ffffffffc020041c:	6c4a                	ld	s8,144(sp)
ffffffffc020041e:	6caa                	ld	s9,136(sp)
ffffffffc0200420:	6d0a                	ld	s10,128(sp)
ffffffffc0200422:	612d                	addi	sp,sp,224
ffffffffc0200424:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200426:	8526                	mv	a0,s1
ffffffffc0200428:	424050ef          	jal	ra,ffffffffc020584c <strchr>
ffffffffc020042c:	c901                	beqz	a0,ffffffffc020043c <kmonitor+0xf6>
ffffffffc020042e:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc0200432:	00040023          	sb	zero,0(s0)
ffffffffc0200436:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200438:	d5c9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc020043a:	b7f5                	j	ffffffffc0200426 <kmonitor+0xe0>
        if (*buf == '\0')
ffffffffc020043c:	00044783          	lbu	a5,0(s0)
ffffffffc0200440:	d3c9                	beqz	a5,ffffffffc02003c2 <kmonitor+0x7c>
        if (argc == MAXARGS - 1)
ffffffffc0200442:	033c8963          	beq	s9,s3,ffffffffc0200474 <kmonitor+0x12e>
        argv[argc++] = buf;
ffffffffc0200446:	003c9793          	slli	a5,s9,0x3
ffffffffc020044a:	0118                	addi	a4,sp,128
ffffffffc020044c:	97ba                	add	a5,a5,a4
ffffffffc020044e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200452:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc0200456:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200458:	e591                	bnez	a1,ffffffffc0200464 <kmonitor+0x11e>
ffffffffc020045a:	b7b5                	j	ffffffffc02003c6 <kmonitor+0x80>
ffffffffc020045c:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200462:	d1a5                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200464:	8526                	mv	a0,s1
ffffffffc0200466:	3e6050ef          	jal	ra,ffffffffc020584c <strchr>
ffffffffc020046a:	d96d                	beqz	a0,ffffffffc020045c <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020046c:	00044583          	lbu	a1,0(s0)
ffffffffc0200470:	d9a9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200472:	bf55                	j	ffffffffc0200426 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200474:	45c1                	li	a1,16
ffffffffc0200476:	855a                	mv	a0,s6
ffffffffc0200478:	d1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020047c:	b7e9                	j	ffffffffc0200446 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020047e:	6582                	ld	a1,0(sp)
ffffffffc0200480:	00005517          	auipc	a0,0x5
ffffffffc0200484:	66050513          	addi	a0,a0,1632 # ffffffffc0205ae0 <etext+0x254>
ffffffffc0200488:	d0dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc020048c:	b715                	j	ffffffffc02003b0 <kmonitor+0x6a>

ffffffffc020048e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc020048e:	000aa317          	auipc	t1,0xaa
ffffffffc0200492:	27a30313          	addi	t1,t1,634 # ffffffffc02aa708 <is_panic>
ffffffffc0200496:	00033e03          	ld	t3,0(t1)
{
ffffffffc020049a:	715d                	addi	sp,sp,-80
ffffffffc020049c:	ec06                	sd	ra,24(sp)
ffffffffc020049e:	e822                	sd	s0,16(sp)
ffffffffc02004a0:	f436                	sd	a3,40(sp)
ffffffffc02004a2:	f83a                	sd	a4,48(sp)
ffffffffc02004a4:	fc3e                	sd	a5,56(sp)
ffffffffc02004a6:	e0c2                	sd	a6,64(sp)
ffffffffc02004a8:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc02004aa:	020e1a63          	bnez	t3,ffffffffc02004de <__panic+0x50>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004ae:	4785                	li	a5,1
ffffffffc02004b0:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	8432                	mv	s0,a2
ffffffffc02004b6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b8:	862e                	mv	a2,a1
ffffffffc02004ba:	85aa                	mv	a1,a0
ffffffffc02004bc:	00005517          	auipc	a0,0x5
ffffffffc02004c0:	68450513          	addi	a0,a0,1668 # ffffffffc0205b40 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	ccfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	ca7ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00006517          	auipc	a0,0x6
ffffffffc02004d6:	7b650513          	addi	a0,a0,1974 # ffffffffc0206c88 <default_pmm_manager+0x578>
ffffffffc02004da:	cbbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004de:	4501                	li	a0,0
ffffffffc02004e0:	4581                	li	a1,0
ffffffffc02004e2:	4601                	li	a2,0
ffffffffc02004e4:	48a1                	li	a7,8
ffffffffc02004e6:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ea:	4ca000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	e57ff0ef          	jal	ra,ffffffffc0200346 <kmonitor>
    while (1)
ffffffffc02004f4:	bfed                	j	ffffffffc02004ee <__panic+0x60>

ffffffffc02004f6 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004f6:	715d                	addi	sp,sp,-80
ffffffffc02004f8:	832e                	mv	t1,a1
ffffffffc02004fa:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fc:	85aa                	mv	a1,a0
{
ffffffffc02004fe:	8432                	mv	s0,a2
ffffffffc0200500:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200502:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200504:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	00005517          	auipc	a0,0x5
ffffffffc020050a:	65a50513          	addi	a0,a0,1626 # ffffffffc0205b60 <commands+0x68>
{
ffffffffc020050e:	ec06                	sd	ra,24(sp)
ffffffffc0200510:	f436                	sd	a3,40(sp)
ffffffffc0200512:	f83a                	sd	a4,48(sp)
ffffffffc0200514:	e0c2                	sd	a6,64(sp)
ffffffffc0200516:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200518:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051a:	c7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020051e:	65a2                	ld	a1,8(sp)
ffffffffc0200520:	8522                	mv	a0,s0
ffffffffc0200522:	c53ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc0200526:	00006517          	auipc	a0,0x6
ffffffffc020052a:	76250513          	addi	a0,a0,1890 # ffffffffc0206c88 <default_pmm_manager+0x578>
ffffffffc020052e:	c67ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc0200532:	60e2                	ld	ra,24(sp)
ffffffffc0200534:	6442                	ld	s0,16(sp)
ffffffffc0200536:	6161                	addi	sp,sp,80
ffffffffc0200538:	8082                	ret

ffffffffc020053a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020053a:	67e1                	lui	a5,0x18
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd578>
ffffffffc0200540:	000aa717          	auipc	a4,0xaa
ffffffffc0200544:	1cf73c23          	sd	a5,472(a4) # ffffffffc02aa718 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200548:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020054c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054e:	953e                	add	a0,a0,a5
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4881                	li	a7,0
ffffffffc0200554:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200558:	02000793          	li	a5,32
ffffffffc020055c:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200560:	00005517          	auipc	a0,0x5
ffffffffc0200564:	62050513          	addi	a0,a0,1568 # ffffffffc0205b80 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000aa797          	auipc	a5,0xaa
ffffffffc020056c:	1a07b423          	sd	zero,424(a5) # ffffffffc02aa710 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000aa797          	auipc	a5,0xaa
ffffffffc020057a:	1a27b783          	ld	a5,418(a5) # ffffffffc02aa718 <timebase>
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4881                	li	a7,0
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	8082                	ret

ffffffffc020058c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020058c:	8082                	ret

ffffffffc020058e <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020058e:	100027f3          	csrr	a5,sstatus
ffffffffc0200592:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200594:	0ff57513          	zext.b	a0,a0
ffffffffc0200598:	e799                	bnez	a5,ffffffffc02005a6 <cons_putc+0x18>
ffffffffc020059a:	4581                	li	a1,0
ffffffffc020059c:	4601                	li	a2,0
ffffffffc020059e:	4885                	li	a7,1
ffffffffc02005a0:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc02005a4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a6:	1101                	addi	sp,sp,-32
ffffffffc02005a8:	ec06                	sd	ra,24(sp)
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ac:	408000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005b0:	6522                	ld	a0,8(sp)
ffffffffc02005b2:	4581                	li	a1,0
ffffffffc02005b4:	4601                	li	a2,0
ffffffffc02005b6:	4885                	li	a7,1
ffffffffc02005b8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005bc:	60e2                	ld	ra,24(sp)
ffffffffc02005be:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005c0:	a6fd                	j	ffffffffc02009ae <intr_enable>

ffffffffc02005c2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005c2:	100027f3          	csrr	a5,sstatus
ffffffffc02005c6:	8b89                	andi	a5,a5,2
ffffffffc02005c8:	eb89                	bnez	a5,ffffffffc02005da <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005ca:	4501                	li	a0,0
ffffffffc02005cc:	4581                	li	a1,0
ffffffffc02005ce:	4601                	li	a2,0
ffffffffc02005d0:	4889                	li	a7,2
ffffffffc02005d2:	00000073          	ecall
ffffffffc02005d6:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d8:	8082                	ret
int cons_getc(void) {
ffffffffc02005da:	1101                	addi	sp,sp,-32
ffffffffc02005dc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005de:	3d6000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005e2:	4501                	li	a0,0
ffffffffc02005e4:	4581                	li	a1,0
ffffffffc02005e6:	4601                	li	a2,0
ffffffffc02005e8:	4889                	li	a7,2
ffffffffc02005ea:	00000073          	ecall
ffffffffc02005ee:	2501                	sext.w	a0,a0
ffffffffc02005f0:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f2:	3bc000ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc02005f6:	60e2                	ld	ra,24(sp)
ffffffffc02005f8:	6522                	ld	a0,8(sp)
ffffffffc02005fa:	6105                	addi	sp,sp,32
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005fe:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200600:	00005517          	auipc	a0,0x5
ffffffffc0200604:	5a050513          	addi	a0,a0,1440 # ffffffffc0205ba0 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200608:	fc86                	sd	ra,120(sp)
ffffffffc020060a:	f8a2                	sd	s0,112(sp)
ffffffffc020060c:	e8d2                	sd	s4,80(sp)
ffffffffc020060e:	f4a6                	sd	s1,104(sp)
ffffffffc0200610:	f0ca                	sd	s2,96(sp)
ffffffffc0200612:	ecce                	sd	s3,88(sp)
ffffffffc0200614:	e4d6                	sd	s5,72(sp)
ffffffffc0200616:	e0da                	sd	s6,64(sp)
ffffffffc0200618:	fc5e                	sd	s7,56(sp)
ffffffffc020061a:	f862                	sd	s8,48(sp)
ffffffffc020061c:	f466                	sd	s9,40(sp)
ffffffffc020061e:	f06a                	sd	s10,32(sp)
ffffffffc0200620:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200622:	b73ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200626:	0000b597          	auipc	a1,0xb
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	58250513          	addi	a0,a0,1410 # ffffffffc0205bb0 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	57c50513          	addi	a0,a0,1404 # ffffffffc0205bc0 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	58450513          	addi	a0,a0,1412 # ffffffffc0205bd8 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc020065c:	120a0463          	beqz	s4,ffffffffc0200784 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200660:	57f5                	li	a5,-3
ffffffffc0200662:	07fa                	slli	a5,a5,0x1e
ffffffffc0200664:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200668:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200674:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	8ec9                	or	a3,a3,a0
ffffffffc0200688:	0087979b          	slliw	a5,a5,0x8
ffffffffc020068c:	1b7d                	addi	s6,s6,-1
ffffffffc020068e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200692:	8dd5                	or	a1,a1,a3
ffffffffc0200694:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe35759>
ffffffffc02006a0:	10f59163          	bne	a1,a5,ffffffffc02007a2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02006a4:	471c                	lw	a5,8(a4)
ffffffffc02006a6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006ae:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006b2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d2:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	01146433          	or	s0,s0,a7
ffffffffc02006d8:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006dc:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e6:	8c49                	or	s0,s0,a0
ffffffffc02006e8:	0166f6b3          	and	a3,a3,s6
ffffffffc02006ec:	00ca6a33          	or	s4,s4,a2
ffffffffc02006f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02006f4:	8c55                	or	s0,s0,a3
ffffffffc02006f6:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fa:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fc:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200704:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200706:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200708:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020070c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020070e:	00005917          	auipc	s2,0x5
ffffffffc0200712:	51a90913          	addi	s2,s2,1306 # ffffffffc0205c28 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	50448493          	addi	s1,s1,1284 # ffffffffc0205c20 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200724:	000a2703          	lw	a4,0(s4)
ffffffffc0200728:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200730:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200740:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0087171b          	slliw	a4,a4,0x8
ffffffffc020074a:	8fd5                	or	a5,a5,a3
ffffffffc020074c:	00eb7733          	and	a4,s6,a4
ffffffffc0200750:	8fd9                	or	a5,a5,a4
ffffffffc0200752:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200754:	09778c63          	beq	a5,s7,ffffffffc02007ec <dtb_init+0x1ee>
ffffffffc0200758:	00fbea63          	bltu	s7,a5,ffffffffc020076c <dtb_init+0x16e>
ffffffffc020075c:	07a78663          	beq	a5,s10,ffffffffc02007c8 <dtb_init+0x1ca>
ffffffffc0200760:	4709                	li	a4,2
ffffffffc0200762:	00e79763          	bne	a5,a4,ffffffffc0200770 <dtb_init+0x172>
ffffffffc0200766:	4c81                	li	s9,0
ffffffffc0200768:	8a56                	mv	s4,s5
ffffffffc020076a:	bf6d                	j	ffffffffc0200724 <dtb_init+0x126>
ffffffffc020076c:	ffb78ee3          	beq	a5,s11,ffffffffc0200768 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200770:	00005517          	auipc	a0,0x5
ffffffffc0200774:	53050513          	addi	a0,a0,1328 # ffffffffc0205ca0 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	55c50513          	addi	a0,a0,1372 # ffffffffc0205cd8 <commands+0x1e0>
}
ffffffffc0200784:	7446                	ld	s0,112(sp)
ffffffffc0200786:	70e6                	ld	ra,120(sp)
ffffffffc0200788:	74a6                	ld	s1,104(sp)
ffffffffc020078a:	7906                	ld	s2,96(sp)
ffffffffc020078c:	69e6                	ld	s3,88(sp)
ffffffffc020078e:	6a46                	ld	s4,80(sp)
ffffffffc0200790:	6aa6                	ld	s5,72(sp)
ffffffffc0200792:	6b06                	ld	s6,64(sp)
ffffffffc0200794:	7be2                	ld	s7,56(sp)
ffffffffc0200796:	7c42                	ld	s8,48(sp)
ffffffffc0200798:	7ca2                	ld	s9,40(sp)
ffffffffc020079a:	7d02                	ld	s10,32(sp)
ffffffffc020079c:	6de2                	ld	s11,24(sp)
ffffffffc020079e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02007a0:	bad5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc02007a2:	7446                	ld	s0,112(sp)
ffffffffc02007a4:	70e6                	ld	ra,120(sp)
ffffffffc02007a6:	74a6                	ld	s1,104(sp)
ffffffffc02007a8:	7906                	ld	s2,96(sp)
ffffffffc02007aa:	69e6                	ld	s3,88(sp)
ffffffffc02007ac:	6a46                	ld	s4,80(sp)
ffffffffc02007ae:	6aa6                	ld	s5,72(sp)
ffffffffc02007b0:	6b06                	ld	s6,64(sp)
ffffffffc02007b2:	7be2                	ld	s7,56(sp)
ffffffffc02007b4:	7c42                	ld	s8,48(sp)
ffffffffc02007b6:	7ca2                	ld	s9,40(sp)
ffffffffc02007b8:	7d02                	ld	s10,32(sp)
ffffffffc02007ba:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	43c50513          	addi	a0,a0,1084 # ffffffffc0205bf8 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	7f7040ef          	jal	ra,ffffffffc02057c0 <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	04e050ef          	jal	ra,ffffffffc0205826 <strncmp>
ffffffffc02007dc:	e111                	bnez	a0,ffffffffc02007e0 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007de:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007e0:	0a91                	addi	s5,s5,4
ffffffffc02007e2:	9ad2                	add	s5,s5,s4
ffffffffc02007e4:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e8:	8a56                	mv	s4,s5
ffffffffc02007ea:	bf2d                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ec:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f0:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f8:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200808:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200814:	00eaeab3          	or	s5,s5,a4
ffffffffc0200818:	00fb77b3          	and	a5,s6,a5
ffffffffc020081c:	00faeab3          	or	s5,s5,a5
ffffffffc0200820:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200822:	000c9c63          	bnez	s9,ffffffffc020083a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200826:	1a82                	slli	s5,s5,0x20
ffffffffc0200828:	00368793          	addi	a5,a3,3
ffffffffc020082c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200830:	9abe                	add	s5,s5,a5
ffffffffc0200832:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200836:	8a56                	mv	s4,s5
ffffffffc0200838:	b5f5                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020083a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020083e:	85ca                	mv	a1,s2
ffffffffc0200840:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020084e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200852:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200856:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200858:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200860:	8d59                	or	a0,a0,a4
ffffffffc0200862:	00fb77b3          	and	a5,s6,a5
ffffffffc0200866:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200868:	1502                	slli	a0,a0,0x20
ffffffffc020086a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020086c:	9522                	add	a0,a0,s0
ffffffffc020086e:	79b040ef          	jal	ra,ffffffffc0205808 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	3ae50513          	addi	a0,a0,942 # ffffffffc0205c30 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020088e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200892:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200896:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020089a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020089e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008a2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	0187d693          	srli	a3,a5,0x18
ffffffffc02008aa:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008ae:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008b2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008ba:	010f6f33          	or	t5,t5,a6
ffffffffc02008be:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008c2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ca:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ce:	0186f6b3          	and	a3,a3,s8
ffffffffc02008d2:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d6:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008da:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008de:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008e2:	8361                	srli	a4,a4,0x18
ffffffffc02008e4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e8:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008ec:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008f0:	00cb7633          	and	a2,s6,a2
ffffffffc02008f4:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f8:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008fc:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200900:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200904:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200908:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200910:	011b78b3          	and	a7,s6,a7
ffffffffc0200914:	005eeeb3          	or	t4,t4,t0
ffffffffc0200918:	00c6e733          	or	a4,a3,a2
ffffffffc020091c:	006c6c33          	or	s8,s8,t1
ffffffffc0200920:	010b76b3          	and	a3,s6,a6
ffffffffc0200924:	00bb7b33          	and	s6,s6,a1
ffffffffc0200928:	01d7e7b3          	or	a5,a5,t4
ffffffffc020092c:	016c6b33          	or	s6,s8,s6
ffffffffc0200930:	01146433          	or	s0,s0,a7
ffffffffc0200934:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	1702                	slli	a4,a4,0x20
ffffffffc0200938:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200940:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200944:	0167eb33          	or	s6,a5,s6
ffffffffc0200948:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020094a:	84bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020094e:	85a2                	mv	a1,s0
ffffffffc0200950:	00005517          	auipc	a0,0x5
ffffffffc0200954:	30050513          	addi	a0,a0,768 # ffffffffc0205c50 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	30650513          	addi	a0,a0,774 # ffffffffc0205c68 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	31450513          	addi	a0,a0,788 # ffffffffc0205c88 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	35850513          	addi	a0,a0,856 # ffffffffc0205cd8 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000aa797          	auipc	a5,0xaa
ffffffffc020098c:	d887bc23          	sd	s0,-616(a5) # ffffffffc02aa720 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000aa797          	auipc	a5,0xaa
ffffffffc0200994:	d967bc23          	sd	s6,-616(a5) # ffffffffc02aa728 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000aa517          	auipc	a0,0xaa
ffffffffc020099e:	d8653503          	ld	a0,-634(a0) # ffffffffc02aa720 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000aa517          	auipc	a0,0xaa
ffffffffc02009a8:	d8453503          	ld	a0,-636(a0) # ffffffffc02aa728 <memory_size>
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009b4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b8:	8082                	ret

ffffffffc02009ba <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009ba:	8082                	ret

ffffffffc02009bc <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009bc:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009c0:	00000797          	auipc	a5,0x0
ffffffffc02009c4:	54878793          	addi	a5,a5,1352 # ffffffffc0200f08 <__alltraps>
ffffffffc02009c8:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009cc:	000407b7          	lui	a5,0x40
ffffffffc02009d0:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009d4:	8082                	ret

ffffffffc02009d6 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d6:	610c                	ld	a1,0(a0)
{
ffffffffc02009d8:	1141                	addi	sp,sp,-16
ffffffffc02009da:	e022                	sd	s0,0(sp)
ffffffffc02009dc:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	31250513          	addi	a0,a0,786 # ffffffffc0205cf0 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	31a50513          	addi	a0,a0,794 # ffffffffc0205d08 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	32450513          	addi	a0,a0,804 # ffffffffc0205d20 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	32e50513          	addi	a0,a0,814 # ffffffffc0205d38 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	33850513          	addi	a0,a0,824 # ffffffffc0205d50 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	34250513          	addi	a0,a0,834 # ffffffffc0205d68 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	34c50513          	addi	a0,a0,844 # ffffffffc0205d80 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	35650513          	addi	a0,a0,854 # ffffffffc0205d98 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	36050513          	addi	a0,a0,864 # ffffffffc0205db0 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	36a50513          	addi	a0,a0,874 # ffffffffc0205dc8 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	37450513          	addi	a0,a0,884 # ffffffffc0205de0 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	37e50513          	addi	a0,a0,894 # ffffffffc0205df8 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	38850513          	addi	a0,a0,904 # ffffffffc0205e10 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	39250513          	addi	a0,a0,914 # ffffffffc0205e28 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	39c50513          	addi	a0,a0,924 # ffffffffc0205e40 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	3a650513          	addi	a0,a0,934 # ffffffffc0205e58 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	3b050513          	addi	a0,a0,944 # ffffffffc0205e70 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	3ba50513          	addi	a0,a0,954 # ffffffffc0205e88 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	3c450513          	addi	a0,a0,964 # ffffffffc0205ea0 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	3ce50513          	addi	a0,a0,974 # ffffffffc0205eb8 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	3d850513          	addi	a0,a0,984 # ffffffffc0205ed0 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	3e250513          	addi	a0,a0,994 # ffffffffc0205ee8 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	3ec50513          	addi	a0,a0,1004 # ffffffffc0205f00 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	3f650513          	addi	a0,a0,1014 # ffffffffc0205f18 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	40050513          	addi	a0,a0,1024 # ffffffffc0205f30 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	40a50513          	addi	a0,a0,1034 # ffffffffc0205f48 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	41450513          	addi	a0,a0,1044 # ffffffffc0205f60 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	41e50513          	addi	a0,a0,1054 # ffffffffc0205f78 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	42850513          	addi	a0,a0,1064 # ffffffffc0205f90 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	43250513          	addi	a0,a0,1074 # ffffffffc0205fa8 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	43c50513          	addi	a0,a0,1084 # ffffffffc0205fc0 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	44250513          	addi	a0,a0,1090 # ffffffffc0205fd8 <commands+0x4e0>
}
ffffffffc0200b9e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ba0:	df4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ba4 <print_trapframe>:
{
ffffffffc0200ba4:	1141                	addi	sp,sp,-16
ffffffffc0200ba6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba8:	85aa                	mv	a1,a0
{
ffffffffc0200baa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bac:	00005517          	auipc	a0,0x5
ffffffffc0200bb0:	44450513          	addi	a0,a0,1092 # ffffffffc0205ff0 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00005517          	auipc	a0,0x5
ffffffffc0200bc8:	44450513          	addi	a0,a0,1092 # ffffffffc0206008 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	44c50513          	addi	a0,a0,1100 # ffffffffc0206020 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	45450513          	addi	a0,a0,1108 # ffffffffc0206038 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	45050513          	addi	a0,a0,1104 # ffffffffc0206048 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c06:	11853783          	ld	a5,280(a0)
ffffffffc0200c0a:	472d                	li	a4,11
ffffffffc0200c0c:	0786                	slli	a5,a5,0x1
ffffffffc0200c0e:	8385                	srli	a5,a5,0x1
ffffffffc0200c10:	08f76d63          	bltu	a4,a5,ffffffffc0200caa <interrupt_handler+0xa4>
ffffffffc0200c14:	00005717          	auipc	a4,0x5
ffffffffc0200c18:	51c70713          	addi	a4,a4,1308 # ffffffffc0206130 <commands+0x638>
ffffffffc0200c1c:	078a                	slli	a5,a5,0x2
ffffffffc0200c1e:	97ba                	add	a5,a5,a4
ffffffffc0200c20:	439c                	lw	a5,0(a5)
ffffffffc0200c22:	97ba                	add	a5,a5,a4
ffffffffc0200c24:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c26:	00005517          	auipc	a0,0x5
ffffffffc0200c2a:	49a50513          	addi	a0,a0,1178 # ffffffffc02060c0 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00005517          	auipc	a0,0x5
ffffffffc0200c36:	46e50513          	addi	a0,a0,1134 # ffffffffc02060a0 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	42250513          	addi	a0,a0,1058 # ffffffffc0206060 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00005517          	auipc	a0,0x5
ffffffffc0200c4e:	43650513          	addi	a0,a0,1078 # ffffffffc0206080 <commands+0x588>
ffffffffc0200c52:	d42ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200c56:	1141                	addi	sp,sp,-16
ffffffffc0200c58:	e022                	sd	s0,0(sp)
ffffffffc0200c5a:	e406                	sd	ra,8(sp)
        /*(1)设置下次时钟中断- clock_set_next_event()
         *(2)计数器（ticks）加一
         *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
         * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
         */
        clock_set_next_event(); // 发生这次时钟中断的时候，我们要设置下一次时钟中断
ffffffffc0200c5c:	917ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
        if (++ticks % TICK_NUM == 0)
ffffffffc0200c60:	000aa697          	auipc	a3,0xaa
ffffffffc0200c64:	ab068693          	addi	a3,a3,-1360 # ffffffffc02aa710 <ticks>
ffffffffc0200c68:	629c                	ld	a5,0(a3)
ffffffffc0200c6a:	06400713          	li	a4,100
ffffffffc0200c6e:	000aa417          	auipc	s0,0xaa
ffffffffc0200c72:	ac240413          	addi	s0,s0,-1342 # ffffffffc02aa730 <print_num>
ffffffffc0200c76:	0785                	addi	a5,a5,1
ffffffffc0200c78:	02e7f733          	remu	a4,a5,a4
ffffffffc0200c7c:	e29c                	sd	a5,0(a3)
ffffffffc0200c7e:	c71d                	beqz	a4,ffffffffc0200cac <interrupt_handler+0xa6>
        {
            print_num++;
            print_ticks();
        }
        // 周期性请求调度，实现基于时钟的抢占
        if (current != NULL)
ffffffffc0200c80:	000aa797          	auipc	a5,0xaa
ffffffffc0200c84:	af87b783          	ld	a5,-1288(a5) # ffffffffc02aa778 <current>
ffffffffc0200c88:	c399                	beqz	a5,ffffffffc0200c8e <interrupt_handler+0x88>
        {
            current->need_resched = 1;
ffffffffc0200c8a:	4705                	li	a4,1
ffffffffc0200c8c:	ef98                	sd	a4,24(a5)
        }
        if (print_num == 10)
ffffffffc0200c8e:	4018                	lw	a4,0(s0)
ffffffffc0200c90:	47a9                	li	a5,10
ffffffffc0200c92:	02f70963          	beq	a4,a5,ffffffffc0200cc4 <interrupt_handler+0xbe>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c96:	60a2                	ld	ra,8(sp)
ffffffffc0200c98:	6402                	ld	s0,0(sp)
ffffffffc0200c9a:	0141                	addi	sp,sp,16
ffffffffc0200c9c:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c9e:	00005517          	auipc	a0,0x5
ffffffffc0200ca2:	47250513          	addi	a0,a0,1138 # ffffffffc0206110 <commands+0x618>
ffffffffc0200ca6:	ceeff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200caa:	bded                	j	ffffffffc0200ba4 <print_trapframe>
            print_num++;
ffffffffc0200cac:	401c                	lw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200cae:	06400593          	li	a1,100
ffffffffc0200cb2:	00005517          	auipc	a0,0x5
ffffffffc0200cb6:	42e50513          	addi	a0,a0,1070 # ffffffffc02060e0 <commands+0x5e8>
            print_num++;
ffffffffc0200cba:	2785                	addiw	a5,a5,1
ffffffffc0200cbc:	c01c                	sw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200cbe:	cd6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0200cc2:	bf7d                	j	ffffffffc0200c80 <interrupt_handler+0x7a>
            cprintf("Calling SBI shutdown...\n");
ffffffffc0200cc4:	00005517          	auipc	a0,0x5
ffffffffc0200cc8:	42c50513          	addi	a0,a0,1068 # ffffffffc02060f0 <commands+0x5f8>
ffffffffc0200ccc:	cc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200cd0:	4501                	li	a0,0
ffffffffc0200cd2:	4581                	li	a1,0
ffffffffc0200cd4:	4601                	li	a2,0
ffffffffc0200cd6:	48a1                	li	a7,8
ffffffffc0200cd8:	00000073          	ecall
}
ffffffffc0200cdc:	bf6d                	j	ffffffffc0200c96 <interrupt_handler+0x90>

ffffffffc0200cde <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200cde:	11853783          	ld	a5,280(a0)
{
ffffffffc0200ce2:	1141                	addi	sp,sp,-16
ffffffffc0200ce4:	e022                	sd	s0,0(sp)
ffffffffc0200ce6:	e406                	sd	ra,8(sp)
ffffffffc0200ce8:	473d                	li	a4,15
ffffffffc0200cea:	842a                	mv	s0,a0
ffffffffc0200cec:	14f76863          	bltu	a4,a5,ffffffffc0200e3c <exception_handler+0x15e>
ffffffffc0200cf0:	00005717          	auipc	a4,0x5
ffffffffc0200cf4:	61c70713          	addi	a4,a4,1564 # ffffffffc020630c <commands+0x814>
ffffffffc0200cf8:	078a                	slli	a5,a5,0x2
ffffffffc0200cfa:	97ba                	add	a5,a5,a4
ffffffffc0200cfc:	439c                	lw	a5,0(a5)
ffffffffc0200cfe:	97ba                	add	a5,a5,a4
ffffffffc0200d00:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200d02:	00005517          	auipc	a0,0x5
ffffffffc0200d06:	54650513          	addi	a0,a0,1350 # ffffffffc0206248 <commands+0x750>
ffffffffc0200d0a:	c8aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200d0e:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200d12:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200d14:	0791                	addi	a5,a5,4
ffffffffc0200d16:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200d1a:	6402                	ld	s0,0(sp)
ffffffffc0200d1c:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200d1e:	61e0406f          	j	ffffffffc020533c <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200d22:	00005517          	auipc	a0,0x5
ffffffffc0200d26:	54650513          	addi	a0,a0,1350 # ffffffffc0206268 <commands+0x770>
}
ffffffffc0200d2a:	6402                	ld	s0,0(sp)
ffffffffc0200d2c:	60a2                	ld	ra,8(sp)
ffffffffc0200d2e:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200d30:	c64ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d34:	00005517          	auipc	a0,0x5
ffffffffc0200d38:	55450513          	addi	a0,a0,1364 # ffffffffc0206288 <commands+0x790>
ffffffffc0200d3c:	b7fd                	j	ffffffffc0200d2a <exception_handler+0x4c>
        if (do_pgfault(current->mm, 0, tf->tval) != 0)
ffffffffc0200d3e:	000aa797          	auipc	a5,0xaa
ffffffffc0200d42:	a3a7b783          	ld	a5,-1478(a5) # ffffffffc02aa778 <current>
ffffffffc0200d46:	11053603          	ld	a2,272(a0)
ffffffffc0200d4a:	7788                	ld	a0,40(a5)
ffffffffc0200d4c:	4581                	li	a1,0
ffffffffc0200d4e:	7bf020ef          	jal	ra,ffffffffc0203d0c <do_pgfault>
ffffffffc0200d52:	10051663          	bnez	a0,ffffffffc0200e5e <exception_handler+0x180>
}
ffffffffc0200d56:	60a2                	ld	ra,8(sp)
ffffffffc0200d58:	6402                	ld	s0,0(sp)
ffffffffc0200d5a:	0141                	addi	sp,sp,16
ffffffffc0200d5c:	8082                	ret
        if (do_pgfault(current->mm, 0, tf->tval) != 0)
ffffffffc0200d5e:	000aa797          	auipc	a5,0xaa
ffffffffc0200d62:	a1a7b783          	ld	a5,-1510(a5) # ffffffffc02aa778 <current>
ffffffffc0200d66:	11053603          	ld	a2,272(a0)
ffffffffc0200d6a:	7788                	ld	a0,40(a5)
ffffffffc0200d6c:	4581                	li	a1,0
ffffffffc0200d6e:	79f020ef          	jal	ra,ffffffffc0203d0c <do_pgfault>
ffffffffc0200d72:	d175                	beqz	a0,ffffffffc0200d56 <exception_handler+0x78>
            print_trapframe(tf);
ffffffffc0200d74:	8522                	mv	a0,s0
ffffffffc0200d76:	e2fff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            panic("unhandled load page fault\n");
ffffffffc0200d7a:	00005617          	auipc	a2,0x5
ffffffffc0200d7e:	55660613          	addi	a2,a2,1366 # ffffffffc02062d0 <commands+0x7d8>
ffffffffc0200d82:	0ed00593          	li	a1,237
ffffffffc0200d86:	00005517          	auipc	a0,0x5
ffffffffc0200d8a:	49250513          	addi	a0,a0,1170 # ffffffffc0206218 <commands+0x720>
ffffffffc0200d8e:	f00ff0ef          	jal	ra,ffffffffc020048e <__panic>
        if (do_pgfault(current->mm, 0x2, tf->tval) != 0)
ffffffffc0200d92:	000aa797          	auipc	a5,0xaa
ffffffffc0200d96:	9e67b783          	ld	a5,-1562(a5) # ffffffffc02aa778 <current>
ffffffffc0200d9a:	11053603          	ld	a2,272(a0)
ffffffffc0200d9e:	7788                	ld	a0,40(a5)
ffffffffc0200da0:	4589                	li	a1,2
ffffffffc0200da2:	76b020ef          	jal	ra,ffffffffc0203d0c <do_pgfault>
ffffffffc0200da6:	d945                	beqz	a0,ffffffffc0200d56 <exception_handler+0x78>
            print_trapframe(tf);
ffffffffc0200da8:	8522                	mv	a0,s0
ffffffffc0200daa:	dfbff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            panic("unhandled store page fault\n");
ffffffffc0200dae:	00005617          	auipc	a2,0x5
ffffffffc0200db2:	54260613          	addi	a2,a2,1346 # ffffffffc02062f0 <commands+0x7f8>
ffffffffc0200db6:	0f500593          	li	a1,245
ffffffffc0200dba:	00005517          	auipc	a0,0x5
ffffffffc0200dbe:	45e50513          	addi	a0,a0,1118 # ffffffffc0206218 <commands+0x720>
ffffffffc0200dc2:	eccff0ef          	jal	ra,ffffffffc020048e <__panic>
        cprintf("Instruction address misaligned\n");
ffffffffc0200dc6:	00005517          	auipc	a0,0x5
ffffffffc0200dca:	39a50513          	addi	a0,a0,922 # ffffffffc0206160 <commands+0x668>
ffffffffc0200dce:	bfb1                	j	ffffffffc0200d2a <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200dd0:	00005517          	auipc	a0,0x5
ffffffffc0200dd4:	3b050513          	addi	a0,a0,944 # ffffffffc0206180 <commands+0x688>
ffffffffc0200dd8:	bf89                	j	ffffffffc0200d2a <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200dda:	00005517          	auipc	a0,0x5
ffffffffc0200dde:	3c650513          	addi	a0,a0,966 # ffffffffc02061a0 <commands+0x6a8>
ffffffffc0200de2:	b7a1                	j	ffffffffc0200d2a <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200de4:	00005517          	auipc	a0,0x5
ffffffffc0200de8:	3d450513          	addi	a0,a0,980 # ffffffffc02061b8 <commands+0x6c0>
ffffffffc0200dec:	ba8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200df0:	6458                	ld	a4,136(s0)
ffffffffc0200df2:	47a9                	li	a5,10
ffffffffc0200df4:	f6f711e3          	bne	a4,a5,ffffffffc0200d56 <exception_handler+0x78>
            tf->epc += 4;
ffffffffc0200df8:	10843783          	ld	a5,264(s0)
ffffffffc0200dfc:	0791                	addi	a5,a5,4
ffffffffc0200dfe:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200e02:	53a040ef          	jal	ra,ffffffffc020533c <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200e06:	000aa797          	auipc	a5,0xaa
ffffffffc0200e0a:	9727b783          	ld	a5,-1678(a5) # ffffffffc02aa778 <current>
ffffffffc0200e0e:	6b9c                	ld	a5,16(a5)
ffffffffc0200e10:	8522                	mv	a0,s0
}
ffffffffc0200e12:	6402                	ld	s0,0(sp)
ffffffffc0200e14:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200e16:	6589                	lui	a1,0x2
ffffffffc0200e18:	95be                	add	a1,a1,a5
}
ffffffffc0200e1a:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200e1c:	aa6d                	j	ffffffffc0200fd6 <kernel_execve_ret>
        cprintf("Load address misaligned\n");
ffffffffc0200e1e:	00005517          	auipc	a0,0x5
ffffffffc0200e22:	3aa50513          	addi	a0,a0,938 # ffffffffc02061c8 <commands+0x6d0>
ffffffffc0200e26:	b711                	j	ffffffffc0200d2a <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200e28:	00005517          	auipc	a0,0x5
ffffffffc0200e2c:	3c050513          	addi	a0,a0,960 # ffffffffc02061e8 <commands+0x6f0>
ffffffffc0200e30:	bded                	j	ffffffffc0200d2a <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200e32:	00005517          	auipc	a0,0x5
ffffffffc0200e36:	3fe50513          	addi	a0,a0,1022 # ffffffffc0206230 <commands+0x738>
ffffffffc0200e3a:	bdc5                	j	ffffffffc0200d2a <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200e3c:	8522                	mv	a0,s0
}
ffffffffc0200e3e:	6402                	ld	s0,0(sp)
ffffffffc0200e40:	60a2                	ld	ra,8(sp)
ffffffffc0200e42:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200e44:	b385                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200e46:	00005617          	auipc	a2,0x5
ffffffffc0200e4a:	3ba60613          	addi	a2,a2,954 # ffffffffc0206200 <commands+0x708>
ffffffffc0200e4e:	0cb00593          	li	a1,203
ffffffffc0200e52:	00005517          	auipc	a0,0x5
ffffffffc0200e56:	3c650513          	addi	a0,a0,966 # ffffffffc0206218 <commands+0x720>
ffffffffc0200e5a:	e34ff0ef          	jal	ra,ffffffffc020048e <__panic>
            print_trapframe(tf);
ffffffffc0200e5e:	8522                	mv	a0,s0
ffffffffc0200e60:	d45ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            panic("unhandled instruction page fault\n");
ffffffffc0200e64:	00005617          	auipc	a2,0x5
ffffffffc0200e68:	44460613          	addi	a2,a2,1092 # ffffffffc02062a8 <commands+0x7b0>
ffffffffc0200e6c:	0e500593          	li	a1,229
ffffffffc0200e70:	00005517          	auipc	a0,0x5
ffffffffc0200e74:	3a850513          	addi	a0,a0,936 # ffffffffc0206218 <commands+0x720>
ffffffffc0200e78:	e16ff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200e7c <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200e7c:	1101                	addi	sp,sp,-32
ffffffffc0200e7e:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200e80:	000aa417          	auipc	s0,0xaa
ffffffffc0200e84:	8f840413          	addi	s0,s0,-1800 # ffffffffc02aa778 <current>
ffffffffc0200e88:	6018                	ld	a4,0(s0)
{
ffffffffc0200e8a:	ec06                	sd	ra,24(sp)
ffffffffc0200e8c:	e426                	sd	s1,8(sp)
ffffffffc0200e8e:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e90:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200e94:	cf1d                	beqz	a4,ffffffffc0200ed2 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e96:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200e9a:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200e9e:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200ea0:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200ea4:	0206c463          	bltz	a3,ffffffffc0200ecc <trap+0x50>
        exception_handler(tf);
ffffffffc0200ea8:	e37ff0ef          	jal	ra,ffffffffc0200cde <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200eac:	601c                	ld	a5,0(s0)
ffffffffc0200eae:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200eb2:	e499                	bnez	s1,ffffffffc0200ec0 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200eb4:	0b07a703          	lw	a4,176(a5)
ffffffffc0200eb8:	8b05                	andi	a4,a4,1
ffffffffc0200eba:	e329                	bnez	a4,ffffffffc0200efc <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200ebc:	6f9c                	ld	a5,24(a5)
ffffffffc0200ebe:	eb85                	bnez	a5,ffffffffc0200eee <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200ec0:	60e2                	ld	ra,24(sp)
ffffffffc0200ec2:	6442                	ld	s0,16(sp)
ffffffffc0200ec4:	64a2                	ld	s1,8(sp)
ffffffffc0200ec6:	6902                	ld	s2,0(sp)
ffffffffc0200ec8:	6105                	addi	sp,sp,32
ffffffffc0200eca:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200ecc:	d3bff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200ed0:	bff1                	j	ffffffffc0200eac <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200ed2:	0006c863          	bltz	a3,ffffffffc0200ee2 <trap+0x66>
}
ffffffffc0200ed6:	6442                	ld	s0,16(sp)
ffffffffc0200ed8:	60e2                	ld	ra,24(sp)
ffffffffc0200eda:	64a2                	ld	s1,8(sp)
ffffffffc0200edc:	6902                	ld	s2,0(sp)
ffffffffc0200ede:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200ee0:	bbfd                	j	ffffffffc0200cde <exception_handler>
}
ffffffffc0200ee2:	6442                	ld	s0,16(sp)
ffffffffc0200ee4:	60e2                	ld	ra,24(sp)
ffffffffc0200ee6:	64a2                	ld	s1,8(sp)
ffffffffc0200ee8:	6902                	ld	s2,0(sp)
ffffffffc0200eea:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200eec:	bb29                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200eee:	6442                	ld	s0,16(sp)
ffffffffc0200ef0:	60e2                	ld	ra,24(sp)
ffffffffc0200ef2:	64a2                	ld	s1,8(sp)
ffffffffc0200ef4:	6902                	ld	s2,0(sp)
ffffffffc0200ef6:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200ef8:	3580406f          	j	ffffffffc0205250 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200efc:	555d                	li	a0,-9
ffffffffc0200efe:	69a030ef          	jal	ra,ffffffffc0204598 <do_exit>
            if (current->need_resched)
ffffffffc0200f02:	601c                	ld	a5,0(s0)
ffffffffc0200f04:	bf65                	j	ffffffffc0200ebc <trap+0x40>
	...

ffffffffc0200f08 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200f08:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200f0c:	00011463          	bnez	sp,ffffffffc0200f14 <__alltraps+0xc>
ffffffffc0200f10:	14002173          	csrr	sp,sscratch
ffffffffc0200f14:	712d                	addi	sp,sp,-288
ffffffffc0200f16:	e002                	sd	zero,0(sp)
ffffffffc0200f18:	e406                	sd	ra,8(sp)
ffffffffc0200f1a:	ec0e                	sd	gp,24(sp)
ffffffffc0200f1c:	f012                	sd	tp,32(sp)
ffffffffc0200f1e:	f416                	sd	t0,40(sp)
ffffffffc0200f20:	f81a                	sd	t1,48(sp)
ffffffffc0200f22:	fc1e                	sd	t2,56(sp)
ffffffffc0200f24:	e0a2                	sd	s0,64(sp)
ffffffffc0200f26:	e4a6                	sd	s1,72(sp)
ffffffffc0200f28:	e8aa                	sd	a0,80(sp)
ffffffffc0200f2a:	ecae                	sd	a1,88(sp)
ffffffffc0200f2c:	f0b2                	sd	a2,96(sp)
ffffffffc0200f2e:	f4b6                	sd	a3,104(sp)
ffffffffc0200f30:	f8ba                	sd	a4,112(sp)
ffffffffc0200f32:	fcbe                	sd	a5,120(sp)
ffffffffc0200f34:	e142                	sd	a6,128(sp)
ffffffffc0200f36:	e546                	sd	a7,136(sp)
ffffffffc0200f38:	e94a                	sd	s2,144(sp)
ffffffffc0200f3a:	ed4e                	sd	s3,152(sp)
ffffffffc0200f3c:	f152                	sd	s4,160(sp)
ffffffffc0200f3e:	f556                	sd	s5,168(sp)
ffffffffc0200f40:	f95a                	sd	s6,176(sp)
ffffffffc0200f42:	fd5e                	sd	s7,184(sp)
ffffffffc0200f44:	e1e2                	sd	s8,192(sp)
ffffffffc0200f46:	e5e6                	sd	s9,200(sp)
ffffffffc0200f48:	e9ea                	sd	s10,208(sp)
ffffffffc0200f4a:	edee                	sd	s11,216(sp)
ffffffffc0200f4c:	f1f2                	sd	t3,224(sp)
ffffffffc0200f4e:	f5f6                	sd	t4,232(sp)
ffffffffc0200f50:	f9fa                	sd	t5,240(sp)
ffffffffc0200f52:	fdfe                	sd	t6,248(sp)
ffffffffc0200f54:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200f58:	100024f3          	csrr	s1,sstatus
ffffffffc0200f5c:	14102973          	csrr	s2,sepc
ffffffffc0200f60:	143029f3          	csrr	s3,stval
ffffffffc0200f64:	14202a73          	csrr	s4,scause
ffffffffc0200f68:	e822                	sd	s0,16(sp)
ffffffffc0200f6a:	e226                	sd	s1,256(sp)
ffffffffc0200f6c:	e64a                	sd	s2,264(sp)
ffffffffc0200f6e:	ea4e                	sd	s3,272(sp)
ffffffffc0200f70:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200f72:	850a                	mv	a0,sp
    jal trap
ffffffffc0200f74:	f09ff0ef          	jal	ra,ffffffffc0200e7c <trap>

ffffffffc0200f78 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200f78:	6492                	ld	s1,256(sp)
ffffffffc0200f7a:	6932                	ld	s2,264(sp)
ffffffffc0200f7c:	1004f413          	andi	s0,s1,256
ffffffffc0200f80:	e401                	bnez	s0,ffffffffc0200f88 <__trapret+0x10>
ffffffffc0200f82:	1200                	addi	s0,sp,288
ffffffffc0200f84:	14041073          	csrw	sscratch,s0
ffffffffc0200f88:	10049073          	csrw	sstatus,s1
ffffffffc0200f8c:	14191073          	csrw	sepc,s2
ffffffffc0200f90:	60a2                	ld	ra,8(sp)
ffffffffc0200f92:	61e2                	ld	gp,24(sp)
ffffffffc0200f94:	7202                	ld	tp,32(sp)
ffffffffc0200f96:	72a2                	ld	t0,40(sp)
ffffffffc0200f98:	7342                	ld	t1,48(sp)
ffffffffc0200f9a:	73e2                	ld	t2,56(sp)
ffffffffc0200f9c:	6406                	ld	s0,64(sp)
ffffffffc0200f9e:	64a6                	ld	s1,72(sp)
ffffffffc0200fa0:	6546                	ld	a0,80(sp)
ffffffffc0200fa2:	65e6                	ld	a1,88(sp)
ffffffffc0200fa4:	7606                	ld	a2,96(sp)
ffffffffc0200fa6:	76a6                	ld	a3,104(sp)
ffffffffc0200fa8:	7746                	ld	a4,112(sp)
ffffffffc0200faa:	77e6                	ld	a5,120(sp)
ffffffffc0200fac:	680a                	ld	a6,128(sp)
ffffffffc0200fae:	68aa                	ld	a7,136(sp)
ffffffffc0200fb0:	694a                	ld	s2,144(sp)
ffffffffc0200fb2:	69ea                	ld	s3,152(sp)
ffffffffc0200fb4:	7a0a                	ld	s4,160(sp)
ffffffffc0200fb6:	7aaa                	ld	s5,168(sp)
ffffffffc0200fb8:	7b4a                	ld	s6,176(sp)
ffffffffc0200fba:	7bea                	ld	s7,184(sp)
ffffffffc0200fbc:	6c0e                	ld	s8,192(sp)
ffffffffc0200fbe:	6cae                	ld	s9,200(sp)
ffffffffc0200fc0:	6d4e                	ld	s10,208(sp)
ffffffffc0200fc2:	6dee                	ld	s11,216(sp)
ffffffffc0200fc4:	7e0e                	ld	t3,224(sp)
ffffffffc0200fc6:	7eae                	ld	t4,232(sp)
ffffffffc0200fc8:	7f4e                	ld	t5,240(sp)
ffffffffc0200fca:	7fee                	ld	t6,248(sp)
ffffffffc0200fcc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200fce:	10200073          	sret

ffffffffc0200fd2 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200fd2:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200fd4:	b755                	j	ffffffffc0200f78 <__trapret>

ffffffffc0200fd6 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200fd6:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd0>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200fda:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200fde:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200fe2:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200fe6:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200fea:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200fee:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200ff2:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200ff6:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200ffa:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200ffc:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200ffe:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0201000:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0201002:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0201004:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0201006:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0201008:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc020100a:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc020100c:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc020100e:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0201010:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0201012:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0201014:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0201016:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0201018:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc020101a:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc020101c:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc020101e:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0201020:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0201022:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0201024:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0201026:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0201028:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc020102a:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc020102c:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc020102e:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0201030:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0201032:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0201034:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0201036:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0201038:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc020103a:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc020103c:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc020103e:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0201040:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0201042:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0201044:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0201046:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0201048:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc020104a:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc020104c:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc020104e:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0201050:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0201052:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0201054:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0201056:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0201058:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc020105a:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc020105c:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc020105e:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0201060:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0201062:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0201064:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0201066:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0201068:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc020106a:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc020106c:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc020106e:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0201070:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0201072:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0201074:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0201076:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0201078:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc020107a:	812e                	mv	sp,a1
ffffffffc020107c:	bdf5                	j	ffffffffc0200f78 <__trapret>

ffffffffc020107e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020107e:	000a5797          	auipc	a5,0xa5
ffffffffc0201082:	66278793          	addi	a5,a5,1634 # ffffffffc02a66e0 <free_area>
ffffffffc0201086:	e79c                	sd	a5,8(a5)
ffffffffc0201088:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc020108a:	0007a823          	sw	zero,16(a5)
}
ffffffffc020108e:	8082                	ret

ffffffffc0201090 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0201090:	000a5517          	auipc	a0,0xa5
ffffffffc0201094:	66056503          	lwu	a0,1632(a0) # ffffffffc02a66f0 <free_area+0x10>
ffffffffc0201098:	8082                	ret

ffffffffc020109a <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc020109a:	715d                	addi	sp,sp,-80
ffffffffc020109c:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020109e:	000a5417          	auipc	s0,0xa5
ffffffffc02010a2:	64240413          	addi	s0,s0,1602 # ffffffffc02a66e0 <free_area>
ffffffffc02010a6:	641c                	ld	a5,8(s0)
ffffffffc02010a8:	e486                	sd	ra,72(sp)
ffffffffc02010aa:	fc26                	sd	s1,56(sp)
ffffffffc02010ac:	f84a                	sd	s2,48(sp)
ffffffffc02010ae:	f44e                	sd	s3,40(sp)
ffffffffc02010b0:	f052                	sd	s4,32(sp)
ffffffffc02010b2:	ec56                	sd	s5,24(sp)
ffffffffc02010b4:	e85a                	sd	s6,16(sp)
ffffffffc02010b6:	e45e                	sd	s7,8(sp)
ffffffffc02010b8:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02010ba:	2a878d63          	beq	a5,s0,ffffffffc0201374 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc02010be:	4481                	li	s1,0
ffffffffc02010c0:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02010c2:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02010c6:	8b09                	andi	a4,a4,2
ffffffffc02010c8:	2a070a63          	beqz	a4,ffffffffc020137c <default_check+0x2e2>
        count++, total += p->property;
ffffffffc02010cc:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010d0:	679c                	ld	a5,8(a5)
ffffffffc02010d2:	2905                	addiw	s2,s2,1
ffffffffc02010d4:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02010d6:	fe8796e3          	bne	a5,s0,ffffffffc02010c2 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02010da:	89a6                	mv	s3,s1
ffffffffc02010dc:	6df000ef          	jal	ra,ffffffffc0201fba <nr_free_pages>
ffffffffc02010e0:	6f351e63          	bne	a0,s3,ffffffffc02017dc <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010e4:	4505                	li	a0,1
ffffffffc02010e6:	657000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc02010ea:	8aaa                	mv	s5,a0
ffffffffc02010ec:	42050863          	beqz	a0,ffffffffc020151c <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010f0:	4505                	li	a0,1
ffffffffc02010f2:	64b000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc02010f6:	89aa                	mv	s3,a0
ffffffffc02010f8:	70050263          	beqz	a0,ffffffffc02017fc <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010fc:	4505                	li	a0,1
ffffffffc02010fe:	63f000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc0201102:	8a2a                	mv	s4,a0
ffffffffc0201104:	48050c63          	beqz	a0,ffffffffc020159c <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201108:	293a8a63          	beq	s5,s3,ffffffffc020139c <default_check+0x302>
ffffffffc020110c:	28aa8863          	beq	s5,a0,ffffffffc020139c <default_check+0x302>
ffffffffc0201110:	28a98663          	beq	s3,a0,ffffffffc020139c <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201114:	000aa783          	lw	a5,0(s5)
ffffffffc0201118:	2a079263          	bnez	a5,ffffffffc02013bc <default_check+0x322>
ffffffffc020111c:	0009a783          	lw	a5,0(s3)
ffffffffc0201120:	28079e63          	bnez	a5,ffffffffc02013bc <default_check+0x322>
ffffffffc0201124:	411c                	lw	a5,0(a0)
ffffffffc0201126:	28079b63          	bnez	a5,ffffffffc02013bc <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc020112a:	000a9797          	auipc	a5,0xa9
ffffffffc020112e:	62e7b783          	ld	a5,1582(a5) # ffffffffc02aa758 <pages>
ffffffffc0201132:	40fa8733          	sub	a4,s5,a5
ffffffffc0201136:	00007617          	auipc	a2,0x7
ffffffffc020113a:	8c263603          	ld	a2,-1854(a2) # ffffffffc02079f8 <nbase>
ffffffffc020113e:	8719                	srai	a4,a4,0x6
ffffffffc0201140:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201142:	000a9697          	auipc	a3,0xa9
ffffffffc0201146:	60e6b683          	ld	a3,1550(a3) # ffffffffc02aa750 <npage>
ffffffffc020114a:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc020114c:	0732                	slli	a4,a4,0xc
ffffffffc020114e:	28d77763          	bgeu	a4,a3,ffffffffc02013dc <default_check+0x342>
    return page - pages + nbase;
ffffffffc0201152:	40f98733          	sub	a4,s3,a5
ffffffffc0201156:	8719                	srai	a4,a4,0x6
ffffffffc0201158:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020115a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020115c:	4cd77063          	bgeu	a4,a3,ffffffffc020161c <default_check+0x582>
    return page - pages + nbase;
ffffffffc0201160:	40f507b3          	sub	a5,a0,a5
ffffffffc0201164:	8799                	srai	a5,a5,0x6
ffffffffc0201166:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201168:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020116a:	30d7f963          	bgeu	a5,a3,ffffffffc020147c <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc020116e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201170:	00043c03          	ld	s8,0(s0)
ffffffffc0201174:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201178:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020117c:	e400                	sd	s0,8(s0)
ffffffffc020117e:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0201180:	000a5797          	auipc	a5,0xa5
ffffffffc0201184:	5607a823          	sw	zero,1392(a5) # ffffffffc02a66f0 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201188:	5b5000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc020118c:	2c051863          	bnez	a0,ffffffffc020145c <default_check+0x3c2>
    free_page(p0);
ffffffffc0201190:	4585                	li	a1,1
ffffffffc0201192:	8556                	mv	a0,s5
ffffffffc0201194:	5e7000ef          	jal	ra,ffffffffc0201f7a <free_pages>
    free_page(p1);
ffffffffc0201198:	4585                	li	a1,1
ffffffffc020119a:	854e                	mv	a0,s3
ffffffffc020119c:	5df000ef          	jal	ra,ffffffffc0201f7a <free_pages>
    free_page(p2);
ffffffffc02011a0:	4585                	li	a1,1
ffffffffc02011a2:	8552                	mv	a0,s4
ffffffffc02011a4:	5d7000ef          	jal	ra,ffffffffc0201f7a <free_pages>
    assert(nr_free == 3);
ffffffffc02011a8:	4818                	lw	a4,16(s0)
ffffffffc02011aa:	478d                	li	a5,3
ffffffffc02011ac:	28f71863          	bne	a4,a5,ffffffffc020143c <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011b0:	4505                	li	a0,1
ffffffffc02011b2:	58b000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc02011b6:	89aa                	mv	s3,a0
ffffffffc02011b8:	26050263          	beqz	a0,ffffffffc020141c <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011bc:	4505                	li	a0,1
ffffffffc02011be:	57f000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc02011c2:	8aaa                	mv	s5,a0
ffffffffc02011c4:	3a050c63          	beqz	a0,ffffffffc020157c <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011c8:	4505                	li	a0,1
ffffffffc02011ca:	573000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc02011ce:	8a2a                	mv	s4,a0
ffffffffc02011d0:	38050663          	beqz	a0,ffffffffc020155c <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc02011d4:	4505                	li	a0,1
ffffffffc02011d6:	567000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc02011da:	36051163          	bnez	a0,ffffffffc020153c <default_check+0x4a2>
    free_page(p0);
ffffffffc02011de:	4585                	li	a1,1
ffffffffc02011e0:	854e                	mv	a0,s3
ffffffffc02011e2:	599000ef          	jal	ra,ffffffffc0201f7a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02011e6:	641c                	ld	a5,8(s0)
ffffffffc02011e8:	20878a63          	beq	a5,s0,ffffffffc02013fc <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc02011ec:	4505                	li	a0,1
ffffffffc02011ee:	54f000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc02011f2:	30a99563          	bne	s3,a0,ffffffffc02014fc <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc02011f6:	4505                	li	a0,1
ffffffffc02011f8:	545000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc02011fc:	2e051063          	bnez	a0,ffffffffc02014dc <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0201200:	481c                	lw	a5,16(s0)
ffffffffc0201202:	2a079d63          	bnez	a5,ffffffffc02014bc <default_check+0x422>
    free_page(p);
ffffffffc0201206:	854e                	mv	a0,s3
ffffffffc0201208:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020120a:	01843023          	sd	s8,0(s0)
ffffffffc020120e:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201212:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201216:	565000ef          	jal	ra,ffffffffc0201f7a <free_pages>
    free_page(p1);
ffffffffc020121a:	4585                	li	a1,1
ffffffffc020121c:	8556                	mv	a0,s5
ffffffffc020121e:	55d000ef          	jal	ra,ffffffffc0201f7a <free_pages>
    free_page(p2);
ffffffffc0201222:	4585                	li	a1,1
ffffffffc0201224:	8552                	mv	a0,s4
ffffffffc0201226:	555000ef          	jal	ra,ffffffffc0201f7a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020122a:	4515                	li	a0,5
ffffffffc020122c:	511000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc0201230:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201232:	26050563          	beqz	a0,ffffffffc020149c <default_check+0x402>
ffffffffc0201236:	651c                	ld	a5,8(a0)
ffffffffc0201238:	8385                	srli	a5,a5,0x1
ffffffffc020123a:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc020123c:	54079063          	bnez	a5,ffffffffc020177c <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201240:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201242:	00043b03          	ld	s6,0(s0)
ffffffffc0201246:	00843a83          	ld	s5,8(s0)
ffffffffc020124a:	e000                	sd	s0,0(s0)
ffffffffc020124c:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020124e:	4ef000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc0201252:	50051563          	bnez	a0,ffffffffc020175c <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201256:	08098a13          	addi	s4,s3,128
ffffffffc020125a:	8552                	mv	a0,s4
ffffffffc020125c:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020125e:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0201262:	000a5797          	auipc	a5,0xa5
ffffffffc0201266:	4807a723          	sw	zero,1166(a5) # ffffffffc02a66f0 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020126a:	511000ef          	jal	ra,ffffffffc0201f7a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020126e:	4511                	li	a0,4
ffffffffc0201270:	4cd000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc0201274:	4c051463          	bnez	a0,ffffffffc020173c <default_check+0x6a2>
ffffffffc0201278:	0889b783          	ld	a5,136(s3)
ffffffffc020127c:	8385                	srli	a5,a5,0x1
ffffffffc020127e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201280:	48078e63          	beqz	a5,ffffffffc020171c <default_check+0x682>
ffffffffc0201284:	0909a703          	lw	a4,144(s3)
ffffffffc0201288:	478d                	li	a5,3
ffffffffc020128a:	48f71963          	bne	a4,a5,ffffffffc020171c <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020128e:	450d                	li	a0,3
ffffffffc0201290:	4ad000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc0201294:	8c2a                	mv	s8,a0
ffffffffc0201296:	46050363          	beqz	a0,ffffffffc02016fc <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc020129a:	4505                	li	a0,1
ffffffffc020129c:	4a1000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc02012a0:	42051e63          	bnez	a0,ffffffffc02016dc <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02012a4:	418a1c63          	bne	s4,s8,ffffffffc02016bc <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02012a8:	4585                	li	a1,1
ffffffffc02012aa:	854e                	mv	a0,s3
ffffffffc02012ac:	4cf000ef          	jal	ra,ffffffffc0201f7a <free_pages>
    free_pages(p1, 3);
ffffffffc02012b0:	458d                	li	a1,3
ffffffffc02012b2:	8552                	mv	a0,s4
ffffffffc02012b4:	4c7000ef          	jal	ra,ffffffffc0201f7a <free_pages>
ffffffffc02012b8:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02012bc:	04098c13          	addi	s8,s3,64
ffffffffc02012c0:	8385                	srli	a5,a5,0x1
ffffffffc02012c2:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02012c4:	3c078c63          	beqz	a5,ffffffffc020169c <default_check+0x602>
ffffffffc02012c8:	0109a703          	lw	a4,16(s3)
ffffffffc02012cc:	4785                	li	a5,1
ffffffffc02012ce:	3cf71763          	bne	a4,a5,ffffffffc020169c <default_check+0x602>
ffffffffc02012d2:	008a3783          	ld	a5,8(s4)
ffffffffc02012d6:	8385                	srli	a5,a5,0x1
ffffffffc02012d8:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02012da:	3a078163          	beqz	a5,ffffffffc020167c <default_check+0x5e2>
ffffffffc02012de:	010a2703          	lw	a4,16(s4)
ffffffffc02012e2:	478d                	li	a5,3
ffffffffc02012e4:	38f71c63          	bne	a4,a5,ffffffffc020167c <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02012e8:	4505                	li	a0,1
ffffffffc02012ea:	453000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc02012ee:	36a99763          	bne	s3,a0,ffffffffc020165c <default_check+0x5c2>
    free_page(p0);
ffffffffc02012f2:	4585                	li	a1,1
ffffffffc02012f4:	487000ef          	jal	ra,ffffffffc0201f7a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02012f8:	4509                	li	a0,2
ffffffffc02012fa:	443000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc02012fe:	32aa1f63          	bne	s4,a0,ffffffffc020163c <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0201302:	4589                	li	a1,2
ffffffffc0201304:	477000ef          	jal	ra,ffffffffc0201f7a <free_pages>
    free_page(p2);
ffffffffc0201308:	4585                	li	a1,1
ffffffffc020130a:	8562                	mv	a0,s8
ffffffffc020130c:	46f000ef          	jal	ra,ffffffffc0201f7a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201310:	4515                	li	a0,5
ffffffffc0201312:	42b000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc0201316:	89aa                	mv	s3,a0
ffffffffc0201318:	48050263          	beqz	a0,ffffffffc020179c <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc020131c:	4505                	li	a0,1
ffffffffc020131e:	41f000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc0201322:	2c051d63          	bnez	a0,ffffffffc02015fc <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201326:	481c                	lw	a5,16(s0)
ffffffffc0201328:	2a079a63          	bnez	a5,ffffffffc02015dc <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020132c:	4595                	li	a1,5
ffffffffc020132e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201330:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201334:	01643023          	sd	s6,0(s0)
ffffffffc0201338:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020133c:	43f000ef          	jal	ra,ffffffffc0201f7a <free_pages>
    return listelm->next;
ffffffffc0201340:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201342:	00878963          	beq	a5,s0,ffffffffc0201354 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201346:	ff87a703          	lw	a4,-8(a5)
ffffffffc020134a:	679c                	ld	a5,8(a5)
ffffffffc020134c:	397d                	addiw	s2,s2,-1
ffffffffc020134e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201350:	fe879be3          	bne	a5,s0,ffffffffc0201346 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201354:	26091463          	bnez	s2,ffffffffc02015bc <default_check+0x522>
    assert(total == 0);
ffffffffc0201358:	46049263          	bnez	s1,ffffffffc02017bc <default_check+0x722>
}
ffffffffc020135c:	60a6                	ld	ra,72(sp)
ffffffffc020135e:	6406                	ld	s0,64(sp)
ffffffffc0201360:	74e2                	ld	s1,56(sp)
ffffffffc0201362:	7942                	ld	s2,48(sp)
ffffffffc0201364:	79a2                	ld	s3,40(sp)
ffffffffc0201366:	7a02                	ld	s4,32(sp)
ffffffffc0201368:	6ae2                	ld	s5,24(sp)
ffffffffc020136a:	6b42                	ld	s6,16(sp)
ffffffffc020136c:	6ba2                	ld	s7,8(sp)
ffffffffc020136e:	6c02                	ld	s8,0(sp)
ffffffffc0201370:	6161                	addi	sp,sp,80
ffffffffc0201372:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201374:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201376:	4481                	li	s1,0
ffffffffc0201378:	4901                	li	s2,0
ffffffffc020137a:	b38d                	j	ffffffffc02010dc <default_check+0x42>
        assert(PageProperty(p));
ffffffffc020137c:	00005697          	auipc	a3,0x5
ffffffffc0201380:	fd468693          	addi	a3,a3,-44 # ffffffffc0206350 <commands+0x858>
ffffffffc0201384:	00005617          	auipc	a2,0x5
ffffffffc0201388:	fdc60613          	addi	a2,a2,-36 # ffffffffc0206360 <commands+0x868>
ffffffffc020138c:	11000593          	li	a1,272
ffffffffc0201390:	00005517          	auipc	a0,0x5
ffffffffc0201394:	fe850513          	addi	a0,a0,-24 # ffffffffc0206378 <commands+0x880>
ffffffffc0201398:	8f6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020139c:	00005697          	auipc	a3,0x5
ffffffffc02013a0:	07468693          	addi	a3,a3,116 # ffffffffc0206410 <commands+0x918>
ffffffffc02013a4:	00005617          	auipc	a2,0x5
ffffffffc02013a8:	fbc60613          	addi	a2,a2,-68 # ffffffffc0206360 <commands+0x868>
ffffffffc02013ac:	0db00593          	li	a1,219
ffffffffc02013b0:	00005517          	auipc	a0,0x5
ffffffffc02013b4:	fc850513          	addi	a0,a0,-56 # ffffffffc0206378 <commands+0x880>
ffffffffc02013b8:	8d6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02013bc:	00005697          	auipc	a3,0x5
ffffffffc02013c0:	07c68693          	addi	a3,a3,124 # ffffffffc0206438 <commands+0x940>
ffffffffc02013c4:	00005617          	auipc	a2,0x5
ffffffffc02013c8:	f9c60613          	addi	a2,a2,-100 # ffffffffc0206360 <commands+0x868>
ffffffffc02013cc:	0dc00593          	li	a1,220
ffffffffc02013d0:	00005517          	auipc	a0,0x5
ffffffffc02013d4:	fa850513          	addi	a0,a0,-88 # ffffffffc0206378 <commands+0x880>
ffffffffc02013d8:	8b6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02013dc:	00005697          	auipc	a3,0x5
ffffffffc02013e0:	09c68693          	addi	a3,a3,156 # ffffffffc0206478 <commands+0x980>
ffffffffc02013e4:	00005617          	auipc	a2,0x5
ffffffffc02013e8:	f7c60613          	addi	a2,a2,-132 # ffffffffc0206360 <commands+0x868>
ffffffffc02013ec:	0de00593          	li	a1,222
ffffffffc02013f0:	00005517          	auipc	a0,0x5
ffffffffc02013f4:	f8850513          	addi	a0,a0,-120 # ffffffffc0206378 <commands+0x880>
ffffffffc02013f8:	896ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc02013fc:	00005697          	auipc	a3,0x5
ffffffffc0201400:	10468693          	addi	a3,a3,260 # ffffffffc0206500 <commands+0xa08>
ffffffffc0201404:	00005617          	auipc	a2,0x5
ffffffffc0201408:	f5c60613          	addi	a2,a2,-164 # ffffffffc0206360 <commands+0x868>
ffffffffc020140c:	0f700593          	li	a1,247
ffffffffc0201410:	00005517          	auipc	a0,0x5
ffffffffc0201414:	f6850513          	addi	a0,a0,-152 # ffffffffc0206378 <commands+0x880>
ffffffffc0201418:	876ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020141c:	00005697          	auipc	a3,0x5
ffffffffc0201420:	f9468693          	addi	a3,a3,-108 # ffffffffc02063b0 <commands+0x8b8>
ffffffffc0201424:	00005617          	auipc	a2,0x5
ffffffffc0201428:	f3c60613          	addi	a2,a2,-196 # ffffffffc0206360 <commands+0x868>
ffffffffc020142c:	0f000593          	li	a1,240
ffffffffc0201430:	00005517          	auipc	a0,0x5
ffffffffc0201434:	f4850513          	addi	a0,a0,-184 # ffffffffc0206378 <commands+0x880>
ffffffffc0201438:	856ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc020143c:	00005697          	auipc	a3,0x5
ffffffffc0201440:	0b468693          	addi	a3,a3,180 # ffffffffc02064f0 <commands+0x9f8>
ffffffffc0201444:	00005617          	auipc	a2,0x5
ffffffffc0201448:	f1c60613          	addi	a2,a2,-228 # ffffffffc0206360 <commands+0x868>
ffffffffc020144c:	0ee00593          	li	a1,238
ffffffffc0201450:	00005517          	auipc	a0,0x5
ffffffffc0201454:	f2850513          	addi	a0,a0,-216 # ffffffffc0206378 <commands+0x880>
ffffffffc0201458:	836ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020145c:	00005697          	auipc	a3,0x5
ffffffffc0201460:	07c68693          	addi	a3,a3,124 # ffffffffc02064d8 <commands+0x9e0>
ffffffffc0201464:	00005617          	auipc	a2,0x5
ffffffffc0201468:	efc60613          	addi	a2,a2,-260 # ffffffffc0206360 <commands+0x868>
ffffffffc020146c:	0e900593          	li	a1,233
ffffffffc0201470:	00005517          	auipc	a0,0x5
ffffffffc0201474:	f0850513          	addi	a0,a0,-248 # ffffffffc0206378 <commands+0x880>
ffffffffc0201478:	816ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020147c:	00005697          	auipc	a3,0x5
ffffffffc0201480:	03c68693          	addi	a3,a3,60 # ffffffffc02064b8 <commands+0x9c0>
ffffffffc0201484:	00005617          	auipc	a2,0x5
ffffffffc0201488:	edc60613          	addi	a2,a2,-292 # ffffffffc0206360 <commands+0x868>
ffffffffc020148c:	0e000593          	li	a1,224
ffffffffc0201490:	00005517          	auipc	a0,0x5
ffffffffc0201494:	ee850513          	addi	a0,a0,-280 # ffffffffc0206378 <commands+0x880>
ffffffffc0201498:	ff7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc020149c:	00005697          	auipc	a3,0x5
ffffffffc02014a0:	0ac68693          	addi	a3,a3,172 # ffffffffc0206548 <commands+0xa50>
ffffffffc02014a4:	00005617          	auipc	a2,0x5
ffffffffc02014a8:	ebc60613          	addi	a2,a2,-324 # ffffffffc0206360 <commands+0x868>
ffffffffc02014ac:	11800593          	li	a1,280
ffffffffc02014b0:	00005517          	auipc	a0,0x5
ffffffffc02014b4:	ec850513          	addi	a0,a0,-312 # ffffffffc0206378 <commands+0x880>
ffffffffc02014b8:	fd7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02014bc:	00005697          	auipc	a3,0x5
ffffffffc02014c0:	07c68693          	addi	a3,a3,124 # ffffffffc0206538 <commands+0xa40>
ffffffffc02014c4:	00005617          	auipc	a2,0x5
ffffffffc02014c8:	e9c60613          	addi	a2,a2,-356 # ffffffffc0206360 <commands+0x868>
ffffffffc02014cc:	0fd00593          	li	a1,253
ffffffffc02014d0:	00005517          	auipc	a0,0x5
ffffffffc02014d4:	ea850513          	addi	a0,a0,-344 # ffffffffc0206378 <commands+0x880>
ffffffffc02014d8:	fb7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014dc:	00005697          	auipc	a3,0x5
ffffffffc02014e0:	ffc68693          	addi	a3,a3,-4 # ffffffffc02064d8 <commands+0x9e0>
ffffffffc02014e4:	00005617          	auipc	a2,0x5
ffffffffc02014e8:	e7c60613          	addi	a2,a2,-388 # ffffffffc0206360 <commands+0x868>
ffffffffc02014ec:	0fb00593          	li	a1,251
ffffffffc02014f0:	00005517          	auipc	a0,0x5
ffffffffc02014f4:	e8850513          	addi	a0,a0,-376 # ffffffffc0206378 <commands+0x880>
ffffffffc02014f8:	f97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02014fc:	00005697          	auipc	a3,0x5
ffffffffc0201500:	01c68693          	addi	a3,a3,28 # ffffffffc0206518 <commands+0xa20>
ffffffffc0201504:	00005617          	auipc	a2,0x5
ffffffffc0201508:	e5c60613          	addi	a2,a2,-420 # ffffffffc0206360 <commands+0x868>
ffffffffc020150c:	0fa00593          	li	a1,250
ffffffffc0201510:	00005517          	auipc	a0,0x5
ffffffffc0201514:	e6850513          	addi	a0,a0,-408 # ffffffffc0206378 <commands+0x880>
ffffffffc0201518:	f77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020151c:	00005697          	auipc	a3,0x5
ffffffffc0201520:	e9468693          	addi	a3,a3,-364 # ffffffffc02063b0 <commands+0x8b8>
ffffffffc0201524:	00005617          	auipc	a2,0x5
ffffffffc0201528:	e3c60613          	addi	a2,a2,-452 # ffffffffc0206360 <commands+0x868>
ffffffffc020152c:	0d700593          	li	a1,215
ffffffffc0201530:	00005517          	auipc	a0,0x5
ffffffffc0201534:	e4850513          	addi	a0,a0,-440 # ffffffffc0206378 <commands+0x880>
ffffffffc0201538:	f57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020153c:	00005697          	auipc	a3,0x5
ffffffffc0201540:	f9c68693          	addi	a3,a3,-100 # ffffffffc02064d8 <commands+0x9e0>
ffffffffc0201544:	00005617          	auipc	a2,0x5
ffffffffc0201548:	e1c60613          	addi	a2,a2,-484 # ffffffffc0206360 <commands+0x868>
ffffffffc020154c:	0f400593          	li	a1,244
ffffffffc0201550:	00005517          	auipc	a0,0x5
ffffffffc0201554:	e2850513          	addi	a0,a0,-472 # ffffffffc0206378 <commands+0x880>
ffffffffc0201558:	f37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020155c:	00005697          	auipc	a3,0x5
ffffffffc0201560:	e9468693          	addi	a3,a3,-364 # ffffffffc02063f0 <commands+0x8f8>
ffffffffc0201564:	00005617          	auipc	a2,0x5
ffffffffc0201568:	dfc60613          	addi	a2,a2,-516 # ffffffffc0206360 <commands+0x868>
ffffffffc020156c:	0f200593          	li	a1,242
ffffffffc0201570:	00005517          	auipc	a0,0x5
ffffffffc0201574:	e0850513          	addi	a0,a0,-504 # ffffffffc0206378 <commands+0x880>
ffffffffc0201578:	f17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020157c:	00005697          	auipc	a3,0x5
ffffffffc0201580:	e5468693          	addi	a3,a3,-428 # ffffffffc02063d0 <commands+0x8d8>
ffffffffc0201584:	00005617          	auipc	a2,0x5
ffffffffc0201588:	ddc60613          	addi	a2,a2,-548 # ffffffffc0206360 <commands+0x868>
ffffffffc020158c:	0f100593          	li	a1,241
ffffffffc0201590:	00005517          	auipc	a0,0x5
ffffffffc0201594:	de850513          	addi	a0,a0,-536 # ffffffffc0206378 <commands+0x880>
ffffffffc0201598:	ef7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020159c:	00005697          	auipc	a3,0x5
ffffffffc02015a0:	e5468693          	addi	a3,a3,-428 # ffffffffc02063f0 <commands+0x8f8>
ffffffffc02015a4:	00005617          	auipc	a2,0x5
ffffffffc02015a8:	dbc60613          	addi	a2,a2,-580 # ffffffffc0206360 <commands+0x868>
ffffffffc02015ac:	0d900593          	li	a1,217
ffffffffc02015b0:	00005517          	auipc	a0,0x5
ffffffffc02015b4:	dc850513          	addi	a0,a0,-568 # ffffffffc0206378 <commands+0x880>
ffffffffc02015b8:	ed7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc02015bc:	00005697          	auipc	a3,0x5
ffffffffc02015c0:	0dc68693          	addi	a3,a3,220 # ffffffffc0206698 <commands+0xba0>
ffffffffc02015c4:	00005617          	auipc	a2,0x5
ffffffffc02015c8:	d9c60613          	addi	a2,a2,-612 # ffffffffc0206360 <commands+0x868>
ffffffffc02015cc:	14600593          	li	a1,326
ffffffffc02015d0:	00005517          	auipc	a0,0x5
ffffffffc02015d4:	da850513          	addi	a0,a0,-600 # ffffffffc0206378 <commands+0x880>
ffffffffc02015d8:	eb7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02015dc:	00005697          	auipc	a3,0x5
ffffffffc02015e0:	f5c68693          	addi	a3,a3,-164 # ffffffffc0206538 <commands+0xa40>
ffffffffc02015e4:	00005617          	auipc	a2,0x5
ffffffffc02015e8:	d7c60613          	addi	a2,a2,-644 # ffffffffc0206360 <commands+0x868>
ffffffffc02015ec:	13a00593          	li	a1,314
ffffffffc02015f0:	00005517          	auipc	a0,0x5
ffffffffc02015f4:	d8850513          	addi	a0,a0,-632 # ffffffffc0206378 <commands+0x880>
ffffffffc02015f8:	e97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015fc:	00005697          	auipc	a3,0x5
ffffffffc0201600:	edc68693          	addi	a3,a3,-292 # ffffffffc02064d8 <commands+0x9e0>
ffffffffc0201604:	00005617          	auipc	a2,0x5
ffffffffc0201608:	d5c60613          	addi	a2,a2,-676 # ffffffffc0206360 <commands+0x868>
ffffffffc020160c:	13800593          	li	a1,312
ffffffffc0201610:	00005517          	auipc	a0,0x5
ffffffffc0201614:	d6850513          	addi	a0,a0,-664 # ffffffffc0206378 <commands+0x880>
ffffffffc0201618:	e77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020161c:	00005697          	auipc	a3,0x5
ffffffffc0201620:	e7c68693          	addi	a3,a3,-388 # ffffffffc0206498 <commands+0x9a0>
ffffffffc0201624:	00005617          	auipc	a2,0x5
ffffffffc0201628:	d3c60613          	addi	a2,a2,-708 # ffffffffc0206360 <commands+0x868>
ffffffffc020162c:	0df00593          	li	a1,223
ffffffffc0201630:	00005517          	auipc	a0,0x5
ffffffffc0201634:	d4850513          	addi	a0,a0,-696 # ffffffffc0206378 <commands+0x880>
ffffffffc0201638:	e57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020163c:	00005697          	auipc	a3,0x5
ffffffffc0201640:	01c68693          	addi	a3,a3,28 # ffffffffc0206658 <commands+0xb60>
ffffffffc0201644:	00005617          	auipc	a2,0x5
ffffffffc0201648:	d1c60613          	addi	a2,a2,-740 # ffffffffc0206360 <commands+0x868>
ffffffffc020164c:	13200593          	li	a1,306
ffffffffc0201650:	00005517          	auipc	a0,0x5
ffffffffc0201654:	d2850513          	addi	a0,a0,-728 # ffffffffc0206378 <commands+0x880>
ffffffffc0201658:	e37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020165c:	00005697          	auipc	a3,0x5
ffffffffc0201660:	fdc68693          	addi	a3,a3,-36 # ffffffffc0206638 <commands+0xb40>
ffffffffc0201664:	00005617          	auipc	a2,0x5
ffffffffc0201668:	cfc60613          	addi	a2,a2,-772 # ffffffffc0206360 <commands+0x868>
ffffffffc020166c:	13000593          	li	a1,304
ffffffffc0201670:	00005517          	auipc	a0,0x5
ffffffffc0201674:	d0850513          	addi	a0,a0,-760 # ffffffffc0206378 <commands+0x880>
ffffffffc0201678:	e17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020167c:	00005697          	auipc	a3,0x5
ffffffffc0201680:	f9468693          	addi	a3,a3,-108 # ffffffffc0206610 <commands+0xb18>
ffffffffc0201684:	00005617          	auipc	a2,0x5
ffffffffc0201688:	cdc60613          	addi	a2,a2,-804 # ffffffffc0206360 <commands+0x868>
ffffffffc020168c:	12e00593          	li	a1,302
ffffffffc0201690:	00005517          	auipc	a0,0x5
ffffffffc0201694:	ce850513          	addi	a0,a0,-792 # ffffffffc0206378 <commands+0x880>
ffffffffc0201698:	df7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020169c:	00005697          	auipc	a3,0x5
ffffffffc02016a0:	f4c68693          	addi	a3,a3,-180 # ffffffffc02065e8 <commands+0xaf0>
ffffffffc02016a4:	00005617          	auipc	a2,0x5
ffffffffc02016a8:	cbc60613          	addi	a2,a2,-836 # ffffffffc0206360 <commands+0x868>
ffffffffc02016ac:	12d00593          	li	a1,301
ffffffffc02016b0:	00005517          	auipc	a0,0x5
ffffffffc02016b4:	cc850513          	addi	a0,a0,-824 # ffffffffc0206378 <commands+0x880>
ffffffffc02016b8:	dd7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc02016bc:	00005697          	auipc	a3,0x5
ffffffffc02016c0:	f1c68693          	addi	a3,a3,-228 # ffffffffc02065d8 <commands+0xae0>
ffffffffc02016c4:	00005617          	auipc	a2,0x5
ffffffffc02016c8:	c9c60613          	addi	a2,a2,-868 # ffffffffc0206360 <commands+0x868>
ffffffffc02016cc:	12800593          	li	a1,296
ffffffffc02016d0:	00005517          	auipc	a0,0x5
ffffffffc02016d4:	ca850513          	addi	a0,a0,-856 # ffffffffc0206378 <commands+0x880>
ffffffffc02016d8:	db7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016dc:	00005697          	auipc	a3,0x5
ffffffffc02016e0:	dfc68693          	addi	a3,a3,-516 # ffffffffc02064d8 <commands+0x9e0>
ffffffffc02016e4:	00005617          	auipc	a2,0x5
ffffffffc02016e8:	c7c60613          	addi	a2,a2,-900 # ffffffffc0206360 <commands+0x868>
ffffffffc02016ec:	12700593          	li	a1,295
ffffffffc02016f0:	00005517          	auipc	a0,0x5
ffffffffc02016f4:	c8850513          	addi	a0,a0,-888 # ffffffffc0206378 <commands+0x880>
ffffffffc02016f8:	d97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02016fc:	00005697          	auipc	a3,0x5
ffffffffc0201700:	ebc68693          	addi	a3,a3,-324 # ffffffffc02065b8 <commands+0xac0>
ffffffffc0201704:	00005617          	auipc	a2,0x5
ffffffffc0201708:	c5c60613          	addi	a2,a2,-932 # ffffffffc0206360 <commands+0x868>
ffffffffc020170c:	12600593          	li	a1,294
ffffffffc0201710:	00005517          	auipc	a0,0x5
ffffffffc0201714:	c6850513          	addi	a0,a0,-920 # ffffffffc0206378 <commands+0x880>
ffffffffc0201718:	d77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020171c:	00005697          	auipc	a3,0x5
ffffffffc0201720:	e6c68693          	addi	a3,a3,-404 # ffffffffc0206588 <commands+0xa90>
ffffffffc0201724:	00005617          	auipc	a2,0x5
ffffffffc0201728:	c3c60613          	addi	a2,a2,-964 # ffffffffc0206360 <commands+0x868>
ffffffffc020172c:	12500593          	li	a1,293
ffffffffc0201730:	00005517          	auipc	a0,0x5
ffffffffc0201734:	c4850513          	addi	a0,a0,-952 # ffffffffc0206378 <commands+0x880>
ffffffffc0201738:	d57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020173c:	00005697          	auipc	a3,0x5
ffffffffc0201740:	e3468693          	addi	a3,a3,-460 # ffffffffc0206570 <commands+0xa78>
ffffffffc0201744:	00005617          	auipc	a2,0x5
ffffffffc0201748:	c1c60613          	addi	a2,a2,-996 # ffffffffc0206360 <commands+0x868>
ffffffffc020174c:	12400593          	li	a1,292
ffffffffc0201750:	00005517          	auipc	a0,0x5
ffffffffc0201754:	c2850513          	addi	a0,a0,-984 # ffffffffc0206378 <commands+0x880>
ffffffffc0201758:	d37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020175c:	00005697          	auipc	a3,0x5
ffffffffc0201760:	d7c68693          	addi	a3,a3,-644 # ffffffffc02064d8 <commands+0x9e0>
ffffffffc0201764:	00005617          	auipc	a2,0x5
ffffffffc0201768:	bfc60613          	addi	a2,a2,-1028 # ffffffffc0206360 <commands+0x868>
ffffffffc020176c:	11e00593          	li	a1,286
ffffffffc0201770:	00005517          	auipc	a0,0x5
ffffffffc0201774:	c0850513          	addi	a0,a0,-1016 # ffffffffc0206378 <commands+0x880>
ffffffffc0201778:	d17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc020177c:	00005697          	auipc	a3,0x5
ffffffffc0201780:	ddc68693          	addi	a3,a3,-548 # ffffffffc0206558 <commands+0xa60>
ffffffffc0201784:	00005617          	auipc	a2,0x5
ffffffffc0201788:	bdc60613          	addi	a2,a2,-1060 # ffffffffc0206360 <commands+0x868>
ffffffffc020178c:	11900593          	li	a1,281
ffffffffc0201790:	00005517          	auipc	a0,0x5
ffffffffc0201794:	be850513          	addi	a0,a0,-1048 # ffffffffc0206378 <commands+0x880>
ffffffffc0201798:	cf7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020179c:	00005697          	auipc	a3,0x5
ffffffffc02017a0:	edc68693          	addi	a3,a3,-292 # ffffffffc0206678 <commands+0xb80>
ffffffffc02017a4:	00005617          	auipc	a2,0x5
ffffffffc02017a8:	bbc60613          	addi	a2,a2,-1092 # ffffffffc0206360 <commands+0x868>
ffffffffc02017ac:	13700593          	li	a1,311
ffffffffc02017b0:	00005517          	auipc	a0,0x5
ffffffffc02017b4:	bc850513          	addi	a0,a0,-1080 # ffffffffc0206378 <commands+0x880>
ffffffffc02017b8:	cd7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc02017bc:	00005697          	auipc	a3,0x5
ffffffffc02017c0:	eec68693          	addi	a3,a3,-276 # ffffffffc02066a8 <commands+0xbb0>
ffffffffc02017c4:	00005617          	auipc	a2,0x5
ffffffffc02017c8:	b9c60613          	addi	a2,a2,-1124 # ffffffffc0206360 <commands+0x868>
ffffffffc02017cc:	14700593          	li	a1,327
ffffffffc02017d0:	00005517          	auipc	a0,0x5
ffffffffc02017d4:	ba850513          	addi	a0,a0,-1112 # ffffffffc0206378 <commands+0x880>
ffffffffc02017d8:	cb7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc02017dc:	00005697          	auipc	a3,0x5
ffffffffc02017e0:	bb468693          	addi	a3,a3,-1100 # ffffffffc0206390 <commands+0x898>
ffffffffc02017e4:	00005617          	auipc	a2,0x5
ffffffffc02017e8:	b7c60613          	addi	a2,a2,-1156 # ffffffffc0206360 <commands+0x868>
ffffffffc02017ec:	11300593          	li	a1,275
ffffffffc02017f0:	00005517          	auipc	a0,0x5
ffffffffc02017f4:	b8850513          	addi	a0,a0,-1144 # ffffffffc0206378 <commands+0x880>
ffffffffc02017f8:	c97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02017fc:	00005697          	auipc	a3,0x5
ffffffffc0201800:	bd468693          	addi	a3,a3,-1068 # ffffffffc02063d0 <commands+0x8d8>
ffffffffc0201804:	00005617          	auipc	a2,0x5
ffffffffc0201808:	b5c60613          	addi	a2,a2,-1188 # ffffffffc0206360 <commands+0x868>
ffffffffc020180c:	0d800593          	li	a1,216
ffffffffc0201810:	00005517          	auipc	a0,0x5
ffffffffc0201814:	b6850513          	addi	a0,a0,-1176 # ffffffffc0206378 <commands+0x880>
ffffffffc0201818:	c77fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020181c <default_free_pages>:
{
ffffffffc020181c:	1141                	addi	sp,sp,-16
ffffffffc020181e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201820:	14058463          	beqz	a1,ffffffffc0201968 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201824:	00659693          	slli	a3,a1,0x6
ffffffffc0201828:	96aa                	add	a3,a3,a0
ffffffffc020182a:	87aa                	mv	a5,a0
ffffffffc020182c:	02d50263          	beq	a0,a3,ffffffffc0201850 <default_free_pages+0x34>
ffffffffc0201830:	6798                	ld	a4,8(a5)
ffffffffc0201832:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201834:	10071a63          	bnez	a4,ffffffffc0201948 <default_free_pages+0x12c>
ffffffffc0201838:	6798                	ld	a4,8(a5)
ffffffffc020183a:	8b09                	andi	a4,a4,2
ffffffffc020183c:	10071663          	bnez	a4,ffffffffc0201948 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201840:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201844:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201848:	04078793          	addi	a5,a5,64
ffffffffc020184c:	fed792e3          	bne	a5,a3,ffffffffc0201830 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201850:	2581                	sext.w	a1,a1
ffffffffc0201852:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201854:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201858:	4789                	li	a5,2
ffffffffc020185a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020185e:	000a5697          	auipc	a3,0xa5
ffffffffc0201862:	e8268693          	addi	a3,a3,-382 # ffffffffc02a66e0 <free_area>
ffffffffc0201866:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201868:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020186a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020186e:	9db9                	addw	a1,a1,a4
ffffffffc0201870:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201872:	0ad78463          	beq	a5,a3,ffffffffc020191a <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc0201876:	fe878713          	addi	a4,a5,-24
ffffffffc020187a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc020187e:	4581                	li	a1,0
            if (base < page)
ffffffffc0201880:	00e56a63          	bltu	a0,a4,ffffffffc0201894 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201884:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201886:	04d70c63          	beq	a4,a3,ffffffffc02018de <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc020188a:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc020188c:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201890:	fee57ae3          	bgeu	a0,a4,ffffffffc0201884 <default_free_pages+0x68>
ffffffffc0201894:	c199                	beqz	a1,ffffffffc020189a <default_free_pages+0x7e>
ffffffffc0201896:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020189a:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020189c:	e390                	sd	a2,0(a5)
ffffffffc020189e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02018a0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018a2:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02018a4:	00d70d63          	beq	a4,a3,ffffffffc02018be <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02018a8:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02018ac:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02018b0:	02059813          	slli	a6,a1,0x20
ffffffffc02018b4:	01a85793          	srli	a5,a6,0x1a
ffffffffc02018b8:	97b2                	add	a5,a5,a2
ffffffffc02018ba:	02f50c63          	beq	a0,a5,ffffffffc02018f2 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02018be:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02018c0:	00d78c63          	beq	a5,a3,ffffffffc02018d8 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02018c4:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02018c6:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02018ca:	02061593          	slli	a1,a2,0x20
ffffffffc02018ce:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02018d2:	972a                	add	a4,a4,a0
ffffffffc02018d4:	04e68a63          	beq	a3,a4,ffffffffc0201928 <default_free_pages+0x10c>
}
ffffffffc02018d8:	60a2                	ld	ra,8(sp)
ffffffffc02018da:	0141                	addi	sp,sp,16
ffffffffc02018dc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02018de:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018e0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02018e2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02018e4:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc02018e6:	02d70763          	beq	a4,a3,ffffffffc0201914 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc02018ea:	8832                	mv	a6,a2
ffffffffc02018ec:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc02018ee:	87ba                	mv	a5,a4
ffffffffc02018f0:	bf71                	j	ffffffffc020188c <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02018f2:	491c                	lw	a5,16(a0)
ffffffffc02018f4:	9dbd                	addw	a1,a1,a5
ffffffffc02018f6:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02018fa:	57f5                	li	a5,-3
ffffffffc02018fc:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201900:	01853803          	ld	a6,24(a0)
ffffffffc0201904:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201906:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201908:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc020190c:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020190e:	0105b023          	sd	a6,0(a1)
ffffffffc0201912:	b77d                	j	ffffffffc02018c0 <default_free_pages+0xa4>
ffffffffc0201914:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201916:	873e                	mv	a4,a5
ffffffffc0201918:	bf41                	j	ffffffffc02018a8 <default_free_pages+0x8c>
}
ffffffffc020191a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020191c:	e390                	sd	a2,0(a5)
ffffffffc020191e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201920:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201922:	ed1c                	sd	a5,24(a0)
ffffffffc0201924:	0141                	addi	sp,sp,16
ffffffffc0201926:	8082                	ret
            base->property += p->property;
ffffffffc0201928:	ff87a703          	lw	a4,-8(a5)
ffffffffc020192c:	ff078693          	addi	a3,a5,-16
ffffffffc0201930:	9e39                	addw	a2,a2,a4
ffffffffc0201932:	c910                	sw	a2,16(a0)
ffffffffc0201934:	5775                	li	a4,-3
ffffffffc0201936:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020193a:	6398                	ld	a4,0(a5)
ffffffffc020193c:	679c                	ld	a5,8(a5)
}
ffffffffc020193e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201940:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201942:	e398                	sd	a4,0(a5)
ffffffffc0201944:	0141                	addi	sp,sp,16
ffffffffc0201946:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201948:	00005697          	auipc	a3,0x5
ffffffffc020194c:	d7868693          	addi	a3,a3,-648 # ffffffffc02066c0 <commands+0xbc8>
ffffffffc0201950:	00005617          	auipc	a2,0x5
ffffffffc0201954:	a1060613          	addi	a2,a2,-1520 # ffffffffc0206360 <commands+0x868>
ffffffffc0201958:	09400593          	li	a1,148
ffffffffc020195c:	00005517          	auipc	a0,0x5
ffffffffc0201960:	a1c50513          	addi	a0,a0,-1508 # ffffffffc0206378 <commands+0x880>
ffffffffc0201964:	b2bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201968:	00005697          	auipc	a3,0x5
ffffffffc020196c:	d5068693          	addi	a3,a3,-688 # ffffffffc02066b8 <commands+0xbc0>
ffffffffc0201970:	00005617          	auipc	a2,0x5
ffffffffc0201974:	9f060613          	addi	a2,a2,-1552 # ffffffffc0206360 <commands+0x868>
ffffffffc0201978:	09000593          	li	a1,144
ffffffffc020197c:	00005517          	auipc	a0,0x5
ffffffffc0201980:	9fc50513          	addi	a0,a0,-1540 # ffffffffc0206378 <commands+0x880>
ffffffffc0201984:	b0bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201988 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201988:	c941                	beqz	a0,ffffffffc0201a18 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc020198a:	000a5597          	auipc	a1,0xa5
ffffffffc020198e:	d5658593          	addi	a1,a1,-682 # ffffffffc02a66e0 <free_area>
ffffffffc0201992:	0105a803          	lw	a6,16(a1)
ffffffffc0201996:	872a                	mv	a4,a0
ffffffffc0201998:	02081793          	slli	a5,a6,0x20
ffffffffc020199c:	9381                	srli	a5,a5,0x20
ffffffffc020199e:	00a7ee63          	bltu	a5,a0,ffffffffc02019ba <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02019a2:	87ae                	mv	a5,a1
ffffffffc02019a4:	a801                	j	ffffffffc02019b4 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc02019a6:	ff87a683          	lw	a3,-8(a5)
ffffffffc02019aa:	02069613          	slli	a2,a3,0x20
ffffffffc02019ae:	9201                	srli	a2,a2,0x20
ffffffffc02019b0:	00e67763          	bgeu	a2,a4,ffffffffc02019be <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02019b4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02019b6:	feb798e3          	bne	a5,a1,ffffffffc02019a6 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02019ba:	4501                	li	a0,0
}
ffffffffc02019bc:	8082                	ret
    return listelm->prev;
ffffffffc02019be:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02019c2:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02019c6:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02019ca:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02019ce:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02019d2:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc02019d6:	02c77863          	bgeu	a4,a2,ffffffffc0201a06 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02019da:	071a                	slli	a4,a4,0x6
ffffffffc02019dc:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02019de:	41c686bb          	subw	a3,a3,t3
ffffffffc02019e2:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02019e4:	00870613          	addi	a2,a4,8
ffffffffc02019e8:	4689                	li	a3,2
ffffffffc02019ea:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02019ee:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02019f2:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc02019f6:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02019fa:	e290                	sd	a2,0(a3)
ffffffffc02019fc:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201a00:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201a02:	01173c23          	sd	a7,24(a4)
ffffffffc0201a06:	41c8083b          	subw	a6,a6,t3
ffffffffc0201a0a:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201a0e:	5775                	li	a4,-3
ffffffffc0201a10:	17c1                	addi	a5,a5,-16
ffffffffc0201a12:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201a16:	8082                	ret
{
ffffffffc0201a18:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201a1a:	00005697          	auipc	a3,0x5
ffffffffc0201a1e:	c9e68693          	addi	a3,a3,-866 # ffffffffc02066b8 <commands+0xbc0>
ffffffffc0201a22:	00005617          	auipc	a2,0x5
ffffffffc0201a26:	93e60613          	addi	a2,a2,-1730 # ffffffffc0206360 <commands+0x868>
ffffffffc0201a2a:	06c00593          	li	a1,108
ffffffffc0201a2e:	00005517          	auipc	a0,0x5
ffffffffc0201a32:	94a50513          	addi	a0,a0,-1718 # ffffffffc0206378 <commands+0x880>
{
ffffffffc0201a36:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201a38:	a57fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201a3c <default_init_memmap>:
{
ffffffffc0201a3c:	1141                	addi	sp,sp,-16
ffffffffc0201a3e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201a40:	c5f1                	beqz	a1,ffffffffc0201b0c <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201a42:	00659693          	slli	a3,a1,0x6
ffffffffc0201a46:	96aa                	add	a3,a3,a0
ffffffffc0201a48:	87aa                	mv	a5,a0
ffffffffc0201a4a:	00d50f63          	beq	a0,a3,ffffffffc0201a68 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201a4e:	6798                	ld	a4,8(a5)
ffffffffc0201a50:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201a52:	cf49                	beqz	a4,ffffffffc0201aec <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201a54:	0007a823          	sw	zero,16(a5)
ffffffffc0201a58:	0007b423          	sd	zero,8(a5)
ffffffffc0201a5c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201a60:	04078793          	addi	a5,a5,64
ffffffffc0201a64:	fed795e3          	bne	a5,a3,ffffffffc0201a4e <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201a68:	2581                	sext.w	a1,a1
ffffffffc0201a6a:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201a6c:	4789                	li	a5,2
ffffffffc0201a6e:	00850713          	addi	a4,a0,8
ffffffffc0201a72:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201a76:	000a5697          	auipc	a3,0xa5
ffffffffc0201a7a:	c6a68693          	addi	a3,a3,-918 # ffffffffc02a66e0 <free_area>
ffffffffc0201a7e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201a80:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a82:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201a86:	9db9                	addw	a1,a1,a4
ffffffffc0201a88:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201a8a:	04d78a63          	beq	a5,a3,ffffffffc0201ade <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201a8e:	fe878713          	addi	a4,a5,-24
ffffffffc0201a92:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201a96:	4581                	li	a1,0
            if (base < page)
ffffffffc0201a98:	00e56a63          	bltu	a0,a4,ffffffffc0201aac <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201a9c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201a9e:	02d70263          	beq	a4,a3,ffffffffc0201ac2 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201aa2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201aa4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201aa8:	fee57ae3          	bgeu	a0,a4,ffffffffc0201a9c <default_init_memmap+0x60>
ffffffffc0201aac:	c199                	beqz	a1,ffffffffc0201ab2 <default_init_memmap+0x76>
ffffffffc0201aae:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201ab2:	6398                	ld	a4,0(a5)
}
ffffffffc0201ab4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201ab6:	e390                	sd	a2,0(a5)
ffffffffc0201ab8:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201aba:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201abc:	ed18                	sd	a4,24(a0)
ffffffffc0201abe:	0141                	addi	sp,sp,16
ffffffffc0201ac0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201ac2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201ac4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201ac6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201ac8:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201aca:	00d70663          	beq	a4,a3,ffffffffc0201ad6 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201ace:	8832                	mv	a6,a2
ffffffffc0201ad0:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201ad2:	87ba                	mv	a5,a4
ffffffffc0201ad4:	bfc1                	j	ffffffffc0201aa4 <default_init_memmap+0x68>
}
ffffffffc0201ad6:	60a2                	ld	ra,8(sp)
ffffffffc0201ad8:	e290                	sd	a2,0(a3)
ffffffffc0201ada:	0141                	addi	sp,sp,16
ffffffffc0201adc:	8082                	ret
ffffffffc0201ade:	60a2                	ld	ra,8(sp)
ffffffffc0201ae0:	e390                	sd	a2,0(a5)
ffffffffc0201ae2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201ae4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201ae6:	ed1c                	sd	a5,24(a0)
ffffffffc0201ae8:	0141                	addi	sp,sp,16
ffffffffc0201aea:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201aec:	00005697          	auipc	a3,0x5
ffffffffc0201af0:	bfc68693          	addi	a3,a3,-1028 # ffffffffc02066e8 <commands+0xbf0>
ffffffffc0201af4:	00005617          	auipc	a2,0x5
ffffffffc0201af8:	86c60613          	addi	a2,a2,-1940 # ffffffffc0206360 <commands+0x868>
ffffffffc0201afc:	04b00593          	li	a1,75
ffffffffc0201b00:	00005517          	auipc	a0,0x5
ffffffffc0201b04:	87850513          	addi	a0,a0,-1928 # ffffffffc0206378 <commands+0x880>
ffffffffc0201b08:	987fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201b0c:	00005697          	auipc	a3,0x5
ffffffffc0201b10:	bac68693          	addi	a3,a3,-1108 # ffffffffc02066b8 <commands+0xbc0>
ffffffffc0201b14:	00005617          	auipc	a2,0x5
ffffffffc0201b18:	84c60613          	addi	a2,a2,-1972 # ffffffffc0206360 <commands+0x868>
ffffffffc0201b1c:	04700593          	li	a1,71
ffffffffc0201b20:	00005517          	auipc	a0,0x5
ffffffffc0201b24:	85850513          	addi	a0,a0,-1960 # ffffffffc0206378 <commands+0x880>
ffffffffc0201b28:	967fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201b2c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201b2c:	c94d                	beqz	a0,ffffffffc0201bde <slob_free+0xb2>
{
ffffffffc0201b2e:	1141                	addi	sp,sp,-16
ffffffffc0201b30:	e022                	sd	s0,0(sp)
ffffffffc0201b32:	e406                	sd	ra,8(sp)
ffffffffc0201b34:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201b36:	e9c1                	bnez	a1,ffffffffc0201bc6 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b38:	100027f3          	csrr	a5,sstatus
ffffffffc0201b3c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b3e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b40:	ebd9                	bnez	a5,ffffffffc0201bd6 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b42:	000a4617          	auipc	a2,0xa4
ffffffffc0201b46:	78e60613          	addi	a2,a2,1934 # ffffffffc02a62d0 <slobfree>
ffffffffc0201b4a:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b4c:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b4e:	679c                	ld	a5,8(a5)
ffffffffc0201b50:	02877a63          	bgeu	a4,s0,ffffffffc0201b84 <slob_free+0x58>
ffffffffc0201b54:	00f46463          	bltu	s0,a5,ffffffffc0201b5c <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b58:	fef76ae3          	bltu	a4,a5,ffffffffc0201b4c <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201b5c:	400c                	lw	a1,0(s0)
ffffffffc0201b5e:	00459693          	slli	a3,a1,0x4
ffffffffc0201b62:	96a2                	add	a3,a3,s0
ffffffffc0201b64:	02d78a63          	beq	a5,a3,ffffffffc0201b98 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201b68:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201b6a:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b6c:	00469793          	slli	a5,a3,0x4
ffffffffc0201b70:	97ba                	add	a5,a5,a4
ffffffffc0201b72:	02f40e63          	beq	s0,a5,ffffffffc0201bae <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201b76:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201b78:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201b7a:	e129                	bnez	a0,ffffffffc0201bbc <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b7c:	60a2                	ld	ra,8(sp)
ffffffffc0201b7e:	6402                	ld	s0,0(sp)
ffffffffc0201b80:	0141                	addi	sp,sp,16
ffffffffc0201b82:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b84:	fcf764e3          	bltu	a4,a5,ffffffffc0201b4c <slob_free+0x20>
ffffffffc0201b88:	fcf472e3          	bgeu	s0,a5,ffffffffc0201b4c <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201b8c:	400c                	lw	a1,0(s0)
ffffffffc0201b8e:	00459693          	slli	a3,a1,0x4
ffffffffc0201b92:	96a2                	add	a3,a3,s0
ffffffffc0201b94:	fcd79ae3          	bne	a5,a3,ffffffffc0201b68 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201b98:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b9a:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b9c:	9db5                	addw	a1,a1,a3
ffffffffc0201b9e:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201ba0:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201ba2:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201ba4:	00469793          	slli	a5,a3,0x4
ffffffffc0201ba8:	97ba                	add	a5,a5,a4
ffffffffc0201baa:	fcf416e3          	bne	s0,a5,ffffffffc0201b76 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201bae:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201bb0:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201bb2:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201bb4:	9ebd                	addw	a3,a3,a5
ffffffffc0201bb6:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201bb8:	e70c                	sd	a1,8(a4)
ffffffffc0201bba:	d169                	beqz	a0,ffffffffc0201b7c <slob_free+0x50>
}
ffffffffc0201bbc:	6402                	ld	s0,0(sp)
ffffffffc0201bbe:	60a2                	ld	ra,8(sp)
ffffffffc0201bc0:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201bc2:	dedfe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201bc6:	25bd                	addiw	a1,a1,15
ffffffffc0201bc8:	8191                	srli	a1,a1,0x4
ffffffffc0201bca:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bcc:	100027f3          	csrr	a5,sstatus
ffffffffc0201bd0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201bd2:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bd4:	d7bd                	beqz	a5,ffffffffc0201b42 <slob_free+0x16>
        intr_disable();
ffffffffc0201bd6:	ddffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201bda:	4505                	li	a0,1
ffffffffc0201bdc:	b79d                	j	ffffffffc0201b42 <slob_free+0x16>
ffffffffc0201bde:	8082                	ret

ffffffffc0201be0 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201be0:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201be2:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201be4:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201be8:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bea:	352000ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
	if (!page)
ffffffffc0201bee:	c91d                	beqz	a0,ffffffffc0201c24 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201bf0:	000a9697          	auipc	a3,0xa9
ffffffffc0201bf4:	b686b683          	ld	a3,-1176(a3) # ffffffffc02aa758 <pages>
ffffffffc0201bf8:	8d15                	sub	a0,a0,a3
ffffffffc0201bfa:	8519                	srai	a0,a0,0x6
ffffffffc0201bfc:	00006697          	auipc	a3,0x6
ffffffffc0201c00:	dfc6b683          	ld	a3,-516(a3) # ffffffffc02079f8 <nbase>
ffffffffc0201c04:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201c06:	00c51793          	slli	a5,a0,0xc
ffffffffc0201c0a:	83b1                	srli	a5,a5,0xc
ffffffffc0201c0c:	000a9717          	auipc	a4,0xa9
ffffffffc0201c10:	b4473703          	ld	a4,-1212(a4) # ffffffffc02aa750 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201c14:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201c16:	00e7fa63          	bgeu	a5,a4,ffffffffc0201c2a <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201c1a:	000a9697          	auipc	a3,0xa9
ffffffffc0201c1e:	b4e6b683          	ld	a3,-1202(a3) # ffffffffc02aa768 <va_pa_offset>
ffffffffc0201c22:	9536                	add	a0,a0,a3
}
ffffffffc0201c24:	60a2                	ld	ra,8(sp)
ffffffffc0201c26:	0141                	addi	sp,sp,16
ffffffffc0201c28:	8082                	ret
ffffffffc0201c2a:	86aa                	mv	a3,a0
ffffffffc0201c2c:	00005617          	auipc	a2,0x5
ffffffffc0201c30:	b1c60613          	addi	a2,a2,-1252 # ffffffffc0206748 <default_pmm_manager+0x38>
ffffffffc0201c34:	07100593          	li	a1,113
ffffffffc0201c38:	00005517          	auipc	a0,0x5
ffffffffc0201c3c:	b3850513          	addi	a0,a0,-1224 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc0201c40:	84ffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201c44 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201c44:	1101                	addi	sp,sp,-32
ffffffffc0201c46:	ec06                	sd	ra,24(sp)
ffffffffc0201c48:	e822                	sd	s0,16(sp)
ffffffffc0201c4a:	e426                	sd	s1,8(sp)
ffffffffc0201c4c:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c4e:	01050713          	addi	a4,a0,16
ffffffffc0201c52:	6785                	lui	a5,0x1
ffffffffc0201c54:	0cf77363          	bgeu	a4,a5,ffffffffc0201d1a <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201c58:	00f50493          	addi	s1,a0,15
ffffffffc0201c5c:	8091                	srli	s1,s1,0x4
ffffffffc0201c5e:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c60:	10002673          	csrr	a2,sstatus
ffffffffc0201c64:	8a09                	andi	a2,a2,2
ffffffffc0201c66:	e25d                	bnez	a2,ffffffffc0201d0c <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201c68:	000a4917          	auipc	s2,0xa4
ffffffffc0201c6c:	66890913          	addi	s2,s2,1640 # ffffffffc02a62d0 <slobfree>
ffffffffc0201c70:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c74:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201c76:	4398                	lw	a4,0(a5)
ffffffffc0201c78:	08975e63          	bge	a4,s1,ffffffffc0201d14 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201c7c:	00f68b63          	beq	a3,a5,ffffffffc0201c92 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c80:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c82:	4018                	lw	a4,0(s0)
ffffffffc0201c84:	02975a63          	bge	a4,s1,ffffffffc0201cb8 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201c88:	00093683          	ld	a3,0(s2)
ffffffffc0201c8c:	87a2                	mv	a5,s0
ffffffffc0201c8e:	fef699e3          	bne	a3,a5,ffffffffc0201c80 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201c92:	ee31                	bnez	a2,ffffffffc0201cee <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c94:	4501                	li	a0,0
ffffffffc0201c96:	f4bff0ef          	jal	ra,ffffffffc0201be0 <__slob_get_free_pages.constprop.0>
ffffffffc0201c9a:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201c9c:	cd05                	beqz	a0,ffffffffc0201cd4 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c9e:	6585                	lui	a1,0x1
ffffffffc0201ca0:	e8dff0ef          	jal	ra,ffffffffc0201b2c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ca4:	10002673          	csrr	a2,sstatus
ffffffffc0201ca8:	8a09                	andi	a2,a2,2
ffffffffc0201caa:	ee05                	bnez	a2,ffffffffc0201ce2 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201cac:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201cb0:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201cb2:	4018                	lw	a4,0(s0)
ffffffffc0201cb4:	fc974ae3          	blt	a4,s1,ffffffffc0201c88 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201cb8:	04e48763          	beq	s1,a4,ffffffffc0201d06 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201cbc:	00449693          	slli	a3,s1,0x4
ffffffffc0201cc0:	96a2                	add	a3,a3,s0
ffffffffc0201cc2:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201cc4:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201cc6:	9f05                	subw	a4,a4,s1
ffffffffc0201cc8:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201cca:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201ccc:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201cce:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201cd2:	e20d                	bnez	a2,ffffffffc0201cf4 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201cd4:	60e2                	ld	ra,24(sp)
ffffffffc0201cd6:	8522                	mv	a0,s0
ffffffffc0201cd8:	6442                	ld	s0,16(sp)
ffffffffc0201cda:	64a2                	ld	s1,8(sp)
ffffffffc0201cdc:	6902                	ld	s2,0(sp)
ffffffffc0201cde:	6105                	addi	sp,sp,32
ffffffffc0201ce0:	8082                	ret
        intr_disable();
ffffffffc0201ce2:	cd3fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201ce6:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201cea:	4605                	li	a2,1
ffffffffc0201cec:	b7d1                	j	ffffffffc0201cb0 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201cee:	cc1fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201cf2:	b74d                	j	ffffffffc0201c94 <slob_alloc.constprop.0+0x50>
ffffffffc0201cf4:	cbbfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201cf8:	60e2                	ld	ra,24(sp)
ffffffffc0201cfa:	8522                	mv	a0,s0
ffffffffc0201cfc:	6442                	ld	s0,16(sp)
ffffffffc0201cfe:	64a2                	ld	s1,8(sp)
ffffffffc0201d00:	6902                	ld	s2,0(sp)
ffffffffc0201d02:	6105                	addi	sp,sp,32
ffffffffc0201d04:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201d06:	6418                	ld	a4,8(s0)
ffffffffc0201d08:	e798                	sd	a4,8(a5)
ffffffffc0201d0a:	b7d1                	j	ffffffffc0201cce <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201d0c:	ca9fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201d10:	4605                	li	a2,1
ffffffffc0201d12:	bf99                	j	ffffffffc0201c68 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201d14:	843e                	mv	s0,a5
ffffffffc0201d16:	87b6                	mv	a5,a3
ffffffffc0201d18:	b745                	j	ffffffffc0201cb8 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201d1a:	00005697          	auipc	a3,0x5
ffffffffc0201d1e:	a6668693          	addi	a3,a3,-1434 # ffffffffc0206780 <default_pmm_manager+0x70>
ffffffffc0201d22:	00004617          	auipc	a2,0x4
ffffffffc0201d26:	63e60613          	addi	a2,a2,1598 # ffffffffc0206360 <commands+0x868>
ffffffffc0201d2a:	06300593          	li	a1,99
ffffffffc0201d2e:	00005517          	auipc	a0,0x5
ffffffffc0201d32:	a7250513          	addi	a0,a0,-1422 # ffffffffc02067a0 <default_pmm_manager+0x90>
ffffffffc0201d36:	f58fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201d3a <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201d3a:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201d3c:	00005517          	auipc	a0,0x5
ffffffffc0201d40:	a7c50513          	addi	a0,a0,-1412 # ffffffffc02067b8 <default_pmm_manager+0xa8>
{
ffffffffc0201d44:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201d46:	c4efe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201d4a:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d4c:	00005517          	auipc	a0,0x5
ffffffffc0201d50:	a8450513          	addi	a0,a0,-1404 # ffffffffc02067d0 <default_pmm_manager+0xc0>
}
ffffffffc0201d54:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d56:	c3efe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201d5a <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201d5a:	4501                	li	a0,0
ffffffffc0201d5c:	8082                	ret

ffffffffc0201d5e <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201d5e:	1101                	addi	sp,sp,-32
ffffffffc0201d60:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d62:	6905                	lui	s2,0x1
{
ffffffffc0201d64:	e822                	sd	s0,16(sp)
ffffffffc0201d66:	ec06                	sd	ra,24(sp)
ffffffffc0201d68:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d6a:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bc1>
{
ffffffffc0201d6e:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d70:	04a7f963          	bgeu	a5,a0,ffffffffc0201dc2 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201d74:	4561                	li	a0,24
ffffffffc0201d76:	ecfff0ef          	jal	ra,ffffffffc0201c44 <slob_alloc.constprop.0>
ffffffffc0201d7a:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201d7c:	c929                	beqz	a0,ffffffffc0201dce <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201d7e:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201d82:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201d84:	00f95763          	bge	s2,a5,ffffffffc0201d92 <kmalloc+0x34>
ffffffffc0201d88:	6705                	lui	a4,0x1
ffffffffc0201d8a:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201d8c:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201d8e:	fef74ee3          	blt	a4,a5,ffffffffc0201d8a <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201d92:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d94:	e4dff0ef          	jal	ra,ffffffffc0201be0 <__slob_get_free_pages.constprop.0>
ffffffffc0201d98:	e488                	sd	a0,8(s1)
ffffffffc0201d9a:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201d9c:	c525                	beqz	a0,ffffffffc0201e04 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d9e:	100027f3          	csrr	a5,sstatus
ffffffffc0201da2:	8b89                	andi	a5,a5,2
ffffffffc0201da4:	ef8d                	bnez	a5,ffffffffc0201dde <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201da6:	000a9797          	auipc	a5,0xa9
ffffffffc0201daa:	99278793          	addi	a5,a5,-1646 # ffffffffc02aa738 <bigblocks>
ffffffffc0201dae:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201db0:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201db2:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201db4:	60e2                	ld	ra,24(sp)
ffffffffc0201db6:	8522                	mv	a0,s0
ffffffffc0201db8:	6442                	ld	s0,16(sp)
ffffffffc0201dba:	64a2                	ld	s1,8(sp)
ffffffffc0201dbc:	6902                	ld	s2,0(sp)
ffffffffc0201dbe:	6105                	addi	sp,sp,32
ffffffffc0201dc0:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201dc2:	0541                	addi	a0,a0,16
ffffffffc0201dc4:	e81ff0ef          	jal	ra,ffffffffc0201c44 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201dc8:	01050413          	addi	s0,a0,16
ffffffffc0201dcc:	f565                	bnez	a0,ffffffffc0201db4 <kmalloc+0x56>
ffffffffc0201dce:	4401                	li	s0,0
}
ffffffffc0201dd0:	60e2                	ld	ra,24(sp)
ffffffffc0201dd2:	8522                	mv	a0,s0
ffffffffc0201dd4:	6442                	ld	s0,16(sp)
ffffffffc0201dd6:	64a2                	ld	s1,8(sp)
ffffffffc0201dd8:	6902                	ld	s2,0(sp)
ffffffffc0201dda:	6105                	addi	sp,sp,32
ffffffffc0201ddc:	8082                	ret
        intr_disable();
ffffffffc0201dde:	bd7fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201de2:	000a9797          	auipc	a5,0xa9
ffffffffc0201de6:	95678793          	addi	a5,a5,-1706 # ffffffffc02aa738 <bigblocks>
ffffffffc0201dea:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201dec:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201dee:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201df0:	bbffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201df4:	6480                	ld	s0,8(s1)
}
ffffffffc0201df6:	60e2                	ld	ra,24(sp)
ffffffffc0201df8:	64a2                	ld	s1,8(sp)
ffffffffc0201dfa:	8522                	mv	a0,s0
ffffffffc0201dfc:	6442                	ld	s0,16(sp)
ffffffffc0201dfe:	6902                	ld	s2,0(sp)
ffffffffc0201e00:	6105                	addi	sp,sp,32
ffffffffc0201e02:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e04:	45e1                	li	a1,24
ffffffffc0201e06:	8526                	mv	a0,s1
ffffffffc0201e08:	d25ff0ef          	jal	ra,ffffffffc0201b2c <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201e0c:	b765                	j	ffffffffc0201db4 <kmalloc+0x56>

ffffffffc0201e0e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201e0e:	c169                	beqz	a0,ffffffffc0201ed0 <kfree+0xc2>
{
ffffffffc0201e10:	1101                	addi	sp,sp,-32
ffffffffc0201e12:	e822                	sd	s0,16(sp)
ffffffffc0201e14:	ec06                	sd	ra,24(sp)
ffffffffc0201e16:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201e18:	03451793          	slli	a5,a0,0x34
ffffffffc0201e1c:	842a                	mv	s0,a0
ffffffffc0201e1e:	e3d9                	bnez	a5,ffffffffc0201ea4 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e20:	100027f3          	csrr	a5,sstatus
ffffffffc0201e24:	8b89                	andi	a5,a5,2
ffffffffc0201e26:	e7d9                	bnez	a5,ffffffffc0201eb4 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e28:	000a9797          	auipc	a5,0xa9
ffffffffc0201e2c:	9107b783          	ld	a5,-1776(a5) # ffffffffc02aa738 <bigblocks>
    return 0;
ffffffffc0201e30:	4601                	li	a2,0
ffffffffc0201e32:	cbad                	beqz	a5,ffffffffc0201ea4 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201e34:	000a9697          	auipc	a3,0xa9
ffffffffc0201e38:	90468693          	addi	a3,a3,-1788 # ffffffffc02aa738 <bigblocks>
ffffffffc0201e3c:	a021                	j	ffffffffc0201e44 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e3e:	01048693          	addi	a3,s1,16
ffffffffc0201e42:	c3a5                	beqz	a5,ffffffffc0201ea2 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201e44:	6798                	ld	a4,8(a5)
ffffffffc0201e46:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201e48:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201e4a:	fe871ae3          	bne	a4,s0,ffffffffc0201e3e <kfree+0x30>
				*last = bb->next;
ffffffffc0201e4e:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201e50:	ee2d                	bnez	a2,ffffffffc0201eca <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201e52:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201e56:	4098                	lw	a4,0(s1)
ffffffffc0201e58:	08f46963          	bltu	s0,a5,ffffffffc0201eea <kfree+0xdc>
ffffffffc0201e5c:	000a9697          	auipc	a3,0xa9
ffffffffc0201e60:	90c6b683          	ld	a3,-1780(a3) # ffffffffc02aa768 <va_pa_offset>
ffffffffc0201e64:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201e66:	8031                	srli	s0,s0,0xc
ffffffffc0201e68:	000a9797          	auipc	a5,0xa9
ffffffffc0201e6c:	8e87b783          	ld	a5,-1816(a5) # ffffffffc02aa750 <npage>
ffffffffc0201e70:	06f47163          	bgeu	s0,a5,ffffffffc0201ed2 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e74:	00006517          	auipc	a0,0x6
ffffffffc0201e78:	b8453503          	ld	a0,-1148(a0) # ffffffffc02079f8 <nbase>
ffffffffc0201e7c:	8c09                	sub	s0,s0,a0
ffffffffc0201e7e:	041a                	slli	s0,s0,0x6
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201e80:	000a9517          	auipc	a0,0xa9
ffffffffc0201e84:	8d853503          	ld	a0,-1832(a0) # ffffffffc02aa758 <pages>
ffffffffc0201e88:	4585                	li	a1,1
ffffffffc0201e8a:	9522                	add	a0,a0,s0
ffffffffc0201e8c:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201e90:	0ea000ef          	jal	ra,ffffffffc0201f7a <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201e94:	6442                	ld	s0,16(sp)
ffffffffc0201e96:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e98:	8526                	mv	a0,s1
}
ffffffffc0201e9a:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e9c:	45e1                	li	a1,24
}
ffffffffc0201e9e:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ea0:	b171                	j	ffffffffc0201b2c <slob_free>
ffffffffc0201ea2:	e20d                	bnez	a2,ffffffffc0201ec4 <kfree+0xb6>
ffffffffc0201ea4:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201ea8:	6442                	ld	s0,16(sp)
ffffffffc0201eaa:	60e2                	ld	ra,24(sp)
ffffffffc0201eac:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201eae:	4581                	li	a1,0
}
ffffffffc0201eb0:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201eb2:	b9ad                	j	ffffffffc0201b2c <slob_free>
        intr_disable();
ffffffffc0201eb4:	b01fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201eb8:	000a9797          	auipc	a5,0xa9
ffffffffc0201ebc:	8807b783          	ld	a5,-1920(a5) # ffffffffc02aa738 <bigblocks>
        return 1;
ffffffffc0201ec0:	4605                	li	a2,1
ffffffffc0201ec2:	fbad                	bnez	a5,ffffffffc0201e34 <kfree+0x26>
        intr_enable();
ffffffffc0201ec4:	aebfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201ec8:	bff1                	j	ffffffffc0201ea4 <kfree+0x96>
ffffffffc0201eca:	ae5fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201ece:	b751                	j	ffffffffc0201e52 <kfree+0x44>
ffffffffc0201ed0:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201ed2:	00005617          	auipc	a2,0x5
ffffffffc0201ed6:	94660613          	addi	a2,a2,-1722 # ffffffffc0206818 <default_pmm_manager+0x108>
ffffffffc0201eda:	06900593          	li	a1,105
ffffffffc0201ede:	00005517          	auipc	a0,0x5
ffffffffc0201ee2:	89250513          	addi	a0,a0,-1902 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc0201ee6:	da8fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201eea:	86a2                	mv	a3,s0
ffffffffc0201eec:	00005617          	auipc	a2,0x5
ffffffffc0201ef0:	90460613          	addi	a2,a2,-1788 # ffffffffc02067f0 <default_pmm_manager+0xe0>
ffffffffc0201ef4:	07700593          	li	a1,119
ffffffffc0201ef8:	00005517          	auipc	a0,0x5
ffffffffc0201efc:	87850513          	addi	a0,a0,-1928 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc0201f00:	d8efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f04 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201f04:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201f06:	00005617          	auipc	a2,0x5
ffffffffc0201f0a:	91260613          	addi	a2,a2,-1774 # ffffffffc0206818 <default_pmm_manager+0x108>
ffffffffc0201f0e:	06900593          	li	a1,105
ffffffffc0201f12:	00005517          	auipc	a0,0x5
ffffffffc0201f16:	85e50513          	addi	a0,a0,-1954 # ffffffffc0206770 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201f1a:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201f1c:	d72fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f20 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201f20:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201f22:	00005617          	auipc	a2,0x5
ffffffffc0201f26:	91660613          	addi	a2,a2,-1770 # ffffffffc0206838 <default_pmm_manager+0x128>
ffffffffc0201f2a:	07f00593          	li	a1,127
ffffffffc0201f2e:	00005517          	auipc	a0,0x5
ffffffffc0201f32:	84250513          	addi	a0,a0,-1982 # ffffffffc0206770 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201f36:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201f38:	d56fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f3c <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f3c:	100027f3          	csrr	a5,sstatus
ffffffffc0201f40:	8b89                	andi	a5,a5,2
ffffffffc0201f42:	e799                	bnez	a5,ffffffffc0201f50 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f44:	000a9797          	auipc	a5,0xa9
ffffffffc0201f48:	81c7b783          	ld	a5,-2020(a5) # ffffffffc02aa760 <pmm_manager>
ffffffffc0201f4c:	6f9c                	ld	a5,24(a5)
ffffffffc0201f4e:	8782                	jr	a5
{
ffffffffc0201f50:	1141                	addi	sp,sp,-16
ffffffffc0201f52:	e406                	sd	ra,8(sp)
ffffffffc0201f54:	e022                	sd	s0,0(sp)
ffffffffc0201f56:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201f58:	a5dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f5c:	000a9797          	auipc	a5,0xa9
ffffffffc0201f60:	8047b783          	ld	a5,-2044(a5) # ffffffffc02aa760 <pmm_manager>
ffffffffc0201f64:	6f9c                	ld	a5,24(a5)
ffffffffc0201f66:	8522                	mv	a0,s0
ffffffffc0201f68:	9782                	jalr	a5
ffffffffc0201f6a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f6c:	a43fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201f70:	60a2                	ld	ra,8(sp)
ffffffffc0201f72:	8522                	mv	a0,s0
ffffffffc0201f74:	6402                	ld	s0,0(sp)
ffffffffc0201f76:	0141                	addi	sp,sp,16
ffffffffc0201f78:	8082                	ret

ffffffffc0201f7a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f7a:	100027f3          	csrr	a5,sstatus
ffffffffc0201f7e:	8b89                	andi	a5,a5,2
ffffffffc0201f80:	e799                	bnez	a5,ffffffffc0201f8e <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201f82:	000a8797          	auipc	a5,0xa8
ffffffffc0201f86:	7de7b783          	ld	a5,2014(a5) # ffffffffc02aa760 <pmm_manager>
ffffffffc0201f8a:	739c                	ld	a5,32(a5)
ffffffffc0201f8c:	8782                	jr	a5
{
ffffffffc0201f8e:	1101                	addi	sp,sp,-32
ffffffffc0201f90:	ec06                	sd	ra,24(sp)
ffffffffc0201f92:	e822                	sd	s0,16(sp)
ffffffffc0201f94:	e426                	sd	s1,8(sp)
ffffffffc0201f96:	842a                	mv	s0,a0
ffffffffc0201f98:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201f9a:	a1bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201f9e:	000a8797          	auipc	a5,0xa8
ffffffffc0201fa2:	7c27b783          	ld	a5,1986(a5) # ffffffffc02aa760 <pmm_manager>
ffffffffc0201fa6:	739c                	ld	a5,32(a5)
ffffffffc0201fa8:	85a6                	mv	a1,s1
ffffffffc0201faa:	8522                	mv	a0,s0
ffffffffc0201fac:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201fae:	6442                	ld	s0,16(sp)
ffffffffc0201fb0:	60e2                	ld	ra,24(sp)
ffffffffc0201fb2:	64a2                	ld	s1,8(sp)
ffffffffc0201fb4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201fb6:	9f9fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0201fba <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201fba:	100027f3          	csrr	a5,sstatus
ffffffffc0201fbe:	8b89                	andi	a5,a5,2
ffffffffc0201fc0:	e799                	bnez	a5,ffffffffc0201fce <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201fc2:	000a8797          	auipc	a5,0xa8
ffffffffc0201fc6:	79e7b783          	ld	a5,1950(a5) # ffffffffc02aa760 <pmm_manager>
ffffffffc0201fca:	779c                	ld	a5,40(a5)
ffffffffc0201fcc:	8782                	jr	a5
{
ffffffffc0201fce:	1141                	addi	sp,sp,-16
ffffffffc0201fd0:	e406                	sd	ra,8(sp)
ffffffffc0201fd2:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201fd4:	9e1fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201fd8:	000a8797          	auipc	a5,0xa8
ffffffffc0201fdc:	7887b783          	ld	a5,1928(a5) # ffffffffc02aa760 <pmm_manager>
ffffffffc0201fe0:	779c                	ld	a5,40(a5)
ffffffffc0201fe2:	9782                	jalr	a5
ffffffffc0201fe4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201fe6:	9c9fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201fea:	60a2                	ld	ra,8(sp)
ffffffffc0201fec:	8522                	mv	a0,s0
ffffffffc0201fee:	6402                	ld	s0,0(sp)
ffffffffc0201ff0:	0141                	addi	sp,sp,16
ffffffffc0201ff2:	8082                	ret

ffffffffc0201ff4 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201ff4:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201ff8:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201ffc:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201ffe:	078e                	slli	a5,a5,0x3
{
ffffffffc0202000:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202002:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0202006:	6094                	ld	a3,0(s1)
{
ffffffffc0202008:	f04a                	sd	s2,32(sp)
ffffffffc020200a:	ec4e                	sd	s3,24(sp)
ffffffffc020200c:	e852                	sd	s4,16(sp)
ffffffffc020200e:	fc06                	sd	ra,56(sp)
ffffffffc0202010:	f822                	sd	s0,48(sp)
ffffffffc0202012:	e456                	sd	s5,8(sp)
ffffffffc0202014:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0202016:	0016f793          	andi	a5,a3,1
{
ffffffffc020201a:	892e                	mv	s2,a1
ffffffffc020201c:	8a32                	mv	s4,a2
ffffffffc020201e:	000a8997          	auipc	s3,0xa8
ffffffffc0202022:	73298993          	addi	s3,s3,1842 # ffffffffc02aa750 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0202026:	efbd                	bnez	a5,ffffffffc02020a4 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202028:	14060c63          	beqz	a2,ffffffffc0202180 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020202c:	100027f3          	csrr	a5,sstatus
ffffffffc0202030:	8b89                	andi	a5,a5,2
ffffffffc0202032:	14079963          	bnez	a5,ffffffffc0202184 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202036:	000a8797          	auipc	a5,0xa8
ffffffffc020203a:	72a7b783          	ld	a5,1834(a5) # ffffffffc02aa760 <pmm_manager>
ffffffffc020203e:	6f9c                	ld	a5,24(a5)
ffffffffc0202040:	4505                	li	a0,1
ffffffffc0202042:	9782                	jalr	a5
ffffffffc0202044:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202046:	12040d63          	beqz	s0,ffffffffc0202180 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc020204a:	000a8b17          	auipc	s6,0xa8
ffffffffc020204e:	70eb0b13          	addi	s6,s6,1806 # ffffffffc02aa758 <pages>
ffffffffc0202052:	000b3503          	ld	a0,0(s6)
ffffffffc0202056:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020205a:	000a8997          	auipc	s3,0xa8
ffffffffc020205e:	6f698993          	addi	s3,s3,1782 # ffffffffc02aa750 <npage>
ffffffffc0202062:	40a40533          	sub	a0,s0,a0
ffffffffc0202066:	8519                	srai	a0,a0,0x6
ffffffffc0202068:	9556                	add	a0,a0,s5
ffffffffc020206a:	0009b703          	ld	a4,0(s3)
ffffffffc020206e:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202072:	4685                	li	a3,1
ffffffffc0202074:	c014                	sw	a3,0(s0)
ffffffffc0202076:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202078:	0532                	slli	a0,a0,0xc
ffffffffc020207a:	16e7f763          	bgeu	a5,a4,ffffffffc02021e8 <get_pte+0x1f4>
ffffffffc020207e:	000a8797          	auipc	a5,0xa8
ffffffffc0202082:	6ea7b783          	ld	a5,1770(a5) # ffffffffc02aa768 <va_pa_offset>
ffffffffc0202086:	6605                	lui	a2,0x1
ffffffffc0202088:	4581                	li	a1,0
ffffffffc020208a:	953e                	add	a0,a0,a5
ffffffffc020208c:	7d6030ef          	jal	ra,ffffffffc0205862 <memset>
    return page - pages + nbase;
ffffffffc0202090:	000b3683          	ld	a3,0(s6)
ffffffffc0202094:	40d406b3          	sub	a3,s0,a3
ffffffffc0202098:	8699                	srai	a3,a3,0x6
ffffffffc020209a:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020209c:	06aa                	slli	a3,a3,0xa
ffffffffc020209e:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02020a2:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02020a4:	77fd                	lui	a5,0xfffff
ffffffffc02020a6:	068a                	slli	a3,a3,0x2
ffffffffc02020a8:	0009b703          	ld	a4,0(s3)
ffffffffc02020ac:	8efd                	and	a3,a3,a5
ffffffffc02020ae:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020b2:	10e7ff63          	bgeu	a5,a4,ffffffffc02021d0 <get_pte+0x1dc>
ffffffffc02020b6:	000a8a97          	auipc	s5,0xa8
ffffffffc02020ba:	6b2a8a93          	addi	s5,s5,1714 # ffffffffc02aa768 <va_pa_offset>
ffffffffc02020be:	000ab403          	ld	s0,0(s5)
ffffffffc02020c2:	01595793          	srli	a5,s2,0x15
ffffffffc02020c6:	1ff7f793          	andi	a5,a5,511
ffffffffc02020ca:	96a2                	add	a3,a3,s0
ffffffffc02020cc:	00379413          	slli	s0,a5,0x3
ffffffffc02020d0:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc02020d2:	6014                	ld	a3,0(s0)
ffffffffc02020d4:	0016f793          	andi	a5,a3,1
ffffffffc02020d8:	ebad                	bnez	a5,ffffffffc020214a <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020da:	0a0a0363          	beqz	s4,ffffffffc0202180 <get_pte+0x18c>
ffffffffc02020de:	100027f3          	csrr	a5,sstatus
ffffffffc02020e2:	8b89                	andi	a5,a5,2
ffffffffc02020e4:	efcd                	bnez	a5,ffffffffc020219e <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020e6:	000a8797          	auipc	a5,0xa8
ffffffffc02020ea:	67a7b783          	ld	a5,1658(a5) # ffffffffc02aa760 <pmm_manager>
ffffffffc02020ee:	6f9c                	ld	a5,24(a5)
ffffffffc02020f0:	4505                	li	a0,1
ffffffffc02020f2:	9782                	jalr	a5
ffffffffc02020f4:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020f6:	c4c9                	beqz	s1,ffffffffc0202180 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc02020f8:	000a8b17          	auipc	s6,0xa8
ffffffffc02020fc:	660b0b13          	addi	s6,s6,1632 # ffffffffc02aa758 <pages>
ffffffffc0202100:	000b3503          	ld	a0,0(s6)
ffffffffc0202104:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202108:	0009b703          	ld	a4,0(s3)
ffffffffc020210c:	40a48533          	sub	a0,s1,a0
ffffffffc0202110:	8519                	srai	a0,a0,0x6
ffffffffc0202112:	9552                	add	a0,a0,s4
ffffffffc0202114:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202118:	4685                	li	a3,1
ffffffffc020211a:	c094                	sw	a3,0(s1)
ffffffffc020211c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020211e:	0532                	slli	a0,a0,0xc
ffffffffc0202120:	0ee7f163          	bgeu	a5,a4,ffffffffc0202202 <get_pte+0x20e>
ffffffffc0202124:	000ab783          	ld	a5,0(s5)
ffffffffc0202128:	6605                	lui	a2,0x1
ffffffffc020212a:	4581                	li	a1,0
ffffffffc020212c:	953e                	add	a0,a0,a5
ffffffffc020212e:	734030ef          	jal	ra,ffffffffc0205862 <memset>
    return page - pages + nbase;
ffffffffc0202132:	000b3683          	ld	a3,0(s6)
ffffffffc0202136:	40d486b3          	sub	a3,s1,a3
ffffffffc020213a:	8699                	srai	a3,a3,0x6
ffffffffc020213c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020213e:	06aa                	slli	a3,a3,0xa
ffffffffc0202140:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202144:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202146:	0009b703          	ld	a4,0(s3)
ffffffffc020214a:	068a                	slli	a3,a3,0x2
ffffffffc020214c:	757d                	lui	a0,0xfffff
ffffffffc020214e:	8ee9                	and	a3,a3,a0
ffffffffc0202150:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202154:	06e7f263          	bgeu	a5,a4,ffffffffc02021b8 <get_pte+0x1c4>
ffffffffc0202158:	000ab503          	ld	a0,0(s5)
ffffffffc020215c:	00c95913          	srli	s2,s2,0xc
ffffffffc0202160:	1ff97913          	andi	s2,s2,511
ffffffffc0202164:	96aa                	add	a3,a3,a0
ffffffffc0202166:	00391513          	slli	a0,s2,0x3
ffffffffc020216a:	9536                	add	a0,a0,a3
}
ffffffffc020216c:	70e2                	ld	ra,56(sp)
ffffffffc020216e:	7442                	ld	s0,48(sp)
ffffffffc0202170:	74a2                	ld	s1,40(sp)
ffffffffc0202172:	7902                	ld	s2,32(sp)
ffffffffc0202174:	69e2                	ld	s3,24(sp)
ffffffffc0202176:	6a42                	ld	s4,16(sp)
ffffffffc0202178:	6aa2                	ld	s5,8(sp)
ffffffffc020217a:	6b02                	ld	s6,0(sp)
ffffffffc020217c:	6121                	addi	sp,sp,64
ffffffffc020217e:	8082                	ret
            return NULL;
ffffffffc0202180:	4501                	li	a0,0
ffffffffc0202182:	b7ed                	j	ffffffffc020216c <get_pte+0x178>
        intr_disable();
ffffffffc0202184:	831fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202188:	000a8797          	auipc	a5,0xa8
ffffffffc020218c:	5d87b783          	ld	a5,1496(a5) # ffffffffc02aa760 <pmm_manager>
ffffffffc0202190:	6f9c                	ld	a5,24(a5)
ffffffffc0202192:	4505                	li	a0,1
ffffffffc0202194:	9782                	jalr	a5
ffffffffc0202196:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202198:	817fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020219c:	b56d                	j	ffffffffc0202046 <get_pte+0x52>
        intr_disable();
ffffffffc020219e:	817fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02021a2:	000a8797          	auipc	a5,0xa8
ffffffffc02021a6:	5be7b783          	ld	a5,1470(a5) # ffffffffc02aa760 <pmm_manager>
ffffffffc02021aa:	6f9c                	ld	a5,24(a5)
ffffffffc02021ac:	4505                	li	a0,1
ffffffffc02021ae:	9782                	jalr	a5
ffffffffc02021b0:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc02021b2:	ffcfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02021b6:	b781                	j	ffffffffc02020f6 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02021b8:	00004617          	auipc	a2,0x4
ffffffffc02021bc:	59060613          	addi	a2,a2,1424 # ffffffffc0206748 <default_pmm_manager+0x38>
ffffffffc02021c0:	0fb00593          	li	a1,251
ffffffffc02021c4:	00004517          	auipc	a0,0x4
ffffffffc02021c8:	69c50513          	addi	a0,a0,1692 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02021cc:	ac2fe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02021d0:	00004617          	auipc	a2,0x4
ffffffffc02021d4:	57860613          	addi	a2,a2,1400 # ffffffffc0206748 <default_pmm_manager+0x38>
ffffffffc02021d8:	0ee00593          	li	a1,238
ffffffffc02021dc:	00004517          	auipc	a0,0x4
ffffffffc02021e0:	68450513          	addi	a0,a0,1668 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02021e4:	aaafe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021e8:	86aa                	mv	a3,a0
ffffffffc02021ea:	00004617          	auipc	a2,0x4
ffffffffc02021ee:	55e60613          	addi	a2,a2,1374 # ffffffffc0206748 <default_pmm_manager+0x38>
ffffffffc02021f2:	0ea00593          	li	a1,234
ffffffffc02021f6:	00004517          	auipc	a0,0x4
ffffffffc02021fa:	66a50513          	addi	a0,a0,1642 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02021fe:	a90fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202202:	86aa                	mv	a3,a0
ffffffffc0202204:	00004617          	auipc	a2,0x4
ffffffffc0202208:	54460613          	addi	a2,a2,1348 # ffffffffc0206748 <default_pmm_manager+0x38>
ffffffffc020220c:	0f800593          	li	a1,248
ffffffffc0202210:	00004517          	auipc	a0,0x4
ffffffffc0202214:	65050513          	addi	a0,a0,1616 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0202218:	a76fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020221c <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc020221c:	1141                	addi	sp,sp,-16
ffffffffc020221e:	e022                	sd	s0,0(sp)
ffffffffc0202220:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202222:	4601                	li	a2,0
{
ffffffffc0202224:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202226:	dcfff0ef          	jal	ra,ffffffffc0201ff4 <get_pte>
    if (ptep_store != NULL)
ffffffffc020222a:	c011                	beqz	s0,ffffffffc020222e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc020222c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020222e:	c511                	beqz	a0,ffffffffc020223a <get_page+0x1e>
ffffffffc0202230:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202232:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202234:	0017f713          	andi	a4,a5,1
ffffffffc0202238:	e709                	bnez	a4,ffffffffc0202242 <get_page+0x26>
}
ffffffffc020223a:	60a2                	ld	ra,8(sp)
ffffffffc020223c:	6402                	ld	s0,0(sp)
ffffffffc020223e:	0141                	addi	sp,sp,16
ffffffffc0202240:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202242:	078a                	slli	a5,a5,0x2
ffffffffc0202244:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202246:	000a8717          	auipc	a4,0xa8
ffffffffc020224a:	50a73703          	ld	a4,1290(a4) # ffffffffc02aa750 <npage>
ffffffffc020224e:	00e7ff63          	bgeu	a5,a4,ffffffffc020226c <get_page+0x50>
ffffffffc0202252:	60a2                	ld	ra,8(sp)
ffffffffc0202254:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0202256:	fff80537          	lui	a0,0xfff80
ffffffffc020225a:	97aa                	add	a5,a5,a0
ffffffffc020225c:	079a                	slli	a5,a5,0x6
ffffffffc020225e:	000a8517          	auipc	a0,0xa8
ffffffffc0202262:	4fa53503          	ld	a0,1274(a0) # ffffffffc02aa758 <pages>
ffffffffc0202266:	953e                	add	a0,a0,a5
ffffffffc0202268:	0141                	addi	sp,sp,16
ffffffffc020226a:	8082                	ret
ffffffffc020226c:	c99ff0ef          	jal	ra,ffffffffc0201f04 <pa2page.part.0>

ffffffffc0202270 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202270:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202272:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202276:	f486                	sd	ra,104(sp)
ffffffffc0202278:	f0a2                	sd	s0,96(sp)
ffffffffc020227a:	eca6                	sd	s1,88(sp)
ffffffffc020227c:	e8ca                	sd	s2,80(sp)
ffffffffc020227e:	e4ce                	sd	s3,72(sp)
ffffffffc0202280:	e0d2                	sd	s4,64(sp)
ffffffffc0202282:	fc56                	sd	s5,56(sp)
ffffffffc0202284:	f85a                	sd	s6,48(sp)
ffffffffc0202286:	f45e                	sd	s7,40(sp)
ffffffffc0202288:	f062                	sd	s8,32(sp)
ffffffffc020228a:	ec66                	sd	s9,24(sp)
ffffffffc020228c:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020228e:	17d2                	slli	a5,a5,0x34
ffffffffc0202290:	e3ed                	bnez	a5,ffffffffc0202372 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc0202292:	002007b7          	lui	a5,0x200
ffffffffc0202296:	842e                	mv	s0,a1
ffffffffc0202298:	0ef5ed63          	bltu	a1,a5,ffffffffc0202392 <unmap_range+0x122>
ffffffffc020229c:	8932                	mv	s2,a2
ffffffffc020229e:	0ec5fa63          	bgeu	a1,a2,ffffffffc0202392 <unmap_range+0x122>
ffffffffc02022a2:	4785                	li	a5,1
ffffffffc02022a4:	07fe                	slli	a5,a5,0x1f
ffffffffc02022a6:	0ec7e663          	bltu	a5,a2,ffffffffc0202392 <unmap_range+0x122>
ffffffffc02022aa:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02022ac:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02022ae:	000a8c97          	auipc	s9,0xa8
ffffffffc02022b2:	4a2c8c93          	addi	s9,s9,1186 # ffffffffc02aa750 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02022b6:	000a8c17          	auipc	s8,0xa8
ffffffffc02022ba:	4a2c0c13          	addi	s8,s8,1186 # ffffffffc02aa758 <pages>
ffffffffc02022be:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02022c2:	000a8d17          	auipc	s10,0xa8
ffffffffc02022c6:	49ed0d13          	addi	s10,s10,1182 # ffffffffc02aa760 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02022ca:	00200b37          	lui	s6,0x200
ffffffffc02022ce:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02022d2:	4601                	li	a2,0
ffffffffc02022d4:	85a2                	mv	a1,s0
ffffffffc02022d6:	854e                	mv	a0,s3
ffffffffc02022d8:	d1dff0ef          	jal	ra,ffffffffc0201ff4 <get_pte>
ffffffffc02022dc:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02022de:	cd29                	beqz	a0,ffffffffc0202338 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc02022e0:	611c                	ld	a5,0(a0)
ffffffffc02022e2:	e395                	bnez	a5,ffffffffc0202306 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc02022e4:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02022e6:	ff2466e3          	bltu	s0,s2,ffffffffc02022d2 <unmap_range+0x62>
}
ffffffffc02022ea:	70a6                	ld	ra,104(sp)
ffffffffc02022ec:	7406                	ld	s0,96(sp)
ffffffffc02022ee:	64e6                	ld	s1,88(sp)
ffffffffc02022f0:	6946                	ld	s2,80(sp)
ffffffffc02022f2:	69a6                	ld	s3,72(sp)
ffffffffc02022f4:	6a06                	ld	s4,64(sp)
ffffffffc02022f6:	7ae2                	ld	s5,56(sp)
ffffffffc02022f8:	7b42                	ld	s6,48(sp)
ffffffffc02022fa:	7ba2                	ld	s7,40(sp)
ffffffffc02022fc:	7c02                	ld	s8,32(sp)
ffffffffc02022fe:	6ce2                	ld	s9,24(sp)
ffffffffc0202300:	6d42                	ld	s10,16(sp)
ffffffffc0202302:	6165                	addi	sp,sp,112
ffffffffc0202304:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202306:	0017f713          	andi	a4,a5,1
ffffffffc020230a:	df69                	beqz	a4,ffffffffc02022e4 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc020230c:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202310:	078a                	slli	a5,a5,0x2
ffffffffc0202312:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202314:	08e7ff63          	bgeu	a5,a4,ffffffffc02023b2 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202318:	000c3503          	ld	a0,0(s8)
ffffffffc020231c:	97de                	add	a5,a5,s7
ffffffffc020231e:	079a                	slli	a5,a5,0x6
ffffffffc0202320:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202322:	411c                	lw	a5,0(a0)
ffffffffc0202324:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202328:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020232a:	cf11                	beqz	a4,ffffffffc0202346 <unmap_range+0xd6>
        *ptep = 0;
ffffffffc020232c:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202330:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202334:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202336:	bf45                	j	ffffffffc02022e6 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202338:	945a                	add	s0,s0,s6
ffffffffc020233a:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020233e:	d455                	beqz	s0,ffffffffc02022ea <unmap_range+0x7a>
ffffffffc0202340:	f92469e3          	bltu	s0,s2,ffffffffc02022d2 <unmap_range+0x62>
ffffffffc0202344:	b75d                	j	ffffffffc02022ea <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202346:	100027f3          	csrr	a5,sstatus
ffffffffc020234a:	8b89                	andi	a5,a5,2
ffffffffc020234c:	e799                	bnez	a5,ffffffffc020235a <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020234e:	000d3783          	ld	a5,0(s10)
ffffffffc0202352:	4585                	li	a1,1
ffffffffc0202354:	739c                	ld	a5,32(a5)
ffffffffc0202356:	9782                	jalr	a5
    if (flag)
ffffffffc0202358:	bfd1                	j	ffffffffc020232c <unmap_range+0xbc>
ffffffffc020235a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020235c:	e58fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202360:	000d3783          	ld	a5,0(s10)
ffffffffc0202364:	6522                	ld	a0,8(sp)
ffffffffc0202366:	4585                	li	a1,1
ffffffffc0202368:	739c                	ld	a5,32(a5)
ffffffffc020236a:	9782                	jalr	a5
        intr_enable();
ffffffffc020236c:	e42fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202370:	bf75                	j	ffffffffc020232c <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202372:	00004697          	auipc	a3,0x4
ffffffffc0202376:	4fe68693          	addi	a3,a3,1278 # ffffffffc0206870 <default_pmm_manager+0x160>
ffffffffc020237a:	00004617          	auipc	a2,0x4
ffffffffc020237e:	fe660613          	addi	a2,a2,-26 # ffffffffc0206360 <commands+0x868>
ffffffffc0202382:	12100593          	li	a1,289
ffffffffc0202386:	00004517          	auipc	a0,0x4
ffffffffc020238a:	4da50513          	addi	a0,a0,1242 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020238e:	900fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202392:	00004697          	auipc	a3,0x4
ffffffffc0202396:	50e68693          	addi	a3,a3,1294 # ffffffffc02068a0 <default_pmm_manager+0x190>
ffffffffc020239a:	00004617          	auipc	a2,0x4
ffffffffc020239e:	fc660613          	addi	a2,a2,-58 # ffffffffc0206360 <commands+0x868>
ffffffffc02023a2:	12200593          	li	a1,290
ffffffffc02023a6:	00004517          	auipc	a0,0x4
ffffffffc02023aa:	4ba50513          	addi	a0,a0,1210 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02023ae:	8e0fe0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02023b2:	b53ff0ef          	jal	ra,ffffffffc0201f04 <pa2page.part.0>

ffffffffc02023b6 <exit_range>:
{
ffffffffc02023b6:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023b8:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02023bc:	fc86                	sd	ra,120(sp)
ffffffffc02023be:	f8a2                	sd	s0,112(sp)
ffffffffc02023c0:	f4a6                	sd	s1,104(sp)
ffffffffc02023c2:	f0ca                	sd	s2,96(sp)
ffffffffc02023c4:	ecce                	sd	s3,88(sp)
ffffffffc02023c6:	e8d2                	sd	s4,80(sp)
ffffffffc02023c8:	e4d6                	sd	s5,72(sp)
ffffffffc02023ca:	e0da                	sd	s6,64(sp)
ffffffffc02023cc:	fc5e                	sd	s7,56(sp)
ffffffffc02023ce:	f862                	sd	s8,48(sp)
ffffffffc02023d0:	f466                	sd	s9,40(sp)
ffffffffc02023d2:	f06a                	sd	s10,32(sp)
ffffffffc02023d4:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023d6:	17d2                	slli	a5,a5,0x34
ffffffffc02023d8:	20079a63          	bnez	a5,ffffffffc02025ec <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02023dc:	002007b7          	lui	a5,0x200
ffffffffc02023e0:	24f5e463          	bltu	a1,a5,ffffffffc0202628 <exit_range+0x272>
ffffffffc02023e4:	8ab2                	mv	s5,a2
ffffffffc02023e6:	24c5f163          	bgeu	a1,a2,ffffffffc0202628 <exit_range+0x272>
ffffffffc02023ea:	4785                	li	a5,1
ffffffffc02023ec:	07fe                	slli	a5,a5,0x1f
ffffffffc02023ee:	22c7ed63          	bltu	a5,a2,ffffffffc0202628 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02023f2:	c00009b7          	lui	s3,0xc0000
ffffffffc02023f6:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02023fa:	ffe00937          	lui	s2,0xffe00
ffffffffc02023fe:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc0202402:	5cfd                	li	s9,-1
ffffffffc0202404:	8c2a                	mv	s8,a0
ffffffffc0202406:	0125f933          	and	s2,a1,s2
ffffffffc020240a:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc020240c:	000a8d17          	auipc	s10,0xa8
ffffffffc0202410:	344d0d13          	addi	s10,s10,836 # ffffffffc02aa750 <npage>
    return KADDR(page2pa(page));
ffffffffc0202414:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202418:	000a8717          	auipc	a4,0xa8
ffffffffc020241c:	34070713          	addi	a4,a4,832 # ffffffffc02aa758 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202420:	000a8d97          	auipc	s11,0xa8
ffffffffc0202424:	340d8d93          	addi	s11,s11,832 # ffffffffc02aa760 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202428:	c0000437          	lui	s0,0xc0000
ffffffffc020242c:	944e                	add	s0,s0,s3
ffffffffc020242e:	8079                	srli	s0,s0,0x1e
ffffffffc0202430:	1ff47413          	andi	s0,s0,511
ffffffffc0202434:	040e                	slli	s0,s0,0x3
ffffffffc0202436:	9462                	add	s0,s0,s8
ffffffffc0202438:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed8>
        if (pde1 & PTE_V)
ffffffffc020243c:	001a7793          	andi	a5,s4,1
ffffffffc0202440:	eb99                	bnez	a5,ffffffffc0202456 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202442:	12098463          	beqz	s3,ffffffffc020256a <exit_range+0x1b4>
ffffffffc0202446:	400007b7          	lui	a5,0x40000
ffffffffc020244a:	97ce                	add	a5,a5,s3
ffffffffc020244c:	894e                	mv	s2,s3
ffffffffc020244e:	1159fe63          	bgeu	s3,s5,ffffffffc020256a <exit_range+0x1b4>
ffffffffc0202452:	89be                	mv	s3,a5
ffffffffc0202454:	bfd1                	j	ffffffffc0202428 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc0202456:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020245a:	0a0a                	slli	s4,s4,0x2
ffffffffc020245c:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202460:	1cfa7263          	bgeu	s4,a5,ffffffffc0202624 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202464:	fff80637          	lui	a2,0xfff80
ffffffffc0202468:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc020246a:	000806b7          	lui	a3,0x80
ffffffffc020246e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202470:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202474:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202476:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202478:	18f5fa63          	bgeu	a1,a5,ffffffffc020260c <exit_range+0x256>
ffffffffc020247c:	000a8817          	auipc	a6,0xa8
ffffffffc0202480:	2ec80813          	addi	a6,a6,748 # ffffffffc02aa768 <va_pa_offset>
ffffffffc0202484:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc0202488:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc020248a:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc020248e:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202490:	00080337          	lui	t1,0x80
ffffffffc0202494:	6885                	lui	a7,0x1
ffffffffc0202496:	a819                	j	ffffffffc02024ac <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc0202498:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc020249a:	002007b7          	lui	a5,0x200
ffffffffc020249e:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02024a0:	08090c63          	beqz	s2,ffffffffc0202538 <exit_range+0x182>
ffffffffc02024a4:	09397a63          	bgeu	s2,s3,ffffffffc0202538 <exit_range+0x182>
ffffffffc02024a8:	0f597063          	bgeu	s2,s5,ffffffffc0202588 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02024ac:	01595493          	srli	s1,s2,0x15
ffffffffc02024b0:	1ff4f493          	andi	s1,s1,511
ffffffffc02024b4:	048e                	slli	s1,s1,0x3
ffffffffc02024b6:	94da                	add	s1,s1,s6
ffffffffc02024b8:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02024ba:	0017f693          	andi	a3,a5,1
ffffffffc02024be:	dee9                	beqz	a3,ffffffffc0202498 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc02024c0:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024c4:	078a                	slli	a5,a5,0x2
ffffffffc02024c6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024c8:	14b7fe63          	bgeu	a5,a1,ffffffffc0202624 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02024cc:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02024ce:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02024d2:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02024d6:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02024da:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02024dc:	12bef863          	bgeu	t4,a1,ffffffffc020260c <exit_range+0x256>
ffffffffc02024e0:	00083783          	ld	a5,0(a6)
ffffffffc02024e4:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024e6:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc02024ea:	629c                	ld	a5,0(a3)
ffffffffc02024ec:	8b85                	andi	a5,a5,1
ffffffffc02024ee:	f7d5                	bnez	a5,ffffffffc020249a <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024f0:	06a1                	addi	a3,a3,8
ffffffffc02024f2:	fed59ce3          	bne	a1,a3,ffffffffc02024ea <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc02024f6:	631c                	ld	a5,0(a4)
ffffffffc02024f8:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02024fa:	100027f3          	csrr	a5,sstatus
ffffffffc02024fe:	8b89                	andi	a5,a5,2
ffffffffc0202500:	e7d9                	bnez	a5,ffffffffc020258e <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc0202502:	000db783          	ld	a5,0(s11)
ffffffffc0202506:	4585                	li	a1,1
ffffffffc0202508:	e032                	sd	a2,0(sp)
ffffffffc020250a:	739c                	ld	a5,32(a5)
ffffffffc020250c:	9782                	jalr	a5
    if (flag)
ffffffffc020250e:	6602                	ld	a2,0(sp)
ffffffffc0202510:	000a8817          	auipc	a6,0xa8
ffffffffc0202514:	25880813          	addi	a6,a6,600 # ffffffffc02aa768 <va_pa_offset>
ffffffffc0202518:	fff80e37          	lui	t3,0xfff80
ffffffffc020251c:	00080337          	lui	t1,0x80
ffffffffc0202520:	6885                	lui	a7,0x1
ffffffffc0202522:	000a8717          	auipc	a4,0xa8
ffffffffc0202526:	23670713          	addi	a4,a4,566 # ffffffffc02aa758 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020252a:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020252e:	002007b7          	lui	a5,0x200
ffffffffc0202532:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202534:	f60918e3          	bnez	s2,ffffffffc02024a4 <exit_range+0xee>
            if (free_pd0)
ffffffffc0202538:	f00b85e3          	beqz	s7,ffffffffc0202442 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc020253c:	000d3783          	ld	a5,0(s10)
ffffffffc0202540:	0efa7263          	bgeu	s4,a5,ffffffffc0202624 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202544:	6308                	ld	a0,0(a4)
ffffffffc0202546:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202548:	100027f3          	csrr	a5,sstatus
ffffffffc020254c:	8b89                	andi	a5,a5,2
ffffffffc020254e:	efad                	bnez	a5,ffffffffc02025c8 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0202550:	000db783          	ld	a5,0(s11)
ffffffffc0202554:	4585                	li	a1,1
ffffffffc0202556:	739c                	ld	a5,32(a5)
ffffffffc0202558:	9782                	jalr	a5
ffffffffc020255a:	000a8717          	auipc	a4,0xa8
ffffffffc020255e:	1fe70713          	addi	a4,a4,510 # ffffffffc02aa758 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202562:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc0202566:	ee0990e3          	bnez	s3,ffffffffc0202446 <exit_range+0x90>
}
ffffffffc020256a:	70e6                	ld	ra,120(sp)
ffffffffc020256c:	7446                	ld	s0,112(sp)
ffffffffc020256e:	74a6                	ld	s1,104(sp)
ffffffffc0202570:	7906                	ld	s2,96(sp)
ffffffffc0202572:	69e6                	ld	s3,88(sp)
ffffffffc0202574:	6a46                	ld	s4,80(sp)
ffffffffc0202576:	6aa6                	ld	s5,72(sp)
ffffffffc0202578:	6b06                	ld	s6,64(sp)
ffffffffc020257a:	7be2                	ld	s7,56(sp)
ffffffffc020257c:	7c42                	ld	s8,48(sp)
ffffffffc020257e:	7ca2                	ld	s9,40(sp)
ffffffffc0202580:	7d02                	ld	s10,32(sp)
ffffffffc0202582:	6de2                	ld	s11,24(sp)
ffffffffc0202584:	6109                	addi	sp,sp,128
ffffffffc0202586:	8082                	ret
            if (free_pd0)
ffffffffc0202588:	ea0b8fe3          	beqz	s7,ffffffffc0202446 <exit_range+0x90>
ffffffffc020258c:	bf45                	j	ffffffffc020253c <exit_range+0x186>
ffffffffc020258e:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202590:	e42a                	sd	a0,8(sp)
ffffffffc0202592:	c22fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202596:	000db783          	ld	a5,0(s11)
ffffffffc020259a:	6522                	ld	a0,8(sp)
ffffffffc020259c:	4585                	li	a1,1
ffffffffc020259e:	739c                	ld	a5,32(a5)
ffffffffc02025a0:	9782                	jalr	a5
        intr_enable();
ffffffffc02025a2:	c0cfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02025a6:	6602                	ld	a2,0(sp)
ffffffffc02025a8:	000a8717          	auipc	a4,0xa8
ffffffffc02025ac:	1b070713          	addi	a4,a4,432 # ffffffffc02aa758 <pages>
ffffffffc02025b0:	6885                	lui	a7,0x1
ffffffffc02025b2:	00080337          	lui	t1,0x80
ffffffffc02025b6:	fff80e37          	lui	t3,0xfff80
ffffffffc02025ba:	000a8817          	auipc	a6,0xa8
ffffffffc02025be:	1ae80813          	addi	a6,a6,430 # ffffffffc02aa768 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02025c2:	0004b023          	sd	zero,0(s1)
ffffffffc02025c6:	b7a5                	j	ffffffffc020252e <exit_range+0x178>
ffffffffc02025c8:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02025ca:	beafe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02025ce:	000db783          	ld	a5,0(s11)
ffffffffc02025d2:	6502                	ld	a0,0(sp)
ffffffffc02025d4:	4585                	li	a1,1
ffffffffc02025d6:	739c                	ld	a5,32(a5)
ffffffffc02025d8:	9782                	jalr	a5
        intr_enable();
ffffffffc02025da:	bd4fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02025de:	000a8717          	auipc	a4,0xa8
ffffffffc02025e2:	17a70713          	addi	a4,a4,378 # ffffffffc02aa758 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02025e6:	00043023          	sd	zero,0(s0)
ffffffffc02025ea:	bfb5                	j	ffffffffc0202566 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02025ec:	00004697          	auipc	a3,0x4
ffffffffc02025f0:	28468693          	addi	a3,a3,644 # ffffffffc0206870 <default_pmm_manager+0x160>
ffffffffc02025f4:	00004617          	auipc	a2,0x4
ffffffffc02025f8:	d6c60613          	addi	a2,a2,-660 # ffffffffc0206360 <commands+0x868>
ffffffffc02025fc:	13600593          	li	a1,310
ffffffffc0202600:	00004517          	auipc	a0,0x4
ffffffffc0202604:	26050513          	addi	a0,a0,608 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0202608:	e87fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc020260c:	00004617          	auipc	a2,0x4
ffffffffc0202610:	13c60613          	addi	a2,a2,316 # ffffffffc0206748 <default_pmm_manager+0x38>
ffffffffc0202614:	07100593          	li	a1,113
ffffffffc0202618:	00004517          	auipc	a0,0x4
ffffffffc020261c:	15850513          	addi	a0,a0,344 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc0202620:	e6ffd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202624:	8e1ff0ef          	jal	ra,ffffffffc0201f04 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202628:	00004697          	auipc	a3,0x4
ffffffffc020262c:	27868693          	addi	a3,a3,632 # ffffffffc02068a0 <default_pmm_manager+0x190>
ffffffffc0202630:	00004617          	auipc	a2,0x4
ffffffffc0202634:	d3060613          	addi	a2,a2,-720 # ffffffffc0206360 <commands+0x868>
ffffffffc0202638:	13700593          	li	a1,311
ffffffffc020263c:	00004517          	auipc	a0,0x4
ffffffffc0202640:	22450513          	addi	a0,a0,548 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0202644:	e4bfd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202648 <page_remove>:
{
ffffffffc0202648:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020264a:	4601                	li	a2,0
{
ffffffffc020264c:	ec26                	sd	s1,24(sp)
ffffffffc020264e:	f406                	sd	ra,40(sp)
ffffffffc0202650:	f022                	sd	s0,32(sp)
ffffffffc0202652:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202654:	9a1ff0ef          	jal	ra,ffffffffc0201ff4 <get_pte>
    if (ptep != NULL)
ffffffffc0202658:	c511                	beqz	a0,ffffffffc0202664 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc020265a:	611c                	ld	a5,0(a0)
ffffffffc020265c:	842a                	mv	s0,a0
ffffffffc020265e:	0017f713          	andi	a4,a5,1
ffffffffc0202662:	e711                	bnez	a4,ffffffffc020266e <page_remove+0x26>
}
ffffffffc0202664:	70a2                	ld	ra,40(sp)
ffffffffc0202666:	7402                	ld	s0,32(sp)
ffffffffc0202668:	64e2                	ld	s1,24(sp)
ffffffffc020266a:	6145                	addi	sp,sp,48
ffffffffc020266c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020266e:	078a                	slli	a5,a5,0x2
ffffffffc0202670:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202672:	000a8717          	auipc	a4,0xa8
ffffffffc0202676:	0de73703          	ld	a4,222(a4) # ffffffffc02aa750 <npage>
ffffffffc020267a:	06e7f363          	bgeu	a5,a4,ffffffffc02026e0 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020267e:	fff80537          	lui	a0,0xfff80
ffffffffc0202682:	97aa                	add	a5,a5,a0
ffffffffc0202684:	079a                	slli	a5,a5,0x6
ffffffffc0202686:	000a8517          	auipc	a0,0xa8
ffffffffc020268a:	0d253503          	ld	a0,210(a0) # ffffffffc02aa758 <pages>
ffffffffc020268e:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202690:	411c                	lw	a5,0(a0)
ffffffffc0202692:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202696:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202698:	cb11                	beqz	a4,ffffffffc02026ac <page_remove+0x64>
        *ptep = 0;
ffffffffc020269a:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020269e:	12048073          	sfence.vma	s1
}
ffffffffc02026a2:	70a2                	ld	ra,40(sp)
ffffffffc02026a4:	7402                	ld	s0,32(sp)
ffffffffc02026a6:	64e2                	ld	s1,24(sp)
ffffffffc02026a8:	6145                	addi	sp,sp,48
ffffffffc02026aa:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02026ac:	100027f3          	csrr	a5,sstatus
ffffffffc02026b0:	8b89                	andi	a5,a5,2
ffffffffc02026b2:	eb89                	bnez	a5,ffffffffc02026c4 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02026b4:	000a8797          	auipc	a5,0xa8
ffffffffc02026b8:	0ac7b783          	ld	a5,172(a5) # ffffffffc02aa760 <pmm_manager>
ffffffffc02026bc:	739c                	ld	a5,32(a5)
ffffffffc02026be:	4585                	li	a1,1
ffffffffc02026c0:	9782                	jalr	a5
    if (flag)
ffffffffc02026c2:	bfe1                	j	ffffffffc020269a <page_remove+0x52>
        intr_disable();
ffffffffc02026c4:	e42a                	sd	a0,8(sp)
ffffffffc02026c6:	aeefe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02026ca:	000a8797          	auipc	a5,0xa8
ffffffffc02026ce:	0967b783          	ld	a5,150(a5) # ffffffffc02aa760 <pmm_manager>
ffffffffc02026d2:	739c                	ld	a5,32(a5)
ffffffffc02026d4:	6522                	ld	a0,8(sp)
ffffffffc02026d6:	4585                	li	a1,1
ffffffffc02026d8:	9782                	jalr	a5
        intr_enable();
ffffffffc02026da:	ad4fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02026de:	bf75                	j	ffffffffc020269a <page_remove+0x52>
ffffffffc02026e0:	825ff0ef          	jal	ra,ffffffffc0201f04 <pa2page.part.0>

ffffffffc02026e4 <page_insert>:
{
ffffffffc02026e4:	7139                	addi	sp,sp,-64
ffffffffc02026e6:	e852                	sd	s4,16(sp)
ffffffffc02026e8:	8a32                	mv	s4,a2
ffffffffc02026ea:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026ec:	4605                	li	a2,1
{
ffffffffc02026ee:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026f0:	85d2                	mv	a1,s4
{
ffffffffc02026f2:	f426                	sd	s1,40(sp)
ffffffffc02026f4:	fc06                	sd	ra,56(sp)
ffffffffc02026f6:	f04a                	sd	s2,32(sp)
ffffffffc02026f8:	ec4e                	sd	s3,24(sp)
ffffffffc02026fa:	e456                	sd	s5,8(sp)
ffffffffc02026fc:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026fe:	8f7ff0ef          	jal	ra,ffffffffc0201ff4 <get_pte>
    if (ptep == NULL)
ffffffffc0202702:	c961                	beqz	a0,ffffffffc02027d2 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202704:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202706:	611c                	ld	a5,0(a0)
ffffffffc0202708:	89aa                	mv	s3,a0
ffffffffc020270a:	0016871b          	addiw	a4,a3,1
ffffffffc020270e:	c018                	sw	a4,0(s0)
ffffffffc0202710:	0017f713          	andi	a4,a5,1
ffffffffc0202714:	ef05                	bnez	a4,ffffffffc020274c <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202716:	000a8717          	auipc	a4,0xa8
ffffffffc020271a:	04273703          	ld	a4,66(a4) # ffffffffc02aa758 <pages>
ffffffffc020271e:	8c19                	sub	s0,s0,a4
ffffffffc0202720:	000807b7          	lui	a5,0x80
ffffffffc0202724:	8419                	srai	s0,s0,0x6
ffffffffc0202726:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202728:	042a                	slli	s0,s0,0xa
ffffffffc020272a:	8cc1                	or	s1,s1,s0
ffffffffc020272c:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202730:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed8>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202734:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202738:	4501                	li	a0,0
}
ffffffffc020273a:	70e2                	ld	ra,56(sp)
ffffffffc020273c:	7442                	ld	s0,48(sp)
ffffffffc020273e:	74a2                	ld	s1,40(sp)
ffffffffc0202740:	7902                	ld	s2,32(sp)
ffffffffc0202742:	69e2                	ld	s3,24(sp)
ffffffffc0202744:	6a42                	ld	s4,16(sp)
ffffffffc0202746:	6aa2                	ld	s5,8(sp)
ffffffffc0202748:	6121                	addi	sp,sp,64
ffffffffc020274a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020274c:	078a                	slli	a5,a5,0x2
ffffffffc020274e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202750:	000a8717          	auipc	a4,0xa8
ffffffffc0202754:	00073703          	ld	a4,0(a4) # ffffffffc02aa750 <npage>
ffffffffc0202758:	06e7ff63          	bgeu	a5,a4,ffffffffc02027d6 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc020275c:	000a8a97          	auipc	s5,0xa8
ffffffffc0202760:	ffca8a93          	addi	s5,s5,-4 # ffffffffc02aa758 <pages>
ffffffffc0202764:	000ab703          	ld	a4,0(s5)
ffffffffc0202768:	fff80937          	lui	s2,0xfff80
ffffffffc020276c:	993e                	add	s2,s2,a5
ffffffffc020276e:	091a                	slli	s2,s2,0x6
ffffffffc0202770:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0202772:	01240c63          	beq	s0,s2,ffffffffc020278a <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202776:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcd586c>
ffffffffc020277a:	fff7869b          	addiw	a3,a5,-1
ffffffffc020277e:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc0202782:	c691                	beqz	a3,ffffffffc020278e <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202784:	120a0073          	sfence.vma	s4
}
ffffffffc0202788:	bf59                	j	ffffffffc020271e <page_insert+0x3a>
ffffffffc020278a:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020278c:	bf49                	j	ffffffffc020271e <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020278e:	100027f3          	csrr	a5,sstatus
ffffffffc0202792:	8b89                	andi	a5,a5,2
ffffffffc0202794:	ef91                	bnez	a5,ffffffffc02027b0 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202796:	000a8797          	auipc	a5,0xa8
ffffffffc020279a:	fca7b783          	ld	a5,-54(a5) # ffffffffc02aa760 <pmm_manager>
ffffffffc020279e:	739c                	ld	a5,32(a5)
ffffffffc02027a0:	4585                	li	a1,1
ffffffffc02027a2:	854a                	mv	a0,s2
ffffffffc02027a4:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02027a6:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027aa:	120a0073          	sfence.vma	s4
ffffffffc02027ae:	bf85                	j	ffffffffc020271e <page_insert+0x3a>
        intr_disable();
ffffffffc02027b0:	a04fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027b4:	000a8797          	auipc	a5,0xa8
ffffffffc02027b8:	fac7b783          	ld	a5,-84(a5) # ffffffffc02aa760 <pmm_manager>
ffffffffc02027bc:	739c                	ld	a5,32(a5)
ffffffffc02027be:	4585                	li	a1,1
ffffffffc02027c0:	854a                	mv	a0,s2
ffffffffc02027c2:	9782                	jalr	a5
        intr_enable();
ffffffffc02027c4:	9eafe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02027c8:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027cc:	120a0073          	sfence.vma	s4
ffffffffc02027d0:	b7b9                	j	ffffffffc020271e <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02027d2:	5571                	li	a0,-4
ffffffffc02027d4:	b79d                	j	ffffffffc020273a <page_insert+0x56>
ffffffffc02027d6:	f2eff0ef          	jal	ra,ffffffffc0201f04 <pa2page.part.0>

ffffffffc02027da <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02027da:	00004797          	auipc	a5,0x4
ffffffffc02027de:	f3678793          	addi	a5,a5,-202 # ffffffffc0206710 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027e2:	638c                	ld	a1,0(a5)
{
ffffffffc02027e4:	7159                	addi	sp,sp,-112
ffffffffc02027e6:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027e8:	00004517          	auipc	a0,0x4
ffffffffc02027ec:	0d050513          	addi	a0,a0,208 # ffffffffc02068b8 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc02027f0:	000a8b17          	auipc	s6,0xa8
ffffffffc02027f4:	f70b0b13          	addi	s6,s6,-144 # ffffffffc02aa760 <pmm_manager>
{
ffffffffc02027f8:	f486                	sd	ra,104(sp)
ffffffffc02027fa:	e8ca                	sd	s2,80(sp)
ffffffffc02027fc:	e4ce                	sd	s3,72(sp)
ffffffffc02027fe:	f0a2                	sd	s0,96(sp)
ffffffffc0202800:	eca6                	sd	s1,88(sp)
ffffffffc0202802:	e0d2                	sd	s4,64(sp)
ffffffffc0202804:	fc56                	sd	s5,56(sp)
ffffffffc0202806:	f45e                	sd	s7,40(sp)
ffffffffc0202808:	f062                	sd	s8,32(sp)
ffffffffc020280a:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020280c:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202810:	985fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202814:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202818:	000a8997          	auipc	s3,0xa8
ffffffffc020281c:	f5098993          	addi	s3,s3,-176 # ffffffffc02aa768 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202820:	679c                	ld	a5,8(a5)
ffffffffc0202822:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202824:	57f5                	li	a5,-3
ffffffffc0202826:	07fa                	slli	a5,a5,0x1e
ffffffffc0202828:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc020282c:	96efe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc0202830:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202832:	972fe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc0202836:	200505e3          	beqz	a0,ffffffffc0203240 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020283a:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc020283c:	00004517          	auipc	a0,0x4
ffffffffc0202840:	0b450513          	addi	a0,a0,180 # ffffffffc02068f0 <default_pmm_manager+0x1e0>
ffffffffc0202844:	951fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202848:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020284c:	fff40693          	addi	a3,s0,-1
ffffffffc0202850:	864a                	mv	a2,s2
ffffffffc0202852:	85a6                	mv	a1,s1
ffffffffc0202854:	00004517          	auipc	a0,0x4
ffffffffc0202858:	0b450513          	addi	a0,a0,180 # ffffffffc0206908 <default_pmm_manager+0x1f8>
ffffffffc020285c:	939fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202860:	c8000737          	lui	a4,0xc8000
ffffffffc0202864:	87a2                	mv	a5,s0
ffffffffc0202866:	54876163          	bltu	a4,s0,ffffffffc0202da8 <pmm_init+0x5ce>
ffffffffc020286a:	757d                	lui	a0,0xfffff
ffffffffc020286c:	000a9617          	auipc	a2,0xa9
ffffffffc0202870:	f2760613          	addi	a2,a2,-217 # ffffffffc02ab793 <end+0xfff>
ffffffffc0202874:	8e69                	and	a2,a2,a0
ffffffffc0202876:	000a8497          	auipc	s1,0xa8
ffffffffc020287a:	eda48493          	addi	s1,s1,-294 # ffffffffc02aa750 <npage>
ffffffffc020287e:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202882:	000a8b97          	auipc	s7,0xa8
ffffffffc0202886:	ed6b8b93          	addi	s7,s7,-298 # ffffffffc02aa758 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020288a:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020288c:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202890:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202894:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202896:	02f50863          	beq	a0,a5,ffffffffc02028c6 <pmm_init+0xec>
ffffffffc020289a:	4781                	li	a5,0
ffffffffc020289c:	4585                	li	a1,1
ffffffffc020289e:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02028a2:	00679513          	slli	a0,a5,0x6
ffffffffc02028a6:	9532                	add	a0,a0,a2
ffffffffc02028a8:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd54874>
ffffffffc02028ac:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02028b0:	6088                	ld	a0,0(s1)
ffffffffc02028b2:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02028b4:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02028b8:	00d50733          	add	a4,a0,a3
ffffffffc02028bc:	fee7e3e3          	bltu	a5,a4,ffffffffc02028a2 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028c0:	071a                	slli	a4,a4,0x6
ffffffffc02028c2:	00e606b3          	add	a3,a2,a4
ffffffffc02028c6:	c02007b7          	lui	a5,0xc0200
ffffffffc02028ca:	2ef6ece3          	bltu	a3,a5,ffffffffc02033c2 <pmm_init+0xbe8>
ffffffffc02028ce:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02028d2:	77fd                	lui	a5,0xfffff
ffffffffc02028d4:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028d6:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02028d8:	5086eb63          	bltu	a3,s0,ffffffffc0202dee <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02028dc:	00004517          	auipc	a0,0x4
ffffffffc02028e0:	05450513          	addi	a0,a0,84 # ffffffffc0206930 <default_pmm_manager+0x220>
ffffffffc02028e4:	8b1fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02028e8:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028ec:	000a8917          	auipc	s2,0xa8
ffffffffc02028f0:	e5c90913          	addi	s2,s2,-420 # ffffffffc02aa748 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02028f4:	7b9c                	ld	a5,48(a5)
ffffffffc02028f6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02028f8:	00004517          	auipc	a0,0x4
ffffffffc02028fc:	05050513          	addi	a0,a0,80 # ffffffffc0206948 <default_pmm_manager+0x238>
ffffffffc0202900:	895fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202904:	00007697          	auipc	a3,0x7
ffffffffc0202908:	6fc68693          	addi	a3,a3,1788 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc020290c:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202910:	c02007b7          	lui	a5,0xc0200
ffffffffc0202914:	28f6ebe3          	bltu	a3,a5,ffffffffc02033aa <pmm_init+0xbd0>
ffffffffc0202918:	0009b783          	ld	a5,0(s3)
ffffffffc020291c:	8e9d                	sub	a3,a3,a5
ffffffffc020291e:	000a8797          	auipc	a5,0xa8
ffffffffc0202922:	e2d7b123          	sd	a3,-478(a5) # ffffffffc02aa740 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202926:	100027f3          	csrr	a5,sstatus
ffffffffc020292a:	8b89                	andi	a5,a5,2
ffffffffc020292c:	4a079763          	bnez	a5,ffffffffc0202dda <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202930:	000b3783          	ld	a5,0(s6)
ffffffffc0202934:	779c                	ld	a5,40(a5)
ffffffffc0202936:	9782                	jalr	a5
ffffffffc0202938:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020293a:	6098                	ld	a4,0(s1)
ffffffffc020293c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202940:	83b1                	srli	a5,a5,0xc
ffffffffc0202942:	66e7e363          	bltu	a5,a4,ffffffffc0202fa8 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202946:	00093503          	ld	a0,0(s2)
ffffffffc020294a:	62050f63          	beqz	a0,ffffffffc0202f88 <pmm_init+0x7ae>
ffffffffc020294e:	03451793          	slli	a5,a0,0x34
ffffffffc0202952:	62079b63          	bnez	a5,ffffffffc0202f88 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202956:	4601                	li	a2,0
ffffffffc0202958:	4581                	li	a1,0
ffffffffc020295a:	8c3ff0ef          	jal	ra,ffffffffc020221c <get_page>
ffffffffc020295e:	60051563          	bnez	a0,ffffffffc0202f68 <pmm_init+0x78e>
ffffffffc0202962:	100027f3          	csrr	a5,sstatus
ffffffffc0202966:	8b89                	andi	a5,a5,2
ffffffffc0202968:	44079e63          	bnez	a5,ffffffffc0202dc4 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc020296c:	000b3783          	ld	a5,0(s6)
ffffffffc0202970:	4505                	li	a0,1
ffffffffc0202972:	6f9c                	ld	a5,24(a5)
ffffffffc0202974:	9782                	jalr	a5
ffffffffc0202976:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202978:	00093503          	ld	a0,0(s2)
ffffffffc020297c:	4681                	li	a3,0
ffffffffc020297e:	4601                	li	a2,0
ffffffffc0202980:	85d2                	mv	a1,s4
ffffffffc0202982:	d63ff0ef          	jal	ra,ffffffffc02026e4 <page_insert>
ffffffffc0202986:	26051ae3          	bnez	a0,ffffffffc02033fa <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020298a:	00093503          	ld	a0,0(s2)
ffffffffc020298e:	4601                	li	a2,0
ffffffffc0202990:	4581                	li	a1,0
ffffffffc0202992:	e62ff0ef          	jal	ra,ffffffffc0201ff4 <get_pte>
ffffffffc0202996:	240502e3          	beqz	a0,ffffffffc02033da <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc020299a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc020299c:	0017f713          	andi	a4,a5,1
ffffffffc02029a0:	5a070263          	beqz	a4,ffffffffc0202f44 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02029a4:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02029a6:	078a                	slli	a5,a5,0x2
ffffffffc02029a8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029aa:	58e7fb63          	bgeu	a5,a4,ffffffffc0202f40 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029ae:	000bb683          	ld	a3,0(s7)
ffffffffc02029b2:	fff80637          	lui	a2,0xfff80
ffffffffc02029b6:	97b2                	add	a5,a5,a2
ffffffffc02029b8:	079a                	slli	a5,a5,0x6
ffffffffc02029ba:	97b6                	add	a5,a5,a3
ffffffffc02029bc:	14fa17e3          	bne	s4,a5,ffffffffc020330a <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc02029c0:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb0>
ffffffffc02029c4:	4785                	li	a5,1
ffffffffc02029c6:	12f692e3          	bne	a3,a5,ffffffffc02032ea <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02029ca:	00093503          	ld	a0,0(s2)
ffffffffc02029ce:	77fd                	lui	a5,0xfffff
ffffffffc02029d0:	6114                	ld	a3,0(a0)
ffffffffc02029d2:	068a                	slli	a3,a3,0x2
ffffffffc02029d4:	8efd                	and	a3,a3,a5
ffffffffc02029d6:	00c6d613          	srli	a2,a3,0xc
ffffffffc02029da:	0ee67ce3          	bgeu	a2,a4,ffffffffc02032d2 <pmm_init+0xaf8>
ffffffffc02029de:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029e2:	96e2                	add	a3,a3,s8
ffffffffc02029e4:	0006ba83          	ld	s5,0(a3)
ffffffffc02029e8:	0a8a                	slli	s5,s5,0x2
ffffffffc02029ea:	00fafab3          	and	s5,s5,a5
ffffffffc02029ee:	00cad793          	srli	a5,s5,0xc
ffffffffc02029f2:	0ce7f3e3          	bgeu	a5,a4,ffffffffc02032b8 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029f6:	4601                	li	a2,0
ffffffffc02029f8:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029fa:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029fc:	df8ff0ef          	jal	ra,ffffffffc0201ff4 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a00:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a02:	55551363          	bne	a0,s5,ffffffffc0202f48 <pmm_init+0x76e>
ffffffffc0202a06:	100027f3          	csrr	a5,sstatus
ffffffffc0202a0a:	8b89                	andi	a5,a5,2
ffffffffc0202a0c:	3a079163          	bnez	a5,ffffffffc0202dae <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202a10:	000b3783          	ld	a5,0(s6)
ffffffffc0202a14:	4505                	li	a0,1
ffffffffc0202a16:	6f9c                	ld	a5,24(a5)
ffffffffc0202a18:	9782                	jalr	a5
ffffffffc0202a1a:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202a1c:	00093503          	ld	a0,0(s2)
ffffffffc0202a20:	46d1                	li	a3,20
ffffffffc0202a22:	6605                	lui	a2,0x1
ffffffffc0202a24:	85e2                	mv	a1,s8
ffffffffc0202a26:	cbfff0ef          	jal	ra,ffffffffc02026e4 <page_insert>
ffffffffc0202a2a:	060517e3          	bnez	a0,ffffffffc0203298 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a2e:	00093503          	ld	a0,0(s2)
ffffffffc0202a32:	4601                	li	a2,0
ffffffffc0202a34:	6585                	lui	a1,0x1
ffffffffc0202a36:	dbeff0ef          	jal	ra,ffffffffc0201ff4 <get_pte>
ffffffffc0202a3a:	02050fe3          	beqz	a0,ffffffffc0203278 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202a3e:	611c                	ld	a5,0(a0)
ffffffffc0202a40:	0107f713          	andi	a4,a5,16
ffffffffc0202a44:	7c070e63          	beqz	a4,ffffffffc0203220 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202a48:	8b91                	andi	a5,a5,4
ffffffffc0202a4a:	7a078b63          	beqz	a5,ffffffffc0203200 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202a4e:	00093503          	ld	a0,0(s2)
ffffffffc0202a52:	611c                	ld	a5,0(a0)
ffffffffc0202a54:	8bc1                	andi	a5,a5,16
ffffffffc0202a56:	78078563          	beqz	a5,ffffffffc02031e0 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202a5a:	000c2703          	lw	a4,0(s8)
ffffffffc0202a5e:	4785                	li	a5,1
ffffffffc0202a60:	76f71063          	bne	a4,a5,ffffffffc02031c0 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202a64:	4681                	li	a3,0
ffffffffc0202a66:	6605                	lui	a2,0x1
ffffffffc0202a68:	85d2                	mv	a1,s4
ffffffffc0202a6a:	c7bff0ef          	jal	ra,ffffffffc02026e4 <page_insert>
ffffffffc0202a6e:	72051963          	bnez	a0,ffffffffc02031a0 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202a72:	000a2703          	lw	a4,0(s4)
ffffffffc0202a76:	4789                	li	a5,2
ffffffffc0202a78:	70f71463          	bne	a4,a5,ffffffffc0203180 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202a7c:	000c2783          	lw	a5,0(s8)
ffffffffc0202a80:	6e079063          	bnez	a5,ffffffffc0203160 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a84:	00093503          	ld	a0,0(s2)
ffffffffc0202a88:	4601                	li	a2,0
ffffffffc0202a8a:	6585                	lui	a1,0x1
ffffffffc0202a8c:	d68ff0ef          	jal	ra,ffffffffc0201ff4 <get_pte>
ffffffffc0202a90:	6a050863          	beqz	a0,ffffffffc0203140 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a94:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a96:	00177793          	andi	a5,a4,1
ffffffffc0202a9a:	4a078563          	beqz	a5,ffffffffc0202f44 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202a9e:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202aa0:	00271793          	slli	a5,a4,0x2
ffffffffc0202aa4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202aa6:	48d7fd63          	bgeu	a5,a3,ffffffffc0202f40 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202aaa:	000bb683          	ld	a3,0(s7)
ffffffffc0202aae:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202ab2:	97d6                	add	a5,a5,s5
ffffffffc0202ab4:	079a                	slli	a5,a5,0x6
ffffffffc0202ab6:	97b6                	add	a5,a5,a3
ffffffffc0202ab8:	66fa1463          	bne	s4,a5,ffffffffc0203120 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202abc:	8b41                	andi	a4,a4,16
ffffffffc0202abe:	64071163          	bnez	a4,ffffffffc0203100 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202ac2:	00093503          	ld	a0,0(s2)
ffffffffc0202ac6:	4581                	li	a1,0
ffffffffc0202ac8:	b81ff0ef          	jal	ra,ffffffffc0202648 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202acc:	000a2c83          	lw	s9,0(s4)
ffffffffc0202ad0:	4785                	li	a5,1
ffffffffc0202ad2:	60fc9763          	bne	s9,a5,ffffffffc02030e0 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202ad6:	000c2783          	lw	a5,0(s8)
ffffffffc0202ada:	5e079363          	bnez	a5,ffffffffc02030c0 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202ade:	00093503          	ld	a0,0(s2)
ffffffffc0202ae2:	6585                	lui	a1,0x1
ffffffffc0202ae4:	b65ff0ef          	jal	ra,ffffffffc0202648 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202ae8:	000a2783          	lw	a5,0(s4)
ffffffffc0202aec:	52079a63          	bnez	a5,ffffffffc0203020 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202af0:	000c2783          	lw	a5,0(s8)
ffffffffc0202af4:	50079663          	bnez	a5,ffffffffc0203000 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202af8:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202afc:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202afe:	000a3683          	ld	a3,0(s4)
ffffffffc0202b02:	068a                	slli	a3,a3,0x2
ffffffffc0202b04:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b06:	42b6fd63          	bgeu	a3,a1,ffffffffc0202f40 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b0a:	000bb503          	ld	a0,0(s7)
ffffffffc0202b0e:	96d6                	add	a3,a3,s5
ffffffffc0202b10:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202b12:	00d507b3          	add	a5,a0,a3
ffffffffc0202b16:	439c                	lw	a5,0(a5)
ffffffffc0202b18:	4d979463          	bne	a5,s9,ffffffffc0202fe0 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202b1c:	8699                	srai	a3,a3,0x6
ffffffffc0202b1e:	00080637          	lui	a2,0x80
ffffffffc0202b22:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202b24:	00c69713          	slli	a4,a3,0xc
ffffffffc0202b28:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b2a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b2c:	48b77e63          	bgeu	a4,a1,ffffffffc0202fc8 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202b30:	0009b703          	ld	a4,0(s3)
ffffffffc0202b34:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b36:	629c                	ld	a5,0(a3)
ffffffffc0202b38:	078a                	slli	a5,a5,0x2
ffffffffc0202b3a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b3c:	40b7f263          	bgeu	a5,a1,ffffffffc0202f40 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b40:	8f91                	sub	a5,a5,a2
ffffffffc0202b42:	079a                	slli	a5,a5,0x6
ffffffffc0202b44:	953e                	add	a0,a0,a5
ffffffffc0202b46:	100027f3          	csrr	a5,sstatus
ffffffffc0202b4a:	8b89                	andi	a5,a5,2
ffffffffc0202b4c:	30079963          	bnez	a5,ffffffffc0202e5e <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202b50:	000b3783          	ld	a5,0(s6)
ffffffffc0202b54:	4585                	li	a1,1
ffffffffc0202b56:	739c                	ld	a5,32(a5)
ffffffffc0202b58:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b5a:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202b5e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b60:	078a                	slli	a5,a5,0x2
ffffffffc0202b62:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b64:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202f40 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b68:	000bb503          	ld	a0,0(s7)
ffffffffc0202b6c:	fff80737          	lui	a4,0xfff80
ffffffffc0202b70:	97ba                	add	a5,a5,a4
ffffffffc0202b72:	079a                	slli	a5,a5,0x6
ffffffffc0202b74:	953e                	add	a0,a0,a5
ffffffffc0202b76:	100027f3          	csrr	a5,sstatus
ffffffffc0202b7a:	8b89                	andi	a5,a5,2
ffffffffc0202b7c:	2c079563          	bnez	a5,ffffffffc0202e46 <pmm_init+0x66c>
ffffffffc0202b80:	000b3783          	ld	a5,0(s6)
ffffffffc0202b84:	4585                	li	a1,1
ffffffffc0202b86:	739c                	ld	a5,32(a5)
ffffffffc0202b88:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b8a:	00093783          	ld	a5,0(s2)
ffffffffc0202b8e:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd5486c>
    asm volatile("sfence.vma");
ffffffffc0202b92:	12000073          	sfence.vma
ffffffffc0202b96:	100027f3          	csrr	a5,sstatus
ffffffffc0202b9a:	8b89                	andi	a5,a5,2
ffffffffc0202b9c:	28079b63          	bnez	a5,ffffffffc0202e32 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ba0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ba4:	779c                	ld	a5,40(a5)
ffffffffc0202ba6:	9782                	jalr	a5
ffffffffc0202ba8:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202baa:	4b441b63          	bne	s0,s4,ffffffffc0203060 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202bae:	00004517          	auipc	a0,0x4
ffffffffc0202bb2:	0c250513          	addi	a0,a0,194 # ffffffffc0206c70 <default_pmm_manager+0x560>
ffffffffc0202bb6:	ddefd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202bba:	100027f3          	csrr	a5,sstatus
ffffffffc0202bbe:	8b89                	andi	a5,a5,2
ffffffffc0202bc0:	24079f63          	bnez	a5,ffffffffc0202e1e <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202bc4:	000b3783          	ld	a5,0(s6)
ffffffffc0202bc8:	779c                	ld	a5,40(a5)
ffffffffc0202bca:	9782                	jalr	a5
ffffffffc0202bcc:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bce:	6098                	ld	a4,0(s1)
ffffffffc0202bd0:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bd4:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bd6:	00c71793          	slli	a5,a4,0xc
ffffffffc0202bda:	6a05                	lui	s4,0x1
ffffffffc0202bdc:	02f47c63          	bgeu	s0,a5,ffffffffc0202c14 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202be0:	00c45793          	srli	a5,s0,0xc
ffffffffc0202be4:	00093503          	ld	a0,0(s2)
ffffffffc0202be8:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202ee6 <pmm_init+0x70c>
ffffffffc0202bec:	0009b583          	ld	a1,0(s3)
ffffffffc0202bf0:	4601                	li	a2,0
ffffffffc0202bf2:	95a2                	add	a1,a1,s0
ffffffffc0202bf4:	c00ff0ef          	jal	ra,ffffffffc0201ff4 <get_pte>
ffffffffc0202bf8:	32050463          	beqz	a0,ffffffffc0202f20 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bfc:	611c                	ld	a5,0(a0)
ffffffffc0202bfe:	078a                	slli	a5,a5,0x2
ffffffffc0202c00:	0157f7b3          	and	a5,a5,s5
ffffffffc0202c04:	2e879e63          	bne	a5,s0,ffffffffc0202f00 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202c08:	6098                	ld	a4,0(s1)
ffffffffc0202c0a:	9452                	add	s0,s0,s4
ffffffffc0202c0c:	00c71793          	slli	a5,a4,0xc
ffffffffc0202c10:	fcf468e3          	bltu	s0,a5,ffffffffc0202be0 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202c14:	00093783          	ld	a5,0(s2)
ffffffffc0202c18:	639c                	ld	a5,0(a5)
ffffffffc0202c1a:	42079363          	bnez	a5,ffffffffc0203040 <pmm_init+0x866>
ffffffffc0202c1e:	100027f3          	csrr	a5,sstatus
ffffffffc0202c22:	8b89                	andi	a5,a5,2
ffffffffc0202c24:	24079963          	bnez	a5,ffffffffc0202e76 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c28:	000b3783          	ld	a5,0(s6)
ffffffffc0202c2c:	4505                	li	a0,1
ffffffffc0202c2e:	6f9c                	ld	a5,24(a5)
ffffffffc0202c30:	9782                	jalr	a5
ffffffffc0202c32:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202c34:	00093503          	ld	a0,0(s2)
ffffffffc0202c38:	4699                	li	a3,6
ffffffffc0202c3a:	10000613          	li	a2,256
ffffffffc0202c3e:	85d2                	mv	a1,s4
ffffffffc0202c40:	aa5ff0ef          	jal	ra,ffffffffc02026e4 <page_insert>
ffffffffc0202c44:	44051e63          	bnez	a0,ffffffffc02030a0 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202c48:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb0>
ffffffffc0202c4c:	4785                	li	a5,1
ffffffffc0202c4e:	42f71963          	bne	a4,a5,ffffffffc0203080 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202c52:	00093503          	ld	a0,0(s2)
ffffffffc0202c56:	6405                	lui	s0,0x1
ffffffffc0202c58:	4699                	li	a3,6
ffffffffc0202c5a:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ab0>
ffffffffc0202c5e:	85d2                	mv	a1,s4
ffffffffc0202c60:	a85ff0ef          	jal	ra,ffffffffc02026e4 <page_insert>
ffffffffc0202c64:	72051363          	bnez	a0,ffffffffc020338a <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202c68:	000a2703          	lw	a4,0(s4)
ffffffffc0202c6c:	4789                	li	a5,2
ffffffffc0202c6e:	6ef71e63          	bne	a4,a5,ffffffffc020336a <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202c72:	00004597          	auipc	a1,0x4
ffffffffc0202c76:	14658593          	addi	a1,a1,326 # ffffffffc0206db8 <default_pmm_manager+0x6a8>
ffffffffc0202c7a:	10000513          	li	a0,256
ffffffffc0202c7e:	379020ef          	jal	ra,ffffffffc02057f6 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c82:	10040593          	addi	a1,s0,256
ffffffffc0202c86:	10000513          	li	a0,256
ffffffffc0202c8a:	37f020ef          	jal	ra,ffffffffc0205808 <strcmp>
ffffffffc0202c8e:	6a051e63          	bnez	a0,ffffffffc020334a <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202c92:	000bb683          	ld	a3,0(s7)
ffffffffc0202c96:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202c9a:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202c9c:	40da06b3          	sub	a3,s4,a3
ffffffffc0202ca0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202ca2:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202ca4:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202ca6:	8031                	srli	s0,s0,0xc
ffffffffc0202ca8:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202cac:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202cae:	30f77d63          	bgeu	a4,a5,ffffffffc0202fc8 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202cb2:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202cb6:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202cba:	96be                	add	a3,a3,a5
ffffffffc0202cbc:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202cc0:	301020ef          	jal	ra,ffffffffc02057c0 <strlen>
ffffffffc0202cc4:	66051363          	bnez	a0,ffffffffc020332a <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202cc8:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202ccc:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cce:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd5486c>
ffffffffc0202cd2:	068a                	slli	a3,a3,0x2
ffffffffc0202cd4:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cd6:	26f6f563          	bgeu	a3,a5,ffffffffc0202f40 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202cda:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202cdc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202cde:	2ef47563          	bgeu	s0,a5,ffffffffc0202fc8 <pmm_init+0x7ee>
ffffffffc0202ce2:	0009b403          	ld	s0,0(s3)
ffffffffc0202ce6:	9436                	add	s0,s0,a3
ffffffffc0202ce8:	100027f3          	csrr	a5,sstatus
ffffffffc0202cec:	8b89                	andi	a5,a5,2
ffffffffc0202cee:	1e079163          	bnez	a5,ffffffffc0202ed0 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202cf2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cf6:	4585                	li	a1,1
ffffffffc0202cf8:	8552                	mv	a0,s4
ffffffffc0202cfa:	739c                	ld	a5,32(a5)
ffffffffc0202cfc:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cfe:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202d00:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d02:	078a                	slli	a5,a5,0x2
ffffffffc0202d04:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d06:	22e7fd63          	bgeu	a5,a4,ffffffffc0202f40 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d0a:	000bb503          	ld	a0,0(s7)
ffffffffc0202d0e:	fff80737          	lui	a4,0xfff80
ffffffffc0202d12:	97ba                	add	a5,a5,a4
ffffffffc0202d14:	079a                	slli	a5,a5,0x6
ffffffffc0202d16:	953e                	add	a0,a0,a5
ffffffffc0202d18:	100027f3          	csrr	a5,sstatus
ffffffffc0202d1c:	8b89                	andi	a5,a5,2
ffffffffc0202d1e:	18079d63          	bnez	a5,ffffffffc0202eb8 <pmm_init+0x6de>
ffffffffc0202d22:	000b3783          	ld	a5,0(s6)
ffffffffc0202d26:	4585                	li	a1,1
ffffffffc0202d28:	739c                	ld	a5,32(a5)
ffffffffc0202d2a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d2c:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202d30:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d32:	078a                	slli	a5,a5,0x2
ffffffffc0202d34:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d36:	20e7f563          	bgeu	a5,a4,ffffffffc0202f40 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d3a:	000bb503          	ld	a0,0(s7)
ffffffffc0202d3e:	fff80737          	lui	a4,0xfff80
ffffffffc0202d42:	97ba                	add	a5,a5,a4
ffffffffc0202d44:	079a                	slli	a5,a5,0x6
ffffffffc0202d46:	953e                	add	a0,a0,a5
ffffffffc0202d48:	100027f3          	csrr	a5,sstatus
ffffffffc0202d4c:	8b89                	andi	a5,a5,2
ffffffffc0202d4e:	14079963          	bnez	a5,ffffffffc0202ea0 <pmm_init+0x6c6>
ffffffffc0202d52:	000b3783          	ld	a5,0(s6)
ffffffffc0202d56:	4585                	li	a1,1
ffffffffc0202d58:	739c                	ld	a5,32(a5)
ffffffffc0202d5a:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202d5c:	00093783          	ld	a5,0(s2)
ffffffffc0202d60:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202d64:	12000073          	sfence.vma
ffffffffc0202d68:	100027f3          	csrr	a5,sstatus
ffffffffc0202d6c:	8b89                	andi	a5,a5,2
ffffffffc0202d6e:	10079f63          	bnez	a5,ffffffffc0202e8c <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d72:	000b3783          	ld	a5,0(s6)
ffffffffc0202d76:	779c                	ld	a5,40(a5)
ffffffffc0202d78:	9782                	jalr	a5
ffffffffc0202d7a:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d7c:	4c8c1e63          	bne	s8,s0,ffffffffc0203258 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d80:	00004517          	auipc	a0,0x4
ffffffffc0202d84:	0b050513          	addi	a0,a0,176 # ffffffffc0206e30 <default_pmm_manager+0x720>
ffffffffc0202d88:	c0cfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202d8c:	7406                	ld	s0,96(sp)
ffffffffc0202d8e:	70a6                	ld	ra,104(sp)
ffffffffc0202d90:	64e6                	ld	s1,88(sp)
ffffffffc0202d92:	6946                	ld	s2,80(sp)
ffffffffc0202d94:	69a6                	ld	s3,72(sp)
ffffffffc0202d96:	6a06                	ld	s4,64(sp)
ffffffffc0202d98:	7ae2                	ld	s5,56(sp)
ffffffffc0202d9a:	7b42                	ld	s6,48(sp)
ffffffffc0202d9c:	7ba2                	ld	s7,40(sp)
ffffffffc0202d9e:	7c02                	ld	s8,32(sp)
ffffffffc0202da0:	6ce2                	ld	s9,24(sp)
ffffffffc0202da2:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202da4:	f97fe06f          	j	ffffffffc0201d3a <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202da8:	c80007b7          	lui	a5,0xc8000
ffffffffc0202dac:	bc7d                	j	ffffffffc020286a <pmm_init+0x90>
        intr_disable();
ffffffffc0202dae:	c07fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202db2:	000b3783          	ld	a5,0(s6)
ffffffffc0202db6:	4505                	li	a0,1
ffffffffc0202db8:	6f9c                	ld	a5,24(a5)
ffffffffc0202dba:	9782                	jalr	a5
ffffffffc0202dbc:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202dbe:	bf1fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dc2:	b9a9                	j	ffffffffc0202a1c <pmm_init+0x242>
        intr_disable();
ffffffffc0202dc4:	bf1fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202dc8:	000b3783          	ld	a5,0(s6)
ffffffffc0202dcc:	4505                	li	a0,1
ffffffffc0202dce:	6f9c                	ld	a5,24(a5)
ffffffffc0202dd0:	9782                	jalr	a5
ffffffffc0202dd2:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202dd4:	bdbfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dd8:	b645                	j	ffffffffc0202978 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202dda:	bdbfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202dde:	000b3783          	ld	a5,0(s6)
ffffffffc0202de2:	779c                	ld	a5,40(a5)
ffffffffc0202de4:	9782                	jalr	a5
ffffffffc0202de6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202de8:	bc7fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dec:	b6b9                	j	ffffffffc020293a <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202dee:	6705                	lui	a4,0x1
ffffffffc0202df0:	177d                	addi	a4,a4,-1
ffffffffc0202df2:	96ba                	add	a3,a3,a4
ffffffffc0202df4:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202df6:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202dfa:	14a77363          	bgeu	a4,a0,ffffffffc0202f40 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202dfe:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202e02:	fff80537          	lui	a0,0xfff80
ffffffffc0202e06:	972a                	add	a4,a4,a0
ffffffffc0202e08:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202e0a:	8c1d                	sub	s0,s0,a5
ffffffffc0202e0c:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202e10:	00c45593          	srli	a1,s0,0xc
ffffffffc0202e14:	9532                	add	a0,a0,a2
ffffffffc0202e16:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202e18:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202e1c:	b4c1                	j	ffffffffc02028dc <pmm_init+0x102>
        intr_disable();
ffffffffc0202e1e:	b97fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e22:	000b3783          	ld	a5,0(s6)
ffffffffc0202e26:	779c                	ld	a5,40(a5)
ffffffffc0202e28:	9782                	jalr	a5
ffffffffc0202e2a:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202e2c:	b83fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e30:	bb79                	j	ffffffffc0202bce <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202e32:	b83fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e36:	000b3783          	ld	a5,0(s6)
ffffffffc0202e3a:	779c                	ld	a5,40(a5)
ffffffffc0202e3c:	9782                	jalr	a5
ffffffffc0202e3e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e40:	b6ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e44:	b39d                	j	ffffffffc0202baa <pmm_init+0x3d0>
ffffffffc0202e46:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e48:	b6dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e4c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e50:	6522                	ld	a0,8(sp)
ffffffffc0202e52:	4585                	li	a1,1
ffffffffc0202e54:	739c                	ld	a5,32(a5)
ffffffffc0202e56:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e58:	b57fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e5c:	b33d                	j	ffffffffc0202b8a <pmm_init+0x3b0>
ffffffffc0202e5e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e60:	b55fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e64:	000b3783          	ld	a5,0(s6)
ffffffffc0202e68:	6522                	ld	a0,8(sp)
ffffffffc0202e6a:	4585                	li	a1,1
ffffffffc0202e6c:	739c                	ld	a5,32(a5)
ffffffffc0202e6e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e70:	b3ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e74:	b1dd                	j	ffffffffc0202b5a <pmm_init+0x380>
        intr_disable();
ffffffffc0202e76:	b3ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e7a:	000b3783          	ld	a5,0(s6)
ffffffffc0202e7e:	4505                	li	a0,1
ffffffffc0202e80:	6f9c                	ld	a5,24(a5)
ffffffffc0202e82:	9782                	jalr	a5
ffffffffc0202e84:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e86:	b29fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e8a:	b36d                	j	ffffffffc0202c34 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202e8c:	b29fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e90:	000b3783          	ld	a5,0(s6)
ffffffffc0202e94:	779c                	ld	a5,40(a5)
ffffffffc0202e96:	9782                	jalr	a5
ffffffffc0202e98:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e9a:	b15fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e9e:	bdf9                	j	ffffffffc0202d7c <pmm_init+0x5a2>
ffffffffc0202ea0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ea2:	b13fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202ea6:	000b3783          	ld	a5,0(s6)
ffffffffc0202eaa:	6522                	ld	a0,8(sp)
ffffffffc0202eac:	4585                	li	a1,1
ffffffffc0202eae:	739c                	ld	a5,32(a5)
ffffffffc0202eb0:	9782                	jalr	a5
        intr_enable();
ffffffffc0202eb2:	afdfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202eb6:	b55d                	j	ffffffffc0202d5c <pmm_init+0x582>
ffffffffc0202eb8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202eba:	afbfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202ebe:	000b3783          	ld	a5,0(s6)
ffffffffc0202ec2:	6522                	ld	a0,8(sp)
ffffffffc0202ec4:	4585                	li	a1,1
ffffffffc0202ec6:	739c                	ld	a5,32(a5)
ffffffffc0202ec8:	9782                	jalr	a5
        intr_enable();
ffffffffc0202eca:	ae5fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ece:	bdb9                	j	ffffffffc0202d2c <pmm_init+0x552>
        intr_disable();
ffffffffc0202ed0:	ae5fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202ed4:	000b3783          	ld	a5,0(s6)
ffffffffc0202ed8:	4585                	li	a1,1
ffffffffc0202eda:	8552                	mv	a0,s4
ffffffffc0202edc:	739c                	ld	a5,32(a5)
ffffffffc0202ede:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ee0:	acffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ee4:	bd29                	j	ffffffffc0202cfe <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ee6:	86a2                	mv	a3,s0
ffffffffc0202ee8:	00004617          	auipc	a2,0x4
ffffffffc0202eec:	86060613          	addi	a2,a2,-1952 # ffffffffc0206748 <default_pmm_manager+0x38>
ffffffffc0202ef0:	23d00593          	li	a1,573
ffffffffc0202ef4:	00004517          	auipc	a0,0x4
ffffffffc0202ef8:	96c50513          	addi	a0,a0,-1684 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0202efc:	d92fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202f00:	00004697          	auipc	a3,0x4
ffffffffc0202f04:	dd068693          	addi	a3,a3,-560 # ffffffffc0206cd0 <default_pmm_manager+0x5c0>
ffffffffc0202f08:	00003617          	auipc	a2,0x3
ffffffffc0202f0c:	45860613          	addi	a2,a2,1112 # ffffffffc0206360 <commands+0x868>
ffffffffc0202f10:	23e00593          	li	a1,574
ffffffffc0202f14:	00004517          	auipc	a0,0x4
ffffffffc0202f18:	94c50513          	addi	a0,a0,-1716 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0202f1c:	d72fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202f20:	00004697          	auipc	a3,0x4
ffffffffc0202f24:	d7068693          	addi	a3,a3,-656 # ffffffffc0206c90 <default_pmm_manager+0x580>
ffffffffc0202f28:	00003617          	auipc	a2,0x3
ffffffffc0202f2c:	43860613          	addi	a2,a2,1080 # ffffffffc0206360 <commands+0x868>
ffffffffc0202f30:	23d00593          	li	a1,573
ffffffffc0202f34:	00004517          	auipc	a0,0x4
ffffffffc0202f38:	92c50513          	addi	a0,a0,-1748 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0202f3c:	d52fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202f40:	fc5fe0ef          	jal	ra,ffffffffc0201f04 <pa2page.part.0>
ffffffffc0202f44:	fddfe0ef          	jal	ra,ffffffffc0201f20 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202f48:	00004697          	auipc	a3,0x4
ffffffffc0202f4c:	b4068693          	addi	a3,a3,-1216 # ffffffffc0206a88 <default_pmm_manager+0x378>
ffffffffc0202f50:	00003617          	auipc	a2,0x3
ffffffffc0202f54:	41060613          	addi	a2,a2,1040 # ffffffffc0206360 <commands+0x868>
ffffffffc0202f58:	20d00593          	li	a1,525
ffffffffc0202f5c:	00004517          	auipc	a0,0x4
ffffffffc0202f60:	90450513          	addi	a0,a0,-1788 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0202f64:	d2afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202f68:	00004697          	auipc	a3,0x4
ffffffffc0202f6c:	a6068693          	addi	a3,a3,-1440 # ffffffffc02069c8 <default_pmm_manager+0x2b8>
ffffffffc0202f70:	00003617          	auipc	a2,0x3
ffffffffc0202f74:	3f060613          	addi	a2,a2,1008 # ffffffffc0206360 <commands+0x868>
ffffffffc0202f78:	20000593          	li	a1,512
ffffffffc0202f7c:	00004517          	auipc	a0,0x4
ffffffffc0202f80:	8e450513          	addi	a0,a0,-1820 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0202f84:	d0afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f88:	00004697          	auipc	a3,0x4
ffffffffc0202f8c:	a0068693          	addi	a3,a3,-1536 # ffffffffc0206988 <default_pmm_manager+0x278>
ffffffffc0202f90:	00003617          	auipc	a2,0x3
ffffffffc0202f94:	3d060613          	addi	a2,a2,976 # ffffffffc0206360 <commands+0x868>
ffffffffc0202f98:	1ff00593          	li	a1,511
ffffffffc0202f9c:	00004517          	auipc	a0,0x4
ffffffffc0202fa0:	8c450513          	addi	a0,a0,-1852 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0202fa4:	ceafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202fa8:	00004697          	auipc	a3,0x4
ffffffffc0202fac:	9c068693          	addi	a3,a3,-1600 # ffffffffc0206968 <default_pmm_manager+0x258>
ffffffffc0202fb0:	00003617          	auipc	a2,0x3
ffffffffc0202fb4:	3b060613          	addi	a2,a2,944 # ffffffffc0206360 <commands+0x868>
ffffffffc0202fb8:	1fe00593          	li	a1,510
ffffffffc0202fbc:	00004517          	auipc	a0,0x4
ffffffffc0202fc0:	8a450513          	addi	a0,a0,-1884 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0202fc4:	ccafd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202fc8:	00003617          	auipc	a2,0x3
ffffffffc0202fcc:	78060613          	addi	a2,a2,1920 # ffffffffc0206748 <default_pmm_manager+0x38>
ffffffffc0202fd0:	07100593          	li	a1,113
ffffffffc0202fd4:	00003517          	auipc	a0,0x3
ffffffffc0202fd8:	79c50513          	addi	a0,a0,1948 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc0202fdc:	cb2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202fe0:	00004697          	auipc	a3,0x4
ffffffffc0202fe4:	c3868693          	addi	a3,a3,-968 # ffffffffc0206c18 <default_pmm_manager+0x508>
ffffffffc0202fe8:	00003617          	auipc	a2,0x3
ffffffffc0202fec:	37860613          	addi	a2,a2,888 # ffffffffc0206360 <commands+0x868>
ffffffffc0202ff0:	22600593          	li	a1,550
ffffffffc0202ff4:	00004517          	auipc	a0,0x4
ffffffffc0202ff8:	86c50513          	addi	a0,a0,-1940 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0202ffc:	c92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203000:	00004697          	auipc	a3,0x4
ffffffffc0203004:	bd068693          	addi	a3,a3,-1072 # ffffffffc0206bd0 <default_pmm_manager+0x4c0>
ffffffffc0203008:	00003617          	auipc	a2,0x3
ffffffffc020300c:	35860613          	addi	a2,a2,856 # ffffffffc0206360 <commands+0x868>
ffffffffc0203010:	22400593          	li	a1,548
ffffffffc0203014:	00004517          	auipc	a0,0x4
ffffffffc0203018:	84c50513          	addi	a0,a0,-1972 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020301c:	c72fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0203020:	00004697          	auipc	a3,0x4
ffffffffc0203024:	be068693          	addi	a3,a3,-1056 # ffffffffc0206c00 <default_pmm_manager+0x4f0>
ffffffffc0203028:	00003617          	auipc	a2,0x3
ffffffffc020302c:	33860613          	addi	a2,a2,824 # ffffffffc0206360 <commands+0x868>
ffffffffc0203030:	22300593          	li	a1,547
ffffffffc0203034:	00004517          	auipc	a0,0x4
ffffffffc0203038:	82c50513          	addi	a0,a0,-2004 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020303c:	c52fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0203040:	00004697          	auipc	a3,0x4
ffffffffc0203044:	ca868693          	addi	a3,a3,-856 # ffffffffc0206ce8 <default_pmm_manager+0x5d8>
ffffffffc0203048:	00003617          	auipc	a2,0x3
ffffffffc020304c:	31860613          	addi	a2,a2,792 # ffffffffc0206360 <commands+0x868>
ffffffffc0203050:	24100593          	li	a1,577
ffffffffc0203054:	00004517          	auipc	a0,0x4
ffffffffc0203058:	80c50513          	addi	a0,a0,-2036 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020305c:	c32fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203060:	00004697          	auipc	a3,0x4
ffffffffc0203064:	be868693          	addi	a3,a3,-1048 # ffffffffc0206c48 <default_pmm_manager+0x538>
ffffffffc0203068:	00003617          	auipc	a2,0x3
ffffffffc020306c:	2f860613          	addi	a2,a2,760 # ffffffffc0206360 <commands+0x868>
ffffffffc0203070:	22e00593          	li	a1,558
ffffffffc0203074:	00003517          	auipc	a0,0x3
ffffffffc0203078:	7ec50513          	addi	a0,a0,2028 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020307c:	c12fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203080:	00004697          	auipc	a3,0x4
ffffffffc0203084:	cc068693          	addi	a3,a3,-832 # ffffffffc0206d40 <default_pmm_manager+0x630>
ffffffffc0203088:	00003617          	auipc	a2,0x3
ffffffffc020308c:	2d860613          	addi	a2,a2,728 # ffffffffc0206360 <commands+0x868>
ffffffffc0203090:	24600593          	li	a1,582
ffffffffc0203094:	00003517          	auipc	a0,0x3
ffffffffc0203098:	7cc50513          	addi	a0,a0,1996 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020309c:	bf2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02030a0:	00004697          	auipc	a3,0x4
ffffffffc02030a4:	c6068693          	addi	a3,a3,-928 # ffffffffc0206d00 <default_pmm_manager+0x5f0>
ffffffffc02030a8:	00003617          	auipc	a2,0x3
ffffffffc02030ac:	2b860613          	addi	a2,a2,696 # ffffffffc0206360 <commands+0x868>
ffffffffc02030b0:	24500593          	li	a1,581
ffffffffc02030b4:	00003517          	auipc	a0,0x3
ffffffffc02030b8:	7ac50513          	addi	a0,a0,1964 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02030bc:	bd2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030c0:	00004697          	auipc	a3,0x4
ffffffffc02030c4:	b1068693          	addi	a3,a3,-1264 # ffffffffc0206bd0 <default_pmm_manager+0x4c0>
ffffffffc02030c8:	00003617          	auipc	a2,0x3
ffffffffc02030cc:	29860613          	addi	a2,a2,664 # ffffffffc0206360 <commands+0x868>
ffffffffc02030d0:	22000593          	li	a1,544
ffffffffc02030d4:	00003517          	auipc	a0,0x3
ffffffffc02030d8:	78c50513          	addi	a0,a0,1932 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02030dc:	bb2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02030e0:	00004697          	auipc	a3,0x4
ffffffffc02030e4:	99068693          	addi	a3,a3,-1648 # ffffffffc0206a70 <default_pmm_manager+0x360>
ffffffffc02030e8:	00003617          	auipc	a2,0x3
ffffffffc02030ec:	27860613          	addi	a2,a2,632 # ffffffffc0206360 <commands+0x868>
ffffffffc02030f0:	21f00593          	li	a1,543
ffffffffc02030f4:	00003517          	auipc	a0,0x3
ffffffffc02030f8:	76c50513          	addi	a0,a0,1900 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02030fc:	b92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203100:	00004697          	auipc	a3,0x4
ffffffffc0203104:	ae868693          	addi	a3,a3,-1304 # ffffffffc0206be8 <default_pmm_manager+0x4d8>
ffffffffc0203108:	00003617          	auipc	a2,0x3
ffffffffc020310c:	25860613          	addi	a2,a2,600 # ffffffffc0206360 <commands+0x868>
ffffffffc0203110:	21c00593          	li	a1,540
ffffffffc0203114:	00003517          	auipc	a0,0x3
ffffffffc0203118:	74c50513          	addi	a0,a0,1868 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020311c:	b72fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203120:	00004697          	auipc	a3,0x4
ffffffffc0203124:	93868693          	addi	a3,a3,-1736 # ffffffffc0206a58 <default_pmm_manager+0x348>
ffffffffc0203128:	00003617          	auipc	a2,0x3
ffffffffc020312c:	23860613          	addi	a2,a2,568 # ffffffffc0206360 <commands+0x868>
ffffffffc0203130:	21b00593          	li	a1,539
ffffffffc0203134:	00003517          	auipc	a0,0x3
ffffffffc0203138:	72c50513          	addi	a0,a0,1836 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020313c:	b52fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203140:	00004697          	auipc	a3,0x4
ffffffffc0203144:	9b868693          	addi	a3,a3,-1608 # ffffffffc0206af8 <default_pmm_manager+0x3e8>
ffffffffc0203148:	00003617          	auipc	a2,0x3
ffffffffc020314c:	21860613          	addi	a2,a2,536 # ffffffffc0206360 <commands+0x868>
ffffffffc0203150:	21a00593          	li	a1,538
ffffffffc0203154:	00003517          	auipc	a0,0x3
ffffffffc0203158:	70c50513          	addi	a0,a0,1804 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020315c:	b32fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203160:	00004697          	auipc	a3,0x4
ffffffffc0203164:	a7068693          	addi	a3,a3,-1424 # ffffffffc0206bd0 <default_pmm_manager+0x4c0>
ffffffffc0203168:	00003617          	auipc	a2,0x3
ffffffffc020316c:	1f860613          	addi	a2,a2,504 # ffffffffc0206360 <commands+0x868>
ffffffffc0203170:	21900593          	li	a1,537
ffffffffc0203174:	00003517          	auipc	a0,0x3
ffffffffc0203178:	6ec50513          	addi	a0,a0,1772 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020317c:	b12fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203180:	00004697          	auipc	a3,0x4
ffffffffc0203184:	a3868693          	addi	a3,a3,-1480 # ffffffffc0206bb8 <default_pmm_manager+0x4a8>
ffffffffc0203188:	00003617          	auipc	a2,0x3
ffffffffc020318c:	1d860613          	addi	a2,a2,472 # ffffffffc0206360 <commands+0x868>
ffffffffc0203190:	21800593          	li	a1,536
ffffffffc0203194:	00003517          	auipc	a0,0x3
ffffffffc0203198:	6cc50513          	addi	a0,a0,1740 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020319c:	af2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02031a0:	00004697          	auipc	a3,0x4
ffffffffc02031a4:	9e868693          	addi	a3,a3,-1560 # ffffffffc0206b88 <default_pmm_manager+0x478>
ffffffffc02031a8:	00003617          	auipc	a2,0x3
ffffffffc02031ac:	1b860613          	addi	a2,a2,440 # ffffffffc0206360 <commands+0x868>
ffffffffc02031b0:	21700593          	li	a1,535
ffffffffc02031b4:	00003517          	auipc	a0,0x3
ffffffffc02031b8:	6ac50513          	addi	a0,a0,1708 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02031bc:	ad2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02031c0:	00004697          	auipc	a3,0x4
ffffffffc02031c4:	9b068693          	addi	a3,a3,-1616 # ffffffffc0206b70 <default_pmm_manager+0x460>
ffffffffc02031c8:	00003617          	auipc	a2,0x3
ffffffffc02031cc:	19860613          	addi	a2,a2,408 # ffffffffc0206360 <commands+0x868>
ffffffffc02031d0:	21500593          	li	a1,533
ffffffffc02031d4:	00003517          	auipc	a0,0x3
ffffffffc02031d8:	68c50513          	addi	a0,a0,1676 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02031dc:	ab2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02031e0:	00004697          	auipc	a3,0x4
ffffffffc02031e4:	97068693          	addi	a3,a3,-1680 # ffffffffc0206b50 <default_pmm_manager+0x440>
ffffffffc02031e8:	00003617          	auipc	a2,0x3
ffffffffc02031ec:	17860613          	addi	a2,a2,376 # ffffffffc0206360 <commands+0x868>
ffffffffc02031f0:	21400593          	li	a1,532
ffffffffc02031f4:	00003517          	auipc	a0,0x3
ffffffffc02031f8:	66c50513          	addi	a0,a0,1644 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02031fc:	a92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203200:	00004697          	auipc	a3,0x4
ffffffffc0203204:	94068693          	addi	a3,a3,-1728 # ffffffffc0206b40 <default_pmm_manager+0x430>
ffffffffc0203208:	00003617          	auipc	a2,0x3
ffffffffc020320c:	15860613          	addi	a2,a2,344 # ffffffffc0206360 <commands+0x868>
ffffffffc0203210:	21300593          	li	a1,531
ffffffffc0203214:	00003517          	auipc	a0,0x3
ffffffffc0203218:	64c50513          	addi	a0,a0,1612 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020321c:	a72fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203220:	00004697          	auipc	a3,0x4
ffffffffc0203224:	91068693          	addi	a3,a3,-1776 # ffffffffc0206b30 <default_pmm_manager+0x420>
ffffffffc0203228:	00003617          	auipc	a2,0x3
ffffffffc020322c:	13860613          	addi	a2,a2,312 # ffffffffc0206360 <commands+0x868>
ffffffffc0203230:	21200593          	li	a1,530
ffffffffc0203234:	00003517          	auipc	a0,0x3
ffffffffc0203238:	62c50513          	addi	a0,a0,1580 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020323c:	a52fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc0203240:	00003617          	auipc	a2,0x3
ffffffffc0203244:	69060613          	addi	a2,a2,1680 # ffffffffc02068d0 <default_pmm_manager+0x1c0>
ffffffffc0203248:	06600593          	li	a1,102
ffffffffc020324c:	00003517          	auipc	a0,0x3
ffffffffc0203250:	61450513          	addi	a0,a0,1556 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0203254:	a3afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203258:	00004697          	auipc	a3,0x4
ffffffffc020325c:	9f068693          	addi	a3,a3,-1552 # ffffffffc0206c48 <default_pmm_manager+0x538>
ffffffffc0203260:	00003617          	auipc	a2,0x3
ffffffffc0203264:	10060613          	addi	a2,a2,256 # ffffffffc0206360 <commands+0x868>
ffffffffc0203268:	25800593          	li	a1,600
ffffffffc020326c:	00003517          	auipc	a0,0x3
ffffffffc0203270:	5f450513          	addi	a0,a0,1524 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0203274:	a1afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203278:	00004697          	auipc	a3,0x4
ffffffffc020327c:	88068693          	addi	a3,a3,-1920 # ffffffffc0206af8 <default_pmm_manager+0x3e8>
ffffffffc0203280:	00003617          	auipc	a2,0x3
ffffffffc0203284:	0e060613          	addi	a2,a2,224 # ffffffffc0206360 <commands+0x868>
ffffffffc0203288:	21100593          	li	a1,529
ffffffffc020328c:	00003517          	auipc	a0,0x3
ffffffffc0203290:	5d450513          	addi	a0,a0,1492 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0203294:	9fafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203298:	00004697          	auipc	a3,0x4
ffffffffc020329c:	82068693          	addi	a3,a3,-2016 # ffffffffc0206ab8 <default_pmm_manager+0x3a8>
ffffffffc02032a0:	00003617          	auipc	a2,0x3
ffffffffc02032a4:	0c060613          	addi	a2,a2,192 # ffffffffc0206360 <commands+0x868>
ffffffffc02032a8:	21000593          	li	a1,528
ffffffffc02032ac:	00003517          	auipc	a0,0x3
ffffffffc02032b0:	5b450513          	addi	a0,a0,1460 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02032b4:	9dafd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02032b8:	86d6                	mv	a3,s5
ffffffffc02032ba:	00003617          	auipc	a2,0x3
ffffffffc02032be:	48e60613          	addi	a2,a2,1166 # ffffffffc0206748 <default_pmm_manager+0x38>
ffffffffc02032c2:	20c00593          	li	a1,524
ffffffffc02032c6:	00003517          	auipc	a0,0x3
ffffffffc02032ca:	59a50513          	addi	a0,a0,1434 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02032ce:	9c0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02032d2:	00003617          	auipc	a2,0x3
ffffffffc02032d6:	47660613          	addi	a2,a2,1142 # ffffffffc0206748 <default_pmm_manager+0x38>
ffffffffc02032da:	20b00593          	li	a1,523
ffffffffc02032de:	00003517          	auipc	a0,0x3
ffffffffc02032e2:	58250513          	addi	a0,a0,1410 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02032e6:	9a8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02032ea:	00003697          	auipc	a3,0x3
ffffffffc02032ee:	78668693          	addi	a3,a3,1926 # ffffffffc0206a70 <default_pmm_manager+0x360>
ffffffffc02032f2:	00003617          	auipc	a2,0x3
ffffffffc02032f6:	06e60613          	addi	a2,a2,110 # ffffffffc0206360 <commands+0x868>
ffffffffc02032fa:	20900593          	li	a1,521
ffffffffc02032fe:	00003517          	auipc	a0,0x3
ffffffffc0203302:	56250513          	addi	a0,a0,1378 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0203306:	988fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020330a:	00003697          	auipc	a3,0x3
ffffffffc020330e:	74e68693          	addi	a3,a3,1870 # ffffffffc0206a58 <default_pmm_manager+0x348>
ffffffffc0203312:	00003617          	auipc	a2,0x3
ffffffffc0203316:	04e60613          	addi	a2,a2,78 # ffffffffc0206360 <commands+0x868>
ffffffffc020331a:	20800593          	li	a1,520
ffffffffc020331e:	00003517          	auipc	a0,0x3
ffffffffc0203322:	54250513          	addi	a0,a0,1346 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0203326:	968fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020332a:	00004697          	auipc	a3,0x4
ffffffffc020332e:	ade68693          	addi	a3,a3,-1314 # ffffffffc0206e08 <default_pmm_manager+0x6f8>
ffffffffc0203332:	00003617          	auipc	a2,0x3
ffffffffc0203336:	02e60613          	addi	a2,a2,46 # ffffffffc0206360 <commands+0x868>
ffffffffc020333a:	24f00593          	li	a1,591
ffffffffc020333e:	00003517          	auipc	a0,0x3
ffffffffc0203342:	52250513          	addi	a0,a0,1314 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0203346:	948fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020334a:	00004697          	auipc	a3,0x4
ffffffffc020334e:	a8668693          	addi	a3,a3,-1402 # ffffffffc0206dd0 <default_pmm_manager+0x6c0>
ffffffffc0203352:	00003617          	auipc	a2,0x3
ffffffffc0203356:	00e60613          	addi	a2,a2,14 # ffffffffc0206360 <commands+0x868>
ffffffffc020335a:	24c00593          	li	a1,588
ffffffffc020335e:	00003517          	auipc	a0,0x3
ffffffffc0203362:	50250513          	addi	a0,a0,1282 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0203366:	928fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc020336a:	00004697          	auipc	a3,0x4
ffffffffc020336e:	a3668693          	addi	a3,a3,-1482 # ffffffffc0206da0 <default_pmm_manager+0x690>
ffffffffc0203372:	00003617          	auipc	a2,0x3
ffffffffc0203376:	fee60613          	addi	a2,a2,-18 # ffffffffc0206360 <commands+0x868>
ffffffffc020337a:	24800593          	li	a1,584
ffffffffc020337e:	00003517          	auipc	a0,0x3
ffffffffc0203382:	4e250513          	addi	a0,a0,1250 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0203386:	908fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020338a:	00004697          	auipc	a3,0x4
ffffffffc020338e:	9ce68693          	addi	a3,a3,-1586 # ffffffffc0206d58 <default_pmm_manager+0x648>
ffffffffc0203392:	00003617          	auipc	a2,0x3
ffffffffc0203396:	fce60613          	addi	a2,a2,-50 # ffffffffc0206360 <commands+0x868>
ffffffffc020339a:	24700593          	li	a1,583
ffffffffc020339e:	00003517          	auipc	a0,0x3
ffffffffc02033a2:	4c250513          	addi	a0,a0,1218 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02033a6:	8e8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02033aa:	00003617          	auipc	a2,0x3
ffffffffc02033ae:	44660613          	addi	a2,a2,1094 # ffffffffc02067f0 <default_pmm_manager+0xe0>
ffffffffc02033b2:	0ca00593          	li	a1,202
ffffffffc02033b6:	00003517          	auipc	a0,0x3
ffffffffc02033ba:	4aa50513          	addi	a0,a0,1194 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02033be:	8d0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02033c2:	00003617          	auipc	a2,0x3
ffffffffc02033c6:	42e60613          	addi	a2,a2,1070 # ffffffffc02067f0 <default_pmm_manager+0xe0>
ffffffffc02033ca:	08200593          	li	a1,130
ffffffffc02033ce:	00003517          	auipc	a0,0x3
ffffffffc02033d2:	49250513          	addi	a0,a0,1170 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02033d6:	8b8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02033da:	00003697          	auipc	a3,0x3
ffffffffc02033de:	64e68693          	addi	a3,a3,1614 # ffffffffc0206a28 <default_pmm_manager+0x318>
ffffffffc02033e2:	00003617          	auipc	a2,0x3
ffffffffc02033e6:	f7e60613          	addi	a2,a2,-130 # ffffffffc0206360 <commands+0x868>
ffffffffc02033ea:	20700593          	li	a1,519
ffffffffc02033ee:	00003517          	auipc	a0,0x3
ffffffffc02033f2:	47250513          	addi	a0,a0,1138 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02033f6:	898fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02033fa:	00003697          	auipc	a3,0x3
ffffffffc02033fe:	5fe68693          	addi	a3,a3,1534 # ffffffffc02069f8 <default_pmm_manager+0x2e8>
ffffffffc0203402:	00003617          	auipc	a2,0x3
ffffffffc0203406:	f5e60613          	addi	a2,a2,-162 # ffffffffc0206360 <commands+0x868>
ffffffffc020340a:	20400593          	li	a1,516
ffffffffc020340e:	00003517          	auipc	a0,0x3
ffffffffc0203412:	45250513          	addi	a0,a0,1106 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc0203416:	878fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020341a <copy_range>:
{
ffffffffc020341a:	711d                	addi	sp,sp,-96
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020341c:	00d667b3          	or	a5,a2,a3
{
ffffffffc0203420:	ec86                	sd	ra,88(sp)
ffffffffc0203422:	e8a2                	sd	s0,80(sp)
ffffffffc0203424:	e4a6                	sd	s1,72(sp)
ffffffffc0203426:	e0ca                	sd	s2,64(sp)
ffffffffc0203428:	fc4e                	sd	s3,56(sp)
ffffffffc020342a:	f852                	sd	s4,48(sp)
ffffffffc020342c:	f456                	sd	s5,40(sp)
ffffffffc020342e:	f05a                	sd	s6,32(sp)
ffffffffc0203430:	ec5e                	sd	s7,24(sp)
ffffffffc0203432:	e862                	sd	s8,16(sp)
ffffffffc0203434:	e466                	sd	s9,8(sp)
ffffffffc0203436:	e06a                	sd	s10,0(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203438:	17d2                	slli	a5,a5,0x34
ffffffffc020343a:	14079863          	bnez	a5,ffffffffc020358a <copy_range+0x170>
    assert(USER_ACCESS(start, end));
ffffffffc020343e:	002007b7          	lui	a5,0x200
ffffffffc0203442:	8432                	mv	s0,a2
ffffffffc0203444:	10f66763          	bltu	a2,a5,ffffffffc0203552 <copy_range+0x138>
ffffffffc0203448:	8936                	mv	s2,a3
ffffffffc020344a:	10d67463          	bgeu	a2,a3,ffffffffc0203552 <copy_range+0x138>
ffffffffc020344e:	4785                	li	a5,1
ffffffffc0203450:	07fe                	slli	a5,a5,0x1f
ffffffffc0203452:	10d7e063          	bltu	a5,a3,ffffffffc0203552 <copy_range+0x138>
ffffffffc0203456:	8aaa                	mv	s5,a0
ffffffffc0203458:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc020345a:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020345c:	000a7c17          	auipc	s8,0xa7
ffffffffc0203460:	2f4c0c13          	addi	s8,s8,756 # ffffffffc02aa750 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203464:	000a7b97          	auipc	s7,0xa7
ffffffffc0203468:	2f4b8b93          	addi	s7,s7,756 # ffffffffc02aa758 <pages>
ffffffffc020346c:	fff80b37          	lui	s6,0xfff80
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203470:	00200d37          	lui	s10,0x200
ffffffffc0203474:	ffe00cb7          	lui	s9,0xffe00
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203478:	4601                	li	a2,0
ffffffffc020347a:	85a2                	mv	a1,s0
ffffffffc020347c:	854e                	mv	a0,s3
ffffffffc020347e:	b77fe0ef          	jal	ra,ffffffffc0201ff4 <get_pte>
ffffffffc0203482:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc0203484:	c559                	beqz	a0,ffffffffc0203512 <copy_range+0xf8>
        if (*ptep & PTE_V)
ffffffffc0203486:	611c                	ld	a5,0(a0)
ffffffffc0203488:	8b85                	andi	a5,a5,1
ffffffffc020348a:	e39d                	bnez	a5,ffffffffc02034b0 <copy_range+0x96>
        start += PGSIZE;
ffffffffc020348c:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020348e:	ff2465e3          	bltu	s0,s2,ffffffffc0203478 <copy_range+0x5e>
    return 0;
ffffffffc0203492:	4501                	li	a0,0
}
ffffffffc0203494:	60e6                	ld	ra,88(sp)
ffffffffc0203496:	6446                	ld	s0,80(sp)
ffffffffc0203498:	64a6                	ld	s1,72(sp)
ffffffffc020349a:	6906                	ld	s2,64(sp)
ffffffffc020349c:	79e2                	ld	s3,56(sp)
ffffffffc020349e:	7a42                	ld	s4,48(sp)
ffffffffc02034a0:	7aa2                	ld	s5,40(sp)
ffffffffc02034a2:	7b02                	ld	s6,32(sp)
ffffffffc02034a4:	6be2                	ld	s7,24(sp)
ffffffffc02034a6:	6c42                	ld	s8,16(sp)
ffffffffc02034a8:	6ca2                	ld	s9,8(sp)
ffffffffc02034aa:	6d02                	ld	s10,0(sp)
ffffffffc02034ac:	6125                	addi	sp,sp,96
ffffffffc02034ae:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02034b0:	4605                	li	a2,1
ffffffffc02034b2:	85a2                	mv	a1,s0
ffffffffc02034b4:	8556                	mv	a0,s5
ffffffffc02034b6:	b3ffe0ef          	jal	ra,ffffffffc0201ff4 <get_pte>
ffffffffc02034ba:	cd35                	beqz	a0,ffffffffc0203536 <copy_range+0x11c>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02034bc:	6098                	ld	a4,0(s1)
    if (!(pte & PTE_V))
ffffffffc02034be:	00177793          	andi	a5,a4,1
ffffffffc02034c2:	0007069b          	sext.w	a3,a4
ffffffffc02034c6:	cbb5                	beqz	a5,ffffffffc020353a <copy_range+0x120>
    if (PPN(pa) >= npage)
ffffffffc02034c8:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc02034cc:	00271793          	slli	a5,a4,0x2
ffffffffc02034d0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02034d2:	0ac7f063          	bgeu	a5,a2,ffffffffc0203572 <copy_range+0x158>
    return &pages[PPN(pa) - nbase];
ffffffffc02034d6:	000bb583          	ld	a1,0(s7)
ffffffffc02034da:	97da                	add	a5,a5,s6
ffffffffc02034dc:	079a                	slli	a5,a5,0x6
            if (perm & PTE_W)
ffffffffc02034de:	0046f613          	andi	a2,a3,4
ffffffffc02034e2:	95be                	add	a1,a1,a5
ffffffffc02034e4:	ee15                	bnez	a2,ffffffffc0203520 <copy_range+0x106>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02034e6:	8afd                	andi	a3,a3,31
            int ret = page_insert(to, page, start, perm);
ffffffffc02034e8:	8622                	mv	a2,s0
ffffffffc02034ea:	8556                	mv	a0,s5
ffffffffc02034ec:	9f8ff0ef          	jal	ra,ffffffffc02026e4 <page_insert>
            assert(ret == 0);
ffffffffc02034f0:	dd51                	beqz	a0,ffffffffc020348c <copy_range+0x72>
ffffffffc02034f2:	00004697          	auipc	a3,0x4
ffffffffc02034f6:	95e68693          	addi	a3,a3,-1698 # ffffffffc0206e50 <default_pmm_manager+0x740>
ffffffffc02034fa:	00003617          	auipc	a2,0x3
ffffffffc02034fe:	e6660613          	addi	a2,a2,-410 # ffffffffc0206360 <commands+0x868>
ffffffffc0203502:	19c00593          	li	a1,412
ffffffffc0203506:	00003517          	auipc	a0,0x3
ffffffffc020350a:	35a50513          	addi	a0,a0,858 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020350e:	f81fc0ef          	jal	ra,ffffffffc020048e <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203512:	946a                	add	s0,s0,s10
ffffffffc0203514:	01947433          	and	s0,s0,s9
    } while (start != 0 && start < end);
ffffffffc0203518:	dc2d                	beqz	s0,ffffffffc0203492 <copy_range+0x78>
ffffffffc020351a:	f5246fe3          	bltu	s0,s2,ffffffffc0203478 <copy_range+0x5e>
ffffffffc020351e:	bf95                	j	ffffffffc0203492 <copy_range+0x78>
                *ptep = (*ptep & ~PTE_W) | PTE_COW;
ffffffffc0203520:	efb77713          	andi	a4,a4,-261
ffffffffc0203524:	10076713          	ori	a4,a4,256
                perm = (perm & ~PTE_W) | PTE_COW;
ffffffffc0203528:	8aed                	andi	a3,a3,27
ffffffffc020352a:	1006e693          	ori	a3,a3,256
                *ptep = (*ptep & ~PTE_W) | PTE_COW;
ffffffffc020352e:	e098                	sd	a4,0(s1)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203530:	12040073          	sfence.vma	s0
}
ffffffffc0203534:	bf55                	j	ffffffffc02034e8 <copy_range+0xce>
                return -E_NO_MEM;
ffffffffc0203536:	5571                	li	a0,-4
ffffffffc0203538:	bfb1                	j	ffffffffc0203494 <copy_range+0x7a>
        panic("pte2page called with invalid pte");
ffffffffc020353a:	00003617          	auipc	a2,0x3
ffffffffc020353e:	2fe60613          	addi	a2,a2,766 # ffffffffc0206838 <default_pmm_manager+0x128>
ffffffffc0203542:	07f00593          	li	a1,127
ffffffffc0203546:	00003517          	auipc	a0,0x3
ffffffffc020354a:	22a50513          	addi	a0,a0,554 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc020354e:	f41fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203552:	00003697          	auipc	a3,0x3
ffffffffc0203556:	34e68693          	addi	a3,a3,846 # ffffffffc02068a0 <default_pmm_manager+0x190>
ffffffffc020355a:	00003617          	auipc	a2,0x3
ffffffffc020355e:	e0660613          	addi	a2,a2,-506 # ffffffffc0206360 <commands+0x868>
ffffffffc0203562:	17d00593          	li	a1,381
ffffffffc0203566:	00003517          	auipc	a0,0x3
ffffffffc020356a:	2fa50513          	addi	a0,a0,762 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020356e:	f21fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203572:	00003617          	auipc	a2,0x3
ffffffffc0203576:	2a660613          	addi	a2,a2,678 # ffffffffc0206818 <default_pmm_manager+0x108>
ffffffffc020357a:	06900593          	li	a1,105
ffffffffc020357e:	00003517          	auipc	a0,0x3
ffffffffc0203582:	1f250513          	addi	a0,a0,498 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc0203586:	f09fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020358a:	00003697          	auipc	a3,0x3
ffffffffc020358e:	2e668693          	addi	a3,a3,742 # ffffffffc0206870 <default_pmm_manager+0x160>
ffffffffc0203592:	00003617          	auipc	a2,0x3
ffffffffc0203596:	dce60613          	addi	a2,a2,-562 # ffffffffc0206360 <commands+0x868>
ffffffffc020359a:	17c00593          	li	a1,380
ffffffffc020359e:	00003517          	auipc	a0,0x3
ffffffffc02035a2:	2c250513          	addi	a0,a0,706 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc02035a6:	ee9fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02035aa <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02035aa:	12058073          	sfence.vma	a1
}
ffffffffc02035ae:	8082                	ret

ffffffffc02035b0 <pgdir_alloc_page>:
{
ffffffffc02035b0:	7179                	addi	sp,sp,-48
ffffffffc02035b2:	ec26                	sd	s1,24(sp)
ffffffffc02035b4:	e84a                	sd	s2,16(sp)
ffffffffc02035b6:	e052                	sd	s4,0(sp)
ffffffffc02035b8:	f406                	sd	ra,40(sp)
ffffffffc02035ba:	f022                	sd	s0,32(sp)
ffffffffc02035bc:	e44e                	sd	s3,8(sp)
ffffffffc02035be:	8a2a                	mv	s4,a0
ffffffffc02035c0:	84ae                	mv	s1,a1
ffffffffc02035c2:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02035c4:	100027f3          	csrr	a5,sstatus
ffffffffc02035c8:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02035ca:	000a7997          	auipc	s3,0xa7
ffffffffc02035ce:	19698993          	addi	s3,s3,406 # ffffffffc02aa760 <pmm_manager>
ffffffffc02035d2:	ef8d                	bnez	a5,ffffffffc020360c <pgdir_alloc_page+0x5c>
ffffffffc02035d4:	0009b783          	ld	a5,0(s3)
ffffffffc02035d8:	4505                	li	a0,1
ffffffffc02035da:	6f9c                	ld	a5,24(a5)
ffffffffc02035dc:	9782                	jalr	a5
ffffffffc02035de:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02035e0:	cc09                	beqz	s0,ffffffffc02035fa <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02035e2:	86ca                	mv	a3,s2
ffffffffc02035e4:	8626                	mv	a2,s1
ffffffffc02035e6:	85a2                	mv	a1,s0
ffffffffc02035e8:	8552                	mv	a0,s4
ffffffffc02035ea:	8faff0ef          	jal	ra,ffffffffc02026e4 <page_insert>
ffffffffc02035ee:	e915                	bnez	a0,ffffffffc0203622 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc02035f0:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc02035f2:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc02035f4:	4785                	li	a5,1
ffffffffc02035f6:	04f71e63          	bne	a4,a5,ffffffffc0203652 <pgdir_alloc_page+0xa2>
}
ffffffffc02035fa:	70a2                	ld	ra,40(sp)
ffffffffc02035fc:	8522                	mv	a0,s0
ffffffffc02035fe:	7402                	ld	s0,32(sp)
ffffffffc0203600:	64e2                	ld	s1,24(sp)
ffffffffc0203602:	6942                	ld	s2,16(sp)
ffffffffc0203604:	69a2                	ld	s3,8(sp)
ffffffffc0203606:	6a02                	ld	s4,0(sp)
ffffffffc0203608:	6145                	addi	sp,sp,48
ffffffffc020360a:	8082                	ret
        intr_disable();
ffffffffc020360c:	ba8fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203610:	0009b783          	ld	a5,0(s3)
ffffffffc0203614:	4505                	li	a0,1
ffffffffc0203616:	6f9c                	ld	a5,24(a5)
ffffffffc0203618:	9782                	jalr	a5
ffffffffc020361a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020361c:	b92fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203620:	b7c1                	j	ffffffffc02035e0 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203622:	100027f3          	csrr	a5,sstatus
ffffffffc0203626:	8b89                	andi	a5,a5,2
ffffffffc0203628:	eb89                	bnez	a5,ffffffffc020363a <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc020362a:	0009b783          	ld	a5,0(s3)
ffffffffc020362e:	8522                	mv	a0,s0
ffffffffc0203630:	4585                	li	a1,1
ffffffffc0203632:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203634:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203636:	9782                	jalr	a5
    if (flag)
ffffffffc0203638:	b7c9                	j	ffffffffc02035fa <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc020363a:	b7afd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020363e:	0009b783          	ld	a5,0(s3)
ffffffffc0203642:	8522                	mv	a0,s0
ffffffffc0203644:	4585                	li	a1,1
ffffffffc0203646:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203648:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020364a:	9782                	jalr	a5
        intr_enable();
ffffffffc020364c:	b62fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203650:	b76d                	j	ffffffffc02035fa <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203652:	00004697          	auipc	a3,0x4
ffffffffc0203656:	80e68693          	addi	a3,a3,-2034 # ffffffffc0206e60 <default_pmm_manager+0x750>
ffffffffc020365a:	00003617          	auipc	a2,0x3
ffffffffc020365e:	d0660613          	addi	a2,a2,-762 # ffffffffc0206360 <commands+0x868>
ffffffffc0203662:	1e500593          	li	a1,485
ffffffffc0203666:	00003517          	auipc	a0,0x3
ffffffffc020366a:	1fa50513          	addi	a0,a0,506 # ffffffffc0206860 <default_pmm_manager+0x150>
ffffffffc020366e:	e21fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203672 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203672:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203674:	00004697          	auipc	a3,0x4
ffffffffc0203678:	80468693          	addi	a3,a3,-2044 # ffffffffc0206e78 <default_pmm_manager+0x768>
ffffffffc020367c:	00003617          	auipc	a2,0x3
ffffffffc0203680:	ce460613          	addi	a2,a2,-796 # ffffffffc0206360 <commands+0x868>
ffffffffc0203684:	08400593          	li	a1,132
ffffffffc0203688:	00004517          	auipc	a0,0x4
ffffffffc020368c:	81050513          	addi	a0,a0,-2032 # ffffffffc0206e98 <default_pmm_manager+0x788>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203690:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203692:	dfdfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203696 <mm_create>:
{
ffffffffc0203696:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203698:	04000513          	li	a0,64
{
ffffffffc020369c:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020369e:	ec0fe0ef          	jal	ra,ffffffffc0201d5e <kmalloc>
    if (mm != NULL)
ffffffffc02036a2:	cd19                	beqz	a0,ffffffffc02036c0 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02036a4:	e508                	sd	a0,8(a0)
ffffffffc02036a6:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02036a8:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02036ac:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02036b0:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02036b4:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02036b8:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02036bc:	02053c23          	sd	zero,56(a0)
}
ffffffffc02036c0:	60a2                	ld	ra,8(sp)
ffffffffc02036c2:	0141                	addi	sp,sp,16
ffffffffc02036c4:	8082                	ret

ffffffffc02036c6 <find_vma>:
{
ffffffffc02036c6:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02036c8:	c505                	beqz	a0,ffffffffc02036f0 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02036ca:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02036cc:	c501                	beqz	a0,ffffffffc02036d4 <find_vma+0xe>
ffffffffc02036ce:	651c                	ld	a5,8(a0)
ffffffffc02036d0:	02f5f263          	bgeu	a1,a5,ffffffffc02036f4 <find_vma+0x2e>
    return listelm->next;
ffffffffc02036d4:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02036d6:	00f68d63          	beq	a3,a5,ffffffffc02036f0 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02036da:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f4ec0>
ffffffffc02036de:	00e5e663          	bltu	a1,a4,ffffffffc02036ea <find_vma+0x24>
ffffffffc02036e2:	ff07b703          	ld	a4,-16(a5)
ffffffffc02036e6:	00e5ec63          	bltu	a1,a4,ffffffffc02036fe <find_vma+0x38>
ffffffffc02036ea:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02036ec:	fef697e3          	bne	a3,a5,ffffffffc02036da <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02036f0:	4501                	li	a0,0
}
ffffffffc02036f2:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02036f4:	691c                	ld	a5,16(a0)
ffffffffc02036f6:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02036d4 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02036fa:	ea88                	sd	a0,16(a3)
ffffffffc02036fc:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02036fe:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203702:	ea88                	sd	a0,16(a3)
ffffffffc0203704:	8082                	ret

ffffffffc0203706 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203706:	6590                	ld	a2,8(a1)
ffffffffc0203708:	0105b803          	ld	a6,16(a1)
{
ffffffffc020370c:	1141                	addi	sp,sp,-16
ffffffffc020370e:	e406                	sd	ra,8(sp)
ffffffffc0203710:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203712:	01066763          	bltu	a2,a6,ffffffffc0203720 <insert_vma_struct+0x1a>
ffffffffc0203716:	a085                	j	ffffffffc0203776 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203718:	fe87b703          	ld	a4,-24(a5)
ffffffffc020371c:	04e66863          	bltu	a2,a4,ffffffffc020376c <insert_vma_struct+0x66>
ffffffffc0203720:	86be                	mv	a3,a5
ffffffffc0203722:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203724:	fef51ae3          	bne	a0,a5,ffffffffc0203718 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203728:	02a68463          	beq	a3,a0,ffffffffc0203750 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020372c:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203730:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203734:	08e8f163          	bgeu	a7,a4,ffffffffc02037b6 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203738:	04e66f63          	bltu	a2,a4,ffffffffc0203796 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc020373c:	00f50a63          	beq	a0,a5,ffffffffc0203750 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203740:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203744:	05076963          	bltu	a4,a6,ffffffffc0203796 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203748:	ff07b603          	ld	a2,-16(a5)
ffffffffc020374c:	02c77363          	bgeu	a4,a2,ffffffffc0203772 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203750:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203752:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203754:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203758:	e390                	sd	a2,0(a5)
ffffffffc020375a:	e690                	sd	a2,8(a3)
}
ffffffffc020375c:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020375e:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203760:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203762:	0017079b          	addiw	a5,a4,1
ffffffffc0203766:	d11c                	sw	a5,32(a0)
}
ffffffffc0203768:	0141                	addi	sp,sp,16
ffffffffc020376a:	8082                	ret
    if (le_prev != list)
ffffffffc020376c:	fca690e3          	bne	a3,a0,ffffffffc020372c <insert_vma_struct+0x26>
ffffffffc0203770:	bfd1                	j	ffffffffc0203744 <insert_vma_struct+0x3e>
ffffffffc0203772:	f01ff0ef          	jal	ra,ffffffffc0203672 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203776:	00003697          	auipc	a3,0x3
ffffffffc020377a:	73268693          	addi	a3,a3,1842 # ffffffffc0206ea8 <default_pmm_manager+0x798>
ffffffffc020377e:	00003617          	auipc	a2,0x3
ffffffffc0203782:	be260613          	addi	a2,a2,-1054 # ffffffffc0206360 <commands+0x868>
ffffffffc0203786:	08a00593          	li	a1,138
ffffffffc020378a:	00003517          	auipc	a0,0x3
ffffffffc020378e:	70e50513          	addi	a0,a0,1806 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203792:	cfdfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203796:	00003697          	auipc	a3,0x3
ffffffffc020379a:	75268693          	addi	a3,a3,1874 # ffffffffc0206ee8 <default_pmm_manager+0x7d8>
ffffffffc020379e:	00003617          	auipc	a2,0x3
ffffffffc02037a2:	bc260613          	addi	a2,a2,-1086 # ffffffffc0206360 <commands+0x868>
ffffffffc02037a6:	08300593          	li	a1,131
ffffffffc02037aa:	00003517          	auipc	a0,0x3
ffffffffc02037ae:	6ee50513          	addi	a0,a0,1774 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc02037b2:	cddfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02037b6:	00003697          	auipc	a3,0x3
ffffffffc02037ba:	71268693          	addi	a3,a3,1810 # ffffffffc0206ec8 <default_pmm_manager+0x7b8>
ffffffffc02037be:	00003617          	auipc	a2,0x3
ffffffffc02037c2:	ba260613          	addi	a2,a2,-1118 # ffffffffc0206360 <commands+0x868>
ffffffffc02037c6:	08200593          	li	a1,130
ffffffffc02037ca:	00003517          	auipc	a0,0x3
ffffffffc02037ce:	6ce50513          	addi	a0,a0,1742 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc02037d2:	cbdfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02037d6 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02037d6:	591c                	lw	a5,48(a0)
{
ffffffffc02037d8:	1141                	addi	sp,sp,-16
ffffffffc02037da:	e406                	sd	ra,8(sp)
ffffffffc02037dc:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02037de:	e78d                	bnez	a5,ffffffffc0203808 <mm_destroy+0x32>
ffffffffc02037e0:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02037e2:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02037e4:	00a40c63          	beq	s0,a0,ffffffffc02037fc <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02037e8:	6118                	ld	a4,0(a0)
ffffffffc02037ea:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02037ec:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02037ee:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02037f0:	e398                	sd	a4,0(a5)
ffffffffc02037f2:	e1cfe0ef          	jal	ra,ffffffffc0201e0e <kfree>
    return listelm->next;
ffffffffc02037f6:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02037f8:	fea418e3          	bne	s0,a0,ffffffffc02037e8 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02037fc:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02037fe:	6402                	ld	s0,0(sp)
ffffffffc0203800:	60a2                	ld	ra,8(sp)
ffffffffc0203802:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203804:	e0afe06f          	j	ffffffffc0201e0e <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203808:	00003697          	auipc	a3,0x3
ffffffffc020380c:	70068693          	addi	a3,a3,1792 # ffffffffc0206f08 <default_pmm_manager+0x7f8>
ffffffffc0203810:	00003617          	auipc	a2,0x3
ffffffffc0203814:	b5060613          	addi	a2,a2,-1200 # ffffffffc0206360 <commands+0x868>
ffffffffc0203818:	0ae00593          	li	a1,174
ffffffffc020381c:	00003517          	auipc	a0,0x3
ffffffffc0203820:	67c50513          	addi	a0,a0,1660 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203824:	c6bfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203828 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203828:	7139                	addi	sp,sp,-64
ffffffffc020382a:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020382c:	6405                	lui	s0,0x1
ffffffffc020382e:	147d                	addi	s0,s0,-1
ffffffffc0203830:	77fd                	lui	a5,0xfffff
ffffffffc0203832:	9622                	add	a2,a2,s0
ffffffffc0203834:	962e                	add	a2,a2,a1
{
ffffffffc0203836:	f426                	sd	s1,40(sp)
ffffffffc0203838:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020383a:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc020383e:	f04a                	sd	s2,32(sp)
ffffffffc0203840:	ec4e                	sd	s3,24(sp)
ffffffffc0203842:	e852                	sd	s4,16(sp)
ffffffffc0203844:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203846:	002005b7          	lui	a1,0x200
ffffffffc020384a:	00f67433          	and	s0,a2,a5
ffffffffc020384e:	06b4e363          	bltu	s1,a1,ffffffffc02038b4 <mm_map+0x8c>
ffffffffc0203852:	0684f163          	bgeu	s1,s0,ffffffffc02038b4 <mm_map+0x8c>
ffffffffc0203856:	4785                	li	a5,1
ffffffffc0203858:	07fe                	slli	a5,a5,0x1f
ffffffffc020385a:	0487ed63          	bltu	a5,s0,ffffffffc02038b4 <mm_map+0x8c>
ffffffffc020385e:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203860:	cd21                	beqz	a0,ffffffffc02038b8 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203862:	85a6                	mv	a1,s1
ffffffffc0203864:	8ab6                	mv	s5,a3
ffffffffc0203866:	8a3a                	mv	s4,a4
ffffffffc0203868:	e5fff0ef          	jal	ra,ffffffffc02036c6 <find_vma>
ffffffffc020386c:	c501                	beqz	a0,ffffffffc0203874 <mm_map+0x4c>
ffffffffc020386e:	651c                	ld	a5,8(a0)
ffffffffc0203870:	0487e263          	bltu	a5,s0,ffffffffc02038b4 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203874:	03000513          	li	a0,48
ffffffffc0203878:	ce6fe0ef          	jal	ra,ffffffffc0201d5e <kmalloc>
ffffffffc020387c:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc020387e:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203880:	02090163          	beqz	s2,ffffffffc02038a2 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203884:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203886:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc020388a:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc020388e:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0203892:	85ca                	mv	a1,s2
ffffffffc0203894:	e73ff0ef          	jal	ra,ffffffffc0203706 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0203898:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc020389a:	000a0463          	beqz	s4,ffffffffc02038a2 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc020389e:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb0>

out:
    return ret;
}
ffffffffc02038a2:	70e2                	ld	ra,56(sp)
ffffffffc02038a4:	7442                	ld	s0,48(sp)
ffffffffc02038a6:	74a2                	ld	s1,40(sp)
ffffffffc02038a8:	7902                	ld	s2,32(sp)
ffffffffc02038aa:	69e2                	ld	s3,24(sp)
ffffffffc02038ac:	6a42                	ld	s4,16(sp)
ffffffffc02038ae:	6aa2                	ld	s5,8(sp)
ffffffffc02038b0:	6121                	addi	sp,sp,64
ffffffffc02038b2:	8082                	ret
        return -E_INVAL;
ffffffffc02038b4:	5575                	li	a0,-3
ffffffffc02038b6:	b7f5                	j	ffffffffc02038a2 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02038b8:	00003697          	auipc	a3,0x3
ffffffffc02038bc:	66868693          	addi	a3,a3,1640 # ffffffffc0206f20 <default_pmm_manager+0x810>
ffffffffc02038c0:	00003617          	auipc	a2,0x3
ffffffffc02038c4:	aa060613          	addi	a2,a2,-1376 # ffffffffc0206360 <commands+0x868>
ffffffffc02038c8:	0c300593          	li	a1,195
ffffffffc02038cc:	00003517          	auipc	a0,0x3
ffffffffc02038d0:	5cc50513          	addi	a0,a0,1484 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc02038d4:	bbbfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038d8 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02038d8:	7139                	addi	sp,sp,-64
ffffffffc02038da:	fc06                	sd	ra,56(sp)
ffffffffc02038dc:	f822                	sd	s0,48(sp)
ffffffffc02038de:	f426                	sd	s1,40(sp)
ffffffffc02038e0:	f04a                	sd	s2,32(sp)
ffffffffc02038e2:	ec4e                	sd	s3,24(sp)
ffffffffc02038e4:	e852                	sd	s4,16(sp)
ffffffffc02038e6:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02038e8:	c52d                	beqz	a0,ffffffffc0203952 <dup_mmap+0x7a>
ffffffffc02038ea:	892a                	mv	s2,a0
ffffffffc02038ec:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02038ee:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02038f0:	e595                	bnez	a1,ffffffffc020391c <dup_mmap+0x44>
ffffffffc02038f2:	a085                	j	ffffffffc0203952 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02038f4:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc02038f6:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ee0>
        vma->vm_end = vm_end;
ffffffffc02038fa:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02038fe:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203902:	e05ff0ef          	jal	ra,ffffffffc0203706 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203906:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bc0>
ffffffffc020390a:	fe843603          	ld	a2,-24(s0)
ffffffffc020390e:	6c8c                	ld	a1,24(s1)
ffffffffc0203910:	01893503          	ld	a0,24(s2)
ffffffffc0203914:	4701                	li	a4,0
ffffffffc0203916:	b05ff0ef          	jal	ra,ffffffffc020341a <copy_range>
ffffffffc020391a:	e105                	bnez	a0,ffffffffc020393a <dup_mmap+0x62>
    return listelm->prev;
ffffffffc020391c:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc020391e:	02848863          	beq	s1,s0,ffffffffc020394e <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203922:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203926:	fe843a83          	ld	s5,-24(s0)
ffffffffc020392a:	ff043a03          	ld	s4,-16(s0)
ffffffffc020392e:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203932:	c2cfe0ef          	jal	ra,ffffffffc0201d5e <kmalloc>
ffffffffc0203936:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203938:	fd55                	bnez	a0,ffffffffc02038f4 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc020393a:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc020393c:	70e2                	ld	ra,56(sp)
ffffffffc020393e:	7442                	ld	s0,48(sp)
ffffffffc0203940:	74a2                	ld	s1,40(sp)
ffffffffc0203942:	7902                	ld	s2,32(sp)
ffffffffc0203944:	69e2                	ld	s3,24(sp)
ffffffffc0203946:	6a42                	ld	s4,16(sp)
ffffffffc0203948:	6aa2                	ld	s5,8(sp)
ffffffffc020394a:	6121                	addi	sp,sp,64
ffffffffc020394c:	8082                	ret
    return 0;
ffffffffc020394e:	4501                	li	a0,0
ffffffffc0203950:	b7f5                	j	ffffffffc020393c <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203952:	00003697          	auipc	a3,0x3
ffffffffc0203956:	5de68693          	addi	a3,a3,1502 # ffffffffc0206f30 <default_pmm_manager+0x820>
ffffffffc020395a:	00003617          	auipc	a2,0x3
ffffffffc020395e:	a0660613          	addi	a2,a2,-1530 # ffffffffc0206360 <commands+0x868>
ffffffffc0203962:	0df00593          	li	a1,223
ffffffffc0203966:	00003517          	auipc	a0,0x3
ffffffffc020396a:	53250513          	addi	a0,a0,1330 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc020396e:	b21fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203972 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203972:	1101                	addi	sp,sp,-32
ffffffffc0203974:	ec06                	sd	ra,24(sp)
ffffffffc0203976:	e822                	sd	s0,16(sp)
ffffffffc0203978:	e426                	sd	s1,8(sp)
ffffffffc020397a:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc020397c:	c531                	beqz	a0,ffffffffc02039c8 <exit_mmap+0x56>
ffffffffc020397e:	591c                	lw	a5,48(a0)
ffffffffc0203980:	84aa                	mv	s1,a0
ffffffffc0203982:	e3b9                	bnez	a5,ffffffffc02039c8 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203984:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203986:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc020398a:	02850663          	beq	a0,s0,ffffffffc02039b6 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc020398e:	ff043603          	ld	a2,-16(s0)
ffffffffc0203992:	fe843583          	ld	a1,-24(s0)
ffffffffc0203996:	854a                	mv	a0,s2
ffffffffc0203998:	8d9fe0ef          	jal	ra,ffffffffc0202270 <unmap_range>
ffffffffc020399c:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc020399e:	fe8498e3          	bne	s1,s0,ffffffffc020398e <exit_mmap+0x1c>
ffffffffc02039a2:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02039a4:	00848c63          	beq	s1,s0,ffffffffc02039bc <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02039a8:	ff043603          	ld	a2,-16(s0)
ffffffffc02039ac:	fe843583          	ld	a1,-24(s0)
ffffffffc02039b0:	854a                	mv	a0,s2
ffffffffc02039b2:	a05fe0ef          	jal	ra,ffffffffc02023b6 <exit_range>
ffffffffc02039b6:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039b8:	fe8498e3          	bne	s1,s0,ffffffffc02039a8 <exit_mmap+0x36>
    }
}
ffffffffc02039bc:	60e2                	ld	ra,24(sp)
ffffffffc02039be:	6442                	ld	s0,16(sp)
ffffffffc02039c0:	64a2                	ld	s1,8(sp)
ffffffffc02039c2:	6902                	ld	s2,0(sp)
ffffffffc02039c4:	6105                	addi	sp,sp,32
ffffffffc02039c6:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02039c8:	00003697          	auipc	a3,0x3
ffffffffc02039cc:	58868693          	addi	a3,a3,1416 # ffffffffc0206f50 <default_pmm_manager+0x840>
ffffffffc02039d0:	00003617          	auipc	a2,0x3
ffffffffc02039d4:	99060613          	addi	a2,a2,-1648 # ffffffffc0206360 <commands+0x868>
ffffffffc02039d8:	0f800593          	li	a1,248
ffffffffc02039dc:	00003517          	auipc	a0,0x3
ffffffffc02039e0:	4bc50513          	addi	a0,a0,1212 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc02039e4:	aabfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039e8 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc02039e8:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02039ea:	04000513          	li	a0,64
{
ffffffffc02039ee:	fc06                	sd	ra,56(sp)
ffffffffc02039f0:	f822                	sd	s0,48(sp)
ffffffffc02039f2:	f426                	sd	s1,40(sp)
ffffffffc02039f4:	f04a                	sd	s2,32(sp)
ffffffffc02039f6:	ec4e                	sd	s3,24(sp)
ffffffffc02039f8:	e852                	sd	s4,16(sp)
ffffffffc02039fa:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02039fc:	b62fe0ef          	jal	ra,ffffffffc0201d5e <kmalloc>
    if (mm != NULL)
ffffffffc0203a00:	2e050663          	beqz	a0,ffffffffc0203cec <vmm_init+0x304>
ffffffffc0203a04:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203a06:	e508                	sd	a0,8(a0)
ffffffffc0203a08:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203a0a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203a0e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203a12:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203a16:	02053423          	sd	zero,40(a0)
ffffffffc0203a1a:	02052823          	sw	zero,48(a0)
ffffffffc0203a1e:	02053c23          	sd	zero,56(a0)
ffffffffc0203a22:	03200413          	li	s0,50
ffffffffc0203a26:	a811                	j	ffffffffc0203a3a <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203a28:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a2a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a2c:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203a30:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a32:	8526                	mv	a0,s1
ffffffffc0203a34:	cd3ff0ef          	jal	ra,ffffffffc0203706 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203a38:	c80d                	beqz	s0,ffffffffc0203a6a <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a3a:	03000513          	li	a0,48
ffffffffc0203a3e:	b20fe0ef          	jal	ra,ffffffffc0201d5e <kmalloc>
ffffffffc0203a42:	85aa                	mv	a1,a0
ffffffffc0203a44:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203a48:	f165                	bnez	a0,ffffffffc0203a28 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203a4a:	00003697          	auipc	a3,0x3
ffffffffc0203a4e:	69e68693          	addi	a3,a3,1694 # ffffffffc02070e8 <default_pmm_manager+0x9d8>
ffffffffc0203a52:	00003617          	auipc	a2,0x3
ffffffffc0203a56:	90e60613          	addi	a2,a2,-1778 # ffffffffc0206360 <commands+0x868>
ffffffffc0203a5a:	13c00593          	li	a1,316
ffffffffc0203a5e:	00003517          	auipc	a0,0x3
ffffffffc0203a62:	43a50513          	addi	a0,a0,1082 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203a66:	a29fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203a6a:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a6e:	1f900913          	li	s2,505
ffffffffc0203a72:	a819                	j	ffffffffc0203a88 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203a74:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a76:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a78:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a7c:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a7e:	8526                	mv	a0,s1
ffffffffc0203a80:	c87ff0ef          	jal	ra,ffffffffc0203706 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a84:	03240a63          	beq	s0,s2,ffffffffc0203ab8 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a88:	03000513          	li	a0,48
ffffffffc0203a8c:	ad2fe0ef          	jal	ra,ffffffffc0201d5e <kmalloc>
ffffffffc0203a90:	85aa                	mv	a1,a0
ffffffffc0203a92:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203a96:	fd79                	bnez	a0,ffffffffc0203a74 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203a98:	00003697          	auipc	a3,0x3
ffffffffc0203a9c:	65068693          	addi	a3,a3,1616 # ffffffffc02070e8 <default_pmm_manager+0x9d8>
ffffffffc0203aa0:	00003617          	auipc	a2,0x3
ffffffffc0203aa4:	8c060613          	addi	a2,a2,-1856 # ffffffffc0206360 <commands+0x868>
ffffffffc0203aa8:	14300593          	li	a1,323
ffffffffc0203aac:	00003517          	auipc	a0,0x3
ffffffffc0203ab0:	3ec50513          	addi	a0,a0,1004 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203ab4:	9dbfc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203ab8:	649c                	ld	a5,8(s1)
ffffffffc0203aba:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203abc:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203ac0:	16f48663          	beq	s1,a5,ffffffffc0203c2c <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203ac4:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd54854>
ffffffffc0203ac8:	ffe70693          	addi	a3,a4,-2 # ffe <_binary_obj___user_faultread_out_size-0x8bb2>
ffffffffc0203acc:	10d61063          	bne	a2,a3,ffffffffc0203bcc <vmm_init+0x1e4>
ffffffffc0203ad0:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203ad4:	0ed71c63          	bne	a4,a3,ffffffffc0203bcc <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203ad8:	0715                	addi	a4,a4,5
ffffffffc0203ada:	679c                	ld	a5,8(a5)
ffffffffc0203adc:	feb712e3          	bne	a4,a1,ffffffffc0203ac0 <vmm_init+0xd8>
ffffffffc0203ae0:	4a1d                	li	s4,7
ffffffffc0203ae2:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203ae4:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203ae8:	85a2                	mv	a1,s0
ffffffffc0203aea:	8526                	mv	a0,s1
ffffffffc0203aec:	bdbff0ef          	jal	ra,ffffffffc02036c6 <find_vma>
ffffffffc0203af0:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203af2:	16050d63          	beqz	a0,ffffffffc0203c6c <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203af6:	00140593          	addi	a1,s0,1
ffffffffc0203afa:	8526                	mv	a0,s1
ffffffffc0203afc:	bcbff0ef          	jal	ra,ffffffffc02036c6 <find_vma>
ffffffffc0203b00:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b02:	14050563          	beqz	a0,ffffffffc0203c4c <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203b06:	85d2                	mv	a1,s4
ffffffffc0203b08:	8526                	mv	a0,s1
ffffffffc0203b0a:	bbdff0ef          	jal	ra,ffffffffc02036c6 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b0e:	16051f63          	bnez	a0,ffffffffc0203c8c <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203b12:	00340593          	addi	a1,s0,3
ffffffffc0203b16:	8526                	mv	a0,s1
ffffffffc0203b18:	bafff0ef          	jal	ra,ffffffffc02036c6 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b1c:	1a051863          	bnez	a0,ffffffffc0203ccc <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203b20:	00440593          	addi	a1,s0,4
ffffffffc0203b24:	8526                	mv	a0,s1
ffffffffc0203b26:	ba1ff0ef          	jal	ra,ffffffffc02036c6 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203b2a:	18051163          	bnez	a0,ffffffffc0203cac <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b2e:	00893783          	ld	a5,8(s2)
ffffffffc0203b32:	0a879d63          	bne	a5,s0,ffffffffc0203bec <vmm_init+0x204>
ffffffffc0203b36:	01093783          	ld	a5,16(s2)
ffffffffc0203b3a:	0b479963          	bne	a5,s4,ffffffffc0203bec <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b3e:	0089b783          	ld	a5,8(s3)
ffffffffc0203b42:	0c879563          	bne	a5,s0,ffffffffc0203c0c <vmm_init+0x224>
ffffffffc0203b46:	0109b783          	ld	a5,16(s3)
ffffffffc0203b4a:	0d479163          	bne	a5,s4,ffffffffc0203c0c <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b4e:	0415                	addi	s0,s0,5
ffffffffc0203b50:	0a15                	addi	s4,s4,5
ffffffffc0203b52:	f9541be3          	bne	s0,s5,ffffffffc0203ae8 <vmm_init+0x100>
ffffffffc0203b56:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203b58:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203b5a:	85a2                	mv	a1,s0
ffffffffc0203b5c:	8526                	mv	a0,s1
ffffffffc0203b5e:	b69ff0ef          	jal	ra,ffffffffc02036c6 <find_vma>
ffffffffc0203b62:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203b66:	c90d                	beqz	a0,ffffffffc0203b98 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203b68:	6914                	ld	a3,16(a0)
ffffffffc0203b6a:	6510                	ld	a2,8(a0)
ffffffffc0203b6c:	00003517          	auipc	a0,0x3
ffffffffc0203b70:	50450513          	addi	a0,a0,1284 # ffffffffc0207070 <default_pmm_manager+0x960>
ffffffffc0203b74:	e20fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203b78:	00003697          	auipc	a3,0x3
ffffffffc0203b7c:	52068693          	addi	a3,a3,1312 # ffffffffc0207098 <default_pmm_manager+0x988>
ffffffffc0203b80:	00002617          	auipc	a2,0x2
ffffffffc0203b84:	7e060613          	addi	a2,a2,2016 # ffffffffc0206360 <commands+0x868>
ffffffffc0203b88:	16900593          	li	a1,361
ffffffffc0203b8c:	00003517          	auipc	a0,0x3
ffffffffc0203b90:	30c50513          	addi	a0,a0,780 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203b94:	8fbfc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203b98:	147d                	addi	s0,s0,-1
ffffffffc0203b9a:	fd2410e3          	bne	s0,s2,ffffffffc0203b5a <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203b9e:	8526                	mv	a0,s1
ffffffffc0203ba0:	c37ff0ef          	jal	ra,ffffffffc02037d6 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203ba4:	00003517          	auipc	a0,0x3
ffffffffc0203ba8:	50c50513          	addi	a0,a0,1292 # ffffffffc02070b0 <default_pmm_manager+0x9a0>
ffffffffc0203bac:	de8fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203bb0:	7442                	ld	s0,48(sp)
ffffffffc0203bb2:	70e2                	ld	ra,56(sp)
ffffffffc0203bb4:	74a2                	ld	s1,40(sp)
ffffffffc0203bb6:	7902                	ld	s2,32(sp)
ffffffffc0203bb8:	69e2                	ld	s3,24(sp)
ffffffffc0203bba:	6a42                	ld	s4,16(sp)
ffffffffc0203bbc:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bbe:	00003517          	auipc	a0,0x3
ffffffffc0203bc2:	51250513          	addi	a0,a0,1298 # ffffffffc02070d0 <default_pmm_manager+0x9c0>
}
ffffffffc0203bc6:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bc8:	dccfc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203bcc:	00003697          	auipc	a3,0x3
ffffffffc0203bd0:	3bc68693          	addi	a3,a3,956 # ffffffffc0206f88 <default_pmm_manager+0x878>
ffffffffc0203bd4:	00002617          	auipc	a2,0x2
ffffffffc0203bd8:	78c60613          	addi	a2,a2,1932 # ffffffffc0206360 <commands+0x868>
ffffffffc0203bdc:	14d00593          	li	a1,333
ffffffffc0203be0:	00003517          	auipc	a0,0x3
ffffffffc0203be4:	2b850513          	addi	a0,a0,696 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203be8:	8a7fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203bec:	00003697          	auipc	a3,0x3
ffffffffc0203bf0:	42468693          	addi	a3,a3,1060 # ffffffffc0207010 <default_pmm_manager+0x900>
ffffffffc0203bf4:	00002617          	auipc	a2,0x2
ffffffffc0203bf8:	76c60613          	addi	a2,a2,1900 # ffffffffc0206360 <commands+0x868>
ffffffffc0203bfc:	15e00593          	li	a1,350
ffffffffc0203c00:	00003517          	auipc	a0,0x3
ffffffffc0203c04:	29850513          	addi	a0,a0,664 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203c08:	887fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c0c:	00003697          	auipc	a3,0x3
ffffffffc0203c10:	43468693          	addi	a3,a3,1076 # ffffffffc0207040 <default_pmm_manager+0x930>
ffffffffc0203c14:	00002617          	auipc	a2,0x2
ffffffffc0203c18:	74c60613          	addi	a2,a2,1868 # ffffffffc0206360 <commands+0x868>
ffffffffc0203c1c:	15f00593          	li	a1,351
ffffffffc0203c20:	00003517          	auipc	a0,0x3
ffffffffc0203c24:	27850513          	addi	a0,a0,632 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203c28:	867fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203c2c:	00003697          	auipc	a3,0x3
ffffffffc0203c30:	34468693          	addi	a3,a3,836 # ffffffffc0206f70 <default_pmm_manager+0x860>
ffffffffc0203c34:	00002617          	auipc	a2,0x2
ffffffffc0203c38:	72c60613          	addi	a2,a2,1836 # ffffffffc0206360 <commands+0x868>
ffffffffc0203c3c:	14b00593          	li	a1,331
ffffffffc0203c40:	00003517          	auipc	a0,0x3
ffffffffc0203c44:	25850513          	addi	a0,a0,600 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203c48:	847fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203c4c:	00003697          	auipc	a3,0x3
ffffffffc0203c50:	38468693          	addi	a3,a3,900 # ffffffffc0206fd0 <default_pmm_manager+0x8c0>
ffffffffc0203c54:	00002617          	auipc	a2,0x2
ffffffffc0203c58:	70c60613          	addi	a2,a2,1804 # ffffffffc0206360 <commands+0x868>
ffffffffc0203c5c:	15600593          	li	a1,342
ffffffffc0203c60:	00003517          	auipc	a0,0x3
ffffffffc0203c64:	23850513          	addi	a0,a0,568 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203c68:	827fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203c6c:	00003697          	auipc	a3,0x3
ffffffffc0203c70:	35468693          	addi	a3,a3,852 # ffffffffc0206fc0 <default_pmm_manager+0x8b0>
ffffffffc0203c74:	00002617          	auipc	a2,0x2
ffffffffc0203c78:	6ec60613          	addi	a2,a2,1772 # ffffffffc0206360 <commands+0x868>
ffffffffc0203c7c:	15400593          	li	a1,340
ffffffffc0203c80:	00003517          	auipc	a0,0x3
ffffffffc0203c84:	21850513          	addi	a0,a0,536 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203c88:	807fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203c8c:	00003697          	auipc	a3,0x3
ffffffffc0203c90:	35468693          	addi	a3,a3,852 # ffffffffc0206fe0 <default_pmm_manager+0x8d0>
ffffffffc0203c94:	00002617          	auipc	a2,0x2
ffffffffc0203c98:	6cc60613          	addi	a2,a2,1740 # ffffffffc0206360 <commands+0x868>
ffffffffc0203c9c:	15800593          	li	a1,344
ffffffffc0203ca0:	00003517          	auipc	a0,0x3
ffffffffc0203ca4:	1f850513          	addi	a0,a0,504 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203ca8:	fe6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203cac:	00003697          	auipc	a3,0x3
ffffffffc0203cb0:	35468693          	addi	a3,a3,852 # ffffffffc0207000 <default_pmm_manager+0x8f0>
ffffffffc0203cb4:	00002617          	auipc	a2,0x2
ffffffffc0203cb8:	6ac60613          	addi	a2,a2,1708 # ffffffffc0206360 <commands+0x868>
ffffffffc0203cbc:	15c00593          	li	a1,348
ffffffffc0203cc0:	00003517          	auipc	a0,0x3
ffffffffc0203cc4:	1d850513          	addi	a0,a0,472 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203cc8:	fc6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203ccc:	00003697          	auipc	a3,0x3
ffffffffc0203cd0:	32468693          	addi	a3,a3,804 # ffffffffc0206ff0 <default_pmm_manager+0x8e0>
ffffffffc0203cd4:	00002617          	auipc	a2,0x2
ffffffffc0203cd8:	68c60613          	addi	a2,a2,1676 # ffffffffc0206360 <commands+0x868>
ffffffffc0203cdc:	15a00593          	li	a1,346
ffffffffc0203ce0:	00003517          	auipc	a0,0x3
ffffffffc0203ce4:	1b850513          	addi	a0,a0,440 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203ce8:	fa6fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203cec:	00003697          	auipc	a3,0x3
ffffffffc0203cf0:	23468693          	addi	a3,a3,564 # ffffffffc0206f20 <default_pmm_manager+0x810>
ffffffffc0203cf4:	00002617          	auipc	a2,0x2
ffffffffc0203cf8:	66c60613          	addi	a2,a2,1644 # ffffffffc0206360 <commands+0x868>
ffffffffc0203cfc:	13400593          	li	a1,308
ffffffffc0203d00:	00003517          	auipc	a0,0x3
ffffffffc0203d04:	19850513          	addi	a0,a0,408 # ffffffffc0206e98 <default_pmm_manager+0x788>
ffffffffc0203d08:	f86fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203d0c <do_pgfault>:
}

// do_pgfault - 处理缺页，包括：未映射时的按需分配，以及写访问触发的 COW 写时复制
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
    pgfault_num++;
ffffffffc0203d0c:	000a7797          	auipc	a5,0xa7
ffffffffc0203d10:	a647a783          	lw	a5,-1436(a5) # ffffffffc02aa770 <pgfault_num>
ffffffffc0203d14:	2785                	addiw	a5,a5,1
ffffffffc0203d16:	000a7717          	auipc	a4,0xa7
ffffffffc0203d1a:	a4f72d23          	sw	a5,-1446(a4) # ffffffffc02aa770 <pgfault_num>

    if (mm == NULL)
ffffffffc0203d1e:	16050663          	beqz	a0,ffffffffc0203e8a <do_pgfault+0x17e>
{
ffffffffc0203d22:	715d                	addi	sp,sp,-80
ffffffffc0203d24:	f44e                	sd	s3,40(sp)
ffffffffc0203d26:	89ae                	mv	s3,a1
    {
        return -E_INVAL;
    }

    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203d28:	85b2                	mv	a1,a2
{
ffffffffc0203d2a:	e0a2                	sd	s0,64(sp)
ffffffffc0203d2c:	fc26                	sd	s1,56(sp)
ffffffffc0203d2e:	f84a                	sd	s2,48(sp)
ffffffffc0203d30:	e486                	sd	ra,72(sp)
ffffffffc0203d32:	f052                	sd	s4,32(sp)
ffffffffc0203d34:	ec56                	sd	s5,24(sp)
ffffffffc0203d36:	e85a                	sd	s6,16(sp)
ffffffffc0203d38:	e45e                	sd	s7,8(sp)
ffffffffc0203d3a:	84aa                	mv	s1,a0
ffffffffc0203d3c:	8432                	mv	s0,a2
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203d3e:	989ff0ef          	jal	ra,ffffffffc02036c6 <find_vma>
ffffffffc0203d42:	892a                	mv	s2,a0
    if (vma == NULL || addr < vma->vm_start)
ffffffffc0203d44:	12050f63          	beqz	a0,ffffffffc0203e82 <do_pgfault+0x176>
ffffffffc0203d48:	651c                	ld	a5,8(a0)
ffffffffc0203d4a:	12f46c63          	bltu	s0,a5,ffffffffc0203e82 <do_pgfault+0x176>
    {
        return -E_INVAL;
    }

    bool write = (error_code & 0x2) != 0;
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203d4e:	75fd                	lui	a1,0xfffff
    pte_t *ptep = get_pte(mm->pgdir, la, 0);
ffffffffc0203d50:	6c88                	ld	a0,24(s1)
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203d52:	8c6d                	and	s0,s0,a1
    pte_t *ptep = get_pte(mm->pgdir, la, 0);
ffffffffc0203d54:	4601                	li	a2,0
ffffffffc0203d56:	85a2                	mv	a1,s0
ffffffffc0203d58:	a9cfe0ef          	jal	ra,ffffffffc0201ff4 <get_pte>
ffffffffc0203d5c:	87aa                	mv	a5,a0

    if (ptep == NULL || !(*ptep & PTE_V))
ffffffffc0203d5e:	c569                	beqz	a0,ffffffffc0203e28 <do_pgfault+0x11c>
ffffffffc0203d60:	00053a03          	ld	s4,0(a0)
ffffffffc0203d64:	001a7713          	andi	a4,s4,1
ffffffffc0203d68:	c361                	beqz	a4,ffffffffc0203e28 <do_pgfault+0x11c>
        }
        return 0;
    }

    // 写访问命中 COW：复制或直接去掉 COW 置可写
    if (write && (*ptep & PTE_COW))
ffffffffc0203d6a:	0029f593          	andi	a1,s3,2
ffffffffc0203d6e:	10058a63          	beqz	a1,ffffffffc0203e82 <do_pgfault+0x176>
ffffffffc0203d72:	100a7713          	andi	a4,s4,256
ffffffffc0203d76:	10070663          	beqz	a4,ffffffffc0203e82 <do_pgfault+0x176>
    if (PPN(pa) >= npage)
ffffffffc0203d7a:	000a7b17          	auipc	s6,0xa7
ffffffffc0203d7e:	9d6b0b13          	addi	s6,s6,-1578 # ffffffffc02aa750 <npage>
ffffffffc0203d82:	000b3683          	ld	a3,0(s6)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203d86:	002a1713          	slli	a4,s4,0x2
ffffffffc0203d8a:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0203d8c:	10d77163          	bgeu	a4,a3,ffffffffc0203e8e <do_pgfault+0x182>
    return &pages[PPN(pa) - nbase];
ffffffffc0203d90:	000a7b97          	auipc	s7,0xa7
ffffffffc0203d94:	9c8b8b93          	addi	s7,s7,-1592 # ffffffffc02aa758 <pages>
ffffffffc0203d98:	000bb903          	ld	s2,0(s7)
ffffffffc0203d9c:	00004a97          	auipc	s5,0x4
ffffffffc0203da0:	c5caba83          	ld	s5,-932(s5) # ffffffffc02079f8 <nbase>
ffffffffc0203da4:	41570733          	sub	a4,a4,s5
ffffffffc0203da8:	071a                	slli	a4,a4,0x6
ffffffffc0203daa:	993a                	add	s2,s2,a4
    {
        uint32_t perm = (*ptep & PTE_USER);
        struct Page *page = pte2page(*ptep);

        if (page_ref(page) > 1)
ffffffffc0203dac:	00092683          	lw	a3,0(s2)
ffffffffc0203db0:	4705                	li	a4,1
ffffffffc0203db2:	0ad75d63          	bge	a4,a3,ffffffffc0203e6c <do_pgfault+0x160>
        {
            struct Page *npage = alloc_page();
ffffffffc0203db6:	4505                	li	a0,1
ffffffffc0203db8:	984fe0ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc0203dbc:	89aa                	mv	s3,a0
            if (npage == NULL)
ffffffffc0203dbe:	c561                	beqz	a0,ffffffffc0203e86 <do_pgfault+0x17a>
    return page - pages + nbase;
ffffffffc0203dc0:	000bb683          	ld	a3,0(s7)
    return KADDR(page2pa(page));
ffffffffc0203dc4:	577d                	li	a4,-1
ffffffffc0203dc6:	000b3603          	ld	a2,0(s6)
    return page - pages + nbase;
ffffffffc0203dca:	40d507b3          	sub	a5,a0,a3
ffffffffc0203dce:	8799                	srai	a5,a5,0x6
ffffffffc0203dd0:	97d6                	add	a5,a5,s5
    return KADDR(page2pa(page));
ffffffffc0203dd2:	8331                	srli	a4,a4,0xc
ffffffffc0203dd4:	00e7f5b3          	and	a1,a5,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0203dd8:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203dda:	0cc5f663          	bgeu	a1,a2,ffffffffc0203ea6 <do_pgfault+0x19a>
    return page - pages + nbase;
ffffffffc0203dde:	40d906b3          	sub	a3,s2,a3
ffffffffc0203de2:	8699                	srai	a3,a3,0x6
ffffffffc0203de4:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc0203de6:	000a7597          	auipc	a1,0xa7
ffffffffc0203dea:	9825b583          	ld	a1,-1662(a1) # ffffffffc02aa768 <va_pa_offset>
ffffffffc0203dee:	8f75                	and	a4,a4,a3
ffffffffc0203df0:	00b78533          	add	a0,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0203df4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203df6:	0cc77563          	bgeu	a4,a2,ffffffffc0203ec0 <do_pgfault+0x1b4>
            {
                return -E_NO_MEM;
            }
            memcpy(page2kva(npage), page2kva(page), PGSIZE);
ffffffffc0203dfa:	95b6                	add	a1,a1,a3
ffffffffc0203dfc:	6605                	lui	a2,0x1
ffffffffc0203dfe:	277010ef          	jal	ra,ffffffffc0205874 <memcpy>
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203e02:	8622                	mv	a2,s0
        }
    }

    // 其他类型缺页未在此处理
    return -E_INVAL;
}
ffffffffc0203e04:	6406                	ld	s0,64(sp)
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203e06:	6c88                	ld	a0,24(s1)
}
ffffffffc0203e08:	60a6                	ld	ra,72(sp)
ffffffffc0203e0a:	74e2                	ld	s1,56(sp)
ffffffffc0203e0c:	7942                	ld	s2,48(sp)
ffffffffc0203e0e:	6ae2                	ld	s5,24(sp)
ffffffffc0203e10:	6b42                	ld	s6,16(sp)
ffffffffc0203e12:	6ba2                	ld	s7,8(sp)
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203e14:	01ba7693          	andi	a3,s4,27
ffffffffc0203e18:	85ce                	mv	a1,s3
}
ffffffffc0203e1a:	7a02                	ld	s4,32(sp)
ffffffffc0203e1c:	79a2                	ld	s3,40(sp)
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203e1e:	0046e693          	ori	a3,a3,4
}
ffffffffc0203e22:	6161                	addi	sp,sp,80
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203e24:	8c1fe06f          	j	ffffffffc02026e4 <page_insert>
        uint32_t perm = perm_from_flags(vma->vm_flags);
ffffffffc0203e28:	01892783          	lw	a5,24(s2)
    uint32_t perm = PTE_U;
ffffffffc0203e2c:	4641                	li	a2,16
    if (vm_flags & VM_READ)
ffffffffc0203e2e:	0017f713          	andi	a4,a5,1
ffffffffc0203e32:	c311                	beqz	a4,ffffffffc0203e36 <do_pgfault+0x12a>
        perm |= PTE_R;
ffffffffc0203e34:	4649                	li	a2,18
    if (vm_flags & VM_WRITE)
ffffffffc0203e36:	0027f713          	andi	a4,a5,2
ffffffffc0203e3a:	c311                	beqz	a4,ffffffffc0203e3e <do_pgfault+0x132>
        perm |= PTE_W | PTE_R;
ffffffffc0203e3c:	4659                	li	a2,22
    if (vm_flags & VM_EXEC)
ffffffffc0203e3e:	8b91                	andi	a5,a5,4
ffffffffc0203e40:	e39d                	bnez	a5,ffffffffc0203e66 <do_pgfault+0x15a>
        if (pgdir_alloc_page(mm->pgdir, la, perm) == NULL)
ffffffffc0203e42:	6c88                	ld	a0,24(s1)
ffffffffc0203e44:	85a2                	mv	a1,s0
ffffffffc0203e46:	f6aff0ef          	jal	ra,ffffffffc02035b0 <pgdir_alloc_page>
ffffffffc0203e4a:	87aa                	mv	a5,a0
        return 0;
ffffffffc0203e4c:	4501                	li	a0,0
        if (pgdir_alloc_page(mm->pgdir, la, perm) == NULL)
ffffffffc0203e4e:	cf85                	beqz	a5,ffffffffc0203e86 <do_pgfault+0x17a>
}
ffffffffc0203e50:	60a6                	ld	ra,72(sp)
ffffffffc0203e52:	6406                	ld	s0,64(sp)
ffffffffc0203e54:	74e2                	ld	s1,56(sp)
ffffffffc0203e56:	7942                	ld	s2,48(sp)
ffffffffc0203e58:	79a2                	ld	s3,40(sp)
ffffffffc0203e5a:	7a02                	ld	s4,32(sp)
ffffffffc0203e5c:	6ae2                	ld	s5,24(sp)
ffffffffc0203e5e:	6b42                	ld	s6,16(sp)
ffffffffc0203e60:	6ba2                	ld	s7,8(sp)
ffffffffc0203e62:	6161                	addi	sp,sp,80
ffffffffc0203e64:	8082                	ret
        perm |= PTE_X;
ffffffffc0203e66:	00866613          	ori	a2,a2,8
ffffffffc0203e6a:	bfe1                	j	ffffffffc0203e42 <do_pgfault+0x136>
            tlb_invalidate(mm->pgdir, la);
ffffffffc0203e6c:	6c88                	ld	a0,24(s1)
            *ptep = (*ptep | PTE_W) & ~PTE_COW;
ffffffffc0203e6e:	efba7713          	andi	a4,s4,-261
ffffffffc0203e72:	00476713          	ori	a4,a4,4
ffffffffc0203e76:	e398                	sd	a4,0(a5)
            tlb_invalidate(mm->pgdir, la);
ffffffffc0203e78:	85a2                	mv	a1,s0
ffffffffc0203e7a:	f30ff0ef          	jal	ra,ffffffffc02035aa <tlb_invalidate>
            return 0;
ffffffffc0203e7e:	4501                	li	a0,0
ffffffffc0203e80:	bfc1                	j	ffffffffc0203e50 <do_pgfault+0x144>
        return -E_INVAL;
ffffffffc0203e82:	5575                	li	a0,-3
ffffffffc0203e84:	b7f1                	j	ffffffffc0203e50 <do_pgfault+0x144>
            return -E_NO_MEM;
ffffffffc0203e86:	5571                	li	a0,-4
ffffffffc0203e88:	b7e1                	j	ffffffffc0203e50 <do_pgfault+0x144>
        return -E_INVAL;
ffffffffc0203e8a:	5575                	li	a0,-3
}
ffffffffc0203e8c:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0203e8e:	00003617          	auipc	a2,0x3
ffffffffc0203e92:	98a60613          	addi	a2,a2,-1654 # ffffffffc0206818 <default_pmm_manager+0x108>
ffffffffc0203e96:	06900593          	li	a1,105
ffffffffc0203e9a:	00003517          	auipc	a0,0x3
ffffffffc0203e9e:	8d650513          	addi	a0,a0,-1834 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc0203ea2:	decfc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0203ea6:	86be                	mv	a3,a5
ffffffffc0203ea8:	00003617          	auipc	a2,0x3
ffffffffc0203eac:	8a060613          	addi	a2,a2,-1888 # ffffffffc0206748 <default_pmm_manager+0x38>
ffffffffc0203eb0:	07100593          	li	a1,113
ffffffffc0203eb4:	00003517          	auipc	a0,0x3
ffffffffc0203eb8:	8bc50513          	addi	a0,a0,-1860 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc0203ebc:	dd2fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203ec0:	00003617          	auipc	a2,0x3
ffffffffc0203ec4:	88860613          	addi	a2,a2,-1912 # ffffffffc0206748 <default_pmm_manager+0x38>
ffffffffc0203ec8:	07100593          	li	a1,113
ffffffffc0203ecc:	00003517          	auipc	a0,0x3
ffffffffc0203ed0:	8a450513          	addi	a0,a0,-1884 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc0203ed4:	dbafc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ed8 <user_mem_check>:
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203ed8:	7179                	addi	sp,sp,-48
ffffffffc0203eda:	f022                	sd	s0,32(sp)
ffffffffc0203edc:	f406                	sd	ra,40(sp)
ffffffffc0203ede:	ec26                	sd	s1,24(sp)
ffffffffc0203ee0:	e84a                	sd	s2,16(sp)
ffffffffc0203ee2:	e44e                	sd	s3,8(sp)
ffffffffc0203ee4:	e052                	sd	s4,0(sp)
ffffffffc0203ee6:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203ee8:	c135                	beqz	a0,ffffffffc0203f4c <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203eea:	002007b7          	lui	a5,0x200
ffffffffc0203eee:	04f5e663          	bltu	a1,a5,ffffffffc0203f3a <user_mem_check+0x62>
ffffffffc0203ef2:	00c584b3          	add	s1,a1,a2
ffffffffc0203ef6:	0495f263          	bgeu	a1,s1,ffffffffc0203f3a <user_mem_check+0x62>
ffffffffc0203efa:	4785                	li	a5,1
ffffffffc0203efc:	07fe                	slli	a5,a5,0x1f
ffffffffc0203efe:	0297ee63          	bltu	a5,s1,ffffffffc0203f3a <user_mem_check+0x62>
ffffffffc0203f02:	892a                	mv	s2,a0
ffffffffc0203f04:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f06:	6a05                	lui	s4,0x1
ffffffffc0203f08:	a821                	j	ffffffffc0203f20 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f0a:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f0e:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203f10:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f12:	c685                	beqz	a3,ffffffffc0203f3a <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203f14:	c399                	beqz	a5,ffffffffc0203f1a <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f16:	02e46263          	bltu	s0,a4,ffffffffc0203f3a <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203f1a:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203f1c:	04947663          	bgeu	s0,s1,ffffffffc0203f68 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203f20:	85a2                	mv	a1,s0
ffffffffc0203f22:	854a                	mv	a0,s2
ffffffffc0203f24:	fa2ff0ef          	jal	ra,ffffffffc02036c6 <find_vma>
ffffffffc0203f28:	c909                	beqz	a0,ffffffffc0203f3a <user_mem_check+0x62>
ffffffffc0203f2a:	6518                	ld	a4,8(a0)
ffffffffc0203f2c:	00e46763          	bltu	s0,a4,ffffffffc0203f3a <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f30:	4d1c                	lw	a5,24(a0)
ffffffffc0203f32:	fc099ce3          	bnez	s3,ffffffffc0203f0a <user_mem_check+0x32>
ffffffffc0203f36:	8b85                	andi	a5,a5,1
ffffffffc0203f38:	f3ed                	bnez	a5,ffffffffc0203f1a <user_mem_check+0x42>
            return 0;
ffffffffc0203f3a:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203f3c:	70a2                	ld	ra,40(sp)
ffffffffc0203f3e:	7402                	ld	s0,32(sp)
ffffffffc0203f40:	64e2                	ld	s1,24(sp)
ffffffffc0203f42:	6942                	ld	s2,16(sp)
ffffffffc0203f44:	69a2                	ld	s3,8(sp)
ffffffffc0203f46:	6a02                	ld	s4,0(sp)
ffffffffc0203f48:	6145                	addi	sp,sp,48
ffffffffc0203f4a:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203f4c:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f50:	4501                	li	a0,0
ffffffffc0203f52:	fef5e5e3          	bltu	a1,a5,ffffffffc0203f3c <user_mem_check+0x64>
ffffffffc0203f56:	962e                	add	a2,a2,a1
ffffffffc0203f58:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203f3c <user_mem_check+0x64>
ffffffffc0203f5c:	c8000537          	lui	a0,0xc8000
ffffffffc0203f60:	0505                	addi	a0,a0,1
ffffffffc0203f62:	00a63533          	sltu	a0,a2,a0
ffffffffc0203f66:	bfd9                	j	ffffffffc0203f3c <user_mem_check+0x64>
        return 1;
ffffffffc0203f68:	4505                	li	a0,1
ffffffffc0203f6a:	bfc9                	j	ffffffffc0203f3c <user_mem_check+0x64>

ffffffffc0203f6c <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203f6c:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203f6e:	9402                	jalr	s0

	jal do_exit
ffffffffc0203f70:	628000ef          	jal	ra,ffffffffc0204598 <do_exit>

ffffffffc0203f74 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203f74:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203f76:	10800513          	li	a0,264
{
ffffffffc0203f7a:	e022                	sd	s0,0(sp)
ffffffffc0203f7c:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203f7e:	de1fd0ef          	jal	ra,ffffffffc0201d5e <kmalloc>
ffffffffc0203f82:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203f84:	c12d                	beqz	a0,ffffffffc0203fe6 <alloc_proc+0x72>
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        //清空整个结构（其实这里偷鸡一下，从打印初始化的条件可以直接看出每个值的处理），666
        memset(proc, 0, sizeof(struct proc_struct));
ffffffffc0203f86:	10800613          	li	a2,264
ffffffffc0203f8a:	4581                	li	a1,0
ffffffffc0203f8c:	0d7010ef          	jal	ra,ffffffffc0205862 <memset>
        proc->state = PROC_UNINIT;
ffffffffc0203f90:	57fd                	li	a5,-1
ffffffffc0203f92:	1782                	slli	a5,a5,0x20
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&proc->context, 0, sizeof(proc->context));
ffffffffc0203f94:	07000613          	li	a2,112
ffffffffc0203f98:	4581                	li	a1,0
        proc->state = PROC_UNINIT;
ffffffffc0203f9a:	e01c                	sd	a5,0(s0)
        proc->runs = 0;
ffffffffc0203f9c:	00042423          	sw	zero,8(s0)
        proc->kstack = 0;
ffffffffc0203fa0:	00043823          	sd	zero,16(s0)
        proc->need_resched = 0;
ffffffffc0203fa4:	00043c23          	sd	zero,24(s0)
        proc->parent = NULL;
ffffffffc0203fa8:	02043023          	sd	zero,32(s0)
        proc->mm = NULL;
ffffffffc0203fac:	02043423          	sd	zero,40(s0)
        memset(&proc->context, 0, sizeof(proc->context));
ffffffffc0203fb0:	03040513          	addi	a0,s0,48
ffffffffc0203fb4:	0af010ef          	jal	ra,ffffffffc0205862 <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203fb8:	000a6797          	auipc	a5,0xa6
ffffffffc0203fbc:	7887b783          	ld	a5,1928(a5) # ffffffffc02aa740 <boot_pgdir_pa>
ffffffffc0203fc0:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;
ffffffffc0203fc2:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc0203fc6:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203fca:	4641                	li	a2,16
ffffffffc0203fcc:	4581                	li	a1,0
ffffffffc0203fce:	0b440513          	addi	a0,s0,180
ffffffffc0203fd2:	091010ef          	jal	ra,ffffffffc0205862 <memset>
        list_init(&proc->list_link);
ffffffffc0203fd6:	0c840713          	addi	a4,s0,200
        list_init(&proc->hash_link);
ffffffffc0203fda:	0d840793          	addi	a5,s0,216
    elm->prev = elm->next = elm;
ffffffffc0203fde:	e878                	sd	a4,208(s0)
ffffffffc0203fe0:	e478                	sd	a4,200(s0)
ffffffffc0203fe2:	f07c                	sd	a5,224(s0)
ffffffffc0203fe4:	ec7c                	sd	a5,216(s0)
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
    }
    return proc;
}
ffffffffc0203fe6:	60a2                	ld	ra,8(sp)
ffffffffc0203fe8:	8522                	mv	a0,s0
ffffffffc0203fea:	6402                	ld	s0,0(sp)
ffffffffc0203fec:	0141                	addi	sp,sp,16
ffffffffc0203fee:	8082                	ret

ffffffffc0203ff0 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203ff0:	000a6797          	auipc	a5,0xa6
ffffffffc0203ff4:	7887b783          	ld	a5,1928(a5) # ffffffffc02aa778 <current>
ffffffffc0203ff8:	73c8                	ld	a0,160(a5)
ffffffffc0203ffa:	fd9fc06f          	j	ffffffffc0200fd2 <forkrets>

ffffffffc0203ffe <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203ffe:	000a6797          	auipc	a5,0xa6
ffffffffc0204002:	77a7b783          	ld	a5,1914(a5) # ffffffffc02aa778 <current>
ffffffffc0204006:	43cc                	lw	a1,4(a5)
{
ffffffffc0204008:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc020400a:	00003617          	auipc	a2,0x3
ffffffffc020400e:	0ee60613          	addi	a2,a2,238 # ffffffffc02070f8 <default_pmm_manager+0x9e8>
ffffffffc0204012:	00003517          	auipc	a0,0x3
ffffffffc0204016:	0f650513          	addi	a0,a0,246 # ffffffffc0207108 <default_pmm_manager+0x9f8>
{
ffffffffc020401a:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc020401c:	978fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0204020:	3fe07797          	auipc	a5,0x3fe07
ffffffffc0204024:	94878793          	addi	a5,a5,-1720 # a968 <_binary_obj___user_forktest_out_size>
ffffffffc0204028:	e43e                	sd	a5,8(sp)
ffffffffc020402a:	00003517          	auipc	a0,0x3
ffffffffc020402e:	0ce50513          	addi	a0,a0,206 # ffffffffc02070f8 <default_pmm_manager+0x9e8>
ffffffffc0204032:	00045797          	auipc	a5,0x45
ffffffffc0204036:	6ee78793          	addi	a5,a5,1774 # ffffffffc0249720 <_binary_obj___user_forktest_out_start>
ffffffffc020403a:	f03e                	sd	a5,32(sp)
ffffffffc020403c:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc020403e:	e802                	sd	zero,16(sp)
ffffffffc0204040:	780010ef          	jal	ra,ffffffffc02057c0 <strlen>
ffffffffc0204044:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204046:	4511                	li	a0,4
ffffffffc0204048:	55a2                	lw	a1,40(sp)
ffffffffc020404a:	4662                	lw	a2,24(sp)
ffffffffc020404c:	5682                	lw	a3,32(sp)
ffffffffc020404e:	4722                	lw	a4,8(sp)
ffffffffc0204050:	48a9                	li	a7,10
ffffffffc0204052:	9002                	ebreak
ffffffffc0204054:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204056:	65c2                	ld	a1,16(sp)
ffffffffc0204058:	00003517          	auipc	a0,0x3
ffffffffc020405c:	0d850513          	addi	a0,a0,216 # ffffffffc0207130 <default_pmm_manager+0xa20>
ffffffffc0204060:	934fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204064:	00003617          	auipc	a2,0x3
ffffffffc0204068:	0dc60613          	addi	a2,a2,220 # ffffffffc0207140 <default_pmm_manager+0xa30>
ffffffffc020406c:	3be00593          	li	a1,958
ffffffffc0204070:	00003517          	auipc	a0,0x3
ffffffffc0204074:	0f050513          	addi	a0,a0,240 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0204078:	c16fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020407c <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc020407c:	6d14                	ld	a3,24(a0)
{
ffffffffc020407e:	1141                	addi	sp,sp,-16
ffffffffc0204080:	e406                	sd	ra,8(sp)
ffffffffc0204082:	c02007b7          	lui	a5,0xc0200
ffffffffc0204086:	02f6ee63          	bltu	a3,a5,ffffffffc02040c2 <put_pgdir+0x46>
ffffffffc020408a:	000a6517          	auipc	a0,0xa6
ffffffffc020408e:	6de53503          	ld	a0,1758(a0) # ffffffffc02aa768 <va_pa_offset>
ffffffffc0204092:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0204094:	82b1                	srli	a3,a3,0xc
ffffffffc0204096:	000a6797          	auipc	a5,0xa6
ffffffffc020409a:	6ba7b783          	ld	a5,1722(a5) # ffffffffc02aa750 <npage>
ffffffffc020409e:	02f6fe63          	bgeu	a3,a5,ffffffffc02040da <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc02040a2:	00004517          	auipc	a0,0x4
ffffffffc02040a6:	95653503          	ld	a0,-1706(a0) # ffffffffc02079f8 <nbase>
}
ffffffffc02040aa:	60a2                	ld	ra,8(sp)
ffffffffc02040ac:	8e89                	sub	a3,a3,a0
ffffffffc02040ae:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc02040b0:	000a6517          	auipc	a0,0xa6
ffffffffc02040b4:	6a853503          	ld	a0,1704(a0) # ffffffffc02aa758 <pages>
ffffffffc02040b8:	4585                	li	a1,1
ffffffffc02040ba:	9536                	add	a0,a0,a3
}
ffffffffc02040bc:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc02040be:	ebdfd06f          	j	ffffffffc0201f7a <free_pages>
    return pa2page(PADDR(kva));
ffffffffc02040c2:	00002617          	auipc	a2,0x2
ffffffffc02040c6:	72e60613          	addi	a2,a2,1838 # ffffffffc02067f0 <default_pmm_manager+0xe0>
ffffffffc02040ca:	07700593          	li	a1,119
ffffffffc02040ce:	00002517          	auipc	a0,0x2
ffffffffc02040d2:	6a250513          	addi	a0,a0,1698 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc02040d6:	bb8fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02040da:	00002617          	auipc	a2,0x2
ffffffffc02040de:	73e60613          	addi	a2,a2,1854 # ffffffffc0206818 <default_pmm_manager+0x108>
ffffffffc02040e2:	06900593          	li	a1,105
ffffffffc02040e6:	00002517          	auipc	a0,0x2
ffffffffc02040ea:	68a50513          	addi	a0,a0,1674 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc02040ee:	ba0fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02040f2 <proc_run>:
{
ffffffffc02040f2:	7179                	addi	sp,sp,-48
ffffffffc02040f4:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc02040f6:	000a6497          	auipc	s1,0xa6
ffffffffc02040fa:	68248493          	addi	s1,s1,1666 # ffffffffc02aa778 <current>
ffffffffc02040fe:	6098                	ld	a4,0(s1)
{
ffffffffc0204100:	f406                	sd	ra,40(sp)
ffffffffc0204102:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0204104:	02a70763          	beq	a4,a0,ffffffffc0204132 <proc_run+0x40>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204108:	100027f3          	csrr	a5,sstatus
ffffffffc020410c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020410e:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204110:	ef85                	bnez	a5,ffffffffc0204148 <proc_run+0x56>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0204112:	755c                	ld	a5,168(a0)
ffffffffc0204114:	56fd                	li	a3,-1
ffffffffc0204116:	16fe                	slli	a3,a3,0x3f
ffffffffc0204118:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc020411a:	e088                	sd	a0,0(s1)
ffffffffc020411c:	8fd5                	or	a5,a5,a3
ffffffffc020411e:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(proc->context));
ffffffffc0204122:	03050593          	addi	a1,a0,48
ffffffffc0204126:	03070513          	addi	a0,a4,48
ffffffffc020412a:	03c010ef          	jal	ra,ffffffffc0205166 <switch_to>
    if (flag)
ffffffffc020412e:	00091763          	bnez	s2,ffffffffc020413c <proc_run+0x4a>
}
ffffffffc0204132:	70a2                	ld	ra,40(sp)
ffffffffc0204134:	7482                	ld	s1,32(sp)
ffffffffc0204136:	6962                	ld	s2,24(sp)
ffffffffc0204138:	6145                	addi	sp,sp,48
ffffffffc020413a:	8082                	ret
ffffffffc020413c:	70a2                	ld	ra,40(sp)
ffffffffc020413e:	7482                	ld	s1,32(sp)
ffffffffc0204140:	6962                	ld	s2,24(sp)
ffffffffc0204142:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204144:	86bfc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0204148:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020414a:	86bfc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
            struct proc_struct *prev = current;
ffffffffc020414e:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0204150:	6522                	ld	a0,8(sp)
ffffffffc0204152:	4905                	li	s2,1
ffffffffc0204154:	bf7d                	j	ffffffffc0204112 <proc_run+0x20>

ffffffffc0204156 <do_fork>:
{
ffffffffc0204156:	7119                	addi	sp,sp,-128
ffffffffc0204158:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020415a:	000a6917          	auipc	s2,0xa6
ffffffffc020415e:	63690913          	addi	s2,s2,1590 # ffffffffc02aa790 <nr_process>
ffffffffc0204162:	00092703          	lw	a4,0(s2)
{
ffffffffc0204166:	fc86                	sd	ra,120(sp)
ffffffffc0204168:	f8a2                	sd	s0,112(sp)
ffffffffc020416a:	f4a6                	sd	s1,104(sp)
ffffffffc020416c:	ecce                	sd	s3,88(sp)
ffffffffc020416e:	e8d2                	sd	s4,80(sp)
ffffffffc0204170:	e4d6                	sd	s5,72(sp)
ffffffffc0204172:	e0da                	sd	s6,64(sp)
ffffffffc0204174:	fc5e                	sd	s7,56(sp)
ffffffffc0204176:	f862                	sd	s8,48(sp)
ffffffffc0204178:	f466                	sd	s9,40(sp)
ffffffffc020417a:	f06a                	sd	s10,32(sp)
ffffffffc020417c:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020417e:	6785                	lui	a5,0x1
ffffffffc0204180:	34f75263          	bge	a4,a5,ffffffffc02044c4 <do_fork+0x36e>
ffffffffc0204184:	8a2a                	mv	s4,a0
ffffffffc0204186:	89ae                	mv	s3,a1
ffffffffc0204188:	8432                	mv	s0,a2
    proc = alloc_proc();
ffffffffc020418a:	debff0ef          	jal	ra,ffffffffc0203f74 <alloc_proc>
ffffffffc020418e:	84aa                	mv	s1,a0
    if(proc == NULL)
ffffffffc0204190:	32050363          	beqz	a0,ffffffffc02044b6 <do_fork+0x360>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204194:	4509                	li	a0,2
ffffffffc0204196:	da7fd0ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
    if (page != NULL)
ffffffffc020419a:	30050b63          	beqz	a0,ffffffffc02044b0 <do_fork+0x35a>
    return page - pages + nbase;
ffffffffc020419e:	000a6b17          	auipc	s6,0xa6
ffffffffc02041a2:	5bab0b13          	addi	s6,s6,1466 # ffffffffc02aa758 <pages>
ffffffffc02041a6:	000b3683          	ld	a3,0(s6)
ffffffffc02041aa:	00004797          	auipc	a5,0x4
ffffffffc02041ae:	84e78793          	addi	a5,a5,-1970 # ffffffffc02079f8 <nbase>
ffffffffc02041b2:	6398                	ld	a4,0(a5)
ffffffffc02041b4:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc02041b8:	000a6c17          	auipc	s8,0xa6
ffffffffc02041bc:	598c0c13          	addi	s8,s8,1432 # ffffffffc02aa750 <npage>
    return page - pages + nbase;
ffffffffc02041c0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02041c2:	57fd                	li	a5,-1
ffffffffc02041c4:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02041c8:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02041ca:	00c7db93          	srli	s7,a5,0xc
ffffffffc02041ce:	0176f5b3          	and	a1,a3,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc02041d2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02041d4:	34c5fe63          	bgeu	a1,a2,ffffffffc0204530 <do_fork+0x3da>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02041d8:	000a6a97          	auipc	s5,0xa6
ffffffffc02041dc:	5a0a8a93          	addi	s5,s5,1440 # ffffffffc02aa778 <current>
ffffffffc02041e0:	000ab583          	ld	a1,0(s5)
ffffffffc02041e4:	000a6c97          	auipc	s9,0xa6
ffffffffc02041e8:	584c8c93          	addi	s9,s9,1412 # ffffffffc02aa768 <va_pa_offset>
ffffffffc02041ec:	000cb603          	ld	a2,0(s9)
ffffffffc02041f0:	0285bd83          	ld	s11,40(a1)
ffffffffc02041f4:	e43a                	sd	a4,8(sp)
ffffffffc02041f6:	96b2                	add	a3,a3,a2
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02041f8:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc02041fa:	020d8863          	beqz	s11,ffffffffc020422a <do_fork+0xd4>
    if (clone_flags & CLONE_VM)
ffffffffc02041fe:	100a7a13          	andi	s4,s4,256
ffffffffc0204202:	1c0a0563          	beqz	s4,ffffffffc02043cc <do_fork+0x276>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0204206:	030da703          	lw	a4,48(s11)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020420a:	018db783          	ld	a5,24(s11)
ffffffffc020420e:	c02006b7          	lui	a3,0xc0200
ffffffffc0204212:	2705                	addiw	a4,a4,1
ffffffffc0204214:	02eda823          	sw	a4,48(s11)
    proc->mm = mm;
ffffffffc0204218:	03b4b423          	sd	s11,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020421c:	2cd7e563          	bltu	a5,a3,ffffffffc02044e6 <do_fork+0x390>
ffffffffc0204220:	000cb703          	ld	a4,0(s9)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204224:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204226:	8f99                	sub	a5,a5,a4
ffffffffc0204228:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020422a:	6789                	lui	a5,0x2
ffffffffc020422c:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd0>
ffffffffc0204230:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204232:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204234:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc0204236:	87b6                	mv	a5,a3
ffffffffc0204238:	12040893          	addi	a7,s0,288
ffffffffc020423c:	00063803          	ld	a6,0(a2)
ffffffffc0204240:	6608                	ld	a0,8(a2)
ffffffffc0204242:	6a0c                	ld	a1,16(a2)
ffffffffc0204244:	6e18                	ld	a4,24(a2)
ffffffffc0204246:	0107b023          	sd	a6,0(a5)
ffffffffc020424a:	e788                	sd	a0,8(a5)
ffffffffc020424c:	eb8c                	sd	a1,16(a5)
ffffffffc020424e:	ef98                	sd	a4,24(a5)
ffffffffc0204250:	02060613          	addi	a2,a2,32
ffffffffc0204254:	02078793          	addi	a5,a5,32
ffffffffc0204258:	ff1612e3          	bne	a2,a7,ffffffffc020423c <do_fork+0xe6>
    proc->tf->gpr.a0 = 0;
ffffffffc020425c:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204260:	14098363          	beqz	s3,ffffffffc02043a6 <do_fork+0x250>
ffffffffc0204264:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204268:	00000797          	auipc	a5,0x0
ffffffffc020426c:	d8878793          	addi	a5,a5,-632 # ffffffffc0203ff0 <forkret>
ffffffffc0204270:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204272:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204274:	100027f3          	csrr	a5,sstatus
ffffffffc0204278:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020427a:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020427c:	14079463          	bnez	a5,ffffffffc02043c4 <do_fork+0x26e>
    if (++last_pid >= MAX_PID)
ffffffffc0204280:	000a2817          	auipc	a6,0xa2
ffffffffc0204284:	05880813          	addi	a6,a6,88 # ffffffffc02a62d8 <last_pid.1>
        proc->parent = current;
ffffffffc0204288:	000ab703          	ld	a4,0(s5)
    if (++last_pid >= MAX_PID)
ffffffffc020428c:	00082783          	lw	a5,0(a6)
ffffffffc0204290:	6689                	lui	a3,0x2
        proc->parent = current;
ffffffffc0204292:	f098                	sd	a4,32(s1)
    if (++last_pid >= MAX_PID)
ffffffffc0204294:	0017851b          	addiw	a0,a5,1
        current->wait_state = 0;
ffffffffc0204298:	0e072623          	sw	zero,236(a4)
    if (++last_pid >= MAX_PID)
ffffffffc020429c:	00a82023          	sw	a0,0(a6)
ffffffffc02042a0:	08d55c63          	bge	a0,a3,ffffffffc0204338 <do_fork+0x1e2>
    if (last_pid >= next_safe)
ffffffffc02042a4:	000a2317          	auipc	t1,0xa2
ffffffffc02042a8:	03830313          	addi	t1,t1,56 # ffffffffc02a62dc <next_safe.0>
ffffffffc02042ac:	00032783          	lw	a5,0(t1)
ffffffffc02042b0:	000a6417          	auipc	s0,0xa6
ffffffffc02042b4:	44840413          	addi	s0,s0,1096 # ffffffffc02aa6f8 <proc_list>
ffffffffc02042b8:	08f55863          	bge	a0,a5,ffffffffc0204348 <do_fork+0x1f2>
        proc->pid = get_pid();
ffffffffc02042bc:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02042be:	45a9                	li	a1,10
ffffffffc02042c0:	2501                	sext.w	a0,a0
ffffffffc02042c2:	0fa010ef          	jal	ra,ffffffffc02053bc <hash32>
ffffffffc02042c6:	02051793          	slli	a5,a0,0x20
ffffffffc02042ca:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02042ce:	000a2797          	auipc	a5,0xa2
ffffffffc02042d2:	42a78793          	addi	a5,a5,1066 # ffffffffc02a66f8 <hash_list>
ffffffffc02042d6:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02042d8:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02042da:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02042dc:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc02042e0:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02042e2:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc02042e4:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02042e6:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02042e8:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc02042ec:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc02042ee:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc02042f0:	e21c                	sd	a5,0(a2)
ffffffffc02042f2:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc02042f4:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc02042f6:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc02042f8:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02042fc:	10e4b023          	sd	a4,256(s1)
ffffffffc0204300:	c311                	beqz	a4,ffffffffc0204304 <do_fork+0x1ae>
        proc->optr->yptr = proc;
ffffffffc0204302:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc0204304:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0204308:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc020430a:	2785                	addiw	a5,a5,1
ffffffffc020430c:	00f92023          	sw	a5,0(s2)
        proc->state = PROC_RUNNABLE;
ffffffffc0204310:	4789                	li	a5,2
ffffffffc0204312:	c09c                	sw	a5,0(s1)
    if (flag)
ffffffffc0204314:	14099863          	bnez	s3,ffffffffc0204464 <do_fork+0x30e>
    ret = proc->pid;
ffffffffc0204318:	40c8                	lw	a0,4(s1)
}
ffffffffc020431a:	70e6                	ld	ra,120(sp)
ffffffffc020431c:	7446                	ld	s0,112(sp)
ffffffffc020431e:	74a6                	ld	s1,104(sp)
ffffffffc0204320:	7906                	ld	s2,96(sp)
ffffffffc0204322:	69e6                	ld	s3,88(sp)
ffffffffc0204324:	6a46                	ld	s4,80(sp)
ffffffffc0204326:	6aa6                	ld	s5,72(sp)
ffffffffc0204328:	6b06                	ld	s6,64(sp)
ffffffffc020432a:	7be2                	ld	s7,56(sp)
ffffffffc020432c:	7c42                	ld	s8,48(sp)
ffffffffc020432e:	7ca2                	ld	s9,40(sp)
ffffffffc0204330:	7d02                	ld	s10,32(sp)
ffffffffc0204332:	6de2                	ld	s11,24(sp)
ffffffffc0204334:	6109                	addi	sp,sp,128
ffffffffc0204336:	8082                	ret
        last_pid = 1;
ffffffffc0204338:	4785                	li	a5,1
ffffffffc020433a:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020433e:	4505                	li	a0,1
ffffffffc0204340:	000a2317          	auipc	t1,0xa2
ffffffffc0204344:	f9c30313          	addi	t1,t1,-100 # ffffffffc02a62dc <next_safe.0>
    return listelm->next;
ffffffffc0204348:	000a6417          	auipc	s0,0xa6
ffffffffc020434c:	3b040413          	addi	s0,s0,944 # ffffffffc02aa6f8 <proc_list>
ffffffffc0204350:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0204354:	6789                	lui	a5,0x2
ffffffffc0204356:	00f32023          	sw	a5,0(t1)
ffffffffc020435a:	86aa                	mv	a3,a0
ffffffffc020435c:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020435e:	6e89                	lui	t4,0x2
ffffffffc0204360:	148e0d63          	beq	t3,s0,ffffffffc02044ba <do_fork+0x364>
ffffffffc0204364:	88ae                	mv	a7,a1
ffffffffc0204366:	87f2                	mv	a5,t3
ffffffffc0204368:	6609                	lui	a2,0x2
ffffffffc020436a:	a811                	j	ffffffffc020437e <do_fork+0x228>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020436c:	00e6d663          	bge	a3,a4,ffffffffc0204378 <do_fork+0x222>
ffffffffc0204370:	00c75463          	bge	a4,a2,ffffffffc0204378 <do_fork+0x222>
ffffffffc0204374:	863a                	mv	a2,a4
ffffffffc0204376:	4885                	li	a7,1
ffffffffc0204378:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020437a:	00878d63          	beq	a5,s0,ffffffffc0204394 <do_fork+0x23e>
            if (proc->pid == last_pid)
ffffffffc020437e:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c74>
ffffffffc0204382:	fed715e3          	bne	a4,a3,ffffffffc020436c <do_fork+0x216>
                if (++last_pid >= next_safe)
ffffffffc0204386:	2685                	addiw	a3,a3,1
ffffffffc0204388:	0ec6d163          	bge	a3,a2,ffffffffc020446a <do_fork+0x314>
ffffffffc020438c:	679c                	ld	a5,8(a5)
ffffffffc020438e:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204390:	fe8797e3          	bne	a5,s0,ffffffffc020437e <do_fork+0x228>
ffffffffc0204394:	c581                	beqz	a1,ffffffffc020439c <do_fork+0x246>
ffffffffc0204396:	00d82023          	sw	a3,0(a6)
ffffffffc020439a:	8536                	mv	a0,a3
ffffffffc020439c:	f20880e3          	beqz	a7,ffffffffc02042bc <do_fork+0x166>
ffffffffc02043a0:	00c32023          	sw	a2,0(t1)
ffffffffc02043a4:	bf21                	j	ffffffffc02042bc <do_fork+0x166>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02043a6:	89b6                	mv	s3,a3
ffffffffc02043a8:	0136b823          	sd	s3,16(a3) # 2010 <_binary_obj___user_faultread_out_size-0x7ba0>
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02043ac:	00000797          	auipc	a5,0x0
ffffffffc02043b0:	c4478793          	addi	a5,a5,-956 # ffffffffc0203ff0 <forkret>
ffffffffc02043b4:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02043b6:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02043b8:	100027f3          	csrr	a5,sstatus
ffffffffc02043bc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02043be:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02043c0:	ec0780e3          	beqz	a5,ffffffffc0204280 <do_fork+0x12a>
        intr_disable();
ffffffffc02043c4:	df0fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02043c8:	4985                	li	s3,1
ffffffffc02043ca:	bd5d                	j	ffffffffc0204280 <do_fork+0x12a>
    if ((mm = mm_create()) == NULL)
ffffffffc02043cc:	acaff0ef          	jal	ra,ffffffffc0203696 <mm_create>
ffffffffc02043d0:	8d2a                	mv	s10,a0
ffffffffc02043d2:	c545                	beqz	a0,ffffffffc020447a <do_fork+0x324>
    if ((page = alloc_page()) == NULL)
ffffffffc02043d4:	4505                	li	a0,1
ffffffffc02043d6:	b67fd0ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc02043da:	cd49                	beqz	a0,ffffffffc0204474 <do_fork+0x31e>
    return page - pages + nbase;
ffffffffc02043dc:	000b3683          	ld	a3,0(s6)
ffffffffc02043e0:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc02043e2:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02043e6:	40d506b3          	sub	a3,a0,a3
ffffffffc02043ea:	8699                	srai	a3,a3,0x6
ffffffffc02043ec:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02043ee:	0176f7b3          	and	a5,a3,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc02043f2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02043f4:	12c7fe63          	bgeu	a5,a2,ffffffffc0204530 <do_fork+0x3da>
ffffffffc02043f8:	000cba03          	ld	s4,0(s9)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02043fc:	6605                	lui	a2,0x1
ffffffffc02043fe:	000a6597          	auipc	a1,0xa6
ffffffffc0204402:	34a5b583          	ld	a1,842(a1) # ffffffffc02aa748 <boot_pgdir_va>
ffffffffc0204406:	9a36                	add	s4,s4,a3
ffffffffc0204408:	8552                	mv	a0,s4
ffffffffc020440a:	46a010ef          	jal	ra,ffffffffc0205874 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc020440e:	038d8b93          	addi	s7,s11,56
    mm->pgdir = pgdir;
ffffffffc0204412:	014d3c23          	sd	s4,24(s10) # 200018 <_binary_obj___user_exit_out_size+0x1f4ef0>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204416:	4785                	li	a5,1
ffffffffc0204418:	40fbb7af          	amoor.d	a5,a5,(s7)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc020441c:	8b85                	andi	a5,a5,1
ffffffffc020441e:	4a05                	li	s4,1
ffffffffc0204420:	c799                	beqz	a5,ffffffffc020442e <do_fork+0x2d8>
    {
        schedule();
ffffffffc0204422:	62f000ef          	jal	ra,ffffffffc0205250 <schedule>
ffffffffc0204426:	414bb7af          	amoor.d	a5,s4,(s7)
    while (!try_lock(lock))
ffffffffc020442a:	8b85                	andi	a5,a5,1
ffffffffc020442c:	fbfd                	bnez	a5,ffffffffc0204422 <do_fork+0x2cc>
        ret = dup_mmap(mm, oldmm);
ffffffffc020442e:	85ee                	mv	a1,s11
ffffffffc0204430:	856a                	mv	a0,s10
ffffffffc0204432:	ca6ff0ef          	jal	ra,ffffffffc02038d8 <dup_mmap>
ffffffffc0204436:	8a2a                	mv	s4,a0
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204438:	57f9                	li	a5,-2
ffffffffc020443a:	60fbb7af          	amoand.d	a5,a5,(s7)
ffffffffc020443e:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc0204440:	0c078c63          	beqz	a5,ffffffffc0204518 <do_fork+0x3c2>
good_mm:
ffffffffc0204444:	8dea                	mv	s11,s10
    if (ret != 0)
ffffffffc0204446:	dc0500e3          	beqz	a0,ffffffffc0204206 <do_fork+0xb0>
    exit_mmap(mm);
ffffffffc020444a:	856a                	mv	a0,s10
ffffffffc020444c:	d26ff0ef          	jal	ra,ffffffffc0203972 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204450:	856a                	mv	a0,s10
ffffffffc0204452:	c2bff0ef          	jal	ra,ffffffffc020407c <put_pgdir>
    mm_destroy(mm);
ffffffffc0204456:	856a                	mv	a0,s10
ffffffffc0204458:	b7eff0ef          	jal	ra,ffffffffc02037d6 <mm_destroy>
    if(copy_mm(clone_flags, proc) < 0)
ffffffffc020445c:	000a4f63          	bltz	s4,ffffffffc020447a <do_fork+0x324>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204460:	6894                	ld	a3,16(s1)
ffffffffc0204462:	b3e1                	j	ffffffffc020422a <do_fork+0xd4>
        intr_enable();
ffffffffc0204464:	d4afc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204468:	bd45                	j	ffffffffc0204318 <do_fork+0x1c2>
                    if (last_pid >= MAX_PID)
ffffffffc020446a:	01d6c363          	blt	a3,t4,ffffffffc0204470 <do_fork+0x31a>
                        last_pid = 1;
ffffffffc020446e:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204470:	4585                	li	a1,1
ffffffffc0204472:	b5fd                	j	ffffffffc0204360 <do_fork+0x20a>
    mm_destroy(mm);
ffffffffc0204474:	856a                	mv	a0,s10
ffffffffc0204476:	b60ff0ef          	jal	ra,ffffffffc02037d6 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020447a:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc020447c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204480:	08f6e063          	bltu	a3,a5,ffffffffc0204500 <do_fork+0x3aa>
ffffffffc0204484:	000cb783          	ld	a5,0(s9)
    if (PPN(pa) >= npage)
ffffffffc0204488:	000c3703          	ld	a4,0(s8)
    return pa2page(PADDR(kva));
ffffffffc020448c:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204490:	83b1                	srli	a5,a5,0xc
ffffffffc0204492:	02e7fe63          	bgeu	a5,a4,ffffffffc02044ce <do_fork+0x378>
    return &pages[PPN(pa) - nbase];
ffffffffc0204496:	00003717          	auipc	a4,0x3
ffffffffc020449a:	56270713          	addi	a4,a4,1378 # ffffffffc02079f8 <nbase>
ffffffffc020449e:	6318                	ld	a4,0(a4)
ffffffffc02044a0:	000b3503          	ld	a0,0(s6)
ffffffffc02044a4:	4589                	li	a1,2
ffffffffc02044a6:	8f99                	sub	a5,a5,a4
ffffffffc02044a8:	079a                	slli	a5,a5,0x6
ffffffffc02044aa:	953e                	add	a0,a0,a5
ffffffffc02044ac:	acffd0ef          	jal	ra,ffffffffc0201f7a <free_pages>
    kfree(proc);
ffffffffc02044b0:	8526                	mv	a0,s1
ffffffffc02044b2:	95dfd0ef          	jal	ra,ffffffffc0201e0e <kfree>
    ret = -E_NO_MEM;
ffffffffc02044b6:	5571                	li	a0,-4
    return ret;
ffffffffc02044b8:	b58d                	j	ffffffffc020431a <do_fork+0x1c4>
ffffffffc02044ba:	c599                	beqz	a1,ffffffffc02044c8 <do_fork+0x372>
ffffffffc02044bc:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02044c0:	8536                	mv	a0,a3
ffffffffc02044c2:	bbed                	j	ffffffffc02042bc <do_fork+0x166>
    int ret = -E_NO_FREE_PROC;
ffffffffc02044c4:	556d                	li	a0,-5
ffffffffc02044c6:	bd91                	j	ffffffffc020431a <do_fork+0x1c4>
    return last_pid;
ffffffffc02044c8:	00082503          	lw	a0,0(a6)
ffffffffc02044cc:	bbc5                	j	ffffffffc02042bc <do_fork+0x166>
        panic("pa2page called with invalid pa");
ffffffffc02044ce:	00002617          	auipc	a2,0x2
ffffffffc02044d2:	34a60613          	addi	a2,a2,842 # ffffffffc0206818 <default_pmm_manager+0x108>
ffffffffc02044d6:	06900593          	li	a1,105
ffffffffc02044da:	00002517          	auipc	a0,0x2
ffffffffc02044de:	29650513          	addi	a0,a0,662 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc02044e2:	fadfb0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02044e6:	86be                	mv	a3,a5
ffffffffc02044e8:	00002617          	auipc	a2,0x2
ffffffffc02044ec:	30860613          	addi	a2,a2,776 # ffffffffc02067f0 <default_pmm_manager+0xe0>
ffffffffc02044f0:	18f00593          	li	a1,399
ffffffffc02044f4:	00003517          	auipc	a0,0x3
ffffffffc02044f8:	c6c50513          	addi	a0,a0,-916 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc02044fc:	f93fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204500:	00002617          	auipc	a2,0x2
ffffffffc0204504:	2f060613          	addi	a2,a2,752 # ffffffffc02067f0 <default_pmm_manager+0xe0>
ffffffffc0204508:	07700593          	li	a1,119
ffffffffc020450c:	00002517          	auipc	a0,0x2
ffffffffc0204510:	26450513          	addi	a0,a0,612 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc0204514:	f7bfb0ef          	jal	ra,ffffffffc020048e <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204518:	00003617          	auipc	a2,0x3
ffffffffc020451c:	c6060613          	addi	a2,a2,-928 # ffffffffc0207178 <default_pmm_manager+0xa68>
ffffffffc0204520:	03f00593          	li	a1,63
ffffffffc0204524:	00003517          	auipc	a0,0x3
ffffffffc0204528:	c6450513          	addi	a0,a0,-924 # ffffffffc0207188 <default_pmm_manager+0xa78>
ffffffffc020452c:	f63fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0204530:	00002617          	auipc	a2,0x2
ffffffffc0204534:	21860613          	addi	a2,a2,536 # ffffffffc0206748 <default_pmm_manager+0x38>
ffffffffc0204538:	07100593          	li	a1,113
ffffffffc020453c:	00002517          	auipc	a0,0x2
ffffffffc0204540:	23450513          	addi	a0,a0,564 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc0204544:	f4bfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204548 <kernel_thread>:
{
ffffffffc0204548:	7129                	addi	sp,sp,-320
ffffffffc020454a:	fa22                	sd	s0,304(sp)
ffffffffc020454c:	f626                	sd	s1,296(sp)
ffffffffc020454e:	f24a                	sd	s2,288(sp)
ffffffffc0204550:	84ae                	mv	s1,a1
ffffffffc0204552:	892a                	mv	s2,a0
ffffffffc0204554:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204556:	4581                	li	a1,0
ffffffffc0204558:	12000613          	li	a2,288
ffffffffc020455c:	850a                	mv	a0,sp
{
ffffffffc020455e:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204560:	302010ef          	jal	ra,ffffffffc0205862 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204564:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204566:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204568:	100027f3          	csrr	a5,sstatus
ffffffffc020456c:	edd7f793          	andi	a5,a5,-291
ffffffffc0204570:	1207e793          	ori	a5,a5,288
ffffffffc0204574:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204576:	860a                	mv	a2,sp
ffffffffc0204578:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020457c:	00000797          	auipc	a5,0x0
ffffffffc0204580:	9f078793          	addi	a5,a5,-1552 # ffffffffc0203f6c <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204584:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204586:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204588:	bcfff0ef          	jal	ra,ffffffffc0204156 <do_fork>
}
ffffffffc020458c:	70f2                	ld	ra,312(sp)
ffffffffc020458e:	7452                	ld	s0,304(sp)
ffffffffc0204590:	74b2                	ld	s1,296(sp)
ffffffffc0204592:	7912                	ld	s2,288(sp)
ffffffffc0204594:	6131                	addi	sp,sp,320
ffffffffc0204596:	8082                	ret

ffffffffc0204598 <do_exit>:
{
ffffffffc0204598:	7179                	addi	sp,sp,-48
ffffffffc020459a:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc020459c:	000a6417          	auipc	s0,0xa6
ffffffffc02045a0:	1dc40413          	addi	s0,s0,476 # ffffffffc02aa778 <current>
ffffffffc02045a4:	601c                	ld	a5,0(s0)
{
ffffffffc02045a6:	f406                	sd	ra,40(sp)
ffffffffc02045a8:	ec26                	sd	s1,24(sp)
ffffffffc02045aa:	e84a                	sd	s2,16(sp)
ffffffffc02045ac:	e44e                	sd	s3,8(sp)
ffffffffc02045ae:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc02045b0:	000a6717          	auipc	a4,0xa6
ffffffffc02045b4:	1d073703          	ld	a4,464(a4) # ffffffffc02aa780 <idleproc>
ffffffffc02045b8:	0ce78c63          	beq	a5,a4,ffffffffc0204690 <do_exit+0xf8>
    if (current == initproc)
ffffffffc02045bc:	000a6497          	auipc	s1,0xa6
ffffffffc02045c0:	1cc48493          	addi	s1,s1,460 # ffffffffc02aa788 <initproc>
ffffffffc02045c4:	6098                	ld	a4,0(s1)
ffffffffc02045c6:	0ee78b63          	beq	a5,a4,ffffffffc02046bc <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc02045ca:	0287b983          	ld	s3,40(a5)
ffffffffc02045ce:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc02045d0:	02098663          	beqz	s3,ffffffffc02045fc <do_exit+0x64>
ffffffffc02045d4:	000a6797          	auipc	a5,0xa6
ffffffffc02045d8:	16c7b783          	ld	a5,364(a5) # ffffffffc02aa740 <boot_pgdir_pa>
ffffffffc02045dc:	577d                	li	a4,-1
ffffffffc02045de:	177e                	slli	a4,a4,0x3f
ffffffffc02045e0:	83b1                	srli	a5,a5,0xc
ffffffffc02045e2:	8fd9                	or	a5,a5,a4
ffffffffc02045e4:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02045e8:	0309a783          	lw	a5,48(s3)
ffffffffc02045ec:	fff7871b          	addiw	a4,a5,-1
ffffffffc02045f0:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02045f4:	cb55                	beqz	a4,ffffffffc02046a8 <do_exit+0x110>
        current->mm = NULL;
ffffffffc02045f6:	601c                	ld	a5,0(s0)
ffffffffc02045f8:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02045fc:	601c                	ld	a5,0(s0)
ffffffffc02045fe:	470d                	li	a4,3
ffffffffc0204600:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0204602:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204606:	100027f3          	csrr	a5,sstatus
ffffffffc020460a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020460c:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020460e:	e3f9                	bnez	a5,ffffffffc02046d4 <do_exit+0x13c>
        proc = current->parent;
ffffffffc0204610:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204612:	800007b7          	lui	a5,0x80000
ffffffffc0204616:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204618:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc020461a:	0ec52703          	lw	a4,236(a0)
ffffffffc020461e:	0af70f63          	beq	a4,a5,ffffffffc02046dc <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc0204622:	6018                	ld	a4,0(s0)
ffffffffc0204624:	7b7c                	ld	a5,240(a4)
ffffffffc0204626:	c3a1                	beqz	a5,ffffffffc0204666 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204628:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc020462c:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc020462e:	0985                	addi	s3,s3,1
ffffffffc0204630:	a021                	j	ffffffffc0204638 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204632:	6018                	ld	a4,0(s0)
ffffffffc0204634:	7b7c                	ld	a5,240(a4)
ffffffffc0204636:	cb85                	beqz	a5,ffffffffc0204666 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204638:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fd8>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020463c:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc020463e:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204640:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204642:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204646:	10e7b023          	sd	a4,256(a5)
ffffffffc020464a:	c311                	beqz	a4,ffffffffc020464e <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc020464c:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020464e:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204650:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204652:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204654:	fd271fe3          	bne	a4,s2,ffffffffc0204632 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204658:	0ec52783          	lw	a5,236(a0)
ffffffffc020465c:	fd379be3          	bne	a5,s3,ffffffffc0204632 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc0204660:	371000ef          	jal	ra,ffffffffc02051d0 <wakeup_proc>
ffffffffc0204664:	b7f9                	j	ffffffffc0204632 <do_exit+0x9a>
    if (flag)
ffffffffc0204666:	020a1263          	bnez	s4,ffffffffc020468a <do_exit+0xf2>
    schedule();
ffffffffc020466a:	3e7000ef          	jal	ra,ffffffffc0205250 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc020466e:	601c                	ld	a5,0(s0)
ffffffffc0204670:	00003617          	auipc	a2,0x3
ffffffffc0204674:	b5060613          	addi	a2,a2,-1200 # ffffffffc02071c0 <default_pmm_manager+0xab0>
ffffffffc0204678:	24500593          	li	a1,581
ffffffffc020467c:	43d4                	lw	a3,4(a5)
ffffffffc020467e:	00003517          	auipc	a0,0x3
ffffffffc0204682:	ae250513          	addi	a0,a0,-1310 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0204686:	e09fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc020468a:	b24fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020468e:	bff1                	j	ffffffffc020466a <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0204690:	00003617          	auipc	a2,0x3
ffffffffc0204694:	b1060613          	addi	a2,a2,-1264 # ffffffffc02071a0 <default_pmm_manager+0xa90>
ffffffffc0204698:	21100593          	li	a1,529
ffffffffc020469c:	00003517          	auipc	a0,0x3
ffffffffc02046a0:	ac450513          	addi	a0,a0,-1340 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc02046a4:	debfb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc02046a8:	854e                	mv	a0,s3
ffffffffc02046aa:	ac8ff0ef          	jal	ra,ffffffffc0203972 <exit_mmap>
            put_pgdir(mm);
ffffffffc02046ae:	854e                	mv	a0,s3
ffffffffc02046b0:	9cdff0ef          	jal	ra,ffffffffc020407c <put_pgdir>
            mm_destroy(mm);
ffffffffc02046b4:	854e                	mv	a0,s3
ffffffffc02046b6:	920ff0ef          	jal	ra,ffffffffc02037d6 <mm_destroy>
ffffffffc02046ba:	bf35                	j	ffffffffc02045f6 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc02046bc:	00003617          	auipc	a2,0x3
ffffffffc02046c0:	af460613          	addi	a2,a2,-1292 # ffffffffc02071b0 <default_pmm_manager+0xaa0>
ffffffffc02046c4:	21500593          	li	a1,533
ffffffffc02046c8:	00003517          	auipc	a0,0x3
ffffffffc02046cc:	a9850513          	addi	a0,a0,-1384 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc02046d0:	dbffb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc02046d4:	ae0fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02046d8:	4a05                	li	s4,1
ffffffffc02046da:	bf1d                	j	ffffffffc0204610 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc02046dc:	2f5000ef          	jal	ra,ffffffffc02051d0 <wakeup_proc>
ffffffffc02046e0:	b789                	j	ffffffffc0204622 <do_exit+0x8a>

ffffffffc02046e2 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc02046e2:	715d                	addi	sp,sp,-80
ffffffffc02046e4:	f84a                	sd	s2,48(sp)
ffffffffc02046e6:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc02046e8:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc02046ec:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc02046ee:	fc26                	sd	s1,56(sp)
ffffffffc02046f0:	f052                	sd	s4,32(sp)
ffffffffc02046f2:	ec56                	sd	s5,24(sp)
ffffffffc02046f4:	e85a                	sd	s6,16(sp)
ffffffffc02046f6:	e45e                	sd	s7,8(sp)
ffffffffc02046f8:	e486                	sd	ra,72(sp)
ffffffffc02046fa:	e0a2                	sd	s0,64(sp)
ffffffffc02046fc:	84aa                	mv	s1,a0
ffffffffc02046fe:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204700:	000a6b97          	auipc	s7,0xa6
ffffffffc0204704:	078b8b93          	addi	s7,s7,120 # ffffffffc02aa778 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204708:	00050b1b          	sext.w	s6,a0
ffffffffc020470c:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204710:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204712:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204714:	ccbd                	beqz	s1,ffffffffc0204792 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204716:	0359e863          	bltu	s3,s5,ffffffffc0204746 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020471a:	45a9                	li	a1,10
ffffffffc020471c:	855a                	mv	a0,s6
ffffffffc020471e:	49f000ef          	jal	ra,ffffffffc02053bc <hash32>
ffffffffc0204722:	02051793          	slli	a5,a0,0x20
ffffffffc0204726:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020472a:	000a2797          	auipc	a5,0xa2
ffffffffc020472e:	fce78793          	addi	a5,a5,-50 # ffffffffc02a66f8 <hash_list>
ffffffffc0204732:	953e                	add	a0,a0,a5
ffffffffc0204734:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204736:	a029                	j	ffffffffc0204740 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204738:	f2c42783          	lw	a5,-212(s0)
ffffffffc020473c:	02978163          	beq	a5,s1,ffffffffc020475e <do_wait.part.0+0x7c>
ffffffffc0204740:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204742:	fe851be3          	bne	a0,s0,ffffffffc0204738 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc0204746:	5579                	li	a0,-2
}
ffffffffc0204748:	60a6                	ld	ra,72(sp)
ffffffffc020474a:	6406                	ld	s0,64(sp)
ffffffffc020474c:	74e2                	ld	s1,56(sp)
ffffffffc020474e:	7942                	ld	s2,48(sp)
ffffffffc0204750:	79a2                	ld	s3,40(sp)
ffffffffc0204752:	7a02                	ld	s4,32(sp)
ffffffffc0204754:	6ae2                	ld	s5,24(sp)
ffffffffc0204756:	6b42                	ld	s6,16(sp)
ffffffffc0204758:	6ba2                	ld	s7,8(sp)
ffffffffc020475a:	6161                	addi	sp,sp,80
ffffffffc020475c:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc020475e:	000bb683          	ld	a3,0(s7)
ffffffffc0204762:	f4843783          	ld	a5,-184(s0)
ffffffffc0204766:	fed790e3          	bne	a5,a3,ffffffffc0204746 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020476a:	f2842703          	lw	a4,-216(s0)
ffffffffc020476e:	478d                	li	a5,3
ffffffffc0204770:	0ef70b63          	beq	a4,a5,ffffffffc0204866 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204774:	4785                	li	a5,1
ffffffffc0204776:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204778:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc020477c:	2d5000ef          	jal	ra,ffffffffc0205250 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204780:	000bb783          	ld	a5,0(s7)
ffffffffc0204784:	0b07a783          	lw	a5,176(a5)
ffffffffc0204788:	8b85                	andi	a5,a5,1
ffffffffc020478a:	d7c9                	beqz	a5,ffffffffc0204714 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc020478c:	555d                	li	a0,-9
ffffffffc020478e:	e0bff0ef          	jal	ra,ffffffffc0204598 <do_exit>
        proc = current->cptr;
ffffffffc0204792:	000bb683          	ld	a3,0(s7)
ffffffffc0204796:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204798:	d45d                	beqz	s0,ffffffffc0204746 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020479a:	470d                	li	a4,3
ffffffffc020479c:	a021                	j	ffffffffc02047a4 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc020479e:	10043403          	ld	s0,256(s0)
ffffffffc02047a2:	d869                	beqz	s0,ffffffffc0204774 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02047a4:	401c                	lw	a5,0(s0)
ffffffffc02047a6:	fee79ce3          	bne	a5,a4,ffffffffc020479e <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc02047aa:	000a6797          	auipc	a5,0xa6
ffffffffc02047ae:	fd67b783          	ld	a5,-42(a5) # ffffffffc02aa780 <idleproc>
ffffffffc02047b2:	0c878963          	beq	a5,s0,ffffffffc0204884 <do_wait.part.0+0x1a2>
ffffffffc02047b6:	000a6797          	auipc	a5,0xa6
ffffffffc02047ba:	fd27b783          	ld	a5,-46(a5) # ffffffffc02aa788 <initproc>
ffffffffc02047be:	0cf40363          	beq	s0,a5,ffffffffc0204884 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc02047c2:	000a0663          	beqz	s4,ffffffffc02047ce <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc02047c6:	0e842783          	lw	a5,232(s0)
ffffffffc02047ca:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb0>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02047ce:	100027f3          	csrr	a5,sstatus
ffffffffc02047d2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02047d4:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02047d6:	e7c1                	bnez	a5,ffffffffc020485e <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02047d8:	6c70                	ld	a2,216(s0)
ffffffffc02047da:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc02047dc:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc02047e0:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02047e2:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02047e4:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02047e6:	6470                	ld	a2,200(s0)
ffffffffc02047e8:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02047ea:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02047ec:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc02047ee:	c319                	beqz	a4,ffffffffc02047f4 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc02047f0:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc02047f2:	7c7c                	ld	a5,248(s0)
ffffffffc02047f4:	c3b5                	beqz	a5,ffffffffc0204858 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc02047f6:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc02047fa:	000a6717          	auipc	a4,0xa6
ffffffffc02047fe:	f9670713          	addi	a4,a4,-106 # ffffffffc02aa790 <nr_process>
ffffffffc0204802:	431c                	lw	a5,0(a4)
ffffffffc0204804:	37fd                	addiw	a5,a5,-1
ffffffffc0204806:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204808:	e5a9                	bnez	a1,ffffffffc0204852 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020480a:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020480c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204810:	04f6ee63          	bltu	a3,a5,ffffffffc020486c <do_wait.part.0+0x18a>
ffffffffc0204814:	000a6797          	auipc	a5,0xa6
ffffffffc0204818:	f547b783          	ld	a5,-172(a5) # ffffffffc02aa768 <va_pa_offset>
ffffffffc020481c:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020481e:	82b1                	srli	a3,a3,0xc
ffffffffc0204820:	000a6797          	auipc	a5,0xa6
ffffffffc0204824:	f307b783          	ld	a5,-208(a5) # ffffffffc02aa750 <npage>
ffffffffc0204828:	06f6fa63          	bgeu	a3,a5,ffffffffc020489c <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc020482c:	00003517          	auipc	a0,0x3
ffffffffc0204830:	1cc53503          	ld	a0,460(a0) # ffffffffc02079f8 <nbase>
ffffffffc0204834:	8e89                	sub	a3,a3,a0
ffffffffc0204836:	069a                	slli	a3,a3,0x6
ffffffffc0204838:	000a6517          	auipc	a0,0xa6
ffffffffc020483c:	f2053503          	ld	a0,-224(a0) # ffffffffc02aa758 <pages>
ffffffffc0204840:	9536                	add	a0,a0,a3
ffffffffc0204842:	4589                	li	a1,2
ffffffffc0204844:	f36fd0ef          	jal	ra,ffffffffc0201f7a <free_pages>
    kfree(proc);
ffffffffc0204848:	8522                	mv	a0,s0
ffffffffc020484a:	dc4fd0ef          	jal	ra,ffffffffc0201e0e <kfree>
    return 0;
ffffffffc020484e:	4501                	li	a0,0
ffffffffc0204850:	bde5                	j	ffffffffc0204748 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204852:	95cfc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204856:	bf55                	j	ffffffffc020480a <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204858:	701c                	ld	a5,32(s0)
ffffffffc020485a:	fbf8                	sd	a4,240(a5)
ffffffffc020485c:	bf79                	j	ffffffffc02047fa <do_wait.part.0+0x118>
        intr_disable();
ffffffffc020485e:	956fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204862:	4585                	li	a1,1
ffffffffc0204864:	bf95                	j	ffffffffc02047d8 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204866:	f2840413          	addi	s0,s0,-216
ffffffffc020486a:	b781                	j	ffffffffc02047aa <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc020486c:	00002617          	auipc	a2,0x2
ffffffffc0204870:	f8460613          	addi	a2,a2,-124 # ffffffffc02067f0 <default_pmm_manager+0xe0>
ffffffffc0204874:	07700593          	li	a1,119
ffffffffc0204878:	00002517          	auipc	a0,0x2
ffffffffc020487c:	ef850513          	addi	a0,a0,-264 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc0204880:	c0ffb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204884:	00003617          	auipc	a2,0x3
ffffffffc0204888:	95c60613          	addi	a2,a2,-1700 # ffffffffc02071e0 <default_pmm_manager+0xad0>
ffffffffc020488c:	36600593          	li	a1,870
ffffffffc0204890:	00003517          	auipc	a0,0x3
ffffffffc0204894:	8d050513          	addi	a0,a0,-1840 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0204898:	bf7fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020489c:	00002617          	auipc	a2,0x2
ffffffffc02048a0:	f7c60613          	addi	a2,a2,-132 # ffffffffc0206818 <default_pmm_manager+0x108>
ffffffffc02048a4:	06900593          	li	a1,105
ffffffffc02048a8:	00002517          	auipc	a0,0x2
ffffffffc02048ac:	ec850513          	addi	a0,a0,-312 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc02048b0:	bdffb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02048b4 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02048b4:	1141                	addi	sp,sp,-16
ffffffffc02048b6:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02048b8:	f02fd0ef          	jal	ra,ffffffffc0201fba <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02048bc:	c9efd0ef          	jal	ra,ffffffffc0201d5a <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02048c0:	4601                	li	a2,0
ffffffffc02048c2:	4581                	li	a1,0
ffffffffc02048c4:	fffff517          	auipc	a0,0xfffff
ffffffffc02048c8:	73a50513          	addi	a0,a0,1850 # ffffffffc0203ffe <user_main>
ffffffffc02048cc:	c7dff0ef          	jal	ra,ffffffffc0204548 <kernel_thread>
    if (pid <= 0)
ffffffffc02048d0:	00a04563          	bgtz	a0,ffffffffc02048da <init_main+0x26>
ffffffffc02048d4:	a041                	j	ffffffffc0204954 <init_main+0xa0>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02048d6:	17b000ef          	jal	ra,ffffffffc0205250 <schedule>
    if (code_store != NULL)
ffffffffc02048da:	4581                	li	a1,0
ffffffffc02048dc:	4501                	li	a0,0
ffffffffc02048de:	e05ff0ef          	jal	ra,ffffffffc02046e2 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02048e2:	d975                	beqz	a0,ffffffffc02048d6 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02048e4:	00003517          	auipc	a0,0x3
ffffffffc02048e8:	93c50513          	addi	a0,a0,-1732 # ffffffffc0207220 <default_pmm_manager+0xb10>
ffffffffc02048ec:	8a9fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(
ffffffffc02048f0:	000a6797          	auipc	a5,0xa6
ffffffffc02048f4:	e987b783          	ld	a5,-360(a5) # ffffffffc02aa788 <initproc>
ffffffffc02048f8:	7bf8                	ld	a4,240(a5)
ffffffffc02048fa:	c30d                	beqz	a4,ffffffffc020491c <init_main+0x68>
ffffffffc02048fc:	00003697          	auipc	a3,0x3
ffffffffc0204900:	94c68693          	addi	a3,a3,-1716 # ffffffffc0207248 <default_pmm_manager+0xb38>
ffffffffc0204904:	00002617          	auipc	a2,0x2
ffffffffc0204908:	a5c60613          	addi	a2,a2,-1444 # ffffffffc0206360 <commands+0x868>
ffffffffc020490c:	3d400593          	li	a1,980
ffffffffc0204910:	00003517          	auipc	a0,0x3
ffffffffc0204914:	85050513          	addi	a0,a0,-1968 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0204918:	b77fb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc020491c:	7ff8                	ld	a4,248(a5)
ffffffffc020491e:	ff79                	bnez	a4,ffffffffc02048fc <init_main+0x48>
ffffffffc0204920:	1007b703          	ld	a4,256(a5)
ffffffffc0204924:	ff61                	bnez	a4,ffffffffc02048fc <init_main+0x48>
        initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
    assert(nr_process == 2);
ffffffffc0204926:	000a6697          	auipc	a3,0xa6
ffffffffc020492a:	e6a6a683          	lw	a3,-406(a3) # ffffffffc02aa790 <nr_process>
ffffffffc020492e:	4709                	li	a4,2
ffffffffc0204930:	02e68e63          	beq	a3,a4,ffffffffc020496c <init_main+0xb8>
ffffffffc0204934:	00003697          	auipc	a3,0x3
ffffffffc0204938:	96468693          	addi	a3,a3,-1692 # ffffffffc0207298 <default_pmm_manager+0xb88>
ffffffffc020493c:	00002617          	auipc	a2,0x2
ffffffffc0204940:	a2460613          	addi	a2,a2,-1500 # ffffffffc0206360 <commands+0x868>
ffffffffc0204944:	3d600593          	li	a1,982
ffffffffc0204948:	00003517          	auipc	a0,0x3
ffffffffc020494c:	81850513          	addi	a0,a0,-2024 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0204950:	b3ffb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204954:	00003617          	auipc	a2,0x3
ffffffffc0204958:	8ac60613          	addi	a2,a2,-1876 # ffffffffc0207200 <default_pmm_manager+0xaf0>
ffffffffc020495c:	3cb00593          	li	a1,971
ffffffffc0204960:	00003517          	auipc	a0,0x3
ffffffffc0204964:	80050513          	addi	a0,a0,-2048 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0204968:	b27fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc020496c:	000a6717          	auipc	a4,0xa6
ffffffffc0204970:	d8c70713          	addi	a4,a4,-628 # ffffffffc02aa6f8 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204974:	6714                	ld	a3,8(a4)
ffffffffc0204976:	0c878793          	addi	a5,a5,200
ffffffffc020497a:	02d78263          	beq	a5,a3,ffffffffc020499e <init_main+0xea>
ffffffffc020497e:	00003697          	auipc	a3,0x3
ffffffffc0204982:	92a68693          	addi	a3,a3,-1750 # ffffffffc02072a8 <default_pmm_manager+0xb98>
ffffffffc0204986:	00002617          	auipc	a2,0x2
ffffffffc020498a:	9da60613          	addi	a2,a2,-1574 # ffffffffc0206360 <commands+0x868>
ffffffffc020498e:	3d700593          	li	a1,983
ffffffffc0204992:	00002517          	auipc	a0,0x2
ffffffffc0204996:	7ce50513          	addi	a0,a0,1998 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc020499a:	af5fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020499e:	6318                	ld	a4,0(a4)
ffffffffc02049a0:	02e78263          	beq	a5,a4,ffffffffc02049c4 <init_main+0x110>
ffffffffc02049a4:	00003697          	auipc	a3,0x3
ffffffffc02049a8:	93468693          	addi	a3,a3,-1740 # ffffffffc02072d8 <default_pmm_manager+0xbc8>
ffffffffc02049ac:	00002617          	auipc	a2,0x2
ffffffffc02049b0:	9b460613          	addi	a2,a2,-1612 # ffffffffc0206360 <commands+0x868>
ffffffffc02049b4:	3d800593          	li	a1,984
ffffffffc02049b8:	00002517          	auipc	a0,0x2
ffffffffc02049bc:	7a850513          	addi	a0,a0,1960 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc02049c0:	acffb0ef          	jal	ra,ffffffffc020048e <__panic>

    cprintf("init check memory pass.\n");
ffffffffc02049c4:	00003517          	auipc	a0,0x3
ffffffffc02049c8:	94450513          	addi	a0,a0,-1724 # ffffffffc0207308 <default_pmm_manager+0xbf8>
ffffffffc02049cc:	fc8fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    // LAB5: initproc 不应退出，否则会触发 panic；保持调度占位
    while (1)
    {
        schedule();
ffffffffc02049d0:	081000ef          	jal	ra,ffffffffc0205250 <schedule>
    while (1)
ffffffffc02049d4:	bff5                	j	ffffffffc02049d0 <init_main+0x11c>

ffffffffc02049d6 <do_execve>:
{
ffffffffc02049d6:	7171                	addi	sp,sp,-176
ffffffffc02049d8:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02049da:	000a6d97          	auipc	s11,0xa6
ffffffffc02049de:	d9ed8d93          	addi	s11,s11,-610 # ffffffffc02aa778 <current>
ffffffffc02049e2:	000db783          	ld	a5,0(s11)
{
ffffffffc02049e6:	e94a                	sd	s2,144(sp)
ffffffffc02049e8:	f122                	sd	s0,160(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02049ea:	0287b903          	ld	s2,40(a5)
{
ffffffffc02049ee:	ed26                	sd	s1,152(sp)
ffffffffc02049f0:	f8da                	sd	s6,112(sp)
ffffffffc02049f2:	84aa                	mv	s1,a0
ffffffffc02049f4:	8b32                	mv	s6,a2
ffffffffc02049f6:	842e                	mv	s0,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02049f8:	862e                	mv	a2,a1
ffffffffc02049fa:	4681                	li	a3,0
ffffffffc02049fc:	85aa                	mv	a1,a0
ffffffffc02049fe:	854a                	mv	a0,s2
{
ffffffffc0204a00:	f506                	sd	ra,168(sp)
ffffffffc0204a02:	e54e                	sd	s3,136(sp)
ffffffffc0204a04:	e152                	sd	s4,128(sp)
ffffffffc0204a06:	fcd6                	sd	s5,120(sp)
ffffffffc0204a08:	f4de                	sd	s7,104(sp)
ffffffffc0204a0a:	f0e2                	sd	s8,96(sp)
ffffffffc0204a0c:	ece6                	sd	s9,88(sp)
ffffffffc0204a0e:	e8ea                	sd	s10,80(sp)
ffffffffc0204a10:	f05a                	sd	s6,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204a12:	cc6ff0ef          	jal	ra,ffffffffc0203ed8 <user_mem_check>
ffffffffc0204a16:	40050a63          	beqz	a0,ffffffffc0204e2a <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204a1a:	4641                	li	a2,16
ffffffffc0204a1c:	4581                	li	a1,0
ffffffffc0204a1e:	1808                	addi	a0,sp,48
ffffffffc0204a20:	643000ef          	jal	ra,ffffffffc0205862 <memset>
    memcpy(local_name, name, len);
ffffffffc0204a24:	47bd                	li	a5,15
ffffffffc0204a26:	8622                	mv	a2,s0
ffffffffc0204a28:	1e87e263          	bltu	a5,s0,ffffffffc0204c0c <do_execve+0x236>
ffffffffc0204a2c:	85a6                	mv	a1,s1
ffffffffc0204a2e:	1808                	addi	a0,sp,48
ffffffffc0204a30:	645000ef          	jal	ra,ffffffffc0205874 <memcpy>
    if (mm != NULL)
ffffffffc0204a34:	1e090363          	beqz	s2,ffffffffc0204c1a <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0204a38:	00002517          	auipc	a0,0x2
ffffffffc0204a3c:	4e850513          	addi	a0,a0,1256 # ffffffffc0206f20 <default_pmm_manager+0x810>
ffffffffc0204a40:	f8cfb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc0204a44:	000a6797          	auipc	a5,0xa6
ffffffffc0204a48:	cfc7b783          	ld	a5,-772(a5) # ffffffffc02aa740 <boot_pgdir_pa>
ffffffffc0204a4c:	577d                	li	a4,-1
ffffffffc0204a4e:	177e                	slli	a4,a4,0x3f
ffffffffc0204a50:	83b1                	srli	a5,a5,0xc
ffffffffc0204a52:	8fd9                	or	a5,a5,a4
ffffffffc0204a54:	18079073          	csrw	satp,a5
ffffffffc0204a58:	03092783          	lw	a5,48(s2) # ffffffff80000030 <_binary_obj___user_exit_out_size+0xffffffff7fff4f08>
ffffffffc0204a5c:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204a60:	02e92823          	sw	a4,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204a64:	2c070463          	beqz	a4,ffffffffc0204d2c <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204a68:	000db783          	ld	a5,0(s11)
ffffffffc0204a6c:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204a70:	c27fe0ef          	jal	ra,ffffffffc0203696 <mm_create>
ffffffffc0204a74:	842a                	mv	s0,a0
ffffffffc0204a76:	1c050d63          	beqz	a0,ffffffffc0204c50 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204a7a:	4505                	li	a0,1
ffffffffc0204a7c:	cc0fd0ef          	jal	ra,ffffffffc0201f3c <alloc_pages>
ffffffffc0204a80:	3a050963          	beqz	a0,ffffffffc0204e32 <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0204a84:	000a6c97          	auipc	s9,0xa6
ffffffffc0204a88:	cd4c8c93          	addi	s9,s9,-812 # ffffffffc02aa758 <pages>
ffffffffc0204a8c:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204a90:	000a6c17          	auipc	s8,0xa6
ffffffffc0204a94:	cc0c0c13          	addi	s8,s8,-832 # ffffffffc02aa750 <npage>
    return page - pages + nbase;
ffffffffc0204a98:	00003717          	auipc	a4,0x3
ffffffffc0204a9c:	f6073703          	ld	a4,-160(a4) # ffffffffc02079f8 <nbase>
ffffffffc0204aa0:	40d506b3          	sub	a3,a0,a3
ffffffffc0204aa4:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204aa6:	5a7d                	li	s4,-1
ffffffffc0204aa8:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204aac:	96ba                	add	a3,a3,a4
ffffffffc0204aae:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204ab0:	00ca5713          	srli	a4,s4,0xc
ffffffffc0204ab4:	ec3a                	sd	a4,24(sp)
ffffffffc0204ab6:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ab8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204aba:	38f77063          	bgeu	a4,a5,ffffffffc0204e3a <do_execve+0x464>
ffffffffc0204abe:	000a6a97          	auipc	s5,0xa6
ffffffffc0204ac2:	caaa8a93          	addi	s5,s5,-854 # ffffffffc02aa768 <va_pa_offset>
ffffffffc0204ac6:	000ab483          	ld	s1,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204aca:	6605                	lui	a2,0x1
ffffffffc0204acc:	000a6597          	auipc	a1,0xa6
ffffffffc0204ad0:	c7c5b583          	ld	a1,-900(a1) # ffffffffc02aa748 <boot_pgdir_va>
ffffffffc0204ad4:	94b6                	add	s1,s1,a3
ffffffffc0204ad6:	8526                	mv	a0,s1
ffffffffc0204ad8:	59d000ef          	jal	ra,ffffffffc0205874 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204adc:	7782                	ld	a5,32(sp)
ffffffffc0204ade:	4398                	lw	a4,0(a5)
ffffffffc0204ae0:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204ae4:	ec04                	sd	s1,24(s0)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204ae6:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9457>
ffffffffc0204aea:	14f71963          	bne	a4,a5,ffffffffc0204c3c <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204aee:	7682                	ld	a3,32(sp)
    struct Page *page = NULL;
ffffffffc0204af0:	4b81                	li	s7,0
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204af2:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204af6:	0206b903          	ld	s2,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204afa:	00371793          	slli	a5,a4,0x3
ffffffffc0204afe:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204b00:	9936                	add	s2,s2,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204b02:	078e                	slli	a5,a5,0x3
ffffffffc0204b04:	97ca                	add	a5,a5,s2
ffffffffc0204b06:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204b08:	00f97c63          	bgeu	s2,a5,ffffffffc0204b20 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204b0c:	00092783          	lw	a5,0(s2)
ffffffffc0204b10:	4705                	li	a4,1
ffffffffc0204b12:	14e78163          	beq	a5,a4,ffffffffc0204c54 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc0204b16:	77a2                	ld	a5,40(sp)
ffffffffc0204b18:	03890913          	addi	s2,s2,56
ffffffffc0204b1c:	fef968e3          	bltu	s2,a5,ffffffffc0204b0c <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204b20:	4701                	li	a4,0
ffffffffc0204b22:	46ad                	li	a3,11
ffffffffc0204b24:	00100637          	lui	a2,0x100
ffffffffc0204b28:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204b2c:	8522                	mv	a0,s0
ffffffffc0204b2e:	cfbfe0ef          	jal	ra,ffffffffc0203828 <mm_map>
ffffffffc0204b32:	89aa                	mv	s3,a0
ffffffffc0204b34:	1e051263          	bnez	a0,ffffffffc0204d18 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204b38:	6c08                	ld	a0,24(s0)
ffffffffc0204b3a:	467d                	li	a2,31
ffffffffc0204b3c:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204b40:	a71fe0ef          	jal	ra,ffffffffc02035b0 <pgdir_alloc_page>
ffffffffc0204b44:	38050363          	beqz	a0,ffffffffc0204eca <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b48:	6c08                	ld	a0,24(s0)
ffffffffc0204b4a:	467d                	li	a2,31
ffffffffc0204b4c:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204b50:	a61fe0ef          	jal	ra,ffffffffc02035b0 <pgdir_alloc_page>
ffffffffc0204b54:	34050b63          	beqz	a0,ffffffffc0204eaa <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b58:	6c08                	ld	a0,24(s0)
ffffffffc0204b5a:	467d                	li	a2,31
ffffffffc0204b5c:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204b60:	a51fe0ef          	jal	ra,ffffffffc02035b0 <pgdir_alloc_page>
ffffffffc0204b64:	32050363          	beqz	a0,ffffffffc0204e8a <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b68:	6c08                	ld	a0,24(s0)
ffffffffc0204b6a:	467d                	li	a2,31
ffffffffc0204b6c:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204b70:	a41fe0ef          	jal	ra,ffffffffc02035b0 <pgdir_alloc_page>
ffffffffc0204b74:	2e050b63          	beqz	a0,ffffffffc0204e6a <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204b78:	581c                	lw	a5,48(s0)
    current->mm = mm;
ffffffffc0204b7a:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b7e:	6c14                	ld	a3,24(s0)
ffffffffc0204b80:	2785                	addiw	a5,a5,1
ffffffffc0204b82:	d81c                	sw	a5,48(s0)
    current->mm = mm;
ffffffffc0204b84:	f600                	sd	s0,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b86:	c02007b7          	lui	a5,0xc0200
ffffffffc0204b8a:	2cf6e463          	bltu	a3,a5,ffffffffc0204e52 <do_execve+0x47c>
ffffffffc0204b8e:	000ab783          	ld	a5,0(s5)
ffffffffc0204b92:	577d                	li	a4,-1
ffffffffc0204b94:	177e                	slli	a4,a4,0x3f
ffffffffc0204b96:	8e9d                	sub	a3,a3,a5
ffffffffc0204b98:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204b9c:	f654                	sd	a3,168(a2)
ffffffffc0204b9e:	8fd9                	or	a5,a5,a4
ffffffffc0204ba0:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204ba4:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204ba6:	4581                	li	a1,0
ffffffffc0204ba8:	12000613          	li	a2,288
ffffffffc0204bac:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204bae:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204bb2:	4b1000ef          	jal	ra,ffffffffc0205862 <memset>
    tf->epc = elf->e_entry;                // entry address of user program
ffffffffc0204bb6:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bb8:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE; // return to U-mode with interrupts enabled after sret
ffffffffc0204bbc:	edd4f493          	andi	s1,s1,-291
    tf->epc = elf->e_entry;                // entry address of user program
ffffffffc0204bc0:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;                // user stack pointer
ffffffffc0204bc2:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bc4:	0b490913          	addi	s2,s2,180
    tf->gpr.sp = USTACKTOP;                // user stack pointer
ffffffffc0204bc8:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE; // return to U-mode with interrupts enabled after sret
ffffffffc0204bca:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bce:	4641                	li	a2,16
ffffffffc0204bd0:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;                // user stack pointer
ffffffffc0204bd2:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;                // entry address of user program
ffffffffc0204bd4:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE; // return to U-mode with interrupts enabled after sret
ffffffffc0204bd8:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bdc:	854a                	mv	a0,s2
ffffffffc0204bde:	485000ef          	jal	ra,ffffffffc0205862 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204be2:	463d                	li	a2,15
ffffffffc0204be4:	180c                	addi	a1,sp,48
ffffffffc0204be6:	854a                	mv	a0,s2
ffffffffc0204be8:	48d000ef          	jal	ra,ffffffffc0205874 <memcpy>
}
ffffffffc0204bec:	70aa                	ld	ra,168(sp)
ffffffffc0204bee:	740a                	ld	s0,160(sp)
ffffffffc0204bf0:	64ea                	ld	s1,152(sp)
ffffffffc0204bf2:	694a                	ld	s2,144(sp)
ffffffffc0204bf4:	6a0a                	ld	s4,128(sp)
ffffffffc0204bf6:	7ae6                	ld	s5,120(sp)
ffffffffc0204bf8:	7b46                	ld	s6,112(sp)
ffffffffc0204bfa:	7ba6                	ld	s7,104(sp)
ffffffffc0204bfc:	7c06                	ld	s8,96(sp)
ffffffffc0204bfe:	6ce6                	ld	s9,88(sp)
ffffffffc0204c00:	6d46                	ld	s10,80(sp)
ffffffffc0204c02:	6da6                	ld	s11,72(sp)
ffffffffc0204c04:	854e                	mv	a0,s3
ffffffffc0204c06:	69aa                	ld	s3,136(sp)
ffffffffc0204c08:	614d                	addi	sp,sp,176
ffffffffc0204c0a:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204c0c:	463d                	li	a2,15
ffffffffc0204c0e:	85a6                	mv	a1,s1
ffffffffc0204c10:	1808                	addi	a0,sp,48
ffffffffc0204c12:	463000ef          	jal	ra,ffffffffc0205874 <memcpy>
    if (mm != NULL)
ffffffffc0204c16:	e20911e3          	bnez	s2,ffffffffc0204a38 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204c1a:	000db783          	ld	a5,0(s11)
ffffffffc0204c1e:	779c                	ld	a5,40(a5)
ffffffffc0204c20:	e40788e3          	beqz	a5,ffffffffc0204a70 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204c24:	00002617          	auipc	a2,0x2
ffffffffc0204c28:	70460613          	addi	a2,a2,1796 # ffffffffc0207328 <default_pmm_manager+0xc18>
ffffffffc0204c2c:	25100593          	li	a1,593
ffffffffc0204c30:	00002517          	auipc	a0,0x2
ffffffffc0204c34:	53050513          	addi	a0,a0,1328 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0204c38:	857fb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204c3c:	8522                	mv	a0,s0
ffffffffc0204c3e:	c3eff0ef          	jal	ra,ffffffffc020407c <put_pgdir>
    mm_destroy(mm);
ffffffffc0204c42:	8522                	mv	a0,s0
ffffffffc0204c44:	b93fe0ef          	jal	ra,ffffffffc02037d6 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204c48:	59e1                	li	s3,-8
    do_exit(ret);
ffffffffc0204c4a:	854e                	mv	a0,s3
ffffffffc0204c4c:	94dff0ef          	jal	ra,ffffffffc0204598 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204c50:	59f1                	li	s3,-4
ffffffffc0204c52:	bfe5                	j	ffffffffc0204c4a <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204c54:	02893603          	ld	a2,40(s2)
ffffffffc0204c58:	02093783          	ld	a5,32(s2)
ffffffffc0204c5c:	1cf66d63          	bltu	a2,a5,ffffffffc0204e36 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204c60:	00492783          	lw	a5,4(s2)
ffffffffc0204c64:	0017f693          	andi	a3,a5,1
ffffffffc0204c68:	c291                	beqz	a3,ffffffffc0204c6c <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204c6a:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c6c:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c70:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c72:	e779                	bnez	a4,ffffffffc0204d40 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204c74:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c76:	c781                	beqz	a5,ffffffffc0204c7e <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204c78:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204c7c:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204c7e:	0026f793          	andi	a5,a3,2
ffffffffc0204c82:	e3f1                	bnez	a5,ffffffffc0204d46 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204c84:	0046f793          	andi	a5,a3,4
ffffffffc0204c88:	c399                	beqz	a5,ffffffffc0204c8e <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204c8a:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204c8e:	01093583          	ld	a1,16(s2)
ffffffffc0204c92:	4701                	li	a4,0
ffffffffc0204c94:	8522                	mv	a0,s0
ffffffffc0204c96:	b93fe0ef          	jal	ra,ffffffffc0203828 <mm_map>
ffffffffc0204c9a:	89aa                	mv	s3,a0
ffffffffc0204c9c:	ed35                	bnez	a0,ffffffffc0204d18 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204c9e:	01093b03          	ld	s6,16(s2)
ffffffffc0204ca2:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204ca4:	02093983          	ld	s3,32(s2)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204ca8:	00893483          	ld	s1,8(s2)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204cac:	00fb7a33          	and	s4,s6,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204cb0:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204cb2:	99da                	add	s3,s3,s6
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204cb4:	94be                	add	s1,s1,a5
        while (start < end)
ffffffffc0204cb6:	053b6963          	bltu	s6,s3,ffffffffc0204d08 <do_execve+0x332>
ffffffffc0204cba:	aa95                	j	ffffffffc0204e2e <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204cbc:	6785                	lui	a5,0x1
ffffffffc0204cbe:	414b0533          	sub	a0,s6,s4
ffffffffc0204cc2:	9a3e                	add	s4,s4,a5
ffffffffc0204cc4:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc0204cc8:	0149f463          	bgeu	s3,s4,ffffffffc0204cd0 <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204ccc:	41698633          	sub	a2,s3,s6
    return page - pages + nbase;
ffffffffc0204cd0:	000cb683          	ld	a3,0(s9)
ffffffffc0204cd4:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204cd6:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204cda:	40db86b3          	sub	a3,s7,a3
ffffffffc0204cde:	8699                	srai	a3,a3,0x6
ffffffffc0204ce0:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204ce2:	67e2                	ld	a5,24(sp)
ffffffffc0204ce4:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ce8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204cea:	14b8f863          	bgeu	a7,a1,ffffffffc0204e3a <do_execve+0x464>
ffffffffc0204cee:	000ab883          	ld	a7,0(s5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204cf2:	85a6                	mv	a1,s1
            start += size, from += size;
ffffffffc0204cf4:	9b32                	add	s6,s6,a2
ffffffffc0204cf6:	96c6                	add	a3,a3,a7
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204cf8:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204cfa:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204cfc:	379000ef          	jal	ra,ffffffffc0205874 <memcpy>
            start += size, from += size;
ffffffffc0204d00:	6622                	ld	a2,8(sp)
ffffffffc0204d02:	94b2                	add	s1,s1,a2
        while (start < end)
ffffffffc0204d04:	053b7363          	bgeu	s6,s3,ffffffffc0204d4a <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204d08:	6c08                	ld	a0,24(s0)
ffffffffc0204d0a:	866a                	mv	a2,s10
ffffffffc0204d0c:	85d2                	mv	a1,s4
ffffffffc0204d0e:	8a3fe0ef          	jal	ra,ffffffffc02035b0 <pgdir_alloc_page>
ffffffffc0204d12:	8baa                	mv	s7,a0
ffffffffc0204d14:	f545                	bnez	a0,ffffffffc0204cbc <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204d16:	59f1                	li	s3,-4
    exit_mmap(mm);
ffffffffc0204d18:	8522                	mv	a0,s0
ffffffffc0204d1a:	c59fe0ef          	jal	ra,ffffffffc0203972 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204d1e:	8522                	mv	a0,s0
ffffffffc0204d20:	b5cff0ef          	jal	ra,ffffffffc020407c <put_pgdir>
    mm_destroy(mm);
ffffffffc0204d24:	8522                	mv	a0,s0
ffffffffc0204d26:	ab1fe0ef          	jal	ra,ffffffffc02037d6 <mm_destroy>
    return ret;
ffffffffc0204d2a:	b705                	j	ffffffffc0204c4a <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204d2c:	854a                	mv	a0,s2
ffffffffc0204d2e:	c45fe0ef          	jal	ra,ffffffffc0203972 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204d32:	854a                	mv	a0,s2
ffffffffc0204d34:	b48ff0ef          	jal	ra,ffffffffc020407c <put_pgdir>
            mm_destroy(mm);
ffffffffc0204d38:	854a                	mv	a0,s2
ffffffffc0204d3a:	a9dfe0ef          	jal	ra,ffffffffc02037d6 <mm_destroy>
ffffffffc0204d3e:	b32d                	j	ffffffffc0204a68 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204d40:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204d44:	fb95                	bnez	a5,ffffffffc0204c78 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204d46:	4d5d                	li	s10,23
ffffffffc0204d48:	bf35                	j	ffffffffc0204c84 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204d4a:	01093483          	ld	s1,16(s2)
ffffffffc0204d4e:	02893683          	ld	a3,40(s2)
ffffffffc0204d52:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204d54:	074b7d63          	bgeu	s6,s4,ffffffffc0204dce <do_execve+0x3f8>
            if (start == end)
ffffffffc0204d58:	db648fe3          	beq	s1,s6,ffffffffc0204b16 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204d5c:	6785                	lui	a5,0x1
ffffffffc0204d5e:	00fb0533          	add	a0,s6,a5
ffffffffc0204d62:	41450533          	sub	a0,a0,s4
                size -= la - end;
ffffffffc0204d66:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204d6a:	0b44fd63          	bgeu	s1,s4,ffffffffc0204e24 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204d6e:	000cb683          	ld	a3,0(s9)
ffffffffc0204d72:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204d74:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204d78:	40db86b3          	sub	a3,s7,a3
ffffffffc0204d7c:	8699                	srai	a3,a3,0x6
ffffffffc0204d7e:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204d80:	67e2                	ld	a5,24(sp)
ffffffffc0204d82:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d86:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d88:	0ac5f963          	bgeu	a1,a2,ffffffffc0204e3a <do_execve+0x464>
ffffffffc0204d8c:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d90:	864e                	mv	a2,s3
ffffffffc0204d92:	4581                	li	a1,0
ffffffffc0204d94:	96c6                	add	a3,a3,a7
ffffffffc0204d96:	9536                	add	a0,a0,a3
ffffffffc0204d98:	2cb000ef          	jal	ra,ffffffffc0205862 <memset>
            start += size;
ffffffffc0204d9c:	01698733          	add	a4,s3,s6
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204da0:	0344f463          	bgeu	s1,s4,ffffffffc0204dc8 <do_execve+0x3f2>
ffffffffc0204da4:	d6e489e3          	beq	s1,a4,ffffffffc0204b16 <do_execve+0x140>
ffffffffc0204da8:	00002697          	auipc	a3,0x2
ffffffffc0204dac:	5a868693          	addi	a3,a3,1448 # ffffffffc0207350 <default_pmm_manager+0xc40>
ffffffffc0204db0:	00001617          	auipc	a2,0x1
ffffffffc0204db4:	5b060613          	addi	a2,a2,1456 # ffffffffc0206360 <commands+0x868>
ffffffffc0204db8:	2ba00593          	li	a1,698
ffffffffc0204dbc:	00002517          	auipc	a0,0x2
ffffffffc0204dc0:	3a450513          	addi	a0,a0,932 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0204dc4:	ecafb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204dc8:	ff4710e3          	bne	a4,s4,ffffffffc0204da8 <do_execve+0x3d2>
ffffffffc0204dcc:	8b52                	mv	s6,s4
        while (start < end)
ffffffffc0204dce:	d49b74e3          	bgeu	s6,s1,ffffffffc0204b16 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204dd2:	6c08                	ld	a0,24(s0)
ffffffffc0204dd4:	866a                	mv	a2,s10
ffffffffc0204dd6:	85d2                	mv	a1,s4
ffffffffc0204dd8:	fd8fe0ef          	jal	ra,ffffffffc02035b0 <pgdir_alloc_page>
ffffffffc0204ddc:	8baa                	mv	s7,a0
ffffffffc0204dde:	dd05                	beqz	a0,ffffffffc0204d16 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204de0:	6785                	lui	a5,0x1
ffffffffc0204de2:	414b0533          	sub	a0,s6,s4
ffffffffc0204de6:	9a3e                	add	s4,s4,a5
ffffffffc0204de8:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc0204dec:	0144f463          	bgeu	s1,s4,ffffffffc0204df4 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204df0:	41648633          	sub	a2,s1,s6
    return page - pages + nbase;
ffffffffc0204df4:	000cb683          	ld	a3,0(s9)
ffffffffc0204df8:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204dfa:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204dfe:	40db86b3          	sub	a3,s7,a3
ffffffffc0204e02:	8699                	srai	a3,a3,0x6
ffffffffc0204e04:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204e06:	67e2                	ld	a5,24(sp)
ffffffffc0204e08:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e0c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204e0e:	02b8f663          	bgeu	a7,a1,ffffffffc0204e3a <do_execve+0x464>
ffffffffc0204e12:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204e16:	4581                	li	a1,0
            start += size;
ffffffffc0204e18:	9b32                	add	s6,s6,a2
ffffffffc0204e1a:	96c6                	add	a3,a3,a7
            memset(page2kva(page) + off, 0, size);
ffffffffc0204e1c:	9536                	add	a0,a0,a3
ffffffffc0204e1e:	245000ef          	jal	ra,ffffffffc0205862 <memset>
ffffffffc0204e22:	b775                	j	ffffffffc0204dce <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204e24:	416a09b3          	sub	s3,s4,s6
ffffffffc0204e28:	b799                	j	ffffffffc0204d6e <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204e2a:	59f5                	li	s3,-3
ffffffffc0204e2c:	b3c1                	j	ffffffffc0204bec <do_execve+0x216>
        while (start < end)
ffffffffc0204e2e:	84da                	mv	s1,s6
ffffffffc0204e30:	bf39                	j	ffffffffc0204d4e <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204e32:	59f1                	li	s3,-4
ffffffffc0204e34:	bdc5                	j	ffffffffc0204d24 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204e36:	59e1                	li	s3,-8
ffffffffc0204e38:	b5c5                	j	ffffffffc0204d18 <do_execve+0x342>
ffffffffc0204e3a:	00002617          	auipc	a2,0x2
ffffffffc0204e3e:	90e60613          	addi	a2,a2,-1778 # ffffffffc0206748 <default_pmm_manager+0x38>
ffffffffc0204e42:	07100593          	li	a1,113
ffffffffc0204e46:	00002517          	auipc	a0,0x2
ffffffffc0204e4a:	92a50513          	addi	a0,a0,-1750 # ffffffffc0206770 <default_pmm_manager+0x60>
ffffffffc0204e4e:	e40fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204e52:	00002617          	auipc	a2,0x2
ffffffffc0204e56:	99e60613          	addi	a2,a2,-1634 # ffffffffc02067f0 <default_pmm_manager+0xe0>
ffffffffc0204e5a:	2d900593          	li	a1,729
ffffffffc0204e5e:	00002517          	auipc	a0,0x2
ffffffffc0204e62:	30250513          	addi	a0,a0,770 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0204e66:	e28fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e6a:	00002697          	auipc	a3,0x2
ffffffffc0204e6e:	5fe68693          	addi	a3,a3,1534 # ffffffffc0207468 <default_pmm_manager+0xd58>
ffffffffc0204e72:	00001617          	auipc	a2,0x1
ffffffffc0204e76:	4ee60613          	addi	a2,a2,1262 # ffffffffc0206360 <commands+0x868>
ffffffffc0204e7a:	2d400593          	li	a1,724
ffffffffc0204e7e:	00002517          	auipc	a0,0x2
ffffffffc0204e82:	2e250513          	addi	a0,a0,738 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0204e86:	e08fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e8a:	00002697          	auipc	a3,0x2
ffffffffc0204e8e:	59668693          	addi	a3,a3,1430 # ffffffffc0207420 <default_pmm_manager+0xd10>
ffffffffc0204e92:	00001617          	auipc	a2,0x1
ffffffffc0204e96:	4ce60613          	addi	a2,a2,1230 # ffffffffc0206360 <commands+0x868>
ffffffffc0204e9a:	2d300593          	li	a1,723
ffffffffc0204e9e:	00002517          	auipc	a0,0x2
ffffffffc0204ea2:	2c250513          	addi	a0,a0,706 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0204ea6:	de8fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204eaa:	00002697          	auipc	a3,0x2
ffffffffc0204eae:	52e68693          	addi	a3,a3,1326 # ffffffffc02073d8 <default_pmm_manager+0xcc8>
ffffffffc0204eb2:	00001617          	auipc	a2,0x1
ffffffffc0204eb6:	4ae60613          	addi	a2,a2,1198 # ffffffffc0206360 <commands+0x868>
ffffffffc0204eba:	2d200593          	li	a1,722
ffffffffc0204ebe:	00002517          	auipc	a0,0x2
ffffffffc0204ec2:	2a250513          	addi	a0,a0,674 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0204ec6:	dc8fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204eca:	00002697          	auipc	a3,0x2
ffffffffc0204ece:	4c668693          	addi	a3,a3,1222 # ffffffffc0207390 <default_pmm_manager+0xc80>
ffffffffc0204ed2:	00001617          	auipc	a2,0x1
ffffffffc0204ed6:	48e60613          	addi	a2,a2,1166 # ffffffffc0206360 <commands+0x868>
ffffffffc0204eda:	2d100593          	li	a1,721
ffffffffc0204ede:	00002517          	auipc	a0,0x2
ffffffffc0204ee2:	28250513          	addi	a0,a0,642 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0204ee6:	da8fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204eea <do_yield>:
    current->need_resched = 1;
ffffffffc0204eea:	000a6797          	auipc	a5,0xa6
ffffffffc0204eee:	88e7b783          	ld	a5,-1906(a5) # ffffffffc02aa778 <current>
ffffffffc0204ef2:	4705                	li	a4,1
ffffffffc0204ef4:	ef98                	sd	a4,24(a5)
}
ffffffffc0204ef6:	4501                	li	a0,0
ffffffffc0204ef8:	8082                	ret

ffffffffc0204efa <do_wait>:
{
ffffffffc0204efa:	1101                	addi	sp,sp,-32
ffffffffc0204efc:	e822                	sd	s0,16(sp)
ffffffffc0204efe:	e426                	sd	s1,8(sp)
ffffffffc0204f00:	ec06                	sd	ra,24(sp)
ffffffffc0204f02:	842e                	mv	s0,a1
ffffffffc0204f04:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204f06:	c999                	beqz	a1,ffffffffc0204f1c <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204f08:	000a6797          	auipc	a5,0xa6
ffffffffc0204f0c:	8707b783          	ld	a5,-1936(a5) # ffffffffc02aa778 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204f10:	7788                	ld	a0,40(a5)
ffffffffc0204f12:	4685                	li	a3,1
ffffffffc0204f14:	4611                	li	a2,4
ffffffffc0204f16:	fc3fe0ef          	jal	ra,ffffffffc0203ed8 <user_mem_check>
ffffffffc0204f1a:	c909                	beqz	a0,ffffffffc0204f2c <do_wait+0x32>
ffffffffc0204f1c:	85a2                	mv	a1,s0
}
ffffffffc0204f1e:	6442                	ld	s0,16(sp)
ffffffffc0204f20:	60e2                	ld	ra,24(sp)
ffffffffc0204f22:	8526                	mv	a0,s1
ffffffffc0204f24:	64a2                	ld	s1,8(sp)
ffffffffc0204f26:	6105                	addi	sp,sp,32
ffffffffc0204f28:	fbaff06f          	j	ffffffffc02046e2 <do_wait.part.0>
ffffffffc0204f2c:	60e2                	ld	ra,24(sp)
ffffffffc0204f2e:	6442                	ld	s0,16(sp)
ffffffffc0204f30:	64a2                	ld	s1,8(sp)
ffffffffc0204f32:	5575                	li	a0,-3
ffffffffc0204f34:	6105                	addi	sp,sp,32
ffffffffc0204f36:	8082                	ret

ffffffffc0204f38 <do_kill>:
{
ffffffffc0204f38:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f3a:	6789                	lui	a5,0x2
{
ffffffffc0204f3c:	e406                	sd	ra,8(sp)
ffffffffc0204f3e:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f40:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204f44:	17f9                	addi	a5,a5,-2
ffffffffc0204f46:	02e7e963          	bltu	a5,a4,ffffffffc0204f78 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f4a:	842a                	mv	s0,a0
ffffffffc0204f4c:	45a9                	li	a1,10
ffffffffc0204f4e:	2501                	sext.w	a0,a0
ffffffffc0204f50:	46c000ef          	jal	ra,ffffffffc02053bc <hash32>
ffffffffc0204f54:	02051793          	slli	a5,a0,0x20
ffffffffc0204f58:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204f5c:	000a1797          	auipc	a5,0xa1
ffffffffc0204f60:	79c78793          	addi	a5,a5,1948 # ffffffffc02a66f8 <hash_list>
ffffffffc0204f64:	953e                	add	a0,a0,a5
ffffffffc0204f66:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204f68:	a029                	j	ffffffffc0204f72 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204f6a:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204f6e:	00870b63          	beq	a4,s0,ffffffffc0204f84 <do_kill+0x4c>
ffffffffc0204f72:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204f74:	fef51be3          	bne	a0,a5,ffffffffc0204f6a <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204f78:	5475                	li	s0,-3
}
ffffffffc0204f7a:	60a2                	ld	ra,8(sp)
ffffffffc0204f7c:	8522                	mv	a0,s0
ffffffffc0204f7e:	6402                	ld	s0,0(sp)
ffffffffc0204f80:	0141                	addi	sp,sp,16
ffffffffc0204f82:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204f84:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204f88:	00177693          	andi	a3,a4,1
ffffffffc0204f8c:	e295                	bnez	a3,ffffffffc0204fb0 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f8e:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204f90:	00176713          	ori	a4,a4,1
ffffffffc0204f94:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204f98:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f9a:	fe06d0e3          	bgez	a3,ffffffffc0204f7a <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204f9e:	f2878513          	addi	a0,a5,-216
ffffffffc0204fa2:	22e000ef          	jal	ra,ffffffffc02051d0 <wakeup_proc>
}
ffffffffc0204fa6:	60a2                	ld	ra,8(sp)
ffffffffc0204fa8:	8522                	mv	a0,s0
ffffffffc0204faa:	6402                	ld	s0,0(sp)
ffffffffc0204fac:	0141                	addi	sp,sp,16
ffffffffc0204fae:	8082                	ret
        return -E_KILLED;
ffffffffc0204fb0:	545d                	li	s0,-9
ffffffffc0204fb2:	b7e1                	j	ffffffffc0204f7a <do_kill+0x42>

ffffffffc0204fb4 <proc_init>:
}

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204fb4:	1101                	addi	sp,sp,-32
ffffffffc0204fb6:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204fb8:	000a5797          	auipc	a5,0xa5
ffffffffc0204fbc:	74078793          	addi	a5,a5,1856 # ffffffffc02aa6f8 <proc_list>
ffffffffc0204fc0:	ec06                	sd	ra,24(sp)
ffffffffc0204fc2:	e822                	sd	s0,16(sp)
ffffffffc0204fc4:	e04a                	sd	s2,0(sp)
ffffffffc0204fc6:	000a1497          	auipc	s1,0xa1
ffffffffc0204fca:	73248493          	addi	s1,s1,1842 # ffffffffc02a66f8 <hash_list>
ffffffffc0204fce:	e79c                	sd	a5,8(a5)
ffffffffc0204fd0:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204fd2:	000a5717          	auipc	a4,0xa5
ffffffffc0204fd6:	72670713          	addi	a4,a4,1830 # ffffffffc02aa6f8 <proc_list>
ffffffffc0204fda:	87a6                	mv	a5,s1
ffffffffc0204fdc:	e79c                	sd	a5,8(a5)
ffffffffc0204fde:	e39c                	sd	a5,0(a5)
ffffffffc0204fe0:	07c1                	addi	a5,a5,16
ffffffffc0204fe2:	fef71de3          	bne	a4,a5,ffffffffc0204fdc <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204fe6:	f8ffe0ef          	jal	ra,ffffffffc0203f74 <alloc_proc>
ffffffffc0204fea:	000a5917          	auipc	s2,0xa5
ffffffffc0204fee:	79690913          	addi	s2,s2,1942 # ffffffffc02aa780 <idleproc>
ffffffffc0204ff2:	00a93023          	sd	a0,0(s2)
ffffffffc0204ff6:	0e050f63          	beqz	a0,ffffffffc02050f4 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204ffa:	4789                	li	a5,2
ffffffffc0204ffc:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204ffe:	00003797          	auipc	a5,0x3
ffffffffc0205002:	00278793          	addi	a5,a5,2 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205006:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc020500a:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc020500c:	4785                	li	a5,1
ffffffffc020500e:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205010:	4641                	li	a2,16
ffffffffc0205012:	4581                	li	a1,0
ffffffffc0205014:	8522                	mv	a0,s0
ffffffffc0205016:	04d000ef          	jal	ra,ffffffffc0205862 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020501a:	463d                	li	a2,15
ffffffffc020501c:	00002597          	auipc	a1,0x2
ffffffffc0205020:	4ac58593          	addi	a1,a1,1196 # ffffffffc02074c8 <default_pmm_manager+0xdb8>
ffffffffc0205024:	8522                	mv	a0,s0
ffffffffc0205026:	04f000ef          	jal	ra,ffffffffc0205874 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc020502a:	000a5717          	auipc	a4,0xa5
ffffffffc020502e:	76670713          	addi	a4,a4,1894 # ffffffffc02aa790 <nr_process>
ffffffffc0205032:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0205034:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205038:	4601                	li	a2,0
    nr_process++;
ffffffffc020503a:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020503c:	4581                	li	a1,0
ffffffffc020503e:	00000517          	auipc	a0,0x0
ffffffffc0205042:	87650513          	addi	a0,a0,-1930 # ffffffffc02048b4 <init_main>
    nr_process++;
ffffffffc0205046:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205048:	000a5797          	auipc	a5,0xa5
ffffffffc020504c:	72d7b823          	sd	a3,1840(a5) # ffffffffc02aa778 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205050:	cf8ff0ef          	jal	ra,ffffffffc0204548 <kernel_thread>
ffffffffc0205054:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0205056:	08a05363          	blez	a0,ffffffffc02050dc <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc020505a:	6789                	lui	a5,0x2
ffffffffc020505c:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205060:	17f9                	addi	a5,a5,-2
ffffffffc0205062:	2501                	sext.w	a0,a0
ffffffffc0205064:	02e7e363          	bltu	a5,a4,ffffffffc020508a <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205068:	45a9                	li	a1,10
ffffffffc020506a:	352000ef          	jal	ra,ffffffffc02053bc <hash32>
ffffffffc020506e:	02051793          	slli	a5,a0,0x20
ffffffffc0205072:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205076:	96a6                	add	a3,a3,s1
ffffffffc0205078:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc020507a:	a029                	j	ffffffffc0205084 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc020507c:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c84>
ffffffffc0205080:	04870b63          	beq	a4,s0,ffffffffc02050d6 <proc_init+0x122>
    return listelm->next;
ffffffffc0205084:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205086:	fef69be3          	bne	a3,a5,ffffffffc020507c <proc_init+0xc8>
    return NULL;
ffffffffc020508a:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020508c:	0b478493          	addi	s1,a5,180
ffffffffc0205090:	4641                	li	a2,16
ffffffffc0205092:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205094:	000a5417          	auipc	s0,0xa5
ffffffffc0205098:	6f440413          	addi	s0,s0,1780 # ffffffffc02aa788 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020509c:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc020509e:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050a0:	7c2000ef          	jal	ra,ffffffffc0205862 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02050a4:	463d                	li	a2,15
ffffffffc02050a6:	00002597          	auipc	a1,0x2
ffffffffc02050aa:	44a58593          	addi	a1,a1,1098 # ffffffffc02074f0 <default_pmm_manager+0xde0>
ffffffffc02050ae:	8526                	mv	a0,s1
ffffffffc02050b0:	7c4000ef          	jal	ra,ffffffffc0205874 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02050b4:	00093783          	ld	a5,0(s2)
ffffffffc02050b8:	cbb5                	beqz	a5,ffffffffc020512c <proc_init+0x178>
ffffffffc02050ba:	43dc                	lw	a5,4(a5)
ffffffffc02050bc:	eba5                	bnez	a5,ffffffffc020512c <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02050be:	601c                	ld	a5,0(s0)
ffffffffc02050c0:	c7b1                	beqz	a5,ffffffffc020510c <proc_init+0x158>
ffffffffc02050c2:	43d8                	lw	a4,4(a5)
ffffffffc02050c4:	4785                	li	a5,1
ffffffffc02050c6:	04f71363          	bne	a4,a5,ffffffffc020510c <proc_init+0x158>
}
ffffffffc02050ca:	60e2                	ld	ra,24(sp)
ffffffffc02050cc:	6442                	ld	s0,16(sp)
ffffffffc02050ce:	64a2                	ld	s1,8(sp)
ffffffffc02050d0:	6902                	ld	s2,0(sp)
ffffffffc02050d2:	6105                	addi	sp,sp,32
ffffffffc02050d4:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02050d6:	f2878793          	addi	a5,a5,-216
ffffffffc02050da:	bf4d                	j	ffffffffc020508c <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc02050dc:	00002617          	auipc	a2,0x2
ffffffffc02050e0:	3f460613          	addi	a2,a2,1012 # ffffffffc02074d0 <default_pmm_manager+0xdc0>
ffffffffc02050e4:	3ff00593          	li	a1,1023
ffffffffc02050e8:	00002517          	auipc	a0,0x2
ffffffffc02050ec:	07850513          	addi	a0,a0,120 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc02050f0:	b9efb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc02050f4:	00002617          	auipc	a2,0x2
ffffffffc02050f8:	3bc60613          	addi	a2,a2,956 # ffffffffc02074b0 <default_pmm_manager+0xda0>
ffffffffc02050fc:	3f000593          	li	a1,1008
ffffffffc0205100:	00002517          	auipc	a0,0x2
ffffffffc0205104:	06050513          	addi	a0,a0,96 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0205108:	b86fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020510c:	00002697          	auipc	a3,0x2
ffffffffc0205110:	41468693          	addi	a3,a3,1044 # ffffffffc0207520 <default_pmm_manager+0xe10>
ffffffffc0205114:	00001617          	auipc	a2,0x1
ffffffffc0205118:	24c60613          	addi	a2,a2,588 # ffffffffc0206360 <commands+0x868>
ffffffffc020511c:	40600593          	li	a1,1030
ffffffffc0205120:	00002517          	auipc	a0,0x2
ffffffffc0205124:	04050513          	addi	a0,a0,64 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0205128:	b66fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020512c:	00002697          	auipc	a3,0x2
ffffffffc0205130:	3cc68693          	addi	a3,a3,972 # ffffffffc02074f8 <default_pmm_manager+0xde8>
ffffffffc0205134:	00001617          	auipc	a2,0x1
ffffffffc0205138:	22c60613          	addi	a2,a2,556 # ffffffffc0206360 <commands+0x868>
ffffffffc020513c:	40500593          	li	a1,1029
ffffffffc0205140:	00002517          	auipc	a0,0x2
ffffffffc0205144:	02050513          	addi	a0,a0,32 # ffffffffc0207160 <default_pmm_manager+0xa50>
ffffffffc0205148:	b46fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020514c <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc020514c:	1141                	addi	sp,sp,-16
ffffffffc020514e:	e022                	sd	s0,0(sp)
ffffffffc0205150:	e406                	sd	ra,8(sp)
ffffffffc0205152:	000a5417          	auipc	s0,0xa5
ffffffffc0205156:	62640413          	addi	s0,s0,1574 # ffffffffc02aa778 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc020515a:	6018                	ld	a4,0(s0)
ffffffffc020515c:	6f1c                	ld	a5,24(a4)
ffffffffc020515e:	dffd                	beqz	a5,ffffffffc020515c <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205160:	0f0000ef          	jal	ra,ffffffffc0205250 <schedule>
ffffffffc0205164:	bfdd                	j	ffffffffc020515a <cpu_idle+0xe>

ffffffffc0205166 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205166:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc020516a:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc020516e:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205170:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205172:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205176:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc020517a:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc020517e:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0205182:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205186:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc020518a:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc020518e:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0205192:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205196:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc020519a:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020519e:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02051a2:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02051a4:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02051a6:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02051aa:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02051ae:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02051b2:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02051b6:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02051ba:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02051be:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02051c2:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02051c6:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02051ca:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02051ce:	8082                	ret

ffffffffc02051d0 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051d0:	4118                	lw	a4,0(a0)
{
ffffffffc02051d2:	1101                	addi	sp,sp,-32
ffffffffc02051d4:	ec06                	sd	ra,24(sp)
ffffffffc02051d6:	e822                	sd	s0,16(sp)
ffffffffc02051d8:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051da:	478d                	li	a5,3
ffffffffc02051dc:	04f70b63          	beq	a4,a5,ffffffffc0205232 <wakeup_proc+0x62>
ffffffffc02051e0:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02051e2:	100027f3          	csrr	a5,sstatus
ffffffffc02051e6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02051e8:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02051ea:	ef9d                	bnez	a5,ffffffffc0205228 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02051ec:	4789                	li	a5,2
ffffffffc02051ee:	02f70163          	beq	a4,a5,ffffffffc0205210 <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc02051f2:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc02051f4:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc02051f8:	e491                	bnez	s1,ffffffffc0205204 <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02051fa:	60e2                	ld	ra,24(sp)
ffffffffc02051fc:	6442                	ld	s0,16(sp)
ffffffffc02051fe:	64a2                	ld	s1,8(sp)
ffffffffc0205200:	6105                	addi	sp,sp,32
ffffffffc0205202:	8082                	ret
ffffffffc0205204:	6442                	ld	s0,16(sp)
ffffffffc0205206:	60e2                	ld	ra,24(sp)
ffffffffc0205208:	64a2                	ld	s1,8(sp)
ffffffffc020520a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020520c:	fa2fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205210:	00002617          	auipc	a2,0x2
ffffffffc0205214:	37060613          	addi	a2,a2,880 # ffffffffc0207580 <default_pmm_manager+0xe70>
ffffffffc0205218:	45d1                	li	a1,20
ffffffffc020521a:	00002517          	auipc	a0,0x2
ffffffffc020521e:	34e50513          	addi	a0,a0,846 # ffffffffc0207568 <default_pmm_manager+0xe58>
ffffffffc0205222:	ad4fb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc0205226:	bfc9                	j	ffffffffc02051f8 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205228:	f8cfb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc020522c:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc020522e:	4485                	li	s1,1
ffffffffc0205230:	bf75                	j	ffffffffc02051ec <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205232:	00002697          	auipc	a3,0x2
ffffffffc0205236:	31668693          	addi	a3,a3,790 # ffffffffc0207548 <default_pmm_manager+0xe38>
ffffffffc020523a:	00001617          	auipc	a2,0x1
ffffffffc020523e:	12660613          	addi	a2,a2,294 # ffffffffc0206360 <commands+0x868>
ffffffffc0205242:	45a5                	li	a1,9
ffffffffc0205244:	00002517          	auipc	a0,0x2
ffffffffc0205248:	32450513          	addi	a0,a0,804 # ffffffffc0207568 <default_pmm_manager+0xe58>
ffffffffc020524c:	a42fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205250 <schedule>:

void schedule(void)
{
ffffffffc0205250:	1141                	addi	sp,sp,-16
ffffffffc0205252:	e406                	sd	ra,8(sp)
ffffffffc0205254:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205256:	100027f3          	csrr	a5,sstatus
ffffffffc020525a:	8b89                	andi	a5,a5,2
ffffffffc020525c:	4401                	li	s0,0
ffffffffc020525e:	efbd                	bnez	a5,ffffffffc02052dc <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205260:	000a5897          	auipc	a7,0xa5
ffffffffc0205264:	5188b883          	ld	a7,1304(a7) # ffffffffc02aa778 <current>
ffffffffc0205268:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020526c:	000a5517          	auipc	a0,0xa5
ffffffffc0205270:	51453503          	ld	a0,1300(a0) # ffffffffc02aa780 <idleproc>
ffffffffc0205274:	04a88e63          	beq	a7,a0,ffffffffc02052d0 <schedule+0x80>
ffffffffc0205278:	0c888693          	addi	a3,a7,200
ffffffffc020527c:	000a5617          	auipc	a2,0xa5
ffffffffc0205280:	47c60613          	addi	a2,a2,1148 # ffffffffc02aa6f8 <proc_list>
        le = last;
ffffffffc0205284:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205286:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc0205288:	4809                	li	a6,2
ffffffffc020528a:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc020528c:	00c78863          	beq	a5,a2,ffffffffc020529c <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc0205290:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0205294:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205298:	03070163          	beq	a4,a6,ffffffffc02052ba <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc020529c:	fef697e3          	bne	a3,a5,ffffffffc020528a <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02052a0:	ed89                	bnez	a1,ffffffffc02052ba <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02052a2:	451c                	lw	a5,8(a0)
ffffffffc02052a4:	2785                	addiw	a5,a5,1
ffffffffc02052a6:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc02052a8:	00a88463          	beq	a7,a0,ffffffffc02052b0 <schedule+0x60>
        {
            proc_run(next);
ffffffffc02052ac:	e47fe0ef          	jal	ra,ffffffffc02040f2 <proc_run>
    if (flag)
ffffffffc02052b0:	e819                	bnez	s0,ffffffffc02052c6 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02052b2:	60a2                	ld	ra,8(sp)
ffffffffc02052b4:	6402                	ld	s0,0(sp)
ffffffffc02052b6:	0141                	addi	sp,sp,16
ffffffffc02052b8:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02052ba:	4198                	lw	a4,0(a1)
ffffffffc02052bc:	4789                	li	a5,2
ffffffffc02052be:	fef712e3          	bne	a4,a5,ffffffffc02052a2 <schedule+0x52>
ffffffffc02052c2:	852e                	mv	a0,a1
ffffffffc02052c4:	bff9                	j	ffffffffc02052a2 <schedule+0x52>
}
ffffffffc02052c6:	6402                	ld	s0,0(sp)
ffffffffc02052c8:	60a2                	ld	ra,8(sp)
ffffffffc02052ca:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02052cc:	ee2fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02052d0:	000a5617          	auipc	a2,0xa5
ffffffffc02052d4:	42860613          	addi	a2,a2,1064 # ffffffffc02aa6f8 <proc_list>
ffffffffc02052d8:	86b2                	mv	a3,a2
ffffffffc02052da:	b76d                	j	ffffffffc0205284 <schedule+0x34>
        intr_disable();
ffffffffc02052dc:	ed8fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02052e0:	4405                	li	s0,1
ffffffffc02052e2:	bfbd                	j	ffffffffc0205260 <schedule+0x10>

ffffffffc02052e4 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02052e4:	000a5797          	auipc	a5,0xa5
ffffffffc02052e8:	4947b783          	ld	a5,1172(a5) # ffffffffc02aa778 <current>
}
ffffffffc02052ec:	43c8                	lw	a0,4(a5)
ffffffffc02052ee:	8082                	ret

ffffffffc02052f0 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02052f0:	4501                	li	a0,0
ffffffffc02052f2:	8082                	ret

ffffffffc02052f4 <sys_putc>:
    cputchar(c);
ffffffffc02052f4:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02052f6:	1141                	addi	sp,sp,-16
ffffffffc02052f8:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02052fa:	ed1fa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc02052fe:	60a2                	ld	ra,8(sp)
ffffffffc0205300:	4501                	li	a0,0
ffffffffc0205302:	0141                	addi	sp,sp,16
ffffffffc0205304:	8082                	ret

ffffffffc0205306 <sys_kill>:
    return do_kill(pid);
ffffffffc0205306:	4108                	lw	a0,0(a0)
ffffffffc0205308:	c31ff06f          	j	ffffffffc0204f38 <do_kill>

ffffffffc020530c <sys_yield>:
    return do_yield();
ffffffffc020530c:	bdfff06f          	j	ffffffffc0204eea <do_yield>

ffffffffc0205310 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205310:	6d14                	ld	a3,24(a0)
ffffffffc0205312:	6910                	ld	a2,16(a0)
ffffffffc0205314:	650c                	ld	a1,8(a0)
ffffffffc0205316:	6108                	ld	a0,0(a0)
ffffffffc0205318:	ebeff06f          	j	ffffffffc02049d6 <do_execve>

ffffffffc020531c <sys_wait>:
    return do_wait(pid, store);
ffffffffc020531c:	650c                	ld	a1,8(a0)
ffffffffc020531e:	4108                	lw	a0,0(a0)
ffffffffc0205320:	bdbff06f          	j	ffffffffc0204efa <do_wait>

ffffffffc0205324 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205324:	000a5797          	auipc	a5,0xa5
ffffffffc0205328:	4547b783          	ld	a5,1108(a5) # ffffffffc02aa778 <current>
ffffffffc020532c:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc020532e:	4501                	li	a0,0
ffffffffc0205330:	6a0c                	ld	a1,16(a2)
ffffffffc0205332:	e25fe06f          	j	ffffffffc0204156 <do_fork>

ffffffffc0205336 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205336:	4108                	lw	a0,0(a0)
ffffffffc0205338:	a60ff06f          	j	ffffffffc0204598 <do_exit>

ffffffffc020533c <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc020533c:	715d                	addi	sp,sp,-80
ffffffffc020533e:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205340:	000a5497          	auipc	s1,0xa5
ffffffffc0205344:	43848493          	addi	s1,s1,1080 # ffffffffc02aa778 <current>
ffffffffc0205348:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc020534a:	e0a2                	sd	s0,64(sp)
ffffffffc020534c:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc020534e:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205350:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205352:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0205354:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205358:	0327ee63          	bltu	a5,s2,ffffffffc0205394 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc020535c:	00391713          	slli	a4,s2,0x3
ffffffffc0205360:	00002797          	auipc	a5,0x2
ffffffffc0205364:	28878793          	addi	a5,a5,648 # ffffffffc02075e8 <syscalls>
ffffffffc0205368:	97ba                	add	a5,a5,a4
ffffffffc020536a:	639c                	ld	a5,0(a5)
ffffffffc020536c:	c785                	beqz	a5,ffffffffc0205394 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc020536e:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205370:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205372:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205374:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205376:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205378:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc020537a:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc020537c:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc020537e:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0205380:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205382:	0028                	addi	a0,sp,8
ffffffffc0205384:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205386:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205388:	e828                	sd	a0,80(s0)
}
ffffffffc020538a:	6406                	ld	s0,64(sp)
ffffffffc020538c:	74e2                	ld	s1,56(sp)
ffffffffc020538e:	7942                	ld	s2,48(sp)
ffffffffc0205390:	6161                	addi	sp,sp,80
ffffffffc0205392:	8082                	ret
    print_trapframe(tf);
ffffffffc0205394:	8522                	mv	a0,s0
ffffffffc0205396:	80ffb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc020539a:	609c                	ld	a5,0(s1)
ffffffffc020539c:	86ca                	mv	a3,s2
ffffffffc020539e:	00002617          	auipc	a2,0x2
ffffffffc02053a2:	20260613          	addi	a2,a2,514 # ffffffffc02075a0 <default_pmm_manager+0xe90>
ffffffffc02053a6:	43d8                	lw	a4,4(a5)
ffffffffc02053a8:	06200593          	li	a1,98
ffffffffc02053ac:	0b478793          	addi	a5,a5,180
ffffffffc02053b0:	00002517          	auipc	a0,0x2
ffffffffc02053b4:	22050513          	addi	a0,a0,544 # ffffffffc02075d0 <default_pmm_manager+0xec0>
ffffffffc02053b8:	8d6fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02053bc <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02053bc:	9e3707b7          	lui	a5,0x9e370
ffffffffc02053c0:	2785                	addiw	a5,a5,1
ffffffffc02053c2:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02053c6:	02000793          	li	a5,32
ffffffffc02053ca:	9f8d                	subw	a5,a5,a1
}
ffffffffc02053cc:	00f5553b          	srlw	a0,a0,a5
ffffffffc02053d0:	8082                	ret

ffffffffc02053d2 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02053d2:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053d6:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02053d8:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053dc:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02053de:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053e2:	f022                	sd	s0,32(sp)
ffffffffc02053e4:	ec26                	sd	s1,24(sp)
ffffffffc02053e6:	e84a                	sd	s2,16(sp)
ffffffffc02053e8:	f406                	sd	ra,40(sp)
ffffffffc02053ea:	e44e                	sd	s3,8(sp)
ffffffffc02053ec:	84aa                	mv	s1,a0
ffffffffc02053ee:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02053f0:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02053f4:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02053f6:	03067e63          	bgeu	a2,a6,ffffffffc0205432 <printnum+0x60>
ffffffffc02053fa:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02053fc:	00805763          	blez	s0,ffffffffc020540a <printnum+0x38>
ffffffffc0205400:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205402:	85ca                	mv	a1,s2
ffffffffc0205404:	854e                	mv	a0,s3
ffffffffc0205406:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205408:	fc65                	bnez	s0,ffffffffc0205400 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020540a:	1a02                	slli	s4,s4,0x20
ffffffffc020540c:	00002797          	auipc	a5,0x2
ffffffffc0205410:	2dc78793          	addi	a5,a5,732 # ffffffffc02076e8 <syscalls+0x100>
ffffffffc0205414:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205418:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020541a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020541c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0205420:	70a2                	ld	ra,40(sp)
ffffffffc0205422:	69a2                	ld	s3,8(sp)
ffffffffc0205424:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205426:	85ca                	mv	a1,s2
ffffffffc0205428:	87a6                	mv	a5,s1
}
ffffffffc020542a:	6942                	ld	s2,16(sp)
ffffffffc020542c:	64e2                	ld	s1,24(sp)
ffffffffc020542e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205430:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205432:	03065633          	divu	a2,a2,a6
ffffffffc0205436:	8722                	mv	a4,s0
ffffffffc0205438:	f9bff0ef          	jal	ra,ffffffffc02053d2 <printnum>
ffffffffc020543c:	b7f9                	j	ffffffffc020540a <printnum+0x38>

ffffffffc020543e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020543e:	7119                	addi	sp,sp,-128
ffffffffc0205440:	f4a6                	sd	s1,104(sp)
ffffffffc0205442:	f0ca                	sd	s2,96(sp)
ffffffffc0205444:	ecce                	sd	s3,88(sp)
ffffffffc0205446:	e8d2                	sd	s4,80(sp)
ffffffffc0205448:	e4d6                	sd	s5,72(sp)
ffffffffc020544a:	e0da                	sd	s6,64(sp)
ffffffffc020544c:	fc5e                	sd	s7,56(sp)
ffffffffc020544e:	f06a                	sd	s10,32(sp)
ffffffffc0205450:	fc86                	sd	ra,120(sp)
ffffffffc0205452:	f8a2                	sd	s0,112(sp)
ffffffffc0205454:	f862                	sd	s8,48(sp)
ffffffffc0205456:	f466                	sd	s9,40(sp)
ffffffffc0205458:	ec6e                	sd	s11,24(sp)
ffffffffc020545a:	892a                	mv	s2,a0
ffffffffc020545c:	84ae                	mv	s1,a1
ffffffffc020545e:	8d32                	mv	s10,a2
ffffffffc0205460:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205462:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205466:	5b7d                	li	s6,-1
ffffffffc0205468:	00002a97          	auipc	s5,0x2
ffffffffc020546c:	2aca8a93          	addi	s5,s5,684 # ffffffffc0207714 <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205470:	00002b97          	auipc	s7,0x2
ffffffffc0205474:	4c0b8b93          	addi	s7,s7,1216 # ffffffffc0207930 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205478:	000d4503          	lbu	a0,0(s10)
ffffffffc020547c:	001d0413          	addi	s0,s10,1
ffffffffc0205480:	01350a63          	beq	a0,s3,ffffffffc0205494 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0205484:	c121                	beqz	a0,ffffffffc02054c4 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205486:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205488:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020548a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020548c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0205490:	ff351ae3          	bne	a0,s3,ffffffffc0205484 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205494:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205498:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020549c:	4c81                	li	s9,0
ffffffffc020549e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02054a0:	5c7d                	li	s8,-1
ffffffffc02054a2:	5dfd                	li	s11,-1
ffffffffc02054a4:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02054a8:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054aa:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02054ae:	0ff5f593          	zext.b	a1,a1
ffffffffc02054b2:	00140d13          	addi	s10,s0,1
ffffffffc02054b6:	04b56263          	bltu	a0,a1,ffffffffc02054fa <vprintfmt+0xbc>
ffffffffc02054ba:	058a                	slli	a1,a1,0x2
ffffffffc02054bc:	95d6                	add	a1,a1,s5
ffffffffc02054be:	4194                	lw	a3,0(a1)
ffffffffc02054c0:	96d6                	add	a3,a3,s5
ffffffffc02054c2:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02054c4:	70e6                	ld	ra,120(sp)
ffffffffc02054c6:	7446                	ld	s0,112(sp)
ffffffffc02054c8:	74a6                	ld	s1,104(sp)
ffffffffc02054ca:	7906                	ld	s2,96(sp)
ffffffffc02054cc:	69e6                	ld	s3,88(sp)
ffffffffc02054ce:	6a46                	ld	s4,80(sp)
ffffffffc02054d0:	6aa6                	ld	s5,72(sp)
ffffffffc02054d2:	6b06                	ld	s6,64(sp)
ffffffffc02054d4:	7be2                	ld	s7,56(sp)
ffffffffc02054d6:	7c42                	ld	s8,48(sp)
ffffffffc02054d8:	7ca2                	ld	s9,40(sp)
ffffffffc02054da:	7d02                	ld	s10,32(sp)
ffffffffc02054dc:	6de2                	ld	s11,24(sp)
ffffffffc02054de:	6109                	addi	sp,sp,128
ffffffffc02054e0:	8082                	ret
            padc = '0';
ffffffffc02054e2:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02054e4:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054e8:	846a                	mv	s0,s10
ffffffffc02054ea:	00140d13          	addi	s10,s0,1
ffffffffc02054ee:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02054f2:	0ff5f593          	zext.b	a1,a1
ffffffffc02054f6:	fcb572e3          	bgeu	a0,a1,ffffffffc02054ba <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02054fa:	85a6                	mv	a1,s1
ffffffffc02054fc:	02500513          	li	a0,37
ffffffffc0205500:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205502:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205506:	8d22                	mv	s10,s0
ffffffffc0205508:	f73788e3          	beq	a5,s3,ffffffffc0205478 <vprintfmt+0x3a>
ffffffffc020550c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0205510:	1d7d                	addi	s10,s10,-1
ffffffffc0205512:	ff379de3          	bne	a5,s3,ffffffffc020550c <vprintfmt+0xce>
ffffffffc0205516:	b78d                	j	ffffffffc0205478 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205518:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020551c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205520:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205522:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205526:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020552a:	02d86463          	bltu	a6,a3,ffffffffc0205552 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020552e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205532:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205536:	0186873b          	addw	a4,a3,s8
ffffffffc020553a:	0017171b          	slliw	a4,a4,0x1
ffffffffc020553e:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205540:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205544:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205546:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020554a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020554e:	fed870e3          	bgeu	a6,a3,ffffffffc020552e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205552:	f40ddce3          	bgez	s11,ffffffffc02054aa <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205556:	8de2                	mv	s11,s8
ffffffffc0205558:	5c7d                	li	s8,-1
ffffffffc020555a:	bf81                	j	ffffffffc02054aa <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020555c:	fffdc693          	not	a3,s11
ffffffffc0205560:	96fd                	srai	a3,a3,0x3f
ffffffffc0205562:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205566:	00144603          	lbu	a2,1(s0)
ffffffffc020556a:	2d81                	sext.w	s11,s11
ffffffffc020556c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020556e:	bf35                	j	ffffffffc02054aa <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205570:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205574:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205578:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020557a:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020557c:	bfd9                	j	ffffffffc0205552 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020557e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205580:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205584:	01174463          	blt	a4,a7,ffffffffc020558c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205588:	1a088e63          	beqz	a7,ffffffffc0205744 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020558c:	000a3603          	ld	a2,0(s4)
ffffffffc0205590:	46c1                	li	a3,16
ffffffffc0205592:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205594:	2781                	sext.w	a5,a5
ffffffffc0205596:	876e                	mv	a4,s11
ffffffffc0205598:	85a6                	mv	a1,s1
ffffffffc020559a:	854a                	mv	a0,s2
ffffffffc020559c:	e37ff0ef          	jal	ra,ffffffffc02053d2 <printnum>
            break;
ffffffffc02055a0:	bde1                	j	ffffffffc0205478 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02055a2:	000a2503          	lw	a0,0(s4)
ffffffffc02055a6:	85a6                	mv	a1,s1
ffffffffc02055a8:	0a21                	addi	s4,s4,8
ffffffffc02055aa:	9902                	jalr	s2
            break;
ffffffffc02055ac:	b5f1                	j	ffffffffc0205478 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02055ae:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055b0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055b4:	01174463          	blt	a4,a7,ffffffffc02055bc <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02055b8:	18088163          	beqz	a7,ffffffffc020573a <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02055bc:	000a3603          	ld	a2,0(s4)
ffffffffc02055c0:	46a9                	li	a3,10
ffffffffc02055c2:	8a2e                	mv	s4,a1
ffffffffc02055c4:	bfc1                	j	ffffffffc0205594 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055c6:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02055ca:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055cc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02055ce:	bdf1                	j	ffffffffc02054aa <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02055d0:	85a6                	mv	a1,s1
ffffffffc02055d2:	02500513          	li	a0,37
ffffffffc02055d6:	9902                	jalr	s2
            break;
ffffffffc02055d8:	b545                	j	ffffffffc0205478 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055da:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02055de:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055e0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02055e2:	b5e1                	j	ffffffffc02054aa <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02055e4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055e6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055ea:	01174463          	blt	a4,a7,ffffffffc02055f2 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02055ee:	14088163          	beqz	a7,ffffffffc0205730 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02055f2:	000a3603          	ld	a2,0(s4)
ffffffffc02055f6:	46a1                	li	a3,8
ffffffffc02055f8:	8a2e                	mv	s4,a1
ffffffffc02055fa:	bf69                	j	ffffffffc0205594 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02055fc:	03000513          	li	a0,48
ffffffffc0205600:	85a6                	mv	a1,s1
ffffffffc0205602:	e03e                	sd	a5,0(sp)
ffffffffc0205604:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205606:	85a6                	mv	a1,s1
ffffffffc0205608:	07800513          	li	a0,120
ffffffffc020560c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020560e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205610:	6782                	ld	a5,0(sp)
ffffffffc0205612:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205614:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205618:	bfb5                	j	ffffffffc0205594 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020561a:	000a3403          	ld	s0,0(s4)
ffffffffc020561e:	008a0713          	addi	a4,s4,8
ffffffffc0205622:	e03a                	sd	a4,0(sp)
ffffffffc0205624:	14040263          	beqz	s0,ffffffffc0205768 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205628:	0fb05763          	blez	s11,ffffffffc0205716 <vprintfmt+0x2d8>
ffffffffc020562c:	02d00693          	li	a3,45
ffffffffc0205630:	0cd79163          	bne	a5,a3,ffffffffc02056f2 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205634:	00044783          	lbu	a5,0(s0)
ffffffffc0205638:	0007851b          	sext.w	a0,a5
ffffffffc020563c:	cf85                	beqz	a5,ffffffffc0205674 <vprintfmt+0x236>
ffffffffc020563e:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205642:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205646:	000c4563          	bltz	s8,ffffffffc0205650 <vprintfmt+0x212>
ffffffffc020564a:	3c7d                	addiw	s8,s8,-1
ffffffffc020564c:	036c0263          	beq	s8,s6,ffffffffc0205670 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205650:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205652:	0e0c8e63          	beqz	s9,ffffffffc020574e <vprintfmt+0x310>
ffffffffc0205656:	3781                	addiw	a5,a5,-32
ffffffffc0205658:	0ef47b63          	bgeu	s0,a5,ffffffffc020574e <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020565c:	03f00513          	li	a0,63
ffffffffc0205660:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205662:	000a4783          	lbu	a5,0(s4)
ffffffffc0205666:	3dfd                	addiw	s11,s11,-1
ffffffffc0205668:	0a05                	addi	s4,s4,1
ffffffffc020566a:	0007851b          	sext.w	a0,a5
ffffffffc020566e:	ffe1                	bnez	a5,ffffffffc0205646 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205670:	01b05963          	blez	s11,ffffffffc0205682 <vprintfmt+0x244>
ffffffffc0205674:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205676:	85a6                	mv	a1,s1
ffffffffc0205678:	02000513          	li	a0,32
ffffffffc020567c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020567e:	fe0d9be3          	bnez	s11,ffffffffc0205674 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205682:	6a02                	ld	s4,0(sp)
ffffffffc0205684:	bbd5                	j	ffffffffc0205478 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205686:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205688:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020568c:	01174463          	blt	a4,a7,ffffffffc0205694 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205690:	08088d63          	beqz	a7,ffffffffc020572a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205694:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205698:	0a044d63          	bltz	s0,ffffffffc0205752 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020569c:	8622                	mv	a2,s0
ffffffffc020569e:	8a66                	mv	s4,s9
ffffffffc02056a0:	46a9                	li	a3,10
ffffffffc02056a2:	bdcd                	j	ffffffffc0205594 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02056a4:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056a8:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02056aa:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02056ac:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02056b0:	8fb5                	xor	a5,a5,a3
ffffffffc02056b2:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056b6:	02d74163          	blt	a4,a3,ffffffffc02056d8 <vprintfmt+0x29a>
ffffffffc02056ba:	00369793          	slli	a5,a3,0x3
ffffffffc02056be:	97de                	add	a5,a5,s7
ffffffffc02056c0:	639c                	ld	a5,0(a5)
ffffffffc02056c2:	cb99                	beqz	a5,ffffffffc02056d8 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02056c4:	86be                	mv	a3,a5
ffffffffc02056c6:	00000617          	auipc	a2,0x0
ffffffffc02056ca:	1f260613          	addi	a2,a2,498 # ffffffffc02058b8 <etext+0x2c>
ffffffffc02056ce:	85a6                	mv	a1,s1
ffffffffc02056d0:	854a                	mv	a0,s2
ffffffffc02056d2:	0ce000ef          	jal	ra,ffffffffc02057a0 <printfmt>
ffffffffc02056d6:	b34d                	j	ffffffffc0205478 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02056d8:	00002617          	auipc	a2,0x2
ffffffffc02056dc:	03060613          	addi	a2,a2,48 # ffffffffc0207708 <syscalls+0x120>
ffffffffc02056e0:	85a6                	mv	a1,s1
ffffffffc02056e2:	854a                	mv	a0,s2
ffffffffc02056e4:	0bc000ef          	jal	ra,ffffffffc02057a0 <printfmt>
ffffffffc02056e8:	bb41                	j	ffffffffc0205478 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02056ea:	00002417          	auipc	s0,0x2
ffffffffc02056ee:	01640413          	addi	s0,s0,22 # ffffffffc0207700 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056f2:	85e2                	mv	a1,s8
ffffffffc02056f4:	8522                	mv	a0,s0
ffffffffc02056f6:	e43e                	sd	a5,8(sp)
ffffffffc02056f8:	0e2000ef          	jal	ra,ffffffffc02057da <strnlen>
ffffffffc02056fc:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0205700:	01b05b63          	blez	s11,ffffffffc0205716 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205704:	67a2                	ld	a5,8(sp)
ffffffffc0205706:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020570a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020570c:	85a6                	mv	a1,s1
ffffffffc020570e:	8552                	mv	a0,s4
ffffffffc0205710:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205712:	fe0d9ce3          	bnez	s11,ffffffffc020570a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205716:	00044783          	lbu	a5,0(s0)
ffffffffc020571a:	00140a13          	addi	s4,s0,1
ffffffffc020571e:	0007851b          	sext.w	a0,a5
ffffffffc0205722:	d3a5                	beqz	a5,ffffffffc0205682 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205724:	05e00413          	li	s0,94
ffffffffc0205728:	bf39                	j	ffffffffc0205646 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020572a:	000a2403          	lw	s0,0(s4)
ffffffffc020572e:	b7ad                	j	ffffffffc0205698 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205730:	000a6603          	lwu	a2,0(s4)
ffffffffc0205734:	46a1                	li	a3,8
ffffffffc0205736:	8a2e                	mv	s4,a1
ffffffffc0205738:	bdb1                	j	ffffffffc0205594 <vprintfmt+0x156>
ffffffffc020573a:	000a6603          	lwu	a2,0(s4)
ffffffffc020573e:	46a9                	li	a3,10
ffffffffc0205740:	8a2e                	mv	s4,a1
ffffffffc0205742:	bd89                	j	ffffffffc0205594 <vprintfmt+0x156>
ffffffffc0205744:	000a6603          	lwu	a2,0(s4)
ffffffffc0205748:	46c1                	li	a3,16
ffffffffc020574a:	8a2e                	mv	s4,a1
ffffffffc020574c:	b5a1                	j	ffffffffc0205594 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020574e:	9902                	jalr	s2
ffffffffc0205750:	bf09                	j	ffffffffc0205662 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205752:	85a6                	mv	a1,s1
ffffffffc0205754:	02d00513          	li	a0,45
ffffffffc0205758:	e03e                	sd	a5,0(sp)
ffffffffc020575a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020575c:	6782                	ld	a5,0(sp)
ffffffffc020575e:	8a66                	mv	s4,s9
ffffffffc0205760:	40800633          	neg	a2,s0
ffffffffc0205764:	46a9                	li	a3,10
ffffffffc0205766:	b53d                	j	ffffffffc0205594 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205768:	03b05163          	blez	s11,ffffffffc020578a <vprintfmt+0x34c>
ffffffffc020576c:	02d00693          	li	a3,45
ffffffffc0205770:	f6d79de3          	bne	a5,a3,ffffffffc02056ea <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205774:	00002417          	auipc	s0,0x2
ffffffffc0205778:	f8c40413          	addi	s0,s0,-116 # ffffffffc0207700 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020577c:	02800793          	li	a5,40
ffffffffc0205780:	02800513          	li	a0,40
ffffffffc0205784:	00140a13          	addi	s4,s0,1
ffffffffc0205788:	bd6d                	j	ffffffffc0205642 <vprintfmt+0x204>
ffffffffc020578a:	00002a17          	auipc	s4,0x2
ffffffffc020578e:	f77a0a13          	addi	s4,s4,-137 # ffffffffc0207701 <syscalls+0x119>
ffffffffc0205792:	02800513          	li	a0,40
ffffffffc0205796:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020579a:	05e00413          	li	s0,94
ffffffffc020579e:	b565                	j	ffffffffc0205646 <vprintfmt+0x208>

ffffffffc02057a0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057a0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02057a2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057a6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057a8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057aa:	ec06                	sd	ra,24(sp)
ffffffffc02057ac:	f83a                	sd	a4,48(sp)
ffffffffc02057ae:	fc3e                	sd	a5,56(sp)
ffffffffc02057b0:	e0c2                	sd	a6,64(sp)
ffffffffc02057b2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02057b4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057b6:	c89ff0ef          	jal	ra,ffffffffc020543e <vprintfmt>
}
ffffffffc02057ba:	60e2                	ld	ra,24(sp)
ffffffffc02057bc:	6161                	addi	sp,sp,80
ffffffffc02057be:	8082                	ret

ffffffffc02057c0 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02057c0:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02057c4:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02057c6:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02057c8:	cb81                	beqz	a5,ffffffffc02057d8 <strlen+0x18>
        cnt ++;
ffffffffc02057ca:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02057cc:	00a707b3          	add	a5,a4,a0
ffffffffc02057d0:	0007c783          	lbu	a5,0(a5)
ffffffffc02057d4:	fbfd                	bnez	a5,ffffffffc02057ca <strlen+0xa>
ffffffffc02057d6:	8082                	ret
    }
    return cnt;
}
ffffffffc02057d8:	8082                	ret

ffffffffc02057da <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02057da:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057dc:	e589                	bnez	a1,ffffffffc02057e6 <strnlen+0xc>
ffffffffc02057de:	a811                	j	ffffffffc02057f2 <strnlen+0x18>
        cnt ++;
ffffffffc02057e0:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057e2:	00f58863          	beq	a1,a5,ffffffffc02057f2 <strnlen+0x18>
ffffffffc02057e6:	00f50733          	add	a4,a0,a5
ffffffffc02057ea:	00074703          	lbu	a4,0(a4)
ffffffffc02057ee:	fb6d                	bnez	a4,ffffffffc02057e0 <strnlen+0x6>
ffffffffc02057f0:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02057f2:	852e                	mv	a0,a1
ffffffffc02057f4:	8082                	ret

ffffffffc02057f6 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02057f6:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02057f8:	0005c703          	lbu	a4,0(a1)
ffffffffc02057fc:	0785                	addi	a5,a5,1
ffffffffc02057fe:	0585                	addi	a1,a1,1
ffffffffc0205800:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205804:	fb75                	bnez	a4,ffffffffc02057f8 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205806:	8082                	ret

ffffffffc0205808 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205808:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020580c:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205810:	cb89                	beqz	a5,ffffffffc0205822 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205812:	0505                	addi	a0,a0,1
ffffffffc0205814:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205816:	fee789e3          	beq	a5,a4,ffffffffc0205808 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020581a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020581e:	9d19                	subw	a0,a0,a4
ffffffffc0205820:	8082                	ret
ffffffffc0205822:	4501                	li	a0,0
ffffffffc0205824:	bfed                	j	ffffffffc020581e <strcmp+0x16>

ffffffffc0205826 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205826:	c20d                	beqz	a2,ffffffffc0205848 <strncmp+0x22>
ffffffffc0205828:	962e                	add	a2,a2,a1
ffffffffc020582a:	a031                	j	ffffffffc0205836 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc020582c:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020582e:	00e79a63          	bne	a5,a4,ffffffffc0205842 <strncmp+0x1c>
ffffffffc0205832:	00b60b63          	beq	a2,a1,ffffffffc0205848 <strncmp+0x22>
ffffffffc0205836:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc020583a:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020583c:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205840:	f7f5                	bnez	a5,ffffffffc020582c <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205842:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205846:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205848:	4501                	li	a0,0
ffffffffc020584a:	8082                	ret

ffffffffc020584c <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020584c:	00054783          	lbu	a5,0(a0)
ffffffffc0205850:	c799                	beqz	a5,ffffffffc020585e <strchr+0x12>
        if (*s == c) {
ffffffffc0205852:	00f58763          	beq	a1,a5,ffffffffc0205860 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205856:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020585a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020585c:	fbfd                	bnez	a5,ffffffffc0205852 <strchr+0x6>
    }
    return NULL;
ffffffffc020585e:	4501                	li	a0,0
}
ffffffffc0205860:	8082                	ret

ffffffffc0205862 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205862:	ca01                	beqz	a2,ffffffffc0205872 <memset+0x10>
ffffffffc0205864:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205866:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205868:	0785                	addi	a5,a5,1
ffffffffc020586a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020586e:	fec79de3          	bne	a5,a2,ffffffffc0205868 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205872:	8082                	ret

ffffffffc0205874 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205874:	ca19                	beqz	a2,ffffffffc020588a <memcpy+0x16>
ffffffffc0205876:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205878:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc020587a:	0005c703          	lbu	a4,0(a1)
ffffffffc020587e:	0585                	addi	a1,a1,1
ffffffffc0205880:	0785                	addi	a5,a5,1
ffffffffc0205882:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205886:	fec59ae3          	bne	a1,a2,ffffffffc020587a <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc020588a:	8082                	ret
