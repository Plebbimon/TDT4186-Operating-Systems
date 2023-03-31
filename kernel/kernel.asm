
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a0013103          	ld	sp,-1536(sp) # 80008a00 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	a2070713          	addi	a4,a4,-1504 # 80008a70 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	ffe78793          	addi	a5,a5,-2 # 80006060 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc91f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e8e78793          	addi	a5,a5,-370 # 80000f3a <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:

//
// user write()s to the console go here.
//
int consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
    int i;

    for (i = 0; i < n; i++)
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    {
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	5fe080e7          	jalr	1534(ra) # 80002728 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	792080e7          	jalr	1938(ra) # 800008cc <uartputc>
    for (i = 0; i < n; i++)
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    }

    return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
    for (i = 0; i < n; i++)
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	addi	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	addi	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
    uint target;
    int c;
    char cbuf;

    target = n;
    80000180:	00060b1b          	sext.w	s6,a2
    acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	a2c50513          	addi	a0,a0,-1492 # 80010bb0 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	b0e080e7          	jalr	-1266(ra) # 80000c9a <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    80000194:	00011497          	auipc	s1,0x11
    80000198:	a1c48493          	addi	s1,s1,-1508 # 80010bb0 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	aac90913          	addi	s2,s2,-1364 # 80010c48 <cons+0x98>
    while (n > 0)
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
        while (cons.r == cons.w)
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
            if (killed(myproc()))
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	9ae080e7          	jalr	-1618(ra) # 80001b62 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	3b6080e7          	jalr	950(ra) # 80002572 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
            sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	100080e7          	jalr	256(ra) # 800022ca <sleep>
        while (cons.r == cons.w)
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	9d270713          	addi	a4,a4,-1582 # 80010bb0 <cons>
    800001e6:	0017869b          	addiw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	andi	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

        if (c == C('D'))
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
            }
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	addi	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	4c2080e7          	jalr	1218(ra) # 800026d2 <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
            break;

        dst++;
    8000021e:	0a05                	addi	s4,s4,1
        --n;
    80000220:	39fd                	addiw	s3,s3,-1

        if (c == '\n')
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	98850513          	addi	a0,a0,-1656 # 80010bb0 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	b1e080e7          	jalr	-1250(ra) # 80000d4e <release>

    return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
                release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	97250513          	addi	a0,a0,-1678 # 80010bb0 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	b08080e7          	jalr	-1272(ra) # 80000d4e <release>
                return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	addi	sp,sp,96
    80000264:	8082                	ret
            if (n < target)
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
                cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	9cf72d23          	sw	a5,-1574(a4) # 80010c48 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
    if (c == BACKSPACE)
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
        uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	572080e7          	jalr	1394(ra) # 800007fa <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	addi	sp,sp,16
    80000296:	8082                	ret
        uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	560080e7          	jalr	1376(ra) # 800007fa <uartputc_sync>
        uartputc_sync(' ');
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	554080e7          	jalr	1364(ra) # 800007fa <uartputc_sync>
        uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	54a080e7          	jalr	1354(ra) # 800007fa <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void consoleintr(int c)
{
    800002ba:	1101                	addi	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	addi	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
    acquire(&cons.lock);
    800002c8:	00011517          	auipc	a0,0x11
    800002cc:	8e850513          	addi	a0,a0,-1816 # 80010bb0 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	9ca080e7          	jalr	-1590(ra) # 80000c9a <acquire>

    switch (c)
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
    {
    case C('P'): // Print process list.
        procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	490080e7          	jalr	1168(ra) # 8000277e <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002f6:	00011517          	auipc	a0,0x11
    800002fa:	8ba50513          	addi	a0,a0,-1862 # 80010bb0 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	a50080e7          	jalr	-1456(ra) # 80000d4e <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	addi	sp,sp,32
    80000310:	8082                	ret
    switch (c)
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    8000031a:	00011717          	auipc	a4,0x11
    8000031e:	89670713          	addi	a4,a4,-1898 # 80010bb0 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
            c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
            consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00011797          	auipc	a5,0x11
    80000348:	86c78793          	addi	a5,a5,-1940 # 80010bb0 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addiw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	andi	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
            if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE)
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00011797          	auipc	a5,0x11
    80000376:	8d67a783          	lw	a5,-1834(a5) # 80010c48 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000386:	00011717          	auipc	a4,0x11
    8000038a:	82a70713          	addi	a4,a4,-2006 # 80010bb0 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    80000396:	00011497          	auipc	s1,0x11
    8000039a:	81a48493          	addi	s1,s1,-2022 # 80010bb0 <cons>
        while (cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003a4:	37fd                	addiw	a5,a5,-1
    800003a6:	07f7f713          	andi	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
        while (cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
            consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
        while (cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
        if (cons.e != cons.w)
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	7de70713          	addi	a4,a4,2014 # 80010bb0 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	86f72423          	sw	a5,-1944(a4) # 80010c50 <cons+0xa0>
            consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
            consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	7a278793          	addi	a5,a5,1954 # 80010bb0 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addiw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	andi	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000432:	00011797          	auipc	a5,0x11
    80000436:	80c7ad23          	sw	a2,-2022(a5) # 80010c4c <cons+0x9c>
                wakeup(&cons.r);
    8000043a:	00011517          	auipc	a0,0x11
    8000043e:	80e50513          	addi	a0,a0,-2034 # 80010c48 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	eec080e7          	jalr	-276(ra) # 8000232e <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void consoleinit(void)
{
    8000044c:	1141                	addi	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bcc58593          	addi	a1,a1,-1076 # 80008020 <__func__.1+0x18>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	75450513          	addi	a0,a0,1876 # 80010bb0 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	7a6080e7          	jalr	1958(ra) # 80000c0a <initlock>

    uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	33e080e7          	jalr	830(ra) # 800007aa <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000474:	00021797          	auipc	a5,0x21
    80000478:	8d478793          	addi	a5,a5,-1836 # 80020d48 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	addi	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
    devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	addi	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	addi	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	addi	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	addi	s0,sp,48
    char buf[16];
    int i;
    uint x;

    if (sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
        x = -xx;
    else
        x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	addi	a3,s0,-48

    i = 0;
    800004b2:	4701                	li	a4,0
    do
    {
        buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b9a60613          	addi	a2,a2,-1126 # 80008050 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addiw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	slli	a5,a5,0x20
    800004c8:	9381                	srli	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
    } while ((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	addi	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

    if (sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
        buf[i++] = '-';
    800004e6:	fe070793          	addi	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addiw	a4,a6,2

    while (--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	addi	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	addi	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addiw	a4,a4,-1
    8000050e:	1702                	slli	a4,a4,0x20
    80000510:	9301                	srli	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
        consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
    while (--i >= 0)
    80000522:	14fd                	addi	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	addi	sp,sp,48
    80000532:	8082                	ret
        x = -xx;
    80000534:	40a0053b          	negw	a0,a0
    if (sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
        x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    if (locking)
        release(&pr.lock);
}

void panic(char *s, ...)
{
    8000053c:	711d                	addi	sp,sp,-96
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	addi	s0,sp,32
    80000546:	84aa                	mv	s1,a0
    80000548:	e40c                	sd	a1,8(s0)
    8000054a:	e810                	sd	a2,16(s0)
    8000054c:	ec14                	sd	a3,24(s0)
    8000054e:	f018                	sd	a4,32(s0)
    80000550:	f41c                	sd	a5,40(s0)
    80000552:	03043823          	sd	a6,48(s0)
    80000556:	03143c23          	sd	a7,56(s0)
    pr.locking = 0;
    8000055a:	00010797          	auipc	a5,0x10
    8000055e:	7007ab23          	sw	zero,1814(a5) # 80010c70 <pr+0x18>
    printf("panic: ");
    80000562:	00008517          	auipc	a0,0x8
    80000566:	ac650513          	addi	a0,a0,-1338 # 80008028 <__func__.1+0x20>
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	02e080e7          	jalr	46(ra) # 80000598 <printf>
    printf(s);
    80000572:	8526                	mv	a0,s1
    80000574:	00000097          	auipc	ra,0x0
    80000578:	024080e7          	jalr	36(ra) # 80000598 <printf>
    printf("\n");
    8000057c:	00008517          	auipc	a0,0x8
    80000580:	b0c50513          	addi	a0,a0,-1268 # 80008088 <digits+0x38>
    80000584:	00000097          	auipc	ra,0x0
    80000588:	014080e7          	jalr	20(ra) # 80000598 <printf>
    panicked = 1; // freeze uart output from other CPUs
    8000058c:	4785                	li	a5,1
    8000058e:	00008717          	auipc	a4,0x8
    80000592:	48f72923          	sw	a5,1170(a4) # 80008a20 <panicked>
    for (;;)
    80000596:	a001                	j	80000596 <panic+0x5a>

0000000080000598 <printf>:
{
    80000598:	7131                	addi	sp,sp,-192
    8000059a:	fc86                	sd	ra,120(sp)
    8000059c:	f8a2                	sd	s0,112(sp)
    8000059e:	f4a6                	sd	s1,104(sp)
    800005a0:	f0ca                	sd	s2,96(sp)
    800005a2:	ecce                	sd	s3,88(sp)
    800005a4:	e8d2                	sd	s4,80(sp)
    800005a6:	e4d6                	sd	s5,72(sp)
    800005a8:	e0da                	sd	s6,64(sp)
    800005aa:	fc5e                	sd	s7,56(sp)
    800005ac:	f862                	sd	s8,48(sp)
    800005ae:	f466                	sd	s9,40(sp)
    800005b0:	f06a                	sd	s10,32(sp)
    800005b2:	ec6e                	sd	s11,24(sp)
    800005b4:	0100                	addi	s0,sp,128
    800005b6:	8a2a                	mv	s4,a0
    800005b8:	e40c                	sd	a1,8(s0)
    800005ba:	e810                	sd	a2,16(s0)
    800005bc:	ec14                	sd	a3,24(s0)
    800005be:	f018                	sd	a4,32(s0)
    800005c0:	f41c                	sd	a5,40(s0)
    800005c2:	03043823          	sd	a6,48(s0)
    800005c6:	03143c23          	sd	a7,56(s0)
    locking = pr.locking;
    800005ca:	00010d97          	auipc	s11,0x10
    800005ce:	6a6dad83          	lw	s11,1702(s11) # 80010c70 <pr+0x18>
    if (locking)
    800005d2:	020d9b63          	bnez	s11,80000608 <printf+0x70>
    if (fmt == 0)
    800005d6:	040a0263          	beqz	s4,8000061a <printf+0x82>
    va_start(ap, fmt);
    800005da:	00840793          	addi	a5,s0,8
    800005de:	f8f43423          	sd	a5,-120(s0)
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    800005e2:	000a4503          	lbu	a0,0(s4)
    800005e6:	14050f63          	beqz	a0,80000744 <printf+0x1ac>
    800005ea:	4981                	li	s3,0
        if (c != '%')
    800005ec:	02500a93          	li	s5,37
        switch (c)
    800005f0:	07000b93          	li	s7,112
    consputc('x');
    800005f4:	4d41                	li	s10,16
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f6:	00008b17          	auipc	s6,0x8
    800005fa:	a5ab0b13          	addi	s6,s6,-1446 # 80008050 <digits>
        switch (c)
    800005fe:	07300c93          	li	s9,115
    80000602:	06400c13          	li	s8,100
    80000606:	a82d                	j	80000640 <printf+0xa8>
        acquire(&pr.lock);
    80000608:	00010517          	auipc	a0,0x10
    8000060c:	65050513          	addi	a0,a0,1616 # 80010c58 <pr>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	68a080e7          	jalr	1674(ra) # 80000c9a <acquire>
    80000618:	bf7d                	j	800005d6 <printf+0x3e>
        panic("null fmt");
    8000061a:	00008517          	auipc	a0,0x8
    8000061e:	a1e50513          	addi	a0,a0,-1506 # 80008038 <__func__.1+0x30>
    80000622:	00000097          	auipc	ra,0x0
    80000626:	f1a080e7          	jalr	-230(ra) # 8000053c <panic>
            consputc(c);
    8000062a:	00000097          	auipc	ra,0x0
    8000062e:	c4e080e7          	jalr	-946(ra) # 80000278 <consputc>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    80000632:	2985                	addiw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c503          	lbu	a0,0(a5)
    8000063c:	10050463          	beqz	a0,80000744 <printf+0x1ac>
        if (c != '%')
    80000640:	ff5515e3          	bne	a0,s5,8000062a <printf+0x92>
        c = fmt[++i] & 0xff;
    80000644:	2985                	addiw	s3,s3,1
    80000646:	013a07b3          	add	a5,s4,s3
    8000064a:	0007c783          	lbu	a5,0(a5)
    8000064e:	0007849b          	sext.w	s1,a5
        if (c == 0)
    80000652:	cbed                	beqz	a5,80000744 <printf+0x1ac>
        switch (c)
    80000654:	05778a63          	beq	a5,s7,800006a8 <printf+0x110>
    80000658:	02fbf663          	bgeu	s7,a5,80000684 <printf+0xec>
    8000065c:	09978863          	beq	a5,s9,800006ec <printf+0x154>
    80000660:	07800713          	li	a4,120
    80000664:	0ce79563          	bne	a5,a4,8000072e <printf+0x196>
            printint(va_arg(ap, int), 16, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	85ea                	mv	a1,s10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e1e080e7          	jalr	-482(ra) # 80000498 <printint>
            break;
    80000682:	bf45                	j	80000632 <printf+0x9a>
        switch (c)
    80000684:	09578f63          	beq	a5,s5,80000722 <printf+0x18a>
    80000688:	0b879363          	bne	a5,s8,8000072e <printf+0x196>
            printint(va_arg(ap, int), 10, 1);
    8000068c:	f8843783          	ld	a5,-120(s0)
    80000690:	00878713          	addi	a4,a5,8
    80000694:	f8e43423          	sd	a4,-120(s0)
    80000698:	4605                	li	a2,1
    8000069a:	45a9                	li	a1,10
    8000069c:	4388                	lw	a0,0(a5)
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	dfa080e7          	jalr	-518(ra) # 80000498 <printint>
            break;
    800006a6:	b771                	j	80000632 <printf+0x9a>
            printptr(va_arg(ap, uint64));
    800006a8:	f8843783          	ld	a5,-120(s0)
    800006ac:	00878713          	addi	a4,a5,8
    800006b0:	f8e43423          	sd	a4,-120(s0)
    800006b4:	0007b903          	ld	s2,0(a5)
    consputc('0');
    800006b8:	03000513          	li	a0,48
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bbc080e7          	jalr	-1092(ra) # 80000278 <consputc>
    consputc('x');
    800006c4:	07800513          	li	a0,120
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bb0080e7          	jalr	-1104(ra) # 80000278 <consputc>
    800006d0:	84ea                	mv	s1,s10
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d2:	03c95793          	srli	a5,s2,0x3c
    800006d6:	97da                	add	a5,a5,s6
    800006d8:	0007c503          	lbu	a0,0(a5)
    800006dc:	00000097          	auipc	ra,0x0
    800006e0:	b9c080e7          	jalr	-1124(ra) # 80000278 <consputc>
    for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e4:	0912                	slli	s2,s2,0x4
    800006e6:	34fd                	addiw	s1,s1,-1
    800006e8:	f4ed                	bnez	s1,800006d2 <printf+0x13a>
    800006ea:	b7a1                	j	80000632 <printf+0x9a>
            if ((s = va_arg(ap, char *)) == 0)
    800006ec:	f8843783          	ld	a5,-120(s0)
    800006f0:	00878713          	addi	a4,a5,8
    800006f4:	f8e43423          	sd	a4,-120(s0)
    800006f8:	6384                	ld	s1,0(a5)
    800006fa:	cc89                	beqz	s1,80000714 <printf+0x17c>
            for (; *s; s++)
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	d90d                	beqz	a0,80000632 <printf+0x9a>
                consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b76080e7          	jalr	-1162(ra) # 80000278 <consputc>
            for (; *s; s++)
    8000070a:	0485                	addi	s1,s1,1
    8000070c:	0004c503          	lbu	a0,0(s1)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x16a>
    80000712:	b705                	j	80000632 <printf+0x9a>
                s = "(null)";
    80000714:	00008497          	auipc	s1,0x8
    80000718:	91c48493          	addi	s1,s1,-1764 # 80008030 <__func__.1+0x28>
            for (; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x16a>
            consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b54080e7          	jalr	-1196(ra) # 80000278 <consputc>
            break;
    8000072c:	b719                	j	80000632 <printf+0x9a>
            consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b48080e7          	jalr	-1208(ra) # 80000278 <consputc>
            consputc(c);
    80000738:	8526                	mv	a0,s1
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b3e080e7          	jalr	-1218(ra) # 80000278 <consputc>
            break;
    80000742:	bdc5                	j	80000632 <printf+0x9a>
    if (locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1ce>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
        release(&pr.lock);
    80000766:	00010517          	auipc	a0,0x10
    8000076a:	4f250513          	addi	a0,a0,1266 # 80010c58 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	5e0080e7          	jalr	1504(ra) # 80000d4e <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b0>

0000000080000778 <printfinit>:
        ;
}

void printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
    initlock(&pr.lock, "pr");
    80000782:	00010497          	auipc	s1,0x10
    80000786:	4d648493          	addi	s1,s1,1238 # 80010c58 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8be58593          	addi	a1,a1,-1858 # 80008048 <__func__.1+0x40>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	476080e7          	jalr	1142(ra) # 80000c0a <initlock>
    pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	88e58593          	addi	a1,a1,-1906 # 80008068 <digits+0x18>
    800007e2:	00010517          	auipc	a0,0x10
    800007e6:	49650513          	addi	a0,a0,1174 # 80010c78 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	420080e7          	jalr	1056(ra) # 80000c0a <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	448080e7          	jalr	1096(ra) # 80000c4e <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	2127a783          	lw	a5,530(a5) # 80008a20 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dfe5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f513          	zext.b	a0,s1
    8000082c:	100007b7          	lui	a5,0x10000
    80000830:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	4ba080e7          	jalr	1210(ra) # 80000cee <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008797          	auipc	a5,0x8
    8000084a:	1e27b783          	ld	a5,482(a5) # 80008a28 <uart_tx_r>
    8000084e:	00008717          	auipc	a4,0x8
    80000852:	1e273703          	ld	a4,482(a4) # 80008a30 <uart_tx_w>
    80000856:	06f70a63          	beq	a4,a5,800008ca <uartstart+0x84>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	408a0a13          	addi	s4,s4,1032 # 80010c78 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	1b048493          	addi	s1,s1,432 # 80008a28 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	1b098993          	addi	s3,s3,432 # 80008a30 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	02077713          	andi	a4,a4,32
    80000890:	c705                	beqz	a4,800008b8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000892:	01f7f713          	andi	a4,a5,31
    80000896:	9752                	add	a4,a4,s4
    80000898:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000089c:	0785                	addi	a5,a5,1
    8000089e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	a8c080e7          	jalr	-1396(ra) # 8000232e <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	609c                	ld	a5,0(s1)
    800008b0:	0009b703          	ld	a4,0(s3)
    800008b4:	fcf71ae3          	bne	a4,a5,80000888 <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008de:	00010517          	auipc	a0,0x10
    800008e2:	39a50513          	addi	a0,a0,922 # 80010c78 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	3b4080e7          	jalr	948(ra) # 80000c9a <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	1327a783          	lw	a5,306(a5) # 80008a20 <panicked>
    800008f6:	e7c9                	bnez	a5,80000980 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008717          	auipc	a4,0x8
    800008fc:	13873703          	ld	a4,312(a4) # 80008a30 <uart_tx_w>
    80000900:	00008797          	auipc	a5,0x8
    80000904:	1287b783          	ld	a5,296(a5) # 80008a28 <uart_tx_r>
    80000908:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000090c:	00010997          	auipc	s3,0x10
    80000910:	36c98993          	addi	s3,s3,876 # 80010c78 <uart_tx_lock>
    80000914:	00008497          	auipc	s1,0x8
    80000918:	11448493          	addi	s1,s1,276 # 80008a28 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000091c:	00008917          	auipc	s2,0x8
    80000920:	11490913          	addi	s2,s2,276 # 80008a30 <uart_tx_w>
    80000924:	00e79f63          	bne	a5,a4,80000942 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85ce                	mv	a1,s3
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	99e080e7          	jalr	-1634(ra) # 800022ca <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093703          	ld	a4,0(s2)
    80000938:	609c                	ld	a5,0(s1)
    8000093a:	02078793          	addi	a5,a5,32
    8000093e:	fee785e3          	beq	a5,a4,80000928 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00010497          	auipc	s1,0x10
    80000946:	33648493          	addi	s1,s1,822 # 80010c78 <uart_tx_lock>
    8000094a:	01f77793          	andi	a5,a4,31
    8000094e:	97a6                	add	a5,a5,s1
    80000950:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000954:	0705                	addi	a4,a4,1
    80000956:	00008797          	auipc	a5,0x8
    8000095a:	0ce7bd23          	sd	a4,218(a5) # 80008a30 <uart_tx_w>
  uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee8080e7          	jalr	-280(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	3e6080e7          	jalr	998(ra) # 80000d4e <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret
    for(;;)
    80000980:	a001                	j	80000980 <uartputc+0xb4>

0000000080000982 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000982:	1141                	addi	sp,sp,-16
    80000984:	e422                	sd	s0,8(sp)
    80000986:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000988:	100007b7          	lui	a5,0x10000
    8000098c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000990:	8b85                	andi	a5,a5,1
    80000992:	cb81                	beqz	a5,800009a2 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000994:	100007b7          	lui	a5,0x10000
    80000998:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000099c:	6422                	ld	s0,8(sp)
    8000099e:	0141                	addi	sp,sp,16
    800009a0:	8082                	ret
    return -1;
    800009a2:	557d                	li	a0,-1
    800009a4:	bfe5                	j	8000099c <uartgetc+0x1a>

00000000800009a6 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009a6:	1101                	addi	sp,sp,-32
    800009a8:	ec06                	sd	ra,24(sp)
    800009aa:	e822                	sd	s0,16(sp)
    800009ac:	e426                	sd	s1,8(sp)
    800009ae:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b0:	54fd                	li	s1,-1
    800009b2:	a029                	j	800009bc <uartintr+0x16>
      break;
    consoleintr(c);
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	906080e7          	jalr	-1786(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009bc:	00000097          	auipc	ra,0x0
    800009c0:	fc6080e7          	jalr	-58(ra) # 80000982 <uartgetc>
    if(c == -1)
    800009c4:	fe9518e3          	bne	a0,s1,800009b4 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009c8:	00010497          	auipc	s1,0x10
    800009cc:	2b048493          	addi	s1,s1,688 # 80010c78 <uart_tx_lock>
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2c8080e7          	jalr	712(ra) # 80000c9a <acquire>
  uartstart();
    800009da:	00000097          	auipc	ra,0x0
    800009de:	e6c080e7          	jalr	-404(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009e2:	8526                	mv	a0,s1
    800009e4:	00000097          	auipc	ra,0x0
    800009e8:	36a080e7          	jalr	874(ra) # 80000d4e <release>
}
    800009ec:	60e2                	ld	ra,24(sp)
    800009ee:	6442                	ld	s0,16(sp)
    800009f0:	64a2                	ld	s1,8(sp)
    800009f2:	6105                	addi	sp,sp,32
    800009f4:	8082                	ret

00000000800009f6 <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    800009f6:	1101                	addi	sp,sp,-32
    800009f8:	ec06                	sd	ra,24(sp)
    800009fa:	e822                	sd	s0,16(sp)
    800009fc:	e426                	sd	s1,8(sp)
    800009fe:	e04a                	sd	s2,0(sp)
    80000a00:	1000                	addi	s0,sp,32
    80000a02:	84aa                	mv	s1,a0
    if (MAX_PAGES != 0)
    80000a04:	00008797          	auipc	a5,0x8
    80000a08:	03c7b783          	ld	a5,60(a5) # 80008a40 <MAX_PAGES>
    80000a0c:	c799                	beqz	a5,80000a1a <kfree+0x24>
        assert(FREE_PAGES < MAX_PAGES);
    80000a0e:	00008717          	auipc	a4,0x8
    80000a12:	02a73703          	ld	a4,42(a4) # 80008a38 <FREE_PAGES>
    80000a16:	06f77663          	bgeu	a4,a5,80000a82 <kfree+0x8c>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a1a:	03449793          	slli	a5,s1,0x34
    80000a1e:	efc1                	bnez	a5,80000ab6 <kfree+0xc0>
    80000a20:	00021797          	auipc	a5,0x21
    80000a24:	4c078793          	addi	a5,a5,1216 # 80021ee0 <end>
    80000a28:	08f4e763          	bltu	s1,a5,80000ab6 <kfree+0xc0>
    80000a2c:	47c5                	li	a5,17
    80000a2e:	07ee                	slli	a5,a5,0x1b
    80000a30:	08f4f363          	bgeu	s1,a5,80000ab6 <kfree+0xc0>
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);
    80000a34:	6605                	lui	a2,0x1
    80000a36:	4585                	li	a1,1
    80000a38:	8526                	mv	a0,s1
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	35c080e7          	jalr	860(ra) # 80000d96 <memset>

    r = (struct run *)pa;

    acquire(&kmem.lock);
    80000a42:	00010917          	auipc	s2,0x10
    80000a46:	26e90913          	addi	s2,s2,622 # 80010cb0 <kmem>
    80000a4a:	854a                	mv	a0,s2
    80000a4c:	00000097          	auipc	ra,0x0
    80000a50:	24e080e7          	jalr	590(ra) # 80000c9a <acquire>
    r->next = kmem.freelist;
    80000a54:	01893783          	ld	a5,24(s2)
    80000a58:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000a5a:	00993c23          	sd	s1,24(s2)
    FREE_PAGES++;
    80000a5e:	00008717          	auipc	a4,0x8
    80000a62:	fda70713          	addi	a4,a4,-38 # 80008a38 <FREE_PAGES>
    80000a66:	631c                	ld	a5,0(a4)
    80000a68:	0785                	addi	a5,a5,1
    80000a6a:	e31c                	sd	a5,0(a4)
    release(&kmem.lock);
    80000a6c:	854a                	mv	a0,s2
    80000a6e:	00000097          	auipc	ra,0x0
    80000a72:	2e0080e7          	jalr	736(ra) # 80000d4e <release>
}
    80000a76:	60e2                	ld	ra,24(sp)
    80000a78:	6442                	ld	s0,16(sp)
    80000a7a:	64a2                	ld	s1,8(sp)
    80000a7c:	6902                	ld	s2,0(sp)
    80000a7e:	6105                	addi	sp,sp,32
    80000a80:	8082                	ret
        assert(FREE_PAGES < MAX_PAGES);
    80000a82:	03700693          	li	a3,55
    80000a86:	00007617          	auipc	a2,0x7
    80000a8a:	58260613          	addi	a2,a2,1410 # 80008008 <__func__.1>
    80000a8e:	00007597          	auipc	a1,0x7
    80000a92:	5e258593          	addi	a1,a1,1506 # 80008070 <digits+0x20>
    80000a96:	00007517          	auipc	a0,0x7
    80000a9a:	5ea50513          	addi	a0,a0,1514 # 80008080 <digits+0x30>
    80000a9e:	00000097          	auipc	ra,0x0
    80000aa2:	afa080e7          	jalr	-1286(ra) # 80000598 <printf>
    80000aa6:	00007517          	auipc	a0,0x7
    80000aaa:	5ea50513          	addi	a0,a0,1514 # 80008090 <digits+0x40>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	a8e080e7          	jalr	-1394(ra) # 8000053c <panic>
        panic("kfree");
    80000ab6:	00007517          	auipc	a0,0x7
    80000aba:	5ea50513          	addi	a0,a0,1514 # 800080a0 <digits+0x50>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	a7e080e7          	jalr	-1410(ra) # 8000053c <panic>

0000000080000ac6 <freerange>:
{
    80000ac6:	7179                	addi	sp,sp,-48
    80000ac8:	f406                	sd	ra,40(sp)
    80000aca:	f022                	sd	s0,32(sp)
    80000acc:	ec26                	sd	s1,24(sp)
    80000ace:	e84a                	sd	s2,16(sp)
    80000ad0:	e44e                	sd	s3,8(sp)
    80000ad2:	e052                	sd	s4,0(sp)
    80000ad4:	1800                	addi	s0,sp,48
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000ad6:	6785                	lui	a5,0x1
    80000ad8:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000adc:	00e504b3          	add	s1,a0,a4
    80000ae0:	777d                	lui	a4,0xfffff
    80000ae2:	8cf9                	and	s1,s1,a4
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000ae4:	94be                	add	s1,s1,a5
    80000ae6:	0095ee63          	bltu	a1,s1,80000b02 <freerange+0x3c>
    80000aea:	892e                	mv	s2,a1
        kfree(p);
    80000aec:	7a7d                	lui	s4,0xfffff
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000aee:	6985                	lui	s3,0x1
        kfree(p);
    80000af0:	01448533          	add	a0,s1,s4
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	f02080e7          	jalr	-254(ra) # 800009f6 <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000afc:	94ce                	add	s1,s1,s3
    80000afe:	fe9979e3          	bgeu	s2,s1,80000af0 <freerange+0x2a>
}
    80000b02:	70a2                	ld	ra,40(sp)
    80000b04:	7402                	ld	s0,32(sp)
    80000b06:	64e2                	ld	s1,24(sp)
    80000b08:	6942                	ld	s2,16(sp)
    80000b0a:	69a2                	ld	s3,8(sp)
    80000b0c:	6a02                	ld	s4,0(sp)
    80000b0e:	6145                	addi	sp,sp,48
    80000b10:	8082                	ret

0000000080000b12 <kinit>:
{
    80000b12:	1141                	addi	sp,sp,-16
    80000b14:	e406                	sd	ra,8(sp)
    80000b16:	e022                	sd	s0,0(sp)
    80000b18:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000b1a:	00007597          	auipc	a1,0x7
    80000b1e:	58e58593          	addi	a1,a1,1422 # 800080a8 <digits+0x58>
    80000b22:	00010517          	auipc	a0,0x10
    80000b26:	18e50513          	addi	a0,a0,398 # 80010cb0 <kmem>
    80000b2a:	00000097          	auipc	ra,0x0
    80000b2e:	0e0080e7          	jalr	224(ra) # 80000c0a <initlock>
    freerange(end, (void *)PHYSTOP);
    80000b32:	45c5                	li	a1,17
    80000b34:	05ee                	slli	a1,a1,0x1b
    80000b36:	00021517          	auipc	a0,0x21
    80000b3a:	3aa50513          	addi	a0,a0,938 # 80021ee0 <end>
    80000b3e:	00000097          	auipc	ra,0x0
    80000b42:	f88080e7          	jalr	-120(ra) # 80000ac6 <freerange>
    MAX_PAGES = FREE_PAGES;
    80000b46:	00008797          	auipc	a5,0x8
    80000b4a:	ef27b783          	ld	a5,-270(a5) # 80008a38 <FREE_PAGES>
    80000b4e:	00008717          	auipc	a4,0x8
    80000b52:	eef73923          	sd	a5,-270(a4) # 80008a40 <MAX_PAGES>
}
    80000b56:	60a2                	ld	ra,8(sp)
    80000b58:	6402                	ld	s0,0(sp)
    80000b5a:	0141                	addi	sp,sp,16
    80000b5c:	8082                	ret

0000000080000b5e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
    assert(FREE_PAGES > 0);
    80000b68:	00008797          	auipc	a5,0x8
    80000b6c:	ed07b783          	ld	a5,-304(a5) # 80008a38 <FREE_PAGES>
    80000b70:	cbb1                	beqz	a5,80000bc4 <kalloc+0x66>
    struct run *r;

    acquire(&kmem.lock);
    80000b72:	00010497          	auipc	s1,0x10
    80000b76:	13e48493          	addi	s1,s1,318 # 80010cb0 <kmem>
    80000b7a:	8526                	mv	a0,s1
    80000b7c:	00000097          	auipc	ra,0x0
    80000b80:	11e080e7          	jalr	286(ra) # 80000c9a <acquire>
    r = kmem.freelist;
    80000b84:	6c84                	ld	s1,24(s1)
    if (r)
    80000b86:	c8ad                	beqz	s1,80000bf8 <kalloc+0x9a>
        kmem.freelist = r->next;
    80000b88:	609c                	ld	a5,0(s1)
    80000b8a:	00010517          	auipc	a0,0x10
    80000b8e:	12650513          	addi	a0,a0,294 # 80010cb0 <kmem>
    80000b92:	ed1c                	sd	a5,24(a0)
    release(&kmem.lock);
    80000b94:	00000097          	auipc	ra,0x0
    80000b98:	1ba080e7          	jalr	442(ra) # 80000d4e <release>

    if (r)
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000b9c:	6605                	lui	a2,0x1
    80000b9e:	4595                	li	a1,5
    80000ba0:	8526                	mv	a0,s1
    80000ba2:	00000097          	auipc	ra,0x0
    80000ba6:	1f4080e7          	jalr	500(ra) # 80000d96 <memset>
    FREE_PAGES--;
    80000baa:	00008717          	auipc	a4,0x8
    80000bae:	e8e70713          	addi	a4,a4,-370 # 80008a38 <FREE_PAGES>
    80000bb2:	631c                	ld	a5,0(a4)
    80000bb4:	17fd                	addi	a5,a5,-1
    80000bb6:	e31c                	sd	a5,0(a4)
    return (void *)r;
}
    80000bb8:	8526                	mv	a0,s1
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret
    assert(FREE_PAGES > 0);
    80000bc4:	04f00693          	li	a3,79
    80000bc8:	00007617          	auipc	a2,0x7
    80000bcc:	43860613          	addi	a2,a2,1080 # 80008000 <etext>
    80000bd0:	00007597          	auipc	a1,0x7
    80000bd4:	4a058593          	addi	a1,a1,1184 # 80008070 <digits+0x20>
    80000bd8:	00007517          	auipc	a0,0x7
    80000bdc:	4a850513          	addi	a0,a0,1192 # 80008080 <digits+0x30>
    80000be0:	00000097          	auipc	ra,0x0
    80000be4:	9b8080e7          	jalr	-1608(ra) # 80000598 <printf>
    80000be8:	00007517          	auipc	a0,0x7
    80000bec:	4a850513          	addi	a0,a0,1192 # 80008090 <digits+0x40>
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	94c080e7          	jalr	-1716(ra) # 8000053c <panic>
    release(&kmem.lock);
    80000bf8:	00010517          	auipc	a0,0x10
    80000bfc:	0b850513          	addi	a0,a0,184 # 80010cb0 <kmem>
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	14e080e7          	jalr	334(ra) # 80000d4e <release>
    if (r)
    80000c08:	b74d                	j	80000baa <kalloc+0x4c>

0000000080000c0a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c0a:	1141                	addi	sp,sp,-16
    80000c0c:	e422                	sd	s0,8(sp)
    80000c0e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c10:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c12:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c16:	00053823          	sd	zero,16(a0)
}
    80000c1a:	6422                	ld	s0,8(sp)
    80000c1c:	0141                	addi	sp,sp,16
    80000c1e:	8082                	ret

0000000080000c20 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c20:	411c                	lw	a5,0(a0)
    80000c22:	e399                	bnez	a5,80000c28 <holding+0x8>
    80000c24:	4501                	li	a0,0
  return r;
}
    80000c26:	8082                	ret
{
    80000c28:	1101                	addi	sp,sp,-32
    80000c2a:	ec06                	sd	ra,24(sp)
    80000c2c:	e822                	sd	s0,16(sp)
    80000c2e:	e426                	sd	s1,8(sp)
    80000c30:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c32:	6904                	ld	s1,16(a0)
    80000c34:	00001097          	auipc	ra,0x1
    80000c38:	f12080e7          	jalr	-238(ra) # 80001b46 <mycpu>
    80000c3c:	40a48533          	sub	a0,s1,a0
    80000c40:	00153513          	seqz	a0,a0
}
    80000c44:	60e2                	ld	ra,24(sp)
    80000c46:	6442                	ld	s0,16(sp)
    80000c48:	64a2                	ld	s1,8(sp)
    80000c4a:	6105                	addi	sp,sp,32
    80000c4c:	8082                	ret

0000000080000c4e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c4e:	1101                	addi	sp,sp,-32
    80000c50:	ec06                	sd	ra,24(sp)
    80000c52:	e822                	sd	s0,16(sp)
    80000c54:	e426                	sd	s1,8(sp)
    80000c56:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c58:	100024f3          	csrr	s1,sstatus
    80000c5c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c60:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c62:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c66:	00001097          	auipc	ra,0x1
    80000c6a:	ee0080e7          	jalr	-288(ra) # 80001b46 <mycpu>
    80000c6e:	5d3c                	lw	a5,120(a0)
    80000c70:	cf89                	beqz	a5,80000c8a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c72:	00001097          	auipc	ra,0x1
    80000c76:	ed4080e7          	jalr	-300(ra) # 80001b46 <mycpu>
    80000c7a:	5d3c                	lw	a5,120(a0)
    80000c7c:	2785                	addiw	a5,a5,1
    80000c7e:	dd3c                	sw	a5,120(a0)
}
    80000c80:	60e2                	ld	ra,24(sp)
    80000c82:	6442                	ld	s0,16(sp)
    80000c84:	64a2                	ld	s1,8(sp)
    80000c86:	6105                	addi	sp,sp,32
    80000c88:	8082                	ret
    mycpu()->intena = old;
    80000c8a:	00001097          	auipc	ra,0x1
    80000c8e:	ebc080e7          	jalr	-324(ra) # 80001b46 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c92:	8085                	srli	s1,s1,0x1
    80000c94:	8885                	andi	s1,s1,1
    80000c96:	dd64                	sw	s1,124(a0)
    80000c98:	bfe9                	j	80000c72 <push_off+0x24>

0000000080000c9a <acquire>:
{
    80000c9a:	1101                	addi	sp,sp,-32
    80000c9c:	ec06                	sd	ra,24(sp)
    80000c9e:	e822                	sd	s0,16(sp)
    80000ca0:	e426                	sd	s1,8(sp)
    80000ca2:	1000                	addi	s0,sp,32
    80000ca4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000ca6:	00000097          	auipc	ra,0x0
    80000caa:	fa8080e7          	jalr	-88(ra) # 80000c4e <push_off>
  if(holding(lk))
    80000cae:	8526                	mv	a0,s1
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f70080e7          	jalr	-144(ra) # 80000c20 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cb8:	4705                	li	a4,1
  if(holding(lk))
    80000cba:	e115                	bnez	a0,80000cde <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cbc:	87ba                	mv	a5,a4
    80000cbe:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cc2:	2781                	sext.w	a5,a5
    80000cc4:	ffe5                	bnez	a5,80000cbc <acquire+0x22>
  __sync_synchronize();
    80000cc6:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000cca:	00001097          	auipc	ra,0x1
    80000cce:	e7c080e7          	jalr	-388(ra) # 80001b46 <mycpu>
    80000cd2:	e888                	sd	a0,16(s1)
}
    80000cd4:	60e2                	ld	ra,24(sp)
    80000cd6:	6442                	ld	s0,16(sp)
    80000cd8:	64a2                	ld	s1,8(sp)
    80000cda:	6105                	addi	sp,sp,32
    80000cdc:	8082                	ret
    panic("acquire");
    80000cde:	00007517          	auipc	a0,0x7
    80000ce2:	3d250513          	addi	a0,a0,978 # 800080b0 <digits+0x60>
    80000ce6:	00000097          	auipc	ra,0x0
    80000cea:	856080e7          	jalr	-1962(ra) # 8000053c <panic>

0000000080000cee <pop_off>:

void
pop_off(void)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e406                	sd	ra,8(sp)
    80000cf2:	e022                	sd	s0,0(sp)
    80000cf4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cf6:	00001097          	auipc	ra,0x1
    80000cfa:	e50080e7          	jalr	-432(ra) # 80001b46 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cfe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d02:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d04:	e78d                	bnez	a5,80000d2e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d06:	5d3c                	lw	a5,120(a0)
    80000d08:	02f05b63          	blez	a5,80000d3e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d0c:	37fd                	addiw	a5,a5,-1
    80000d0e:	0007871b          	sext.w	a4,a5
    80000d12:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d14:	eb09                	bnez	a4,80000d26 <pop_off+0x38>
    80000d16:	5d7c                	lw	a5,124(a0)
    80000d18:	c799                	beqz	a5,80000d26 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d1e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d22:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d26:	60a2                	ld	ra,8(sp)
    80000d28:	6402                	ld	s0,0(sp)
    80000d2a:	0141                	addi	sp,sp,16
    80000d2c:	8082                	ret
    panic("pop_off - interruptible");
    80000d2e:	00007517          	auipc	a0,0x7
    80000d32:	38a50513          	addi	a0,a0,906 # 800080b8 <digits+0x68>
    80000d36:	00000097          	auipc	ra,0x0
    80000d3a:	806080e7          	jalr	-2042(ra) # 8000053c <panic>
    panic("pop_off");
    80000d3e:	00007517          	auipc	a0,0x7
    80000d42:	39250513          	addi	a0,a0,914 # 800080d0 <digits+0x80>
    80000d46:	fffff097          	auipc	ra,0xfffff
    80000d4a:	7f6080e7          	jalr	2038(ra) # 8000053c <panic>

0000000080000d4e <release>:
{
    80000d4e:	1101                	addi	sp,sp,-32
    80000d50:	ec06                	sd	ra,24(sp)
    80000d52:	e822                	sd	s0,16(sp)
    80000d54:	e426                	sd	s1,8(sp)
    80000d56:	1000                	addi	s0,sp,32
    80000d58:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d5a:	00000097          	auipc	ra,0x0
    80000d5e:	ec6080e7          	jalr	-314(ra) # 80000c20 <holding>
    80000d62:	c115                	beqz	a0,80000d86 <release+0x38>
  lk->cpu = 0;
    80000d64:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d68:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d6c:	0f50000f          	fence	iorw,ow
    80000d70:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d74:	00000097          	auipc	ra,0x0
    80000d78:	f7a080e7          	jalr	-134(ra) # 80000cee <pop_off>
}
    80000d7c:	60e2                	ld	ra,24(sp)
    80000d7e:	6442                	ld	s0,16(sp)
    80000d80:	64a2                	ld	s1,8(sp)
    80000d82:	6105                	addi	sp,sp,32
    80000d84:	8082                	ret
    panic("release");
    80000d86:	00007517          	auipc	a0,0x7
    80000d8a:	35250513          	addi	a0,a0,850 # 800080d8 <digits+0x88>
    80000d8e:	fffff097          	auipc	ra,0xfffff
    80000d92:	7ae080e7          	jalr	1966(ra) # 8000053c <panic>

0000000080000d96 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d9c:	ca19                	beqz	a2,80000db2 <memset+0x1c>
    80000d9e:	87aa                	mv	a5,a0
    80000da0:	1602                	slli	a2,a2,0x20
    80000da2:	9201                	srli	a2,a2,0x20
    80000da4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000da8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000dac:	0785                	addi	a5,a5,1
    80000dae:	fee79de3          	bne	a5,a4,80000da8 <memset+0x12>
  }
  return dst;
}
    80000db2:	6422                	ld	s0,8(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dbe:	ca05                	beqz	a2,80000dee <memcmp+0x36>
    80000dc0:	fff6069b          	addiw	a3,a2,-1
    80000dc4:	1682                	slli	a3,a3,0x20
    80000dc6:	9281                	srli	a3,a3,0x20
    80000dc8:	0685                	addi	a3,a3,1
    80000dca:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000dcc:	00054783          	lbu	a5,0(a0)
    80000dd0:	0005c703          	lbu	a4,0(a1)
    80000dd4:	00e79863          	bne	a5,a4,80000de4 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000dd8:	0505                	addi	a0,a0,1
    80000dda:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ddc:	fed518e3          	bne	a0,a3,80000dcc <memcmp+0x14>
  }

  return 0;
    80000de0:	4501                	li	a0,0
    80000de2:	a019                	j	80000de8 <memcmp+0x30>
      return *s1 - *s2;
    80000de4:	40e7853b          	subw	a0,a5,a4
}
    80000de8:	6422                	ld	s0,8(sp)
    80000dea:	0141                	addi	sp,sp,16
    80000dec:	8082                	ret
  return 0;
    80000dee:	4501                	li	a0,0
    80000df0:	bfe5                	j	80000de8 <memcmp+0x30>

0000000080000df2 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000df2:	1141                	addi	sp,sp,-16
    80000df4:	e422                	sd	s0,8(sp)
    80000df6:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000df8:	c205                	beqz	a2,80000e18 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dfa:	02a5e263          	bltu	a1,a0,80000e1e <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dfe:	1602                	slli	a2,a2,0x20
    80000e00:	9201                	srli	a2,a2,0x20
    80000e02:	00c587b3          	add	a5,a1,a2
{
    80000e06:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e08:	0585                	addi	a1,a1,1
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	fff5c683          	lbu	a3,-1(a1)
    80000e10:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e14:	fef59ae3          	bne	a1,a5,80000e08 <memmove+0x16>

  return dst;
}
    80000e18:	6422                	ld	s0,8(sp)
    80000e1a:	0141                	addi	sp,sp,16
    80000e1c:	8082                	ret
  if(s < d && s + n > d){
    80000e1e:	02061693          	slli	a3,a2,0x20
    80000e22:	9281                	srli	a3,a3,0x20
    80000e24:	00d58733          	add	a4,a1,a3
    80000e28:	fce57be3          	bgeu	a0,a4,80000dfe <memmove+0xc>
    d += n;
    80000e2c:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e2e:	fff6079b          	addiw	a5,a2,-1
    80000e32:	1782                	slli	a5,a5,0x20
    80000e34:	9381                	srli	a5,a5,0x20
    80000e36:	fff7c793          	not	a5,a5
    80000e3a:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e3c:	177d                	addi	a4,a4,-1
    80000e3e:	16fd                	addi	a3,a3,-1
    80000e40:	00074603          	lbu	a2,0(a4)
    80000e44:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e48:	fee79ae3          	bne	a5,a4,80000e3c <memmove+0x4a>
    80000e4c:	b7f1                	j	80000e18 <memmove+0x26>

0000000080000e4e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e406                	sd	ra,8(sp)
    80000e52:	e022                	sd	s0,0(sp)
    80000e54:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e56:	00000097          	auipc	ra,0x0
    80000e5a:	f9c080e7          	jalr	-100(ra) # 80000df2 <memmove>
}
    80000e5e:	60a2                	ld	ra,8(sp)
    80000e60:	6402                	ld	s0,0(sp)
    80000e62:	0141                	addi	sp,sp,16
    80000e64:	8082                	ret

0000000080000e66 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e66:	1141                	addi	sp,sp,-16
    80000e68:	e422                	sd	s0,8(sp)
    80000e6a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e6c:	ce11                	beqz	a2,80000e88 <strncmp+0x22>
    80000e6e:	00054783          	lbu	a5,0(a0)
    80000e72:	cf89                	beqz	a5,80000e8c <strncmp+0x26>
    80000e74:	0005c703          	lbu	a4,0(a1)
    80000e78:	00f71a63          	bne	a4,a5,80000e8c <strncmp+0x26>
    n--, p++, q++;
    80000e7c:	367d                	addiw	a2,a2,-1
    80000e7e:	0505                	addi	a0,a0,1
    80000e80:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e82:	f675                	bnez	a2,80000e6e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e84:	4501                	li	a0,0
    80000e86:	a809                	j	80000e98 <strncmp+0x32>
    80000e88:	4501                	li	a0,0
    80000e8a:	a039                	j	80000e98 <strncmp+0x32>
  if(n == 0)
    80000e8c:	ca09                	beqz	a2,80000e9e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e8e:	00054503          	lbu	a0,0(a0)
    80000e92:	0005c783          	lbu	a5,0(a1)
    80000e96:	9d1d                	subw	a0,a0,a5
}
    80000e98:	6422                	ld	s0,8(sp)
    80000e9a:	0141                	addi	sp,sp,16
    80000e9c:	8082                	ret
    return 0;
    80000e9e:	4501                	li	a0,0
    80000ea0:	bfe5                	j	80000e98 <strncmp+0x32>

0000000080000ea2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ea2:	1141                	addi	sp,sp,-16
    80000ea4:	e422                	sd	s0,8(sp)
    80000ea6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ea8:	87aa                	mv	a5,a0
    80000eaa:	86b2                	mv	a3,a2
    80000eac:	367d                	addiw	a2,a2,-1
    80000eae:	00d05963          	blez	a3,80000ec0 <strncpy+0x1e>
    80000eb2:	0785                	addi	a5,a5,1
    80000eb4:	0005c703          	lbu	a4,0(a1)
    80000eb8:	fee78fa3          	sb	a4,-1(a5)
    80000ebc:	0585                	addi	a1,a1,1
    80000ebe:	f775                	bnez	a4,80000eaa <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ec0:	873e                	mv	a4,a5
    80000ec2:	9fb5                	addw	a5,a5,a3
    80000ec4:	37fd                	addiw	a5,a5,-1
    80000ec6:	00c05963          	blez	a2,80000ed8 <strncpy+0x36>
    *s++ = 0;
    80000eca:	0705                	addi	a4,a4,1
    80000ecc:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000ed0:	40e786bb          	subw	a3,a5,a4
    80000ed4:	fed04be3          	bgtz	a3,80000eca <strncpy+0x28>
  return os;
}
    80000ed8:	6422                	ld	s0,8(sp)
    80000eda:	0141                	addi	sp,sp,16
    80000edc:	8082                	ret

0000000080000ede <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ede:	1141                	addi	sp,sp,-16
    80000ee0:	e422                	sd	s0,8(sp)
    80000ee2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ee4:	02c05363          	blez	a2,80000f0a <safestrcpy+0x2c>
    80000ee8:	fff6069b          	addiw	a3,a2,-1
    80000eec:	1682                	slli	a3,a3,0x20
    80000eee:	9281                	srli	a3,a3,0x20
    80000ef0:	96ae                	add	a3,a3,a1
    80000ef2:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ef4:	00d58963          	beq	a1,a3,80000f06 <safestrcpy+0x28>
    80000ef8:	0585                	addi	a1,a1,1
    80000efa:	0785                	addi	a5,a5,1
    80000efc:	fff5c703          	lbu	a4,-1(a1)
    80000f00:	fee78fa3          	sb	a4,-1(a5)
    80000f04:	fb65                	bnez	a4,80000ef4 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f06:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f0a:	6422                	ld	s0,8(sp)
    80000f0c:	0141                	addi	sp,sp,16
    80000f0e:	8082                	ret

0000000080000f10 <strlen>:

int
strlen(const char *s)
{
    80000f10:	1141                	addi	sp,sp,-16
    80000f12:	e422                	sd	s0,8(sp)
    80000f14:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f16:	00054783          	lbu	a5,0(a0)
    80000f1a:	cf91                	beqz	a5,80000f36 <strlen+0x26>
    80000f1c:	0505                	addi	a0,a0,1
    80000f1e:	87aa                	mv	a5,a0
    80000f20:	86be                	mv	a3,a5
    80000f22:	0785                	addi	a5,a5,1
    80000f24:	fff7c703          	lbu	a4,-1(a5)
    80000f28:	ff65                	bnez	a4,80000f20 <strlen+0x10>
    80000f2a:	40a6853b          	subw	a0,a3,a0
    80000f2e:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000f30:	6422                	ld	s0,8(sp)
    80000f32:	0141                	addi	sp,sp,16
    80000f34:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f36:	4501                	li	a0,0
    80000f38:	bfe5                	j	80000f30 <strlen+0x20>

0000000080000f3a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f3a:	1141                	addi	sp,sp,-16
    80000f3c:	e406                	sd	ra,8(sp)
    80000f3e:	e022                	sd	s0,0(sp)
    80000f40:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	bf4080e7          	jalr	-1036(ra) # 80001b36 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f4a:	00008717          	auipc	a4,0x8
    80000f4e:	afe70713          	addi	a4,a4,-1282 # 80008a48 <started>
  if(cpuid() == 0){
    80000f52:	c139                	beqz	a0,80000f98 <main+0x5e>
    while(started == 0)
    80000f54:	431c                	lw	a5,0(a4)
    80000f56:	2781                	sext.w	a5,a5
    80000f58:	dff5                	beqz	a5,80000f54 <main+0x1a>
      ;
    __sync_synchronize();
    80000f5a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	bd8080e7          	jalr	-1064(ra) # 80001b36 <cpuid>
    80000f66:	85aa                	mv	a1,a0
    80000f68:	00007517          	auipc	a0,0x7
    80000f6c:	19050513          	addi	a0,a0,400 # 800080f8 <digits+0xa8>
    80000f70:	fffff097          	auipc	ra,0xfffff
    80000f74:	628080e7          	jalr	1576(ra) # 80000598 <printf>
    kvminithart();    // turn on paging
    80000f78:	00000097          	auipc	ra,0x0
    80000f7c:	0d8080e7          	jalr	216(ra) # 80001050 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f80:	00002097          	auipc	ra,0x2
    80000f84:	ae4080e7          	jalr	-1308(ra) # 80002a64 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	118080e7          	jalr	280(ra) # 800060a0 <plicinithart>
  }

  scheduler();        
    80000f90:	00001097          	auipc	ra,0x1
    80000f94:	218080e7          	jalr	536(ra) # 800021a8 <scheduler>
    consoleinit();
    80000f98:	fffff097          	auipc	ra,0xfffff
    80000f9c:	4b4080e7          	jalr	1204(ra) # 8000044c <consoleinit>
    printfinit();
    80000fa0:	fffff097          	auipc	ra,0xfffff
    80000fa4:	7d8080e7          	jalr	2008(ra) # 80000778 <printfinit>
    printf("\n");
    80000fa8:	00007517          	auipc	a0,0x7
    80000fac:	0e050513          	addi	a0,a0,224 # 80008088 <digits+0x38>
    80000fb0:	fffff097          	auipc	ra,0xfffff
    80000fb4:	5e8080e7          	jalr	1512(ra) # 80000598 <printf>
    printf("xv6 kernel is booting\n");
    80000fb8:	00007517          	auipc	a0,0x7
    80000fbc:	12850513          	addi	a0,a0,296 # 800080e0 <digits+0x90>
    80000fc0:	fffff097          	auipc	ra,0xfffff
    80000fc4:	5d8080e7          	jalr	1496(ra) # 80000598 <printf>
    printf("\n");
    80000fc8:	00007517          	auipc	a0,0x7
    80000fcc:	0c050513          	addi	a0,a0,192 # 80008088 <digits+0x38>
    80000fd0:	fffff097          	auipc	ra,0xfffff
    80000fd4:	5c8080e7          	jalr	1480(ra) # 80000598 <printf>
    kinit();         // physical page allocator
    80000fd8:	00000097          	auipc	ra,0x0
    80000fdc:	b3a080e7          	jalr	-1222(ra) # 80000b12 <kinit>
    kvminit();       // create kernel page table
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	326080e7          	jalr	806(ra) # 80001306 <kvminit>
    kvminithart();   // turn on paging
    80000fe8:	00000097          	auipc	ra,0x0
    80000fec:	068080e7          	jalr	104(ra) # 80001050 <kvminithart>
    procinit();      // process table
    80000ff0:	00001097          	auipc	ra,0x1
    80000ff4:	a6e080e7          	jalr	-1426(ra) # 80001a5e <procinit>
    trapinit();      // trap vectors
    80000ff8:	00002097          	auipc	ra,0x2
    80000ffc:	a44080e7          	jalr	-1468(ra) # 80002a3c <trapinit>
    trapinithart();  // install kernel trap vector
    80001000:	00002097          	auipc	ra,0x2
    80001004:	a64080e7          	jalr	-1436(ra) # 80002a64 <trapinithart>
    plicinit();      // set up interrupt controller
    80001008:	00005097          	auipc	ra,0x5
    8000100c:	082080e7          	jalr	130(ra) # 8000608a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001010:	00005097          	auipc	ra,0x5
    80001014:	090080e7          	jalr	144(ra) # 800060a0 <plicinithart>
    binit();         // buffer cache
    80001018:	00002097          	auipc	ra,0x2
    8000101c:	28a080e7          	jalr	650(ra) # 800032a2 <binit>
    iinit();         // inode table
    80001020:	00003097          	auipc	ra,0x3
    80001024:	928080e7          	jalr	-1752(ra) # 80003948 <iinit>
    fileinit();      // file table
    80001028:	00004097          	auipc	ra,0x4
    8000102c:	89e080e7          	jalr	-1890(ra) # 800048c6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001030:	00005097          	auipc	ra,0x5
    80001034:	178080e7          	jalr	376(ra) # 800061a8 <virtio_disk_init>
    userinit();      // first user process
    80001038:	00001097          	auipc	ra,0x1
    8000103c:	e02080e7          	jalr	-510(ra) # 80001e3a <userinit>
    __sync_synchronize();
    80001040:	0ff0000f          	fence
    started = 1;
    80001044:	4785                	li	a5,1
    80001046:	00008717          	auipc	a4,0x8
    8000104a:	a0f72123          	sw	a5,-1534(a4) # 80008a48 <started>
    8000104e:	b789                	j	80000f90 <main+0x56>

0000000080001050 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001050:	1141                	addi	sp,sp,-16
    80001052:	e422                	sd	s0,8(sp)
    80001054:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001056:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    8000105a:	00008797          	auipc	a5,0x8
    8000105e:	9f67b783          	ld	a5,-1546(a5) # 80008a50 <kernel_pagetable>
    80001062:	83b1                	srli	a5,a5,0xc
    80001064:	577d                	li	a4,-1
    80001066:	177e                	slli	a4,a4,0x3f
    80001068:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000106a:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000106e:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001072:	6422                	ld	s0,8(sp)
    80001074:	0141                	addi	sp,sp,16
    80001076:	8082                	ret

0000000080001078 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001078:	7139                	addi	sp,sp,-64
    8000107a:	fc06                	sd	ra,56(sp)
    8000107c:	f822                	sd	s0,48(sp)
    8000107e:	f426                	sd	s1,40(sp)
    80001080:	f04a                	sd	s2,32(sp)
    80001082:	ec4e                	sd	s3,24(sp)
    80001084:	e852                	sd	s4,16(sp)
    80001086:	e456                	sd	s5,8(sp)
    80001088:	e05a                	sd	s6,0(sp)
    8000108a:	0080                	addi	s0,sp,64
    8000108c:	84aa                	mv	s1,a0
    8000108e:	89ae                	mv	s3,a1
    80001090:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001092:	57fd                	li	a5,-1
    80001094:	83e9                	srli	a5,a5,0x1a
    80001096:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001098:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000109a:	04b7f263          	bgeu	a5,a1,800010de <walk+0x66>
    panic("walk");
    8000109e:	00007517          	auipc	a0,0x7
    800010a2:	07250513          	addi	a0,a0,114 # 80008110 <digits+0xc0>
    800010a6:	fffff097          	auipc	ra,0xfffff
    800010aa:	496080e7          	jalr	1174(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010ae:	060a8663          	beqz	s5,8000111a <walk+0xa2>
    800010b2:	00000097          	auipc	ra,0x0
    800010b6:	aac080e7          	jalr	-1364(ra) # 80000b5e <kalloc>
    800010ba:	84aa                	mv	s1,a0
    800010bc:	c529                	beqz	a0,80001106 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010be:	6605                	lui	a2,0x1
    800010c0:	4581                	li	a1,0
    800010c2:	00000097          	auipc	ra,0x0
    800010c6:	cd4080e7          	jalr	-812(ra) # 80000d96 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010ca:	00c4d793          	srli	a5,s1,0xc
    800010ce:	07aa                	slli	a5,a5,0xa
    800010d0:	0017e793          	ori	a5,a5,1
    800010d4:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010d8:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd117>
    800010da:	036a0063          	beq	s4,s6,800010fa <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010de:	0149d933          	srl	s2,s3,s4
    800010e2:	1ff97913          	andi	s2,s2,511
    800010e6:	090e                	slli	s2,s2,0x3
    800010e8:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010ea:	00093483          	ld	s1,0(s2)
    800010ee:	0014f793          	andi	a5,s1,1
    800010f2:	dfd5                	beqz	a5,800010ae <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010f4:	80a9                	srli	s1,s1,0xa
    800010f6:	04b2                	slli	s1,s1,0xc
    800010f8:	b7c5                	j	800010d8 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010fa:	00c9d513          	srli	a0,s3,0xc
    800010fe:	1ff57513          	andi	a0,a0,511
    80001102:	050e                	slli	a0,a0,0x3
    80001104:	9526                	add	a0,a0,s1
}
    80001106:	70e2                	ld	ra,56(sp)
    80001108:	7442                	ld	s0,48(sp)
    8000110a:	74a2                	ld	s1,40(sp)
    8000110c:	7902                	ld	s2,32(sp)
    8000110e:	69e2                	ld	s3,24(sp)
    80001110:	6a42                	ld	s4,16(sp)
    80001112:	6aa2                	ld	s5,8(sp)
    80001114:	6b02                	ld	s6,0(sp)
    80001116:	6121                	addi	sp,sp,64
    80001118:	8082                	ret
        return 0;
    8000111a:	4501                	li	a0,0
    8000111c:	b7ed                	j	80001106 <walk+0x8e>

000000008000111e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000111e:	57fd                	li	a5,-1
    80001120:	83e9                	srli	a5,a5,0x1a
    80001122:	00b7f463          	bgeu	a5,a1,8000112a <walkaddr+0xc>
    return 0;
    80001126:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001128:	8082                	ret
{
    8000112a:	1141                	addi	sp,sp,-16
    8000112c:	e406                	sd	ra,8(sp)
    8000112e:	e022                	sd	s0,0(sp)
    80001130:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001132:	4601                	li	a2,0
    80001134:	00000097          	auipc	ra,0x0
    80001138:	f44080e7          	jalr	-188(ra) # 80001078 <walk>
  if(pte == 0)
    8000113c:	c105                	beqz	a0,8000115c <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000113e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001140:	0117f693          	andi	a3,a5,17
    80001144:	4745                	li	a4,17
    return 0;
    80001146:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001148:	00e68663          	beq	a3,a4,80001154 <walkaddr+0x36>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
  pa = PTE2PA(*pte);
    80001154:	83a9                	srli	a5,a5,0xa
    80001156:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000115a:	bfcd                	j	8000114c <walkaddr+0x2e>
    return 0;
    8000115c:	4501                	li	a0,0
    8000115e:	b7fd                	j	8000114c <walkaddr+0x2e>

0000000080001160 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001160:	715d                	addi	sp,sp,-80
    80001162:	e486                	sd	ra,72(sp)
    80001164:	e0a2                	sd	s0,64(sp)
    80001166:	fc26                	sd	s1,56(sp)
    80001168:	f84a                	sd	s2,48(sp)
    8000116a:	f44e                	sd	s3,40(sp)
    8000116c:	f052                	sd	s4,32(sp)
    8000116e:	ec56                	sd	s5,24(sp)
    80001170:	e85a                	sd	s6,16(sp)
    80001172:	e45e                	sd	s7,8(sp)
    80001174:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001176:	c639                	beqz	a2,800011c4 <mappages+0x64>
    80001178:	8aaa                	mv	s5,a0
    8000117a:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000117c:	777d                	lui	a4,0xfffff
    8000117e:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001182:	fff58993          	addi	s3,a1,-1
    80001186:	99b2                	add	s3,s3,a2
    80001188:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000118c:	893e                	mv	s2,a5
    8000118e:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001192:	6b85                	lui	s7,0x1
    80001194:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001198:	4605                	li	a2,1
    8000119a:	85ca                	mv	a1,s2
    8000119c:	8556                	mv	a0,s5
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	eda080e7          	jalr	-294(ra) # 80001078 <walk>
    800011a6:	cd1d                	beqz	a0,800011e4 <mappages+0x84>
    if(*pte & PTE_V)
    800011a8:	611c                	ld	a5,0(a0)
    800011aa:	8b85                	andi	a5,a5,1
    800011ac:	e785                	bnez	a5,800011d4 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011ae:	80b1                	srli	s1,s1,0xc
    800011b0:	04aa                	slli	s1,s1,0xa
    800011b2:	0164e4b3          	or	s1,s1,s6
    800011b6:	0014e493          	ori	s1,s1,1
    800011ba:	e104                	sd	s1,0(a0)
    if(a == last)
    800011bc:	05390063          	beq	s2,s3,800011fc <mappages+0x9c>
    a += PGSIZE;
    800011c0:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011c2:	bfc9                	j	80001194 <mappages+0x34>
    panic("mappages: size");
    800011c4:	00007517          	auipc	a0,0x7
    800011c8:	f5450513          	addi	a0,a0,-172 # 80008118 <digits+0xc8>
    800011cc:	fffff097          	auipc	ra,0xfffff
    800011d0:	370080e7          	jalr	880(ra) # 8000053c <panic>
      panic("mappages: remap");
    800011d4:	00007517          	auipc	a0,0x7
    800011d8:	f5450513          	addi	a0,a0,-172 # 80008128 <digits+0xd8>
    800011dc:	fffff097          	auipc	ra,0xfffff
    800011e0:	360080e7          	jalr	864(ra) # 8000053c <panic>
      return -1;
    800011e4:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011e6:	60a6                	ld	ra,72(sp)
    800011e8:	6406                	ld	s0,64(sp)
    800011ea:	74e2                	ld	s1,56(sp)
    800011ec:	7942                	ld	s2,48(sp)
    800011ee:	79a2                	ld	s3,40(sp)
    800011f0:	7a02                	ld	s4,32(sp)
    800011f2:	6ae2                	ld	s5,24(sp)
    800011f4:	6b42                	ld	s6,16(sp)
    800011f6:	6ba2                	ld	s7,8(sp)
    800011f8:	6161                	addi	sp,sp,80
    800011fa:	8082                	ret
  return 0;
    800011fc:	4501                	li	a0,0
    800011fe:	b7e5                	j	800011e6 <mappages+0x86>

0000000080001200 <kvmmap>:
{
    80001200:	1141                	addi	sp,sp,-16
    80001202:	e406                	sd	ra,8(sp)
    80001204:	e022                	sd	s0,0(sp)
    80001206:	0800                	addi	s0,sp,16
    80001208:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000120a:	86b2                	mv	a3,a2
    8000120c:	863e                	mv	a2,a5
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f52080e7          	jalr	-174(ra) # 80001160 <mappages>
    80001216:	e509                	bnez	a0,80001220 <kvmmap+0x20>
}
    80001218:	60a2                	ld	ra,8(sp)
    8000121a:	6402                	ld	s0,0(sp)
    8000121c:	0141                	addi	sp,sp,16
    8000121e:	8082                	ret
    panic("kvmmap");
    80001220:	00007517          	auipc	a0,0x7
    80001224:	f1850513          	addi	a0,a0,-232 # 80008138 <digits+0xe8>
    80001228:	fffff097          	auipc	ra,0xfffff
    8000122c:	314080e7          	jalr	788(ra) # 8000053c <panic>

0000000080001230 <kvmmake>:
{
    80001230:	1101                	addi	sp,sp,-32
    80001232:	ec06                	sd	ra,24(sp)
    80001234:	e822                	sd	s0,16(sp)
    80001236:	e426                	sd	s1,8(sp)
    80001238:	e04a                	sd	s2,0(sp)
    8000123a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000123c:	00000097          	auipc	ra,0x0
    80001240:	922080e7          	jalr	-1758(ra) # 80000b5e <kalloc>
    80001244:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001246:	6605                	lui	a2,0x1
    80001248:	4581                	li	a1,0
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	b4c080e7          	jalr	-1204(ra) # 80000d96 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001252:	4719                	li	a4,6
    80001254:	6685                	lui	a3,0x1
    80001256:	10000637          	lui	a2,0x10000
    8000125a:	100005b7          	lui	a1,0x10000
    8000125e:	8526                	mv	a0,s1
    80001260:	00000097          	auipc	ra,0x0
    80001264:	fa0080e7          	jalr	-96(ra) # 80001200 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001268:	4719                	li	a4,6
    8000126a:	6685                	lui	a3,0x1
    8000126c:	10001637          	lui	a2,0x10001
    80001270:	100015b7          	lui	a1,0x10001
    80001274:	8526                	mv	a0,s1
    80001276:	00000097          	auipc	ra,0x0
    8000127a:	f8a080e7          	jalr	-118(ra) # 80001200 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000127e:	4719                	li	a4,6
    80001280:	004006b7          	lui	a3,0x400
    80001284:	0c000637          	lui	a2,0xc000
    80001288:	0c0005b7          	lui	a1,0xc000
    8000128c:	8526                	mv	a0,s1
    8000128e:	00000097          	auipc	ra,0x0
    80001292:	f72080e7          	jalr	-142(ra) # 80001200 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001296:	00007917          	auipc	s2,0x7
    8000129a:	d6a90913          	addi	s2,s2,-662 # 80008000 <etext>
    8000129e:	4729                	li	a4,10
    800012a0:	80007697          	auipc	a3,0x80007
    800012a4:	d6068693          	addi	a3,a3,-672 # 8000 <_entry-0x7fff8000>
    800012a8:	4605                	li	a2,1
    800012aa:	067e                	slli	a2,a2,0x1f
    800012ac:	85b2                	mv	a1,a2
    800012ae:	8526                	mv	a0,s1
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	f50080e7          	jalr	-176(ra) # 80001200 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012b8:	4719                	li	a4,6
    800012ba:	46c5                	li	a3,17
    800012bc:	06ee                	slli	a3,a3,0x1b
    800012be:	412686b3          	sub	a3,a3,s2
    800012c2:	864a                	mv	a2,s2
    800012c4:	85ca                	mv	a1,s2
    800012c6:	8526                	mv	a0,s1
    800012c8:	00000097          	auipc	ra,0x0
    800012cc:	f38080e7          	jalr	-200(ra) # 80001200 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012d0:	4729                	li	a4,10
    800012d2:	6685                	lui	a3,0x1
    800012d4:	00006617          	auipc	a2,0x6
    800012d8:	d2c60613          	addi	a2,a2,-724 # 80007000 <_trampoline>
    800012dc:	040005b7          	lui	a1,0x4000
    800012e0:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800012e2:	05b2                	slli	a1,a1,0xc
    800012e4:	8526                	mv	a0,s1
    800012e6:	00000097          	auipc	ra,0x0
    800012ea:	f1a080e7          	jalr	-230(ra) # 80001200 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012ee:	8526                	mv	a0,s1
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	6d8080e7          	jalr	1752(ra) # 800019c8 <proc_mapstacks>
}
    800012f8:	8526                	mv	a0,s1
    800012fa:	60e2                	ld	ra,24(sp)
    800012fc:	6442                	ld	s0,16(sp)
    800012fe:	64a2                	ld	s1,8(sp)
    80001300:	6902                	ld	s2,0(sp)
    80001302:	6105                	addi	sp,sp,32
    80001304:	8082                	ret

0000000080001306 <kvminit>:
{
    80001306:	1141                	addi	sp,sp,-16
    80001308:	e406                	sd	ra,8(sp)
    8000130a:	e022                	sd	s0,0(sp)
    8000130c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	f22080e7          	jalr	-222(ra) # 80001230 <kvmmake>
    80001316:	00007797          	auipc	a5,0x7
    8000131a:	72a7bd23          	sd	a0,1850(a5) # 80008a50 <kernel_pagetable>
}
    8000131e:	60a2                	ld	ra,8(sp)
    80001320:	6402                	ld	s0,0(sp)
    80001322:	0141                	addi	sp,sp,16
    80001324:	8082                	ret

0000000080001326 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001326:	715d                	addi	sp,sp,-80
    80001328:	e486                	sd	ra,72(sp)
    8000132a:	e0a2                	sd	s0,64(sp)
    8000132c:	fc26                	sd	s1,56(sp)
    8000132e:	f84a                	sd	s2,48(sp)
    80001330:	f44e                	sd	s3,40(sp)
    80001332:	f052                	sd	s4,32(sp)
    80001334:	ec56                	sd	s5,24(sp)
    80001336:	e85a                	sd	s6,16(sp)
    80001338:	e45e                	sd	s7,8(sp)
    8000133a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000133c:	03459793          	slli	a5,a1,0x34
    80001340:	e795                	bnez	a5,8000136c <uvmunmap+0x46>
    80001342:	8a2a                	mv	s4,a0
    80001344:	892e                	mv	s2,a1
    80001346:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001348:	0632                	slli	a2,a2,0xc
    8000134a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000134e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001350:	6b05                	lui	s6,0x1
    80001352:	0735e263          	bltu	a1,s3,800013b6 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001356:	60a6                	ld	ra,72(sp)
    80001358:	6406                	ld	s0,64(sp)
    8000135a:	74e2                	ld	s1,56(sp)
    8000135c:	7942                	ld	s2,48(sp)
    8000135e:	79a2                	ld	s3,40(sp)
    80001360:	7a02                	ld	s4,32(sp)
    80001362:	6ae2                	ld	s5,24(sp)
    80001364:	6b42                	ld	s6,16(sp)
    80001366:	6ba2                	ld	s7,8(sp)
    80001368:	6161                	addi	sp,sp,80
    8000136a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000136c:	00007517          	auipc	a0,0x7
    80001370:	dd450513          	addi	a0,a0,-556 # 80008140 <digits+0xf0>
    80001374:	fffff097          	auipc	ra,0xfffff
    80001378:	1c8080e7          	jalr	456(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    8000137c:	00007517          	auipc	a0,0x7
    80001380:	ddc50513          	addi	a0,a0,-548 # 80008158 <digits+0x108>
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	1b8080e7          	jalr	440(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    8000138c:	00007517          	auipc	a0,0x7
    80001390:	ddc50513          	addi	a0,a0,-548 # 80008168 <digits+0x118>
    80001394:	fffff097          	auipc	ra,0xfffff
    80001398:	1a8080e7          	jalr	424(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    8000139c:	00007517          	auipc	a0,0x7
    800013a0:	de450513          	addi	a0,a0,-540 # 80008180 <digits+0x130>
    800013a4:	fffff097          	auipc	ra,0xfffff
    800013a8:	198080e7          	jalr	408(ra) # 8000053c <panic>
    *pte = 0;
    800013ac:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013b0:	995a                	add	s2,s2,s6
    800013b2:	fb3972e3          	bgeu	s2,s3,80001356 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013b6:	4601                	li	a2,0
    800013b8:	85ca                	mv	a1,s2
    800013ba:	8552                	mv	a0,s4
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	cbc080e7          	jalr	-836(ra) # 80001078 <walk>
    800013c4:	84aa                	mv	s1,a0
    800013c6:	d95d                	beqz	a0,8000137c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013c8:	6108                	ld	a0,0(a0)
    800013ca:	00157793          	andi	a5,a0,1
    800013ce:	dfdd                	beqz	a5,8000138c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013d0:	3ff57793          	andi	a5,a0,1023
    800013d4:	fd7784e3          	beq	a5,s7,8000139c <uvmunmap+0x76>
    if(do_free){
    800013d8:	fc0a8ae3          	beqz	s5,800013ac <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013dc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013de:	0532                	slli	a0,a0,0xc
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	616080e7          	jalr	1558(ra) # 800009f6 <kfree>
    800013e8:	b7d1                	j	800013ac <uvmunmap+0x86>

00000000800013ea <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013ea:	1101                	addi	sp,sp,-32
    800013ec:	ec06                	sd	ra,24(sp)
    800013ee:	e822                	sd	s0,16(sp)
    800013f0:	e426                	sd	s1,8(sp)
    800013f2:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013f4:	fffff097          	auipc	ra,0xfffff
    800013f8:	76a080e7          	jalr	1898(ra) # 80000b5e <kalloc>
    800013fc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013fe:	c519                	beqz	a0,8000140c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001400:	6605                	lui	a2,0x1
    80001402:	4581                	li	a1,0
    80001404:	00000097          	auipc	ra,0x0
    80001408:	992080e7          	jalr	-1646(ra) # 80000d96 <memset>
  return pagetable;
}
    8000140c:	8526                	mv	a0,s1
    8000140e:	60e2                	ld	ra,24(sp)
    80001410:	6442                	ld	s0,16(sp)
    80001412:	64a2                	ld	s1,8(sp)
    80001414:	6105                	addi	sp,sp,32
    80001416:	8082                	ret

0000000080001418 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001418:	7179                	addi	sp,sp,-48
    8000141a:	f406                	sd	ra,40(sp)
    8000141c:	f022                	sd	s0,32(sp)
    8000141e:	ec26                	sd	s1,24(sp)
    80001420:	e84a                	sd	s2,16(sp)
    80001422:	e44e                	sd	s3,8(sp)
    80001424:	e052                	sd	s4,0(sp)
    80001426:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001428:	6785                	lui	a5,0x1
    8000142a:	04f67863          	bgeu	a2,a5,8000147a <uvmfirst+0x62>
    8000142e:	8a2a                	mv	s4,a0
    80001430:	89ae                	mv	s3,a1
    80001432:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001434:	fffff097          	auipc	ra,0xfffff
    80001438:	72a080e7          	jalr	1834(ra) # 80000b5e <kalloc>
    8000143c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	954080e7          	jalr	-1708(ra) # 80000d96 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000144a:	4779                	li	a4,30
    8000144c:	86ca                	mv	a3,s2
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	8552                	mv	a0,s4
    80001454:	00000097          	auipc	ra,0x0
    80001458:	d0c080e7          	jalr	-756(ra) # 80001160 <mappages>
  memmove(mem, src, sz);
    8000145c:	8626                	mv	a2,s1
    8000145e:	85ce                	mv	a1,s3
    80001460:	854a                	mv	a0,s2
    80001462:	00000097          	auipc	ra,0x0
    80001466:	990080e7          	jalr	-1648(ra) # 80000df2 <memmove>
}
    8000146a:	70a2                	ld	ra,40(sp)
    8000146c:	7402                	ld	s0,32(sp)
    8000146e:	64e2                	ld	s1,24(sp)
    80001470:	6942                	ld	s2,16(sp)
    80001472:	69a2                	ld	s3,8(sp)
    80001474:	6a02                	ld	s4,0(sp)
    80001476:	6145                	addi	sp,sp,48
    80001478:	8082                	ret
    panic("uvmfirst: more than a page");
    8000147a:	00007517          	auipc	a0,0x7
    8000147e:	d1e50513          	addi	a0,a0,-738 # 80008198 <digits+0x148>
    80001482:	fffff097          	auipc	ra,0xfffff
    80001486:	0ba080e7          	jalr	186(ra) # 8000053c <panic>

000000008000148a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000148a:	1101                	addi	sp,sp,-32
    8000148c:	ec06                	sd	ra,24(sp)
    8000148e:	e822                	sd	s0,16(sp)
    80001490:	e426                	sd	s1,8(sp)
    80001492:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001494:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001496:	00b67d63          	bgeu	a2,a1,800014b0 <uvmdealloc+0x26>
    8000149a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000149c:	6785                	lui	a5,0x1
    8000149e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014a0:	00f60733          	add	a4,a2,a5
    800014a4:	76fd                	lui	a3,0xfffff
    800014a6:	8f75                	and	a4,a4,a3
    800014a8:	97ae                	add	a5,a5,a1
    800014aa:	8ff5                	and	a5,a5,a3
    800014ac:	00f76863          	bltu	a4,a5,800014bc <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014b0:	8526                	mv	a0,s1
    800014b2:	60e2                	ld	ra,24(sp)
    800014b4:	6442                	ld	s0,16(sp)
    800014b6:	64a2                	ld	s1,8(sp)
    800014b8:	6105                	addi	sp,sp,32
    800014ba:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014bc:	8f99                	sub	a5,a5,a4
    800014be:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014c0:	4685                	li	a3,1
    800014c2:	0007861b          	sext.w	a2,a5
    800014c6:	85ba                	mv	a1,a4
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	e5e080e7          	jalr	-418(ra) # 80001326 <uvmunmap>
    800014d0:	b7c5                	j	800014b0 <uvmdealloc+0x26>

00000000800014d2 <uvmalloc>:
  if(newsz < oldsz)
    800014d2:	0ab66563          	bltu	a2,a1,8000157c <uvmalloc+0xaa>
{
    800014d6:	7139                	addi	sp,sp,-64
    800014d8:	fc06                	sd	ra,56(sp)
    800014da:	f822                	sd	s0,48(sp)
    800014dc:	f426                	sd	s1,40(sp)
    800014de:	f04a                	sd	s2,32(sp)
    800014e0:	ec4e                	sd	s3,24(sp)
    800014e2:	e852                	sd	s4,16(sp)
    800014e4:	e456                	sd	s5,8(sp)
    800014e6:	e05a                	sd	s6,0(sp)
    800014e8:	0080                	addi	s0,sp,64
    800014ea:	8aaa                	mv	s5,a0
    800014ec:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014ee:	6785                	lui	a5,0x1
    800014f0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014f2:	95be                	add	a1,a1,a5
    800014f4:	77fd                	lui	a5,0xfffff
    800014f6:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014fa:	08c9f363          	bgeu	s3,a2,80001580 <uvmalloc+0xae>
    800014fe:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001500:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	65a080e7          	jalr	1626(ra) # 80000b5e <kalloc>
    8000150c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000150e:	c51d                	beqz	a0,8000153c <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001510:	6605                	lui	a2,0x1
    80001512:	4581                	li	a1,0
    80001514:	00000097          	auipc	ra,0x0
    80001518:	882080e7          	jalr	-1918(ra) # 80000d96 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000151c:	875a                	mv	a4,s6
    8000151e:	86a6                	mv	a3,s1
    80001520:	6605                	lui	a2,0x1
    80001522:	85ca                	mv	a1,s2
    80001524:	8556                	mv	a0,s5
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	c3a080e7          	jalr	-966(ra) # 80001160 <mappages>
    8000152e:	e90d                	bnez	a0,80001560 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001530:	6785                	lui	a5,0x1
    80001532:	993e                	add	s2,s2,a5
    80001534:	fd4968e3          	bltu	s2,s4,80001504 <uvmalloc+0x32>
  return newsz;
    80001538:	8552                	mv	a0,s4
    8000153a:	a809                	j	8000154c <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000153c:	864e                	mv	a2,s3
    8000153e:	85ca                	mv	a1,s2
    80001540:	8556                	mv	a0,s5
    80001542:	00000097          	auipc	ra,0x0
    80001546:	f48080e7          	jalr	-184(ra) # 8000148a <uvmdealloc>
      return 0;
    8000154a:	4501                	li	a0,0
}
    8000154c:	70e2                	ld	ra,56(sp)
    8000154e:	7442                	ld	s0,48(sp)
    80001550:	74a2                	ld	s1,40(sp)
    80001552:	7902                	ld	s2,32(sp)
    80001554:	69e2                	ld	s3,24(sp)
    80001556:	6a42                	ld	s4,16(sp)
    80001558:	6aa2                	ld	s5,8(sp)
    8000155a:	6b02                	ld	s6,0(sp)
    8000155c:	6121                	addi	sp,sp,64
    8000155e:	8082                	ret
      kfree(mem);
    80001560:	8526                	mv	a0,s1
    80001562:	fffff097          	auipc	ra,0xfffff
    80001566:	494080e7          	jalr	1172(ra) # 800009f6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000156a:	864e                	mv	a2,s3
    8000156c:	85ca                	mv	a1,s2
    8000156e:	8556                	mv	a0,s5
    80001570:	00000097          	auipc	ra,0x0
    80001574:	f1a080e7          	jalr	-230(ra) # 8000148a <uvmdealloc>
      return 0;
    80001578:	4501                	li	a0,0
    8000157a:	bfc9                	j	8000154c <uvmalloc+0x7a>
    return oldsz;
    8000157c:	852e                	mv	a0,a1
}
    8000157e:	8082                	ret
  return newsz;
    80001580:	8532                	mv	a0,a2
    80001582:	b7e9                	j	8000154c <uvmalloc+0x7a>

0000000080001584 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001584:	7179                	addi	sp,sp,-48
    80001586:	f406                	sd	ra,40(sp)
    80001588:	f022                	sd	s0,32(sp)
    8000158a:	ec26                	sd	s1,24(sp)
    8000158c:	e84a                	sd	s2,16(sp)
    8000158e:	e44e                	sd	s3,8(sp)
    80001590:	e052                	sd	s4,0(sp)
    80001592:	1800                	addi	s0,sp,48
    80001594:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001596:	84aa                	mv	s1,a0
    80001598:	6905                	lui	s2,0x1
    8000159a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000159c:	4985                	li	s3,1
    8000159e:	a829                	j	800015b8 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015a0:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800015a2:	00c79513          	slli	a0,a5,0xc
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	fde080e7          	jalr	-34(ra) # 80001584 <freewalk>
      pagetable[i] = 0;
    800015ae:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015b2:	04a1                	addi	s1,s1,8
    800015b4:	03248163          	beq	s1,s2,800015d6 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800015b8:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ba:	00f7f713          	andi	a4,a5,15
    800015be:	ff3701e3          	beq	a4,s3,800015a0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015c2:	8b85                	andi	a5,a5,1
    800015c4:	d7fd                	beqz	a5,800015b2 <freewalk+0x2e>
      panic("freewalk: leaf");
    800015c6:	00007517          	auipc	a0,0x7
    800015ca:	bf250513          	addi	a0,a0,-1038 # 800081b8 <digits+0x168>
    800015ce:	fffff097          	auipc	ra,0xfffff
    800015d2:	f6e080e7          	jalr	-146(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    800015d6:	8552                	mv	a0,s4
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	41e080e7          	jalr	1054(ra) # 800009f6 <kfree>
}
    800015e0:	70a2                	ld	ra,40(sp)
    800015e2:	7402                	ld	s0,32(sp)
    800015e4:	64e2                	ld	s1,24(sp)
    800015e6:	6942                	ld	s2,16(sp)
    800015e8:	69a2                	ld	s3,8(sp)
    800015ea:	6a02                	ld	s4,0(sp)
    800015ec:	6145                	addi	sp,sp,48
    800015ee:	8082                	ret

00000000800015f0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015f0:	1101                	addi	sp,sp,-32
    800015f2:	ec06                	sd	ra,24(sp)
    800015f4:	e822                	sd	s0,16(sp)
    800015f6:	e426                	sd	s1,8(sp)
    800015f8:	1000                	addi	s0,sp,32
    800015fa:	84aa                	mv	s1,a0
  if(sz > 0)
    800015fc:	e999                	bnez	a1,80001612 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015fe:	8526                	mv	a0,s1
    80001600:	00000097          	auipc	ra,0x0
    80001604:	f84080e7          	jalr	-124(ra) # 80001584 <freewalk>
}
    80001608:	60e2                	ld	ra,24(sp)
    8000160a:	6442                	ld	s0,16(sp)
    8000160c:	64a2                	ld	s1,8(sp)
    8000160e:	6105                	addi	sp,sp,32
    80001610:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001612:	6785                	lui	a5,0x1
    80001614:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001616:	95be                	add	a1,a1,a5
    80001618:	4685                	li	a3,1
    8000161a:	00c5d613          	srli	a2,a1,0xc
    8000161e:	4581                	li	a1,0
    80001620:	00000097          	auipc	ra,0x0
    80001624:	d06080e7          	jalr	-762(ra) # 80001326 <uvmunmap>
    80001628:	bfd9                	j	800015fe <uvmfree+0xe>

000000008000162a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000162a:	c679                	beqz	a2,800016f8 <uvmcopy+0xce>
{
    8000162c:	715d                	addi	sp,sp,-80
    8000162e:	e486                	sd	ra,72(sp)
    80001630:	e0a2                	sd	s0,64(sp)
    80001632:	fc26                	sd	s1,56(sp)
    80001634:	f84a                	sd	s2,48(sp)
    80001636:	f44e                	sd	s3,40(sp)
    80001638:	f052                	sd	s4,32(sp)
    8000163a:	ec56                	sd	s5,24(sp)
    8000163c:	e85a                	sd	s6,16(sp)
    8000163e:	e45e                	sd	s7,8(sp)
    80001640:	0880                	addi	s0,sp,80
    80001642:	8b2a                	mv	s6,a0
    80001644:	8aae                	mv	s5,a1
    80001646:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001648:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000164a:	4601                	li	a2,0
    8000164c:	85ce                	mv	a1,s3
    8000164e:	855a                	mv	a0,s6
    80001650:	00000097          	auipc	ra,0x0
    80001654:	a28080e7          	jalr	-1496(ra) # 80001078 <walk>
    80001658:	c531                	beqz	a0,800016a4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000165a:	6118                	ld	a4,0(a0)
    8000165c:	00177793          	andi	a5,a4,1
    80001660:	cbb1                	beqz	a5,800016b4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001662:	00a75593          	srli	a1,a4,0xa
    80001666:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000166a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000166e:	fffff097          	auipc	ra,0xfffff
    80001672:	4f0080e7          	jalr	1264(ra) # 80000b5e <kalloc>
    80001676:	892a                	mv	s2,a0
    80001678:	c939                	beqz	a0,800016ce <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000167a:	6605                	lui	a2,0x1
    8000167c:	85de                	mv	a1,s7
    8000167e:	fffff097          	auipc	ra,0xfffff
    80001682:	774080e7          	jalr	1908(ra) # 80000df2 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001686:	8726                	mv	a4,s1
    80001688:	86ca                	mv	a3,s2
    8000168a:	6605                	lui	a2,0x1
    8000168c:	85ce                	mv	a1,s3
    8000168e:	8556                	mv	a0,s5
    80001690:	00000097          	auipc	ra,0x0
    80001694:	ad0080e7          	jalr	-1328(ra) # 80001160 <mappages>
    80001698:	e515                	bnez	a0,800016c4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000169a:	6785                	lui	a5,0x1
    8000169c:	99be                	add	s3,s3,a5
    8000169e:	fb49e6e3          	bltu	s3,s4,8000164a <uvmcopy+0x20>
    800016a2:	a081                	j	800016e2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016a4:	00007517          	auipc	a0,0x7
    800016a8:	b2450513          	addi	a0,a0,-1244 # 800081c8 <digits+0x178>
    800016ac:	fffff097          	auipc	ra,0xfffff
    800016b0:	e90080e7          	jalr	-368(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800016b4:	00007517          	auipc	a0,0x7
    800016b8:	b3450513          	addi	a0,a0,-1228 # 800081e8 <digits+0x198>
    800016bc:	fffff097          	auipc	ra,0xfffff
    800016c0:	e80080e7          	jalr	-384(ra) # 8000053c <panic>
      kfree(mem);
    800016c4:	854a                	mv	a0,s2
    800016c6:	fffff097          	auipc	ra,0xfffff
    800016ca:	330080e7          	jalr	816(ra) # 800009f6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016ce:	4685                	li	a3,1
    800016d0:	00c9d613          	srli	a2,s3,0xc
    800016d4:	4581                	li	a1,0
    800016d6:	8556                	mv	a0,s5
    800016d8:	00000097          	auipc	ra,0x0
    800016dc:	c4e080e7          	jalr	-946(ra) # 80001326 <uvmunmap>
  return -1;
    800016e0:	557d                	li	a0,-1
}
    800016e2:	60a6                	ld	ra,72(sp)
    800016e4:	6406                	ld	s0,64(sp)
    800016e6:	74e2                	ld	s1,56(sp)
    800016e8:	7942                	ld	s2,48(sp)
    800016ea:	79a2                	ld	s3,40(sp)
    800016ec:	7a02                	ld	s4,32(sp)
    800016ee:	6ae2                	ld	s5,24(sp)
    800016f0:	6b42                	ld	s6,16(sp)
    800016f2:	6ba2                	ld	s7,8(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret
  return 0;
    800016f8:	4501                	li	a0,0
}
    800016fa:	8082                	ret

00000000800016fc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016fc:	1141                	addi	sp,sp,-16
    800016fe:	e406                	sd	ra,8(sp)
    80001700:	e022                	sd	s0,0(sp)
    80001702:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001704:	4601                	li	a2,0
    80001706:	00000097          	auipc	ra,0x0
    8000170a:	972080e7          	jalr	-1678(ra) # 80001078 <walk>
  if(pte == 0)
    8000170e:	c901                	beqz	a0,8000171e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001710:	611c                	ld	a5,0(a0)
    80001712:	9bbd                	andi	a5,a5,-17
    80001714:	e11c                	sd	a5,0(a0)
}
    80001716:	60a2                	ld	ra,8(sp)
    80001718:	6402                	ld	s0,0(sp)
    8000171a:	0141                	addi	sp,sp,16
    8000171c:	8082                	ret
    panic("uvmclear");
    8000171e:	00007517          	auipc	a0,0x7
    80001722:	aea50513          	addi	a0,a0,-1302 # 80008208 <digits+0x1b8>
    80001726:	fffff097          	auipc	ra,0xfffff
    8000172a:	e16080e7          	jalr	-490(ra) # 8000053c <panic>

000000008000172e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000172e:	c6bd                	beqz	a3,8000179c <copyout+0x6e>
{
    80001730:	715d                	addi	sp,sp,-80
    80001732:	e486                	sd	ra,72(sp)
    80001734:	e0a2                	sd	s0,64(sp)
    80001736:	fc26                	sd	s1,56(sp)
    80001738:	f84a                	sd	s2,48(sp)
    8000173a:	f44e                	sd	s3,40(sp)
    8000173c:	f052                	sd	s4,32(sp)
    8000173e:	ec56                	sd	s5,24(sp)
    80001740:	e85a                	sd	s6,16(sp)
    80001742:	e45e                	sd	s7,8(sp)
    80001744:	e062                	sd	s8,0(sp)
    80001746:	0880                	addi	s0,sp,80
    80001748:	8b2a                	mv	s6,a0
    8000174a:	8c2e                	mv	s8,a1
    8000174c:	8a32                	mv	s4,a2
    8000174e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001750:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001752:	6a85                	lui	s5,0x1
    80001754:	a015                	j	80001778 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001756:	9562                	add	a0,a0,s8
    80001758:	0004861b          	sext.w	a2,s1
    8000175c:	85d2                	mv	a1,s4
    8000175e:	41250533          	sub	a0,a0,s2
    80001762:	fffff097          	auipc	ra,0xfffff
    80001766:	690080e7          	jalr	1680(ra) # 80000df2 <memmove>

    len -= n;
    8000176a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000176e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001770:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001774:	02098263          	beqz	s3,80001798 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001778:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000177c:	85ca                	mv	a1,s2
    8000177e:	855a                	mv	a0,s6
    80001780:	00000097          	auipc	ra,0x0
    80001784:	99e080e7          	jalr	-1634(ra) # 8000111e <walkaddr>
    if(pa0 == 0)
    80001788:	cd01                	beqz	a0,800017a0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000178a:	418904b3          	sub	s1,s2,s8
    8000178e:	94d6                	add	s1,s1,s5
    80001790:	fc99f3e3          	bgeu	s3,s1,80001756 <copyout+0x28>
    80001794:	84ce                	mv	s1,s3
    80001796:	b7c1                	j	80001756 <copyout+0x28>
  }
  return 0;
    80001798:	4501                	li	a0,0
    8000179a:	a021                	j	800017a2 <copyout+0x74>
    8000179c:	4501                	li	a0,0
}
    8000179e:	8082                	ret
      return -1;
    800017a0:	557d                	li	a0,-1
}
    800017a2:	60a6                	ld	ra,72(sp)
    800017a4:	6406                	ld	s0,64(sp)
    800017a6:	74e2                	ld	s1,56(sp)
    800017a8:	7942                	ld	s2,48(sp)
    800017aa:	79a2                	ld	s3,40(sp)
    800017ac:	7a02                	ld	s4,32(sp)
    800017ae:	6ae2                	ld	s5,24(sp)
    800017b0:	6b42                	ld	s6,16(sp)
    800017b2:	6ba2                	ld	s7,8(sp)
    800017b4:	6c02                	ld	s8,0(sp)
    800017b6:	6161                	addi	sp,sp,80
    800017b8:	8082                	ret

00000000800017ba <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ba:	caa5                	beqz	a3,8000182a <copyin+0x70>
{
    800017bc:	715d                	addi	sp,sp,-80
    800017be:	e486                	sd	ra,72(sp)
    800017c0:	e0a2                	sd	s0,64(sp)
    800017c2:	fc26                	sd	s1,56(sp)
    800017c4:	f84a                	sd	s2,48(sp)
    800017c6:	f44e                	sd	s3,40(sp)
    800017c8:	f052                	sd	s4,32(sp)
    800017ca:	ec56                	sd	s5,24(sp)
    800017cc:	e85a                	sd	s6,16(sp)
    800017ce:	e45e                	sd	s7,8(sp)
    800017d0:	e062                	sd	s8,0(sp)
    800017d2:	0880                	addi	s0,sp,80
    800017d4:	8b2a                	mv	s6,a0
    800017d6:	8a2e                	mv	s4,a1
    800017d8:	8c32                	mv	s8,a2
    800017da:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017dc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017de:	6a85                	lui	s5,0x1
    800017e0:	a01d                	j	80001806 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017e2:	018505b3          	add	a1,a0,s8
    800017e6:	0004861b          	sext.w	a2,s1
    800017ea:	412585b3          	sub	a1,a1,s2
    800017ee:	8552                	mv	a0,s4
    800017f0:	fffff097          	auipc	ra,0xfffff
    800017f4:	602080e7          	jalr	1538(ra) # 80000df2 <memmove>

    len -= n;
    800017f8:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017fc:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017fe:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001802:	02098263          	beqz	s3,80001826 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001806:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000180a:	85ca                	mv	a1,s2
    8000180c:	855a                	mv	a0,s6
    8000180e:	00000097          	auipc	ra,0x0
    80001812:	910080e7          	jalr	-1776(ra) # 8000111e <walkaddr>
    if(pa0 == 0)
    80001816:	cd01                	beqz	a0,8000182e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001818:	418904b3          	sub	s1,s2,s8
    8000181c:	94d6                	add	s1,s1,s5
    8000181e:	fc99f2e3          	bgeu	s3,s1,800017e2 <copyin+0x28>
    80001822:	84ce                	mv	s1,s3
    80001824:	bf7d                	j	800017e2 <copyin+0x28>
  }
  return 0;
    80001826:	4501                	li	a0,0
    80001828:	a021                	j	80001830 <copyin+0x76>
    8000182a:	4501                	li	a0,0
}
    8000182c:	8082                	ret
      return -1;
    8000182e:	557d                	li	a0,-1
}
    80001830:	60a6                	ld	ra,72(sp)
    80001832:	6406                	ld	s0,64(sp)
    80001834:	74e2                	ld	s1,56(sp)
    80001836:	7942                	ld	s2,48(sp)
    80001838:	79a2                	ld	s3,40(sp)
    8000183a:	7a02                	ld	s4,32(sp)
    8000183c:	6ae2                	ld	s5,24(sp)
    8000183e:	6b42                	ld	s6,16(sp)
    80001840:	6ba2                	ld	s7,8(sp)
    80001842:	6c02                	ld	s8,0(sp)
    80001844:	6161                	addi	sp,sp,80
    80001846:	8082                	ret

0000000080001848 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001848:	c2dd                	beqz	a3,800018ee <copyinstr+0xa6>
{
    8000184a:	715d                	addi	sp,sp,-80
    8000184c:	e486                	sd	ra,72(sp)
    8000184e:	e0a2                	sd	s0,64(sp)
    80001850:	fc26                	sd	s1,56(sp)
    80001852:	f84a                	sd	s2,48(sp)
    80001854:	f44e                	sd	s3,40(sp)
    80001856:	f052                	sd	s4,32(sp)
    80001858:	ec56                	sd	s5,24(sp)
    8000185a:	e85a                	sd	s6,16(sp)
    8000185c:	e45e                	sd	s7,8(sp)
    8000185e:	0880                	addi	s0,sp,80
    80001860:	8a2a                	mv	s4,a0
    80001862:	8b2e                	mv	s6,a1
    80001864:	8bb2                	mv	s7,a2
    80001866:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001868:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000186a:	6985                	lui	s3,0x1
    8000186c:	a02d                	j	80001896 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000186e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001872:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001874:	37fd                	addiw	a5,a5,-1
    80001876:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000187a:	60a6                	ld	ra,72(sp)
    8000187c:	6406                	ld	s0,64(sp)
    8000187e:	74e2                	ld	s1,56(sp)
    80001880:	7942                	ld	s2,48(sp)
    80001882:	79a2                	ld	s3,40(sp)
    80001884:	7a02                	ld	s4,32(sp)
    80001886:	6ae2                	ld	s5,24(sp)
    80001888:	6b42                	ld	s6,16(sp)
    8000188a:	6ba2                	ld	s7,8(sp)
    8000188c:	6161                	addi	sp,sp,80
    8000188e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001890:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001894:	c8a9                	beqz	s1,800018e6 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001896:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000189a:	85ca                	mv	a1,s2
    8000189c:	8552                	mv	a0,s4
    8000189e:	00000097          	auipc	ra,0x0
    800018a2:	880080e7          	jalr	-1920(ra) # 8000111e <walkaddr>
    if(pa0 == 0)
    800018a6:	c131                	beqz	a0,800018ea <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800018a8:	417906b3          	sub	a3,s2,s7
    800018ac:	96ce                	add	a3,a3,s3
    800018ae:	00d4f363          	bgeu	s1,a3,800018b4 <copyinstr+0x6c>
    800018b2:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018b4:	955e                	add	a0,a0,s7
    800018b6:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018ba:	daf9                	beqz	a3,80001890 <copyinstr+0x48>
    800018bc:	87da                	mv	a5,s6
    800018be:	885a                	mv	a6,s6
      if(*p == '\0'){
    800018c0:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800018c4:	96da                	add	a3,a3,s6
    800018c6:	85be                	mv	a1,a5
      if(*p == '\0'){
    800018c8:	00f60733          	add	a4,a2,a5
    800018cc:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd120>
    800018d0:	df59                	beqz	a4,8000186e <copyinstr+0x26>
        *dst = *p;
    800018d2:	00e78023          	sb	a4,0(a5)
      dst++;
    800018d6:	0785                	addi	a5,a5,1
    while(n > 0){
    800018d8:	fed797e3          	bne	a5,a3,800018c6 <copyinstr+0x7e>
    800018dc:	14fd                	addi	s1,s1,-1
    800018de:	94c2                	add	s1,s1,a6
      --max;
    800018e0:	8c8d                	sub	s1,s1,a1
      dst++;
    800018e2:	8b3e                	mv	s6,a5
    800018e4:	b775                	j	80001890 <copyinstr+0x48>
    800018e6:	4781                	li	a5,0
    800018e8:	b771                	j	80001874 <copyinstr+0x2c>
      return -1;
    800018ea:	557d                	li	a0,-1
    800018ec:	b779                	j	8000187a <copyinstr+0x32>
  int got_null = 0;
    800018ee:	4781                	li	a5,0
  if(got_null){
    800018f0:	37fd                	addiw	a5,a5,-1
    800018f2:	0007851b          	sext.w	a0,a5
}
    800018f6:	8082                	ret

00000000800018f8 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    800018f8:	715d                	addi	sp,sp,-80
    800018fa:	e486                	sd	ra,72(sp)
    800018fc:	e0a2                	sd	s0,64(sp)
    800018fe:	fc26                	sd	s1,56(sp)
    80001900:	f84a                	sd	s2,48(sp)
    80001902:	f44e                	sd	s3,40(sp)
    80001904:	f052                	sd	s4,32(sp)
    80001906:	ec56                	sd	s5,24(sp)
    80001908:	e85a                	sd	s6,16(sp)
    8000190a:	e45e                	sd	s7,8(sp)
    8000190c:	e062                	sd	s8,0(sp)
    8000190e:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80001910:	8792                	mv	a5,tp
    int id = r_tp();
    80001912:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001914:	0000fa97          	auipc	s5,0xf
    80001918:	3bca8a93          	addi	s5,s5,956 # 80010cd0 <cpus>
    8000191c:	00779713          	slli	a4,a5,0x7
    80001920:	00ea86b3          	add	a3,s5,a4
    80001924:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffdd120>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    80001928:	0721                	addi	a4,a4,8
    8000192a:	9aba                	add	s5,s5,a4
                c->proc = p;
    8000192c:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    8000192e:	00007c17          	auipc	s8,0x7
    80001932:	05ac0c13          	addi	s8,s8,90 # 80008988 <sched_pointer>
    80001936:	00000b97          	auipc	s7,0x0
    8000193a:	fc2b8b93          	addi	s7,s7,-62 # 800018f8 <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000193e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001942:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001946:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    8000194a:	0000f497          	auipc	s1,0xf
    8000194e:	7b648493          	addi	s1,s1,1974 # 80011100 <proc>
            if (p->state == RUNNABLE)
    80001952:	498d                	li	s3,3
                p->state = RUNNING;
    80001954:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    80001956:	00015a17          	auipc	s4,0x15
    8000195a:	1aaa0a13          	addi	s4,s4,426 # 80016b00 <tickslock>
    8000195e:	a81d                	j	80001994 <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    80001960:	8526                	mv	a0,s1
    80001962:	fffff097          	auipc	ra,0xfffff
    80001966:	3ec080e7          	jalr	1004(ra) # 80000d4e <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    8000196a:	60a6                	ld	ra,72(sp)
    8000196c:	6406                	ld	s0,64(sp)
    8000196e:	74e2                	ld	s1,56(sp)
    80001970:	7942                	ld	s2,48(sp)
    80001972:	79a2                	ld	s3,40(sp)
    80001974:	7a02                	ld	s4,32(sp)
    80001976:	6ae2                	ld	s5,24(sp)
    80001978:	6b42                	ld	s6,16(sp)
    8000197a:	6ba2                	ld	s7,8(sp)
    8000197c:	6c02                	ld	s8,0(sp)
    8000197e:	6161                	addi	sp,sp,80
    80001980:	8082                	ret
            release(&p->lock);
    80001982:	8526                	mv	a0,s1
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	3ca080e7          	jalr	970(ra) # 80000d4e <release>
        for (p = proc; p < &proc[NPROC]; p++)
    8000198c:	16848493          	addi	s1,s1,360
    80001990:	fb4487e3          	beq	s1,s4,8000193e <rr_scheduler+0x46>
            acquire(&p->lock);
    80001994:	8526                	mv	a0,s1
    80001996:	fffff097          	auipc	ra,0xfffff
    8000199a:	304080e7          	jalr	772(ra) # 80000c9a <acquire>
            if (p->state == RUNNABLE)
    8000199e:	4c9c                	lw	a5,24(s1)
    800019a0:	ff3791e3          	bne	a5,s3,80001982 <rr_scheduler+0x8a>
                p->state = RUNNING;
    800019a4:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    800019a8:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    800019ac:	06048593          	addi	a1,s1,96
    800019b0:	8556                	mv	a0,s5
    800019b2:	00001097          	auipc	ra,0x1
    800019b6:	020080e7          	jalr	32(ra) # 800029d2 <swtch>
                if (sched_pointer != &rr_scheduler)
    800019ba:	000c3783          	ld	a5,0(s8)
    800019be:	fb7791e3          	bne	a5,s7,80001960 <rr_scheduler+0x68>
                c->proc = 0;
    800019c2:	00093023          	sd	zero,0(s2)
    800019c6:	bf75                	j	80001982 <rr_scheduler+0x8a>

00000000800019c8 <proc_mapstacks>:
{
    800019c8:	7139                	addi	sp,sp,-64
    800019ca:	fc06                	sd	ra,56(sp)
    800019cc:	f822                	sd	s0,48(sp)
    800019ce:	f426                	sd	s1,40(sp)
    800019d0:	f04a                	sd	s2,32(sp)
    800019d2:	ec4e                	sd	s3,24(sp)
    800019d4:	e852                	sd	s4,16(sp)
    800019d6:	e456                	sd	s5,8(sp)
    800019d8:	e05a                	sd	s6,0(sp)
    800019da:	0080                	addi	s0,sp,64
    800019dc:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    800019de:	0000f497          	auipc	s1,0xf
    800019e2:	72248493          	addi	s1,s1,1826 # 80011100 <proc>
        uint64 va = KSTACK((int)(p - proc));
    800019e6:	8b26                	mv	s6,s1
    800019e8:	00006a97          	auipc	s5,0x6
    800019ec:	628a8a93          	addi	s5,s5,1576 # 80008010 <__func__.1+0x8>
    800019f0:	04000937          	lui	s2,0x4000
    800019f4:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019f6:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    800019f8:	00015a17          	auipc	s4,0x15
    800019fc:	108a0a13          	addi	s4,s4,264 # 80016b00 <tickslock>
        char *pa = kalloc();
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	15e080e7          	jalr	350(ra) # 80000b5e <kalloc>
    80001a08:	862a                	mv	a2,a0
        if (pa == 0)
    80001a0a:	c131                	beqz	a0,80001a4e <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001a0c:	416485b3          	sub	a1,s1,s6
    80001a10:	858d                	srai	a1,a1,0x3
    80001a12:	000ab783          	ld	a5,0(s5)
    80001a16:	02f585b3          	mul	a1,a1,a5
    80001a1a:	2585                	addiw	a1,a1,1
    80001a1c:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a20:	4719                	li	a4,6
    80001a22:	6685                	lui	a3,0x1
    80001a24:	40b905b3          	sub	a1,s2,a1
    80001a28:	854e                	mv	a0,s3
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	7d6080e7          	jalr	2006(ra) # 80001200 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001a32:	16848493          	addi	s1,s1,360
    80001a36:	fd4495e3          	bne	s1,s4,80001a00 <proc_mapstacks+0x38>
}
    80001a3a:	70e2                	ld	ra,56(sp)
    80001a3c:	7442                	ld	s0,48(sp)
    80001a3e:	74a2                	ld	s1,40(sp)
    80001a40:	7902                	ld	s2,32(sp)
    80001a42:	69e2                	ld	s3,24(sp)
    80001a44:	6a42                	ld	s4,16(sp)
    80001a46:	6aa2                	ld	s5,8(sp)
    80001a48:	6b02                	ld	s6,0(sp)
    80001a4a:	6121                	addi	sp,sp,64
    80001a4c:	8082                	ret
            panic("kalloc");
    80001a4e:	00006517          	auipc	a0,0x6
    80001a52:	7ca50513          	addi	a0,a0,1994 # 80008218 <digits+0x1c8>
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	ae6080e7          	jalr	-1306(ra) # 8000053c <panic>

0000000080001a5e <procinit>:
{
    80001a5e:	7139                	addi	sp,sp,-64
    80001a60:	fc06                	sd	ra,56(sp)
    80001a62:	f822                	sd	s0,48(sp)
    80001a64:	f426                	sd	s1,40(sp)
    80001a66:	f04a                	sd	s2,32(sp)
    80001a68:	ec4e                	sd	s3,24(sp)
    80001a6a:	e852                	sd	s4,16(sp)
    80001a6c:	e456                	sd	s5,8(sp)
    80001a6e:	e05a                	sd	s6,0(sp)
    80001a70:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001a72:	00006597          	auipc	a1,0x6
    80001a76:	7ae58593          	addi	a1,a1,1966 # 80008220 <digits+0x1d0>
    80001a7a:	0000f517          	auipc	a0,0xf
    80001a7e:	65650513          	addi	a0,a0,1622 # 800110d0 <pid_lock>
    80001a82:	fffff097          	auipc	ra,0xfffff
    80001a86:	188080e7          	jalr	392(ra) # 80000c0a <initlock>
    initlock(&wait_lock, "wait_lock");
    80001a8a:	00006597          	auipc	a1,0x6
    80001a8e:	79e58593          	addi	a1,a1,1950 # 80008228 <digits+0x1d8>
    80001a92:	0000f517          	auipc	a0,0xf
    80001a96:	65650513          	addi	a0,a0,1622 # 800110e8 <wait_lock>
    80001a9a:	fffff097          	auipc	ra,0xfffff
    80001a9e:	170080e7          	jalr	368(ra) # 80000c0a <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001aa2:	0000f497          	auipc	s1,0xf
    80001aa6:	65e48493          	addi	s1,s1,1630 # 80011100 <proc>
        initlock(&p->lock, "proc");
    80001aaa:	00006b17          	auipc	s6,0x6
    80001aae:	78eb0b13          	addi	s6,s6,1934 # 80008238 <digits+0x1e8>
        p->kstack = KSTACK((int)(p - proc));
    80001ab2:	8aa6                	mv	s5,s1
    80001ab4:	00006a17          	auipc	s4,0x6
    80001ab8:	55ca0a13          	addi	s4,s4,1372 # 80008010 <__func__.1+0x8>
    80001abc:	04000937          	lui	s2,0x4000
    80001ac0:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001ac2:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001ac4:	00015997          	auipc	s3,0x15
    80001ac8:	03c98993          	addi	s3,s3,60 # 80016b00 <tickslock>
        initlock(&p->lock, "proc");
    80001acc:	85da                	mv	a1,s6
    80001ace:	8526                	mv	a0,s1
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	13a080e7          	jalr	314(ra) # 80000c0a <initlock>
        p->state = UNUSED;
    80001ad8:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001adc:	415487b3          	sub	a5,s1,s5
    80001ae0:	878d                	srai	a5,a5,0x3
    80001ae2:	000a3703          	ld	a4,0(s4)
    80001ae6:	02e787b3          	mul	a5,a5,a4
    80001aea:	2785                	addiw	a5,a5,1
    80001aec:	00d7979b          	slliw	a5,a5,0xd
    80001af0:	40f907b3          	sub	a5,s2,a5
    80001af4:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001af6:	16848493          	addi	s1,s1,360
    80001afa:	fd3499e3          	bne	s1,s3,80001acc <procinit+0x6e>
}
    80001afe:	70e2                	ld	ra,56(sp)
    80001b00:	7442                	ld	s0,48(sp)
    80001b02:	74a2                	ld	s1,40(sp)
    80001b04:	7902                	ld	s2,32(sp)
    80001b06:	69e2                	ld	s3,24(sp)
    80001b08:	6a42                	ld	s4,16(sp)
    80001b0a:	6aa2                	ld	s5,8(sp)
    80001b0c:	6b02                	ld	s6,0(sp)
    80001b0e:	6121                	addi	sp,sp,64
    80001b10:	8082                	ret

0000000080001b12 <copy_array>:
{
    80001b12:	1141                	addi	sp,sp,-16
    80001b14:	e422                	sd	s0,8(sp)
    80001b16:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001b18:	00c05c63          	blez	a2,80001b30 <copy_array+0x1e>
    80001b1c:	87aa                	mv	a5,a0
    80001b1e:	9532                	add	a0,a0,a2
        dst[i] = src[i];
    80001b20:	0007c703          	lbu	a4,0(a5)
    80001b24:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001b28:	0785                	addi	a5,a5,1
    80001b2a:	0585                	addi	a1,a1,1
    80001b2c:	fea79ae3          	bne	a5,a0,80001b20 <copy_array+0xe>
}
    80001b30:	6422                	ld	s0,8(sp)
    80001b32:	0141                	addi	sp,sp,16
    80001b34:	8082                	ret

0000000080001b36 <cpuid>:
{
    80001b36:	1141                	addi	sp,sp,-16
    80001b38:	e422                	sd	s0,8(sp)
    80001b3a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b3c:	8512                	mv	a0,tp
}
    80001b3e:	2501                	sext.w	a0,a0
    80001b40:	6422                	ld	s0,8(sp)
    80001b42:	0141                	addi	sp,sp,16
    80001b44:	8082                	ret

0000000080001b46 <mycpu>:
{
    80001b46:	1141                	addi	sp,sp,-16
    80001b48:	e422                	sd	s0,8(sp)
    80001b4a:	0800                	addi	s0,sp,16
    80001b4c:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001b4e:	2781                	sext.w	a5,a5
    80001b50:	079e                	slli	a5,a5,0x7
}
    80001b52:	0000f517          	auipc	a0,0xf
    80001b56:	17e50513          	addi	a0,a0,382 # 80010cd0 <cpus>
    80001b5a:	953e                	add	a0,a0,a5
    80001b5c:	6422                	ld	s0,8(sp)
    80001b5e:	0141                	addi	sp,sp,16
    80001b60:	8082                	ret

0000000080001b62 <myproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    push_off();
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	0e2080e7          	jalr	226(ra) # 80000c4e <push_off>
    80001b74:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001b76:	2781                	sext.w	a5,a5
    80001b78:	079e                	slli	a5,a5,0x7
    80001b7a:	0000f717          	auipc	a4,0xf
    80001b7e:	15670713          	addi	a4,a4,342 # 80010cd0 <cpus>
    80001b82:	97ba                	add	a5,a5,a4
    80001b84:	6384                	ld	s1,0(a5)
    pop_off();
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	168080e7          	jalr	360(ra) # 80000cee <pop_off>
}
    80001b8e:	8526                	mv	a0,s1
    80001b90:	60e2                	ld	ra,24(sp)
    80001b92:	6442                	ld	s0,16(sp)
    80001b94:	64a2                	ld	s1,8(sp)
    80001b96:	6105                	addi	sp,sp,32
    80001b98:	8082                	ret

0000000080001b9a <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001b9a:	1141                	addi	sp,sp,-16
    80001b9c:	e406                	sd	ra,8(sp)
    80001b9e:	e022                	sd	s0,0(sp)
    80001ba0:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001ba2:	00000097          	auipc	ra,0x0
    80001ba6:	fc0080e7          	jalr	-64(ra) # 80001b62 <myproc>
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	1a4080e7          	jalr	420(ra) # 80000d4e <release>

    if (first)
    80001bb2:	00007797          	auipc	a5,0x7
    80001bb6:	dce7a783          	lw	a5,-562(a5) # 80008980 <first.1>
    80001bba:	eb89                	bnez	a5,80001bcc <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001bbc:	00001097          	auipc	ra,0x1
    80001bc0:	ec0080e7          	jalr	-320(ra) # 80002a7c <usertrapret>
}
    80001bc4:	60a2                	ld	ra,8(sp)
    80001bc6:	6402                	ld	s0,0(sp)
    80001bc8:	0141                	addi	sp,sp,16
    80001bca:	8082                	ret
        first = 0;
    80001bcc:	00007797          	auipc	a5,0x7
    80001bd0:	da07aa23          	sw	zero,-588(a5) # 80008980 <first.1>
        fsinit(ROOTDEV);
    80001bd4:	4505                	li	a0,1
    80001bd6:	00002097          	auipc	ra,0x2
    80001bda:	cf2080e7          	jalr	-782(ra) # 800038c8 <fsinit>
    80001bde:	bff9                	j	80001bbc <forkret+0x22>

0000000080001be0 <allocpid>:
{
    80001be0:	1101                	addi	sp,sp,-32
    80001be2:	ec06                	sd	ra,24(sp)
    80001be4:	e822                	sd	s0,16(sp)
    80001be6:	e426                	sd	s1,8(sp)
    80001be8:	e04a                	sd	s2,0(sp)
    80001bea:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001bec:	0000f917          	auipc	s2,0xf
    80001bf0:	4e490913          	addi	s2,s2,1252 # 800110d0 <pid_lock>
    80001bf4:	854a                	mv	a0,s2
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	0a4080e7          	jalr	164(ra) # 80000c9a <acquire>
    pid = nextpid;
    80001bfe:	00007797          	auipc	a5,0x7
    80001c02:	d9278793          	addi	a5,a5,-622 # 80008990 <nextpid>
    80001c06:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001c08:	0014871b          	addiw	a4,s1,1
    80001c0c:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001c0e:	854a                	mv	a0,s2
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	13e080e7          	jalr	318(ra) # 80000d4e <release>
}
    80001c18:	8526                	mv	a0,s1
    80001c1a:	60e2                	ld	ra,24(sp)
    80001c1c:	6442                	ld	s0,16(sp)
    80001c1e:	64a2                	ld	s1,8(sp)
    80001c20:	6902                	ld	s2,0(sp)
    80001c22:	6105                	addi	sp,sp,32
    80001c24:	8082                	ret

0000000080001c26 <proc_pagetable>:
{
    80001c26:	1101                	addi	sp,sp,-32
    80001c28:	ec06                	sd	ra,24(sp)
    80001c2a:	e822                	sd	s0,16(sp)
    80001c2c:	e426                	sd	s1,8(sp)
    80001c2e:	e04a                	sd	s2,0(sp)
    80001c30:	1000                	addi	s0,sp,32
    80001c32:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	7b6080e7          	jalr	1974(ra) # 800013ea <uvmcreate>
    80001c3c:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001c3e:	c121                	beqz	a0,80001c7e <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c40:	4729                	li	a4,10
    80001c42:	00005697          	auipc	a3,0x5
    80001c46:	3be68693          	addi	a3,a3,958 # 80007000 <_trampoline>
    80001c4a:	6605                	lui	a2,0x1
    80001c4c:	040005b7          	lui	a1,0x4000
    80001c50:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c52:	05b2                	slli	a1,a1,0xc
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	50c080e7          	jalr	1292(ra) # 80001160 <mappages>
    80001c5c:	02054863          	bltz	a0,80001c8c <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c60:	4719                	li	a4,6
    80001c62:	05893683          	ld	a3,88(s2)
    80001c66:	6605                	lui	a2,0x1
    80001c68:	020005b7          	lui	a1,0x2000
    80001c6c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c6e:	05b6                	slli	a1,a1,0xd
    80001c70:	8526                	mv	a0,s1
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	4ee080e7          	jalr	1262(ra) # 80001160 <mappages>
    80001c7a:	02054163          	bltz	a0,80001c9c <proc_pagetable+0x76>
}
    80001c7e:	8526                	mv	a0,s1
    80001c80:	60e2                	ld	ra,24(sp)
    80001c82:	6442                	ld	s0,16(sp)
    80001c84:	64a2                	ld	s1,8(sp)
    80001c86:	6902                	ld	s2,0(sp)
    80001c88:	6105                	addi	sp,sp,32
    80001c8a:	8082                	ret
        uvmfree(pagetable, 0);
    80001c8c:	4581                	li	a1,0
    80001c8e:	8526                	mv	a0,s1
    80001c90:	00000097          	auipc	ra,0x0
    80001c94:	960080e7          	jalr	-1696(ra) # 800015f0 <uvmfree>
        return 0;
    80001c98:	4481                	li	s1,0
    80001c9a:	b7d5                	j	80001c7e <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c9c:	4681                	li	a3,0
    80001c9e:	4605                	li	a2,1
    80001ca0:	040005b7          	lui	a1,0x4000
    80001ca4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ca6:	05b2                	slli	a1,a1,0xc
    80001ca8:	8526                	mv	a0,s1
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	67c080e7          	jalr	1660(ra) # 80001326 <uvmunmap>
        uvmfree(pagetable, 0);
    80001cb2:	4581                	li	a1,0
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	93a080e7          	jalr	-1734(ra) # 800015f0 <uvmfree>
        return 0;
    80001cbe:	4481                	li	s1,0
    80001cc0:	bf7d                	j	80001c7e <proc_pagetable+0x58>

0000000080001cc2 <proc_freepagetable>:
{
    80001cc2:	1101                	addi	sp,sp,-32
    80001cc4:	ec06                	sd	ra,24(sp)
    80001cc6:	e822                	sd	s0,16(sp)
    80001cc8:	e426                	sd	s1,8(sp)
    80001cca:	e04a                	sd	s2,0(sp)
    80001ccc:	1000                	addi	s0,sp,32
    80001cce:	84aa                	mv	s1,a0
    80001cd0:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cd2:	4681                	li	a3,0
    80001cd4:	4605                	li	a2,1
    80001cd6:	040005b7          	lui	a1,0x4000
    80001cda:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cdc:	05b2                	slli	a1,a1,0xc
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	648080e7          	jalr	1608(ra) # 80001326 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ce6:	4681                	li	a3,0
    80001ce8:	4605                	li	a2,1
    80001cea:	020005b7          	lui	a1,0x2000
    80001cee:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001cf0:	05b6                	slli	a1,a1,0xd
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	632080e7          	jalr	1586(ra) # 80001326 <uvmunmap>
    uvmfree(pagetable, sz);
    80001cfc:	85ca                	mv	a1,s2
    80001cfe:	8526                	mv	a0,s1
    80001d00:	00000097          	auipc	ra,0x0
    80001d04:	8f0080e7          	jalr	-1808(ra) # 800015f0 <uvmfree>
}
    80001d08:	60e2                	ld	ra,24(sp)
    80001d0a:	6442                	ld	s0,16(sp)
    80001d0c:	64a2                	ld	s1,8(sp)
    80001d0e:	6902                	ld	s2,0(sp)
    80001d10:	6105                	addi	sp,sp,32
    80001d12:	8082                	ret

0000000080001d14 <freeproc>:
{
    80001d14:	1101                	addi	sp,sp,-32
    80001d16:	ec06                	sd	ra,24(sp)
    80001d18:	e822                	sd	s0,16(sp)
    80001d1a:	e426                	sd	s1,8(sp)
    80001d1c:	1000                	addi	s0,sp,32
    80001d1e:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001d20:	6d28                	ld	a0,88(a0)
    80001d22:	c509                	beqz	a0,80001d2c <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	cd2080e7          	jalr	-814(ra) # 800009f6 <kfree>
    p->trapframe = 0;
    80001d2c:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001d30:	68a8                	ld	a0,80(s1)
    80001d32:	c511                	beqz	a0,80001d3e <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001d34:	64ac                	ld	a1,72(s1)
    80001d36:	00000097          	auipc	ra,0x0
    80001d3a:	f8c080e7          	jalr	-116(ra) # 80001cc2 <proc_freepagetable>
    p->pagetable = 0;
    80001d3e:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001d42:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001d46:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001d4a:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001d4e:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001d52:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001d56:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001d5a:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001d5e:	0004ac23          	sw	zero,24(s1)
}
    80001d62:	60e2                	ld	ra,24(sp)
    80001d64:	6442                	ld	s0,16(sp)
    80001d66:	64a2                	ld	s1,8(sp)
    80001d68:	6105                	addi	sp,sp,32
    80001d6a:	8082                	ret

0000000080001d6c <allocproc>:
{
    80001d6c:	1101                	addi	sp,sp,-32
    80001d6e:	ec06                	sd	ra,24(sp)
    80001d70:	e822                	sd	s0,16(sp)
    80001d72:	e426                	sd	s1,8(sp)
    80001d74:	e04a                	sd	s2,0(sp)
    80001d76:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001d78:	0000f497          	auipc	s1,0xf
    80001d7c:	38848493          	addi	s1,s1,904 # 80011100 <proc>
    80001d80:	00015917          	auipc	s2,0x15
    80001d84:	d8090913          	addi	s2,s2,-640 # 80016b00 <tickslock>
        acquire(&p->lock);
    80001d88:	8526                	mv	a0,s1
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	f10080e7          	jalr	-240(ra) # 80000c9a <acquire>
        if (p->state == UNUSED)
    80001d92:	4c9c                	lw	a5,24(s1)
    80001d94:	cf81                	beqz	a5,80001dac <allocproc+0x40>
            release(&p->lock);
    80001d96:	8526                	mv	a0,s1
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	fb6080e7          	jalr	-74(ra) # 80000d4e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001da0:	16848493          	addi	s1,s1,360
    80001da4:	ff2492e3          	bne	s1,s2,80001d88 <allocproc+0x1c>
    return 0;
    80001da8:	4481                	li	s1,0
    80001daa:	a889                	j	80001dfc <allocproc+0x90>
    p->pid = allocpid();
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	e34080e7          	jalr	-460(ra) # 80001be0 <allocpid>
    80001db4:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001db6:	4785                	li	a5,1
    80001db8:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	da4080e7          	jalr	-604(ra) # 80000b5e <kalloc>
    80001dc2:	892a                	mv	s2,a0
    80001dc4:	eca8                	sd	a0,88(s1)
    80001dc6:	c131                	beqz	a0,80001e0a <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001dc8:	8526                	mv	a0,s1
    80001dca:	00000097          	auipc	ra,0x0
    80001dce:	e5c080e7          	jalr	-420(ra) # 80001c26 <proc_pagetable>
    80001dd2:	892a                	mv	s2,a0
    80001dd4:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001dd6:	c531                	beqz	a0,80001e22 <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001dd8:	07000613          	li	a2,112
    80001ddc:	4581                	li	a1,0
    80001dde:	06048513          	addi	a0,s1,96
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	fb4080e7          	jalr	-76(ra) # 80000d96 <memset>
    p->context.ra = (uint64)forkret;
    80001dea:	00000797          	auipc	a5,0x0
    80001dee:	db078793          	addi	a5,a5,-592 # 80001b9a <forkret>
    80001df2:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001df4:	60bc                	ld	a5,64(s1)
    80001df6:	6705                	lui	a4,0x1
    80001df8:	97ba                	add	a5,a5,a4
    80001dfa:	f4bc                	sd	a5,104(s1)
}
    80001dfc:	8526                	mv	a0,s1
    80001dfe:	60e2                	ld	ra,24(sp)
    80001e00:	6442                	ld	s0,16(sp)
    80001e02:	64a2                	ld	s1,8(sp)
    80001e04:	6902                	ld	s2,0(sp)
    80001e06:	6105                	addi	sp,sp,32
    80001e08:	8082                	ret
        freeproc(p);
    80001e0a:	8526                	mv	a0,s1
    80001e0c:	00000097          	auipc	ra,0x0
    80001e10:	f08080e7          	jalr	-248(ra) # 80001d14 <freeproc>
        release(&p->lock);
    80001e14:	8526                	mv	a0,s1
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	f38080e7          	jalr	-200(ra) # 80000d4e <release>
        return 0;
    80001e1e:	84ca                	mv	s1,s2
    80001e20:	bff1                	j	80001dfc <allocproc+0x90>
        freeproc(p);
    80001e22:	8526                	mv	a0,s1
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	ef0080e7          	jalr	-272(ra) # 80001d14 <freeproc>
        release(&p->lock);
    80001e2c:	8526                	mv	a0,s1
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	f20080e7          	jalr	-224(ra) # 80000d4e <release>
        return 0;
    80001e36:	84ca                	mv	s1,s2
    80001e38:	b7d1                	j	80001dfc <allocproc+0x90>

0000000080001e3a <userinit>:
{
    80001e3a:	1101                	addi	sp,sp,-32
    80001e3c:	ec06                	sd	ra,24(sp)
    80001e3e:	e822                	sd	s0,16(sp)
    80001e40:	e426                	sd	s1,8(sp)
    80001e42:	1000                	addi	s0,sp,32
    p = allocproc();
    80001e44:	00000097          	auipc	ra,0x0
    80001e48:	f28080e7          	jalr	-216(ra) # 80001d6c <allocproc>
    80001e4c:	84aa                	mv	s1,a0
    initproc = p;
    80001e4e:	00007797          	auipc	a5,0x7
    80001e52:	c0a7b523          	sd	a0,-1014(a5) # 80008a58 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e56:	03400613          	li	a2,52
    80001e5a:	00007597          	auipc	a1,0x7
    80001e5e:	b4658593          	addi	a1,a1,-1210 # 800089a0 <initcode>
    80001e62:	6928                	ld	a0,80(a0)
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	5b4080e7          	jalr	1460(ra) # 80001418 <uvmfirst>
    p->sz = PGSIZE;
    80001e6c:	6785                	lui	a5,0x1
    80001e6e:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001e70:	6cb8                	ld	a4,88(s1)
    80001e72:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001e76:	6cb8                	ld	a4,88(s1)
    80001e78:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e7a:	4641                	li	a2,16
    80001e7c:	00006597          	auipc	a1,0x6
    80001e80:	3c458593          	addi	a1,a1,964 # 80008240 <digits+0x1f0>
    80001e84:	15848513          	addi	a0,s1,344
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	056080e7          	jalr	86(ra) # 80000ede <safestrcpy>
    p->cwd = namei("/");
    80001e90:	00006517          	auipc	a0,0x6
    80001e94:	3c050513          	addi	a0,a0,960 # 80008250 <digits+0x200>
    80001e98:	00002097          	auipc	ra,0x2
    80001e9c:	44e080e7          	jalr	1102(ra) # 800042e6 <namei>
    80001ea0:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001ea4:	478d                	li	a5,3
    80001ea6:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	ea4080e7          	jalr	-348(ra) # 80000d4e <release>
}
    80001eb2:	60e2                	ld	ra,24(sp)
    80001eb4:	6442                	ld	s0,16(sp)
    80001eb6:	64a2                	ld	s1,8(sp)
    80001eb8:	6105                	addi	sp,sp,32
    80001eba:	8082                	ret

0000000080001ebc <growproc>:
{
    80001ebc:	1101                	addi	sp,sp,-32
    80001ebe:	ec06                	sd	ra,24(sp)
    80001ec0:	e822                	sd	s0,16(sp)
    80001ec2:	e426                	sd	s1,8(sp)
    80001ec4:	e04a                	sd	s2,0(sp)
    80001ec6:	1000                	addi	s0,sp,32
    80001ec8:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001eca:	00000097          	auipc	ra,0x0
    80001ece:	c98080e7          	jalr	-872(ra) # 80001b62 <myproc>
    80001ed2:	84aa                	mv	s1,a0
    sz = p->sz;
    80001ed4:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001ed6:	01204c63          	bgtz	s2,80001eee <growproc+0x32>
    else if (n < 0)
    80001eda:	02094663          	bltz	s2,80001f06 <growproc+0x4a>
    p->sz = sz;
    80001ede:	e4ac                	sd	a1,72(s1)
    return 0;
    80001ee0:	4501                	li	a0,0
}
    80001ee2:	60e2                	ld	ra,24(sp)
    80001ee4:	6442                	ld	s0,16(sp)
    80001ee6:	64a2                	ld	s1,8(sp)
    80001ee8:	6902                	ld	s2,0(sp)
    80001eea:	6105                	addi	sp,sp,32
    80001eec:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001eee:	4691                	li	a3,4
    80001ef0:	00b90633          	add	a2,s2,a1
    80001ef4:	6928                	ld	a0,80(a0)
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	5dc080e7          	jalr	1500(ra) # 800014d2 <uvmalloc>
    80001efe:	85aa                	mv	a1,a0
    80001f00:	fd79                	bnez	a0,80001ede <growproc+0x22>
            return -1;
    80001f02:	557d                	li	a0,-1
    80001f04:	bff9                	j	80001ee2 <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f06:	00b90633          	add	a2,s2,a1
    80001f0a:	6928                	ld	a0,80(a0)
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	57e080e7          	jalr	1406(ra) # 8000148a <uvmdealloc>
    80001f14:	85aa                	mv	a1,a0
    80001f16:	b7e1                	j	80001ede <growproc+0x22>

0000000080001f18 <ps>:
{
    80001f18:	715d                	addi	sp,sp,-80
    80001f1a:	e486                	sd	ra,72(sp)
    80001f1c:	e0a2                	sd	s0,64(sp)
    80001f1e:	fc26                	sd	s1,56(sp)
    80001f20:	f84a                	sd	s2,48(sp)
    80001f22:	f44e                	sd	s3,40(sp)
    80001f24:	f052                	sd	s4,32(sp)
    80001f26:	ec56                	sd	s5,24(sp)
    80001f28:	e85a                	sd	s6,16(sp)
    80001f2a:	e45e                	sd	s7,8(sp)
    80001f2c:	e062                	sd	s8,0(sp)
    80001f2e:	0880                	addi	s0,sp,80
    80001f30:	84aa                	mv	s1,a0
    80001f32:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	c2e080e7          	jalr	-978(ra) # 80001b62 <myproc>
    if (count == 0)
    80001f3c:	120b8063          	beqz	s7,8000205c <ps+0x144>
    void *result = (void *)myproc()->sz;
    80001f40:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80001f44:	003b951b          	slliw	a0,s7,0x3
    80001f48:	0175053b          	addw	a0,a0,s7
    80001f4c:	0025151b          	slliw	a0,a0,0x2
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	f6c080e7          	jalr	-148(ra) # 80001ebc <growproc>
    80001f58:	10054463          	bltz	a0,80002060 <ps+0x148>
    struct user_proc loc_result[count];
    80001f5c:	003b9a13          	slli	s4,s7,0x3
    80001f60:	9a5e                	add	s4,s4,s7
    80001f62:	0a0a                	slli	s4,s4,0x2
    80001f64:	00fa0793          	addi	a5,s4,15
    80001f68:	8391                	srli	a5,a5,0x4
    80001f6a:	0792                	slli	a5,a5,0x4
    80001f6c:	40f10133          	sub	sp,sp,a5
    80001f70:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    80001f72:	007e97b7          	lui	a5,0x7e9
    80001f76:	02f484b3          	mul	s1,s1,a5
    80001f7a:	0000f797          	auipc	a5,0xf
    80001f7e:	18678793          	addi	a5,a5,390 # 80011100 <proc>
    80001f82:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80001f84:	00015797          	auipc	a5,0x15
    80001f88:	b7c78793          	addi	a5,a5,-1156 # 80016b00 <tickslock>
    80001f8c:	0cf4fc63          	bgeu	s1,a5,80002064 <ps+0x14c>
        if (localCount == count)
    80001f90:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    80001f94:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    80001f96:	8c3e                	mv	s8,a5
    80001f98:	a069                	j	80002022 <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    80001f9a:	00399793          	slli	a5,s3,0x3
    80001f9e:	97ce                	add	a5,a5,s3
    80001fa0:	078a                	slli	a5,a5,0x2
    80001fa2:	97d6                	add	a5,a5,s5
    80001fa4:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80001fa8:	8526                	mv	a0,s1
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	da4080e7          	jalr	-604(ra) # 80000d4e <release>
    if (localCount < count)
    80001fb2:	0179f963          	bgeu	s3,s7,80001fc4 <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80001fb6:	00399793          	slli	a5,s3,0x3
    80001fba:	97ce                	add	a5,a5,s3
    80001fbc:	078a                	slli	a5,a5,0x2
    80001fbe:	97d6                	add	a5,a5,s5
    80001fc0:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    80001fc4:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    80001fc6:	00000097          	auipc	ra,0x0
    80001fca:	b9c080e7          	jalr	-1124(ra) # 80001b62 <myproc>
    80001fce:	86d2                	mv	a3,s4
    80001fd0:	8656                	mv	a2,s5
    80001fd2:	85da                	mv	a1,s6
    80001fd4:	6928                	ld	a0,80(a0)
    80001fd6:	fffff097          	auipc	ra,0xfffff
    80001fda:	758080e7          	jalr	1880(ra) # 8000172e <copyout>
}
    80001fde:	8526                	mv	a0,s1
    80001fe0:	fb040113          	addi	sp,s0,-80
    80001fe4:	60a6                	ld	ra,72(sp)
    80001fe6:	6406                	ld	s0,64(sp)
    80001fe8:	74e2                	ld	s1,56(sp)
    80001fea:	7942                	ld	s2,48(sp)
    80001fec:	79a2                	ld	s3,40(sp)
    80001fee:	7a02                	ld	s4,32(sp)
    80001ff0:	6ae2                	ld	s5,24(sp)
    80001ff2:	6b42                	ld	s6,16(sp)
    80001ff4:	6ba2                	ld	s7,8(sp)
    80001ff6:	6c02                	ld	s8,0(sp)
    80001ff8:	6161                	addi	sp,sp,80
    80001ffa:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    80001ffc:	5b9c                	lw	a5,48(a5)
    80001ffe:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    80002002:	8526                	mv	a0,s1
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	d4a080e7          	jalr	-694(ra) # 80000d4e <release>
        localCount++;
    8000200c:	2985                	addiw	s3,s3,1
    8000200e:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    80002012:	16848493          	addi	s1,s1,360
    80002016:	f984fee3          	bgeu	s1,s8,80001fb2 <ps+0x9a>
        if (localCount == count)
    8000201a:	02490913          	addi	s2,s2,36
    8000201e:	fb3b83e3          	beq	s7,s3,80001fc4 <ps+0xac>
        acquire(&p->lock);
    80002022:	8526                	mv	a0,s1
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	c76080e7          	jalr	-906(ra) # 80000c9a <acquire>
        if (p->state == UNUSED)
    8000202c:	4c9c                	lw	a5,24(s1)
    8000202e:	d7b5                	beqz	a5,80001f9a <ps+0x82>
        loc_result[localCount].state = p->state;
    80002030:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    80002034:	549c                	lw	a5,40(s1)
    80002036:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    8000203a:	54dc                	lw	a5,44(s1)
    8000203c:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    80002040:	589c                	lw	a5,48(s1)
    80002042:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    80002046:	4641                	li	a2,16
    80002048:	85ca                	mv	a1,s2
    8000204a:	15848513          	addi	a0,s1,344
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	ac4080e7          	jalr	-1340(ra) # 80001b12 <copy_array>
        if (p->parent != 0) // init
    80002056:	7c9c                	ld	a5,56(s1)
    80002058:	f3d5                	bnez	a5,80001ffc <ps+0xe4>
    8000205a:	b765                	j	80002002 <ps+0xea>
        return result;
    8000205c:	4481                	li	s1,0
    8000205e:	b741                	j	80001fde <ps+0xc6>
        return result;
    80002060:	4481                	li	s1,0
    80002062:	bfb5                	j	80001fde <ps+0xc6>
        return result;
    80002064:	4481                	li	s1,0
    80002066:	bfa5                	j	80001fde <ps+0xc6>

0000000080002068 <fork>:
{
    80002068:	7139                	addi	sp,sp,-64
    8000206a:	fc06                	sd	ra,56(sp)
    8000206c:	f822                	sd	s0,48(sp)
    8000206e:	f426                	sd	s1,40(sp)
    80002070:	f04a                	sd	s2,32(sp)
    80002072:	ec4e                	sd	s3,24(sp)
    80002074:	e852                	sd	s4,16(sp)
    80002076:	e456                	sd	s5,8(sp)
    80002078:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    8000207a:	00000097          	auipc	ra,0x0
    8000207e:	ae8080e7          	jalr	-1304(ra) # 80001b62 <myproc>
    80002082:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    80002084:	00000097          	auipc	ra,0x0
    80002088:	ce8080e7          	jalr	-792(ra) # 80001d6c <allocproc>
    8000208c:	10050c63          	beqz	a0,800021a4 <fork+0x13c>
    80002090:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80002092:	048ab603          	ld	a2,72(s5)
    80002096:	692c                	ld	a1,80(a0)
    80002098:	050ab503          	ld	a0,80(s5)
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	58e080e7          	jalr	1422(ra) # 8000162a <uvmcopy>
    800020a4:	04054863          	bltz	a0,800020f4 <fork+0x8c>
    np->sz = p->sz;
    800020a8:	048ab783          	ld	a5,72(s5)
    800020ac:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    800020b0:	058ab683          	ld	a3,88(s5)
    800020b4:	87b6                	mv	a5,a3
    800020b6:	058a3703          	ld	a4,88(s4)
    800020ba:	12068693          	addi	a3,a3,288
    800020be:	0007b803          	ld	a6,0(a5)
    800020c2:	6788                	ld	a0,8(a5)
    800020c4:	6b8c                	ld	a1,16(a5)
    800020c6:	6f90                	ld	a2,24(a5)
    800020c8:	01073023          	sd	a6,0(a4)
    800020cc:	e708                	sd	a0,8(a4)
    800020ce:	eb0c                	sd	a1,16(a4)
    800020d0:	ef10                	sd	a2,24(a4)
    800020d2:	02078793          	addi	a5,a5,32
    800020d6:	02070713          	addi	a4,a4,32
    800020da:	fed792e3          	bne	a5,a3,800020be <fork+0x56>
    np->trapframe->a0 = 0;
    800020de:	058a3783          	ld	a5,88(s4)
    800020e2:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    800020e6:	0d0a8493          	addi	s1,s5,208
    800020ea:	0d0a0913          	addi	s2,s4,208
    800020ee:	150a8993          	addi	s3,s5,336
    800020f2:	a00d                	j	80002114 <fork+0xac>
        freeproc(np);
    800020f4:	8552                	mv	a0,s4
    800020f6:	00000097          	auipc	ra,0x0
    800020fa:	c1e080e7          	jalr	-994(ra) # 80001d14 <freeproc>
        release(&np->lock);
    800020fe:	8552                	mv	a0,s4
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	c4e080e7          	jalr	-946(ra) # 80000d4e <release>
        return -1;
    80002108:	597d                	li	s2,-1
    8000210a:	a059                	j	80002190 <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    8000210c:	04a1                	addi	s1,s1,8
    8000210e:	0921                	addi	s2,s2,8
    80002110:	01348b63          	beq	s1,s3,80002126 <fork+0xbe>
        if (p->ofile[i])
    80002114:	6088                	ld	a0,0(s1)
    80002116:	d97d                	beqz	a0,8000210c <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002118:	00003097          	auipc	ra,0x3
    8000211c:	840080e7          	jalr	-1984(ra) # 80004958 <filedup>
    80002120:	00a93023          	sd	a0,0(s2)
    80002124:	b7e5                	j	8000210c <fork+0xa4>
    np->cwd = idup(p->cwd);
    80002126:	150ab503          	ld	a0,336(s5)
    8000212a:	00002097          	auipc	ra,0x2
    8000212e:	9d8080e7          	jalr	-1576(ra) # 80003b02 <idup>
    80002132:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002136:	4641                	li	a2,16
    80002138:	158a8593          	addi	a1,s5,344
    8000213c:	158a0513          	addi	a0,s4,344
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	d9e080e7          	jalr	-610(ra) # 80000ede <safestrcpy>
    pid = np->pid;
    80002148:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    8000214c:	8552                	mv	a0,s4
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	c00080e7          	jalr	-1024(ra) # 80000d4e <release>
    acquire(&wait_lock);
    80002156:	0000f497          	auipc	s1,0xf
    8000215a:	f9248493          	addi	s1,s1,-110 # 800110e8 <wait_lock>
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	b3a080e7          	jalr	-1222(ra) # 80000c9a <acquire>
    np->parent = p;
    80002168:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	be0080e7          	jalr	-1056(ra) # 80000d4e <release>
    acquire(&np->lock);
    80002176:	8552                	mv	a0,s4
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	b22080e7          	jalr	-1246(ra) # 80000c9a <acquire>
    np->state = RUNNABLE;
    80002180:	478d                	li	a5,3
    80002182:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    80002186:	8552                	mv	a0,s4
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	bc6080e7          	jalr	-1082(ra) # 80000d4e <release>
}
    80002190:	854a                	mv	a0,s2
    80002192:	70e2                	ld	ra,56(sp)
    80002194:	7442                	ld	s0,48(sp)
    80002196:	74a2                	ld	s1,40(sp)
    80002198:	7902                	ld	s2,32(sp)
    8000219a:	69e2                	ld	s3,24(sp)
    8000219c:	6a42                	ld	s4,16(sp)
    8000219e:	6aa2                	ld	s5,8(sp)
    800021a0:	6121                	addi	sp,sp,64
    800021a2:	8082                	ret
        return -1;
    800021a4:	597d                	li	s2,-1
    800021a6:	b7ed                	j	80002190 <fork+0x128>

00000000800021a8 <scheduler>:
{
    800021a8:	1101                	addi	sp,sp,-32
    800021aa:	ec06                	sd	ra,24(sp)
    800021ac:	e822                	sd	s0,16(sp)
    800021ae:	e426                	sd	s1,8(sp)
    800021b0:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800021b2:	00006497          	auipc	s1,0x6
    800021b6:	7d648493          	addi	s1,s1,2006 # 80008988 <sched_pointer>
    800021ba:	609c                	ld	a5,0(s1)
    800021bc:	9782                	jalr	a5
    while (1)
    800021be:	bff5                	j	800021ba <scheduler+0x12>

00000000800021c0 <sched>:
{
    800021c0:	7179                	addi	sp,sp,-48
    800021c2:	f406                	sd	ra,40(sp)
    800021c4:	f022                	sd	s0,32(sp)
    800021c6:	ec26                	sd	s1,24(sp)
    800021c8:	e84a                	sd	s2,16(sp)
    800021ca:	e44e                	sd	s3,8(sp)
    800021cc:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800021ce:	00000097          	auipc	ra,0x0
    800021d2:	994080e7          	jalr	-1644(ra) # 80001b62 <myproc>
    800021d6:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	a48080e7          	jalr	-1464(ra) # 80000c20 <holding>
    800021e0:	c53d                	beqz	a0,8000224e <sched+0x8e>
    800021e2:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    800021e4:	2781                	sext.w	a5,a5
    800021e6:	079e                	slli	a5,a5,0x7
    800021e8:	0000f717          	auipc	a4,0xf
    800021ec:	ae870713          	addi	a4,a4,-1304 # 80010cd0 <cpus>
    800021f0:	97ba                	add	a5,a5,a4
    800021f2:	5fb8                	lw	a4,120(a5)
    800021f4:	4785                	li	a5,1
    800021f6:	06f71463          	bne	a4,a5,8000225e <sched+0x9e>
    if (p->state == RUNNING)
    800021fa:	4c98                	lw	a4,24(s1)
    800021fc:	4791                	li	a5,4
    800021fe:	06f70863          	beq	a4,a5,8000226e <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002202:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002206:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002208:	ebbd                	bnez	a5,8000227e <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000220a:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    8000220c:	0000f917          	auipc	s2,0xf
    80002210:	ac490913          	addi	s2,s2,-1340 # 80010cd0 <cpus>
    80002214:	2781                	sext.w	a5,a5
    80002216:	079e                	slli	a5,a5,0x7
    80002218:	97ca                	add	a5,a5,s2
    8000221a:	07c7a983          	lw	s3,124(a5)
    8000221e:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    80002220:	2581                	sext.w	a1,a1
    80002222:	059e                	slli	a1,a1,0x7
    80002224:	05a1                	addi	a1,a1,8
    80002226:	95ca                	add	a1,a1,s2
    80002228:	06048513          	addi	a0,s1,96
    8000222c:	00000097          	auipc	ra,0x0
    80002230:	7a6080e7          	jalr	1958(ra) # 800029d2 <swtch>
    80002234:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002236:	2781                	sext.w	a5,a5
    80002238:	079e                	slli	a5,a5,0x7
    8000223a:	993e                	add	s2,s2,a5
    8000223c:	07392e23          	sw	s3,124(s2)
}
    80002240:	70a2                	ld	ra,40(sp)
    80002242:	7402                	ld	s0,32(sp)
    80002244:	64e2                	ld	s1,24(sp)
    80002246:	6942                	ld	s2,16(sp)
    80002248:	69a2                	ld	s3,8(sp)
    8000224a:	6145                	addi	sp,sp,48
    8000224c:	8082                	ret
        panic("sched p->lock");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	00a50513          	addi	a0,a0,10 # 80008258 <digits+0x208>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2e6080e7          	jalr	742(ra) # 8000053c <panic>
        panic("sched locks");
    8000225e:	00006517          	auipc	a0,0x6
    80002262:	00a50513          	addi	a0,a0,10 # 80008268 <digits+0x218>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	2d6080e7          	jalr	726(ra) # 8000053c <panic>
        panic("sched running");
    8000226e:	00006517          	auipc	a0,0x6
    80002272:	00a50513          	addi	a0,a0,10 # 80008278 <digits+0x228>
    80002276:	ffffe097          	auipc	ra,0xffffe
    8000227a:	2c6080e7          	jalr	710(ra) # 8000053c <panic>
        panic("sched interruptible");
    8000227e:	00006517          	auipc	a0,0x6
    80002282:	00a50513          	addi	a0,a0,10 # 80008288 <digits+0x238>
    80002286:	ffffe097          	auipc	ra,0xffffe
    8000228a:	2b6080e7          	jalr	694(ra) # 8000053c <panic>

000000008000228e <yield>:
{
    8000228e:	1101                	addi	sp,sp,-32
    80002290:	ec06                	sd	ra,24(sp)
    80002292:	e822                	sd	s0,16(sp)
    80002294:	e426                	sd	s1,8(sp)
    80002296:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	8ca080e7          	jalr	-1846(ra) # 80001b62 <myproc>
    800022a0:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	9f8080e7          	jalr	-1544(ra) # 80000c9a <acquire>
    p->state = RUNNABLE;
    800022aa:	478d                	li	a5,3
    800022ac:	cc9c                	sw	a5,24(s1)
    sched();
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	f12080e7          	jalr	-238(ra) # 800021c0 <sched>
    release(&p->lock);
    800022b6:	8526                	mv	a0,s1
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	a96080e7          	jalr	-1386(ra) # 80000d4e <release>
}
    800022c0:	60e2                	ld	ra,24(sp)
    800022c2:	6442                	ld	s0,16(sp)
    800022c4:	64a2                	ld	s1,8(sp)
    800022c6:	6105                	addi	sp,sp,32
    800022c8:	8082                	ret

00000000800022ca <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800022ca:	7179                	addi	sp,sp,-48
    800022cc:	f406                	sd	ra,40(sp)
    800022ce:	f022                	sd	s0,32(sp)
    800022d0:	ec26                	sd	s1,24(sp)
    800022d2:	e84a                	sd	s2,16(sp)
    800022d4:	e44e                	sd	s3,8(sp)
    800022d6:	1800                	addi	s0,sp,48
    800022d8:	89aa                	mv	s3,a0
    800022da:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800022dc:	00000097          	auipc	ra,0x0
    800022e0:	886080e7          	jalr	-1914(ra) # 80001b62 <myproc>
    800022e4:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	9b4080e7          	jalr	-1612(ra) # 80000c9a <acquire>
    release(lk);
    800022ee:	854a                	mv	a0,s2
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	a5e080e7          	jalr	-1442(ra) # 80000d4e <release>

    // Go to sleep.
    p->chan = chan;
    800022f8:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    800022fc:	4789                	li	a5,2
    800022fe:	cc9c                	sw	a5,24(s1)

    sched();
    80002300:	00000097          	auipc	ra,0x0
    80002304:	ec0080e7          	jalr	-320(ra) # 800021c0 <sched>

    // Tidy up.
    p->chan = 0;
    80002308:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    8000230c:	8526                	mv	a0,s1
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	a40080e7          	jalr	-1472(ra) # 80000d4e <release>
    acquire(lk);
    80002316:	854a                	mv	a0,s2
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	982080e7          	jalr	-1662(ra) # 80000c9a <acquire>
}
    80002320:	70a2                	ld	ra,40(sp)
    80002322:	7402                	ld	s0,32(sp)
    80002324:	64e2                	ld	s1,24(sp)
    80002326:	6942                	ld	s2,16(sp)
    80002328:	69a2                	ld	s3,8(sp)
    8000232a:	6145                	addi	sp,sp,48
    8000232c:	8082                	ret

000000008000232e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000232e:	7139                	addi	sp,sp,-64
    80002330:	fc06                	sd	ra,56(sp)
    80002332:	f822                	sd	s0,48(sp)
    80002334:	f426                	sd	s1,40(sp)
    80002336:	f04a                	sd	s2,32(sp)
    80002338:	ec4e                	sd	s3,24(sp)
    8000233a:	e852                	sd	s4,16(sp)
    8000233c:	e456                	sd	s5,8(sp)
    8000233e:	0080                	addi	s0,sp,64
    80002340:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002342:	0000f497          	auipc	s1,0xf
    80002346:	dbe48493          	addi	s1,s1,-578 # 80011100 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    8000234a:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    8000234c:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    8000234e:	00014917          	auipc	s2,0x14
    80002352:	7b290913          	addi	s2,s2,1970 # 80016b00 <tickslock>
    80002356:	a811                	j	8000236a <wakeup+0x3c>
            }
            release(&p->lock);
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	9f4080e7          	jalr	-1548(ra) # 80000d4e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002362:	16848493          	addi	s1,s1,360
    80002366:	03248663          	beq	s1,s2,80002392 <wakeup+0x64>
        if (p != myproc())
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	7f8080e7          	jalr	2040(ra) # 80001b62 <myproc>
    80002372:	fea488e3          	beq	s1,a0,80002362 <wakeup+0x34>
            acquire(&p->lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	922080e7          	jalr	-1758(ra) # 80000c9a <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    80002380:	4c9c                	lw	a5,24(s1)
    80002382:	fd379be3          	bne	a5,s3,80002358 <wakeup+0x2a>
    80002386:	709c                	ld	a5,32(s1)
    80002388:	fd4798e3          	bne	a5,s4,80002358 <wakeup+0x2a>
                p->state = RUNNABLE;
    8000238c:	0154ac23          	sw	s5,24(s1)
    80002390:	b7e1                	j	80002358 <wakeup+0x2a>
        }
    }
}
    80002392:	70e2                	ld	ra,56(sp)
    80002394:	7442                	ld	s0,48(sp)
    80002396:	74a2                	ld	s1,40(sp)
    80002398:	7902                	ld	s2,32(sp)
    8000239a:	69e2                	ld	s3,24(sp)
    8000239c:	6a42                	ld	s4,16(sp)
    8000239e:	6aa2                	ld	s5,8(sp)
    800023a0:	6121                	addi	sp,sp,64
    800023a2:	8082                	ret

00000000800023a4 <reparent>:
{
    800023a4:	7179                	addi	sp,sp,-48
    800023a6:	f406                	sd	ra,40(sp)
    800023a8:	f022                	sd	s0,32(sp)
    800023aa:	ec26                	sd	s1,24(sp)
    800023ac:	e84a                	sd	s2,16(sp)
    800023ae:	e44e                	sd	s3,8(sp)
    800023b0:	e052                	sd	s4,0(sp)
    800023b2:	1800                	addi	s0,sp,48
    800023b4:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023b6:	0000f497          	auipc	s1,0xf
    800023ba:	d4a48493          	addi	s1,s1,-694 # 80011100 <proc>
            pp->parent = initproc;
    800023be:	00006a17          	auipc	s4,0x6
    800023c2:	69aa0a13          	addi	s4,s4,1690 # 80008a58 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023c6:	00014997          	auipc	s3,0x14
    800023ca:	73a98993          	addi	s3,s3,1850 # 80016b00 <tickslock>
    800023ce:	a029                	j	800023d8 <reparent+0x34>
    800023d0:	16848493          	addi	s1,s1,360
    800023d4:	01348d63          	beq	s1,s3,800023ee <reparent+0x4a>
        if (pp->parent == p)
    800023d8:	7c9c                	ld	a5,56(s1)
    800023da:	ff279be3          	bne	a5,s2,800023d0 <reparent+0x2c>
            pp->parent = initproc;
    800023de:	000a3503          	ld	a0,0(s4)
    800023e2:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    800023e4:	00000097          	auipc	ra,0x0
    800023e8:	f4a080e7          	jalr	-182(ra) # 8000232e <wakeup>
    800023ec:	b7d5                	j	800023d0 <reparent+0x2c>
}
    800023ee:	70a2                	ld	ra,40(sp)
    800023f0:	7402                	ld	s0,32(sp)
    800023f2:	64e2                	ld	s1,24(sp)
    800023f4:	6942                	ld	s2,16(sp)
    800023f6:	69a2                	ld	s3,8(sp)
    800023f8:	6a02                	ld	s4,0(sp)
    800023fa:	6145                	addi	sp,sp,48
    800023fc:	8082                	ret

00000000800023fe <exit>:
{
    800023fe:	7179                	addi	sp,sp,-48
    80002400:	f406                	sd	ra,40(sp)
    80002402:	f022                	sd	s0,32(sp)
    80002404:	ec26                	sd	s1,24(sp)
    80002406:	e84a                	sd	s2,16(sp)
    80002408:	e44e                	sd	s3,8(sp)
    8000240a:	e052                	sd	s4,0(sp)
    8000240c:	1800                	addi	s0,sp,48
    8000240e:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	752080e7          	jalr	1874(ra) # 80001b62 <myproc>
    80002418:	89aa                	mv	s3,a0
    if (p == initproc)
    8000241a:	00006797          	auipc	a5,0x6
    8000241e:	63e7b783          	ld	a5,1598(a5) # 80008a58 <initproc>
    80002422:	0d050493          	addi	s1,a0,208
    80002426:	15050913          	addi	s2,a0,336
    8000242a:	02a79363          	bne	a5,a0,80002450 <exit+0x52>
        panic("init exiting");
    8000242e:	00006517          	auipc	a0,0x6
    80002432:	e7250513          	addi	a0,a0,-398 # 800082a0 <digits+0x250>
    80002436:	ffffe097          	auipc	ra,0xffffe
    8000243a:	106080e7          	jalr	262(ra) # 8000053c <panic>
            fileclose(f);
    8000243e:	00002097          	auipc	ra,0x2
    80002442:	56c080e7          	jalr	1388(ra) # 800049aa <fileclose>
            p->ofile[fd] = 0;
    80002446:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    8000244a:	04a1                	addi	s1,s1,8
    8000244c:	01248563          	beq	s1,s2,80002456 <exit+0x58>
        if (p->ofile[fd])
    80002450:	6088                	ld	a0,0(s1)
    80002452:	f575                	bnez	a0,8000243e <exit+0x40>
    80002454:	bfdd                	j	8000244a <exit+0x4c>
    begin_op();
    80002456:	00002097          	auipc	ra,0x2
    8000245a:	090080e7          	jalr	144(ra) # 800044e6 <begin_op>
    iput(p->cwd);
    8000245e:	1509b503          	ld	a0,336(s3)
    80002462:	00002097          	auipc	ra,0x2
    80002466:	898080e7          	jalr	-1896(ra) # 80003cfa <iput>
    end_op();
    8000246a:	00002097          	auipc	ra,0x2
    8000246e:	0f6080e7          	jalr	246(ra) # 80004560 <end_op>
    p->cwd = 0;
    80002472:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    80002476:	0000f497          	auipc	s1,0xf
    8000247a:	c7248493          	addi	s1,s1,-910 # 800110e8 <wait_lock>
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	81a080e7          	jalr	-2022(ra) # 80000c9a <acquire>
    reparent(p);
    80002488:	854e                	mv	a0,s3
    8000248a:	00000097          	auipc	ra,0x0
    8000248e:	f1a080e7          	jalr	-230(ra) # 800023a4 <reparent>
    wakeup(p->parent);
    80002492:	0389b503          	ld	a0,56(s3)
    80002496:	00000097          	auipc	ra,0x0
    8000249a:	e98080e7          	jalr	-360(ra) # 8000232e <wakeup>
    acquire(&p->lock);
    8000249e:	854e                	mv	a0,s3
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	7fa080e7          	jalr	2042(ra) # 80000c9a <acquire>
    p->xstate = status;
    800024a8:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800024ac:	4795                	li	a5,5
    800024ae:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	89a080e7          	jalr	-1894(ra) # 80000d4e <release>
    sched();
    800024bc:	00000097          	auipc	ra,0x0
    800024c0:	d04080e7          	jalr	-764(ra) # 800021c0 <sched>
    panic("zombie exit");
    800024c4:	00006517          	auipc	a0,0x6
    800024c8:	dec50513          	addi	a0,a0,-532 # 800082b0 <digits+0x260>
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	070080e7          	jalr	112(ra) # 8000053c <panic>

00000000800024d4 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800024d4:	7179                	addi	sp,sp,-48
    800024d6:	f406                	sd	ra,40(sp)
    800024d8:	f022                	sd	s0,32(sp)
    800024da:	ec26                	sd	s1,24(sp)
    800024dc:	e84a                	sd	s2,16(sp)
    800024de:	e44e                	sd	s3,8(sp)
    800024e0:	1800                	addi	s0,sp,48
    800024e2:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800024e4:	0000f497          	auipc	s1,0xf
    800024e8:	c1c48493          	addi	s1,s1,-996 # 80011100 <proc>
    800024ec:	00014997          	auipc	s3,0x14
    800024f0:	61498993          	addi	s3,s3,1556 # 80016b00 <tickslock>
    {
        acquire(&p->lock);
    800024f4:	8526                	mv	a0,s1
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	7a4080e7          	jalr	1956(ra) # 80000c9a <acquire>
        if (p->pid == pid)
    800024fe:	589c                	lw	a5,48(s1)
    80002500:	01278d63          	beq	a5,s2,8000251a <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    80002504:	8526                	mv	a0,s1
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	848080e7          	jalr	-1976(ra) # 80000d4e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000250e:	16848493          	addi	s1,s1,360
    80002512:	ff3491e3          	bne	s1,s3,800024f4 <kill+0x20>
    }
    return -1;
    80002516:	557d                	li	a0,-1
    80002518:	a829                	j	80002532 <kill+0x5e>
            p->killed = 1;
    8000251a:	4785                	li	a5,1
    8000251c:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    8000251e:	4c98                	lw	a4,24(s1)
    80002520:	4789                	li	a5,2
    80002522:	00f70f63          	beq	a4,a5,80002540 <kill+0x6c>
            release(&p->lock);
    80002526:	8526                	mv	a0,s1
    80002528:	fffff097          	auipc	ra,0xfffff
    8000252c:	826080e7          	jalr	-2010(ra) # 80000d4e <release>
            return 0;
    80002530:	4501                	li	a0,0
}
    80002532:	70a2                	ld	ra,40(sp)
    80002534:	7402                	ld	s0,32(sp)
    80002536:	64e2                	ld	s1,24(sp)
    80002538:	6942                	ld	s2,16(sp)
    8000253a:	69a2                	ld	s3,8(sp)
    8000253c:	6145                	addi	sp,sp,48
    8000253e:	8082                	ret
                p->state = RUNNABLE;
    80002540:	478d                	li	a5,3
    80002542:	cc9c                	sw	a5,24(s1)
    80002544:	b7cd                	j	80002526 <kill+0x52>

0000000080002546 <setkilled>:

void setkilled(struct proc *p)
{
    80002546:	1101                	addi	sp,sp,-32
    80002548:	ec06                	sd	ra,24(sp)
    8000254a:	e822                	sd	s0,16(sp)
    8000254c:	e426                	sd	s1,8(sp)
    8000254e:	1000                	addi	s0,sp,32
    80002550:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	748080e7          	jalr	1864(ra) # 80000c9a <acquire>
    p->killed = 1;
    8000255a:	4785                	li	a5,1
    8000255c:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    8000255e:	8526                	mv	a0,s1
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	7ee080e7          	jalr	2030(ra) # 80000d4e <release>
}
    80002568:	60e2                	ld	ra,24(sp)
    8000256a:	6442                	ld	s0,16(sp)
    8000256c:	64a2                	ld	s1,8(sp)
    8000256e:	6105                	addi	sp,sp,32
    80002570:	8082                	ret

0000000080002572 <killed>:

int killed(struct proc *p)
{
    80002572:	1101                	addi	sp,sp,-32
    80002574:	ec06                	sd	ra,24(sp)
    80002576:	e822                	sd	s0,16(sp)
    80002578:	e426                	sd	s1,8(sp)
    8000257a:	e04a                	sd	s2,0(sp)
    8000257c:	1000                	addi	s0,sp,32
    8000257e:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	71a080e7          	jalr	1818(ra) # 80000c9a <acquire>
    k = p->killed;
    80002588:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    8000258c:	8526                	mv	a0,s1
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	7c0080e7          	jalr	1984(ra) # 80000d4e <release>
    return k;
}
    80002596:	854a                	mv	a0,s2
    80002598:	60e2                	ld	ra,24(sp)
    8000259a:	6442                	ld	s0,16(sp)
    8000259c:	64a2                	ld	s1,8(sp)
    8000259e:	6902                	ld	s2,0(sp)
    800025a0:	6105                	addi	sp,sp,32
    800025a2:	8082                	ret

00000000800025a4 <wait>:
{
    800025a4:	715d                	addi	sp,sp,-80
    800025a6:	e486                	sd	ra,72(sp)
    800025a8:	e0a2                	sd	s0,64(sp)
    800025aa:	fc26                	sd	s1,56(sp)
    800025ac:	f84a                	sd	s2,48(sp)
    800025ae:	f44e                	sd	s3,40(sp)
    800025b0:	f052                	sd	s4,32(sp)
    800025b2:	ec56                	sd	s5,24(sp)
    800025b4:	e85a                	sd	s6,16(sp)
    800025b6:	e45e                	sd	s7,8(sp)
    800025b8:	e062                	sd	s8,0(sp)
    800025ba:	0880                	addi	s0,sp,80
    800025bc:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800025be:	fffff097          	auipc	ra,0xfffff
    800025c2:	5a4080e7          	jalr	1444(ra) # 80001b62 <myproc>
    800025c6:	892a                	mv	s2,a0
    acquire(&wait_lock);
    800025c8:	0000f517          	auipc	a0,0xf
    800025cc:	b2050513          	addi	a0,a0,-1248 # 800110e8 <wait_lock>
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	6ca080e7          	jalr	1738(ra) # 80000c9a <acquire>
        havekids = 0;
    800025d8:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    800025da:	4a15                	li	s4,5
                havekids = 1;
    800025dc:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800025de:	00014997          	auipc	s3,0x14
    800025e2:	52298993          	addi	s3,s3,1314 # 80016b00 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800025e6:	0000fc17          	auipc	s8,0xf
    800025ea:	b02c0c13          	addi	s8,s8,-1278 # 800110e8 <wait_lock>
    800025ee:	a0d1                	j	800026b2 <wait+0x10e>
                    pid = pp->pid;
    800025f0:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800025f4:	000b0e63          	beqz	s6,80002610 <wait+0x6c>
    800025f8:	4691                	li	a3,4
    800025fa:	02c48613          	addi	a2,s1,44
    800025fe:	85da                	mv	a1,s6
    80002600:	05093503          	ld	a0,80(s2)
    80002604:	fffff097          	auipc	ra,0xfffff
    80002608:	12a080e7          	jalr	298(ra) # 8000172e <copyout>
    8000260c:	04054163          	bltz	a0,8000264e <wait+0xaa>
                    freeproc(pp);
    80002610:	8526                	mv	a0,s1
    80002612:	fffff097          	auipc	ra,0xfffff
    80002616:	702080e7          	jalr	1794(ra) # 80001d14 <freeproc>
                    release(&pp->lock);
    8000261a:	8526                	mv	a0,s1
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	732080e7          	jalr	1842(ra) # 80000d4e <release>
                    release(&wait_lock);
    80002624:	0000f517          	auipc	a0,0xf
    80002628:	ac450513          	addi	a0,a0,-1340 # 800110e8 <wait_lock>
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	722080e7          	jalr	1826(ra) # 80000d4e <release>
}
    80002634:	854e                	mv	a0,s3
    80002636:	60a6                	ld	ra,72(sp)
    80002638:	6406                	ld	s0,64(sp)
    8000263a:	74e2                	ld	s1,56(sp)
    8000263c:	7942                	ld	s2,48(sp)
    8000263e:	79a2                	ld	s3,40(sp)
    80002640:	7a02                	ld	s4,32(sp)
    80002642:	6ae2                	ld	s5,24(sp)
    80002644:	6b42                	ld	s6,16(sp)
    80002646:	6ba2                	ld	s7,8(sp)
    80002648:	6c02                	ld	s8,0(sp)
    8000264a:	6161                	addi	sp,sp,80
    8000264c:	8082                	ret
                        release(&pp->lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	6fe080e7          	jalr	1790(ra) # 80000d4e <release>
                        release(&wait_lock);
    80002658:	0000f517          	auipc	a0,0xf
    8000265c:	a9050513          	addi	a0,a0,-1392 # 800110e8 <wait_lock>
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	6ee080e7          	jalr	1774(ra) # 80000d4e <release>
                        return -1;
    80002668:	59fd                	li	s3,-1
    8000266a:	b7e9                	j	80002634 <wait+0x90>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    8000266c:	16848493          	addi	s1,s1,360
    80002670:	03348463          	beq	s1,s3,80002698 <wait+0xf4>
            if (pp->parent == p)
    80002674:	7c9c                	ld	a5,56(s1)
    80002676:	ff279be3          	bne	a5,s2,8000266c <wait+0xc8>
                acquire(&pp->lock);
    8000267a:	8526                	mv	a0,s1
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	61e080e7          	jalr	1566(ra) # 80000c9a <acquire>
                if (pp->state == ZOMBIE)
    80002684:	4c9c                	lw	a5,24(s1)
    80002686:	f74785e3          	beq	a5,s4,800025f0 <wait+0x4c>
                release(&pp->lock);
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	6c2080e7          	jalr	1730(ra) # 80000d4e <release>
                havekids = 1;
    80002694:	8756                	mv	a4,s5
    80002696:	bfd9                	j	8000266c <wait+0xc8>
        if (!havekids || killed(p))
    80002698:	c31d                	beqz	a4,800026be <wait+0x11a>
    8000269a:	854a                	mv	a0,s2
    8000269c:	00000097          	auipc	ra,0x0
    800026a0:	ed6080e7          	jalr	-298(ra) # 80002572 <killed>
    800026a4:	ed09                	bnez	a0,800026be <wait+0x11a>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800026a6:	85e2                	mv	a1,s8
    800026a8:	854a                	mv	a0,s2
    800026aa:	00000097          	auipc	ra,0x0
    800026ae:	c20080e7          	jalr	-992(ra) # 800022ca <sleep>
        havekids = 0;
    800026b2:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026b4:	0000f497          	auipc	s1,0xf
    800026b8:	a4c48493          	addi	s1,s1,-1460 # 80011100 <proc>
    800026bc:	bf65                	j	80002674 <wait+0xd0>
            release(&wait_lock);
    800026be:	0000f517          	auipc	a0,0xf
    800026c2:	a2a50513          	addi	a0,a0,-1494 # 800110e8 <wait_lock>
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	688080e7          	jalr	1672(ra) # 80000d4e <release>
            return -1;
    800026ce:	59fd                	li	s3,-1
    800026d0:	b795                	j	80002634 <wait+0x90>

00000000800026d2 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026d2:	7179                	addi	sp,sp,-48
    800026d4:	f406                	sd	ra,40(sp)
    800026d6:	f022                	sd	s0,32(sp)
    800026d8:	ec26                	sd	s1,24(sp)
    800026da:	e84a                	sd	s2,16(sp)
    800026dc:	e44e                	sd	s3,8(sp)
    800026de:	e052                	sd	s4,0(sp)
    800026e0:	1800                	addi	s0,sp,48
    800026e2:	84aa                	mv	s1,a0
    800026e4:	892e                	mv	s2,a1
    800026e6:	89b2                	mv	s3,a2
    800026e8:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800026ea:	fffff097          	auipc	ra,0xfffff
    800026ee:	478080e7          	jalr	1144(ra) # 80001b62 <myproc>
    if (user_dst)
    800026f2:	c08d                	beqz	s1,80002714 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    800026f4:	86d2                	mv	a3,s4
    800026f6:	864e                	mv	a2,s3
    800026f8:	85ca                	mv	a1,s2
    800026fa:	6928                	ld	a0,80(a0)
    800026fc:	fffff097          	auipc	ra,0xfffff
    80002700:	032080e7          	jalr	50(ra) # 8000172e <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    80002704:	70a2                	ld	ra,40(sp)
    80002706:	7402                	ld	s0,32(sp)
    80002708:	64e2                	ld	s1,24(sp)
    8000270a:	6942                	ld	s2,16(sp)
    8000270c:	69a2                	ld	s3,8(sp)
    8000270e:	6a02                	ld	s4,0(sp)
    80002710:	6145                	addi	sp,sp,48
    80002712:	8082                	ret
        memmove((char *)dst, src, len);
    80002714:	000a061b          	sext.w	a2,s4
    80002718:	85ce                	mv	a1,s3
    8000271a:	854a                	mv	a0,s2
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	6d6080e7          	jalr	1750(ra) # 80000df2 <memmove>
        return 0;
    80002724:	8526                	mv	a0,s1
    80002726:	bff9                	j	80002704 <either_copyout+0x32>

0000000080002728 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002728:	7179                	addi	sp,sp,-48
    8000272a:	f406                	sd	ra,40(sp)
    8000272c:	f022                	sd	s0,32(sp)
    8000272e:	ec26                	sd	s1,24(sp)
    80002730:	e84a                	sd	s2,16(sp)
    80002732:	e44e                	sd	s3,8(sp)
    80002734:	e052                	sd	s4,0(sp)
    80002736:	1800                	addi	s0,sp,48
    80002738:	892a                	mv	s2,a0
    8000273a:	84ae                	mv	s1,a1
    8000273c:	89b2                	mv	s3,a2
    8000273e:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002740:	fffff097          	auipc	ra,0xfffff
    80002744:	422080e7          	jalr	1058(ra) # 80001b62 <myproc>
    if (user_src)
    80002748:	c08d                	beqz	s1,8000276a <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    8000274a:	86d2                	mv	a3,s4
    8000274c:	864e                	mv	a2,s3
    8000274e:	85ca                	mv	a1,s2
    80002750:	6928                	ld	a0,80(a0)
    80002752:	fffff097          	auipc	ra,0xfffff
    80002756:	068080e7          	jalr	104(ra) # 800017ba <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    8000275a:	70a2                	ld	ra,40(sp)
    8000275c:	7402                	ld	s0,32(sp)
    8000275e:	64e2                	ld	s1,24(sp)
    80002760:	6942                	ld	s2,16(sp)
    80002762:	69a2                	ld	s3,8(sp)
    80002764:	6a02                	ld	s4,0(sp)
    80002766:	6145                	addi	sp,sp,48
    80002768:	8082                	ret
        memmove(dst, (char *)src, len);
    8000276a:	000a061b          	sext.w	a2,s4
    8000276e:	85ce                	mv	a1,s3
    80002770:	854a                	mv	a0,s2
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	680080e7          	jalr	1664(ra) # 80000df2 <memmove>
        return 0;
    8000277a:	8526                	mv	a0,s1
    8000277c:	bff9                	j	8000275a <either_copyin+0x32>

000000008000277e <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000277e:	715d                	addi	sp,sp,-80
    80002780:	e486                	sd	ra,72(sp)
    80002782:	e0a2                	sd	s0,64(sp)
    80002784:	fc26                	sd	s1,56(sp)
    80002786:	f84a                	sd	s2,48(sp)
    80002788:	f44e                	sd	s3,40(sp)
    8000278a:	f052                	sd	s4,32(sp)
    8000278c:	ec56                	sd	s5,24(sp)
    8000278e:	e85a                	sd	s6,16(sp)
    80002790:	e45e                	sd	s7,8(sp)
    80002792:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    80002794:	00006517          	auipc	a0,0x6
    80002798:	8f450513          	addi	a0,a0,-1804 # 80008088 <digits+0x38>
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	dfc080e7          	jalr	-516(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800027a4:	0000f497          	auipc	s1,0xf
    800027a8:	ab448493          	addi	s1,s1,-1356 # 80011258 <proc+0x158>
    800027ac:	00014917          	auipc	s2,0x14
    800027b0:	4ac90913          	addi	s2,s2,1196 # 80016c58 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027b4:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800027b6:	00006997          	auipc	s3,0x6
    800027ba:	b0a98993          	addi	s3,s3,-1270 # 800082c0 <digits+0x270>
        printf("%d <%s %s", p->pid, state, p->name);
    800027be:	00006a97          	auipc	s5,0x6
    800027c2:	b0aa8a93          	addi	s5,s5,-1270 # 800082c8 <digits+0x278>
        printf("\n");
    800027c6:	00006a17          	auipc	s4,0x6
    800027ca:	8c2a0a13          	addi	s4,s4,-1854 # 80008088 <digits+0x38>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ce:	00006b97          	auipc	s7,0x6
    800027d2:	c0ab8b93          	addi	s7,s7,-1014 # 800083d8 <states.0>
    800027d6:	a00d                	j	800027f8 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    800027d8:	ed86a583          	lw	a1,-296(a3)
    800027dc:	8556                	mv	a0,s5
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	dba080e7          	jalr	-582(ra) # 80000598 <printf>
        printf("\n");
    800027e6:	8552                	mv	a0,s4
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	db0080e7          	jalr	-592(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800027f0:	16848493          	addi	s1,s1,360
    800027f4:	03248263          	beq	s1,s2,80002818 <procdump+0x9a>
        if (p->state == UNUSED)
    800027f8:	86a6                	mv	a3,s1
    800027fa:	ec04a783          	lw	a5,-320(s1)
    800027fe:	dbed                	beqz	a5,800027f0 <procdump+0x72>
            state = "???";
    80002800:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002802:	fcfb6be3          	bltu	s6,a5,800027d8 <procdump+0x5a>
    80002806:	02079713          	slli	a4,a5,0x20
    8000280a:	01d75793          	srli	a5,a4,0x1d
    8000280e:	97de                	add	a5,a5,s7
    80002810:	6390                	ld	a2,0(a5)
    80002812:	f279                	bnez	a2,800027d8 <procdump+0x5a>
            state = "???";
    80002814:	864e                	mv	a2,s3
    80002816:	b7c9                	j	800027d8 <procdump+0x5a>
    }
}
    80002818:	60a6                	ld	ra,72(sp)
    8000281a:	6406                	ld	s0,64(sp)
    8000281c:	74e2                	ld	s1,56(sp)
    8000281e:	7942                	ld	s2,48(sp)
    80002820:	79a2                	ld	s3,40(sp)
    80002822:	7a02                	ld	s4,32(sp)
    80002824:	6ae2                	ld	s5,24(sp)
    80002826:	6b42                	ld	s6,16(sp)
    80002828:	6ba2                	ld	s7,8(sp)
    8000282a:	6161                	addi	sp,sp,80
    8000282c:	8082                	ret

000000008000282e <schedls>:

void schedls()
{
    8000282e:	1141                	addi	sp,sp,-16
    80002830:	e406                	sd	ra,8(sp)
    80002832:	e022                	sd	s0,0(sp)
    80002834:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    80002836:	00006517          	auipc	a0,0x6
    8000283a:	aa250513          	addi	a0,a0,-1374 # 800082d8 <digits+0x288>
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	d5a080e7          	jalr	-678(ra) # 80000598 <printf>
    printf("====================================\n");
    80002846:	00006517          	auipc	a0,0x6
    8000284a:	aba50513          	addi	a0,a0,-1350 # 80008300 <digits+0x2b0>
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	d4a080e7          	jalr	-694(ra) # 80000598 <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    80002856:	00006717          	auipc	a4,0x6
    8000285a:	19273703          	ld	a4,402(a4) # 800089e8 <available_schedulers+0x10>
    8000285e:	00006797          	auipc	a5,0x6
    80002862:	12a7b783          	ld	a5,298(a5) # 80008988 <sched_pointer>
    80002866:	04f70663          	beq	a4,a5,800028b2 <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    8000286a:	00006517          	auipc	a0,0x6
    8000286e:	ac650513          	addi	a0,a0,-1338 # 80008330 <digits+0x2e0>
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	d26080e7          	jalr	-730(ra) # 80000598 <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    8000287a:	00006617          	auipc	a2,0x6
    8000287e:	17662603          	lw	a2,374(a2) # 800089f0 <available_schedulers+0x18>
    80002882:	00006597          	auipc	a1,0x6
    80002886:	15658593          	addi	a1,a1,342 # 800089d8 <available_schedulers>
    8000288a:	00006517          	auipc	a0,0x6
    8000288e:	aae50513          	addi	a0,a0,-1362 # 80008338 <digits+0x2e8>
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	d06080e7          	jalr	-762(ra) # 80000598 <printf>
    }
    printf("\n*: current scheduler\n\n");
    8000289a:	00006517          	auipc	a0,0x6
    8000289e:	aa650513          	addi	a0,a0,-1370 # 80008340 <digits+0x2f0>
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	cf6080e7          	jalr	-778(ra) # 80000598 <printf>
}
    800028aa:	60a2                	ld	ra,8(sp)
    800028ac:	6402                	ld	s0,0(sp)
    800028ae:	0141                	addi	sp,sp,16
    800028b0:	8082                	ret
            printf("[*]\t");
    800028b2:	00006517          	auipc	a0,0x6
    800028b6:	a7650513          	addi	a0,a0,-1418 # 80008328 <digits+0x2d8>
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	cde080e7          	jalr	-802(ra) # 80000598 <printf>
    800028c2:	bf65                	j	8000287a <schedls+0x4c>

00000000800028c4 <schedset>:

void schedset(int id)
{
    800028c4:	1141                	addi	sp,sp,-16
    800028c6:	e406                	sd	ra,8(sp)
    800028c8:	e022                	sd	s0,0(sp)
    800028ca:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    800028cc:	e90d                	bnez	a0,800028fe <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    800028ce:	00006797          	auipc	a5,0x6
    800028d2:	11a7b783          	ld	a5,282(a5) # 800089e8 <available_schedulers+0x10>
    800028d6:	00006717          	auipc	a4,0x6
    800028da:	0af73923          	sd	a5,178(a4) # 80008988 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    800028de:	00006597          	auipc	a1,0x6
    800028e2:	0fa58593          	addi	a1,a1,250 # 800089d8 <available_schedulers>
    800028e6:	00006517          	auipc	a0,0x6
    800028ea:	a9a50513          	addi	a0,a0,-1382 # 80008380 <digits+0x330>
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	caa080e7          	jalr	-854(ra) # 80000598 <printf>
}
    800028f6:	60a2                	ld	ra,8(sp)
    800028f8:	6402                	ld	s0,0(sp)
    800028fa:	0141                	addi	sp,sp,16
    800028fc:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    800028fe:	00006517          	auipc	a0,0x6
    80002902:	a5a50513          	addi	a0,a0,-1446 # 80008358 <digits+0x308>
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	c92080e7          	jalr	-878(ra) # 80000598 <printf>
        return;
    8000290e:	b7e5                	j	800028f6 <schedset+0x32>

0000000080002910 <find_proc>:

struct proc *find_proc(int pid)
{
    80002910:	7179                	addi	sp,sp,-48
    80002912:	f406                	sd	ra,40(sp)
    80002914:	f022                	sd	s0,32(sp)
    80002916:	ec26                	sd	s1,24(sp)
    80002918:	e84a                	sd	s2,16(sp)
    8000291a:	e44e                	sd	s3,8(sp)
    8000291c:	1800                	addi	s0,sp,48
    8000291e:	892a                	mv	s2,a0
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++)
    80002920:	0000e497          	auipc	s1,0xe
    80002924:	7e048493          	addi	s1,s1,2016 # 80011100 <proc>
    80002928:	00014997          	auipc	s3,0x14
    8000292c:	1d898993          	addi	s3,s3,472 # 80016b00 <tickslock>
    {
        acquire(&p->lock);
    80002930:	8526                	mv	a0,s1
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	368080e7          	jalr	872(ra) # 80000c9a <acquire>
        if (p->pid == pid)
    8000293a:	589c                	lw	a5,48(s1)
    8000293c:	01278d63          	beq	a5,s2,80002956 <find_proc+0x46>
        {
            release(&p->lock);
            return p;
        }
        release(&p->lock);
    80002940:	8526                	mv	a0,s1
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	40c080e7          	jalr	1036(ra) # 80000d4e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000294a:	16848493          	addi	s1,s1,360
    8000294e:	ff3491e3          	bne	s1,s3,80002930 <find_proc+0x20>
    }
    return 0;
    80002952:	4481                	li	s1,0
    80002954:	a031                	j	80002960 <find_proc+0x50>
            release(&p->lock);
    80002956:	8526                	mv	a0,s1
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	3f6080e7          	jalr	1014(ra) # 80000d4e <release>
}
    80002960:	8526                	mv	a0,s1
    80002962:	70a2                	ld	ra,40(sp)
    80002964:	7402                	ld	s0,32(sp)
    80002966:	64e2                	ld	s1,24(sp)
    80002968:	6942                	ld	s2,16(sp)
    8000296a:	69a2                	ld	s3,8(sp)
    8000296c:	6145                	addi	sp,sp,48
    8000296e:	8082                	ret

0000000080002970 <va2pa>:

uint64 va2pa(uint64 va, int pid)
{
    80002970:	1101                	addi	sp,sp,-32
    80002972:	ec06                	sd	ra,24(sp)
    80002974:	e822                	sd	s0,16(sp)
    80002976:	e426                	sd	s1,8(sp)
    80002978:	e04a                	sd	s2,0(sp)
    8000297a:	1000                	addi	s0,sp,32
    8000297c:	84aa                	mv	s1,a0
    8000297e:	892e                	mv	s2,a1
    uint64 pa, offset;
    pagetable_t ptable = myproc()->pagetable;
    80002980:	fffff097          	auipc	ra,0xfffff
    80002984:	1e2080e7          	jalr	482(ra) # 80001b62 <myproc>
    80002988:	6928                	ld	a0,80(a0)
    if (pid != 0)
    8000298a:	00090963          	beqz	s2,8000299c <va2pa+0x2c>
    {
        struct proc *p = find_proc(pid);
    8000298e:	854a                	mv	a0,s2
    80002990:	00000097          	auipc	ra,0x0
    80002994:	f80080e7          	jalr	-128(ra) # 80002910 <find_proc>
        if (p == 0)
    80002998:	c90d                	beqz	a0,800029ca <va2pa+0x5a>
        {
            return 0;
        }
        ptable = p->pagetable;
    8000299a:	6928                	ld	a0,80(a0)
    }
    pte_t *pte = walk(ptable, va, 0);
    8000299c:	4601                	li	a2,0
    8000299e:	85a6                	mv	a1,s1
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	6d8080e7          	jalr	1752(ra) # 80001078 <walk>
    if (pte == 0)
    800029a8:	c11d                	beqz	a0,800029ce <va2pa+0x5e>
    {
        return 0;
    }
    if ((*pte & PTE_V) == 0)
    800029aa:	611c                	ld	a5,0(a0)
    800029ac:	0017f513          	andi	a0,a5,1
    800029b0:	c519                	beqz	a0,800029be <va2pa+0x4e>
    {
        return 0;
    }
    offset = va % PGSIZE;
    pa = PTE2PA(*pte);
    800029b2:	83a9                	srli	a5,a5,0xa
    800029b4:	07b2                	slli	a5,a5,0xc
    offset = va % PGSIZE;
    800029b6:	14d2                	slli	s1,s1,0x34
    800029b8:	90d1                	srli	s1,s1,0x34
    return pa + offset;
    800029ba:	00978533          	add	a0,a5,s1
    800029be:	60e2                	ld	ra,24(sp)
    800029c0:	6442                	ld	s0,16(sp)
    800029c2:	64a2                	ld	s1,8(sp)
    800029c4:	6902                	ld	s2,0(sp)
    800029c6:	6105                	addi	sp,sp,32
    800029c8:	8082                	ret
            return 0;
    800029ca:	4501                	li	a0,0
    800029cc:	bfcd                	j	800029be <va2pa+0x4e>
        return 0;
    800029ce:	4501                	li	a0,0
    800029d0:	b7fd                	j	800029be <va2pa+0x4e>

00000000800029d2 <swtch>:
    800029d2:	00153023          	sd	ra,0(a0)
    800029d6:	00253423          	sd	sp,8(a0)
    800029da:	e900                	sd	s0,16(a0)
    800029dc:	ed04                	sd	s1,24(a0)
    800029de:	03253023          	sd	s2,32(a0)
    800029e2:	03353423          	sd	s3,40(a0)
    800029e6:	03453823          	sd	s4,48(a0)
    800029ea:	03553c23          	sd	s5,56(a0)
    800029ee:	05653023          	sd	s6,64(a0)
    800029f2:	05753423          	sd	s7,72(a0)
    800029f6:	05853823          	sd	s8,80(a0)
    800029fa:	05953c23          	sd	s9,88(a0)
    800029fe:	07a53023          	sd	s10,96(a0)
    80002a02:	07b53423          	sd	s11,104(a0)
    80002a06:	0005b083          	ld	ra,0(a1)
    80002a0a:	0085b103          	ld	sp,8(a1)
    80002a0e:	6980                	ld	s0,16(a1)
    80002a10:	6d84                	ld	s1,24(a1)
    80002a12:	0205b903          	ld	s2,32(a1)
    80002a16:	0285b983          	ld	s3,40(a1)
    80002a1a:	0305ba03          	ld	s4,48(a1)
    80002a1e:	0385ba83          	ld	s5,56(a1)
    80002a22:	0405bb03          	ld	s6,64(a1)
    80002a26:	0485bb83          	ld	s7,72(a1)
    80002a2a:	0505bc03          	ld	s8,80(a1)
    80002a2e:	0585bc83          	ld	s9,88(a1)
    80002a32:	0605bd03          	ld	s10,96(a1)
    80002a36:	0685bd83          	ld	s11,104(a1)
    80002a3a:	8082                	ret

0000000080002a3c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a3c:	1141                	addi	sp,sp,-16
    80002a3e:	e406                	sd	ra,8(sp)
    80002a40:	e022                	sd	s0,0(sp)
    80002a42:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a44:	00006597          	auipc	a1,0x6
    80002a48:	9c458593          	addi	a1,a1,-1596 # 80008408 <states.0+0x30>
    80002a4c:	00014517          	auipc	a0,0x14
    80002a50:	0b450513          	addi	a0,a0,180 # 80016b00 <tickslock>
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	1b6080e7          	jalr	438(ra) # 80000c0a <initlock>
}
    80002a5c:	60a2                	ld	ra,8(sp)
    80002a5e:	6402                	ld	s0,0(sp)
    80002a60:	0141                	addi	sp,sp,16
    80002a62:	8082                	ret

0000000080002a64 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a64:	1141                	addi	sp,sp,-16
    80002a66:	e422                	sd	s0,8(sp)
    80002a68:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a6a:	00003797          	auipc	a5,0x3
    80002a6e:	56678793          	addi	a5,a5,1382 # 80005fd0 <kernelvec>
    80002a72:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a76:	6422                	ld	s0,8(sp)
    80002a78:	0141                	addi	sp,sp,16
    80002a7a:	8082                	ret

0000000080002a7c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a7c:	1141                	addi	sp,sp,-16
    80002a7e:	e406                	sd	ra,8(sp)
    80002a80:	e022                	sd	s0,0(sp)
    80002a82:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a84:	fffff097          	auipc	ra,0xfffff
    80002a88:	0de080e7          	jalr	222(ra) # 80001b62 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a8c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a90:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a92:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a96:	00004697          	auipc	a3,0x4
    80002a9a:	56a68693          	addi	a3,a3,1386 # 80007000 <_trampoline>
    80002a9e:	00004717          	auipc	a4,0x4
    80002aa2:	56270713          	addi	a4,a4,1378 # 80007000 <_trampoline>
    80002aa6:	8f15                	sub	a4,a4,a3
    80002aa8:	040007b7          	lui	a5,0x4000
    80002aac:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002aae:	07b2                	slli	a5,a5,0xc
    80002ab0:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ab2:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ab6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ab8:	18002673          	csrr	a2,satp
    80002abc:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002abe:	6d30                	ld	a2,88(a0)
    80002ac0:	6138                	ld	a4,64(a0)
    80002ac2:	6585                	lui	a1,0x1
    80002ac4:	972e                	add	a4,a4,a1
    80002ac6:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ac8:	6d38                	ld	a4,88(a0)
    80002aca:	00000617          	auipc	a2,0x0
    80002ace:	13460613          	addi	a2,a2,308 # 80002bfe <usertrap>
    80002ad2:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ad4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ad6:	8612                	mv	a2,tp
    80002ad8:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ada:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ade:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ae2:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ae6:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002aea:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002aec:	6f18                	ld	a4,24(a4)
    80002aee:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002af2:	6928                	ld	a0,80(a0)
    80002af4:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002af6:	00004717          	auipc	a4,0x4
    80002afa:	5a670713          	addi	a4,a4,1446 # 8000709c <userret>
    80002afe:	8f15                	sub	a4,a4,a3
    80002b00:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b02:	577d                	li	a4,-1
    80002b04:	177e                	slli	a4,a4,0x3f
    80002b06:	8d59                	or	a0,a0,a4
    80002b08:	9782                	jalr	a5
}
    80002b0a:	60a2                	ld	ra,8(sp)
    80002b0c:	6402                	ld	s0,0(sp)
    80002b0e:	0141                	addi	sp,sp,16
    80002b10:	8082                	ret

0000000080002b12 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b12:	1101                	addi	sp,sp,-32
    80002b14:	ec06                	sd	ra,24(sp)
    80002b16:	e822                	sd	s0,16(sp)
    80002b18:	e426                	sd	s1,8(sp)
    80002b1a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b1c:	00014497          	auipc	s1,0x14
    80002b20:	fe448493          	addi	s1,s1,-28 # 80016b00 <tickslock>
    80002b24:	8526                	mv	a0,s1
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	174080e7          	jalr	372(ra) # 80000c9a <acquire>
  ticks++;
    80002b2e:	00006517          	auipc	a0,0x6
    80002b32:	f3250513          	addi	a0,a0,-206 # 80008a60 <ticks>
    80002b36:	411c                	lw	a5,0(a0)
    80002b38:	2785                	addiw	a5,a5,1
    80002b3a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	7f2080e7          	jalr	2034(ra) # 8000232e <wakeup>
  release(&tickslock);
    80002b44:	8526                	mv	a0,s1
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	208080e7          	jalr	520(ra) # 80000d4e <release>
}
    80002b4e:	60e2                	ld	ra,24(sp)
    80002b50:	6442                	ld	s0,16(sp)
    80002b52:	64a2                	ld	s1,8(sp)
    80002b54:	6105                	addi	sp,sp,32
    80002b56:	8082                	ret

0000000080002b58 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b58:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b5c:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002b5e:	0807df63          	bgez	a5,80002bfc <devintr+0xa4>
{
    80002b62:	1101                	addi	sp,sp,-32
    80002b64:	ec06                	sd	ra,24(sp)
    80002b66:	e822                	sd	s0,16(sp)
    80002b68:	e426                	sd	s1,8(sp)
    80002b6a:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    80002b6c:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002b70:	46a5                	li	a3,9
    80002b72:	00d70d63          	beq	a4,a3,80002b8c <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002b76:	577d                	li	a4,-1
    80002b78:	177e                	slli	a4,a4,0x3f
    80002b7a:	0705                	addi	a4,a4,1
    return 0;
    80002b7c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b7e:	04e78e63          	beq	a5,a4,80002bda <devintr+0x82>
  }
}
    80002b82:	60e2                	ld	ra,24(sp)
    80002b84:	6442                	ld	s0,16(sp)
    80002b86:	64a2                	ld	s1,8(sp)
    80002b88:	6105                	addi	sp,sp,32
    80002b8a:	8082                	ret
    int irq = plic_claim();
    80002b8c:	00003097          	auipc	ra,0x3
    80002b90:	54c080e7          	jalr	1356(ra) # 800060d8 <plic_claim>
    80002b94:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b96:	47a9                	li	a5,10
    80002b98:	02f50763          	beq	a0,a5,80002bc6 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002b9c:	4785                	li	a5,1
    80002b9e:	02f50963          	beq	a0,a5,80002bd0 <devintr+0x78>
    return 1;
    80002ba2:	4505                	li	a0,1
    } else if(irq){
    80002ba4:	dcf9                	beqz	s1,80002b82 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ba6:	85a6                	mv	a1,s1
    80002ba8:	00006517          	auipc	a0,0x6
    80002bac:	86850513          	addi	a0,a0,-1944 # 80008410 <states.0+0x38>
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	9e8080e7          	jalr	-1560(ra) # 80000598 <printf>
      plic_complete(irq);
    80002bb8:	8526                	mv	a0,s1
    80002bba:	00003097          	auipc	ra,0x3
    80002bbe:	542080e7          	jalr	1346(ra) # 800060fc <plic_complete>
    return 1;
    80002bc2:	4505                	li	a0,1
    80002bc4:	bf7d                	j	80002b82 <devintr+0x2a>
      uartintr();
    80002bc6:	ffffe097          	auipc	ra,0xffffe
    80002bca:	de0080e7          	jalr	-544(ra) # 800009a6 <uartintr>
    if(irq)
    80002bce:	b7ed                	j	80002bb8 <devintr+0x60>
      virtio_disk_intr();
    80002bd0:	00004097          	auipc	ra,0x4
    80002bd4:	9f2080e7          	jalr	-1550(ra) # 800065c2 <virtio_disk_intr>
    if(irq)
    80002bd8:	b7c5                	j	80002bb8 <devintr+0x60>
    if(cpuid() == 0){
    80002bda:	fffff097          	auipc	ra,0xfffff
    80002bde:	f5c080e7          	jalr	-164(ra) # 80001b36 <cpuid>
    80002be2:	c901                	beqz	a0,80002bf2 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002be4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002be8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bea:	14479073          	csrw	sip,a5
    return 2;
    80002bee:	4509                	li	a0,2
    80002bf0:	bf49                	j	80002b82 <devintr+0x2a>
      clockintr();
    80002bf2:	00000097          	auipc	ra,0x0
    80002bf6:	f20080e7          	jalr	-224(ra) # 80002b12 <clockintr>
    80002bfa:	b7ed                	j	80002be4 <devintr+0x8c>
}
    80002bfc:	8082                	ret

0000000080002bfe <usertrap>:
{
    80002bfe:	1101                	addi	sp,sp,-32
    80002c00:	ec06                	sd	ra,24(sp)
    80002c02:	e822                	sd	s0,16(sp)
    80002c04:	e426                	sd	s1,8(sp)
    80002c06:	e04a                	sd	s2,0(sp)
    80002c08:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c0a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c0e:	1007f793          	andi	a5,a5,256
    80002c12:	e3b1                	bnez	a5,80002c56 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c14:	00003797          	auipc	a5,0x3
    80002c18:	3bc78793          	addi	a5,a5,956 # 80005fd0 <kernelvec>
    80002c1c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c20:	fffff097          	auipc	ra,0xfffff
    80002c24:	f42080e7          	jalr	-190(ra) # 80001b62 <myproc>
    80002c28:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c2a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c2c:	14102773          	csrr	a4,sepc
    80002c30:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c32:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c36:	47a1                	li	a5,8
    80002c38:	02f70763          	beq	a4,a5,80002c66 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002c3c:	00000097          	auipc	ra,0x0
    80002c40:	f1c080e7          	jalr	-228(ra) # 80002b58 <devintr>
    80002c44:	892a                	mv	s2,a0
    80002c46:	c151                	beqz	a0,80002cca <usertrap+0xcc>
  if(killed(p))
    80002c48:	8526                	mv	a0,s1
    80002c4a:	00000097          	auipc	ra,0x0
    80002c4e:	928080e7          	jalr	-1752(ra) # 80002572 <killed>
    80002c52:	c929                	beqz	a0,80002ca4 <usertrap+0xa6>
    80002c54:	a099                	j	80002c9a <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002c56:	00005517          	auipc	a0,0x5
    80002c5a:	7da50513          	addi	a0,a0,2010 # 80008430 <states.0+0x58>
    80002c5e:	ffffe097          	auipc	ra,0xffffe
    80002c62:	8de080e7          	jalr	-1826(ra) # 8000053c <panic>
    if(killed(p))
    80002c66:	00000097          	auipc	ra,0x0
    80002c6a:	90c080e7          	jalr	-1780(ra) # 80002572 <killed>
    80002c6e:	e921                	bnez	a0,80002cbe <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002c70:	6cb8                	ld	a4,88(s1)
    80002c72:	6f1c                	ld	a5,24(a4)
    80002c74:	0791                	addi	a5,a5,4
    80002c76:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c78:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c7c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c80:	10079073          	csrw	sstatus,a5
    syscall();
    80002c84:	00000097          	auipc	ra,0x0
    80002c88:	2d4080e7          	jalr	724(ra) # 80002f58 <syscall>
  if(killed(p))
    80002c8c:	8526                	mv	a0,s1
    80002c8e:	00000097          	auipc	ra,0x0
    80002c92:	8e4080e7          	jalr	-1820(ra) # 80002572 <killed>
    80002c96:	c911                	beqz	a0,80002caa <usertrap+0xac>
    80002c98:	4901                	li	s2,0
    exit(-1);
    80002c9a:	557d                	li	a0,-1
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	762080e7          	jalr	1890(ra) # 800023fe <exit>
  if(which_dev == 2)
    80002ca4:	4789                	li	a5,2
    80002ca6:	04f90f63          	beq	s2,a5,80002d04 <usertrap+0x106>
  usertrapret();
    80002caa:	00000097          	auipc	ra,0x0
    80002cae:	dd2080e7          	jalr	-558(ra) # 80002a7c <usertrapret>
}
    80002cb2:	60e2                	ld	ra,24(sp)
    80002cb4:	6442                	ld	s0,16(sp)
    80002cb6:	64a2                	ld	s1,8(sp)
    80002cb8:	6902                	ld	s2,0(sp)
    80002cba:	6105                	addi	sp,sp,32
    80002cbc:	8082                	ret
      exit(-1);
    80002cbe:	557d                	li	a0,-1
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	73e080e7          	jalr	1854(ra) # 800023fe <exit>
    80002cc8:	b765                	j	80002c70 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cca:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cce:	5890                	lw	a2,48(s1)
    80002cd0:	00005517          	auipc	a0,0x5
    80002cd4:	78050513          	addi	a0,a0,1920 # 80008450 <states.0+0x78>
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	8c0080e7          	jalr	-1856(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ce0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ce4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ce8:	00005517          	auipc	a0,0x5
    80002cec:	79850513          	addi	a0,a0,1944 # 80008480 <states.0+0xa8>
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	8a8080e7          	jalr	-1880(ra) # 80000598 <printf>
    setkilled(p);
    80002cf8:	8526                	mv	a0,s1
    80002cfa:	00000097          	auipc	ra,0x0
    80002cfe:	84c080e7          	jalr	-1972(ra) # 80002546 <setkilled>
    80002d02:	b769                	j	80002c8c <usertrap+0x8e>
    yield();
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	58a080e7          	jalr	1418(ra) # 8000228e <yield>
    80002d0c:	bf79                	j	80002caa <usertrap+0xac>

0000000080002d0e <kerneltrap>:
{
    80002d0e:	7179                	addi	sp,sp,-48
    80002d10:	f406                	sd	ra,40(sp)
    80002d12:	f022                	sd	s0,32(sp)
    80002d14:	ec26                	sd	s1,24(sp)
    80002d16:	e84a                	sd	s2,16(sp)
    80002d18:	e44e                	sd	s3,8(sp)
    80002d1a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d1c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d20:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d24:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d28:	1004f793          	andi	a5,s1,256
    80002d2c:	cb85                	beqz	a5,80002d5c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d2e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d32:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d34:	ef85                	bnez	a5,80002d6c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d36:	00000097          	auipc	ra,0x0
    80002d3a:	e22080e7          	jalr	-478(ra) # 80002b58 <devintr>
    80002d3e:	cd1d                	beqz	a0,80002d7c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d40:	4789                	li	a5,2
    80002d42:	06f50a63          	beq	a0,a5,80002db6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d46:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d4a:	10049073          	csrw	sstatus,s1
}
    80002d4e:	70a2                	ld	ra,40(sp)
    80002d50:	7402                	ld	s0,32(sp)
    80002d52:	64e2                	ld	s1,24(sp)
    80002d54:	6942                	ld	s2,16(sp)
    80002d56:	69a2                	ld	s3,8(sp)
    80002d58:	6145                	addi	sp,sp,48
    80002d5a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d5c:	00005517          	auipc	a0,0x5
    80002d60:	74450513          	addi	a0,a0,1860 # 800084a0 <states.0+0xc8>
    80002d64:	ffffd097          	auipc	ra,0xffffd
    80002d68:	7d8080e7          	jalr	2008(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002d6c:	00005517          	auipc	a0,0x5
    80002d70:	75c50513          	addi	a0,a0,1884 # 800084c8 <states.0+0xf0>
    80002d74:	ffffd097          	auipc	ra,0xffffd
    80002d78:	7c8080e7          	jalr	1992(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002d7c:	85ce                	mv	a1,s3
    80002d7e:	00005517          	auipc	a0,0x5
    80002d82:	76a50513          	addi	a0,a0,1898 # 800084e8 <states.0+0x110>
    80002d86:	ffffe097          	auipc	ra,0xffffe
    80002d8a:	812080e7          	jalr	-2030(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d8e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d92:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d96:	00005517          	auipc	a0,0x5
    80002d9a:	76250513          	addi	a0,a0,1890 # 800084f8 <states.0+0x120>
    80002d9e:	ffffd097          	auipc	ra,0xffffd
    80002da2:	7fa080e7          	jalr	2042(ra) # 80000598 <printf>
    panic("kerneltrap");
    80002da6:	00005517          	auipc	a0,0x5
    80002daa:	76a50513          	addi	a0,a0,1898 # 80008510 <states.0+0x138>
    80002dae:	ffffd097          	auipc	ra,0xffffd
    80002db2:	78e080e7          	jalr	1934(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002db6:	fffff097          	auipc	ra,0xfffff
    80002dba:	dac080e7          	jalr	-596(ra) # 80001b62 <myproc>
    80002dbe:	d541                	beqz	a0,80002d46 <kerneltrap+0x38>
    80002dc0:	fffff097          	auipc	ra,0xfffff
    80002dc4:	da2080e7          	jalr	-606(ra) # 80001b62 <myproc>
    80002dc8:	4d18                	lw	a4,24(a0)
    80002dca:	4791                	li	a5,4
    80002dcc:	f6f71de3          	bne	a4,a5,80002d46 <kerneltrap+0x38>
    yield();
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	4be080e7          	jalr	1214(ra) # 8000228e <yield>
    80002dd8:	b7bd                	j	80002d46 <kerneltrap+0x38>

0000000080002dda <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002dda:	1101                	addi	sp,sp,-32
    80002ddc:	ec06                	sd	ra,24(sp)
    80002dde:	e822                	sd	s0,16(sp)
    80002de0:	e426                	sd	s1,8(sp)
    80002de2:	1000                	addi	s0,sp,32
    80002de4:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	d7c080e7          	jalr	-644(ra) # 80001b62 <myproc>
    switch (n)
    80002dee:	4795                	li	a5,5
    80002df0:	0497e163          	bltu	a5,s1,80002e32 <argraw+0x58>
    80002df4:	048a                	slli	s1,s1,0x2
    80002df6:	00005717          	auipc	a4,0x5
    80002dfa:	75270713          	addi	a4,a4,1874 # 80008548 <states.0+0x170>
    80002dfe:	94ba                	add	s1,s1,a4
    80002e00:	409c                	lw	a5,0(s1)
    80002e02:	97ba                	add	a5,a5,a4
    80002e04:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002e06:	6d3c                	ld	a5,88(a0)
    80002e08:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002e0a:	60e2                	ld	ra,24(sp)
    80002e0c:	6442                	ld	s0,16(sp)
    80002e0e:	64a2                	ld	s1,8(sp)
    80002e10:	6105                	addi	sp,sp,32
    80002e12:	8082                	ret
        return p->trapframe->a1;
    80002e14:	6d3c                	ld	a5,88(a0)
    80002e16:	7fa8                	ld	a0,120(a5)
    80002e18:	bfcd                	j	80002e0a <argraw+0x30>
        return p->trapframe->a2;
    80002e1a:	6d3c                	ld	a5,88(a0)
    80002e1c:	63c8                	ld	a0,128(a5)
    80002e1e:	b7f5                	j	80002e0a <argraw+0x30>
        return p->trapframe->a3;
    80002e20:	6d3c                	ld	a5,88(a0)
    80002e22:	67c8                	ld	a0,136(a5)
    80002e24:	b7dd                	j	80002e0a <argraw+0x30>
        return p->trapframe->a4;
    80002e26:	6d3c                	ld	a5,88(a0)
    80002e28:	6bc8                	ld	a0,144(a5)
    80002e2a:	b7c5                	j	80002e0a <argraw+0x30>
        return p->trapframe->a5;
    80002e2c:	6d3c                	ld	a5,88(a0)
    80002e2e:	6fc8                	ld	a0,152(a5)
    80002e30:	bfe9                	j	80002e0a <argraw+0x30>
    panic("argraw");
    80002e32:	00005517          	auipc	a0,0x5
    80002e36:	6ee50513          	addi	a0,a0,1774 # 80008520 <states.0+0x148>
    80002e3a:	ffffd097          	auipc	ra,0xffffd
    80002e3e:	702080e7          	jalr	1794(ra) # 8000053c <panic>

0000000080002e42 <fetchaddr>:
{
    80002e42:	1101                	addi	sp,sp,-32
    80002e44:	ec06                	sd	ra,24(sp)
    80002e46:	e822                	sd	s0,16(sp)
    80002e48:	e426                	sd	s1,8(sp)
    80002e4a:	e04a                	sd	s2,0(sp)
    80002e4c:	1000                	addi	s0,sp,32
    80002e4e:	84aa                	mv	s1,a0
    80002e50:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002e52:	fffff097          	auipc	ra,0xfffff
    80002e56:	d10080e7          	jalr	-752(ra) # 80001b62 <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002e5a:	653c                	ld	a5,72(a0)
    80002e5c:	02f4f863          	bgeu	s1,a5,80002e8c <fetchaddr+0x4a>
    80002e60:	00848713          	addi	a4,s1,8
    80002e64:	02e7e663          	bltu	a5,a4,80002e90 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e68:	46a1                	li	a3,8
    80002e6a:	8626                	mv	a2,s1
    80002e6c:	85ca                	mv	a1,s2
    80002e6e:	6928                	ld	a0,80(a0)
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	94a080e7          	jalr	-1718(ra) # 800017ba <copyin>
    80002e78:	00a03533          	snez	a0,a0
    80002e7c:	40a00533          	neg	a0,a0
}
    80002e80:	60e2                	ld	ra,24(sp)
    80002e82:	6442                	ld	s0,16(sp)
    80002e84:	64a2                	ld	s1,8(sp)
    80002e86:	6902                	ld	s2,0(sp)
    80002e88:	6105                	addi	sp,sp,32
    80002e8a:	8082                	ret
        return -1;
    80002e8c:	557d                	li	a0,-1
    80002e8e:	bfcd                	j	80002e80 <fetchaddr+0x3e>
    80002e90:	557d                	li	a0,-1
    80002e92:	b7fd                	j	80002e80 <fetchaddr+0x3e>

0000000080002e94 <fetchstr>:
{
    80002e94:	7179                	addi	sp,sp,-48
    80002e96:	f406                	sd	ra,40(sp)
    80002e98:	f022                	sd	s0,32(sp)
    80002e9a:	ec26                	sd	s1,24(sp)
    80002e9c:	e84a                	sd	s2,16(sp)
    80002e9e:	e44e                	sd	s3,8(sp)
    80002ea0:	1800                	addi	s0,sp,48
    80002ea2:	892a                	mv	s2,a0
    80002ea4:	84ae                	mv	s1,a1
    80002ea6:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	cba080e7          	jalr	-838(ra) # 80001b62 <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002eb0:	86ce                	mv	a3,s3
    80002eb2:	864a                	mv	a2,s2
    80002eb4:	85a6                	mv	a1,s1
    80002eb6:	6928                	ld	a0,80(a0)
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	990080e7          	jalr	-1648(ra) # 80001848 <copyinstr>
    80002ec0:	00054e63          	bltz	a0,80002edc <fetchstr+0x48>
    return strlen(buf);
    80002ec4:	8526                	mv	a0,s1
    80002ec6:	ffffe097          	auipc	ra,0xffffe
    80002eca:	04a080e7          	jalr	74(ra) # 80000f10 <strlen>
}
    80002ece:	70a2                	ld	ra,40(sp)
    80002ed0:	7402                	ld	s0,32(sp)
    80002ed2:	64e2                	ld	s1,24(sp)
    80002ed4:	6942                	ld	s2,16(sp)
    80002ed6:	69a2                	ld	s3,8(sp)
    80002ed8:	6145                	addi	sp,sp,48
    80002eda:	8082                	ret
        return -1;
    80002edc:	557d                	li	a0,-1
    80002ede:	bfc5                	j	80002ece <fetchstr+0x3a>

0000000080002ee0 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002ee0:	1101                	addi	sp,sp,-32
    80002ee2:	ec06                	sd	ra,24(sp)
    80002ee4:	e822                	sd	s0,16(sp)
    80002ee6:	e426                	sd	s1,8(sp)
    80002ee8:	1000                	addi	s0,sp,32
    80002eea:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002eec:	00000097          	auipc	ra,0x0
    80002ef0:	eee080e7          	jalr	-274(ra) # 80002dda <argraw>
    80002ef4:	c088                	sw	a0,0(s1)
}
    80002ef6:	60e2                	ld	ra,24(sp)
    80002ef8:	6442                	ld	s0,16(sp)
    80002efa:	64a2                	ld	s1,8(sp)
    80002efc:	6105                	addi	sp,sp,32
    80002efe:	8082                	ret

0000000080002f00 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002f00:	1101                	addi	sp,sp,-32
    80002f02:	ec06                	sd	ra,24(sp)
    80002f04:	e822                	sd	s0,16(sp)
    80002f06:	e426                	sd	s1,8(sp)
    80002f08:	1000                	addi	s0,sp,32
    80002f0a:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002f0c:	00000097          	auipc	ra,0x0
    80002f10:	ece080e7          	jalr	-306(ra) # 80002dda <argraw>
    80002f14:	e088                	sd	a0,0(s1)
}
    80002f16:	60e2                	ld	ra,24(sp)
    80002f18:	6442                	ld	s0,16(sp)
    80002f1a:	64a2                	ld	s1,8(sp)
    80002f1c:	6105                	addi	sp,sp,32
    80002f1e:	8082                	ret

0000000080002f20 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002f20:	7179                	addi	sp,sp,-48
    80002f22:	f406                	sd	ra,40(sp)
    80002f24:	f022                	sd	s0,32(sp)
    80002f26:	ec26                	sd	s1,24(sp)
    80002f28:	e84a                	sd	s2,16(sp)
    80002f2a:	1800                	addi	s0,sp,48
    80002f2c:	84ae                	mv	s1,a1
    80002f2e:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80002f30:	fd840593          	addi	a1,s0,-40
    80002f34:	00000097          	auipc	ra,0x0
    80002f38:	fcc080e7          	jalr	-52(ra) # 80002f00 <argaddr>
    return fetchstr(addr, buf, max);
    80002f3c:	864a                	mv	a2,s2
    80002f3e:	85a6                	mv	a1,s1
    80002f40:	fd843503          	ld	a0,-40(s0)
    80002f44:	00000097          	auipc	ra,0x0
    80002f48:	f50080e7          	jalr	-176(ra) # 80002e94 <fetchstr>
}
    80002f4c:	70a2                	ld	ra,40(sp)
    80002f4e:	7402                	ld	s0,32(sp)
    80002f50:	64e2                	ld	s1,24(sp)
    80002f52:	6942                	ld	s2,16(sp)
    80002f54:	6145                	addi	sp,sp,48
    80002f56:	8082                	ret

0000000080002f58 <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    80002f58:	1101                	addi	sp,sp,-32
    80002f5a:	ec06                	sd	ra,24(sp)
    80002f5c:	e822                	sd	s0,16(sp)
    80002f5e:	e426                	sd	s1,8(sp)
    80002f60:	e04a                	sd	s2,0(sp)
    80002f62:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    80002f64:	fffff097          	auipc	ra,0xfffff
    80002f68:	bfe080e7          	jalr	-1026(ra) # 80001b62 <myproc>
    80002f6c:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80002f6e:	05853903          	ld	s2,88(a0)
    80002f72:	0a893783          	ld	a5,168(s2)
    80002f76:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002f7a:	37fd                	addiw	a5,a5,-1
    80002f7c:	4765                	li	a4,25
    80002f7e:	00f76f63          	bltu	a4,a5,80002f9c <syscall+0x44>
    80002f82:	00369713          	slli	a4,a3,0x3
    80002f86:	00005797          	auipc	a5,0x5
    80002f8a:	5da78793          	addi	a5,a5,1498 # 80008560 <syscalls>
    80002f8e:	97ba                	add	a5,a5,a4
    80002f90:	639c                	ld	a5,0(a5)
    80002f92:	c789                	beqz	a5,80002f9c <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    80002f94:	9782                	jalr	a5
    80002f96:	06a93823          	sd	a0,112(s2)
    80002f9a:	a839                	j	80002fb8 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    80002f9c:	15848613          	addi	a2,s1,344
    80002fa0:	588c                	lw	a1,48(s1)
    80002fa2:	00005517          	auipc	a0,0x5
    80002fa6:	58650513          	addi	a0,a0,1414 # 80008528 <states.0+0x150>
    80002faa:	ffffd097          	auipc	ra,0xffffd
    80002fae:	5ee080e7          	jalr	1518(ra) # 80000598 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    80002fb2:	6cbc                	ld	a5,88(s1)
    80002fb4:	577d                	li	a4,-1
    80002fb6:	fbb8                	sd	a4,112(a5)
    }
}
    80002fb8:	60e2                	ld	ra,24(sp)
    80002fba:	6442                	ld	s0,16(sp)
    80002fbc:	64a2                	ld	s1,8(sp)
    80002fbe:	6902                	ld	s2,0(sp)
    80002fc0:	6105                	addi	sp,sp,32
    80002fc2:	8082                	ret

0000000080002fc4 <sys_exit>:

extern uint64 FREE_PAGES; // kalloc.c keeps track of those

uint64
sys_exit(void)
{
    80002fc4:	1101                	addi	sp,sp,-32
    80002fc6:	ec06                	sd	ra,24(sp)
    80002fc8:	e822                	sd	s0,16(sp)
    80002fca:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    80002fcc:	fec40593          	addi	a1,s0,-20
    80002fd0:	4501                	li	a0,0
    80002fd2:	00000097          	auipc	ra,0x0
    80002fd6:	f0e080e7          	jalr	-242(ra) # 80002ee0 <argint>
    exit(n);
    80002fda:	fec42503          	lw	a0,-20(s0)
    80002fde:	fffff097          	auipc	ra,0xfffff
    80002fe2:	420080e7          	jalr	1056(ra) # 800023fe <exit>
    return 0; // not reached
}
    80002fe6:	4501                	li	a0,0
    80002fe8:	60e2                	ld	ra,24(sp)
    80002fea:	6442                	ld	s0,16(sp)
    80002fec:	6105                	addi	sp,sp,32
    80002fee:	8082                	ret

0000000080002ff0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ff0:	1141                	addi	sp,sp,-16
    80002ff2:	e406                	sd	ra,8(sp)
    80002ff4:	e022                	sd	s0,0(sp)
    80002ff6:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80002ff8:	fffff097          	auipc	ra,0xfffff
    80002ffc:	b6a080e7          	jalr	-1174(ra) # 80001b62 <myproc>
}
    80003000:	5908                	lw	a0,48(a0)
    80003002:	60a2                	ld	ra,8(sp)
    80003004:	6402                	ld	s0,0(sp)
    80003006:	0141                	addi	sp,sp,16
    80003008:	8082                	ret

000000008000300a <sys_fork>:

uint64
sys_fork(void)
{
    8000300a:	1141                	addi	sp,sp,-16
    8000300c:	e406                	sd	ra,8(sp)
    8000300e:	e022                	sd	s0,0(sp)
    80003010:	0800                	addi	s0,sp,16
    return fork();
    80003012:	fffff097          	auipc	ra,0xfffff
    80003016:	056080e7          	jalr	86(ra) # 80002068 <fork>
}
    8000301a:	60a2                	ld	ra,8(sp)
    8000301c:	6402                	ld	s0,0(sp)
    8000301e:	0141                	addi	sp,sp,16
    80003020:	8082                	ret

0000000080003022 <sys_wait>:

uint64
sys_wait(void)
{
    80003022:	1101                	addi	sp,sp,-32
    80003024:	ec06                	sd	ra,24(sp)
    80003026:	e822                	sd	s0,16(sp)
    80003028:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    8000302a:	fe840593          	addi	a1,s0,-24
    8000302e:	4501                	li	a0,0
    80003030:	00000097          	auipc	ra,0x0
    80003034:	ed0080e7          	jalr	-304(ra) # 80002f00 <argaddr>
    return wait(p);
    80003038:	fe843503          	ld	a0,-24(s0)
    8000303c:	fffff097          	auipc	ra,0xfffff
    80003040:	568080e7          	jalr	1384(ra) # 800025a4 <wait>
}
    80003044:	60e2                	ld	ra,24(sp)
    80003046:	6442                	ld	s0,16(sp)
    80003048:	6105                	addi	sp,sp,32
    8000304a:	8082                	ret

000000008000304c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000304c:	7179                	addi	sp,sp,-48
    8000304e:	f406                	sd	ra,40(sp)
    80003050:	f022                	sd	s0,32(sp)
    80003052:	ec26                	sd	s1,24(sp)
    80003054:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80003056:	fdc40593          	addi	a1,s0,-36
    8000305a:	4501                	li	a0,0
    8000305c:	00000097          	auipc	ra,0x0
    80003060:	e84080e7          	jalr	-380(ra) # 80002ee0 <argint>
    addr = myproc()->sz;
    80003064:	fffff097          	auipc	ra,0xfffff
    80003068:	afe080e7          	jalr	-1282(ra) # 80001b62 <myproc>
    8000306c:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    8000306e:	fdc42503          	lw	a0,-36(s0)
    80003072:	fffff097          	auipc	ra,0xfffff
    80003076:	e4a080e7          	jalr	-438(ra) # 80001ebc <growproc>
    8000307a:	00054863          	bltz	a0,8000308a <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    8000307e:	8526                	mv	a0,s1
    80003080:	70a2                	ld	ra,40(sp)
    80003082:	7402                	ld	s0,32(sp)
    80003084:	64e2                	ld	s1,24(sp)
    80003086:	6145                	addi	sp,sp,48
    80003088:	8082                	ret
        return -1;
    8000308a:	54fd                	li	s1,-1
    8000308c:	bfcd                	j	8000307e <sys_sbrk+0x32>

000000008000308e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000308e:	7139                	addi	sp,sp,-64
    80003090:	fc06                	sd	ra,56(sp)
    80003092:	f822                	sd	s0,48(sp)
    80003094:	f426                	sd	s1,40(sp)
    80003096:	f04a                	sd	s2,32(sp)
    80003098:	ec4e                	sd	s3,24(sp)
    8000309a:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    8000309c:	fcc40593          	addi	a1,s0,-52
    800030a0:	4501                	li	a0,0
    800030a2:	00000097          	auipc	ra,0x0
    800030a6:	e3e080e7          	jalr	-450(ra) # 80002ee0 <argint>
    acquire(&tickslock);
    800030aa:	00014517          	auipc	a0,0x14
    800030ae:	a5650513          	addi	a0,a0,-1450 # 80016b00 <tickslock>
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	be8080e7          	jalr	-1048(ra) # 80000c9a <acquire>
    ticks0 = ticks;
    800030ba:	00006917          	auipc	s2,0x6
    800030be:	9a692903          	lw	s2,-1626(s2) # 80008a60 <ticks>
    while (ticks - ticks0 < n)
    800030c2:	fcc42783          	lw	a5,-52(s0)
    800030c6:	cf9d                	beqz	a5,80003104 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    800030c8:	00014997          	auipc	s3,0x14
    800030cc:	a3898993          	addi	s3,s3,-1480 # 80016b00 <tickslock>
    800030d0:	00006497          	auipc	s1,0x6
    800030d4:	99048493          	addi	s1,s1,-1648 # 80008a60 <ticks>
        if (killed(myproc()))
    800030d8:	fffff097          	auipc	ra,0xfffff
    800030dc:	a8a080e7          	jalr	-1398(ra) # 80001b62 <myproc>
    800030e0:	fffff097          	auipc	ra,0xfffff
    800030e4:	492080e7          	jalr	1170(ra) # 80002572 <killed>
    800030e8:	ed15                	bnez	a0,80003124 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    800030ea:	85ce                	mv	a1,s3
    800030ec:	8526                	mv	a0,s1
    800030ee:	fffff097          	auipc	ra,0xfffff
    800030f2:	1dc080e7          	jalr	476(ra) # 800022ca <sleep>
    while (ticks - ticks0 < n)
    800030f6:	409c                	lw	a5,0(s1)
    800030f8:	412787bb          	subw	a5,a5,s2
    800030fc:	fcc42703          	lw	a4,-52(s0)
    80003100:	fce7ece3          	bltu	a5,a4,800030d8 <sys_sleep+0x4a>
    }
    release(&tickslock);
    80003104:	00014517          	auipc	a0,0x14
    80003108:	9fc50513          	addi	a0,a0,-1540 # 80016b00 <tickslock>
    8000310c:	ffffe097          	auipc	ra,0xffffe
    80003110:	c42080e7          	jalr	-958(ra) # 80000d4e <release>
    return 0;
    80003114:	4501                	li	a0,0
}
    80003116:	70e2                	ld	ra,56(sp)
    80003118:	7442                	ld	s0,48(sp)
    8000311a:	74a2                	ld	s1,40(sp)
    8000311c:	7902                	ld	s2,32(sp)
    8000311e:	69e2                	ld	s3,24(sp)
    80003120:	6121                	addi	sp,sp,64
    80003122:	8082                	ret
            release(&tickslock);
    80003124:	00014517          	auipc	a0,0x14
    80003128:	9dc50513          	addi	a0,a0,-1572 # 80016b00 <tickslock>
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	c22080e7          	jalr	-990(ra) # 80000d4e <release>
            return -1;
    80003134:	557d                	li	a0,-1
    80003136:	b7c5                	j	80003116 <sys_sleep+0x88>

0000000080003138 <sys_kill>:

uint64
sys_kill(void)
{
    80003138:	1101                	addi	sp,sp,-32
    8000313a:	ec06                	sd	ra,24(sp)
    8000313c:	e822                	sd	s0,16(sp)
    8000313e:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    80003140:	fec40593          	addi	a1,s0,-20
    80003144:	4501                	li	a0,0
    80003146:	00000097          	auipc	ra,0x0
    8000314a:	d9a080e7          	jalr	-614(ra) # 80002ee0 <argint>
    return kill(pid);
    8000314e:	fec42503          	lw	a0,-20(s0)
    80003152:	fffff097          	auipc	ra,0xfffff
    80003156:	382080e7          	jalr	898(ra) # 800024d4 <kill>
}
    8000315a:	60e2                	ld	ra,24(sp)
    8000315c:	6442                	ld	s0,16(sp)
    8000315e:	6105                	addi	sp,sp,32
    80003160:	8082                	ret

0000000080003162 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003162:	1101                	addi	sp,sp,-32
    80003164:	ec06                	sd	ra,24(sp)
    80003166:	e822                	sd	s0,16(sp)
    80003168:	e426                	sd	s1,8(sp)
    8000316a:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    8000316c:	00014517          	auipc	a0,0x14
    80003170:	99450513          	addi	a0,a0,-1644 # 80016b00 <tickslock>
    80003174:	ffffe097          	auipc	ra,0xffffe
    80003178:	b26080e7          	jalr	-1242(ra) # 80000c9a <acquire>
    xticks = ticks;
    8000317c:	00006497          	auipc	s1,0x6
    80003180:	8e44a483          	lw	s1,-1820(s1) # 80008a60 <ticks>
    release(&tickslock);
    80003184:	00014517          	auipc	a0,0x14
    80003188:	97c50513          	addi	a0,a0,-1668 # 80016b00 <tickslock>
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	bc2080e7          	jalr	-1086(ra) # 80000d4e <release>
    return xticks;
}
    80003194:	02049513          	slli	a0,s1,0x20
    80003198:	9101                	srli	a0,a0,0x20
    8000319a:	60e2                	ld	ra,24(sp)
    8000319c:	6442                	ld	s0,16(sp)
    8000319e:	64a2                	ld	s1,8(sp)
    800031a0:	6105                	addi	sp,sp,32
    800031a2:	8082                	ret

00000000800031a4 <sys_ps>:

void *
sys_ps(void)
{
    800031a4:	1101                	addi	sp,sp,-32
    800031a6:	ec06                	sd	ra,24(sp)
    800031a8:	e822                	sd	s0,16(sp)
    800031aa:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800031ac:	fe042623          	sw	zero,-20(s0)
    800031b0:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800031b4:	fec40593          	addi	a1,s0,-20
    800031b8:	4501                	li	a0,0
    800031ba:	00000097          	auipc	ra,0x0
    800031be:	d26080e7          	jalr	-730(ra) # 80002ee0 <argint>
    argint(1, &count);
    800031c2:	fe840593          	addi	a1,s0,-24
    800031c6:	4505                	li	a0,1
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	d18080e7          	jalr	-744(ra) # 80002ee0 <argint>
    return ps((uint8)start, (uint8)count);
    800031d0:	fe844583          	lbu	a1,-24(s0)
    800031d4:	fec44503          	lbu	a0,-20(s0)
    800031d8:	fffff097          	auipc	ra,0xfffff
    800031dc:	d40080e7          	jalr	-704(ra) # 80001f18 <ps>
}
    800031e0:	60e2                	ld	ra,24(sp)
    800031e2:	6442                	ld	s0,16(sp)
    800031e4:	6105                	addi	sp,sp,32
    800031e6:	8082                	ret

00000000800031e8 <sys_schedls>:

uint64 sys_schedls(void)
{
    800031e8:	1141                	addi	sp,sp,-16
    800031ea:	e406                	sd	ra,8(sp)
    800031ec:	e022                	sd	s0,0(sp)
    800031ee:	0800                	addi	s0,sp,16
    schedls();
    800031f0:	fffff097          	auipc	ra,0xfffff
    800031f4:	63e080e7          	jalr	1598(ra) # 8000282e <schedls>
    return 0;
}
    800031f8:	4501                	li	a0,0
    800031fa:	60a2                	ld	ra,8(sp)
    800031fc:	6402                	ld	s0,0(sp)
    800031fe:	0141                	addi	sp,sp,16
    80003200:	8082                	ret

0000000080003202 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003202:	1101                	addi	sp,sp,-32
    80003204:	ec06                	sd	ra,24(sp)
    80003206:	e822                	sd	s0,16(sp)
    80003208:	1000                	addi	s0,sp,32
    int id = 0;
    8000320a:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    8000320e:	fec40593          	addi	a1,s0,-20
    80003212:	4501                	li	a0,0
    80003214:	00000097          	auipc	ra,0x0
    80003218:	ccc080e7          	jalr	-820(ra) # 80002ee0 <argint>
    schedset(id - 1);
    8000321c:	fec42503          	lw	a0,-20(s0)
    80003220:	357d                	addiw	a0,a0,-1
    80003222:	fffff097          	auipc	ra,0xfffff
    80003226:	6a2080e7          	jalr	1698(ra) # 800028c4 <schedset>
    return 0;
}
    8000322a:	4501                	li	a0,0
    8000322c:	60e2                	ld	ra,24(sp)
    8000322e:	6442                	ld	s0,16(sp)
    80003230:	6105                	addi	sp,sp,32
    80003232:	8082                	ret

0000000080003234 <sys_va2pa>:

uint64 sys_va2pa(void)
{
    80003234:	1101                	addi	sp,sp,-32
    80003236:	ec06                	sd	ra,24(sp)
    80003238:	e822                	sd	s0,16(sp)
    8000323a:	1000                	addi	s0,sp,32
    uint64 va = 0;
    8000323c:	fe043423          	sd	zero,-24(s0)
    argaddr(0, &va);
    80003240:	fe840593          	addi	a1,s0,-24
    80003244:	4501                	li	a0,0
    80003246:	00000097          	auipc	ra,0x0
    8000324a:	cba080e7          	jalr	-838(ra) # 80002f00 <argaddr>
    int pid = 0;
    8000324e:	fe042223          	sw	zero,-28(s0)
    argint(1, &pid);
    80003252:	fe440593          	addi	a1,s0,-28
    80003256:	4505                	li	a0,1
    80003258:	00000097          	auipc	ra,0x0
    8000325c:	c88080e7          	jalr	-888(ra) # 80002ee0 <argint>
    return va2pa(va, pid);
    80003260:	fe442583          	lw	a1,-28(s0)
    80003264:	fe843503          	ld	a0,-24(s0)
    80003268:	fffff097          	auipc	ra,0xfffff
    8000326c:	708080e7          	jalr	1800(ra) # 80002970 <va2pa>
}
    80003270:	60e2                	ld	ra,24(sp)
    80003272:	6442                	ld	s0,16(sp)
    80003274:	6105                	addi	sp,sp,32
    80003276:	8082                	ret

0000000080003278 <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    80003278:	1141                	addi	sp,sp,-16
    8000327a:	e406                	sd	ra,8(sp)
    8000327c:	e022                	sd	s0,0(sp)
    8000327e:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    80003280:	00005597          	auipc	a1,0x5
    80003284:	7b85b583          	ld	a1,1976(a1) # 80008a38 <FREE_PAGES>
    80003288:	00005517          	auipc	a0,0x5
    8000328c:	2b850513          	addi	a0,a0,696 # 80008540 <states.0+0x168>
    80003290:	ffffd097          	auipc	ra,0xffffd
    80003294:	308080e7          	jalr	776(ra) # 80000598 <printf>
    return 0;
    80003298:	4501                	li	a0,0
    8000329a:	60a2                	ld	ra,8(sp)
    8000329c:	6402                	ld	s0,0(sp)
    8000329e:	0141                	addi	sp,sp,16
    800032a0:	8082                	ret

00000000800032a2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032a2:	7179                	addi	sp,sp,-48
    800032a4:	f406                	sd	ra,40(sp)
    800032a6:	f022                	sd	s0,32(sp)
    800032a8:	ec26                	sd	s1,24(sp)
    800032aa:	e84a                	sd	s2,16(sp)
    800032ac:	e44e                	sd	s3,8(sp)
    800032ae:	e052                	sd	s4,0(sp)
    800032b0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800032b2:	00005597          	auipc	a1,0x5
    800032b6:	38658593          	addi	a1,a1,902 # 80008638 <syscalls+0xd8>
    800032ba:	00014517          	auipc	a0,0x14
    800032be:	85e50513          	addi	a0,a0,-1954 # 80016b18 <bcache>
    800032c2:	ffffe097          	auipc	ra,0xffffe
    800032c6:	948080e7          	jalr	-1720(ra) # 80000c0a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800032ca:	0001c797          	auipc	a5,0x1c
    800032ce:	84e78793          	addi	a5,a5,-1970 # 8001eb18 <bcache+0x8000>
    800032d2:	0001c717          	auipc	a4,0x1c
    800032d6:	aae70713          	addi	a4,a4,-1362 # 8001ed80 <bcache+0x8268>
    800032da:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800032de:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032e2:	00014497          	auipc	s1,0x14
    800032e6:	84e48493          	addi	s1,s1,-1970 # 80016b30 <bcache+0x18>
    b->next = bcache.head.next;
    800032ea:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032ec:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032ee:	00005a17          	auipc	s4,0x5
    800032f2:	352a0a13          	addi	s4,s4,850 # 80008640 <syscalls+0xe0>
    b->next = bcache.head.next;
    800032f6:	2b893783          	ld	a5,696(s2)
    800032fa:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032fc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003300:	85d2                	mv	a1,s4
    80003302:	01048513          	addi	a0,s1,16
    80003306:	00001097          	auipc	ra,0x1
    8000330a:	496080e7          	jalr	1174(ra) # 8000479c <initsleeplock>
    bcache.head.next->prev = b;
    8000330e:	2b893783          	ld	a5,696(s2)
    80003312:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003314:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003318:	45848493          	addi	s1,s1,1112
    8000331c:	fd349de3          	bne	s1,s3,800032f6 <binit+0x54>
  }
}
    80003320:	70a2                	ld	ra,40(sp)
    80003322:	7402                	ld	s0,32(sp)
    80003324:	64e2                	ld	s1,24(sp)
    80003326:	6942                	ld	s2,16(sp)
    80003328:	69a2                	ld	s3,8(sp)
    8000332a:	6a02                	ld	s4,0(sp)
    8000332c:	6145                	addi	sp,sp,48
    8000332e:	8082                	ret

0000000080003330 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003330:	7179                	addi	sp,sp,-48
    80003332:	f406                	sd	ra,40(sp)
    80003334:	f022                	sd	s0,32(sp)
    80003336:	ec26                	sd	s1,24(sp)
    80003338:	e84a                	sd	s2,16(sp)
    8000333a:	e44e                	sd	s3,8(sp)
    8000333c:	1800                	addi	s0,sp,48
    8000333e:	892a                	mv	s2,a0
    80003340:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003342:	00013517          	auipc	a0,0x13
    80003346:	7d650513          	addi	a0,a0,2006 # 80016b18 <bcache>
    8000334a:	ffffe097          	auipc	ra,0xffffe
    8000334e:	950080e7          	jalr	-1712(ra) # 80000c9a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003352:	0001c497          	auipc	s1,0x1c
    80003356:	a7e4b483          	ld	s1,-1410(s1) # 8001edd0 <bcache+0x82b8>
    8000335a:	0001c797          	auipc	a5,0x1c
    8000335e:	a2678793          	addi	a5,a5,-1498 # 8001ed80 <bcache+0x8268>
    80003362:	02f48f63          	beq	s1,a5,800033a0 <bread+0x70>
    80003366:	873e                	mv	a4,a5
    80003368:	a021                	j	80003370 <bread+0x40>
    8000336a:	68a4                	ld	s1,80(s1)
    8000336c:	02e48a63          	beq	s1,a4,800033a0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003370:	449c                	lw	a5,8(s1)
    80003372:	ff279ce3          	bne	a5,s2,8000336a <bread+0x3a>
    80003376:	44dc                	lw	a5,12(s1)
    80003378:	ff3799e3          	bne	a5,s3,8000336a <bread+0x3a>
      b->refcnt++;
    8000337c:	40bc                	lw	a5,64(s1)
    8000337e:	2785                	addiw	a5,a5,1
    80003380:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003382:	00013517          	auipc	a0,0x13
    80003386:	79650513          	addi	a0,a0,1942 # 80016b18 <bcache>
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	9c4080e7          	jalr	-1596(ra) # 80000d4e <release>
      acquiresleep(&b->lock);
    80003392:	01048513          	addi	a0,s1,16
    80003396:	00001097          	auipc	ra,0x1
    8000339a:	440080e7          	jalr	1088(ra) # 800047d6 <acquiresleep>
      return b;
    8000339e:	a8b9                	j	800033fc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033a0:	0001c497          	auipc	s1,0x1c
    800033a4:	a284b483          	ld	s1,-1496(s1) # 8001edc8 <bcache+0x82b0>
    800033a8:	0001c797          	auipc	a5,0x1c
    800033ac:	9d878793          	addi	a5,a5,-1576 # 8001ed80 <bcache+0x8268>
    800033b0:	00f48863          	beq	s1,a5,800033c0 <bread+0x90>
    800033b4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800033b6:	40bc                	lw	a5,64(s1)
    800033b8:	cf81                	beqz	a5,800033d0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033ba:	64a4                	ld	s1,72(s1)
    800033bc:	fee49de3          	bne	s1,a4,800033b6 <bread+0x86>
  panic("bget: no buffers");
    800033c0:	00005517          	auipc	a0,0x5
    800033c4:	28850513          	addi	a0,a0,648 # 80008648 <syscalls+0xe8>
    800033c8:	ffffd097          	auipc	ra,0xffffd
    800033cc:	174080e7          	jalr	372(ra) # 8000053c <panic>
      b->dev = dev;
    800033d0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800033d4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800033d8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800033dc:	4785                	li	a5,1
    800033de:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033e0:	00013517          	auipc	a0,0x13
    800033e4:	73850513          	addi	a0,a0,1848 # 80016b18 <bcache>
    800033e8:	ffffe097          	auipc	ra,0xffffe
    800033ec:	966080e7          	jalr	-1690(ra) # 80000d4e <release>
      acquiresleep(&b->lock);
    800033f0:	01048513          	addi	a0,s1,16
    800033f4:	00001097          	auipc	ra,0x1
    800033f8:	3e2080e7          	jalr	994(ra) # 800047d6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033fc:	409c                	lw	a5,0(s1)
    800033fe:	cb89                	beqz	a5,80003410 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003400:	8526                	mv	a0,s1
    80003402:	70a2                	ld	ra,40(sp)
    80003404:	7402                	ld	s0,32(sp)
    80003406:	64e2                	ld	s1,24(sp)
    80003408:	6942                	ld	s2,16(sp)
    8000340a:	69a2                	ld	s3,8(sp)
    8000340c:	6145                	addi	sp,sp,48
    8000340e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003410:	4581                	li	a1,0
    80003412:	8526                	mv	a0,s1
    80003414:	00003097          	auipc	ra,0x3
    80003418:	f7e080e7          	jalr	-130(ra) # 80006392 <virtio_disk_rw>
    b->valid = 1;
    8000341c:	4785                	li	a5,1
    8000341e:	c09c                	sw	a5,0(s1)
  return b;
    80003420:	b7c5                	j	80003400 <bread+0xd0>

0000000080003422 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003422:	1101                	addi	sp,sp,-32
    80003424:	ec06                	sd	ra,24(sp)
    80003426:	e822                	sd	s0,16(sp)
    80003428:	e426                	sd	s1,8(sp)
    8000342a:	1000                	addi	s0,sp,32
    8000342c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000342e:	0541                	addi	a0,a0,16
    80003430:	00001097          	auipc	ra,0x1
    80003434:	440080e7          	jalr	1088(ra) # 80004870 <holdingsleep>
    80003438:	cd01                	beqz	a0,80003450 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000343a:	4585                	li	a1,1
    8000343c:	8526                	mv	a0,s1
    8000343e:	00003097          	auipc	ra,0x3
    80003442:	f54080e7          	jalr	-172(ra) # 80006392 <virtio_disk_rw>
}
    80003446:	60e2                	ld	ra,24(sp)
    80003448:	6442                	ld	s0,16(sp)
    8000344a:	64a2                	ld	s1,8(sp)
    8000344c:	6105                	addi	sp,sp,32
    8000344e:	8082                	ret
    panic("bwrite");
    80003450:	00005517          	auipc	a0,0x5
    80003454:	21050513          	addi	a0,a0,528 # 80008660 <syscalls+0x100>
    80003458:	ffffd097          	auipc	ra,0xffffd
    8000345c:	0e4080e7          	jalr	228(ra) # 8000053c <panic>

0000000080003460 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003460:	1101                	addi	sp,sp,-32
    80003462:	ec06                	sd	ra,24(sp)
    80003464:	e822                	sd	s0,16(sp)
    80003466:	e426                	sd	s1,8(sp)
    80003468:	e04a                	sd	s2,0(sp)
    8000346a:	1000                	addi	s0,sp,32
    8000346c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000346e:	01050913          	addi	s2,a0,16
    80003472:	854a                	mv	a0,s2
    80003474:	00001097          	auipc	ra,0x1
    80003478:	3fc080e7          	jalr	1020(ra) # 80004870 <holdingsleep>
    8000347c:	c925                	beqz	a0,800034ec <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000347e:	854a                	mv	a0,s2
    80003480:	00001097          	auipc	ra,0x1
    80003484:	3ac080e7          	jalr	940(ra) # 8000482c <releasesleep>

  acquire(&bcache.lock);
    80003488:	00013517          	auipc	a0,0x13
    8000348c:	69050513          	addi	a0,a0,1680 # 80016b18 <bcache>
    80003490:	ffffe097          	auipc	ra,0xffffe
    80003494:	80a080e7          	jalr	-2038(ra) # 80000c9a <acquire>
  b->refcnt--;
    80003498:	40bc                	lw	a5,64(s1)
    8000349a:	37fd                	addiw	a5,a5,-1
    8000349c:	0007871b          	sext.w	a4,a5
    800034a0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034a2:	e71d                	bnez	a4,800034d0 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034a4:	68b8                	ld	a4,80(s1)
    800034a6:	64bc                	ld	a5,72(s1)
    800034a8:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800034aa:	68b8                	ld	a4,80(s1)
    800034ac:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034ae:	0001b797          	auipc	a5,0x1b
    800034b2:	66a78793          	addi	a5,a5,1642 # 8001eb18 <bcache+0x8000>
    800034b6:	2b87b703          	ld	a4,696(a5)
    800034ba:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800034bc:	0001c717          	auipc	a4,0x1c
    800034c0:	8c470713          	addi	a4,a4,-1852 # 8001ed80 <bcache+0x8268>
    800034c4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800034c6:	2b87b703          	ld	a4,696(a5)
    800034ca:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800034cc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800034d0:	00013517          	auipc	a0,0x13
    800034d4:	64850513          	addi	a0,a0,1608 # 80016b18 <bcache>
    800034d8:	ffffe097          	auipc	ra,0xffffe
    800034dc:	876080e7          	jalr	-1930(ra) # 80000d4e <release>
}
    800034e0:	60e2                	ld	ra,24(sp)
    800034e2:	6442                	ld	s0,16(sp)
    800034e4:	64a2                	ld	s1,8(sp)
    800034e6:	6902                	ld	s2,0(sp)
    800034e8:	6105                	addi	sp,sp,32
    800034ea:	8082                	ret
    panic("brelse");
    800034ec:	00005517          	auipc	a0,0x5
    800034f0:	17c50513          	addi	a0,a0,380 # 80008668 <syscalls+0x108>
    800034f4:	ffffd097          	auipc	ra,0xffffd
    800034f8:	048080e7          	jalr	72(ra) # 8000053c <panic>

00000000800034fc <bpin>:

void
bpin(struct buf *b) {
    800034fc:	1101                	addi	sp,sp,-32
    800034fe:	ec06                	sd	ra,24(sp)
    80003500:	e822                	sd	s0,16(sp)
    80003502:	e426                	sd	s1,8(sp)
    80003504:	1000                	addi	s0,sp,32
    80003506:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003508:	00013517          	auipc	a0,0x13
    8000350c:	61050513          	addi	a0,a0,1552 # 80016b18 <bcache>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	78a080e7          	jalr	1930(ra) # 80000c9a <acquire>
  b->refcnt++;
    80003518:	40bc                	lw	a5,64(s1)
    8000351a:	2785                	addiw	a5,a5,1
    8000351c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000351e:	00013517          	auipc	a0,0x13
    80003522:	5fa50513          	addi	a0,a0,1530 # 80016b18 <bcache>
    80003526:	ffffe097          	auipc	ra,0xffffe
    8000352a:	828080e7          	jalr	-2008(ra) # 80000d4e <release>
}
    8000352e:	60e2                	ld	ra,24(sp)
    80003530:	6442                	ld	s0,16(sp)
    80003532:	64a2                	ld	s1,8(sp)
    80003534:	6105                	addi	sp,sp,32
    80003536:	8082                	ret

0000000080003538 <bunpin>:

void
bunpin(struct buf *b) {
    80003538:	1101                	addi	sp,sp,-32
    8000353a:	ec06                	sd	ra,24(sp)
    8000353c:	e822                	sd	s0,16(sp)
    8000353e:	e426                	sd	s1,8(sp)
    80003540:	1000                	addi	s0,sp,32
    80003542:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003544:	00013517          	auipc	a0,0x13
    80003548:	5d450513          	addi	a0,a0,1492 # 80016b18 <bcache>
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	74e080e7          	jalr	1870(ra) # 80000c9a <acquire>
  b->refcnt--;
    80003554:	40bc                	lw	a5,64(s1)
    80003556:	37fd                	addiw	a5,a5,-1
    80003558:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000355a:	00013517          	auipc	a0,0x13
    8000355e:	5be50513          	addi	a0,a0,1470 # 80016b18 <bcache>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	7ec080e7          	jalr	2028(ra) # 80000d4e <release>
}
    8000356a:	60e2                	ld	ra,24(sp)
    8000356c:	6442                	ld	s0,16(sp)
    8000356e:	64a2                	ld	s1,8(sp)
    80003570:	6105                	addi	sp,sp,32
    80003572:	8082                	ret

0000000080003574 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003574:	1101                	addi	sp,sp,-32
    80003576:	ec06                	sd	ra,24(sp)
    80003578:	e822                	sd	s0,16(sp)
    8000357a:	e426                	sd	s1,8(sp)
    8000357c:	e04a                	sd	s2,0(sp)
    8000357e:	1000                	addi	s0,sp,32
    80003580:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003582:	00d5d59b          	srliw	a1,a1,0xd
    80003586:	0001c797          	auipc	a5,0x1c
    8000358a:	c6e7a783          	lw	a5,-914(a5) # 8001f1f4 <sb+0x1c>
    8000358e:	9dbd                	addw	a1,a1,a5
    80003590:	00000097          	auipc	ra,0x0
    80003594:	da0080e7          	jalr	-608(ra) # 80003330 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003598:	0074f713          	andi	a4,s1,7
    8000359c:	4785                	li	a5,1
    8000359e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035a2:	14ce                	slli	s1,s1,0x33
    800035a4:	90d9                	srli	s1,s1,0x36
    800035a6:	00950733          	add	a4,a0,s1
    800035aa:	05874703          	lbu	a4,88(a4)
    800035ae:	00e7f6b3          	and	a3,a5,a4
    800035b2:	c69d                	beqz	a3,800035e0 <bfree+0x6c>
    800035b4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800035b6:	94aa                	add	s1,s1,a0
    800035b8:	fff7c793          	not	a5,a5
    800035bc:	8f7d                	and	a4,a4,a5
    800035be:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800035c2:	00001097          	auipc	ra,0x1
    800035c6:	0f6080e7          	jalr	246(ra) # 800046b8 <log_write>
  brelse(bp);
    800035ca:	854a                	mv	a0,s2
    800035cc:	00000097          	auipc	ra,0x0
    800035d0:	e94080e7          	jalr	-364(ra) # 80003460 <brelse>
}
    800035d4:	60e2                	ld	ra,24(sp)
    800035d6:	6442                	ld	s0,16(sp)
    800035d8:	64a2                	ld	s1,8(sp)
    800035da:	6902                	ld	s2,0(sp)
    800035dc:	6105                	addi	sp,sp,32
    800035de:	8082                	ret
    panic("freeing free block");
    800035e0:	00005517          	auipc	a0,0x5
    800035e4:	09050513          	addi	a0,a0,144 # 80008670 <syscalls+0x110>
    800035e8:	ffffd097          	auipc	ra,0xffffd
    800035ec:	f54080e7          	jalr	-172(ra) # 8000053c <panic>

00000000800035f0 <balloc>:
{
    800035f0:	711d                	addi	sp,sp,-96
    800035f2:	ec86                	sd	ra,88(sp)
    800035f4:	e8a2                	sd	s0,80(sp)
    800035f6:	e4a6                	sd	s1,72(sp)
    800035f8:	e0ca                	sd	s2,64(sp)
    800035fa:	fc4e                	sd	s3,56(sp)
    800035fc:	f852                	sd	s4,48(sp)
    800035fe:	f456                	sd	s5,40(sp)
    80003600:	f05a                	sd	s6,32(sp)
    80003602:	ec5e                	sd	s7,24(sp)
    80003604:	e862                	sd	s8,16(sp)
    80003606:	e466                	sd	s9,8(sp)
    80003608:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000360a:	0001c797          	auipc	a5,0x1c
    8000360e:	bd27a783          	lw	a5,-1070(a5) # 8001f1dc <sb+0x4>
    80003612:	cff5                	beqz	a5,8000370e <balloc+0x11e>
    80003614:	8baa                	mv	s7,a0
    80003616:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003618:	0001cb17          	auipc	s6,0x1c
    8000361c:	bc0b0b13          	addi	s6,s6,-1088 # 8001f1d8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003620:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003622:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003624:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003626:	6c89                	lui	s9,0x2
    80003628:	a061                	j	800036b0 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000362a:	97ca                	add	a5,a5,s2
    8000362c:	8e55                	or	a2,a2,a3
    8000362e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003632:	854a                	mv	a0,s2
    80003634:	00001097          	auipc	ra,0x1
    80003638:	084080e7          	jalr	132(ra) # 800046b8 <log_write>
        brelse(bp);
    8000363c:	854a                	mv	a0,s2
    8000363e:	00000097          	auipc	ra,0x0
    80003642:	e22080e7          	jalr	-478(ra) # 80003460 <brelse>
  bp = bread(dev, bno);
    80003646:	85a6                	mv	a1,s1
    80003648:	855e                	mv	a0,s7
    8000364a:	00000097          	auipc	ra,0x0
    8000364e:	ce6080e7          	jalr	-794(ra) # 80003330 <bread>
    80003652:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003654:	40000613          	li	a2,1024
    80003658:	4581                	li	a1,0
    8000365a:	05850513          	addi	a0,a0,88
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	738080e7          	jalr	1848(ra) # 80000d96 <memset>
  log_write(bp);
    80003666:	854a                	mv	a0,s2
    80003668:	00001097          	auipc	ra,0x1
    8000366c:	050080e7          	jalr	80(ra) # 800046b8 <log_write>
  brelse(bp);
    80003670:	854a                	mv	a0,s2
    80003672:	00000097          	auipc	ra,0x0
    80003676:	dee080e7          	jalr	-530(ra) # 80003460 <brelse>
}
    8000367a:	8526                	mv	a0,s1
    8000367c:	60e6                	ld	ra,88(sp)
    8000367e:	6446                	ld	s0,80(sp)
    80003680:	64a6                	ld	s1,72(sp)
    80003682:	6906                	ld	s2,64(sp)
    80003684:	79e2                	ld	s3,56(sp)
    80003686:	7a42                	ld	s4,48(sp)
    80003688:	7aa2                	ld	s5,40(sp)
    8000368a:	7b02                	ld	s6,32(sp)
    8000368c:	6be2                	ld	s7,24(sp)
    8000368e:	6c42                	ld	s8,16(sp)
    80003690:	6ca2                	ld	s9,8(sp)
    80003692:	6125                	addi	sp,sp,96
    80003694:	8082                	ret
    brelse(bp);
    80003696:	854a                	mv	a0,s2
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	dc8080e7          	jalr	-568(ra) # 80003460 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036a0:	015c87bb          	addw	a5,s9,s5
    800036a4:	00078a9b          	sext.w	s5,a5
    800036a8:	004b2703          	lw	a4,4(s6)
    800036ac:	06eaf163          	bgeu	s5,a4,8000370e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800036b0:	41fad79b          	sraiw	a5,s5,0x1f
    800036b4:	0137d79b          	srliw	a5,a5,0x13
    800036b8:	015787bb          	addw	a5,a5,s5
    800036bc:	40d7d79b          	sraiw	a5,a5,0xd
    800036c0:	01cb2583          	lw	a1,28(s6)
    800036c4:	9dbd                	addw	a1,a1,a5
    800036c6:	855e                	mv	a0,s7
    800036c8:	00000097          	auipc	ra,0x0
    800036cc:	c68080e7          	jalr	-920(ra) # 80003330 <bread>
    800036d0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036d2:	004b2503          	lw	a0,4(s6)
    800036d6:	000a849b          	sext.w	s1,s5
    800036da:	8762                	mv	a4,s8
    800036dc:	faa4fde3          	bgeu	s1,a0,80003696 <balloc+0xa6>
      m = 1 << (bi % 8);
    800036e0:	00777693          	andi	a3,a4,7
    800036e4:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036e8:	41f7579b          	sraiw	a5,a4,0x1f
    800036ec:	01d7d79b          	srliw	a5,a5,0x1d
    800036f0:	9fb9                	addw	a5,a5,a4
    800036f2:	4037d79b          	sraiw	a5,a5,0x3
    800036f6:	00f90633          	add	a2,s2,a5
    800036fa:	05864603          	lbu	a2,88(a2)
    800036fe:	00c6f5b3          	and	a1,a3,a2
    80003702:	d585                	beqz	a1,8000362a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003704:	2705                	addiw	a4,a4,1
    80003706:	2485                	addiw	s1,s1,1
    80003708:	fd471ae3          	bne	a4,s4,800036dc <balloc+0xec>
    8000370c:	b769                	j	80003696 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000370e:	00005517          	auipc	a0,0x5
    80003712:	f7a50513          	addi	a0,a0,-134 # 80008688 <syscalls+0x128>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	e82080e7          	jalr	-382(ra) # 80000598 <printf>
  return 0;
    8000371e:	4481                	li	s1,0
    80003720:	bfa9                	j	8000367a <balloc+0x8a>

0000000080003722 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003722:	7179                	addi	sp,sp,-48
    80003724:	f406                	sd	ra,40(sp)
    80003726:	f022                	sd	s0,32(sp)
    80003728:	ec26                	sd	s1,24(sp)
    8000372a:	e84a                	sd	s2,16(sp)
    8000372c:	e44e                	sd	s3,8(sp)
    8000372e:	e052                	sd	s4,0(sp)
    80003730:	1800                	addi	s0,sp,48
    80003732:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003734:	47ad                	li	a5,11
    80003736:	02b7e863          	bltu	a5,a1,80003766 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000373a:	02059793          	slli	a5,a1,0x20
    8000373e:	01e7d593          	srli	a1,a5,0x1e
    80003742:	00b504b3          	add	s1,a0,a1
    80003746:	0504a903          	lw	s2,80(s1)
    8000374a:	06091e63          	bnez	s2,800037c6 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000374e:	4108                	lw	a0,0(a0)
    80003750:	00000097          	auipc	ra,0x0
    80003754:	ea0080e7          	jalr	-352(ra) # 800035f0 <balloc>
    80003758:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000375c:	06090563          	beqz	s2,800037c6 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003760:	0524a823          	sw	s2,80(s1)
    80003764:	a08d                	j	800037c6 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003766:	ff45849b          	addiw	s1,a1,-12
    8000376a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000376e:	0ff00793          	li	a5,255
    80003772:	08e7e563          	bltu	a5,a4,800037fc <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003776:	08052903          	lw	s2,128(a0)
    8000377a:	00091d63          	bnez	s2,80003794 <bmap+0x72>
      addr = balloc(ip->dev);
    8000377e:	4108                	lw	a0,0(a0)
    80003780:	00000097          	auipc	ra,0x0
    80003784:	e70080e7          	jalr	-400(ra) # 800035f0 <balloc>
    80003788:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000378c:	02090d63          	beqz	s2,800037c6 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003790:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003794:	85ca                	mv	a1,s2
    80003796:	0009a503          	lw	a0,0(s3)
    8000379a:	00000097          	auipc	ra,0x0
    8000379e:	b96080e7          	jalr	-1130(ra) # 80003330 <bread>
    800037a2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037a4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037a8:	02049713          	slli	a4,s1,0x20
    800037ac:	01e75593          	srli	a1,a4,0x1e
    800037b0:	00b784b3          	add	s1,a5,a1
    800037b4:	0004a903          	lw	s2,0(s1)
    800037b8:	02090063          	beqz	s2,800037d8 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800037bc:	8552                	mv	a0,s4
    800037be:	00000097          	auipc	ra,0x0
    800037c2:	ca2080e7          	jalr	-862(ra) # 80003460 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037c6:	854a                	mv	a0,s2
    800037c8:	70a2                	ld	ra,40(sp)
    800037ca:	7402                	ld	s0,32(sp)
    800037cc:	64e2                	ld	s1,24(sp)
    800037ce:	6942                	ld	s2,16(sp)
    800037d0:	69a2                	ld	s3,8(sp)
    800037d2:	6a02                	ld	s4,0(sp)
    800037d4:	6145                	addi	sp,sp,48
    800037d6:	8082                	ret
      addr = balloc(ip->dev);
    800037d8:	0009a503          	lw	a0,0(s3)
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	e14080e7          	jalr	-492(ra) # 800035f0 <balloc>
    800037e4:	0005091b          	sext.w	s2,a0
      if(addr){
    800037e8:	fc090ae3          	beqz	s2,800037bc <bmap+0x9a>
        a[bn] = addr;
    800037ec:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800037f0:	8552                	mv	a0,s4
    800037f2:	00001097          	auipc	ra,0x1
    800037f6:	ec6080e7          	jalr	-314(ra) # 800046b8 <log_write>
    800037fa:	b7c9                	j	800037bc <bmap+0x9a>
  panic("bmap: out of range");
    800037fc:	00005517          	auipc	a0,0x5
    80003800:	ea450513          	addi	a0,a0,-348 # 800086a0 <syscalls+0x140>
    80003804:	ffffd097          	auipc	ra,0xffffd
    80003808:	d38080e7          	jalr	-712(ra) # 8000053c <panic>

000000008000380c <iget>:
{
    8000380c:	7179                	addi	sp,sp,-48
    8000380e:	f406                	sd	ra,40(sp)
    80003810:	f022                	sd	s0,32(sp)
    80003812:	ec26                	sd	s1,24(sp)
    80003814:	e84a                	sd	s2,16(sp)
    80003816:	e44e                	sd	s3,8(sp)
    80003818:	e052                	sd	s4,0(sp)
    8000381a:	1800                	addi	s0,sp,48
    8000381c:	89aa                	mv	s3,a0
    8000381e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003820:	0001c517          	auipc	a0,0x1c
    80003824:	9d850513          	addi	a0,a0,-1576 # 8001f1f8 <itable>
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	472080e7          	jalr	1138(ra) # 80000c9a <acquire>
  empty = 0;
    80003830:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003832:	0001c497          	auipc	s1,0x1c
    80003836:	9de48493          	addi	s1,s1,-1570 # 8001f210 <itable+0x18>
    8000383a:	0001d697          	auipc	a3,0x1d
    8000383e:	46668693          	addi	a3,a3,1126 # 80020ca0 <log>
    80003842:	a039                	j	80003850 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003844:	02090b63          	beqz	s2,8000387a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003848:	08848493          	addi	s1,s1,136
    8000384c:	02d48a63          	beq	s1,a3,80003880 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003850:	449c                	lw	a5,8(s1)
    80003852:	fef059e3          	blez	a5,80003844 <iget+0x38>
    80003856:	4098                	lw	a4,0(s1)
    80003858:	ff3716e3          	bne	a4,s3,80003844 <iget+0x38>
    8000385c:	40d8                	lw	a4,4(s1)
    8000385e:	ff4713e3          	bne	a4,s4,80003844 <iget+0x38>
      ip->ref++;
    80003862:	2785                	addiw	a5,a5,1
    80003864:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003866:	0001c517          	auipc	a0,0x1c
    8000386a:	99250513          	addi	a0,a0,-1646 # 8001f1f8 <itable>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	4e0080e7          	jalr	1248(ra) # 80000d4e <release>
      return ip;
    80003876:	8926                	mv	s2,s1
    80003878:	a03d                	j	800038a6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000387a:	f7f9                	bnez	a5,80003848 <iget+0x3c>
    8000387c:	8926                	mv	s2,s1
    8000387e:	b7e9                	j	80003848 <iget+0x3c>
  if(empty == 0)
    80003880:	02090c63          	beqz	s2,800038b8 <iget+0xac>
  ip->dev = dev;
    80003884:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003888:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000388c:	4785                	li	a5,1
    8000388e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003892:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003896:	0001c517          	auipc	a0,0x1c
    8000389a:	96250513          	addi	a0,a0,-1694 # 8001f1f8 <itable>
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	4b0080e7          	jalr	1200(ra) # 80000d4e <release>
}
    800038a6:	854a                	mv	a0,s2
    800038a8:	70a2                	ld	ra,40(sp)
    800038aa:	7402                	ld	s0,32(sp)
    800038ac:	64e2                	ld	s1,24(sp)
    800038ae:	6942                	ld	s2,16(sp)
    800038b0:	69a2                	ld	s3,8(sp)
    800038b2:	6a02                	ld	s4,0(sp)
    800038b4:	6145                	addi	sp,sp,48
    800038b6:	8082                	ret
    panic("iget: no inodes");
    800038b8:	00005517          	auipc	a0,0x5
    800038bc:	e0050513          	addi	a0,a0,-512 # 800086b8 <syscalls+0x158>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	c7c080e7          	jalr	-900(ra) # 8000053c <panic>

00000000800038c8 <fsinit>:
fsinit(int dev) {
    800038c8:	7179                	addi	sp,sp,-48
    800038ca:	f406                	sd	ra,40(sp)
    800038cc:	f022                	sd	s0,32(sp)
    800038ce:	ec26                	sd	s1,24(sp)
    800038d0:	e84a                	sd	s2,16(sp)
    800038d2:	e44e                	sd	s3,8(sp)
    800038d4:	1800                	addi	s0,sp,48
    800038d6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800038d8:	4585                	li	a1,1
    800038da:	00000097          	auipc	ra,0x0
    800038de:	a56080e7          	jalr	-1450(ra) # 80003330 <bread>
    800038e2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038e4:	0001c997          	auipc	s3,0x1c
    800038e8:	8f498993          	addi	s3,s3,-1804 # 8001f1d8 <sb>
    800038ec:	02000613          	li	a2,32
    800038f0:	05850593          	addi	a1,a0,88
    800038f4:	854e                	mv	a0,s3
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	4fc080e7          	jalr	1276(ra) # 80000df2 <memmove>
  brelse(bp);
    800038fe:	8526                	mv	a0,s1
    80003900:	00000097          	auipc	ra,0x0
    80003904:	b60080e7          	jalr	-1184(ra) # 80003460 <brelse>
  if(sb.magic != FSMAGIC)
    80003908:	0009a703          	lw	a4,0(s3)
    8000390c:	102037b7          	lui	a5,0x10203
    80003910:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003914:	02f71263          	bne	a4,a5,80003938 <fsinit+0x70>
  initlog(dev, &sb);
    80003918:	0001c597          	auipc	a1,0x1c
    8000391c:	8c058593          	addi	a1,a1,-1856 # 8001f1d8 <sb>
    80003920:	854a                	mv	a0,s2
    80003922:	00001097          	auipc	ra,0x1
    80003926:	b2c080e7          	jalr	-1236(ra) # 8000444e <initlog>
}
    8000392a:	70a2                	ld	ra,40(sp)
    8000392c:	7402                	ld	s0,32(sp)
    8000392e:	64e2                	ld	s1,24(sp)
    80003930:	6942                	ld	s2,16(sp)
    80003932:	69a2                	ld	s3,8(sp)
    80003934:	6145                	addi	sp,sp,48
    80003936:	8082                	ret
    panic("invalid file system");
    80003938:	00005517          	auipc	a0,0x5
    8000393c:	d9050513          	addi	a0,a0,-624 # 800086c8 <syscalls+0x168>
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	bfc080e7          	jalr	-1028(ra) # 8000053c <panic>

0000000080003948 <iinit>:
{
    80003948:	7179                	addi	sp,sp,-48
    8000394a:	f406                	sd	ra,40(sp)
    8000394c:	f022                	sd	s0,32(sp)
    8000394e:	ec26                	sd	s1,24(sp)
    80003950:	e84a                	sd	s2,16(sp)
    80003952:	e44e                	sd	s3,8(sp)
    80003954:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003956:	00005597          	auipc	a1,0x5
    8000395a:	d8a58593          	addi	a1,a1,-630 # 800086e0 <syscalls+0x180>
    8000395e:	0001c517          	auipc	a0,0x1c
    80003962:	89a50513          	addi	a0,a0,-1894 # 8001f1f8 <itable>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	2a4080e7          	jalr	676(ra) # 80000c0a <initlock>
  for(i = 0; i < NINODE; i++) {
    8000396e:	0001c497          	auipc	s1,0x1c
    80003972:	8b248493          	addi	s1,s1,-1870 # 8001f220 <itable+0x28>
    80003976:	0001d997          	auipc	s3,0x1d
    8000397a:	33a98993          	addi	s3,s3,826 # 80020cb0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000397e:	00005917          	auipc	s2,0x5
    80003982:	d6a90913          	addi	s2,s2,-662 # 800086e8 <syscalls+0x188>
    80003986:	85ca                	mv	a1,s2
    80003988:	8526                	mv	a0,s1
    8000398a:	00001097          	auipc	ra,0x1
    8000398e:	e12080e7          	jalr	-494(ra) # 8000479c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003992:	08848493          	addi	s1,s1,136
    80003996:	ff3498e3          	bne	s1,s3,80003986 <iinit+0x3e>
}
    8000399a:	70a2                	ld	ra,40(sp)
    8000399c:	7402                	ld	s0,32(sp)
    8000399e:	64e2                	ld	s1,24(sp)
    800039a0:	6942                	ld	s2,16(sp)
    800039a2:	69a2                	ld	s3,8(sp)
    800039a4:	6145                	addi	sp,sp,48
    800039a6:	8082                	ret

00000000800039a8 <ialloc>:
{
    800039a8:	7139                	addi	sp,sp,-64
    800039aa:	fc06                	sd	ra,56(sp)
    800039ac:	f822                	sd	s0,48(sp)
    800039ae:	f426                	sd	s1,40(sp)
    800039b0:	f04a                	sd	s2,32(sp)
    800039b2:	ec4e                	sd	s3,24(sp)
    800039b4:	e852                	sd	s4,16(sp)
    800039b6:	e456                	sd	s5,8(sp)
    800039b8:	e05a                	sd	s6,0(sp)
    800039ba:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800039bc:	0001c717          	auipc	a4,0x1c
    800039c0:	82872703          	lw	a4,-2008(a4) # 8001f1e4 <sb+0xc>
    800039c4:	4785                	li	a5,1
    800039c6:	04e7f863          	bgeu	a5,a4,80003a16 <ialloc+0x6e>
    800039ca:	8aaa                	mv	s5,a0
    800039cc:	8b2e                	mv	s6,a1
    800039ce:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039d0:	0001ca17          	auipc	s4,0x1c
    800039d4:	808a0a13          	addi	s4,s4,-2040 # 8001f1d8 <sb>
    800039d8:	00495593          	srli	a1,s2,0x4
    800039dc:	018a2783          	lw	a5,24(s4)
    800039e0:	9dbd                	addw	a1,a1,a5
    800039e2:	8556                	mv	a0,s5
    800039e4:	00000097          	auipc	ra,0x0
    800039e8:	94c080e7          	jalr	-1716(ra) # 80003330 <bread>
    800039ec:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039ee:	05850993          	addi	s3,a0,88
    800039f2:	00f97793          	andi	a5,s2,15
    800039f6:	079a                	slli	a5,a5,0x6
    800039f8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039fa:	00099783          	lh	a5,0(s3)
    800039fe:	cf9d                	beqz	a5,80003a3c <ialloc+0x94>
    brelse(bp);
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	a60080e7          	jalr	-1440(ra) # 80003460 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a08:	0905                	addi	s2,s2,1
    80003a0a:	00ca2703          	lw	a4,12(s4)
    80003a0e:	0009079b          	sext.w	a5,s2
    80003a12:	fce7e3e3          	bltu	a5,a4,800039d8 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003a16:	00005517          	auipc	a0,0x5
    80003a1a:	cda50513          	addi	a0,a0,-806 # 800086f0 <syscalls+0x190>
    80003a1e:	ffffd097          	auipc	ra,0xffffd
    80003a22:	b7a080e7          	jalr	-1158(ra) # 80000598 <printf>
  return 0;
    80003a26:	4501                	li	a0,0
}
    80003a28:	70e2                	ld	ra,56(sp)
    80003a2a:	7442                	ld	s0,48(sp)
    80003a2c:	74a2                	ld	s1,40(sp)
    80003a2e:	7902                	ld	s2,32(sp)
    80003a30:	69e2                	ld	s3,24(sp)
    80003a32:	6a42                	ld	s4,16(sp)
    80003a34:	6aa2                	ld	s5,8(sp)
    80003a36:	6b02                	ld	s6,0(sp)
    80003a38:	6121                	addi	sp,sp,64
    80003a3a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003a3c:	04000613          	li	a2,64
    80003a40:	4581                	li	a1,0
    80003a42:	854e                	mv	a0,s3
    80003a44:	ffffd097          	auipc	ra,0xffffd
    80003a48:	352080e7          	jalr	850(ra) # 80000d96 <memset>
      dip->type = type;
    80003a4c:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a50:	8526                	mv	a0,s1
    80003a52:	00001097          	auipc	ra,0x1
    80003a56:	c66080e7          	jalr	-922(ra) # 800046b8 <log_write>
      brelse(bp);
    80003a5a:	8526                	mv	a0,s1
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	a04080e7          	jalr	-1532(ra) # 80003460 <brelse>
      return iget(dev, inum);
    80003a64:	0009059b          	sext.w	a1,s2
    80003a68:	8556                	mv	a0,s5
    80003a6a:	00000097          	auipc	ra,0x0
    80003a6e:	da2080e7          	jalr	-606(ra) # 8000380c <iget>
    80003a72:	bf5d                	j	80003a28 <ialloc+0x80>

0000000080003a74 <iupdate>:
{
    80003a74:	1101                	addi	sp,sp,-32
    80003a76:	ec06                	sd	ra,24(sp)
    80003a78:	e822                	sd	s0,16(sp)
    80003a7a:	e426                	sd	s1,8(sp)
    80003a7c:	e04a                	sd	s2,0(sp)
    80003a7e:	1000                	addi	s0,sp,32
    80003a80:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a82:	415c                	lw	a5,4(a0)
    80003a84:	0047d79b          	srliw	a5,a5,0x4
    80003a88:	0001b597          	auipc	a1,0x1b
    80003a8c:	7685a583          	lw	a1,1896(a1) # 8001f1f0 <sb+0x18>
    80003a90:	9dbd                	addw	a1,a1,a5
    80003a92:	4108                	lw	a0,0(a0)
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	89c080e7          	jalr	-1892(ra) # 80003330 <bread>
    80003a9c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a9e:	05850793          	addi	a5,a0,88
    80003aa2:	40d8                	lw	a4,4(s1)
    80003aa4:	8b3d                	andi	a4,a4,15
    80003aa6:	071a                	slli	a4,a4,0x6
    80003aa8:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003aaa:	04449703          	lh	a4,68(s1)
    80003aae:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003ab2:	04649703          	lh	a4,70(s1)
    80003ab6:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003aba:	04849703          	lh	a4,72(s1)
    80003abe:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003ac2:	04a49703          	lh	a4,74(s1)
    80003ac6:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003aca:	44f8                	lw	a4,76(s1)
    80003acc:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ace:	03400613          	li	a2,52
    80003ad2:	05048593          	addi	a1,s1,80
    80003ad6:	00c78513          	addi	a0,a5,12
    80003ada:	ffffd097          	auipc	ra,0xffffd
    80003ade:	318080e7          	jalr	792(ra) # 80000df2 <memmove>
  log_write(bp);
    80003ae2:	854a                	mv	a0,s2
    80003ae4:	00001097          	auipc	ra,0x1
    80003ae8:	bd4080e7          	jalr	-1068(ra) # 800046b8 <log_write>
  brelse(bp);
    80003aec:	854a                	mv	a0,s2
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	972080e7          	jalr	-1678(ra) # 80003460 <brelse>
}
    80003af6:	60e2                	ld	ra,24(sp)
    80003af8:	6442                	ld	s0,16(sp)
    80003afa:	64a2                	ld	s1,8(sp)
    80003afc:	6902                	ld	s2,0(sp)
    80003afe:	6105                	addi	sp,sp,32
    80003b00:	8082                	ret

0000000080003b02 <idup>:
{
    80003b02:	1101                	addi	sp,sp,-32
    80003b04:	ec06                	sd	ra,24(sp)
    80003b06:	e822                	sd	s0,16(sp)
    80003b08:	e426                	sd	s1,8(sp)
    80003b0a:	1000                	addi	s0,sp,32
    80003b0c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b0e:	0001b517          	auipc	a0,0x1b
    80003b12:	6ea50513          	addi	a0,a0,1770 # 8001f1f8 <itable>
    80003b16:	ffffd097          	auipc	ra,0xffffd
    80003b1a:	184080e7          	jalr	388(ra) # 80000c9a <acquire>
  ip->ref++;
    80003b1e:	449c                	lw	a5,8(s1)
    80003b20:	2785                	addiw	a5,a5,1
    80003b22:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b24:	0001b517          	auipc	a0,0x1b
    80003b28:	6d450513          	addi	a0,a0,1748 # 8001f1f8 <itable>
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	222080e7          	jalr	546(ra) # 80000d4e <release>
}
    80003b34:	8526                	mv	a0,s1
    80003b36:	60e2                	ld	ra,24(sp)
    80003b38:	6442                	ld	s0,16(sp)
    80003b3a:	64a2                	ld	s1,8(sp)
    80003b3c:	6105                	addi	sp,sp,32
    80003b3e:	8082                	ret

0000000080003b40 <ilock>:
{
    80003b40:	1101                	addi	sp,sp,-32
    80003b42:	ec06                	sd	ra,24(sp)
    80003b44:	e822                	sd	s0,16(sp)
    80003b46:	e426                	sd	s1,8(sp)
    80003b48:	e04a                	sd	s2,0(sp)
    80003b4a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b4c:	c115                	beqz	a0,80003b70 <ilock+0x30>
    80003b4e:	84aa                	mv	s1,a0
    80003b50:	451c                	lw	a5,8(a0)
    80003b52:	00f05f63          	blez	a5,80003b70 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b56:	0541                	addi	a0,a0,16
    80003b58:	00001097          	auipc	ra,0x1
    80003b5c:	c7e080e7          	jalr	-898(ra) # 800047d6 <acquiresleep>
  if(ip->valid == 0){
    80003b60:	40bc                	lw	a5,64(s1)
    80003b62:	cf99                	beqz	a5,80003b80 <ilock+0x40>
}
    80003b64:	60e2                	ld	ra,24(sp)
    80003b66:	6442                	ld	s0,16(sp)
    80003b68:	64a2                	ld	s1,8(sp)
    80003b6a:	6902                	ld	s2,0(sp)
    80003b6c:	6105                	addi	sp,sp,32
    80003b6e:	8082                	ret
    panic("ilock");
    80003b70:	00005517          	auipc	a0,0x5
    80003b74:	b9850513          	addi	a0,a0,-1128 # 80008708 <syscalls+0x1a8>
    80003b78:	ffffd097          	auipc	ra,0xffffd
    80003b7c:	9c4080e7          	jalr	-1596(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b80:	40dc                	lw	a5,4(s1)
    80003b82:	0047d79b          	srliw	a5,a5,0x4
    80003b86:	0001b597          	auipc	a1,0x1b
    80003b8a:	66a5a583          	lw	a1,1642(a1) # 8001f1f0 <sb+0x18>
    80003b8e:	9dbd                	addw	a1,a1,a5
    80003b90:	4088                	lw	a0,0(s1)
    80003b92:	fffff097          	auipc	ra,0xfffff
    80003b96:	79e080e7          	jalr	1950(ra) # 80003330 <bread>
    80003b9a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b9c:	05850593          	addi	a1,a0,88
    80003ba0:	40dc                	lw	a5,4(s1)
    80003ba2:	8bbd                	andi	a5,a5,15
    80003ba4:	079a                	slli	a5,a5,0x6
    80003ba6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ba8:	00059783          	lh	a5,0(a1)
    80003bac:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003bb0:	00259783          	lh	a5,2(a1)
    80003bb4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003bb8:	00459783          	lh	a5,4(a1)
    80003bbc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003bc0:	00659783          	lh	a5,6(a1)
    80003bc4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003bc8:	459c                	lw	a5,8(a1)
    80003bca:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003bcc:	03400613          	li	a2,52
    80003bd0:	05b1                	addi	a1,a1,12
    80003bd2:	05048513          	addi	a0,s1,80
    80003bd6:	ffffd097          	auipc	ra,0xffffd
    80003bda:	21c080e7          	jalr	540(ra) # 80000df2 <memmove>
    brelse(bp);
    80003bde:	854a                	mv	a0,s2
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	880080e7          	jalr	-1920(ra) # 80003460 <brelse>
    ip->valid = 1;
    80003be8:	4785                	li	a5,1
    80003bea:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003bec:	04449783          	lh	a5,68(s1)
    80003bf0:	fbb5                	bnez	a5,80003b64 <ilock+0x24>
      panic("ilock: no type");
    80003bf2:	00005517          	auipc	a0,0x5
    80003bf6:	b1e50513          	addi	a0,a0,-1250 # 80008710 <syscalls+0x1b0>
    80003bfa:	ffffd097          	auipc	ra,0xffffd
    80003bfe:	942080e7          	jalr	-1726(ra) # 8000053c <panic>

0000000080003c02 <iunlock>:
{
    80003c02:	1101                	addi	sp,sp,-32
    80003c04:	ec06                	sd	ra,24(sp)
    80003c06:	e822                	sd	s0,16(sp)
    80003c08:	e426                	sd	s1,8(sp)
    80003c0a:	e04a                	sd	s2,0(sp)
    80003c0c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c0e:	c905                	beqz	a0,80003c3e <iunlock+0x3c>
    80003c10:	84aa                	mv	s1,a0
    80003c12:	01050913          	addi	s2,a0,16
    80003c16:	854a                	mv	a0,s2
    80003c18:	00001097          	auipc	ra,0x1
    80003c1c:	c58080e7          	jalr	-936(ra) # 80004870 <holdingsleep>
    80003c20:	cd19                	beqz	a0,80003c3e <iunlock+0x3c>
    80003c22:	449c                	lw	a5,8(s1)
    80003c24:	00f05d63          	blez	a5,80003c3e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c28:	854a                	mv	a0,s2
    80003c2a:	00001097          	auipc	ra,0x1
    80003c2e:	c02080e7          	jalr	-1022(ra) # 8000482c <releasesleep>
}
    80003c32:	60e2                	ld	ra,24(sp)
    80003c34:	6442                	ld	s0,16(sp)
    80003c36:	64a2                	ld	s1,8(sp)
    80003c38:	6902                	ld	s2,0(sp)
    80003c3a:	6105                	addi	sp,sp,32
    80003c3c:	8082                	ret
    panic("iunlock");
    80003c3e:	00005517          	auipc	a0,0x5
    80003c42:	ae250513          	addi	a0,a0,-1310 # 80008720 <syscalls+0x1c0>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	8f6080e7          	jalr	-1802(ra) # 8000053c <panic>

0000000080003c4e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c4e:	7179                	addi	sp,sp,-48
    80003c50:	f406                	sd	ra,40(sp)
    80003c52:	f022                	sd	s0,32(sp)
    80003c54:	ec26                	sd	s1,24(sp)
    80003c56:	e84a                	sd	s2,16(sp)
    80003c58:	e44e                	sd	s3,8(sp)
    80003c5a:	e052                	sd	s4,0(sp)
    80003c5c:	1800                	addi	s0,sp,48
    80003c5e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c60:	05050493          	addi	s1,a0,80
    80003c64:	08050913          	addi	s2,a0,128
    80003c68:	a021                	j	80003c70 <itrunc+0x22>
    80003c6a:	0491                	addi	s1,s1,4
    80003c6c:	01248d63          	beq	s1,s2,80003c86 <itrunc+0x38>
    if(ip->addrs[i]){
    80003c70:	408c                	lw	a1,0(s1)
    80003c72:	dde5                	beqz	a1,80003c6a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c74:	0009a503          	lw	a0,0(s3)
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	8fc080e7          	jalr	-1796(ra) # 80003574 <bfree>
      ip->addrs[i] = 0;
    80003c80:	0004a023          	sw	zero,0(s1)
    80003c84:	b7dd                	j	80003c6a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c86:	0809a583          	lw	a1,128(s3)
    80003c8a:	e185                	bnez	a1,80003caa <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c8c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c90:	854e                	mv	a0,s3
    80003c92:	00000097          	auipc	ra,0x0
    80003c96:	de2080e7          	jalr	-542(ra) # 80003a74 <iupdate>
}
    80003c9a:	70a2                	ld	ra,40(sp)
    80003c9c:	7402                	ld	s0,32(sp)
    80003c9e:	64e2                	ld	s1,24(sp)
    80003ca0:	6942                	ld	s2,16(sp)
    80003ca2:	69a2                	ld	s3,8(sp)
    80003ca4:	6a02                	ld	s4,0(sp)
    80003ca6:	6145                	addi	sp,sp,48
    80003ca8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003caa:	0009a503          	lw	a0,0(s3)
    80003cae:	fffff097          	auipc	ra,0xfffff
    80003cb2:	682080e7          	jalr	1666(ra) # 80003330 <bread>
    80003cb6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003cb8:	05850493          	addi	s1,a0,88
    80003cbc:	45850913          	addi	s2,a0,1112
    80003cc0:	a021                	j	80003cc8 <itrunc+0x7a>
    80003cc2:	0491                	addi	s1,s1,4
    80003cc4:	01248b63          	beq	s1,s2,80003cda <itrunc+0x8c>
      if(a[j])
    80003cc8:	408c                	lw	a1,0(s1)
    80003cca:	dde5                	beqz	a1,80003cc2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003ccc:	0009a503          	lw	a0,0(s3)
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	8a4080e7          	jalr	-1884(ra) # 80003574 <bfree>
    80003cd8:	b7ed                	j	80003cc2 <itrunc+0x74>
    brelse(bp);
    80003cda:	8552                	mv	a0,s4
    80003cdc:	fffff097          	auipc	ra,0xfffff
    80003ce0:	784080e7          	jalr	1924(ra) # 80003460 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ce4:	0809a583          	lw	a1,128(s3)
    80003ce8:	0009a503          	lw	a0,0(s3)
    80003cec:	00000097          	auipc	ra,0x0
    80003cf0:	888080e7          	jalr	-1912(ra) # 80003574 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003cf4:	0809a023          	sw	zero,128(s3)
    80003cf8:	bf51                	j	80003c8c <itrunc+0x3e>

0000000080003cfa <iput>:
{
    80003cfa:	1101                	addi	sp,sp,-32
    80003cfc:	ec06                	sd	ra,24(sp)
    80003cfe:	e822                	sd	s0,16(sp)
    80003d00:	e426                	sd	s1,8(sp)
    80003d02:	e04a                	sd	s2,0(sp)
    80003d04:	1000                	addi	s0,sp,32
    80003d06:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d08:	0001b517          	auipc	a0,0x1b
    80003d0c:	4f050513          	addi	a0,a0,1264 # 8001f1f8 <itable>
    80003d10:	ffffd097          	auipc	ra,0xffffd
    80003d14:	f8a080e7          	jalr	-118(ra) # 80000c9a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d18:	4498                	lw	a4,8(s1)
    80003d1a:	4785                	li	a5,1
    80003d1c:	02f70363          	beq	a4,a5,80003d42 <iput+0x48>
  ip->ref--;
    80003d20:	449c                	lw	a5,8(s1)
    80003d22:	37fd                	addiw	a5,a5,-1
    80003d24:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d26:	0001b517          	auipc	a0,0x1b
    80003d2a:	4d250513          	addi	a0,a0,1234 # 8001f1f8 <itable>
    80003d2e:	ffffd097          	auipc	ra,0xffffd
    80003d32:	020080e7          	jalr	32(ra) # 80000d4e <release>
}
    80003d36:	60e2                	ld	ra,24(sp)
    80003d38:	6442                	ld	s0,16(sp)
    80003d3a:	64a2                	ld	s1,8(sp)
    80003d3c:	6902                	ld	s2,0(sp)
    80003d3e:	6105                	addi	sp,sp,32
    80003d40:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d42:	40bc                	lw	a5,64(s1)
    80003d44:	dff1                	beqz	a5,80003d20 <iput+0x26>
    80003d46:	04a49783          	lh	a5,74(s1)
    80003d4a:	fbf9                	bnez	a5,80003d20 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d4c:	01048913          	addi	s2,s1,16
    80003d50:	854a                	mv	a0,s2
    80003d52:	00001097          	auipc	ra,0x1
    80003d56:	a84080e7          	jalr	-1404(ra) # 800047d6 <acquiresleep>
    release(&itable.lock);
    80003d5a:	0001b517          	auipc	a0,0x1b
    80003d5e:	49e50513          	addi	a0,a0,1182 # 8001f1f8 <itable>
    80003d62:	ffffd097          	auipc	ra,0xffffd
    80003d66:	fec080e7          	jalr	-20(ra) # 80000d4e <release>
    itrunc(ip);
    80003d6a:	8526                	mv	a0,s1
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	ee2080e7          	jalr	-286(ra) # 80003c4e <itrunc>
    ip->type = 0;
    80003d74:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d78:	8526                	mv	a0,s1
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	cfa080e7          	jalr	-774(ra) # 80003a74 <iupdate>
    ip->valid = 0;
    80003d82:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d86:	854a                	mv	a0,s2
    80003d88:	00001097          	auipc	ra,0x1
    80003d8c:	aa4080e7          	jalr	-1372(ra) # 8000482c <releasesleep>
    acquire(&itable.lock);
    80003d90:	0001b517          	auipc	a0,0x1b
    80003d94:	46850513          	addi	a0,a0,1128 # 8001f1f8 <itable>
    80003d98:	ffffd097          	auipc	ra,0xffffd
    80003d9c:	f02080e7          	jalr	-254(ra) # 80000c9a <acquire>
    80003da0:	b741                	j	80003d20 <iput+0x26>

0000000080003da2 <iunlockput>:
{
    80003da2:	1101                	addi	sp,sp,-32
    80003da4:	ec06                	sd	ra,24(sp)
    80003da6:	e822                	sd	s0,16(sp)
    80003da8:	e426                	sd	s1,8(sp)
    80003daa:	1000                	addi	s0,sp,32
    80003dac:	84aa                	mv	s1,a0
  iunlock(ip);
    80003dae:	00000097          	auipc	ra,0x0
    80003db2:	e54080e7          	jalr	-428(ra) # 80003c02 <iunlock>
  iput(ip);
    80003db6:	8526                	mv	a0,s1
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	f42080e7          	jalr	-190(ra) # 80003cfa <iput>
}
    80003dc0:	60e2                	ld	ra,24(sp)
    80003dc2:	6442                	ld	s0,16(sp)
    80003dc4:	64a2                	ld	s1,8(sp)
    80003dc6:	6105                	addi	sp,sp,32
    80003dc8:	8082                	ret

0000000080003dca <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003dca:	1141                	addi	sp,sp,-16
    80003dcc:	e422                	sd	s0,8(sp)
    80003dce:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003dd0:	411c                	lw	a5,0(a0)
    80003dd2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003dd4:	415c                	lw	a5,4(a0)
    80003dd6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003dd8:	04451783          	lh	a5,68(a0)
    80003ddc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003de0:	04a51783          	lh	a5,74(a0)
    80003de4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003de8:	04c56783          	lwu	a5,76(a0)
    80003dec:	e99c                	sd	a5,16(a1)
}
    80003dee:	6422                	ld	s0,8(sp)
    80003df0:	0141                	addi	sp,sp,16
    80003df2:	8082                	ret

0000000080003df4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003df4:	457c                	lw	a5,76(a0)
    80003df6:	0ed7e963          	bltu	a5,a3,80003ee8 <readi+0xf4>
{
    80003dfa:	7159                	addi	sp,sp,-112
    80003dfc:	f486                	sd	ra,104(sp)
    80003dfe:	f0a2                	sd	s0,96(sp)
    80003e00:	eca6                	sd	s1,88(sp)
    80003e02:	e8ca                	sd	s2,80(sp)
    80003e04:	e4ce                	sd	s3,72(sp)
    80003e06:	e0d2                	sd	s4,64(sp)
    80003e08:	fc56                	sd	s5,56(sp)
    80003e0a:	f85a                	sd	s6,48(sp)
    80003e0c:	f45e                	sd	s7,40(sp)
    80003e0e:	f062                	sd	s8,32(sp)
    80003e10:	ec66                	sd	s9,24(sp)
    80003e12:	e86a                	sd	s10,16(sp)
    80003e14:	e46e                	sd	s11,8(sp)
    80003e16:	1880                	addi	s0,sp,112
    80003e18:	8b2a                	mv	s6,a0
    80003e1a:	8bae                	mv	s7,a1
    80003e1c:	8a32                	mv	s4,a2
    80003e1e:	84b6                	mv	s1,a3
    80003e20:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003e22:	9f35                	addw	a4,a4,a3
    return 0;
    80003e24:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e26:	0ad76063          	bltu	a4,a3,80003ec6 <readi+0xd2>
  if(off + n > ip->size)
    80003e2a:	00e7f463          	bgeu	a5,a4,80003e32 <readi+0x3e>
    n = ip->size - off;
    80003e2e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e32:	0a0a8963          	beqz	s5,80003ee4 <readi+0xf0>
    80003e36:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e38:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e3c:	5c7d                	li	s8,-1
    80003e3e:	a82d                	j	80003e78 <readi+0x84>
    80003e40:	020d1d93          	slli	s11,s10,0x20
    80003e44:	020ddd93          	srli	s11,s11,0x20
    80003e48:	05890613          	addi	a2,s2,88
    80003e4c:	86ee                	mv	a3,s11
    80003e4e:	963a                	add	a2,a2,a4
    80003e50:	85d2                	mv	a1,s4
    80003e52:	855e                	mv	a0,s7
    80003e54:	fffff097          	auipc	ra,0xfffff
    80003e58:	87e080e7          	jalr	-1922(ra) # 800026d2 <either_copyout>
    80003e5c:	05850d63          	beq	a0,s8,80003eb6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e60:	854a                	mv	a0,s2
    80003e62:	fffff097          	auipc	ra,0xfffff
    80003e66:	5fe080e7          	jalr	1534(ra) # 80003460 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e6a:	013d09bb          	addw	s3,s10,s3
    80003e6e:	009d04bb          	addw	s1,s10,s1
    80003e72:	9a6e                	add	s4,s4,s11
    80003e74:	0559f763          	bgeu	s3,s5,80003ec2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003e78:	00a4d59b          	srliw	a1,s1,0xa
    80003e7c:	855a                	mv	a0,s6
    80003e7e:	00000097          	auipc	ra,0x0
    80003e82:	8a4080e7          	jalr	-1884(ra) # 80003722 <bmap>
    80003e86:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e8a:	cd85                	beqz	a1,80003ec2 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003e8c:	000b2503          	lw	a0,0(s6)
    80003e90:	fffff097          	auipc	ra,0xfffff
    80003e94:	4a0080e7          	jalr	1184(ra) # 80003330 <bread>
    80003e98:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e9a:	3ff4f713          	andi	a4,s1,1023
    80003e9e:	40ec87bb          	subw	a5,s9,a4
    80003ea2:	413a86bb          	subw	a3,s5,s3
    80003ea6:	8d3e                	mv	s10,a5
    80003ea8:	2781                	sext.w	a5,a5
    80003eaa:	0006861b          	sext.w	a2,a3
    80003eae:	f8f679e3          	bgeu	a2,a5,80003e40 <readi+0x4c>
    80003eb2:	8d36                	mv	s10,a3
    80003eb4:	b771                	j	80003e40 <readi+0x4c>
      brelse(bp);
    80003eb6:	854a                	mv	a0,s2
    80003eb8:	fffff097          	auipc	ra,0xfffff
    80003ebc:	5a8080e7          	jalr	1448(ra) # 80003460 <brelse>
      tot = -1;
    80003ec0:	59fd                	li	s3,-1
  }
  return tot;
    80003ec2:	0009851b          	sext.w	a0,s3
}
    80003ec6:	70a6                	ld	ra,104(sp)
    80003ec8:	7406                	ld	s0,96(sp)
    80003eca:	64e6                	ld	s1,88(sp)
    80003ecc:	6946                	ld	s2,80(sp)
    80003ece:	69a6                	ld	s3,72(sp)
    80003ed0:	6a06                	ld	s4,64(sp)
    80003ed2:	7ae2                	ld	s5,56(sp)
    80003ed4:	7b42                	ld	s6,48(sp)
    80003ed6:	7ba2                	ld	s7,40(sp)
    80003ed8:	7c02                	ld	s8,32(sp)
    80003eda:	6ce2                	ld	s9,24(sp)
    80003edc:	6d42                	ld	s10,16(sp)
    80003ede:	6da2                	ld	s11,8(sp)
    80003ee0:	6165                	addi	sp,sp,112
    80003ee2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ee4:	89d6                	mv	s3,s5
    80003ee6:	bff1                	j	80003ec2 <readi+0xce>
    return 0;
    80003ee8:	4501                	li	a0,0
}
    80003eea:	8082                	ret

0000000080003eec <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003eec:	457c                	lw	a5,76(a0)
    80003eee:	10d7e863          	bltu	a5,a3,80003ffe <writei+0x112>
{
    80003ef2:	7159                	addi	sp,sp,-112
    80003ef4:	f486                	sd	ra,104(sp)
    80003ef6:	f0a2                	sd	s0,96(sp)
    80003ef8:	eca6                	sd	s1,88(sp)
    80003efa:	e8ca                	sd	s2,80(sp)
    80003efc:	e4ce                	sd	s3,72(sp)
    80003efe:	e0d2                	sd	s4,64(sp)
    80003f00:	fc56                	sd	s5,56(sp)
    80003f02:	f85a                	sd	s6,48(sp)
    80003f04:	f45e                	sd	s7,40(sp)
    80003f06:	f062                	sd	s8,32(sp)
    80003f08:	ec66                	sd	s9,24(sp)
    80003f0a:	e86a                	sd	s10,16(sp)
    80003f0c:	e46e                	sd	s11,8(sp)
    80003f0e:	1880                	addi	s0,sp,112
    80003f10:	8aaa                	mv	s5,a0
    80003f12:	8bae                	mv	s7,a1
    80003f14:	8a32                	mv	s4,a2
    80003f16:	8936                	mv	s2,a3
    80003f18:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f1a:	00e687bb          	addw	a5,a3,a4
    80003f1e:	0ed7e263          	bltu	a5,a3,80004002 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f22:	00043737          	lui	a4,0x43
    80003f26:	0ef76063          	bltu	a4,a5,80004006 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f2a:	0c0b0863          	beqz	s6,80003ffa <writei+0x10e>
    80003f2e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f30:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f34:	5c7d                	li	s8,-1
    80003f36:	a091                	j	80003f7a <writei+0x8e>
    80003f38:	020d1d93          	slli	s11,s10,0x20
    80003f3c:	020ddd93          	srli	s11,s11,0x20
    80003f40:	05848513          	addi	a0,s1,88
    80003f44:	86ee                	mv	a3,s11
    80003f46:	8652                	mv	a2,s4
    80003f48:	85de                	mv	a1,s7
    80003f4a:	953a                	add	a0,a0,a4
    80003f4c:	ffffe097          	auipc	ra,0xffffe
    80003f50:	7dc080e7          	jalr	2012(ra) # 80002728 <either_copyin>
    80003f54:	07850263          	beq	a0,s8,80003fb8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f58:	8526                	mv	a0,s1
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	75e080e7          	jalr	1886(ra) # 800046b8 <log_write>
    brelse(bp);
    80003f62:	8526                	mv	a0,s1
    80003f64:	fffff097          	auipc	ra,0xfffff
    80003f68:	4fc080e7          	jalr	1276(ra) # 80003460 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f6c:	013d09bb          	addw	s3,s10,s3
    80003f70:	012d093b          	addw	s2,s10,s2
    80003f74:	9a6e                	add	s4,s4,s11
    80003f76:	0569f663          	bgeu	s3,s6,80003fc2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003f7a:	00a9559b          	srliw	a1,s2,0xa
    80003f7e:	8556                	mv	a0,s5
    80003f80:	fffff097          	auipc	ra,0xfffff
    80003f84:	7a2080e7          	jalr	1954(ra) # 80003722 <bmap>
    80003f88:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f8c:	c99d                	beqz	a1,80003fc2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003f8e:	000aa503          	lw	a0,0(s5)
    80003f92:	fffff097          	auipc	ra,0xfffff
    80003f96:	39e080e7          	jalr	926(ra) # 80003330 <bread>
    80003f9a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f9c:	3ff97713          	andi	a4,s2,1023
    80003fa0:	40ec87bb          	subw	a5,s9,a4
    80003fa4:	413b06bb          	subw	a3,s6,s3
    80003fa8:	8d3e                	mv	s10,a5
    80003faa:	2781                	sext.w	a5,a5
    80003fac:	0006861b          	sext.w	a2,a3
    80003fb0:	f8f674e3          	bgeu	a2,a5,80003f38 <writei+0x4c>
    80003fb4:	8d36                	mv	s10,a3
    80003fb6:	b749                	j	80003f38 <writei+0x4c>
      brelse(bp);
    80003fb8:	8526                	mv	a0,s1
    80003fba:	fffff097          	auipc	ra,0xfffff
    80003fbe:	4a6080e7          	jalr	1190(ra) # 80003460 <brelse>
  }

  if(off > ip->size)
    80003fc2:	04caa783          	lw	a5,76(s5)
    80003fc6:	0127f463          	bgeu	a5,s2,80003fce <writei+0xe2>
    ip->size = off;
    80003fca:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003fce:	8556                	mv	a0,s5
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	aa4080e7          	jalr	-1372(ra) # 80003a74 <iupdate>

  return tot;
    80003fd8:	0009851b          	sext.w	a0,s3
}
    80003fdc:	70a6                	ld	ra,104(sp)
    80003fde:	7406                	ld	s0,96(sp)
    80003fe0:	64e6                	ld	s1,88(sp)
    80003fe2:	6946                	ld	s2,80(sp)
    80003fe4:	69a6                	ld	s3,72(sp)
    80003fe6:	6a06                	ld	s4,64(sp)
    80003fe8:	7ae2                	ld	s5,56(sp)
    80003fea:	7b42                	ld	s6,48(sp)
    80003fec:	7ba2                	ld	s7,40(sp)
    80003fee:	7c02                	ld	s8,32(sp)
    80003ff0:	6ce2                	ld	s9,24(sp)
    80003ff2:	6d42                	ld	s10,16(sp)
    80003ff4:	6da2                	ld	s11,8(sp)
    80003ff6:	6165                	addi	sp,sp,112
    80003ff8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ffa:	89da                	mv	s3,s6
    80003ffc:	bfc9                	j	80003fce <writei+0xe2>
    return -1;
    80003ffe:	557d                	li	a0,-1
}
    80004000:	8082                	ret
    return -1;
    80004002:	557d                	li	a0,-1
    80004004:	bfe1                	j	80003fdc <writei+0xf0>
    return -1;
    80004006:	557d                	li	a0,-1
    80004008:	bfd1                	j	80003fdc <writei+0xf0>

000000008000400a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000400a:	1141                	addi	sp,sp,-16
    8000400c:	e406                	sd	ra,8(sp)
    8000400e:	e022                	sd	s0,0(sp)
    80004010:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004012:	4639                	li	a2,14
    80004014:	ffffd097          	auipc	ra,0xffffd
    80004018:	e52080e7          	jalr	-430(ra) # 80000e66 <strncmp>
}
    8000401c:	60a2                	ld	ra,8(sp)
    8000401e:	6402                	ld	s0,0(sp)
    80004020:	0141                	addi	sp,sp,16
    80004022:	8082                	ret

0000000080004024 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004024:	7139                	addi	sp,sp,-64
    80004026:	fc06                	sd	ra,56(sp)
    80004028:	f822                	sd	s0,48(sp)
    8000402a:	f426                	sd	s1,40(sp)
    8000402c:	f04a                	sd	s2,32(sp)
    8000402e:	ec4e                	sd	s3,24(sp)
    80004030:	e852                	sd	s4,16(sp)
    80004032:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004034:	04451703          	lh	a4,68(a0)
    80004038:	4785                	li	a5,1
    8000403a:	00f71a63          	bne	a4,a5,8000404e <dirlookup+0x2a>
    8000403e:	892a                	mv	s2,a0
    80004040:	89ae                	mv	s3,a1
    80004042:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004044:	457c                	lw	a5,76(a0)
    80004046:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004048:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000404a:	e79d                	bnez	a5,80004078 <dirlookup+0x54>
    8000404c:	a8a5                	j	800040c4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000404e:	00004517          	auipc	a0,0x4
    80004052:	6da50513          	addi	a0,a0,1754 # 80008728 <syscalls+0x1c8>
    80004056:	ffffc097          	auipc	ra,0xffffc
    8000405a:	4e6080e7          	jalr	1254(ra) # 8000053c <panic>
      panic("dirlookup read");
    8000405e:	00004517          	auipc	a0,0x4
    80004062:	6e250513          	addi	a0,a0,1762 # 80008740 <syscalls+0x1e0>
    80004066:	ffffc097          	auipc	ra,0xffffc
    8000406a:	4d6080e7          	jalr	1238(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000406e:	24c1                	addiw	s1,s1,16
    80004070:	04c92783          	lw	a5,76(s2)
    80004074:	04f4f763          	bgeu	s1,a5,800040c2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004078:	4741                	li	a4,16
    8000407a:	86a6                	mv	a3,s1
    8000407c:	fc040613          	addi	a2,s0,-64
    80004080:	4581                	li	a1,0
    80004082:	854a                	mv	a0,s2
    80004084:	00000097          	auipc	ra,0x0
    80004088:	d70080e7          	jalr	-656(ra) # 80003df4 <readi>
    8000408c:	47c1                	li	a5,16
    8000408e:	fcf518e3          	bne	a0,a5,8000405e <dirlookup+0x3a>
    if(de.inum == 0)
    80004092:	fc045783          	lhu	a5,-64(s0)
    80004096:	dfe1                	beqz	a5,8000406e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004098:	fc240593          	addi	a1,s0,-62
    8000409c:	854e                	mv	a0,s3
    8000409e:	00000097          	auipc	ra,0x0
    800040a2:	f6c080e7          	jalr	-148(ra) # 8000400a <namecmp>
    800040a6:	f561                	bnez	a0,8000406e <dirlookup+0x4a>
      if(poff)
    800040a8:	000a0463          	beqz	s4,800040b0 <dirlookup+0x8c>
        *poff = off;
    800040ac:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040b0:	fc045583          	lhu	a1,-64(s0)
    800040b4:	00092503          	lw	a0,0(s2)
    800040b8:	fffff097          	auipc	ra,0xfffff
    800040bc:	754080e7          	jalr	1876(ra) # 8000380c <iget>
    800040c0:	a011                	j	800040c4 <dirlookup+0xa0>
  return 0;
    800040c2:	4501                	li	a0,0
}
    800040c4:	70e2                	ld	ra,56(sp)
    800040c6:	7442                	ld	s0,48(sp)
    800040c8:	74a2                	ld	s1,40(sp)
    800040ca:	7902                	ld	s2,32(sp)
    800040cc:	69e2                	ld	s3,24(sp)
    800040ce:	6a42                	ld	s4,16(sp)
    800040d0:	6121                	addi	sp,sp,64
    800040d2:	8082                	ret

00000000800040d4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040d4:	711d                	addi	sp,sp,-96
    800040d6:	ec86                	sd	ra,88(sp)
    800040d8:	e8a2                	sd	s0,80(sp)
    800040da:	e4a6                	sd	s1,72(sp)
    800040dc:	e0ca                	sd	s2,64(sp)
    800040de:	fc4e                	sd	s3,56(sp)
    800040e0:	f852                	sd	s4,48(sp)
    800040e2:	f456                	sd	s5,40(sp)
    800040e4:	f05a                	sd	s6,32(sp)
    800040e6:	ec5e                	sd	s7,24(sp)
    800040e8:	e862                	sd	s8,16(sp)
    800040ea:	e466                	sd	s9,8(sp)
    800040ec:	1080                	addi	s0,sp,96
    800040ee:	84aa                	mv	s1,a0
    800040f0:	8b2e                	mv	s6,a1
    800040f2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040f4:	00054703          	lbu	a4,0(a0)
    800040f8:	02f00793          	li	a5,47
    800040fc:	02f70263          	beq	a4,a5,80004120 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004100:	ffffe097          	auipc	ra,0xffffe
    80004104:	a62080e7          	jalr	-1438(ra) # 80001b62 <myproc>
    80004108:	15053503          	ld	a0,336(a0)
    8000410c:	00000097          	auipc	ra,0x0
    80004110:	9f6080e7          	jalr	-1546(ra) # 80003b02 <idup>
    80004114:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004116:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000411a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000411c:	4b85                	li	s7,1
    8000411e:	a875                	j	800041da <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004120:	4585                	li	a1,1
    80004122:	4505                	li	a0,1
    80004124:	fffff097          	auipc	ra,0xfffff
    80004128:	6e8080e7          	jalr	1768(ra) # 8000380c <iget>
    8000412c:	8a2a                	mv	s4,a0
    8000412e:	b7e5                	j	80004116 <namex+0x42>
      iunlockput(ip);
    80004130:	8552                	mv	a0,s4
    80004132:	00000097          	auipc	ra,0x0
    80004136:	c70080e7          	jalr	-912(ra) # 80003da2 <iunlockput>
      return 0;
    8000413a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000413c:	8552                	mv	a0,s4
    8000413e:	60e6                	ld	ra,88(sp)
    80004140:	6446                	ld	s0,80(sp)
    80004142:	64a6                	ld	s1,72(sp)
    80004144:	6906                	ld	s2,64(sp)
    80004146:	79e2                	ld	s3,56(sp)
    80004148:	7a42                	ld	s4,48(sp)
    8000414a:	7aa2                	ld	s5,40(sp)
    8000414c:	7b02                	ld	s6,32(sp)
    8000414e:	6be2                	ld	s7,24(sp)
    80004150:	6c42                	ld	s8,16(sp)
    80004152:	6ca2                	ld	s9,8(sp)
    80004154:	6125                	addi	sp,sp,96
    80004156:	8082                	ret
      iunlock(ip);
    80004158:	8552                	mv	a0,s4
    8000415a:	00000097          	auipc	ra,0x0
    8000415e:	aa8080e7          	jalr	-1368(ra) # 80003c02 <iunlock>
      return ip;
    80004162:	bfe9                	j	8000413c <namex+0x68>
      iunlockput(ip);
    80004164:	8552                	mv	a0,s4
    80004166:	00000097          	auipc	ra,0x0
    8000416a:	c3c080e7          	jalr	-964(ra) # 80003da2 <iunlockput>
      return 0;
    8000416e:	8a4e                	mv	s4,s3
    80004170:	b7f1                	j	8000413c <namex+0x68>
  len = path - s;
    80004172:	40998633          	sub	a2,s3,s1
    80004176:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000417a:	099c5863          	bge	s8,s9,8000420a <namex+0x136>
    memmove(name, s, DIRSIZ);
    8000417e:	4639                	li	a2,14
    80004180:	85a6                	mv	a1,s1
    80004182:	8556                	mv	a0,s5
    80004184:	ffffd097          	auipc	ra,0xffffd
    80004188:	c6e080e7          	jalr	-914(ra) # 80000df2 <memmove>
    8000418c:	84ce                	mv	s1,s3
  while(*path == '/')
    8000418e:	0004c783          	lbu	a5,0(s1)
    80004192:	01279763          	bne	a5,s2,800041a0 <namex+0xcc>
    path++;
    80004196:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004198:	0004c783          	lbu	a5,0(s1)
    8000419c:	ff278de3          	beq	a5,s2,80004196 <namex+0xc2>
    ilock(ip);
    800041a0:	8552                	mv	a0,s4
    800041a2:	00000097          	auipc	ra,0x0
    800041a6:	99e080e7          	jalr	-1634(ra) # 80003b40 <ilock>
    if(ip->type != T_DIR){
    800041aa:	044a1783          	lh	a5,68(s4)
    800041ae:	f97791e3          	bne	a5,s7,80004130 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800041b2:	000b0563          	beqz	s6,800041bc <namex+0xe8>
    800041b6:	0004c783          	lbu	a5,0(s1)
    800041ba:	dfd9                	beqz	a5,80004158 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041bc:	4601                	li	a2,0
    800041be:	85d6                	mv	a1,s5
    800041c0:	8552                	mv	a0,s4
    800041c2:	00000097          	auipc	ra,0x0
    800041c6:	e62080e7          	jalr	-414(ra) # 80004024 <dirlookup>
    800041ca:	89aa                	mv	s3,a0
    800041cc:	dd41                	beqz	a0,80004164 <namex+0x90>
    iunlockput(ip);
    800041ce:	8552                	mv	a0,s4
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	bd2080e7          	jalr	-1070(ra) # 80003da2 <iunlockput>
    ip = next;
    800041d8:	8a4e                	mv	s4,s3
  while(*path == '/')
    800041da:	0004c783          	lbu	a5,0(s1)
    800041de:	01279763          	bne	a5,s2,800041ec <namex+0x118>
    path++;
    800041e2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041e4:	0004c783          	lbu	a5,0(s1)
    800041e8:	ff278de3          	beq	a5,s2,800041e2 <namex+0x10e>
  if(*path == 0)
    800041ec:	cb9d                	beqz	a5,80004222 <namex+0x14e>
  while(*path != '/' && *path != 0)
    800041ee:	0004c783          	lbu	a5,0(s1)
    800041f2:	89a6                	mv	s3,s1
  len = path - s;
    800041f4:	4c81                	li	s9,0
    800041f6:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800041f8:	01278963          	beq	a5,s2,8000420a <namex+0x136>
    800041fc:	dbbd                	beqz	a5,80004172 <namex+0x9e>
    path++;
    800041fe:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004200:	0009c783          	lbu	a5,0(s3)
    80004204:	ff279ce3          	bne	a5,s2,800041fc <namex+0x128>
    80004208:	b7ad                	j	80004172 <namex+0x9e>
    memmove(name, s, len);
    8000420a:	2601                	sext.w	a2,a2
    8000420c:	85a6                	mv	a1,s1
    8000420e:	8556                	mv	a0,s5
    80004210:	ffffd097          	auipc	ra,0xffffd
    80004214:	be2080e7          	jalr	-1054(ra) # 80000df2 <memmove>
    name[len] = 0;
    80004218:	9cd6                	add	s9,s9,s5
    8000421a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000421e:	84ce                	mv	s1,s3
    80004220:	b7bd                	j	8000418e <namex+0xba>
  if(nameiparent){
    80004222:	f00b0de3          	beqz	s6,8000413c <namex+0x68>
    iput(ip);
    80004226:	8552                	mv	a0,s4
    80004228:	00000097          	auipc	ra,0x0
    8000422c:	ad2080e7          	jalr	-1326(ra) # 80003cfa <iput>
    return 0;
    80004230:	4a01                	li	s4,0
    80004232:	b729                	j	8000413c <namex+0x68>

0000000080004234 <dirlink>:
{
    80004234:	7139                	addi	sp,sp,-64
    80004236:	fc06                	sd	ra,56(sp)
    80004238:	f822                	sd	s0,48(sp)
    8000423a:	f426                	sd	s1,40(sp)
    8000423c:	f04a                	sd	s2,32(sp)
    8000423e:	ec4e                	sd	s3,24(sp)
    80004240:	e852                	sd	s4,16(sp)
    80004242:	0080                	addi	s0,sp,64
    80004244:	892a                	mv	s2,a0
    80004246:	8a2e                	mv	s4,a1
    80004248:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000424a:	4601                	li	a2,0
    8000424c:	00000097          	auipc	ra,0x0
    80004250:	dd8080e7          	jalr	-552(ra) # 80004024 <dirlookup>
    80004254:	e93d                	bnez	a0,800042ca <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004256:	04c92483          	lw	s1,76(s2)
    8000425a:	c49d                	beqz	s1,80004288 <dirlink+0x54>
    8000425c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000425e:	4741                	li	a4,16
    80004260:	86a6                	mv	a3,s1
    80004262:	fc040613          	addi	a2,s0,-64
    80004266:	4581                	li	a1,0
    80004268:	854a                	mv	a0,s2
    8000426a:	00000097          	auipc	ra,0x0
    8000426e:	b8a080e7          	jalr	-1142(ra) # 80003df4 <readi>
    80004272:	47c1                	li	a5,16
    80004274:	06f51163          	bne	a0,a5,800042d6 <dirlink+0xa2>
    if(de.inum == 0)
    80004278:	fc045783          	lhu	a5,-64(s0)
    8000427c:	c791                	beqz	a5,80004288 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000427e:	24c1                	addiw	s1,s1,16
    80004280:	04c92783          	lw	a5,76(s2)
    80004284:	fcf4ede3          	bltu	s1,a5,8000425e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004288:	4639                	li	a2,14
    8000428a:	85d2                	mv	a1,s4
    8000428c:	fc240513          	addi	a0,s0,-62
    80004290:	ffffd097          	auipc	ra,0xffffd
    80004294:	c12080e7          	jalr	-1006(ra) # 80000ea2 <strncpy>
  de.inum = inum;
    80004298:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000429c:	4741                	li	a4,16
    8000429e:	86a6                	mv	a3,s1
    800042a0:	fc040613          	addi	a2,s0,-64
    800042a4:	4581                	li	a1,0
    800042a6:	854a                	mv	a0,s2
    800042a8:	00000097          	auipc	ra,0x0
    800042ac:	c44080e7          	jalr	-956(ra) # 80003eec <writei>
    800042b0:	1541                	addi	a0,a0,-16
    800042b2:	00a03533          	snez	a0,a0
    800042b6:	40a00533          	neg	a0,a0
}
    800042ba:	70e2                	ld	ra,56(sp)
    800042bc:	7442                	ld	s0,48(sp)
    800042be:	74a2                	ld	s1,40(sp)
    800042c0:	7902                	ld	s2,32(sp)
    800042c2:	69e2                	ld	s3,24(sp)
    800042c4:	6a42                	ld	s4,16(sp)
    800042c6:	6121                	addi	sp,sp,64
    800042c8:	8082                	ret
    iput(ip);
    800042ca:	00000097          	auipc	ra,0x0
    800042ce:	a30080e7          	jalr	-1488(ra) # 80003cfa <iput>
    return -1;
    800042d2:	557d                	li	a0,-1
    800042d4:	b7dd                	j	800042ba <dirlink+0x86>
      panic("dirlink read");
    800042d6:	00004517          	auipc	a0,0x4
    800042da:	47a50513          	addi	a0,a0,1146 # 80008750 <syscalls+0x1f0>
    800042de:	ffffc097          	auipc	ra,0xffffc
    800042e2:	25e080e7          	jalr	606(ra) # 8000053c <panic>

00000000800042e6 <namei>:

struct inode*
namei(char *path)
{
    800042e6:	1101                	addi	sp,sp,-32
    800042e8:	ec06                	sd	ra,24(sp)
    800042ea:	e822                	sd	s0,16(sp)
    800042ec:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042ee:	fe040613          	addi	a2,s0,-32
    800042f2:	4581                	li	a1,0
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	de0080e7          	jalr	-544(ra) # 800040d4 <namex>
}
    800042fc:	60e2                	ld	ra,24(sp)
    800042fe:	6442                	ld	s0,16(sp)
    80004300:	6105                	addi	sp,sp,32
    80004302:	8082                	ret

0000000080004304 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004304:	1141                	addi	sp,sp,-16
    80004306:	e406                	sd	ra,8(sp)
    80004308:	e022                	sd	s0,0(sp)
    8000430a:	0800                	addi	s0,sp,16
    8000430c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000430e:	4585                	li	a1,1
    80004310:	00000097          	auipc	ra,0x0
    80004314:	dc4080e7          	jalr	-572(ra) # 800040d4 <namex>
}
    80004318:	60a2                	ld	ra,8(sp)
    8000431a:	6402                	ld	s0,0(sp)
    8000431c:	0141                	addi	sp,sp,16
    8000431e:	8082                	ret

0000000080004320 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004320:	1101                	addi	sp,sp,-32
    80004322:	ec06                	sd	ra,24(sp)
    80004324:	e822                	sd	s0,16(sp)
    80004326:	e426                	sd	s1,8(sp)
    80004328:	e04a                	sd	s2,0(sp)
    8000432a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000432c:	0001d917          	auipc	s2,0x1d
    80004330:	97490913          	addi	s2,s2,-1676 # 80020ca0 <log>
    80004334:	01892583          	lw	a1,24(s2)
    80004338:	02892503          	lw	a0,40(s2)
    8000433c:	fffff097          	auipc	ra,0xfffff
    80004340:	ff4080e7          	jalr	-12(ra) # 80003330 <bread>
    80004344:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004346:	02c92603          	lw	a2,44(s2)
    8000434a:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000434c:	00c05f63          	blez	a2,8000436a <write_head+0x4a>
    80004350:	0001d717          	auipc	a4,0x1d
    80004354:	98070713          	addi	a4,a4,-1664 # 80020cd0 <log+0x30>
    80004358:	87aa                	mv	a5,a0
    8000435a:	060a                	slli	a2,a2,0x2
    8000435c:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    8000435e:	4314                	lw	a3,0(a4)
    80004360:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004362:	0711                	addi	a4,a4,4
    80004364:	0791                	addi	a5,a5,4
    80004366:	fec79ce3          	bne	a5,a2,8000435e <write_head+0x3e>
  }
  bwrite(buf);
    8000436a:	8526                	mv	a0,s1
    8000436c:	fffff097          	auipc	ra,0xfffff
    80004370:	0b6080e7          	jalr	182(ra) # 80003422 <bwrite>
  brelse(buf);
    80004374:	8526                	mv	a0,s1
    80004376:	fffff097          	auipc	ra,0xfffff
    8000437a:	0ea080e7          	jalr	234(ra) # 80003460 <brelse>
}
    8000437e:	60e2                	ld	ra,24(sp)
    80004380:	6442                	ld	s0,16(sp)
    80004382:	64a2                	ld	s1,8(sp)
    80004384:	6902                	ld	s2,0(sp)
    80004386:	6105                	addi	sp,sp,32
    80004388:	8082                	ret

000000008000438a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000438a:	0001d797          	auipc	a5,0x1d
    8000438e:	9427a783          	lw	a5,-1726(a5) # 80020ccc <log+0x2c>
    80004392:	0af05d63          	blez	a5,8000444c <install_trans+0xc2>
{
    80004396:	7139                	addi	sp,sp,-64
    80004398:	fc06                	sd	ra,56(sp)
    8000439a:	f822                	sd	s0,48(sp)
    8000439c:	f426                	sd	s1,40(sp)
    8000439e:	f04a                	sd	s2,32(sp)
    800043a0:	ec4e                	sd	s3,24(sp)
    800043a2:	e852                	sd	s4,16(sp)
    800043a4:	e456                	sd	s5,8(sp)
    800043a6:	e05a                	sd	s6,0(sp)
    800043a8:	0080                	addi	s0,sp,64
    800043aa:	8b2a                	mv	s6,a0
    800043ac:	0001da97          	auipc	s5,0x1d
    800043b0:	924a8a93          	addi	s5,s5,-1756 # 80020cd0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043b4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043b6:	0001d997          	auipc	s3,0x1d
    800043ba:	8ea98993          	addi	s3,s3,-1814 # 80020ca0 <log>
    800043be:	a00d                	j	800043e0 <install_trans+0x56>
    brelse(lbuf);
    800043c0:	854a                	mv	a0,s2
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	09e080e7          	jalr	158(ra) # 80003460 <brelse>
    brelse(dbuf);
    800043ca:	8526                	mv	a0,s1
    800043cc:	fffff097          	auipc	ra,0xfffff
    800043d0:	094080e7          	jalr	148(ra) # 80003460 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d4:	2a05                	addiw	s4,s4,1
    800043d6:	0a91                	addi	s5,s5,4
    800043d8:	02c9a783          	lw	a5,44(s3)
    800043dc:	04fa5e63          	bge	s4,a5,80004438 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043e0:	0189a583          	lw	a1,24(s3)
    800043e4:	014585bb          	addw	a1,a1,s4
    800043e8:	2585                	addiw	a1,a1,1
    800043ea:	0289a503          	lw	a0,40(s3)
    800043ee:	fffff097          	auipc	ra,0xfffff
    800043f2:	f42080e7          	jalr	-190(ra) # 80003330 <bread>
    800043f6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043f8:	000aa583          	lw	a1,0(s5)
    800043fc:	0289a503          	lw	a0,40(s3)
    80004400:	fffff097          	auipc	ra,0xfffff
    80004404:	f30080e7          	jalr	-208(ra) # 80003330 <bread>
    80004408:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000440a:	40000613          	li	a2,1024
    8000440e:	05890593          	addi	a1,s2,88
    80004412:	05850513          	addi	a0,a0,88
    80004416:	ffffd097          	auipc	ra,0xffffd
    8000441a:	9dc080e7          	jalr	-1572(ra) # 80000df2 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000441e:	8526                	mv	a0,s1
    80004420:	fffff097          	auipc	ra,0xfffff
    80004424:	002080e7          	jalr	2(ra) # 80003422 <bwrite>
    if(recovering == 0)
    80004428:	f80b1ce3          	bnez	s6,800043c0 <install_trans+0x36>
      bunpin(dbuf);
    8000442c:	8526                	mv	a0,s1
    8000442e:	fffff097          	auipc	ra,0xfffff
    80004432:	10a080e7          	jalr	266(ra) # 80003538 <bunpin>
    80004436:	b769                	j	800043c0 <install_trans+0x36>
}
    80004438:	70e2                	ld	ra,56(sp)
    8000443a:	7442                	ld	s0,48(sp)
    8000443c:	74a2                	ld	s1,40(sp)
    8000443e:	7902                	ld	s2,32(sp)
    80004440:	69e2                	ld	s3,24(sp)
    80004442:	6a42                	ld	s4,16(sp)
    80004444:	6aa2                	ld	s5,8(sp)
    80004446:	6b02                	ld	s6,0(sp)
    80004448:	6121                	addi	sp,sp,64
    8000444a:	8082                	ret
    8000444c:	8082                	ret

000000008000444e <initlog>:
{
    8000444e:	7179                	addi	sp,sp,-48
    80004450:	f406                	sd	ra,40(sp)
    80004452:	f022                	sd	s0,32(sp)
    80004454:	ec26                	sd	s1,24(sp)
    80004456:	e84a                	sd	s2,16(sp)
    80004458:	e44e                	sd	s3,8(sp)
    8000445a:	1800                	addi	s0,sp,48
    8000445c:	892a                	mv	s2,a0
    8000445e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004460:	0001d497          	auipc	s1,0x1d
    80004464:	84048493          	addi	s1,s1,-1984 # 80020ca0 <log>
    80004468:	00004597          	auipc	a1,0x4
    8000446c:	2f858593          	addi	a1,a1,760 # 80008760 <syscalls+0x200>
    80004470:	8526                	mv	a0,s1
    80004472:	ffffc097          	auipc	ra,0xffffc
    80004476:	798080e7          	jalr	1944(ra) # 80000c0a <initlock>
  log.start = sb->logstart;
    8000447a:	0149a583          	lw	a1,20(s3)
    8000447e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004480:	0109a783          	lw	a5,16(s3)
    80004484:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004486:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000448a:	854a                	mv	a0,s2
    8000448c:	fffff097          	auipc	ra,0xfffff
    80004490:	ea4080e7          	jalr	-348(ra) # 80003330 <bread>
  log.lh.n = lh->n;
    80004494:	4d30                	lw	a2,88(a0)
    80004496:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004498:	00c05f63          	blez	a2,800044b6 <initlog+0x68>
    8000449c:	87aa                	mv	a5,a0
    8000449e:	0001d717          	auipc	a4,0x1d
    800044a2:	83270713          	addi	a4,a4,-1998 # 80020cd0 <log+0x30>
    800044a6:	060a                	slli	a2,a2,0x2
    800044a8:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800044aa:	4ff4                	lw	a3,92(a5)
    800044ac:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044ae:	0791                	addi	a5,a5,4
    800044b0:	0711                	addi	a4,a4,4
    800044b2:	fec79ce3          	bne	a5,a2,800044aa <initlog+0x5c>
  brelse(buf);
    800044b6:	fffff097          	auipc	ra,0xfffff
    800044ba:	faa080e7          	jalr	-86(ra) # 80003460 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044be:	4505                	li	a0,1
    800044c0:	00000097          	auipc	ra,0x0
    800044c4:	eca080e7          	jalr	-310(ra) # 8000438a <install_trans>
  log.lh.n = 0;
    800044c8:	0001d797          	auipc	a5,0x1d
    800044cc:	8007a223          	sw	zero,-2044(a5) # 80020ccc <log+0x2c>
  write_head(); // clear the log
    800044d0:	00000097          	auipc	ra,0x0
    800044d4:	e50080e7          	jalr	-432(ra) # 80004320 <write_head>
}
    800044d8:	70a2                	ld	ra,40(sp)
    800044da:	7402                	ld	s0,32(sp)
    800044dc:	64e2                	ld	s1,24(sp)
    800044de:	6942                	ld	s2,16(sp)
    800044e0:	69a2                	ld	s3,8(sp)
    800044e2:	6145                	addi	sp,sp,48
    800044e4:	8082                	ret

00000000800044e6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044e6:	1101                	addi	sp,sp,-32
    800044e8:	ec06                	sd	ra,24(sp)
    800044ea:	e822                	sd	s0,16(sp)
    800044ec:	e426                	sd	s1,8(sp)
    800044ee:	e04a                	sd	s2,0(sp)
    800044f0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044f2:	0001c517          	auipc	a0,0x1c
    800044f6:	7ae50513          	addi	a0,a0,1966 # 80020ca0 <log>
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	7a0080e7          	jalr	1952(ra) # 80000c9a <acquire>
  while(1){
    if(log.committing){
    80004502:	0001c497          	auipc	s1,0x1c
    80004506:	79e48493          	addi	s1,s1,1950 # 80020ca0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000450a:	4979                	li	s2,30
    8000450c:	a039                	j	8000451a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000450e:	85a6                	mv	a1,s1
    80004510:	8526                	mv	a0,s1
    80004512:	ffffe097          	auipc	ra,0xffffe
    80004516:	db8080e7          	jalr	-584(ra) # 800022ca <sleep>
    if(log.committing){
    8000451a:	50dc                	lw	a5,36(s1)
    8000451c:	fbed                	bnez	a5,8000450e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000451e:	5098                	lw	a4,32(s1)
    80004520:	2705                	addiw	a4,a4,1
    80004522:	0027179b          	slliw	a5,a4,0x2
    80004526:	9fb9                	addw	a5,a5,a4
    80004528:	0017979b          	slliw	a5,a5,0x1
    8000452c:	54d4                	lw	a3,44(s1)
    8000452e:	9fb5                	addw	a5,a5,a3
    80004530:	00f95963          	bge	s2,a5,80004542 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004534:	85a6                	mv	a1,s1
    80004536:	8526                	mv	a0,s1
    80004538:	ffffe097          	auipc	ra,0xffffe
    8000453c:	d92080e7          	jalr	-622(ra) # 800022ca <sleep>
    80004540:	bfe9                	j	8000451a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004542:	0001c517          	auipc	a0,0x1c
    80004546:	75e50513          	addi	a0,a0,1886 # 80020ca0 <log>
    8000454a:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000454c:	ffffd097          	auipc	ra,0xffffd
    80004550:	802080e7          	jalr	-2046(ra) # 80000d4e <release>
      break;
    }
  }
}
    80004554:	60e2                	ld	ra,24(sp)
    80004556:	6442                	ld	s0,16(sp)
    80004558:	64a2                	ld	s1,8(sp)
    8000455a:	6902                	ld	s2,0(sp)
    8000455c:	6105                	addi	sp,sp,32
    8000455e:	8082                	ret

0000000080004560 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004560:	7139                	addi	sp,sp,-64
    80004562:	fc06                	sd	ra,56(sp)
    80004564:	f822                	sd	s0,48(sp)
    80004566:	f426                	sd	s1,40(sp)
    80004568:	f04a                	sd	s2,32(sp)
    8000456a:	ec4e                	sd	s3,24(sp)
    8000456c:	e852                	sd	s4,16(sp)
    8000456e:	e456                	sd	s5,8(sp)
    80004570:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004572:	0001c497          	auipc	s1,0x1c
    80004576:	72e48493          	addi	s1,s1,1838 # 80020ca0 <log>
    8000457a:	8526                	mv	a0,s1
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	71e080e7          	jalr	1822(ra) # 80000c9a <acquire>
  log.outstanding -= 1;
    80004584:	509c                	lw	a5,32(s1)
    80004586:	37fd                	addiw	a5,a5,-1
    80004588:	0007891b          	sext.w	s2,a5
    8000458c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000458e:	50dc                	lw	a5,36(s1)
    80004590:	e7b9                	bnez	a5,800045de <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004592:	04091e63          	bnez	s2,800045ee <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004596:	0001c497          	auipc	s1,0x1c
    8000459a:	70a48493          	addi	s1,s1,1802 # 80020ca0 <log>
    8000459e:	4785                	li	a5,1
    800045a0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045a2:	8526                	mv	a0,s1
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	7aa080e7          	jalr	1962(ra) # 80000d4e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045ac:	54dc                	lw	a5,44(s1)
    800045ae:	06f04763          	bgtz	a5,8000461c <end_op+0xbc>
    acquire(&log.lock);
    800045b2:	0001c497          	auipc	s1,0x1c
    800045b6:	6ee48493          	addi	s1,s1,1774 # 80020ca0 <log>
    800045ba:	8526                	mv	a0,s1
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	6de080e7          	jalr	1758(ra) # 80000c9a <acquire>
    log.committing = 0;
    800045c4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045c8:	8526                	mv	a0,s1
    800045ca:	ffffe097          	auipc	ra,0xffffe
    800045ce:	d64080e7          	jalr	-668(ra) # 8000232e <wakeup>
    release(&log.lock);
    800045d2:	8526                	mv	a0,s1
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	77a080e7          	jalr	1914(ra) # 80000d4e <release>
}
    800045dc:	a03d                	j	8000460a <end_op+0xaa>
    panic("log.committing");
    800045de:	00004517          	auipc	a0,0x4
    800045e2:	18a50513          	addi	a0,a0,394 # 80008768 <syscalls+0x208>
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	f56080e7          	jalr	-170(ra) # 8000053c <panic>
    wakeup(&log);
    800045ee:	0001c497          	auipc	s1,0x1c
    800045f2:	6b248493          	addi	s1,s1,1714 # 80020ca0 <log>
    800045f6:	8526                	mv	a0,s1
    800045f8:	ffffe097          	auipc	ra,0xffffe
    800045fc:	d36080e7          	jalr	-714(ra) # 8000232e <wakeup>
  release(&log.lock);
    80004600:	8526                	mv	a0,s1
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	74c080e7          	jalr	1868(ra) # 80000d4e <release>
}
    8000460a:	70e2                	ld	ra,56(sp)
    8000460c:	7442                	ld	s0,48(sp)
    8000460e:	74a2                	ld	s1,40(sp)
    80004610:	7902                	ld	s2,32(sp)
    80004612:	69e2                	ld	s3,24(sp)
    80004614:	6a42                	ld	s4,16(sp)
    80004616:	6aa2                	ld	s5,8(sp)
    80004618:	6121                	addi	sp,sp,64
    8000461a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000461c:	0001ca97          	auipc	s5,0x1c
    80004620:	6b4a8a93          	addi	s5,s5,1716 # 80020cd0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004624:	0001ca17          	auipc	s4,0x1c
    80004628:	67ca0a13          	addi	s4,s4,1660 # 80020ca0 <log>
    8000462c:	018a2583          	lw	a1,24(s4)
    80004630:	012585bb          	addw	a1,a1,s2
    80004634:	2585                	addiw	a1,a1,1
    80004636:	028a2503          	lw	a0,40(s4)
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	cf6080e7          	jalr	-778(ra) # 80003330 <bread>
    80004642:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004644:	000aa583          	lw	a1,0(s5)
    80004648:	028a2503          	lw	a0,40(s4)
    8000464c:	fffff097          	auipc	ra,0xfffff
    80004650:	ce4080e7          	jalr	-796(ra) # 80003330 <bread>
    80004654:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004656:	40000613          	li	a2,1024
    8000465a:	05850593          	addi	a1,a0,88
    8000465e:	05848513          	addi	a0,s1,88
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	790080e7          	jalr	1936(ra) # 80000df2 <memmove>
    bwrite(to);  // write the log
    8000466a:	8526                	mv	a0,s1
    8000466c:	fffff097          	auipc	ra,0xfffff
    80004670:	db6080e7          	jalr	-586(ra) # 80003422 <bwrite>
    brelse(from);
    80004674:	854e                	mv	a0,s3
    80004676:	fffff097          	auipc	ra,0xfffff
    8000467a:	dea080e7          	jalr	-534(ra) # 80003460 <brelse>
    brelse(to);
    8000467e:	8526                	mv	a0,s1
    80004680:	fffff097          	auipc	ra,0xfffff
    80004684:	de0080e7          	jalr	-544(ra) # 80003460 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004688:	2905                	addiw	s2,s2,1
    8000468a:	0a91                	addi	s5,s5,4
    8000468c:	02ca2783          	lw	a5,44(s4)
    80004690:	f8f94ee3          	blt	s2,a5,8000462c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004694:	00000097          	auipc	ra,0x0
    80004698:	c8c080e7          	jalr	-884(ra) # 80004320 <write_head>
    install_trans(0); // Now install writes to home locations
    8000469c:	4501                	li	a0,0
    8000469e:	00000097          	auipc	ra,0x0
    800046a2:	cec080e7          	jalr	-788(ra) # 8000438a <install_trans>
    log.lh.n = 0;
    800046a6:	0001c797          	auipc	a5,0x1c
    800046aa:	6207a323          	sw	zero,1574(a5) # 80020ccc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800046ae:	00000097          	auipc	ra,0x0
    800046b2:	c72080e7          	jalr	-910(ra) # 80004320 <write_head>
    800046b6:	bdf5                	j	800045b2 <end_op+0x52>

00000000800046b8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046b8:	1101                	addi	sp,sp,-32
    800046ba:	ec06                	sd	ra,24(sp)
    800046bc:	e822                	sd	s0,16(sp)
    800046be:	e426                	sd	s1,8(sp)
    800046c0:	e04a                	sd	s2,0(sp)
    800046c2:	1000                	addi	s0,sp,32
    800046c4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046c6:	0001c917          	auipc	s2,0x1c
    800046ca:	5da90913          	addi	s2,s2,1498 # 80020ca0 <log>
    800046ce:	854a                	mv	a0,s2
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	5ca080e7          	jalr	1482(ra) # 80000c9a <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046d8:	02c92603          	lw	a2,44(s2)
    800046dc:	47f5                	li	a5,29
    800046de:	06c7c563          	blt	a5,a2,80004748 <log_write+0x90>
    800046e2:	0001c797          	auipc	a5,0x1c
    800046e6:	5da7a783          	lw	a5,1498(a5) # 80020cbc <log+0x1c>
    800046ea:	37fd                	addiw	a5,a5,-1
    800046ec:	04f65e63          	bge	a2,a5,80004748 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046f0:	0001c797          	auipc	a5,0x1c
    800046f4:	5d07a783          	lw	a5,1488(a5) # 80020cc0 <log+0x20>
    800046f8:	06f05063          	blez	a5,80004758 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046fc:	4781                	li	a5,0
    800046fe:	06c05563          	blez	a2,80004768 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004702:	44cc                	lw	a1,12(s1)
    80004704:	0001c717          	auipc	a4,0x1c
    80004708:	5cc70713          	addi	a4,a4,1484 # 80020cd0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000470c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000470e:	4314                	lw	a3,0(a4)
    80004710:	04b68c63          	beq	a3,a1,80004768 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004714:	2785                	addiw	a5,a5,1
    80004716:	0711                	addi	a4,a4,4
    80004718:	fef61be3          	bne	a2,a5,8000470e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000471c:	0621                	addi	a2,a2,8
    8000471e:	060a                	slli	a2,a2,0x2
    80004720:	0001c797          	auipc	a5,0x1c
    80004724:	58078793          	addi	a5,a5,1408 # 80020ca0 <log>
    80004728:	97b2                	add	a5,a5,a2
    8000472a:	44d8                	lw	a4,12(s1)
    8000472c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000472e:	8526                	mv	a0,s1
    80004730:	fffff097          	auipc	ra,0xfffff
    80004734:	dcc080e7          	jalr	-564(ra) # 800034fc <bpin>
    log.lh.n++;
    80004738:	0001c717          	auipc	a4,0x1c
    8000473c:	56870713          	addi	a4,a4,1384 # 80020ca0 <log>
    80004740:	575c                	lw	a5,44(a4)
    80004742:	2785                	addiw	a5,a5,1
    80004744:	d75c                	sw	a5,44(a4)
    80004746:	a82d                	j	80004780 <log_write+0xc8>
    panic("too big a transaction");
    80004748:	00004517          	auipc	a0,0x4
    8000474c:	03050513          	addi	a0,a0,48 # 80008778 <syscalls+0x218>
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	dec080e7          	jalr	-532(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004758:	00004517          	auipc	a0,0x4
    8000475c:	03850513          	addi	a0,a0,56 # 80008790 <syscalls+0x230>
    80004760:	ffffc097          	auipc	ra,0xffffc
    80004764:	ddc080e7          	jalr	-548(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004768:	00878693          	addi	a3,a5,8
    8000476c:	068a                	slli	a3,a3,0x2
    8000476e:	0001c717          	auipc	a4,0x1c
    80004772:	53270713          	addi	a4,a4,1330 # 80020ca0 <log>
    80004776:	9736                	add	a4,a4,a3
    80004778:	44d4                	lw	a3,12(s1)
    8000477a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000477c:	faf609e3          	beq	a2,a5,8000472e <log_write+0x76>
  }
  release(&log.lock);
    80004780:	0001c517          	auipc	a0,0x1c
    80004784:	52050513          	addi	a0,a0,1312 # 80020ca0 <log>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	5c6080e7          	jalr	1478(ra) # 80000d4e <release>
}
    80004790:	60e2                	ld	ra,24(sp)
    80004792:	6442                	ld	s0,16(sp)
    80004794:	64a2                	ld	s1,8(sp)
    80004796:	6902                	ld	s2,0(sp)
    80004798:	6105                	addi	sp,sp,32
    8000479a:	8082                	ret

000000008000479c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000479c:	1101                	addi	sp,sp,-32
    8000479e:	ec06                	sd	ra,24(sp)
    800047a0:	e822                	sd	s0,16(sp)
    800047a2:	e426                	sd	s1,8(sp)
    800047a4:	e04a                	sd	s2,0(sp)
    800047a6:	1000                	addi	s0,sp,32
    800047a8:	84aa                	mv	s1,a0
    800047aa:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047ac:	00004597          	auipc	a1,0x4
    800047b0:	00458593          	addi	a1,a1,4 # 800087b0 <syscalls+0x250>
    800047b4:	0521                	addi	a0,a0,8
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	454080e7          	jalr	1108(ra) # 80000c0a <initlock>
  lk->name = name;
    800047be:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047c2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047c6:	0204a423          	sw	zero,40(s1)
}
    800047ca:	60e2                	ld	ra,24(sp)
    800047cc:	6442                	ld	s0,16(sp)
    800047ce:	64a2                	ld	s1,8(sp)
    800047d0:	6902                	ld	s2,0(sp)
    800047d2:	6105                	addi	sp,sp,32
    800047d4:	8082                	ret

00000000800047d6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047d6:	1101                	addi	sp,sp,-32
    800047d8:	ec06                	sd	ra,24(sp)
    800047da:	e822                	sd	s0,16(sp)
    800047dc:	e426                	sd	s1,8(sp)
    800047de:	e04a                	sd	s2,0(sp)
    800047e0:	1000                	addi	s0,sp,32
    800047e2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047e4:	00850913          	addi	s2,a0,8
    800047e8:	854a                	mv	a0,s2
    800047ea:	ffffc097          	auipc	ra,0xffffc
    800047ee:	4b0080e7          	jalr	1200(ra) # 80000c9a <acquire>
  while (lk->locked) {
    800047f2:	409c                	lw	a5,0(s1)
    800047f4:	cb89                	beqz	a5,80004806 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047f6:	85ca                	mv	a1,s2
    800047f8:	8526                	mv	a0,s1
    800047fa:	ffffe097          	auipc	ra,0xffffe
    800047fe:	ad0080e7          	jalr	-1328(ra) # 800022ca <sleep>
  while (lk->locked) {
    80004802:	409c                	lw	a5,0(s1)
    80004804:	fbed                	bnez	a5,800047f6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004806:	4785                	li	a5,1
    80004808:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000480a:	ffffd097          	auipc	ra,0xffffd
    8000480e:	358080e7          	jalr	856(ra) # 80001b62 <myproc>
    80004812:	591c                	lw	a5,48(a0)
    80004814:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004816:	854a                	mv	a0,s2
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	536080e7          	jalr	1334(ra) # 80000d4e <release>
}
    80004820:	60e2                	ld	ra,24(sp)
    80004822:	6442                	ld	s0,16(sp)
    80004824:	64a2                	ld	s1,8(sp)
    80004826:	6902                	ld	s2,0(sp)
    80004828:	6105                	addi	sp,sp,32
    8000482a:	8082                	ret

000000008000482c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000482c:	1101                	addi	sp,sp,-32
    8000482e:	ec06                	sd	ra,24(sp)
    80004830:	e822                	sd	s0,16(sp)
    80004832:	e426                	sd	s1,8(sp)
    80004834:	e04a                	sd	s2,0(sp)
    80004836:	1000                	addi	s0,sp,32
    80004838:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000483a:	00850913          	addi	s2,a0,8
    8000483e:	854a                	mv	a0,s2
    80004840:	ffffc097          	auipc	ra,0xffffc
    80004844:	45a080e7          	jalr	1114(ra) # 80000c9a <acquire>
  lk->locked = 0;
    80004848:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000484c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004850:	8526                	mv	a0,s1
    80004852:	ffffe097          	auipc	ra,0xffffe
    80004856:	adc080e7          	jalr	-1316(ra) # 8000232e <wakeup>
  release(&lk->lk);
    8000485a:	854a                	mv	a0,s2
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	4f2080e7          	jalr	1266(ra) # 80000d4e <release>
}
    80004864:	60e2                	ld	ra,24(sp)
    80004866:	6442                	ld	s0,16(sp)
    80004868:	64a2                	ld	s1,8(sp)
    8000486a:	6902                	ld	s2,0(sp)
    8000486c:	6105                	addi	sp,sp,32
    8000486e:	8082                	ret

0000000080004870 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004870:	7179                	addi	sp,sp,-48
    80004872:	f406                	sd	ra,40(sp)
    80004874:	f022                	sd	s0,32(sp)
    80004876:	ec26                	sd	s1,24(sp)
    80004878:	e84a                	sd	s2,16(sp)
    8000487a:	e44e                	sd	s3,8(sp)
    8000487c:	1800                	addi	s0,sp,48
    8000487e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004880:	00850913          	addi	s2,a0,8
    80004884:	854a                	mv	a0,s2
    80004886:	ffffc097          	auipc	ra,0xffffc
    8000488a:	414080e7          	jalr	1044(ra) # 80000c9a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000488e:	409c                	lw	a5,0(s1)
    80004890:	ef99                	bnez	a5,800048ae <holdingsleep+0x3e>
    80004892:	4481                	li	s1,0
  release(&lk->lk);
    80004894:	854a                	mv	a0,s2
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	4b8080e7          	jalr	1208(ra) # 80000d4e <release>
  return r;
}
    8000489e:	8526                	mv	a0,s1
    800048a0:	70a2                	ld	ra,40(sp)
    800048a2:	7402                	ld	s0,32(sp)
    800048a4:	64e2                	ld	s1,24(sp)
    800048a6:	6942                	ld	s2,16(sp)
    800048a8:	69a2                	ld	s3,8(sp)
    800048aa:	6145                	addi	sp,sp,48
    800048ac:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048ae:	0284a983          	lw	s3,40(s1)
    800048b2:	ffffd097          	auipc	ra,0xffffd
    800048b6:	2b0080e7          	jalr	688(ra) # 80001b62 <myproc>
    800048ba:	5904                	lw	s1,48(a0)
    800048bc:	413484b3          	sub	s1,s1,s3
    800048c0:	0014b493          	seqz	s1,s1
    800048c4:	bfc1                	j	80004894 <holdingsleep+0x24>

00000000800048c6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048c6:	1141                	addi	sp,sp,-16
    800048c8:	e406                	sd	ra,8(sp)
    800048ca:	e022                	sd	s0,0(sp)
    800048cc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048ce:	00004597          	auipc	a1,0x4
    800048d2:	ef258593          	addi	a1,a1,-270 # 800087c0 <syscalls+0x260>
    800048d6:	0001c517          	auipc	a0,0x1c
    800048da:	51250513          	addi	a0,a0,1298 # 80020de8 <ftable>
    800048de:	ffffc097          	auipc	ra,0xffffc
    800048e2:	32c080e7          	jalr	812(ra) # 80000c0a <initlock>
}
    800048e6:	60a2                	ld	ra,8(sp)
    800048e8:	6402                	ld	s0,0(sp)
    800048ea:	0141                	addi	sp,sp,16
    800048ec:	8082                	ret

00000000800048ee <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048ee:	1101                	addi	sp,sp,-32
    800048f0:	ec06                	sd	ra,24(sp)
    800048f2:	e822                	sd	s0,16(sp)
    800048f4:	e426                	sd	s1,8(sp)
    800048f6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048f8:	0001c517          	auipc	a0,0x1c
    800048fc:	4f050513          	addi	a0,a0,1264 # 80020de8 <ftable>
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	39a080e7          	jalr	922(ra) # 80000c9a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004908:	0001c497          	auipc	s1,0x1c
    8000490c:	4f848493          	addi	s1,s1,1272 # 80020e00 <ftable+0x18>
    80004910:	0001d717          	auipc	a4,0x1d
    80004914:	49070713          	addi	a4,a4,1168 # 80021da0 <disk>
    if(f->ref == 0){
    80004918:	40dc                	lw	a5,4(s1)
    8000491a:	cf99                	beqz	a5,80004938 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000491c:	02848493          	addi	s1,s1,40
    80004920:	fee49ce3          	bne	s1,a4,80004918 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004924:	0001c517          	auipc	a0,0x1c
    80004928:	4c450513          	addi	a0,a0,1220 # 80020de8 <ftable>
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	422080e7          	jalr	1058(ra) # 80000d4e <release>
  return 0;
    80004934:	4481                	li	s1,0
    80004936:	a819                	j	8000494c <filealloc+0x5e>
      f->ref = 1;
    80004938:	4785                	li	a5,1
    8000493a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000493c:	0001c517          	auipc	a0,0x1c
    80004940:	4ac50513          	addi	a0,a0,1196 # 80020de8 <ftable>
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	40a080e7          	jalr	1034(ra) # 80000d4e <release>
}
    8000494c:	8526                	mv	a0,s1
    8000494e:	60e2                	ld	ra,24(sp)
    80004950:	6442                	ld	s0,16(sp)
    80004952:	64a2                	ld	s1,8(sp)
    80004954:	6105                	addi	sp,sp,32
    80004956:	8082                	ret

0000000080004958 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004958:	1101                	addi	sp,sp,-32
    8000495a:	ec06                	sd	ra,24(sp)
    8000495c:	e822                	sd	s0,16(sp)
    8000495e:	e426                	sd	s1,8(sp)
    80004960:	1000                	addi	s0,sp,32
    80004962:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004964:	0001c517          	auipc	a0,0x1c
    80004968:	48450513          	addi	a0,a0,1156 # 80020de8 <ftable>
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	32e080e7          	jalr	814(ra) # 80000c9a <acquire>
  if(f->ref < 1)
    80004974:	40dc                	lw	a5,4(s1)
    80004976:	02f05263          	blez	a5,8000499a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000497a:	2785                	addiw	a5,a5,1
    8000497c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000497e:	0001c517          	auipc	a0,0x1c
    80004982:	46a50513          	addi	a0,a0,1130 # 80020de8 <ftable>
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	3c8080e7          	jalr	968(ra) # 80000d4e <release>
  return f;
}
    8000498e:	8526                	mv	a0,s1
    80004990:	60e2                	ld	ra,24(sp)
    80004992:	6442                	ld	s0,16(sp)
    80004994:	64a2                	ld	s1,8(sp)
    80004996:	6105                	addi	sp,sp,32
    80004998:	8082                	ret
    panic("filedup");
    8000499a:	00004517          	auipc	a0,0x4
    8000499e:	e2e50513          	addi	a0,a0,-466 # 800087c8 <syscalls+0x268>
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	b9a080e7          	jalr	-1126(ra) # 8000053c <panic>

00000000800049aa <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049aa:	7139                	addi	sp,sp,-64
    800049ac:	fc06                	sd	ra,56(sp)
    800049ae:	f822                	sd	s0,48(sp)
    800049b0:	f426                	sd	s1,40(sp)
    800049b2:	f04a                	sd	s2,32(sp)
    800049b4:	ec4e                	sd	s3,24(sp)
    800049b6:	e852                	sd	s4,16(sp)
    800049b8:	e456                	sd	s5,8(sp)
    800049ba:	0080                	addi	s0,sp,64
    800049bc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049be:	0001c517          	auipc	a0,0x1c
    800049c2:	42a50513          	addi	a0,a0,1066 # 80020de8 <ftable>
    800049c6:	ffffc097          	auipc	ra,0xffffc
    800049ca:	2d4080e7          	jalr	724(ra) # 80000c9a <acquire>
  if(f->ref < 1)
    800049ce:	40dc                	lw	a5,4(s1)
    800049d0:	06f05163          	blez	a5,80004a32 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049d4:	37fd                	addiw	a5,a5,-1
    800049d6:	0007871b          	sext.w	a4,a5
    800049da:	c0dc                	sw	a5,4(s1)
    800049dc:	06e04363          	bgtz	a4,80004a42 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049e0:	0004a903          	lw	s2,0(s1)
    800049e4:	0094ca83          	lbu	s5,9(s1)
    800049e8:	0104ba03          	ld	s4,16(s1)
    800049ec:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049f0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049f4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049f8:	0001c517          	auipc	a0,0x1c
    800049fc:	3f050513          	addi	a0,a0,1008 # 80020de8 <ftable>
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	34e080e7          	jalr	846(ra) # 80000d4e <release>

  if(ff.type == FD_PIPE){
    80004a08:	4785                	li	a5,1
    80004a0a:	04f90d63          	beq	s2,a5,80004a64 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a0e:	3979                	addiw	s2,s2,-2
    80004a10:	4785                	li	a5,1
    80004a12:	0527e063          	bltu	a5,s2,80004a52 <fileclose+0xa8>
    begin_op();
    80004a16:	00000097          	auipc	ra,0x0
    80004a1a:	ad0080e7          	jalr	-1328(ra) # 800044e6 <begin_op>
    iput(ff.ip);
    80004a1e:	854e                	mv	a0,s3
    80004a20:	fffff097          	auipc	ra,0xfffff
    80004a24:	2da080e7          	jalr	730(ra) # 80003cfa <iput>
    end_op();
    80004a28:	00000097          	auipc	ra,0x0
    80004a2c:	b38080e7          	jalr	-1224(ra) # 80004560 <end_op>
    80004a30:	a00d                	j	80004a52 <fileclose+0xa8>
    panic("fileclose");
    80004a32:	00004517          	auipc	a0,0x4
    80004a36:	d9e50513          	addi	a0,a0,-610 # 800087d0 <syscalls+0x270>
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	b02080e7          	jalr	-1278(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004a42:	0001c517          	auipc	a0,0x1c
    80004a46:	3a650513          	addi	a0,a0,934 # 80020de8 <ftable>
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	304080e7          	jalr	772(ra) # 80000d4e <release>
  }
}
    80004a52:	70e2                	ld	ra,56(sp)
    80004a54:	7442                	ld	s0,48(sp)
    80004a56:	74a2                	ld	s1,40(sp)
    80004a58:	7902                	ld	s2,32(sp)
    80004a5a:	69e2                	ld	s3,24(sp)
    80004a5c:	6a42                	ld	s4,16(sp)
    80004a5e:	6aa2                	ld	s5,8(sp)
    80004a60:	6121                	addi	sp,sp,64
    80004a62:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a64:	85d6                	mv	a1,s5
    80004a66:	8552                	mv	a0,s4
    80004a68:	00000097          	auipc	ra,0x0
    80004a6c:	348080e7          	jalr	840(ra) # 80004db0 <pipeclose>
    80004a70:	b7cd                	j	80004a52 <fileclose+0xa8>

0000000080004a72 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a72:	715d                	addi	sp,sp,-80
    80004a74:	e486                	sd	ra,72(sp)
    80004a76:	e0a2                	sd	s0,64(sp)
    80004a78:	fc26                	sd	s1,56(sp)
    80004a7a:	f84a                	sd	s2,48(sp)
    80004a7c:	f44e                	sd	s3,40(sp)
    80004a7e:	0880                	addi	s0,sp,80
    80004a80:	84aa                	mv	s1,a0
    80004a82:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a84:	ffffd097          	auipc	ra,0xffffd
    80004a88:	0de080e7          	jalr	222(ra) # 80001b62 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a8c:	409c                	lw	a5,0(s1)
    80004a8e:	37f9                	addiw	a5,a5,-2
    80004a90:	4705                	li	a4,1
    80004a92:	04f76763          	bltu	a4,a5,80004ae0 <filestat+0x6e>
    80004a96:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a98:	6c88                	ld	a0,24(s1)
    80004a9a:	fffff097          	auipc	ra,0xfffff
    80004a9e:	0a6080e7          	jalr	166(ra) # 80003b40 <ilock>
    stati(f->ip, &st);
    80004aa2:	fb840593          	addi	a1,s0,-72
    80004aa6:	6c88                	ld	a0,24(s1)
    80004aa8:	fffff097          	auipc	ra,0xfffff
    80004aac:	322080e7          	jalr	802(ra) # 80003dca <stati>
    iunlock(f->ip);
    80004ab0:	6c88                	ld	a0,24(s1)
    80004ab2:	fffff097          	auipc	ra,0xfffff
    80004ab6:	150080e7          	jalr	336(ra) # 80003c02 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004aba:	46e1                	li	a3,24
    80004abc:	fb840613          	addi	a2,s0,-72
    80004ac0:	85ce                	mv	a1,s3
    80004ac2:	05093503          	ld	a0,80(s2)
    80004ac6:	ffffd097          	auipc	ra,0xffffd
    80004aca:	c68080e7          	jalr	-920(ra) # 8000172e <copyout>
    80004ace:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ad2:	60a6                	ld	ra,72(sp)
    80004ad4:	6406                	ld	s0,64(sp)
    80004ad6:	74e2                	ld	s1,56(sp)
    80004ad8:	7942                	ld	s2,48(sp)
    80004ada:	79a2                	ld	s3,40(sp)
    80004adc:	6161                	addi	sp,sp,80
    80004ade:	8082                	ret
  return -1;
    80004ae0:	557d                	li	a0,-1
    80004ae2:	bfc5                	j	80004ad2 <filestat+0x60>

0000000080004ae4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ae4:	7179                	addi	sp,sp,-48
    80004ae6:	f406                	sd	ra,40(sp)
    80004ae8:	f022                	sd	s0,32(sp)
    80004aea:	ec26                	sd	s1,24(sp)
    80004aec:	e84a                	sd	s2,16(sp)
    80004aee:	e44e                	sd	s3,8(sp)
    80004af0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004af2:	00854783          	lbu	a5,8(a0)
    80004af6:	c3d5                	beqz	a5,80004b9a <fileread+0xb6>
    80004af8:	84aa                	mv	s1,a0
    80004afa:	89ae                	mv	s3,a1
    80004afc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004afe:	411c                	lw	a5,0(a0)
    80004b00:	4705                	li	a4,1
    80004b02:	04e78963          	beq	a5,a4,80004b54 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b06:	470d                	li	a4,3
    80004b08:	04e78d63          	beq	a5,a4,80004b62 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b0c:	4709                	li	a4,2
    80004b0e:	06e79e63          	bne	a5,a4,80004b8a <fileread+0xa6>
    ilock(f->ip);
    80004b12:	6d08                	ld	a0,24(a0)
    80004b14:	fffff097          	auipc	ra,0xfffff
    80004b18:	02c080e7          	jalr	44(ra) # 80003b40 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b1c:	874a                	mv	a4,s2
    80004b1e:	5094                	lw	a3,32(s1)
    80004b20:	864e                	mv	a2,s3
    80004b22:	4585                	li	a1,1
    80004b24:	6c88                	ld	a0,24(s1)
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	2ce080e7          	jalr	718(ra) # 80003df4 <readi>
    80004b2e:	892a                	mv	s2,a0
    80004b30:	00a05563          	blez	a0,80004b3a <fileread+0x56>
      f->off += r;
    80004b34:	509c                	lw	a5,32(s1)
    80004b36:	9fa9                	addw	a5,a5,a0
    80004b38:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b3a:	6c88                	ld	a0,24(s1)
    80004b3c:	fffff097          	auipc	ra,0xfffff
    80004b40:	0c6080e7          	jalr	198(ra) # 80003c02 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b44:	854a                	mv	a0,s2
    80004b46:	70a2                	ld	ra,40(sp)
    80004b48:	7402                	ld	s0,32(sp)
    80004b4a:	64e2                	ld	s1,24(sp)
    80004b4c:	6942                	ld	s2,16(sp)
    80004b4e:	69a2                	ld	s3,8(sp)
    80004b50:	6145                	addi	sp,sp,48
    80004b52:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b54:	6908                	ld	a0,16(a0)
    80004b56:	00000097          	auipc	ra,0x0
    80004b5a:	3c2080e7          	jalr	962(ra) # 80004f18 <piperead>
    80004b5e:	892a                	mv	s2,a0
    80004b60:	b7d5                	j	80004b44 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b62:	02451783          	lh	a5,36(a0)
    80004b66:	03079693          	slli	a3,a5,0x30
    80004b6a:	92c1                	srli	a3,a3,0x30
    80004b6c:	4725                	li	a4,9
    80004b6e:	02d76863          	bltu	a4,a3,80004b9e <fileread+0xba>
    80004b72:	0792                	slli	a5,a5,0x4
    80004b74:	0001c717          	auipc	a4,0x1c
    80004b78:	1d470713          	addi	a4,a4,468 # 80020d48 <devsw>
    80004b7c:	97ba                	add	a5,a5,a4
    80004b7e:	639c                	ld	a5,0(a5)
    80004b80:	c38d                	beqz	a5,80004ba2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b82:	4505                	li	a0,1
    80004b84:	9782                	jalr	a5
    80004b86:	892a                	mv	s2,a0
    80004b88:	bf75                	j	80004b44 <fileread+0x60>
    panic("fileread");
    80004b8a:	00004517          	auipc	a0,0x4
    80004b8e:	c5650513          	addi	a0,a0,-938 # 800087e0 <syscalls+0x280>
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	9aa080e7          	jalr	-1622(ra) # 8000053c <panic>
    return -1;
    80004b9a:	597d                	li	s2,-1
    80004b9c:	b765                	j	80004b44 <fileread+0x60>
      return -1;
    80004b9e:	597d                	li	s2,-1
    80004ba0:	b755                	j	80004b44 <fileread+0x60>
    80004ba2:	597d                	li	s2,-1
    80004ba4:	b745                	j	80004b44 <fileread+0x60>

0000000080004ba6 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004ba6:	00954783          	lbu	a5,9(a0)
    80004baa:	10078e63          	beqz	a5,80004cc6 <filewrite+0x120>
{
    80004bae:	715d                	addi	sp,sp,-80
    80004bb0:	e486                	sd	ra,72(sp)
    80004bb2:	e0a2                	sd	s0,64(sp)
    80004bb4:	fc26                	sd	s1,56(sp)
    80004bb6:	f84a                	sd	s2,48(sp)
    80004bb8:	f44e                	sd	s3,40(sp)
    80004bba:	f052                	sd	s4,32(sp)
    80004bbc:	ec56                	sd	s5,24(sp)
    80004bbe:	e85a                	sd	s6,16(sp)
    80004bc0:	e45e                	sd	s7,8(sp)
    80004bc2:	e062                	sd	s8,0(sp)
    80004bc4:	0880                	addi	s0,sp,80
    80004bc6:	892a                	mv	s2,a0
    80004bc8:	8b2e                	mv	s6,a1
    80004bca:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bcc:	411c                	lw	a5,0(a0)
    80004bce:	4705                	li	a4,1
    80004bd0:	02e78263          	beq	a5,a4,80004bf4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bd4:	470d                	li	a4,3
    80004bd6:	02e78563          	beq	a5,a4,80004c00 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bda:	4709                	li	a4,2
    80004bdc:	0ce79d63          	bne	a5,a4,80004cb6 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004be0:	0ac05b63          	blez	a2,80004c96 <filewrite+0xf0>
    int i = 0;
    80004be4:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004be6:	6b85                	lui	s7,0x1
    80004be8:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004bec:	6c05                	lui	s8,0x1
    80004bee:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004bf2:	a851                	j	80004c86 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004bf4:	6908                	ld	a0,16(a0)
    80004bf6:	00000097          	auipc	ra,0x0
    80004bfa:	22a080e7          	jalr	554(ra) # 80004e20 <pipewrite>
    80004bfe:	a045                	j	80004c9e <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c00:	02451783          	lh	a5,36(a0)
    80004c04:	03079693          	slli	a3,a5,0x30
    80004c08:	92c1                	srli	a3,a3,0x30
    80004c0a:	4725                	li	a4,9
    80004c0c:	0ad76f63          	bltu	a4,a3,80004cca <filewrite+0x124>
    80004c10:	0792                	slli	a5,a5,0x4
    80004c12:	0001c717          	auipc	a4,0x1c
    80004c16:	13670713          	addi	a4,a4,310 # 80020d48 <devsw>
    80004c1a:	97ba                	add	a5,a5,a4
    80004c1c:	679c                	ld	a5,8(a5)
    80004c1e:	cbc5                	beqz	a5,80004cce <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004c20:	4505                	li	a0,1
    80004c22:	9782                	jalr	a5
    80004c24:	a8ad                	j	80004c9e <filewrite+0xf8>
      if(n1 > max)
    80004c26:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004c2a:	00000097          	auipc	ra,0x0
    80004c2e:	8bc080e7          	jalr	-1860(ra) # 800044e6 <begin_op>
      ilock(f->ip);
    80004c32:	01893503          	ld	a0,24(s2)
    80004c36:	fffff097          	auipc	ra,0xfffff
    80004c3a:	f0a080e7          	jalr	-246(ra) # 80003b40 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c3e:	8756                	mv	a4,s5
    80004c40:	02092683          	lw	a3,32(s2)
    80004c44:	01698633          	add	a2,s3,s6
    80004c48:	4585                	li	a1,1
    80004c4a:	01893503          	ld	a0,24(s2)
    80004c4e:	fffff097          	auipc	ra,0xfffff
    80004c52:	29e080e7          	jalr	670(ra) # 80003eec <writei>
    80004c56:	84aa                	mv	s1,a0
    80004c58:	00a05763          	blez	a0,80004c66 <filewrite+0xc0>
        f->off += r;
    80004c5c:	02092783          	lw	a5,32(s2)
    80004c60:	9fa9                	addw	a5,a5,a0
    80004c62:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c66:	01893503          	ld	a0,24(s2)
    80004c6a:	fffff097          	auipc	ra,0xfffff
    80004c6e:	f98080e7          	jalr	-104(ra) # 80003c02 <iunlock>
      end_op();
    80004c72:	00000097          	auipc	ra,0x0
    80004c76:	8ee080e7          	jalr	-1810(ra) # 80004560 <end_op>

      if(r != n1){
    80004c7a:	009a9f63          	bne	s5,s1,80004c98 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004c7e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c82:	0149db63          	bge	s3,s4,80004c98 <filewrite+0xf2>
      int n1 = n - i;
    80004c86:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004c8a:	0004879b          	sext.w	a5,s1
    80004c8e:	f8fbdce3          	bge	s7,a5,80004c26 <filewrite+0x80>
    80004c92:	84e2                	mv	s1,s8
    80004c94:	bf49                	j	80004c26 <filewrite+0x80>
    int i = 0;
    80004c96:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c98:	033a1d63          	bne	s4,s3,80004cd2 <filewrite+0x12c>
    80004c9c:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c9e:	60a6                	ld	ra,72(sp)
    80004ca0:	6406                	ld	s0,64(sp)
    80004ca2:	74e2                	ld	s1,56(sp)
    80004ca4:	7942                	ld	s2,48(sp)
    80004ca6:	79a2                	ld	s3,40(sp)
    80004ca8:	7a02                	ld	s4,32(sp)
    80004caa:	6ae2                	ld	s5,24(sp)
    80004cac:	6b42                	ld	s6,16(sp)
    80004cae:	6ba2                	ld	s7,8(sp)
    80004cb0:	6c02                	ld	s8,0(sp)
    80004cb2:	6161                	addi	sp,sp,80
    80004cb4:	8082                	ret
    panic("filewrite");
    80004cb6:	00004517          	auipc	a0,0x4
    80004cba:	b3a50513          	addi	a0,a0,-1222 # 800087f0 <syscalls+0x290>
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	87e080e7          	jalr	-1922(ra) # 8000053c <panic>
    return -1;
    80004cc6:	557d                	li	a0,-1
}
    80004cc8:	8082                	ret
      return -1;
    80004cca:	557d                	li	a0,-1
    80004ccc:	bfc9                	j	80004c9e <filewrite+0xf8>
    80004cce:	557d                	li	a0,-1
    80004cd0:	b7f9                	j	80004c9e <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004cd2:	557d                	li	a0,-1
    80004cd4:	b7e9                	j	80004c9e <filewrite+0xf8>

0000000080004cd6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004cd6:	7179                	addi	sp,sp,-48
    80004cd8:	f406                	sd	ra,40(sp)
    80004cda:	f022                	sd	s0,32(sp)
    80004cdc:	ec26                	sd	s1,24(sp)
    80004cde:	e84a                	sd	s2,16(sp)
    80004ce0:	e44e                	sd	s3,8(sp)
    80004ce2:	e052                	sd	s4,0(sp)
    80004ce4:	1800                	addi	s0,sp,48
    80004ce6:	84aa                	mv	s1,a0
    80004ce8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cea:	0005b023          	sd	zero,0(a1)
    80004cee:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cf2:	00000097          	auipc	ra,0x0
    80004cf6:	bfc080e7          	jalr	-1028(ra) # 800048ee <filealloc>
    80004cfa:	e088                	sd	a0,0(s1)
    80004cfc:	c551                	beqz	a0,80004d88 <pipealloc+0xb2>
    80004cfe:	00000097          	auipc	ra,0x0
    80004d02:	bf0080e7          	jalr	-1040(ra) # 800048ee <filealloc>
    80004d06:	00aa3023          	sd	a0,0(s4)
    80004d0a:	c92d                	beqz	a0,80004d7c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	e52080e7          	jalr	-430(ra) # 80000b5e <kalloc>
    80004d14:	892a                	mv	s2,a0
    80004d16:	c125                	beqz	a0,80004d76 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d18:	4985                	li	s3,1
    80004d1a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d1e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d22:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d26:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d2a:	00004597          	auipc	a1,0x4
    80004d2e:	ad658593          	addi	a1,a1,-1322 # 80008800 <syscalls+0x2a0>
    80004d32:	ffffc097          	auipc	ra,0xffffc
    80004d36:	ed8080e7          	jalr	-296(ra) # 80000c0a <initlock>
  (*f0)->type = FD_PIPE;
    80004d3a:	609c                	ld	a5,0(s1)
    80004d3c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d40:	609c                	ld	a5,0(s1)
    80004d42:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d46:	609c                	ld	a5,0(s1)
    80004d48:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d4c:	609c                	ld	a5,0(s1)
    80004d4e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d52:	000a3783          	ld	a5,0(s4)
    80004d56:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d5a:	000a3783          	ld	a5,0(s4)
    80004d5e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d62:	000a3783          	ld	a5,0(s4)
    80004d66:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d6a:	000a3783          	ld	a5,0(s4)
    80004d6e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d72:	4501                	li	a0,0
    80004d74:	a025                	j	80004d9c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d76:	6088                	ld	a0,0(s1)
    80004d78:	e501                	bnez	a0,80004d80 <pipealloc+0xaa>
    80004d7a:	a039                	j	80004d88 <pipealloc+0xb2>
    80004d7c:	6088                	ld	a0,0(s1)
    80004d7e:	c51d                	beqz	a0,80004dac <pipealloc+0xd6>
    fileclose(*f0);
    80004d80:	00000097          	auipc	ra,0x0
    80004d84:	c2a080e7          	jalr	-982(ra) # 800049aa <fileclose>
  if(*f1)
    80004d88:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d8c:	557d                	li	a0,-1
  if(*f1)
    80004d8e:	c799                	beqz	a5,80004d9c <pipealloc+0xc6>
    fileclose(*f1);
    80004d90:	853e                	mv	a0,a5
    80004d92:	00000097          	auipc	ra,0x0
    80004d96:	c18080e7          	jalr	-1000(ra) # 800049aa <fileclose>
  return -1;
    80004d9a:	557d                	li	a0,-1
}
    80004d9c:	70a2                	ld	ra,40(sp)
    80004d9e:	7402                	ld	s0,32(sp)
    80004da0:	64e2                	ld	s1,24(sp)
    80004da2:	6942                	ld	s2,16(sp)
    80004da4:	69a2                	ld	s3,8(sp)
    80004da6:	6a02                	ld	s4,0(sp)
    80004da8:	6145                	addi	sp,sp,48
    80004daa:	8082                	ret
  return -1;
    80004dac:	557d                	li	a0,-1
    80004dae:	b7fd                	j	80004d9c <pipealloc+0xc6>

0000000080004db0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004db0:	1101                	addi	sp,sp,-32
    80004db2:	ec06                	sd	ra,24(sp)
    80004db4:	e822                	sd	s0,16(sp)
    80004db6:	e426                	sd	s1,8(sp)
    80004db8:	e04a                	sd	s2,0(sp)
    80004dba:	1000                	addi	s0,sp,32
    80004dbc:	84aa                	mv	s1,a0
    80004dbe:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004dc0:	ffffc097          	auipc	ra,0xffffc
    80004dc4:	eda080e7          	jalr	-294(ra) # 80000c9a <acquire>
  if(writable){
    80004dc8:	02090d63          	beqz	s2,80004e02 <pipeclose+0x52>
    pi->writeopen = 0;
    80004dcc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004dd0:	21848513          	addi	a0,s1,536
    80004dd4:	ffffd097          	auipc	ra,0xffffd
    80004dd8:	55a080e7          	jalr	1370(ra) # 8000232e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ddc:	2204b783          	ld	a5,544(s1)
    80004de0:	eb95                	bnez	a5,80004e14 <pipeclose+0x64>
    release(&pi->lock);
    80004de2:	8526                	mv	a0,s1
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	f6a080e7          	jalr	-150(ra) # 80000d4e <release>
    kfree((char*)pi);
    80004dec:	8526                	mv	a0,s1
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	c08080e7          	jalr	-1016(ra) # 800009f6 <kfree>
  } else
    release(&pi->lock);
}
    80004df6:	60e2                	ld	ra,24(sp)
    80004df8:	6442                	ld	s0,16(sp)
    80004dfa:	64a2                	ld	s1,8(sp)
    80004dfc:	6902                	ld	s2,0(sp)
    80004dfe:	6105                	addi	sp,sp,32
    80004e00:	8082                	ret
    pi->readopen = 0;
    80004e02:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e06:	21c48513          	addi	a0,s1,540
    80004e0a:	ffffd097          	auipc	ra,0xffffd
    80004e0e:	524080e7          	jalr	1316(ra) # 8000232e <wakeup>
    80004e12:	b7e9                	j	80004ddc <pipeclose+0x2c>
    release(&pi->lock);
    80004e14:	8526                	mv	a0,s1
    80004e16:	ffffc097          	auipc	ra,0xffffc
    80004e1a:	f38080e7          	jalr	-200(ra) # 80000d4e <release>
}
    80004e1e:	bfe1                	j	80004df6 <pipeclose+0x46>

0000000080004e20 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e20:	711d                	addi	sp,sp,-96
    80004e22:	ec86                	sd	ra,88(sp)
    80004e24:	e8a2                	sd	s0,80(sp)
    80004e26:	e4a6                	sd	s1,72(sp)
    80004e28:	e0ca                	sd	s2,64(sp)
    80004e2a:	fc4e                	sd	s3,56(sp)
    80004e2c:	f852                	sd	s4,48(sp)
    80004e2e:	f456                	sd	s5,40(sp)
    80004e30:	f05a                	sd	s6,32(sp)
    80004e32:	ec5e                	sd	s7,24(sp)
    80004e34:	e862                	sd	s8,16(sp)
    80004e36:	1080                	addi	s0,sp,96
    80004e38:	84aa                	mv	s1,a0
    80004e3a:	8aae                	mv	s5,a1
    80004e3c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e3e:	ffffd097          	auipc	ra,0xffffd
    80004e42:	d24080e7          	jalr	-732(ra) # 80001b62 <myproc>
    80004e46:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e48:	8526                	mv	a0,s1
    80004e4a:	ffffc097          	auipc	ra,0xffffc
    80004e4e:	e50080e7          	jalr	-432(ra) # 80000c9a <acquire>
  while(i < n){
    80004e52:	0b405663          	blez	s4,80004efe <pipewrite+0xde>
  int i = 0;
    80004e56:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e58:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e5a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e5e:	21c48b93          	addi	s7,s1,540
    80004e62:	a089                	j	80004ea4 <pipewrite+0x84>
      release(&pi->lock);
    80004e64:	8526                	mv	a0,s1
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	ee8080e7          	jalr	-280(ra) # 80000d4e <release>
      return -1;
    80004e6e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e70:	854a                	mv	a0,s2
    80004e72:	60e6                	ld	ra,88(sp)
    80004e74:	6446                	ld	s0,80(sp)
    80004e76:	64a6                	ld	s1,72(sp)
    80004e78:	6906                	ld	s2,64(sp)
    80004e7a:	79e2                	ld	s3,56(sp)
    80004e7c:	7a42                	ld	s4,48(sp)
    80004e7e:	7aa2                	ld	s5,40(sp)
    80004e80:	7b02                	ld	s6,32(sp)
    80004e82:	6be2                	ld	s7,24(sp)
    80004e84:	6c42                	ld	s8,16(sp)
    80004e86:	6125                	addi	sp,sp,96
    80004e88:	8082                	ret
      wakeup(&pi->nread);
    80004e8a:	8562                	mv	a0,s8
    80004e8c:	ffffd097          	auipc	ra,0xffffd
    80004e90:	4a2080e7          	jalr	1186(ra) # 8000232e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e94:	85a6                	mv	a1,s1
    80004e96:	855e                	mv	a0,s7
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	432080e7          	jalr	1074(ra) # 800022ca <sleep>
  while(i < n){
    80004ea0:	07495063          	bge	s2,s4,80004f00 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004ea4:	2204a783          	lw	a5,544(s1)
    80004ea8:	dfd5                	beqz	a5,80004e64 <pipewrite+0x44>
    80004eaa:	854e                	mv	a0,s3
    80004eac:	ffffd097          	auipc	ra,0xffffd
    80004eb0:	6c6080e7          	jalr	1734(ra) # 80002572 <killed>
    80004eb4:	f945                	bnez	a0,80004e64 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004eb6:	2184a783          	lw	a5,536(s1)
    80004eba:	21c4a703          	lw	a4,540(s1)
    80004ebe:	2007879b          	addiw	a5,a5,512
    80004ec2:	fcf704e3          	beq	a4,a5,80004e8a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ec6:	4685                	li	a3,1
    80004ec8:	01590633          	add	a2,s2,s5
    80004ecc:	faf40593          	addi	a1,s0,-81
    80004ed0:	0509b503          	ld	a0,80(s3)
    80004ed4:	ffffd097          	auipc	ra,0xffffd
    80004ed8:	8e6080e7          	jalr	-1818(ra) # 800017ba <copyin>
    80004edc:	03650263          	beq	a0,s6,80004f00 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ee0:	21c4a783          	lw	a5,540(s1)
    80004ee4:	0017871b          	addiw	a4,a5,1
    80004ee8:	20e4ae23          	sw	a4,540(s1)
    80004eec:	1ff7f793          	andi	a5,a5,511
    80004ef0:	97a6                	add	a5,a5,s1
    80004ef2:	faf44703          	lbu	a4,-81(s0)
    80004ef6:	00e78c23          	sb	a4,24(a5)
      i++;
    80004efa:	2905                	addiw	s2,s2,1
    80004efc:	b755                	j	80004ea0 <pipewrite+0x80>
  int i = 0;
    80004efe:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f00:	21848513          	addi	a0,s1,536
    80004f04:	ffffd097          	auipc	ra,0xffffd
    80004f08:	42a080e7          	jalr	1066(ra) # 8000232e <wakeup>
  release(&pi->lock);
    80004f0c:	8526                	mv	a0,s1
    80004f0e:	ffffc097          	auipc	ra,0xffffc
    80004f12:	e40080e7          	jalr	-448(ra) # 80000d4e <release>
  return i;
    80004f16:	bfa9                	j	80004e70 <pipewrite+0x50>

0000000080004f18 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f18:	715d                	addi	sp,sp,-80
    80004f1a:	e486                	sd	ra,72(sp)
    80004f1c:	e0a2                	sd	s0,64(sp)
    80004f1e:	fc26                	sd	s1,56(sp)
    80004f20:	f84a                	sd	s2,48(sp)
    80004f22:	f44e                	sd	s3,40(sp)
    80004f24:	f052                	sd	s4,32(sp)
    80004f26:	ec56                	sd	s5,24(sp)
    80004f28:	e85a                	sd	s6,16(sp)
    80004f2a:	0880                	addi	s0,sp,80
    80004f2c:	84aa                	mv	s1,a0
    80004f2e:	892e                	mv	s2,a1
    80004f30:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f32:	ffffd097          	auipc	ra,0xffffd
    80004f36:	c30080e7          	jalr	-976(ra) # 80001b62 <myproc>
    80004f3a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f3c:	8526                	mv	a0,s1
    80004f3e:	ffffc097          	auipc	ra,0xffffc
    80004f42:	d5c080e7          	jalr	-676(ra) # 80000c9a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f46:	2184a703          	lw	a4,536(s1)
    80004f4a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f4e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f52:	02f71763          	bne	a4,a5,80004f80 <piperead+0x68>
    80004f56:	2244a783          	lw	a5,548(s1)
    80004f5a:	c39d                	beqz	a5,80004f80 <piperead+0x68>
    if(killed(pr)){
    80004f5c:	8552                	mv	a0,s4
    80004f5e:	ffffd097          	auipc	ra,0xffffd
    80004f62:	614080e7          	jalr	1556(ra) # 80002572 <killed>
    80004f66:	e949                	bnez	a0,80004ff8 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f68:	85a6                	mv	a1,s1
    80004f6a:	854e                	mv	a0,s3
    80004f6c:	ffffd097          	auipc	ra,0xffffd
    80004f70:	35e080e7          	jalr	862(ra) # 800022ca <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f74:	2184a703          	lw	a4,536(s1)
    80004f78:	21c4a783          	lw	a5,540(s1)
    80004f7c:	fcf70de3          	beq	a4,a5,80004f56 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f80:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f82:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f84:	05505463          	blez	s5,80004fcc <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004f88:	2184a783          	lw	a5,536(s1)
    80004f8c:	21c4a703          	lw	a4,540(s1)
    80004f90:	02f70e63          	beq	a4,a5,80004fcc <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f94:	0017871b          	addiw	a4,a5,1
    80004f98:	20e4ac23          	sw	a4,536(s1)
    80004f9c:	1ff7f793          	andi	a5,a5,511
    80004fa0:	97a6                	add	a5,a5,s1
    80004fa2:	0187c783          	lbu	a5,24(a5)
    80004fa6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004faa:	4685                	li	a3,1
    80004fac:	fbf40613          	addi	a2,s0,-65
    80004fb0:	85ca                	mv	a1,s2
    80004fb2:	050a3503          	ld	a0,80(s4)
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	778080e7          	jalr	1912(ra) # 8000172e <copyout>
    80004fbe:	01650763          	beq	a0,s6,80004fcc <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fc2:	2985                	addiw	s3,s3,1
    80004fc4:	0905                	addi	s2,s2,1
    80004fc6:	fd3a91e3          	bne	s5,s3,80004f88 <piperead+0x70>
    80004fca:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fcc:	21c48513          	addi	a0,s1,540
    80004fd0:	ffffd097          	auipc	ra,0xffffd
    80004fd4:	35e080e7          	jalr	862(ra) # 8000232e <wakeup>
  release(&pi->lock);
    80004fd8:	8526                	mv	a0,s1
    80004fda:	ffffc097          	auipc	ra,0xffffc
    80004fde:	d74080e7          	jalr	-652(ra) # 80000d4e <release>
  return i;
}
    80004fe2:	854e                	mv	a0,s3
    80004fe4:	60a6                	ld	ra,72(sp)
    80004fe6:	6406                	ld	s0,64(sp)
    80004fe8:	74e2                	ld	s1,56(sp)
    80004fea:	7942                	ld	s2,48(sp)
    80004fec:	79a2                	ld	s3,40(sp)
    80004fee:	7a02                	ld	s4,32(sp)
    80004ff0:	6ae2                	ld	s5,24(sp)
    80004ff2:	6b42                	ld	s6,16(sp)
    80004ff4:	6161                	addi	sp,sp,80
    80004ff6:	8082                	ret
      release(&pi->lock);
    80004ff8:	8526                	mv	a0,s1
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	d54080e7          	jalr	-684(ra) # 80000d4e <release>
      return -1;
    80005002:	59fd                	li	s3,-1
    80005004:	bff9                	j	80004fe2 <piperead+0xca>

0000000080005006 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005006:	1141                	addi	sp,sp,-16
    80005008:	e422                	sd	s0,8(sp)
    8000500a:	0800                	addi	s0,sp,16
    8000500c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000500e:	8905                	andi	a0,a0,1
    80005010:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005012:	8b89                	andi	a5,a5,2
    80005014:	c399                	beqz	a5,8000501a <flags2perm+0x14>
      perm |= PTE_W;
    80005016:	00456513          	ori	a0,a0,4
    return perm;
}
    8000501a:	6422                	ld	s0,8(sp)
    8000501c:	0141                	addi	sp,sp,16
    8000501e:	8082                	ret

0000000080005020 <exec>:

int
exec(char *path, char **argv)
{
    80005020:	df010113          	addi	sp,sp,-528
    80005024:	20113423          	sd	ra,520(sp)
    80005028:	20813023          	sd	s0,512(sp)
    8000502c:	ffa6                	sd	s1,504(sp)
    8000502e:	fbca                	sd	s2,496(sp)
    80005030:	f7ce                	sd	s3,488(sp)
    80005032:	f3d2                	sd	s4,480(sp)
    80005034:	efd6                	sd	s5,472(sp)
    80005036:	ebda                	sd	s6,464(sp)
    80005038:	e7de                	sd	s7,456(sp)
    8000503a:	e3e2                	sd	s8,448(sp)
    8000503c:	ff66                	sd	s9,440(sp)
    8000503e:	fb6a                	sd	s10,432(sp)
    80005040:	f76e                	sd	s11,424(sp)
    80005042:	0c00                	addi	s0,sp,528
    80005044:	892a                	mv	s2,a0
    80005046:	dea43c23          	sd	a0,-520(s0)
    8000504a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000504e:	ffffd097          	auipc	ra,0xffffd
    80005052:	b14080e7          	jalr	-1260(ra) # 80001b62 <myproc>
    80005056:	84aa                	mv	s1,a0

  begin_op();
    80005058:	fffff097          	auipc	ra,0xfffff
    8000505c:	48e080e7          	jalr	1166(ra) # 800044e6 <begin_op>

  if((ip = namei(path)) == 0){
    80005060:	854a                	mv	a0,s2
    80005062:	fffff097          	auipc	ra,0xfffff
    80005066:	284080e7          	jalr	644(ra) # 800042e6 <namei>
    8000506a:	c92d                	beqz	a0,800050dc <exec+0xbc>
    8000506c:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000506e:	fffff097          	auipc	ra,0xfffff
    80005072:	ad2080e7          	jalr	-1326(ra) # 80003b40 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005076:	04000713          	li	a4,64
    8000507a:	4681                	li	a3,0
    8000507c:	e5040613          	addi	a2,s0,-432
    80005080:	4581                	li	a1,0
    80005082:	8552                	mv	a0,s4
    80005084:	fffff097          	auipc	ra,0xfffff
    80005088:	d70080e7          	jalr	-656(ra) # 80003df4 <readi>
    8000508c:	04000793          	li	a5,64
    80005090:	00f51a63          	bne	a0,a5,800050a4 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005094:	e5042703          	lw	a4,-432(s0)
    80005098:	464c47b7          	lui	a5,0x464c4
    8000509c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050a0:	04f70463          	beq	a4,a5,800050e8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050a4:	8552                	mv	a0,s4
    800050a6:	fffff097          	auipc	ra,0xfffff
    800050aa:	cfc080e7          	jalr	-772(ra) # 80003da2 <iunlockput>
    end_op();
    800050ae:	fffff097          	auipc	ra,0xfffff
    800050b2:	4b2080e7          	jalr	1202(ra) # 80004560 <end_op>
  }
  return -1;
    800050b6:	557d                	li	a0,-1
}
    800050b8:	20813083          	ld	ra,520(sp)
    800050bc:	20013403          	ld	s0,512(sp)
    800050c0:	74fe                	ld	s1,504(sp)
    800050c2:	795e                	ld	s2,496(sp)
    800050c4:	79be                	ld	s3,488(sp)
    800050c6:	7a1e                	ld	s4,480(sp)
    800050c8:	6afe                	ld	s5,472(sp)
    800050ca:	6b5e                	ld	s6,464(sp)
    800050cc:	6bbe                	ld	s7,456(sp)
    800050ce:	6c1e                	ld	s8,448(sp)
    800050d0:	7cfa                	ld	s9,440(sp)
    800050d2:	7d5a                	ld	s10,432(sp)
    800050d4:	7dba                	ld	s11,424(sp)
    800050d6:	21010113          	addi	sp,sp,528
    800050da:	8082                	ret
    end_op();
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	484080e7          	jalr	1156(ra) # 80004560 <end_op>
    return -1;
    800050e4:	557d                	li	a0,-1
    800050e6:	bfc9                	j	800050b8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800050e8:	8526                	mv	a0,s1
    800050ea:	ffffd097          	auipc	ra,0xffffd
    800050ee:	b3c080e7          	jalr	-1220(ra) # 80001c26 <proc_pagetable>
    800050f2:	8b2a                	mv	s6,a0
    800050f4:	d945                	beqz	a0,800050a4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050f6:	e7042d03          	lw	s10,-400(s0)
    800050fa:	e8845783          	lhu	a5,-376(s0)
    800050fe:	10078463          	beqz	a5,80005206 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005102:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005104:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005106:	6c85                	lui	s9,0x1
    80005108:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000510c:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005110:	6a85                	lui	s5,0x1
    80005112:	a0b5                	j	8000517e <exec+0x15e>
      panic("loadseg: address should exist");
    80005114:	00003517          	auipc	a0,0x3
    80005118:	6f450513          	addi	a0,a0,1780 # 80008808 <syscalls+0x2a8>
    8000511c:	ffffb097          	auipc	ra,0xffffb
    80005120:	420080e7          	jalr	1056(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005124:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005126:	8726                	mv	a4,s1
    80005128:	012c06bb          	addw	a3,s8,s2
    8000512c:	4581                	li	a1,0
    8000512e:	8552                	mv	a0,s4
    80005130:	fffff097          	auipc	ra,0xfffff
    80005134:	cc4080e7          	jalr	-828(ra) # 80003df4 <readi>
    80005138:	2501                	sext.w	a0,a0
    8000513a:	24a49863          	bne	s1,a0,8000538a <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    8000513e:	012a893b          	addw	s2,s5,s2
    80005142:	03397563          	bgeu	s2,s3,8000516c <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005146:	02091593          	slli	a1,s2,0x20
    8000514a:	9181                	srli	a1,a1,0x20
    8000514c:	95de                	add	a1,a1,s7
    8000514e:	855a                	mv	a0,s6
    80005150:	ffffc097          	auipc	ra,0xffffc
    80005154:	fce080e7          	jalr	-50(ra) # 8000111e <walkaddr>
    80005158:	862a                	mv	a2,a0
    if(pa == 0)
    8000515a:	dd4d                	beqz	a0,80005114 <exec+0xf4>
    if(sz - i < PGSIZE)
    8000515c:	412984bb          	subw	s1,s3,s2
    80005160:	0004879b          	sext.w	a5,s1
    80005164:	fcfcf0e3          	bgeu	s9,a5,80005124 <exec+0x104>
    80005168:	84d6                	mv	s1,s5
    8000516a:	bf6d                	j	80005124 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000516c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005170:	2d85                	addiw	s11,s11,1
    80005172:	038d0d1b          	addiw	s10,s10,56
    80005176:	e8845783          	lhu	a5,-376(s0)
    8000517a:	08fdd763          	bge	s11,a5,80005208 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000517e:	2d01                	sext.w	s10,s10
    80005180:	03800713          	li	a4,56
    80005184:	86ea                	mv	a3,s10
    80005186:	e1840613          	addi	a2,s0,-488
    8000518a:	4581                	li	a1,0
    8000518c:	8552                	mv	a0,s4
    8000518e:	fffff097          	auipc	ra,0xfffff
    80005192:	c66080e7          	jalr	-922(ra) # 80003df4 <readi>
    80005196:	03800793          	li	a5,56
    8000519a:	1ef51663          	bne	a0,a5,80005386 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    8000519e:	e1842783          	lw	a5,-488(s0)
    800051a2:	4705                	li	a4,1
    800051a4:	fce796e3          	bne	a5,a4,80005170 <exec+0x150>
    if(ph.memsz < ph.filesz)
    800051a8:	e4043483          	ld	s1,-448(s0)
    800051ac:	e3843783          	ld	a5,-456(s0)
    800051b0:	1ef4e863          	bltu	s1,a5,800053a0 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051b4:	e2843783          	ld	a5,-472(s0)
    800051b8:	94be                	add	s1,s1,a5
    800051ba:	1ef4e663          	bltu	s1,a5,800053a6 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800051be:	df043703          	ld	a4,-528(s0)
    800051c2:	8ff9                	and	a5,a5,a4
    800051c4:	1e079463          	bnez	a5,800053ac <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051c8:	e1c42503          	lw	a0,-484(s0)
    800051cc:	00000097          	auipc	ra,0x0
    800051d0:	e3a080e7          	jalr	-454(ra) # 80005006 <flags2perm>
    800051d4:	86aa                	mv	a3,a0
    800051d6:	8626                	mv	a2,s1
    800051d8:	85ca                	mv	a1,s2
    800051da:	855a                	mv	a0,s6
    800051dc:	ffffc097          	auipc	ra,0xffffc
    800051e0:	2f6080e7          	jalr	758(ra) # 800014d2 <uvmalloc>
    800051e4:	e0a43423          	sd	a0,-504(s0)
    800051e8:	1c050563          	beqz	a0,800053b2 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051ec:	e2843b83          	ld	s7,-472(s0)
    800051f0:	e2042c03          	lw	s8,-480(s0)
    800051f4:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051f8:	00098463          	beqz	s3,80005200 <exec+0x1e0>
    800051fc:	4901                	li	s2,0
    800051fe:	b7a1                	j	80005146 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005200:	e0843903          	ld	s2,-504(s0)
    80005204:	b7b5                	j	80005170 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005206:	4901                	li	s2,0
  iunlockput(ip);
    80005208:	8552                	mv	a0,s4
    8000520a:	fffff097          	auipc	ra,0xfffff
    8000520e:	b98080e7          	jalr	-1128(ra) # 80003da2 <iunlockput>
  end_op();
    80005212:	fffff097          	auipc	ra,0xfffff
    80005216:	34e080e7          	jalr	846(ra) # 80004560 <end_op>
  p = myproc();
    8000521a:	ffffd097          	auipc	ra,0xffffd
    8000521e:	948080e7          	jalr	-1720(ra) # 80001b62 <myproc>
    80005222:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005224:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005228:	6985                	lui	s3,0x1
    8000522a:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    8000522c:	99ca                	add	s3,s3,s2
    8000522e:	77fd                	lui	a5,0xfffff
    80005230:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005234:	4691                	li	a3,4
    80005236:	6609                	lui	a2,0x2
    80005238:	964e                	add	a2,a2,s3
    8000523a:	85ce                	mv	a1,s3
    8000523c:	855a                	mv	a0,s6
    8000523e:	ffffc097          	auipc	ra,0xffffc
    80005242:	294080e7          	jalr	660(ra) # 800014d2 <uvmalloc>
    80005246:	892a                	mv	s2,a0
    80005248:	e0a43423          	sd	a0,-504(s0)
    8000524c:	e509                	bnez	a0,80005256 <exec+0x236>
  if(pagetable)
    8000524e:	e1343423          	sd	s3,-504(s0)
    80005252:	4a01                	li	s4,0
    80005254:	aa1d                	j	8000538a <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005256:	75f9                	lui	a1,0xffffe
    80005258:	95aa                	add	a1,a1,a0
    8000525a:	855a                	mv	a0,s6
    8000525c:	ffffc097          	auipc	ra,0xffffc
    80005260:	4a0080e7          	jalr	1184(ra) # 800016fc <uvmclear>
  stackbase = sp - PGSIZE;
    80005264:	7bfd                	lui	s7,0xfffff
    80005266:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005268:	e0043783          	ld	a5,-512(s0)
    8000526c:	6388                	ld	a0,0(a5)
    8000526e:	c52d                	beqz	a0,800052d8 <exec+0x2b8>
    80005270:	e9040993          	addi	s3,s0,-368
    80005274:	f9040c13          	addi	s8,s0,-112
    80005278:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000527a:	ffffc097          	auipc	ra,0xffffc
    8000527e:	c96080e7          	jalr	-874(ra) # 80000f10 <strlen>
    80005282:	0015079b          	addiw	a5,a0,1
    80005286:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000528a:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000528e:	13796563          	bltu	s2,s7,800053b8 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005292:	e0043d03          	ld	s10,-512(s0)
    80005296:	000d3a03          	ld	s4,0(s10)
    8000529a:	8552                	mv	a0,s4
    8000529c:	ffffc097          	auipc	ra,0xffffc
    800052a0:	c74080e7          	jalr	-908(ra) # 80000f10 <strlen>
    800052a4:	0015069b          	addiw	a3,a0,1
    800052a8:	8652                	mv	a2,s4
    800052aa:	85ca                	mv	a1,s2
    800052ac:	855a                	mv	a0,s6
    800052ae:	ffffc097          	auipc	ra,0xffffc
    800052b2:	480080e7          	jalr	1152(ra) # 8000172e <copyout>
    800052b6:	10054363          	bltz	a0,800053bc <exec+0x39c>
    ustack[argc] = sp;
    800052ba:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052be:	0485                	addi	s1,s1,1
    800052c0:	008d0793          	addi	a5,s10,8
    800052c4:	e0f43023          	sd	a5,-512(s0)
    800052c8:	008d3503          	ld	a0,8(s10)
    800052cc:	c909                	beqz	a0,800052de <exec+0x2be>
    if(argc >= MAXARG)
    800052ce:	09a1                	addi	s3,s3,8
    800052d0:	fb8995e3          	bne	s3,s8,8000527a <exec+0x25a>
  ip = 0;
    800052d4:	4a01                	li	s4,0
    800052d6:	a855                	j	8000538a <exec+0x36a>
  sp = sz;
    800052d8:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800052dc:	4481                	li	s1,0
  ustack[argc] = 0;
    800052de:	00349793          	slli	a5,s1,0x3
    800052e2:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdd0b0>
    800052e6:	97a2                	add	a5,a5,s0
    800052e8:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800052ec:	00148693          	addi	a3,s1,1
    800052f0:	068e                	slli	a3,a3,0x3
    800052f2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052f6:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    800052fa:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800052fe:	f57968e3          	bltu	s2,s7,8000524e <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005302:	e9040613          	addi	a2,s0,-368
    80005306:	85ca                	mv	a1,s2
    80005308:	855a                	mv	a0,s6
    8000530a:	ffffc097          	auipc	ra,0xffffc
    8000530e:	424080e7          	jalr	1060(ra) # 8000172e <copyout>
    80005312:	0a054763          	bltz	a0,800053c0 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005316:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    8000531a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000531e:	df843783          	ld	a5,-520(s0)
    80005322:	0007c703          	lbu	a4,0(a5)
    80005326:	cf11                	beqz	a4,80005342 <exec+0x322>
    80005328:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000532a:	02f00693          	li	a3,47
    8000532e:	a039                	j	8000533c <exec+0x31c>
      last = s+1;
    80005330:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005334:	0785                	addi	a5,a5,1
    80005336:	fff7c703          	lbu	a4,-1(a5)
    8000533a:	c701                	beqz	a4,80005342 <exec+0x322>
    if(*s == '/')
    8000533c:	fed71ce3          	bne	a4,a3,80005334 <exec+0x314>
    80005340:	bfc5                	j	80005330 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80005342:	4641                	li	a2,16
    80005344:	df843583          	ld	a1,-520(s0)
    80005348:	158a8513          	addi	a0,s5,344
    8000534c:	ffffc097          	auipc	ra,0xffffc
    80005350:	b92080e7          	jalr	-1134(ra) # 80000ede <safestrcpy>
  oldpagetable = p->pagetable;
    80005354:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005358:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000535c:	e0843783          	ld	a5,-504(s0)
    80005360:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005364:	058ab783          	ld	a5,88(s5)
    80005368:	e6843703          	ld	a4,-408(s0)
    8000536c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000536e:	058ab783          	ld	a5,88(s5)
    80005372:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005376:	85e6                	mv	a1,s9
    80005378:	ffffd097          	auipc	ra,0xffffd
    8000537c:	94a080e7          	jalr	-1718(ra) # 80001cc2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005380:	0004851b          	sext.w	a0,s1
    80005384:	bb15                	j	800050b8 <exec+0x98>
    80005386:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000538a:	e0843583          	ld	a1,-504(s0)
    8000538e:	855a                	mv	a0,s6
    80005390:	ffffd097          	auipc	ra,0xffffd
    80005394:	932080e7          	jalr	-1742(ra) # 80001cc2 <proc_freepagetable>
  return -1;
    80005398:	557d                	li	a0,-1
  if(ip){
    8000539a:	d00a0fe3          	beqz	s4,800050b8 <exec+0x98>
    8000539e:	b319                	j	800050a4 <exec+0x84>
    800053a0:	e1243423          	sd	s2,-504(s0)
    800053a4:	b7dd                	j	8000538a <exec+0x36a>
    800053a6:	e1243423          	sd	s2,-504(s0)
    800053aa:	b7c5                	j	8000538a <exec+0x36a>
    800053ac:	e1243423          	sd	s2,-504(s0)
    800053b0:	bfe9                	j	8000538a <exec+0x36a>
    800053b2:	e1243423          	sd	s2,-504(s0)
    800053b6:	bfd1                	j	8000538a <exec+0x36a>
  ip = 0;
    800053b8:	4a01                	li	s4,0
    800053ba:	bfc1                	j	8000538a <exec+0x36a>
    800053bc:	4a01                	li	s4,0
  if(pagetable)
    800053be:	b7f1                	j	8000538a <exec+0x36a>
  sz = sz1;
    800053c0:	e0843983          	ld	s3,-504(s0)
    800053c4:	b569                	j	8000524e <exec+0x22e>

00000000800053c6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053c6:	7179                	addi	sp,sp,-48
    800053c8:	f406                	sd	ra,40(sp)
    800053ca:	f022                	sd	s0,32(sp)
    800053cc:	ec26                	sd	s1,24(sp)
    800053ce:	e84a                	sd	s2,16(sp)
    800053d0:	1800                	addi	s0,sp,48
    800053d2:	892e                	mv	s2,a1
    800053d4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800053d6:	fdc40593          	addi	a1,s0,-36
    800053da:	ffffe097          	auipc	ra,0xffffe
    800053de:	b06080e7          	jalr	-1274(ra) # 80002ee0 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053e2:	fdc42703          	lw	a4,-36(s0)
    800053e6:	47bd                	li	a5,15
    800053e8:	02e7eb63          	bltu	a5,a4,8000541e <argfd+0x58>
    800053ec:	ffffc097          	auipc	ra,0xffffc
    800053f0:	776080e7          	jalr	1910(ra) # 80001b62 <myproc>
    800053f4:	fdc42703          	lw	a4,-36(s0)
    800053f8:	01a70793          	addi	a5,a4,26
    800053fc:	078e                	slli	a5,a5,0x3
    800053fe:	953e                	add	a0,a0,a5
    80005400:	611c                	ld	a5,0(a0)
    80005402:	c385                	beqz	a5,80005422 <argfd+0x5c>
    return -1;
  if(pfd)
    80005404:	00090463          	beqz	s2,8000540c <argfd+0x46>
    *pfd = fd;
    80005408:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000540c:	4501                	li	a0,0
  if(pf)
    8000540e:	c091                	beqz	s1,80005412 <argfd+0x4c>
    *pf = f;
    80005410:	e09c                	sd	a5,0(s1)
}
    80005412:	70a2                	ld	ra,40(sp)
    80005414:	7402                	ld	s0,32(sp)
    80005416:	64e2                	ld	s1,24(sp)
    80005418:	6942                	ld	s2,16(sp)
    8000541a:	6145                	addi	sp,sp,48
    8000541c:	8082                	ret
    return -1;
    8000541e:	557d                	li	a0,-1
    80005420:	bfcd                	j	80005412 <argfd+0x4c>
    80005422:	557d                	li	a0,-1
    80005424:	b7fd                	j	80005412 <argfd+0x4c>

0000000080005426 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005426:	1101                	addi	sp,sp,-32
    80005428:	ec06                	sd	ra,24(sp)
    8000542a:	e822                	sd	s0,16(sp)
    8000542c:	e426                	sd	s1,8(sp)
    8000542e:	1000                	addi	s0,sp,32
    80005430:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005432:	ffffc097          	auipc	ra,0xffffc
    80005436:	730080e7          	jalr	1840(ra) # 80001b62 <myproc>
    8000543a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000543c:	0d050793          	addi	a5,a0,208
    80005440:	4501                	li	a0,0
    80005442:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005444:	6398                	ld	a4,0(a5)
    80005446:	cb19                	beqz	a4,8000545c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005448:	2505                	addiw	a0,a0,1
    8000544a:	07a1                	addi	a5,a5,8
    8000544c:	fed51ce3          	bne	a0,a3,80005444 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005450:	557d                	li	a0,-1
}
    80005452:	60e2                	ld	ra,24(sp)
    80005454:	6442                	ld	s0,16(sp)
    80005456:	64a2                	ld	s1,8(sp)
    80005458:	6105                	addi	sp,sp,32
    8000545a:	8082                	ret
      p->ofile[fd] = f;
    8000545c:	01a50793          	addi	a5,a0,26
    80005460:	078e                	slli	a5,a5,0x3
    80005462:	963e                	add	a2,a2,a5
    80005464:	e204                	sd	s1,0(a2)
      return fd;
    80005466:	b7f5                	j	80005452 <fdalloc+0x2c>

0000000080005468 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005468:	715d                	addi	sp,sp,-80
    8000546a:	e486                	sd	ra,72(sp)
    8000546c:	e0a2                	sd	s0,64(sp)
    8000546e:	fc26                	sd	s1,56(sp)
    80005470:	f84a                	sd	s2,48(sp)
    80005472:	f44e                	sd	s3,40(sp)
    80005474:	f052                	sd	s4,32(sp)
    80005476:	ec56                	sd	s5,24(sp)
    80005478:	e85a                	sd	s6,16(sp)
    8000547a:	0880                	addi	s0,sp,80
    8000547c:	8b2e                	mv	s6,a1
    8000547e:	89b2                	mv	s3,a2
    80005480:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005482:	fb040593          	addi	a1,s0,-80
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	e7e080e7          	jalr	-386(ra) # 80004304 <nameiparent>
    8000548e:	84aa                	mv	s1,a0
    80005490:	14050b63          	beqz	a0,800055e6 <create+0x17e>
    return 0;

  ilock(dp);
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	6ac080e7          	jalr	1708(ra) # 80003b40 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000549c:	4601                	li	a2,0
    8000549e:	fb040593          	addi	a1,s0,-80
    800054a2:	8526                	mv	a0,s1
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	b80080e7          	jalr	-1152(ra) # 80004024 <dirlookup>
    800054ac:	8aaa                	mv	s5,a0
    800054ae:	c921                	beqz	a0,800054fe <create+0x96>
    iunlockput(dp);
    800054b0:	8526                	mv	a0,s1
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	8f0080e7          	jalr	-1808(ra) # 80003da2 <iunlockput>
    ilock(ip);
    800054ba:	8556                	mv	a0,s5
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	684080e7          	jalr	1668(ra) # 80003b40 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054c4:	4789                	li	a5,2
    800054c6:	02fb1563          	bne	s6,a5,800054f0 <create+0x88>
    800054ca:	044ad783          	lhu	a5,68(s5)
    800054ce:	37f9                	addiw	a5,a5,-2
    800054d0:	17c2                	slli	a5,a5,0x30
    800054d2:	93c1                	srli	a5,a5,0x30
    800054d4:	4705                	li	a4,1
    800054d6:	00f76d63          	bltu	a4,a5,800054f0 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800054da:	8556                	mv	a0,s5
    800054dc:	60a6                	ld	ra,72(sp)
    800054de:	6406                	ld	s0,64(sp)
    800054e0:	74e2                	ld	s1,56(sp)
    800054e2:	7942                	ld	s2,48(sp)
    800054e4:	79a2                	ld	s3,40(sp)
    800054e6:	7a02                	ld	s4,32(sp)
    800054e8:	6ae2                	ld	s5,24(sp)
    800054ea:	6b42                	ld	s6,16(sp)
    800054ec:	6161                	addi	sp,sp,80
    800054ee:	8082                	ret
    iunlockput(ip);
    800054f0:	8556                	mv	a0,s5
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	8b0080e7          	jalr	-1872(ra) # 80003da2 <iunlockput>
    return 0;
    800054fa:	4a81                	li	s5,0
    800054fc:	bff9                	j	800054da <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    800054fe:	85da                	mv	a1,s6
    80005500:	4088                	lw	a0,0(s1)
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	4a6080e7          	jalr	1190(ra) # 800039a8 <ialloc>
    8000550a:	8a2a                	mv	s4,a0
    8000550c:	c529                	beqz	a0,80005556 <create+0xee>
  ilock(ip);
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	632080e7          	jalr	1586(ra) # 80003b40 <ilock>
  ip->major = major;
    80005516:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000551a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000551e:	4905                	li	s2,1
    80005520:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005524:	8552                	mv	a0,s4
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	54e080e7          	jalr	1358(ra) # 80003a74 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000552e:	032b0b63          	beq	s6,s2,80005564 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005532:	004a2603          	lw	a2,4(s4)
    80005536:	fb040593          	addi	a1,s0,-80
    8000553a:	8526                	mv	a0,s1
    8000553c:	fffff097          	auipc	ra,0xfffff
    80005540:	cf8080e7          	jalr	-776(ra) # 80004234 <dirlink>
    80005544:	06054f63          	bltz	a0,800055c2 <create+0x15a>
  iunlockput(dp);
    80005548:	8526                	mv	a0,s1
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	858080e7          	jalr	-1960(ra) # 80003da2 <iunlockput>
  return ip;
    80005552:	8ad2                	mv	s5,s4
    80005554:	b759                	j	800054da <create+0x72>
    iunlockput(dp);
    80005556:	8526                	mv	a0,s1
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	84a080e7          	jalr	-1974(ra) # 80003da2 <iunlockput>
    return 0;
    80005560:	8ad2                	mv	s5,s4
    80005562:	bfa5                	j	800054da <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005564:	004a2603          	lw	a2,4(s4)
    80005568:	00003597          	auipc	a1,0x3
    8000556c:	2c058593          	addi	a1,a1,704 # 80008828 <syscalls+0x2c8>
    80005570:	8552                	mv	a0,s4
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	cc2080e7          	jalr	-830(ra) # 80004234 <dirlink>
    8000557a:	04054463          	bltz	a0,800055c2 <create+0x15a>
    8000557e:	40d0                	lw	a2,4(s1)
    80005580:	00003597          	auipc	a1,0x3
    80005584:	2b058593          	addi	a1,a1,688 # 80008830 <syscalls+0x2d0>
    80005588:	8552                	mv	a0,s4
    8000558a:	fffff097          	auipc	ra,0xfffff
    8000558e:	caa080e7          	jalr	-854(ra) # 80004234 <dirlink>
    80005592:	02054863          	bltz	a0,800055c2 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005596:	004a2603          	lw	a2,4(s4)
    8000559a:	fb040593          	addi	a1,s0,-80
    8000559e:	8526                	mv	a0,s1
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	c94080e7          	jalr	-876(ra) # 80004234 <dirlink>
    800055a8:	00054d63          	bltz	a0,800055c2 <create+0x15a>
    dp->nlink++;  // for ".."
    800055ac:	04a4d783          	lhu	a5,74(s1)
    800055b0:	2785                	addiw	a5,a5,1
    800055b2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055b6:	8526                	mv	a0,s1
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	4bc080e7          	jalr	1212(ra) # 80003a74 <iupdate>
    800055c0:	b761                	j	80005548 <create+0xe0>
  ip->nlink = 0;
    800055c2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800055c6:	8552                	mv	a0,s4
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	4ac080e7          	jalr	1196(ra) # 80003a74 <iupdate>
  iunlockput(ip);
    800055d0:	8552                	mv	a0,s4
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	7d0080e7          	jalr	2000(ra) # 80003da2 <iunlockput>
  iunlockput(dp);
    800055da:	8526                	mv	a0,s1
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	7c6080e7          	jalr	1990(ra) # 80003da2 <iunlockput>
  return 0;
    800055e4:	bddd                	j	800054da <create+0x72>
    return 0;
    800055e6:	8aaa                	mv	s5,a0
    800055e8:	bdcd                	j	800054da <create+0x72>

00000000800055ea <sys_dup>:
{
    800055ea:	7179                	addi	sp,sp,-48
    800055ec:	f406                	sd	ra,40(sp)
    800055ee:	f022                	sd	s0,32(sp)
    800055f0:	ec26                	sd	s1,24(sp)
    800055f2:	e84a                	sd	s2,16(sp)
    800055f4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055f6:	fd840613          	addi	a2,s0,-40
    800055fa:	4581                	li	a1,0
    800055fc:	4501                	li	a0,0
    800055fe:	00000097          	auipc	ra,0x0
    80005602:	dc8080e7          	jalr	-568(ra) # 800053c6 <argfd>
    return -1;
    80005606:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005608:	02054363          	bltz	a0,8000562e <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000560c:	fd843903          	ld	s2,-40(s0)
    80005610:	854a                	mv	a0,s2
    80005612:	00000097          	auipc	ra,0x0
    80005616:	e14080e7          	jalr	-492(ra) # 80005426 <fdalloc>
    8000561a:	84aa                	mv	s1,a0
    return -1;
    8000561c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000561e:	00054863          	bltz	a0,8000562e <sys_dup+0x44>
  filedup(f);
    80005622:	854a                	mv	a0,s2
    80005624:	fffff097          	auipc	ra,0xfffff
    80005628:	334080e7          	jalr	820(ra) # 80004958 <filedup>
  return fd;
    8000562c:	87a6                	mv	a5,s1
}
    8000562e:	853e                	mv	a0,a5
    80005630:	70a2                	ld	ra,40(sp)
    80005632:	7402                	ld	s0,32(sp)
    80005634:	64e2                	ld	s1,24(sp)
    80005636:	6942                	ld	s2,16(sp)
    80005638:	6145                	addi	sp,sp,48
    8000563a:	8082                	ret

000000008000563c <sys_read>:
{
    8000563c:	7179                	addi	sp,sp,-48
    8000563e:	f406                	sd	ra,40(sp)
    80005640:	f022                	sd	s0,32(sp)
    80005642:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005644:	fd840593          	addi	a1,s0,-40
    80005648:	4505                	li	a0,1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	8b6080e7          	jalr	-1866(ra) # 80002f00 <argaddr>
  argint(2, &n);
    80005652:	fe440593          	addi	a1,s0,-28
    80005656:	4509                	li	a0,2
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	888080e7          	jalr	-1912(ra) # 80002ee0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005660:	fe840613          	addi	a2,s0,-24
    80005664:	4581                	li	a1,0
    80005666:	4501                	li	a0,0
    80005668:	00000097          	auipc	ra,0x0
    8000566c:	d5e080e7          	jalr	-674(ra) # 800053c6 <argfd>
    80005670:	87aa                	mv	a5,a0
    return -1;
    80005672:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005674:	0007cc63          	bltz	a5,8000568c <sys_read+0x50>
  return fileread(f, p, n);
    80005678:	fe442603          	lw	a2,-28(s0)
    8000567c:	fd843583          	ld	a1,-40(s0)
    80005680:	fe843503          	ld	a0,-24(s0)
    80005684:	fffff097          	auipc	ra,0xfffff
    80005688:	460080e7          	jalr	1120(ra) # 80004ae4 <fileread>
}
    8000568c:	70a2                	ld	ra,40(sp)
    8000568e:	7402                	ld	s0,32(sp)
    80005690:	6145                	addi	sp,sp,48
    80005692:	8082                	ret

0000000080005694 <sys_write>:
{
    80005694:	7179                	addi	sp,sp,-48
    80005696:	f406                	sd	ra,40(sp)
    80005698:	f022                	sd	s0,32(sp)
    8000569a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000569c:	fd840593          	addi	a1,s0,-40
    800056a0:	4505                	li	a0,1
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	85e080e7          	jalr	-1954(ra) # 80002f00 <argaddr>
  argint(2, &n);
    800056aa:	fe440593          	addi	a1,s0,-28
    800056ae:	4509                	li	a0,2
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	830080e7          	jalr	-2000(ra) # 80002ee0 <argint>
  if(argfd(0, 0, &f) < 0)
    800056b8:	fe840613          	addi	a2,s0,-24
    800056bc:	4581                	li	a1,0
    800056be:	4501                	li	a0,0
    800056c0:	00000097          	auipc	ra,0x0
    800056c4:	d06080e7          	jalr	-762(ra) # 800053c6 <argfd>
    800056c8:	87aa                	mv	a5,a0
    return -1;
    800056ca:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056cc:	0007cc63          	bltz	a5,800056e4 <sys_write+0x50>
  return filewrite(f, p, n);
    800056d0:	fe442603          	lw	a2,-28(s0)
    800056d4:	fd843583          	ld	a1,-40(s0)
    800056d8:	fe843503          	ld	a0,-24(s0)
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	4ca080e7          	jalr	1226(ra) # 80004ba6 <filewrite>
}
    800056e4:	70a2                	ld	ra,40(sp)
    800056e6:	7402                	ld	s0,32(sp)
    800056e8:	6145                	addi	sp,sp,48
    800056ea:	8082                	ret

00000000800056ec <sys_close>:
{
    800056ec:	1101                	addi	sp,sp,-32
    800056ee:	ec06                	sd	ra,24(sp)
    800056f0:	e822                	sd	s0,16(sp)
    800056f2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800056f4:	fe040613          	addi	a2,s0,-32
    800056f8:	fec40593          	addi	a1,s0,-20
    800056fc:	4501                	li	a0,0
    800056fe:	00000097          	auipc	ra,0x0
    80005702:	cc8080e7          	jalr	-824(ra) # 800053c6 <argfd>
    return -1;
    80005706:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005708:	02054463          	bltz	a0,80005730 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000570c:	ffffc097          	auipc	ra,0xffffc
    80005710:	456080e7          	jalr	1110(ra) # 80001b62 <myproc>
    80005714:	fec42783          	lw	a5,-20(s0)
    80005718:	07e9                	addi	a5,a5,26
    8000571a:	078e                	slli	a5,a5,0x3
    8000571c:	953e                	add	a0,a0,a5
    8000571e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005722:	fe043503          	ld	a0,-32(s0)
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	284080e7          	jalr	644(ra) # 800049aa <fileclose>
  return 0;
    8000572e:	4781                	li	a5,0
}
    80005730:	853e                	mv	a0,a5
    80005732:	60e2                	ld	ra,24(sp)
    80005734:	6442                	ld	s0,16(sp)
    80005736:	6105                	addi	sp,sp,32
    80005738:	8082                	ret

000000008000573a <sys_fstat>:
{
    8000573a:	1101                	addi	sp,sp,-32
    8000573c:	ec06                	sd	ra,24(sp)
    8000573e:	e822                	sd	s0,16(sp)
    80005740:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005742:	fe040593          	addi	a1,s0,-32
    80005746:	4505                	li	a0,1
    80005748:	ffffd097          	auipc	ra,0xffffd
    8000574c:	7b8080e7          	jalr	1976(ra) # 80002f00 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005750:	fe840613          	addi	a2,s0,-24
    80005754:	4581                	li	a1,0
    80005756:	4501                	li	a0,0
    80005758:	00000097          	auipc	ra,0x0
    8000575c:	c6e080e7          	jalr	-914(ra) # 800053c6 <argfd>
    80005760:	87aa                	mv	a5,a0
    return -1;
    80005762:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005764:	0007ca63          	bltz	a5,80005778 <sys_fstat+0x3e>
  return filestat(f, st);
    80005768:	fe043583          	ld	a1,-32(s0)
    8000576c:	fe843503          	ld	a0,-24(s0)
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	302080e7          	jalr	770(ra) # 80004a72 <filestat>
}
    80005778:	60e2                	ld	ra,24(sp)
    8000577a:	6442                	ld	s0,16(sp)
    8000577c:	6105                	addi	sp,sp,32
    8000577e:	8082                	ret

0000000080005780 <sys_link>:
{
    80005780:	7169                	addi	sp,sp,-304
    80005782:	f606                	sd	ra,296(sp)
    80005784:	f222                	sd	s0,288(sp)
    80005786:	ee26                	sd	s1,280(sp)
    80005788:	ea4a                	sd	s2,272(sp)
    8000578a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000578c:	08000613          	li	a2,128
    80005790:	ed040593          	addi	a1,s0,-304
    80005794:	4501                	li	a0,0
    80005796:	ffffd097          	auipc	ra,0xffffd
    8000579a:	78a080e7          	jalr	1930(ra) # 80002f20 <argstr>
    return -1;
    8000579e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057a0:	10054e63          	bltz	a0,800058bc <sys_link+0x13c>
    800057a4:	08000613          	li	a2,128
    800057a8:	f5040593          	addi	a1,s0,-176
    800057ac:	4505                	li	a0,1
    800057ae:	ffffd097          	auipc	ra,0xffffd
    800057b2:	772080e7          	jalr	1906(ra) # 80002f20 <argstr>
    return -1;
    800057b6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057b8:	10054263          	bltz	a0,800058bc <sys_link+0x13c>
  begin_op();
    800057bc:	fffff097          	auipc	ra,0xfffff
    800057c0:	d2a080e7          	jalr	-726(ra) # 800044e6 <begin_op>
  if((ip = namei(old)) == 0){
    800057c4:	ed040513          	addi	a0,s0,-304
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	b1e080e7          	jalr	-1250(ra) # 800042e6 <namei>
    800057d0:	84aa                	mv	s1,a0
    800057d2:	c551                	beqz	a0,8000585e <sys_link+0xde>
  ilock(ip);
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	36c080e7          	jalr	876(ra) # 80003b40 <ilock>
  if(ip->type == T_DIR){
    800057dc:	04449703          	lh	a4,68(s1)
    800057e0:	4785                	li	a5,1
    800057e2:	08f70463          	beq	a4,a5,8000586a <sys_link+0xea>
  ip->nlink++;
    800057e6:	04a4d783          	lhu	a5,74(s1)
    800057ea:	2785                	addiw	a5,a5,1
    800057ec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057f0:	8526                	mv	a0,s1
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	282080e7          	jalr	642(ra) # 80003a74 <iupdate>
  iunlock(ip);
    800057fa:	8526                	mv	a0,s1
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	406080e7          	jalr	1030(ra) # 80003c02 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005804:	fd040593          	addi	a1,s0,-48
    80005808:	f5040513          	addi	a0,s0,-176
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	af8080e7          	jalr	-1288(ra) # 80004304 <nameiparent>
    80005814:	892a                	mv	s2,a0
    80005816:	c935                	beqz	a0,8000588a <sys_link+0x10a>
  ilock(dp);
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	328080e7          	jalr	808(ra) # 80003b40 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005820:	00092703          	lw	a4,0(s2)
    80005824:	409c                	lw	a5,0(s1)
    80005826:	04f71d63          	bne	a4,a5,80005880 <sys_link+0x100>
    8000582a:	40d0                	lw	a2,4(s1)
    8000582c:	fd040593          	addi	a1,s0,-48
    80005830:	854a                	mv	a0,s2
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	a02080e7          	jalr	-1534(ra) # 80004234 <dirlink>
    8000583a:	04054363          	bltz	a0,80005880 <sys_link+0x100>
  iunlockput(dp);
    8000583e:	854a                	mv	a0,s2
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	562080e7          	jalr	1378(ra) # 80003da2 <iunlockput>
  iput(ip);
    80005848:	8526                	mv	a0,s1
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	4b0080e7          	jalr	1200(ra) # 80003cfa <iput>
  end_op();
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	d0e080e7          	jalr	-754(ra) # 80004560 <end_op>
  return 0;
    8000585a:	4781                	li	a5,0
    8000585c:	a085                	j	800058bc <sys_link+0x13c>
    end_op();
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	d02080e7          	jalr	-766(ra) # 80004560 <end_op>
    return -1;
    80005866:	57fd                	li	a5,-1
    80005868:	a891                	j	800058bc <sys_link+0x13c>
    iunlockput(ip);
    8000586a:	8526                	mv	a0,s1
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	536080e7          	jalr	1334(ra) # 80003da2 <iunlockput>
    end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	cec080e7          	jalr	-788(ra) # 80004560 <end_op>
    return -1;
    8000587c:	57fd                	li	a5,-1
    8000587e:	a83d                	j	800058bc <sys_link+0x13c>
    iunlockput(dp);
    80005880:	854a                	mv	a0,s2
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	520080e7          	jalr	1312(ra) # 80003da2 <iunlockput>
  ilock(ip);
    8000588a:	8526                	mv	a0,s1
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	2b4080e7          	jalr	692(ra) # 80003b40 <ilock>
  ip->nlink--;
    80005894:	04a4d783          	lhu	a5,74(s1)
    80005898:	37fd                	addiw	a5,a5,-1
    8000589a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000589e:	8526                	mv	a0,s1
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	1d4080e7          	jalr	468(ra) # 80003a74 <iupdate>
  iunlockput(ip);
    800058a8:	8526                	mv	a0,s1
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	4f8080e7          	jalr	1272(ra) # 80003da2 <iunlockput>
  end_op();
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	cae080e7          	jalr	-850(ra) # 80004560 <end_op>
  return -1;
    800058ba:	57fd                	li	a5,-1
}
    800058bc:	853e                	mv	a0,a5
    800058be:	70b2                	ld	ra,296(sp)
    800058c0:	7412                	ld	s0,288(sp)
    800058c2:	64f2                	ld	s1,280(sp)
    800058c4:	6952                	ld	s2,272(sp)
    800058c6:	6155                	addi	sp,sp,304
    800058c8:	8082                	ret

00000000800058ca <sys_unlink>:
{
    800058ca:	7151                	addi	sp,sp,-240
    800058cc:	f586                	sd	ra,232(sp)
    800058ce:	f1a2                	sd	s0,224(sp)
    800058d0:	eda6                	sd	s1,216(sp)
    800058d2:	e9ca                	sd	s2,208(sp)
    800058d4:	e5ce                	sd	s3,200(sp)
    800058d6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058d8:	08000613          	li	a2,128
    800058dc:	f3040593          	addi	a1,s0,-208
    800058e0:	4501                	li	a0,0
    800058e2:	ffffd097          	auipc	ra,0xffffd
    800058e6:	63e080e7          	jalr	1598(ra) # 80002f20 <argstr>
    800058ea:	18054163          	bltz	a0,80005a6c <sys_unlink+0x1a2>
  begin_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	bf8080e7          	jalr	-1032(ra) # 800044e6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058f6:	fb040593          	addi	a1,s0,-80
    800058fa:	f3040513          	addi	a0,s0,-208
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	a06080e7          	jalr	-1530(ra) # 80004304 <nameiparent>
    80005906:	84aa                	mv	s1,a0
    80005908:	c979                	beqz	a0,800059de <sys_unlink+0x114>
  ilock(dp);
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	236080e7          	jalr	566(ra) # 80003b40 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005912:	00003597          	auipc	a1,0x3
    80005916:	f1658593          	addi	a1,a1,-234 # 80008828 <syscalls+0x2c8>
    8000591a:	fb040513          	addi	a0,s0,-80
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	6ec080e7          	jalr	1772(ra) # 8000400a <namecmp>
    80005926:	14050a63          	beqz	a0,80005a7a <sys_unlink+0x1b0>
    8000592a:	00003597          	auipc	a1,0x3
    8000592e:	f0658593          	addi	a1,a1,-250 # 80008830 <syscalls+0x2d0>
    80005932:	fb040513          	addi	a0,s0,-80
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	6d4080e7          	jalr	1748(ra) # 8000400a <namecmp>
    8000593e:	12050e63          	beqz	a0,80005a7a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005942:	f2c40613          	addi	a2,s0,-212
    80005946:	fb040593          	addi	a1,s0,-80
    8000594a:	8526                	mv	a0,s1
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	6d8080e7          	jalr	1752(ra) # 80004024 <dirlookup>
    80005954:	892a                	mv	s2,a0
    80005956:	12050263          	beqz	a0,80005a7a <sys_unlink+0x1b0>
  ilock(ip);
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	1e6080e7          	jalr	486(ra) # 80003b40 <ilock>
  if(ip->nlink < 1)
    80005962:	04a91783          	lh	a5,74(s2)
    80005966:	08f05263          	blez	a5,800059ea <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000596a:	04491703          	lh	a4,68(s2)
    8000596e:	4785                	li	a5,1
    80005970:	08f70563          	beq	a4,a5,800059fa <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005974:	4641                	li	a2,16
    80005976:	4581                	li	a1,0
    80005978:	fc040513          	addi	a0,s0,-64
    8000597c:	ffffb097          	auipc	ra,0xffffb
    80005980:	41a080e7          	jalr	1050(ra) # 80000d96 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005984:	4741                	li	a4,16
    80005986:	f2c42683          	lw	a3,-212(s0)
    8000598a:	fc040613          	addi	a2,s0,-64
    8000598e:	4581                	li	a1,0
    80005990:	8526                	mv	a0,s1
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	55a080e7          	jalr	1370(ra) # 80003eec <writei>
    8000599a:	47c1                	li	a5,16
    8000599c:	0af51563          	bne	a0,a5,80005a46 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059a0:	04491703          	lh	a4,68(s2)
    800059a4:	4785                	li	a5,1
    800059a6:	0af70863          	beq	a4,a5,80005a56 <sys_unlink+0x18c>
  iunlockput(dp);
    800059aa:	8526                	mv	a0,s1
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	3f6080e7          	jalr	1014(ra) # 80003da2 <iunlockput>
  ip->nlink--;
    800059b4:	04a95783          	lhu	a5,74(s2)
    800059b8:	37fd                	addiw	a5,a5,-1
    800059ba:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059be:	854a                	mv	a0,s2
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	0b4080e7          	jalr	180(ra) # 80003a74 <iupdate>
  iunlockput(ip);
    800059c8:	854a                	mv	a0,s2
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	3d8080e7          	jalr	984(ra) # 80003da2 <iunlockput>
  end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	b8e080e7          	jalr	-1138(ra) # 80004560 <end_op>
  return 0;
    800059da:	4501                	li	a0,0
    800059dc:	a84d                	j	80005a8e <sys_unlink+0x1c4>
    end_op();
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	b82080e7          	jalr	-1150(ra) # 80004560 <end_op>
    return -1;
    800059e6:	557d                	li	a0,-1
    800059e8:	a05d                	j	80005a8e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059ea:	00003517          	auipc	a0,0x3
    800059ee:	e4e50513          	addi	a0,a0,-434 # 80008838 <syscalls+0x2d8>
    800059f2:	ffffb097          	auipc	ra,0xffffb
    800059f6:	b4a080e7          	jalr	-1206(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059fa:	04c92703          	lw	a4,76(s2)
    800059fe:	02000793          	li	a5,32
    80005a02:	f6e7f9e3          	bgeu	a5,a4,80005974 <sys_unlink+0xaa>
    80005a06:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a0a:	4741                	li	a4,16
    80005a0c:	86ce                	mv	a3,s3
    80005a0e:	f1840613          	addi	a2,s0,-232
    80005a12:	4581                	li	a1,0
    80005a14:	854a                	mv	a0,s2
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	3de080e7          	jalr	990(ra) # 80003df4 <readi>
    80005a1e:	47c1                	li	a5,16
    80005a20:	00f51b63          	bne	a0,a5,80005a36 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a24:	f1845783          	lhu	a5,-232(s0)
    80005a28:	e7a1                	bnez	a5,80005a70 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a2a:	29c1                	addiw	s3,s3,16
    80005a2c:	04c92783          	lw	a5,76(s2)
    80005a30:	fcf9ede3          	bltu	s3,a5,80005a0a <sys_unlink+0x140>
    80005a34:	b781                	j	80005974 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a36:	00003517          	auipc	a0,0x3
    80005a3a:	e1a50513          	addi	a0,a0,-486 # 80008850 <syscalls+0x2f0>
    80005a3e:	ffffb097          	auipc	ra,0xffffb
    80005a42:	afe080e7          	jalr	-1282(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005a46:	00003517          	auipc	a0,0x3
    80005a4a:	e2250513          	addi	a0,a0,-478 # 80008868 <syscalls+0x308>
    80005a4e:	ffffb097          	auipc	ra,0xffffb
    80005a52:	aee080e7          	jalr	-1298(ra) # 8000053c <panic>
    dp->nlink--;
    80005a56:	04a4d783          	lhu	a5,74(s1)
    80005a5a:	37fd                	addiw	a5,a5,-1
    80005a5c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a60:	8526                	mv	a0,s1
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	012080e7          	jalr	18(ra) # 80003a74 <iupdate>
    80005a6a:	b781                	j	800059aa <sys_unlink+0xe0>
    return -1;
    80005a6c:	557d                	li	a0,-1
    80005a6e:	a005                	j	80005a8e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a70:	854a                	mv	a0,s2
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	330080e7          	jalr	816(ra) # 80003da2 <iunlockput>
  iunlockput(dp);
    80005a7a:	8526                	mv	a0,s1
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	326080e7          	jalr	806(ra) # 80003da2 <iunlockput>
  end_op();
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	adc080e7          	jalr	-1316(ra) # 80004560 <end_op>
  return -1;
    80005a8c:	557d                	li	a0,-1
}
    80005a8e:	70ae                	ld	ra,232(sp)
    80005a90:	740e                	ld	s0,224(sp)
    80005a92:	64ee                	ld	s1,216(sp)
    80005a94:	694e                	ld	s2,208(sp)
    80005a96:	69ae                	ld	s3,200(sp)
    80005a98:	616d                	addi	sp,sp,240
    80005a9a:	8082                	ret

0000000080005a9c <sys_open>:

uint64
sys_open(void)
{
    80005a9c:	7131                	addi	sp,sp,-192
    80005a9e:	fd06                	sd	ra,184(sp)
    80005aa0:	f922                	sd	s0,176(sp)
    80005aa2:	f526                	sd	s1,168(sp)
    80005aa4:	f14a                	sd	s2,160(sp)
    80005aa6:	ed4e                	sd	s3,152(sp)
    80005aa8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005aaa:	f4c40593          	addi	a1,s0,-180
    80005aae:	4505                	li	a0,1
    80005ab0:	ffffd097          	auipc	ra,0xffffd
    80005ab4:	430080e7          	jalr	1072(ra) # 80002ee0 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ab8:	08000613          	li	a2,128
    80005abc:	f5040593          	addi	a1,s0,-176
    80005ac0:	4501                	li	a0,0
    80005ac2:	ffffd097          	auipc	ra,0xffffd
    80005ac6:	45e080e7          	jalr	1118(ra) # 80002f20 <argstr>
    80005aca:	87aa                	mv	a5,a0
    return -1;
    80005acc:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ace:	0a07c863          	bltz	a5,80005b7e <sys_open+0xe2>

  begin_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	a14080e7          	jalr	-1516(ra) # 800044e6 <begin_op>

  if(omode & O_CREATE){
    80005ada:	f4c42783          	lw	a5,-180(s0)
    80005ade:	2007f793          	andi	a5,a5,512
    80005ae2:	cbdd                	beqz	a5,80005b98 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005ae4:	4681                	li	a3,0
    80005ae6:	4601                	li	a2,0
    80005ae8:	4589                	li	a1,2
    80005aea:	f5040513          	addi	a0,s0,-176
    80005aee:	00000097          	auipc	ra,0x0
    80005af2:	97a080e7          	jalr	-1670(ra) # 80005468 <create>
    80005af6:	84aa                	mv	s1,a0
    if(ip == 0){
    80005af8:	c951                	beqz	a0,80005b8c <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005afa:	04449703          	lh	a4,68(s1)
    80005afe:	478d                	li	a5,3
    80005b00:	00f71763          	bne	a4,a5,80005b0e <sys_open+0x72>
    80005b04:	0464d703          	lhu	a4,70(s1)
    80005b08:	47a5                	li	a5,9
    80005b0a:	0ce7ec63          	bltu	a5,a4,80005be2 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b0e:	fffff097          	auipc	ra,0xfffff
    80005b12:	de0080e7          	jalr	-544(ra) # 800048ee <filealloc>
    80005b16:	892a                	mv	s2,a0
    80005b18:	c56d                	beqz	a0,80005c02 <sys_open+0x166>
    80005b1a:	00000097          	auipc	ra,0x0
    80005b1e:	90c080e7          	jalr	-1780(ra) # 80005426 <fdalloc>
    80005b22:	89aa                	mv	s3,a0
    80005b24:	0c054a63          	bltz	a0,80005bf8 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b28:	04449703          	lh	a4,68(s1)
    80005b2c:	478d                	li	a5,3
    80005b2e:	0ef70563          	beq	a4,a5,80005c18 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b32:	4789                	li	a5,2
    80005b34:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005b38:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005b3c:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005b40:	f4c42783          	lw	a5,-180(s0)
    80005b44:	0017c713          	xori	a4,a5,1
    80005b48:	8b05                	andi	a4,a4,1
    80005b4a:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b4e:	0037f713          	andi	a4,a5,3
    80005b52:	00e03733          	snez	a4,a4
    80005b56:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b5a:	4007f793          	andi	a5,a5,1024
    80005b5e:	c791                	beqz	a5,80005b6a <sys_open+0xce>
    80005b60:	04449703          	lh	a4,68(s1)
    80005b64:	4789                	li	a5,2
    80005b66:	0cf70063          	beq	a4,a5,80005c26 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005b6a:	8526                	mv	a0,s1
    80005b6c:	ffffe097          	auipc	ra,0xffffe
    80005b70:	096080e7          	jalr	150(ra) # 80003c02 <iunlock>
  end_op();
    80005b74:	fffff097          	auipc	ra,0xfffff
    80005b78:	9ec080e7          	jalr	-1556(ra) # 80004560 <end_op>

  return fd;
    80005b7c:	854e                	mv	a0,s3
}
    80005b7e:	70ea                	ld	ra,184(sp)
    80005b80:	744a                	ld	s0,176(sp)
    80005b82:	74aa                	ld	s1,168(sp)
    80005b84:	790a                	ld	s2,160(sp)
    80005b86:	69ea                	ld	s3,152(sp)
    80005b88:	6129                	addi	sp,sp,192
    80005b8a:	8082                	ret
      end_op();
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	9d4080e7          	jalr	-1580(ra) # 80004560 <end_op>
      return -1;
    80005b94:	557d                	li	a0,-1
    80005b96:	b7e5                	j	80005b7e <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005b98:	f5040513          	addi	a0,s0,-176
    80005b9c:	ffffe097          	auipc	ra,0xffffe
    80005ba0:	74a080e7          	jalr	1866(ra) # 800042e6 <namei>
    80005ba4:	84aa                	mv	s1,a0
    80005ba6:	c905                	beqz	a0,80005bd6 <sys_open+0x13a>
    ilock(ip);
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	f98080e7          	jalr	-104(ra) # 80003b40 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bb0:	04449703          	lh	a4,68(s1)
    80005bb4:	4785                	li	a5,1
    80005bb6:	f4f712e3          	bne	a4,a5,80005afa <sys_open+0x5e>
    80005bba:	f4c42783          	lw	a5,-180(s0)
    80005bbe:	dba1                	beqz	a5,80005b0e <sys_open+0x72>
      iunlockput(ip);
    80005bc0:	8526                	mv	a0,s1
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	1e0080e7          	jalr	480(ra) # 80003da2 <iunlockput>
      end_op();
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	996080e7          	jalr	-1642(ra) # 80004560 <end_op>
      return -1;
    80005bd2:	557d                	li	a0,-1
    80005bd4:	b76d                	j	80005b7e <sys_open+0xe2>
      end_op();
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	98a080e7          	jalr	-1654(ra) # 80004560 <end_op>
      return -1;
    80005bde:	557d                	li	a0,-1
    80005be0:	bf79                	j	80005b7e <sys_open+0xe2>
    iunlockput(ip);
    80005be2:	8526                	mv	a0,s1
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	1be080e7          	jalr	446(ra) # 80003da2 <iunlockput>
    end_op();
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	974080e7          	jalr	-1676(ra) # 80004560 <end_op>
    return -1;
    80005bf4:	557d                	li	a0,-1
    80005bf6:	b761                	j	80005b7e <sys_open+0xe2>
      fileclose(f);
    80005bf8:	854a                	mv	a0,s2
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	db0080e7          	jalr	-592(ra) # 800049aa <fileclose>
    iunlockput(ip);
    80005c02:	8526                	mv	a0,s1
    80005c04:	ffffe097          	auipc	ra,0xffffe
    80005c08:	19e080e7          	jalr	414(ra) # 80003da2 <iunlockput>
    end_op();
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	954080e7          	jalr	-1708(ra) # 80004560 <end_op>
    return -1;
    80005c14:	557d                	li	a0,-1
    80005c16:	b7a5                	j	80005b7e <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005c18:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005c1c:	04649783          	lh	a5,70(s1)
    80005c20:	02f91223          	sh	a5,36(s2)
    80005c24:	bf21                	j	80005b3c <sys_open+0xa0>
    itrunc(ip);
    80005c26:	8526                	mv	a0,s1
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	026080e7          	jalr	38(ra) # 80003c4e <itrunc>
    80005c30:	bf2d                	j	80005b6a <sys_open+0xce>

0000000080005c32 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c32:	7175                	addi	sp,sp,-144
    80005c34:	e506                	sd	ra,136(sp)
    80005c36:	e122                	sd	s0,128(sp)
    80005c38:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	8ac080e7          	jalr	-1876(ra) # 800044e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c42:	08000613          	li	a2,128
    80005c46:	f7040593          	addi	a1,s0,-144
    80005c4a:	4501                	li	a0,0
    80005c4c:	ffffd097          	auipc	ra,0xffffd
    80005c50:	2d4080e7          	jalr	724(ra) # 80002f20 <argstr>
    80005c54:	02054963          	bltz	a0,80005c86 <sys_mkdir+0x54>
    80005c58:	4681                	li	a3,0
    80005c5a:	4601                	li	a2,0
    80005c5c:	4585                	li	a1,1
    80005c5e:	f7040513          	addi	a0,s0,-144
    80005c62:	00000097          	auipc	ra,0x0
    80005c66:	806080e7          	jalr	-2042(ra) # 80005468 <create>
    80005c6a:	cd11                	beqz	a0,80005c86 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	136080e7          	jalr	310(ra) # 80003da2 <iunlockput>
  end_op();
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	8ec080e7          	jalr	-1812(ra) # 80004560 <end_op>
  return 0;
    80005c7c:	4501                	li	a0,0
}
    80005c7e:	60aa                	ld	ra,136(sp)
    80005c80:	640a                	ld	s0,128(sp)
    80005c82:	6149                	addi	sp,sp,144
    80005c84:	8082                	ret
    end_op();
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	8da080e7          	jalr	-1830(ra) # 80004560 <end_op>
    return -1;
    80005c8e:	557d                	li	a0,-1
    80005c90:	b7fd                	j	80005c7e <sys_mkdir+0x4c>

0000000080005c92 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c92:	7135                	addi	sp,sp,-160
    80005c94:	ed06                	sd	ra,152(sp)
    80005c96:	e922                	sd	s0,144(sp)
    80005c98:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	84c080e7          	jalr	-1972(ra) # 800044e6 <begin_op>
  argint(1, &major);
    80005ca2:	f6c40593          	addi	a1,s0,-148
    80005ca6:	4505                	li	a0,1
    80005ca8:	ffffd097          	auipc	ra,0xffffd
    80005cac:	238080e7          	jalr	568(ra) # 80002ee0 <argint>
  argint(2, &minor);
    80005cb0:	f6840593          	addi	a1,s0,-152
    80005cb4:	4509                	li	a0,2
    80005cb6:	ffffd097          	auipc	ra,0xffffd
    80005cba:	22a080e7          	jalr	554(ra) # 80002ee0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cbe:	08000613          	li	a2,128
    80005cc2:	f7040593          	addi	a1,s0,-144
    80005cc6:	4501                	li	a0,0
    80005cc8:	ffffd097          	auipc	ra,0xffffd
    80005ccc:	258080e7          	jalr	600(ra) # 80002f20 <argstr>
    80005cd0:	02054b63          	bltz	a0,80005d06 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005cd4:	f6841683          	lh	a3,-152(s0)
    80005cd8:	f6c41603          	lh	a2,-148(s0)
    80005cdc:	458d                	li	a1,3
    80005cde:	f7040513          	addi	a0,s0,-144
    80005ce2:	fffff097          	auipc	ra,0xfffff
    80005ce6:	786080e7          	jalr	1926(ra) # 80005468 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cea:	cd11                	beqz	a0,80005d06 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cec:	ffffe097          	auipc	ra,0xffffe
    80005cf0:	0b6080e7          	jalr	182(ra) # 80003da2 <iunlockput>
  end_op();
    80005cf4:	fffff097          	auipc	ra,0xfffff
    80005cf8:	86c080e7          	jalr	-1940(ra) # 80004560 <end_op>
  return 0;
    80005cfc:	4501                	li	a0,0
}
    80005cfe:	60ea                	ld	ra,152(sp)
    80005d00:	644a                	ld	s0,144(sp)
    80005d02:	610d                	addi	sp,sp,160
    80005d04:	8082                	ret
    end_op();
    80005d06:	fffff097          	auipc	ra,0xfffff
    80005d0a:	85a080e7          	jalr	-1958(ra) # 80004560 <end_op>
    return -1;
    80005d0e:	557d                	li	a0,-1
    80005d10:	b7fd                	j	80005cfe <sys_mknod+0x6c>

0000000080005d12 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d12:	7135                	addi	sp,sp,-160
    80005d14:	ed06                	sd	ra,152(sp)
    80005d16:	e922                	sd	s0,144(sp)
    80005d18:	e526                	sd	s1,136(sp)
    80005d1a:	e14a                	sd	s2,128(sp)
    80005d1c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d1e:	ffffc097          	auipc	ra,0xffffc
    80005d22:	e44080e7          	jalr	-444(ra) # 80001b62 <myproc>
    80005d26:	892a                	mv	s2,a0
  
  begin_op();
    80005d28:	ffffe097          	auipc	ra,0xffffe
    80005d2c:	7be080e7          	jalr	1982(ra) # 800044e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d30:	08000613          	li	a2,128
    80005d34:	f6040593          	addi	a1,s0,-160
    80005d38:	4501                	li	a0,0
    80005d3a:	ffffd097          	auipc	ra,0xffffd
    80005d3e:	1e6080e7          	jalr	486(ra) # 80002f20 <argstr>
    80005d42:	04054b63          	bltz	a0,80005d98 <sys_chdir+0x86>
    80005d46:	f6040513          	addi	a0,s0,-160
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	59c080e7          	jalr	1436(ra) # 800042e6 <namei>
    80005d52:	84aa                	mv	s1,a0
    80005d54:	c131                	beqz	a0,80005d98 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d56:	ffffe097          	auipc	ra,0xffffe
    80005d5a:	dea080e7          	jalr	-534(ra) # 80003b40 <ilock>
  if(ip->type != T_DIR){
    80005d5e:	04449703          	lh	a4,68(s1)
    80005d62:	4785                	li	a5,1
    80005d64:	04f71063          	bne	a4,a5,80005da4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d68:	8526                	mv	a0,s1
    80005d6a:	ffffe097          	auipc	ra,0xffffe
    80005d6e:	e98080e7          	jalr	-360(ra) # 80003c02 <iunlock>
  iput(p->cwd);
    80005d72:	15093503          	ld	a0,336(s2)
    80005d76:	ffffe097          	auipc	ra,0xffffe
    80005d7a:	f84080e7          	jalr	-124(ra) # 80003cfa <iput>
  end_op();
    80005d7e:	ffffe097          	auipc	ra,0xffffe
    80005d82:	7e2080e7          	jalr	2018(ra) # 80004560 <end_op>
  p->cwd = ip;
    80005d86:	14993823          	sd	s1,336(s2)
  return 0;
    80005d8a:	4501                	li	a0,0
}
    80005d8c:	60ea                	ld	ra,152(sp)
    80005d8e:	644a                	ld	s0,144(sp)
    80005d90:	64aa                	ld	s1,136(sp)
    80005d92:	690a                	ld	s2,128(sp)
    80005d94:	610d                	addi	sp,sp,160
    80005d96:	8082                	ret
    end_op();
    80005d98:	ffffe097          	auipc	ra,0xffffe
    80005d9c:	7c8080e7          	jalr	1992(ra) # 80004560 <end_op>
    return -1;
    80005da0:	557d                	li	a0,-1
    80005da2:	b7ed                	j	80005d8c <sys_chdir+0x7a>
    iunlockput(ip);
    80005da4:	8526                	mv	a0,s1
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	ffc080e7          	jalr	-4(ra) # 80003da2 <iunlockput>
    end_op();
    80005dae:	ffffe097          	auipc	ra,0xffffe
    80005db2:	7b2080e7          	jalr	1970(ra) # 80004560 <end_op>
    return -1;
    80005db6:	557d                	li	a0,-1
    80005db8:	bfd1                	j	80005d8c <sys_chdir+0x7a>

0000000080005dba <sys_exec>:

uint64
sys_exec(void)
{
    80005dba:	7121                	addi	sp,sp,-448
    80005dbc:	ff06                	sd	ra,440(sp)
    80005dbe:	fb22                	sd	s0,432(sp)
    80005dc0:	f726                	sd	s1,424(sp)
    80005dc2:	f34a                	sd	s2,416(sp)
    80005dc4:	ef4e                	sd	s3,408(sp)
    80005dc6:	eb52                	sd	s4,400(sp)
    80005dc8:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005dca:	e4840593          	addi	a1,s0,-440
    80005dce:	4505                	li	a0,1
    80005dd0:	ffffd097          	auipc	ra,0xffffd
    80005dd4:	130080e7          	jalr	304(ra) # 80002f00 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005dd8:	08000613          	li	a2,128
    80005ddc:	f5040593          	addi	a1,s0,-176
    80005de0:	4501                	li	a0,0
    80005de2:	ffffd097          	auipc	ra,0xffffd
    80005de6:	13e080e7          	jalr	318(ra) # 80002f20 <argstr>
    80005dea:	87aa                	mv	a5,a0
    return -1;
    80005dec:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005dee:	0c07c263          	bltz	a5,80005eb2 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005df2:	10000613          	li	a2,256
    80005df6:	4581                	li	a1,0
    80005df8:	e5040513          	addi	a0,s0,-432
    80005dfc:	ffffb097          	auipc	ra,0xffffb
    80005e00:	f9a080e7          	jalr	-102(ra) # 80000d96 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e04:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005e08:	89a6                	mv	s3,s1
    80005e0a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e0c:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e10:	00391513          	slli	a0,s2,0x3
    80005e14:	e4040593          	addi	a1,s0,-448
    80005e18:	e4843783          	ld	a5,-440(s0)
    80005e1c:	953e                	add	a0,a0,a5
    80005e1e:	ffffd097          	auipc	ra,0xffffd
    80005e22:	024080e7          	jalr	36(ra) # 80002e42 <fetchaddr>
    80005e26:	02054a63          	bltz	a0,80005e5a <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005e2a:	e4043783          	ld	a5,-448(s0)
    80005e2e:	c3b9                	beqz	a5,80005e74 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e30:	ffffb097          	auipc	ra,0xffffb
    80005e34:	d2e080e7          	jalr	-722(ra) # 80000b5e <kalloc>
    80005e38:	85aa                	mv	a1,a0
    80005e3a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e3e:	cd11                	beqz	a0,80005e5a <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e40:	6605                	lui	a2,0x1
    80005e42:	e4043503          	ld	a0,-448(s0)
    80005e46:	ffffd097          	auipc	ra,0xffffd
    80005e4a:	04e080e7          	jalr	78(ra) # 80002e94 <fetchstr>
    80005e4e:	00054663          	bltz	a0,80005e5a <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005e52:	0905                	addi	s2,s2,1
    80005e54:	09a1                	addi	s3,s3,8
    80005e56:	fb491de3          	bne	s2,s4,80005e10 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e5a:	f5040913          	addi	s2,s0,-176
    80005e5e:	6088                	ld	a0,0(s1)
    80005e60:	c921                	beqz	a0,80005eb0 <sys_exec+0xf6>
    kfree(argv[i]);
    80005e62:	ffffb097          	auipc	ra,0xffffb
    80005e66:	b94080e7          	jalr	-1132(ra) # 800009f6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e6a:	04a1                	addi	s1,s1,8
    80005e6c:	ff2499e3          	bne	s1,s2,80005e5e <sys_exec+0xa4>
  return -1;
    80005e70:	557d                	li	a0,-1
    80005e72:	a081                	j	80005eb2 <sys_exec+0xf8>
      argv[i] = 0;
    80005e74:	0009079b          	sext.w	a5,s2
    80005e78:	078e                	slli	a5,a5,0x3
    80005e7a:	fd078793          	addi	a5,a5,-48
    80005e7e:	97a2                	add	a5,a5,s0
    80005e80:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005e84:	e5040593          	addi	a1,s0,-432
    80005e88:	f5040513          	addi	a0,s0,-176
    80005e8c:	fffff097          	auipc	ra,0xfffff
    80005e90:	194080e7          	jalr	404(ra) # 80005020 <exec>
    80005e94:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e96:	f5040993          	addi	s3,s0,-176
    80005e9a:	6088                	ld	a0,0(s1)
    80005e9c:	c901                	beqz	a0,80005eac <sys_exec+0xf2>
    kfree(argv[i]);
    80005e9e:	ffffb097          	auipc	ra,0xffffb
    80005ea2:	b58080e7          	jalr	-1192(ra) # 800009f6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ea6:	04a1                	addi	s1,s1,8
    80005ea8:	ff3499e3          	bne	s1,s3,80005e9a <sys_exec+0xe0>
  return ret;
    80005eac:	854a                	mv	a0,s2
    80005eae:	a011                	j	80005eb2 <sys_exec+0xf8>
  return -1;
    80005eb0:	557d                	li	a0,-1
}
    80005eb2:	70fa                	ld	ra,440(sp)
    80005eb4:	745a                	ld	s0,432(sp)
    80005eb6:	74ba                	ld	s1,424(sp)
    80005eb8:	791a                	ld	s2,416(sp)
    80005eba:	69fa                	ld	s3,408(sp)
    80005ebc:	6a5a                	ld	s4,400(sp)
    80005ebe:	6139                	addi	sp,sp,448
    80005ec0:	8082                	ret

0000000080005ec2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ec2:	7139                	addi	sp,sp,-64
    80005ec4:	fc06                	sd	ra,56(sp)
    80005ec6:	f822                	sd	s0,48(sp)
    80005ec8:	f426                	sd	s1,40(sp)
    80005eca:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ecc:	ffffc097          	auipc	ra,0xffffc
    80005ed0:	c96080e7          	jalr	-874(ra) # 80001b62 <myproc>
    80005ed4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005ed6:	fd840593          	addi	a1,s0,-40
    80005eda:	4501                	li	a0,0
    80005edc:	ffffd097          	auipc	ra,0xffffd
    80005ee0:	024080e7          	jalr	36(ra) # 80002f00 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005ee4:	fc840593          	addi	a1,s0,-56
    80005ee8:	fd040513          	addi	a0,s0,-48
    80005eec:	fffff097          	auipc	ra,0xfffff
    80005ef0:	dea080e7          	jalr	-534(ra) # 80004cd6 <pipealloc>
    return -1;
    80005ef4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ef6:	0c054463          	bltz	a0,80005fbe <sys_pipe+0xfc>
  fd0 = -1;
    80005efa:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005efe:	fd043503          	ld	a0,-48(s0)
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	524080e7          	jalr	1316(ra) # 80005426 <fdalloc>
    80005f0a:	fca42223          	sw	a0,-60(s0)
    80005f0e:	08054b63          	bltz	a0,80005fa4 <sys_pipe+0xe2>
    80005f12:	fc843503          	ld	a0,-56(s0)
    80005f16:	fffff097          	auipc	ra,0xfffff
    80005f1a:	510080e7          	jalr	1296(ra) # 80005426 <fdalloc>
    80005f1e:	fca42023          	sw	a0,-64(s0)
    80005f22:	06054863          	bltz	a0,80005f92 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f26:	4691                	li	a3,4
    80005f28:	fc440613          	addi	a2,s0,-60
    80005f2c:	fd843583          	ld	a1,-40(s0)
    80005f30:	68a8                	ld	a0,80(s1)
    80005f32:	ffffb097          	auipc	ra,0xffffb
    80005f36:	7fc080e7          	jalr	2044(ra) # 8000172e <copyout>
    80005f3a:	02054063          	bltz	a0,80005f5a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f3e:	4691                	li	a3,4
    80005f40:	fc040613          	addi	a2,s0,-64
    80005f44:	fd843583          	ld	a1,-40(s0)
    80005f48:	0591                	addi	a1,a1,4
    80005f4a:	68a8                	ld	a0,80(s1)
    80005f4c:	ffffb097          	auipc	ra,0xffffb
    80005f50:	7e2080e7          	jalr	2018(ra) # 8000172e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f54:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f56:	06055463          	bgez	a0,80005fbe <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005f5a:	fc442783          	lw	a5,-60(s0)
    80005f5e:	07e9                	addi	a5,a5,26
    80005f60:	078e                	slli	a5,a5,0x3
    80005f62:	97a6                	add	a5,a5,s1
    80005f64:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f68:	fc042783          	lw	a5,-64(s0)
    80005f6c:	07e9                	addi	a5,a5,26
    80005f6e:	078e                	slli	a5,a5,0x3
    80005f70:	94be                	add	s1,s1,a5
    80005f72:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005f76:	fd043503          	ld	a0,-48(s0)
    80005f7a:	fffff097          	auipc	ra,0xfffff
    80005f7e:	a30080e7          	jalr	-1488(ra) # 800049aa <fileclose>
    fileclose(wf);
    80005f82:	fc843503          	ld	a0,-56(s0)
    80005f86:	fffff097          	auipc	ra,0xfffff
    80005f8a:	a24080e7          	jalr	-1500(ra) # 800049aa <fileclose>
    return -1;
    80005f8e:	57fd                	li	a5,-1
    80005f90:	a03d                	j	80005fbe <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005f92:	fc442783          	lw	a5,-60(s0)
    80005f96:	0007c763          	bltz	a5,80005fa4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005f9a:	07e9                	addi	a5,a5,26
    80005f9c:	078e                	slli	a5,a5,0x3
    80005f9e:	97a6                	add	a5,a5,s1
    80005fa0:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005fa4:	fd043503          	ld	a0,-48(s0)
    80005fa8:	fffff097          	auipc	ra,0xfffff
    80005fac:	a02080e7          	jalr	-1534(ra) # 800049aa <fileclose>
    fileclose(wf);
    80005fb0:	fc843503          	ld	a0,-56(s0)
    80005fb4:	fffff097          	auipc	ra,0xfffff
    80005fb8:	9f6080e7          	jalr	-1546(ra) # 800049aa <fileclose>
    return -1;
    80005fbc:	57fd                	li	a5,-1
}
    80005fbe:	853e                	mv	a0,a5
    80005fc0:	70e2                	ld	ra,56(sp)
    80005fc2:	7442                	ld	s0,48(sp)
    80005fc4:	74a2                	ld	s1,40(sp)
    80005fc6:	6121                	addi	sp,sp,64
    80005fc8:	8082                	ret
    80005fca:	0000                	unimp
    80005fcc:	0000                	unimp
	...

0000000080005fd0 <kernelvec>:
    80005fd0:	7111                	addi	sp,sp,-256
    80005fd2:	e006                	sd	ra,0(sp)
    80005fd4:	e40a                	sd	sp,8(sp)
    80005fd6:	e80e                	sd	gp,16(sp)
    80005fd8:	ec12                	sd	tp,24(sp)
    80005fda:	f016                	sd	t0,32(sp)
    80005fdc:	f41a                	sd	t1,40(sp)
    80005fde:	f81e                	sd	t2,48(sp)
    80005fe0:	fc22                	sd	s0,56(sp)
    80005fe2:	e0a6                	sd	s1,64(sp)
    80005fe4:	e4aa                	sd	a0,72(sp)
    80005fe6:	e8ae                	sd	a1,80(sp)
    80005fe8:	ecb2                	sd	a2,88(sp)
    80005fea:	f0b6                	sd	a3,96(sp)
    80005fec:	f4ba                	sd	a4,104(sp)
    80005fee:	f8be                	sd	a5,112(sp)
    80005ff0:	fcc2                	sd	a6,120(sp)
    80005ff2:	e146                	sd	a7,128(sp)
    80005ff4:	e54a                	sd	s2,136(sp)
    80005ff6:	e94e                	sd	s3,144(sp)
    80005ff8:	ed52                	sd	s4,152(sp)
    80005ffa:	f156                	sd	s5,160(sp)
    80005ffc:	f55a                	sd	s6,168(sp)
    80005ffe:	f95e                	sd	s7,176(sp)
    80006000:	fd62                	sd	s8,184(sp)
    80006002:	e1e6                	sd	s9,192(sp)
    80006004:	e5ea                	sd	s10,200(sp)
    80006006:	e9ee                	sd	s11,208(sp)
    80006008:	edf2                	sd	t3,216(sp)
    8000600a:	f1f6                	sd	t4,224(sp)
    8000600c:	f5fa                	sd	t5,232(sp)
    8000600e:	f9fe                	sd	t6,240(sp)
    80006010:	cfffc0ef          	jal	ra,80002d0e <kerneltrap>
    80006014:	6082                	ld	ra,0(sp)
    80006016:	6122                	ld	sp,8(sp)
    80006018:	61c2                	ld	gp,16(sp)
    8000601a:	7282                	ld	t0,32(sp)
    8000601c:	7322                	ld	t1,40(sp)
    8000601e:	73c2                	ld	t2,48(sp)
    80006020:	7462                	ld	s0,56(sp)
    80006022:	6486                	ld	s1,64(sp)
    80006024:	6526                	ld	a0,72(sp)
    80006026:	65c6                	ld	a1,80(sp)
    80006028:	6666                	ld	a2,88(sp)
    8000602a:	7686                	ld	a3,96(sp)
    8000602c:	7726                	ld	a4,104(sp)
    8000602e:	77c6                	ld	a5,112(sp)
    80006030:	7866                	ld	a6,120(sp)
    80006032:	688a                	ld	a7,128(sp)
    80006034:	692a                	ld	s2,136(sp)
    80006036:	69ca                	ld	s3,144(sp)
    80006038:	6a6a                	ld	s4,152(sp)
    8000603a:	7a8a                	ld	s5,160(sp)
    8000603c:	7b2a                	ld	s6,168(sp)
    8000603e:	7bca                	ld	s7,176(sp)
    80006040:	7c6a                	ld	s8,184(sp)
    80006042:	6c8e                	ld	s9,192(sp)
    80006044:	6d2e                	ld	s10,200(sp)
    80006046:	6dce                	ld	s11,208(sp)
    80006048:	6e6e                	ld	t3,216(sp)
    8000604a:	7e8e                	ld	t4,224(sp)
    8000604c:	7f2e                	ld	t5,232(sp)
    8000604e:	7fce                	ld	t6,240(sp)
    80006050:	6111                	addi	sp,sp,256
    80006052:	10200073          	sret
    80006056:	00000013          	nop
    8000605a:	00000013          	nop
    8000605e:	0001                	nop

0000000080006060 <timervec>:
    80006060:	34051573          	csrrw	a0,mscratch,a0
    80006064:	e10c                	sd	a1,0(a0)
    80006066:	e510                	sd	a2,8(a0)
    80006068:	e914                	sd	a3,16(a0)
    8000606a:	6d0c                	ld	a1,24(a0)
    8000606c:	7110                	ld	a2,32(a0)
    8000606e:	6194                	ld	a3,0(a1)
    80006070:	96b2                	add	a3,a3,a2
    80006072:	e194                	sd	a3,0(a1)
    80006074:	4589                	li	a1,2
    80006076:	14459073          	csrw	sip,a1
    8000607a:	6914                	ld	a3,16(a0)
    8000607c:	6510                	ld	a2,8(a0)
    8000607e:	610c                	ld	a1,0(a0)
    80006080:	34051573          	csrrw	a0,mscratch,a0
    80006084:	30200073          	mret
	...

000000008000608a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000608a:	1141                	addi	sp,sp,-16
    8000608c:	e422                	sd	s0,8(sp)
    8000608e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006090:	0c0007b7          	lui	a5,0xc000
    80006094:	4705                	li	a4,1
    80006096:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006098:	c3d8                	sw	a4,4(a5)
}
    8000609a:	6422                	ld	s0,8(sp)
    8000609c:	0141                	addi	sp,sp,16
    8000609e:	8082                	ret

00000000800060a0 <plicinithart>:

void
plicinithart(void)
{
    800060a0:	1141                	addi	sp,sp,-16
    800060a2:	e406                	sd	ra,8(sp)
    800060a4:	e022                	sd	s0,0(sp)
    800060a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060a8:	ffffc097          	auipc	ra,0xffffc
    800060ac:	a8e080e7          	jalr	-1394(ra) # 80001b36 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060b0:	0085171b          	slliw	a4,a0,0x8
    800060b4:	0c0027b7          	lui	a5,0xc002
    800060b8:	97ba                	add	a5,a5,a4
    800060ba:	40200713          	li	a4,1026
    800060be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060c2:	00d5151b          	slliw	a0,a0,0xd
    800060c6:	0c2017b7          	lui	a5,0xc201
    800060ca:	97aa                	add	a5,a5,a0
    800060cc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800060d0:	60a2                	ld	ra,8(sp)
    800060d2:	6402                	ld	s0,0(sp)
    800060d4:	0141                	addi	sp,sp,16
    800060d6:	8082                	ret

00000000800060d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060d8:	1141                	addi	sp,sp,-16
    800060da:	e406                	sd	ra,8(sp)
    800060dc:	e022                	sd	s0,0(sp)
    800060de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060e0:	ffffc097          	auipc	ra,0xffffc
    800060e4:	a56080e7          	jalr	-1450(ra) # 80001b36 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060e8:	00d5151b          	slliw	a0,a0,0xd
    800060ec:	0c2017b7          	lui	a5,0xc201
    800060f0:	97aa                	add	a5,a5,a0
  return irq;
}
    800060f2:	43c8                	lw	a0,4(a5)
    800060f4:	60a2                	ld	ra,8(sp)
    800060f6:	6402                	ld	s0,0(sp)
    800060f8:	0141                	addi	sp,sp,16
    800060fa:	8082                	ret

00000000800060fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060fc:	1101                	addi	sp,sp,-32
    800060fe:	ec06                	sd	ra,24(sp)
    80006100:	e822                	sd	s0,16(sp)
    80006102:	e426                	sd	s1,8(sp)
    80006104:	1000                	addi	s0,sp,32
    80006106:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006108:	ffffc097          	auipc	ra,0xffffc
    8000610c:	a2e080e7          	jalr	-1490(ra) # 80001b36 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006110:	00d5151b          	slliw	a0,a0,0xd
    80006114:	0c2017b7          	lui	a5,0xc201
    80006118:	97aa                	add	a5,a5,a0
    8000611a:	c3c4                	sw	s1,4(a5)
}
    8000611c:	60e2                	ld	ra,24(sp)
    8000611e:	6442                	ld	s0,16(sp)
    80006120:	64a2                	ld	s1,8(sp)
    80006122:	6105                	addi	sp,sp,32
    80006124:	8082                	ret

0000000080006126 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006126:	1141                	addi	sp,sp,-16
    80006128:	e406                	sd	ra,8(sp)
    8000612a:	e022                	sd	s0,0(sp)
    8000612c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000612e:	479d                	li	a5,7
    80006130:	04a7cc63          	blt	a5,a0,80006188 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006134:	0001c797          	auipc	a5,0x1c
    80006138:	c6c78793          	addi	a5,a5,-916 # 80021da0 <disk>
    8000613c:	97aa                	add	a5,a5,a0
    8000613e:	0187c783          	lbu	a5,24(a5)
    80006142:	ebb9                	bnez	a5,80006198 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006144:	00451693          	slli	a3,a0,0x4
    80006148:	0001c797          	auipc	a5,0x1c
    8000614c:	c5878793          	addi	a5,a5,-936 # 80021da0 <disk>
    80006150:	6398                	ld	a4,0(a5)
    80006152:	9736                	add	a4,a4,a3
    80006154:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006158:	6398                	ld	a4,0(a5)
    8000615a:	9736                	add	a4,a4,a3
    8000615c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006160:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006164:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006168:	97aa                	add	a5,a5,a0
    8000616a:	4705                	li	a4,1
    8000616c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006170:	0001c517          	auipc	a0,0x1c
    80006174:	c4850513          	addi	a0,a0,-952 # 80021db8 <disk+0x18>
    80006178:	ffffc097          	auipc	ra,0xffffc
    8000617c:	1b6080e7          	jalr	438(ra) # 8000232e <wakeup>
}
    80006180:	60a2                	ld	ra,8(sp)
    80006182:	6402                	ld	s0,0(sp)
    80006184:	0141                	addi	sp,sp,16
    80006186:	8082                	ret
    panic("free_desc 1");
    80006188:	00002517          	auipc	a0,0x2
    8000618c:	6f050513          	addi	a0,a0,1776 # 80008878 <syscalls+0x318>
    80006190:	ffffa097          	auipc	ra,0xffffa
    80006194:	3ac080e7          	jalr	940(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006198:	00002517          	auipc	a0,0x2
    8000619c:	6f050513          	addi	a0,a0,1776 # 80008888 <syscalls+0x328>
    800061a0:	ffffa097          	auipc	ra,0xffffa
    800061a4:	39c080e7          	jalr	924(ra) # 8000053c <panic>

00000000800061a8 <virtio_disk_init>:
{
    800061a8:	1101                	addi	sp,sp,-32
    800061aa:	ec06                	sd	ra,24(sp)
    800061ac:	e822                	sd	s0,16(sp)
    800061ae:	e426                	sd	s1,8(sp)
    800061b0:	e04a                	sd	s2,0(sp)
    800061b2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061b4:	00002597          	auipc	a1,0x2
    800061b8:	6e458593          	addi	a1,a1,1764 # 80008898 <syscalls+0x338>
    800061bc:	0001c517          	auipc	a0,0x1c
    800061c0:	d0c50513          	addi	a0,a0,-756 # 80021ec8 <disk+0x128>
    800061c4:	ffffb097          	auipc	ra,0xffffb
    800061c8:	a46080e7          	jalr	-1466(ra) # 80000c0a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061cc:	100017b7          	lui	a5,0x10001
    800061d0:	4398                	lw	a4,0(a5)
    800061d2:	2701                	sext.w	a4,a4
    800061d4:	747277b7          	lui	a5,0x74727
    800061d8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061dc:	14f71b63          	bne	a4,a5,80006332 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800061e0:	100017b7          	lui	a5,0x10001
    800061e4:	43dc                	lw	a5,4(a5)
    800061e6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061e8:	4709                	li	a4,2
    800061ea:	14e79463          	bne	a5,a4,80006332 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061ee:	100017b7          	lui	a5,0x10001
    800061f2:	479c                	lw	a5,8(a5)
    800061f4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800061f6:	12e79e63          	bne	a5,a4,80006332 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061fa:	100017b7          	lui	a5,0x10001
    800061fe:	47d8                	lw	a4,12(a5)
    80006200:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006202:	554d47b7          	lui	a5,0x554d4
    80006206:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000620a:	12f71463          	bne	a4,a5,80006332 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000620e:	100017b7          	lui	a5,0x10001
    80006212:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006216:	4705                	li	a4,1
    80006218:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000621a:	470d                	li	a4,3
    8000621c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000621e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006220:	c7ffe6b7          	lui	a3,0xc7ffe
    80006224:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc87f>
    80006228:	8f75                	and	a4,a4,a3
    8000622a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000622c:	472d                	li	a4,11
    8000622e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006230:	5bbc                	lw	a5,112(a5)
    80006232:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006236:	8ba1                	andi	a5,a5,8
    80006238:	10078563          	beqz	a5,80006342 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000623c:	100017b7          	lui	a5,0x10001
    80006240:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006244:	43fc                	lw	a5,68(a5)
    80006246:	2781                	sext.w	a5,a5
    80006248:	10079563          	bnez	a5,80006352 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000624c:	100017b7          	lui	a5,0x10001
    80006250:	5bdc                	lw	a5,52(a5)
    80006252:	2781                	sext.w	a5,a5
  if(max == 0)
    80006254:	10078763          	beqz	a5,80006362 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006258:	471d                	li	a4,7
    8000625a:	10f77c63          	bgeu	a4,a5,80006372 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000625e:	ffffb097          	auipc	ra,0xffffb
    80006262:	900080e7          	jalr	-1792(ra) # 80000b5e <kalloc>
    80006266:	0001c497          	auipc	s1,0x1c
    8000626a:	b3a48493          	addi	s1,s1,-1222 # 80021da0 <disk>
    8000626e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006270:	ffffb097          	auipc	ra,0xffffb
    80006274:	8ee080e7          	jalr	-1810(ra) # 80000b5e <kalloc>
    80006278:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000627a:	ffffb097          	auipc	ra,0xffffb
    8000627e:	8e4080e7          	jalr	-1820(ra) # 80000b5e <kalloc>
    80006282:	87aa                	mv	a5,a0
    80006284:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006286:	6088                	ld	a0,0(s1)
    80006288:	cd6d                	beqz	a0,80006382 <virtio_disk_init+0x1da>
    8000628a:	0001c717          	auipc	a4,0x1c
    8000628e:	b1e73703          	ld	a4,-1250(a4) # 80021da8 <disk+0x8>
    80006292:	cb65                	beqz	a4,80006382 <virtio_disk_init+0x1da>
    80006294:	c7fd                	beqz	a5,80006382 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006296:	6605                	lui	a2,0x1
    80006298:	4581                	li	a1,0
    8000629a:	ffffb097          	auipc	ra,0xffffb
    8000629e:	afc080e7          	jalr	-1284(ra) # 80000d96 <memset>
  memset(disk.avail, 0, PGSIZE);
    800062a2:	0001c497          	auipc	s1,0x1c
    800062a6:	afe48493          	addi	s1,s1,-1282 # 80021da0 <disk>
    800062aa:	6605                	lui	a2,0x1
    800062ac:	4581                	li	a1,0
    800062ae:	6488                	ld	a0,8(s1)
    800062b0:	ffffb097          	auipc	ra,0xffffb
    800062b4:	ae6080e7          	jalr	-1306(ra) # 80000d96 <memset>
  memset(disk.used, 0, PGSIZE);
    800062b8:	6605                	lui	a2,0x1
    800062ba:	4581                	li	a1,0
    800062bc:	6888                	ld	a0,16(s1)
    800062be:	ffffb097          	auipc	ra,0xffffb
    800062c2:	ad8080e7          	jalr	-1320(ra) # 80000d96 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062c6:	100017b7          	lui	a5,0x10001
    800062ca:	4721                	li	a4,8
    800062cc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800062ce:	4098                	lw	a4,0(s1)
    800062d0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800062d4:	40d8                	lw	a4,4(s1)
    800062d6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800062da:	6498                	ld	a4,8(s1)
    800062dc:	0007069b          	sext.w	a3,a4
    800062e0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800062e4:	9701                	srai	a4,a4,0x20
    800062e6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800062ea:	6898                	ld	a4,16(s1)
    800062ec:	0007069b          	sext.w	a3,a4
    800062f0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800062f4:	9701                	srai	a4,a4,0x20
    800062f6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800062fa:	4705                	li	a4,1
    800062fc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800062fe:	00e48c23          	sb	a4,24(s1)
    80006302:	00e48ca3          	sb	a4,25(s1)
    80006306:	00e48d23          	sb	a4,26(s1)
    8000630a:	00e48da3          	sb	a4,27(s1)
    8000630e:	00e48e23          	sb	a4,28(s1)
    80006312:	00e48ea3          	sb	a4,29(s1)
    80006316:	00e48f23          	sb	a4,30(s1)
    8000631a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000631e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006322:	0727a823          	sw	s2,112(a5)
}
    80006326:	60e2                	ld	ra,24(sp)
    80006328:	6442                	ld	s0,16(sp)
    8000632a:	64a2                	ld	s1,8(sp)
    8000632c:	6902                	ld	s2,0(sp)
    8000632e:	6105                	addi	sp,sp,32
    80006330:	8082                	ret
    panic("could not find virtio disk");
    80006332:	00002517          	auipc	a0,0x2
    80006336:	57650513          	addi	a0,a0,1398 # 800088a8 <syscalls+0x348>
    8000633a:	ffffa097          	auipc	ra,0xffffa
    8000633e:	202080e7          	jalr	514(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006342:	00002517          	auipc	a0,0x2
    80006346:	58650513          	addi	a0,a0,1414 # 800088c8 <syscalls+0x368>
    8000634a:	ffffa097          	auipc	ra,0xffffa
    8000634e:	1f2080e7          	jalr	498(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006352:	00002517          	auipc	a0,0x2
    80006356:	59650513          	addi	a0,a0,1430 # 800088e8 <syscalls+0x388>
    8000635a:	ffffa097          	auipc	ra,0xffffa
    8000635e:	1e2080e7          	jalr	482(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006362:	00002517          	auipc	a0,0x2
    80006366:	5a650513          	addi	a0,a0,1446 # 80008908 <syscalls+0x3a8>
    8000636a:	ffffa097          	auipc	ra,0xffffa
    8000636e:	1d2080e7          	jalr	466(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006372:	00002517          	auipc	a0,0x2
    80006376:	5b650513          	addi	a0,a0,1462 # 80008928 <syscalls+0x3c8>
    8000637a:	ffffa097          	auipc	ra,0xffffa
    8000637e:	1c2080e7          	jalr	450(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006382:	00002517          	auipc	a0,0x2
    80006386:	5c650513          	addi	a0,a0,1478 # 80008948 <syscalls+0x3e8>
    8000638a:	ffffa097          	auipc	ra,0xffffa
    8000638e:	1b2080e7          	jalr	434(ra) # 8000053c <panic>

0000000080006392 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006392:	7159                	addi	sp,sp,-112
    80006394:	f486                	sd	ra,104(sp)
    80006396:	f0a2                	sd	s0,96(sp)
    80006398:	eca6                	sd	s1,88(sp)
    8000639a:	e8ca                	sd	s2,80(sp)
    8000639c:	e4ce                	sd	s3,72(sp)
    8000639e:	e0d2                	sd	s4,64(sp)
    800063a0:	fc56                	sd	s5,56(sp)
    800063a2:	f85a                	sd	s6,48(sp)
    800063a4:	f45e                	sd	s7,40(sp)
    800063a6:	f062                	sd	s8,32(sp)
    800063a8:	ec66                	sd	s9,24(sp)
    800063aa:	e86a                	sd	s10,16(sp)
    800063ac:	1880                	addi	s0,sp,112
    800063ae:	8a2a                	mv	s4,a0
    800063b0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063b2:	00c52c83          	lw	s9,12(a0)
    800063b6:	001c9c9b          	slliw	s9,s9,0x1
    800063ba:	1c82                	slli	s9,s9,0x20
    800063bc:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800063c0:	0001c517          	auipc	a0,0x1c
    800063c4:	b0850513          	addi	a0,a0,-1272 # 80021ec8 <disk+0x128>
    800063c8:	ffffb097          	auipc	ra,0xffffb
    800063cc:	8d2080e7          	jalr	-1838(ra) # 80000c9a <acquire>
  for(int i = 0; i < 3; i++){
    800063d0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800063d2:	44a1                	li	s1,8
      disk.free[i] = 0;
    800063d4:	0001cb17          	auipc	s6,0x1c
    800063d8:	9ccb0b13          	addi	s6,s6,-1588 # 80021da0 <disk>
  for(int i = 0; i < 3; i++){
    800063dc:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063de:	0001cc17          	auipc	s8,0x1c
    800063e2:	aeac0c13          	addi	s8,s8,-1302 # 80021ec8 <disk+0x128>
    800063e6:	a095                	j	8000644a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800063e8:	00fb0733          	add	a4,s6,a5
    800063ec:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800063f0:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    800063f2:	0207c563          	bltz	a5,8000641c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    800063f6:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    800063f8:	0591                	addi	a1,a1,4
    800063fa:	05560d63          	beq	a2,s5,80006454 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800063fe:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006400:	0001c717          	auipc	a4,0x1c
    80006404:	9a070713          	addi	a4,a4,-1632 # 80021da0 <disk>
    80006408:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000640a:	01874683          	lbu	a3,24(a4)
    8000640e:	fee9                	bnez	a3,800063e8 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006410:	2785                	addiw	a5,a5,1
    80006412:	0705                	addi	a4,a4,1
    80006414:	fe979be3          	bne	a5,s1,8000640a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006418:	57fd                	li	a5,-1
    8000641a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000641c:	00c05e63          	blez	a2,80006438 <virtio_disk_rw+0xa6>
    80006420:	060a                	slli	a2,a2,0x2
    80006422:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006426:	0009a503          	lw	a0,0(s3)
    8000642a:	00000097          	auipc	ra,0x0
    8000642e:	cfc080e7          	jalr	-772(ra) # 80006126 <free_desc>
      for(int j = 0; j < i; j++)
    80006432:	0991                	addi	s3,s3,4
    80006434:	ffa999e3          	bne	s3,s10,80006426 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006438:	85e2                	mv	a1,s8
    8000643a:	0001c517          	auipc	a0,0x1c
    8000643e:	97e50513          	addi	a0,a0,-1666 # 80021db8 <disk+0x18>
    80006442:	ffffc097          	auipc	ra,0xffffc
    80006446:	e88080e7          	jalr	-376(ra) # 800022ca <sleep>
  for(int i = 0; i < 3; i++){
    8000644a:	f9040993          	addi	s3,s0,-112
{
    8000644e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006450:	864a                	mv	a2,s2
    80006452:	b775                	j	800063fe <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006454:	f9042503          	lw	a0,-112(s0)
    80006458:	00a50713          	addi	a4,a0,10
    8000645c:	0712                	slli	a4,a4,0x4

  if(write)
    8000645e:	0001c797          	auipc	a5,0x1c
    80006462:	94278793          	addi	a5,a5,-1726 # 80021da0 <disk>
    80006466:	00e786b3          	add	a3,a5,a4
    8000646a:	01703633          	snez	a2,s7
    8000646e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006470:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006474:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006478:	f6070613          	addi	a2,a4,-160
    8000647c:	6394                	ld	a3,0(a5)
    8000647e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006480:	00870593          	addi	a1,a4,8
    80006484:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006486:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006488:	0007b803          	ld	a6,0(a5)
    8000648c:	9642                	add	a2,a2,a6
    8000648e:	46c1                	li	a3,16
    80006490:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006492:	4585                	li	a1,1
    80006494:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006498:	f9442683          	lw	a3,-108(s0)
    8000649c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064a0:	0692                	slli	a3,a3,0x4
    800064a2:	9836                	add	a6,a6,a3
    800064a4:	058a0613          	addi	a2,s4,88
    800064a8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800064ac:	0007b803          	ld	a6,0(a5)
    800064b0:	96c2                	add	a3,a3,a6
    800064b2:	40000613          	li	a2,1024
    800064b6:	c690                	sw	a2,8(a3)
  if(write)
    800064b8:	001bb613          	seqz	a2,s7
    800064bc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064c0:	00166613          	ori	a2,a2,1
    800064c4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800064c8:	f9842603          	lw	a2,-104(s0)
    800064cc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064d0:	00250693          	addi	a3,a0,2
    800064d4:	0692                	slli	a3,a3,0x4
    800064d6:	96be                	add	a3,a3,a5
    800064d8:	58fd                	li	a7,-1
    800064da:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064de:	0612                	slli	a2,a2,0x4
    800064e0:	9832                	add	a6,a6,a2
    800064e2:	f9070713          	addi	a4,a4,-112
    800064e6:	973e                	add	a4,a4,a5
    800064e8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800064ec:	6398                	ld	a4,0(a5)
    800064ee:	9732                	add	a4,a4,a2
    800064f0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800064f2:	4609                	li	a2,2
    800064f4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800064f8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800064fc:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006500:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006504:	6794                	ld	a3,8(a5)
    80006506:	0026d703          	lhu	a4,2(a3)
    8000650a:	8b1d                	andi	a4,a4,7
    8000650c:	0706                	slli	a4,a4,0x1
    8000650e:	96ba                	add	a3,a3,a4
    80006510:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006514:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006518:	6798                	ld	a4,8(a5)
    8000651a:	00275783          	lhu	a5,2(a4)
    8000651e:	2785                	addiw	a5,a5,1
    80006520:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006524:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006528:	100017b7          	lui	a5,0x10001
    8000652c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006530:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006534:	0001c917          	auipc	s2,0x1c
    80006538:	99490913          	addi	s2,s2,-1644 # 80021ec8 <disk+0x128>
  while(b->disk == 1) {
    8000653c:	4485                	li	s1,1
    8000653e:	00b79c63          	bne	a5,a1,80006556 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006542:	85ca                	mv	a1,s2
    80006544:	8552                	mv	a0,s4
    80006546:	ffffc097          	auipc	ra,0xffffc
    8000654a:	d84080e7          	jalr	-636(ra) # 800022ca <sleep>
  while(b->disk == 1) {
    8000654e:	004a2783          	lw	a5,4(s4)
    80006552:	fe9788e3          	beq	a5,s1,80006542 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006556:	f9042903          	lw	s2,-112(s0)
    8000655a:	00290713          	addi	a4,s2,2
    8000655e:	0712                	slli	a4,a4,0x4
    80006560:	0001c797          	auipc	a5,0x1c
    80006564:	84078793          	addi	a5,a5,-1984 # 80021da0 <disk>
    80006568:	97ba                	add	a5,a5,a4
    8000656a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000656e:	0001c997          	auipc	s3,0x1c
    80006572:	83298993          	addi	s3,s3,-1998 # 80021da0 <disk>
    80006576:	00491713          	slli	a4,s2,0x4
    8000657a:	0009b783          	ld	a5,0(s3)
    8000657e:	97ba                	add	a5,a5,a4
    80006580:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006584:	854a                	mv	a0,s2
    80006586:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000658a:	00000097          	auipc	ra,0x0
    8000658e:	b9c080e7          	jalr	-1124(ra) # 80006126 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006592:	8885                	andi	s1,s1,1
    80006594:	f0ed                	bnez	s1,80006576 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006596:	0001c517          	auipc	a0,0x1c
    8000659a:	93250513          	addi	a0,a0,-1742 # 80021ec8 <disk+0x128>
    8000659e:	ffffa097          	auipc	ra,0xffffa
    800065a2:	7b0080e7          	jalr	1968(ra) # 80000d4e <release>
}
    800065a6:	70a6                	ld	ra,104(sp)
    800065a8:	7406                	ld	s0,96(sp)
    800065aa:	64e6                	ld	s1,88(sp)
    800065ac:	6946                	ld	s2,80(sp)
    800065ae:	69a6                	ld	s3,72(sp)
    800065b0:	6a06                	ld	s4,64(sp)
    800065b2:	7ae2                	ld	s5,56(sp)
    800065b4:	7b42                	ld	s6,48(sp)
    800065b6:	7ba2                	ld	s7,40(sp)
    800065b8:	7c02                	ld	s8,32(sp)
    800065ba:	6ce2                	ld	s9,24(sp)
    800065bc:	6d42                	ld	s10,16(sp)
    800065be:	6165                	addi	sp,sp,112
    800065c0:	8082                	ret

00000000800065c2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065c2:	1101                	addi	sp,sp,-32
    800065c4:	ec06                	sd	ra,24(sp)
    800065c6:	e822                	sd	s0,16(sp)
    800065c8:	e426                	sd	s1,8(sp)
    800065ca:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065cc:	0001b497          	auipc	s1,0x1b
    800065d0:	7d448493          	addi	s1,s1,2004 # 80021da0 <disk>
    800065d4:	0001c517          	auipc	a0,0x1c
    800065d8:	8f450513          	addi	a0,a0,-1804 # 80021ec8 <disk+0x128>
    800065dc:	ffffa097          	auipc	ra,0xffffa
    800065e0:	6be080e7          	jalr	1726(ra) # 80000c9a <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065e4:	10001737          	lui	a4,0x10001
    800065e8:	533c                	lw	a5,96(a4)
    800065ea:	8b8d                	andi	a5,a5,3
    800065ec:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065ee:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065f2:	689c                	ld	a5,16(s1)
    800065f4:	0204d703          	lhu	a4,32(s1)
    800065f8:	0027d783          	lhu	a5,2(a5)
    800065fc:	04f70863          	beq	a4,a5,8000664c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006600:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006604:	6898                	ld	a4,16(s1)
    80006606:	0204d783          	lhu	a5,32(s1)
    8000660a:	8b9d                	andi	a5,a5,7
    8000660c:	078e                	slli	a5,a5,0x3
    8000660e:	97ba                	add	a5,a5,a4
    80006610:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006612:	00278713          	addi	a4,a5,2
    80006616:	0712                	slli	a4,a4,0x4
    80006618:	9726                	add	a4,a4,s1
    8000661a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000661e:	e721                	bnez	a4,80006666 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006620:	0789                	addi	a5,a5,2
    80006622:	0792                	slli	a5,a5,0x4
    80006624:	97a6                	add	a5,a5,s1
    80006626:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006628:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000662c:	ffffc097          	auipc	ra,0xffffc
    80006630:	d02080e7          	jalr	-766(ra) # 8000232e <wakeup>

    disk.used_idx += 1;
    80006634:	0204d783          	lhu	a5,32(s1)
    80006638:	2785                	addiw	a5,a5,1
    8000663a:	17c2                	slli	a5,a5,0x30
    8000663c:	93c1                	srli	a5,a5,0x30
    8000663e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006642:	6898                	ld	a4,16(s1)
    80006644:	00275703          	lhu	a4,2(a4)
    80006648:	faf71ce3          	bne	a4,a5,80006600 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000664c:	0001c517          	auipc	a0,0x1c
    80006650:	87c50513          	addi	a0,a0,-1924 # 80021ec8 <disk+0x128>
    80006654:	ffffa097          	auipc	ra,0xffffa
    80006658:	6fa080e7          	jalr	1786(ra) # 80000d4e <release>
}
    8000665c:	60e2                	ld	ra,24(sp)
    8000665e:	6442                	ld	s0,16(sp)
    80006660:	64a2                	ld	s1,8(sp)
    80006662:	6105                	addi	sp,sp,32
    80006664:	8082                	ret
      panic("virtio_disk_intr status");
    80006666:	00002517          	auipc	a0,0x2
    8000666a:	2fa50513          	addi	a0,a0,762 # 80008960 <syscalls+0x400>
    8000666e:	ffffa097          	auipc	ra,0xffffa
    80006672:	ece080e7          	jalr	-306(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
