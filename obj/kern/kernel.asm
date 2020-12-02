
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 f0 11 00       	mov    $0x11f000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 f0 11 f0       	mov    $0xf011f000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 6a 00 00 00       	call   f01000a8 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	83 ec 10             	sub    $0x10,%esp
f0100048:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010004b:	83 3d 80 0e 23 f0 00 	cmpl   $0x0,0xf0230e80
f0100052:	75 46                	jne    f010009a <_panic+0x5a>
		goto dead;
	panicstr = fmt;
f0100054:	89 35 80 0e 23 f0    	mov    %esi,0xf0230e80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f010005a:	fa                   	cli    
f010005b:	fc                   	cld    

	va_start(ap, fmt);
f010005c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005f:	e8 75 64 00 00       	call   f01064d9 <cpunum>
f0100064:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100067:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010006b:	8b 55 08             	mov    0x8(%ebp),%edx
f010006e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100072:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100076:	c7 04 24 c0 6b 10 f0 	movl   $0xf0106bc0,(%esp)
f010007d:	e8 e1 3e 00 00       	call   f0103f63 <cprintf>
	vcprintf(fmt, ap);
f0100082:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100086:	89 34 24             	mov    %esi,(%esp)
f0100089:	e8 a2 3e 00 00       	call   f0103f30 <vcprintf>
	cprintf("\n");
f010008e:	c7 04 24 bc 7d 10 f0 	movl   $0xf0107dbc,(%esp)
f0100095:	e8 c9 3e 00 00       	call   f0103f63 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000a1:	e8 15 09 00 00       	call   f01009bb <monitor>
f01000a6:	eb f2                	jmp    f010009a <_panic+0x5a>

f01000a8 <i386_init>:
{
f01000a8:	55                   	push   %ebp
f01000a9:	89 e5                	mov    %esp,%ebp
f01000ab:	53                   	push   %ebx
f01000ac:	83 ec 14             	sub    $0x14,%esp
	memset(edata, 0, end - edata);
f01000af:	b8 08 20 27 f0       	mov    $0xf0272008,%eax
f01000b4:	2d 00 00 23 f0       	sub    $0xf0230000,%eax
f01000b9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000c4:	00 
f01000c5:	c7 04 24 00 00 23 f0 	movl   $0xf0230000,(%esp)
f01000cc:	e8 b6 5d 00 00       	call   f0105e87 <memset>
	cons_init();
f01000d1:	e8 b9 05 00 00       	call   f010068f <cons_init>
	cprintf("444544 decimal is %o octal!\n", 444544);
f01000d6:	c7 44 24 04 80 c8 06 	movl   $0x6c880,0x4(%esp)
f01000dd:	00 
f01000de:	c7 04 24 2c 6c 10 f0 	movl   $0xf0106c2c,(%esp)
f01000e5:	e8 79 3e 00 00       	call   f0103f63 <cprintf>
	mem_init();
f01000ea:	e8 54 14 00 00       	call   f0101543 <mem_init>
	env_init();
f01000ef:	e8 42 36 00 00       	call   f0103736 <env_init>
	trap_init();
f01000f4:	e8 45 3f 00 00       	call   f010403e <trap_init>
	mp_init();
f01000f9:	e8 cc 60 00 00       	call   f01061ca <mp_init>
	lapic_init();
f01000fe:	66 90                	xchg   %ax,%ax
f0100100:	e8 ef 63 00 00       	call   f01064f4 <lapic_init>
	pic_init();
f0100105:	e8 89 3d 00 00       	call   f0103e93 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f010010a:	c7 04 24 60 14 12 f0 	movl   $0xf0121460,(%esp)
f0100111:	e8 41 66 00 00       	call   f0106757 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100116:	83 3d 88 0e 23 f0 07 	cmpl   $0x7,0xf0230e88
f010011d:	77 24                	ja     f0100143 <i386_init+0x9b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010011f:	c7 44 24 0c 00 70 00 	movl   $0x7000,0xc(%esp)
f0100126:	00 
f0100127:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f010012e:	f0 
f010012f:	c7 44 24 04 55 00 00 	movl   $0x55,0x4(%esp)
f0100136:	00 
f0100137:	c7 04 24 49 6c 10 f0 	movl   $0xf0106c49,(%esp)
f010013e:	e8 fd fe ff ff       	call   f0100040 <_panic>
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100143:	b8 02 61 10 f0       	mov    $0xf0106102,%eax
f0100148:	2d 88 60 10 f0       	sub    $0xf0106088,%eax
f010014d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100151:	c7 44 24 04 88 60 10 	movl   $0xf0106088,0x4(%esp)
f0100158:	f0 
f0100159:	c7 04 24 00 70 00 f0 	movl   $0xf0007000,(%esp)
f0100160:	e8 6f 5d 00 00       	call   f0105ed4 <memmove>
	for (c = cpus; c < cpus + ncpu; c++) {
f0100165:	bb 20 10 23 f0       	mov    $0xf0231020,%ebx
f010016a:	eb 4d                	jmp    f01001b9 <i386_init+0x111>
		if (c == cpus + cpunum())  // We've started already.
f010016c:	e8 68 63 00 00       	call   f01064d9 <cpunum>
f0100171:	6b c0 74             	imul   $0x74,%eax,%eax
f0100174:	05 20 10 23 f0       	add    $0xf0231020,%eax
f0100179:	39 c3                	cmp    %eax,%ebx
f010017b:	74 39                	je     f01001b6 <i386_init+0x10e>
f010017d:	89 d8                	mov    %ebx,%eax
f010017f:	2d 20 10 23 f0       	sub    $0xf0231020,%eax
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100184:	c1 f8 02             	sar    $0x2,%eax
f0100187:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f010018d:	c1 e0 0f             	shl    $0xf,%eax
f0100190:	8d 80 00 a0 23 f0    	lea    -0xfdc6000(%eax),%eax
f0100196:	a3 84 0e 23 f0       	mov    %eax,0xf0230e84
		lapic_startap(c->cpu_id, PADDR(code));
f010019b:	c7 44 24 04 00 70 00 	movl   $0x7000,0x4(%esp)
f01001a2:	00 
f01001a3:	0f b6 03             	movzbl (%ebx),%eax
f01001a6:	89 04 24             	mov    %eax,(%esp)
f01001a9:	e8 96 64 00 00       	call   f0106644 <lapic_startap>
		while(c->cpu_status != CPU_STARTED)
f01001ae:	8b 43 04             	mov    0x4(%ebx),%eax
f01001b1:	83 f8 01             	cmp    $0x1,%eax
f01001b4:	75 f8                	jne    f01001ae <i386_init+0x106>
	for (c = cpus; c < cpus + ncpu; c++) {
f01001b6:	83 c3 74             	add    $0x74,%ebx
f01001b9:	6b 05 c4 13 23 f0 74 	imul   $0x74,0xf02313c4,%eax
f01001c0:	05 20 10 23 f0       	add    $0xf0231020,%eax
f01001c5:	39 c3                	cmp    %eax,%ebx
f01001c7:	72 a3                	jb     f010016c <i386_init+0xc4>
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01001d0:	00 
f01001d1:	c7 04 24 6c 5f 22 f0 	movl   $0xf0225f6c,(%esp)
f01001d8:	e8 48 37 00 00       	call   f0103925 <env_create>
	sched_yield();
f01001dd:	e8 91 49 00 00       	call   f0104b73 <sched_yield>

f01001e2 <mp_main>:
{
f01001e2:	55                   	push   %ebp
f01001e3:	89 e5                	mov    %esp,%ebp
f01001e5:	83 ec 18             	sub    $0x18,%esp
	lcr3(PADDR(kern_pgdir));
f01001e8:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01001ed:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001f2:	77 20                	ja     f0100214 <mp_main+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01001f8:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f01001ff:	f0 
f0100200:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
f0100207:	00 
f0100208:	c7 04 24 49 6c 10 f0 	movl   $0xf0106c49,(%esp)
f010020f:	e8 2c fe ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100214:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0100219:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f010021c:	e8 b8 62 00 00       	call   f01064d9 <cpunum>
f0100221:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100225:	c7 04 24 55 6c 10 f0 	movl   $0xf0106c55,(%esp)
f010022c:	e8 32 3d 00 00       	call   f0103f63 <cprintf>
	lapic_init();
f0100231:	e8 be 62 00 00       	call   f01064f4 <lapic_init>
	env_init_percpu();
f0100236:	e8 d1 34 00 00       	call   f010370c <env_init_percpu>
	trap_init_percpu();
f010023b:	90                   	nop
f010023c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100240:	e8 3b 3d 00 00       	call   f0103f80 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100245:	e8 8f 62 00 00       	call   f01064d9 <cpunum>
f010024a:	6b d0 74             	imul   $0x74,%eax,%edx
f010024d:	81 c2 20 10 23 f0    	add    $0xf0231020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0100253:	b8 01 00 00 00       	mov    $0x1,%eax
f0100258:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010025c:	c7 04 24 60 14 12 f0 	movl   $0xf0121460,(%esp)
f0100263:	e8 ef 64 00 00       	call   f0106757 <spin_lock>
	sched_yield();
f0100268:	e8 06 49 00 00       	call   f0104b73 <sched_yield>

f010026d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010026d:	55                   	push   %ebp
f010026e:	89 e5                	mov    %esp,%ebp
f0100270:	53                   	push   %ebx
f0100271:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100274:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100277:	8b 45 0c             	mov    0xc(%ebp),%eax
f010027a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010027e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100281:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100285:	c7 04 24 6b 6c 10 f0 	movl   $0xf0106c6b,(%esp)
f010028c:	e8 d2 3c 00 00       	call   f0103f63 <cprintf>
	vcprintf(fmt, ap);
f0100291:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100295:	8b 45 10             	mov    0x10(%ebp),%eax
f0100298:	89 04 24             	mov    %eax,(%esp)
f010029b:	e8 90 3c 00 00       	call   f0103f30 <vcprintf>
	cprintf("\n");
f01002a0:	c7 04 24 bc 7d 10 f0 	movl   $0xf0107dbc,(%esp)
f01002a7:	e8 b7 3c 00 00       	call   f0103f63 <cprintf>
	va_end(ap);
}
f01002ac:	83 c4 14             	add    $0x14,%esp
f01002af:	5b                   	pop    %ebx
f01002b0:	5d                   	pop    %ebp
f01002b1:	c3                   	ret    
f01002b2:	66 90                	xchg   %ax,%ax
f01002b4:	66 90                	xchg   %ax,%ax
f01002b6:	66 90                	xchg   %ax,%ax
f01002b8:	66 90                	xchg   %ax,%ax
f01002ba:	66 90                	xchg   %ax,%ax
f01002bc:	66 90                	xchg   %ax,%ax
f01002be:	66 90                	xchg   %ax,%ax

f01002c0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01002c0:	55                   	push   %ebp
f01002c1:	89 e5                	mov    %esp,%ebp
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002c8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01002c9:	a8 01                	test   $0x1,%al
f01002cb:	74 08                	je     f01002d5 <serial_proc_data+0x15>
f01002cd:	b2 f8                	mov    $0xf8,%dl
f01002cf:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01002d0:	0f b6 c0             	movzbl %al,%eax
f01002d3:	eb 05                	jmp    f01002da <serial_proc_data+0x1a>
		return -1;
f01002d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f01002da:	5d                   	pop    %ebp
f01002db:	c3                   	ret    

f01002dc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002dc:	55                   	push   %ebp
f01002dd:	89 e5                	mov    %esp,%ebp
f01002df:	53                   	push   %ebx
f01002e0:	83 ec 04             	sub    $0x4,%esp
f01002e3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002e5:	eb 2a                	jmp    f0100311 <cons_intr+0x35>
		if (c == 0)
f01002e7:	85 d2                	test   %edx,%edx
f01002e9:	74 26                	je     f0100311 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01002eb:	a1 24 02 23 f0       	mov    0xf0230224,%eax
f01002f0:	8d 48 01             	lea    0x1(%eax),%ecx
f01002f3:	89 0d 24 02 23 f0    	mov    %ecx,0xf0230224
f01002f9:	88 90 20 00 23 f0    	mov    %dl,-0xfdcffe0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002ff:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100305:	75 0a                	jne    f0100311 <cons_intr+0x35>
			cons.wpos = 0;
f0100307:	c7 05 24 02 23 f0 00 	movl   $0x0,0xf0230224
f010030e:	00 00 00 
	while ((c = (*proc)()) != -1) {
f0100311:	ff d3                	call   *%ebx
f0100313:	89 c2                	mov    %eax,%edx
f0100315:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100318:	75 cd                	jne    f01002e7 <cons_intr+0xb>
	}
}
f010031a:	83 c4 04             	add    $0x4,%esp
f010031d:	5b                   	pop    %ebx
f010031e:	5d                   	pop    %ebp
f010031f:	c3                   	ret    

f0100320 <kbd_proc_data>:
f0100320:	ba 64 00 00 00       	mov    $0x64,%edx
f0100325:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f0100326:	a8 01                	test   $0x1,%al
f0100328:	0f 84 f7 00 00 00    	je     f0100425 <kbd_proc_data+0x105>
	if (stat & KBS_TERR)
f010032e:	a8 20                	test   $0x20,%al
f0100330:	0f 85 f5 00 00 00    	jne    f010042b <kbd_proc_data+0x10b>
f0100336:	b2 60                	mov    $0x60,%dl
f0100338:	ec                   	in     (%dx),%al
f0100339:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f010033b:	3c e0                	cmp    $0xe0,%al
f010033d:	75 0d                	jne    f010034c <kbd_proc_data+0x2c>
		shift |= E0ESC;
f010033f:	83 0d 00 00 23 f0 40 	orl    $0x40,0xf0230000
		return 0;
f0100346:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010034b:	c3                   	ret    
{
f010034c:	55                   	push   %ebp
f010034d:	89 e5                	mov    %esp,%ebp
f010034f:	53                   	push   %ebx
f0100350:	83 ec 14             	sub    $0x14,%esp
	} else if (data & 0x80) {
f0100353:	84 c0                	test   %al,%al
f0100355:	79 37                	jns    f010038e <kbd_proc_data+0x6e>
		data = (shift & E0ESC ? data : data & 0x7F);
f0100357:	8b 0d 00 00 23 f0    	mov    0xf0230000,%ecx
f010035d:	89 cb                	mov    %ecx,%ebx
f010035f:	83 e3 40             	and    $0x40,%ebx
f0100362:	83 e0 7f             	and    $0x7f,%eax
f0100365:	85 db                	test   %ebx,%ebx
f0100367:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010036a:	0f b6 d2             	movzbl %dl,%edx
f010036d:	0f b6 82 e0 6d 10 f0 	movzbl -0xfef9220(%edx),%eax
f0100374:	83 c8 40             	or     $0x40,%eax
f0100377:	0f b6 c0             	movzbl %al,%eax
f010037a:	f7 d0                	not    %eax
f010037c:	21 c1                	and    %eax,%ecx
f010037e:	89 0d 00 00 23 f0    	mov    %ecx,0xf0230000
		return 0;
f0100384:	b8 00 00 00 00       	mov    $0x0,%eax
f0100389:	e9 a3 00 00 00       	jmp    f0100431 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010038e:	8b 0d 00 00 23 f0    	mov    0xf0230000,%ecx
f0100394:	f6 c1 40             	test   $0x40,%cl
f0100397:	74 0e                	je     f01003a7 <kbd_proc_data+0x87>
		data |= 0x80;
f0100399:	83 c8 80             	or     $0xffffff80,%eax
f010039c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010039e:	83 e1 bf             	and    $0xffffffbf,%ecx
f01003a1:	89 0d 00 00 23 f0    	mov    %ecx,0xf0230000
	shift |= shiftcode[data];
f01003a7:	0f b6 d2             	movzbl %dl,%edx
f01003aa:	0f b6 82 e0 6d 10 f0 	movzbl -0xfef9220(%edx),%eax
f01003b1:	0b 05 00 00 23 f0    	or     0xf0230000,%eax
	shift ^= togglecode[data];
f01003b7:	0f b6 8a e0 6c 10 f0 	movzbl -0xfef9320(%edx),%ecx
f01003be:	31 c8                	xor    %ecx,%eax
f01003c0:	a3 00 00 23 f0       	mov    %eax,0xf0230000
	c = charcode[shift & (CTL | SHIFT)][data];
f01003c5:	89 c1                	mov    %eax,%ecx
f01003c7:	83 e1 03             	and    $0x3,%ecx
f01003ca:	8b 0c 8d c0 6c 10 f0 	mov    -0xfef9340(,%ecx,4),%ecx
f01003d1:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01003d5:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01003d8:	a8 08                	test   $0x8,%al
f01003da:	74 1b                	je     f01003f7 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f01003dc:	89 da                	mov    %ebx,%edx
f01003de:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01003e1:	83 f9 19             	cmp    $0x19,%ecx
f01003e4:	77 05                	ja     f01003eb <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f01003e6:	83 eb 20             	sub    $0x20,%ebx
f01003e9:	eb 0c                	jmp    f01003f7 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f01003eb:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003ee:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003f1:	83 fa 19             	cmp    $0x19,%edx
f01003f4:	0f 46 d9             	cmovbe %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003f7:	f7 d0                	not    %eax
f01003f9:	89 c2                	mov    %eax,%edx
	return c;
f01003fb:	89 d8                	mov    %ebx,%eax
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003fd:	f6 c2 06             	test   $0x6,%dl
f0100400:	75 2f                	jne    f0100431 <kbd_proc_data+0x111>
f0100402:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100408:	75 27                	jne    f0100431 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f010040a:	c7 04 24 85 6c 10 f0 	movl   $0xf0106c85,(%esp)
f0100411:	e8 4d 3b 00 00       	call   f0103f63 <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100416:	ba 92 00 00 00       	mov    $0x92,%edx
f010041b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100420:	ee                   	out    %al,(%dx)
	return c;
f0100421:	89 d8                	mov    %ebx,%eax
f0100423:	eb 0c                	jmp    f0100431 <kbd_proc_data+0x111>
		return -1;
f0100425:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010042a:	c3                   	ret    
		return -1;
f010042b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100430:	c3                   	ret    
}
f0100431:	83 c4 14             	add    $0x14,%esp
f0100434:	5b                   	pop    %ebx
f0100435:	5d                   	pop    %ebp
f0100436:	c3                   	ret    

f0100437 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100437:	55                   	push   %ebp
f0100438:	89 e5                	mov    %esp,%ebp
f010043a:	57                   	push   %edi
f010043b:	56                   	push   %esi
f010043c:	53                   	push   %ebx
f010043d:	83 ec 1c             	sub    $0x1c,%esp
f0100440:	89 c7                	mov    %eax,%edi
f0100442:	bb 01 32 00 00       	mov    $0x3201,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100447:	be fd 03 00 00       	mov    $0x3fd,%esi
f010044c:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100451:	eb 06                	jmp    f0100459 <cons_putc+0x22>
f0100453:	89 ca                	mov    %ecx,%edx
f0100455:	ec                   	in     (%dx),%al
f0100456:	ec                   	in     (%dx),%al
f0100457:	ec                   	in     (%dx),%al
f0100458:	ec                   	in     (%dx),%al
f0100459:	89 f2                	mov    %esi,%edx
f010045b:	ec                   	in     (%dx),%al
	for (i = 0;
f010045c:	a8 20                	test   $0x20,%al
f010045e:	75 05                	jne    f0100465 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100460:	83 eb 01             	sub    $0x1,%ebx
f0100463:	75 ee                	jne    f0100453 <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f0100465:	89 f8                	mov    %edi,%eax
f0100467:	0f b6 c0             	movzbl %al,%eax
f010046a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010046d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	bb 01 32 00 00       	mov    $0x3201,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100478:	be 79 03 00 00       	mov    $0x379,%esi
f010047d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100482:	eb 06                	jmp    f010048a <cons_putc+0x53>
f0100484:	89 ca                	mov    %ecx,%edx
f0100486:	ec                   	in     (%dx),%al
f0100487:	ec                   	in     (%dx),%al
f0100488:	ec                   	in     (%dx),%al
f0100489:	ec                   	in     (%dx),%al
f010048a:	89 f2                	mov    %esi,%edx
f010048c:	ec                   	in     (%dx),%al
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010048d:	84 c0                	test   %al,%al
f010048f:	78 05                	js     f0100496 <cons_putc+0x5f>
f0100491:	83 eb 01             	sub    $0x1,%ebx
f0100494:	75 ee                	jne    f0100484 <cons_putc+0x4d>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100496:	ba 78 03 00 00       	mov    $0x378,%edx
f010049b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010049f:	ee                   	out    %al,(%dx)
f01004a0:	b2 7a                	mov    $0x7a,%dl
f01004a2:	b8 0d 00 00 00       	mov    $0xd,%eax
f01004a7:	ee                   	out    %al,(%dx)
f01004a8:	b8 08 00 00 00       	mov    $0x8,%eax
f01004ad:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f01004ae:	89 fa                	mov    %edi,%edx
f01004b0:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01004b6:	89 f8                	mov    %edi,%eax
f01004b8:	80 cc 07             	or     $0x7,%ah
f01004bb:	85 d2                	test   %edx,%edx
f01004bd:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f01004c0:	89 f8                	mov    %edi,%eax
f01004c2:	0f b6 c0             	movzbl %al,%eax
f01004c5:	83 f8 09             	cmp    $0x9,%eax
f01004c8:	74 78                	je     f0100542 <cons_putc+0x10b>
f01004ca:	83 f8 09             	cmp    $0x9,%eax
f01004cd:	7f 0a                	jg     f01004d9 <cons_putc+0xa2>
f01004cf:	83 f8 08             	cmp    $0x8,%eax
f01004d2:	74 18                	je     f01004ec <cons_putc+0xb5>
f01004d4:	e9 9d 00 00 00       	jmp    f0100576 <cons_putc+0x13f>
f01004d9:	83 f8 0a             	cmp    $0xa,%eax
f01004dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01004e0:	74 3a                	je     f010051c <cons_putc+0xe5>
f01004e2:	83 f8 0d             	cmp    $0xd,%eax
f01004e5:	74 3d                	je     f0100524 <cons_putc+0xed>
f01004e7:	e9 8a 00 00 00       	jmp    f0100576 <cons_putc+0x13f>
		if (crt_pos > 0) {
f01004ec:	0f b7 05 28 02 23 f0 	movzwl 0xf0230228,%eax
f01004f3:	66 85 c0             	test   %ax,%ax
f01004f6:	0f 84 e5 00 00 00    	je     f01005e1 <cons_putc+0x1aa>
			crt_pos--;
f01004fc:	83 e8 01             	sub    $0x1,%eax
f01004ff:	66 a3 28 02 23 f0    	mov    %ax,0xf0230228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100505:	0f b7 c0             	movzwl %ax,%eax
f0100508:	66 81 e7 00 ff       	and    $0xff00,%di
f010050d:	83 cf 20             	or     $0x20,%edi
f0100510:	8b 15 2c 02 23 f0    	mov    0xf023022c,%edx
f0100516:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010051a:	eb 78                	jmp    f0100594 <cons_putc+0x15d>
		crt_pos += CRT_COLS;
f010051c:	66 83 05 28 02 23 f0 	addw   $0x50,0xf0230228
f0100523:	50 
		crt_pos -= (crt_pos % CRT_COLS);
f0100524:	0f b7 05 28 02 23 f0 	movzwl 0xf0230228,%eax
f010052b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100531:	c1 e8 16             	shr    $0x16,%eax
f0100534:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100537:	c1 e0 04             	shl    $0x4,%eax
f010053a:	66 a3 28 02 23 f0    	mov    %ax,0xf0230228
f0100540:	eb 52                	jmp    f0100594 <cons_putc+0x15d>
		cons_putc(' ');
f0100542:	b8 20 00 00 00       	mov    $0x20,%eax
f0100547:	e8 eb fe ff ff       	call   f0100437 <cons_putc>
		cons_putc(' ');
f010054c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100551:	e8 e1 fe ff ff       	call   f0100437 <cons_putc>
		cons_putc(' ');
f0100556:	b8 20 00 00 00       	mov    $0x20,%eax
f010055b:	e8 d7 fe ff ff       	call   f0100437 <cons_putc>
		cons_putc(' ');
f0100560:	b8 20 00 00 00       	mov    $0x20,%eax
f0100565:	e8 cd fe ff ff       	call   f0100437 <cons_putc>
		cons_putc(' ');
f010056a:	b8 20 00 00 00       	mov    $0x20,%eax
f010056f:	e8 c3 fe ff ff       	call   f0100437 <cons_putc>
f0100574:	eb 1e                	jmp    f0100594 <cons_putc+0x15d>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100576:	0f b7 05 28 02 23 f0 	movzwl 0xf0230228,%eax
f010057d:	8d 50 01             	lea    0x1(%eax),%edx
f0100580:	66 89 15 28 02 23 f0 	mov    %dx,0xf0230228
f0100587:	0f b7 c0             	movzwl %ax,%eax
f010058a:	8b 15 2c 02 23 f0    	mov    0xf023022c,%edx
f0100590:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
	if (crt_pos >= CRT_SIZE) {
f0100594:	66 81 3d 28 02 23 f0 	cmpw   $0x7cf,0xf0230228
f010059b:	cf 07 
f010059d:	76 42                	jbe    f01005e1 <cons_putc+0x1aa>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010059f:	a1 2c 02 23 f0       	mov    0xf023022c,%eax
f01005a4:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01005ab:	00 
f01005ac:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005b2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01005b6:	89 04 24             	mov    %eax,(%esp)
f01005b9:	e8 16 59 00 00       	call   f0105ed4 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01005be:	8b 15 2c 02 23 f0    	mov    0xf023022c,%edx
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005c4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01005c9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005cf:	83 c0 01             	add    $0x1,%eax
f01005d2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01005d7:	75 f0                	jne    f01005c9 <cons_putc+0x192>
		crt_pos -= CRT_COLS;
f01005d9:	66 83 2d 28 02 23 f0 	subw   $0x50,0xf0230228
f01005e0:	50 
	outb(addr_6845, 14);
f01005e1:	8b 0d 30 02 23 f0    	mov    0xf0230230,%ecx
f01005e7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ec:	89 ca                	mov    %ecx,%edx
f01005ee:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005ef:	0f b7 1d 28 02 23 f0 	movzwl 0xf0230228,%ebx
f01005f6:	8d 71 01             	lea    0x1(%ecx),%esi
f01005f9:	89 d8                	mov    %ebx,%eax
f01005fb:	66 c1 e8 08          	shr    $0x8,%ax
f01005ff:	89 f2                	mov    %esi,%edx
f0100601:	ee                   	out    %al,(%dx)
f0100602:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100607:	89 ca                	mov    %ecx,%edx
f0100609:	ee                   	out    %al,(%dx)
f010060a:	89 d8                	mov    %ebx,%eax
f010060c:	89 f2                	mov    %esi,%edx
f010060e:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010060f:	83 c4 1c             	add    $0x1c,%esp
f0100612:	5b                   	pop    %ebx
f0100613:	5e                   	pop    %esi
f0100614:	5f                   	pop    %edi
f0100615:	5d                   	pop    %ebp
f0100616:	c3                   	ret    

f0100617 <serial_intr>:
	if (serial_exists)
f0100617:	80 3d 34 02 23 f0 00 	cmpb   $0x0,0xf0230234
f010061e:	74 11                	je     f0100631 <serial_intr+0x1a>
{
f0100620:	55                   	push   %ebp
f0100621:	89 e5                	mov    %esp,%ebp
f0100623:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100626:	b8 c0 02 10 f0       	mov    $0xf01002c0,%eax
f010062b:	e8 ac fc ff ff       	call   f01002dc <cons_intr>
}
f0100630:	c9                   	leave  
f0100631:	f3 c3                	repz ret 

f0100633 <kbd_intr>:
{
f0100633:	55                   	push   %ebp
f0100634:	89 e5                	mov    %esp,%ebp
f0100636:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100639:	b8 20 03 10 f0       	mov    $0xf0100320,%eax
f010063e:	e8 99 fc ff ff       	call   f01002dc <cons_intr>
}
f0100643:	c9                   	leave  
f0100644:	c3                   	ret    

f0100645 <cons_getc>:
{
f0100645:	55                   	push   %ebp
f0100646:	89 e5                	mov    %esp,%ebp
f0100648:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f010064b:	e8 c7 ff ff ff       	call   f0100617 <serial_intr>
	kbd_intr();
f0100650:	e8 de ff ff ff       	call   f0100633 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100655:	a1 20 02 23 f0       	mov    0xf0230220,%eax
f010065a:	3b 05 24 02 23 f0    	cmp    0xf0230224,%eax
f0100660:	74 26                	je     f0100688 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100662:	8d 50 01             	lea    0x1(%eax),%edx
f0100665:	89 15 20 02 23 f0    	mov    %edx,0xf0230220
f010066b:	0f b6 88 20 00 23 f0 	movzbl -0xfdcffe0(%eax),%ecx
		return c;
f0100672:	89 c8                	mov    %ecx,%eax
		if (cons.rpos == CONSBUFSIZE)
f0100674:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010067a:	75 11                	jne    f010068d <cons_getc+0x48>
			cons.rpos = 0;
f010067c:	c7 05 20 02 23 f0 00 	movl   $0x0,0xf0230220
f0100683:	00 00 00 
f0100686:	eb 05                	jmp    f010068d <cons_getc+0x48>
	return 0;
f0100688:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010068d:	c9                   	leave  
f010068e:	c3                   	ret    

f010068f <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010068f:	55                   	push   %ebp
f0100690:	89 e5                	mov    %esp,%ebp
f0100692:	57                   	push   %edi
f0100693:	56                   	push   %esi
f0100694:	53                   	push   %ebx
f0100695:	83 ec 1c             	sub    $0x1c,%esp
	was = *cp;
f0100698:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010069f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01006a6:	5a a5 
	if (*cp != 0xA55A) {
f01006a8:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01006af:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01006b3:	74 11                	je     f01006c6 <cons_init+0x37>
		addr_6845 = MONO_BASE;
f01006b5:	c7 05 30 02 23 f0 b4 	movl   $0x3b4,0xf0230230
f01006bc:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01006bf:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01006c4:	eb 16                	jmp    f01006dc <cons_init+0x4d>
		*cp = was;
f01006c6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006cd:	c7 05 30 02 23 f0 d4 	movl   $0x3d4,0xf0230230
f01006d4:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006d7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
	outb(addr_6845, 14);
f01006dc:	8b 0d 30 02 23 f0    	mov    0xf0230230,%ecx
f01006e2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006e7:	89 ca                	mov    %ecx,%edx
f01006e9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006ea:	8d 59 01             	lea    0x1(%ecx),%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ed:	89 da                	mov    %ebx,%edx
f01006ef:	ec                   	in     (%dx),%al
f01006f0:	0f b6 f0             	movzbl %al,%esi
f01006f3:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006f6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006fb:	89 ca                	mov    %ecx,%edx
f01006fd:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006fe:	89 da                	mov    %ebx,%edx
f0100700:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100701:	89 3d 2c 02 23 f0    	mov    %edi,0xf023022c
	pos |= inb(addr_6845 + 1);
f0100707:	0f b6 d8             	movzbl %al,%ebx
f010070a:	09 de                	or     %ebx,%esi
	crt_pos = pos;
f010070c:	66 89 35 28 02 23 f0 	mov    %si,0xf0230228
	kbd_intr();
f0100713:	e8 1b ff ff ff       	call   f0100633 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f0100718:	0f b7 05 a8 13 12 f0 	movzwl 0xf01213a8,%eax
f010071f:	25 fd ff 00 00       	and    $0xfffd,%eax
f0100724:	89 04 24             	mov    %eax,(%esp)
f0100727:	e8 f8 36 00 00       	call   f0103e24 <irq_setmask_8259A>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010072c:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100731:	b8 00 00 00 00       	mov    $0x0,%eax
f0100736:	89 f2                	mov    %esi,%edx
f0100738:	ee                   	out    %al,(%dx)
f0100739:	b2 fb                	mov    $0xfb,%dl
f010073b:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100740:	ee                   	out    %al,(%dx)
f0100741:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100746:	b8 0c 00 00 00       	mov    $0xc,%eax
f010074b:	89 da                	mov    %ebx,%edx
f010074d:	ee                   	out    %al,(%dx)
f010074e:	b2 f9                	mov    $0xf9,%dl
f0100750:	b8 00 00 00 00       	mov    $0x0,%eax
f0100755:	ee                   	out    %al,(%dx)
f0100756:	b2 fb                	mov    $0xfb,%dl
f0100758:	b8 03 00 00 00       	mov    $0x3,%eax
f010075d:	ee                   	out    %al,(%dx)
f010075e:	b2 fc                	mov    $0xfc,%dl
f0100760:	b8 00 00 00 00       	mov    $0x0,%eax
f0100765:	ee                   	out    %al,(%dx)
f0100766:	b2 f9                	mov    $0xf9,%dl
f0100768:	b8 01 00 00 00       	mov    $0x1,%eax
f010076d:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010076e:	b2 fd                	mov    $0xfd,%dl
f0100770:	ec                   	in     (%dx),%al
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100771:	3c ff                	cmp    $0xff,%al
f0100773:	0f 95 c1             	setne  %cl
f0100776:	88 0d 34 02 23 f0    	mov    %cl,0xf0230234
f010077c:	89 f2                	mov    %esi,%edx
f010077e:	ec                   	in     (%dx),%al
f010077f:	89 da                	mov    %ebx,%edx
f0100781:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100782:	84 c9                	test   %cl,%cl
f0100784:	75 0c                	jne    f0100792 <cons_init+0x103>
		cprintf("Serial port does not exist!\n");
f0100786:	c7 04 24 91 6c 10 f0 	movl   $0xf0106c91,(%esp)
f010078d:	e8 d1 37 00 00       	call   f0103f63 <cprintf>
}
f0100792:	83 c4 1c             	add    $0x1c,%esp
f0100795:	5b                   	pop    %ebx
f0100796:	5e                   	pop    %esi
f0100797:	5f                   	pop    %edi
f0100798:	5d                   	pop    %ebp
f0100799:	c3                   	ret    

f010079a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010079a:	55                   	push   %ebp
f010079b:	89 e5                	mov    %esp,%ebp
f010079d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01007a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01007a3:	e8 8f fc ff ff       	call   f0100437 <cons_putc>
}
f01007a8:	c9                   	leave  
f01007a9:	c3                   	ret    

f01007aa <getchar>:

int
getchar(void)
{
f01007aa:	55                   	push   %ebp
f01007ab:	89 e5                	mov    %esp,%ebp
f01007ad:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007b0:	e8 90 fe ff ff       	call   f0100645 <cons_getc>
f01007b5:	85 c0                	test   %eax,%eax
f01007b7:	74 f7                	je     f01007b0 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007b9:	c9                   	leave  
f01007ba:	c3                   	ret    

f01007bb <iscons>:

int
iscons(int fdnum)
{
f01007bb:	55                   	push   %ebp
f01007bc:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007be:	b8 01 00 00 00       	mov    $0x1,%eax
f01007c3:	5d                   	pop    %ebp
f01007c4:	c3                   	ret    
f01007c5:	66 90                	xchg   %ax,%ax
f01007c7:	66 90                	xchg   %ax,%ax
f01007c9:	66 90                	xchg   %ax,%ax
f01007cb:	66 90                	xchg   %ax,%ax
f01007cd:	66 90                	xchg   %ax,%ax
f01007cf:	90                   	nop

f01007d0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007d0:	55                   	push   %ebp
f01007d1:	89 e5                	mov    %esp,%ebp
f01007d3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007d6:	c7 44 24 08 e0 6e 10 	movl   $0xf0106ee0,0x8(%esp)
f01007dd:	f0 
f01007de:	c7 44 24 04 fe 6e 10 	movl   $0xf0106efe,0x4(%esp)
f01007e5:	f0 
f01007e6:	c7 04 24 03 6f 10 f0 	movl   $0xf0106f03,(%esp)
f01007ed:	e8 71 37 00 00       	call   f0103f63 <cprintf>
f01007f2:	c7 44 24 08 a8 6f 10 	movl   $0xf0106fa8,0x8(%esp)
f01007f9:	f0 
f01007fa:	c7 44 24 04 0c 6f 10 	movl   $0xf0106f0c,0x4(%esp)
f0100801:	f0 
f0100802:	c7 04 24 03 6f 10 f0 	movl   $0xf0106f03,(%esp)
f0100809:	e8 55 37 00 00       	call   f0103f63 <cprintf>
f010080e:	c7 44 24 08 15 6f 10 	movl   $0xf0106f15,0x8(%esp)
f0100815:	f0 
f0100816:	c7 44 24 04 25 6f 10 	movl   $0xf0106f25,0x4(%esp)
f010081d:	f0 
f010081e:	c7 04 24 03 6f 10 f0 	movl   $0xf0106f03,(%esp)
f0100825:	e8 39 37 00 00       	call   f0103f63 <cprintf>
	return 0;
}
f010082a:	b8 00 00 00 00       	mov    $0x0,%eax
f010082f:	c9                   	leave  
f0100830:	c3                   	ret    

f0100831 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100831:	55                   	push   %ebp
f0100832:	89 e5                	mov    %esp,%ebp
f0100834:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100837:	c7 04 24 2f 6f 10 f0 	movl   $0xf0106f2f,(%esp)
f010083e:	e8 20 37 00 00       	call   f0103f63 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100843:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010084a:	00 
f010084b:	c7 04 24 d0 6f 10 f0 	movl   $0xf0106fd0,(%esp)
f0100852:	e8 0c 37 00 00       	call   f0103f63 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100857:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010085e:	00 
f010085f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100866:	f0 
f0100867:	c7 04 24 f8 6f 10 f0 	movl   $0xf0106ff8,(%esp)
f010086e:	e8 f0 36 00 00       	call   f0103f63 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100873:	c7 44 24 08 a7 6b 10 	movl   $0x106ba7,0x8(%esp)
f010087a:	00 
f010087b:	c7 44 24 04 a7 6b 10 	movl   $0xf0106ba7,0x4(%esp)
f0100882:	f0 
f0100883:	c7 04 24 1c 70 10 f0 	movl   $0xf010701c,(%esp)
f010088a:	e8 d4 36 00 00       	call   f0103f63 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010088f:	c7 44 24 08 00 00 23 	movl   $0x230000,0x8(%esp)
f0100896:	00 
f0100897:	c7 44 24 04 00 00 23 	movl   $0xf0230000,0x4(%esp)
f010089e:	f0 
f010089f:	c7 04 24 40 70 10 f0 	movl   $0xf0107040,(%esp)
f01008a6:	e8 b8 36 00 00       	call   f0103f63 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01008ab:	c7 44 24 08 08 20 27 	movl   $0x272008,0x8(%esp)
f01008b2:	00 
f01008b3:	c7 44 24 04 08 20 27 	movl   $0xf0272008,0x4(%esp)
f01008ba:	f0 
f01008bb:	c7 04 24 64 70 10 f0 	movl   $0xf0107064,(%esp)
f01008c2:	e8 9c 36 00 00       	call   f0103f63 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01008c7:	b8 07 24 27 f0       	mov    $0xf0272407,%eax
f01008cc:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01008d1:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008d6:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01008dc:	85 c0                	test   %eax,%eax
f01008de:	0f 48 c2             	cmovs  %edx,%eax
f01008e1:	c1 f8 0a             	sar    $0xa,%eax
f01008e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e8:	c7 04 24 88 70 10 f0 	movl   $0xf0107088,(%esp)
f01008ef:	e8 6f 36 00 00       	call   f0103f63 <cprintf>
	return 0;
}
f01008f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01008f9:	c9                   	leave  
f01008fa:	c3                   	ret    

f01008fb <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008fb:	55                   	push   %ebp
f01008fc:	89 e5                	mov    %esp,%ebp
f01008fe:	57                   	push   %edi
f01008ff:	56                   	push   %esi
f0100900:	53                   	push   %ebx
f0100901:	83 ec 5c             	sub    $0x5c,%esp
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100904:	89 eb                	mov    %ebp,%ebx

	uint32_t ebp = read_ebp(), eip, arguments[5];
	struct Eipdebuginfo debuginfo;
	int i = 0;

	cprintf("Stack Backtrace:\n");
f0100906:	c7 04 24 48 6f 10 f0 	movl   $0xf0106f48,(%esp)
f010090d:	e8 51 36 00 00       	call   f0103f63 <cprintf>
		eip = ((uint32_t *)ebp)[1];
		for (i = 0; i < 4; i++)
		{
			arguments[i] = ((uint32_t *)ebp)[i + 2];
		}
		debuginfo_eip (eip, &debuginfo);
f0100912:	8d 7d bc             	lea    -0x44(%ebp),%edi
	while (ebp)
f0100915:	e9 8c 00 00 00       	jmp    f01009a6 <mon_backtrace+0xab>
		eip = ((uint32_t *)ebp)[1];
f010091a:	8b 73 04             	mov    0x4(%ebx),%esi
		for (i = 0; i < 4; i++)
f010091d:	b8 00 00 00 00       	mov    $0x0,%eax
			arguments[i] = ((uint32_t *)ebp)[i + 2];
f0100922:	8b 54 83 08          	mov    0x8(%ebx,%eax,4),%edx
f0100926:	89 54 85 d4          	mov    %edx,-0x2c(%ebp,%eax,4)
		for (i = 0; i < 4; i++)
f010092a:	83 c0 01             	add    $0x1,%eax
f010092d:	83 f8 04             	cmp    $0x4,%eax
f0100930:	75 f0                	jne    f0100922 <mon_backtrace+0x27>
		debuginfo_eip (eip, &debuginfo);
f0100932:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100936:	89 34 24             	mov    %esi,(%esp)
f0100939:	e8 11 4a 00 00       	call   f010534f <debuginfo_eip>

		cprintf(" ebp  %08x  eip %08x  args  %08x %08x %08x %08x %08x\n", ebp, eip, arguments[0], arguments[1], arguments[2], arguments[3], arguments[4]);
f010093e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100941:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100945:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100948:	89 44 24 18          	mov    %eax,0x18(%esp)
f010094c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010094f:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100953:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100956:	89 44 24 10          	mov    %eax,0x10(%esp)
f010095a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010095d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100961:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100965:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100969:	c7 04 24 b4 70 10 f0 	movl   $0xf01070b4,(%esp)
f0100970:	e8 ee 35 00 00       	call   f0103f63 <cprintf>
		cprintf("\t%s:%d: %.*s+%u\n", debuginfo.eip_file, debuginfo.eip_line, debuginfo.eip_fn_namelen, debuginfo.eip_fn_name, eip - debuginfo.eip_fn_addr);
f0100975:	2b 75 cc             	sub    -0x34(%ebp),%esi
f0100978:	89 74 24 14          	mov    %esi,0x14(%esp)
f010097c:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010097f:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100983:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100986:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010098a:	8b 45 c0             	mov    -0x40(%ebp),%eax
f010098d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100991:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0100994:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100998:	c7 04 24 5a 6f 10 f0 	movl   $0xf0106f5a,(%esp)
f010099f:	e8 bf 35 00 00       	call   f0103f63 <cprintf>

		ebp = *((uint32_t *)ebp);
f01009a4:	8b 1b                	mov    (%ebx),%ebx
	while (ebp)
f01009a6:	85 db                	test   %ebx,%ebx
f01009a8:	0f 85 6c ff ff ff    	jne    f010091a <mon_backtrace+0x1f>
	}
	return 0;
}
f01009ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01009b3:	83 c4 5c             	add    $0x5c,%esp
f01009b6:	5b                   	pop    %ebx
f01009b7:	5e                   	pop    %esi
f01009b8:	5f                   	pop    %edi
f01009b9:	5d                   	pop    %ebp
f01009ba:	c3                   	ret    

f01009bb <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01009bb:	55                   	push   %ebp
f01009bc:	89 e5                	mov    %esp,%ebp
f01009be:	57                   	push   %edi
f01009bf:	56                   	push   %esi
f01009c0:	53                   	push   %ebx
f01009c1:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01009c4:	c7 04 24 ec 70 10 f0 	movl   $0xf01070ec,(%esp)
f01009cb:	e8 93 35 00 00       	call   f0103f63 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009d0:	c7 04 24 10 71 10 f0 	movl   $0xf0107110,(%esp)
f01009d7:	e8 87 35 00 00       	call   f0103f63 <cprintf>

	if (tf != NULL)
f01009dc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01009e0:	74 0b                	je     f01009ed <monitor+0x32>
		print_trapframe(tf);
f01009e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01009e5:	89 04 24             	mov    %eax,(%esp)
f01009e8:	e8 63 3b 00 00       	call   f0104550 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f01009ed:	c7 04 24 6b 6f 10 f0 	movl   $0xf0106f6b,(%esp)
f01009f4:	e8 37 52 00 00       	call   f0105c30 <readline>
f01009f9:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01009fb:	85 c0                	test   %eax,%eax
f01009fd:	74 ee                	je     f01009ed <monitor+0x32>
	argv[argc] = 0;
f01009ff:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100a06:	be 00 00 00 00       	mov    $0x0,%esi
f0100a0b:	eb 0a                	jmp    f0100a17 <monitor+0x5c>
			*buf++ = 0;
f0100a0d:	c6 03 00             	movb   $0x0,(%ebx)
f0100a10:	89 f7                	mov    %esi,%edi
f0100a12:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100a15:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f0100a17:	0f b6 03             	movzbl (%ebx),%eax
f0100a1a:	84 c0                	test   %al,%al
f0100a1c:	74 66                	je     f0100a84 <monitor+0xc9>
f0100a1e:	0f be c0             	movsbl %al,%eax
f0100a21:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a25:	c7 04 24 6f 6f 10 f0 	movl   $0xf0106f6f,(%esp)
f0100a2c:	e8 19 54 00 00       	call   f0105e4a <strchr>
f0100a31:	85 c0                	test   %eax,%eax
f0100a33:	75 d8                	jne    f0100a0d <monitor+0x52>
		if (*buf == 0)
f0100a35:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100a38:	74 4a                	je     f0100a84 <monitor+0xc9>
		if (argc == MAXARGS-1) {
f0100a3a:	83 fe 0f             	cmp    $0xf,%esi
f0100a3d:	8d 76 00             	lea    0x0(%esi),%esi
f0100a40:	75 16                	jne    f0100a58 <monitor+0x9d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a42:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100a49:	00 
f0100a4a:	c7 04 24 74 6f 10 f0 	movl   $0xf0106f74,(%esp)
f0100a51:	e8 0d 35 00 00       	call   f0103f63 <cprintf>
f0100a56:	eb 95                	jmp    f01009ed <monitor+0x32>
		argv[argc++] = buf;
f0100a58:	8d 7e 01             	lea    0x1(%esi),%edi
f0100a5b:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100a5f:	eb 03                	jmp    f0100a64 <monitor+0xa9>
			buf++;
f0100a61:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a64:	0f b6 03             	movzbl (%ebx),%eax
f0100a67:	84 c0                	test   %al,%al
f0100a69:	74 aa                	je     f0100a15 <monitor+0x5a>
f0100a6b:	0f be c0             	movsbl %al,%eax
f0100a6e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a72:	c7 04 24 6f 6f 10 f0 	movl   $0xf0106f6f,(%esp)
f0100a79:	e8 cc 53 00 00       	call   f0105e4a <strchr>
f0100a7e:	85 c0                	test   %eax,%eax
f0100a80:	74 df                	je     f0100a61 <monitor+0xa6>
f0100a82:	eb 91                	jmp    f0100a15 <monitor+0x5a>
	argv[argc] = 0;
f0100a84:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a8b:	00 
	if (argc == 0)
f0100a8c:	85 f6                	test   %esi,%esi
f0100a8e:	0f 84 59 ff ff ff    	je     f01009ed <monitor+0x32>
f0100a94:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100a99:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a9c:	8b 04 85 40 71 10 f0 	mov    -0xfef8ec0(,%eax,4),%eax
f0100aa3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100aa7:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100aaa:	89 04 24             	mov    %eax,(%esp)
f0100aad:	e8 3a 53 00 00       	call   f0105dec <strcmp>
f0100ab2:	85 c0                	test   %eax,%eax
f0100ab4:	75 24                	jne    f0100ada <monitor+0x11f>
			return commands[i].func(argc, argv, tf);
f0100ab6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100ab9:	8b 55 08             	mov    0x8(%ebp),%edx
f0100abc:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100ac0:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100ac3:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100ac7:	89 34 24             	mov    %esi,(%esp)
f0100aca:	ff 14 85 48 71 10 f0 	call   *-0xfef8eb8(,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100ad1:	85 c0                	test   %eax,%eax
f0100ad3:	78 25                	js     f0100afa <monitor+0x13f>
f0100ad5:	e9 13 ff ff ff       	jmp    f01009ed <monitor+0x32>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100ada:	83 c3 01             	add    $0x1,%ebx
f0100add:	83 fb 03             	cmp    $0x3,%ebx
f0100ae0:	75 b7                	jne    f0100a99 <monitor+0xde>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100ae2:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100ae5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ae9:	c7 04 24 91 6f 10 f0 	movl   $0xf0106f91,(%esp)
f0100af0:	e8 6e 34 00 00       	call   f0103f63 <cprintf>
f0100af5:	e9 f3 fe ff ff       	jmp    f01009ed <monitor+0x32>
				break;
	}
}
f0100afa:	83 c4 5c             	add    $0x5c,%esp
f0100afd:	5b                   	pop    %ebx
f0100afe:	5e                   	pop    %esi
f0100aff:	5f                   	pop    %edi
f0100b00:	5d                   	pop    %ebp
f0100b01:	c3                   	ret    
f0100b02:	66 90                	xchg   %ax,%ax
f0100b04:	66 90                	xchg   %ax,%ax
f0100b06:	66 90                	xchg   %ax,%ax
f0100b08:	66 90                	xchg   %ax,%ax
f0100b0a:	66 90                	xchg   %ax,%ax
f0100b0c:	66 90                	xchg   %ax,%ax
f0100b0e:	66 90                	xchg   %ax,%ax

f0100b10 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b10:	55                   	push   %ebp
f0100b11:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b13:	83 3d 38 02 23 f0 00 	cmpl   $0x0,0xf0230238
f0100b1a:	75 37                	jne    f0100b53 <boot_alloc+0x43>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b1c:	ba 07 30 27 f0       	mov    $0xf0273007,%edx
f0100b21:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b27:	89 15 38 02 23 f0    	mov    %edx,0xf0230238
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	if (n > 0)
f0100b2d:	85 c0                	test   %eax,%eax
f0100b2f:	74 1b                	je     f0100b4c <boot_alloc+0x3c>
	{
		uint32_t sizetoalloc = ROUNDUP(n, PGSIZE);
f0100b31:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
		result = nextfree;
f0100b37:	a1 38 02 23 f0       	mov    0xf0230238,%eax
		uint32_t sizetoalloc = ROUNDUP(n, PGSIZE);
f0100b3c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
		nextfree = nextfree + sizetoalloc;
f0100b42:	01 c2                	add    %eax,%edx
f0100b44:	89 15 38 02 23 f0    	mov    %edx,0xf0230238

		return result;
f0100b4a:	eb 0d                	jmp    f0100b59 <boot_alloc+0x49>
		if ((uintptr_t)nextfree >= 0xf0400000)
			panic("boot_alloc: out of memory");
	}
	else if (n == 0)
	{
		result = nextfree;
f0100b4c:	a1 38 02 23 f0       	mov    0xf0230238,%eax
		return result;
f0100b51:	eb 06                	jmp    f0100b59 <boot_alloc+0x49>
	if (n > 0)
f0100b53:	85 c0                	test   %eax,%eax
f0100b55:	74 f5                	je     f0100b4c <boot_alloc+0x3c>
f0100b57:	eb d8                	jmp    f0100b31 <boot_alloc+0x21>
	}
	return NULL;
}
f0100b59:	5d                   	pop    %ebp
f0100b5a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0100b60:	c3                   	ret    

f0100b61 <nvram_read>:
{
f0100b61:	55                   	push   %ebp
f0100b62:	89 e5                	mov    %esp,%ebp
f0100b64:	56                   	push   %esi
f0100b65:	53                   	push   %ebx
f0100b66:	83 ec 10             	sub    $0x10,%esp
f0100b69:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100b6b:	89 04 24             	mov    %eax,(%esp)
f0100b6e:	e8 87 32 00 00       	call   f0103dfa <mc146818_read>
f0100b73:	89 c6                	mov    %eax,%esi
f0100b75:	83 c3 01             	add    $0x1,%ebx
f0100b78:	89 1c 24             	mov    %ebx,(%esp)
f0100b7b:	e8 7a 32 00 00       	call   f0103dfa <mc146818_read>
f0100b80:	c1 e0 08             	shl    $0x8,%eax
f0100b83:	09 f0                	or     %esi,%eax
}
f0100b85:	83 c4 10             	add    $0x10,%esp
f0100b88:	5b                   	pop    %ebx
f0100b89:	5e                   	pop    %esi
f0100b8a:	5d                   	pop    %ebp
f0100b8b:	c3                   	ret    

f0100b8c <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b8c:	2b 05 90 0e 23 f0    	sub    0xf0230e90,%eax
f0100b92:	c1 f8 03             	sar    $0x3,%eax
f0100b95:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100b98:	89 c2                	mov    %eax,%edx
f0100b9a:	c1 ea 0c             	shr    $0xc,%edx
f0100b9d:	3b 15 88 0e 23 f0    	cmp    0xf0230e88,%edx
f0100ba3:	72 26                	jb     f0100bcb <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100ba5:	55                   	push   %ebp
f0100ba6:	89 e5                	mov    %esp,%ebp
f0100ba8:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100baf:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f0100bb6:	f0 
f0100bb7:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100bbe:	00 
f0100bbf:	c7 04 24 a5 7a 10 f0 	movl   $0xf0107aa5,(%esp)
f0100bc6:	e8 75 f4 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100bcb:	2d 00 00 00 10       	sub    $0x10000000,%eax
	return KADDR(page2pa(pp));
}
f0100bd0:	c3                   	ret    

f0100bd1 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100bd1:	89 d1                	mov    %edx,%ecx
f0100bd3:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100bd6:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100bd9:	a8 01                	test   $0x1,%al
f0100bdb:	74 5d                	je     f0100c3a <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100bdd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100be2:	89 c1                	mov    %eax,%ecx
f0100be4:	c1 e9 0c             	shr    $0xc,%ecx
f0100be7:	3b 0d 88 0e 23 f0    	cmp    0xf0230e88,%ecx
f0100bed:	72 26                	jb     f0100c15 <check_va2pa+0x44>
{
f0100bef:	55                   	push   %ebp
f0100bf0:	89 e5                	mov    %esp,%ebp
f0100bf2:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bf5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100bf9:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f0100c00:	f0 
f0100c01:	c7 44 24 04 ca 03 00 	movl   $0x3ca,0x4(%esp)
f0100c08:	00 
f0100c09:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0100c10:	e8 2b f4 ff ff       	call   f0100040 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100c15:	c1 ea 0c             	shr    $0xc,%edx
f0100c18:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100c1e:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100c25:	89 c2                	mov    %eax,%edx
f0100c27:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100c2a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c2f:	85 d2                	test   %edx,%edx
f0100c31:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100c36:	0f 44 c2             	cmove  %edx,%eax
f0100c39:	c3                   	ret    
		return ~0;
f0100c3a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100c3f:	c3                   	ret    

f0100c40 <check_page_free_list>:
{
f0100c40:	55                   	push   %ebp
f0100c41:	89 e5                	mov    %esp,%ebp
f0100c43:	57                   	push   %edi
f0100c44:	56                   	push   %esi
f0100c45:	53                   	push   %ebx
f0100c46:	83 ec 4c             	sub    $0x4c,%esp
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c49:	84 c0                	test   %al,%al
f0100c4b:	0f 85 3f 03 00 00    	jne    f0100f90 <check_page_free_list+0x350>
f0100c51:	e9 4f 03 00 00       	jmp    f0100fa5 <check_page_free_list+0x365>
		panic("'page_free_list' is a null pointer!");
f0100c56:	c7 44 24 08 64 71 10 	movl   $0xf0107164,0x8(%esp)
f0100c5d:	f0 
f0100c5e:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0100c65:	00 
f0100c66:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0100c6d:	e8 ce f3 ff ff       	call   f0100040 <_panic>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100c72:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100c75:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c78:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c7b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100c7e:	89 c2                	mov    %eax,%edx
f0100c80:	2b 15 90 0e 23 f0    	sub    0xf0230e90,%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100c86:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100c8c:	0f 95 c2             	setne  %dl
f0100c8f:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100c92:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100c96:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c98:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c9c:	8b 00                	mov    (%eax),%eax
f0100c9e:	85 c0                	test   %eax,%eax
f0100ca0:	75 dc                	jne    f0100c7e <check_page_free_list+0x3e>
		*tp[1] = 0;
f0100ca2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ca5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100cab:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cae:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cb1:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100cb3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100cb6:	a3 40 02 23 f0       	mov    %eax,0xf0230240
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cbb:	be 01 00 00 00       	mov    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100cc0:	8b 1d 40 02 23 f0    	mov    0xf0230240,%ebx
f0100cc6:	eb 63                	jmp    f0100d2b <check_page_free_list+0xeb>
f0100cc8:	89 d8                	mov    %ebx,%eax
f0100cca:	2b 05 90 0e 23 f0    	sub    0xf0230e90,%eax
f0100cd0:	c1 f8 03             	sar    $0x3,%eax
f0100cd3:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100cd6:	89 c2                	mov    %eax,%edx
f0100cd8:	c1 ea 16             	shr    $0x16,%edx
f0100cdb:	39 f2                	cmp    %esi,%edx
f0100cdd:	73 4a                	jae    f0100d29 <check_page_free_list+0xe9>
	if (PGNUM(pa) >= npages)
f0100cdf:	89 c2                	mov    %eax,%edx
f0100ce1:	c1 ea 0c             	shr    $0xc,%edx
f0100ce4:	3b 15 88 0e 23 f0    	cmp    0xf0230e88,%edx
f0100cea:	72 20                	jb     f0100d0c <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cec:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cf0:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f0100cf7:	f0 
f0100cf8:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100cff:	00 
f0100d00:	c7 04 24 a5 7a 10 f0 	movl   $0xf0107aa5,(%esp)
f0100d07:	e8 34 f3 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100d0c:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100d13:	00 
f0100d14:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100d1b:	00 
	return (void *)(pa + KERNBASE);
f0100d1c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d21:	89 04 24             	mov    %eax,(%esp)
f0100d24:	e8 5e 51 00 00       	call   f0105e87 <memset>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d29:	8b 1b                	mov    (%ebx),%ebx
f0100d2b:	85 db                	test   %ebx,%ebx
f0100d2d:	75 99                	jne    f0100cc8 <check_page_free_list+0x88>
	first_free_page = (char *) boot_alloc(0);
f0100d2f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d34:	e8 d7 fd ff ff       	call   f0100b10 <boot_alloc>
f0100d39:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d3c:	8b 15 40 02 23 f0    	mov    0xf0230240,%edx
		assert(pp >= pages);
f0100d42:	8b 0d 90 0e 23 f0    	mov    0xf0230e90,%ecx
		assert(pp < pages + npages);
f0100d48:	a1 88 0e 23 f0       	mov    0xf0230e88,%eax
f0100d4d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100d50:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100d53:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d56:	89 4d cc             	mov    %ecx,-0x34(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100d59:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d5e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d61:	e9 c4 01 00 00       	jmp    f0100f2a <check_page_free_list+0x2ea>
		assert(pp >= pages);
f0100d66:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100d69:	73 24                	jae    f0100d8f <check_page_free_list+0x14f>
f0100d6b:	c7 44 24 0c bf 7a 10 	movl   $0xf0107abf,0xc(%esp)
f0100d72:	f0 
f0100d73:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0100d7a:	f0 
f0100d7b:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0100d82:	00 
f0100d83:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0100d8a:	e8 b1 f2 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100d8f:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100d92:	72 24                	jb     f0100db8 <check_page_free_list+0x178>
f0100d94:	c7 44 24 0c e0 7a 10 	movl   $0xf0107ae0,0xc(%esp)
f0100d9b:	f0 
f0100d9c:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0100da3:	f0 
f0100da4:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f0100dab:	00 
f0100dac:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0100db3:	e8 88 f2 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100db8:	89 d0                	mov    %edx,%eax
f0100dba:	2b 45 cc             	sub    -0x34(%ebp),%eax
f0100dbd:	a8 07                	test   $0x7,%al
f0100dbf:	74 24                	je     f0100de5 <check_page_free_list+0x1a5>
f0100dc1:	c7 44 24 0c 88 71 10 	movl   $0xf0107188,0xc(%esp)
f0100dc8:	f0 
f0100dc9:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0100dd0:	f0 
f0100dd1:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f0100dd8:	00 
f0100dd9:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0100de0:	e8 5b f2 ff ff       	call   f0100040 <_panic>
	return (pp - pages) << PGSHIFT;
f0100de5:	c1 f8 03             	sar    $0x3,%eax
f0100de8:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100deb:	85 c0                	test   %eax,%eax
f0100ded:	75 24                	jne    f0100e13 <check_page_free_list+0x1d3>
f0100def:	c7 44 24 0c f4 7a 10 	movl   $0xf0107af4,0xc(%esp)
f0100df6:	f0 
f0100df7:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0100dfe:	f0 
f0100dff:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0100e06:	00 
f0100e07:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0100e0e:	e8 2d f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e13:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e18:	75 24                	jne    f0100e3e <check_page_free_list+0x1fe>
f0100e1a:	c7 44 24 0c 05 7b 10 	movl   $0xf0107b05,0xc(%esp)
f0100e21:	f0 
f0100e22:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0100e29:	f0 
f0100e2a:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0100e31:	00 
f0100e32:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0100e39:	e8 02 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e3e:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e43:	75 24                	jne    f0100e69 <check_page_free_list+0x229>
f0100e45:	c7 44 24 0c bc 71 10 	movl   $0xf01071bc,0xc(%esp)
f0100e4c:	f0 
f0100e4d:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0100e54:	f0 
f0100e55:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0100e5c:	00 
f0100e5d:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0100e64:	e8 d7 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e69:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e6e:	75 24                	jne    f0100e94 <check_page_free_list+0x254>
f0100e70:	c7 44 24 0c 1e 7b 10 	movl   $0xf0107b1e,0xc(%esp)
f0100e77:	f0 
f0100e78:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0100e7f:	f0 
f0100e80:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0100e87:	00 
f0100e88:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0100e8f:	e8 ac f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e94:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e99:	0f 86 2d 01 00 00    	jbe    f0100fcc <check_page_free_list+0x38c>
	if (PGNUM(pa) >= npages)
f0100e9f:	89 c1                	mov    %eax,%ecx
f0100ea1:	c1 e9 0c             	shr    $0xc,%ecx
f0100ea4:	39 4d c4             	cmp    %ecx,-0x3c(%ebp)
f0100ea7:	77 20                	ja     f0100ec9 <check_page_free_list+0x289>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ea9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ead:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f0100eb4:	f0 
f0100eb5:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100ebc:	00 
f0100ebd:	c7 04 24 a5 7a 10 f0 	movl   $0xf0107aa5,(%esp)
f0100ec4:	e8 77 f1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100ec9:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f0100ecf:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100ed2:	0f 86 e4 00 00 00    	jbe    f0100fbc <check_page_free_list+0x37c>
f0100ed8:	c7 44 24 0c e0 71 10 	movl   $0xf01071e0,0xc(%esp)
f0100edf:	f0 
f0100ee0:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0100ee7:	f0 
f0100ee8:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0100eef:	00 
f0100ef0:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0100ef7:	e8 44 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100efc:	c7 44 24 0c 38 7b 10 	movl   $0xf0107b38,0xc(%esp)
f0100f03:	f0 
f0100f04:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0100f0b:	f0 
f0100f0c:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0100f13:	00 
f0100f14:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0100f1b:	e8 20 f1 ff ff       	call   f0100040 <_panic>
			++nfree_basemem;
f0100f20:	83 c3 01             	add    $0x1,%ebx
f0100f23:	eb 03                	jmp    f0100f28 <check_page_free_list+0x2e8>
			++nfree_extmem;
f0100f25:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f28:	8b 12                	mov    (%edx),%edx
f0100f2a:	85 d2                	test   %edx,%edx
f0100f2c:	0f 85 34 fe ff ff    	jne    f0100d66 <check_page_free_list+0x126>
	assert(nfree_basemem > 0);
f0100f32:	85 db                	test   %ebx,%ebx
f0100f34:	7f 24                	jg     f0100f5a <check_page_free_list+0x31a>
f0100f36:	c7 44 24 0c 55 7b 10 	movl   $0xf0107b55,0xc(%esp)
f0100f3d:	f0 
f0100f3e:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0100f45:	f0 
f0100f46:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0100f4d:	00 
f0100f4e:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0100f55:	e8 e6 f0 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100f5a:	85 ff                	test   %edi,%edi
f0100f5c:	7f 24                	jg     f0100f82 <check_page_free_list+0x342>
f0100f5e:	c7 44 24 0c 67 7b 10 	movl   $0xf0107b67,0xc(%esp)
f0100f65:	f0 
f0100f66:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0100f6d:	f0 
f0100f6e:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0100f75:	00 
f0100f76:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0100f7d:	e8 be f0 ff ff       	call   f0100040 <_panic>
	cprintf("check_page_free_list() succeeded!\n");
f0100f82:	c7 04 24 28 72 10 f0 	movl   $0xf0107228,(%esp)
f0100f89:	e8 d5 2f 00 00       	call   f0103f63 <cprintf>
f0100f8e:	eb 4c                	jmp    f0100fdc <check_page_free_list+0x39c>
	if (!page_free_list)
f0100f90:	a1 40 02 23 f0       	mov    0xf0230240,%eax
f0100f95:	85 c0                	test   %eax,%eax
f0100f97:	0f 85 d5 fc ff ff    	jne    f0100c72 <check_page_free_list+0x32>
f0100f9d:	8d 76 00             	lea    0x0(%esi),%esi
f0100fa0:	e9 b1 fc ff ff       	jmp    f0100c56 <check_page_free_list+0x16>
f0100fa5:	83 3d 40 02 23 f0 00 	cmpl   $0x0,0xf0230240
f0100fac:	0f 84 a4 fc ff ff    	je     f0100c56 <check_page_free_list+0x16>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100fb2:	be 00 04 00 00       	mov    $0x400,%esi
f0100fb7:	e9 04 fd ff ff       	jmp    f0100cc0 <check_page_free_list+0x80>
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100fbc:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100fc1:	0f 85 5e ff ff ff    	jne    f0100f25 <check_page_free_list+0x2e5>
f0100fc7:	e9 30 ff ff ff       	jmp    f0100efc <check_page_free_list+0x2bc>
f0100fcc:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100fd1:	0f 85 49 ff ff ff    	jne    f0100f20 <check_page_free_list+0x2e0>
f0100fd7:	e9 20 ff ff ff       	jmp    f0100efc <check_page_free_list+0x2bc>
}
f0100fdc:	83 c4 4c             	add    $0x4c,%esp
f0100fdf:	5b                   	pop    %ebx
f0100fe0:	5e                   	pop    %esi
f0100fe1:	5f                   	pop    %edi
f0100fe2:	5d                   	pop    %ebp
f0100fe3:	c3                   	ret    

f0100fe4 <page_init>:
{
f0100fe4:	55                   	push   %ebp
f0100fe5:	89 e5                	mov    %esp,%ebp
f0100fe7:	56                   	push   %esi
f0100fe8:	53                   	push   %ebx
f0100fe9:	83 ec 10             	sub    $0x10,%esp
	page_free_list = 0;
f0100fec:	c7 05 40 02 23 f0 00 	movl   $0x0,0xf0230240
f0100ff3:	00 00 00 
	for (i = 0; i < npages; i++)
f0100ff6:	be 00 00 00 00       	mov    $0x0,%esi
f0100ffb:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101000:	e9 da 00 00 00       	jmp    f01010df <page_init+0xfb>
		if(i == 0)
f0101005:	85 db                	test   %ebx,%ebx
f0101007:	75 16                	jne    f010101f <page_init+0x3b>
			pages[i].pp_ref = 1;
f0101009:	a1 90 0e 23 f0       	mov    0xf0230e90,%eax
f010100e:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0101014:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f010101a:	e9 ba 00 00 00       	jmp    f01010d9 <page_init+0xf5>
		else if (i == MPENTRY_PADDR / PGSIZE)
f010101f:	83 fb 07             	cmp    $0x7,%ebx
f0101022:	75 17                	jne    f010103b <page_init+0x57>
			pages[i].pp_ref = 1;
f0101024:	a1 90 0e 23 f0       	mov    0xf0230e90,%eax
f0101029:	66 c7 40 3c 01 00    	movw   $0x1,0x3c(%eax)
			pages[i].pp_link = NULL;
f010102f:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
f0101036:	e9 9e 00 00 00       	jmp    f01010d9 <page_init+0xf5>
f010103b:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
		else if (i >= (IOPHYSMEM / PGSIZE) && i < (EXTPHYSMEM / PGSIZE))
f0101041:	83 f8 5f             	cmp    $0x5f,%eax
f0101044:	77 15                	ja     f010105b <page_init+0x77>
			pages[i].pp_ref = 1;
f0101046:	a1 90 0e 23 f0       	mov    0xf0230e90,%eax
f010104b:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
			pages[i].pp_link = NULL;
f0101052:	c7 04 30 00 00 00 00 	movl   $0x0,(%eax,%esi,1)
f0101059:	eb 7e                	jmp    f01010d9 <page_init+0xf5>
		else if (i >= EXTPHYSMEM / PGSIZE && i < PGNUM(PADDR(boot_alloc(0))))
f010105b:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0101061:	76 53                	jbe    f01010b6 <page_init+0xd2>
f0101063:	b8 00 00 00 00       	mov    $0x0,%eax
f0101068:	e8 a3 fa ff ff       	call   f0100b10 <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f010106d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101072:	77 20                	ja     f0101094 <page_init+0xb0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101074:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101078:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f010107f:	f0 
f0101080:	c7 44 24 04 5b 01 00 	movl   $0x15b,0x4(%esp)
f0101087:	00 
f0101088:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010108f:	e8 ac ef ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101094:	05 00 00 00 10       	add    $0x10000000,%eax
f0101099:	c1 e8 0c             	shr    $0xc,%eax
f010109c:	39 c3                	cmp    %eax,%ebx
f010109e:	73 16                	jae    f01010b6 <page_init+0xd2>
			pages[i].pp_ref = 1;
f01010a0:	89 f0                	mov    %esi,%eax
f01010a2:	03 05 90 0e 23 f0    	add    0xf0230e90,%eax
f01010a8:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f01010ae:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f01010b4:	eb 23                	jmp    f01010d9 <page_init+0xf5>
			pages[i].pp_ref = 0;
f01010b6:	89 f0                	mov    %esi,%eax
f01010b8:	03 05 90 0e 23 f0    	add    0xf0230e90,%eax
f01010be:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f01010c4:	8b 15 40 02 23 f0    	mov    0xf0230240,%edx
f01010ca:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f01010cc:	89 f0                	mov    %esi,%eax
f01010ce:	03 05 90 0e 23 f0    	add    0xf0230e90,%eax
f01010d4:	a3 40 02 23 f0       	mov    %eax,0xf0230240
	for (i = 0; i < npages; i++)
f01010d9:	83 c3 01             	add    $0x1,%ebx
f01010dc:	83 c6 08             	add    $0x8,%esi
f01010df:	3b 1d 88 0e 23 f0    	cmp    0xf0230e88,%ebx
f01010e5:	0f 82 1a ff ff ff    	jb     f0101005 <page_init+0x21>
}
f01010eb:	83 c4 10             	add    $0x10,%esp
f01010ee:	5b                   	pop    %ebx
f01010ef:	5e                   	pop    %esi
f01010f0:	5d                   	pop    %ebp
f01010f1:	c3                   	ret    

f01010f2 <page_alloc>:
{
f01010f2:	55                   	push   %ebp
f01010f3:	89 e5                	mov    %esp,%ebp
f01010f5:	53                   	push   %ebx
f01010f6:	83 ec 14             	sub    $0x14,%esp
	if (page_free_list == NULL)
f01010f9:	8b 1d 40 02 23 f0    	mov    0xf0230240,%ebx
f01010ff:	85 db                	test   %ebx,%ebx
f0101101:	74 6f                	je     f0101172 <page_alloc+0x80>
	page_free_list = page_free_list->pp_link;
f0101103:	8b 03                	mov    (%ebx),%eax
f0101105:	a3 40 02 23 f0       	mov    %eax,0xf0230240
	result->pp_link = NULL;
f010110a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	return result;
f0101110:	89 d8                	mov    %ebx,%eax
	if (alloc_flags & ALLOC_ZERO)
f0101112:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101116:	74 5f                	je     f0101177 <page_alloc+0x85>
	return (pp - pages) << PGSHIFT;
f0101118:	2b 05 90 0e 23 f0    	sub    0xf0230e90,%eax
f010111e:	c1 f8 03             	sar    $0x3,%eax
f0101121:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101124:	89 c2                	mov    %eax,%edx
f0101126:	c1 ea 0c             	shr    $0xc,%edx
f0101129:	3b 15 88 0e 23 f0    	cmp    0xf0230e88,%edx
f010112f:	72 20                	jb     f0101151 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101131:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101135:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f010113c:	f0 
f010113d:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101144:	00 
f0101145:	c7 04 24 a5 7a 10 f0 	movl   $0xf0107aa5,(%esp)
f010114c:	e8 ef ee ff ff       	call   f0100040 <_panic>
		memset(page2kva(result), '\0', PGSIZE);
f0101151:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101158:	00 
f0101159:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101160:	00 
	return (void *)(pa + KERNBASE);
f0101161:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101166:	89 04 24             	mov    %eax,(%esp)
f0101169:	e8 19 4d 00 00       	call   f0105e87 <memset>
	return result;
f010116e:	89 d8                	mov    %ebx,%eax
f0101170:	eb 05                	jmp    f0101177 <page_alloc+0x85>
		return NULL;
f0101172:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101177:	83 c4 14             	add    $0x14,%esp
f010117a:	5b                   	pop    %ebx
f010117b:	5d                   	pop    %ebp
f010117c:	c3                   	ret    

f010117d <page_free>:
{
f010117d:	55                   	push   %ebp
f010117e:	89 e5                	mov    %esp,%ebp
f0101180:	83 ec 18             	sub    $0x18,%esp
f0101183:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref > 0)
f0101186:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010118b:	74 1c                	je     f01011a9 <page_free+0x2c>
		panic("page_free: page is still in use");
f010118d:	c7 44 24 08 4c 72 10 	movl   $0xf010724c,0x8(%esp)
f0101194:	f0 
f0101195:	c7 44 24 04 97 01 00 	movl   $0x197,0x4(%esp)
f010119c:	00 
f010119d:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01011a4:	e8 97 ee ff ff       	call   f0100040 <_panic>
	if (pp->pp_link != NULL)
f01011a9:	83 38 00             	cmpl   $0x0,(%eax)
f01011ac:	74 1c                	je     f01011ca <page_free+0x4d>
		panic("page_free: page is not NULL");
f01011ae:	c7 44 24 08 78 7b 10 	movl   $0xf0107b78,0x8(%esp)
f01011b5:	f0 
f01011b6:	c7 44 24 04 9b 01 00 	movl   $0x19b,0x4(%esp)
f01011bd:	00 
f01011be:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01011c5:	e8 76 ee ff ff       	call   f0100040 <_panic>
	pp->pp_link = page_free_list;
f01011ca:	8b 15 40 02 23 f0    	mov    0xf0230240,%edx
f01011d0:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f01011d2:	a3 40 02 23 f0       	mov    %eax,0xf0230240
}
f01011d7:	c9                   	leave  
f01011d8:	c3                   	ret    

f01011d9 <page_decref>:
{
f01011d9:	55                   	push   %ebp
f01011da:	89 e5                	mov    %esp,%ebp
f01011dc:	83 ec 18             	sub    $0x18,%esp
f01011df:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01011e2:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f01011e6:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01011e9:	66 89 50 04          	mov    %dx,0x4(%eax)
f01011ed:	66 85 d2             	test   %dx,%dx
f01011f0:	75 08                	jne    f01011fa <page_decref+0x21>
		page_free(pp);
f01011f2:	89 04 24             	mov    %eax,(%esp)
f01011f5:	e8 83 ff ff ff       	call   f010117d <page_free>
}
f01011fa:	c9                   	leave  
f01011fb:	c3                   	ret    

f01011fc <pgdir_walk>:
{
f01011fc:	55                   	push   %ebp
f01011fd:	89 e5                	mov    %esp,%ebp
f01011ff:	56                   	push   %esi
f0101200:	53                   	push   %ebx
f0101201:	83 ec 10             	sub    $0x10,%esp
f0101204:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	size_t IndexOfPageDir = PDX(va);
f0101207:	89 de                	mov    %ebx,%esi
f0101209:	c1 ee 16             	shr    $0x16,%esi
	pde_t* PDEntry = &pgdir[IndexOfPageDir];
f010120c:	c1 e6 02             	shl    $0x2,%esi
f010120f:	03 75 08             	add    0x8(%ebp),%esi
	if(!(*PDEntry & PTE_P))
f0101212:	8b 06                	mov    (%esi),%eax
f0101214:	a8 01                	test   $0x1,%al
f0101216:	75 76                	jne    f010128e <pgdir_walk+0x92>
		if (!create)
f0101218:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010121c:	0f 84 b0 00 00 00    	je     f01012d2 <pgdir_walk+0xd6>
		struct PageInfo* newPageTable = page_alloc(ALLOC_ZERO);
f0101222:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101229:	e8 c4 fe ff ff       	call   f01010f2 <page_alloc>
		if(newPageTable == NULL)
f010122e:	85 c0                	test   %eax,%eax
f0101230:	0f 84 a3 00 00 00    	je     f01012d9 <pgdir_walk+0xdd>
	return (pp - pages) << PGSHIFT;
f0101236:	89 c2                	mov    %eax,%edx
f0101238:	2b 15 90 0e 23 f0    	sub    0xf0230e90,%edx
f010123e:	c1 fa 03             	sar    $0x3,%edx
f0101241:	c1 e2 0c             	shl    $0xc,%edx
		*PDEntry = page2pa(newPageTable) | PTE_P | PTE_W | PTE_U;
f0101244:	83 ca 07             	or     $0x7,%edx
f0101247:	89 16                	mov    %edx,(%esi)
		newPageTable->pp_ref++;
f0101249:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f010124e:	2b 05 90 0e 23 f0    	sub    0xf0230e90,%eax
f0101254:	c1 f8 03             	sar    $0x3,%eax
f0101257:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010125a:	89 c2                	mov    %eax,%edx
f010125c:	c1 ea 0c             	shr    $0xc,%edx
f010125f:	3b 15 88 0e 23 f0    	cmp    0xf0230e88,%edx
f0101265:	72 20                	jb     f0101287 <pgdir_walk+0x8b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101267:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010126b:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f0101272:	f0 
f0101273:	c7 44 24 04 d8 01 00 	movl   $0x1d8,0x4(%esp)
f010127a:	00 
f010127b:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101282:	e8 b9 ed ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101287:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010128c:	eb 37                	jmp    f01012c5 <pgdir_walk+0xc9>
		pTable = KADDR(PTE_ADDR(*PDEntry));
f010128e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101293:	89 c2                	mov    %eax,%edx
f0101295:	c1 ea 0c             	shr    $0xc,%edx
f0101298:	3b 15 88 0e 23 f0    	cmp    0xf0230e88,%edx
f010129e:	72 20                	jb     f01012c0 <pgdir_walk+0xc4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012a0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012a4:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f01012ab:	f0 
f01012ac:	c7 44 24 04 dc 01 00 	movl   $0x1dc,0x4(%esp)
f01012b3:	00 
f01012b4:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01012bb:	e8 80 ed ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01012c0:	2d 00 00 00 10       	sub    $0x10000000,%eax
	return &pTable[PTX(va)];
f01012c5:	c1 eb 0a             	shr    $0xa,%ebx
f01012c8:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f01012ce:	01 d8                	add    %ebx,%eax
f01012d0:	eb 0c                	jmp    f01012de <pgdir_walk+0xe2>
			return NULL;
f01012d2:	b8 00 00 00 00       	mov    $0x0,%eax
f01012d7:	eb 05                	jmp    f01012de <pgdir_walk+0xe2>
			return NULL;
f01012d9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012de:	83 c4 10             	add    $0x10,%esp
f01012e1:	5b                   	pop    %ebx
f01012e2:	5e                   	pop    %esi
f01012e3:	5d                   	pop    %ebp
f01012e4:	c3                   	ret    

f01012e5 <boot_map_region>:
{
f01012e5:	55                   	push   %ebp
f01012e6:	89 e5                	mov    %esp,%ebp
f01012e8:	57                   	push   %edi
f01012e9:	56                   	push   %esi
f01012ea:	53                   	push   %ebx
f01012eb:	83 ec 2c             	sub    $0x2c,%esp
f01012ee:	89 c7                	mov    %eax,%edi
f01012f0:	89 d6                	mov    %edx,%esi
f01012f2:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for (i = 0; i < size; i = i + PGSIZE)
f01012f5:	bb 00 00 00 00       	mov    $0x0,%ebx
		*pageTableEntry = (pa + i) | perm | PTE_P;
f01012fa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012fd:	83 c8 01             	or     $0x1,%eax
f0101300:	89 45 e0             	mov    %eax,-0x20(%ebp)
	for (i = 0; i < size; i = i + PGSIZE)
f0101303:	eb 2b                	jmp    f0101330 <boot_map_region+0x4b>
		pageTableEntry = pgdir_walk(pgdir, (void*)(va + i), 1);
f0101305:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010130c:	00 
f010130d:	8d 04 33             	lea    (%ebx,%esi,1),%eax
f0101310:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101314:	89 3c 24             	mov    %edi,(%esp)
f0101317:	e8 e0 fe ff ff       	call   f01011fc <pgdir_walk>
		if (pageTableEntry == NULL)
f010131c:	85 c0                	test   %eax,%eax
f010131e:	74 15                	je     f0101335 <boot_map_region+0x50>
f0101320:	89 da                	mov    %ebx,%edx
f0101322:	03 55 08             	add    0x8(%ebp),%edx
		*pageTableEntry = (pa + i) | perm | PTE_P;
f0101325:	0b 55 e0             	or     -0x20(%ebp),%edx
f0101328:	89 10                	mov    %edx,(%eax)
	for (i = 0; i < size; i = i + PGSIZE)
f010132a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101330:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101333:	72 d0                	jb     f0101305 <boot_map_region+0x20>
}
f0101335:	83 c4 2c             	add    $0x2c,%esp
f0101338:	5b                   	pop    %ebx
f0101339:	5e                   	pop    %esi
f010133a:	5f                   	pop    %edi
f010133b:	5d                   	pop    %ebp
f010133c:	c3                   	ret    

f010133d <page_lookup>:
{
f010133d:	55                   	push   %ebp
f010133e:	89 e5                	mov    %esp,%ebp
f0101340:	53                   	push   %ebx
f0101341:	83 ec 14             	sub    $0x14,%esp
f0101344:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t* pageTableEntry = pgdir_walk(pgdir, va, 0);
f0101347:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010134e:	00 
f010134f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101352:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101356:	8b 45 08             	mov    0x8(%ebp),%eax
f0101359:	89 04 24             	mov    %eax,(%esp)
f010135c:	e8 9b fe ff ff       	call   f01011fc <pgdir_walk>
	if (pageTableEntry == NULL)
f0101361:	85 c0                	test   %eax,%eax
f0101363:	74 34                	je     f0101399 <page_lookup+0x5c>
	if(pte_store)
f0101365:	85 db                	test   %ebx,%ebx
f0101367:	74 37                	je     f01013a0 <page_lookup+0x63>
		*pte_store = pageTableEntry;
f0101369:	89 03                	mov    %eax,(%ebx)
f010136b:	90                   	nop
f010136c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101370:	eb 2e                	jmp    f01013a0 <page_lookup+0x63>
		panic("pa2page called with invalid pa");
f0101372:	c7 44 24 08 6c 72 10 	movl   $0xf010726c,0x8(%esp)
f0101379:	f0 
f010137a:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0101381:	00 
f0101382:	c7 04 24 a5 7a 10 f0 	movl   $0xf0107aa5,(%esp)
f0101389:	e8 b2 ec ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f010138e:	8b 15 90 0e 23 f0    	mov    0xf0230e90,%edx
f0101394:	8d 04 c2             	lea    (%edx,%eax,8),%eax
		return pa2page(PTE_ADDR(*pageTableEntry));
f0101397:	eb 16                	jmp    f01013af <page_lookup+0x72>
		return NULL;
f0101399:	b8 00 00 00 00       	mov    $0x0,%eax
f010139e:	eb 0f                	jmp    f01013af <page_lookup+0x72>
		return pa2page(PTE_ADDR(*pageTableEntry));
f01013a0:	8b 00                	mov    (%eax),%eax
	if (PGNUM(pa) >= npages)
f01013a2:	c1 e8 0c             	shr    $0xc,%eax
f01013a5:	3b 05 88 0e 23 f0    	cmp    0xf0230e88,%eax
f01013ab:	72 e1                	jb     f010138e <page_lookup+0x51>
f01013ad:	eb c3                	jmp    f0101372 <page_lookup+0x35>
}
f01013af:	83 c4 14             	add    $0x14,%esp
f01013b2:	5b                   	pop    %ebx
f01013b3:	5d                   	pop    %ebp
f01013b4:	c3                   	ret    

f01013b5 <tlb_invalidate>:
{
f01013b5:	55                   	push   %ebp
f01013b6:	89 e5                	mov    %esp,%ebp
f01013b8:	83 ec 08             	sub    $0x8,%esp
	if (!curenv || curenv->env_pgdir == pgdir)
f01013bb:	e8 19 51 00 00       	call   f01064d9 <cpunum>
f01013c0:	6b c0 74             	imul   $0x74,%eax,%eax
f01013c3:	83 b8 28 10 23 f0 00 	cmpl   $0x0,-0xfdcefd8(%eax)
f01013ca:	74 16                	je     f01013e2 <tlb_invalidate+0x2d>
f01013cc:	e8 08 51 00 00       	call   f01064d9 <cpunum>
f01013d1:	6b c0 74             	imul   $0x74,%eax,%eax
f01013d4:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f01013da:	8b 55 08             	mov    0x8(%ebp),%edx
f01013dd:	39 50 60             	cmp    %edx,0x60(%eax)
f01013e0:	75 06                	jne    f01013e8 <tlb_invalidate+0x33>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01013e2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013e5:	0f 01 38             	invlpg (%eax)
}
f01013e8:	c9                   	leave  
f01013e9:	c3                   	ret    

f01013ea <page_remove>:
{
f01013ea:	55                   	push   %ebp
f01013eb:	89 e5                	mov    %esp,%ebp
f01013ed:	56                   	push   %esi
f01013ee:	53                   	push   %ebx
f01013ef:	83 ec 20             	sub    $0x20,%esp
f01013f2:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01013f5:	8b 75 0c             	mov    0xc(%ebp),%esi
	struct PageInfo* page = page_lookup(pgdir, va, &pageTableEntry);
f01013f8:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01013fb:	89 44 24 08          	mov    %eax,0x8(%esp)
f01013ff:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101403:	89 1c 24             	mov    %ebx,(%esp)
f0101406:	e8 32 ff ff ff       	call   f010133d <page_lookup>
	if (page == NULL)
f010140b:	85 c0                	test   %eax,%eax
f010140d:	74 1d                	je     f010142c <page_remove+0x42>
	page_decref(page);
f010140f:	89 04 24             	mov    %eax,(%esp)
f0101412:	e8 c2 fd ff ff       	call   f01011d9 <page_decref>
	*pageTableEntry = 0;
f0101417:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010141a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f0101420:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101424:	89 1c 24             	mov    %ebx,(%esp)
f0101427:	e8 89 ff ff ff       	call   f01013b5 <tlb_invalidate>
}
f010142c:	83 c4 20             	add    $0x20,%esp
f010142f:	5b                   	pop    %ebx
f0101430:	5e                   	pop    %esi
f0101431:	5d                   	pop    %ebp
f0101432:	c3                   	ret    

f0101433 <page_insert>:
{
f0101433:	55                   	push   %ebp
f0101434:	89 e5                	mov    %esp,%ebp
f0101436:	57                   	push   %edi
f0101437:	56                   	push   %esi
f0101438:	53                   	push   %ebx
f0101439:	83 ec 1c             	sub    $0x1c,%esp
f010143c:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t* pageTableEntry = pgdir_walk(pgdir, va, 1);
f010143f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101446:	00 
f0101447:	8b 45 10             	mov    0x10(%ebp),%eax
f010144a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010144e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101451:	89 04 24             	mov    %eax,(%esp)
f0101454:	e8 a3 fd ff ff       	call   f01011fc <pgdir_walk>
f0101459:	89 c3                	mov    %eax,%ebx
	if (pageTableEntry == NULL)
f010145b:	85 c0                	test   %eax,%eax
f010145d:	74 68                	je     f01014c7 <page_insert+0x94>
	return (pp - pages) << PGSHIFT;
f010145f:	89 f7                	mov    %esi,%edi
f0101461:	2b 3d 90 0e 23 f0    	sub    0xf0230e90,%edi
f0101467:	c1 ff 03             	sar    $0x3,%edi
f010146a:	c1 e7 0c             	shl    $0xc,%edi
	if(*pageTableEntry & PTE_P)
f010146d:	8b 00                	mov    (%eax),%eax
f010146f:	a8 01                	test   $0x1,%al
f0101471:	74 3e                	je     f01014b1 <page_insert+0x7e>
		if(PTE_ADDR(*pageTableEntry) == pagePhysAddr)
f0101473:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101478:	39 f8                	cmp    %edi,%eax
f010147a:	75 11                	jne    f010148d <page_insert+0x5a>
			*pageTableEntry = pagePhysAddr | PTE_P | perm;
f010147c:	8b 55 14             	mov    0x14(%ebp),%edx
f010147f:	83 ca 01             	or     $0x1,%edx
f0101482:	09 d0                	or     %edx,%eax
f0101484:	89 03                	mov    %eax,(%ebx)
			return 0;
f0101486:	b8 00 00 00 00       	mov    $0x0,%eax
f010148b:	eb 3f                	jmp    f01014cc <page_insert+0x99>
			tlb_invalidate(pgdir, va);
f010148d:	8b 45 10             	mov    0x10(%ebp),%eax
f0101490:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101494:	8b 45 08             	mov    0x8(%ebp),%eax
f0101497:	89 04 24             	mov    %eax,(%esp)
f010149a:	e8 16 ff ff ff       	call   f01013b5 <tlb_invalidate>
			page_remove(pgdir, va);
f010149f:	8b 45 10             	mov    0x10(%ebp),%eax
f01014a2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a9:	89 04 24             	mov    %eax,(%esp)
f01014ac:	e8 39 ff ff ff       	call   f01013ea <page_remove>
	pp->pp_ref++;
f01014b1:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	*pageTableEntry = pagePhysAddr | perm | PTE_P;
f01014b6:	8b 45 14             	mov    0x14(%ebp),%eax
f01014b9:	83 c8 01             	or     $0x1,%eax
f01014bc:	09 c7                	or     %eax,%edi
f01014be:	89 3b                	mov    %edi,(%ebx)
	return 0;
f01014c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01014c5:	eb 05                	jmp    f01014cc <page_insert+0x99>
		return -E_NO_MEM;
f01014c7:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f01014cc:	83 c4 1c             	add    $0x1c,%esp
f01014cf:	5b                   	pop    %ebx
f01014d0:	5e                   	pop    %esi
f01014d1:	5f                   	pop    %edi
f01014d2:	5d                   	pop    %ebp
f01014d3:	c3                   	ret    

f01014d4 <mmio_map_region>:
{
f01014d4:	55                   	push   %ebp
f01014d5:	89 e5                	mov    %esp,%ebp
f01014d7:	53                   	push   %ebx
f01014d8:	83 ec 14             	sub    $0x14,%esp
	size_t n = ROUNDUP(size, PGSIZE);
f01014db:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014de:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f01014e4:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	if (base + n > MMIOLIM)
f01014ea:	8b 15 00 13 12 f0    	mov    0xf0121300,%edx
f01014f0:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f01014f3:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f01014f8:	76 1c                	jbe    f0101516 <mmio_map_region+0x42>
		panic("mapped region past MMIOLIM");
f01014fa:	c7 44 24 08 94 7b 10 	movl   $0xf0107b94,0x8(%esp)
f0101501:	f0 
f0101502:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f0101509:	00 
f010150a:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101511:	e8 2a eb ff ff       	call   f0100040 <_panic>
	boot_map_region(kern_pgdir, base, n, pa, PTE_P | PTE_W | PTE_PCD | PTE_PWT);
f0101516:	c7 44 24 04 1b 00 00 	movl   $0x1b,0x4(%esp)
f010151d:	00 
f010151e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101521:	89 04 24             	mov    %eax,(%esp)
f0101524:	89 d9                	mov    %ebx,%ecx
f0101526:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f010152b:	e8 b5 fd ff ff       	call   f01012e5 <boot_map_region>
	void * value = (void *)base;
f0101530:	a1 00 13 12 f0       	mov    0xf0121300,%eax
	base = base + n;
f0101535:	01 c3                	add    %eax,%ebx
f0101537:	89 1d 00 13 12 f0    	mov    %ebx,0xf0121300
}
f010153d:	83 c4 14             	add    $0x14,%esp
f0101540:	5b                   	pop    %ebx
f0101541:	5d                   	pop    %ebp
f0101542:	c3                   	ret    

f0101543 <mem_init>:
{
f0101543:	55                   	push   %ebp
f0101544:	89 e5                	mov    %esp,%ebp
f0101546:	57                   	push   %edi
f0101547:	56                   	push   %esi
f0101548:	53                   	push   %ebx
f0101549:	83 ec 4c             	sub    $0x4c,%esp
	basemem = nvram_read(NVRAM_BASELO);
f010154c:	b8 15 00 00 00       	mov    $0x15,%eax
f0101551:	e8 0b f6 ff ff       	call   f0100b61 <nvram_read>
f0101556:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101558:	b8 17 00 00 00       	mov    $0x17,%eax
f010155d:	e8 ff f5 ff ff       	call   f0100b61 <nvram_read>
f0101562:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101564:	b8 34 00 00 00       	mov    $0x34,%eax
f0101569:	e8 f3 f5 ff ff       	call   f0100b61 <nvram_read>
f010156e:	c1 e0 06             	shl    $0x6,%eax
f0101571:	89 c2                	mov    %eax,%edx
		totalmem = 16 * 1024 + ext16mem;
f0101573:	8d 80 00 40 00 00    	lea    0x4000(%eax),%eax
	if (ext16mem)
f0101579:	85 d2                	test   %edx,%edx
f010157b:	75 0b                	jne    f0101588 <mem_init+0x45>
		totalmem = 1 * 1024 + extmem;
f010157d:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101583:	85 f6                	test   %esi,%esi
f0101585:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f0101588:	89 c2                	mov    %eax,%edx
f010158a:	c1 ea 02             	shr    $0x2,%edx
f010158d:	89 15 88 0e 23 f0    	mov    %edx,0xf0230e88
	npages_basemem = basemem / (PGSIZE / 1024);
f0101593:	89 da                	mov    %ebx,%edx
f0101595:	c1 ea 02             	shr    $0x2,%edx
f0101598:	89 15 44 02 23 f0    	mov    %edx,0xf0230244
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010159e:	89 c2                	mov    %eax,%edx
f01015a0:	29 da                	sub    %ebx,%edx
f01015a2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01015a6:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01015aa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015ae:	c7 04 24 8c 72 10 f0 	movl   $0xf010728c,(%esp)
f01015b5:	e8 a9 29 00 00       	call   f0103f63 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01015ba:	b8 00 10 00 00       	mov    $0x1000,%eax
f01015bf:	e8 4c f5 ff ff       	call   f0100b10 <boot_alloc>
f01015c4:	a3 8c 0e 23 f0       	mov    %eax,0xf0230e8c
	memset(kern_pgdir, 0, PGSIZE);
f01015c9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01015d0:	00 
f01015d1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01015d8:	00 
f01015d9:	89 04 24             	mov    %eax,(%esp)
f01015dc:	e8 a6 48 00 00       	call   f0105e87 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01015e1:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01015e6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01015eb:	77 20                	ja     f010160d <mem_init+0xca>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01015ed:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01015f1:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f01015f8:	f0 
f01015f9:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
f0101600:	00 
f0101601:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101608:	e8 33 ea ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010160d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101613:	83 ca 05             	or     $0x5,%edx
f0101616:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f010161c:	a1 88 0e 23 f0       	mov    0xf0230e88,%eax
f0101621:	c1 e0 03             	shl    $0x3,%eax
f0101624:	e8 e7 f4 ff ff       	call   f0100b10 <boot_alloc>
f0101629:	a3 90 0e 23 f0       	mov    %eax,0xf0230e90
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010162e:	8b 0d 88 0e 23 f0    	mov    0xf0230e88,%ecx
f0101634:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010163b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010163f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101646:	00 
f0101647:	89 04 24             	mov    %eax,(%esp)
f010164a:	e8 38 48 00 00       	call   f0105e87 <memset>
	envs = (struct Env *)boot_alloc(NENV * sizeof(struct Env));
f010164f:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101654:	e8 b7 f4 ff ff       	call   f0100b10 <boot_alloc>
f0101659:	a3 48 02 23 f0       	mov    %eax,0xf0230248
	memset(envs, 0, NENV * sizeof(struct Env));
f010165e:	c7 44 24 08 00 f0 01 	movl   $0x1f000,0x8(%esp)
f0101665:	00 
f0101666:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010166d:	00 
f010166e:	89 04 24             	mov    %eax,(%esp)
f0101671:	e8 11 48 00 00       	call   f0105e87 <memset>
	page_init();
f0101676:	e8 69 f9 ff ff       	call   f0100fe4 <page_init>
	check_page_free_list(1);
f010167b:	b8 01 00 00 00       	mov    $0x1,%eax
f0101680:	e8 bb f5 ff ff       	call   f0100c40 <check_page_free_list>
	if (!pages)
f0101685:	83 3d 90 0e 23 f0 00 	cmpl   $0x0,0xf0230e90
f010168c:	75 1c                	jne    f01016aa <mem_init+0x167>
		panic("'pages' is a null pointer!");
f010168e:	c7 44 24 08 af 7b 10 	movl   $0xf0107baf,0x8(%esp)
f0101695:	f0 
f0101696:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f010169d:	00 
f010169e:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01016a5:	e8 96 e9 ff ff       	call   f0100040 <_panic>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01016aa:	a1 40 02 23 f0       	mov    0xf0230240,%eax
f01016af:	bb 00 00 00 00       	mov    $0x0,%ebx
f01016b4:	eb 05                	jmp    f01016bb <mem_init+0x178>
		++nfree;
f01016b6:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01016b9:	8b 00                	mov    (%eax),%eax
f01016bb:	85 c0                	test   %eax,%eax
f01016bd:	75 f7                	jne    f01016b6 <mem_init+0x173>
	assert((pp0 = page_alloc(0)));
f01016bf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016c6:	e8 27 fa ff ff       	call   f01010f2 <page_alloc>
f01016cb:	89 c7                	mov    %eax,%edi
f01016cd:	85 c0                	test   %eax,%eax
f01016cf:	75 24                	jne    f01016f5 <mem_init+0x1b2>
f01016d1:	c7 44 24 0c ca 7b 10 	movl   $0xf0107bca,0xc(%esp)
f01016d8:	f0 
f01016d9:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01016e0:	f0 
f01016e1:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f01016e8:	00 
f01016e9:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01016f0:	e8 4b e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01016f5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016fc:	e8 f1 f9 ff ff       	call   f01010f2 <page_alloc>
f0101701:	89 c6                	mov    %eax,%esi
f0101703:	85 c0                	test   %eax,%eax
f0101705:	75 24                	jne    f010172b <mem_init+0x1e8>
f0101707:	c7 44 24 0c e0 7b 10 	movl   $0xf0107be0,0xc(%esp)
f010170e:	f0 
f010170f:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101716:	f0 
f0101717:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f010171e:	00 
f010171f:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101726:	e8 15 e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010172b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101732:	e8 bb f9 ff ff       	call   f01010f2 <page_alloc>
f0101737:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010173a:	85 c0                	test   %eax,%eax
f010173c:	75 24                	jne    f0101762 <mem_init+0x21f>
f010173e:	c7 44 24 0c f6 7b 10 	movl   $0xf0107bf6,0xc(%esp)
f0101745:	f0 
f0101746:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010174d:	f0 
f010174e:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0101755:	00 
f0101756:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010175d:	e8 de e8 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f0101762:	39 f7                	cmp    %esi,%edi
f0101764:	75 24                	jne    f010178a <mem_init+0x247>
f0101766:	c7 44 24 0c 0c 7c 10 	movl   $0xf0107c0c,0xc(%esp)
f010176d:	f0 
f010176e:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101775:	f0 
f0101776:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f010177d:	00 
f010177e:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101785:	e8 b6 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010178a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010178d:	39 c6                	cmp    %eax,%esi
f010178f:	74 04                	je     f0101795 <mem_init+0x252>
f0101791:	39 c7                	cmp    %eax,%edi
f0101793:	75 24                	jne    f01017b9 <mem_init+0x276>
f0101795:	c7 44 24 0c c8 72 10 	movl   $0xf01072c8,0xc(%esp)
f010179c:	f0 
f010179d:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01017a4:	f0 
f01017a5:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f01017ac:	00 
f01017ad:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01017b4:	e8 87 e8 ff ff       	call   f0100040 <_panic>
	return (pp - pages) << PGSHIFT;
f01017b9:	8b 15 90 0e 23 f0    	mov    0xf0230e90,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01017bf:	a1 88 0e 23 f0       	mov    0xf0230e88,%eax
f01017c4:	c1 e0 0c             	shl    $0xc,%eax
f01017c7:	89 f9                	mov    %edi,%ecx
f01017c9:	29 d1                	sub    %edx,%ecx
f01017cb:	c1 f9 03             	sar    $0x3,%ecx
f01017ce:	c1 e1 0c             	shl    $0xc,%ecx
f01017d1:	39 c1                	cmp    %eax,%ecx
f01017d3:	72 24                	jb     f01017f9 <mem_init+0x2b6>
f01017d5:	c7 44 24 0c 1e 7c 10 	movl   $0xf0107c1e,0xc(%esp)
f01017dc:	f0 
f01017dd:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01017e4:	f0 
f01017e5:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f01017ec:	00 
f01017ed:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01017f4:	e8 47 e8 ff ff       	call   f0100040 <_panic>
f01017f9:	89 f1                	mov    %esi,%ecx
f01017fb:	29 d1                	sub    %edx,%ecx
f01017fd:	c1 f9 03             	sar    $0x3,%ecx
f0101800:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101803:	39 c8                	cmp    %ecx,%eax
f0101805:	77 24                	ja     f010182b <mem_init+0x2e8>
f0101807:	c7 44 24 0c 3b 7c 10 	movl   $0xf0107c3b,0xc(%esp)
f010180e:	f0 
f010180f:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101816:	f0 
f0101817:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f010181e:	00 
f010181f:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101826:	e8 15 e8 ff ff       	call   f0100040 <_panic>
f010182b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010182e:	29 d1                	sub    %edx,%ecx
f0101830:	89 ca                	mov    %ecx,%edx
f0101832:	c1 fa 03             	sar    $0x3,%edx
f0101835:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101838:	39 d0                	cmp    %edx,%eax
f010183a:	77 24                	ja     f0101860 <mem_init+0x31d>
f010183c:	c7 44 24 0c 58 7c 10 	movl   $0xf0107c58,0xc(%esp)
f0101843:	f0 
f0101844:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010184b:	f0 
f010184c:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0101853:	00 
f0101854:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010185b:	e8 e0 e7 ff ff       	call   f0100040 <_panic>
	fl = page_free_list;
f0101860:	a1 40 02 23 f0       	mov    0xf0230240,%eax
f0101865:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101868:	c7 05 40 02 23 f0 00 	movl   $0x0,0xf0230240
f010186f:	00 00 00 
	assert(!page_alloc(0));
f0101872:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101879:	e8 74 f8 ff ff       	call   f01010f2 <page_alloc>
f010187e:	85 c0                	test   %eax,%eax
f0101880:	74 24                	je     f01018a6 <mem_init+0x363>
f0101882:	c7 44 24 0c 75 7c 10 	movl   $0xf0107c75,0xc(%esp)
f0101889:	f0 
f010188a:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101891:	f0 
f0101892:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0101899:	00 
f010189a:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01018a1:	e8 9a e7 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f01018a6:	89 3c 24             	mov    %edi,(%esp)
f01018a9:	e8 cf f8 ff ff       	call   f010117d <page_free>
	page_free(pp1);
f01018ae:	89 34 24             	mov    %esi,(%esp)
f01018b1:	e8 c7 f8 ff ff       	call   f010117d <page_free>
	page_free(pp2);
f01018b6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018b9:	89 04 24             	mov    %eax,(%esp)
f01018bc:	e8 bc f8 ff ff       	call   f010117d <page_free>
	assert((pp0 = page_alloc(0)));
f01018c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018c8:	e8 25 f8 ff ff       	call   f01010f2 <page_alloc>
f01018cd:	89 c6                	mov    %eax,%esi
f01018cf:	85 c0                	test   %eax,%eax
f01018d1:	75 24                	jne    f01018f7 <mem_init+0x3b4>
f01018d3:	c7 44 24 0c ca 7b 10 	movl   $0xf0107bca,0xc(%esp)
f01018da:	f0 
f01018db:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01018e2:	f0 
f01018e3:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f01018ea:	00 
f01018eb:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01018f2:	e8 49 e7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01018f7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018fe:	e8 ef f7 ff ff       	call   f01010f2 <page_alloc>
f0101903:	89 c7                	mov    %eax,%edi
f0101905:	85 c0                	test   %eax,%eax
f0101907:	75 24                	jne    f010192d <mem_init+0x3ea>
f0101909:	c7 44 24 0c e0 7b 10 	movl   $0xf0107be0,0xc(%esp)
f0101910:	f0 
f0101911:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101918:	f0 
f0101919:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0101920:	00 
f0101921:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101928:	e8 13 e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010192d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101934:	e8 b9 f7 ff ff       	call   f01010f2 <page_alloc>
f0101939:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010193c:	85 c0                	test   %eax,%eax
f010193e:	75 24                	jne    f0101964 <mem_init+0x421>
f0101940:	c7 44 24 0c f6 7b 10 	movl   $0xf0107bf6,0xc(%esp)
f0101947:	f0 
f0101948:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010194f:	f0 
f0101950:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0101957:	00 
f0101958:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010195f:	e8 dc e6 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f0101964:	39 fe                	cmp    %edi,%esi
f0101966:	75 24                	jne    f010198c <mem_init+0x449>
f0101968:	c7 44 24 0c 0c 7c 10 	movl   $0xf0107c0c,0xc(%esp)
f010196f:	f0 
f0101970:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101977:	f0 
f0101978:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f010197f:	00 
f0101980:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101987:	e8 b4 e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010198c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010198f:	39 c7                	cmp    %eax,%edi
f0101991:	74 04                	je     f0101997 <mem_init+0x454>
f0101993:	39 c6                	cmp    %eax,%esi
f0101995:	75 24                	jne    f01019bb <mem_init+0x478>
f0101997:	c7 44 24 0c c8 72 10 	movl   $0xf01072c8,0xc(%esp)
f010199e:	f0 
f010199f:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01019a6:	f0 
f01019a7:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f01019ae:	00 
f01019af:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01019b6:	e8 85 e6 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01019bb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019c2:	e8 2b f7 ff ff       	call   f01010f2 <page_alloc>
f01019c7:	85 c0                	test   %eax,%eax
f01019c9:	74 24                	je     f01019ef <mem_init+0x4ac>
f01019cb:	c7 44 24 0c 75 7c 10 	movl   $0xf0107c75,0xc(%esp)
f01019d2:	f0 
f01019d3:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01019da:	f0 
f01019db:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f01019e2:	00 
f01019e3:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01019ea:	e8 51 e6 ff ff       	call   f0100040 <_panic>
f01019ef:	89 f0                	mov    %esi,%eax
f01019f1:	2b 05 90 0e 23 f0    	sub    0xf0230e90,%eax
f01019f7:	c1 f8 03             	sar    $0x3,%eax
f01019fa:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01019fd:	89 c2                	mov    %eax,%edx
f01019ff:	c1 ea 0c             	shr    $0xc,%edx
f0101a02:	3b 15 88 0e 23 f0    	cmp    0xf0230e88,%edx
f0101a08:	72 20                	jb     f0101a2a <mem_init+0x4e7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a0a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101a0e:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f0101a15:	f0 
f0101a16:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101a1d:	00 
f0101a1e:	c7 04 24 a5 7a 10 f0 	movl   $0xf0107aa5,(%esp)
f0101a25:	e8 16 e6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
f0101a2a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101a31:	00 
f0101a32:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101a39:	00 
	return (void *)(pa + KERNBASE);
f0101a3a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a3f:	89 04 24             	mov    %eax,(%esp)
f0101a42:	e8 40 44 00 00       	call   f0105e87 <memset>
	page_free(pp0);
f0101a47:	89 34 24             	mov    %esi,(%esp)
f0101a4a:	e8 2e f7 ff ff       	call   f010117d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101a4f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101a56:	e8 97 f6 ff ff       	call   f01010f2 <page_alloc>
f0101a5b:	85 c0                	test   %eax,%eax
f0101a5d:	75 24                	jne    f0101a83 <mem_init+0x540>
f0101a5f:	c7 44 24 0c 84 7c 10 	movl   $0xf0107c84,0xc(%esp)
f0101a66:	f0 
f0101a67:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101a6e:	f0 
f0101a6f:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f0101a76:	00 
f0101a77:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101a7e:	e8 bd e5 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101a83:	39 c6                	cmp    %eax,%esi
f0101a85:	74 24                	je     f0101aab <mem_init+0x568>
f0101a87:	c7 44 24 0c a2 7c 10 	movl   $0xf0107ca2,0xc(%esp)
f0101a8e:	f0 
f0101a8f:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101a96:	f0 
f0101a97:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0101a9e:	00 
f0101a9f:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101aa6:	e8 95 e5 ff ff       	call   f0100040 <_panic>
	return (pp - pages) << PGSHIFT;
f0101aab:	89 f0                	mov    %esi,%eax
f0101aad:	2b 05 90 0e 23 f0    	sub    0xf0230e90,%eax
f0101ab3:	c1 f8 03             	sar    $0x3,%eax
f0101ab6:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101ab9:	89 c2                	mov    %eax,%edx
f0101abb:	c1 ea 0c             	shr    $0xc,%edx
f0101abe:	3b 15 88 0e 23 f0    	cmp    0xf0230e88,%edx
f0101ac4:	72 20                	jb     f0101ae6 <mem_init+0x5a3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ac6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101aca:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f0101ad1:	f0 
f0101ad2:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101ad9:	00 
f0101ada:	c7 04 24 a5 7a 10 f0 	movl   $0xf0107aa5,(%esp)
f0101ae1:	e8 5a e5 ff ff       	call   f0100040 <_panic>
f0101ae6:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101aec:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
		assert(c[i] == 0);
f0101af2:	80 38 00             	cmpb   $0x0,(%eax)
f0101af5:	74 24                	je     f0101b1b <mem_init+0x5d8>
f0101af7:	c7 44 24 0c b2 7c 10 	movl   $0xf0107cb2,0xc(%esp)
f0101afe:	f0 
f0101aff:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101b06:	f0 
f0101b07:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f0101b0e:	00 
f0101b0f:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101b16:	e8 25 e5 ff ff       	call   f0100040 <_panic>
f0101b1b:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101b1e:	39 d0                	cmp    %edx,%eax
f0101b20:	75 d0                	jne    f0101af2 <mem_init+0x5af>
	page_free_list = fl;
f0101b22:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b25:	a3 40 02 23 f0       	mov    %eax,0xf0230240
	page_free(pp0);
f0101b2a:	89 34 24             	mov    %esi,(%esp)
f0101b2d:	e8 4b f6 ff ff       	call   f010117d <page_free>
	page_free(pp1);
f0101b32:	89 3c 24             	mov    %edi,(%esp)
f0101b35:	e8 43 f6 ff ff       	call   f010117d <page_free>
	page_free(pp2);
f0101b3a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b3d:	89 04 24             	mov    %eax,(%esp)
f0101b40:	e8 38 f6 ff ff       	call   f010117d <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101b45:	a1 40 02 23 f0       	mov    0xf0230240,%eax
f0101b4a:	eb 05                	jmp    f0101b51 <mem_init+0x60e>
		--nfree;
f0101b4c:	83 eb 01             	sub    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101b4f:	8b 00                	mov    (%eax),%eax
f0101b51:	85 c0                	test   %eax,%eax
f0101b53:	75 f7                	jne    f0101b4c <mem_init+0x609>
	assert(nfree == 0);
f0101b55:	85 db                	test   %ebx,%ebx
f0101b57:	74 24                	je     f0101b7d <mem_init+0x63a>
f0101b59:	c7 44 24 0c bc 7c 10 	movl   $0xf0107cbc,0xc(%esp)
f0101b60:	f0 
f0101b61:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101b68:	f0 
f0101b69:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f0101b70:	00 
f0101b71:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101b78:	e8 c3 e4 ff ff       	call   f0100040 <_panic>
	cprintf("check_page_alloc() succeeded!\n");
f0101b7d:	c7 04 24 e8 72 10 f0 	movl   $0xf01072e8,(%esp)
f0101b84:	e8 da 23 00 00       	call   f0103f63 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b89:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b90:	e8 5d f5 ff ff       	call   f01010f2 <page_alloc>
f0101b95:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b98:	85 c0                	test   %eax,%eax
f0101b9a:	75 24                	jne    f0101bc0 <mem_init+0x67d>
f0101b9c:	c7 44 24 0c ca 7b 10 	movl   $0xf0107bca,0xc(%esp)
f0101ba3:	f0 
f0101ba4:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101bab:	f0 
f0101bac:	c7 44 24 04 df 03 00 	movl   $0x3df,0x4(%esp)
f0101bb3:	00 
f0101bb4:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101bbb:	e8 80 e4 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101bc0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bc7:	e8 26 f5 ff ff       	call   f01010f2 <page_alloc>
f0101bcc:	89 c3                	mov    %eax,%ebx
f0101bce:	85 c0                	test   %eax,%eax
f0101bd0:	75 24                	jne    f0101bf6 <mem_init+0x6b3>
f0101bd2:	c7 44 24 0c e0 7b 10 	movl   $0xf0107be0,0xc(%esp)
f0101bd9:	f0 
f0101bda:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101be1:	f0 
f0101be2:	c7 44 24 04 e0 03 00 	movl   $0x3e0,0x4(%esp)
f0101be9:	00 
f0101bea:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101bf1:	e8 4a e4 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101bf6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bfd:	e8 f0 f4 ff ff       	call   f01010f2 <page_alloc>
f0101c02:	89 c6                	mov    %eax,%esi
f0101c04:	85 c0                	test   %eax,%eax
f0101c06:	75 24                	jne    f0101c2c <mem_init+0x6e9>
f0101c08:	c7 44 24 0c f6 7b 10 	movl   $0xf0107bf6,0xc(%esp)
f0101c0f:	f0 
f0101c10:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101c17:	f0 
f0101c18:	c7 44 24 04 e1 03 00 	movl   $0x3e1,0x4(%esp)
f0101c1f:	00 
f0101c20:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101c27:	e8 14 e4 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101c2c:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101c2f:	75 24                	jne    f0101c55 <mem_init+0x712>
f0101c31:	c7 44 24 0c 0c 7c 10 	movl   $0xf0107c0c,0xc(%esp)
f0101c38:	f0 
f0101c39:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101c40:	f0 
f0101c41:	c7 44 24 04 e4 03 00 	movl   $0x3e4,0x4(%esp)
f0101c48:	00 
f0101c49:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101c50:	e8 eb e3 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101c55:	39 c3                	cmp    %eax,%ebx
f0101c57:	74 05                	je     f0101c5e <mem_init+0x71b>
f0101c59:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101c5c:	75 24                	jne    f0101c82 <mem_init+0x73f>
f0101c5e:	c7 44 24 0c c8 72 10 	movl   $0xf01072c8,0xc(%esp)
f0101c65:	f0 
f0101c66:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101c6d:	f0 
f0101c6e:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f0101c75:	00 
f0101c76:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101c7d:	e8 be e3 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101c82:	a1 40 02 23 f0       	mov    0xf0230240,%eax
f0101c87:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101c8a:	c7 05 40 02 23 f0 00 	movl   $0x0,0xf0230240
f0101c91:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101c94:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c9b:	e8 52 f4 ff ff       	call   f01010f2 <page_alloc>
f0101ca0:	85 c0                	test   %eax,%eax
f0101ca2:	74 24                	je     f0101cc8 <mem_init+0x785>
f0101ca4:	c7 44 24 0c 75 7c 10 	movl   $0xf0107c75,0xc(%esp)
f0101cab:	f0 
f0101cac:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101cb3:	f0 
f0101cb4:	c7 44 24 04 ec 03 00 	movl   $0x3ec,0x4(%esp)
f0101cbb:	00 
f0101cbc:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101cc3:	e8 78 e3 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101cc8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101ccb:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101ccf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101cd6:	00 
f0101cd7:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0101cdc:	89 04 24             	mov    %eax,(%esp)
f0101cdf:	e8 59 f6 ff ff       	call   f010133d <page_lookup>
f0101ce4:	85 c0                	test   %eax,%eax
f0101ce6:	74 24                	je     f0101d0c <mem_init+0x7c9>
f0101ce8:	c7 44 24 0c 08 73 10 	movl   $0xf0107308,0xc(%esp)
f0101cef:	f0 
f0101cf0:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101cf7:	f0 
f0101cf8:	c7 44 24 04 ef 03 00 	movl   $0x3ef,0x4(%esp)
f0101cff:	00 
f0101d00:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101d07:	e8 34 e3 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101d0c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d13:	00 
f0101d14:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d1b:	00 
f0101d1c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d20:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0101d25:	89 04 24             	mov    %eax,(%esp)
f0101d28:	e8 06 f7 ff ff       	call   f0101433 <page_insert>
f0101d2d:	85 c0                	test   %eax,%eax
f0101d2f:	78 24                	js     f0101d55 <mem_init+0x812>
f0101d31:	c7 44 24 0c 40 73 10 	movl   $0xf0107340,0xc(%esp)
f0101d38:	f0 
f0101d39:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101d40:	f0 
f0101d41:	c7 44 24 04 f2 03 00 	movl   $0x3f2,0x4(%esp)
f0101d48:	00 
f0101d49:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101d50:	e8 eb e2 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101d55:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d58:	89 04 24             	mov    %eax,(%esp)
f0101d5b:	e8 1d f4 ff ff       	call   f010117d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101d60:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d67:	00 
f0101d68:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d6f:	00 
f0101d70:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d74:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0101d79:	89 04 24             	mov    %eax,(%esp)
f0101d7c:	e8 b2 f6 ff ff       	call   f0101433 <page_insert>
f0101d81:	85 c0                	test   %eax,%eax
f0101d83:	74 24                	je     f0101da9 <mem_init+0x866>
f0101d85:	c7 44 24 0c 70 73 10 	movl   $0xf0107370,0xc(%esp)
f0101d8c:	f0 
f0101d8d:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101d94:	f0 
f0101d95:	c7 44 24 04 f6 03 00 	movl   $0x3f6,0x4(%esp)
f0101d9c:	00 
f0101d9d:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101da4:	e8 97 e2 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101da9:	8b 3d 8c 0e 23 f0    	mov    0xf0230e8c,%edi
	return (pp - pages) << PGSHIFT;
f0101daf:	a1 90 0e 23 f0       	mov    0xf0230e90,%eax
f0101db4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101db7:	8b 17                	mov    (%edi),%edx
f0101db9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101dbf:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101dc2:	29 c1                	sub    %eax,%ecx
f0101dc4:	89 c8                	mov    %ecx,%eax
f0101dc6:	c1 f8 03             	sar    $0x3,%eax
f0101dc9:	c1 e0 0c             	shl    $0xc,%eax
f0101dcc:	39 c2                	cmp    %eax,%edx
f0101dce:	74 24                	je     f0101df4 <mem_init+0x8b1>
f0101dd0:	c7 44 24 0c a0 73 10 	movl   $0xf01073a0,0xc(%esp)
f0101dd7:	f0 
f0101dd8:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101ddf:	f0 
f0101de0:	c7 44 24 04 f7 03 00 	movl   $0x3f7,0x4(%esp)
f0101de7:	00 
f0101de8:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101def:	e8 4c e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101df4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101df9:	89 f8                	mov    %edi,%eax
f0101dfb:	e8 d1 ed ff ff       	call   f0100bd1 <check_va2pa>
f0101e00:	89 da                	mov    %ebx,%edx
f0101e02:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101e05:	c1 fa 03             	sar    $0x3,%edx
f0101e08:	c1 e2 0c             	shl    $0xc,%edx
f0101e0b:	39 d0                	cmp    %edx,%eax
f0101e0d:	74 24                	je     f0101e33 <mem_init+0x8f0>
f0101e0f:	c7 44 24 0c c8 73 10 	movl   $0xf01073c8,0xc(%esp)
f0101e16:	f0 
f0101e17:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101e1e:	f0 
f0101e1f:	c7 44 24 04 f8 03 00 	movl   $0x3f8,0x4(%esp)
f0101e26:	00 
f0101e27:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101e2e:	e8 0d e2 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101e33:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101e38:	74 24                	je     f0101e5e <mem_init+0x91b>
f0101e3a:	c7 44 24 0c c7 7c 10 	movl   $0xf0107cc7,0xc(%esp)
f0101e41:	f0 
f0101e42:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101e49:	f0 
f0101e4a:	c7 44 24 04 f9 03 00 	movl   $0x3f9,0x4(%esp)
f0101e51:	00 
f0101e52:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101e59:	e8 e2 e1 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101e5e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e61:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e66:	74 24                	je     f0101e8c <mem_init+0x949>
f0101e68:	c7 44 24 0c d8 7c 10 	movl   $0xf0107cd8,0xc(%esp)
f0101e6f:	f0 
f0101e70:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101e77:	f0 
f0101e78:	c7 44 24 04 fa 03 00 	movl   $0x3fa,0x4(%esp)
f0101e7f:	00 
f0101e80:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101e87:	e8 b4 e1 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e8c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e93:	00 
f0101e94:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e9b:	00 
f0101e9c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101ea0:	89 3c 24             	mov    %edi,(%esp)
f0101ea3:	e8 8b f5 ff ff       	call   f0101433 <page_insert>
f0101ea8:	85 c0                	test   %eax,%eax
f0101eaa:	74 24                	je     f0101ed0 <mem_init+0x98d>
f0101eac:	c7 44 24 0c f8 73 10 	movl   $0xf01073f8,0xc(%esp)
f0101eb3:	f0 
f0101eb4:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101ebb:	f0 
f0101ebc:	c7 44 24 04 fd 03 00 	movl   $0x3fd,0x4(%esp)
f0101ec3:	00 
f0101ec4:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101ecb:	e8 70 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ed0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ed5:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0101eda:	e8 f2 ec ff ff       	call   f0100bd1 <check_va2pa>
f0101edf:	89 f2                	mov    %esi,%edx
f0101ee1:	2b 15 90 0e 23 f0    	sub    0xf0230e90,%edx
f0101ee7:	c1 fa 03             	sar    $0x3,%edx
f0101eea:	c1 e2 0c             	shl    $0xc,%edx
f0101eed:	39 d0                	cmp    %edx,%eax
f0101eef:	74 24                	je     f0101f15 <mem_init+0x9d2>
f0101ef1:	c7 44 24 0c 34 74 10 	movl   $0xf0107434,0xc(%esp)
f0101ef8:	f0 
f0101ef9:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101f00:	f0 
f0101f01:	c7 44 24 04 fe 03 00 	movl   $0x3fe,0x4(%esp)
f0101f08:	00 
f0101f09:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101f10:	e8 2b e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101f15:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f1a:	74 24                	je     f0101f40 <mem_init+0x9fd>
f0101f1c:	c7 44 24 0c e9 7c 10 	movl   $0xf0107ce9,0xc(%esp)
f0101f23:	f0 
f0101f24:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101f2b:	f0 
f0101f2c:	c7 44 24 04 ff 03 00 	movl   $0x3ff,0x4(%esp)
f0101f33:	00 
f0101f34:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101f3b:	e8 00 e1 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f40:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f47:	e8 a6 f1 ff ff       	call   f01010f2 <page_alloc>
f0101f4c:	85 c0                	test   %eax,%eax
f0101f4e:	74 24                	je     f0101f74 <mem_init+0xa31>
f0101f50:	c7 44 24 0c 75 7c 10 	movl   $0xf0107c75,0xc(%esp)
f0101f57:	f0 
f0101f58:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101f5f:	f0 
f0101f60:	c7 44 24 04 02 04 00 	movl   $0x402,0x4(%esp)
f0101f67:	00 
f0101f68:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101f6f:	e8 cc e0 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f74:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f7b:	00 
f0101f7c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f83:	00 
f0101f84:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f88:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0101f8d:	89 04 24             	mov    %eax,(%esp)
f0101f90:	e8 9e f4 ff ff       	call   f0101433 <page_insert>
f0101f95:	85 c0                	test   %eax,%eax
f0101f97:	74 24                	je     f0101fbd <mem_init+0xa7a>
f0101f99:	c7 44 24 0c f8 73 10 	movl   $0xf01073f8,0xc(%esp)
f0101fa0:	f0 
f0101fa1:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101fa8:	f0 
f0101fa9:	c7 44 24 04 05 04 00 	movl   $0x405,0x4(%esp)
f0101fb0:	00 
f0101fb1:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101fb8:	e8 83 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101fbd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fc2:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0101fc7:	e8 05 ec ff ff       	call   f0100bd1 <check_va2pa>
f0101fcc:	89 f2                	mov    %esi,%edx
f0101fce:	2b 15 90 0e 23 f0    	sub    0xf0230e90,%edx
f0101fd4:	c1 fa 03             	sar    $0x3,%edx
f0101fd7:	c1 e2 0c             	shl    $0xc,%edx
f0101fda:	39 d0                	cmp    %edx,%eax
f0101fdc:	74 24                	je     f0102002 <mem_init+0xabf>
f0101fde:	c7 44 24 0c 34 74 10 	movl   $0xf0107434,0xc(%esp)
f0101fe5:	f0 
f0101fe6:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0101fed:	f0 
f0101fee:	c7 44 24 04 06 04 00 	movl   $0x406,0x4(%esp)
f0101ff5:	00 
f0101ff6:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0101ffd:	e8 3e e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102002:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102007:	74 24                	je     f010202d <mem_init+0xaea>
f0102009:	c7 44 24 0c e9 7c 10 	movl   $0xf0107ce9,0xc(%esp)
f0102010:	f0 
f0102011:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102018:	f0 
f0102019:	c7 44 24 04 07 04 00 	movl   $0x407,0x4(%esp)
f0102020:	00 
f0102021:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102028:	e8 13 e0 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010202d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102034:	e8 b9 f0 ff ff       	call   f01010f2 <page_alloc>
f0102039:	85 c0                	test   %eax,%eax
f010203b:	74 24                	je     f0102061 <mem_init+0xb1e>
f010203d:	c7 44 24 0c 75 7c 10 	movl   $0xf0107c75,0xc(%esp)
f0102044:	f0 
f0102045:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010204c:	f0 
f010204d:	c7 44 24 04 0b 04 00 	movl   $0x40b,0x4(%esp)
f0102054:	00 
f0102055:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010205c:	e8 df df ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0102061:	8b 15 8c 0e 23 f0    	mov    0xf0230e8c,%edx
f0102067:	8b 02                	mov    (%edx),%eax
f0102069:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f010206e:	89 c1                	mov    %eax,%ecx
f0102070:	c1 e9 0c             	shr    $0xc,%ecx
f0102073:	3b 0d 88 0e 23 f0    	cmp    0xf0230e88,%ecx
f0102079:	72 20                	jb     f010209b <mem_init+0xb58>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010207b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010207f:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f0102086:	f0 
f0102087:	c7 44 24 04 0e 04 00 	movl   $0x40e,0x4(%esp)
f010208e:	00 
f010208f:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102096:	e8 a5 df ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010209b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020a0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01020a3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01020aa:	00 
f01020ab:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01020b2:	00 
f01020b3:	89 14 24             	mov    %edx,(%esp)
f01020b6:	e8 41 f1 ff ff       	call   f01011fc <pgdir_walk>
f01020bb:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01020be:	8d 51 04             	lea    0x4(%ecx),%edx
f01020c1:	39 d0                	cmp    %edx,%eax
f01020c3:	74 24                	je     f01020e9 <mem_init+0xba6>
f01020c5:	c7 44 24 0c 64 74 10 	movl   $0xf0107464,0xc(%esp)
f01020cc:	f0 
f01020cd:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01020d4:	f0 
f01020d5:	c7 44 24 04 0f 04 00 	movl   $0x40f,0x4(%esp)
f01020dc:	00 
f01020dd:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01020e4:	e8 57 df ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01020e9:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01020f0:	00 
f01020f1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01020f8:	00 
f01020f9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01020fd:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0102102:	89 04 24             	mov    %eax,(%esp)
f0102105:	e8 29 f3 ff ff       	call   f0101433 <page_insert>
f010210a:	85 c0                	test   %eax,%eax
f010210c:	74 24                	je     f0102132 <mem_init+0xbef>
f010210e:	c7 44 24 0c a4 74 10 	movl   $0xf01074a4,0xc(%esp)
f0102115:	f0 
f0102116:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010211d:	f0 
f010211e:	c7 44 24 04 12 04 00 	movl   $0x412,0x4(%esp)
f0102125:	00 
f0102126:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010212d:	e8 0e df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102132:	8b 3d 8c 0e 23 f0    	mov    0xf0230e8c,%edi
f0102138:	ba 00 10 00 00       	mov    $0x1000,%edx
f010213d:	89 f8                	mov    %edi,%eax
f010213f:	e8 8d ea ff ff       	call   f0100bd1 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0102144:	89 f2                	mov    %esi,%edx
f0102146:	2b 15 90 0e 23 f0    	sub    0xf0230e90,%edx
f010214c:	c1 fa 03             	sar    $0x3,%edx
f010214f:	c1 e2 0c             	shl    $0xc,%edx
f0102152:	39 d0                	cmp    %edx,%eax
f0102154:	74 24                	je     f010217a <mem_init+0xc37>
f0102156:	c7 44 24 0c 34 74 10 	movl   $0xf0107434,0xc(%esp)
f010215d:	f0 
f010215e:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102165:	f0 
f0102166:	c7 44 24 04 13 04 00 	movl   $0x413,0x4(%esp)
f010216d:	00 
f010216e:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102175:	e8 c6 de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010217a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010217f:	74 24                	je     f01021a5 <mem_init+0xc62>
f0102181:	c7 44 24 0c e9 7c 10 	movl   $0xf0107ce9,0xc(%esp)
f0102188:	f0 
f0102189:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102190:	f0 
f0102191:	c7 44 24 04 14 04 00 	movl   $0x414,0x4(%esp)
f0102198:	00 
f0102199:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01021a0:	e8 9b de ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01021a5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021ac:	00 
f01021ad:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021b4:	00 
f01021b5:	89 3c 24             	mov    %edi,(%esp)
f01021b8:	e8 3f f0 ff ff       	call   f01011fc <pgdir_walk>
f01021bd:	f6 00 04             	testb  $0x4,(%eax)
f01021c0:	75 24                	jne    f01021e6 <mem_init+0xca3>
f01021c2:	c7 44 24 0c e4 74 10 	movl   $0xf01074e4,0xc(%esp)
f01021c9:	f0 
f01021ca:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01021d1:	f0 
f01021d2:	c7 44 24 04 15 04 00 	movl   $0x415,0x4(%esp)
f01021d9:	00 
f01021da:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01021e1:	e8 5a de ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01021e6:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f01021eb:	f6 00 04             	testb  $0x4,(%eax)
f01021ee:	75 24                	jne    f0102214 <mem_init+0xcd1>
f01021f0:	c7 44 24 0c fa 7c 10 	movl   $0xf0107cfa,0xc(%esp)
f01021f7:	f0 
f01021f8:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01021ff:	f0 
f0102200:	c7 44 24 04 16 04 00 	movl   $0x416,0x4(%esp)
f0102207:	00 
f0102208:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010220f:	e8 2c de ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102214:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010221b:	00 
f010221c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102223:	00 
f0102224:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102228:	89 04 24             	mov    %eax,(%esp)
f010222b:	e8 03 f2 ff ff       	call   f0101433 <page_insert>
f0102230:	85 c0                	test   %eax,%eax
f0102232:	74 24                	je     f0102258 <mem_init+0xd15>
f0102234:	c7 44 24 0c f8 73 10 	movl   $0xf01073f8,0xc(%esp)
f010223b:	f0 
f010223c:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102243:	f0 
f0102244:	c7 44 24 04 19 04 00 	movl   $0x419,0x4(%esp)
f010224b:	00 
f010224c:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102253:	e8 e8 dd ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102258:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010225f:	00 
f0102260:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102267:	00 
f0102268:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f010226d:	89 04 24             	mov    %eax,(%esp)
f0102270:	e8 87 ef ff ff       	call   f01011fc <pgdir_walk>
f0102275:	f6 00 02             	testb  $0x2,(%eax)
f0102278:	75 24                	jne    f010229e <mem_init+0xd5b>
f010227a:	c7 44 24 0c 18 75 10 	movl   $0xf0107518,0xc(%esp)
f0102281:	f0 
f0102282:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102289:	f0 
f010228a:	c7 44 24 04 1a 04 00 	movl   $0x41a,0x4(%esp)
f0102291:	00 
f0102292:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102299:	e8 a2 dd ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010229e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01022a5:	00 
f01022a6:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022ad:	00 
f01022ae:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f01022b3:	89 04 24             	mov    %eax,(%esp)
f01022b6:	e8 41 ef ff ff       	call   f01011fc <pgdir_walk>
f01022bb:	f6 00 04             	testb  $0x4,(%eax)
f01022be:	74 24                	je     f01022e4 <mem_init+0xda1>
f01022c0:	c7 44 24 0c 4c 75 10 	movl   $0xf010754c,0xc(%esp)
f01022c7:	f0 
f01022c8:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01022cf:	f0 
f01022d0:	c7 44 24 04 1b 04 00 	movl   $0x41b,0x4(%esp)
f01022d7:	00 
f01022d8:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01022df:	e8 5c dd ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01022e4:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01022eb:	00 
f01022ec:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01022f3:	00 
f01022f4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01022fb:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0102300:	89 04 24             	mov    %eax,(%esp)
f0102303:	e8 2b f1 ff ff       	call   f0101433 <page_insert>
f0102308:	85 c0                	test   %eax,%eax
f010230a:	78 24                	js     f0102330 <mem_init+0xded>
f010230c:	c7 44 24 0c 84 75 10 	movl   $0xf0107584,0xc(%esp)
f0102313:	f0 
f0102314:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010231b:	f0 
f010231c:	c7 44 24 04 1e 04 00 	movl   $0x41e,0x4(%esp)
f0102323:	00 
f0102324:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010232b:	e8 10 dd ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102330:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102337:	00 
f0102338:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010233f:	00 
f0102340:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102344:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0102349:	89 04 24             	mov    %eax,(%esp)
f010234c:	e8 e2 f0 ff ff       	call   f0101433 <page_insert>
f0102351:	85 c0                	test   %eax,%eax
f0102353:	74 24                	je     f0102379 <mem_init+0xe36>
f0102355:	c7 44 24 0c bc 75 10 	movl   $0xf01075bc,0xc(%esp)
f010235c:	f0 
f010235d:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102364:	f0 
f0102365:	c7 44 24 04 21 04 00 	movl   $0x421,0x4(%esp)
f010236c:	00 
f010236d:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102374:	e8 c7 dc ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102379:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102380:	00 
f0102381:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102388:	00 
f0102389:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f010238e:	89 04 24             	mov    %eax,(%esp)
f0102391:	e8 66 ee ff ff       	call   f01011fc <pgdir_walk>
f0102396:	f6 00 04             	testb  $0x4,(%eax)
f0102399:	74 24                	je     f01023bf <mem_init+0xe7c>
f010239b:	c7 44 24 0c 4c 75 10 	movl   $0xf010754c,0xc(%esp)
f01023a2:	f0 
f01023a3:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01023aa:	f0 
f01023ab:	c7 44 24 04 22 04 00 	movl   $0x422,0x4(%esp)
f01023b2:	00 
f01023b3:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01023ba:	e8 81 dc ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01023bf:	8b 3d 8c 0e 23 f0    	mov    0xf0230e8c,%edi
f01023c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01023ca:	89 f8                	mov    %edi,%eax
f01023cc:	e8 00 e8 ff ff       	call   f0100bd1 <check_va2pa>
f01023d1:	89 c1                	mov    %eax,%ecx
f01023d3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01023d6:	89 d8                	mov    %ebx,%eax
f01023d8:	2b 05 90 0e 23 f0    	sub    0xf0230e90,%eax
f01023de:	c1 f8 03             	sar    $0x3,%eax
f01023e1:	c1 e0 0c             	shl    $0xc,%eax
f01023e4:	39 c1                	cmp    %eax,%ecx
f01023e6:	74 24                	je     f010240c <mem_init+0xec9>
f01023e8:	c7 44 24 0c f8 75 10 	movl   $0xf01075f8,0xc(%esp)
f01023ef:	f0 
f01023f0:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01023f7:	f0 
f01023f8:	c7 44 24 04 25 04 00 	movl   $0x425,0x4(%esp)
f01023ff:	00 
f0102400:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102407:	e8 34 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010240c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102411:	89 f8                	mov    %edi,%eax
f0102413:	e8 b9 e7 ff ff       	call   f0100bd1 <check_va2pa>
f0102418:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010241b:	74 24                	je     f0102441 <mem_init+0xefe>
f010241d:	c7 44 24 0c 24 76 10 	movl   $0xf0107624,0xc(%esp)
f0102424:	f0 
f0102425:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010242c:	f0 
f010242d:	c7 44 24 04 26 04 00 	movl   $0x426,0x4(%esp)
f0102434:	00 
f0102435:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010243c:	e8 ff db ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102441:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0102446:	74 24                	je     f010246c <mem_init+0xf29>
f0102448:	c7 44 24 0c 10 7d 10 	movl   $0xf0107d10,0xc(%esp)
f010244f:	f0 
f0102450:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102457:	f0 
f0102458:	c7 44 24 04 28 04 00 	movl   $0x428,0x4(%esp)
f010245f:	00 
f0102460:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102467:	e8 d4 db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010246c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102471:	74 24                	je     f0102497 <mem_init+0xf54>
f0102473:	c7 44 24 0c 21 7d 10 	movl   $0xf0107d21,0xc(%esp)
f010247a:	f0 
f010247b:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102482:	f0 
f0102483:	c7 44 24 04 29 04 00 	movl   $0x429,0x4(%esp)
f010248a:	00 
f010248b:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102492:	e8 a9 db ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102497:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010249e:	e8 4f ec ff ff       	call   f01010f2 <page_alloc>
f01024a3:	85 c0                	test   %eax,%eax
f01024a5:	74 04                	je     f01024ab <mem_init+0xf68>
f01024a7:	39 c6                	cmp    %eax,%esi
f01024a9:	74 24                	je     f01024cf <mem_init+0xf8c>
f01024ab:	c7 44 24 0c 54 76 10 	movl   $0xf0107654,0xc(%esp)
f01024b2:	f0 
f01024b3:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01024ba:	f0 
f01024bb:	c7 44 24 04 2c 04 00 	movl   $0x42c,0x4(%esp)
f01024c2:	00 
f01024c3:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01024ca:	e8 71 db ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01024cf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01024d6:	00 
f01024d7:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f01024dc:	89 04 24             	mov    %eax,(%esp)
f01024df:	e8 06 ef ff ff       	call   f01013ea <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01024e4:	8b 3d 8c 0e 23 f0    	mov    0xf0230e8c,%edi
f01024ea:	ba 00 00 00 00       	mov    $0x0,%edx
f01024ef:	89 f8                	mov    %edi,%eax
f01024f1:	e8 db e6 ff ff       	call   f0100bd1 <check_va2pa>
f01024f6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024f9:	74 24                	je     f010251f <mem_init+0xfdc>
f01024fb:	c7 44 24 0c 78 76 10 	movl   $0xf0107678,0xc(%esp)
f0102502:	f0 
f0102503:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010250a:	f0 
f010250b:	c7 44 24 04 30 04 00 	movl   $0x430,0x4(%esp)
f0102512:	00 
f0102513:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010251a:	e8 21 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010251f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102524:	89 f8                	mov    %edi,%eax
f0102526:	e8 a6 e6 ff ff       	call   f0100bd1 <check_va2pa>
f010252b:	89 da                	mov    %ebx,%edx
f010252d:	2b 15 90 0e 23 f0    	sub    0xf0230e90,%edx
f0102533:	c1 fa 03             	sar    $0x3,%edx
f0102536:	c1 e2 0c             	shl    $0xc,%edx
f0102539:	39 d0                	cmp    %edx,%eax
f010253b:	74 24                	je     f0102561 <mem_init+0x101e>
f010253d:	c7 44 24 0c 24 76 10 	movl   $0xf0107624,0xc(%esp)
f0102544:	f0 
f0102545:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010254c:	f0 
f010254d:	c7 44 24 04 31 04 00 	movl   $0x431,0x4(%esp)
f0102554:	00 
f0102555:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010255c:	e8 df da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102561:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102566:	74 24                	je     f010258c <mem_init+0x1049>
f0102568:	c7 44 24 0c c7 7c 10 	movl   $0xf0107cc7,0xc(%esp)
f010256f:	f0 
f0102570:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102577:	f0 
f0102578:	c7 44 24 04 32 04 00 	movl   $0x432,0x4(%esp)
f010257f:	00 
f0102580:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102587:	e8 b4 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010258c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102591:	74 24                	je     f01025b7 <mem_init+0x1074>
f0102593:	c7 44 24 0c 21 7d 10 	movl   $0xf0107d21,0xc(%esp)
f010259a:	f0 
f010259b:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01025a2:	f0 
f01025a3:	c7 44 24 04 33 04 00 	movl   $0x433,0x4(%esp)
f01025aa:	00 
f01025ab:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01025b2:	e8 89 da ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01025b7:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01025be:	00 
f01025bf:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01025c6:	00 
f01025c7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01025cb:	89 3c 24             	mov    %edi,(%esp)
f01025ce:	e8 60 ee ff ff       	call   f0101433 <page_insert>
f01025d3:	85 c0                	test   %eax,%eax
f01025d5:	74 24                	je     f01025fb <mem_init+0x10b8>
f01025d7:	c7 44 24 0c 9c 76 10 	movl   $0xf010769c,0xc(%esp)
f01025de:	f0 
f01025df:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01025e6:	f0 
f01025e7:	c7 44 24 04 36 04 00 	movl   $0x436,0x4(%esp)
f01025ee:	00 
f01025ef:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01025f6:	e8 45 da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f01025fb:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102600:	75 24                	jne    f0102626 <mem_init+0x10e3>
f0102602:	c7 44 24 0c 32 7d 10 	movl   $0xf0107d32,0xc(%esp)
f0102609:	f0 
f010260a:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102611:	f0 
f0102612:	c7 44 24 04 37 04 00 	movl   $0x437,0x4(%esp)
f0102619:	00 
f010261a:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102621:	e8 1a da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102626:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102629:	74 24                	je     f010264f <mem_init+0x110c>
f010262b:	c7 44 24 0c 3e 7d 10 	movl   $0xf0107d3e,0xc(%esp)
f0102632:	f0 
f0102633:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010263a:	f0 
f010263b:	c7 44 24 04 38 04 00 	movl   $0x438,0x4(%esp)
f0102642:	00 
f0102643:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010264a:	e8 f1 d9 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010264f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102656:	00 
f0102657:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f010265c:	89 04 24             	mov    %eax,(%esp)
f010265f:	e8 86 ed ff ff       	call   f01013ea <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102664:	8b 3d 8c 0e 23 f0    	mov    0xf0230e8c,%edi
f010266a:	ba 00 00 00 00       	mov    $0x0,%edx
f010266f:	89 f8                	mov    %edi,%eax
f0102671:	e8 5b e5 ff ff       	call   f0100bd1 <check_va2pa>
f0102676:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102679:	74 24                	je     f010269f <mem_init+0x115c>
f010267b:	c7 44 24 0c 78 76 10 	movl   $0xf0107678,0xc(%esp)
f0102682:	f0 
f0102683:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010268a:	f0 
f010268b:	c7 44 24 04 3c 04 00 	movl   $0x43c,0x4(%esp)
f0102692:	00 
f0102693:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010269a:	e8 a1 d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010269f:	ba 00 10 00 00       	mov    $0x1000,%edx
f01026a4:	89 f8                	mov    %edi,%eax
f01026a6:	e8 26 e5 ff ff       	call   f0100bd1 <check_va2pa>
f01026ab:	83 f8 ff             	cmp    $0xffffffff,%eax
f01026ae:	74 24                	je     f01026d4 <mem_init+0x1191>
f01026b0:	c7 44 24 0c d4 76 10 	movl   $0xf01076d4,0xc(%esp)
f01026b7:	f0 
f01026b8:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01026bf:	f0 
f01026c0:	c7 44 24 04 3d 04 00 	movl   $0x43d,0x4(%esp)
f01026c7:	00 
f01026c8:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01026cf:	e8 6c d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01026d4:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01026d9:	74 24                	je     f01026ff <mem_init+0x11bc>
f01026db:	c7 44 24 0c 53 7d 10 	movl   $0xf0107d53,0xc(%esp)
f01026e2:	f0 
f01026e3:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01026ea:	f0 
f01026eb:	c7 44 24 04 3e 04 00 	movl   $0x43e,0x4(%esp)
f01026f2:	00 
f01026f3:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01026fa:	e8 41 d9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01026ff:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102704:	74 24                	je     f010272a <mem_init+0x11e7>
f0102706:	c7 44 24 0c 21 7d 10 	movl   $0xf0107d21,0xc(%esp)
f010270d:	f0 
f010270e:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102715:	f0 
f0102716:	c7 44 24 04 3f 04 00 	movl   $0x43f,0x4(%esp)
f010271d:	00 
f010271e:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102725:	e8 16 d9 ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010272a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102731:	e8 bc e9 ff ff       	call   f01010f2 <page_alloc>
f0102736:	85 c0                	test   %eax,%eax
f0102738:	74 04                	je     f010273e <mem_init+0x11fb>
f010273a:	39 c3                	cmp    %eax,%ebx
f010273c:	74 24                	je     f0102762 <mem_init+0x121f>
f010273e:	c7 44 24 0c fc 76 10 	movl   $0xf01076fc,0xc(%esp)
f0102745:	f0 
f0102746:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010274d:	f0 
f010274e:	c7 44 24 04 42 04 00 	movl   $0x442,0x4(%esp)
f0102755:	00 
f0102756:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010275d:	e8 de d8 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102762:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102769:	e8 84 e9 ff ff       	call   f01010f2 <page_alloc>
f010276e:	85 c0                	test   %eax,%eax
f0102770:	74 24                	je     f0102796 <mem_init+0x1253>
f0102772:	c7 44 24 0c 75 7c 10 	movl   $0xf0107c75,0xc(%esp)
f0102779:	f0 
f010277a:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102781:	f0 
f0102782:	c7 44 24 04 45 04 00 	movl   $0x445,0x4(%esp)
f0102789:	00 
f010278a:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102791:	e8 aa d8 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102796:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f010279b:	8b 08                	mov    (%eax),%ecx
f010279d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01027a3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01027a6:	2b 15 90 0e 23 f0    	sub    0xf0230e90,%edx
f01027ac:	c1 fa 03             	sar    $0x3,%edx
f01027af:	c1 e2 0c             	shl    $0xc,%edx
f01027b2:	39 d1                	cmp    %edx,%ecx
f01027b4:	74 24                	je     f01027da <mem_init+0x1297>
f01027b6:	c7 44 24 0c a0 73 10 	movl   $0xf01073a0,0xc(%esp)
f01027bd:	f0 
f01027be:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01027c5:	f0 
f01027c6:	c7 44 24 04 48 04 00 	movl   $0x448,0x4(%esp)
f01027cd:	00 
f01027ce:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01027d5:	e8 66 d8 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01027da:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01027e0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01027e3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01027e8:	74 24                	je     f010280e <mem_init+0x12cb>
f01027ea:	c7 44 24 0c d8 7c 10 	movl   $0xf0107cd8,0xc(%esp)
f01027f1:	f0 
f01027f2:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01027f9:	f0 
f01027fa:	c7 44 24 04 4a 04 00 	movl   $0x44a,0x4(%esp)
f0102801:	00 
f0102802:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102809:	e8 32 d8 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010280e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102811:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102817:	89 04 24             	mov    %eax,(%esp)
f010281a:	e8 5e e9 ff ff       	call   f010117d <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010281f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102826:	00 
f0102827:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010282e:	00 
f010282f:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0102834:	89 04 24             	mov    %eax,(%esp)
f0102837:	e8 c0 e9 ff ff       	call   f01011fc <pgdir_walk>
f010283c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010283f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102842:	8b 15 8c 0e 23 f0    	mov    0xf0230e8c,%edx
f0102848:	8b 7a 04             	mov    0x4(%edx),%edi
f010284b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	if (PGNUM(pa) >= npages)
f0102851:	8b 0d 88 0e 23 f0    	mov    0xf0230e88,%ecx
f0102857:	89 f8                	mov    %edi,%eax
f0102859:	c1 e8 0c             	shr    $0xc,%eax
f010285c:	39 c8                	cmp    %ecx,%eax
f010285e:	72 20                	jb     f0102880 <mem_init+0x133d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102860:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102864:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f010286b:	f0 
f010286c:	c7 44 24 04 51 04 00 	movl   $0x451,0x4(%esp)
f0102873:	00 
f0102874:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010287b:	e8 c0 d7 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102880:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102886:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102889:	74 24                	je     f01028af <mem_init+0x136c>
f010288b:	c7 44 24 0c 64 7d 10 	movl   $0xf0107d64,0xc(%esp)
f0102892:	f0 
f0102893:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010289a:	f0 
f010289b:	c7 44 24 04 52 04 00 	movl   $0x452,0x4(%esp)
f01028a2:	00 
f01028a3:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01028aa:	e8 91 d7 ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01028af:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01028b6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028b9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01028bf:	2b 05 90 0e 23 f0    	sub    0xf0230e90,%eax
f01028c5:	c1 f8 03             	sar    $0x3,%eax
f01028c8:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01028cb:	89 c2                	mov    %eax,%edx
f01028cd:	c1 ea 0c             	shr    $0xc,%edx
f01028d0:	39 d1                	cmp    %edx,%ecx
f01028d2:	77 20                	ja     f01028f4 <mem_init+0x13b1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01028d4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028d8:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f01028df:	f0 
f01028e0:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01028e7:	00 
f01028e8:	c7 04 24 a5 7a 10 f0 	movl   $0xf0107aa5,(%esp)
f01028ef:	e8 4c d7 ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01028f4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01028fb:	00 
f01028fc:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102903:	00 
	return (void *)(pa + KERNBASE);
f0102904:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102909:	89 04 24             	mov    %eax,(%esp)
f010290c:	e8 76 35 00 00       	call   f0105e87 <memset>
	page_free(pp0);
f0102911:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102914:	89 3c 24             	mov    %edi,(%esp)
f0102917:	e8 61 e8 ff ff       	call   f010117d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010291c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102923:	00 
f0102924:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010292b:	00 
f010292c:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0102931:	89 04 24             	mov    %eax,(%esp)
f0102934:	e8 c3 e8 ff ff       	call   f01011fc <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0102939:	89 fa                	mov    %edi,%edx
f010293b:	2b 15 90 0e 23 f0    	sub    0xf0230e90,%edx
f0102941:	c1 fa 03             	sar    $0x3,%edx
f0102944:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102947:	89 d0                	mov    %edx,%eax
f0102949:	c1 e8 0c             	shr    $0xc,%eax
f010294c:	3b 05 88 0e 23 f0    	cmp    0xf0230e88,%eax
f0102952:	72 20                	jb     f0102974 <mem_init+0x1431>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102954:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102958:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f010295f:	f0 
f0102960:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0102967:	00 
f0102968:	c7 04 24 a5 7a 10 f0 	movl   $0xf0107aa5,(%esp)
f010296f:	e8 cc d6 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102974:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010297a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010297d:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102983:	f6 00 01             	testb  $0x1,(%eax)
f0102986:	74 24                	je     f01029ac <mem_init+0x1469>
f0102988:	c7 44 24 0c 7c 7d 10 	movl   $0xf0107d7c,0xc(%esp)
f010298f:	f0 
f0102990:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102997:	f0 
f0102998:	c7 44 24 04 5c 04 00 	movl   $0x45c,0x4(%esp)
f010299f:	00 
f01029a0:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01029a7:	e8 94 d6 ff ff       	call   f0100040 <_panic>
f01029ac:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01029af:	39 d0                	cmp    %edx,%eax
f01029b1:	75 d0                	jne    f0102983 <mem_init+0x1440>
	kern_pgdir[0] = 0;
f01029b3:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f01029b8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01029be:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029c1:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01029c7:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01029ca:	89 0d 40 02 23 f0    	mov    %ecx,0xf0230240

	// free the pages we took
	page_free(pp0);
f01029d0:	89 04 24             	mov    %eax,(%esp)
f01029d3:	e8 a5 e7 ff ff       	call   f010117d <page_free>
	page_free(pp1);
f01029d8:	89 1c 24             	mov    %ebx,(%esp)
f01029db:	e8 9d e7 ff ff       	call   f010117d <page_free>
	page_free(pp2);
f01029e0:	89 34 24             	mov    %esi,(%esp)
f01029e3:	e8 95 e7 ff ff       	call   f010117d <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01029e8:	c7 44 24 04 01 10 00 	movl   $0x1001,0x4(%esp)
f01029ef:	00 
f01029f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01029f7:	e8 d8 ea ff ff       	call   f01014d4 <mmio_map_region>
f01029fc:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f01029fe:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102a05:	00 
f0102a06:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a0d:	e8 c2 ea ff ff       	call   f01014d4 <mmio_map_region>
f0102a12:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8192 < MMIOLIM);
f0102a14:	8d 83 00 20 00 00    	lea    0x2000(%ebx),%eax
f0102a1a:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102a1f:	77 08                	ja     f0102a29 <mem_init+0x14e6>
f0102a21:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102a27:	77 24                	ja     f0102a4d <mem_init+0x150a>
f0102a29:	c7 44 24 0c 20 77 10 	movl   $0xf0107720,0xc(%esp)
f0102a30:	f0 
f0102a31:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102a38:	f0 
f0102a39:	c7 44 24 04 6c 04 00 	movl   $0x46c,0x4(%esp)
f0102a40:	00 
f0102a41:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102a48:	e8 f3 d5 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8192 < MMIOLIM);
f0102a4d:	8d 96 00 20 00 00    	lea    0x2000(%esi),%edx
f0102a53:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102a59:	77 08                	ja     f0102a63 <mem_init+0x1520>
f0102a5b:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102a61:	77 24                	ja     f0102a87 <mem_init+0x1544>
f0102a63:	c7 44 24 0c 48 77 10 	movl   $0xf0107748,0xc(%esp)
f0102a6a:	f0 
f0102a6b:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102a72:	f0 
f0102a73:	c7 44 24 04 6d 04 00 	movl   $0x46d,0x4(%esp)
f0102a7a:	00 
f0102a7b:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102a82:	e8 b9 d5 ff ff       	call   f0100040 <_panic>
f0102a87:	89 da                	mov    %ebx,%edx
f0102a89:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102a8b:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102a91:	74 24                	je     f0102ab7 <mem_init+0x1574>
f0102a93:	c7 44 24 0c 70 77 10 	movl   $0xf0107770,0xc(%esp)
f0102a9a:	f0 
f0102a9b:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102aa2:	f0 
f0102aa3:	c7 44 24 04 6f 04 00 	movl   $0x46f,0x4(%esp)
f0102aaa:	00 
f0102aab:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102ab2:	e8 89 d5 ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8192 <= mm2);
f0102ab7:	39 c6                	cmp    %eax,%esi
f0102ab9:	73 24                	jae    f0102adf <mem_init+0x159c>
f0102abb:	c7 44 24 0c 93 7d 10 	movl   $0xf0107d93,0xc(%esp)
f0102ac2:	f0 
f0102ac3:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102aca:	f0 
f0102acb:	c7 44 24 04 71 04 00 	movl   $0x471,0x4(%esp)
f0102ad2:	00 
f0102ad3:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102ada:	e8 61 d5 ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102adf:	8b 3d 8c 0e 23 f0    	mov    0xf0230e8c,%edi
f0102ae5:	89 da                	mov    %ebx,%edx
f0102ae7:	89 f8                	mov    %edi,%eax
f0102ae9:	e8 e3 e0 ff ff       	call   f0100bd1 <check_va2pa>
f0102aee:	85 c0                	test   %eax,%eax
f0102af0:	74 24                	je     f0102b16 <mem_init+0x15d3>
f0102af2:	c7 44 24 0c 98 77 10 	movl   $0xf0107798,0xc(%esp)
f0102af9:	f0 
f0102afa:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102b01:	f0 
f0102b02:	c7 44 24 04 73 04 00 	movl   $0x473,0x4(%esp)
f0102b09:	00 
f0102b0a:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102b11:	e8 2a d5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102b16:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102b1c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102b1f:	89 c2                	mov    %eax,%edx
f0102b21:	89 f8                	mov    %edi,%eax
f0102b23:	e8 a9 e0 ff ff       	call   f0100bd1 <check_va2pa>
f0102b28:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102b2d:	74 24                	je     f0102b53 <mem_init+0x1610>
f0102b2f:	c7 44 24 0c bc 77 10 	movl   $0xf01077bc,0xc(%esp)
f0102b36:	f0 
f0102b37:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102b3e:	f0 
f0102b3f:	c7 44 24 04 74 04 00 	movl   $0x474,0x4(%esp)
f0102b46:	00 
f0102b47:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102b4e:	e8 ed d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102b53:	89 f2                	mov    %esi,%edx
f0102b55:	89 f8                	mov    %edi,%eax
f0102b57:	e8 75 e0 ff ff       	call   f0100bd1 <check_va2pa>
f0102b5c:	85 c0                	test   %eax,%eax
f0102b5e:	74 24                	je     f0102b84 <mem_init+0x1641>
f0102b60:	c7 44 24 0c ec 77 10 	movl   $0xf01077ec,0xc(%esp)
f0102b67:	f0 
f0102b68:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102b6f:	f0 
f0102b70:	c7 44 24 04 75 04 00 	movl   $0x475,0x4(%esp)
f0102b77:	00 
f0102b78:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102b7f:	e8 bc d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102b84:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102b8a:	89 f8                	mov    %edi,%eax
f0102b8c:	e8 40 e0 ff ff       	call   f0100bd1 <check_va2pa>
f0102b91:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102b94:	74 24                	je     f0102bba <mem_init+0x1677>
f0102b96:	c7 44 24 0c 10 78 10 	movl   $0xf0107810,0xc(%esp)
f0102b9d:	f0 
f0102b9e:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102ba5:	f0 
f0102ba6:	c7 44 24 04 76 04 00 	movl   $0x476,0x4(%esp)
f0102bad:	00 
f0102bae:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102bb5:	e8 86 d4 ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102bba:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102bc1:	00 
f0102bc2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102bc6:	89 3c 24             	mov    %edi,(%esp)
f0102bc9:	e8 2e e6 ff ff       	call   f01011fc <pgdir_walk>
f0102bce:	f6 00 1a             	testb  $0x1a,(%eax)
f0102bd1:	75 24                	jne    f0102bf7 <mem_init+0x16b4>
f0102bd3:	c7 44 24 0c 3c 78 10 	movl   $0xf010783c,0xc(%esp)
f0102bda:	f0 
f0102bdb:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102be2:	f0 
f0102be3:	c7 44 24 04 78 04 00 	movl   $0x478,0x4(%esp)
f0102bea:	00 
f0102beb:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102bf2:	e8 49 d4 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102bf7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102bfe:	00 
f0102bff:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102c03:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0102c08:	89 04 24             	mov    %eax,(%esp)
f0102c0b:	e8 ec e5 ff ff       	call   f01011fc <pgdir_walk>
f0102c10:	f6 00 04             	testb  $0x4,(%eax)
f0102c13:	74 24                	je     f0102c39 <mem_init+0x16f6>
f0102c15:	c7 44 24 0c 80 78 10 	movl   $0xf0107880,0xc(%esp)
f0102c1c:	f0 
f0102c1d:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102c24:	f0 
f0102c25:	c7 44 24 04 79 04 00 	movl   $0x479,0x4(%esp)
f0102c2c:	00 
f0102c2d:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102c34:	e8 07 d4 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102c39:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102c40:	00 
f0102c41:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102c45:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0102c4a:	89 04 24             	mov    %eax,(%esp)
f0102c4d:	e8 aa e5 ff ff       	call   f01011fc <pgdir_walk>
f0102c52:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102c58:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102c5f:	00 
f0102c60:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c63:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102c67:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0102c6c:	89 04 24             	mov    %eax,(%esp)
f0102c6f:	e8 88 e5 ff ff       	call   f01011fc <pgdir_walk>
f0102c74:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102c7a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102c81:	00 
f0102c82:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102c86:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0102c8b:	89 04 24             	mov    %eax,(%esp)
f0102c8e:	e8 69 e5 ff ff       	call   f01011fc <pgdir_walk>
f0102c93:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102c99:	c7 04 24 a5 7d 10 f0 	movl   $0xf0107da5,(%esp)
f0102ca0:	e8 be 12 00 00       	call   f0103f63 <cprintf>
	boot_map_region(kern_pgdir, UPAGES, npages * sizeof(struct PageInfo), PADDR(pages), PTE_U | PTE_P);
f0102ca5:	a1 90 0e 23 f0       	mov    0xf0230e90,%eax
	if ((uint32_t)kva < KERNBASE)
f0102caa:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102caf:	77 20                	ja     f0102cd1 <mem_init+0x178e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102cb1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102cb5:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0102cbc:	f0 
f0102cbd:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
f0102cc4:	00 
f0102cc5:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102ccc:	e8 6f d3 ff ff       	call   f0100040 <_panic>
f0102cd1:	8b 0d 88 0e 23 f0    	mov    0xf0230e88,%ecx
f0102cd7:	c1 e1 03             	shl    $0x3,%ecx
f0102cda:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102ce1:	00 
	return (physaddr_t)kva - KERNBASE;
f0102ce2:	05 00 00 00 10       	add    $0x10000000,%eax
f0102ce7:	89 04 24             	mov    %eax,(%esp)
f0102cea:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102cef:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0102cf4:	e8 ec e5 ff ff       	call   f01012e5 <boot_map_region>
	boot_map_region(kern_pgdir, UENVS, NENV * sizeof(struct Env), PADDR(envs), PTE_U | PTE_P);
f0102cf9:	a1 48 02 23 f0       	mov    0xf0230248,%eax
	if ((uint32_t)kva < KERNBASE)
f0102cfe:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d03:	77 20                	ja     f0102d25 <mem_init+0x17e2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d05:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d09:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0102d10:	f0 
f0102d11:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
f0102d18:	00 
f0102d19:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102d20:	e8 1b d3 ff ff       	call   f0100040 <_panic>
f0102d25:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102d2c:	00 
	return (physaddr_t)kva - KERNBASE;
f0102d2d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d32:	89 04 24             	mov    %eax,(%esp)
f0102d35:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f0102d3a:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102d3f:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0102d44:	e8 9c e5 ff ff       	call   f01012e5 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102d49:	b8 00 70 11 f0       	mov    $0xf0117000,%eax
f0102d4e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d53:	77 20                	ja     f0102d75 <mem_init+0x1832>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d55:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d59:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0102d60:	f0 
f0102d61:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
f0102d68:	00 
f0102d69:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102d70:	e8 cb d2 ff ff       	call   f0100040 <_panic>
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102d75:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102d7c:	00 
f0102d7d:	c7 04 24 00 70 11 00 	movl   $0x117000,(%esp)
f0102d84:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102d89:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102d8e:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0102d93:	e8 4d e5 ff ff       	call   f01012e5 <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0xFFFFFFFF - KERNBASE, 0, PTE_W);
f0102d98:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102d9f:	00 
f0102da0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102da7:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102dac:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102db1:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0102db6:	e8 2a e5 ff ff       	call   f01012e5 <boot_map_region>
f0102dbb:	bb 00 20 23 f0       	mov    $0xf0232000,%ebx
	uintptr_t stackSpot = KSTACKTOP - KSTKSIZE;
f0102dc0:	be 00 80 ff ef       	mov    $0xefff8000,%esi
	if ((uint32_t)kva < KERNBASE)
f0102dc5:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102dcb:	77 20                	ja     f0102ded <mem_init+0x18aa>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dcd:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102dd1:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0102dd8:	f0 
f0102dd9:	c7 44 24 04 1c 01 00 	movl   $0x11c,0x4(%esp)
f0102de0:	00 
f0102de1:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102de8:	e8 53 d2 ff ff       	call   f0100040 <_panic>
		boot_map_region(kern_pgdir, stackSpot, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
f0102ded:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102df4:	00 
f0102df5:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0102dfb:	89 04 24             	mov    %eax,(%esp)
f0102dfe:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102e03:	89 f2                	mov    %esi,%edx
f0102e05:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0102e0a:	e8 d6 e4 ff ff       	call   f01012e5 <boot_map_region>
		stackSpot -= (KSTKSIZE + KSTKGAP);
f0102e0f:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f0102e15:	81 c3 00 80 00 00    	add    $0x8000,%ebx
	for(i = 0; i < NCPU; i++)
f0102e1b:	81 fe 00 80 f7 ef    	cmp    $0xeff78000,%esi
f0102e21:	75 a2                	jne    f0102dc5 <mem_init+0x1882>
	pgdir = kern_pgdir;
f0102e23:	8b 3d 8c 0e 23 f0    	mov    0xf0230e8c,%edi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102e29:	a1 88 0e 23 f0       	mov    0xf0230e88,%eax
f0102e2e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102e31:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102e38:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102e3d:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102e40:	8b 35 90 0e 23 f0    	mov    0xf0230e90,%esi
	if ((uint32_t)kva < KERNBASE)
f0102e46:	89 75 cc             	mov    %esi,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102e49:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0102e4f:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f0102e52:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102e57:	eb 6a                	jmp    f0102ec3 <mem_init+0x1980>
f0102e59:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102e5f:	89 f8                	mov    %edi,%eax
f0102e61:	e8 6b dd ff ff       	call   f0100bd1 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102e66:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102e6d:	77 20                	ja     f0102e8f <mem_init+0x194c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e6f:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102e73:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0102e7a:	f0 
f0102e7b:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f0102e82:	00 
f0102e83:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102e8a:	e8 b1 d1 ff ff       	call   f0100040 <_panic>
f0102e8f:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102e92:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f0102e95:	39 d0                	cmp    %edx,%eax
f0102e97:	74 24                	je     f0102ebd <mem_init+0x197a>
f0102e99:	c7 44 24 0c b4 78 10 	movl   $0xf01078b4,0xc(%esp)
f0102ea0:	f0 
f0102ea1:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102ea8:	f0 
f0102ea9:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f0102eb0:	00 
f0102eb1:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102eb8:	e8 83 d1 ff ff       	call   f0100040 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f0102ebd:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102ec3:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102ec6:	77 91                	ja     f0102e59 <mem_init+0x1916>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102ec8:	8b 1d 48 02 23 f0    	mov    0xf0230248,%ebx
	if ((uint32_t)kva < KERNBASE)
f0102ece:	89 de                	mov    %ebx,%esi
f0102ed0:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102ed5:	89 f8                	mov    %edi,%eax
f0102ed7:	e8 f5 dc ff ff       	call   f0100bd1 <check_va2pa>
f0102edc:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102ee2:	77 20                	ja     f0102f04 <mem_init+0x19c1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ee4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102ee8:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0102eef:	f0 
f0102ef0:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0102ef7:	00 
f0102ef8:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102eff:	e8 3c d1 ff ff       	call   f0100040 <_panic>
	if ((uint32_t)kva < KERNBASE)
f0102f04:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102f09:	81 c6 00 00 40 21    	add    $0x21400000,%esi
f0102f0f:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f0102f12:	39 d0                	cmp    %edx,%eax
f0102f14:	74 24                	je     f0102f3a <mem_init+0x19f7>
f0102f16:	c7 44 24 0c e8 78 10 	movl   $0xf01078e8,0xc(%esp)
f0102f1d:	f0 
f0102f1e:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102f25:	f0 
f0102f26:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0102f2d:	00 
f0102f2e:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102f35:	e8 06 d1 ff ff       	call   f0100040 <_panic>
f0102f3a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
f0102f40:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102f46:	0f 85 a9 05 00 00    	jne    f01034f5 <mem_init+0x1fb2>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102f4c:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102f4f:	c1 e6 0c             	shl    $0xc,%esi
f0102f52:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102f57:	eb 3b                	jmp    f0102f94 <mem_init+0x1a51>
f0102f59:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102f5f:	89 f8                	mov    %edi,%eax
f0102f61:	e8 6b dc ff ff       	call   f0100bd1 <check_va2pa>
f0102f66:	39 c3                	cmp    %eax,%ebx
f0102f68:	74 24                	je     f0102f8e <mem_init+0x1a4b>
f0102f6a:	c7 44 24 0c 1c 79 10 	movl   $0xf010791c,0xc(%esp)
f0102f71:	f0 
f0102f72:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0102f79:	f0 
f0102f7a:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102f81:	00 
f0102f82:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102f89:	e8 b2 d0 ff ff       	call   f0100040 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102f8e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102f94:	39 f3                	cmp    %esi,%ebx
f0102f96:	72 c1                	jb     f0102f59 <mem_init+0x1a16>
f0102f98:	c7 45 d0 00 20 23 f0 	movl   $0xf0232000,-0x30(%ebp)
f0102f9f:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0102fa6:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102fab:	b8 00 20 23 f0       	mov    $0xf0232000,%eax
f0102fb0:	05 00 80 00 20       	add    $0x20008000,%eax
f0102fb5:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102fb8:	8d 86 00 80 00 00    	lea    0x8000(%esi),%eax
f0102fbe:	89 45 cc             	mov    %eax,-0x34(%ebp)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102fc1:	89 f2                	mov    %esi,%edx
f0102fc3:	89 f8                	mov    %edi,%eax
f0102fc5:	e8 07 dc ff ff       	call   f0100bd1 <check_va2pa>
f0102fca:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102fcd:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0102fd3:	77 20                	ja     f0102ff5 <mem_init+0x1ab2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102fd5:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102fd9:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0102fe0:	f0 
f0102fe1:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f0102fe8:	00 
f0102fe9:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0102ff0:	e8 4b d0 ff ff       	call   f0100040 <_panic>
	if ((uint32_t)kva < KERNBASE)
f0102ff5:	89 f3                	mov    %esi,%ebx
f0102ff7:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102ffa:	03 4d d4             	add    -0x2c(%ebp),%ecx
f0102ffd:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103000:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0103003:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
f0103006:	39 c2                	cmp    %eax,%edx
f0103008:	74 24                	je     f010302e <mem_init+0x1aeb>
f010300a:	c7 44 24 0c 44 79 10 	movl   $0xf0107944,0xc(%esp)
f0103011:	f0 
f0103012:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0103019:	f0 
f010301a:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f0103021:	00 
f0103022:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0103029:	e8 12 d0 ff ff       	call   f0100040 <_panic>
f010302e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0103034:	3b 5d cc             	cmp    -0x34(%ebp),%ebx
f0103037:	0f 85 a9 04 00 00    	jne    f01034e6 <mem_init+0x1fa3>
f010303d:	8d 9e 00 80 ff ff    	lea    -0x8000(%esi),%ebx
			assert(check_va2pa(pgdir, base + i) == ~0);
f0103043:	89 da                	mov    %ebx,%edx
f0103045:	89 f8                	mov    %edi,%eax
f0103047:	e8 85 db ff ff       	call   f0100bd1 <check_va2pa>
f010304c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010304f:	74 24                	je     f0103075 <mem_init+0x1b32>
f0103051:	c7 44 24 0c 8c 79 10 	movl   $0xf010798c,0xc(%esp)
f0103058:	f0 
f0103059:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0103060:	f0 
f0103061:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f0103068:	00 
f0103069:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0103070:	e8 cb cf ff ff       	call   f0100040 <_panic>
f0103075:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f010307b:	39 f3                	cmp    %esi,%ebx
f010307d:	75 c4                	jne    f0103043 <mem_init+0x1b00>
f010307f:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f0103085:	81 45 d4 00 80 01 00 	addl   $0x18000,-0x2c(%ebp)
f010308c:	81 45 d0 00 80 00 00 	addl   $0x8000,-0x30(%ebp)
	for (n = 0; n < NCPU; n++) {
f0103093:	81 fe 00 80 f7 ef    	cmp    $0xeff78000,%esi
f0103099:	0f 85 19 ff ff ff    	jne    f0102fb8 <mem_init+0x1a75>
f010309f:	b8 00 00 00 00       	mov    $0x0,%eax
f01030a4:	e9 c2 00 00 00       	jmp    f010316b <mem_init+0x1c28>
		switch (i) {
f01030a9:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f01030af:	83 fa 04             	cmp    $0x4,%edx
f01030b2:	77 2e                	ja     f01030e2 <mem_init+0x1b9f>
			assert(pgdir[i] & PTE_P);
f01030b4:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f01030b8:	0f 85 aa 00 00 00    	jne    f0103168 <mem_init+0x1c25>
f01030be:	c7 44 24 0c be 7d 10 	movl   $0xf0107dbe,0xc(%esp)
f01030c5:	f0 
f01030c6:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01030cd:	f0 
f01030ce:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f01030d5:	00 
f01030d6:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01030dd:	e8 5e cf ff ff       	call   f0100040 <_panic>
			if (i >= PDX(KERNBASE)) {
f01030e2:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01030e7:	76 55                	jbe    f010313e <mem_init+0x1bfb>
				assert(pgdir[i] & PTE_P);
f01030e9:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01030ec:	f6 c2 01             	test   $0x1,%dl
f01030ef:	75 24                	jne    f0103115 <mem_init+0x1bd2>
f01030f1:	c7 44 24 0c be 7d 10 	movl   $0xf0107dbe,0xc(%esp)
f01030f8:	f0 
f01030f9:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0103100:	f0 
f0103101:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f0103108:	00 
f0103109:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0103110:	e8 2b cf ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0103115:	f6 c2 02             	test   $0x2,%dl
f0103118:	75 4e                	jne    f0103168 <mem_init+0x1c25>
f010311a:	c7 44 24 0c cf 7d 10 	movl   $0xf0107dcf,0xc(%esp)
f0103121:	f0 
f0103122:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0103129:	f0 
f010312a:	c7 44 24 04 b4 03 00 	movl   $0x3b4,0x4(%esp)
f0103131:	00 
f0103132:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0103139:	e8 02 cf ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] == 0);
f010313e:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0103142:	74 24                	je     f0103168 <mem_init+0x1c25>
f0103144:	c7 44 24 0c e0 7d 10 	movl   $0xf0107de0,0xc(%esp)
f010314b:	f0 
f010314c:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0103153:	f0 
f0103154:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f010315b:	00 
f010315c:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0103163:	e8 d8 ce ff ff       	call   f0100040 <_panic>
	for (i = 0; i < NPDENTRIES; i++) {
f0103168:	83 c0 01             	add    $0x1,%eax
f010316b:	3d 00 04 00 00       	cmp    $0x400,%eax
f0103170:	0f 85 33 ff ff ff    	jne    f01030a9 <mem_init+0x1b66>
	cprintf("check_kern_pgdir() succeeded!\n");
f0103176:	c7 04 24 b0 79 10 f0 	movl   $0xf01079b0,(%esp)
f010317d:	e8 e1 0d 00 00       	call   f0103f63 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0103182:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0103187:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010318c:	77 20                	ja     f01031ae <mem_init+0x1c6b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010318e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103192:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0103199:	f0 
f010319a:	c7 44 24 04 f3 00 00 	movl   $0xf3,0x4(%esp)
f01031a1:	00 
f01031a2:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01031a9:	e8 92 ce ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01031ae:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01031b3:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f01031b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01031bb:	e8 80 da ff ff       	call   f0100c40 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01031c0:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f01031c3:	83 e0 f3             	and    $0xfffffff3,%eax
f01031c6:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01031cb:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01031ce:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01031d5:	e8 18 df ff ff       	call   f01010f2 <page_alloc>
f01031da:	89 c3                	mov    %eax,%ebx
f01031dc:	85 c0                	test   %eax,%eax
f01031de:	75 24                	jne    f0103204 <mem_init+0x1cc1>
f01031e0:	c7 44 24 0c ca 7b 10 	movl   $0xf0107bca,0xc(%esp)
f01031e7:	f0 
f01031e8:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01031ef:	f0 
f01031f0:	c7 44 24 04 8e 04 00 	movl   $0x48e,0x4(%esp)
f01031f7:	00 
f01031f8:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01031ff:	e8 3c ce ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0103204:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010320b:	e8 e2 de ff ff       	call   f01010f2 <page_alloc>
f0103210:	89 c7                	mov    %eax,%edi
f0103212:	85 c0                	test   %eax,%eax
f0103214:	75 24                	jne    f010323a <mem_init+0x1cf7>
f0103216:	c7 44 24 0c e0 7b 10 	movl   $0xf0107be0,0xc(%esp)
f010321d:	f0 
f010321e:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0103225:	f0 
f0103226:	c7 44 24 04 8f 04 00 	movl   $0x48f,0x4(%esp)
f010322d:	00 
f010322e:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0103235:	e8 06 ce ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010323a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103241:	e8 ac de ff ff       	call   f01010f2 <page_alloc>
f0103246:	89 c6                	mov    %eax,%esi
f0103248:	85 c0                	test   %eax,%eax
f010324a:	75 24                	jne    f0103270 <mem_init+0x1d2d>
f010324c:	c7 44 24 0c f6 7b 10 	movl   $0xf0107bf6,0xc(%esp)
f0103253:	f0 
f0103254:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010325b:	f0 
f010325c:	c7 44 24 04 90 04 00 	movl   $0x490,0x4(%esp)
f0103263:	00 
f0103264:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010326b:	e8 d0 cd ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0103270:	89 1c 24             	mov    %ebx,(%esp)
f0103273:	e8 05 df ff ff       	call   f010117d <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0103278:	89 f8                	mov    %edi,%eax
f010327a:	e8 0d d9 ff ff       	call   f0100b8c <page2kva>
f010327f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103286:	00 
f0103287:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010328e:	00 
f010328f:	89 04 24             	mov    %eax,(%esp)
f0103292:	e8 f0 2b 00 00       	call   f0105e87 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0103297:	89 f0                	mov    %esi,%eax
f0103299:	e8 ee d8 ff ff       	call   f0100b8c <page2kva>
f010329e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01032a5:	00 
f01032a6:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01032ad:	00 
f01032ae:	89 04 24             	mov    %eax,(%esp)
f01032b1:	e8 d1 2b 00 00       	call   f0105e87 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01032b6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01032bd:	00 
f01032be:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01032c5:	00 
f01032c6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032ca:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f01032cf:	89 04 24             	mov    %eax,(%esp)
f01032d2:	e8 5c e1 ff ff       	call   f0101433 <page_insert>
	assert(pp1->pp_ref == 1);
f01032d7:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01032dc:	74 24                	je     f0103302 <mem_init+0x1dbf>
f01032de:	c7 44 24 0c c7 7c 10 	movl   $0xf0107cc7,0xc(%esp)
f01032e5:	f0 
f01032e6:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01032ed:	f0 
f01032ee:	c7 44 24 04 95 04 00 	movl   $0x495,0x4(%esp)
f01032f5:	00 
f01032f6:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01032fd:	e8 3e cd ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103302:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0103309:	01 01 01 
f010330c:	74 24                	je     f0103332 <mem_init+0x1def>
f010330e:	c7 44 24 0c d0 79 10 	movl   $0xf01079d0,0xc(%esp)
f0103315:	f0 
f0103316:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010331d:	f0 
f010331e:	c7 44 24 04 96 04 00 	movl   $0x496,0x4(%esp)
f0103325:	00 
f0103326:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010332d:	e8 0e cd ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0103332:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103339:	00 
f010333a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103341:	00 
f0103342:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103346:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f010334b:	89 04 24             	mov    %eax,(%esp)
f010334e:	e8 e0 e0 ff ff       	call   f0101433 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103353:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010335a:	02 02 02 
f010335d:	74 24                	je     f0103383 <mem_init+0x1e40>
f010335f:	c7 44 24 0c f4 79 10 	movl   $0xf01079f4,0xc(%esp)
f0103366:	f0 
f0103367:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f010336e:	f0 
f010336f:	c7 44 24 04 98 04 00 	movl   $0x498,0x4(%esp)
f0103376:	00 
f0103377:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f010337e:	e8 bd cc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0103383:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103388:	74 24                	je     f01033ae <mem_init+0x1e6b>
f010338a:	c7 44 24 0c e9 7c 10 	movl   $0xf0107ce9,0xc(%esp)
f0103391:	f0 
f0103392:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0103399:	f0 
f010339a:	c7 44 24 04 99 04 00 	movl   $0x499,0x4(%esp)
f01033a1:	00 
f01033a2:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01033a9:	e8 92 cc ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01033ae:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01033b3:	74 24                	je     f01033d9 <mem_init+0x1e96>
f01033b5:	c7 44 24 0c 53 7d 10 	movl   $0xf0107d53,0xc(%esp)
f01033bc:	f0 
f01033bd:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01033c4:	f0 
f01033c5:	c7 44 24 04 9a 04 00 	movl   $0x49a,0x4(%esp)
f01033cc:	00 
f01033cd:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01033d4:	e8 67 cc ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01033d9:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01033e0:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01033e3:	89 f0                	mov    %esi,%eax
f01033e5:	e8 a2 d7 ff ff       	call   f0100b8c <page2kva>
f01033ea:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f01033f0:	74 24                	je     f0103416 <mem_init+0x1ed3>
f01033f2:	c7 44 24 0c 18 7a 10 	movl   $0xf0107a18,0xc(%esp)
f01033f9:	f0 
f01033fa:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0103401:	f0 
f0103402:	c7 44 24 04 9c 04 00 	movl   $0x49c,0x4(%esp)
f0103409:	00 
f010340a:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0103411:	e8 2a cc ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0103416:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010341d:	00 
f010341e:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f0103423:	89 04 24             	mov    %eax,(%esp)
f0103426:	e8 bf df ff ff       	call   f01013ea <page_remove>
	assert(pp2->pp_ref == 0);
f010342b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0103430:	74 24                	je     f0103456 <mem_init+0x1f13>
f0103432:	c7 44 24 0c 21 7d 10 	movl   $0xf0107d21,0xc(%esp)
f0103439:	f0 
f010343a:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0103441:	f0 
f0103442:	c7 44 24 04 9e 04 00 	movl   $0x49e,0x4(%esp)
f0103449:	00 
f010344a:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0103451:	e8 ea cb ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103456:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
f010345b:	8b 08                	mov    (%eax),%ecx
f010345d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	return (pp - pages) << PGSHIFT;
f0103463:	89 da                	mov    %ebx,%edx
f0103465:	2b 15 90 0e 23 f0    	sub    0xf0230e90,%edx
f010346b:	c1 fa 03             	sar    $0x3,%edx
f010346e:	c1 e2 0c             	shl    $0xc,%edx
f0103471:	39 d1                	cmp    %edx,%ecx
f0103473:	74 24                	je     f0103499 <mem_init+0x1f56>
f0103475:	c7 44 24 0c a0 73 10 	movl   $0xf01073a0,0xc(%esp)
f010347c:	f0 
f010347d:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0103484:	f0 
f0103485:	c7 44 24 04 a1 04 00 	movl   $0x4a1,0x4(%esp)
f010348c:	00 
f010348d:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f0103494:	e8 a7 cb ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0103499:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010349f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01034a4:	74 24                	je     f01034ca <mem_init+0x1f87>
f01034a6:	c7 44 24 0c d8 7c 10 	movl   $0xf0107cd8,0xc(%esp)
f01034ad:	f0 
f01034ae:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01034b5:	f0 
f01034b6:	c7 44 24 04 a3 04 00 	movl   $0x4a3,0x4(%esp)
f01034bd:	00 
f01034be:	c7 04 24 b3 7a 10 f0 	movl   $0xf0107ab3,(%esp)
f01034c5:	e8 76 cb ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01034ca:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01034d0:	89 1c 24             	mov    %ebx,(%esp)
f01034d3:	e8 a5 dc ff ff       	call   f010117d <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01034d8:	c7 04 24 44 7a 10 f0 	movl   $0xf0107a44,(%esp)
f01034df:	e8 7f 0a 00 00       	call   f0103f63 <cprintf>
f01034e4:	eb 1f                	jmp    f0103505 <mem_init+0x1fc2>
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f01034e6:	89 da                	mov    %ebx,%edx
f01034e8:	89 f8                	mov    %edi,%eax
f01034ea:	e8 e2 d6 ff ff       	call   f0100bd1 <check_va2pa>
f01034ef:	90                   	nop
f01034f0:	e9 0b fb ff ff       	jmp    f0103000 <mem_init+0x1abd>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01034f5:	89 da                	mov    %ebx,%edx
f01034f7:	89 f8                	mov    %edi,%eax
f01034f9:	e8 d3 d6 ff ff       	call   f0100bd1 <check_va2pa>
f01034fe:	66 90                	xchg   %ax,%ax
f0103500:	e9 0a fa ff ff       	jmp    f0102f0f <mem_init+0x19cc>
}
f0103505:	83 c4 4c             	add    $0x4c,%esp
f0103508:	5b                   	pop    %ebx
f0103509:	5e                   	pop    %esi
f010350a:	5f                   	pop    %edi
f010350b:	5d                   	pop    %ebp
f010350c:	c3                   	ret    

f010350d <user_mem_check>:
{
f010350d:	55                   	push   %ebp
f010350e:	89 e5                	mov    %esp,%ebp
f0103510:	57                   	push   %edi
f0103511:	56                   	push   %esi
f0103512:	53                   	push   %ebx
f0103513:	83 ec 2c             	sub    $0x2c,%esp
f0103516:	8b 75 08             	mov    0x8(%ebp),%esi
f0103519:	8b 45 0c             	mov    0xc(%ebp),%eax
	user_mem_check_addr = (uintptr_t) va;
f010351c:	a3 3c 02 23 f0       	mov    %eax,0xf023023c
	uintptr_t upperAddress = ROUNDUP((uintptr_t) va + len, PGSIZE);
f0103521:	8b 55 10             	mov    0x10(%ebp),%edx
f0103524:	8d 84 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%eax
f010352b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0103530:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (upperAddress >= ULIM)
f0103533:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0103538:	77 55                	ja     f010358f <user_mem_check+0x82>
		struct PageInfo *cPage = page_lookup(env->env_pgdir, (void *)user_mem_check_addr, &ptEntry);
f010353a:	8d 7d e4             	lea    -0x1c(%ebp),%edi
		if((*ptEntry & (perm | PTE_P)) != (perm | PTE_P))
f010353d:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0103540:	83 cb 01             	or     $0x1,%ebx
f0103543:	eb 39                	jmp    f010357e <user_mem_check+0x71>
		struct PageInfo *cPage = page_lookup(env->env_pgdir, (void *)user_mem_check_addr, &ptEntry);
f0103545:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103549:	89 44 24 04          	mov    %eax,0x4(%esp)
f010354d:	8b 46 60             	mov    0x60(%esi),%eax
f0103550:	89 04 24             	mov    %eax,(%esp)
f0103553:	e8 e5 dd ff ff       	call   f010133d <page_lookup>
		if((*ptEntry & (perm | PTE_P)) != (perm | PTE_P))
f0103558:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010355b:	89 d9                	mov    %ebx,%ecx
f010355d:	23 08                	and    (%eax),%ecx
f010355f:	39 cb                	cmp    %ecx,%ebx
f0103561:	74 07                	je     f010356a <user_mem_check+0x5d>
			return -E_FAULT;
f0103563:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0103568:	eb 2a                	jmp    f0103594 <user_mem_check+0x87>
		user_mem_check_addr = ROUNDDOWN(user_mem_check_addr + PGSIZE, PGSIZE);
f010356a:	a1 3c 02 23 f0       	mov    0xf023023c,%eax
f010356f:	05 00 10 00 00       	add    $0x1000,%eax
f0103574:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0103579:	a3 3c 02 23 f0       	mov    %eax,0xf023023c
	while (user_mem_check_addr < upperAddress)
f010357e:	a1 3c 02 23 f0       	mov    0xf023023c,%eax
f0103583:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0103586:	77 bd                	ja     f0103545 <user_mem_check+0x38>
	return 0;
f0103588:	b8 00 00 00 00       	mov    $0x0,%eax
f010358d:	eb 05                	jmp    f0103594 <user_mem_check+0x87>
		return -E_FAULT;
f010358f:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
}
f0103594:	83 c4 2c             	add    $0x2c,%esp
f0103597:	5b                   	pop    %ebx
f0103598:	5e                   	pop    %esi
f0103599:	5f                   	pop    %edi
f010359a:	5d                   	pop    %ebp
f010359b:	c3                   	ret    

f010359c <user_mem_assert>:
{
f010359c:	55                   	push   %ebp
f010359d:	89 e5                	mov    %esp,%ebp
f010359f:	53                   	push   %ebx
f01035a0:	83 ec 14             	sub    $0x14,%esp
f01035a3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01035a6:	8b 45 14             	mov    0x14(%ebp),%eax
f01035a9:	83 c8 04             	or     $0x4,%eax
f01035ac:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035b0:	8b 45 10             	mov    0x10(%ebp),%eax
f01035b3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035b7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035be:	89 1c 24             	mov    %ebx,(%esp)
f01035c1:	e8 47 ff ff ff       	call   f010350d <user_mem_check>
f01035c6:	85 c0                	test   %eax,%eax
f01035c8:	79 24                	jns    f01035ee <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f01035ca:	a1 3c 02 23 f0       	mov    0xf023023c,%eax
f01035cf:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035d3:	8b 43 48             	mov    0x48(%ebx),%eax
f01035d6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035da:	c7 04 24 70 7a 10 f0 	movl   $0xf0107a70,(%esp)
f01035e1:	e8 7d 09 00 00       	call   f0103f63 <cprintf>
		env_destroy(env);	// may not return
f01035e6:	89 1c 24             	mov    %ebx,(%esp)
f01035e9:	e8 9c 06 00 00       	call   f0103c8a <env_destroy>
}
f01035ee:	83 c4 14             	add    $0x14,%esp
f01035f1:	5b                   	pop    %ebx
f01035f2:	5d                   	pop    %ebp
f01035f3:	c3                   	ret    

f01035f4 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01035f4:	55                   	push   %ebp
f01035f5:	89 e5                	mov    %esp,%ebp
f01035f7:	57                   	push   %edi
f01035f8:	56                   	push   %esi
f01035f9:	53                   	push   %ebx
f01035fa:	83 ec 1c             	sub    $0x1c,%esp
f01035fd:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t beginning = ROUNDDOWN((uintptr_t) va, PGSIZE);
f01035ff:	89 d3                	mov    %edx,%ebx
f0103601:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t ending = ROUNDUP((uintptr_t) va + len, PGSIZE);
f0103607:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010360e:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while(beginning < ending)
f0103614:	eb 4d                	jmp    f0103663 <region_alloc+0x6f>
	{
		struct PageInfo* pp = page_alloc(0);
f0103616:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010361d:	e8 d0 da ff ff       	call   f01010f2 <page_alloc>

		if(pp == NULL)
f0103622:	85 c0                	test   %eax,%eax
f0103624:	75 1c                	jne    f0103642 <region_alloc+0x4e>
		{
			panic("page allocation bad");
f0103626:	c7 44 24 08 ee 7d 10 	movl   $0xf0107dee,0x8(%esp)
f010362d:	f0 
f010362e:	c7 44 24 04 31 01 00 	movl   $0x131,0x4(%esp)
f0103635:	00 
f0103636:	c7 04 24 02 7e 10 f0 	movl   $0xf0107e02,(%esp)
f010363d:	e8 fe c9 ff ff       	call   f0100040 <_panic>
		}

		page_insert(e->env_pgdir, pp, (void*)beginning, PTE_U | PTE_W | PTE_P);
f0103642:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
f0103649:	00 
f010364a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010364e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103652:	8b 47 60             	mov    0x60(%edi),%eax
f0103655:	89 04 24             	mov    %eax,(%esp)
f0103658:	e8 d6 dd ff ff       	call   f0101433 <page_insert>
		beginning += PGSIZE;
f010365d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	while(beginning < ending)
f0103663:	39 f3                	cmp    %esi,%ebx
f0103665:	72 af                	jb     f0103616 <region_alloc+0x22>
	}
}
f0103667:	83 c4 1c             	add    $0x1c,%esp
f010366a:	5b                   	pop    %ebx
f010366b:	5e                   	pop    %esi
f010366c:	5f                   	pop    %edi
f010366d:	5d                   	pop    %ebp
f010366e:	c3                   	ret    

f010366f <envid2env>:
{
f010366f:	55                   	push   %ebp
f0103670:	89 e5                	mov    %esp,%ebp
f0103672:	56                   	push   %esi
f0103673:	53                   	push   %ebx
f0103674:	8b 45 08             	mov    0x8(%ebp),%eax
f0103677:	8b 55 10             	mov    0x10(%ebp),%edx
	if (envid == 0) {
f010367a:	85 c0                	test   %eax,%eax
f010367c:	75 1a                	jne    f0103698 <envid2env+0x29>
		*env_store = curenv;
f010367e:	e8 56 2e 00 00       	call   f01064d9 <cpunum>
f0103683:	6b c0 74             	imul   $0x74,%eax,%eax
f0103686:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f010368c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010368f:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103691:	b8 00 00 00 00       	mov    $0x0,%eax
f0103696:	eb 70                	jmp    f0103708 <envid2env+0x99>
	e = &envs[ENVX(envid)];
f0103698:	89 c3                	mov    %eax,%ebx
f010369a:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f01036a0:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f01036a3:	03 1d 48 02 23 f0    	add    0xf0230248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01036a9:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f01036ad:	74 05                	je     f01036b4 <envid2env+0x45>
f01036af:	39 43 48             	cmp    %eax,0x48(%ebx)
f01036b2:	74 10                	je     f01036c4 <envid2env+0x55>
		*env_store = 0;
f01036b4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036b7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01036bd:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01036c2:	eb 44                	jmp    f0103708 <envid2env+0x99>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01036c4:	84 d2                	test   %dl,%dl
f01036c6:	74 36                	je     f01036fe <envid2env+0x8f>
f01036c8:	e8 0c 2e 00 00       	call   f01064d9 <cpunum>
f01036cd:	6b c0 74             	imul   $0x74,%eax,%eax
f01036d0:	39 98 28 10 23 f0    	cmp    %ebx,-0xfdcefd8(%eax)
f01036d6:	74 26                	je     f01036fe <envid2env+0x8f>
f01036d8:	8b 73 4c             	mov    0x4c(%ebx),%esi
f01036db:	e8 f9 2d 00 00       	call   f01064d9 <cpunum>
f01036e0:	6b c0 74             	imul   $0x74,%eax,%eax
f01036e3:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f01036e9:	3b 70 48             	cmp    0x48(%eax),%esi
f01036ec:	74 10                	je     f01036fe <envid2env+0x8f>
		*env_store = 0;
f01036ee:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036f1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01036f7:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01036fc:	eb 0a                	jmp    f0103708 <envid2env+0x99>
	*env_store = e;
f01036fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103701:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103703:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103708:	5b                   	pop    %ebx
f0103709:	5e                   	pop    %esi
f010370a:	5d                   	pop    %ebp
f010370b:	c3                   	ret    

f010370c <env_init_percpu>:
{
f010370c:	55                   	push   %ebp
f010370d:	89 e5                	mov    %esp,%ebp
	asm volatile("lgdt (%0)" : : "r" (p));
f010370f:	b8 20 13 12 f0       	mov    $0xf0121320,%eax
f0103714:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0103717:	b8 23 00 00 00       	mov    $0x23,%eax
f010371c:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f010371e:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0103720:	b0 10                	mov    $0x10,%al
f0103722:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0103724:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0103726:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0103728:	ea 2f 37 10 f0 08 00 	ljmp   $0x8,$0xf010372f
	asm volatile("lldt %0" : : "r" (sel));
f010372f:	b0 00                	mov    $0x0,%al
f0103731:	0f 00 d0             	lldt   %ax
}
f0103734:	5d                   	pop    %ebp
f0103735:	c3                   	ret    

f0103736 <env_init>:
{
f0103736:	a1 48 02 23 f0       	mov    0xf0230248,%eax
f010373b:	83 c0 7c             	add    $0x7c,%eax
		envs[i].env_id = 0;
f010373e:	ba ff 03 00 00       	mov    $0x3ff,%edx
f0103743:	c7 40 cc 00 00 00 00 	movl   $0x0,-0x34(%eax)
		envs[i].env_link = &envs[i + 1];
f010374a:	89 40 c8             	mov    %eax,-0x38(%eax)
f010374d:	83 c0 7c             	add    $0x7c,%eax
	for (i = 0; i < NENV - 1; i++)
f0103750:	83 ea 01             	sub    $0x1,%edx
f0103753:	75 ee                	jne    f0103743 <env_init+0xd>
{
f0103755:	55                   	push   %ebp
f0103756:	89 e5                	mov    %esp,%ebp
	env_free_list = &envs[0];
f0103758:	a1 48 02 23 f0       	mov    0xf0230248,%eax
f010375d:	a3 4c 02 23 f0       	mov    %eax,0xf023024c
	envs[NENV - 1].env_link = NULL;
f0103762:	c7 80 c8 ef 01 00 00 	movl   $0x0,0x1efc8(%eax)
f0103769:	00 00 00 
	env_init_percpu();
f010376c:	e8 9b ff ff ff       	call   f010370c <env_init_percpu>
}
f0103771:	5d                   	pop    %ebp
f0103772:	c3                   	ret    

f0103773 <env_alloc>:
{
f0103773:	55                   	push   %ebp
f0103774:	89 e5                	mov    %esp,%ebp
f0103776:	56                   	push   %esi
f0103777:	53                   	push   %ebx
f0103778:	83 ec 10             	sub    $0x10,%esp
	if (!(e = env_free_list))
f010377b:	8b 1d 4c 02 23 f0    	mov    0xf023024c,%ebx
f0103781:	85 db                	test   %ebx,%ebx
f0103783:	0f 84 89 01 00 00    	je     f0103912 <env_alloc+0x19f>
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103789:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103790:	e8 5d d9 ff ff       	call   f01010f2 <page_alloc>
f0103795:	89 c6                	mov    %eax,%esi
f0103797:	85 c0                	test   %eax,%eax
f0103799:	0f 84 7a 01 00 00    	je     f0103919 <env_alloc+0x1a6>
f010379f:	2b 05 90 0e 23 f0    	sub    0xf0230e90,%eax
f01037a5:	c1 f8 03             	sar    $0x3,%eax
f01037a8:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01037ab:	89 c2                	mov    %eax,%edx
f01037ad:	c1 ea 0c             	shr    $0xc,%edx
f01037b0:	3b 15 88 0e 23 f0    	cmp    0xf0230e88,%edx
f01037b6:	72 20                	jb     f01037d8 <env_alloc+0x65>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01037b8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01037bc:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f01037c3:	f0 
f01037c4:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01037cb:	00 
f01037cc:	c7 04 24 a5 7a 10 f0 	movl   $0xf0107aa5,(%esp)
f01037d3:	e8 68 c8 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01037d8:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = page2kva(p);
f01037dd:	89 43 60             	mov    %eax,0x60(%ebx)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f01037e0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01037e7:	00 
f01037e8:	8b 15 8c 0e 23 f0    	mov    0xf0230e8c,%edx
f01037ee:	89 54 24 04          	mov    %edx,0x4(%esp)
f01037f2:	89 04 24             	mov    %eax,(%esp)
f01037f5:	e8 42 27 00 00       	call   f0105f3c <memcpy>
	p->pp_ref++;
f01037fa:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01037ff:	8b 43 60             	mov    0x60(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f0103802:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103807:	77 20                	ja     f0103829 <env_alloc+0xb6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103809:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010380d:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0103814:	f0 
f0103815:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
f010381c:	00 
f010381d:	c7 04 24 02 7e 10 f0 	movl   $0xf0107e02,(%esp)
f0103824:	e8 17 c8 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103829:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010382f:	83 ca 05             	or     $0x5,%edx
f0103832:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103838:	8b 43 48             	mov    0x48(%ebx),%eax
f010383b:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103840:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103845:	ba 00 10 00 00       	mov    $0x1000,%edx
f010384a:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010384d:	89 da                	mov    %ebx,%edx
f010384f:	2b 15 48 02 23 f0    	sub    0xf0230248,%edx
f0103855:	c1 fa 02             	sar    $0x2,%edx
f0103858:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f010385e:	09 d0                	or     %edx,%eax
f0103860:	89 43 48             	mov    %eax,0x48(%ebx)
	e->env_parent_id = parent_id;
f0103863:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103866:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103869:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103870:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103877:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010387e:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103885:	00 
f0103886:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010388d:	00 
f010388e:	89 1c 24             	mov    %ebx,(%esp)
f0103891:	e8 f1 25 00 00       	call   f0105e87 <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f0103896:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010389c:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01038a2:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01038a8:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01038af:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	e->env_pgfault_upcall = 0;
f01038b5:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)
	e->env_ipc_recving = 0;
f01038bc:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	env_free_list = e->env_link;
f01038c0:	8b 43 44             	mov    0x44(%ebx),%eax
f01038c3:	a3 4c 02 23 f0       	mov    %eax,0xf023024c
	*newenv_store = e;
f01038c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01038cb:	89 18                	mov    %ebx,(%eax)
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01038cd:	8b 5b 48             	mov    0x48(%ebx),%ebx
f01038d0:	e8 04 2c 00 00       	call   f01064d9 <cpunum>
f01038d5:	6b c0 74             	imul   $0x74,%eax,%eax
f01038d8:	ba 00 00 00 00       	mov    $0x0,%edx
f01038dd:	83 b8 28 10 23 f0 00 	cmpl   $0x0,-0xfdcefd8(%eax)
f01038e4:	74 11                	je     f01038f7 <env_alloc+0x184>
f01038e6:	e8 ee 2b 00 00       	call   f01064d9 <cpunum>
f01038eb:	6b c0 74             	imul   $0x74,%eax,%eax
f01038ee:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f01038f4:	8b 50 48             	mov    0x48(%eax),%edx
f01038f7:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01038fb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01038ff:	c7 04 24 0d 7e 10 f0 	movl   $0xf0107e0d,(%esp)
f0103906:	e8 58 06 00 00       	call   f0103f63 <cprintf>
	return 0;
f010390b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103910:	eb 0c                	jmp    f010391e <env_alloc+0x1ab>
		return -E_NO_FREE_ENV;
f0103912:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103917:	eb 05                	jmp    f010391e <env_alloc+0x1ab>
		return -E_NO_MEM;
f0103919:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f010391e:	83 c4 10             	add    $0x10,%esp
f0103921:	5b                   	pop    %ebx
f0103922:	5e                   	pop    %esi
f0103923:	5d                   	pop    %ebp
f0103924:	c3                   	ret    

f0103925 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103925:	55                   	push   %ebp
f0103926:	89 e5                	mov    %esp,%ebp
f0103928:	57                   	push   %edi
f0103929:	56                   	push   %esi
f010392a:	53                   	push   %ebx
f010392b:	83 ec 3c             	sub    $0x3c,%esp
f010392e:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env* environ;
	int e = env_alloc(&environ, 0);
f0103931:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103938:	00 
f0103939:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010393c:	89 04 24             	mov    %eax,(%esp)
f010393f:	e8 2f fe ff ff       	call   f0103773 <env_alloc>
	if (e != 0)
f0103944:	85 c0                	test   %eax,%eax
f0103946:	74 20                	je     f0103968 <env_create+0x43>
	{
		panic("env_alloc: %e", e);
f0103948:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010394c:	c7 44 24 08 22 7e 10 	movl   $0xf0107e22,0x8(%esp)
f0103953:	f0 
f0103954:	c7 44 24 04 9c 01 00 	movl   $0x19c,0x4(%esp)
f010395b:	00 
f010395c:	c7 04 24 02 7e 10 f0 	movl   $0xf0107e02,(%esp)
f0103963:	e8 d8 c6 ff ff       	call   f0100040 <_panic>
	}
	load_icode(environ, binary);
f0103968:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010396b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	struct Proghdr* progHead = (struct Proghdr*) (binary + elf->e_phoff);
f010396e:	89 fb                	mov    %edi,%ebx
f0103970:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr* elfProgHead = progHead + elf->e_phnum;
f0103973:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103977:	c1 e6 05             	shl    $0x5,%esi
f010397a:	01 de                	add    %ebx,%esi
	lcr3(PADDR(e->env_pgdir));
f010397c:	8b 40 60             	mov    0x60(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010397f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103984:	77 20                	ja     f01039a6 <env_create+0x81>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103986:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010398a:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0103991:	f0 
f0103992:	c7 44 24 04 73 01 00 	movl   $0x173,0x4(%esp)
f0103999:	00 
f010399a:	c7 04 24 02 7e 10 f0 	movl   $0xf0107e02,(%esp)
f01039a1:	e8 9a c6 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01039a6:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01039ab:	0f 22 d8             	mov    %eax,%cr3
	if (elf->e_magic != ELF_MAGIC)
f01039ae:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01039b4:	74 6c                	je     f0103a22 <env_create+0xfd>
		panic("bad ELF file");
f01039b6:	c7 44 24 08 30 7e 10 	movl   $0xf0107e30,0x8(%esp)
f01039bd:	f0 
f01039be:	c7 44 24 04 77 01 00 	movl   $0x177,0x4(%esp)
f01039c5:	00 
f01039c6:	c7 04 24 02 7e 10 f0 	movl   $0xf0107e02,(%esp)
f01039cd:	e8 6e c6 ff ff       	call   f0100040 <_panic>
		if(progHead->p_type == ELF_PROG_LOAD)
f01039d2:	83 3b 01             	cmpl   $0x1,(%ebx)
f01039d5:	75 48                	jne    f0103a1f <env_create+0xfa>
			region_alloc(e, (void*)progHead->p_va, progHead->p_memsz);
f01039d7:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01039da:	8b 53 08             	mov    0x8(%ebx),%edx
f01039dd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01039e0:	e8 0f fc ff ff       	call   f01035f4 <region_alloc>
			memcpy((void*)progHead->p_va, binary + progHead->p_offset, progHead->p_filesz);
f01039e5:	8b 43 10             	mov    0x10(%ebx),%eax
f01039e8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01039ec:	89 f8                	mov    %edi,%eax
f01039ee:	03 43 04             	add    0x4(%ebx),%eax
f01039f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039f5:	8b 43 08             	mov    0x8(%ebx),%eax
f01039f8:	89 04 24             	mov    %eax,(%esp)
f01039fb:	e8 3c 25 00 00       	call   f0105f3c <memcpy>
			memset((void*)(progHead->p_va + progHead->p_filesz), 0, progHead->p_memsz - progHead->p_filesz);
f0103a00:	8b 43 10             	mov    0x10(%ebx),%eax
f0103a03:	8b 53 14             	mov    0x14(%ebx),%edx
f0103a06:	29 c2                	sub    %eax,%edx
f0103a08:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103a0c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103a13:	00 
f0103a14:	03 43 08             	add    0x8(%ebx),%eax
f0103a17:	89 04 24             	mov    %eax,(%esp)
f0103a1a:	e8 68 24 00 00       	call   f0105e87 <memset>
	for(; progHead < elfProgHead; progHead++)
f0103a1f:	83 c3 20             	add    $0x20,%ebx
f0103a22:	39 de                	cmp    %ebx,%esi
f0103a24:	77 ac                	ja     f01039d2 <env_create+0xad>
	lcr3(PADDR(kern_pgdir));
f0103a26:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0103a2b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103a30:	77 20                	ja     f0103a52 <env_create+0x12d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103a32:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103a36:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0103a3d:	f0 
f0103a3e:	c7 44 24 04 84 01 00 	movl   $0x184,0x4(%esp)
f0103a45:	00 
f0103a46:	c7 04 24 02 7e 10 f0 	movl   $0xf0107e02,(%esp)
f0103a4d:	e8 ee c5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103a52:	05 00 00 00 10       	add    $0x10000000,%eax
f0103a57:	0f 22 d8             	mov    %eax,%cr3
	region_alloc(e, (void*) USTACKTOP-PGSIZE, PGSIZE);
f0103a5a:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103a5f:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103a64:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0103a67:	89 f0                	mov    %esi,%eax
f0103a69:	e8 86 fb ff ff       	call   f01035f4 <region_alloc>
	e->env_tf.tf_eip = elf->e_entry;
f0103a6e:	8b 47 18             	mov    0x18(%edi),%eax
f0103a71:	89 46 30             	mov    %eax,0x30(%esi)

	environ->env_type = type;
f0103a74:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a77:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a7a:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103a7d:	83 c4 3c             	add    $0x3c,%esp
f0103a80:	5b                   	pop    %ebx
f0103a81:	5e                   	pop    %esi
f0103a82:	5f                   	pop    %edi
f0103a83:	5d                   	pop    %ebp
f0103a84:	c3                   	ret    

f0103a85 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103a85:	55                   	push   %ebp
f0103a86:	89 e5                	mov    %esp,%ebp
f0103a88:	57                   	push   %edi
f0103a89:	56                   	push   %esi
f0103a8a:	53                   	push   %ebx
f0103a8b:	83 ec 2c             	sub    $0x2c,%esp
f0103a8e:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103a91:	e8 43 2a 00 00       	call   f01064d9 <cpunum>
f0103a96:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a99:	39 b8 28 10 23 f0    	cmp    %edi,-0xfdcefd8(%eax)
f0103a9f:	75 34                	jne    f0103ad5 <env_free+0x50>
		lcr3(PADDR(kern_pgdir));
f0103aa1:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0103aa6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103aab:	77 20                	ja     f0103acd <env_free+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103aad:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103ab1:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0103ab8:	f0 
f0103ab9:	c7 44 24 04 b1 01 00 	movl   $0x1b1,0x4(%esp)
f0103ac0:	00 
f0103ac1:	c7 04 24 02 7e 10 f0 	movl   $0xf0107e02,(%esp)
f0103ac8:	e8 73 c5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103acd:	05 00 00 00 10       	add    $0x10000000,%eax
f0103ad2:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103ad5:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103ad8:	e8 fc 29 00 00       	call   f01064d9 <cpunum>
f0103add:	6b d0 74             	imul   $0x74,%eax,%edx
f0103ae0:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ae5:	83 ba 28 10 23 f0 00 	cmpl   $0x0,-0xfdcefd8(%edx)
f0103aec:	74 11                	je     f0103aff <env_free+0x7a>
f0103aee:	e8 e6 29 00 00       	call   f01064d9 <cpunum>
f0103af3:	6b c0 74             	imul   $0x74,%eax,%eax
f0103af6:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0103afc:	8b 40 48             	mov    0x48(%eax),%eax
f0103aff:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103b03:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b07:	c7 04 24 3d 7e 10 f0 	movl   $0xf0107e3d,(%esp)
f0103b0e:	e8 50 04 00 00       	call   f0103f63 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103b13:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103b1a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103b1d:	89 c8                	mov    %ecx,%eax
f0103b1f:	c1 e0 02             	shl    $0x2,%eax
f0103b22:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103b25:	8b 47 60             	mov    0x60(%edi),%eax
f0103b28:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f0103b2b:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103b31:	0f 84 b7 00 00 00    	je     f0103bee <env_free+0x169>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103b37:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f0103b3d:	89 f0                	mov    %esi,%eax
f0103b3f:	c1 e8 0c             	shr    $0xc,%eax
f0103b42:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103b45:	3b 05 88 0e 23 f0    	cmp    0xf0230e88,%eax
f0103b4b:	72 20                	jb     f0103b6d <env_free+0xe8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103b4d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103b51:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f0103b58:	f0 
f0103b59:	c7 44 24 04 c0 01 00 	movl   $0x1c0,0x4(%esp)
f0103b60:	00 
f0103b61:	c7 04 24 02 7e 10 f0 	movl   $0xf0107e02,(%esp)
f0103b68:	e8 d3 c4 ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103b6d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b70:	c1 e0 16             	shl    $0x16,%eax
f0103b73:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103b76:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103b7b:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103b82:	01 
f0103b83:	74 17                	je     f0103b9c <env_free+0x117>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103b85:	89 d8                	mov    %ebx,%eax
f0103b87:	c1 e0 0c             	shl    $0xc,%eax
f0103b8a:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103b8d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b91:	8b 47 60             	mov    0x60(%edi),%eax
f0103b94:	89 04 24             	mov    %eax,(%esp)
f0103b97:	e8 4e d8 ff ff       	call   f01013ea <page_remove>
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103b9c:	83 c3 01             	add    $0x1,%ebx
f0103b9f:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103ba5:	75 d4                	jne    f0103b7b <env_free+0xf6>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103ba7:	8b 47 60             	mov    0x60(%edi),%eax
f0103baa:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103bad:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f0103bb4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103bb7:	3b 05 88 0e 23 f0    	cmp    0xf0230e88,%eax
f0103bbd:	72 1c                	jb     f0103bdb <env_free+0x156>
		panic("pa2page called with invalid pa");
f0103bbf:	c7 44 24 08 6c 72 10 	movl   $0xf010726c,0x8(%esp)
f0103bc6:	f0 
f0103bc7:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103bce:	00 
f0103bcf:	c7 04 24 a5 7a 10 f0 	movl   $0xf0107aa5,(%esp)
f0103bd6:	e8 65 c4 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103bdb:	a1 90 0e 23 f0       	mov    0xf0230e90,%eax
f0103be0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103be3:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103be6:	89 04 24             	mov    %eax,(%esp)
f0103be9:	e8 eb d5 ff ff       	call   f01011d9 <page_decref>
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103bee:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103bf2:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103bf9:	0f 85 1b ff ff ff    	jne    f0103b1a <env_free+0x95>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103bff:	8b 47 60             	mov    0x60(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f0103c02:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103c07:	77 20                	ja     f0103c29 <env_free+0x1a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103c09:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103c0d:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0103c14:	f0 
f0103c15:	c7 44 24 04 ce 01 00 	movl   $0x1ce,0x4(%esp)
f0103c1c:	00 
f0103c1d:	c7 04 24 02 7e 10 f0 	movl   $0xf0107e02,(%esp)
f0103c24:	e8 17 c4 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103c29:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103c30:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103c35:	c1 e8 0c             	shr    $0xc,%eax
f0103c38:	3b 05 88 0e 23 f0    	cmp    0xf0230e88,%eax
f0103c3e:	72 1c                	jb     f0103c5c <env_free+0x1d7>
		panic("pa2page called with invalid pa");
f0103c40:	c7 44 24 08 6c 72 10 	movl   $0xf010726c,0x8(%esp)
f0103c47:	f0 
f0103c48:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103c4f:	00 
f0103c50:	c7 04 24 a5 7a 10 f0 	movl   $0xf0107aa5,(%esp)
f0103c57:	e8 e4 c3 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103c5c:	8b 15 90 0e 23 f0    	mov    0xf0230e90,%edx
f0103c62:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103c65:	89 04 24             	mov    %eax,(%esp)
f0103c68:	e8 6c d5 ff ff       	call   f01011d9 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103c6d:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103c74:	a1 4c 02 23 f0       	mov    0xf023024c,%eax
f0103c79:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103c7c:	89 3d 4c 02 23 f0    	mov    %edi,0xf023024c
}
f0103c82:	83 c4 2c             	add    $0x2c,%esp
f0103c85:	5b                   	pop    %ebx
f0103c86:	5e                   	pop    %esi
f0103c87:	5f                   	pop    %edi
f0103c88:	5d                   	pop    %ebp
f0103c89:	c3                   	ret    

f0103c8a <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103c8a:	55                   	push   %ebp
f0103c8b:	89 e5                	mov    %esp,%ebp
f0103c8d:	53                   	push   %ebx
f0103c8e:	83 ec 14             	sub    $0x14,%esp
f0103c91:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103c94:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103c98:	75 19                	jne    f0103cb3 <env_destroy+0x29>
f0103c9a:	e8 3a 28 00 00       	call   f01064d9 <cpunum>
f0103c9f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ca2:	39 98 28 10 23 f0    	cmp    %ebx,-0xfdcefd8(%eax)
f0103ca8:	74 09                	je     f0103cb3 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103caa:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103cb1:	eb 2f                	jmp    f0103ce2 <env_destroy+0x58>
	}

	env_free(e);
f0103cb3:	89 1c 24             	mov    %ebx,(%esp)
f0103cb6:	e8 ca fd ff ff       	call   f0103a85 <env_free>

	if (curenv == e) {
f0103cbb:	e8 19 28 00 00       	call   f01064d9 <cpunum>
f0103cc0:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cc3:	39 98 28 10 23 f0    	cmp    %ebx,-0xfdcefd8(%eax)
f0103cc9:	75 17                	jne    f0103ce2 <env_destroy+0x58>
		curenv = NULL;
f0103ccb:	e8 09 28 00 00       	call   f01064d9 <cpunum>
f0103cd0:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cd3:	c7 80 28 10 23 f0 00 	movl   $0x0,-0xfdcefd8(%eax)
f0103cda:	00 00 00 
		sched_yield();
f0103cdd:	e8 91 0e 00 00       	call   f0104b73 <sched_yield>
	}
}
f0103ce2:	83 c4 14             	add    $0x14,%esp
f0103ce5:	5b                   	pop    %ebx
f0103ce6:	5d                   	pop    %ebp
f0103ce7:	c3                   	ret    

f0103ce8 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103ce8:	55                   	push   %ebp
f0103ce9:	89 e5                	mov    %esp,%ebp
f0103ceb:	53                   	push   %ebx
f0103cec:	83 ec 14             	sub    $0x14,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103cef:	e8 e5 27 00 00       	call   f01064d9 <cpunum>
f0103cf4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cf7:	8b 98 28 10 23 f0    	mov    -0xfdcefd8(%eax),%ebx
f0103cfd:	e8 d7 27 00 00       	call   f01064d9 <cpunum>
f0103d02:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f0103d05:	8b 65 08             	mov    0x8(%ebp),%esp
f0103d08:	61                   	popa   
f0103d09:	07                   	pop    %es
f0103d0a:	1f                   	pop    %ds
f0103d0b:	83 c4 08             	add    $0x8,%esp
f0103d0e:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103d0f:	c7 44 24 08 53 7e 10 	movl   $0xf0107e53,0x8(%esp)
f0103d16:	f0 
f0103d17:	c7 44 24 04 05 02 00 	movl   $0x205,0x4(%esp)
f0103d1e:	00 
f0103d1f:	c7 04 24 02 7e 10 f0 	movl   $0xf0107e02,(%esp)
f0103d26:	e8 15 c3 ff ff       	call   f0100040 <_panic>

f0103d2b <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103d2b:	55                   	push   %ebp
f0103d2c:	89 e5                	mov    %esp,%ebp
f0103d2e:	53                   	push   %ebx
f0103d2f:	83 ec 14             	sub    $0x14,%esp
f0103d32:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && curenv->env_status == ENV_RUNNING)
f0103d35:	e8 9f 27 00 00       	call   f01064d9 <cpunum>
f0103d3a:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d3d:	83 b8 28 10 23 f0 00 	cmpl   $0x0,-0xfdcefd8(%eax)
f0103d44:	74 29                	je     f0103d6f <env_run+0x44>
f0103d46:	e8 8e 27 00 00       	call   f01064d9 <cpunum>
f0103d4b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d4e:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0103d54:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103d58:	75 15                	jne    f0103d6f <env_run+0x44>
	{
		curenv->env_status = ENV_RUNNABLE;
f0103d5a:	e8 7a 27 00 00       	call   f01064d9 <cpunum>
f0103d5f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d62:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0103d68:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}

	curenv = e;
f0103d6f:	e8 65 27 00 00       	call   f01064d9 <cpunum>
f0103d74:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d77:	89 98 28 10 23 f0    	mov    %ebx,-0xfdcefd8(%eax)
	curenv->env_status = ENV_RUNNING;
f0103d7d:	e8 57 27 00 00       	call   f01064d9 <cpunum>
f0103d82:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d85:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0103d8b:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103d92:	e8 42 27 00 00       	call   f01064d9 <cpunum>
f0103d97:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d9a:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0103da0:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));
f0103da4:	8b 43 60             	mov    0x60(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f0103da7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103dac:	77 20                	ja     f0103dce <env_run+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103dae:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103db2:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0103db9:	f0 
f0103dba:	c7 44 24 04 2b 02 00 	movl   $0x22b,0x4(%esp)
f0103dc1:	00 
f0103dc2:	c7 04 24 02 7e 10 f0 	movl   $0xf0107e02,(%esp)
f0103dc9:	e8 72 c2 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103dce:	05 00 00 00 10       	add    $0x10000000,%eax
f0103dd3:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103dd6:	c7 04 24 60 14 12 f0 	movl   $0xf0121460,(%esp)
f0103ddd:	e8 21 2a 00 00       	call   f0106803 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103de2:	f3 90                	pause  

	unlock_kernel();
	env_pop_tf(&(curenv->env_tf));
f0103de4:	e8 f0 26 00 00       	call   f01064d9 <cpunum>
f0103de9:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dec:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0103df2:	89 04 24             	mov    %eax,(%esp)
f0103df5:	e8 ee fe ff ff       	call   f0103ce8 <env_pop_tf>

f0103dfa <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103dfa:	55                   	push   %ebp
f0103dfb:	89 e5                	mov    %esp,%ebp
f0103dfd:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103e01:	ba 70 00 00 00       	mov    $0x70,%edx
f0103e06:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103e07:	b2 71                	mov    $0x71,%dl
f0103e09:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103e0a:	0f b6 c0             	movzbl %al,%eax
}
f0103e0d:	5d                   	pop    %ebp
f0103e0e:	c3                   	ret    

f0103e0f <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103e0f:	55                   	push   %ebp
f0103e10:	89 e5                	mov    %esp,%ebp
f0103e12:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103e16:	ba 70 00 00 00       	mov    $0x70,%edx
f0103e1b:	ee                   	out    %al,(%dx)
f0103e1c:	b2 71                	mov    $0x71,%dl
f0103e1e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103e21:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103e22:	5d                   	pop    %ebp
f0103e23:	c3                   	ret    

f0103e24 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103e24:	55                   	push   %ebp
f0103e25:	89 e5                	mov    %esp,%ebp
f0103e27:	56                   	push   %esi
f0103e28:	53                   	push   %ebx
f0103e29:	83 ec 10             	sub    $0x10,%esp
f0103e2c:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103e2f:	66 a3 a8 13 12 f0    	mov    %ax,0xf01213a8
	if (!didinit)
f0103e35:	80 3d 50 02 23 f0 00 	cmpb   $0x0,0xf0230250
f0103e3c:	74 4e                	je     f0103e8c <irq_setmask_8259A+0x68>
f0103e3e:	89 c6                	mov    %eax,%esi
f0103e40:	ba 21 00 00 00       	mov    $0x21,%edx
f0103e45:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103e46:	66 c1 e8 08          	shr    $0x8,%ax
f0103e4a:	b2 a1                	mov    $0xa1,%dl
f0103e4c:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103e4d:	c7 04 24 5f 7e 10 f0 	movl   $0xf0107e5f,(%esp)
f0103e54:	e8 0a 01 00 00       	call   f0103f63 <cprintf>
	for (i = 0; i < 16; i++)
f0103e59:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103e5e:	0f b7 f6             	movzwl %si,%esi
f0103e61:	f7 d6                	not    %esi
f0103e63:	0f a3 de             	bt     %ebx,%esi
f0103e66:	73 10                	jae    f0103e78 <irq_setmask_8259A+0x54>
			cprintf(" %d", i);
f0103e68:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103e6c:	c7 04 24 1b 83 10 f0 	movl   $0xf010831b,(%esp)
f0103e73:	e8 eb 00 00 00       	call   f0103f63 <cprintf>
	for (i = 0; i < 16; i++)
f0103e78:	83 c3 01             	add    $0x1,%ebx
f0103e7b:	83 fb 10             	cmp    $0x10,%ebx
f0103e7e:	75 e3                	jne    f0103e63 <irq_setmask_8259A+0x3f>
	cprintf("\n");
f0103e80:	c7 04 24 bc 7d 10 f0 	movl   $0xf0107dbc,(%esp)
f0103e87:	e8 d7 00 00 00       	call   f0103f63 <cprintf>
}
f0103e8c:	83 c4 10             	add    $0x10,%esp
f0103e8f:	5b                   	pop    %ebx
f0103e90:	5e                   	pop    %esi
f0103e91:	5d                   	pop    %ebp
f0103e92:	c3                   	ret    

f0103e93 <pic_init>:
	didinit = 1;
f0103e93:	c6 05 50 02 23 f0 01 	movb   $0x1,0xf0230250
f0103e9a:	ba 21 00 00 00       	mov    $0x21,%edx
f0103e9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ea4:	ee                   	out    %al,(%dx)
f0103ea5:	b2 a1                	mov    $0xa1,%dl
f0103ea7:	ee                   	out    %al,(%dx)
f0103ea8:	b2 20                	mov    $0x20,%dl
f0103eaa:	b8 11 00 00 00       	mov    $0x11,%eax
f0103eaf:	ee                   	out    %al,(%dx)
f0103eb0:	b2 21                	mov    $0x21,%dl
f0103eb2:	b8 20 00 00 00       	mov    $0x20,%eax
f0103eb7:	ee                   	out    %al,(%dx)
f0103eb8:	b8 04 00 00 00       	mov    $0x4,%eax
f0103ebd:	ee                   	out    %al,(%dx)
f0103ebe:	b8 03 00 00 00       	mov    $0x3,%eax
f0103ec3:	ee                   	out    %al,(%dx)
f0103ec4:	b2 a0                	mov    $0xa0,%dl
f0103ec6:	b8 11 00 00 00       	mov    $0x11,%eax
f0103ecb:	ee                   	out    %al,(%dx)
f0103ecc:	b2 a1                	mov    $0xa1,%dl
f0103ece:	b8 28 00 00 00       	mov    $0x28,%eax
f0103ed3:	ee                   	out    %al,(%dx)
f0103ed4:	b8 02 00 00 00       	mov    $0x2,%eax
f0103ed9:	ee                   	out    %al,(%dx)
f0103eda:	b8 01 00 00 00       	mov    $0x1,%eax
f0103edf:	ee                   	out    %al,(%dx)
f0103ee0:	b2 20                	mov    $0x20,%dl
f0103ee2:	b8 68 00 00 00       	mov    $0x68,%eax
f0103ee7:	ee                   	out    %al,(%dx)
f0103ee8:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103eed:	ee                   	out    %al,(%dx)
f0103eee:	b2 a0                	mov    $0xa0,%dl
f0103ef0:	b8 68 00 00 00       	mov    $0x68,%eax
f0103ef5:	ee                   	out    %al,(%dx)
f0103ef6:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103efb:	ee                   	out    %al,(%dx)
	if (irq_mask_8259A != 0xFFFF)
f0103efc:	0f b7 05 a8 13 12 f0 	movzwl 0xf01213a8,%eax
f0103f03:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103f07:	74 12                	je     f0103f1b <pic_init+0x88>
{
f0103f09:	55                   	push   %ebp
f0103f0a:	89 e5                	mov    %esp,%ebp
f0103f0c:	83 ec 18             	sub    $0x18,%esp
		irq_setmask_8259A(irq_mask_8259A);
f0103f0f:	0f b7 c0             	movzwl %ax,%eax
f0103f12:	89 04 24             	mov    %eax,(%esp)
f0103f15:	e8 0a ff ff ff       	call   f0103e24 <irq_setmask_8259A>
}
f0103f1a:	c9                   	leave  
f0103f1b:	f3 c3                	repz ret 

f0103f1d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103f1d:	55                   	push   %ebp
f0103f1e:	89 e5                	mov    %esp,%ebp
f0103f20:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103f23:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f26:	89 04 24             	mov    %eax,(%esp)
f0103f29:	e8 6c c8 ff ff       	call   f010079a <cputchar>
	*cnt++;
}
f0103f2e:	c9                   	leave  
f0103f2f:	c3                   	ret    

f0103f30 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103f30:	55                   	push   %ebp
f0103f31:	89 e5                	mov    %esp,%ebp
f0103f33:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103f36:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103f3d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f40:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103f44:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f47:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f4b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103f4e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f52:	c7 04 24 1d 3f 10 f0 	movl   $0xf0103f1d,(%esp)
f0103f59:	e8 70 18 00 00       	call   f01057ce <vprintfmt>
	return cnt;
}
f0103f5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103f61:	c9                   	leave  
f0103f62:	c3                   	ret    

f0103f63 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103f63:	55                   	push   %ebp
f0103f64:	89 e5                	mov    %esp,%ebp
f0103f66:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103f69:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103f6c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f70:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f73:	89 04 24             	mov    %eax,(%esp)
f0103f76:	e8 b5 ff ff ff       	call   f0103f30 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103f7b:	c9                   	leave  
f0103f7c:	c3                   	ret    
f0103f7d:	66 90                	xchg   %ax,%ax
f0103f7f:	90                   	nop

f0103f80 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103f80:	55                   	push   %ebp
f0103f81:	89 e5                	mov    %esp,%ebp
f0103f83:	57                   	push   %edi
f0103f84:	56                   	push   %esi
f0103f85:	53                   	push   %ebx
f0103f86:	83 ec 1c             	sub    $0x1c,%esp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	uint32_t i = cpunum();
f0103f89:	e8 4b 25 00 00       	call   f01064d9 <cpunum>
f0103f8e:	89 c6                	mov    %eax,%esi
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
f0103f90:	e8 44 25 00 00       	call   f01064d9 <cpunum>
f0103f95:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f98:	89 f2                	mov    %esi,%edx
f0103f9a:	f7 da                	neg    %edx
f0103f9c:	c1 e2 10             	shl    $0x10,%edx
f0103f9f:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0103fa5:	89 90 30 10 23 f0    	mov    %edx,-0xfdcefd0(%eax)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0103fab:	e8 29 25 00 00       	call   f01064d9 <cpunum>
f0103fb0:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fb3:	66 c7 80 34 10 23 f0 	movw   $0x10,-0xfdcefcc(%eax)
f0103fba:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + i] = SEG16(STS_T32A, (uint32_t) &(thiscpu->cpu_ts),
f0103fbc:	8d 5e 05             	lea    0x5(%esi),%ebx
f0103fbf:	e8 15 25 00 00       	call   f01064d9 <cpunum>
f0103fc4:	89 c7                	mov    %eax,%edi
f0103fc6:	e8 0e 25 00 00       	call   f01064d9 <cpunum>
f0103fcb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103fce:	e8 06 25 00 00       	call   f01064d9 <cpunum>
f0103fd3:	66 c7 04 dd 40 13 12 	movw   $0x67,-0xfedecc0(,%ebx,8)
f0103fda:	f0 67 00 
f0103fdd:	6b ff 74             	imul   $0x74,%edi,%edi
f0103fe0:	81 c7 2c 10 23 f0    	add    $0xf023102c,%edi
f0103fe6:	66 89 3c dd 42 13 12 	mov    %di,-0xfedecbe(,%ebx,8)
f0103fed:	f0 
f0103fee:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f0103ff2:	81 c2 2c 10 23 f0    	add    $0xf023102c,%edx
f0103ff8:	c1 ea 10             	shr    $0x10,%edx
f0103ffb:	88 14 dd 44 13 12 f0 	mov    %dl,-0xfedecbc(,%ebx,8)
f0104002:	c6 04 dd 46 13 12 f0 	movb   $0x40,-0xfedecba(,%ebx,8)
f0104009:	40 
f010400a:	6b c0 74             	imul   $0x74,%eax,%eax
f010400d:	05 2c 10 23 f0       	add    $0xf023102c,%eax
f0104012:	c1 e8 18             	shr    $0x18,%eax
f0104015:	88 04 dd 47 13 12 f0 	mov    %al,-0xfedecb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + i].sd_s = 0;
f010401c:	c6 04 dd 45 13 12 f0 	movb   $0x89,-0xfedecbb(,%ebx,8)
f0104023:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (i << 3));
f0104024:	8d 34 f5 28 00 00 00 	lea    0x28(,%esi,8),%esi
	asm volatile("ltr %0" : : "r" (sel));
f010402b:	0f 00 de             	ltr    %si
	asm volatile("lidt (%0)" : : "r" (p));
f010402e:	b8 aa 13 12 f0       	mov    $0xf01213aa,%eax
f0104033:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f0104036:	83 c4 1c             	add    $0x1c,%esp
f0104039:	5b                   	pop    %ebx
f010403a:	5e                   	pop    %esi
f010403b:	5f                   	pop    %edi
f010403c:	5d                   	pop    %ebp
f010403d:	c3                   	ret    

f010403e <trap_init>:
{
f010403e:	55                   	push   %ebp
f010403f:	89 e5                	mov    %esp,%ebp
f0104041:	83 ec 08             	sub    $0x8,%esp
	SETGATE(idt[T_DIVIDE], 1, GD_KT, t_divide, 0);
f0104044:	b8 b0 13 12 f0       	mov    $0xf01213b0,%eax
f0104049:	66 a3 60 02 23 f0    	mov    %ax,0xf0230260
f010404f:	66 c7 05 62 02 23 f0 	movw   $0x8,0xf0230262
f0104056:	08 00 
f0104058:	c6 05 64 02 23 f0 00 	movb   $0x0,0xf0230264
f010405f:	c6 05 65 02 23 f0 8f 	movb   $0x8f,0xf0230265
f0104066:	c1 e8 10             	shr    $0x10,%eax
f0104069:	66 a3 66 02 23 f0    	mov    %ax,0xf0230266
	SETGATE(idt[T_DEBUG], 1, GD_KT, t_debug, 0);
f010406f:	b8 ba 13 12 f0       	mov    $0xf01213ba,%eax
f0104074:	66 a3 68 02 23 f0    	mov    %ax,0xf0230268
f010407a:	66 c7 05 6a 02 23 f0 	movw   $0x8,0xf023026a
f0104081:	08 00 
f0104083:	c6 05 6c 02 23 f0 00 	movb   $0x0,0xf023026c
f010408a:	c6 05 6d 02 23 f0 8f 	movb   $0x8f,0xf023026d
f0104091:	c1 e8 10             	shr    $0x10,%eax
f0104094:	66 a3 6e 02 23 f0    	mov    %ax,0xf023026e
	SETGATE(idt[T_NMI], 1, GD_KT, t_nmi, 0);
f010409a:	b8 c4 13 12 f0       	mov    $0xf01213c4,%eax
f010409f:	66 a3 70 02 23 f0    	mov    %ax,0xf0230270
f01040a5:	66 c7 05 72 02 23 f0 	movw   $0x8,0xf0230272
f01040ac:	08 00 
f01040ae:	c6 05 74 02 23 f0 00 	movb   $0x0,0xf0230274
f01040b5:	c6 05 75 02 23 f0 8f 	movb   $0x8f,0xf0230275
f01040bc:	c1 e8 10             	shr    $0x10,%eax
f01040bf:	66 a3 76 02 23 f0    	mov    %ax,0xf0230276
	SETGATE(idt[T_BRKPT], 1, GD_KT, t_brkpt, 3);
f01040c5:	b8 ca 13 12 f0       	mov    $0xf01213ca,%eax
f01040ca:	66 a3 78 02 23 f0    	mov    %ax,0xf0230278
f01040d0:	66 c7 05 7a 02 23 f0 	movw   $0x8,0xf023027a
f01040d7:	08 00 
f01040d9:	c6 05 7c 02 23 f0 00 	movb   $0x0,0xf023027c
f01040e0:	c6 05 7d 02 23 f0 ef 	movb   $0xef,0xf023027d
f01040e7:	c1 e8 10             	shr    $0x10,%eax
f01040ea:	66 a3 7e 02 23 f0    	mov    %ax,0xf023027e
	SETGATE(idt[T_OFLOW], 1, GD_KT, t_oflow, 0);
f01040f0:	b8 d0 13 12 f0       	mov    $0xf01213d0,%eax
f01040f5:	66 a3 80 02 23 f0    	mov    %ax,0xf0230280
f01040fb:	66 c7 05 82 02 23 f0 	movw   $0x8,0xf0230282
f0104102:	08 00 
f0104104:	c6 05 84 02 23 f0 00 	movb   $0x0,0xf0230284
f010410b:	c6 05 85 02 23 f0 8f 	movb   $0x8f,0xf0230285
f0104112:	c1 e8 10             	shr    $0x10,%eax
f0104115:	66 a3 86 02 23 f0    	mov    %ax,0xf0230286
	SETGATE(idt[T_BOUND], 1, GD_KT, t_bound, 0);
f010411b:	b8 d6 13 12 f0       	mov    $0xf01213d6,%eax
f0104120:	66 a3 88 02 23 f0    	mov    %ax,0xf0230288
f0104126:	66 c7 05 8a 02 23 f0 	movw   $0x8,0xf023028a
f010412d:	08 00 
f010412f:	c6 05 8c 02 23 f0 00 	movb   $0x0,0xf023028c
f0104136:	c6 05 8d 02 23 f0 8f 	movb   $0x8f,0xf023028d
f010413d:	c1 e8 10             	shr    $0x10,%eax
f0104140:	66 a3 8e 02 23 f0    	mov    %ax,0xf023028e
	SETGATE(idt[T_ILLOP], 1, GD_KT, t_illop, 0);
f0104146:	b8 dc 13 12 f0       	mov    $0xf01213dc,%eax
f010414b:	66 a3 90 02 23 f0    	mov    %ax,0xf0230290
f0104151:	66 c7 05 92 02 23 f0 	movw   $0x8,0xf0230292
f0104158:	08 00 
f010415a:	c6 05 94 02 23 f0 00 	movb   $0x0,0xf0230294
f0104161:	c6 05 95 02 23 f0 8f 	movb   $0x8f,0xf0230295
f0104168:	c1 e8 10             	shr    $0x10,%eax
f010416b:	66 a3 96 02 23 f0    	mov    %ax,0xf0230296
	SETGATE(idt[T_DEVICE], 1, GD_KT, t_device, 0);
f0104171:	b8 e2 13 12 f0       	mov    $0xf01213e2,%eax
f0104176:	66 a3 98 02 23 f0    	mov    %ax,0xf0230298
f010417c:	66 c7 05 9a 02 23 f0 	movw   $0x8,0xf023029a
f0104183:	08 00 
f0104185:	c6 05 9c 02 23 f0 00 	movb   $0x0,0xf023029c
f010418c:	c6 05 9d 02 23 f0 8f 	movb   $0x8f,0xf023029d
f0104193:	c1 e8 10             	shr    $0x10,%eax
f0104196:	66 a3 9e 02 23 f0    	mov    %ax,0xf023029e
	SETGATE(idt[T_DBLFLT], 1, GD_KT, t_dblflt, 0);
f010419c:	b8 e8 13 12 f0       	mov    $0xf01213e8,%eax
f01041a1:	66 a3 a0 02 23 f0    	mov    %ax,0xf02302a0
f01041a7:	66 c7 05 a2 02 23 f0 	movw   $0x8,0xf02302a2
f01041ae:	08 00 
f01041b0:	c6 05 a4 02 23 f0 00 	movb   $0x0,0xf02302a4
f01041b7:	c6 05 a5 02 23 f0 8f 	movb   $0x8f,0xf02302a5
f01041be:	c1 e8 10             	shr    $0x10,%eax
f01041c1:	66 a3 a6 02 23 f0    	mov    %ax,0xf02302a6
	SETGATE(idt[T_TSS], 1, GD_KT, t_tss, 0);
f01041c7:	b8 ec 13 12 f0       	mov    $0xf01213ec,%eax
f01041cc:	66 a3 b0 02 23 f0    	mov    %ax,0xf02302b0
f01041d2:	66 c7 05 b2 02 23 f0 	movw   $0x8,0xf02302b2
f01041d9:	08 00 
f01041db:	c6 05 b4 02 23 f0 00 	movb   $0x0,0xf02302b4
f01041e2:	c6 05 b5 02 23 f0 8f 	movb   $0x8f,0xf02302b5
f01041e9:	c1 e8 10             	shr    $0x10,%eax
f01041ec:	66 a3 b6 02 23 f0    	mov    %ax,0xf02302b6
	SETGATE(idt[T_SEGNP], 1, GD_KT, t_segnp, 0);
f01041f2:	b8 f0 13 12 f0       	mov    $0xf01213f0,%eax
f01041f7:	66 a3 b8 02 23 f0    	mov    %ax,0xf02302b8
f01041fd:	66 c7 05 ba 02 23 f0 	movw   $0x8,0xf02302ba
f0104204:	08 00 
f0104206:	c6 05 bc 02 23 f0 00 	movb   $0x0,0xf02302bc
f010420d:	c6 05 bd 02 23 f0 8f 	movb   $0x8f,0xf02302bd
f0104214:	c1 e8 10             	shr    $0x10,%eax
f0104217:	66 a3 be 02 23 f0    	mov    %ax,0xf02302be
	SETGATE(idt[T_STACK], 1, GD_KT, t_stack, 0);
f010421d:	b8 f4 13 12 f0       	mov    $0xf01213f4,%eax
f0104222:	66 a3 c0 02 23 f0    	mov    %ax,0xf02302c0
f0104228:	66 c7 05 c2 02 23 f0 	movw   $0x8,0xf02302c2
f010422f:	08 00 
f0104231:	c6 05 c4 02 23 f0 00 	movb   $0x0,0xf02302c4
f0104238:	c6 05 c5 02 23 f0 8f 	movb   $0x8f,0xf02302c5
f010423f:	c1 e8 10             	shr    $0x10,%eax
f0104242:	66 a3 c6 02 23 f0    	mov    %ax,0xf02302c6
	SETGATE(idt[T_GPFLT], 1, GD_KT, t_gpflt, 0);
f0104248:	b8 f8 13 12 f0       	mov    $0xf01213f8,%eax
f010424d:	66 a3 c8 02 23 f0    	mov    %ax,0xf02302c8
f0104253:	66 c7 05 ca 02 23 f0 	movw   $0x8,0xf02302ca
f010425a:	08 00 
f010425c:	c6 05 cc 02 23 f0 00 	movb   $0x0,0xf02302cc
f0104263:	c6 05 cd 02 23 f0 8f 	movb   $0x8f,0xf02302cd
f010426a:	c1 e8 10             	shr    $0x10,%eax
f010426d:	66 a3 ce 02 23 f0    	mov    %ax,0xf02302ce
	SETGATE(idt[T_PGFLT], 1, GD_KT, t_pgflt, 0);
f0104273:	b8 fc 13 12 f0       	mov    $0xf01213fc,%eax
f0104278:	66 a3 d0 02 23 f0    	mov    %ax,0xf02302d0
f010427e:	66 c7 05 d2 02 23 f0 	movw   $0x8,0xf02302d2
f0104285:	08 00 
f0104287:	c6 05 d4 02 23 f0 00 	movb   $0x0,0xf02302d4
f010428e:	c6 05 d5 02 23 f0 8f 	movb   $0x8f,0xf02302d5
f0104295:	c1 e8 10             	shr    $0x10,%eax
f0104298:	66 a3 d6 02 23 f0    	mov    %ax,0xf02302d6
	SETGATE(idt[T_FPERR], 1, GD_KT, t_fperr, 0);
f010429e:	b8 00 14 12 f0       	mov    $0xf0121400,%eax
f01042a3:	66 a3 e0 02 23 f0    	mov    %ax,0xf02302e0
f01042a9:	66 c7 05 e2 02 23 f0 	movw   $0x8,0xf02302e2
f01042b0:	08 00 
f01042b2:	c6 05 e4 02 23 f0 00 	movb   $0x0,0xf02302e4
f01042b9:	c6 05 e5 02 23 f0 8f 	movb   $0x8f,0xf02302e5
f01042c0:	c1 e8 10             	shr    $0x10,%eax
f01042c3:	66 a3 e6 02 23 f0    	mov    %ax,0xf02302e6
	SETGATE(idt[T_ALIGN], 1, GD_KT, t_align, 0);
f01042c9:	b8 06 14 12 f0       	mov    $0xf0121406,%eax
f01042ce:	66 a3 e8 02 23 f0    	mov    %ax,0xf02302e8
f01042d4:	66 c7 05 ea 02 23 f0 	movw   $0x8,0xf02302ea
f01042db:	08 00 
f01042dd:	c6 05 ec 02 23 f0 00 	movb   $0x0,0xf02302ec
f01042e4:	c6 05 ed 02 23 f0 8f 	movb   $0x8f,0xf02302ed
f01042eb:	c1 e8 10             	shr    $0x10,%eax
f01042ee:	66 a3 ee 02 23 f0    	mov    %ax,0xf02302ee
	SETGATE(idt[T_MCHK], 1, GD_KT, t_mchk, 0);
f01042f4:	b8 0a 14 12 f0       	mov    $0xf012140a,%eax
f01042f9:	66 a3 f0 02 23 f0    	mov    %ax,0xf02302f0
f01042ff:	66 c7 05 f2 02 23 f0 	movw   $0x8,0xf02302f2
f0104306:	08 00 
f0104308:	c6 05 f4 02 23 f0 00 	movb   $0x0,0xf02302f4
f010430f:	c6 05 f5 02 23 f0 8f 	movb   $0x8f,0xf02302f5
f0104316:	c1 e8 10             	shr    $0x10,%eax
f0104319:	66 a3 f6 02 23 f0    	mov    %ax,0xf02302f6
	SETGATE(idt[T_SIMDERR], 1, GD_KT, t_simderr, 0);
f010431f:	b8 10 14 12 f0       	mov    $0xf0121410,%eax
f0104324:	66 a3 f8 02 23 f0    	mov    %ax,0xf02302f8
f010432a:	66 c7 05 fa 02 23 f0 	movw   $0x8,0xf02302fa
f0104331:	08 00 
f0104333:	c6 05 fc 02 23 f0 00 	movb   $0x0,0xf02302fc
f010433a:	c6 05 fd 02 23 f0 8f 	movb   $0x8f,0xf02302fd
f0104341:	c1 e8 10             	shr    $0x10,%eax
f0104344:	66 a3 fe 02 23 f0    	mov    %ax,0xf02302fe
	SETGATE(idt[T_SYSCALL], 1, GD_KT, t_syscall, 3);
f010434a:	b8 3a 14 12 f0       	mov    $0xf012143a,%eax
f010434f:	66 a3 e0 03 23 f0    	mov    %ax,0xf02303e0
f0104355:	66 c7 05 e2 03 23 f0 	movw   $0x8,0xf02303e2
f010435c:	08 00 
f010435e:	c6 05 e4 03 23 f0 00 	movb   $0x0,0xf02303e4
f0104365:	c6 05 e5 03 23 f0 ef 	movb   $0xef,0xf02303e5
f010436c:	c1 e8 10             	shr    $0x10,%eax
f010436f:	66 a3 e6 03 23 f0    	mov    %ax,0xf02303e6
	SETGATE(idt[T_DEFAULT], 1, GD_KT, t_default, 0);
f0104375:	b8 40 14 12 f0       	mov    $0xf0121440,%eax
f010437a:	66 a3 00 12 23 f0    	mov    %ax,0xf0231200
f0104380:	66 c7 05 02 12 23 f0 	movw   $0x8,0xf0231202
f0104387:	08 00 
f0104389:	c6 05 04 12 23 f0 00 	movb   $0x0,0xf0231204
f0104390:	c6 05 05 12 23 f0 8f 	movb   $0x8f,0xf0231205
f0104397:	c1 e8 10             	shr    $0x10,%eax
f010439a:	66 a3 06 12 23 f0    	mov    %ax,0xf0231206
	SETGATE(idt[IRQ_OFFSET + IRQ_TIMER], 1, GD_KT, irq_timer, 0);
f01043a0:	b8 16 14 12 f0       	mov    $0xf0121416,%eax
f01043a5:	66 a3 60 03 23 f0    	mov    %ax,0xf0230360
f01043ab:	66 c7 05 62 03 23 f0 	movw   $0x8,0xf0230362
f01043b2:	08 00 
f01043b4:	c6 05 64 03 23 f0 00 	movb   $0x0,0xf0230364
f01043bb:	c6 05 65 03 23 f0 8f 	movb   $0x8f,0xf0230365
f01043c2:	c1 e8 10             	shr    $0x10,%eax
f01043c5:	66 a3 66 03 23 f0    	mov    %ax,0xf0230366
	SETGATE(idt[IRQ_OFFSET + IRQ_KBD], 1, GD_KT, irq_kbd, 0);
f01043cb:	b8 1c 14 12 f0       	mov    $0xf012141c,%eax
f01043d0:	66 a3 68 03 23 f0    	mov    %ax,0xf0230368
f01043d6:	66 c7 05 6a 03 23 f0 	movw   $0x8,0xf023036a
f01043dd:	08 00 
f01043df:	c6 05 6c 03 23 f0 00 	movb   $0x0,0xf023036c
f01043e6:	c6 05 6d 03 23 f0 8f 	movb   $0x8f,0xf023036d
f01043ed:	c1 e8 10             	shr    $0x10,%eax
f01043f0:	66 a3 6e 03 23 f0    	mov    %ax,0xf023036e
	SETGATE(idt[IRQ_OFFSET + IRQ_SERIAL], 1, GD_KT, irq_serial, 0);
f01043f6:	b8 22 14 12 f0       	mov    $0xf0121422,%eax
f01043fb:	66 a3 80 03 23 f0    	mov    %ax,0xf0230380
f0104401:	66 c7 05 82 03 23 f0 	movw   $0x8,0xf0230382
f0104408:	08 00 
f010440a:	c6 05 84 03 23 f0 00 	movb   $0x0,0xf0230384
f0104411:	c6 05 85 03 23 f0 8f 	movb   $0x8f,0xf0230385
f0104418:	c1 e8 10             	shr    $0x10,%eax
f010441b:	66 a3 86 03 23 f0    	mov    %ax,0xf0230386
	SETGATE(idt[IRQ_OFFSET + IRQ_SPURIOUS], 1, GD_KT, irq_spurious, 0);
f0104421:	b8 28 14 12 f0       	mov    $0xf0121428,%eax
f0104426:	66 a3 98 03 23 f0    	mov    %ax,0xf0230398
f010442c:	66 c7 05 9a 03 23 f0 	movw   $0x8,0xf023039a
f0104433:	08 00 
f0104435:	c6 05 9c 03 23 f0 00 	movb   $0x0,0xf023039c
f010443c:	c6 05 9d 03 23 f0 8f 	movb   $0x8f,0xf023039d
f0104443:	c1 e8 10             	shr    $0x10,%eax
f0104446:	66 a3 9e 03 23 f0    	mov    %ax,0xf023039e
	SETGATE(idt[IRQ_OFFSET + IRQ_IDE], 1, GD_KT, irq_ide, 0);
f010444c:	b8 2e 14 12 f0       	mov    $0xf012142e,%eax
f0104451:	66 a3 d0 03 23 f0    	mov    %ax,0xf02303d0
f0104457:	66 c7 05 d2 03 23 f0 	movw   $0x8,0xf02303d2
f010445e:	08 00 
f0104460:	c6 05 d4 03 23 f0 00 	movb   $0x0,0xf02303d4
f0104467:	c6 05 d5 03 23 f0 8f 	movb   $0x8f,0xf02303d5
f010446e:	c1 e8 10             	shr    $0x10,%eax
f0104471:	66 a3 d6 03 23 f0    	mov    %ax,0xf02303d6
	SETGATE(idt[IRQ_OFFSET + IRQ_ERROR], 1, GD_KT, irq_error, 0);
f0104477:	b8 34 14 12 f0       	mov    $0xf0121434,%eax
f010447c:	66 a3 f8 03 23 f0    	mov    %ax,0xf02303f8
f0104482:	66 c7 05 fa 03 23 f0 	movw   $0x8,0xf02303fa
f0104489:	08 00 
f010448b:	c6 05 fc 03 23 f0 00 	movb   $0x0,0xf02303fc
f0104492:	c6 05 fd 03 23 f0 8f 	movb   $0x8f,0xf02303fd
f0104499:	c1 e8 10             	shr    $0x10,%eax
f010449c:	66 a3 fe 03 23 f0    	mov    %ax,0xf02303fe
	trap_init_percpu();
f01044a2:	e8 d9 fa ff ff       	call   f0103f80 <trap_init_percpu>
}
f01044a7:	c9                   	leave  
f01044a8:	c3                   	ret    

f01044a9 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01044a9:	55                   	push   %ebp
f01044aa:	89 e5                	mov    %esp,%ebp
f01044ac:	53                   	push   %ebx
f01044ad:	83 ec 14             	sub    $0x14,%esp
f01044b0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01044b3:	8b 03                	mov    (%ebx),%eax
f01044b5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044b9:	c7 04 24 73 7e 10 f0 	movl   $0xf0107e73,(%esp)
f01044c0:	e8 9e fa ff ff       	call   f0103f63 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01044c5:	8b 43 04             	mov    0x4(%ebx),%eax
f01044c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044cc:	c7 04 24 82 7e 10 f0 	movl   $0xf0107e82,(%esp)
f01044d3:	e8 8b fa ff ff       	call   f0103f63 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01044d8:	8b 43 08             	mov    0x8(%ebx),%eax
f01044db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044df:	c7 04 24 91 7e 10 f0 	movl   $0xf0107e91,(%esp)
f01044e6:	e8 78 fa ff ff       	call   f0103f63 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01044eb:	8b 43 0c             	mov    0xc(%ebx),%eax
f01044ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044f2:	c7 04 24 a0 7e 10 f0 	movl   $0xf0107ea0,(%esp)
f01044f9:	e8 65 fa ff ff       	call   f0103f63 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01044fe:	8b 43 10             	mov    0x10(%ebx),%eax
f0104501:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104505:	c7 04 24 af 7e 10 f0 	movl   $0xf0107eaf,(%esp)
f010450c:	e8 52 fa ff ff       	call   f0103f63 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0104511:	8b 43 14             	mov    0x14(%ebx),%eax
f0104514:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104518:	c7 04 24 be 7e 10 f0 	movl   $0xf0107ebe,(%esp)
f010451f:	e8 3f fa ff ff       	call   f0103f63 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0104524:	8b 43 18             	mov    0x18(%ebx),%eax
f0104527:	89 44 24 04          	mov    %eax,0x4(%esp)
f010452b:	c7 04 24 cd 7e 10 f0 	movl   $0xf0107ecd,(%esp)
f0104532:	e8 2c fa ff ff       	call   f0103f63 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0104537:	8b 43 1c             	mov    0x1c(%ebx),%eax
f010453a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010453e:	c7 04 24 dc 7e 10 f0 	movl   $0xf0107edc,(%esp)
f0104545:	e8 19 fa ff ff       	call   f0103f63 <cprintf>
}
f010454a:	83 c4 14             	add    $0x14,%esp
f010454d:	5b                   	pop    %ebx
f010454e:	5d                   	pop    %ebp
f010454f:	c3                   	ret    

f0104550 <print_trapframe>:
{
f0104550:	55                   	push   %ebp
f0104551:	89 e5                	mov    %esp,%ebp
f0104553:	56                   	push   %esi
f0104554:	53                   	push   %ebx
f0104555:	83 ec 10             	sub    $0x10,%esp
f0104558:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f010455b:	e8 79 1f 00 00       	call   f01064d9 <cpunum>
f0104560:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104564:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104568:	c7 04 24 40 7f 10 f0 	movl   $0xf0107f40,(%esp)
f010456f:	e8 ef f9 ff ff       	call   f0103f63 <cprintf>
	print_regs(&tf->tf_regs);
f0104574:	89 1c 24             	mov    %ebx,(%esp)
f0104577:	e8 2d ff ff ff       	call   f01044a9 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010457c:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0104580:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104584:	c7 04 24 5e 7f 10 f0 	movl   $0xf0107f5e,(%esp)
f010458b:	e8 d3 f9 ff ff       	call   f0103f63 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0104590:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0104594:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104598:	c7 04 24 71 7f 10 f0 	movl   $0xf0107f71,(%esp)
f010459f:	e8 bf f9 ff ff       	call   f0103f63 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01045a4:	8b 43 28             	mov    0x28(%ebx),%eax
	if (trapno < ARRAY_SIZE(excnames))
f01045a7:	83 f8 13             	cmp    $0x13,%eax
f01045aa:	77 09                	ja     f01045b5 <print_trapframe+0x65>
		return excnames[trapno];
f01045ac:	8b 14 85 00 82 10 f0 	mov    -0xfef7e00(,%eax,4),%edx
f01045b3:	eb 1f                	jmp    f01045d4 <print_trapframe+0x84>
	if (trapno == T_SYSCALL)
f01045b5:	83 f8 30             	cmp    $0x30,%eax
f01045b8:	74 15                	je     f01045cf <print_trapframe+0x7f>
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f01045ba:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f01045bd:	83 fa 0f             	cmp    $0xf,%edx
f01045c0:	ba f7 7e 10 f0       	mov    $0xf0107ef7,%edx
f01045c5:	b9 0a 7f 10 f0       	mov    $0xf0107f0a,%ecx
f01045ca:	0f 47 d1             	cmova  %ecx,%edx
f01045cd:	eb 05                	jmp    f01045d4 <print_trapframe+0x84>
		return "System call";
f01045cf:	ba eb 7e 10 f0       	mov    $0xf0107eeb,%edx
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01045d4:	89 54 24 08          	mov    %edx,0x8(%esp)
f01045d8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045dc:	c7 04 24 84 7f 10 f0 	movl   $0xf0107f84,(%esp)
f01045e3:	e8 7b f9 ff ff       	call   f0103f63 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01045e8:	3b 1d 60 0a 23 f0    	cmp    0xf0230a60,%ebx
f01045ee:	75 19                	jne    f0104609 <print_trapframe+0xb9>
f01045f0:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01045f4:	75 13                	jne    f0104609 <print_trapframe+0xb9>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01045f6:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01045f9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045fd:	c7 04 24 96 7f 10 f0 	movl   $0xf0107f96,(%esp)
f0104604:	e8 5a f9 ff ff       	call   f0103f63 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0104609:	8b 43 2c             	mov    0x2c(%ebx),%eax
f010460c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104610:	c7 04 24 a5 7f 10 f0 	movl   $0xf0107fa5,(%esp)
f0104617:	e8 47 f9 ff ff       	call   f0103f63 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f010461c:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0104620:	75 51                	jne    f0104673 <print_trapframe+0x123>
			tf->tf_err & 1 ? "protection" : "not-present");
f0104622:	8b 43 2c             	mov    0x2c(%ebx),%eax
		cprintf(" [%s, %s, %s]\n",
f0104625:	89 c2                	mov    %eax,%edx
f0104627:	83 e2 01             	and    $0x1,%edx
f010462a:	ba 19 7f 10 f0       	mov    $0xf0107f19,%edx
f010462f:	b9 24 7f 10 f0       	mov    $0xf0107f24,%ecx
f0104634:	0f 45 ca             	cmovne %edx,%ecx
f0104637:	89 c2                	mov    %eax,%edx
f0104639:	83 e2 02             	and    $0x2,%edx
f010463c:	ba 30 7f 10 f0       	mov    $0xf0107f30,%edx
f0104641:	be 36 7f 10 f0       	mov    $0xf0107f36,%esi
f0104646:	0f 44 d6             	cmove  %esi,%edx
f0104649:	83 e0 04             	and    $0x4,%eax
f010464c:	b8 3b 7f 10 f0       	mov    $0xf0107f3b,%eax
f0104651:	be 82 80 10 f0       	mov    $0xf0108082,%esi
f0104656:	0f 44 c6             	cmove  %esi,%eax
f0104659:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010465d:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104661:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104665:	c7 04 24 b3 7f 10 f0 	movl   $0xf0107fb3,(%esp)
f010466c:	e8 f2 f8 ff ff       	call   f0103f63 <cprintf>
f0104671:	eb 0c                	jmp    f010467f <print_trapframe+0x12f>
		cprintf("\n");
f0104673:	c7 04 24 bc 7d 10 f0 	movl   $0xf0107dbc,(%esp)
f010467a:	e8 e4 f8 ff ff       	call   f0103f63 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010467f:	8b 43 30             	mov    0x30(%ebx),%eax
f0104682:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104686:	c7 04 24 c2 7f 10 f0 	movl   $0xf0107fc2,(%esp)
f010468d:	e8 d1 f8 ff ff       	call   f0103f63 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0104692:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0104696:	89 44 24 04          	mov    %eax,0x4(%esp)
f010469a:	c7 04 24 d1 7f 10 f0 	movl   $0xf0107fd1,(%esp)
f01046a1:	e8 bd f8 ff ff       	call   f0103f63 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01046a6:	8b 43 38             	mov    0x38(%ebx),%eax
f01046a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046ad:	c7 04 24 e4 7f 10 f0 	movl   $0xf0107fe4,(%esp)
f01046b4:	e8 aa f8 ff ff       	call   f0103f63 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01046b9:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01046bd:	74 27                	je     f01046e6 <print_trapframe+0x196>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01046bf:	8b 43 3c             	mov    0x3c(%ebx),%eax
f01046c2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046c6:	c7 04 24 f3 7f 10 f0 	movl   $0xf0107ff3,(%esp)
f01046cd:	e8 91 f8 ff ff       	call   f0103f63 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01046d2:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01046d6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046da:	c7 04 24 02 80 10 f0 	movl   $0xf0108002,(%esp)
f01046e1:	e8 7d f8 ff ff       	call   f0103f63 <cprintf>
}
f01046e6:	83 c4 10             	add    $0x10,%esp
f01046e9:	5b                   	pop    %ebx
f01046ea:	5e                   	pop    %esi
f01046eb:	5d                   	pop    %ebp
f01046ec:	c3                   	ret    

f01046ed <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01046ed:	55                   	push   %ebp
f01046ee:	89 e5                	mov    %esp,%ebp
f01046f0:	57                   	push   %edi
f01046f1:	56                   	push   %esi
f01046f2:	53                   	push   %ebx
f01046f3:	83 ec 2c             	sub    $0x2c,%esp
f01046f6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01046f9:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0)
f01046fc:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104700:	75 24                	jne    f0104726 <page_fault_handler+0x39>
	{
		print_trapframe(tf);
f0104702:	89 1c 24             	mov    %ebx,(%esp)
f0104705:	e8 46 fe ff ff       	call   f0104550 <print_trapframe>
		panic("Kernel pagefault\n");
f010470a:	c7 44 24 08 15 80 10 	movl   $0xf0108015,0x8(%esp)
f0104711:	f0 
f0104712:	c7 44 24 04 6e 01 00 	movl   $0x16e,0x4(%esp)
f0104719:	00 
f010471a:	c7 04 24 27 80 10 f0 	movl   $0xf0108027,(%esp)
f0104721:	e8 1a b9 ff ff       	call   f0100040 <_panic>
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if (curenv->env_pgfault_upcall) {
f0104726:	e8 ae 1d 00 00       	call   f01064d9 <cpunum>
f010472b:	6b c0 74             	imul   $0x74,%eax,%eax
f010472e:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104734:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0104738:	0f 84 db 00 00 00    	je     f0104819 <page_fault_handler+0x12c>
		struct UTrapframe *uTrap = NULL;

		if (tf->tf_esp >= UXSTACKTOP - PGSIZE && tf->tf_esp <= UXSTACKTOP - 1)
f010473e:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0104741:	8d 90 00 10 40 11    	lea    0x11401000(%eax),%edx
		{
			uTrap = (struct UTrapframe *)(tf->tf_esp - 4 - sizeof(struct UTrapframe));
f0104747:	83 e8 38             	sub    $0x38,%eax
f010474a:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0104750:	ba cb ff bf ee       	mov    $0xeebfffcb,%edx
f0104755:	0f 46 d0             	cmovbe %eax,%edx
f0104758:	89 d7                	mov    %edx,%edi
f010475a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		else
		{
			uTrap = (struct UTrapframe *)(UXSTACKTOP - 1 - sizeof(struct UTrapframe));
		}

		user_mem_assert(curenv, uTrap, sizeof(struct UTrapframe), PTE_U|PTE_W|PTE_P);
f010475d:	e8 77 1d 00 00       	call   f01064d9 <cpunum>
f0104762:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
f0104769:	00 
f010476a:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
f0104771:	00 
f0104772:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104776:	6b c0 74             	imul   $0x74,%eax,%eax
f0104779:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f010477f:	89 04 24             	mov    %eax,(%esp)
f0104782:	e8 15 ee ff ff       	call   f010359c <user_mem_assert>

		uTrap->utf_fault_va = fault_va;
f0104787:	89 37                	mov    %esi,(%edi)
		uTrap->utf_err = tf->tf_err;
f0104789:	8b 43 2c             	mov    0x2c(%ebx),%eax
f010478c:	89 47 04             	mov    %eax,0x4(%edi)
		uTrap->utf_regs = tf->tf_regs;
f010478f:	8d 7f 08             	lea    0x8(%edi),%edi
f0104792:	89 de                	mov    %ebx,%esi
f0104794:	b8 20 00 00 00       	mov    $0x20,%eax
f0104799:	f7 c7 01 00 00 00    	test   $0x1,%edi
f010479f:	74 03                	je     f01047a4 <page_fault_handler+0xb7>
f01047a1:	a4                   	movsb  %ds:(%esi),%es:(%edi)
f01047a2:	b0 1f                	mov    $0x1f,%al
f01047a4:	f7 c7 02 00 00 00    	test   $0x2,%edi
f01047aa:	74 05                	je     f01047b1 <page_fault_handler+0xc4>
f01047ac:	66 a5                	movsw  %ds:(%esi),%es:(%edi)
f01047ae:	83 e8 02             	sub    $0x2,%eax
f01047b1:	89 c1                	mov    %eax,%ecx
f01047b3:	c1 e9 02             	shr    $0x2,%ecx
f01047b6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01047b8:	ba 00 00 00 00       	mov    $0x0,%edx
f01047bd:	a8 02                	test   $0x2,%al
f01047bf:	74 0b                	je     f01047cc <page_fault_handler+0xdf>
f01047c1:	0f b7 16             	movzwl (%esi),%edx
f01047c4:	66 89 17             	mov    %dx,(%edi)
f01047c7:	ba 02 00 00 00       	mov    $0x2,%edx
f01047cc:	a8 01                	test   $0x1,%al
f01047ce:	74 07                	je     f01047d7 <page_fault_handler+0xea>
f01047d0:	0f b6 04 16          	movzbl (%esi,%edx,1),%eax
f01047d4:	88 04 17             	mov    %al,(%edi,%edx,1)
		uTrap->utf_eip = tf->tf_eip;
f01047d7:	8b 43 30             	mov    0x30(%ebx),%eax
f01047da:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01047dd:	89 41 28             	mov    %eax,0x28(%ecx)
		uTrap->utf_eflags = tf->tf_eflags;
f01047e0:	8b 43 38             	mov    0x38(%ebx),%eax
f01047e3:	89 41 2c             	mov    %eax,0x2c(%ecx)
		uTrap->utf_esp = tf->tf_esp;
f01047e6:	8b 43 3c             	mov    0x3c(%ebx),%eax
f01047e9:	89 41 30             	mov    %eax,0x30(%ecx)

		tf->tf_esp = (intptr_t)uTrap;
f01047ec:	89 4b 3c             	mov    %ecx,0x3c(%ebx)

		tf->tf_eip = (intptr_t)curenv->env_pgfault_upcall;
f01047ef:	e8 e5 1c 00 00       	call   f01064d9 <cpunum>
f01047f4:	6b c0 74             	imul   $0x74,%eax,%eax
f01047f7:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f01047fd:	8b 40 64             	mov    0x64(%eax),%eax
f0104800:	89 43 30             	mov    %eax,0x30(%ebx)

		env_run(curenv);
f0104803:	e8 d1 1c 00 00       	call   f01064d9 <cpunum>
f0104808:	6b c0 74             	imul   $0x74,%eax,%eax
f010480b:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104811:	89 04 24             	mov    %eax,(%esp)
f0104814:	e8 12 f5 ff ff       	call   f0103d2b <env_run>

		return;
	}
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104819:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f010481c:	e8 b8 1c 00 00       	call   f01064d9 <cpunum>
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104821:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104825:	89 74 24 08          	mov    %esi,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f0104829:	6b c0 74             	imul   $0x74,%eax,%eax
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010482c:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104832:	8b 40 48             	mov    0x48(%eax),%eax
f0104835:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104839:	c7 04 24 cc 81 10 f0 	movl   $0xf01081cc,(%esp)
f0104840:	e8 1e f7 ff ff       	call   f0103f63 <cprintf>
	print_trapframe(tf);
f0104845:	89 1c 24             	mov    %ebx,(%esp)
f0104848:	e8 03 fd ff ff       	call   f0104550 <print_trapframe>
	env_destroy(curenv);
f010484d:	e8 87 1c 00 00       	call   f01064d9 <cpunum>
f0104852:	6b c0 74             	imul   $0x74,%eax,%eax
f0104855:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f010485b:	89 04 24             	mov    %eax,(%esp)
f010485e:	e8 27 f4 ff ff       	call   f0103c8a <env_destroy>
}
f0104863:	83 c4 2c             	add    $0x2c,%esp
f0104866:	5b                   	pop    %ebx
f0104867:	5e                   	pop    %esi
f0104868:	5f                   	pop    %edi
f0104869:	5d                   	pop    %ebp
f010486a:	c3                   	ret    

f010486b <trap>:
{
f010486b:	55                   	push   %ebp
f010486c:	89 e5                	mov    %esp,%ebp
f010486e:	57                   	push   %edi
f010486f:	56                   	push   %esi
f0104870:	83 ec 20             	sub    $0x20,%esp
f0104873:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f0104876:	fc                   	cld    
	if (panicstr)
f0104877:	83 3d 80 0e 23 f0 00 	cmpl   $0x0,0xf0230e80
f010487e:	74 01                	je     f0104881 <trap+0x16>
		asm volatile("hlt");
f0104880:	f4                   	hlt    
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0104881:	e8 53 1c 00 00       	call   f01064d9 <cpunum>
f0104886:	6b d0 74             	imul   $0x74,%eax,%edx
f0104889:	81 c2 20 10 23 f0    	add    $0xf0231020,%edx
	asm volatile("lock; xchgl %0, %1"
f010488f:	b8 01 00 00 00       	mov    $0x1,%eax
f0104894:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0104898:	83 f8 02             	cmp    $0x2,%eax
f010489b:	75 0c                	jne    f01048a9 <trap+0x3e>
	spin_lock(&kernel_lock);
f010489d:	c7 04 24 60 14 12 f0 	movl   $0xf0121460,(%esp)
f01048a4:	e8 ae 1e 00 00       	call   f0106757 <spin_lock>
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01048a9:	9c                   	pushf  
f01048aa:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f01048ab:	f6 c4 02             	test   $0x2,%ah
f01048ae:	74 24                	je     f01048d4 <trap+0x69>
f01048b0:	c7 44 24 0c 33 80 10 	movl   $0xf0108033,0xc(%esp)
f01048b7:	f0 
f01048b8:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f01048bf:	f0 
f01048c0:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
f01048c7:	00 
f01048c8:	c7 04 24 27 80 10 f0 	movl   $0xf0108027,(%esp)
f01048cf:	e8 6c b7 ff ff       	call   f0100040 <_panic>
	if ((tf->tf_cs & 3) == 3) {
f01048d4:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01048d8:	83 e0 03             	and    $0x3,%eax
f01048db:	66 83 f8 03          	cmp    $0x3,%ax
f01048df:	0f 85 a7 00 00 00    	jne    f010498c <trap+0x121>
f01048e5:	c7 04 24 60 14 12 f0 	movl   $0xf0121460,(%esp)
f01048ec:	e8 66 1e 00 00       	call   f0106757 <spin_lock>
		assert(curenv);
f01048f1:	e8 e3 1b 00 00       	call   f01064d9 <cpunum>
f01048f6:	6b c0 74             	imul   $0x74,%eax,%eax
f01048f9:	83 b8 28 10 23 f0 00 	cmpl   $0x0,-0xfdcefd8(%eax)
f0104900:	75 24                	jne    f0104926 <trap+0xbb>
f0104902:	c7 44 24 0c 4c 80 10 	movl   $0xf010804c,0xc(%esp)
f0104909:	f0 
f010490a:	c7 44 24 08 cb 7a 10 	movl   $0xf0107acb,0x8(%esp)
f0104911:	f0 
f0104912:	c7 44 24 04 3e 01 00 	movl   $0x13e,0x4(%esp)
f0104919:	00 
f010491a:	c7 04 24 27 80 10 f0 	movl   $0xf0108027,(%esp)
f0104921:	e8 1a b7 ff ff       	call   f0100040 <_panic>
		if (curenv->env_status == ENV_DYING) {
f0104926:	e8 ae 1b 00 00       	call   f01064d9 <cpunum>
f010492b:	6b c0 74             	imul   $0x74,%eax,%eax
f010492e:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104934:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0104938:	75 2d                	jne    f0104967 <trap+0xfc>
			env_free(curenv);
f010493a:	e8 9a 1b 00 00       	call   f01064d9 <cpunum>
f010493f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104942:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104948:	89 04 24             	mov    %eax,(%esp)
f010494b:	e8 35 f1 ff ff       	call   f0103a85 <env_free>
			curenv = NULL;
f0104950:	e8 84 1b 00 00       	call   f01064d9 <cpunum>
f0104955:	6b c0 74             	imul   $0x74,%eax,%eax
f0104958:	c7 80 28 10 23 f0 00 	movl   $0x0,-0xfdcefd8(%eax)
f010495f:	00 00 00 
			sched_yield();
f0104962:	e8 0c 02 00 00       	call   f0104b73 <sched_yield>
		curenv->env_tf = *tf;
f0104967:	e8 6d 1b 00 00       	call   f01064d9 <cpunum>
f010496c:	6b c0 74             	imul   $0x74,%eax,%eax
f010496f:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104975:	b9 11 00 00 00       	mov    $0x11,%ecx
f010497a:	89 c7                	mov    %eax,%edi
f010497c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f010497e:	e8 56 1b 00 00       	call   f01064d9 <cpunum>
f0104983:	6b c0 74             	imul   $0x74,%eax,%eax
f0104986:	8b b0 28 10 23 f0    	mov    -0xfdcefd8(%eax),%esi
	last_tf = tf;
f010498c:	89 35 60 0a 23 f0    	mov    %esi,0xf0230a60
	if(tf->tf_trapno == T_PGFLT)
f0104992:	8b 46 28             	mov    0x28(%esi),%eax
f0104995:	83 f8 0e             	cmp    $0xe,%eax
f0104998:	75 0d                	jne    f01049a7 <trap+0x13c>
		page_fault_handler(tf);
f010499a:	89 34 24             	mov    %esi,(%esp)
f010499d:	e8 4b fd ff ff       	call   f01046ed <page_fault_handler>
f01049a2:	e9 b6 00 00 00       	jmp    f0104a5d <trap+0x1f2>
	if(tf->tf_trapno == T_BRKPT)
f01049a7:	83 f8 03             	cmp    $0x3,%eax
f01049aa:	75 0e                	jne    f01049ba <trap+0x14f>
		monitor(tf);
f01049ac:	89 34 24             	mov    %esi,(%esp)
f01049af:	90                   	nop
f01049b0:	e8 06 c0 ff ff       	call   f01009bb <monitor>
f01049b5:	e9 a3 00 00 00       	jmp    f0104a5d <trap+0x1f2>
	if (tf->tf_trapno == T_SYSCALL)
f01049ba:	83 f8 30             	cmp    $0x30,%eax
f01049bd:	75 32                	jne    f01049f1 <trap+0x186>
		uint32_t retVal = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
f01049bf:	8b 46 04             	mov    0x4(%esi),%eax
f01049c2:	89 44 24 14          	mov    %eax,0x14(%esp)
f01049c6:	8b 06                	mov    (%esi),%eax
f01049c8:	89 44 24 10          	mov    %eax,0x10(%esp)
f01049cc:	8b 46 10             	mov    0x10(%esi),%eax
f01049cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01049d3:	8b 46 18             	mov    0x18(%esi),%eax
f01049d6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01049da:	8b 46 14             	mov    0x14(%esi),%eax
f01049dd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01049e1:	8b 46 1c             	mov    0x1c(%esi),%eax
f01049e4:	89 04 24             	mov    %eax,(%esp)
f01049e7:	e8 14 02 00 00       	call   f0104c00 <syscall>
		tf->tf_regs.reg_eax = retVal;
f01049ec:	89 46 1c             	mov    %eax,0x1c(%esi)
f01049ef:	eb 6c                	jmp    f0104a5d <trap+0x1f2>
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f01049f1:	83 f8 27             	cmp    $0x27,%eax
f01049f4:	75 16                	jne    f0104a0c <trap+0x1a1>
		cprintf("Spurious interrupt on irq 7\n");
f01049f6:	c7 04 24 53 80 10 f0 	movl   $0xf0108053,(%esp)
f01049fd:	e8 61 f5 ff ff       	call   f0103f63 <cprintf>
		print_trapframe(tf);
f0104a02:	89 34 24             	mov    %esi,(%esp)
f0104a05:	e8 46 fb ff ff       	call   f0104550 <print_trapframe>
f0104a0a:	eb 51                	jmp    f0104a5d <trap+0x1f2>
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_TIMER)
f0104a0c:	83 f8 20             	cmp    $0x20,%eax
f0104a0f:	90                   	nop
f0104a10:	75 0a                	jne    f0104a1c <trap+0x1b1>
		lapic_eoi();
f0104a12:	e8 0f 1c 00 00       	call   f0106626 <lapic_eoi>
		sched_yield();
f0104a17:	e8 57 01 00 00       	call   f0104b73 <sched_yield>
	print_trapframe(tf);
f0104a1c:	89 34 24             	mov    %esi,(%esp)
f0104a1f:	e8 2c fb ff ff       	call   f0104550 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0104a24:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104a29:	75 1c                	jne    f0104a47 <trap+0x1dc>
		panic("unhandled trap in kernel");
f0104a2b:	c7 44 24 08 70 80 10 	movl   $0xf0108070,0x8(%esp)
f0104a32:	f0 
f0104a33:	c7 44 24 04 1c 01 00 	movl   $0x11c,0x4(%esp)
f0104a3a:	00 
f0104a3b:	c7 04 24 27 80 10 f0 	movl   $0xf0108027,(%esp)
f0104a42:	e8 f9 b5 ff ff       	call   f0100040 <_panic>
		env_destroy(curenv);
f0104a47:	e8 8d 1a 00 00       	call   f01064d9 <cpunum>
f0104a4c:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a4f:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104a55:	89 04 24             	mov    %eax,(%esp)
f0104a58:	e8 2d f2 ff ff       	call   f0103c8a <env_destroy>
	if (curenv && curenv->env_status == ENV_RUNNING)
f0104a5d:	e8 77 1a 00 00       	call   f01064d9 <cpunum>
f0104a62:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a65:	83 b8 28 10 23 f0 00 	cmpl   $0x0,-0xfdcefd8(%eax)
f0104a6c:	74 2a                	je     f0104a98 <trap+0x22d>
f0104a6e:	e8 66 1a 00 00       	call   f01064d9 <cpunum>
f0104a73:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a76:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104a7c:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104a80:	75 16                	jne    f0104a98 <trap+0x22d>
		env_run(curenv);
f0104a82:	e8 52 1a 00 00       	call   f01064d9 <cpunum>
f0104a87:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a8a:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104a90:	89 04 24             	mov    %eax,(%esp)
f0104a93:	e8 93 f2 ff ff       	call   f0103d2b <env_run>
		sched_yield();
f0104a98:	e8 d6 00 00 00       	call   f0104b73 <sched_yield>

f0104a9d <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104a9d:	55                   	push   %ebp
f0104a9e:	89 e5                	mov    %esp,%ebp
f0104aa0:	83 ec 18             	sub    $0x18,%esp
f0104aa3:	8b 15 48 02 23 f0    	mov    0xf0230248,%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104aa9:	b8 00 00 00 00       	mov    $0x0,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f0104aae:	8b 4a 54             	mov    0x54(%edx),%ecx
f0104ab1:	83 e9 01             	sub    $0x1,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104ab4:	83 f9 02             	cmp    $0x2,%ecx
f0104ab7:	76 0f                	jbe    f0104ac8 <sched_halt+0x2b>
	for (i = 0; i < NENV; i++) {
f0104ab9:	83 c0 01             	add    $0x1,%eax
f0104abc:	83 c2 7c             	add    $0x7c,%edx
f0104abf:	3d 00 04 00 00       	cmp    $0x400,%eax
f0104ac4:	75 e8                	jne    f0104aae <sched_halt+0x11>
f0104ac6:	eb 07                	jmp    f0104acf <sched_halt+0x32>
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0104ac8:	3d 00 04 00 00       	cmp    $0x400,%eax
f0104acd:	75 1a                	jne    f0104ae9 <sched_halt+0x4c>
		cprintf("No runnable environments in the system!\n");
f0104acf:	c7 04 24 50 82 10 f0 	movl   $0xf0108250,(%esp)
f0104ad6:	e8 88 f4 ff ff       	call   f0103f63 <cprintf>
		while (1)
			monitor(NULL);
f0104adb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104ae2:	e8 d4 be ff ff       	call   f01009bb <monitor>
f0104ae7:	eb f2                	jmp    f0104adb <sched_halt+0x3e>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104ae9:	e8 eb 19 00 00       	call   f01064d9 <cpunum>
f0104aee:	6b c0 74             	imul   $0x74,%eax,%eax
f0104af1:	c7 80 28 10 23 f0 00 	movl   $0x0,-0xfdcefd8(%eax)
f0104af8:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104afb:	a1 8c 0e 23 f0       	mov    0xf0230e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0104b00:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104b05:	77 20                	ja     f0104b27 <sched_halt+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104b07:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104b0b:	c7 44 24 08 08 6c 10 	movl   $0xf0106c08,0x8(%esp)
f0104b12:	f0 
f0104b13:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0104b1a:	00 
f0104b1b:	c7 04 24 79 82 10 f0 	movl   $0xf0108279,(%esp)
f0104b22:	e8 19 b5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0104b27:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0104b2c:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104b2f:	e8 a5 19 00 00       	call   f01064d9 <cpunum>
f0104b34:	6b d0 74             	imul   $0x74,%eax,%edx
f0104b37:	81 c2 20 10 23 f0    	add    $0xf0231020,%edx
	asm volatile("lock; xchgl %0, %1"
f0104b3d:	b8 02 00 00 00       	mov    $0x2,%eax
f0104b42:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
	spin_unlock(&kernel_lock);
f0104b46:	c7 04 24 60 14 12 f0 	movl   $0xf0121460,(%esp)
f0104b4d:	e8 b1 1c 00 00       	call   f0106803 <spin_unlock>
	asm volatile("pause");
f0104b52:	f3 90                	pause  
		// Uncomment the following line after completing exercise 13
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104b54:	e8 80 19 00 00       	call   f01064d9 <cpunum>
f0104b59:	6b c0 74             	imul   $0x74,%eax,%eax
	asm volatile (
f0104b5c:	8b 80 30 10 23 f0    	mov    -0xfdcefd0(%eax),%eax
f0104b62:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104b67:	89 c4                	mov    %eax,%esp
f0104b69:	6a 00                	push   $0x0
f0104b6b:	6a 00                	push   $0x0
f0104b6d:	fb                   	sti    
f0104b6e:	f4                   	hlt    
f0104b6f:	eb fd                	jmp    f0104b6e <sched_halt+0xd1>
}
f0104b71:	c9                   	leave  
f0104b72:	c3                   	ret    

f0104b73 <sched_yield>:
{
f0104b73:	55                   	push   %ebp
f0104b74:	89 e5                	mov    %esp,%ebp
f0104b76:	56                   	push   %esi
f0104b77:	53                   	push   %ebx
f0104b78:	83 ec 10             	sub    $0x10,%esp
	struct Env *idle = thiscpu->cpu_env;
f0104b7b:	e8 59 19 00 00       	call   f01064d9 <cpunum>
f0104b80:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b83:	8b 98 28 10 23 f0    	mov    -0xfdcefd8(%eax),%ebx
	if(!idle)
f0104b89:	85 db                	test   %ebx,%ebx
f0104b8b:	74 0b                	je     f0104b98 <sched_yield+0x25>
		ID = ENVX(idle->env_id);
f0104b8d:	8b 73 48             	mov    0x48(%ebx),%esi
f0104b90:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0104b96:	eb 05                	jmp    f0104b9d <sched_yield+0x2a>
		ID = 0;
f0104b98:	be 00 00 00 00       	mov    $0x0,%esi
		if (envs[i].env_status == ENV_RUNNABLE){
f0104b9d:	8b 0d 48 02 23 f0    	mov    0xf0230248,%ecx
f0104ba3:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ba8:	6b d0 7c             	imul   $0x7c,%eax,%edx
f0104bab:	01 ca                	add    %ecx,%edx
f0104bad:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f0104bb1:	75 08                	jne    f0104bbb <sched_yield+0x48>
			env_run(&envs[i]);
f0104bb3:	89 14 24             	mov    %edx,(%esp)
f0104bb6:	e8 70 f1 ff ff       	call   f0103d2b <env_run>
	for (; i != ID || first; i = (i + 1) % NENV, first = 0){
f0104bbb:	83 c0 01             	add    $0x1,%eax
f0104bbe:	25 ff 03 00 00       	and    $0x3ff,%eax
f0104bc3:	39 c6                	cmp    %eax,%esi
f0104bc5:	75 e1                	jne    f0104ba8 <sched_yield+0x35>
	if(idle && curenv->env_status == ENV_RUNNING)
f0104bc7:	85 db                	test   %ebx,%ebx
f0104bc9:	74 1c                	je     f0104be7 <sched_yield+0x74>
f0104bcb:	e8 09 19 00 00       	call   f01064d9 <cpunum>
f0104bd0:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bd3:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104bd9:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104bdd:	75 08                	jne    f0104be7 <sched_yield+0x74>
		env_run(idle);
f0104bdf:	89 1c 24             	mov    %ebx,(%esp)
f0104be2:	e8 44 f1 ff ff       	call   f0103d2b <env_run>
	sched_halt();
f0104be7:	e8 b1 fe ff ff       	call   f0104a9d <sched_halt>
}
f0104bec:	83 c4 10             	add    $0x10,%esp
f0104bef:	5b                   	pop    %ebx
f0104bf0:	5e                   	pop    %esi
f0104bf1:	5d                   	pop    %ebp
f0104bf2:	c3                   	ret    
f0104bf3:	66 90                	xchg   %ax,%ax
f0104bf5:	66 90                	xchg   %ax,%ax
f0104bf7:	66 90                	xchg   %ax,%ax
f0104bf9:	66 90                	xchg   %ax,%ax
f0104bfb:	66 90                	xchg   %ax,%ax
f0104bfd:	66 90                	xchg   %ax,%ax
f0104bff:	90                   	nop

f0104c00 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104c00:	55                   	push   %ebp
f0104c01:	89 e5                	mov    %esp,%ebp
f0104c03:	57                   	push   %edi
f0104c04:	56                   	push   %esi
f0104c05:	53                   	push   %ebx
f0104c06:	83 ec 2c             	sub    $0x2c,%esp
f0104c09:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) {
f0104c0c:	83 f8 0c             	cmp    $0xc,%eax
f0104c0f:	0f 87 24 06 00 00    	ja     f0105239 <syscall+0x639>
f0104c15:	ff 24 85 c0 82 10 f0 	jmp    *-0xfef7d40(,%eax,4)
	user_mem_assert(curenv, s, len, PTE_U);
f0104c1c:	e8 b8 18 00 00       	call   f01064d9 <cpunum>
f0104c21:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104c28:	00 
f0104c29:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104c2c:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104c30:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104c33:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104c37:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c3a:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104c40:	89 04 24             	mov    %eax,(%esp)
f0104c43:	e8 54 e9 ff ff       	call   f010359c <user_mem_assert>
	cprintf("%.*s", len, s);
f0104c48:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c4b:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104c4f:	8b 45 10             	mov    0x10(%ebp),%eax
f0104c52:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c56:	c7 04 24 86 82 10 f0 	movl   $0xf0108286,(%esp)
f0104c5d:	e8 01 f3 ff ff       	call   f0103f63 <cprintf>
	case SYS_cputs:
		sys_cputs((char*)a1, a2);
		return 0;
f0104c62:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c67:	e9 d9 05 00 00       	jmp    f0105245 <syscall+0x645>
	return cons_getc();
f0104c6c:	e8 d4 b9 ff ff       	call   f0100645 <cons_getc>

	case SYS_cgetc:
		return sys_cgetc();
f0104c71:	e9 cf 05 00 00       	jmp    f0105245 <syscall+0x645>
	return curenv->env_id;
f0104c76:	e8 5e 18 00 00       	call   f01064d9 <cpunum>
f0104c7b:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c7e:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104c84:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_getenvid:
		return sys_getenvid();
f0104c87:	e9 b9 05 00 00       	jmp    f0105245 <syscall+0x645>
	if ((r = envid2env(envid, &e, 1)) < 0)
f0104c8c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104c93:	00 
f0104c94:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104c97:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c9b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c9e:	89 04 24             	mov    %eax,(%esp)
f0104ca1:	e8 c9 e9 ff ff       	call   f010366f <envid2env>
		return r;
f0104ca6:	89 c2                	mov    %eax,%edx
	if ((r = envid2env(envid, &e, 1)) < 0)
f0104ca8:	85 c0                	test   %eax,%eax
f0104caa:	78 6e                	js     f0104d1a <syscall+0x11a>
	if (e == curenv)
f0104cac:	e8 28 18 00 00       	call   f01064d9 <cpunum>
f0104cb1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104cb4:	6b c0 74             	imul   $0x74,%eax,%eax
f0104cb7:	39 90 28 10 23 f0    	cmp    %edx,-0xfdcefd8(%eax)
f0104cbd:	75 23                	jne    f0104ce2 <syscall+0xe2>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104cbf:	e8 15 18 00 00       	call   f01064d9 <cpunum>
f0104cc4:	6b c0 74             	imul   $0x74,%eax,%eax
f0104cc7:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104ccd:	8b 40 48             	mov    0x48(%eax),%eax
f0104cd0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104cd4:	c7 04 24 8b 82 10 f0 	movl   $0xf010828b,(%esp)
f0104cdb:	e8 83 f2 ff ff       	call   f0103f63 <cprintf>
f0104ce0:	eb 28                	jmp    f0104d0a <syscall+0x10a>
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104ce2:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104ce5:	e8 ef 17 00 00       	call   f01064d9 <cpunum>
f0104cea:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104cee:	6b c0 74             	imul   $0x74,%eax,%eax
f0104cf1:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104cf7:	8b 40 48             	mov    0x48(%eax),%eax
f0104cfa:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104cfe:	c7 04 24 a6 82 10 f0 	movl   $0xf01082a6,(%esp)
f0104d05:	e8 59 f2 ff ff       	call   f0103f63 <cprintf>
	env_destroy(e);
f0104d0a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104d0d:	89 04 24             	mov    %eax,(%esp)
f0104d10:	e8 75 ef ff ff       	call   f0103c8a <env_destroy>
	return 0;
f0104d15:	ba 00 00 00 00       	mov    $0x0,%edx

	case SYS_env_destroy:
		return sys_env_destroy(a1);
f0104d1a:	89 d0                	mov    %edx,%eax
f0104d1c:	e9 24 05 00 00       	jmp    f0105245 <syscall+0x645>
	sched_yield();
f0104d21:	e8 4d fe ff ff       	call   f0104b73 <sched_yield>
	struct Env* newenv = NULL;
f0104d26:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int x = env_alloc(&newenv, curenv->env_id);
f0104d2d:	e8 a7 17 00 00       	call   f01064d9 <cpunum>
f0104d32:	6b c0 74             	imul   $0x74,%eax,%eax
f0104d35:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0104d3b:	8b 40 48             	mov    0x48(%eax),%eax
f0104d3e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d42:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104d45:	89 04 24             	mov    %eax,(%esp)
f0104d48:	e8 26 ea ff ff       	call   f0103773 <env_alloc>
	if (x < 0)
f0104d4d:	85 c0                	test   %eax,%eax
f0104d4f:	78 33                	js     f0104d84 <syscall+0x184>
	newenv->env_status = ENV_NOT_RUNNABLE;
f0104d51:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104d54:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
	newenv->env_tf = curenv->env_tf;
f0104d5b:	e8 79 17 00 00       	call   f01064d9 <cpunum>
f0104d60:	6b c0 74             	imul   $0x74,%eax,%eax
f0104d63:	8b b0 28 10 23 f0    	mov    -0xfdcefd8(%eax),%esi
f0104d69:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104d6e:	89 df                	mov    %ebx,%edi
f0104d70:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	newenv->env_tf.tf_regs.reg_eax = 0;
f0104d72:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104d75:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return newenv->env_id;
f0104d7c:	8b 40 48             	mov    0x48(%eax),%eax
f0104d7f:	e9 c1 04 00 00       	jmp    f0105245 <syscall+0x645>
		return -E_NO_FREE_ENV;
f0104d84:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
	case SYS_yield:
		sys_yield();
		return 0;

	case SYS_exofork:
		return sys_exofork();
f0104d89:	e9 b7 04 00 00       	jmp    f0105245 <syscall+0x645>
	struct Env* environ = NULL;
f0104d8e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int x = envid2env(envid, &environ, 1);
f0104d95:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104d9c:	00 
f0104d9d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104da0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104da4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104da7:	89 04 24             	mov    %eax,(%esp)
f0104daa:	e8 c0 e8 ff ff       	call   f010366f <envid2env>
	if (x < 0)
f0104daf:	85 c0                	test   %eax,%eax
f0104db1:	0f 88 8e 04 00 00    	js     f0105245 <syscall+0x645>
	if (status != ENV_RUNNABLE && status != ENV_NOT_RUNNABLE)
f0104db7:	83 7d 10 04          	cmpl   $0x4,0x10(%ebp)
f0104dbb:	74 06                	je     f0104dc3 <syscall+0x1c3>
f0104dbd:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
f0104dc1:	75 13                	jne    f0104dd6 <syscall+0x1d6>
	environ->env_status = status;
f0104dc3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104dc6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104dc9:	89 48 54             	mov    %ecx,0x54(%eax)
	return 0;
f0104dcc:	b8 00 00 00 00       	mov    $0x0,%eax
f0104dd1:	e9 6f 04 00 00       	jmp    f0105245 <syscall+0x645>
		return -E_INVAL;
f0104dd6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	case SYS_env_set_status:
		return sys_env_set_status(a1, a2);
f0104ddb:	e9 65 04 00 00       	jmp    f0105245 <syscall+0x645>
	struct Env* environ = NULL;
f0104de0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int x = envid2env(envid, &environ, 1);
f0104de7:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104dee:	00 
f0104def:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104df2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104df6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104df9:	89 04 24             	mov    %eax,(%esp)
f0104dfc:	e8 6e e8 ff ff       	call   f010366f <envid2env>
	if (x < 0)
f0104e01:	85 c0                	test   %eax,%eax
f0104e03:	0f 88 3c 04 00 00    	js     f0105245 <syscall+0x645>
	environ->env_pgfault_upcall = func;
f0104e09:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104e0c:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104e0f:	89 78 64             	mov    %edi,0x64(%eax)
	return 0;
f0104e12:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e17:	e9 29 04 00 00       	jmp    f0105245 <syscall+0x645>
	struct Env* environ = NULL;
f0104e1c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int x = envid2env(envid, &environ, 1);
f0104e23:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104e2a:	00 
f0104e2b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104e2e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e32:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104e35:	89 04 24             	mov    %eax,(%esp)
f0104e38:	e8 32 e8 ff ff       	call   f010366f <envid2env>
	if (x < 0)
f0104e3d:	85 c0                	test   %eax,%eax
f0104e3f:	78 6d                	js     f0104eae <syscall+0x2ae>
	if ((uint32_t)va >= UTOP || ((int32_t)va % PGSIZE != 0))
f0104e41:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104e48:	77 6b                	ja     f0104eb5 <syscall+0x2b5>
f0104e4a:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104e51:	75 69                	jne    f0104ebc <syscall+0x2bc>
	if (!((perm & PTE_U) && (perm & PTE_P)))
f0104e53:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e56:	83 e0 05             	and    $0x5,%eax
f0104e59:	83 f8 05             	cmp    $0x5,%eax
f0104e5c:	75 65                	jne    f0104ec3 <syscall+0x2c3>
	if (perm & ~(PTE_U | PTE_P | PTE_W | PTE_AVAIL))
f0104e5e:	8b 75 14             	mov    0x14(%ebp),%esi
f0104e61:	81 e6 f8 f1 ff ff    	and    $0xfffff1f8,%esi
f0104e67:	75 61                	jne    f0104eca <syscall+0x2ca>
	struct PageInfo *NP = page_alloc(ALLOC_ZERO);
f0104e69:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0104e70:	e8 7d c2 ff ff       	call   f01010f2 <page_alloc>
f0104e75:	89 c3                	mov    %eax,%ebx
	if (NP == NULL)
f0104e77:	85 c0                	test   %eax,%eax
f0104e79:	74 56                	je     f0104ed1 <syscall+0x2d1>
	x = page_insert(environ->env_pgdir, NP, va, perm);
f0104e7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e7e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104e82:	8b 45 10             	mov    0x10(%ebp),%eax
f0104e85:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104e89:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104e8d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104e90:	8b 40 60             	mov    0x60(%eax),%eax
f0104e93:	89 04 24             	mov    %eax,(%esp)
f0104e96:	e8 98 c5 ff ff       	call   f0101433 <page_insert>
	if (x < 0)
f0104e9b:	85 c0                	test   %eax,%eax
f0104e9d:	79 37                	jns    f0104ed6 <syscall+0x2d6>
		page_free(NP);
f0104e9f:	89 1c 24             	mov    %ebx,(%esp)
f0104ea2:	e8 d6 c2 ff ff       	call   f010117d <page_free>
		return -E_NO_MEM;
f0104ea7:	be fc ff ff ff       	mov    $0xfffffffc,%esi
f0104eac:	eb 28                	jmp    f0104ed6 <syscall+0x2d6>
		return -E_BAD_ENV;
f0104eae:	be fe ff ff ff       	mov    $0xfffffffe,%esi
f0104eb3:	eb 21                	jmp    f0104ed6 <syscall+0x2d6>
		return -E_INVAL;
f0104eb5:	be fd ff ff ff       	mov    $0xfffffffd,%esi
f0104eba:	eb 1a                	jmp    f0104ed6 <syscall+0x2d6>
f0104ebc:	be fd ff ff ff       	mov    $0xfffffffd,%esi
f0104ec1:	eb 13                	jmp    f0104ed6 <syscall+0x2d6>
		return -E_INVAL;
f0104ec3:	be fd ff ff ff       	mov    $0xfffffffd,%esi
f0104ec8:	eb 0c                	jmp    f0104ed6 <syscall+0x2d6>
		return -E_INVAL;
f0104eca:	be fd ff ff ff       	mov    $0xfffffffd,%esi
f0104ecf:	eb 05                	jmp    f0104ed6 <syscall+0x2d6>
		return -E_NO_MEM;
f0104ed1:	be fc ff ff ff       	mov    $0xfffffffc,%esi

	case SYS_env_set_pgfault_upcall:
		return sys_env_set_pgfault_upcall(a1, (void *)a2);

	case SYS_page_alloc:
		return sys_page_alloc(a1, (void *)a2, a3);
f0104ed6:	89 f0                	mov    %esi,%eax
f0104ed8:	e9 68 03 00 00       	jmp    f0105245 <syscall+0x645>
	struct Env *source = NULL;
f0104edd:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	struct Env *dest = NULL;
f0104ee4:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	if ((envid2env(srcenvid, &source, 1) < 0) || (envid2env(dstenvid, &dest, 1) < 0)) 
f0104eeb:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104ef2:	00 
f0104ef3:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104ef6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104efa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104efd:	89 04 24             	mov    %eax,(%esp)
f0104f00:	e8 6a e7 ff ff       	call   f010366f <envid2env>
		return x;
f0104f05:	ba 00 00 00 00       	mov    $0x0,%edx
	if ((envid2env(srcenvid, &source, 1) < 0) || (envid2env(dstenvid, &dest, 1) < 0)) 
f0104f0a:	85 c0                	test   %eax,%eax
f0104f0c:	0f 88 13 01 00 00    	js     f0105025 <syscall+0x425>
f0104f12:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104f19:	00 
f0104f1a:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104f1d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104f21:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f24:	89 04 24             	mov    %eax,(%esp)
f0104f27:	e8 43 e7 ff ff       	call   f010366f <envid2env>
f0104f2c:	85 c0                	test   %eax,%eax
f0104f2e:	0f 88 bb 00 00 00    	js     f0104fef <syscall+0x3ef>
	if ((int)srcva >= UTOP || (srcva != ROUNDUP(srcva, PGSIZE)))//((int32_t)srcva % PGSIZE != 0))
f0104f34:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104f3b:	0f 87 b5 00 00 00    	ja     f0104ff6 <syscall+0x3f6>
f0104f41:	8b 45 10             	mov    0x10(%ebp),%eax
f0104f44:	05 ff 0f 00 00       	add    $0xfff,%eax
f0104f49:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0104f4e:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104f51:	0f 85 a6 00 00 00    	jne    f0104ffd <syscall+0x3fd>
	if ((int)dstva >= UTOP || (dstva != ROUNDUP(dstva, PGSIZE)))//((int32_t)dstva % PGSIZE != 0))
f0104f57:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104f5e:	0f 87 a0 00 00 00    	ja     f0105004 <syscall+0x404>
f0104f64:	8b 45 18             	mov    0x18(%ebp),%eax
f0104f67:	05 ff 0f 00 00       	add    $0xfff,%eax
f0104f6c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
		return -E_INVAL;
f0104f71:	ba fd ff ff ff       	mov    $0xfffffffd,%edx
	if ((int)dstva >= UTOP || (dstva != ROUNDUP(dstva, PGSIZE)))//((int32_t)dstva % PGSIZE != 0))
f0104f76:	39 45 18             	cmp    %eax,0x18(%ebp)
f0104f79:	0f 85 a6 00 00 00    	jne    f0105025 <syscall+0x425>
	pte_t * sourcePTentry = NULL;
f0104f7f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	struct PageInfo *sourcePage = page_lookup(source->env_pgdir, srcva, &sourcePTentry);
f0104f86:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104f89:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104f8d:	8b 45 10             	mov    0x10(%ebp),%eax
f0104f90:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104f94:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104f97:	8b 40 60             	mov    0x60(%eax),%eax
f0104f9a:	89 04 24             	mov    %eax,(%esp)
f0104f9d:	e8 9b c3 ff ff       	call   f010133d <page_lookup>
	if (sourcePage == NULL)
f0104fa2:	85 c0                	test   %eax,%eax
f0104fa4:	74 65                	je     f010500b <syscall+0x40b>
	if ((!(perm & (PTE_U|PTE_P))) || (perm & ~(PTE_U|PTE_P|PTE_W|PTE_AVAIL)) || ((perm & PTE_W) && !(*sourcePTentry & PTE_W)))
f0104fa6:	f6 45 1c 05          	testb  $0x5,0x1c(%ebp)
f0104faa:	74 66                	je     f0105012 <syscall+0x412>
f0104fac:	f7 45 1c f8 f1 ff ff 	testl  $0xfffff1f8,0x1c(%ebp)
f0104fb3:	75 64                	jne    f0105019 <syscall+0x419>
f0104fb5:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104fb9:	74 08                	je     f0104fc3 <syscall+0x3c3>
f0104fbb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104fbe:	f6 02 02             	testb  $0x2,(%edx)
f0104fc1:	74 5d                	je     f0105020 <syscall+0x420>
	x = page_insert(dest->env_pgdir, sourcePage, dstva, perm);
f0104fc3:	8b 4d 1c             	mov    0x1c(%ebp),%ecx
f0104fc6:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104fca:	8b 75 18             	mov    0x18(%ebp),%esi
f0104fcd:	89 74 24 08          	mov    %esi,0x8(%esp)
f0104fd1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104fd5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104fd8:	8b 40 60             	mov    0x60(%eax),%eax
f0104fdb:	89 04 24             	mov    %eax,(%esp)
f0104fde:	e8 50 c4 ff ff       	call   f0101433 <page_insert>
f0104fe3:	85 c0                	test   %eax,%eax
f0104fe5:	ba 00 00 00 00       	mov    $0x0,%edx
f0104fea:	0f 4e d0             	cmovle %eax,%edx
f0104fed:	eb 36                	jmp    f0105025 <syscall+0x425>
		return x;
f0104fef:	ba 00 00 00 00       	mov    $0x0,%edx
f0104ff4:	eb 2f                	jmp    f0105025 <syscall+0x425>
		return -E_INVAL;
f0104ff6:	ba fd ff ff ff       	mov    $0xfffffffd,%edx
f0104ffb:	eb 28                	jmp    f0105025 <syscall+0x425>
f0104ffd:	ba fd ff ff ff       	mov    $0xfffffffd,%edx
f0105002:	eb 21                	jmp    f0105025 <syscall+0x425>
		return -E_INVAL;
f0105004:	ba fd ff ff ff       	mov    $0xfffffffd,%edx
f0105009:	eb 1a                	jmp    f0105025 <syscall+0x425>
		return -E_INVAL;
f010500b:	ba fd ff ff ff       	mov    $0xfffffffd,%edx
f0105010:	eb 13                	jmp    f0105025 <syscall+0x425>
		return -E_INVAL;
f0105012:	ba fd ff ff ff       	mov    $0xfffffffd,%edx
f0105017:	eb 0c                	jmp    f0105025 <syscall+0x425>
f0105019:	ba fd ff ff ff       	mov    $0xfffffffd,%edx
f010501e:	eb 05                	jmp    f0105025 <syscall+0x425>
f0105020:	ba fd ff ff ff       	mov    $0xfffffffd,%edx

	case SYS_page_map:
		return sys_page_map(a1, (void *)a2, a3, (void *)a4, a5);
f0105025:	89 d0                	mov    %edx,%eax
f0105027:	e9 19 02 00 00       	jmp    f0105245 <syscall+0x645>
	struct Env* environ = NULL;
f010502c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int x = envid2env(envid, &environ, 1);
f0105033:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010503a:	00 
f010503b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010503e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105042:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105045:	89 04 24             	mov    %eax,(%esp)
f0105048:	e8 22 e6 ff ff       	call   f010366f <envid2env>
	if(x < 0)
f010504d:	85 c0                	test   %eax,%eax
f010504f:	0f 88 f0 01 00 00    	js     f0105245 <syscall+0x645>
	if ((int)va >= UTOP || (va != ROUNDUP(va, PGSIZE)))//((int32_t)va % PGSIZE != 0))
f0105055:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f010505c:	77 3c                	ja     f010509a <syscall+0x49a>
f010505e:	8b 45 10             	mov    0x10(%ebp),%eax
f0105061:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0105067:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
		return -E_INVAL;
f010506d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	if ((int)va >= UTOP || (va != ROUNDUP(va, PGSIZE)))//((int32_t)va % PGSIZE != 0))
f0105072:	39 55 10             	cmp    %edx,0x10(%ebp)
f0105075:	0f 85 ca 01 00 00    	jne    f0105245 <syscall+0x645>
	page_remove(environ->env_pgdir, va);
f010507b:	8b 45 10             	mov    0x10(%ebp),%eax
f010507e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105082:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105085:	8b 40 60             	mov    0x60(%eax),%eax
f0105088:	89 04 24             	mov    %eax,(%esp)
f010508b:	e8 5a c3 ff ff       	call   f01013ea <page_remove>
	return 0;
f0105090:	b8 00 00 00 00       	mov    $0x0,%eax
f0105095:	e9 ab 01 00 00       	jmp    f0105245 <syscall+0x645>
		return -E_INVAL;
f010509a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	case SYS_page_unmap:
		return sys_page_unmap(a1, (void *)a2);
f010509f:	e9 a1 01 00 00       	jmp    f0105245 <syscall+0x645>
	struct Env* environ = NULL;
f01050a4:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	int x = envid2env(envid, &environ, 0);
f01050ab:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01050b2:	00 
f01050b3:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01050b6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01050ba:	8b 45 0c             	mov    0xc(%ebp),%eax
f01050bd:	89 04 24             	mov    %eax,(%esp)
f01050c0:	e8 aa e5 ff ff       	call   f010366f <envid2env>
	if (x < 0)
f01050c5:	85 c0                	test   %eax,%eax
f01050c7:	0f 88 78 01 00 00    	js     f0105245 <syscall+0x645>
	if (!environ->env_ipc_recving)
f01050cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01050d0:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f01050d4:	0f 84 dc 00 00 00    	je     f01051b6 <syscall+0x5b6>
	if (srcva < (void *)UTOP)
f01050da:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f01050e1:	77 11                	ja     f01050f4 <syscall+0x4f4>
		if (srcva != ROUNDDOWN(srcva, PGSIZE))
f01050e3:	8b 45 14             	mov    0x14(%ebp),%eax
f01050e6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01050eb:	39 45 14             	cmp    %eax,0x14(%ebp)
f01050ee:	0f 85 cc 00 00 00    	jne    f01051c0 <syscall+0x5c0>
	struct PageInfo *page = page_lookup(curenv->env_pgdir, srcva, &PTentry);
f01050f4:	e8 e0 13 00 00       	call   f01064d9 <cpunum>
f01050f9:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01050fc:	89 54 24 08          	mov    %edx,0x8(%esp)
f0105100:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0105103:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105107:	6b c0 74             	imul   $0x74,%eax,%eax
f010510a:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0105110:	8b 40 60             	mov    0x60(%eax),%eax
f0105113:	89 04 24             	mov    %eax,(%esp)
f0105116:	e8 22 c2 ff ff       	call   f010133d <page_lookup>
	if (!page || (*PTentry & perm) != perm)
f010511b:	85 c0                	test   %eax,%eax
f010511d:	0f 84 a4 00 00 00    	je     f01051c7 <syscall+0x5c7>
f0105123:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0105126:	8b 12                	mov    (%edx),%edx
f0105128:	89 d1                	mov    %edx,%ecx
f010512a:	23 4d 18             	and    0x18(%ebp),%ecx
f010512d:	39 4d 18             	cmp    %ecx,0x18(%ebp)
f0105130:	0f 85 98 00 00 00    	jne    f01051ce <syscall+0x5ce>
	if (perm & PTE_W && !(*PTentry & PTE_W))
f0105136:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f010513a:	74 09                	je     f0105145 <syscall+0x545>
f010513c:	f6 c2 02             	test   $0x2,%dl
f010513f:	0f 84 90 00 00 00    	je     f01051d5 <syscall+0x5d5>
	if (environ->env_ipc_dstva < (void *)UTOP)
f0105145:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0105148:	8b 4a 6c             	mov    0x6c(%edx),%ecx
f010514b:	81 f9 ff ff bf ee    	cmp    $0xeebfffff,%ecx
f0105151:	77 27                	ja     f010517a <syscall+0x57a>
		x = page_insert(environ->env_pgdir, page, environ->env_ipc_dstva, perm);
f0105153:	8b 7d 18             	mov    0x18(%ebp),%edi
f0105156:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010515a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010515e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105162:	8b 42 60             	mov    0x60(%edx),%eax
f0105165:	89 04 24             	mov    %eax,(%esp)
f0105168:	e8 c6 c2 ff ff       	call   f0101433 <page_insert>
		if (x < 0)
f010516d:	85 c0                	test   %eax,%eax
f010516f:	78 6b                	js     f01051dc <syscall+0x5dc>
		environ->env_ipc_perm = perm;
f0105171:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105174:	8b 7d 18             	mov    0x18(%ebp),%edi
f0105177:	89 78 78             	mov    %edi,0x78(%eax)
	environ->env_ipc_from = curenv->env_id;
f010517a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010517d:	e8 57 13 00 00       	call   f01064d9 <cpunum>
f0105182:	6b c0 74             	imul   $0x74,%eax,%eax
f0105185:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f010518b:	8b 40 48             	mov    0x48(%eax),%eax
f010518e:	89 43 74             	mov    %eax,0x74(%ebx)
	environ->env_ipc_value = value;
f0105191:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105194:	8b 75 10             	mov    0x10(%ebp),%esi
f0105197:	89 70 70             	mov    %esi,0x70(%eax)
	environ->env_ipc_recving = 0;
f010519a:	c6 40 68 00          	movb   $0x0,0x68(%eax)
	environ->env_status = ENV_RUNNABLE;
f010519e:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	environ->env_tf.tf_regs.reg_eax = 0;
f01051a5:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return 0;
f01051ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01051b1:	e9 8f 00 00 00       	jmp    f0105245 <syscall+0x645>
		return -E_IPC_NOT_RECV;
f01051b6:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
f01051bb:	e9 85 00 00 00       	jmp    f0105245 <syscall+0x645>
			return -E_INVAL;
f01051c0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01051c5:	eb 7e                	jmp    f0105245 <syscall+0x645>
		return -E_INVAL;
f01051c7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01051cc:	eb 77                	jmp    f0105245 <syscall+0x645>
f01051ce:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01051d3:	eb 70                	jmp    f0105245 <syscall+0x645>
		return -E_INVAL;
f01051d5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01051da:	eb 69                	jmp    f0105245 <syscall+0x645>
			return -E_NO_MEM;
f01051dc:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax

	case SYS_ipc_try_send:
		return sys_ipc_try_send(a1, a2, (void *)a3, a4);
f01051e1:	eb 62                	jmp    f0105245 <syscall+0x645>
	if (dstva < (void *)UTOP && dstva != ROUNDDOWN(dstva, PGSIZE))//((uint32_t)dstva % PGSIZE != 0))
f01051e3:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f01051ea:	77 0d                	ja     f01051f9 <syscall+0x5f9>
f01051ec:	8b 45 0c             	mov    0xc(%ebp),%eax
f01051ef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01051f4:	39 45 0c             	cmp    %eax,0xc(%ebp)
f01051f7:	75 47                	jne    f0105240 <syscall+0x640>
	curenv->env_ipc_recving = 1;
f01051f9:	e8 db 12 00 00       	call   f01064d9 <cpunum>
f01051fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0105201:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0105207:	c6 40 68 01          	movb   $0x1,0x68(%eax)
	curenv->env_ipc_dstva = dstva;
f010520b:	e8 c9 12 00 00       	call   f01064d9 <cpunum>
f0105210:	6b c0 74             	imul   $0x74,%eax,%eax
f0105213:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0105219:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010521c:	89 58 6c             	mov    %ebx,0x6c(%eax)
	curenv->env_status = ENV_NOT_RUNNABLE;
f010521f:	e8 b5 12 00 00       	call   f01064d9 <cpunum>
f0105224:	6b c0 74             	imul   $0x74,%eax,%eax
f0105227:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f010522d:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	sched_yield();
f0105234:	e8 3a f9 ff ff       	call   f0104b73 <sched_yield>

	case SYS_ipc_recv:
		return sys_ipc_recv((void *)a1);

	default:
		return -E_INVAL;
f0105239:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010523e:	eb 05                	jmp    f0105245 <syscall+0x645>
		return sys_ipc_recv((void *)a1);
f0105240:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f0105245:	83 c4 2c             	add    $0x2c,%esp
f0105248:	5b                   	pop    %ebx
f0105249:	5e                   	pop    %esi
f010524a:	5f                   	pop    %edi
f010524b:	5d                   	pop    %ebp
f010524c:	c3                   	ret    

f010524d <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010524d:	55                   	push   %ebp
f010524e:	89 e5                	mov    %esp,%ebp
f0105250:	57                   	push   %edi
f0105251:	56                   	push   %esi
f0105252:	53                   	push   %ebx
f0105253:	83 ec 14             	sub    $0x14,%esp
f0105256:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105259:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010525c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010525f:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0105262:	8b 1a                	mov    (%edx),%ebx
f0105264:	8b 01                	mov    (%ecx),%eax
f0105266:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0105269:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0105270:	e9 88 00 00 00       	jmp    f01052fd <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0105275:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105278:	01 d8                	add    %ebx,%eax
f010527a:	89 c7                	mov    %eax,%edi
f010527c:	c1 ef 1f             	shr    $0x1f,%edi
f010527f:	01 c7                	add    %eax,%edi
f0105281:	d1 ff                	sar    %edi
f0105283:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0105286:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0105289:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010528c:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010528e:	eb 03                	jmp    f0105293 <stab_binsearch+0x46>
			m--;
f0105290:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0105293:	39 c3                	cmp    %eax,%ebx
f0105295:	7f 1f                	jg     f01052b6 <stab_binsearch+0x69>
f0105297:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010529b:	83 ea 0c             	sub    $0xc,%edx
f010529e:	39 f1                	cmp    %esi,%ecx
f01052a0:	75 ee                	jne    f0105290 <stab_binsearch+0x43>
f01052a2:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01052a5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01052a8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01052ab:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01052af:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01052b2:	76 18                	jbe    f01052cc <stab_binsearch+0x7f>
f01052b4:	eb 05                	jmp    f01052bb <stab_binsearch+0x6e>
			l = true_m + 1;
f01052b6:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01052b9:	eb 42                	jmp    f01052fd <stab_binsearch+0xb0>
			*region_left = m;
f01052bb:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01052be:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01052c0:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f01052c3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01052ca:	eb 31                	jmp    f01052fd <stab_binsearch+0xb0>
		} else if (stabs[m].n_value > addr) {
f01052cc:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01052cf:	73 17                	jae    f01052e8 <stab_binsearch+0x9b>
			*region_right = m - 1;
f01052d1:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01052d4:	83 e8 01             	sub    $0x1,%eax
f01052d7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01052da:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01052dd:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f01052df:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01052e6:	eb 15                	jmp    f01052fd <stab_binsearch+0xb0>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01052e8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01052eb:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01052ee:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f01052f0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01052f4:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f01052f6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01052fd:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0105300:	0f 8e 6f ff ff ff    	jle    f0105275 <stab_binsearch+0x28>
		}
	}

	if (!any_matches)
f0105306:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010530a:	75 0f                	jne    f010531b <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f010530c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010530f:	8b 00                	mov    (%eax),%eax
f0105311:	83 e8 01             	sub    $0x1,%eax
f0105314:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0105317:	89 07                	mov    %eax,(%edi)
f0105319:	eb 2c                	jmp    f0105347 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010531b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010531e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0105320:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105323:	8b 0f                	mov    (%edi),%ecx
f0105325:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0105328:	8b 7d ec             	mov    -0x14(%ebp),%edi
f010532b:	8d 14 97             	lea    (%edi,%edx,4),%edx
		for (l = *region_right;
f010532e:	eb 03                	jmp    f0105333 <stab_binsearch+0xe6>
		     l--)
f0105330:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0105333:	39 c8                	cmp    %ecx,%eax
f0105335:	7e 0b                	jle    f0105342 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0105337:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010533b:	83 ea 0c             	sub    $0xc,%edx
f010533e:	39 f3                	cmp    %esi,%ebx
f0105340:	75 ee                	jne    f0105330 <stab_binsearch+0xe3>
			/* do nothing */;
		*region_left = l;
f0105342:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105345:	89 07                	mov    %eax,(%edi)
	}
}
f0105347:	83 c4 14             	add    $0x14,%esp
f010534a:	5b                   	pop    %ebx
f010534b:	5e                   	pop    %esi
f010534c:	5f                   	pop    %edi
f010534d:	5d                   	pop    %ebp
f010534e:	c3                   	ret    

f010534f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010534f:	55                   	push   %ebp
f0105350:	89 e5                	mov    %esp,%ebp
f0105352:	57                   	push   %edi
f0105353:	56                   	push   %esi
f0105354:	53                   	push   %ebx
f0105355:	83 ec 4c             	sub    $0x4c,%esp
f0105358:	8b 75 08             	mov    0x8(%ebp),%esi
f010535b:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010535e:	c7 07 f4 82 10 f0    	movl   $0xf01082f4,(%edi)
	info->eip_line = 0;
f0105364:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f010536b:	c7 47 08 f4 82 10 f0 	movl   $0xf01082f4,0x8(%edi)
	info->eip_fn_namelen = 9;
f0105372:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0105379:	89 77 10             	mov    %esi,0x10(%edi)
	info->eip_fn_narg = 0;
f010537c:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0105383:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0105389:	0f 87 ca 00 00 00    	ja     f0105459 <debuginfo_eip+0x10a>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(usd), PTE_U) != 0)
f010538f:	e8 45 11 00 00       	call   f01064d9 <cpunum>
f0105394:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f010539b:	00 
f010539c:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f01053a3:	00 
f01053a4:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f01053ab:	00 
f01053ac:	6b c0 74             	imul   $0x74,%eax,%eax
f01053af:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f01053b5:	89 04 24             	mov    %eax,(%esp)
f01053b8:	e8 50 e1 ff ff       	call   f010350d <user_mem_check>
f01053bd:	85 c0                	test   %eax,%eax
f01053bf:	0f 85 5a 02 00 00    	jne    f010561f <debuginfo_eip+0x2d0>
		{
			return -1;
		}

		stabs = usd->stabs;
f01053c5:	a1 00 00 20 00       	mov    0x200000,%eax
f01053ca:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f01053cd:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f01053d3:	8b 15 08 00 20 00    	mov    0x200008,%edx
f01053d9:	89 55 c0             	mov    %edx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f01053dc:	a1 0c 00 20 00       	mov    0x20000c,%eax
f01053e1:	89 45 bc             	mov    %eax,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end - stabs, PTE_P | PTE_U) != 0)
f01053e4:	e8 f0 10 00 00       	call   f01064d9 <cpunum>
f01053e9:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f01053f0:	00 
f01053f1:	89 da                	mov    %ebx,%edx
f01053f3:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01053f6:	29 ca                	sub    %ecx,%edx
f01053f8:	c1 fa 02             	sar    $0x2,%edx
f01053fb:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0105401:	89 54 24 08          	mov    %edx,0x8(%esp)
f0105405:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105409:	6b c0 74             	imul   $0x74,%eax,%eax
f010540c:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0105412:	89 04 24             	mov    %eax,(%esp)
f0105415:	e8 f3 e0 ff ff       	call   f010350d <user_mem_check>
f010541a:	85 c0                	test   %eax,%eax
f010541c:	0f 85 04 02 00 00    	jne    f0105626 <debuginfo_eip+0x2d7>
		{
			return -1;
		}
		if (user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_P | PTE_U) != 0)
f0105422:	e8 b2 10 00 00       	call   f01064d9 <cpunum>
f0105427:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f010542e:	00 
f010542f:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0105432:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0105435:	29 ca                	sub    %ecx,%edx
f0105437:	89 54 24 08          	mov    %edx,0x8(%esp)
f010543b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010543f:	6b c0 74             	imul   $0x74,%eax,%eax
f0105442:	8b 80 28 10 23 f0    	mov    -0xfdcefd8(%eax),%eax
f0105448:	89 04 24             	mov    %eax,(%esp)
f010544b:	e8 bd e0 ff ff       	call   f010350d <user_mem_check>
f0105450:	85 c0                	test   %eax,%eax
f0105452:	74 1f                	je     f0105473 <debuginfo_eip+0x124>
f0105454:	e9 d4 01 00 00       	jmp    f010562d <debuginfo_eip+0x2de>
		stabstr_end = __STABSTR_END__;
f0105459:	c7 45 bc 05 66 11 f0 	movl   $0xf0116605,-0x44(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0105460:	c7 45 c0 b5 2e 11 f0 	movl   $0xf0112eb5,-0x40(%ebp)
		stab_end = __STAB_END__;
f0105467:	bb b4 2e 11 f0       	mov    $0xf0112eb4,%ebx
		stabs = __STAB_BEGIN__;
f010546c:	c7 45 c4 d4 87 10 f0 	movl   $0xf01087d4,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0105473:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0105476:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0105479:	0f 83 b5 01 00 00    	jae    f0105634 <debuginfo_eip+0x2e5>
f010547f:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0105483:	0f 85 b2 01 00 00    	jne    f010563b <debuginfo_eip+0x2ec>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0105489:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0105490:	2b 5d c4             	sub    -0x3c(%ebp),%ebx
f0105493:	c1 fb 02             	sar    $0x2,%ebx
f0105496:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f010549c:	83 e8 01             	sub    $0x1,%eax
f010549f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01054a2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01054a6:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01054ad:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01054b0:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01054b3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01054b6:	89 d8                	mov    %ebx,%eax
f01054b8:	e8 90 fd ff ff       	call   f010524d <stab_binsearch>
	if (lfile == 0)
f01054bd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01054c0:	85 c0                	test   %eax,%eax
f01054c2:	0f 84 7a 01 00 00    	je     f0105642 <debuginfo_eip+0x2f3>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01054c8:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01054cb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01054ce:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01054d1:	89 74 24 04          	mov    %esi,0x4(%esp)
f01054d5:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01054dc:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01054df:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01054e2:	89 d8                	mov    %ebx,%eax
f01054e4:	e8 64 fd ff ff       	call   f010524d <stab_binsearch>

	if (lfun <= rfun) {
f01054e9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01054ec:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01054ef:	39 d8                	cmp    %ebx,%eax
f01054f1:	7f 32                	jg     f0105525 <debuginfo_eip+0x1d6>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01054f3:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01054f6:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01054f9:	8d 14 91             	lea    (%ecx,%edx,4),%edx
f01054fc:	8b 0a                	mov    (%edx),%ecx
f01054fe:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f0105501:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0105504:	2b 4d c0             	sub    -0x40(%ebp),%ecx
f0105507:	39 4d b8             	cmp    %ecx,-0x48(%ebp)
f010550a:	73 09                	jae    f0105515 <debuginfo_eip+0x1c6>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010550c:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f010550f:	03 4d c0             	add    -0x40(%ebp),%ecx
f0105512:	89 4f 08             	mov    %ecx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0105515:	8b 52 08             	mov    0x8(%edx),%edx
f0105518:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f010551b:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010551d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0105520:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0105523:	eb 0f                	jmp    f0105534 <debuginfo_eip+0x1e5>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0105525:	89 77 10             	mov    %esi,0x10(%edi)
		lline = lfile;
f0105528:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010552b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010552e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105531:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0105534:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f010553b:	00 
f010553c:	8b 47 08             	mov    0x8(%edi),%eax
f010553f:	89 04 24             	mov    %eax,(%esp)
f0105542:	e8 24 09 00 00       	call   f0105e6b <strfind>
f0105547:	2b 47 08             	sub    0x8(%edi),%eax
f010554a:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010554d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105551:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0105558:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010555b:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010555e:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0105561:	89 f0                	mov    %esi,%eax
f0105563:	e8 e5 fc ff ff       	call   f010524d <stab_binsearch>
	
	if (lline <= rline)
f0105568:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010556b:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f010556e:	0f 8f d5 00 00 00    	jg     f0105649 <debuginfo_eip+0x2fa>
	{
		info->eip_line = stabs[lline].n_desc;
f0105574:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0105577:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f010557c:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010557f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105582:	89 c3                	mov    %eax,%ebx
f0105584:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105587:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010558a:	8d 14 96             	lea    (%esi,%edx,4),%edx
f010558d:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0105590:	89 df                	mov    %ebx,%edi
f0105592:	eb 06                	jmp    f010559a <debuginfo_eip+0x24b>
f0105594:	83 e8 01             	sub    $0x1,%eax
f0105597:	83 ea 0c             	sub    $0xc,%edx
f010559a:	89 c6                	mov    %eax,%esi
f010559c:	39 c7                	cmp    %eax,%edi
f010559e:	7f 3c                	jg     f01055dc <debuginfo_eip+0x28d>
	       && stabs[lline].n_type != N_SOL
f01055a0:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01055a4:	80 f9 84             	cmp    $0x84,%cl
f01055a7:	75 08                	jne    f01055b1 <debuginfo_eip+0x262>
f01055a9:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01055ac:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01055af:	eb 11                	jmp    f01055c2 <debuginfo_eip+0x273>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01055b1:	80 f9 64             	cmp    $0x64,%cl
f01055b4:	75 de                	jne    f0105594 <debuginfo_eip+0x245>
f01055b6:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01055ba:	74 d8                	je     f0105594 <debuginfo_eip+0x245>
f01055bc:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01055bf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01055c2:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01055c5:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01055c8:	8b 04 86             	mov    (%esi,%eax,4),%eax
f01055cb:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01055ce:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01055d1:	39 d0                	cmp    %edx,%eax
f01055d3:	73 0a                	jae    f01055df <debuginfo_eip+0x290>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01055d5:	03 45 c0             	add    -0x40(%ebp),%eax
f01055d8:	89 07                	mov    %eax,(%edi)
f01055da:	eb 03                	jmp    f01055df <debuginfo_eip+0x290>
f01055dc:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01055df:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01055e2:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01055e5:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01055ea:	39 da                	cmp    %ebx,%edx
f01055ec:	7d 67                	jge    f0105655 <debuginfo_eip+0x306>
		for (lline = lfun + 1;
f01055ee:	83 c2 01             	add    $0x1,%edx
f01055f1:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01055f4:	89 d0                	mov    %edx,%eax
f01055f6:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01055f9:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01055fc:	8d 14 96             	lea    (%esi,%edx,4),%edx
f01055ff:	eb 04                	jmp    f0105605 <debuginfo_eip+0x2b6>
			info->eip_fn_narg++;
f0105601:	83 47 14 01          	addl   $0x1,0x14(%edi)
		for (lline = lfun + 1;
f0105605:	39 c3                	cmp    %eax,%ebx
f0105607:	7e 47                	jle    f0105650 <debuginfo_eip+0x301>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0105609:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010560d:	83 c0 01             	add    $0x1,%eax
f0105610:	83 c2 0c             	add    $0xc,%edx
f0105613:	80 f9 a0             	cmp    $0xa0,%cl
f0105616:	74 e9                	je     f0105601 <debuginfo_eip+0x2b2>
	return 0;
f0105618:	b8 00 00 00 00       	mov    $0x0,%eax
f010561d:	eb 36                	jmp    f0105655 <debuginfo_eip+0x306>
			return -1;
f010561f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105624:	eb 2f                	jmp    f0105655 <debuginfo_eip+0x306>
			return -1;
f0105626:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010562b:	eb 28                	jmp    f0105655 <debuginfo_eip+0x306>
			return -1;
f010562d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105632:	eb 21                	jmp    f0105655 <debuginfo_eip+0x306>
		return -1;
f0105634:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105639:	eb 1a                	jmp    f0105655 <debuginfo_eip+0x306>
f010563b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105640:	eb 13                	jmp    f0105655 <debuginfo_eip+0x306>
		return -1;
f0105642:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105647:	eb 0c                	jmp    f0105655 <debuginfo_eip+0x306>
		return -1;
f0105649:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010564e:	eb 05                	jmp    f0105655 <debuginfo_eip+0x306>
	return 0;
f0105650:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105655:	83 c4 4c             	add    $0x4c,%esp
f0105658:	5b                   	pop    %ebx
f0105659:	5e                   	pop    %esi
f010565a:	5f                   	pop    %edi
f010565b:	5d                   	pop    %ebp
f010565c:	c3                   	ret    
f010565d:	66 90                	xchg   %ax,%ax
f010565f:	90                   	nop

f0105660 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0105660:	55                   	push   %ebp
f0105661:	89 e5                	mov    %esp,%ebp
f0105663:	57                   	push   %edi
f0105664:	56                   	push   %esi
f0105665:	53                   	push   %ebx
f0105666:	83 ec 3c             	sub    $0x3c,%esp
f0105669:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010566c:	89 d7                	mov    %edx,%edi
f010566e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105671:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105674:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105677:	89 c3                	mov    %eax,%ebx
f0105679:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010567c:	8b 45 10             	mov    0x10(%ebp),%eax
f010567f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0105682:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105687:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010568a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010568d:	39 d9                	cmp    %ebx,%ecx
f010568f:	72 05                	jb     f0105696 <printnum+0x36>
f0105691:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0105694:	77 69                	ja     f01056ff <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0105696:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0105699:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010569d:	83 ee 01             	sub    $0x1,%esi
f01056a0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01056a4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01056a8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01056ac:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01056b0:	89 c3                	mov    %eax,%ebx
f01056b2:	89 d6                	mov    %edx,%esi
f01056b4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01056b7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01056ba:	89 54 24 08          	mov    %edx,0x8(%esp)
f01056be:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01056c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01056c5:	89 04 24             	mov    %eax,(%esp)
f01056c8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01056cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01056cf:	e8 4c 12 00 00       	call   f0106920 <__udivdi3>
f01056d4:	89 d9                	mov    %ebx,%ecx
f01056d6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01056da:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01056de:	89 04 24             	mov    %eax,(%esp)
f01056e1:	89 54 24 04          	mov    %edx,0x4(%esp)
f01056e5:	89 fa                	mov    %edi,%edx
f01056e7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01056ea:	e8 71 ff ff ff       	call   f0105660 <printnum>
f01056ef:	eb 1b                	jmp    f010570c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01056f1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01056f5:	8b 45 18             	mov    0x18(%ebp),%eax
f01056f8:	89 04 24             	mov    %eax,(%esp)
f01056fb:	ff d3                	call   *%ebx
f01056fd:	eb 03                	jmp    f0105702 <printnum+0xa2>
f01056ff:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while (--width > 0)
f0105702:	83 ee 01             	sub    $0x1,%esi
f0105705:	85 f6                	test   %esi,%esi
f0105707:	7f e8                	jg     f01056f1 <printnum+0x91>
f0105709:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010570c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105710:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105714:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105717:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010571a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010571e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0105722:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105725:	89 04 24             	mov    %eax,(%esp)
f0105728:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010572b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010572f:	e8 1c 13 00 00       	call   f0106a50 <__umoddi3>
f0105734:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105738:	0f be 80 fe 82 10 f0 	movsbl -0xfef7d02(%eax),%eax
f010573f:	89 04 24             	mov    %eax,(%esp)
f0105742:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105745:	ff d0                	call   *%eax
}
f0105747:	83 c4 3c             	add    $0x3c,%esp
f010574a:	5b                   	pop    %ebx
f010574b:	5e                   	pop    %esi
f010574c:	5f                   	pop    %edi
f010574d:	5d                   	pop    %ebp
f010574e:	c3                   	ret    

f010574f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010574f:	55                   	push   %ebp
f0105750:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0105752:	83 fa 01             	cmp    $0x1,%edx
f0105755:	7e 0e                	jle    f0105765 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0105757:	8b 10                	mov    (%eax),%edx
f0105759:	8d 4a 08             	lea    0x8(%edx),%ecx
f010575c:	89 08                	mov    %ecx,(%eax)
f010575e:	8b 02                	mov    (%edx),%eax
f0105760:	8b 52 04             	mov    0x4(%edx),%edx
f0105763:	eb 22                	jmp    f0105787 <getuint+0x38>
	else if (lflag)
f0105765:	85 d2                	test   %edx,%edx
f0105767:	74 10                	je     f0105779 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0105769:	8b 10                	mov    (%eax),%edx
f010576b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010576e:	89 08                	mov    %ecx,(%eax)
f0105770:	8b 02                	mov    (%edx),%eax
f0105772:	ba 00 00 00 00       	mov    $0x0,%edx
f0105777:	eb 0e                	jmp    f0105787 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0105779:	8b 10                	mov    (%eax),%edx
f010577b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010577e:	89 08                	mov    %ecx,(%eax)
f0105780:	8b 02                	mov    (%edx),%eax
f0105782:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0105787:	5d                   	pop    %ebp
f0105788:	c3                   	ret    

f0105789 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0105789:	55                   	push   %ebp
f010578a:	89 e5                	mov    %esp,%ebp
f010578c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010578f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0105793:	8b 10                	mov    (%eax),%edx
f0105795:	3b 50 04             	cmp    0x4(%eax),%edx
f0105798:	73 0a                	jae    f01057a4 <sprintputch+0x1b>
		*b->buf++ = ch;
f010579a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010579d:	89 08                	mov    %ecx,(%eax)
f010579f:	8b 45 08             	mov    0x8(%ebp),%eax
f01057a2:	88 02                	mov    %al,(%edx)
}
f01057a4:	5d                   	pop    %ebp
f01057a5:	c3                   	ret    

f01057a6 <printfmt>:
{
f01057a6:	55                   	push   %ebp
f01057a7:	89 e5                	mov    %esp,%ebp
f01057a9:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
f01057ac:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01057af:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01057b3:	8b 45 10             	mov    0x10(%ebp),%eax
f01057b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01057ba:	8b 45 0c             	mov    0xc(%ebp),%eax
f01057bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01057c1:	8b 45 08             	mov    0x8(%ebp),%eax
f01057c4:	89 04 24             	mov    %eax,(%esp)
f01057c7:	e8 02 00 00 00       	call   f01057ce <vprintfmt>
}
f01057cc:	c9                   	leave  
f01057cd:	c3                   	ret    

f01057ce <vprintfmt>:
{
f01057ce:	55                   	push   %ebp
f01057cf:	89 e5                	mov    %esp,%ebp
f01057d1:	57                   	push   %edi
f01057d2:	56                   	push   %esi
f01057d3:	53                   	push   %ebx
f01057d4:	83 ec 3c             	sub    $0x3c,%esp
f01057d7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01057da:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01057dd:	eb 14                	jmp    f01057f3 <vprintfmt+0x25>
			if (ch == '\0')
f01057df:	85 c0                	test   %eax,%eax
f01057e1:	0f 84 b3 03 00 00    	je     f0105b9a <vprintfmt+0x3cc>
			putch(ch, putdat);
f01057e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01057eb:	89 04 24             	mov    %eax,(%esp)
f01057ee:	ff 55 08             	call   *0x8(%ebp)
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01057f1:	89 f3                	mov    %esi,%ebx
f01057f3:	8d 73 01             	lea    0x1(%ebx),%esi
f01057f6:	0f b6 03             	movzbl (%ebx),%eax
f01057f9:	83 f8 25             	cmp    $0x25,%eax
f01057fc:	75 e1                	jne    f01057df <vprintfmt+0x11>
f01057fe:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0105802:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0105809:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0105810:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0105817:	ba 00 00 00 00       	mov    $0x0,%edx
f010581c:	eb 1d                	jmp    f010583b <vprintfmt+0x6d>
		switch (ch = *(unsigned char *) fmt++) {
f010581e:	89 de                	mov    %ebx,%esi
			padc = '-';
f0105820:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0105824:	eb 15                	jmp    f010583b <vprintfmt+0x6d>
		switch (ch = *(unsigned char *) fmt++) {
f0105826:	89 de                	mov    %ebx,%esi
			padc = '0';
f0105828:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010582c:	eb 0d                	jmp    f010583b <vprintfmt+0x6d>
				width = precision, precision = -1;
f010582e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105831:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105834:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010583b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010583e:	0f b6 0e             	movzbl (%esi),%ecx
f0105841:	0f b6 c1             	movzbl %cl,%eax
f0105844:	83 e9 23             	sub    $0x23,%ecx
f0105847:	80 f9 55             	cmp    $0x55,%cl
f010584a:	0f 87 2a 03 00 00    	ja     f0105b7a <vprintfmt+0x3ac>
f0105850:	0f b6 c9             	movzbl %cl,%ecx
f0105853:	ff 24 8d c0 83 10 f0 	jmp    *-0xfef7c40(,%ecx,4)
f010585a:	89 de                	mov    %ebx,%esi
f010585c:	b9 00 00 00 00       	mov    $0x0,%ecx
				precision = precision * 10 + ch - '0';
f0105861:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0105864:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0105868:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010586b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010586e:	83 fb 09             	cmp    $0x9,%ebx
f0105871:	77 36                	ja     f01058a9 <vprintfmt+0xdb>
			for (precision = 0; ; ++fmt) {
f0105873:	83 c6 01             	add    $0x1,%esi
			}
f0105876:	eb e9                	jmp    f0105861 <vprintfmt+0x93>
			precision = va_arg(ap, int);
f0105878:	8b 45 14             	mov    0x14(%ebp),%eax
f010587b:	8d 48 04             	lea    0x4(%eax),%ecx
f010587e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0105881:	8b 00                	mov    (%eax),%eax
f0105883:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0105886:	89 de                	mov    %ebx,%esi
			goto process_precision;
f0105888:	eb 22                	jmp    f01058ac <vprintfmt+0xde>
f010588a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010588d:	85 c9                	test   %ecx,%ecx
f010588f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105894:	0f 49 c1             	cmovns %ecx,%eax
f0105897:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010589a:	89 de                	mov    %ebx,%esi
f010589c:	eb 9d                	jmp    f010583b <vprintfmt+0x6d>
f010589e:	89 de                	mov    %ebx,%esi
			altflag = 1;
f01058a0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f01058a7:	eb 92                	jmp    f010583b <vprintfmt+0x6d>
f01058a9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
			if (width < 0)
f01058ac:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01058b0:	79 89                	jns    f010583b <vprintfmt+0x6d>
f01058b2:	e9 77 ff ff ff       	jmp    f010582e <vprintfmt+0x60>
			lflag++;
f01058b7:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f01058ba:	89 de                	mov    %ebx,%esi
			goto reswitch;
f01058bc:	e9 7a ff ff ff       	jmp    f010583b <vprintfmt+0x6d>
			putch(va_arg(ap, int), putdat);
f01058c1:	8b 45 14             	mov    0x14(%ebp),%eax
f01058c4:	8d 50 04             	lea    0x4(%eax),%edx
f01058c7:	89 55 14             	mov    %edx,0x14(%ebp)
f01058ca:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01058ce:	8b 00                	mov    (%eax),%eax
f01058d0:	89 04 24             	mov    %eax,(%esp)
f01058d3:	ff 55 08             	call   *0x8(%ebp)
			break;
f01058d6:	e9 18 ff ff ff       	jmp    f01057f3 <vprintfmt+0x25>
			err = va_arg(ap, int);
f01058db:	8b 45 14             	mov    0x14(%ebp),%eax
f01058de:	8d 50 04             	lea    0x4(%eax),%edx
f01058e1:	89 55 14             	mov    %edx,0x14(%ebp)
f01058e4:	8b 00                	mov    (%eax),%eax
f01058e6:	99                   	cltd   
f01058e7:	31 d0                	xor    %edx,%eax
f01058e9:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01058eb:	83 f8 08             	cmp    $0x8,%eax
f01058ee:	7f 0b                	jg     f01058fb <vprintfmt+0x12d>
f01058f0:	8b 14 85 20 85 10 f0 	mov    -0xfef7ae0(,%eax,4),%edx
f01058f7:	85 d2                	test   %edx,%edx
f01058f9:	75 20                	jne    f010591b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f01058fb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01058ff:	c7 44 24 08 16 83 10 	movl   $0xf0108316,0x8(%esp)
f0105906:	f0 
f0105907:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010590b:	8b 45 08             	mov    0x8(%ebp),%eax
f010590e:	89 04 24             	mov    %eax,(%esp)
f0105911:	e8 90 fe ff ff       	call   f01057a6 <printfmt>
f0105916:	e9 d8 fe ff ff       	jmp    f01057f3 <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
f010591b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010591f:	c7 44 24 08 dd 7a 10 	movl   $0xf0107add,0x8(%esp)
f0105926:	f0 
f0105927:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010592b:	8b 45 08             	mov    0x8(%ebp),%eax
f010592e:	89 04 24             	mov    %eax,(%esp)
f0105931:	e8 70 fe ff ff       	call   f01057a6 <printfmt>
f0105936:	e9 b8 fe ff ff       	jmp    f01057f3 <vprintfmt+0x25>
		switch (ch = *(unsigned char *) fmt++) {
f010593b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010593e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105941:	89 45 d0             	mov    %eax,-0x30(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f0105944:	8b 45 14             	mov    0x14(%ebp),%eax
f0105947:	8d 50 04             	lea    0x4(%eax),%edx
f010594a:	89 55 14             	mov    %edx,0x14(%ebp)
f010594d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010594f:	85 f6                	test   %esi,%esi
f0105951:	b8 0f 83 10 f0       	mov    $0xf010830f,%eax
f0105956:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0105959:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010595d:	0f 84 97 00 00 00    	je     f01059fa <vprintfmt+0x22c>
f0105963:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0105967:	0f 8e 9b 00 00 00    	jle    f0105a08 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010596d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105971:	89 34 24             	mov    %esi,(%esp)
f0105974:	e8 9f 03 00 00       	call   f0105d18 <strnlen>
f0105979:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010597c:	29 c2                	sub    %eax,%edx
f010597e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0105981:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0105985:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105988:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010598b:	8b 75 08             	mov    0x8(%ebp),%esi
f010598e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105991:	89 d3                	mov    %edx,%ebx
				for (width -= strnlen(p, precision); width > 0; width--)
f0105993:	eb 0f                	jmp    f01059a4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0105995:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105999:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010599c:	89 04 24             	mov    %eax,(%esp)
f010599f:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f01059a1:	83 eb 01             	sub    $0x1,%ebx
f01059a4:	85 db                	test   %ebx,%ebx
f01059a6:	7f ed                	jg     f0105995 <vprintfmt+0x1c7>
f01059a8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01059ab:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01059ae:	85 d2                	test   %edx,%edx
f01059b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01059b5:	0f 49 c2             	cmovns %edx,%eax
f01059b8:	29 c2                	sub    %eax,%edx
f01059ba:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01059bd:	89 d7                	mov    %edx,%edi
f01059bf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01059c2:	eb 50                	jmp    f0105a14 <vprintfmt+0x246>
				if (altflag && (ch < ' ' || ch > '~'))
f01059c4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01059c8:	74 1e                	je     f01059e8 <vprintfmt+0x21a>
f01059ca:	0f be d2             	movsbl %dl,%edx
f01059cd:	83 ea 20             	sub    $0x20,%edx
f01059d0:	83 fa 5e             	cmp    $0x5e,%edx
f01059d3:	76 13                	jbe    f01059e8 <vprintfmt+0x21a>
					putch('?', putdat);
f01059d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01059d8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01059dc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01059e3:	ff 55 08             	call   *0x8(%ebp)
f01059e6:	eb 0d                	jmp    f01059f5 <vprintfmt+0x227>
					putch(ch, putdat);
f01059e8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01059eb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01059ef:	89 04 24             	mov    %eax,(%esp)
f01059f2:	ff 55 08             	call   *0x8(%ebp)
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01059f5:	83 ef 01             	sub    $0x1,%edi
f01059f8:	eb 1a                	jmp    f0105a14 <vprintfmt+0x246>
f01059fa:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01059fd:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0105a00:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105a03:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105a06:	eb 0c                	jmp    f0105a14 <vprintfmt+0x246>
f0105a08:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0105a0b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0105a0e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105a11:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105a14:	83 c6 01             	add    $0x1,%esi
f0105a17:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0105a1b:	0f be c2             	movsbl %dl,%eax
f0105a1e:	85 c0                	test   %eax,%eax
f0105a20:	74 27                	je     f0105a49 <vprintfmt+0x27b>
f0105a22:	85 db                	test   %ebx,%ebx
f0105a24:	78 9e                	js     f01059c4 <vprintfmt+0x1f6>
f0105a26:	83 eb 01             	sub    $0x1,%ebx
f0105a29:	79 99                	jns    f01059c4 <vprintfmt+0x1f6>
f0105a2b:	89 f8                	mov    %edi,%eax
f0105a2d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105a30:	8b 75 08             	mov    0x8(%ebp),%esi
f0105a33:	89 c3                	mov    %eax,%ebx
f0105a35:	eb 1a                	jmp    f0105a51 <vprintfmt+0x283>
				putch(' ', putdat);
f0105a37:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105a3b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0105a42:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0105a44:	83 eb 01             	sub    $0x1,%ebx
f0105a47:	eb 08                	jmp    f0105a51 <vprintfmt+0x283>
f0105a49:	89 fb                	mov    %edi,%ebx
f0105a4b:	8b 75 08             	mov    0x8(%ebp),%esi
f0105a4e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105a51:	85 db                	test   %ebx,%ebx
f0105a53:	7f e2                	jg     f0105a37 <vprintfmt+0x269>
f0105a55:	89 75 08             	mov    %esi,0x8(%ebp)
f0105a58:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0105a5b:	e9 93 fd ff ff       	jmp    f01057f3 <vprintfmt+0x25>
	if (lflag >= 2)
f0105a60:	83 fa 01             	cmp    $0x1,%edx
f0105a63:	7e 16                	jle    f0105a7b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0105a65:	8b 45 14             	mov    0x14(%ebp),%eax
f0105a68:	8d 50 08             	lea    0x8(%eax),%edx
f0105a6b:	89 55 14             	mov    %edx,0x14(%ebp)
f0105a6e:	8b 50 04             	mov    0x4(%eax),%edx
f0105a71:	8b 00                	mov    (%eax),%eax
f0105a73:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105a76:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0105a79:	eb 32                	jmp    f0105aad <vprintfmt+0x2df>
	else if (lflag)
f0105a7b:	85 d2                	test   %edx,%edx
f0105a7d:	74 18                	je     f0105a97 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f0105a7f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105a82:	8d 50 04             	lea    0x4(%eax),%edx
f0105a85:	89 55 14             	mov    %edx,0x14(%ebp)
f0105a88:	8b 30                	mov    (%eax),%esi
f0105a8a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0105a8d:	89 f0                	mov    %esi,%eax
f0105a8f:	c1 f8 1f             	sar    $0x1f,%eax
f0105a92:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105a95:	eb 16                	jmp    f0105aad <vprintfmt+0x2df>
		return va_arg(*ap, int);
f0105a97:	8b 45 14             	mov    0x14(%ebp),%eax
f0105a9a:	8d 50 04             	lea    0x4(%eax),%edx
f0105a9d:	89 55 14             	mov    %edx,0x14(%ebp)
f0105aa0:	8b 30                	mov    (%eax),%esi
f0105aa2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0105aa5:	89 f0                	mov    %esi,%eax
f0105aa7:	c1 f8 1f             	sar    $0x1f,%eax
f0105aaa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			num = getint(&ap, lflag);
f0105aad:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105ab0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			base = 10;
f0105ab3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f0105ab8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0105abc:	0f 89 80 00 00 00    	jns    f0105b42 <vprintfmt+0x374>
				putch('-', putdat);
f0105ac2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105ac6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0105acd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0105ad0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105ad3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0105ad6:	f7 d8                	neg    %eax
f0105ad8:	83 d2 00             	adc    $0x0,%edx
f0105adb:	f7 da                	neg    %edx
			base = 10;
f0105add:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0105ae2:	eb 5e                	jmp    f0105b42 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f0105ae4:	8d 45 14             	lea    0x14(%ebp),%eax
f0105ae7:	e8 63 fc ff ff       	call   f010574f <getuint>
			base = 10;
f0105aec:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0105af1:	eb 4f                	jmp    f0105b42 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f0105af3:	8d 45 14             	lea    0x14(%ebp),%eax
f0105af6:	e8 54 fc ff ff       	call   f010574f <getuint>
			base = 8;
f0105afb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0105b00:	eb 40                	jmp    f0105b42 <vprintfmt+0x374>
			putch('0', putdat);
f0105b02:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105b06:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0105b0d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0105b10:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105b14:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0105b1b:	ff 55 08             	call   *0x8(%ebp)
				(uintptr_t) va_arg(ap, void *);
f0105b1e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105b21:	8d 50 04             	lea    0x4(%eax),%edx
f0105b24:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f0105b27:	8b 00                	mov    (%eax),%eax
f0105b29:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
f0105b2e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0105b33:	eb 0d                	jmp    f0105b42 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f0105b35:	8d 45 14             	lea    0x14(%ebp),%eax
f0105b38:	e8 12 fc ff ff       	call   f010574f <getuint>
			base = 16;
f0105b3d:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
f0105b42:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0105b46:	89 74 24 10          	mov    %esi,0x10(%esp)
f0105b4a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0105b4d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105b51:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105b55:	89 04 24             	mov    %eax,(%esp)
f0105b58:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105b5c:	89 fa                	mov    %edi,%edx
f0105b5e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b61:	e8 fa fa ff ff       	call   f0105660 <printnum>
			break;
f0105b66:	e9 88 fc ff ff       	jmp    f01057f3 <vprintfmt+0x25>
			putch(ch, putdat);
f0105b6b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105b6f:	89 04 24             	mov    %eax,(%esp)
f0105b72:	ff 55 08             	call   *0x8(%ebp)
			break;
f0105b75:	e9 79 fc ff ff       	jmp    f01057f3 <vprintfmt+0x25>
			putch('%', putdat);
f0105b7a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105b7e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0105b85:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105b88:	89 f3                	mov    %esi,%ebx
f0105b8a:	eb 03                	jmp    f0105b8f <vprintfmt+0x3c1>
f0105b8c:	83 eb 01             	sub    $0x1,%ebx
f0105b8f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0105b93:	75 f7                	jne    f0105b8c <vprintfmt+0x3be>
f0105b95:	e9 59 fc ff ff       	jmp    f01057f3 <vprintfmt+0x25>
}
f0105b9a:	83 c4 3c             	add    $0x3c,%esp
f0105b9d:	5b                   	pop    %ebx
f0105b9e:	5e                   	pop    %esi
f0105b9f:	5f                   	pop    %edi
f0105ba0:	5d                   	pop    %ebp
f0105ba1:	c3                   	ret    

f0105ba2 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105ba2:	55                   	push   %ebp
f0105ba3:	89 e5                	mov    %esp,%ebp
f0105ba5:	83 ec 28             	sub    $0x28,%esp
f0105ba8:	8b 45 08             	mov    0x8(%ebp),%eax
f0105bab:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105bae:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105bb1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105bb5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105bb8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105bbf:	85 c0                	test   %eax,%eax
f0105bc1:	74 30                	je     f0105bf3 <vsnprintf+0x51>
f0105bc3:	85 d2                	test   %edx,%edx
f0105bc5:	7e 2c                	jle    f0105bf3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105bc7:	8b 45 14             	mov    0x14(%ebp),%eax
f0105bca:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105bce:	8b 45 10             	mov    0x10(%ebp),%eax
f0105bd1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105bd5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105bd8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105bdc:	c7 04 24 89 57 10 f0 	movl   $0xf0105789,(%esp)
f0105be3:	e8 e6 fb ff ff       	call   f01057ce <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105be8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105beb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105bee:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105bf1:	eb 05                	jmp    f0105bf8 <vsnprintf+0x56>
		return -E_INVAL;
f0105bf3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f0105bf8:	c9                   	leave  
f0105bf9:	c3                   	ret    

f0105bfa <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105bfa:	55                   	push   %ebp
f0105bfb:	89 e5                	mov    %esp,%ebp
f0105bfd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105c00:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105c03:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105c07:	8b 45 10             	mov    0x10(%ebp),%eax
f0105c0a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105c0e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105c11:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105c15:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c18:	89 04 24             	mov    %eax,(%esp)
f0105c1b:	e8 82 ff ff ff       	call   f0105ba2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0105c20:	c9                   	leave  
f0105c21:	c3                   	ret    
f0105c22:	66 90                	xchg   %ax,%ax
f0105c24:	66 90                	xchg   %ax,%ax
f0105c26:	66 90                	xchg   %ax,%ax
f0105c28:	66 90                	xchg   %ax,%ax
f0105c2a:	66 90                	xchg   %ax,%ax
f0105c2c:	66 90                	xchg   %ax,%ax
f0105c2e:	66 90                	xchg   %ax,%ax

f0105c30 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105c30:	55                   	push   %ebp
f0105c31:	89 e5                	mov    %esp,%ebp
f0105c33:	57                   	push   %edi
f0105c34:	56                   	push   %esi
f0105c35:	53                   	push   %ebx
f0105c36:	83 ec 1c             	sub    $0x1c,%esp
f0105c39:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0105c3c:	85 c0                	test   %eax,%eax
f0105c3e:	74 10                	je     f0105c50 <readline+0x20>
		cprintf("%s", prompt);
f0105c40:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105c44:	c7 04 24 dd 7a 10 f0 	movl   $0xf0107add,(%esp)
f0105c4b:	e8 13 e3 ff ff       	call   f0103f63 <cprintf>

	i = 0;
	echoing = iscons(0);
f0105c50:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0105c57:	e8 5f ab ff ff       	call   f01007bb <iscons>
f0105c5c:	89 c7                	mov    %eax,%edi
	i = 0;
f0105c5e:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f0105c63:	e8 42 ab ff ff       	call   f01007aa <getchar>
f0105c68:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0105c6a:	85 c0                	test   %eax,%eax
f0105c6c:	79 17                	jns    f0105c85 <readline+0x55>
			cprintf("read error: %e\n", c);
f0105c6e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105c72:	c7 04 24 44 85 10 f0 	movl   $0xf0108544,(%esp)
f0105c79:	e8 e5 e2 ff ff       	call   f0103f63 <cprintf>
			return NULL;
f0105c7e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105c83:	eb 6d                	jmp    f0105cf2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105c85:	83 f8 7f             	cmp    $0x7f,%eax
f0105c88:	74 05                	je     f0105c8f <readline+0x5f>
f0105c8a:	83 f8 08             	cmp    $0x8,%eax
f0105c8d:	75 19                	jne    f0105ca8 <readline+0x78>
f0105c8f:	85 f6                	test   %esi,%esi
f0105c91:	7e 15                	jle    f0105ca8 <readline+0x78>
			if (echoing)
f0105c93:	85 ff                	test   %edi,%edi
f0105c95:	74 0c                	je     f0105ca3 <readline+0x73>
				cputchar('\b');
f0105c97:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0105c9e:	e8 f7 aa ff ff       	call   f010079a <cputchar>
			i--;
f0105ca3:	83 ee 01             	sub    $0x1,%esi
f0105ca6:	eb bb                	jmp    f0105c63 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105ca8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0105cae:	7f 1c                	jg     f0105ccc <readline+0x9c>
f0105cb0:	83 fb 1f             	cmp    $0x1f,%ebx
f0105cb3:	7e 17                	jle    f0105ccc <readline+0x9c>
			if (echoing)
f0105cb5:	85 ff                	test   %edi,%edi
f0105cb7:	74 08                	je     f0105cc1 <readline+0x91>
				cputchar(c);
f0105cb9:	89 1c 24             	mov    %ebx,(%esp)
f0105cbc:	e8 d9 aa ff ff       	call   f010079a <cputchar>
			buf[i++] = c;
f0105cc1:	88 9e 80 0a 23 f0    	mov    %bl,-0xfdcf580(%esi)
f0105cc7:	8d 76 01             	lea    0x1(%esi),%esi
f0105cca:	eb 97                	jmp    f0105c63 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0105ccc:	83 fb 0d             	cmp    $0xd,%ebx
f0105ccf:	74 05                	je     f0105cd6 <readline+0xa6>
f0105cd1:	83 fb 0a             	cmp    $0xa,%ebx
f0105cd4:	75 8d                	jne    f0105c63 <readline+0x33>
			if (echoing)
f0105cd6:	85 ff                	test   %edi,%edi
f0105cd8:	74 0c                	je     f0105ce6 <readline+0xb6>
				cputchar('\n');
f0105cda:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0105ce1:	e8 b4 aa ff ff       	call   f010079a <cputchar>
			buf[i] = 0;
f0105ce6:	c6 86 80 0a 23 f0 00 	movb   $0x0,-0xfdcf580(%esi)
			return buf;
f0105ced:	b8 80 0a 23 f0       	mov    $0xf0230a80,%eax
		}
	}
}
f0105cf2:	83 c4 1c             	add    $0x1c,%esp
f0105cf5:	5b                   	pop    %ebx
f0105cf6:	5e                   	pop    %esi
f0105cf7:	5f                   	pop    %edi
f0105cf8:	5d                   	pop    %ebp
f0105cf9:	c3                   	ret    
f0105cfa:	66 90                	xchg   %ax,%ax
f0105cfc:	66 90                	xchg   %ax,%ax
f0105cfe:	66 90                	xchg   %ax,%ax

f0105d00 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105d00:	55                   	push   %ebp
f0105d01:	89 e5                	mov    %esp,%ebp
f0105d03:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105d06:	b8 00 00 00 00       	mov    $0x0,%eax
f0105d0b:	eb 03                	jmp    f0105d10 <strlen+0x10>
		n++;
f0105d0d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0105d10:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105d14:	75 f7                	jne    f0105d0d <strlen+0xd>
	return n;
}
f0105d16:	5d                   	pop    %ebp
f0105d17:	c3                   	ret    

f0105d18 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105d18:	55                   	push   %ebp
f0105d19:	89 e5                	mov    %esp,%ebp
f0105d1b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105d1e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105d21:	b8 00 00 00 00       	mov    $0x0,%eax
f0105d26:	eb 03                	jmp    f0105d2b <strnlen+0x13>
		n++;
f0105d28:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105d2b:	39 d0                	cmp    %edx,%eax
f0105d2d:	74 06                	je     f0105d35 <strnlen+0x1d>
f0105d2f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0105d33:	75 f3                	jne    f0105d28 <strnlen+0x10>
	return n;
}
f0105d35:	5d                   	pop    %ebp
f0105d36:	c3                   	ret    

f0105d37 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105d37:	55                   	push   %ebp
f0105d38:	89 e5                	mov    %esp,%ebp
f0105d3a:	53                   	push   %ebx
f0105d3b:	8b 45 08             	mov    0x8(%ebp),%eax
f0105d3e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105d41:	89 c2                	mov    %eax,%edx
f0105d43:	83 c2 01             	add    $0x1,%edx
f0105d46:	83 c1 01             	add    $0x1,%ecx
f0105d49:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0105d4d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105d50:	84 db                	test   %bl,%bl
f0105d52:	75 ef                	jne    f0105d43 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105d54:	5b                   	pop    %ebx
f0105d55:	5d                   	pop    %ebp
f0105d56:	c3                   	ret    

f0105d57 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105d57:	55                   	push   %ebp
f0105d58:	89 e5                	mov    %esp,%ebp
f0105d5a:	53                   	push   %ebx
f0105d5b:	83 ec 08             	sub    $0x8,%esp
f0105d5e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105d61:	89 1c 24             	mov    %ebx,(%esp)
f0105d64:	e8 97 ff ff ff       	call   f0105d00 <strlen>
	strcpy(dst + len, src);
f0105d69:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105d6c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105d70:	01 d8                	add    %ebx,%eax
f0105d72:	89 04 24             	mov    %eax,(%esp)
f0105d75:	e8 bd ff ff ff       	call   f0105d37 <strcpy>
	return dst;
}
f0105d7a:	89 d8                	mov    %ebx,%eax
f0105d7c:	83 c4 08             	add    $0x8,%esp
f0105d7f:	5b                   	pop    %ebx
f0105d80:	5d                   	pop    %ebp
f0105d81:	c3                   	ret    

f0105d82 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105d82:	55                   	push   %ebp
f0105d83:	89 e5                	mov    %esp,%ebp
f0105d85:	56                   	push   %esi
f0105d86:	53                   	push   %ebx
f0105d87:	8b 75 08             	mov    0x8(%ebp),%esi
f0105d8a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105d8d:	89 f3                	mov    %esi,%ebx
f0105d8f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105d92:	89 f2                	mov    %esi,%edx
f0105d94:	eb 0f                	jmp    f0105da5 <strncpy+0x23>
		*dst++ = *src;
f0105d96:	83 c2 01             	add    $0x1,%edx
f0105d99:	0f b6 01             	movzbl (%ecx),%eax
f0105d9c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105d9f:	80 39 01             	cmpb   $0x1,(%ecx)
f0105da2:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0105da5:	39 da                	cmp    %ebx,%edx
f0105da7:	75 ed                	jne    f0105d96 <strncpy+0x14>
	}
	return ret;
}
f0105da9:	89 f0                	mov    %esi,%eax
f0105dab:	5b                   	pop    %ebx
f0105dac:	5e                   	pop    %esi
f0105dad:	5d                   	pop    %ebp
f0105dae:	c3                   	ret    

f0105daf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105daf:	55                   	push   %ebp
f0105db0:	89 e5                	mov    %esp,%ebp
f0105db2:	56                   	push   %esi
f0105db3:	53                   	push   %ebx
f0105db4:	8b 75 08             	mov    0x8(%ebp),%esi
f0105db7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105dba:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0105dbd:	89 f0                	mov    %esi,%eax
f0105dbf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105dc3:	85 c9                	test   %ecx,%ecx
f0105dc5:	75 0b                	jne    f0105dd2 <strlcpy+0x23>
f0105dc7:	eb 1d                	jmp    f0105de6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0105dc9:	83 c0 01             	add    $0x1,%eax
f0105dcc:	83 c2 01             	add    $0x1,%edx
f0105dcf:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0105dd2:	39 d8                	cmp    %ebx,%eax
f0105dd4:	74 0b                	je     f0105de1 <strlcpy+0x32>
f0105dd6:	0f b6 0a             	movzbl (%edx),%ecx
f0105dd9:	84 c9                	test   %cl,%cl
f0105ddb:	75 ec                	jne    f0105dc9 <strlcpy+0x1a>
f0105ddd:	89 c2                	mov    %eax,%edx
f0105ddf:	eb 02                	jmp    f0105de3 <strlcpy+0x34>
f0105de1:	89 c2                	mov    %eax,%edx
		*dst = '\0';
f0105de3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0105de6:	29 f0                	sub    %esi,%eax
}
f0105de8:	5b                   	pop    %ebx
f0105de9:	5e                   	pop    %esi
f0105dea:	5d                   	pop    %ebp
f0105deb:	c3                   	ret    

f0105dec <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105dec:	55                   	push   %ebp
f0105ded:	89 e5                	mov    %esp,%ebp
f0105def:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105df2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105df5:	eb 06                	jmp    f0105dfd <strcmp+0x11>
		p++, q++;
f0105df7:	83 c1 01             	add    $0x1,%ecx
f0105dfa:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0105dfd:	0f b6 01             	movzbl (%ecx),%eax
f0105e00:	84 c0                	test   %al,%al
f0105e02:	74 04                	je     f0105e08 <strcmp+0x1c>
f0105e04:	3a 02                	cmp    (%edx),%al
f0105e06:	74 ef                	je     f0105df7 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105e08:	0f b6 c0             	movzbl %al,%eax
f0105e0b:	0f b6 12             	movzbl (%edx),%edx
f0105e0e:	29 d0                	sub    %edx,%eax
}
f0105e10:	5d                   	pop    %ebp
f0105e11:	c3                   	ret    

f0105e12 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105e12:	55                   	push   %ebp
f0105e13:	89 e5                	mov    %esp,%ebp
f0105e15:	53                   	push   %ebx
f0105e16:	8b 45 08             	mov    0x8(%ebp),%eax
f0105e19:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105e1c:	89 c3                	mov    %eax,%ebx
f0105e1e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105e21:	eb 06                	jmp    f0105e29 <strncmp+0x17>
		n--, p++, q++;
f0105e23:	83 c0 01             	add    $0x1,%eax
f0105e26:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0105e29:	39 d8                	cmp    %ebx,%eax
f0105e2b:	74 15                	je     f0105e42 <strncmp+0x30>
f0105e2d:	0f b6 08             	movzbl (%eax),%ecx
f0105e30:	84 c9                	test   %cl,%cl
f0105e32:	74 04                	je     f0105e38 <strncmp+0x26>
f0105e34:	3a 0a                	cmp    (%edx),%cl
f0105e36:	74 eb                	je     f0105e23 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105e38:	0f b6 00             	movzbl (%eax),%eax
f0105e3b:	0f b6 12             	movzbl (%edx),%edx
f0105e3e:	29 d0                	sub    %edx,%eax
f0105e40:	eb 05                	jmp    f0105e47 <strncmp+0x35>
		return 0;
f0105e42:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105e47:	5b                   	pop    %ebx
f0105e48:	5d                   	pop    %ebp
f0105e49:	c3                   	ret    

f0105e4a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105e4a:	55                   	push   %ebp
f0105e4b:	89 e5                	mov    %esp,%ebp
f0105e4d:	8b 45 08             	mov    0x8(%ebp),%eax
f0105e50:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105e54:	eb 07                	jmp    f0105e5d <strchr+0x13>
		if (*s == c)
f0105e56:	38 ca                	cmp    %cl,%dl
f0105e58:	74 0f                	je     f0105e69 <strchr+0x1f>
	for (; *s; s++)
f0105e5a:	83 c0 01             	add    $0x1,%eax
f0105e5d:	0f b6 10             	movzbl (%eax),%edx
f0105e60:	84 d2                	test   %dl,%dl
f0105e62:	75 f2                	jne    f0105e56 <strchr+0xc>
			return (char *) s;
	return 0;
f0105e64:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105e69:	5d                   	pop    %ebp
f0105e6a:	c3                   	ret    

f0105e6b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105e6b:	55                   	push   %ebp
f0105e6c:	89 e5                	mov    %esp,%ebp
f0105e6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105e71:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105e75:	eb 07                	jmp    f0105e7e <strfind+0x13>
		if (*s == c)
f0105e77:	38 ca                	cmp    %cl,%dl
f0105e79:	74 0a                	je     f0105e85 <strfind+0x1a>
	for (; *s; s++)
f0105e7b:	83 c0 01             	add    $0x1,%eax
f0105e7e:	0f b6 10             	movzbl (%eax),%edx
f0105e81:	84 d2                	test   %dl,%dl
f0105e83:	75 f2                	jne    f0105e77 <strfind+0xc>
			break;
	return (char *) s;
}
f0105e85:	5d                   	pop    %ebp
f0105e86:	c3                   	ret    

f0105e87 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105e87:	55                   	push   %ebp
f0105e88:	89 e5                	mov    %esp,%ebp
f0105e8a:	57                   	push   %edi
f0105e8b:	56                   	push   %esi
f0105e8c:	53                   	push   %ebx
f0105e8d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105e90:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105e93:	85 c9                	test   %ecx,%ecx
f0105e95:	74 36                	je     f0105ecd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105e97:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0105e9d:	75 28                	jne    f0105ec7 <memset+0x40>
f0105e9f:	f6 c1 03             	test   $0x3,%cl
f0105ea2:	75 23                	jne    f0105ec7 <memset+0x40>
		c &= 0xFF;
f0105ea4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105ea8:	89 d3                	mov    %edx,%ebx
f0105eaa:	c1 e3 08             	shl    $0x8,%ebx
f0105ead:	89 d6                	mov    %edx,%esi
f0105eaf:	c1 e6 18             	shl    $0x18,%esi
f0105eb2:	89 d0                	mov    %edx,%eax
f0105eb4:	c1 e0 10             	shl    $0x10,%eax
f0105eb7:	09 f0                	or     %esi,%eax
f0105eb9:	09 c2                	or     %eax,%edx
f0105ebb:	89 d0                	mov    %edx,%eax
f0105ebd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0105ebf:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0105ec2:	fc                   	cld    
f0105ec3:	f3 ab                	rep stos %eax,%es:(%edi)
f0105ec5:	eb 06                	jmp    f0105ecd <memset+0x46>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105ec7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105eca:	fc                   	cld    
f0105ecb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105ecd:	89 f8                	mov    %edi,%eax
f0105ecf:	5b                   	pop    %ebx
f0105ed0:	5e                   	pop    %esi
f0105ed1:	5f                   	pop    %edi
f0105ed2:	5d                   	pop    %ebp
f0105ed3:	c3                   	ret    

f0105ed4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105ed4:	55                   	push   %ebp
f0105ed5:	89 e5                	mov    %esp,%ebp
f0105ed7:	57                   	push   %edi
f0105ed8:	56                   	push   %esi
f0105ed9:	8b 45 08             	mov    0x8(%ebp),%eax
f0105edc:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105edf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105ee2:	39 c6                	cmp    %eax,%esi
f0105ee4:	73 35                	jae    f0105f1b <memmove+0x47>
f0105ee6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105ee9:	39 d0                	cmp    %edx,%eax
f0105eeb:	73 2e                	jae    f0105f1b <memmove+0x47>
		s += n;
		d += n;
f0105eed:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0105ef0:	89 d6                	mov    %edx,%esi
f0105ef2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105ef4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105efa:	75 13                	jne    f0105f0f <memmove+0x3b>
f0105efc:	f6 c1 03             	test   $0x3,%cl
f0105eff:	75 0e                	jne    f0105f0f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105f01:	83 ef 04             	sub    $0x4,%edi
f0105f04:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105f07:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0105f0a:	fd                   	std    
f0105f0b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105f0d:	eb 09                	jmp    f0105f18 <memmove+0x44>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105f0f:	83 ef 01             	sub    $0x1,%edi
f0105f12:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0105f15:	fd                   	std    
f0105f16:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105f18:	fc                   	cld    
f0105f19:	eb 1d                	jmp    f0105f38 <memmove+0x64>
f0105f1b:	89 f2                	mov    %esi,%edx
f0105f1d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105f1f:	f6 c2 03             	test   $0x3,%dl
f0105f22:	75 0f                	jne    f0105f33 <memmove+0x5f>
f0105f24:	f6 c1 03             	test   $0x3,%cl
f0105f27:	75 0a                	jne    f0105f33 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105f29:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0105f2c:	89 c7                	mov    %eax,%edi
f0105f2e:	fc                   	cld    
f0105f2f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105f31:	eb 05                	jmp    f0105f38 <memmove+0x64>
		else
			asm volatile("cld; rep movsb\n"
f0105f33:	89 c7                	mov    %eax,%edi
f0105f35:	fc                   	cld    
f0105f36:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105f38:	5e                   	pop    %esi
f0105f39:	5f                   	pop    %edi
f0105f3a:	5d                   	pop    %ebp
f0105f3b:	c3                   	ret    

f0105f3c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105f3c:	55                   	push   %ebp
f0105f3d:	89 e5                	mov    %esp,%ebp
f0105f3f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105f42:	8b 45 10             	mov    0x10(%ebp),%eax
f0105f45:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105f49:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105f4c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105f50:	8b 45 08             	mov    0x8(%ebp),%eax
f0105f53:	89 04 24             	mov    %eax,(%esp)
f0105f56:	e8 79 ff ff ff       	call   f0105ed4 <memmove>
}
f0105f5b:	c9                   	leave  
f0105f5c:	c3                   	ret    

f0105f5d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105f5d:	55                   	push   %ebp
f0105f5e:	89 e5                	mov    %esp,%ebp
f0105f60:	56                   	push   %esi
f0105f61:	53                   	push   %ebx
f0105f62:	8b 55 08             	mov    0x8(%ebp),%edx
f0105f65:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105f68:	89 d6                	mov    %edx,%esi
f0105f6a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105f6d:	eb 1a                	jmp    f0105f89 <memcmp+0x2c>
		if (*s1 != *s2)
f0105f6f:	0f b6 02             	movzbl (%edx),%eax
f0105f72:	0f b6 19             	movzbl (%ecx),%ebx
f0105f75:	38 d8                	cmp    %bl,%al
f0105f77:	74 0a                	je     f0105f83 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105f79:	0f b6 c0             	movzbl %al,%eax
f0105f7c:	0f b6 db             	movzbl %bl,%ebx
f0105f7f:	29 d8                	sub    %ebx,%eax
f0105f81:	eb 0f                	jmp    f0105f92 <memcmp+0x35>
		s1++, s2++;
f0105f83:	83 c2 01             	add    $0x1,%edx
f0105f86:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
f0105f89:	39 f2                	cmp    %esi,%edx
f0105f8b:	75 e2                	jne    f0105f6f <memcmp+0x12>
	}

	return 0;
f0105f8d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105f92:	5b                   	pop    %ebx
f0105f93:	5e                   	pop    %esi
f0105f94:	5d                   	pop    %ebp
f0105f95:	c3                   	ret    

f0105f96 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105f96:	55                   	push   %ebp
f0105f97:	89 e5                	mov    %esp,%ebp
f0105f99:	8b 45 08             	mov    0x8(%ebp),%eax
f0105f9c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0105f9f:	89 c2                	mov    %eax,%edx
f0105fa1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105fa4:	eb 07                	jmp    f0105fad <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105fa6:	38 08                	cmp    %cl,(%eax)
f0105fa8:	74 07                	je     f0105fb1 <memfind+0x1b>
	for (; s < ends; s++)
f0105faa:	83 c0 01             	add    $0x1,%eax
f0105fad:	39 d0                	cmp    %edx,%eax
f0105faf:	72 f5                	jb     f0105fa6 <memfind+0x10>
			break;
	return (void *) s;
}
f0105fb1:	5d                   	pop    %ebp
f0105fb2:	c3                   	ret    

f0105fb3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105fb3:	55                   	push   %ebp
f0105fb4:	89 e5                	mov    %esp,%ebp
f0105fb6:	57                   	push   %edi
f0105fb7:	56                   	push   %esi
f0105fb8:	53                   	push   %ebx
f0105fb9:	8b 55 08             	mov    0x8(%ebp),%edx
f0105fbc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105fbf:	eb 03                	jmp    f0105fc4 <strtol+0x11>
		s++;
f0105fc1:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0105fc4:	0f b6 0a             	movzbl (%edx),%ecx
f0105fc7:	80 f9 09             	cmp    $0x9,%cl
f0105fca:	74 f5                	je     f0105fc1 <strtol+0xe>
f0105fcc:	80 f9 20             	cmp    $0x20,%cl
f0105fcf:	74 f0                	je     f0105fc1 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0105fd1:	80 f9 2b             	cmp    $0x2b,%cl
f0105fd4:	75 0a                	jne    f0105fe0 <strtol+0x2d>
		s++;
f0105fd6:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f0105fd9:	bf 00 00 00 00       	mov    $0x0,%edi
f0105fde:	eb 11                	jmp    f0105ff1 <strtol+0x3e>
f0105fe0:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
f0105fe5:	80 f9 2d             	cmp    $0x2d,%cl
f0105fe8:	75 07                	jne    f0105ff1 <strtol+0x3e>
		s++, neg = 1;
f0105fea:	8d 52 01             	lea    0x1(%edx),%edx
f0105fed:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105ff1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0105ff6:	75 15                	jne    f010600d <strtol+0x5a>
f0105ff8:	80 3a 30             	cmpb   $0x30,(%edx)
f0105ffb:	75 10                	jne    f010600d <strtol+0x5a>
f0105ffd:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0106001:	75 0a                	jne    f010600d <strtol+0x5a>
		s += 2, base = 16;
f0106003:	83 c2 02             	add    $0x2,%edx
f0106006:	b8 10 00 00 00       	mov    $0x10,%eax
f010600b:	eb 10                	jmp    f010601d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010600d:	85 c0                	test   %eax,%eax
f010600f:	75 0c                	jne    f010601d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0106011:	b0 0a                	mov    $0xa,%al
	else if (base == 0 && s[0] == '0')
f0106013:	80 3a 30             	cmpb   $0x30,(%edx)
f0106016:	75 05                	jne    f010601d <strtol+0x6a>
		s++, base = 8;
f0106018:	83 c2 01             	add    $0x1,%edx
f010601b:	b0 08                	mov    $0x8,%al
		base = 10;
f010601d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0106022:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0106025:	0f b6 0a             	movzbl (%edx),%ecx
f0106028:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010602b:	89 f0                	mov    %esi,%eax
f010602d:	3c 09                	cmp    $0x9,%al
f010602f:	77 08                	ja     f0106039 <strtol+0x86>
			dig = *s - '0';
f0106031:	0f be c9             	movsbl %cl,%ecx
f0106034:	83 e9 30             	sub    $0x30,%ecx
f0106037:	eb 20                	jmp    f0106059 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0106039:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010603c:	89 f0                	mov    %esi,%eax
f010603e:	3c 19                	cmp    $0x19,%al
f0106040:	77 08                	ja     f010604a <strtol+0x97>
			dig = *s - 'a' + 10;
f0106042:	0f be c9             	movsbl %cl,%ecx
f0106045:	83 e9 57             	sub    $0x57,%ecx
f0106048:	eb 0f                	jmp    f0106059 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010604a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010604d:	89 f0                	mov    %esi,%eax
f010604f:	3c 19                	cmp    $0x19,%al
f0106051:	77 16                	ja     f0106069 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0106053:	0f be c9             	movsbl %cl,%ecx
f0106056:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0106059:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010605c:	7d 0f                	jge    f010606d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010605e:	83 c2 01             	add    $0x1,%edx
f0106061:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0106065:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0106067:	eb bc                	jmp    f0106025 <strtol+0x72>
f0106069:	89 d8                	mov    %ebx,%eax
f010606b:	eb 02                	jmp    f010606f <strtol+0xbc>
f010606d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010606f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0106073:	74 05                	je     f010607a <strtol+0xc7>
		*endptr = (char *) s;
f0106075:	8b 75 0c             	mov    0xc(%ebp),%esi
f0106078:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010607a:	f7 d8                	neg    %eax
f010607c:	85 ff                	test   %edi,%edi
f010607e:	0f 44 c3             	cmove  %ebx,%eax
}
f0106081:	5b                   	pop    %ebx
f0106082:	5e                   	pop    %esi
f0106083:	5f                   	pop    %edi
f0106084:	5d                   	pop    %ebp
f0106085:	c3                   	ret    
f0106086:	66 90                	xchg   %ax,%ax

f0106088 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0106088:	fa                   	cli    

	xorw    %ax, %ax
f0106089:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010608b:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f010608d:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f010608f:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0106091:	0f 01 16             	lgdtl  (%esi)
f0106094:	74 70                	je     f0106106 <mpentry_end+0x4>
	movl    %cr0, %eax
f0106096:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0106099:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f010609d:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f01060a0:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f01060a6:	08 00                	or     %al,(%eax)

f01060a8 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f01060a8:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f01060ac:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01060ae:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01060b0:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01060b2:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f01060b6:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01060b8:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01060ba:	b8 00 f0 11 00       	mov    $0x11f000,%eax
	movl    %eax, %cr3
f01060bf:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f01060c2:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f01060c5:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f01060ca:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f01060cd:	8b 25 84 0e 23 f0    	mov    0xf0230e84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f01060d3:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f01060d8:	b8 e2 01 10 f0       	mov    $0xf01001e2,%eax
	call    *%eax
f01060dd:	ff d0                	call   *%eax

f01060df <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f01060df:	eb fe                	jmp    f01060df <spin>
f01060e1:	8d 76 00             	lea    0x0(%esi),%esi

f01060e4 <gdt>:
	...
f01060ec:	ff                   	(bad)  
f01060ed:	ff 00                	incl   (%eax)
f01060ef:	00 00                	add    %al,(%eax)
f01060f1:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f01060f8:	00                   	.byte 0x0
f01060f9:	92                   	xchg   %eax,%edx
f01060fa:	cf                   	iret   
	...

f01060fc <gdtdesc>:
f01060fc:	17                   	pop    %ss
f01060fd:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0106102 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0106102:	90                   	nop
f0106103:	66 90                	xchg   %ax,%ax
f0106105:	66 90                	xchg   %ax,%ax
f0106107:	66 90                	xchg   %ax,%ax
f0106109:	66 90                	xchg   %ax,%ax
f010610b:	66 90                	xchg   %ax,%ax
f010610d:	66 90                	xchg   %ax,%ax
f010610f:	90                   	nop

f0106110 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0106110:	55                   	push   %ebp
f0106111:	89 e5                	mov    %esp,%ebp
f0106113:	56                   	push   %esi
f0106114:	53                   	push   %ebx
f0106115:	83 ec 10             	sub    $0x10,%esp
	if (PGNUM(pa) >= npages)
f0106118:	8b 0d 88 0e 23 f0    	mov    0xf0230e88,%ecx
f010611e:	89 c3                	mov    %eax,%ebx
f0106120:	c1 eb 0c             	shr    $0xc,%ebx
f0106123:	39 cb                	cmp    %ecx,%ebx
f0106125:	72 20                	jb     f0106147 <mpsearch1+0x37>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106127:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010612b:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f0106132:	f0 
f0106133:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f010613a:	00 
f010613b:	c7 04 24 e1 86 10 f0 	movl   $0xf01086e1,(%esp)
f0106142:	e8 f9 9e ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0106147:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f010614d:	01 d0                	add    %edx,%eax
	if (PGNUM(pa) >= npages)
f010614f:	89 c2                	mov    %eax,%edx
f0106151:	c1 ea 0c             	shr    $0xc,%edx
f0106154:	39 d1                	cmp    %edx,%ecx
f0106156:	77 20                	ja     f0106178 <mpsearch1+0x68>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106158:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010615c:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f0106163:	f0 
f0106164:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f010616b:	00 
f010616c:	c7 04 24 e1 86 10 f0 	movl   $0xf01086e1,(%esp)
f0106173:	e8 c8 9e ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0106178:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f010617e:	eb 36                	jmp    f01061b6 <mpsearch1+0xa6>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0106180:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0106187:	00 
f0106188:	c7 44 24 04 f1 86 10 	movl   $0xf01086f1,0x4(%esp)
f010618f:	f0 
f0106190:	89 1c 24             	mov    %ebx,(%esp)
f0106193:	e8 c5 fd ff ff       	call   f0105f5d <memcmp>
f0106198:	85 c0                	test   %eax,%eax
f010619a:	75 17                	jne    f01061b3 <mpsearch1+0xa3>
	for (i = 0; i < len; i++)
f010619c:	ba 00 00 00 00       	mov    $0x0,%edx
		sum += ((uint8_t *)addr)[i];
f01061a1:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01061a5:	01 c8                	add    %ecx,%eax
	for (i = 0; i < len; i++)
f01061a7:	83 c2 01             	add    $0x1,%edx
f01061aa:	83 fa 10             	cmp    $0x10,%edx
f01061ad:	75 f2                	jne    f01061a1 <mpsearch1+0x91>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01061af:	84 c0                	test   %al,%al
f01061b1:	74 0e                	je     f01061c1 <mpsearch1+0xb1>
	for (; mp < end; mp++)
f01061b3:	83 c3 10             	add    $0x10,%ebx
f01061b6:	39 f3                	cmp    %esi,%ebx
f01061b8:	72 c6                	jb     f0106180 <mpsearch1+0x70>
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01061ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01061bf:	eb 02                	jmp    f01061c3 <mpsearch1+0xb3>
f01061c1:	89 d8                	mov    %ebx,%eax
}
f01061c3:	83 c4 10             	add    $0x10,%esp
f01061c6:	5b                   	pop    %ebx
f01061c7:	5e                   	pop    %esi
f01061c8:	5d                   	pop    %ebp
f01061c9:	c3                   	ret    

f01061ca <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01061ca:	55                   	push   %ebp
f01061cb:	89 e5                	mov    %esp,%ebp
f01061cd:	57                   	push   %edi
f01061ce:	56                   	push   %esi
f01061cf:	53                   	push   %ebx
f01061d0:	83 ec 2c             	sub    $0x2c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f01061d3:	c7 05 c0 13 23 f0 20 	movl   $0xf0231020,0xf02313c0
f01061da:	10 23 f0 
	if (PGNUM(pa) >= npages)
f01061dd:	83 3d 88 0e 23 f0 00 	cmpl   $0x0,0xf0230e88
f01061e4:	75 24                	jne    f010620a <mp_init+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01061e6:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
f01061ed:	00 
f01061ee:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f01061f5:	f0 
f01061f6:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f01061fd:	00 
f01061fe:	c7 04 24 e1 86 10 f0 	movl   $0xf01086e1,(%esp)
f0106205:	e8 36 9e ff ff       	call   f0100040 <_panic>
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f010620a:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0106211:	85 c0                	test   %eax,%eax
f0106213:	74 16                	je     f010622b <mp_init+0x61>
		p <<= 4;	// Translate from segment to PA
f0106215:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0106218:	ba 00 04 00 00       	mov    $0x400,%edx
f010621d:	e8 ee fe ff ff       	call   f0106110 <mpsearch1>
f0106222:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0106225:	85 c0                	test   %eax,%eax
f0106227:	75 3c                	jne    f0106265 <mp_init+0x9b>
f0106229:	eb 20                	jmp    f010624b <mp_init+0x81>
		p = *(uint16_t *) (bda + 0x13) * 1024;
f010622b:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0106232:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0106235:	2d 00 04 00 00       	sub    $0x400,%eax
f010623a:	ba 00 04 00 00       	mov    $0x400,%edx
f010623f:	e8 cc fe ff ff       	call   f0106110 <mpsearch1>
f0106244:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0106247:	85 c0                	test   %eax,%eax
f0106249:	75 1a                	jne    f0106265 <mp_init+0x9b>
	return mpsearch1(0xF0000, 0x10000);
f010624b:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106250:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0106255:	e8 b6 fe ff ff       	call   f0106110 <mpsearch1>
f010625a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if ((mp = mpsearch()) == 0)
f010625d:	85 c0                	test   %eax,%eax
f010625f:	0f 84 54 02 00 00    	je     f01064b9 <mp_init+0x2ef>
	if (mp->physaddr == 0 || mp->type != 0) {
f0106265:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0106268:	8b 70 04             	mov    0x4(%eax),%esi
f010626b:	85 f6                	test   %esi,%esi
f010626d:	74 06                	je     f0106275 <mp_init+0xab>
f010626f:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0106273:	74 11                	je     f0106286 <mp_init+0xbc>
		cprintf("SMP: Default configurations not implemented\n");
f0106275:	c7 04 24 54 85 10 f0 	movl   $0xf0108554,(%esp)
f010627c:	e8 e2 dc ff ff       	call   f0103f63 <cprintf>
f0106281:	e9 33 02 00 00       	jmp    f01064b9 <mp_init+0x2ef>
	if (PGNUM(pa) >= npages)
f0106286:	89 f0                	mov    %esi,%eax
f0106288:	c1 e8 0c             	shr    $0xc,%eax
f010628b:	3b 05 88 0e 23 f0    	cmp    0xf0230e88,%eax
f0106291:	72 20                	jb     f01062b3 <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106293:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0106297:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f010629e:	f0 
f010629f:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
f01062a6:	00 
f01062a7:	c7 04 24 e1 86 10 f0 	movl   $0xf01086e1,(%esp)
f01062ae:	e8 8d 9d ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01062b3:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
	if (memcmp(conf, "PCMP", 4) != 0) {
f01062b9:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f01062c0:	00 
f01062c1:	c7 44 24 04 f6 86 10 	movl   $0xf01086f6,0x4(%esp)
f01062c8:	f0 
f01062c9:	89 1c 24             	mov    %ebx,(%esp)
f01062cc:	e8 8c fc ff ff       	call   f0105f5d <memcmp>
f01062d1:	85 c0                	test   %eax,%eax
f01062d3:	74 11                	je     f01062e6 <mp_init+0x11c>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01062d5:	c7 04 24 84 85 10 f0 	movl   $0xf0108584,(%esp)
f01062dc:	e8 82 dc ff ff       	call   f0103f63 <cprintf>
f01062e1:	e9 d3 01 00 00       	jmp    f01064b9 <mp_init+0x2ef>
	if (sum(conf, conf->length) != 0) {
f01062e6:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01062ea:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f01062ee:	0f b7 f8             	movzwl %ax,%edi
	sum = 0;
f01062f1:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01062f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01062fb:	eb 0d                	jmp    f010630a <mp_init+0x140>
		sum += ((uint8_t *)addr)[i];
f01062fd:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0106304:	f0 
f0106305:	01 ca                	add    %ecx,%edx
	for (i = 0; i < len; i++)
f0106307:	83 c0 01             	add    $0x1,%eax
f010630a:	39 c7                	cmp    %eax,%edi
f010630c:	7f ef                	jg     f01062fd <mp_init+0x133>
	if (sum(conf, conf->length) != 0) {
f010630e:	84 d2                	test   %dl,%dl
f0106310:	74 11                	je     f0106323 <mp_init+0x159>
		cprintf("SMP: Bad MP configuration checksum\n");
f0106312:	c7 04 24 b8 85 10 f0 	movl   $0xf01085b8,(%esp)
f0106319:	e8 45 dc ff ff       	call   f0103f63 <cprintf>
f010631e:	e9 96 01 00 00       	jmp    f01064b9 <mp_init+0x2ef>
	if (conf->version != 1 && conf->version != 4) {
f0106323:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0106327:	3c 04                	cmp    $0x4,%al
f0106329:	74 1f                	je     f010634a <mp_init+0x180>
f010632b:	3c 01                	cmp    $0x1,%al
f010632d:	8d 76 00             	lea    0x0(%esi),%esi
f0106330:	74 18                	je     f010634a <mp_init+0x180>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0106332:	0f b6 c0             	movzbl %al,%eax
f0106335:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106339:	c7 04 24 dc 85 10 f0 	movl   $0xf01085dc,(%esp)
f0106340:	e8 1e dc ff ff       	call   f0103f63 <cprintf>
f0106345:	e9 6f 01 00 00       	jmp    f01064b9 <mp_init+0x2ef>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010634a:	0f b7 73 28          	movzwl 0x28(%ebx),%esi
f010634e:	0f b7 7d e2          	movzwl -0x1e(%ebp),%edi
f0106352:	01 df                	add    %ebx,%edi
	sum = 0;
f0106354:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0106359:	b8 00 00 00 00       	mov    $0x0,%eax
f010635e:	eb 09                	jmp    f0106369 <mp_init+0x19f>
		sum += ((uint8_t *)addr)[i];
f0106360:	0f b6 0c 07          	movzbl (%edi,%eax,1),%ecx
f0106364:	01 ca                	add    %ecx,%edx
	for (i = 0; i < len; i++)
f0106366:	83 c0 01             	add    $0x1,%eax
f0106369:	39 c6                	cmp    %eax,%esi
f010636b:	7f f3                	jg     f0106360 <mp_init+0x196>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010636d:	02 53 2a             	add    0x2a(%ebx),%dl
f0106370:	84 d2                	test   %dl,%dl
f0106372:	74 11                	je     f0106385 <mp_init+0x1bb>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0106374:	c7 04 24 fc 85 10 f0 	movl   $0xf01085fc,(%esp)
f010637b:	e8 e3 db ff ff       	call   f0103f63 <cprintf>
f0106380:	e9 34 01 00 00       	jmp    f01064b9 <mp_init+0x2ef>
	if ((conf = mpconfig(&mp)) == 0)
f0106385:	85 db                	test   %ebx,%ebx
f0106387:	0f 84 2c 01 00 00    	je     f01064b9 <mp_init+0x2ef>
		return;
	ismp = 1;
f010638d:	c7 05 00 10 23 f0 01 	movl   $0x1,0xf0231000
f0106394:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0106397:	8b 43 24             	mov    0x24(%ebx),%eax
f010639a:	a3 00 20 27 f0       	mov    %eax,0xf0272000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010639f:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01063a2:	be 00 00 00 00       	mov    $0x0,%esi
f01063a7:	e9 86 00 00 00       	jmp    f0106432 <mp_init+0x268>
		switch (*p) {
f01063ac:	0f b6 07             	movzbl (%edi),%eax
f01063af:	84 c0                	test   %al,%al
f01063b1:	74 06                	je     f01063b9 <mp_init+0x1ef>
f01063b3:	3c 04                	cmp    $0x4,%al
f01063b5:	77 57                	ja     f010640e <mp_init+0x244>
f01063b7:	eb 50                	jmp    f0106409 <mp_init+0x23f>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01063b9:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01063bd:	8d 76 00             	lea    0x0(%esi),%esi
f01063c0:	74 11                	je     f01063d3 <mp_init+0x209>
				bootcpu = &cpus[ncpu];
f01063c2:	6b 05 c4 13 23 f0 74 	imul   $0x74,0xf02313c4,%eax
f01063c9:	05 20 10 23 f0       	add    $0xf0231020,%eax
f01063ce:	a3 c0 13 23 f0       	mov    %eax,0xf02313c0
			if (ncpu < NCPU) {
f01063d3:	a1 c4 13 23 f0       	mov    0xf02313c4,%eax
f01063d8:	83 f8 07             	cmp    $0x7,%eax
f01063db:	7f 13                	jg     f01063f0 <mp_init+0x226>
				cpus[ncpu].cpu_id = ncpu;
f01063dd:	6b d0 74             	imul   $0x74,%eax,%edx
f01063e0:	88 82 20 10 23 f0    	mov    %al,-0xfdcefe0(%edx)
				ncpu++;
f01063e6:	83 c0 01             	add    $0x1,%eax
f01063e9:	a3 c4 13 23 f0       	mov    %eax,0xf02313c4
f01063ee:	eb 14                	jmp    f0106404 <mp_init+0x23a>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01063f0:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01063f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01063f8:	c7 04 24 2c 86 10 f0 	movl   $0xf010862c,(%esp)
f01063ff:	e8 5f db ff ff       	call   f0103f63 <cprintf>
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0106404:	83 c7 14             	add    $0x14,%edi
			continue;
f0106407:	eb 26                	jmp    f010642f <mp_init+0x265>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0106409:	83 c7 08             	add    $0x8,%edi
			continue;
f010640c:	eb 21                	jmp    f010642f <mp_init+0x265>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f010640e:	0f b6 c0             	movzbl %al,%eax
f0106411:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106415:	c7 04 24 54 86 10 f0 	movl   $0xf0108654,(%esp)
f010641c:	e8 42 db ff ff       	call   f0103f63 <cprintf>
			ismp = 0;
f0106421:	c7 05 00 10 23 f0 00 	movl   $0x0,0xf0231000
f0106428:	00 00 00 
			i = conf->entry;
f010642b:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010642f:	83 c6 01             	add    $0x1,%esi
f0106432:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0106436:	39 c6                	cmp    %eax,%esi
f0106438:	0f 82 6e ff ff ff    	jb     f01063ac <mp_init+0x1e2>
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f010643e:	a1 c0 13 23 f0       	mov    0xf02313c0,%eax
f0106443:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010644a:	83 3d 00 10 23 f0 00 	cmpl   $0x0,0xf0231000
f0106451:	75 22                	jne    f0106475 <mp_init+0x2ab>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0106453:	c7 05 c4 13 23 f0 01 	movl   $0x1,0xf02313c4
f010645a:	00 00 00 
		lapicaddr = 0;
f010645d:	c7 05 00 20 27 f0 00 	movl   $0x0,0xf0272000
f0106464:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0106467:	c7 04 24 74 86 10 f0 	movl   $0xf0108674,(%esp)
f010646e:	e8 f0 da ff ff       	call   f0103f63 <cprintf>
		return;
f0106473:	eb 44                	jmp    f01064b9 <mp_init+0x2ef>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0106475:	8b 15 c4 13 23 f0    	mov    0xf02313c4,%edx
f010647b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010647f:	0f b6 00             	movzbl (%eax),%eax
f0106482:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106486:	c7 04 24 fb 86 10 f0 	movl   $0xf01086fb,(%esp)
f010648d:	e8 d1 da ff ff       	call   f0103f63 <cprintf>

	if (mp->imcrp) {
f0106492:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0106495:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0106499:	74 1e                	je     f01064b9 <mp_init+0x2ef>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f010649b:	c7 04 24 a0 86 10 f0 	movl   $0xf01086a0,(%esp)
f01064a2:	e8 bc da ff ff       	call   f0103f63 <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01064a7:	ba 22 00 00 00       	mov    $0x22,%edx
f01064ac:	b8 70 00 00 00       	mov    $0x70,%eax
f01064b1:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01064b2:	b2 23                	mov    $0x23,%dl
f01064b4:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f01064b5:	83 c8 01             	or     $0x1,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01064b8:	ee                   	out    %al,(%dx)
	}
}
f01064b9:	83 c4 2c             	add    $0x2c,%esp
f01064bc:	5b                   	pop    %ebx
f01064bd:	5e                   	pop    %esi
f01064be:	5f                   	pop    %edi
f01064bf:	5d                   	pop    %ebp
f01064c0:	c3                   	ret    

f01064c1 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01064c1:	55                   	push   %ebp
f01064c2:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01064c4:	8b 0d 04 20 27 f0    	mov    0xf0272004,%ecx
f01064ca:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01064cd:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01064cf:	a1 04 20 27 f0       	mov    0xf0272004,%eax
f01064d4:	8b 40 20             	mov    0x20(%eax),%eax
}
f01064d7:	5d                   	pop    %ebp
f01064d8:	c3                   	ret    

f01064d9 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01064d9:	55                   	push   %ebp
f01064da:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01064dc:	a1 04 20 27 f0       	mov    0xf0272004,%eax
f01064e1:	85 c0                	test   %eax,%eax
f01064e3:	74 08                	je     f01064ed <cpunum+0x14>
		return lapic[ID] >> 24;
f01064e5:	8b 40 20             	mov    0x20(%eax),%eax
f01064e8:	c1 e8 18             	shr    $0x18,%eax
f01064eb:	eb 05                	jmp    f01064f2 <cpunum+0x19>
	return 0;
f01064ed:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01064f2:	5d                   	pop    %ebp
f01064f3:	c3                   	ret    

f01064f4 <lapic_init>:
	if (!lapicaddr)
f01064f4:	a1 00 20 27 f0       	mov    0xf0272000,%eax
f01064f9:	85 c0                	test   %eax,%eax
f01064fb:	0f 84 23 01 00 00    	je     f0106624 <lapic_init+0x130>
{
f0106501:	55                   	push   %ebp
f0106502:	89 e5                	mov    %esp,%ebp
f0106504:	83 ec 18             	sub    $0x18,%esp
	lapic = mmio_map_region(lapicaddr, 4096);
f0106507:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010650e:	00 
f010650f:	89 04 24             	mov    %eax,(%esp)
f0106512:	e8 bd af ff ff       	call   f01014d4 <mmio_map_region>
f0106517:	a3 04 20 27 f0       	mov    %eax,0xf0272004
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f010651c:	ba 27 01 00 00       	mov    $0x127,%edx
f0106521:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0106526:	e8 96 ff ff ff       	call   f01064c1 <lapicw>
	lapicw(TDCR, X1);
f010652b:	ba 0b 00 00 00       	mov    $0xb,%edx
f0106530:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0106535:	e8 87 ff ff ff       	call   f01064c1 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f010653a:	ba 20 00 02 00       	mov    $0x20020,%edx
f010653f:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0106544:	e8 78 ff ff ff       	call   f01064c1 <lapicw>
	lapicw(TICR, 10000000); 
f0106549:	ba 80 96 98 00       	mov    $0x989680,%edx
f010654e:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0106553:	e8 69 ff ff ff       	call   f01064c1 <lapicw>
	if (thiscpu != bootcpu)
f0106558:	e8 7c ff ff ff       	call   f01064d9 <cpunum>
f010655d:	6b c0 74             	imul   $0x74,%eax,%eax
f0106560:	05 20 10 23 f0       	add    $0xf0231020,%eax
f0106565:	39 05 c0 13 23 f0    	cmp    %eax,0xf02313c0
f010656b:	74 0f                	je     f010657c <lapic_init+0x88>
		lapicw(LINT0, MASKED);
f010656d:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106572:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0106577:	e8 45 ff ff ff       	call   f01064c1 <lapicw>
	lapicw(LINT1, MASKED);
f010657c:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106581:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0106586:	e8 36 ff ff ff       	call   f01064c1 <lapicw>
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f010658b:	a1 04 20 27 f0       	mov    0xf0272004,%eax
f0106590:	8b 40 30             	mov    0x30(%eax),%eax
f0106593:	c1 e8 10             	shr    $0x10,%eax
f0106596:	3c 03                	cmp    $0x3,%al
f0106598:	76 0f                	jbe    f01065a9 <lapic_init+0xb5>
		lapicw(PCINT, MASKED);
f010659a:	ba 00 00 01 00       	mov    $0x10000,%edx
f010659f:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01065a4:	e8 18 ff ff ff       	call   f01064c1 <lapicw>
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01065a9:	ba 33 00 00 00       	mov    $0x33,%edx
f01065ae:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01065b3:	e8 09 ff ff ff       	call   f01064c1 <lapicw>
	lapicw(ESR, 0);
f01065b8:	ba 00 00 00 00       	mov    $0x0,%edx
f01065bd:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01065c2:	e8 fa fe ff ff       	call   f01064c1 <lapicw>
	lapicw(ESR, 0);
f01065c7:	ba 00 00 00 00       	mov    $0x0,%edx
f01065cc:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01065d1:	e8 eb fe ff ff       	call   f01064c1 <lapicw>
	lapicw(EOI, 0);
f01065d6:	ba 00 00 00 00       	mov    $0x0,%edx
f01065db:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01065e0:	e8 dc fe ff ff       	call   f01064c1 <lapicw>
	lapicw(ICRHI, 0);
f01065e5:	ba 00 00 00 00       	mov    $0x0,%edx
f01065ea:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01065ef:	e8 cd fe ff ff       	call   f01064c1 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f01065f4:	ba 00 85 08 00       	mov    $0x88500,%edx
f01065f9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01065fe:	e8 be fe ff ff       	call   f01064c1 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0106603:	8b 15 04 20 27 f0    	mov    0xf0272004,%edx
f0106609:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010660f:	f6 c4 10             	test   $0x10,%ah
f0106612:	75 f5                	jne    f0106609 <lapic_init+0x115>
	lapicw(TPR, 0);
f0106614:	ba 00 00 00 00       	mov    $0x0,%edx
f0106619:	b8 20 00 00 00       	mov    $0x20,%eax
f010661e:	e8 9e fe ff ff       	call   f01064c1 <lapicw>
}
f0106623:	c9                   	leave  
f0106624:	f3 c3                	repz ret 

f0106626 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0106626:	83 3d 04 20 27 f0 00 	cmpl   $0x0,0xf0272004
f010662d:	74 13                	je     f0106642 <lapic_eoi+0x1c>
{
f010662f:	55                   	push   %ebp
f0106630:	89 e5                	mov    %esp,%ebp
		lapicw(EOI, 0);
f0106632:	ba 00 00 00 00       	mov    $0x0,%edx
f0106637:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010663c:	e8 80 fe ff ff       	call   f01064c1 <lapicw>
}
f0106641:	5d                   	pop    %ebp
f0106642:	f3 c3                	repz ret 

f0106644 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0106644:	55                   	push   %ebp
f0106645:	89 e5                	mov    %esp,%ebp
f0106647:	56                   	push   %esi
f0106648:	53                   	push   %ebx
f0106649:	83 ec 10             	sub    $0x10,%esp
f010664c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010664f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0106652:	ba 70 00 00 00       	mov    $0x70,%edx
f0106657:	b8 0f 00 00 00       	mov    $0xf,%eax
f010665c:	ee                   	out    %al,(%dx)
f010665d:	b2 71                	mov    $0x71,%dl
f010665f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0106664:	ee                   	out    %al,(%dx)
	if (PGNUM(pa) >= npages)
f0106665:	83 3d 88 0e 23 f0 00 	cmpl   $0x0,0xf0230e88
f010666c:	75 24                	jne    f0106692 <lapic_startap+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010666e:	c7 44 24 0c 67 04 00 	movl   $0x467,0xc(%esp)
f0106675:	00 
f0106676:	c7 44 24 08 e4 6b 10 	movl   $0xf0106be4,0x8(%esp)
f010667d:	f0 
f010667e:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f0106685:	00 
f0106686:	c7 04 24 18 87 10 f0 	movl   $0xf0108718,(%esp)
f010668d:	e8 ae 99 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0106692:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0106699:	00 00 
	wrv[1] = addr >> 4;
f010669b:	89 f0                	mov    %esi,%eax
f010669d:	c1 e8 04             	shr    $0x4,%eax
f01066a0:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01066a6:	c1 e3 18             	shl    $0x18,%ebx
f01066a9:	89 da                	mov    %ebx,%edx
f01066ab:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01066b0:	e8 0c fe ff ff       	call   f01064c1 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f01066b5:	ba 00 c5 00 00       	mov    $0xc500,%edx
f01066ba:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01066bf:	e8 fd fd ff ff       	call   f01064c1 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f01066c4:	ba 00 85 00 00       	mov    $0x8500,%edx
f01066c9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01066ce:	e8 ee fd ff ff       	call   f01064c1 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01066d3:	c1 ee 0c             	shr    $0xc,%esi
f01066d6:	81 ce 00 06 00 00    	or     $0x600,%esi
		lapicw(ICRHI, apicid << 24);
f01066dc:	89 da                	mov    %ebx,%edx
f01066de:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01066e3:	e8 d9 fd ff ff       	call   f01064c1 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01066e8:	89 f2                	mov    %esi,%edx
f01066ea:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01066ef:	e8 cd fd ff ff       	call   f01064c1 <lapicw>
		lapicw(ICRHI, apicid << 24);
f01066f4:	89 da                	mov    %ebx,%edx
f01066f6:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01066fb:	e8 c1 fd ff ff       	call   f01064c1 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106700:	89 f2                	mov    %esi,%edx
f0106702:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106707:	e8 b5 fd ff ff       	call   f01064c1 <lapicw>
		microdelay(200);
	}
}
f010670c:	83 c4 10             	add    $0x10,%esp
f010670f:	5b                   	pop    %ebx
f0106710:	5e                   	pop    %esi
f0106711:	5d                   	pop    %ebp
f0106712:	c3                   	ret    

f0106713 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0106713:	55                   	push   %ebp
f0106714:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0106716:	8b 55 08             	mov    0x8(%ebp),%edx
f0106719:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010671f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106724:	e8 98 fd ff ff       	call   f01064c1 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0106729:	8b 15 04 20 27 f0    	mov    0xf0272004,%edx
f010672f:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0106735:	f6 c4 10             	test   $0x10,%ah
f0106738:	75 f5                	jne    f010672f <lapic_ipi+0x1c>
		;
}
f010673a:	5d                   	pop    %ebp
f010673b:	c3                   	ret    

f010673c <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f010673c:	55                   	push   %ebp
f010673d:	89 e5                	mov    %esp,%ebp
f010673f:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0106742:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0106748:	8b 55 0c             	mov    0xc(%ebp),%edx
f010674b:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f010674e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0106755:	5d                   	pop    %ebp
f0106756:	c3                   	ret    

f0106757 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0106757:	55                   	push   %ebp
f0106758:	89 e5                	mov    %esp,%ebp
f010675a:	56                   	push   %esi
f010675b:	53                   	push   %ebx
f010675c:	83 ec 20             	sub    $0x20,%esp
f010675f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	return lock->locked && lock->cpu == thiscpu;
f0106762:	83 3b 00             	cmpl   $0x0,(%ebx)
f0106765:	75 07                	jne    f010676e <spin_lock+0x17>
	asm volatile("lock; xchgl %0, %1"
f0106767:	ba 01 00 00 00       	mov    $0x1,%edx
f010676c:	eb 42                	jmp    f01067b0 <spin_lock+0x59>
f010676e:	8b 73 08             	mov    0x8(%ebx),%esi
f0106771:	e8 63 fd ff ff       	call   f01064d9 <cpunum>
f0106776:	6b c0 74             	imul   $0x74,%eax,%eax
f0106779:	05 20 10 23 f0       	add    $0xf0231020,%eax
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f010677e:	39 c6                	cmp    %eax,%esi
f0106780:	75 e5                	jne    f0106767 <spin_lock+0x10>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0106782:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0106785:	e8 4f fd ff ff       	call   f01064d9 <cpunum>
f010678a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f010678e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0106792:	c7 44 24 08 28 87 10 	movl   $0xf0108728,0x8(%esp)
f0106799:	f0 
f010679a:	c7 44 24 04 41 00 00 	movl   $0x41,0x4(%esp)
f01067a1:	00 
f01067a2:	c7 04 24 8c 87 10 f0 	movl   $0xf010878c,(%esp)
f01067a9:	e8 92 98 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f01067ae:	f3 90                	pause  
f01067b0:	89 d0                	mov    %edx,%eax
f01067b2:	f0 87 03             	lock xchg %eax,(%ebx)
	while (xchg(&lk->locked, 1) != 0)
f01067b5:	85 c0                	test   %eax,%eax
f01067b7:	75 f5                	jne    f01067ae <spin_lock+0x57>

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f01067b9:	e8 1b fd ff ff       	call   f01064d9 <cpunum>
f01067be:	6b c0 74             	imul   $0x74,%eax,%eax
f01067c1:	05 20 10 23 f0       	add    $0xf0231020,%eax
f01067c6:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f01067c9:	83 c3 0c             	add    $0xc,%ebx
	ebp = (uint32_t *)read_ebp();
f01067cc:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f01067ce:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f01067d3:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f01067d9:	76 12                	jbe    f01067ed <spin_lock+0x96>
		pcs[i] = ebp[1];          // saved %eip
f01067db:	8b 4a 04             	mov    0x4(%edx),%ecx
f01067de:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f01067e1:	8b 12                	mov    (%edx),%edx
	for (i = 0; i < 10; i++){
f01067e3:	83 c0 01             	add    $0x1,%eax
f01067e6:	83 f8 0a             	cmp    $0xa,%eax
f01067e9:	75 e8                	jne    f01067d3 <spin_lock+0x7c>
f01067eb:	eb 0f                	jmp    f01067fc <spin_lock+0xa5>
		pcs[i] = 0;
f01067ed:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
	for (; i < 10; i++)
f01067f4:	83 c0 01             	add    $0x1,%eax
f01067f7:	83 f8 09             	cmp    $0x9,%eax
f01067fa:	7e f1                	jle    f01067ed <spin_lock+0x96>
#endif
}
f01067fc:	83 c4 20             	add    $0x20,%esp
f01067ff:	5b                   	pop    %ebx
f0106800:	5e                   	pop    %esi
f0106801:	5d                   	pop    %ebp
f0106802:	c3                   	ret    

f0106803 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0106803:	55                   	push   %ebp
f0106804:	89 e5                	mov    %esp,%ebp
f0106806:	57                   	push   %edi
f0106807:	56                   	push   %esi
f0106808:	53                   	push   %ebx
f0106809:	83 ec 6c             	sub    $0x6c,%esp
f010680c:	8b 75 08             	mov    0x8(%ebp),%esi
	return lock->locked && lock->cpu == thiscpu;
f010680f:	83 3e 00             	cmpl   $0x0,(%esi)
f0106812:	74 18                	je     f010682c <spin_unlock+0x29>
f0106814:	8b 5e 08             	mov    0x8(%esi),%ebx
f0106817:	e8 bd fc ff ff       	call   f01064d9 <cpunum>
f010681c:	6b c0 74             	imul   $0x74,%eax,%eax
f010681f:	05 20 10 23 f0       	add    $0xf0231020,%eax
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0106824:	39 c3                	cmp    %eax,%ebx
f0106826:	0f 84 ce 00 00 00    	je     f01068fa <spin_unlock+0xf7>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f010682c:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
f0106833:	00 
f0106834:	8d 46 0c             	lea    0xc(%esi),%eax
f0106837:	89 44 24 04          	mov    %eax,0x4(%esp)
f010683b:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f010683e:	89 1c 24             	mov    %ebx,(%esp)
f0106841:	e8 8e f6 ff ff       	call   f0105ed4 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0106846:	8b 46 08             	mov    0x8(%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0106849:	0f b6 38             	movzbl (%eax),%edi
f010684c:	8b 76 04             	mov    0x4(%esi),%esi
f010684f:	e8 85 fc ff ff       	call   f01064d9 <cpunum>
f0106854:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106858:	89 74 24 08          	mov    %esi,0x8(%esp)
f010685c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106860:	c7 04 24 54 87 10 f0 	movl   $0xf0108754,(%esp)
f0106867:	e8 f7 d6 ff ff       	call   f0103f63 <cprintf>
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f010686c:	8d 7d a8             	lea    -0x58(%ebp),%edi
f010686f:	eb 65                	jmp    f01068d6 <spin_unlock+0xd3>
f0106871:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0106875:	89 04 24             	mov    %eax,(%esp)
f0106878:	e8 d2 ea ff ff       	call   f010534f <debuginfo_eip>
f010687d:	85 c0                	test   %eax,%eax
f010687f:	78 39                	js     f01068ba <spin_unlock+0xb7>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0106881:	8b 06                	mov    (%esi),%eax
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0106883:	89 c2                	mov    %eax,%edx
f0106885:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0106888:	89 54 24 18          	mov    %edx,0x18(%esp)
f010688c:	8b 55 b0             	mov    -0x50(%ebp),%edx
f010688f:	89 54 24 14          	mov    %edx,0x14(%esp)
f0106893:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0106896:	89 54 24 10          	mov    %edx,0x10(%esp)
f010689a:	8b 55 ac             	mov    -0x54(%ebp),%edx
f010689d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01068a1:	8b 55 a8             	mov    -0x58(%ebp),%edx
f01068a4:	89 54 24 08          	mov    %edx,0x8(%esp)
f01068a8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01068ac:	c7 04 24 9c 87 10 f0 	movl   $0xf010879c,(%esp)
f01068b3:	e8 ab d6 ff ff       	call   f0103f63 <cprintf>
f01068b8:	eb 12                	jmp    f01068cc <spin_unlock+0xc9>
			else
				cprintf("  %08x\n", pcs[i]);
f01068ba:	8b 06                	mov    (%esi),%eax
f01068bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01068c0:	c7 04 24 b3 87 10 f0 	movl   $0xf01087b3,(%esp)
f01068c7:	e8 97 d6 ff ff       	call   f0103f63 <cprintf>
f01068cc:	83 c3 04             	add    $0x4,%ebx
		for (i = 0; i < 10 && pcs[i]; i++) {
f01068cf:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01068d2:	39 c3                	cmp    %eax,%ebx
f01068d4:	74 08                	je     f01068de <spin_unlock+0xdb>
f01068d6:	89 de                	mov    %ebx,%esi
f01068d8:	8b 03                	mov    (%ebx),%eax
f01068da:	85 c0                	test   %eax,%eax
f01068dc:	75 93                	jne    f0106871 <spin_unlock+0x6e>
		}
		panic("spin_unlock");
f01068de:	c7 44 24 08 bb 87 10 	movl   $0xf01087bb,0x8(%esp)
f01068e5:	f0 
f01068e6:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
f01068ed:	00 
f01068ee:	c7 04 24 8c 87 10 f0 	movl   $0xf010878c,(%esp)
f01068f5:	e8 46 97 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f01068fa:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0106901:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0106908:	b8 00 00 00 00       	mov    $0x0,%eax
f010690d:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0106910:	83 c4 6c             	add    $0x6c,%esp
f0106913:	5b                   	pop    %ebx
f0106914:	5e                   	pop    %esi
f0106915:	5f                   	pop    %edi
f0106916:	5d                   	pop    %ebp
f0106917:	c3                   	ret    
f0106918:	66 90                	xchg   %ax,%ax
f010691a:	66 90                	xchg   %ax,%ax
f010691c:	66 90                	xchg   %ax,%ax
f010691e:	66 90                	xchg   %ax,%ax

f0106920 <__udivdi3>:
f0106920:	55                   	push   %ebp
f0106921:	57                   	push   %edi
f0106922:	56                   	push   %esi
f0106923:	83 ec 0c             	sub    $0xc,%esp
f0106926:	8b 44 24 28          	mov    0x28(%esp),%eax
f010692a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010692e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0106932:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0106936:	85 c0                	test   %eax,%eax
f0106938:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010693c:	89 ea                	mov    %ebp,%edx
f010693e:	89 0c 24             	mov    %ecx,(%esp)
f0106941:	75 2d                	jne    f0106970 <__udivdi3+0x50>
f0106943:	39 e9                	cmp    %ebp,%ecx
f0106945:	77 61                	ja     f01069a8 <__udivdi3+0x88>
f0106947:	85 c9                	test   %ecx,%ecx
f0106949:	89 ce                	mov    %ecx,%esi
f010694b:	75 0b                	jne    f0106958 <__udivdi3+0x38>
f010694d:	b8 01 00 00 00       	mov    $0x1,%eax
f0106952:	31 d2                	xor    %edx,%edx
f0106954:	f7 f1                	div    %ecx
f0106956:	89 c6                	mov    %eax,%esi
f0106958:	31 d2                	xor    %edx,%edx
f010695a:	89 e8                	mov    %ebp,%eax
f010695c:	f7 f6                	div    %esi
f010695e:	89 c5                	mov    %eax,%ebp
f0106960:	89 f8                	mov    %edi,%eax
f0106962:	f7 f6                	div    %esi
f0106964:	89 ea                	mov    %ebp,%edx
f0106966:	83 c4 0c             	add    $0xc,%esp
f0106969:	5e                   	pop    %esi
f010696a:	5f                   	pop    %edi
f010696b:	5d                   	pop    %ebp
f010696c:	c3                   	ret    
f010696d:	8d 76 00             	lea    0x0(%esi),%esi
f0106970:	39 e8                	cmp    %ebp,%eax
f0106972:	77 24                	ja     f0106998 <__udivdi3+0x78>
f0106974:	0f bd e8             	bsr    %eax,%ebp
f0106977:	83 f5 1f             	xor    $0x1f,%ebp
f010697a:	75 3c                	jne    f01069b8 <__udivdi3+0x98>
f010697c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0106980:	39 34 24             	cmp    %esi,(%esp)
f0106983:	0f 86 9f 00 00 00    	jbe    f0106a28 <__udivdi3+0x108>
f0106989:	39 d0                	cmp    %edx,%eax
f010698b:	0f 82 97 00 00 00    	jb     f0106a28 <__udivdi3+0x108>
f0106991:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106998:	31 d2                	xor    %edx,%edx
f010699a:	31 c0                	xor    %eax,%eax
f010699c:	83 c4 0c             	add    $0xc,%esp
f010699f:	5e                   	pop    %esi
f01069a0:	5f                   	pop    %edi
f01069a1:	5d                   	pop    %ebp
f01069a2:	c3                   	ret    
f01069a3:	90                   	nop
f01069a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01069a8:	89 f8                	mov    %edi,%eax
f01069aa:	f7 f1                	div    %ecx
f01069ac:	31 d2                	xor    %edx,%edx
f01069ae:	83 c4 0c             	add    $0xc,%esp
f01069b1:	5e                   	pop    %esi
f01069b2:	5f                   	pop    %edi
f01069b3:	5d                   	pop    %ebp
f01069b4:	c3                   	ret    
f01069b5:	8d 76 00             	lea    0x0(%esi),%esi
f01069b8:	89 e9                	mov    %ebp,%ecx
f01069ba:	8b 3c 24             	mov    (%esp),%edi
f01069bd:	d3 e0                	shl    %cl,%eax
f01069bf:	89 c6                	mov    %eax,%esi
f01069c1:	b8 20 00 00 00       	mov    $0x20,%eax
f01069c6:	29 e8                	sub    %ebp,%eax
f01069c8:	89 c1                	mov    %eax,%ecx
f01069ca:	d3 ef                	shr    %cl,%edi
f01069cc:	89 e9                	mov    %ebp,%ecx
f01069ce:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01069d2:	8b 3c 24             	mov    (%esp),%edi
f01069d5:	09 74 24 08          	or     %esi,0x8(%esp)
f01069d9:	89 d6                	mov    %edx,%esi
f01069db:	d3 e7                	shl    %cl,%edi
f01069dd:	89 c1                	mov    %eax,%ecx
f01069df:	89 3c 24             	mov    %edi,(%esp)
f01069e2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01069e6:	d3 ee                	shr    %cl,%esi
f01069e8:	89 e9                	mov    %ebp,%ecx
f01069ea:	d3 e2                	shl    %cl,%edx
f01069ec:	89 c1                	mov    %eax,%ecx
f01069ee:	d3 ef                	shr    %cl,%edi
f01069f0:	09 d7                	or     %edx,%edi
f01069f2:	89 f2                	mov    %esi,%edx
f01069f4:	89 f8                	mov    %edi,%eax
f01069f6:	f7 74 24 08          	divl   0x8(%esp)
f01069fa:	89 d6                	mov    %edx,%esi
f01069fc:	89 c7                	mov    %eax,%edi
f01069fe:	f7 24 24             	mull   (%esp)
f0106a01:	39 d6                	cmp    %edx,%esi
f0106a03:	89 14 24             	mov    %edx,(%esp)
f0106a06:	72 30                	jb     f0106a38 <__udivdi3+0x118>
f0106a08:	8b 54 24 04          	mov    0x4(%esp),%edx
f0106a0c:	89 e9                	mov    %ebp,%ecx
f0106a0e:	d3 e2                	shl    %cl,%edx
f0106a10:	39 c2                	cmp    %eax,%edx
f0106a12:	73 05                	jae    f0106a19 <__udivdi3+0xf9>
f0106a14:	3b 34 24             	cmp    (%esp),%esi
f0106a17:	74 1f                	je     f0106a38 <__udivdi3+0x118>
f0106a19:	89 f8                	mov    %edi,%eax
f0106a1b:	31 d2                	xor    %edx,%edx
f0106a1d:	e9 7a ff ff ff       	jmp    f010699c <__udivdi3+0x7c>
f0106a22:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106a28:	31 d2                	xor    %edx,%edx
f0106a2a:	b8 01 00 00 00       	mov    $0x1,%eax
f0106a2f:	e9 68 ff ff ff       	jmp    f010699c <__udivdi3+0x7c>
f0106a34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106a38:	8d 47 ff             	lea    -0x1(%edi),%eax
f0106a3b:	31 d2                	xor    %edx,%edx
f0106a3d:	83 c4 0c             	add    $0xc,%esp
f0106a40:	5e                   	pop    %esi
f0106a41:	5f                   	pop    %edi
f0106a42:	5d                   	pop    %ebp
f0106a43:	c3                   	ret    
f0106a44:	66 90                	xchg   %ax,%ax
f0106a46:	66 90                	xchg   %ax,%ax
f0106a48:	66 90                	xchg   %ax,%ax
f0106a4a:	66 90                	xchg   %ax,%ax
f0106a4c:	66 90                	xchg   %ax,%ax
f0106a4e:	66 90                	xchg   %ax,%ax

f0106a50 <__umoddi3>:
f0106a50:	55                   	push   %ebp
f0106a51:	57                   	push   %edi
f0106a52:	56                   	push   %esi
f0106a53:	83 ec 14             	sub    $0x14,%esp
f0106a56:	8b 44 24 28          	mov    0x28(%esp),%eax
f0106a5a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0106a5e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0106a62:	89 c7                	mov    %eax,%edi
f0106a64:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106a68:	8b 44 24 30          	mov    0x30(%esp),%eax
f0106a6c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0106a70:	89 34 24             	mov    %esi,(%esp)
f0106a73:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106a77:	85 c0                	test   %eax,%eax
f0106a79:	89 c2                	mov    %eax,%edx
f0106a7b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106a7f:	75 17                	jne    f0106a98 <__umoddi3+0x48>
f0106a81:	39 fe                	cmp    %edi,%esi
f0106a83:	76 4b                	jbe    f0106ad0 <__umoddi3+0x80>
f0106a85:	89 c8                	mov    %ecx,%eax
f0106a87:	89 fa                	mov    %edi,%edx
f0106a89:	f7 f6                	div    %esi
f0106a8b:	89 d0                	mov    %edx,%eax
f0106a8d:	31 d2                	xor    %edx,%edx
f0106a8f:	83 c4 14             	add    $0x14,%esp
f0106a92:	5e                   	pop    %esi
f0106a93:	5f                   	pop    %edi
f0106a94:	5d                   	pop    %ebp
f0106a95:	c3                   	ret    
f0106a96:	66 90                	xchg   %ax,%ax
f0106a98:	39 f8                	cmp    %edi,%eax
f0106a9a:	77 54                	ja     f0106af0 <__umoddi3+0xa0>
f0106a9c:	0f bd e8             	bsr    %eax,%ebp
f0106a9f:	83 f5 1f             	xor    $0x1f,%ebp
f0106aa2:	75 5c                	jne    f0106b00 <__umoddi3+0xb0>
f0106aa4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0106aa8:	39 3c 24             	cmp    %edi,(%esp)
f0106aab:	0f 87 e7 00 00 00    	ja     f0106b98 <__umoddi3+0x148>
f0106ab1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0106ab5:	29 f1                	sub    %esi,%ecx
f0106ab7:	19 c7                	sbb    %eax,%edi
f0106ab9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106abd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106ac1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0106ac5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0106ac9:	83 c4 14             	add    $0x14,%esp
f0106acc:	5e                   	pop    %esi
f0106acd:	5f                   	pop    %edi
f0106ace:	5d                   	pop    %ebp
f0106acf:	c3                   	ret    
f0106ad0:	85 f6                	test   %esi,%esi
f0106ad2:	89 f5                	mov    %esi,%ebp
f0106ad4:	75 0b                	jne    f0106ae1 <__umoddi3+0x91>
f0106ad6:	b8 01 00 00 00       	mov    $0x1,%eax
f0106adb:	31 d2                	xor    %edx,%edx
f0106add:	f7 f6                	div    %esi
f0106adf:	89 c5                	mov    %eax,%ebp
f0106ae1:	8b 44 24 04          	mov    0x4(%esp),%eax
f0106ae5:	31 d2                	xor    %edx,%edx
f0106ae7:	f7 f5                	div    %ebp
f0106ae9:	89 c8                	mov    %ecx,%eax
f0106aeb:	f7 f5                	div    %ebp
f0106aed:	eb 9c                	jmp    f0106a8b <__umoddi3+0x3b>
f0106aef:	90                   	nop
f0106af0:	89 c8                	mov    %ecx,%eax
f0106af2:	89 fa                	mov    %edi,%edx
f0106af4:	83 c4 14             	add    $0x14,%esp
f0106af7:	5e                   	pop    %esi
f0106af8:	5f                   	pop    %edi
f0106af9:	5d                   	pop    %ebp
f0106afa:	c3                   	ret    
f0106afb:	90                   	nop
f0106afc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106b00:	8b 04 24             	mov    (%esp),%eax
f0106b03:	be 20 00 00 00       	mov    $0x20,%esi
f0106b08:	89 e9                	mov    %ebp,%ecx
f0106b0a:	29 ee                	sub    %ebp,%esi
f0106b0c:	d3 e2                	shl    %cl,%edx
f0106b0e:	89 f1                	mov    %esi,%ecx
f0106b10:	d3 e8                	shr    %cl,%eax
f0106b12:	89 e9                	mov    %ebp,%ecx
f0106b14:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106b18:	8b 04 24             	mov    (%esp),%eax
f0106b1b:	09 54 24 04          	or     %edx,0x4(%esp)
f0106b1f:	89 fa                	mov    %edi,%edx
f0106b21:	d3 e0                	shl    %cl,%eax
f0106b23:	89 f1                	mov    %esi,%ecx
f0106b25:	89 44 24 08          	mov    %eax,0x8(%esp)
f0106b29:	8b 44 24 10          	mov    0x10(%esp),%eax
f0106b2d:	d3 ea                	shr    %cl,%edx
f0106b2f:	89 e9                	mov    %ebp,%ecx
f0106b31:	d3 e7                	shl    %cl,%edi
f0106b33:	89 f1                	mov    %esi,%ecx
f0106b35:	d3 e8                	shr    %cl,%eax
f0106b37:	89 e9                	mov    %ebp,%ecx
f0106b39:	09 f8                	or     %edi,%eax
f0106b3b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0106b3f:	f7 74 24 04          	divl   0x4(%esp)
f0106b43:	d3 e7                	shl    %cl,%edi
f0106b45:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106b49:	89 d7                	mov    %edx,%edi
f0106b4b:	f7 64 24 08          	mull   0x8(%esp)
f0106b4f:	39 d7                	cmp    %edx,%edi
f0106b51:	89 c1                	mov    %eax,%ecx
f0106b53:	89 14 24             	mov    %edx,(%esp)
f0106b56:	72 2c                	jb     f0106b84 <__umoddi3+0x134>
f0106b58:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0106b5c:	72 22                	jb     f0106b80 <__umoddi3+0x130>
f0106b5e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0106b62:	29 c8                	sub    %ecx,%eax
f0106b64:	19 d7                	sbb    %edx,%edi
f0106b66:	89 e9                	mov    %ebp,%ecx
f0106b68:	89 fa                	mov    %edi,%edx
f0106b6a:	d3 e8                	shr    %cl,%eax
f0106b6c:	89 f1                	mov    %esi,%ecx
f0106b6e:	d3 e2                	shl    %cl,%edx
f0106b70:	89 e9                	mov    %ebp,%ecx
f0106b72:	d3 ef                	shr    %cl,%edi
f0106b74:	09 d0                	or     %edx,%eax
f0106b76:	89 fa                	mov    %edi,%edx
f0106b78:	83 c4 14             	add    $0x14,%esp
f0106b7b:	5e                   	pop    %esi
f0106b7c:	5f                   	pop    %edi
f0106b7d:	5d                   	pop    %ebp
f0106b7e:	c3                   	ret    
f0106b7f:	90                   	nop
f0106b80:	39 d7                	cmp    %edx,%edi
f0106b82:	75 da                	jne    f0106b5e <__umoddi3+0x10e>
f0106b84:	8b 14 24             	mov    (%esp),%edx
f0106b87:	89 c1                	mov    %eax,%ecx
f0106b89:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0106b8d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0106b91:	eb cb                	jmp    f0106b5e <__umoddi3+0x10e>
f0106b93:	90                   	nop
f0106b94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106b98:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0106b9c:	0f 82 0f ff ff ff    	jb     f0106ab1 <__umoddi3+0x61>
f0106ba2:	e9 1a ff ff ff       	jmp    f0106ac1 <__umoddi3+0x71>
