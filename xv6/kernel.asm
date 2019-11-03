
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4                   	.byte 0xe4

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 90 10 00       	mov    $0x109000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc c0 b5 10 80       	mov    $0x8010b5c0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 05 2c 10 80       	mov    $0x80102c05,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	57                   	push   %edi
80100038:	56                   	push   %esi
80100039:	53                   	push   %ebx
8010003a:	83 ec 18             	sub    $0x18,%esp
8010003d:	89 c6                	mov    %eax,%esi
8010003f:	89 d7                	mov    %edx,%edi
  struct buf *b;

  acquire(&bcache.lock);
80100041:	68 c0 b5 10 80       	push   $0x8010b5c0
80100046:	e8 78 3d 00 00       	call   80103dc3 <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 10 fd 10 80    	mov    0x8010fd10,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb bc fc 10 80    	cmp    $0x8010fcbc,%ebx
8010005f:	74 30                	je     80100091 <bget+0x5d>
    if(b->dev == dev && b->blockno == blockno){
80100061:	39 73 04             	cmp    %esi,0x4(%ebx)
80100064:	75 f0                	jne    80100056 <bget+0x22>
80100066:	39 7b 08             	cmp    %edi,0x8(%ebx)
80100069:	75 eb                	jne    80100056 <bget+0x22>
      b->refcnt++;
8010006b:	8b 43 4c             	mov    0x4c(%ebx),%eax
8010006e:	83 c0 01             	add    $0x1,%eax
80100071:	89 43 4c             	mov    %eax,0x4c(%ebx)
      release(&bcache.lock);
80100074:	83 ec 0c             	sub    $0xc,%esp
80100077:	68 c0 b5 10 80       	push   $0x8010b5c0
8010007c:	e8 a7 3d 00 00       	call   80103e28 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 23 3b 00 00       	call   80103baf <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 0c fd 10 80    	mov    0x8010fd0c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb bc fc 10 80    	cmp    $0x8010fcbc,%ebx
801000a2:	74 43                	je     801000e7 <bget+0xb3>
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
801000a4:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801000a8:	75 ef                	jne    80100099 <bget+0x65>
801000aa:	f6 03 04             	testb  $0x4,(%ebx)
801000ad:	75 ea                	jne    80100099 <bget+0x65>
      b->dev = dev;
801000af:	89 73 04             	mov    %esi,0x4(%ebx)
      b->blockno = blockno;
801000b2:	89 7b 08             	mov    %edi,0x8(%ebx)
      b->flags = 0;
801000b5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
      b->refcnt = 1;
801000bb:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
      release(&bcache.lock);
801000c2:	83 ec 0c             	sub    $0xc,%esp
801000c5:	68 c0 b5 10 80       	push   $0x8010b5c0
801000ca:	e8 59 3d 00 00       	call   80103e28 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 d5 3a 00 00       	call   80103baf <acquiresleep>
      return b;
801000da:	83 c4 10             	add    $0x10,%esp
    }
  }
  panic("bget: no buffers");
}
801000dd:	89 d8                	mov    %ebx,%eax
801000df:	8d 65 f4             	lea    -0xc(%ebp),%esp
801000e2:	5b                   	pop    %ebx
801000e3:	5e                   	pop    %esi
801000e4:	5f                   	pop    %edi
801000e5:	5d                   	pop    %ebp
801000e6:	c3                   	ret    
  panic("bget: no buffers");
801000e7:	83 ec 0c             	sub    $0xc,%esp
801000ea:	68 e0 66 10 80       	push   $0x801066e0
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 f1 66 10 80       	push   $0x801066f1
80100100:	68 c0 b5 10 80       	push   $0x8010b5c0
80100105:	e8 7d 3b 00 00       	call   80103c87 <initlock>
  bcache.head.prev = &bcache.head;
8010010a:	c7 05 0c fd 10 80 bc 	movl   $0x8010fcbc,0x8010fd0c
80100111:	fc 10 80 
  bcache.head.next = &bcache.head;
80100114:	c7 05 10 fd 10 80 bc 	movl   $0x8010fcbc,0x8010fd10
8010011b:	fc 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010011e:	83 c4 10             	add    $0x10,%esp
80100121:	bb f4 b5 10 80       	mov    $0x8010b5f4,%ebx
80100126:	eb 37                	jmp    8010015f <binit+0x6b>
    b->next = bcache.head.next;
80100128:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010012d:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100130:	c7 43 50 bc fc 10 80 	movl   $0x8010fcbc,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
80100137:	83 ec 08             	sub    $0x8,%esp
8010013a:	68 f8 66 10 80       	push   $0x801066f8
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 34 3a 00 00       	call   80103b7c <initsleeplock>
    bcache.head.next->prev = b;
80100148:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010014d:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100150:	89 1d 10 fd 10 80    	mov    %ebx,0x8010fd10
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100156:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
8010015c:	83 c4 10             	add    $0x10,%esp
8010015f:	81 fb bc fc 10 80    	cmp    $0x8010fcbc,%ebx
80100165:	72 c1                	jb     80100128 <binit+0x34>
}
80100167:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010016a:	c9                   	leave  
8010016b:	c3                   	ret    

8010016c <bread>:

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
8010016c:	55                   	push   %ebp
8010016d:	89 e5                	mov    %esp,%ebp
8010016f:	53                   	push   %ebx
80100170:	83 ec 04             	sub    $0x4,%esp
  struct buf *b;

  b = bget(dev, blockno);
80100173:	8b 55 0c             	mov    0xc(%ebp),%edx
80100176:	8b 45 08             	mov    0x8(%ebp),%eax
80100179:	e8 b6 fe ff ff       	call   80100034 <bget>
8010017e:	89 c3                	mov    %eax,%ebx
  if((b->flags & B_VALID) == 0) {
80100180:	f6 00 02             	testb  $0x2,(%eax)
80100183:	74 07                	je     8010018c <bread+0x20>
    iderw(b);
  }
  return b;
}
80100185:	89 d8                	mov    %ebx,%eax
80100187:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010018a:	c9                   	leave  
8010018b:	c3                   	ret    
    iderw(b);
8010018c:	83 ec 0c             	sub    $0xc,%esp
8010018f:	50                   	push   %eax
80100190:	e8 77 1c 00 00       	call   80101e0c <iderw>
80100195:	83 c4 10             	add    $0x10,%esp
  return b;
80100198:	eb eb                	jmp    80100185 <bread+0x19>

8010019a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
8010019a:	55                   	push   %ebp
8010019b:	89 e5                	mov    %esp,%ebp
8010019d:	53                   	push   %ebx
8010019e:	83 ec 10             	sub    $0x10,%esp
801001a1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001a4:	8d 43 0c             	lea    0xc(%ebx),%eax
801001a7:	50                   	push   %eax
801001a8:	e8 8c 3a 00 00       	call   80103c39 <holdingsleep>
801001ad:	83 c4 10             	add    $0x10,%esp
801001b0:	85 c0                	test   %eax,%eax
801001b2:	74 14                	je     801001c8 <bwrite+0x2e>
    panic("bwrite");
  b->flags |= B_DIRTY;
801001b4:	83 0b 04             	orl    $0x4,(%ebx)
  iderw(b);
801001b7:	83 ec 0c             	sub    $0xc,%esp
801001ba:	53                   	push   %ebx
801001bb:	e8 4c 1c 00 00       	call   80101e0c <iderw>
}
801001c0:	83 c4 10             	add    $0x10,%esp
801001c3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801001c6:	c9                   	leave  
801001c7:	c3                   	ret    
    panic("bwrite");
801001c8:	83 ec 0c             	sub    $0xc,%esp
801001cb:	68 ff 66 10 80       	push   $0x801066ff
801001d0:	e8 73 01 00 00       	call   80100348 <panic>

801001d5 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
801001d5:	55                   	push   %ebp
801001d6:	89 e5                	mov    %esp,%ebp
801001d8:	56                   	push   %esi
801001d9:	53                   	push   %ebx
801001da:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001dd:	8d 73 0c             	lea    0xc(%ebx),%esi
801001e0:	83 ec 0c             	sub    $0xc,%esp
801001e3:	56                   	push   %esi
801001e4:	e8 50 3a 00 00       	call   80103c39 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 05 3a 00 00       	call   80103bfe <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100200:	e8 be 3b 00 00       	call   80103dc3 <acquire>
  b->refcnt--;
80100205:	8b 43 4c             	mov    0x4c(%ebx),%eax
80100208:	83 e8 01             	sub    $0x1,%eax
8010020b:	89 43 4c             	mov    %eax,0x4c(%ebx)
  if (b->refcnt == 0) {
8010020e:	83 c4 10             	add    $0x10,%esp
80100211:	85 c0                	test   %eax,%eax
80100213:	75 2f                	jne    80100244 <brelse+0x6f>
    // no one is waiting for it.
    b->next->prev = b->prev;
80100215:	8b 43 54             	mov    0x54(%ebx),%eax
80100218:	8b 53 50             	mov    0x50(%ebx),%edx
8010021b:	89 50 50             	mov    %edx,0x50(%eax)
    b->prev->next = b->next;
8010021e:	8b 43 50             	mov    0x50(%ebx),%eax
80100221:	8b 53 54             	mov    0x54(%ebx),%edx
80100224:	89 50 54             	mov    %edx,0x54(%eax)
    b->next = bcache.head.next;
80100227:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010022c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010022f:	c7 43 50 bc fc 10 80 	movl   $0x8010fcbc,0x50(%ebx)
    bcache.head.next->prev = b;
80100236:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010023b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010023e:	89 1d 10 fd 10 80    	mov    %ebx,0x8010fd10
  }
  
  release(&bcache.lock);
80100244:	83 ec 0c             	sub    $0xc,%esp
80100247:	68 c0 b5 10 80       	push   $0x8010b5c0
8010024c:	e8 d7 3b 00 00       	call   80103e28 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 06 67 10 80       	push   $0x80106706
80100263:	e8 e0 00 00 00       	call   80100348 <panic>

80100268 <consoleread>:
  }
}

int
consoleread(struct inode *ip, char *dst, int n)
{
80100268:	55                   	push   %ebp
80100269:	89 e5                	mov    %esp,%ebp
8010026b:	57                   	push   %edi
8010026c:	56                   	push   %esi
8010026d:	53                   	push   %ebx
8010026e:	83 ec 28             	sub    $0x28,%esp
80100271:	8b 7d 08             	mov    0x8(%ebp),%edi
80100274:	8b 75 0c             	mov    0xc(%ebp),%esi
80100277:	8b 5d 10             	mov    0x10(%ebp),%ebx
  uint target;
  int c;

  iunlock(ip);
8010027a:	57                   	push   %edi
8010027b:	e8 c3 13 00 00       	call   80101643 <iunlock>
  target = n;
80100280:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&cons.lock);
80100283:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
8010028a:	e8 34 3b 00 00       	call   80103dc3 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 a0 ff 10 80       	mov    0x8010ffa0,%eax
8010029f:	3b 05 a4 ff 10 80    	cmp    0x8010ffa4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 f9 30 00 00       	call   801033a5 <myproc>
801002ac:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002b0:	75 17                	jne    801002c9 <consoleread+0x61>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002b2:	83 ec 08             	sub    $0x8,%esp
801002b5:	68 20 a5 10 80       	push   $0x8010a520
801002ba:	68 a0 ff 10 80       	push   $0x8010ffa0
801002bf:	e8 85 35 00 00       	call   80103849 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 10 80       	push   $0x8010a520
801002d1:	e8 52 3b 00 00       	call   80103e28 <release>
        ilock(ip);
801002d6:	89 3c 24             	mov    %edi,(%esp)
801002d9:	e8 a3 12 00 00       	call   80101581 <ilock>
        return -1;
801002de:	83 c4 10             	add    $0x10,%esp
801002e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  release(&cons.lock);
  ilock(ip);

  return target - n;
}
801002e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801002e9:	5b                   	pop    %ebx
801002ea:	5e                   	pop    %esi
801002eb:	5f                   	pop    %edi
801002ec:	5d                   	pop    %ebp
801002ed:	c3                   	ret    
    c = input.buf[input.r++ % INPUT_BUF];
801002ee:	8d 50 01             	lea    0x1(%eax),%edx
801002f1:	89 15 a0 ff 10 80    	mov    %edx,0x8010ffa0
801002f7:	89 c2                	mov    %eax,%edx
801002f9:	83 e2 7f             	and    $0x7f,%edx
801002fc:	0f b6 8a 20 ff 10 80 	movzbl -0x7fef00e0(%edx),%ecx
80100303:	0f be d1             	movsbl %cl,%edx
    if(c == C('D')){  // EOF
80100306:	83 fa 04             	cmp    $0x4,%edx
80100309:	74 14                	je     8010031f <consoleread+0xb7>
    *dst++ = c;
8010030b:	8d 46 01             	lea    0x1(%esi),%eax
8010030e:	88 0e                	mov    %cl,(%esi)
    --n;
80100310:	83 eb 01             	sub    $0x1,%ebx
    if(c == '\n')
80100313:	83 fa 0a             	cmp    $0xa,%edx
80100316:	74 11                	je     80100329 <consoleread+0xc1>
    *dst++ = c;
80100318:	89 c6                	mov    %eax,%esi
8010031a:	e9 73 ff ff ff       	jmp    80100292 <consoleread+0x2a>
      if(n < target){
8010031f:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
80100322:	73 05                	jae    80100329 <consoleread+0xc1>
        input.r--;
80100324:	a3 a0 ff 10 80       	mov    %eax,0x8010ffa0
  release(&cons.lock);
80100329:	83 ec 0c             	sub    $0xc,%esp
8010032c:	68 20 a5 10 80       	push   $0x8010a520
80100331:	e8 f2 3a 00 00       	call   80103e28 <release>
  ilock(ip);
80100336:	89 3c 24             	mov    %edi,(%esp)
80100339:	e8 43 12 00 00       	call   80101581 <ilock>
  return target - n;
8010033e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100341:	29 d8                	sub    %ebx,%eax
80100343:	83 c4 10             	add    $0x10,%esp
80100346:	eb 9e                	jmp    801002e6 <consoleread+0x7e>

80100348 <panic>:
{
80100348:	55                   	push   %ebp
80100349:	89 e5                	mov    %esp,%ebp
8010034b:	53                   	push   %ebx
8010034c:	83 ec 34             	sub    $0x34,%esp
}

static inline void
cli(void)
{
  asm volatile("cli");
8010034f:	fa                   	cli    
  cons.locking = 0;
80100350:	c7 05 54 a5 10 80 00 	movl   $0x0,0x8010a554
80100357:	00 00 00 
  cprintf("lapicid %d: panic: ", lapicid());
8010035a:	e8 b5 21 00 00       	call   80102514 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 0d 67 10 80       	push   $0x8010670d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 5b 70 10 80 	movl   $0x8010705b,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 0e 39 00 00       	call   80103ca2 <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 21 67 10 80       	push   $0x80106721
801003aa:	e8 5c 02 00 00       	call   8010060b <cprintf>
  for(i=0; i<10; i++)
801003af:	83 c3 01             	add    $0x1,%ebx
801003b2:	83 c4 10             	add    $0x10,%esp
801003b5:	83 fb 09             	cmp    $0x9,%ebx
801003b8:	7e e4                	jle    8010039e <panic+0x56>
  panicked = 1; // freeze other CPU
801003ba:	c7 05 58 a5 10 80 01 	movl   $0x1,0x8010a558
801003c1:	00 00 00 
801003c4:	eb fe                	jmp    801003c4 <panic+0x7c>

801003c6 <cgaputc>:
{
801003c6:	55                   	push   %ebp
801003c7:	89 e5                	mov    %esp,%ebp
801003c9:	57                   	push   %edi
801003ca:	56                   	push   %esi
801003cb:	53                   	push   %ebx
801003cc:	83 ec 0c             	sub    $0xc,%esp
801003cf:	89 c6                	mov    %eax,%esi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003d1:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
801003d6:	b8 0e 00 00 00       	mov    $0xe,%eax
801003db:	89 ca                	mov    %ecx,%edx
801003dd:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003de:	bb d5 03 00 00       	mov    $0x3d5,%ebx
801003e3:	89 da                	mov    %ebx,%edx
801003e5:	ec                   	in     (%dx),%al
  pos = inb(CRTPORT+1) << 8;
801003e6:	0f b6 f8             	movzbl %al,%edi
801003e9:	c1 e7 08             	shl    $0x8,%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003ec:	b8 0f 00 00 00       	mov    $0xf,%eax
801003f1:	89 ca                	mov    %ecx,%edx
801003f3:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003f4:	89 da                	mov    %ebx,%edx
801003f6:	ec                   	in     (%dx),%al
  pos |= inb(CRTPORT+1);
801003f7:	0f b6 c8             	movzbl %al,%ecx
801003fa:	09 f9                	or     %edi,%ecx
  if(c == '\n')
801003fc:	83 fe 0a             	cmp    $0xa,%esi
801003ff:	74 6a                	je     8010046b <cgaputc+0xa5>
  else if(c == BACKSPACE){
80100401:	81 fe 00 01 00 00    	cmp    $0x100,%esi
80100407:	0f 84 81 00 00 00    	je     8010048e <cgaputc+0xc8>
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010040d:	89 f0                	mov    %esi,%eax
8010040f:	0f b6 f0             	movzbl %al,%esi
80100412:	8d 59 01             	lea    0x1(%ecx),%ebx
80100415:	66 81 ce 00 07       	or     $0x700,%si
8010041a:	66 89 b4 09 00 80 0b 	mov    %si,-0x7ff48000(%ecx,%ecx,1)
80100421:	80 
  if(pos < 0 || pos > 25*80)
80100422:	81 fb d0 07 00 00    	cmp    $0x7d0,%ebx
80100428:	77 71                	ja     8010049b <cgaputc+0xd5>
  if((pos/80) >= 24){  // Scroll up.
8010042a:	81 fb 7f 07 00 00    	cmp    $0x77f,%ebx
80100430:	7f 76                	jg     801004a8 <cgaputc+0xe2>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80100432:	be d4 03 00 00       	mov    $0x3d4,%esi
80100437:	b8 0e 00 00 00       	mov    $0xe,%eax
8010043c:	89 f2                	mov    %esi,%edx
8010043e:	ee                   	out    %al,(%dx)
  outb(CRTPORT+1, pos>>8);
8010043f:	89 d8                	mov    %ebx,%eax
80100441:	c1 f8 08             	sar    $0x8,%eax
80100444:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
80100449:	89 ca                	mov    %ecx,%edx
8010044b:	ee                   	out    %al,(%dx)
8010044c:	b8 0f 00 00 00       	mov    $0xf,%eax
80100451:	89 f2                	mov    %esi,%edx
80100453:	ee                   	out    %al,(%dx)
80100454:	89 d8                	mov    %ebx,%eax
80100456:	89 ca                	mov    %ecx,%edx
80100458:	ee                   	out    %al,(%dx)
  crt[pos] = ' ' | 0x0700;
80100459:	66 c7 84 1b 00 80 0b 	movw   $0x720,-0x7ff48000(%ebx,%ebx,1)
80100460:	80 20 07 
}
80100463:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100466:	5b                   	pop    %ebx
80100467:	5e                   	pop    %esi
80100468:	5f                   	pop    %edi
80100469:	5d                   	pop    %ebp
8010046a:	c3                   	ret    
    pos += 80 - pos%80;
8010046b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100470:	89 c8                	mov    %ecx,%eax
80100472:	f7 ea                	imul   %edx
80100474:	c1 fa 05             	sar    $0x5,%edx
80100477:	8d 14 92             	lea    (%edx,%edx,4),%edx
8010047a:	89 d0                	mov    %edx,%eax
8010047c:	c1 e0 04             	shl    $0x4,%eax
8010047f:	89 ca                	mov    %ecx,%edx
80100481:	29 c2                	sub    %eax,%edx
80100483:	bb 50 00 00 00       	mov    $0x50,%ebx
80100488:	29 d3                	sub    %edx,%ebx
8010048a:	01 cb                	add    %ecx,%ebx
8010048c:	eb 94                	jmp    80100422 <cgaputc+0x5c>
    if(pos > 0) --pos;
8010048e:	85 c9                	test   %ecx,%ecx
80100490:	7e 05                	jle    80100497 <cgaputc+0xd1>
80100492:	8d 59 ff             	lea    -0x1(%ecx),%ebx
80100495:	eb 8b                	jmp    80100422 <cgaputc+0x5c>
  pos |= inb(CRTPORT+1);
80100497:	89 cb                	mov    %ecx,%ebx
80100499:	eb 87                	jmp    80100422 <cgaputc+0x5c>
    panic("pos under/overflow");
8010049b:	83 ec 0c             	sub    $0xc,%esp
8010049e:	68 25 67 10 80       	push   $0x80106725
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 2b 3a 00 00       	call   80103eea <memmove>
    pos -= 80;
801004bf:	83 eb 50             	sub    $0x50,%ebx
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801004c2:	b8 80 07 00 00       	mov    $0x780,%eax
801004c7:	29 d8                	sub    %ebx,%eax
801004c9:	8d 94 1b 00 80 0b 80 	lea    -0x7ff48000(%ebx,%ebx,1),%edx
801004d0:	83 c4 0c             	add    $0xc,%esp
801004d3:	01 c0                	add    %eax,%eax
801004d5:	50                   	push   %eax
801004d6:	6a 00                	push   $0x0
801004d8:	52                   	push   %edx
801004d9:	e8 91 39 00 00       	call   80103e6f <memset>
801004de:	83 c4 10             	add    $0x10,%esp
801004e1:	e9 4c ff ff ff       	jmp    80100432 <cgaputc+0x6c>

801004e6 <consputc>:
  if(panicked){
801004e6:	83 3d 58 a5 10 80 00 	cmpl   $0x0,0x8010a558
801004ed:	74 03                	je     801004f2 <consputc+0xc>
  asm volatile("cli");
801004ef:	fa                   	cli    
801004f0:	eb fe                	jmp    801004f0 <consputc+0xa>
{
801004f2:	55                   	push   %ebp
801004f3:	89 e5                	mov    %esp,%ebp
801004f5:	53                   	push   %ebx
801004f6:	83 ec 04             	sub    $0x4,%esp
801004f9:	89 c3                	mov    %eax,%ebx
  if(c == BACKSPACE){
801004fb:	3d 00 01 00 00       	cmp    $0x100,%eax
80100500:	74 18                	je     8010051a <consputc+0x34>
    uartputc(c);
80100502:	83 ec 0c             	sub    $0xc,%esp
80100505:	50                   	push   %eax
80100506:	e8 9e 4d 00 00       	call   801052a9 <uartputc>
8010050b:	83 c4 10             	add    $0x10,%esp
  cgaputc(c);
8010050e:	89 d8                	mov    %ebx,%eax
80100510:	e8 b1 fe ff ff       	call   801003c6 <cgaputc>
}
80100515:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100518:	c9                   	leave  
80100519:	c3                   	ret    
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010051a:	83 ec 0c             	sub    $0xc,%esp
8010051d:	6a 08                	push   $0x8
8010051f:	e8 85 4d 00 00       	call   801052a9 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 79 4d 00 00       	call   801052a9 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 6d 4d 00 00       	call   801052a9 <uartputc>
8010053c:	83 c4 10             	add    $0x10,%esp
8010053f:	eb cd                	jmp    8010050e <consputc+0x28>

80100541 <printint>:
{
80100541:	55                   	push   %ebp
80100542:	89 e5                	mov    %esp,%ebp
80100544:	57                   	push   %edi
80100545:	56                   	push   %esi
80100546:	53                   	push   %ebx
80100547:	83 ec 1c             	sub    $0x1c,%esp
8010054a:	89 d7                	mov    %edx,%edi
  if(sign && (sign = xx < 0))
8010054c:	85 c9                	test   %ecx,%ecx
8010054e:	74 09                	je     80100559 <printint+0x18>
80100550:	89 c1                	mov    %eax,%ecx
80100552:	c1 e9 1f             	shr    $0x1f,%ecx
80100555:	85 c0                	test   %eax,%eax
80100557:	78 09                	js     80100562 <printint+0x21>
    x = xx;
80100559:	89 c2                	mov    %eax,%edx
  i = 0;
8010055b:	be 00 00 00 00       	mov    $0x0,%esi
80100560:	eb 08                	jmp    8010056a <printint+0x29>
    x = -xx;
80100562:	f7 d8                	neg    %eax
80100564:	89 c2                	mov    %eax,%edx
80100566:	eb f3                	jmp    8010055b <printint+0x1a>
    buf[i++] = digits[x % base];
80100568:	89 de                	mov    %ebx,%esi
8010056a:	89 d0                	mov    %edx,%eax
8010056c:	ba 00 00 00 00       	mov    $0x0,%edx
80100571:	f7 f7                	div    %edi
80100573:	8d 5e 01             	lea    0x1(%esi),%ebx
80100576:	0f b6 92 50 67 10 80 	movzbl -0x7fef98b0(%edx),%edx
8010057d:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
80100581:	89 c2                	mov    %eax,%edx
80100583:	85 c0                	test   %eax,%eax
80100585:	75 e1                	jne    80100568 <printint+0x27>
  if(sign)
80100587:	85 c9                	test   %ecx,%ecx
80100589:	74 14                	je     8010059f <printint+0x5e>
    buf[i++] = '-';
8010058b:	c6 44 1d d8 2d       	movb   $0x2d,-0x28(%ebp,%ebx,1)
80100590:	8d 5e 02             	lea    0x2(%esi),%ebx
80100593:	eb 0a                	jmp    8010059f <printint+0x5e>
    consputc(buf[i]);
80100595:	0f be 44 1d d8       	movsbl -0x28(%ebp,%ebx,1),%eax
8010059a:	e8 47 ff ff ff       	call   801004e6 <consputc>
  while(--i >= 0)
8010059f:	83 eb 01             	sub    $0x1,%ebx
801005a2:	79 f1                	jns    80100595 <printint+0x54>
}
801005a4:	83 c4 1c             	add    $0x1c,%esp
801005a7:	5b                   	pop    %ebx
801005a8:	5e                   	pop    %esi
801005a9:	5f                   	pop    %edi
801005aa:	5d                   	pop    %ebp
801005ab:	c3                   	ret    

801005ac <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
801005ac:	55                   	push   %ebp
801005ad:	89 e5                	mov    %esp,%ebp
801005af:	57                   	push   %edi
801005b0:	56                   	push   %esi
801005b1:	53                   	push   %ebx
801005b2:	83 ec 18             	sub    $0x18,%esp
801005b5:	8b 7d 0c             	mov    0xc(%ebp),%edi
801005b8:	8b 75 10             	mov    0x10(%ebp),%esi
  int i;

  iunlock(ip);
801005bb:	ff 75 08             	pushl  0x8(%ebp)
801005be:	e8 80 10 00 00       	call   80101643 <iunlock>
  acquire(&cons.lock);
801005c3:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
801005ca:	e8 f4 37 00 00       	call   80103dc3 <acquire>
  for(i = 0; i < n; i++)
801005cf:	83 c4 10             	add    $0x10,%esp
801005d2:	bb 00 00 00 00       	mov    $0x0,%ebx
801005d7:	eb 0c                	jmp    801005e5 <consolewrite+0x39>
    consputc(buf[i] & 0xff);
801005d9:	0f b6 04 1f          	movzbl (%edi,%ebx,1),%eax
801005dd:	e8 04 ff ff ff       	call   801004e6 <consputc>
  for(i = 0; i < n; i++)
801005e2:	83 c3 01             	add    $0x1,%ebx
801005e5:	39 f3                	cmp    %esi,%ebx
801005e7:	7c f0                	jl     801005d9 <consolewrite+0x2d>
  release(&cons.lock);
801005e9:	83 ec 0c             	sub    $0xc,%esp
801005ec:	68 20 a5 10 80       	push   $0x8010a520
801005f1:	e8 32 38 00 00       	call   80103e28 <release>
  ilock(ip);
801005f6:	83 c4 04             	add    $0x4,%esp
801005f9:	ff 75 08             	pushl  0x8(%ebp)
801005fc:	e8 80 0f 00 00       	call   80101581 <ilock>

  return n;
}
80100601:	89 f0                	mov    %esi,%eax
80100603:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100606:	5b                   	pop    %ebx
80100607:	5e                   	pop    %esi
80100608:	5f                   	pop    %edi
80100609:	5d                   	pop    %ebp
8010060a:	c3                   	ret    

8010060b <cprintf>:
{
8010060b:	55                   	push   %ebp
8010060c:	89 e5                	mov    %esp,%ebp
8010060e:	57                   	push   %edi
8010060f:	56                   	push   %esi
80100610:	53                   	push   %ebx
80100611:	83 ec 1c             	sub    $0x1c,%esp
  locking = cons.locking;
80100614:	a1 54 a5 10 80       	mov    0x8010a554,%eax
80100619:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  if(locking)
8010061c:	85 c0                	test   %eax,%eax
8010061e:	75 10                	jne    80100630 <cprintf+0x25>
  if (fmt == 0)
80100620:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80100624:	74 1c                	je     80100642 <cprintf+0x37>
  argp = (uint*)(void*)(&fmt + 1);
80100626:	8d 7d 0c             	lea    0xc(%ebp),%edi
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100629:	bb 00 00 00 00       	mov    $0x0,%ebx
8010062e:	eb 27                	jmp    80100657 <cprintf+0x4c>
    acquire(&cons.lock);
80100630:	83 ec 0c             	sub    $0xc,%esp
80100633:	68 20 a5 10 80       	push   $0x8010a520
80100638:	e8 86 37 00 00       	call   80103dc3 <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 3f 67 10 80       	push   $0x8010673f
8010064a:	e8 f9 fc ff ff       	call   80100348 <panic>
      consputc(c);
8010064f:	e8 92 fe ff ff       	call   801004e6 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100654:	83 c3 01             	add    $0x1,%ebx
80100657:	8b 55 08             	mov    0x8(%ebp),%edx
8010065a:	0f b6 04 1a          	movzbl (%edx,%ebx,1),%eax
8010065e:	85 c0                	test   %eax,%eax
80100660:	0f 84 b8 00 00 00    	je     8010071e <cprintf+0x113>
    if(c != '%'){
80100666:	83 f8 25             	cmp    $0x25,%eax
80100669:	75 e4                	jne    8010064f <cprintf+0x44>
    c = fmt[++i] & 0xff;
8010066b:	83 c3 01             	add    $0x1,%ebx
8010066e:	0f b6 34 1a          	movzbl (%edx,%ebx,1),%esi
    if(c == 0)
80100672:	85 f6                	test   %esi,%esi
80100674:	0f 84 a4 00 00 00    	je     8010071e <cprintf+0x113>
    switch(c){
8010067a:	83 fe 70             	cmp    $0x70,%esi
8010067d:	74 48                	je     801006c7 <cprintf+0xbc>
8010067f:	83 fe 70             	cmp    $0x70,%esi
80100682:	7f 26                	jg     801006aa <cprintf+0x9f>
80100684:	83 fe 25             	cmp    $0x25,%esi
80100687:	0f 84 82 00 00 00    	je     8010070f <cprintf+0x104>
8010068d:	83 fe 64             	cmp    $0x64,%esi
80100690:	75 22                	jne    801006b4 <cprintf+0xa9>
      printint(*argp++, 10, 1);
80100692:	8d 77 04             	lea    0x4(%edi),%esi
80100695:	8b 07                	mov    (%edi),%eax
80100697:	b9 01 00 00 00       	mov    $0x1,%ecx
8010069c:	ba 0a 00 00 00       	mov    $0xa,%edx
801006a1:	e8 9b fe ff ff       	call   80100541 <printint>
801006a6:	89 f7                	mov    %esi,%edi
      break;
801006a8:	eb aa                	jmp    80100654 <cprintf+0x49>
    switch(c){
801006aa:	83 fe 73             	cmp    $0x73,%esi
801006ad:	74 33                	je     801006e2 <cprintf+0xd7>
801006af:	83 fe 78             	cmp    $0x78,%esi
801006b2:	74 13                	je     801006c7 <cprintf+0xbc>
      consputc('%');
801006b4:	b8 25 00 00 00       	mov    $0x25,%eax
801006b9:	e8 28 fe ff ff       	call   801004e6 <consputc>
      consputc(c);
801006be:	89 f0                	mov    %esi,%eax
801006c0:	e8 21 fe ff ff       	call   801004e6 <consputc>
      break;
801006c5:	eb 8d                	jmp    80100654 <cprintf+0x49>
      printint(*argp++, 16, 0);
801006c7:	8d 77 04             	lea    0x4(%edi),%esi
801006ca:	8b 07                	mov    (%edi),%eax
801006cc:	b9 00 00 00 00       	mov    $0x0,%ecx
801006d1:	ba 10 00 00 00       	mov    $0x10,%edx
801006d6:	e8 66 fe ff ff       	call   80100541 <printint>
801006db:	89 f7                	mov    %esi,%edi
      break;
801006dd:	e9 72 ff ff ff       	jmp    80100654 <cprintf+0x49>
      if((s = (char*)*argp++) == 0)
801006e2:	8d 47 04             	lea    0x4(%edi),%eax
801006e5:	89 45 e0             	mov    %eax,-0x20(%ebp)
801006e8:	8b 37                	mov    (%edi),%esi
801006ea:	85 f6                	test   %esi,%esi
801006ec:	75 12                	jne    80100700 <cprintf+0xf5>
        s = "(null)";
801006ee:	be 38 67 10 80       	mov    $0x80106738,%esi
801006f3:	eb 0b                	jmp    80100700 <cprintf+0xf5>
        consputc(*s);
801006f5:	0f be c0             	movsbl %al,%eax
801006f8:	e8 e9 fd ff ff       	call   801004e6 <consputc>
      for(; *s; s++)
801006fd:	83 c6 01             	add    $0x1,%esi
80100700:	0f b6 06             	movzbl (%esi),%eax
80100703:	84 c0                	test   %al,%al
80100705:	75 ee                	jne    801006f5 <cprintf+0xea>
      if((s = (char*)*argp++) == 0)
80100707:	8b 7d e0             	mov    -0x20(%ebp),%edi
8010070a:	e9 45 ff ff ff       	jmp    80100654 <cprintf+0x49>
      consputc('%');
8010070f:	b8 25 00 00 00       	mov    $0x25,%eax
80100714:	e8 cd fd ff ff       	call   801004e6 <consputc>
      break;
80100719:	e9 36 ff ff ff       	jmp    80100654 <cprintf+0x49>
  if(locking)
8010071e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100722:	75 08                	jne    8010072c <cprintf+0x121>
}
80100724:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100727:	5b                   	pop    %ebx
80100728:	5e                   	pop    %esi
80100729:	5f                   	pop    %edi
8010072a:	5d                   	pop    %ebp
8010072b:	c3                   	ret    
    release(&cons.lock);
8010072c:	83 ec 0c             	sub    $0xc,%esp
8010072f:	68 20 a5 10 80       	push   $0x8010a520
80100734:	e8 ef 36 00 00       	call   80103e28 <release>
80100739:	83 c4 10             	add    $0x10,%esp
}
8010073c:	eb e6                	jmp    80100724 <cprintf+0x119>

8010073e <consoleintr>:
{
8010073e:	55                   	push   %ebp
8010073f:	89 e5                	mov    %esp,%ebp
80100741:	57                   	push   %edi
80100742:	56                   	push   %esi
80100743:	53                   	push   %ebx
80100744:	83 ec 18             	sub    $0x18,%esp
80100747:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&cons.lock);
8010074a:	68 20 a5 10 80       	push   $0x8010a520
8010074f:	e8 6f 36 00 00       	call   80103dc3 <acquire>
  while((c = getc()) >= 0){
80100754:	83 c4 10             	add    $0x10,%esp
  int c, doprocdump = 0;
80100757:	be 00 00 00 00       	mov    $0x0,%esi
  while((c = getc()) >= 0){
8010075c:	e9 c5 00 00 00       	jmp    80100826 <consoleintr+0xe8>
    switch(c){
80100761:	83 ff 08             	cmp    $0x8,%edi
80100764:	0f 84 e0 00 00 00    	je     8010084a <consoleintr+0x10c>
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010076a:	85 ff                	test   %edi,%edi
8010076c:	0f 84 b4 00 00 00    	je     80100826 <consoleintr+0xe8>
80100772:	a1 a8 ff 10 80       	mov    0x8010ffa8,%eax
80100777:	89 c2                	mov    %eax,%edx
80100779:	2b 15 a0 ff 10 80    	sub    0x8010ffa0,%edx
8010077f:	83 fa 7f             	cmp    $0x7f,%edx
80100782:	0f 87 9e 00 00 00    	ja     80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100788:	83 ff 0d             	cmp    $0xd,%edi
8010078b:	0f 84 86 00 00 00    	je     80100817 <consoleintr+0xd9>
        input.buf[input.e++ % INPUT_BUF] = c;
80100791:	8d 50 01             	lea    0x1(%eax),%edx
80100794:	89 15 a8 ff 10 80    	mov    %edx,0x8010ffa8
8010079a:	83 e0 7f             	and    $0x7f,%eax
8010079d:	89 f9                	mov    %edi,%ecx
8010079f:	88 88 20 ff 10 80    	mov    %cl,-0x7fef00e0(%eax)
        consputc(c);
801007a5:	89 f8                	mov    %edi,%eax
801007a7:	e8 3a fd ff ff       	call   801004e6 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801007ac:	83 ff 0a             	cmp    $0xa,%edi
801007af:	0f 94 c2             	sete   %dl
801007b2:	83 ff 04             	cmp    $0x4,%edi
801007b5:	0f 94 c0             	sete   %al
801007b8:	08 c2                	or     %al,%dl
801007ba:	75 10                	jne    801007cc <consoleintr+0x8e>
801007bc:	a1 a0 ff 10 80       	mov    0x8010ffa0,%eax
801007c1:	83 e8 80             	sub    $0xffffff80,%eax
801007c4:	39 05 a8 ff 10 80    	cmp    %eax,0x8010ffa8
801007ca:	75 5a                	jne    80100826 <consoleintr+0xe8>
          input.w = input.e;
801007cc:	a1 a8 ff 10 80       	mov    0x8010ffa8,%eax
801007d1:	a3 a4 ff 10 80       	mov    %eax,0x8010ffa4
          wakeup(&input.r);
801007d6:	83 ec 0c             	sub    $0xc,%esp
801007d9:	68 a0 ff 10 80       	push   $0x8010ffa0
801007de:	e8 cb 31 00 00       	call   801039ae <wakeup>
801007e3:	83 c4 10             	add    $0x10,%esp
801007e6:	eb 3e                	jmp    80100826 <consoleintr+0xe8>
        input.e--;
801007e8:	a3 a8 ff 10 80       	mov    %eax,0x8010ffa8
        consputc(BACKSPACE);
801007ed:	b8 00 01 00 00       	mov    $0x100,%eax
801007f2:	e8 ef fc ff ff       	call   801004e6 <consputc>
      while(input.e != input.w &&
801007f7:	a1 a8 ff 10 80       	mov    0x8010ffa8,%eax
801007fc:	3b 05 a4 ff 10 80    	cmp    0x8010ffa4,%eax
80100802:	74 22                	je     80100826 <consoleintr+0xe8>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100804:	83 e8 01             	sub    $0x1,%eax
80100807:	89 c2                	mov    %eax,%edx
80100809:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010080c:	80 ba 20 ff 10 80 0a 	cmpb   $0xa,-0x7fef00e0(%edx)
80100813:	75 d3                	jne    801007e8 <consoleintr+0xaa>
80100815:	eb 0f                	jmp    80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100817:	bf 0a 00 00 00       	mov    $0xa,%edi
8010081c:	e9 70 ff ff ff       	jmp    80100791 <consoleintr+0x53>
      doprocdump = 1;
80100821:	be 01 00 00 00       	mov    $0x1,%esi
  while((c = getc()) >= 0){
80100826:	ff d3                	call   *%ebx
80100828:	89 c7                	mov    %eax,%edi
8010082a:	85 c0                	test   %eax,%eax
8010082c:	78 3d                	js     8010086b <consoleintr+0x12d>
    switch(c){
8010082e:	83 ff 10             	cmp    $0x10,%edi
80100831:	74 ee                	je     80100821 <consoleintr+0xe3>
80100833:	83 ff 10             	cmp    $0x10,%edi
80100836:	0f 8e 25 ff ff ff    	jle    80100761 <consoleintr+0x23>
8010083c:	83 ff 15             	cmp    $0x15,%edi
8010083f:	74 b6                	je     801007f7 <consoleintr+0xb9>
80100841:	83 ff 7f             	cmp    $0x7f,%edi
80100844:	0f 85 20 ff ff ff    	jne    8010076a <consoleintr+0x2c>
      if(input.e != input.w){
8010084a:	a1 a8 ff 10 80       	mov    0x8010ffa8,%eax
8010084f:	3b 05 a4 ff 10 80    	cmp    0x8010ffa4,%eax
80100855:	74 cf                	je     80100826 <consoleintr+0xe8>
        input.e--;
80100857:	83 e8 01             	sub    $0x1,%eax
8010085a:	a3 a8 ff 10 80       	mov    %eax,0x8010ffa8
        consputc(BACKSPACE);
8010085f:	b8 00 01 00 00       	mov    $0x100,%eax
80100864:	e8 7d fc ff ff       	call   801004e6 <consputc>
80100869:	eb bb                	jmp    80100826 <consoleintr+0xe8>
  release(&cons.lock);
8010086b:	83 ec 0c             	sub    $0xc,%esp
8010086e:	68 20 a5 10 80       	push   $0x8010a520
80100873:	e8 b0 35 00 00       	call   80103e28 <release>
  if(doprocdump) {
80100878:	83 c4 10             	add    $0x10,%esp
8010087b:	85 f6                	test   %esi,%esi
8010087d:	75 08                	jne    80100887 <consoleintr+0x149>
}
8010087f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100882:	5b                   	pop    %ebx
80100883:	5e                   	pop    %esi
80100884:	5f                   	pop    %edi
80100885:	5d                   	pop    %ebp
80100886:	c3                   	ret    
    procdump();  // now call procdump() wo. cons.lock held
80100887:	e8 bf 31 00 00       	call   80103a4b <procdump>
}
8010088c:	eb f1                	jmp    8010087f <consoleintr+0x141>

8010088e <consoleinit>:

void
consoleinit(void)
{
8010088e:	55                   	push   %ebp
8010088f:	89 e5                	mov    %esp,%ebp
80100891:	83 ec 10             	sub    $0x10,%esp
  initlock(&cons.lock, "console");
80100894:	68 48 67 10 80       	push   $0x80106748
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 e4 33 00 00       	call   80103c87 <initlock>

  devsw[CONSOLE].write = consolewrite;
801008a3:	c7 05 6c 09 11 80 ac 	movl   $0x801005ac,0x8011096c
801008aa:	05 10 80 
  devsw[CONSOLE].read = consoleread;
801008ad:	c7 05 68 09 11 80 68 	movl   $0x80100268,0x80110968
801008b4:	02 10 80 
  cons.locking = 1;
801008b7:	c7 05 54 a5 10 80 01 	movl   $0x1,0x8010a554
801008be:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
801008c1:	83 c4 08             	add    $0x8,%esp
801008c4:	6a 00                	push   $0x0
801008c6:	6a 01                	push   $0x1
801008c8:	e8 b1 16 00 00       	call   80101f7e <ioapicenable>
}
801008cd:	83 c4 10             	add    $0x10,%esp
801008d0:	c9                   	leave  
801008d1:	c3                   	ret    

801008d2 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
801008d2:	55                   	push   %ebp
801008d3:	89 e5                	mov    %esp,%ebp
801008d5:	57                   	push   %edi
801008d6:	56                   	push   %esi
801008d7:	53                   	push   %ebx
801008d8:	81 ec 0c 01 00 00    	sub    $0x10c,%esp
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();
801008de:	e8 c2 2a 00 00       	call   801033a5 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 56 20 00 00       	call   80102944 <begin_op>

  if((ip = namei(path)) == 0){
801008ee:	83 ec 0c             	sub    $0xc,%esp
801008f1:	ff 75 08             	pushl  0x8(%ebp)
801008f4:	e8 e8 12 00 00       	call   80101be1 <namei>
801008f9:	83 c4 10             	add    $0x10,%esp
801008fc:	85 c0                	test   %eax,%eax
801008fe:	74 4a                	je     8010094a <exec+0x78>
80100900:	89 c3                	mov    %eax,%ebx
    end_op();
    cprintf("exec: fail\n");
    return -1;
  }
  ilock(ip);
80100902:	83 ec 0c             	sub    $0xc,%esp
80100905:	50                   	push   %eax
80100906:	e8 76 0c 00 00       	call   80101581 <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
8010090b:	6a 34                	push   $0x34
8010090d:	6a 00                	push   $0x0
8010090f:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
80100915:	50                   	push   %eax
80100916:	53                   	push   %ebx
80100917:	e8 57 0e 00 00       	call   80101773 <readi>
8010091c:	83 c4 20             	add    $0x20,%esp
8010091f:	83 f8 34             	cmp    $0x34,%eax
80100922:	74 42                	je     80100966 <exec+0x94>
  return 0;

 bad:
  if(pgdir)
    freevm(pgdir);
  if(ip){
80100924:	85 db                	test   %ebx,%ebx
80100926:	0f 84 dd 02 00 00    	je     80100c09 <exec+0x337>
    iunlockput(ip);
8010092c:	83 ec 0c             	sub    $0xc,%esp
8010092f:	53                   	push   %ebx
80100930:	e8 f3 0d 00 00       	call   80101728 <iunlockput>
    end_op();
80100935:	e8 84 20 00 00       	call   801029be <end_op>
8010093a:	83 c4 10             	add    $0x10,%esp
  }
  return -1;
8010093d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100942:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100945:	5b                   	pop    %ebx
80100946:	5e                   	pop    %esi
80100947:	5f                   	pop    %edi
80100948:	5d                   	pop    %ebp
80100949:	c3                   	ret    
    end_op();
8010094a:	e8 6f 20 00 00       	call   801029be <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 61 67 10 80       	push   $0x80106761
80100957:	e8 af fc ff ff       	call   8010060b <cprintf>
    return -1;
8010095c:	83 c4 10             	add    $0x10,%esp
8010095f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100964:	eb dc                	jmp    80100942 <exec+0x70>
  if(elf.magic != ELF_MAGIC)
80100966:	81 bd 24 ff ff ff 7f 	cmpl   $0x464c457f,-0xdc(%ebp)
8010096d:	45 4c 46 
80100970:	75 b2                	jne    80100924 <exec+0x52>
  if((pgdir = setupkvm()) == 0)
80100972:	e8 0b 5b 00 00       	call   80106482 <setupkvm>
80100977:	89 85 ec fe ff ff    	mov    %eax,-0x114(%ebp)
8010097d:	85 c0                	test   %eax,%eax
8010097f:	0f 84 06 01 00 00    	je     80100a8b <exec+0x1b9>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100985:	8b 85 40 ff ff ff    	mov    -0xc0(%ebp),%eax
  sz = 0;
8010098b:	bf 00 00 00 00       	mov    $0x0,%edi
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100990:	be 00 00 00 00       	mov    $0x0,%esi
80100995:	eb 0c                	jmp    801009a3 <exec+0xd1>
80100997:	83 c6 01             	add    $0x1,%esi
8010099a:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
801009a0:	83 c0 20             	add    $0x20,%eax
801009a3:	0f b7 95 50 ff ff ff 	movzwl -0xb0(%ebp),%edx
801009aa:	39 f2                	cmp    %esi,%edx
801009ac:	0f 8e 98 00 00 00    	jle    80100a4a <exec+0x178>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
801009b2:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
801009b8:	6a 20                	push   $0x20
801009ba:	50                   	push   %eax
801009bb:	8d 85 04 ff ff ff    	lea    -0xfc(%ebp),%eax
801009c1:	50                   	push   %eax
801009c2:	53                   	push   %ebx
801009c3:	e8 ab 0d 00 00       	call   80101773 <readi>
801009c8:	83 c4 10             	add    $0x10,%esp
801009cb:	83 f8 20             	cmp    $0x20,%eax
801009ce:	0f 85 b7 00 00 00    	jne    80100a8b <exec+0x1b9>
    if(ph.type != ELF_PROG_LOAD)
801009d4:	83 bd 04 ff ff ff 01 	cmpl   $0x1,-0xfc(%ebp)
801009db:	75 ba                	jne    80100997 <exec+0xc5>
    if(ph.memsz < ph.filesz)
801009dd:	8b 85 18 ff ff ff    	mov    -0xe8(%ebp),%eax
801009e3:	3b 85 14 ff ff ff    	cmp    -0xec(%ebp),%eax
801009e9:	0f 82 9c 00 00 00    	jb     80100a8b <exec+0x1b9>
    if(ph.vaddr + ph.memsz < ph.vaddr)
801009ef:	03 85 0c ff ff ff    	add    -0xf4(%ebp),%eax
801009f5:	0f 82 90 00 00 00    	jb     80100a8b <exec+0x1b9>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
801009fb:	83 ec 04             	sub    $0x4,%esp
801009fe:	50                   	push   %eax
801009ff:	57                   	push   %edi
80100a00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a06:	e8 04 59 00 00       	call   8010630f <allocuvm>
80100a0b:	89 c7                	mov    %eax,%edi
80100a0d:	83 c4 10             	add    $0x10,%esp
80100a10:	85 c0                	test   %eax,%eax
80100a12:	74 77                	je     80100a8b <exec+0x1b9>
    if(ph.vaddr % PGSIZE != 0)
80100a14:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100a1a:	a9 ff 0f 00 00       	test   $0xfff,%eax
80100a1f:	75 6a                	jne    80100a8b <exec+0x1b9>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100a21:	83 ec 0c             	sub    $0xc,%esp
80100a24:	ff b5 14 ff ff ff    	pushl  -0xec(%ebp)
80100a2a:	ff b5 08 ff ff ff    	pushl  -0xf8(%ebp)
80100a30:	53                   	push   %ebx
80100a31:	50                   	push   %eax
80100a32:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a38:	e8 a0 57 00 00       	call   801061dd <loaduvm>
80100a3d:	83 c4 20             	add    $0x20,%esp
80100a40:	85 c0                	test   %eax,%eax
80100a42:	0f 89 4f ff ff ff    	jns    80100997 <exec+0xc5>
 bad:
80100a48:	eb 41                	jmp    80100a8b <exec+0x1b9>
  iunlockput(ip);
80100a4a:	83 ec 0c             	sub    $0xc,%esp
80100a4d:	53                   	push   %ebx
80100a4e:	e8 d5 0c 00 00       	call   80101728 <iunlockput>
  end_op();
80100a53:	e8 66 1f 00 00       	call   801029be <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 96 58 00 00       	call   8010630f <allocuvm>
80100a79:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
80100a7f:	83 c4 10             	add    $0x10,%esp
80100a82:	85 c0                	test   %eax,%eax
80100a84:	75 24                	jne    80100aaa <exec+0x1d8>
  ip = 0;
80100a86:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(pgdir)
80100a8b:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100a91:	85 c0                	test   %eax,%eax
80100a93:	0f 84 8b fe ff ff    	je     80100924 <exec+0x52>
    freevm(pgdir);
80100a99:	83 ec 0c             	sub    $0xc,%esp
80100a9c:	50                   	push   %eax
80100a9d:	e8 70 59 00 00       	call   80106412 <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 46 5a 00 00       	call   80106507 <clearpteu>
  for(argc = 0; argv[argc]; argc++) {
80100ac1:	83 c4 10             	add    $0x10,%esp
80100ac4:	bb 00 00 00 00       	mov    $0x0,%ebx
80100ac9:	8b 45 0c             	mov    0xc(%ebp),%eax
80100acc:	8d 34 98             	lea    (%eax,%ebx,4),%esi
80100acf:	8b 06                	mov    (%esi),%eax
80100ad1:	85 c0                	test   %eax,%eax
80100ad3:	74 4d                	je     80100b22 <exec+0x250>
    if(argc >= MAXARG)
80100ad5:	83 fb 1f             	cmp    $0x1f,%ebx
80100ad8:	0f 87 0d 01 00 00    	ja     80100beb <exec+0x319>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100ade:	83 ec 0c             	sub    $0xc,%esp
80100ae1:	50                   	push   %eax
80100ae2:	e8 2a 35 00 00       	call   80104011 <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 18 35 00 00       	call   80104011 <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 58 5b 00 00       	call   80106663 <copyout>
80100b0b:	83 c4 20             	add    $0x20,%esp
80100b0e:	85 c0                	test   %eax,%eax
80100b10:	0f 88 df 00 00 00    	js     80100bf5 <exec+0x323>
    ustack[3+argc] = sp;
80100b16:	89 bc 9d 64 ff ff ff 	mov    %edi,-0x9c(%ebp,%ebx,4)
  for(argc = 0; argv[argc]; argc++) {
80100b1d:	83 c3 01             	add    $0x1,%ebx
80100b20:	eb a7                	jmp    80100ac9 <exec+0x1f7>
  ustack[3+argc] = 0;
80100b22:	c7 84 9d 64 ff ff ff 	movl   $0x0,-0x9c(%ebp,%ebx,4)
80100b29:	00 00 00 00 
  ustack[0] = 0xffffffff;  // fake return PC
80100b2d:	c7 85 58 ff ff ff ff 	movl   $0xffffffff,-0xa8(%ebp)
80100b34:	ff ff ff 
  ustack[1] = argc;
80100b37:	89 9d 5c ff ff ff    	mov    %ebx,-0xa4(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100b3d:	8d 04 9d 04 00 00 00 	lea    0x4(,%ebx,4),%eax
80100b44:	89 f9                	mov    %edi,%ecx
80100b46:	29 c1                	sub    %eax,%ecx
80100b48:	89 8d 60 ff ff ff    	mov    %ecx,-0xa0(%ebp)
  sp -= (3+argc+1) * 4;
80100b4e:	8d 04 9d 10 00 00 00 	lea    0x10(,%ebx,4),%eax
80100b55:	29 c7                	sub    %eax,%edi
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100b57:	50                   	push   %eax
80100b58:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
80100b5e:	50                   	push   %eax
80100b5f:	57                   	push   %edi
80100b60:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b66:	e8 f8 5a 00 00       	call   80106663 <copyout>
80100b6b:	83 c4 10             	add    $0x10,%esp
80100b6e:	85 c0                	test   %eax,%eax
80100b70:	0f 88 89 00 00 00    	js     80100bff <exec+0x32d>
  for(last=s=path; *s; s++)
80100b76:	8b 55 08             	mov    0x8(%ebp),%edx
80100b79:	89 d0                	mov    %edx,%eax
80100b7b:	eb 03                	jmp    80100b80 <exec+0x2ae>
80100b7d:	83 c0 01             	add    $0x1,%eax
80100b80:	0f b6 08             	movzbl (%eax),%ecx
80100b83:	84 c9                	test   %cl,%cl
80100b85:	74 0a                	je     80100b91 <exec+0x2bf>
    if(*s == '/')
80100b87:	80 f9 2f             	cmp    $0x2f,%cl
80100b8a:	75 f1                	jne    80100b7d <exec+0x2ab>
      last = s+1;
80100b8c:	8d 50 01             	lea    0x1(%eax),%edx
80100b8f:	eb ec                	jmp    80100b7d <exec+0x2ab>
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100b91:	8b b5 f4 fe ff ff    	mov    -0x10c(%ebp),%esi
80100b97:	89 f0                	mov    %esi,%eax
80100b99:	83 c0 6c             	add    $0x6c,%eax
80100b9c:	83 ec 04             	sub    $0x4,%esp
80100b9f:	6a 10                	push   $0x10
80100ba1:	52                   	push   %edx
80100ba2:	50                   	push   %eax
80100ba3:	e8 2e 34 00 00       	call   80103fd6 <safestrcpy>
  oldpgdir = curproc->pgdir;
80100ba8:	8b 5e 04             	mov    0x4(%esi),%ebx
  curproc->pgdir = pgdir;
80100bab:	8b 8d ec fe ff ff    	mov    -0x114(%ebp),%ecx
80100bb1:	89 4e 04             	mov    %ecx,0x4(%esi)
  curproc->sz = sz;
80100bb4:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100bba:	89 0e                	mov    %ecx,(%esi)
  curproc->tf->eip = elf.entry;  // main
80100bbc:	8b 46 18             	mov    0x18(%esi),%eax
80100bbf:	8b 95 3c ff ff ff    	mov    -0xc4(%ebp),%edx
80100bc5:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100bc8:	8b 46 18             	mov    0x18(%esi),%eax
80100bcb:	89 78 44             	mov    %edi,0x44(%eax)
  switchuvm(curproc);
80100bce:	89 34 24             	mov    %esi,(%esp)
80100bd1:	e8 86 54 00 00       	call   8010605c <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 34 58 00 00       	call   80106412 <freevm>
  return 0;
80100bde:	83 c4 10             	add    $0x10,%esp
80100be1:	b8 00 00 00 00       	mov    $0x0,%eax
80100be6:	e9 57 fd ff ff       	jmp    80100942 <exec+0x70>
  ip = 0;
80100beb:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bf0:	e9 96 fe ff ff       	jmp    80100a8b <exec+0x1b9>
80100bf5:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bfa:	e9 8c fe ff ff       	jmp    80100a8b <exec+0x1b9>
80100bff:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c04:	e9 82 fe ff ff       	jmp    80100a8b <exec+0x1b9>
  return -1;
80100c09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100c0e:	e9 2f fd ff ff       	jmp    80100942 <exec+0x70>

80100c13 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100c13:	55                   	push   %ebp
80100c14:	89 e5                	mov    %esp,%ebp
80100c16:	83 ec 10             	sub    $0x10,%esp
  initlock(&ftable.lock, "ftable");
80100c19:	68 6d 67 10 80       	push   $0x8010676d
80100c1e:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c23:	e8 5f 30 00 00       	call   80103c87 <initlock>
}
80100c28:	83 c4 10             	add    $0x10,%esp
80100c2b:	c9                   	leave  
80100c2c:	c3                   	ret    

80100c2d <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100c2d:	55                   	push   %ebp
80100c2e:	89 e5                	mov    %esp,%ebp
80100c30:	53                   	push   %ebx
80100c31:	83 ec 10             	sub    $0x10,%esp
  struct file *f;

  acquire(&ftable.lock);
80100c34:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c39:	e8 85 31 00 00       	call   80103dc3 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c3e:	83 c4 10             	add    $0x10,%esp
80100c41:	bb f4 ff 10 80       	mov    $0x8010fff4,%ebx
80100c46:	81 fb 54 09 11 80    	cmp    $0x80110954,%ebx
80100c4c:	73 29                	jae    80100c77 <filealloc+0x4a>
    if(f->ref == 0){
80100c4e:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80100c52:	74 05                	je     80100c59 <filealloc+0x2c>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c54:	83 c3 18             	add    $0x18,%ebx
80100c57:	eb ed                	jmp    80100c46 <filealloc+0x19>
      f->ref = 1;
80100c59:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
80100c60:	83 ec 0c             	sub    $0xc,%esp
80100c63:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c68:	e8 bb 31 00 00       	call   80103e28 <release>
      return f;
80100c6d:	83 c4 10             	add    $0x10,%esp
    }
  }
  release(&ftable.lock);
  return 0;
}
80100c70:	89 d8                	mov    %ebx,%eax
80100c72:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100c75:	c9                   	leave  
80100c76:	c3                   	ret    
  release(&ftable.lock);
80100c77:	83 ec 0c             	sub    $0xc,%esp
80100c7a:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c7f:	e8 a4 31 00 00       	call   80103e28 <release>
  return 0;
80100c84:	83 c4 10             	add    $0x10,%esp
80100c87:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c8c:	eb e2                	jmp    80100c70 <filealloc+0x43>

80100c8e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100c8e:	55                   	push   %ebp
80100c8f:	89 e5                	mov    %esp,%ebp
80100c91:	53                   	push   %ebx
80100c92:	83 ec 10             	sub    $0x10,%esp
80100c95:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
80100c98:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c9d:	e8 21 31 00 00       	call   80103dc3 <acquire>
  if(f->ref < 1)
80100ca2:	8b 43 04             	mov    0x4(%ebx),%eax
80100ca5:	83 c4 10             	add    $0x10,%esp
80100ca8:	85 c0                	test   %eax,%eax
80100caa:	7e 1a                	jle    80100cc6 <filedup+0x38>
    panic("filedup");
  f->ref++;
80100cac:	83 c0 01             	add    $0x1,%eax
80100caf:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
80100cb2:	83 ec 0c             	sub    $0xc,%esp
80100cb5:	68 c0 ff 10 80       	push   $0x8010ffc0
80100cba:	e8 69 31 00 00       	call   80103e28 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 74 67 10 80       	push   $0x80106774
80100cce:	e8 75 f6 ff ff       	call   80100348 <panic>

80100cd3 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100cd3:	55                   	push   %ebp
80100cd4:	89 e5                	mov    %esp,%ebp
80100cd6:	53                   	push   %ebx
80100cd7:	83 ec 30             	sub    $0x30,%esp
80100cda:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct file ff;

  acquire(&ftable.lock);
80100cdd:	68 c0 ff 10 80       	push   $0x8010ffc0
80100ce2:	e8 dc 30 00 00       	call   80103dc3 <acquire>
  if(f->ref < 1)
80100ce7:	8b 43 04             	mov    0x4(%ebx),%eax
80100cea:	83 c4 10             	add    $0x10,%esp
80100ced:	85 c0                	test   %eax,%eax
80100cef:	7e 1f                	jle    80100d10 <fileclose+0x3d>
    panic("fileclose");
  if(--f->ref > 0){
80100cf1:	83 e8 01             	sub    $0x1,%eax
80100cf4:	89 43 04             	mov    %eax,0x4(%ebx)
80100cf7:	85 c0                	test   %eax,%eax
80100cf9:	7e 22                	jle    80100d1d <fileclose+0x4a>
    release(&ftable.lock);
80100cfb:	83 ec 0c             	sub    $0xc,%esp
80100cfe:	68 c0 ff 10 80       	push   $0x8010ffc0
80100d03:	e8 20 31 00 00       	call   80103e28 <release>
    return;
80100d08:	83 c4 10             	add    $0x10,%esp
  else if(ff.type == FD_INODE){
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
80100d0b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100d0e:	c9                   	leave  
80100d0f:	c3                   	ret    
    panic("fileclose");
80100d10:	83 ec 0c             	sub    $0xc,%esp
80100d13:	68 7c 67 10 80       	push   $0x8010677c
80100d18:	e8 2b f6 ff ff       	call   80100348 <panic>
  ff = *f;
80100d1d:	8b 03                	mov    (%ebx),%eax
80100d1f:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d22:	8b 43 08             	mov    0x8(%ebx),%eax
80100d25:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d28:	8b 43 0c             	mov    0xc(%ebx),%eax
80100d2b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100d2e:	8b 43 10             	mov    0x10(%ebx),%eax
80100d31:	89 45 f0             	mov    %eax,-0x10(%ebp)
  f->ref = 0;
80100d34:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
80100d3b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
80100d41:	83 ec 0c             	sub    $0xc,%esp
80100d44:	68 c0 ff 10 80       	push   $0x8010ffc0
80100d49:	e8 da 30 00 00       	call   80103e28 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 e1 1b 00 00       	call   80102944 <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 4b 1c 00 00       	call   801029be <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 43 22 00 00       	call   80102fcb <pipeclose>
80100d88:	83 c4 10             	add    $0x10,%esp
80100d8b:	e9 7b ff ff ff       	jmp    80100d0b <fileclose+0x38>

80100d90 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80100d90:	55                   	push   %ebp
80100d91:	89 e5                	mov    %esp,%ebp
80100d93:	53                   	push   %ebx
80100d94:	83 ec 04             	sub    $0x4,%esp
80100d97:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
80100d9a:	83 3b 02             	cmpl   $0x2,(%ebx)
80100d9d:	75 31                	jne    80100dd0 <filestat+0x40>
    ilock(f->ip);
80100d9f:	83 ec 0c             	sub    $0xc,%esp
80100da2:	ff 73 10             	pushl  0x10(%ebx)
80100da5:	e8 d7 07 00 00       	call   80101581 <ilock>
    stati(f->ip, st);
80100daa:	83 c4 08             	add    $0x8,%esp
80100dad:	ff 75 0c             	pushl  0xc(%ebp)
80100db0:	ff 73 10             	pushl  0x10(%ebx)
80100db3:	e8 90 09 00 00       	call   80101748 <stati>
    iunlock(f->ip);
80100db8:	83 c4 04             	add    $0x4,%esp
80100dbb:	ff 73 10             	pushl  0x10(%ebx)
80100dbe:	e8 80 08 00 00       	call   80101643 <iunlock>
    return 0;
80100dc3:	83 c4 10             	add    $0x10,%esp
80100dc6:	b8 00 00 00 00       	mov    $0x0,%eax
  }
  return -1;
}
80100dcb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100dce:	c9                   	leave  
80100dcf:	c3                   	ret    
  return -1;
80100dd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100dd5:	eb f4                	jmp    80100dcb <filestat+0x3b>

80100dd7 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80100dd7:	55                   	push   %ebp
80100dd8:	89 e5                	mov    %esp,%ebp
80100dda:	56                   	push   %esi
80100ddb:	53                   	push   %ebx
80100ddc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->readable == 0)
80100ddf:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
80100de3:	74 70                	je     80100e55 <fileread+0x7e>
    return -1;
  if(f->type == FD_PIPE)
80100de5:	8b 03                	mov    (%ebx),%eax
80100de7:	83 f8 01             	cmp    $0x1,%eax
80100dea:	74 44                	je     80100e30 <fileread+0x59>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100dec:	83 f8 02             	cmp    $0x2,%eax
80100def:	75 57                	jne    80100e48 <fileread+0x71>
    ilock(f->ip);
80100df1:	83 ec 0c             	sub    $0xc,%esp
80100df4:	ff 73 10             	pushl  0x10(%ebx)
80100df7:	e8 85 07 00 00       	call   80101581 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80100dfc:	ff 75 10             	pushl  0x10(%ebp)
80100dff:	ff 73 14             	pushl  0x14(%ebx)
80100e02:	ff 75 0c             	pushl  0xc(%ebp)
80100e05:	ff 73 10             	pushl  0x10(%ebx)
80100e08:	e8 66 09 00 00       	call   80101773 <readi>
80100e0d:	89 c6                	mov    %eax,%esi
80100e0f:	83 c4 20             	add    $0x20,%esp
80100e12:	85 c0                	test   %eax,%eax
80100e14:	7e 03                	jle    80100e19 <fileread+0x42>
      f->off += r;
80100e16:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
80100e19:	83 ec 0c             	sub    $0xc,%esp
80100e1c:	ff 73 10             	pushl  0x10(%ebx)
80100e1f:	e8 1f 08 00 00       	call   80101643 <iunlock>
    return r;
80100e24:	83 c4 10             	add    $0x10,%esp
  }
  panic("fileread");
}
80100e27:	89 f0                	mov    %esi,%eax
80100e29:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100e2c:	5b                   	pop    %ebx
80100e2d:	5e                   	pop    %esi
80100e2e:	5d                   	pop    %ebp
80100e2f:	c3                   	ret    
    return piperead(f->pipe, addr, n);
80100e30:	83 ec 04             	sub    $0x4,%esp
80100e33:	ff 75 10             	pushl  0x10(%ebp)
80100e36:	ff 75 0c             	pushl  0xc(%ebp)
80100e39:	ff 73 0c             	pushl  0xc(%ebx)
80100e3c:	e8 e2 22 00 00       	call   80103123 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 86 67 10 80       	push   $0x80106786
80100e50:	e8 f3 f4 ff ff       	call   80100348 <panic>
    return -1;
80100e55:	be ff ff ff ff       	mov    $0xffffffff,%esi
80100e5a:	eb cb                	jmp    80100e27 <fileread+0x50>

80100e5c <filewrite>:

// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80100e5c:	55                   	push   %ebp
80100e5d:	89 e5                	mov    %esp,%ebp
80100e5f:	57                   	push   %edi
80100e60:	56                   	push   %esi
80100e61:	53                   	push   %ebx
80100e62:	83 ec 1c             	sub    $0x1c,%esp
80100e65:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->writable == 0)
80100e68:	80 7b 09 00          	cmpb   $0x0,0x9(%ebx)
80100e6c:	0f 84 c5 00 00 00    	je     80100f37 <filewrite+0xdb>
    return -1;
  if(f->type == FD_PIPE)
80100e72:	8b 03                	mov    (%ebx),%eax
80100e74:	83 f8 01             	cmp    $0x1,%eax
80100e77:	74 10                	je     80100e89 <filewrite+0x2d>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100e79:	83 f8 02             	cmp    $0x2,%eax
80100e7c:	0f 85 a8 00 00 00    	jne    80100f2a <filewrite+0xce>
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
80100e82:	bf 00 00 00 00       	mov    $0x0,%edi
80100e87:	eb 67                	jmp    80100ef0 <filewrite+0x94>
    return pipewrite(f->pipe, addr, n);
80100e89:	83 ec 04             	sub    $0x4,%esp
80100e8c:	ff 75 10             	pushl  0x10(%ebp)
80100e8f:	ff 75 0c             	pushl  0xc(%ebp)
80100e92:	ff 73 0c             	pushl  0xc(%ebx)
80100e95:	e8 bd 21 00 00       	call   80103057 <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 9d 1a 00 00       	call   80102944 <begin_op>
      ilock(f->ip);
80100ea7:	83 ec 0c             	sub    $0xc,%esp
80100eaa:	ff 73 10             	pushl  0x10(%ebx)
80100ead:	e8 cf 06 00 00       	call   80101581 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80100eb2:	89 f8                	mov    %edi,%eax
80100eb4:	03 45 0c             	add    0xc(%ebp),%eax
80100eb7:	ff 75 e4             	pushl  -0x1c(%ebp)
80100eba:	ff 73 14             	pushl  0x14(%ebx)
80100ebd:	50                   	push   %eax
80100ebe:	ff 73 10             	pushl  0x10(%ebx)
80100ec1:	e8 aa 09 00 00       	call   80101870 <writei>
80100ec6:	89 c6                	mov    %eax,%esi
80100ec8:	83 c4 20             	add    $0x20,%esp
80100ecb:	85 c0                	test   %eax,%eax
80100ecd:	7e 03                	jle    80100ed2 <filewrite+0x76>
        f->off += r;
80100ecf:	01 43 14             	add    %eax,0x14(%ebx)
      iunlock(f->ip);
80100ed2:	83 ec 0c             	sub    $0xc,%esp
80100ed5:	ff 73 10             	pushl  0x10(%ebx)
80100ed8:	e8 66 07 00 00       	call   80101643 <iunlock>
      end_op();
80100edd:	e8 dc 1a 00 00       	call   801029be <end_op>

      if(r < 0)
80100ee2:	83 c4 10             	add    $0x10,%esp
80100ee5:	85 f6                	test   %esi,%esi
80100ee7:	78 31                	js     80100f1a <filewrite+0xbe>
        break;
      if(r != n1)
80100ee9:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
80100eec:	75 1f                	jne    80100f0d <filewrite+0xb1>
        panic("short filewrite");
      i += r;
80100eee:	01 f7                	add    %esi,%edi
    while(i < n){
80100ef0:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100ef3:	7d 25                	jge    80100f1a <filewrite+0xbe>
      int n1 = n - i;
80100ef5:	8b 45 10             	mov    0x10(%ebp),%eax
80100ef8:	29 f8                	sub    %edi,%eax
80100efa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(n1 > max)
80100efd:	3d 00 06 00 00       	cmp    $0x600,%eax
80100f02:	7e 9e                	jle    80100ea2 <filewrite+0x46>
        n1 = max;
80100f04:	c7 45 e4 00 06 00 00 	movl   $0x600,-0x1c(%ebp)
80100f0b:	eb 95                	jmp    80100ea2 <filewrite+0x46>
        panic("short filewrite");
80100f0d:	83 ec 0c             	sub    $0xc,%esp
80100f10:	68 8f 67 10 80       	push   $0x8010678f
80100f15:	e8 2e f4 ff ff       	call   80100348 <panic>
    }
    return i == n ? n : -1;
80100f1a:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f1d:	75 1f                	jne    80100f3e <filewrite+0xe2>
80100f1f:	8b 45 10             	mov    0x10(%ebp),%eax
  }
  panic("filewrite");
}
80100f22:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100f25:	5b                   	pop    %ebx
80100f26:	5e                   	pop    %esi
80100f27:	5f                   	pop    %edi
80100f28:	5d                   	pop    %ebp
80100f29:	c3                   	ret    
  panic("filewrite");
80100f2a:	83 ec 0c             	sub    $0xc,%esp
80100f2d:	68 95 67 10 80       	push   $0x80106795
80100f32:	e8 11 f4 ff ff       	call   80100348 <panic>
    return -1;
80100f37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f3c:	eb e4                	jmp    80100f22 <filewrite+0xc6>
    return i == n ? n : -1;
80100f3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f43:	eb dd                	jmp    80100f22 <filewrite+0xc6>

80100f45 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80100f45:	55                   	push   %ebp
80100f46:	89 e5                	mov    %esp,%ebp
80100f48:	57                   	push   %edi
80100f49:	56                   	push   %esi
80100f4a:	53                   	push   %ebx
80100f4b:	83 ec 0c             	sub    $0xc,%esp
80100f4e:	89 d7                	mov    %edx,%edi
  char *s;
  int len;

  while(*path == '/')
80100f50:	eb 03                	jmp    80100f55 <skipelem+0x10>
    path++;
80100f52:	83 c0 01             	add    $0x1,%eax
  while(*path == '/')
80100f55:	0f b6 10             	movzbl (%eax),%edx
80100f58:	80 fa 2f             	cmp    $0x2f,%dl
80100f5b:	74 f5                	je     80100f52 <skipelem+0xd>
  if(*path == 0)
80100f5d:	84 d2                	test   %dl,%dl
80100f5f:	74 59                	je     80100fba <skipelem+0x75>
80100f61:	89 c3                	mov    %eax,%ebx
80100f63:	eb 03                	jmp    80100f68 <skipelem+0x23>
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
    path++;
80100f65:	83 c3 01             	add    $0x1,%ebx
  while(*path != '/' && *path != 0)
80100f68:	0f b6 13             	movzbl (%ebx),%edx
80100f6b:	80 fa 2f             	cmp    $0x2f,%dl
80100f6e:	0f 95 c1             	setne  %cl
80100f71:	84 d2                	test   %dl,%dl
80100f73:	0f 95 c2             	setne  %dl
80100f76:	84 d1                	test   %dl,%cl
80100f78:	75 eb                	jne    80100f65 <skipelem+0x20>
  len = path - s;
80100f7a:	89 de                	mov    %ebx,%esi
80100f7c:	29 c6                	sub    %eax,%esi
  if(len >= DIRSIZ)
80100f7e:	83 fe 0d             	cmp    $0xd,%esi
80100f81:	7e 11                	jle    80100f94 <skipelem+0x4f>
    memmove(name, s, DIRSIZ);
80100f83:	83 ec 04             	sub    $0x4,%esp
80100f86:	6a 0e                	push   $0xe
80100f88:	50                   	push   %eax
80100f89:	57                   	push   %edi
80100f8a:	e8 5b 2f 00 00       	call   80103eea <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 4b 2f 00 00       	call   80103eea <memmove>
    name[len] = 0;
80100f9f:	c6 04 37 00          	movb   $0x0,(%edi,%esi,1)
80100fa3:	83 c4 10             	add    $0x10,%esp
80100fa6:	eb 03                	jmp    80100fab <skipelem+0x66>
  }
  while(*path == '/')
    path++;
80100fa8:	83 c3 01             	add    $0x1,%ebx
  while(*path == '/')
80100fab:	80 3b 2f             	cmpb   $0x2f,(%ebx)
80100fae:	74 f8                	je     80100fa8 <skipelem+0x63>
  return path;
}
80100fb0:	89 d8                	mov    %ebx,%eax
80100fb2:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100fb5:	5b                   	pop    %ebx
80100fb6:	5e                   	pop    %esi
80100fb7:	5f                   	pop    %edi
80100fb8:	5d                   	pop    %ebp
80100fb9:	c3                   	ret    
    return 0;
80100fba:	bb 00 00 00 00       	mov    $0x0,%ebx
80100fbf:	eb ef                	jmp    80100fb0 <skipelem+0x6b>

80100fc1 <bzero>:
{
80100fc1:	55                   	push   %ebp
80100fc2:	89 e5                	mov    %esp,%ebp
80100fc4:	53                   	push   %ebx
80100fc5:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, bno);
80100fc8:	52                   	push   %edx
80100fc9:	50                   	push   %eax
80100fca:	e8 9d f1 ff ff       	call   8010016c <bread>
80100fcf:	89 c3                	mov    %eax,%ebx
  memset(bp->data, 0, BSIZE);
80100fd1:	8d 40 5c             	lea    0x5c(%eax),%eax
80100fd4:	83 c4 0c             	add    $0xc,%esp
80100fd7:	68 00 02 00 00       	push   $0x200
80100fdc:	6a 00                	push   $0x0
80100fde:	50                   	push   %eax
80100fdf:	e8 8b 2e 00 00       	call   80103e6f <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 81 1a 00 00       	call   80102a6d <log_write>
  brelse(bp);
80100fec:	89 1c 24             	mov    %ebx,(%esp)
80100fef:	e8 e1 f1 ff ff       	call   801001d5 <brelse>
}
80100ff4:	83 c4 10             	add    $0x10,%esp
80100ff7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100ffa:	c9                   	leave  
80100ffb:	c3                   	ret    

80100ffc <balloc>:
{
80100ffc:	55                   	push   %ebp
80100ffd:	89 e5                	mov    %esp,%ebp
80100fff:	57                   	push   %edi
80101000:	56                   	push   %esi
80101001:	53                   	push   %ebx
80101002:	83 ec 1c             	sub    $0x1c,%esp
80101005:	89 45 d8             	mov    %eax,-0x28(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101008:	be 00 00 00 00       	mov    $0x0,%esi
8010100d:	eb 14                	jmp    80101023 <balloc+0x27>
    brelse(bp);
8010100f:	83 ec 0c             	sub    $0xc,%esp
80101012:	ff 75 e4             	pushl  -0x1c(%ebp)
80101015:	e8 bb f1 ff ff       	call   801001d5 <brelse>
  for(b = 0; b < sb.size; b += BPB){
8010101a:	81 c6 00 10 00 00    	add    $0x1000,%esi
80101020:	83 c4 10             	add    $0x10,%esp
80101023:	39 35 c0 09 11 80    	cmp    %esi,0x801109c0
80101029:	76 75                	jbe    801010a0 <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
8010102b:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
80101031:	85 f6                	test   %esi,%esi
80101033:	0f 49 c6             	cmovns %esi,%eax
80101036:	c1 f8 0c             	sar    $0xc,%eax
80101039:	03 05 d8 09 11 80    	add    0x801109d8,%eax
8010103f:	83 ec 08             	sub    $0x8,%esp
80101042:	50                   	push   %eax
80101043:	ff 75 d8             	pushl  -0x28(%ebp)
80101046:	e8 21 f1 ff ff       	call   8010016c <bread>
8010104b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010104e:	83 c4 10             	add    $0x10,%esp
80101051:	b8 00 00 00 00       	mov    $0x0,%eax
80101056:	3d ff 0f 00 00       	cmp    $0xfff,%eax
8010105b:	7f b2                	jg     8010100f <balloc+0x13>
8010105d:	8d 1c 06             	lea    (%esi,%eax,1),%ebx
80101060:	89 5d e0             	mov    %ebx,-0x20(%ebp)
80101063:	3b 1d c0 09 11 80    	cmp    0x801109c0,%ebx
80101069:	73 a4                	jae    8010100f <balloc+0x13>
      m = 1 << (bi % 8);
8010106b:	99                   	cltd   
8010106c:	c1 ea 1d             	shr    $0x1d,%edx
8010106f:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80101072:	83 e1 07             	and    $0x7,%ecx
80101075:	29 d1                	sub    %edx,%ecx
80101077:	ba 01 00 00 00       	mov    $0x1,%edx
8010107c:	d3 e2                	shl    %cl,%edx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010107e:	8d 48 07             	lea    0x7(%eax),%ecx
80101081:	85 c0                	test   %eax,%eax
80101083:	0f 49 c8             	cmovns %eax,%ecx
80101086:	c1 f9 03             	sar    $0x3,%ecx
80101089:	89 4d dc             	mov    %ecx,-0x24(%ebp)
8010108c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010108f:	0f b6 4c 0f 5c       	movzbl 0x5c(%edi,%ecx,1),%ecx
80101094:	0f b6 f9             	movzbl %cl,%edi
80101097:	85 d7                	test   %edx,%edi
80101099:	74 12                	je     801010ad <balloc+0xb1>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010109b:	83 c0 01             	add    $0x1,%eax
8010109e:	eb b6                	jmp    80101056 <balloc+0x5a>
  panic("balloc: out of blocks");
801010a0:	83 ec 0c             	sub    $0xc,%esp
801010a3:	68 9f 67 10 80       	push   $0x8010679f
801010a8:	e8 9b f2 ff ff       	call   80100348 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
801010ad:	09 ca                	or     %ecx,%edx
801010af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801010b2:	8b 75 dc             	mov    -0x24(%ebp),%esi
801010b5:	88 54 30 5c          	mov    %dl,0x5c(%eax,%esi,1)
        log_write(bp);
801010b9:	83 ec 0c             	sub    $0xc,%esp
801010bc:	89 c6                	mov    %eax,%esi
801010be:	50                   	push   %eax
801010bf:	e8 a9 19 00 00       	call   80102a6d <log_write>
        brelse(bp);
801010c4:	89 34 24             	mov    %esi,(%esp)
801010c7:	e8 09 f1 ff ff       	call   801001d5 <brelse>
        bzero(dev, b + bi);
801010cc:	89 da                	mov    %ebx,%edx
801010ce:	8b 45 d8             	mov    -0x28(%ebp),%eax
801010d1:	e8 eb fe ff ff       	call   80100fc1 <bzero>
}
801010d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010d9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801010dc:	5b                   	pop    %ebx
801010dd:	5e                   	pop    %esi
801010de:	5f                   	pop    %edi
801010df:	5d                   	pop    %ebp
801010e0:	c3                   	ret    

801010e1 <bmap>:
{
801010e1:	55                   	push   %ebp
801010e2:	89 e5                	mov    %esp,%ebp
801010e4:	57                   	push   %edi
801010e5:	56                   	push   %esi
801010e6:	53                   	push   %ebx
801010e7:	83 ec 1c             	sub    $0x1c,%esp
801010ea:	89 c6                	mov    %eax,%esi
801010ec:	89 d7                	mov    %edx,%edi
  if(bn < NDIRECT){
801010ee:	83 fa 0b             	cmp    $0xb,%edx
801010f1:	77 17                	ja     8010110a <bmap+0x29>
    if((addr = ip->addrs[bn]) == 0)
801010f3:	8b 5c 90 5c          	mov    0x5c(%eax,%edx,4),%ebx
801010f7:	85 db                	test   %ebx,%ebx
801010f9:	75 4a                	jne    80101145 <bmap+0x64>
      ip->addrs[bn] = addr = balloc(ip->dev);
801010fb:	8b 00                	mov    (%eax),%eax
801010fd:	e8 fa fe ff ff       	call   80100ffc <balloc>
80101102:	89 c3                	mov    %eax,%ebx
80101104:	89 44 be 5c          	mov    %eax,0x5c(%esi,%edi,4)
80101108:	eb 3b                	jmp    80101145 <bmap+0x64>
  bn -= NDIRECT;
8010110a:	8d 5a f4             	lea    -0xc(%edx),%ebx
  if(bn < NINDIRECT){
8010110d:	83 fb 7f             	cmp    $0x7f,%ebx
80101110:	77 68                	ja     8010117a <bmap+0x99>
    if((addr = ip->addrs[NDIRECT]) == 0)
80101112:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101118:	85 c0                	test   %eax,%eax
8010111a:	74 33                	je     8010114f <bmap+0x6e>
    bp = bread(ip->dev, addr);
8010111c:	83 ec 08             	sub    $0x8,%esp
8010111f:	50                   	push   %eax
80101120:	ff 36                	pushl  (%esi)
80101122:	e8 45 f0 ff ff       	call   8010016c <bread>
80101127:	89 c7                	mov    %eax,%edi
    if((addr = a[bn]) == 0){
80101129:	8d 44 98 5c          	lea    0x5c(%eax,%ebx,4),%eax
8010112d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80101130:	8b 18                	mov    (%eax),%ebx
80101132:	83 c4 10             	add    $0x10,%esp
80101135:	85 db                	test   %ebx,%ebx
80101137:	74 25                	je     8010115e <bmap+0x7d>
    brelse(bp);
80101139:	83 ec 0c             	sub    $0xc,%esp
8010113c:	57                   	push   %edi
8010113d:	e8 93 f0 ff ff       	call   801001d5 <brelse>
    return addr;
80101142:	83 c4 10             	add    $0x10,%esp
}
80101145:	89 d8                	mov    %ebx,%eax
80101147:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010114a:	5b                   	pop    %ebx
8010114b:	5e                   	pop    %esi
8010114c:	5f                   	pop    %edi
8010114d:	5d                   	pop    %ebp
8010114e:	c3                   	ret    
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
8010114f:	8b 06                	mov    (%esi),%eax
80101151:	e8 a6 fe ff ff       	call   80100ffc <balloc>
80101156:	89 86 8c 00 00 00    	mov    %eax,0x8c(%esi)
8010115c:	eb be                	jmp    8010111c <bmap+0x3b>
      a[bn] = addr = balloc(ip->dev);
8010115e:	8b 06                	mov    (%esi),%eax
80101160:	e8 97 fe ff ff       	call   80100ffc <balloc>
80101165:	89 c3                	mov    %eax,%ebx
80101167:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010116a:	89 18                	mov    %ebx,(%eax)
      log_write(bp);
8010116c:	83 ec 0c             	sub    $0xc,%esp
8010116f:	57                   	push   %edi
80101170:	e8 f8 18 00 00       	call   80102a6d <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 b5 67 10 80       	push   $0x801067b5
80101182:	e8 c1 f1 ff ff       	call   80100348 <panic>

80101187 <iget>:
{
80101187:	55                   	push   %ebp
80101188:	89 e5                	mov    %esp,%ebp
8010118a:	57                   	push   %edi
8010118b:	56                   	push   %esi
8010118c:	53                   	push   %ebx
8010118d:	83 ec 28             	sub    $0x28,%esp
80101190:	89 c7                	mov    %eax,%edi
80101192:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  acquire(&icache.lock);
80101195:	68 e0 09 11 80       	push   $0x801109e0
8010119a:	e8 24 2c 00 00       	call   80103dc3 <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010119f:	83 c4 10             	add    $0x10,%esp
  empty = 0;
801011a2:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011a7:	bb 14 0a 11 80       	mov    $0x80110a14,%ebx
801011ac:	eb 0a                	jmp    801011b8 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ae:	85 f6                	test   %esi,%esi
801011b0:	74 3b                	je     801011ed <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011b2:	81 c3 90 00 00 00    	add    $0x90,%ebx
801011b8:	81 fb 34 26 11 80    	cmp    $0x80112634,%ebx
801011be:	73 35                	jae    801011f5 <iget+0x6e>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801011c0:	8b 43 08             	mov    0x8(%ebx),%eax
801011c3:	85 c0                	test   %eax,%eax
801011c5:	7e e7                	jle    801011ae <iget+0x27>
801011c7:	39 3b                	cmp    %edi,(%ebx)
801011c9:	75 e3                	jne    801011ae <iget+0x27>
801011cb:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801011ce:	39 4b 04             	cmp    %ecx,0x4(%ebx)
801011d1:	75 db                	jne    801011ae <iget+0x27>
      ip->ref++;
801011d3:	83 c0 01             	add    $0x1,%eax
801011d6:	89 43 08             	mov    %eax,0x8(%ebx)
      release(&icache.lock);
801011d9:	83 ec 0c             	sub    $0xc,%esp
801011dc:	68 e0 09 11 80       	push   $0x801109e0
801011e1:	e8 42 2c 00 00       	call   80103e28 <release>
      return ip;
801011e6:	83 c4 10             	add    $0x10,%esp
801011e9:	89 de                	mov    %ebx,%esi
801011eb:	eb 32                	jmp    8010121f <iget+0x98>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ed:	85 c0                	test   %eax,%eax
801011ef:	75 c1                	jne    801011b2 <iget+0x2b>
      empty = ip;
801011f1:	89 de                	mov    %ebx,%esi
801011f3:	eb bd                	jmp    801011b2 <iget+0x2b>
  if(empty == 0)
801011f5:	85 f6                	test   %esi,%esi
801011f7:	74 30                	je     80101229 <iget+0xa2>
  ip->dev = dev;
801011f9:	89 3e                	mov    %edi,(%esi)
  ip->inum = inum;
801011fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801011fe:	89 46 04             	mov    %eax,0x4(%esi)
  ip->ref = 1;
80101201:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->valid = 0;
80101208:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  release(&icache.lock);
8010120f:	83 ec 0c             	sub    $0xc,%esp
80101212:	68 e0 09 11 80       	push   $0x801109e0
80101217:	e8 0c 2c 00 00       	call   80103e28 <release>
  return ip;
8010121c:	83 c4 10             	add    $0x10,%esp
}
8010121f:	89 f0                	mov    %esi,%eax
80101221:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101224:	5b                   	pop    %ebx
80101225:	5e                   	pop    %esi
80101226:	5f                   	pop    %edi
80101227:	5d                   	pop    %ebp
80101228:	c3                   	ret    
    panic("iget: no inodes");
80101229:	83 ec 0c             	sub    $0xc,%esp
8010122c:	68 c8 67 10 80       	push   $0x801067c8
80101231:	e8 12 f1 ff ff       	call   80100348 <panic>

80101236 <readsb>:
{
80101236:	55                   	push   %ebp
80101237:	89 e5                	mov    %esp,%ebp
80101239:	53                   	push   %ebx
8010123a:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, 1);
8010123d:	6a 01                	push   $0x1
8010123f:	ff 75 08             	pushl  0x8(%ebp)
80101242:	e8 25 ef ff ff       	call   8010016c <bread>
80101247:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
80101249:	8d 40 5c             	lea    0x5c(%eax),%eax
8010124c:	83 c4 0c             	add    $0xc,%esp
8010124f:	6a 1c                	push   $0x1c
80101251:	50                   	push   %eax
80101252:	ff 75 0c             	pushl  0xc(%ebp)
80101255:	e8 90 2c 00 00       	call   80103eea <memmove>
  brelse(bp);
8010125a:	89 1c 24             	mov    %ebx,(%esp)
8010125d:	e8 73 ef ff ff       	call   801001d5 <brelse>
}
80101262:	83 c4 10             	add    $0x10,%esp
80101265:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101268:	c9                   	leave  
80101269:	c3                   	ret    

8010126a <bfree>:
{
8010126a:	55                   	push   %ebp
8010126b:	89 e5                	mov    %esp,%ebp
8010126d:	56                   	push   %esi
8010126e:	53                   	push   %ebx
8010126f:	89 c6                	mov    %eax,%esi
80101271:	89 d3                	mov    %edx,%ebx
  readsb(dev, &sb);
80101273:	83 ec 08             	sub    $0x8,%esp
80101276:	68 c0 09 11 80       	push   $0x801109c0
8010127b:	50                   	push   %eax
8010127c:	e8 b5 ff ff ff       	call   80101236 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101281:	89 d8                	mov    %ebx,%eax
80101283:	c1 e8 0c             	shr    $0xc,%eax
80101286:	03 05 d8 09 11 80    	add    0x801109d8,%eax
8010128c:	83 c4 08             	add    $0x8,%esp
8010128f:	50                   	push   %eax
80101290:	56                   	push   %esi
80101291:	e8 d6 ee ff ff       	call   8010016c <bread>
80101296:	89 c6                	mov    %eax,%esi
  m = 1 << (bi % 8);
80101298:	89 d9                	mov    %ebx,%ecx
8010129a:	83 e1 07             	and    $0x7,%ecx
8010129d:	b8 01 00 00 00       	mov    $0x1,%eax
801012a2:	d3 e0                	shl    %cl,%eax
  if((bp->data[bi/8] & m) == 0)
801012a4:	83 c4 10             	add    $0x10,%esp
801012a7:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801012ad:	c1 fb 03             	sar    $0x3,%ebx
801012b0:	0f b6 54 1e 5c       	movzbl 0x5c(%esi,%ebx,1),%edx
801012b5:	0f b6 ca             	movzbl %dl,%ecx
801012b8:	85 c1                	test   %eax,%ecx
801012ba:	74 23                	je     801012df <bfree+0x75>
  bp->data[bi/8] &= ~m;
801012bc:	f7 d0                	not    %eax
801012be:	21 d0                	and    %edx,%eax
801012c0:	88 44 1e 5c          	mov    %al,0x5c(%esi,%ebx,1)
  log_write(bp);
801012c4:	83 ec 0c             	sub    $0xc,%esp
801012c7:	56                   	push   %esi
801012c8:	e8 a0 17 00 00       	call   80102a6d <log_write>
  brelse(bp);
801012cd:	89 34 24             	mov    %esi,(%esp)
801012d0:	e8 00 ef ff ff       	call   801001d5 <brelse>
}
801012d5:	83 c4 10             	add    $0x10,%esp
801012d8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801012db:	5b                   	pop    %ebx
801012dc:	5e                   	pop    %esi
801012dd:	5d                   	pop    %ebp
801012de:	c3                   	ret    
    panic("freeing free block");
801012df:	83 ec 0c             	sub    $0xc,%esp
801012e2:	68 d8 67 10 80       	push   $0x801067d8
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 eb 67 10 80       	push   $0x801067eb
801012f8:	68 e0 09 11 80       	push   $0x801109e0
801012fd:	e8 85 29 00 00       	call   80103c87 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 f2 67 10 80       	push   $0x801067f2
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 20 0a 11 80       	add    $0x80110a20,%eax
80101321:	50                   	push   %eax
80101322:	e8 55 28 00 00       	call   80103b7c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101327:	83 c3 01             	add    $0x1,%ebx
8010132a:	83 c4 10             	add    $0x10,%esp
8010132d:	83 fb 31             	cmp    $0x31,%ebx
80101330:	7e da                	jle    8010130c <iinit+0x20>
  readsb(dev, &sb);
80101332:	83 ec 08             	sub    $0x8,%esp
80101335:	68 c0 09 11 80       	push   $0x801109c0
8010133a:	ff 75 08             	pushl  0x8(%ebp)
8010133d:	e8 f4 fe ff ff       	call   80101236 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101342:	ff 35 d8 09 11 80    	pushl  0x801109d8
80101348:	ff 35 d4 09 11 80    	pushl  0x801109d4
8010134e:	ff 35 d0 09 11 80    	pushl  0x801109d0
80101354:	ff 35 cc 09 11 80    	pushl  0x801109cc
8010135a:	ff 35 c8 09 11 80    	pushl  0x801109c8
80101360:	ff 35 c4 09 11 80    	pushl  0x801109c4
80101366:	ff 35 c0 09 11 80    	pushl  0x801109c0
8010136c:	68 58 68 10 80       	push   $0x80106858
80101371:	e8 95 f2 ff ff       	call   8010060b <cprintf>
}
80101376:	83 c4 30             	add    $0x30,%esp
80101379:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010137c:	c9                   	leave  
8010137d:	c3                   	ret    

8010137e <ialloc>:
{
8010137e:	55                   	push   %ebp
8010137f:	89 e5                	mov    %esp,%ebp
80101381:	57                   	push   %edi
80101382:	56                   	push   %esi
80101383:	53                   	push   %ebx
80101384:	83 ec 1c             	sub    $0x1c,%esp
80101387:	8b 45 0c             	mov    0xc(%ebp),%eax
8010138a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(inum = 1; inum < sb.ninodes; inum++){
8010138d:	bb 01 00 00 00       	mov    $0x1,%ebx
80101392:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
80101395:	39 1d c8 09 11 80    	cmp    %ebx,0x801109c8
8010139b:	76 3f                	jbe    801013dc <ialloc+0x5e>
    bp = bread(dev, IBLOCK(inum, sb));
8010139d:	89 d8                	mov    %ebx,%eax
8010139f:	c1 e8 03             	shr    $0x3,%eax
801013a2:	03 05 d4 09 11 80    	add    0x801109d4,%eax
801013a8:	83 ec 08             	sub    $0x8,%esp
801013ab:	50                   	push   %eax
801013ac:	ff 75 08             	pushl  0x8(%ebp)
801013af:	e8 b8 ed ff ff       	call   8010016c <bread>
801013b4:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + inum%IPB;
801013b6:	89 d8                	mov    %ebx,%eax
801013b8:	83 e0 07             	and    $0x7,%eax
801013bb:	c1 e0 06             	shl    $0x6,%eax
801013be:	8d 7c 06 5c          	lea    0x5c(%esi,%eax,1),%edi
    if(dip->type == 0){  // a free inode
801013c2:	83 c4 10             	add    $0x10,%esp
801013c5:	66 83 3f 00          	cmpw   $0x0,(%edi)
801013c9:	74 1e                	je     801013e9 <ialloc+0x6b>
    brelse(bp);
801013cb:	83 ec 0c             	sub    $0xc,%esp
801013ce:	56                   	push   %esi
801013cf:	e8 01 ee ff ff       	call   801001d5 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
801013d4:	83 c3 01             	add    $0x1,%ebx
801013d7:	83 c4 10             	add    $0x10,%esp
801013da:	eb b6                	jmp    80101392 <ialloc+0x14>
  panic("ialloc: no inodes");
801013dc:	83 ec 0c             	sub    $0xc,%esp
801013df:	68 f8 67 10 80       	push   $0x801067f8
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 79 2a 00 00       	call   80103e6f <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 68 16 00 00       	call   80102a6d <log_write>
      brelse(bp);
80101405:	89 34 24             	mov    %esi,(%esp)
80101408:	e8 c8 ed ff ff       	call   801001d5 <brelse>
      return iget(dev, inum);
8010140d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101410:	8b 45 08             	mov    0x8(%ebp),%eax
80101413:	e8 6f fd ff ff       	call   80101187 <iget>
}
80101418:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010141b:	5b                   	pop    %ebx
8010141c:	5e                   	pop    %esi
8010141d:	5f                   	pop    %edi
8010141e:	5d                   	pop    %ebp
8010141f:	c3                   	ret    

80101420 <iupdate>:
{
80101420:	55                   	push   %ebp
80101421:	89 e5                	mov    %esp,%ebp
80101423:	56                   	push   %esi
80101424:	53                   	push   %ebx
80101425:	8b 5d 08             	mov    0x8(%ebp),%ebx
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101428:	8b 43 04             	mov    0x4(%ebx),%eax
8010142b:	c1 e8 03             	shr    $0x3,%eax
8010142e:	03 05 d4 09 11 80    	add    0x801109d4,%eax
80101434:	83 ec 08             	sub    $0x8,%esp
80101437:	50                   	push   %eax
80101438:	ff 33                	pushl  (%ebx)
8010143a:	e8 2d ed ff ff       	call   8010016c <bread>
8010143f:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101441:	8b 43 04             	mov    0x4(%ebx),%eax
80101444:	83 e0 07             	and    $0x7,%eax
80101447:	c1 e0 06             	shl    $0x6,%eax
8010144a:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
  dip->type = ip->type;
8010144e:	0f b7 53 50          	movzwl 0x50(%ebx),%edx
80101452:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101455:	0f b7 53 52          	movzwl 0x52(%ebx),%edx
80101459:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
8010145d:	0f b7 53 54          	movzwl 0x54(%ebx),%edx
80101461:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101465:	0f b7 53 56          	movzwl 0x56(%ebx),%edx
80101469:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
8010146d:	8b 53 58             	mov    0x58(%ebx),%edx
80101470:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101473:	83 c3 5c             	add    $0x5c,%ebx
80101476:	83 c0 0c             	add    $0xc,%eax
80101479:	83 c4 0c             	add    $0xc,%esp
8010147c:	6a 34                	push   $0x34
8010147e:	53                   	push   %ebx
8010147f:	50                   	push   %eax
80101480:	e8 65 2a 00 00       	call   80103eea <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 e0 15 00 00       	call   80102a6d <log_write>
  brelse(bp);
8010148d:	89 34 24             	mov    %esi,(%esp)
80101490:	e8 40 ed ff ff       	call   801001d5 <brelse>
}
80101495:	83 c4 10             	add    $0x10,%esp
80101498:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010149b:	5b                   	pop    %ebx
8010149c:	5e                   	pop    %esi
8010149d:	5d                   	pop    %ebp
8010149e:	c3                   	ret    

8010149f <itrunc>:
{
8010149f:	55                   	push   %ebp
801014a0:	89 e5                	mov    %esp,%ebp
801014a2:	57                   	push   %edi
801014a3:	56                   	push   %esi
801014a4:	53                   	push   %ebx
801014a5:	83 ec 1c             	sub    $0x1c,%esp
801014a8:	89 c6                	mov    %eax,%esi
  for(i = 0; i < NDIRECT; i++){
801014aa:	bb 00 00 00 00       	mov    $0x0,%ebx
801014af:	eb 03                	jmp    801014b4 <itrunc+0x15>
801014b1:	83 c3 01             	add    $0x1,%ebx
801014b4:	83 fb 0b             	cmp    $0xb,%ebx
801014b7:	7f 19                	jg     801014d2 <itrunc+0x33>
    if(ip->addrs[i]){
801014b9:	8b 54 9e 5c          	mov    0x5c(%esi,%ebx,4),%edx
801014bd:	85 d2                	test   %edx,%edx
801014bf:	74 f0                	je     801014b1 <itrunc+0x12>
      bfree(ip->dev, ip->addrs[i]);
801014c1:	8b 06                	mov    (%esi),%eax
801014c3:	e8 a2 fd ff ff       	call   8010126a <bfree>
      ip->addrs[i] = 0;
801014c8:	c7 44 9e 5c 00 00 00 	movl   $0x0,0x5c(%esi,%ebx,4)
801014cf:	00 
801014d0:	eb df                	jmp    801014b1 <itrunc+0x12>
  if(ip->addrs[NDIRECT]){
801014d2:	8b 86 8c 00 00 00    	mov    0x8c(%esi),%eax
801014d8:	85 c0                	test   %eax,%eax
801014da:	75 1b                	jne    801014f7 <itrunc+0x58>
  ip->size = 0;
801014dc:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
  iupdate(ip);
801014e3:	83 ec 0c             	sub    $0xc,%esp
801014e6:	56                   	push   %esi
801014e7:	e8 34 ff ff ff       	call   80101420 <iupdate>
}
801014ec:	83 c4 10             	add    $0x10,%esp
801014ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
801014f2:	5b                   	pop    %ebx
801014f3:	5e                   	pop    %esi
801014f4:	5f                   	pop    %edi
801014f5:	5d                   	pop    %ebp
801014f6:	c3                   	ret    
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801014f7:	83 ec 08             	sub    $0x8,%esp
801014fa:	50                   	push   %eax
801014fb:	ff 36                	pushl  (%esi)
801014fd:	e8 6a ec ff ff       	call   8010016c <bread>
80101502:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
80101505:	8d 78 5c             	lea    0x5c(%eax),%edi
    for(j = 0; j < NINDIRECT; j++){
80101508:	83 c4 10             	add    $0x10,%esp
8010150b:	bb 00 00 00 00       	mov    $0x0,%ebx
80101510:	eb 03                	jmp    80101515 <itrunc+0x76>
80101512:	83 c3 01             	add    $0x1,%ebx
80101515:	83 fb 7f             	cmp    $0x7f,%ebx
80101518:	77 10                	ja     8010152a <itrunc+0x8b>
      if(a[j])
8010151a:	8b 14 9f             	mov    (%edi,%ebx,4),%edx
8010151d:	85 d2                	test   %edx,%edx
8010151f:	74 f1                	je     80101512 <itrunc+0x73>
        bfree(ip->dev, a[j]);
80101521:	8b 06                	mov    (%esi),%eax
80101523:	e8 42 fd ff ff       	call   8010126a <bfree>
80101528:	eb e8                	jmp    80101512 <itrunc+0x73>
    brelse(bp);
8010152a:	83 ec 0c             	sub    $0xc,%esp
8010152d:	ff 75 e4             	pushl  -0x1c(%ebp)
80101530:	e8 a0 ec ff ff       	call   801001d5 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101535:	8b 06                	mov    (%esi),%eax
80101537:	8b 96 8c 00 00 00    	mov    0x8c(%esi),%edx
8010153d:	e8 28 fd ff ff       	call   8010126a <bfree>
    ip->addrs[NDIRECT] = 0;
80101542:	c7 86 8c 00 00 00 00 	movl   $0x0,0x8c(%esi)
80101549:	00 00 00 
8010154c:	83 c4 10             	add    $0x10,%esp
8010154f:	eb 8b                	jmp    801014dc <itrunc+0x3d>

80101551 <idup>:
{
80101551:	55                   	push   %ebp
80101552:	89 e5                	mov    %esp,%ebp
80101554:	53                   	push   %ebx
80101555:	83 ec 10             	sub    $0x10,%esp
80101558:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
8010155b:	68 e0 09 11 80       	push   $0x801109e0
80101560:	e8 5e 28 00 00       	call   80103dc3 <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
80101575:	e8 ae 28 00 00       	call   80103e28 <release>
}
8010157a:	89 d8                	mov    %ebx,%eax
8010157c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010157f:	c9                   	leave  
80101580:	c3                   	ret    

80101581 <ilock>:
{
80101581:	55                   	push   %ebp
80101582:	89 e5                	mov    %esp,%ebp
80101584:	56                   	push   %esi
80101585:	53                   	push   %ebx
80101586:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || ip->ref < 1)
80101589:	85 db                	test   %ebx,%ebx
8010158b:	74 22                	je     801015af <ilock+0x2e>
8010158d:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101591:	7e 1c                	jle    801015af <ilock+0x2e>
  acquiresleep(&ip->lock);
80101593:	83 ec 0c             	sub    $0xc,%esp
80101596:	8d 43 0c             	lea    0xc(%ebx),%eax
80101599:	50                   	push   %eax
8010159a:	e8 10 26 00 00       	call   80103baf <acquiresleep>
  if(ip->valid == 0){
8010159f:	83 c4 10             	add    $0x10,%esp
801015a2:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801015a6:	74 14                	je     801015bc <ilock+0x3b>
}
801015a8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801015ab:	5b                   	pop    %ebx
801015ac:	5e                   	pop    %esi
801015ad:	5d                   	pop    %ebp
801015ae:	c3                   	ret    
    panic("ilock");
801015af:	83 ec 0c             	sub    $0xc,%esp
801015b2:	68 0a 68 10 80       	push   $0x8010680a
801015b7:	e8 8c ed ff ff       	call   80100348 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801015bc:	8b 43 04             	mov    0x4(%ebx),%eax
801015bf:	c1 e8 03             	shr    $0x3,%eax
801015c2:	03 05 d4 09 11 80    	add    0x801109d4,%eax
801015c8:	83 ec 08             	sub    $0x8,%esp
801015cb:	50                   	push   %eax
801015cc:	ff 33                	pushl  (%ebx)
801015ce:	e8 99 eb ff ff       	call   8010016c <bread>
801015d3:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801015d5:	8b 43 04             	mov    0x4(%ebx),%eax
801015d8:	83 e0 07             	and    $0x7,%eax
801015db:	c1 e0 06             	shl    $0x6,%eax
801015de:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
    ip->type = dip->type;
801015e2:	0f b7 10             	movzwl (%eax),%edx
801015e5:	66 89 53 50          	mov    %dx,0x50(%ebx)
    ip->major = dip->major;
801015e9:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801015ed:	66 89 53 52          	mov    %dx,0x52(%ebx)
    ip->minor = dip->minor;
801015f1:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801015f5:	66 89 53 54          	mov    %dx,0x54(%ebx)
    ip->nlink = dip->nlink;
801015f9:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801015fd:	66 89 53 56          	mov    %dx,0x56(%ebx)
    ip->size = dip->size;
80101601:	8b 50 08             	mov    0x8(%eax),%edx
80101604:	89 53 58             	mov    %edx,0x58(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101607:	83 c0 0c             	add    $0xc,%eax
8010160a:	8d 53 5c             	lea    0x5c(%ebx),%edx
8010160d:	83 c4 0c             	add    $0xc,%esp
80101610:	6a 34                	push   $0x34
80101612:	50                   	push   %eax
80101613:	52                   	push   %edx
80101614:	e8 d1 28 00 00       	call   80103eea <memmove>
    brelse(bp);
80101619:	89 34 24             	mov    %esi,(%esp)
8010161c:	e8 b4 eb ff ff       	call   801001d5 <brelse>
    ip->valid = 1;
80101621:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
    if(ip->type == 0)
80101628:	83 c4 10             	add    $0x10,%esp
8010162b:	66 83 7b 50 00       	cmpw   $0x0,0x50(%ebx)
80101630:	0f 85 72 ff ff ff    	jne    801015a8 <ilock+0x27>
      panic("ilock: no type");
80101636:	83 ec 0c             	sub    $0xc,%esp
80101639:	68 10 68 10 80       	push   $0x80106810
8010163e:	e8 05 ed ff ff       	call   80100348 <panic>

80101643 <iunlock>:
{
80101643:	55                   	push   %ebp
80101644:	89 e5                	mov    %esp,%ebp
80101646:	56                   	push   %esi
80101647:	53                   	push   %ebx
80101648:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
8010164b:	85 db                	test   %ebx,%ebx
8010164d:	74 2c                	je     8010167b <iunlock+0x38>
8010164f:	8d 73 0c             	lea    0xc(%ebx),%esi
80101652:	83 ec 0c             	sub    $0xc,%esp
80101655:	56                   	push   %esi
80101656:	e8 de 25 00 00       	call   80103c39 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 8d 25 00 00       	call   80103bfe <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 1f 68 10 80       	push   $0x8010681f
80101683:	e8 c0 ec ff ff       	call   80100348 <panic>

80101688 <iput>:
{
80101688:	55                   	push   %ebp
80101689:	89 e5                	mov    %esp,%ebp
8010168b:	57                   	push   %edi
8010168c:	56                   	push   %esi
8010168d:	53                   	push   %ebx
8010168e:	83 ec 18             	sub    $0x18,%esp
80101691:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquiresleep(&ip->lock);
80101694:	8d 73 0c             	lea    0xc(%ebx),%esi
80101697:	56                   	push   %esi
80101698:	e8 12 25 00 00       	call   80103baf <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 48 25 00 00       	call   80103bfe <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016bd:	e8 01 27 00 00       	call   80103dc3 <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016d2:	e8 51 27 00 00       	call   80103e28 <release>
}
801016d7:	83 c4 10             	add    $0x10,%esp
801016da:	8d 65 f4             	lea    -0xc(%ebp),%esp
801016dd:	5b                   	pop    %ebx
801016de:	5e                   	pop    %esi
801016df:	5f                   	pop    %edi
801016e0:	5d                   	pop    %ebp
801016e1:	c3                   	ret    
    acquire(&icache.lock);
801016e2:	83 ec 0c             	sub    $0xc,%esp
801016e5:	68 e0 09 11 80       	push   $0x801109e0
801016ea:	e8 d4 26 00 00       	call   80103dc3 <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016f9:	e8 2a 27 00 00       	call   80103e28 <release>
    if(r == 1){
801016fe:	83 c4 10             	add    $0x10,%esp
80101701:	83 ff 01             	cmp    $0x1,%edi
80101704:	75 a7                	jne    801016ad <iput+0x25>
      itrunc(ip);
80101706:	89 d8                	mov    %ebx,%eax
80101708:	e8 92 fd ff ff       	call   8010149f <itrunc>
      ip->type = 0;
8010170d:	66 c7 43 50 00 00    	movw   $0x0,0x50(%ebx)
      iupdate(ip);
80101713:	83 ec 0c             	sub    $0xc,%esp
80101716:	53                   	push   %ebx
80101717:	e8 04 fd ff ff       	call   80101420 <iupdate>
      ip->valid = 0;
8010171c:	c7 43 4c 00 00 00 00 	movl   $0x0,0x4c(%ebx)
80101723:	83 c4 10             	add    $0x10,%esp
80101726:	eb 85                	jmp    801016ad <iput+0x25>

80101728 <iunlockput>:
{
80101728:	55                   	push   %ebp
80101729:	89 e5                	mov    %esp,%ebp
8010172b:	53                   	push   %ebx
8010172c:	83 ec 10             	sub    $0x10,%esp
8010172f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
80101732:	53                   	push   %ebx
80101733:	e8 0b ff ff ff       	call   80101643 <iunlock>
  iput(ip);
80101738:	89 1c 24             	mov    %ebx,(%esp)
8010173b:	e8 48 ff ff ff       	call   80101688 <iput>
}
80101740:	83 c4 10             	add    $0x10,%esp
80101743:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101746:	c9                   	leave  
80101747:	c3                   	ret    

80101748 <stati>:
{
80101748:	55                   	push   %ebp
80101749:	89 e5                	mov    %esp,%ebp
8010174b:	8b 55 08             	mov    0x8(%ebp),%edx
8010174e:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
80101751:	8b 0a                	mov    (%edx),%ecx
80101753:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
80101756:	8b 4a 04             	mov    0x4(%edx),%ecx
80101759:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
8010175c:	0f b7 4a 50          	movzwl 0x50(%edx),%ecx
80101760:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
80101763:	0f b7 4a 56          	movzwl 0x56(%edx),%ecx
80101767:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
8010176b:	8b 52 58             	mov    0x58(%edx),%edx
8010176e:	89 50 10             	mov    %edx,0x10(%eax)
}
80101771:	5d                   	pop    %ebp
80101772:	c3                   	ret    

80101773 <readi>:
{
80101773:	55                   	push   %ebp
80101774:	89 e5                	mov    %esp,%ebp
80101776:	57                   	push   %edi
80101777:	56                   	push   %esi
80101778:	53                   	push   %ebx
80101779:	83 ec 1c             	sub    $0x1c,%esp
8010177c:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(ip->type == T_DEV){
8010177f:	8b 45 08             	mov    0x8(%ebp),%eax
80101782:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101787:	74 2c                	je     801017b5 <readi+0x42>
  if(off > ip->size || off + n < off)
80101789:	8b 45 08             	mov    0x8(%ebp),%eax
8010178c:	8b 40 58             	mov    0x58(%eax),%eax
8010178f:	39 f8                	cmp    %edi,%eax
80101791:	0f 82 cb 00 00 00    	jb     80101862 <readi+0xef>
80101797:	89 fa                	mov    %edi,%edx
80101799:	03 55 14             	add    0x14(%ebp),%edx
8010179c:	0f 82 c7 00 00 00    	jb     80101869 <readi+0xf6>
  if(off + n > ip->size)
801017a2:	39 d0                	cmp    %edx,%eax
801017a4:	73 05                	jae    801017ab <readi+0x38>
    n = ip->size - off;
801017a6:	29 f8                	sub    %edi,%eax
801017a8:	89 45 14             	mov    %eax,0x14(%ebp)
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801017ab:	be 00 00 00 00       	mov    $0x0,%esi
801017b0:	e9 8f 00 00 00       	jmp    80101844 <readi+0xd1>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801017b5:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801017b9:	66 83 f8 09          	cmp    $0x9,%ax
801017bd:	0f 87 91 00 00 00    	ja     80101854 <readi+0xe1>
801017c3:	98                   	cwtl   
801017c4:	8b 04 c5 60 09 11 80 	mov    -0x7feef6a0(,%eax,8),%eax
801017cb:	85 c0                	test   %eax,%eax
801017cd:	0f 84 88 00 00 00    	je     8010185b <readi+0xe8>
    return devsw[ip->major].read(ip, dst, n);
801017d3:	83 ec 04             	sub    $0x4,%esp
801017d6:	ff 75 14             	pushl  0x14(%ebp)
801017d9:	ff 75 0c             	pushl  0xc(%ebp)
801017dc:	ff 75 08             	pushl  0x8(%ebp)
801017df:	ff d0                	call   *%eax
801017e1:	83 c4 10             	add    $0x10,%esp
801017e4:	eb 66                	jmp    8010184c <readi+0xd9>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801017e6:	89 fa                	mov    %edi,%edx
801017e8:	c1 ea 09             	shr    $0x9,%edx
801017eb:	8b 45 08             	mov    0x8(%ebp),%eax
801017ee:	e8 ee f8 ff ff       	call   801010e1 <bmap>
801017f3:	83 ec 08             	sub    $0x8,%esp
801017f6:	50                   	push   %eax
801017f7:	8b 45 08             	mov    0x8(%ebp),%eax
801017fa:	ff 30                	pushl  (%eax)
801017fc:	e8 6b e9 ff ff       	call   8010016c <bread>
80101801:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
80101803:	89 f8                	mov    %edi,%eax
80101805:	25 ff 01 00 00       	and    $0x1ff,%eax
8010180a:	bb 00 02 00 00       	mov    $0x200,%ebx
8010180f:	29 c3                	sub    %eax,%ebx
80101811:	8b 55 14             	mov    0x14(%ebp),%edx
80101814:	29 f2                	sub    %esi,%edx
80101816:	83 c4 0c             	add    $0xc,%esp
80101819:	39 d3                	cmp    %edx,%ebx
8010181b:	0f 47 da             	cmova  %edx,%ebx
    memmove(dst, bp->data + off%BSIZE, m);
8010181e:	53                   	push   %ebx
8010181f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
80101822:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
80101826:	50                   	push   %eax
80101827:	ff 75 0c             	pushl  0xc(%ebp)
8010182a:	e8 bb 26 00 00       	call   80103eea <memmove>
    brelse(bp);
8010182f:	83 c4 04             	add    $0x4,%esp
80101832:	ff 75 e4             	pushl  -0x1c(%ebp)
80101835:	e8 9b e9 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010183a:	01 de                	add    %ebx,%esi
8010183c:	01 df                	add    %ebx,%edi
8010183e:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101841:	83 c4 10             	add    $0x10,%esp
80101844:	39 75 14             	cmp    %esi,0x14(%ebp)
80101847:	77 9d                	ja     801017e6 <readi+0x73>
  return n;
80101849:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010184c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010184f:	5b                   	pop    %ebx
80101850:	5e                   	pop    %esi
80101851:	5f                   	pop    %edi
80101852:	5d                   	pop    %ebp
80101853:	c3                   	ret    
      return -1;
80101854:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101859:	eb f1                	jmp    8010184c <readi+0xd9>
8010185b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101860:	eb ea                	jmp    8010184c <readi+0xd9>
    return -1;
80101862:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101867:	eb e3                	jmp    8010184c <readi+0xd9>
80101869:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010186e:	eb dc                	jmp    8010184c <readi+0xd9>

80101870 <writei>:
{
80101870:	55                   	push   %ebp
80101871:	89 e5                	mov    %esp,%ebp
80101873:	57                   	push   %edi
80101874:	56                   	push   %esi
80101875:	53                   	push   %ebx
80101876:	83 ec 0c             	sub    $0xc,%esp
  if(ip->type == T_DEV){
80101879:	8b 45 08             	mov    0x8(%ebp),%eax
8010187c:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101881:	74 2f                	je     801018b2 <writei+0x42>
  if(off > ip->size || off + n < off)
80101883:	8b 45 08             	mov    0x8(%ebp),%eax
80101886:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101889:	39 48 58             	cmp    %ecx,0x58(%eax)
8010188c:	0f 82 f4 00 00 00    	jb     80101986 <writei+0x116>
80101892:	89 c8                	mov    %ecx,%eax
80101894:	03 45 14             	add    0x14(%ebp),%eax
80101897:	0f 82 f0 00 00 00    	jb     8010198d <writei+0x11d>
  if(off + n > MAXFILE*BSIZE)
8010189d:	3d 00 18 01 00       	cmp    $0x11800,%eax
801018a2:	0f 87 ec 00 00 00    	ja     80101994 <writei+0x124>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801018a8:	be 00 00 00 00       	mov    $0x0,%esi
801018ad:	e9 94 00 00 00       	jmp    80101946 <writei+0xd6>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801018b2:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801018b6:	66 83 f8 09          	cmp    $0x9,%ax
801018ba:	0f 87 b8 00 00 00    	ja     80101978 <writei+0x108>
801018c0:	98                   	cwtl   
801018c1:	8b 04 c5 64 09 11 80 	mov    -0x7feef69c(,%eax,8),%eax
801018c8:	85 c0                	test   %eax,%eax
801018ca:	0f 84 af 00 00 00    	je     8010197f <writei+0x10f>
    return devsw[ip->major].write(ip, src, n);
801018d0:	83 ec 04             	sub    $0x4,%esp
801018d3:	ff 75 14             	pushl  0x14(%ebp)
801018d6:	ff 75 0c             	pushl  0xc(%ebp)
801018d9:	ff 75 08             	pushl  0x8(%ebp)
801018dc:	ff d0                	call   *%eax
801018de:	83 c4 10             	add    $0x10,%esp
801018e1:	eb 7c                	jmp    8010195f <writei+0xef>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801018e3:	8b 55 10             	mov    0x10(%ebp),%edx
801018e6:	c1 ea 09             	shr    $0x9,%edx
801018e9:	8b 45 08             	mov    0x8(%ebp),%eax
801018ec:	e8 f0 f7 ff ff       	call   801010e1 <bmap>
801018f1:	83 ec 08             	sub    $0x8,%esp
801018f4:	50                   	push   %eax
801018f5:	8b 45 08             	mov    0x8(%ebp),%eax
801018f8:	ff 30                	pushl  (%eax)
801018fa:	e8 6d e8 ff ff       	call   8010016c <bread>
801018ff:	89 c7                	mov    %eax,%edi
    m = min(n - tot, BSIZE - off%BSIZE);
80101901:	8b 45 10             	mov    0x10(%ebp),%eax
80101904:	25 ff 01 00 00       	and    $0x1ff,%eax
80101909:	bb 00 02 00 00       	mov    $0x200,%ebx
8010190e:	29 c3                	sub    %eax,%ebx
80101910:	8b 55 14             	mov    0x14(%ebp),%edx
80101913:	29 f2                	sub    %esi,%edx
80101915:	83 c4 0c             	add    $0xc,%esp
80101918:	39 d3                	cmp    %edx,%ebx
8010191a:	0f 47 da             	cmova  %edx,%ebx
    memmove(bp->data + off%BSIZE, src, m);
8010191d:	53                   	push   %ebx
8010191e:	ff 75 0c             	pushl  0xc(%ebp)
80101921:	8d 44 07 5c          	lea    0x5c(%edi,%eax,1),%eax
80101925:	50                   	push   %eax
80101926:	e8 bf 25 00 00       	call   80103eea <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 3a 11 00 00       	call   80102a6d <log_write>
    brelse(bp);
80101933:	89 3c 24             	mov    %edi,(%esp)
80101936:	e8 9a e8 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010193b:	01 de                	add    %ebx,%esi
8010193d:	01 5d 10             	add    %ebx,0x10(%ebp)
80101940:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101943:	83 c4 10             	add    $0x10,%esp
80101946:	3b 75 14             	cmp    0x14(%ebp),%esi
80101949:	72 98                	jb     801018e3 <writei+0x73>
  if(n > 0 && off > ip->size){
8010194b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010194f:	74 0b                	je     8010195c <writei+0xec>
80101951:	8b 45 08             	mov    0x8(%ebp),%eax
80101954:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101957:	39 48 58             	cmp    %ecx,0x58(%eax)
8010195a:	72 0b                	jb     80101967 <writei+0xf7>
  return n;
8010195c:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010195f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101962:	5b                   	pop    %ebx
80101963:	5e                   	pop    %esi
80101964:	5f                   	pop    %edi
80101965:	5d                   	pop    %ebp
80101966:	c3                   	ret    
    ip->size = off;
80101967:	89 48 58             	mov    %ecx,0x58(%eax)
    iupdate(ip);
8010196a:	83 ec 0c             	sub    $0xc,%esp
8010196d:	50                   	push   %eax
8010196e:	e8 ad fa ff ff       	call   80101420 <iupdate>
80101973:	83 c4 10             	add    $0x10,%esp
80101976:	eb e4                	jmp    8010195c <writei+0xec>
      return -1;
80101978:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010197d:	eb e0                	jmp    8010195f <writei+0xef>
8010197f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101984:	eb d9                	jmp    8010195f <writei+0xef>
    return -1;
80101986:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010198b:	eb d2                	jmp    8010195f <writei+0xef>
8010198d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101992:	eb cb                	jmp    8010195f <writei+0xef>
    return -1;
80101994:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101999:	eb c4                	jmp    8010195f <writei+0xef>

8010199b <namecmp>:
{
8010199b:	55                   	push   %ebp
8010199c:	89 e5                	mov    %esp,%ebp
8010199e:	83 ec 0c             	sub    $0xc,%esp
  return strncmp(s, t, DIRSIZ);
801019a1:	6a 0e                	push   $0xe
801019a3:	ff 75 0c             	pushl  0xc(%ebp)
801019a6:	ff 75 08             	pushl  0x8(%ebp)
801019a9:	e8 a3 25 00 00       	call   80103f51 <strncmp>
}
801019ae:	c9                   	leave  
801019af:	c3                   	ret    

801019b0 <dirlookup>:
{
801019b0:	55                   	push   %ebp
801019b1:	89 e5                	mov    %esp,%ebp
801019b3:	57                   	push   %edi
801019b4:	56                   	push   %esi
801019b5:	53                   	push   %ebx
801019b6:	83 ec 1c             	sub    $0x1c,%esp
801019b9:	8b 75 08             	mov    0x8(%ebp),%esi
801019bc:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if(dp->type != T_DIR)
801019bf:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801019c4:	75 07                	jne    801019cd <dirlookup+0x1d>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019c6:	bb 00 00 00 00       	mov    $0x0,%ebx
801019cb:	eb 1d                	jmp    801019ea <dirlookup+0x3a>
    panic("dirlookup not DIR");
801019cd:	83 ec 0c             	sub    $0xc,%esp
801019d0:	68 27 68 10 80       	push   $0x80106827
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 39 68 10 80       	push   $0x80106839
801019e2:	e8 61 e9 ff ff       	call   80100348 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019e7:	83 c3 10             	add    $0x10,%ebx
801019ea:	39 5e 58             	cmp    %ebx,0x58(%esi)
801019ed:	76 48                	jbe    80101a37 <dirlookup+0x87>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801019ef:	6a 10                	push   $0x10
801019f1:	53                   	push   %ebx
801019f2:	8d 45 d8             	lea    -0x28(%ebp),%eax
801019f5:	50                   	push   %eax
801019f6:	56                   	push   %esi
801019f7:	e8 77 fd ff ff       	call   80101773 <readi>
801019fc:	83 c4 10             	add    $0x10,%esp
801019ff:	83 f8 10             	cmp    $0x10,%eax
80101a02:	75 d6                	jne    801019da <dirlookup+0x2a>
    if(de.inum == 0)
80101a04:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101a09:	74 dc                	je     801019e7 <dirlookup+0x37>
    if(namecmp(name, de.name) == 0){
80101a0b:	83 ec 08             	sub    $0x8,%esp
80101a0e:	8d 45 da             	lea    -0x26(%ebp),%eax
80101a11:	50                   	push   %eax
80101a12:	57                   	push   %edi
80101a13:	e8 83 ff ff ff       	call   8010199b <namecmp>
80101a18:	83 c4 10             	add    $0x10,%esp
80101a1b:	85 c0                	test   %eax,%eax
80101a1d:	75 c8                	jne    801019e7 <dirlookup+0x37>
      if(poff)
80101a1f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80101a23:	74 05                	je     80101a2a <dirlookup+0x7a>
        *poff = off;
80101a25:	8b 45 10             	mov    0x10(%ebp),%eax
80101a28:	89 18                	mov    %ebx,(%eax)
      inum = de.inum;
80101a2a:	0f b7 55 d8          	movzwl -0x28(%ebp),%edx
      return iget(dp->dev, inum);
80101a2e:	8b 06                	mov    (%esi),%eax
80101a30:	e8 52 f7 ff ff       	call   80101187 <iget>
80101a35:	eb 05                	jmp    80101a3c <dirlookup+0x8c>
  return 0;
80101a37:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101a3c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a3f:	5b                   	pop    %ebx
80101a40:	5e                   	pop    %esi
80101a41:	5f                   	pop    %edi
80101a42:	5d                   	pop    %ebp
80101a43:	c3                   	ret    

80101a44 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80101a44:	55                   	push   %ebp
80101a45:	89 e5                	mov    %esp,%ebp
80101a47:	57                   	push   %edi
80101a48:	56                   	push   %esi
80101a49:	53                   	push   %ebx
80101a4a:	83 ec 1c             	sub    $0x1c,%esp
80101a4d:	89 c6                	mov    %eax,%esi
80101a4f:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101a52:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
80101a55:	80 38 2f             	cmpb   $0x2f,(%eax)
80101a58:	74 17                	je     80101a71 <namex+0x2d>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
80101a5a:	e8 46 19 00 00       	call   801033a5 <myproc>
80101a5f:	83 ec 0c             	sub    $0xc,%esp
80101a62:	ff 70 68             	pushl  0x68(%eax)
80101a65:	e8 e7 fa ff ff       	call   80101551 <idup>
80101a6a:	89 c3                	mov    %eax,%ebx
80101a6c:	83 c4 10             	add    $0x10,%esp
80101a6f:	eb 53                	jmp    80101ac4 <namex+0x80>
    ip = iget(ROOTDEV, ROOTINO);
80101a71:	ba 01 00 00 00       	mov    $0x1,%edx
80101a76:	b8 01 00 00 00       	mov    $0x1,%eax
80101a7b:	e8 07 f7 ff ff       	call   80101187 <iget>
80101a80:	89 c3                	mov    %eax,%ebx
80101a82:	eb 40                	jmp    80101ac4 <namex+0x80>

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
      iunlockput(ip);
80101a84:	83 ec 0c             	sub    $0xc,%esp
80101a87:	53                   	push   %ebx
80101a88:	e8 9b fc ff ff       	call   80101728 <iunlockput>
      return 0;
80101a8d:	83 c4 10             	add    $0x10,%esp
80101a90:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
80101a95:	89 d8                	mov    %ebx,%eax
80101a97:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a9a:	5b                   	pop    %ebx
80101a9b:	5e                   	pop    %esi
80101a9c:	5f                   	pop    %edi
80101a9d:	5d                   	pop    %ebp
80101a9e:	c3                   	ret    
    if((next = dirlookup(ip, name, 0)) == 0){
80101a9f:	83 ec 04             	sub    $0x4,%esp
80101aa2:	6a 00                	push   $0x0
80101aa4:	ff 75 e4             	pushl  -0x1c(%ebp)
80101aa7:	53                   	push   %ebx
80101aa8:	e8 03 ff ff ff       	call   801019b0 <dirlookup>
80101aad:	89 c7                	mov    %eax,%edi
80101aaf:	83 c4 10             	add    $0x10,%esp
80101ab2:	85 c0                	test   %eax,%eax
80101ab4:	74 4a                	je     80101b00 <namex+0xbc>
    iunlockput(ip);
80101ab6:	83 ec 0c             	sub    $0xc,%esp
80101ab9:	53                   	push   %ebx
80101aba:	e8 69 fc ff ff       	call   80101728 <iunlockput>
    ip = next;
80101abf:	83 c4 10             	add    $0x10,%esp
80101ac2:	89 fb                	mov    %edi,%ebx
  while((path = skipelem(path, name)) != 0){
80101ac4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101ac7:	89 f0                	mov    %esi,%eax
80101ac9:	e8 77 f4 ff ff       	call   80100f45 <skipelem>
80101ace:	89 c6                	mov    %eax,%esi
80101ad0:	85 c0                	test   %eax,%eax
80101ad2:	74 3c                	je     80101b10 <namex+0xcc>
    ilock(ip);
80101ad4:	83 ec 0c             	sub    $0xc,%esp
80101ad7:	53                   	push   %ebx
80101ad8:	e8 a4 fa ff ff       	call   80101581 <ilock>
    if(ip->type != T_DIR){
80101add:	83 c4 10             	add    $0x10,%esp
80101ae0:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80101ae5:	75 9d                	jne    80101a84 <namex+0x40>
    if(nameiparent && *path == '\0'){
80101ae7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101aeb:	74 b2                	je     80101a9f <namex+0x5b>
80101aed:	80 3e 00             	cmpb   $0x0,(%esi)
80101af0:	75 ad                	jne    80101a9f <namex+0x5b>
      iunlock(ip);
80101af2:	83 ec 0c             	sub    $0xc,%esp
80101af5:	53                   	push   %ebx
80101af6:	e8 48 fb ff ff       	call   80101643 <iunlock>
      return ip;
80101afb:	83 c4 10             	add    $0x10,%esp
80101afe:	eb 95                	jmp    80101a95 <namex+0x51>
      iunlockput(ip);
80101b00:	83 ec 0c             	sub    $0xc,%esp
80101b03:	53                   	push   %ebx
80101b04:	e8 1f fc ff ff       	call   80101728 <iunlockput>
      return 0;
80101b09:	83 c4 10             	add    $0x10,%esp
80101b0c:	89 fb                	mov    %edi,%ebx
80101b0e:	eb 85                	jmp    80101a95 <namex+0x51>
  if(nameiparent){
80101b10:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b14:	0f 84 7b ff ff ff    	je     80101a95 <namex+0x51>
    iput(ip);
80101b1a:	83 ec 0c             	sub    $0xc,%esp
80101b1d:	53                   	push   %ebx
80101b1e:	e8 65 fb ff ff       	call   80101688 <iput>
    return 0;
80101b23:	83 c4 10             	add    $0x10,%esp
80101b26:	bb 00 00 00 00       	mov    $0x0,%ebx
80101b2b:	e9 65 ff ff ff       	jmp    80101a95 <namex+0x51>

80101b30 <dirlink>:
{
80101b30:	55                   	push   %ebp
80101b31:	89 e5                	mov    %esp,%ebp
80101b33:	57                   	push   %edi
80101b34:	56                   	push   %esi
80101b35:	53                   	push   %ebx
80101b36:	83 ec 20             	sub    $0x20,%esp
80101b39:	8b 5d 08             	mov    0x8(%ebp),%ebx
80101b3c:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if((ip = dirlookup(dp, name, 0)) != 0){
80101b3f:	6a 00                	push   $0x0
80101b41:	57                   	push   %edi
80101b42:	53                   	push   %ebx
80101b43:	e8 68 fe ff ff       	call   801019b0 <dirlookup>
80101b48:	83 c4 10             	add    $0x10,%esp
80101b4b:	85 c0                	test   %eax,%eax
80101b4d:	75 2d                	jne    80101b7c <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b4f:	b8 00 00 00 00       	mov    $0x0,%eax
80101b54:	89 c6                	mov    %eax,%esi
80101b56:	39 43 58             	cmp    %eax,0x58(%ebx)
80101b59:	76 41                	jbe    80101b9c <dirlink+0x6c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101b5b:	6a 10                	push   $0x10
80101b5d:	50                   	push   %eax
80101b5e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101b61:	50                   	push   %eax
80101b62:	53                   	push   %ebx
80101b63:	e8 0b fc ff ff       	call   80101773 <readi>
80101b68:	83 c4 10             	add    $0x10,%esp
80101b6b:	83 f8 10             	cmp    $0x10,%eax
80101b6e:	75 1f                	jne    80101b8f <dirlink+0x5f>
    if(de.inum == 0)
80101b70:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101b75:	74 25                	je     80101b9c <dirlink+0x6c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b77:	8d 46 10             	lea    0x10(%esi),%eax
80101b7a:	eb d8                	jmp    80101b54 <dirlink+0x24>
    iput(ip);
80101b7c:	83 ec 0c             	sub    $0xc,%esp
80101b7f:	50                   	push   %eax
80101b80:	e8 03 fb ff ff       	call   80101688 <iput>
    return -1;
80101b85:	83 c4 10             	add    $0x10,%esp
80101b88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101b8d:	eb 3d                	jmp    80101bcc <dirlink+0x9c>
      panic("dirlink read");
80101b8f:	83 ec 0c             	sub    $0xc,%esp
80101b92:	68 48 68 10 80       	push   $0x80106848
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 e0 23 00 00       	call   80103f8e <strncpy>
  de.inum = inum;
80101bae:	8b 45 10             	mov    0x10(%ebp),%eax
80101bb1:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101bb5:	6a 10                	push   $0x10
80101bb7:	56                   	push   %esi
80101bb8:	57                   	push   %edi
80101bb9:	53                   	push   %ebx
80101bba:	e8 b1 fc ff ff       	call   80101870 <writei>
80101bbf:	83 c4 20             	add    $0x20,%esp
80101bc2:	83 f8 10             	cmp    $0x10,%eax
80101bc5:	75 0d                	jne    80101bd4 <dirlink+0xa4>
  return 0;
80101bc7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101bcc:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101bcf:	5b                   	pop    %ebx
80101bd0:	5e                   	pop    %esi
80101bd1:	5f                   	pop    %edi
80101bd2:	5d                   	pop    %ebp
80101bd3:	c3                   	ret    
    panic("dirlink");
80101bd4:	83 ec 0c             	sub    $0xc,%esp
80101bd7:	68 54 6e 10 80       	push   $0x80106e54
80101bdc:	e8 67 e7 ff ff       	call   80100348 <panic>

80101be1 <namei>:

struct inode*
namei(char *path)
{
80101be1:	55                   	push   %ebp
80101be2:	89 e5                	mov    %esp,%ebp
80101be4:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80101be7:	8d 4d ea             	lea    -0x16(%ebp),%ecx
80101bea:	ba 00 00 00 00       	mov    $0x0,%edx
80101bef:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf2:	e8 4d fe ff ff       	call   80101a44 <namex>
}
80101bf7:	c9                   	leave  
80101bf8:	c3                   	ret    

80101bf9 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80101bf9:	55                   	push   %ebp
80101bfa:	89 e5                	mov    %esp,%ebp
80101bfc:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80101bff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80101c02:	ba 01 00 00 00       	mov    $0x1,%edx
80101c07:	8b 45 08             	mov    0x8(%ebp),%eax
80101c0a:	e8 35 fe ff ff       	call   80101a44 <namex>
}
80101c0f:	c9                   	leave  
80101c10:	c3                   	ret    

80101c11 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80101c11:	55                   	push   %ebp
80101c12:	89 e5                	mov    %esp,%ebp
80101c14:	89 c1                	mov    %eax,%ecx
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101c16:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101c1b:	ec                   	in     (%dx),%al
80101c1c:	89 c2                	mov    %eax,%edx
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80101c1e:	83 e0 c0             	and    $0xffffffc0,%eax
80101c21:	3c 40                	cmp    $0x40,%al
80101c23:	75 f1                	jne    80101c16 <idewait+0x5>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80101c25:	85 c9                	test   %ecx,%ecx
80101c27:	74 0c                	je     80101c35 <idewait+0x24>
80101c29:	f6 c2 21             	test   $0x21,%dl
80101c2c:	75 0e                	jne    80101c3c <idewait+0x2b>
    return -1;
  return 0;
80101c2e:	b8 00 00 00 00       	mov    $0x0,%eax
80101c33:	eb 05                	jmp    80101c3a <idewait+0x29>
80101c35:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101c3a:	5d                   	pop    %ebp
80101c3b:	c3                   	ret    
    return -1;
80101c3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101c41:	eb f7                	jmp    80101c3a <idewait+0x29>

80101c43 <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80101c43:	55                   	push   %ebp
80101c44:	89 e5                	mov    %esp,%ebp
80101c46:	56                   	push   %esi
80101c47:	53                   	push   %ebx
  if(b == 0)
80101c48:	85 c0                	test   %eax,%eax
80101c4a:	74 7d                	je     80101cc9 <idestart+0x86>
80101c4c:	89 c6                	mov    %eax,%esi
    panic("idestart");
  if(b->blockno >= FSSIZE)
80101c4e:	8b 58 08             	mov    0x8(%eax),%ebx
80101c51:	81 fb e7 03 00 00    	cmp    $0x3e7,%ebx
80101c57:	77 7d                	ja     80101cd6 <idestart+0x93>
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;

  if (sector_per_block > 7) panic("idestart");

  idewait(0);
80101c59:	b8 00 00 00 00       	mov    $0x0,%eax
80101c5e:	e8 ae ff ff ff       	call   80101c11 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101c63:	b8 00 00 00 00       	mov    $0x0,%eax
80101c68:	ba f6 03 00 00       	mov    $0x3f6,%edx
80101c6d:	ee                   	out    %al,(%dx)
80101c6e:	b8 01 00 00 00       	mov    $0x1,%eax
80101c73:	ba f2 01 00 00       	mov    $0x1f2,%edx
80101c78:	ee                   	out    %al,(%dx)
80101c79:	ba f3 01 00 00       	mov    $0x1f3,%edx
80101c7e:	89 d8                	mov    %ebx,%eax
80101c80:	ee                   	out    %al,(%dx)
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, sector_per_block);  // number of sectors
  outb(0x1f3, sector & 0xff);
  outb(0x1f4, (sector >> 8) & 0xff);
80101c81:	89 d8                	mov    %ebx,%eax
80101c83:	c1 f8 08             	sar    $0x8,%eax
80101c86:	ba f4 01 00 00       	mov    $0x1f4,%edx
80101c8b:	ee                   	out    %al,(%dx)
  outb(0x1f5, (sector >> 16) & 0xff);
80101c8c:	89 d8                	mov    %ebx,%eax
80101c8e:	c1 f8 10             	sar    $0x10,%eax
80101c91:	ba f5 01 00 00       	mov    $0x1f5,%edx
80101c96:	ee                   	out    %al,(%dx)
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80101c97:	0f b6 46 04          	movzbl 0x4(%esi),%eax
80101c9b:	c1 e0 04             	shl    $0x4,%eax
80101c9e:	83 e0 10             	and    $0x10,%eax
80101ca1:	c1 fb 18             	sar    $0x18,%ebx
80101ca4:	83 e3 0f             	and    $0xf,%ebx
80101ca7:	09 d8                	or     %ebx,%eax
80101ca9:	83 c8 e0             	or     $0xffffffe0,%eax
80101cac:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101cb1:	ee                   	out    %al,(%dx)
  if(b->flags & B_DIRTY){
80101cb2:	f6 06 04             	testb  $0x4,(%esi)
80101cb5:	75 2c                	jne    80101ce3 <idestart+0xa0>
80101cb7:	b8 20 00 00 00       	mov    $0x20,%eax
80101cbc:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101cc1:	ee                   	out    %al,(%dx)
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
  } else {
    outb(0x1f7, read_cmd);
  }
}
80101cc2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101cc5:	5b                   	pop    %ebx
80101cc6:	5e                   	pop    %esi
80101cc7:	5d                   	pop    %ebp
80101cc8:	c3                   	ret    
    panic("idestart");
80101cc9:	83 ec 0c             	sub    $0xc,%esp
80101ccc:	68 ab 68 10 80       	push   $0x801068ab
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 b4 68 10 80       	push   $0x801068b4
80101cde:	e8 65 e6 ff ff       	call   80100348 <panic>
80101ce3:	b8 30 00 00 00       	mov    $0x30,%eax
80101ce8:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101ced:	ee                   	out    %al,(%dx)
    outsl(0x1f0, b->data, BSIZE/4);
80101cee:	83 c6 5c             	add    $0x5c,%esi
  asm volatile("cld; rep outsl" :
80101cf1:	b9 80 00 00 00       	mov    $0x80,%ecx
80101cf6:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101cfb:	fc                   	cld    
80101cfc:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80101cfe:	eb c2                	jmp    80101cc2 <idestart+0x7f>

80101d00 <ideinit>:
{
80101d00:	55                   	push   %ebp
80101d01:	89 e5                	mov    %esp,%ebp
80101d03:	83 ec 10             	sub    $0x10,%esp
  initlock(&idelock, "ide");
80101d06:	68 c6 68 10 80       	push   $0x801068c6
80101d0b:	68 80 a5 10 80       	push   $0x8010a580
80101d10:	e8 72 1f 00 00       	call   80103c87 <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d15:	83 c4 08             	add    $0x8,%esp
80101d18:	a1 20 2d 15 80       	mov    0x80152d20,%eax
80101d1d:	83 e8 01             	sub    $0x1,%eax
80101d20:	50                   	push   %eax
80101d21:	6a 0e                	push   $0xe
80101d23:	e8 56 02 00 00       	call   80101f7e <ioapicenable>
  idewait(0);
80101d28:	b8 00 00 00 00       	mov    $0x0,%eax
80101d2d:	e8 df fe ff ff       	call   80101c11 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d32:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
80101d37:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d3c:	ee                   	out    %al,(%dx)
  for(i=0; i<1000; i++){
80101d3d:	83 c4 10             	add    $0x10,%esp
80101d40:	b9 00 00 00 00       	mov    $0x0,%ecx
80101d45:	81 f9 e7 03 00 00    	cmp    $0x3e7,%ecx
80101d4b:	7f 19                	jg     80101d66 <ideinit+0x66>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101d4d:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101d52:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
80101d53:	84 c0                	test   %al,%al
80101d55:	75 05                	jne    80101d5c <ideinit+0x5c>
  for(i=0; i<1000; i++){
80101d57:	83 c1 01             	add    $0x1,%ecx
80101d5a:	eb e9                	jmp    80101d45 <ideinit+0x45>
      havedisk1 = 1;
80101d5c:	c7 05 60 a5 10 80 01 	movl   $0x1,0x8010a560
80101d63:	00 00 00 
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d66:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
80101d6b:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d70:	ee                   	out    %al,(%dx)
}
80101d71:	c9                   	leave  
80101d72:	c3                   	ret    

80101d73 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80101d73:	55                   	push   %ebp
80101d74:	89 e5                	mov    %esp,%ebp
80101d76:	57                   	push   %edi
80101d77:	53                   	push   %ebx
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80101d78:	83 ec 0c             	sub    $0xc,%esp
80101d7b:	68 80 a5 10 80       	push   $0x8010a580
80101d80:	e8 3e 20 00 00       	call   80103dc3 <acquire>

  if((b = idequeue) == 0){
80101d85:	8b 1d 64 a5 10 80    	mov    0x8010a564,%ebx
80101d8b:	83 c4 10             	add    $0x10,%esp
80101d8e:	85 db                	test   %ebx,%ebx
80101d90:	74 48                	je     80101dda <ideintr+0x67>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101d92:	8b 43 58             	mov    0x58(%ebx),%eax
80101d95:	a3 64 a5 10 80       	mov    %eax,0x8010a564

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101d9a:	f6 03 04             	testb  $0x4,(%ebx)
80101d9d:	74 4d                	je     80101dec <ideintr+0x79>
    insl(0x1f0, b->data, BSIZE/4);

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80101d9f:	8b 03                	mov    (%ebx),%eax
80101da1:	83 c8 02             	or     $0x2,%eax
  b->flags &= ~B_DIRTY;
80101da4:	83 e0 fb             	and    $0xfffffffb,%eax
80101da7:	89 03                	mov    %eax,(%ebx)
  wakeup(b);
80101da9:	83 ec 0c             	sub    $0xc,%esp
80101dac:	53                   	push   %ebx
80101dad:	e8 fc 1b 00 00       	call   801039ae <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101db2:	a1 64 a5 10 80       	mov    0x8010a564,%eax
80101db7:	83 c4 10             	add    $0x10,%esp
80101dba:	85 c0                	test   %eax,%eax
80101dbc:	74 05                	je     80101dc3 <ideintr+0x50>
    idestart(idequeue);
80101dbe:	e8 80 fe ff ff       	call   80101c43 <idestart>

  release(&idelock);
80101dc3:	83 ec 0c             	sub    $0xc,%esp
80101dc6:	68 80 a5 10 80       	push   $0x8010a580
80101dcb:	e8 58 20 00 00       	call   80103e28 <release>
80101dd0:	83 c4 10             	add    $0x10,%esp
}
80101dd3:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101dd6:	5b                   	pop    %ebx
80101dd7:	5f                   	pop    %edi
80101dd8:	5d                   	pop    %ebp
80101dd9:	c3                   	ret    
    release(&idelock);
80101dda:	83 ec 0c             	sub    $0xc,%esp
80101ddd:	68 80 a5 10 80       	push   $0x8010a580
80101de2:	e8 41 20 00 00       	call   80103e28 <release>
    return;
80101de7:	83 c4 10             	add    $0x10,%esp
80101dea:	eb e7                	jmp    80101dd3 <ideintr+0x60>
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101dec:	b8 01 00 00 00       	mov    $0x1,%eax
80101df1:	e8 1b fe ff ff       	call   80101c11 <idewait>
80101df6:	85 c0                	test   %eax,%eax
80101df8:	78 a5                	js     80101d9f <ideintr+0x2c>
    insl(0x1f0, b->data, BSIZE/4);
80101dfa:	8d 7b 5c             	lea    0x5c(%ebx),%edi
  asm volatile("cld; rep insl" :
80101dfd:	b9 80 00 00 00       	mov    $0x80,%ecx
80101e02:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101e07:	fc                   	cld    
80101e08:	f3 6d                	rep insl (%dx),%es:(%edi)
80101e0a:	eb 93                	jmp    80101d9f <ideintr+0x2c>

80101e0c <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80101e0c:	55                   	push   %ebp
80101e0d:	89 e5                	mov    %esp,%ebp
80101e0f:	53                   	push   %ebx
80101e10:	83 ec 10             	sub    $0x10,%esp
80101e13:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80101e16:	8d 43 0c             	lea    0xc(%ebx),%eax
80101e19:	50                   	push   %eax
80101e1a:	e8 1a 1e 00 00       	call   80103c39 <holdingsleep>
80101e1f:	83 c4 10             	add    $0x10,%esp
80101e22:	85 c0                	test   %eax,%eax
80101e24:	74 37                	je     80101e5d <iderw+0x51>
    panic("iderw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80101e26:	8b 03                	mov    (%ebx),%eax
80101e28:	83 e0 06             	and    $0x6,%eax
80101e2b:	83 f8 02             	cmp    $0x2,%eax
80101e2e:	74 3a                	je     80101e6a <iderw+0x5e>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
80101e30:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80101e34:	74 09                	je     80101e3f <iderw+0x33>
80101e36:	83 3d 60 a5 10 80 00 	cmpl   $0x0,0x8010a560
80101e3d:	74 38                	je     80101e77 <iderw+0x6b>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101e3f:	83 ec 0c             	sub    $0xc,%esp
80101e42:	68 80 a5 10 80       	push   $0x8010a580
80101e47:	e8 77 1f 00 00       	call   80103dc3 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 ca 68 10 80       	push   $0x801068ca
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 e0 68 10 80       	push   $0x801068e0
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 f5 68 10 80       	push   $0x801068f5
80101e7f:	e8 c4 e4 ff ff       	call   80100348 <panic>
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e84:	8d 50 58             	lea    0x58(%eax),%edx
80101e87:	8b 02                	mov    (%edx),%eax
80101e89:	85 c0                	test   %eax,%eax
80101e8b:	75 f7                	jne    80101e84 <iderw+0x78>
    ;
  *pp = b;
80101e8d:	89 1a                	mov    %ebx,(%edx)

  // Start disk if necessary.
  if(idequeue == b)
80101e8f:	39 1d 64 a5 10 80    	cmp    %ebx,0x8010a564
80101e95:	75 1a                	jne    80101eb1 <iderw+0xa5>
    idestart(b);
80101e97:	89 d8                	mov    %ebx,%eax
80101e99:	e8 a5 fd ff ff       	call   80101c43 <idestart>
80101e9e:	eb 11                	jmp    80101eb1 <iderw+0xa5>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101ea0:	83 ec 08             	sub    $0x8,%esp
80101ea3:	68 80 a5 10 80       	push   $0x8010a580
80101ea8:	53                   	push   %ebx
80101ea9:	e8 9b 19 00 00       	call   80103849 <sleep>
80101eae:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101eb1:	8b 03                	mov    (%ebx),%eax
80101eb3:	83 e0 06             	and    $0x6,%eax
80101eb6:	83 f8 02             	cmp    $0x2,%eax
80101eb9:	75 e5                	jne    80101ea0 <iderw+0x94>
  }


  release(&idelock);
80101ebb:	83 ec 0c             	sub    $0xc,%esp
80101ebe:	68 80 a5 10 80       	push   $0x8010a580
80101ec3:	e8 60 1f 00 00       	call   80103e28 <release>
}
80101ec8:	83 c4 10             	add    $0x10,%esp
80101ecb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101ece:	c9                   	leave  
80101ecf:	c3                   	ret    

80101ed0 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80101ed0:	55                   	push   %ebp
80101ed1:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ed3:	8b 15 34 26 11 80    	mov    0x80112634,%edx
80101ed9:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101edb:	a1 34 26 11 80       	mov    0x80112634,%eax
80101ee0:	8b 40 10             	mov    0x10(%eax),%eax
}
80101ee3:	5d                   	pop    %ebp
80101ee4:	c3                   	ret    

80101ee5 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80101ee5:	55                   	push   %ebp
80101ee6:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ee8:	8b 0d 34 26 11 80    	mov    0x80112634,%ecx
80101eee:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101ef0:	a1 34 26 11 80       	mov    0x80112634,%eax
80101ef5:	89 50 10             	mov    %edx,0x10(%eax)
}
80101ef8:	5d                   	pop    %ebp
80101ef9:	c3                   	ret    

80101efa <ioapicinit>:

void
ioapicinit(void)
{
80101efa:	55                   	push   %ebp
80101efb:	89 e5                	mov    %esp,%ebp
80101efd:	57                   	push   %edi
80101efe:	56                   	push   %esi
80101eff:	53                   	push   %ebx
80101f00:	83 ec 0c             	sub    $0xc,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80101f03:	c7 05 34 26 11 80 00 	movl   $0xfec00000,0x80112634
80101f0a:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80101f0d:	b8 01 00 00 00       	mov    $0x1,%eax
80101f12:	e8 b9 ff ff ff       	call   80101ed0 <ioapicread>
80101f17:	c1 e8 10             	shr    $0x10,%eax
80101f1a:	0f b6 f8             	movzbl %al,%edi
  id = ioapicread(REG_ID) >> 24;
80101f1d:	b8 00 00 00 00       	mov    $0x0,%eax
80101f22:	e8 a9 ff ff ff       	call   80101ed0 <ioapicread>
80101f27:	c1 e8 18             	shr    $0x18,%eax
  if(id != ioapicid)
80101f2a:	0f b6 15 80 27 15 80 	movzbl 0x80152780,%edx
80101f31:	39 c2                	cmp    %eax,%edx
80101f33:	75 07                	jne    80101f3c <ioapicinit+0x42>
{
80101f35:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f3a:	eb 36                	jmp    80101f72 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f3c:	83 ec 0c             	sub    $0xc,%esp
80101f3f:	68 14 69 10 80       	push   $0x80106914
80101f44:	e8 c2 e6 ff ff       	call   8010060b <cprintf>
80101f49:	83 c4 10             	add    $0x10,%esp
80101f4c:	eb e7                	jmp    80101f35 <ioapicinit+0x3b>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80101f4e:	8d 53 20             	lea    0x20(%ebx),%edx
80101f51:	81 ca 00 00 01 00    	or     $0x10000,%edx
80101f57:	8d 74 1b 10          	lea    0x10(%ebx,%ebx,1),%esi
80101f5b:	89 f0                	mov    %esi,%eax
80101f5d:	e8 83 ff ff ff       	call   80101ee5 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80101f62:	8d 46 01             	lea    0x1(%esi),%eax
80101f65:	ba 00 00 00 00       	mov    $0x0,%edx
80101f6a:	e8 76 ff ff ff       	call   80101ee5 <ioapicwrite>
  for(i = 0; i <= maxintr; i++){
80101f6f:	83 c3 01             	add    $0x1,%ebx
80101f72:	39 fb                	cmp    %edi,%ebx
80101f74:	7e d8                	jle    80101f4e <ioapicinit+0x54>
  }
}
80101f76:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101f79:	5b                   	pop    %ebx
80101f7a:	5e                   	pop    %esi
80101f7b:	5f                   	pop    %edi
80101f7c:	5d                   	pop    %ebp
80101f7d:	c3                   	ret    

80101f7e <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80101f7e:	55                   	push   %ebp
80101f7f:	89 e5                	mov    %esp,%ebp
80101f81:	53                   	push   %ebx
80101f82:	8b 45 08             	mov    0x8(%ebp),%eax
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80101f85:	8d 50 20             	lea    0x20(%eax),%edx
80101f88:	8d 5c 00 10          	lea    0x10(%eax,%eax,1),%ebx
80101f8c:	89 d8                	mov    %ebx,%eax
80101f8e:	e8 52 ff ff ff       	call   80101ee5 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80101f93:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f96:	c1 e2 18             	shl    $0x18,%edx
80101f99:	8d 43 01             	lea    0x1(%ebx),%eax
80101f9c:	e8 44 ff ff ff       	call   80101ee5 <ioapicwrite>
}
80101fa1:	5b                   	pop    %ebx
80101fa2:	5d                   	pop    %ebp
80101fa3:	c3                   	ret    

80101fa4 <getframesList>:
  struct af *aFrames;
} allocFrames;

int framesList[65536];
int* getframesList(void)
{
80101fa4:	55                   	push   %ebp
80101fa5:	89 e5                	mov    %esp,%ebp
  return framesList;
}
80101fa7:	b8 80 26 11 80       	mov    $0x80112680,%eax
80101fac:	5d                   	pop    %ebp
80101fad:	c3                   	ret    

80101fae <kfree>:
// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(char *v)
{
80101fae:	55                   	push   %ebp
80101faf:	89 e5                	mov    %esp,%ebp
80101fb1:	56                   	push   %esi
80101fb2:	53                   	push   %ebx
80101fb3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if ((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80101fb6:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80101fbc:	75 42                	jne    80102000 <kfree+0x52>
80101fbe:	81 fb c8 54 15 80    	cmp    $0x801554c8,%ebx
80101fc4:	72 3a                	jb     80102000 <kfree+0x52>
80101fc6:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
80101fcc:	81 fe ff ff ff 0d    	cmp    $0xdffffff,%esi
80101fd2:	77 2c                	ja     80102000 <kfree+0x52>
    panic("kfree");

  // cprintf("freeing: %x\n", V2P(v)>>12);

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fd4:	83 ec 04             	sub    $0x4,%esp
80101fd7:	68 00 10 00 00       	push   $0x1000
80101fdc:	6a 01                	push   $0x1
80101fde:	53                   	push   %ebx
80101fdf:	e8 8b 1e 00 00       	call   80103e6f <memset>

  if (kmem.use_lock)
80101fe4:	83 c4 10             	add    $0x10,%esp
80101fe7:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80101fee:	75 1d                	jne    8010200d <kfree+0x5f>
    acquire(&kmem.lock);
  r = (struct run *)v;
  r->pid = -1;
80101ff0:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
  //we need to ensure that the freelist is sorted when a freed frame is added. 
  //iterate through the freelist to find the frame that
  
  // if the freelist is empty add it to head.
  if(r > kmem.freelist) {
80101ff7:	a1 78 26 11 80       	mov    0x80112678,%eax
  } else {
    // if the list is not empty, find the first element smaller than 

  }
  struct run *curr = kmem.freelist;
  struct run *prev = kmem.freelist;
80101ffc:	89 c2                	mov    %eax,%edx
  while(r<curr) {
80101ffe:	eb 23                	jmp    80102023 <kfree+0x75>
    panic("kfree");
80102000:	83 ec 0c             	sub    $0xc,%esp
80102003:	68 46 69 10 80       	push   $0x80106946
80102008:	e8 3b e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200d:	83 ec 0c             	sub    $0xc,%esp
80102010:	68 40 26 11 80       	push   $0x80112640
80102015:	e8 a9 1d 00 00       	call   80103dc3 <acquire>
8010201a:	83 c4 10             	add    $0x10,%esp
8010201d:	eb d1                	jmp    80101ff0 <kfree+0x42>
    prev = curr;
8010201f:	89 c2                	mov    %eax,%edx
    curr = curr->next;
80102021:	8b 00                	mov    (%eax),%eax
  while(r<curr) {
80102023:	39 d8                	cmp    %ebx,%eax
80102025:	77 f8                	ja     8010201f <kfree+0x71>
  }
  curr->prev = r;
80102027:	89 58 08             	mov    %ebx,0x8(%eax)
  r->next = curr;
8010202a:	89 03                	mov    %eax,(%ebx)
  if(prev == kmem.freelist){
8010202c:	39 15 78 26 11 80    	cmp    %edx,0x80112678
80102032:	74 23                	je     80102057 <kfree+0xa9>
    kmem.freelist = r;
  } else{
    prev->next = r;
80102034:	89 1a                	mov    %ebx,(%edx)
    r->prev = prev;
80102036:	89 53 08             	mov    %edx,0x8(%ebx)
  }
  //find the frame being freed in the allocated list
  int i = V2P(r)>>12;
80102039:	c1 ee 0c             	shr    $0xc,%esi
  framesList[i] = 0;
8010203c:	c7 04 b5 80 26 11 80 	movl   $0x0,-0x7feed980(,%esi,4)
80102043:	00 00 00 00 
  // r->next = kmem.freelist;
  // kmem.freelist = r;
  
  if (kmem.use_lock)
80102047:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
8010204e:	75 0f                	jne    8010205f <kfree+0xb1>
    release(&kmem.lock);
}
80102050:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102053:	5b                   	pop    %ebx
80102054:	5e                   	pop    %esi
80102055:	5d                   	pop    %ebp
80102056:	c3                   	ret    
    kmem.freelist = r;
80102057:	89 1d 78 26 11 80    	mov    %ebx,0x80112678
8010205d:	eb da                	jmp    80102039 <kfree+0x8b>
    release(&kmem.lock);
8010205f:	83 ec 0c             	sub    $0xc,%esp
80102062:	68 40 26 11 80       	push   $0x80112640
80102067:	e8 bc 1d 00 00       	call   80103e28 <release>
8010206c:	83 c4 10             	add    $0x10,%esp
}
8010206f:	eb df                	jmp    80102050 <kfree+0xa2>

80102071 <kfree2>:
void kfree2(char *v)
{
80102071:	55                   	push   %ebp
80102072:	89 e5                	mov    %esp,%ebp
80102074:	56                   	push   %esi
80102075:	53                   	push   %ebx
80102076:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if ((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80102079:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
8010207f:	75 64                	jne    801020e5 <kfree2+0x74>
80102081:	81 fb c8 54 15 80    	cmp    $0x801554c8,%ebx
80102087:	72 5c                	jb     801020e5 <kfree2+0x74>
80102089:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
8010208f:	81 fe ff ff ff 0d    	cmp    $0xdffffff,%esi
80102095:	77 4e                	ja     801020e5 <kfree2+0x74>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102097:	83 ec 04             	sub    $0x4,%esp
8010209a:	68 00 10 00 00       	push   $0x1000
8010209f:	6a 01                	push   $0x1
801020a1:	53                   	push   %ebx
801020a2:	e8 c8 1d 00 00       	call   80103e6f <memset>

  if (kmem.use_lock)
801020a7:	83 c4 10             	add    $0x10,%esp
801020aa:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801020b1:	75 3f                	jne    801020f2 <kfree2+0x81>
    acquire(&kmem.lock);
  r = (struct run *)v;
  r->next = kmem.freelist;
801020b3:	a1 78 26 11 80       	mov    0x80112678,%eax
801020b8:	89 03                	mov    %eax,(%ebx)
  r->pid = -1;
801020ba:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
  int i = V2P(r)>>12;
801020c1:	c1 ee 0c             	shr    $0xc,%esi
  framesList[i] = 0;
801020c4:	c7 04 b5 80 26 11 80 	movl   $0x0,-0x7feed980(,%esi,4)
801020cb:	00 00 00 00 
  kmem.freelist = r;
801020cf:	89 1d 78 26 11 80    	mov    %ebx,0x80112678
  if (kmem.use_lock)
801020d5:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801020dc:	75 26                	jne    80102104 <kfree2+0x93>
    release(&kmem.lock);
}
801020de:	8d 65 f8             	lea    -0x8(%ebp),%esp
801020e1:	5b                   	pop    %ebx
801020e2:	5e                   	pop    %esi
801020e3:	5d                   	pop    %ebp
801020e4:	c3                   	ret    
    panic("kfree");
801020e5:	83 ec 0c             	sub    $0xc,%esp
801020e8:	68 46 69 10 80       	push   $0x80106946
801020ed:	e8 56 e2 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
801020f2:	83 ec 0c             	sub    $0xc,%esp
801020f5:	68 40 26 11 80       	push   $0x80112640
801020fa:	e8 c4 1c 00 00       	call   80103dc3 <acquire>
801020ff:	83 c4 10             	add    $0x10,%esp
80102102:	eb af                	jmp    801020b3 <kfree2+0x42>
    release(&kmem.lock);
80102104:	83 ec 0c             	sub    $0xc,%esp
80102107:	68 40 26 11 80       	push   $0x80112640
8010210c:	e8 17 1d 00 00       	call   80103e28 <release>
80102111:	83 c4 10             	add    $0x10,%esp
}
80102114:	eb c8                	jmp    801020de <kfree2+0x6d>

80102116 <freerange>:
{
80102116:	55                   	push   %ebp
80102117:	89 e5                	mov    %esp,%ebp
80102119:	56                   	push   %esi
8010211a:	53                   	push   %ebx
8010211b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char *)PGROUNDUP((uint)vstart);
8010211e:	8b 45 08             	mov    0x8(%ebp),%eax
80102121:	05 ff 0f 00 00       	add    $0xfff,%eax
80102126:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
8010212b:	eb 0e                	jmp    8010213b <freerange+0x25>
    kfree2(p);
8010212d:	83 ec 0c             	sub    $0xc,%esp
80102130:	50                   	push   %eax
80102131:	e8 3b ff ff ff       	call   80102071 <kfree2>
  for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
80102136:	83 c4 10             	add    $0x10,%esp
80102139:	89 f0                	mov    %esi,%eax
8010213b:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
80102141:	39 de                	cmp    %ebx,%esi
80102143:	76 e8                	jbe    8010212d <freerange+0x17>
}
80102145:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102148:	5b                   	pop    %ebx
80102149:	5e                   	pop    %esi
8010214a:	5d                   	pop    %ebp
8010214b:	c3                   	ret    

8010214c <kinit1>:
{
8010214c:	55                   	push   %ebp
8010214d:	89 e5                	mov    %esp,%ebp
8010214f:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
80102152:	68 4c 69 10 80       	push   $0x8010694c
80102157:	68 40 26 11 80       	push   $0x80112640
8010215c:	e8 26 1b 00 00       	call   80103c87 <initlock>
  kmem.use_lock = 0;
80102161:	c7 05 74 26 11 80 00 	movl   $0x0,0x80112674
80102168:	00 00 00 
  freerange(vstart, vend);
8010216b:	83 c4 08             	add    $0x8,%esp
8010216e:	ff 75 0c             	pushl  0xc(%ebp)
80102171:	ff 75 08             	pushl  0x8(%ebp)
80102174:	e8 9d ff ff ff       	call   80102116 <freerange>
}
80102179:	83 c4 10             	add    $0x10,%esp
8010217c:	c9                   	leave  
8010217d:	c3                   	ret    

8010217e <kinit2>:
{
8010217e:	55                   	push   %ebp
8010217f:	89 e5                	mov    %esp,%ebp
80102181:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
80102184:	ff 75 0c             	pushl  0xc(%ebp)
80102187:	ff 75 08             	pushl  0x8(%ebp)
8010218a:	e8 87 ff ff ff       	call   80102116 <freerange>
  kmem.use_lock = 1;
8010218f:	c7 05 74 26 11 80 01 	movl   $0x1,0x80112674
80102196:	00 00 00 
}
80102199:	83 c4 10             	add    $0x10,%esp
8010219c:	c9                   	leave  
8010219d:	c3                   	ret    

8010219e <kalloc>:
// Returns 0 if the memory cannot be allocated.
// From spec - kalloc manages freelist and allocates physical memory
// returns first page on the freelist
char *
kalloc(int pid)
{
8010219e:	55                   	push   %ebp
8010219f:	89 e5                	mov    %esp,%ebp
801021a1:	56                   	push   %esi
801021a2:	53                   	push   %ebx
801021a3:	8b 75 08             	mov    0x8(%ebp),%esi
  struct run *r;
  struct af *a;

  if (kmem.use_lock)
801021a6:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801021ad:	75 4e                	jne    801021fd <kalloc+0x5f>
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;
801021af:	8b 1d 78 26 11 80    	mov    0x80112678,%ebx

  // we need to get the PA to retrieve the frame number
  if (r)
801021b5:	85 db                	test   %ebx,%ebx
801021b7:	74 32                	je     801021eb <kalloc+0x4d>
  {
    
    r->pid = pid;
801021b9:	89 73 04             	mov    %esi,0x4(%ebx)
    // if the last process allocated is the same as the current, then create a free frame
    int frameNumber = V2P(r) >> 12;
801021bc:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801021c2:	c1 e8 0c             	shr    $0xc,%eax
    if(frameNumber > 1023) {
801021c5:	3d ff 03 00 00       	cmp    $0x3ff,%eax
801021ca:	7e 18                	jle    801021e4 <kalloc+0x46>
      framesList[frameNumber] = pid;
801021cc:	89 34 85 80 26 11 80 	mov    %esi,-0x7feed980(,%eax,4)
      a = (struct af *)r;
      //we can get the frameNumber of a with V2P>>12
      a->next = allocFrames.aFrames;
801021d3:	a1 7c 26 11 80       	mov    0x8011267c,%eax
801021d8:	89 43 08             	mov    %eax,0x8(%ebx)
      a->pid = pid;
801021db:	89 73 04             	mov    %esi,0x4(%ebx)
      allocFrames.aFrames = a;
801021de:	89 1d 7c 26 11 80    	mov    %ebx,0x8011267c
      
    }  
    kmem.freelist = r->next;
801021e4:	8b 03                	mov    (%ebx),%eax
801021e6:	a3 78 26 11 80       	mov    %eax,0x80112678
    
  }
  if (kmem.use_lock)
801021eb:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801021f2:	75 1b                	jne    8010220f <kalloc+0x71>
  {
    release(&kmem.lock);
  }
  return (char *)r;
}
801021f4:	89 d8                	mov    %ebx,%eax
801021f6:	8d 65 f8             	lea    -0x8(%ebp),%esp
801021f9:	5b                   	pop    %ebx
801021fa:	5e                   	pop    %esi
801021fb:	5d                   	pop    %ebp
801021fc:	c3                   	ret    
    acquire(&kmem.lock);
801021fd:	83 ec 0c             	sub    $0xc,%esp
80102200:	68 40 26 11 80       	push   $0x80112640
80102205:	e8 b9 1b 00 00       	call   80103dc3 <acquire>
8010220a:	83 c4 10             	add    $0x10,%esp
8010220d:	eb a0                	jmp    801021af <kalloc+0x11>
    release(&kmem.lock);
8010220f:	83 ec 0c             	sub    $0xc,%esp
80102212:	68 40 26 11 80       	push   $0x80112640
80102217:	e8 0c 1c 00 00       	call   80103e28 <release>
8010221c:	83 c4 10             	add    $0x10,%esp
  return (char *)r;
8010221f:	eb d3                	jmp    801021f4 <kalloc+0x56>

80102221 <kalloc2>:

// called by the excluded methods (inituvm, setupkvm, walkpgdir). We need to
// "mark these pages as belonging to an unknown process". (-2)
char *
kalloc2(void)
{
80102221:	55                   	push   %ebp
80102222:	89 e5                	mov    %esp,%ebp
80102224:	53                   	push   %ebx
80102225:	83 ec 04             	sub    $0x4,%esp
  struct run *r;
  struct af *a;

  if (kmem.use_lock)
80102228:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
8010222f:	75 51                	jne    80102282 <kalloc2+0x61>
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;
80102231:	8b 1d 78 26 11 80    	mov    0x80112678,%ebx

  // we need to get the PA to retrieve the frame number
  if (r)
80102237:	85 db                	test   %ebx,%ebx
80102239:	74 37                	je     80102272 <kalloc2+0x51>
  {
    int frameNumber = V2P(r) >> 12; 
8010223b:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102241:	c1 e8 0c             	shr    $0xc,%eax

    if(frameNumber > 1023) {
80102244:	3d ff 03 00 00       	cmp    $0x3ff,%eax
80102249:	7e 20                	jle    8010226b <kalloc2+0x4a>
      framesList[frameNumber] = -2;
8010224b:	c7 04 85 80 26 11 80 	movl   $0xfffffffe,-0x7feed980(,%eax,4)
80102252:	fe ff ff ff 
       a = (struct af *)r;
      //we can get the frameNumber of a with V2P>>12
      a->next = allocFrames.aFrames;
80102256:	a1 7c 26 11 80       	mov    0x8011267c,%eax
8010225b:	89 43 08             	mov    %eax,0x8(%ebx)
      a->pid = -2;
8010225e:	c7 43 04 fe ff ff ff 	movl   $0xfffffffe,0x4(%ebx)
      allocFrames.aFrames = a;
80102265:	89 1d 7c 26 11 80    	mov    %ebx,0x8011267c
      
    }    
    kmem.freelist = r->next;
8010226b:	8b 03                	mov    (%ebx),%eax
8010226d:	a3 78 26 11 80       	mov    %eax,0x80112678
   
  }
  if (kmem.use_lock)
80102272:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80102279:	75 19                	jne    80102294 <kalloc2+0x73>
  {
    release(&kmem.lock);
  }
  return (char *)r;
}
8010227b:	89 d8                	mov    %ebx,%eax
8010227d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102280:	c9                   	leave  
80102281:	c3                   	ret    
    acquire(&kmem.lock);
80102282:	83 ec 0c             	sub    $0xc,%esp
80102285:	68 40 26 11 80       	push   $0x80112640
8010228a:	e8 34 1b 00 00       	call   80103dc3 <acquire>
8010228f:	83 c4 10             	add    $0x10,%esp
80102292:	eb 9d                	jmp    80102231 <kalloc2+0x10>
    release(&kmem.lock);
80102294:	83 ec 0c             	sub    $0xc,%esp
80102297:	68 40 26 11 80       	push   $0x80112640
8010229c:	e8 87 1b 00 00       	call   80103e28 <release>
801022a1:	83 c4 10             	add    $0x10,%esp
  return (char *)r;
801022a4:	eb d5                	jmp    8010227b <kalloc2+0x5a>

801022a6 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801022a6:	55                   	push   %ebp
801022a7:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801022a9:	ba 64 00 00 00       	mov    $0x64,%edx
801022ae:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
801022af:	a8 01                	test   $0x1,%al
801022b1:	0f 84 b5 00 00 00    	je     8010236c <kbdgetc+0xc6>
801022b7:	ba 60 00 00 00       	mov    $0x60,%edx
801022bc:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
801022bd:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
801022c0:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
801022c6:	74 5c                	je     80102324 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
801022c8:	84 c0                	test   %al,%al
801022ca:	78 66                	js     80102332 <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
801022cc:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
801022d2:	f6 c1 40             	test   $0x40,%cl
801022d5:	74 0f                	je     801022e6 <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801022d7:	83 c8 80             	or     $0xffffff80,%eax
801022da:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
801022dd:	83 e1 bf             	and    $0xffffffbf,%ecx
801022e0:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  }

  shift |= shiftcode[data];
801022e6:	0f b6 8a 80 6a 10 80 	movzbl -0x7fef9580(%edx),%ecx
801022ed:	0b 0d b4 a5 10 80    	or     0x8010a5b4,%ecx
  shift ^= togglecode[data];
801022f3:	0f b6 82 80 69 10 80 	movzbl -0x7fef9680(%edx),%eax
801022fa:	31 c1                	xor    %eax,%ecx
801022fc:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  c = charcode[shift & (CTL | SHIFT)][data];
80102302:	89 c8                	mov    %ecx,%eax
80102304:	83 e0 03             	and    $0x3,%eax
80102307:	8b 04 85 60 69 10 80 	mov    -0x7fef96a0(,%eax,4),%eax
8010230e:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
80102312:	f6 c1 08             	test   $0x8,%cl
80102315:	74 19                	je     80102330 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
80102317:	8d 50 9f             	lea    -0x61(%eax),%edx
8010231a:	83 fa 19             	cmp    $0x19,%edx
8010231d:	77 40                	ja     8010235f <kbdgetc+0xb9>
      c += 'A' - 'a';
8010231f:	83 e8 20             	sub    $0x20,%eax
80102322:	eb 0c                	jmp    80102330 <kbdgetc+0x8a>
    shift |= E0ESC;
80102324:	83 0d b4 a5 10 80 40 	orl    $0x40,0x8010a5b4
    return 0;
8010232b:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
80102330:	5d                   	pop    %ebp
80102331:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
80102332:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
80102338:	f6 c1 40             	test   $0x40,%cl
8010233b:	75 05                	jne    80102342 <kbdgetc+0x9c>
8010233d:	89 c2                	mov    %eax,%edx
8010233f:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
80102342:	0f b6 82 80 6a 10 80 	movzbl -0x7fef9580(%edx),%eax
80102349:	83 c8 40             	or     $0x40,%eax
8010234c:	0f b6 c0             	movzbl %al,%eax
8010234f:	f7 d0                	not    %eax
80102351:	21 c8                	and    %ecx,%eax
80102353:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    return 0;
80102358:	b8 00 00 00 00       	mov    $0x0,%eax
8010235d:	eb d1                	jmp    80102330 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
8010235f:	8d 50 bf             	lea    -0x41(%eax),%edx
80102362:	83 fa 19             	cmp    $0x19,%edx
80102365:	77 c9                	ja     80102330 <kbdgetc+0x8a>
      c += 'a' - 'A';
80102367:	83 c0 20             	add    $0x20,%eax
  return c;
8010236a:	eb c4                	jmp    80102330 <kbdgetc+0x8a>
    return -1;
8010236c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102371:	eb bd                	jmp    80102330 <kbdgetc+0x8a>

80102373 <kbdintr>:

void
kbdintr(void)
{
80102373:	55                   	push   %ebp
80102374:	89 e5                	mov    %esp,%ebp
80102376:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
80102379:	68 a6 22 10 80       	push   $0x801022a6
8010237e:	e8 bb e3 ff ff       	call   8010073e <consoleintr>
}
80102383:	83 c4 10             	add    $0x10,%esp
80102386:	c9                   	leave  
80102387:	c3                   	ret    

80102388 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102388:	55                   	push   %ebp
80102389:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
8010238b:	8b 0d 84 26 15 80    	mov    0x80152684,%ecx
80102391:	8d 04 81             	lea    (%ecx,%eax,4),%eax
80102394:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
80102396:	a1 84 26 15 80       	mov    0x80152684,%eax
8010239b:	8b 40 20             	mov    0x20(%eax),%eax
}
8010239e:	5d                   	pop    %ebp
8010239f:	c3                   	ret    

801023a0 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
801023a0:	55                   	push   %ebp
801023a1:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801023a3:	ba 70 00 00 00       	mov    $0x70,%edx
801023a8:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801023a9:	ba 71 00 00 00       	mov    $0x71,%edx
801023ae:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
801023af:	0f b6 c0             	movzbl %al,%eax
}
801023b2:	5d                   	pop    %ebp
801023b3:	c3                   	ret    

801023b4 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
801023b4:	55                   	push   %ebp
801023b5:	89 e5                	mov    %esp,%ebp
801023b7:	53                   	push   %ebx
801023b8:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
801023ba:	b8 00 00 00 00       	mov    $0x0,%eax
801023bf:	e8 dc ff ff ff       	call   801023a0 <cmos_read>
801023c4:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
801023c6:	b8 02 00 00 00       	mov    $0x2,%eax
801023cb:	e8 d0 ff ff ff       	call   801023a0 <cmos_read>
801023d0:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
801023d3:	b8 04 00 00 00       	mov    $0x4,%eax
801023d8:	e8 c3 ff ff ff       	call   801023a0 <cmos_read>
801023dd:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
801023e0:	b8 07 00 00 00       	mov    $0x7,%eax
801023e5:	e8 b6 ff ff ff       	call   801023a0 <cmos_read>
801023ea:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
801023ed:	b8 08 00 00 00       	mov    $0x8,%eax
801023f2:	e8 a9 ff ff ff       	call   801023a0 <cmos_read>
801023f7:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
801023fa:	b8 09 00 00 00       	mov    $0x9,%eax
801023ff:	e8 9c ff ff ff       	call   801023a0 <cmos_read>
80102404:	89 43 14             	mov    %eax,0x14(%ebx)
}
80102407:	5b                   	pop    %ebx
80102408:	5d                   	pop    %ebp
80102409:	c3                   	ret    

8010240a <lapicinit>:
  if(!lapic)
8010240a:	83 3d 84 26 15 80 00 	cmpl   $0x0,0x80152684
80102411:	0f 84 fb 00 00 00    	je     80102512 <lapicinit+0x108>
{
80102417:	55                   	push   %ebp
80102418:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010241a:	ba 3f 01 00 00       	mov    $0x13f,%edx
8010241f:	b8 3c 00 00 00       	mov    $0x3c,%eax
80102424:	e8 5f ff ff ff       	call   80102388 <lapicw>
  lapicw(TDCR, X1);
80102429:	ba 0b 00 00 00       	mov    $0xb,%edx
8010242e:	b8 f8 00 00 00       	mov    $0xf8,%eax
80102433:	e8 50 ff ff ff       	call   80102388 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102438:	ba 20 00 02 00       	mov    $0x20020,%edx
8010243d:	b8 c8 00 00 00       	mov    $0xc8,%eax
80102442:	e8 41 ff ff ff       	call   80102388 <lapicw>
  lapicw(TICR, 10000000);
80102447:	ba 80 96 98 00       	mov    $0x989680,%edx
8010244c:	b8 e0 00 00 00       	mov    $0xe0,%eax
80102451:	e8 32 ff ff ff       	call   80102388 <lapicw>
  lapicw(LINT0, MASKED);
80102456:	ba 00 00 01 00       	mov    $0x10000,%edx
8010245b:	b8 d4 00 00 00       	mov    $0xd4,%eax
80102460:	e8 23 ff ff ff       	call   80102388 <lapicw>
  lapicw(LINT1, MASKED);
80102465:	ba 00 00 01 00       	mov    $0x10000,%edx
8010246a:	b8 d8 00 00 00       	mov    $0xd8,%eax
8010246f:	e8 14 ff ff ff       	call   80102388 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102474:	a1 84 26 15 80       	mov    0x80152684,%eax
80102479:	8b 40 30             	mov    0x30(%eax),%eax
8010247c:	c1 e8 10             	shr    $0x10,%eax
8010247f:	3c 03                	cmp    $0x3,%al
80102481:	77 7b                	ja     801024fe <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102483:	ba 33 00 00 00       	mov    $0x33,%edx
80102488:	b8 dc 00 00 00       	mov    $0xdc,%eax
8010248d:	e8 f6 fe ff ff       	call   80102388 <lapicw>
  lapicw(ESR, 0);
80102492:	ba 00 00 00 00       	mov    $0x0,%edx
80102497:	b8 a0 00 00 00       	mov    $0xa0,%eax
8010249c:	e8 e7 fe ff ff       	call   80102388 <lapicw>
  lapicw(ESR, 0);
801024a1:	ba 00 00 00 00       	mov    $0x0,%edx
801024a6:	b8 a0 00 00 00       	mov    $0xa0,%eax
801024ab:	e8 d8 fe ff ff       	call   80102388 <lapicw>
  lapicw(EOI, 0);
801024b0:	ba 00 00 00 00       	mov    $0x0,%edx
801024b5:	b8 2c 00 00 00       	mov    $0x2c,%eax
801024ba:	e8 c9 fe ff ff       	call   80102388 <lapicw>
  lapicw(ICRHI, 0);
801024bf:	ba 00 00 00 00       	mov    $0x0,%edx
801024c4:	b8 c4 00 00 00       	mov    $0xc4,%eax
801024c9:	e8 ba fe ff ff       	call   80102388 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801024ce:	ba 00 85 08 00       	mov    $0x88500,%edx
801024d3:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024d8:	e8 ab fe ff ff       	call   80102388 <lapicw>
  while(lapic[ICRLO] & DELIVS)
801024dd:	a1 84 26 15 80       	mov    0x80152684,%eax
801024e2:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
801024e8:	f6 c4 10             	test   $0x10,%ah
801024eb:	75 f0                	jne    801024dd <lapicinit+0xd3>
  lapicw(TPR, 0);
801024ed:	ba 00 00 00 00       	mov    $0x0,%edx
801024f2:	b8 20 00 00 00       	mov    $0x20,%eax
801024f7:	e8 8c fe ff ff       	call   80102388 <lapicw>
}
801024fc:	5d                   	pop    %ebp
801024fd:	c3                   	ret    
    lapicw(PCINT, MASKED);
801024fe:	ba 00 00 01 00       	mov    $0x10000,%edx
80102503:	b8 d0 00 00 00       	mov    $0xd0,%eax
80102508:	e8 7b fe ff ff       	call   80102388 <lapicw>
8010250d:	e9 71 ff ff ff       	jmp    80102483 <lapicinit+0x79>
80102512:	f3 c3                	repz ret 

80102514 <lapicid>:
{
80102514:	55                   	push   %ebp
80102515:	89 e5                	mov    %esp,%ebp
  if (!lapic)
80102517:	a1 84 26 15 80       	mov    0x80152684,%eax
8010251c:	85 c0                	test   %eax,%eax
8010251e:	74 08                	je     80102528 <lapicid+0x14>
  return lapic[ID] >> 24;
80102520:	8b 40 20             	mov    0x20(%eax),%eax
80102523:	c1 e8 18             	shr    $0x18,%eax
}
80102526:	5d                   	pop    %ebp
80102527:	c3                   	ret    
    return 0;
80102528:	b8 00 00 00 00       	mov    $0x0,%eax
8010252d:	eb f7                	jmp    80102526 <lapicid+0x12>

8010252f <lapiceoi>:
  if(lapic)
8010252f:	83 3d 84 26 15 80 00 	cmpl   $0x0,0x80152684
80102536:	74 14                	je     8010254c <lapiceoi+0x1d>
{
80102538:	55                   	push   %ebp
80102539:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
8010253b:	ba 00 00 00 00       	mov    $0x0,%edx
80102540:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102545:	e8 3e fe ff ff       	call   80102388 <lapicw>
}
8010254a:	5d                   	pop    %ebp
8010254b:	c3                   	ret    
8010254c:	f3 c3                	repz ret 

8010254e <microdelay>:
{
8010254e:	55                   	push   %ebp
8010254f:	89 e5                	mov    %esp,%ebp
}
80102551:	5d                   	pop    %ebp
80102552:	c3                   	ret    

80102553 <lapicstartap>:
{
80102553:	55                   	push   %ebp
80102554:	89 e5                	mov    %esp,%ebp
80102556:	57                   	push   %edi
80102557:	56                   	push   %esi
80102558:	53                   	push   %ebx
80102559:	8b 75 08             	mov    0x8(%ebp),%esi
8010255c:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010255f:	b8 0f 00 00 00       	mov    $0xf,%eax
80102564:	ba 70 00 00 00       	mov    $0x70,%edx
80102569:	ee                   	out    %al,(%dx)
8010256a:	b8 0a 00 00 00       	mov    $0xa,%eax
8010256f:	ba 71 00 00 00       	mov    $0x71,%edx
80102574:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
80102575:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
8010257c:	00 00 
  wrv[1] = addr >> 4;
8010257e:	89 f8                	mov    %edi,%eax
80102580:	c1 e8 04             	shr    $0x4,%eax
80102583:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
80102589:	c1 e6 18             	shl    $0x18,%esi
8010258c:	89 f2                	mov    %esi,%edx
8010258e:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102593:	e8 f0 fd ff ff       	call   80102388 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102598:	ba 00 c5 00 00       	mov    $0xc500,%edx
8010259d:	b8 c0 00 00 00       	mov    $0xc0,%eax
801025a2:	e8 e1 fd ff ff       	call   80102388 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
801025a7:	ba 00 85 00 00       	mov    $0x8500,%edx
801025ac:	b8 c0 00 00 00       	mov    $0xc0,%eax
801025b1:	e8 d2 fd ff ff       	call   80102388 <lapicw>
  for(i = 0; i < 2; i++){
801025b6:	bb 00 00 00 00       	mov    $0x0,%ebx
801025bb:	eb 21                	jmp    801025de <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
801025bd:	89 f2                	mov    %esi,%edx
801025bf:	b8 c4 00 00 00       	mov    $0xc4,%eax
801025c4:	e8 bf fd ff ff       	call   80102388 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801025c9:	89 fa                	mov    %edi,%edx
801025cb:	c1 ea 0c             	shr    $0xc,%edx
801025ce:	80 ce 06             	or     $0x6,%dh
801025d1:	b8 c0 00 00 00       	mov    $0xc0,%eax
801025d6:	e8 ad fd ff ff       	call   80102388 <lapicw>
  for(i = 0; i < 2; i++){
801025db:	83 c3 01             	add    $0x1,%ebx
801025de:	83 fb 01             	cmp    $0x1,%ebx
801025e1:	7e da                	jle    801025bd <lapicstartap+0x6a>
}
801025e3:	5b                   	pop    %ebx
801025e4:	5e                   	pop    %esi
801025e5:	5f                   	pop    %edi
801025e6:	5d                   	pop    %ebp
801025e7:	c3                   	ret    

801025e8 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
801025e8:	55                   	push   %ebp
801025e9:	89 e5                	mov    %esp,%ebp
801025eb:	57                   	push   %edi
801025ec:	56                   	push   %esi
801025ed:	53                   	push   %ebx
801025ee:	83 ec 3c             	sub    $0x3c,%esp
801025f1:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801025f4:	b8 0b 00 00 00       	mov    $0xb,%eax
801025f9:	e8 a2 fd ff ff       	call   801023a0 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
801025fe:	83 e0 04             	and    $0x4,%eax
80102601:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
80102603:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102606:	e8 a9 fd ff ff       	call   801023b4 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
8010260b:	b8 0a 00 00 00       	mov    $0xa,%eax
80102610:	e8 8b fd ff ff       	call   801023a0 <cmos_read>
80102615:	a8 80                	test   $0x80,%al
80102617:	75 ea                	jne    80102603 <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
80102619:	8d 5d b8             	lea    -0x48(%ebp),%ebx
8010261c:	89 d8                	mov    %ebx,%eax
8010261e:	e8 91 fd ff ff       	call   801023b4 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
80102623:	83 ec 04             	sub    $0x4,%esp
80102626:	6a 18                	push   $0x18
80102628:	53                   	push   %ebx
80102629:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010262c:	50                   	push   %eax
8010262d:	e8 83 18 00 00       	call   80103eb5 <memcmp>
80102632:	83 c4 10             	add    $0x10,%esp
80102635:	85 c0                	test   %eax,%eax
80102637:	75 ca                	jne    80102603 <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
80102639:	85 ff                	test   %edi,%edi
8010263b:	0f 85 84 00 00 00    	jne    801026c5 <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80102641:	8b 55 d0             	mov    -0x30(%ebp),%edx
80102644:	89 d0                	mov    %edx,%eax
80102646:	c1 e8 04             	shr    $0x4,%eax
80102649:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010264c:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010264f:	83 e2 0f             	and    $0xf,%edx
80102652:	01 d0                	add    %edx,%eax
80102654:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
80102657:	8b 55 d4             	mov    -0x2c(%ebp),%edx
8010265a:	89 d0                	mov    %edx,%eax
8010265c:	c1 e8 04             	shr    $0x4,%eax
8010265f:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102662:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102665:	83 e2 0f             	and    $0xf,%edx
80102668:	01 d0                	add    %edx,%eax
8010266a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
8010266d:	8b 55 d8             	mov    -0x28(%ebp),%edx
80102670:	89 d0                	mov    %edx,%eax
80102672:	c1 e8 04             	shr    $0x4,%eax
80102675:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102678:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010267b:	83 e2 0f             	and    $0xf,%edx
8010267e:	01 d0                	add    %edx,%eax
80102680:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
80102683:	8b 55 dc             	mov    -0x24(%ebp),%edx
80102686:	89 d0                	mov    %edx,%eax
80102688:	c1 e8 04             	shr    $0x4,%eax
8010268b:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010268e:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102691:	83 e2 0f             	and    $0xf,%edx
80102694:	01 d0                	add    %edx,%eax
80102696:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
80102699:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010269c:	89 d0                	mov    %edx,%eax
8010269e:	c1 e8 04             	shr    $0x4,%eax
801026a1:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801026a4:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801026a7:	83 e2 0f             	and    $0xf,%edx
801026aa:	01 d0                	add    %edx,%eax
801026ac:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
801026af:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801026b2:	89 d0                	mov    %edx,%eax
801026b4:	c1 e8 04             	shr    $0x4,%eax
801026b7:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801026ba:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801026bd:	83 e2 0f             	and    $0xf,%edx
801026c0:	01 d0                	add    %edx,%eax
801026c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
801026c5:	8b 45 d0             	mov    -0x30(%ebp),%eax
801026c8:	89 06                	mov    %eax,(%esi)
801026ca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801026cd:	89 46 04             	mov    %eax,0x4(%esi)
801026d0:	8b 45 d8             	mov    -0x28(%ebp),%eax
801026d3:	89 46 08             	mov    %eax,0x8(%esi)
801026d6:	8b 45 dc             	mov    -0x24(%ebp),%eax
801026d9:	89 46 0c             	mov    %eax,0xc(%esi)
801026dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801026df:	89 46 10             	mov    %eax,0x10(%esi)
801026e2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801026e5:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
801026e8:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
801026ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
801026f2:	5b                   	pop    %ebx
801026f3:	5e                   	pop    %esi
801026f4:	5f                   	pop    %edi
801026f5:	5d                   	pop    %ebp
801026f6:	c3                   	ret    

801026f7 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801026f7:	55                   	push   %ebp
801026f8:	89 e5                	mov    %esp,%ebp
801026fa:	53                   	push   %ebx
801026fb:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801026fe:	ff 35 d4 26 15 80    	pushl  0x801526d4
80102704:	ff 35 e4 26 15 80    	pushl  0x801526e4
8010270a:	e8 5d da ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
8010270f:	8b 58 5c             	mov    0x5c(%eax),%ebx
80102712:	89 1d e8 26 15 80    	mov    %ebx,0x801526e8
  for (i = 0; i < log.lh.n; i++) {
80102718:	83 c4 10             	add    $0x10,%esp
8010271b:	ba 00 00 00 00       	mov    $0x0,%edx
80102720:	eb 0e                	jmp    80102730 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
80102722:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
80102726:	89 0c 95 ec 26 15 80 	mov    %ecx,-0x7fead914(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
8010272d:	83 c2 01             	add    $0x1,%edx
80102730:	39 d3                	cmp    %edx,%ebx
80102732:	7f ee                	jg     80102722 <read_head+0x2b>
  }
  brelse(buf);
80102734:	83 ec 0c             	sub    $0xc,%esp
80102737:	50                   	push   %eax
80102738:	e8 98 da ff ff       	call   801001d5 <brelse>
}
8010273d:	83 c4 10             	add    $0x10,%esp
80102740:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102743:	c9                   	leave  
80102744:	c3                   	ret    

80102745 <install_trans>:
{
80102745:	55                   	push   %ebp
80102746:	89 e5                	mov    %esp,%ebp
80102748:	57                   	push   %edi
80102749:	56                   	push   %esi
8010274a:	53                   	push   %ebx
8010274b:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
8010274e:	bb 00 00 00 00       	mov    $0x0,%ebx
80102753:	eb 66                	jmp    801027bb <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80102755:	89 d8                	mov    %ebx,%eax
80102757:	03 05 d4 26 15 80    	add    0x801526d4,%eax
8010275d:	83 c0 01             	add    $0x1,%eax
80102760:	83 ec 08             	sub    $0x8,%esp
80102763:	50                   	push   %eax
80102764:	ff 35 e4 26 15 80    	pushl  0x801526e4
8010276a:	e8 fd d9 ff ff       	call   8010016c <bread>
8010276f:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80102771:	83 c4 08             	add    $0x8,%esp
80102774:	ff 34 9d ec 26 15 80 	pushl  -0x7fead914(,%ebx,4)
8010277b:	ff 35 e4 26 15 80    	pushl  0x801526e4
80102781:	e8 e6 d9 ff ff       	call   8010016c <bread>
80102786:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80102788:	8d 57 5c             	lea    0x5c(%edi),%edx
8010278b:	8d 40 5c             	lea    0x5c(%eax),%eax
8010278e:	83 c4 0c             	add    $0xc,%esp
80102791:	68 00 02 00 00       	push   $0x200
80102796:	52                   	push   %edx
80102797:	50                   	push   %eax
80102798:	e8 4d 17 00 00       	call   80103eea <memmove>
    bwrite(dbuf);  // write dst to disk
8010279d:	89 34 24             	mov    %esi,(%esp)
801027a0:	e8 f5 d9 ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
801027a5:	89 3c 24             	mov    %edi,(%esp)
801027a8:	e8 28 da ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
801027ad:	89 34 24             	mov    %esi,(%esp)
801027b0:	e8 20 da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801027b5:	83 c3 01             	add    $0x1,%ebx
801027b8:	83 c4 10             	add    $0x10,%esp
801027bb:	39 1d e8 26 15 80    	cmp    %ebx,0x801526e8
801027c1:	7f 92                	jg     80102755 <install_trans+0x10>
}
801027c3:	8d 65 f4             	lea    -0xc(%ebp),%esp
801027c6:	5b                   	pop    %ebx
801027c7:	5e                   	pop    %esi
801027c8:	5f                   	pop    %edi
801027c9:	5d                   	pop    %ebp
801027ca:	c3                   	ret    

801027cb <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801027cb:	55                   	push   %ebp
801027cc:	89 e5                	mov    %esp,%ebp
801027ce:	53                   	push   %ebx
801027cf:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801027d2:	ff 35 d4 26 15 80    	pushl  0x801526d4
801027d8:	ff 35 e4 26 15 80    	pushl  0x801526e4
801027de:	e8 89 d9 ff ff       	call   8010016c <bread>
801027e3:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
801027e5:	8b 0d e8 26 15 80    	mov    0x801526e8,%ecx
801027eb:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
801027ee:	83 c4 10             	add    $0x10,%esp
801027f1:	b8 00 00 00 00       	mov    $0x0,%eax
801027f6:	eb 0e                	jmp    80102806 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
801027f8:	8b 14 85 ec 26 15 80 	mov    -0x7fead914(,%eax,4),%edx
801027ff:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
80102803:	83 c0 01             	add    $0x1,%eax
80102806:	39 c1                	cmp    %eax,%ecx
80102808:	7f ee                	jg     801027f8 <write_head+0x2d>
  }
  bwrite(buf);
8010280a:	83 ec 0c             	sub    $0xc,%esp
8010280d:	53                   	push   %ebx
8010280e:	e8 87 d9 ff ff       	call   8010019a <bwrite>
  brelse(buf);
80102813:	89 1c 24             	mov    %ebx,(%esp)
80102816:	e8 ba d9 ff ff       	call   801001d5 <brelse>
}
8010281b:	83 c4 10             	add    $0x10,%esp
8010281e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102821:	c9                   	leave  
80102822:	c3                   	ret    

80102823 <recover_from_log>:

static void
recover_from_log(void)
{
80102823:	55                   	push   %ebp
80102824:	89 e5                	mov    %esp,%ebp
80102826:	83 ec 08             	sub    $0x8,%esp
  read_head();
80102829:	e8 c9 fe ff ff       	call   801026f7 <read_head>
  install_trans(); // if committed, copy from log to disk
8010282e:	e8 12 ff ff ff       	call   80102745 <install_trans>
  log.lh.n = 0;
80102833:	c7 05 e8 26 15 80 00 	movl   $0x0,0x801526e8
8010283a:	00 00 00 
  write_head(); // clear the log
8010283d:	e8 89 ff ff ff       	call   801027cb <write_head>
}
80102842:	c9                   	leave  
80102843:	c3                   	ret    

80102844 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
80102844:	55                   	push   %ebp
80102845:	89 e5                	mov    %esp,%ebp
80102847:	57                   	push   %edi
80102848:	56                   	push   %esi
80102849:	53                   	push   %ebx
8010284a:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010284d:	bb 00 00 00 00       	mov    $0x0,%ebx
80102852:	eb 66                	jmp    801028ba <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80102854:	89 d8                	mov    %ebx,%eax
80102856:	03 05 d4 26 15 80    	add    0x801526d4,%eax
8010285c:	83 c0 01             	add    $0x1,%eax
8010285f:	83 ec 08             	sub    $0x8,%esp
80102862:	50                   	push   %eax
80102863:	ff 35 e4 26 15 80    	pushl  0x801526e4
80102869:	e8 fe d8 ff ff       	call   8010016c <bread>
8010286e:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80102870:	83 c4 08             	add    $0x8,%esp
80102873:	ff 34 9d ec 26 15 80 	pushl  -0x7fead914(,%ebx,4)
8010287a:	ff 35 e4 26 15 80    	pushl  0x801526e4
80102880:	e8 e7 d8 ff ff       	call   8010016c <bread>
80102885:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
80102887:	8d 50 5c             	lea    0x5c(%eax),%edx
8010288a:	8d 46 5c             	lea    0x5c(%esi),%eax
8010288d:	83 c4 0c             	add    $0xc,%esp
80102890:	68 00 02 00 00       	push   $0x200
80102895:	52                   	push   %edx
80102896:	50                   	push   %eax
80102897:	e8 4e 16 00 00       	call   80103eea <memmove>
    bwrite(to);  // write the log
8010289c:	89 34 24             	mov    %esi,(%esp)
8010289f:	e8 f6 d8 ff ff       	call   8010019a <bwrite>
    brelse(from);
801028a4:	89 3c 24             	mov    %edi,(%esp)
801028a7:	e8 29 d9 ff ff       	call   801001d5 <brelse>
    brelse(to);
801028ac:	89 34 24             	mov    %esi,(%esp)
801028af:	e8 21 d9 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801028b4:	83 c3 01             	add    $0x1,%ebx
801028b7:	83 c4 10             	add    $0x10,%esp
801028ba:	39 1d e8 26 15 80    	cmp    %ebx,0x801526e8
801028c0:	7f 92                	jg     80102854 <write_log+0x10>
  }
}
801028c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
801028c5:	5b                   	pop    %ebx
801028c6:	5e                   	pop    %esi
801028c7:	5f                   	pop    %edi
801028c8:	5d                   	pop    %ebp
801028c9:	c3                   	ret    

801028ca <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
801028ca:	83 3d e8 26 15 80 00 	cmpl   $0x0,0x801526e8
801028d1:	7e 26                	jle    801028f9 <commit+0x2f>
{
801028d3:	55                   	push   %ebp
801028d4:	89 e5                	mov    %esp,%ebp
801028d6:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
801028d9:	e8 66 ff ff ff       	call   80102844 <write_log>
    write_head();    // Write header to disk -- the real commit
801028de:	e8 e8 fe ff ff       	call   801027cb <write_head>
    install_trans(); // Now install writes to home locations
801028e3:	e8 5d fe ff ff       	call   80102745 <install_trans>
    log.lh.n = 0;
801028e8:	c7 05 e8 26 15 80 00 	movl   $0x0,0x801526e8
801028ef:	00 00 00 
    write_head();    // Erase the transaction from the log
801028f2:	e8 d4 fe ff ff       	call   801027cb <write_head>
  }
}
801028f7:	c9                   	leave  
801028f8:	c3                   	ret    
801028f9:	f3 c3                	repz ret 

801028fb <initlog>:
{
801028fb:	55                   	push   %ebp
801028fc:	89 e5                	mov    %esp,%ebp
801028fe:	53                   	push   %ebx
801028ff:	83 ec 2c             	sub    $0x2c,%esp
80102902:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
80102905:	68 80 6b 10 80       	push   $0x80106b80
8010290a:	68 a0 26 15 80       	push   $0x801526a0
8010290f:	e8 73 13 00 00       	call   80103c87 <initlock>
  readsb(dev, &sb);
80102914:	83 c4 08             	add    $0x8,%esp
80102917:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010291a:	50                   	push   %eax
8010291b:	53                   	push   %ebx
8010291c:	e8 15 e9 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
80102921:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102924:	a3 d4 26 15 80       	mov    %eax,0x801526d4
  log.size = sb.nlog;
80102929:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010292c:	a3 d8 26 15 80       	mov    %eax,0x801526d8
  log.dev = dev;
80102931:	89 1d e4 26 15 80    	mov    %ebx,0x801526e4
  recover_from_log();
80102937:	e8 e7 fe ff ff       	call   80102823 <recover_from_log>
}
8010293c:	83 c4 10             	add    $0x10,%esp
8010293f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102942:	c9                   	leave  
80102943:	c3                   	ret    

80102944 <begin_op>:
{
80102944:	55                   	push   %ebp
80102945:	89 e5                	mov    %esp,%ebp
80102947:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
8010294a:	68 a0 26 15 80       	push   $0x801526a0
8010294f:	e8 6f 14 00 00       	call   80103dc3 <acquire>
80102954:	83 c4 10             	add    $0x10,%esp
80102957:	eb 15                	jmp    8010296e <begin_op+0x2a>
      sleep(&log, &log.lock);
80102959:	83 ec 08             	sub    $0x8,%esp
8010295c:	68 a0 26 15 80       	push   $0x801526a0
80102961:	68 a0 26 15 80       	push   $0x801526a0
80102966:	e8 de 0e 00 00       	call   80103849 <sleep>
8010296b:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
8010296e:	83 3d e0 26 15 80 00 	cmpl   $0x0,0x801526e0
80102975:	75 e2                	jne    80102959 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102977:	a1 dc 26 15 80       	mov    0x801526dc,%eax
8010297c:	83 c0 01             	add    $0x1,%eax
8010297f:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102982:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102985:	03 15 e8 26 15 80    	add    0x801526e8,%edx
8010298b:	83 fa 1e             	cmp    $0x1e,%edx
8010298e:	7e 17                	jle    801029a7 <begin_op+0x63>
      sleep(&log, &log.lock);
80102990:	83 ec 08             	sub    $0x8,%esp
80102993:	68 a0 26 15 80       	push   $0x801526a0
80102998:	68 a0 26 15 80       	push   $0x801526a0
8010299d:	e8 a7 0e 00 00       	call   80103849 <sleep>
801029a2:	83 c4 10             	add    $0x10,%esp
801029a5:	eb c7                	jmp    8010296e <begin_op+0x2a>
      log.outstanding += 1;
801029a7:	a3 dc 26 15 80       	mov    %eax,0x801526dc
      release(&log.lock);
801029ac:	83 ec 0c             	sub    $0xc,%esp
801029af:	68 a0 26 15 80       	push   $0x801526a0
801029b4:	e8 6f 14 00 00       	call   80103e28 <release>
}
801029b9:	83 c4 10             	add    $0x10,%esp
801029bc:	c9                   	leave  
801029bd:	c3                   	ret    

801029be <end_op>:
{
801029be:	55                   	push   %ebp
801029bf:	89 e5                	mov    %esp,%ebp
801029c1:	53                   	push   %ebx
801029c2:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
801029c5:	68 a0 26 15 80       	push   $0x801526a0
801029ca:	e8 f4 13 00 00       	call   80103dc3 <acquire>
  log.outstanding -= 1;
801029cf:	a1 dc 26 15 80       	mov    0x801526dc,%eax
801029d4:	83 e8 01             	sub    $0x1,%eax
801029d7:	a3 dc 26 15 80       	mov    %eax,0x801526dc
  if(log.committing)
801029dc:	8b 1d e0 26 15 80    	mov    0x801526e0,%ebx
801029e2:	83 c4 10             	add    $0x10,%esp
801029e5:	85 db                	test   %ebx,%ebx
801029e7:	75 2c                	jne    80102a15 <end_op+0x57>
  if(log.outstanding == 0){
801029e9:	85 c0                	test   %eax,%eax
801029eb:	75 35                	jne    80102a22 <end_op+0x64>
    log.committing = 1;
801029ed:	c7 05 e0 26 15 80 01 	movl   $0x1,0x801526e0
801029f4:	00 00 00 
    do_commit = 1;
801029f7:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
801029fc:	83 ec 0c             	sub    $0xc,%esp
801029ff:	68 a0 26 15 80       	push   $0x801526a0
80102a04:	e8 1f 14 00 00       	call   80103e28 <release>
  if(do_commit){
80102a09:	83 c4 10             	add    $0x10,%esp
80102a0c:	85 db                	test   %ebx,%ebx
80102a0e:	75 24                	jne    80102a34 <end_op+0x76>
}
80102a10:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a13:	c9                   	leave  
80102a14:	c3                   	ret    
    panic("log.committing");
80102a15:	83 ec 0c             	sub    $0xc,%esp
80102a18:	68 84 6b 10 80       	push   $0x80106b84
80102a1d:	e8 26 d9 ff ff       	call   80100348 <panic>
    wakeup(&log);
80102a22:	83 ec 0c             	sub    $0xc,%esp
80102a25:	68 a0 26 15 80       	push   $0x801526a0
80102a2a:	e8 7f 0f 00 00       	call   801039ae <wakeup>
80102a2f:	83 c4 10             	add    $0x10,%esp
80102a32:	eb c8                	jmp    801029fc <end_op+0x3e>
    commit();
80102a34:	e8 91 fe ff ff       	call   801028ca <commit>
    acquire(&log.lock);
80102a39:	83 ec 0c             	sub    $0xc,%esp
80102a3c:	68 a0 26 15 80       	push   $0x801526a0
80102a41:	e8 7d 13 00 00       	call   80103dc3 <acquire>
    log.committing = 0;
80102a46:	c7 05 e0 26 15 80 00 	movl   $0x0,0x801526e0
80102a4d:	00 00 00 
    wakeup(&log);
80102a50:	c7 04 24 a0 26 15 80 	movl   $0x801526a0,(%esp)
80102a57:	e8 52 0f 00 00       	call   801039ae <wakeup>
    release(&log.lock);
80102a5c:	c7 04 24 a0 26 15 80 	movl   $0x801526a0,(%esp)
80102a63:	e8 c0 13 00 00       	call   80103e28 <release>
80102a68:	83 c4 10             	add    $0x10,%esp
}
80102a6b:	eb a3                	jmp    80102a10 <end_op+0x52>

80102a6d <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102a6d:	55                   	push   %ebp
80102a6e:	89 e5                	mov    %esp,%ebp
80102a70:	53                   	push   %ebx
80102a71:	83 ec 04             	sub    $0x4,%esp
80102a74:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102a77:	8b 15 e8 26 15 80    	mov    0x801526e8,%edx
80102a7d:	83 fa 1d             	cmp    $0x1d,%edx
80102a80:	7f 45                	jg     80102ac7 <log_write+0x5a>
80102a82:	a1 d8 26 15 80       	mov    0x801526d8,%eax
80102a87:	83 e8 01             	sub    $0x1,%eax
80102a8a:	39 c2                	cmp    %eax,%edx
80102a8c:	7d 39                	jge    80102ac7 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102a8e:	83 3d dc 26 15 80 00 	cmpl   $0x0,0x801526dc
80102a95:	7e 3d                	jle    80102ad4 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102a97:	83 ec 0c             	sub    $0xc,%esp
80102a9a:	68 a0 26 15 80       	push   $0x801526a0
80102a9f:	e8 1f 13 00 00       	call   80103dc3 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102aa4:	83 c4 10             	add    $0x10,%esp
80102aa7:	b8 00 00 00 00       	mov    $0x0,%eax
80102aac:	8b 15 e8 26 15 80    	mov    0x801526e8,%edx
80102ab2:	39 c2                	cmp    %eax,%edx
80102ab4:	7e 2b                	jle    80102ae1 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102ab6:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102ab9:	39 0c 85 ec 26 15 80 	cmp    %ecx,-0x7fead914(,%eax,4)
80102ac0:	74 1f                	je     80102ae1 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102ac2:	83 c0 01             	add    $0x1,%eax
80102ac5:	eb e5                	jmp    80102aac <log_write+0x3f>
    panic("too big a transaction");
80102ac7:	83 ec 0c             	sub    $0xc,%esp
80102aca:	68 93 6b 10 80       	push   $0x80106b93
80102acf:	e8 74 d8 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102ad4:	83 ec 0c             	sub    $0xc,%esp
80102ad7:	68 a9 6b 10 80       	push   $0x80106ba9
80102adc:	e8 67 d8 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102ae1:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102ae4:	89 0c 85 ec 26 15 80 	mov    %ecx,-0x7fead914(,%eax,4)
  if (i == log.lh.n)
80102aeb:	39 c2                	cmp    %eax,%edx
80102aed:	74 18                	je     80102b07 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102aef:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102af2:	83 ec 0c             	sub    $0xc,%esp
80102af5:	68 a0 26 15 80       	push   $0x801526a0
80102afa:	e8 29 13 00 00       	call   80103e28 <release>
}
80102aff:	83 c4 10             	add    $0x10,%esp
80102b02:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102b05:	c9                   	leave  
80102b06:	c3                   	ret    
    log.lh.n++;
80102b07:	83 c2 01             	add    $0x1,%edx
80102b0a:	89 15 e8 26 15 80    	mov    %edx,0x801526e8
80102b10:	eb dd                	jmp    80102aef <log_write+0x82>

80102b12 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102b12:	55                   	push   %ebp
80102b13:	89 e5                	mov    %esp,%ebp
80102b15:	53                   	push   %ebx
80102b16:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102b19:	68 8a 00 00 00       	push   $0x8a
80102b1e:	68 8c a4 10 80       	push   $0x8010a48c
80102b23:	68 00 70 00 80       	push   $0x80007000
80102b28:	e8 bd 13 00 00       	call   80103eea <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102b2d:	83 c4 10             	add    $0x10,%esp
80102b30:	bb a0 27 15 80       	mov    $0x801527a0,%ebx
80102b35:	eb 06                	jmp    80102b3d <startothers+0x2b>
80102b37:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102b3d:	69 05 20 2d 15 80 b0 	imul   $0xb0,0x80152d20,%eax
80102b44:	00 00 00 
80102b47:	05 a0 27 15 80       	add    $0x801527a0,%eax
80102b4c:	39 d8                	cmp    %ebx,%eax
80102b4e:	76 57                	jbe    80102ba7 <startothers+0x95>
    if(c == mycpu())  // We've started already.
80102b50:	e8 d9 07 00 00       	call   8010332e <mycpu>
80102b55:	39 d8                	cmp    %ebx,%eax
80102b57:	74 de                	je     80102b37 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc(myproc()->pid); // need to pass the pid to kalloc?
80102b59:	e8 47 08 00 00       	call   801033a5 <myproc>
80102b5e:	83 ec 0c             	sub    $0xc,%esp
80102b61:	ff 70 10             	pushl  0x10(%eax)
80102b64:	e8 35 f6 ff ff       	call   8010219e <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102b69:	05 00 10 00 00       	add    $0x1000,%eax
80102b6e:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102b73:	c7 05 f8 6f 00 80 eb 	movl   $0x80102beb,0x80006ff8
80102b7a:	2b 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102b7d:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102b84:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102b87:	83 c4 08             	add    $0x8,%esp
80102b8a:	68 00 70 00 00       	push   $0x7000
80102b8f:	0f b6 03             	movzbl (%ebx),%eax
80102b92:	50                   	push   %eax
80102b93:	e8 bb f9 ff ff       	call   80102553 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102b98:	83 c4 10             	add    $0x10,%esp
80102b9b:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102ba1:	85 c0                	test   %eax,%eax
80102ba3:	74 f6                	je     80102b9b <startothers+0x89>
80102ba5:	eb 90                	jmp    80102b37 <startothers+0x25>
      ;
  }
}
80102ba7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102baa:	c9                   	leave  
80102bab:	c3                   	ret    

80102bac <mpmain>:
{
80102bac:	55                   	push   %ebp
80102bad:	89 e5                	mov    %esp,%ebp
80102baf:	53                   	push   %ebx
80102bb0:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102bb3:	e8 d2 07 00 00       	call   8010338a <cpuid>
80102bb8:	89 c3                	mov    %eax,%ebx
80102bba:	e8 cb 07 00 00       	call   8010338a <cpuid>
80102bbf:	83 ec 04             	sub    $0x4,%esp
80102bc2:	53                   	push   %ebx
80102bc3:	50                   	push   %eax
80102bc4:	68 c4 6b 10 80       	push   $0x80106bc4
80102bc9:	e8 3d da ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102bce:	e8 6e 24 00 00       	call   80105041 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102bd3:	e8 56 07 00 00       	call   8010332e <mycpu>
80102bd8:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102bda:	b8 01 00 00 00       	mov    $0x1,%eax
80102bdf:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102be6:	e8 39 0a 00 00       	call   80103624 <scheduler>

80102beb <mpenter>:
{
80102beb:	55                   	push   %ebp
80102bec:	89 e5                	mov    %esp,%ebp
80102bee:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102bf1:	e8 54 34 00 00       	call   8010604a <switchkvm>
  seginit();
80102bf6:	e8 03 33 00 00       	call   80105efe <seginit>
  lapicinit();
80102bfb:	e8 0a f8 ff ff       	call   8010240a <lapicinit>
  mpmain();
80102c00:	e8 a7 ff ff ff       	call   80102bac <mpmain>

80102c05 <main>:
{
80102c05:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102c09:	83 e4 f0             	and    $0xfffffff0,%esp
80102c0c:	ff 71 fc             	pushl  -0x4(%ecx)
80102c0f:	55                   	push   %ebp
80102c10:	89 e5                	mov    %esp,%ebp
80102c12:	51                   	push   %ecx
80102c13:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102c16:	68 00 00 40 80       	push   $0x80400000
80102c1b:	68 c8 54 15 80       	push   $0x801554c8
80102c20:	e8 27 f5 ff ff       	call   8010214c <kinit1>
  kvmalloc();      // kernel page table
80102c25:	e8 c6 38 00 00       	call   801064f0 <kvmalloc>
  mpinit();        // detect other processors
80102c2a:	e8 c9 01 00 00       	call   80102df8 <mpinit>
  lapicinit();     // interrupt controller
80102c2f:	e8 d6 f7 ff ff       	call   8010240a <lapicinit>
  seginit();       // segment descriptors
80102c34:	e8 c5 32 00 00       	call   80105efe <seginit>
  picinit();       // disable pic
80102c39:	e8 82 02 00 00       	call   80102ec0 <picinit>
  ioapicinit();    // another interrupt controller
80102c3e:	e8 b7 f2 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102c43:	e8 46 dc ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102c48:	e8 a2 26 00 00       	call   801052ef <uartinit>
  pinit();         // process table
80102c4d:	e8 c2 06 00 00       	call   80103314 <pinit>
  tvinit();        // trap vectors
80102c52:	e8 39 23 00 00       	call   80104f90 <tvinit>
  binit();         // buffer cache
80102c57:	e8 98 d4 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102c5c:	e8 b2 df ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102c61:	e8 9a f0 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102c66:	e8 a7 fe ff ff       	call   80102b12 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102c6b:	83 c4 08             	add    $0x8,%esp
80102c6e:	68 00 00 00 8e       	push   $0x8e000000
80102c73:	68 00 00 40 80       	push   $0x80400000
80102c78:	e8 01 f5 ff ff       	call   8010217e <kinit2>
  userinit();      // first user process
80102c7d:	e8 47 07 00 00       	call   801033c9 <userinit>
  mpmain();        // finish this processor's setup
80102c82:	e8 25 ff ff ff       	call   80102bac <mpmain>

80102c87 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102c87:	55                   	push   %ebp
80102c88:	89 e5                	mov    %esp,%ebp
80102c8a:	56                   	push   %esi
80102c8b:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102c8c:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102c91:	b9 00 00 00 00       	mov    $0x0,%ecx
80102c96:	eb 09                	jmp    80102ca1 <sum+0x1a>
    sum += addr[i];
80102c98:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102c9c:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102c9e:	83 c1 01             	add    $0x1,%ecx
80102ca1:	39 d1                	cmp    %edx,%ecx
80102ca3:	7c f3                	jl     80102c98 <sum+0x11>
  return sum;
}
80102ca5:	89 d8                	mov    %ebx,%eax
80102ca7:	5b                   	pop    %ebx
80102ca8:	5e                   	pop    %esi
80102ca9:	5d                   	pop    %ebp
80102caa:	c3                   	ret    

80102cab <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102cab:	55                   	push   %ebp
80102cac:	89 e5                	mov    %esp,%ebp
80102cae:	56                   	push   %esi
80102caf:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102cb0:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102cb6:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102cb8:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102cba:	eb 03                	jmp    80102cbf <mpsearch1+0x14>
80102cbc:	83 c3 10             	add    $0x10,%ebx
80102cbf:	39 f3                	cmp    %esi,%ebx
80102cc1:	73 29                	jae    80102cec <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102cc3:	83 ec 04             	sub    $0x4,%esp
80102cc6:	6a 04                	push   $0x4
80102cc8:	68 d8 6b 10 80       	push   $0x80106bd8
80102ccd:	53                   	push   %ebx
80102cce:	e8 e2 11 00 00       	call   80103eb5 <memcmp>
80102cd3:	83 c4 10             	add    $0x10,%esp
80102cd6:	85 c0                	test   %eax,%eax
80102cd8:	75 e2                	jne    80102cbc <mpsearch1+0x11>
80102cda:	ba 10 00 00 00       	mov    $0x10,%edx
80102cdf:	89 d8                	mov    %ebx,%eax
80102ce1:	e8 a1 ff ff ff       	call   80102c87 <sum>
80102ce6:	84 c0                	test   %al,%al
80102ce8:	75 d2                	jne    80102cbc <mpsearch1+0x11>
80102cea:	eb 05                	jmp    80102cf1 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102cec:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102cf1:	89 d8                	mov    %ebx,%eax
80102cf3:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102cf6:	5b                   	pop    %ebx
80102cf7:	5e                   	pop    %esi
80102cf8:	5d                   	pop    %ebp
80102cf9:	c3                   	ret    

80102cfa <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102cfa:	55                   	push   %ebp
80102cfb:	89 e5                	mov    %esp,%ebp
80102cfd:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102d00:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102d07:	c1 e0 08             	shl    $0x8,%eax
80102d0a:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102d11:	09 d0                	or     %edx,%eax
80102d13:	c1 e0 04             	shl    $0x4,%eax
80102d16:	85 c0                	test   %eax,%eax
80102d18:	74 1f                	je     80102d39 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102d1a:	ba 00 04 00 00       	mov    $0x400,%edx
80102d1f:	e8 87 ff ff ff       	call   80102cab <mpsearch1>
80102d24:	85 c0                	test   %eax,%eax
80102d26:	75 0f                	jne    80102d37 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102d28:	ba 00 00 01 00       	mov    $0x10000,%edx
80102d2d:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102d32:	e8 74 ff ff ff       	call   80102cab <mpsearch1>
}
80102d37:	c9                   	leave  
80102d38:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102d39:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102d40:	c1 e0 08             	shl    $0x8,%eax
80102d43:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102d4a:	09 d0                	or     %edx,%eax
80102d4c:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102d4f:	2d 00 04 00 00       	sub    $0x400,%eax
80102d54:	ba 00 04 00 00       	mov    $0x400,%edx
80102d59:	e8 4d ff ff ff       	call   80102cab <mpsearch1>
80102d5e:	85 c0                	test   %eax,%eax
80102d60:	75 d5                	jne    80102d37 <mpsearch+0x3d>
80102d62:	eb c4                	jmp    80102d28 <mpsearch+0x2e>

80102d64 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102d64:	55                   	push   %ebp
80102d65:	89 e5                	mov    %esp,%ebp
80102d67:	57                   	push   %edi
80102d68:	56                   	push   %esi
80102d69:	53                   	push   %ebx
80102d6a:	83 ec 1c             	sub    $0x1c,%esp
80102d6d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102d70:	e8 85 ff ff ff       	call   80102cfa <mpsearch>
80102d75:	85 c0                	test   %eax,%eax
80102d77:	74 5c                	je     80102dd5 <mpconfig+0x71>
80102d79:	89 c7                	mov    %eax,%edi
80102d7b:	8b 58 04             	mov    0x4(%eax),%ebx
80102d7e:	85 db                	test   %ebx,%ebx
80102d80:	74 5a                	je     80102ddc <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102d82:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102d88:	83 ec 04             	sub    $0x4,%esp
80102d8b:	6a 04                	push   $0x4
80102d8d:	68 dd 6b 10 80       	push   $0x80106bdd
80102d92:	56                   	push   %esi
80102d93:	e8 1d 11 00 00       	call   80103eb5 <memcmp>
80102d98:	83 c4 10             	add    $0x10,%esp
80102d9b:	85 c0                	test   %eax,%eax
80102d9d:	75 44                	jne    80102de3 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102d9f:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102da6:	3c 01                	cmp    $0x1,%al
80102da8:	0f 95 c2             	setne  %dl
80102dab:	3c 04                	cmp    $0x4,%al
80102dad:	0f 95 c0             	setne  %al
80102db0:	84 c2                	test   %al,%dl
80102db2:	75 36                	jne    80102dea <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102db4:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102dbb:	89 f0                	mov    %esi,%eax
80102dbd:	e8 c5 fe ff ff       	call   80102c87 <sum>
80102dc2:	84 c0                	test   %al,%al
80102dc4:	75 2b                	jne    80102df1 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102dc6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102dc9:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102dcb:	89 f0                	mov    %esi,%eax
80102dcd:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102dd0:	5b                   	pop    %ebx
80102dd1:	5e                   	pop    %esi
80102dd2:	5f                   	pop    %edi
80102dd3:	5d                   	pop    %ebp
80102dd4:	c3                   	ret    
    return 0;
80102dd5:	be 00 00 00 00       	mov    $0x0,%esi
80102dda:	eb ef                	jmp    80102dcb <mpconfig+0x67>
80102ddc:	be 00 00 00 00       	mov    $0x0,%esi
80102de1:	eb e8                	jmp    80102dcb <mpconfig+0x67>
    return 0;
80102de3:	be 00 00 00 00       	mov    $0x0,%esi
80102de8:	eb e1                	jmp    80102dcb <mpconfig+0x67>
    return 0;
80102dea:	be 00 00 00 00       	mov    $0x0,%esi
80102def:	eb da                	jmp    80102dcb <mpconfig+0x67>
    return 0;
80102df1:	be 00 00 00 00       	mov    $0x0,%esi
80102df6:	eb d3                	jmp    80102dcb <mpconfig+0x67>

80102df8 <mpinit>:

void
mpinit(void)
{
80102df8:	55                   	push   %ebp
80102df9:	89 e5                	mov    %esp,%ebp
80102dfb:	57                   	push   %edi
80102dfc:	56                   	push   %esi
80102dfd:	53                   	push   %ebx
80102dfe:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102e01:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102e04:	e8 5b ff ff ff       	call   80102d64 <mpconfig>
80102e09:	85 c0                	test   %eax,%eax
80102e0b:	74 19                	je     80102e26 <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102e0d:	8b 50 24             	mov    0x24(%eax),%edx
80102e10:	89 15 84 26 15 80    	mov    %edx,0x80152684
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102e16:	8d 50 2c             	lea    0x2c(%eax),%edx
80102e19:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102e1d:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102e1f:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102e24:	eb 34                	jmp    80102e5a <mpinit+0x62>
    panic("Expect to run on an SMP");
80102e26:	83 ec 0c             	sub    $0xc,%esp
80102e29:	68 e2 6b 10 80       	push   $0x80106be2
80102e2e:	e8 15 d5 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102e33:	8b 35 20 2d 15 80    	mov    0x80152d20,%esi
80102e39:	83 fe 07             	cmp    $0x7,%esi
80102e3c:	7f 19                	jg     80102e57 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102e3e:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102e42:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102e48:	88 87 a0 27 15 80    	mov    %al,-0x7fead860(%edi)
        ncpu++;
80102e4e:	83 c6 01             	add    $0x1,%esi
80102e51:	89 35 20 2d 15 80    	mov    %esi,0x80152d20
      }
      p += sizeof(struct mpproc);
80102e57:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102e5a:	39 ca                	cmp    %ecx,%edx
80102e5c:	73 2b                	jae    80102e89 <mpinit+0x91>
    switch(*p){
80102e5e:	0f b6 02             	movzbl (%edx),%eax
80102e61:	3c 04                	cmp    $0x4,%al
80102e63:	77 1d                	ja     80102e82 <mpinit+0x8a>
80102e65:	0f b6 c0             	movzbl %al,%eax
80102e68:	ff 24 85 1c 6c 10 80 	jmp    *-0x7fef93e4(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102e6f:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102e73:	a2 80 27 15 80       	mov    %al,0x80152780
      p += sizeof(struct mpioapic);
80102e78:	83 c2 08             	add    $0x8,%edx
      continue;
80102e7b:	eb dd                	jmp    80102e5a <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102e7d:	83 c2 08             	add    $0x8,%edx
      continue;
80102e80:	eb d8                	jmp    80102e5a <mpinit+0x62>
    default:
      ismp = 0;
80102e82:	bb 00 00 00 00       	mov    $0x0,%ebx
80102e87:	eb d1                	jmp    80102e5a <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102e89:	85 db                	test   %ebx,%ebx
80102e8b:	74 26                	je     80102eb3 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102e8d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e90:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102e94:	74 15                	je     80102eab <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e96:	b8 70 00 00 00       	mov    $0x70,%eax
80102e9b:	ba 22 00 00 00       	mov    $0x22,%edx
80102ea0:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102ea1:	ba 23 00 00 00       	mov    $0x23,%edx
80102ea6:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102ea7:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102eaa:	ee                   	out    %al,(%dx)
  }
}
80102eab:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102eae:	5b                   	pop    %ebx
80102eaf:	5e                   	pop    %esi
80102eb0:	5f                   	pop    %edi
80102eb1:	5d                   	pop    %ebp
80102eb2:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102eb3:	83 ec 0c             	sub    $0xc,%esp
80102eb6:	68 fc 6b 10 80       	push   $0x80106bfc
80102ebb:	e8 88 d4 ff ff       	call   80100348 <panic>

80102ec0 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102ec0:	55                   	push   %ebp
80102ec1:	89 e5                	mov    %esp,%ebp
80102ec3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102ec8:	ba 21 00 00 00       	mov    $0x21,%edx
80102ecd:	ee                   	out    %al,(%dx)
80102ece:	ba a1 00 00 00       	mov    $0xa1,%edx
80102ed3:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102ed4:	5d                   	pop    %ebp
80102ed5:	c3                   	ret    

80102ed6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102ed6:	55                   	push   %ebp
80102ed7:	89 e5                	mov    %esp,%ebp
80102ed9:	57                   	push   %edi
80102eda:	56                   	push   %esi
80102edb:	53                   	push   %ebx
80102edc:	83 ec 0c             	sub    $0xc,%esp
80102edf:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102ee2:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102ee5:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102eeb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102ef1:	e8 37 dd ff ff       	call   80100c2d <filealloc>
80102ef6:	89 03                	mov    %eax,(%ebx)
80102ef8:	85 c0                	test   %eax,%eax
80102efa:	74 1e                	je     80102f1a <pipealloc+0x44>
80102efc:	e8 2c dd ff ff       	call   80100c2d <filealloc>
80102f01:	89 06                	mov    %eax,(%esi)
80102f03:	85 c0                	test   %eax,%eax
80102f05:	74 13                	je     80102f1a <pipealloc+0x44>
    goto bad;
  // need to pass the pid to kalloc?
  if((p = (struct pipe*)kalloc(0)) == 0)
80102f07:	83 ec 0c             	sub    $0xc,%esp
80102f0a:	6a 00                	push   $0x0
80102f0c:	e8 8d f2 ff ff       	call   8010219e <kalloc>
80102f11:	89 c7                	mov    %eax,%edi
80102f13:	83 c4 10             	add    $0x10,%esp
80102f16:	85 c0                	test   %eax,%eax
80102f18:	75 35                	jne    80102f4f <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102f1a:	8b 03                	mov    (%ebx),%eax
80102f1c:	85 c0                	test   %eax,%eax
80102f1e:	74 0c                	je     80102f2c <pipealloc+0x56>
    fileclose(*f0);
80102f20:	83 ec 0c             	sub    $0xc,%esp
80102f23:	50                   	push   %eax
80102f24:	e8 aa dd ff ff       	call   80100cd3 <fileclose>
80102f29:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102f2c:	8b 06                	mov    (%esi),%eax
80102f2e:	85 c0                	test   %eax,%eax
80102f30:	0f 84 8b 00 00 00    	je     80102fc1 <pipealloc+0xeb>
    fileclose(*f1);
80102f36:	83 ec 0c             	sub    $0xc,%esp
80102f39:	50                   	push   %eax
80102f3a:	e8 94 dd ff ff       	call   80100cd3 <fileclose>
80102f3f:	83 c4 10             	add    $0x10,%esp
  return -1;
80102f42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102f47:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f4a:	5b                   	pop    %ebx
80102f4b:	5e                   	pop    %esi
80102f4c:	5f                   	pop    %edi
80102f4d:	5d                   	pop    %ebp
80102f4e:	c3                   	ret    
  p->readopen = 1;
80102f4f:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102f56:	00 00 00 
  p->writeopen = 1;
80102f59:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102f60:	00 00 00 
  p->nwrite = 0;
80102f63:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102f6a:	00 00 00 
  p->nread = 0;
80102f6d:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102f74:	00 00 00 
  initlock(&p->lock, "pipe");
80102f77:	83 ec 08             	sub    $0x8,%esp
80102f7a:	68 30 6c 10 80       	push   $0x80106c30
80102f7f:	50                   	push   %eax
80102f80:	e8 02 0d 00 00       	call   80103c87 <initlock>
  (*f0)->type = FD_PIPE;
80102f85:	8b 03                	mov    (%ebx),%eax
80102f87:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102f8d:	8b 03                	mov    (%ebx),%eax
80102f8f:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102f93:	8b 03                	mov    (%ebx),%eax
80102f95:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102f99:	8b 03                	mov    (%ebx),%eax
80102f9b:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102f9e:	8b 06                	mov    (%esi),%eax
80102fa0:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102fa6:	8b 06                	mov    (%esi),%eax
80102fa8:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102fac:	8b 06                	mov    (%esi),%eax
80102fae:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102fb2:	8b 06                	mov    (%esi),%eax
80102fb4:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102fb7:	83 c4 10             	add    $0x10,%esp
80102fba:	b8 00 00 00 00       	mov    $0x0,%eax
80102fbf:	eb 86                	jmp    80102f47 <pipealloc+0x71>
  return -1;
80102fc1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102fc6:	e9 7c ff ff ff       	jmp    80102f47 <pipealloc+0x71>

80102fcb <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102fcb:	55                   	push   %ebp
80102fcc:	89 e5                	mov    %esp,%ebp
80102fce:	53                   	push   %ebx
80102fcf:	83 ec 10             	sub    $0x10,%esp
80102fd2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102fd5:	53                   	push   %ebx
80102fd6:	e8 e8 0d 00 00       	call   80103dc3 <acquire>
  if(writable){
80102fdb:	83 c4 10             	add    $0x10,%esp
80102fde:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102fe2:	74 3f                	je     80103023 <pipeclose+0x58>
    p->writeopen = 0;
80102fe4:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102feb:	00 00 00 
    wakeup(&p->nread);
80102fee:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102ff4:	83 ec 0c             	sub    $0xc,%esp
80102ff7:	50                   	push   %eax
80102ff8:	e8 b1 09 00 00       	call   801039ae <wakeup>
80102ffd:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103000:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103007:	75 09                	jne    80103012 <pipeclose+0x47>
80103009:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80103010:	74 2f                	je     80103041 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80103012:	83 ec 0c             	sub    $0xc,%esp
80103015:	53                   	push   %ebx
80103016:	e8 0d 0e 00 00       	call   80103e28 <release>
8010301b:	83 c4 10             	add    $0x10,%esp
}
8010301e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103021:	c9                   	leave  
80103022:	c3                   	ret    
    p->readopen = 0;
80103023:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
8010302a:	00 00 00 
    wakeup(&p->nwrite);
8010302d:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103033:	83 ec 0c             	sub    $0xc,%esp
80103036:	50                   	push   %eax
80103037:	e8 72 09 00 00       	call   801039ae <wakeup>
8010303c:	83 c4 10             	add    $0x10,%esp
8010303f:	eb bf                	jmp    80103000 <pipeclose+0x35>
    release(&p->lock);
80103041:	83 ec 0c             	sub    $0xc,%esp
80103044:	53                   	push   %ebx
80103045:	e8 de 0d 00 00       	call   80103e28 <release>
    kfree((char*)p);
8010304a:	89 1c 24             	mov    %ebx,(%esp)
8010304d:	e8 5c ef ff ff       	call   80101fae <kfree>
80103052:	83 c4 10             	add    $0x10,%esp
80103055:	eb c7                	jmp    8010301e <pipeclose+0x53>

80103057 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80103057:	55                   	push   %ebp
80103058:	89 e5                	mov    %esp,%ebp
8010305a:	57                   	push   %edi
8010305b:	56                   	push   %esi
8010305c:	53                   	push   %ebx
8010305d:	83 ec 18             	sub    $0x18,%esp
80103060:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103063:	89 de                	mov    %ebx,%esi
80103065:	53                   	push   %ebx
80103066:	e8 58 0d 00 00       	call   80103dc3 <acquire>
  for(i = 0; i < n; i++){
8010306b:	83 c4 10             	add    $0x10,%esp
8010306e:	bf 00 00 00 00       	mov    $0x0,%edi
80103073:	3b 7d 10             	cmp    0x10(%ebp),%edi
80103076:	0f 8d 88 00 00 00    	jge    80103104 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010307c:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80103082:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103088:	05 00 02 00 00       	add    $0x200,%eax
8010308d:	39 c2                	cmp    %eax,%edx
8010308f:	75 51                	jne    801030e2 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80103091:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103098:	74 2f                	je     801030c9 <pipewrite+0x72>
8010309a:	e8 06 03 00 00       	call   801033a5 <myproc>
8010309f:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801030a3:	75 24                	jne    801030c9 <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
801030a5:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801030ab:	83 ec 0c             	sub    $0xc,%esp
801030ae:	50                   	push   %eax
801030af:	e8 fa 08 00 00       	call   801039ae <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801030b4:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
801030ba:	83 c4 08             	add    $0x8,%esp
801030bd:	56                   	push   %esi
801030be:	50                   	push   %eax
801030bf:	e8 85 07 00 00       	call   80103849 <sleep>
801030c4:	83 c4 10             	add    $0x10,%esp
801030c7:	eb b3                	jmp    8010307c <pipewrite+0x25>
        release(&p->lock);
801030c9:	83 ec 0c             	sub    $0xc,%esp
801030cc:	53                   	push   %ebx
801030cd:	e8 56 0d 00 00       	call   80103e28 <release>
        return -1;
801030d2:	83 c4 10             	add    $0x10,%esp
801030d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
801030da:	8d 65 f4             	lea    -0xc(%ebp),%esp
801030dd:	5b                   	pop    %ebx
801030de:	5e                   	pop    %esi
801030df:	5f                   	pop    %edi
801030e0:	5d                   	pop    %ebp
801030e1:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801030e2:	8d 42 01             	lea    0x1(%edx),%eax
801030e5:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
801030eb:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
801030f1:	8b 45 0c             	mov    0xc(%ebp),%eax
801030f4:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
801030f8:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
801030fc:	83 c7 01             	add    $0x1,%edi
801030ff:	e9 6f ff ff ff       	jmp    80103073 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103104:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010310a:	83 ec 0c             	sub    $0xc,%esp
8010310d:	50                   	push   %eax
8010310e:	e8 9b 08 00 00       	call   801039ae <wakeup>
  release(&p->lock);
80103113:	89 1c 24             	mov    %ebx,(%esp)
80103116:	e8 0d 0d 00 00       	call   80103e28 <release>
  return n;
8010311b:	83 c4 10             	add    $0x10,%esp
8010311e:	8b 45 10             	mov    0x10(%ebp),%eax
80103121:	eb b7                	jmp    801030da <pipewrite+0x83>

80103123 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103123:	55                   	push   %ebp
80103124:	89 e5                	mov    %esp,%ebp
80103126:	57                   	push   %edi
80103127:	56                   	push   %esi
80103128:	53                   	push   %ebx
80103129:	83 ec 18             	sub    $0x18,%esp
8010312c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
8010312f:	89 df                	mov    %ebx,%edi
80103131:	53                   	push   %ebx
80103132:	e8 8c 0c 00 00       	call   80103dc3 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103137:	83 c4 10             	add    $0x10,%esp
8010313a:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
80103140:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
80103146:	75 3d                	jne    80103185 <piperead+0x62>
80103148:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
8010314e:	85 f6                	test   %esi,%esi
80103150:	74 38                	je     8010318a <piperead+0x67>
    if(myproc()->killed){
80103152:	e8 4e 02 00 00       	call   801033a5 <myproc>
80103157:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010315b:	75 15                	jne    80103172 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010315d:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103163:	83 ec 08             	sub    $0x8,%esp
80103166:	57                   	push   %edi
80103167:	50                   	push   %eax
80103168:	e8 dc 06 00 00       	call   80103849 <sleep>
8010316d:	83 c4 10             	add    $0x10,%esp
80103170:	eb c8                	jmp    8010313a <piperead+0x17>
      release(&p->lock);
80103172:	83 ec 0c             	sub    $0xc,%esp
80103175:	53                   	push   %ebx
80103176:	e8 ad 0c 00 00       	call   80103e28 <release>
      return -1;
8010317b:	83 c4 10             	add    $0x10,%esp
8010317e:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103183:	eb 50                	jmp    801031d5 <piperead+0xb2>
80103185:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010318a:	3b 75 10             	cmp    0x10(%ebp),%esi
8010318d:	7d 2c                	jge    801031bb <piperead+0x98>
    if(p->nread == p->nwrite)
8010318f:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103195:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
8010319b:	74 1e                	je     801031bb <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010319d:	8d 50 01             	lea    0x1(%eax),%edx
801031a0:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
801031a6:	25 ff 01 00 00       	and    $0x1ff,%eax
801031ab:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
801031b0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801031b3:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801031b6:	83 c6 01             	add    $0x1,%esi
801031b9:	eb cf                	jmp    8010318a <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801031bb:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
801031c1:	83 ec 0c             	sub    $0xc,%esp
801031c4:	50                   	push   %eax
801031c5:	e8 e4 07 00 00       	call   801039ae <wakeup>
  release(&p->lock);
801031ca:	89 1c 24             	mov    %ebx,(%esp)
801031cd:	e8 56 0c 00 00       	call   80103e28 <release>
  return i;
801031d2:	83 c4 10             	add    $0x10,%esp
}
801031d5:	89 f0                	mov    %esi,%eax
801031d7:	8d 65 f4             	lea    -0xc(%ebp),%esp
801031da:	5b                   	pop    %ebx
801031db:	5e                   	pop    %esi
801031dc:	5f                   	pop    %edi
801031dd:	5d                   	pop    %ebp
801031de:	c3                   	ret    

801031df <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801031df:	55                   	push   %ebp
801031e0:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801031e2:	ba 74 2d 15 80       	mov    $0x80152d74,%edx
801031e7:	eb 03                	jmp    801031ec <wakeup1+0xd>
801031e9:	83 c2 7c             	add    $0x7c,%edx
801031ec:	81 fa 74 4c 15 80    	cmp    $0x80154c74,%edx
801031f2:	73 14                	jae    80103208 <wakeup1+0x29>
    if (p->state == SLEEPING && p->chan == chan)
801031f4:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
801031f8:	75 ef                	jne    801031e9 <wakeup1+0xa>
801031fa:	39 42 20             	cmp    %eax,0x20(%edx)
801031fd:	75 ea                	jne    801031e9 <wakeup1+0xa>
      p->state = RUNNABLE;
801031ff:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
80103206:	eb e1                	jmp    801031e9 <wakeup1+0xa>
}
80103208:	5d                   	pop    %ebp
80103209:	c3                   	ret    

8010320a <allocproc>:
{
8010320a:	55                   	push   %ebp
8010320b:	89 e5                	mov    %esp,%ebp
8010320d:	53                   	push   %ebx
8010320e:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
80103211:	68 40 2d 15 80       	push   $0x80152d40
80103216:	e8 a8 0b 00 00       	call   80103dc3 <acquire>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010321b:	83 c4 10             	add    $0x10,%esp
8010321e:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
80103223:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
80103229:	73 0b                	jae    80103236 <allocproc+0x2c>
    if (p->state == UNUSED)
8010322b:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
8010322f:	74 1c                	je     8010324d <allocproc+0x43>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103231:	83 c3 7c             	add    $0x7c,%ebx
80103234:	eb ed                	jmp    80103223 <allocproc+0x19>
  release(&ptable.lock);
80103236:	83 ec 0c             	sub    $0xc,%esp
80103239:	68 40 2d 15 80       	push   $0x80152d40
8010323e:	e8 e5 0b 00 00       	call   80103e28 <release>
  return 0;
80103243:	83 c4 10             	add    $0x10,%esp
80103246:	bb 00 00 00 00       	mov    $0x0,%ebx
8010324b:	eb 6f                	jmp    801032bc <allocproc+0xb2>
  p->state = EMBRYO;
8010324d:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
80103254:	a1 04 a0 10 80       	mov    0x8010a004,%eax
80103259:	8d 50 01             	lea    0x1(%eax),%edx
8010325c:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
80103262:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
80103265:	83 ec 0c             	sub    $0xc,%esp
80103268:	68 40 2d 15 80       	push   $0x80152d40
8010326d:	e8 b6 0b 00 00       	call   80103e28 <release>
  if ((p->kstack = kalloc(p->pid)) == 0)
80103272:	83 c4 04             	add    $0x4,%esp
80103275:	ff 73 10             	pushl  0x10(%ebx)
80103278:	e8 21 ef ff ff       	call   8010219e <kalloc>
8010327d:	89 43 08             	mov    %eax,0x8(%ebx)
80103280:	83 c4 10             	add    $0x10,%esp
80103283:	85 c0                	test   %eax,%eax
80103285:	74 3c                	je     801032c3 <allocproc+0xb9>
  sp -= sizeof *p->tf;
80103287:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe *)sp;
8010328d:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint *)sp = (uint)trapret;
80103290:	c7 80 b0 0f 00 00 85 	movl   $0x80104f85,0xfb0(%eax)
80103297:	4f 10 80 
  sp -= sizeof *p->context;
8010329a:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context *)sp;
8010329f:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
801032a2:	83 ec 04             	sub    $0x4,%esp
801032a5:	6a 14                	push   $0x14
801032a7:	6a 00                	push   $0x0
801032a9:	50                   	push   %eax
801032aa:	e8 c0 0b 00 00       	call   80103e6f <memset>
  p->context->eip = (uint)forkret;
801032af:	8b 43 1c             	mov    0x1c(%ebx),%eax
801032b2:	c7 40 10 d1 32 10 80 	movl   $0x801032d1,0x10(%eax)
  return p;
801032b9:	83 c4 10             	add    $0x10,%esp
}
801032bc:	89 d8                	mov    %ebx,%eax
801032be:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801032c1:	c9                   	leave  
801032c2:	c3                   	ret    
    p->state = UNUSED;
801032c3:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
801032ca:	bb 00 00 00 00       	mov    $0x0,%ebx
801032cf:	eb eb                	jmp    801032bc <allocproc+0xb2>

801032d1 <forkret>:
{
801032d1:	55                   	push   %ebp
801032d2:	89 e5                	mov    %esp,%ebp
801032d4:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
801032d7:	68 40 2d 15 80       	push   $0x80152d40
801032dc:	e8 47 0b 00 00       	call   80103e28 <release>
  if (first)
801032e1:	83 c4 10             	add    $0x10,%esp
801032e4:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
801032eb:	75 02                	jne    801032ef <forkret+0x1e>
}
801032ed:	c9                   	leave  
801032ee:	c3                   	ret    
    first = 0;
801032ef:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
801032f6:	00 00 00 
    iinit(ROOTDEV);
801032f9:	83 ec 0c             	sub    $0xc,%esp
801032fc:	6a 01                	push   $0x1
801032fe:	e8 e9 df ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
80103303:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010330a:	e8 ec f5 ff ff       	call   801028fb <initlog>
8010330f:	83 c4 10             	add    $0x10,%esp
}
80103312:	eb d9                	jmp    801032ed <forkret+0x1c>

80103314 <pinit>:
{
80103314:	55                   	push   %ebp
80103315:	89 e5                	mov    %esp,%ebp
80103317:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
8010331a:	68 35 6c 10 80       	push   $0x80106c35
8010331f:	68 40 2d 15 80       	push   $0x80152d40
80103324:	e8 5e 09 00 00       	call   80103c87 <initlock>
}
80103329:	83 c4 10             	add    $0x10,%esp
8010332c:	c9                   	leave  
8010332d:	c3                   	ret    

8010332e <mycpu>:
{
8010332e:	55                   	push   %ebp
8010332f:	89 e5                	mov    %esp,%ebp
80103331:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103334:	9c                   	pushf  
80103335:	58                   	pop    %eax
  if (readeflags() & FL_IF)
80103336:	f6 c4 02             	test   $0x2,%ah
80103339:	75 28                	jne    80103363 <mycpu+0x35>
  apicid = lapicid();
8010333b:	e8 d4 f1 ff ff       	call   80102514 <lapicid>
  for (i = 0; i < ncpu; ++i)
80103340:	ba 00 00 00 00       	mov    $0x0,%edx
80103345:	39 15 20 2d 15 80    	cmp    %edx,0x80152d20
8010334b:	7e 23                	jle    80103370 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
8010334d:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
80103353:	0f b6 89 a0 27 15 80 	movzbl -0x7fead860(%ecx),%ecx
8010335a:	39 c1                	cmp    %eax,%ecx
8010335c:	74 1f                	je     8010337d <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i)
8010335e:	83 c2 01             	add    $0x1,%edx
80103361:	eb e2                	jmp    80103345 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
80103363:	83 ec 0c             	sub    $0xc,%esp
80103366:	68 18 6d 10 80       	push   $0x80106d18
8010336b:	e8 d8 cf ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
80103370:	83 ec 0c             	sub    $0xc,%esp
80103373:	68 3c 6c 10 80       	push   $0x80106c3c
80103378:	e8 cb cf ff ff       	call   80100348 <panic>
      return &cpus[i];
8010337d:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
80103383:	05 a0 27 15 80       	add    $0x801527a0,%eax
}
80103388:	c9                   	leave  
80103389:	c3                   	ret    

8010338a <cpuid>:
{
8010338a:	55                   	push   %ebp
8010338b:	89 e5                	mov    %esp,%ebp
8010338d:	83 ec 08             	sub    $0x8,%esp
  return mycpu() - cpus;
80103390:	e8 99 ff ff ff       	call   8010332e <mycpu>
80103395:	2d a0 27 15 80       	sub    $0x801527a0,%eax
8010339a:	c1 f8 04             	sar    $0x4,%eax
8010339d:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
801033a3:	c9                   	leave  
801033a4:	c3                   	ret    

801033a5 <myproc>:
{
801033a5:	55                   	push   %ebp
801033a6:	89 e5                	mov    %esp,%ebp
801033a8:	53                   	push   %ebx
801033a9:	83 ec 04             	sub    $0x4,%esp
  pushcli();
801033ac:	e8 35 09 00 00       	call   80103ce6 <pushcli>
  c = mycpu();
801033b1:	e8 78 ff ff ff       	call   8010332e <mycpu>
  p = c->proc;
801033b6:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
801033bc:	e8 62 09 00 00       	call   80103d23 <popcli>
}
801033c1:	89 d8                	mov    %ebx,%eax
801033c3:	83 c4 04             	add    $0x4,%esp
801033c6:	5b                   	pop    %ebx
801033c7:	5d                   	pop    %ebp
801033c8:	c3                   	ret    

801033c9 <userinit>:
{
801033c9:	55                   	push   %ebp
801033ca:	89 e5                	mov    %esp,%ebp
801033cc:	53                   	push   %ebx
801033cd:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
801033d0:	e8 35 fe ff ff       	call   8010320a <allocproc>
801033d5:	89 c3                	mov    %eax,%ebx
  initproc = p;
801033d7:	a3 b8 a5 10 80       	mov    %eax,0x8010a5b8
  if ((p->pgdir = setupkvm()) == 0)
801033dc:	e8 a1 30 00 00       	call   80106482 <setupkvm>
801033e1:	89 43 04             	mov    %eax,0x4(%ebx)
801033e4:	85 c0                	test   %eax,%eax
801033e6:	0f 84 b7 00 00 00    	je     801034a3 <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801033ec:	83 ec 04             	sub    $0x4,%esp
801033ef:	68 2c 00 00 00       	push   $0x2c
801033f4:	68 60 a4 10 80       	push   $0x8010a460
801033f9:	50                   	push   %eax
801033fa:	e8 75 2d 00 00       	call   80106174 <inituvm>
  p->sz = PGSIZE;
801033ff:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
80103405:	83 c4 0c             	add    $0xc,%esp
80103408:	6a 4c                	push   $0x4c
8010340a:	6a 00                	push   $0x0
8010340c:	ff 73 18             	pushl  0x18(%ebx)
8010340f:	e8 5b 0a 00 00       	call   80103e6f <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80103414:	8b 43 18             	mov    0x18(%ebx),%eax
80103417:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010341d:	8b 43 18             	mov    0x18(%ebx),%eax
80103420:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
80103426:	8b 43 18             	mov    0x18(%ebx),%eax
80103429:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
8010342d:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80103431:	8b 43 18             	mov    0x18(%ebx),%eax
80103434:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103438:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
8010343c:	8b 43 18             	mov    0x18(%ebx),%eax
8010343f:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80103446:	8b 43 18             	mov    0x18(%ebx),%eax
80103449:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0; // beginning of initcode.S
80103450:	8b 43 18             	mov    0x18(%ebx),%eax
80103453:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
8010345a:	8d 43 6c             	lea    0x6c(%ebx),%eax
8010345d:	83 c4 0c             	add    $0xc,%esp
80103460:	6a 10                	push   $0x10
80103462:	68 65 6c 10 80       	push   $0x80106c65
80103467:	50                   	push   %eax
80103468:	e8 69 0b 00 00       	call   80103fd6 <safestrcpy>
  p->cwd = namei("/");
8010346d:	c7 04 24 6e 6c 10 80 	movl   $0x80106c6e,(%esp)
80103474:	e8 68 e7 ff ff       	call   80101be1 <namei>
80103479:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
8010347c:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
80103483:	e8 3b 09 00 00       	call   80103dc3 <acquire>
  p->state = RUNNABLE;
80103488:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
8010348f:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
80103496:	e8 8d 09 00 00       	call   80103e28 <release>
}
8010349b:	83 c4 10             	add    $0x10,%esp
8010349e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801034a1:	c9                   	leave  
801034a2:	c3                   	ret    
    panic("userinit: out of memory?");
801034a3:	83 ec 0c             	sub    $0xc,%esp
801034a6:	68 4c 6c 10 80       	push   $0x80106c4c
801034ab:	e8 98 ce ff ff       	call   80100348 <panic>

801034b0 <growproc>:
{
801034b0:	55                   	push   %ebp
801034b1:	89 e5                	mov    %esp,%ebp
801034b3:	56                   	push   %esi
801034b4:	53                   	push   %ebx
801034b5:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
801034b8:	e8 e8 fe ff ff       	call   801033a5 <myproc>
801034bd:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
801034bf:	8b 00                	mov    (%eax),%eax
  if (n > 0)
801034c1:	85 f6                	test   %esi,%esi
801034c3:	7f 21                	jg     801034e6 <growproc+0x36>
  else if (n < 0)
801034c5:	85 f6                	test   %esi,%esi
801034c7:	79 33                	jns    801034fc <growproc+0x4c>
    if ((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
801034c9:	83 ec 04             	sub    $0x4,%esp
801034cc:	01 c6                	add    %eax,%esi
801034ce:	56                   	push   %esi
801034cf:	50                   	push   %eax
801034d0:	ff 73 04             	pushl  0x4(%ebx)
801034d3:	e8 a5 2d 00 00       	call   8010627d <deallocuvm>
801034d8:	83 c4 10             	add    $0x10,%esp
801034db:	85 c0                	test   %eax,%eax
801034dd:	75 1d                	jne    801034fc <growproc+0x4c>
      return -1;
801034df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801034e4:	eb 29                	jmp    8010350f <growproc+0x5f>
    if ((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
801034e6:	83 ec 04             	sub    $0x4,%esp
801034e9:	01 c6                	add    %eax,%esi
801034eb:	56                   	push   %esi
801034ec:	50                   	push   %eax
801034ed:	ff 73 04             	pushl  0x4(%ebx)
801034f0:	e8 1a 2e 00 00       	call   8010630f <allocuvm>
801034f5:	83 c4 10             	add    $0x10,%esp
801034f8:	85 c0                	test   %eax,%eax
801034fa:	74 1a                	je     80103516 <growproc+0x66>
  curproc->sz = sz;
801034fc:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
801034fe:	83 ec 0c             	sub    $0xc,%esp
80103501:	53                   	push   %ebx
80103502:	e8 55 2b 00 00       	call   8010605c <switchuvm>
  return 0;
80103507:	83 c4 10             	add    $0x10,%esp
8010350a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010350f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103512:	5b                   	pop    %ebx
80103513:	5e                   	pop    %esi
80103514:	5d                   	pop    %ebp
80103515:	c3                   	ret    
      return -1;
80103516:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010351b:	eb f2                	jmp    8010350f <growproc+0x5f>

8010351d <fork>:
{
8010351d:	55                   	push   %ebp
8010351e:	89 e5                	mov    %esp,%ebp
80103520:	57                   	push   %edi
80103521:	56                   	push   %esi
80103522:	53                   	push   %ebx
80103523:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
80103526:	e8 7a fe ff ff       	call   801033a5 <myproc>
8010352b:	89 c3                	mov    %eax,%ebx
  if ((np = allocproc()) == 0)
8010352d:	e8 d8 fc ff ff       	call   8010320a <allocproc>
80103532:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80103535:	85 c0                	test   %eax,%eax
80103537:	0f 84 e0 00 00 00    	je     8010361d <fork+0x100>
8010353d:	89 c7                	mov    %eax,%edi
  if ((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0)
8010353f:	83 ec 08             	sub    $0x8,%esp
80103542:	ff 33                	pushl  (%ebx)
80103544:	ff 73 04             	pushl  0x4(%ebx)
80103547:	e8 e7 2f 00 00       	call   80106533 <copyuvm>
8010354c:	89 47 04             	mov    %eax,0x4(%edi)
8010354f:	83 c4 10             	add    $0x10,%esp
80103552:	85 c0                	test   %eax,%eax
80103554:	74 2a                	je     80103580 <fork+0x63>
  np->sz = curproc->sz;
80103556:	8b 03                	mov    (%ebx),%eax
80103558:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010355b:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
8010355d:	89 c8                	mov    %ecx,%eax
8010355f:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
80103562:	8b 73 18             	mov    0x18(%ebx),%esi
80103565:	8b 79 18             	mov    0x18(%ecx),%edi
80103568:	b9 13 00 00 00       	mov    $0x13,%ecx
8010356d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
8010356f:	8b 40 18             	mov    0x18(%eax),%eax
80103572:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for (i = 0; i < NOFILE; i++)
80103579:	be 00 00 00 00       	mov    $0x0,%esi
8010357e:	eb 29                	jmp    801035a9 <fork+0x8c>
    kfree(np->kstack);
80103580:	83 ec 0c             	sub    $0xc,%esp
80103583:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80103586:	ff 73 08             	pushl  0x8(%ebx)
80103589:	e8 20 ea ff ff       	call   80101fae <kfree>
    np->kstack = 0;
8010358e:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
80103595:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
8010359c:	83 c4 10             	add    $0x10,%esp
8010359f:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801035a4:	eb 6d                	jmp    80103613 <fork+0xf6>
  for (i = 0; i < NOFILE; i++)
801035a6:	83 c6 01             	add    $0x1,%esi
801035a9:	83 fe 0f             	cmp    $0xf,%esi
801035ac:	7f 1d                	jg     801035cb <fork+0xae>
    if (curproc->ofile[i])
801035ae:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
801035b2:	85 c0                	test   %eax,%eax
801035b4:	74 f0                	je     801035a6 <fork+0x89>
      np->ofile[i] = filedup(curproc->ofile[i]);
801035b6:	83 ec 0c             	sub    $0xc,%esp
801035b9:	50                   	push   %eax
801035ba:	e8 cf d6 ff ff       	call   80100c8e <filedup>
801035bf:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801035c2:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
801035c6:	83 c4 10             	add    $0x10,%esp
801035c9:	eb db                	jmp    801035a6 <fork+0x89>
  np->cwd = idup(curproc->cwd);
801035cb:	83 ec 0c             	sub    $0xc,%esp
801035ce:	ff 73 68             	pushl  0x68(%ebx)
801035d1:	e8 7b df ff ff       	call   80101551 <idup>
801035d6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
801035d9:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
801035dc:	83 c3 6c             	add    $0x6c,%ebx
801035df:	8d 47 6c             	lea    0x6c(%edi),%eax
801035e2:	83 c4 0c             	add    $0xc,%esp
801035e5:	6a 10                	push   $0x10
801035e7:	53                   	push   %ebx
801035e8:	50                   	push   %eax
801035e9:	e8 e8 09 00 00       	call   80103fd6 <safestrcpy>
  pid = np->pid;
801035ee:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
801035f1:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
801035f8:	e8 c6 07 00 00       	call   80103dc3 <acquire>
  np->state = RUNNABLE;
801035fd:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
80103604:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
8010360b:	e8 18 08 00 00       	call   80103e28 <release>
  return pid;
80103610:	83 c4 10             	add    $0x10,%esp
}
80103613:	89 d8                	mov    %ebx,%eax
80103615:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103618:	5b                   	pop    %ebx
80103619:	5e                   	pop    %esi
8010361a:	5f                   	pop    %edi
8010361b:	5d                   	pop    %ebp
8010361c:	c3                   	ret    
    return -1;
8010361d:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103622:	eb ef                	jmp    80103613 <fork+0xf6>

80103624 <scheduler>:
{
80103624:	55                   	push   %ebp
80103625:	89 e5                	mov    %esp,%ebp
80103627:	56                   	push   %esi
80103628:	53                   	push   %ebx
  struct cpu *c = mycpu();
80103629:	e8 00 fd ff ff       	call   8010332e <mycpu>
8010362e:	89 c6                	mov    %eax,%esi
  c->proc = 0;
80103630:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
80103637:	00 00 00 
8010363a:	eb 5a                	jmp    80103696 <scheduler+0x72>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010363c:	83 c3 7c             	add    $0x7c,%ebx
8010363f:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
80103645:	73 3f                	jae    80103686 <scheduler+0x62>
      if (p->state != RUNNABLE)
80103647:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
8010364b:	75 ef                	jne    8010363c <scheduler+0x18>
      c->proc = p;
8010364d:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
80103653:	83 ec 0c             	sub    $0xc,%esp
80103656:	53                   	push   %ebx
80103657:	e8 00 2a 00 00       	call   8010605c <switchuvm>
      p->state = RUNNING;
8010365c:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
80103663:	83 c4 08             	add    $0x8,%esp
80103666:	ff 73 1c             	pushl  0x1c(%ebx)
80103669:	8d 46 04             	lea    0x4(%esi),%eax
8010366c:	50                   	push   %eax
8010366d:	e8 b7 09 00 00       	call   80104029 <swtch>
      switchkvm();
80103672:	e8 d3 29 00 00       	call   8010604a <switchkvm>
      c->proc = 0;
80103677:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
8010367e:	00 00 00 
80103681:	83 c4 10             	add    $0x10,%esp
80103684:	eb b6                	jmp    8010363c <scheduler+0x18>
    release(&ptable.lock);
80103686:	83 ec 0c             	sub    $0xc,%esp
80103689:	68 40 2d 15 80       	push   $0x80152d40
8010368e:	e8 95 07 00 00       	call   80103e28 <release>
    sti();
80103693:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
80103696:	fb                   	sti    
    acquire(&ptable.lock);
80103697:	83 ec 0c             	sub    $0xc,%esp
8010369a:	68 40 2d 15 80       	push   $0x80152d40
8010369f:	e8 1f 07 00 00       	call   80103dc3 <acquire>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801036a4:	83 c4 10             	add    $0x10,%esp
801036a7:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
801036ac:	eb 91                	jmp    8010363f <scheduler+0x1b>

801036ae <sched>:
{
801036ae:	55                   	push   %ebp
801036af:	89 e5                	mov    %esp,%ebp
801036b1:	56                   	push   %esi
801036b2:	53                   	push   %ebx
  struct proc *p = myproc();
801036b3:	e8 ed fc ff ff       	call   801033a5 <myproc>
801036b8:	89 c3                	mov    %eax,%ebx
  if (!holding(&ptable.lock))
801036ba:	83 ec 0c             	sub    $0xc,%esp
801036bd:	68 40 2d 15 80       	push   $0x80152d40
801036c2:	e8 bc 06 00 00       	call   80103d83 <holding>
801036c7:	83 c4 10             	add    $0x10,%esp
801036ca:	85 c0                	test   %eax,%eax
801036cc:	74 4f                	je     8010371d <sched+0x6f>
  if (mycpu()->ncli != 1)
801036ce:	e8 5b fc ff ff       	call   8010332e <mycpu>
801036d3:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
801036da:	75 4e                	jne    8010372a <sched+0x7c>
  if (p->state == RUNNING)
801036dc:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
801036e0:	74 55                	je     80103737 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801036e2:	9c                   	pushf  
801036e3:	58                   	pop    %eax
  if (readeflags() & FL_IF)
801036e4:	f6 c4 02             	test   $0x2,%ah
801036e7:	75 5b                	jne    80103744 <sched+0x96>
  intena = mycpu()->intena;
801036e9:	e8 40 fc ff ff       	call   8010332e <mycpu>
801036ee:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
801036f4:	e8 35 fc ff ff       	call   8010332e <mycpu>
801036f9:	83 ec 08             	sub    $0x8,%esp
801036fc:	ff 70 04             	pushl  0x4(%eax)
801036ff:	83 c3 1c             	add    $0x1c,%ebx
80103702:	53                   	push   %ebx
80103703:	e8 21 09 00 00       	call   80104029 <swtch>
  mycpu()->intena = intena;
80103708:	e8 21 fc ff ff       	call   8010332e <mycpu>
8010370d:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
80103713:	83 c4 10             	add    $0x10,%esp
80103716:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103719:	5b                   	pop    %ebx
8010371a:	5e                   	pop    %esi
8010371b:	5d                   	pop    %ebp
8010371c:	c3                   	ret    
    panic("sched ptable.lock");
8010371d:	83 ec 0c             	sub    $0xc,%esp
80103720:	68 70 6c 10 80       	push   $0x80106c70
80103725:	e8 1e cc ff ff       	call   80100348 <panic>
    panic("sched locks");
8010372a:	83 ec 0c             	sub    $0xc,%esp
8010372d:	68 82 6c 10 80       	push   $0x80106c82
80103732:	e8 11 cc ff ff       	call   80100348 <panic>
    panic("sched running");
80103737:	83 ec 0c             	sub    $0xc,%esp
8010373a:	68 8e 6c 10 80       	push   $0x80106c8e
8010373f:	e8 04 cc ff ff       	call   80100348 <panic>
    panic("sched interruptible");
80103744:	83 ec 0c             	sub    $0xc,%esp
80103747:	68 9c 6c 10 80       	push   $0x80106c9c
8010374c:	e8 f7 cb ff ff       	call   80100348 <panic>

80103751 <exit>:
{
80103751:	55                   	push   %ebp
80103752:	89 e5                	mov    %esp,%ebp
80103754:	56                   	push   %esi
80103755:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103756:	e8 4a fc ff ff       	call   801033a5 <myproc>
  if (curproc == initproc)
8010375b:	39 05 b8 a5 10 80    	cmp    %eax,0x8010a5b8
80103761:	74 09                	je     8010376c <exit+0x1b>
80103763:	89 c6                	mov    %eax,%esi
  for (fd = 0; fd < NOFILE; fd++)
80103765:	bb 00 00 00 00       	mov    $0x0,%ebx
8010376a:	eb 10                	jmp    8010377c <exit+0x2b>
    panic("init exiting");
8010376c:	83 ec 0c             	sub    $0xc,%esp
8010376f:	68 b0 6c 10 80       	push   $0x80106cb0
80103774:	e8 cf cb ff ff       	call   80100348 <panic>
  for (fd = 0; fd < NOFILE; fd++)
80103779:	83 c3 01             	add    $0x1,%ebx
8010377c:	83 fb 0f             	cmp    $0xf,%ebx
8010377f:	7f 1e                	jg     8010379f <exit+0x4e>
    if (curproc->ofile[fd])
80103781:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
80103785:	85 c0                	test   %eax,%eax
80103787:	74 f0                	je     80103779 <exit+0x28>
      fileclose(curproc->ofile[fd]);
80103789:	83 ec 0c             	sub    $0xc,%esp
8010378c:	50                   	push   %eax
8010378d:	e8 41 d5 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
80103792:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103799:	00 
8010379a:	83 c4 10             	add    $0x10,%esp
8010379d:	eb da                	jmp    80103779 <exit+0x28>
  begin_op();
8010379f:	e8 a0 f1 ff ff       	call   80102944 <begin_op>
  iput(curproc->cwd);
801037a4:	83 ec 0c             	sub    $0xc,%esp
801037a7:	ff 76 68             	pushl  0x68(%esi)
801037aa:	e8 d9 de ff ff       	call   80101688 <iput>
  end_op();
801037af:	e8 0a f2 ff ff       	call   801029be <end_op>
  curproc->cwd = 0;
801037b4:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
801037bb:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
801037c2:	e8 fc 05 00 00       	call   80103dc3 <acquire>
  wakeup1(curproc->parent);
801037c7:	8b 46 14             	mov    0x14(%esi),%eax
801037ca:	e8 10 fa ff ff       	call   801031df <wakeup1>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801037cf:	83 c4 10             	add    $0x10,%esp
801037d2:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
801037d7:	eb 03                	jmp    801037dc <exit+0x8b>
801037d9:	83 c3 7c             	add    $0x7c,%ebx
801037dc:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
801037e2:	73 1a                	jae    801037fe <exit+0xad>
    if (p->parent == curproc)
801037e4:	39 73 14             	cmp    %esi,0x14(%ebx)
801037e7:	75 f0                	jne    801037d9 <exit+0x88>
      p->parent = initproc;
801037e9:	a1 b8 a5 10 80       	mov    0x8010a5b8,%eax
801037ee:	89 43 14             	mov    %eax,0x14(%ebx)
      if (p->state == ZOMBIE)
801037f1:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801037f5:	75 e2                	jne    801037d9 <exit+0x88>
        wakeup1(initproc);
801037f7:	e8 e3 f9 ff ff       	call   801031df <wakeup1>
801037fc:	eb db                	jmp    801037d9 <exit+0x88>
  curproc->state = ZOMBIE;
801037fe:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
80103805:	e8 a4 fe ff ff       	call   801036ae <sched>
  panic("zombie exit");
8010380a:	83 ec 0c             	sub    $0xc,%esp
8010380d:	68 bd 6c 10 80       	push   $0x80106cbd
80103812:	e8 31 cb ff ff       	call   80100348 <panic>

80103817 <yield>:
{
80103817:	55                   	push   %ebp
80103818:	89 e5                	mov    %esp,%ebp
8010381a:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock); //DOC: yieldlock
8010381d:	68 40 2d 15 80       	push   $0x80152d40
80103822:	e8 9c 05 00 00       	call   80103dc3 <acquire>
  myproc()->state = RUNNABLE;
80103827:	e8 79 fb ff ff       	call   801033a5 <myproc>
8010382c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80103833:	e8 76 fe ff ff       	call   801036ae <sched>
  release(&ptable.lock);
80103838:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
8010383f:	e8 e4 05 00 00       	call   80103e28 <release>
}
80103844:	83 c4 10             	add    $0x10,%esp
80103847:	c9                   	leave  
80103848:	c3                   	ret    

80103849 <sleep>:
{
80103849:	55                   	push   %ebp
8010384a:	89 e5                	mov    %esp,%ebp
8010384c:	56                   	push   %esi
8010384d:	53                   	push   %ebx
8010384e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
80103851:	e8 4f fb ff ff       	call   801033a5 <myproc>
  if (p == 0)
80103856:	85 c0                	test   %eax,%eax
80103858:	74 66                	je     801038c0 <sleep+0x77>
8010385a:	89 c6                	mov    %eax,%esi
  if (lk == 0)
8010385c:	85 db                	test   %ebx,%ebx
8010385e:	74 6d                	je     801038cd <sleep+0x84>
  if (lk != &ptable.lock)
80103860:	81 fb 40 2d 15 80    	cmp    $0x80152d40,%ebx
80103866:	74 18                	je     80103880 <sleep+0x37>
    acquire(&ptable.lock); //DOC: sleeplock1
80103868:	83 ec 0c             	sub    $0xc,%esp
8010386b:	68 40 2d 15 80       	push   $0x80152d40
80103870:	e8 4e 05 00 00       	call   80103dc3 <acquire>
    release(lk);
80103875:	89 1c 24             	mov    %ebx,(%esp)
80103878:	e8 ab 05 00 00       	call   80103e28 <release>
8010387d:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103880:	8b 45 08             	mov    0x8(%ebp),%eax
80103883:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
80103886:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
8010388d:	e8 1c fe ff ff       	call   801036ae <sched>
  p->chan = 0;
80103892:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if (lk != &ptable.lock)
80103899:	81 fb 40 2d 15 80    	cmp    $0x80152d40,%ebx
8010389f:	74 18                	je     801038b9 <sleep+0x70>
    release(&ptable.lock);
801038a1:	83 ec 0c             	sub    $0xc,%esp
801038a4:	68 40 2d 15 80       	push   $0x80152d40
801038a9:	e8 7a 05 00 00       	call   80103e28 <release>
    acquire(lk);
801038ae:	89 1c 24             	mov    %ebx,(%esp)
801038b1:	e8 0d 05 00 00       	call   80103dc3 <acquire>
801038b6:	83 c4 10             	add    $0x10,%esp
}
801038b9:	8d 65 f8             	lea    -0x8(%ebp),%esp
801038bc:	5b                   	pop    %ebx
801038bd:	5e                   	pop    %esi
801038be:	5d                   	pop    %ebp
801038bf:	c3                   	ret    
    panic("sleep");
801038c0:	83 ec 0c             	sub    $0xc,%esp
801038c3:	68 c9 6c 10 80       	push   $0x80106cc9
801038c8:	e8 7b ca ff ff       	call   80100348 <panic>
    panic("sleep without lk");
801038cd:	83 ec 0c             	sub    $0xc,%esp
801038d0:	68 cf 6c 10 80       	push   $0x80106ccf
801038d5:	e8 6e ca ff ff       	call   80100348 <panic>

801038da <wait>:
{
801038da:	55                   	push   %ebp
801038db:	89 e5                	mov    %esp,%ebp
801038dd:	56                   	push   %esi
801038de:	53                   	push   %ebx
  struct proc *curproc = myproc();
801038df:	e8 c1 fa ff ff       	call   801033a5 <myproc>
801038e4:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
801038e6:	83 ec 0c             	sub    $0xc,%esp
801038e9:	68 40 2d 15 80       	push   $0x80152d40
801038ee:	e8 d0 04 00 00       	call   80103dc3 <acquire>
801038f3:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
801038f6:	b8 00 00 00 00       	mov    $0x0,%eax
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801038fb:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
80103900:	eb 5b                	jmp    8010395d <wait+0x83>
        pid = p->pid;
80103902:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
80103905:	83 ec 0c             	sub    $0xc,%esp
80103908:	ff 73 08             	pushl  0x8(%ebx)
8010390b:	e8 9e e6 ff ff       	call   80101fae <kfree>
        p->kstack = 0;
80103910:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
80103917:	83 c4 04             	add    $0x4,%esp
8010391a:	ff 73 04             	pushl  0x4(%ebx)
8010391d:	e8 f0 2a 00 00       	call   80106412 <freevm>
        p->pid = 0;
80103922:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103929:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103930:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
80103934:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
8010393b:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
80103942:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
80103949:	e8 da 04 00 00       	call   80103e28 <release>
        return pid;
8010394e:	83 c4 10             	add    $0x10,%esp
}
80103951:	89 f0                	mov    %esi,%eax
80103953:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103956:	5b                   	pop    %ebx
80103957:	5e                   	pop    %esi
80103958:	5d                   	pop    %ebp
80103959:	c3                   	ret    
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010395a:	83 c3 7c             	add    $0x7c,%ebx
8010395d:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
80103963:	73 12                	jae    80103977 <wait+0x9d>
      if (p->parent != curproc)
80103965:	39 73 14             	cmp    %esi,0x14(%ebx)
80103968:	75 f0                	jne    8010395a <wait+0x80>
      if (p->state == ZOMBIE)
8010396a:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010396e:	74 92                	je     80103902 <wait+0x28>
      havekids = 1;
80103970:	b8 01 00 00 00       	mov    $0x1,%eax
80103975:	eb e3                	jmp    8010395a <wait+0x80>
    if (!havekids || curproc->killed)
80103977:	85 c0                	test   %eax,%eax
80103979:	74 06                	je     80103981 <wait+0xa7>
8010397b:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
8010397f:	74 17                	je     80103998 <wait+0xbe>
      release(&ptable.lock);
80103981:	83 ec 0c             	sub    $0xc,%esp
80103984:	68 40 2d 15 80       	push   $0x80152d40
80103989:	e8 9a 04 00 00       	call   80103e28 <release>
      return -1;
8010398e:	83 c4 10             	add    $0x10,%esp
80103991:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103996:	eb b9                	jmp    80103951 <wait+0x77>
    sleep(curproc, &ptable.lock); //DOC: wait-sleep
80103998:	83 ec 08             	sub    $0x8,%esp
8010399b:	68 40 2d 15 80       	push   $0x80152d40
801039a0:	56                   	push   %esi
801039a1:	e8 a3 fe ff ff       	call   80103849 <sleep>
    havekids = 0;
801039a6:	83 c4 10             	add    $0x10,%esp
801039a9:	e9 48 ff ff ff       	jmp    801038f6 <wait+0x1c>

801039ae <wakeup>:

// Wake up all processes sleeping on chan.
void wakeup(void *chan)
{
801039ae:	55                   	push   %ebp
801039af:	89 e5                	mov    %esp,%ebp
801039b1:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
801039b4:	68 40 2d 15 80       	push   $0x80152d40
801039b9:	e8 05 04 00 00       	call   80103dc3 <acquire>
  wakeup1(chan);
801039be:	8b 45 08             	mov    0x8(%ebp),%eax
801039c1:	e8 19 f8 ff ff       	call   801031df <wakeup1>
  release(&ptable.lock);
801039c6:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
801039cd:	e8 56 04 00 00       	call   80103e28 <release>
}
801039d2:	83 c4 10             	add    $0x10,%esp
801039d5:	c9                   	leave  
801039d6:	c3                   	ret    

801039d7 <kill>:

// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int kill(int pid)
{
801039d7:	55                   	push   %ebp
801039d8:	89 e5                	mov    %esp,%ebp
801039da:	53                   	push   %ebx
801039db:	83 ec 10             	sub    $0x10,%esp
801039de:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
801039e1:	68 40 2d 15 80       	push   $0x80152d40
801039e6:	e8 d8 03 00 00       	call   80103dc3 <acquire>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801039eb:	83 c4 10             	add    $0x10,%esp
801039ee:	b8 74 2d 15 80       	mov    $0x80152d74,%eax
801039f3:	3d 74 4c 15 80       	cmp    $0x80154c74,%eax
801039f8:	73 3a                	jae    80103a34 <kill+0x5d>
  {
    if (p->pid == pid)
801039fa:	39 58 10             	cmp    %ebx,0x10(%eax)
801039fd:	74 05                	je     80103a04 <kill+0x2d>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801039ff:	83 c0 7c             	add    $0x7c,%eax
80103a02:	eb ef                	jmp    801039f3 <kill+0x1c>
    {
      p->killed = 1;
80103a04:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if (p->state == SLEEPING)
80103a0b:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103a0f:	74 1a                	je     80103a2b <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103a11:	83 ec 0c             	sub    $0xc,%esp
80103a14:	68 40 2d 15 80       	push   $0x80152d40
80103a19:	e8 0a 04 00 00       	call   80103e28 <release>
      return 0;
80103a1e:	83 c4 10             	add    $0x10,%esp
80103a21:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103a26:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103a29:	c9                   	leave  
80103a2a:	c3                   	ret    
        p->state = RUNNABLE;
80103a2b:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103a32:	eb dd                	jmp    80103a11 <kill+0x3a>
  release(&ptable.lock);
80103a34:	83 ec 0c             	sub    $0xc,%esp
80103a37:	68 40 2d 15 80       	push   $0x80152d40
80103a3c:	e8 e7 03 00 00       	call   80103e28 <release>
  return -1;
80103a41:	83 c4 10             	add    $0x10,%esp
80103a44:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103a49:	eb db                	jmp    80103a26 <kill+0x4f>

80103a4b <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
80103a4b:	55                   	push   %ebp
80103a4c:	89 e5                	mov    %esp,%ebp
80103a4e:	56                   	push   %esi
80103a4f:	53                   	push   %ebx
80103a50:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103a53:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
80103a58:	eb 33                	jmp    80103a8d <procdump+0x42>
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103a5a:	b8 e0 6c 10 80       	mov    $0x80106ce0,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103a5f:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103a62:	52                   	push   %edx
80103a63:	50                   	push   %eax
80103a64:	ff 73 10             	pushl  0x10(%ebx)
80103a67:	68 e4 6c 10 80       	push   $0x80106ce4
80103a6c:	e8 9a cb ff ff       	call   8010060b <cprintf>
    if (p->state == SLEEPING)
80103a71:	83 c4 10             	add    $0x10,%esp
80103a74:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103a78:	74 39                	je     80103ab3 <procdump+0x68>
    {
      getcallerpcs((uint *)p->context->ebp + 2, pc);
      for (i = 0; i < 10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103a7a:	83 ec 0c             	sub    $0xc,%esp
80103a7d:	68 5b 70 10 80       	push   $0x8010705b
80103a82:	e8 84 cb ff ff       	call   8010060b <cprintf>
80103a87:	83 c4 10             	add    $0x10,%esp
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103a8a:	83 c3 7c             	add    $0x7c,%ebx
80103a8d:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
80103a93:	73 61                	jae    80103af6 <procdump+0xab>
    if (p->state == UNUSED)
80103a95:	8b 43 0c             	mov    0xc(%ebx),%eax
80103a98:	85 c0                	test   %eax,%eax
80103a9a:	74 ee                	je     80103a8a <procdump+0x3f>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103a9c:	83 f8 05             	cmp    $0x5,%eax
80103a9f:	77 b9                	ja     80103a5a <procdump+0xf>
80103aa1:	8b 04 85 40 6d 10 80 	mov    -0x7fef92c0(,%eax,4),%eax
80103aa8:	85 c0                	test   %eax,%eax
80103aaa:	75 b3                	jne    80103a5f <procdump+0x14>
      state = "???";
80103aac:	b8 e0 6c 10 80       	mov    $0x80106ce0,%eax
80103ab1:	eb ac                	jmp    80103a5f <procdump+0x14>
      getcallerpcs((uint *)p->context->ebp + 2, pc);
80103ab3:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103ab6:	8b 40 0c             	mov    0xc(%eax),%eax
80103ab9:	83 c0 08             	add    $0x8,%eax
80103abc:	83 ec 08             	sub    $0x8,%esp
80103abf:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103ac2:	52                   	push   %edx
80103ac3:	50                   	push   %eax
80103ac4:	e8 d9 01 00 00       	call   80103ca2 <getcallerpcs>
      for (i = 0; i < 10 && pc[i] != 0; i++)
80103ac9:	83 c4 10             	add    $0x10,%esp
80103acc:	be 00 00 00 00       	mov    $0x0,%esi
80103ad1:	eb 14                	jmp    80103ae7 <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103ad3:	83 ec 08             	sub    $0x8,%esp
80103ad6:	50                   	push   %eax
80103ad7:	68 21 67 10 80       	push   $0x80106721
80103adc:	e8 2a cb ff ff       	call   8010060b <cprintf>
      for (i = 0; i < 10 && pc[i] != 0; i++)
80103ae1:	83 c6 01             	add    $0x1,%esi
80103ae4:	83 c4 10             	add    $0x10,%esp
80103ae7:	83 fe 09             	cmp    $0x9,%esi
80103aea:	7f 8e                	jg     80103a7a <procdump+0x2f>
80103aec:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103af0:	85 c0                	test   %eax,%eax
80103af2:	75 df                	jne    80103ad3 <procdump+0x88>
80103af4:	eb 84                	jmp    80103a7a <procdump+0x2f>
  }
}
80103af6:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103af9:	5b                   	pop    %ebx
80103afa:	5e                   	pop    %esi
80103afb:	5d                   	pop    %ebp
80103afc:	c3                   	ret    

80103afd <dump_physmem>:

int dump_physmem(int *frames, int *pids, int numframes)
{
80103afd:	55                   	push   %ebp
80103afe:	89 e5                	mov    %esp,%ebp
80103b00:	57                   	push   %edi
80103b01:	56                   	push   %esi
80103b02:	53                   	push   %ebx
80103b03:	83 ec 0c             	sub    $0xc,%esp
80103b06:	8b 5d 10             	mov    0x10(%ebp),%ebx
  if(numframes == 0 || frames == 0 || pids == 0) {
80103b09:	85 db                	test   %ebx,%ebx
80103b0b:	0f 94 c2             	sete   %dl
80103b0e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80103b12:	0f 94 c0             	sete   %al
80103b15:	08 c2                	or     %al,%dl
80103b17:	75 55                	jne    80103b6e <dump_physmem+0x71>
80103b19:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103b1d:	74 56                	je     80103b75 <dump_physmem+0x78>
    return -1;
  }
  int* framesList = getframesList();
80103b1f:	e8 80 e4 ff ff       	call   80101fa4 <getframesList>
  int j = 0;
  for(int i = 65535; i >=0; i--) {
80103b24:	ba ff ff 00 00       	mov    $0xffff,%edx
  int j = 0;
80103b29:	be 00 00 00 00       	mov    $0x0,%esi
80103b2e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  for(int i = 65535; i >=0; i--) {
80103b31:	eb 03                	jmp    80103b36 <dump_physmem+0x39>
80103b33:	83 ea 01             	sub    $0x1,%edx
80103b36:	85 d2                	test   %edx,%edx
80103b38:	78 27                	js     80103b61 <dump_physmem+0x64>
    if(framesList[i] != 0 && j < numframes){
80103b3a:	8d 0c 90             	lea    (%eax,%edx,4),%ecx
80103b3d:	83 39 00             	cmpl   $0x0,(%ecx)
80103b40:	74 f1                	je     80103b33 <dump_physmem+0x36>
80103b42:	3b 75 10             	cmp    0x10(%ebp),%esi
80103b45:	7d ec                	jge    80103b33 <dump_physmem+0x36>
      frames[j] = i;
80103b47:	8d 3c b5 00 00 00 00 	lea    0x0(,%esi,4),%edi
80103b4e:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103b51:	89 14 3b             	mov    %edx,(%ebx,%edi,1)
      pids[j++] = framesList[i];
80103b54:	83 c6 01             	add    $0x1,%esi
80103b57:	8b 09                	mov    (%ecx),%ecx
80103b59:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103b5c:	89 0c 3b             	mov    %ecx,(%ebx,%edi,1)
80103b5f:	eb d2                	jmp    80103b33 <dump_physmem+0x36>
    }
  }
  return 0;
80103b61:	b8 00 00 00 00       	mov    $0x0,%eax
80103b66:	83 c4 0c             	add    $0xc,%esp
80103b69:	5b                   	pop    %ebx
80103b6a:	5e                   	pop    %esi
80103b6b:	5f                   	pop    %edi
80103b6c:	5d                   	pop    %ebp
80103b6d:	c3                   	ret    
    return -1;
80103b6e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103b73:	eb f1                	jmp    80103b66 <dump_physmem+0x69>
80103b75:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103b7a:	eb ea                	jmp    80103b66 <dump_physmem+0x69>

80103b7c <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103b7c:	55                   	push   %ebp
80103b7d:	89 e5                	mov    %esp,%ebp
80103b7f:	53                   	push   %ebx
80103b80:	83 ec 0c             	sub    $0xc,%esp
80103b83:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103b86:	68 58 6d 10 80       	push   $0x80106d58
80103b8b:	8d 43 04             	lea    0x4(%ebx),%eax
80103b8e:	50                   	push   %eax
80103b8f:	e8 f3 00 00 00       	call   80103c87 <initlock>
  lk->name = name;
80103b94:	8b 45 0c             	mov    0xc(%ebp),%eax
80103b97:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103b9a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103ba0:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103ba7:	83 c4 10             	add    $0x10,%esp
80103baa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103bad:	c9                   	leave  
80103bae:	c3                   	ret    

80103baf <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103baf:	55                   	push   %ebp
80103bb0:	89 e5                	mov    %esp,%ebp
80103bb2:	56                   	push   %esi
80103bb3:	53                   	push   %ebx
80103bb4:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103bb7:	8d 73 04             	lea    0x4(%ebx),%esi
80103bba:	83 ec 0c             	sub    $0xc,%esp
80103bbd:	56                   	push   %esi
80103bbe:	e8 00 02 00 00       	call   80103dc3 <acquire>
  while (lk->locked) {
80103bc3:	83 c4 10             	add    $0x10,%esp
80103bc6:	eb 0d                	jmp    80103bd5 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103bc8:	83 ec 08             	sub    $0x8,%esp
80103bcb:	56                   	push   %esi
80103bcc:	53                   	push   %ebx
80103bcd:	e8 77 fc ff ff       	call   80103849 <sleep>
80103bd2:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103bd5:	83 3b 00             	cmpl   $0x0,(%ebx)
80103bd8:	75 ee                	jne    80103bc8 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103bda:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103be0:	e8 c0 f7 ff ff       	call   801033a5 <myproc>
80103be5:	8b 40 10             	mov    0x10(%eax),%eax
80103be8:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103beb:	83 ec 0c             	sub    $0xc,%esp
80103bee:	56                   	push   %esi
80103bef:	e8 34 02 00 00       	call   80103e28 <release>
}
80103bf4:	83 c4 10             	add    $0x10,%esp
80103bf7:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103bfa:	5b                   	pop    %ebx
80103bfb:	5e                   	pop    %esi
80103bfc:	5d                   	pop    %ebp
80103bfd:	c3                   	ret    

80103bfe <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103bfe:	55                   	push   %ebp
80103bff:	89 e5                	mov    %esp,%ebp
80103c01:	56                   	push   %esi
80103c02:	53                   	push   %ebx
80103c03:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103c06:	8d 73 04             	lea    0x4(%ebx),%esi
80103c09:	83 ec 0c             	sub    $0xc,%esp
80103c0c:	56                   	push   %esi
80103c0d:	e8 b1 01 00 00       	call   80103dc3 <acquire>
  lk->locked = 0;
80103c12:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103c18:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103c1f:	89 1c 24             	mov    %ebx,(%esp)
80103c22:	e8 87 fd ff ff       	call   801039ae <wakeup>
  release(&lk->lk);
80103c27:	89 34 24             	mov    %esi,(%esp)
80103c2a:	e8 f9 01 00 00       	call   80103e28 <release>
}
80103c2f:	83 c4 10             	add    $0x10,%esp
80103c32:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c35:	5b                   	pop    %ebx
80103c36:	5e                   	pop    %esi
80103c37:	5d                   	pop    %ebp
80103c38:	c3                   	ret    

80103c39 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103c39:	55                   	push   %ebp
80103c3a:	89 e5                	mov    %esp,%ebp
80103c3c:	56                   	push   %esi
80103c3d:	53                   	push   %ebx
80103c3e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103c41:	8d 73 04             	lea    0x4(%ebx),%esi
80103c44:	83 ec 0c             	sub    $0xc,%esp
80103c47:	56                   	push   %esi
80103c48:	e8 76 01 00 00       	call   80103dc3 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103c4d:	83 c4 10             	add    $0x10,%esp
80103c50:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c53:	75 17                	jne    80103c6c <holdingsleep+0x33>
80103c55:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103c5a:	83 ec 0c             	sub    $0xc,%esp
80103c5d:	56                   	push   %esi
80103c5e:	e8 c5 01 00 00       	call   80103e28 <release>
  return r;
}
80103c63:	89 d8                	mov    %ebx,%eax
80103c65:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c68:	5b                   	pop    %ebx
80103c69:	5e                   	pop    %esi
80103c6a:	5d                   	pop    %ebp
80103c6b:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103c6c:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103c6f:	e8 31 f7 ff ff       	call   801033a5 <myproc>
80103c74:	3b 58 10             	cmp    0x10(%eax),%ebx
80103c77:	74 07                	je     80103c80 <holdingsleep+0x47>
80103c79:	bb 00 00 00 00       	mov    $0x0,%ebx
80103c7e:	eb da                	jmp    80103c5a <holdingsleep+0x21>
80103c80:	bb 01 00 00 00       	mov    $0x1,%ebx
80103c85:	eb d3                	jmp    80103c5a <holdingsleep+0x21>

80103c87 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103c87:	55                   	push   %ebp
80103c88:	89 e5                	mov    %esp,%ebp
80103c8a:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103c8d:	8b 55 0c             	mov    0xc(%ebp),%edx
80103c90:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103c93:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103c99:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103ca0:	5d                   	pop    %ebp
80103ca1:	c3                   	ret    

80103ca2 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103ca2:	55                   	push   %ebp
80103ca3:	89 e5                	mov    %esp,%ebp
80103ca5:	53                   	push   %ebx
80103ca6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103ca9:	8b 45 08             	mov    0x8(%ebp),%eax
80103cac:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103caf:	b8 00 00 00 00       	mov    $0x0,%eax
80103cb4:	83 f8 09             	cmp    $0x9,%eax
80103cb7:	7f 25                	jg     80103cde <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103cb9:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103cbf:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103cc5:	77 17                	ja     80103cde <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103cc7:	8b 5a 04             	mov    0x4(%edx),%ebx
80103cca:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103ccd:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103ccf:	83 c0 01             	add    $0x1,%eax
80103cd2:	eb e0                	jmp    80103cb4 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103cd4:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103cdb:	83 c0 01             	add    $0x1,%eax
80103cde:	83 f8 09             	cmp    $0x9,%eax
80103ce1:	7e f1                	jle    80103cd4 <getcallerpcs+0x32>
}
80103ce3:	5b                   	pop    %ebx
80103ce4:	5d                   	pop    %ebp
80103ce5:	c3                   	ret    

80103ce6 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103ce6:	55                   	push   %ebp
80103ce7:	89 e5                	mov    %esp,%ebp
80103ce9:	53                   	push   %ebx
80103cea:	83 ec 04             	sub    $0x4,%esp
80103ced:	9c                   	pushf  
80103cee:	5b                   	pop    %ebx
  asm volatile("cli");
80103cef:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103cf0:	e8 39 f6 ff ff       	call   8010332e <mycpu>
80103cf5:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103cfc:	74 12                	je     80103d10 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103cfe:	e8 2b f6 ff ff       	call   8010332e <mycpu>
80103d03:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103d0a:	83 c4 04             	add    $0x4,%esp
80103d0d:	5b                   	pop    %ebx
80103d0e:	5d                   	pop    %ebp
80103d0f:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103d10:	e8 19 f6 ff ff       	call   8010332e <mycpu>
80103d15:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103d1b:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103d21:	eb db                	jmp    80103cfe <pushcli+0x18>

80103d23 <popcli>:

void
popcli(void)
{
80103d23:	55                   	push   %ebp
80103d24:	89 e5                	mov    %esp,%ebp
80103d26:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103d29:	9c                   	pushf  
80103d2a:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103d2b:	f6 c4 02             	test   $0x2,%ah
80103d2e:	75 28                	jne    80103d58 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103d30:	e8 f9 f5 ff ff       	call   8010332e <mycpu>
80103d35:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103d3b:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103d3e:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103d44:	85 d2                	test   %edx,%edx
80103d46:	78 1d                	js     80103d65 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103d48:	e8 e1 f5 ff ff       	call   8010332e <mycpu>
80103d4d:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103d54:	74 1c                	je     80103d72 <popcli+0x4f>
    sti();
}
80103d56:	c9                   	leave  
80103d57:	c3                   	ret    
    panic("popcli - interruptible");
80103d58:	83 ec 0c             	sub    $0xc,%esp
80103d5b:	68 63 6d 10 80       	push   $0x80106d63
80103d60:	e8 e3 c5 ff ff       	call   80100348 <panic>
    panic("popcli");
80103d65:	83 ec 0c             	sub    $0xc,%esp
80103d68:	68 7a 6d 10 80       	push   $0x80106d7a
80103d6d:	e8 d6 c5 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103d72:	e8 b7 f5 ff ff       	call   8010332e <mycpu>
80103d77:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103d7e:	74 d6                	je     80103d56 <popcli+0x33>
  asm volatile("sti");
80103d80:	fb                   	sti    
}
80103d81:	eb d3                	jmp    80103d56 <popcli+0x33>

80103d83 <holding>:
{
80103d83:	55                   	push   %ebp
80103d84:	89 e5                	mov    %esp,%ebp
80103d86:	53                   	push   %ebx
80103d87:	83 ec 04             	sub    $0x4,%esp
80103d8a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103d8d:	e8 54 ff ff ff       	call   80103ce6 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103d92:	83 3b 00             	cmpl   $0x0,(%ebx)
80103d95:	75 12                	jne    80103da9 <holding+0x26>
80103d97:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103d9c:	e8 82 ff ff ff       	call   80103d23 <popcli>
}
80103da1:	89 d8                	mov    %ebx,%eax
80103da3:	83 c4 04             	add    $0x4,%esp
80103da6:	5b                   	pop    %ebx
80103da7:	5d                   	pop    %ebp
80103da8:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103da9:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103dac:	e8 7d f5 ff ff       	call   8010332e <mycpu>
80103db1:	39 c3                	cmp    %eax,%ebx
80103db3:	74 07                	je     80103dbc <holding+0x39>
80103db5:	bb 00 00 00 00       	mov    $0x0,%ebx
80103dba:	eb e0                	jmp    80103d9c <holding+0x19>
80103dbc:	bb 01 00 00 00       	mov    $0x1,%ebx
80103dc1:	eb d9                	jmp    80103d9c <holding+0x19>

80103dc3 <acquire>:
{
80103dc3:	55                   	push   %ebp
80103dc4:	89 e5                	mov    %esp,%ebp
80103dc6:	53                   	push   %ebx
80103dc7:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103dca:	e8 17 ff ff ff       	call   80103ce6 <pushcli>
  if(holding(lk))
80103dcf:	83 ec 0c             	sub    $0xc,%esp
80103dd2:	ff 75 08             	pushl  0x8(%ebp)
80103dd5:	e8 a9 ff ff ff       	call   80103d83 <holding>
80103dda:	83 c4 10             	add    $0x10,%esp
80103ddd:	85 c0                	test   %eax,%eax
80103ddf:	75 3a                	jne    80103e1b <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103de1:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103de4:	b8 01 00 00 00       	mov    $0x1,%eax
80103de9:	f0 87 02             	lock xchg %eax,(%edx)
80103dec:	85 c0                	test   %eax,%eax
80103dee:	75 f1                	jne    80103de1 <acquire+0x1e>
  __sync_synchronize();
80103df0:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103df5:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103df8:	e8 31 f5 ff ff       	call   8010332e <mycpu>
80103dfd:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103e00:	8b 45 08             	mov    0x8(%ebp),%eax
80103e03:	83 c0 0c             	add    $0xc,%eax
80103e06:	83 ec 08             	sub    $0x8,%esp
80103e09:	50                   	push   %eax
80103e0a:	8d 45 08             	lea    0x8(%ebp),%eax
80103e0d:	50                   	push   %eax
80103e0e:	e8 8f fe ff ff       	call   80103ca2 <getcallerpcs>
}
80103e13:	83 c4 10             	add    $0x10,%esp
80103e16:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103e19:	c9                   	leave  
80103e1a:	c3                   	ret    
    panic("acquire");
80103e1b:	83 ec 0c             	sub    $0xc,%esp
80103e1e:	68 81 6d 10 80       	push   $0x80106d81
80103e23:	e8 20 c5 ff ff       	call   80100348 <panic>

80103e28 <release>:
{
80103e28:	55                   	push   %ebp
80103e29:	89 e5                	mov    %esp,%ebp
80103e2b:	53                   	push   %ebx
80103e2c:	83 ec 10             	sub    $0x10,%esp
80103e2f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103e32:	53                   	push   %ebx
80103e33:	e8 4b ff ff ff       	call   80103d83 <holding>
80103e38:	83 c4 10             	add    $0x10,%esp
80103e3b:	85 c0                	test   %eax,%eax
80103e3d:	74 23                	je     80103e62 <release+0x3a>
  lk->pcs[0] = 0;
80103e3f:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103e46:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103e4d:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103e52:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103e58:	e8 c6 fe ff ff       	call   80103d23 <popcli>
}
80103e5d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103e60:	c9                   	leave  
80103e61:	c3                   	ret    
    panic("release");
80103e62:	83 ec 0c             	sub    $0xc,%esp
80103e65:	68 89 6d 10 80       	push   $0x80106d89
80103e6a:	e8 d9 c4 ff ff       	call   80100348 <panic>

80103e6f <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103e6f:	55                   	push   %ebp
80103e70:	89 e5                	mov    %esp,%ebp
80103e72:	57                   	push   %edi
80103e73:	53                   	push   %ebx
80103e74:	8b 55 08             	mov    0x8(%ebp),%edx
80103e77:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103e7a:	f6 c2 03             	test   $0x3,%dl
80103e7d:	75 05                	jne    80103e84 <memset+0x15>
80103e7f:	f6 c1 03             	test   $0x3,%cl
80103e82:	74 0e                	je     80103e92 <memset+0x23>
  asm volatile("cld; rep stosb" :
80103e84:	89 d7                	mov    %edx,%edi
80103e86:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e89:	fc                   	cld    
80103e8a:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103e8c:	89 d0                	mov    %edx,%eax
80103e8e:	5b                   	pop    %ebx
80103e8f:	5f                   	pop    %edi
80103e90:	5d                   	pop    %ebp
80103e91:	c3                   	ret    
    c &= 0xFF;
80103e92:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103e96:	c1 e9 02             	shr    $0x2,%ecx
80103e99:	89 f8                	mov    %edi,%eax
80103e9b:	c1 e0 18             	shl    $0x18,%eax
80103e9e:	89 fb                	mov    %edi,%ebx
80103ea0:	c1 e3 10             	shl    $0x10,%ebx
80103ea3:	09 d8                	or     %ebx,%eax
80103ea5:	89 fb                	mov    %edi,%ebx
80103ea7:	c1 e3 08             	shl    $0x8,%ebx
80103eaa:	09 d8                	or     %ebx,%eax
80103eac:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103eae:	89 d7                	mov    %edx,%edi
80103eb0:	fc                   	cld    
80103eb1:	f3 ab                	rep stos %eax,%es:(%edi)
80103eb3:	eb d7                	jmp    80103e8c <memset+0x1d>

80103eb5 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103eb5:	55                   	push   %ebp
80103eb6:	89 e5                	mov    %esp,%ebp
80103eb8:	56                   	push   %esi
80103eb9:	53                   	push   %ebx
80103eba:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103ebd:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ec0:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103ec3:	8d 70 ff             	lea    -0x1(%eax),%esi
80103ec6:	85 c0                	test   %eax,%eax
80103ec8:	74 1c                	je     80103ee6 <memcmp+0x31>
    if(*s1 != *s2)
80103eca:	0f b6 01             	movzbl (%ecx),%eax
80103ecd:	0f b6 1a             	movzbl (%edx),%ebx
80103ed0:	38 d8                	cmp    %bl,%al
80103ed2:	75 0a                	jne    80103ede <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103ed4:	83 c1 01             	add    $0x1,%ecx
80103ed7:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103eda:	89 f0                	mov    %esi,%eax
80103edc:	eb e5                	jmp    80103ec3 <memcmp+0xe>
      return *s1 - *s2;
80103ede:	0f b6 c0             	movzbl %al,%eax
80103ee1:	0f b6 db             	movzbl %bl,%ebx
80103ee4:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103ee6:	5b                   	pop    %ebx
80103ee7:	5e                   	pop    %esi
80103ee8:	5d                   	pop    %ebp
80103ee9:	c3                   	ret    

80103eea <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103eea:	55                   	push   %ebp
80103eeb:	89 e5                	mov    %esp,%ebp
80103eed:	56                   	push   %esi
80103eee:	53                   	push   %ebx
80103eef:	8b 45 08             	mov    0x8(%ebp),%eax
80103ef2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103ef5:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103ef8:	39 c1                	cmp    %eax,%ecx
80103efa:	73 3a                	jae    80103f36 <memmove+0x4c>
80103efc:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103eff:	39 c3                	cmp    %eax,%ebx
80103f01:	76 37                	jbe    80103f3a <memmove+0x50>
    s += n;
    d += n;
80103f03:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103f06:	eb 0d                	jmp    80103f15 <memmove+0x2b>
      *--d = *--s;
80103f08:	83 eb 01             	sub    $0x1,%ebx
80103f0b:	83 e9 01             	sub    $0x1,%ecx
80103f0e:	0f b6 13             	movzbl (%ebx),%edx
80103f11:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103f13:	89 f2                	mov    %esi,%edx
80103f15:	8d 72 ff             	lea    -0x1(%edx),%esi
80103f18:	85 d2                	test   %edx,%edx
80103f1a:	75 ec                	jne    80103f08 <memmove+0x1e>
80103f1c:	eb 14                	jmp    80103f32 <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103f1e:	0f b6 11             	movzbl (%ecx),%edx
80103f21:	88 13                	mov    %dl,(%ebx)
80103f23:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103f26:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103f29:	89 f2                	mov    %esi,%edx
80103f2b:	8d 72 ff             	lea    -0x1(%edx),%esi
80103f2e:	85 d2                	test   %edx,%edx
80103f30:	75 ec                	jne    80103f1e <memmove+0x34>

  return dst;
}
80103f32:	5b                   	pop    %ebx
80103f33:	5e                   	pop    %esi
80103f34:	5d                   	pop    %ebp
80103f35:	c3                   	ret    
80103f36:	89 c3                	mov    %eax,%ebx
80103f38:	eb f1                	jmp    80103f2b <memmove+0x41>
80103f3a:	89 c3                	mov    %eax,%ebx
80103f3c:	eb ed                	jmp    80103f2b <memmove+0x41>

80103f3e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103f3e:	55                   	push   %ebp
80103f3f:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103f41:	ff 75 10             	pushl  0x10(%ebp)
80103f44:	ff 75 0c             	pushl  0xc(%ebp)
80103f47:	ff 75 08             	pushl  0x8(%ebp)
80103f4a:	e8 9b ff ff ff       	call   80103eea <memmove>
}
80103f4f:	c9                   	leave  
80103f50:	c3                   	ret    

80103f51 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103f51:	55                   	push   %ebp
80103f52:	89 e5                	mov    %esp,%ebp
80103f54:	53                   	push   %ebx
80103f55:	8b 55 08             	mov    0x8(%ebp),%edx
80103f58:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103f5b:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103f5e:	eb 09                	jmp    80103f69 <strncmp+0x18>
    n--, p++, q++;
80103f60:	83 e8 01             	sub    $0x1,%eax
80103f63:	83 c2 01             	add    $0x1,%edx
80103f66:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103f69:	85 c0                	test   %eax,%eax
80103f6b:	74 0b                	je     80103f78 <strncmp+0x27>
80103f6d:	0f b6 1a             	movzbl (%edx),%ebx
80103f70:	84 db                	test   %bl,%bl
80103f72:	74 04                	je     80103f78 <strncmp+0x27>
80103f74:	3a 19                	cmp    (%ecx),%bl
80103f76:	74 e8                	je     80103f60 <strncmp+0xf>
  if(n == 0)
80103f78:	85 c0                	test   %eax,%eax
80103f7a:	74 0b                	je     80103f87 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103f7c:	0f b6 02             	movzbl (%edx),%eax
80103f7f:	0f b6 11             	movzbl (%ecx),%edx
80103f82:	29 d0                	sub    %edx,%eax
}
80103f84:	5b                   	pop    %ebx
80103f85:	5d                   	pop    %ebp
80103f86:	c3                   	ret    
    return 0;
80103f87:	b8 00 00 00 00       	mov    $0x0,%eax
80103f8c:	eb f6                	jmp    80103f84 <strncmp+0x33>

80103f8e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103f8e:	55                   	push   %ebp
80103f8f:	89 e5                	mov    %esp,%ebp
80103f91:	57                   	push   %edi
80103f92:	56                   	push   %esi
80103f93:	53                   	push   %ebx
80103f94:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103f97:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103f9a:	8b 45 08             	mov    0x8(%ebp),%eax
80103f9d:	eb 04                	jmp    80103fa3 <strncpy+0x15>
80103f9f:	89 fb                	mov    %edi,%ebx
80103fa1:	89 f0                	mov    %esi,%eax
80103fa3:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103fa6:	85 c9                	test   %ecx,%ecx
80103fa8:	7e 1d                	jle    80103fc7 <strncpy+0x39>
80103faa:	8d 7b 01             	lea    0x1(%ebx),%edi
80103fad:	8d 70 01             	lea    0x1(%eax),%esi
80103fb0:	0f b6 1b             	movzbl (%ebx),%ebx
80103fb3:	88 18                	mov    %bl,(%eax)
80103fb5:	89 d1                	mov    %edx,%ecx
80103fb7:	84 db                	test   %bl,%bl
80103fb9:	75 e4                	jne    80103f9f <strncpy+0x11>
80103fbb:	89 f0                	mov    %esi,%eax
80103fbd:	eb 08                	jmp    80103fc7 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103fbf:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103fc2:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103fc4:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103fc7:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103fca:	85 d2                	test   %edx,%edx
80103fcc:	7f f1                	jg     80103fbf <strncpy+0x31>
  return os;
}
80103fce:	8b 45 08             	mov    0x8(%ebp),%eax
80103fd1:	5b                   	pop    %ebx
80103fd2:	5e                   	pop    %esi
80103fd3:	5f                   	pop    %edi
80103fd4:	5d                   	pop    %ebp
80103fd5:	c3                   	ret    

80103fd6 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103fd6:	55                   	push   %ebp
80103fd7:	89 e5                	mov    %esp,%ebp
80103fd9:	57                   	push   %edi
80103fda:	56                   	push   %esi
80103fdb:	53                   	push   %ebx
80103fdc:	8b 45 08             	mov    0x8(%ebp),%eax
80103fdf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103fe2:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80103fe5:	85 d2                	test   %edx,%edx
80103fe7:	7e 23                	jle    8010400c <safestrcpy+0x36>
80103fe9:	89 c1                	mov    %eax,%ecx
80103feb:	eb 04                	jmp    80103ff1 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103fed:	89 fb                	mov    %edi,%ebx
80103fef:	89 f1                	mov    %esi,%ecx
80103ff1:	83 ea 01             	sub    $0x1,%edx
80103ff4:	85 d2                	test   %edx,%edx
80103ff6:	7e 11                	jle    80104009 <safestrcpy+0x33>
80103ff8:	8d 7b 01             	lea    0x1(%ebx),%edi
80103ffb:	8d 71 01             	lea    0x1(%ecx),%esi
80103ffe:	0f b6 1b             	movzbl (%ebx),%ebx
80104001:	88 19                	mov    %bl,(%ecx)
80104003:	84 db                	test   %bl,%bl
80104005:	75 e6                	jne    80103fed <safestrcpy+0x17>
80104007:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80104009:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
8010400c:	5b                   	pop    %ebx
8010400d:	5e                   	pop    %esi
8010400e:	5f                   	pop    %edi
8010400f:	5d                   	pop    %ebp
80104010:	c3                   	ret    

80104011 <strlen>:

int
strlen(const char *s)
{
80104011:	55                   	push   %ebp
80104012:	89 e5                	mov    %esp,%ebp
80104014:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80104017:	b8 00 00 00 00       	mov    $0x0,%eax
8010401c:	eb 03                	jmp    80104021 <strlen+0x10>
8010401e:	83 c0 01             	add    $0x1,%eax
80104021:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80104025:	75 f7                	jne    8010401e <strlen+0xd>
    ;
  return n;
}
80104027:	5d                   	pop    %ebp
80104028:	c3                   	ret    

80104029 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80104029:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
8010402d:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80104031:	55                   	push   %ebp
  pushl %ebx
80104032:	53                   	push   %ebx
  pushl %esi
80104033:	56                   	push   %esi
  pushl %edi
80104034:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80104035:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80104037:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80104039:	5f                   	pop    %edi
  popl %esi
8010403a:	5e                   	pop    %esi
  popl %ebx
8010403b:	5b                   	pop    %ebx
  popl %ebp
8010403c:	5d                   	pop    %ebp
  ret
8010403d:	c3                   	ret    

8010403e <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
8010403e:	55                   	push   %ebp
8010403f:	89 e5                	mov    %esp,%ebp
80104041:	53                   	push   %ebx
80104042:	83 ec 04             	sub    $0x4,%esp
80104045:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80104048:	e8 58 f3 ff ff       	call   801033a5 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
8010404d:	8b 00                	mov    (%eax),%eax
8010404f:	39 d8                	cmp    %ebx,%eax
80104051:	76 19                	jbe    8010406c <fetchint+0x2e>
80104053:	8d 53 04             	lea    0x4(%ebx),%edx
80104056:	39 d0                	cmp    %edx,%eax
80104058:	72 19                	jb     80104073 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
8010405a:	8b 13                	mov    (%ebx),%edx
8010405c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010405f:	89 10                	mov    %edx,(%eax)
  return 0;
80104061:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104066:	83 c4 04             	add    $0x4,%esp
80104069:	5b                   	pop    %ebx
8010406a:	5d                   	pop    %ebp
8010406b:	c3                   	ret    
    return -1;
8010406c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104071:	eb f3                	jmp    80104066 <fetchint+0x28>
80104073:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104078:	eb ec                	jmp    80104066 <fetchint+0x28>

8010407a <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
8010407a:	55                   	push   %ebp
8010407b:	89 e5                	mov    %esp,%ebp
8010407d:	53                   	push   %ebx
8010407e:	83 ec 04             	sub    $0x4,%esp
80104081:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80104084:	e8 1c f3 ff ff       	call   801033a5 <myproc>

  if(addr >= curproc->sz)
80104089:	39 18                	cmp    %ebx,(%eax)
8010408b:	76 26                	jbe    801040b3 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
8010408d:	8b 55 0c             	mov    0xc(%ebp),%edx
80104090:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80104092:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80104094:	89 d8                	mov    %ebx,%eax
80104096:	39 d0                	cmp    %edx,%eax
80104098:	73 0e                	jae    801040a8 <fetchstr+0x2e>
    if(*s == 0)
8010409a:	80 38 00             	cmpb   $0x0,(%eax)
8010409d:	74 05                	je     801040a4 <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
8010409f:	83 c0 01             	add    $0x1,%eax
801040a2:	eb f2                	jmp    80104096 <fetchstr+0x1c>
      return s - *pp;
801040a4:	29 d8                	sub    %ebx,%eax
801040a6:	eb 05                	jmp    801040ad <fetchstr+0x33>
  }
  return -1;
801040a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801040ad:	83 c4 04             	add    $0x4,%esp
801040b0:	5b                   	pop    %ebx
801040b1:	5d                   	pop    %ebp
801040b2:	c3                   	ret    
    return -1;
801040b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040b8:	eb f3                	jmp    801040ad <fetchstr+0x33>

801040ba <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801040ba:	55                   	push   %ebp
801040bb:	89 e5                	mov    %esp,%ebp
801040bd:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
801040c0:	e8 e0 f2 ff ff       	call   801033a5 <myproc>
801040c5:	8b 50 18             	mov    0x18(%eax),%edx
801040c8:	8b 45 08             	mov    0x8(%ebp),%eax
801040cb:	c1 e0 02             	shl    $0x2,%eax
801040ce:	03 42 44             	add    0x44(%edx),%eax
801040d1:	83 ec 08             	sub    $0x8,%esp
801040d4:	ff 75 0c             	pushl  0xc(%ebp)
801040d7:	83 c0 04             	add    $0x4,%eax
801040da:	50                   	push   %eax
801040db:	e8 5e ff ff ff       	call   8010403e <fetchint>
}
801040e0:	c9                   	leave  
801040e1:	c3                   	ret    

801040e2 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801040e2:	55                   	push   %ebp
801040e3:	89 e5                	mov    %esp,%ebp
801040e5:	56                   	push   %esi
801040e6:	53                   	push   %ebx
801040e7:	83 ec 10             	sub    $0x10,%esp
801040ea:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
801040ed:	e8 b3 f2 ff ff       	call   801033a5 <myproc>
801040f2:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
801040f4:	83 ec 08             	sub    $0x8,%esp
801040f7:	8d 45 f4             	lea    -0xc(%ebp),%eax
801040fa:	50                   	push   %eax
801040fb:	ff 75 08             	pushl  0x8(%ebp)
801040fe:	e8 b7 ff ff ff       	call   801040ba <argint>
80104103:	83 c4 10             	add    $0x10,%esp
80104106:	85 c0                	test   %eax,%eax
80104108:	78 24                	js     8010412e <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
8010410a:	85 db                	test   %ebx,%ebx
8010410c:	78 27                	js     80104135 <argptr+0x53>
8010410e:	8b 16                	mov    (%esi),%edx
80104110:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104113:	39 c2                	cmp    %eax,%edx
80104115:	76 25                	jbe    8010413c <argptr+0x5a>
80104117:	01 c3                	add    %eax,%ebx
80104119:	39 da                	cmp    %ebx,%edx
8010411b:	72 26                	jb     80104143 <argptr+0x61>
    return -1;
  *pp = (char*)i;
8010411d:	8b 55 0c             	mov    0xc(%ebp),%edx
80104120:	89 02                	mov    %eax,(%edx)
  return 0;
80104122:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104127:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010412a:	5b                   	pop    %ebx
8010412b:	5e                   	pop    %esi
8010412c:	5d                   	pop    %ebp
8010412d:	c3                   	ret    
    return -1;
8010412e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104133:	eb f2                	jmp    80104127 <argptr+0x45>
    return -1;
80104135:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010413a:	eb eb                	jmp    80104127 <argptr+0x45>
8010413c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104141:	eb e4                	jmp    80104127 <argptr+0x45>
80104143:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104148:	eb dd                	jmp    80104127 <argptr+0x45>

8010414a <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
8010414a:	55                   	push   %ebp
8010414b:	89 e5                	mov    %esp,%ebp
8010414d:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80104150:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104153:	50                   	push   %eax
80104154:	ff 75 08             	pushl  0x8(%ebp)
80104157:	e8 5e ff ff ff       	call   801040ba <argint>
8010415c:	83 c4 10             	add    $0x10,%esp
8010415f:	85 c0                	test   %eax,%eax
80104161:	78 13                	js     80104176 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
80104163:	83 ec 08             	sub    $0x8,%esp
80104166:	ff 75 0c             	pushl  0xc(%ebp)
80104169:	ff 75 f4             	pushl  -0xc(%ebp)
8010416c:	e8 09 ff ff ff       	call   8010407a <fetchstr>
80104171:	83 c4 10             	add    $0x10,%esp
}
80104174:	c9                   	leave  
80104175:	c3                   	ret    
    return -1;
80104176:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010417b:	eb f7                	jmp    80104174 <argstr+0x2a>

8010417d <syscall>:
[SYS_dump_physmem]  sys_dump_physmem,
};

void
syscall(void)
{
8010417d:	55                   	push   %ebp
8010417e:	89 e5                	mov    %esp,%ebp
80104180:	53                   	push   %ebx
80104181:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
80104184:	e8 1c f2 ff ff       	call   801033a5 <myproc>
80104189:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
8010418b:	8b 40 18             	mov    0x18(%eax),%eax
8010418e:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80104191:	8d 50 ff             	lea    -0x1(%eax),%edx
80104194:	83 fa 15             	cmp    $0x15,%edx
80104197:	77 18                	ja     801041b1 <syscall+0x34>
80104199:	8b 14 85 c0 6d 10 80 	mov    -0x7fef9240(,%eax,4),%edx
801041a0:	85 d2                	test   %edx,%edx
801041a2:	74 0d                	je     801041b1 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
801041a4:	ff d2                	call   *%edx
801041a6:	8b 53 18             	mov    0x18(%ebx),%edx
801041a9:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
801041ac:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801041af:	c9                   	leave  
801041b0:	c3                   	ret    
            curproc->pid, curproc->name, num);
801041b1:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801041b4:	50                   	push   %eax
801041b5:	52                   	push   %edx
801041b6:	ff 73 10             	pushl  0x10(%ebx)
801041b9:	68 91 6d 10 80       	push   $0x80106d91
801041be:	e8 48 c4 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
801041c3:	8b 43 18             	mov    0x18(%ebx),%eax
801041c6:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
801041cd:	83 c4 10             	add    $0x10,%esp
801041d0:	eb da                	jmp    801041ac <syscall+0x2f>

801041d2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801041d2:	55                   	push   %ebp
801041d3:	89 e5                	mov    %esp,%ebp
801041d5:	56                   	push   %esi
801041d6:	53                   	push   %ebx
801041d7:	83 ec 18             	sub    $0x18,%esp
801041da:	89 d6                	mov    %edx,%esi
801041dc:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801041de:	8d 55 f4             	lea    -0xc(%ebp),%edx
801041e1:	52                   	push   %edx
801041e2:	50                   	push   %eax
801041e3:	e8 d2 fe ff ff       	call   801040ba <argint>
801041e8:	83 c4 10             	add    $0x10,%esp
801041eb:	85 c0                	test   %eax,%eax
801041ed:	78 2e                	js     8010421d <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
801041ef:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801041f3:	77 2f                	ja     80104224 <argfd+0x52>
801041f5:	e8 ab f1 ff ff       	call   801033a5 <myproc>
801041fa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041fd:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
80104201:	85 c0                	test   %eax,%eax
80104203:	74 26                	je     8010422b <argfd+0x59>
    return -1;
  if(pfd)
80104205:	85 f6                	test   %esi,%esi
80104207:	74 02                	je     8010420b <argfd+0x39>
    *pfd = fd;
80104209:	89 16                	mov    %edx,(%esi)
  if(pf)
8010420b:	85 db                	test   %ebx,%ebx
8010420d:	74 23                	je     80104232 <argfd+0x60>
    *pf = f;
8010420f:	89 03                	mov    %eax,(%ebx)
  return 0;
80104211:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104216:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104219:	5b                   	pop    %ebx
8010421a:	5e                   	pop    %esi
8010421b:	5d                   	pop    %ebp
8010421c:	c3                   	ret    
    return -1;
8010421d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104222:	eb f2                	jmp    80104216 <argfd+0x44>
    return -1;
80104224:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104229:	eb eb                	jmp    80104216 <argfd+0x44>
8010422b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104230:	eb e4                	jmp    80104216 <argfd+0x44>
  return 0;
80104232:	b8 00 00 00 00       	mov    $0x0,%eax
80104237:	eb dd                	jmp    80104216 <argfd+0x44>

80104239 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104239:	55                   	push   %ebp
8010423a:	89 e5                	mov    %esp,%ebp
8010423c:	53                   	push   %ebx
8010423d:	83 ec 04             	sub    $0x4,%esp
80104240:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
80104242:	e8 5e f1 ff ff       	call   801033a5 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104247:	ba 00 00 00 00       	mov    $0x0,%edx
8010424c:	83 fa 0f             	cmp    $0xf,%edx
8010424f:	7f 18                	jg     80104269 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
80104251:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
80104256:	74 05                	je     8010425d <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104258:	83 c2 01             	add    $0x1,%edx
8010425b:	eb ef                	jmp    8010424c <fdalloc+0x13>
      curproc->ofile[fd] = f;
8010425d:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
80104261:	89 d0                	mov    %edx,%eax
80104263:	83 c4 04             	add    $0x4,%esp
80104266:	5b                   	pop    %ebx
80104267:	5d                   	pop    %ebp
80104268:	c3                   	ret    
  return -1;
80104269:	ba ff ff ff ff       	mov    $0xffffffff,%edx
8010426e:	eb f1                	jmp    80104261 <fdalloc+0x28>

80104270 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80104270:	55                   	push   %ebp
80104271:	89 e5                	mov    %esp,%ebp
80104273:	56                   	push   %esi
80104274:	53                   	push   %ebx
80104275:	83 ec 10             	sub    $0x10,%esp
80104278:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010427a:	b8 20 00 00 00       	mov    $0x20,%eax
8010427f:	89 c6                	mov    %eax,%esi
80104281:	39 43 58             	cmp    %eax,0x58(%ebx)
80104284:	76 2e                	jbe    801042b4 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104286:	6a 10                	push   $0x10
80104288:	50                   	push   %eax
80104289:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010428c:	50                   	push   %eax
8010428d:	53                   	push   %ebx
8010428e:	e8 e0 d4 ff ff       	call   80101773 <readi>
80104293:	83 c4 10             	add    $0x10,%esp
80104296:	83 f8 10             	cmp    $0x10,%eax
80104299:	75 0c                	jne    801042a7 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
8010429b:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
801042a0:	75 1e                	jne    801042c0 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801042a2:	8d 46 10             	lea    0x10(%esi),%eax
801042a5:	eb d8                	jmp    8010427f <isdirempty+0xf>
      panic("isdirempty: readi");
801042a7:	83 ec 0c             	sub    $0xc,%esp
801042aa:	68 1c 6e 10 80       	push   $0x80106e1c
801042af:	e8 94 c0 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
801042b4:	b8 01 00 00 00       	mov    $0x1,%eax
}
801042b9:	8d 65 f8             	lea    -0x8(%ebp),%esp
801042bc:	5b                   	pop    %ebx
801042bd:	5e                   	pop    %esi
801042be:	5d                   	pop    %ebp
801042bf:	c3                   	ret    
      return 0;
801042c0:	b8 00 00 00 00       	mov    $0x0,%eax
801042c5:	eb f2                	jmp    801042b9 <isdirempty+0x49>

801042c7 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
801042c7:	55                   	push   %ebp
801042c8:	89 e5                	mov    %esp,%ebp
801042ca:	57                   	push   %edi
801042cb:	56                   	push   %esi
801042cc:	53                   	push   %ebx
801042cd:	83 ec 44             	sub    $0x44,%esp
801042d0:	89 55 c4             	mov    %edx,-0x3c(%ebp)
801042d3:	89 4d c0             	mov    %ecx,-0x40(%ebp)
801042d6:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801042d9:	8d 55 d6             	lea    -0x2a(%ebp),%edx
801042dc:	52                   	push   %edx
801042dd:	50                   	push   %eax
801042de:	e8 16 d9 ff ff       	call   80101bf9 <nameiparent>
801042e3:	89 c6                	mov    %eax,%esi
801042e5:	83 c4 10             	add    $0x10,%esp
801042e8:	85 c0                	test   %eax,%eax
801042ea:	0f 84 3a 01 00 00    	je     8010442a <create+0x163>
    return 0;
  ilock(dp);
801042f0:	83 ec 0c             	sub    $0xc,%esp
801042f3:	50                   	push   %eax
801042f4:	e8 88 d2 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801042f9:	83 c4 0c             	add    $0xc,%esp
801042fc:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801042ff:	50                   	push   %eax
80104300:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104303:	50                   	push   %eax
80104304:	56                   	push   %esi
80104305:	e8 a6 d6 ff ff       	call   801019b0 <dirlookup>
8010430a:	89 c3                	mov    %eax,%ebx
8010430c:	83 c4 10             	add    $0x10,%esp
8010430f:	85 c0                	test   %eax,%eax
80104311:	74 3f                	je     80104352 <create+0x8b>
    iunlockput(dp);
80104313:	83 ec 0c             	sub    $0xc,%esp
80104316:	56                   	push   %esi
80104317:	e8 0c d4 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
8010431c:	89 1c 24             	mov    %ebx,(%esp)
8010431f:	e8 5d d2 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80104324:	83 c4 10             	add    $0x10,%esp
80104327:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
8010432c:	75 11                	jne    8010433f <create+0x78>
8010432e:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
80104333:	75 0a                	jne    8010433f <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
80104335:	89 d8                	mov    %ebx,%eax
80104337:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010433a:	5b                   	pop    %ebx
8010433b:	5e                   	pop    %esi
8010433c:	5f                   	pop    %edi
8010433d:	5d                   	pop    %ebp
8010433e:	c3                   	ret    
    iunlockput(ip);
8010433f:	83 ec 0c             	sub    $0xc,%esp
80104342:	53                   	push   %ebx
80104343:	e8 e0 d3 ff ff       	call   80101728 <iunlockput>
    return 0;
80104348:	83 c4 10             	add    $0x10,%esp
8010434b:	bb 00 00 00 00       	mov    $0x0,%ebx
80104350:	eb e3                	jmp    80104335 <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
80104352:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104356:	83 ec 08             	sub    $0x8,%esp
80104359:	50                   	push   %eax
8010435a:	ff 36                	pushl  (%esi)
8010435c:	e8 1d d0 ff ff       	call   8010137e <ialloc>
80104361:	89 c3                	mov    %eax,%ebx
80104363:	83 c4 10             	add    $0x10,%esp
80104366:	85 c0                	test   %eax,%eax
80104368:	74 55                	je     801043bf <create+0xf8>
  ilock(ip);
8010436a:	83 ec 0c             	sub    $0xc,%esp
8010436d:	50                   	push   %eax
8010436e:	e8 0e d2 ff ff       	call   80101581 <ilock>
  ip->major = major;
80104373:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
80104377:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
8010437b:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
8010437f:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
80104385:	89 1c 24             	mov    %ebx,(%esp)
80104388:	e8 93 d0 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
8010438d:	83 c4 10             	add    $0x10,%esp
80104390:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
80104395:	74 35                	je     801043cc <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
80104397:	83 ec 04             	sub    $0x4,%esp
8010439a:	ff 73 04             	pushl  0x4(%ebx)
8010439d:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801043a0:	50                   	push   %eax
801043a1:	56                   	push   %esi
801043a2:	e8 89 d7 ff ff       	call   80101b30 <dirlink>
801043a7:	83 c4 10             	add    $0x10,%esp
801043aa:	85 c0                	test   %eax,%eax
801043ac:	78 6f                	js     8010441d <create+0x156>
  iunlockput(dp);
801043ae:	83 ec 0c             	sub    $0xc,%esp
801043b1:	56                   	push   %esi
801043b2:	e8 71 d3 ff ff       	call   80101728 <iunlockput>
  return ip;
801043b7:	83 c4 10             	add    $0x10,%esp
801043ba:	e9 76 ff ff ff       	jmp    80104335 <create+0x6e>
    panic("create: ialloc");
801043bf:	83 ec 0c             	sub    $0xc,%esp
801043c2:	68 2e 6e 10 80       	push   $0x80106e2e
801043c7:	e8 7c bf ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
801043cc:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801043d0:	83 c0 01             	add    $0x1,%eax
801043d3:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801043d7:	83 ec 0c             	sub    $0xc,%esp
801043da:	56                   	push   %esi
801043db:	e8 40 d0 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801043e0:	83 c4 0c             	add    $0xc,%esp
801043e3:	ff 73 04             	pushl  0x4(%ebx)
801043e6:	68 3e 6e 10 80       	push   $0x80106e3e
801043eb:	53                   	push   %ebx
801043ec:	e8 3f d7 ff ff       	call   80101b30 <dirlink>
801043f1:	83 c4 10             	add    $0x10,%esp
801043f4:	85 c0                	test   %eax,%eax
801043f6:	78 18                	js     80104410 <create+0x149>
801043f8:	83 ec 04             	sub    $0x4,%esp
801043fb:	ff 76 04             	pushl  0x4(%esi)
801043fe:	68 3d 6e 10 80       	push   $0x80106e3d
80104403:	53                   	push   %ebx
80104404:	e8 27 d7 ff ff       	call   80101b30 <dirlink>
80104409:	83 c4 10             	add    $0x10,%esp
8010440c:	85 c0                	test   %eax,%eax
8010440e:	79 87                	jns    80104397 <create+0xd0>
      panic("create dots");
80104410:	83 ec 0c             	sub    $0xc,%esp
80104413:	68 40 6e 10 80       	push   $0x80106e40
80104418:	e8 2b bf ff ff       	call   80100348 <panic>
    panic("create: dirlink");
8010441d:	83 ec 0c             	sub    $0xc,%esp
80104420:	68 4c 6e 10 80       	push   $0x80106e4c
80104425:	e8 1e bf ff ff       	call   80100348 <panic>
    return 0;
8010442a:	89 c3                	mov    %eax,%ebx
8010442c:	e9 04 ff ff ff       	jmp    80104335 <create+0x6e>

80104431 <sys_dup>:
{
80104431:	55                   	push   %ebp
80104432:	89 e5                	mov    %esp,%ebp
80104434:	53                   	push   %ebx
80104435:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104438:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010443b:	ba 00 00 00 00       	mov    $0x0,%edx
80104440:	b8 00 00 00 00       	mov    $0x0,%eax
80104445:	e8 88 fd ff ff       	call   801041d2 <argfd>
8010444a:	85 c0                	test   %eax,%eax
8010444c:	78 23                	js     80104471 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
8010444e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104451:	e8 e3 fd ff ff       	call   80104239 <fdalloc>
80104456:	89 c3                	mov    %eax,%ebx
80104458:	85 c0                	test   %eax,%eax
8010445a:	78 1c                	js     80104478 <sys_dup+0x47>
  filedup(f);
8010445c:	83 ec 0c             	sub    $0xc,%esp
8010445f:	ff 75 f4             	pushl  -0xc(%ebp)
80104462:	e8 27 c8 ff ff       	call   80100c8e <filedup>
  return fd;
80104467:	83 c4 10             	add    $0x10,%esp
}
8010446a:	89 d8                	mov    %ebx,%eax
8010446c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010446f:	c9                   	leave  
80104470:	c3                   	ret    
    return -1;
80104471:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104476:	eb f2                	jmp    8010446a <sys_dup+0x39>
    return -1;
80104478:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010447d:	eb eb                	jmp    8010446a <sys_dup+0x39>

8010447f <sys_read>:
{
8010447f:	55                   	push   %ebp
80104480:	89 e5                	mov    %esp,%ebp
80104482:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104485:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104488:	ba 00 00 00 00       	mov    $0x0,%edx
8010448d:	b8 00 00 00 00       	mov    $0x0,%eax
80104492:	e8 3b fd ff ff       	call   801041d2 <argfd>
80104497:	85 c0                	test   %eax,%eax
80104499:	78 43                	js     801044de <sys_read+0x5f>
8010449b:	83 ec 08             	sub    $0x8,%esp
8010449e:	8d 45 f0             	lea    -0x10(%ebp),%eax
801044a1:	50                   	push   %eax
801044a2:	6a 02                	push   $0x2
801044a4:	e8 11 fc ff ff       	call   801040ba <argint>
801044a9:	83 c4 10             	add    $0x10,%esp
801044ac:	85 c0                	test   %eax,%eax
801044ae:	78 35                	js     801044e5 <sys_read+0x66>
801044b0:	83 ec 04             	sub    $0x4,%esp
801044b3:	ff 75 f0             	pushl  -0x10(%ebp)
801044b6:	8d 45 ec             	lea    -0x14(%ebp),%eax
801044b9:	50                   	push   %eax
801044ba:	6a 01                	push   $0x1
801044bc:	e8 21 fc ff ff       	call   801040e2 <argptr>
801044c1:	83 c4 10             	add    $0x10,%esp
801044c4:	85 c0                	test   %eax,%eax
801044c6:	78 24                	js     801044ec <sys_read+0x6d>
  return fileread(f, p, n);
801044c8:	83 ec 04             	sub    $0x4,%esp
801044cb:	ff 75 f0             	pushl  -0x10(%ebp)
801044ce:	ff 75 ec             	pushl  -0x14(%ebp)
801044d1:	ff 75 f4             	pushl  -0xc(%ebp)
801044d4:	e8 fe c8 ff ff       	call   80100dd7 <fileread>
801044d9:	83 c4 10             	add    $0x10,%esp
}
801044dc:	c9                   	leave  
801044dd:	c3                   	ret    
    return -1;
801044de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044e3:	eb f7                	jmp    801044dc <sys_read+0x5d>
801044e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044ea:	eb f0                	jmp    801044dc <sys_read+0x5d>
801044ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044f1:	eb e9                	jmp    801044dc <sys_read+0x5d>

801044f3 <sys_write>:
{
801044f3:	55                   	push   %ebp
801044f4:	89 e5                	mov    %esp,%ebp
801044f6:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801044f9:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801044fc:	ba 00 00 00 00       	mov    $0x0,%edx
80104501:	b8 00 00 00 00       	mov    $0x0,%eax
80104506:	e8 c7 fc ff ff       	call   801041d2 <argfd>
8010450b:	85 c0                	test   %eax,%eax
8010450d:	78 43                	js     80104552 <sys_write+0x5f>
8010450f:	83 ec 08             	sub    $0x8,%esp
80104512:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104515:	50                   	push   %eax
80104516:	6a 02                	push   $0x2
80104518:	e8 9d fb ff ff       	call   801040ba <argint>
8010451d:	83 c4 10             	add    $0x10,%esp
80104520:	85 c0                	test   %eax,%eax
80104522:	78 35                	js     80104559 <sys_write+0x66>
80104524:	83 ec 04             	sub    $0x4,%esp
80104527:	ff 75 f0             	pushl  -0x10(%ebp)
8010452a:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010452d:	50                   	push   %eax
8010452e:	6a 01                	push   $0x1
80104530:	e8 ad fb ff ff       	call   801040e2 <argptr>
80104535:	83 c4 10             	add    $0x10,%esp
80104538:	85 c0                	test   %eax,%eax
8010453a:	78 24                	js     80104560 <sys_write+0x6d>
  return filewrite(f, p, n);
8010453c:	83 ec 04             	sub    $0x4,%esp
8010453f:	ff 75 f0             	pushl  -0x10(%ebp)
80104542:	ff 75 ec             	pushl  -0x14(%ebp)
80104545:	ff 75 f4             	pushl  -0xc(%ebp)
80104548:	e8 0f c9 ff ff       	call   80100e5c <filewrite>
8010454d:	83 c4 10             	add    $0x10,%esp
}
80104550:	c9                   	leave  
80104551:	c3                   	ret    
    return -1;
80104552:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104557:	eb f7                	jmp    80104550 <sys_write+0x5d>
80104559:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010455e:	eb f0                	jmp    80104550 <sys_write+0x5d>
80104560:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104565:	eb e9                	jmp    80104550 <sys_write+0x5d>

80104567 <sys_close>:
{
80104567:	55                   	push   %ebp
80104568:	89 e5                	mov    %esp,%ebp
8010456a:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
8010456d:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104570:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104573:	b8 00 00 00 00       	mov    $0x0,%eax
80104578:	e8 55 fc ff ff       	call   801041d2 <argfd>
8010457d:	85 c0                	test   %eax,%eax
8010457f:	78 25                	js     801045a6 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
80104581:	e8 1f ee ff ff       	call   801033a5 <myproc>
80104586:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104589:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
80104590:	00 
  fileclose(f);
80104591:	83 ec 0c             	sub    $0xc,%esp
80104594:	ff 75 f0             	pushl  -0x10(%ebp)
80104597:	e8 37 c7 ff ff       	call   80100cd3 <fileclose>
  return 0;
8010459c:	83 c4 10             	add    $0x10,%esp
8010459f:	b8 00 00 00 00       	mov    $0x0,%eax
}
801045a4:	c9                   	leave  
801045a5:	c3                   	ret    
    return -1;
801045a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045ab:	eb f7                	jmp    801045a4 <sys_close+0x3d>

801045ad <sys_fstat>:
{
801045ad:	55                   	push   %ebp
801045ae:	89 e5                	mov    %esp,%ebp
801045b0:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801045b3:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801045b6:	ba 00 00 00 00       	mov    $0x0,%edx
801045bb:	b8 00 00 00 00       	mov    $0x0,%eax
801045c0:	e8 0d fc ff ff       	call   801041d2 <argfd>
801045c5:	85 c0                	test   %eax,%eax
801045c7:	78 2a                	js     801045f3 <sys_fstat+0x46>
801045c9:	83 ec 04             	sub    $0x4,%esp
801045cc:	6a 14                	push   $0x14
801045ce:	8d 45 f0             	lea    -0x10(%ebp),%eax
801045d1:	50                   	push   %eax
801045d2:	6a 01                	push   $0x1
801045d4:	e8 09 fb ff ff       	call   801040e2 <argptr>
801045d9:	83 c4 10             	add    $0x10,%esp
801045dc:	85 c0                	test   %eax,%eax
801045de:	78 1a                	js     801045fa <sys_fstat+0x4d>
  return filestat(f, st);
801045e0:	83 ec 08             	sub    $0x8,%esp
801045e3:	ff 75 f0             	pushl  -0x10(%ebp)
801045e6:	ff 75 f4             	pushl  -0xc(%ebp)
801045e9:	e8 a2 c7 ff ff       	call   80100d90 <filestat>
801045ee:	83 c4 10             	add    $0x10,%esp
}
801045f1:	c9                   	leave  
801045f2:	c3                   	ret    
    return -1;
801045f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045f8:	eb f7                	jmp    801045f1 <sys_fstat+0x44>
801045fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045ff:	eb f0                	jmp    801045f1 <sys_fstat+0x44>

80104601 <sys_link>:
{
80104601:	55                   	push   %ebp
80104602:	89 e5                	mov    %esp,%ebp
80104604:	56                   	push   %esi
80104605:	53                   	push   %ebx
80104606:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104609:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010460c:	50                   	push   %eax
8010460d:	6a 00                	push   $0x0
8010460f:	e8 36 fb ff ff       	call   8010414a <argstr>
80104614:	83 c4 10             	add    $0x10,%esp
80104617:	85 c0                	test   %eax,%eax
80104619:	0f 88 32 01 00 00    	js     80104751 <sys_link+0x150>
8010461f:	83 ec 08             	sub    $0x8,%esp
80104622:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104625:	50                   	push   %eax
80104626:	6a 01                	push   $0x1
80104628:	e8 1d fb ff ff       	call   8010414a <argstr>
8010462d:	83 c4 10             	add    $0x10,%esp
80104630:	85 c0                	test   %eax,%eax
80104632:	0f 88 20 01 00 00    	js     80104758 <sys_link+0x157>
  begin_op();
80104638:	e8 07 e3 ff ff       	call   80102944 <begin_op>
  if((ip = namei(old)) == 0){
8010463d:	83 ec 0c             	sub    $0xc,%esp
80104640:	ff 75 e0             	pushl  -0x20(%ebp)
80104643:	e8 99 d5 ff ff       	call   80101be1 <namei>
80104648:	89 c3                	mov    %eax,%ebx
8010464a:	83 c4 10             	add    $0x10,%esp
8010464d:	85 c0                	test   %eax,%eax
8010464f:	0f 84 99 00 00 00    	je     801046ee <sys_link+0xed>
  ilock(ip);
80104655:	83 ec 0c             	sub    $0xc,%esp
80104658:	50                   	push   %eax
80104659:	e8 23 cf ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
8010465e:	83 c4 10             	add    $0x10,%esp
80104661:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104666:	0f 84 8e 00 00 00    	je     801046fa <sys_link+0xf9>
  ip->nlink++;
8010466c:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104670:	83 c0 01             	add    $0x1,%eax
80104673:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104677:	83 ec 0c             	sub    $0xc,%esp
8010467a:	53                   	push   %ebx
8010467b:	e8 a0 cd ff ff       	call   80101420 <iupdate>
  iunlock(ip);
80104680:	89 1c 24             	mov    %ebx,(%esp)
80104683:	e8 bb cf ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
80104688:	83 c4 08             	add    $0x8,%esp
8010468b:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010468e:	50                   	push   %eax
8010468f:	ff 75 e4             	pushl  -0x1c(%ebp)
80104692:	e8 62 d5 ff ff       	call   80101bf9 <nameiparent>
80104697:	89 c6                	mov    %eax,%esi
80104699:	83 c4 10             	add    $0x10,%esp
8010469c:	85 c0                	test   %eax,%eax
8010469e:	74 7e                	je     8010471e <sys_link+0x11d>
  ilock(dp);
801046a0:	83 ec 0c             	sub    $0xc,%esp
801046a3:	50                   	push   %eax
801046a4:	e8 d8 ce ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801046a9:	83 c4 10             	add    $0x10,%esp
801046ac:	8b 03                	mov    (%ebx),%eax
801046ae:	39 06                	cmp    %eax,(%esi)
801046b0:	75 60                	jne    80104712 <sys_link+0x111>
801046b2:	83 ec 04             	sub    $0x4,%esp
801046b5:	ff 73 04             	pushl  0x4(%ebx)
801046b8:	8d 45 ea             	lea    -0x16(%ebp),%eax
801046bb:	50                   	push   %eax
801046bc:	56                   	push   %esi
801046bd:	e8 6e d4 ff ff       	call   80101b30 <dirlink>
801046c2:	83 c4 10             	add    $0x10,%esp
801046c5:	85 c0                	test   %eax,%eax
801046c7:	78 49                	js     80104712 <sys_link+0x111>
  iunlockput(dp);
801046c9:	83 ec 0c             	sub    $0xc,%esp
801046cc:	56                   	push   %esi
801046cd:	e8 56 d0 ff ff       	call   80101728 <iunlockput>
  iput(ip);
801046d2:	89 1c 24             	mov    %ebx,(%esp)
801046d5:	e8 ae cf ff ff       	call   80101688 <iput>
  end_op();
801046da:	e8 df e2 ff ff       	call   801029be <end_op>
  return 0;
801046df:	83 c4 10             	add    $0x10,%esp
801046e2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801046e7:	8d 65 f8             	lea    -0x8(%ebp),%esp
801046ea:	5b                   	pop    %ebx
801046eb:	5e                   	pop    %esi
801046ec:	5d                   	pop    %ebp
801046ed:	c3                   	ret    
    end_op();
801046ee:	e8 cb e2 ff ff       	call   801029be <end_op>
    return -1;
801046f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046f8:	eb ed                	jmp    801046e7 <sys_link+0xe6>
    iunlockput(ip);
801046fa:	83 ec 0c             	sub    $0xc,%esp
801046fd:	53                   	push   %ebx
801046fe:	e8 25 d0 ff ff       	call   80101728 <iunlockput>
    end_op();
80104703:	e8 b6 e2 ff ff       	call   801029be <end_op>
    return -1;
80104708:	83 c4 10             	add    $0x10,%esp
8010470b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104710:	eb d5                	jmp    801046e7 <sys_link+0xe6>
    iunlockput(dp);
80104712:	83 ec 0c             	sub    $0xc,%esp
80104715:	56                   	push   %esi
80104716:	e8 0d d0 ff ff       	call   80101728 <iunlockput>
    goto bad;
8010471b:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
8010471e:	83 ec 0c             	sub    $0xc,%esp
80104721:	53                   	push   %ebx
80104722:	e8 5a ce ff ff       	call   80101581 <ilock>
  ip->nlink--;
80104727:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010472b:	83 e8 01             	sub    $0x1,%eax
8010472e:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104732:	89 1c 24             	mov    %ebx,(%esp)
80104735:	e8 e6 cc ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
8010473a:	89 1c 24             	mov    %ebx,(%esp)
8010473d:	e8 e6 cf ff ff       	call   80101728 <iunlockput>
  end_op();
80104742:	e8 77 e2 ff ff       	call   801029be <end_op>
  return -1;
80104747:	83 c4 10             	add    $0x10,%esp
8010474a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010474f:	eb 96                	jmp    801046e7 <sys_link+0xe6>
    return -1;
80104751:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104756:	eb 8f                	jmp    801046e7 <sys_link+0xe6>
80104758:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010475d:	eb 88                	jmp    801046e7 <sys_link+0xe6>

8010475f <sys_unlink>:
{
8010475f:	55                   	push   %ebp
80104760:	89 e5                	mov    %esp,%ebp
80104762:	57                   	push   %edi
80104763:	56                   	push   %esi
80104764:	53                   	push   %ebx
80104765:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104768:	8d 45 c4             	lea    -0x3c(%ebp),%eax
8010476b:	50                   	push   %eax
8010476c:	6a 00                	push   $0x0
8010476e:	e8 d7 f9 ff ff       	call   8010414a <argstr>
80104773:	83 c4 10             	add    $0x10,%esp
80104776:	85 c0                	test   %eax,%eax
80104778:	0f 88 83 01 00 00    	js     80104901 <sys_unlink+0x1a2>
  begin_op();
8010477e:	e8 c1 e1 ff ff       	call   80102944 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80104783:	83 ec 08             	sub    $0x8,%esp
80104786:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104789:	50                   	push   %eax
8010478a:	ff 75 c4             	pushl  -0x3c(%ebp)
8010478d:	e8 67 d4 ff ff       	call   80101bf9 <nameiparent>
80104792:	89 c6                	mov    %eax,%esi
80104794:	83 c4 10             	add    $0x10,%esp
80104797:	85 c0                	test   %eax,%eax
80104799:	0f 84 ed 00 00 00    	je     8010488c <sys_unlink+0x12d>
  ilock(dp);
8010479f:	83 ec 0c             	sub    $0xc,%esp
801047a2:	50                   	push   %eax
801047a3:	e8 d9 cd ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801047a8:	83 c4 08             	add    $0x8,%esp
801047ab:	68 3e 6e 10 80       	push   $0x80106e3e
801047b0:	8d 45 ca             	lea    -0x36(%ebp),%eax
801047b3:	50                   	push   %eax
801047b4:	e8 e2 d1 ff ff       	call   8010199b <namecmp>
801047b9:	83 c4 10             	add    $0x10,%esp
801047bc:	85 c0                	test   %eax,%eax
801047be:	0f 84 fc 00 00 00    	je     801048c0 <sys_unlink+0x161>
801047c4:	83 ec 08             	sub    $0x8,%esp
801047c7:	68 3d 6e 10 80       	push   $0x80106e3d
801047cc:	8d 45 ca             	lea    -0x36(%ebp),%eax
801047cf:	50                   	push   %eax
801047d0:	e8 c6 d1 ff ff       	call   8010199b <namecmp>
801047d5:	83 c4 10             	add    $0x10,%esp
801047d8:	85 c0                	test   %eax,%eax
801047da:	0f 84 e0 00 00 00    	je     801048c0 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
801047e0:	83 ec 04             	sub    $0x4,%esp
801047e3:	8d 45 c0             	lea    -0x40(%ebp),%eax
801047e6:	50                   	push   %eax
801047e7:	8d 45 ca             	lea    -0x36(%ebp),%eax
801047ea:	50                   	push   %eax
801047eb:	56                   	push   %esi
801047ec:	e8 bf d1 ff ff       	call   801019b0 <dirlookup>
801047f1:	89 c3                	mov    %eax,%ebx
801047f3:	83 c4 10             	add    $0x10,%esp
801047f6:	85 c0                	test   %eax,%eax
801047f8:	0f 84 c2 00 00 00    	je     801048c0 <sys_unlink+0x161>
  ilock(ip);
801047fe:	83 ec 0c             	sub    $0xc,%esp
80104801:	50                   	push   %eax
80104802:	e8 7a cd ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
80104807:	83 c4 10             	add    $0x10,%esp
8010480a:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
8010480f:	0f 8e 83 00 00 00    	jle    80104898 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104815:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010481a:	0f 84 85 00 00 00    	je     801048a5 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
80104820:	83 ec 04             	sub    $0x4,%esp
80104823:	6a 10                	push   $0x10
80104825:	6a 00                	push   $0x0
80104827:	8d 7d d8             	lea    -0x28(%ebp),%edi
8010482a:	57                   	push   %edi
8010482b:	e8 3f f6 ff ff       	call   80103e6f <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104830:	6a 10                	push   $0x10
80104832:	ff 75 c0             	pushl  -0x40(%ebp)
80104835:	57                   	push   %edi
80104836:	56                   	push   %esi
80104837:	e8 34 d0 ff ff       	call   80101870 <writei>
8010483c:	83 c4 20             	add    $0x20,%esp
8010483f:	83 f8 10             	cmp    $0x10,%eax
80104842:	0f 85 90 00 00 00    	jne    801048d8 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104848:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010484d:	0f 84 92 00 00 00    	je     801048e5 <sys_unlink+0x186>
  iunlockput(dp);
80104853:	83 ec 0c             	sub    $0xc,%esp
80104856:	56                   	push   %esi
80104857:	e8 cc ce ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
8010485c:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104860:	83 e8 01             	sub    $0x1,%eax
80104863:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104867:	89 1c 24             	mov    %ebx,(%esp)
8010486a:	e8 b1 cb ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
8010486f:	89 1c 24             	mov    %ebx,(%esp)
80104872:	e8 b1 ce ff ff       	call   80101728 <iunlockput>
  end_op();
80104877:	e8 42 e1 ff ff       	call   801029be <end_op>
  return 0;
8010487c:	83 c4 10             	add    $0x10,%esp
8010487f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104884:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104887:	5b                   	pop    %ebx
80104888:	5e                   	pop    %esi
80104889:	5f                   	pop    %edi
8010488a:	5d                   	pop    %ebp
8010488b:	c3                   	ret    
    end_op();
8010488c:	e8 2d e1 ff ff       	call   801029be <end_op>
    return -1;
80104891:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104896:	eb ec                	jmp    80104884 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
80104898:	83 ec 0c             	sub    $0xc,%esp
8010489b:	68 5c 6e 10 80       	push   $0x80106e5c
801048a0:	e8 a3 ba ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801048a5:	89 d8                	mov    %ebx,%eax
801048a7:	e8 c4 f9 ff ff       	call   80104270 <isdirempty>
801048ac:	85 c0                	test   %eax,%eax
801048ae:	0f 85 6c ff ff ff    	jne    80104820 <sys_unlink+0xc1>
    iunlockput(ip);
801048b4:	83 ec 0c             	sub    $0xc,%esp
801048b7:	53                   	push   %ebx
801048b8:	e8 6b ce ff ff       	call   80101728 <iunlockput>
    goto bad;
801048bd:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
801048c0:	83 ec 0c             	sub    $0xc,%esp
801048c3:	56                   	push   %esi
801048c4:	e8 5f ce ff ff       	call   80101728 <iunlockput>
  end_op();
801048c9:	e8 f0 e0 ff ff       	call   801029be <end_op>
  return -1;
801048ce:	83 c4 10             	add    $0x10,%esp
801048d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048d6:	eb ac                	jmp    80104884 <sys_unlink+0x125>
    panic("unlink: writei");
801048d8:	83 ec 0c             	sub    $0xc,%esp
801048db:	68 6e 6e 10 80       	push   $0x80106e6e
801048e0:	e8 63 ba ff ff       	call   80100348 <panic>
    dp->nlink--;
801048e5:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801048e9:	83 e8 01             	sub    $0x1,%eax
801048ec:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801048f0:	83 ec 0c             	sub    $0xc,%esp
801048f3:	56                   	push   %esi
801048f4:	e8 27 cb ff ff       	call   80101420 <iupdate>
801048f9:	83 c4 10             	add    $0x10,%esp
801048fc:	e9 52 ff ff ff       	jmp    80104853 <sys_unlink+0xf4>
    return -1;
80104901:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104906:	e9 79 ff ff ff       	jmp    80104884 <sys_unlink+0x125>

8010490b <sys_open>:

int
sys_open(void)
{
8010490b:	55                   	push   %ebp
8010490c:	89 e5                	mov    %esp,%ebp
8010490e:	57                   	push   %edi
8010490f:	56                   	push   %esi
80104910:	53                   	push   %ebx
80104911:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104914:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104917:	50                   	push   %eax
80104918:	6a 00                	push   $0x0
8010491a:	e8 2b f8 ff ff       	call   8010414a <argstr>
8010491f:	83 c4 10             	add    $0x10,%esp
80104922:	85 c0                	test   %eax,%eax
80104924:	0f 88 30 01 00 00    	js     80104a5a <sys_open+0x14f>
8010492a:	83 ec 08             	sub    $0x8,%esp
8010492d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104930:	50                   	push   %eax
80104931:	6a 01                	push   $0x1
80104933:	e8 82 f7 ff ff       	call   801040ba <argint>
80104938:	83 c4 10             	add    $0x10,%esp
8010493b:	85 c0                	test   %eax,%eax
8010493d:	0f 88 21 01 00 00    	js     80104a64 <sys_open+0x159>
    return -1;

  begin_op();
80104943:	e8 fc df ff ff       	call   80102944 <begin_op>

  if(omode & O_CREATE){
80104948:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
8010494c:	0f 84 84 00 00 00    	je     801049d6 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
80104952:	83 ec 0c             	sub    $0xc,%esp
80104955:	6a 00                	push   $0x0
80104957:	b9 00 00 00 00       	mov    $0x0,%ecx
8010495c:	ba 02 00 00 00       	mov    $0x2,%edx
80104961:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104964:	e8 5e f9 ff ff       	call   801042c7 <create>
80104969:	89 c6                	mov    %eax,%esi
    if(ip == 0){
8010496b:	83 c4 10             	add    $0x10,%esp
8010496e:	85 c0                	test   %eax,%eax
80104970:	74 58                	je     801049ca <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104972:	e8 b6 c2 ff ff       	call   80100c2d <filealloc>
80104977:	89 c3                	mov    %eax,%ebx
80104979:	85 c0                	test   %eax,%eax
8010497b:	0f 84 ae 00 00 00    	je     80104a2f <sys_open+0x124>
80104981:	e8 b3 f8 ff ff       	call   80104239 <fdalloc>
80104986:	89 c7                	mov    %eax,%edi
80104988:	85 c0                	test   %eax,%eax
8010498a:	0f 88 9f 00 00 00    	js     80104a2f <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104990:	83 ec 0c             	sub    $0xc,%esp
80104993:	56                   	push   %esi
80104994:	e8 aa cc ff ff       	call   80101643 <iunlock>
  end_op();
80104999:	e8 20 e0 ff ff       	call   801029be <end_op>

  f->type = FD_INODE;
8010499e:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
801049a4:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
801049a7:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
801049ae:	8b 45 e0             	mov    -0x20(%ebp),%eax
801049b1:	83 c4 10             	add    $0x10,%esp
801049b4:	a8 01                	test   $0x1,%al
801049b6:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801049ba:	a8 03                	test   $0x3,%al
801049bc:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
801049c0:	89 f8                	mov    %edi,%eax
801049c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
801049c5:	5b                   	pop    %ebx
801049c6:	5e                   	pop    %esi
801049c7:	5f                   	pop    %edi
801049c8:	5d                   	pop    %ebp
801049c9:	c3                   	ret    
      end_op();
801049ca:	e8 ef df ff ff       	call   801029be <end_op>
      return -1;
801049cf:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049d4:	eb ea                	jmp    801049c0 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
801049d6:	83 ec 0c             	sub    $0xc,%esp
801049d9:	ff 75 e4             	pushl  -0x1c(%ebp)
801049dc:	e8 00 d2 ff ff       	call   80101be1 <namei>
801049e1:	89 c6                	mov    %eax,%esi
801049e3:	83 c4 10             	add    $0x10,%esp
801049e6:	85 c0                	test   %eax,%eax
801049e8:	74 39                	je     80104a23 <sys_open+0x118>
    ilock(ip);
801049ea:	83 ec 0c             	sub    $0xc,%esp
801049ed:	50                   	push   %eax
801049ee:	e8 8e cb ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801049f3:	83 c4 10             	add    $0x10,%esp
801049f6:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801049fb:	0f 85 71 ff ff ff    	jne    80104972 <sys_open+0x67>
80104a01:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104a05:	0f 84 67 ff ff ff    	je     80104972 <sys_open+0x67>
      iunlockput(ip);
80104a0b:	83 ec 0c             	sub    $0xc,%esp
80104a0e:	56                   	push   %esi
80104a0f:	e8 14 cd ff ff       	call   80101728 <iunlockput>
      end_op();
80104a14:	e8 a5 df ff ff       	call   801029be <end_op>
      return -1;
80104a19:	83 c4 10             	add    $0x10,%esp
80104a1c:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a21:	eb 9d                	jmp    801049c0 <sys_open+0xb5>
      end_op();
80104a23:	e8 96 df ff ff       	call   801029be <end_op>
      return -1;
80104a28:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a2d:	eb 91                	jmp    801049c0 <sys_open+0xb5>
    if(f)
80104a2f:	85 db                	test   %ebx,%ebx
80104a31:	74 0c                	je     80104a3f <sys_open+0x134>
      fileclose(f);
80104a33:	83 ec 0c             	sub    $0xc,%esp
80104a36:	53                   	push   %ebx
80104a37:	e8 97 c2 ff ff       	call   80100cd3 <fileclose>
80104a3c:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104a3f:	83 ec 0c             	sub    $0xc,%esp
80104a42:	56                   	push   %esi
80104a43:	e8 e0 cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104a48:	e8 71 df ff ff       	call   801029be <end_op>
    return -1;
80104a4d:	83 c4 10             	add    $0x10,%esp
80104a50:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a55:	e9 66 ff ff ff       	jmp    801049c0 <sys_open+0xb5>
    return -1;
80104a5a:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a5f:	e9 5c ff ff ff       	jmp    801049c0 <sys_open+0xb5>
80104a64:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a69:	e9 52 ff ff ff       	jmp    801049c0 <sys_open+0xb5>

80104a6e <sys_mkdir>:

int
sys_mkdir(void)
{
80104a6e:	55                   	push   %ebp
80104a6f:	89 e5                	mov    %esp,%ebp
80104a71:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104a74:	e8 cb de ff ff       	call   80102944 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104a79:	83 ec 08             	sub    $0x8,%esp
80104a7c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a7f:	50                   	push   %eax
80104a80:	6a 00                	push   $0x0
80104a82:	e8 c3 f6 ff ff       	call   8010414a <argstr>
80104a87:	83 c4 10             	add    $0x10,%esp
80104a8a:	85 c0                	test   %eax,%eax
80104a8c:	78 36                	js     80104ac4 <sys_mkdir+0x56>
80104a8e:	83 ec 0c             	sub    $0xc,%esp
80104a91:	6a 00                	push   $0x0
80104a93:	b9 00 00 00 00       	mov    $0x0,%ecx
80104a98:	ba 01 00 00 00       	mov    $0x1,%edx
80104a9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aa0:	e8 22 f8 ff ff       	call   801042c7 <create>
80104aa5:	83 c4 10             	add    $0x10,%esp
80104aa8:	85 c0                	test   %eax,%eax
80104aaa:	74 18                	je     80104ac4 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104aac:	83 ec 0c             	sub    $0xc,%esp
80104aaf:	50                   	push   %eax
80104ab0:	e8 73 cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104ab5:	e8 04 df ff ff       	call   801029be <end_op>
  return 0;
80104aba:	83 c4 10             	add    $0x10,%esp
80104abd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ac2:	c9                   	leave  
80104ac3:	c3                   	ret    
    end_op();
80104ac4:	e8 f5 de ff ff       	call   801029be <end_op>
    return -1;
80104ac9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ace:	eb f2                	jmp    80104ac2 <sys_mkdir+0x54>

80104ad0 <sys_mknod>:

int
sys_mknod(void)
{
80104ad0:	55                   	push   %ebp
80104ad1:	89 e5                	mov    %esp,%ebp
80104ad3:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104ad6:	e8 69 de ff ff       	call   80102944 <begin_op>
  if((argstr(0, &path)) < 0 ||
80104adb:	83 ec 08             	sub    $0x8,%esp
80104ade:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ae1:	50                   	push   %eax
80104ae2:	6a 00                	push   $0x0
80104ae4:	e8 61 f6 ff ff       	call   8010414a <argstr>
80104ae9:	83 c4 10             	add    $0x10,%esp
80104aec:	85 c0                	test   %eax,%eax
80104aee:	78 62                	js     80104b52 <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104af0:	83 ec 08             	sub    $0x8,%esp
80104af3:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104af6:	50                   	push   %eax
80104af7:	6a 01                	push   $0x1
80104af9:	e8 bc f5 ff ff       	call   801040ba <argint>
  if((argstr(0, &path)) < 0 ||
80104afe:	83 c4 10             	add    $0x10,%esp
80104b01:	85 c0                	test   %eax,%eax
80104b03:	78 4d                	js     80104b52 <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104b05:	83 ec 08             	sub    $0x8,%esp
80104b08:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104b0b:	50                   	push   %eax
80104b0c:	6a 02                	push   $0x2
80104b0e:	e8 a7 f5 ff ff       	call   801040ba <argint>
     argint(1, &major) < 0 ||
80104b13:	83 c4 10             	add    $0x10,%esp
80104b16:	85 c0                	test   %eax,%eax
80104b18:	78 38                	js     80104b52 <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104b1a:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104b1e:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104b22:	83 ec 0c             	sub    $0xc,%esp
80104b25:	50                   	push   %eax
80104b26:	ba 03 00 00 00       	mov    $0x3,%edx
80104b2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b2e:	e8 94 f7 ff ff       	call   801042c7 <create>
80104b33:	83 c4 10             	add    $0x10,%esp
80104b36:	85 c0                	test   %eax,%eax
80104b38:	74 18                	je     80104b52 <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104b3a:	83 ec 0c             	sub    $0xc,%esp
80104b3d:	50                   	push   %eax
80104b3e:	e8 e5 cb ff ff       	call   80101728 <iunlockput>
  end_op();
80104b43:	e8 76 de ff ff       	call   801029be <end_op>
  return 0;
80104b48:	83 c4 10             	add    $0x10,%esp
80104b4b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b50:	c9                   	leave  
80104b51:	c3                   	ret    
    end_op();
80104b52:	e8 67 de ff ff       	call   801029be <end_op>
    return -1;
80104b57:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b5c:	eb f2                	jmp    80104b50 <sys_mknod+0x80>

80104b5e <sys_chdir>:

int
sys_chdir(void)
{
80104b5e:	55                   	push   %ebp
80104b5f:	89 e5                	mov    %esp,%ebp
80104b61:	56                   	push   %esi
80104b62:	53                   	push   %ebx
80104b63:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104b66:	e8 3a e8 ff ff       	call   801033a5 <myproc>
80104b6b:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104b6d:	e8 d2 dd ff ff       	call   80102944 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104b72:	83 ec 08             	sub    $0x8,%esp
80104b75:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b78:	50                   	push   %eax
80104b79:	6a 00                	push   $0x0
80104b7b:	e8 ca f5 ff ff       	call   8010414a <argstr>
80104b80:	83 c4 10             	add    $0x10,%esp
80104b83:	85 c0                	test   %eax,%eax
80104b85:	78 52                	js     80104bd9 <sys_chdir+0x7b>
80104b87:	83 ec 0c             	sub    $0xc,%esp
80104b8a:	ff 75 f4             	pushl  -0xc(%ebp)
80104b8d:	e8 4f d0 ff ff       	call   80101be1 <namei>
80104b92:	89 c3                	mov    %eax,%ebx
80104b94:	83 c4 10             	add    $0x10,%esp
80104b97:	85 c0                	test   %eax,%eax
80104b99:	74 3e                	je     80104bd9 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104b9b:	83 ec 0c             	sub    $0xc,%esp
80104b9e:	50                   	push   %eax
80104b9f:	e8 dd c9 ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104ba4:	83 c4 10             	add    $0x10,%esp
80104ba7:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104bac:	75 37                	jne    80104be5 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104bae:	83 ec 0c             	sub    $0xc,%esp
80104bb1:	53                   	push   %ebx
80104bb2:	e8 8c ca ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104bb7:	83 c4 04             	add    $0x4,%esp
80104bba:	ff 76 68             	pushl  0x68(%esi)
80104bbd:	e8 c6 ca ff ff       	call   80101688 <iput>
  end_op();
80104bc2:	e8 f7 dd ff ff       	call   801029be <end_op>
  curproc->cwd = ip;
80104bc7:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104bca:	83 c4 10             	add    $0x10,%esp
80104bcd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104bd2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104bd5:	5b                   	pop    %ebx
80104bd6:	5e                   	pop    %esi
80104bd7:	5d                   	pop    %ebp
80104bd8:	c3                   	ret    
    end_op();
80104bd9:	e8 e0 dd ff ff       	call   801029be <end_op>
    return -1;
80104bde:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104be3:	eb ed                	jmp    80104bd2 <sys_chdir+0x74>
    iunlockput(ip);
80104be5:	83 ec 0c             	sub    $0xc,%esp
80104be8:	53                   	push   %ebx
80104be9:	e8 3a cb ff ff       	call   80101728 <iunlockput>
    end_op();
80104bee:	e8 cb dd ff ff       	call   801029be <end_op>
    return -1;
80104bf3:	83 c4 10             	add    $0x10,%esp
80104bf6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bfb:	eb d5                	jmp    80104bd2 <sys_chdir+0x74>

80104bfd <sys_exec>:

int
sys_exec(void)
{
80104bfd:	55                   	push   %ebp
80104bfe:	89 e5                	mov    %esp,%ebp
80104c00:	53                   	push   %ebx
80104c01:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104c07:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c0a:	50                   	push   %eax
80104c0b:	6a 00                	push   $0x0
80104c0d:	e8 38 f5 ff ff       	call   8010414a <argstr>
80104c12:	83 c4 10             	add    $0x10,%esp
80104c15:	85 c0                	test   %eax,%eax
80104c17:	0f 88 a8 00 00 00    	js     80104cc5 <sys_exec+0xc8>
80104c1d:	83 ec 08             	sub    $0x8,%esp
80104c20:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104c26:	50                   	push   %eax
80104c27:	6a 01                	push   $0x1
80104c29:	e8 8c f4 ff ff       	call   801040ba <argint>
80104c2e:	83 c4 10             	add    $0x10,%esp
80104c31:	85 c0                	test   %eax,%eax
80104c33:	0f 88 93 00 00 00    	js     80104ccc <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104c39:	83 ec 04             	sub    $0x4,%esp
80104c3c:	68 80 00 00 00       	push   $0x80
80104c41:	6a 00                	push   $0x0
80104c43:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104c49:	50                   	push   %eax
80104c4a:	e8 20 f2 ff ff       	call   80103e6f <memset>
80104c4f:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104c52:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104c57:	83 fb 1f             	cmp    $0x1f,%ebx
80104c5a:	77 77                	ja     80104cd3 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104c5c:	83 ec 08             	sub    $0x8,%esp
80104c5f:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104c65:	50                   	push   %eax
80104c66:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104c6c:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104c6f:	50                   	push   %eax
80104c70:	e8 c9 f3 ff ff       	call   8010403e <fetchint>
80104c75:	83 c4 10             	add    $0x10,%esp
80104c78:	85 c0                	test   %eax,%eax
80104c7a:	78 5e                	js     80104cda <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104c7c:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104c82:	85 c0                	test   %eax,%eax
80104c84:	74 1d                	je     80104ca3 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104c86:	83 ec 08             	sub    $0x8,%esp
80104c89:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104c90:	52                   	push   %edx
80104c91:	50                   	push   %eax
80104c92:	e8 e3 f3 ff ff       	call   8010407a <fetchstr>
80104c97:	83 c4 10             	add    $0x10,%esp
80104c9a:	85 c0                	test   %eax,%eax
80104c9c:	78 46                	js     80104ce4 <sys_exec+0xe7>
  for(i=0;; i++){
80104c9e:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104ca1:	eb b4                	jmp    80104c57 <sys_exec+0x5a>
      argv[i] = 0;
80104ca3:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104caa:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104cae:	83 ec 08             	sub    $0x8,%esp
80104cb1:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104cb7:	50                   	push   %eax
80104cb8:	ff 75 f4             	pushl  -0xc(%ebp)
80104cbb:	e8 12 bc ff ff       	call   801008d2 <exec>
80104cc0:	83 c4 10             	add    $0x10,%esp
80104cc3:	eb 1a                	jmp    80104cdf <sys_exec+0xe2>
    return -1;
80104cc5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cca:	eb 13                	jmp    80104cdf <sys_exec+0xe2>
80104ccc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cd1:	eb 0c                	jmp    80104cdf <sys_exec+0xe2>
      return -1;
80104cd3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cd8:	eb 05                	jmp    80104cdf <sys_exec+0xe2>
      return -1;
80104cda:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104cdf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104ce2:	c9                   	leave  
80104ce3:	c3                   	ret    
      return -1;
80104ce4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ce9:	eb f4                	jmp    80104cdf <sys_exec+0xe2>

80104ceb <sys_pipe>:

int
sys_pipe(void)
{
80104ceb:	55                   	push   %ebp
80104cec:	89 e5                	mov    %esp,%ebp
80104cee:	53                   	push   %ebx
80104cef:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104cf2:	6a 08                	push   $0x8
80104cf4:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104cf7:	50                   	push   %eax
80104cf8:	6a 00                	push   $0x0
80104cfa:	e8 e3 f3 ff ff       	call   801040e2 <argptr>
80104cff:	83 c4 10             	add    $0x10,%esp
80104d02:	85 c0                	test   %eax,%eax
80104d04:	78 77                	js     80104d7d <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104d06:	83 ec 08             	sub    $0x8,%esp
80104d09:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104d0c:	50                   	push   %eax
80104d0d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104d10:	50                   	push   %eax
80104d11:	e8 c0 e1 ff ff       	call   80102ed6 <pipealloc>
80104d16:	83 c4 10             	add    $0x10,%esp
80104d19:	85 c0                	test   %eax,%eax
80104d1b:	78 67                	js     80104d84 <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104d1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d20:	e8 14 f5 ff ff       	call   80104239 <fdalloc>
80104d25:	89 c3                	mov    %eax,%ebx
80104d27:	85 c0                	test   %eax,%eax
80104d29:	78 21                	js     80104d4c <sys_pipe+0x61>
80104d2b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104d2e:	e8 06 f5 ff ff       	call   80104239 <fdalloc>
80104d33:	85 c0                	test   %eax,%eax
80104d35:	78 15                	js     80104d4c <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104d37:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d3a:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104d3c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d3f:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104d42:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d47:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d4a:	c9                   	leave  
80104d4b:	c3                   	ret    
    if(fd0 >= 0)
80104d4c:	85 db                	test   %ebx,%ebx
80104d4e:	78 0d                	js     80104d5d <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104d50:	e8 50 e6 ff ff       	call   801033a5 <myproc>
80104d55:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104d5c:	00 
    fileclose(rf);
80104d5d:	83 ec 0c             	sub    $0xc,%esp
80104d60:	ff 75 f0             	pushl  -0x10(%ebp)
80104d63:	e8 6b bf ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104d68:	83 c4 04             	add    $0x4,%esp
80104d6b:	ff 75 ec             	pushl  -0x14(%ebp)
80104d6e:	e8 60 bf ff ff       	call   80100cd3 <fileclose>
    return -1;
80104d73:	83 c4 10             	add    $0x10,%esp
80104d76:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d7b:	eb ca                	jmp    80104d47 <sys_pipe+0x5c>
    return -1;
80104d7d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d82:	eb c3                	jmp    80104d47 <sys_pipe+0x5c>
    return -1;
80104d84:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d89:	eb bc                	jmp    80104d47 <sys_pipe+0x5c>

80104d8b <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104d8b:	55                   	push   %ebp
80104d8c:	89 e5                	mov    %esp,%ebp
80104d8e:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104d91:	e8 87 e7 ff ff       	call   8010351d <fork>
}
80104d96:	c9                   	leave  
80104d97:	c3                   	ret    

80104d98 <sys_exit>:

int
sys_exit(void)
{
80104d98:	55                   	push   %ebp
80104d99:	89 e5                	mov    %esp,%ebp
80104d9b:	83 ec 08             	sub    $0x8,%esp
  exit();
80104d9e:	e8 ae e9 ff ff       	call   80103751 <exit>
  return 0;  // not reached
}
80104da3:	b8 00 00 00 00       	mov    $0x0,%eax
80104da8:	c9                   	leave  
80104da9:	c3                   	ret    

80104daa <sys_wait>:

int
sys_wait(void)
{
80104daa:	55                   	push   %ebp
80104dab:	89 e5                	mov    %esp,%ebp
80104dad:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104db0:	e8 25 eb ff ff       	call   801038da <wait>
}
80104db5:	c9                   	leave  
80104db6:	c3                   	ret    

80104db7 <sys_kill>:

int
sys_kill(void)
{
80104db7:	55                   	push   %ebp
80104db8:	89 e5                	mov    %esp,%ebp
80104dba:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104dbd:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104dc0:	50                   	push   %eax
80104dc1:	6a 00                	push   $0x0
80104dc3:	e8 f2 f2 ff ff       	call   801040ba <argint>
80104dc8:	83 c4 10             	add    $0x10,%esp
80104dcb:	85 c0                	test   %eax,%eax
80104dcd:	78 10                	js     80104ddf <sys_kill+0x28>
    return -1;
  return kill(pid);
80104dcf:	83 ec 0c             	sub    $0xc,%esp
80104dd2:	ff 75 f4             	pushl  -0xc(%ebp)
80104dd5:	e8 fd eb ff ff       	call   801039d7 <kill>
80104dda:	83 c4 10             	add    $0x10,%esp
}
80104ddd:	c9                   	leave  
80104dde:	c3                   	ret    
    return -1;
80104ddf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104de4:	eb f7                	jmp    80104ddd <sys_kill+0x26>

80104de6 <sys_getpid>:

int
sys_getpid(void)
{
80104de6:	55                   	push   %ebp
80104de7:	89 e5                	mov    %esp,%ebp
80104de9:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104dec:	e8 b4 e5 ff ff       	call   801033a5 <myproc>
80104df1:	8b 40 10             	mov    0x10(%eax),%eax
}
80104df4:	c9                   	leave  
80104df5:	c3                   	ret    

80104df6 <sys_sbrk>:

int
sys_sbrk(void)
{
80104df6:	55                   	push   %ebp
80104df7:	89 e5                	mov    %esp,%ebp
80104df9:	53                   	push   %ebx
80104dfa:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104dfd:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e00:	50                   	push   %eax
80104e01:	6a 00                	push   $0x0
80104e03:	e8 b2 f2 ff ff       	call   801040ba <argint>
80104e08:	83 c4 10             	add    $0x10,%esp
80104e0b:	85 c0                	test   %eax,%eax
80104e0d:	78 27                	js     80104e36 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104e0f:	e8 91 e5 ff ff       	call   801033a5 <myproc>
80104e14:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104e16:	83 ec 0c             	sub    $0xc,%esp
80104e19:	ff 75 f4             	pushl  -0xc(%ebp)
80104e1c:	e8 8f e6 ff ff       	call   801034b0 <growproc>
80104e21:	83 c4 10             	add    $0x10,%esp
80104e24:	85 c0                	test   %eax,%eax
80104e26:	78 07                	js     80104e2f <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104e28:	89 d8                	mov    %ebx,%eax
80104e2a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e2d:	c9                   	leave  
80104e2e:	c3                   	ret    
    return -1;
80104e2f:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104e34:	eb f2                	jmp    80104e28 <sys_sbrk+0x32>
    return -1;
80104e36:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104e3b:	eb eb                	jmp    80104e28 <sys_sbrk+0x32>

80104e3d <sys_sleep>:

int
sys_sleep(void)
{
80104e3d:	55                   	push   %ebp
80104e3e:	89 e5                	mov    %esp,%ebp
80104e40:	53                   	push   %ebx
80104e41:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104e44:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e47:	50                   	push   %eax
80104e48:	6a 00                	push   $0x0
80104e4a:	e8 6b f2 ff ff       	call   801040ba <argint>
80104e4f:	83 c4 10             	add    $0x10,%esp
80104e52:	85 c0                	test   %eax,%eax
80104e54:	78 75                	js     80104ecb <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104e56:	83 ec 0c             	sub    $0xc,%esp
80104e59:	68 80 4c 15 80       	push   $0x80154c80
80104e5e:	e8 60 ef ff ff       	call   80103dc3 <acquire>
  ticks0 = ticks;
80104e63:	8b 1d c0 54 15 80    	mov    0x801554c0,%ebx
  while(ticks - ticks0 < n){
80104e69:	83 c4 10             	add    $0x10,%esp
80104e6c:	a1 c0 54 15 80       	mov    0x801554c0,%eax
80104e71:	29 d8                	sub    %ebx,%eax
80104e73:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104e76:	73 39                	jae    80104eb1 <sys_sleep+0x74>
    if(myproc()->killed){
80104e78:	e8 28 e5 ff ff       	call   801033a5 <myproc>
80104e7d:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104e81:	75 17                	jne    80104e9a <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104e83:	83 ec 08             	sub    $0x8,%esp
80104e86:	68 80 4c 15 80       	push   $0x80154c80
80104e8b:	68 c0 54 15 80       	push   $0x801554c0
80104e90:	e8 b4 e9 ff ff       	call   80103849 <sleep>
80104e95:	83 c4 10             	add    $0x10,%esp
80104e98:	eb d2                	jmp    80104e6c <sys_sleep+0x2f>
      release(&tickslock);
80104e9a:	83 ec 0c             	sub    $0xc,%esp
80104e9d:	68 80 4c 15 80       	push   $0x80154c80
80104ea2:	e8 81 ef ff ff       	call   80103e28 <release>
      return -1;
80104ea7:	83 c4 10             	add    $0x10,%esp
80104eaa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104eaf:	eb 15                	jmp    80104ec6 <sys_sleep+0x89>
  }
  release(&tickslock);
80104eb1:	83 ec 0c             	sub    $0xc,%esp
80104eb4:	68 80 4c 15 80       	push   $0x80154c80
80104eb9:	e8 6a ef ff ff       	call   80103e28 <release>
  return 0;
80104ebe:	83 c4 10             	add    $0x10,%esp
80104ec1:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ec6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104ec9:	c9                   	leave  
80104eca:	c3                   	ret    
    return -1;
80104ecb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ed0:	eb f4                	jmp    80104ec6 <sys_sleep+0x89>

80104ed2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104ed2:	55                   	push   %ebp
80104ed3:	89 e5                	mov    %esp,%ebp
80104ed5:	53                   	push   %ebx
80104ed6:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104ed9:	68 80 4c 15 80       	push   $0x80154c80
80104ede:	e8 e0 ee ff ff       	call   80103dc3 <acquire>
  xticks = ticks;
80104ee3:	8b 1d c0 54 15 80    	mov    0x801554c0,%ebx
  release(&tickslock);
80104ee9:	c7 04 24 80 4c 15 80 	movl   $0x80154c80,(%esp)
80104ef0:	e8 33 ef ff ff       	call   80103e28 <release>
  return xticks;
}
80104ef5:	89 d8                	mov    %ebx,%eax
80104ef7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104efa:	c9                   	leave  
80104efb:	c3                   	ret    

80104efc <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104efc:	55                   	push   %ebp
80104efd:	89 e5                	mov    %esp,%ebp
80104eff:	83 ec 1c             	sub    $0x1c,%esp
  int* frames;
  int* pids;
  int numframes;

  if(argptr(0, (void*)&frames,sizeof(frames)) < 0)
80104f02:	6a 04                	push   $0x4
80104f04:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f07:	50                   	push   %eax
80104f08:	6a 00                	push   $0x0
80104f0a:	e8 d3 f1 ff ff       	call   801040e2 <argptr>
80104f0f:	83 c4 10             	add    $0x10,%esp
80104f12:	85 c0                	test   %eax,%eax
80104f14:	78 42                	js     80104f58 <sys_dump_physmem+0x5c>
    return -1;
  
  if(argptr(1, (void*)&pids, sizeof(pids)) < 0)
80104f16:	83 ec 04             	sub    $0x4,%esp
80104f19:	6a 04                	push   $0x4
80104f1b:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104f1e:	50                   	push   %eax
80104f1f:	6a 01                	push   $0x1
80104f21:	e8 bc f1 ff ff       	call   801040e2 <argptr>
80104f26:	83 c4 10             	add    $0x10,%esp
80104f29:	85 c0                	test   %eax,%eax
80104f2b:	78 32                	js     80104f5f <sys_dump_physmem+0x63>
    return -1;
  
  if(argint(2, &numframes) < 0)
80104f2d:	83 ec 08             	sub    $0x8,%esp
80104f30:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104f33:	50                   	push   %eax
80104f34:	6a 02                	push   $0x2
80104f36:	e8 7f f1 ff ff       	call   801040ba <argint>
80104f3b:	83 c4 10             	add    $0x10,%esp
80104f3e:	85 c0                	test   %eax,%eax
80104f40:	78 24                	js     80104f66 <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
80104f42:	83 ec 04             	sub    $0x4,%esp
80104f45:	ff 75 ec             	pushl  -0x14(%ebp)
80104f48:	ff 75 f0             	pushl  -0x10(%ebp)
80104f4b:	ff 75 f4             	pushl  -0xc(%ebp)
80104f4e:	e8 aa eb ff ff       	call   80103afd <dump_physmem>
80104f53:	83 c4 10             	add    $0x10,%esp
80104f56:	c9                   	leave  
80104f57:	c3                   	ret    
    return -1;
80104f58:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f5d:	eb f7                	jmp    80104f56 <sys_dump_physmem+0x5a>
    return -1;
80104f5f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f64:	eb f0                	jmp    80104f56 <sys_dump_physmem+0x5a>
    return -1;
80104f66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f6b:	eb e9                	jmp    80104f56 <sys_dump_physmem+0x5a>

80104f6d <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104f6d:	1e                   	push   %ds
  pushl %es
80104f6e:	06                   	push   %es
  pushl %fs
80104f6f:	0f a0                	push   %fs
  pushl %gs
80104f71:	0f a8                	push   %gs
  pushal
80104f73:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104f74:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104f78:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104f7a:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104f7c:	54                   	push   %esp
  call trap
80104f7d:	e8 e3 00 00 00       	call   80105065 <trap>
  addl $4, %esp
80104f82:	83 c4 04             	add    $0x4,%esp

80104f85 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104f85:	61                   	popa   
  popl %gs
80104f86:	0f a9                	pop    %gs
  popl %fs
80104f88:	0f a1                	pop    %fs
  popl %es
80104f8a:	07                   	pop    %es
  popl %ds
80104f8b:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104f8c:	83 c4 08             	add    $0x8,%esp
  iret
80104f8f:	cf                   	iret   

80104f90 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104f90:	55                   	push   %ebp
80104f91:	89 e5                	mov    %esp,%ebp
80104f93:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104f96:	b8 00 00 00 00       	mov    $0x0,%eax
80104f9b:	eb 4a                	jmp    80104fe7 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104f9d:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
80104fa4:	66 89 0c c5 c0 4c 15 	mov    %cx,-0x7feab340(,%eax,8)
80104fab:	80 
80104fac:	66 c7 04 c5 c2 4c 15 	movw   $0x8,-0x7feab33e(,%eax,8)
80104fb3:	80 08 00 
80104fb6:	c6 04 c5 c4 4c 15 80 	movb   $0x0,-0x7feab33c(,%eax,8)
80104fbd:	00 
80104fbe:	0f b6 14 c5 c5 4c 15 	movzbl -0x7feab33b(,%eax,8),%edx
80104fc5:	80 
80104fc6:	83 e2 f0             	and    $0xfffffff0,%edx
80104fc9:	83 ca 0e             	or     $0xe,%edx
80104fcc:	83 e2 8f             	and    $0xffffff8f,%edx
80104fcf:	83 ca 80             	or     $0xffffff80,%edx
80104fd2:	88 14 c5 c5 4c 15 80 	mov    %dl,-0x7feab33b(,%eax,8)
80104fd9:	c1 e9 10             	shr    $0x10,%ecx
80104fdc:	66 89 0c c5 c6 4c 15 	mov    %cx,-0x7feab33a(,%eax,8)
80104fe3:	80 
  for(i = 0; i < 256; i++)
80104fe4:	83 c0 01             	add    $0x1,%eax
80104fe7:	3d ff 00 00 00       	cmp    $0xff,%eax
80104fec:	7e af                	jle    80104f9d <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104fee:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
80104ff4:	66 89 15 c0 4e 15 80 	mov    %dx,0x80154ec0
80104ffb:	66 c7 05 c2 4e 15 80 	movw   $0x8,0x80154ec2
80105002:	08 00 
80105004:	c6 05 c4 4e 15 80 00 	movb   $0x0,0x80154ec4
8010500b:	0f b6 05 c5 4e 15 80 	movzbl 0x80154ec5,%eax
80105012:	83 c8 0f             	or     $0xf,%eax
80105015:	83 e0 ef             	and    $0xffffffef,%eax
80105018:	83 c8 e0             	or     $0xffffffe0,%eax
8010501b:	a2 c5 4e 15 80       	mov    %al,0x80154ec5
80105020:	c1 ea 10             	shr    $0x10,%edx
80105023:	66 89 15 c6 4e 15 80 	mov    %dx,0x80154ec6

  initlock(&tickslock, "time");
8010502a:	83 ec 08             	sub    $0x8,%esp
8010502d:	68 7d 6e 10 80       	push   $0x80106e7d
80105032:	68 80 4c 15 80       	push   $0x80154c80
80105037:	e8 4b ec ff ff       	call   80103c87 <initlock>
}
8010503c:	83 c4 10             	add    $0x10,%esp
8010503f:	c9                   	leave  
80105040:	c3                   	ret    

80105041 <idtinit>:

void
idtinit(void)
{
80105041:	55                   	push   %ebp
80105042:	89 e5                	mov    %esp,%ebp
80105044:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80105047:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
8010504d:	b8 c0 4c 15 80       	mov    $0x80154cc0,%eax
80105052:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80105056:	c1 e8 10             	shr    $0x10,%eax
80105059:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
8010505d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80105060:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80105063:	c9                   	leave  
80105064:	c3                   	ret    

80105065 <trap>:

void
trap(struct trapframe *tf)
{
80105065:	55                   	push   %ebp
80105066:	89 e5                	mov    %esp,%ebp
80105068:	57                   	push   %edi
80105069:	56                   	push   %esi
8010506a:	53                   	push   %ebx
8010506b:	83 ec 1c             	sub    $0x1c,%esp
8010506e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80105071:	8b 43 30             	mov    0x30(%ebx),%eax
80105074:	83 f8 40             	cmp    $0x40,%eax
80105077:	74 13                	je     8010508c <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80105079:	83 e8 20             	sub    $0x20,%eax
8010507c:	83 f8 1f             	cmp    $0x1f,%eax
8010507f:	0f 87 3a 01 00 00    	ja     801051bf <trap+0x15a>
80105085:	ff 24 85 24 6f 10 80 	jmp    *-0x7fef90dc(,%eax,4)
    if(myproc()->killed)
8010508c:	e8 14 e3 ff ff       	call   801033a5 <myproc>
80105091:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105095:	75 1f                	jne    801050b6 <trap+0x51>
    myproc()->tf = tf;
80105097:	e8 09 e3 ff ff       	call   801033a5 <myproc>
8010509c:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
8010509f:	e8 d9 f0 ff ff       	call   8010417d <syscall>
    if(myproc()->killed)
801050a4:	e8 fc e2 ff ff       	call   801033a5 <myproc>
801050a9:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801050ad:	74 7e                	je     8010512d <trap+0xc8>
      exit();
801050af:	e8 9d e6 ff ff       	call   80103751 <exit>
801050b4:	eb 77                	jmp    8010512d <trap+0xc8>
      exit();
801050b6:	e8 96 e6 ff ff       	call   80103751 <exit>
801050bb:	eb da                	jmp    80105097 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
801050bd:	e8 c8 e2 ff ff       	call   8010338a <cpuid>
801050c2:	85 c0                	test   %eax,%eax
801050c4:	74 6f                	je     80105135 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
801050c6:	e8 64 d4 ff ff       	call   8010252f <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
801050cb:	e8 d5 e2 ff ff       	call   801033a5 <myproc>
801050d0:	85 c0                	test   %eax,%eax
801050d2:	74 1c                	je     801050f0 <trap+0x8b>
801050d4:	e8 cc e2 ff ff       	call   801033a5 <myproc>
801050d9:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801050dd:	74 11                	je     801050f0 <trap+0x8b>
801050df:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
801050e3:	83 e0 03             	and    $0x3,%eax
801050e6:	66 83 f8 03          	cmp    $0x3,%ax
801050ea:	0f 84 62 01 00 00    	je     80105252 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
801050f0:	e8 b0 e2 ff ff       	call   801033a5 <myproc>
801050f5:	85 c0                	test   %eax,%eax
801050f7:	74 0f                	je     80105108 <trap+0xa3>
801050f9:	e8 a7 e2 ff ff       	call   801033a5 <myproc>
801050fe:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80105102:	0f 84 54 01 00 00    	je     8010525c <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105108:	e8 98 e2 ff ff       	call   801033a5 <myproc>
8010510d:	85 c0                	test   %eax,%eax
8010510f:	74 1c                	je     8010512d <trap+0xc8>
80105111:	e8 8f e2 ff ff       	call   801033a5 <myproc>
80105116:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010511a:	74 11                	je     8010512d <trap+0xc8>
8010511c:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105120:	83 e0 03             	and    $0x3,%eax
80105123:	66 83 f8 03          	cmp    $0x3,%ax
80105127:	0f 84 43 01 00 00    	je     80105270 <trap+0x20b>
    exit();
}
8010512d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105130:	5b                   	pop    %ebx
80105131:	5e                   	pop    %esi
80105132:	5f                   	pop    %edi
80105133:	5d                   	pop    %ebp
80105134:	c3                   	ret    
      acquire(&tickslock);
80105135:	83 ec 0c             	sub    $0xc,%esp
80105138:	68 80 4c 15 80       	push   $0x80154c80
8010513d:	e8 81 ec ff ff       	call   80103dc3 <acquire>
      ticks++;
80105142:	83 05 c0 54 15 80 01 	addl   $0x1,0x801554c0
      wakeup(&ticks);
80105149:	c7 04 24 c0 54 15 80 	movl   $0x801554c0,(%esp)
80105150:	e8 59 e8 ff ff       	call   801039ae <wakeup>
      release(&tickslock);
80105155:	c7 04 24 80 4c 15 80 	movl   $0x80154c80,(%esp)
8010515c:	e8 c7 ec ff ff       	call   80103e28 <release>
80105161:	83 c4 10             	add    $0x10,%esp
80105164:	e9 5d ff ff ff       	jmp    801050c6 <trap+0x61>
    ideintr();
80105169:	e8 05 cc ff ff       	call   80101d73 <ideintr>
    lapiceoi();
8010516e:	e8 bc d3 ff ff       	call   8010252f <lapiceoi>
    break;
80105173:	e9 53 ff ff ff       	jmp    801050cb <trap+0x66>
    kbdintr();
80105178:	e8 f6 d1 ff ff       	call   80102373 <kbdintr>
    lapiceoi();
8010517d:	e8 ad d3 ff ff       	call   8010252f <lapiceoi>
    break;
80105182:	e9 44 ff ff ff       	jmp    801050cb <trap+0x66>
    uartintr();
80105187:	e8 05 02 00 00       	call   80105391 <uartintr>
    lapiceoi();
8010518c:	e8 9e d3 ff ff       	call   8010252f <lapiceoi>
    break;
80105191:	e9 35 ff ff ff       	jmp    801050cb <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105196:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
80105199:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010519d:	e8 e8 e1 ff ff       	call   8010338a <cpuid>
801051a2:	57                   	push   %edi
801051a3:	0f b7 f6             	movzwl %si,%esi
801051a6:	56                   	push   %esi
801051a7:	50                   	push   %eax
801051a8:	68 88 6e 10 80       	push   $0x80106e88
801051ad:	e8 59 b4 ff ff       	call   8010060b <cprintf>
    lapiceoi();
801051b2:	e8 78 d3 ff ff       	call   8010252f <lapiceoi>
    break;
801051b7:	83 c4 10             	add    $0x10,%esp
801051ba:	e9 0c ff ff ff       	jmp    801050cb <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
801051bf:	e8 e1 e1 ff ff       	call   801033a5 <myproc>
801051c4:	85 c0                	test   %eax,%eax
801051c6:	74 5f                	je     80105227 <trap+0x1c2>
801051c8:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
801051cc:	74 59                	je     80105227 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801051ce:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801051d1:	8b 43 38             	mov    0x38(%ebx),%eax
801051d4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801051d7:	e8 ae e1 ff ff       	call   8010338a <cpuid>
801051dc:	89 45 e0             	mov    %eax,-0x20(%ebp)
801051df:	8b 53 34             	mov    0x34(%ebx),%edx
801051e2:	89 55 dc             	mov    %edx,-0x24(%ebp)
801051e5:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
801051e8:	e8 b8 e1 ff ff       	call   801033a5 <myproc>
801051ed:	8d 48 6c             	lea    0x6c(%eax),%ecx
801051f0:	89 4d d8             	mov    %ecx,-0x28(%ebp)
801051f3:	e8 ad e1 ff ff       	call   801033a5 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801051f8:	57                   	push   %edi
801051f9:	ff 75 e4             	pushl  -0x1c(%ebp)
801051fc:	ff 75 e0             	pushl  -0x20(%ebp)
801051ff:	ff 75 dc             	pushl  -0x24(%ebp)
80105202:	56                   	push   %esi
80105203:	ff 75 d8             	pushl  -0x28(%ebp)
80105206:	ff 70 10             	pushl  0x10(%eax)
80105209:	68 e0 6e 10 80       	push   $0x80106ee0
8010520e:	e8 f8 b3 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
80105213:	83 c4 20             	add    $0x20,%esp
80105216:	e8 8a e1 ff ff       	call   801033a5 <myproc>
8010521b:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80105222:	e9 a4 fe ff ff       	jmp    801050cb <trap+0x66>
80105227:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010522a:	8b 73 38             	mov    0x38(%ebx),%esi
8010522d:	e8 58 e1 ff ff       	call   8010338a <cpuid>
80105232:	83 ec 0c             	sub    $0xc,%esp
80105235:	57                   	push   %edi
80105236:	56                   	push   %esi
80105237:	50                   	push   %eax
80105238:	ff 73 30             	pushl  0x30(%ebx)
8010523b:	68 ac 6e 10 80       	push   $0x80106eac
80105240:	e8 c6 b3 ff ff       	call   8010060b <cprintf>
      panic("trap");
80105245:	83 c4 14             	add    $0x14,%esp
80105248:	68 82 6e 10 80       	push   $0x80106e82
8010524d:	e8 f6 b0 ff ff       	call   80100348 <panic>
    exit();
80105252:	e8 fa e4 ff ff       	call   80103751 <exit>
80105257:	e9 94 fe ff ff       	jmp    801050f0 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
8010525c:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
80105260:	0f 85 a2 fe ff ff    	jne    80105108 <trap+0xa3>
    yield();
80105266:	e8 ac e5 ff ff       	call   80103817 <yield>
8010526b:	e9 98 fe ff ff       	jmp    80105108 <trap+0xa3>
    exit();
80105270:	e8 dc e4 ff ff       	call   80103751 <exit>
80105275:	e9 b3 fe ff ff       	jmp    8010512d <trap+0xc8>

8010527a <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
8010527a:	55                   	push   %ebp
8010527b:	89 e5                	mov    %esp,%ebp
  if(!uart)
8010527d:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
80105284:	74 15                	je     8010529b <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105286:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010528b:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
8010528c:	a8 01                	test   $0x1,%al
8010528e:	74 12                	je     801052a2 <uartgetc+0x28>
80105290:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105295:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
80105296:	0f b6 c0             	movzbl %al,%eax
}
80105299:	5d                   	pop    %ebp
8010529a:	c3                   	ret    
    return -1;
8010529b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052a0:	eb f7                	jmp    80105299 <uartgetc+0x1f>
    return -1;
801052a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052a7:	eb f0                	jmp    80105299 <uartgetc+0x1f>

801052a9 <uartputc>:
  if(!uart)
801052a9:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
801052b0:	74 3b                	je     801052ed <uartputc+0x44>
{
801052b2:	55                   	push   %ebp
801052b3:	89 e5                	mov    %esp,%ebp
801052b5:	53                   	push   %ebx
801052b6:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801052b9:	bb 00 00 00 00       	mov    $0x0,%ebx
801052be:	eb 10                	jmp    801052d0 <uartputc+0x27>
    microdelay(10);
801052c0:	83 ec 0c             	sub    $0xc,%esp
801052c3:	6a 0a                	push   $0xa
801052c5:	e8 84 d2 ff ff       	call   8010254e <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801052ca:	83 c3 01             	add    $0x1,%ebx
801052cd:	83 c4 10             	add    $0x10,%esp
801052d0:	83 fb 7f             	cmp    $0x7f,%ebx
801052d3:	7f 0a                	jg     801052df <uartputc+0x36>
801052d5:	ba fd 03 00 00       	mov    $0x3fd,%edx
801052da:	ec                   	in     (%dx),%al
801052db:	a8 20                	test   $0x20,%al
801052dd:	74 e1                	je     801052c0 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801052df:	8b 45 08             	mov    0x8(%ebp),%eax
801052e2:	ba f8 03 00 00       	mov    $0x3f8,%edx
801052e7:	ee                   	out    %al,(%dx)
}
801052e8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801052eb:	c9                   	leave  
801052ec:	c3                   	ret    
801052ed:	f3 c3                	repz ret 

801052ef <uartinit>:
{
801052ef:	55                   	push   %ebp
801052f0:	89 e5                	mov    %esp,%ebp
801052f2:	56                   	push   %esi
801052f3:	53                   	push   %ebx
801052f4:	b9 00 00 00 00       	mov    $0x0,%ecx
801052f9:	ba fa 03 00 00       	mov    $0x3fa,%edx
801052fe:	89 c8                	mov    %ecx,%eax
80105300:	ee                   	out    %al,(%dx)
80105301:	be fb 03 00 00       	mov    $0x3fb,%esi
80105306:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
8010530b:	89 f2                	mov    %esi,%edx
8010530d:	ee                   	out    %al,(%dx)
8010530e:	b8 0c 00 00 00       	mov    $0xc,%eax
80105313:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105318:	ee                   	out    %al,(%dx)
80105319:	bb f9 03 00 00       	mov    $0x3f9,%ebx
8010531e:	89 c8                	mov    %ecx,%eax
80105320:	89 da                	mov    %ebx,%edx
80105322:	ee                   	out    %al,(%dx)
80105323:	b8 03 00 00 00       	mov    $0x3,%eax
80105328:	89 f2                	mov    %esi,%edx
8010532a:	ee                   	out    %al,(%dx)
8010532b:	ba fc 03 00 00       	mov    $0x3fc,%edx
80105330:	89 c8                	mov    %ecx,%eax
80105332:	ee                   	out    %al,(%dx)
80105333:	b8 01 00 00 00       	mov    $0x1,%eax
80105338:	89 da                	mov    %ebx,%edx
8010533a:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010533b:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105340:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
80105341:	3c ff                	cmp    $0xff,%al
80105343:	74 45                	je     8010538a <uartinit+0x9b>
  uart = 1;
80105345:	c7 05 bc a5 10 80 01 	movl   $0x1,0x8010a5bc
8010534c:	00 00 00 
8010534f:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105354:	ec                   	in     (%dx),%al
80105355:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010535a:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
8010535b:	83 ec 08             	sub    $0x8,%esp
8010535e:	6a 00                	push   $0x0
80105360:	6a 04                	push   $0x4
80105362:	e8 17 cc ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
80105367:	83 c4 10             	add    $0x10,%esp
8010536a:	bb a4 6f 10 80       	mov    $0x80106fa4,%ebx
8010536f:	eb 12                	jmp    80105383 <uartinit+0x94>
    uartputc(*p);
80105371:	83 ec 0c             	sub    $0xc,%esp
80105374:	0f be c0             	movsbl %al,%eax
80105377:	50                   	push   %eax
80105378:	e8 2c ff ff ff       	call   801052a9 <uartputc>
  for(p="xv6...\n"; *p; p++)
8010537d:	83 c3 01             	add    $0x1,%ebx
80105380:	83 c4 10             	add    $0x10,%esp
80105383:	0f b6 03             	movzbl (%ebx),%eax
80105386:	84 c0                	test   %al,%al
80105388:	75 e7                	jne    80105371 <uartinit+0x82>
}
8010538a:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010538d:	5b                   	pop    %ebx
8010538e:	5e                   	pop    %esi
8010538f:	5d                   	pop    %ebp
80105390:	c3                   	ret    

80105391 <uartintr>:

void
uartintr(void)
{
80105391:	55                   	push   %ebp
80105392:	89 e5                	mov    %esp,%ebp
80105394:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
80105397:	68 7a 52 10 80       	push   $0x8010527a
8010539c:	e8 9d b3 ff ff       	call   8010073e <consoleintr>
}
801053a1:	83 c4 10             	add    $0x10,%esp
801053a4:	c9                   	leave  
801053a5:	c3                   	ret    

801053a6 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801053a6:	6a 00                	push   $0x0
  pushl $0
801053a8:	6a 00                	push   $0x0
  jmp alltraps
801053aa:	e9 be fb ff ff       	jmp    80104f6d <alltraps>

801053af <vector1>:
.globl vector1
vector1:
  pushl $0
801053af:	6a 00                	push   $0x0
  pushl $1
801053b1:	6a 01                	push   $0x1
  jmp alltraps
801053b3:	e9 b5 fb ff ff       	jmp    80104f6d <alltraps>

801053b8 <vector2>:
.globl vector2
vector2:
  pushl $0
801053b8:	6a 00                	push   $0x0
  pushl $2
801053ba:	6a 02                	push   $0x2
  jmp alltraps
801053bc:	e9 ac fb ff ff       	jmp    80104f6d <alltraps>

801053c1 <vector3>:
.globl vector3
vector3:
  pushl $0
801053c1:	6a 00                	push   $0x0
  pushl $3
801053c3:	6a 03                	push   $0x3
  jmp alltraps
801053c5:	e9 a3 fb ff ff       	jmp    80104f6d <alltraps>

801053ca <vector4>:
.globl vector4
vector4:
  pushl $0
801053ca:	6a 00                	push   $0x0
  pushl $4
801053cc:	6a 04                	push   $0x4
  jmp alltraps
801053ce:	e9 9a fb ff ff       	jmp    80104f6d <alltraps>

801053d3 <vector5>:
.globl vector5
vector5:
  pushl $0
801053d3:	6a 00                	push   $0x0
  pushl $5
801053d5:	6a 05                	push   $0x5
  jmp alltraps
801053d7:	e9 91 fb ff ff       	jmp    80104f6d <alltraps>

801053dc <vector6>:
.globl vector6
vector6:
  pushl $0
801053dc:	6a 00                	push   $0x0
  pushl $6
801053de:	6a 06                	push   $0x6
  jmp alltraps
801053e0:	e9 88 fb ff ff       	jmp    80104f6d <alltraps>

801053e5 <vector7>:
.globl vector7
vector7:
  pushl $0
801053e5:	6a 00                	push   $0x0
  pushl $7
801053e7:	6a 07                	push   $0x7
  jmp alltraps
801053e9:	e9 7f fb ff ff       	jmp    80104f6d <alltraps>

801053ee <vector8>:
.globl vector8
vector8:
  pushl $8
801053ee:	6a 08                	push   $0x8
  jmp alltraps
801053f0:	e9 78 fb ff ff       	jmp    80104f6d <alltraps>

801053f5 <vector9>:
.globl vector9
vector9:
  pushl $0
801053f5:	6a 00                	push   $0x0
  pushl $9
801053f7:	6a 09                	push   $0x9
  jmp alltraps
801053f9:	e9 6f fb ff ff       	jmp    80104f6d <alltraps>

801053fe <vector10>:
.globl vector10
vector10:
  pushl $10
801053fe:	6a 0a                	push   $0xa
  jmp alltraps
80105400:	e9 68 fb ff ff       	jmp    80104f6d <alltraps>

80105405 <vector11>:
.globl vector11
vector11:
  pushl $11
80105405:	6a 0b                	push   $0xb
  jmp alltraps
80105407:	e9 61 fb ff ff       	jmp    80104f6d <alltraps>

8010540c <vector12>:
.globl vector12
vector12:
  pushl $12
8010540c:	6a 0c                	push   $0xc
  jmp alltraps
8010540e:	e9 5a fb ff ff       	jmp    80104f6d <alltraps>

80105413 <vector13>:
.globl vector13
vector13:
  pushl $13
80105413:	6a 0d                	push   $0xd
  jmp alltraps
80105415:	e9 53 fb ff ff       	jmp    80104f6d <alltraps>

8010541a <vector14>:
.globl vector14
vector14:
  pushl $14
8010541a:	6a 0e                	push   $0xe
  jmp alltraps
8010541c:	e9 4c fb ff ff       	jmp    80104f6d <alltraps>

80105421 <vector15>:
.globl vector15
vector15:
  pushl $0
80105421:	6a 00                	push   $0x0
  pushl $15
80105423:	6a 0f                	push   $0xf
  jmp alltraps
80105425:	e9 43 fb ff ff       	jmp    80104f6d <alltraps>

8010542a <vector16>:
.globl vector16
vector16:
  pushl $0
8010542a:	6a 00                	push   $0x0
  pushl $16
8010542c:	6a 10                	push   $0x10
  jmp alltraps
8010542e:	e9 3a fb ff ff       	jmp    80104f6d <alltraps>

80105433 <vector17>:
.globl vector17
vector17:
  pushl $17
80105433:	6a 11                	push   $0x11
  jmp alltraps
80105435:	e9 33 fb ff ff       	jmp    80104f6d <alltraps>

8010543a <vector18>:
.globl vector18
vector18:
  pushl $0
8010543a:	6a 00                	push   $0x0
  pushl $18
8010543c:	6a 12                	push   $0x12
  jmp alltraps
8010543e:	e9 2a fb ff ff       	jmp    80104f6d <alltraps>

80105443 <vector19>:
.globl vector19
vector19:
  pushl $0
80105443:	6a 00                	push   $0x0
  pushl $19
80105445:	6a 13                	push   $0x13
  jmp alltraps
80105447:	e9 21 fb ff ff       	jmp    80104f6d <alltraps>

8010544c <vector20>:
.globl vector20
vector20:
  pushl $0
8010544c:	6a 00                	push   $0x0
  pushl $20
8010544e:	6a 14                	push   $0x14
  jmp alltraps
80105450:	e9 18 fb ff ff       	jmp    80104f6d <alltraps>

80105455 <vector21>:
.globl vector21
vector21:
  pushl $0
80105455:	6a 00                	push   $0x0
  pushl $21
80105457:	6a 15                	push   $0x15
  jmp alltraps
80105459:	e9 0f fb ff ff       	jmp    80104f6d <alltraps>

8010545e <vector22>:
.globl vector22
vector22:
  pushl $0
8010545e:	6a 00                	push   $0x0
  pushl $22
80105460:	6a 16                	push   $0x16
  jmp alltraps
80105462:	e9 06 fb ff ff       	jmp    80104f6d <alltraps>

80105467 <vector23>:
.globl vector23
vector23:
  pushl $0
80105467:	6a 00                	push   $0x0
  pushl $23
80105469:	6a 17                	push   $0x17
  jmp alltraps
8010546b:	e9 fd fa ff ff       	jmp    80104f6d <alltraps>

80105470 <vector24>:
.globl vector24
vector24:
  pushl $0
80105470:	6a 00                	push   $0x0
  pushl $24
80105472:	6a 18                	push   $0x18
  jmp alltraps
80105474:	e9 f4 fa ff ff       	jmp    80104f6d <alltraps>

80105479 <vector25>:
.globl vector25
vector25:
  pushl $0
80105479:	6a 00                	push   $0x0
  pushl $25
8010547b:	6a 19                	push   $0x19
  jmp alltraps
8010547d:	e9 eb fa ff ff       	jmp    80104f6d <alltraps>

80105482 <vector26>:
.globl vector26
vector26:
  pushl $0
80105482:	6a 00                	push   $0x0
  pushl $26
80105484:	6a 1a                	push   $0x1a
  jmp alltraps
80105486:	e9 e2 fa ff ff       	jmp    80104f6d <alltraps>

8010548b <vector27>:
.globl vector27
vector27:
  pushl $0
8010548b:	6a 00                	push   $0x0
  pushl $27
8010548d:	6a 1b                	push   $0x1b
  jmp alltraps
8010548f:	e9 d9 fa ff ff       	jmp    80104f6d <alltraps>

80105494 <vector28>:
.globl vector28
vector28:
  pushl $0
80105494:	6a 00                	push   $0x0
  pushl $28
80105496:	6a 1c                	push   $0x1c
  jmp alltraps
80105498:	e9 d0 fa ff ff       	jmp    80104f6d <alltraps>

8010549d <vector29>:
.globl vector29
vector29:
  pushl $0
8010549d:	6a 00                	push   $0x0
  pushl $29
8010549f:	6a 1d                	push   $0x1d
  jmp alltraps
801054a1:	e9 c7 fa ff ff       	jmp    80104f6d <alltraps>

801054a6 <vector30>:
.globl vector30
vector30:
  pushl $0
801054a6:	6a 00                	push   $0x0
  pushl $30
801054a8:	6a 1e                	push   $0x1e
  jmp alltraps
801054aa:	e9 be fa ff ff       	jmp    80104f6d <alltraps>

801054af <vector31>:
.globl vector31
vector31:
  pushl $0
801054af:	6a 00                	push   $0x0
  pushl $31
801054b1:	6a 1f                	push   $0x1f
  jmp alltraps
801054b3:	e9 b5 fa ff ff       	jmp    80104f6d <alltraps>

801054b8 <vector32>:
.globl vector32
vector32:
  pushl $0
801054b8:	6a 00                	push   $0x0
  pushl $32
801054ba:	6a 20                	push   $0x20
  jmp alltraps
801054bc:	e9 ac fa ff ff       	jmp    80104f6d <alltraps>

801054c1 <vector33>:
.globl vector33
vector33:
  pushl $0
801054c1:	6a 00                	push   $0x0
  pushl $33
801054c3:	6a 21                	push   $0x21
  jmp alltraps
801054c5:	e9 a3 fa ff ff       	jmp    80104f6d <alltraps>

801054ca <vector34>:
.globl vector34
vector34:
  pushl $0
801054ca:	6a 00                	push   $0x0
  pushl $34
801054cc:	6a 22                	push   $0x22
  jmp alltraps
801054ce:	e9 9a fa ff ff       	jmp    80104f6d <alltraps>

801054d3 <vector35>:
.globl vector35
vector35:
  pushl $0
801054d3:	6a 00                	push   $0x0
  pushl $35
801054d5:	6a 23                	push   $0x23
  jmp alltraps
801054d7:	e9 91 fa ff ff       	jmp    80104f6d <alltraps>

801054dc <vector36>:
.globl vector36
vector36:
  pushl $0
801054dc:	6a 00                	push   $0x0
  pushl $36
801054de:	6a 24                	push   $0x24
  jmp alltraps
801054e0:	e9 88 fa ff ff       	jmp    80104f6d <alltraps>

801054e5 <vector37>:
.globl vector37
vector37:
  pushl $0
801054e5:	6a 00                	push   $0x0
  pushl $37
801054e7:	6a 25                	push   $0x25
  jmp alltraps
801054e9:	e9 7f fa ff ff       	jmp    80104f6d <alltraps>

801054ee <vector38>:
.globl vector38
vector38:
  pushl $0
801054ee:	6a 00                	push   $0x0
  pushl $38
801054f0:	6a 26                	push   $0x26
  jmp alltraps
801054f2:	e9 76 fa ff ff       	jmp    80104f6d <alltraps>

801054f7 <vector39>:
.globl vector39
vector39:
  pushl $0
801054f7:	6a 00                	push   $0x0
  pushl $39
801054f9:	6a 27                	push   $0x27
  jmp alltraps
801054fb:	e9 6d fa ff ff       	jmp    80104f6d <alltraps>

80105500 <vector40>:
.globl vector40
vector40:
  pushl $0
80105500:	6a 00                	push   $0x0
  pushl $40
80105502:	6a 28                	push   $0x28
  jmp alltraps
80105504:	e9 64 fa ff ff       	jmp    80104f6d <alltraps>

80105509 <vector41>:
.globl vector41
vector41:
  pushl $0
80105509:	6a 00                	push   $0x0
  pushl $41
8010550b:	6a 29                	push   $0x29
  jmp alltraps
8010550d:	e9 5b fa ff ff       	jmp    80104f6d <alltraps>

80105512 <vector42>:
.globl vector42
vector42:
  pushl $0
80105512:	6a 00                	push   $0x0
  pushl $42
80105514:	6a 2a                	push   $0x2a
  jmp alltraps
80105516:	e9 52 fa ff ff       	jmp    80104f6d <alltraps>

8010551b <vector43>:
.globl vector43
vector43:
  pushl $0
8010551b:	6a 00                	push   $0x0
  pushl $43
8010551d:	6a 2b                	push   $0x2b
  jmp alltraps
8010551f:	e9 49 fa ff ff       	jmp    80104f6d <alltraps>

80105524 <vector44>:
.globl vector44
vector44:
  pushl $0
80105524:	6a 00                	push   $0x0
  pushl $44
80105526:	6a 2c                	push   $0x2c
  jmp alltraps
80105528:	e9 40 fa ff ff       	jmp    80104f6d <alltraps>

8010552d <vector45>:
.globl vector45
vector45:
  pushl $0
8010552d:	6a 00                	push   $0x0
  pushl $45
8010552f:	6a 2d                	push   $0x2d
  jmp alltraps
80105531:	e9 37 fa ff ff       	jmp    80104f6d <alltraps>

80105536 <vector46>:
.globl vector46
vector46:
  pushl $0
80105536:	6a 00                	push   $0x0
  pushl $46
80105538:	6a 2e                	push   $0x2e
  jmp alltraps
8010553a:	e9 2e fa ff ff       	jmp    80104f6d <alltraps>

8010553f <vector47>:
.globl vector47
vector47:
  pushl $0
8010553f:	6a 00                	push   $0x0
  pushl $47
80105541:	6a 2f                	push   $0x2f
  jmp alltraps
80105543:	e9 25 fa ff ff       	jmp    80104f6d <alltraps>

80105548 <vector48>:
.globl vector48
vector48:
  pushl $0
80105548:	6a 00                	push   $0x0
  pushl $48
8010554a:	6a 30                	push   $0x30
  jmp alltraps
8010554c:	e9 1c fa ff ff       	jmp    80104f6d <alltraps>

80105551 <vector49>:
.globl vector49
vector49:
  pushl $0
80105551:	6a 00                	push   $0x0
  pushl $49
80105553:	6a 31                	push   $0x31
  jmp alltraps
80105555:	e9 13 fa ff ff       	jmp    80104f6d <alltraps>

8010555a <vector50>:
.globl vector50
vector50:
  pushl $0
8010555a:	6a 00                	push   $0x0
  pushl $50
8010555c:	6a 32                	push   $0x32
  jmp alltraps
8010555e:	e9 0a fa ff ff       	jmp    80104f6d <alltraps>

80105563 <vector51>:
.globl vector51
vector51:
  pushl $0
80105563:	6a 00                	push   $0x0
  pushl $51
80105565:	6a 33                	push   $0x33
  jmp alltraps
80105567:	e9 01 fa ff ff       	jmp    80104f6d <alltraps>

8010556c <vector52>:
.globl vector52
vector52:
  pushl $0
8010556c:	6a 00                	push   $0x0
  pushl $52
8010556e:	6a 34                	push   $0x34
  jmp alltraps
80105570:	e9 f8 f9 ff ff       	jmp    80104f6d <alltraps>

80105575 <vector53>:
.globl vector53
vector53:
  pushl $0
80105575:	6a 00                	push   $0x0
  pushl $53
80105577:	6a 35                	push   $0x35
  jmp alltraps
80105579:	e9 ef f9 ff ff       	jmp    80104f6d <alltraps>

8010557e <vector54>:
.globl vector54
vector54:
  pushl $0
8010557e:	6a 00                	push   $0x0
  pushl $54
80105580:	6a 36                	push   $0x36
  jmp alltraps
80105582:	e9 e6 f9 ff ff       	jmp    80104f6d <alltraps>

80105587 <vector55>:
.globl vector55
vector55:
  pushl $0
80105587:	6a 00                	push   $0x0
  pushl $55
80105589:	6a 37                	push   $0x37
  jmp alltraps
8010558b:	e9 dd f9 ff ff       	jmp    80104f6d <alltraps>

80105590 <vector56>:
.globl vector56
vector56:
  pushl $0
80105590:	6a 00                	push   $0x0
  pushl $56
80105592:	6a 38                	push   $0x38
  jmp alltraps
80105594:	e9 d4 f9 ff ff       	jmp    80104f6d <alltraps>

80105599 <vector57>:
.globl vector57
vector57:
  pushl $0
80105599:	6a 00                	push   $0x0
  pushl $57
8010559b:	6a 39                	push   $0x39
  jmp alltraps
8010559d:	e9 cb f9 ff ff       	jmp    80104f6d <alltraps>

801055a2 <vector58>:
.globl vector58
vector58:
  pushl $0
801055a2:	6a 00                	push   $0x0
  pushl $58
801055a4:	6a 3a                	push   $0x3a
  jmp alltraps
801055a6:	e9 c2 f9 ff ff       	jmp    80104f6d <alltraps>

801055ab <vector59>:
.globl vector59
vector59:
  pushl $0
801055ab:	6a 00                	push   $0x0
  pushl $59
801055ad:	6a 3b                	push   $0x3b
  jmp alltraps
801055af:	e9 b9 f9 ff ff       	jmp    80104f6d <alltraps>

801055b4 <vector60>:
.globl vector60
vector60:
  pushl $0
801055b4:	6a 00                	push   $0x0
  pushl $60
801055b6:	6a 3c                	push   $0x3c
  jmp alltraps
801055b8:	e9 b0 f9 ff ff       	jmp    80104f6d <alltraps>

801055bd <vector61>:
.globl vector61
vector61:
  pushl $0
801055bd:	6a 00                	push   $0x0
  pushl $61
801055bf:	6a 3d                	push   $0x3d
  jmp alltraps
801055c1:	e9 a7 f9 ff ff       	jmp    80104f6d <alltraps>

801055c6 <vector62>:
.globl vector62
vector62:
  pushl $0
801055c6:	6a 00                	push   $0x0
  pushl $62
801055c8:	6a 3e                	push   $0x3e
  jmp alltraps
801055ca:	e9 9e f9 ff ff       	jmp    80104f6d <alltraps>

801055cf <vector63>:
.globl vector63
vector63:
  pushl $0
801055cf:	6a 00                	push   $0x0
  pushl $63
801055d1:	6a 3f                	push   $0x3f
  jmp alltraps
801055d3:	e9 95 f9 ff ff       	jmp    80104f6d <alltraps>

801055d8 <vector64>:
.globl vector64
vector64:
  pushl $0
801055d8:	6a 00                	push   $0x0
  pushl $64
801055da:	6a 40                	push   $0x40
  jmp alltraps
801055dc:	e9 8c f9 ff ff       	jmp    80104f6d <alltraps>

801055e1 <vector65>:
.globl vector65
vector65:
  pushl $0
801055e1:	6a 00                	push   $0x0
  pushl $65
801055e3:	6a 41                	push   $0x41
  jmp alltraps
801055e5:	e9 83 f9 ff ff       	jmp    80104f6d <alltraps>

801055ea <vector66>:
.globl vector66
vector66:
  pushl $0
801055ea:	6a 00                	push   $0x0
  pushl $66
801055ec:	6a 42                	push   $0x42
  jmp alltraps
801055ee:	e9 7a f9 ff ff       	jmp    80104f6d <alltraps>

801055f3 <vector67>:
.globl vector67
vector67:
  pushl $0
801055f3:	6a 00                	push   $0x0
  pushl $67
801055f5:	6a 43                	push   $0x43
  jmp alltraps
801055f7:	e9 71 f9 ff ff       	jmp    80104f6d <alltraps>

801055fc <vector68>:
.globl vector68
vector68:
  pushl $0
801055fc:	6a 00                	push   $0x0
  pushl $68
801055fe:	6a 44                	push   $0x44
  jmp alltraps
80105600:	e9 68 f9 ff ff       	jmp    80104f6d <alltraps>

80105605 <vector69>:
.globl vector69
vector69:
  pushl $0
80105605:	6a 00                	push   $0x0
  pushl $69
80105607:	6a 45                	push   $0x45
  jmp alltraps
80105609:	e9 5f f9 ff ff       	jmp    80104f6d <alltraps>

8010560e <vector70>:
.globl vector70
vector70:
  pushl $0
8010560e:	6a 00                	push   $0x0
  pushl $70
80105610:	6a 46                	push   $0x46
  jmp alltraps
80105612:	e9 56 f9 ff ff       	jmp    80104f6d <alltraps>

80105617 <vector71>:
.globl vector71
vector71:
  pushl $0
80105617:	6a 00                	push   $0x0
  pushl $71
80105619:	6a 47                	push   $0x47
  jmp alltraps
8010561b:	e9 4d f9 ff ff       	jmp    80104f6d <alltraps>

80105620 <vector72>:
.globl vector72
vector72:
  pushl $0
80105620:	6a 00                	push   $0x0
  pushl $72
80105622:	6a 48                	push   $0x48
  jmp alltraps
80105624:	e9 44 f9 ff ff       	jmp    80104f6d <alltraps>

80105629 <vector73>:
.globl vector73
vector73:
  pushl $0
80105629:	6a 00                	push   $0x0
  pushl $73
8010562b:	6a 49                	push   $0x49
  jmp alltraps
8010562d:	e9 3b f9 ff ff       	jmp    80104f6d <alltraps>

80105632 <vector74>:
.globl vector74
vector74:
  pushl $0
80105632:	6a 00                	push   $0x0
  pushl $74
80105634:	6a 4a                	push   $0x4a
  jmp alltraps
80105636:	e9 32 f9 ff ff       	jmp    80104f6d <alltraps>

8010563b <vector75>:
.globl vector75
vector75:
  pushl $0
8010563b:	6a 00                	push   $0x0
  pushl $75
8010563d:	6a 4b                	push   $0x4b
  jmp alltraps
8010563f:	e9 29 f9 ff ff       	jmp    80104f6d <alltraps>

80105644 <vector76>:
.globl vector76
vector76:
  pushl $0
80105644:	6a 00                	push   $0x0
  pushl $76
80105646:	6a 4c                	push   $0x4c
  jmp alltraps
80105648:	e9 20 f9 ff ff       	jmp    80104f6d <alltraps>

8010564d <vector77>:
.globl vector77
vector77:
  pushl $0
8010564d:	6a 00                	push   $0x0
  pushl $77
8010564f:	6a 4d                	push   $0x4d
  jmp alltraps
80105651:	e9 17 f9 ff ff       	jmp    80104f6d <alltraps>

80105656 <vector78>:
.globl vector78
vector78:
  pushl $0
80105656:	6a 00                	push   $0x0
  pushl $78
80105658:	6a 4e                	push   $0x4e
  jmp alltraps
8010565a:	e9 0e f9 ff ff       	jmp    80104f6d <alltraps>

8010565f <vector79>:
.globl vector79
vector79:
  pushl $0
8010565f:	6a 00                	push   $0x0
  pushl $79
80105661:	6a 4f                	push   $0x4f
  jmp alltraps
80105663:	e9 05 f9 ff ff       	jmp    80104f6d <alltraps>

80105668 <vector80>:
.globl vector80
vector80:
  pushl $0
80105668:	6a 00                	push   $0x0
  pushl $80
8010566a:	6a 50                	push   $0x50
  jmp alltraps
8010566c:	e9 fc f8 ff ff       	jmp    80104f6d <alltraps>

80105671 <vector81>:
.globl vector81
vector81:
  pushl $0
80105671:	6a 00                	push   $0x0
  pushl $81
80105673:	6a 51                	push   $0x51
  jmp alltraps
80105675:	e9 f3 f8 ff ff       	jmp    80104f6d <alltraps>

8010567a <vector82>:
.globl vector82
vector82:
  pushl $0
8010567a:	6a 00                	push   $0x0
  pushl $82
8010567c:	6a 52                	push   $0x52
  jmp alltraps
8010567e:	e9 ea f8 ff ff       	jmp    80104f6d <alltraps>

80105683 <vector83>:
.globl vector83
vector83:
  pushl $0
80105683:	6a 00                	push   $0x0
  pushl $83
80105685:	6a 53                	push   $0x53
  jmp alltraps
80105687:	e9 e1 f8 ff ff       	jmp    80104f6d <alltraps>

8010568c <vector84>:
.globl vector84
vector84:
  pushl $0
8010568c:	6a 00                	push   $0x0
  pushl $84
8010568e:	6a 54                	push   $0x54
  jmp alltraps
80105690:	e9 d8 f8 ff ff       	jmp    80104f6d <alltraps>

80105695 <vector85>:
.globl vector85
vector85:
  pushl $0
80105695:	6a 00                	push   $0x0
  pushl $85
80105697:	6a 55                	push   $0x55
  jmp alltraps
80105699:	e9 cf f8 ff ff       	jmp    80104f6d <alltraps>

8010569e <vector86>:
.globl vector86
vector86:
  pushl $0
8010569e:	6a 00                	push   $0x0
  pushl $86
801056a0:	6a 56                	push   $0x56
  jmp alltraps
801056a2:	e9 c6 f8 ff ff       	jmp    80104f6d <alltraps>

801056a7 <vector87>:
.globl vector87
vector87:
  pushl $0
801056a7:	6a 00                	push   $0x0
  pushl $87
801056a9:	6a 57                	push   $0x57
  jmp alltraps
801056ab:	e9 bd f8 ff ff       	jmp    80104f6d <alltraps>

801056b0 <vector88>:
.globl vector88
vector88:
  pushl $0
801056b0:	6a 00                	push   $0x0
  pushl $88
801056b2:	6a 58                	push   $0x58
  jmp alltraps
801056b4:	e9 b4 f8 ff ff       	jmp    80104f6d <alltraps>

801056b9 <vector89>:
.globl vector89
vector89:
  pushl $0
801056b9:	6a 00                	push   $0x0
  pushl $89
801056bb:	6a 59                	push   $0x59
  jmp alltraps
801056bd:	e9 ab f8 ff ff       	jmp    80104f6d <alltraps>

801056c2 <vector90>:
.globl vector90
vector90:
  pushl $0
801056c2:	6a 00                	push   $0x0
  pushl $90
801056c4:	6a 5a                	push   $0x5a
  jmp alltraps
801056c6:	e9 a2 f8 ff ff       	jmp    80104f6d <alltraps>

801056cb <vector91>:
.globl vector91
vector91:
  pushl $0
801056cb:	6a 00                	push   $0x0
  pushl $91
801056cd:	6a 5b                	push   $0x5b
  jmp alltraps
801056cf:	e9 99 f8 ff ff       	jmp    80104f6d <alltraps>

801056d4 <vector92>:
.globl vector92
vector92:
  pushl $0
801056d4:	6a 00                	push   $0x0
  pushl $92
801056d6:	6a 5c                	push   $0x5c
  jmp alltraps
801056d8:	e9 90 f8 ff ff       	jmp    80104f6d <alltraps>

801056dd <vector93>:
.globl vector93
vector93:
  pushl $0
801056dd:	6a 00                	push   $0x0
  pushl $93
801056df:	6a 5d                	push   $0x5d
  jmp alltraps
801056e1:	e9 87 f8 ff ff       	jmp    80104f6d <alltraps>

801056e6 <vector94>:
.globl vector94
vector94:
  pushl $0
801056e6:	6a 00                	push   $0x0
  pushl $94
801056e8:	6a 5e                	push   $0x5e
  jmp alltraps
801056ea:	e9 7e f8 ff ff       	jmp    80104f6d <alltraps>

801056ef <vector95>:
.globl vector95
vector95:
  pushl $0
801056ef:	6a 00                	push   $0x0
  pushl $95
801056f1:	6a 5f                	push   $0x5f
  jmp alltraps
801056f3:	e9 75 f8 ff ff       	jmp    80104f6d <alltraps>

801056f8 <vector96>:
.globl vector96
vector96:
  pushl $0
801056f8:	6a 00                	push   $0x0
  pushl $96
801056fa:	6a 60                	push   $0x60
  jmp alltraps
801056fc:	e9 6c f8 ff ff       	jmp    80104f6d <alltraps>

80105701 <vector97>:
.globl vector97
vector97:
  pushl $0
80105701:	6a 00                	push   $0x0
  pushl $97
80105703:	6a 61                	push   $0x61
  jmp alltraps
80105705:	e9 63 f8 ff ff       	jmp    80104f6d <alltraps>

8010570a <vector98>:
.globl vector98
vector98:
  pushl $0
8010570a:	6a 00                	push   $0x0
  pushl $98
8010570c:	6a 62                	push   $0x62
  jmp alltraps
8010570e:	e9 5a f8 ff ff       	jmp    80104f6d <alltraps>

80105713 <vector99>:
.globl vector99
vector99:
  pushl $0
80105713:	6a 00                	push   $0x0
  pushl $99
80105715:	6a 63                	push   $0x63
  jmp alltraps
80105717:	e9 51 f8 ff ff       	jmp    80104f6d <alltraps>

8010571c <vector100>:
.globl vector100
vector100:
  pushl $0
8010571c:	6a 00                	push   $0x0
  pushl $100
8010571e:	6a 64                	push   $0x64
  jmp alltraps
80105720:	e9 48 f8 ff ff       	jmp    80104f6d <alltraps>

80105725 <vector101>:
.globl vector101
vector101:
  pushl $0
80105725:	6a 00                	push   $0x0
  pushl $101
80105727:	6a 65                	push   $0x65
  jmp alltraps
80105729:	e9 3f f8 ff ff       	jmp    80104f6d <alltraps>

8010572e <vector102>:
.globl vector102
vector102:
  pushl $0
8010572e:	6a 00                	push   $0x0
  pushl $102
80105730:	6a 66                	push   $0x66
  jmp alltraps
80105732:	e9 36 f8 ff ff       	jmp    80104f6d <alltraps>

80105737 <vector103>:
.globl vector103
vector103:
  pushl $0
80105737:	6a 00                	push   $0x0
  pushl $103
80105739:	6a 67                	push   $0x67
  jmp alltraps
8010573b:	e9 2d f8 ff ff       	jmp    80104f6d <alltraps>

80105740 <vector104>:
.globl vector104
vector104:
  pushl $0
80105740:	6a 00                	push   $0x0
  pushl $104
80105742:	6a 68                	push   $0x68
  jmp alltraps
80105744:	e9 24 f8 ff ff       	jmp    80104f6d <alltraps>

80105749 <vector105>:
.globl vector105
vector105:
  pushl $0
80105749:	6a 00                	push   $0x0
  pushl $105
8010574b:	6a 69                	push   $0x69
  jmp alltraps
8010574d:	e9 1b f8 ff ff       	jmp    80104f6d <alltraps>

80105752 <vector106>:
.globl vector106
vector106:
  pushl $0
80105752:	6a 00                	push   $0x0
  pushl $106
80105754:	6a 6a                	push   $0x6a
  jmp alltraps
80105756:	e9 12 f8 ff ff       	jmp    80104f6d <alltraps>

8010575b <vector107>:
.globl vector107
vector107:
  pushl $0
8010575b:	6a 00                	push   $0x0
  pushl $107
8010575d:	6a 6b                	push   $0x6b
  jmp alltraps
8010575f:	e9 09 f8 ff ff       	jmp    80104f6d <alltraps>

80105764 <vector108>:
.globl vector108
vector108:
  pushl $0
80105764:	6a 00                	push   $0x0
  pushl $108
80105766:	6a 6c                	push   $0x6c
  jmp alltraps
80105768:	e9 00 f8 ff ff       	jmp    80104f6d <alltraps>

8010576d <vector109>:
.globl vector109
vector109:
  pushl $0
8010576d:	6a 00                	push   $0x0
  pushl $109
8010576f:	6a 6d                	push   $0x6d
  jmp alltraps
80105771:	e9 f7 f7 ff ff       	jmp    80104f6d <alltraps>

80105776 <vector110>:
.globl vector110
vector110:
  pushl $0
80105776:	6a 00                	push   $0x0
  pushl $110
80105778:	6a 6e                	push   $0x6e
  jmp alltraps
8010577a:	e9 ee f7 ff ff       	jmp    80104f6d <alltraps>

8010577f <vector111>:
.globl vector111
vector111:
  pushl $0
8010577f:	6a 00                	push   $0x0
  pushl $111
80105781:	6a 6f                	push   $0x6f
  jmp alltraps
80105783:	e9 e5 f7 ff ff       	jmp    80104f6d <alltraps>

80105788 <vector112>:
.globl vector112
vector112:
  pushl $0
80105788:	6a 00                	push   $0x0
  pushl $112
8010578a:	6a 70                	push   $0x70
  jmp alltraps
8010578c:	e9 dc f7 ff ff       	jmp    80104f6d <alltraps>

80105791 <vector113>:
.globl vector113
vector113:
  pushl $0
80105791:	6a 00                	push   $0x0
  pushl $113
80105793:	6a 71                	push   $0x71
  jmp alltraps
80105795:	e9 d3 f7 ff ff       	jmp    80104f6d <alltraps>

8010579a <vector114>:
.globl vector114
vector114:
  pushl $0
8010579a:	6a 00                	push   $0x0
  pushl $114
8010579c:	6a 72                	push   $0x72
  jmp alltraps
8010579e:	e9 ca f7 ff ff       	jmp    80104f6d <alltraps>

801057a3 <vector115>:
.globl vector115
vector115:
  pushl $0
801057a3:	6a 00                	push   $0x0
  pushl $115
801057a5:	6a 73                	push   $0x73
  jmp alltraps
801057a7:	e9 c1 f7 ff ff       	jmp    80104f6d <alltraps>

801057ac <vector116>:
.globl vector116
vector116:
  pushl $0
801057ac:	6a 00                	push   $0x0
  pushl $116
801057ae:	6a 74                	push   $0x74
  jmp alltraps
801057b0:	e9 b8 f7 ff ff       	jmp    80104f6d <alltraps>

801057b5 <vector117>:
.globl vector117
vector117:
  pushl $0
801057b5:	6a 00                	push   $0x0
  pushl $117
801057b7:	6a 75                	push   $0x75
  jmp alltraps
801057b9:	e9 af f7 ff ff       	jmp    80104f6d <alltraps>

801057be <vector118>:
.globl vector118
vector118:
  pushl $0
801057be:	6a 00                	push   $0x0
  pushl $118
801057c0:	6a 76                	push   $0x76
  jmp alltraps
801057c2:	e9 a6 f7 ff ff       	jmp    80104f6d <alltraps>

801057c7 <vector119>:
.globl vector119
vector119:
  pushl $0
801057c7:	6a 00                	push   $0x0
  pushl $119
801057c9:	6a 77                	push   $0x77
  jmp alltraps
801057cb:	e9 9d f7 ff ff       	jmp    80104f6d <alltraps>

801057d0 <vector120>:
.globl vector120
vector120:
  pushl $0
801057d0:	6a 00                	push   $0x0
  pushl $120
801057d2:	6a 78                	push   $0x78
  jmp alltraps
801057d4:	e9 94 f7 ff ff       	jmp    80104f6d <alltraps>

801057d9 <vector121>:
.globl vector121
vector121:
  pushl $0
801057d9:	6a 00                	push   $0x0
  pushl $121
801057db:	6a 79                	push   $0x79
  jmp alltraps
801057dd:	e9 8b f7 ff ff       	jmp    80104f6d <alltraps>

801057e2 <vector122>:
.globl vector122
vector122:
  pushl $0
801057e2:	6a 00                	push   $0x0
  pushl $122
801057e4:	6a 7a                	push   $0x7a
  jmp alltraps
801057e6:	e9 82 f7 ff ff       	jmp    80104f6d <alltraps>

801057eb <vector123>:
.globl vector123
vector123:
  pushl $0
801057eb:	6a 00                	push   $0x0
  pushl $123
801057ed:	6a 7b                	push   $0x7b
  jmp alltraps
801057ef:	e9 79 f7 ff ff       	jmp    80104f6d <alltraps>

801057f4 <vector124>:
.globl vector124
vector124:
  pushl $0
801057f4:	6a 00                	push   $0x0
  pushl $124
801057f6:	6a 7c                	push   $0x7c
  jmp alltraps
801057f8:	e9 70 f7 ff ff       	jmp    80104f6d <alltraps>

801057fd <vector125>:
.globl vector125
vector125:
  pushl $0
801057fd:	6a 00                	push   $0x0
  pushl $125
801057ff:	6a 7d                	push   $0x7d
  jmp alltraps
80105801:	e9 67 f7 ff ff       	jmp    80104f6d <alltraps>

80105806 <vector126>:
.globl vector126
vector126:
  pushl $0
80105806:	6a 00                	push   $0x0
  pushl $126
80105808:	6a 7e                	push   $0x7e
  jmp alltraps
8010580a:	e9 5e f7 ff ff       	jmp    80104f6d <alltraps>

8010580f <vector127>:
.globl vector127
vector127:
  pushl $0
8010580f:	6a 00                	push   $0x0
  pushl $127
80105811:	6a 7f                	push   $0x7f
  jmp alltraps
80105813:	e9 55 f7 ff ff       	jmp    80104f6d <alltraps>

80105818 <vector128>:
.globl vector128
vector128:
  pushl $0
80105818:	6a 00                	push   $0x0
  pushl $128
8010581a:	68 80 00 00 00       	push   $0x80
  jmp alltraps
8010581f:	e9 49 f7 ff ff       	jmp    80104f6d <alltraps>

80105824 <vector129>:
.globl vector129
vector129:
  pushl $0
80105824:	6a 00                	push   $0x0
  pushl $129
80105826:	68 81 00 00 00       	push   $0x81
  jmp alltraps
8010582b:	e9 3d f7 ff ff       	jmp    80104f6d <alltraps>

80105830 <vector130>:
.globl vector130
vector130:
  pushl $0
80105830:	6a 00                	push   $0x0
  pushl $130
80105832:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80105837:	e9 31 f7 ff ff       	jmp    80104f6d <alltraps>

8010583c <vector131>:
.globl vector131
vector131:
  pushl $0
8010583c:	6a 00                	push   $0x0
  pushl $131
8010583e:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105843:	e9 25 f7 ff ff       	jmp    80104f6d <alltraps>

80105848 <vector132>:
.globl vector132
vector132:
  pushl $0
80105848:	6a 00                	push   $0x0
  pushl $132
8010584a:	68 84 00 00 00       	push   $0x84
  jmp alltraps
8010584f:	e9 19 f7 ff ff       	jmp    80104f6d <alltraps>

80105854 <vector133>:
.globl vector133
vector133:
  pushl $0
80105854:	6a 00                	push   $0x0
  pushl $133
80105856:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010585b:	e9 0d f7 ff ff       	jmp    80104f6d <alltraps>

80105860 <vector134>:
.globl vector134
vector134:
  pushl $0
80105860:	6a 00                	push   $0x0
  pushl $134
80105862:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80105867:	e9 01 f7 ff ff       	jmp    80104f6d <alltraps>

8010586c <vector135>:
.globl vector135
vector135:
  pushl $0
8010586c:	6a 00                	push   $0x0
  pushl $135
8010586e:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105873:	e9 f5 f6 ff ff       	jmp    80104f6d <alltraps>

80105878 <vector136>:
.globl vector136
vector136:
  pushl $0
80105878:	6a 00                	push   $0x0
  pushl $136
8010587a:	68 88 00 00 00       	push   $0x88
  jmp alltraps
8010587f:	e9 e9 f6 ff ff       	jmp    80104f6d <alltraps>

80105884 <vector137>:
.globl vector137
vector137:
  pushl $0
80105884:	6a 00                	push   $0x0
  pushl $137
80105886:	68 89 00 00 00       	push   $0x89
  jmp alltraps
8010588b:	e9 dd f6 ff ff       	jmp    80104f6d <alltraps>

80105890 <vector138>:
.globl vector138
vector138:
  pushl $0
80105890:	6a 00                	push   $0x0
  pushl $138
80105892:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105897:	e9 d1 f6 ff ff       	jmp    80104f6d <alltraps>

8010589c <vector139>:
.globl vector139
vector139:
  pushl $0
8010589c:	6a 00                	push   $0x0
  pushl $139
8010589e:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801058a3:	e9 c5 f6 ff ff       	jmp    80104f6d <alltraps>

801058a8 <vector140>:
.globl vector140
vector140:
  pushl $0
801058a8:	6a 00                	push   $0x0
  pushl $140
801058aa:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801058af:	e9 b9 f6 ff ff       	jmp    80104f6d <alltraps>

801058b4 <vector141>:
.globl vector141
vector141:
  pushl $0
801058b4:	6a 00                	push   $0x0
  pushl $141
801058b6:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801058bb:	e9 ad f6 ff ff       	jmp    80104f6d <alltraps>

801058c0 <vector142>:
.globl vector142
vector142:
  pushl $0
801058c0:	6a 00                	push   $0x0
  pushl $142
801058c2:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801058c7:	e9 a1 f6 ff ff       	jmp    80104f6d <alltraps>

801058cc <vector143>:
.globl vector143
vector143:
  pushl $0
801058cc:	6a 00                	push   $0x0
  pushl $143
801058ce:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801058d3:	e9 95 f6 ff ff       	jmp    80104f6d <alltraps>

801058d8 <vector144>:
.globl vector144
vector144:
  pushl $0
801058d8:	6a 00                	push   $0x0
  pushl $144
801058da:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801058df:	e9 89 f6 ff ff       	jmp    80104f6d <alltraps>

801058e4 <vector145>:
.globl vector145
vector145:
  pushl $0
801058e4:	6a 00                	push   $0x0
  pushl $145
801058e6:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801058eb:	e9 7d f6 ff ff       	jmp    80104f6d <alltraps>

801058f0 <vector146>:
.globl vector146
vector146:
  pushl $0
801058f0:	6a 00                	push   $0x0
  pushl $146
801058f2:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801058f7:	e9 71 f6 ff ff       	jmp    80104f6d <alltraps>

801058fc <vector147>:
.globl vector147
vector147:
  pushl $0
801058fc:	6a 00                	push   $0x0
  pushl $147
801058fe:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105903:	e9 65 f6 ff ff       	jmp    80104f6d <alltraps>

80105908 <vector148>:
.globl vector148
vector148:
  pushl $0
80105908:	6a 00                	push   $0x0
  pushl $148
8010590a:	68 94 00 00 00       	push   $0x94
  jmp alltraps
8010590f:	e9 59 f6 ff ff       	jmp    80104f6d <alltraps>

80105914 <vector149>:
.globl vector149
vector149:
  pushl $0
80105914:	6a 00                	push   $0x0
  pushl $149
80105916:	68 95 00 00 00       	push   $0x95
  jmp alltraps
8010591b:	e9 4d f6 ff ff       	jmp    80104f6d <alltraps>

80105920 <vector150>:
.globl vector150
vector150:
  pushl $0
80105920:	6a 00                	push   $0x0
  pushl $150
80105922:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80105927:	e9 41 f6 ff ff       	jmp    80104f6d <alltraps>

8010592c <vector151>:
.globl vector151
vector151:
  pushl $0
8010592c:	6a 00                	push   $0x0
  pushl $151
8010592e:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105933:	e9 35 f6 ff ff       	jmp    80104f6d <alltraps>

80105938 <vector152>:
.globl vector152
vector152:
  pushl $0
80105938:	6a 00                	push   $0x0
  pushl $152
8010593a:	68 98 00 00 00       	push   $0x98
  jmp alltraps
8010593f:	e9 29 f6 ff ff       	jmp    80104f6d <alltraps>

80105944 <vector153>:
.globl vector153
vector153:
  pushl $0
80105944:	6a 00                	push   $0x0
  pushl $153
80105946:	68 99 00 00 00       	push   $0x99
  jmp alltraps
8010594b:	e9 1d f6 ff ff       	jmp    80104f6d <alltraps>

80105950 <vector154>:
.globl vector154
vector154:
  pushl $0
80105950:	6a 00                	push   $0x0
  pushl $154
80105952:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105957:	e9 11 f6 ff ff       	jmp    80104f6d <alltraps>

8010595c <vector155>:
.globl vector155
vector155:
  pushl $0
8010595c:	6a 00                	push   $0x0
  pushl $155
8010595e:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105963:	e9 05 f6 ff ff       	jmp    80104f6d <alltraps>

80105968 <vector156>:
.globl vector156
vector156:
  pushl $0
80105968:	6a 00                	push   $0x0
  pushl $156
8010596a:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
8010596f:	e9 f9 f5 ff ff       	jmp    80104f6d <alltraps>

80105974 <vector157>:
.globl vector157
vector157:
  pushl $0
80105974:	6a 00                	push   $0x0
  pushl $157
80105976:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
8010597b:	e9 ed f5 ff ff       	jmp    80104f6d <alltraps>

80105980 <vector158>:
.globl vector158
vector158:
  pushl $0
80105980:	6a 00                	push   $0x0
  pushl $158
80105982:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105987:	e9 e1 f5 ff ff       	jmp    80104f6d <alltraps>

8010598c <vector159>:
.globl vector159
vector159:
  pushl $0
8010598c:	6a 00                	push   $0x0
  pushl $159
8010598e:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105993:	e9 d5 f5 ff ff       	jmp    80104f6d <alltraps>

80105998 <vector160>:
.globl vector160
vector160:
  pushl $0
80105998:	6a 00                	push   $0x0
  pushl $160
8010599a:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
8010599f:	e9 c9 f5 ff ff       	jmp    80104f6d <alltraps>

801059a4 <vector161>:
.globl vector161
vector161:
  pushl $0
801059a4:	6a 00                	push   $0x0
  pushl $161
801059a6:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801059ab:	e9 bd f5 ff ff       	jmp    80104f6d <alltraps>

801059b0 <vector162>:
.globl vector162
vector162:
  pushl $0
801059b0:	6a 00                	push   $0x0
  pushl $162
801059b2:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801059b7:	e9 b1 f5 ff ff       	jmp    80104f6d <alltraps>

801059bc <vector163>:
.globl vector163
vector163:
  pushl $0
801059bc:	6a 00                	push   $0x0
  pushl $163
801059be:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801059c3:	e9 a5 f5 ff ff       	jmp    80104f6d <alltraps>

801059c8 <vector164>:
.globl vector164
vector164:
  pushl $0
801059c8:	6a 00                	push   $0x0
  pushl $164
801059ca:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801059cf:	e9 99 f5 ff ff       	jmp    80104f6d <alltraps>

801059d4 <vector165>:
.globl vector165
vector165:
  pushl $0
801059d4:	6a 00                	push   $0x0
  pushl $165
801059d6:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801059db:	e9 8d f5 ff ff       	jmp    80104f6d <alltraps>

801059e0 <vector166>:
.globl vector166
vector166:
  pushl $0
801059e0:	6a 00                	push   $0x0
  pushl $166
801059e2:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801059e7:	e9 81 f5 ff ff       	jmp    80104f6d <alltraps>

801059ec <vector167>:
.globl vector167
vector167:
  pushl $0
801059ec:	6a 00                	push   $0x0
  pushl $167
801059ee:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801059f3:	e9 75 f5 ff ff       	jmp    80104f6d <alltraps>

801059f8 <vector168>:
.globl vector168
vector168:
  pushl $0
801059f8:	6a 00                	push   $0x0
  pushl $168
801059fa:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801059ff:	e9 69 f5 ff ff       	jmp    80104f6d <alltraps>

80105a04 <vector169>:
.globl vector169
vector169:
  pushl $0
80105a04:	6a 00                	push   $0x0
  pushl $169
80105a06:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105a0b:	e9 5d f5 ff ff       	jmp    80104f6d <alltraps>

80105a10 <vector170>:
.globl vector170
vector170:
  pushl $0
80105a10:	6a 00                	push   $0x0
  pushl $170
80105a12:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105a17:	e9 51 f5 ff ff       	jmp    80104f6d <alltraps>

80105a1c <vector171>:
.globl vector171
vector171:
  pushl $0
80105a1c:	6a 00                	push   $0x0
  pushl $171
80105a1e:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105a23:	e9 45 f5 ff ff       	jmp    80104f6d <alltraps>

80105a28 <vector172>:
.globl vector172
vector172:
  pushl $0
80105a28:	6a 00                	push   $0x0
  pushl $172
80105a2a:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105a2f:	e9 39 f5 ff ff       	jmp    80104f6d <alltraps>

80105a34 <vector173>:
.globl vector173
vector173:
  pushl $0
80105a34:	6a 00                	push   $0x0
  pushl $173
80105a36:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105a3b:	e9 2d f5 ff ff       	jmp    80104f6d <alltraps>

80105a40 <vector174>:
.globl vector174
vector174:
  pushl $0
80105a40:	6a 00                	push   $0x0
  pushl $174
80105a42:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105a47:	e9 21 f5 ff ff       	jmp    80104f6d <alltraps>

80105a4c <vector175>:
.globl vector175
vector175:
  pushl $0
80105a4c:	6a 00                	push   $0x0
  pushl $175
80105a4e:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105a53:	e9 15 f5 ff ff       	jmp    80104f6d <alltraps>

80105a58 <vector176>:
.globl vector176
vector176:
  pushl $0
80105a58:	6a 00                	push   $0x0
  pushl $176
80105a5a:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105a5f:	e9 09 f5 ff ff       	jmp    80104f6d <alltraps>

80105a64 <vector177>:
.globl vector177
vector177:
  pushl $0
80105a64:	6a 00                	push   $0x0
  pushl $177
80105a66:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105a6b:	e9 fd f4 ff ff       	jmp    80104f6d <alltraps>

80105a70 <vector178>:
.globl vector178
vector178:
  pushl $0
80105a70:	6a 00                	push   $0x0
  pushl $178
80105a72:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105a77:	e9 f1 f4 ff ff       	jmp    80104f6d <alltraps>

80105a7c <vector179>:
.globl vector179
vector179:
  pushl $0
80105a7c:	6a 00                	push   $0x0
  pushl $179
80105a7e:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105a83:	e9 e5 f4 ff ff       	jmp    80104f6d <alltraps>

80105a88 <vector180>:
.globl vector180
vector180:
  pushl $0
80105a88:	6a 00                	push   $0x0
  pushl $180
80105a8a:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105a8f:	e9 d9 f4 ff ff       	jmp    80104f6d <alltraps>

80105a94 <vector181>:
.globl vector181
vector181:
  pushl $0
80105a94:	6a 00                	push   $0x0
  pushl $181
80105a96:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105a9b:	e9 cd f4 ff ff       	jmp    80104f6d <alltraps>

80105aa0 <vector182>:
.globl vector182
vector182:
  pushl $0
80105aa0:	6a 00                	push   $0x0
  pushl $182
80105aa2:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105aa7:	e9 c1 f4 ff ff       	jmp    80104f6d <alltraps>

80105aac <vector183>:
.globl vector183
vector183:
  pushl $0
80105aac:	6a 00                	push   $0x0
  pushl $183
80105aae:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105ab3:	e9 b5 f4 ff ff       	jmp    80104f6d <alltraps>

80105ab8 <vector184>:
.globl vector184
vector184:
  pushl $0
80105ab8:	6a 00                	push   $0x0
  pushl $184
80105aba:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105abf:	e9 a9 f4 ff ff       	jmp    80104f6d <alltraps>

80105ac4 <vector185>:
.globl vector185
vector185:
  pushl $0
80105ac4:	6a 00                	push   $0x0
  pushl $185
80105ac6:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105acb:	e9 9d f4 ff ff       	jmp    80104f6d <alltraps>

80105ad0 <vector186>:
.globl vector186
vector186:
  pushl $0
80105ad0:	6a 00                	push   $0x0
  pushl $186
80105ad2:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105ad7:	e9 91 f4 ff ff       	jmp    80104f6d <alltraps>

80105adc <vector187>:
.globl vector187
vector187:
  pushl $0
80105adc:	6a 00                	push   $0x0
  pushl $187
80105ade:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105ae3:	e9 85 f4 ff ff       	jmp    80104f6d <alltraps>

80105ae8 <vector188>:
.globl vector188
vector188:
  pushl $0
80105ae8:	6a 00                	push   $0x0
  pushl $188
80105aea:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105aef:	e9 79 f4 ff ff       	jmp    80104f6d <alltraps>

80105af4 <vector189>:
.globl vector189
vector189:
  pushl $0
80105af4:	6a 00                	push   $0x0
  pushl $189
80105af6:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105afb:	e9 6d f4 ff ff       	jmp    80104f6d <alltraps>

80105b00 <vector190>:
.globl vector190
vector190:
  pushl $0
80105b00:	6a 00                	push   $0x0
  pushl $190
80105b02:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105b07:	e9 61 f4 ff ff       	jmp    80104f6d <alltraps>

80105b0c <vector191>:
.globl vector191
vector191:
  pushl $0
80105b0c:	6a 00                	push   $0x0
  pushl $191
80105b0e:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105b13:	e9 55 f4 ff ff       	jmp    80104f6d <alltraps>

80105b18 <vector192>:
.globl vector192
vector192:
  pushl $0
80105b18:	6a 00                	push   $0x0
  pushl $192
80105b1a:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105b1f:	e9 49 f4 ff ff       	jmp    80104f6d <alltraps>

80105b24 <vector193>:
.globl vector193
vector193:
  pushl $0
80105b24:	6a 00                	push   $0x0
  pushl $193
80105b26:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105b2b:	e9 3d f4 ff ff       	jmp    80104f6d <alltraps>

80105b30 <vector194>:
.globl vector194
vector194:
  pushl $0
80105b30:	6a 00                	push   $0x0
  pushl $194
80105b32:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105b37:	e9 31 f4 ff ff       	jmp    80104f6d <alltraps>

80105b3c <vector195>:
.globl vector195
vector195:
  pushl $0
80105b3c:	6a 00                	push   $0x0
  pushl $195
80105b3e:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105b43:	e9 25 f4 ff ff       	jmp    80104f6d <alltraps>

80105b48 <vector196>:
.globl vector196
vector196:
  pushl $0
80105b48:	6a 00                	push   $0x0
  pushl $196
80105b4a:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105b4f:	e9 19 f4 ff ff       	jmp    80104f6d <alltraps>

80105b54 <vector197>:
.globl vector197
vector197:
  pushl $0
80105b54:	6a 00                	push   $0x0
  pushl $197
80105b56:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105b5b:	e9 0d f4 ff ff       	jmp    80104f6d <alltraps>

80105b60 <vector198>:
.globl vector198
vector198:
  pushl $0
80105b60:	6a 00                	push   $0x0
  pushl $198
80105b62:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105b67:	e9 01 f4 ff ff       	jmp    80104f6d <alltraps>

80105b6c <vector199>:
.globl vector199
vector199:
  pushl $0
80105b6c:	6a 00                	push   $0x0
  pushl $199
80105b6e:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105b73:	e9 f5 f3 ff ff       	jmp    80104f6d <alltraps>

80105b78 <vector200>:
.globl vector200
vector200:
  pushl $0
80105b78:	6a 00                	push   $0x0
  pushl $200
80105b7a:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105b7f:	e9 e9 f3 ff ff       	jmp    80104f6d <alltraps>

80105b84 <vector201>:
.globl vector201
vector201:
  pushl $0
80105b84:	6a 00                	push   $0x0
  pushl $201
80105b86:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105b8b:	e9 dd f3 ff ff       	jmp    80104f6d <alltraps>

80105b90 <vector202>:
.globl vector202
vector202:
  pushl $0
80105b90:	6a 00                	push   $0x0
  pushl $202
80105b92:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105b97:	e9 d1 f3 ff ff       	jmp    80104f6d <alltraps>

80105b9c <vector203>:
.globl vector203
vector203:
  pushl $0
80105b9c:	6a 00                	push   $0x0
  pushl $203
80105b9e:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105ba3:	e9 c5 f3 ff ff       	jmp    80104f6d <alltraps>

80105ba8 <vector204>:
.globl vector204
vector204:
  pushl $0
80105ba8:	6a 00                	push   $0x0
  pushl $204
80105baa:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105baf:	e9 b9 f3 ff ff       	jmp    80104f6d <alltraps>

80105bb4 <vector205>:
.globl vector205
vector205:
  pushl $0
80105bb4:	6a 00                	push   $0x0
  pushl $205
80105bb6:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105bbb:	e9 ad f3 ff ff       	jmp    80104f6d <alltraps>

80105bc0 <vector206>:
.globl vector206
vector206:
  pushl $0
80105bc0:	6a 00                	push   $0x0
  pushl $206
80105bc2:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105bc7:	e9 a1 f3 ff ff       	jmp    80104f6d <alltraps>

80105bcc <vector207>:
.globl vector207
vector207:
  pushl $0
80105bcc:	6a 00                	push   $0x0
  pushl $207
80105bce:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105bd3:	e9 95 f3 ff ff       	jmp    80104f6d <alltraps>

80105bd8 <vector208>:
.globl vector208
vector208:
  pushl $0
80105bd8:	6a 00                	push   $0x0
  pushl $208
80105bda:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105bdf:	e9 89 f3 ff ff       	jmp    80104f6d <alltraps>

80105be4 <vector209>:
.globl vector209
vector209:
  pushl $0
80105be4:	6a 00                	push   $0x0
  pushl $209
80105be6:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105beb:	e9 7d f3 ff ff       	jmp    80104f6d <alltraps>

80105bf0 <vector210>:
.globl vector210
vector210:
  pushl $0
80105bf0:	6a 00                	push   $0x0
  pushl $210
80105bf2:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105bf7:	e9 71 f3 ff ff       	jmp    80104f6d <alltraps>

80105bfc <vector211>:
.globl vector211
vector211:
  pushl $0
80105bfc:	6a 00                	push   $0x0
  pushl $211
80105bfe:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105c03:	e9 65 f3 ff ff       	jmp    80104f6d <alltraps>

80105c08 <vector212>:
.globl vector212
vector212:
  pushl $0
80105c08:	6a 00                	push   $0x0
  pushl $212
80105c0a:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105c0f:	e9 59 f3 ff ff       	jmp    80104f6d <alltraps>

80105c14 <vector213>:
.globl vector213
vector213:
  pushl $0
80105c14:	6a 00                	push   $0x0
  pushl $213
80105c16:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105c1b:	e9 4d f3 ff ff       	jmp    80104f6d <alltraps>

80105c20 <vector214>:
.globl vector214
vector214:
  pushl $0
80105c20:	6a 00                	push   $0x0
  pushl $214
80105c22:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105c27:	e9 41 f3 ff ff       	jmp    80104f6d <alltraps>

80105c2c <vector215>:
.globl vector215
vector215:
  pushl $0
80105c2c:	6a 00                	push   $0x0
  pushl $215
80105c2e:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105c33:	e9 35 f3 ff ff       	jmp    80104f6d <alltraps>

80105c38 <vector216>:
.globl vector216
vector216:
  pushl $0
80105c38:	6a 00                	push   $0x0
  pushl $216
80105c3a:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105c3f:	e9 29 f3 ff ff       	jmp    80104f6d <alltraps>

80105c44 <vector217>:
.globl vector217
vector217:
  pushl $0
80105c44:	6a 00                	push   $0x0
  pushl $217
80105c46:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105c4b:	e9 1d f3 ff ff       	jmp    80104f6d <alltraps>

80105c50 <vector218>:
.globl vector218
vector218:
  pushl $0
80105c50:	6a 00                	push   $0x0
  pushl $218
80105c52:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105c57:	e9 11 f3 ff ff       	jmp    80104f6d <alltraps>

80105c5c <vector219>:
.globl vector219
vector219:
  pushl $0
80105c5c:	6a 00                	push   $0x0
  pushl $219
80105c5e:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105c63:	e9 05 f3 ff ff       	jmp    80104f6d <alltraps>

80105c68 <vector220>:
.globl vector220
vector220:
  pushl $0
80105c68:	6a 00                	push   $0x0
  pushl $220
80105c6a:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105c6f:	e9 f9 f2 ff ff       	jmp    80104f6d <alltraps>

80105c74 <vector221>:
.globl vector221
vector221:
  pushl $0
80105c74:	6a 00                	push   $0x0
  pushl $221
80105c76:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105c7b:	e9 ed f2 ff ff       	jmp    80104f6d <alltraps>

80105c80 <vector222>:
.globl vector222
vector222:
  pushl $0
80105c80:	6a 00                	push   $0x0
  pushl $222
80105c82:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105c87:	e9 e1 f2 ff ff       	jmp    80104f6d <alltraps>

80105c8c <vector223>:
.globl vector223
vector223:
  pushl $0
80105c8c:	6a 00                	push   $0x0
  pushl $223
80105c8e:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105c93:	e9 d5 f2 ff ff       	jmp    80104f6d <alltraps>

80105c98 <vector224>:
.globl vector224
vector224:
  pushl $0
80105c98:	6a 00                	push   $0x0
  pushl $224
80105c9a:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105c9f:	e9 c9 f2 ff ff       	jmp    80104f6d <alltraps>

80105ca4 <vector225>:
.globl vector225
vector225:
  pushl $0
80105ca4:	6a 00                	push   $0x0
  pushl $225
80105ca6:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105cab:	e9 bd f2 ff ff       	jmp    80104f6d <alltraps>

80105cb0 <vector226>:
.globl vector226
vector226:
  pushl $0
80105cb0:	6a 00                	push   $0x0
  pushl $226
80105cb2:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105cb7:	e9 b1 f2 ff ff       	jmp    80104f6d <alltraps>

80105cbc <vector227>:
.globl vector227
vector227:
  pushl $0
80105cbc:	6a 00                	push   $0x0
  pushl $227
80105cbe:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105cc3:	e9 a5 f2 ff ff       	jmp    80104f6d <alltraps>

80105cc8 <vector228>:
.globl vector228
vector228:
  pushl $0
80105cc8:	6a 00                	push   $0x0
  pushl $228
80105cca:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105ccf:	e9 99 f2 ff ff       	jmp    80104f6d <alltraps>

80105cd4 <vector229>:
.globl vector229
vector229:
  pushl $0
80105cd4:	6a 00                	push   $0x0
  pushl $229
80105cd6:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105cdb:	e9 8d f2 ff ff       	jmp    80104f6d <alltraps>

80105ce0 <vector230>:
.globl vector230
vector230:
  pushl $0
80105ce0:	6a 00                	push   $0x0
  pushl $230
80105ce2:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105ce7:	e9 81 f2 ff ff       	jmp    80104f6d <alltraps>

80105cec <vector231>:
.globl vector231
vector231:
  pushl $0
80105cec:	6a 00                	push   $0x0
  pushl $231
80105cee:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105cf3:	e9 75 f2 ff ff       	jmp    80104f6d <alltraps>

80105cf8 <vector232>:
.globl vector232
vector232:
  pushl $0
80105cf8:	6a 00                	push   $0x0
  pushl $232
80105cfa:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105cff:	e9 69 f2 ff ff       	jmp    80104f6d <alltraps>

80105d04 <vector233>:
.globl vector233
vector233:
  pushl $0
80105d04:	6a 00                	push   $0x0
  pushl $233
80105d06:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105d0b:	e9 5d f2 ff ff       	jmp    80104f6d <alltraps>

80105d10 <vector234>:
.globl vector234
vector234:
  pushl $0
80105d10:	6a 00                	push   $0x0
  pushl $234
80105d12:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105d17:	e9 51 f2 ff ff       	jmp    80104f6d <alltraps>

80105d1c <vector235>:
.globl vector235
vector235:
  pushl $0
80105d1c:	6a 00                	push   $0x0
  pushl $235
80105d1e:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105d23:	e9 45 f2 ff ff       	jmp    80104f6d <alltraps>

80105d28 <vector236>:
.globl vector236
vector236:
  pushl $0
80105d28:	6a 00                	push   $0x0
  pushl $236
80105d2a:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105d2f:	e9 39 f2 ff ff       	jmp    80104f6d <alltraps>

80105d34 <vector237>:
.globl vector237
vector237:
  pushl $0
80105d34:	6a 00                	push   $0x0
  pushl $237
80105d36:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105d3b:	e9 2d f2 ff ff       	jmp    80104f6d <alltraps>

80105d40 <vector238>:
.globl vector238
vector238:
  pushl $0
80105d40:	6a 00                	push   $0x0
  pushl $238
80105d42:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105d47:	e9 21 f2 ff ff       	jmp    80104f6d <alltraps>

80105d4c <vector239>:
.globl vector239
vector239:
  pushl $0
80105d4c:	6a 00                	push   $0x0
  pushl $239
80105d4e:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105d53:	e9 15 f2 ff ff       	jmp    80104f6d <alltraps>

80105d58 <vector240>:
.globl vector240
vector240:
  pushl $0
80105d58:	6a 00                	push   $0x0
  pushl $240
80105d5a:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105d5f:	e9 09 f2 ff ff       	jmp    80104f6d <alltraps>

80105d64 <vector241>:
.globl vector241
vector241:
  pushl $0
80105d64:	6a 00                	push   $0x0
  pushl $241
80105d66:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105d6b:	e9 fd f1 ff ff       	jmp    80104f6d <alltraps>

80105d70 <vector242>:
.globl vector242
vector242:
  pushl $0
80105d70:	6a 00                	push   $0x0
  pushl $242
80105d72:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105d77:	e9 f1 f1 ff ff       	jmp    80104f6d <alltraps>

80105d7c <vector243>:
.globl vector243
vector243:
  pushl $0
80105d7c:	6a 00                	push   $0x0
  pushl $243
80105d7e:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105d83:	e9 e5 f1 ff ff       	jmp    80104f6d <alltraps>

80105d88 <vector244>:
.globl vector244
vector244:
  pushl $0
80105d88:	6a 00                	push   $0x0
  pushl $244
80105d8a:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105d8f:	e9 d9 f1 ff ff       	jmp    80104f6d <alltraps>

80105d94 <vector245>:
.globl vector245
vector245:
  pushl $0
80105d94:	6a 00                	push   $0x0
  pushl $245
80105d96:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105d9b:	e9 cd f1 ff ff       	jmp    80104f6d <alltraps>

80105da0 <vector246>:
.globl vector246
vector246:
  pushl $0
80105da0:	6a 00                	push   $0x0
  pushl $246
80105da2:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105da7:	e9 c1 f1 ff ff       	jmp    80104f6d <alltraps>

80105dac <vector247>:
.globl vector247
vector247:
  pushl $0
80105dac:	6a 00                	push   $0x0
  pushl $247
80105dae:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105db3:	e9 b5 f1 ff ff       	jmp    80104f6d <alltraps>

80105db8 <vector248>:
.globl vector248
vector248:
  pushl $0
80105db8:	6a 00                	push   $0x0
  pushl $248
80105dba:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105dbf:	e9 a9 f1 ff ff       	jmp    80104f6d <alltraps>

80105dc4 <vector249>:
.globl vector249
vector249:
  pushl $0
80105dc4:	6a 00                	push   $0x0
  pushl $249
80105dc6:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105dcb:	e9 9d f1 ff ff       	jmp    80104f6d <alltraps>

80105dd0 <vector250>:
.globl vector250
vector250:
  pushl $0
80105dd0:	6a 00                	push   $0x0
  pushl $250
80105dd2:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105dd7:	e9 91 f1 ff ff       	jmp    80104f6d <alltraps>

80105ddc <vector251>:
.globl vector251
vector251:
  pushl $0
80105ddc:	6a 00                	push   $0x0
  pushl $251
80105dde:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105de3:	e9 85 f1 ff ff       	jmp    80104f6d <alltraps>

80105de8 <vector252>:
.globl vector252
vector252:
  pushl $0
80105de8:	6a 00                	push   $0x0
  pushl $252
80105dea:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105def:	e9 79 f1 ff ff       	jmp    80104f6d <alltraps>

80105df4 <vector253>:
.globl vector253
vector253:
  pushl $0
80105df4:	6a 00                	push   $0x0
  pushl $253
80105df6:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105dfb:	e9 6d f1 ff ff       	jmp    80104f6d <alltraps>

80105e00 <vector254>:
.globl vector254
vector254:
  pushl $0
80105e00:	6a 00                	push   $0x0
  pushl $254
80105e02:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105e07:	e9 61 f1 ff ff       	jmp    80104f6d <alltraps>

80105e0c <vector255>:
.globl vector255
vector255:
  pushl $0
80105e0c:	6a 00                	push   $0x0
  pushl $255
80105e0e:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105e13:	e9 55 f1 ff ff       	jmp    80104f6d <alltraps>

80105e18 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105e18:	55                   	push   %ebp
80105e19:	89 e5                	mov    %esp,%ebp
80105e1b:	57                   	push   %edi
80105e1c:	56                   	push   %esi
80105e1d:	53                   	push   %ebx
80105e1e:	83 ec 0c             	sub    $0xc,%esp
80105e21:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105e23:	c1 ea 16             	shr    $0x16,%edx
80105e26:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105e29:	8b 1f                	mov    (%edi),%ebx
80105e2b:	f6 c3 01             	test   $0x1,%bl
80105e2e:	74 22                	je     80105e52 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105e30:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105e36:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105e3c:	c1 ee 0c             	shr    $0xc,%esi
80105e3f:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105e45:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105e48:	89 d8                	mov    %ebx,%eax
80105e4a:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105e4d:	5b                   	pop    %ebx
80105e4e:	5e                   	pop    %esi
80105e4f:	5f                   	pop    %edi
80105e50:	5d                   	pop    %ebp
80105e51:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc2()) == 0)
80105e52:	85 c9                	test   %ecx,%ecx
80105e54:	74 2b                	je     80105e81 <walkpgdir+0x69>
80105e56:	e8 c6 c3 ff ff       	call   80102221 <kalloc2>
80105e5b:	89 c3                	mov    %eax,%ebx
80105e5d:	85 c0                	test   %eax,%eax
80105e5f:	74 e7                	je     80105e48 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105e61:	83 ec 04             	sub    $0x4,%esp
80105e64:	68 00 10 00 00       	push   $0x1000
80105e69:	6a 00                	push   $0x0
80105e6b:	50                   	push   %eax
80105e6c:	e8 fe df ff ff       	call   80103e6f <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105e71:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105e77:	83 c8 07             	or     $0x7,%eax
80105e7a:	89 07                	mov    %eax,(%edi)
80105e7c:	83 c4 10             	add    $0x10,%esp
80105e7f:	eb bb                	jmp    80105e3c <walkpgdir+0x24>
      return 0;
80105e81:	bb 00 00 00 00       	mov    $0x0,%ebx
80105e86:	eb c0                	jmp    80105e48 <walkpgdir+0x30>

80105e88 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105e88:	55                   	push   %ebp
80105e89:	89 e5                	mov    %esp,%ebp
80105e8b:	57                   	push   %edi
80105e8c:	56                   	push   %esi
80105e8d:	53                   	push   %ebx
80105e8e:	83 ec 1c             	sub    $0x1c,%esp
80105e91:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105e94:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80105e97:	89 d3                	mov    %edx,%ebx
80105e99:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105e9f:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105ea3:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105ea9:	b9 01 00 00 00       	mov    $0x1,%ecx
80105eae:	89 da                	mov    %ebx,%edx
80105eb0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105eb3:	e8 60 ff ff ff       	call   80105e18 <walkpgdir>
80105eb8:	85 c0                	test   %eax,%eax
80105eba:	74 2e                	je     80105eea <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105ebc:	f6 00 01             	testb  $0x1,(%eax)
80105ebf:	75 1c                	jne    80105edd <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105ec1:	89 f2                	mov    %esi,%edx
80105ec3:	0b 55 0c             	or     0xc(%ebp),%edx
80105ec6:	83 ca 01             	or     $0x1,%edx
80105ec9:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105ecb:	39 fb                	cmp    %edi,%ebx
80105ecd:	74 28                	je     80105ef7 <mappages+0x6f>
      break;
    a += PGSIZE;
80105ecf:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105ed5:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105edb:	eb cc                	jmp    80105ea9 <mappages+0x21>
      panic("remap");
80105edd:	83 ec 0c             	sub    $0xc,%esp
80105ee0:	68 ac 6f 10 80       	push   $0x80106fac
80105ee5:	e8 5e a4 ff ff       	call   80100348 <panic>
      return -1;
80105eea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105eef:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105ef2:	5b                   	pop    %ebx
80105ef3:	5e                   	pop    %esi
80105ef4:	5f                   	pop    %edi
80105ef5:	5d                   	pop    %ebp
80105ef6:	c3                   	ret    
  return 0;
80105ef7:	b8 00 00 00 00       	mov    $0x0,%eax
80105efc:	eb f1                	jmp    80105eef <mappages+0x67>

80105efe <seginit>:
{
80105efe:	55                   	push   %ebp
80105eff:	89 e5                	mov    %esp,%ebp
80105f01:	53                   	push   %ebx
80105f02:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105f05:	e8 80 d4 ff ff       	call   8010338a <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105f0a:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105f10:	66 c7 80 18 28 15 80 	movw   $0xffff,-0x7fead7e8(%eax)
80105f17:	ff ff 
80105f19:	66 c7 80 1a 28 15 80 	movw   $0x0,-0x7fead7e6(%eax)
80105f20:	00 00 
80105f22:	c6 80 1c 28 15 80 00 	movb   $0x0,-0x7fead7e4(%eax)
80105f29:	0f b6 88 1d 28 15 80 	movzbl -0x7fead7e3(%eax),%ecx
80105f30:	83 e1 f0             	and    $0xfffffff0,%ecx
80105f33:	83 c9 1a             	or     $0x1a,%ecx
80105f36:	83 e1 9f             	and    $0xffffff9f,%ecx
80105f39:	83 c9 80             	or     $0xffffff80,%ecx
80105f3c:	88 88 1d 28 15 80    	mov    %cl,-0x7fead7e3(%eax)
80105f42:	0f b6 88 1e 28 15 80 	movzbl -0x7fead7e2(%eax),%ecx
80105f49:	83 c9 0f             	or     $0xf,%ecx
80105f4c:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f4f:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f52:	88 88 1e 28 15 80    	mov    %cl,-0x7fead7e2(%eax)
80105f58:	c6 80 1f 28 15 80 00 	movb   $0x0,-0x7fead7e1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105f5f:	66 c7 80 20 28 15 80 	movw   $0xffff,-0x7fead7e0(%eax)
80105f66:	ff ff 
80105f68:	66 c7 80 22 28 15 80 	movw   $0x0,-0x7fead7de(%eax)
80105f6f:	00 00 
80105f71:	c6 80 24 28 15 80 00 	movb   $0x0,-0x7fead7dc(%eax)
80105f78:	0f b6 88 25 28 15 80 	movzbl -0x7fead7db(%eax),%ecx
80105f7f:	83 e1 f0             	and    $0xfffffff0,%ecx
80105f82:	83 c9 12             	or     $0x12,%ecx
80105f85:	83 e1 9f             	and    $0xffffff9f,%ecx
80105f88:	83 c9 80             	or     $0xffffff80,%ecx
80105f8b:	88 88 25 28 15 80    	mov    %cl,-0x7fead7db(%eax)
80105f91:	0f b6 88 26 28 15 80 	movzbl -0x7fead7da(%eax),%ecx
80105f98:	83 c9 0f             	or     $0xf,%ecx
80105f9b:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f9e:	83 c9 c0             	or     $0xffffffc0,%ecx
80105fa1:	88 88 26 28 15 80    	mov    %cl,-0x7fead7da(%eax)
80105fa7:	c6 80 27 28 15 80 00 	movb   $0x0,-0x7fead7d9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105fae:	66 c7 80 28 28 15 80 	movw   $0xffff,-0x7fead7d8(%eax)
80105fb5:	ff ff 
80105fb7:	66 c7 80 2a 28 15 80 	movw   $0x0,-0x7fead7d6(%eax)
80105fbe:	00 00 
80105fc0:	c6 80 2c 28 15 80 00 	movb   $0x0,-0x7fead7d4(%eax)
80105fc7:	c6 80 2d 28 15 80 fa 	movb   $0xfa,-0x7fead7d3(%eax)
80105fce:	0f b6 88 2e 28 15 80 	movzbl -0x7fead7d2(%eax),%ecx
80105fd5:	83 c9 0f             	or     $0xf,%ecx
80105fd8:	83 e1 cf             	and    $0xffffffcf,%ecx
80105fdb:	83 c9 c0             	or     $0xffffffc0,%ecx
80105fde:	88 88 2e 28 15 80    	mov    %cl,-0x7fead7d2(%eax)
80105fe4:	c6 80 2f 28 15 80 00 	movb   $0x0,-0x7fead7d1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105feb:	66 c7 80 30 28 15 80 	movw   $0xffff,-0x7fead7d0(%eax)
80105ff2:	ff ff 
80105ff4:	66 c7 80 32 28 15 80 	movw   $0x0,-0x7fead7ce(%eax)
80105ffb:	00 00 
80105ffd:	c6 80 34 28 15 80 00 	movb   $0x0,-0x7fead7cc(%eax)
80106004:	c6 80 35 28 15 80 f2 	movb   $0xf2,-0x7fead7cb(%eax)
8010600b:	0f b6 88 36 28 15 80 	movzbl -0x7fead7ca(%eax),%ecx
80106012:	83 c9 0f             	or     $0xf,%ecx
80106015:	83 e1 cf             	and    $0xffffffcf,%ecx
80106018:	83 c9 c0             	or     $0xffffffc0,%ecx
8010601b:	88 88 36 28 15 80    	mov    %cl,-0x7fead7ca(%eax)
80106021:	c6 80 37 28 15 80 00 	movb   $0x0,-0x7fead7c9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80106028:	05 10 28 15 80       	add    $0x80152810,%eax
  pd[0] = size-1;
8010602d:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80106033:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80106037:	c1 e8 10             	shr    $0x10,%eax
8010603a:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
8010603e:	8d 45 f2             	lea    -0xe(%ebp),%eax
80106041:	0f 01 10             	lgdtl  (%eax)
}
80106044:	83 c4 14             	add    $0x14,%esp
80106047:	5b                   	pop    %ebx
80106048:	5d                   	pop    %ebp
80106049:	c3                   	ret    

8010604a <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
8010604a:	55                   	push   %ebp
8010604b:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
8010604d:	a1 c4 54 15 80       	mov    0x801554c4,%eax
80106052:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106057:	0f 22 d8             	mov    %eax,%cr3
}
8010605a:	5d                   	pop    %ebp
8010605b:	c3                   	ret    

8010605c <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
8010605c:	55                   	push   %ebp
8010605d:	89 e5                	mov    %esp,%ebp
8010605f:	57                   	push   %edi
80106060:	56                   	push   %esi
80106061:	53                   	push   %ebx
80106062:	83 ec 1c             	sub    $0x1c,%esp
80106065:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80106068:	85 f6                	test   %esi,%esi
8010606a:	0f 84 dd 00 00 00    	je     8010614d <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80106070:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80106074:	0f 84 e0 00 00 00    	je     8010615a <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
8010607a:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
8010607e:	0f 84 e3 00 00 00    	je     80106167 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80106084:	e8 5d dc ff ff       	call   80103ce6 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80106089:	e8 a0 d2 ff ff       	call   8010332e <mycpu>
8010608e:	89 c3                	mov    %eax,%ebx
80106090:	e8 99 d2 ff ff       	call   8010332e <mycpu>
80106095:	8d 78 08             	lea    0x8(%eax),%edi
80106098:	e8 91 d2 ff ff       	call   8010332e <mycpu>
8010609d:	83 c0 08             	add    $0x8,%eax
801060a0:	c1 e8 10             	shr    $0x10,%eax
801060a3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801060a6:	e8 83 d2 ff ff       	call   8010332e <mycpu>
801060ab:	83 c0 08             	add    $0x8,%eax
801060ae:	c1 e8 18             	shr    $0x18,%eax
801060b1:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
801060b8:	67 00 
801060ba:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
801060c1:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
801060c5:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
801060cb:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
801060d2:	83 e2 f0             	and    $0xfffffff0,%edx
801060d5:	83 ca 19             	or     $0x19,%edx
801060d8:	83 e2 9f             	and    $0xffffff9f,%edx
801060db:	83 ca 80             	or     $0xffffff80,%edx
801060de:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
801060e4:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
801060eb:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
801060f1:	e8 38 d2 ff ff       	call   8010332e <mycpu>
801060f6:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801060fd:	83 e2 ef             	and    $0xffffffef,%edx
80106100:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80106106:	e8 23 d2 ff ff       	call   8010332e <mycpu>
8010610b:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80106111:	8b 5e 08             	mov    0x8(%esi),%ebx
80106114:	e8 15 d2 ff ff       	call   8010332e <mycpu>
80106119:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010611f:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80106122:	e8 07 d2 ff ff       	call   8010332e <mycpu>
80106127:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
8010612d:	b8 28 00 00 00       	mov    $0x28,%eax
80106132:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80106135:	8b 46 04             	mov    0x4(%esi),%eax
80106138:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010613d:	0f 22 d8             	mov    %eax,%cr3
  popcli();
80106140:	e8 de db ff ff       	call   80103d23 <popcli>
}
80106145:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106148:	5b                   	pop    %ebx
80106149:	5e                   	pop    %esi
8010614a:	5f                   	pop    %edi
8010614b:	5d                   	pop    %ebp
8010614c:	c3                   	ret    
    panic("switchuvm: no process");
8010614d:	83 ec 0c             	sub    $0xc,%esp
80106150:	68 b2 6f 10 80       	push   $0x80106fb2
80106155:	e8 ee a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
8010615a:	83 ec 0c             	sub    $0xc,%esp
8010615d:	68 c8 6f 10 80       	push   $0x80106fc8
80106162:	e8 e1 a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80106167:	83 ec 0c             	sub    $0xc,%esp
8010616a:	68 dd 6f 10 80       	push   $0x80106fdd
8010616f:	e8 d4 a1 ff ff       	call   80100348 <panic>

80106174 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80106174:	55                   	push   %ebp
80106175:	89 e5                	mov    %esp,%ebp
80106177:	56                   	push   %esi
80106178:	53                   	push   %ebx
80106179:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
8010617c:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106182:	77 4c                	ja     801061d0 <inituvm+0x5c>
    panic("inituvm: more than a page");
  // ignore this call to kalloc. Mark as UNKNOWN
  mem = kalloc2();
80106184:	e8 98 c0 ff ff       	call   80102221 <kalloc2>
80106189:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
8010618b:	83 ec 04             	sub    $0x4,%esp
8010618e:	68 00 10 00 00       	push   $0x1000
80106193:	6a 00                	push   $0x0
80106195:	50                   	push   %eax
80106196:	e8 d4 dc ff ff       	call   80103e6f <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
8010619b:	83 c4 08             	add    $0x8,%esp
8010619e:	6a 06                	push   $0x6
801061a0:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801061a6:	50                   	push   %eax
801061a7:	b9 00 10 00 00       	mov    $0x1000,%ecx
801061ac:	ba 00 00 00 00       	mov    $0x0,%edx
801061b1:	8b 45 08             	mov    0x8(%ebp),%eax
801061b4:	e8 cf fc ff ff       	call   80105e88 <mappages>
  memmove(mem, init, sz);
801061b9:	83 c4 0c             	add    $0xc,%esp
801061bc:	56                   	push   %esi
801061bd:	ff 75 0c             	pushl  0xc(%ebp)
801061c0:	53                   	push   %ebx
801061c1:	e8 24 dd ff ff       	call   80103eea <memmove>
}
801061c6:	83 c4 10             	add    $0x10,%esp
801061c9:	8d 65 f8             	lea    -0x8(%ebp),%esp
801061cc:	5b                   	pop    %ebx
801061cd:	5e                   	pop    %esi
801061ce:	5d                   	pop    %ebp
801061cf:	c3                   	ret    
    panic("inituvm: more than a page");
801061d0:	83 ec 0c             	sub    $0xc,%esp
801061d3:	68 f1 6f 10 80       	push   $0x80106ff1
801061d8:	e8 6b a1 ff ff       	call   80100348 <panic>

801061dd <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801061dd:	55                   	push   %ebp
801061de:	89 e5                	mov    %esp,%ebp
801061e0:	57                   	push   %edi
801061e1:	56                   	push   %esi
801061e2:	53                   	push   %ebx
801061e3:	83 ec 0c             	sub    $0xc,%esp
801061e6:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801061e9:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
801061f0:	75 07                	jne    801061f9 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801061f2:	bb 00 00 00 00       	mov    $0x0,%ebx
801061f7:	eb 3c                	jmp    80106235 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
801061f9:	83 ec 0c             	sub    $0xc,%esp
801061fc:	68 ac 70 10 80       	push   $0x801070ac
80106201:	e8 42 a1 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
80106206:	83 ec 0c             	sub    $0xc,%esp
80106209:	68 0b 70 10 80       	push   $0x8010700b
8010620e:	e8 35 a1 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80106213:	05 00 00 00 80       	add    $0x80000000,%eax
80106218:	56                   	push   %esi
80106219:	89 da                	mov    %ebx,%edx
8010621b:	03 55 14             	add    0x14(%ebp),%edx
8010621e:	52                   	push   %edx
8010621f:	50                   	push   %eax
80106220:	ff 75 10             	pushl  0x10(%ebp)
80106223:	e8 4b b5 ff ff       	call   80101773 <readi>
80106228:	83 c4 10             	add    $0x10,%esp
8010622b:	39 f0                	cmp    %esi,%eax
8010622d:	75 47                	jne    80106276 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
8010622f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106235:	39 fb                	cmp    %edi,%ebx
80106237:	73 30                	jae    80106269 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80106239:	89 da                	mov    %ebx,%edx
8010623b:	03 55 0c             	add    0xc(%ebp),%edx
8010623e:	b9 00 00 00 00       	mov    $0x0,%ecx
80106243:	8b 45 08             	mov    0x8(%ebp),%eax
80106246:	e8 cd fb ff ff       	call   80105e18 <walkpgdir>
8010624b:	85 c0                	test   %eax,%eax
8010624d:	74 b7                	je     80106206 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
8010624f:	8b 00                	mov    (%eax),%eax
80106251:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
80106256:	89 fe                	mov    %edi,%esi
80106258:	29 de                	sub    %ebx,%esi
8010625a:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106260:	76 b1                	jbe    80106213 <loaduvm+0x36>
      n = PGSIZE;
80106262:	be 00 10 00 00       	mov    $0x1000,%esi
80106267:	eb aa                	jmp    80106213 <loaduvm+0x36>
      return -1;
  }
  return 0;
80106269:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010626e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106271:	5b                   	pop    %ebx
80106272:	5e                   	pop    %esi
80106273:	5f                   	pop    %edi
80106274:	5d                   	pop    %ebp
80106275:	c3                   	ret    
      return -1;
80106276:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010627b:	eb f1                	jmp    8010626e <loaduvm+0x91>

8010627d <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010627d:	55                   	push   %ebp
8010627e:	89 e5                	mov    %esp,%ebp
80106280:	57                   	push   %edi
80106281:	56                   	push   %esi
80106282:	53                   	push   %ebx
80106283:	83 ec 0c             	sub    $0xc,%esp
80106286:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80106289:	39 7d 10             	cmp    %edi,0x10(%ebp)
8010628c:	73 11                	jae    8010629f <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
8010628e:	8b 45 10             	mov    0x10(%ebp),%eax
80106291:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106297:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010629d:	eb 19                	jmp    801062b8 <deallocuvm+0x3b>
    return oldsz;
8010629f:	89 f8                	mov    %edi,%eax
801062a1:	eb 64                	jmp    80106307 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
801062a3:	c1 eb 16             	shr    $0x16,%ebx
801062a6:	83 c3 01             	add    $0x1,%ebx
801062a9:	c1 e3 16             	shl    $0x16,%ebx
801062ac:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801062b2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801062b8:	39 fb                	cmp    %edi,%ebx
801062ba:	73 48                	jae    80106304 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
801062bc:	b9 00 00 00 00       	mov    $0x0,%ecx
801062c1:	89 da                	mov    %ebx,%edx
801062c3:	8b 45 08             	mov    0x8(%ebp),%eax
801062c6:	e8 4d fb ff ff       	call   80105e18 <walkpgdir>
801062cb:	89 c6                	mov    %eax,%esi
    if(!pte)
801062cd:	85 c0                	test   %eax,%eax
801062cf:	74 d2                	je     801062a3 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
801062d1:	8b 00                	mov    (%eax),%eax
801062d3:	a8 01                	test   $0x1,%al
801062d5:	74 db                	je     801062b2 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
801062d7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801062dc:	74 19                	je     801062f7 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
801062de:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801062e3:	83 ec 0c             	sub    $0xc,%esp
801062e6:	50                   	push   %eax
801062e7:	e8 c2 bc ff ff       	call   80101fae <kfree>
      *pte = 0;
801062ec:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
801062f2:	83 c4 10             	add    $0x10,%esp
801062f5:	eb bb                	jmp    801062b2 <deallocuvm+0x35>
        panic("kfree");
801062f7:	83 ec 0c             	sub    $0xc,%esp
801062fa:	68 46 69 10 80       	push   $0x80106946
801062ff:	e8 44 a0 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
80106304:	8b 45 10             	mov    0x10(%ebp),%eax
}
80106307:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010630a:	5b                   	pop    %ebx
8010630b:	5e                   	pop    %esi
8010630c:	5f                   	pop    %edi
8010630d:	5d                   	pop    %ebp
8010630e:	c3                   	ret    

8010630f <allocuvm>:
{
8010630f:	55                   	push   %ebp
80106310:	89 e5                	mov    %esp,%ebp
80106312:	57                   	push   %edi
80106313:	56                   	push   %esi
80106314:	53                   	push   %ebx
80106315:	83 ec 1c             	sub    $0x1c,%esp
80106318:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
8010631b:	89 7d e4             	mov    %edi,-0x1c(%ebp)
8010631e:	85 ff                	test   %edi,%edi
80106320:	0f 88 e0 00 00 00    	js     80106406 <allocuvm+0xf7>
  if(newsz < oldsz)
80106326:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106329:	73 11                	jae    8010633c <allocuvm+0x2d>
    return oldsz;
8010632b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010632e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}
80106331:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106334:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106337:	5b                   	pop    %ebx
80106338:	5e                   	pop    %esi
80106339:	5f                   	pop    %edi
8010633a:	5d                   	pop    %ebp
8010633b:	c3                   	ret    
  a = PGROUNDUP(oldsz);
8010633c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010633f:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106345:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  int pid = myproc()->pid;
8010634b:	e8 55 d0 ff ff       	call   801033a5 <myproc>
80106350:	8b 40 10             	mov    0x10(%eax),%eax
80106353:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(; a < newsz; a += PGSIZE){
80106356:	39 fb                	cmp    %edi,%ebx
80106358:	73 d7                	jae    80106331 <allocuvm+0x22>
    mem = kalloc(pid);
8010635a:	83 ec 0c             	sub    $0xc,%esp
8010635d:	ff 75 e0             	pushl  -0x20(%ebp)
80106360:	e8 39 be ff ff       	call   8010219e <kalloc>
80106365:	89 c6                	mov    %eax,%esi
    if(mem == 0){
80106367:	83 c4 10             	add    $0x10,%esp
8010636a:	85 c0                	test   %eax,%eax
8010636c:	74 3a                	je     801063a8 <allocuvm+0x99>
    memset(mem, 0, PGSIZE);
8010636e:	83 ec 04             	sub    $0x4,%esp
80106371:	68 00 10 00 00       	push   $0x1000
80106376:	6a 00                	push   $0x0
80106378:	50                   	push   %eax
80106379:	e8 f1 da ff ff       	call   80103e6f <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
8010637e:	83 c4 08             	add    $0x8,%esp
80106381:	6a 06                	push   $0x6
80106383:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
80106389:	50                   	push   %eax
8010638a:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010638f:	89 da                	mov    %ebx,%edx
80106391:	8b 45 08             	mov    0x8(%ebp),%eax
80106394:	e8 ef fa ff ff       	call   80105e88 <mappages>
80106399:	83 c4 10             	add    $0x10,%esp
8010639c:	85 c0                	test   %eax,%eax
8010639e:	78 33                	js     801063d3 <allocuvm+0xc4>
  for(; a < newsz; a += PGSIZE){
801063a0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801063a6:	eb ae                	jmp    80106356 <allocuvm+0x47>
      cprintf("allocuvm out of memory\n");
801063a8:	83 ec 0c             	sub    $0xc,%esp
801063ab:	68 29 70 10 80       	push   $0x80107029
801063b0:	e8 56 a2 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801063b5:	83 c4 0c             	add    $0xc,%esp
801063b8:	ff 75 0c             	pushl  0xc(%ebp)
801063bb:	57                   	push   %edi
801063bc:	ff 75 08             	pushl  0x8(%ebp)
801063bf:	e8 b9 fe ff ff       	call   8010627d <deallocuvm>
      return 0;
801063c4:	83 c4 10             	add    $0x10,%esp
801063c7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801063ce:	e9 5e ff ff ff       	jmp    80106331 <allocuvm+0x22>
      cprintf("allocuvm out of memory (2)\n");
801063d3:	83 ec 0c             	sub    $0xc,%esp
801063d6:	68 41 70 10 80       	push   $0x80107041
801063db:	e8 2b a2 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801063e0:	83 c4 0c             	add    $0xc,%esp
801063e3:	ff 75 0c             	pushl  0xc(%ebp)
801063e6:	57                   	push   %edi
801063e7:	ff 75 08             	pushl  0x8(%ebp)
801063ea:	e8 8e fe ff ff       	call   8010627d <deallocuvm>
      kfree(mem);
801063ef:	89 34 24             	mov    %esi,(%esp)
801063f2:	e8 b7 bb ff ff       	call   80101fae <kfree>
      return 0;
801063f7:	83 c4 10             	add    $0x10,%esp
801063fa:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106401:	e9 2b ff ff ff       	jmp    80106331 <allocuvm+0x22>
    return 0;
80106406:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010640d:	e9 1f ff ff ff       	jmp    80106331 <allocuvm+0x22>

80106412 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80106412:	55                   	push   %ebp
80106413:	89 e5                	mov    %esp,%ebp
80106415:	56                   	push   %esi
80106416:	53                   	push   %ebx
80106417:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
8010641a:	85 f6                	test   %esi,%esi
8010641c:	74 1a                	je     80106438 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
8010641e:	83 ec 04             	sub    $0x4,%esp
80106421:	6a 00                	push   $0x0
80106423:	68 00 00 00 80       	push   $0x80000000
80106428:	56                   	push   %esi
80106429:	e8 4f fe ff ff       	call   8010627d <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
8010642e:	83 c4 10             	add    $0x10,%esp
80106431:	bb 00 00 00 00       	mov    $0x0,%ebx
80106436:	eb 10                	jmp    80106448 <freevm+0x36>
    panic("freevm: no pgdir");
80106438:	83 ec 0c             	sub    $0xc,%esp
8010643b:	68 5d 70 10 80       	push   $0x8010705d
80106440:	e8 03 9f ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
80106445:	83 c3 01             	add    $0x1,%ebx
80106448:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
8010644e:	77 1f                	ja     8010646f <freevm+0x5d>
    if(pgdir[i] & PTE_P){
80106450:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
80106453:	a8 01                	test   $0x1,%al
80106455:	74 ee                	je     80106445 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
80106457:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010645c:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106461:	83 ec 0c             	sub    $0xc,%esp
80106464:	50                   	push   %eax
80106465:	e8 44 bb ff ff       	call   80101fae <kfree>
8010646a:	83 c4 10             	add    $0x10,%esp
8010646d:	eb d6                	jmp    80106445 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
8010646f:	83 ec 0c             	sub    $0xc,%esp
80106472:	56                   	push   %esi
80106473:	e8 36 bb ff ff       	call   80101fae <kfree>
}
80106478:	83 c4 10             	add    $0x10,%esp
8010647b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010647e:	5b                   	pop    %ebx
8010647f:	5e                   	pop    %esi
80106480:	5d                   	pop    %ebp
80106481:	c3                   	ret    

80106482 <setupkvm>:
{
80106482:	55                   	push   %ebp
80106483:	89 e5                	mov    %esp,%ebp
80106485:	56                   	push   %esi
80106486:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc2()) == 0)
80106487:	e8 95 bd ff ff       	call   80102221 <kalloc2>
8010648c:	89 c6                	mov    %eax,%esi
8010648e:	85 c0                	test   %eax,%eax
80106490:	74 55                	je     801064e7 <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
80106492:	83 ec 04             	sub    $0x4,%esp
80106495:	68 00 10 00 00       	push   $0x1000
8010649a:	6a 00                	push   $0x0
8010649c:	50                   	push   %eax
8010649d:	e8 cd d9 ff ff       	call   80103e6f <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801064a2:	83 c4 10             	add    $0x10,%esp
801064a5:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
801064aa:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
801064b0:	73 35                	jae    801064e7 <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
801064b2:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
801064b5:	8b 4b 08             	mov    0x8(%ebx),%ecx
801064b8:	29 c1                	sub    %eax,%ecx
801064ba:	83 ec 08             	sub    $0x8,%esp
801064bd:	ff 73 0c             	pushl  0xc(%ebx)
801064c0:	50                   	push   %eax
801064c1:	8b 13                	mov    (%ebx),%edx
801064c3:	89 f0                	mov    %esi,%eax
801064c5:	e8 be f9 ff ff       	call   80105e88 <mappages>
801064ca:	83 c4 10             	add    $0x10,%esp
801064cd:	85 c0                	test   %eax,%eax
801064cf:	78 05                	js     801064d6 <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801064d1:	83 c3 10             	add    $0x10,%ebx
801064d4:	eb d4                	jmp    801064aa <setupkvm+0x28>
      freevm(pgdir);
801064d6:	83 ec 0c             	sub    $0xc,%esp
801064d9:	56                   	push   %esi
801064da:	e8 33 ff ff ff       	call   80106412 <freevm>
      return 0;
801064df:	83 c4 10             	add    $0x10,%esp
801064e2:	be 00 00 00 00       	mov    $0x0,%esi
}
801064e7:	89 f0                	mov    %esi,%eax
801064e9:	8d 65 f8             	lea    -0x8(%ebp),%esp
801064ec:	5b                   	pop    %ebx
801064ed:	5e                   	pop    %esi
801064ee:	5d                   	pop    %ebp
801064ef:	c3                   	ret    

801064f0 <kvmalloc>:
{
801064f0:	55                   	push   %ebp
801064f1:	89 e5                	mov    %esp,%ebp
801064f3:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801064f6:	e8 87 ff ff ff       	call   80106482 <setupkvm>
801064fb:	a3 c4 54 15 80       	mov    %eax,0x801554c4
  switchkvm();
80106500:	e8 45 fb ff ff       	call   8010604a <switchkvm>
}
80106505:	c9                   	leave  
80106506:	c3                   	ret    

80106507 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106507:	55                   	push   %ebp
80106508:	89 e5                	mov    %esp,%ebp
8010650a:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010650d:	b9 00 00 00 00       	mov    $0x0,%ecx
80106512:	8b 55 0c             	mov    0xc(%ebp),%edx
80106515:	8b 45 08             	mov    0x8(%ebp),%eax
80106518:	e8 fb f8 ff ff       	call   80105e18 <walkpgdir>
  if(pte == 0)
8010651d:	85 c0                	test   %eax,%eax
8010651f:	74 05                	je     80106526 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
80106521:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
80106524:	c9                   	leave  
80106525:	c3                   	ret    
    panic("clearpteu");
80106526:	83 ec 0c             	sub    $0xc,%esp
80106529:	68 6e 70 10 80       	push   $0x8010706e
8010652e:	e8 15 9e ff ff       	call   80100348 <panic>

80106533 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80106533:	55                   	push   %ebp
80106534:	89 e5                	mov    %esp,%ebp
80106536:	57                   	push   %edi
80106537:	56                   	push   %esi
80106538:	53                   	push   %ebx
80106539:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
8010653c:	e8 41 ff ff ff       	call   80106482 <setupkvm>
80106541:	89 45 dc             	mov    %eax,-0x24(%ebp)
80106544:	85 c0                	test   %eax,%eax
80106546:	0f 84 d2 00 00 00    	je     8010661e <copyuvm+0xeb>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010654c:	bf 00 00 00 00       	mov    $0x0,%edi
80106551:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106554:	0f 83 c4 00 00 00    	jae    8010661e <copyuvm+0xeb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010655a:	89 7d e4             	mov    %edi,-0x1c(%ebp)
8010655d:	b9 00 00 00 00       	mov    $0x0,%ecx
80106562:	89 fa                	mov    %edi,%edx
80106564:	8b 45 08             	mov    0x8(%ebp),%eax
80106567:	e8 ac f8 ff ff       	call   80105e18 <walkpgdir>
8010656c:	85 c0                	test   %eax,%eax
8010656e:	74 73                	je     801065e3 <copyuvm+0xb0>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
80106570:	8b 00                	mov    (%eax),%eax
80106572:	a8 01                	test   $0x1,%al
80106574:	74 7a                	je     801065f0 <copyuvm+0xbd>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
80106576:	89 c6                	mov    %eax,%esi
80106578:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
8010657e:	25 ff 0f 00 00       	and    $0xfff,%eax
80106583:	89 45 e0             	mov    %eax,-0x20(%ebp)
    // manipulate this call to kalloc. Need to pass the pid?
    int pid = myproc()->pid;
80106586:	e8 1a ce ff ff       	call   801033a5 <myproc>

    if((mem = kalloc(pid)) == 0)
8010658b:	83 ec 0c             	sub    $0xc,%esp
8010658e:	ff 70 10             	pushl  0x10(%eax)
80106591:	e8 08 bc ff ff       	call   8010219e <kalloc>
80106596:	89 c3                	mov    %eax,%ebx
80106598:	83 c4 10             	add    $0x10,%esp
8010659b:	85 c0                	test   %eax,%eax
8010659d:	74 6a                	je     80106609 <copyuvm+0xd6>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
8010659f:	81 c6 00 00 00 80    	add    $0x80000000,%esi
801065a5:	83 ec 04             	sub    $0x4,%esp
801065a8:	68 00 10 00 00       	push   $0x1000
801065ad:	56                   	push   %esi
801065ae:	50                   	push   %eax
801065af:	e8 36 d9 ff ff       	call   80103eea <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
801065b4:	83 c4 08             	add    $0x8,%esp
801065b7:	ff 75 e0             	pushl  -0x20(%ebp)
801065ba:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801065c0:	50                   	push   %eax
801065c1:	b9 00 10 00 00       	mov    $0x1000,%ecx
801065c6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801065c9:	8b 45 dc             	mov    -0x24(%ebp),%eax
801065cc:	e8 b7 f8 ff ff       	call   80105e88 <mappages>
801065d1:	83 c4 10             	add    $0x10,%esp
801065d4:	85 c0                	test   %eax,%eax
801065d6:	78 25                	js     801065fd <copyuvm+0xca>
  for(i = 0; i < sz; i += PGSIZE){
801065d8:	81 c7 00 10 00 00    	add    $0x1000,%edi
801065de:	e9 6e ff ff ff       	jmp    80106551 <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
801065e3:	83 ec 0c             	sub    $0xc,%esp
801065e6:	68 78 70 10 80       	push   $0x80107078
801065eb:	e8 58 9d ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
801065f0:	83 ec 0c             	sub    $0xc,%esp
801065f3:	68 92 70 10 80       	push   $0x80107092
801065f8:	e8 4b 9d ff ff       	call   80100348 <panic>
      kfree(mem);
801065fd:	83 ec 0c             	sub    $0xc,%esp
80106600:	53                   	push   %ebx
80106601:	e8 a8 b9 ff ff       	call   80101fae <kfree>
      goto bad;
80106606:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106609:	83 ec 0c             	sub    $0xc,%esp
8010660c:	ff 75 dc             	pushl  -0x24(%ebp)
8010660f:	e8 fe fd ff ff       	call   80106412 <freevm>
  return 0;
80106614:	83 c4 10             	add    $0x10,%esp
80106617:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
8010661e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106621:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106624:	5b                   	pop    %ebx
80106625:	5e                   	pop    %esi
80106626:	5f                   	pop    %edi
80106627:	5d                   	pop    %ebp
80106628:	c3                   	ret    

80106629 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106629:	55                   	push   %ebp
8010662a:	89 e5                	mov    %esp,%ebp
8010662c:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010662f:	b9 00 00 00 00       	mov    $0x0,%ecx
80106634:	8b 55 0c             	mov    0xc(%ebp),%edx
80106637:	8b 45 08             	mov    0x8(%ebp),%eax
8010663a:	e8 d9 f7 ff ff       	call   80105e18 <walkpgdir>
  if((*pte & PTE_P) == 0)
8010663f:	8b 00                	mov    (%eax),%eax
80106641:	a8 01                	test   $0x1,%al
80106643:	74 10                	je     80106655 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
80106645:	a8 04                	test   $0x4,%al
80106647:	74 13                	je     8010665c <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106649:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010664e:	05 00 00 00 80       	add    $0x80000000,%eax
}
80106653:	c9                   	leave  
80106654:	c3                   	ret    
    return 0;
80106655:	b8 00 00 00 00       	mov    $0x0,%eax
8010665a:	eb f7                	jmp    80106653 <uva2ka+0x2a>
    return 0;
8010665c:	b8 00 00 00 00       	mov    $0x0,%eax
80106661:	eb f0                	jmp    80106653 <uva2ka+0x2a>

80106663 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80106663:	55                   	push   %ebp
80106664:	89 e5                	mov    %esp,%ebp
80106666:	57                   	push   %edi
80106667:	56                   	push   %esi
80106668:	53                   	push   %ebx
80106669:	83 ec 0c             	sub    $0xc,%esp
8010666c:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010666f:	eb 25                	jmp    80106696 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
80106671:	8b 55 0c             	mov    0xc(%ebp),%edx
80106674:	29 f2                	sub    %esi,%edx
80106676:	01 d0                	add    %edx,%eax
80106678:	83 ec 04             	sub    $0x4,%esp
8010667b:	53                   	push   %ebx
8010667c:	ff 75 10             	pushl  0x10(%ebp)
8010667f:	50                   	push   %eax
80106680:	e8 65 d8 ff ff       	call   80103eea <memmove>
    len -= n;
80106685:	29 df                	sub    %ebx,%edi
    buf += n;
80106687:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
8010668a:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
80106690:	89 45 0c             	mov    %eax,0xc(%ebp)
80106693:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
80106696:	85 ff                	test   %edi,%edi
80106698:	74 2f                	je     801066c9 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
8010669a:	8b 75 0c             	mov    0xc(%ebp),%esi
8010669d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
801066a3:	83 ec 08             	sub    $0x8,%esp
801066a6:	56                   	push   %esi
801066a7:	ff 75 08             	pushl  0x8(%ebp)
801066aa:	e8 7a ff ff ff       	call   80106629 <uva2ka>
    if(pa0 == 0)
801066af:	83 c4 10             	add    $0x10,%esp
801066b2:	85 c0                	test   %eax,%eax
801066b4:	74 20                	je     801066d6 <copyout+0x73>
    n = PGSIZE - (va - va0);
801066b6:	89 f3                	mov    %esi,%ebx
801066b8:	2b 5d 0c             	sub    0xc(%ebp),%ebx
801066bb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
801066c1:	39 df                	cmp    %ebx,%edi
801066c3:	73 ac                	jae    80106671 <copyout+0xe>
      n = len;
801066c5:	89 fb                	mov    %edi,%ebx
801066c7:	eb a8                	jmp    80106671 <copyout+0xe>
  }
  return 0;
801066c9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801066ce:	8d 65 f4             	lea    -0xc(%ebp),%esp
801066d1:	5b                   	pop    %ebx
801066d2:	5e                   	pop    %esi
801066d3:	5f                   	pop    %edi
801066d4:	5d                   	pop    %ebp
801066d5:	c3                   	ret    
      return -1;
801066d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066db:	eb f1                	jmp    801066ce <copyout+0x6b>
