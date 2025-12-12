
obj/__user_cowtest.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
.text
.globl _start
_start:
    # call user-program function
    call umain
  800020:	12a000ef          	jal	ra,80014a <umain>
1:  j 1b
  800024:	a001                	j	800024 <_start+0x4>

0000000000800026 <__panic>:
#include <stdio.h>
#include <ulib.h>
#include <error.h>

void
__panic(const char *file, int line, const char *fmt, ...) {
  800026:	715d                	addi	sp,sp,-80
  800028:	8e2e                	mv	t3,a1
  80002a:	e822                	sd	s0,16(sp)
    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("user panic at %s:%d:\n    ", file, line);
  80002c:	85aa                	mv	a1,a0
__panic(const char *file, int line, const char *fmt, ...) {
  80002e:	8432                	mv	s0,a2
  800030:	fc3e                	sd	a5,56(sp)
    cprintf("user panic at %s:%d:\n    ", file, line);
  800032:	8672                	mv	a2,t3
    va_start(ap, fmt);
  800034:	103c                	addi	a5,sp,40
    cprintf("user panic at %s:%d:\n    ", file, line);
  800036:	00001517          	auipc	a0,0x1
  80003a:	eda50513          	addi	a0,a0,-294 # 800f10 <main+0x104>
__panic(const char *file, int line, const char *fmt, ...) {
  80003e:	ec06                	sd	ra,24(sp)
  800040:	f436                	sd	a3,40(sp)
  800042:	f83a                	sd	a4,48(sp)
  800044:	e0c2                	sd	a6,64(sp)
  800046:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800048:	e43e                	sd	a5,8(sp)
    cprintf("user panic at %s:%d:\n    ", file, line);
  80004a:	058000ef          	jal	ra,8000a2 <cprintf>
    vcprintf(fmt, ap);
  80004e:	65a2                	ld	a1,8(sp)
  800050:	8522                	mv	a0,s0
  800052:	030000ef          	jal	ra,800082 <vcprintf>
    cprintf("\n");
  800056:	00001517          	auipc	a0,0x1
  80005a:	2ea50513          	addi	a0,a0,746 # 801340 <error_string+0x1a8>
  80005e:	044000ef          	jal	ra,8000a2 <cprintf>
    va_end(ap);
    exit(-E_PANIC);
  800062:	5559                	li	a0,-10
  800064:	0ca000ef          	jal	ra,80012e <exit>

0000000000800068 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  800068:	1141                	addi	sp,sp,-16
  80006a:	e022                	sd	s0,0(sp)
  80006c:	e406                	sd	ra,8(sp)
  80006e:	842e                	mv	s0,a1
    sys_putc(c);
  800070:	0b8000ef          	jal	ra,800128 <sys_putc>
    (*cnt) ++;
  800074:	401c                	lw	a5,0(s0)
}
  800076:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
  800078:	2785                	addiw	a5,a5,1
  80007a:	c01c                	sw	a5,0(s0)
}
  80007c:	6402                	ld	s0,0(sp)
  80007e:	0141                	addi	sp,sp,16
  800080:	8082                	ret

0000000000800082 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
  800082:	1101                	addi	sp,sp,-32
  800084:	862a                	mv	a2,a0
  800086:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  800088:	00000517          	auipc	a0,0x0
  80008c:	fe050513          	addi	a0,a0,-32 # 800068 <cputch>
  800090:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
  800092:	ec06                	sd	ra,24(sp)
    int cnt = 0;
  800094:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  800096:	12c000ef          	jal	ra,8001c2 <vprintfmt>
    return cnt;
}
  80009a:	60e2                	ld	ra,24(sp)
  80009c:	4532                	lw	a0,12(sp)
  80009e:	6105                	addi	sp,sp,32
  8000a0:	8082                	ret

00000000008000a2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  8000a2:	711d                	addi	sp,sp,-96
    va_list ap;

    va_start(ap, fmt);
  8000a4:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
  8000a8:	8e2a                	mv	t3,a0
  8000aa:	f42e                	sd	a1,40(sp)
  8000ac:	f832                	sd	a2,48(sp)
  8000ae:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000b0:	00000517          	auipc	a0,0x0
  8000b4:	fb850513          	addi	a0,a0,-72 # 800068 <cputch>
  8000b8:	004c                	addi	a1,sp,4
  8000ba:	869a                	mv	a3,t1
  8000bc:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
  8000be:	ec06                	sd	ra,24(sp)
  8000c0:	e0ba                	sd	a4,64(sp)
  8000c2:	e4be                	sd	a5,72(sp)
  8000c4:	e8c2                	sd	a6,80(sp)
  8000c6:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
  8000c8:	e41a                	sd	t1,8(sp)
    int cnt = 0;
  8000ca:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000cc:	0f6000ef          	jal	ra,8001c2 <vprintfmt>
    int cnt = vcprintf(fmt, ap);
    va_end(ap);

    return cnt;
}
  8000d0:	60e2                	ld	ra,24(sp)
  8000d2:	4512                	lw	a0,4(sp)
  8000d4:	6125                	addi	sp,sp,96
  8000d6:	8082                	ret

00000000008000d8 <syscall>:
#include <syscall.h>

#define MAX_ARGS            5

static inline int
syscall(int64_t num, ...) {
  8000d8:	7175                	addi	sp,sp,-144
  8000da:	f8ba                	sd	a4,112(sp)
    va_list ap;
    va_start(ap, num);
    uint64_t a[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i ++) {
        a[i] = va_arg(ap, uint64_t);
  8000dc:	e0ba                	sd	a4,64(sp)
  8000de:	0118                	addi	a4,sp,128
syscall(int64_t num, ...) {
  8000e0:	e42a                	sd	a0,8(sp)
  8000e2:	ecae                	sd	a1,88(sp)
  8000e4:	f0b2                	sd	a2,96(sp)
  8000e6:	f4b6                	sd	a3,104(sp)
  8000e8:	fcbe                	sd	a5,120(sp)
  8000ea:	e142                	sd	a6,128(sp)
  8000ec:	e546                	sd	a7,136(sp)
        a[i] = va_arg(ap, uint64_t);
  8000ee:	f42e                	sd	a1,40(sp)
  8000f0:	f832                	sd	a2,48(sp)
  8000f2:	fc36                	sd	a3,56(sp)
  8000f4:	f03a                	sd	a4,32(sp)
  8000f6:	e4be                	sd	a5,72(sp)
    }
    va_end(ap);

    asm volatile (
  8000f8:	6522                	ld	a0,8(sp)
  8000fa:	75a2                	ld	a1,40(sp)
  8000fc:	7642                	ld	a2,48(sp)
  8000fe:	76e2                	ld	a3,56(sp)
  800100:	6706                	ld	a4,64(sp)
  800102:	67a6                	ld	a5,72(sp)
  800104:	00000073          	ecall
  800108:	00a13e23          	sd	a0,28(sp)
        "sd a0, %0"
        : "=m" (ret)
        : "m"(num), "m"(a[0]), "m"(a[1]), "m"(a[2]), "m"(a[3]), "m"(a[4])
        :"memory");
    return ret;
}
  80010c:	4572                	lw	a0,28(sp)
  80010e:	6149                	addi	sp,sp,144
  800110:	8082                	ret

0000000000800112 <sys_exit>:

int
sys_exit(int64_t error_code) {
  800112:	85aa                	mv	a1,a0
    return syscall(SYS_exit, error_code);
  800114:	4505                	li	a0,1
  800116:	b7c9                	j	8000d8 <syscall>

0000000000800118 <sys_fork>:
}

int
sys_fork(void) {
    return syscall(SYS_fork);
  800118:	4509                	li	a0,2
  80011a:	bf7d                	j	8000d8 <syscall>

000000000080011c <sys_wait>:
}

int
sys_wait(int64_t pid, int *store) {
  80011c:	862e                	mv	a2,a1
    return syscall(SYS_wait, pid, store);
  80011e:	85aa                	mv	a1,a0
  800120:	450d                	li	a0,3
  800122:	bf5d                	j	8000d8 <syscall>

0000000000800124 <sys_yield>:
}

int
sys_yield(void) {
    return syscall(SYS_yield);
  800124:	4529                	li	a0,10
  800126:	bf4d                	j	8000d8 <syscall>

0000000000800128 <sys_putc>:
sys_getpid(void) {
    return syscall(SYS_getpid);
}

int
sys_putc(int64_t c) {
  800128:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  80012a:	4579                	li	a0,30
  80012c:	b775                	j	8000d8 <syscall>

000000000080012e <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  80012e:	1141                	addi	sp,sp,-16
  800130:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  800132:	fe1ff0ef          	jal	ra,800112 <sys_exit>
    cprintf("BUG: exit failed.\n");
  800136:	00001517          	auipc	a0,0x1
  80013a:	dfa50513          	addi	a0,a0,-518 # 800f30 <main+0x124>
  80013e:	f65ff0ef          	jal	ra,8000a2 <cprintf>
    while (1);
  800142:	a001                	j	800142 <exit+0x14>

0000000000800144 <fork>:
}

int
fork(void) {
    return sys_fork();
  800144:	bfd1                	j	800118 <sys_fork>

0000000000800146 <waitpid>:
    return sys_wait(0, NULL);
}

int
waitpid(int pid, int *store) {
    return sys_wait(pid, store);
  800146:	bfd9                	j	80011c <sys_wait>

0000000000800148 <yield>:
}

void
yield(void) {
    sys_yield();
  800148:	bff1                	j	800124 <sys_yield>

000000000080014a <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  80014a:	1141                	addi	sp,sp,-16
  80014c:	e406                	sd	ra,8(sp)
    int ret = main();
  80014e:	4bf000ef          	jal	ra,800e0c <main>
    exit(ret);
  800152:	fddff0ef          	jal	ra,80012e <exit>

0000000000800156 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  800156:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  80015a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  80015c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800160:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  800162:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  800166:	f022                	sd	s0,32(sp)
  800168:	ec26                	sd	s1,24(sp)
  80016a:	e84a                	sd	s2,16(sp)
  80016c:	f406                	sd	ra,40(sp)
  80016e:	e44e                	sd	s3,8(sp)
  800170:	84aa                	mv	s1,a0
  800172:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800174:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  800178:	2a01                	sext.w	s4,s4
    if (num >= base) {
  80017a:	03067e63          	bgeu	a2,a6,8001b6 <printnum+0x60>
  80017e:	89be                	mv	s3,a5
        while (-- width > 0)
  800180:	00805763          	blez	s0,80018e <printnum+0x38>
  800184:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  800186:	85ca                	mv	a1,s2
  800188:	854e                	mv	a0,s3
  80018a:	9482                	jalr	s1
        while (-- width > 0)
  80018c:	fc65                	bnez	s0,800184 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  80018e:	1a02                	slli	s4,s4,0x20
  800190:	00001797          	auipc	a5,0x1
  800194:	db878793          	addi	a5,a5,-584 # 800f48 <main+0x13c>
  800198:	020a5a13          	srli	s4,s4,0x20
  80019c:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  80019e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001a0:	000a4503          	lbu	a0,0(s4)
}
  8001a4:	70a2                	ld	ra,40(sp)
  8001a6:	69a2                	ld	s3,8(sp)
  8001a8:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001aa:	85ca                	mv	a1,s2
  8001ac:	87a6                	mv	a5,s1
}
  8001ae:	6942                	ld	s2,16(sp)
  8001b0:	64e2                	ld	s1,24(sp)
  8001b2:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  8001b4:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  8001b6:	03065633          	divu	a2,a2,a6
  8001ba:	8722                	mv	a4,s0
  8001bc:	f9bff0ef          	jal	ra,800156 <printnum>
  8001c0:	b7f9                	j	80018e <printnum+0x38>

00000000008001c2 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  8001c2:	7119                	addi	sp,sp,-128
  8001c4:	f4a6                	sd	s1,104(sp)
  8001c6:	f0ca                	sd	s2,96(sp)
  8001c8:	ecce                	sd	s3,88(sp)
  8001ca:	e8d2                	sd	s4,80(sp)
  8001cc:	e4d6                	sd	s5,72(sp)
  8001ce:	e0da                	sd	s6,64(sp)
  8001d0:	fc5e                	sd	s7,56(sp)
  8001d2:	f06a                	sd	s10,32(sp)
  8001d4:	fc86                	sd	ra,120(sp)
  8001d6:	f8a2                	sd	s0,112(sp)
  8001d8:	f862                	sd	s8,48(sp)
  8001da:	f466                	sd	s9,40(sp)
  8001dc:	ec6e                	sd	s11,24(sp)
  8001de:	892a                	mv	s2,a0
  8001e0:	84ae                	mv	s1,a1
  8001e2:	8d32                	mv	s10,a2
  8001e4:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001e6:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
  8001ea:	5b7d                	li	s6,-1
  8001ec:	00001a97          	auipc	s5,0x1
  8001f0:	d90a8a93          	addi	s5,s5,-624 # 800f7c <main+0x170>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8001f4:	00001b97          	auipc	s7,0x1
  8001f8:	fa4b8b93          	addi	s7,s7,-92 # 801198 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001fc:	000d4503          	lbu	a0,0(s10)
  800200:	001d0413          	addi	s0,s10,1
  800204:	01350a63          	beq	a0,s3,800218 <vprintfmt+0x56>
            if (ch == '\0') {
  800208:	c121                	beqz	a0,800248 <vprintfmt+0x86>
            putch(ch, putdat);
  80020a:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80020c:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  80020e:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800210:	fff44503          	lbu	a0,-1(s0)
  800214:	ff351ae3          	bne	a0,s3,800208 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  800218:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  80021c:	02000793          	li	a5,32
        lflag = altflag = 0;
  800220:	4c81                	li	s9,0
  800222:	4881                	li	a7,0
        width = precision = -1;
  800224:	5c7d                	li	s8,-1
  800226:	5dfd                	li	s11,-1
  800228:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  80022c:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  80022e:	fdd6059b          	addiw	a1,a2,-35
  800232:	0ff5f593          	zext.b	a1,a1
  800236:	00140d13          	addi	s10,s0,1
  80023a:	04b56263          	bltu	a0,a1,80027e <vprintfmt+0xbc>
  80023e:	058a                	slli	a1,a1,0x2
  800240:	95d6                	add	a1,a1,s5
  800242:	4194                	lw	a3,0(a1)
  800244:	96d6                	add	a3,a3,s5
  800246:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  800248:	70e6                	ld	ra,120(sp)
  80024a:	7446                	ld	s0,112(sp)
  80024c:	74a6                	ld	s1,104(sp)
  80024e:	7906                	ld	s2,96(sp)
  800250:	69e6                	ld	s3,88(sp)
  800252:	6a46                	ld	s4,80(sp)
  800254:	6aa6                	ld	s5,72(sp)
  800256:	6b06                	ld	s6,64(sp)
  800258:	7be2                	ld	s7,56(sp)
  80025a:	7c42                	ld	s8,48(sp)
  80025c:	7ca2                	ld	s9,40(sp)
  80025e:	7d02                	ld	s10,32(sp)
  800260:	6de2                	ld	s11,24(sp)
  800262:	6109                	addi	sp,sp,128
  800264:	8082                	ret
            padc = '0';
  800266:	87b2                	mv	a5,a2
            goto reswitch;
  800268:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  80026c:	846a                	mv	s0,s10
  80026e:	00140d13          	addi	s10,s0,1
  800272:	fdd6059b          	addiw	a1,a2,-35
  800276:	0ff5f593          	zext.b	a1,a1
  80027a:	fcb572e3          	bgeu	a0,a1,80023e <vprintfmt+0x7c>
            putch('%', putdat);
  80027e:	85a6                	mv	a1,s1
  800280:	02500513          	li	a0,37
  800284:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  800286:	fff44783          	lbu	a5,-1(s0)
  80028a:	8d22                	mv	s10,s0
  80028c:	f73788e3          	beq	a5,s3,8001fc <vprintfmt+0x3a>
  800290:	ffed4783          	lbu	a5,-2(s10)
  800294:	1d7d                	addi	s10,s10,-1
  800296:	ff379de3          	bne	a5,s3,800290 <vprintfmt+0xce>
  80029a:	b78d                	j	8001fc <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  80029c:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  8002a0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  8002a4:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  8002a6:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  8002aa:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  8002ae:	02d86463          	bltu	a6,a3,8002d6 <vprintfmt+0x114>
                ch = *fmt;
  8002b2:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  8002b6:	002c169b          	slliw	a3,s8,0x2
  8002ba:	0186873b          	addw	a4,a3,s8
  8002be:	0017171b          	slliw	a4,a4,0x1
  8002c2:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  8002c4:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  8002c8:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  8002ca:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  8002ce:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  8002d2:	fed870e3          	bgeu	a6,a3,8002b2 <vprintfmt+0xf0>
            if (width < 0)
  8002d6:	f40ddce3          	bgez	s11,80022e <vprintfmt+0x6c>
                width = precision, precision = -1;
  8002da:	8de2                	mv	s11,s8
  8002dc:	5c7d                	li	s8,-1
  8002de:	bf81                	j	80022e <vprintfmt+0x6c>
            if (width < 0)
  8002e0:	fffdc693          	not	a3,s11
  8002e4:	96fd                	srai	a3,a3,0x3f
  8002e6:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  8002ea:	00144603          	lbu	a2,1(s0)
  8002ee:	2d81                	sext.w	s11,s11
  8002f0:	846a                	mv	s0,s10
            goto reswitch;
  8002f2:	bf35                	j	80022e <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  8002f4:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  8002f8:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  8002fc:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  8002fe:	846a                	mv	s0,s10
            goto process_precision;
  800300:	bfd9                	j	8002d6 <vprintfmt+0x114>
    if (lflag >= 2) {
  800302:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800304:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800308:	01174463          	blt	a4,a7,800310 <vprintfmt+0x14e>
    else if (lflag) {
  80030c:	1a088e63          	beqz	a7,8004c8 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  800310:	000a3603          	ld	a2,0(s4)
  800314:	46c1                	li	a3,16
  800316:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  800318:	2781                	sext.w	a5,a5
  80031a:	876e                	mv	a4,s11
  80031c:	85a6                	mv	a1,s1
  80031e:	854a                	mv	a0,s2
  800320:	e37ff0ef          	jal	ra,800156 <printnum>
            break;
  800324:	bde1                	j	8001fc <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  800326:	000a2503          	lw	a0,0(s4)
  80032a:	85a6                	mv	a1,s1
  80032c:	0a21                	addi	s4,s4,8
  80032e:	9902                	jalr	s2
            break;
  800330:	b5f1                	j	8001fc <vprintfmt+0x3a>
    if (lflag >= 2) {
  800332:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800334:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800338:	01174463          	blt	a4,a7,800340 <vprintfmt+0x17e>
    else if (lflag) {
  80033c:	18088163          	beqz	a7,8004be <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  800340:	000a3603          	ld	a2,0(s4)
  800344:	46a9                	li	a3,10
  800346:	8a2e                	mv	s4,a1
  800348:	bfc1                	j	800318 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  80034a:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  80034e:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  800350:	846a                	mv	s0,s10
            goto reswitch;
  800352:	bdf1                	j	80022e <vprintfmt+0x6c>
            putch(ch, putdat);
  800354:	85a6                	mv	a1,s1
  800356:	02500513          	li	a0,37
  80035a:	9902                	jalr	s2
            break;
  80035c:	b545                	j	8001fc <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  80035e:	00144603          	lbu	a2,1(s0)
            lflag ++;
  800362:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  800364:	846a                	mv	s0,s10
            goto reswitch;
  800366:	b5e1                	j	80022e <vprintfmt+0x6c>
    if (lflag >= 2) {
  800368:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80036a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80036e:	01174463          	blt	a4,a7,800376 <vprintfmt+0x1b4>
    else if (lflag) {
  800372:	14088163          	beqz	a7,8004b4 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  800376:	000a3603          	ld	a2,0(s4)
  80037a:	46a1                	li	a3,8
  80037c:	8a2e                	mv	s4,a1
  80037e:	bf69                	j	800318 <vprintfmt+0x156>
            putch('0', putdat);
  800380:	03000513          	li	a0,48
  800384:	85a6                	mv	a1,s1
  800386:	e03e                	sd	a5,0(sp)
  800388:	9902                	jalr	s2
            putch('x', putdat);
  80038a:	85a6                	mv	a1,s1
  80038c:	07800513          	li	a0,120
  800390:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800392:	0a21                	addi	s4,s4,8
            goto number;
  800394:	6782                	ld	a5,0(sp)
  800396:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800398:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  80039c:	bfb5                	j	800318 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  80039e:	000a3403          	ld	s0,0(s4)
  8003a2:	008a0713          	addi	a4,s4,8
  8003a6:	e03a                	sd	a4,0(sp)
  8003a8:	14040263          	beqz	s0,8004ec <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  8003ac:	0fb05763          	blez	s11,80049a <vprintfmt+0x2d8>
  8003b0:	02d00693          	li	a3,45
  8003b4:	0cd79163          	bne	a5,a3,800476 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003b8:	00044783          	lbu	a5,0(s0)
  8003bc:	0007851b          	sext.w	a0,a5
  8003c0:	cf85                	beqz	a5,8003f8 <vprintfmt+0x236>
  8003c2:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003c6:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003ca:	000c4563          	bltz	s8,8003d4 <vprintfmt+0x212>
  8003ce:	3c7d                	addiw	s8,s8,-1
  8003d0:	036c0263          	beq	s8,s6,8003f4 <vprintfmt+0x232>
                    putch('?', putdat);
  8003d4:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003d6:	0e0c8e63          	beqz	s9,8004d2 <vprintfmt+0x310>
  8003da:	3781                	addiw	a5,a5,-32
  8003dc:	0ef47b63          	bgeu	s0,a5,8004d2 <vprintfmt+0x310>
                    putch('?', putdat);
  8003e0:	03f00513          	li	a0,63
  8003e4:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003e6:	000a4783          	lbu	a5,0(s4)
  8003ea:	3dfd                	addiw	s11,s11,-1
  8003ec:	0a05                	addi	s4,s4,1
  8003ee:	0007851b          	sext.w	a0,a5
  8003f2:	ffe1                	bnez	a5,8003ca <vprintfmt+0x208>
            for (; width > 0; width --) {
  8003f4:	01b05963          	blez	s11,800406 <vprintfmt+0x244>
  8003f8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  8003fa:	85a6                	mv	a1,s1
  8003fc:	02000513          	li	a0,32
  800400:	9902                	jalr	s2
            for (; width > 0; width --) {
  800402:	fe0d9be3          	bnez	s11,8003f8 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  800406:	6a02                	ld	s4,0(sp)
  800408:	bbd5                	j	8001fc <vprintfmt+0x3a>
    if (lflag >= 2) {
  80040a:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80040c:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  800410:	01174463          	blt	a4,a7,800418 <vprintfmt+0x256>
    else if (lflag) {
  800414:	08088d63          	beqz	a7,8004ae <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  800418:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  80041c:	0a044d63          	bltz	s0,8004d6 <vprintfmt+0x314>
            num = getint(&ap, lflag);
  800420:	8622                	mv	a2,s0
  800422:	8a66                	mv	s4,s9
  800424:	46a9                	li	a3,10
  800426:	bdcd                	j	800318 <vprintfmt+0x156>
            err = va_arg(ap, int);
  800428:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  80042c:	4761                	li	a4,24
            err = va_arg(ap, int);
  80042e:	0a21                	addi	s4,s4,8
            if (err < 0) {
  800430:	41f7d69b          	sraiw	a3,a5,0x1f
  800434:	8fb5                	xor	a5,a5,a3
  800436:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  80043a:	02d74163          	blt	a4,a3,80045c <vprintfmt+0x29a>
  80043e:	00369793          	slli	a5,a3,0x3
  800442:	97de                	add	a5,a5,s7
  800444:	639c                	ld	a5,0(a5)
  800446:	cb99                	beqz	a5,80045c <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  800448:	86be                	mv	a3,a5
  80044a:	00001617          	auipc	a2,0x1
  80044e:	b2e60613          	addi	a2,a2,-1234 # 800f78 <main+0x16c>
  800452:	85a6                	mv	a1,s1
  800454:	854a                	mv	a0,s2
  800456:	0ce000ef          	jal	ra,800524 <printfmt>
  80045a:	b34d                	j	8001fc <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  80045c:	00001617          	auipc	a2,0x1
  800460:	b0c60613          	addi	a2,a2,-1268 # 800f68 <main+0x15c>
  800464:	85a6                	mv	a1,s1
  800466:	854a                	mv	a0,s2
  800468:	0bc000ef          	jal	ra,800524 <printfmt>
  80046c:	bb41                	j	8001fc <vprintfmt+0x3a>
                p = "(null)";
  80046e:	00001417          	auipc	s0,0x1
  800472:	af240413          	addi	s0,s0,-1294 # 800f60 <main+0x154>
                for (width -= strnlen(p, precision); width > 0; width --) {
  800476:	85e2                	mv	a1,s8
  800478:	8522                	mv	a0,s0
  80047a:	e43e                	sd	a5,8(sp)
  80047c:	0c8000ef          	jal	ra,800544 <strnlen>
  800480:	40ad8dbb          	subw	s11,s11,a0
  800484:	01b05b63          	blez	s11,80049a <vprintfmt+0x2d8>
                    putch(padc, putdat);
  800488:	67a2                	ld	a5,8(sp)
  80048a:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  80048e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  800490:	85a6                	mv	a1,s1
  800492:	8552                	mv	a0,s4
  800494:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  800496:	fe0d9ce3          	bnez	s11,80048e <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80049a:	00044783          	lbu	a5,0(s0)
  80049e:	00140a13          	addi	s4,s0,1
  8004a2:	0007851b          	sext.w	a0,a5
  8004a6:	d3a5                	beqz	a5,800406 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  8004a8:	05e00413          	li	s0,94
  8004ac:	bf39                	j	8003ca <vprintfmt+0x208>
        return va_arg(*ap, int);
  8004ae:	000a2403          	lw	s0,0(s4)
  8004b2:	b7ad                	j	80041c <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  8004b4:	000a6603          	lwu	a2,0(s4)
  8004b8:	46a1                	li	a3,8
  8004ba:	8a2e                	mv	s4,a1
  8004bc:	bdb1                	j	800318 <vprintfmt+0x156>
  8004be:	000a6603          	lwu	a2,0(s4)
  8004c2:	46a9                	li	a3,10
  8004c4:	8a2e                	mv	s4,a1
  8004c6:	bd89                	j	800318 <vprintfmt+0x156>
  8004c8:	000a6603          	lwu	a2,0(s4)
  8004cc:	46c1                	li	a3,16
  8004ce:	8a2e                	mv	s4,a1
  8004d0:	b5a1                	j	800318 <vprintfmt+0x156>
                    putch(ch, putdat);
  8004d2:	9902                	jalr	s2
  8004d4:	bf09                	j	8003e6 <vprintfmt+0x224>
                putch('-', putdat);
  8004d6:	85a6                	mv	a1,s1
  8004d8:	02d00513          	li	a0,45
  8004dc:	e03e                	sd	a5,0(sp)
  8004de:	9902                	jalr	s2
                num = -(long long)num;
  8004e0:	6782                	ld	a5,0(sp)
  8004e2:	8a66                	mv	s4,s9
  8004e4:	40800633          	neg	a2,s0
  8004e8:	46a9                	li	a3,10
  8004ea:	b53d                	j	800318 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  8004ec:	03b05163          	blez	s11,80050e <vprintfmt+0x34c>
  8004f0:	02d00693          	li	a3,45
  8004f4:	f6d79de3          	bne	a5,a3,80046e <vprintfmt+0x2ac>
                p = "(null)";
  8004f8:	00001417          	auipc	s0,0x1
  8004fc:	a6840413          	addi	s0,s0,-1432 # 800f60 <main+0x154>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800500:	02800793          	li	a5,40
  800504:	02800513          	li	a0,40
  800508:	00140a13          	addi	s4,s0,1
  80050c:	bd6d                	j	8003c6 <vprintfmt+0x204>
  80050e:	00001a17          	auipc	s4,0x1
  800512:	a53a0a13          	addi	s4,s4,-1453 # 800f61 <main+0x155>
  800516:	02800513          	li	a0,40
  80051a:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  80051e:	05e00413          	li	s0,94
  800522:	b565                	j	8003ca <vprintfmt+0x208>

0000000000800524 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800524:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  800526:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80052a:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  80052c:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80052e:	ec06                	sd	ra,24(sp)
  800530:	f83a                	sd	a4,48(sp)
  800532:	fc3e                	sd	a5,56(sp)
  800534:	e0c2                	sd	a6,64(sp)
  800536:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800538:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  80053a:	c89ff0ef          	jal	ra,8001c2 <vprintfmt>
}
  80053e:	60e2                	ld	ra,24(sp)
  800540:	6161                	addi	sp,sp,80
  800542:	8082                	ret

0000000000800544 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  800544:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  800546:	e589                	bnez	a1,800550 <strnlen+0xc>
  800548:	a811                	j	80055c <strnlen+0x18>
        cnt ++;
  80054a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  80054c:	00f58863          	beq	a1,a5,80055c <strnlen+0x18>
  800550:	00f50733          	add	a4,a0,a5
  800554:	00074703          	lbu	a4,0(a4)
  800558:	fb6d                	bnez	a4,80054a <strnlen+0x6>
  80055a:	85be                	mv	a1,a5
    }
    return cnt;
}
  80055c:	852e                	mv	a0,a1
  80055e:	8082                	ret

0000000000800560 <test_cow_read_same>:
int global_data_test7[1024];
int global_data_test8[512];

// Test 1: fork 后读一致性 - 验证父子进程初始数据共享
void test_cow_read_same(void)
{
  800560:	1101                	addi	sp,sp,-32
    cprintf("Test 1: READ CONSISTENCY (parent and child see same initial data)\n");
  800562:	00001517          	auipc	a0,0x1
  800566:	cfe50513          	addi	a0,a0,-770 # 801260 <error_string+0xc8>
{
  80056a:	e822                	sd	s0,16(sp)
  80056c:	ec06                	sd	ra,24(sp)
    cprintf("Test 1: READ CONSISTENCY (parent and child see same initial data)\n");
  80056e:	b35ff0ef          	jal	ra,8000a2 <cprintf>
    
    // 父进程初始化测试数据
    for (int i = 0; i < 512; i++)
  800572:	00002417          	auipc	s0,0x2
  800576:	a8e40413          	addi	s0,s0,-1394 # 802000 <global_data_test1>
  80057a:	6685                	lui	a3,0x1
    cprintf("Test 1: READ CONSISTENCY (parent and child see same initial data)\n");
  80057c:	8722                	mv	a4,s0
  80057e:	4785                	li	a5,1
    for (int i = 0; i < 512; i++)
  800580:	e0168693          	addi	a3,a3,-511 # e01 <_start-0x7ff21f>
    {
        global_data_test1[i] = i * 7 + 1;
  800584:	c31c                	sw	a5,0(a4)
    for (int i = 0; i < 512; i++)
  800586:	279d                	addiw	a5,a5,7
  800588:	0711                	addi	a4,a4,4
  80058a:	fed79de3          	bne	a5,a3,800584 <test_cow_read_same+0x24>
    }
    
    int pid = fork();
  80058e:	bb7ff0ef          	jal	ra,800144 <fork>
  800592:	85aa                	mv	a1,a0
    if (pid == 0)
  800594:	c105                	beqz	a0,8005b4 <test_cow_read_same+0x54>
        exit(0);
    }
    else
    {
        // 父进程：等待子进程
        assert(pid > 0);
  800596:	04a05563          	blez	a0,8005e0 <test_cow_read_same+0x80>
        int code;
        waitpid(pid, &code);
  80059a:	006c                	addi	a1,sp,12
  80059c:	babff0ef          	jal	ra,800146 <waitpid>
        cprintf("  [Parent] Test 1: PASS\n\n");
  8005a0:	00001517          	auipc	a0,0x1
  8005a4:	d8850513          	addi	a0,a0,-632 # 801328 <error_string+0x190>
  8005a8:	afbff0ef          	jal	ra,8000a2 <cprintf>
    }
}
  8005ac:	60e2                	ld	ra,24(sp)
  8005ae:	6442                	ld	s0,16(sp)
  8005b0:	6105                	addi	sp,sp,32
  8005b2:	8082                	ret
        for (int i = 0; i < 512; i++)
  8005b4:	6705                	lui	a4,0x1
  8005b6:	4785                	li	a5,1
  8005b8:	e0170713          	addi	a4,a4,-511 # e01 <_start-0x7ff21f>
            if (global_data_test1[i] != i * 7 + 1)
  8005bc:	4014                	lw	a3,0(s0)
  8005be:	00f68363          	beq	a3,a5,8005c4 <test_cow_read_same+0x64>
                errors++;
  8005c2:	2585                	addiw	a1,a1,1
        for (int i = 0; i < 512; i++)
  8005c4:	279d                	addiw	a5,a5,7
  8005c6:	0411                	addi	s0,s0,4
  8005c8:	fee79ae3          	bne	a5,a4,8005bc <test_cow_read_same+0x5c>
        if (errors == 0)
  8005cc:	e995                	bnez	a1,800600 <test_cow_read_same+0xa0>
            cprintf("  [Child]  Read check: PASS\n");
  8005ce:	00001517          	auipc	a0,0x1
  8005d2:	cda50513          	addi	a0,a0,-806 # 8012a8 <error_string+0x110>
  8005d6:	acdff0ef          	jal	ra,8000a2 <cprintf>
        exit(0);
  8005da:	4501                	li	a0,0
  8005dc:	b53ff0ef          	jal	ra,80012e <exit>
        assert(pid > 0);
  8005e0:	00001697          	auipc	a3,0x1
  8005e4:	d1868693          	addi	a3,a3,-744 # 8012f8 <error_string+0x160>
  8005e8:	00001617          	auipc	a2,0x1
  8005ec:	d1860613          	addi	a2,a2,-744 # 801300 <error_string+0x168>
  8005f0:	04800593          	li	a1,72
  8005f4:	00001517          	auipc	a0,0x1
  8005f8:	d2450513          	addi	a0,a0,-732 # 801318 <error_string+0x180>
  8005fc:	a2bff0ef          	jal	ra,800026 <__panic>
            cprintf("  [Child]  Read check: FAIL (errors=%d)\n", errors);
  800600:	00001517          	auipc	a0,0x1
  800604:	cc850513          	addi	a0,a0,-824 # 8012c8 <error_string+0x130>
  800608:	a9bff0ef          	jal	ra,8000a2 <cprintf>
  80060c:	b7f9                	j	8005da <test_cow_read_same+0x7a>

000000000080060e <test_cow_parent_write>:

// Test 2: 父进程写入后隔离 - 验证 COW 复制机制
void test_cow_parent_write(void)
{
  80060e:	715d                	addi	sp,sp,-80
    cprintf("Test 2: PARENT WRITE ISOLATION (child sees original data)\n");
  800610:	00001517          	auipc	a0,0x1
  800614:	d3850513          	addi	a0,a0,-712 # 801348 <error_string+0x1b0>
{
  800618:	e0a2                	sd	s0,64(sp)
  80061a:	e486                	sd	ra,72(sp)
  80061c:	fc26                	sd	s1,56(sp)
  80061e:	f84a                	sd	s2,48(sp)
  800620:	f44e                	sd	s3,40(sp)
  800622:	f052                	sd	s4,32(sp)
  800624:	ec56                	sd	s5,24(sp)
  800626:	00002417          	auipc	s0,0x2
  80062a:	1da40413          	addi	s0,s0,474 # 802800 <global_data_test2>
    cprintf("Test 2: PARENT WRITE ISOLATION (child sees original data)\n");
  80062e:	a75ff0ef          	jal	ra,8000a2 <cprintf>
  800632:	8722                	mv	a4,s0
  800634:	4789                	li	a5,2
    
    // 初始化数据
    for (int i = 0; i < 512; i++)
  800636:	60200693          	li	a3,1538
    {
        global_data_test2[i] = i * 3 + 2;
  80063a:	c31c                	sw	a5,0(a4)
    for (int i = 0; i < 512; i++)
  80063c:	278d                	addiw	a5,a5,3
  80063e:	0711                	addi	a4,a4,4
  800640:	fed79de3          	bne	a5,a3,80063a <test_cow_parent_write+0x2c>
    }
    
    int pid = fork();
  800644:	b01ff0ef          	jal	ra,800144 <fork>
  800648:	892a                	mv	s2,a0
    if (pid == 0)
  80064a:	00002717          	auipc	a4,0x2
  80064e:	1b670713          	addi	a4,a4,438 # 802800 <global_data_test2>
  800652:	06400793          	li	a5,100
        exit(0);
    }
    else
    {
        // 父进程：修改数据（触发 COW）
        for (int i = 0; i < 512; i++)
  800656:	66400693          	li	a3,1636
    if (pid == 0)
  80065a:	c525                	beqz	a0,8006c2 <test_cow_parent_write+0xb4>
        {
            global_data_test2[i] = i * 3 + 100;
  80065c:	c31c                	sw	a5,0(a4)
        for (int i = 0; i < 512; i++)
  80065e:	278d                	addiw	a5,a5,3
  800660:	0711                	addi	a4,a4,4
  800662:	fed79de3          	bne	a5,a3,80065c <test_cow_parent_write+0x4e>
  800666:	06400793          	li	a5,100
        }
        
        // 验证父进程看到新值
        int errors = 0;
  80066a:	4481                	li	s1,0
        for (int i = 0; i < 512; i++)
  80066c:	66400693          	li	a3,1636
        {
            if (global_data_test2[i] != i * 3 + 100)
  800670:	4018                	lw	a4,0(s0)
  800672:	00f70363          	beq	a4,a5,800678 <test_cow_parent_write+0x6a>
            {
                errors++;
  800676:	2485                	addiw	s1,s1,1
        for (int i = 0; i < 512; i++)
  800678:	278d                	addiw	a5,a5,3
  80067a:	0411                	addi	s0,s0,4
  80067c:	fed79ae3          	bne	a5,a3,800670 <test_cow_parent_write+0x62>
            }
        }
        
        int code;
        waitpid(pid, &code);
  800680:	006c                	addi	a1,sp,12
  800682:	854a                	mv	a0,s2
  800684:	ac3ff0ef          	jal	ra,800146 <waitpid>
        
        if (errors == 0)
  800688:	c495                	beqz	s1,8006b4 <test_cow_parent_write+0xa6>
        {
            cprintf("  [Parent] Write and isolation: PASS\n");
        }
        else
        {
            cprintf("  [Parent] Write verification: FAIL\n");
  80068a:	00001517          	auipc	a0,0x1
  80068e:	da650513          	addi	a0,a0,-602 # 801430 <error_string+0x298>
  800692:	a11ff0ef          	jal	ra,8000a2 <cprintf>
        }
        cprintf("  [Parent] Test 2: PASS\n\n");
  800696:	00001517          	auipc	a0,0x1
  80069a:	dc250513          	addi	a0,a0,-574 # 801458 <error_string+0x2c0>
  80069e:	a05ff0ef          	jal	ra,8000a2 <cprintf>
    }
}
  8006a2:	60a6                	ld	ra,72(sp)
  8006a4:	6406                	ld	s0,64(sp)
  8006a6:	74e2                	ld	s1,56(sp)
  8006a8:	7942                	ld	s2,48(sp)
  8006aa:	79a2                	ld	s3,40(sp)
  8006ac:	7a02                	ld	s4,32(sp)
  8006ae:	6ae2                	ld	s5,24(sp)
  8006b0:	6161                	addi	sp,sp,80
  8006b2:	8082                	ret
            cprintf("  [Parent] Write and isolation: PASS\n");
  8006b4:	00001517          	auipc	a0,0x1
  8006b8:	d5450513          	addi	a0,a0,-684 # 801408 <error_string+0x270>
  8006bc:	9e7ff0ef          	jal	ra,8000a2 <cprintf>
  8006c0:	bfd9                	j	800696 <test_cow_parent_write+0x88>
        yield();
  8006c2:	a87ff0ef          	jal	ra,800148 <yield>
        for (int i = 0; i < 512; i++)
  8006c6:	4981                	li	s3,0
        yield();
  8006c8:	a81ff0ef          	jal	ra,800148 <yield>
  8006cc:	4489                	li	s1,2
                cprintf("    ERROR at [%d]: got %d, expected %d\n", 
  8006ce:	00001a97          	auipc	s5,0x1
  8006d2:	cbaa8a93          	addi	s5,s5,-838 # 801388 <error_string+0x1f0>
        for (int i = 0; i < 512; i++)
  8006d6:	20000a13          	li	s4,512
            if (global_data_test2[i] != i * 3 + 2)
  8006da:	4010                	lw	a2,0(s0)
  8006dc:	0004869b          	sext.w	a3,s1
  8006e0:	00960763          	beq	a2,s1,8006ee <test_cow_parent_write+0xe0>
                cprintf("    ERROR at [%d]: got %d, expected %d\n", 
  8006e4:	85ce                	mv	a1,s3
  8006e6:	8556                	mv	a0,s5
  8006e8:	9bbff0ef          	jal	ra,8000a2 <cprintf>
                errors++;
  8006ec:	2905                	addiw	s2,s2,1
        for (int i = 0; i < 512; i++)
  8006ee:	2985                	addiw	s3,s3,1
  8006f0:	0411                	addi	s0,s0,4
  8006f2:	248d                	addiw	s1,s1,3
  8006f4:	ff4993e3          	bne	s3,s4,8006da <test_cow_parent_write+0xcc>
        if (errors == 0)
  8006f8:	00091b63          	bnez	s2,80070e <test_cow_parent_write+0x100>
            cprintf("  [Child]  Data isolation: PASS\n");
  8006fc:	00001517          	auipc	a0,0x1
  800700:	cb450513          	addi	a0,a0,-844 # 8013b0 <error_string+0x218>
  800704:	99fff0ef          	jal	ra,8000a2 <cprintf>
        exit(0);
  800708:	4501                	li	a0,0
  80070a:	a25ff0ef          	jal	ra,80012e <exit>
            cprintf("  [Child]  Data isolation: FAIL (errors=%d)\n", errors);
  80070e:	85ca                	mv	a1,s2
  800710:	00001517          	auipc	a0,0x1
  800714:	cc850513          	addi	a0,a0,-824 # 8013d8 <error_string+0x240>
  800718:	98bff0ef          	jal	ra,8000a2 <cprintf>
  80071c:	b7f5                	j	800708 <test_cow_parent_write+0xfa>

000000000080071e <test_cow_child_write>:

// Test 3: 子进程写入后隔离 - 验证子进程修改不影响父进程
void test_cow_child_write(void)
{
  80071e:	715d                	addi	sp,sp,-80
    cprintf("Test 3: CHILD WRITE ISOLATION (parent sees original data)\n");
  800720:	00001517          	auipc	a0,0x1
  800724:	d5850513          	addi	a0,a0,-680 # 801478 <error_string+0x2e0>
{
  800728:	f84a                	sd	s2,48(sp)
  80072a:	e486                	sd	ra,72(sp)
  80072c:	e0a2                	sd	s0,64(sp)
  80072e:	fc26                	sd	s1,56(sp)
  800730:	f44e                	sd	s3,40(sp)
  800732:	f052                	sd	s4,32(sp)
  800734:	ec56                	sd	s5,24(sp)
    cprintf("Test 3: CHILD WRITE ISOLATION (parent sees original data)\n");
  800736:	96dff0ef          	jal	ra,8000a2 <cprintf>
    
    // 初始化数据
    for (int i = 0; i < 512; i++)
  80073a:	00003917          	auipc	s2,0x3
  80073e:	8c690913          	addi	s2,s2,-1850 # 803000 <global_data_test3>
  800742:	6685                	lui	a3,0x1
    cprintf("Test 3: CHILD WRITE ISOLATION (parent sees original data)\n");
  800744:	874a                	mv	a4,s2
  800746:	478d                	li	a5,3
    for (int i = 0; i < 512; i++)
  800748:	a0368693          	addi	a3,a3,-1533 # a03 <_start-0x7ff61d>
    {
        global_data_test3[i] = i * 5 + 3;
  80074c:	c31c                	sw	a5,0(a4)
    for (int i = 0; i < 512; i++)
  80074e:	2795                	addiw	a5,a5,5
  800750:	0711                	addi	a4,a4,4
  800752:	fed79de3          	bne	a5,a3,80074c <test_cow_child_write+0x2e>
    }
    
    int pid = fork();
  800756:	9efff0ef          	jal	ra,800144 <fork>
  80075a:	85aa                	mv	a1,a0
    if (pid == 0)
  80075c:	cd25                	beqz	a0,8007d4 <test_cow_child_write+0xb6>
    }
    else
    {
        // 父进程等待
        int code;
        waitpid(pid, &code);
  80075e:	006c                	addi	a1,sp,12
  800760:	9e7ff0ef          	jal	ra,800146 <waitpid>
  800764:	440d                	li	s0,3
        
        // 父进程验证数据未被修改
        int errors = 0;
        for (int i = 0; i < 512; i++)
  800766:	4481                	li	s1,0
        int errors = 0;
  800768:	4a01                	li	s4,0
        {
            if (global_data_test3[i] != i * 5 + 3)
            {
                cprintf("    ERROR at [%d]: got %d, expected %d\n", 
  80076a:	00001a97          	auipc	s5,0x1
  80076e:	c1ea8a93          	addi	s5,s5,-994 # 801388 <error_string+0x1f0>
        for (int i = 0; i < 512; i++)
  800772:	20000993          	li	s3,512
            if (global_data_test3[i] != i * 5 + 3)
  800776:	00092603          	lw	a2,0(s2)
  80077a:	0004069b          	sext.w	a3,s0
  80077e:	00860763          	beq	a2,s0,80078c <test_cow_child_write+0x6e>
                cprintf("    ERROR at [%d]: got %d, expected %d\n", 
  800782:	85a6                	mv	a1,s1
  800784:	8556                	mv	a0,s5
  800786:	91dff0ef          	jal	ra,8000a2 <cprintf>
                    i, global_data_test3[i], i * 5 + 3);
                errors++;
  80078a:	2a05                	addiw	s4,s4,1
        for (int i = 0; i < 512; i++)
  80078c:	2485                	addiw	s1,s1,1
  80078e:	0911                	addi	s2,s2,4
  800790:	2415                	addiw	s0,s0,5
  800792:	ff3492e3          	bne	s1,s3,800776 <test_cow_child_write+0x58>
            }
        }
        
        if (errors == 0)
  800796:	020a0863          	beqz	s4,8007c6 <test_cow_child_write+0xa8>
        {
            cprintf("  [Parent] Data isolation: PASS\n");
        }
        else
        {
            cprintf("  [Parent] Data isolation: FAIL (errors=%d)\n", errors);
  80079a:	85d2                	mv	a1,s4
  80079c:	00001517          	auipc	a0,0x1
  8007a0:	da450513          	addi	a0,a0,-604 # 801540 <error_string+0x3a8>
  8007a4:	8ffff0ef          	jal	ra,8000a2 <cprintf>
        }
        cprintf("  [Parent] Test 3: PASS\n\n");
  8007a8:	00001517          	auipc	a0,0x1
  8007ac:	dc850513          	addi	a0,a0,-568 # 801570 <error_string+0x3d8>
  8007b0:	8f3ff0ef          	jal	ra,8000a2 <cprintf>
    }
}
  8007b4:	60a6                	ld	ra,72(sp)
  8007b6:	6406                	ld	s0,64(sp)
  8007b8:	74e2                	ld	s1,56(sp)
  8007ba:	7942                	ld	s2,48(sp)
  8007bc:	79a2                	ld	s3,40(sp)
  8007be:	7a02                	ld	s4,32(sp)
  8007c0:	6ae2                	ld	s5,24(sp)
  8007c2:	6161                	addi	sp,sp,80
  8007c4:	8082                	ret
            cprintf("  [Parent] Data isolation: PASS\n");
  8007c6:	00001517          	auipc	a0,0x1
  8007ca:	d5250513          	addi	a0,a0,-686 # 801518 <error_string+0x380>
  8007ce:	8d5ff0ef          	jal	ra,8000a2 <cprintf>
  8007d2:	bfd9                	j	8007a8 <test_cow_child_write+0x8a>
        for (int i = 0; i < 512; i++)
  8007d4:	6705                	lui	a4,0x1
  8007d6:	00003697          	auipc	a3,0x3
  8007da:	82a68693          	addi	a3,a3,-2006 # 803000 <global_data_test3>
  8007de:	0c800793          	li	a5,200
  8007e2:	ac870713          	addi	a4,a4,-1336 # ac8 <_start-0x7ff558>
            global_data_test3[i] = i * 5 + 200;
  8007e6:	c29c                	sw	a5,0(a3)
        for (int i = 0; i < 512; i++)
  8007e8:	2795                	addiw	a5,a5,5
  8007ea:	0691                	addi	a3,a3,4
  8007ec:	fee79de3          	bne	a5,a4,8007e6 <test_cow_child_write+0xc8>
        for (int i = 0; i < 512; i++)
  8007f0:	6705                	lui	a4,0x1
  8007f2:	0c800793          	li	a5,200
  8007f6:	ac870713          	addi	a4,a4,-1336 # ac8 <_start-0x7ff558>
            if (global_data_test3[i] != i * 5 + 200)
  8007fa:	00092683          	lw	a3,0(s2)
  8007fe:	00f68363          	beq	a3,a5,800804 <test_cow_child_write+0xe6>
                errors++;
  800802:	2585                	addiw	a1,a1,1
        for (int i = 0; i < 512; i++)
  800804:	2795                	addiw	a5,a5,5
  800806:	0911                	addi	s2,s2,4
  800808:	fee799e3          	bne	a5,a4,8007fa <test_cow_child_write+0xdc>
        if (errors == 0)
  80080c:	e991                	bnez	a1,800820 <test_cow_child_write+0x102>
            cprintf("  [Child]  Write verification: PASS\n");
  80080e:	00001517          	auipc	a0,0x1
  800812:	caa50513          	addi	a0,a0,-854 # 8014b8 <error_string+0x320>
  800816:	88dff0ef          	jal	ra,8000a2 <cprintf>
        exit(0);
  80081a:	4501                	li	a0,0
  80081c:	913ff0ef          	jal	ra,80012e <exit>
            cprintf("  [Child]  Write verification: FAIL (errors=%d)\n", errors);
  800820:	00001517          	auipc	a0,0x1
  800824:	cc050513          	addi	a0,a0,-832 # 8014e0 <error_string+0x348>
  800828:	87bff0ef          	jal	ra,8000a2 <cprintf>
  80082c:	b7fd                	j	80081a <test_cow_child_write+0xfc>

000000000080082e <test_cow_multiple_fork>:

// Test 4: 多进程 fork - 验证引用计数和多页 COW
void test_cow_multiple_fork(void)
{
  80082e:	7139                	addi	sp,sp,-64
    cprintf("Test 4: MULTIPLE FORK (reference counting)\n");
  800830:	00001517          	auipc	a0,0x1
  800834:	d6050513          	addi	a0,a0,-672 # 801590 <error_string+0x3f8>
{
  800838:	f04a                	sd	s2,32(sp)
  80083a:	ec4e                	sd	s3,24(sp)
  80083c:	fc06                	sd	ra,56(sp)
  80083e:	f822                	sd	s0,48(sp)
  800840:	f426                	sd	s1,40(sp)
  800842:	00003917          	auipc	s2,0x3
  800846:	fbe90913          	addi	s2,s2,-66 # 803800 <global_data_test4>
    cprintf("Test 4: MULTIPLE FORK (reference counting)\n");
  80084a:	859ff0ef          	jal	ra,8000a2 <cprintf>
    
    // 初始化数据
    for (int i = 0; i < 256; i++)
  80084e:	6985                	lui	s3,0x1
  800850:	874a                	mv	a4,s2
    cprintf("Test 4: MULTIPLE FORK (reference counting)\n");
  800852:	4791                	li	a5,4
    for (int i = 0; i < 256; i++)
  800854:	90498693          	addi	a3,s3,-1788 # 904 <_start-0x7ff71c>
    {
        global_data_test4[i] = i * 9 + 4;
  800858:	c31c                	sw	a5,0(a4)
    for (int i = 0; i < 256; i++)
  80085a:	27a5                	addiw	a5,a5,9
  80085c:	0711                	addi	a4,a4,4
  80085e:	fed79de3          	bne	a5,a3,800858 <test_cow_multiple_fork+0x2a>
    }
    
    int pid1 = fork();
  800862:	8e3ff0ef          	jal	ra,800144 <fork>
  800866:	84aa                	mv	s1,a0
    if (pid1 == 0)
  800868:	c941                	beqz	a0,8008f8 <test_cow_multiple_fork+0xca>
        }
        exit(0);
    }
    else
    {
        int pid2 = fork();
  80086a:	8dbff0ef          	jal	ra,800144 <fork>
  80086e:	842a                	mv	s0,a0
        if (pid2 == 0)
  800870:	cd39                	beqz	a0,8008ce <test_cow_multiple_fork+0xa0>
        }
        else
        {
            // 父进程等待两个子进程
            int code;
            waitpid(pid1, &code);
  800872:	006c                	addi	a1,sp,12
  800874:	8526                	mv	a0,s1
  800876:	8d1ff0ef          	jal	ra,800146 <waitpid>
            waitpid(pid2, &code);
  80087a:	006c                	addi	a1,sp,12
  80087c:	8522                	mv	a0,s0
  80087e:	8c9ff0ef          	jal	ra,800146 <waitpid>
            
            // 验证父进程数据未被修改
            int errors = 0;
            if (global_data_test4[100] != 100 * 9 + 4)
  800882:	19092703          	lw	a4,400(s2)
  800886:	38800793          	li	a5,904
  80088a:	02f70563          	beq	a4,a5,8008b4 <test_cow_multiple_fork+0x86>
            {
                cprintf("  [Parent] Data isolation (2 children): PASS\n");
            }
            else
            {
                cprintf("  [Parent] Data isolation (2 children): FAIL\n");
  80088e:	00001517          	auipc	a0,0x1
  800892:	df250513          	addi	a0,a0,-526 # 801680 <error_string+0x4e8>
  800896:	80dff0ef          	jal	ra,8000a2 <cprintf>
            }
            cprintf("  [Parent] Test 4: PASS\n\n");
  80089a:	00001517          	auipc	a0,0x1
  80089e:	e1650513          	addi	a0,a0,-490 # 8016b0 <error_string+0x518>
  8008a2:	801ff0ef          	jal	ra,8000a2 <cprintf>
        }
    }
}
  8008a6:	70e2                	ld	ra,56(sp)
  8008a8:	7442                	ld	s0,48(sp)
  8008aa:	74a2                	ld	s1,40(sp)
  8008ac:	7902                	ld	s2,32(sp)
  8008ae:	69e2                	ld	s3,24(sp)
  8008b0:	6121                	addi	sp,sp,64
  8008b2:	8082                	ret
            if (global_data_test4[200] != 200 * 9 + 4)
  8008b4:	32092703          	lw	a4,800(s2)
  8008b8:	70c00793          	li	a5,1804
  8008bc:	fcf719e3          	bne	a4,a5,80088e <test_cow_multiple_fork+0x60>
                cprintf("  [Parent] Data isolation (2 children): PASS\n");
  8008c0:	00001517          	auipc	a0,0x1
  8008c4:	d9050513          	addi	a0,a0,-624 # 801650 <error_string+0x4b8>
  8008c8:	fdaff0ef          	jal	ra,8000a2 <cprintf>
  8008cc:	b7f9                	j	80089a <test_cow_multiple_fork+0x6c>
            yield();
  8008ce:	87bff0ef          	jal	ra,800148 <yield>
            if (global_data_test4[0] != 4 || global_data_test4[255] != 255 * 9 + 4)
  8008d2:	00092703          	lw	a4,0(s2)
  8008d6:	4791                	li	a5,4
  8008d8:	04f70563          	beq	a4,a5,800922 <test_cow_multiple_fork+0xf4>
            global_data_test4[200] = 8888;
  8008dc:	6789                	lui	a5,0x2
  8008de:	2b878793          	addi	a5,a5,696 # 22b8 <_start-0x7fdd68>
                cprintf("  [Child2] Write verification: PASS\n");
  8008e2:	00001517          	auipc	a0,0x1
  8008e6:	d4650513          	addi	a0,a0,-698 # 801628 <error_string+0x490>
            global_data_test4[200] = 8888;
  8008ea:	32f92023          	sw	a5,800(s2)
                cprintf("  [Child2] Write verification: PASS\n");
  8008ee:	fb4ff0ef          	jal	ra,8000a2 <cprintf>
            exit(0);
  8008f2:	4501                	li	a0,0
  8008f4:	83bff0ef          	jal	ra,80012e <exit>
        yield();
  8008f8:	851ff0ef          	jal	ra,800148 <yield>
        if (global_data_test4[0] != 4 || global_data_test4[255] != 255 * 9 + 4)
  8008fc:	00092703          	lw	a4,0(s2)
  800900:	4791                	li	a5,4
  800902:	02f70d63          	beq	a4,a5,80093c <test_cow_multiple_fork+0x10e>
        global_data_test4[100] = 9999;
  800906:	6789                	lui	a5,0x2
  800908:	70f78793          	addi	a5,a5,1807 # 270f <_start-0x7fd911>
            cprintf("  [Child1] Write verification: PASS\n");
  80090c:	00001517          	auipc	a0,0x1
  800910:	cd450513          	addi	a0,a0,-812 # 8015e0 <error_string+0x448>
        global_data_test4[100] = 9999;
  800914:	18f92823          	sw	a5,400(s2)
            cprintf("  [Child1] Write verification: PASS\n");
  800918:	f8aff0ef          	jal	ra,8000a2 <cprintf>
        exit(0);
  80091c:	4501                	li	a0,0
  80091e:	811ff0ef          	jal	ra,80012e <exit>
            if (global_data_test4[0] != 4 || global_data_test4[255] != 255 * 9 + 4)
  800922:	3fc92783          	lw	a5,1020(s2)
  800926:	8fb98993          	addi	s3,s3,-1797
  80092a:	fb3799e3          	bne	a5,s3,8008dc <test_cow_multiple_fork+0xae>
                cprintf("  [Child2] Initial data: PASS\n");
  80092e:	00001517          	auipc	a0,0x1
  800932:	cda50513          	addi	a0,a0,-806 # 801608 <error_string+0x470>
  800936:	f6cff0ef          	jal	ra,8000a2 <cprintf>
  80093a:	b74d                	j	8008dc <test_cow_multiple_fork+0xae>
        if (global_data_test4[0] != 4 || global_data_test4[255] != 255 * 9 + 4)
  80093c:	3fc92783          	lw	a5,1020(s2)
  800940:	8fb98993          	addi	s3,s3,-1797
  800944:	fd3791e3          	bne	a5,s3,800906 <test_cow_multiple_fork+0xd8>
            cprintf("  [Child1] Initial data: PASS\n");
  800948:	00001517          	auipc	a0,0x1
  80094c:	c7850513          	addi	a0,a0,-904 # 8015c0 <error_string+0x428>
  800950:	f52ff0ef          	jal	ra,8000a2 <cprintf>
  800954:	bf4d                	j	800906 <test_cow_multiple_fork+0xd8>

0000000000800956 <test_cow_cross_page>:

// Test 5: 跨页写入 - 验证多页数据的 COW
void test_cow_cross_page(void)
{
  800956:	1101                	addi	sp,sp,-32
    cprintf("Test 5: CROSS-PAGE WRITE (multiple pages)\n");
  800958:	00001517          	auipc	a0,0x1
  80095c:	d7850513          	addi	a0,a0,-648 # 8016d0 <error_string+0x538>
{
  800960:	e822                	sd	s0,16(sp)
  800962:	ec06                	sd	ra,24(sp)
    cprintf("Test 5: CROSS-PAGE WRITE (multiple pages)\n");
  800964:	f3eff0ef          	jal	ra,8000a2 <cprintf>
    
    // 初始化大数组（跨多个页）
    for (int i = 0; i < 1024; i++)
  800968:	00003417          	auipc	s0,0x3
  80096c:	29840413          	addi	s0,s0,664 # 803c00 <global_data_test5>
  800970:	668d                	lui	a3,0x3
    cprintf("Test 5: CROSS-PAGE WRITE (multiple pages)\n");
  800972:	8722                	mv	a4,s0
  800974:	4795                	li	a5,5
    for (int i = 0; i < 1024; i++)
  800976:	c0568693          	addi	a3,a3,-1019 # 2c05 <_start-0x7fd41b>
    {
        global_data_test5[i] = i * 11 + 5;
  80097a:	c31c                	sw	a5,0(a4)
    for (int i = 0; i < 1024; i++)
  80097c:	27ad                	addiw	a5,a5,11
  80097e:	0711                	addi	a4,a4,4
  800980:	fed79de3          	bne	a5,a3,80097a <test_cow_cross_page+0x24>
    }
    
    int pid = fork();
  800984:	fc0ff0ef          	jal	ra,800144 <fork>
  800988:	85aa                	mv	a1,a0
    if (pid == 0)
  80098a:	c135                	beqz	a0,8009ee <test_cow_cross_page+0x98>
    }
    else
    {
        // 父进程等待
        int code;
        waitpid(pid, &code);
  80098c:	006c                	addi	a1,sp,12
  80098e:	fb8ff0ef          	jal	ra,800146 <waitpid>
        
        // 验证父进程数据未变
        int errors = 0;
        for (int i = 0; i < 1024; i++)
  800992:	668d                	lui	a3,0x3
        waitpid(pid, &code);
  800994:	4795                	li	a5,5
        int errors = 0;
  800996:	4581                	li	a1,0
        for (int i = 0; i < 1024; i++)
  800998:	c0568693          	addi	a3,a3,-1019 # 2c05 <_start-0x7fd41b>
        {
            if (global_data_test5[i] != i * 11 + 5)
  80099c:	4018                	lw	a4,0(s0)
  80099e:	00f70363          	beq	a4,a5,8009a4 <test_cow_cross_page+0x4e>
            {
                errors++;
  8009a2:	2585                	addiw	a1,a1,1
        for (int i = 0; i < 1024; i++)
  8009a4:	27ad                	addiw	a5,a5,11
  8009a6:	0411                	addi	s0,s0,4
  8009a8:	fed79ae3          	bne	a5,a3,80099c <test_cow_cross_page+0x46>
            }
        }
        if (errors == 0)
  8009ac:	c18d                	beqz	a1,8009ce <test_cow_cross_page+0x78>
        {
            cprintf("  [Parent] Cross-page isolation: PASS\n");
        }
        else
        {
            cprintf("  [Parent] Cross-page isolation: FAIL (errors=%d)\n", errors);
  8009ae:	00001517          	auipc	a0,0x1
  8009b2:	dd250513          	addi	a0,a0,-558 # 801780 <error_string+0x5e8>
  8009b6:	eecff0ef          	jal	ra,8000a2 <cprintf>
        }
        cprintf("  [Parent] Test 5: PASS\n\n");
  8009ba:	00001517          	auipc	a0,0x1
  8009be:	dfe50513          	addi	a0,a0,-514 # 8017b8 <error_string+0x620>
  8009c2:	ee0ff0ef          	jal	ra,8000a2 <cprintf>
    }
}
  8009c6:	60e2                	ld	ra,24(sp)
  8009c8:	6442                	ld	s0,16(sp)
  8009ca:	6105                	addi	sp,sp,32
  8009cc:	8082                	ret
            cprintf("  [Parent] Cross-page isolation: PASS\n");
  8009ce:	00001517          	auipc	a0,0x1
  8009d2:	d8a50513          	addi	a0,a0,-630 # 801758 <error_string+0x5c0>
  8009d6:	eccff0ef          	jal	ra,8000a2 <cprintf>
        cprintf("  [Parent] Test 5: PASS\n\n");
  8009da:	00001517          	auipc	a0,0x1
  8009de:	dde50513          	addi	a0,a0,-546 # 8017b8 <error_string+0x620>
  8009e2:	ec0ff0ef          	jal	ra,8000a2 <cprintf>
}
  8009e6:	60e2                	ld	ra,24(sp)
  8009e8:	6442                	ld	s0,16(sp)
  8009ea:	6105                	addi	sp,sp,32
  8009ec:	8082                	ret
        for (int i = 0; i < 1024; i++)
  8009ee:	670d                	lui	a4,0x3
  8009f0:	00003697          	auipc	a3,0x3
  8009f4:	21068693          	addi	a3,a3,528 # 803c00 <global_data_test5>
  8009f8:	09600793          	li	a5,150
  8009fc:	c9670713          	addi	a4,a4,-874 # 2c96 <_start-0x7fd38a>
            global_data_test5[i] = i * 11 + 150;
  800a00:	c29c                	sw	a5,0(a3)
        for (int i = 0; i < 1024; i++)
  800a02:	27ad                	addiw	a5,a5,11
  800a04:	0691                	addi	a3,a3,4
  800a06:	fee79de3          	bne	a5,a4,800a00 <test_cow_cross_page+0xaa>
        for (int i = 0; i < 1024; i++)
  800a0a:	670d                	lui	a4,0x3
  800a0c:	09600793          	li	a5,150
  800a10:	c9670713          	addi	a4,a4,-874 # 2c96 <_start-0x7fd38a>
            if (global_data_test5[i] != i * 11 + 150)
  800a14:	4014                	lw	a3,0(s0)
  800a16:	00f68363          	beq	a3,a5,800a1c <test_cow_cross_page+0xc6>
                errors++;
  800a1a:	2585                	addiw	a1,a1,1
        for (int i = 0; i < 1024; i++)
  800a1c:	27ad                	addiw	a5,a5,11
  800a1e:	0411                	addi	s0,s0,4
  800a20:	fee79ae3          	bne	a5,a4,800a14 <test_cow_cross_page+0xbe>
        if (errors == 0)
  800a24:	e991                	bnez	a1,800a38 <test_cow_cross_page+0xe2>
            cprintf("  [Child]  Cross-page write: PASS\n");
  800a26:	00001517          	auipc	a0,0x1
  800a2a:	cda50513          	addi	a0,a0,-806 # 801700 <error_string+0x568>
  800a2e:	e74ff0ef          	jal	ra,8000a2 <cprintf>
        exit(0);
  800a32:	4501                	li	a0,0
  800a34:	efaff0ef          	jal	ra,80012e <exit>
            cprintf("  [Child]  Cross-page write: FAIL (errors=%d)\n", errors);
  800a38:	00001517          	auipc	a0,0x1
  800a3c:	cf050513          	addi	a0,a0,-784 # 801728 <error_string+0x590>
  800a40:	e62ff0ef          	jal	ra,8000a2 <cprintf>
  800a44:	b7fd                	j	800a32 <test_cow_cross_page+0xdc>

0000000000800a46 <test_cow_partial_write>:

// Test 6: 部分页写入 - 验证选择性复制
void test_cow_partial_write(void)
{
  800a46:	1101                	addi	sp,sp,-32
    cprintf("Test 6: PARTIAL WRITE (selective page copy)\n");
  800a48:	00001517          	auipc	a0,0x1
  800a4c:	d9050513          	addi	a0,a0,-624 # 8017d8 <error_string+0x640>
{
  800a50:	e822                	sd	s0,16(sp)
  800a52:	ec06                	sd	ra,24(sp)
    cprintf("Test 6: PARTIAL WRITE (selective page copy)\n");
  800a54:	e4eff0ef          	jal	ra,8000a2 <cprintf>
    
    // 初始化数据
    for (int i = 0; i < 1024; i++)
  800a58:	00004417          	auipc	s0,0x4
  800a5c:	1a840413          	addi	s0,s0,424 # 804c00 <global_data_test6>
  800a60:	668d                	lui	a3,0x3
    cprintf("Test 6: PARTIAL WRITE (selective page copy)\n");
  800a62:	8722                	mv	a4,s0
  800a64:	4799                	li	a5,6
    for (int i = 0; i < 1024; i++)
  800a66:	40668693          	addi	a3,a3,1030 # 3406 <_start-0x7fcc1a>
    {
        global_data_test6[i] = i * 13 + 6;
  800a6a:	c31c                	sw	a5,0(a4)
    for (int i = 0; i < 1024; i++)
  800a6c:	27b5                	addiw	a5,a5,13
  800a6e:	0711                	addi	a4,a4,4
  800a70:	fed79de3          	bne	a5,a3,800a6a <test_cow_partial_write+0x24>
    }
    
    int pid = fork();
  800a74:	ed0ff0ef          	jal	ra,800144 <fork>
  800a78:	85aa                	mv	a1,a0
    if (pid == 0)
  800a7a:	c135                	beqz	a0,800ade <test_cow_partial_write+0x98>
    }
    else
    {
        // 父进程等待
        int code;
        waitpid(pid, &code);
  800a7c:	006c                	addi	a1,sp,12
  800a7e:	ec8ff0ef          	jal	ra,800146 <waitpid>
        
        // 父进程验证数据完全未变
        int errors = 0;
        for (int i = 0; i < 1024; i++)
  800a82:	668d                	lui	a3,0x3
        waitpid(pid, &code);
  800a84:	4799                	li	a5,6
        int errors = 0;
  800a86:	4581                	li	a1,0
        for (int i = 0; i < 1024; i++)
  800a88:	40668693          	addi	a3,a3,1030 # 3406 <_start-0x7fcc1a>
        {
            if (global_data_test6[i] != i * 13 + 6)
  800a8c:	4018                	lw	a4,0(s0)
  800a8e:	00f70363          	beq	a4,a5,800a94 <test_cow_partial_write+0x4e>
            {
                errors++;
  800a92:	2585                	addiw	a1,a1,1
        for (int i = 0; i < 1024; i++)
  800a94:	27b5                	addiw	a5,a5,13
  800a96:	0411                	addi	s0,s0,4
  800a98:	fed79ae3          	bne	a5,a3,800a8c <test_cow_partial_write+0x46>
            }
        }
        if (errors == 0)
  800a9c:	c18d                	beqz	a1,800abe <test_cow_partial_write+0x78>
        {
            cprintf("  [Parent] Partial write isolation: PASS\n");
        }
        else
        {
            cprintf("  [Parent] Partial write isolation: FAIL (errors=%d)\n", errors);
  800a9e:	00001517          	auipc	a0,0x1
  800aa2:	dea50513          	addi	a0,a0,-534 # 801888 <error_string+0x6f0>
  800aa6:	dfcff0ef          	jal	ra,8000a2 <cprintf>
        }
        cprintf("  [Parent] Test 6: PASS\n\n");
  800aaa:	00001517          	auipc	a0,0x1
  800aae:	e1650513          	addi	a0,a0,-490 # 8018c0 <error_string+0x728>
  800ab2:	df0ff0ef          	jal	ra,8000a2 <cprintf>
    }
}
  800ab6:	60e2                	ld	ra,24(sp)
  800ab8:	6442                	ld	s0,16(sp)
  800aba:	6105                	addi	sp,sp,32
  800abc:	8082                	ret
            cprintf("  [Parent] Partial write isolation: PASS\n");
  800abe:	00001517          	auipc	a0,0x1
  800ac2:	d9a50513          	addi	a0,a0,-614 # 801858 <error_string+0x6c0>
  800ac6:	ddcff0ef          	jal	ra,8000a2 <cprintf>
        cprintf("  [Parent] Test 6: PASS\n\n");
  800aca:	00001517          	auipc	a0,0x1
  800ace:	df650513          	addi	a0,a0,-522 # 8018c0 <error_string+0x728>
  800ad2:	dd0ff0ef          	jal	ra,8000a2 <cprintf>
}
  800ad6:	60e2                	ld	ra,24(sp)
  800ad8:	6442                	ld	s0,16(sp)
  800ada:	6105                	addi	sp,sp,32
  800adc:	8082                	ret
  800ade:	00004717          	auipc	a4,0x4
  800ae2:	52270713          	addi	a4,a4,1314 # 805000 <global_data_test6+0x400>
    if (pid == 0)
  800ae6:	6785                	lui	a5,0x1
  800ae8:	00005617          	auipc	a2,0x5
  800aec:	91860613          	addi	a2,a2,-1768 # 805400 <global_data_test6+0x800>
  800af0:	86ba                	mv	a3,a4
  800af2:	48878793          	addi	a5,a5,1160 # 1488 <_start-0x7feb98>
            global_data_test6[i] = i + 5000;
  800af6:	c29c                	sw	a5,0(a3)
        for (int i = 256; i < 512; i++)
  800af8:	0691                	addi	a3,a3,4
  800afa:	2785                	addiw	a5,a5,1
  800afc:	fec69de3          	bne	a3,a2,800af6 <test_cow_partial_write+0xb0>
        for (int i = 0; i < 256; i++)
  800b00:	6785                	lui	a5,0x1
  800b02:	4699                	li	a3,6
  800b04:	d0678513          	addi	a0,a5,-762 # d06 <_start-0x7ff31a>
            if (global_data_test6[i] != i * 13 + 6)
  800b08:	00042803          	lw	a6,0(s0)
  800b0c:	00d80363          	beq	a6,a3,800b12 <test_cow_partial_write+0xcc>
                errors++;
  800b10:	2585                	addiw	a1,a1,1
        for (int i = 0; i < 256; i++)
  800b12:	26b5                	addiw	a3,a3,13
  800b14:	0411                	addi	s0,s0,4
  800b16:	fea699e3          	bne	a3,a0,800b08 <test_cow_partial_write+0xc2>
  800b1a:	48878793          	addi	a5,a5,1160
            if (global_data_test6[i] != i + 5000)
  800b1e:	4314                	lw	a3,0(a4)
  800b20:	00f68363          	beq	a3,a5,800b26 <test_cow_partial_write+0xe0>
                errors++;
  800b24:	2585                	addiw	a1,a1,1
        for (int i = 256; i < 512; i++)
  800b26:	0711                	addi	a4,a4,4
  800b28:	2785                	addiw	a5,a5,1
  800b2a:	fec71ae3          	bne	a4,a2,800b1e <test_cow_partial_write+0xd8>
  800b2e:	6789                	lui	a5,0x2
        for (int i = 512; i < 1024; i++)
  800b30:	670d                	lui	a4,0x3
  800b32:	00005697          	auipc	a3,0x5
  800b36:	8ce68693          	addi	a3,a3,-1842 # 805400 <global_data_test6+0x800>
        for (int i = 256; i < 512; i++)
  800b3a:	a0678793          	addi	a5,a5,-1530 # 1a06 <_start-0x7fe61a>
        for (int i = 512; i < 1024; i++)
  800b3e:	40670713          	addi	a4,a4,1030 # 3406 <_start-0x7fcc1a>
            if (global_data_test6[i] != i * 13 + 6)
  800b42:	4290                	lw	a2,0(a3)
  800b44:	00f60363          	beq	a2,a5,800b4a <test_cow_partial_write+0x104>
                errors++;
  800b48:	2585                	addiw	a1,a1,1
        for (int i = 512; i < 1024; i++)
  800b4a:	27b5                	addiw	a5,a5,13
  800b4c:	0691                	addi	a3,a3,4
  800b4e:	fee79ae3          	bne	a5,a4,800b42 <test_cow_partial_write+0xfc>
        if (errors == 0)
  800b52:	e991                	bnez	a1,800b66 <test_cow_partial_write+0x120>
            cprintf("  [Child]  Partial write: PASS\n");
  800b54:	00001517          	auipc	a0,0x1
  800b58:	cb450513          	addi	a0,a0,-844 # 801808 <error_string+0x670>
  800b5c:	d46ff0ef          	jal	ra,8000a2 <cprintf>
        exit(0);
  800b60:	4501                	li	a0,0
  800b62:	dccff0ef          	jal	ra,80012e <exit>
            cprintf("  [Child]  Partial write: FAIL (errors=%d)\n", errors);
  800b66:	00001517          	auipc	a0,0x1
  800b6a:	cc250513          	addi	a0,a0,-830 # 801828 <error_string+0x690>
  800b6e:	d34ff0ef          	jal	ra,8000a2 <cprintf>
  800b72:	b7fd                	j	800b60 <test_cow_partial_write+0x11a>

0000000000800b74 <test_cow_stack>:

// Test 7: 栈空间 COW - 验证栈上数据的 COW 语义
void test_cow_stack(void)
{
  800b74:	bd010113          	addi	sp,sp,-1072
    cprintf("Test 7: STACK COW (local variables)\n");
  800b78:	00001517          	auipc	a0,0x1
  800b7c:	d6850513          	addi	a0,a0,-664 # 8018e0 <error_string+0x748>
{
  800b80:	42813023          	sd	s0,1056(sp)
  800b84:	42113423          	sd	ra,1064(sp)
    cprintf("Test 7: STACK COW (local variables)\n");
  800b88:	d1aff0ef          	jal	ra,8000a2 <cprintf>
    
    // 栈上局部数组
    int stack_array[256];
    for (int i = 0; i < 256; i++)
  800b8c:	1000                	addi	s0,sp,32
  800b8e:	6685                	lui	a3,0x1
    cprintf("Test 7: STACK COW (local variables)\n");
  800b90:	8722                	mv	a4,s0
  800b92:	479d                	li	a5,7
    for (int i = 0; i < 256; i++)
  800b94:	10768693          	addi	a3,a3,263 # 1107 <_start-0x7fef19>
    {
        stack_array[i] = i * 17 + 7;
  800b98:	c31c                	sw	a5,0(a4)
    for (int i = 0; i < 256; i++)
  800b9a:	27c5                	addiw	a5,a5,17
  800b9c:	0711                	addi	a4,a4,4
  800b9e:	fed79de3          	bne	a5,a3,800b98 <test_cow_stack+0x24>
    }
    
    int pid = fork();
  800ba2:	da2ff0ef          	jal	ra,800144 <fork>
    if (pid == 0)
  800ba6:	c925                	beqz	a0,800c16 <test_cow_stack+0xa2>
    }
    else
    {
        // 父进程等待
        int code;
        waitpid(pid, &code);
  800ba8:	086c                	addi	a1,sp,28
  800baa:	d9cff0ef          	jal	ra,800146 <waitpid>
        
        // 父进程验证栈数据未变
        int errors = 0;
        for (int i = 0; i < 256; i++)
  800bae:	6685                	lui	a3,0x1
        waitpid(pid, &code);
  800bb0:	479d                	li	a5,7
        int errors = 0;
  800bb2:	4581                	li	a1,0
        for (int i = 0; i < 256; i++)
  800bb4:	10768693          	addi	a3,a3,263 # 1107 <_start-0x7fef19>
        {
            if (stack_array[i] != i * 17 + 7)
  800bb8:	4018                	lw	a4,0(s0)
  800bba:	00f70363          	beq	a4,a5,800bc0 <test_cow_stack+0x4c>
            {
                errors++;
  800bbe:	2585                	addiw	a1,a1,1
        for (int i = 0; i < 256; i++)
  800bc0:	27c5                	addiw	a5,a5,17
  800bc2:	0411                	addi	s0,s0,4
  800bc4:	fed79ae3          	bne	a5,a3,800bb8 <test_cow_stack+0x44>
            }
        }
        
        if (errors == 0)
  800bc8:	c585                	beqz	a1,800bf0 <test_cow_stack+0x7c>
        {
            cprintf("  [Parent] Stack isolation: PASS\n");
        }
        else
        {
            cprintf("  [Parent] Stack isolation: FAIL (errors=%d)\n", errors);
  800bca:	00001517          	auipc	a0,0x1
  800bce:	db650513          	addi	a0,a0,-586 # 801980 <error_string+0x7e8>
  800bd2:	cd0ff0ef          	jal	ra,8000a2 <cprintf>
        }
        cprintf("  [Parent] Test 7: PASS\n\n");
  800bd6:	00001517          	auipc	a0,0x1
  800bda:	dda50513          	addi	a0,a0,-550 # 8019b0 <error_string+0x818>
  800bde:	cc4ff0ef          	jal	ra,8000a2 <cprintf>
    }
}
  800be2:	42813083          	ld	ra,1064(sp)
  800be6:	42013403          	ld	s0,1056(sp)
  800bea:	43010113          	addi	sp,sp,1072
  800bee:	8082                	ret
            cprintf("  [Parent] Stack isolation: PASS\n");
  800bf0:	00001517          	auipc	a0,0x1
  800bf4:	d6850513          	addi	a0,a0,-664 # 801958 <error_string+0x7c0>
  800bf8:	caaff0ef          	jal	ra,8000a2 <cprintf>
        cprintf("  [Parent] Test 7: PASS\n\n");
  800bfc:	00001517          	auipc	a0,0x1
  800c00:	db450513          	addi	a0,a0,-588 # 8019b0 <error_string+0x818>
  800c04:	c9eff0ef          	jal	ra,8000a2 <cprintf>
}
  800c08:	42813083          	ld	ra,1064(sp)
  800c0c:	42013403          	ld	s0,1056(sp)
  800c10:	43010113          	addi	sp,sp,1072
  800c14:	8082                	ret
  800c16:	e42a                	sd	a0,8(sp)
        yield();
  800c18:	d30ff0ef          	jal	ra,800148 <yield>
        for (int i = 0; i < 256; i++)
  800c1c:	65a2                	ld	a1,8(sp)
  800c1e:	6705                	lui	a4,0x1
        yield();
  800c20:	86a2                	mv	a3,s0
  800c22:	12c00793          	li	a5,300
        for (int i = 0; i < 256; i++)
  800c26:	22c70713          	addi	a4,a4,556 # 122c <_start-0x7fedf4>
            stack_array[i] = i * 17 + 300;
  800c2a:	c29c                	sw	a5,0(a3)
        for (int i = 0; i < 256; i++)
  800c2c:	27c5                	addiw	a5,a5,17
  800c2e:	0691                	addi	a3,a3,4
  800c30:	fee79de3          	bne	a5,a4,800c2a <test_cow_stack+0xb6>
        for (int i = 0; i < 256; i++)
  800c34:	6705                	lui	a4,0x1
  800c36:	12c00793          	li	a5,300
  800c3a:	22c70713          	addi	a4,a4,556 # 122c <_start-0x7fedf4>
            if (stack_array[i] != i * 17 + 300)
  800c3e:	4014                	lw	a3,0(s0)
  800c40:	00f68363          	beq	a3,a5,800c46 <test_cow_stack+0xd2>
                errors++;
  800c44:	2585                	addiw	a1,a1,1
        for (int i = 0; i < 256; i++)
  800c46:	27c5                	addiw	a5,a5,17
  800c48:	0411                	addi	s0,s0,4
  800c4a:	fee79ae3          	bne	a5,a4,800c3e <test_cow_stack+0xca>
        if (errors == 0)
  800c4e:	e991                	bnez	a1,800c62 <test_cow_stack+0xee>
            cprintf("  [Child]  Stack write: PASS\n");
  800c50:	00001517          	auipc	a0,0x1
  800c54:	cb850513          	addi	a0,a0,-840 # 801908 <error_string+0x770>
  800c58:	c4aff0ef          	jal	ra,8000a2 <cprintf>
        exit(0);
  800c5c:	4501                	li	a0,0
  800c5e:	cd0ff0ef          	jal	ra,80012e <exit>
            cprintf("  [Child]  Stack write: FAIL (errors=%d)\n", errors);
  800c62:	00001517          	auipc	a0,0x1
  800c66:	cc650513          	addi	a0,a0,-826 # 801928 <error_string+0x790>
  800c6a:	c38ff0ef          	jal	ra,8000a2 <cprintf>
  800c6e:	b7fd                	j	800c5c <test_cow_stack+0xe8>

0000000000800c70 <test_cow_mixed>:

// Test 8: 混合操作 - 验证复杂场景
void test_cow_mixed(void)
{
  800c70:	7179                	addi	sp,sp,-48
    cprintf("Test 8: MIXED OPERATIONS (complex scenario)\n");
  800c72:	00001517          	auipc	a0,0x1
  800c76:	d5e50513          	addi	a0,a0,-674 # 8019d0 <error_string+0x838>
{
  800c7a:	f022                	sd	s0,32(sp)
  800c7c:	ec26                	sd	s1,24(sp)
  800c7e:	f406                	sd	ra,40(sp)
    cprintf("Test 8: MIXED OPERATIONS (complex scenario)\n");
  800c80:	c22ff0ef          	jal	ra,8000a2 <cprintf>
    
    // 初始化数据
    for (int i = 0; i < 512; i++)
  800c84:	00005417          	auipc	s0,0x5
  800c88:	f7c40413          	addi	s0,s0,-132 # 805c00 <global_data_test8>
  800c8c:	6689                	lui	a3,0x2
    cprintf("Test 8: MIXED OPERATIONS (complex scenario)\n");
  800c8e:	84a2                	mv	s1,s0
  800c90:	8722                	mv	a4,s0
  800c92:	47a1                	li	a5,8
    for (int i = 0; i < 512; i++)
  800c94:	60868693          	addi	a3,a3,1544 # 2608 <_start-0x7fda18>
    {
        global_data_test8[i] = i * 19 + 8;
  800c98:	c31c                	sw	a5,0(a4)
    for (int i = 0; i < 512; i++)
  800c9a:	27cd                	addiw	a5,a5,19
  800c9c:	0711                	addi	a4,a4,4
  800c9e:	fed79de3          	bne	a5,a3,800c98 <test_cow_mixed+0x28>
    }
    
    int pid = fork();
  800ca2:	ca2ff0ef          	jal	ra,800144 <fork>
        exit(0);
    }
    else
    {
        // 父进程也进行修改
        for (int i = 0; i < 100; i++)
  800ca6:	6685                	lui	a3,0x1
  800ca8:	00005717          	auipc	a4,0x5
  800cac:	f5870713          	addi	a4,a4,-168 # 805c00 <global_data_test8>
  800cb0:	25800793          	li	a5,600
  800cb4:	9c468693          	addi	a3,a3,-1596 # 9c4 <_start-0x7ff65c>
    if (pid == 0)
  800cb8:	c959                	beqz	a0,800d4e <test_cow_mixed+0xde>
        {
            global_data_test8[i] = i * 19 + 600;
  800cba:	c31c                	sw	a5,0(a4)
        for (int i = 0; i < 100; i++)
  800cbc:	27cd                	addiw	a5,a5,19
  800cbe:	0711                	addi	a4,a4,4
  800cc0:	fed79de3          	bne	a5,a3,800cba <test_cow_mixed+0x4a>
        }
        
        // 等待子进程
        int code;
        waitpid(pid, &code);
  800cc4:	006c                	addi	a1,sp,12
  800cc6:	c80ff0ef          	jal	ra,800146 <waitpid>
        
        // 验证：父进程的修改应该保留，但子进程的修改不可见
        int errors = 0;
        for (int i = 0; i < 100; i++)
  800cca:	6685                	lui	a3,0x1
        waitpid(pid, &code);
  800ccc:	25800793          	li	a5,600
        int errors = 0;
  800cd0:	4581                	li	a1,0
        for (int i = 0; i < 100; i++)
  800cd2:	9c468693          	addi	a3,a3,-1596 # 9c4 <_start-0x7ff65c>
        {
            if (global_data_test8[i] != i * 19 + 600)
  800cd6:	4018                	lw	a4,0(s0)
  800cd8:	00f70363          	beq	a4,a5,800cde <test_cow_mixed+0x6e>
                errors++;
  800cdc:	2585                	addiw	a1,a1,1
        for (int i = 0; i < 100; i++)
  800cde:	27cd                	addiw	a5,a5,19
  800ce0:	0411                	addi	s0,s0,4
  800ce2:	fed79ae3          	bne	a5,a3,800cd6 <test_cow_mixed+0x66>
        }
        for (int i = 100; i < 512; i++)
  800ce6:	6609                	lui	a2,0x2
  800ce8:	00005717          	auipc	a4,0x5
  800cec:	0a870713          	addi	a4,a4,168 # 805d90 <global_data_test8+0x190>
        for (int i = 0; i < 100; i++)
  800cf0:	77400793          	li	a5,1908
        for (int i = 100; i < 512; i++)
  800cf4:	60860613          	addi	a2,a2,1544 # 2608 <_start-0x7fda18>
        {
            if (global_data_test8[i] != i * 19 + 8)
  800cf8:	4314                	lw	a3,0(a4)
  800cfa:	00f68363          	beq	a3,a5,800d00 <test_cow_mixed+0x90>
                errors++;
  800cfe:	2585                	addiw	a1,a1,1
        for (int i = 100; i < 512; i++)
  800d00:	27cd                	addiw	a5,a5,19
  800d02:	0711                	addi	a4,a4,4
  800d04:	fec79ae3          	bne	a5,a2,800cf8 <test_cow_mixed+0x88>
        }
        
        if (errors == 0)
  800d08:	c195                	beqz	a1,800d2c <test_cow_mixed+0xbc>
        {
            cprintf("  [Parent] Mixed operations isolation: PASS\n");
        }
        else
        {
            cprintf("  [Parent] Mixed operations isolation: FAIL (errors=%d)\n", errors);
  800d0a:	00001517          	auipc	a0,0x1
  800d0e:	d7e50513          	addi	a0,a0,-642 # 801a88 <error_string+0x8f0>
  800d12:	b90ff0ef          	jal	ra,8000a2 <cprintf>
        }
        cprintf("  [Parent] Test 8: PASS\n\n");
  800d16:	00001517          	auipc	a0,0x1
  800d1a:	db250513          	addi	a0,a0,-590 # 801ac8 <error_string+0x930>
  800d1e:	b84ff0ef          	jal	ra,8000a2 <cprintf>
    }
}
  800d22:	70a2                	ld	ra,40(sp)
  800d24:	7402                	ld	s0,32(sp)
  800d26:	64e2                	ld	s1,24(sp)
  800d28:	6145                	addi	sp,sp,48
  800d2a:	8082                	ret
            cprintf("  [Parent] Mixed operations isolation: PASS\n");
  800d2c:	00001517          	auipc	a0,0x1
  800d30:	d2c50513          	addi	a0,a0,-724 # 801a58 <error_string+0x8c0>
  800d34:	b6eff0ef          	jal	ra,8000a2 <cprintf>
        cprintf("  [Parent] Test 8: PASS\n\n");
  800d38:	00001517          	auipc	a0,0x1
  800d3c:	d9050513          	addi	a0,a0,-624 # 801ac8 <error_string+0x930>
  800d40:	b62ff0ef          	jal	ra,8000a2 <cprintf>
}
  800d44:	70a2                	ld	ra,40(sp)
  800d46:	7402                	ld	s0,32(sp)
  800d48:	64e2                	ld	s1,24(sp)
  800d4a:	6145                	addi	sp,sp,48
  800d4c:	8082                	ret
        if (global_data_test8[0] != 8 || global_data_test8[100] != 100 * 19 + 8)
  800d4e:	4098                	lw	a4,0(s1)
  800d50:	47a1                	li	a5,8
            verify_read = 0;
  800d52:	4581                	li	a1,0
        if (global_data_test8[0] != 8 || global_data_test8[100] != 100 * 19 + 8)
  800d54:	00f71863          	bne	a4,a5,800d64 <test_cow_mixed+0xf4>
  800d58:	1904a583          	lw	a1,400(s1)
  800d5c:	88c58593          	addi	a1,a1,-1908
            verify_read = 0;
  800d60:	0015b593          	seqz	a1,a1
        for (int i = 0; i < 256; i++)
  800d64:	6785                	lui	a5,0x1
            verify_read = 0;
  800d66:	00005697          	auipc	a3,0x5
  800d6a:	e9a68693          	addi	a3,a3,-358 # 805c00 <global_data_test8>
  800d6e:	19000713          	li	a4,400
        for (int i = 0; i < 256; i++)
  800d72:	49078613          	addi	a2,a5,1168 # 1490 <_start-0x7feb90>
            global_data_test8[i] = i * 19 + 400;
  800d76:	c298                	sw	a4,0(a3)
        for (int i = 0; i < 256; i++)
  800d78:	274d                	addiw	a4,a4,19
  800d7a:	0691                	addi	a3,a3,4
  800d7c:	fec71de3          	bne	a4,a2,800d76 <test_cow_mixed+0x106>
        if (global_data_test8[256] != 256 * 19 + 8)
  800d80:	4004a603          	lw	a2,1024(s1)
        for (int i = 256; i < 512; i++)
  800d84:	6709                	lui	a4,0x2
  800d86:	00005697          	auipc	a3,0x5
  800d8a:	27a68693          	addi	a3,a3,634 # 806000 <global_data_test8+0x400>
        if (global_data_test8[256] != 256 * 19 + 8)
  800d8e:	4f478793          	addi	a5,a5,1268
        for (int i = 256; i < 512; i++)
  800d92:	7f470713          	addi	a4,a4,2036 # 27f4 <_start-0x7fd82c>
            global_data_test8[i] = i * 19 + 500;
  800d96:	c29c                	sw	a5,0(a3)
        for (int i = 256; i < 512; i++)
  800d98:	27cd                	addiw	a5,a5,19
  800d9a:	0691                	addi	a3,a3,4
  800d9c:	fee79de3          	bne	a5,a4,800d96 <test_cow_mixed+0x126>
        if (!verify_unmodified)
  800da0:	6785                	lui	a5,0x1
  800da2:	30878793          	addi	a5,a5,776 # 1308 <_start-0x7fed18>
  800da6:	04f61863          	bne	a2,a5,800df6 <test_cow_mixed+0x186>
        if (!verify_read)
  800daa:	0015c593          	xori	a1,a1,1
        if (global_data_test8[256] != 256 * 19 + 8)
  800dae:	1f400793          	li	a5,500
            int expected = (i < 256) ? (i * 19 + 400) : (i * 19 + 500);
  800db2:	0ff00613          	li	a2,255
        for (int i = 0; i < 512; i++)
  800db6:	20000693          	li	a3,512
            int expected = (i < 256) ? (i * 19 + 400) : (i * 19 + 500);
  800dba:	0005081b          	sext.w	a6,a0
            if (global_data_test8[i] != expected)
  800dbe:	4018                	lw	a4,0(s0)
        for (int i = 0; i < 512; i++)
  800dc0:	2505                	addiw	a0,a0,1
            int expected = (i < 256) ? (i * 19 + 400) : (i * 19 + 500);
  800dc2:	03066663          	bltu	a2,a6,800dee <test_cow_mixed+0x17e>
            if (global_data_test8[i] != expected)
  800dc6:	f9c7881b          	addiw	a6,a5,-100
  800dca:	00e80f63          	beq	a6,a4,800de8 <test_cow_mixed+0x178>
                errors++;
  800dce:	2585                	addiw	a1,a1,1
        for (int i = 0; i < 512; i++)
  800dd0:	00d51c63          	bne	a0,a3,800de8 <test_cow_mixed+0x178>
        if (errors == 0)
  800dd4:	e58d                	bnez	a1,800dfe <test_cow_mixed+0x18e>
            cprintf("  [Child]  Mixed operations: PASS\n");
  800dd6:	00001517          	auipc	a0,0x1
  800dda:	c2a50513          	addi	a0,a0,-982 # 801a00 <error_string+0x868>
  800dde:	ac4ff0ef          	jal	ra,8000a2 <cprintf>
        exit(0);
  800de2:	4501                	li	a0,0
  800de4:	b4aff0ef          	jal	ra,80012e <exit>
  800de8:	0411                	addi	s0,s0,4
  800dea:	27cd                	addiw	a5,a5,19
  800dec:	b7f9                	j	800dba <test_cow_mixed+0x14a>
            if (global_data_test8[i] != expected)
  800dee:	fee781e3          	beq	a5,a4,800dd0 <test_cow_mixed+0x160>
                errors++;
  800df2:	2585                	addiw	a1,a1,1
  800df4:	bff1                	j	800dd0 <test_cow_mixed+0x160>
            errors++;
  800df6:	4789                	li	a5,2
  800df8:	40b785bb          	subw	a1,a5,a1
  800dfc:	bf4d                	j	800dae <test_cow_mixed+0x13e>
            cprintf("  [Child]  Mixed operations: FAIL (errors=%d)\n", errors);
  800dfe:	00001517          	auipc	a0,0x1
  800e02:	c2a50513          	addi	a0,a0,-982 # 801a28 <error_string+0x890>
  800e06:	a9cff0ef          	jal	ra,8000a2 <cprintf>
  800e0a:	bfe1                	j	800de2 <test_cow_mixed+0x172>

0000000000800e0c <main>:

int main(void)
{
  800e0c:	1141                	addi	sp,sp,-16
    cprintf("================================================\n");
  800e0e:	00001517          	auipc	a0,0x1
  800e12:	cda50513          	addi	a0,a0,-806 # 801ae8 <error_string+0x950>
{
  800e16:	e406                	sd	ra,8(sp)
    cprintf("================================================\n");
  800e18:	a8aff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("  COW (Copy-On-Write) Comprehensive Test Suite\n");
  800e1c:	00001517          	auipc	a0,0x1
  800e20:	d0450513          	addi	a0,a0,-764 # 801b20 <error_string+0x988>
  800e24:	a7eff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("================================================\n\n");
  800e28:	00001517          	auipc	a0,0x1
  800e2c:	d2850513          	addi	a0,a0,-728 # 801b50 <error_string+0x9b8>
  800e30:	a72ff0ef          	jal	ra,8000a2 <cprintf>
    
    cprintf("Test Objectives:\n");
  800e34:	00001517          	auipc	a0,0x1
  800e38:	d5450513          	addi	a0,a0,-684 # 801b88 <error_string+0x9f0>
  800e3c:	a66ff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("  1. Verify fork creates shared read-only pages\n");
  800e40:	00001517          	auipc	a0,0x1
  800e44:	d6050513          	addi	a0,a0,-672 # 801ba0 <error_string+0xa08>
  800e48:	a5aff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("  2. Verify parent writes trigger COW copying\n");
  800e4c:	00001517          	auipc	a0,0x1
  800e50:	d8c50513          	addi	a0,a0,-628 # 801bd8 <error_string+0xa40>
  800e54:	a4eff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("  3. Verify child writes trigger COW copying\n");
  800e58:	00001517          	auipc	a0,0x1
  800e5c:	db050513          	addi	a0,a0,-592 # 801c08 <error_string+0xa70>
  800e60:	a42ff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("  4. Verify multiple children with reference counting\n");
  800e64:	00001517          	auipc	a0,0x1
  800e68:	dd450513          	addi	a0,a0,-556 # 801c38 <error_string+0xaa0>
  800e6c:	a36ff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("  5. Verify COW works across multiple pages\n");
  800e70:	00001517          	auipc	a0,0x1
  800e74:	e0050513          	addi	a0,a0,-512 # 801c70 <error_string+0xad8>
  800e78:	a2aff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("  6. Verify selective page copying\n");
  800e7c:	00001517          	auipc	a0,0x1
  800e80:	e2450513          	addi	a0,a0,-476 # 801ca0 <error_string+0xb08>
  800e84:	a1eff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("  7. Verify stack space COW semantics\n");
  800e88:	00001517          	auipc	a0,0x1
  800e8c:	e4050513          	addi	a0,a0,-448 # 801cc8 <error_string+0xb30>
  800e90:	a12ff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("  8. Verify complex mixed operations\n\n");
  800e94:	00001517          	auipc	a0,0x1
  800e98:	e5c50513          	addi	a0,a0,-420 # 801cf0 <error_string+0xb58>
  800e9c:	a06ff0ef          	jal	ra,8000a2 <cprintf>
    
    cprintf("Running tests...\n");
  800ea0:	00001517          	auipc	a0,0x1
  800ea4:	e7850513          	addi	a0,a0,-392 # 801d18 <error_string+0xb80>
  800ea8:	9faff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("================================================\n\n");
  800eac:	00001517          	auipc	a0,0x1
  800eb0:	ca450513          	addi	a0,a0,-860 # 801b50 <error_string+0x9b8>
  800eb4:	9eeff0ef          	jal	ra,8000a2 <cprintf>
    
    // 运行所有测试
    test_cow_read_same();
  800eb8:	ea8ff0ef          	jal	ra,800560 <test_cow_read_same>
    test_cow_parent_write();
  800ebc:	f52ff0ef          	jal	ra,80060e <test_cow_parent_write>
    test_cow_child_write();
  800ec0:	85fff0ef          	jal	ra,80071e <test_cow_child_write>
    test_cow_multiple_fork();
  800ec4:	96bff0ef          	jal	ra,80082e <test_cow_multiple_fork>
    test_cow_cross_page();
  800ec8:	a8fff0ef          	jal	ra,800956 <test_cow_cross_page>
    test_cow_partial_write();
  800ecc:	b7bff0ef          	jal	ra,800a46 <test_cow_partial_write>
    test_cow_stack();
  800ed0:	ca5ff0ef          	jal	ra,800b74 <test_cow_stack>
    test_cow_mixed();
  800ed4:	d9dff0ef          	jal	ra,800c70 <test_cow_mixed>
    
    cprintf("================================================\n");
  800ed8:	00001517          	auipc	a0,0x1
  800edc:	c1050513          	addi	a0,a0,-1008 # 801ae8 <error_string+0x950>
  800ee0:	9c2ff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("All COW tests completed successfully!\n");
  800ee4:	00001517          	auipc	a0,0x1
  800ee8:	e4c50513          	addi	a0,a0,-436 # 801d30 <error_string+0xb98>
  800eec:	9b6ff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("cowtest pass.\n");
  800ef0:	00001517          	auipc	a0,0x1
  800ef4:	e6850513          	addi	a0,a0,-408 # 801d58 <error_string+0xbc0>
  800ef8:	9aaff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("================================================\n");
  800efc:	00001517          	auipc	a0,0x1
  800f00:	bec50513          	addi	a0,a0,-1044 # 801ae8 <error_string+0x950>
  800f04:	99eff0ef          	jal	ra,8000a2 <cprintf>
    
    return 0;
}
  800f08:	60a2                	ld	ra,8(sp)
  800f0a:	4501                	li	a0,0
  800f0c:	0141                	addi	sp,sp,16
  800f0e:	8082                	ret
