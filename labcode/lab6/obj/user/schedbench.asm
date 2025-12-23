
obj/__user_schedbench.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	0d2000ef          	jal	ra,8000f2 <umain>
1:  j 1b
  800024:	a001                	j	800024 <_start+0x4>

0000000000800026 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  800026:	1141                	addi	sp,sp,-16
  800028:	e022                	sd	s0,0(sp)
  80002a:	e406                	sd	ra,8(sp)
  80002c:	842e                	mv	s0,a1
    sys_putc(c);
  80002e:	09a000ef          	jal	ra,8000c8 <sys_putc>
    (*cnt) ++;
  800032:	401c                	lw	a5,0(s0)
}
  800034:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
  800036:	2785                	addiw	a5,a5,1
  800038:	c01c                	sw	a5,0(s0)
}
  80003a:	6402                	ld	s0,0(sp)
  80003c:	0141                	addi	sp,sp,16
  80003e:	8082                	ret

0000000000800040 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  800040:	711d                	addi	sp,sp,-96
    va_list ap;

    va_start(ap, fmt);
  800042:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
  800046:	8e2a                	mv	t3,a0
  800048:	f42e                	sd	a1,40(sp)
  80004a:	f832                	sd	a2,48(sp)
  80004c:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  80004e:	00000517          	auipc	a0,0x0
  800052:	fd850513          	addi	a0,a0,-40 # 800026 <cputch>
  800056:	004c                	addi	a1,sp,4
  800058:	869a                	mv	a3,t1
  80005a:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
  80005c:	ec06                	sd	ra,24(sp)
  80005e:	e0ba                	sd	a4,64(sp)
  800060:	e4be                	sd	a5,72(sp)
  800062:	e8c2                	sd	a6,80(sp)
  800064:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
  800066:	e41a                	sd	t1,8(sp)
    int cnt = 0;
  800068:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  80006a:	100000ef          	jal	ra,80016a <vprintfmt>
    int cnt = vcprintf(fmt, ap);
    va_end(ap);

    return cnt;
}
  80006e:	60e2                	ld	ra,24(sp)
  800070:	4512                	lw	a0,4(sp)
  800072:	6125                	addi	sp,sp,96
  800074:	8082                	ret

0000000000800076 <syscall>:
#include <syscall.h>

#define MAX_ARGS            5

static inline int
syscall(int64_t num, ...) {
  800076:	7175                	addi	sp,sp,-144
  800078:	f8ba                	sd	a4,112(sp)
    va_list ap;
    va_start(ap, num);
    uint64_t a[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i ++) {
        a[i] = va_arg(ap, uint64_t);
  80007a:	e0ba                	sd	a4,64(sp)
  80007c:	0118                	addi	a4,sp,128
syscall(int64_t num, ...) {
  80007e:	e42a                	sd	a0,8(sp)
  800080:	ecae                	sd	a1,88(sp)
  800082:	f0b2                	sd	a2,96(sp)
  800084:	f4b6                	sd	a3,104(sp)
  800086:	fcbe                	sd	a5,120(sp)
  800088:	e142                	sd	a6,128(sp)
  80008a:	e546                	sd	a7,136(sp)
        a[i] = va_arg(ap, uint64_t);
  80008c:	f42e                	sd	a1,40(sp)
  80008e:	f832                	sd	a2,48(sp)
  800090:	fc36                	sd	a3,56(sp)
  800092:	f03a                	sd	a4,32(sp)
  800094:	e4be                	sd	a5,72(sp)
    }
    va_end(ap);
    asm volatile (
  800096:	4522                	lw	a0,8(sp)
  800098:	55a2                	lw	a1,40(sp)
  80009a:	5642                	lw	a2,48(sp)
  80009c:	56e2                	lw	a3,56(sp)
  80009e:	4706                	lw	a4,64(sp)
  8000a0:	47a6                	lw	a5,72(sp)
  8000a2:	00000073          	ecall
  8000a6:	ce2a                	sw	a0,28(sp)
          "m" (a[3]),
          "m" (a[4])
        : "memory"
      );
    return ret;
}
  8000a8:	4572                	lw	a0,28(sp)
  8000aa:	6149                	addi	sp,sp,144
  8000ac:	8082                	ret

00000000008000ae <sys_exit>:

int
sys_exit(int64_t error_code) {
  8000ae:	85aa                	mv	a1,a0
    return syscall(SYS_exit, error_code);
  8000b0:	4505                	li	a0,1
  8000b2:	b7d1                	j	800076 <syscall>

00000000008000b4 <sys_fork>:
}

int
sys_fork(void) {
    return syscall(SYS_fork);
  8000b4:	4509                	li	a0,2
  8000b6:	b7c1                	j	800076 <syscall>

00000000008000b8 <sys_wait>:
}

int
sys_wait(int64_t pid, int *store) {
  8000b8:	862e                	mv	a2,a1
    return syscall(SYS_wait, pid, store);
  8000ba:	85aa                	mv	a1,a0
  8000bc:	450d                	li	a0,3
  8000be:	bf65                	j	800076 <syscall>

00000000008000c0 <sys_yield>:
}

int
sys_yield(void) {
    return syscall(SYS_yield);
  8000c0:	4529                	li	a0,10
  8000c2:	bf55                	j	800076 <syscall>

00000000008000c4 <sys_getpid>:
    return syscall(SYS_kill, pid);
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
  8000c4:	4549                	li	a0,18
  8000c6:	bf45                	j	800076 <syscall>

00000000008000c8 <sys_putc>:
}

int
sys_putc(int64_t c) {
  8000c8:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  8000ca:	4579                	li	a0,30
  8000cc:	b76d                	j	800076 <syscall>

00000000008000ce <sys_gettime>:
    return syscall(SYS_pgdir);
}

int
sys_gettime(void) {
    return syscall(SYS_gettime);
  8000ce:	4545                	li	a0,17
  8000d0:	b75d                	j	800076 <syscall>

00000000008000d2 <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  8000d2:	1141                	addi	sp,sp,-16
  8000d4:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  8000d6:	fd9ff0ef          	jal	ra,8000ae <sys_exit>
    cprintf("BUG: exit failed.\n");
  8000da:	00000517          	auipc	a0,0x0
  8000de:	57e50513          	addi	a0,a0,1406 # 800658 <main+0x150>
  8000e2:	f5fff0ef          	jal	ra,800040 <cprintf>
    while (1);
  8000e6:	a001                	j	8000e6 <exit+0x14>

00000000008000e8 <fork>:
}

int
fork(void) {
    return sys_fork();
  8000e8:	b7f1                	j	8000b4 <sys_fork>

00000000008000ea <waitpid>:
    return sys_wait(0, NULL);
}

int
waitpid(int pid, int *store) {
    return sys_wait(pid, store);
  8000ea:	b7f9                	j	8000b8 <sys_wait>

00000000008000ec <yield>:
}

void
yield(void) {
    sys_yield();
  8000ec:	bfd1                	j	8000c0 <sys_yield>

00000000008000ee <getpid>:
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
  8000ee:	bfd9                	j	8000c4 <sys_getpid>

00000000008000f0 <gettime_msec>:
    sys_pgdir();
}

unsigned int
gettime_msec(void) {
    return (unsigned int)sys_gettime();
  8000f0:	bff9                	j	8000ce <sys_gettime>

00000000008000f2 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  8000f2:	1141                	addi	sp,sp,-16
  8000f4:	e406                	sd	ra,8(sp)
    int ret = main();
  8000f6:	412000ef          	jal	ra,800508 <main>
    exit(ret);
  8000fa:	fd9ff0ef          	jal	ra,8000d2 <exit>

00000000008000fe <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  8000fe:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800102:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  800104:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800108:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  80010a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  80010e:	f022                	sd	s0,32(sp)
  800110:	ec26                	sd	s1,24(sp)
  800112:	e84a                	sd	s2,16(sp)
  800114:	f406                	sd	ra,40(sp)
  800116:	e44e                	sd	s3,8(sp)
  800118:	84aa                	mv	s1,a0
  80011a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  80011c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  800120:	2a01                	sext.w	s4,s4
    if (num >= base) {
  800122:	03067e63          	bgeu	a2,a6,80015e <printnum+0x60>
  800126:	89be                	mv	s3,a5
        while (-- width > 0)
  800128:	00805763          	blez	s0,800136 <printnum+0x38>
  80012c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  80012e:	85ca                	mv	a1,s2
  800130:	854e                	mv	a0,s3
  800132:	9482                	jalr	s1
        while (-- width > 0)
  800134:	fc65                	bnez	s0,80012c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800136:	1a02                	slli	s4,s4,0x20
  800138:	00000797          	auipc	a5,0x0
  80013c:	53878793          	addi	a5,a5,1336 # 800670 <main+0x168>
  800140:	020a5a13          	srli	s4,s4,0x20
  800144:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  800146:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800148:	000a4503          	lbu	a0,0(s4)
}
  80014c:	70a2                	ld	ra,40(sp)
  80014e:	69a2                	ld	s3,8(sp)
  800150:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  800152:	85ca                	mv	a1,s2
  800154:	87a6                	mv	a5,s1
}
  800156:	6942                	ld	s2,16(sp)
  800158:	64e2                	ld	s1,24(sp)
  80015a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  80015c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  80015e:	03065633          	divu	a2,a2,a6
  800162:	8722                	mv	a4,s0
  800164:	f9bff0ef          	jal	ra,8000fe <printnum>
  800168:	b7f9                	j	800136 <printnum+0x38>

000000000080016a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  80016a:	7119                	addi	sp,sp,-128
  80016c:	f4a6                	sd	s1,104(sp)
  80016e:	f0ca                	sd	s2,96(sp)
  800170:	ecce                	sd	s3,88(sp)
  800172:	e8d2                	sd	s4,80(sp)
  800174:	e4d6                	sd	s5,72(sp)
  800176:	e0da                	sd	s6,64(sp)
  800178:	fc5e                	sd	s7,56(sp)
  80017a:	f06a                	sd	s10,32(sp)
  80017c:	fc86                	sd	ra,120(sp)
  80017e:	f8a2                	sd	s0,112(sp)
  800180:	f862                	sd	s8,48(sp)
  800182:	f466                	sd	s9,40(sp)
  800184:	ec6e                	sd	s11,24(sp)
  800186:	892a                	mv	s2,a0
  800188:	84ae                	mv	s1,a1
  80018a:	8d32                	mv	s10,a2
  80018c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80018e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
  800192:	5b7d                	li	s6,-1
  800194:	00000a97          	auipc	s5,0x0
  800198:	510a8a93          	addi	s5,s5,1296 # 8006a4 <main+0x19c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  80019c:	00000b97          	auipc	s7,0x0
  8001a0:	724b8b93          	addi	s7,s7,1828 # 8008c0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001a4:	000d4503          	lbu	a0,0(s10)
  8001a8:	001d0413          	addi	s0,s10,1
  8001ac:	01350a63          	beq	a0,s3,8001c0 <vprintfmt+0x56>
            if (ch == '\0') {
  8001b0:	c121                	beqz	a0,8001f0 <vprintfmt+0x86>
            putch(ch, putdat);
  8001b2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001b4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  8001b6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001b8:	fff44503          	lbu	a0,-1(s0)
  8001bc:	ff351ae3          	bne	a0,s3,8001b0 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  8001c0:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  8001c4:	02000793          	li	a5,32
        lflag = altflag = 0;
  8001c8:	4c81                	li	s9,0
  8001ca:	4881                	li	a7,0
        width = precision = -1;
  8001cc:	5c7d                	li	s8,-1
  8001ce:	5dfd                	li	s11,-1
  8001d0:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  8001d4:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  8001d6:	fdd6059b          	addiw	a1,a2,-35
  8001da:	0ff5f593          	zext.b	a1,a1
  8001de:	00140d13          	addi	s10,s0,1
  8001e2:	04b56263          	bltu	a0,a1,800226 <vprintfmt+0xbc>
  8001e6:	058a                	slli	a1,a1,0x2
  8001e8:	95d6                	add	a1,a1,s5
  8001ea:	4194                	lw	a3,0(a1)
  8001ec:	96d6                	add	a3,a3,s5
  8001ee:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  8001f0:	70e6                	ld	ra,120(sp)
  8001f2:	7446                	ld	s0,112(sp)
  8001f4:	74a6                	ld	s1,104(sp)
  8001f6:	7906                	ld	s2,96(sp)
  8001f8:	69e6                	ld	s3,88(sp)
  8001fa:	6a46                	ld	s4,80(sp)
  8001fc:	6aa6                	ld	s5,72(sp)
  8001fe:	6b06                	ld	s6,64(sp)
  800200:	7be2                	ld	s7,56(sp)
  800202:	7c42                	ld	s8,48(sp)
  800204:	7ca2                	ld	s9,40(sp)
  800206:	7d02                	ld	s10,32(sp)
  800208:	6de2                	ld	s11,24(sp)
  80020a:	6109                	addi	sp,sp,128
  80020c:	8082                	ret
            padc = '0';
  80020e:	87b2                	mv	a5,a2
            goto reswitch;
  800210:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  800214:	846a                	mv	s0,s10
  800216:	00140d13          	addi	s10,s0,1
  80021a:	fdd6059b          	addiw	a1,a2,-35
  80021e:	0ff5f593          	zext.b	a1,a1
  800222:	fcb572e3          	bgeu	a0,a1,8001e6 <vprintfmt+0x7c>
            putch('%', putdat);
  800226:	85a6                	mv	a1,s1
  800228:	02500513          	li	a0,37
  80022c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  80022e:	fff44783          	lbu	a5,-1(s0)
  800232:	8d22                	mv	s10,s0
  800234:	f73788e3          	beq	a5,s3,8001a4 <vprintfmt+0x3a>
  800238:	ffed4783          	lbu	a5,-2(s10)
  80023c:	1d7d                	addi	s10,s10,-1
  80023e:	ff379de3          	bne	a5,s3,800238 <vprintfmt+0xce>
  800242:	b78d                	j	8001a4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  800244:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  800248:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  80024c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  80024e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  800252:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800256:	02d86463          	bltu	a6,a3,80027e <vprintfmt+0x114>
                ch = *fmt;
  80025a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  80025e:	002c169b          	slliw	a3,s8,0x2
  800262:	0186873b          	addw	a4,a3,s8
  800266:	0017171b          	slliw	a4,a4,0x1
  80026a:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  80026c:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  800270:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  800272:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  800276:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  80027a:	fed870e3          	bgeu	a6,a3,80025a <vprintfmt+0xf0>
            if (width < 0)
  80027e:	f40ddce3          	bgez	s11,8001d6 <vprintfmt+0x6c>
                width = precision, precision = -1;
  800282:	8de2                	mv	s11,s8
  800284:	5c7d                	li	s8,-1
  800286:	bf81                	j	8001d6 <vprintfmt+0x6c>
            if (width < 0)
  800288:	fffdc693          	not	a3,s11
  80028c:	96fd                	srai	a3,a3,0x3f
  80028e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  800292:	00144603          	lbu	a2,1(s0)
  800296:	2d81                	sext.w	s11,s11
  800298:	846a                	mv	s0,s10
            goto reswitch;
  80029a:	bf35                	j	8001d6 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  80029c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  8002a0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  8002a4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  8002a6:	846a                	mv	s0,s10
            goto process_precision;
  8002a8:	bfd9                	j	80027e <vprintfmt+0x114>
    if (lflag >= 2) {
  8002aa:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002ac:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002b0:	01174463          	blt	a4,a7,8002b8 <vprintfmt+0x14e>
    else if (lflag) {
  8002b4:	1a088e63          	beqz	a7,800470 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  8002b8:	000a3603          	ld	a2,0(s4)
  8002bc:	46c1                	li	a3,16
  8002be:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002c0:	2781                	sext.w	a5,a5
  8002c2:	876e                	mv	a4,s11
  8002c4:	85a6                	mv	a1,s1
  8002c6:	854a                	mv	a0,s2
  8002c8:	e37ff0ef          	jal	ra,8000fe <printnum>
            break;
  8002cc:	bde1                	j	8001a4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  8002ce:	000a2503          	lw	a0,0(s4)
  8002d2:	85a6                	mv	a1,s1
  8002d4:	0a21                	addi	s4,s4,8
  8002d6:	9902                	jalr	s2
            break;
  8002d8:	b5f1                	j	8001a4 <vprintfmt+0x3a>
    if (lflag >= 2) {
  8002da:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002dc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002e0:	01174463          	blt	a4,a7,8002e8 <vprintfmt+0x17e>
    else if (lflag) {
  8002e4:	18088163          	beqz	a7,800466 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  8002e8:	000a3603          	ld	a2,0(s4)
  8002ec:	46a9                	li	a3,10
  8002ee:	8a2e                	mv	s4,a1
  8002f0:	bfc1                	j	8002c0 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  8002f2:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  8002f6:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  8002f8:	846a                	mv	s0,s10
            goto reswitch;
  8002fa:	bdf1                	j	8001d6 <vprintfmt+0x6c>
            putch(ch, putdat);
  8002fc:	85a6                	mv	a1,s1
  8002fe:	02500513          	li	a0,37
  800302:	9902                	jalr	s2
            break;
  800304:	b545                	j	8001a4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  800306:	00144603          	lbu	a2,1(s0)
            lflag ++;
  80030a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  80030c:	846a                	mv	s0,s10
            goto reswitch;
  80030e:	b5e1                	j	8001d6 <vprintfmt+0x6c>
    if (lflag >= 2) {
  800310:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800312:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800316:	01174463          	blt	a4,a7,80031e <vprintfmt+0x1b4>
    else if (lflag) {
  80031a:	14088163          	beqz	a7,80045c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  80031e:	000a3603          	ld	a2,0(s4)
  800322:	46a1                	li	a3,8
  800324:	8a2e                	mv	s4,a1
  800326:	bf69                	j	8002c0 <vprintfmt+0x156>
            putch('0', putdat);
  800328:	03000513          	li	a0,48
  80032c:	85a6                	mv	a1,s1
  80032e:	e03e                	sd	a5,0(sp)
  800330:	9902                	jalr	s2
            putch('x', putdat);
  800332:	85a6                	mv	a1,s1
  800334:	07800513          	li	a0,120
  800338:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80033a:	0a21                	addi	s4,s4,8
            goto number;
  80033c:	6782                	ld	a5,0(sp)
  80033e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800340:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  800344:	bfb5                	j	8002c0 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  800346:	000a3403          	ld	s0,0(s4)
  80034a:	008a0713          	addi	a4,s4,8
  80034e:	e03a                	sd	a4,0(sp)
  800350:	14040263          	beqz	s0,800494 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  800354:	0fb05763          	blez	s11,800442 <vprintfmt+0x2d8>
  800358:	02d00693          	li	a3,45
  80035c:	0cd79163          	bne	a5,a3,80041e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800360:	00044783          	lbu	a5,0(s0)
  800364:	0007851b          	sext.w	a0,a5
  800368:	cf85                	beqz	a5,8003a0 <vprintfmt+0x236>
  80036a:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  80036e:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800372:	000c4563          	bltz	s8,80037c <vprintfmt+0x212>
  800376:	3c7d                	addiw	s8,s8,-1
  800378:	036c0263          	beq	s8,s6,80039c <vprintfmt+0x232>
                    putch('?', putdat);
  80037c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  80037e:	0e0c8e63          	beqz	s9,80047a <vprintfmt+0x310>
  800382:	3781                	addiw	a5,a5,-32
  800384:	0ef47b63          	bgeu	s0,a5,80047a <vprintfmt+0x310>
                    putch('?', putdat);
  800388:	03f00513          	li	a0,63
  80038c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80038e:	000a4783          	lbu	a5,0(s4)
  800392:	3dfd                	addiw	s11,s11,-1
  800394:	0a05                	addi	s4,s4,1
  800396:	0007851b          	sext.w	a0,a5
  80039a:	ffe1                	bnez	a5,800372 <vprintfmt+0x208>
            for (; width > 0; width --) {
  80039c:	01b05963          	blez	s11,8003ae <vprintfmt+0x244>
  8003a0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  8003a2:	85a6                	mv	a1,s1
  8003a4:	02000513          	li	a0,32
  8003a8:	9902                	jalr	s2
            for (; width > 0; width --) {
  8003aa:	fe0d9be3          	bnez	s11,8003a0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003ae:	6a02                	ld	s4,0(sp)
  8003b0:	bbd5                	j	8001a4 <vprintfmt+0x3a>
    if (lflag >= 2) {
  8003b2:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8003b4:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  8003b8:	01174463          	blt	a4,a7,8003c0 <vprintfmt+0x256>
    else if (lflag) {
  8003bc:	08088d63          	beqz	a7,800456 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  8003c0:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  8003c4:	0a044d63          	bltz	s0,80047e <vprintfmt+0x314>
            num = getint(&ap, lflag);
  8003c8:	8622                	mv	a2,s0
  8003ca:	8a66                	mv	s4,s9
  8003cc:	46a9                	li	a3,10
  8003ce:	bdcd                	j	8002c0 <vprintfmt+0x156>
            err = va_arg(ap, int);
  8003d0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003d4:	4761                	li	a4,24
            err = va_arg(ap, int);
  8003d6:	0a21                	addi	s4,s4,8
            if (err < 0) {
  8003d8:	41f7d69b          	sraiw	a3,a5,0x1f
  8003dc:	8fb5                	xor	a5,a5,a3
  8003de:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003e2:	02d74163          	blt	a4,a3,800404 <vprintfmt+0x29a>
  8003e6:	00369793          	slli	a5,a3,0x3
  8003ea:	97de                	add	a5,a5,s7
  8003ec:	639c                	ld	a5,0(a5)
  8003ee:	cb99                	beqz	a5,800404 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  8003f0:	86be                	mv	a3,a5
  8003f2:	00000617          	auipc	a2,0x0
  8003f6:	2ae60613          	addi	a2,a2,686 # 8006a0 <main+0x198>
  8003fa:	85a6                	mv	a1,s1
  8003fc:	854a                	mv	a0,s2
  8003fe:	0ce000ef          	jal	ra,8004cc <printfmt>
  800402:	b34d                	j	8001a4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  800404:	00000617          	auipc	a2,0x0
  800408:	28c60613          	addi	a2,a2,652 # 800690 <main+0x188>
  80040c:	85a6                	mv	a1,s1
  80040e:	854a                	mv	a0,s2
  800410:	0bc000ef          	jal	ra,8004cc <printfmt>
  800414:	bb41                	j	8001a4 <vprintfmt+0x3a>
                p = "(null)";
  800416:	00000417          	auipc	s0,0x0
  80041a:	27240413          	addi	s0,s0,626 # 800688 <main+0x180>
                for (width -= strnlen(p, precision); width > 0; width --) {
  80041e:	85e2                	mv	a1,s8
  800420:	8522                	mv	a0,s0
  800422:	e43e                	sd	a5,8(sp)
  800424:	0c8000ef          	jal	ra,8004ec <strnlen>
  800428:	40ad8dbb          	subw	s11,s11,a0
  80042c:	01b05b63          	blez	s11,800442 <vprintfmt+0x2d8>
                    putch(padc, putdat);
  800430:	67a2                	ld	a5,8(sp)
  800432:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800436:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  800438:	85a6                	mv	a1,s1
  80043a:	8552                	mv	a0,s4
  80043c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  80043e:	fe0d9ce3          	bnez	s11,800436 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800442:	00044783          	lbu	a5,0(s0)
  800446:	00140a13          	addi	s4,s0,1
  80044a:	0007851b          	sext.w	a0,a5
  80044e:	d3a5                	beqz	a5,8003ae <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  800450:	05e00413          	li	s0,94
  800454:	bf39                	j	800372 <vprintfmt+0x208>
        return va_arg(*ap, int);
  800456:	000a2403          	lw	s0,0(s4)
  80045a:	b7ad                	j	8003c4 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  80045c:	000a6603          	lwu	a2,0(s4)
  800460:	46a1                	li	a3,8
  800462:	8a2e                	mv	s4,a1
  800464:	bdb1                	j	8002c0 <vprintfmt+0x156>
  800466:	000a6603          	lwu	a2,0(s4)
  80046a:	46a9                	li	a3,10
  80046c:	8a2e                	mv	s4,a1
  80046e:	bd89                	j	8002c0 <vprintfmt+0x156>
  800470:	000a6603          	lwu	a2,0(s4)
  800474:	46c1                	li	a3,16
  800476:	8a2e                	mv	s4,a1
  800478:	b5a1                	j	8002c0 <vprintfmt+0x156>
                    putch(ch, putdat);
  80047a:	9902                	jalr	s2
  80047c:	bf09                	j	80038e <vprintfmt+0x224>
                putch('-', putdat);
  80047e:	85a6                	mv	a1,s1
  800480:	02d00513          	li	a0,45
  800484:	e03e                	sd	a5,0(sp)
  800486:	9902                	jalr	s2
                num = -(long long)num;
  800488:	6782                	ld	a5,0(sp)
  80048a:	8a66                	mv	s4,s9
  80048c:	40800633          	neg	a2,s0
  800490:	46a9                	li	a3,10
  800492:	b53d                	j	8002c0 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  800494:	03b05163          	blez	s11,8004b6 <vprintfmt+0x34c>
  800498:	02d00693          	li	a3,45
  80049c:	f6d79de3          	bne	a5,a3,800416 <vprintfmt+0x2ac>
                p = "(null)";
  8004a0:	00000417          	auipc	s0,0x0
  8004a4:	1e840413          	addi	s0,s0,488 # 800688 <main+0x180>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004a8:	02800793          	li	a5,40
  8004ac:	02800513          	li	a0,40
  8004b0:	00140a13          	addi	s4,s0,1
  8004b4:	bd6d                	j	80036e <vprintfmt+0x204>
  8004b6:	00000a17          	auipc	s4,0x0
  8004ba:	1d3a0a13          	addi	s4,s4,467 # 800689 <main+0x181>
  8004be:	02800513          	li	a0,40
  8004c2:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  8004c6:	05e00413          	li	s0,94
  8004ca:	b565                	j	800372 <vprintfmt+0x208>

00000000008004cc <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004cc:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  8004ce:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004d2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004d4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004d6:	ec06                	sd	ra,24(sp)
  8004d8:	f83a                	sd	a4,48(sp)
  8004da:	fc3e                	sd	a5,56(sp)
  8004dc:	e0c2                	sd	a6,64(sp)
  8004de:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  8004e0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004e2:	c89ff0ef          	jal	ra,80016a <vprintfmt>
}
  8004e6:	60e2                	ld	ra,24(sp)
  8004e8:	6161                	addi	sp,sp,80
  8004ea:	8082                	ret

00000000008004ec <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  8004ec:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  8004ee:	e589                	bnez	a1,8004f8 <strnlen+0xc>
  8004f0:	a811                	j	800504 <strnlen+0x18>
        cnt ++;
  8004f2:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  8004f4:	00f58863          	beq	a1,a5,800504 <strnlen+0x18>
  8004f8:	00f50733          	add	a4,a0,a5
  8004fc:	00074703          	lbu	a4,0(a4)
  800500:	fb6d                	bnez	a4,8004f2 <strnlen+0x6>
  800502:	85be                	mv	a1,a5
    }
    return cnt;
}
  800504:	852e                	mv	a0,a1
  800506:	8082                	ret

0000000000800508 <main>:
    cprintf("[IO  ] pid=%d tag=%s ticks=%d elapsed=%dms\n", getpid(), tag, ticks, gettime_msec() - start);
    exit(ticks);
}

int main(void)
{
  800508:	715d                	addi	sp,sp,-80
  80050a:	e0a2                	sd	s0,64(sp)
    cprintf("schedbench: mix cpu/io workers, each ~500ms\n");
  80050c:	00000517          	auipc	a0,0x0
  800510:	47c50513          	addi	a0,a0,1148 # 800988 <error_string+0xc8>
  800514:	0020                	addi	s0,sp,8
{
  800516:	fc26                	sd	s1,56(sp)
  800518:	f84a                	sd	s2,48(sp)
  80051a:	e486                	sd	ra,72(sp)
  80051c:	f44e                	sd	s3,40(sp)
  80051e:	f052                	sd	s4,32(sp)
  800520:	01410913          	addi	s2,sp,20
    cprintf("schedbench: mix cpu/io workers, each ~500ms\n");
  800524:	b1dff0ef          	jal	ra,800040 <cprintf>
  800528:	84a2                	mv	s1,s0
    const int ncpu = 3, nio = 2;
    int pids[5], idx = 0;

    for (int i = 0; i < ncpu; i++)
    {
        if ((pids[idx] = fork()) == 0)
  80052a:	bbfff0ef          	jal	ra,8000e8 <fork>
  80052e:	c088                	sw	a0,0(s1)
  800530:	cd39                	beqz	a0,80058e <main+0x86>
    for (int i = 0; i < ncpu; i++)
  800532:	0491                	addi	s1,s1,4
  800534:	fe991be3          	bne	s2,s1,80052a <main+0x22>
        }
        idx++;
    }
    for (int i = 0; i < nio; i++)
    {
        if ((pids[idx] = fork()) == 0)
  800538:	bb1ff0ef          	jal	ra,8000e8 <fork>
  80053c:	ca2a                	sw	a0,20(sp)
  80053e:	c955                	beqz	a0,8005f2 <main+0xea>
  800540:	ba9ff0ef          	jal	ra,8000e8 <fork>
  800544:	cc2a                	sw	a0,24(sp)
  800546:	01440993          	addi	s3,s0,20

    for (int i = 0; i < idx; i++)
    {
        int status = 0;
        waitpid(pids[i], &status);
        cprintf("child pid=%d exit=%d\n", pids[i], status);
  80054a:	00000917          	auipc	s2,0x0
  80054e:	4de90913          	addi	s2,s2,1246 # 800a28 <error_string+0x168>
        if ((pids[idx] = fork()) == 0)
  800552:	c145                	beqz	a0,8005f2 <main+0xea>
        waitpid(pids[i], &status);
  800554:	4004                	lw	s1,0(s0)
  800556:	004c                	addi	a1,sp,4
        int status = 0;
  800558:	c202                	sw	zero,4(sp)
        waitpid(pids[i], &status);
  80055a:	8526                	mv	a0,s1
  80055c:	b8fff0ef          	jal	ra,8000ea <waitpid>
        cprintf("child pid=%d exit=%d\n", pids[i], status);
  800560:	4612                	lw	a2,4(sp)
    for (int i = 0; i < idx; i++)
  800562:	0411                	addi	s0,s0,4
        cprintf("child pid=%d exit=%d\n", pids[i], status);
  800564:	85a6                	mv	a1,s1
  800566:	854a                	mv	a0,s2
  800568:	ad9ff0ef          	jal	ra,800040 <cprintf>
    for (int i = 0; i < idx; i++)
  80056c:	ff3414e3          	bne	s0,s3,800554 <main+0x4c>
    }

    cprintf("schedbench done.\n");
  800570:	00000517          	auipc	a0,0x0
  800574:	4d050513          	addi	a0,a0,1232 # 800a40 <error_string+0x180>
  800578:	ac9ff0ef          	jal	ra,800040 <cprintf>
    return 0;
}
  80057c:	60a6                	ld	ra,72(sp)
  80057e:	6406                	ld	s0,64(sp)
  800580:	74e2                	ld	s1,56(sp)
  800582:	7942                	ld	s2,48(sp)
  800584:	79a2                	ld	s3,40(sp)
  800586:	7a02                	ld	s4,32(sp)
  800588:	4501                	li	a0,0
  80058a:	6161                	addi	sp,sp,80
  80058c:	8082                	ret
    int start = gettime_msec();
  80058e:	b63ff0ef          	jal	ra,8000f0 <gettime_msec>
  800592:	0005091b          	sext.w	s2,a0
    unsigned long iter = 0;
  800596:	4481                	li	s1,0
    while (gettime_msec() - start < ms)
  800598:	1f300993          	li	s3,499
        for (volatile int i = 0; i < 1000; i++)
  80059c:	3e700413          	li	s0,999
    while (gettime_msec() - start < ms)
  8005a0:	b51ff0ef          	jal	ra,8000f0 <gettime_msec>
  8005a4:	412507bb          	subw	a5,a0,s2
  8005a8:	00f9ed63          	bltu	s3,a5,8005c2 <main+0xba>
        for (volatile int i = 0; i < 1000; i++)
  8005ac:	c202                	sw	zero,4(sp)
  8005ae:	a021                	j	8005b6 <main+0xae>
  8005b0:	4792                	lw	a5,4(sp)
  8005b2:	2785                	addiw	a5,a5,1
  8005b4:	c23e                	sw	a5,4(sp)
  8005b6:	4792                	lw	a5,4(sp)
  8005b8:	2781                	sext.w	a5,a5
  8005ba:	fef45be3          	bge	s0,a5,8005b0 <main+0xa8>
        iter++;
  8005be:	0485                	addi	s1,s1,1
  8005c0:	b7c5                	j	8005a0 <main+0x98>
    cprintf("[CPU ] pid=%d tag=%s iter=%lu elapsed=%dms\n", getpid(), tag, iter, gettime_msec() - start);
  8005c2:	b2dff0ef          	jal	ra,8000ee <getpid>
  8005c6:	842a                	mv	s0,a0
  8005c8:	b29ff0ef          	jal	ra,8000f0 <gettime_msec>
  8005cc:	4125073b          	subw	a4,a0,s2
  8005d0:	86a6                	mv	a3,s1
  8005d2:	00000617          	auipc	a2,0x0
  8005d6:	3e660613          	addi	a2,a2,998 # 8009b8 <error_string+0xf8>
  8005da:	85a2                	mv	a1,s0
  8005dc:	00000517          	auipc	a0,0x0
  8005e0:	3e450513          	addi	a0,a0,996 # 8009c0 <error_string+0x100>
  8005e4:	a5dff0ef          	jal	ra,800040 <cprintf>
    exit((int)(iter & 0xFFFF));
  8005e8:	03049513          	slli	a0,s1,0x30
  8005ec:	9141                	srli	a0,a0,0x30
  8005ee:	ae5ff0ef          	jal	ra,8000d2 <exit>
    int start = gettime_msec();
  8005f2:	affff0ef          	jal	ra,8000f0 <gettime_msec>
  8005f6:	0005099b          	sext.w	s3,a0
    int ticks = 0;
  8005fa:	4901                	li	s2,0
    while (gettime_msec() - start < ms)
  8005fc:	1f300a13          	li	s4,499
        while (gettime_msec() - t0 < 10)
  800600:	44a5                	li	s1,9
    while (gettime_msec() - start < ms)
  800602:	aefff0ef          	jal	ra,8000f0 <gettime_msec>
  800606:	413507bb          	subw	a5,a0,s3
  80060a:	02fa6063          	bltu	s4,a5,80062a <main+0x122>
        yield();
  80060e:	adfff0ef          	jal	ra,8000ec <yield>
        int t0 = gettime_msec();
  800612:	adfff0ef          	jal	ra,8000f0 <gettime_msec>
  800616:	0005041b          	sext.w	s0,a0
        while (gettime_msec() - t0 < 10)
  80061a:	ad7ff0ef          	jal	ra,8000f0 <gettime_msec>
  80061e:	408507bb          	subw	a5,a0,s0
  800622:	fef4fce3          	bgeu	s1,a5,80061a <main+0x112>
        ticks++;
  800626:	2905                	addiw	s2,s2,1
  800628:	bfe9                	j	800602 <main+0xfa>
    cprintf("[IO  ] pid=%d tag=%s ticks=%d elapsed=%dms\n", getpid(), tag, ticks, gettime_msec() - start);
  80062a:	ac5ff0ef          	jal	ra,8000ee <getpid>
  80062e:	842a                	mv	s0,a0
  800630:	ac1ff0ef          	jal	ra,8000f0 <gettime_msec>
  800634:	4135073b          	subw	a4,a0,s3
  800638:	86ca                	mv	a3,s2
  80063a:	00000617          	auipc	a2,0x0
  80063e:	3b660613          	addi	a2,a2,950 # 8009f0 <error_string+0x130>
  800642:	85a2                	mv	a1,s0
  800644:	00000517          	auipc	a0,0x0
  800648:	3b450513          	addi	a0,a0,948 # 8009f8 <error_string+0x138>
  80064c:	9f5ff0ef          	jal	ra,800040 <cprintf>
    exit(ticks);
  800650:	854a                	mv	a0,s2
  800652:	a81ff0ef          	jal	ra,8000d2 <exit>
