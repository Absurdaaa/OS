
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
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
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0205337          	lui	t1,0xc0205
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    // 解释：BSS段用于存放未初始化的全局变量，memset会将其全部清零。
    // 如果DTB（设备树）信息存放在BSS段中，必须先保存DTB内容，否则memset会把DTB数据清掉，导致后续无法获取设备信息。
    memset(edata, 0, end - edata);
ffffffffc0200054:	00006517          	auipc	a0,0x6
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0206028 <free_area>
ffffffffc020005c:	00006617          	auipc	a2,0x6
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02064a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	0e1010ef          	jal	ra,ffffffffc020194c <memset>
    dtb_init();
ffffffffc0200070:	3be000ef          	jal	ra,ffffffffc020042e <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	7ae000ef          	jal	ra,ffffffffc0200822 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	df850513          	addi	a0,a0,-520 # ffffffffc0201e70 <etext+0x6>
ffffffffc0200080:	090000ef          	jal	ra,ffffffffc0200110 <cputs>

    print_kerninfo();
ffffffffc0200084:	138000ef          	jal	ra,ffffffffc02001bc <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7b4000ef          	jal	ra,ffffffffc020083c <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	46b000ef          	jal	ra,ffffffffc0200cf6 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	7ac000ef          	jal	ra,ffffffffc020083c <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	74a000ef          	jal	ra,ffffffffc02007de <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	798000ef          	jal	ra,ffffffffc0200830 <intr_enable>
    // asm volatile("ebreak");          // 触发断点
    // asm volatile(".word 0xffffffff"); // 非法指令


    /* do nothing */
    while (1)
ffffffffc020009c:	a001                	j	ffffffffc020009c <kern_init+0x48>

ffffffffc020009e <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020009e:	1141                	addi	sp,sp,-16
ffffffffc02000a0:	e022                	sd	s0,0(sp)
ffffffffc02000a2:	e406                	sd	ra,8(sp)
ffffffffc02000a4:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000a6:	77e000ef          	jal	ra,ffffffffc0200824 <cons_putc>
    (*cnt) ++;
ffffffffc02000aa:	401c                	lw	a5,0(s0)
}
ffffffffc02000ac:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000ae:	2785                	addiw	a5,a5,1
ffffffffc02000b0:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b2:	6402                	ld	s0,0(sp)
ffffffffc02000b4:	0141                	addi	sp,sp,16
ffffffffc02000b6:	8082                	ret

ffffffffc02000b8 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b8:	1101                	addi	sp,sp,-32
ffffffffc02000ba:	862a                	mv	a2,a0
ffffffffc02000bc:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	00000517          	auipc	a0,0x0
ffffffffc02000c2:	fe050513          	addi	a0,a0,-32 # ffffffffc020009e <cputch>
ffffffffc02000c6:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c8:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ca:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000cc:	0ff010ef          	jal	ra,ffffffffc02019ca <vprintfmt>
    return cnt;
}
ffffffffc02000d0:	60e2                	ld	ra,24(sp)
ffffffffc02000d2:	4532                	lw	a0,12(sp)
ffffffffc02000d4:	6105                	addi	sp,sp,32
ffffffffc02000d6:	8082                	ret

ffffffffc02000d8 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000da:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000de:	8e2a                	mv	t3,a0
ffffffffc02000e0:	f42e                	sd	a1,40(sp)
ffffffffc02000e2:	f832                	sd	a2,48(sp)
ffffffffc02000e4:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e6:	00000517          	auipc	a0,0x0
ffffffffc02000ea:	fb850513          	addi	a0,a0,-72 # ffffffffc020009e <cputch>
ffffffffc02000ee:	004c                	addi	a1,sp,4
ffffffffc02000f0:	869a                	mv	a3,t1
ffffffffc02000f2:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000f4:	ec06                	sd	ra,24(sp)
ffffffffc02000f6:	e0ba                	sd	a4,64(sp)
ffffffffc02000f8:	e4be                	sd	a5,72(sp)
ffffffffc02000fa:	e8c2                	sd	a6,80(sp)
ffffffffc02000fc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000fe:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200100:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200102:	0c9010ef          	jal	ra,ffffffffc02019ca <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200106:	60e2                	ld	ra,24(sp)
ffffffffc0200108:	4512                	lw	a0,4(sp)
ffffffffc020010a:	6125                	addi	sp,sp,96
ffffffffc020010c:	8082                	ret

ffffffffc020010e <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020010e:	af19                	j	ffffffffc0200824 <cons_putc>

ffffffffc0200110 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	ec06                	sd	ra,24(sp)
ffffffffc0200116:	e426                	sd	s1,8(sp)
ffffffffc0200118:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020011a:	00054503          	lbu	a0,0(a0)
ffffffffc020011e:	c51d                	beqz	a0,ffffffffc020014c <cputs+0x3c>
ffffffffc0200120:	0405                	addi	s0,s0,1
ffffffffc0200122:	4485                	li	s1,1
ffffffffc0200124:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200126:	6fe000ef          	jal	ra,ffffffffc0200824 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	00044503          	lbu	a0,0(s0)
ffffffffc020012e:	008487bb          	addw	a5,s1,s0
ffffffffc0200132:	0405                	addi	s0,s0,1
ffffffffc0200134:	f96d                	bnez	a0,ffffffffc0200126 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200136:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020013a:	4529                	li	a0,10
ffffffffc020013c:	6e8000ef          	jal	ra,ffffffffc0200824 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	6442                	ld	s0,16(sp)
ffffffffc0200146:	64a2                	ld	s1,8(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020014c:	4405                	li	s0,1
ffffffffc020014e:	b7f5                	j	ffffffffc020013a <cputs+0x2a>

ffffffffc0200150 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200150:	1141                	addi	sp,sp,-16
ffffffffc0200152:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200154:	6d8000ef          	jal	ra,ffffffffc020082c <cons_getc>
ffffffffc0200158:	dd75                	beqz	a0,ffffffffc0200154 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020015a:	60a2                	ld	ra,8(sp)
ffffffffc020015c:	0141                	addi	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200160:	00006317          	auipc	t1,0x6
ffffffffc0200164:	2e030313          	addi	t1,t1,736 # ffffffffc0206440 <is_panic>
ffffffffc0200168:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020016c:	715d                	addi	sp,sp,-80
ffffffffc020016e:	ec06                	sd	ra,24(sp)
ffffffffc0200170:	e822                	sd	s0,16(sp)
ffffffffc0200172:	f436                	sd	a3,40(sp)
ffffffffc0200174:	f83a                	sd	a4,48(sp)
ffffffffc0200176:	fc3e                	sd	a5,56(sp)
ffffffffc0200178:	e0c2                	sd	a6,64(sp)
ffffffffc020017a:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020017c:	020e1a63          	bnez	t3,ffffffffc02001b0 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200180:	4785                	li	a5,1
ffffffffc0200182:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200186:	8432                	mv	s0,a2
ffffffffc0200188:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020018a:	862e                	mv	a2,a1
ffffffffc020018c:	85aa                	mv	a1,a0
ffffffffc020018e:	00002517          	auipc	a0,0x2
ffffffffc0200192:	d0250513          	addi	a0,a0,-766 # ffffffffc0201e90 <etext+0x26>
    va_start(ap, fmt);
ffffffffc0200196:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200198:	f41ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020019c:	65a2                	ld	a1,8(sp)
ffffffffc020019e:	8522                	mv	a0,s0
ffffffffc02001a0:	f19ff0ef          	jal	ra,ffffffffc02000b8 <vcprintf>
    cprintf("\n");
ffffffffc02001a4:	00002517          	auipc	a0,0x2
ffffffffc02001a8:	dd450513          	addi	a0,a0,-556 # ffffffffc0201f78 <etext+0x10e>
ffffffffc02001ac:	f2dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02001b0:	686000ef          	jal	ra,ffffffffc0200836 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02001b4:	4501                	li	a0,0
ffffffffc02001b6:	130000ef          	jal	ra,ffffffffc02002e6 <kmonitor>
    while (1) {
ffffffffc02001ba:	bfed                	j	ffffffffc02001b4 <__panic+0x54>

ffffffffc02001bc <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02001bc:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001be:	00002517          	auipc	a0,0x2
ffffffffc02001c2:	cf250513          	addi	a0,a0,-782 # ffffffffc0201eb0 <etext+0x46>
void print_kerninfo(void) {
ffffffffc02001c6:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001c8:	f11ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001cc:	00000597          	auipc	a1,0x0
ffffffffc02001d0:	e8858593          	addi	a1,a1,-376 # ffffffffc0200054 <kern_init>
ffffffffc02001d4:	00002517          	auipc	a0,0x2
ffffffffc02001d8:	cfc50513          	addi	a0,a0,-772 # ffffffffc0201ed0 <etext+0x66>
ffffffffc02001dc:	efdff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001e0:	00002597          	auipc	a1,0x2
ffffffffc02001e4:	c8a58593          	addi	a1,a1,-886 # ffffffffc0201e6a <etext>
ffffffffc02001e8:	00002517          	auipc	a0,0x2
ffffffffc02001ec:	d0850513          	addi	a0,a0,-760 # ffffffffc0201ef0 <etext+0x86>
ffffffffc02001f0:	ee9ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001f4:	00006597          	auipc	a1,0x6
ffffffffc02001f8:	e3458593          	addi	a1,a1,-460 # ffffffffc0206028 <free_area>
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	d1450513          	addi	a0,a0,-748 # ffffffffc0201f10 <etext+0xa6>
ffffffffc0200204:	ed5ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200208:	00006597          	auipc	a1,0x6
ffffffffc020020c:	29858593          	addi	a1,a1,664 # ffffffffc02064a0 <end>
ffffffffc0200210:	00002517          	auipc	a0,0x2
ffffffffc0200214:	d2050513          	addi	a0,a0,-736 # ffffffffc0201f30 <etext+0xc6>
ffffffffc0200218:	ec1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020021c:	00006597          	auipc	a1,0x6
ffffffffc0200220:	68358593          	addi	a1,a1,1667 # ffffffffc020689f <end+0x3ff>
ffffffffc0200224:	00000797          	auipc	a5,0x0
ffffffffc0200228:	e3078793          	addi	a5,a5,-464 # ffffffffc0200054 <kern_init>
ffffffffc020022c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200230:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200234:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200236:	3ff5f593          	andi	a1,a1,1023
ffffffffc020023a:	95be                	add	a1,a1,a5
ffffffffc020023c:	85a9                	srai	a1,a1,0xa
ffffffffc020023e:	00002517          	auipc	a0,0x2
ffffffffc0200242:	d1250513          	addi	a0,a0,-750 # ffffffffc0201f50 <etext+0xe6>
}
ffffffffc0200246:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200248:	bd41                	j	ffffffffc02000d8 <cprintf>

ffffffffc020024a <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc020024a:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020024c:	00002617          	auipc	a2,0x2
ffffffffc0200250:	d3460613          	addi	a2,a2,-716 # ffffffffc0201f80 <etext+0x116>
ffffffffc0200254:	04d00593          	li	a1,77
ffffffffc0200258:	00002517          	auipc	a0,0x2
ffffffffc020025c:	d4050513          	addi	a0,a0,-704 # ffffffffc0201f98 <etext+0x12e>
void print_stackframe(void) {
ffffffffc0200260:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200262:	effff0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0200266 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200266:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200268:	00002617          	auipc	a2,0x2
ffffffffc020026c:	d4860613          	addi	a2,a2,-696 # ffffffffc0201fb0 <etext+0x146>
ffffffffc0200270:	00002597          	auipc	a1,0x2
ffffffffc0200274:	d6058593          	addi	a1,a1,-672 # ffffffffc0201fd0 <etext+0x166>
ffffffffc0200278:	00002517          	auipc	a0,0x2
ffffffffc020027c:	d6050513          	addi	a0,a0,-672 # ffffffffc0201fd8 <etext+0x16e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200280:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200282:	e57ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200286:	00002617          	auipc	a2,0x2
ffffffffc020028a:	d6260613          	addi	a2,a2,-670 # ffffffffc0201fe8 <etext+0x17e>
ffffffffc020028e:	00002597          	auipc	a1,0x2
ffffffffc0200292:	d8258593          	addi	a1,a1,-638 # ffffffffc0202010 <etext+0x1a6>
ffffffffc0200296:	00002517          	auipc	a0,0x2
ffffffffc020029a:	d4250513          	addi	a0,a0,-702 # ffffffffc0201fd8 <etext+0x16e>
ffffffffc020029e:	e3bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02002a2:	00002617          	auipc	a2,0x2
ffffffffc02002a6:	d7e60613          	addi	a2,a2,-642 # ffffffffc0202020 <etext+0x1b6>
ffffffffc02002aa:	00002597          	auipc	a1,0x2
ffffffffc02002ae:	d9658593          	addi	a1,a1,-618 # ffffffffc0202040 <etext+0x1d6>
ffffffffc02002b2:	00002517          	auipc	a0,0x2
ffffffffc02002b6:	d2650513          	addi	a0,a0,-730 # ffffffffc0201fd8 <etext+0x16e>
ffffffffc02002ba:	e1fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    return 0;
}
ffffffffc02002be:	60a2                	ld	ra,8(sp)
ffffffffc02002c0:	4501                	li	a0,0
ffffffffc02002c2:	0141                	addi	sp,sp,16
ffffffffc02002c4:	8082                	ret

ffffffffc02002c6 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002c6:	1141                	addi	sp,sp,-16
ffffffffc02002c8:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002ca:	ef3ff0ef          	jal	ra,ffffffffc02001bc <print_kerninfo>
    return 0;
}
ffffffffc02002ce:	60a2                	ld	ra,8(sp)
ffffffffc02002d0:	4501                	li	a0,0
ffffffffc02002d2:	0141                	addi	sp,sp,16
ffffffffc02002d4:	8082                	ret

ffffffffc02002d6 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002d6:	1141                	addi	sp,sp,-16
ffffffffc02002d8:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002da:	f71ff0ef          	jal	ra,ffffffffc020024a <print_stackframe>
    return 0;
}
ffffffffc02002de:	60a2                	ld	ra,8(sp)
ffffffffc02002e0:	4501                	li	a0,0
ffffffffc02002e2:	0141                	addi	sp,sp,16
ffffffffc02002e4:	8082                	ret

ffffffffc02002e6 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002e6:	7115                	addi	sp,sp,-224
ffffffffc02002e8:	ed5e                	sd	s7,152(sp)
ffffffffc02002ea:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ec:	00002517          	auipc	a0,0x2
ffffffffc02002f0:	d6450513          	addi	a0,a0,-668 # ffffffffc0202050 <etext+0x1e6>
kmonitor(struct trapframe *tf) {
ffffffffc02002f4:	ed86                	sd	ra,216(sp)
ffffffffc02002f6:	e9a2                	sd	s0,208(sp)
ffffffffc02002f8:	e5a6                	sd	s1,200(sp)
ffffffffc02002fa:	e1ca                	sd	s2,192(sp)
ffffffffc02002fc:	fd4e                	sd	s3,184(sp)
ffffffffc02002fe:	f952                	sd	s4,176(sp)
ffffffffc0200300:	f556                	sd	s5,168(sp)
ffffffffc0200302:	f15a                	sd	s6,160(sp)
ffffffffc0200304:	e962                	sd	s8,144(sp)
ffffffffc0200306:	e566                	sd	s9,136(sp)
ffffffffc0200308:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020030a:	dcfff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020030e:	00002517          	auipc	a0,0x2
ffffffffc0200312:	d6a50513          	addi	a0,a0,-662 # ffffffffc0202078 <etext+0x20e>
ffffffffc0200316:	dc3ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    if (tf != NULL) {
ffffffffc020031a:	000b8563          	beqz	s7,ffffffffc0200324 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020031e:	855e                	mv	a0,s7
ffffffffc0200320:	6fc000ef          	jal	ra,ffffffffc0200a1c <print_trapframe>
ffffffffc0200324:	00002c17          	auipc	s8,0x2
ffffffffc0200328:	dc4c0c13          	addi	s8,s8,-572 # ffffffffc02020e8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020032c:	00002917          	auipc	s2,0x2
ffffffffc0200330:	d7490913          	addi	s2,s2,-652 # ffffffffc02020a0 <etext+0x236>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200334:	00002497          	auipc	s1,0x2
ffffffffc0200338:	d7448493          	addi	s1,s1,-652 # ffffffffc02020a8 <etext+0x23e>
        if (argc == MAXARGS - 1) {
ffffffffc020033c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020033e:	00002b17          	auipc	s6,0x2
ffffffffc0200342:	d72b0b13          	addi	s6,s6,-654 # ffffffffc02020b0 <etext+0x246>
        argv[argc ++] = buf;
ffffffffc0200346:	00002a17          	auipc	s4,0x2
ffffffffc020034a:	c8aa0a13          	addi	s4,s4,-886 # ffffffffc0201fd0 <etext+0x166>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034e:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200350:	854a                	mv	a0,s2
ffffffffc0200352:	1fb010ef          	jal	ra,ffffffffc0201d4c <readline>
ffffffffc0200356:	842a                	mv	s0,a0
ffffffffc0200358:	dd65                	beqz	a0,ffffffffc0200350 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020035a:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020035e:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200360:	e1bd                	bnez	a1,ffffffffc02003c6 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200362:	fe0c87e3          	beqz	s9,ffffffffc0200350 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200366:	6582                	ld	a1,0(sp)
ffffffffc0200368:	00002d17          	auipc	s10,0x2
ffffffffc020036c:	d80d0d13          	addi	s10,s10,-640 # ffffffffc02020e8 <commands>
        argv[argc ++] = buf;
ffffffffc0200370:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200372:	4401                	li	s0,0
ffffffffc0200374:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200376:	57c010ef          	jal	ra,ffffffffc02018f2 <strcmp>
ffffffffc020037a:	c919                	beqz	a0,ffffffffc0200390 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020037c:	2405                	addiw	s0,s0,1
ffffffffc020037e:	0b540063          	beq	s0,s5,ffffffffc020041e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200382:	000d3503          	ld	a0,0(s10)
ffffffffc0200386:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200388:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020038a:	568010ef          	jal	ra,ffffffffc02018f2 <strcmp>
ffffffffc020038e:	f57d                	bnez	a0,ffffffffc020037c <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200390:	00141793          	slli	a5,s0,0x1
ffffffffc0200394:	97a2                	add	a5,a5,s0
ffffffffc0200396:	078e                	slli	a5,a5,0x3
ffffffffc0200398:	97e2                	add	a5,a5,s8
ffffffffc020039a:	6b9c                	ld	a5,16(a5)
ffffffffc020039c:	865e                	mv	a2,s7
ffffffffc020039e:	002c                	addi	a1,sp,8
ffffffffc02003a0:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003a4:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003a6:	fa0555e3          	bgez	a0,ffffffffc0200350 <kmonitor+0x6a>
}
ffffffffc02003aa:	60ee                	ld	ra,216(sp)
ffffffffc02003ac:	644e                	ld	s0,208(sp)
ffffffffc02003ae:	64ae                	ld	s1,200(sp)
ffffffffc02003b0:	690e                	ld	s2,192(sp)
ffffffffc02003b2:	79ea                	ld	s3,184(sp)
ffffffffc02003b4:	7a4a                	ld	s4,176(sp)
ffffffffc02003b6:	7aaa                	ld	s5,168(sp)
ffffffffc02003b8:	7b0a                	ld	s6,160(sp)
ffffffffc02003ba:	6bea                	ld	s7,152(sp)
ffffffffc02003bc:	6c4a                	ld	s8,144(sp)
ffffffffc02003be:	6caa                	ld	s9,136(sp)
ffffffffc02003c0:	6d0a                	ld	s10,128(sp)
ffffffffc02003c2:	612d                	addi	sp,sp,224
ffffffffc02003c4:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c6:	8526                	mv	a0,s1
ffffffffc02003c8:	56e010ef          	jal	ra,ffffffffc0201936 <strchr>
ffffffffc02003cc:	c901                	beqz	a0,ffffffffc02003dc <kmonitor+0xf6>
ffffffffc02003ce:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003d2:	00040023          	sb	zero,0(s0)
ffffffffc02003d6:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003d8:	d5c9                	beqz	a1,ffffffffc0200362 <kmonitor+0x7c>
ffffffffc02003da:	b7f5                	j	ffffffffc02003c6 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02003dc:	00044783          	lbu	a5,0(s0)
ffffffffc02003e0:	d3c9                	beqz	a5,ffffffffc0200362 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02003e2:	033c8963          	beq	s9,s3,ffffffffc0200414 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02003e6:	003c9793          	slli	a5,s9,0x3
ffffffffc02003ea:	0118                	addi	a4,sp,128
ffffffffc02003ec:	97ba                	add	a5,a5,a4
ffffffffc02003ee:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003f2:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003f6:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003f8:	e591                	bnez	a1,ffffffffc0200404 <kmonitor+0x11e>
ffffffffc02003fa:	b7b5                	j	ffffffffc0200366 <kmonitor+0x80>
ffffffffc02003fc:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200400:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200402:	d1a5                	beqz	a1,ffffffffc0200362 <kmonitor+0x7c>
ffffffffc0200404:	8526                	mv	a0,s1
ffffffffc0200406:	530010ef          	jal	ra,ffffffffc0201936 <strchr>
ffffffffc020040a:	d96d                	beqz	a0,ffffffffc02003fc <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020040c:	00044583          	lbu	a1,0(s0)
ffffffffc0200410:	d9a9                	beqz	a1,ffffffffc0200362 <kmonitor+0x7c>
ffffffffc0200412:	bf55                	j	ffffffffc02003c6 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200414:	45c1                	li	a1,16
ffffffffc0200416:	855a                	mv	a0,s6
ffffffffc0200418:	cc1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020041c:	b7e9                	j	ffffffffc02003e6 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020041e:	6582                	ld	a1,0(sp)
ffffffffc0200420:	00002517          	auipc	a0,0x2
ffffffffc0200424:	cb050513          	addi	a0,a0,-848 # ffffffffc02020d0 <etext+0x266>
ffffffffc0200428:	cb1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    return 0;
ffffffffc020042c:	b715                	j	ffffffffc0200350 <kmonitor+0x6a>

ffffffffc020042e <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020042e:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200430:	00002517          	auipc	a0,0x2
ffffffffc0200434:	d0050513          	addi	a0,a0,-768 # ffffffffc0202130 <commands+0x48>
void dtb_init(void) {
ffffffffc0200438:	fc86                	sd	ra,120(sp)
ffffffffc020043a:	f8a2                	sd	s0,112(sp)
ffffffffc020043c:	e8d2                	sd	s4,80(sp)
ffffffffc020043e:	f4a6                	sd	s1,104(sp)
ffffffffc0200440:	f0ca                	sd	s2,96(sp)
ffffffffc0200442:	ecce                	sd	s3,88(sp)
ffffffffc0200444:	e4d6                	sd	s5,72(sp)
ffffffffc0200446:	e0da                	sd	s6,64(sp)
ffffffffc0200448:	fc5e                	sd	s7,56(sp)
ffffffffc020044a:	f862                	sd	s8,48(sp)
ffffffffc020044c:	f466                	sd	s9,40(sp)
ffffffffc020044e:	f06a                	sd	s10,32(sp)
ffffffffc0200450:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200452:	c87ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200456:	00006597          	auipc	a1,0x6
ffffffffc020045a:	baa5b583          	ld	a1,-1110(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc020045e:	00002517          	auipc	a0,0x2
ffffffffc0200462:	ce250513          	addi	a0,a0,-798 # ffffffffc0202140 <commands+0x58>
ffffffffc0200466:	c73ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020046a:	00006417          	auipc	s0,0x6
ffffffffc020046e:	b9e40413          	addi	s0,s0,-1122 # ffffffffc0206008 <boot_dtb>
ffffffffc0200472:	600c                	ld	a1,0(s0)
ffffffffc0200474:	00002517          	auipc	a0,0x2
ffffffffc0200478:	cdc50513          	addi	a0,a0,-804 # ffffffffc0202150 <commands+0x68>
ffffffffc020047c:	c5dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200480:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200484:	00002517          	auipc	a0,0x2
ffffffffc0200488:	ce450513          	addi	a0,a0,-796 # ffffffffc0202168 <commands+0x80>
    if (boot_dtb == 0) {
ffffffffc020048c:	120a0463          	beqz	s4,ffffffffc02005b4 <dtb_init+0x186>
        return;
    }

    // 转换为虚拟地址， PHYSICAL_MEMORY_OFFSET 是物理地址到虚拟地址的映射偏移量。
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200490:	57f5                	li	a5,-3
ffffffffc0200492:	07fa                	slli	a5,a5,0x1e
ffffffffc0200494:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200498:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020049a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020049e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004a0:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004a4:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a8:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ac:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b4:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b6:	8ec9                	or	a3,a3,a0
ffffffffc02004b8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004bc:	1b7d                	addi	s6,s6,-1
ffffffffc02004be:	0167f7b3          	and	a5,a5,s6
ffffffffc02004c2:	8dd5                	or	a1,a1,a3
ffffffffc02004c4:	8ddd                	or	a1,a1,a5
    /**
     * 这是用于检查设备树（DTB）文件头的魔数（magic number）是否正确。
     * 0xd00dfeed 是DTB文件的标准魔数。
     * 如果读取到的 magic 不等于这个值，说明DTB文件格式错误或数据损坏，于是打印错误信息并返回，不再继续解析DTB内容。
     */
    if (magic != 0xd00dfeed) {
ffffffffc02004c6:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ca:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02004cc:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a4d>
ffffffffc02004d0:	10f59163          	bne	a1,a5,ffffffffc02005d2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02004d4:	471c                	lw	a5,8(a4)
ffffffffc02004d6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02004d8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004da:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004de:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02004e2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ea:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ee:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fa:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fe:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200502:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200504:	01146433          	or	s0,s0,a7
ffffffffc0200508:	0086969b          	slliw	a3,a3,0x8
ffffffffc020050c:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200510:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200512:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200516:	8c49                	or	s0,s0,a0
ffffffffc0200518:	0166f6b3          	and	a3,a3,s6
ffffffffc020051c:	00ca6a33          	or	s4,s4,a2
ffffffffc0200520:	0167f7b3          	and	a5,a5,s6
ffffffffc0200524:	8c55                	or	s0,s0,a3
ffffffffc0200526:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020052a:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020052c:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020052e:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200530:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200534:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200536:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200538:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020053c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020053e:	00002917          	auipc	s2,0x2
ffffffffc0200542:	c7a90913          	addi	s2,s2,-902 # ffffffffc02021b8 <commands+0xd0>
ffffffffc0200546:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200548:	4d91                	li	s11,4
ffffffffc020054a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020054c:	00002497          	auipc	s1,0x2
ffffffffc0200550:	c6448493          	addi	s1,s1,-924 # ffffffffc02021b0 <commands+0xc8>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200554:	000a2703          	lw	a4,0(s4)
ffffffffc0200558:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020055c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200560:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200564:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200568:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020056c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200570:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200572:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200576:	0087171b          	slliw	a4,a4,0x8
ffffffffc020057a:	8fd5                	or	a5,a5,a3
ffffffffc020057c:	00eb7733          	and	a4,s6,a4
ffffffffc0200580:	8fd9                	or	a5,a5,a4
ffffffffc0200582:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200584:	09778c63          	beq	a5,s7,ffffffffc020061c <dtb_init+0x1ee>
ffffffffc0200588:	00fbea63          	bltu	s7,a5,ffffffffc020059c <dtb_init+0x16e>
ffffffffc020058c:	07a78663          	beq	a5,s10,ffffffffc02005f8 <dtb_init+0x1ca>
ffffffffc0200590:	4709                	li	a4,2
ffffffffc0200592:	00e79763          	bne	a5,a4,ffffffffc02005a0 <dtb_init+0x172>
ffffffffc0200596:	4c81                	li	s9,0
ffffffffc0200598:	8a56                	mv	s4,s5
ffffffffc020059a:	bf6d                	j	ffffffffc0200554 <dtb_init+0x126>
ffffffffc020059c:	ffb78ee3          	beq	a5,s11,ffffffffc0200598 <dtb_init+0x16a>
        // 保存到全局变量，供 PMM 查询
        // PMM（Physical Memory Management，物理内存管理）是操作系统内核中负责管理物理内存分配和释放的模块。它用于跟踪哪些物理内存已被使用、哪些空闲，并为内核或用户程序分配所需的物理内存页。
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005a0:	00002517          	auipc	a0,0x2
ffffffffc02005a4:	c9050513          	addi	a0,a0,-880 # ffffffffc0202230 <commands+0x148>
ffffffffc02005a8:	b31ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	cbc50513          	addi	a0,a0,-836 # ffffffffc0202268 <commands+0x180>
}
ffffffffc02005b4:	7446                	ld	s0,112(sp)
ffffffffc02005b6:	70e6                	ld	ra,120(sp)
ffffffffc02005b8:	74a6                	ld	s1,104(sp)
ffffffffc02005ba:	7906                	ld	s2,96(sp)
ffffffffc02005bc:	69e6                	ld	s3,88(sp)
ffffffffc02005be:	6a46                	ld	s4,80(sp)
ffffffffc02005c0:	6aa6                	ld	s5,72(sp)
ffffffffc02005c2:	6b06                	ld	s6,64(sp)
ffffffffc02005c4:	7be2                	ld	s7,56(sp)
ffffffffc02005c6:	7c42                	ld	s8,48(sp)
ffffffffc02005c8:	7ca2                	ld	s9,40(sp)
ffffffffc02005ca:	7d02                	ld	s10,32(sp)
ffffffffc02005cc:	6de2                	ld	s11,24(sp)
ffffffffc02005ce:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02005d0:	b621                	j	ffffffffc02000d8 <cprintf>
}
ffffffffc02005d2:	7446                	ld	s0,112(sp)
ffffffffc02005d4:	70e6                	ld	ra,120(sp)
ffffffffc02005d6:	74a6                	ld	s1,104(sp)
ffffffffc02005d8:	7906                	ld	s2,96(sp)
ffffffffc02005da:	69e6                	ld	s3,88(sp)
ffffffffc02005dc:	6a46                	ld	s4,80(sp)
ffffffffc02005de:	6aa6                	ld	s5,72(sp)
ffffffffc02005e0:	6b06                	ld	s6,64(sp)
ffffffffc02005e2:	7be2                	ld	s7,56(sp)
ffffffffc02005e4:	7c42                	ld	s8,48(sp)
ffffffffc02005e6:	7ca2                	ld	s9,40(sp)
ffffffffc02005e8:	7d02                	ld	s10,32(sp)
ffffffffc02005ea:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02005ec:	00002517          	auipc	a0,0x2
ffffffffc02005f0:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0202188 <commands+0xa0>
}
ffffffffc02005f4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02005f6:	b4cd                	j	ffffffffc02000d8 <cprintf>
                int name_len = strlen(name);
ffffffffc02005f8:	8556                	mv	a0,s5
ffffffffc02005fa:	2c2010ef          	jal	ra,ffffffffc02018bc <strlen>
ffffffffc02005fe:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200600:	4619                	li	a2,6
ffffffffc0200602:	85a6                	mv	a1,s1
ffffffffc0200604:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200606:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200608:	308010ef          	jal	ra,ffffffffc0201910 <strncmp>
ffffffffc020060c:	e111                	bnez	a0,ffffffffc0200610 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020060e:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200610:	0a91                	addi	s5,s5,4
ffffffffc0200612:	9ad2                	add	s5,s5,s4
ffffffffc0200614:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200618:	8a56                	mv	s4,s5
ffffffffc020061a:	bf2d                	j	ffffffffc0200554 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020061c:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200620:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200624:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200628:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020062c:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200630:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200634:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200638:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020063c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200640:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200644:	00eaeab3          	or	s5,s5,a4
ffffffffc0200648:	00fb77b3          	and	a5,s6,a5
ffffffffc020064c:	00faeab3          	or	s5,s5,a5
ffffffffc0200650:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200652:	000c9c63          	bnez	s9,ffffffffc020066a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200656:	1a82                	slli	s5,s5,0x20
ffffffffc0200658:	00368793          	addi	a5,a3,3
ffffffffc020065c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200660:	9abe                	add	s5,s5,a5
ffffffffc0200662:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200666:	8a56                	mv	s4,s5
ffffffffc0200668:	b5f5                	j	ffffffffc0200554 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020066a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020066e:	85ca                	mv	a1,s2
ffffffffc0200670:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200672:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200676:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020067e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200682:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200686:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200688:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020068c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200690:	8d59                	or	a0,a0,a4
ffffffffc0200692:	00fb77b3          	and	a5,s6,a5
ffffffffc0200696:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200698:	1502                	slli	a0,a0,0x20
ffffffffc020069a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020069c:	9522                	add	a0,a0,s0
ffffffffc020069e:	254010ef          	jal	ra,ffffffffc02018f2 <strcmp>
ffffffffc02006a2:	66a2                	ld	a3,8(sp)
ffffffffc02006a4:	f94d                	bnez	a0,ffffffffc0200656 <dtb_init+0x228>
ffffffffc02006a6:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200656 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006aa:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006ae:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02006b2:	00002517          	auipc	a0,0x2
ffffffffc02006b6:	b0e50513          	addi	a0,a0,-1266 # ffffffffc02021c0 <commands+0xd8>
           fdt32_to_cpu(x >> 32);
ffffffffc02006ba:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006be:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02006c2:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02006ca:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ce:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d6:	0187d693          	srli	a3,a5,0x18
ffffffffc02006da:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02006de:	0087579b          	srliw	a5,a4,0x8
ffffffffc02006e2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02006ea:	010f6f33          	or	t5,t5,a6
ffffffffc02006ee:	0187529b          	srliw	t0,a4,0x18
ffffffffc02006f2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006f6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006fa:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fe:	0186f6b3          	and	a3,a3,s8
ffffffffc0200702:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200706:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020070a:	0107581b          	srliw	a6,a4,0x10
ffffffffc020070e:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200712:	8361                	srli	a4,a4,0x18
ffffffffc0200714:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200718:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020071c:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200720:	00cb7633          	and	a2,s6,a2
ffffffffc0200724:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200728:	0085959b          	slliw	a1,a1,0x8
ffffffffc020072c:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200730:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200740:	011b78b3          	and	a7,s6,a7
ffffffffc0200744:	005eeeb3          	or	t4,t4,t0
ffffffffc0200748:	00c6e733          	or	a4,a3,a2
ffffffffc020074c:	006c6c33          	or	s8,s8,t1
ffffffffc0200750:	010b76b3          	and	a3,s6,a6
ffffffffc0200754:	00bb7b33          	and	s6,s6,a1
ffffffffc0200758:	01d7e7b3          	or	a5,a5,t4
ffffffffc020075c:	016c6b33          	or	s6,s8,s6
ffffffffc0200760:	01146433          	or	s0,s0,a7
ffffffffc0200764:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200766:	1702                	slli	a4,a4,0x20
ffffffffc0200768:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020076a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020076c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020076e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200770:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200774:	0167eb33          	or	s6,a5,s6
ffffffffc0200778:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020077a:	95fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020077e:	85a2                	mv	a1,s0
ffffffffc0200780:	00002517          	auipc	a0,0x2
ffffffffc0200784:	a6050513          	addi	a0,a0,-1440 # ffffffffc02021e0 <commands+0xf8>
ffffffffc0200788:	951ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020078c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200790:	85da                	mv	a1,s6
ffffffffc0200792:	00002517          	auipc	a0,0x2
ffffffffc0200796:	a6650513          	addi	a0,a0,-1434 # ffffffffc02021f8 <commands+0x110>
ffffffffc020079a:	93fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020079e:	008b05b3          	add	a1,s6,s0
ffffffffc02007a2:	15fd                	addi	a1,a1,-1
ffffffffc02007a4:	00002517          	auipc	a0,0x2
ffffffffc02007a8:	a7450513          	addi	a0,a0,-1420 # ffffffffc0202218 <commands+0x130>
ffffffffc02007ac:	92dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02007b0:	00002517          	auipc	a0,0x2
ffffffffc02007b4:	ab850513          	addi	a0,a0,-1352 # ffffffffc0202268 <commands+0x180>
        memory_base = mem_base;
ffffffffc02007b8:	00006797          	auipc	a5,0x6
ffffffffc02007bc:	c887b823          	sd	s0,-880(a5) # ffffffffc0206448 <memory_base>
        memory_size = mem_size;
ffffffffc02007c0:	00006797          	auipc	a5,0x6
ffffffffc02007c4:	c967b823          	sd	s6,-880(a5) # ffffffffc0206450 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02007c8:	b3f5                	j	ffffffffc02005b4 <dtb_init+0x186>

ffffffffc02007ca <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02007ca:	00006517          	auipc	a0,0x6
ffffffffc02007ce:	c7e53503          	ld	a0,-898(a0) # ffffffffc0206448 <memory_base>
ffffffffc02007d2:	8082                	ret

ffffffffc02007d4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02007d4:	00006517          	auipc	a0,0x6
ffffffffc02007d8:	c7c53503          	ld	a0,-900(a0) # ffffffffc0206450 <memory_size>
ffffffffc02007dc:	8082                	ret

ffffffffc02007de <clock_init>:
 * and then enable IRQ_TIMER.
 * 初始化时钟系统，使能定时器中断，并设置下一个时钟事件。
 * Spike环境下建议除以500，QEMU环境下建议除以100。
 * 初始化ticks计数器为0，并打印初始化信息。
 * */
void clock_init(void) {
ffffffffc02007de:	1141                	addi	sp,sp,-16
ffffffffc02007e0:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    // 使能Supervisor Timer Interrupt（STIP），允许定时器中断
    set_csr(sie, MIP_STIP);
ffffffffc02007e2:	02000793          	li	a5,32
ffffffffc02007e6:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02007ea:	c0102573          	rdtime	a0
 * 通过sbi_set_timer通知SBI层在指定周期数产生中断
 * 该函数会将下一个中断时间设为当前周期数加上timebase，实现周期性时钟中断。
 */
void clock_set_next_event(void) {
    // 设定下一个中断时间为当前周期数加上timebase
    sbi_set_timer(get_cycles() + timebase);
ffffffffc02007ee:	67e1                	lui	a5,0x18
ffffffffc02007f0:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02007f4:	953e                	add	a0,a0,a5
ffffffffc02007f6:	624010ef          	jal	ra,ffffffffc0201e1a <sbi_set_timer>
}
ffffffffc02007fa:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc02007fc:	00006797          	auipc	a5,0x6
ffffffffc0200800:	c407be23          	sd	zero,-932(a5) # ffffffffc0206458 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200804:	00002517          	auipc	a0,0x2
ffffffffc0200808:	a7c50513          	addi	a0,a0,-1412 # ffffffffc0202280 <commands+0x198>
}
ffffffffc020080c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020080e:	8cbff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200812 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200812:	c0102573          	rdtime	a0
    sbi_set_timer(get_cycles() + timebase);
ffffffffc0200816:	67e1                	lui	a5,0x18
ffffffffc0200818:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020081c:	953e                	add	a0,a0,a5
ffffffffc020081e:	5fc0106f          	j	ffffffffc0201e1a <sbi_set_timer>

ffffffffc0200822 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200822:	8082                	ret

ffffffffc0200824 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200824:	0ff57513          	zext.b	a0,a0
ffffffffc0200828:	5d80106f          	j	ffffffffc0201e00 <sbi_console_putchar>

ffffffffc020082c <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020082c:	6080106f          	j	ffffffffc0201e34 <sbi_console_getchar>

ffffffffc0200830 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200830:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200834:	8082                	ret

ffffffffc0200836 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200836:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020083a:	8082                	ret

ffffffffc020083c <idt_init>:
    // 1. 声明异常处理入口函数 __alltraps
    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    // 设置 sscratch 为 0，表示当前在内核态
    write_csr(sscratch, 0);
ffffffffc020083c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    // 设置异常向量表地址为 __alltraps
    write_csr(stvec, &__alltraps);
ffffffffc0200840:	00000797          	auipc	a5,0x0
ffffffffc0200844:	3dc78793          	addi	a5,a5,988 # ffffffffc0200c1c <__alltraps>
ffffffffc0200848:	10579073          	csrw	stvec,a5
}
ffffffffc020084c:	8082                	ret

ffffffffc020084e <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

// print_regs - 打印 pushregs 结构体内容，显示所有寄存器值
void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020084e:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200850:	1141                	addi	sp,sp,-16
ffffffffc0200852:	e022                	sd	s0,0(sp)
ffffffffc0200854:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200856:	00002517          	auipc	a0,0x2
ffffffffc020085a:	a4a50513          	addi	a0,a0,-1462 # ffffffffc02022a0 <commands+0x1b8>
void print_regs(struct pushregs *gpr) {
ffffffffc020085e:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200860:	879ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200864:	640c                	ld	a1,8(s0)
ffffffffc0200866:	00002517          	auipc	a0,0x2
ffffffffc020086a:	a5250513          	addi	a0,a0,-1454 # ffffffffc02022b8 <commands+0x1d0>
ffffffffc020086e:	86bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200872:	680c                	ld	a1,16(s0)
ffffffffc0200874:	00002517          	auipc	a0,0x2
ffffffffc0200878:	a5c50513          	addi	a0,a0,-1444 # ffffffffc02022d0 <commands+0x1e8>
ffffffffc020087c:	85dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200880:	6c0c                	ld	a1,24(s0)
ffffffffc0200882:	00002517          	auipc	a0,0x2
ffffffffc0200886:	a6650513          	addi	a0,a0,-1434 # ffffffffc02022e8 <commands+0x200>
ffffffffc020088a:	84fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020088e:	700c                	ld	a1,32(s0)
ffffffffc0200890:	00002517          	auipc	a0,0x2
ffffffffc0200894:	a7050513          	addi	a0,a0,-1424 # ffffffffc0202300 <commands+0x218>
ffffffffc0200898:	841ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020089c:	740c                	ld	a1,40(s0)
ffffffffc020089e:	00002517          	auipc	a0,0x2
ffffffffc02008a2:	a7a50513          	addi	a0,a0,-1414 # ffffffffc0202318 <commands+0x230>
ffffffffc02008a6:	833ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008aa:	780c                	ld	a1,48(s0)
ffffffffc02008ac:	00002517          	auipc	a0,0x2
ffffffffc02008b0:	a8450513          	addi	a0,a0,-1404 # ffffffffc0202330 <commands+0x248>
ffffffffc02008b4:	825ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008b8:	7c0c                	ld	a1,56(s0)
ffffffffc02008ba:	00002517          	auipc	a0,0x2
ffffffffc02008be:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0202348 <commands+0x260>
ffffffffc02008c2:	817ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008c6:	602c                	ld	a1,64(s0)
ffffffffc02008c8:	00002517          	auipc	a0,0x2
ffffffffc02008cc:	a9850513          	addi	a0,a0,-1384 # ffffffffc0202360 <commands+0x278>
ffffffffc02008d0:	809ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008d4:	642c                	ld	a1,72(s0)
ffffffffc02008d6:	00002517          	auipc	a0,0x2
ffffffffc02008da:	aa250513          	addi	a0,a0,-1374 # ffffffffc0202378 <commands+0x290>
ffffffffc02008de:	ffaff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008e2:	682c                	ld	a1,80(s0)
ffffffffc02008e4:	00002517          	auipc	a0,0x2
ffffffffc02008e8:	aac50513          	addi	a0,a0,-1364 # ffffffffc0202390 <commands+0x2a8>
ffffffffc02008ec:	fecff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008f0:	6c2c                	ld	a1,88(s0)
ffffffffc02008f2:	00002517          	auipc	a0,0x2
ffffffffc02008f6:	ab650513          	addi	a0,a0,-1354 # ffffffffc02023a8 <commands+0x2c0>
ffffffffc02008fa:	fdeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008fe:	702c                	ld	a1,96(s0)
ffffffffc0200900:	00002517          	auipc	a0,0x2
ffffffffc0200904:	ac050513          	addi	a0,a0,-1344 # ffffffffc02023c0 <commands+0x2d8>
ffffffffc0200908:	fd0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020090c:	742c                	ld	a1,104(s0)
ffffffffc020090e:	00002517          	auipc	a0,0x2
ffffffffc0200912:	aca50513          	addi	a0,a0,-1334 # ffffffffc02023d8 <commands+0x2f0>
ffffffffc0200916:	fc2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020091a:	782c                	ld	a1,112(s0)
ffffffffc020091c:	00002517          	auipc	a0,0x2
ffffffffc0200920:	ad450513          	addi	a0,a0,-1324 # ffffffffc02023f0 <commands+0x308>
ffffffffc0200924:	fb4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200928:	7c2c                	ld	a1,120(s0)
ffffffffc020092a:	00002517          	auipc	a0,0x2
ffffffffc020092e:	ade50513          	addi	a0,a0,-1314 # ffffffffc0202408 <commands+0x320>
ffffffffc0200932:	fa6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200936:	604c                	ld	a1,128(s0)
ffffffffc0200938:	00002517          	auipc	a0,0x2
ffffffffc020093c:	ae850513          	addi	a0,a0,-1304 # ffffffffc0202420 <commands+0x338>
ffffffffc0200940:	f98ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200944:	644c                	ld	a1,136(s0)
ffffffffc0200946:	00002517          	auipc	a0,0x2
ffffffffc020094a:	af250513          	addi	a0,a0,-1294 # ffffffffc0202438 <commands+0x350>
ffffffffc020094e:	f8aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200952:	684c                	ld	a1,144(s0)
ffffffffc0200954:	00002517          	auipc	a0,0x2
ffffffffc0200958:	afc50513          	addi	a0,a0,-1284 # ffffffffc0202450 <commands+0x368>
ffffffffc020095c:	f7cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200960:	6c4c                	ld	a1,152(s0)
ffffffffc0200962:	00002517          	auipc	a0,0x2
ffffffffc0200966:	b0650513          	addi	a0,a0,-1274 # ffffffffc0202468 <commands+0x380>
ffffffffc020096a:	f6eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020096e:	704c                	ld	a1,160(s0)
ffffffffc0200970:	00002517          	auipc	a0,0x2
ffffffffc0200974:	b1050513          	addi	a0,a0,-1264 # ffffffffc0202480 <commands+0x398>
ffffffffc0200978:	f60ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020097c:	744c                	ld	a1,168(s0)
ffffffffc020097e:	00002517          	auipc	a0,0x2
ffffffffc0200982:	b1a50513          	addi	a0,a0,-1254 # ffffffffc0202498 <commands+0x3b0>
ffffffffc0200986:	f52ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc020098a:	784c                	ld	a1,176(s0)
ffffffffc020098c:	00002517          	auipc	a0,0x2
ffffffffc0200990:	b2450513          	addi	a0,a0,-1244 # ffffffffc02024b0 <commands+0x3c8>
ffffffffc0200994:	f44ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200998:	7c4c                	ld	a1,184(s0)
ffffffffc020099a:	00002517          	auipc	a0,0x2
ffffffffc020099e:	b2e50513          	addi	a0,a0,-1234 # ffffffffc02024c8 <commands+0x3e0>
ffffffffc02009a2:	f36ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009a6:	606c                	ld	a1,192(s0)
ffffffffc02009a8:	00002517          	auipc	a0,0x2
ffffffffc02009ac:	b3850513          	addi	a0,a0,-1224 # ffffffffc02024e0 <commands+0x3f8>
ffffffffc02009b0:	f28ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009b4:	646c                	ld	a1,200(s0)
ffffffffc02009b6:	00002517          	auipc	a0,0x2
ffffffffc02009ba:	b4250513          	addi	a0,a0,-1214 # ffffffffc02024f8 <commands+0x410>
ffffffffc02009be:	f1aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009c2:	686c                	ld	a1,208(s0)
ffffffffc02009c4:	00002517          	auipc	a0,0x2
ffffffffc02009c8:	b4c50513          	addi	a0,a0,-1204 # ffffffffc0202510 <commands+0x428>
ffffffffc02009cc:	f0cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009d0:	6c6c                	ld	a1,216(s0)
ffffffffc02009d2:	00002517          	auipc	a0,0x2
ffffffffc02009d6:	b5650513          	addi	a0,a0,-1194 # ffffffffc0202528 <commands+0x440>
ffffffffc02009da:	efeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009de:	706c                	ld	a1,224(s0)
ffffffffc02009e0:	00002517          	auipc	a0,0x2
ffffffffc02009e4:	b6050513          	addi	a0,a0,-1184 # ffffffffc0202540 <commands+0x458>
ffffffffc02009e8:	ef0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009ec:	746c                	ld	a1,232(s0)
ffffffffc02009ee:	00002517          	auipc	a0,0x2
ffffffffc02009f2:	b6a50513          	addi	a0,a0,-1174 # ffffffffc0202558 <commands+0x470>
ffffffffc02009f6:	ee2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009fa:	786c                	ld	a1,240(s0)
ffffffffc02009fc:	00002517          	auipc	a0,0x2
ffffffffc0200a00:	b7450513          	addi	a0,a0,-1164 # ffffffffc0202570 <commands+0x488>
ffffffffc0200a04:	ed4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a08:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a0a:	6402                	ld	s0,0(sp)
ffffffffc0200a0c:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a0e:	00002517          	auipc	a0,0x2
ffffffffc0200a12:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0202588 <commands+0x4a0>
}
ffffffffc0200a16:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a18:	ec0ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a1c <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a1c:	1141                	addi	sp,sp,-16
ffffffffc0200a1e:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a20:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a22:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a24:	00002517          	auipc	a0,0x2
ffffffffc0200a28:	b7c50513          	addi	a0,a0,-1156 # ffffffffc02025a0 <commands+0x4b8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a2c:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a2e:	eaaff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a32:	8522                	mv	a0,s0
ffffffffc0200a34:	e1bff0ef          	jal	ra,ffffffffc020084e <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a38:	10043583          	ld	a1,256(s0)
ffffffffc0200a3c:	00002517          	auipc	a0,0x2
ffffffffc0200a40:	b7c50513          	addi	a0,a0,-1156 # ffffffffc02025b8 <commands+0x4d0>
ffffffffc0200a44:	e94ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a48:	10843583          	ld	a1,264(s0)
ffffffffc0200a4c:	00002517          	auipc	a0,0x2
ffffffffc0200a50:	b8450513          	addi	a0,a0,-1148 # ffffffffc02025d0 <commands+0x4e8>
ffffffffc0200a54:	e84ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a58:	11043583          	ld	a1,272(s0)
ffffffffc0200a5c:	00002517          	auipc	a0,0x2
ffffffffc0200a60:	b8c50513          	addi	a0,a0,-1140 # ffffffffc02025e8 <commands+0x500>
ffffffffc0200a64:	e74ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a68:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a6c:	6402                	ld	s0,0(sp)
ffffffffc0200a6e:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a70:	00002517          	auipc	a0,0x2
ffffffffc0200a74:	b9050513          	addi	a0,a0,-1136 # ffffffffc0202600 <commands+0x518>
}
ffffffffc0200a78:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a7a:	e5eff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a7e <interrupt_handler>:

// interrupt_handler - 中断处理函数，根据 cause 判断中断类型并处理
    // trapframe 结构体保存异常现场，包括所有寄存器和相关状态
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a7e:	11853783          	ld	a5,280(a0)
ffffffffc0200a82:	472d                	li	a4,11
ffffffffc0200a84:	0786                	slli	a5,a5,0x1
ffffffffc0200a86:	8385                	srli	a5,a5,0x1
ffffffffc0200a88:	08f76c63          	bltu	a4,a5,ffffffffc0200b20 <interrupt_handler+0xa2>
ffffffffc0200a8c:	00002717          	auipc	a4,0x2
ffffffffc0200a90:	c7470713          	addi	a4,a4,-908 # ffffffffc0202700 <commands+0x618>
ffffffffc0200a94:	078a                	slli	a5,a5,0x2
ffffffffc0200a96:	97ba                	add	a5,a5,a4
ffffffffc0200a98:	439c                	lw	a5,0(a5)
ffffffffc0200a9a:	97ba                	add	a5,a5,a4
ffffffffc0200a9c:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a9e:	00002517          	auipc	a0,0x2
ffffffffc0200aa2:	bda50513          	addi	a0,a0,-1062 # ffffffffc0202678 <commands+0x590>
ffffffffc0200aa6:	e32ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200aaa:	00002517          	auipc	a0,0x2
ffffffffc0200aae:	bae50513          	addi	a0,a0,-1106 # ffffffffc0202658 <commands+0x570>
ffffffffc0200ab2:	e26ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200ab6:	00002517          	auipc	a0,0x2
ffffffffc0200aba:	b6250513          	addi	a0,a0,-1182 # ffffffffc0202618 <commands+0x530>
ffffffffc0200abe:	e1aff06f          	j	ffffffffc02000d8 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200ac2:	00002517          	auipc	a0,0x2
ffffffffc0200ac6:	bd650513          	addi	a0,a0,-1066 # ffffffffc0202698 <commands+0x5b0>
ffffffffc0200aca:	e0eff06f          	j	ffffffffc02000d8 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200ace:	1141                	addi	sp,sp,-16
ffffffffc0200ad0:	e022                	sd	s0,0(sp)
ffffffffc0200ad2:	e406                	sd	ra,8(sp)
            */
            // 1. 设置下次时钟中断
            // 2. 维护时钟计数器
            // 3. 每100次中断打印一次
            // 4. 达到指定次数后关机
            clock_set_next_event(); // 发生这次时钟中断的时候，我们要设置下一次时钟中断
ffffffffc0200ad4:	d3fff0ef          	jal	ra,ffffffffc0200812 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0)
ffffffffc0200ad8:	00006697          	auipc	a3,0x6
ffffffffc0200adc:	98068693          	addi	a3,a3,-1664 # ffffffffc0206458 <ticks>
ffffffffc0200ae0:	629c                	ld	a5,0(a3)
ffffffffc0200ae2:	06400713          	li	a4,100
ffffffffc0200ae6:	00006417          	auipc	s0,0x6
ffffffffc0200aea:	97a40413          	addi	s0,s0,-1670 # ffffffffc0206460 <print_num>
ffffffffc0200aee:	0785                	addi	a5,a5,1
ffffffffc0200af0:	02e7f733          	remu	a4,a5,a4
ffffffffc0200af4:	e29c                	sd	a5,0(a3)
ffffffffc0200af6:	c715                	beqz	a4,ffffffffc0200b22 <interrupt_handler+0xa4>
            {
              print_num++;
              print_ticks();
            }
            if (print_num == 10)
ffffffffc0200af8:	4018                	lw	a4,0(s0)
ffffffffc0200afa:	47a9                	li	a5,10
ffffffffc0200afc:	02f70f63          	beq	a4,a5,ffffffffc0200b3a <interrupt_handler+0xbc>
        default:
            // 未知中断类型，打印 trapframe 便于调试
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b00:	60a2                	ld	ra,8(sp)
ffffffffc0200b02:	6402                	ld	s0,0(sp)
ffffffffc0200b04:	0141                	addi	sp,sp,16
ffffffffc0200b06:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200b08:	00002517          	auipc	a0,0x2
ffffffffc0200b0c:	bd850513          	addi	a0,a0,-1064 # ffffffffc02026e0 <commands+0x5f8>
ffffffffc0200b10:	dc8ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200b14:	00002517          	auipc	a0,0x2
ffffffffc0200b18:	b2450513          	addi	a0,a0,-1244 # ffffffffc0202638 <commands+0x550>
ffffffffc0200b1c:	dbcff06f          	j	ffffffffc02000d8 <cprintf>
            print_trapframe(tf);
ffffffffc0200b20:	bdf5                	j	ffffffffc0200a1c <print_trapframe>
              print_num++;
ffffffffc0200b22:	401c                	lw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b24:	06400593          	li	a1,100
ffffffffc0200b28:	00002517          	auipc	a0,0x2
ffffffffc0200b2c:	b8850513          	addi	a0,a0,-1144 # ffffffffc02026b0 <commands+0x5c8>
              print_num++;
ffffffffc0200b30:	2785                	addiw	a5,a5,1
ffffffffc0200b32:	c01c                	sw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b34:	da4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
}
ffffffffc0200b38:	b7c1                	j	ffffffffc0200af8 <interrupt_handler+0x7a>
              cprintf("Calling SBI shutdown...\n");
ffffffffc0200b3a:	00002517          	auipc	a0,0x2
ffffffffc0200b3e:	b8650513          	addi	a0,a0,-1146 # ffffffffc02026c0 <commands+0x5d8>
ffffffffc0200b42:	d96ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
}
ffffffffc0200b46:	6402                	ld	s0,0(sp)
ffffffffc0200b48:	60a2                	ld	ra,8(sp)
ffffffffc0200b4a:	0141                	addi	sp,sp,16
              sbi_shutdown();
ffffffffc0200b4c:	3040106f          	j	ffffffffc0201e50 <sbi_shutdown>

ffffffffc0200b50 <exception_handler>:

// exception_handler - 异常处理函数，根据 cause 判断异常类型并处理
void exception_handler(struct trapframe *tf) {
ffffffffc0200b50:	7179                	addi	sp,sp,-48
ffffffffc0200b52:	f022                	sd	s0,32(sp)
    switch (tf->cause) {
ffffffffc0200b54:	11853403          	ld	s0,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b58:	ec26                	sd	s1,24(sp)
ffffffffc0200b5a:	e84a                	sd	s2,16(sp)
ffffffffc0200b5c:	f406                	sd	ra,40(sp)
ffffffffc0200b5e:	e44e                	sd	s3,8(sp)
    switch (tf->cause) {
ffffffffc0200b60:	490d                	li	s2,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200b62:	84aa                	mv	s1,a0
    switch (tf->cause) {
ffffffffc0200b64:	07240163          	beq	s0,s2,ffffffffc0200bc6 <exception_handler+0x76>
ffffffffc0200b68:	04896463          	bltu	s2,s0,ffffffffc0200bb0 <exception_handler+0x60>
ffffffffc0200b6c:	4789                	li	a5,2
ffffffffc0200b6e:	02f41a63          	bne	s0,a5,ffffffffc0200ba2 <exception_handler+0x52>
            */
            // 1. 打印非法指令异常信息
            // 2. 打印异常指令地址
            // 3. 跳过异常指令，更新 epc
            {
                cprintf("Exception type:Illegal instruction\n");
ffffffffc0200b72:	00002517          	auipc	a0,0x2
ffffffffc0200b76:	bbe50513          	addi	a0,a0,-1090 # ffffffffc0202730 <commands+0x648>
ffffffffc0200b7a:	d5eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
                uintptr_t ep = tf->epc;
ffffffffc0200b7e:	1084b983          	ld	s3,264(s1)
                cprintf("Illegal instruction caught at 0x%08x\n", (unsigned)ep);
ffffffffc0200b82:	00002517          	auipc	a0,0x2
ffffffffc0200b86:	bd650513          	addi	a0,a0,-1066 # ffffffffc0202758 <commands+0x670>
ffffffffc0200b8a:	0009859b          	sext.w	a1,s3
ffffffffc0200b8e:	d4aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    trap_dispatch(tf);
}

static inline int riscv_inst_length(uintptr_t epc) {
    volatile uint16_t *p16 = (volatile uint16_t *)epc;
    uint16_t low = *p16;
ffffffffc0200b92:	0009d783          	lhu	a5,0(s3)
    int len = (low & 0x3) != 0x3 ? 2 : 4;
ffffffffc0200b96:	8b8d                	andi	a5,a5,3
ffffffffc0200b98:	07278963          	beq	a5,s2,ffffffffc0200c0a <exception_handler+0xba>
                tf->epc = ep + ilen;
ffffffffc0200b9c:	944e                	add	s0,s0,s3
ffffffffc0200b9e:	1084b423          	sd	s0,264(s1)
}
ffffffffc0200ba2:	70a2                	ld	ra,40(sp)
ffffffffc0200ba4:	7402                	ld	s0,32(sp)
ffffffffc0200ba6:	64e2                	ld	s1,24(sp)
ffffffffc0200ba8:	6942                	ld	s2,16(sp)
ffffffffc0200baa:	69a2                	ld	s3,8(sp)
ffffffffc0200bac:	6145                	addi	sp,sp,48
ffffffffc0200bae:	8082                	ret
    switch (tf->cause) {
ffffffffc0200bb0:	1471                	addi	s0,s0,-4
ffffffffc0200bb2:	479d                	li	a5,7
ffffffffc0200bb4:	fe87f7e3          	bgeu	a5,s0,ffffffffc0200ba2 <exception_handler+0x52>
}
ffffffffc0200bb8:	7402                	ld	s0,32(sp)
ffffffffc0200bba:	70a2                	ld	ra,40(sp)
ffffffffc0200bbc:	64e2                	ld	s1,24(sp)
ffffffffc0200bbe:	6942                	ld	s2,16(sp)
ffffffffc0200bc0:	69a2                	ld	s3,8(sp)
ffffffffc0200bc2:	6145                	addi	sp,sp,48
            print_trapframe(tf);
ffffffffc0200bc4:	bda1                	j	ffffffffc0200a1c <print_trapframe>
                cprintf("Exception type: breakpoint\n");
ffffffffc0200bc6:	00002517          	auipc	a0,0x2
ffffffffc0200bca:	bba50513          	addi	a0,a0,-1094 # ffffffffc0202780 <commands+0x698>
ffffffffc0200bce:	d0aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
                uintptr_t ep = tf->epc;
ffffffffc0200bd2:	1084b903          	ld	s2,264(s1)
                cprintf("ebreak caught at 0x%08x\n", (unsigned)ep);
ffffffffc0200bd6:	00002517          	auipc	a0,0x2
ffffffffc0200bda:	bca50513          	addi	a0,a0,-1078 # ffffffffc02027a0 <commands+0x6b8>
ffffffffc0200bde:	0009059b          	sext.w	a1,s2
ffffffffc0200be2:	cf6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    uint16_t low = *p16;
ffffffffc0200be6:	00095783          	lhu	a5,0(s2)
    int len = (low & 0x3) != 0x3 ? 2 : 4;
ffffffffc0200bea:	4709                	li	a4,2
ffffffffc0200bec:	8b8d                	andi	a5,a5,3
ffffffffc0200bee:	00878c63          	beq	a5,s0,ffffffffc0200c06 <exception_handler+0xb6>
}
ffffffffc0200bf2:	70a2                	ld	ra,40(sp)
ffffffffc0200bf4:	7402                	ld	s0,32(sp)
                tf->epc = ep + ilen;
ffffffffc0200bf6:	993a                	add	s2,s2,a4
ffffffffc0200bf8:	1124b423          	sd	s2,264(s1)
}
ffffffffc0200bfc:	69a2                	ld	s3,8(sp)
ffffffffc0200bfe:	64e2                	ld	s1,24(sp)
ffffffffc0200c00:	6942                	ld	s2,16(sp)
ffffffffc0200c02:	6145                	addi	sp,sp,48
ffffffffc0200c04:	8082                	ret
    int len = (low & 0x3) != 0x3 ? 2 : 4;
ffffffffc0200c06:	4711                	li	a4,4
ffffffffc0200c08:	b7ed                	j	ffffffffc0200bf2 <exception_handler+0xa2>
ffffffffc0200c0a:	4411                	li	s0,4
ffffffffc0200c0c:	bf41                	j	ffffffffc0200b9c <exception_handler+0x4c>

ffffffffc0200c0e <trap>:
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c0e:	11853783          	ld	a5,280(a0)
ffffffffc0200c12:	0007c363          	bltz	a5,ffffffffc0200c18 <trap+0xa>
        exception_handler(tf);
ffffffffc0200c16:	bf2d                	j	ffffffffc0200b50 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200c18:	b59d                	j	ffffffffc0200a7e <interrupt_handler>
	...

ffffffffc0200c1c <__alltraps>:

    // 异常入口，全局符号
    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL                   // 保存现场
ffffffffc0200c1c:	14011073          	csrw	sscratch,sp
ffffffffc0200c20:	712d                	addi	sp,sp,-288
ffffffffc0200c22:	e002                	sd	zero,0(sp)
ffffffffc0200c24:	e406                	sd	ra,8(sp)
ffffffffc0200c26:	ec0e                	sd	gp,24(sp)
ffffffffc0200c28:	f012                	sd	tp,32(sp)
ffffffffc0200c2a:	f416                	sd	t0,40(sp)
ffffffffc0200c2c:	f81a                	sd	t1,48(sp)
ffffffffc0200c2e:	fc1e                	sd	t2,56(sp)
ffffffffc0200c30:	e0a2                	sd	s0,64(sp)
ffffffffc0200c32:	e4a6                	sd	s1,72(sp)
ffffffffc0200c34:	e8aa                	sd	a0,80(sp)
ffffffffc0200c36:	ecae                	sd	a1,88(sp)
ffffffffc0200c38:	f0b2                	sd	a2,96(sp)
ffffffffc0200c3a:	f4b6                	sd	a3,104(sp)
ffffffffc0200c3c:	f8ba                	sd	a4,112(sp)
ffffffffc0200c3e:	fcbe                	sd	a5,120(sp)
ffffffffc0200c40:	e142                	sd	a6,128(sp)
ffffffffc0200c42:	e546                	sd	a7,136(sp)
ffffffffc0200c44:	e94a                	sd	s2,144(sp)
ffffffffc0200c46:	ed4e                	sd	s3,152(sp)
ffffffffc0200c48:	f152                	sd	s4,160(sp)
ffffffffc0200c4a:	f556                	sd	s5,168(sp)
ffffffffc0200c4c:	f95a                	sd	s6,176(sp)
ffffffffc0200c4e:	fd5e                	sd	s7,184(sp)
ffffffffc0200c50:	e1e2                	sd	s8,192(sp)
ffffffffc0200c52:	e5e6                	sd	s9,200(sp)
ffffffffc0200c54:	e9ea                	sd	s10,208(sp)
ffffffffc0200c56:	edee                	sd	s11,216(sp)
ffffffffc0200c58:	f1f2                	sd	t3,224(sp)
ffffffffc0200c5a:	f5f6                	sd	t4,232(sp)
ffffffffc0200c5c:	f9fa                	sd	t5,240(sp)
ffffffffc0200c5e:	fdfe                	sd	t6,248(sp)
ffffffffc0200c60:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c64:	100024f3          	csrr	s1,sstatus
ffffffffc0200c68:	14102973          	csrr	s2,sepc
ffffffffc0200c6c:	143029f3          	csrr	s3,stval
ffffffffc0200c70:	14202a73          	csrr	s4,scause
ffffffffc0200c74:	e822                	sd	s0,16(sp)
ffffffffc0200c76:	e226                	sd	s1,256(sp)
ffffffffc0200c78:	e64a                	sd	s2,264(sp)
ffffffffc0200c7a:	ea4e                	sd	s3,272(sp)
ffffffffc0200c7c:	ee52                	sd	s4,280(sp)

    move  a0, sp               // 将sp传给trap函数（参数a0）
ffffffffc0200c7e:	850a                	mv	a0,sp
    jal trap                   // 跳转到trap处理函数
ffffffffc0200c80:	f8fff0ef          	jal	ra,ffffffffc0200c0e <trap>

ffffffffc0200c84 <__trapret>:
    # trap返回后，sp应与进入trap前一致

    // 异常返回，全局符号
    .globl __trapret
__trapret:
    RESTORE_ALL                // 恢复现场
ffffffffc0200c84:	6492                	ld	s1,256(sp)
ffffffffc0200c86:	6932                	ld	s2,264(sp)
ffffffffc0200c88:	10049073          	csrw	sstatus,s1
ffffffffc0200c8c:	14191073          	csrw	sepc,s2
ffffffffc0200c90:	60a2                	ld	ra,8(sp)
ffffffffc0200c92:	61e2                	ld	gp,24(sp)
ffffffffc0200c94:	7202                	ld	tp,32(sp)
ffffffffc0200c96:	72a2                	ld	t0,40(sp)
ffffffffc0200c98:	7342                	ld	t1,48(sp)
ffffffffc0200c9a:	73e2                	ld	t2,56(sp)
ffffffffc0200c9c:	6406                	ld	s0,64(sp)
ffffffffc0200c9e:	64a6                	ld	s1,72(sp)
ffffffffc0200ca0:	6546                	ld	a0,80(sp)
ffffffffc0200ca2:	65e6                	ld	a1,88(sp)
ffffffffc0200ca4:	7606                	ld	a2,96(sp)
ffffffffc0200ca6:	76a6                	ld	a3,104(sp)
ffffffffc0200ca8:	7746                	ld	a4,112(sp)
ffffffffc0200caa:	77e6                	ld	a5,120(sp)
ffffffffc0200cac:	680a                	ld	a6,128(sp)
ffffffffc0200cae:	68aa                	ld	a7,136(sp)
ffffffffc0200cb0:	694a                	ld	s2,144(sp)
ffffffffc0200cb2:	69ea                	ld	s3,152(sp)
ffffffffc0200cb4:	7a0a                	ld	s4,160(sp)
ffffffffc0200cb6:	7aaa                	ld	s5,168(sp)
ffffffffc0200cb8:	7b4a                	ld	s6,176(sp)
ffffffffc0200cba:	7bea                	ld	s7,184(sp)
ffffffffc0200cbc:	6c0e                	ld	s8,192(sp)
ffffffffc0200cbe:	6cae                	ld	s9,200(sp)
ffffffffc0200cc0:	6d4e                	ld	s10,208(sp)
ffffffffc0200cc2:	6dee                	ld	s11,216(sp)
ffffffffc0200cc4:	7e0e                	ld	t3,224(sp)
ffffffffc0200cc6:	7eae                	ld	t4,232(sp)
ffffffffc0200cc8:	7f4e                	ld	t5,240(sp)
ffffffffc0200cca:	7fee                	ld	t6,248(sp)
ffffffffc0200ccc:	6142                	ld	sp,16(sp)
    # 从supervisor模式返回
    sret                       // 异常返回指令
ffffffffc0200cce:	10200073          	sret

ffffffffc0200cd2 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200cd2:	00005797          	auipc	a5,0x5
ffffffffc0200cd6:	7a67b783          	ld	a5,1958(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200cda:	6f9c                	ld	a5,24(a5)
ffffffffc0200cdc:	8782                	jr	a5

ffffffffc0200cde <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200cde:	00005797          	auipc	a5,0x5
ffffffffc0200ce2:	79a7b783          	ld	a5,1946(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200ce6:	739c                	ld	a5,32(a5)
ffffffffc0200ce8:	8782                	jr	a5

ffffffffc0200cea <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200cea:	00005797          	auipc	a5,0x5
ffffffffc0200cee:	78e7b783          	ld	a5,1934(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200cf2:	779c                	ld	a5,40(a5)
ffffffffc0200cf4:	8782                	jr	a5

ffffffffc0200cf6 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200cf6:	00002797          	auipc	a5,0x2
ffffffffc0200cfa:	f5a78793          	addi	a5,a5,-166 # ffffffffc0202c50 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200cfe:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200d00:	715d                	addi	sp,sp,-80
ffffffffc0200d02:	fc26                	sd	s1,56(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200d04:	00002517          	auipc	a0,0x2
ffffffffc0200d08:	abc50513          	addi	a0,a0,-1348 # ffffffffc02027c0 <commands+0x6d8>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200d0c:	00005497          	auipc	s1,0x5
ffffffffc0200d10:	76c48493          	addi	s1,s1,1900 # ffffffffc0206478 <pmm_manager>
void pmm_init(void) {
ffffffffc0200d14:	e486                	sd	ra,72(sp)
ffffffffc0200d16:	e0a2                	sd	s0,64(sp)
ffffffffc0200d18:	f84a                	sd	s2,48(sp)
ffffffffc0200d1a:	f44e                	sd	s3,40(sp)
ffffffffc0200d1c:	f052                	sd	s4,32(sp)
ffffffffc0200d1e:	ec56                	sd	s5,24(sp)
ffffffffc0200d20:	e85a                	sd	s6,16(sp)
ffffffffc0200d22:	e45e                	sd	s7,8(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200d24:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200d26:	bb2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    pmm_manager->init();
ffffffffc0200d2a:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200d2c:	00005917          	auipc	s2,0x5
ffffffffc0200d30:	76490913          	addi	s2,s2,1892 # ffffffffc0206490 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200d34:	679c                	ld	a5,8(a5)
ffffffffc0200d36:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200d38:	57f5                	li	a5,-3
ffffffffc0200d3a:	07fa                	slli	a5,a5,0x1e
ffffffffc0200d3c:	00f93023          	sd	a5,0(s2)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200d40:	a8bff0ef          	jal	ra,ffffffffc02007ca <get_memory_base>
ffffffffc0200d44:	842a                	mv	s0,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200d46:	a8fff0ef          	jal	ra,ffffffffc02007d4 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200d4a:	18050963          	beqz	a0,ffffffffc0200edc <pmm_init+0x1e6>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200d4e:	8aaa                	mv	s5,a0
    cprintf("physcial memory map:\n");
ffffffffc0200d50:	00002517          	auipc	a0,0x2
ffffffffc0200d54:	ab850513          	addi	a0,a0,-1352 # ffffffffc0202808 <commands+0x720>
ffffffffc0200d58:	b80ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200d5c:	015409b3          	add	s3,s0,s5
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200d60:	fff98693          	addi	a3,s3,-1
ffffffffc0200d64:	8622                	mv	a2,s0
ffffffffc0200d66:	85d6                	mv	a1,s5
ffffffffc0200d68:	00002517          	auipc	a0,0x2
ffffffffc0200d6c:	ab850513          	addi	a0,a0,-1352 # ffffffffc0202820 <commands+0x738>
ffffffffc0200d70:	b68ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200d74:	c80007b7          	lui	a5,0xc8000
ffffffffc0200d78:	884e                	mv	a6,s3
ffffffffc0200d7a:	0f37ee63          	bltu	a5,s3,ffffffffc0200e76 <pmm_init+0x180>
ffffffffc0200d7e:	77fd                	lui	a5,0xfffff
ffffffffc0200d80:	00006697          	auipc	a3,0x6
ffffffffc0200d84:	71f68693          	addi	a3,a3,1823 # ffffffffc020749f <end+0xfff>
ffffffffc0200d88:	8efd                	and	a3,a3,a5
ffffffffc0200d8a:	00c85813          	srli	a6,a6,0xc
ffffffffc0200d8e:	00005b17          	auipc	s6,0x5
ffffffffc0200d92:	6dab0b13          	addi	s6,s6,1754 # ffffffffc0206468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200d96:	00005b97          	auipc	s7,0x5
ffffffffc0200d9a:	6dab8b93          	addi	s7,s7,1754 # ffffffffc0206470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0200d9e:	010b3023          	sd	a6,0(s6)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200da2:	00dbb023          	sd	a3,0(s7)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200da6:	000807b7          	lui	a5,0x80
ffffffffc0200daa:	002005b7          	lui	a1,0x200
ffffffffc0200dae:	02f80563          	beq	a6,a5,ffffffffc0200dd8 <pmm_init+0xe2>
ffffffffc0200db2:	00281593          	slli	a1,a6,0x2
ffffffffc0200db6:	01058633          	add	a2,a1,a6
ffffffffc0200dba:	fec007b7          	lui	a5,0xfec00
ffffffffc0200dbe:	97b6                	add	a5,a5,a3
ffffffffc0200dc0:	060e                	slli	a2,a2,0x3
ffffffffc0200dc2:	963e                	add	a2,a2,a5
ffffffffc0200dc4:	87b6                	mv	a5,a3
        SetPageReserved(pages + i);
ffffffffc0200dc6:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200dc8:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9b88>
        SetPageReserved(pages + i);
ffffffffc0200dcc:	00176713          	ori	a4,a4,1
ffffffffc0200dd0:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200dd4:	fef619e3          	bne	a2,a5,ffffffffc0200dc6 <pmm_init+0xd0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200dd8:	fec007b7          	lui	a5,0xfec00
ffffffffc0200ddc:	95c2                	add	a1,a1,a6
ffffffffc0200dde:	96be                	add	a3,a3,a5
ffffffffc0200de0:	058e                	slli	a1,a1,0x3
ffffffffc0200de2:	96ae                	add	a3,a3,a1
ffffffffc0200de4:	c02007b7          	lui	a5,0xc0200
ffffffffc0200de8:	0cf6ee63          	bltu	a3,a5,ffffffffc0200ec4 <pmm_init+0x1ce>
ffffffffc0200dec:	00093403          	ld	s0,0(s2)
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200df0:	6a05                	lui	s4,0x1
ffffffffc0200df2:	1a7d                	addi	s4,s4,-1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200df4:	40868433          	sub	s0,a3,s0
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200df8:	75fd                	lui	a1,0xfffff
ffffffffc0200dfa:	9a22                	add	s4,s4,s0
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200dfc:	00b9f9b3          	and	s3,s3,a1
ffffffffc0200e00:	00ba7a33          	and	s4,s4,a1
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200e04:	fff98693          	addi	a3,s3,-1
ffffffffc0200e08:	8652                	mv	a2,s4
ffffffffc0200e0a:	85d6                	mv	a1,s5
ffffffffc0200e0c:	00002517          	auipc	a0,0x2
ffffffffc0200e10:	a1450513          	addi	a0,a0,-1516 # ffffffffc0202820 <commands+0x738>
ffffffffc0200e14:	ac4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    if (freemem < mem_end) {
ffffffffc0200e18:	07346263          	bltu	s0,s3,ffffffffc0200e7c <pmm_init+0x186>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200e1c:	609c                	ld	a5,0(s1)
ffffffffc0200e1e:	7b9c                	ld	a5,48(a5)
ffffffffc0200e20:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200e22:	00002517          	auipc	a0,0x2
ffffffffc0200e26:	a8650513          	addi	a0,a0,-1402 # ffffffffc02028a8 <commands+0x7c0>
ffffffffc0200e2a:	aaeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200e2e:	00004597          	auipc	a1,0x4
ffffffffc0200e32:	1d258593          	addi	a1,a1,466 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200e36:	00005797          	auipc	a5,0x5
ffffffffc0200e3a:	64b7b923          	sd	a1,1618(a5) # ffffffffc0206488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200e3e:	c02007b7          	lui	a5,0xc0200
ffffffffc0200e42:	0af5e963          	bltu	a1,a5,ffffffffc0200ef4 <pmm_init+0x1fe>
ffffffffc0200e46:	00093603          	ld	a2,0(s2)
}
ffffffffc0200e4a:	6406                	ld	s0,64(sp)
ffffffffc0200e4c:	60a6                	ld	ra,72(sp)
ffffffffc0200e4e:	74e2                	ld	s1,56(sp)
ffffffffc0200e50:	7942                	ld	s2,48(sp)
ffffffffc0200e52:	79a2                	ld	s3,40(sp)
ffffffffc0200e54:	7a02                	ld	s4,32(sp)
ffffffffc0200e56:	6ae2                	ld	s5,24(sp)
ffffffffc0200e58:	6b42                	ld	s6,16(sp)
ffffffffc0200e5a:	6ba2                	ld	s7,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200e5c:	40c58633          	sub	a2,a1,a2
ffffffffc0200e60:	00005797          	auipc	a5,0x5
ffffffffc0200e64:	62c7b023          	sd	a2,1568(a5) # ffffffffc0206480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200e68:	00002517          	auipc	a0,0x2
ffffffffc0200e6c:	a6050513          	addi	a0,a0,-1440 # ffffffffc02028c8 <commands+0x7e0>
}
ffffffffc0200e70:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200e72:	a66ff06f          	j	ffffffffc02000d8 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200e76:	c8000837          	lui	a6,0xc8000
ffffffffc0200e7a:	b711                	j	ffffffffc0200d7e <pmm_init+0x88>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200e7c:	000b3703          	ld	a4,0(s6)
ffffffffc0200e80:	00ca5793          	srli	a5,s4,0xc
ffffffffc0200e84:	02e7f463          	bgeu	a5,a4,ffffffffc0200eac <pmm_init+0x1b6>
    pmm_manager->init_memmap(base, n);
ffffffffc0200e88:	6094                	ld	a3,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200e8a:	fff80737          	lui	a4,0xfff80
ffffffffc0200e8e:	973e                	add	a4,a4,a5
ffffffffc0200e90:	000bb503          	ld	a0,0(s7)
ffffffffc0200e94:	00271793          	slli	a5,a4,0x2
ffffffffc0200e98:	97ba                	add	a5,a5,a4
ffffffffc0200e9a:	6a98                	ld	a4,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200e9c:	414989b3          	sub	s3,s3,s4
ffffffffc0200ea0:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200ea2:	00c9d593          	srli	a1,s3,0xc
ffffffffc0200ea6:	953e                	add	a0,a0,a5
ffffffffc0200ea8:	9702                	jalr	a4
}
ffffffffc0200eaa:	bf8d                	j	ffffffffc0200e1c <pmm_init+0x126>
        panic("pa2page called with invalid pa");
ffffffffc0200eac:	00002617          	auipc	a2,0x2
ffffffffc0200eb0:	9cc60613          	addi	a2,a2,-1588 # ffffffffc0202878 <commands+0x790>
ffffffffc0200eb4:	08900593          	li	a1,137
ffffffffc0200eb8:	00002517          	auipc	a0,0x2
ffffffffc0200ebc:	9e050513          	addi	a0,a0,-1568 # ffffffffc0202898 <commands+0x7b0>
ffffffffc0200ec0:	aa0ff0ef          	jal	ra,ffffffffc0200160 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200ec4:	00002617          	auipc	a2,0x2
ffffffffc0200ec8:	98c60613          	addi	a2,a2,-1652 # ffffffffc0202850 <commands+0x768>
ffffffffc0200ecc:	06c00593          	li	a1,108
ffffffffc0200ed0:	00002517          	auipc	a0,0x2
ffffffffc0200ed4:	92850513          	addi	a0,a0,-1752 # ffffffffc02027f8 <commands+0x710>
ffffffffc0200ed8:	a88ff0ef          	jal	ra,ffffffffc0200160 <__panic>
        panic("DTB memory info not available");
ffffffffc0200edc:	00002617          	auipc	a2,0x2
ffffffffc0200ee0:	8fc60613          	addi	a2,a2,-1796 # ffffffffc02027d8 <commands+0x6f0>
ffffffffc0200ee4:	05000593          	li	a1,80
ffffffffc0200ee8:	00002517          	auipc	a0,0x2
ffffffffc0200eec:	91050513          	addi	a0,a0,-1776 # ffffffffc02027f8 <commands+0x710>
ffffffffc0200ef0:	a70ff0ef          	jal	ra,ffffffffc0200160 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200ef4:	86ae                	mv	a3,a1
ffffffffc0200ef6:	00002617          	auipc	a2,0x2
ffffffffc0200efa:	95a60613          	addi	a2,a2,-1702 # ffffffffc0202850 <commands+0x768>
ffffffffc0200efe:	08a00593          	li	a1,138
ffffffffc0200f02:	00002517          	auipc	a0,0x2
ffffffffc0200f06:	8f650513          	addi	a0,a0,-1802 # ffffffffc02027f8 <commands+0x710>
ffffffffc0200f0a:	a56ff0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0200f0e <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200f0e:	00005797          	auipc	a5,0x5
ffffffffc0200f12:	11a78793          	addi	a5,a5,282 # ffffffffc0206028 <free_area>
ffffffffc0200f16:	e79c                	sd	a5,8(a5)
ffffffffc0200f18:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200f1a:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200f1e:	8082                	ret

ffffffffc0200f20 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200f20:	00005517          	auipc	a0,0x5
ffffffffc0200f24:	11856503          	lwu	a0,280(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200f28:	8082                	ret

ffffffffc0200f2a <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200f2a:	cd49                	beqz	a0,ffffffffc0200fc4 <best_fit_alloc_pages+0x9a>
    if (n > nr_free) {
ffffffffc0200f2c:	00005617          	auipc	a2,0x5
ffffffffc0200f30:	0fc60613          	addi	a2,a2,252 # ffffffffc0206028 <free_area>
ffffffffc0200f34:	01062803          	lw	a6,16(a2)
ffffffffc0200f38:	86aa                	mv	a3,a0
ffffffffc0200f3a:	02081793          	slli	a5,a6,0x20
ffffffffc0200f3e:	9381                	srli	a5,a5,0x20
ffffffffc0200f40:	08a7e063          	bltu	a5,a0,ffffffffc0200fc0 <best_fit_alloc_pages+0x96>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200f44:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200f46:	0018059b          	addiw	a1,a6,1
ffffffffc0200f4a:	1582                	slli	a1,a1,0x20
ffffffffc0200f4c:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200f4e:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f50:	06c78763          	beq	a5,a2,ffffffffc0200fbe <best_fit_alloc_pages+0x94>
        if (p->property >= n) {
ffffffffc0200f54:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200f58:	00d76763          	bltu	a4,a3,ffffffffc0200f66 <best_fit_alloc_pages+0x3c>
            if (p->property < min_size) {
ffffffffc0200f5c:	00b77563          	bgeu	a4,a1,ffffffffc0200f66 <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200f60:	fe878513          	addi	a0,a5,-24
ffffffffc0200f64:	85ba                	mv	a1,a4
ffffffffc0200f66:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f68:	fec796e3          	bne	a5,a2,ffffffffc0200f54 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200f6c:	c929                	beqz	a0,ffffffffc0200fbe <best_fit_alloc_pages+0x94>
        if (page->property > n) {
ffffffffc0200f6e:	01052883          	lw	a7,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200f72:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200f74:	710c                	ld	a1,32(a0)
ffffffffc0200f76:	02089793          	slli	a5,a7,0x20
ffffffffc0200f7a:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200f7c:	e70c                	sd	a1,8(a4)
    next->prev = prev;
ffffffffc0200f7e:	e198                	sd	a4,0(a1)
            p->property = page->property - n;
ffffffffc0200f80:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc0200f84:	02f6f563          	bgeu	a3,a5,ffffffffc0200fae <best_fit_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc0200f88:	00269793          	slli	a5,a3,0x2
ffffffffc0200f8c:	97b6                	add	a5,a5,a3
ffffffffc0200f8e:	078e                	slli	a5,a5,0x3
ffffffffc0200f90:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc0200f92:	6794                	ld	a3,8(a5)
            p->property = page->property - n;
ffffffffc0200f94:	406888bb          	subw	a7,a7,t1
ffffffffc0200f98:	0117a823          	sw	a7,16(a5)
            SetPageProperty(p);
ffffffffc0200f9c:	0026e693          	ori	a3,a3,2
ffffffffc0200fa0:	e794                	sd	a3,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc0200fa2:	01878693          	addi	a3,a5,24
    prev->next = next->prev = elm;
ffffffffc0200fa6:	e194                	sd	a3,0(a1)
ffffffffc0200fa8:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200faa:	f38c                	sd	a1,32(a5)
    elm->prev = prev;
ffffffffc0200fac:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc0200fae:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc0200fb0:	4068083b          	subw	a6,a6,t1
ffffffffc0200fb4:	01062823          	sw	a6,16(a2)
        ClearPageProperty(page);
ffffffffc0200fb8:	9bf5                	andi	a5,a5,-3
ffffffffc0200fba:	e51c                	sd	a5,8(a0)
ffffffffc0200fbc:	8082                	ret
}
ffffffffc0200fbe:	8082                	ret
        return NULL;
ffffffffc0200fc0:	4501                	li	a0,0
ffffffffc0200fc2:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200fc4:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200fc6:	00002697          	auipc	a3,0x2
ffffffffc0200fca:	94268693          	addi	a3,a3,-1726 # ffffffffc0202908 <commands+0x820>
ffffffffc0200fce:	00002617          	auipc	a2,0x2
ffffffffc0200fd2:	94260613          	addi	a2,a2,-1726 # ffffffffc0202910 <commands+0x828>
ffffffffc0200fd6:	06b00593          	li	a1,107
ffffffffc0200fda:	00002517          	auipc	a0,0x2
ffffffffc0200fde:	94e50513          	addi	a0,a0,-1714 # ffffffffc0202928 <commands+0x840>
best_fit_alloc_pages(size_t n) {
ffffffffc0200fe2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200fe4:	97cff0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0200fe8 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200fe8:	715d                	addi	sp,sp,-80
ffffffffc0200fea:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200fec:	00005417          	auipc	s0,0x5
ffffffffc0200ff0:	03c40413          	addi	s0,s0,60 # ffffffffc0206028 <free_area>
ffffffffc0200ff4:	641c                	ld	a5,8(s0)
ffffffffc0200ff6:	e486                	sd	ra,72(sp)
ffffffffc0200ff8:	fc26                	sd	s1,56(sp)
ffffffffc0200ffa:	f84a                	sd	s2,48(sp)
ffffffffc0200ffc:	f44e                	sd	s3,40(sp)
ffffffffc0200ffe:	f052                	sd	s4,32(sp)
ffffffffc0201000:	ec56                	sd	s5,24(sp)
ffffffffc0201002:	e85a                	sd	s6,16(sp)
ffffffffc0201004:	e45e                	sd	s7,8(sp)
ffffffffc0201006:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201008:	26878963          	beq	a5,s0,ffffffffc020127a <best_fit_check+0x292>
    int count = 0, total = 0;
ffffffffc020100c:	4481                	li	s1,0
ffffffffc020100e:	4901                	li	s2,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201010:	ff07b703          	ld	a4,-16(a5)
ffffffffc0201014:	8b09                	andi	a4,a4,2
ffffffffc0201016:	26070663          	beqz	a4,ffffffffc0201282 <best_fit_check+0x29a>
        count ++, total += p->property;
ffffffffc020101a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020101e:	679c                	ld	a5,8(a5)
ffffffffc0201020:	2905                	addiw	s2,s2,1
ffffffffc0201022:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201024:	fe8796e3          	bne	a5,s0,ffffffffc0201010 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0201028:	89a6                	mv	s3,s1
ffffffffc020102a:	cc1ff0ef          	jal	ra,ffffffffc0200cea <nr_free_pages>
ffffffffc020102e:	33351a63          	bne	a0,s3,ffffffffc0201362 <best_fit_check+0x37a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201032:	4505                	li	a0,1
ffffffffc0201034:	c9fff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0201038:	8a2a                	mv	s4,a0
ffffffffc020103a:	36050463          	beqz	a0,ffffffffc02013a2 <best_fit_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020103e:	4505                	li	a0,1
ffffffffc0201040:	c93ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0201044:	89aa                	mv	s3,a0
ffffffffc0201046:	32050e63          	beqz	a0,ffffffffc0201382 <best_fit_check+0x39a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020104a:	4505                	li	a0,1
ffffffffc020104c:	c87ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0201050:	8aaa                	mv	s5,a0
ffffffffc0201052:	2c050863          	beqz	a0,ffffffffc0201322 <best_fit_check+0x33a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201056:	253a0663          	beq	s4,s3,ffffffffc02012a2 <best_fit_check+0x2ba>
ffffffffc020105a:	24aa0463          	beq	s4,a0,ffffffffc02012a2 <best_fit_check+0x2ba>
ffffffffc020105e:	24a98263          	beq	s3,a0,ffffffffc02012a2 <best_fit_check+0x2ba>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201062:	000a2783          	lw	a5,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0201066:	24079e63          	bnez	a5,ffffffffc02012c2 <best_fit_check+0x2da>
ffffffffc020106a:	0009a783          	lw	a5,0(s3)
ffffffffc020106e:	24079a63          	bnez	a5,ffffffffc02012c2 <best_fit_check+0x2da>
ffffffffc0201072:	411c                	lw	a5,0(a0)
ffffffffc0201074:	24079763          	bnez	a5,ffffffffc02012c2 <best_fit_check+0x2da>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201078:	00005797          	auipc	a5,0x5
ffffffffc020107c:	3f87b783          	ld	a5,1016(a5) # ffffffffc0206470 <pages>
ffffffffc0201080:	40fa0733          	sub	a4,s4,a5
ffffffffc0201084:	870d                	srai	a4,a4,0x3
ffffffffc0201086:	00002597          	auipc	a1,0x2
ffffffffc020108a:	e525b583          	ld	a1,-430(a1) # ffffffffc0202ed8 <nbase+0x8>
ffffffffc020108e:	02b70733          	mul	a4,a4,a1
ffffffffc0201092:	00002617          	auipc	a2,0x2
ffffffffc0201096:	e3e63603          	ld	a2,-450(a2) # ffffffffc0202ed0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020109a:	00005697          	auipc	a3,0x5
ffffffffc020109e:	3ce6b683          	ld	a3,974(a3) # ffffffffc0206468 <npage>
ffffffffc02010a2:	06b2                	slli	a3,a3,0xc
ffffffffc02010a4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010a6:	0732                	slli	a4,a4,0xc
ffffffffc02010a8:	22d77d63          	bgeu	a4,a3,ffffffffc02012e2 <best_fit_check+0x2fa>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02010ac:	40f98733          	sub	a4,s3,a5
ffffffffc02010b0:	870d                	srai	a4,a4,0x3
ffffffffc02010b2:	02b70733          	mul	a4,a4,a1
ffffffffc02010b6:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010b8:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010ba:	3ed77463          	bgeu	a4,a3,ffffffffc02014a2 <best_fit_check+0x4ba>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02010be:	40f507b3          	sub	a5,a0,a5
ffffffffc02010c2:	878d                	srai	a5,a5,0x3
ffffffffc02010c4:	02b787b3          	mul	a5,a5,a1
ffffffffc02010c8:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010ca:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010cc:	3ad7fb63          	bgeu	a5,a3,ffffffffc0201482 <best_fit_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc02010d0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02010d2:	00043c03          	ld	s8,0(s0)
ffffffffc02010d6:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02010da:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02010de:	e400                	sd	s0,8(s0)
ffffffffc02010e0:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02010e2:	00005797          	auipc	a5,0x5
ffffffffc02010e6:	f407ab23          	sw	zero,-170(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02010ea:	be9ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc02010ee:	36051a63          	bnez	a0,ffffffffc0201462 <best_fit_check+0x47a>
    free_page(p0);
ffffffffc02010f2:	4585                	li	a1,1
ffffffffc02010f4:	8552                	mv	a0,s4
ffffffffc02010f6:	be9ff0ef          	jal	ra,ffffffffc0200cde <free_pages>
    free_page(p1);
ffffffffc02010fa:	4585                	li	a1,1
ffffffffc02010fc:	854e                	mv	a0,s3
ffffffffc02010fe:	be1ff0ef          	jal	ra,ffffffffc0200cde <free_pages>
    free_page(p2);
ffffffffc0201102:	4585                	li	a1,1
ffffffffc0201104:	8556                	mv	a0,s5
ffffffffc0201106:	bd9ff0ef          	jal	ra,ffffffffc0200cde <free_pages>
    assert(nr_free == 3);
ffffffffc020110a:	4818                	lw	a4,16(s0)
ffffffffc020110c:	478d                	li	a5,3
ffffffffc020110e:	32f71a63          	bne	a4,a5,ffffffffc0201442 <best_fit_check+0x45a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201112:	4505                	li	a0,1
ffffffffc0201114:	bbfff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0201118:	89aa                	mv	s3,a0
ffffffffc020111a:	30050463          	beqz	a0,ffffffffc0201422 <best_fit_check+0x43a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020111e:	4505                	li	a0,1
ffffffffc0201120:	bb3ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0201124:	8aaa                	mv	s5,a0
ffffffffc0201126:	2c050e63          	beqz	a0,ffffffffc0201402 <best_fit_check+0x41a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020112a:	4505                	li	a0,1
ffffffffc020112c:	ba7ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0201130:	8a2a                	mv	s4,a0
ffffffffc0201132:	2a050863          	beqz	a0,ffffffffc02013e2 <best_fit_check+0x3fa>
    assert(alloc_page() == NULL);
ffffffffc0201136:	4505                	li	a0,1
ffffffffc0201138:	b9bff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc020113c:	28051363          	bnez	a0,ffffffffc02013c2 <best_fit_check+0x3da>
    free_page(p0);
ffffffffc0201140:	4585                	li	a1,1
ffffffffc0201142:	854e                	mv	a0,s3
ffffffffc0201144:	b9bff0ef          	jal	ra,ffffffffc0200cde <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201148:	641c                	ld	a5,8(s0)
ffffffffc020114a:	1a878c63          	beq	a5,s0,ffffffffc0201302 <best_fit_check+0x31a>
    assert((p = alloc_page()) == p0);
ffffffffc020114e:	4505                	li	a0,1
ffffffffc0201150:	b83ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0201154:	52a99763          	bne	s3,a0,ffffffffc0201682 <best_fit_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc0201158:	4505                	li	a0,1
ffffffffc020115a:	b79ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc020115e:	50051263          	bnez	a0,ffffffffc0201662 <best_fit_check+0x67a>
    assert(nr_free == 0);
ffffffffc0201162:	481c                	lw	a5,16(s0)
ffffffffc0201164:	4c079f63          	bnez	a5,ffffffffc0201642 <best_fit_check+0x65a>
    free_page(p);
ffffffffc0201168:	854e                	mv	a0,s3
ffffffffc020116a:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020116c:	01843023          	sd	s8,0(s0)
ffffffffc0201170:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201174:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201178:	b67ff0ef          	jal	ra,ffffffffc0200cde <free_pages>
    free_page(p1);
ffffffffc020117c:	4585                	li	a1,1
ffffffffc020117e:	8556                	mv	a0,s5
ffffffffc0201180:	b5fff0ef          	jal	ra,ffffffffc0200cde <free_pages>
    free_page(p2);
ffffffffc0201184:	4585                	li	a1,1
ffffffffc0201186:	8552                	mv	a0,s4
ffffffffc0201188:	b57ff0ef          	jal	ra,ffffffffc0200cde <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020118c:	4515                	li	a0,5
ffffffffc020118e:	b45ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0201192:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201194:	48050763          	beqz	a0,ffffffffc0201622 <best_fit_check+0x63a>
    assert(!PageProperty(p0));
ffffffffc0201198:	651c                	ld	a5,8(a0)
ffffffffc020119a:	8b89                	andi	a5,a5,2
ffffffffc020119c:	46079363          	bnez	a5,ffffffffc0201602 <best_fit_check+0x61a>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02011a0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02011a2:	00043b03          	ld	s6,0(s0)
ffffffffc02011a6:	00843a83          	ld	s5,8(s0)
ffffffffc02011aa:	e000                	sd	s0,0(s0)
ffffffffc02011ac:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02011ae:	b25ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc02011b2:	42051863          	bnez	a0,ffffffffc02015e2 <best_fit_check+0x5fa>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc02011b6:	4589                	li	a1,2
ffffffffc02011b8:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc02011bc:	01042b83          	lw	s7,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc02011c0:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc02011c4:	00005797          	auipc	a5,0x5
ffffffffc02011c8:	e607aa23          	sw	zero,-396(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc02011cc:	b13ff0ef          	jal	ra,ffffffffc0200cde <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc02011d0:	8562                	mv	a0,s8
ffffffffc02011d2:	4585                	li	a1,1
ffffffffc02011d4:	b0bff0ef          	jal	ra,ffffffffc0200cde <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02011d8:	4511                	li	a0,4
ffffffffc02011da:	af9ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc02011de:	3e051263          	bnez	a0,ffffffffc02015c2 <best_fit_check+0x5da>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02011e2:	0309b783          	ld	a5,48(s3)
ffffffffc02011e6:	8b89                	andi	a5,a5,2
ffffffffc02011e8:	3a078d63          	beqz	a5,ffffffffc02015a2 <best_fit_check+0x5ba>
ffffffffc02011ec:	0389a703          	lw	a4,56(s3)
ffffffffc02011f0:	4789                	li	a5,2
ffffffffc02011f2:	3af71863          	bne	a4,a5,ffffffffc02015a2 <best_fit_check+0x5ba>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02011f6:	4505                	li	a0,1
ffffffffc02011f8:	adbff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc02011fc:	8a2a                	mv	s4,a0
ffffffffc02011fe:	38050263          	beqz	a0,ffffffffc0201582 <best_fit_check+0x59a>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0201202:	4509                	li	a0,2
ffffffffc0201204:	acfff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0201208:	34050d63          	beqz	a0,ffffffffc0201562 <best_fit_check+0x57a>
    assert(p0 + 4 == p1);
ffffffffc020120c:	334c1b63          	bne	s8,s4,ffffffffc0201542 <best_fit_check+0x55a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0201210:	854e                	mv	a0,s3
ffffffffc0201212:	4595                	li	a1,5
ffffffffc0201214:	acbff0ef          	jal	ra,ffffffffc0200cde <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201218:	4515                	li	a0,5
ffffffffc020121a:	ab9ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc020121e:	89aa                	mv	s3,a0
ffffffffc0201220:	30050163          	beqz	a0,ffffffffc0201522 <best_fit_check+0x53a>
    assert(alloc_page() == NULL);
ffffffffc0201224:	4505                	li	a0,1
ffffffffc0201226:	aadff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc020122a:	2c051c63          	bnez	a0,ffffffffc0201502 <best_fit_check+0x51a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc020122e:	481c                	lw	a5,16(s0)
ffffffffc0201230:	2a079963          	bnez	a5,ffffffffc02014e2 <best_fit_check+0x4fa>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201234:	4595                	li	a1,5
ffffffffc0201236:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201238:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc020123c:	01643023          	sd	s6,0(s0)
ffffffffc0201240:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201244:	a9bff0ef          	jal	ra,ffffffffc0200cde <free_pages>
    return listelm->next;
ffffffffc0201248:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020124a:	00878963          	beq	a5,s0,ffffffffc020125c <best_fit_check+0x274>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020124e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201252:	679c                	ld	a5,8(a5)
ffffffffc0201254:	397d                	addiw	s2,s2,-1
ffffffffc0201256:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201258:	fe879be3          	bne	a5,s0,ffffffffc020124e <best_fit_check+0x266>
    }
    assert(count == 0);
ffffffffc020125c:	26091363          	bnez	s2,ffffffffc02014c2 <best_fit_check+0x4da>
    assert(total == 0);
ffffffffc0201260:	e0ed                	bnez	s1,ffffffffc0201342 <best_fit_check+0x35a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0201262:	60a6                	ld	ra,72(sp)
ffffffffc0201264:	6406                	ld	s0,64(sp)
ffffffffc0201266:	74e2                	ld	s1,56(sp)
ffffffffc0201268:	7942                	ld	s2,48(sp)
ffffffffc020126a:	79a2                	ld	s3,40(sp)
ffffffffc020126c:	7a02                	ld	s4,32(sp)
ffffffffc020126e:	6ae2                	ld	s5,24(sp)
ffffffffc0201270:	6b42                	ld	s6,16(sp)
ffffffffc0201272:	6ba2                	ld	s7,8(sp)
ffffffffc0201274:	6c02                	ld	s8,0(sp)
ffffffffc0201276:	6161                	addi	sp,sp,80
ffffffffc0201278:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020127a:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020127c:	4481                	li	s1,0
ffffffffc020127e:	4901                	li	s2,0
ffffffffc0201280:	b36d                	j	ffffffffc020102a <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0201282:	00001697          	auipc	a3,0x1
ffffffffc0201286:	6be68693          	addi	a3,a3,1726 # ffffffffc0202940 <commands+0x858>
ffffffffc020128a:	00001617          	auipc	a2,0x1
ffffffffc020128e:	68660613          	addi	a2,a2,1670 # ffffffffc0202910 <commands+0x828>
ffffffffc0201292:	10f00593          	li	a1,271
ffffffffc0201296:	00001517          	auipc	a0,0x1
ffffffffc020129a:	69250513          	addi	a0,a0,1682 # ffffffffc0202928 <commands+0x840>
ffffffffc020129e:	ec3fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02012a2:	00001697          	auipc	a3,0x1
ffffffffc02012a6:	72e68693          	addi	a3,a3,1838 # ffffffffc02029d0 <commands+0x8e8>
ffffffffc02012aa:	00001617          	auipc	a2,0x1
ffffffffc02012ae:	66660613          	addi	a2,a2,1638 # ffffffffc0202910 <commands+0x828>
ffffffffc02012b2:	0db00593          	li	a1,219
ffffffffc02012b6:	00001517          	auipc	a0,0x1
ffffffffc02012ba:	67250513          	addi	a0,a0,1650 # ffffffffc0202928 <commands+0x840>
ffffffffc02012be:	ea3fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02012c2:	00001697          	auipc	a3,0x1
ffffffffc02012c6:	73668693          	addi	a3,a3,1846 # ffffffffc02029f8 <commands+0x910>
ffffffffc02012ca:	00001617          	auipc	a2,0x1
ffffffffc02012ce:	64660613          	addi	a2,a2,1606 # ffffffffc0202910 <commands+0x828>
ffffffffc02012d2:	0dc00593          	li	a1,220
ffffffffc02012d6:	00001517          	auipc	a0,0x1
ffffffffc02012da:	65250513          	addi	a0,a0,1618 # ffffffffc0202928 <commands+0x840>
ffffffffc02012de:	e83fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02012e2:	00001697          	auipc	a3,0x1
ffffffffc02012e6:	75668693          	addi	a3,a3,1878 # ffffffffc0202a38 <commands+0x950>
ffffffffc02012ea:	00001617          	auipc	a2,0x1
ffffffffc02012ee:	62660613          	addi	a2,a2,1574 # ffffffffc0202910 <commands+0x828>
ffffffffc02012f2:	0de00593          	li	a1,222
ffffffffc02012f6:	00001517          	auipc	a0,0x1
ffffffffc02012fa:	63250513          	addi	a0,a0,1586 # ffffffffc0202928 <commands+0x840>
ffffffffc02012fe:	e63fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201302:	00001697          	auipc	a3,0x1
ffffffffc0201306:	7be68693          	addi	a3,a3,1982 # ffffffffc0202ac0 <commands+0x9d8>
ffffffffc020130a:	00001617          	auipc	a2,0x1
ffffffffc020130e:	60660613          	addi	a2,a2,1542 # ffffffffc0202910 <commands+0x828>
ffffffffc0201312:	0f700593          	li	a1,247
ffffffffc0201316:	00001517          	auipc	a0,0x1
ffffffffc020131a:	61250513          	addi	a0,a0,1554 # ffffffffc0202928 <commands+0x840>
ffffffffc020131e:	e43fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201322:	00001697          	auipc	a3,0x1
ffffffffc0201326:	68e68693          	addi	a3,a3,1678 # ffffffffc02029b0 <commands+0x8c8>
ffffffffc020132a:	00001617          	auipc	a2,0x1
ffffffffc020132e:	5e660613          	addi	a2,a2,1510 # ffffffffc0202910 <commands+0x828>
ffffffffc0201332:	0d900593          	li	a1,217
ffffffffc0201336:	00001517          	auipc	a0,0x1
ffffffffc020133a:	5f250513          	addi	a0,a0,1522 # ffffffffc0202928 <commands+0x840>
ffffffffc020133e:	e23fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(total == 0);
ffffffffc0201342:	00002697          	auipc	a3,0x2
ffffffffc0201346:	8ae68693          	addi	a3,a3,-1874 # ffffffffc0202bf0 <commands+0xb08>
ffffffffc020134a:	00001617          	auipc	a2,0x1
ffffffffc020134e:	5c660613          	addi	a2,a2,1478 # ffffffffc0202910 <commands+0x828>
ffffffffc0201352:	15100593          	li	a1,337
ffffffffc0201356:	00001517          	auipc	a0,0x1
ffffffffc020135a:	5d250513          	addi	a0,a0,1490 # ffffffffc0202928 <commands+0x840>
ffffffffc020135e:	e03fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201362:	00001697          	auipc	a3,0x1
ffffffffc0201366:	5ee68693          	addi	a3,a3,1518 # ffffffffc0202950 <commands+0x868>
ffffffffc020136a:	00001617          	auipc	a2,0x1
ffffffffc020136e:	5a660613          	addi	a2,a2,1446 # ffffffffc0202910 <commands+0x828>
ffffffffc0201372:	11200593          	li	a1,274
ffffffffc0201376:	00001517          	auipc	a0,0x1
ffffffffc020137a:	5b250513          	addi	a0,a0,1458 # ffffffffc0202928 <commands+0x840>
ffffffffc020137e:	de3fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201382:	00001697          	auipc	a3,0x1
ffffffffc0201386:	60e68693          	addi	a3,a3,1550 # ffffffffc0202990 <commands+0x8a8>
ffffffffc020138a:	00001617          	auipc	a2,0x1
ffffffffc020138e:	58660613          	addi	a2,a2,1414 # ffffffffc0202910 <commands+0x828>
ffffffffc0201392:	0d800593          	li	a1,216
ffffffffc0201396:	00001517          	auipc	a0,0x1
ffffffffc020139a:	59250513          	addi	a0,a0,1426 # ffffffffc0202928 <commands+0x840>
ffffffffc020139e:	dc3fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02013a2:	00001697          	auipc	a3,0x1
ffffffffc02013a6:	5ce68693          	addi	a3,a3,1486 # ffffffffc0202970 <commands+0x888>
ffffffffc02013aa:	00001617          	auipc	a2,0x1
ffffffffc02013ae:	56660613          	addi	a2,a2,1382 # ffffffffc0202910 <commands+0x828>
ffffffffc02013b2:	0d700593          	li	a1,215
ffffffffc02013b6:	00001517          	auipc	a0,0x1
ffffffffc02013ba:	57250513          	addi	a0,a0,1394 # ffffffffc0202928 <commands+0x840>
ffffffffc02013be:	da3fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013c2:	00001697          	auipc	a3,0x1
ffffffffc02013c6:	6d668693          	addi	a3,a3,1750 # ffffffffc0202a98 <commands+0x9b0>
ffffffffc02013ca:	00001617          	auipc	a2,0x1
ffffffffc02013ce:	54660613          	addi	a2,a2,1350 # ffffffffc0202910 <commands+0x828>
ffffffffc02013d2:	0f400593          	li	a1,244
ffffffffc02013d6:	00001517          	auipc	a0,0x1
ffffffffc02013da:	55250513          	addi	a0,a0,1362 # ffffffffc0202928 <commands+0x840>
ffffffffc02013de:	d83fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013e2:	00001697          	auipc	a3,0x1
ffffffffc02013e6:	5ce68693          	addi	a3,a3,1486 # ffffffffc02029b0 <commands+0x8c8>
ffffffffc02013ea:	00001617          	auipc	a2,0x1
ffffffffc02013ee:	52660613          	addi	a2,a2,1318 # ffffffffc0202910 <commands+0x828>
ffffffffc02013f2:	0f200593          	li	a1,242
ffffffffc02013f6:	00001517          	auipc	a0,0x1
ffffffffc02013fa:	53250513          	addi	a0,a0,1330 # ffffffffc0202928 <commands+0x840>
ffffffffc02013fe:	d63fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201402:	00001697          	auipc	a3,0x1
ffffffffc0201406:	58e68693          	addi	a3,a3,1422 # ffffffffc0202990 <commands+0x8a8>
ffffffffc020140a:	00001617          	auipc	a2,0x1
ffffffffc020140e:	50660613          	addi	a2,a2,1286 # ffffffffc0202910 <commands+0x828>
ffffffffc0201412:	0f100593          	li	a1,241
ffffffffc0201416:	00001517          	auipc	a0,0x1
ffffffffc020141a:	51250513          	addi	a0,a0,1298 # ffffffffc0202928 <commands+0x840>
ffffffffc020141e:	d43fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201422:	00001697          	auipc	a3,0x1
ffffffffc0201426:	54e68693          	addi	a3,a3,1358 # ffffffffc0202970 <commands+0x888>
ffffffffc020142a:	00001617          	auipc	a2,0x1
ffffffffc020142e:	4e660613          	addi	a2,a2,1254 # ffffffffc0202910 <commands+0x828>
ffffffffc0201432:	0f000593          	li	a1,240
ffffffffc0201436:	00001517          	auipc	a0,0x1
ffffffffc020143a:	4f250513          	addi	a0,a0,1266 # ffffffffc0202928 <commands+0x840>
ffffffffc020143e:	d23fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(nr_free == 3);
ffffffffc0201442:	00001697          	auipc	a3,0x1
ffffffffc0201446:	66e68693          	addi	a3,a3,1646 # ffffffffc0202ab0 <commands+0x9c8>
ffffffffc020144a:	00001617          	auipc	a2,0x1
ffffffffc020144e:	4c660613          	addi	a2,a2,1222 # ffffffffc0202910 <commands+0x828>
ffffffffc0201452:	0ee00593          	li	a1,238
ffffffffc0201456:	00001517          	auipc	a0,0x1
ffffffffc020145a:	4d250513          	addi	a0,a0,1234 # ffffffffc0202928 <commands+0x840>
ffffffffc020145e:	d03fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201462:	00001697          	auipc	a3,0x1
ffffffffc0201466:	63668693          	addi	a3,a3,1590 # ffffffffc0202a98 <commands+0x9b0>
ffffffffc020146a:	00001617          	auipc	a2,0x1
ffffffffc020146e:	4a660613          	addi	a2,a2,1190 # ffffffffc0202910 <commands+0x828>
ffffffffc0201472:	0e900593          	li	a1,233
ffffffffc0201476:	00001517          	auipc	a0,0x1
ffffffffc020147a:	4b250513          	addi	a0,a0,1202 # ffffffffc0202928 <commands+0x840>
ffffffffc020147e:	ce3fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201482:	00001697          	auipc	a3,0x1
ffffffffc0201486:	5f668693          	addi	a3,a3,1526 # ffffffffc0202a78 <commands+0x990>
ffffffffc020148a:	00001617          	auipc	a2,0x1
ffffffffc020148e:	48660613          	addi	a2,a2,1158 # ffffffffc0202910 <commands+0x828>
ffffffffc0201492:	0e000593          	li	a1,224
ffffffffc0201496:	00001517          	auipc	a0,0x1
ffffffffc020149a:	49250513          	addi	a0,a0,1170 # ffffffffc0202928 <commands+0x840>
ffffffffc020149e:	cc3fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02014a2:	00001697          	auipc	a3,0x1
ffffffffc02014a6:	5b668693          	addi	a3,a3,1462 # ffffffffc0202a58 <commands+0x970>
ffffffffc02014aa:	00001617          	auipc	a2,0x1
ffffffffc02014ae:	46660613          	addi	a2,a2,1126 # ffffffffc0202910 <commands+0x828>
ffffffffc02014b2:	0df00593          	li	a1,223
ffffffffc02014b6:	00001517          	auipc	a0,0x1
ffffffffc02014ba:	47250513          	addi	a0,a0,1138 # ffffffffc0202928 <commands+0x840>
ffffffffc02014be:	ca3fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(count == 0);
ffffffffc02014c2:	00001697          	auipc	a3,0x1
ffffffffc02014c6:	71e68693          	addi	a3,a3,1822 # ffffffffc0202be0 <commands+0xaf8>
ffffffffc02014ca:	00001617          	auipc	a2,0x1
ffffffffc02014ce:	44660613          	addi	a2,a2,1094 # ffffffffc0202910 <commands+0x828>
ffffffffc02014d2:	15000593          	li	a1,336
ffffffffc02014d6:	00001517          	auipc	a0,0x1
ffffffffc02014da:	45250513          	addi	a0,a0,1106 # ffffffffc0202928 <commands+0x840>
ffffffffc02014de:	c83fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(nr_free == 0);
ffffffffc02014e2:	00001697          	auipc	a3,0x1
ffffffffc02014e6:	61668693          	addi	a3,a3,1558 # ffffffffc0202af8 <commands+0xa10>
ffffffffc02014ea:	00001617          	auipc	a2,0x1
ffffffffc02014ee:	42660613          	addi	a2,a2,1062 # ffffffffc0202910 <commands+0x828>
ffffffffc02014f2:	14500593          	li	a1,325
ffffffffc02014f6:	00001517          	auipc	a0,0x1
ffffffffc02014fa:	43250513          	addi	a0,a0,1074 # ffffffffc0202928 <commands+0x840>
ffffffffc02014fe:	c63fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201502:	00001697          	auipc	a3,0x1
ffffffffc0201506:	59668693          	addi	a3,a3,1430 # ffffffffc0202a98 <commands+0x9b0>
ffffffffc020150a:	00001617          	auipc	a2,0x1
ffffffffc020150e:	40660613          	addi	a2,a2,1030 # ffffffffc0202910 <commands+0x828>
ffffffffc0201512:	13f00593          	li	a1,319
ffffffffc0201516:	00001517          	auipc	a0,0x1
ffffffffc020151a:	41250513          	addi	a0,a0,1042 # ffffffffc0202928 <commands+0x840>
ffffffffc020151e:	c43fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201522:	00001697          	auipc	a3,0x1
ffffffffc0201526:	69e68693          	addi	a3,a3,1694 # ffffffffc0202bc0 <commands+0xad8>
ffffffffc020152a:	00001617          	auipc	a2,0x1
ffffffffc020152e:	3e660613          	addi	a2,a2,998 # ffffffffc0202910 <commands+0x828>
ffffffffc0201532:	13e00593          	li	a1,318
ffffffffc0201536:	00001517          	auipc	a0,0x1
ffffffffc020153a:	3f250513          	addi	a0,a0,1010 # ffffffffc0202928 <commands+0x840>
ffffffffc020153e:	c23fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0201542:	00001697          	auipc	a3,0x1
ffffffffc0201546:	66e68693          	addi	a3,a3,1646 # ffffffffc0202bb0 <commands+0xac8>
ffffffffc020154a:	00001617          	auipc	a2,0x1
ffffffffc020154e:	3c660613          	addi	a2,a2,966 # ffffffffc0202910 <commands+0x828>
ffffffffc0201552:	13600593          	li	a1,310
ffffffffc0201556:	00001517          	auipc	a0,0x1
ffffffffc020155a:	3d250513          	addi	a0,a0,978 # ffffffffc0202928 <commands+0x840>
ffffffffc020155e:	c03fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0201562:	00001697          	auipc	a3,0x1
ffffffffc0201566:	63668693          	addi	a3,a3,1590 # ffffffffc0202b98 <commands+0xab0>
ffffffffc020156a:	00001617          	auipc	a2,0x1
ffffffffc020156e:	3a660613          	addi	a2,a2,934 # ffffffffc0202910 <commands+0x828>
ffffffffc0201572:	13500593          	li	a1,309
ffffffffc0201576:	00001517          	auipc	a0,0x1
ffffffffc020157a:	3b250513          	addi	a0,a0,946 # ffffffffc0202928 <commands+0x840>
ffffffffc020157e:	be3fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0201582:	00001697          	auipc	a3,0x1
ffffffffc0201586:	5f668693          	addi	a3,a3,1526 # ffffffffc0202b78 <commands+0xa90>
ffffffffc020158a:	00001617          	auipc	a2,0x1
ffffffffc020158e:	38660613          	addi	a2,a2,902 # ffffffffc0202910 <commands+0x828>
ffffffffc0201592:	13400593          	li	a1,308
ffffffffc0201596:	00001517          	auipc	a0,0x1
ffffffffc020159a:	39250513          	addi	a0,a0,914 # ffffffffc0202928 <commands+0x840>
ffffffffc020159e:	bc3fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02015a2:	00001697          	auipc	a3,0x1
ffffffffc02015a6:	5a668693          	addi	a3,a3,1446 # ffffffffc0202b48 <commands+0xa60>
ffffffffc02015aa:	00001617          	auipc	a2,0x1
ffffffffc02015ae:	36660613          	addi	a2,a2,870 # ffffffffc0202910 <commands+0x828>
ffffffffc02015b2:	13200593          	li	a1,306
ffffffffc02015b6:	00001517          	auipc	a0,0x1
ffffffffc02015ba:	37250513          	addi	a0,a0,882 # ffffffffc0202928 <commands+0x840>
ffffffffc02015be:	ba3fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02015c2:	00001697          	auipc	a3,0x1
ffffffffc02015c6:	56e68693          	addi	a3,a3,1390 # ffffffffc0202b30 <commands+0xa48>
ffffffffc02015ca:	00001617          	auipc	a2,0x1
ffffffffc02015ce:	34660613          	addi	a2,a2,838 # ffffffffc0202910 <commands+0x828>
ffffffffc02015d2:	13100593          	li	a1,305
ffffffffc02015d6:	00001517          	auipc	a0,0x1
ffffffffc02015da:	35250513          	addi	a0,a0,850 # ffffffffc0202928 <commands+0x840>
ffffffffc02015de:	b83fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015e2:	00001697          	auipc	a3,0x1
ffffffffc02015e6:	4b668693          	addi	a3,a3,1206 # ffffffffc0202a98 <commands+0x9b0>
ffffffffc02015ea:	00001617          	auipc	a2,0x1
ffffffffc02015ee:	32660613          	addi	a2,a2,806 # ffffffffc0202910 <commands+0x828>
ffffffffc02015f2:	12500593          	li	a1,293
ffffffffc02015f6:	00001517          	auipc	a0,0x1
ffffffffc02015fa:	33250513          	addi	a0,a0,818 # ffffffffc0202928 <commands+0x840>
ffffffffc02015fe:	b63fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201602:	00001697          	auipc	a3,0x1
ffffffffc0201606:	51668693          	addi	a3,a3,1302 # ffffffffc0202b18 <commands+0xa30>
ffffffffc020160a:	00001617          	auipc	a2,0x1
ffffffffc020160e:	30660613          	addi	a2,a2,774 # ffffffffc0202910 <commands+0x828>
ffffffffc0201612:	11c00593          	li	a1,284
ffffffffc0201616:	00001517          	auipc	a0,0x1
ffffffffc020161a:	31250513          	addi	a0,a0,786 # ffffffffc0202928 <commands+0x840>
ffffffffc020161e:	b43fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(p0 != NULL);
ffffffffc0201622:	00001697          	auipc	a3,0x1
ffffffffc0201626:	4e668693          	addi	a3,a3,1254 # ffffffffc0202b08 <commands+0xa20>
ffffffffc020162a:	00001617          	auipc	a2,0x1
ffffffffc020162e:	2e660613          	addi	a2,a2,742 # ffffffffc0202910 <commands+0x828>
ffffffffc0201632:	11b00593          	li	a1,283
ffffffffc0201636:	00001517          	auipc	a0,0x1
ffffffffc020163a:	2f250513          	addi	a0,a0,754 # ffffffffc0202928 <commands+0x840>
ffffffffc020163e:	b23fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(nr_free == 0);
ffffffffc0201642:	00001697          	auipc	a3,0x1
ffffffffc0201646:	4b668693          	addi	a3,a3,1206 # ffffffffc0202af8 <commands+0xa10>
ffffffffc020164a:	00001617          	auipc	a2,0x1
ffffffffc020164e:	2c660613          	addi	a2,a2,710 # ffffffffc0202910 <commands+0x828>
ffffffffc0201652:	0fd00593          	li	a1,253
ffffffffc0201656:	00001517          	auipc	a0,0x1
ffffffffc020165a:	2d250513          	addi	a0,a0,722 # ffffffffc0202928 <commands+0x840>
ffffffffc020165e:	b03fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201662:	00001697          	auipc	a3,0x1
ffffffffc0201666:	43668693          	addi	a3,a3,1078 # ffffffffc0202a98 <commands+0x9b0>
ffffffffc020166a:	00001617          	auipc	a2,0x1
ffffffffc020166e:	2a660613          	addi	a2,a2,678 # ffffffffc0202910 <commands+0x828>
ffffffffc0201672:	0fb00593          	li	a1,251
ffffffffc0201676:	00001517          	auipc	a0,0x1
ffffffffc020167a:	2b250513          	addi	a0,a0,690 # ffffffffc0202928 <commands+0x840>
ffffffffc020167e:	ae3fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201682:	00001697          	auipc	a3,0x1
ffffffffc0201686:	45668693          	addi	a3,a3,1110 # ffffffffc0202ad8 <commands+0x9f0>
ffffffffc020168a:	00001617          	auipc	a2,0x1
ffffffffc020168e:	28660613          	addi	a2,a2,646 # ffffffffc0202910 <commands+0x828>
ffffffffc0201692:	0fa00593          	li	a1,250
ffffffffc0201696:	00001517          	auipc	a0,0x1
ffffffffc020169a:	29250513          	addi	a0,a0,658 # ffffffffc0202928 <commands+0x840>
ffffffffc020169e:	ac3fe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc02016a2 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc02016a2:	1141                	addi	sp,sp,-16
ffffffffc02016a4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016a6:	12058b63          	beqz	a1,ffffffffc02017dc <best_fit_free_pages+0x13a>
    for (; p != base + n; p ++) {
ffffffffc02016aa:	00259693          	slli	a3,a1,0x2
ffffffffc02016ae:	96ae                	add	a3,a3,a1
ffffffffc02016b0:	068e                	slli	a3,a3,0x3
ffffffffc02016b2:	96aa                	add	a3,a3,a0
ffffffffc02016b4:	87aa                	mv	a5,a0
ffffffffc02016b6:	00d50d63          	beq	a0,a3,ffffffffc02016d0 <best_fit_free_pages+0x2e>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02016ba:	6798                	ld	a4,8(a5)
ffffffffc02016bc:	8b0d                	andi	a4,a4,3
ffffffffc02016be:	ef7d                	bnez	a4,ffffffffc02017bc <best_fit_free_pages+0x11a>
        p->flags = 0;
ffffffffc02016c0:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02016c4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02016c8:	02878793          	addi	a5,a5,40
ffffffffc02016cc:	fed797e3          	bne	a5,a3,ffffffffc02016ba <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc02016d0:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc02016d4:	00005697          	auipc	a3,0x5
ffffffffc02016d8:	95468693          	addi	a3,a3,-1708 # ffffffffc0206028 <free_area>
ffffffffc02016dc:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc02016de:	2581                	sext.w	a1,a1
    return list->next == list;
ffffffffc02016e0:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc02016e2:	0028e613          	ori	a2,a7,2
    base->property = n;
ffffffffc02016e6:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02016e8:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc02016ea:	9f2d                	addw	a4,a4,a1
ffffffffc02016ec:	ca98                	sw	a4,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02016ee:	01850813          	addi	a6,a0,24
    if (list_empty(&free_list)) {
ffffffffc02016f2:	06d78d63          	beq	a5,a3,ffffffffc020176c <best_fit_free_pages+0xca>
            struct Page* page = le2page(le, page_link);
ffffffffc02016f6:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016fa:	04e56f63          	bltu	a0,a4,ffffffffc0201758 <best_fit_free_pages+0xb6>
    return listelm->next;
ffffffffc02016fe:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201700:	fed79be3          	bne	a5,a3,ffffffffc02016f6 <best_fit_free_pages+0x54>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201704:	6390                	ld	a2,0(a5)
    prev->next = next->prev = elm;
ffffffffc0201706:	0107b023          	sd	a6,0(a5)
ffffffffc020170a:	01063423          	sd	a6,8(a2)
    elm->next = next;
ffffffffc020170e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201710:	ed10                	sd	a2,24(a0)
    if (le != &free_list) {
ffffffffc0201712:	04f60063          	beq	a2,a5,ffffffffc0201752 <best_fit_free_pages+0xb0>
        if (p + p->property == base) {
ffffffffc0201716:	ff862e03          	lw	t3,-8(a2)
        p = le2page(le, page_link);
ffffffffc020171a:	fe860313          	addi	t1,a2,-24
        if (p + p->property == base) {
ffffffffc020171e:	020e1813          	slli	a6,t3,0x20
ffffffffc0201722:	02085813          	srli	a6,a6,0x20
ffffffffc0201726:	00281713          	slli	a4,a6,0x2
ffffffffc020172a:	9742                	add	a4,a4,a6
ffffffffc020172c:	070e                	slli	a4,a4,0x3
ffffffffc020172e:	971a                	add	a4,a4,t1
ffffffffc0201730:	06e50a63          	beq	a0,a4,ffffffffc02017a4 <best_fit_free_pages+0x102>
    if (le != &free_list) {
ffffffffc0201734:	fe878713          	addi	a4,a5,-24
ffffffffc0201738:	00d78d63          	beq	a5,a3,ffffffffc0201752 <best_fit_free_pages+0xb0>
        if (base + base->property == p) {
ffffffffc020173c:	490c                	lw	a1,16(a0)
ffffffffc020173e:	02059613          	slli	a2,a1,0x20
ffffffffc0201742:	9201                	srli	a2,a2,0x20
ffffffffc0201744:	00261693          	slli	a3,a2,0x2
ffffffffc0201748:	96b2                	add	a3,a3,a2
ffffffffc020174a:	068e                	slli	a3,a3,0x3
ffffffffc020174c:	96aa                	add	a3,a3,a0
ffffffffc020174e:	02d70863          	beq	a4,a3,ffffffffc020177e <best_fit_free_pages+0xdc>
}
ffffffffc0201752:	60a2                	ld	ra,8(sp)
ffffffffc0201754:	0141                	addi	sp,sp,16
ffffffffc0201756:	8082                	ret
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201758:	6390                	ld	a2,0(a5)
    prev->next = next->prev = elm;
ffffffffc020175a:	0107b023          	sd	a6,0(a5)
ffffffffc020175e:	01063423          	sd	a6,8(a2)
    elm->next = next;
ffffffffc0201762:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201764:	ed10                	sd	a2,24(a0)
    if (le != &free_list) {
ffffffffc0201766:	fad618e3          	bne	a2,a3,ffffffffc0201716 <best_fit_free_pages+0x74>
ffffffffc020176a:	bfc9                	j	ffffffffc020173c <best_fit_free_pages+0x9a>
}
ffffffffc020176c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020176e:	0107b023          	sd	a6,0(a5)
ffffffffc0201772:	0107b423          	sd	a6,8(a5)
    elm->next = next;
ffffffffc0201776:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201778:	ed1c                	sd	a5,24(a0)
ffffffffc020177a:	0141                	addi	sp,sp,16
ffffffffc020177c:	8082                	ret
            base->property += p->property;
ffffffffc020177e:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0201782:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201786:	0007b803          	ld	a6,0(a5)
ffffffffc020178a:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc020178c:	9db5                	addw	a1,a1,a3
ffffffffc020178e:	c90c                	sw	a1,16(a0)
            ClearPageProperty(p);
ffffffffc0201790:	9b75                	andi	a4,a4,-3
ffffffffc0201792:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0201796:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201798:	00c83423          	sd	a2,8(a6) # ffffffffc8000008 <end+0x7df9b68>
    next->prev = prev;
ffffffffc020179c:	01063023          	sd	a6,0(a2)
ffffffffc02017a0:	0141                	addi	sp,sp,16
ffffffffc02017a2:	8082                	ret
            p->property += base->property;
ffffffffc02017a4:	01c585bb          	addw	a1,a1,t3
ffffffffc02017a8:	feb62c23          	sw	a1,-8(a2)
            ClearPageProperty(base);
ffffffffc02017ac:	ffd8f893          	andi	a7,a7,-3
ffffffffc02017b0:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc02017b4:	e61c                	sd	a5,8(a2)
    next->prev = prev;
ffffffffc02017b6:	e390                	sd	a2,0(a5)
            base = p;
ffffffffc02017b8:	851a                	mv	a0,t1
ffffffffc02017ba:	bfad                	j	ffffffffc0201734 <best_fit_free_pages+0x92>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017bc:	00001697          	auipc	a3,0x1
ffffffffc02017c0:	44468693          	addi	a3,a3,1092 # ffffffffc0202c00 <commands+0xb18>
ffffffffc02017c4:	00001617          	auipc	a2,0x1
ffffffffc02017c8:	14c60613          	addi	a2,a2,332 # ffffffffc0202910 <commands+0x828>
ffffffffc02017cc:	09500593          	li	a1,149
ffffffffc02017d0:	00001517          	auipc	a0,0x1
ffffffffc02017d4:	15850513          	addi	a0,a0,344 # ffffffffc0202928 <commands+0x840>
ffffffffc02017d8:	989fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(n > 0);
ffffffffc02017dc:	00001697          	auipc	a3,0x1
ffffffffc02017e0:	12c68693          	addi	a3,a3,300 # ffffffffc0202908 <commands+0x820>
ffffffffc02017e4:	00001617          	auipc	a2,0x1
ffffffffc02017e8:	12c60613          	addi	a2,a2,300 # ffffffffc0202910 <commands+0x828>
ffffffffc02017ec:	09200593          	li	a1,146
ffffffffc02017f0:	00001517          	auipc	a0,0x1
ffffffffc02017f4:	13850513          	addi	a0,a0,312 # ffffffffc0202928 <commands+0x840>
ffffffffc02017f8:	969fe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc02017fc <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc02017fc:	1141                	addi	sp,sp,-16
ffffffffc02017fe:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201800:	cdd1                	beqz	a1,ffffffffc020189c <best_fit_init_memmap+0xa0>
    for (; p != base + n; p ++) {
ffffffffc0201802:	00259693          	slli	a3,a1,0x2
ffffffffc0201806:	96ae                	add	a3,a3,a1
ffffffffc0201808:	068e                	slli	a3,a3,0x3
ffffffffc020180a:	96aa                	add	a3,a3,a0
ffffffffc020180c:	87aa                	mv	a5,a0
ffffffffc020180e:	00d50f63          	beq	a0,a3,ffffffffc020182c <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0201812:	6798                	ld	a4,8(a5)
ffffffffc0201814:	8b05                	andi	a4,a4,1
ffffffffc0201816:	c33d                	beqz	a4,ffffffffc020187c <best_fit_init_memmap+0x80>
        p->flags = p->property = 0;
ffffffffc0201818:	0007a823          	sw	zero,16(a5)
ffffffffc020181c:	0007b423          	sd	zero,8(a5)
ffffffffc0201820:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201824:	02878793          	addi	a5,a5,40
ffffffffc0201828:	fed795e3          	bne	a5,a3,ffffffffc0201812 <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc020182c:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc020182e:	00004697          	auipc	a3,0x4
ffffffffc0201832:	7fa68693          	addi	a3,a3,2042 # ffffffffc0206028 <free_area>
ffffffffc0201836:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0201838:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc020183a:	00266613          	ori	a2,a2,2
    return list->next == list;
ffffffffc020183e:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc0201840:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201842:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0201844:	9db9                	addw	a1,a1,a4
ffffffffc0201846:	ca8c                	sw	a1,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201848:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc020184c:	02d78163          	beq	a5,a3,ffffffffc020186e <best_fit_init_memmap+0x72>
            struct Page* page = le2page(le, page_link);
ffffffffc0201850:	fe878713          	addi	a4,a5,-24
            if (base < page) {// 讲base插入到合适的地址
ffffffffc0201854:	00e56563          	bltu	a0,a4,ffffffffc020185e <best_fit_init_memmap+0x62>
    return listelm->next;
ffffffffc0201858:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020185a:	fed79be3          	bne	a5,a3,ffffffffc0201850 <best_fit_init_memmap+0x54>
    __list_add(elm, listelm->prev, listelm);
ffffffffc020185e:	6398                	ld	a4,0(a5)
}
ffffffffc0201860:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201862:	e390                	sd	a2,0(a5)
ffffffffc0201864:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201866:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201868:	ed18                	sd	a4,24(a0)
ffffffffc020186a:	0141                	addi	sp,sp,16
ffffffffc020186c:	8082                	ret
ffffffffc020186e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201870:	e390                	sd	a2,0(a5)
ffffffffc0201872:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201874:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201876:	ed1c                	sd	a5,24(a0)
ffffffffc0201878:	0141                	addi	sp,sp,16
ffffffffc020187a:	8082                	ret
        assert(PageReserved(p));
ffffffffc020187c:	00001697          	auipc	a3,0x1
ffffffffc0201880:	3ac68693          	addi	a3,a3,940 # ffffffffc0202c28 <commands+0xb40>
ffffffffc0201884:	00001617          	auipc	a2,0x1
ffffffffc0201888:	08c60613          	addi	a2,a2,140 # ffffffffc0202910 <commands+0x828>
ffffffffc020188c:	04a00593          	li	a1,74
ffffffffc0201890:	00001517          	auipc	a0,0x1
ffffffffc0201894:	09850513          	addi	a0,a0,152 # ffffffffc0202928 <commands+0x840>
ffffffffc0201898:	8c9fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(n > 0);
ffffffffc020189c:	00001697          	auipc	a3,0x1
ffffffffc02018a0:	06c68693          	addi	a3,a3,108 # ffffffffc0202908 <commands+0x820>
ffffffffc02018a4:	00001617          	auipc	a2,0x1
ffffffffc02018a8:	06c60613          	addi	a2,a2,108 # ffffffffc0202910 <commands+0x828>
ffffffffc02018ac:	04700593          	li	a1,71
ffffffffc02018b0:	00001517          	auipc	a0,0x1
ffffffffc02018b4:	07850513          	addi	a0,a0,120 # ffffffffc0202928 <commands+0x840>
ffffffffc02018b8:	8a9fe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc02018bc <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02018bc:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02018c0:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02018c2:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02018c4:	cb81                	beqz	a5,ffffffffc02018d4 <strlen+0x18>
        cnt ++;
ffffffffc02018c6:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02018c8:	00a707b3          	add	a5,a4,a0
ffffffffc02018cc:	0007c783          	lbu	a5,0(a5)
ffffffffc02018d0:	fbfd                	bnez	a5,ffffffffc02018c6 <strlen+0xa>
ffffffffc02018d2:	8082                	ret
    }
    return cnt;
}
ffffffffc02018d4:	8082                	ret

ffffffffc02018d6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02018d6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02018d8:	e589                	bnez	a1,ffffffffc02018e2 <strnlen+0xc>
ffffffffc02018da:	a811                	j	ffffffffc02018ee <strnlen+0x18>
        cnt ++;
ffffffffc02018dc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02018de:	00f58863          	beq	a1,a5,ffffffffc02018ee <strnlen+0x18>
ffffffffc02018e2:	00f50733          	add	a4,a0,a5
ffffffffc02018e6:	00074703          	lbu	a4,0(a4) # fffffffffff80000 <end+0x3fd79b60>
ffffffffc02018ea:	fb6d                	bnez	a4,ffffffffc02018dc <strnlen+0x6>
ffffffffc02018ec:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02018ee:	852e                	mv	a0,a1
ffffffffc02018f0:	8082                	ret

ffffffffc02018f2 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02018f2:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02018f6:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02018fa:	cb89                	beqz	a5,ffffffffc020190c <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02018fc:	0505                	addi	a0,a0,1
ffffffffc02018fe:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201900:	fee789e3          	beq	a5,a4,ffffffffc02018f2 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201904:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201908:	9d19                	subw	a0,a0,a4
ffffffffc020190a:	8082                	ret
ffffffffc020190c:	4501                	li	a0,0
ffffffffc020190e:	bfed                	j	ffffffffc0201908 <strcmp+0x16>

ffffffffc0201910 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201910:	c20d                	beqz	a2,ffffffffc0201932 <strncmp+0x22>
ffffffffc0201912:	962e                	add	a2,a2,a1
ffffffffc0201914:	a031                	j	ffffffffc0201920 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201916:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201918:	00e79a63          	bne	a5,a4,ffffffffc020192c <strncmp+0x1c>
ffffffffc020191c:	00b60b63          	beq	a2,a1,ffffffffc0201932 <strncmp+0x22>
ffffffffc0201920:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201924:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201926:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020192a:	f7f5                	bnez	a5,ffffffffc0201916 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020192c:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201930:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201932:	4501                	li	a0,0
ffffffffc0201934:	8082                	ret

ffffffffc0201936 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201936:	00054783          	lbu	a5,0(a0)
ffffffffc020193a:	c799                	beqz	a5,ffffffffc0201948 <strchr+0x12>
        if (*s == c) {
ffffffffc020193c:	00f58763          	beq	a1,a5,ffffffffc020194a <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201940:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201944:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201946:	fbfd                	bnez	a5,ffffffffc020193c <strchr+0x6>
    }
    return NULL;
ffffffffc0201948:	4501                	li	a0,0
}
ffffffffc020194a:	8082                	ret

ffffffffc020194c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020194c:	ca01                	beqz	a2,ffffffffc020195c <memset+0x10>
ffffffffc020194e:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201950:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201952:	0785                	addi	a5,a5,1
ffffffffc0201954:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201958:	fec79de3          	bne	a5,a2,ffffffffc0201952 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020195c:	8082                	ret

ffffffffc020195e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020195e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201962:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201964:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201968:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020196a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020196e:	f022                	sd	s0,32(sp)
ffffffffc0201970:	ec26                	sd	s1,24(sp)
ffffffffc0201972:	e84a                	sd	s2,16(sp)
ffffffffc0201974:	f406                	sd	ra,40(sp)
ffffffffc0201976:	e44e                	sd	s3,8(sp)
ffffffffc0201978:	84aa                	mv	s1,a0
ffffffffc020197a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020197c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201980:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201982:	03067e63          	bgeu	a2,a6,ffffffffc02019be <printnum+0x60>
ffffffffc0201986:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201988:	00805763          	blez	s0,ffffffffc0201996 <printnum+0x38>
ffffffffc020198c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020198e:	85ca                	mv	a1,s2
ffffffffc0201990:	854e                	mv	a0,s3
ffffffffc0201992:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201994:	fc65                	bnez	s0,ffffffffc020198c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201996:	1a02                	slli	s4,s4,0x20
ffffffffc0201998:	00001797          	auipc	a5,0x1
ffffffffc020199c:	2f078793          	addi	a5,a5,752 # ffffffffc0202c88 <best_fit_pmm_manager+0x38>
ffffffffc02019a0:	020a5a13          	srli	s4,s4,0x20
ffffffffc02019a4:	9a3e                	add	s4,s4,a5
}
ffffffffc02019a6:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019a8:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02019ac:	70a2                	ld	ra,40(sp)
ffffffffc02019ae:	69a2                	ld	s3,8(sp)
ffffffffc02019b0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019b2:	85ca                	mv	a1,s2
ffffffffc02019b4:	87a6                	mv	a5,s1
}
ffffffffc02019b6:	6942                	ld	s2,16(sp)
ffffffffc02019b8:	64e2                	ld	s1,24(sp)
ffffffffc02019ba:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019bc:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02019be:	03065633          	divu	a2,a2,a6
ffffffffc02019c2:	8722                	mv	a4,s0
ffffffffc02019c4:	f9bff0ef          	jal	ra,ffffffffc020195e <printnum>
ffffffffc02019c8:	b7f9                	j	ffffffffc0201996 <printnum+0x38>

ffffffffc02019ca <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02019ca:	7119                	addi	sp,sp,-128
ffffffffc02019cc:	f4a6                	sd	s1,104(sp)
ffffffffc02019ce:	f0ca                	sd	s2,96(sp)
ffffffffc02019d0:	ecce                	sd	s3,88(sp)
ffffffffc02019d2:	e8d2                	sd	s4,80(sp)
ffffffffc02019d4:	e4d6                	sd	s5,72(sp)
ffffffffc02019d6:	e0da                	sd	s6,64(sp)
ffffffffc02019d8:	fc5e                	sd	s7,56(sp)
ffffffffc02019da:	f06a                	sd	s10,32(sp)
ffffffffc02019dc:	fc86                	sd	ra,120(sp)
ffffffffc02019de:	f8a2                	sd	s0,112(sp)
ffffffffc02019e0:	f862                	sd	s8,48(sp)
ffffffffc02019e2:	f466                	sd	s9,40(sp)
ffffffffc02019e4:	ec6e                	sd	s11,24(sp)
ffffffffc02019e6:	892a                	mv	s2,a0
ffffffffc02019e8:	84ae                	mv	s1,a1
ffffffffc02019ea:	8d32                	mv	s10,a2
ffffffffc02019ec:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019ee:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02019f2:	5b7d                	li	s6,-1
ffffffffc02019f4:	00001a97          	auipc	s5,0x1
ffffffffc02019f8:	2c8a8a93          	addi	s5,s5,712 # ffffffffc0202cbc <best_fit_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02019fc:	00001b97          	auipc	s7,0x1
ffffffffc0201a00:	49cb8b93          	addi	s7,s7,1180 # ffffffffc0202e98 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a04:	000d4503          	lbu	a0,0(s10)
ffffffffc0201a08:	001d0413          	addi	s0,s10,1
ffffffffc0201a0c:	01350a63          	beq	a0,s3,ffffffffc0201a20 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201a10:	c121                	beqz	a0,ffffffffc0201a50 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201a12:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a14:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201a16:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a18:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201a1c:	ff351ae3          	bne	a0,s3,ffffffffc0201a10 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a20:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201a24:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201a28:	4c81                	li	s9,0
ffffffffc0201a2a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201a2c:	5c7d                	li	s8,-1
ffffffffc0201a2e:	5dfd                	li	s11,-1
ffffffffc0201a30:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201a34:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a36:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a3a:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a3e:	00140d13          	addi	s10,s0,1
ffffffffc0201a42:	04b56263          	bltu	a0,a1,ffffffffc0201a86 <vprintfmt+0xbc>
ffffffffc0201a46:	058a                	slli	a1,a1,0x2
ffffffffc0201a48:	95d6                	add	a1,a1,s5
ffffffffc0201a4a:	4194                	lw	a3,0(a1)
ffffffffc0201a4c:	96d6                	add	a3,a3,s5
ffffffffc0201a4e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201a50:	70e6                	ld	ra,120(sp)
ffffffffc0201a52:	7446                	ld	s0,112(sp)
ffffffffc0201a54:	74a6                	ld	s1,104(sp)
ffffffffc0201a56:	7906                	ld	s2,96(sp)
ffffffffc0201a58:	69e6                	ld	s3,88(sp)
ffffffffc0201a5a:	6a46                	ld	s4,80(sp)
ffffffffc0201a5c:	6aa6                	ld	s5,72(sp)
ffffffffc0201a5e:	6b06                	ld	s6,64(sp)
ffffffffc0201a60:	7be2                	ld	s7,56(sp)
ffffffffc0201a62:	7c42                	ld	s8,48(sp)
ffffffffc0201a64:	7ca2                	ld	s9,40(sp)
ffffffffc0201a66:	7d02                	ld	s10,32(sp)
ffffffffc0201a68:	6de2                	ld	s11,24(sp)
ffffffffc0201a6a:	6109                	addi	sp,sp,128
ffffffffc0201a6c:	8082                	ret
            padc = '0';
ffffffffc0201a6e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201a70:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a74:	846a                	mv	s0,s10
ffffffffc0201a76:	00140d13          	addi	s10,s0,1
ffffffffc0201a7a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a7e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a82:	fcb572e3          	bgeu	a0,a1,ffffffffc0201a46 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201a86:	85a6                	mv	a1,s1
ffffffffc0201a88:	02500513          	li	a0,37
ffffffffc0201a8c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201a8e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201a92:	8d22                	mv	s10,s0
ffffffffc0201a94:	f73788e3          	beq	a5,s3,ffffffffc0201a04 <vprintfmt+0x3a>
ffffffffc0201a98:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201a9c:	1d7d                	addi	s10,s10,-1
ffffffffc0201a9e:	ff379de3          	bne	a5,s3,ffffffffc0201a98 <vprintfmt+0xce>
ffffffffc0201aa2:	b78d                	j	ffffffffc0201a04 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201aa4:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201aa8:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aac:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201aae:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201ab2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201ab6:	02d86463          	bltu	a6,a3,ffffffffc0201ade <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201aba:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201abe:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201ac2:	0186873b          	addw	a4,a3,s8
ffffffffc0201ac6:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201aca:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201acc:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201ad0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201ad2:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201ad6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201ada:	fed870e3          	bgeu	a6,a3,ffffffffc0201aba <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201ade:	f40ddce3          	bgez	s11,ffffffffc0201a36 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201ae2:	8de2                	mv	s11,s8
ffffffffc0201ae4:	5c7d                	li	s8,-1
ffffffffc0201ae6:	bf81                	j	ffffffffc0201a36 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201ae8:	fffdc693          	not	a3,s11
ffffffffc0201aec:	96fd                	srai	a3,a3,0x3f
ffffffffc0201aee:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201af2:	00144603          	lbu	a2,1(s0)
ffffffffc0201af6:	2d81                	sext.w	s11,s11
ffffffffc0201af8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201afa:	bf35                	j	ffffffffc0201a36 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201afc:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b00:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201b04:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b06:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201b08:	bfd9                	j	ffffffffc0201ade <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201b0a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b0c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b10:	01174463          	blt	a4,a7,ffffffffc0201b18 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201b14:	1a088e63          	beqz	a7,ffffffffc0201cd0 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201b18:	000a3603          	ld	a2,0(s4)
ffffffffc0201b1c:	46c1                	li	a3,16
ffffffffc0201b1e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b20:	2781                	sext.w	a5,a5
ffffffffc0201b22:	876e                	mv	a4,s11
ffffffffc0201b24:	85a6                	mv	a1,s1
ffffffffc0201b26:	854a                	mv	a0,s2
ffffffffc0201b28:	e37ff0ef          	jal	ra,ffffffffc020195e <printnum>
            break;
ffffffffc0201b2c:	bde1                	j	ffffffffc0201a04 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b2e:	000a2503          	lw	a0,0(s4)
ffffffffc0201b32:	85a6                	mv	a1,s1
ffffffffc0201b34:	0a21                	addi	s4,s4,8
ffffffffc0201b36:	9902                	jalr	s2
            break;
ffffffffc0201b38:	b5f1                	j	ffffffffc0201a04 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201b3a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b3c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b40:	01174463          	blt	a4,a7,ffffffffc0201b48 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201b44:	18088163          	beqz	a7,ffffffffc0201cc6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201b48:	000a3603          	ld	a2,0(s4)
ffffffffc0201b4c:	46a9                	li	a3,10
ffffffffc0201b4e:	8a2e                	mv	s4,a1
ffffffffc0201b50:	bfc1                	j	ffffffffc0201b20 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b52:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201b56:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b58:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b5a:	bdf1                	j	ffffffffc0201a36 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201b5c:	85a6                	mv	a1,s1
ffffffffc0201b5e:	02500513          	li	a0,37
ffffffffc0201b62:	9902                	jalr	s2
            break;
ffffffffc0201b64:	b545                	j	ffffffffc0201a04 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b66:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201b6a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b6c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b6e:	b5e1                	j	ffffffffc0201a36 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201b70:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b72:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b76:	01174463          	blt	a4,a7,ffffffffc0201b7e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201b7a:	14088163          	beqz	a7,ffffffffc0201cbc <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201b7e:	000a3603          	ld	a2,0(s4)
ffffffffc0201b82:	46a1                	li	a3,8
ffffffffc0201b84:	8a2e                	mv	s4,a1
ffffffffc0201b86:	bf69                	j	ffffffffc0201b20 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201b88:	03000513          	li	a0,48
ffffffffc0201b8c:	85a6                	mv	a1,s1
ffffffffc0201b8e:	e03e                	sd	a5,0(sp)
ffffffffc0201b90:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201b92:	85a6                	mv	a1,s1
ffffffffc0201b94:	07800513          	li	a0,120
ffffffffc0201b98:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b9a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201b9c:	6782                	ld	a5,0(sp)
ffffffffc0201b9e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201ba0:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201ba4:	bfb5                	j	ffffffffc0201b20 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201ba6:	000a3403          	ld	s0,0(s4)
ffffffffc0201baa:	008a0713          	addi	a4,s4,8
ffffffffc0201bae:	e03a                	sd	a4,0(sp)
ffffffffc0201bb0:	14040263          	beqz	s0,ffffffffc0201cf4 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201bb4:	0fb05763          	blez	s11,ffffffffc0201ca2 <vprintfmt+0x2d8>
ffffffffc0201bb8:	02d00693          	li	a3,45
ffffffffc0201bbc:	0cd79163          	bne	a5,a3,ffffffffc0201c7e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bc0:	00044783          	lbu	a5,0(s0)
ffffffffc0201bc4:	0007851b          	sext.w	a0,a5
ffffffffc0201bc8:	cf85                	beqz	a5,ffffffffc0201c00 <vprintfmt+0x236>
ffffffffc0201bca:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bce:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bd2:	000c4563          	bltz	s8,ffffffffc0201bdc <vprintfmt+0x212>
ffffffffc0201bd6:	3c7d                	addiw	s8,s8,-1
ffffffffc0201bd8:	036c0263          	beq	s8,s6,ffffffffc0201bfc <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201bdc:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bde:	0e0c8e63          	beqz	s9,ffffffffc0201cda <vprintfmt+0x310>
ffffffffc0201be2:	3781                	addiw	a5,a5,-32
ffffffffc0201be4:	0ef47b63          	bgeu	s0,a5,ffffffffc0201cda <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201be8:	03f00513          	li	a0,63
ffffffffc0201bec:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bee:	000a4783          	lbu	a5,0(s4)
ffffffffc0201bf2:	3dfd                	addiw	s11,s11,-1
ffffffffc0201bf4:	0a05                	addi	s4,s4,1
ffffffffc0201bf6:	0007851b          	sext.w	a0,a5
ffffffffc0201bfa:	ffe1                	bnez	a5,ffffffffc0201bd2 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201bfc:	01b05963          	blez	s11,ffffffffc0201c0e <vprintfmt+0x244>
ffffffffc0201c00:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201c02:	85a6                	mv	a1,s1
ffffffffc0201c04:	02000513          	li	a0,32
ffffffffc0201c08:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201c0a:	fe0d9be3          	bnez	s11,ffffffffc0201c00 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c0e:	6a02                	ld	s4,0(sp)
ffffffffc0201c10:	bbd5                	j	ffffffffc0201a04 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c12:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c14:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201c18:	01174463          	blt	a4,a7,ffffffffc0201c20 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201c1c:	08088d63          	beqz	a7,ffffffffc0201cb6 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201c20:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201c24:	0a044d63          	bltz	s0,ffffffffc0201cde <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201c28:	8622                	mv	a2,s0
ffffffffc0201c2a:	8a66                	mv	s4,s9
ffffffffc0201c2c:	46a9                	li	a3,10
ffffffffc0201c2e:	bdcd                	j	ffffffffc0201b20 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201c30:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c34:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201c36:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201c38:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201c3c:	8fb5                	xor	a5,a5,a3
ffffffffc0201c3e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c42:	02d74163          	blt	a4,a3,ffffffffc0201c64 <vprintfmt+0x29a>
ffffffffc0201c46:	00369793          	slli	a5,a3,0x3
ffffffffc0201c4a:	97de                	add	a5,a5,s7
ffffffffc0201c4c:	639c                	ld	a5,0(a5)
ffffffffc0201c4e:	cb99                	beqz	a5,ffffffffc0201c64 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201c50:	86be                	mv	a3,a5
ffffffffc0201c52:	00001617          	auipc	a2,0x1
ffffffffc0201c56:	06660613          	addi	a2,a2,102 # ffffffffc0202cb8 <best_fit_pmm_manager+0x68>
ffffffffc0201c5a:	85a6                	mv	a1,s1
ffffffffc0201c5c:	854a                	mv	a0,s2
ffffffffc0201c5e:	0ce000ef          	jal	ra,ffffffffc0201d2c <printfmt>
ffffffffc0201c62:	b34d                	j	ffffffffc0201a04 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201c64:	00001617          	auipc	a2,0x1
ffffffffc0201c68:	04460613          	addi	a2,a2,68 # ffffffffc0202ca8 <best_fit_pmm_manager+0x58>
ffffffffc0201c6c:	85a6                	mv	a1,s1
ffffffffc0201c6e:	854a                	mv	a0,s2
ffffffffc0201c70:	0bc000ef          	jal	ra,ffffffffc0201d2c <printfmt>
ffffffffc0201c74:	bb41                	j	ffffffffc0201a04 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201c76:	00001417          	auipc	s0,0x1
ffffffffc0201c7a:	02a40413          	addi	s0,s0,42 # ffffffffc0202ca0 <best_fit_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c7e:	85e2                	mv	a1,s8
ffffffffc0201c80:	8522                	mv	a0,s0
ffffffffc0201c82:	e43e                	sd	a5,8(sp)
ffffffffc0201c84:	c53ff0ef          	jal	ra,ffffffffc02018d6 <strnlen>
ffffffffc0201c88:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201c8c:	01b05b63          	blez	s11,ffffffffc0201ca2 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201c90:	67a2                	ld	a5,8(sp)
ffffffffc0201c92:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c96:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201c98:	85a6                	mv	a1,s1
ffffffffc0201c9a:	8552                	mv	a0,s4
ffffffffc0201c9c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c9e:	fe0d9ce3          	bnez	s11,ffffffffc0201c96 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ca2:	00044783          	lbu	a5,0(s0)
ffffffffc0201ca6:	00140a13          	addi	s4,s0,1
ffffffffc0201caa:	0007851b          	sext.w	a0,a5
ffffffffc0201cae:	d3a5                	beqz	a5,ffffffffc0201c0e <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cb0:	05e00413          	li	s0,94
ffffffffc0201cb4:	bf39                	j	ffffffffc0201bd2 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201cb6:	000a2403          	lw	s0,0(s4)
ffffffffc0201cba:	b7ad                	j	ffffffffc0201c24 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201cbc:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cc0:	46a1                	li	a3,8
ffffffffc0201cc2:	8a2e                	mv	s4,a1
ffffffffc0201cc4:	bdb1                	j	ffffffffc0201b20 <vprintfmt+0x156>
ffffffffc0201cc6:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cca:	46a9                	li	a3,10
ffffffffc0201ccc:	8a2e                	mv	s4,a1
ffffffffc0201cce:	bd89                	j	ffffffffc0201b20 <vprintfmt+0x156>
ffffffffc0201cd0:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cd4:	46c1                	li	a3,16
ffffffffc0201cd6:	8a2e                	mv	s4,a1
ffffffffc0201cd8:	b5a1                	j	ffffffffc0201b20 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201cda:	9902                	jalr	s2
ffffffffc0201cdc:	bf09                	j	ffffffffc0201bee <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201cde:	85a6                	mv	a1,s1
ffffffffc0201ce0:	02d00513          	li	a0,45
ffffffffc0201ce4:	e03e                	sd	a5,0(sp)
ffffffffc0201ce6:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201ce8:	6782                	ld	a5,0(sp)
ffffffffc0201cea:	8a66                	mv	s4,s9
ffffffffc0201cec:	40800633          	neg	a2,s0
ffffffffc0201cf0:	46a9                	li	a3,10
ffffffffc0201cf2:	b53d                	j	ffffffffc0201b20 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201cf4:	03b05163          	blez	s11,ffffffffc0201d16 <vprintfmt+0x34c>
ffffffffc0201cf8:	02d00693          	li	a3,45
ffffffffc0201cfc:	f6d79de3          	bne	a5,a3,ffffffffc0201c76 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201d00:	00001417          	auipc	s0,0x1
ffffffffc0201d04:	fa040413          	addi	s0,s0,-96 # ffffffffc0202ca0 <best_fit_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d08:	02800793          	li	a5,40
ffffffffc0201d0c:	02800513          	li	a0,40
ffffffffc0201d10:	00140a13          	addi	s4,s0,1
ffffffffc0201d14:	bd6d                	j	ffffffffc0201bce <vprintfmt+0x204>
ffffffffc0201d16:	00001a17          	auipc	s4,0x1
ffffffffc0201d1a:	f8ba0a13          	addi	s4,s4,-117 # ffffffffc0202ca1 <best_fit_pmm_manager+0x51>
ffffffffc0201d1e:	02800513          	li	a0,40
ffffffffc0201d22:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d26:	05e00413          	li	s0,94
ffffffffc0201d2a:	b565                	j	ffffffffc0201bd2 <vprintfmt+0x208>

ffffffffc0201d2c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d2c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d2e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d32:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d34:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d36:	ec06                	sd	ra,24(sp)
ffffffffc0201d38:	f83a                	sd	a4,48(sp)
ffffffffc0201d3a:	fc3e                	sd	a5,56(sp)
ffffffffc0201d3c:	e0c2                	sd	a6,64(sp)
ffffffffc0201d3e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d40:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d42:	c89ff0ef          	jal	ra,ffffffffc02019ca <vprintfmt>
}
ffffffffc0201d46:	60e2                	ld	ra,24(sp)
ffffffffc0201d48:	6161                	addi	sp,sp,80
ffffffffc0201d4a:	8082                	ret

ffffffffc0201d4c <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201d4c:	715d                	addi	sp,sp,-80
ffffffffc0201d4e:	e486                	sd	ra,72(sp)
ffffffffc0201d50:	e0a6                	sd	s1,64(sp)
ffffffffc0201d52:	fc4a                	sd	s2,56(sp)
ffffffffc0201d54:	f84e                	sd	s3,48(sp)
ffffffffc0201d56:	f452                	sd	s4,40(sp)
ffffffffc0201d58:	f056                	sd	s5,32(sp)
ffffffffc0201d5a:	ec5a                	sd	s6,24(sp)
ffffffffc0201d5c:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201d5e:	c901                	beqz	a0,ffffffffc0201d6e <readline+0x22>
ffffffffc0201d60:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201d62:	00001517          	auipc	a0,0x1
ffffffffc0201d66:	f5650513          	addi	a0,a0,-170 # ffffffffc0202cb8 <best_fit_pmm_manager+0x68>
ffffffffc0201d6a:	b6efe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
readline(const char *prompt) {
ffffffffc0201d6e:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d70:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201d72:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201d74:	4aa9                	li	s5,10
ffffffffc0201d76:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201d78:	00004b97          	auipc	s7,0x4
ffffffffc0201d7c:	2c8b8b93          	addi	s7,s7,712 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d80:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201d84:	bccfe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201d88:	00054a63          	bltz	a0,ffffffffc0201d9c <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d8c:	00a95a63          	bge	s2,a0,ffffffffc0201da0 <readline+0x54>
ffffffffc0201d90:	029a5263          	bge	s4,s1,ffffffffc0201db4 <readline+0x68>
        c = getchar();
ffffffffc0201d94:	bbcfe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201d98:	fe055ae3          	bgez	a0,ffffffffc0201d8c <readline+0x40>
            return NULL;
ffffffffc0201d9c:	4501                	li	a0,0
ffffffffc0201d9e:	a091                	j	ffffffffc0201de2 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201da0:	03351463          	bne	a0,s3,ffffffffc0201dc8 <readline+0x7c>
ffffffffc0201da4:	e8a9                	bnez	s1,ffffffffc0201df6 <readline+0xaa>
        c = getchar();
ffffffffc0201da6:	baafe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201daa:	fe0549e3          	bltz	a0,ffffffffc0201d9c <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dae:	fea959e3          	bge	s2,a0,ffffffffc0201da0 <readline+0x54>
ffffffffc0201db2:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201db4:	e42a                	sd	a0,8(sp)
ffffffffc0201db6:	b58fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i ++] = c;
ffffffffc0201dba:	6522                	ld	a0,8(sp)
ffffffffc0201dbc:	009b87b3          	add	a5,s7,s1
ffffffffc0201dc0:	2485                	addiw	s1,s1,1
ffffffffc0201dc2:	00a78023          	sb	a0,0(a5)
ffffffffc0201dc6:	bf7d                	j	ffffffffc0201d84 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201dc8:	01550463          	beq	a0,s5,ffffffffc0201dd0 <readline+0x84>
ffffffffc0201dcc:	fb651ce3          	bne	a0,s6,ffffffffc0201d84 <readline+0x38>
            cputchar(c);
ffffffffc0201dd0:	b3efe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i] = '\0';
ffffffffc0201dd4:	00004517          	auipc	a0,0x4
ffffffffc0201dd8:	26c50513          	addi	a0,a0,620 # ffffffffc0206040 <buf>
ffffffffc0201ddc:	94aa                	add	s1,s1,a0
ffffffffc0201dde:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201de2:	60a6                	ld	ra,72(sp)
ffffffffc0201de4:	6486                	ld	s1,64(sp)
ffffffffc0201de6:	7962                	ld	s2,56(sp)
ffffffffc0201de8:	79c2                	ld	s3,48(sp)
ffffffffc0201dea:	7a22                	ld	s4,40(sp)
ffffffffc0201dec:	7a82                	ld	s5,32(sp)
ffffffffc0201dee:	6b62                	ld	s6,24(sp)
ffffffffc0201df0:	6bc2                	ld	s7,16(sp)
ffffffffc0201df2:	6161                	addi	sp,sp,80
ffffffffc0201df4:	8082                	ret
            cputchar(c);
ffffffffc0201df6:	4521                	li	a0,8
ffffffffc0201df8:	b16fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            i --;
ffffffffc0201dfc:	34fd                	addiw	s1,s1,-1
ffffffffc0201dfe:	b759                	j	ffffffffc0201d84 <readline+0x38>

ffffffffc0201e00 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201e00:	4781                	li	a5,0
ffffffffc0201e02:	00004717          	auipc	a4,0x4
ffffffffc0201e06:	21673703          	ld	a4,534(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e0a:	88ba                	mv	a7,a4
ffffffffc0201e0c:	852a                	mv	a0,a0
ffffffffc0201e0e:	85be                	mv	a1,a5
ffffffffc0201e10:	863e                	mv	a2,a5
ffffffffc0201e12:	00000073          	ecall
ffffffffc0201e16:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e18:	8082                	ret

ffffffffc0201e1a <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201e1a:	4781                	li	a5,0
ffffffffc0201e1c:	00004717          	auipc	a4,0x4
ffffffffc0201e20:	67c73703          	ld	a4,1660(a4) # ffffffffc0206498 <SBI_SET_TIMER>
ffffffffc0201e24:	88ba                	mv	a7,a4
ffffffffc0201e26:	852a                	mv	a0,a0
ffffffffc0201e28:	85be                	mv	a1,a5
ffffffffc0201e2a:	863e                	mv	a2,a5
ffffffffc0201e2c:	00000073          	ecall
ffffffffc0201e30:	87aa                	mv	a5,a0
 * @stime_value: 触发定时器中断的目标时间（CPU周期数）
 * 通过SBI调用，通知底层固件在指定时间产生时钟中断。
 */
void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201e32:	8082                	ret

ffffffffc0201e34 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201e34:	4501                	li	a0,0
ffffffffc0201e36:	00004797          	auipc	a5,0x4
ffffffffc0201e3a:	1da7b783          	ld	a5,474(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e3e:	88be                	mv	a7,a5
ffffffffc0201e40:	852a                	mv	a0,a0
ffffffffc0201e42:	85aa                	mv	a1,a0
ffffffffc0201e44:	862a                	mv	a2,a0
ffffffffc0201e46:	00000073          	ecall
ffffffffc0201e4a:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201e4c:	2501                	sext.w	a0,a0
ffffffffc0201e4e:	8082                	ret

ffffffffc0201e50 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201e50:	4781                	li	a5,0
ffffffffc0201e52:	00004717          	auipc	a4,0x4
ffffffffc0201e56:	1ce73703          	ld	a4,462(a4) # ffffffffc0206020 <SBI_SHUTDOWN>
ffffffffc0201e5a:	88ba                	mv	a7,a4
ffffffffc0201e5c:	853e                	mv	a0,a5
ffffffffc0201e5e:	85be                	mv	a1,a5
ffffffffc0201e60:	863e                	mv	a2,a5
ffffffffc0201e62:	00000073          	ecall
ffffffffc0201e66:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201e68:	8082                	ret
