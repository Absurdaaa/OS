
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
ffffffffc020004e:	20650513          	addi	a0,a0,518 # ffffffffc02a6250 <buf>
ffffffffc0200052:	000aa617          	auipc	a2,0xaa
ffffffffc0200056:	6b260613          	addi	a2,a2,1714 # ffffffffc02aa704 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	01d050ef          	jal	ra,ffffffffc020587e <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	83a58593          	addi	a1,a1,-1990 # ffffffffc02058a8 <etext>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	85250513          	addi	a0,a0,-1966 # ffffffffc02058c8 <etext+0x20>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	760020ef          	jal	ra,ffffffffc02027e6 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	163030ef          	jal	ra,ffffffffc02039f4 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	73b040ef          	jal	ra,ffffffffc0204fd0 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	0c6050ef          	jal	ra,ffffffffc0205168 <cpu_idle>

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
ffffffffc02000bc:	00006517          	auipc	a0,0x6
ffffffffc02000c0:	81450513          	addi	a0,a0,-2028 # ffffffffc02058d0 <etext+0x28>
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
ffffffffc02000d6:	17eb8b93          	addi	s7,s7,382 # ffffffffc02a6250 <buf>
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
ffffffffc0200132:	12250513          	addi	a0,a0,290 # ffffffffc02a6250 <buf>
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
ffffffffc0200188:	2d2050ef          	jal	ra,ffffffffc020545a <vprintfmt>
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
ffffffffc02001be:	29c050ef          	jal	ra,ffffffffc020545a <vprintfmt>
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
// - 文本段(.text)结束地址(etext)
// - 数据段(.data)结束地址(edata)
// - 内核内存占用结束地址(end)
// - 内核总共使用的内存大小(KB为单位)
void print_kerninfo(void)
{
ffffffffc020021c:	1141                	addi	sp,sp,-16
  // edata: 数据段结束地址
  // end:   内核所有段(包括bss)的结束地址
  // kern_init: 内核入口函数地址
  extern char etext[], edata[], end[], kern_init[];

  cprintf("Special kernel symbols:\n");
ffffffffc020021e:	00005517          	auipc	a0,0x5
ffffffffc0200222:	6ba50513          	addi	a0,a0,1722 # ffffffffc02058d8 <etext+0x30>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
  cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
  cprintf("  entry  0x%08x (virtual)\n", kern_init); // 内核入口地址(虚拟地址)
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	6c450513          	addi	a0,a0,1732 # ffffffffc02058f8 <etext+0x50>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
  cprintf("  etext  0x%08x (virtual)\n", etext);     // 文本段结束地址(虚拟地址)
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	66858593          	addi	a1,a1,1640 # ffffffffc02058a8 <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	6d050513          	addi	a0,a0,1744 # ffffffffc0205918 <etext+0x70>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
  cprintf("  edata  0x%08x (virtual)\n", edata);     // 数据段结束地址(虚拟地址)
ffffffffc0200254:	000a6597          	auipc	a1,0xa6
ffffffffc0200258:	ffc58593          	addi	a1,a1,-4 # ffffffffc02a6250 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	6dc50513          	addi	a0,a0,1756 # ffffffffc0205938 <etext+0x90>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
  cprintf("  end    0x%08x (virtual)\n", end);       // 内核内存占用结束地址(虚拟地址)
ffffffffc0200268:	000aa597          	auipc	a1,0xaa
ffffffffc020026c:	49c58593          	addi	a1,a1,1180 # ffffffffc02aa704 <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	6e850513          	addi	a0,a0,1768 # ffffffffc0205958 <etext+0xb0>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>

  // 计算内核可执行文件的内存占用大小(KB)
  // 公式说明：(end - kern_init) 得到字节数，+1023是为了向上取整，再除以1024转换为KB
  cprintf("Kernel executable memory footprint: %dKB\n",
          (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000ab597          	auipc	a1,0xab
ffffffffc0200280:	88758593          	addi	a1,a1,-1913 # ffffffffc02aab03 <end+0x3ff>
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
ffffffffc02002a2:	6da50513          	addi	a0,a0,1754 # ffffffffc0205978 <etext+0xd0>
}
ffffffffc02002a6:	0141                	addi	sp,sp,16
  cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	b5f5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002aa <print_stackframe>:
//   - print_stackframe()最终负责追踪并打印这些调试信息
//
// 边界条件：
//   - ebp链的长度有限，在boot/bootasm.S中跳转到内核入口前，ebp会被设为0，这是回溯的终止边界
void print_stackframe(void)
{
ffffffffc02002aa:	1141                	addi	sp,sp,-16
  panic("Not Implemented!");
ffffffffc02002ac:	00005617          	auipc	a2,0x5
ffffffffc02002b0:	6fc60613          	addi	a2,a2,1788 # ffffffffc02059a8 <etext+0x100>
ffffffffc02002b4:	06c00593          	li	a1,108
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	70850513          	addi	a0,a0,1800 # ffffffffc02059c0 <etext+0x118>
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
ffffffffc02002cc:	71060613          	addi	a2,a2,1808 # ffffffffc02059d8 <etext+0x130>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	72858593          	addi	a1,a1,1832 # ffffffffc02059f8 <etext+0x150>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	72850513          	addi	a0,a0,1832 # ffffffffc0205a00 <etext+0x158>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	72a60613          	addi	a2,a2,1834 # ffffffffc0205a10 <etext+0x168>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	74a58593          	addi	a1,a1,1866 # ffffffffc0205a38 <etext+0x190>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	70a50513          	addi	a0,a0,1802 # ffffffffc0205a00 <etext+0x158>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	74660613          	addi	a2,a2,1862 # ffffffffc0205a48 <etext+0x1a0>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	75e58593          	addi	a1,a1,1886 # ffffffffc0205a68 <etext+0x1c0>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	6ee50513          	addi	a0,a0,1774 # ffffffffc0205a00 <etext+0x158>
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
ffffffffc0200350:	72c50513          	addi	a0,a0,1836 # ffffffffc0205a78 <etext+0x1d0>
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
ffffffffc0200372:	73250513          	addi	a0,a0,1842 # ffffffffc0205aa0 <etext+0x1f8>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	78cc0c13          	addi	s8,s8,1932 # ffffffffc0205b10 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	73c90913          	addi	s2,s2,1852 # ffffffffc0205ac8 <etext+0x220>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	73c48493          	addi	s1,s1,1852 # ffffffffc0205ad0 <etext+0x228>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	73ab0b13          	addi	s6,s6,1850 # ffffffffc0205ad8 <etext+0x230>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	652a0a13          	addi	s4,s4,1618 # ffffffffc02059f8 <etext+0x150>
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
ffffffffc02003cc:	748d0d13          	addi	s10,s10,1864 # ffffffffc0205b10 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	44e050ef          	jal	ra,ffffffffc0205824 <strcmp>
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
ffffffffc02003ea:	43a050ef          	jal	ra,ffffffffc0205824 <strcmp>
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
ffffffffc0200428:	440050ef          	jal	ra,ffffffffc0205868 <strchr>
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
ffffffffc0200466:	402050ef          	jal	ra,ffffffffc0205868 <strchr>
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
ffffffffc0200484:	67850513          	addi	a0,a0,1656 # ffffffffc0205af8 <etext+0x250>
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
ffffffffc0200492:	1ea30313          	addi	t1,t1,490 # ffffffffc02aa678 <is_panic>
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
ffffffffc02004c0:	69c50513          	addi	a0,a0,1692 # ffffffffc0205b58 <commands+0x48>
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
ffffffffc02004d6:	7ee50513          	addi	a0,a0,2030 # ffffffffc0206cc0 <default_pmm_manager+0x578>
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
ffffffffc020050a:	67250513          	addi	a0,a0,1650 # ffffffffc0205b78 <commands+0x68>
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
ffffffffc020052a:	79a50513          	addi	a0,a0,1946 # ffffffffc0206cc0 <default_pmm_manager+0x578>
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
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd588>
ffffffffc0200540:	000aa717          	auipc	a4,0xaa
ffffffffc0200544:	14f73423          	sd	a5,328(a4) # ffffffffc02aa688 <timebase>
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
ffffffffc0200564:	63850513          	addi	a0,a0,1592 # ffffffffc0205b98 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000aa797          	auipc	a5,0xaa
ffffffffc020056c:	1007bc23          	sd	zero,280(a5) # ffffffffc02aa680 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000aa797          	auipc	a5,0xaa
ffffffffc020057a:	1127b783          	ld	a5,274(a5) # ffffffffc02aa688 <timebase>
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
ffffffffc0200604:	5b850513          	addi	a0,a0,1464 # ffffffffc0205bb8 <commands+0xa8>
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
ffffffffc0200632:	59a50513          	addi	a0,a0,1434 # ffffffffc0205bc8 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	59450513          	addi	a0,a0,1428 # ffffffffc0205bd8 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	59c50513          	addi	a0,a0,1436 # ffffffffc0205bf0 <commands+0xe0>
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
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe357e9>
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
ffffffffc0200712:	53290913          	addi	s2,s2,1330 # ffffffffc0205c40 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	51c48493          	addi	s1,s1,1308 # ffffffffc0205c38 <commands+0x128>
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
ffffffffc0200774:	54850513          	addi	a0,a0,1352 # ffffffffc0205cb8 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	57450513          	addi	a0,a0,1396 # ffffffffc0205cf0 <commands+0x1e0>
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
ffffffffc02007c0:	45450513          	addi	a0,a0,1108 # ffffffffc0205c10 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	012050ef          	jal	ra,ffffffffc02057dc <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	06a050ef          	jal	ra,ffffffffc0205842 <strncmp>
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
ffffffffc020086e:	7b7040ef          	jal	ra,ffffffffc0205824 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	3c650513          	addi	a0,a0,966 # ffffffffc0205c48 <commands+0x138>
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
ffffffffc0200954:	31850513          	addi	a0,a0,792 # ffffffffc0205c68 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	31e50513          	addi	a0,a0,798 # ffffffffc0205c80 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	32c50513          	addi	a0,a0,812 # ffffffffc0205ca0 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	37050513          	addi	a0,a0,880 # ffffffffc0205cf0 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000aa797          	auipc	a5,0xaa
ffffffffc020098c:	d087b423          	sd	s0,-760(a5) # ffffffffc02aa690 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000aa797          	auipc	a5,0xaa
ffffffffc0200994:	d167b423          	sd	s6,-760(a5) # ffffffffc02aa698 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000aa517          	auipc	a0,0xaa
ffffffffc020099e:	cf653503          	ld	a0,-778(a0) # ffffffffc02aa690 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000aa517          	auipc	a0,0xaa
ffffffffc02009a8:	cf453503          	ld	a0,-780(a0) # ffffffffc02aa698 <memory_size>
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
ffffffffc02009c4:	55478793          	addi	a5,a5,1364 # ffffffffc0200f14 <__alltraps>
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
ffffffffc02009e2:	32a50513          	addi	a0,a0,810 # ffffffffc0205d08 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	33250513          	addi	a0,a0,818 # ffffffffc0205d20 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	33c50513          	addi	a0,a0,828 # ffffffffc0205d38 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	34650513          	addi	a0,a0,838 # ffffffffc0205d50 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	35050513          	addi	a0,a0,848 # ffffffffc0205d68 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	35a50513          	addi	a0,a0,858 # ffffffffc0205d80 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	36450513          	addi	a0,a0,868 # ffffffffc0205d98 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	36e50513          	addi	a0,a0,878 # ffffffffc0205db0 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	37850513          	addi	a0,a0,888 # ffffffffc0205dc8 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	38250513          	addi	a0,a0,898 # ffffffffc0205de0 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	38c50513          	addi	a0,a0,908 # ffffffffc0205df8 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	39650513          	addi	a0,a0,918 # ffffffffc0205e10 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	3a050513          	addi	a0,a0,928 # ffffffffc0205e28 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	3aa50513          	addi	a0,a0,938 # ffffffffc0205e40 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	3b450513          	addi	a0,a0,948 # ffffffffc0205e58 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	3be50513          	addi	a0,a0,958 # ffffffffc0205e70 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	3c850513          	addi	a0,a0,968 # ffffffffc0205e88 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	3d250513          	addi	a0,a0,978 # ffffffffc0205ea0 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	3dc50513          	addi	a0,a0,988 # ffffffffc0205eb8 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	3e650513          	addi	a0,a0,998 # ffffffffc0205ed0 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	3f050513          	addi	a0,a0,1008 # ffffffffc0205ee8 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	3fa50513          	addi	a0,a0,1018 # ffffffffc0205f00 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	40450513          	addi	a0,a0,1028 # ffffffffc0205f18 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	40e50513          	addi	a0,a0,1038 # ffffffffc0205f30 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	41850513          	addi	a0,a0,1048 # ffffffffc0205f48 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	42250513          	addi	a0,a0,1058 # ffffffffc0205f60 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	42c50513          	addi	a0,a0,1068 # ffffffffc0205f78 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	43650513          	addi	a0,a0,1078 # ffffffffc0205f90 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	44050513          	addi	a0,a0,1088 # ffffffffc0205fa8 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	44a50513          	addi	a0,a0,1098 # ffffffffc0205fc0 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	45450513          	addi	a0,a0,1108 # ffffffffc0205fd8 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	45a50513          	addi	a0,a0,1114 # ffffffffc0205ff0 <commands+0x4e0>
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
ffffffffc0200bb0:	45c50513          	addi	a0,a0,1116 # ffffffffc0206008 <commands+0x4f8>
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
ffffffffc0200bc8:	45c50513          	addi	a0,a0,1116 # ffffffffc0206020 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	46450513          	addi	a0,a0,1124 # ffffffffc0206038 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	46c50513          	addi	a0,a0,1132 # ffffffffc0206050 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	46850513          	addi	a0,a0,1128 # ffffffffc0206060 <commands+0x550>
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
ffffffffc0200c18:	53470713          	addi	a4,a4,1332 # ffffffffc0206148 <commands+0x638>
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
ffffffffc0200c2a:	4b250513          	addi	a0,a0,1202 # ffffffffc02060d8 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00005517          	auipc	a0,0x5
ffffffffc0200c36:	48650513          	addi	a0,a0,1158 # ffffffffc02060b8 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	43a50513          	addi	a0,a0,1082 # ffffffffc0206078 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00005517          	auipc	a0,0x5
ffffffffc0200c4e:	44e50513          	addi	a0,a0,1102 # ffffffffc0206098 <commands+0x588>
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
ffffffffc0200c64:	a2068693          	addi	a3,a3,-1504 # ffffffffc02aa680 <ticks>
ffffffffc0200c68:	629c                	ld	a5,0(a3)
ffffffffc0200c6a:	06400713          	li	a4,100
ffffffffc0200c6e:	000aa417          	auipc	s0,0xaa
ffffffffc0200c72:	a3240413          	addi	s0,s0,-1486 # ffffffffc02aa6a0 <print_num>
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
ffffffffc0200c84:	a687b783          	ld	a5,-1432(a5) # ffffffffc02aa6e8 <current>
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
ffffffffc0200ca2:	48a50513          	addi	a0,a0,1162 # ffffffffc0206128 <commands+0x618>
ffffffffc0200ca6:	ceeff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200caa:	bded                	j	ffffffffc0200ba4 <print_trapframe>
            print_num++;
ffffffffc0200cac:	401c                	lw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200cae:	06400593          	li	a1,100
ffffffffc0200cb2:	00005517          	auipc	a0,0x5
ffffffffc0200cb6:	44650513          	addi	a0,a0,1094 # ffffffffc02060f8 <commands+0x5e8>
            print_num++;
ffffffffc0200cba:	2785                	addiw	a5,a5,1
ffffffffc0200cbc:	c01c                	sw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200cbe:	cd6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0200cc2:	bf7d                	j	ffffffffc0200c80 <interrupt_handler+0x7a>
            cprintf("Calling SBI shutdown...\n");
ffffffffc0200cc4:	00005517          	auipc	a0,0x5
ffffffffc0200cc8:	44450513          	addi	a0,a0,1092 # ffffffffc0206108 <commands+0x5f8>
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

// 处理各种异常
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
ffffffffc0200cec:	14f76e63          	bltu	a4,a5,ffffffffc0200e48 <exception_handler+0x16a>
ffffffffc0200cf0:	00005717          	auipc	a4,0x5
ffffffffc0200cf4:	65470713          	addi	a4,a4,1620 # ffffffffc0206344 <commands+0x834>
ffffffffc0200cf8:	078a                	slli	a5,a5,0x2
ffffffffc0200cfa:	97ba                	add	a5,a5,a4
ffffffffc0200cfc:	439c                	lw	a5,0(a5)
ffffffffc0200cfe:	97ba                	add	a5,a5,a4
ffffffffc0200d00:	8782                	jr	a5
            panic("unhandled load page fault\n");
        }
        break;
    case CAUSE_STORE_PAGE_FAULT:
        // 写缺页，error_code 置写标志 0x2 触发 COW 分支
        if (do_pgfault(current->mm, 0x2, tf->tval) != 0)
ffffffffc0200d02:	000aa797          	auipc	a5,0xaa
ffffffffc0200d06:	9e67b783          	ld	a5,-1562(a5) # ffffffffc02aa6e8 <current>
ffffffffc0200d0a:	11053603          	ld	a2,272(a0)
ffffffffc0200d0e:	7788                	ld	a0,40(a5)
ffffffffc0200d10:	4589                	li	a1,2
ffffffffc0200d12:	006030ef          	jal	ra,ffffffffc0203d18 <do_pgfault>
ffffffffc0200d16:	14051a63          	bnez	a0,ffffffffc0200e6a <exception_handler+0x18c>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200d1a:	60a2                	ld	ra,8(sp)
ffffffffc0200d1c:	6402                	ld	s0,0(sp)
ffffffffc0200d1e:	0141                	addi	sp,sp,16
ffffffffc0200d20:	8082                	ret
        cprintf("Instruction address misaligned\n");
ffffffffc0200d22:	00005517          	auipc	a0,0x5
ffffffffc0200d26:	45650513          	addi	a0,a0,1110 # ffffffffc0206178 <commands+0x668>
}
ffffffffc0200d2a:	6402                	ld	s0,0(sp)
ffffffffc0200d2c:	60a2                	ld	ra,8(sp)
ffffffffc0200d2e:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200d30:	c64ff06f          	j	ffffffffc0200194 <cprintf>
ffffffffc0200d34:	00005517          	auipc	a0,0x5
ffffffffc0200d38:	46450513          	addi	a0,a0,1124 # ffffffffc0206198 <commands+0x688>
ffffffffc0200d3c:	b7fd                	j	ffffffffc0200d2a <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d3e:	00005517          	auipc	a0,0x5
ffffffffc0200d42:	47a50513          	addi	a0,a0,1146 # ffffffffc02061b8 <commands+0x6a8>
ffffffffc0200d46:	b7d5                	j	ffffffffc0200d2a <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d48:	00005517          	auipc	a0,0x5
ffffffffc0200d4c:	48850513          	addi	a0,a0,1160 # ffffffffc02061d0 <commands+0x6c0>
ffffffffc0200d50:	c44ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)// 特殊标记
ffffffffc0200d54:	6458                	ld	a4,136(s0)
ffffffffc0200d56:	47a9                	li	a5,10
ffffffffc0200d58:	fcf711e3          	bne	a4,a5,ffffffffc0200d1a <exception_handler+0x3c>
            tf->epc += 4;//注意返回时要执行ebreak的下一条指令
ffffffffc0200d5c:	10843783          	ld	a5,264(s0)
ffffffffc0200d60:	0791                	addi	a5,a5,4
ffffffffc0200d62:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200d66:	5f2040ef          	jal	ra,ffffffffc0205358 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d6a:	000aa797          	auipc	a5,0xaa
ffffffffc0200d6e:	97e7b783          	ld	a5,-1666(a5) # ffffffffc02aa6e8 <current>
ffffffffc0200d72:	6b9c                	ld	a5,16(a5)
ffffffffc0200d74:	8522                	mv	a0,s0
}
ffffffffc0200d76:	6402                	ld	s0,0(sp)
ffffffffc0200d78:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d7a:	6589                	lui	a1,0x2
ffffffffc0200d7c:	95be                	add	a1,a1,a5
}
ffffffffc0200d7e:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d80:	a48d                	j	ffffffffc0200fe2 <kernel_execve_ret>
        cprintf("Load address misaligned\n");
ffffffffc0200d82:	00005517          	auipc	a0,0x5
ffffffffc0200d86:	45e50513          	addi	a0,a0,1118 # ffffffffc02061e0 <commands+0x6d0>
ffffffffc0200d8a:	b745                	j	ffffffffc0200d2a <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200d8c:	00005517          	auipc	a0,0x5
ffffffffc0200d90:	47450513          	addi	a0,a0,1140 # ffffffffc0206200 <commands+0x6f0>
ffffffffc0200d94:	bf59                	j	ffffffffc0200d2a <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200d96:	00005517          	auipc	a0,0x5
ffffffffc0200d9a:	4b250513          	addi	a0,a0,1202 # ffffffffc0206248 <commands+0x738>
ffffffffc0200d9e:	b771                	j	ffffffffc0200d2a <exception_handler+0x4c>
        cprintf("Environment call from U-mode\n");
ffffffffc0200da0:	00005517          	auipc	a0,0x5
ffffffffc0200da4:	4c050513          	addi	a0,a0,1216 # ffffffffc0206260 <commands+0x750>
        cprintf("Environment call from S-mode\n");
ffffffffc0200da8:	becff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200dac:	10843783          	ld	a5,264(s0)
}
ffffffffc0200db0:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200db2:	0791                	addi	a5,a5,4
ffffffffc0200db4:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200db8:	6402                	ld	s0,0(sp)
ffffffffc0200dba:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200dbc:	59c0406f          	j	ffffffffc0205358 <syscall>
        cprintf("Environment call from S-mode\n");
ffffffffc0200dc0:	00005517          	auipc	a0,0x5
ffffffffc0200dc4:	4c050513          	addi	a0,a0,1216 # ffffffffc0206280 <commands+0x770>
ffffffffc0200dc8:	b7c5                	j	ffffffffc0200da8 <exception_handler+0xca>
        cprintf("Environment call from H-mode\n");
ffffffffc0200dca:	00005517          	auipc	a0,0x5
ffffffffc0200dce:	4d650513          	addi	a0,a0,1238 # ffffffffc02062a0 <commands+0x790>
ffffffffc0200dd2:	bfa1                	j	ffffffffc0200d2a <exception_handler+0x4c>
        cprintf("Environment call from M-mode\n");
ffffffffc0200dd4:	00005517          	auipc	a0,0x5
ffffffffc0200dd8:	4ec50513          	addi	a0,a0,1260 # ffffffffc02062c0 <commands+0x7b0>
ffffffffc0200ddc:	b7b9                	j	ffffffffc0200d2a <exception_handler+0x4c>
        if (do_pgfault(current->mm, 0, tf->tval) != 0)
ffffffffc0200dde:	000aa797          	auipc	a5,0xaa
ffffffffc0200de2:	90a7b783          	ld	a5,-1782(a5) # ffffffffc02aa6e8 <current>
ffffffffc0200de6:	11053603          	ld	a2,272(a0)
ffffffffc0200dea:	7788                	ld	a0,40(a5)
ffffffffc0200dec:	4581                	li	a1,0
ffffffffc0200dee:	72b020ef          	jal	ra,ffffffffc0203d18 <do_pgfault>
ffffffffc0200df2:	d505                	beqz	a0,ffffffffc0200d1a <exception_handler+0x3c>
            print_trapframe(tf);
ffffffffc0200df4:	8522                	mv	a0,s0
ffffffffc0200df6:	dafff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            panic("unhandled instruction page fault\n");
ffffffffc0200dfa:	00005617          	auipc	a2,0x5
ffffffffc0200dfe:	4e660613          	addi	a2,a2,1254 # ffffffffc02062e0 <commands+0x7d0>
ffffffffc0200e02:	0e700593          	li	a1,231
ffffffffc0200e06:	00005517          	auipc	a0,0x5
ffffffffc0200e0a:	42a50513          	addi	a0,a0,1066 # ffffffffc0206230 <commands+0x720>
ffffffffc0200e0e:	e80ff0ef          	jal	ra,ffffffffc020048e <__panic>
        if (do_pgfault(current->mm, 0, tf->tval) != 0)
ffffffffc0200e12:	000aa797          	auipc	a5,0xaa
ffffffffc0200e16:	8d67b783          	ld	a5,-1834(a5) # ffffffffc02aa6e8 <current>
ffffffffc0200e1a:	11053603          	ld	a2,272(a0)
ffffffffc0200e1e:	7788                	ld	a0,40(a5)
ffffffffc0200e20:	4581                	li	a1,0
ffffffffc0200e22:	6f7020ef          	jal	ra,ffffffffc0203d18 <do_pgfault>
ffffffffc0200e26:	ee050ae3          	beqz	a0,ffffffffc0200d1a <exception_handler+0x3c>
            print_trapframe(tf);
ffffffffc0200e2a:	8522                	mv	a0,s0
ffffffffc0200e2c:	d79ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            panic("unhandled load page fault\n");
ffffffffc0200e30:	00005617          	auipc	a2,0x5
ffffffffc0200e34:	4d860613          	addi	a2,a2,1240 # ffffffffc0206308 <commands+0x7f8>
ffffffffc0200e38:	0ef00593          	li	a1,239
ffffffffc0200e3c:	00005517          	auipc	a0,0x5
ffffffffc0200e40:	3f450513          	addi	a0,a0,1012 # ffffffffc0206230 <commands+0x720>
ffffffffc0200e44:	e4aff0ef          	jal	ra,ffffffffc020048e <__panic>
        print_trapframe(tf);
ffffffffc0200e48:	8522                	mv	a0,s0
}
ffffffffc0200e4a:	6402                	ld	s0,0(sp)
ffffffffc0200e4c:	60a2                	ld	ra,8(sp)
ffffffffc0200e4e:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200e50:	bb91                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200e52:	00005617          	auipc	a2,0x5
ffffffffc0200e56:	3c660613          	addi	a2,a2,966 # ffffffffc0206218 <commands+0x708>
ffffffffc0200e5a:	0cd00593          	li	a1,205
ffffffffc0200e5e:	00005517          	auipc	a0,0x5
ffffffffc0200e62:	3d250513          	addi	a0,a0,978 # ffffffffc0206230 <commands+0x720>
ffffffffc0200e66:	e28ff0ef          	jal	ra,ffffffffc020048e <__panic>
            print_trapframe(tf);
ffffffffc0200e6a:	8522                	mv	a0,s0
ffffffffc0200e6c:	d39ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            panic("unhandled store page fault\n");
ffffffffc0200e70:	00005617          	auipc	a2,0x5
ffffffffc0200e74:	4b860613          	addi	a2,a2,1208 # ffffffffc0206328 <commands+0x818>
ffffffffc0200e78:	0f700593          	li	a1,247
ffffffffc0200e7c:	00005517          	auipc	a0,0x5
ffffffffc0200e80:	3b450513          	addi	a0,a0,948 # ffffffffc0206230 <commands+0x720>
ffffffffc0200e84:	e0aff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200e88 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200e88:	1101                	addi	sp,sp,-32
ffffffffc0200e8a:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200e8c:	000aa417          	auipc	s0,0xaa
ffffffffc0200e90:	85c40413          	addi	s0,s0,-1956 # ffffffffc02aa6e8 <current>
ffffffffc0200e94:	6018                	ld	a4,0(s0)
{
ffffffffc0200e96:	ec06                	sd	ra,24(sp)
ffffffffc0200e98:	e426                	sd	s1,8(sp)
ffffffffc0200e9a:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e9c:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200ea0:	cf1d                	beqz	a4,ffffffffc0200ede <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200ea2:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200ea6:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200eaa:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200eac:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200eb0:	0206c463          	bltz	a3,ffffffffc0200ed8 <trap+0x50>
        exception_handler(tf);
ffffffffc0200eb4:	e2bff0ef          	jal	ra,ffffffffc0200cde <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200eb8:	601c                	ld	a5,0(s0)
ffffffffc0200eba:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200ebe:	e499                	bnez	s1,ffffffffc0200ecc <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200ec0:	0b07a703          	lw	a4,176(a5)
ffffffffc0200ec4:	8b05                	andi	a4,a4,1
ffffffffc0200ec6:	e329                	bnez	a4,ffffffffc0200f08 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200ec8:	6f9c                	ld	a5,24(a5)
ffffffffc0200eca:	eb85                	bnez	a5,ffffffffc0200efa <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200ecc:	60e2                	ld	ra,24(sp)
ffffffffc0200ece:	6442                	ld	s0,16(sp)
ffffffffc0200ed0:	64a2                	ld	s1,8(sp)
ffffffffc0200ed2:	6902                	ld	s2,0(sp)
ffffffffc0200ed4:	6105                	addi	sp,sp,32
ffffffffc0200ed6:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200ed8:	d2fff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200edc:	bff1                	j	ffffffffc0200eb8 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200ede:	0006c863          	bltz	a3,ffffffffc0200eee <trap+0x66>
}
ffffffffc0200ee2:	6442                	ld	s0,16(sp)
ffffffffc0200ee4:	60e2                	ld	ra,24(sp)
ffffffffc0200ee6:	64a2                	ld	s1,8(sp)
ffffffffc0200ee8:	6902                	ld	s2,0(sp)
ffffffffc0200eea:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200eec:	bbcd                	j	ffffffffc0200cde <exception_handler>
}
ffffffffc0200eee:	6442                	ld	s0,16(sp)
ffffffffc0200ef0:	60e2                	ld	ra,24(sp)
ffffffffc0200ef2:	64a2                	ld	s1,8(sp)
ffffffffc0200ef4:	6902                	ld	s2,0(sp)
ffffffffc0200ef6:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200ef8:	b339                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200efa:	6442                	ld	s0,16(sp)
ffffffffc0200efc:	60e2                	ld	ra,24(sp)
ffffffffc0200efe:	64a2                	ld	s1,8(sp)
ffffffffc0200f00:	6902                	ld	s2,0(sp)
ffffffffc0200f02:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200f04:	3680406f          	j	ffffffffc020526c <schedule>
                do_exit(-E_KILLED);
ffffffffc0200f08:	555d                	li	a0,-9
ffffffffc0200f0a:	6aa030ef          	jal	ra,ffffffffc02045b4 <do_exit>
            if (current->need_resched)
ffffffffc0200f0e:	601c                	ld	a5,0(s0)
ffffffffc0200f10:	bf65                	j	ffffffffc0200ec8 <trap+0x40>
	...

ffffffffc0200f14 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200f14:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200f18:	00011463          	bnez	sp,ffffffffc0200f20 <__alltraps+0xc>
ffffffffc0200f1c:	14002173          	csrr	sp,sscratch
ffffffffc0200f20:	712d                	addi	sp,sp,-288
ffffffffc0200f22:	e002                	sd	zero,0(sp)
ffffffffc0200f24:	e406                	sd	ra,8(sp)
ffffffffc0200f26:	ec0e                	sd	gp,24(sp)
ffffffffc0200f28:	f012                	sd	tp,32(sp)
ffffffffc0200f2a:	f416                	sd	t0,40(sp)
ffffffffc0200f2c:	f81a                	sd	t1,48(sp)
ffffffffc0200f2e:	fc1e                	sd	t2,56(sp)
ffffffffc0200f30:	e0a2                	sd	s0,64(sp)
ffffffffc0200f32:	e4a6                	sd	s1,72(sp)
ffffffffc0200f34:	e8aa                	sd	a0,80(sp)
ffffffffc0200f36:	ecae                	sd	a1,88(sp)
ffffffffc0200f38:	f0b2                	sd	a2,96(sp)
ffffffffc0200f3a:	f4b6                	sd	a3,104(sp)
ffffffffc0200f3c:	f8ba                	sd	a4,112(sp)
ffffffffc0200f3e:	fcbe                	sd	a5,120(sp)
ffffffffc0200f40:	e142                	sd	a6,128(sp)
ffffffffc0200f42:	e546                	sd	a7,136(sp)
ffffffffc0200f44:	e94a                	sd	s2,144(sp)
ffffffffc0200f46:	ed4e                	sd	s3,152(sp)
ffffffffc0200f48:	f152                	sd	s4,160(sp)
ffffffffc0200f4a:	f556                	sd	s5,168(sp)
ffffffffc0200f4c:	f95a                	sd	s6,176(sp)
ffffffffc0200f4e:	fd5e                	sd	s7,184(sp)
ffffffffc0200f50:	e1e2                	sd	s8,192(sp)
ffffffffc0200f52:	e5e6                	sd	s9,200(sp)
ffffffffc0200f54:	e9ea                	sd	s10,208(sp)
ffffffffc0200f56:	edee                	sd	s11,216(sp)
ffffffffc0200f58:	f1f2                	sd	t3,224(sp)
ffffffffc0200f5a:	f5f6                	sd	t4,232(sp)
ffffffffc0200f5c:	f9fa                	sd	t5,240(sp)
ffffffffc0200f5e:	fdfe                	sd	t6,248(sp)
ffffffffc0200f60:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200f64:	100024f3          	csrr	s1,sstatus
ffffffffc0200f68:	14102973          	csrr	s2,sepc
ffffffffc0200f6c:	143029f3          	csrr	s3,stval
ffffffffc0200f70:	14202a73          	csrr	s4,scause
ffffffffc0200f74:	e822                	sd	s0,16(sp)
ffffffffc0200f76:	e226                	sd	s1,256(sp)
ffffffffc0200f78:	e64a                	sd	s2,264(sp)
ffffffffc0200f7a:	ea4e                	sd	s3,272(sp)
ffffffffc0200f7c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200f7e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200f80:	f09ff0ef          	jal	ra,ffffffffc0200e88 <trap>

ffffffffc0200f84 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200f84:	6492                	ld	s1,256(sp)
ffffffffc0200f86:	6932                	ld	s2,264(sp)
ffffffffc0200f88:	1004f413          	andi	s0,s1,256
ffffffffc0200f8c:	e401                	bnez	s0,ffffffffc0200f94 <__trapret+0x10>
ffffffffc0200f8e:	1200                	addi	s0,sp,288
ffffffffc0200f90:	14041073          	csrw	sscratch,s0
ffffffffc0200f94:	10049073          	csrw	sstatus,s1
ffffffffc0200f98:	14191073          	csrw	sepc,s2
ffffffffc0200f9c:	60a2                	ld	ra,8(sp)
ffffffffc0200f9e:	61e2                	ld	gp,24(sp)
ffffffffc0200fa0:	7202                	ld	tp,32(sp)
ffffffffc0200fa2:	72a2                	ld	t0,40(sp)
ffffffffc0200fa4:	7342                	ld	t1,48(sp)
ffffffffc0200fa6:	73e2                	ld	t2,56(sp)
ffffffffc0200fa8:	6406                	ld	s0,64(sp)
ffffffffc0200faa:	64a6                	ld	s1,72(sp)
ffffffffc0200fac:	6546                	ld	a0,80(sp)
ffffffffc0200fae:	65e6                	ld	a1,88(sp)
ffffffffc0200fb0:	7606                	ld	a2,96(sp)
ffffffffc0200fb2:	76a6                	ld	a3,104(sp)
ffffffffc0200fb4:	7746                	ld	a4,112(sp)
ffffffffc0200fb6:	77e6                	ld	a5,120(sp)
ffffffffc0200fb8:	680a                	ld	a6,128(sp)
ffffffffc0200fba:	68aa                	ld	a7,136(sp)
ffffffffc0200fbc:	694a                	ld	s2,144(sp)
ffffffffc0200fbe:	69ea                	ld	s3,152(sp)
ffffffffc0200fc0:	7a0a                	ld	s4,160(sp)
ffffffffc0200fc2:	7aaa                	ld	s5,168(sp)
ffffffffc0200fc4:	7b4a                	ld	s6,176(sp)
ffffffffc0200fc6:	7bea                	ld	s7,184(sp)
ffffffffc0200fc8:	6c0e                	ld	s8,192(sp)
ffffffffc0200fca:	6cae                	ld	s9,200(sp)
ffffffffc0200fcc:	6d4e                	ld	s10,208(sp)
ffffffffc0200fce:	6dee                	ld	s11,216(sp)
ffffffffc0200fd0:	7e0e                	ld	t3,224(sp)
ffffffffc0200fd2:	7eae                	ld	t4,232(sp)
ffffffffc0200fd4:	7f4e                	ld	t5,240(sp)
ffffffffc0200fd6:	7fee                	ld	t6,248(sp)
ffffffffc0200fd8:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200fda:	10200073          	sret

ffffffffc0200fde <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200fde:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200fe0:	b755                	j	ffffffffc0200f84 <__trapret>

ffffffffc0200fe2 <kernel_execve_ret>:
    //先把 a1 下移 36 个寄存器槽位（陷阱帧大小），作为新 trapframe 的位置（位于当前进程内核栈顶之下）。
    //按序从旧 trapframe（a0 指向）逐项读取保存的寄存器值，写入新 trapframe（a1 指向），共 36 个槽位（通用寄存器 + sstatus/sepc/stval/scause）。
    //把 sp 设为新 trapframe 起始地址 a1。
    //跳转到 __trapret，执行标准的寄存器恢复和 sret，返回到新上下文。
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200fe2:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200fe6:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200fea:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200fee:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200ff2:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200ff6:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200ffa:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200ffe:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0201002:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0201006:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0201008:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc020100a:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc020100c:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc020100e:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0201010:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0201012:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0201014:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0201016:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0201018:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc020101a:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc020101c:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc020101e:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0201020:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0201022:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0201024:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0201026:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0201028:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc020102a:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc020102c:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc020102e:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0201030:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0201032:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0201034:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0201036:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0201038:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc020103a:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc020103c:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc020103e:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0201040:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0201042:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0201044:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0201046:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0201048:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc020104a:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc020104c:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc020104e:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0201050:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0201052:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0201054:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0201056:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0201058:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc020105a:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc020105c:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc020105e:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0201060:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0201062:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0201064:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0201066:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0201068:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc020106a:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc020106c:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc020106e:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0201070:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0201072:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0201074:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0201076:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0201078:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc020107a:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc020107c:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc020107e:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0201080:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0201082:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0201084:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0201086:	812e                	mv	sp,a1
ffffffffc0201088:	bdf5                	j	ffffffffc0200f84 <__trapret>

ffffffffc020108a <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020108a:	000a5797          	auipc	a5,0xa5
ffffffffc020108e:	5c678793          	addi	a5,a5,1478 # ffffffffc02a6650 <free_area>
ffffffffc0201092:	e79c                	sd	a5,8(a5)
ffffffffc0201094:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0201096:	0007a823          	sw	zero,16(a5)
}
ffffffffc020109a:	8082                	ret

ffffffffc020109c <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc020109c:	000a5517          	auipc	a0,0xa5
ffffffffc02010a0:	5c456503          	lwu	a0,1476(a0) # ffffffffc02a6660 <free_area+0x10>
ffffffffc02010a4:	8082                	ret

ffffffffc02010a6 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc02010a6:	715d                	addi	sp,sp,-80
ffffffffc02010a8:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02010aa:	000a5417          	auipc	s0,0xa5
ffffffffc02010ae:	5a640413          	addi	s0,s0,1446 # ffffffffc02a6650 <free_area>
ffffffffc02010b2:	641c                	ld	a5,8(s0)
ffffffffc02010b4:	e486                	sd	ra,72(sp)
ffffffffc02010b6:	fc26                	sd	s1,56(sp)
ffffffffc02010b8:	f84a                	sd	s2,48(sp)
ffffffffc02010ba:	f44e                	sd	s3,40(sp)
ffffffffc02010bc:	f052                	sd	s4,32(sp)
ffffffffc02010be:	ec56                	sd	s5,24(sp)
ffffffffc02010c0:	e85a                	sd	s6,16(sp)
ffffffffc02010c2:	e45e                	sd	s7,8(sp)
ffffffffc02010c4:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02010c6:	2a878d63          	beq	a5,s0,ffffffffc0201380 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc02010ca:	4481                	li	s1,0
ffffffffc02010cc:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02010ce:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02010d2:	8b09                	andi	a4,a4,2
ffffffffc02010d4:	2a070a63          	beqz	a4,ffffffffc0201388 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc02010d8:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010dc:	679c                	ld	a5,8(a5)
ffffffffc02010de:	2905                	addiw	s2,s2,1
ffffffffc02010e0:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02010e2:	fe8796e3          	bne	a5,s0,ffffffffc02010ce <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02010e6:	89a6                	mv	s3,s1
ffffffffc02010e8:	6df000ef          	jal	ra,ffffffffc0201fc6 <nr_free_pages>
ffffffffc02010ec:	6f351e63          	bne	a0,s3,ffffffffc02017e8 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010f0:	4505                	li	a0,1
ffffffffc02010f2:	657000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc02010f6:	8aaa                	mv	s5,a0
ffffffffc02010f8:	42050863          	beqz	a0,ffffffffc0201528 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010fc:	4505                	li	a0,1
ffffffffc02010fe:	64b000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc0201102:	89aa                	mv	s3,a0
ffffffffc0201104:	70050263          	beqz	a0,ffffffffc0201808 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201108:	4505                	li	a0,1
ffffffffc020110a:	63f000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc020110e:	8a2a                	mv	s4,a0
ffffffffc0201110:	48050c63          	beqz	a0,ffffffffc02015a8 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201114:	293a8a63          	beq	s5,s3,ffffffffc02013a8 <default_check+0x302>
ffffffffc0201118:	28aa8863          	beq	s5,a0,ffffffffc02013a8 <default_check+0x302>
ffffffffc020111c:	28a98663          	beq	s3,a0,ffffffffc02013a8 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201120:	000aa783          	lw	a5,0(s5)
ffffffffc0201124:	2a079263          	bnez	a5,ffffffffc02013c8 <default_check+0x322>
ffffffffc0201128:	0009a783          	lw	a5,0(s3)
ffffffffc020112c:	28079e63          	bnez	a5,ffffffffc02013c8 <default_check+0x322>
ffffffffc0201130:	411c                	lw	a5,0(a0)
ffffffffc0201132:	28079b63          	bnez	a5,ffffffffc02013c8 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0201136:	000a9797          	auipc	a5,0xa9
ffffffffc020113a:	5927b783          	ld	a5,1426(a5) # ffffffffc02aa6c8 <pages>
ffffffffc020113e:	40fa8733          	sub	a4,s5,a5
ffffffffc0201142:	00007617          	auipc	a2,0x7
ffffffffc0201146:	8e663603          	ld	a2,-1818(a2) # ffffffffc0207a28 <nbase>
ffffffffc020114a:	8719                	srai	a4,a4,0x6
ffffffffc020114c:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020114e:	000a9697          	auipc	a3,0xa9
ffffffffc0201152:	5726b683          	ld	a3,1394(a3) # ffffffffc02aa6c0 <npage>
ffffffffc0201156:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0201158:	0732                	slli	a4,a4,0xc
ffffffffc020115a:	28d77763          	bgeu	a4,a3,ffffffffc02013e8 <default_check+0x342>
    return page - pages + nbase;
ffffffffc020115e:	40f98733          	sub	a4,s3,a5
ffffffffc0201162:	8719                	srai	a4,a4,0x6
ffffffffc0201164:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201166:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201168:	4cd77063          	bgeu	a4,a3,ffffffffc0201628 <default_check+0x582>
    return page - pages + nbase;
ffffffffc020116c:	40f507b3          	sub	a5,a0,a5
ffffffffc0201170:	8799                	srai	a5,a5,0x6
ffffffffc0201172:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201174:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201176:	30d7f963          	bgeu	a5,a3,ffffffffc0201488 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc020117a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020117c:	00043c03          	ld	s8,0(s0)
ffffffffc0201180:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201184:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0201188:	e400                	sd	s0,8(s0)
ffffffffc020118a:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc020118c:	000a5797          	auipc	a5,0xa5
ffffffffc0201190:	4c07aa23          	sw	zero,1236(a5) # ffffffffc02a6660 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201194:	5b5000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc0201198:	2c051863          	bnez	a0,ffffffffc0201468 <default_check+0x3c2>
    free_page(p0);
ffffffffc020119c:	4585                	li	a1,1
ffffffffc020119e:	8556                	mv	a0,s5
ffffffffc02011a0:	5e7000ef          	jal	ra,ffffffffc0201f86 <free_pages>
    free_page(p1);
ffffffffc02011a4:	4585                	li	a1,1
ffffffffc02011a6:	854e                	mv	a0,s3
ffffffffc02011a8:	5df000ef          	jal	ra,ffffffffc0201f86 <free_pages>
    free_page(p2);
ffffffffc02011ac:	4585                	li	a1,1
ffffffffc02011ae:	8552                	mv	a0,s4
ffffffffc02011b0:	5d7000ef          	jal	ra,ffffffffc0201f86 <free_pages>
    assert(nr_free == 3);
ffffffffc02011b4:	4818                	lw	a4,16(s0)
ffffffffc02011b6:	478d                	li	a5,3
ffffffffc02011b8:	28f71863          	bne	a4,a5,ffffffffc0201448 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011bc:	4505                	li	a0,1
ffffffffc02011be:	58b000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc02011c2:	89aa                	mv	s3,a0
ffffffffc02011c4:	26050263          	beqz	a0,ffffffffc0201428 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011c8:	4505                	li	a0,1
ffffffffc02011ca:	57f000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc02011ce:	8aaa                	mv	s5,a0
ffffffffc02011d0:	3a050c63          	beqz	a0,ffffffffc0201588 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011d4:	4505                	li	a0,1
ffffffffc02011d6:	573000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc02011da:	8a2a                	mv	s4,a0
ffffffffc02011dc:	38050663          	beqz	a0,ffffffffc0201568 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc02011e0:	4505                	li	a0,1
ffffffffc02011e2:	567000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc02011e6:	36051163          	bnez	a0,ffffffffc0201548 <default_check+0x4a2>
    free_page(p0);
ffffffffc02011ea:	4585                	li	a1,1
ffffffffc02011ec:	854e                	mv	a0,s3
ffffffffc02011ee:	599000ef          	jal	ra,ffffffffc0201f86 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02011f2:	641c                	ld	a5,8(s0)
ffffffffc02011f4:	20878a63          	beq	a5,s0,ffffffffc0201408 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc02011f8:	4505                	li	a0,1
ffffffffc02011fa:	54f000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc02011fe:	30a99563          	bne	s3,a0,ffffffffc0201508 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201202:	4505                	li	a0,1
ffffffffc0201204:	545000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc0201208:	2e051063          	bnez	a0,ffffffffc02014e8 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc020120c:	481c                	lw	a5,16(s0)
ffffffffc020120e:	2a079d63          	bnez	a5,ffffffffc02014c8 <default_check+0x422>
    free_page(p);
ffffffffc0201212:	854e                	mv	a0,s3
ffffffffc0201214:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201216:	01843023          	sd	s8,0(s0)
ffffffffc020121a:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020121e:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201222:	565000ef          	jal	ra,ffffffffc0201f86 <free_pages>
    free_page(p1);
ffffffffc0201226:	4585                	li	a1,1
ffffffffc0201228:	8556                	mv	a0,s5
ffffffffc020122a:	55d000ef          	jal	ra,ffffffffc0201f86 <free_pages>
    free_page(p2);
ffffffffc020122e:	4585                	li	a1,1
ffffffffc0201230:	8552                	mv	a0,s4
ffffffffc0201232:	555000ef          	jal	ra,ffffffffc0201f86 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201236:	4515                	li	a0,5
ffffffffc0201238:	511000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc020123c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020123e:	26050563          	beqz	a0,ffffffffc02014a8 <default_check+0x402>
ffffffffc0201242:	651c                	ld	a5,8(a0)
ffffffffc0201244:	8385                	srli	a5,a5,0x1
ffffffffc0201246:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201248:	54079063          	bnez	a5,ffffffffc0201788 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020124c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020124e:	00043b03          	ld	s6,0(s0)
ffffffffc0201252:	00843a83          	ld	s5,8(s0)
ffffffffc0201256:	e000                	sd	s0,0(s0)
ffffffffc0201258:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020125a:	4ef000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc020125e:	50051563          	bnez	a0,ffffffffc0201768 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201262:	08098a13          	addi	s4,s3,128
ffffffffc0201266:	8552                	mv	a0,s4
ffffffffc0201268:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020126a:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc020126e:	000a5797          	auipc	a5,0xa5
ffffffffc0201272:	3e07a923          	sw	zero,1010(a5) # ffffffffc02a6660 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201276:	511000ef          	jal	ra,ffffffffc0201f86 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020127a:	4511                	li	a0,4
ffffffffc020127c:	4cd000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc0201280:	4c051463          	bnez	a0,ffffffffc0201748 <default_check+0x6a2>
ffffffffc0201284:	0889b783          	ld	a5,136(s3)
ffffffffc0201288:	8385                	srli	a5,a5,0x1
ffffffffc020128a:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020128c:	48078e63          	beqz	a5,ffffffffc0201728 <default_check+0x682>
ffffffffc0201290:	0909a703          	lw	a4,144(s3)
ffffffffc0201294:	478d                	li	a5,3
ffffffffc0201296:	48f71963          	bne	a4,a5,ffffffffc0201728 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020129a:	450d                	li	a0,3
ffffffffc020129c:	4ad000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc02012a0:	8c2a                	mv	s8,a0
ffffffffc02012a2:	46050363          	beqz	a0,ffffffffc0201708 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02012a6:	4505                	li	a0,1
ffffffffc02012a8:	4a1000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc02012ac:	42051e63          	bnez	a0,ffffffffc02016e8 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02012b0:	418a1c63          	bne	s4,s8,ffffffffc02016c8 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02012b4:	4585                	li	a1,1
ffffffffc02012b6:	854e                	mv	a0,s3
ffffffffc02012b8:	4cf000ef          	jal	ra,ffffffffc0201f86 <free_pages>
    free_pages(p1, 3);
ffffffffc02012bc:	458d                	li	a1,3
ffffffffc02012be:	8552                	mv	a0,s4
ffffffffc02012c0:	4c7000ef          	jal	ra,ffffffffc0201f86 <free_pages>
ffffffffc02012c4:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02012c8:	04098c13          	addi	s8,s3,64
ffffffffc02012cc:	8385                	srli	a5,a5,0x1
ffffffffc02012ce:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02012d0:	3c078c63          	beqz	a5,ffffffffc02016a8 <default_check+0x602>
ffffffffc02012d4:	0109a703          	lw	a4,16(s3)
ffffffffc02012d8:	4785                	li	a5,1
ffffffffc02012da:	3cf71763          	bne	a4,a5,ffffffffc02016a8 <default_check+0x602>
ffffffffc02012de:	008a3783          	ld	a5,8(s4)
ffffffffc02012e2:	8385                	srli	a5,a5,0x1
ffffffffc02012e4:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02012e6:	3a078163          	beqz	a5,ffffffffc0201688 <default_check+0x5e2>
ffffffffc02012ea:	010a2703          	lw	a4,16(s4)
ffffffffc02012ee:	478d                	li	a5,3
ffffffffc02012f0:	38f71c63          	bne	a4,a5,ffffffffc0201688 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02012f4:	4505                	li	a0,1
ffffffffc02012f6:	453000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc02012fa:	36a99763          	bne	s3,a0,ffffffffc0201668 <default_check+0x5c2>
    free_page(p0);
ffffffffc02012fe:	4585                	li	a1,1
ffffffffc0201300:	487000ef          	jal	ra,ffffffffc0201f86 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201304:	4509                	li	a0,2
ffffffffc0201306:	443000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc020130a:	32aa1f63          	bne	s4,a0,ffffffffc0201648 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020130e:	4589                	li	a1,2
ffffffffc0201310:	477000ef          	jal	ra,ffffffffc0201f86 <free_pages>
    free_page(p2);
ffffffffc0201314:	4585                	li	a1,1
ffffffffc0201316:	8562                	mv	a0,s8
ffffffffc0201318:	46f000ef          	jal	ra,ffffffffc0201f86 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020131c:	4515                	li	a0,5
ffffffffc020131e:	42b000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc0201322:	89aa                	mv	s3,a0
ffffffffc0201324:	48050263          	beqz	a0,ffffffffc02017a8 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201328:	4505                	li	a0,1
ffffffffc020132a:	41f000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc020132e:	2c051d63          	bnez	a0,ffffffffc0201608 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201332:	481c                	lw	a5,16(s0)
ffffffffc0201334:	2a079a63          	bnez	a5,ffffffffc02015e8 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201338:	4595                	li	a1,5
ffffffffc020133a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020133c:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201340:	01643023          	sd	s6,0(s0)
ffffffffc0201344:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201348:	43f000ef          	jal	ra,ffffffffc0201f86 <free_pages>
    return listelm->next;
ffffffffc020134c:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020134e:	00878963          	beq	a5,s0,ffffffffc0201360 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201352:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201356:	679c                	ld	a5,8(a5)
ffffffffc0201358:	397d                	addiw	s2,s2,-1
ffffffffc020135a:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020135c:	fe879be3          	bne	a5,s0,ffffffffc0201352 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201360:	26091463          	bnez	s2,ffffffffc02015c8 <default_check+0x522>
    assert(total == 0);
ffffffffc0201364:	46049263          	bnez	s1,ffffffffc02017c8 <default_check+0x722>
}
ffffffffc0201368:	60a6                	ld	ra,72(sp)
ffffffffc020136a:	6406                	ld	s0,64(sp)
ffffffffc020136c:	74e2                	ld	s1,56(sp)
ffffffffc020136e:	7942                	ld	s2,48(sp)
ffffffffc0201370:	79a2                	ld	s3,40(sp)
ffffffffc0201372:	7a02                	ld	s4,32(sp)
ffffffffc0201374:	6ae2                	ld	s5,24(sp)
ffffffffc0201376:	6b42                	ld	s6,16(sp)
ffffffffc0201378:	6ba2                	ld	s7,8(sp)
ffffffffc020137a:	6c02                	ld	s8,0(sp)
ffffffffc020137c:	6161                	addi	sp,sp,80
ffffffffc020137e:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201380:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201382:	4481                	li	s1,0
ffffffffc0201384:	4901                	li	s2,0
ffffffffc0201386:	b38d                	j	ffffffffc02010e8 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201388:	00005697          	auipc	a3,0x5
ffffffffc020138c:	00068693          	mv	a3,a3
ffffffffc0201390:	00005617          	auipc	a2,0x5
ffffffffc0201394:	00860613          	addi	a2,a2,8 # ffffffffc0206398 <commands+0x888>
ffffffffc0201398:	11000593          	li	a1,272
ffffffffc020139c:	00005517          	auipc	a0,0x5
ffffffffc02013a0:	01450513          	addi	a0,a0,20 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02013a4:	8eaff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02013a8:	00005697          	auipc	a3,0x5
ffffffffc02013ac:	0a068693          	addi	a3,a3,160 # ffffffffc0206448 <commands+0x938>
ffffffffc02013b0:	00005617          	auipc	a2,0x5
ffffffffc02013b4:	fe860613          	addi	a2,a2,-24 # ffffffffc0206398 <commands+0x888>
ffffffffc02013b8:	0db00593          	li	a1,219
ffffffffc02013bc:	00005517          	auipc	a0,0x5
ffffffffc02013c0:	ff450513          	addi	a0,a0,-12 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02013c4:	8caff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02013c8:	00005697          	auipc	a3,0x5
ffffffffc02013cc:	0a868693          	addi	a3,a3,168 # ffffffffc0206470 <commands+0x960>
ffffffffc02013d0:	00005617          	auipc	a2,0x5
ffffffffc02013d4:	fc860613          	addi	a2,a2,-56 # ffffffffc0206398 <commands+0x888>
ffffffffc02013d8:	0dc00593          	li	a1,220
ffffffffc02013dc:	00005517          	auipc	a0,0x5
ffffffffc02013e0:	fd450513          	addi	a0,a0,-44 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02013e4:	8aaff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02013e8:	00005697          	auipc	a3,0x5
ffffffffc02013ec:	0c868693          	addi	a3,a3,200 # ffffffffc02064b0 <commands+0x9a0>
ffffffffc02013f0:	00005617          	auipc	a2,0x5
ffffffffc02013f4:	fa860613          	addi	a2,a2,-88 # ffffffffc0206398 <commands+0x888>
ffffffffc02013f8:	0de00593          	li	a1,222
ffffffffc02013fc:	00005517          	auipc	a0,0x5
ffffffffc0201400:	fb450513          	addi	a0,a0,-76 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201404:	88aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201408:	00005697          	auipc	a3,0x5
ffffffffc020140c:	13068693          	addi	a3,a3,304 # ffffffffc0206538 <commands+0xa28>
ffffffffc0201410:	00005617          	auipc	a2,0x5
ffffffffc0201414:	f8860613          	addi	a2,a2,-120 # ffffffffc0206398 <commands+0x888>
ffffffffc0201418:	0f700593          	li	a1,247
ffffffffc020141c:	00005517          	auipc	a0,0x5
ffffffffc0201420:	f9450513          	addi	a0,a0,-108 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201424:	86aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201428:	00005697          	auipc	a3,0x5
ffffffffc020142c:	fc068693          	addi	a3,a3,-64 # ffffffffc02063e8 <commands+0x8d8>
ffffffffc0201430:	00005617          	auipc	a2,0x5
ffffffffc0201434:	f6860613          	addi	a2,a2,-152 # ffffffffc0206398 <commands+0x888>
ffffffffc0201438:	0f000593          	li	a1,240
ffffffffc020143c:	00005517          	auipc	a0,0x5
ffffffffc0201440:	f7450513          	addi	a0,a0,-140 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201444:	84aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc0201448:	00005697          	auipc	a3,0x5
ffffffffc020144c:	0e068693          	addi	a3,a3,224 # ffffffffc0206528 <commands+0xa18>
ffffffffc0201450:	00005617          	auipc	a2,0x5
ffffffffc0201454:	f4860613          	addi	a2,a2,-184 # ffffffffc0206398 <commands+0x888>
ffffffffc0201458:	0ee00593          	li	a1,238
ffffffffc020145c:	00005517          	auipc	a0,0x5
ffffffffc0201460:	f5450513          	addi	a0,a0,-172 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201464:	82aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201468:	00005697          	auipc	a3,0x5
ffffffffc020146c:	0a868693          	addi	a3,a3,168 # ffffffffc0206510 <commands+0xa00>
ffffffffc0201470:	00005617          	auipc	a2,0x5
ffffffffc0201474:	f2860613          	addi	a2,a2,-216 # ffffffffc0206398 <commands+0x888>
ffffffffc0201478:	0e900593          	li	a1,233
ffffffffc020147c:	00005517          	auipc	a0,0x5
ffffffffc0201480:	f3450513          	addi	a0,a0,-204 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201484:	80aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201488:	00005697          	auipc	a3,0x5
ffffffffc020148c:	06868693          	addi	a3,a3,104 # ffffffffc02064f0 <commands+0x9e0>
ffffffffc0201490:	00005617          	auipc	a2,0x5
ffffffffc0201494:	f0860613          	addi	a2,a2,-248 # ffffffffc0206398 <commands+0x888>
ffffffffc0201498:	0e000593          	li	a1,224
ffffffffc020149c:	00005517          	auipc	a0,0x5
ffffffffc02014a0:	f1450513          	addi	a0,a0,-236 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02014a4:	febfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc02014a8:	00005697          	auipc	a3,0x5
ffffffffc02014ac:	0d868693          	addi	a3,a3,216 # ffffffffc0206580 <commands+0xa70>
ffffffffc02014b0:	00005617          	auipc	a2,0x5
ffffffffc02014b4:	ee860613          	addi	a2,a2,-280 # ffffffffc0206398 <commands+0x888>
ffffffffc02014b8:	11800593          	li	a1,280
ffffffffc02014bc:	00005517          	auipc	a0,0x5
ffffffffc02014c0:	ef450513          	addi	a0,a0,-268 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02014c4:	fcbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02014c8:	00005697          	auipc	a3,0x5
ffffffffc02014cc:	0a868693          	addi	a3,a3,168 # ffffffffc0206570 <commands+0xa60>
ffffffffc02014d0:	00005617          	auipc	a2,0x5
ffffffffc02014d4:	ec860613          	addi	a2,a2,-312 # ffffffffc0206398 <commands+0x888>
ffffffffc02014d8:	0fd00593          	li	a1,253
ffffffffc02014dc:	00005517          	auipc	a0,0x5
ffffffffc02014e0:	ed450513          	addi	a0,a0,-300 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02014e4:	fabfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014e8:	00005697          	auipc	a3,0x5
ffffffffc02014ec:	02868693          	addi	a3,a3,40 # ffffffffc0206510 <commands+0xa00>
ffffffffc02014f0:	00005617          	auipc	a2,0x5
ffffffffc02014f4:	ea860613          	addi	a2,a2,-344 # ffffffffc0206398 <commands+0x888>
ffffffffc02014f8:	0fb00593          	li	a1,251
ffffffffc02014fc:	00005517          	auipc	a0,0x5
ffffffffc0201500:	eb450513          	addi	a0,a0,-332 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201504:	f8bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201508:	00005697          	auipc	a3,0x5
ffffffffc020150c:	04868693          	addi	a3,a3,72 # ffffffffc0206550 <commands+0xa40>
ffffffffc0201510:	00005617          	auipc	a2,0x5
ffffffffc0201514:	e8860613          	addi	a2,a2,-376 # ffffffffc0206398 <commands+0x888>
ffffffffc0201518:	0fa00593          	li	a1,250
ffffffffc020151c:	00005517          	auipc	a0,0x5
ffffffffc0201520:	e9450513          	addi	a0,a0,-364 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201524:	f6bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201528:	00005697          	auipc	a3,0x5
ffffffffc020152c:	ec068693          	addi	a3,a3,-320 # ffffffffc02063e8 <commands+0x8d8>
ffffffffc0201530:	00005617          	auipc	a2,0x5
ffffffffc0201534:	e6860613          	addi	a2,a2,-408 # ffffffffc0206398 <commands+0x888>
ffffffffc0201538:	0d700593          	li	a1,215
ffffffffc020153c:	00005517          	auipc	a0,0x5
ffffffffc0201540:	e7450513          	addi	a0,a0,-396 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201544:	f4bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201548:	00005697          	auipc	a3,0x5
ffffffffc020154c:	fc868693          	addi	a3,a3,-56 # ffffffffc0206510 <commands+0xa00>
ffffffffc0201550:	00005617          	auipc	a2,0x5
ffffffffc0201554:	e4860613          	addi	a2,a2,-440 # ffffffffc0206398 <commands+0x888>
ffffffffc0201558:	0f400593          	li	a1,244
ffffffffc020155c:	00005517          	auipc	a0,0x5
ffffffffc0201560:	e5450513          	addi	a0,a0,-428 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201564:	f2bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201568:	00005697          	auipc	a3,0x5
ffffffffc020156c:	ec068693          	addi	a3,a3,-320 # ffffffffc0206428 <commands+0x918>
ffffffffc0201570:	00005617          	auipc	a2,0x5
ffffffffc0201574:	e2860613          	addi	a2,a2,-472 # ffffffffc0206398 <commands+0x888>
ffffffffc0201578:	0f200593          	li	a1,242
ffffffffc020157c:	00005517          	auipc	a0,0x5
ffffffffc0201580:	e3450513          	addi	a0,a0,-460 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201584:	f0bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201588:	00005697          	auipc	a3,0x5
ffffffffc020158c:	e8068693          	addi	a3,a3,-384 # ffffffffc0206408 <commands+0x8f8>
ffffffffc0201590:	00005617          	auipc	a2,0x5
ffffffffc0201594:	e0860613          	addi	a2,a2,-504 # ffffffffc0206398 <commands+0x888>
ffffffffc0201598:	0f100593          	li	a1,241
ffffffffc020159c:	00005517          	auipc	a0,0x5
ffffffffc02015a0:	e1450513          	addi	a0,a0,-492 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02015a4:	eebfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02015a8:	00005697          	auipc	a3,0x5
ffffffffc02015ac:	e8068693          	addi	a3,a3,-384 # ffffffffc0206428 <commands+0x918>
ffffffffc02015b0:	00005617          	auipc	a2,0x5
ffffffffc02015b4:	de860613          	addi	a2,a2,-536 # ffffffffc0206398 <commands+0x888>
ffffffffc02015b8:	0d900593          	li	a1,217
ffffffffc02015bc:	00005517          	auipc	a0,0x5
ffffffffc02015c0:	df450513          	addi	a0,a0,-524 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02015c4:	ecbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc02015c8:	00005697          	auipc	a3,0x5
ffffffffc02015cc:	10868693          	addi	a3,a3,264 # ffffffffc02066d0 <commands+0xbc0>
ffffffffc02015d0:	00005617          	auipc	a2,0x5
ffffffffc02015d4:	dc860613          	addi	a2,a2,-568 # ffffffffc0206398 <commands+0x888>
ffffffffc02015d8:	14600593          	li	a1,326
ffffffffc02015dc:	00005517          	auipc	a0,0x5
ffffffffc02015e0:	dd450513          	addi	a0,a0,-556 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02015e4:	eabfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02015e8:	00005697          	auipc	a3,0x5
ffffffffc02015ec:	f8868693          	addi	a3,a3,-120 # ffffffffc0206570 <commands+0xa60>
ffffffffc02015f0:	00005617          	auipc	a2,0x5
ffffffffc02015f4:	da860613          	addi	a2,a2,-600 # ffffffffc0206398 <commands+0x888>
ffffffffc02015f8:	13a00593          	li	a1,314
ffffffffc02015fc:	00005517          	auipc	a0,0x5
ffffffffc0201600:	db450513          	addi	a0,a0,-588 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201604:	e8bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201608:	00005697          	auipc	a3,0x5
ffffffffc020160c:	f0868693          	addi	a3,a3,-248 # ffffffffc0206510 <commands+0xa00>
ffffffffc0201610:	00005617          	auipc	a2,0x5
ffffffffc0201614:	d8860613          	addi	a2,a2,-632 # ffffffffc0206398 <commands+0x888>
ffffffffc0201618:	13800593          	li	a1,312
ffffffffc020161c:	00005517          	auipc	a0,0x5
ffffffffc0201620:	d9450513          	addi	a0,a0,-620 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201624:	e6bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201628:	00005697          	auipc	a3,0x5
ffffffffc020162c:	ea868693          	addi	a3,a3,-344 # ffffffffc02064d0 <commands+0x9c0>
ffffffffc0201630:	00005617          	auipc	a2,0x5
ffffffffc0201634:	d6860613          	addi	a2,a2,-664 # ffffffffc0206398 <commands+0x888>
ffffffffc0201638:	0df00593          	li	a1,223
ffffffffc020163c:	00005517          	auipc	a0,0x5
ffffffffc0201640:	d7450513          	addi	a0,a0,-652 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201644:	e4bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201648:	00005697          	auipc	a3,0x5
ffffffffc020164c:	04868693          	addi	a3,a3,72 # ffffffffc0206690 <commands+0xb80>
ffffffffc0201650:	00005617          	auipc	a2,0x5
ffffffffc0201654:	d4860613          	addi	a2,a2,-696 # ffffffffc0206398 <commands+0x888>
ffffffffc0201658:	13200593          	li	a1,306
ffffffffc020165c:	00005517          	auipc	a0,0x5
ffffffffc0201660:	d5450513          	addi	a0,a0,-684 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201664:	e2bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201668:	00005697          	auipc	a3,0x5
ffffffffc020166c:	00868693          	addi	a3,a3,8 # ffffffffc0206670 <commands+0xb60>
ffffffffc0201670:	00005617          	auipc	a2,0x5
ffffffffc0201674:	d2860613          	addi	a2,a2,-728 # ffffffffc0206398 <commands+0x888>
ffffffffc0201678:	13000593          	li	a1,304
ffffffffc020167c:	00005517          	auipc	a0,0x5
ffffffffc0201680:	d3450513          	addi	a0,a0,-716 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201684:	e0bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201688:	00005697          	auipc	a3,0x5
ffffffffc020168c:	fc068693          	addi	a3,a3,-64 # ffffffffc0206648 <commands+0xb38>
ffffffffc0201690:	00005617          	auipc	a2,0x5
ffffffffc0201694:	d0860613          	addi	a2,a2,-760 # ffffffffc0206398 <commands+0x888>
ffffffffc0201698:	12e00593          	li	a1,302
ffffffffc020169c:	00005517          	auipc	a0,0x5
ffffffffc02016a0:	d1450513          	addi	a0,a0,-748 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02016a4:	debfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02016a8:	00005697          	auipc	a3,0x5
ffffffffc02016ac:	f7868693          	addi	a3,a3,-136 # ffffffffc0206620 <commands+0xb10>
ffffffffc02016b0:	00005617          	auipc	a2,0x5
ffffffffc02016b4:	ce860613          	addi	a2,a2,-792 # ffffffffc0206398 <commands+0x888>
ffffffffc02016b8:	12d00593          	li	a1,301
ffffffffc02016bc:	00005517          	auipc	a0,0x5
ffffffffc02016c0:	cf450513          	addi	a0,a0,-780 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02016c4:	dcbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc02016c8:	00005697          	auipc	a3,0x5
ffffffffc02016cc:	f4868693          	addi	a3,a3,-184 # ffffffffc0206610 <commands+0xb00>
ffffffffc02016d0:	00005617          	auipc	a2,0x5
ffffffffc02016d4:	cc860613          	addi	a2,a2,-824 # ffffffffc0206398 <commands+0x888>
ffffffffc02016d8:	12800593          	li	a1,296
ffffffffc02016dc:	00005517          	auipc	a0,0x5
ffffffffc02016e0:	cd450513          	addi	a0,a0,-812 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02016e4:	dabfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016e8:	00005697          	auipc	a3,0x5
ffffffffc02016ec:	e2868693          	addi	a3,a3,-472 # ffffffffc0206510 <commands+0xa00>
ffffffffc02016f0:	00005617          	auipc	a2,0x5
ffffffffc02016f4:	ca860613          	addi	a2,a2,-856 # ffffffffc0206398 <commands+0x888>
ffffffffc02016f8:	12700593          	li	a1,295
ffffffffc02016fc:	00005517          	auipc	a0,0x5
ffffffffc0201700:	cb450513          	addi	a0,a0,-844 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201704:	d8bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201708:	00005697          	auipc	a3,0x5
ffffffffc020170c:	ee868693          	addi	a3,a3,-280 # ffffffffc02065f0 <commands+0xae0>
ffffffffc0201710:	00005617          	auipc	a2,0x5
ffffffffc0201714:	c8860613          	addi	a2,a2,-888 # ffffffffc0206398 <commands+0x888>
ffffffffc0201718:	12600593          	li	a1,294
ffffffffc020171c:	00005517          	auipc	a0,0x5
ffffffffc0201720:	c9450513          	addi	a0,a0,-876 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201724:	d6bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201728:	00005697          	auipc	a3,0x5
ffffffffc020172c:	e9868693          	addi	a3,a3,-360 # ffffffffc02065c0 <commands+0xab0>
ffffffffc0201730:	00005617          	auipc	a2,0x5
ffffffffc0201734:	c6860613          	addi	a2,a2,-920 # ffffffffc0206398 <commands+0x888>
ffffffffc0201738:	12500593          	li	a1,293
ffffffffc020173c:	00005517          	auipc	a0,0x5
ffffffffc0201740:	c7450513          	addi	a0,a0,-908 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201744:	d4bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201748:	00005697          	auipc	a3,0x5
ffffffffc020174c:	e6068693          	addi	a3,a3,-416 # ffffffffc02065a8 <commands+0xa98>
ffffffffc0201750:	00005617          	auipc	a2,0x5
ffffffffc0201754:	c4860613          	addi	a2,a2,-952 # ffffffffc0206398 <commands+0x888>
ffffffffc0201758:	12400593          	li	a1,292
ffffffffc020175c:	00005517          	auipc	a0,0x5
ffffffffc0201760:	c5450513          	addi	a0,a0,-940 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201764:	d2bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201768:	00005697          	auipc	a3,0x5
ffffffffc020176c:	da868693          	addi	a3,a3,-600 # ffffffffc0206510 <commands+0xa00>
ffffffffc0201770:	00005617          	auipc	a2,0x5
ffffffffc0201774:	c2860613          	addi	a2,a2,-984 # ffffffffc0206398 <commands+0x888>
ffffffffc0201778:	11e00593          	li	a1,286
ffffffffc020177c:	00005517          	auipc	a0,0x5
ffffffffc0201780:	c3450513          	addi	a0,a0,-972 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201784:	d0bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc0201788:	00005697          	auipc	a3,0x5
ffffffffc020178c:	e0868693          	addi	a3,a3,-504 # ffffffffc0206590 <commands+0xa80>
ffffffffc0201790:	00005617          	auipc	a2,0x5
ffffffffc0201794:	c0860613          	addi	a2,a2,-1016 # ffffffffc0206398 <commands+0x888>
ffffffffc0201798:	11900593          	li	a1,281
ffffffffc020179c:	00005517          	auipc	a0,0x5
ffffffffc02017a0:	c1450513          	addi	a0,a0,-1004 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02017a4:	cebfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02017a8:	00005697          	auipc	a3,0x5
ffffffffc02017ac:	f0868693          	addi	a3,a3,-248 # ffffffffc02066b0 <commands+0xba0>
ffffffffc02017b0:	00005617          	auipc	a2,0x5
ffffffffc02017b4:	be860613          	addi	a2,a2,-1048 # ffffffffc0206398 <commands+0x888>
ffffffffc02017b8:	13700593          	li	a1,311
ffffffffc02017bc:	00005517          	auipc	a0,0x5
ffffffffc02017c0:	bf450513          	addi	a0,a0,-1036 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02017c4:	ccbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc02017c8:	00005697          	auipc	a3,0x5
ffffffffc02017cc:	f1868693          	addi	a3,a3,-232 # ffffffffc02066e0 <commands+0xbd0>
ffffffffc02017d0:	00005617          	auipc	a2,0x5
ffffffffc02017d4:	bc860613          	addi	a2,a2,-1080 # ffffffffc0206398 <commands+0x888>
ffffffffc02017d8:	14700593          	li	a1,327
ffffffffc02017dc:	00005517          	auipc	a0,0x5
ffffffffc02017e0:	bd450513          	addi	a0,a0,-1068 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc02017e4:	cabfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc02017e8:	00005697          	auipc	a3,0x5
ffffffffc02017ec:	be068693          	addi	a3,a3,-1056 # ffffffffc02063c8 <commands+0x8b8>
ffffffffc02017f0:	00005617          	auipc	a2,0x5
ffffffffc02017f4:	ba860613          	addi	a2,a2,-1112 # ffffffffc0206398 <commands+0x888>
ffffffffc02017f8:	11300593          	li	a1,275
ffffffffc02017fc:	00005517          	auipc	a0,0x5
ffffffffc0201800:	bb450513          	addi	a0,a0,-1100 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201804:	c8bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201808:	00005697          	auipc	a3,0x5
ffffffffc020180c:	c0068693          	addi	a3,a3,-1024 # ffffffffc0206408 <commands+0x8f8>
ffffffffc0201810:	00005617          	auipc	a2,0x5
ffffffffc0201814:	b8860613          	addi	a2,a2,-1144 # ffffffffc0206398 <commands+0x888>
ffffffffc0201818:	0d800593          	li	a1,216
ffffffffc020181c:	00005517          	auipc	a0,0x5
ffffffffc0201820:	b9450513          	addi	a0,a0,-1132 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201824:	c6bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201828 <default_free_pages>:
{
ffffffffc0201828:	1141                	addi	sp,sp,-16
ffffffffc020182a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020182c:	14058463          	beqz	a1,ffffffffc0201974 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201830:	00659693          	slli	a3,a1,0x6
ffffffffc0201834:	96aa                	add	a3,a3,a0
ffffffffc0201836:	87aa                	mv	a5,a0
ffffffffc0201838:	02d50263          	beq	a0,a3,ffffffffc020185c <default_free_pages+0x34>
ffffffffc020183c:	6798                	ld	a4,8(a5)
ffffffffc020183e:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201840:	10071a63          	bnez	a4,ffffffffc0201954 <default_free_pages+0x12c>
ffffffffc0201844:	6798                	ld	a4,8(a5)
ffffffffc0201846:	8b09                	andi	a4,a4,2
ffffffffc0201848:	10071663          	bnez	a4,ffffffffc0201954 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc020184c:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201850:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201854:	04078793          	addi	a5,a5,64
ffffffffc0201858:	fed792e3          	bne	a5,a3,ffffffffc020183c <default_free_pages+0x14>
    base->property = n;
ffffffffc020185c:	2581                	sext.w	a1,a1
ffffffffc020185e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201860:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201864:	4789                	li	a5,2
ffffffffc0201866:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020186a:	000a5697          	auipc	a3,0xa5
ffffffffc020186e:	de668693          	addi	a3,a3,-538 # ffffffffc02a6650 <free_area>
ffffffffc0201872:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201874:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201876:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020187a:	9db9                	addw	a1,a1,a4
ffffffffc020187c:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc020187e:	0ad78463          	beq	a5,a3,ffffffffc0201926 <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc0201882:	fe878713          	addi	a4,a5,-24
ffffffffc0201886:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc020188a:	4581                	li	a1,0
            if (base < page)
ffffffffc020188c:	00e56a63          	bltu	a0,a4,ffffffffc02018a0 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201890:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201892:	04d70c63          	beq	a4,a3,ffffffffc02018ea <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc0201896:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201898:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc020189c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201890 <default_free_pages+0x68>
ffffffffc02018a0:	c199                	beqz	a1,ffffffffc02018a6 <default_free_pages+0x7e>
ffffffffc02018a2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02018a6:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02018a8:	e390                	sd	a2,0(a5)
ffffffffc02018aa:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02018ac:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018ae:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02018b0:	00d70d63          	beq	a4,a3,ffffffffc02018ca <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02018b4:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02018b8:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02018bc:	02059813          	slli	a6,a1,0x20
ffffffffc02018c0:	01a85793          	srli	a5,a6,0x1a
ffffffffc02018c4:	97b2                	add	a5,a5,a2
ffffffffc02018c6:	02f50c63          	beq	a0,a5,ffffffffc02018fe <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02018ca:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02018cc:	00d78c63          	beq	a5,a3,ffffffffc02018e4 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02018d0:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02018d2:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02018d6:	02061593          	slli	a1,a2,0x20
ffffffffc02018da:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02018de:	972a                	add	a4,a4,a0
ffffffffc02018e0:	04e68a63          	beq	a3,a4,ffffffffc0201934 <default_free_pages+0x10c>
}
ffffffffc02018e4:	60a2                	ld	ra,8(sp)
ffffffffc02018e6:	0141                	addi	sp,sp,16
ffffffffc02018e8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02018ea:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018ec:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02018ee:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02018f0:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc02018f2:	02d70763          	beq	a4,a3,ffffffffc0201920 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc02018f6:	8832                	mv	a6,a2
ffffffffc02018f8:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc02018fa:	87ba                	mv	a5,a4
ffffffffc02018fc:	bf71                	j	ffffffffc0201898 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02018fe:	491c                	lw	a5,16(a0)
ffffffffc0201900:	9dbd                	addw	a1,a1,a5
ffffffffc0201902:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201906:	57f5                	li	a5,-3
ffffffffc0201908:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020190c:	01853803          	ld	a6,24(a0)
ffffffffc0201910:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201912:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201914:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201918:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020191a:	0105b023          	sd	a6,0(a1)
ffffffffc020191e:	b77d                	j	ffffffffc02018cc <default_free_pages+0xa4>
ffffffffc0201920:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201922:	873e                	mv	a4,a5
ffffffffc0201924:	bf41                	j	ffffffffc02018b4 <default_free_pages+0x8c>
}
ffffffffc0201926:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201928:	e390                	sd	a2,0(a5)
ffffffffc020192a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020192c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020192e:	ed1c                	sd	a5,24(a0)
ffffffffc0201930:	0141                	addi	sp,sp,16
ffffffffc0201932:	8082                	ret
            base->property += p->property;
ffffffffc0201934:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201938:	ff078693          	addi	a3,a5,-16
ffffffffc020193c:	9e39                	addw	a2,a2,a4
ffffffffc020193e:	c910                	sw	a2,16(a0)
ffffffffc0201940:	5775                	li	a4,-3
ffffffffc0201942:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201946:	6398                	ld	a4,0(a5)
ffffffffc0201948:	679c                	ld	a5,8(a5)
}
ffffffffc020194a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020194c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020194e:	e398                	sd	a4,0(a5)
ffffffffc0201950:	0141                	addi	sp,sp,16
ffffffffc0201952:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201954:	00005697          	auipc	a3,0x5
ffffffffc0201958:	da468693          	addi	a3,a3,-604 # ffffffffc02066f8 <commands+0xbe8>
ffffffffc020195c:	00005617          	auipc	a2,0x5
ffffffffc0201960:	a3c60613          	addi	a2,a2,-1476 # ffffffffc0206398 <commands+0x888>
ffffffffc0201964:	09400593          	li	a1,148
ffffffffc0201968:	00005517          	auipc	a0,0x5
ffffffffc020196c:	a4850513          	addi	a0,a0,-1464 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201970:	b1ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201974:	00005697          	auipc	a3,0x5
ffffffffc0201978:	d7c68693          	addi	a3,a3,-644 # ffffffffc02066f0 <commands+0xbe0>
ffffffffc020197c:	00005617          	auipc	a2,0x5
ffffffffc0201980:	a1c60613          	addi	a2,a2,-1508 # ffffffffc0206398 <commands+0x888>
ffffffffc0201984:	09000593          	li	a1,144
ffffffffc0201988:	00005517          	auipc	a0,0x5
ffffffffc020198c:	a2850513          	addi	a0,a0,-1496 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201990:	afffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201994 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201994:	c941                	beqz	a0,ffffffffc0201a24 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc0201996:	000a5597          	auipc	a1,0xa5
ffffffffc020199a:	cba58593          	addi	a1,a1,-838 # ffffffffc02a6650 <free_area>
ffffffffc020199e:	0105a803          	lw	a6,16(a1)
ffffffffc02019a2:	872a                	mv	a4,a0
ffffffffc02019a4:	02081793          	slli	a5,a6,0x20
ffffffffc02019a8:	9381                	srli	a5,a5,0x20
ffffffffc02019aa:	00a7ee63          	bltu	a5,a0,ffffffffc02019c6 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02019ae:	87ae                	mv	a5,a1
ffffffffc02019b0:	a801                	j	ffffffffc02019c0 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc02019b2:	ff87a683          	lw	a3,-8(a5)
ffffffffc02019b6:	02069613          	slli	a2,a3,0x20
ffffffffc02019ba:	9201                	srli	a2,a2,0x20
ffffffffc02019bc:	00e67763          	bgeu	a2,a4,ffffffffc02019ca <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02019c0:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02019c2:	feb798e3          	bne	a5,a1,ffffffffc02019b2 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02019c6:	4501                	li	a0,0
}
ffffffffc02019c8:	8082                	ret
    return listelm->prev;
ffffffffc02019ca:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02019ce:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02019d2:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02019d6:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02019da:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02019de:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc02019e2:	02c77863          	bgeu	a4,a2,ffffffffc0201a12 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02019e6:	071a                	slli	a4,a4,0x6
ffffffffc02019e8:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02019ea:	41c686bb          	subw	a3,a3,t3
ffffffffc02019ee:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02019f0:	00870613          	addi	a2,a4,8
ffffffffc02019f4:	4689                	li	a3,2
ffffffffc02019f6:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02019fa:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02019fe:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201a02:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201a06:	e290                	sd	a2,0(a3)
ffffffffc0201a08:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201a0c:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201a0e:	01173c23          	sd	a7,24(a4)
ffffffffc0201a12:	41c8083b          	subw	a6,a6,t3
ffffffffc0201a16:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201a1a:	5775                	li	a4,-3
ffffffffc0201a1c:	17c1                	addi	a5,a5,-16
ffffffffc0201a1e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201a22:	8082                	ret
{
ffffffffc0201a24:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201a26:	00005697          	auipc	a3,0x5
ffffffffc0201a2a:	cca68693          	addi	a3,a3,-822 # ffffffffc02066f0 <commands+0xbe0>
ffffffffc0201a2e:	00005617          	auipc	a2,0x5
ffffffffc0201a32:	96a60613          	addi	a2,a2,-1686 # ffffffffc0206398 <commands+0x888>
ffffffffc0201a36:	06c00593          	li	a1,108
ffffffffc0201a3a:	00005517          	auipc	a0,0x5
ffffffffc0201a3e:	97650513          	addi	a0,a0,-1674 # ffffffffc02063b0 <commands+0x8a0>
{
ffffffffc0201a42:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201a44:	a4bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201a48 <default_init_memmap>:
{
ffffffffc0201a48:	1141                	addi	sp,sp,-16
ffffffffc0201a4a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201a4c:	c5f1                	beqz	a1,ffffffffc0201b18 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201a4e:	00659693          	slli	a3,a1,0x6
ffffffffc0201a52:	96aa                	add	a3,a3,a0
ffffffffc0201a54:	87aa                	mv	a5,a0
ffffffffc0201a56:	00d50f63          	beq	a0,a3,ffffffffc0201a74 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201a5a:	6798                	ld	a4,8(a5)
ffffffffc0201a5c:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201a5e:	cf49                	beqz	a4,ffffffffc0201af8 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201a60:	0007a823          	sw	zero,16(a5)
ffffffffc0201a64:	0007b423          	sd	zero,8(a5)
ffffffffc0201a68:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201a6c:	04078793          	addi	a5,a5,64
ffffffffc0201a70:	fed795e3          	bne	a5,a3,ffffffffc0201a5a <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201a74:	2581                	sext.w	a1,a1
ffffffffc0201a76:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201a78:	4789                	li	a5,2
ffffffffc0201a7a:	00850713          	addi	a4,a0,8
ffffffffc0201a7e:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201a82:	000a5697          	auipc	a3,0xa5
ffffffffc0201a86:	bce68693          	addi	a3,a3,-1074 # ffffffffc02a6650 <free_area>
ffffffffc0201a8a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201a8c:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a8e:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201a92:	9db9                	addw	a1,a1,a4
ffffffffc0201a94:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201a96:	04d78a63          	beq	a5,a3,ffffffffc0201aea <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201a9a:	fe878713          	addi	a4,a5,-24
ffffffffc0201a9e:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201aa2:	4581                	li	a1,0
            if (base < page)
ffffffffc0201aa4:	00e56a63          	bltu	a0,a4,ffffffffc0201ab8 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201aa8:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201aaa:	02d70263          	beq	a4,a3,ffffffffc0201ace <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201aae:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201ab0:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201ab4:	fee57ae3          	bgeu	a0,a4,ffffffffc0201aa8 <default_init_memmap+0x60>
ffffffffc0201ab8:	c199                	beqz	a1,ffffffffc0201abe <default_init_memmap+0x76>
ffffffffc0201aba:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201abe:	6398                	ld	a4,0(a5)
}
ffffffffc0201ac0:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201ac2:	e390                	sd	a2,0(a5)
ffffffffc0201ac4:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201ac6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201ac8:	ed18                	sd	a4,24(a0)
ffffffffc0201aca:	0141                	addi	sp,sp,16
ffffffffc0201acc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201ace:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201ad0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201ad2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201ad4:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201ad6:	00d70663          	beq	a4,a3,ffffffffc0201ae2 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201ada:	8832                	mv	a6,a2
ffffffffc0201adc:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201ade:	87ba                	mv	a5,a4
ffffffffc0201ae0:	bfc1                	j	ffffffffc0201ab0 <default_init_memmap+0x68>
}
ffffffffc0201ae2:	60a2                	ld	ra,8(sp)
ffffffffc0201ae4:	e290                	sd	a2,0(a3)
ffffffffc0201ae6:	0141                	addi	sp,sp,16
ffffffffc0201ae8:	8082                	ret
ffffffffc0201aea:	60a2                	ld	ra,8(sp)
ffffffffc0201aec:	e390                	sd	a2,0(a5)
ffffffffc0201aee:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201af0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201af2:	ed1c                	sd	a5,24(a0)
ffffffffc0201af4:	0141                	addi	sp,sp,16
ffffffffc0201af6:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201af8:	00005697          	auipc	a3,0x5
ffffffffc0201afc:	c2868693          	addi	a3,a3,-984 # ffffffffc0206720 <commands+0xc10>
ffffffffc0201b00:	00005617          	auipc	a2,0x5
ffffffffc0201b04:	89860613          	addi	a2,a2,-1896 # ffffffffc0206398 <commands+0x888>
ffffffffc0201b08:	04b00593          	li	a1,75
ffffffffc0201b0c:	00005517          	auipc	a0,0x5
ffffffffc0201b10:	8a450513          	addi	a0,a0,-1884 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201b14:	97bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201b18:	00005697          	auipc	a3,0x5
ffffffffc0201b1c:	bd868693          	addi	a3,a3,-1064 # ffffffffc02066f0 <commands+0xbe0>
ffffffffc0201b20:	00005617          	auipc	a2,0x5
ffffffffc0201b24:	87860613          	addi	a2,a2,-1928 # ffffffffc0206398 <commands+0x888>
ffffffffc0201b28:	04700593          	li	a1,71
ffffffffc0201b2c:	00005517          	auipc	a0,0x5
ffffffffc0201b30:	88450513          	addi	a0,a0,-1916 # ffffffffc02063b0 <commands+0x8a0>
ffffffffc0201b34:	95bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201b38 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201b38:	c94d                	beqz	a0,ffffffffc0201bea <slob_free+0xb2>
{
ffffffffc0201b3a:	1141                	addi	sp,sp,-16
ffffffffc0201b3c:	e022                	sd	s0,0(sp)
ffffffffc0201b3e:	e406                	sd	ra,8(sp)
ffffffffc0201b40:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201b42:	e9c1                	bnez	a1,ffffffffc0201bd2 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b44:	100027f3          	csrr	a5,sstatus
ffffffffc0201b48:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b4a:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b4c:	ebd9                	bnez	a5,ffffffffc0201be2 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b4e:	000a4617          	auipc	a2,0xa4
ffffffffc0201b52:	6f260613          	addi	a2,a2,1778 # ffffffffc02a6240 <slobfree>
ffffffffc0201b56:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b58:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b5a:	679c                	ld	a5,8(a5)
ffffffffc0201b5c:	02877a63          	bgeu	a4,s0,ffffffffc0201b90 <slob_free+0x58>
ffffffffc0201b60:	00f46463          	bltu	s0,a5,ffffffffc0201b68 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b64:	fef76ae3          	bltu	a4,a5,ffffffffc0201b58 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201b68:	400c                	lw	a1,0(s0)
ffffffffc0201b6a:	00459693          	slli	a3,a1,0x4
ffffffffc0201b6e:	96a2                	add	a3,a3,s0
ffffffffc0201b70:	02d78a63          	beq	a5,a3,ffffffffc0201ba4 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201b74:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201b76:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b78:	00469793          	slli	a5,a3,0x4
ffffffffc0201b7c:	97ba                	add	a5,a5,a4
ffffffffc0201b7e:	02f40e63          	beq	s0,a5,ffffffffc0201bba <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201b82:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201b84:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201b86:	e129                	bnez	a0,ffffffffc0201bc8 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b88:	60a2                	ld	ra,8(sp)
ffffffffc0201b8a:	6402                	ld	s0,0(sp)
ffffffffc0201b8c:	0141                	addi	sp,sp,16
ffffffffc0201b8e:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b90:	fcf764e3          	bltu	a4,a5,ffffffffc0201b58 <slob_free+0x20>
ffffffffc0201b94:	fcf472e3          	bgeu	s0,a5,ffffffffc0201b58 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201b98:	400c                	lw	a1,0(s0)
ffffffffc0201b9a:	00459693          	slli	a3,a1,0x4
ffffffffc0201b9e:	96a2                	add	a3,a3,s0
ffffffffc0201ba0:	fcd79ae3          	bne	a5,a3,ffffffffc0201b74 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201ba4:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201ba6:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201ba8:	9db5                	addw	a1,a1,a3
ffffffffc0201baa:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201bac:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201bae:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201bb0:	00469793          	slli	a5,a3,0x4
ffffffffc0201bb4:	97ba                	add	a5,a5,a4
ffffffffc0201bb6:	fcf416e3          	bne	s0,a5,ffffffffc0201b82 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201bba:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201bbc:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201bbe:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201bc0:	9ebd                	addw	a3,a3,a5
ffffffffc0201bc2:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201bc4:	e70c                	sd	a1,8(a4)
ffffffffc0201bc6:	d169                	beqz	a0,ffffffffc0201b88 <slob_free+0x50>
}
ffffffffc0201bc8:	6402                	ld	s0,0(sp)
ffffffffc0201bca:	60a2                	ld	ra,8(sp)
ffffffffc0201bcc:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201bce:	de1fe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201bd2:	25bd                	addiw	a1,a1,15
ffffffffc0201bd4:	8191                	srli	a1,a1,0x4
ffffffffc0201bd6:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bd8:	100027f3          	csrr	a5,sstatus
ffffffffc0201bdc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201bde:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201be0:	d7bd                	beqz	a5,ffffffffc0201b4e <slob_free+0x16>
        intr_disable();
ffffffffc0201be2:	dd3fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201be6:	4505                	li	a0,1
ffffffffc0201be8:	b79d                	j	ffffffffc0201b4e <slob_free+0x16>
ffffffffc0201bea:	8082                	ret

ffffffffc0201bec <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bec:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201bee:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bf0:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201bf4:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bf6:	352000ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
	if (!page)
ffffffffc0201bfa:	c91d                	beqz	a0,ffffffffc0201c30 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201bfc:	000a9697          	auipc	a3,0xa9
ffffffffc0201c00:	acc6b683          	ld	a3,-1332(a3) # ffffffffc02aa6c8 <pages>
ffffffffc0201c04:	8d15                	sub	a0,a0,a3
ffffffffc0201c06:	8519                	srai	a0,a0,0x6
ffffffffc0201c08:	00006697          	auipc	a3,0x6
ffffffffc0201c0c:	e206b683          	ld	a3,-480(a3) # ffffffffc0207a28 <nbase>
ffffffffc0201c10:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201c12:	00c51793          	slli	a5,a0,0xc
ffffffffc0201c16:	83b1                	srli	a5,a5,0xc
ffffffffc0201c18:	000a9717          	auipc	a4,0xa9
ffffffffc0201c1c:	aa873703          	ld	a4,-1368(a4) # ffffffffc02aa6c0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201c20:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201c22:	00e7fa63          	bgeu	a5,a4,ffffffffc0201c36 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201c26:	000a9697          	auipc	a3,0xa9
ffffffffc0201c2a:	ab26b683          	ld	a3,-1358(a3) # ffffffffc02aa6d8 <va_pa_offset>
ffffffffc0201c2e:	9536                	add	a0,a0,a3
}
ffffffffc0201c30:	60a2                	ld	ra,8(sp)
ffffffffc0201c32:	0141                	addi	sp,sp,16
ffffffffc0201c34:	8082                	ret
ffffffffc0201c36:	86aa                	mv	a3,a0
ffffffffc0201c38:	00005617          	auipc	a2,0x5
ffffffffc0201c3c:	b4860613          	addi	a2,a2,-1208 # ffffffffc0206780 <default_pmm_manager+0x38>
ffffffffc0201c40:	07100593          	li	a1,113
ffffffffc0201c44:	00005517          	auipc	a0,0x5
ffffffffc0201c48:	b6450513          	addi	a0,a0,-1180 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc0201c4c:	843fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201c50 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201c50:	1101                	addi	sp,sp,-32
ffffffffc0201c52:	ec06                	sd	ra,24(sp)
ffffffffc0201c54:	e822                	sd	s0,16(sp)
ffffffffc0201c56:	e426                	sd	s1,8(sp)
ffffffffc0201c58:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c5a:	01050713          	addi	a4,a0,16
ffffffffc0201c5e:	6785                	lui	a5,0x1
ffffffffc0201c60:	0cf77363          	bgeu	a4,a5,ffffffffc0201d26 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201c64:	00f50493          	addi	s1,a0,15
ffffffffc0201c68:	8091                	srli	s1,s1,0x4
ffffffffc0201c6a:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c6c:	10002673          	csrr	a2,sstatus
ffffffffc0201c70:	8a09                	andi	a2,a2,2
ffffffffc0201c72:	e25d                	bnez	a2,ffffffffc0201d18 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201c74:	000a4917          	auipc	s2,0xa4
ffffffffc0201c78:	5cc90913          	addi	s2,s2,1484 # ffffffffc02a6240 <slobfree>
ffffffffc0201c7c:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c80:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201c82:	4398                	lw	a4,0(a5)
ffffffffc0201c84:	08975e63          	bge	a4,s1,ffffffffc0201d20 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201c88:	00f68b63          	beq	a3,a5,ffffffffc0201c9e <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c8c:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c8e:	4018                	lw	a4,0(s0)
ffffffffc0201c90:	02975a63          	bge	a4,s1,ffffffffc0201cc4 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201c94:	00093683          	ld	a3,0(s2)
ffffffffc0201c98:	87a2                	mv	a5,s0
ffffffffc0201c9a:	fef699e3          	bne	a3,a5,ffffffffc0201c8c <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201c9e:	ee31                	bnez	a2,ffffffffc0201cfa <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201ca0:	4501                	li	a0,0
ffffffffc0201ca2:	f4bff0ef          	jal	ra,ffffffffc0201bec <__slob_get_free_pages.constprop.0>
ffffffffc0201ca6:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201ca8:	cd05                	beqz	a0,ffffffffc0201ce0 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201caa:	6585                	lui	a1,0x1
ffffffffc0201cac:	e8dff0ef          	jal	ra,ffffffffc0201b38 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201cb0:	10002673          	csrr	a2,sstatus
ffffffffc0201cb4:	8a09                	andi	a2,a2,2
ffffffffc0201cb6:	ee05                	bnez	a2,ffffffffc0201cee <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201cb8:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201cbc:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201cbe:	4018                	lw	a4,0(s0)
ffffffffc0201cc0:	fc974ae3          	blt	a4,s1,ffffffffc0201c94 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201cc4:	04e48763          	beq	s1,a4,ffffffffc0201d12 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201cc8:	00449693          	slli	a3,s1,0x4
ffffffffc0201ccc:	96a2                	add	a3,a3,s0
ffffffffc0201cce:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201cd0:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201cd2:	9f05                	subw	a4,a4,s1
ffffffffc0201cd4:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201cd6:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201cd8:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201cda:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201cde:	e20d                	bnez	a2,ffffffffc0201d00 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201ce0:	60e2                	ld	ra,24(sp)
ffffffffc0201ce2:	8522                	mv	a0,s0
ffffffffc0201ce4:	6442                	ld	s0,16(sp)
ffffffffc0201ce6:	64a2                	ld	s1,8(sp)
ffffffffc0201ce8:	6902                	ld	s2,0(sp)
ffffffffc0201cea:	6105                	addi	sp,sp,32
ffffffffc0201cec:	8082                	ret
        intr_disable();
ffffffffc0201cee:	cc7fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201cf2:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201cf6:	4605                	li	a2,1
ffffffffc0201cf8:	b7d1                	j	ffffffffc0201cbc <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201cfa:	cb5fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201cfe:	b74d                	j	ffffffffc0201ca0 <slob_alloc.constprop.0+0x50>
ffffffffc0201d00:	caffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201d04:	60e2                	ld	ra,24(sp)
ffffffffc0201d06:	8522                	mv	a0,s0
ffffffffc0201d08:	6442                	ld	s0,16(sp)
ffffffffc0201d0a:	64a2                	ld	s1,8(sp)
ffffffffc0201d0c:	6902                	ld	s2,0(sp)
ffffffffc0201d0e:	6105                	addi	sp,sp,32
ffffffffc0201d10:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201d12:	6418                	ld	a4,8(s0)
ffffffffc0201d14:	e798                	sd	a4,8(a5)
ffffffffc0201d16:	b7d1                	j	ffffffffc0201cda <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201d18:	c9dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201d1c:	4605                	li	a2,1
ffffffffc0201d1e:	bf99                	j	ffffffffc0201c74 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201d20:	843e                	mv	s0,a5
ffffffffc0201d22:	87b6                	mv	a5,a3
ffffffffc0201d24:	b745                	j	ffffffffc0201cc4 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201d26:	00005697          	auipc	a3,0x5
ffffffffc0201d2a:	a9268693          	addi	a3,a3,-1390 # ffffffffc02067b8 <default_pmm_manager+0x70>
ffffffffc0201d2e:	00004617          	auipc	a2,0x4
ffffffffc0201d32:	66a60613          	addi	a2,a2,1642 # ffffffffc0206398 <commands+0x888>
ffffffffc0201d36:	06300593          	li	a1,99
ffffffffc0201d3a:	00005517          	auipc	a0,0x5
ffffffffc0201d3e:	a9e50513          	addi	a0,a0,-1378 # ffffffffc02067d8 <default_pmm_manager+0x90>
ffffffffc0201d42:	f4cfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201d46 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201d46:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201d48:	00005517          	auipc	a0,0x5
ffffffffc0201d4c:	aa850513          	addi	a0,a0,-1368 # ffffffffc02067f0 <default_pmm_manager+0xa8>
{
ffffffffc0201d50:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201d52:	c42fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201d56:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d58:	00005517          	auipc	a0,0x5
ffffffffc0201d5c:	ab050513          	addi	a0,a0,-1360 # ffffffffc0206808 <default_pmm_manager+0xc0>
}
ffffffffc0201d60:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d62:	c32fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201d66 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201d66:	4501                	li	a0,0
ffffffffc0201d68:	8082                	ret

ffffffffc0201d6a <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201d6a:	1101                	addi	sp,sp,-32
ffffffffc0201d6c:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d6e:	6905                	lui	s2,0x1
{
ffffffffc0201d70:	e822                	sd	s0,16(sp)
ffffffffc0201d72:	ec06                	sd	ra,24(sp)
ffffffffc0201d74:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d76:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bb9>
{
ffffffffc0201d7a:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d7c:	04a7f963          	bgeu	a5,a0,ffffffffc0201dce <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201d80:	4561                	li	a0,24
ffffffffc0201d82:	ecfff0ef          	jal	ra,ffffffffc0201c50 <slob_alloc.constprop.0>
ffffffffc0201d86:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201d88:	c929                	beqz	a0,ffffffffc0201dda <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201d8a:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201d8e:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201d90:	00f95763          	bge	s2,a5,ffffffffc0201d9e <kmalloc+0x34>
ffffffffc0201d94:	6705                	lui	a4,0x1
ffffffffc0201d96:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201d98:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201d9a:	fef74ee3          	blt	a4,a5,ffffffffc0201d96 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201d9e:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201da0:	e4dff0ef          	jal	ra,ffffffffc0201bec <__slob_get_free_pages.constprop.0>
ffffffffc0201da4:	e488                	sd	a0,8(s1)
ffffffffc0201da6:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201da8:	c525                	beqz	a0,ffffffffc0201e10 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201daa:	100027f3          	csrr	a5,sstatus
ffffffffc0201dae:	8b89                	andi	a5,a5,2
ffffffffc0201db0:	ef8d                	bnez	a5,ffffffffc0201dea <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201db2:	000a9797          	auipc	a5,0xa9
ffffffffc0201db6:	8f678793          	addi	a5,a5,-1802 # ffffffffc02aa6a8 <bigblocks>
ffffffffc0201dba:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201dbc:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201dbe:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201dc0:	60e2                	ld	ra,24(sp)
ffffffffc0201dc2:	8522                	mv	a0,s0
ffffffffc0201dc4:	6442                	ld	s0,16(sp)
ffffffffc0201dc6:	64a2                	ld	s1,8(sp)
ffffffffc0201dc8:	6902                	ld	s2,0(sp)
ffffffffc0201dca:	6105                	addi	sp,sp,32
ffffffffc0201dcc:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201dce:	0541                	addi	a0,a0,16
ffffffffc0201dd0:	e81ff0ef          	jal	ra,ffffffffc0201c50 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201dd4:	01050413          	addi	s0,a0,16
ffffffffc0201dd8:	f565                	bnez	a0,ffffffffc0201dc0 <kmalloc+0x56>
ffffffffc0201dda:	4401                	li	s0,0
}
ffffffffc0201ddc:	60e2                	ld	ra,24(sp)
ffffffffc0201dde:	8522                	mv	a0,s0
ffffffffc0201de0:	6442                	ld	s0,16(sp)
ffffffffc0201de2:	64a2                	ld	s1,8(sp)
ffffffffc0201de4:	6902                	ld	s2,0(sp)
ffffffffc0201de6:	6105                	addi	sp,sp,32
ffffffffc0201de8:	8082                	ret
        intr_disable();
ffffffffc0201dea:	bcbfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201dee:	000a9797          	auipc	a5,0xa9
ffffffffc0201df2:	8ba78793          	addi	a5,a5,-1862 # ffffffffc02aa6a8 <bigblocks>
ffffffffc0201df6:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201df8:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201dfa:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201dfc:	bb3fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201e00:	6480                	ld	s0,8(s1)
}
ffffffffc0201e02:	60e2                	ld	ra,24(sp)
ffffffffc0201e04:	64a2                	ld	s1,8(sp)
ffffffffc0201e06:	8522                	mv	a0,s0
ffffffffc0201e08:	6442                	ld	s0,16(sp)
ffffffffc0201e0a:	6902                	ld	s2,0(sp)
ffffffffc0201e0c:	6105                	addi	sp,sp,32
ffffffffc0201e0e:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e10:	45e1                	li	a1,24
ffffffffc0201e12:	8526                	mv	a0,s1
ffffffffc0201e14:	d25ff0ef          	jal	ra,ffffffffc0201b38 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201e18:	b765                	j	ffffffffc0201dc0 <kmalloc+0x56>

ffffffffc0201e1a <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201e1a:	c169                	beqz	a0,ffffffffc0201edc <kfree+0xc2>
{
ffffffffc0201e1c:	1101                	addi	sp,sp,-32
ffffffffc0201e1e:	e822                	sd	s0,16(sp)
ffffffffc0201e20:	ec06                	sd	ra,24(sp)
ffffffffc0201e22:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201e24:	03451793          	slli	a5,a0,0x34
ffffffffc0201e28:	842a                	mv	s0,a0
ffffffffc0201e2a:	e3d9                	bnez	a5,ffffffffc0201eb0 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e2c:	100027f3          	csrr	a5,sstatus
ffffffffc0201e30:	8b89                	andi	a5,a5,2
ffffffffc0201e32:	e7d9                	bnez	a5,ffffffffc0201ec0 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e34:	000a9797          	auipc	a5,0xa9
ffffffffc0201e38:	8747b783          	ld	a5,-1932(a5) # ffffffffc02aa6a8 <bigblocks>
    return 0;
ffffffffc0201e3c:	4601                	li	a2,0
ffffffffc0201e3e:	cbad                	beqz	a5,ffffffffc0201eb0 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201e40:	000a9697          	auipc	a3,0xa9
ffffffffc0201e44:	86868693          	addi	a3,a3,-1944 # ffffffffc02aa6a8 <bigblocks>
ffffffffc0201e48:	a021                	j	ffffffffc0201e50 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e4a:	01048693          	addi	a3,s1,16
ffffffffc0201e4e:	c3a5                	beqz	a5,ffffffffc0201eae <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201e50:	6798                	ld	a4,8(a5)
ffffffffc0201e52:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201e54:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201e56:	fe871ae3          	bne	a4,s0,ffffffffc0201e4a <kfree+0x30>
				*last = bb->next;
ffffffffc0201e5a:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201e5c:	ee2d                	bnez	a2,ffffffffc0201ed6 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201e5e:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201e62:	4098                	lw	a4,0(s1)
ffffffffc0201e64:	08f46963          	bltu	s0,a5,ffffffffc0201ef6 <kfree+0xdc>
ffffffffc0201e68:	000a9697          	auipc	a3,0xa9
ffffffffc0201e6c:	8706b683          	ld	a3,-1936(a3) # ffffffffc02aa6d8 <va_pa_offset>
ffffffffc0201e70:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201e72:	8031                	srli	s0,s0,0xc
ffffffffc0201e74:	000a9797          	auipc	a5,0xa9
ffffffffc0201e78:	84c7b783          	ld	a5,-1972(a5) # ffffffffc02aa6c0 <npage>
ffffffffc0201e7c:	06f47163          	bgeu	s0,a5,ffffffffc0201ede <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e80:	00006517          	auipc	a0,0x6
ffffffffc0201e84:	ba853503          	ld	a0,-1112(a0) # ffffffffc0207a28 <nbase>
ffffffffc0201e88:	8c09                	sub	s0,s0,a0
ffffffffc0201e8a:	041a                	slli	s0,s0,0x6
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201e8c:	000a9517          	auipc	a0,0xa9
ffffffffc0201e90:	83c53503          	ld	a0,-1988(a0) # ffffffffc02aa6c8 <pages>
ffffffffc0201e94:	4585                	li	a1,1
ffffffffc0201e96:	9522                	add	a0,a0,s0
ffffffffc0201e98:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201e9c:	0ea000ef          	jal	ra,ffffffffc0201f86 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201ea0:	6442                	ld	s0,16(sp)
ffffffffc0201ea2:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ea4:	8526                	mv	a0,s1
}
ffffffffc0201ea6:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ea8:	45e1                	li	a1,24
}
ffffffffc0201eaa:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201eac:	b171                	j	ffffffffc0201b38 <slob_free>
ffffffffc0201eae:	e20d                	bnez	a2,ffffffffc0201ed0 <kfree+0xb6>
ffffffffc0201eb0:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201eb4:	6442                	ld	s0,16(sp)
ffffffffc0201eb6:	60e2                	ld	ra,24(sp)
ffffffffc0201eb8:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201eba:	4581                	li	a1,0
}
ffffffffc0201ebc:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ebe:	b9ad                	j	ffffffffc0201b38 <slob_free>
        intr_disable();
ffffffffc0201ec0:	af5fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201ec4:	000a8797          	auipc	a5,0xa8
ffffffffc0201ec8:	7e47b783          	ld	a5,2020(a5) # ffffffffc02aa6a8 <bigblocks>
        return 1;
ffffffffc0201ecc:	4605                	li	a2,1
ffffffffc0201ece:	fbad                	bnez	a5,ffffffffc0201e40 <kfree+0x26>
        intr_enable();
ffffffffc0201ed0:	adffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201ed4:	bff1                	j	ffffffffc0201eb0 <kfree+0x96>
ffffffffc0201ed6:	ad9fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201eda:	b751                	j	ffffffffc0201e5e <kfree+0x44>
ffffffffc0201edc:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201ede:	00005617          	auipc	a2,0x5
ffffffffc0201ee2:	97260613          	addi	a2,a2,-1678 # ffffffffc0206850 <default_pmm_manager+0x108>
ffffffffc0201ee6:	06900593          	li	a1,105
ffffffffc0201eea:	00005517          	auipc	a0,0x5
ffffffffc0201eee:	8be50513          	addi	a0,a0,-1858 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc0201ef2:	d9cfe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201ef6:	86a2                	mv	a3,s0
ffffffffc0201ef8:	00005617          	auipc	a2,0x5
ffffffffc0201efc:	93060613          	addi	a2,a2,-1744 # ffffffffc0206828 <default_pmm_manager+0xe0>
ffffffffc0201f00:	07700593          	li	a1,119
ffffffffc0201f04:	00005517          	auipc	a0,0x5
ffffffffc0201f08:	8a450513          	addi	a0,a0,-1884 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc0201f0c:	d82fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f10 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201f10:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201f12:	00005617          	auipc	a2,0x5
ffffffffc0201f16:	93e60613          	addi	a2,a2,-1730 # ffffffffc0206850 <default_pmm_manager+0x108>
ffffffffc0201f1a:	06900593          	li	a1,105
ffffffffc0201f1e:	00005517          	auipc	a0,0x5
ffffffffc0201f22:	88a50513          	addi	a0,a0,-1910 # ffffffffc02067a8 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201f26:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201f28:	d66fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f2c <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201f2c:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201f2e:	00005617          	auipc	a2,0x5
ffffffffc0201f32:	94260613          	addi	a2,a2,-1726 # ffffffffc0206870 <default_pmm_manager+0x128>
ffffffffc0201f36:	07f00593          	li	a1,127
ffffffffc0201f3a:	00005517          	auipc	a0,0x5
ffffffffc0201f3e:	86e50513          	addi	a0,a0,-1938 # ffffffffc02067a8 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201f42:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201f44:	d4afe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f48 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f48:	100027f3          	csrr	a5,sstatus
ffffffffc0201f4c:	8b89                	andi	a5,a5,2
ffffffffc0201f4e:	e799                	bnez	a5,ffffffffc0201f5c <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f50:	000a8797          	auipc	a5,0xa8
ffffffffc0201f54:	7807b783          	ld	a5,1920(a5) # ffffffffc02aa6d0 <pmm_manager>
ffffffffc0201f58:	6f9c                	ld	a5,24(a5)
ffffffffc0201f5a:	8782                	jr	a5
{
ffffffffc0201f5c:	1141                	addi	sp,sp,-16
ffffffffc0201f5e:	e406                	sd	ra,8(sp)
ffffffffc0201f60:	e022                	sd	s0,0(sp)
ffffffffc0201f62:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201f64:	a51fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f68:	000a8797          	auipc	a5,0xa8
ffffffffc0201f6c:	7687b783          	ld	a5,1896(a5) # ffffffffc02aa6d0 <pmm_manager>
ffffffffc0201f70:	6f9c                	ld	a5,24(a5)
ffffffffc0201f72:	8522                	mv	a0,s0
ffffffffc0201f74:	9782                	jalr	a5
ffffffffc0201f76:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f78:	a37fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201f7c:	60a2                	ld	ra,8(sp)
ffffffffc0201f7e:	8522                	mv	a0,s0
ffffffffc0201f80:	6402                	ld	s0,0(sp)
ffffffffc0201f82:	0141                	addi	sp,sp,16
ffffffffc0201f84:	8082                	ret

ffffffffc0201f86 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f86:	100027f3          	csrr	a5,sstatus
ffffffffc0201f8a:	8b89                	andi	a5,a5,2
ffffffffc0201f8c:	e799                	bnez	a5,ffffffffc0201f9a <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201f8e:	000a8797          	auipc	a5,0xa8
ffffffffc0201f92:	7427b783          	ld	a5,1858(a5) # ffffffffc02aa6d0 <pmm_manager>
ffffffffc0201f96:	739c                	ld	a5,32(a5)
ffffffffc0201f98:	8782                	jr	a5
{
ffffffffc0201f9a:	1101                	addi	sp,sp,-32
ffffffffc0201f9c:	ec06                	sd	ra,24(sp)
ffffffffc0201f9e:	e822                	sd	s0,16(sp)
ffffffffc0201fa0:	e426                	sd	s1,8(sp)
ffffffffc0201fa2:	842a                	mv	s0,a0
ffffffffc0201fa4:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201fa6:	a0ffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201faa:	000a8797          	auipc	a5,0xa8
ffffffffc0201fae:	7267b783          	ld	a5,1830(a5) # ffffffffc02aa6d0 <pmm_manager>
ffffffffc0201fb2:	739c                	ld	a5,32(a5)
ffffffffc0201fb4:	85a6                	mv	a1,s1
ffffffffc0201fb6:	8522                	mv	a0,s0
ffffffffc0201fb8:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201fba:	6442                	ld	s0,16(sp)
ffffffffc0201fbc:	60e2                	ld	ra,24(sp)
ffffffffc0201fbe:	64a2                	ld	s1,8(sp)
ffffffffc0201fc0:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201fc2:	9edfe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0201fc6 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201fc6:	100027f3          	csrr	a5,sstatus
ffffffffc0201fca:	8b89                	andi	a5,a5,2
ffffffffc0201fcc:	e799                	bnez	a5,ffffffffc0201fda <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201fce:	000a8797          	auipc	a5,0xa8
ffffffffc0201fd2:	7027b783          	ld	a5,1794(a5) # ffffffffc02aa6d0 <pmm_manager>
ffffffffc0201fd6:	779c                	ld	a5,40(a5)
ffffffffc0201fd8:	8782                	jr	a5
{
ffffffffc0201fda:	1141                	addi	sp,sp,-16
ffffffffc0201fdc:	e406                	sd	ra,8(sp)
ffffffffc0201fde:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201fe0:	9d5fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201fe4:	000a8797          	auipc	a5,0xa8
ffffffffc0201fe8:	6ec7b783          	ld	a5,1772(a5) # ffffffffc02aa6d0 <pmm_manager>
ffffffffc0201fec:	779c                	ld	a5,40(a5)
ffffffffc0201fee:	9782                	jalr	a5
ffffffffc0201ff0:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201ff2:	9bdfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201ff6:	60a2                	ld	ra,8(sp)
ffffffffc0201ff8:	8522                	mv	a0,s0
ffffffffc0201ffa:	6402                	ld	s0,0(sp)
ffffffffc0201ffc:	0141                	addi	sp,sp,16
ffffffffc0201ffe:	8082                	ret

ffffffffc0202000 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202000:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0202004:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0202008:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc020200a:	078e                	slli	a5,a5,0x3
{
ffffffffc020200c:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc020200e:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0202012:	6094                	ld	a3,0(s1)
{
ffffffffc0202014:	f04a                	sd	s2,32(sp)
ffffffffc0202016:	ec4e                	sd	s3,24(sp)
ffffffffc0202018:	e852                	sd	s4,16(sp)
ffffffffc020201a:	fc06                	sd	ra,56(sp)
ffffffffc020201c:	f822                	sd	s0,48(sp)
ffffffffc020201e:	e456                	sd	s5,8(sp)
ffffffffc0202020:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0202022:	0016f793          	andi	a5,a3,1
{
ffffffffc0202026:	892e                	mv	s2,a1
ffffffffc0202028:	8a32                	mv	s4,a2
ffffffffc020202a:	000a8997          	auipc	s3,0xa8
ffffffffc020202e:	69698993          	addi	s3,s3,1686 # ffffffffc02aa6c0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0202032:	efbd                	bnez	a5,ffffffffc02020b0 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202034:	14060c63          	beqz	a2,ffffffffc020218c <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202038:	100027f3          	csrr	a5,sstatus
ffffffffc020203c:	8b89                	andi	a5,a5,2
ffffffffc020203e:	14079963          	bnez	a5,ffffffffc0202190 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202042:	000a8797          	auipc	a5,0xa8
ffffffffc0202046:	68e7b783          	ld	a5,1678(a5) # ffffffffc02aa6d0 <pmm_manager>
ffffffffc020204a:	6f9c                	ld	a5,24(a5)
ffffffffc020204c:	4505                	li	a0,1
ffffffffc020204e:	9782                	jalr	a5
ffffffffc0202050:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202052:	12040d63          	beqz	s0,ffffffffc020218c <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0202056:	000a8b17          	auipc	s6,0xa8
ffffffffc020205a:	672b0b13          	addi	s6,s6,1650 # ffffffffc02aa6c8 <pages>
ffffffffc020205e:	000b3503          	ld	a0,0(s6)
ffffffffc0202062:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202066:	000a8997          	auipc	s3,0xa8
ffffffffc020206a:	65a98993          	addi	s3,s3,1626 # ffffffffc02aa6c0 <npage>
ffffffffc020206e:	40a40533          	sub	a0,s0,a0
ffffffffc0202072:	8519                	srai	a0,a0,0x6
ffffffffc0202074:	9556                	add	a0,a0,s5
ffffffffc0202076:	0009b703          	ld	a4,0(s3)
ffffffffc020207a:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc020207e:	4685                	li	a3,1
ffffffffc0202080:	c014                	sw	a3,0(s0)
ffffffffc0202082:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202084:	0532                	slli	a0,a0,0xc
ffffffffc0202086:	16e7f763          	bgeu	a5,a4,ffffffffc02021f4 <get_pte+0x1f4>
ffffffffc020208a:	000a8797          	auipc	a5,0xa8
ffffffffc020208e:	64e7b783          	ld	a5,1614(a5) # ffffffffc02aa6d8 <va_pa_offset>
ffffffffc0202092:	6605                	lui	a2,0x1
ffffffffc0202094:	4581                	li	a1,0
ffffffffc0202096:	953e                	add	a0,a0,a5
ffffffffc0202098:	7e6030ef          	jal	ra,ffffffffc020587e <memset>
    return page - pages + nbase;
ffffffffc020209c:	000b3683          	ld	a3,0(s6)
ffffffffc02020a0:	40d406b3          	sub	a3,s0,a3
ffffffffc02020a4:	8699                	srai	a3,a3,0x6
ffffffffc02020a6:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020a8:	06aa                	slli	a3,a3,0xa
ffffffffc02020aa:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02020ae:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02020b0:	77fd                	lui	a5,0xfffff
ffffffffc02020b2:	068a                	slli	a3,a3,0x2
ffffffffc02020b4:	0009b703          	ld	a4,0(s3)
ffffffffc02020b8:	8efd                	and	a3,a3,a5
ffffffffc02020ba:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020be:	10e7ff63          	bgeu	a5,a4,ffffffffc02021dc <get_pte+0x1dc>
ffffffffc02020c2:	000a8a97          	auipc	s5,0xa8
ffffffffc02020c6:	616a8a93          	addi	s5,s5,1558 # ffffffffc02aa6d8 <va_pa_offset>
ffffffffc02020ca:	000ab403          	ld	s0,0(s5)
ffffffffc02020ce:	01595793          	srli	a5,s2,0x15
ffffffffc02020d2:	1ff7f793          	andi	a5,a5,511
ffffffffc02020d6:	96a2                	add	a3,a3,s0
ffffffffc02020d8:	00379413          	slli	s0,a5,0x3
ffffffffc02020dc:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc02020de:	6014                	ld	a3,0(s0)
ffffffffc02020e0:	0016f793          	andi	a5,a3,1
ffffffffc02020e4:	ebad                	bnez	a5,ffffffffc0202156 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020e6:	0a0a0363          	beqz	s4,ffffffffc020218c <get_pte+0x18c>
ffffffffc02020ea:	100027f3          	csrr	a5,sstatus
ffffffffc02020ee:	8b89                	andi	a5,a5,2
ffffffffc02020f0:	efcd                	bnez	a5,ffffffffc02021aa <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020f2:	000a8797          	auipc	a5,0xa8
ffffffffc02020f6:	5de7b783          	ld	a5,1502(a5) # ffffffffc02aa6d0 <pmm_manager>
ffffffffc02020fa:	6f9c                	ld	a5,24(a5)
ffffffffc02020fc:	4505                	li	a0,1
ffffffffc02020fe:	9782                	jalr	a5
ffffffffc0202100:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202102:	c4c9                	beqz	s1,ffffffffc020218c <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0202104:	000a8b17          	auipc	s6,0xa8
ffffffffc0202108:	5c4b0b13          	addi	s6,s6,1476 # ffffffffc02aa6c8 <pages>
ffffffffc020210c:	000b3503          	ld	a0,0(s6)
ffffffffc0202110:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202114:	0009b703          	ld	a4,0(s3)
ffffffffc0202118:	40a48533          	sub	a0,s1,a0
ffffffffc020211c:	8519                	srai	a0,a0,0x6
ffffffffc020211e:	9552                	add	a0,a0,s4
ffffffffc0202120:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202124:	4685                	li	a3,1
ffffffffc0202126:	c094                	sw	a3,0(s1)
ffffffffc0202128:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020212a:	0532                	slli	a0,a0,0xc
ffffffffc020212c:	0ee7f163          	bgeu	a5,a4,ffffffffc020220e <get_pte+0x20e>
ffffffffc0202130:	000ab783          	ld	a5,0(s5)
ffffffffc0202134:	6605                	lui	a2,0x1
ffffffffc0202136:	4581                	li	a1,0
ffffffffc0202138:	953e                	add	a0,a0,a5
ffffffffc020213a:	744030ef          	jal	ra,ffffffffc020587e <memset>
    return page - pages + nbase;
ffffffffc020213e:	000b3683          	ld	a3,0(s6)
ffffffffc0202142:	40d486b3          	sub	a3,s1,a3
ffffffffc0202146:	8699                	srai	a3,a3,0x6
ffffffffc0202148:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020214a:	06aa                	slli	a3,a3,0xa
ffffffffc020214c:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202150:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202152:	0009b703          	ld	a4,0(s3)
ffffffffc0202156:	068a                	slli	a3,a3,0x2
ffffffffc0202158:	757d                	lui	a0,0xfffff
ffffffffc020215a:	8ee9                	and	a3,a3,a0
ffffffffc020215c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202160:	06e7f263          	bgeu	a5,a4,ffffffffc02021c4 <get_pte+0x1c4>
ffffffffc0202164:	000ab503          	ld	a0,0(s5)
ffffffffc0202168:	00c95913          	srli	s2,s2,0xc
ffffffffc020216c:	1ff97913          	andi	s2,s2,511
ffffffffc0202170:	96aa                	add	a3,a3,a0
ffffffffc0202172:	00391513          	slli	a0,s2,0x3
ffffffffc0202176:	9536                	add	a0,a0,a3
}
ffffffffc0202178:	70e2                	ld	ra,56(sp)
ffffffffc020217a:	7442                	ld	s0,48(sp)
ffffffffc020217c:	74a2                	ld	s1,40(sp)
ffffffffc020217e:	7902                	ld	s2,32(sp)
ffffffffc0202180:	69e2                	ld	s3,24(sp)
ffffffffc0202182:	6a42                	ld	s4,16(sp)
ffffffffc0202184:	6aa2                	ld	s5,8(sp)
ffffffffc0202186:	6b02                	ld	s6,0(sp)
ffffffffc0202188:	6121                	addi	sp,sp,64
ffffffffc020218a:	8082                	ret
            return NULL;
ffffffffc020218c:	4501                	li	a0,0
ffffffffc020218e:	b7ed                	j	ffffffffc0202178 <get_pte+0x178>
        intr_disable();
ffffffffc0202190:	825fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202194:	000a8797          	auipc	a5,0xa8
ffffffffc0202198:	53c7b783          	ld	a5,1340(a5) # ffffffffc02aa6d0 <pmm_manager>
ffffffffc020219c:	6f9c                	ld	a5,24(a5)
ffffffffc020219e:	4505                	li	a0,1
ffffffffc02021a0:	9782                	jalr	a5
ffffffffc02021a2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02021a4:	80bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02021a8:	b56d                	j	ffffffffc0202052 <get_pte+0x52>
        intr_disable();
ffffffffc02021aa:	80bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02021ae:	000a8797          	auipc	a5,0xa8
ffffffffc02021b2:	5227b783          	ld	a5,1314(a5) # ffffffffc02aa6d0 <pmm_manager>
ffffffffc02021b6:	6f9c                	ld	a5,24(a5)
ffffffffc02021b8:	4505                	li	a0,1
ffffffffc02021ba:	9782                	jalr	a5
ffffffffc02021bc:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc02021be:	ff0fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02021c2:	b781                	j	ffffffffc0202102 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02021c4:	00004617          	auipc	a2,0x4
ffffffffc02021c8:	5bc60613          	addi	a2,a2,1468 # ffffffffc0206780 <default_pmm_manager+0x38>
ffffffffc02021cc:	0fb00593          	li	a1,251
ffffffffc02021d0:	00004517          	auipc	a0,0x4
ffffffffc02021d4:	6c850513          	addi	a0,a0,1736 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02021d8:	ab6fe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02021dc:	00004617          	auipc	a2,0x4
ffffffffc02021e0:	5a460613          	addi	a2,a2,1444 # ffffffffc0206780 <default_pmm_manager+0x38>
ffffffffc02021e4:	0ee00593          	li	a1,238
ffffffffc02021e8:	00004517          	auipc	a0,0x4
ffffffffc02021ec:	6b050513          	addi	a0,a0,1712 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02021f0:	a9efe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021f4:	86aa                	mv	a3,a0
ffffffffc02021f6:	00004617          	auipc	a2,0x4
ffffffffc02021fa:	58a60613          	addi	a2,a2,1418 # ffffffffc0206780 <default_pmm_manager+0x38>
ffffffffc02021fe:	0ea00593          	li	a1,234
ffffffffc0202202:	00004517          	auipc	a0,0x4
ffffffffc0202206:	69650513          	addi	a0,a0,1686 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc020220a:	a84fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020220e:	86aa                	mv	a3,a0
ffffffffc0202210:	00004617          	auipc	a2,0x4
ffffffffc0202214:	57060613          	addi	a2,a2,1392 # ffffffffc0206780 <default_pmm_manager+0x38>
ffffffffc0202218:	0f800593          	li	a1,248
ffffffffc020221c:	00004517          	auipc	a0,0x4
ffffffffc0202220:	67c50513          	addi	a0,a0,1660 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0202224:	a6afe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202228 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202228:	1141                	addi	sp,sp,-16
ffffffffc020222a:	e022                	sd	s0,0(sp)
ffffffffc020222c:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020222e:	4601                	li	a2,0
{
ffffffffc0202230:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202232:	dcfff0ef          	jal	ra,ffffffffc0202000 <get_pte>
    if (ptep_store != NULL)
ffffffffc0202236:	c011                	beqz	s0,ffffffffc020223a <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202238:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020223a:	c511                	beqz	a0,ffffffffc0202246 <get_page+0x1e>
ffffffffc020223c:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc020223e:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202240:	0017f713          	andi	a4,a5,1
ffffffffc0202244:	e709                	bnez	a4,ffffffffc020224e <get_page+0x26>
}
ffffffffc0202246:	60a2                	ld	ra,8(sp)
ffffffffc0202248:	6402                	ld	s0,0(sp)
ffffffffc020224a:	0141                	addi	sp,sp,16
ffffffffc020224c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020224e:	078a                	slli	a5,a5,0x2
ffffffffc0202250:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202252:	000a8717          	auipc	a4,0xa8
ffffffffc0202256:	46e73703          	ld	a4,1134(a4) # ffffffffc02aa6c0 <npage>
ffffffffc020225a:	00e7ff63          	bgeu	a5,a4,ffffffffc0202278 <get_page+0x50>
ffffffffc020225e:	60a2                	ld	ra,8(sp)
ffffffffc0202260:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0202262:	fff80537          	lui	a0,0xfff80
ffffffffc0202266:	97aa                	add	a5,a5,a0
ffffffffc0202268:	079a                	slli	a5,a5,0x6
ffffffffc020226a:	000a8517          	auipc	a0,0xa8
ffffffffc020226e:	45e53503          	ld	a0,1118(a0) # ffffffffc02aa6c8 <pages>
ffffffffc0202272:	953e                	add	a0,a0,a5
ffffffffc0202274:	0141                	addi	sp,sp,16
ffffffffc0202276:	8082                	ret
ffffffffc0202278:	c99ff0ef          	jal	ra,ffffffffc0201f10 <pa2page.part.0>

ffffffffc020227c <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc020227c:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020227e:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202282:	f486                	sd	ra,104(sp)
ffffffffc0202284:	f0a2                	sd	s0,96(sp)
ffffffffc0202286:	eca6                	sd	s1,88(sp)
ffffffffc0202288:	e8ca                	sd	s2,80(sp)
ffffffffc020228a:	e4ce                	sd	s3,72(sp)
ffffffffc020228c:	e0d2                	sd	s4,64(sp)
ffffffffc020228e:	fc56                	sd	s5,56(sp)
ffffffffc0202290:	f85a                	sd	s6,48(sp)
ffffffffc0202292:	f45e                	sd	s7,40(sp)
ffffffffc0202294:	f062                	sd	s8,32(sp)
ffffffffc0202296:	ec66                	sd	s9,24(sp)
ffffffffc0202298:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020229a:	17d2                	slli	a5,a5,0x34
ffffffffc020229c:	e3ed                	bnez	a5,ffffffffc020237e <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc020229e:	002007b7          	lui	a5,0x200
ffffffffc02022a2:	842e                	mv	s0,a1
ffffffffc02022a4:	0ef5ed63          	bltu	a1,a5,ffffffffc020239e <unmap_range+0x122>
ffffffffc02022a8:	8932                	mv	s2,a2
ffffffffc02022aa:	0ec5fa63          	bgeu	a1,a2,ffffffffc020239e <unmap_range+0x122>
ffffffffc02022ae:	4785                	li	a5,1
ffffffffc02022b0:	07fe                	slli	a5,a5,0x1f
ffffffffc02022b2:	0ec7e663          	bltu	a5,a2,ffffffffc020239e <unmap_range+0x122>
ffffffffc02022b6:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02022b8:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02022ba:	000a8c97          	auipc	s9,0xa8
ffffffffc02022be:	406c8c93          	addi	s9,s9,1030 # ffffffffc02aa6c0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02022c2:	000a8c17          	auipc	s8,0xa8
ffffffffc02022c6:	406c0c13          	addi	s8,s8,1030 # ffffffffc02aa6c8 <pages>
ffffffffc02022ca:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02022ce:	000a8d17          	auipc	s10,0xa8
ffffffffc02022d2:	402d0d13          	addi	s10,s10,1026 # ffffffffc02aa6d0 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02022d6:	00200b37          	lui	s6,0x200
ffffffffc02022da:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02022de:	4601                	li	a2,0
ffffffffc02022e0:	85a2                	mv	a1,s0
ffffffffc02022e2:	854e                	mv	a0,s3
ffffffffc02022e4:	d1dff0ef          	jal	ra,ffffffffc0202000 <get_pte>
ffffffffc02022e8:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02022ea:	cd29                	beqz	a0,ffffffffc0202344 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc02022ec:	611c                	ld	a5,0(a0)
ffffffffc02022ee:	e395                	bnez	a5,ffffffffc0202312 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc02022f0:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02022f2:	ff2466e3          	bltu	s0,s2,ffffffffc02022de <unmap_range+0x62>
}
ffffffffc02022f6:	70a6                	ld	ra,104(sp)
ffffffffc02022f8:	7406                	ld	s0,96(sp)
ffffffffc02022fa:	64e6                	ld	s1,88(sp)
ffffffffc02022fc:	6946                	ld	s2,80(sp)
ffffffffc02022fe:	69a6                	ld	s3,72(sp)
ffffffffc0202300:	6a06                	ld	s4,64(sp)
ffffffffc0202302:	7ae2                	ld	s5,56(sp)
ffffffffc0202304:	7b42                	ld	s6,48(sp)
ffffffffc0202306:	7ba2                	ld	s7,40(sp)
ffffffffc0202308:	7c02                	ld	s8,32(sp)
ffffffffc020230a:	6ce2                	ld	s9,24(sp)
ffffffffc020230c:	6d42                	ld	s10,16(sp)
ffffffffc020230e:	6165                	addi	sp,sp,112
ffffffffc0202310:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202312:	0017f713          	andi	a4,a5,1
ffffffffc0202316:	df69                	beqz	a4,ffffffffc02022f0 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc0202318:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020231c:	078a                	slli	a5,a5,0x2
ffffffffc020231e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202320:	08e7ff63          	bgeu	a5,a4,ffffffffc02023be <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202324:	000c3503          	ld	a0,0(s8)
ffffffffc0202328:	97de                	add	a5,a5,s7
ffffffffc020232a:	079a                	slli	a5,a5,0x6
ffffffffc020232c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020232e:	411c                	lw	a5,0(a0)
ffffffffc0202330:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202334:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202336:	cf11                	beqz	a4,ffffffffc0202352 <unmap_range+0xd6>
        *ptep = 0;
ffffffffc0202338:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020233c:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202340:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202342:	bf45                	j	ffffffffc02022f2 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202344:	945a                	add	s0,s0,s6
ffffffffc0202346:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020234a:	d455                	beqz	s0,ffffffffc02022f6 <unmap_range+0x7a>
ffffffffc020234c:	f92469e3          	bltu	s0,s2,ffffffffc02022de <unmap_range+0x62>
ffffffffc0202350:	b75d                	j	ffffffffc02022f6 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202352:	100027f3          	csrr	a5,sstatus
ffffffffc0202356:	8b89                	andi	a5,a5,2
ffffffffc0202358:	e799                	bnez	a5,ffffffffc0202366 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020235a:	000d3783          	ld	a5,0(s10)
ffffffffc020235e:	4585                	li	a1,1
ffffffffc0202360:	739c                	ld	a5,32(a5)
ffffffffc0202362:	9782                	jalr	a5
    if (flag)
ffffffffc0202364:	bfd1                	j	ffffffffc0202338 <unmap_range+0xbc>
ffffffffc0202366:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202368:	e4cfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020236c:	000d3783          	ld	a5,0(s10)
ffffffffc0202370:	6522                	ld	a0,8(sp)
ffffffffc0202372:	4585                	li	a1,1
ffffffffc0202374:	739c                	ld	a5,32(a5)
ffffffffc0202376:	9782                	jalr	a5
        intr_enable();
ffffffffc0202378:	e36fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020237c:	bf75                	j	ffffffffc0202338 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020237e:	00004697          	auipc	a3,0x4
ffffffffc0202382:	52a68693          	addi	a3,a3,1322 # ffffffffc02068a8 <default_pmm_manager+0x160>
ffffffffc0202386:	00004617          	auipc	a2,0x4
ffffffffc020238a:	01260613          	addi	a2,a2,18 # ffffffffc0206398 <commands+0x888>
ffffffffc020238e:	12100593          	li	a1,289
ffffffffc0202392:	00004517          	auipc	a0,0x4
ffffffffc0202396:	50650513          	addi	a0,a0,1286 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc020239a:	8f4fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020239e:	00004697          	auipc	a3,0x4
ffffffffc02023a2:	53a68693          	addi	a3,a3,1338 # ffffffffc02068d8 <default_pmm_manager+0x190>
ffffffffc02023a6:	00004617          	auipc	a2,0x4
ffffffffc02023aa:	ff260613          	addi	a2,a2,-14 # ffffffffc0206398 <commands+0x888>
ffffffffc02023ae:	12200593          	li	a1,290
ffffffffc02023b2:	00004517          	auipc	a0,0x4
ffffffffc02023b6:	4e650513          	addi	a0,a0,1254 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02023ba:	8d4fe0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02023be:	b53ff0ef          	jal	ra,ffffffffc0201f10 <pa2page.part.0>

ffffffffc02023c2 <exit_range>:
{
ffffffffc02023c2:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023c4:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02023c8:	fc86                	sd	ra,120(sp)
ffffffffc02023ca:	f8a2                	sd	s0,112(sp)
ffffffffc02023cc:	f4a6                	sd	s1,104(sp)
ffffffffc02023ce:	f0ca                	sd	s2,96(sp)
ffffffffc02023d0:	ecce                	sd	s3,88(sp)
ffffffffc02023d2:	e8d2                	sd	s4,80(sp)
ffffffffc02023d4:	e4d6                	sd	s5,72(sp)
ffffffffc02023d6:	e0da                	sd	s6,64(sp)
ffffffffc02023d8:	fc5e                	sd	s7,56(sp)
ffffffffc02023da:	f862                	sd	s8,48(sp)
ffffffffc02023dc:	f466                	sd	s9,40(sp)
ffffffffc02023de:	f06a                	sd	s10,32(sp)
ffffffffc02023e0:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023e2:	17d2                	slli	a5,a5,0x34
ffffffffc02023e4:	20079a63          	bnez	a5,ffffffffc02025f8 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02023e8:	002007b7          	lui	a5,0x200
ffffffffc02023ec:	24f5e463          	bltu	a1,a5,ffffffffc0202634 <exit_range+0x272>
ffffffffc02023f0:	8ab2                	mv	s5,a2
ffffffffc02023f2:	24c5f163          	bgeu	a1,a2,ffffffffc0202634 <exit_range+0x272>
ffffffffc02023f6:	4785                	li	a5,1
ffffffffc02023f8:	07fe                	slli	a5,a5,0x1f
ffffffffc02023fa:	22c7ed63          	bltu	a5,a2,ffffffffc0202634 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02023fe:	c00009b7          	lui	s3,0xc0000
ffffffffc0202402:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202406:	ffe00937          	lui	s2,0xffe00
ffffffffc020240a:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc020240e:	5cfd                	li	s9,-1
ffffffffc0202410:	8c2a                	mv	s8,a0
ffffffffc0202412:	0125f933          	and	s2,a1,s2
ffffffffc0202416:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc0202418:	000a8d17          	auipc	s10,0xa8
ffffffffc020241c:	2a8d0d13          	addi	s10,s10,680 # ffffffffc02aa6c0 <npage>
    return KADDR(page2pa(page));
ffffffffc0202420:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202424:	000a8717          	auipc	a4,0xa8
ffffffffc0202428:	2a470713          	addi	a4,a4,676 # ffffffffc02aa6c8 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc020242c:	000a8d97          	auipc	s11,0xa8
ffffffffc0202430:	2a4d8d93          	addi	s11,s11,676 # ffffffffc02aa6d0 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202434:	c0000437          	lui	s0,0xc0000
ffffffffc0202438:	944e                	add	s0,s0,s3
ffffffffc020243a:	8079                	srli	s0,s0,0x1e
ffffffffc020243c:	1ff47413          	andi	s0,s0,511
ffffffffc0202440:	040e                	slli	s0,s0,0x3
ffffffffc0202442:	9462                	add	s0,s0,s8
ffffffffc0202444:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee8>
        if (pde1 & PTE_V)
ffffffffc0202448:	001a7793          	andi	a5,s4,1
ffffffffc020244c:	eb99                	bnez	a5,ffffffffc0202462 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc020244e:	12098463          	beqz	s3,ffffffffc0202576 <exit_range+0x1b4>
ffffffffc0202452:	400007b7          	lui	a5,0x40000
ffffffffc0202456:	97ce                	add	a5,a5,s3
ffffffffc0202458:	894e                	mv	s2,s3
ffffffffc020245a:	1159fe63          	bgeu	s3,s5,ffffffffc0202576 <exit_range+0x1b4>
ffffffffc020245e:	89be                	mv	s3,a5
ffffffffc0202460:	bfd1                	j	ffffffffc0202434 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc0202462:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202466:	0a0a                	slli	s4,s4,0x2
ffffffffc0202468:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc020246c:	1cfa7263          	bgeu	s4,a5,ffffffffc0202630 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202470:	fff80637          	lui	a2,0xfff80
ffffffffc0202474:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc0202476:	000806b7          	lui	a3,0x80
ffffffffc020247a:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc020247c:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202480:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202482:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202484:	18f5fa63          	bgeu	a1,a5,ffffffffc0202618 <exit_range+0x256>
ffffffffc0202488:	000a8817          	auipc	a6,0xa8
ffffffffc020248c:	25080813          	addi	a6,a6,592 # ffffffffc02aa6d8 <va_pa_offset>
ffffffffc0202490:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc0202494:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc0202496:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc020249a:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc020249c:	00080337          	lui	t1,0x80
ffffffffc02024a0:	6885                	lui	a7,0x1
ffffffffc02024a2:	a819                	j	ffffffffc02024b8 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02024a4:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02024a6:	002007b7          	lui	a5,0x200
ffffffffc02024aa:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02024ac:	08090c63          	beqz	s2,ffffffffc0202544 <exit_range+0x182>
ffffffffc02024b0:	09397a63          	bgeu	s2,s3,ffffffffc0202544 <exit_range+0x182>
ffffffffc02024b4:	0f597063          	bgeu	s2,s5,ffffffffc0202594 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02024b8:	01595493          	srli	s1,s2,0x15
ffffffffc02024bc:	1ff4f493          	andi	s1,s1,511
ffffffffc02024c0:	048e                	slli	s1,s1,0x3
ffffffffc02024c2:	94da                	add	s1,s1,s6
ffffffffc02024c4:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02024c6:	0017f693          	andi	a3,a5,1
ffffffffc02024ca:	dee9                	beqz	a3,ffffffffc02024a4 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc02024cc:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024d0:	078a                	slli	a5,a5,0x2
ffffffffc02024d2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024d4:	14b7fe63          	bgeu	a5,a1,ffffffffc0202630 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02024d8:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02024da:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02024de:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02024e2:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02024e6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02024e8:	12bef863          	bgeu	t4,a1,ffffffffc0202618 <exit_range+0x256>
ffffffffc02024ec:	00083783          	ld	a5,0(a6)
ffffffffc02024f0:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024f2:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc02024f6:	629c                	ld	a5,0(a3)
ffffffffc02024f8:	8b85                	andi	a5,a5,1
ffffffffc02024fa:	f7d5                	bnez	a5,ffffffffc02024a6 <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024fc:	06a1                	addi	a3,a3,8
ffffffffc02024fe:	fed59ce3          	bne	a1,a3,ffffffffc02024f6 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202502:	631c                	ld	a5,0(a4)
ffffffffc0202504:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202506:	100027f3          	csrr	a5,sstatus
ffffffffc020250a:	8b89                	andi	a5,a5,2
ffffffffc020250c:	e7d9                	bnez	a5,ffffffffc020259a <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc020250e:	000db783          	ld	a5,0(s11)
ffffffffc0202512:	4585                	li	a1,1
ffffffffc0202514:	e032                	sd	a2,0(sp)
ffffffffc0202516:	739c                	ld	a5,32(a5)
ffffffffc0202518:	9782                	jalr	a5
    if (flag)
ffffffffc020251a:	6602                	ld	a2,0(sp)
ffffffffc020251c:	000a8817          	auipc	a6,0xa8
ffffffffc0202520:	1bc80813          	addi	a6,a6,444 # ffffffffc02aa6d8 <va_pa_offset>
ffffffffc0202524:	fff80e37          	lui	t3,0xfff80
ffffffffc0202528:	00080337          	lui	t1,0x80
ffffffffc020252c:	6885                	lui	a7,0x1
ffffffffc020252e:	000a8717          	auipc	a4,0xa8
ffffffffc0202532:	19a70713          	addi	a4,a4,410 # ffffffffc02aa6c8 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202536:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020253a:	002007b7          	lui	a5,0x200
ffffffffc020253e:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202540:	f60918e3          	bnez	s2,ffffffffc02024b0 <exit_range+0xee>
            if (free_pd0)
ffffffffc0202544:	f00b85e3          	beqz	s7,ffffffffc020244e <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc0202548:	000d3783          	ld	a5,0(s10)
ffffffffc020254c:	0efa7263          	bgeu	s4,a5,ffffffffc0202630 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202550:	6308                	ld	a0,0(a4)
ffffffffc0202552:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202554:	100027f3          	csrr	a5,sstatus
ffffffffc0202558:	8b89                	andi	a5,a5,2
ffffffffc020255a:	efad                	bnez	a5,ffffffffc02025d4 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc020255c:	000db783          	ld	a5,0(s11)
ffffffffc0202560:	4585                	li	a1,1
ffffffffc0202562:	739c                	ld	a5,32(a5)
ffffffffc0202564:	9782                	jalr	a5
ffffffffc0202566:	000a8717          	auipc	a4,0xa8
ffffffffc020256a:	16270713          	addi	a4,a4,354 # ffffffffc02aa6c8 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020256e:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc0202572:	ee0990e3          	bnez	s3,ffffffffc0202452 <exit_range+0x90>
}
ffffffffc0202576:	70e6                	ld	ra,120(sp)
ffffffffc0202578:	7446                	ld	s0,112(sp)
ffffffffc020257a:	74a6                	ld	s1,104(sp)
ffffffffc020257c:	7906                	ld	s2,96(sp)
ffffffffc020257e:	69e6                	ld	s3,88(sp)
ffffffffc0202580:	6a46                	ld	s4,80(sp)
ffffffffc0202582:	6aa6                	ld	s5,72(sp)
ffffffffc0202584:	6b06                	ld	s6,64(sp)
ffffffffc0202586:	7be2                	ld	s7,56(sp)
ffffffffc0202588:	7c42                	ld	s8,48(sp)
ffffffffc020258a:	7ca2                	ld	s9,40(sp)
ffffffffc020258c:	7d02                	ld	s10,32(sp)
ffffffffc020258e:	6de2                	ld	s11,24(sp)
ffffffffc0202590:	6109                	addi	sp,sp,128
ffffffffc0202592:	8082                	ret
            if (free_pd0)
ffffffffc0202594:	ea0b8fe3          	beqz	s7,ffffffffc0202452 <exit_range+0x90>
ffffffffc0202598:	bf45                	j	ffffffffc0202548 <exit_range+0x186>
ffffffffc020259a:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc020259c:	e42a                	sd	a0,8(sp)
ffffffffc020259e:	c16fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02025a2:	000db783          	ld	a5,0(s11)
ffffffffc02025a6:	6522                	ld	a0,8(sp)
ffffffffc02025a8:	4585                	li	a1,1
ffffffffc02025aa:	739c                	ld	a5,32(a5)
ffffffffc02025ac:	9782                	jalr	a5
        intr_enable();
ffffffffc02025ae:	c00fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02025b2:	6602                	ld	a2,0(sp)
ffffffffc02025b4:	000a8717          	auipc	a4,0xa8
ffffffffc02025b8:	11470713          	addi	a4,a4,276 # ffffffffc02aa6c8 <pages>
ffffffffc02025bc:	6885                	lui	a7,0x1
ffffffffc02025be:	00080337          	lui	t1,0x80
ffffffffc02025c2:	fff80e37          	lui	t3,0xfff80
ffffffffc02025c6:	000a8817          	auipc	a6,0xa8
ffffffffc02025ca:	11280813          	addi	a6,a6,274 # ffffffffc02aa6d8 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02025ce:	0004b023          	sd	zero,0(s1)
ffffffffc02025d2:	b7a5                	j	ffffffffc020253a <exit_range+0x178>
ffffffffc02025d4:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02025d6:	bdefe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02025da:	000db783          	ld	a5,0(s11)
ffffffffc02025de:	6502                	ld	a0,0(sp)
ffffffffc02025e0:	4585                	li	a1,1
ffffffffc02025e2:	739c                	ld	a5,32(a5)
ffffffffc02025e4:	9782                	jalr	a5
        intr_enable();
ffffffffc02025e6:	bc8fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02025ea:	000a8717          	auipc	a4,0xa8
ffffffffc02025ee:	0de70713          	addi	a4,a4,222 # ffffffffc02aa6c8 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02025f2:	00043023          	sd	zero,0(s0)
ffffffffc02025f6:	bfb5                	j	ffffffffc0202572 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02025f8:	00004697          	auipc	a3,0x4
ffffffffc02025fc:	2b068693          	addi	a3,a3,688 # ffffffffc02068a8 <default_pmm_manager+0x160>
ffffffffc0202600:	00004617          	auipc	a2,0x4
ffffffffc0202604:	d9860613          	addi	a2,a2,-616 # ffffffffc0206398 <commands+0x888>
ffffffffc0202608:	13600593          	li	a1,310
ffffffffc020260c:	00004517          	auipc	a0,0x4
ffffffffc0202610:	28c50513          	addi	a0,a0,652 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0202614:	e7bfd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202618:	00004617          	auipc	a2,0x4
ffffffffc020261c:	16860613          	addi	a2,a2,360 # ffffffffc0206780 <default_pmm_manager+0x38>
ffffffffc0202620:	07100593          	li	a1,113
ffffffffc0202624:	00004517          	auipc	a0,0x4
ffffffffc0202628:	18450513          	addi	a0,a0,388 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc020262c:	e63fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202630:	8e1ff0ef          	jal	ra,ffffffffc0201f10 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202634:	00004697          	auipc	a3,0x4
ffffffffc0202638:	2a468693          	addi	a3,a3,676 # ffffffffc02068d8 <default_pmm_manager+0x190>
ffffffffc020263c:	00004617          	auipc	a2,0x4
ffffffffc0202640:	d5c60613          	addi	a2,a2,-676 # ffffffffc0206398 <commands+0x888>
ffffffffc0202644:	13700593          	li	a1,311
ffffffffc0202648:	00004517          	auipc	a0,0x4
ffffffffc020264c:	25050513          	addi	a0,a0,592 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0202650:	e3ffd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202654 <page_remove>:
{
ffffffffc0202654:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202656:	4601                	li	a2,0
{
ffffffffc0202658:	ec26                	sd	s1,24(sp)
ffffffffc020265a:	f406                	sd	ra,40(sp)
ffffffffc020265c:	f022                	sd	s0,32(sp)
ffffffffc020265e:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202660:	9a1ff0ef          	jal	ra,ffffffffc0202000 <get_pte>
    if (ptep != NULL)
ffffffffc0202664:	c511                	beqz	a0,ffffffffc0202670 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0202666:	611c                	ld	a5,0(a0)
ffffffffc0202668:	842a                	mv	s0,a0
ffffffffc020266a:	0017f713          	andi	a4,a5,1
ffffffffc020266e:	e711                	bnez	a4,ffffffffc020267a <page_remove+0x26>
}
ffffffffc0202670:	70a2                	ld	ra,40(sp)
ffffffffc0202672:	7402                	ld	s0,32(sp)
ffffffffc0202674:	64e2                	ld	s1,24(sp)
ffffffffc0202676:	6145                	addi	sp,sp,48
ffffffffc0202678:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020267a:	078a                	slli	a5,a5,0x2
ffffffffc020267c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020267e:	000a8717          	auipc	a4,0xa8
ffffffffc0202682:	04273703          	ld	a4,66(a4) # ffffffffc02aa6c0 <npage>
ffffffffc0202686:	06e7f363          	bgeu	a5,a4,ffffffffc02026ec <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020268a:	fff80537          	lui	a0,0xfff80
ffffffffc020268e:	97aa                	add	a5,a5,a0
ffffffffc0202690:	079a                	slli	a5,a5,0x6
ffffffffc0202692:	000a8517          	auipc	a0,0xa8
ffffffffc0202696:	03653503          	ld	a0,54(a0) # ffffffffc02aa6c8 <pages>
ffffffffc020269a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020269c:	411c                	lw	a5,0(a0)
ffffffffc020269e:	fff7871b          	addiw	a4,a5,-1
ffffffffc02026a2:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02026a4:	cb11                	beqz	a4,ffffffffc02026b8 <page_remove+0x64>
        *ptep = 0;
ffffffffc02026a6:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026aa:	12048073          	sfence.vma	s1
}
ffffffffc02026ae:	70a2                	ld	ra,40(sp)
ffffffffc02026b0:	7402                	ld	s0,32(sp)
ffffffffc02026b2:	64e2                	ld	s1,24(sp)
ffffffffc02026b4:	6145                	addi	sp,sp,48
ffffffffc02026b6:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02026b8:	100027f3          	csrr	a5,sstatus
ffffffffc02026bc:	8b89                	andi	a5,a5,2
ffffffffc02026be:	eb89                	bnez	a5,ffffffffc02026d0 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02026c0:	000a8797          	auipc	a5,0xa8
ffffffffc02026c4:	0107b783          	ld	a5,16(a5) # ffffffffc02aa6d0 <pmm_manager>
ffffffffc02026c8:	739c                	ld	a5,32(a5)
ffffffffc02026ca:	4585                	li	a1,1
ffffffffc02026cc:	9782                	jalr	a5
    if (flag)
ffffffffc02026ce:	bfe1                	j	ffffffffc02026a6 <page_remove+0x52>
        intr_disable();
ffffffffc02026d0:	e42a                	sd	a0,8(sp)
ffffffffc02026d2:	ae2fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02026d6:	000a8797          	auipc	a5,0xa8
ffffffffc02026da:	ffa7b783          	ld	a5,-6(a5) # ffffffffc02aa6d0 <pmm_manager>
ffffffffc02026de:	739c                	ld	a5,32(a5)
ffffffffc02026e0:	6522                	ld	a0,8(sp)
ffffffffc02026e2:	4585                	li	a1,1
ffffffffc02026e4:	9782                	jalr	a5
        intr_enable();
ffffffffc02026e6:	ac8fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02026ea:	bf75                	j	ffffffffc02026a6 <page_remove+0x52>
ffffffffc02026ec:	825ff0ef          	jal	ra,ffffffffc0201f10 <pa2page.part.0>

ffffffffc02026f0 <page_insert>:
{
ffffffffc02026f0:	7139                	addi	sp,sp,-64
ffffffffc02026f2:	e852                	sd	s4,16(sp)
ffffffffc02026f4:	8a32                	mv	s4,a2
ffffffffc02026f6:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026f8:	4605                	li	a2,1
{
ffffffffc02026fa:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026fc:	85d2                	mv	a1,s4
{
ffffffffc02026fe:	f426                	sd	s1,40(sp)
ffffffffc0202700:	fc06                	sd	ra,56(sp)
ffffffffc0202702:	f04a                	sd	s2,32(sp)
ffffffffc0202704:	ec4e                	sd	s3,24(sp)
ffffffffc0202706:	e456                	sd	s5,8(sp)
ffffffffc0202708:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020270a:	8f7ff0ef          	jal	ra,ffffffffc0202000 <get_pte>
    if (ptep == NULL)
ffffffffc020270e:	c961                	beqz	a0,ffffffffc02027de <page_insert+0xee>
    page->ref += 1;
ffffffffc0202710:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202712:	611c                	ld	a5,0(a0)
ffffffffc0202714:	89aa                	mv	s3,a0
ffffffffc0202716:	0016871b          	addiw	a4,a3,1
ffffffffc020271a:	c018                	sw	a4,0(s0)
ffffffffc020271c:	0017f713          	andi	a4,a5,1
ffffffffc0202720:	ef05                	bnez	a4,ffffffffc0202758 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202722:	000a8717          	auipc	a4,0xa8
ffffffffc0202726:	fa673703          	ld	a4,-90(a4) # ffffffffc02aa6c8 <pages>
ffffffffc020272a:	8c19                	sub	s0,s0,a4
ffffffffc020272c:	000807b7          	lui	a5,0x80
ffffffffc0202730:	8419                	srai	s0,s0,0x6
ffffffffc0202732:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202734:	042a                	slli	s0,s0,0xa
ffffffffc0202736:	8cc1                	or	s1,s1,s0
ffffffffc0202738:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020273c:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee8>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202740:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202744:	4501                	li	a0,0
}
ffffffffc0202746:	70e2                	ld	ra,56(sp)
ffffffffc0202748:	7442                	ld	s0,48(sp)
ffffffffc020274a:	74a2                	ld	s1,40(sp)
ffffffffc020274c:	7902                	ld	s2,32(sp)
ffffffffc020274e:	69e2                	ld	s3,24(sp)
ffffffffc0202750:	6a42                	ld	s4,16(sp)
ffffffffc0202752:	6aa2                	ld	s5,8(sp)
ffffffffc0202754:	6121                	addi	sp,sp,64
ffffffffc0202756:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202758:	078a                	slli	a5,a5,0x2
ffffffffc020275a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020275c:	000a8717          	auipc	a4,0xa8
ffffffffc0202760:	f6473703          	ld	a4,-156(a4) # ffffffffc02aa6c0 <npage>
ffffffffc0202764:	06e7ff63          	bgeu	a5,a4,ffffffffc02027e2 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202768:	000a8a97          	auipc	s5,0xa8
ffffffffc020276c:	f60a8a93          	addi	s5,s5,-160 # ffffffffc02aa6c8 <pages>
ffffffffc0202770:	000ab703          	ld	a4,0(s5)
ffffffffc0202774:	fff80937          	lui	s2,0xfff80
ffffffffc0202778:	993e                	add	s2,s2,a5
ffffffffc020277a:	091a                	slli	s2,s2,0x6
ffffffffc020277c:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc020277e:	01240c63          	beq	s0,s2,ffffffffc0202796 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202782:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcd58fc>
ffffffffc0202786:	fff7869b          	addiw	a3,a5,-1
ffffffffc020278a:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc020278e:	c691                	beqz	a3,ffffffffc020279a <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202790:	120a0073          	sfence.vma	s4
}
ffffffffc0202794:	bf59                	j	ffffffffc020272a <page_insert+0x3a>
ffffffffc0202796:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202798:	bf49                	j	ffffffffc020272a <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020279a:	100027f3          	csrr	a5,sstatus
ffffffffc020279e:	8b89                	andi	a5,a5,2
ffffffffc02027a0:	ef91                	bnez	a5,ffffffffc02027bc <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02027a2:	000a8797          	auipc	a5,0xa8
ffffffffc02027a6:	f2e7b783          	ld	a5,-210(a5) # ffffffffc02aa6d0 <pmm_manager>
ffffffffc02027aa:	739c                	ld	a5,32(a5)
ffffffffc02027ac:	4585                	li	a1,1
ffffffffc02027ae:	854a                	mv	a0,s2
ffffffffc02027b0:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02027b2:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027b6:	120a0073          	sfence.vma	s4
ffffffffc02027ba:	bf85                	j	ffffffffc020272a <page_insert+0x3a>
        intr_disable();
ffffffffc02027bc:	9f8fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027c0:	000a8797          	auipc	a5,0xa8
ffffffffc02027c4:	f107b783          	ld	a5,-240(a5) # ffffffffc02aa6d0 <pmm_manager>
ffffffffc02027c8:	739c                	ld	a5,32(a5)
ffffffffc02027ca:	4585                	li	a1,1
ffffffffc02027cc:	854a                	mv	a0,s2
ffffffffc02027ce:	9782                	jalr	a5
        intr_enable();
ffffffffc02027d0:	9defe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02027d4:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027d8:	120a0073          	sfence.vma	s4
ffffffffc02027dc:	b7b9                	j	ffffffffc020272a <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02027de:	5571                	li	a0,-4
ffffffffc02027e0:	b79d                	j	ffffffffc0202746 <page_insert+0x56>
ffffffffc02027e2:	f2eff0ef          	jal	ra,ffffffffc0201f10 <pa2page.part.0>

ffffffffc02027e6 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02027e6:	00004797          	auipc	a5,0x4
ffffffffc02027ea:	f6278793          	addi	a5,a5,-158 # ffffffffc0206748 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027ee:	638c                	ld	a1,0(a5)
{
ffffffffc02027f0:	7159                	addi	sp,sp,-112
ffffffffc02027f2:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027f4:	00004517          	auipc	a0,0x4
ffffffffc02027f8:	0fc50513          	addi	a0,a0,252 # ffffffffc02068f0 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc02027fc:	000a8b17          	auipc	s6,0xa8
ffffffffc0202800:	ed4b0b13          	addi	s6,s6,-300 # ffffffffc02aa6d0 <pmm_manager>
{
ffffffffc0202804:	f486                	sd	ra,104(sp)
ffffffffc0202806:	e8ca                	sd	s2,80(sp)
ffffffffc0202808:	e4ce                	sd	s3,72(sp)
ffffffffc020280a:	f0a2                	sd	s0,96(sp)
ffffffffc020280c:	eca6                	sd	s1,88(sp)
ffffffffc020280e:	e0d2                	sd	s4,64(sp)
ffffffffc0202810:	fc56                	sd	s5,56(sp)
ffffffffc0202812:	f45e                	sd	s7,40(sp)
ffffffffc0202814:	f062                	sd	s8,32(sp)
ffffffffc0202816:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202818:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020281c:	979fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202820:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202824:	000a8997          	auipc	s3,0xa8
ffffffffc0202828:	eb498993          	addi	s3,s3,-332 # ffffffffc02aa6d8 <va_pa_offset>
    pmm_manager->init();
ffffffffc020282c:	679c                	ld	a5,8(a5)
ffffffffc020282e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202830:	57f5                	li	a5,-3
ffffffffc0202832:	07fa                	slli	a5,a5,0x1e
ffffffffc0202834:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202838:	962fe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc020283c:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc020283e:	966fe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc0202842:	200505e3          	beqz	a0,ffffffffc020324c <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202846:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202848:	00004517          	auipc	a0,0x4
ffffffffc020284c:	0e050513          	addi	a0,a0,224 # ffffffffc0206928 <default_pmm_manager+0x1e0>
ffffffffc0202850:	945fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202854:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202858:	fff40693          	addi	a3,s0,-1
ffffffffc020285c:	864a                	mv	a2,s2
ffffffffc020285e:	85a6                	mv	a1,s1
ffffffffc0202860:	00004517          	auipc	a0,0x4
ffffffffc0202864:	0e050513          	addi	a0,a0,224 # ffffffffc0206940 <default_pmm_manager+0x1f8>
ffffffffc0202868:	92dfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020286c:	c8000737          	lui	a4,0xc8000
ffffffffc0202870:	87a2                	mv	a5,s0
ffffffffc0202872:	54876163          	bltu	a4,s0,ffffffffc0202db4 <pmm_init+0x5ce>
ffffffffc0202876:	757d                	lui	a0,0xfffff
ffffffffc0202878:	000a9617          	auipc	a2,0xa9
ffffffffc020287c:	e8b60613          	addi	a2,a2,-373 # ffffffffc02ab703 <end+0xfff>
ffffffffc0202880:	8e69                	and	a2,a2,a0
ffffffffc0202882:	000a8497          	auipc	s1,0xa8
ffffffffc0202886:	e3e48493          	addi	s1,s1,-450 # ffffffffc02aa6c0 <npage>
ffffffffc020288a:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020288e:	000a8b97          	auipc	s7,0xa8
ffffffffc0202892:	e3ab8b93          	addi	s7,s7,-454 # ffffffffc02aa6c8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202896:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202898:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020289c:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02028a0:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02028a2:	02f50863          	beq	a0,a5,ffffffffc02028d2 <pmm_init+0xec>
ffffffffc02028a6:	4781                	li	a5,0
ffffffffc02028a8:	4585                	li	a1,1
ffffffffc02028aa:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02028ae:	00679513          	slli	a0,a5,0x6
ffffffffc02028b2:	9532                	add	a0,a0,a2
ffffffffc02028b4:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd54904>
ffffffffc02028b8:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02028bc:	6088                	ld	a0,0(s1)
ffffffffc02028be:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02028c0:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02028c4:	00d50733          	add	a4,a0,a3
ffffffffc02028c8:	fee7e3e3          	bltu	a5,a4,ffffffffc02028ae <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028cc:	071a                	slli	a4,a4,0x6
ffffffffc02028ce:	00e606b3          	add	a3,a2,a4
ffffffffc02028d2:	c02007b7          	lui	a5,0xc0200
ffffffffc02028d6:	2ef6ece3          	bltu	a3,a5,ffffffffc02033ce <pmm_init+0xbe8>
ffffffffc02028da:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02028de:	77fd                	lui	a5,0xfffff
ffffffffc02028e0:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028e2:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02028e4:	5086eb63          	bltu	a3,s0,ffffffffc0202dfa <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02028e8:	00004517          	auipc	a0,0x4
ffffffffc02028ec:	08050513          	addi	a0,a0,128 # ffffffffc0206968 <default_pmm_manager+0x220>
ffffffffc02028f0:	8a5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02028f4:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028f8:	000a8917          	auipc	s2,0xa8
ffffffffc02028fc:	dc090913          	addi	s2,s2,-576 # ffffffffc02aa6b8 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202900:	7b9c                	ld	a5,48(a5)
ffffffffc0202902:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202904:	00004517          	auipc	a0,0x4
ffffffffc0202908:	07c50513          	addi	a0,a0,124 # ffffffffc0206980 <default_pmm_manager+0x238>
ffffffffc020290c:	889fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202910:	00007697          	auipc	a3,0x7
ffffffffc0202914:	6f068693          	addi	a3,a3,1776 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202918:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020291c:	c02007b7          	lui	a5,0xc0200
ffffffffc0202920:	28f6ebe3          	bltu	a3,a5,ffffffffc02033b6 <pmm_init+0xbd0>
ffffffffc0202924:	0009b783          	ld	a5,0(s3)
ffffffffc0202928:	8e9d                	sub	a3,a3,a5
ffffffffc020292a:	000a8797          	auipc	a5,0xa8
ffffffffc020292e:	d8d7b323          	sd	a3,-634(a5) # ffffffffc02aa6b0 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202932:	100027f3          	csrr	a5,sstatus
ffffffffc0202936:	8b89                	andi	a5,a5,2
ffffffffc0202938:	4a079763          	bnez	a5,ffffffffc0202de6 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc020293c:	000b3783          	ld	a5,0(s6)
ffffffffc0202940:	779c                	ld	a5,40(a5)
ffffffffc0202942:	9782                	jalr	a5
ffffffffc0202944:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202946:	6098                	ld	a4,0(s1)
ffffffffc0202948:	c80007b7          	lui	a5,0xc8000
ffffffffc020294c:	83b1                	srli	a5,a5,0xc
ffffffffc020294e:	66e7e363          	bltu	a5,a4,ffffffffc0202fb4 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202952:	00093503          	ld	a0,0(s2)
ffffffffc0202956:	62050f63          	beqz	a0,ffffffffc0202f94 <pmm_init+0x7ae>
ffffffffc020295a:	03451793          	slli	a5,a0,0x34
ffffffffc020295e:	62079b63          	bnez	a5,ffffffffc0202f94 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202962:	4601                	li	a2,0
ffffffffc0202964:	4581                	li	a1,0
ffffffffc0202966:	8c3ff0ef          	jal	ra,ffffffffc0202228 <get_page>
ffffffffc020296a:	60051563          	bnez	a0,ffffffffc0202f74 <pmm_init+0x78e>
ffffffffc020296e:	100027f3          	csrr	a5,sstatus
ffffffffc0202972:	8b89                	andi	a5,a5,2
ffffffffc0202974:	44079e63          	bnez	a5,ffffffffc0202dd0 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202978:	000b3783          	ld	a5,0(s6)
ffffffffc020297c:	4505                	li	a0,1
ffffffffc020297e:	6f9c                	ld	a5,24(a5)
ffffffffc0202980:	9782                	jalr	a5
ffffffffc0202982:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202984:	00093503          	ld	a0,0(s2)
ffffffffc0202988:	4681                	li	a3,0
ffffffffc020298a:	4601                	li	a2,0
ffffffffc020298c:	85d2                	mv	a1,s4
ffffffffc020298e:	d63ff0ef          	jal	ra,ffffffffc02026f0 <page_insert>
ffffffffc0202992:	26051ae3          	bnez	a0,ffffffffc0203406 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202996:	00093503          	ld	a0,0(s2)
ffffffffc020299a:	4601                	li	a2,0
ffffffffc020299c:	4581                	li	a1,0
ffffffffc020299e:	e62ff0ef          	jal	ra,ffffffffc0202000 <get_pte>
ffffffffc02029a2:	240502e3          	beqz	a0,ffffffffc02033e6 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc02029a6:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02029a8:	0017f713          	andi	a4,a5,1
ffffffffc02029ac:	5a070263          	beqz	a4,ffffffffc0202f50 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02029b0:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02029b2:	078a                	slli	a5,a5,0x2
ffffffffc02029b4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029b6:	58e7fb63          	bgeu	a5,a4,ffffffffc0202f4c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029ba:	000bb683          	ld	a3,0(s7)
ffffffffc02029be:	fff80637          	lui	a2,0xfff80
ffffffffc02029c2:	97b2                	add	a5,a5,a2
ffffffffc02029c4:	079a                	slli	a5,a5,0x6
ffffffffc02029c6:	97b6                	add	a5,a5,a3
ffffffffc02029c8:	14fa17e3          	bne	s4,a5,ffffffffc0203316 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc02029cc:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
ffffffffc02029d0:	4785                	li	a5,1
ffffffffc02029d2:	12f692e3          	bne	a3,a5,ffffffffc02032f6 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02029d6:	00093503          	ld	a0,0(s2)
ffffffffc02029da:	77fd                	lui	a5,0xfffff
ffffffffc02029dc:	6114                	ld	a3,0(a0)
ffffffffc02029de:	068a                	slli	a3,a3,0x2
ffffffffc02029e0:	8efd                	and	a3,a3,a5
ffffffffc02029e2:	00c6d613          	srli	a2,a3,0xc
ffffffffc02029e6:	0ee67ce3          	bgeu	a2,a4,ffffffffc02032de <pmm_init+0xaf8>
ffffffffc02029ea:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029ee:	96e2                	add	a3,a3,s8
ffffffffc02029f0:	0006ba83          	ld	s5,0(a3)
ffffffffc02029f4:	0a8a                	slli	s5,s5,0x2
ffffffffc02029f6:	00fafab3          	and	s5,s5,a5
ffffffffc02029fa:	00cad793          	srli	a5,s5,0xc
ffffffffc02029fe:	0ce7f3e3          	bgeu	a5,a4,ffffffffc02032c4 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a02:	4601                	li	a2,0
ffffffffc0202a04:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a06:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a08:	df8ff0ef          	jal	ra,ffffffffc0202000 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a0c:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a0e:	55551363          	bne	a0,s5,ffffffffc0202f54 <pmm_init+0x76e>
ffffffffc0202a12:	100027f3          	csrr	a5,sstatus
ffffffffc0202a16:	8b89                	andi	a5,a5,2
ffffffffc0202a18:	3a079163          	bnez	a5,ffffffffc0202dba <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202a1c:	000b3783          	ld	a5,0(s6)
ffffffffc0202a20:	4505                	li	a0,1
ffffffffc0202a22:	6f9c                	ld	a5,24(a5)
ffffffffc0202a24:	9782                	jalr	a5
ffffffffc0202a26:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202a28:	00093503          	ld	a0,0(s2)
ffffffffc0202a2c:	46d1                	li	a3,20
ffffffffc0202a2e:	6605                	lui	a2,0x1
ffffffffc0202a30:	85e2                	mv	a1,s8
ffffffffc0202a32:	cbfff0ef          	jal	ra,ffffffffc02026f0 <page_insert>
ffffffffc0202a36:	060517e3          	bnez	a0,ffffffffc02032a4 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a3a:	00093503          	ld	a0,0(s2)
ffffffffc0202a3e:	4601                	li	a2,0
ffffffffc0202a40:	6585                	lui	a1,0x1
ffffffffc0202a42:	dbeff0ef          	jal	ra,ffffffffc0202000 <get_pte>
ffffffffc0202a46:	02050fe3          	beqz	a0,ffffffffc0203284 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202a4a:	611c                	ld	a5,0(a0)
ffffffffc0202a4c:	0107f713          	andi	a4,a5,16
ffffffffc0202a50:	7c070e63          	beqz	a4,ffffffffc020322c <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202a54:	8b91                	andi	a5,a5,4
ffffffffc0202a56:	7a078b63          	beqz	a5,ffffffffc020320c <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202a5a:	00093503          	ld	a0,0(s2)
ffffffffc0202a5e:	611c                	ld	a5,0(a0)
ffffffffc0202a60:	8bc1                	andi	a5,a5,16
ffffffffc0202a62:	78078563          	beqz	a5,ffffffffc02031ec <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202a66:	000c2703          	lw	a4,0(s8)
ffffffffc0202a6a:	4785                	li	a5,1
ffffffffc0202a6c:	76f71063          	bne	a4,a5,ffffffffc02031cc <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202a70:	4681                	li	a3,0
ffffffffc0202a72:	6605                	lui	a2,0x1
ffffffffc0202a74:	85d2                	mv	a1,s4
ffffffffc0202a76:	c7bff0ef          	jal	ra,ffffffffc02026f0 <page_insert>
ffffffffc0202a7a:	72051963          	bnez	a0,ffffffffc02031ac <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202a7e:	000a2703          	lw	a4,0(s4)
ffffffffc0202a82:	4789                	li	a5,2
ffffffffc0202a84:	70f71463          	bne	a4,a5,ffffffffc020318c <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202a88:	000c2783          	lw	a5,0(s8)
ffffffffc0202a8c:	6e079063          	bnez	a5,ffffffffc020316c <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a90:	00093503          	ld	a0,0(s2)
ffffffffc0202a94:	4601                	li	a2,0
ffffffffc0202a96:	6585                	lui	a1,0x1
ffffffffc0202a98:	d68ff0ef          	jal	ra,ffffffffc0202000 <get_pte>
ffffffffc0202a9c:	6a050863          	beqz	a0,ffffffffc020314c <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202aa0:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202aa2:	00177793          	andi	a5,a4,1
ffffffffc0202aa6:	4a078563          	beqz	a5,ffffffffc0202f50 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202aaa:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202aac:	00271793          	slli	a5,a4,0x2
ffffffffc0202ab0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ab2:	48d7fd63          	bgeu	a5,a3,ffffffffc0202f4c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ab6:	000bb683          	ld	a3,0(s7)
ffffffffc0202aba:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202abe:	97d6                	add	a5,a5,s5
ffffffffc0202ac0:	079a                	slli	a5,a5,0x6
ffffffffc0202ac2:	97b6                	add	a5,a5,a3
ffffffffc0202ac4:	66fa1463          	bne	s4,a5,ffffffffc020312c <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202ac8:	8b41                	andi	a4,a4,16
ffffffffc0202aca:	64071163          	bnez	a4,ffffffffc020310c <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202ace:	00093503          	ld	a0,0(s2)
ffffffffc0202ad2:	4581                	li	a1,0
ffffffffc0202ad4:	b81ff0ef          	jal	ra,ffffffffc0202654 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202ad8:	000a2c83          	lw	s9,0(s4)
ffffffffc0202adc:	4785                	li	a5,1
ffffffffc0202ade:	60fc9763          	bne	s9,a5,ffffffffc02030ec <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202ae2:	000c2783          	lw	a5,0(s8)
ffffffffc0202ae6:	5e079363          	bnez	a5,ffffffffc02030cc <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202aea:	00093503          	ld	a0,0(s2)
ffffffffc0202aee:	6585                	lui	a1,0x1
ffffffffc0202af0:	b65ff0ef          	jal	ra,ffffffffc0202654 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202af4:	000a2783          	lw	a5,0(s4)
ffffffffc0202af8:	52079a63          	bnez	a5,ffffffffc020302c <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202afc:	000c2783          	lw	a5,0(s8)
ffffffffc0202b00:	50079663          	bnez	a5,ffffffffc020300c <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202b04:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202b08:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b0a:	000a3683          	ld	a3,0(s4)
ffffffffc0202b0e:	068a                	slli	a3,a3,0x2
ffffffffc0202b10:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b12:	42b6fd63          	bgeu	a3,a1,ffffffffc0202f4c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b16:	000bb503          	ld	a0,0(s7)
ffffffffc0202b1a:	96d6                	add	a3,a3,s5
ffffffffc0202b1c:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202b1e:	00d507b3          	add	a5,a0,a3
ffffffffc0202b22:	439c                	lw	a5,0(a5)
ffffffffc0202b24:	4d979463          	bne	a5,s9,ffffffffc0202fec <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202b28:	8699                	srai	a3,a3,0x6
ffffffffc0202b2a:	00080637          	lui	a2,0x80
ffffffffc0202b2e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202b30:	00c69713          	slli	a4,a3,0xc
ffffffffc0202b34:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b36:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b38:	48b77e63          	bgeu	a4,a1,ffffffffc0202fd4 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202b3c:	0009b703          	ld	a4,0(s3)
ffffffffc0202b40:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b42:	629c                	ld	a5,0(a3)
ffffffffc0202b44:	078a                	slli	a5,a5,0x2
ffffffffc0202b46:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b48:	40b7f263          	bgeu	a5,a1,ffffffffc0202f4c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b4c:	8f91                	sub	a5,a5,a2
ffffffffc0202b4e:	079a                	slli	a5,a5,0x6
ffffffffc0202b50:	953e                	add	a0,a0,a5
ffffffffc0202b52:	100027f3          	csrr	a5,sstatus
ffffffffc0202b56:	8b89                	andi	a5,a5,2
ffffffffc0202b58:	30079963          	bnez	a5,ffffffffc0202e6a <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202b5c:	000b3783          	ld	a5,0(s6)
ffffffffc0202b60:	4585                	li	a1,1
ffffffffc0202b62:	739c                	ld	a5,32(a5)
ffffffffc0202b64:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b66:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202b6a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b6c:	078a                	slli	a5,a5,0x2
ffffffffc0202b6e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b70:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202f4c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b74:	000bb503          	ld	a0,0(s7)
ffffffffc0202b78:	fff80737          	lui	a4,0xfff80
ffffffffc0202b7c:	97ba                	add	a5,a5,a4
ffffffffc0202b7e:	079a                	slli	a5,a5,0x6
ffffffffc0202b80:	953e                	add	a0,a0,a5
ffffffffc0202b82:	100027f3          	csrr	a5,sstatus
ffffffffc0202b86:	8b89                	andi	a5,a5,2
ffffffffc0202b88:	2c079563          	bnez	a5,ffffffffc0202e52 <pmm_init+0x66c>
ffffffffc0202b8c:	000b3783          	ld	a5,0(s6)
ffffffffc0202b90:	4585                	li	a1,1
ffffffffc0202b92:	739c                	ld	a5,32(a5)
ffffffffc0202b94:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b96:	00093783          	ld	a5,0(s2)
ffffffffc0202b9a:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd548fc>
    asm volatile("sfence.vma");
ffffffffc0202b9e:	12000073          	sfence.vma
ffffffffc0202ba2:	100027f3          	csrr	a5,sstatus
ffffffffc0202ba6:	8b89                	andi	a5,a5,2
ffffffffc0202ba8:	28079b63          	bnez	a5,ffffffffc0202e3e <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202bac:	000b3783          	ld	a5,0(s6)
ffffffffc0202bb0:	779c                	ld	a5,40(a5)
ffffffffc0202bb2:	9782                	jalr	a5
ffffffffc0202bb4:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202bb6:	4b441b63          	bne	s0,s4,ffffffffc020306c <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202bba:	00004517          	auipc	a0,0x4
ffffffffc0202bbe:	0ee50513          	addi	a0,a0,238 # ffffffffc0206ca8 <default_pmm_manager+0x560>
ffffffffc0202bc2:	dd2fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202bc6:	100027f3          	csrr	a5,sstatus
ffffffffc0202bca:	8b89                	andi	a5,a5,2
ffffffffc0202bcc:	24079f63          	bnez	a5,ffffffffc0202e2a <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202bd0:	000b3783          	ld	a5,0(s6)
ffffffffc0202bd4:	779c                	ld	a5,40(a5)
ffffffffc0202bd6:	9782                	jalr	a5
ffffffffc0202bd8:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bda:	6098                	ld	a4,0(s1)
ffffffffc0202bdc:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202be0:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202be2:	00c71793          	slli	a5,a4,0xc
ffffffffc0202be6:	6a05                	lui	s4,0x1
ffffffffc0202be8:	02f47c63          	bgeu	s0,a5,ffffffffc0202c20 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202bec:	00c45793          	srli	a5,s0,0xc
ffffffffc0202bf0:	00093503          	ld	a0,0(s2)
ffffffffc0202bf4:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202ef2 <pmm_init+0x70c>
ffffffffc0202bf8:	0009b583          	ld	a1,0(s3)
ffffffffc0202bfc:	4601                	li	a2,0
ffffffffc0202bfe:	95a2                	add	a1,a1,s0
ffffffffc0202c00:	c00ff0ef          	jal	ra,ffffffffc0202000 <get_pte>
ffffffffc0202c04:	32050463          	beqz	a0,ffffffffc0202f2c <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202c08:	611c                	ld	a5,0(a0)
ffffffffc0202c0a:	078a                	slli	a5,a5,0x2
ffffffffc0202c0c:	0157f7b3          	and	a5,a5,s5
ffffffffc0202c10:	2e879e63          	bne	a5,s0,ffffffffc0202f0c <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202c14:	6098                	ld	a4,0(s1)
ffffffffc0202c16:	9452                	add	s0,s0,s4
ffffffffc0202c18:	00c71793          	slli	a5,a4,0xc
ffffffffc0202c1c:	fcf468e3          	bltu	s0,a5,ffffffffc0202bec <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202c20:	00093783          	ld	a5,0(s2)
ffffffffc0202c24:	639c                	ld	a5,0(a5)
ffffffffc0202c26:	42079363          	bnez	a5,ffffffffc020304c <pmm_init+0x866>
ffffffffc0202c2a:	100027f3          	csrr	a5,sstatus
ffffffffc0202c2e:	8b89                	andi	a5,a5,2
ffffffffc0202c30:	24079963          	bnez	a5,ffffffffc0202e82 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c34:	000b3783          	ld	a5,0(s6)
ffffffffc0202c38:	4505                	li	a0,1
ffffffffc0202c3a:	6f9c                	ld	a5,24(a5)
ffffffffc0202c3c:	9782                	jalr	a5
ffffffffc0202c3e:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202c40:	00093503          	ld	a0,0(s2)
ffffffffc0202c44:	4699                	li	a3,6
ffffffffc0202c46:	10000613          	li	a2,256
ffffffffc0202c4a:	85d2                	mv	a1,s4
ffffffffc0202c4c:	aa5ff0ef          	jal	ra,ffffffffc02026f0 <page_insert>
ffffffffc0202c50:	44051e63          	bnez	a0,ffffffffc02030ac <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202c54:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
ffffffffc0202c58:	4785                	li	a5,1
ffffffffc0202c5a:	42f71963          	bne	a4,a5,ffffffffc020308c <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202c5e:	00093503          	ld	a0,0(s2)
ffffffffc0202c62:	6405                	lui	s0,0x1
ffffffffc0202c64:	4699                	li	a3,6
ffffffffc0202c66:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8aa8>
ffffffffc0202c6a:	85d2                	mv	a1,s4
ffffffffc0202c6c:	a85ff0ef          	jal	ra,ffffffffc02026f0 <page_insert>
ffffffffc0202c70:	72051363          	bnez	a0,ffffffffc0203396 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202c74:	000a2703          	lw	a4,0(s4)
ffffffffc0202c78:	4789                	li	a5,2
ffffffffc0202c7a:	6ef71e63          	bne	a4,a5,ffffffffc0203376 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202c7e:	00004597          	auipc	a1,0x4
ffffffffc0202c82:	17258593          	addi	a1,a1,370 # ffffffffc0206df0 <default_pmm_manager+0x6a8>
ffffffffc0202c86:	10000513          	li	a0,256
ffffffffc0202c8a:	389020ef          	jal	ra,ffffffffc0205812 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c8e:	10040593          	addi	a1,s0,256
ffffffffc0202c92:	10000513          	li	a0,256
ffffffffc0202c96:	38f020ef          	jal	ra,ffffffffc0205824 <strcmp>
ffffffffc0202c9a:	6a051e63          	bnez	a0,ffffffffc0203356 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202c9e:	000bb683          	ld	a3,0(s7)
ffffffffc0202ca2:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202ca6:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202ca8:	40da06b3          	sub	a3,s4,a3
ffffffffc0202cac:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202cae:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202cb0:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202cb2:	8031                	srli	s0,s0,0xc
ffffffffc0202cb4:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202cb8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202cba:	30f77d63          	bgeu	a4,a5,ffffffffc0202fd4 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202cbe:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202cc2:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202cc6:	96be                	add	a3,a3,a5
ffffffffc0202cc8:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ccc:	311020ef          	jal	ra,ffffffffc02057dc <strlen>
ffffffffc0202cd0:	66051363          	bnez	a0,ffffffffc0203336 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202cd4:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202cd8:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cda:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd548fc>
ffffffffc0202cde:	068a                	slli	a3,a3,0x2
ffffffffc0202ce0:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ce2:	26f6f563          	bgeu	a3,a5,ffffffffc0202f4c <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202ce6:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ce8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202cea:	2ef47563          	bgeu	s0,a5,ffffffffc0202fd4 <pmm_init+0x7ee>
ffffffffc0202cee:	0009b403          	ld	s0,0(s3)
ffffffffc0202cf2:	9436                	add	s0,s0,a3
ffffffffc0202cf4:	100027f3          	csrr	a5,sstatus
ffffffffc0202cf8:	8b89                	andi	a5,a5,2
ffffffffc0202cfa:	1e079163          	bnez	a5,ffffffffc0202edc <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202cfe:	000b3783          	ld	a5,0(s6)
ffffffffc0202d02:	4585                	li	a1,1
ffffffffc0202d04:	8552                	mv	a0,s4
ffffffffc0202d06:	739c                	ld	a5,32(a5)
ffffffffc0202d08:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d0a:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202d0c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d0e:	078a                	slli	a5,a5,0x2
ffffffffc0202d10:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d12:	22e7fd63          	bgeu	a5,a4,ffffffffc0202f4c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d16:	000bb503          	ld	a0,0(s7)
ffffffffc0202d1a:	fff80737          	lui	a4,0xfff80
ffffffffc0202d1e:	97ba                	add	a5,a5,a4
ffffffffc0202d20:	079a                	slli	a5,a5,0x6
ffffffffc0202d22:	953e                	add	a0,a0,a5
ffffffffc0202d24:	100027f3          	csrr	a5,sstatus
ffffffffc0202d28:	8b89                	andi	a5,a5,2
ffffffffc0202d2a:	18079d63          	bnez	a5,ffffffffc0202ec4 <pmm_init+0x6de>
ffffffffc0202d2e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d32:	4585                	li	a1,1
ffffffffc0202d34:	739c                	ld	a5,32(a5)
ffffffffc0202d36:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d38:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202d3c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d3e:	078a                	slli	a5,a5,0x2
ffffffffc0202d40:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d42:	20e7f563          	bgeu	a5,a4,ffffffffc0202f4c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d46:	000bb503          	ld	a0,0(s7)
ffffffffc0202d4a:	fff80737          	lui	a4,0xfff80
ffffffffc0202d4e:	97ba                	add	a5,a5,a4
ffffffffc0202d50:	079a                	slli	a5,a5,0x6
ffffffffc0202d52:	953e                	add	a0,a0,a5
ffffffffc0202d54:	100027f3          	csrr	a5,sstatus
ffffffffc0202d58:	8b89                	andi	a5,a5,2
ffffffffc0202d5a:	14079963          	bnez	a5,ffffffffc0202eac <pmm_init+0x6c6>
ffffffffc0202d5e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d62:	4585                	li	a1,1
ffffffffc0202d64:	739c                	ld	a5,32(a5)
ffffffffc0202d66:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202d68:	00093783          	ld	a5,0(s2)
ffffffffc0202d6c:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202d70:	12000073          	sfence.vma
ffffffffc0202d74:	100027f3          	csrr	a5,sstatus
ffffffffc0202d78:	8b89                	andi	a5,a5,2
ffffffffc0202d7a:	10079f63          	bnez	a5,ffffffffc0202e98 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d7e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d82:	779c                	ld	a5,40(a5)
ffffffffc0202d84:	9782                	jalr	a5
ffffffffc0202d86:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d88:	4c8c1e63          	bne	s8,s0,ffffffffc0203264 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d8c:	00004517          	auipc	a0,0x4
ffffffffc0202d90:	0dc50513          	addi	a0,a0,220 # ffffffffc0206e68 <default_pmm_manager+0x720>
ffffffffc0202d94:	c00fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202d98:	7406                	ld	s0,96(sp)
ffffffffc0202d9a:	70a6                	ld	ra,104(sp)
ffffffffc0202d9c:	64e6                	ld	s1,88(sp)
ffffffffc0202d9e:	6946                	ld	s2,80(sp)
ffffffffc0202da0:	69a6                	ld	s3,72(sp)
ffffffffc0202da2:	6a06                	ld	s4,64(sp)
ffffffffc0202da4:	7ae2                	ld	s5,56(sp)
ffffffffc0202da6:	7b42                	ld	s6,48(sp)
ffffffffc0202da8:	7ba2                	ld	s7,40(sp)
ffffffffc0202daa:	7c02                	ld	s8,32(sp)
ffffffffc0202dac:	6ce2                	ld	s9,24(sp)
ffffffffc0202dae:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202db0:	f97fe06f          	j	ffffffffc0201d46 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202db4:	c80007b7          	lui	a5,0xc8000
ffffffffc0202db8:	bc7d                	j	ffffffffc0202876 <pmm_init+0x90>
        intr_disable();
ffffffffc0202dba:	bfbfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202dbe:	000b3783          	ld	a5,0(s6)
ffffffffc0202dc2:	4505                	li	a0,1
ffffffffc0202dc4:	6f9c                	ld	a5,24(a5)
ffffffffc0202dc6:	9782                	jalr	a5
ffffffffc0202dc8:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202dca:	be5fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dce:	b9a9                	j	ffffffffc0202a28 <pmm_init+0x242>
        intr_disable();
ffffffffc0202dd0:	be5fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202dd4:	000b3783          	ld	a5,0(s6)
ffffffffc0202dd8:	4505                	li	a0,1
ffffffffc0202dda:	6f9c                	ld	a5,24(a5)
ffffffffc0202ddc:	9782                	jalr	a5
ffffffffc0202dde:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202de0:	bcffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202de4:	b645                	j	ffffffffc0202984 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202de6:	bcffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202dea:	000b3783          	ld	a5,0(s6)
ffffffffc0202dee:	779c                	ld	a5,40(a5)
ffffffffc0202df0:	9782                	jalr	a5
ffffffffc0202df2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202df4:	bbbfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202df8:	b6b9                	j	ffffffffc0202946 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202dfa:	6705                	lui	a4,0x1
ffffffffc0202dfc:	177d                	addi	a4,a4,-1
ffffffffc0202dfe:	96ba                	add	a3,a3,a4
ffffffffc0202e00:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202e02:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202e06:	14a77363          	bgeu	a4,a0,ffffffffc0202f4c <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202e0a:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202e0e:	fff80537          	lui	a0,0xfff80
ffffffffc0202e12:	972a                	add	a4,a4,a0
ffffffffc0202e14:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202e16:	8c1d                	sub	s0,s0,a5
ffffffffc0202e18:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202e1c:	00c45593          	srli	a1,s0,0xc
ffffffffc0202e20:	9532                	add	a0,a0,a2
ffffffffc0202e22:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202e24:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202e28:	b4c1                	j	ffffffffc02028e8 <pmm_init+0x102>
        intr_disable();
ffffffffc0202e2a:	b8bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e2e:	000b3783          	ld	a5,0(s6)
ffffffffc0202e32:	779c                	ld	a5,40(a5)
ffffffffc0202e34:	9782                	jalr	a5
ffffffffc0202e36:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202e38:	b77fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e3c:	bb79                	j	ffffffffc0202bda <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202e3e:	b77fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e42:	000b3783          	ld	a5,0(s6)
ffffffffc0202e46:	779c                	ld	a5,40(a5)
ffffffffc0202e48:	9782                	jalr	a5
ffffffffc0202e4a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e4c:	b63fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e50:	b39d                	j	ffffffffc0202bb6 <pmm_init+0x3d0>
ffffffffc0202e52:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e54:	b61fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e58:	000b3783          	ld	a5,0(s6)
ffffffffc0202e5c:	6522                	ld	a0,8(sp)
ffffffffc0202e5e:	4585                	li	a1,1
ffffffffc0202e60:	739c                	ld	a5,32(a5)
ffffffffc0202e62:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e64:	b4bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e68:	b33d                	j	ffffffffc0202b96 <pmm_init+0x3b0>
ffffffffc0202e6a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e6c:	b49fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e70:	000b3783          	ld	a5,0(s6)
ffffffffc0202e74:	6522                	ld	a0,8(sp)
ffffffffc0202e76:	4585                	li	a1,1
ffffffffc0202e78:	739c                	ld	a5,32(a5)
ffffffffc0202e7a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e7c:	b33fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e80:	b1dd                	j	ffffffffc0202b66 <pmm_init+0x380>
        intr_disable();
ffffffffc0202e82:	b33fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e86:	000b3783          	ld	a5,0(s6)
ffffffffc0202e8a:	4505                	li	a0,1
ffffffffc0202e8c:	6f9c                	ld	a5,24(a5)
ffffffffc0202e8e:	9782                	jalr	a5
ffffffffc0202e90:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e92:	b1dfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e96:	b36d                	j	ffffffffc0202c40 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202e98:	b1dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e9c:	000b3783          	ld	a5,0(s6)
ffffffffc0202ea0:	779c                	ld	a5,40(a5)
ffffffffc0202ea2:	9782                	jalr	a5
ffffffffc0202ea4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202ea6:	b09fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202eaa:	bdf9                	j	ffffffffc0202d88 <pmm_init+0x5a2>
ffffffffc0202eac:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202eae:	b07fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202eb2:	000b3783          	ld	a5,0(s6)
ffffffffc0202eb6:	6522                	ld	a0,8(sp)
ffffffffc0202eb8:	4585                	li	a1,1
ffffffffc0202eba:	739c                	ld	a5,32(a5)
ffffffffc0202ebc:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ebe:	af1fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ec2:	b55d                	j	ffffffffc0202d68 <pmm_init+0x582>
ffffffffc0202ec4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ec6:	aeffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202eca:	000b3783          	ld	a5,0(s6)
ffffffffc0202ece:	6522                	ld	a0,8(sp)
ffffffffc0202ed0:	4585                	li	a1,1
ffffffffc0202ed2:	739c                	ld	a5,32(a5)
ffffffffc0202ed4:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ed6:	ad9fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202eda:	bdb9                	j	ffffffffc0202d38 <pmm_init+0x552>
        intr_disable();
ffffffffc0202edc:	ad9fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202ee0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ee4:	4585                	li	a1,1
ffffffffc0202ee6:	8552                	mv	a0,s4
ffffffffc0202ee8:	739c                	ld	a5,32(a5)
ffffffffc0202eea:	9782                	jalr	a5
        intr_enable();
ffffffffc0202eec:	ac3fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ef0:	bd29                	j	ffffffffc0202d0a <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ef2:	86a2                	mv	a3,s0
ffffffffc0202ef4:	00004617          	auipc	a2,0x4
ffffffffc0202ef8:	88c60613          	addi	a2,a2,-1908 # ffffffffc0206780 <default_pmm_manager+0x38>
ffffffffc0202efc:	24300593          	li	a1,579
ffffffffc0202f00:	00004517          	auipc	a0,0x4
ffffffffc0202f04:	99850513          	addi	a0,a0,-1640 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0202f08:	d86fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202f0c:	00004697          	auipc	a3,0x4
ffffffffc0202f10:	dfc68693          	addi	a3,a3,-516 # ffffffffc0206d08 <default_pmm_manager+0x5c0>
ffffffffc0202f14:	00003617          	auipc	a2,0x3
ffffffffc0202f18:	48460613          	addi	a2,a2,1156 # ffffffffc0206398 <commands+0x888>
ffffffffc0202f1c:	24400593          	li	a1,580
ffffffffc0202f20:	00004517          	auipc	a0,0x4
ffffffffc0202f24:	97850513          	addi	a0,a0,-1672 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0202f28:	d66fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202f2c:	00004697          	auipc	a3,0x4
ffffffffc0202f30:	d9c68693          	addi	a3,a3,-612 # ffffffffc0206cc8 <default_pmm_manager+0x580>
ffffffffc0202f34:	00003617          	auipc	a2,0x3
ffffffffc0202f38:	46460613          	addi	a2,a2,1124 # ffffffffc0206398 <commands+0x888>
ffffffffc0202f3c:	24300593          	li	a1,579
ffffffffc0202f40:	00004517          	auipc	a0,0x4
ffffffffc0202f44:	95850513          	addi	a0,a0,-1704 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0202f48:	d46fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202f4c:	fc5fe0ef          	jal	ra,ffffffffc0201f10 <pa2page.part.0>
ffffffffc0202f50:	fddfe0ef          	jal	ra,ffffffffc0201f2c <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202f54:	00004697          	auipc	a3,0x4
ffffffffc0202f58:	b6c68693          	addi	a3,a3,-1172 # ffffffffc0206ac0 <default_pmm_manager+0x378>
ffffffffc0202f5c:	00003617          	auipc	a2,0x3
ffffffffc0202f60:	43c60613          	addi	a2,a2,1084 # ffffffffc0206398 <commands+0x888>
ffffffffc0202f64:	21300593          	li	a1,531
ffffffffc0202f68:	00004517          	auipc	a0,0x4
ffffffffc0202f6c:	93050513          	addi	a0,a0,-1744 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0202f70:	d1efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202f74:	00004697          	auipc	a3,0x4
ffffffffc0202f78:	a8c68693          	addi	a3,a3,-1396 # ffffffffc0206a00 <default_pmm_manager+0x2b8>
ffffffffc0202f7c:	00003617          	auipc	a2,0x3
ffffffffc0202f80:	41c60613          	addi	a2,a2,1052 # ffffffffc0206398 <commands+0x888>
ffffffffc0202f84:	20600593          	li	a1,518
ffffffffc0202f88:	00004517          	auipc	a0,0x4
ffffffffc0202f8c:	91050513          	addi	a0,a0,-1776 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0202f90:	cfefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f94:	00004697          	auipc	a3,0x4
ffffffffc0202f98:	a2c68693          	addi	a3,a3,-1492 # ffffffffc02069c0 <default_pmm_manager+0x278>
ffffffffc0202f9c:	00003617          	auipc	a2,0x3
ffffffffc0202fa0:	3fc60613          	addi	a2,a2,1020 # ffffffffc0206398 <commands+0x888>
ffffffffc0202fa4:	20500593          	li	a1,517
ffffffffc0202fa8:	00004517          	auipc	a0,0x4
ffffffffc0202fac:	8f050513          	addi	a0,a0,-1808 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0202fb0:	cdefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202fb4:	00004697          	auipc	a3,0x4
ffffffffc0202fb8:	9ec68693          	addi	a3,a3,-1556 # ffffffffc02069a0 <default_pmm_manager+0x258>
ffffffffc0202fbc:	00003617          	auipc	a2,0x3
ffffffffc0202fc0:	3dc60613          	addi	a2,a2,988 # ffffffffc0206398 <commands+0x888>
ffffffffc0202fc4:	20400593          	li	a1,516
ffffffffc0202fc8:	00004517          	auipc	a0,0x4
ffffffffc0202fcc:	8d050513          	addi	a0,a0,-1840 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0202fd0:	cbefd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202fd4:	00003617          	auipc	a2,0x3
ffffffffc0202fd8:	7ac60613          	addi	a2,a2,1964 # ffffffffc0206780 <default_pmm_manager+0x38>
ffffffffc0202fdc:	07100593          	li	a1,113
ffffffffc0202fe0:	00003517          	auipc	a0,0x3
ffffffffc0202fe4:	7c850513          	addi	a0,a0,1992 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc0202fe8:	ca6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202fec:	00004697          	auipc	a3,0x4
ffffffffc0202ff0:	c6468693          	addi	a3,a3,-924 # ffffffffc0206c50 <default_pmm_manager+0x508>
ffffffffc0202ff4:	00003617          	auipc	a2,0x3
ffffffffc0202ff8:	3a460613          	addi	a2,a2,932 # ffffffffc0206398 <commands+0x888>
ffffffffc0202ffc:	22c00593          	li	a1,556
ffffffffc0203000:	00004517          	auipc	a0,0x4
ffffffffc0203004:	89850513          	addi	a0,a0,-1896 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203008:	c86fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020300c:	00004697          	auipc	a3,0x4
ffffffffc0203010:	bfc68693          	addi	a3,a3,-1028 # ffffffffc0206c08 <default_pmm_manager+0x4c0>
ffffffffc0203014:	00003617          	auipc	a2,0x3
ffffffffc0203018:	38460613          	addi	a2,a2,900 # ffffffffc0206398 <commands+0x888>
ffffffffc020301c:	22a00593          	li	a1,554
ffffffffc0203020:	00004517          	auipc	a0,0x4
ffffffffc0203024:	87850513          	addi	a0,a0,-1928 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203028:	c66fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020302c:	00004697          	auipc	a3,0x4
ffffffffc0203030:	c0c68693          	addi	a3,a3,-1012 # ffffffffc0206c38 <default_pmm_manager+0x4f0>
ffffffffc0203034:	00003617          	auipc	a2,0x3
ffffffffc0203038:	36460613          	addi	a2,a2,868 # ffffffffc0206398 <commands+0x888>
ffffffffc020303c:	22900593          	li	a1,553
ffffffffc0203040:	00004517          	auipc	a0,0x4
ffffffffc0203044:	85850513          	addi	a0,a0,-1960 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203048:	c46fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc020304c:	00004697          	auipc	a3,0x4
ffffffffc0203050:	cd468693          	addi	a3,a3,-812 # ffffffffc0206d20 <default_pmm_manager+0x5d8>
ffffffffc0203054:	00003617          	auipc	a2,0x3
ffffffffc0203058:	34460613          	addi	a2,a2,836 # ffffffffc0206398 <commands+0x888>
ffffffffc020305c:	24700593          	li	a1,583
ffffffffc0203060:	00004517          	auipc	a0,0x4
ffffffffc0203064:	83850513          	addi	a0,a0,-1992 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203068:	c26fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020306c:	00004697          	auipc	a3,0x4
ffffffffc0203070:	c1468693          	addi	a3,a3,-1004 # ffffffffc0206c80 <default_pmm_manager+0x538>
ffffffffc0203074:	00003617          	auipc	a2,0x3
ffffffffc0203078:	32460613          	addi	a2,a2,804 # ffffffffc0206398 <commands+0x888>
ffffffffc020307c:	23400593          	li	a1,564
ffffffffc0203080:	00004517          	auipc	a0,0x4
ffffffffc0203084:	81850513          	addi	a0,a0,-2024 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203088:	c06fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc020308c:	00004697          	auipc	a3,0x4
ffffffffc0203090:	cec68693          	addi	a3,a3,-788 # ffffffffc0206d78 <default_pmm_manager+0x630>
ffffffffc0203094:	00003617          	auipc	a2,0x3
ffffffffc0203098:	30460613          	addi	a2,a2,772 # ffffffffc0206398 <commands+0x888>
ffffffffc020309c:	24c00593          	li	a1,588
ffffffffc02030a0:	00003517          	auipc	a0,0x3
ffffffffc02030a4:	7f850513          	addi	a0,a0,2040 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02030a8:	be6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02030ac:	00004697          	auipc	a3,0x4
ffffffffc02030b0:	c8c68693          	addi	a3,a3,-884 # ffffffffc0206d38 <default_pmm_manager+0x5f0>
ffffffffc02030b4:	00003617          	auipc	a2,0x3
ffffffffc02030b8:	2e460613          	addi	a2,a2,740 # ffffffffc0206398 <commands+0x888>
ffffffffc02030bc:	24b00593          	li	a1,587
ffffffffc02030c0:	00003517          	auipc	a0,0x3
ffffffffc02030c4:	7d850513          	addi	a0,a0,2008 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02030c8:	bc6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030cc:	00004697          	auipc	a3,0x4
ffffffffc02030d0:	b3c68693          	addi	a3,a3,-1220 # ffffffffc0206c08 <default_pmm_manager+0x4c0>
ffffffffc02030d4:	00003617          	auipc	a2,0x3
ffffffffc02030d8:	2c460613          	addi	a2,a2,708 # ffffffffc0206398 <commands+0x888>
ffffffffc02030dc:	22600593          	li	a1,550
ffffffffc02030e0:	00003517          	auipc	a0,0x3
ffffffffc02030e4:	7b850513          	addi	a0,a0,1976 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02030e8:	ba6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02030ec:	00004697          	auipc	a3,0x4
ffffffffc02030f0:	9bc68693          	addi	a3,a3,-1604 # ffffffffc0206aa8 <default_pmm_manager+0x360>
ffffffffc02030f4:	00003617          	auipc	a2,0x3
ffffffffc02030f8:	2a460613          	addi	a2,a2,676 # ffffffffc0206398 <commands+0x888>
ffffffffc02030fc:	22500593          	li	a1,549
ffffffffc0203100:	00003517          	auipc	a0,0x3
ffffffffc0203104:	79850513          	addi	a0,a0,1944 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203108:	b86fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020310c:	00004697          	auipc	a3,0x4
ffffffffc0203110:	b1468693          	addi	a3,a3,-1260 # ffffffffc0206c20 <default_pmm_manager+0x4d8>
ffffffffc0203114:	00003617          	auipc	a2,0x3
ffffffffc0203118:	28460613          	addi	a2,a2,644 # ffffffffc0206398 <commands+0x888>
ffffffffc020311c:	22200593          	li	a1,546
ffffffffc0203120:	00003517          	auipc	a0,0x3
ffffffffc0203124:	77850513          	addi	a0,a0,1912 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203128:	b66fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020312c:	00004697          	auipc	a3,0x4
ffffffffc0203130:	96468693          	addi	a3,a3,-1692 # ffffffffc0206a90 <default_pmm_manager+0x348>
ffffffffc0203134:	00003617          	auipc	a2,0x3
ffffffffc0203138:	26460613          	addi	a2,a2,612 # ffffffffc0206398 <commands+0x888>
ffffffffc020313c:	22100593          	li	a1,545
ffffffffc0203140:	00003517          	auipc	a0,0x3
ffffffffc0203144:	75850513          	addi	a0,a0,1880 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203148:	b46fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020314c:	00004697          	auipc	a3,0x4
ffffffffc0203150:	9e468693          	addi	a3,a3,-1564 # ffffffffc0206b30 <default_pmm_manager+0x3e8>
ffffffffc0203154:	00003617          	auipc	a2,0x3
ffffffffc0203158:	24460613          	addi	a2,a2,580 # ffffffffc0206398 <commands+0x888>
ffffffffc020315c:	22000593          	li	a1,544
ffffffffc0203160:	00003517          	auipc	a0,0x3
ffffffffc0203164:	73850513          	addi	a0,a0,1848 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203168:	b26fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020316c:	00004697          	auipc	a3,0x4
ffffffffc0203170:	a9c68693          	addi	a3,a3,-1380 # ffffffffc0206c08 <default_pmm_manager+0x4c0>
ffffffffc0203174:	00003617          	auipc	a2,0x3
ffffffffc0203178:	22460613          	addi	a2,a2,548 # ffffffffc0206398 <commands+0x888>
ffffffffc020317c:	21f00593          	li	a1,543
ffffffffc0203180:	00003517          	auipc	a0,0x3
ffffffffc0203184:	71850513          	addi	a0,a0,1816 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203188:	b06fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc020318c:	00004697          	auipc	a3,0x4
ffffffffc0203190:	a6468693          	addi	a3,a3,-1436 # ffffffffc0206bf0 <default_pmm_manager+0x4a8>
ffffffffc0203194:	00003617          	auipc	a2,0x3
ffffffffc0203198:	20460613          	addi	a2,a2,516 # ffffffffc0206398 <commands+0x888>
ffffffffc020319c:	21e00593          	li	a1,542
ffffffffc02031a0:	00003517          	auipc	a0,0x3
ffffffffc02031a4:	6f850513          	addi	a0,a0,1784 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02031a8:	ae6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02031ac:	00004697          	auipc	a3,0x4
ffffffffc02031b0:	a1468693          	addi	a3,a3,-1516 # ffffffffc0206bc0 <default_pmm_manager+0x478>
ffffffffc02031b4:	00003617          	auipc	a2,0x3
ffffffffc02031b8:	1e460613          	addi	a2,a2,484 # ffffffffc0206398 <commands+0x888>
ffffffffc02031bc:	21d00593          	li	a1,541
ffffffffc02031c0:	00003517          	auipc	a0,0x3
ffffffffc02031c4:	6d850513          	addi	a0,a0,1752 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02031c8:	ac6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02031cc:	00004697          	auipc	a3,0x4
ffffffffc02031d0:	9dc68693          	addi	a3,a3,-1572 # ffffffffc0206ba8 <default_pmm_manager+0x460>
ffffffffc02031d4:	00003617          	auipc	a2,0x3
ffffffffc02031d8:	1c460613          	addi	a2,a2,452 # ffffffffc0206398 <commands+0x888>
ffffffffc02031dc:	21b00593          	li	a1,539
ffffffffc02031e0:	00003517          	auipc	a0,0x3
ffffffffc02031e4:	6b850513          	addi	a0,a0,1720 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02031e8:	aa6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02031ec:	00004697          	auipc	a3,0x4
ffffffffc02031f0:	99c68693          	addi	a3,a3,-1636 # ffffffffc0206b88 <default_pmm_manager+0x440>
ffffffffc02031f4:	00003617          	auipc	a2,0x3
ffffffffc02031f8:	1a460613          	addi	a2,a2,420 # ffffffffc0206398 <commands+0x888>
ffffffffc02031fc:	21a00593          	li	a1,538
ffffffffc0203200:	00003517          	auipc	a0,0x3
ffffffffc0203204:	69850513          	addi	a0,a0,1688 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203208:	a86fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc020320c:	00004697          	auipc	a3,0x4
ffffffffc0203210:	96c68693          	addi	a3,a3,-1684 # ffffffffc0206b78 <default_pmm_manager+0x430>
ffffffffc0203214:	00003617          	auipc	a2,0x3
ffffffffc0203218:	18460613          	addi	a2,a2,388 # ffffffffc0206398 <commands+0x888>
ffffffffc020321c:	21900593          	li	a1,537
ffffffffc0203220:	00003517          	auipc	a0,0x3
ffffffffc0203224:	67850513          	addi	a0,a0,1656 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203228:	a66fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc020322c:	00004697          	auipc	a3,0x4
ffffffffc0203230:	93c68693          	addi	a3,a3,-1732 # ffffffffc0206b68 <default_pmm_manager+0x420>
ffffffffc0203234:	00003617          	auipc	a2,0x3
ffffffffc0203238:	16460613          	addi	a2,a2,356 # ffffffffc0206398 <commands+0x888>
ffffffffc020323c:	21800593          	li	a1,536
ffffffffc0203240:	00003517          	auipc	a0,0x3
ffffffffc0203244:	65850513          	addi	a0,a0,1624 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203248:	a46fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc020324c:	00003617          	auipc	a2,0x3
ffffffffc0203250:	6bc60613          	addi	a2,a2,1724 # ffffffffc0206908 <default_pmm_manager+0x1c0>
ffffffffc0203254:	06600593          	li	a1,102
ffffffffc0203258:	00003517          	auipc	a0,0x3
ffffffffc020325c:	64050513          	addi	a0,a0,1600 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203260:	a2efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203264:	00004697          	auipc	a3,0x4
ffffffffc0203268:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0206c80 <default_pmm_manager+0x538>
ffffffffc020326c:	00003617          	auipc	a2,0x3
ffffffffc0203270:	12c60613          	addi	a2,a2,300 # ffffffffc0206398 <commands+0x888>
ffffffffc0203274:	25e00593          	li	a1,606
ffffffffc0203278:	00003517          	auipc	a0,0x3
ffffffffc020327c:	62050513          	addi	a0,a0,1568 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203280:	a0efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203284:	00004697          	auipc	a3,0x4
ffffffffc0203288:	8ac68693          	addi	a3,a3,-1876 # ffffffffc0206b30 <default_pmm_manager+0x3e8>
ffffffffc020328c:	00003617          	auipc	a2,0x3
ffffffffc0203290:	10c60613          	addi	a2,a2,268 # ffffffffc0206398 <commands+0x888>
ffffffffc0203294:	21700593          	li	a1,535
ffffffffc0203298:	00003517          	auipc	a0,0x3
ffffffffc020329c:	60050513          	addi	a0,a0,1536 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02032a0:	9eefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02032a4:	00004697          	auipc	a3,0x4
ffffffffc02032a8:	84c68693          	addi	a3,a3,-1972 # ffffffffc0206af0 <default_pmm_manager+0x3a8>
ffffffffc02032ac:	00003617          	auipc	a2,0x3
ffffffffc02032b0:	0ec60613          	addi	a2,a2,236 # ffffffffc0206398 <commands+0x888>
ffffffffc02032b4:	21600593          	li	a1,534
ffffffffc02032b8:	00003517          	auipc	a0,0x3
ffffffffc02032bc:	5e050513          	addi	a0,a0,1504 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02032c0:	9cefd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02032c4:	86d6                	mv	a3,s5
ffffffffc02032c6:	00003617          	auipc	a2,0x3
ffffffffc02032ca:	4ba60613          	addi	a2,a2,1210 # ffffffffc0206780 <default_pmm_manager+0x38>
ffffffffc02032ce:	21200593          	li	a1,530
ffffffffc02032d2:	00003517          	auipc	a0,0x3
ffffffffc02032d6:	5c650513          	addi	a0,a0,1478 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02032da:	9b4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02032de:	00003617          	auipc	a2,0x3
ffffffffc02032e2:	4a260613          	addi	a2,a2,1186 # ffffffffc0206780 <default_pmm_manager+0x38>
ffffffffc02032e6:	21100593          	li	a1,529
ffffffffc02032ea:	00003517          	auipc	a0,0x3
ffffffffc02032ee:	5ae50513          	addi	a0,a0,1454 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02032f2:	99cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02032f6:	00003697          	auipc	a3,0x3
ffffffffc02032fa:	7b268693          	addi	a3,a3,1970 # ffffffffc0206aa8 <default_pmm_manager+0x360>
ffffffffc02032fe:	00003617          	auipc	a2,0x3
ffffffffc0203302:	09a60613          	addi	a2,a2,154 # ffffffffc0206398 <commands+0x888>
ffffffffc0203306:	20f00593          	li	a1,527
ffffffffc020330a:	00003517          	auipc	a0,0x3
ffffffffc020330e:	58e50513          	addi	a0,a0,1422 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203312:	97cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203316:	00003697          	auipc	a3,0x3
ffffffffc020331a:	77a68693          	addi	a3,a3,1914 # ffffffffc0206a90 <default_pmm_manager+0x348>
ffffffffc020331e:	00003617          	auipc	a2,0x3
ffffffffc0203322:	07a60613          	addi	a2,a2,122 # ffffffffc0206398 <commands+0x888>
ffffffffc0203326:	20e00593          	li	a1,526
ffffffffc020332a:	00003517          	auipc	a0,0x3
ffffffffc020332e:	56e50513          	addi	a0,a0,1390 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203332:	95cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203336:	00004697          	auipc	a3,0x4
ffffffffc020333a:	b0a68693          	addi	a3,a3,-1270 # ffffffffc0206e40 <default_pmm_manager+0x6f8>
ffffffffc020333e:	00003617          	auipc	a2,0x3
ffffffffc0203342:	05a60613          	addi	a2,a2,90 # ffffffffc0206398 <commands+0x888>
ffffffffc0203346:	25500593          	li	a1,597
ffffffffc020334a:	00003517          	auipc	a0,0x3
ffffffffc020334e:	54e50513          	addi	a0,a0,1358 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203352:	93cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0203356:	00004697          	auipc	a3,0x4
ffffffffc020335a:	ab268693          	addi	a3,a3,-1358 # ffffffffc0206e08 <default_pmm_manager+0x6c0>
ffffffffc020335e:	00003617          	auipc	a2,0x3
ffffffffc0203362:	03a60613          	addi	a2,a2,58 # ffffffffc0206398 <commands+0x888>
ffffffffc0203366:	25200593          	li	a1,594
ffffffffc020336a:	00003517          	auipc	a0,0x3
ffffffffc020336e:	52e50513          	addi	a0,a0,1326 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203372:	91cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc0203376:	00004697          	auipc	a3,0x4
ffffffffc020337a:	a6268693          	addi	a3,a3,-1438 # ffffffffc0206dd8 <default_pmm_manager+0x690>
ffffffffc020337e:	00003617          	auipc	a2,0x3
ffffffffc0203382:	01a60613          	addi	a2,a2,26 # ffffffffc0206398 <commands+0x888>
ffffffffc0203386:	24e00593          	li	a1,590
ffffffffc020338a:	00003517          	auipc	a0,0x3
ffffffffc020338e:	50e50513          	addi	a0,a0,1294 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203392:	8fcfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203396:	00004697          	auipc	a3,0x4
ffffffffc020339a:	9fa68693          	addi	a3,a3,-1542 # ffffffffc0206d90 <default_pmm_manager+0x648>
ffffffffc020339e:	00003617          	auipc	a2,0x3
ffffffffc02033a2:	ffa60613          	addi	a2,a2,-6 # ffffffffc0206398 <commands+0x888>
ffffffffc02033a6:	24d00593          	li	a1,589
ffffffffc02033aa:	00003517          	auipc	a0,0x3
ffffffffc02033ae:	4ee50513          	addi	a0,a0,1262 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02033b2:	8dcfd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02033b6:	00003617          	auipc	a2,0x3
ffffffffc02033ba:	47260613          	addi	a2,a2,1138 # ffffffffc0206828 <default_pmm_manager+0xe0>
ffffffffc02033be:	0ca00593          	li	a1,202
ffffffffc02033c2:	00003517          	auipc	a0,0x3
ffffffffc02033c6:	4d650513          	addi	a0,a0,1238 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02033ca:	8c4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02033ce:	00003617          	auipc	a2,0x3
ffffffffc02033d2:	45a60613          	addi	a2,a2,1114 # ffffffffc0206828 <default_pmm_manager+0xe0>
ffffffffc02033d6:	08200593          	li	a1,130
ffffffffc02033da:	00003517          	auipc	a0,0x3
ffffffffc02033de:	4be50513          	addi	a0,a0,1214 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02033e2:	8acfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02033e6:	00003697          	auipc	a3,0x3
ffffffffc02033ea:	67a68693          	addi	a3,a3,1658 # ffffffffc0206a60 <default_pmm_manager+0x318>
ffffffffc02033ee:	00003617          	auipc	a2,0x3
ffffffffc02033f2:	faa60613          	addi	a2,a2,-86 # ffffffffc0206398 <commands+0x888>
ffffffffc02033f6:	20d00593          	li	a1,525
ffffffffc02033fa:	00003517          	auipc	a0,0x3
ffffffffc02033fe:	49e50513          	addi	a0,a0,1182 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203402:	88cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203406:	00003697          	auipc	a3,0x3
ffffffffc020340a:	62a68693          	addi	a3,a3,1578 # ffffffffc0206a30 <default_pmm_manager+0x2e8>
ffffffffc020340e:	00003617          	auipc	a2,0x3
ffffffffc0203412:	f8a60613          	addi	a2,a2,-118 # ffffffffc0206398 <commands+0x888>
ffffffffc0203416:	20a00593          	li	a1,522
ffffffffc020341a:	00003517          	auipc	a0,0x3
ffffffffc020341e:	47e50513          	addi	a0,a0,1150 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc0203422:	86cfd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203426 <copy_range>:
{
ffffffffc0203426:	711d                	addi	sp,sp,-96
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203428:	00d667b3          	or	a5,a2,a3
{
ffffffffc020342c:	ec86                	sd	ra,88(sp)
ffffffffc020342e:	e8a2                	sd	s0,80(sp)
ffffffffc0203430:	e4a6                	sd	s1,72(sp)
ffffffffc0203432:	e0ca                	sd	s2,64(sp)
ffffffffc0203434:	fc4e                	sd	s3,56(sp)
ffffffffc0203436:	f852                	sd	s4,48(sp)
ffffffffc0203438:	f456                	sd	s5,40(sp)
ffffffffc020343a:	f05a                	sd	s6,32(sp)
ffffffffc020343c:	ec5e                	sd	s7,24(sp)
ffffffffc020343e:	e862                	sd	s8,16(sp)
ffffffffc0203440:	e466                	sd	s9,8(sp)
ffffffffc0203442:	e06a                	sd	s10,0(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203444:	17d2                	slli	a5,a5,0x34
ffffffffc0203446:	14079863          	bnez	a5,ffffffffc0203596 <copy_range+0x170>
    assert(USER_ACCESS(start, end));
ffffffffc020344a:	002007b7          	lui	a5,0x200
ffffffffc020344e:	8432                	mv	s0,a2
ffffffffc0203450:	10f66763          	bltu	a2,a5,ffffffffc020355e <copy_range+0x138>
ffffffffc0203454:	8936                	mv	s2,a3
ffffffffc0203456:	10d67463          	bgeu	a2,a3,ffffffffc020355e <copy_range+0x138>
ffffffffc020345a:	4785                	li	a5,1
ffffffffc020345c:	07fe                	slli	a5,a5,0x1f
ffffffffc020345e:	10d7e063          	bltu	a5,a3,ffffffffc020355e <copy_range+0x138>
ffffffffc0203462:	8aaa                	mv	s5,a0
ffffffffc0203464:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc0203466:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc0203468:	000a7c17          	auipc	s8,0xa7
ffffffffc020346c:	258c0c13          	addi	s8,s8,600 # ffffffffc02aa6c0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203470:	000a7b97          	auipc	s7,0xa7
ffffffffc0203474:	258b8b93          	addi	s7,s7,600 # ffffffffc02aa6c8 <pages>
ffffffffc0203478:	fff80b37          	lui	s6,0xfff80
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020347c:	00200d37          	lui	s10,0x200
ffffffffc0203480:	ffe00cb7          	lui	s9,0xffe00
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203484:	4601                	li	a2,0
ffffffffc0203486:	85a2                	mv	a1,s0
ffffffffc0203488:	854e                	mv	a0,s3
ffffffffc020348a:	b77fe0ef          	jal	ra,ffffffffc0202000 <get_pte>
ffffffffc020348e:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc0203490:	c559                	beqz	a0,ffffffffc020351e <copy_range+0xf8>
        if (*ptep & PTE_V)
ffffffffc0203492:	611c                	ld	a5,0(a0)
ffffffffc0203494:	8b85                	andi	a5,a5,1
ffffffffc0203496:	e39d                	bnez	a5,ffffffffc02034bc <copy_range+0x96>
        start += PGSIZE;
ffffffffc0203498:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020349a:	ff2465e3          	bltu	s0,s2,ffffffffc0203484 <copy_range+0x5e>
    return 0;
ffffffffc020349e:	4501                	li	a0,0
}
ffffffffc02034a0:	60e6                	ld	ra,88(sp)
ffffffffc02034a2:	6446                	ld	s0,80(sp)
ffffffffc02034a4:	64a6                	ld	s1,72(sp)
ffffffffc02034a6:	6906                	ld	s2,64(sp)
ffffffffc02034a8:	79e2                	ld	s3,56(sp)
ffffffffc02034aa:	7a42                	ld	s4,48(sp)
ffffffffc02034ac:	7aa2                	ld	s5,40(sp)
ffffffffc02034ae:	7b02                	ld	s6,32(sp)
ffffffffc02034b0:	6be2                	ld	s7,24(sp)
ffffffffc02034b2:	6c42                	ld	s8,16(sp)
ffffffffc02034b4:	6ca2                	ld	s9,8(sp)
ffffffffc02034b6:	6d02                	ld	s10,0(sp)
ffffffffc02034b8:	6125                	addi	sp,sp,96
ffffffffc02034ba:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02034bc:	4605                	li	a2,1
ffffffffc02034be:	85a2                	mv	a1,s0
ffffffffc02034c0:	8556                	mv	a0,s5
ffffffffc02034c2:	b3ffe0ef          	jal	ra,ffffffffc0202000 <get_pte>
ffffffffc02034c6:	cd35                	beqz	a0,ffffffffc0203542 <copy_range+0x11c>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02034c8:	6098                	ld	a4,0(s1)
    if (!(pte & PTE_V))
ffffffffc02034ca:	00177793          	andi	a5,a4,1
ffffffffc02034ce:	0007069b          	sext.w	a3,a4
ffffffffc02034d2:	cbb5                	beqz	a5,ffffffffc0203546 <copy_range+0x120>
    if (PPN(pa) >= npage)
ffffffffc02034d4:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc02034d8:	00271793          	slli	a5,a4,0x2
ffffffffc02034dc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02034de:	0ac7f063          	bgeu	a5,a2,ffffffffc020357e <copy_range+0x158>
    return &pages[PPN(pa) - nbase];
ffffffffc02034e2:	000bb583          	ld	a1,0(s7)
ffffffffc02034e6:	97da                	add	a5,a5,s6
ffffffffc02034e8:	079a                	slli	a5,a5,0x6
            if (perm & PTE_W)
ffffffffc02034ea:	0046f613          	andi	a2,a3,4
ffffffffc02034ee:	95be                	add	a1,a1,a5
ffffffffc02034f0:	ee15                	bnez	a2,ffffffffc020352c <copy_range+0x106>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02034f2:	8afd                	andi	a3,a3,31
            int ret = page_insert(to, page, start, perm);
ffffffffc02034f4:	8622                	mv	a2,s0
ffffffffc02034f6:	8556                	mv	a0,s5
ffffffffc02034f8:	9f8ff0ef          	jal	ra,ffffffffc02026f0 <page_insert>
            assert(ret == 0);
ffffffffc02034fc:	dd51                	beqz	a0,ffffffffc0203498 <copy_range+0x72>
ffffffffc02034fe:	00004697          	auipc	a3,0x4
ffffffffc0203502:	98a68693          	addi	a3,a3,-1654 # ffffffffc0206e88 <default_pmm_manager+0x740>
ffffffffc0203506:	00003617          	auipc	a2,0x3
ffffffffc020350a:	e9260613          	addi	a2,a2,-366 # ffffffffc0206398 <commands+0x888>
ffffffffc020350e:	1a200593          	li	a1,418
ffffffffc0203512:	00003517          	auipc	a0,0x3
ffffffffc0203516:	38650513          	addi	a0,a0,902 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc020351a:	f75fc0ef          	jal	ra,ffffffffc020048e <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020351e:	946a                	add	s0,s0,s10
ffffffffc0203520:	01947433          	and	s0,s0,s9
    } while (start != 0 && start < end);
ffffffffc0203524:	dc2d                	beqz	s0,ffffffffc020349e <copy_range+0x78>
ffffffffc0203526:	f5246fe3          	bltu	s0,s2,ffffffffc0203484 <copy_range+0x5e>
ffffffffc020352a:	bf95                	j	ffffffffc020349e <copy_range+0x78>
                *ptep = (*ptep & ~PTE_W) | PTE_COW;
ffffffffc020352c:	efb77713          	andi	a4,a4,-261
ffffffffc0203530:	10076713          	ori	a4,a4,256
                perm = (perm & ~PTE_W) | PTE_COW;
ffffffffc0203534:	8aed                	andi	a3,a3,27
ffffffffc0203536:	1006e693          	ori	a3,a3,256
                *ptep = (*ptep & ~PTE_W) | PTE_COW;
ffffffffc020353a:	e098                	sd	a4,0(s1)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020353c:	12040073          	sfence.vma	s0
}
ffffffffc0203540:	bf55                	j	ffffffffc02034f4 <copy_range+0xce>
                return -E_NO_MEM;
ffffffffc0203542:	5571                	li	a0,-4
ffffffffc0203544:	bfb1                	j	ffffffffc02034a0 <copy_range+0x7a>
        panic("pte2page called with invalid pte");
ffffffffc0203546:	00003617          	auipc	a2,0x3
ffffffffc020354a:	32a60613          	addi	a2,a2,810 # ffffffffc0206870 <default_pmm_manager+0x128>
ffffffffc020354e:	07f00593          	li	a1,127
ffffffffc0203552:	00003517          	auipc	a0,0x3
ffffffffc0203556:	25650513          	addi	a0,a0,598 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc020355a:	f35fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020355e:	00003697          	auipc	a3,0x3
ffffffffc0203562:	37a68693          	addi	a3,a3,890 # ffffffffc02068d8 <default_pmm_manager+0x190>
ffffffffc0203566:	00003617          	auipc	a2,0x3
ffffffffc020356a:	e3260613          	addi	a2,a2,-462 # ffffffffc0206398 <commands+0x888>
ffffffffc020356e:	18300593          	li	a1,387
ffffffffc0203572:	00003517          	auipc	a0,0x3
ffffffffc0203576:	32650513          	addi	a0,a0,806 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc020357a:	f15fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020357e:	00003617          	auipc	a2,0x3
ffffffffc0203582:	2d260613          	addi	a2,a2,722 # ffffffffc0206850 <default_pmm_manager+0x108>
ffffffffc0203586:	06900593          	li	a1,105
ffffffffc020358a:	00003517          	auipc	a0,0x3
ffffffffc020358e:	21e50513          	addi	a0,a0,542 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc0203592:	efdfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203596:	00003697          	auipc	a3,0x3
ffffffffc020359a:	31268693          	addi	a3,a3,786 # ffffffffc02068a8 <default_pmm_manager+0x160>
ffffffffc020359e:	00003617          	auipc	a2,0x3
ffffffffc02035a2:	dfa60613          	addi	a2,a2,-518 # ffffffffc0206398 <commands+0x888>
ffffffffc02035a6:	18200593          	li	a1,386
ffffffffc02035aa:	00003517          	auipc	a0,0x3
ffffffffc02035ae:	2ee50513          	addi	a0,a0,750 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc02035b2:	eddfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02035b6 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02035b6:	12058073          	sfence.vma	a1
}
ffffffffc02035ba:	8082                	ret

ffffffffc02035bc <pgdir_alloc_page>:
{
ffffffffc02035bc:	7179                	addi	sp,sp,-48
ffffffffc02035be:	ec26                	sd	s1,24(sp)
ffffffffc02035c0:	e84a                	sd	s2,16(sp)
ffffffffc02035c2:	e052                	sd	s4,0(sp)
ffffffffc02035c4:	f406                	sd	ra,40(sp)
ffffffffc02035c6:	f022                	sd	s0,32(sp)
ffffffffc02035c8:	e44e                	sd	s3,8(sp)
ffffffffc02035ca:	8a2a                	mv	s4,a0
ffffffffc02035cc:	84ae                	mv	s1,a1
ffffffffc02035ce:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02035d0:	100027f3          	csrr	a5,sstatus
ffffffffc02035d4:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02035d6:	000a7997          	auipc	s3,0xa7
ffffffffc02035da:	0fa98993          	addi	s3,s3,250 # ffffffffc02aa6d0 <pmm_manager>
ffffffffc02035de:	ef8d                	bnez	a5,ffffffffc0203618 <pgdir_alloc_page+0x5c>
ffffffffc02035e0:	0009b783          	ld	a5,0(s3)
ffffffffc02035e4:	4505                	li	a0,1
ffffffffc02035e6:	6f9c                	ld	a5,24(a5)
ffffffffc02035e8:	9782                	jalr	a5
ffffffffc02035ea:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02035ec:	cc09                	beqz	s0,ffffffffc0203606 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02035ee:	86ca                	mv	a3,s2
ffffffffc02035f0:	8626                	mv	a2,s1
ffffffffc02035f2:	85a2                	mv	a1,s0
ffffffffc02035f4:	8552                	mv	a0,s4
ffffffffc02035f6:	8faff0ef          	jal	ra,ffffffffc02026f0 <page_insert>
ffffffffc02035fa:	e915                	bnez	a0,ffffffffc020362e <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc02035fc:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc02035fe:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc0203600:	4785                	li	a5,1
ffffffffc0203602:	04f71e63          	bne	a4,a5,ffffffffc020365e <pgdir_alloc_page+0xa2>
}
ffffffffc0203606:	70a2                	ld	ra,40(sp)
ffffffffc0203608:	8522                	mv	a0,s0
ffffffffc020360a:	7402                	ld	s0,32(sp)
ffffffffc020360c:	64e2                	ld	s1,24(sp)
ffffffffc020360e:	6942                	ld	s2,16(sp)
ffffffffc0203610:	69a2                	ld	s3,8(sp)
ffffffffc0203612:	6a02                	ld	s4,0(sp)
ffffffffc0203614:	6145                	addi	sp,sp,48
ffffffffc0203616:	8082                	ret
        intr_disable();
ffffffffc0203618:	b9cfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020361c:	0009b783          	ld	a5,0(s3)
ffffffffc0203620:	4505                	li	a0,1
ffffffffc0203622:	6f9c                	ld	a5,24(a5)
ffffffffc0203624:	9782                	jalr	a5
ffffffffc0203626:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203628:	b86fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020362c:	b7c1                	j	ffffffffc02035ec <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020362e:	100027f3          	csrr	a5,sstatus
ffffffffc0203632:	8b89                	andi	a5,a5,2
ffffffffc0203634:	eb89                	bnez	a5,ffffffffc0203646 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc0203636:	0009b783          	ld	a5,0(s3)
ffffffffc020363a:	8522                	mv	a0,s0
ffffffffc020363c:	4585                	li	a1,1
ffffffffc020363e:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203640:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203642:	9782                	jalr	a5
    if (flag)
ffffffffc0203644:	b7c9                	j	ffffffffc0203606 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0203646:	b6efd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020364a:	0009b783          	ld	a5,0(s3)
ffffffffc020364e:	8522                	mv	a0,s0
ffffffffc0203650:	4585                	li	a1,1
ffffffffc0203652:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203654:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203656:	9782                	jalr	a5
        intr_enable();
ffffffffc0203658:	b56fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020365c:	b76d                	j	ffffffffc0203606 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc020365e:	00004697          	auipc	a3,0x4
ffffffffc0203662:	83a68693          	addi	a3,a3,-1990 # ffffffffc0206e98 <default_pmm_manager+0x750>
ffffffffc0203666:	00003617          	auipc	a2,0x3
ffffffffc020366a:	d3260613          	addi	a2,a2,-718 # ffffffffc0206398 <commands+0x888>
ffffffffc020366e:	1eb00593          	li	a1,491
ffffffffc0203672:	00003517          	auipc	a0,0x3
ffffffffc0203676:	22650513          	addi	a0,a0,550 # ffffffffc0206898 <default_pmm_manager+0x150>
ffffffffc020367a:	e15fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020367e <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020367e:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203680:	00004697          	auipc	a3,0x4
ffffffffc0203684:	83068693          	addi	a3,a3,-2000 # ffffffffc0206eb0 <default_pmm_manager+0x768>
ffffffffc0203688:	00003617          	auipc	a2,0x3
ffffffffc020368c:	d1060613          	addi	a2,a2,-752 # ffffffffc0206398 <commands+0x888>
ffffffffc0203690:	08400593          	li	a1,132
ffffffffc0203694:	00004517          	auipc	a0,0x4
ffffffffc0203698:	83c50513          	addi	a0,a0,-1988 # ffffffffc0206ed0 <default_pmm_manager+0x788>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020369c:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc020369e:	df1fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02036a2 <mm_create>:
{
ffffffffc02036a2:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036a4:	04000513          	li	a0,64
{
ffffffffc02036a8:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036aa:	ec0fe0ef          	jal	ra,ffffffffc0201d6a <kmalloc>
    if (mm != NULL)
ffffffffc02036ae:	cd19                	beqz	a0,ffffffffc02036cc <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02036b0:	e508                	sd	a0,8(a0)
ffffffffc02036b2:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02036b4:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02036b8:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02036bc:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02036c0:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02036c4:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02036c8:	02053c23          	sd	zero,56(a0)
}
ffffffffc02036cc:	60a2                	ld	ra,8(sp)
ffffffffc02036ce:	0141                	addi	sp,sp,16
ffffffffc02036d0:	8082                	ret

ffffffffc02036d2 <find_vma>:
{
ffffffffc02036d2:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02036d4:	c505                	beqz	a0,ffffffffc02036fc <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02036d6:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02036d8:	c501                	beqz	a0,ffffffffc02036e0 <find_vma+0xe>
ffffffffc02036da:	651c                	ld	a5,8(a0)
ffffffffc02036dc:	02f5f263          	bgeu	a1,a5,ffffffffc0203700 <find_vma+0x2e>
    return listelm->next;
ffffffffc02036e0:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02036e2:	00f68d63          	beq	a3,a5,ffffffffc02036fc <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02036e6:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f4ed0>
ffffffffc02036ea:	00e5e663          	bltu	a1,a4,ffffffffc02036f6 <find_vma+0x24>
ffffffffc02036ee:	ff07b703          	ld	a4,-16(a5)
ffffffffc02036f2:	00e5ec63          	bltu	a1,a4,ffffffffc020370a <find_vma+0x38>
ffffffffc02036f6:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02036f8:	fef697e3          	bne	a3,a5,ffffffffc02036e6 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02036fc:	4501                	li	a0,0
}
ffffffffc02036fe:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203700:	691c                	ld	a5,16(a0)
ffffffffc0203702:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02036e0 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0203706:	ea88                	sd	a0,16(a3)
ffffffffc0203708:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc020370a:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc020370e:	ea88                	sd	a0,16(a3)
ffffffffc0203710:	8082                	ret

ffffffffc0203712 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203712:	6590                	ld	a2,8(a1)
ffffffffc0203714:	0105b803          	ld	a6,16(a1)
{
ffffffffc0203718:	1141                	addi	sp,sp,-16
ffffffffc020371a:	e406                	sd	ra,8(sp)
ffffffffc020371c:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020371e:	01066763          	bltu	a2,a6,ffffffffc020372c <insert_vma_struct+0x1a>
ffffffffc0203722:	a085                	j	ffffffffc0203782 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203724:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203728:	04e66863          	bltu	a2,a4,ffffffffc0203778 <insert_vma_struct+0x66>
ffffffffc020372c:	86be                	mv	a3,a5
ffffffffc020372e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203730:	fef51ae3          	bne	a0,a5,ffffffffc0203724 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203734:	02a68463          	beq	a3,a0,ffffffffc020375c <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203738:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020373c:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203740:	08e8f163          	bgeu	a7,a4,ffffffffc02037c2 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203744:	04e66f63          	bltu	a2,a4,ffffffffc02037a2 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203748:	00f50a63          	beq	a0,a5,ffffffffc020375c <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020374c:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203750:	05076963          	bltu	a4,a6,ffffffffc02037a2 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203754:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203758:	02c77363          	bgeu	a4,a2,ffffffffc020377e <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc020375c:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc020375e:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203760:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203764:	e390                	sd	a2,0(a5)
ffffffffc0203766:	e690                	sd	a2,8(a3)
}
ffffffffc0203768:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020376a:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020376c:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc020376e:	0017079b          	addiw	a5,a4,1
ffffffffc0203772:	d11c                	sw	a5,32(a0)
}
ffffffffc0203774:	0141                	addi	sp,sp,16
ffffffffc0203776:	8082                	ret
    if (le_prev != list)
ffffffffc0203778:	fca690e3          	bne	a3,a0,ffffffffc0203738 <insert_vma_struct+0x26>
ffffffffc020377c:	bfd1                	j	ffffffffc0203750 <insert_vma_struct+0x3e>
ffffffffc020377e:	f01ff0ef          	jal	ra,ffffffffc020367e <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203782:	00003697          	auipc	a3,0x3
ffffffffc0203786:	75e68693          	addi	a3,a3,1886 # ffffffffc0206ee0 <default_pmm_manager+0x798>
ffffffffc020378a:	00003617          	auipc	a2,0x3
ffffffffc020378e:	c0e60613          	addi	a2,a2,-1010 # ffffffffc0206398 <commands+0x888>
ffffffffc0203792:	08a00593          	li	a1,138
ffffffffc0203796:	00003517          	auipc	a0,0x3
ffffffffc020379a:	73a50513          	addi	a0,a0,1850 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc020379e:	cf1fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037a2:	00003697          	auipc	a3,0x3
ffffffffc02037a6:	77e68693          	addi	a3,a3,1918 # ffffffffc0206f20 <default_pmm_manager+0x7d8>
ffffffffc02037aa:	00003617          	auipc	a2,0x3
ffffffffc02037ae:	bee60613          	addi	a2,a2,-1042 # ffffffffc0206398 <commands+0x888>
ffffffffc02037b2:	08300593          	li	a1,131
ffffffffc02037b6:	00003517          	auipc	a0,0x3
ffffffffc02037ba:	71a50513          	addi	a0,a0,1818 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc02037be:	cd1fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02037c2:	00003697          	auipc	a3,0x3
ffffffffc02037c6:	73e68693          	addi	a3,a3,1854 # ffffffffc0206f00 <default_pmm_manager+0x7b8>
ffffffffc02037ca:	00003617          	auipc	a2,0x3
ffffffffc02037ce:	bce60613          	addi	a2,a2,-1074 # ffffffffc0206398 <commands+0x888>
ffffffffc02037d2:	08200593          	li	a1,130
ffffffffc02037d6:	00003517          	auipc	a0,0x3
ffffffffc02037da:	6fa50513          	addi	a0,a0,1786 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc02037de:	cb1fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02037e2 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02037e2:	591c                	lw	a5,48(a0)
{
ffffffffc02037e4:	1141                	addi	sp,sp,-16
ffffffffc02037e6:	e406                	sd	ra,8(sp)
ffffffffc02037e8:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02037ea:	e78d                	bnez	a5,ffffffffc0203814 <mm_destroy+0x32>
ffffffffc02037ec:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02037ee:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02037f0:	00a40c63          	beq	s0,a0,ffffffffc0203808 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02037f4:	6118                	ld	a4,0(a0)
ffffffffc02037f6:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02037f8:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02037fa:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02037fc:	e398                	sd	a4,0(a5)
ffffffffc02037fe:	e1cfe0ef          	jal	ra,ffffffffc0201e1a <kfree>
    return listelm->next;
ffffffffc0203802:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203804:	fea418e3          	bne	s0,a0,ffffffffc02037f4 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203808:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc020380a:	6402                	ld	s0,0(sp)
ffffffffc020380c:	60a2                	ld	ra,8(sp)
ffffffffc020380e:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203810:	e0afe06f          	j	ffffffffc0201e1a <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203814:	00003697          	auipc	a3,0x3
ffffffffc0203818:	72c68693          	addi	a3,a3,1836 # ffffffffc0206f40 <default_pmm_manager+0x7f8>
ffffffffc020381c:	00003617          	auipc	a2,0x3
ffffffffc0203820:	b7c60613          	addi	a2,a2,-1156 # ffffffffc0206398 <commands+0x888>
ffffffffc0203824:	0ae00593          	li	a1,174
ffffffffc0203828:	00003517          	auipc	a0,0x3
ffffffffc020382c:	6a850513          	addi	a0,a0,1704 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc0203830:	c5ffc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203834 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203834:	7139                	addi	sp,sp,-64
ffffffffc0203836:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203838:	6405                	lui	s0,0x1
ffffffffc020383a:	147d                	addi	s0,s0,-1
ffffffffc020383c:	77fd                	lui	a5,0xfffff
ffffffffc020383e:	9622                	add	a2,a2,s0
ffffffffc0203840:	962e                	add	a2,a2,a1
{
ffffffffc0203842:	f426                	sd	s1,40(sp)
ffffffffc0203844:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203846:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc020384a:	f04a                	sd	s2,32(sp)
ffffffffc020384c:	ec4e                	sd	s3,24(sp)
ffffffffc020384e:	e852                	sd	s4,16(sp)
ffffffffc0203850:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203852:	002005b7          	lui	a1,0x200
ffffffffc0203856:	00f67433          	and	s0,a2,a5
ffffffffc020385a:	06b4e363          	bltu	s1,a1,ffffffffc02038c0 <mm_map+0x8c>
ffffffffc020385e:	0684f163          	bgeu	s1,s0,ffffffffc02038c0 <mm_map+0x8c>
ffffffffc0203862:	4785                	li	a5,1
ffffffffc0203864:	07fe                	slli	a5,a5,0x1f
ffffffffc0203866:	0487ed63          	bltu	a5,s0,ffffffffc02038c0 <mm_map+0x8c>
ffffffffc020386a:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc020386c:	cd21                	beqz	a0,ffffffffc02038c4 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc020386e:	85a6                	mv	a1,s1
ffffffffc0203870:	8ab6                	mv	s5,a3
ffffffffc0203872:	8a3a                	mv	s4,a4
ffffffffc0203874:	e5fff0ef          	jal	ra,ffffffffc02036d2 <find_vma>
ffffffffc0203878:	c501                	beqz	a0,ffffffffc0203880 <mm_map+0x4c>
ffffffffc020387a:	651c                	ld	a5,8(a0)
ffffffffc020387c:	0487e263          	bltu	a5,s0,ffffffffc02038c0 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203880:	03000513          	li	a0,48
ffffffffc0203884:	ce6fe0ef          	jal	ra,ffffffffc0201d6a <kmalloc>
ffffffffc0203888:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc020388a:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc020388c:	02090163          	beqz	s2,ffffffffc02038ae <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203890:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203892:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0203896:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc020389a:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc020389e:	85ca                	mv	a1,s2
ffffffffc02038a0:	e73ff0ef          	jal	ra,ffffffffc0203712 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc02038a4:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc02038a6:	000a0463          	beqz	s4,ffffffffc02038ae <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02038aa:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>

out:
    return ret;
}
ffffffffc02038ae:	70e2                	ld	ra,56(sp)
ffffffffc02038b0:	7442                	ld	s0,48(sp)
ffffffffc02038b2:	74a2                	ld	s1,40(sp)
ffffffffc02038b4:	7902                	ld	s2,32(sp)
ffffffffc02038b6:	69e2                	ld	s3,24(sp)
ffffffffc02038b8:	6a42                	ld	s4,16(sp)
ffffffffc02038ba:	6aa2                	ld	s5,8(sp)
ffffffffc02038bc:	6121                	addi	sp,sp,64
ffffffffc02038be:	8082                	ret
        return -E_INVAL;
ffffffffc02038c0:	5575                	li	a0,-3
ffffffffc02038c2:	b7f5                	j	ffffffffc02038ae <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02038c4:	00003697          	auipc	a3,0x3
ffffffffc02038c8:	69468693          	addi	a3,a3,1684 # ffffffffc0206f58 <default_pmm_manager+0x810>
ffffffffc02038cc:	00003617          	auipc	a2,0x3
ffffffffc02038d0:	acc60613          	addi	a2,a2,-1332 # ffffffffc0206398 <commands+0x888>
ffffffffc02038d4:	0c300593          	li	a1,195
ffffffffc02038d8:	00003517          	auipc	a0,0x3
ffffffffc02038dc:	5f850513          	addi	a0,a0,1528 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc02038e0:	baffc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038e4 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02038e4:	7139                	addi	sp,sp,-64
ffffffffc02038e6:	fc06                	sd	ra,56(sp)
ffffffffc02038e8:	f822                	sd	s0,48(sp)
ffffffffc02038ea:	f426                	sd	s1,40(sp)
ffffffffc02038ec:	f04a                	sd	s2,32(sp)
ffffffffc02038ee:	ec4e                	sd	s3,24(sp)
ffffffffc02038f0:	e852                	sd	s4,16(sp)
ffffffffc02038f2:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02038f4:	c52d                	beqz	a0,ffffffffc020395e <dup_mmap+0x7a>
ffffffffc02038f6:	892a                	mv	s2,a0
ffffffffc02038f8:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02038fa:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02038fc:	e595                	bnez	a1,ffffffffc0203928 <dup_mmap+0x44>
ffffffffc02038fe:	a085                	j	ffffffffc020395e <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203900:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203902:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ef0>
        vma->vm_end = vm_end;
ffffffffc0203906:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc020390a:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc020390e:	e05ff0ef          	jal	ra,ffffffffc0203712 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203912:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0203916:	fe843603          	ld	a2,-24(s0)
ffffffffc020391a:	6c8c                	ld	a1,24(s1)
ffffffffc020391c:	01893503          	ld	a0,24(s2)
ffffffffc0203920:	4701                	li	a4,0
ffffffffc0203922:	b05ff0ef          	jal	ra,ffffffffc0203426 <copy_range>
ffffffffc0203926:	e105                	bnez	a0,ffffffffc0203946 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203928:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc020392a:	02848863          	beq	s1,s0,ffffffffc020395a <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020392e:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203932:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203936:	ff043a03          	ld	s4,-16(s0)
ffffffffc020393a:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020393e:	c2cfe0ef          	jal	ra,ffffffffc0201d6a <kmalloc>
ffffffffc0203942:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203944:	fd55                	bnez	a0,ffffffffc0203900 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203946:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203948:	70e2                	ld	ra,56(sp)
ffffffffc020394a:	7442                	ld	s0,48(sp)
ffffffffc020394c:	74a2                	ld	s1,40(sp)
ffffffffc020394e:	7902                	ld	s2,32(sp)
ffffffffc0203950:	69e2                	ld	s3,24(sp)
ffffffffc0203952:	6a42                	ld	s4,16(sp)
ffffffffc0203954:	6aa2                	ld	s5,8(sp)
ffffffffc0203956:	6121                	addi	sp,sp,64
ffffffffc0203958:	8082                	ret
    return 0;
ffffffffc020395a:	4501                	li	a0,0
ffffffffc020395c:	b7f5                	j	ffffffffc0203948 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc020395e:	00003697          	auipc	a3,0x3
ffffffffc0203962:	60a68693          	addi	a3,a3,1546 # ffffffffc0206f68 <default_pmm_manager+0x820>
ffffffffc0203966:	00003617          	auipc	a2,0x3
ffffffffc020396a:	a3260613          	addi	a2,a2,-1486 # ffffffffc0206398 <commands+0x888>
ffffffffc020396e:	0df00593          	li	a1,223
ffffffffc0203972:	00003517          	auipc	a0,0x3
ffffffffc0203976:	55e50513          	addi	a0,a0,1374 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc020397a:	b15fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020397e <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc020397e:	1101                	addi	sp,sp,-32
ffffffffc0203980:	ec06                	sd	ra,24(sp)
ffffffffc0203982:	e822                	sd	s0,16(sp)
ffffffffc0203984:	e426                	sd	s1,8(sp)
ffffffffc0203986:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203988:	c531                	beqz	a0,ffffffffc02039d4 <exit_mmap+0x56>
ffffffffc020398a:	591c                	lw	a5,48(a0)
ffffffffc020398c:	84aa                	mv	s1,a0
ffffffffc020398e:	e3b9                	bnez	a5,ffffffffc02039d4 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203990:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203992:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203996:	02850663          	beq	a0,s0,ffffffffc02039c2 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc020399a:	ff043603          	ld	a2,-16(s0)
ffffffffc020399e:	fe843583          	ld	a1,-24(s0)
ffffffffc02039a2:	854a                	mv	a0,s2
ffffffffc02039a4:	8d9fe0ef          	jal	ra,ffffffffc020227c <unmap_range>
ffffffffc02039a8:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039aa:	fe8498e3          	bne	s1,s0,ffffffffc020399a <exit_mmap+0x1c>
ffffffffc02039ae:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02039b0:	00848c63          	beq	s1,s0,ffffffffc02039c8 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02039b4:	ff043603          	ld	a2,-16(s0)
ffffffffc02039b8:	fe843583          	ld	a1,-24(s0)
ffffffffc02039bc:	854a                	mv	a0,s2
ffffffffc02039be:	a05fe0ef          	jal	ra,ffffffffc02023c2 <exit_range>
ffffffffc02039c2:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039c4:	fe8498e3          	bne	s1,s0,ffffffffc02039b4 <exit_mmap+0x36>
    }
}
ffffffffc02039c8:	60e2                	ld	ra,24(sp)
ffffffffc02039ca:	6442                	ld	s0,16(sp)
ffffffffc02039cc:	64a2                	ld	s1,8(sp)
ffffffffc02039ce:	6902                	ld	s2,0(sp)
ffffffffc02039d0:	6105                	addi	sp,sp,32
ffffffffc02039d2:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02039d4:	00003697          	auipc	a3,0x3
ffffffffc02039d8:	5b468693          	addi	a3,a3,1460 # ffffffffc0206f88 <default_pmm_manager+0x840>
ffffffffc02039dc:	00003617          	auipc	a2,0x3
ffffffffc02039e0:	9bc60613          	addi	a2,a2,-1604 # ffffffffc0206398 <commands+0x888>
ffffffffc02039e4:	0f800593          	li	a1,248
ffffffffc02039e8:	00003517          	auipc	a0,0x3
ffffffffc02039ec:	4e850513          	addi	a0,a0,1256 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc02039f0:	a9ffc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039f4 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc02039f4:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02039f6:	04000513          	li	a0,64
{
ffffffffc02039fa:	fc06                	sd	ra,56(sp)
ffffffffc02039fc:	f822                	sd	s0,48(sp)
ffffffffc02039fe:	f426                	sd	s1,40(sp)
ffffffffc0203a00:	f04a                	sd	s2,32(sp)
ffffffffc0203a02:	ec4e                	sd	s3,24(sp)
ffffffffc0203a04:	e852                	sd	s4,16(sp)
ffffffffc0203a06:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a08:	b62fe0ef          	jal	ra,ffffffffc0201d6a <kmalloc>
    if (mm != NULL)
ffffffffc0203a0c:	2e050663          	beqz	a0,ffffffffc0203cf8 <vmm_init+0x304>
ffffffffc0203a10:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203a12:	e508                	sd	a0,8(a0)
ffffffffc0203a14:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203a16:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203a1a:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203a1e:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203a22:	02053423          	sd	zero,40(a0)
ffffffffc0203a26:	02052823          	sw	zero,48(a0)
ffffffffc0203a2a:	02053c23          	sd	zero,56(a0)
ffffffffc0203a2e:	03200413          	li	s0,50
ffffffffc0203a32:	a811                	j	ffffffffc0203a46 <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203a34:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a36:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a38:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203a3c:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a3e:	8526                	mv	a0,s1
ffffffffc0203a40:	cd3ff0ef          	jal	ra,ffffffffc0203712 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203a44:	c80d                	beqz	s0,ffffffffc0203a76 <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a46:	03000513          	li	a0,48
ffffffffc0203a4a:	b20fe0ef          	jal	ra,ffffffffc0201d6a <kmalloc>
ffffffffc0203a4e:	85aa                	mv	a1,a0
ffffffffc0203a50:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203a54:	f165                	bnez	a0,ffffffffc0203a34 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203a56:	00003697          	auipc	a3,0x3
ffffffffc0203a5a:	6ca68693          	addi	a3,a3,1738 # ffffffffc0207120 <default_pmm_manager+0x9d8>
ffffffffc0203a5e:	00003617          	auipc	a2,0x3
ffffffffc0203a62:	93a60613          	addi	a2,a2,-1734 # ffffffffc0206398 <commands+0x888>
ffffffffc0203a66:	13c00593          	li	a1,316
ffffffffc0203a6a:	00003517          	auipc	a0,0x3
ffffffffc0203a6e:	46650513          	addi	a0,a0,1126 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc0203a72:	a1dfc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203a76:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a7a:	1f900913          	li	s2,505
ffffffffc0203a7e:	a819                	j	ffffffffc0203a94 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203a80:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a82:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a84:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a88:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a8a:	8526                	mv	a0,s1
ffffffffc0203a8c:	c87ff0ef          	jal	ra,ffffffffc0203712 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a90:	03240a63          	beq	s0,s2,ffffffffc0203ac4 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a94:	03000513          	li	a0,48
ffffffffc0203a98:	ad2fe0ef          	jal	ra,ffffffffc0201d6a <kmalloc>
ffffffffc0203a9c:	85aa                	mv	a1,a0
ffffffffc0203a9e:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203aa2:	fd79                	bnez	a0,ffffffffc0203a80 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203aa4:	00003697          	auipc	a3,0x3
ffffffffc0203aa8:	67c68693          	addi	a3,a3,1660 # ffffffffc0207120 <default_pmm_manager+0x9d8>
ffffffffc0203aac:	00003617          	auipc	a2,0x3
ffffffffc0203ab0:	8ec60613          	addi	a2,a2,-1812 # ffffffffc0206398 <commands+0x888>
ffffffffc0203ab4:	14300593          	li	a1,323
ffffffffc0203ab8:	00003517          	auipc	a0,0x3
ffffffffc0203abc:	41850513          	addi	a0,a0,1048 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc0203ac0:	9cffc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203ac4:	649c                	ld	a5,8(s1)
ffffffffc0203ac6:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203ac8:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203acc:	16f48663          	beq	s1,a5,ffffffffc0203c38 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203ad0:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd548e4>
ffffffffc0203ad4:	ffe70693          	addi	a3,a4,-2 # ffe <_binary_obj___user_faultread_out_size-0x8baa>
ffffffffc0203ad8:	10d61063          	bne	a2,a3,ffffffffc0203bd8 <vmm_init+0x1e4>
ffffffffc0203adc:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203ae0:	0ed71c63          	bne	a4,a3,ffffffffc0203bd8 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203ae4:	0715                	addi	a4,a4,5
ffffffffc0203ae6:	679c                	ld	a5,8(a5)
ffffffffc0203ae8:	feb712e3          	bne	a4,a1,ffffffffc0203acc <vmm_init+0xd8>
ffffffffc0203aec:	4a1d                	li	s4,7
ffffffffc0203aee:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203af0:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203af4:	85a2                	mv	a1,s0
ffffffffc0203af6:	8526                	mv	a0,s1
ffffffffc0203af8:	bdbff0ef          	jal	ra,ffffffffc02036d2 <find_vma>
ffffffffc0203afc:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203afe:	16050d63          	beqz	a0,ffffffffc0203c78 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203b02:	00140593          	addi	a1,s0,1
ffffffffc0203b06:	8526                	mv	a0,s1
ffffffffc0203b08:	bcbff0ef          	jal	ra,ffffffffc02036d2 <find_vma>
ffffffffc0203b0c:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b0e:	14050563          	beqz	a0,ffffffffc0203c58 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203b12:	85d2                	mv	a1,s4
ffffffffc0203b14:	8526                	mv	a0,s1
ffffffffc0203b16:	bbdff0ef          	jal	ra,ffffffffc02036d2 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b1a:	16051f63          	bnez	a0,ffffffffc0203c98 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203b1e:	00340593          	addi	a1,s0,3
ffffffffc0203b22:	8526                	mv	a0,s1
ffffffffc0203b24:	bafff0ef          	jal	ra,ffffffffc02036d2 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b28:	1a051863          	bnez	a0,ffffffffc0203cd8 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203b2c:	00440593          	addi	a1,s0,4
ffffffffc0203b30:	8526                	mv	a0,s1
ffffffffc0203b32:	ba1ff0ef          	jal	ra,ffffffffc02036d2 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203b36:	18051163          	bnez	a0,ffffffffc0203cb8 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b3a:	00893783          	ld	a5,8(s2)
ffffffffc0203b3e:	0a879d63          	bne	a5,s0,ffffffffc0203bf8 <vmm_init+0x204>
ffffffffc0203b42:	01093783          	ld	a5,16(s2)
ffffffffc0203b46:	0b479963          	bne	a5,s4,ffffffffc0203bf8 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b4a:	0089b783          	ld	a5,8(s3)
ffffffffc0203b4e:	0c879563          	bne	a5,s0,ffffffffc0203c18 <vmm_init+0x224>
ffffffffc0203b52:	0109b783          	ld	a5,16(s3)
ffffffffc0203b56:	0d479163          	bne	a5,s4,ffffffffc0203c18 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b5a:	0415                	addi	s0,s0,5
ffffffffc0203b5c:	0a15                	addi	s4,s4,5
ffffffffc0203b5e:	f9541be3          	bne	s0,s5,ffffffffc0203af4 <vmm_init+0x100>
ffffffffc0203b62:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203b64:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203b66:	85a2                	mv	a1,s0
ffffffffc0203b68:	8526                	mv	a0,s1
ffffffffc0203b6a:	b69ff0ef          	jal	ra,ffffffffc02036d2 <find_vma>
ffffffffc0203b6e:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203b72:	c90d                	beqz	a0,ffffffffc0203ba4 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203b74:	6914                	ld	a3,16(a0)
ffffffffc0203b76:	6510                	ld	a2,8(a0)
ffffffffc0203b78:	00003517          	auipc	a0,0x3
ffffffffc0203b7c:	53050513          	addi	a0,a0,1328 # ffffffffc02070a8 <default_pmm_manager+0x960>
ffffffffc0203b80:	e14fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203b84:	00003697          	auipc	a3,0x3
ffffffffc0203b88:	54c68693          	addi	a3,a3,1356 # ffffffffc02070d0 <default_pmm_manager+0x988>
ffffffffc0203b8c:	00003617          	auipc	a2,0x3
ffffffffc0203b90:	80c60613          	addi	a2,a2,-2036 # ffffffffc0206398 <commands+0x888>
ffffffffc0203b94:	16900593          	li	a1,361
ffffffffc0203b98:	00003517          	auipc	a0,0x3
ffffffffc0203b9c:	33850513          	addi	a0,a0,824 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc0203ba0:	8effc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203ba4:	147d                	addi	s0,s0,-1
ffffffffc0203ba6:	fd2410e3          	bne	s0,s2,ffffffffc0203b66 <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203baa:	8526                	mv	a0,s1
ffffffffc0203bac:	c37ff0ef          	jal	ra,ffffffffc02037e2 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203bb0:	00003517          	auipc	a0,0x3
ffffffffc0203bb4:	53850513          	addi	a0,a0,1336 # ffffffffc02070e8 <default_pmm_manager+0x9a0>
ffffffffc0203bb8:	ddcfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203bbc:	7442                	ld	s0,48(sp)
ffffffffc0203bbe:	70e2                	ld	ra,56(sp)
ffffffffc0203bc0:	74a2                	ld	s1,40(sp)
ffffffffc0203bc2:	7902                	ld	s2,32(sp)
ffffffffc0203bc4:	69e2                	ld	s3,24(sp)
ffffffffc0203bc6:	6a42                	ld	s4,16(sp)
ffffffffc0203bc8:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bca:	00003517          	auipc	a0,0x3
ffffffffc0203bce:	53e50513          	addi	a0,a0,1342 # ffffffffc0207108 <default_pmm_manager+0x9c0>
}
ffffffffc0203bd2:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bd4:	dc0fc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203bd8:	00003697          	auipc	a3,0x3
ffffffffc0203bdc:	3e868693          	addi	a3,a3,1000 # ffffffffc0206fc0 <default_pmm_manager+0x878>
ffffffffc0203be0:	00002617          	auipc	a2,0x2
ffffffffc0203be4:	7b860613          	addi	a2,a2,1976 # ffffffffc0206398 <commands+0x888>
ffffffffc0203be8:	14d00593          	li	a1,333
ffffffffc0203bec:	00003517          	auipc	a0,0x3
ffffffffc0203bf0:	2e450513          	addi	a0,a0,740 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc0203bf4:	89bfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203bf8:	00003697          	auipc	a3,0x3
ffffffffc0203bfc:	45068693          	addi	a3,a3,1104 # ffffffffc0207048 <default_pmm_manager+0x900>
ffffffffc0203c00:	00002617          	auipc	a2,0x2
ffffffffc0203c04:	79860613          	addi	a2,a2,1944 # ffffffffc0206398 <commands+0x888>
ffffffffc0203c08:	15e00593          	li	a1,350
ffffffffc0203c0c:	00003517          	auipc	a0,0x3
ffffffffc0203c10:	2c450513          	addi	a0,a0,708 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc0203c14:	87bfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c18:	00003697          	auipc	a3,0x3
ffffffffc0203c1c:	46068693          	addi	a3,a3,1120 # ffffffffc0207078 <default_pmm_manager+0x930>
ffffffffc0203c20:	00002617          	auipc	a2,0x2
ffffffffc0203c24:	77860613          	addi	a2,a2,1912 # ffffffffc0206398 <commands+0x888>
ffffffffc0203c28:	15f00593          	li	a1,351
ffffffffc0203c2c:	00003517          	auipc	a0,0x3
ffffffffc0203c30:	2a450513          	addi	a0,a0,676 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc0203c34:	85bfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203c38:	00003697          	auipc	a3,0x3
ffffffffc0203c3c:	37068693          	addi	a3,a3,880 # ffffffffc0206fa8 <default_pmm_manager+0x860>
ffffffffc0203c40:	00002617          	auipc	a2,0x2
ffffffffc0203c44:	75860613          	addi	a2,a2,1880 # ffffffffc0206398 <commands+0x888>
ffffffffc0203c48:	14b00593          	li	a1,331
ffffffffc0203c4c:	00003517          	auipc	a0,0x3
ffffffffc0203c50:	28450513          	addi	a0,a0,644 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc0203c54:	83bfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203c58:	00003697          	auipc	a3,0x3
ffffffffc0203c5c:	3b068693          	addi	a3,a3,944 # ffffffffc0207008 <default_pmm_manager+0x8c0>
ffffffffc0203c60:	00002617          	auipc	a2,0x2
ffffffffc0203c64:	73860613          	addi	a2,a2,1848 # ffffffffc0206398 <commands+0x888>
ffffffffc0203c68:	15600593          	li	a1,342
ffffffffc0203c6c:	00003517          	auipc	a0,0x3
ffffffffc0203c70:	26450513          	addi	a0,a0,612 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc0203c74:	81bfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203c78:	00003697          	auipc	a3,0x3
ffffffffc0203c7c:	38068693          	addi	a3,a3,896 # ffffffffc0206ff8 <default_pmm_manager+0x8b0>
ffffffffc0203c80:	00002617          	auipc	a2,0x2
ffffffffc0203c84:	71860613          	addi	a2,a2,1816 # ffffffffc0206398 <commands+0x888>
ffffffffc0203c88:	15400593          	li	a1,340
ffffffffc0203c8c:	00003517          	auipc	a0,0x3
ffffffffc0203c90:	24450513          	addi	a0,a0,580 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc0203c94:	ffafc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203c98:	00003697          	auipc	a3,0x3
ffffffffc0203c9c:	38068693          	addi	a3,a3,896 # ffffffffc0207018 <default_pmm_manager+0x8d0>
ffffffffc0203ca0:	00002617          	auipc	a2,0x2
ffffffffc0203ca4:	6f860613          	addi	a2,a2,1784 # ffffffffc0206398 <commands+0x888>
ffffffffc0203ca8:	15800593          	li	a1,344
ffffffffc0203cac:	00003517          	auipc	a0,0x3
ffffffffc0203cb0:	22450513          	addi	a0,a0,548 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc0203cb4:	fdafc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203cb8:	00003697          	auipc	a3,0x3
ffffffffc0203cbc:	38068693          	addi	a3,a3,896 # ffffffffc0207038 <default_pmm_manager+0x8f0>
ffffffffc0203cc0:	00002617          	auipc	a2,0x2
ffffffffc0203cc4:	6d860613          	addi	a2,a2,1752 # ffffffffc0206398 <commands+0x888>
ffffffffc0203cc8:	15c00593          	li	a1,348
ffffffffc0203ccc:	00003517          	auipc	a0,0x3
ffffffffc0203cd0:	20450513          	addi	a0,a0,516 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc0203cd4:	fbafc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203cd8:	00003697          	auipc	a3,0x3
ffffffffc0203cdc:	35068693          	addi	a3,a3,848 # ffffffffc0207028 <default_pmm_manager+0x8e0>
ffffffffc0203ce0:	00002617          	auipc	a2,0x2
ffffffffc0203ce4:	6b860613          	addi	a2,a2,1720 # ffffffffc0206398 <commands+0x888>
ffffffffc0203ce8:	15a00593          	li	a1,346
ffffffffc0203cec:	00003517          	auipc	a0,0x3
ffffffffc0203cf0:	1e450513          	addi	a0,a0,484 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc0203cf4:	f9afc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203cf8:	00003697          	auipc	a3,0x3
ffffffffc0203cfc:	26068693          	addi	a3,a3,608 # ffffffffc0206f58 <default_pmm_manager+0x810>
ffffffffc0203d00:	00002617          	auipc	a2,0x2
ffffffffc0203d04:	69860613          	addi	a2,a2,1688 # ffffffffc0206398 <commands+0x888>
ffffffffc0203d08:	13400593          	li	a1,308
ffffffffc0203d0c:	00003517          	auipc	a0,0x3
ffffffffc0203d10:	1c450513          	addi	a0,a0,452 # ffffffffc0206ed0 <default_pmm_manager+0x788>
ffffffffc0203d14:	f7afc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203d18 <do_pgfault>:
}

// do_pgfault - 处理缺页，包括：未映射时的按需分配，以及写访问触发的 COW 写时复制
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
    pgfault_num++;
ffffffffc0203d18:	000a7797          	auipc	a5,0xa7
ffffffffc0203d1c:	9c87a783          	lw	a5,-1592(a5) # ffffffffc02aa6e0 <pgfault_num>
ffffffffc0203d20:	2785                	addiw	a5,a5,1
ffffffffc0203d22:	000a7717          	auipc	a4,0xa7
ffffffffc0203d26:	9af72f23          	sw	a5,-1602(a4) # ffffffffc02aa6e0 <pgfault_num>

    if (mm == NULL)
ffffffffc0203d2a:	16050663          	beqz	a0,ffffffffc0203e96 <do_pgfault+0x17e>
{
ffffffffc0203d2e:	715d                	addi	sp,sp,-80
ffffffffc0203d30:	f44e                	sd	s3,40(sp)
ffffffffc0203d32:	89ae                	mv	s3,a1
    {
        return -E_INVAL;
    }

    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203d34:	85b2                	mv	a1,a2
{
ffffffffc0203d36:	e0a2                	sd	s0,64(sp)
ffffffffc0203d38:	fc26                	sd	s1,56(sp)
ffffffffc0203d3a:	f84a                	sd	s2,48(sp)
ffffffffc0203d3c:	e486                	sd	ra,72(sp)
ffffffffc0203d3e:	f052                	sd	s4,32(sp)
ffffffffc0203d40:	ec56                	sd	s5,24(sp)
ffffffffc0203d42:	e85a                	sd	s6,16(sp)
ffffffffc0203d44:	e45e                	sd	s7,8(sp)
ffffffffc0203d46:	84aa                	mv	s1,a0
ffffffffc0203d48:	8432                	mv	s0,a2
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203d4a:	989ff0ef          	jal	ra,ffffffffc02036d2 <find_vma>
ffffffffc0203d4e:	892a                	mv	s2,a0
    if (vma == NULL || addr < vma->vm_start)
ffffffffc0203d50:	12050f63          	beqz	a0,ffffffffc0203e8e <do_pgfault+0x176>
ffffffffc0203d54:	651c                	ld	a5,8(a0)
ffffffffc0203d56:	12f46c63          	bltu	s0,a5,ffffffffc0203e8e <do_pgfault+0x176>
    {
        return -E_INVAL;
    }

    bool write = (error_code & 0x2) != 0;
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203d5a:	75fd                	lui	a1,0xfffff
    pte_t *ptep = get_pte(mm->pgdir, la, 0);
ffffffffc0203d5c:	6c88                	ld	a0,24(s1)
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203d5e:	8c6d                	and	s0,s0,a1
    pte_t *ptep = get_pte(mm->pgdir, la, 0);
ffffffffc0203d60:	4601                	li	a2,0
ffffffffc0203d62:	85a2                	mv	a1,s0
ffffffffc0203d64:	a9cfe0ef          	jal	ra,ffffffffc0202000 <get_pte>
ffffffffc0203d68:	87aa                	mv	a5,a0

    if (ptep == NULL || !(*ptep & PTE_V))
ffffffffc0203d6a:	c569                	beqz	a0,ffffffffc0203e34 <do_pgfault+0x11c>
ffffffffc0203d6c:	00053a03          	ld	s4,0(a0)
ffffffffc0203d70:	001a7713          	andi	a4,s4,1
ffffffffc0203d74:	c361                	beqz	a4,ffffffffc0203e34 <do_pgfault+0x11c>
        }
        return 0;
    }

    // 写访问命中 COW：复制或直接去掉 COW 置可写
    if (write && (*ptep & PTE_COW))
ffffffffc0203d76:	0029f593          	andi	a1,s3,2
ffffffffc0203d7a:	10058a63          	beqz	a1,ffffffffc0203e8e <do_pgfault+0x176>
ffffffffc0203d7e:	100a7713          	andi	a4,s4,256
ffffffffc0203d82:	10070663          	beqz	a4,ffffffffc0203e8e <do_pgfault+0x176>
    if (PPN(pa) >= npage)
ffffffffc0203d86:	000a7b17          	auipc	s6,0xa7
ffffffffc0203d8a:	93ab0b13          	addi	s6,s6,-1734 # ffffffffc02aa6c0 <npage>
ffffffffc0203d8e:	000b3683          	ld	a3,0(s6)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203d92:	002a1713          	slli	a4,s4,0x2
ffffffffc0203d96:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0203d98:	10d77163          	bgeu	a4,a3,ffffffffc0203e9a <do_pgfault+0x182>
    return &pages[PPN(pa) - nbase];
ffffffffc0203d9c:	000a7b97          	auipc	s7,0xa7
ffffffffc0203da0:	92cb8b93          	addi	s7,s7,-1748 # ffffffffc02aa6c8 <pages>
ffffffffc0203da4:	000bb903          	ld	s2,0(s7)
ffffffffc0203da8:	00004a97          	auipc	s5,0x4
ffffffffc0203dac:	c80aba83          	ld	s5,-896(s5) # ffffffffc0207a28 <nbase>
ffffffffc0203db0:	41570733          	sub	a4,a4,s5
ffffffffc0203db4:	071a                	slli	a4,a4,0x6
ffffffffc0203db6:	993a                	add	s2,s2,a4
    {
        uint32_t perm = (*ptep & PTE_USER);
        struct Page *page = pte2page(*ptep);

        if (page_ref(page) > 1)
ffffffffc0203db8:	00092683          	lw	a3,0(s2)
ffffffffc0203dbc:	4705                	li	a4,1
ffffffffc0203dbe:	0ad75d63          	bge	a4,a3,ffffffffc0203e78 <do_pgfault+0x160>
        {
            struct Page *npage = alloc_page();
ffffffffc0203dc2:	4505                	li	a0,1
ffffffffc0203dc4:	984fe0ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc0203dc8:	89aa                	mv	s3,a0
            if (npage == NULL)
ffffffffc0203dca:	c561                	beqz	a0,ffffffffc0203e92 <do_pgfault+0x17a>
    return page - pages + nbase;
ffffffffc0203dcc:	000bb683          	ld	a3,0(s7)
    return KADDR(page2pa(page));
ffffffffc0203dd0:	577d                	li	a4,-1
ffffffffc0203dd2:	000b3603          	ld	a2,0(s6)
    return page - pages + nbase;
ffffffffc0203dd6:	40d507b3          	sub	a5,a0,a3
ffffffffc0203dda:	8799                	srai	a5,a5,0x6
ffffffffc0203ddc:	97d6                	add	a5,a5,s5
    return KADDR(page2pa(page));
ffffffffc0203dde:	8331                	srli	a4,a4,0xc
ffffffffc0203de0:	00e7f5b3          	and	a1,a5,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0203de4:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203de6:	0cc5f663          	bgeu	a1,a2,ffffffffc0203eb2 <do_pgfault+0x19a>
    return page - pages + nbase;
ffffffffc0203dea:	40d906b3          	sub	a3,s2,a3
ffffffffc0203dee:	8699                	srai	a3,a3,0x6
ffffffffc0203df0:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc0203df2:	000a7597          	auipc	a1,0xa7
ffffffffc0203df6:	8e65b583          	ld	a1,-1818(a1) # ffffffffc02aa6d8 <va_pa_offset>
ffffffffc0203dfa:	8f75                	and	a4,a4,a3
ffffffffc0203dfc:	00b78533          	add	a0,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0203e00:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203e02:	0cc77563          	bgeu	a4,a2,ffffffffc0203ecc <do_pgfault+0x1b4>
            {
                return -E_NO_MEM;
            }
            memcpy(page2kva(npage), page2kva(page), PGSIZE);
ffffffffc0203e06:	95b6                	add	a1,a1,a3
ffffffffc0203e08:	6605                	lui	a2,0x1
ffffffffc0203e0a:	287010ef          	jal	ra,ffffffffc0205890 <memcpy>
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203e0e:	8622                	mv	a2,s0
        }
    }

    // 其他类型缺页未在此处理
    return -E_INVAL;
}
ffffffffc0203e10:	6406                	ld	s0,64(sp)
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203e12:	6c88                	ld	a0,24(s1)
}
ffffffffc0203e14:	60a6                	ld	ra,72(sp)
ffffffffc0203e16:	74e2                	ld	s1,56(sp)
ffffffffc0203e18:	7942                	ld	s2,48(sp)
ffffffffc0203e1a:	6ae2                	ld	s5,24(sp)
ffffffffc0203e1c:	6b42                	ld	s6,16(sp)
ffffffffc0203e1e:	6ba2                	ld	s7,8(sp)
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203e20:	01ba7693          	andi	a3,s4,27
ffffffffc0203e24:	85ce                	mv	a1,s3
}
ffffffffc0203e26:	7a02                	ld	s4,32(sp)
ffffffffc0203e28:	79a2                	ld	s3,40(sp)
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203e2a:	0046e693          	ori	a3,a3,4
}
ffffffffc0203e2e:	6161                	addi	sp,sp,80
            int ret = page_insert(mm->pgdir, npage, la, (perm & ~PTE_COW) | PTE_W);
ffffffffc0203e30:	8c1fe06f          	j	ffffffffc02026f0 <page_insert>
        uint32_t perm = perm_from_flags(vma->vm_flags);
ffffffffc0203e34:	01892783          	lw	a5,24(s2)
    uint32_t perm = PTE_U;
ffffffffc0203e38:	4641                	li	a2,16
    if (vm_flags & VM_READ)
ffffffffc0203e3a:	0017f713          	andi	a4,a5,1
ffffffffc0203e3e:	c311                	beqz	a4,ffffffffc0203e42 <do_pgfault+0x12a>
        perm |= PTE_R;
ffffffffc0203e40:	4649                	li	a2,18
    if (vm_flags & VM_WRITE)
ffffffffc0203e42:	0027f713          	andi	a4,a5,2
ffffffffc0203e46:	c311                	beqz	a4,ffffffffc0203e4a <do_pgfault+0x132>
        perm |= PTE_W | PTE_R;
ffffffffc0203e48:	4659                	li	a2,22
    if (vm_flags & VM_EXEC)
ffffffffc0203e4a:	8b91                	andi	a5,a5,4
ffffffffc0203e4c:	e39d                	bnez	a5,ffffffffc0203e72 <do_pgfault+0x15a>
        if (pgdir_alloc_page(mm->pgdir, la, perm) == NULL)
ffffffffc0203e4e:	6c88                	ld	a0,24(s1)
ffffffffc0203e50:	85a2                	mv	a1,s0
ffffffffc0203e52:	f6aff0ef          	jal	ra,ffffffffc02035bc <pgdir_alloc_page>
ffffffffc0203e56:	87aa                	mv	a5,a0
        return 0;
ffffffffc0203e58:	4501                	li	a0,0
        if (pgdir_alloc_page(mm->pgdir, la, perm) == NULL)
ffffffffc0203e5a:	cf85                	beqz	a5,ffffffffc0203e92 <do_pgfault+0x17a>
}
ffffffffc0203e5c:	60a6                	ld	ra,72(sp)
ffffffffc0203e5e:	6406                	ld	s0,64(sp)
ffffffffc0203e60:	74e2                	ld	s1,56(sp)
ffffffffc0203e62:	7942                	ld	s2,48(sp)
ffffffffc0203e64:	79a2                	ld	s3,40(sp)
ffffffffc0203e66:	7a02                	ld	s4,32(sp)
ffffffffc0203e68:	6ae2                	ld	s5,24(sp)
ffffffffc0203e6a:	6b42                	ld	s6,16(sp)
ffffffffc0203e6c:	6ba2                	ld	s7,8(sp)
ffffffffc0203e6e:	6161                	addi	sp,sp,80
ffffffffc0203e70:	8082                	ret
        perm |= PTE_X;
ffffffffc0203e72:	00866613          	ori	a2,a2,8
ffffffffc0203e76:	bfe1                	j	ffffffffc0203e4e <do_pgfault+0x136>
            tlb_invalidate(mm->pgdir, la);
ffffffffc0203e78:	6c88                	ld	a0,24(s1)
            *ptep = (*ptep | PTE_W) & ~PTE_COW;
ffffffffc0203e7a:	efba7713          	andi	a4,s4,-261
ffffffffc0203e7e:	00476713          	ori	a4,a4,4
ffffffffc0203e82:	e398                	sd	a4,0(a5)
            tlb_invalidate(mm->pgdir, la);
ffffffffc0203e84:	85a2                	mv	a1,s0
ffffffffc0203e86:	f30ff0ef          	jal	ra,ffffffffc02035b6 <tlb_invalidate>
            return 0;
ffffffffc0203e8a:	4501                	li	a0,0
ffffffffc0203e8c:	bfc1                	j	ffffffffc0203e5c <do_pgfault+0x144>
        return -E_INVAL;
ffffffffc0203e8e:	5575                	li	a0,-3
ffffffffc0203e90:	b7f1                	j	ffffffffc0203e5c <do_pgfault+0x144>
            return -E_NO_MEM;
ffffffffc0203e92:	5571                	li	a0,-4
ffffffffc0203e94:	b7e1                	j	ffffffffc0203e5c <do_pgfault+0x144>
        return -E_INVAL;
ffffffffc0203e96:	5575                	li	a0,-3
}
ffffffffc0203e98:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0203e9a:	00003617          	auipc	a2,0x3
ffffffffc0203e9e:	9b660613          	addi	a2,a2,-1610 # ffffffffc0206850 <default_pmm_manager+0x108>
ffffffffc0203ea2:	06900593          	li	a1,105
ffffffffc0203ea6:	00003517          	auipc	a0,0x3
ffffffffc0203eaa:	90250513          	addi	a0,a0,-1790 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc0203eae:	de0fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0203eb2:	86be                	mv	a3,a5
ffffffffc0203eb4:	00003617          	auipc	a2,0x3
ffffffffc0203eb8:	8cc60613          	addi	a2,a2,-1844 # ffffffffc0206780 <default_pmm_manager+0x38>
ffffffffc0203ebc:	07100593          	li	a1,113
ffffffffc0203ec0:	00003517          	auipc	a0,0x3
ffffffffc0203ec4:	8e850513          	addi	a0,a0,-1816 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc0203ec8:	dc6fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203ecc:	00003617          	auipc	a2,0x3
ffffffffc0203ed0:	8b460613          	addi	a2,a2,-1868 # ffffffffc0206780 <default_pmm_manager+0x38>
ffffffffc0203ed4:	07100593          	li	a1,113
ffffffffc0203ed8:	00003517          	auipc	a0,0x3
ffffffffc0203edc:	8d050513          	addi	a0,a0,-1840 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc0203ee0:	daefc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ee4 <user_mem_check>:
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203ee4:	7179                	addi	sp,sp,-48
ffffffffc0203ee6:	f022                	sd	s0,32(sp)
ffffffffc0203ee8:	f406                	sd	ra,40(sp)
ffffffffc0203eea:	ec26                	sd	s1,24(sp)
ffffffffc0203eec:	e84a                	sd	s2,16(sp)
ffffffffc0203eee:	e44e                	sd	s3,8(sp)
ffffffffc0203ef0:	e052                	sd	s4,0(sp)
ffffffffc0203ef2:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203ef4:	c135                	beqz	a0,ffffffffc0203f58 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203ef6:	002007b7          	lui	a5,0x200
ffffffffc0203efa:	04f5e663          	bltu	a1,a5,ffffffffc0203f46 <user_mem_check+0x62>
ffffffffc0203efe:	00c584b3          	add	s1,a1,a2
ffffffffc0203f02:	0495f263          	bgeu	a1,s1,ffffffffc0203f46 <user_mem_check+0x62>
ffffffffc0203f06:	4785                	li	a5,1
ffffffffc0203f08:	07fe                	slli	a5,a5,0x1f
ffffffffc0203f0a:	0297ee63          	bltu	a5,s1,ffffffffc0203f46 <user_mem_check+0x62>
ffffffffc0203f0e:	892a                	mv	s2,a0
ffffffffc0203f10:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f12:	6a05                	lui	s4,0x1
ffffffffc0203f14:	a821                	j	ffffffffc0203f2c <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f16:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f1a:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203f1c:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f1e:	c685                	beqz	a3,ffffffffc0203f46 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203f20:	c399                	beqz	a5,ffffffffc0203f26 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f22:	02e46263          	bltu	s0,a4,ffffffffc0203f46 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203f26:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203f28:	04947663          	bgeu	s0,s1,ffffffffc0203f74 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203f2c:	85a2                	mv	a1,s0
ffffffffc0203f2e:	854a                	mv	a0,s2
ffffffffc0203f30:	fa2ff0ef          	jal	ra,ffffffffc02036d2 <find_vma>
ffffffffc0203f34:	c909                	beqz	a0,ffffffffc0203f46 <user_mem_check+0x62>
ffffffffc0203f36:	6518                	ld	a4,8(a0)
ffffffffc0203f38:	00e46763          	bltu	s0,a4,ffffffffc0203f46 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f3c:	4d1c                	lw	a5,24(a0)
ffffffffc0203f3e:	fc099ce3          	bnez	s3,ffffffffc0203f16 <user_mem_check+0x32>
ffffffffc0203f42:	8b85                	andi	a5,a5,1
ffffffffc0203f44:	f3ed                	bnez	a5,ffffffffc0203f26 <user_mem_check+0x42>
            return 0;
ffffffffc0203f46:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203f48:	70a2                	ld	ra,40(sp)
ffffffffc0203f4a:	7402                	ld	s0,32(sp)
ffffffffc0203f4c:	64e2                	ld	s1,24(sp)
ffffffffc0203f4e:	6942                	ld	s2,16(sp)
ffffffffc0203f50:	69a2                	ld	s3,8(sp)
ffffffffc0203f52:	6a02                	ld	s4,0(sp)
ffffffffc0203f54:	6145                	addi	sp,sp,48
ffffffffc0203f56:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203f58:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f5c:	4501                	li	a0,0
ffffffffc0203f5e:	fef5e5e3          	bltu	a1,a5,ffffffffc0203f48 <user_mem_check+0x64>
ffffffffc0203f62:	962e                	add	a2,a2,a1
ffffffffc0203f64:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203f48 <user_mem_check+0x64>
ffffffffc0203f68:	c8000537          	lui	a0,0xc8000
ffffffffc0203f6c:	0505                	addi	a0,a0,1
ffffffffc0203f6e:	00a63533          	sltu	a0,a2,a0
ffffffffc0203f72:	bfd9                	j	ffffffffc0203f48 <user_mem_check+0x64>
        return 1;
ffffffffc0203f74:	4505                	li	a0,1
ffffffffc0203f76:	bfc9                	j	ffffffffc0203f48 <user_mem_check+0x64>

ffffffffc0203f78 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203f78:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203f7a:	9402                	jalr	s0

	jal do_exit
ffffffffc0203f7c:	638000ef          	jal	ra,ffffffffc02045b4 <do_exit>

ffffffffc0203f80 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203f80:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203f82:	10800513          	li	a0,264
{
ffffffffc0203f86:	e022                	sd	s0,0(sp)
ffffffffc0203f88:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203f8a:	de1fd0ef          	jal	ra,ffffffffc0201d6a <kmalloc>
ffffffffc0203f8e:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203f90:	c92d                	beqz	a0,ffffffffc0204002 <alloc_proc+0x82>
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        //清空整个结构（其实这里偷鸡一下，从打印初始化的条件可以直接看出每个值的处理），666
        memset(proc, 0, sizeof(struct proc_struct));
ffffffffc0203f92:	10800613          	li	a2,264
ffffffffc0203f96:	4581                	li	a1,0
ffffffffc0203f98:	0e7010ef          	jal	ra,ffffffffc020587e <memset>
        proc->state = PROC_UNINIT;
ffffffffc0203f9c:	57fd                	li	a5,-1
ffffffffc0203f9e:	1782                	slli	a5,a5,0x20
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&proc->context, 0, sizeof(proc->context));
ffffffffc0203fa0:	07000613          	li	a2,112
ffffffffc0203fa4:	4581                	li	a1,0
        proc->state = PROC_UNINIT;
ffffffffc0203fa6:	e01c                	sd	a5,0(s0)
        proc->runs = 0;
ffffffffc0203fa8:	00042423          	sw	zero,8(s0)
        proc->kstack = 0;
ffffffffc0203fac:	00043823          	sd	zero,16(s0)
        proc->need_resched = 0;
ffffffffc0203fb0:	00043c23          	sd	zero,24(s0)
        proc->parent = NULL;
ffffffffc0203fb4:	02043023          	sd	zero,32(s0)
        proc->mm = NULL;
ffffffffc0203fb8:	02043423          	sd	zero,40(s0)
        memset(&proc->context, 0, sizeof(proc->context));
ffffffffc0203fbc:	03040513          	addi	a0,s0,48
ffffffffc0203fc0:	0bf010ef          	jal	ra,ffffffffc020587e <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203fc4:	000a6797          	auipc	a5,0xa6
ffffffffc0203fc8:	6ec7b783          	ld	a5,1772(a5) # ffffffffc02aa6b0 <boot_pgdir_pa>
ffffffffc0203fcc:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;
ffffffffc0203fce:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc0203fd2:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203fd6:	4641                	li	a2,16
ffffffffc0203fd8:	4581                	li	a1,0
ffffffffc0203fda:	0b440513          	addi	a0,s0,180
ffffffffc0203fde:	0a1010ef          	jal	ra,ffffffffc020587e <memset>
        list_init(&proc->list_link);
ffffffffc0203fe2:	0c840713          	addi	a4,s0,200
        list_init(&proc->hash_link);
ffffffffc0203fe6:	0d840793          	addi	a5,s0,216
    elm->prev = elm->next = elm;
ffffffffc0203fea:	e878                	sd	a4,208(s0)
ffffffffc0203fec:	e478                	sd	a4,200(s0)
ffffffffc0203fee:	f07c                	sd	a5,224(s0)
ffffffffc0203ff0:	ec7c                	sd	a5,216(s0)
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->wait_state = 0;
ffffffffc0203ff2:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;
ffffffffc0203ff6:	0e043823          	sd	zero,240(s0)
        proc->yptr = NULL;
ffffffffc0203ffa:	0e043c23          	sd	zero,248(s0)
        proc->optr = NULL;
ffffffffc0203ffe:	10043023          	sd	zero,256(s0)
    }
    return proc;
}
ffffffffc0204002:	60a2                	ld	ra,8(sp)
ffffffffc0204004:	8522                	mv	a0,s0
ffffffffc0204006:	6402                	ld	s0,0(sp)
ffffffffc0204008:	0141                	addi	sp,sp,16
ffffffffc020400a:	8082                	ret

ffffffffc020400c <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc020400c:	000a6797          	auipc	a5,0xa6
ffffffffc0204010:	6dc7b783          	ld	a5,1756(a5) # ffffffffc02aa6e8 <current>
ffffffffc0204014:	73c8                	ld	a0,160(a5)
ffffffffc0204016:	fc9fc06f          	j	ffffffffc0200fde <forkrets>

ffffffffc020401a <user_main>:
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
#else
    KERNEL_EXECVE(exit);
ffffffffc020401a:	000a6797          	auipc	a5,0xa6
ffffffffc020401e:	6ce7b783          	ld	a5,1742(a5) # ffffffffc02aa6e8 <current>
ffffffffc0204022:	43cc                	lw	a1,4(a5)
{
ffffffffc0204024:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE(exit);
ffffffffc0204026:	00003617          	auipc	a2,0x3
ffffffffc020402a:	10a60613          	addi	a2,a2,266 # ffffffffc0207130 <default_pmm_manager+0x9e8>
ffffffffc020402e:	00003517          	auipc	a0,0x3
ffffffffc0204032:	10a50513          	addi	a0,a0,266 # ffffffffc0207138 <default_pmm_manager+0x9f0>
{
ffffffffc0204036:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE(exit);
ffffffffc0204038:	95cfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020403c:	3fe07797          	auipc	a5,0x3fe07
ffffffffc0204040:	0dc78793          	addi	a5,a5,220 # b118 <_binary_obj___user_exit_out_size>
ffffffffc0204044:	e43e                	sd	a5,8(sp)
ffffffffc0204046:	00003517          	auipc	a0,0x3
ffffffffc020404a:	0ea50513          	addi	a0,a0,234 # ffffffffc0207130 <default_pmm_manager+0x9e8>
ffffffffc020404e:	00026797          	auipc	a5,0x26
ffffffffc0204052:	4c278793          	addi	a5,a5,1218 # ffffffffc022a510 <_binary_obj___user_exit_out_start>
ffffffffc0204056:	f03e                	sd	a5,32(sp)
ffffffffc0204058:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc020405a:	e802                	sd	zero,16(sp)
ffffffffc020405c:	780010ef          	jal	ra,ffffffffc02057dc <strlen>
ffffffffc0204060:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204062:	4511                	li	a0,4
ffffffffc0204064:	55a2                	lw	a1,40(sp)
ffffffffc0204066:	4662                	lw	a2,24(sp)
ffffffffc0204068:	5682                	lw	a3,32(sp)
ffffffffc020406a:	4722                	lw	a4,8(sp)
ffffffffc020406c:	48a9                	li	a7,10
ffffffffc020406e:	9002                	ebreak
ffffffffc0204070:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204072:	65c2                	ld	a1,16(sp)
ffffffffc0204074:	00003517          	auipc	a0,0x3
ffffffffc0204078:	0ec50513          	addi	a0,a0,236 # ffffffffc0207160 <default_pmm_manager+0xa18>
ffffffffc020407c:	918fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
    panic("user_main execve failed.\n");
ffffffffc0204080:	00003617          	auipc	a2,0x3
ffffffffc0204084:	0f060613          	addi	a2,a2,240 # ffffffffc0207170 <default_pmm_manager+0xa28>
ffffffffc0204088:	3fa00593          	li	a1,1018
ffffffffc020408c:	00003517          	auipc	a0,0x3
ffffffffc0204090:	10450513          	addi	a0,a0,260 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc0204094:	bfafc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204098 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204098:	6d14                	ld	a3,24(a0)
{
ffffffffc020409a:	1141                	addi	sp,sp,-16
ffffffffc020409c:	e406                	sd	ra,8(sp)
ffffffffc020409e:	c02007b7          	lui	a5,0xc0200
ffffffffc02040a2:	02f6ee63          	bltu	a3,a5,ffffffffc02040de <put_pgdir+0x46>
ffffffffc02040a6:	000a6517          	auipc	a0,0xa6
ffffffffc02040aa:	63253503          	ld	a0,1586(a0) # ffffffffc02aa6d8 <va_pa_offset>
ffffffffc02040ae:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc02040b0:	82b1                	srli	a3,a3,0xc
ffffffffc02040b2:	000a6797          	auipc	a5,0xa6
ffffffffc02040b6:	60e7b783          	ld	a5,1550(a5) # ffffffffc02aa6c0 <npage>
ffffffffc02040ba:	02f6fe63          	bgeu	a3,a5,ffffffffc02040f6 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc02040be:	00004517          	auipc	a0,0x4
ffffffffc02040c2:	96a53503          	ld	a0,-1686(a0) # ffffffffc0207a28 <nbase>
}
ffffffffc02040c6:	60a2                	ld	ra,8(sp)
ffffffffc02040c8:	8e89                	sub	a3,a3,a0
ffffffffc02040ca:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc02040cc:	000a6517          	auipc	a0,0xa6
ffffffffc02040d0:	5fc53503          	ld	a0,1532(a0) # ffffffffc02aa6c8 <pages>
ffffffffc02040d4:	4585                	li	a1,1
ffffffffc02040d6:	9536                	add	a0,a0,a3
}
ffffffffc02040d8:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc02040da:	eadfd06f          	j	ffffffffc0201f86 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc02040de:	00002617          	auipc	a2,0x2
ffffffffc02040e2:	74a60613          	addi	a2,a2,1866 # ffffffffc0206828 <default_pmm_manager+0xe0>
ffffffffc02040e6:	07700593          	li	a1,119
ffffffffc02040ea:	00002517          	auipc	a0,0x2
ffffffffc02040ee:	6be50513          	addi	a0,a0,1726 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc02040f2:	b9cfc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02040f6:	00002617          	auipc	a2,0x2
ffffffffc02040fa:	75a60613          	addi	a2,a2,1882 # ffffffffc0206850 <default_pmm_manager+0x108>
ffffffffc02040fe:	06900593          	li	a1,105
ffffffffc0204102:	00002517          	auipc	a0,0x2
ffffffffc0204106:	6a650513          	addi	a0,a0,1702 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc020410a:	b84fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020410e <proc_run>:
{
ffffffffc020410e:	7179                	addi	sp,sp,-48
ffffffffc0204110:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0204112:	000a6497          	auipc	s1,0xa6
ffffffffc0204116:	5d648493          	addi	s1,s1,1494 # ffffffffc02aa6e8 <current>
ffffffffc020411a:	6098                	ld	a4,0(s1)
{
ffffffffc020411c:	f406                	sd	ra,40(sp)
ffffffffc020411e:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0204120:	02a70763          	beq	a4,a0,ffffffffc020414e <proc_run+0x40>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204124:	100027f3          	csrr	a5,sstatus
ffffffffc0204128:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020412a:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020412c:	ef85                	bnez	a5,ffffffffc0204164 <proc_run+0x56>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc020412e:	755c                	ld	a5,168(a0)
ffffffffc0204130:	56fd                	li	a3,-1
ffffffffc0204132:	16fe                	slli	a3,a3,0x3f
ffffffffc0204134:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0204136:	e088                	sd	a0,0(s1)
ffffffffc0204138:	8fd5                	or	a5,a5,a3
ffffffffc020413a:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(proc->context));
ffffffffc020413e:	03050593          	addi	a1,a0,48
ffffffffc0204142:	03070513          	addi	a0,a4,48
ffffffffc0204146:	03c010ef          	jal	ra,ffffffffc0205182 <switch_to>
    if (flag)
ffffffffc020414a:	00091763          	bnez	s2,ffffffffc0204158 <proc_run+0x4a>
}
ffffffffc020414e:	70a2                	ld	ra,40(sp)
ffffffffc0204150:	7482                	ld	s1,32(sp)
ffffffffc0204152:	6962                	ld	s2,24(sp)
ffffffffc0204154:	6145                	addi	sp,sp,48
ffffffffc0204156:	8082                	ret
ffffffffc0204158:	70a2                	ld	ra,40(sp)
ffffffffc020415a:	7482                	ld	s1,32(sp)
ffffffffc020415c:	6962                	ld	s2,24(sp)
ffffffffc020415e:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204160:	84ffc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0204164:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204166:	84ffc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
            struct proc_struct *prev = current;
ffffffffc020416a:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc020416c:	6522                	ld	a0,8(sp)
ffffffffc020416e:	4905                	li	s2,1
ffffffffc0204170:	bf7d                	j	ffffffffc020412e <proc_run+0x20>

ffffffffc0204172 <do_fork>:
{
ffffffffc0204172:	7119                	addi	sp,sp,-128
ffffffffc0204174:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204176:	000a6917          	auipc	s2,0xa6
ffffffffc020417a:	58a90913          	addi	s2,s2,1418 # ffffffffc02aa700 <nr_process>
ffffffffc020417e:	00092703          	lw	a4,0(s2)
{
ffffffffc0204182:	fc86                	sd	ra,120(sp)
ffffffffc0204184:	f8a2                	sd	s0,112(sp)
ffffffffc0204186:	f4a6                	sd	s1,104(sp)
ffffffffc0204188:	ecce                	sd	s3,88(sp)
ffffffffc020418a:	e8d2                	sd	s4,80(sp)
ffffffffc020418c:	e4d6                	sd	s5,72(sp)
ffffffffc020418e:	e0da                	sd	s6,64(sp)
ffffffffc0204190:	fc5e                	sd	s7,56(sp)
ffffffffc0204192:	f862                	sd	s8,48(sp)
ffffffffc0204194:	f466                	sd	s9,40(sp)
ffffffffc0204196:	f06a                	sd	s10,32(sp)
ffffffffc0204198:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020419a:	6785                	lui	a5,0x1
ffffffffc020419c:	34f75263          	bge	a4,a5,ffffffffc02044e0 <do_fork+0x36e>
ffffffffc02041a0:	8a2a                	mv	s4,a0
ffffffffc02041a2:	89ae                	mv	s3,a1
ffffffffc02041a4:	8432                	mv	s0,a2
    proc = alloc_proc();
ffffffffc02041a6:	ddbff0ef          	jal	ra,ffffffffc0203f80 <alloc_proc>
ffffffffc02041aa:	84aa                	mv	s1,a0
    if(proc == NULL)
ffffffffc02041ac:	32050363          	beqz	a0,ffffffffc02044d2 <do_fork+0x360>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02041b0:	4509                	li	a0,2
ffffffffc02041b2:	d97fd0ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
    if (page != NULL)
ffffffffc02041b6:	30050b63          	beqz	a0,ffffffffc02044cc <do_fork+0x35a>
    return page - pages + nbase;
ffffffffc02041ba:	000a6b17          	auipc	s6,0xa6
ffffffffc02041be:	50eb0b13          	addi	s6,s6,1294 # ffffffffc02aa6c8 <pages>
ffffffffc02041c2:	000b3683          	ld	a3,0(s6)
ffffffffc02041c6:	00004797          	auipc	a5,0x4
ffffffffc02041ca:	86278793          	addi	a5,a5,-1950 # ffffffffc0207a28 <nbase>
ffffffffc02041ce:	6398                	ld	a4,0(a5)
ffffffffc02041d0:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc02041d4:	000a6c17          	auipc	s8,0xa6
ffffffffc02041d8:	4ecc0c13          	addi	s8,s8,1260 # ffffffffc02aa6c0 <npage>
    return page - pages + nbase;
ffffffffc02041dc:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02041de:	57fd                	li	a5,-1
ffffffffc02041e0:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02041e4:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02041e6:	00c7db93          	srli	s7,a5,0xc
ffffffffc02041ea:	0176f5b3          	and	a1,a3,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc02041ee:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02041f0:	34c5fe63          	bgeu	a1,a2,ffffffffc020454c <do_fork+0x3da>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02041f4:	000a6a97          	auipc	s5,0xa6
ffffffffc02041f8:	4f4a8a93          	addi	s5,s5,1268 # ffffffffc02aa6e8 <current>
ffffffffc02041fc:	000ab583          	ld	a1,0(s5)
ffffffffc0204200:	000a6c97          	auipc	s9,0xa6
ffffffffc0204204:	4d8c8c93          	addi	s9,s9,1240 # ffffffffc02aa6d8 <va_pa_offset>
ffffffffc0204208:	000cb603          	ld	a2,0(s9)
ffffffffc020420c:	0285bd83          	ld	s11,40(a1)
ffffffffc0204210:	e43a                	sd	a4,8(sp)
ffffffffc0204212:	96b2                	add	a3,a3,a2
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204214:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc0204216:	020d8863          	beqz	s11,ffffffffc0204246 <do_fork+0xd4>
    if (clone_flags & CLONE_VM)
ffffffffc020421a:	100a7a13          	andi	s4,s4,256
ffffffffc020421e:	1c0a0563          	beqz	s4,ffffffffc02043e8 <do_fork+0x276>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0204222:	030da703          	lw	a4,48(s11)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204226:	018db783          	ld	a5,24(s11)
ffffffffc020422a:	c02006b7          	lui	a3,0xc0200
ffffffffc020422e:	2705                	addiw	a4,a4,1
ffffffffc0204230:	02eda823          	sw	a4,48(s11)
    proc->mm = mm;
ffffffffc0204234:	03b4b423          	sd	s11,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204238:	2cd7e563          	bltu	a5,a3,ffffffffc0204502 <do_fork+0x390>
ffffffffc020423c:	000cb703          	ld	a4,0(s9)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204240:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204242:	8f99                	sub	a5,a5,a4
ffffffffc0204244:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204246:	6789                	lui	a5,0x2
ffffffffc0204248:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc8>
ffffffffc020424c:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc020424e:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204250:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc0204252:	87b6                	mv	a5,a3
ffffffffc0204254:	12040893          	addi	a7,s0,288
ffffffffc0204258:	00063803          	ld	a6,0(a2)
ffffffffc020425c:	6608                	ld	a0,8(a2)
ffffffffc020425e:	6a0c                	ld	a1,16(a2)
ffffffffc0204260:	6e18                	ld	a4,24(a2)
ffffffffc0204262:	0107b023          	sd	a6,0(a5)
ffffffffc0204266:	e788                	sd	a0,8(a5)
ffffffffc0204268:	eb8c                	sd	a1,16(a5)
ffffffffc020426a:	ef98                	sd	a4,24(a5)
ffffffffc020426c:	02060613          	addi	a2,a2,32
ffffffffc0204270:	02078793          	addi	a5,a5,32
ffffffffc0204274:	ff1612e3          	bne	a2,a7,ffffffffc0204258 <do_fork+0xe6>
    proc->tf->gpr.a0 = 0;
ffffffffc0204278:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020427c:	14098363          	beqz	s3,ffffffffc02043c2 <do_fork+0x250>
ffffffffc0204280:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204284:	00000797          	auipc	a5,0x0
ffffffffc0204288:	d8878793          	addi	a5,a5,-632 # ffffffffc020400c <forkret>
ffffffffc020428c:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020428e:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204290:	100027f3          	csrr	a5,sstatus
ffffffffc0204294:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204296:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204298:	14079463          	bnez	a5,ffffffffc02043e0 <do_fork+0x26e>
    if (++last_pid >= MAX_PID)
ffffffffc020429c:	000a2817          	auipc	a6,0xa2
ffffffffc02042a0:	fac80813          	addi	a6,a6,-84 # ffffffffc02a6248 <last_pid.1>
        proc->parent = current;
ffffffffc02042a4:	000ab703          	ld	a4,0(s5)
    if (++last_pid >= MAX_PID)
ffffffffc02042a8:	00082783          	lw	a5,0(a6)
ffffffffc02042ac:	6689                	lui	a3,0x2
        proc->parent = current;
ffffffffc02042ae:	f098                	sd	a4,32(s1)
    if (++last_pid >= MAX_PID)
ffffffffc02042b0:	0017851b          	addiw	a0,a5,1
        current->wait_state = 0;
ffffffffc02042b4:	0e072623          	sw	zero,236(a4)
    if (++last_pid >= MAX_PID)
ffffffffc02042b8:	00a82023          	sw	a0,0(a6)
ffffffffc02042bc:	08d55c63          	bge	a0,a3,ffffffffc0204354 <do_fork+0x1e2>
    if (last_pid >= next_safe)
ffffffffc02042c0:	000a2317          	auipc	t1,0xa2
ffffffffc02042c4:	f8c30313          	addi	t1,t1,-116 # ffffffffc02a624c <next_safe.0>
ffffffffc02042c8:	00032783          	lw	a5,0(t1)
ffffffffc02042cc:	000a6417          	auipc	s0,0xa6
ffffffffc02042d0:	39c40413          	addi	s0,s0,924 # ffffffffc02aa668 <proc_list>
ffffffffc02042d4:	08f55863          	bge	a0,a5,ffffffffc0204364 <do_fork+0x1f2>
        proc->pid = get_pid();
ffffffffc02042d8:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02042da:	45a9                	li	a1,10
ffffffffc02042dc:	2501                	sext.w	a0,a0
ffffffffc02042de:	0fa010ef          	jal	ra,ffffffffc02053d8 <hash32>
ffffffffc02042e2:	02051793          	slli	a5,a0,0x20
ffffffffc02042e6:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02042ea:	000a2797          	auipc	a5,0xa2
ffffffffc02042ee:	37e78793          	addi	a5,a5,894 # ffffffffc02a6668 <hash_list>
ffffffffc02042f2:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02042f4:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02042f6:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02042f8:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc02042fc:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02042fe:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0204300:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204302:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204304:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc0204308:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc020430a:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc020430c:	e21c                	sd	a5,0(a2)
ffffffffc020430e:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0204310:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0204312:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0204314:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204318:	10e4b023          	sd	a4,256(s1)
ffffffffc020431c:	c311                	beqz	a4,ffffffffc0204320 <do_fork+0x1ae>
        proc->optr->yptr = proc;
ffffffffc020431e:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc0204320:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0204324:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc0204326:	2785                	addiw	a5,a5,1
ffffffffc0204328:	00f92023          	sw	a5,0(s2)
        proc->state = PROC_RUNNABLE;
ffffffffc020432c:	4789                	li	a5,2
ffffffffc020432e:	c09c                	sw	a5,0(s1)
    if (flag)
ffffffffc0204330:	14099863          	bnez	s3,ffffffffc0204480 <do_fork+0x30e>
    ret = proc->pid;
ffffffffc0204334:	40c8                	lw	a0,4(s1)
}
ffffffffc0204336:	70e6                	ld	ra,120(sp)
ffffffffc0204338:	7446                	ld	s0,112(sp)
ffffffffc020433a:	74a6                	ld	s1,104(sp)
ffffffffc020433c:	7906                	ld	s2,96(sp)
ffffffffc020433e:	69e6                	ld	s3,88(sp)
ffffffffc0204340:	6a46                	ld	s4,80(sp)
ffffffffc0204342:	6aa6                	ld	s5,72(sp)
ffffffffc0204344:	6b06                	ld	s6,64(sp)
ffffffffc0204346:	7be2                	ld	s7,56(sp)
ffffffffc0204348:	7c42                	ld	s8,48(sp)
ffffffffc020434a:	7ca2                	ld	s9,40(sp)
ffffffffc020434c:	7d02                	ld	s10,32(sp)
ffffffffc020434e:	6de2                	ld	s11,24(sp)
ffffffffc0204350:	6109                	addi	sp,sp,128
ffffffffc0204352:	8082                	ret
        last_pid = 1;
ffffffffc0204354:	4785                	li	a5,1
ffffffffc0204356:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020435a:	4505                	li	a0,1
ffffffffc020435c:	000a2317          	auipc	t1,0xa2
ffffffffc0204360:	ef030313          	addi	t1,t1,-272 # ffffffffc02a624c <next_safe.0>
    return listelm->next;
ffffffffc0204364:	000a6417          	auipc	s0,0xa6
ffffffffc0204368:	30440413          	addi	s0,s0,772 # ffffffffc02aa668 <proc_list>
ffffffffc020436c:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0204370:	6789                	lui	a5,0x2
ffffffffc0204372:	00f32023          	sw	a5,0(t1)
ffffffffc0204376:	86aa                	mv	a3,a0
ffffffffc0204378:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020437a:	6e89                	lui	t4,0x2
ffffffffc020437c:	148e0d63          	beq	t3,s0,ffffffffc02044d6 <do_fork+0x364>
ffffffffc0204380:	88ae                	mv	a7,a1
ffffffffc0204382:	87f2                	mv	a5,t3
ffffffffc0204384:	6609                	lui	a2,0x2
ffffffffc0204386:	a811                	j	ffffffffc020439a <do_fork+0x228>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204388:	00e6d663          	bge	a3,a4,ffffffffc0204394 <do_fork+0x222>
ffffffffc020438c:	00c75463          	bge	a4,a2,ffffffffc0204394 <do_fork+0x222>
ffffffffc0204390:	863a                	mv	a2,a4
ffffffffc0204392:	4885                	li	a7,1
ffffffffc0204394:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204396:	00878d63          	beq	a5,s0,ffffffffc02043b0 <do_fork+0x23e>
            if (proc->pid == last_pid)
ffffffffc020439a:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c6c>
ffffffffc020439e:	fed715e3          	bne	a4,a3,ffffffffc0204388 <do_fork+0x216>
                if (++last_pid >= next_safe)
ffffffffc02043a2:	2685                	addiw	a3,a3,1
ffffffffc02043a4:	0ec6d163          	bge	a3,a2,ffffffffc0204486 <do_fork+0x314>
ffffffffc02043a8:	679c                	ld	a5,8(a5)
ffffffffc02043aa:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02043ac:	fe8797e3          	bne	a5,s0,ffffffffc020439a <do_fork+0x228>
ffffffffc02043b0:	c581                	beqz	a1,ffffffffc02043b8 <do_fork+0x246>
ffffffffc02043b2:	00d82023          	sw	a3,0(a6)
ffffffffc02043b6:	8536                	mv	a0,a3
ffffffffc02043b8:	f20880e3          	beqz	a7,ffffffffc02042d8 <do_fork+0x166>
ffffffffc02043bc:	00c32023          	sw	a2,0(t1)
ffffffffc02043c0:	bf21                	j	ffffffffc02042d8 <do_fork+0x166>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02043c2:	89b6                	mv	s3,a3
ffffffffc02043c4:	0136b823          	sd	s3,16(a3) # 2010 <_binary_obj___user_faultread_out_size-0x7b98>
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02043c8:	00000797          	auipc	a5,0x0
ffffffffc02043cc:	c4478793          	addi	a5,a5,-956 # ffffffffc020400c <forkret>
ffffffffc02043d0:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02043d2:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02043d4:	100027f3          	csrr	a5,sstatus
ffffffffc02043d8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02043da:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02043dc:	ec0780e3          	beqz	a5,ffffffffc020429c <do_fork+0x12a>
        intr_disable();
ffffffffc02043e0:	dd4fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02043e4:	4985                	li	s3,1
ffffffffc02043e6:	bd5d                	j	ffffffffc020429c <do_fork+0x12a>
    if ((mm = mm_create()) == NULL)
ffffffffc02043e8:	abaff0ef          	jal	ra,ffffffffc02036a2 <mm_create>
ffffffffc02043ec:	8d2a                	mv	s10,a0
ffffffffc02043ee:	c545                	beqz	a0,ffffffffc0204496 <do_fork+0x324>
    if ((page = alloc_page()) == NULL)
ffffffffc02043f0:	4505                	li	a0,1
ffffffffc02043f2:	b57fd0ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc02043f6:	cd49                	beqz	a0,ffffffffc0204490 <do_fork+0x31e>
    return page - pages + nbase;
ffffffffc02043f8:	000b3683          	ld	a3,0(s6)
ffffffffc02043fc:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc02043fe:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204402:	40d506b3          	sub	a3,a0,a3
ffffffffc0204406:	8699                	srai	a3,a3,0x6
ffffffffc0204408:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc020440a:	0176f7b3          	and	a5,a3,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc020440e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204410:	12c7fe63          	bgeu	a5,a2,ffffffffc020454c <do_fork+0x3da>
ffffffffc0204414:	000cba03          	ld	s4,0(s9)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204418:	6605                	lui	a2,0x1
ffffffffc020441a:	000a6597          	auipc	a1,0xa6
ffffffffc020441e:	29e5b583          	ld	a1,670(a1) # ffffffffc02aa6b8 <boot_pgdir_va>
ffffffffc0204422:	9a36                	add	s4,s4,a3
ffffffffc0204424:	8552                	mv	a0,s4
ffffffffc0204426:	46a010ef          	jal	ra,ffffffffc0205890 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc020442a:	038d8b93          	addi	s7,s11,56
    mm->pgdir = pgdir;
ffffffffc020442e:	014d3c23          	sd	s4,24(s10) # 200018 <_binary_obj___user_exit_out_size+0x1f4f00>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204432:	4785                	li	a5,1
ffffffffc0204434:	40fbb7af          	amoor.d	a5,a5,(s7)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204438:	8b85                	andi	a5,a5,1
ffffffffc020443a:	4a05                	li	s4,1
ffffffffc020443c:	c799                	beqz	a5,ffffffffc020444a <do_fork+0x2d8>
    {
        schedule();
ffffffffc020443e:	62f000ef          	jal	ra,ffffffffc020526c <schedule>
ffffffffc0204442:	414bb7af          	amoor.d	a5,s4,(s7)
    while (!try_lock(lock))
ffffffffc0204446:	8b85                	andi	a5,a5,1
ffffffffc0204448:	fbfd                	bnez	a5,ffffffffc020443e <do_fork+0x2cc>
        ret = dup_mmap(mm, oldmm);
ffffffffc020444a:	85ee                	mv	a1,s11
ffffffffc020444c:	856a                	mv	a0,s10
ffffffffc020444e:	c96ff0ef          	jal	ra,ffffffffc02038e4 <dup_mmap>
ffffffffc0204452:	8a2a                	mv	s4,a0
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204454:	57f9                	li	a5,-2
ffffffffc0204456:	60fbb7af          	amoand.d	a5,a5,(s7)
ffffffffc020445a:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020445c:	0c078c63          	beqz	a5,ffffffffc0204534 <do_fork+0x3c2>
good_mm:
ffffffffc0204460:	8dea                	mv	s11,s10
    if (ret != 0)
ffffffffc0204462:	dc0500e3          	beqz	a0,ffffffffc0204222 <do_fork+0xb0>
    exit_mmap(mm);
ffffffffc0204466:	856a                	mv	a0,s10
ffffffffc0204468:	d16ff0ef          	jal	ra,ffffffffc020397e <exit_mmap>
    put_pgdir(mm);
ffffffffc020446c:	856a                	mv	a0,s10
ffffffffc020446e:	c2bff0ef          	jal	ra,ffffffffc0204098 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204472:	856a                	mv	a0,s10
ffffffffc0204474:	b6eff0ef          	jal	ra,ffffffffc02037e2 <mm_destroy>
    if(copy_mm(clone_flags, proc) < 0)
ffffffffc0204478:	000a4f63          	bltz	s4,ffffffffc0204496 <do_fork+0x324>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020447c:	6894                	ld	a3,16(s1)
ffffffffc020447e:	b3e1                	j	ffffffffc0204246 <do_fork+0xd4>
        intr_enable();
ffffffffc0204480:	d2efc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204484:	bd45                	j	ffffffffc0204334 <do_fork+0x1c2>
                    if (last_pid >= MAX_PID)
ffffffffc0204486:	01d6c363          	blt	a3,t4,ffffffffc020448c <do_fork+0x31a>
                        last_pid = 1;
ffffffffc020448a:	4685                	li	a3,1
                    goto repeat;
ffffffffc020448c:	4585                	li	a1,1
ffffffffc020448e:	b5fd                	j	ffffffffc020437c <do_fork+0x20a>
    mm_destroy(mm);
ffffffffc0204490:	856a                	mv	a0,s10
ffffffffc0204492:	b50ff0ef          	jal	ra,ffffffffc02037e2 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204496:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc0204498:	c02007b7          	lui	a5,0xc0200
ffffffffc020449c:	08f6e063          	bltu	a3,a5,ffffffffc020451c <do_fork+0x3aa>
ffffffffc02044a0:	000cb783          	ld	a5,0(s9)
    if (PPN(pa) >= npage)
ffffffffc02044a4:	000c3703          	ld	a4,0(s8)
    return pa2page(PADDR(kva));
ffffffffc02044a8:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02044ac:	83b1                	srli	a5,a5,0xc
ffffffffc02044ae:	02e7fe63          	bgeu	a5,a4,ffffffffc02044ea <do_fork+0x378>
    return &pages[PPN(pa) - nbase];
ffffffffc02044b2:	00003717          	auipc	a4,0x3
ffffffffc02044b6:	57670713          	addi	a4,a4,1398 # ffffffffc0207a28 <nbase>
ffffffffc02044ba:	6318                	ld	a4,0(a4)
ffffffffc02044bc:	000b3503          	ld	a0,0(s6)
ffffffffc02044c0:	4589                	li	a1,2
ffffffffc02044c2:	8f99                	sub	a5,a5,a4
ffffffffc02044c4:	079a                	slli	a5,a5,0x6
ffffffffc02044c6:	953e                	add	a0,a0,a5
ffffffffc02044c8:	abffd0ef          	jal	ra,ffffffffc0201f86 <free_pages>
    kfree(proc);
ffffffffc02044cc:	8526                	mv	a0,s1
ffffffffc02044ce:	94dfd0ef          	jal	ra,ffffffffc0201e1a <kfree>
    ret = -E_NO_MEM;
ffffffffc02044d2:	5571                	li	a0,-4
    return ret;
ffffffffc02044d4:	b58d                	j	ffffffffc0204336 <do_fork+0x1c4>
ffffffffc02044d6:	c599                	beqz	a1,ffffffffc02044e4 <do_fork+0x372>
ffffffffc02044d8:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02044dc:	8536                	mv	a0,a3
ffffffffc02044de:	bbed                	j	ffffffffc02042d8 <do_fork+0x166>
    int ret = -E_NO_FREE_PROC;
ffffffffc02044e0:	556d                	li	a0,-5
ffffffffc02044e2:	bd91                	j	ffffffffc0204336 <do_fork+0x1c4>
    return last_pid;
ffffffffc02044e4:	00082503          	lw	a0,0(a6)
ffffffffc02044e8:	bbc5                	j	ffffffffc02042d8 <do_fork+0x166>
        panic("pa2page called with invalid pa");
ffffffffc02044ea:	00002617          	auipc	a2,0x2
ffffffffc02044ee:	36660613          	addi	a2,a2,870 # ffffffffc0206850 <default_pmm_manager+0x108>
ffffffffc02044f2:	06900593          	li	a1,105
ffffffffc02044f6:	00002517          	auipc	a0,0x2
ffffffffc02044fa:	2b250513          	addi	a0,a0,690 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc02044fe:	f91fb0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204502:	86be                	mv	a3,a5
ffffffffc0204504:	00002617          	auipc	a2,0x2
ffffffffc0204508:	32460613          	addi	a2,a2,804 # ffffffffc0206828 <default_pmm_manager+0xe0>
ffffffffc020450c:	19300593          	li	a1,403
ffffffffc0204510:	00003517          	auipc	a0,0x3
ffffffffc0204514:	c8050513          	addi	a0,a0,-896 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc0204518:	f77fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc020451c:	00002617          	auipc	a2,0x2
ffffffffc0204520:	30c60613          	addi	a2,a2,780 # ffffffffc0206828 <default_pmm_manager+0xe0>
ffffffffc0204524:	07700593          	li	a1,119
ffffffffc0204528:	00002517          	auipc	a0,0x2
ffffffffc020452c:	28050513          	addi	a0,a0,640 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc0204530:	f5ffb0ef          	jal	ra,ffffffffc020048e <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204534:	00003617          	auipc	a2,0x3
ffffffffc0204538:	c7460613          	addi	a2,a2,-908 # ffffffffc02071a8 <default_pmm_manager+0xa60>
ffffffffc020453c:	03f00593          	li	a1,63
ffffffffc0204540:	00003517          	auipc	a0,0x3
ffffffffc0204544:	c7850513          	addi	a0,a0,-904 # ffffffffc02071b8 <default_pmm_manager+0xa70>
ffffffffc0204548:	f47fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc020454c:	00002617          	auipc	a2,0x2
ffffffffc0204550:	23460613          	addi	a2,a2,564 # ffffffffc0206780 <default_pmm_manager+0x38>
ffffffffc0204554:	07100593          	li	a1,113
ffffffffc0204558:	00002517          	auipc	a0,0x2
ffffffffc020455c:	25050513          	addi	a0,a0,592 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc0204560:	f2ffb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204564 <kernel_thread>:
{
ffffffffc0204564:	7129                	addi	sp,sp,-320
ffffffffc0204566:	fa22                	sd	s0,304(sp)
ffffffffc0204568:	f626                	sd	s1,296(sp)
ffffffffc020456a:	f24a                	sd	s2,288(sp)
ffffffffc020456c:	84ae                	mv	s1,a1
ffffffffc020456e:	892a                	mv	s2,a0
ffffffffc0204570:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204572:	4581                	li	a1,0
ffffffffc0204574:	12000613          	li	a2,288
ffffffffc0204578:	850a                	mv	a0,sp
{
ffffffffc020457a:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020457c:	302010ef          	jal	ra,ffffffffc020587e <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204580:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204582:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204584:	100027f3          	csrr	a5,sstatus
ffffffffc0204588:	edd7f793          	andi	a5,a5,-291
ffffffffc020458c:	1207e793          	ori	a5,a5,288
ffffffffc0204590:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204592:	860a                	mv	a2,sp
ffffffffc0204594:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204598:	00000797          	auipc	a5,0x0
ffffffffc020459c:	9e078793          	addi	a5,a5,-1568 # ffffffffc0203f78 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02045a0:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02045a2:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02045a4:	bcfff0ef          	jal	ra,ffffffffc0204172 <do_fork>
}
ffffffffc02045a8:	70f2                	ld	ra,312(sp)
ffffffffc02045aa:	7452                	ld	s0,304(sp)
ffffffffc02045ac:	74b2                	ld	s1,296(sp)
ffffffffc02045ae:	7912                	ld	s2,288(sp)
ffffffffc02045b0:	6131                	addi	sp,sp,320
ffffffffc02045b2:	8082                	ret

ffffffffc02045b4 <do_exit>:
{
ffffffffc02045b4:	7179                	addi	sp,sp,-48
ffffffffc02045b6:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02045b8:	000a6417          	auipc	s0,0xa6
ffffffffc02045bc:	13040413          	addi	s0,s0,304 # ffffffffc02aa6e8 <current>
ffffffffc02045c0:	601c                	ld	a5,0(s0)
{
ffffffffc02045c2:	f406                	sd	ra,40(sp)
ffffffffc02045c4:	ec26                	sd	s1,24(sp)
ffffffffc02045c6:	e84a                	sd	s2,16(sp)
ffffffffc02045c8:	e44e                	sd	s3,8(sp)
ffffffffc02045ca:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc02045cc:	000a6717          	auipc	a4,0xa6
ffffffffc02045d0:	12473703          	ld	a4,292(a4) # ffffffffc02aa6f0 <idleproc>
ffffffffc02045d4:	0ce78c63          	beq	a5,a4,ffffffffc02046ac <do_exit+0xf8>
    if (current == initproc)
ffffffffc02045d8:	000a6497          	auipc	s1,0xa6
ffffffffc02045dc:	12048493          	addi	s1,s1,288 # ffffffffc02aa6f8 <initproc>
ffffffffc02045e0:	6098                	ld	a4,0(s1)
ffffffffc02045e2:	0ee78b63          	beq	a5,a4,ffffffffc02046d8 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc02045e6:	0287b983          	ld	s3,40(a5)
ffffffffc02045ea:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc02045ec:	02098663          	beqz	s3,ffffffffc0204618 <do_exit+0x64>
ffffffffc02045f0:	000a6797          	auipc	a5,0xa6
ffffffffc02045f4:	0c07b783          	ld	a5,192(a5) # ffffffffc02aa6b0 <boot_pgdir_pa>
ffffffffc02045f8:	577d                	li	a4,-1
ffffffffc02045fa:	177e                	slli	a4,a4,0x3f
ffffffffc02045fc:	83b1                	srli	a5,a5,0xc
ffffffffc02045fe:	8fd9                	or	a5,a5,a4
ffffffffc0204600:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204604:	0309a783          	lw	a5,48(s3)
ffffffffc0204608:	fff7871b          	addiw	a4,a5,-1
ffffffffc020460c:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204610:	cb55                	beqz	a4,ffffffffc02046c4 <do_exit+0x110>
        current->mm = NULL;
ffffffffc0204612:	601c                	ld	a5,0(s0)
ffffffffc0204614:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204618:	601c                	ld	a5,0(s0)
ffffffffc020461a:	470d                	li	a4,3
ffffffffc020461c:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc020461e:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204622:	100027f3          	csrr	a5,sstatus
ffffffffc0204626:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204628:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020462a:	e3f9                	bnez	a5,ffffffffc02046f0 <do_exit+0x13c>
        proc = current->parent;
ffffffffc020462c:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc020462e:	800007b7          	lui	a5,0x80000
ffffffffc0204632:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204634:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204636:	0ec52703          	lw	a4,236(a0)
ffffffffc020463a:	0af70f63          	beq	a4,a5,ffffffffc02046f8 <do_exit+0x144>
        while (current->cptr != NULL) // 遍历当前进程的所有子进程
ffffffffc020463e:	6018                	ld	a4,0(s0)
ffffffffc0204640:	7b7c                	ld	a5,240(a4)
ffffffffc0204642:	c3a1                	beqz	a5,ffffffffc0204682 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204644:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204648:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc020464a:	0985                	addi	s3,s3,1
ffffffffc020464c:	a021                	j	ffffffffc0204654 <do_exit+0xa0>
        while (current->cptr != NULL) // 遍历当前进程的所有子进程
ffffffffc020464e:	6018                	ld	a4,0(s0)
ffffffffc0204650:	7b7c                	ld	a5,240(a4)
ffffffffc0204652:	cb85                	beqz	a5,ffffffffc0204682 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204654:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fe8>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204658:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc020465a:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020465c:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc020465e:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204662:	10e7b023          	sd	a4,256(a5)
ffffffffc0204666:	c311                	beqz	a4,ffffffffc020466a <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204668:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020466a:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020466c:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020466e:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204670:	fd271fe3          	bne	a4,s2,ffffffffc020464e <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204674:	0ec52783          	lw	a5,236(a0)
ffffffffc0204678:	fd379be3          	bne	a5,s3,ffffffffc020464e <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc020467c:	371000ef          	jal	ra,ffffffffc02051ec <wakeup_proc>
ffffffffc0204680:	b7f9                	j	ffffffffc020464e <do_exit+0x9a>
    if (flag)
ffffffffc0204682:	020a1263          	bnez	s4,ffffffffc02046a6 <do_exit+0xf2>
    schedule(); // 调用调度器，选择新的进程执行
ffffffffc0204686:	3e7000ef          	jal	ra,ffffffffc020526c <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc020468a:	601c                	ld	a5,0(s0)
ffffffffc020468c:	00003617          	auipc	a2,0x3
ffffffffc0204690:	b6460613          	addi	a2,a2,-1180 # ffffffffc02071f0 <default_pmm_manager+0xaa8>
ffffffffc0204694:	26800593          	li	a1,616
ffffffffc0204698:	43d4                	lw	a3,4(a5)
ffffffffc020469a:	00003517          	auipc	a0,0x3
ffffffffc020469e:	af650513          	addi	a0,a0,-1290 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc02046a2:	dedfb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc02046a6:	b08fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02046aa:	bff1                	j	ffffffffc0204686 <do_exit+0xd2>
      panic("idleproc exit.\n");
ffffffffc02046ac:	00003617          	auipc	a2,0x3
ffffffffc02046b0:	b2460613          	addi	a2,a2,-1244 # ffffffffc02071d0 <default_pmm_manager+0xa88>
ffffffffc02046b4:	22700593          	li	a1,551
ffffffffc02046b8:	00003517          	auipc	a0,0x3
ffffffffc02046bc:	ad850513          	addi	a0,a0,-1320 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc02046c0:	dcffb0ef          	jal	ra,ffffffffc020048e <__panic>
          exit_mmap(mm);
ffffffffc02046c4:	854e                	mv	a0,s3
ffffffffc02046c6:	ab8ff0ef          	jal	ra,ffffffffc020397e <exit_mmap>
          put_pgdir(mm);
ffffffffc02046ca:	854e                	mv	a0,s3
ffffffffc02046cc:	9cdff0ef          	jal	ra,ffffffffc0204098 <put_pgdir>
          mm_destroy(mm);
ffffffffc02046d0:	854e                	mv	a0,s3
ffffffffc02046d2:	910ff0ef          	jal	ra,ffffffffc02037e2 <mm_destroy>
ffffffffc02046d6:	bf35                	j	ffffffffc0204612 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc02046d8:	00003617          	auipc	a2,0x3
ffffffffc02046dc:	b0860613          	addi	a2,a2,-1272 # ffffffffc02071e0 <default_pmm_manager+0xa98>
ffffffffc02046e0:	22b00593          	li	a1,555
ffffffffc02046e4:	00003517          	auipc	a0,0x3
ffffffffc02046e8:	aac50513          	addi	a0,a0,-1364 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc02046ec:	da3fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc02046f0:	ac4fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02046f4:	4a05                	li	s4,1
ffffffffc02046f6:	bf1d                	j	ffffffffc020462c <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc02046f8:	2f5000ef          	jal	ra,ffffffffc02051ec <wakeup_proc>
ffffffffc02046fc:	b789                	j	ffffffffc020463e <do_exit+0x8a>

ffffffffc02046fe <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc02046fe:	715d                	addi	sp,sp,-80
ffffffffc0204700:	f84a                	sd	s2,48(sp)
ffffffffc0204702:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc0204704:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204708:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc020470a:	fc26                	sd	s1,56(sp)
ffffffffc020470c:	f052                	sd	s4,32(sp)
ffffffffc020470e:	ec56                	sd	s5,24(sp)
ffffffffc0204710:	e85a                	sd	s6,16(sp)
ffffffffc0204712:	e45e                	sd	s7,8(sp)
ffffffffc0204714:	e486                	sd	ra,72(sp)
ffffffffc0204716:	e0a2                	sd	s0,64(sp)
ffffffffc0204718:	84aa                	mv	s1,a0
ffffffffc020471a:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc020471c:	000a6b97          	auipc	s7,0xa6
ffffffffc0204720:	fccb8b93          	addi	s7,s7,-52 # ffffffffc02aa6e8 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204724:	00050b1b          	sext.w	s6,a0
ffffffffc0204728:	fff50a9b          	addiw	s5,a0,-1
ffffffffc020472c:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc020472e:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204730:	ccbd                	beqz	s1,ffffffffc02047ae <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204732:	0359e863          	bltu	s3,s5,ffffffffc0204762 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204736:	45a9                	li	a1,10
ffffffffc0204738:	855a                	mv	a0,s6
ffffffffc020473a:	49f000ef          	jal	ra,ffffffffc02053d8 <hash32>
ffffffffc020473e:	02051793          	slli	a5,a0,0x20
ffffffffc0204742:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204746:	000a2797          	auipc	a5,0xa2
ffffffffc020474a:	f2278793          	addi	a5,a5,-222 # ffffffffc02a6668 <hash_list>
ffffffffc020474e:	953e                	add	a0,a0,a5
ffffffffc0204750:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204752:	a029                	j	ffffffffc020475c <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204754:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204758:	02978163          	beq	a5,s1,ffffffffc020477a <do_wait.part.0+0x7c>
ffffffffc020475c:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc020475e:	fe851be3          	bne	a0,s0,ffffffffc0204754 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc0204762:	5579                	li	a0,-2
}
ffffffffc0204764:	60a6                	ld	ra,72(sp)
ffffffffc0204766:	6406                	ld	s0,64(sp)
ffffffffc0204768:	74e2                	ld	s1,56(sp)
ffffffffc020476a:	7942                	ld	s2,48(sp)
ffffffffc020476c:	79a2                	ld	s3,40(sp)
ffffffffc020476e:	7a02                	ld	s4,32(sp)
ffffffffc0204770:	6ae2                	ld	s5,24(sp)
ffffffffc0204772:	6b42                	ld	s6,16(sp)
ffffffffc0204774:	6ba2                	ld	s7,8(sp)
ffffffffc0204776:	6161                	addi	sp,sp,80
ffffffffc0204778:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc020477a:	000bb683          	ld	a3,0(s7)
ffffffffc020477e:	f4843783          	ld	a5,-184(s0)
ffffffffc0204782:	fed790e3          	bne	a5,a3,ffffffffc0204762 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204786:	f2842703          	lw	a4,-216(s0)
ffffffffc020478a:	478d                	li	a5,3
ffffffffc020478c:	0ef70b63          	beq	a4,a5,ffffffffc0204882 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204790:	4785                	li	a5,1
ffffffffc0204792:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204794:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204798:	2d5000ef          	jal	ra,ffffffffc020526c <schedule>
        if (current->flags & PF_EXITING)
ffffffffc020479c:	000bb783          	ld	a5,0(s7)
ffffffffc02047a0:	0b07a783          	lw	a5,176(a5)
ffffffffc02047a4:	8b85                	andi	a5,a5,1
ffffffffc02047a6:	d7c9                	beqz	a5,ffffffffc0204730 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02047a8:	555d                	li	a0,-9
ffffffffc02047aa:	e0bff0ef          	jal	ra,ffffffffc02045b4 <do_exit>
        proc = current->cptr;
ffffffffc02047ae:	000bb683          	ld	a3,0(s7)
ffffffffc02047b2:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc02047b4:	d45d                	beqz	s0,ffffffffc0204762 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02047b6:	470d                	li	a4,3
ffffffffc02047b8:	a021                	j	ffffffffc02047c0 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc02047ba:	10043403          	ld	s0,256(s0)
ffffffffc02047be:	d869                	beqz	s0,ffffffffc0204790 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02047c0:	401c                	lw	a5,0(s0)
ffffffffc02047c2:	fee79ce3          	bne	a5,a4,ffffffffc02047ba <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc02047c6:	000a6797          	auipc	a5,0xa6
ffffffffc02047ca:	f2a7b783          	ld	a5,-214(a5) # ffffffffc02aa6f0 <idleproc>
ffffffffc02047ce:	0c878963          	beq	a5,s0,ffffffffc02048a0 <do_wait.part.0+0x1a2>
ffffffffc02047d2:	000a6797          	auipc	a5,0xa6
ffffffffc02047d6:	f267b783          	ld	a5,-218(a5) # ffffffffc02aa6f8 <initproc>
ffffffffc02047da:	0cf40363          	beq	s0,a5,ffffffffc02048a0 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc02047de:	000a0663          	beqz	s4,ffffffffc02047ea <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc02047e2:	0e842783          	lw	a5,232(s0)
ffffffffc02047e6:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02047ea:	100027f3          	csrr	a5,sstatus
ffffffffc02047ee:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02047f0:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02047f2:	e7c1                	bnez	a5,ffffffffc020487a <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02047f4:	6c70                	ld	a2,216(s0)
ffffffffc02047f6:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc02047f8:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc02047fc:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02047fe:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204800:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204802:	6470                	ld	a2,200(s0)
ffffffffc0204804:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204806:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204808:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc020480a:	c319                	beqz	a4,ffffffffc0204810 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc020480c:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc020480e:	7c7c                	ld	a5,248(s0)
ffffffffc0204810:	c3b5                	beqz	a5,ffffffffc0204874 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0204812:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc0204816:	000a6717          	auipc	a4,0xa6
ffffffffc020481a:	eea70713          	addi	a4,a4,-278 # ffffffffc02aa700 <nr_process>
ffffffffc020481e:	431c                	lw	a5,0(a4)
ffffffffc0204820:	37fd                	addiw	a5,a5,-1
ffffffffc0204822:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204824:	e5a9                	bnez	a1,ffffffffc020486e <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204826:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204828:	c02007b7          	lui	a5,0xc0200
ffffffffc020482c:	04f6ee63          	bltu	a3,a5,ffffffffc0204888 <do_wait.part.0+0x18a>
ffffffffc0204830:	000a6797          	auipc	a5,0xa6
ffffffffc0204834:	ea87b783          	ld	a5,-344(a5) # ffffffffc02aa6d8 <va_pa_offset>
ffffffffc0204838:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020483a:	82b1                	srli	a3,a3,0xc
ffffffffc020483c:	000a6797          	auipc	a5,0xa6
ffffffffc0204840:	e847b783          	ld	a5,-380(a5) # ffffffffc02aa6c0 <npage>
ffffffffc0204844:	06f6fa63          	bgeu	a3,a5,ffffffffc02048b8 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204848:	00003517          	auipc	a0,0x3
ffffffffc020484c:	1e053503          	ld	a0,480(a0) # ffffffffc0207a28 <nbase>
ffffffffc0204850:	8e89                	sub	a3,a3,a0
ffffffffc0204852:	069a                	slli	a3,a3,0x6
ffffffffc0204854:	000a6517          	auipc	a0,0xa6
ffffffffc0204858:	e7453503          	ld	a0,-396(a0) # ffffffffc02aa6c8 <pages>
ffffffffc020485c:	9536                	add	a0,a0,a3
ffffffffc020485e:	4589                	li	a1,2
ffffffffc0204860:	f26fd0ef          	jal	ra,ffffffffc0201f86 <free_pages>
    kfree(proc);
ffffffffc0204864:	8522                	mv	a0,s0
ffffffffc0204866:	db4fd0ef          	jal	ra,ffffffffc0201e1a <kfree>
    return 0;
ffffffffc020486a:	4501                	li	a0,0
ffffffffc020486c:	bde5                	j	ffffffffc0204764 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc020486e:	940fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204872:	bf55                	j	ffffffffc0204826 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204874:	701c                	ld	a5,32(s0)
ffffffffc0204876:	fbf8                	sd	a4,240(a5)
ffffffffc0204878:	bf79                	j	ffffffffc0204816 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc020487a:	93afc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc020487e:	4585                	li	a1,1
ffffffffc0204880:	bf95                	j	ffffffffc02047f4 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204882:	f2840413          	addi	s0,s0,-216
ffffffffc0204886:	b781                	j	ffffffffc02047c6 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204888:	00002617          	auipc	a2,0x2
ffffffffc020488c:	fa060613          	addi	a2,a2,-96 # ffffffffc0206828 <default_pmm_manager+0xe0>
ffffffffc0204890:	07700593          	li	a1,119
ffffffffc0204894:	00002517          	auipc	a0,0x2
ffffffffc0204898:	f1450513          	addi	a0,a0,-236 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc020489c:	bf3fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc02048a0:	00003617          	auipc	a2,0x3
ffffffffc02048a4:	97060613          	addi	a2,a2,-1680 # ffffffffc0207210 <default_pmm_manager+0xac8>
ffffffffc02048a8:	39700593          	li	a1,919
ffffffffc02048ac:	00003517          	auipc	a0,0x3
ffffffffc02048b0:	8e450513          	addi	a0,a0,-1820 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc02048b4:	bdbfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02048b8:	00002617          	auipc	a2,0x2
ffffffffc02048bc:	f9860613          	addi	a2,a2,-104 # ffffffffc0206850 <default_pmm_manager+0x108>
ffffffffc02048c0:	06900593          	li	a1,105
ffffffffc02048c4:	00002517          	auipc	a0,0x2
ffffffffc02048c8:	ee450513          	addi	a0,a0,-284 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc02048cc:	bc3fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02048d0 <init_main>:

// init_main - the second kernel thread used to create user_main kernel threads
// 初始化主函数 - 第二个内核线程，用于创建 user_main 内核线程
static int
init_main(void *arg)
{
ffffffffc02048d0:	1141                	addi	sp,sp,-16
ffffffffc02048d2:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02048d4:	ef2fd0ef          	jal	ra,ffffffffc0201fc6 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02048d8:	c8efd0ef          	jal	ra,ffffffffc0201d66 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02048dc:	4601                	li	a2,0
ffffffffc02048de:	4581                	li	a1,0
ffffffffc02048e0:	fffff517          	auipc	a0,0xfffff
ffffffffc02048e4:	73a50513          	addi	a0,a0,1850 # ffffffffc020401a <user_main>
ffffffffc02048e8:	c7dff0ef          	jal	ra,ffffffffc0204564 <kernel_thread>
    if (pid <= 0)
ffffffffc02048ec:	00a04563          	bgtz	a0,ffffffffc02048f6 <init_main+0x26>
ffffffffc02048f0:	a041                	j	ffffffffc0204970 <init_main+0xa0>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02048f2:	17b000ef          	jal	ra,ffffffffc020526c <schedule>
    if (code_store != NULL)
ffffffffc02048f6:	4581                	li	a1,0
ffffffffc02048f8:	4501                	li	a0,0
ffffffffc02048fa:	e05ff0ef          	jal	ra,ffffffffc02046fe <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02048fe:	d975                	beqz	a0,ffffffffc02048f2 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204900:	00003517          	auipc	a0,0x3
ffffffffc0204904:	95050513          	addi	a0,a0,-1712 # ffffffffc0207250 <default_pmm_manager+0xb08>
ffffffffc0204908:	88dfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(
ffffffffc020490c:	000a6797          	auipc	a5,0xa6
ffffffffc0204910:	dec7b783          	ld	a5,-532(a5) # ffffffffc02aa6f8 <initproc>
ffffffffc0204914:	7bf8                	ld	a4,240(a5)
ffffffffc0204916:	c30d                	beqz	a4,ffffffffc0204938 <init_main+0x68>
ffffffffc0204918:	00003697          	auipc	a3,0x3
ffffffffc020491c:	96068693          	addi	a3,a3,-1696 # ffffffffc0207278 <default_pmm_manager+0xb30>
ffffffffc0204920:	00002617          	auipc	a2,0x2
ffffffffc0204924:	a7860613          	addi	a2,a2,-1416 # ffffffffc0206398 <commands+0x888>
ffffffffc0204928:	41100593          	li	a1,1041
ffffffffc020492c:	00003517          	auipc	a0,0x3
ffffffffc0204930:	86450513          	addi	a0,a0,-1948 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc0204934:	b5bfb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204938:	7ff8                	ld	a4,248(a5)
ffffffffc020493a:	ff79                	bnez	a4,ffffffffc0204918 <init_main+0x48>
ffffffffc020493c:	1007b703          	ld	a4,256(a5)
ffffffffc0204940:	ff61                	bnez	a4,ffffffffc0204918 <init_main+0x48>
        initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
    assert(nr_process == 2);
ffffffffc0204942:	000a6697          	auipc	a3,0xa6
ffffffffc0204946:	dbe6a683          	lw	a3,-578(a3) # ffffffffc02aa700 <nr_process>
ffffffffc020494a:	4709                	li	a4,2
ffffffffc020494c:	02e68e63          	beq	a3,a4,ffffffffc0204988 <init_main+0xb8>
ffffffffc0204950:	00003697          	auipc	a3,0x3
ffffffffc0204954:	97868693          	addi	a3,a3,-1672 # ffffffffc02072c8 <default_pmm_manager+0xb80>
ffffffffc0204958:	00002617          	auipc	a2,0x2
ffffffffc020495c:	a4060613          	addi	a2,a2,-1472 # ffffffffc0206398 <commands+0x888>
ffffffffc0204960:	41300593          	li	a1,1043
ffffffffc0204964:	00003517          	auipc	a0,0x3
ffffffffc0204968:	82c50513          	addi	a0,a0,-2004 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc020496c:	b23fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204970:	00003617          	auipc	a2,0x3
ffffffffc0204974:	8c060613          	addi	a2,a2,-1856 # ffffffffc0207230 <default_pmm_manager+0xae8>
ffffffffc0204978:	40800593          	li	a1,1032
ffffffffc020497c:	00003517          	auipc	a0,0x3
ffffffffc0204980:	81450513          	addi	a0,a0,-2028 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc0204984:	b0bfb0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0204988:	000a6717          	auipc	a4,0xa6
ffffffffc020498c:	ce070713          	addi	a4,a4,-800 # ffffffffc02aa668 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204990:	6714                	ld	a3,8(a4)
ffffffffc0204992:	0c878793          	addi	a5,a5,200
ffffffffc0204996:	02d78263          	beq	a5,a3,ffffffffc02049ba <init_main+0xea>
ffffffffc020499a:	00003697          	auipc	a3,0x3
ffffffffc020499e:	93e68693          	addi	a3,a3,-1730 # ffffffffc02072d8 <default_pmm_manager+0xb90>
ffffffffc02049a2:	00002617          	auipc	a2,0x2
ffffffffc02049a6:	9f660613          	addi	a2,a2,-1546 # ffffffffc0206398 <commands+0x888>
ffffffffc02049aa:	41400593          	li	a1,1044
ffffffffc02049ae:	00002517          	auipc	a0,0x2
ffffffffc02049b2:	7e250513          	addi	a0,a0,2018 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc02049b6:	ad9fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02049ba:	6318                	ld	a4,0(a4)
ffffffffc02049bc:	02e78263          	beq	a5,a4,ffffffffc02049e0 <init_main+0x110>
ffffffffc02049c0:	00003697          	auipc	a3,0x3
ffffffffc02049c4:	94868693          	addi	a3,a3,-1720 # ffffffffc0207308 <default_pmm_manager+0xbc0>
ffffffffc02049c8:	00002617          	auipc	a2,0x2
ffffffffc02049cc:	9d060613          	addi	a2,a2,-1584 # ffffffffc0206398 <commands+0x888>
ffffffffc02049d0:	41500593          	li	a1,1045
ffffffffc02049d4:	00002517          	auipc	a0,0x2
ffffffffc02049d8:	7bc50513          	addi	a0,a0,1980 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc02049dc:	ab3fb0ef          	jal	ra,ffffffffc020048e <__panic>

    cprintf("init check memory pass.\n");
ffffffffc02049e0:	00003517          	auipc	a0,0x3
ffffffffc02049e4:	95850513          	addi	a0,a0,-1704 # ffffffffc0207338 <default_pmm_manager+0xbf0>
ffffffffc02049e8:	facfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    // LAB5: initproc 不应退出，否则会触发 panic；保持调度占位
    while (1)
    {
        schedule();
ffffffffc02049ec:	081000ef          	jal	ra,ffffffffc020526c <schedule>
    while (1)
ffffffffc02049f0:	bff5                	j	ffffffffc02049ec <init_main+0x11c>

ffffffffc02049f2 <do_execve>:
{
ffffffffc02049f2:	7171                	addi	sp,sp,-176
ffffffffc02049f4:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02049f6:	000a6d97          	auipc	s11,0xa6
ffffffffc02049fa:	cf2d8d93          	addi	s11,s11,-782 # ffffffffc02aa6e8 <current>
ffffffffc02049fe:	000db783          	ld	a5,0(s11)
{
ffffffffc0204a02:	e94a                	sd	s2,144(sp)
ffffffffc0204a04:	f122                	sd	s0,160(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204a06:	0287b903          	ld	s2,40(a5)
{
ffffffffc0204a0a:	ed26                	sd	s1,152(sp)
ffffffffc0204a0c:	f8da                	sd	s6,112(sp)
ffffffffc0204a0e:	84aa                	mv	s1,a0
ffffffffc0204a10:	8b32                	mv	s6,a2
ffffffffc0204a12:	842e                	mv	s0,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) // 检查name的内存空间能否被访问return -E_INVAL;
ffffffffc0204a14:	862e                	mv	a2,a1
ffffffffc0204a16:	4681                	li	a3,0
ffffffffc0204a18:	85aa                	mv	a1,a0
ffffffffc0204a1a:	854a                	mv	a0,s2
{
ffffffffc0204a1c:	f506                	sd	ra,168(sp)
ffffffffc0204a1e:	e54e                	sd	s3,136(sp)
ffffffffc0204a20:	e152                	sd	s4,128(sp)
ffffffffc0204a22:	fcd6                	sd	s5,120(sp)
ffffffffc0204a24:	f4de                	sd	s7,104(sp)
ffffffffc0204a26:	f0e2                	sd	s8,96(sp)
ffffffffc0204a28:	ece6                	sd	s9,88(sp)
ffffffffc0204a2a:	e8ea                	sd	s10,80(sp)
ffffffffc0204a2c:	f05a                	sd	s6,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) // 检查name的内存空间能否被访问return -E_INVAL;
ffffffffc0204a2e:	cb6ff0ef          	jal	ra,ffffffffc0203ee4 <user_mem_check>
ffffffffc0204a32:	40050a63          	beqz	a0,ffffffffc0204e46 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204a36:	4641                	li	a2,16
ffffffffc0204a38:	4581                	li	a1,0
ffffffffc0204a3a:	1808                	addi	a0,sp,48
ffffffffc0204a3c:	643000ef          	jal	ra,ffffffffc020587e <memset>
    memcpy(local_name, name, len);
ffffffffc0204a40:	47bd                	li	a5,15
ffffffffc0204a42:	8622                	mv	a2,s0
ffffffffc0204a44:	1e87e263          	bltu	a5,s0,ffffffffc0204c28 <do_execve+0x236>
ffffffffc0204a48:	85a6                	mv	a1,s1
ffffffffc0204a4a:	1808                	addi	a0,sp,48
ffffffffc0204a4c:	645000ef          	jal	ra,ffffffffc0205890 <memcpy>
    if (mm != NULL)
ffffffffc0204a50:	1e090363          	beqz	s2,ffffffffc0204c36 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0204a54:	00002517          	auipc	a0,0x2
ffffffffc0204a58:	50450513          	addi	a0,a0,1284 # ffffffffc0206f58 <default_pmm_manager+0x810>
ffffffffc0204a5c:	f70fb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc0204a60:	000a6797          	auipc	a5,0xa6
ffffffffc0204a64:	c507b783          	ld	a5,-944(a5) # ffffffffc02aa6b0 <boot_pgdir_pa>
ffffffffc0204a68:	577d                	li	a4,-1
ffffffffc0204a6a:	177e                	slli	a4,a4,0x3f
ffffffffc0204a6c:	83b1                	srli	a5,a5,0xc
ffffffffc0204a6e:	8fd9                	or	a5,a5,a4
ffffffffc0204a70:	18079073          	csrw	satp,a5
ffffffffc0204a74:	03092783          	lw	a5,48(s2) # ffffffff80000030 <_binary_obj___user_exit_out_size+0xffffffff7fff4f18>
ffffffffc0204a78:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204a7c:	02e92823          	sw	a4,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204a80:	2c070463          	beqz	a4,ffffffffc0204d48 <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204a84:	000db783          	ld	a5,0(s11)
ffffffffc0204a88:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204a8c:	c17fe0ef          	jal	ra,ffffffffc02036a2 <mm_create>
ffffffffc0204a90:	842a                	mv	s0,a0
ffffffffc0204a92:	1c050d63          	beqz	a0,ffffffffc0204c6c <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204a96:	4505                	li	a0,1
ffffffffc0204a98:	cb0fd0ef          	jal	ra,ffffffffc0201f48 <alloc_pages>
ffffffffc0204a9c:	3a050963          	beqz	a0,ffffffffc0204e4e <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0204aa0:	000a6c97          	auipc	s9,0xa6
ffffffffc0204aa4:	c28c8c93          	addi	s9,s9,-984 # ffffffffc02aa6c8 <pages>
ffffffffc0204aa8:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204aac:	000a6c17          	auipc	s8,0xa6
ffffffffc0204ab0:	c14c0c13          	addi	s8,s8,-1004 # ffffffffc02aa6c0 <npage>
    return page - pages + nbase;
ffffffffc0204ab4:	00003717          	auipc	a4,0x3
ffffffffc0204ab8:	f7473703          	ld	a4,-140(a4) # ffffffffc0207a28 <nbase>
ffffffffc0204abc:	40d506b3          	sub	a3,a0,a3
ffffffffc0204ac0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204ac2:	5a7d                	li	s4,-1
ffffffffc0204ac4:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204ac8:	96ba                	add	a3,a3,a4
ffffffffc0204aca:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204acc:	00ca5713          	srli	a4,s4,0xc
ffffffffc0204ad0:	ec3a                	sd	a4,24(sp)
ffffffffc0204ad2:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ad4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204ad6:	38f77063          	bgeu	a4,a5,ffffffffc0204e56 <do_execve+0x464>
ffffffffc0204ada:	000a6a97          	auipc	s5,0xa6
ffffffffc0204ade:	bfea8a93          	addi	s5,s5,-1026 # ffffffffc02aa6d8 <va_pa_offset>
ffffffffc0204ae2:	000ab483          	ld	s1,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204ae6:	6605                	lui	a2,0x1
ffffffffc0204ae8:	000a6597          	auipc	a1,0xa6
ffffffffc0204aec:	bd05b583          	ld	a1,-1072(a1) # ffffffffc02aa6b8 <boot_pgdir_va>
ffffffffc0204af0:	94b6                	add	s1,s1,a3
ffffffffc0204af2:	8526                	mv	a0,s1
ffffffffc0204af4:	59d000ef          	jal	ra,ffffffffc0205890 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204af8:	7782                	ld	a5,32(sp)
ffffffffc0204afa:	4398                	lw	a4,0(a5)
ffffffffc0204afc:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204b00:	ec04                	sd	s1,24(s0)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204b02:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9467>
ffffffffc0204b06:	14f71963          	bne	a4,a5,ffffffffc0204c58 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204b0a:	7682                	ld	a3,32(sp)
    struct Page *page = NULL;
ffffffffc0204b0c:	4b81                	li	s7,0
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204b0e:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204b12:	0206b903          	ld	s2,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204b16:	00371793          	slli	a5,a4,0x3
ffffffffc0204b1a:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204b1c:	9936                	add	s2,s2,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204b1e:	078e                	slli	a5,a5,0x3
ffffffffc0204b20:	97ca                	add	a5,a5,s2
ffffffffc0204b22:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204b24:	00f97c63          	bgeu	s2,a5,ffffffffc0204b3c <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)// 只处理可加载的 program 段
ffffffffc0204b28:	00092783          	lw	a5,0(s2)
ffffffffc0204b2c:	4705                	li	a4,1
ffffffffc0204b2e:	14e78163          	beq	a5,a4,ffffffffc0204c70 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc0204b32:	77a2                	ld	a5,40(sp)
ffffffffc0204b34:	03890913          	addi	s2,s2,56
ffffffffc0204b38:	fef968e3          	bltu	s2,a5,ffffffffc0204b28 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204b3c:	4701                	li	a4,0
ffffffffc0204b3e:	46ad                	li	a3,11
ffffffffc0204b40:	00100637          	lui	a2,0x100
ffffffffc0204b44:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204b48:	8522                	mv	a0,s0
ffffffffc0204b4a:	cebfe0ef          	jal	ra,ffffffffc0203834 <mm_map>
ffffffffc0204b4e:	89aa                	mv	s3,a0
ffffffffc0204b50:	1e051263          	bnez	a0,ffffffffc0204d34 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204b54:	6c08                	ld	a0,24(s0)
ffffffffc0204b56:	467d                	li	a2,31
ffffffffc0204b58:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204b5c:	a61fe0ef          	jal	ra,ffffffffc02035bc <pgdir_alloc_page>
ffffffffc0204b60:	38050363          	beqz	a0,ffffffffc0204ee6 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b64:	6c08                	ld	a0,24(s0)
ffffffffc0204b66:	467d                	li	a2,31
ffffffffc0204b68:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204b6c:	a51fe0ef          	jal	ra,ffffffffc02035bc <pgdir_alloc_page>
ffffffffc0204b70:	34050b63          	beqz	a0,ffffffffc0204ec6 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b74:	6c08                	ld	a0,24(s0)
ffffffffc0204b76:	467d                	li	a2,31
ffffffffc0204b78:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204b7c:	a41fe0ef          	jal	ra,ffffffffc02035bc <pgdir_alloc_page>
ffffffffc0204b80:	32050363          	beqz	a0,ffffffffc0204ea6 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b84:	6c08                	ld	a0,24(s0)
ffffffffc0204b86:	467d                	li	a2,31
ffffffffc0204b88:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204b8c:	a31fe0ef          	jal	ra,ffffffffc02035bc <pgdir_alloc_page>
ffffffffc0204b90:	2e050b63          	beqz	a0,ffffffffc0204e86 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204b94:	581c                	lw	a5,48(s0)
    current->mm = mm;
ffffffffc0204b96:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b9a:	6c14                	ld	a3,24(s0)
ffffffffc0204b9c:	2785                	addiw	a5,a5,1
ffffffffc0204b9e:	d81c                	sw	a5,48(s0)
    current->mm = mm;
ffffffffc0204ba0:	f600                	sd	s0,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204ba2:	c02007b7          	lui	a5,0xc0200
ffffffffc0204ba6:	2cf6e463          	bltu	a3,a5,ffffffffc0204e6e <do_execve+0x47c>
ffffffffc0204baa:	000ab783          	ld	a5,0(s5)
ffffffffc0204bae:	577d                	li	a4,-1
ffffffffc0204bb0:	177e                	slli	a4,a4,0x3f
ffffffffc0204bb2:	8e9d                	sub	a3,a3,a5
ffffffffc0204bb4:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204bb8:	f654                	sd	a3,168(a2)
ffffffffc0204bba:	8fd9                	or	a5,a5,a4
ffffffffc0204bbc:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204bc0:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204bc2:	4581                	li	a1,0
ffffffffc0204bc4:	12000613          	li	a2,288
ffffffffc0204bc8:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204bca:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204bce:	4b1000ef          	jal	ra,ffffffffc020587e <memset>
    tf->epc = elf->e_entry;                // entry address of user program
ffffffffc0204bd2:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bd4:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE; // return to U-mode with interrupts enabled after sret
ffffffffc0204bd8:	edd4f493          	andi	s1,s1,-291
    tf->epc = elf->e_entry;                // entry address of user program
ffffffffc0204bdc:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;                // user stack pointer
ffffffffc0204bde:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204be0:	0b490913          	addi	s2,s2,180
    tf->gpr.sp = USTACKTOP;                // user stack pointer
ffffffffc0204be4:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE; // return to U-mode with interrupts enabled after sret
ffffffffc0204be6:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bea:	4641                	li	a2,16
ffffffffc0204bec:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;                // user stack pointer
ffffffffc0204bee:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;                // entry address of user program
ffffffffc0204bf0:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE; // return to U-mode with interrupts enabled after sret
ffffffffc0204bf4:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bf8:	854a                	mv	a0,s2
ffffffffc0204bfa:	485000ef          	jal	ra,ffffffffc020587e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204bfe:	463d                	li	a2,15
ffffffffc0204c00:	180c                	addi	a1,sp,48
ffffffffc0204c02:	854a                	mv	a0,s2
ffffffffc0204c04:	48d000ef          	jal	ra,ffffffffc0205890 <memcpy>
}
ffffffffc0204c08:	70aa                	ld	ra,168(sp)
ffffffffc0204c0a:	740a                	ld	s0,160(sp)
ffffffffc0204c0c:	64ea                	ld	s1,152(sp)
ffffffffc0204c0e:	694a                	ld	s2,144(sp)
ffffffffc0204c10:	6a0a                	ld	s4,128(sp)
ffffffffc0204c12:	7ae6                	ld	s5,120(sp)
ffffffffc0204c14:	7b46                	ld	s6,112(sp)
ffffffffc0204c16:	7ba6                	ld	s7,104(sp)
ffffffffc0204c18:	7c06                	ld	s8,96(sp)
ffffffffc0204c1a:	6ce6                	ld	s9,88(sp)
ffffffffc0204c1c:	6d46                	ld	s10,80(sp)
ffffffffc0204c1e:	6da6                	ld	s11,72(sp)
ffffffffc0204c20:	854e                	mv	a0,s3
ffffffffc0204c22:	69aa                	ld	s3,136(sp)
ffffffffc0204c24:	614d                	addi	sp,sp,176
ffffffffc0204c26:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204c28:	463d                	li	a2,15
ffffffffc0204c2a:	85a6                	mv	a1,s1
ffffffffc0204c2c:	1808                	addi	a0,sp,48
ffffffffc0204c2e:	463000ef          	jal	ra,ffffffffc0205890 <memcpy>
    if (mm != NULL)
ffffffffc0204c32:	e20911e3          	bnez	s2,ffffffffc0204a54 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204c36:	000db783          	ld	a5,0(s11)
ffffffffc0204c3a:	779c                	ld	a5,40(a5)
ffffffffc0204c3c:	e40788e3          	beqz	a5,ffffffffc0204a8c <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204c40:	00002617          	auipc	a2,0x2
ffffffffc0204c44:	71860613          	addi	a2,a2,1816 # ffffffffc0207358 <default_pmm_manager+0xc10>
ffffffffc0204c48:	27400593          	li	a1,628
ffffffffc0204c4c:	00002517          	auipc	a0,0x2
ffffffffc0204c50:	54450513          	addi	a0,a0,1348 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc0204c54:	83bfb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204c58:	8522                	mv	a0,s0
ffffffffc0204c5a:	c3eff0ef          	jal	ra,ffffffffc0204098 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204c5e:	8522                	mv	a0,s0
ffffffffc0204c60:	b83fe0ef          	jal	ra,ffffffffc02037e2 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204c64:	59e1                	li	s3,-8
    do_exit(ret);// 失败就退出当前进程
ffffffffc0204c66:	854e                	mv	a0,s3
ffffffffc0204c68:	94dff0ef          	jal	ra,ffffffffc02045b4 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204c6c:	59f1                	li	s3,-4
ffffffffc0204c6e:	bfe5                	j	ffffffffc0204c66 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)// 文件大小不能大于内存大小
ffffffffc0204c70:	02893603          	ld	a2,40(s2)
ffffffffc0204c74:	02093783          	ld	a5,32(s2)
ffffffffc0204c78:	1cf66d63          	bltu	a2,a5,ffffffffc0204e52 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204c7c:	00492783          	lw	a5,4(s2)
ffffffffc0204c80:	0017f693          	andi	a3,a5,1
ffffffffc0204c84:	c291                	beqz	a3,ffffffffc0204c88 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204c86:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c88:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c8c:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c8e:	e779                	bnez	a4,ffffffffc0204d5c <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204c90:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c92:	c781                	beqz	a5,ffffffffc0204c9a <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204c94:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204c98:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204c9a:	0026f793          	andi	a5,a3,2
ffffffffc0204c9e:	e3f1                	bnez	a5,ffffffffc0204d62 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204ca0:	0046f793          	andi	a5,a3,4
ffffffffc0204ca4:	c399                	beqz	a5,ffffffffc0204caa <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204ca6:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204caa:	01093583          	ld	a1,16(s2)
ffffffffc0204cae:	4701                	li	a4,0
ffffffffc0204cb0:	8522                	mv	a0,s0
ffffffffc0204cb2:	b83fe0ef          	jal	ra,ffffffffc0203834 <mm_map>
ffffffffc0204cb6:	89aa                	mv	s3,a0
ffffffffc0204cb8:	ed35                	bnez	a0,ffffffffc0204d34 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204cba:	01093b03          	ld	s6,16(s2)
ffffffffc0204cbe:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204cc0:	02093983          	ld	s3,32(s2)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204cc4:	00893483          	ld	s1,8(s2)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204cc8:	00fb7a33          	and	s4,s6,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204ccc:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204cce:	99da                	add	s3,s3,s6
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204cd0:	94be                	add	s1,s1,a5
        while (start < end)
ffffffffc0204cd2:	053b6963          	bltu	s6,s3,ffffffffc0204d24 <do_execve+0x332>
ffffffffc0204cd6:	aa95                	j	ffffffffc0204e4a <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204cd8:	6785                	lui	a5,0x1
ffffffffc0204cda:	414b0533          	sub	a0,s6,s4
ffffffffc0204cde:	9a3e                	add	s4,s4,a5
ffffffffc0204ce0:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc0204ce4:	0149f463          	bgeu	s3,s4,ffffffffc0204cec <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204ce8:	41698633          	sub	a2,s3,s6
    return page - pages + nbase;
ffffffffc0204cec:	000cb683          	ld	a3,0(s9)
ffffffffc0204cf0:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204cf2:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204cf6:	40db86b3          	sub	a3,s7,a3
ffffffffc0204cfa:	8699                	srai	a3,a3,0x6
ffffffffc0204cfc:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204cfe:	67e2                	ld	a5,24(sp)
ffffffffc0204d00:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d04:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d06:	14b8f863          	bgeu	a7,a1,ffffffffc0204e56 <do_execve+0x464>
ffffffffc0204d0a:	000ab883          	ld	a7,0(s5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204d0e:	85a6                	mv	a1,s1
            start += size, from += size;
ffffffffc0204d10:	9b32                	add	s6,s6,a2
ffffffffc0204d12:	96c6                	add	a3,a3,a7
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204d14:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204d16:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204d18:	379000ef          	jal	ra,ffffffffc0205890 <memcpy>
            start += size, from += size;
ffffffffc0204d1c:	6622                	ld	a2,8(sp)
ffffffffc0204d1e:	94b2                	add	s1,s1,a2
        while (start < end)
ffffffffc0204d20:	053b7363          	bgeu	s6,s3,ffffffffc0204d66 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204d24:	6c08                	ld	a0,24(s0)
ffffffffc0204d26:	866a                	mv	a2,s10
ffffffffc0204d28:	85d2                	mv	a1,s4
ffffffffc0204d2a:	893fe0ef          	jal	ra,ffffffffc02035bc <pgdir_alloc_page>
ffffffffc0204d2e:	8baa                	mv	s7,a0
ffffffffc0204d30:	f545                	bnez	a0,ffffffffc0204cd8 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204d32:	59f1                	li	s3,-4
    exit_mmap(mm);
ffffffffc0204d34:	8522                	mv	a0,s0
ffffffffc0204d36:	c49fe0ef          	jal	ra,ffffffffc020397e <exit_mmap>
    put_pgdir(mm);
ffffffffc0204d3a:	8522                	mv	a0,s0
ffffffffc0204d3c:	b5cff0ef          	jal	ra,ffffffffc0204098 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204d40:	8522                	mv	a0,s0
ffffffffc0204d42:	aa1fe0ef          	jal	ra,ffffffffc02037e2 <mm_destroy>
    return ret;
ffffffffc0204d46:	b705                	j	ffffffffc0204c66 <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204d48:	854a                	mv	a0,s2
ffffffffc0204d4a:	c35fe0ef          	jal	ra,ffffffffc020397e <exit_mmap>
            put_pgdir(mm);
ffffffffc0204d4e:	854a                	mv	a0,s2
ffffffffc0204d50:	b48ff0ef          	jal	ra,ffffffffc0204098 <put_pgdir>
            mm_destroy(mm); // 把进程当前占用的内存释放，之后重新分配内存
ffffffffc0204d54:	854a                	mv	a0,s2
ffffffffc0204d56:	a8dfe0ef          	jal	ra,ffffffffc02037e2 <mm_destroy>
ffffffffc0204d5a:	b32d                	j	ffffffffc0204a84 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204d5c:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204d60:	fb95                	bnez	a5,ffffffffc0204c94 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204d62:	4d5d                	li	s10,23
ffffffffc0204d64:	bf35                	j	ffffffffc0204ca0 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204d66:	01093483          	ld	s1,16(s2)
ffffffffc0204d6a:	02893683          	ld	a3,40(s2)
ffffffffc0204d6e:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204d70:	074b7d63          	bgeu	s6,s4,ffffffffc0204dea <do_execve+0x3f8>
            if (start == end)
ffffffffc0204d74:	db648fe3          	beq	s1,s6,ffffffffc0204b32 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204d78:	6785                	lui	a5,0x1
ffffffffc0204d7a:	00fb0533          	add	a0,s6,a5
ffffffffc0204d7e:	41450533          	sub	a0,a0,s4
                size -= la - end;
ffffffffc0204d82:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204d86:	0b44fd63          	bgeu	s1,s4,ffffffffc0204e40 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204d8a:	000cb683          	ld	a3,0(s9)
ffffffffc0204d8e:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204d90:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204d94:	40db86b3          	sub	a3,s7,a3
ffffffffc0204d98:	8699                	srai	a3,a3,0x6
ffffffffc0204d9a:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204d9c:	67e2                	ld	a5,24(sp)
ffffffffc0204d9e:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204da2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204da4:	0ac5f963          	bgeu	a1,a2,ffffffffc0204e56 <do_execve+0x464>
ffffffffc0204da8:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204dac:	864e                	mv	a2,s3
ffffffffc0204dae:	4581                	li	a1,0
ffffffffc0204db0:	96c6                	add	a3,a3,a7
ffffffffc0204db2:	9536                	add	a0,a0,a3
ffffffffc0204db4:	2cb000ef          	jal	ra,ffffffffc020587e <memset>
            start += size;
ffffffffc0204db8:	01698733          	add	a4,s3,s6
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204dbc:	0344f463          	bgeu	s1,s4,ffffffffc0204de4 <do_execve+0x3f2>
ffffffffc0204dc0:	d6e489e3          	beq	s1,a4,ffffffffc0204b32 <do_execve+0x140>
ffffffffc0204dc4:	00002697          	auipc	a3,0x2
ffffffffc0204dc8:	5bc68693          	addi	a3,a3,1468 # ffffffffc0207380 <default_pmm_manager+0xc38>
ffffffffc0204dcc:	00001617          	auipc	a2,0x1
ffffffffc0204dd0:	5cc60613          	addi	a2,a2,1484 # ffffffffc0206398 <commands+0x888>
ffffffffc0204dd4:	2de00593          	li	a1,734
ffffffffc0204dd8:	00002517          	auipc	a0,0x2
ffffffffc0204ddc:	3b850513          	addi	a0,a0,952 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc0204de0:	eaefb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204de4:	ff4710e3          	bne	a4,s4,ffffffffc0204dc4 <do_execve+0x3d2>
ffffffffc0204de8:	8b52                	mv	s6,s4
        while (start < end)
ffffffffc0204dea:	d49b74e3          	bgeu	s6,s1,ffffffffc0204b32 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204dee:	6c08                	ld	a0,24(s0)
ffffffffc0204df0:	866a                	mv	a2,s10
ffffffffc0204df2:	85d2                	mv	a1,s4
ffffffffc0204df4:	fc8fe0ef          	jal	ra,ffffffffc02035bc <pgdir_alloc_page>
ffffffffc0204df8:	8baa                	mv	s7,a0
ffffffffc0204dfa:	dd05                	beqz	a0,ffffffffc0204d32 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204dfc:	6785                	lui	a5,0x1
ffffffffc0204dfe:	414b0533          	sub	a0,s6,s4
ffffffffc0204e02:	9a3e                	add	s4,s4,a5
ffffffffc0204e04:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc0204e08:	0144f463          	bgeu	s1,s4,ffffffffc0204e10 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204e0c:	41648633          	sub	a2,s1,s6
    return page - pages + nbase;
ffffffffc0204e10:	000cb683          	ld	a3,0(s9)
ffffffffc0204e14:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204e16:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204e1a:	40db86b3          	sub	a3,s7,a3
ffffffffc0204e1e:	8699                	srai	a3,a3,0x6
ffffffffc0204e20:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204e22:	67e2                	ld	a5,24(sp)
ffffffffc0204e24:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e28:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204e2a:	02b8f663          	bgeu	a7,a1,ffffffffc0204e56 <do_execve+0x464>
ffffffffc0204e2e:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204e32:	4581                	li	a1,0
            start += size;
ffffffffc0204e34:	9b32                	add	s6,s6,a2
ffffffffc0204e36:	96c6                	add	a3,a3,a7
            memset(page2kva(page) + off, 0, size);
ffffffffc0204e38:	9536                	add	a0,a0,a3
ffffffffc0204e3a:	245000ef          	jal	ra,ffffffffc020587e <memset>
ffffffffc0204e3e:	b775                	j	ffffffffc0204dea <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204e40:	416a09b3          	sub	s3,s4,s6
ffffffffc0204e44:	b799                	j	ffffffffc0204d8a <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204e46:	59f5                	li	s3,-3
ffffffffc0204e48:	b3c1                	j	ffffffffc0204c08 <do_execve+0x216>
        while (start < end)
ffffffffc0204e4a:	84da                	mv	s1,s6
ffffffffc0204e4c:	bf39                	j	ffffffffc0204d6a <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204e4e:	59f1                	li	s3,-4
ffffffffc0204e50:	bdc5                	j	ffffffffc0204d40 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204e52:	59e1                	li	s3,-8
ffffffffc0204e54:	b5c5                	j	ffffffffc0204d34 <do_execve+0x342>
ffffffffc0204e56:	00002617          	auipc	a2,0x2
ffffffffc0204e5a:	92a60613          	addi	a2,a2,-1750 # ffffffffc0206780 <default_pmm_manager+0x38>
ffffffffc0204e5e:	07100593          	li	a1,113
ffffffffc0204e62:	00002517          	auipc	a0,0x2
ffffffffc0204e66:	94650513          	addi	a0,a0,-1722 # ffffffffc02067a8 <default_pmm_manager+0x60>
ffffffffc0204e6a:	e24fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204e6e:	00002617          	auipc	a2,0x2
ffffffffc0204e72:	9ba60613          	addi	a2,a2,-1606 # ffffffffc0206828 <default_pmm_manager+0xe0>
ffffffffc0204e76:	2fd00593          	li	a1,765
ffffffffc0204e7a:	00002517          	auipc	a0,0x2
ffffffffc0204e7e:	31650513          	addi	a0,a0,790 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc0204e82:	e0cfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e86:	00002697          	auipc	a3,0x2
ffffffffc0204e8a:	61268693          	addi	a3,a3,1554 # ffffffffc0207498 <default_pmm_manager+0xd50>
ffffffffc0204e8e:	00001617          	auipc	a2,0x1
ffffffffc0204e92:	50a60613          	addi	a2,a2,1290 # ffffffffc0206398 <commands+0x888>
ffffffffc0204e96:	2f800593          	li	a1,760
ffffffffc0204e9a:	00002517          	auipc	a0,0x2
ffffffffc0204e9e:	2f650513          	addi	a0,a0,758 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc0204ea2:	decfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ea6:	00002697          	auipc	a3,0x2
ffffffffc0204eaa:	5aa68693          	addi	a3,a3,1450 # ffffffffc0207450 <default_pmm_manager+0xd08>
ffffffffc0204eae:	00001617          	auipc	a2,0x1
ffffffffc0204eb2:	4ea60613          	addi	a2,a2,1258 # ffffffffc0206398 <commands+0x888>
ffffffffc0204eb6:	2f700593          	li	a1,759
ffffffffc0204eba:	00002517          	auipc	a0,0x2
ffffffffc0204ebe:	2d650513          	addi	a0,a0,726 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc0204ec2:	dccfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ec6:	00002697          	auipc	a3,0x2
ffffffffc0204eca:	54268693          	addi	a3,a3,1346 # ffffffffc0207408 <default_pmm_manager+0xcc0>
ffffffffc0204ece:	00001617          	auipc	a2,0x1
ffffffffc0204ed2:	4ca60613          	addi	a2,a2,1226 # ffffffffc0206398 <commands+0x888>
ffffffffc0204ed6:	2f600593          	li	a1,758
ffffffffc0204eda:	00002517          	auipc	a0,0x2
ffffffffc0204ede:	2b650513          	addi	a0,a0,694 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc0204ee2:	dacfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204ee6:	00002697          	auipc	a3,0x2
ffffffffc0204eea:	4da68693          	addi	a3,a3,1242 # ffffffffc02073c0 <default_pmm_manager+0xc78>
ffffffffc0204eee:	00001617          	auipc	a2,0x1
ffffffffc0204ef2:	4aa60613          	addi	a2,a2,1194 # ffffffffc0206398 <commands+0x888>
ffffffffc0204ef6:	2f500593          	li	a1,757
ffffffffc0204efa:	00002517          	auipc	a0,0x2
ffffffffc0204efe:	29650513          	addi	a0,a0,662 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc0204f02:	d8cfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204f06 <do_yield>:
    current->need_resched = 1;
ffffffffc0204f06:	000a5797          	auipc	a5,0xa5
ffffffffc0204f0a:	7e27b783          	ld	a5,2018(a5) # ffffffffc02aa6e8 <current>
ffffffffc0204f0e:	4705                	li	a4,1
ffffffffc0204f10:	ef98                	sd	a4,24(a5)
}
ffffffffc0204f12:	4501                	li	a0,0
ffffffffc0204f14:	8082                	ret

ffffffffc0204f16 <do_wait>:
{
ffffffffc0204f16:	1101                	addi	sp,sp,-32
ffffffffc0204f18:	e822                	sd	s0,16(sp)
ffffffffc0204f1a:	e426                	sd	s1,8(sp)
ffffffffc0204f1c:	ec06                	sd	ra,24(sp)
ffffffffc0204f1e:	842e                	mv	s0,a1
ffffffffc0204f20:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204f22:	c999                	beqz	a1,ffffffffc0204f38 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204f24:	000a5797          	auipc	a5,0xa5
ffffffffc0204f28:	7c47b783          	ld	a5,1988(a5) # ffffffffc02aa6e8 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204f2c:	7788                	ld	a0,40(a5)
ffffffffc0204f2e:	4685                	li	a3,1
ffffffffc0204f30:	4611                	li	a2,4
ffffffffc0204f32:	fb3fe0ef          	jal	ra,ffffffffc0203ee4 <user_mem_check>
ffffffffc0204f36:	c909                	beqz	a0,ffffffffc0204f48 <do_wait+0x32>
ffffffffc0204f38:	85a2                	mv	a1,s0
}
ffffffffc0204f3a:	6442                	ld	s0,16(sp)
ffffffffc0204f3c:	60e2                	ld	ra,24(sp)
ffffffffc0204f3e:	8526                	mv	a0,s1
ffffffffc0204f40:	64a2                	ld	s1,8(sp)
ffffffffc0204f42:	6105                	addi	sp,sp,32
ffffffffc0204f44:	fbaff06f          	j	ffffffffc02046fe <do_wait.part.0>
ffffffffc0204f48:	60e2                	ld	ra,24(sp)
ffffffffc0204f4a:	6442                	ld	s0,16(sp)
ffffffffc0204f4c:	64a2                	ld	s1,8(sp)
ffffffffc0204f4e:	5575                	li	a0,-3
ffffffffc0204f50:	6105                	addi	sp,sp,32
ffffffffc0204f52:	8082                	ret

ffffffffc0204f54 <do_kill>:
{
ffffffffc0204f54:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f56:	6789                	lui	a5,0x2
{
ffffffffc0204f58:	e406                	sd	ra,8(sp)
ffffffffc0204f5a:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f5c:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204f60:	17f9                	addi	a5,a5,-2
ffffffffc0204f62:	02e7e963          	bltu	a5,a4,ffffffffc0204f94 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f66:	842a                	mv	s0,a0
ffffffffc0204f68:	45a9                	li	a1,10
ffffffffc0204f6a:	2501                	sext.w	a0,a0
ffffffffc0204f6c:	46c000ef          	jal	ra,ffffffffc02053d8 <hash32>
ffffffffc0204f70:	02051793          	slli	a5,a0,0x20
ffffffffc0204f74:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204f78:	000a1797          	auipc	a5,0xa1
ffffffffc0204f7c:	6f078793          	addi	a5,a5,1776 # ffffffffc02a6668 <hash_list>
ffffffffc0204f80:	953e                	add	a0,a0,a5
ffffffffc0204f82:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204f84:	a029                	j	ffffffffc0204f8e <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204f86:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204f8a:	00870b63          	beq	a4,s0,ffffffffc0204fa0 <do_kill+0x4c>
ffffffffc0204f8e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204f90:	fef51be3          	bne	a0,a5,ffffffffc0204f86 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204f94:	5475                	li	s0,-3
}
ffffffffc0204f96:	60a2                	ld	ra,8(sp)
ffffffffc0204f98:	8522                	mv	a0,s0
ffffffffc0204f9a:	6402                	ld	s0,0(sp)
ffffffffc0204f9c:	0141                	addi	sp,sp,16
ffffffffc0204f9e:	8082                	ret
        if (!(proc->flags & PF_EXITING))// 如果该进程未处于退出状态
ffffffffc0204fa0:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204fa4:	00177693          	andi	a3,a4,1
ffffffffc0204fa8:	e295                	bnez	a3,ffffffffc0204fcc <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED) // 处于可中断等待状态，则唤醒该进程
ffffffffc0204faa:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;// 设置该进程的标志为 PF_EXITING
ffffffffc0204fac:	00176713          	ori	a4,a4,1
ffffffffc0204fb0:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204fb4:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED) // 处于可中断等待状态，则唤醒该进程
ffffffffc0204fb6:	fe06d0e3          	bgez	a3,ffffffffc0204f96 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204fba:	f2878513          	addi	a0,a5,-216
ffffffffc0204fbe:	22e000ef          	jal	ra,ffffffffc02051ec <wakeup_proc>
}
ffffffffc0204fc2:	60a2                	ld	ra,8(sp)
ffffffffc0204fc4:	8522                	mv	a0,s0
ffffffffc0204fc6:	6402                	ld	s0,0(sp)
ffffffffc0204fc8:	0141                	addi	sp,sp,16
ffffffffc0204fca:	8082                	ret
        return -E_KILLED;
ffffffffc0204fcc:	545d                	li	s0,-9
ffffffffc0204fce:	b7e1                	j	ffffffffc0204f96 <do_kill+0x42>

ffffffffc0204fd0 <proc_init>:
}

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204fd0:	1101                	addi	sp,sp,-32
ffffffffc0204fd2:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204fd4:	000a5797          	auipc	a5,0xa5
ffffffffc0204fd8:	69478793          	addi	a5,a5,1684 # ffffffffc02aa668 <proc_list>
ffffffffc0204fdc:	ec06                	sd	ra,24(sp)
ffffffffc0204fde:	e822                	sd	s0,16(sp)
ffffffffc0204fe0:	e04a                	sd	s2,0(sp)
ffffffffc0204fe2:	000a1497          	auipc	s1,0xa1
ffffffffc0204fe6:	68648493          	addi	s1,s1,1670 # ffffffffc02a6668 <hash_list>
ffffffffc0204fea:	e79c                	sd	a5,8(a5)
ffffffffc0204fec:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204fee:	000a5717          	auipc	a4,0xa5
ffffffffc0204ff2:	67a70713          	addi	a4,a4,1658 # ffffffffc02aa668 <proc_list>
ffffffffc0204ff6:	87a6                	mv	a5,s1
ffffffffc0204ff8:	e79c                	sd	a5,8(a5)
ffffffffc0204ffa:	e39c                	sd	a5,0(a5)
ffffffffc0204ffc:	07c1                	addi	a5,a5,16
ffffffffc0204ffe:	fef71de3          	bne	a4,a5,ffffffffc0204ff8 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0205002:	f7ffe0ef          	jal	ra,ffffffffc0203f80 <alloc_proc>
ffffffffc0205006:	000a5917          	auipc	s2,0xa5
ffffffffc020500a:	6ea90913          	addi	s2,s2,1770 # ffffffffc02aa6f0 <idleproc>
ffffffffc020500e:	00a93023          	sd	a0,0(s2)
ffffffffc0205012:	0e050f63          	beqz	a0,ffffffffc0205110 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205016:	4789                	li	a5,2
ffffffffc0205018:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc020501a:	00003797          	auipc	a5,0x3
ffffffffc020501e:	fe678793          	addi	a5,a5,-26 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205022:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205026:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205028:	4785                	li	a5,1
ffffffffc020502a:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020502c:	4641                	li	a2,16
ffffffffc020502e:	4581                	li	a1,0
ffffffffc0205030:	8522                	mv	a0,s0
ffffffffc0205032:	04d000ef          	jal	ra,ffffffffc020587e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205036:	463d                	li	a2,15
ffffffffc0205038:	00002597          	auipc	a1,0x2
ffffffffc020503c:	4c058593          	addi	a1,a1,1216 # ffffffffc02074f8 <default_pmm_manager+0xdb0>
ffffffffc0205040:	8522                	mv	a0,s0
ffffffffc0205042:	04f000ef          	jal	ra,ffffffffc0205890 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0205046:	000a5717          	auipc	a4,0xa5
ffffffffc020504a:	6ba70713          	addi	a4,a4,1722 # ffffffffc02aa700 <nr_process>
ffffffffc020504e:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0205050:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205054:	4601                	li	a2,0
    nr_process++;
ffffffffc0205056:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205058:	4581                	li	a1,0
ffffffffc020505a:	00000517          	auipc	a0,0x0
ffffffffc020505e:	87650513          	addi	a0,a0,-1930 # ffffffffc02048d0 <init_main>
    nr_process++;
ffffffffc0205062:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205064:	000a5797          	auipc	a5,0xa5
ffffffffc0205068:	68d7b223          	sd	a3,1668(a5) # ffffffffc02aa6e8 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020506c:	cf8ff0ef          	jal	ra,ffffffffc0204564 <kernel_thread>
ffffffffc0205070:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0205072:	08a05363          	blez	a0,ffffffffc02050f8 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0205076:	6789                	lui	a5,0x2
ffffffffc0205078:	fff5071b          	addiw	a4,a0,-1
ffffffffc020507c:	17f9                	addi	a5,a5,-2
ffffffffc020507e:	2501                	sext.w	a0,a0
ffffffffc0205080:	02e7e363          	bltu	a5,a4,ffffffffc02050a6 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205084:	45a9                	li	a1,10
ffffffffc0205086:	352000ef          	jal	ra,ffffffffc02053d8 <hash32>
ffffffffc020508a:	02051793          	slli	a5,a0,0x20
ffffffffc020508e:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205092:	96a6                	add	a3,a3,s1
ffffffffc0205094:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0205096:	a029                	j	ffffffffc02050a0 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0205098:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c7c>
ffffffffc020509c:	04870b63          	beq	a4,s0,ffffffffc02050f2 <proc_init+0x122>
    return listelm->next;
ffffffffc02050a0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02050a2:	fef69be3          	bne	a3,a5,ffffffffc0205098 <proc_init+0xc8>
    return NULL;
ffffffffc02050a6:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050a8:	0b478493          	addi	s1,a5,180
ffffffffc02050ac:	4641                	li	a2,16
ffffffffc02050ae:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc02050b0:	000a5417          	auipc	s0,0xa5
ffffffffc02050b4:	64840413          	addi	s0,s0,1608 # ffffffffc02aa6f8 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050b8:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc02050ba:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050bc:	7c2000ef          	jal	ra,ffffffffc020587e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02050c0:	463d                	li	a2,15
ffffffffc02050c2:	00002597          	auipc	a1,0x2
ffffffffc02050c6:	45e58593          	addi	a1,a1,1118 # ffffffffc0207520 <default_pmm_manager+0xdd8>
ffffffffc02050ca:	8526                	mv	a0,s1
ffffffffc02050cc:	7c4000ef          	jal	ra,ffffffffc0205890 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02050d0:	00093783          	ld	a5,0(s2)
ffffffffc02050d4:	cbb5                	beqz	a5,ffffffffc0205148 <proc_init+0x178>
ffffffffc02050d6:	43dc                	lw	a5,4(a5)
ffffffffc02050d8:	eba5                	bnez	a5,ffffffffc0205148 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02050da:	601c                	ld	a5,0(s0)
ffffffffc02050dc:	c7b1                	beqz	a5,ffffffffc0205128 <proc_init+0x158>
ffffffffc02050de:	43d8                	lw	a4,4(a5)
ffffffffc02050e0:	4785                	li	a5,1
ffffffffc02050e2:	04f71363          	bne	a4,a5,ffffffffc0205128 <proc_init+0x158>
}
ffffffffc02050e6:	60e2                	ld	ra,24(sp)
ffffffffc02050e8:	6442                	ld	s0,16(sp)
ffffffffc02050ea:	64a2                	ld	s1,8(sp)
ffffffffc02050ec:	6902                	ld	s2,0(sp)
ffffffffc02050ee:	6105                	addi	sp,sp,32
ffffffffc02050f0:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02050f2:	f2878793          	addi	a5,a5,-216
ffffffffc02050f6:	bf4d                	j	ffffffffc02050a8 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc02050f8:	00002617          	auipc	a2,0x2
ffffffffc02050fc:	40860613          	addi	a2,a2,1032 # ffffffffc0207500 <default_pmm_manager+0xdb8>
ffffffffc0205100:	43c00593          	li	a1,1084
ffffffffc0205104:	00002517          	auipc	a0,0x2
ffffffffc0205108:	08c50513          	addi	a0,a0,140 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc020510c:	b82fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205110:	00002617          	auipc	a2,0x2
ffffffffc0205114:	3d060613          	addi	a2,a2,976 # ffffffffc02074e0 <default_pmm_manager+0xd98>
ffffffffc0205118:	42d00593          	li	a1,1069
ffffffffc020511c:	00002517          	auipc	a0,0x2
ffffffffc0205120:	07450513          	addi	a0,a0,116 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc0205124:	b6afb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205128:	00002697          	auipc	a3,0x2
ffffffffc020512c:	42868693          	addi	a3,a3,1064 # ffffffffc0207550 <default_pmm_manager+0xe08>
ffffffffc0205130:	00001617          	auipc	a2,0x1
ffffffffc0205134:	26860613          	addi	a2,a2,616 # ffffffffc0206398 <commands+0x888>
ffffffffc0205138:	44300593          	li	a1,1091
ffffffffc020513c:	00002517          	auipc	a0,0x2
ffffffffc0205140:	05450513          	addi	a0,a0,84 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc0205144:	b4afb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205148:	00002697          	auipc	a3,0x2
ffffffffc020514c:	3e068693          	addi	a3,a3,992 # ffffffffc0207528 <default_pmm_manager+0xde0>
ffffffffc0205150:	00001617          	auipc	a2,0x1
ffffffffc0205154:	24860613          	addi	a2,a2,584 # ffffffffc0206398 <commands+0x888>
ffffffffc0205158:	44200593          	li	a1,1090
ffffffffc020515c:	00002517          	auipc	a0,0x2
ffffffffc0205160:	03450513          	addi	a0,a0,52 # ffffffffc0207190 <default_pmm_manager+0xa48>
ffffffffc0205164:	b2afb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205168 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205168:	1141                	addi	sp,sp,-16
ffffffffc020516a:	e022                	sd	s0,0(sp)
ffffffffc020516c:	e406                	sd	ra,8(sp)
ffffffffc020516e:	000a5417          	auipc	s0,0xa5
ffffffffc0205172:	57a40413          	addi	s0,s0,1402 # ffffffffc02aa6e8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205176:	6018                	ld	a4,0(s0)
ffffffffc0205178:	6f1c                	ld	a5,24(a4)
ffffffffc020517a:	dffd                	beqz	a5,ffffffffc0205178 <cpu_idle+0x10>
        {
            schedule();
ffffffffc020517c:	0f0000ef          	jal	ra,ffffffffc020526c <schedule>
ffffffffc0205180:	bfdd                	j	ffffffffc0205176 <cpu_idle+0xe>

ffffffffc0205182 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205182:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205186:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc020518a:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020518c:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020518e:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205192:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205196:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc020519a:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020519e:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02051a2:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02051a6:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02051aa:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02051ae:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02051b2:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02051b6:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02051ba:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02051be:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02051c0:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02051c2:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02051c6:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02051ca:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02051ce:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02051d2:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02051d6:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02051da:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02051de:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02051e2:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02051e6:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02051ea:	8082                	ret

ffffffffc02051ec <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051ec:	4118                	lw	a4,0(a0)
{
ffffffffc02051ee:	1101                	addi	sp,sp,-32
ffffffffc02051f0:	ec06                	sd	ra,24(sp)
ffffffffc02051f2:	e822                	sd	s0,16(sp)
ffffffffc02051f4:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051f6:	478d                	li	a5,3
ffffffffc02051f8:	04f70b63          	beq	a4,a5,ffffffffc020524e <wakeup_proc+0x62>
ffffffffc02051fc:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02051fe:	100027f3          	csrr	a5,sstatus
ffffffffc0205202:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205204:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205206:	ef9d                	bnez	a5,ffffffffc0205244 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205208:	4789                	li	a5,2
ffffffffc020520a:	02f70163          	beq	a4,a5,ffffffffc020522c <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc020520e:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205210:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc0205214:	e491                	bnez	s1,ffffffffc0205220 <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205216:	60e2                	ld	ra,24(sp)
ffffffffc0205218:	6442                	ld	s0,16(sp)
ffffffffc020521a:	64a2                	ld	s1,8(sp)
ffffffffc020521c:	6105                	addi	sp,sp,32
ffffffffc020521e:	8082                	ret
ffffffffc0205220:	6442                	ld	s0,16(sp)
ffffffffc0205222:	60e2                	ld	ra,24(sp)
ffffffffc0205224:	64a2                	ld	s1,8(sp)
ffffffffc0205226:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205228:	f86fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc020522c:	00002617          	auipc	a2,0x2
ffffffffc0205230:	38460613          	addi	a2,a2,900 # ffffffffc02075b0 <default_pmm_manager+0xe68>
ffffffffc0205234:	45d1                	li	a1,20
ffffffffc0205236:	00002517          	auipc	a0,0x2
ffffffffc020523a:	36250513          	addi	a0,a0,866 # ffffffffc0207598 <default_pmm_manager+0xe50>
ffffffffc020523e:	ab8fb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc0205242:	bfc9                	j	ffffffffc0205214 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205244:	f70fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205248:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc020524a:	4485                	li	s1,1
ffffffffc020524c:	bf75                	j	ffffffffc0205208 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020524e:	00002697          	auipc	a3,0x2
ffffffffc0205252:	32a68693          	addi	a3,a3,810 # ffffffffc0207578 <default_pmm_manager+0xe30>
ffffffffc0205256:	00001617          	auipc	a2,0x1
ffffffffc020525a:	14260613          	addi	a2,a2,322 # ffffffffc0206398 <commands+0x888>
ffffffffc020525e:	45a5                	li	a1,9
ffffffffc0205260:	00002517          	auipc	a0,0x2
ffffffffc0205264:	33850513          	addi	a0,a0,824 # ffffffffc0207598 <default_pmm_manager+0xe50>
ffffffffc0205268:	a26fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020526c <schedule>:

void schedule(void)
{
ffffffffc020526c:	1141                	addi	sp,sp,-16
ffffffffc020526e:	e406                	sd	ra,8(sp)
ffffffffc0205270:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205272:	100027f3          	csrr	a5,sstatus
ffffffffc0205276:	8b89                	andi	a5,a5,2
ffffffffc0205278:	4401                	li	s0,0
ffffffffc020527a:	efbd                	bnez	a5,ffffffffc02052f8 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020527c:	000a5897          	auipc	a7,0xa5
ffffffffc0205280:	46c8b883          	ld	a7,1132(a7) # ffffffffc02aa6e8 <current>
ffffffffc0205284:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205288:	000a5517          	auipc	a0,0xa5
ffffffffc020528c:	46853503          	ld	a0,1128(a0) # ffffffffc02aa6f0 <idleproc>
ffffffffc0205290:	04a88e63          	beq	a7,a0,ffffffffc02052ec <schedule+0x80>
ffffffffc0205294:	0c888693          	addi	a3,a7,200
ffffffffc0205298:	000a5617          	auipc	a2,0xa5
ffffffffc020529c:	3d060613          	addi	a2,a2,976 # ffffffffc02aa668 <proc_list>
        le = last;
ffffffffc02052a0:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02052a2:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc02052a4:	4809                	li	a6,2
ffffffffc02052a6:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02052a8:	00c78863          	beq	a5,a2,ffffffffc02052b8 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc02052ac:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02052b0:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc02052b4:	03070163          	beq	a4,a6,ffffffffc02052d6 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc02052b8:	fef697e3          	bne	a3,a5,ffffffffc02052a6 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02052bc:	ed89                	bnez	a1,ffffffffc02052d6 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02052be:	451c                	lw	a5,8(a0)
ffffffffc02052c0:	2785                	addiw	a5,a5,1
ffffffffc02052c2:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc02052c4:	00a88463          	beq	a7,a0,ffffffffc02052cc <schedule+0x60>
        {
            proc_run(next);
ffffffffc02052c8:	e47fe0ef          	jal	ra,ffffffffc020410e <proc_run>
    if (flag)
ffffffffc02052cc:	e819                	bnez	s0,ffffffffc02052e2 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02052ce:	60a2                	ld	ra,8(sp)
ffffffffc02052d0:	6402                	ld	s0,0(sp)
ffffffffc02052d2:	0141                	addi	sp,sp,16
ffffffffc02052d4:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02052d6:	4198                	lw	a4,0(a1)
ffffffffc02052d8:	4789                	li	a5,2
ffffffffc02052da:	fef712e3          	bne	a4,a5,ffffffffc02052be <schedule+0x52>
ffffffffc02052de:	852e                	mv	a0,a1
ffffffffc02052e0:	bff9                	j	ffffffffc02052be <schedule+0x52>
}
ffffffffc02052e2:	6402                	ld	s0,0(sp)
ffffffffc02052e4:	60a2                	ld	ra,8(sp)
ffffffffc02052e6:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02052e8:	ec6fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02052ec:	000a5617          	auipc	a2,0xa5
ffffffffc02052f0:	37c60613          	addi	a2,a2,892 # ffffffffc02aa668 <proc_list>
ffffffffc02052f4:	86b2                	mv	a3,a2
ffffffffc02052f6:	b76d                	j	ffffffffc02052a0 <schedule+0x34>
        intr_disable();
ffffffffc02052f8:	ebcfb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02052fc:	4405                	li	s0,1
ffffffffc02052fe:	bfbd                	j	ffffffffc020527c <schedule+0x10>

ffffffffc0205300 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205300:	000a5797          	auipc	a5,0xa5
ffffffffc0205304:	3e87b783          	ld	a5,1000(a5) # ffffffffc02aa6e8 <current>
}
ffffffffc0205308:	43c8                	lw	a0,4(a5)
ffffffffc020530a:	8082                	ret

ffffffffc020530c <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc020530c:	4501                	li	a0,0
ffffffffc020530e:	8082                	ret

ffffffffc0205310 <sys_putc>:
    cputchar(c);
ffffffffc0205310:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205312:	1141                	addi	sp,sp,-16
ffffffffc0205314:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205316:	eb5fa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc020531a:	60a2                	ld	ra,8(sp)
ffffffffc020531c:	4501                	li	a0,0
ffffffffc020531e:	0141                	addi	sp,sp,16
ffffffffc0205320:	8082                	ret

ffffffffc0205322 <sys_kill>:
    return do_kill(pid);
ffffffffc0205322:	4108                	lw	a0,0(a0)
ffffffffc0205324:	c31ff06f          	j	ffffffffc0204f54 <do_kill>

ffffffffc0205328 <sys_yield>:
    return do_yield();
ffffffffc0205328:	bdfff06f          	j	ffffffffc0204f06 <do_yield>

ffffffffc020532c <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc020532c:	6d14                	ld	a3,24(a0)
ffffffffc020532e:	6910                	ld	a2,16(a0)
ffffffffc0205330:	650c                	ld	a1,8(a0)
ffffffffc0205332:	6108                	ld	a0,0(a0)
ffffffffc0205334:	ebeff06f          	j	ffffffffc02049f2 <do_execve>

ffffffffc0205338 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205338:	650c                	ld	a1,8(a0)
ffffffffc020533a:	4108                	lw	a0,0(a0)
ffffffffc020533c:	bdbff06f          	j	ffffffffc0204f16 <do_wait>

ffffffffc0205340 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205340:	000a5797          	auipc	a5,0xa5
ffffffffc0205344:	3a87b783          	ld	a5,936(a5) # ffffffffc02aa6e8 <current>
ffffffffc0205348:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc020534a:	4501                	li	a0,0
ffffffffc020534c:	6a0c                	ld	a1,16(a2)
ffffffffc020534e:	e25fe06f          	j	ffffffffc0204172 <do_fork>

ffffffffc0205352 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205352:	4108                	lw	a0,0(a0)
ffffffffc0205354:	a60ff06f          	j	ffffffffc02045b4 <do_exit>

ffffffffc0205358 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205358:	715d                	addi	sp,sp,-80
ffffffffc020535a:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc020535c:	000a5497          	auipc	s1,0xa5
ffffffffc0205360:	38c48493          	addi	s1,s1,908 # ffffffffc02aa6e8 <current>
ffffffffc0205364:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205366:	e0a2                	sd	s0,64(sp)
ffffffffc0205368:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc020536a:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc020536c:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020536e:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0205370:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205374:	0327ee63          	bltu	a5,s2,ffffffffc02053b0 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc0205378:	00391713          	slli	a4,s2,0x3
ffffffffc020537c:	00002797          	auipc	a5,0x2
ffffffffc0205380:	29c78793          	addi	a5,a5,668 # ffffffffc0207618 <syscalls>
ffffffffc0205384:	97ba                	add	a5,a5,a4
ffffffffc0205386:	639c                	ld	a5,0(a5)
ffffffffc0205388:	c785                	beqz	a5,ffffffffc02053b0 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc020538a:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc020538c:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc020538e:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205390:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205392:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205394:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205396:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0205398:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc020539a:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc020539c:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020539e:	0028                	addi	a0,sp,8
ffffffffc02053a0:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02053a2:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053a4:	e828                	sd	a0,80(s0)
}
ffffffffc02053a6:	6406                	ld	s0,64(sp)
ffffffffc02053a8:	74e2                	ld	s1,56(sp)
ffffffffc02053aa:	7942                	ld	s2,48(sp)
ffffffffc02053ac:	6161                	addi	sp,sp,80
ffffffffc02053ae:	8082                	ret
    print_trapframe(tf);
ffffffffc02053b0:	8522                	mv	a0,s0
ffffffffc02053b2:	ff2fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02053b6:	609c                	ld	a5,0(s1)
ffffffffc02053b8:	86ca                	mv	a3,s2
ffffffffc02053ba:	00002617          	auipc	a2,0x2
ffffffffc02053be:	21660613          	addi	a2,a2,534 # ffffffffc02075d0 <default_pmm_manager+0xe88>
ffffffffc02053c2:	43d8                	lw	a4,4(a5)
ffffffffc02053c4:	06200593          	li	a1,98
ffffffffc02053c8:	0b478793          	addi	a5,a5,180
ffffffffc02053cc:	00002517          	auipc	a0,0x2
ffffffffc02053d0:	23450513          	addi	a0,a0,564 # ffffffffc0207600 <default_pmm_manager+0xeb8>
ffffffffc02053d4:	8bafb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02053d8 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02053d8:	9e3707b7          	lui	a5,0x9e370
ffffffffc02053dc:	2785                	addiw	a5,a5,1
ffffffffc02053de:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02053e2:	02000793          	li	a5,32
ffffffffc02053e6:	9f8d                	subw	a5,a5,a1
}
ffffffffc02053e8:	00f5553b          	srlw	a0,a0,a5
ffffffffc02053ec:	8082                	ret

ffffffffc02053ee <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02053ee:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053f2:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02053f4:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053f8:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02053fa:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053fe:	f022                	sd	s0,32(sp)
ffffffffc0205400:	ec26                	sd	s1,24(sp)
ffffffffc0205402:	e84a                	sd	s2,16(sp)
ffffffffc0205404:	f406                	sd	ra,40(sp)
ffffffffc0205406:	e44e                	sd	s3,8(sp)
ffffffffc0205408:	84aa                	mv	s1,a0
ffffffffc020540a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020540c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0205410:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0205412:	03067e63          	bgeu	a2,a6,ffffffffc020544e <printnum+0x60>
ffffffffc0205416:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205418:	00805763          	blez	s0,ffffffffc0205426 <printnum+0x38>
ffffffffc020541c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020541e:	85ca                	mv	a1,s2
ffffffffc0205420:	854e                	mv	a0,s3
ffffffffc0205422:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205424:	fc65                	bnez	s0,ffffffffc020541c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205426:	1a02                	slli	s4,s4,0x20
ffffffffc0205428:	00002797          	auipc	a5,0x2
ffffffffc020542c:	2f078793          	addi	a5,a5,752 # ffffffffc0207718 <syscalls+0x100>
ffffffffc0205430:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205434:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205436:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205438:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020543c:	70a2                	ld	ra,40(sp)
ffffffffc020543e:	69a2                	ld	s3,8(sp)
ffffffffc0205440:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205442:	85ca                	mv	a1,s2
ffffffffc0205444:	87a6                	mv	a5,s1
}
ffffffffc0205446:	6942                	ld	s2,16(sp)
ffffffffc0205448:	64e2                	ld	s1,24(sp)
ffffffffc020544a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020544c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020544e:	03065633          	divu	a2,a2,a6
ffffffffc0205452:	8722                	mv	a4,s0
ffffffffc0205454:	f9bff0ef          	jal	ra,ffffffffc02053ee <printnum>
ffffffffc0205458:	b7f9                	j	ffffffffc0205426 <printnum+0x38>

ffffffffc020545a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020545a:	7119                	addi	sp,sp,-128
ffffffffc020545c:	f4a6                	sd	s1,104(sp)
ffffffffc020545e:	f0ca                	sd	s2,96(sp)
ffffffffc0205460:	ecce                	sd	s3,88(sp)
ffffffffc0205462:	e8d2                	sd	s4,80(sp)
ffffffffc0205464:	e4d6                	sd	s5,72(sp)
ffffffffc0205466:	e0da                	sd	s6,64(sp)
ffffffffc0205468:	fc5e                	sd	s7,56(sp)
ffffffffc020546a:	f06a                	sd	s10,32(sp)
ffffffffc020546c:	fc86                	sd	ra,120(sp)
ffffffffc020546e:	f8a2                	sd	s0,112(sp)
ffffffffc0205470:	f862                	sd	s8,48(sp)
ffffffffc0205472:	f466                	sd	s9,40(sp)
ffffffffc0205474:	ec6e                	sd	s11,24(sp)
ffffffffc0205476:	892a                	mv	s2,a0
ffffffffc0205478:	84ae                	mv	s1,a1
ffffffffc020547a:	8d32                	mv	s10,a2
ffffffffc020547c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020547e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205482:	5b7d                	li	s6,-1
ffffffffc0205484:	00002a97          	auipc	s5,0x2
ffffffffc0205488:	2c0a8a93          	addi	s5,s5,704 # ffffffffc0207744 <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020548c:	00002b97          	auipc	s7,0x2
ffffffffc0205490:	4d4b8b93          	addi	s7,s7,1236 # ffffffffc0207960 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205494:	000d4503          	lbu	a0,0(s10)
ffffffffc0205498:	001d0413          	addi	s0,s10,1
ffffffffc020549c:	01350a63          	beq	a0,s3,ffffffffc02054b0 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02054a0:	c121                	beqz	a0,ffffffffc02054e0 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02054a2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054a4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02054a6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054a8:	fff44503          	lbu	a0,-1(s0)
ffffffffc02054ac:	ff351ae3          	bne	a0,s3,ffffffffc02054a0 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054b0:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02054b4:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02054b8:	4c81                	li	s9,0
ffffffffc02054ba:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02054bc:	5c7d                	li	s8,-1
ffffffffc02054be:	5dfd                	li	s11,-1
ffffffffc02054c0:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02054c4:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054c6:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02054ca:	0ff5f593          	zext.b	a1,a1
ffffffffc02054ce:	00140d13          	addi	s10,s0,1
ffffffffc02054d2:	04b56263          	bltu	a0,a1,ffffffffc0205516 <vprintfmt+0xbc>
ffffffffc02054d6:	058a                	slli	a1,a1,0x2
ffffffffc02054d8:	95d6                	add	a1,a1,s5
ffffffffc02054da:	4194                	lw	a3,0(a1)
ffffffffc02054dc:	96d6                	add	a3,a3,s5
ffffffffc02054de:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02054e0:	70e6                	ld	ra,120(sp)
ffffffffc02054e2:	7446                	ld	s0,112(sp)
ffffffffc02054e4:	74a6                	ld	s1,104(sp)
ffffffffc02054e6:	7906                	ld	s2,96(sp)
ffffffffc02054e8:	69e6                	ld	s3,88(sp)
ffffffffc02054ea:	6a46                	ld	s4,80(sp)
ffffffffc02054ec:	6aa6                	ld	s5,72(sp)
ffffffffc02054ee:	6b06                	ld	s6,64(sp)
ffffffffc02054f0:	7be2                	ld	s7,56(sp)
ffffffffc02054f2:	7c42                	ld	s8,48(sp)
ffffffffc02054f4:	7ca2                	ld	s9,40(sp)
ffffffffc02054f6:	7d02                	ld	s10,32(sp)
ffffffffc02054f8:	6de2                	ld	s11,24(sp)
ffffffffc02054fa:	6109                	addi	sp,sp,128
ffffffffc02054fc:	8082                	ret
            padc = '0';
ffffffffc02054fe:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0205500:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205504:	846a                	mv	s0,s10
ffffffffc0205506:	00140d13          	addi	s10,s0,1
ffffffffc020550a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020550e:	0ff5f593          	zext.b	a1,a1
ffffffffc0205512:	fcb572e3          	bgeu	a0,a1,ffffffffc02054d6 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0205516:	85a6                	mv	a1,s1
ffffffffc0205518:	02500513          	li	a0,37
ffffffffc020551c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020551e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205522:	8d22                	mv	s10,s0
ffffffffc0205524:	f73788e3          	beq	a5,s3,ffffffffc0205494 <vprintfmt+0x3a>
ffffffffc0205528:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020552c:	1d7d                	addi	s10,s10,-1
ffffffffc020552e:	ff379de3          	bne	a5,s3,ffffffffc0205528 <vprintfmt+0xce>
ffffffffc0205532:	b78d                	j	ffffffffc0205494 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205534:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205538:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020553c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020553e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205542:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205546:	02d86463          	bltu	a6,a3,ffffffffc020556e <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020554a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020554e:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205552:	0186873b          	addw	a4,a3,s8
ffffffffc0205556:	0017171b          	slliw	a4,a4,0x1
ffffffffc020555a:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020555c:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205560:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205562:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205566:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020556a:	fed870e3          	bgeu	a6,a3,ffffffffc020554a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc020556e:	f40ddce3          	bgez	s11,ffffffffc02054c6 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205572:	8de2                	mv	s11,s8
ffffffffc0205574:	5c7d                	li	s8,-1
ffffffffc0205576:	bf81                	j	ffffffffc02054c6 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205578:	fffdc693          	not	a3,s11
ffffffffc020557c:	96fd                	srai	a3,a3,0x3f
ffffffffc020557e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205582:	00144603          	lbu	a2,1(s0)
ffffffffc0205586:	2d81                	sext.w	s11,s11
ffffffffc0205588:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020558a:	bf35                	j	ffffffffc02054c6 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020558c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205590:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205594:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205596:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205598:	bfd9                	j	ffffffffc020556e <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020559a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020559c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055a0:	01174463          	blt	a4,a7,ffffffffc02055a8 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02055a4:	1a088e63          	beqz	a7,ffffffffc0205760 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02055a8:	000a3603          	ld	a2,0(s4)
ffffffffc02055ac:	46c1                	li	a3,16
ffffffffc02055ae:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02055b0:	2781                	sext.w	a5,a5
ffffffffc02055b2:	876e                	mv	a4,s11
ffffffffc02055b4:	85a6                	mv	a1,s1
ffffffffc02055b6:	854a                	mv	a0,s2
ffffffffc02055b8:	e37ff0ef          	jal	ra,ffffffffc02053ee <printnum>
            break;
ffffffffc02055bc:	bde1                	j	ffffffffc0205494 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02055be:	000a2503          	lw	a0,0(s4)
ffffffffc02055c2:	85a6                	mv	a1,s1
ffffffffc02055c4:	0a21                	addi	s4,s4,8
ffffffffc02055c6:	9902                	jalr	s2
            break;
ffffffffc02055c8:	b5f1                	j	ffffffffc0205494 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02055ca:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055cc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055d0:	01174463          	blt	a4,a7,ffffffffc02055d8 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02055d4:	18088163          	beqz	a7,ffffffffc0205756 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02055d8:	000a3603          	ld	a2,0(s4)
ffffffffc02055dc:	46a9                	li	a3,10
ffffffffc02055de:	8a2e                	mv	s4,a1
ffffffffc02055e0:	bfc1                	j	ffffffffc02055b0 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055e2:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02055e6:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055e8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02055ea:	bdf1                	j	ffffffffc02054c6 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02055ec:	85a6                	mv	a1,s1
ffffffffc02055ee:	02500513          	li	a0,37
ffffffffc02055f2:	9902                	jalr	s2
            break;
ffffffffc02055f4:	b545                	j	ffffffffc0205494 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055f6:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02055fa:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055fc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02055fe:	b5e1                	j	ffffffffc02054c6 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205600:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205602:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205606:	01174463          	blt	a4,a7,ffffffffc020560e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020560a:	14088163          	beqz	a7,ffffffffc020574c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020560e:	000a3603          	ld	a2,0(s4)
ffffffffc0205612:	46a1                	li	a3,8
ffffffffc0205614:	8a2e                	mv	s4,a1
ffffffffc0205616:	bf69                	j	ffffffffc02055b0 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0205618:	03000513          	li	a0,48
ffffffffc020561c:	85a6                	mv	a1,s1
ffffffffc020561e:	e03e                	sd	a5,0(sp)
ffffffffc0205620:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205622:	85a6                	mv	a1,s1
ffffffffc0205624:	07800513          	li	a0,120
ffffffffc0205628:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020562a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020562c:	6782                	ld	a5,0(sp)
ffffffffc020562e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205630:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205634:	bfb5                	j	ffffffffc02055b0 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205636:	000a3403          	ld	s0,0(s4)
ffffffffc020563a:	008a0713          	addi	a4,s4,8
ffffffffc020563e:	e03a                	sd	a4,0(sp)
ffffffffc0205640:	14040263          	beqz	s0,ffffffffc0205784 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205644:	0fb05763          	blez	s11,ffffffffc0205732 <vprintfmt+0x2d8>
ffffffffc0205648:	02d00693          	li	a3,45
ffffffffc020564c:	0cd79163          	bne	a5,a3,ffffffffc020570e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205650:	00044783          	lbu	a5,0(s0)
ffffffffc0205654:	0007851b          	sext.w	a0,a5
ffffffffc0205658:	cf85                	beqz	a5,ffffffffc0205690 <vprintfmt+0x236>
ffffffffc020565a:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020565e:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205662:	000c4563          	bltz	s8,ffffffffc020566c <vprintfmt+0x212>
ffffffffc0205666:	3c7d                	addiw	s8,s8,-1
ffffffffc0205668:	036c0263          	beq	s8,s6,ffffffffc020568c <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020566c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020566e:	0e0c8e63          	beqz	s9,ffffffffc020576a <vprintfmt+0x310>
ffffffffc0205672:	3781                	addiw	a5,a5,-32
ffffffffc0205674:	0ef47b63          	bgeu	s0,a5,ffffffffc020576a <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205678:	03f00513          	li	a0,63
ffffffffc020567c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020567e:	000a4783          	lbu	a5,0(s4)
ffffffffc0205682:	3dfd                	addiw	s11,s11,-1
ffffffffc0205684:	0a05                	addi	s4,s4,1
ffffffffc0205686:	0007851b          	sext.w	a0,a5
ffffffffc020568a:	ffe1                	bnez	a5,ffffffffc0205662 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020568c:	01b05963          	blez	s11,ffffffffc020569e <vprintfmt+0x244>
ffffffffc0205690:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205692:	85a6                	mv	a1,s1
ffffffffc0205694:	02000513          	li	a0,32
ffffffffc0205698:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020569a:	fe0d9be3          	bnez	s11,ffffffffc0205690 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020569e:	6a02                	ld	s4,0(sp)
ffffffffc02056a0:	bbd5                	j	ffffffffc0205494 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02056a2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02056a4:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02056a8:	01174463          	blt	a4,a7,ffffffffc02056b0 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02056ac:	08088d63          	beqz	a7,ffffffffc0205746 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02056b0:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02056b4:	0a044d63          	bltz	s0,ffffffffc020576e <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02056b8:	8622                	mv	a2,s0
ffffffffc02056ba:	8a66                	mv	s4,s9
ffffffffc02056bc:	46a9                	li	a3,10
ffffffffc02056be:	bdcd                	j	ffffffffc02055b0 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02056c0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056c4:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02056c6:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02056c8:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02056cc:	8fb5                	xor	a5,a5,a3
ffffffffc02056ce:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056d2:	02d74163          	blt	a4,a3,ffffffffc02056f4 <vprintfmt+0x29a>
ffffffffc02056d6:	00369793          	slli	a5,a3,0x3
ffffffffc02056da:	97de                	add	a5,a5,s7
ffffffffc02056dc:	639c                	ld	a5,0(a5)
ffffffffc02056de:	cb99                	beqz	a5,ffffffffc02056f4 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02056e0:	86be                	mv	a3,a5
ffffffffc02056e2:	00000617          	auipc	a2,0x0
ffffffffc02056e6:	1ee60613          	addi	a2,a2,494 # ffffffffc02058d0 <etext+0x28>
ffffffffc02056ea:	85a6                	mv	a1,s1
ffffffffc02056ec:	854a                	mv	a0,s2
ffffffffc02056ee:	0ce000ef          	jal	ra,ffffffffc02057bc <printfmt>
ffffffffc02056f2:	b34d                	j	ffffffffc0205494 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02056f4:	00002617          	auipc	a2,0x2
ffffffffc02056f8:	04460613          	addi	a2,a2,68 # ffffffffc0207738 <syscalls+0x120>
ffffffffc02056fc:	85a6                	mv	a1,s1
ffffffffc02056fe:	854a                	mv	a0,s2
ffffffffc0205700:	0bc000ef          	jal	ra,ffffffffc02057bc <printfmt>
ffffffffc0205704:	bb41                	j	ffffffffc0205494 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205706:	00002417          	auipc	s0,0x2
ffffffffc020570a:	02a40413          	addi	s0,s0,42 # ffffffffc0207730 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020570e:	85e2                	mv	a1,s8
ffffffffc0205710:	8522                	mv	a0,s0
ffffffffc0205712:	e43e                	sd	a5,8(sp)
ffffffffc0205714:	0e2000ef          	jal	ra,ffffffffc02057f6 <strnlen>
ffffffffc0205718:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020571c:	01b05b63          	blez	s11,ffffffffc0205732 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205720:	67a2                	ld	a5,8(sp)
ffffffffc0205722:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205726:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205728:	85a6                	mv	a1,s1
ffffffffc020572a:	8552                	mv	a0,s4
ffffffffc020572c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020572e:	fe0d9ce3          	bnez	s11,ffffffffc0205726 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205732:	00044783          	lbu	a5,0(s0)
ffffffffc0205736:	00140a13          	addi	s4,s0,1
ffffffffc020573a:	0007851b          	sext.w	a0,a5
ffffffffc020573e:	d3a5                	beqz	a5,ffffffffc020569e <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205740:	05e00413          	li	s0,94
ffffffffc0205744:	bf39                	j	ffffffffc0205662 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205746:	000a2403          	lw	s0,0(s4)
ffffffffc020574a:	b7ad                	j	ffffffffc02056b4 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020574c:	000a6603          	lwu	a2,0(s4)
ffffffffc0205750:	46a1                	li	a3,8
ffffffffc0205752:	8a2e                	mv	s4,a1
ffffffffc0205754:	bdb1                	j	ffffffffc02055b0 <vprintfmt+0x156>
ffffffffc0205756:	000a6603          	lwu	a2,0(s4)
ffffffffc020575a:	46a9                	li	a3,10
ffffffffc020575c:	8a2e                	mv	s4,a1
ffffffffc020575e:	bd89                	j	ffffffffc02055b0 <vprintfmt+0x156>
ffffffffc0205760:	000a6603          	lwu	a2,0(s4)
ffffffffc0205764:	46c1                	li	a3,16
ffffffffc0205766:	8a2e                	mv	s4,a1
ffffffffc0205768:	b5a1                	j	ffffffffc02055b0 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020576a:	9902                	jalr	s2
ffffffffc020576c:	bf09                	j	ffffffffc020567e <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc020576e:	85a6                	mv	a1,s1
ffffffffc0205770:	02d00513          	li	a0,45
ffffffffc0205774:	e03e                	sd	a5,0(sp)
ffffffffc0205776:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205778:	6782                	ld	a5,0(sp)
ffffffffc020577a:	8a66                	mv	s4,s9
ffffffffc020577c:	40800633          	neg	a2,s0
ffffffffc0205780:	46a9                	li	a3,10
ffffffffc0205782:	b53d                	j	ffffffffc02055b0 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205784:	03b05163          	blez	s11,ffffffffc02057a6 <vprintfmt+0x34c>
ffffffffc0205788:	02d00693          	li	a3,45
ffffffffc020578c:	f6d79de3          	bne	a5,a3,ffffffffc0205706 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205790:	00002417          	auipc	s0,0x2
ffffffffc0205794:	fa040413          	addi	s0,s0,-96 # ffffffffc0207730 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205798:	02800793          	li	a5,40
ffffffffc020579c:	02800513          	li	a0,40
ffffffffc02057a0:	00140a13          	addi	s4,s0,1
ffffffffc02057a4:	bd6d                	j	ffffffffc020565e <vprintfmt+0x204>
ffffffffc02057a6:	00002a17          	auipc	s4,0x2
ffffffffc02057aa:	f8ba0a13          	addi	s4,s4,-117 # ffffffffc0207731 <syscalls+0x119>
ffffffffc02057ae:	02800513          	li	a0,40
ffffffffc02057b2:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02057b6:	05e00413          	li	s0,94
ffffffffc02057ba:	b565                	j	ffffffffc0205662 <vprintfmt+0x208>

ffffffffc02057bc <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057bc:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02057be:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057c2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057c4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057c6:	ec06                	sd	ra,24(sp)
ffffffffc02057c8:	f83a                	sd	a4,48(sp)
ffffffffc02057ca:	fc3e                	sd	a5,56(sp)
ffffffffc02057cc:	e0c2                	sd	a6,64(sp)
ffffffffc02057ce:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02057d0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057d2:	c89ff0ef          	jal	ra,ffffffffc020545a <vprintfmt>
}
ffffffffc02057d6:	60e2                	ld	ra,24(sp)
ffffffffc02057d8:	6161                	addi	sp,sp,80
ffffffffc02057da:	8082                	ret

ffffffffc02057dc <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02057dc:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02057e0:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02057e2:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02057e4:	cb81                	beqz	a5,ffffffffc02057f4 <strlen+0x18>
        cnt ++;
ffffffffc02057e6:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02057e8:	00a707b3          	add	a5,a4,a0
ffffffffc02057ec:	0007c783          	lbu	a5,0(a5)
ffffffffc02057f0:	fbfd                	bnez	a5,ffffffffc02057e6 <strlen+0xa>
ffffffffc02057f2:	8082                	ret
    }
    return cnt;
}
ffffffffc02057f4:	8082                	ret

ffffffffc02057f6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02057f6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057f8:	e589                	bnez	a1,ffffffffc0205802 <strnlen+0xc>
ffffffffc02057fa:	a811                	j	ffffffffc020580e <strnlen+0x18>
        cnt ++;
ffffffffc02057fc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057fe:	00f58863          	beq	a1,a5,ffffffffc020580e <strnlen+0x18>
ffffffffc0205802:	00f50733          	add	a4,a0,a5
ffffffffc0205806:	00074703          	lbu	a4,0(a4)
ffffffffc020580a:	fb6d                	bnez	a4,ffffffffc02057fc <strnlen+0x6>
ffffffffc020580c:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020580e:	852e                	mv	a0,a1
ffffffffc0205810:	8082                	ret

ffffffffc0205812 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205812:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205814:	0005c703          	lbu	a4,0(a1)
ffffffffc0205818:	0785                	addi	a5,a5,1
ffffffffc020581a:	0585                	addi	a1,a1,1
ffffffffc020581c:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205820:	fb75                	bnez	a4,ffffffffc0205814 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205822:	8082                	ret

ffffffffc0205824 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205824:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205828:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020582c:	cb89                	beqz	a5,ffffffffc020583e <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020582e:	0505                	addi	a0,a0,1
ffffffffc0205830:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205832:	fee789e3          	beq	a5,a4,ffffffffc0205824 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205836:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020583a:	9d19                	subw	a0,a0,a4
ffffffffc020583c:	8082                	ret
ffffffffc020583e:	4501                	li	a0,0
ffffffffc0205840:	bfed                	j	ffffffffc020583a <strcmp+0x16>

ffffffffc0205842 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205842:	c20d                	beqz	a2,ffffffffc0205864 <strncmp+0x22>
ffffffffc0205844:	962e                	add	a2,a2,a1
ffffffffc0205846:	a031                	j	ffffffffc0205852 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205848:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020584a:	00e79a63          	bne	a5,a4,ffffffffc020585e <strncmp+0x1c>
ffffffffc020584e:	00b60b63          	beq	a2,a1,ffffffffc0205864 <strncmp+0x22>
ffffffffc0205852:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205856:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205858:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020585c:	f7f5                	bnez	a5,ffffffffc0205848 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020585e:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205862:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205864:	4501                	li	a0,0
ffffffffc0205866:	8082                	ret

ffffffffc0205868 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205868:	00054783          	lbu	a5,0(a0)
ffffffffc020586c:	c799                	beqz	a5,ffffffffc020587a <strchr+0x12>
        if (*s == c) {
ffffffffc020586e:	00f58763          	beq	a1,a5,ffffffffc020587c <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205872:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205876:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205878:	fbfd                	bnez	a5,ffffffffc020586e <strchr+0x6>
    }
    return NULL;
ffffffffc020587a:	4501                	li	a0,0
}
ffffffffc020587c:	8082                	ret

ffffffffc020587e <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020587e:	ca01                	beqz	a2,ffffffffc020588e <memset+0x10>
ffffffffc0205880:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205882:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205884:	0785                	addi	a5,a5,1
ffffffffc0205886:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020588a:	fec79de3          	bne	a5,a2,ffffffffc0205884 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020588e:	8082                	ret

ffffffffc0205890 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205890:	ca19                	beqz	a2,ffffffffc02058a6 <memcpy+0x16>
ffffffffc0205892:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205894:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205896:	0005c703          	lbu	a4,0(a1)
ffffffffc020589a:	0585                	addi	a1,a1,1
ffffffffc020589c:	0785                	addi	a5,a5,1
ffffffffc020589e:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02058a2:	fec59ae3          	bne	a1,a2,ffffffffc0205896 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02058a6:	8082                	ret
