
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
ffffffffc0200034:	18029073          	csrw	satp,t0
ffffffffc0200038:	12000073          	sfence.vma
ffffffffc020003c:	c0206137          	lui	sp,0xc0206
ffffffffc0200040:	c0206337          	lui	t1,0xc0206
ffffffffc0200044:	00030313          	mv	t1,t1
ffffffffc0200048:	811a                	mv	sp,t1
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    // 解释：BSS段用于存放未初始化的全局变量，memset会将其全部清零。
    // 如果DTB（设备树）信息存放在BSS段中，必须先保存DTB内容，否则memset会把DTB数据清掉，导致后续无法获取设备信息。
    memset(edata, 0, end - edata);
ffffffffc0200054:	00007517          	auipc	a0,0x7
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0207028 <free_area>
ffffffffc020005c:	00007617          	auipc	a2,0x7
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02074a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	265010ef          	jal	ra,ffffffffc0201ad0 <memset>
    dtb_init();
ffffffffc0200070:	3be000ef          	jal	ra,ffffffffc020042e <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	7ae000ef          	jal	ra,ffffffffc0200822 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	f7850513          	addi	a0,a0,-136 # ffffffffc0201ff0 <etext+0x2>
ffffffffc0200080:	090000ef          	jal	ra,ffffffffc0200110 <cputs>

    print_kerninfo();
ffffffffc0200084:	138000ef          	jal	ra,ffffffffc02001bc <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7b4000ef          	jal	ra,ffffffffc020083c <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	4fd000ef          	jal	ra,ffffffffc0200d88 <pmm_init>

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
ffffffffc020009e:	1141                	addi	sp,sp,-16
ffffffffc02000a0:	e022                	sd	s0,0(sp)
ffffffffc02000a2:	e406                	sd	ra,8(sp)
ffffffffc02000a4:	842e                	mv	s0,a1
ffffffffc02000a6:	77e000ef          	jal	ra,ffffffffc0200824 <cons_putc>
ffffffffc02000aa:	401c                	lw	a5,0(s0)
ffffffffc02000ac:	60a2                	ld	ra,8(sp)
ffffffffc02000ae:	2785                	addiw	a5,a5,1
ffffffffc02000b0:	c01c                	sw	a5,0(s0)
ffffffffc02000b2:	6402                	ld	s0,0(sp)
ffffffffc02000b4:	0141                	addi	sp,sp,16
ffffffffc02000b6:	8082                	ret

ffffffffc02000b8 <vcprintf>:
ffffffffc02000b8:	1101                	addi	sp,sp,-32
ffffffffc02000ba:	862a                	mv	a2,a0
ffffffffc02000bc:	86ae                	mv	a3,a1
ffffffffc02000be:	00000517          	auipc	a0,0x0
ffffffffc02000c2:	fe050513          	addi	a0,a0,-32 # ffffffffc020009e <cputch>
ffffffffc02000c6:	006c                	addi	a1,sp,12
ffffffffc02000c8:	ec06                	sd	ra,24(sp)
ffffffffc02000ca:	c602                	sw	zero,12(sp)
ffffffffc02000cc:	283010ef          	jal	ra,ffffffffc0201b4e <vprintfmt>
ffffffffc02000d0:	60e2                	ld	ra,24(sp)
ffffffffc02000d2:	4532                	lw	a0,12(sp)
ffffffffc02000d4:	6105                	addi	sp,sp,32
ffffffffc02000d6:	8082                	ret

ffffffffc02000d8 <cprintf>:
ffffffffc02000d8:	711d                	addi	sp,sp,-96
ffffffffc02000da:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
ffffffffc02000de:	8e2a                	mv	t3,a0
ffffffffc02000e0:	f42e                	sd	a1,40(sp)
ffffffffc02000e2:	f832                	sd	a2,48(sp)
ffffffffc02000e4:	fc36                	sd	a3,56(sp)
ffffffffc02000e6:	00000517          	auipc	a0,0x0
ffffffffc02000ea:	fb850513          	addi	a0,a0,-72 # ffffffffc020009e <cputch>
ffffffffc02000ee:	004c                	addi	a1,sp,4
ffffffffc02000f0:	869a                	mv	a3,t1
ffffffffc02000f2:	8672                	mv	a2,t3
ffffffffc02000f4:	ec06                	sd	ra,24(sp)
ffffffffc02000f6:	e0ba                	sd	a4,64(sp)
ffffffffc02000f8:	e4be                	sd	a5,72(sp)
ffffffffc02000fa:	e8c2                	sd	a6,80(sp)
ffffffffc02000fc:	ecc6                	sd	a7,88(sp)
ffffffffc02000fe:	e41a                	sd	t1,8(sp)
ffffffffc0200100:	c202                	sw	zero,4(sp)
ffffffffc0200102:	24d010ef          	jal	ra,ffffffffc0201b4e <vprintfmt>
ffffffffc0200106:	60e2                	ld	ra,24(sp)
ffffffffc0200108:	4512                	lw	a0,4(sp)
ffffffffc020010a:	6125                	addi	sp,sp,96
ffffffffc020010c:	8082                	ret

ffffffffc020010e <cputchar>:
ffffffffc020010e:	af19                	j	ffffffffc0200824 <cons_putc>

ffffffffc0200110 <cputs>:
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	ec06                	sd	ra,24(sp)
ffffffffc0200116:	e426                	sd	s1,8(sp)
ffffffffc0200118:	842a                	mv	s0,a0
ffffffffc020011a:	00054503          	lbu	a0,0(a0)
ffffffffc020011e:	c51d                	beqz	a0,ffffffffc020014c <cputs+0x3c>
ffffffffc0200120:	0405                	addi	s0,s0,1
ffffffffc0200122:	4485                	li	s1,1
ffffffffc0200124:	9c81                	subw	s1,s1,s0
ffffffffc0200126:	6fe000ef          	jal	ra,ffffffffc0200824 <cons_putc>
ffffffffc020012a:	00044503          	lbu	a0,0(s0)
ffffffffc020012e:	008487bb          	addw	a5,s1,s0
ffffffffc0200132:	0405                	addi	s0,s0,1
ffffffffc0200134:	f96d                	bnez	a0,ffffffffc0200126 <cputs+0x16>
ffffffffc0200136:	0017841b          	addiw	s0,a5,1
ffffffffc020013a:	4529                	li	a0,10
ffffffffc020013c:	6e8000ef          	jal	ra,ffffffffc0200824 <cons_putc>
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	6442                	ld	s0,16(sp)
ffffffffc0200146:	64a2                	ld	s1,8(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret
ffffffffc020014c:	4405                	li	s0,1
ffffffffc020014e:	b7f5                	j	ffffffffc020013a <cputs+0x2a>

ffffffffc0200150 <getchar>:
ffffffffc0200150:	1141                	addi	sp,sp,-16
ffffffffc0200152:	e406                	sd	ra,8(sp)
ffffffffc0200154:	6d8000ef          	jal	ra,ffffffffc020082c <cons_getc>
ffffffffc0200158:	dd75                	beqz	a0,ffffffffc0200154 <getchar+0x4>
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
ffffffffc0200160:	00007317          	auipc	t1,0x7
ffffffffc0200164:	2e030313          	addi	t1,t1,736 # ffffffffc0207440 <is_panic>
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
ffffffffc0200192:	e8250513          	addi	a0,a0,-382 # ffffffffc0202010 <etext+0x22>
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
ffffffffc02001a8:	f5450513          	addi	a0,a0,-172 # ffffffffc02020f8 <etext+0x10a>
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
ffffffffc02001bc:	1141                	addi	sp,sp,-16
ffffffffc02001be:	00002517          	auipc	a0,0x2
ffffffffc02001c2:	e7250513          	addi	a0,a0,-398 # ffffffffc0202030 <etext+0x42>
ffffffffc02001c6:	e406                	sd	ra,8(sp)
ffffffffc02001c8:	f11ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02001cc:	00000597          	auipc	a1,0x0
ffffffffc02001d0:	e8858593          	addi	a1,a1,-376 # ffffffffc0200054 <kern_init>
ffffffffc02001d4:	00002517          	auipc	a0,0x2
ffffffffc02001d8:	e7c50513          	addi	a0,a0,-388 # ffffffffc0202050 <etext+0x62>
ffffffffc02001dc:	efdff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02001e0:	00002597          	auipc	a1,0x2
ffffffffc02001e4:	e0e58593          	addi	a1,a1,-498 # ffffffffc0201fee <etext>
ffffffffc02001e8:	00002517          	auipc	a0,0x2
ffffffffc02001ec:	e8850513          	addi	a0,a0,-376 # ffffffffc0202070 <etext+0x82>
ffffffffc02001f0:	ee9ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02001f4:	00007597          	auipc	a1,0x7
ffffffffc02001f8:	e3458593          	addi	a1,a1,-460 # ffffffffc0207028 <free_area>
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	e9450513          	addi	a0,a0,-364 # ffffffffc0202090 <etext+0xa2>
ffffffffc0200204:	ed5ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200208:	00007597          	auipc	a1,0x7
ffffffffc020020c:	29858593          	addi	a1,a1,664 # ffffffffc02074a0 <end>
ffffffffc0200210:	00002517          	auipc	a0,0x2
ffffffffc0200214:	ea050513          	addi	a0,a0,-352 # ffffffffc02020b0 <etext+0xc2>
ffffffffc0200218:	ec1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020021c:	00007597          	auipc	a1,0x7
ffffffffc0200220:	68358593          	addi	a1,a1,1667 # ffffffffc020789f <end+0x3ff>
ffffffffc0200224:	00000797          	auipc	a5,0x0
ffffffffc0200228:	e3078793          	addi	a5,a5,-464 # ffffffffc0200054 <kern_init>
ffffffffc020022c:	40f587b3          	sub	a5,a1,a5
ffffffffc0200230:	43f7d593          	srai	a1,a5,0x3f
ffffffffc0200234:	60a2                	ld	ra,8(sp)
ffffffffc0200236:	3ff5f593          	andi	a1,a1,1023
ffffffffc020023a:	95be                	add	a1,a1,a5
ffffffffc020023c:	85a9                	srai	a1,a1,0xa
ffffffffc020023e:	00002517          	auipc	a0,0x2
ffffffffc0200242:	e9250513          	addi	a0,a0,-366 # ffffffffc02020d0 <etext+0xe2>
ffffffffc0200246:	0141                	addi	sp,sp,16
ffffffffc0200248:	bd41                	j	ffffffffc02000d8 <cprintf>

ffffffffc020024a <print_stackframe>:
ffffffffc020024a:	1141                	addi	sp,sp,-16
ffffffffc020024c:	00002617          	auipc	a2,0x2
ffffffffc0200250:	eb460613          	addi	a2,a2,-332 # ffffffffc0202100 <etext+0x112>
ffffffffc0200254:	04d00593          	li	a1,77
ffffffffc0200258:	00002517          	auipc	a0,0x2
ffffffffc020025c:	ec050513          	addi	a0,a0,-320 # ffffffffc0202118 <etext+0x12a>
ffffffffc0200260:	e406                	sd	ra,8(sp)
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
ffffffffc020026c:	ec860613          	addi	a2,a2,-312 # ffffffffc0202130 <etext+0x142>
ffffffffc0200270:	00002597          	auipc	a1,0x2
ffffffffc0200274:	ee058593          	addi	a1,a1,-288 # ffffffffc0202150 <etext+0x162>
ffffffffc0200278:	00002517          	auipc	a0,0x2
ffffffffc020027c:	ee050513          	addi	a0,a0,-288 # ffffffffc0202158 <etext+0x16a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200280:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200282:	e57ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200286:	00002617          	auipc	a2,0x2
ffffffffc020028a:	ee260613          	addi	a2,a2,-286 # ffffffffc0202168 <etext+0x17a>
ffffffffc020028e:	00002597          	auipc	a1,0x2
ffffffffc0200292:	f0258593          	addi	a1,a1,-254 # ffffffffc0202190 <etext+0x1a2>
ffffffffc0200296:	00002517          	auipc	a0,0x2
ffffffffc020029a:	ec250513          	addi	a0,a0,-318 # ffffffffc0202158 <etext+0x16a>
ffffffffc020029e:	e3bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02002a2:	00002617          	auipc	a2,0x2
ffffffffc02002a6:	efe60613          	addi	a2,a2,-258 # ffffffffc02021a0 <etext+0x1b2>
ffffffffc02002aa:	00002597          	auipc	a1,0x2
ffffffffc02002ae:	f1658593          	addi	a1,a1,-234 # ffffffffc02021c0 <etext+0x1d2>
ffffffffc02002b2:	00002517          	auipc	a0,0x2
ffffffffc02002b6:	ea650513          	addi	a0,a0,-346 # ffffffffc0202158 <etext+0x16a>
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
ffffffffc02002f0:	ee450513          	addi	a0,a0,-284 # ffffffffc02021d0 <etext+0x1e2>
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
ffffffffc0200312:	eea50513          	addi	a0,a0,-278 # ffffffffc02021f8 <etext+0x20a>
ffffffffc0200316:	dc3ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    if (tf != NULL) {
ffffffffc020031a:	000b8563          	beqz	s7,ffffffffc0200324 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020031e:	855e                	mv	a0,s7
ffffffffc0200320:	6fc000ef          	jal	ra,ffffffffc0200a1c <print_trapframe>
ffffffffc0200324:	00002c17          	auipc	s8,0x2
ffffffffc0200328:	f44c0c13          	addi	s8,s8,-188 # ffffffffc0202268 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020032c:	00002917          	auipc	s2,0x2
ffffffffc0200330:	ef490913          	addi	s2,s2,-268 # ffffffffc0202220 <etext+0x232>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200334:	00002497          	auipc	s1,0x2
ffffffffc0200338:	ef448493          	addi	s1,s1,-268 # ffffffffc0202228 <etext+0x23a>
        if (argc == MAXARGS - 1) {
ffffffffc020033c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020033e:	00002b17          	auipc	s6,0x2
ffffffffc0200342:	ef2b0b13          	addi	s6,s6,-270 # ffffffffc0202230 <etext+0x242>
        argv[argc ++] = buf;
ffffffffc0200346:	00002a17          	auipc	s4,0x2
ffffffffc020034a:	e0aa0a13          	addi	s4,s4,-502 # ffffffffc0202150 <etext+0x162>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034e:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200350:	854a                	mv	a0,s2
ffffffffc0200352:	37f010ef          	jal	ra,ffffffffc0201ed0 <readline>
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
ffffffffc020036c:	f00d0d13          	addi	s10,s10,-256 # ffffffffc0202268 <commands>
        argv[argc ++] = buf;
ffffffffc0200370:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200372:	4401                	li	s0,0
ffffffffc0200374:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200376:	700010ef          	jal	ra,ffffffffc0201a76 <strcmp>
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
ffffffffc020038a:	6ec010ef          	jal	ra,ffffffffc0201a76 <strcmp>
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
ffffffffc02003c8:	6f2010ef          	jal	ra,ffffffffc0201aba <strchr>
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
ffffffffc0200406:	6b4010ef          	jal	ra,ffffffffc0201aba <strchr>
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
ffffffffc0200424:	e3050513          	addi	a0,a0,-464 # ffffffffc0202250 <etext+0x262>
ffffffffc0200428:	cb1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    return 0;
ffffffffc020042c:	b715                	j	ffffffffc0200350 <kmonitor+0x6a>

ffffffffc020042e <dtb_init>:
ffffffffc020042e:	7119                	addi	sp,sp,-128
ffffffffc0200430:	00002517          	auipc	a0,0x2
ffffffffc0200434:	e8050513          	addi	a0,a0,-384 # ffffffffc02022b0 <commands+0x48>
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
ffffffffc0200452:	c87ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200456:	00007597          	auipc	a1,0x7
ffffffffc020045a:	baa5b583          	ld	a1,-1110(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc020045e:	00002517          	auipc	a0,0x2
ffffffffc0200462:	e6250513          	addi	a0,a0,-414 # ffffffffc02022c0 <commands+0x58>
ffffffffc0200466:	c73ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020046a:	00007417          	auipc	s0,0x7
ffffffffc020046e:	b9e40413          	addi	s0,s0,-1122 # ffffffffc0207008 <boot_dtb>
ffffffffc0200472:	600c                	ld	a1,0(s0)
ffffffffc0200474:	00002517          	auipc	a0,0x2
ffffffffc0200478:	e5c50513          	addi	a0,a0,-420 # ffffffffc02022d0 <commands+0x68>
ffffffffc020047c:	c5dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200480:	00043a03          	ld	s4,0(s0)
ffffffffc0200484:	00002517          	auipc	a0,0x2
ffffffffc0200488:	e6450513          	addi	a0,a0,-412 # ffffffffc02022e8 <commands+0x80>
ffffffffc020048c:	120a0463          	beqz	s4,ffffffffc02005b4 <dtb_init+0x186>
ffffffffc0200490:	57f5                	li	a5,-3
ffffffffc0200492:	07fa                	slli	a5,a5,0x1e
ffffffffc0200494:	00fa0733          	add	a4,s4,a5
ffffffffc0200498:	431c                	lw	a5,0(a4)
ffffffffc020049a:	00ff0637          	lui	a2,0xff0
ffffffffc020049e:	6b41                	lui	s6,0x10
ffffffffc02004a0:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004a4:	0187969b          	slliw	a3,a5,0x18
ffffffffc02004a8:	0187d51b          	srliw	a0,a5,0x18
ffffffffc02004ac:	0105959b          	slliw	a1,a1,0x10
ffffffffc02004b0:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02004b4:	8df1                	and	a1,a1,a2
ffffffffc02004b6:	8ec9                	or	a3,a3,a0
ffffffffc02004b8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004bc:	1b7d                	addi	s6,s6,-1
ffffffffc02004be:	0167f7b3          	and	a5,a5,s6
ffffffffc02004c2:	8dd5                	or	a1,a1,a3
ffffffffc02004c4:	8ddd                	or	a1,a1,a5
ffffffffc02004c6:	d00e07b7          	lui	a5,0xd00e0
ffffffffc02004ca:	2581                	sext.w	a1,a1
ffffffffc02004cc:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8a4d>
ffffffffc02004d0:	10f59163          	bne	a1,a5,ffffffffc02005d2 <dtb_init+0x1a4>
ffffffffc02004d4:	471c                	lw	a5,8(a4)
ffffffffc02004d6:	4754                	lw	a3,12(a4)
ffffffffc02004d8:	4c81                	li	s9,0
ffffffffc02004da:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004de:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02004e2:	0186941b          	slliw	s0,a3,0x18
ffffffffc02004e6:	0186d89b          	srliw	a7,a3,0x18
ffffffffc02004ea:	01879a1b          	slliw	s4,a5,0x18
ffffffffc02004ee:	0187d81b          	srliw	a6,a5,0x18
ffffffffc02004f2:	0105151b          	slliw	a0,a0,0x10
ffffffffc02004f6:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02004fa:	0105959b          	slliw	a1,a1,0x10
ffffffffc02004fe:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200502:	8d71                	and	a0,a0,a2
ffffffffc0200504:	01146433          	or	s0,s0,a7
ffffffffc0200508:	0086969b          	slliw	a3,a3,0x8
ffffffffc020050c:	010a6a33          	or	s4,s4,a6
ffffffffc0200510:	8e6d                	and	a2,a2,a1
ffffffffc0200512:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200516:	8c49                	or	s0,s0,a0
ffffffffc0200518:	0166f6b3          	and	a3,a3,s6
ffffffffc020051c:	00ca6a33          	or	s4,s4,a2
ffffffffc0200520:	0167f7b3          	and	a5,a5,s6
ffffffffc0200524:	8c55                	or	s0,s0,a3
ffffffffc0200526:	00fa6a33          	or	s4,s4,a5
ffffffffc020052a:	1402                	slli	s0,s0,0x20
ffffffffc020052c:	1a02                	slli	s4,s4,0x20
ffffffffc020052e:	9001                	srli	s0,s0,0x20
ffffffffc0200530:	020a5a13          	srli	s4,s4,0x20
ffffffffc0200534:	943a                	add	s0,s0,a4
ffffffffc0200536:	9a3a                	add	s4,s4,a4
ffffffffc0200538:	00ff0c37          	lui	s8,0xff0
ffffffffc020053c:	4b8d                	li	s7,3
ffffffffc020053e:	00002917          	auipc	s2,0x2
ffffffffc0200542:	dfa90913          	addi	s2,s2,-518 # ffffffffc0202338 <commands+0xd0>
ffffffffc0200546:	49bd                	li	s3,15
ffffffffc0200548:	4d91                	li	s11,4
ffffffffc020054a:	4d05                	li	s10,1
ffffffffc020054c:	00002497          	auipc	s1,0x2
ffffffffc0200550:	de448493          	addi	s1,s1,-540 # ffffffffc0202330 <commands+0xc8>
ffffffffc0200554:	000a2703          	lw	a4,0(s4)
ffffffffc0200558:	004a0a93          	addi	s5,s4,4
ffffffffc020055c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200560:	0187179b          	slliw	a5,a4,0x18
ffffffffc0200564:	0187561b          	srliw	a2,a4,0x18
ffffffffc0200568:	0106969b          	slliw	a3,a3,0x10
ffffffffc020056c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200570:	8fd1                	or	a5,a5,a2
ffffffffc0200572:	0186f6b3          	and	a3,a3,s8
ffffffffc0200576:	0087171b          	slliw	a4,a4,0x8
ffffffffc020057a:	8fd5                	or	a5,a5,a3
ffffffffc020057c:	00eb7733          	and	a4,s6,a4
ffffffffc0200580:	8fd9                	or	a5,a5,a4
ffffffffc0200582:	2781                	sext.w	a5,a5
ffffffffc0200584:	09778c63          	beq	a5,s7,ffffffffc020061c <dtb_init+0x1ee>
ffffffffc0200588:	00fbea63          	bltu	s7,a5,ffffffffc020059c <dtb_init+0x16e>
ffffffffc020058c:	07a78663          	beq	a5,s10,ffffffffc02005f8 <dtb_init+0x1ca>
ffffffffc0200590:	4709                	li	a4,2
ffffffffc0200592:	00e79763          	bne	a5,a4,ffffffffc02005a0 <dtb_init+0x172>
ffffffffc0200596:	4c81                	li	s9,0
ffffffffc0200598:	8a56                	mv	s4,s5
ffffffffc020059a:	bf6d                	j	ffffffffc0200554 <dtb_init+0x126>
ffffffffc020059c:	ffb78ee3          	beq	a5,s11,ffffffffc0200598 <dtb_init+0x16a>
ffffffffc02005a0:	00002517          	auipc	a0,0x2
ffffffffc02005a4:	e1050513          	addi	a0,a0,-496 # ffffffffc02023b0 <commands+0x148>
ffffffffc02005a8:	b31ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	e3c50513          	addi	a0,a0,-452 # ffffffffc02023e8 <commands+0x180>
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
ffffffffc02005d0:	b621                	j	ffffffffc02000d8 <cprintf>
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
ffffffffc02005ec:	00002517          	auipc	a0,0x2
ffffffffc02005f0:	d1c50513          	addi	a0,a0,-740 # ffffffffc0202308 <commands+0xa0>
ffffffffc02005f4:	6109                	addi	sp,sp,128
ffffffffc02005f6:	b4cd                	j	ffffffffc02000d8 <cprintf>
ffffffffc02005f8:	8556                	mv	a0,s5
ffffffffc02005fa:	446010ef          	jal	ra,ffffffffc0201a40 <strlen>
ffffffffc02005fe:	8a2a                	mv	s4,a0
ffffffffc0200600:	4619                	li	a2,6
ffffffffc0200602:	85a6                	mv	a1,s1
ffffffffc0200604:	8556                	mv	a0,s5
ffffffffc0200606:	2a01                	sext.w	s4,s4
ffffffffc0200608:	48c010ef          	jal	ra,ffffffffc0201a94 <strncmp>
ffffffffc020060c:	e111                	bnez	a0,ffffffffc0200610 <dtb_init+0x1e2>
ffffffffc020060e:	4c85                	li	s9,1
ffffffffc0200610:	0a91                	addi	s5,s5,4
ffffffffc0200612:	9ad2                	add	s5,s5,s4
ffffffffc0200614:	ffcafa93          	andi	s5,s5,-4
ffffffffc0200618:	8a56                	mv	s4,s5
ffffffffc020061a:	bf2d                	j	ffffffffc0200554 <dtb_init+0x126>
ffffffffc020061c:	004a2783          	lw	a5,4(s4)
ffffffffc0200620:	00ca0693          	addi	a3,s4,12
ffffffffc0200624:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200628:	01879a9b          	slliw	s5,a5,0x18
ffffffffc020062c:	0187d61b          	srliw	a2,a5,0x18
ffffffffc0200630:	0107171b          	slliw	a4,a4,0x10
ffffffffc0200634:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200638:	00caeab3          	or	s5,s5,a2
ffffffffc020063c:	01877733          	and	a4,a4,s8
ffffffffc0200640:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200644:	00eaeab3          	or	s5,s5,a4
ffffffffc0200648:	00fb77b3          	and	a5,s6,a5
ffffffffc020064c:	00faeab3          	or	s5,s5,a5
ffffffffc0200650:	2a81                	sext.w	s5,s5
ffffffffc0200652:	000c9c63          	bnez	s9,ffffffffc020066a <dtb_init+0x23c>
ffffffffc0200656:	1a82                	slli	s5,s5,0x20
ffffffffc0200658:	00368793          	addi	a5,a3,3
ffffffffc020065c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200660:	9abe                	add	s5,s5,a5
ffffffffc0200662:	ffcafa93          	andi	s5,s5,-4
ffffffffc0200666:	8a56                	mv	s4,s5
ffffffffc0200668:	b5f5                	j	ffffffffc0200554 <dtb_init+0x126>
ffffffffc020066a:	008a2783          	lw	a5,8(s4)
ffffffffc020066e:	85ca                	mv	a1,s2
ffffffffc0200670:	e436                	sd	a3,8(sp)
ffffffffc0200672:	0087d51b          	srliw	a0,a5,0x8
ffffffffc0200676:	0187d61b          	srliw	a2,a5,0x18
ffffffffc020067a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020067e:	0105151b          	slliw	a0,a0,0x10
ffffffffc0200682:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200686:	8f51                	or	a4,a4,a2
ffffffffc0200688:	01857533          	and	a0,a0,s8
ffffffffc020068c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200690:	8d59                	or	a0,a0,a4
ffffffffc0200692:	00fb77b3          	and	a5,s6,a5
ffffffffc0200696:	8d5d                	or	a0,a0,a5
ffffffffc0200698:	1502                	slli	a0,a0,0x20
ffffffffc020069a:	9101                	srli	a0,a0,0x20
ffffffffc020069c:	9522                	add	a0,a0,s0
ffffffffc020069e:	3d8010ef          	jal	ra,ffffffffc0201a76 <strcmp>
ffffffffc02006a2:	66a2                	ld	a3,8(sp)
ffffffffc02006a4:	f94d                	bnez	a0,ffffffffc0200656 <dtb_init+0x228>
ffffffffc02006a6:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200656 <dtb_init+0x228>
ffffffffc02006aa:	00ca3783          	ld	a5,12(s4)
ffffffffc02006ae:	014a3703          	ld	a4,20(s4)
ffffffffc02006b2:	00002517          	auipc	a0,0x2
ffffffffc02006b6:	c8e50513          	addi	a0,a0,-882 # ffffffffc0202340 <commands+0xd8>
ffffffffc02006ba:	4207d613          	srai	a2,a5,0x20
ffffffffc02006be:	0087d31b          	srliw	t1,a5,0x8
ffffffffc02006c2:	42075593          	srai	a1,a4,0x20
ffffffffc02006c6:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02006ca:	0186581b          	srliw	a6,a2,0x18
ffffffffc02006ce:	0187941b          	slliw	s0,a5,0x18
ffffffffc02006d2:	0107d89b          	srliw	a7,a5,0x10
ffffffffc02006d6:	0187d693          	srli	a3,a5,0x18
ffffffffc02006da:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02006de:	0087579b          	srliw	a5,a4,0x8
ffffffffc02006e2:	0103131b          	slliw	t1,t1,0x10
ffffffffc02006e6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02006ea:	010f6f33          	or	t5,t5,a6
ffffffffc02006ee:	0187529b          	srliw	t0,a4,0x18
ffffffffc02006f2:	0185df9b          	srliw	t6,a1,0x18
ffffffffc02006f6:	01837333          	and	t1,t1,s8
ffffffffc02006fa:	01c46433          	or	s0,s0,t3
ffffffffc02006fe:	0186f6b3          	and	a3,a3,s8
ffffffffc0200702:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200706:	01871e9b          	slliw	t4,a4,0x18
ffffffffc020070a:	0107581b          	srliw	a6,a4,0x10
ffffffffc020070e:	0086161b          	slliw	a2,a2,0x8
ffffffffc0200712:	8361                	srli	a4,a4,0x18
ffffffffc0200714:	0107979b          	slliw	a5,a5,0x10
ffffffffc0200718:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020071c:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200720:	00cb7633          	and	a2,s6,a2
ffffffffc0200724:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200728:	0085959b          	slliw	a1,a1,0x8
ffffffffc020072c:	00646433          	or	s0,s0,t1
ffffffffc0200730:	0187f7b3          	and	a5,a5,s8
ffffffffc0200734:	01fe6333          	or	t1,t3,t6
ffffffffc0200738:	01877c33          	and	s8,a4,s8
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
ffffffffc0200766:	1702                	slli	a4,a4,0x20
ffffffffc0200768:	1b02                	slli	s6,s6,0x20
ffffffffc020076a:	1782                	slli	a5,a5,0x20
ffffffffc020076c:	9301                	srli	a4,a4,0x20
ffffffffc020076e:	1402                	slli	s0,s0,0x20
ffffffffc0200770:	020b5b13          	srli	s6,s6,0x20
ffffffffc0200774:	0167eb33          	or	s6,a5,s6
ffffffffc0200778:	8c59                	or	s0,s0,a4
ffffffffc020077a:	95fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020077e:	85a2                	mv	a1,s0
ffffffffc0200780:	00002517          	auipc	a0,0x2
ffffffffc0200784:	be050513          	addi	a0,a0,-1056 # ffffffffc0202360 <commands+0xf8>
ffffffffc0200788:	951ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020078c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200790:	85da                	mv	a1,s6
ffffffffc0200792:	00002517          	auipc	a0,0x2
ffffffffc0200796:	be650513          	addi	a0,a0,-1050 # ffffffffc0202378 <commands+0x110>
ffffffffc020079a:	93fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020079e:	008b05b3          	add	a1,s6,s0
ffffffffc02007a2:	15fd                	addi	a1,a1,-1
ffffffffc02007a4:	00002517          	auipc	a0,0x2
ffffffffc02007a8:	bf450513          	addi	a0,a0,-1036 # ffffffffc0202398 <commands+0x130>
ffffffffc02007ac:	92dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02007b0:	00002517          	auipc	a0,0x2
ffffffffc02007b4:	c3850513          	addi	a0,a0,-968 # ffffffffc02023e8 <commands+0x180>
ffffffffc02007b8:	00007797          	auipc	a5,0x7
ffffffffc02007bc:	c887b823          	sd	s0,-880(a5) # ffffffffc0207448 <memory_base>
ffffffffc02007c0:	00007797          	auipc	a5,0x7
ffffffffc02007c4:	c967b823          	sd	s6,-880(a5) # ffffffffc0207450 <memory_size>
ffffffffc02007c8:	b3f5                	j	ffffffffc02005b4 <dtb_init+0x186>

ffffffffc02007ca <get_memory_base>:
ffffffffc02007ca:	00007517          	auipc	a0,0x7
ffffffffc02007ce:	c7e53503          	ld	a0,-898(a0) # ffffffffc0207448 <memory_base>
ffffffffc02007d2:	8082                	ret

ffffffffc02007d4 <get_memory_size>:
ffffffffc02007d4:	00007517          	auipc	a0,0x7
ffffffffc02007d8:	c7c53503          	ld	a0,-900(a0) # ffffffffc0207450 <memory_size>
ffffffffc02007dc:	8082                	ret

ffffffffc02007de <clock_init>:
ffffffffc02007de:	1141                	addi	sp,sp,-16
ffffffffc02007e0:	e406                	sd	ra,8(sp)
ffffffffc02007e2:	02000793          	li	a5,32
ffffffffc02007e6:	1047a7f3          	csrrs	a5,sie,a5
ffffffffc02007ea:	c0102573          	rdtime	a0
ffffffffc02007ee:	67e1                	lui	a5,0x18
ffffffffc02007f0:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02007f4:	953e                	add	a0,a0,a5
ffffffffc02007f6:	7a8010ef          	jal	ra,ffffffffc0201f9e <sbi_set_timer>
ffffffffc02007fa:	60a2                	ld	ra,8(sp)
ffffffffc02007fc:	00007797          	auipc	a5,0x7
ffffffffc0200800:	c407be23          	sd	zero,-932(a5) # ffffffffc0207458 <ticks>
ffffffffc0200804:	00002517          	auipc	a0,0x2
ffffffffc0200808:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0202400 <commands+0x198>
ffffffffc020080c:	0141                	addi	sp,sp,16
ffffffffc020080e:	8cbff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200812 <clock_set_next_event>:
ffffffffc0200812:	c0102573          	rdtime	a0
ffffffffc0200816:	67e1                	lui	a5,0x18
ffffffffc0200818:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020081c:	953e                	add	a0,a0,a5
ffffffffc020081e:	7800106f          	j	ffffffffc0201f9e <sbi_set_timer>

ffffffffc0200822 <cons_init>:
ffffffffc0200822:	8082                	ret

ffffffffc0200824 <cons_putc>:
ffffffffc0200824:	0ff57513          	zext.b	a0,a0
ffffffffc0200828:	75c0106f          	j	ffffffffc0201f84 <sbi_console_putchar>

ffffffffc020082c <cons_getc>:
ffffffffc020082c:	78c0106f          	j	ffffffffc0201fb8 <sbi_console_getchar>

ffffffffc0200830 <intr_enable>:
ffffffffc0200830:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200834:	8082                	ret

ffffffffc0200836 <intr_disable>:
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
ffffffffc020085a:	bca50513          	addi	a0,a0,-1078 # ffffffffc0202420 <commands+0x1b8>
void print_regs(struct pushregs *gpr) {
ffffffffc020085e:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200860:	879ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200864:	640c                	ld	a1,8(s0)
ffffffffc0200866:	00002517          	auipc	a0,0x2
ffffffffc020086a:	bd250513          	addi	a0,a0,-1070 # ffffffffc0202438 <commands+0x1d0>
ffffffffc020086e:	86bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200872:	680c                	ld	a1,16(s0)
ffffffffc0200874:	00002517          	auipc	a0,0x2
ffffffffc0200878:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0202450 <commands+0x1e8>
ffffffffc020087c:	85dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200880:	6c0c                	ld	a1,24(s0)
ffffffffc0200882:	00002517          	auipc	a0,0x2
ffffffffc0200886:	be650513          	addi	a0,a0,-1050 # ffffffffc0202468 <commands+0x200>
ffffffffc020088a:	84fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020088e:	700c                	ld	a1,32(s0)
ffffffffc0200890:	00002517          	auipc	a0,0x2
ffffffffc0200894:	bf050513          	addi	a0,a0,-1040 # ffffffffc0202480 <commands+0x218>
ffffffffc0200898:	841ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020089c:	740c                	ld	a1,40(s0)
ffffffffc020089e:	00002517          	auipc	a0,0x2
ffffffffc02008a2:	bfa50513          	addi	a0,a0,-1030 # ffffffffc0202498 <commands+0x230>
ffffffffc02008a6:	833ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008aa:	780c                	ld	a1,48(s0)
ffffffffc02008ac:	00002517          	auipc	a0,0x2
ffffffffc02008b0:	c0450513          	addi	a0,a0,-1020 # ffffffffc02024b0 <commands+0x248>
ffffffffc02008b4:	825ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008b8:	7c0c                	ld	a1,56(s0)
ffffffffc02008ba:	00002517          	auipc	a0,0x2
ffffffffc02008be:	c0e50513          	addi	a0,a0,-1010 # ffffffffc02024c8 <commands+0x260>
ffffffffc02008c2:	817ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008c6:	602c                	ld	a1,64(s0)
ffffffffc02008c8:	00002517          	auipc	a0,0x2
ffffffffc02008cc:	c1850513          	addi	a0,a0,-1000 # ffffffffc02024e0 <commands+0x278>
ffffffffc02008d0:	809ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008d4:	642c                	ld	a1,72(s0)
ffffffffc02008d6:	00002517          	auipc	a0,0x2
ffffffffc02008da:	c2250513          	addi	a0,a0,-990 # ffffffffc02024f8 <commands+0x290>
ffffffffc02008de:	ffaff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008e2:	682c                	ld	a1,80(s0)
ffffffffc02008e4:	00002517          	auipc	a0,0x2
ffffffffc02008e8:	c2c50513          	addi	a0,a0,-980 # ffffffffc0202510 <commands+0x2a8>
ffffffffc02008ec:	fecff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008f0:	6c2c                	ld	a1,88(s0)
ffffffffc02008f2:	00002517          	auipc	a0,0x2
ffffffffc02008f6:	c3650513          	addi	a0,a0,-970 # ffffffffc0202528 <commands+0x2c0>
ffffffffc02008fa:	fdeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008fe:	702c                	ld	a1,96(s0)
ffffffffc0200900:	00002517          	auipc	a0,0x2
ffffffffc0200904:	c4050513          	addi	a0,a0,-960 # ffffffffc0202540 <commands+0x2d8>
ffffffffc0200908:	fd0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020090c:	742c                	ld	a1,104(s0)
ffffffffc020090e:	00002517          	auipc	a0,0x2
ffffffffc0200912:	c4a50513          	addi	a0,a0,-950 # ffffffffc0202558 <commands+0x2f0>
ffffffffc0200916:	fc2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020091a:	782c                	ld	a1,112(s0)
ffffffffc020091c:	00002517          	auipc	a0,0x2
ffffffffc0200920:	c5450513          	addi	a0,a0,-940 # ffffffffc0202570 <commands+0x308>
ffffffffc0200924:	fb4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200928:	7c2c                	ld	a1,120(s0)
ffffffffc020092a:	00002517          	auipc	a0,0x2
ffffffffc020092e:	c5e50513          	addi	a0,a0,-930 # ffffffffc0202588 <commands+0x320>
ffffffffc0200932:	fa6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200936:	604c                	ld	a1,128(s0)
ffffffffc0200938:	00002517          	auipc	a0,0x2
ffffffffc020093c:	c6850513          	addi	a0,a0,-920 # ffffffffc02025a0 <commands+0x338>
ffffffffc0200940:	f98ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200944:	644c                	ld	a1,136(s0)
ffffffffc0200946:	00002517          	auipc	a0,0x2
ffffffffc020094a:	c7250513          	addi	a0,a0,-910 # ffffffffc02025b8 <commands+0x350>
ffffffffc020094e:	f8aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200952:	684c                	ld	a1,144(s0)
ffffffffc0200954:	00002517          	auipc	a0,0x2
ffffffffc0200958:	c7c50513          	addi	a0,a0,-900 # ffffffffc02025d0 <commands+0x368>
ffffffffc020095c:	f7cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200960:	6c4c                	ld	a1,152(s0)
ffffffffc0200962:	00002517          	auipc	a0,0x2
ffffffffc0200966:	c8650513          	addi	a0,a0,-890 # ffffffffc02025e8 <commands+0x380>
ffffffffc020096a:	f6eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020096e:	704c                	ld	a1,160(s0)
ffffffffc0200970:	00002517          	auipc	a0,0x2
ffffffffc0200974:	c9050513          	addi	a0,a0,-880 # ffffffffc0202600 <commands+0x398>
ffffffffc0200978:	f60ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020097c:	744c                	ld	a1,168(s0)
ffffffffc020097e:	00002517          	auipc	a0,0x2
ffffffffc0200982:	c9a50513          	addi	a0,a0,-870 # ffffffffc0202618 <commands+0x3b0>
ffffffffc0200986:	f52ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc020098a:	784c                	ld	a1,176(s0)
ffffffffc020098c:	00002517          	auipc	a0,0x2
ffffffffc0200990:	ca450513          	addi	a0,a0,-860 # ffffffffc0202630 <commands+0x3c8>
ffffffffc0200994:	f44ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200998:	7c4c                	ld	a1,184(s0)
ffffffffc020099a:	00002517          	auipc	a0,0x2
ffffffffc020099e:	cae50513          	addi	a0,a0,-850 # ffffffffc0202648 <commands+0x3e0>
ffffffffc02009a2:	f36ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009a6:	606c                	ld	a1,192(s0)
ffffffffc02009a8:	00002517          	auipc	a0,0x2
ffffffffc02009ac:	cb850513          	addi	a0,a0,-840 # ffffffffc0202660 <commands+0x3f8>
ffffffffc02009b0:	f28ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009b4:	646c                	ld	a1,200(s0)
ffffffffc02009b6:	00002517          	auipc	a0,0x2
ffffffffc02009ba:	cc250513          	addi	a0,a0,-830 # ffffffffc0202678 <commands+0x410>
ffffffffc02009be:	f1aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009c2:	686c                	ld	a1,208(s0)
ffffffffc02009c4:	00002517          	auipc	a0,0x2
ffffffffc02009c8:	ccc50513          	addi	a0,a0,-820 # ffffffffc0202690 <commands+0x428>
ffffffffc02009cc:	f0cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009d0:	6c6c                	ld	a1,216(s0)
ffffffffc02009d2:	00002517          	auipc	a0,0x2
ffffffffc02009d6:	cd650513          	addi	a0,a0,-810 # ffffffffc02026a8 <commands+0x440>
ffffffffc02009da:	efeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009de:	706c                	ld	a1,224(s0)
ffffffffc02009e0:	00002517          	auipc	a0,0x2
ffffffffc02009e4:	ce050513          	addi	a0,a0,-800 # ffffffffc02026c0 <commands+0x458>
ffffffffc02009e8:	ef0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009ec:	746c                	ld	a1,232(s0)
ffffffffc02009ee:	00002517          	auipc	a0,0x2
ffffffffc02009f2:	cea50513          	addi	a0,a0,-790 # ffffffffc02026d8 <commands+0x470>
ffffffffc02009f6:	ee2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009fa:	786c                	ld	a1,240(s0)
ffffffffc02009fc:	00002517          	auipc	a0,0x2
ffffffffc0200a00:	cf450513          	addi	a0,a0,-780 # ffffffffc02026f0 <commands+0x488>
ffffffffc0200a04:	ed4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a08:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a0a:	6402                	ld	s0,0(sp)
ffffffffc0200a0c:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a0e:	00002517          	auipc	a0,0x2
ffffffffc0200a12:	cfa50513          	addi	a0,a0,-774 # ffffffffc0202708 <commands+0x4a0>
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
ffffffffc0200a28:	cfc50513          	addi	a0,a0,-772 # ffffffffc0202720 <commands+0x4b8>
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
ffffffffc0200a40:	cfc50513          	addi	a0,a0,-772 # ffffffffc0202738 <commands+0x4d0>
ffffffffc0200a44:	e94ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a48:	10843583          	ld	a1,264(s0)
ffffffffc0200a4c:	00002517          	auipc	a0,0x2
ffffffffc0200a50:	d0450513          	addi	a0,a0,-764 # ffffffffc0202750 <commands+0x4e8>
ffffffffc0200a54:	e84ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a58:	11043583          	ld	a1,272(s0)
ffffffffc0200a5c:	00002517          	auipc	a0,0x2
ffffffffc0200a60:	d0c50513          	addi	a0,a0,-756 # ffffffffc0202768 <commands+0x500>
ffffffffc0200a64:	e74ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a68:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a6c:	6402                	ld	s0,0(sp)
ffffffffc0200a6e:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a70:	00002517          	auipc	a0,0x2
ffffffffc0200a74:	d1050513          	addi	a0,a0,-752 # ffffffffc0202780 <commands+0x518>
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
ffffffffc0200a90:	df470713          	addi	a4,a4,-524 # ffffffffc0202880 <commands+0x618>
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
ffffffffc0200aa2:	d5a50513          	addi	a0,a0,-678 # ffffffffc02027f8 <commands+0x590>
ffffffffc0200aa6:	e32ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200aaa:	00002517          	auipc	a0,0x2
ffffffffc0200aae:	d2e50513          	addi	a0,a0,-722 # ffffffffc02027d8 <commands+0x570>
ffffffffc0200ab2:	e26ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200ab6:	00002517          	auipc	a0,0x2
ffffffffc0200aba:	ce250513          	addi	a0,a0,-798 # ffffffffc0202798 <commands+0x530>
ffffffffc0200abe:	e1aff06f          	j	ffffffffc02000d8 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200ac2:	00002517          	auipc	a0,0x2
ffffffffc0200ac6:	d5650513          	addi	a0,a0,-682 # ffffffffc0202818 <commands+0x5b0>
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
ffffffffc0200ad8:	00007697          	auipc	a3,0x7
ffffffffc0200adc:	98068693          	addi	a3,a3,-1664 # ffffffffc0207458 <ticks>
ffffffffc0200ae0:	629c                	ld	a5,0(a3)
ffffffffc0200ae2:	06400713          	li	a4,100
ffffffffc0200ae6:	00007417          	auipc	s0,0x7
ffffffffc0200aea:	97a40413          	addi	s0,s0,-1670 # ffffffffc0207460 <print_num>
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
ffffffffc0200b0c:	d5850513          	addi	a0,a0,-680 # ffffffffc0202860 <commands+0x5f8>
ffffffffc0200b10:	dc8ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200b14:	00002517          	auipc	a0,0x2
ffffffffc0200b18:	ca450513          	addi	a0,a0,-860 # ffffffffc02027b8 <commands+0x550>
ffffffffc0200b1c:	dbcff06f          	j	ffffffffc02000d8 <cprintf>
            print_trapframe(tf);
ffffffffc0200b20:	bdf5                	j	ffffffffc0200a1c <print_trapframe>
              print_num++;
ffffffffc0200b22:	401c                	lw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b24:	06400593          	li	a1,100
ffffffffc0200b28:	00002517          	auipc	a0,0x2
ffffffffc0200b2c:	d0850513          	addi	a0,a0,-760 # ffffffffc0202830 <commands+0x5c8>
              print_num++;
ffffffffc0200b30:	2785                	addiw	a5,a5,1
ffffffffc0200b32:	c01c                	sw	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b34:	da4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
}
ffffffffc0200b38:	b7c1                	j	ffffffffc0200af8 <interrupt_handler+0x7a>
              cprintf("Calling SBI shutdown...\n");
ffffffffc0200b3a:	00002517          	auipc	a0,0x2
ffffffffc0200b3e:	d0650513          	addi	a0,a0,-762 # ffffffffc0202840 <commands+0x5d8>
ffffffffc0200b42:	d96ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
}
ffffffffc0200b46:	6402                	ld	s0,0(sp)
ffffffffc0200b48:	60a2                	ld	ra,8(sp)
ffffffffc0200b4a:	0141                	addi	sp,sp,16
              sbi_shutdown();
ffffffffc0200b4c:	4880106f          	j	ffffffffc0201fd4 <sbi_shutdown>

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
ffffffffc0200b76:	d3e50513          	addi	a0,a0,-706 # ffffffffc02028b0 <commands+0x648>
ffffffffc0200b7a:	d5eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
                uintptr_t ep = tf->epc;
ffffffffc0200b7e:	1084b983          	ld	s3,264(s1)
                cprintf("Illegal instruction caught at 0x%08x\n", (unsigned)ep);
ffffffffc0200b82:	00002517          	auipc	a0,0x2
ffffffffc0200b86:	d5650513          	addi	a0,a0,-682 # ffffffffc02028d8 <commands+0x670>
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
ffffffffc0200bca:	d3a50513          	addi	a0,a0,-710 # ffffffffc0202900 <commands+0x698>
ffffffffc0200bce:	d0aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
                uintptr_t ep = tf->epc;
ffffffffc0200bd2:	1084b903          	ld	s2,264(s1)
                cprintf("ebreak caught at 0x%08x\n", (unsigned)ep);
ffffffffc0200bd6:	00002517          	auipc	a0,0x2
ffffffffc0200bda:	d4a50513          	addi	a0,a0,-694 # ffffffffc0202920 <commands+0x6b8>
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
ffffffffc0200c7e:	850a                	mv	a0,sp
ffffffffc0200c80:	f8fff0ef          	jal	ra,ffffffffc0200c0e <trap>

ffffffffc0200c84 <__trapret>:
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
ffffffffc0200cce:	10200073          	sret

ffffffffc0200cd2 <alloc_pages>:
ffffffffc0200cd2:	100027f3          	csrr	a5,sstatus
ffffffffc0200cd6:	8b89                	andi	a5,a5,2
ffffffffc0200cd8:	e799                	bnez	a5,ffffffffc0200ce6 <alloc_pages+0x14>
ffffffffc0200cda:	00006797          	auipc	a5,0x6
ffffffffc0200cde:	79e7b783          	ld	a5,1950(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0200ce2:	6f9c                	ld	a5,24(a5)
ffffffffc0200ce4:	8782                	jr	a5
ffffffffc0200ce6:	1141                	addi	sp,sp,-16
ffffffffc0200ce8:	e406                	sd	ra,8(sp)
ffffffffc0200cea:	e022                	sd	s0,0(sp)
ffffffffc0200cec:	842a                	mv	s0,a0
ffffffffc0200cee:	b49ff0ef          	jal	ra,ffffffffc0200836 <intr_disable>
ffffffffc0200cf2:	00006797          	auipc	a5,0x6
ffffffffc0200cf6:	7867b783          	ld	a5,1926(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0200cfa:	6f9c                	ld	a5,24(a5)
ffffffffc0200cfc:	8522                	mv	a0,s0
ffffffffc0200cfe:	9782                	jalr	a5
ffffffffc0200d00:	842a                	mv	s0,a0
ffffffffc0200d02:	b2fff0ef          	jal	ra,ffffffffc0200830 <intr_enable>
ffffffffc0200d06:	60a2                	ld	ra,8(sp)
ffffffffc0200d08:	8522                	mv	a0,s0
ffffffffc0200d0a:	6402                	ld	s0,0(sp)
ffffffffc0200d0c:	0141                	addi	sp,sp,16
ffffffffc0200d0e:	8082                	ret

ffffffffc0200d10 <free_pages>:
ffffffffc0200d10:	100027f3          	csrr	a5,sstatus
ffffffffc0200d14:	8b89                	andi	a5,a5,2
ffffffffc0200d16:	e799                	bnez	a5,ffffffffc0200d24 <free_pages+0x14>
ffffffffc0200d18:	00006797          	auipc	a5,0x6
ffffffffc0200d1c:	7607b783          	ld	a5,1888(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0200d20:	739c                	ld	a5,32(a5)
ffffffffc0200d22:	8782                	jr	a5
ffffffffc0200d24:	1101                	addi	sp,sp,-32
ffffffffc0200d26:	ec06                	sd	ra,24(sp)
ffffffffc0200d28:	e822                	sd	s0,16(sp)
ffffffffc0200d2a:	e426                	sd	s1,8(sp)
ffffffffc0200d2c:	842a                	mv	s0,a0
ffffffffc0200d2e:	84ae                	mv	s1,a1
ffffffffc0200d30:	b07ff0ef          	jal	ra,ffffffffc0200836 <intr_disable>
ffffffffc0200d34:	00006797          	auipc	a5,0x6
ffffffffc0200d38:	7447b783          	ld	a5,1860(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0200d3c:	739c                	ld	a5,32(a5)
ffffffffc0200d3e:	85a6                	mv	a1,s1
ffffffffc0200d40:	8522                	mv	a0,s0
ffffffffc0200d42:	9782                	jalr	a5
ffffffffc0200d44:	6442                	ld	s0,16(sp)
ffffffffc0200d46:	60e2                	ld	ra,24(sp)
ffffffffc0200d48:	64a2                	ld	s1,8(sp)
ffffffffc0200d4a:	6105                	addi	sp,sp,32
ffffffffc0200d4c:	b4d5                	j	ffffffffc0200830 <intr_enable>

ffffffffc0200d4e <nr_free_pages>:
ffffffffc0200d4e:	100027f3          	csrr	a5,sstatus
ffffffffc0200d52:	8b89                	andi	a5,a5,2
ffffffffc0200d54:	e799                	bnez	a5,ffffffffc0200d62 <nr_free_pages+0x14>
ffffffffc0200d56:	00006797          	auipc	a5,0x6
ffffffffc0200d5a:	7227b783          	ld	a5,1826(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0200d5e:	779c                	ld	a5,40(a5)
ffffffffc0200d60:	8782                	jr	a5
ffffffffc0200d62:	1141                	addi	sp,sp,-16
ffffffffc0200d64:	e406                	sd	ra,8(sp)
ffffffffc0200d66:	e022                	sd	s0,0(sp)
ffffffffc0200d68:	acfff0ef          	jal	ra,ffffffffc0200836 <intr_disable>
ffffffffc0200d6c:	00006797          	auipc	a5,0x6
ffffffffc0200d70:	70c7b783          	ld	a5,1804(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0200d74:	779c                	ld	a5,40(a5)
ffffffffc0200d76:	9782                	jalr	a5
ffffffffc0200d78:	842a                	mv	s0,a0
ffffffffc0200d7a:	ab7ff0ef          	jal	ra,ffffffffc0200830 <intr_enable>
ffffffffc0200d7e:	60a2                	ld	ra,8(sp)
ffffffffc0200d80:	8522                	mv	a0,s0
ffffffffc0200d82:	6402                	ld	s0,0(sp)
ffffffffc0200d84:	0141                	addi	sp,sp,16
ffffffffc0200d86:	8082                	ret

ffffffffc0200d88 <pmm_init>:
ffffffffc0200d88:	00002797          	auipc	a5,0x2
ffffffffc0200d8c:	0c078793          	addi	a5,a5,192 # ffffffffc0202e48 <default_pmm_manager>
ffffffffc0200d90:	638c                	ld	a1,0(a5)
ffffffffc0200d92:	7179                	addi	sp,sp,-48
ffffffffc0200d94:	f022                	sd	s0,32(sp)
ffffffffc0200d96:	00002517          	auipc	a0,0x2
ffffffffc0200d9a:	baa50513          	addi	a0,a0,-1110 # ffffffffc0202940 <commands+0x6d8>
ffffffffc0200d9e:	00006417          	auipc	s0,0x6
ffffffffc0200da2:	6da40413          	addi	s0,s0,1754 # ffffffffc0207478 <pmm_manager>
ffffffffc0200da6:	f406                	sd	ra,40(sp)
ffffffffc0200da8:	ec26                	sd	s1,24(sp)
ffffffffc0200daa:	e44e                	sd	s3,8(sp)
ffffffffc0200dac:	e84a                	sd	s2,16(sp)
ffffffffc0200dae:	e052                	sd	s4,0(sp)
ffffffffc0200db0:	e01c                	sd	a5,0(s0)
ffffffffc0200db2:	b26ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200db6:	601c                	ld	a5,0(s0)
ffffffffc0200db8:	00006497          	auipc	s1,0x6
ffffffffc0200dbc:	6d848493          	addi	s1,s1,1752 # ffffffffc0207490 <va_pa_offset>
ffffffffc0200dc0:	679c                	ld	a5,8(a5)
ffffffffc0200dc2:	9782                	jalr	a5
ffffffffc0200dc4:	57f5                	li	a5,-3
ffffffffc0200dc6:	07fa                	slli	a5,a5,0x1e
ffffffffc0200dc8:	e09c                	sd	a5,0(s1)
ffffffffc0200dca:	a01ff0ef          	jal	ra,ffffffffc02007ca <get_memory_base>
ffffffffc0200dce:	89aa                	mv	s3,a0
ffffffffc0200dd0:	a05ff0ef          	jal	ra,ffffffffc02007d4 <get_memory_size>
ffffffffc0200dd4:	16050163          	beqz	a0,ffffffffc0200f36 <pmm_init+0x1ae>
ffffffffc0200dd8:	892a                	mv	s2,a0
ffffffffc0200dda:	00002517          	auipc	a0,0x2
ffffffffc0200dde:	bae50513          	addi	a0,a0,-1106 # ffffffffc0202988 <commands+0x720>
ffffffffc0200de2:	af6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200de6:	01298a33          	add	s4,s3,s2
ffffffffc0200dea:	864e                	mv	a2,s3
ffffffffc0200dec:	fffa0693          	addi	a3,s4,-1
ffffffffc0200df0:	85ca                	mv	a1,s2
ffffffffc0200df2:	00002517          	auipc	a0,0x2
ffffffffc0200df6:	bae50513          	addi	a0,a0,-1106 # ffffffffc02029a0 <commands+0x738>
ffffffffc0200dfa:	adeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200dfe:	c80007b7          	lui	a5,0xc8000
ffffffffc0200e02:	8652                	mv	a2,s4
ffffffffc0200e04:	0d47e863          	bltu	a5,s4,ffffffffc0200ed4 <pmm_init+0x14c>
ffffffffc0200e08:	00007797          	auipc	a5,0x7
ffffffffc0200e0c:	69778793          	addi	a5,a5,1687 # ffffffffc020849f <end+0xfff>
ffffffffc0200e10:	757d                	lui	a0,0xfffff
ffffffffc0200e12:	8d7d                	and	a0,a0,a5
ffffffffc0200e14:	8231                	srli	a2,a2,0xc
ffffffffc0200e16:	00006597          	auipc	a1,0x6
ffffffffc0200e1a:	65258593          	addi	a1,a1,1618 # ffffffffc0207468 <npage>
ffffffffc0200e1e:	00006817          	auipc	a6,0x6
ffffffffc0200e22:	65280813          	addi	a6,a6,1618 # ffffffffc0207470 <pages>
ffffffffc0200e26:	e190                	sd	a2,0(a1)
ffffffffc0200e28:	00a83023          	sd	a0,0(a6)
ffffffffc0200e2c:	000807b7          	lui	a5,0x80
ffffffffc0200e30:	02f60663          	beq	a2,a5,ffffffffc0200e5c <pmm_init+0xd4>
ffffffffc0200e34:	4701                	li	a4,0
ffffffffc0200e36:	4781                	li	a5,0
ffffffffc0200e38:	4305                	li	t1,1
ffffffffc0200e3a:	fff808b7          	lui	a7,0xfff80
ffffffffc0200e3e:	953a                	add	a0,a0,a4
ffffffffc0200e40:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf7b68>
ffffffffc0200e44:	4066b02f          	amoor.d	zero,t1,(a3)
ffffffffc0200e48:	6190                	ld	a2,0(a1)
ffffffffc0200e4a:	0785                	addi	a5,a5,1
ffffffffc0200e4c:	00083503          	ld	a0,0(a6)
ffffffffc0200e50:	011606b3          	add	a3,a2,a7
ffffffffc0200e54:	02870713          	addi	a4,a4,40
ffffffffc0200e58:	fed7e3e3          	bltu	a5,a3,ffffffffc0200e3e <pmm_init+0xb6>
ffffffffc0200e5c:	00261693          	slli	a3,a2,0x2
ffffffffc0200e60:	96b2                	add	a3,a3,a2
ffffffffc0200e62:	fec007b7          	lui	a5,0xfec00
ffffffffc0200e66:	97aa                	add	a5,a5,a0
ffffffffc0200e68:	068e                	slli	a3,a3,0x3
ffffffffc0200e6a:	96be                	add	a3,a3,a5
ffffffffc0200e6c:	c02007b7          	lui	a5,0xc0200
ffffffffc0200e70:	0af6e763          	bltu	a3,a5,ffffffffc0200f1e <pmm_init+0x196>
ffffffffc0200e74:	6098                	ld	a4,0(s1)
ffffffffc0200e76:	77fd                	lui	a5,0xfffff
ffffffffc0200e78:	00fa75b3          	and	a1,s4,a5
ffffffffc0200e7c:	8e99                	sub	a3,a3,a4
ffffffffc0200e7e:	04b6ee63          	bltu	a3,a1,ffffffffc0200eda <pmm_init+0x152>
ffffffffc0200e82:	601c                	ld	a5,0(s0)
ffffffffc0200e84:	7b9c                	ld	a5,48(a5)
ffffffffc0200e86:	9782                	jalr	a5
ffffffffc0200e88:	00002517          	auipc	a0,0x2
ffffffffc0200e8c:	ba050513          	addi	a0,a0,-1120 # ffffffffc0202a28 <commands+0x7c0>
ffffffffc0200e90:	a48ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200e94:	00005597          	auipc	a1,0x5
ffffffffc0200e98:	16c58593          	addi	a1,a1,364 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0200e9c:	00006797          	auipc	a5,0x6
ffffffffc0200ea0:	5eb7b623          	sd	a1,1516(a5) # ffffffffc0207488 <satp_virtual>
ffffffffc0200ea4:	c02007b7          	lui	a5,0xc0200
ffffffffc0200ea8:	0af5e363          	bltu	a1,a5,ffffffffc0200f4e <pmm_init+0x1c6>
ffffffffc0200eac:	6090                	ld	a2,0(s1)
ffffffffc0200eae:	7402                	ld	s0,32(sp)
ffffffffc0200eb0:	70a2                	ld	ra,40(sp)
ffffffffc0200eb2:	64e2                	ld	s1,24(sp)
ffffffffc0200eb4:	6942                	ld	s2,16(sp)
ffffffffc0200eb6:	69a2                	ld	s3,8(sp)
ffffffffc0200eb8:	6a02                	ld	s4,0(sp)
ffffffffc0200eba:	40c58633          	sub	a2,a1,a2
ffffffffc0200ebe:	00006797          	auipc	a5,0x6
ffffffffc0200ec2:	5cc7b123          	sd	a2,1474(a5) # ffffffffc0207480 <satp_physical>
ffffffffc0200ec6:	00002517          	auipc	a0,0x2
ffffffffc0200eca:	b8250513          	addi	a0,a0,-1150 # ffffffffc0202a48 <commands+0x7e0>
ffffffffc0200ece:	6145                	addi	sp,sp,48
ffffffffc0200ed0:	a08ff06f          	j	ffffffffc02000d8 <cprintf>
ffffffffc0200ed4:	c8000637          	lui	a2,0xc8000
ffffffffc0200ed8:	bf05                	j	ffffffffc0200e08 <pmm_init+0x80>
ffffffffc0200eda:	6705                	lui	a4,0x1
ffffffffc0200edc:	177d                	addi	a4,a4,-1
ffffffffc0200ede:	96ba                	add	a3,a3,a4
ffffffffc0200ee0:	8efd                	and	a3,a3,a5
ffffffffc0200ee2:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200ee6:	02c7f063          	bgeu	a5,a2,ffffffffc0200f06 <pmm_init+0x17e>
ffffffffc0200eea:	6010                	ld	a2,0(s0)
ffffffffc0200eec:	fff80737          	lui	a4,0xfff80
ffffffffc0200ef0:	973e                	add	a4,a4,a5
ffffffffc0200ef2:	00271793          	slli	a5,a4,0x2
ffffffffc0200ef6:	97ba                	add	a5,a5,a4
ffffffffc0200ef8:	6a18                	ld	a4,16(a2)
ffffffffc0200efa:	8d95                	sub	a1,a1,a3
ffffffffc0200efc:	078e                	slli	a5,a5,0x3
ffffffffc0200efe:	81b1                	srli	a1,a1,0xc
ffffffffc0200f00:	953e                	add	a0,a0,a5
ffffffffc0200f02:	9702                	jalr	a4
ffffffffc0200f04:	bfbd                	j	ffffffffc0200e82 <pmm_init+0xfa>
ffffffffc0200f06:	00002617          	auipc	a2,0x2
ffffffffc0200f0a:	af260613          	addi	a2,a2,-1294 # ffffffffc02029f8 <commands+0x790>
ffffffffc0200f0e:	06b00593          	li	a1,107
ffffffffc0200f12:	00002517          	auipc	a0,0x2
ffffffffc0200f16:	b0650513          	addi	a0,a0,-1274 # ffffffffc0202a18 <commands+0x7b0>
ffffffffc0200f1a:	a46ff0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc0200f1e:	00002617          	auipc	a2,0x2
ffffffffc0200f22:	ab260613          	addi	a2,a2,-1358 # ffffffffc02029d0 <commands+0x768>
ffffffffc0200f26:	07100593          	li	a1,113
ffffffffc0200f2a:	00002517          	auipc	a0,0x2
ffffffffc0200f2e:	a4e50513          	addi	a0,a0,-1458 # ffffffffc0202978 <commands+0x710>
ffffffffc0200f32:	a2eff0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc0200f36:	00002617          	auipc	a2,0x2
ffffffffc0200f3a:	a2260613          	addi	a2,a2,-1502 # ffffffffc0202958 <commands+0x6f0>
ffffffffc0200f3e:	05a00593          	li	a1,90
ffffffffc0200f42:	00002517          	auipc	a0,0x2
ffffffffc0200f46:	a3650513          	addi	a0,a0,-1482 # ffffffffc0202978 <commands+0x710>
ffffffffc0200f4a:	a16ff0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc0200f4e:	86ae                	mv	a3,a1
ffffffffc0200f50:	00002617          	auipc	a2,0x2
ffffffffc0200f54:	a8060613          	addi	a2,a2,-1408 # ffffffffc02029d0 <commands+0x768>
ffffffffc0200f58:	08c00593          	li	a1,140
ffffffffc0200f5c:	00002517          	auipc	a0,0x2
ffffffffc0200f60:	a1c50513          	addi	a0,a0,-1508 # ffffffffc0202978 <commands+0x710>
ffffffffc0200f64:	9fcff0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0200f68 <default_init>:
ffffffffc0200f68:	00006797          	auipc	a5,0x6
ffffffffc0200f6c:	0c078793          	addi	a5,a5,192 # ffffffffc0207028 <free_area>
ffffffffc0200f70:	e79c                	sd	a5,8(a5)
ffffffffc0200f72:	e39c                	sd	a5,0(a5)
ffffffffc0200f74:	0007a823          	sw	zero,16(a5)
ffffffffc0200f78:	8082                	ret

ffffffffc0200f7a <default_nr_free_pages>:
ffffffffc0200f7a:	00006517          	auipc	a0,0x6
ffffffffc0200f7e:	0be56503          	lwu	a0,190(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200f82:	8082                	ret

ffffffffc0200f84 <default_check>:
ffffffffc0200f84:	715d                	addi	sp,sp,-80
ffffffffc0200f86:	e0a2                	sd	s0,64(sp)
ffffffffc0200f88:	00006417          	auipc	s0,0x6
ffffffffc0200f8c:	0a040413          	addi	s0,s0,160 # ffffffffc0207028 <free_area>
ffffffffc0200f90:	641c                	ld	a5,8(s0)
ffffffffc0200f92:	e486                	sd	ra,72(sp)
ffffffffc0200f94:	fc26                	sd	s1,56(sp)
ffffffffc0200f96:	f84a                	sd	s2,48(sp)
ffffffffc0200f98:	f44e                	sd	s3,40(sp)
ffffffffc0200f9a:	f052                	sd	s4,32(sp)
ffffffffc0200f9c:	ec56                	sd	s5,24(sp)
ffffffffc0200f9e:	e85a                	sd	s6,16(sp)
ffffffffc0200fa0:	e45e                	sd	s7,8(sp)
ffffffffc0200fa2:	e062                	sd	s8,0(sp)
ffffffffc0200fa4:	2c878763          	beq	a5,s0,ffffffffc0201272 <default_check+0x2ee>
ffffffffc0200fa8:	4481                	li	s1,0
ffffffffc0200faa:	4901                	li	s2,0
ffffffffc0200fac:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200fb0:	8b09                	andi	a4,a4,2
ffffffffc0200fb2:	2c070463          	beqz	a4,ffffffffc020127a <default_check+0x2f6>
ffffffffc0200fb6:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fba:	679c                	ld	a5,8(a5)
ffffffffc0200fbc:	2905                	addiw	s2,s2,1
ffffffffc0200fbe:	9cb9                	addw	s1,s1,a4
ffffffffc0200fc0:	fe8796e3          	bne	a5,s0,ffffffffc0200fac <default_check+0x28>
ffffffffc0200fc4:	89a6                	mv	s3,s1
ffffffffc0200fc6:	d89ff0ef          	jal	ra,ffffffffc0200d4e <nr_free_pages>
ffffffffc0200fca:	71351863          	bne	a0,s3,ffffffffc02016da <default_check+0x756>
ffffffffc0200fce:	4505                	li	a0,1
ffffffffc0200fd0:	d03ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0200fd4:	8a2a                	mv	s4,a0
ffffffffc0200fd6:	44050263          	beqz	a0,ffffffffc020141a <default_check+0x496>
ffffffffc0200fda:	4505                	li	a0,1
ffffffffc0200fdc:	cf7ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0200fe0:	89aa                	mv	s3,a0
ffffffffc0200fe2:	70050c63          	beqz	a0,ffffffffc02016fa <default_check+0x776>
ffffffffc0200fe6:	4505                	li	a0,1
ffffffffc0200fe8:	cebff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0200fec:	8aaa                	mv	s5,a0
ffffffffc0200fee:	4a050663          	beqz	a0,ffffffffc020149a <default_check+0x516>
ffffffffc0200ff2:	2b3a0463          	beq	s4,s3,ffffffffc020129a <default_check+0x316>
ffffffffc0200ff6:	2aaa0263          	beq	s4,a0,ffffffffc020129a <default_check+0x316>
ffffffffc0200ffa:	2aa98063          	beq	s3,a0,ffffffffc020129a <default_check+0x316>
ffffffffc0200ffe:	000a2783          	lw	a5,0(s4)
ffffffffc0201002:	2a079c63          	bnez	a5,ffffffffc02012ba <default_check+0x336>
ffffffffc0201006:	0009a783          	lw	a5,0(s3)
ffffffffc020100a:	2a079863          	bnez	a5,ffffffffc02012ba <default_check+0x336>
ffffffffc020100e:	411c                	lw	a5,0(a0)
ffffffffc0201010:	2a079563          	bnez	a5,ffffffffc02012ba <default_check+0x336>
ffffffffc0201014:	00006797          	auipc	a5,0x6
ffffffffc0201018:	45c7b783          	ld	a5,1116(a5) # ffffffffc0207470 <pages>
ffffffffc020101c:	40fa0733          	sub	a4,s4,a5
ffffffffc0201020:	870d                	srai	a4,a4,0x3
ffffffffc0201022:	00002597          	auipc	a1,0x2
ffffffffc0201026:	0ae5b583          	ld	a1,174(a1) # ffffffffc02030d0 <nbase+0x8>
ffffffffc020102a:	02b70733          	mul	a4,a4,a1
ffffffffc020102e:	00002617          	auipc	a2,0x2
ffffffffc0201032:	09a63603          	ld	a2,154(a2) # ffffffffc02030c8 <nbase>
ffffffffc0201036:	00006697          	auipc	a3,0x6
ffffffffc020103a:	4326b683          	ld	a3,1074(a3) # ffffffffc0207468 <npage>
ffffffffc020103e:	06b2                	slli	a3,a3,0xc
ffffffffc0201040:	9732                	add	a4,a4,a2
ffffffffc0201042:	0732                	slli	a4,a4,0xc
ffffffffc0201044:	28d77b63          	bgeu	a4,a3,ffffffffc02012da <default_check+0x356>
ffffffffc0201048:	40f98733          	sub	a4,s3,a5
ffffffffc020104c:	870d                	srai	a4,a4,0x3
ffffffffc020104e:	02b70733          	mul	a4,a4,a1
ffffffffc0201052:	9732                	add	a4,a4,a2
ffffffffc0201054:	0732                	slli	a4,a4,0xc
ffffffffc0201056:	4cd77263          	bgeu	a4,a3,ffffffffc020151a <default_check+0x596>
ffffffffc020105a:	40f507b3          	sub	a5,a0,a5
ffffffffc020105e:	878d                	srai	a5,a5,0x3
ffffffffc0201060:	02b787b3          	mul	a5,a5,a1
ffffffffc0201064:	97b2                	add	a5,a5,a2
ffffffffc0201066:	07b2                	slli	a5,a5,0xc
ffffffffc0201068:	30d7f963          	bgeu	a5,a3,ffffffffc020137a <default_check+0x3f6>
ffffffffc020106c:	4505                	li	a0,1
ffffffffc020106e:	00043c03          	ld	s8,0(s0)
ffffffffc0201072:	00843b83          	ld	s7,8(s0)
ffffffffc0201076:	01042b03          	lw	s6,16(s0)
ffffffffc020107a:	e400                	sd	s0,8(s0)
ffffffffc020107c:	e000                	sd	s0,0(s0)
ffffffffc020107e:	00006797          	auipc	a5,0x6
ffffffffc0201082:	fa07ad23          	sw	zero,-70(a5) # ffffffffc0207038 <free_area+0x10>
ffffffffc0201086:	c4dff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc020108a:	2c051863          	bnez	a0,ffffffffc020135a <default_check+0x3d6>
ffffffffc020108e:	4585                	li	a1,1
ffffffffc0201090:	8552                	mv	a0,s4
ffffffffc0201092:	c7fff0ef          	jal	ra,ffffffffc0200d10 <free_pages>
ffffffffc0201096:	4585                	li	a1,1
ffffffffc0201098:	854e                	mv	a0,s3
ffffffffc020109a:	c77ff0ef          	jal	ra,ffffffffc0200d10 <free_pages>
ffffffffc020109e:	4585                	li	a1,1
ffffffffc02010a0:	8556                	mv	a0,s5
ffffffffc02010a2:	c6fff0ef          	jal	ra,ffffffffc0200d10 <free_pages>
ffffffffc02010a6:	4818                	lw	a4,16(s0)
ffffffffc02010a8:	478d                	li	a5,3
ffffffffc02010aa:	28f71863          	bne	a4,a5,ffffffffc020133a <default_check+0x3b6>
ffffffffc02010ae:	4505                	li	a0,1
ffffffffc02010b0:	c23ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc02010b4:	89aa                	mv	s3,a0
ffffffffc02010b6:	26050263          	beqz	a0,ffffffffc020131a <default_check+0x396>
ffffffffc02010ba:	4505                	li	a0,1
ffffffffc02010bc:	c17ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc02010c0:	8aaa                	mv	s5,a0
ffffffffc02010c2:	3a050c63          	beqz	a0,ffffffffc020147a <default_check+0x4f6>
ffffffffc02010c6:	4505                	li	a0,1
ffffffffc02010c8:	c0bff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc02010cc:	8a2a                	mv	s4,a0
ffffffffc02010ce:	38050663          	beqz	a0,ffffffffc020145a <default_check+0x4d6>
ffffffffc02010d2:	4505                	li	a0,1
ffffffffc02010d4:	bffff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc02010d8:	36051163          	bnez	a0,ffffffffc020143a <default_check+0x4b6>
ffffffffc02010dc:	4585                	li	a1,1
ffffffffc02010de:	854e                	mv	a0,s3
ffffffffc02010e0:	c31ff0ef          	jal	ra,ffffffffc0200d10 <free_pages>
ffffffffc02010e4:	641c                	ld	a5,8(s0)
ffffffffc02010e6:	20878a63          	beq	a5,s0,ffffffffc02012fa <default_check+0x376>
ffffffffc02010ea:	4505                	li	a0,1
ffffffffc02010ec:	be7ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc02010f0:	30a99563          	bne	s3,a0,ffffffffc02013fa <default_check+0x476>
ffffffffc02010f4:	4505                	li	a0,1
ffffffffc02010f6:	bddff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc02010fa:	2e051063          	bnez	a0,ffffffffc02013da <default_check+0x456>
ffffffffc02010fe:	481c                	lw	a5,16(s0)
ffffffffc0201100:	2a079d63          	bnez	a5,ffffffffc02013ba <default_check+0x436>
ffffffffc0201104:	854e                	mv	a0,s3
ffffffffc0201106:	4585                	li	a1,1
ffffffffc0201108:	01843023          	sd	s8,0(s0)
ffffffffc020110c:	01743423          	sd	s7,8(s0)
ffffffffc0201110:	01642823          	sw	s6,16(s0)
ffffffffc0201114:	bfdff0ef          	jal	ra,ffffffffc0200d10 <free_pages>
ffffffffc0201118:	4585                	li	a1,1
ffffffffc020111a:	8556                	mv	a0,s5
ffffffffc020111c:	bf5ff0ef          	jal	ra,ffffffffc0200d10 <free_pages>
ffffffffc0201120:	4585                	li	a1,1
ffffffffc0201122:	8552                	mv	a0,s4
ffffffffc0201124:	bedff0ef          	jal	ra,ffffffffc0200d10 <free_pages>
ffffffffc0201128:	4515                	li	a0,5
ffffffffc020112a:	ba9ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc020112e:	89aa                	mv	s3,a0
ffffffffc0201130:	26050563          	beqz	a0,ffffffffc020139a <default_check+0x416>
ffffffffc0201134:	651c                	ld	a5,8(a0)
ffffffffc0201136:	8385                	srli	a5,a5,0x1
ffffffffc0201138:	8b85                	andi	a5,a5,1
ffffffffc020113a:	54079063          	bnez	a5,ffffffffc020167a <default_check+0x6f6>
ffffffffc020113e:	4505                	li	a0,1
ffffffffc0201140:	00043b03          	ld	s6,0(s0)
ffffffffc0201144:	00843a83          	ld	s5,8(s0)
ffffffffc0201148:	e000                	sd	s0,0(s0)
ffffffffc020114a:	e400                	sd	s0,8(s0)
ffffffffc020114c:	b87ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0201150:	50051563          	bnez	a0,ffffffffc020165a <default_check+0x6d6>
ffffffffc0201154:	05098a13          	addi	s4,s3,80
ffffffffc0201158:	8552                	mv	a0,s4
ffffffffc020115a:	458d                	li	a1,3
ffffffffc020115c:	01042b83          	lw	s7,16(s0)
ffffffffc0201160:	00006797          	auipc	a5,0x6
ffffffffc0201164:	ec07ac23          	sw	zero,-296(a5) # ffffffffc0207038 <free_area+0x10>
ffffffffc0201168:	ba9ff0ef          	jal	ra,ffffffffc0200d10 <free_pages>
ffffffffc020116c:	4511                	li	a0,4
ffffffffc020116e:	b65ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0201172:	4c051463          	bnez	a0,ffffffffc020163a <default_check+0x6b6>
ffffffffc0201176:	0589b783          	ld	a5,88(s3)
ffffffffc020117a:	8385                	srli	a5,a5,0x1
ffffffffc020117c:	8b85                	andi	a5,a5,1
ffffffffc020117e:	48078e63          	beqz	a5,ffffffffc020161a <default_check+0x696>
ffffffffc0201182:	0609a703          	lw	a4,96(s3)
ffffffffc0201186:	478d                	li	a5,3
ffffffffc0201188:	48f71963          	bne	a4,a5,ffffffffc020161a <default_check+0x696>
ffffffffc020118c:	450d                	li	a0,3
ffffffffc020118e:	b45ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0201192:	8c2a                	mv	s8,a0
ffffffffc0201194:	46050363          	beqz	a0,ffffffffc02015fa <default_check+0x676>
ffffffffc0201198:	4505                	li	a0,1
ffffffffc020119a:	b39ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc020119e:	42051e63          	bnez	a0,ffffffffc02015da <default_check+0x656>
ffffffffc02011a2:	418a1c63          	bne	s4,s8,ffffffffc02015ba <default_check+0x636>
ffffffffc02011a6:	4585                	li	a1,1
ffffffffc02011a8:	854e                	mv	a0,s3
ffffffffc02011aa:	b67ff0ef          	jal	ra,ffffffffc0200d10 <free_pages>
ffffffffc02011ae:	458d                	li	a1,3
ffffffffc02011b0:	8552                	mv	a0,s4
ffffffffc02011b2:	b5fff0ef          	jal	ra,ffffffffc0200d10 <free_pages>
ffffffffc02011b6:	0089b783          	ld	a5,8(s3)
ffffffffc02011ba:	02898c13          	addi	s8,s3,40
ffffffffc02011be:	8385                	srli	a5,a5,0x1
ffffffffc02011c0:	8b85                	andi	a5,a5,1
ffffffffc02011c2:	3c078c63          	beqz	a5,ffffffffc020159a <default_check+0x616>
ffffffffc02011c6:	0109a703          	lw	a4,16(s3)
ffffffffc02011ca:	4785                	li	a5,1
ffffffffc02011cc:	3cf71763          	bne	a4,a5,ffffffffc020159a <default_check+0x616>
ffffffffc02011d0:	008a3783          	ld	a5,8(s4)
ffffffffc02011d4:	8385                	srli	a5,a5,0x1
ffffffffc02011d6:	8b85                	andi	a5,a5,1
ffffffffc02011d8:	3a078163          	beqz	a5,ffffffffc020157a <default_check+0x5f6>
ffffffffc02011dc:	010a2703          	lw	a4,16(s4)
ffffffffc02011e0:	478d                	li	a5,3
ffffffffc02011e2:	38f71c63          	bne	a4,a5,ffffffffc020157a <default_check+0x5f6>
ffffffffc02011e6:	4505                	li	a0,1
ffffffffc02011e8:	aebff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc02011ec:	36a99763          	bne	s3,a0,ffffffffc020155a <default_check+0x5d6>
ffffffffc02011f0:	4585                	li	a1,1
ffffffffc02011f2:	b1fff0ef          	jal	ra,ffffffffc0200d10 <free_pages>
ffffffffc02011f6:	4509                	li	a0,2
ffffffffc02011f8:	adbff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc02011fc:	32aa1f63          	bne	s4,a0,ffffffffc020153a <default_check+0x5b6>
ffffffffc0201200:	4589                	li	a1,2
ffffffffc0201202:	b0fff0ef          	jal	ra,ffffffffc0200d10 <free_pages>
ffffffffc0201206:	4585                	li	a1,1
ffffffffc0201208:	8562                	mv	a0,s8
ffffffffc020120a:	b07ff0ef          	jal	ra,ffffffffc0200d10 <free_pages>
ffffffffc020120e:	4515                	li	a0,5
ffffffffc0201210:	ac3ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0201214:	89aa                	mv	s3,a0
ffffffffc0201216:	48050263          	beqz	a0,ffffffffc020169a <default_check+0x716>
ffffffffc020121a:	4505                	li	a0,1
ffffffffc020121c:	ab7ff0ef          	jal	ra,ffffffffc0200cd2 <alloc_pages>
ffffffffc0201220:	2c051d63          	bnez	a0,ffffffffc02014fa <default_check+0x576>
ffffffffc0201224:	481c                	lw	a5,16(s0)
ffffffffc0201226:	2a079a63          	bnez	a5,ffffffffc02014da <default_check+0x556>
ffffffffc020122a:	4595                	li	a1,5
ffffffffc020122c:	854e                	mv	a0,s3
ffffffffc020122e:	01742823          	sw	s7,16(s0)
ffffffffc0201232:	01643023          	sd	s6,0(s0)
ffffffffc0201236:	01543423          	sd	s5,8(s0)
ffffffffc020123a:	ad7ff0ef          	jal	ra,ffffffffc0200d10 <free_pages>
ffffffffc020123e:	641c                	ld	a5,8(s0)
ffffffffc0201240:	00878963          	beq	a5,s0,ffffffffc0201252 <default_check+0x2ce>
ffffffffc0201244:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201248:	679c                	ld	a5,8(a5)
ffffffffc020124a:	397d                	addiw	s2,s2,-1
ffffffffc020124c:	9c99                	subw	s1,s1,a4
ffffffffc020124e:	fe879be3          	bne	a5,s0,ffffffffc0201244 <default_check+0x2c0>
ffffffffc0201252:	26091463          	bnez	s2,ffffffffc02014ba <default_check+0x536>
ffffffffc0201256:	46049263          	bnez	s1,ffffffffc02016ba <default_check+0x736>
ffffffffc020125a:	60a6                	ld	ra,72(sp)
ffffffffc020125c:	6406                	ld	s0,64(sp)
ffffffffc020125e:	74e2                	ld	s1,56(sp)
ffffffffc0201260:	7942                	ld	s2,48(sp)
ffffffffc0201262:	79a2                	ld	s3,40(sp)
ffffffffc0201264:	7a02                	ld	s4,32(sp)
ffffffffc0201266:	6ae2                	ld	s5,24(sp)
ffffffffc0201268:	6b42                	ld	s6,16(sp)
ffffffffc020126a:	6ba2                	ld	s7,8(sp)
ffffffffc020126c:	6c02                	ld	s8,0(sp)
ffffffffc020126e:	6161                	addi	sp,sp,80
ffffffffc0201270:	8082                	ret
ffffffffc0201272:	4981                	li	s3,0
ffffffffc0201274:	4481                	li	s1,0
ffffffffc0201276:	4901                	li	s2,0
ffffffffc0201278:	b3b9                	j	ffffffffc0200fc6 <default_check+0x42>
ffffffffc020127a:	00002697          	auipc	a3,0x2
ffffffffc020127e:	80e68693          	addi	a3,a3,-2034 # ffffffffc0202a88 <commands+0x820>
ffffffffc0201282:	00002617          	auipc	a2,0x2
ffffffffc0201286:	81660613          	addi	a2,a2,-2026 # ffffffffc0202a98 <commands+0x830>
ffffffffc020128a:	0f000593          	li	a1,240
ffffffffc020128e:	00002517          	auipc	a0,0x2
ffffffffc0201292:	82250513          	addi	a0,a0,-2014 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201296:	ecbfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020129a:	00002697          	auipc	a3,0x2
ffffffffc020129e:	8ae68693          	addi	a3,a3,-1874 # ffffffffc0202b48 <commands+0x8e0>
ffffffffc02012a2:	00001617          	auipc	a2,0x1
ffffffffc02012a6:	7f660613          	addi	a2,a2,2038 # ffffffffc0202a98 <commands+0x830>
ffffffffc02012aa:	0bd00593          	li	a1,189
ffffffffc02012ae:	00002517          	auipc	a0,0x2
ffffffffc02012b2:	80250513          	addi	a0,a0,-2046 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02012b6:	eabfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02012ba:	00002697          	auipc	a3,0x2
ffffffffc02012be:	8b668693          	addi	a3,a3,-1866 # ffffffffc0202b70 <commands+0x908>
ffffffffc02012c2:	00001617          	auipc	a2,0x1
ffffffffc02012c6:	7d660613          	addi	a2,a2,2006 # ffffffffc0202a98 <commands+0x830>
ffffffffc02012ca:	0be00593          	li	a1,190
ffffffffc02012ce:	00001517          	auipc	a0,0x1
ffffffffc02012d2:	7e250513          	addi	a0,a0,2018 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02012d6:	e8bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02012da:	00002697          	auipc	a3,0x2
ffffffffc02012de:	8d668693          	addi	a3,a3,-1834 # ffffffffc0202bb0 <commands+0x948>
ffffffffc02012e2:	00001617          	auipc	a2,0x1
ffffffffc02012e6:	7b660613          	addi	a2,a2,1974 # ffffffffc0202a98 <commands+0x830>
ffffffffc02012ea:	0c000593          	li	a1,192
ffffffffc02012ee:	00001517          	auipc	a0,0x1
ffffffffc02012f2:	7c250513          	addi	a0,a0,1986 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02012f6:	e6bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02012fa:	00002697          	auipc	a3,0x2
ffffffffc02012fe:	93e68693          	addi	a3,a3,-1730 # ffffffffc0202c38 <commands+0x9d0>
ffffffffc0201302:	00001617          	auipc	a2,0x1
ffffffffc0201306:	79660613          	addi	a2,a2,1942 # ffffffffc0202a98 <commands+0x830>
ffffffffc020130a:	0d900593          	li	a1,217
ffffffffc020130e:	00001517          	auipc	a0,0x1
ffffffffc0201312:	7a250513          	addi	a0,a0,1954 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201316:	e4bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020131a:	00001697          	auipc	a3,0x1
ffffffffc020131e:	7ce68693          	addi	a3,a3,1998 # ffffffffc0202ae8 <commands+0x880>
ffffffffc0201322:	00001617          	auipc	a2,0x1
ffffffffc0201326:	77660613          	addi	a2,a2,1910 # ffffffffc0202a98 <commands+0x830>
ffffffffc020132a:	0d200593          	li	a1,210
ffffffffc020132e:	00001517          	auipc	a0,0x1
ffffffffc0201332:	78250513          	addi	a0,a0,1922 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201336:	e2bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020133a:	00002697          	auipc	a3,0x2
ffffffffc020133e:	8ee68693          	addi	a3,a3,-1810 # ffffffffc0202c28 <commands+0x9c0>
ffffffffc0201342:	00001617          	auipc	a2,0x1
ffffffffc0201346:	75660613          	addi	a2,a2,1878 # ffffffffc0202a98 <commands+0x830>
ffffffffc020134a:	0d000593          	li	a1,208
ffffffffc020134e:	00001517          	auipc	a0,0x1
ffffffffc0201352:	76250513          	addi	a0,a0,1890 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201356:	e0bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020135a:	00002697          	auipc	a3,0x2
ffffffffc020135e:	8b668693          	addi	a3,a3,-1866 # ffffffffc0202c10 <commands+0x9a8>
ffffffffc0201362:	00001617          	auipc	a2,0x1
ffffffffc0201366:	73660613          	addi	a2,a2,1846 # ffffffffc0202a98 <commands+0x830>
ffffffffc020136a:	0cb00593          	li	a1,203
ffffffffc020136e:	00001517          	auipc	a0,0x1
ffffffffc0201372:	74250513          	addi	a0,a0,1858 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201376:	debfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020137a:	00002697          	auipc	a3,0x2
ffffffffc020137e:	87668693          	addi	a3,a3,-1930 # ffffffffc0202bf0 <commands+0x988>
ffffffffc0201382:	00001617          	auipc	a2,0x1
ffffffffc0201386:	71660613          	addi	a2,a2,1814 # ffffffffc0202a98 <commands+0x830>
ffffffffc020138a:	0c200593          	li	a1,194
ffffffffc020138e:	00001517          	auipc	a0,0x1
ffffffffc0201392:	72250513          	addi	a0,a0,1826 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201396:	dcbfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020139a:	00002697          	auipc	a3,0x2
ffffffffc020139e:	8e668693          	addi	a3,a3,-1818 # ffffffffc0202c80 <commands+0xa18>
ffffffffc02013a2:	00001617          	auipc	a2,0x1
ffffffffc02013a6:	6f660613          	addi	a2,a2,1782 # ffffffffc0202a98 <commands+0x830>
ffffffffc02013aa:	0f800593          	li	a1,248
ffffffffc02013ae:	00001517          	auipc	a0,0x1
ffffffffc02013b2:	70250513          	addi	a0,a0,1794 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02013b6:	dabfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02013ba:	00002697          	auipc	a3,0x2
ffffffffc02013be:	8b668693          	addi	a3,a3,-1866 # ffffffffc0202c70 <commands+0xa08>
ffffffffc02013c2:	00001617          	auipc	a2,0x1
ffffffffc02013c6:	6d660613          	addi	a2,a2,1750 # ffffffffc0202a98 <commands+0x830>
ffffffffc02013ca:	0df00593          	li	a1,223
ffffffffc02013ce:	00001517          	auipc	a0,0x1
ffffffffc02013d2:	6e250513          	addi	a0,a0,1762 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02013d6:	d8bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02013da:	00002697          	auipc	a3,0x2
ffffffffc02013de:	83668693          	addi	a3,a3,-1994 # ffffffffc0202c10 <commands+0x9a8>
ffffffffc02013e2:	00001617          	auipc	a2,0x1
ffffffffc02013e6:	6b660613          	addi	a2,a2,1718 # ffffffffc0202a98 <commands+0x830>
ffffffffc02013ea:	0dd00593          	li	a1,221
ffffffffc02013ee:	00001517          	auipc	a0,0x1
ffffffffc02013f2:	6c250513          	addi	a0,a0,1730 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02013f6:	d6bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02013fa:	00002697          	auipc	a3,0x2
ffffffffc02013fe:	85668693          	addi	a3,a3,-1962 # ffffffffc0202c50 <commands+0x9e8>
ffffffffc0201402:	00001617          	auipc	a2,0x1
ffffffffc0201406:	69660613          	addi	a2,a2,1686 # ffffffffc0202a98 <commands+0x830>
ffffffffc020140a:	0dc00593          	li	a1,220
ffffffffc020140e:	00001517          	auipc	a0,0x1
ffffffffc0201412:	6a250513          	addi	a0,a0,1698 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201416:	d4bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020141a:	00001697          	auipc	a3,0x1
ffffffffc020141e:	6ce68693          	addi	a3,a3,1742 # ffffffffc0202ae8 <commands+0x880>
ffffffffc0201422:	00001617          	auipc	a2,0x1
ffffffffc0201426:	67660613          	addi	a2,a2,1654 # ffffffffc0202a98 <commands+0x830>
ffffffffc020142a:	0b900593          	li	a1,185
ffffffffc020142e:	00001517          	auipc	a0,0x1
ffffffffc0201432:	68250513          	addi	a0,a0,1666 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201436:	d2bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020143a:	00001697          	auipc	a3,0x1
ffffffffc020143e:	7d668693          	addi	a3,a3,2006 # ffffffffc0202c10 <commands+0x9a8>
ffffffffc0201442:	00001617          	auipc	a2,0x1
ffffffffc0201446:	65660613          	addi	a2,a2,1622 # ffffffffc0202a98 <commands+0x830>
ffffffffc020144a:	0d600593          	li	a1,214
ffffffffc020144e:	00001517          	auipc	a0,0x1
ffffffffc0201452:	66250513          	addi	a0,a0,1634 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201456:	d0bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020145a:	00001697          	auipc	a3,0x1
ffffffffc020145e:	6ce68693          	addi	a3,a3,1742 # ffffffffc0202b28 <commands+0x8c0>
ffffffffc0201462:	00001617          	auipc	a2,0x1
ffffffffc0201466:	63660613          	addi	a2,a2,1590 # ffffffffc0202a98 <commands+0x830>
ffffffffc020146a:	0d400593          	li	a1,212
ffffffffc020146e:	00001517          	auipc	a0,0x1
ffffffffc0201472:	64250513          	addi	a0,a0,1602 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201476:	cebfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020147a:	00001697          	auipc	a3,0x1
ffffffffc020147e:	68e68693          	addi	a3,a3,1678 # ffffffffc0202b08 <commands+0x8a0>
ffffffffc0201482:	00001617          	auipc	a2,0x1
ffffffffc0201486:	61660613          	addi	a2,a2,1558 # ffffffffc0202a98 <commands+0x830>
ffffffffc020148a:	0d300593          	li	a1,211
ffffffffc020148e:	00001517          	auipc	a0,0x1
ffffffffc0201492:	62250513          	addi	a0,a0,1570 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201496:	ccbfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020149a:	00001697          	auipc	a3,0x1
ffffffffc020149e:	68e68693          	addi	a3,a3,1678 # ffffffffc0202b28 <commands+0x8c0>
ffffffffc02014a2:	00001617          	auipc	a2,0x1
ffffffffc02014a6:	5f660613          	addi	a2,a2,1526 # ffffffffc0202a98 <commands+0x830>
ffffffffc02014aa:	0bb00593          	li	a1,187
ffffffffc02014ae:	00001517          	auipc	a0,0x1
ffffffffc02014b2:	60250513          	addi	a0,a0,1538 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02014b6:	cabfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02014ba:	00002697          	auipc	a3,0x2
ffffffffc02014be:	91668693          	addi	a3,a3,-1770 # ffffffffc0202dd0 <commands+0xb68>
ffffffffc02014c2:	00001617          	auipc	a2,0x1
ffffffffc02014c6:	5d660613          	addi	a2,a2,1494 # ffffffffc0202a98 <commands+0x830>
ffffffffc02014ca:	12500593          	li	a1,293
ffffffffc02014ce:	00001517          	auipc	a0,0x1
ffffffffc02014d2:	5e250513          	addi	a0,a0,1506 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02014d6:	c8bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02014da:	00001697          	auipc	a3,0x1
ffffffffc02014de:	79668693          	addi	a3,a3,1942 # ffffffffc0202c70 <commands+0xa08>
ffffffffc02014e2:	00001617          	auipc	a2,0x1
ffffffffc02014e6:	5b660613          	addi	a2,a2,1462 # ffffffffc0202a98 <commands+0x830>
ffffffffc02014ea:	11a00593          	li	a1,282
ffffffffc02014ee:	00001517          	auipc	a0,0x1
ffffffffc02014f2:	5c250513          	addi	a0,a0,1474 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02014f6:	c6bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02014fa:	00001697          	auipc	a3,0x1
ffffffffc02014fe:	71668693          	addi	a3,a3,1814 # ffffffffc0202c10 <commands+0x9a8>
ffffffffc0201502:	00001617          	auipc	a2,0x1
ffffffffc0201506:	59660613          	addi	a2,a2,1430 # ffffffffc0202a98 <commands+0x830>
ffffffffc020150a:	11800593          	li	a1,280
ffffffffc020150e:	00001517          	auipc	a0,0x1
ffffffffc0201512:	5a250513          	addi	a0,a0,1442 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201516:	c4bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020151a:	00001697          	auipc	a3,0x1
ffffffffc020151e:	6b668693          	addi	a3,a3,1718 # ffffffffc0202bd0 <commands+0x968>
ffffffffc0201522:	00001617          	auipc	a2,0x1
ffffffffc0201526:	57660613          	addi	a2,a2,1398 # ffffffffc0202a98 <commands+0x830>
ffffffffc020152a:	0c100593          	li	a1,193
ffffffffc020152e:	00001517          	auipc	a0,0x1
ffffffffc0201532:	58250513          	addi	a0,a0,1410 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201536:	c2bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020153a:	00002697          	auipc	a3,0x2
ffffffffc020153e:	85668693          	addi	a3,a3,-1962 # ffffffffc0202d90 <commands+0xb28>
ffffffffc0201542:	00001617          	auipc	a2,0x1
ffffffffc0201546:	55660613          	addi	a2,a2,1366 # ffffffffc0202a98 <commands+0x830>
ffffffffc020154a:	11200593          	li	a1,274
ffffffffc020154e:	00001517          	auipc	a0,0x1
ffffffffc0201552:	56250513          	addi	a0,a0,1378 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201556:	c0bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020155a:	00002697          	auipc	a3,0x2
ffffffffc020155e:	81668693          	addi	a3,a3,-2026 # ffffffffc0202d70 <commands+0xb08>
ffffffffc0201562:	00001617          	auipc	a2,0x1
ffffffffc0201566:	53660613          	addi	a2,a2,1334 # ffffffffc0202a98 <commands+0x830>
ffffffffc020156a:	11000593          	li	a1,272
ffffffffc020156e:	00001517          	auipc	a0,0x1
ffffffffc0201572:	54250513          	addi	a0,a0,1346 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201576:	bebfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020157a:	00001697          	auipc	a3,0x1
ffffffffc020157e:	7ce68693          	addi	a3,a3,1998 # ffffffffc0202d48 <commands+0xae0>
ffffffffc0201582:	00001617          	auipc	a2,0x1
ffffffffc0201586:	51660613          	addi	a2,a2,1302 # ffffffffc0202a98 <commands+0x830>
ffffffffc020158a:	10e00593          	li	a1,270
ffffffffc020158e:	00001517          	auipc	a0,0x1
ffffffffc0201592:	52250513          	addi	a0,a0,1314 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201596:	bcbfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020159a:	00001697          	auipc	a3,0x1
ffffffffc020159e:	78668693          	addi	a3,a3,1926 # ffffffffc0202d20 <commands+0xab8>
ffffffffc02015a2:	00001617          	auipc	a2,0x1
ffffffffc02015a6:	4f660613          	addi	a2,a2,1270 # ffffffffc0202a98 <commands+0x830>
ffffffffc02015aa:	10d00593          	li	a1,269
ffffffffc02015ae:	00001517          	auipc	a0,0x1
ffffffffc02015b2:	50250513          	addi	a0,a0,1282 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02015b6:	babfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02015ba:	00001697          	auipc	a3,0x1
ffffffffc02015be:	75668693          	addi	a3,a3,1878 # ffffffffc0202d10 <commands+0xaa8>
ffffffffc02015c2:	00001617          	auipc	a2,0x1
ffffffffc02015c6:	4d660613          	addi	a2,a2,1238 # ffffffffc0202a98 <commands+0x830>
ffffffffc02015ca:	10800593          	li	a1,264
ffffffffc02015ce:	00001517          	auipc	a0,0x1
ffffffffc02015d2:	4e250513          	addi	a0,a0,1250 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02015d6:	b8bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02015da:	00001697          	auipc	a3,0x1
ffffffffc02015de:	63668693          	addi	a3,a3,1590 # ffffffffc0202c10 <commands+0x9a8>
ffffffffc02015e2:	00001617          	auipc	a2,0x1
ffffffffc02015e6:	4b660613          	addi	a2,a2,1206 # ffffffffc0202a98 <commands+0x830>
ffffffffc02015ea:	10700593          	li	a1,263
ffffffffc02015ee:	00001517          	auipc	a0,0x1
ffffffffc02015f2:	4c250513          	addi	a0,a0,1218 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02015f6:	b6bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02015fa:	00001697          	auipc	a3,0x1
ffffffffc02015fe:	6f668693          	addi	a3,a3,1782 # ffffffffc0202cf0 <commands+0xa88>
ffffffffc0201602:	00001617          	auipc	a2,0x1
ffffffffc0201606:	49660613          	addi	a2,a2,1174 # ffffffffc0202a98 <commands+0x830>
ffffffffc020160a:	10600593          	li	a1,262
ffffffffc020160e:	00001517          	auipc	a0,0x1
ffffffffc0201612:	4a250513          	addi	a0,a0,1186 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201616:	b4bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020161a:	00001697          	auipc	a3,0x1
ffffffffc020161e:	6a668693          	addi	a3,a3,1702 # ffffffffc0202cc0 <commands+0xa58>
ffffffffc0201622:	00001617          	auipc	a2,0x1
ffffffffc0201626:	47660613          	addi	a2,a2,1142 # ffffffffc0202a98 <commands+0x830>
ffffffffc020162a:	10500593          	li	a1,261
ffffffffc020162e:	00001517          	auipc	a0,0x1
ffffffffc0201632:	48250513          	addi	a0,a0,1154 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201636:	b2bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020163a:	00001697          	auipc	a3,0x1
ffffffffc020163e:	66e68693          	addi	a3,a3,1646 # ffffffffc0202ca8 <commands+0xa40>
ffffffffc0201642:	00001617          	auipc	a2,0x1
ffffffffc0201646:	45660613          	addi	a2,a2,1110 # ffffffffc0202a98 <commands+0x830>
ffffffffc020164a:	10400593          	li	a1,260
ffffffffc020164e:	00001517          	auipc	a0,0x1
ffffffffc0201652:	46250513          	addi	a0,a0,1122 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201656:	b0bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020165a:	00001697          	auipc	a3,0x1
ffffffffc020165e:	5b668693          	addi	a3,a3,1462 # ffffffffc0202c10 <commands+0x9a8>
ffffffffc0201662:	00001617          	auipc	a2,0x1
ffffffffc0201666:	43660613          	addi	a2,a2,1078 # ffffffffc0202a98 <commands+0x830>
ffffffffc020166a:	0fe00593          	li	a1,254
ffffffffc020166e:	00001517          	auipc	a0,0x1
ffffffffc0201672:	44250513          	addi	a0,a0,1090 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201676:	aebfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020167a:	00001697          	auipc	a3,0x1
ffffffffc020167e:	61668693          	addi	a3,a3,1558 # ffffffffc0202c90 <commands+0xa28>
ffffffffc0201682:	00001617          	auipc	a2,0x1
ffffffffc0201686:	41660613          	addi	a2,a2,1046 # ffffffffc0202a98 <commands+0x830>
ffffffffc020168a:	0f900593          	li	a1,249
ffffffffc020168e:	00001517          	auipc	a0,0x1
ffffffffc0201692:	42250513          	addi	a0,a0,1058 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201696:	acbfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc020169a:	00001697          	auipc	a3,0x1
ffffffffc020169e:	71668693          	addi	a3,a3,1814 # ffffffffc0202db0 <commands+0xb48>
ffffffffc02016a2:	00001617          	auipc	a2,0x1
ffffffffc02016a6:	3f660613          	addi	a2,a2,1014 # ffffffffc0202a98 <commands+0x830>
ffffffffc02016aa:	11700593          	li	a1,279
ffffffffc02016ae:	00001517          	auipc	a0,0x1
ffffffffc02016b2:	40250513          	addi	a0,a0,1026 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02016b6:	aabfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02016ba:	00001697          	auipc	a3,0x1
ffffffffc02016be:	72668693          	addi	a3,a3,1830 # ffffffffc0202de0 <commands+0xb78>
ffffffffc02016c2:	00001617          	auipc	a2,0x1
ffffffffc02016c6:	3d660613          	addi	a2,a2,982 # ffffffffc0202a98 <commands+0x830>
ffffffffc02016ca:	12600593          	li	a1,294
ffffffffc02016ce:	00001517          	auipc	a0,0x1
ffffffffc02016d2:	3e250513          	addi	a0,a0,994 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02016d6:	a8bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02016da:	00001697          	auipc	a3,0x1
ffffffffc02016de:	3ee68693          	addi	a3,a3,1006 # ffffffffc0202ac8 <commands+0x860>
ffffffffc02016e2:	00001617          	auipc	a2,0x1
ffffffffc02016e6:	3b660613          	addi	a2,a2,950 # ffffffffc0202a98 <commands+0x830>
ffffffffc02016ea:	0f300593          	li	a1,243
ffffffffc02016ee:	00001517          	auipc	a0,0x1
ffffffffc02016f2:	3c250513          	addi	a0,a0,962 # ffffffffc0202ab0 <commands+0x848>
ffffffffc02016f6:	a6bfe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc02016fa:	00001697          	auipc	a3,0x1
ffffffffc02016fe:	40e68693          	addi	a3,a3,1038 # ffffffffc0202b08 <commands+0x8a0>
ffffffffc0201702:	00001617          	auipc	a2,0x1
ffffffffc0201706:	39660613          	addi	a2,a2,918 # ffffffffc0202a98 <commands+0x830>
ffffffffc020170a:	0ba00593          	li	a1,186
ffffffffc020170e:	00001517          	auipc	a0,0x1
ffffffffc0201712:	3a250513          	addi	a0,a0,930 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201716:	a4bfe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc020171a <default_free_pages>:
ffffffffc020171a:	1141                	addi	sp,sp,-16
ffffffffc020171c:	e406                	sd	ra,8(sp)
ffffffffc020171e:	14058a63          	beqz	a1,ffffffffc0201872 <default_free_pages+0x158>
ffffffffc0201722:	00259693          	slli	a3,a1,0x2
ffffffffc0201726:	96ae                	add	a3,a3,a1
ffffffffc0201728:	068e                	slli	a3,a3,0x3
ffffffffc020172a:	96aa                	add	a3,a3,a0
ffffffffc020172c:	87aa                	mv	a5,a0
ffffffffc020172e:	02d50263          	beq	a0,a3,ffffffffc0201752 <default_free_pages+0x38>
ffffffffc0201732:	6798                	ld	a4,8(a5)
ffffffffc0201734:	8b05                	andi	a4,a4,1
ffffffffc0201736:	10071e63          	bnez	a4,ffffffffc0201852 <default_free_pages+0x138>
ffffffffc020173a:	6798                	ld	a4,8(a5)
ffffffffc020173c:	8b09                	andi	a4,a4,2
ffffffffc020173e:	10071a63          	bnez	a4,ffffffffc0201852 <default_free_pages+0x138>
ffffffffc0201742:	0007b423          	sd	zero,8(a5)
ffffffffc0201746:	0007a023          	sw	zero,0(a5)
ffffffffc020174a:	02878793          	addi	a5,a5,40
ffffffffc020174e:	fed792e3          	bne	a5,a3,ffffffffc0201732 <default_free_pages+0x18>
ffffffffc0201752:	2581                	sext.w	a1,a1
ffffffffc0201754:	c90c                	sw	a1,16(a0)
ffffffffc0201756:	00850893          	addi	a7,a0,8
ffffffffc020175a:	4789                	li	a5,2
ffffffffc020175c:	40f8b02f          	amoor.d	zero,a5,(a7)
ffffffffc0201760:	00006697          	auipc	a3,0x6
ffffffffc0201764:	8c868693          	addi	a3,a3,-1848 # ffffffffc0207028 <free_area>
ffffffffc0201768:	4a98                	lw	a4,16(a3)
ffffffffc020176a:	669c                	ld	a5,8(a3)
ffffffffc020176c:	01850613          	addi	a2,a0,24
ffffffffc0201770:	9db9                	addw	a1,a1,a4
ffffffffc0201772:	ca8c                	sw	a1,16(a3)
ffffffffc0201774:	0ad78863          	beq	a5,a3,ffffffffc0201824 <default_free_pages+0x10a>
ffffffffc0201778:	fe878713          	addi	a4,a5,-24
ffffffffc020177c:	0006b803          	ld	a6,0(a3)
ffffffffc0201780:	4581                	li	a1,0
ffffffffc0201782:	00e56a63          	bltu	a0,a4,ffffffffc0201796 <default_free_pages+0x7c>
ffffffffc0201786:	6798                	ld	a4,8(a5)
ffffffffc0201788:	06d70263          	beq	a4,a3,ffffffffc02017ec <default_free_pages+0xd2>
ffffffffc020178c:	87ba                	mv	a5,a4
ffffffffc020178e:	fe878713          	addi	a4,a5,-24
ffffffffc0201792:	fee57ae3          	bgeu	a0,a4,ffffffffc0201786 <default_free_pages+0x6c>
ffffffffc0201796:	c199                	beqz	a1,ffffffffc020179c <default_free_pages+0x82>
ffffffffc0201798:	0106b023          	sd	a6,0(a3)
ffffffffc020179c:	6398                	ld	a4,0(a5)
ffffffffc020179e:	e390                	sd	a2,0(a5)
ffffffffc02017a0:	e710                	sd	a2,8(a4)
ffffffffc02017a2:	f11c                	sd	a5,32(a0)
ffffffffc02017a4:	ed18                	sd	a4,24(a0)
ffffffffc02017a6:	02d70063          	beq	a4,a3,ffffffffc02017c6 <default_free_pages+0xac>
ffffffffc02017aa:	ff872803          	lw	a6,-8(a4) # fffffffffff7fff8 <end+0x3fd78b58>
ffffffffc02017ae:	fe870593          	addi	a1,a4,-24
ffffffffc02017b2:	02081613          	slli	a2,a6,0x20
ffffffffc02017b6:	9201                	srli	a2,a2,0x20
ffffffffc02017b8:	00261793          	slli	a5,a2,0x2
ffffffffc02017bc:	97b2                	add	a5,a5,a2
ffffffffc02017be:	078e                	slli	a5,a5,0x3
ffffffffc02017c0:	97ae                	add	a5,a5,a1
ffffffffc02017c2:	02f50f63          	beq	a0,a5,ffffffffc0201800 <default_free_pages+0xe6>
ffffffffc02017c6:	7118                	ld	a4,32(a0)
ffffffffc02017c8:	00d70f63          	beq	a4,a3,ffffffffc02017e6 <default_free_pages+0xcc>
ffffffffc02017cc:	490c                	lw	a1,16(a0)
ffffffffc02017ce:	fe870693          	addi	a3,a4,-24
ffffffffc02017d2:	02059613          	slli	a2,a1,0x20
ffffffffc02017d6:	9201                	srli	a2,a2,0x20
ffffffffc02017d8:	00261793          	slli	a5,a2,0x2
ffffffffc02017dc:	97b2                	add	a5,a5,a2
ffffffffc02017de:	078e                	slli	a5,a5,0x3
ffffffffc02017e0:	97aa                	add	a5,a5,a0
ffffffffc02017e2:	04f68863          	beq	a3,a5,ffffffffc0201832 <default_free_pages+0x118>
ffffffffc02017e6:	60a2                	ld	ra,8(sp)
ffffffffc02017e8:	0141                	addi	sp,sp,16
ffffffffc02017ea:	8082                	ret
ffffffffc02017ec:	e790                	sd	a2,8(a5)
ffffffffc02017ee:	f114                	sd	a3,32(a0)
ffffffffc02017f0:	6798                	ld	a4,8(a5)
ffffffffc02017f2:	ed1c                	sd	a5,24(a0)
ffffffffc02017f4:	02d70563          	beq	a4,a3,ffffffffc020181e <default_free_pages+0x104>
ffffffffc02017f8:	8832                	mv	a6,a2
ffffffffc02017fa:	4585                	li	a1,1
ffffffffc02017fc:	87ba                	mv	a5,a4
ffffffffc02017fe:	bf41                	j	ffffffffc020178e <default_free_pages+0x74>
ffffffffc0201800:	491c                	lw	a5,16(a0)
ffffffffc0201802:	0107883b          	addw	a6,a5,a6
ffffffffc0201806:	ff072c23          	sw	a6,-8(a4)
ffffffffc020180a:	57f5                	li	a5,-3
ffffffffc020180c:	60f8b02f          	amoand.d	zero,a5,(a7)
ffffffffc0201810:	6d10                	ld	a2,24(a0)
ffffffffc0201812:	711c                	ld	a5,32(a0)
ffffffffc0201814:	852e                	mv	a0,a1
ffffffffc0201816:	e61c                	sd	a5,8(a2)
ffffffffc0201818:	6718                	ld	a4,8(a4)
ffffffffc020181a:	e390                	sd	a2,0(a5)
ffffffffc020181c:	b775                	j	ffffffffc02017c8 <default_free_pages+0xae>
ffffffffc020181e:	e290                	sd	a2,0(a3)
ffffffffc0201820:	873e                	mv	a4,a5
ffffffffc0201822:	b761                	j	ffffffffc02017aa <default_free_pages+0x90>
ffffffffc0201824:	60a2                	ld	ra,8(sp)
ffffffffc0201826:	e390                	sd	a2,0(a5)
ffffffffc0201828:	e790                	sd	a2,8(a5)
ffffffffc020182a:	f11c                	sd	a5,32(a0)
ffffffffc020182c:	ed1c                	sd	a5,24(a0)
ffffffffc020182e:	0141                	addi	sp,sp,16
ffffffffc0201830:	8082                	ret
ffffffffc0201832:	ff872783          	lw	a5,-8(a4)
ffffffffc0201836:	ff070693          	addi	a3,a4,-16
ffffffffc020183a:	9dbd                	addw	a1,a1,a5
ffffffffc020183c:	c90c                	sw	a1,16(a0)
ffffffffc020183e:	57f5                	li	a5,-3
ffffffffc0201840:	60f6b02f          	amoand.d	zero,a5,(a3)
ffffffffc0201844:	6314                	ld	a3,0(a4)
ffffffffc0201846:	671c                	ld	a5,8(a4)
ffffffffc0201848:	60a2                	ld	ra,8(sp)
ffffffffc020184a:	e69c                	sd	a5,8(a3)
ffffffffc020184c:	e394                	sd	a3,0(a5)
ffffffffc020184e:	0141                	addi	sp,sp,16
ffffffffc0201850:	8082                	ret
ffffffffc0201852:	00001697          	auipc	a3,0x1
ffffffffc0201856:	5a668693          	addi	a3,a3,1446 # ffffffffc0202df8 <commands+0xb90>
ffffffffc020185a:	00001617          	auipc	a2,0x1
ffffffffc020185e:	23e60613          	addi	a2,a2,574 # ffffffffc0202a98 <commands+0x830>
ffffffffc0201862:	08300593          	li	a1,131
ffffffffc0201866:	00001517          	auipc	a0,0x1
ffffffffc020186a:	24a50513          	addi	a0,a0,586 # ffffffffc0202ab0 <commands+0x848>
ffffffffc020186e:	8f3fe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc0201872:	00001697          	auipc	a3,0x1
ffffffffc0201876:	57e68693          	addi	a3,a3,1406 # ffffffffc0202df0 <commands+0xb88>
ffffffffc020187a:	00001617          	auipc	a2,0x1
ffffffffc020187e:	21e60613          	addi	a2,a2,542 # ffffffffc0202a98 <commands+0x830>
ffffffffc0201882:	08000593          	li	a1,128
ffffffffc0201886:	00001517          	auipc	a0,0x1
ffffffffc020188a:	22a50513          	addi	a0,a0,554 # ffffffffc0202ab0 <commands+0x848>
ffffffffc020188e:	8d3fe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0201892 <default_alloc_pages>:
ffffffffc0201892:	c959                	beqz	a0,ffffffffc0201928 <default_alloc_pages+0x96>
ffffffffc0201894:	00005597          	auipc	a1,0x5
ffffffffc0201898:	79458593          	addi	a1,a1,1940 # ffffffffc0207028 <free_area>
ffffffffc020189c:	0105a803          	lw	a6,16(a1)
ffffffffc02018a0:	862a                	mv	a2,a0
ffffffffc02018a2:	02081793          	slli	a5,a6,0x20
ffffffffc02018a6:	9381                	srli	a5,a5,0x20
ffffffffc02018a8:	00a7ee63          	bltu	a5,a0,ffffffffc02018c4 <default_alloc_pages+0x32>
ffffffffc02018ac:	87ae                	mv	a5,a1
ffffffffc02018ae:	a801                	j	ffffffffc02018be <default_alloc_pages+0x2c>
ffffffffc02018b0:	ff87a703          	lw	a4,-8(a5)
ffffffffc02018b4:	02071693          	slli	a3,a4,0x20
ffffffffc02018b8:	9281                	srli	a3,a3,0x20
ffffffffc02018ba:	00c6f763          	bgeu	a3,a2,ffffffffc02018c8 <default_alloc_pages+0x36>
ffffffffc02018be:	679c                	ld	a5,8(a5)
ffffffffc02018c0:	feb798e3          	bne	a5,a1,ffffffffc02018b0 <default_alloc_pages+0x1e>
ffffffffc02018c4:	4501                	li	a0,0
ffffffffc02018c6:	8082                	ret
ffffffffc02018c8:	0007b883          	ld	a7,0(a5)
ffffffffc02018cc:	0087b303          	ld	t1,8(a5)
ffffffffc02018d0:	fe878513          	addi	a0,a5,-24
ffffffffc02018d4:	00060e1b          	sext.w	t3,a2
ffffffffc02018d8:	0068b423          	sd	t1,8(a7) # fffffffffff80008 <end+0x3fd78b68>
ffffffffc02018dc:	01133023          	sd	a7,0(t1)
ffffffffc02018e0:	02d67b63          	bgeu	a2,a3,ffffffffc0201916 <default_alloc_pages+0x84>
ffffffffc02018e4:	00261693          	slli	a3,a2,0x2
ffffffffc02018e8:	96b2                	add	a3,a3,a2
ffffffffc02018ea:	068e                	slli	a3,a3,0x3
ffffffffc02018ec:	96aa                	add	a3,a3,a0
ffffffffc02018ee:	41c7073b          	subw	a4,a4,t3
ffffffffc02018f2:	ca98                	sw	a4,16(a3)
ffffffffc02018f4:	00868613          	addi	a2,a3,8
ffffffffc02018f8:	4709                	li	a4,2
ffffffffc02018fa:	40e6302f          	amoor.d	zero,a4,(a2)
ffffffffc02018fe:	0088b703          	ld	a4,8(a7)
ffffffffc0201902:	01868613          	addi	a2,a3,24
ffffffffc0201906:	0105a803          	lw	a6,16(a1)
ffffffffc020190a:	e310                	sd	a2,0(a4)
ffffffffc020190c:	00c8b423          	sd	a2,8(a7)
ffffffffc0201910:	f298                	sd	a4,32(a3)
ffffffffc0201912:	0116bc23          	sd	a7,24(a3)
ffffffffc0201916:	41c8083b          	subw	a6,a6,t3
ffffffffc020191a:	0105a823          	sw	a6,16(a1)
ffffffffc020191e:	5775                	li	a4,-3
ffffffffc0201920:	17c1                	addi	a5,a5,-16
ffffffffc0201922:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0201926:	8082                	ret
ffffffffc0201928:	1141                	addi	sp,sp,-16
ffffffffc020192a:	00001697          	auipc	a3,0x1
ffffffffc020192e:	4c668693          	addi	a3,a3,1222 # ffffffffc0202df0 <commands+0xb88>
ffffffffc0201932:	00001617          	auipc	a2,0x1
ffffffffc0201936:	16660613          	addi	a2,a2,358 # ffffffffc0202a98 <commands+0x830>
ffffffffc020193a:	06200593          	li	a1,98
ffffffffc020193e:	00001517          	auipc	a0,0x1
ffffffffc0201942:	17250513          	addi	a0,a0,370 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201946:	e406                	sd	ra,8(sp)
ffffffffc0201948:	819fe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc020194c <default_init_memmap>:
ffffffffc020194c:	1141                	addi	sp,sp,-16
ffffffffc020194e:	e406                	sd	ra,8(sp)
ffffffffc0201950:	c9e1                	beqz	a1,ffffffffc0201a20 <default_init_memmap+0xd4>
ffffffffc0201952:	00259693          	slli	a3,a1,0x2
ffffffffc0201956:	96ae                	add	a3,a3,a1
ffffffffc0201958:	068e                	slli	a3,a3,0x3
ffffffffc020195a:	96aa                	add	a3,a3,a0
ffffffffc020195c:	87aa                	mv	a5,a0
ffffffffc020195e:	00d50f63          	beq	a0,a3,ffffffffc020197c <default_init_memmap+0x30>
ffffffffc0201962:	6798                	ld	a4,8(a5)
ffffffffc0201964:	8b05                	andi	a4,a4,1
ffffffffc0201966:	cf49                	beqz	a4,ffffffffc0201a00 <default_init_memmap+0xb4>
ffffffffc0201968:	0007a823          	sw	zero,16(a5)
ffffffffc020196c:	0007b423          	sd	zero,8(a5)
ffffffffc0201970:	0007a023          	sw	zero,0(a5)
ffffffffc0201974:	02878793          	addi	a5,a5,40
ffffffffc0201978:	fed795e3          	bne	a5,a3,ffffffffc0201962 <default_init_memmap+0x16>
ffffffffc020197c:	2581                	sext.w	a1,a1
ffffffffc020197e:	c90c                	sw	a1,16(a0)
ffffffffc0201980:	4789                	li	a5,2
ffffffffc0201982:	00850713          	addi	a4,a0,8
ffffffffc0201986:	40f7302f          	amoor.d	zero,a5,(a4)
ffffffffc020198a:	00005697          	auipc	a3,0x5
ffffffffc020198e:	69e68693          	addi	a3,a3,1694 # ffffffffc0207028 <free_area>
ffffffffc0201992:	4a98                	lw	a4,16(a3)
ffffffffc0201994:	669c                	ld	a5,8(a3)
ffffffffc0201996:	01850613          	addi	a2,a0,24
ffffffffc020199a:	9db9                	addw	a1,a1,a4
ffffffffc020199c:	ca8c                	sw	a1,16(a3)
ffffffffc020199e:	04d78a63          	beq	a5,a3,ffffffffc02019f2 <default_init_memmap+0xa6>
ffffffffc02019a2:	fe878713          	addi	a4,a5,-24
ffffffffc02019a6:	0006b803          	ld	a6,0(a3)
ffffffffc02019aa:	4581                	li	a1,0
ffffffffc02019ac:	00e56a63          	bltu	a0,a4,ffffffffc02019c0 <default_init_memmap+0x74>
ffffffffc02019b0:	6798                	ld	a4,8(a5)
ffffffffc02019b2:	02d70263          	beq	a4,a3,ffffffffc02019d6 <default_init_memmap+0x8a>
ffffffffc02019b6:	87ba                	mv	a5,a4
ffffffffc02019b8:	fe878713          	addi	a4,a5,-24
ffffffffc02019bc:	fee57ae3          	bgeu	a0,a4,ffffffffc02019b0 <default_init_memmap+0x64>
ffffffffc02019c0:	c199                	beqz	a1,ffffffffc02019c6 <default_init_memmap+0x7a>
ffffffffc02019c2:	0106b023          	sd	a6,0(a3)
ffffffffc02019c6:	6398                	ld	a4,0(a5)
ffffffffc02019c8:	60a2                	ld	ra,8(sp)
ffffffffc02019ca:	e390                	sd	a2,0(a5)
ffffffffc02019cc:	e710                	sd	a2,8(a4)
ffffffffc02019ce:	f11c                	sd	a5,32(a0)
ffffffffc02019d0:	ed18                	sd	a4,24(a0)
ffffffffc02019d2:	0141                	addi	sp,sp,16
ffffffffc02019d4:	8082                	ret
ffffffffc02019d6:	e790                	sd	a2,8(a5)
ffffffffc02019d8:	f114                	sd	a3,32(a0)
ffffffffc02019da:	6798                	ld	a4,8(a5)
ffffffffc02019dc:	ed1c                	sd	a5,24(a0)
ffffffffc02019de:	00d70663          	beq	a4,a3,ffffffffc02019ea <default_init_memmap+0x9e>
ffffffffc02019e2:	8832                	mv	a6,a2
ffffffffc02019e4:	4585                	li	a1,1
ffffffffc02019e6:	87ba                	mv	a5,a4
ffffffffc02019e8:	bfc1                	j	ffffffffc02019b8 <default_init_memmap+0x6c>
ffffffffc02019ea:	60a2                	ld	ra,8(sp)
ffffffffc02019ec:	e290                	sd	a2,0(a3)
ffffffffc02019ee:	0141                	addi	sp,sp,16
ffffffffc02019f0:	8082                	ret
ffffffffc02019f2:	60a2                	ld	ra,8(sp)
ffffffffc02019f4:	e390                	sd	a2,0(a5)
ffffffffc02019f6:	e790                	sd	a2,8(a5)
ffffffffc02019f8:	f11c                	sd	a5,32(a0)
ffffffffc02019fa:	ed1c                	sd	a5,24(a0)
ffffffffc02019fc:	0141                	addi	sp,sp,16
ffffffffc02019fe:	8082                	ret
ffffffffc0201a00:	00001697          	auipc	a3,0x1
ffffffffc0201a04:	42068693          	addi	a3,a3,1056 # ffffffffc0202e20 <commands+0xbb8>
ffffffffc0201a08:	00001617          	auipc	a2,0x1
ffffffffc0201a0c:	09060613          	addi	a2,a2,144 # ffffffffc0202a98 <commands+0x830>
ffffffffc0201a10:	04900593          	li	a1,73
ffffffffc0201a14:	00001517          	auipc	a0,0x1
ffffffffc0201a18:	09c50513          	addi	a0,a0,156 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201a1c:	f44fe0ef          	jal	ra,ffffffffc0200160 <__panic>
ffffffffc0201a20:	00001697          	auipc	a3,0x1
ffffffffc0201a24:	3d068693          	addi	a3,a3,976 # ffffffffc0202df0 <commands+0xb88>
ffffffffc0201a28:	00001617          	auipc	a2,0x1
ffffffffc0201a2c:	07060613          	addi	a2,a2,112 # ffffffffc0202a98 <commands+0x830>
ffffffffc0201a30:	04600593          	li	a1,70
ffffffffc0201a34:	00001517          	auipc	a0,0x1
ffffffffc0201a38:	07c50513          	addi	a0,a0,124 # ffffffffc0202ab0 <commands+0x848>
ffffffffc0201a3c:	f24fe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0201a40 <strlen>:
ffffffffc0201a40:	00054783          	lbu	a5,0(a0)
ffffffffc0201a44:	872a                	mv	a4,a0
ffffffffc0201a46:	4501                	li	a0,0
ffffffffc0201a48:	cb81                	beqz	a5,ffffffffc0201a58 <strlen+0x18>
ffffffffc0201a4a:	0505                	addi	a0,a0,1
ffffffffc0201a4c:	00a707b3          	add	a5,a4,a0
ffffffffc0201a50:	0007c783          	lbu	a5,0(a5)
ffffffffc0201a54:	fbfd                	bnez	a5,ffffffffc0201a4a <strlen+0xa>
ffffffffc0201a56:	8082                	ret
ffffffffc0201a58:	8082                	ret

ffffffffc0201a5a <strnlen>:
ffffffffc0201a5a:	4781                	li	a5,0
ffffffffc0201a5c:	e589                	bnez	a1,ffffffffc0201a66 <strnlen+0xc>
ffffffffc0201a5e:	a811                	j	ffffffffc0201a72 <strnlen+0x18>
ffffffffc0201a60:	0785                	addi	a5,a5,1
ffffffffc0201a62:	00f58863          	beq	a1,a5,ffffffffc0201a72 <strnlen+0x18>
ffffffffc0201a66:	00f50733          	add	a4,a0,a5
ffffffffc0201a6a:	00074703          	lbu	a4,0(a4)
ffffffffc0201a6e:	fb6d                	bnez	a4,ffffffffc0201a60 <strnlen+0x6>
ffffffffc0201a70:	85be                	mv	a1,a5
ffffffffc0201a72:	852e                	mv	a0,a1
ffffffffc0201a74:	8082                	ret

ffffffffc0201a76 <strcmp>:
ffffffffc0201a76:	00054783          	lbu	a5,0(a0)
ffffffffc0201a7a:	0005c703          	lbu	a4,0(a1)
ffffffffc0201a7e:	cb89                	beqz	a5,ffffffffc0201a90 <strcmp+0x1a>
ffffffffc0201a80:	0505                	addi	a0,a0,1
ffffffffc0201a82:	0585                	addi	a1,a1,1
ffffffffc0201a84:	fee789e3          	beq	a5,a4,ffffffffc0201a76 <strcmp>
ffffffffc0201a88:	0007851b          	sext.w	a0,a5
ffffffffc0201a8c:	9d19                	subw	a0,a0,a4
ffffffffc0201a8e:	8082                	ret
ffffffffc0201a90:	4501                	li	a0,0
ffffffffc0201a92:	bfed                	j	ffffffffc0201a8c <strcmp+0x16>

ffffffffc0201a94 <strncmp>:
ffffffffc0201a94:	c20d                	beqz	a2,ffffffffc0201ab6 <strncmp+0x22>
ffffffffc0201a96:	962e                	add	a2,a2,a1
ffffffffc0201a98:	a031                	j	ffffffffc0201aa4 <strncmp+0x10>
ffffffffc0201a9a:	0505                	addi	a0,a0,1
ffffffffc0201a9c:	00e79a63          	bne	a5,a4,ffffffffc0201ab0 <strncmp+0x1c>
ffffffffc0201aa0:	00b60b63          	beq	a2,a1,ffffffffc0201ab6 <strncmp+0x22>
ffffffffc0201aa4:	00054783          	lbu	a5,0(a0)
ffffffffc0201aa8:	0585                	addi	a1,a1,1
ffffffffc0201aaa:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201aae:	f7f5                	bnez	a5,ffffffffc0201a9a <strncmp+0x6>
ffffffffc0201ab0:	40e7853b          	subw	a0,a5,a4
ffffffffc0201ab4:	8082                	ret
ffffffffc0201ab6:	4501                	li	a0,0
ffffffffc0201ab8:	8082                	ret

ffffffffc0201aba <strchr>:
ffffffffc0201aba:	00054783          	lbu	a5,0(a0)
ffffffffc0201abe:	c799                	beqz	a5,ffffffffc0201acc <strchr+0x12>
ffffffffc0201ac0:	00f58763          	beq	a1,a5,ffffffffc0201ace <strchr+0x14>
ffffffffc0201ac4:	00154783          	lbu	a5,1(a0)
ffffffffc0201ac8:	0505                	addi	a0,a0,1
ffffffffc0201aca:	fbfd                	bnez	a5,ffffffffc0201ac0 <strchr+0x6>
ffffffffc0201acc:	4501                	li	a0,0
ffffffffc0201ace:	8082                	ret

ffffffffc0201ad0 <memset>:
ffffffffc0201ad0:	ca01                	beqz	a2,ffffffffc0201ae0 <memset+0x10>
ffffffffc0201ad2:	962a                	add	a2,a2,a0
ffffffffc0201ad4:	87aa                	mv	a5,a0
ffffffffc0201ad6:	0785                	addi	a5,a5,1
ffffffffc0201ad8:	feb78fa3          	sb	a1,-1(a5)
ffffffffc0201adc:	fec79de3          	bne	a5,a2,ffffffffc0201ad6 <memset+0x6>
ffffffffc0201ae0:	8082                	ret

ffffffffc0201ae2 <printnum>:
ffffffffc0201ae2:	02069813          	slli	a6,a3,0x20
ffffffffc0201ae6:	7179                	addi	sp,sp,-48
ffffffffc0201ae8:	02085813          	srli	a6,a6,0x20
ffffffffc0201aec:	e052                	sd	s4,0(sp)
ffffffffc0201aee:	03067a33          	remu	s4,a2,a6
ffffffffc0201af2:	f022                	sd	s0,32(sp)
ffffffffc0201af4:	ec26                	sd	s1,24(sp)
ffffffffc0201af6:	e84a                	sd	s2,16(sp)
ffffffffc0201af8:	f406                	sd	ra,40(sp)
ffffffffc0201afa:	e44e                	sd	s3,8(sp)
ffffffffc0201afc:	84aa                	mv	s1,a0
ffffffffc0201afe:	892e                	mv	s2,a1
ffffffffc0201b00:	fff7041b          	addiw	s0,a4,-1
ffffffffc0201b04:	2a01                	sext.w	s4,s4
ffffffffc0201b06:	03067e63          	bgeu	a2,a6,ffffffffc0201b42 <printnum+0x60>
ffffffffc0201b0a:	89be                	mv	s3,a5
ffffffffc0201b0c:	00805763          	blez	s0,ffffffffc0201b1a <printnum+0x38>
ffffffffc0201b10:	347d                	addiw	s0,s0,-1
ffffffffc0201b12:	85ca                	mv	a1,s2
ffffffffc0201b14:	854e                	mv	a0,s3
ffffffffc0201b16:	9482                	jalr	s1
ffffffffc0201b18:	fc65                	bnez	s0,ffffffffc0201b10 <printnum+0x2e>
ffffffffc0201b1a:	1a02                	slli	s4,s4,0x20
ffffffffc0201b1c:	00001797          	auipc	a5,0x1
ffffffffc0201b20:	36478793          	addi	a5,a5,868 # ffffffffc0202e80 <default_pmm_manager+0x38>
ffffffffc0201b24:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201b28:	9a3e                	add	s4,s4,a5
ffffffffc0201b2a:	7402                	ld	s0,32(sp)
ffffffffc0201b2c:	000a4503          	lbu	a0,0(s4)
ffffffffc0201b30:	70a2                	ld	ra,40(sp)
ffffffffc0201b32:	69a2                	ld	s3,8(sp)
ffffffffc0201b34:	6a02                	ld	s4,0(sp)
ffffffffc0201b36:	85ca                	mv	a1,s2
ffffffffc0201b38:	87a6                	mv	a5,s1
ffffffffc0201b3a:	6942                	ld	s2,16(sp)
ffffffffc0201b3c:	64e2                	ld	s1,24(sp)
ffffffffc0201b3e:	6145                	addi	sp,sp,48
ffffffffc0201b40:	8782                	jr	a5
ffffffffc0201b42:	03065633          	divu	a2,a2,a6
ffffffffc0201b46:	8722                	mv	a4,s0
ffffffffc0201b48:	f9bff0ef          	jal	ra,ffffffffc0201ae2 <printnum>
ffffffffc0201b4c:	b7f9                	j	ffffffffc0201b1a <printnum+0x38>

ffffffffc0201b4e <vprintfmt>:
ffffffffc0201b4e:	7119                	addi	sp,sp,-128
ffffffffc0201b50:	f4a6                	sd	s1,104(sp)
ffffffffc0201b52:	f0ca                	sd	s2,96(sp)
ffffffffc0201b54:	ecce                	sd	s3,88(sp)
ffffffffc0201b56:	e8d2                	sd	s4,80(sp)
ffffffffc0201b58:	e4d6                	sd	s5,72(sp)
ffffffffc0201b5a:	e0da                	sd	s6,64(sp)
ffffffffc0201b5c:	fc5e                	sd	s7,56(sp)
ffffffffc0201b5e:	f06a                	sd	s10,32(sp)
ffffffffc0201b60:	fc86                	sd	ra,120(sp)
ffffffffc0201b62:	f8a2                	sd	s0,112(sp)
ffffffffc0201b64:	f862                	sd	s8,48(sp)
ffffffffc0201b66:	f466                	sd	s9,40(sp)
ffffffffc0201b68:	ec6e                	sd	s11,24(sp)
ffffffffc0201b6a:	892a                	mv	s2,a0
ffffffffc0201b6c:	84ae                	mv	s1,a1
ffffffffc0201b6e:	8d32                	mv	s10,a2
ffffffffc0201b70:	8a36                	mv	s4,a3
ffffffffc0201b72:	02500993          	li	s3,37
ffffffffc0201b76:	5b7d                	li	s6,-1
ffffffffc0201b78:	00001a97          	auipc	s5,0x1
ffffffffc0201b7c:	33ca8a93          	addi	s5,s5,828 # ffffffffc0202eb4 <default_pmm_manager+0x6c>
ffffffffc0201b80:	00001b97          	auipc	s7,0x1
ffffffffc0201b84:	510b8b93          	addi	s7,s7,1296 # ffffffffc0203090 <error_string>
ffffffffc0201b88:	000d4503          	lbu	a0,0(s10)
ffffffffc0201b8c:	001d0413          	addi	s0,s10,1
ffffffffc0201b90:	01350a63          	beq	a0,s3,ffffffffc0201ba4 <vprintfmt+0x56>
ffffffffc0201b94:	c121                	beqz	a0,ffffffffc0201bd4 <vprintfmt+0x86>
ffffffffc0201b96:	85a6                	mv	a1,s1
ffffffffc0201b98:	0405                	addi	s0,s0,1
ffffffffc0201b9a:	9902                	jalr	s2
ffffffffc0201b9c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201ba0:	ff351ae3          	bne	a0,s3,ffffffffc0201b94 <vprintfmt+0x46>
ffffffffc0201ba4:	00044603          	lbu	a2,0(s0)
ffffffffc0201ba8:	02000793          	li	a5,32
ffffffffc0201bac:	4c81                	li	s9,0
ffffffffc0201bae:	4881                	li	a7,0
ffffffffc0201bb0:	5c7d                	li	s8,-1
ffffffffc0201bb2:	5dfd                	li	s11,-1
ffffffffc0201bb4:	05500513          	li	a0,85
ffffffffc0201bb8:	4825                	li	a6,9
ffffffffc0201bba:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201bbe:	0ff5f593          	zext.b	a1,a1
ffffffffc0201bc2:	00140d13          	addi	s10,s0,1
ffffffffc0201bc6:	04b56263          	bltu	a0,a1,ffffffffc0201c0a <vprintfmt+0xbc>
ffffffffc0201bca:	058a                	slli	a1,a1,0x2
ffffffffc0201bcc:	95d6                	add	a1,a1,s5
ffffffffc0201bce:	4194                	lw	a3,0(a1)
ffffffffc0201bd0:	96d6                	add	a3,a3,s5
ffffffffc0201bd2:	8682                	jr	a3
ffffffffc0201bd4:	70e6                	ld	ra,120(sp)
ffffffffc0201bd6:	7446                	ld	s0,112(sp)
ffffffffc0201bd8:	74a6                	ld	s1,104(sp)
ffffffffc0201bda:	7906                	ld	s2,96(sp)
ffffffffc0201bdc:	69e6                	ld	s3,88(sp)
ffffffffc0201bde:	6a46                	ld	s4,80(sp)
ffffffffc0201be0:	6aa6                	ld	s5,72(sp)
ffffffffc0201be2:	6b06                	ld	s6,64(sp)
ffffffffc0201be4:	7be2                	ld	s7,56(sp)
ffffffffc0201be6:	7c42                	ld	s8,48(sp)
ffffffffc0201be8:	7ca2                	ld	s9,40(sp)
ffffffffc0201bea:	7d02                	ld	s10,32(sp)
ffffffffc0201bec:	6de2                	ld	s11,24(sp)
ffffffffc0201bee:	6109                	addi	sp,sp,128
ffffffffc0201bf0:	8082                	ret
ffffffffc0201bf2:	87b2                	mv	a5,a2
ffffffffc0201bf4:	00144603          	lbu	a2,1(s0)
ffffffffc0201bf8:	846a                	mv	s0,s10
ffffffffc0201bfa:	00140d13          	addi	s10,s0,1
ffffffffc0201bfe:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201c02:	0ff5f593          	zext.b	a1,a1
ffffffffc0201c06:	fcb572e3          	bgeu	a0,a1,ffffffffc0201bca <vprintfmt+0x7c>
ffffffffc0201c0a:	85a6                	mv	a1,s1
ffffffffc0201c0c:	02500513          	li	a0,37
ffffffffc0201c10:	9902                	jalr	s2
ffffffffc0201c12:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201c16:	8d22                	mv	s10,s0
ffffffffc0201c18:	f73788e3          	beq	a5,s3,ffffffffc0201b88 <vprintfmt+0x3a>
ffffffffc0201c1c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201c20:	1d7d                	addi	s10,s10,-1
ffffffffc0201c22:	ff379de3          	bne	a5,s3,ffffffffc0201c1c <vprintfmt+0xce>
ffffffffc0201c26:	b78d                	j	ffffffffc0201b88 <vprintfmt+0x3a>
ffffffffc0201c28:	fd060c1b          	addiw	s8,a2,-48
ffffffffc0201c2c:	00144603          	lbu	a2,1(s0)
ffffffffc0201c30:	846a                	mv	s0,s10
ffffffffc0201c32:	fd06069b          	addiw	a3,a2,-48
ffffffffc0201c36:	0006059b          	sext.w	a1,a2
ffffffffc0201c3a:	02d86463          	bltu	a6,a3,ffffffffc0201c62 <vprintfmt+0x114>
ffffffffc0201c3e:	00144603          	lbu	a2,1(s0)
ffffffffc0201c42:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201c46:	0186873b          	addw	a4,a3,s8
ffffffffc0201c4a:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201c4e:	9f2d                	addw	a4,a4,a1
ffffffffc0201c50:	fd06069b          	addiw	a3,a2,-48
ffffffffc0201c54:	0405                	addi	s0,s0,1
ffffffffc0201c56:	fd070c1b          	addiw	s8,a4,-48
ffffffffc0201c5a:	0006059b          	sext.w	a1,a2
ffffffffc0201c5e:	fed870e3          	bgeu	a6,a3,ffffffffc0201c3e <vprintfmt+0xf0>
ffffffffc0201c62:	f40ddce3          	bgez	s11,ffffffffc0201bba <vprintfmt+0x6c>
ffffffffc0201c66:	8de2                	mv	s11,s8
ffffffffc0201c68:	5c7d                	li	s8,-1
ffffffffc0201c6a:	bf81                	j	ffffffffc0201bba <vprintfmt+0x6c>
ffffffffc0201c6c:	fffdc693          	not	a3,s11
ffffffffc0201c70:	96fd                	srai	a3,a3,0x3f
ffffffffc0201c72:	00ddfdb3          	and	s11,s11,a3
ffffffffc0201c76:	00144603          	lbu	a2,1(s0)
ffffffffc0201c7a:	2d81                	sext.w	s11,s11
ffffffffc0201c7c:	846a                	mv	s0,s10
ffffffffc0201c7e:	bf35                	j	ffffffffc0201bba <vprintfmt+0x6c>
ffffffffc0201c80:	000a2c03          	lw	s8,0(s4)
ffffffffc0201c84:	00144603          	lbu	a2,1(s0)
ffffffffc0201c88:	0a21                	addi	s4,s4,8
ffffffffc0201c8a:	846a                	mv	s0,s10
ffffffffc0201c8c:	bfd9                	j	ffffffffc0201c62 <vprintfmt+0x114>
ffffffffc0201c8e:	4705                	li	a4,1
ffffffffc0201c90:	008a0593          	addi	a1,s4,8
ffffffffc0201c94:	01174463          	blt	a4,a7,ffffffffc0201c9c <vprintfmt+0x14e>
ffffffffc0201c98:	1a088e63          	beqz	a7,ffffffffc0201e54 <vprintfmt+0x306>
ffffffffc0201c9c:	000a3603          	ld	a2,0(s4)
ffffffffc0201ca0:	46c1                	li	a3,16
ffffffffc0201ca2:	8a2e                	mv	s4,a1
ffffffffc0201ca4:	2781                	sext.w	a5,a5
ffffffffc0201ca6:	876e                	mv	a4,s11
ffffffffc0201ca8:	85a6                	mv	a1,s1
ffffffffc0201caa:	854a                	mv	a0,s2
ffffffffc0201cac:	e37ff0ef          	jal	ra,ffffffffc0201ae2 <printnum>
ffffffffc0201cb0:	bde1                	j	ffffffffc0201b88 <vprintfmt+0x3a>
ffffffffc0201cb2:	000a2503          	lw	a0,0(s4)
ffffffffc0201cb6:	85a6                	mv	a1,s1
ffffffffc0201cb8:	0a21                	addi	s4,s4,8
ffffffffc0201cba:	9902                	jalr	s2
ffffffffc0201cbc:	b5f1                	j	ffffffffc0201b88 <vprintfmt+0x3a>
ffffffffc0201cbe:	4705                	li	a4,1
ffffffffc0201cc0:	008a0593          	addi	a1,s4,8
ffffffffc0201cc4:	01174463          	blt	a4,a7,ffffffffc0201ccc <vprintfmt+0x17e>
ffffffffc0201cc8:	18088163          	beqz	a7,ffffffffc0201e4a <vprintfmt+0x2fc>
ffffffffc0201ccc:	000a3603          	ld	a2,0(s4)
ffffffffc0201cd0:	46a9                	li	a3,10
ffffffffc0201cd2:	8a2e                	mv	s4,a1
ffffffffc0201cd4:	bfc1                	j	ffffffffc0201ca4 <vprintfmt+0x156>
ffffffffc0201cd6:	00144603          	lbu	a2,1(s0)
ffffffffc0201cda:	4c85                	li	s9,1
ffffffffc0201cdc:	846a                	mv	s0,s10
ffffffffc0201cde:	bdf1                	j	ffffffffc0201bba <vprintfmt+0x6c>
ffffffffc0201ce0:	85a6                	mv	a1,s1
ffffffffc0201ce2:	02500513          	li	a0,37
ffffffffc0201ce6:	9902                	jalr	s2
ffffffffc0201ce8:	b545                	j	ffffffffc0201b88 <vprintfmt+0x3a>
ffffffffc0201cea:	00144603          	lbu	a2,1(s0)
ffffffffc0201cee:	2885                	addiw	a7,a7,1
ffffffffc0201cf0:	846a                	mv	s0,s10
ffffffffc0201cf2:	b5e1                	j	ffffffffc0201bba <vprintfmt+0x6c>
ffffffffc0201cf4:	4705                	li	a4,1
ffffffffc0201cf6:	008a0593          	addi	a1,s4,8
ffffffffc0201cfa:	01174463          	blt	a4,a7,ffffffffc0201d02 <vprintfmt+0x1b4>
ffffffffc0201cfe:	14088163          	beqz	a7,ffffffffc0201e40 <vprintfmt+0x2f2>
ffffffffc0201d02:	000a3603          	ld	a2,0(s4)
ffffffffc0201d06:	46a1                	li	a3,8
ffffffffc0201d08:	8a2e                	mv	s4,a1
ffffffffc0201d0a:	bf69                	j	ffffffffc0201ca4 <vprintfmt+0x156>
ffffffffc0201d0c:	03000513          	li	a0,48
ffffffffc0201d10:	85a6                	mv	a1,s1
ffffffffc0201d12:	e03e                	sd	a5,0(sp)
ffffffffc0201d14:	9902                	jalr	s2
ffffffffc0201d16:	85a6                	mv	a1,s1
ffffffffc0201d18:	07800513          	li	a0,120
ffffffffc0201d1c:	9902                	jalr	s2
ffffffffc0201d1e:	0a21                	addi	s4,s4,8
ffffffffc0201d20:	6782                	ld	a5,0(sp)
ffffffffc0201d22:	46c1                	li	a3,16
ffffffffc0201d24:	ff8a3603          	ld	a2,-8(s4)
ffffffffc0201d28:	bfb5                	j	ffffffffc0201ca4 <vprintfmt+0x156>
ffffffffc0201d2a:	000a3403          	ld	s0,0(s4)
ffffffffc0201d2e:	008a0713          	addi	a4,s4,8
ffffffffc0201d32:	e03a                	sd	a4,0(sp)
ffffffffc0201d34:	14040263          	beqz	s0,ffffffffc0201e78 <vprintfmt+0x32a>
ffffffffc0201d38:	0fb05763          	blez	s11,ffffffffc0201e26 <vprintfmt+0x2d8>
ffffffffc0201d3c:	02d00693          	li	a3,45
ffffffffc0201d40:	0cd79163          	bne	a5,a3,ffffffffc0201e02 <vprintfmt+0x2b4>
ffffffffc0201d44:	00044783          	lbu	a5,0(s0)
ffffffffc0201d48:	0007851b          	sext.w	a0,a5
ffffffffc0201d4c:	cf85                	beqz	a5,ffffffffc0201d84 <vprintfmt+0x236>
ffffffffc0201d4e:	00140a13          	addi	s4,s0,1
ffffffffc0201d52:	05e00413          	li	s0,94
ffffffffc0201d56:	000c4563          	bltz	s8,ffffffffc0201d60 <vprintfmt+0x212>
ffffffffc0201d5a:	3c7d                	addiw	s8,s8,-1
ffffffffc0201d5c:	036c0263          	beq	s8,s6,ffffffffc0201d80 <vprintfmt+0x232>
ffffffffc0201d60:	85a6                	mv	a1,s1
ffffffffc0201d62:	0e0c8e63          	beqz	s9,ffffffffc0201e5e <vprintfmt+0x310>
ffffffffc0201d66:	3781                	addiw	a5,a5,-32
ffffffffc0201d68:	0ef47b63          	bgeu	s0,a5,ffffffffc0201e5e <vprintfmt+0x310>
ffffffffc0201d6c:	03f00513          	li	a0,63
ffffffffc0201d70:	9902                	jalr	s2
ffffffffc0201d72:	000a4783          	lbu	a5,0(s4)
ffffffffc0201d76:	3dfd                	addiw	s11,s11,-1
ffffffffc0201d78:	0a05                	addi	s4,s4,1
ffffffffc0201d7a:	0007851b          	sext.w	a0,a5
ffffffffc0201d7e:	ffe1                	bnez	a5,ffffffffc0201d56 <vprintfmt+0x208>
ffffffffc0201d80:	01b05963          	blez	s11,ffffffffc0201d92 <vprintfmt+0x244>
ffffffffc0201d84:	3dfd                	addiw	s11,s11,-1
ffffffffc0201d86:	85a6                	mv	a1,s1
ffffffffc0201d88:	02000513          	li	a0,32
ffffffffc0201d8c:	9902                	jalr	s2
ffffffffc0201d8e:	fe0d9be3          	bnez	s11,ffffffffc0201d84 <vprintfmt+0x236>
ffffffffc0201d92:	6a02                	ld	s4,0(sp)
ffffffffc0201d94:	bbd5                	j	ffffffffc0201b88 <vprintfmt+0x3a>
ffffffffc0201d96:	4705                	li	a4,1
ffffffffc0201d98:	008a0c93          	addi	s9,s4,8
ffffffffc0201d9c:	01174463          	blt	a4,a7,ffffffffc0201da4 <vprintfmt+0x256>
ffffffffc0201da0:	08088d63          	beqz	a7,ffffffffc0201e3a <vprintfmt+0x2ec>
ffffffffc0201da4:	000a3403          	ld	s0,0(s4)
ffffffffc0201da8:	0a044d63          	bltz	s0,ffffffffc0201e62 <vprintfmt+0x314>
ffffffffc0201dac:	8622                	mv	a2,s0
ffffffffc0201dae:	8a66                	mv	s4,s9
ffffffffc0201db0:	46a9                	li	a3,10
ffffffffc0201db2:	bdcd                	j	ffffffffc0201ca4 <vprintfmt+0x156>
ffffffffc0201db4:	000a2783          	lw	a5,0(s4)
ffffffffc0201db8:	4719                	li	a4,6
ffffffffc0201dba:	0a21                	addi	s4,s4,8
ffffffffc0201dbc:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201dc0:	8fb5                	xor	a5,a5,a3
ffffffffc0201dc2:	40d786bb          	subw	a3,a5,a3
ffffffffc0201dc6:	02d74163          	blt	a4,a3,ffffffffc0201de8 <vprintfmt+0x29a>
ffffffffc0201dca:	00369793          	slli	a5,a3,0x3
ffffffffc0201dce:	97de                	add	a5,a5,s7
ffffffffc0201dd0:	639c                	ld	a5,0(a5)
ffffffffc0201dd2:	cb99                	beqz	a5,ffffffffc0201de8 <vprintfmt+0x29a>
ffffffffc0201dd4:	86be                	mv	a3,a5
ffffffffc0201dd6:	00001617          	auipc	a2,0x1
ffffffffc0201dda:	0da60613          	addi	a2,a2,218 # ffffffffc0202eb0 <default_pmm_manager+0x68>
ffffffffc0201dde:	85a6                	mv	a1,s1
ffffffffc0201de0:	854a                	mv	a0,s2
ffffffffc0201de2:	0ce000ef          	jal	ra,ffffffffc0201eb0 <printfmt>
ffffffffc0201de6:	b34d                	j	ffffffffc0201b88 <vprintfmt+0x3a>
ffffffffc0201de8:	00001617          	auipc	a2,0x1
ffffffffc0201dec:	0b860613          	addi	a2,a2,184 # ffffffffc0202ea0 <default_pmm_manager+0x58>
ffffffffc0201df0:	85a6                	mv	a1,s1
ffffffffc0201df2:	854a                	mv	a0,s2
ffffffffc0201df4:	0bc000ef          	jal	ra,ffffffffc0201eb0 <printfmt>
ffffffffc0201df8:	bb41                	j	ffffffffc0201b88 <vprintfmt+0x3a>
ffffffffc0201dfa:	00001417          	auipc	s0,0x1
ffffffffc0201dfe:	09e40413          	addi	s0,s0,158 # ffffffffc0202e98 <default_pmm_manager+0x50>
ffffffffc0201e02:	85e2                	mv	a1,s8
ffffffffc0201e04:	8522                	mv	a0,s0
ffffffffc0201e06:	e43e                	sd	a5,8(sp)
ffffffffc0201e08:	c53ff0ef          	jal	ra,ffffffffc0201a5a <strnlen>
ffffffffc0201e0c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201e10:	01b05b63          	blez	s11,ffffffffc0201e26 <vprintfmt+0x2d8>
ffffffffc0201e14:	67a2                	ld	a5,8(sp)
ffffffffc0201e16:	00078a1b          	sext.w	s4,a5
ffffffffc0201e1a:	3dfd                	addiw	s11,s11,-1
ffffffffc0201e1c:	85a6                	mv	a1,s1
ffffffffc0201e1e:	8552                	mv	a0,s4
ffffffffc0201e20:	9902                	jalr	s2
ffffffffc0201e22:	fe0d9ce3          	bnez	s11,ffffffffc0201e1a <vprintfmt+0x2cc>
ffffffffc0201e26:	00044783          	lbu	a5,0(s0)
ffffffffc0201e2a:	00140a13          	addi	s4,s0,1
ffffffffc0201e2e:	0007851b          	sext.w	a0,a5
ffffffffc0201e32:	d3a5                	beqz	a5,ffffffffc0201d92 <vprintfmt+0x244>
ffffffffc0201e34:	05e00413          	li	s0,94
ffffffffc0201e38:	bf39                	j	ffffffffc0201d56 <vprintfmt+0x208>
ffffffffc0201e3a:	000a2403          	lw	s0,0(s4)
ffffffffc0201e3e:	b7ad                	j	ffffffffc0201da8 <vprintfmt+0x25a>
ffffffffc0201e40:	000a6603          	lwu	a2,0(s4)
ffffffffc0201e44:	46a1                	li	a3,8
ffffffffc0201e46:	8a2e                	mv	s4,a1
ffffffffc0201e48:	bdb1                	j	ffffffffc0201ca4 <vprintfmt+0x156>
ffffffffc0201e4a:	000a6603          	lwu	a2,0(s4)
ffffffffc0201e4e:	46a9                	li	a3,10
ffffffffc0201e50:	8a2e                	mv	s4,a1
ffffffffc0201e52:	bd89                	j	ffffffffc0201ca4 <vprintfmt+0x156>
ffffffffc0201e54:	000a6603          	lwu	a2,0(s4)
ffffffffc0201e58:	46c1                	li	a3,16
ffffffffc0201e5a:	8a2e                	mv	s4,a1
ffffffffc0201e5c:	b5a1                	j	ffffffffc0201ca4 <vprintfmt+0x156>
ffffffffc0201e5e:	9902                	jalr	s2
ffffffffc0201e60:	bf09                	j	ffffffffc0201d72 <vprintfmt+0x224>
ffffffffc0201e62:	85a6                	mv	a1,s1
ffffffffc0201e64:	02d00513          	li	a0,45
ffffffffc0201e68:	e03e                	sd	a5,0(sp)
ffffffffc0201e6a:	9902                	jalr	s2
ffffffffc0201e6c:	6782                	ld	a5,0(sp)
ffffffffc0201e6e:	8a66                	mv	s4,s9
ffffffffc0201e70:	40800633          	neg	a2,s0
ffffffffc0201e74:	46a9                	li	a3,10
ffffffffc0201e76:	b53d                	j	ffffffffc0201ca4 <vprintfmt+0x156>
ffffffffc0201e78:	03b05163          	blez	s11,ffffffffc0201e9a <vprintfmt+0x34c>
ffffffffc0201e7c:	02d00693          	li	a3,45
ffffffffc0201e80:	f6d79de3          	bne	a5,a3,ffffffffc0201dfa <vprintfmt+0x2ac>
ffffffffc0201e84:	00001417          	auipc	s0,0x1
ffffffffc0201e88:	01440413          	addi	s0,s0,20 # ffffffffc0202e98 <default_pmm_manager+0x50>
ffffffffc0201e8c:	02800793          	li	a5,40
ffffffffc0201e90:	02800513          	li	a0,40
ffffffffc0201e94:	00140a13          	addi	s4,s0,1
ffffffffc0201e98:	bd6d                	j	ffffffffc0201d52 <vprintfmt+0x204>
ffffffffc0201e9a:	00001a17          	auipc	s4,0x1
ffffffffc0201e9e:	fffa0a13          	addi	s4,s4,-1 # ffffffffc0202e99 <default_pmm_manager+0x51>
ffffffffc0201ea2:	02800513          	li	a0,40
ffffffffc0201ea6:	02800793          	li	a5,40
ffffffffc0201eaa:	05e00413          	li	s0,94
ffffffffc0201eae:	b565                	j	ffffffffc0201d56 <vprintfmt+0x208>

ffffffffc0201eb0 <printfmt>:
ffffffffc0201eb0:	715d                	addi	sp,sp,-80
ffffffffc0201eb2:	02810313          	addi	t1,sp,40
ffffffffc0201eb6:	f436                	sd	a3,40(sp)
ffffffffc0201eb8:	869a                	mv	a3,t1
ffffffffc0201eba:	ec06                	sd	ra,24(sp)
ffffffffc0201ebc:	f83a                	sd	a4,48(sp)
ffffffffc0201ebe:	fc3e                	sd	a5,56(sp)
ffffffffc0201ec0:	e0c2                	sd	a6,64(sp)
ffffffffc0201ec2:	e4c6                	sd	a7,72(sp)
ffffffffc0201ec4:	e41a                	sd	t1,8(sp)
ffffffffc0201ec6:	c89ff0ef          	jal	ra,ffffffffc0201b4e <vprintfmt>
ffffffffc0201eca:	60e2                	ld	ra,24(sp)
ffffffffc0201ecc:	6161                	addi	sp,sp,80
ffffffffc0201ece:	8082                	ret

ffffffffc0201ed0 <readline>:
ffffffffc0201ed0:	715d                	addi	sp,sp,-80
ffffffffc0201ed2:	e486                	sd	ra,72(sp)
ffffffffc0201ed4:	e0a6                	sd	s1,64(sp)
ffffffffc0201ed6:	fc4a                	sd	s2,56(sp)
ffffffffc0201ed8:	f84e                	sd	s3,48(sp)
ffffffffc0201eda:	f452                	sd	s4,40(sp)
ffffffffc0201edc:	f056                	sd	s5,32(sp)
ffffffffc0201ede:	ec5a                	sd	s6,24(sp)
ffffffffc0201ee0:	e85e                	sd	s7,16(sp)
ffffffffc0201ee2:	c901                	beqz	a0,ffffffffc0201ef2 <readline+0x22>
ffffffffc0201ee4:	85aa                	mv	a1,a0
ffffffffc0201ee6:	00001517          	auipc	a0,0x1
ffffffffc0201eea:	fca50513          	addi	a0,a0,-54 # ffffffffc0202eb0 <default_pmm_manager+0x68>
ffffffffc0201eee:	9eafe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0201ef2:	4481                	li	s1,0
ffffffffc0201ef4:	497d                	li	s2,31
ffffffffc0201ef6:	49a1                	li	s3,8
ffffffffc0201ef8:	4aa9                	li	s5,10
ffffffffc0201efa:	4b35                	li	s6,13
ffffffffc0201efc:	00005b97          	auipc	s7,0x5
ffffffffc0201f00:	144b8b93          	addi	s7,s7,324 # ffffffffc0207040 <buf>
ffffffffc0201f04:	3fe00a13          	li	s4,1022
ffffffffc0201f08:	a48fe0ef          	jal	ra,ffffffffc0200150 <getchar>
ffffffffc0201f0c:	00054a63          	bltz	a0,ffffffffc0201f20 <readline+0x50>
ffffffffc0201f10:	00a95a63          	bge	s2,a0,ffffffffc0201f24 <readline+0x54>
ffffffffc0201f14:	029a5263          	bge	s4,s1,ffffffffc0201f38 <readline+0x68>
ffffffffc0201f18:	a38fe0ef          	jal	ra,ffffffffc0200150 <getchar>
ffffffffc0201f1c:	fe055ae3          	bgez	a0,ffffffffc0201f10 <readline+0x40>
ffffffffc0201f20:	4501                	li	a0,0
ffffffffc0201f22:	a091                	j	ffffffffc0201f66 <readline+0x96>
ffffffffc0201f24:	03351463          	bne	a0,s3,ffffffffc0201f4c <readline+0x7c>
ffffffffc0201f28:	e8a9                	bnez	s1,ffffffffc0201f7a <readline+0xaa>
ffffffffc0201f2a:	a26fe0ef          	jal	ra,ffffffffc0200150 <getchar>
ffffffffc0201f2e:	fe0549e3          	bltz	a0,ffffffffc0201f20 <readline+0x50>
ffffffffc0201f32:	fea959e3          	bge	s2,a0,ffffffffc0201f24 <readline+0x54>
ffffffffc0201f36:	4481                	li	s1,0
ffffffffc0201f38:	e42a                	sd	a0,8(sp)
ffffffffc0201f3a:	9d4fe0ef          	jal	ra,ffffffffc020010e <cputchar>
ffffffffc0201f3e:	6522                	ld	a0,8(sp)
ffffffffc0201f40:	009b87b3          	add	a5,s7,s1
ffffffffc0201f44:	2485                	addiw	s1,s1,1
ffffffffc0201f46:	00a78023          	sb	a0,0(a5)
ffffffffc0201f4a:	bf7d                	j	ffffffffc0201f08 <readline+0x38>
ffffffffc0201f4c:	01550463          	beq	a0,s5,ffffffffc0201f54 <readline+0x84>
ffffffffc0201f50:	fb651ce3          	bne	a0,s6,ffffffffc0201f08 <readline+0x38>
ffffffffc0201f54:	9bafe0ef          	jal	ra,ffffffffc020010e <cputchar>
ffffffffc0201f58:	00005517          	auipc	a0,0x5
ffffffffc0201f5c:	0e850513          	addi	a0,a0,232 # ffffffffc0207040 <buf>
ffffffffc0201f60:	94aa                	add	s1,s1,a0
ffffffffc0201f62:	00048023          	sb	zero,0(s1)
ffffffffc0201f66:	60a6                	ld	ra,72(sp)
ffffffffc0201f68:	6486                	ld	s1,64(sp)
ffffffffc0201f6a:	7962                	ld	s2,56(sp)
ffffffffc0201f6c:	79c2                	ld	s3,48(sp)
ffffffffc0201f6e:	7a22                	ld	s4,40(sp)
ffffffffc0201f70:	7a82                	ld	s5,32(sp)
ffffffffc0201f72:	6b62                	ld	s6,24(sp)
ffffffffc0201f74:	6bc2                	ld	s7,16(sp)
ffffffffc0201f76:	6161                	addi	sp,sp,80
ffffffffc0201f78:	8082                	ret
ffffffffc0201f7a:	4521                	li	a0,8
ffffffffc0201f7c:	992fe0ef          	jal	ra,ffffffffc020010e <cputchar>
ffffffffc0201f80:	34fd                	addiw	s1,s1,-1
ffffffffc0201f82:	b759                	j	ffffffffc0201f08 <readline+0x38>

ffffffffc0201f84 <sbi_console_putchar>:
ffffffffc0201f84:	4781                	li	a5,0
ffffffffc0201f86:	00005717          	auipc	a4,0x5
ffffffffc0201f8a:	09273703          	ld	a4,146(a4) # ffffffffc0207018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201f8e:	88ba                	mv	a7,a4
ffffffffc0201f90:	852a                	mv	a0,a0
ffffffffc0201f92:	85be                	mv	a1,a5
ffffffffc0201f94:	863e                	mv	a2,a5
ffffffffc0201f96:	00000073          	ecall
ffffffffc0201f9a:	87aa                	mv	a5,a0
ffffffffc0201f9c:	8082                	ret

ffffffffc0201f9e <sbi_set_timer>:
ffffffffc0201f9e:	4781                	li	a5,0
ffffffffc0201fa0:	00005717          	auipc	a4,0x5
ffffffffc0201fa4:	4f873703          	ld	a4,1272(a4) # ffffffffc0207498 <SBI_SET_TIMER>
ffffffffc0201fa8:	88ba                	mv	a7,a4
ffffffffc0201faa:	852a                	mv	a0,a0
ffffffffc0201fac:	85be                	mv	a1,a5
ffffffffc0201fae:	863e                	mv	a2,a5
ffffffffc0201fb0:	00000073          	ecall
ffffffffc0201fb4:	87aa                	mv	a5,a0
ffffffffc0201fb6:	8082                	ret

ffffffffc0201fb8 <sbi_console_getchar>:
ffffffffc0201fb8:	4501                	li	a0,0
ffffffffc0201fba:	00005797          	auipc	a5,0x5
ffffffffc0201fbe:	0567b783          	ld	a5,86(a5) # ffffffffc0207010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201fc2:	88be                	mv	a7,a5
ffffffffc0201fc4:	852a                	mv	a0,a0
ffffffffc0201fc6:	85aa                	mv	a1,a0
ffffffffc0201fc8:	862a                	mv	a2,a0
ffffffffc0201fca:	00000073          	ecall
ffffffffc0201fce:	852a                	mv	a0,a0
ffffffffc0201fd0:	2501                	sext.w	a0,a0
ffffffffc0201fd2:	8082                	ret

ffffffffc0201fd4 <sbi_shutdown>:
ffffffffc0201fd4:	4781                	li	a5,0
ffffffffc0201fd6:	00005717          	auipc	a4,0x5
ffffffffc0201fda:	04a73703          	ld	a4,74(a4) # ffffffffc0207020 <SBI_SHUTDOWN>
ffffffffc0201fde:	88ba                	mv	a7,a4
ffffffffc0201fe0:	853e                	mv	a0,a5
ffffffffc0201fe2:	85be                	mv	a1,a5
ffffffffc0201fe4:	863e                	mv	a2,a5
ffffffffc0201fe6:	00000073          	ecall
ffffffffc0201fea:	87aa                	mv	a5,a0
ffffffffc0201fec:	8082                	ret
