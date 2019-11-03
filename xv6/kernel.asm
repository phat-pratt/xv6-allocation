
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
8010002d:	b8 6a 2c 10 80       	mov    $0x80102c6a,%eax
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
80100046:	e8 d0 3d 00 00       	call   80103e1b <acquire>

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
8010007c:	e8 ff 3d 00 00       	call   80103e80 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 7b 3b 00 00       	call   80103c07 <acquiresleep>
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
801000ca:	e8 b1 3d 00 00       	call   80103e80 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 2d 3b 00 00       	call   80103c07 <acquiresleep>
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
801000ea:	68 40 67 10 80       	push   $0x80106740
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 51 67 10 80       	push   $0x80106751
80100100:	68 c0 b5 10 80       	push   $0x8010b5c0
80100105:	e8 d5 3b 00 00       	call   80103cdf <initlock>
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
8010013a:	68 58 67 10 80       	push   $0x80106758
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 8c 3a 00 00       	call   80103bd4 <initsleeplock>
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
801001a8:	e8 e4 3a 00 00       	call   80103c91 <holdingsleep>
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
801001cb:	68 5f 67 10 80       	push   $0x8010675f
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
801001e4:	e8 a8 3a 00 00       	call   80103c91 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 5d 3a 00 00       	call   80103c56 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100200:	e8 16 3c 00 00       	call   80103e1b <acquire>
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
8010024c:	e8 2f 3c 00 00       	call   80103e80 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 66 67 10 80       	push   $0x80106766
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
8010028a:	e8 8c 3b 00 00       	call   80103e1b <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 a0 ff 10 80       	mov    0x8010ffa0,%eax
8010029f:	3b 05 a4 ff 10 80    	cmp    0x8010ffa4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 5e 31 00 00       	call   8010340a <myproc>
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
801002bf:	e8 ea 35 00 00       	call   801038ae <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 10 80       	push   $0x8010a520
801002d1:	e8 aa 3b 00 00       	call   80103e80 <release>
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
80100331:	e8 4a 3b 00 00       	call   80103e80 <release>
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
8010035a:	e8 1a 22 00 00       	call   80102579 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 6d 67 10 80       	push   $0x8010676d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 bb 70 10 80 	movl   $0x801070bb,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 66 39 00 00       	call   80103cfa <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 81 67 10 80       	push   $0x80106781
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
8010049e:	68 85 67 10 80       	push   $0x80106785
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 83 3a 00 00       	call   80103f42 <memmove>
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
801004d9:	e8 e9 39 00 00       	call   80103ec7 <memset>
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
80100506:	e8 f6 4d 00 00       	call   80105301 <uartputc>
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
8010051f:	e8 dd 4d 00 00       	call   80105301 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 d1 4d 00 00       	call   80105301 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 c5 4d 00 00       	call   80105301 <uartputc>
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
80100576:	0f b6 92 b0 67 10 80 	movzbl -0x7fef9850(%edx),%edx
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
801005ca:	e8 4c 38 00 00       	call   80103e1b <acquire>
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
801005f1:	e8 8a 38 00 00       	call   80103e80 <release>
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
80100638:	e8 de 37 00 00       	call   80103e1b <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 9f 67 10 80       	push   $0x8010679f
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
801006ee:	be 98 67 10 80       	mov    $0x80106798,%esi
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
80100734:	e8 47 37 00 00       	call   80103e80 <release>
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
8010074f:	e8 c7 36 00 00       	call   80103e1b <acquire>
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
801007de:	e8 30 32 00 00       	call   80103a13 <wakeup>
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
80100873:	e8 08 36 00 00       	call   80103e80 <release>
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
80100887:	e8 24 32 00 00       	call   80103ab0 <procdump>
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
80100894:	68 a8 67 10 80       	push   $0x801067a8
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 3c 34 00 00       	call   80103cdf <initlock>

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
801008de:	e8 27 2b 00 00       	call   8010340a <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 bb 20 00 00       	call   801029a9 <begin_op>

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
80100935:	e8 e9 20 00 00       	call   80102a23 <end_op>
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
8010094a:	e8 d4 20 00 00       	call   80102a23 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 c1 67 10 80       	push   $0x801067c1
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
80100972:	e8 63 5b 00 00       	call   801064da <setupkvm>
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
80100a06:	e8 5c 59 00 00       	call   80106367 <allocuvm>
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
80100a38:	e8 f8 57 00 00       	call   80106235 <loaduvm>
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
80100a53:	e8 cb 1f 00 00       	call   80102a23 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 ee 58 00 00       	call   80106367 <allocuvm>
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
80100a9d:	e8 c8 59 00 00       	call   8010646a <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 9e 5a 00 00       	call   8010655f <clearpteu>
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
80100ae2:	e8 82 35 00 00       	call   80104069 <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 70 35 00 00       	call   80104069 <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 b0 5b 00 00       	call   801066bb <copyout>
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
80100b66:	e8 50 5b 00 00       	call   801066bb <copyout>
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
80100ba3:	e8 86 34 00 00       	call   8010402e <safestrcpy>
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
80100bd1:	e8 de 54 00 00       	call   801060b4 <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 8c 58 00 00       	call   8010646a <freevm>
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
80100c19:	68 cd 67 10 80       	push   $0x801067cd
80100c1e:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c23:	e8 b7 30 00 00       	call   80103cdf <initlock>
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
80100c39:	e8 dd 31 00 00       	call   80103e1b <acquire>
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
80100c68:	e8 13 32 00 00       	call   80103e80 <release>
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
80100c7f:	e8 fc 31 00 00       	call   80103e80 <release>
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
80100c9d:	e8 79 31 00 00       	call   80103e1b <acquire>
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
80100cba:	e8 c1 31 00 00       	call   80103e80 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 d4 67 10 80       	push   $0x801067d4
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
80100ce2:	e8 34 31 00 00       	call   80103e1b <acquire>
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
80100d03:	e8 78 31 00 00       	call   80103e80 <release>
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
80100d13:	68 dc 67 10 80       	push   $0x801067dc
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
80100d49:	e8 32 31 00 00       	call   80103e80 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 46 1c 00 00       	call   801029a9 <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 b0 1c 00 00       	call   80102a23 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 a8 22 00 00       	call   80103030 <pipeclose>
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
80100e3c:	e8 47 23 00 00       	call   80103188 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 e6 67 10 80       	push   $0x801067e6
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
80100e95:	e8 22 22 00 00       	call   801030bc <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 02 1b 00 00       	call   801029a9 <begin_op>
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
80100edd:	e8 41 1b 00 00       	call   80102a23 <end_op>

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
80100f10:	68 ef 67 10 80       	push   $0x801067ef
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
80100f2d:	68 f5 67 10 80       	push   $0x801067f5
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
80100f8a:	e8 b3 2f 00 00       	call   80103f42 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 a3 2f 00 00       	call   80103f42 <memmove>
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
80100fdf:	e8 e3 2e 00 00       	call   80103ec7 <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 e6 1a 00 00       	call   80102ad2 <log_write>
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
801010a3:	68 ff 67 10 80       	push   $0x801067ff
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
801010bf:	e8 0e 1a 00 00       	call   80102ad2 <log_write>
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
80101170:	e8 5d 19 00 00       	call   80102ad2 <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 15 68 10 80       	push   $0x80106815
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
8010119a:	e8 7c 2c 00 00       	call   80103e1b <acquire>
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
801011e1:	e8 9a 2c 00 00       	call   80103e80 <release>
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
80101217:	e8 64 2c 00 00       	call   80103e80 <release>
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
8010122c:	68 28 68 10 80       	push   $0x80106828
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
80101255:	e8 e8 2c 00 00       	call   80103f42 <memmove>
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
801012c8:	e8 05 18 00 00       	call   80102ad2 <log_write>
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
801012e2:	68 38 68 10 80       	push   $0x80106838
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 4b 68 10 80       	push   $0x8010684b
801012f8:	68 e0 09 11 80       	push   $0x801109e0
801012fd:	e8 dd 29 00 00       	call   80103cdf <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 52 68 10 80       	push   $0x80106852
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 20 0a 11 80       	add    $0x80110a20,%eax
80101321:	50                   	push   %eax
80101322:	e8 ad 28 00 00       	call   80103bd4 <initsleeplock>
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
8010136c:	68 b8 68 10 80       	push   $0x801068b8
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
801013df:	68 58 68 10 80       	push   $0x80106858
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 d1 2a 00 00       	call   80103ec7 <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 cd 16 00 00       	call   80102ad2 <log_write>
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
80101480:	e8 bd 2a 00 00       	call   80103f42 <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 45 16 00 00       	call   80102ad2 <log_write>
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
80101560:	e8 b6 28 00 00       	call   80103e1b <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
80101575:	e8 06 29 00 00       	call   80103e80 <release>
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
8010159a:	e8 68 26 00 00       	call   80103c07 <acquiresleep>
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
801015b2:	68 6a 68 10 80       	push   $0x8010686a
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
80101614:	e8 29 29 00 00       	call   80103f42 <memmove>
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
80101639:	68 70 68 10 80       	push   $0x80106870
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
80101656:	e8 36 26 00 00       	call   80103c91 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 e5 25 00 00       	call   80103c56 <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 7f 68 10 80       	push   $0x8010687f
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
80101698:	e8 6a 25 00 00       	call   80103c07 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 a0 25 00 00       	call   80103c56 <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016bd:	e8 59 27 00 00       	call   80103e1b <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016d2:	e8 a9 27 00 00       	call   80103e80 <release>
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
801016ea:	e8 2c 27 00 00       	call   80103e1b <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016f9:	e8 82 27 00 00       	call   80103e80 <release>
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
8010182a:	e8 13 27 00 00       	call   80103f42 <memmove>
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
80101926:	e8 17 26 00 00       	call   80103f42 <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 9f 11 00 00       	call   80102ad2 <log_write>
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
801019a9:	e8 fb 25 00 00       	call   80103fa9 <strncmp>
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
801019d0:	68 87 68 10 80       	push   $0x80106887
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 99 68 10 80       	push   $0x80106899
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
80101a5a:	e8 ab 19 00 00       	call   8010340a <myproc>
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
80101b92:	68 a8 68 10 80       	push   $0x801068a8
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 38 24 00 00       	call   80103fe6 <strncpy>
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
80101bd7:	68 b4 6e 10 80       	push   $0x80106eb4
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
80101ccc:	68 0b 69 10 80       	push   $0x8010690b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 14 69 10 80       	push   $0x80106914
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
80101d06:	68 26 69 10 80       	push   $0x80106926
80101d0b:	68 80 a5 10 80       	push   $0x8010a580
80101d10:	e8 ca 1f 00 00       	call   80103cdf <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d15:	83 c4 08             	add    $0x8,%esp
80101d18:	a1 20 2d 13 80       	mov    0x80132d20,%eax
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
80101d80:	e8 96 20 00 00       	call   80103e1b <acquire>

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
80101dad:	e8 61 1c 00 00       	call   80103a13 <wakeup>

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
80101dcb:	e8 b0 20 00 00       	call   80103e80 <release>
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
80101de2:	e8 99 20 00 00       	call   80103e80 <release>
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
80101e1a:	e8 72 1e 00 00       	call   80103c91 <holdingsleep>
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
80101e47:	e8 cf 1f 00 00       	call   80103e1b <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 2a 69 10 80       	push   $0x8010692a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 40 69 10 80       	push   $0x80106940
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 55 69 10 80       	push   $0x80106955
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
80101ea9:	e8 00 1a 00 00       	call   801038ae <sleep>
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
80101ec3:	e8 b8 1f 00 00       	call   80103e80 <release>
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
80101f2a:	0f b6 15 80 27 13 80 	movzbl 0x80132780,%edx
80101f31:	39 c2                	cmp    %eax,%edx
80101f33:	75 07                	jne    80101f3c <ioapicinit+0x42>
{
80101f35:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f3a:	eb 36                	jmp    80101f72 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f3c:	83 ec 0c             	sub    $0xc,%esp
80101f3f:	68 74 69 10 80       	push   $0x80106974
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

int framesList[16384];
int pidList[16384];
int frame;
int* getframesList(void)
{
80101fa4:	55                   	push   %ebp
80101fa5:	89 e5                	mov    %esp,%ebp
  return framesList;
}
80101fa7:	b8 80 26 11 80       	mov    $0x80112680,%eax
80101fac:	5d                   	pop    %ebp
80101fad:	c3                   	ret    

80101fae <getframe>:
int
getframe(void) {
80101fae:	55                   	push   %ebp
80101faf:	89 e5                	mov    %esp,%ebp
  return frame;
}
80101fb1:	a1 84 26 13 80       	mov    0x80132684,%eax
80101fb6:	5d                   	pop    %ebp
80101fb7:	c3                   	ret    

80101fb8 <getpidList>:
int* getpidList(void) {
80101fb8:	55                   	push   %ebp
80101fb9:	89 e5                	mov    %esp,%ebp
  return pidList;
}
80101fbb:	b8 80 26 12 80       	mov    $0x80122680,%eax
80101fc0:	5d                   	pop    %ebp
80101fc1:	c3                   	ret    

80101fc2 <kfree>:
// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(char *v)
{
80101fc2:	55                   	push   %ebp
80101fc3:	89 e5                	mov    %esp,%ebp
80101fc5:	56                   	push   %esi
80101fc6:	53                   	push   %ebx
80101fc7:	8b 75 08             	mov    0x8(%ebp),%esi
  struct run *r;

  if ((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80101fca:	f7 c6 ff 0f 00 00    	test   $0xfff,%esi
80101fd0:	75 42                	jne    80102014 <kfree+0x52>
80101fd2:	81 fe c8 54 13 80    	cmp    $0x801354c8,%esi
80101fd8:	72 3a                	jb     80102014 <kfree+0x52>
80101fda:	8d 9e 00 00 00 80    	lea    -0x80000000(%esi),%ebx
80101fe0:	81 fb ff ff ff 0d    	cmp    $0xdffffff,%ebx
80101fe6:	77 2c                	ja     80102014 <kfree+0x52>
    panic("kfree");

  // cprintf("freeing: %x\n", V2P(v)>>12);

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fe8:	83 ec 04             	sub    $0x4,%esp
80101feb:	68 00 10 00 00       	push   $0x1000
80101ff0:	6a 01                	push   $0x1
80101ff2:	56                   	push   %esi
80101ff3:	e8 cf 1e 00 00       	call   80103ec7 <memset>

  if (kmem.use_lock)
80101ff8:	83 c4 10             	add    $0x10,%esp
80101ffb:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80102002:	75 1d                	jne    80102021 <kfree+0x5f>
    acquire(&kmem.lock);
  r = (struct run *)v;
  r->pid = -1;
80102004:	c7 46 04 ff ff ff ff 	movl   $0xffffffff,0x4(%esi)
  //we need to ensure that the freelist is sorted when a freed frame is added. 
  //iterate through the freelist to find the frame that
  
  // if the freelist is empty add it to head.
  if(r > kmem.freelist) {
8010200b:	a1 78 26 11 80       	mov    0x80112678,%eax
  } else {
    // if the list is not empty, find the first element smaller than 

  }
  struct run *curr = kmem.freelist;
  struct run *prev = kmem.freelist;
80102010:	89 c2                	mov    %eax,%edx
  while(r<curr) {
80102012:	eb 23                	jmp    80102037 <kfree+0x75>
    panic("kfree");
80102014:	83 ec 0c             	sub    $0xc,%esp
80102017:	68 a6 69 10 80       	push   $0x801069a6
8010201c:	e8 27 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 40 26 11 80       	push   $0x80112640
80102029:	e8 ed 1d 00 00       	call   80103e1b <acquire>
8010202e:	83 c4 10             	add    $0x10,%esp
80102031:	eb d1                	jmp    80102004 <kfree+0x42>
    prev = curr;
80102033:	89 c2                	mov    %eax,%edx
    curr = curr->next;
80102035:	8b 00                	mov    (%eax),%eax
  while(r<curr) {
80102037:	39 f0                	cmp    %esi,%eax
80102039:	77 f8                	ja     80102033 <kfree+0x71>
  }
  curr->prev = r;
8010203b:	89 70 08             	mov    %esi,0x8(%eax)
  r->next = curr;
8010203e:	89 06                	mov    %eax,(%esi)
  if(prev == kmem.freelist){
80102040:	39 15 78 26 11 80    	cmp    %edx,0x80112678
80102046:	74 27                	je     8010206f <kfree+0xad>
    kmem.freelist = r;
  } else{
    prev->next = r;
80102048:	89 32                	mov    %esi,(%edx)
    r->prev = prev;
8010204a:	89 56 08             	mov    %edx,0x8(%esi)
  }
  //find the frame being freed in the allocated list
  for(int i = 0; i<frame; i++){
8010204d:	b8 00 00 00 00       	mov    $0x0,%eax
80102052:	8b 15 84 26 13 80    	mov    0x80132684,%edx
80102058:	39 c2                	cmp    %eax,%edx
8010205a:	7e 3b                	jle    80102097 <kfree+0xd5>
    if(framesList[i] == V2P(r)>>12){
8010205c:	89 d9                	mov    %ebx,%ecx
8010205e:	c1 e9 0c             	shr    $0xc,%ecx
80102061:	39 0c 85 80 26 11 80 	cmp    %ecx,-0x7feed980(,%eax,4)
80102068:	74 20                	je     8010208a <kfree+0xc8>
  for(int i = 0; i<frame; i++){
8010206a:	83 c0 01             	add    $0x1,%eax
8010206d:	eb e3                	jmp    80102052 <kfree+0x90>
    kmem.freelist = r;
8010206f:	89 35 78 26 11 80    	mov    %esi,0x80112678
80102075:	eb d6                	jmp    8010204d <kfree+0x8b>
      //if the process is found, remove it and shift list
      for(int j = i; j<frame-1;j++) {
        framesList[j] = framesList[j+1];
80102077:	8d 48 01             	lea    0x1(%eax),%ecx
8010207a:	8b 1c 8d 80 26 11 80 	mov    -0x7feed980(,%ecx,4),%ebx
80102081:	89 1c 85 80 26 11 80 	mov    %ebx,-0x7feed980(,%eax,4)
      for(int j = i; j<frame-1;j++) {
80102088:	89 c8                	mov    %ecx,%eax
8010208a:	8d 4a ff             	lea    -0x1(%edx),%ecx
8010208d:	39 c1                	cmp    %eax,%ecx
8010208f:	7f e6                	jg     80102077 <kfree+0xb5>
      }
      frame--;
80102091:	89 0d 84 26 13 80    	mov    %ecx,0x80132684
    }
  }
  // r->next = kmem.freelist;
  // kmem.freelist = r;
  
  if (kmem.use_lock)
80102097:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
8010209e:	75 07                	jne    801020a7 <kfree+0xe5>
    release(&kmem.lock);
}
801020a0:	8d 65 f8             	lea    -0x8(%ebp),%esp
801020a3:	5b                   	pop    %ebx
801020a4:	5e                   	pop    %esi
801020a5:	5d                   	pop    %ebp
801020a6:	c3                   	ret    
    release(&kmem.lock);
801020a7:	83 ec 0c             	sub    $0xc,%esp
801020aa:	68 40 26 11 80       	push   $0x80112640
801020af:	e8 cc 1d 00 00       	call   80103e80 <release>
801020b4:	83 c4 10             	add    $0x10,%esp
}
801020b7:	eb e7                	jmp    801020a0 <kfree+0xde>

801020b9 <kfree2>:
void kfree2(char *v)
{
801020b9:	55                   	push   %ebp
801020ba:	89 e5                	mov    %esp,%ebp
801020bc:	53                   	push   %ebx
801020bd:	83 ec 04             	sub    $0x4,%esp
801020c0:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if ((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
801020c3:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
801020c9:	75 53                	jne    8010211e <kfree2+0x65>
801020cb:	81 fb c8 54 13 80    	cmp    $0x801354c8,%ebx
801020d1:	72 4b                	jb     8010211e <kfree2+0x65>
801020d3:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801020d9:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
801020de:	77 3e                	ja     8010211e <kfree2+0x65>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
801020e0:	83 ec 04             	sub    $0x4,%esp
801020e3:	68 00 10 00 00       	push   $0x1000
801020e8:	6a 01                	push   $0x1
801020ea:	53                   	push   %ebx
801020eb:	e8 d7 1d 00 00       	call   80103ec7 <memset>

  if (kmem.use_lock)
801020f0:	83 c4 10             	add    $0x10,%esp
801020f3:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801020fa:	75 2f                	jne    8010212b <kfree2+0x72>
    acquire(&kmem.lock);
  r = (struct run *)v;
  r->next = kmem.freelist;
801020fc:	a1 78 26 11 80       	mov    0x80112678,%eax
80102101:	89 03                	mov    %eax,(%ebx)
  r->pid = -1;
80102103:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
  kmem.freelist = r;
8010210a:	89 1d 78 26 11 80    	mov    %ebx,0x80112678
  if (kmem.use_lock)
80102110:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80102117:	75 24                	jne    8010213d <kfree2+0x84>
    release(&kmem.lock);
}
80102119:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010211c:	c9                   	leave  
8010211d:	c3                   	ret    
    panic("kfree");
8010211e:	83 ec 0c             	sub    $0xc,%esp
80102121:	68 a6 69 10 80       	push   $0x801069a6
80102126:	e8 1d e2 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010212b:	83 ec 0c             	sub    $0xc,%esp
8010212e:	68 40 26 11 80       	push   $0x80112640
80102133:	e8 e3 1c 00 00       	call   80103e1b <acquire>
80102138:	83 c4 10             	add    $0x10,%esp
8010213b:	eb bf                	jmp    801020fc <kfree2+0x43>
    release(&kmem.lock);
8010213d:	83 ec 0c             	sub    $0xc,%esp
80102140:	68 40 26 11 80       	push   $0x80112640
80102145:	e8 36 1d 00 00       	call   80103e80 <release>
8010214a:	83 c4 10             	add    $0x10,%esp
}
8010214d:	eb ca                	jmp    80102119 <kfree2+0x60>

8010214f <freerange>:
{
8010214f:	55                   	push   %ebp
80102150:	89 e5                	mov    %esp,%ebp
80102152:	56                   	push   %esi
80102153:	53                   	push   %ebx
80102154:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char *)PGROUNDUP((uint)vstart);
80102157:	8b 45 08             	mov    0x8(%ebp),%eax
8010215a:	05 ff 0f 00 00       	add    $0xfff,%eax
8010215f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
80102164:	eb 0e                	jmp    80102174 <freerange+0x25>
    kfree2(p);
80102166:	83 ec 0c             	sub    $0xc,%esp
80102169:	50                   	push   %eax
8010216a:	e8 4a ff ff ff       	call   801020b9 <kfree2>
  for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
8010216f:	83 c4 10             	add    $0x10,%esp
80102172:	89 f0                	mov    %esi,%eax
80102174:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
8010217a:	39 de                	cmp    %ebx,%esi
8010217c:	76 e8                	jbe    80102166 <freerange+0x17>
}
8010217e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102181:	5b                   	pop    %ebx
80102182:	5e                   	pop    %esi
80102183:	5d                   	pop    %ebp
80102184:	c3                   	ret    

80102185 <kinit1>:
{
80102185:	55                   	push   %ebp
80102186:	89 e5                	mov    %esp,%ebp
80102188:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
8010218b:	68 ac 69 10 80       	push   $0x801069ac
80102190:	68 40 26 11 80       	push   $0x80112640
80102195:	e8 45 1b 00 00       	call   80103cdf <initlock>
  kmem.use_lock = 0;
8010219a:	c7 05 74 26 11 80 00 	movl   $0x0,0x80112674
801021a1:	00 00 00 
  freerange(vstart, vend);
801021a4:	83 c4 08             	add    $0x8,%esp
801021a7:	ff 75 0c             	pushl  0xc(%ebp)
801021aa:	ff 75 08             	pushl  0x8(%ebp)
801021ad:	e8 9d ff ff ff       	call   8010214f <freerange>
}
801021b2:	83 c4 10             	add    $0x10,%esp
801021b5:	c9                   	leave  
801021b6:	c3                   	ret    

801021b7 <kinit2>:
{
801021b7:	55                   	push   %ebp
801021b8:	89 e5                	mov    %esp,%ebp
801021ba:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
801021bd:	ff 75 0c             	pushl  0xc(%ebp)
801021c0:	ff 75 08             	pushl  0x8(%ebp)
801021c3:	e8 87 ff ff ff       	call   8010214f <freerange>
  kmem.use_lock = 1;
801021c8:	c7 05 74 26 11 80 01 	movl   $0x1,0x80112674
801021cf:	00 00 00 
}
801021d2:	83 c4 10             	add    $0x10,%esp
801021d5:	c9                   	leave  
801021d6:	c3                   	ret    

801021d7 <kalloc>:
// Returns 0 if the memory cannot be allocated.
// From spec - kalloc manages freelist and allocates physical memory
// returns first page on the freelist
char *
kalloc(int pid)
{
801021d7:	55                   	push   %ebp
801021d8:	89 e5                	mov    %esp,%ebp
801021da:	56                   	push   %esi
801021db:	53                   	push   %ebx
801021dc:	8b 75 08             	mov    0x8(%ebp),%esi
  struct run *r;
  struct af *a;

  if (kmem.use_lock)
801021df:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801021e6:	75 64                	jne    8010224c <kalloc+0x75>
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;
801021e8:	8b 1d 78 26 11 80    	mov    0x80112678,%ebx

  // we need to get the PA to retrieve the frame number
  if (r)
801021ee:	85 db                	test   %ebx,%ebx
801021f0:	74 48                	je     8010223a <kalloc+0x63>
  {
    
    r->pid = pid;
801021f2:	89 73 04             	mov    %esi,0x4(%ebx)
    // if the last process allocated is the same as the current, then create a free frame
    int frameNumber = V2P(r) >> 12;
801021f5:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801021fb:	c1 e8 0c             	shr    $0xc,%eax
    if(frameNumber > 1023) {
801021fe:	3d ff 03 00 00       	cmp    $0x3ff,%eax
80102203:	7e 2e                	jle    80102233 <kalloc+0x5c>
      pidList[frame] = pid;
80102205:	8b 15 84 26 13 80    	mov    0x80132684,%edx
8010220b:	89 34 95 80 26 12 80 	mov    %esi,-0x7fedd980(,%edx,4)
      framesList[frame++] = frameNumber;
80102212:	8d 4a 01             	lea    0x1(%edx),%ecx
80102215:	89 0d 84 26 13 80    	mov    %ecx,0x80132684
8010221b:	89 04 95 80 26 11 80 	mov    %eax,-0x7feed980(,%edx,4)
      a = (struct af *)r;
      //we can get the frameNumber of a with V2P>>12
      a->next = allocFrames.aFrames;
80102222:	a1 7c 26 11 80       	mov    0x8011267c,%eax
80102227:	89 43 08             	mov    %eax,0x8(%ebx)
      a->pid = pid;
8010222a:	89 73 04             	mov    %esi,0x4(%ebx)
      allocFrames.aFrames = a;
8010222d:	89 1d 7c 26 11 80    	mov    %ebx,0x8011267c
      
    }  
    kmem.freelist = r->next;
80102233:	8b 03                	mov    (%ebx),%eax
80102235:	a3 78 26 11 80       	mov    %eax,0x80112678
    
  }
  if (kmem.use_lock)
8010223a:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80102241:	75 1b                	jne    8010225e <kalloc+0x87>
  {
    release(&kmem.lock);
  }
  return (char *)r;
}
80102243:	89 d8                	mov    %ebx,%eax
80102245:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102248:	5b                   	pop    %ebx
80102249:	5e                   	pop    %esi
8010224a:	5d                   	pop    %ebp
8010224b:	c3                   	ret    
    acquire(&kmem.lock);
8010224c:	83 ec 0c             	sub    $0xc,%esp
8010224f:	68 40 26 11 80       	push   $0x80112640
80102254:	e8 c2 1b 00 00       	call   80103e1b <acquire>
80102259:	83 c4 10             	add    $0x10,%esp
8010225c:	eb 8a                	jmp    801021e8 <kalloc+0x11>
    release(&kmem.lock);
8010225e:	83 ec 0c             	sub    $0xc,%esp
80102261:	68 40 26 11 80       	push   $0x80112640
80102266:	e8 15 1c 00 00       	call   80103e80 <release>
8010226b:	83 c4 10             	add    $0x10,%esp
  return (char *)r;
8010226e:	eb d3                	jmp    80102243 <kalloc+0x6c>

80102270 <kalloc2>:

// called by the excluded methods (inituvm, setupkvm, walkpgdir). We need to
// "mark these pages as belonging to an unknown process". (-2)
char *
kalloc2(void)
{
80102270:	55                   	push   %ebp
80102271:	89 e5                	mov    %esp,%ebp
80102273:	53                   	push   %ebx
80102274:	83 ec 04             	sub    $0x4,%esp
  struct run *r;
  struct af *a;

  if (kmem.use_lock)
80102277:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
8010227e:	75 67                	jne    801022e7 <kalloc2+0x77>
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;
80102280:	8b 1d 78 26 11 80    	mov    0x80112678,%ebx

  // we need to get the PA to retrieve the frame number
  if (r)
80102286:	85 db                	test   %ebx,%ebx
80102288:	74 4d                	je     801022d7 <kalloc2+0x67>
  {
    int frameNumber = V2P(r) >> 12; 
8010228a:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102290:	c1 e8 0c             	shr    $0xc,%eax
    if(frameNumber > 1023) {
80102293:	3d ff 03 00 00       	cmp    $0x3ff,%eax
80102298:	7e 36                	jle    801022d0 <kalloc2+0x60>
      pidList[frame] = -2; // -2 for unknown process.
8010229a:	8b 15 84 26 13 80    	mov    0x80132684,%edx
801022a0:	c7 04 95 80 26 12 80 	movl   $0xfffffffe,-0x7fedd980(,%edx,4)
801022a7:	fe ff ff ff 
      framesList[frame++] = frameNumber;
801022ab:	8d 4a 01             	lea    0x1(%edx),%ecx
801022ae:	89 0d 84 26 13 80    	mov    %ecx,0x80132684
801022b4:	89 04 95 80 26 11 80 	mov    %eax,-0x7feed980(,%edx,4)
       a = (struct af *)r;
      //we can get the frameNumber of a with V2P>>12
      a->next = allocFrames.aFrames;
801022bb:	a1 7c 26 11 80       	mov    0x8011267c,%eax
801022c0:	89 43 08             	mov    %eax,0x8(%ebx)
      a->pid = -2;
801022c3:	c7 43 04 fe ff ff ff 	movl   $0xfffffffe,0x4(%ebx)
      allocFrames.aFrames = a;
801022ca:	89 1d 7c 26 11 80    	mov    %ebx,0x8011267c
      
    }    
    kmem.freelist = r->next;
801022d0:	8b 03                	mov    (%ebx),%eax
801022d2:	a3 78 26 11 80       	mov    %eax,0x80112678
   
  }
  if (kmem.use_lock)
801022d7:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801022de:	75 19                	jne    801022f9 <kalloc2+0x89>
  {
    release(&kmem.lock);
  }
  return (char *)r;
801022e0:	89 d8                	mov    %ebx,%eax
801022e2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801022e5:	c9                   	leave  
801022e6:	c3                   	ret    
    acquire(&kmem.lock);
801022e7:	83 ec 0c             	sub    $0xc,%esp
801022ea:	68 40 26 11 80       	push   $0x80112640
801022ef:	e8 27 1b 00 00       	call   80103e1b <acquire>
801022f4:	83 c4 10             	add    $0x10,%esp
801022f7:	eb 87                	jmp    80102280 <kalloc2+0x10>
    release(&kmem.lock);
801022f9:	83 ec 0c             	sub    $0xc,%esp
801022fc:	68 40 26 11 80       	push   $0x80112640
80102301:	e8 7a 1b 00 00       	call   80103e80 <release>
80102306:	83 c4 10             	add    $0x10,%esp
  return (char *)r;
80102309:	eb d5                	jmp    801022e0 <kalloc2+0x70>

8010230b <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
8010230b:	55                   	push   %ebp
8010230c:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010230e:	ba 64 00 00 00       	mov    $0x64,%edx
80102313:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
80102314:	a8 01                	test   $0x1,%al
80102316:	0f 84 b5 00 00 00    	je     801023d1 <kbdgetc+0xc6>
8010231c:	ba 60 00 00 00       	mov    $0x60,%edx
80102321:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102322:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
80102325:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
8010232b:	74 5c                	je     80102389 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
8010232d:	84 c0                	test   %al,%al
8010232f:	78 66                	js     80102397 <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102331:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
80102337:	f6 c1 40             	test   $0x40,%cl
8010233a:	74 0f                	je     8010234b <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
8010233c:	83 c8 80             	or     $0xffffff80,%eax
8010233f:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
80102342:	83 e1 bf             	and    $0xffffffbf,%ecx
80102345:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  }

  shift |= shiftcode[data];
8010234b:	0f b6 8a e0 6a 10 80 	movzbl -0x7fef9520(%edx),%ecx
80102352:	0b 0d b4 a5 10 80    	or     0x8010a5b4,%ecx
  shift ^= togglecode[data];
80102358:	0f b6 82 e0 69 10 80 	movzbl -0x7fef9620(%edx),%eax
8010235f:	31 c1                	xor    %eax,%ecx
80102361:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  c = charcode[shift & (CTL | SHIFT)][data];
80102367:	89 c8                	mov    %ecx,%eax
80102369:	83 e0 03             	and    $0x3,%eax
8010236c:	8b 04 85 c0 69 10 80 	mov    -0x7fef9640(,%eax,4),%eax
80102373:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
80102377:	f6 c1 08             	test   $0x8,%cl
8010237a:	74 19                	je     80102395 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
8010237c:	8d 50 9f             	lea    -0x61(%eax),%edx
8010237f:	83 fa 19             	cmp    $0x19,%edx
80102382:	77 40                	ja     801023c4 <kbdgetc+0xb9>
      c += 'A' - 'a';
80102384:	83 e8 20             	sub    $0x20,%eax
80102387:	eb 0c                	jmp    80102395 <kbdgetc+0x8a>
    shift |= E0ESC;
80102389:	83 0d b4 a5 10 80 40 	orl    $0x40,0x8010a5b4
    return 0;
80102390:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
80102395:	5d                   	pop    %ebp
80102396:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
80102397:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
8010239d:	f6 c1 40             	test   $0x40,%cl
801023a0:	75 05                	jne    801023a7 <kbdgetc+0x9c>
801023a2:	89 c2                	mov    %eax,%edx
801023a4:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
801023a7:	0f b6 82 e0 6a 10 80 	movzbl -0x7fef9520(%edx),%eax
801023ae:	83 c8 40             	or     $0x40,%eax
801023b1:	0f b6 c0             	movzbl %al,%eax
801023b4:	f7 d0                	not    %eax
801023b6:	21 c8                	and    %ecx,%eax
801023b8:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    return 0;
801023bd:	b8 00 00 00 00       	mov    $0x0,%eax
801023c2:	eb d1                	jmp    80102395 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
801023c4:	8d 50 bf             	lea    -0x41(%eax),%edx
801023c7:	83 fa 19             	cmp    $0x19,%edx
801023ca:	77 c9                	ja     80102395 <kbdgetc+0x8a>
      c += 'a' - 'A';
801023cc:	83 c0 20             	add    $0x20,%eax
  return c;
801023cf:	eb c4                	jmp    80102395 <kbdgetc+0x8a>
    return -1;
801023d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801023d6:	eb bd                	jmp    80102395 <kbdgetc+0x8a>

801023d8 <kbdintr>:

void
kbdintr(void)
{
801023d8:	55                   	push   %ebp
801023d9:	89 e5                	mov    %esp,%ebp
801023db:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
801023de:	68 0b 23 10 80       	push   $0x8010230b
801023e3:	e8 56 e3 ff ff       	call   8010073e <consoleintr>
}
801023e8:	83 c4 10             	add    $0x10,%esp
801023eb:	c9                   	leave  
801023ec:	c3                   	ret    

801023ed <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
801023ed:	55                   	push   %ebp
801023ee:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
801023f0:	8b 0d 88 26 13 80    	mov    0x80132688,%ecx
801023f6:	8d 04 81             	lea    (%ecx,%eax,4),%eax
801023f9:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
801023fb:	a1 88 26 13 80       	mov    0x80132688,%eax
80102400:	8b 40 20             	mov    0x20(%eax),%eax
}
80102403:	5d                   	pop    %ebp
80102404:	c3                   	ret    

80102405 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
80102405:	55                   	push   %ebp
80102406:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102408:	ba 70 00 00 00       	mov    $0x70,%edx
8010240d:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010240e:	ba 71 00 00 00       	mov    $0x71,%edx
80102413:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
80102414:	0f b6 c0             	movzbl %al,%eax
}
80102417:	5d                   	pop    %ebp
80102418:	c3                   	ret    

80102419 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
80102419:	55                   	push   %ebp
8010241a:	89 e5                	mov    %esp,%ebp
8010241c:	53                   	push   %ebx
8010241d:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
8010241f:	b8 00 00 00 00       	mov    $0x0,%eax
80102424:	e8 dc ff ff ff       	call   80102405 <cmos_read>
80102429:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
8010242b:	b8 02 00 00 00       	mov    $0x2,%eax
80102430:	e8 d0 ff ff ff       	call   80102405 <cmos_read>
80102435:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
80102438:	b8 04 00 00 00       	mov    $0x4,%eax
8010243d:	e8 c3 ff ff ff       	call   80102405 <cmos_read>
80102442:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
80102445:	b8 07 00 00 00       	mov    $0x7,%eax
8010244a:	e8 b6 ff ff ff       	call   80102405 <cmos_read>
8010244f:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102452:	b8 08 00 00 00       	mov    $0x8,%eax
80102457:	e8 a9 ff ff ff       	call   80102405 <cmos_read>
8010245c:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
8010245f:	b8 09 00 00 00       	mov    $0x9,%eax
80102464:	e8 9c ff ff ff       	call   80102405 <cmos_read>
80102469:	89 43 14             	mov    %eax,0x14(%ebx)
}
8010246c:	5b                   	pop    %ebx
8010246d:	5d                   	pop    %ebp
8010246e:	c3                   	ret    

8010246f <lapicinit>:
  if(!lapic)
8010246f:	83 3d 88 26 13 80 00 	cmpl   $0x0,0x80132688
80102476:	0f 84 fb 00 00 00    	je     80102577 <lapicinit+0x108>
{
8010247c:	55                   	push   %ebp
8010247d:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010247f:	ba 3f 01 00 00       	mov    $0x13f,%edx
80102484:	b8 3c 00 00 00       	mov    $0x3c,%eax
80102489:	e8 5f ff ff ff       	call   801023ed <lapicw>
  lapicw(TDCR, X1);
8010248e:	ba 0b 00 00 00       	mov    $0xb,%edx
80102493:	b8 f8 00 00 00       	mov    $0xf8,%eax
80102498:	e8 50 ff ff ff       	call   801023ed <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
8010249d:	ba 20 00 02 00       	mov    $0x20020,%edx
801024a2:	b8 c8 00 00 00       	mov    $0xc8,%eax
801024a7:	e8 41 ff ff ff       	call   801023ed <lapicw>
  lapicw(TICR, 10000000);
801024ac:	ba 80 96 98 00       	mov    $0x989680,%edx
801024b1:	b8 e0 00 00 00       	mov    $0xe0,%eax
801024b6:	e8 32 ff ff ff       	call   801023ed <lapicw>
  lapicw(LINT0, MASKED);
801024bb:	ba 00 00 01 00       	mov    $0x10000,%edx
801024c0:	b8 d4 00 00 00       	mov    $0xd4,%eax
801024c5:	e8 23 ff ff ff       	call   801023ed <lapicw>
  lapicw(LINT1, MASKED);
801024ca:	ba 00 00 01 00       	mov    $0x10000,%edx
801024cf:	b8 d8 00 00 00       	mov    $0xd8,%eax
801024d4:	e8 14 ff ff ff       	call   801023ed <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801024d9:	a1 88 26 13 80       	mov    0x80132688,%eax
801024de:	8b 40 30             	mov    0x30(%eax),%eax
801024e1:	c1 e8 10             	shr    $0x10,%eax
801024e4:	3c 03                	cmp    $0x3,%al
801024e6:	77 7b                	ja     80102563 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801024e8:	ba 33 00 00 00       	mov    $0x33,%edx
801024ed:	b8 dc 00 00 00       	mov    $0xdc,%eax
801024f2:	e8 f6 fe ff ff       	call   801023ed <lapicw>
  lapicw(ESR, 0);
801024f7:	ba 00 00 00 00       	mov    $0x0,%edx
801024fc:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102501:	e8 e7 fe ff ff       	call   801023ed <lapicw>
  lapicw(ESR, 0);
80102506:	ba 00 00 00 00       	mov    $0x0,%edx
8010250b:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102510:	e8 d8 fe ff ff       	call   801023ed <lapicw>
  lapicw(EOI, 0);
80102515:	ba 00 00 00 00       	mov    $0x0,%edx
8010251a:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010251f:	e8 c9 fe ff ff       	call   801023ed <lapicw>
  lapicw(ICRHI, 0);
80102524:	ba 00 00 00 00       	mov    $0x0,%edx
80102529:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010252e:	e8 ba fe ff ff       	call   801023ed <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102533:	ba 00 85 08 00       	mov    $0x88500,%edx
80102538:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010253d:	e8 ab fe ff ff       	call   801023ed <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102542:	a1 88 26 13 80       	mov    0x80132688,%eax
80102547:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
8010254d:	f6 c4 10             	test   $0x10,%ah
80102550:	75 f0                	jne    80102542 <lapicinit+0xd3>
  lapicw(TPR, 0);
80102552:	ba 00 00 00 00       	mov    $0x0,%edx
80102557:	b8 20 00 00 00       	mov    $0x20,%eax
8010255c:	e8 8c fe ff ff       	call   801023ed <lapicw>
}
80102561:	5d                   	pop    %ebp
80102562:	c3                   	ret    
    lapicw(PCINT, MASKED);
80102563:	ba 00 00 01 00       	mov    $0x10000,%edx
80102568:	b8 d0 00 00 00       	mov    $0xd0,%eax
8010256d:	e8 7b fe ff ff       	call   801023ed <lapicw>
80102572:	e9 71 ff ff ff       	jmp    801024e8 <lapicinit+0x79>
80102577:	f3 c3                	repz ret 

80102579 <lapicid>:
{
80102579:	55                   	push   %ebp
8010257a:	89 e5                	mov    %esp,%ebp
  if (!lapic)
8010257c:	a1 88 26 13 80       	mov    0x80132688,%eax
80102581:	85 c0                	test   %eax,%eax
80102583:	74 08                	je     8010258d <lapicid+0x14>
  return lapic[ID] >> 24;
80102585:	8b 40 20             	mov    0x20(%eax),%eax
80102588:	c1 e8 18             	shr    $0x18,%eax
}
8010258b:	5d                   	pop    %ebp
8010258c:	c3                   	ret    
    return 0;
8010258d:	b8 00 00 00 00       	mov    $0x0,%eax
80102592:	eb f7                	jmp    8010258b <lapicid+0x12>

80102594 <lapiceoi>:
  if(lapic)
80102594:	83 3d 88 26 13 80 00 	cmpl   $0x0,0x80132688
8010259b:	74 14                	je     801025b1 <lapiceoi+0x1d>
{
8010259d:	55                   	push   %ebp
8010259e:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
801025a0:	ba 00 00 00 00       	mov    $0x0,%edx
801025a5:	b8 2c 00 00 00       	mov    $0x2c,%eax
801025aa:	e8 3e fe ff ff       	call   801023ed <lapicw>
}
801025af:	5d                   	pop    %ebp
801025b0:	c3                   	ret    
801025b1:	f3 c3                	repz ret 

801025b3 <microdelay>:
{
801025b3:	55                   	push   %ebp
801025b4:	89 e5                	mov    %esp,%ebp
}
801025b6:	5d                   	pop    %ebp
801025b7:	c3                   	ret    

801025b8 <lapicstartap>:
{
801025b8:	55                   	push   %ebp
801025b9:	89 e5                	mov    %esp,%ebp
801025bb:	57                   	push   %edi
801025bc:	56                   	push   %esi
801025bd:	53                   	push   %ebx
801025be:	8b 75 08             	mov    0x8(%ebp),%esi
801025c1:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801025c4:	b8 0f 00 00 00       	mov    $0xf,%eax
801025c9:	ba 70 00 00 00       	mov    $0x70,%edx
801025ce:	ee                   	out    %al,(%dx)
801025cf:	b8 0a 00 00 00       	mov    $0xa,%eax
801025d4:	ba 71 00 00 00       	mov    $0x71,%edx
801025d9:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
801025da:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
801025e1:	00 00 
  wrv[1] = addr >> 4;
801025e3:	89 f8                	mov    %edi,%eax
801025e5:	c1 e8 04             	shr    $0x4,%eax
801025e8:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
801025ee:	c1 e6 18             	shl    $0x18,%esi
801025f1:	89 f2                	mov    %esi,%edx
801025f3:	b8 c4 00 00 00       	mov    $0xc4,%eax
801025f8:	e8 f0 fd ff ff       	call   801023ed <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801025fd:	ba 00 c5 00 00       	mov    $0xc500,%edx
80102602:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102607:	e8 e1 fd ff ff       	call   801023ed <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
8010260c:	ba 00 85 00 00       	mov    $0x8500,%edx
80102611:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102616:	e8 d2 fd ff ff       	call   801023ed <lapicw>
  for(i = 0; i < 2; i++){
8010261b:	bb 00 00 00 00       	mov    $0x0,%ebx
80102620:	eb 21                	jmp    80102643 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102622:	89 f2                	mov    %esi,%edx
80102624:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102629:	e8 bf fd ff ff       	call   801023ed <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010262e:	89 fa                	mov    %edi,%edx
80102630:	c1 ea 0c             	shr    $0xc,%edx
80102633:	80 ce 06             	or     $0x6,%dh
80102636:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010263b:	e8 ad fd ff ff       	call   801023ed <lapicw>
  for(i = 0; i < 2; i++){
80102640:	83 c3 01             	add    $0x1,%ebx
80102643:	83 fb 01             	cmp    $0x1,%ebx
80102646:	7e da                	jle    80102622 <lapicstartap+0x6a>
}
80102648:	5b                   	pop    %ebx
80102649:	5e                   	pop    %esi
8010264a:	5f                   	pop    %edi
8010264b:	5d                   	pop    %ebp
8010264c:	c3                   	ret    

8010264d <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
8010264d:	55                   	push   %ebp
8010264e:	89 e5                	mov    %esp,%ebp
80102650:	57                   	push   %edi
80102651:	56                   	push   %esi
80102652:	53                   	push   %ebx
80102653:	83 ec 3c             	sub    $0x3c,%esp
80102656:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80102659:	b8 0b 00 00 00       	mov    $0xb,%eax
8010265e:	e8 a2 fd ff ff       	call   80102405 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
80102663:	83 e0 04             	and    $0x4,%eax
80102666:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
80102668:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010266b:	e8 a9 fd ff ff       	call   80102419 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80102670:	b8 0a 00 00 00       	mov    $0xa,%eax
80102675:	e8 8b fd ff ff       	call   80102405 <cmos_read>
8010267a:	a8 80                	test   $0x80,%al
8010267c:	75 ea                	jne    80102668 <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
8010267e:	8d 5d b8             	lea    -0x48(%ebp),%ebx
80102681:	89 d8                	mov    %ebx,%eax
80102683:	e8 91 fd ff ff       	call   80102419 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
80102688:	83 ec 04             	sub    $0x4,%esp
8010268b:	6a 18                	push   $0x18
8010268d:	53                   	push   %ebx
8010268e:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102691:	50                   	push   %eax
80102692:	e8 76 18 00 00       	call   80103f0d <memcmp>
80102697:	83 c4 10             	add    $0x10,%esp
8010269a:	85 c0                	test   %eax,%eax
8010269c:	75 ca                	jne    80102668 <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
8010269e:	85 ff                	test   %edi,%edi
801026a0:	0f 85 84 00 00 00    	jne    8010272a <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801026a6:	8b 55 d0             	mov    -0x30(%ebp),%edx
801026a9:	89 d0                	mov    %edx,%eax
801026ab:	c1 e8 04             	shr    $0x4,%eax
801026ae:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801026b1:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801026b4:	83 e2 0f             	and    $0xf,%edx
801026b7:	01 d0                	add    %edx,%eax
801026b9:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
801026bc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
801026bf:	89 d0                	mov    %edx,%eax
801026c1:	c1 e8 04             	shr    $0x4,%eax
801026c4:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801026c7:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801026ca:	83 e2 0f             	and    $0xf,%edx
801026cd:	01 d0                	add    %edx,%eax
801026cf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801026d2:	8b 55 d8             	mov    -0x28(%ebp),%edx
801026d5:	89 d0                	mov    %edx,%eax
801026d7:	c1 e8 04             	shr    $0x4,%eax
801026da:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801026dd:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801026e0:	83 e2 0f             	and    $0xf,%edx
801026e3:	01 d0                	add    %edx,%eax
801026e5:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
801026e8:	8b 55 dc             	mov    -0x24(%ebp),%edx
801026eb:	89 d0                	mov    %edx,%eax
801026ed:	c1 e8 04             	shr    $0x4,%eax
801026f0:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801026f3:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801026f6:	83 e2 0f             	and    $0xf,%edx
801026f9:	01 d0                	add    %edx,%eax
801026fb:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
801026fe:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102701:	89 d0                	mov    %edx,%eax
80102703:	c1 e8 04             	shr    $0x4,%eax
80102706:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102709:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010270c:	83 e2 0f             	and    $0xf,%edx
8010270f:	01 d0                	add    %edx,%eax
80102711:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
80102714:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102717:	89 d0                	mov    %edx,%eax
80102719:	c1 e8 04             	shr    $0x4,%eax
8010271c:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010271f:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102722:	83 e2 0f             	and    $0xf,%edx
80102725:	01 d0                	add    %edx,%eax
80102727:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
8010272a:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010272d:	89 06                	mov    %eax,(%esi)
8010272f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102732:	89 46 04             	mov    %eax,0x4(%esi)
80102735:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102738:	89 46 08             	mov    %eax,0x8(%esi)
8010273b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010273e:	89 46 0c             	mov    %eax,0xc(%esi)
80102741:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102744:	89 46 10             	mov    %eax,0x10(%esi)
80102747:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010274a:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
8010274d:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
80102754:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102757:	5b                   	pop    %ebx
80102758:	5e                   	pop    %esi
80102759:	5f                   	pop    %edi
8010275a:	5d                   	pop    %ebp
8010275b:	c3                   	ret    

8010275c <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010275c:	55                   	push   %ebp
8010275d:	89 e5                	mov    %esp,%ebp
8010275f:	53                   	push   %ebx
80102760:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102763:	ff 35 d4 26 13 80    	pushl  0x801326d4
80102769:	ff 35 e4 26 13 80    	pushl  0x801326e4
8010276f:	e8 f8 d9 ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
80102774:	8b 58 5c             	mov    0x5c(%eax),%ebx
80102777:	89 1d e8 26 13 80    	mov    %ebx,0x801326e8
  for (i = 0; i < log.lh.n; i++) {
8010277d:	83 c4 10             	add    $0x10,%esp
80102780:	ba 00 00 00 00       	mov    $0x0,%edx
80102785:	eb 0e                	jmp    80102795 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
80102787:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
8010278b:	89 0c 95 ec 26 13 80 	mov    %ecx,-0x7fecd914(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
80102792:	83 c2 01             	add    $0x1,%edx
80102795:	39 d3                	cmp    %edx,%ebx
80102797:	7f ee                	jg     80102787 <read_head+0x2b>
  }
  brelse(buf);
80102799:	83 ec 0c             	sub    $0xc,%esp
8010279c:	50                   	push   %eax
8010279d:	e8 33 da ff ff       	call   801001d5 <brelse>
}
801027a2:	83 c4 10             	add    $0x10,%esp
801027a5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801027a8:	c9                   	leave  
801027a9:	c3                   	ret    

801027aa <install_trans>:
{
801027aa:	55                   	push   %ebp
801027ab:	89 e5                	mov    %esp,%ebp
801027ad:	57                   	push   %edi
801027ae:	56                   	push   %esi
801027af:	53                   	push   %ebx
801027b0:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
801027b3:	bb 00 00 00 00       	mov    $0x0,%ebx
801027b8:	eb 66                	jmp    80102820 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801027ba:	89 d8                	mov    %ebx,%eax
801027bc:	03 05 d4 26 13 80    	add    0x801326d4,%eax
801027c2:	83 c0 01             	add    $0x1,%eax
801027c5:	83 ec 08             	sub    $0x8,%esp
801027c8:	50                   	push   %eax
801027c9:	ff 35 e4 26 13 80    	pushl  0x801326e4
801027cf:	e8 98 d9 ff ff       	call   8010016c <bread>
801027d4:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801027d6:	83 c4 08             	add    $0x8,%esp
801027d9:	ff 34 9d ec 26 13 80 	pushl  -0x7fecd914(,%ebx,4)
801027e0:	ff 35 e4 26 13 80    	pushl  0x801326e4
801027e6:	e8 81 d9 ff ff       	call   8010016c <bread>
801027eb:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801027ed:	8d 57 5c             	lea    0x5c(%edi),%edx
801027f0:	8d 40 5c             	lea    0x5c(%eax),%eax
801027f3:	83 c4 0c             	add    $0xc,%esp
801027f6:	68 00 02 00 00       	push   $0x200
801027fb:	52                   	push   %edx
801027fc:	50                   	push   %eax
801027fd:	e8 40 17 00 00       	call   80103f42 <memmove>
    bwrite(dbuf);  // write dst to disk
80102802:	89 34 24             	mov    %esi,(%esp)
80102805:	e8 90 d9 ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
8010280a:	89 3c 24             	mov    %edi,(%esp)
8010280d:	e8 c3 d9 ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
80102812:	89 34 24             	mov    %esi,(%esp)
80102815:	e8 bb d9 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
8010281a:	83 c3 01             	add    $0x1,%ebx
8010281d:	83 c4 10             	add    $0x10,%esp
80102820:	39 1d e8 26 13 80    	cmp    %ebx,0x801326e8
80102826:	7f 92                	jg     801027ba <install_trans+0x10>
}
80102828:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010282b:	5b                   	pop    %ebx
8010282c:	5e                   	pop    %esi
8010282d:	5f                   	pop    %edi
8010282e:	5d                   	pop    %ebp
8010282f:	c3                   	ret    

80102830 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102830:	55                   	push   %ebp
80102831:	89 e5                	mov    %esp,%ebp
80102833:	53                   	push   %ebx
80102834:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102837:	ff 35 d4 26 13 80    	pushl  0x801326d4
8010283d:	ff 35 e4 26 13 80    	pushl  0x801326e4
80102843:	e8 24 d9 ff ff       	call   8010016c <bread>
80102848:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
8010284a:	8b 0d e8 26 13 80    	mov    0x801326e8,%ecx
80102850:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102853:	83 c4 10             	add    $0x10,%esp
80102856:	b8 00 00 00 00       	mov    $0x0,%eax
8010285b:	eb 0e                	jmp    8010286b <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
8010285d:	8b 14 85 ec 26 13 80 	mov    -0x7fecd914(,%eax,4),%edx
80102864:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
80102868:	83 c0 01             	add    $0x1,%eax
8010286b:	39 c1                	cmp    %eax,%ecx
8010286d:	7f ee                	jg     8010285d <write_head+0x2d>
  }
  bwrite(buf);
8010286f:	83 ec 0c             	sub    $0xc,%esp
80102872:	53                   	push   %ebx
80102873:	e8 22 d9 ff ff       	call   8010019a <bwrite>
  brelse(buf);
80102878:	89 1c 24             	mov    %ebx,(%esp)
8010287b:	e8 55 d9 ff ff       	call   801001d5 <brelse>
}
80102880:	83 c4 10             	add    $0x10,%esp
80102883:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102886:	c9                   	leave  
80102887:	c3                   	ret    

80102888 <recover_from_log>:

static void
recover_from_log(void)
{
80102888:	55                   	push   %ebp
80102889:	89 e5                	mov    %esp,%ebp
8010288b:	83 ec 08             	sub    $0x8,%esp
  read_head();
8010288e:	e8 c9 fe ff ff       	call   8010275c <read_head>
  install_trans(); // if committed, copy from log to disk
80102893:	e8 12 ff ff ff       	call   801027aa <install_trans>
  log.lh.n = 0;
80102898:	c7 05 e8 26 13 80 00 	movl   $0x0,0x801326e8
8010289f:	00 00 00 
  write_head(); // clear the log
801028a2:	e8 89 ff ff ff       	call   80102830 <write_head>
}
801028a7:	c9                   	leave  
801028a8:	c3                   	ret    

801028a9 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
801028a9:	55                   	push   %ebp
801028aa:	89 e5                	mov    %esp,%ebp
801028ac:	57                   	push   %edi
801028ad:	56                   	push   %esi
801028ae:	53                   	push   %ebx
801028af:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801028b2:	bb 00 00 00 00       	mov    $0x0,%ebx
801028b7:	eb 66                	jmp    8010291f <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
801028b9:	89 d8                	mov    %ebx,%eax
801028bb:	03 05 d4 26 13 80    	add    0x801326d4,%eax
801028c1:	83 c0 01             	add    $0x1,%eax
801028c4:	83 ec 08             	sub    $0x8,%esp
801028c7:	50                   	push   %eax
801028c8:	ff 35 e4 26 13 80    	pushl  0x801326e4
801028ce:	e8 99 d8 ff ff       	call   8010016c <bread>
801028d3:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801028d5:	83 c4 08             	add    $0x8,%esp
801028d8:	ff 34 9d ec 26 13 80 	pushl  -0x7fecd914(,%ebx,4)
801028df:	ff 35 e4 26 13 80    	pushl  0x801326e4
801028e5:	e8 82 d8 ff ff       	call   8010016c <bread>
801028ea:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
801028ec:	8d 50 5c             	lea    0x5c(%eax),%edx
801028ef:	8d 46 5c             	lea    0x5c(%esi),%eax
801028f2:	83 c4 0c             	add    $0xc,%esp
801028f5:	68 00 02 00 00       	push   $0x200
801028fa:	52                   	push   %edx
801028fb:	50                   	push   %eax
801028fc:	e8 41 16 00 00       	call   80103f42 <memmove>
    bwrite(to);  // write the log
80102901:	89 34 24             	mov    %esi,(%esp)
80102904:	e8 91 d8 ff ff       	call   8010019a <bwrite>
    brelse(from);
80102909:	89 3c 24             	mov    %edi,(%esp)
8010290c:	e8 c4 d8 ff ff       	call   801001d5 <brelse>
    brelse(to);
80102911:	89 34 24             	mov    %esi,(%esp)
80102914:	e8 bc d8 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102919:	83 c3 01             	add    $0x1,%ebx
8010291c:	83 c4 10             	add    $0x10,%esp
8010291f:	39 1d e8 26 13 80    	cmp    %ebx,0x801326e8
80102925:	7f 92                	jg     801028b9 <write_log+0x10>
  }
}
80102927:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010292a:	5b                   	pop    %ebx
8010292b:	5e                   	pop    %esi
8010292c:	5f                   	pop    %edi
8010292d:	5d                   	pop    %ebp
8010292e:	c3                   	ret    

8010292f <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
8010292f:	83 3d e8 26 13 80 00 	cmpl   $0x0,0x801326e8
80102936:	7e 26                	jle    8010295e <commit+0x2f>
{
80102938:	55                   	push   %ebp
80102939:	89 e5                	mov    %esp,%ebp
8010293b:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
8010293e:	e8 66 ff ff ff       	call   801028a9 <write_log>
    write_head();    // Write header to disk -- the real commit
80102943:	e8 e8 fe ff ff       	call   80102830 <write_head>
    install_trans(); // Now install writes to home locations
80102948:	e8 5d fe ff ff       	call   801027aa <install_trans>
    log.lh.n = 0;
8010294d:	c7 05 e8 26 13 80 00 	movl   $0x0,0x801326e8
80102954:	00 00 00 
    write_head();    // Erase the transaction from the log
80102957:	e8 d4 fe ff ff       	call   80102830 <write_head>
  }
}
8010295c:	c9                   	leave  
8010295d:	c3                   	ret    
8010295e:	f3 c3                	repz ret 

80102960 <initlog>:
{
80102960:	55                   	push   %ebp
80102961:	89 e5                	mov    %esp,%ebp
80102963:	53                   	push   %ebx
80102964:	83 ec 2c             	sub    $0x2c,%esp
80102967:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
8010296a:	68 e0 6b 10 80       	push   $0x80106be0
8010296f:	68 a0 26 13 80       	push   $0x801326a0
80102974:	e8 66 13 00 00       	call   80103cdf <initlock>
  readsb(dev, &sb);
80102979:	83 c4 08             	add    $0x8,%esp
8010297c:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010297f:	50                   	push   %eax
80102980:	53                   	push   %ebx
80102981:	e8 b0 e8 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
80102986:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102989:	a3 d4 26 13 80       	mov    %eax,0x801326d4
  log.size = sb.nlog;
8010298e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102991:	a3 d8 26 13 80       	mov    %eax,0x801326d8
  log.dev = dev;
80102996:	89 1d e4 26 13 80    	mov    %ebx,0x801326e4
  recover_from_log();
8010299c:	e8 e7 fe ff ff       	call   80102888 <recover_from_log>
}
801029a1:	83 c4 10             	add    $0x10,%esp
801029a4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801029a7:	c9                   	leave  
801029a8:	c3                   	ret    

801029a9 <begin_op>:
{
801029a9:	55                   	push   %ebp
801029aa:	89 e5                	mov    %esp,%ebp
801029ac:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
801029af:	68 a0 26 13 80       	push   $0x801326a0
801029b4:	e8 62 14 00 00       	call   80103e1b <acquire>
801029b9:	83 c4 10             	add    $0x10,%esp
801029bc:	eb 15                	jmp    801029d3 <begin_op+0x2a>
      sleep(&log, &log.lock);
801029be:	83 ec 08             	sub    $0x8,%esp
801029c1:	68 a0 26 13 80       	push   $0x801326a0
801029c6:	68 a0 26 13 80       	push   $0x801326a0
801029cb:	e8 de 0e 00 00       	call   801038ae <sleep>
801029d0:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
801029d3:	83 3d e0 26 13 80 00 	cmpl   $0x0,0x801326e0
801029da:	75 e2                	jne    801029be <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
801029dc:	a1 dc 26 13 80       	mov    0x801326dc,%eax
801029e1:	83 c0 01             	add    $0x1,%eax
801029e4:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801029e7:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
801029ea:	03 15 e8 26 13 80    	add    0x801326e8,%edx
801029f0:	83 fa 1e             	cmp    $0x1e,%edx
801029f3:	7e 17                	jle    80102a0c <begin_op+0x63>
      sleep(&log, &log.lock);
801029f5:	83 ec 08             	sub    $0x8,%esp
801029f8:	68 a0 26 13 80       	push   $0x801326a0
801029fd:	68 a0 26 13 80       	push   $0x801326a0
80102a02:	e8 a7 0e 00 00       	call   801038ae <sleep>
80102a07:	83 c4 10             	add    $0x10,%esp
80102a0a:	eb c7                	jmp    801029d3 <begin_op+0x2a>
      log.outstanding += 1;
80102a0c:	a3 dc 26 13 80       	mov    %eax,0x801326dc
      release(&log.lock);
80102a11:	83 ec 0c             	sub    $0xc,%esp
80102a14:	68 a0 26 13 80       	push   $0x801326a0
80102a19:	e8 62 14 00 00       	call   80103e80 <release>
}
80102a1e:	83 c4 10             	add    $0x10,%esp
80102a21:	c9                   	leave  
80102a22:	c3                   	ret    

80102a23 <end_op>:
{
80102a23:	55                   	push   %ebp
80102a24:	89 e5                	mov    %esp,%ebp
80102a26:	53                   	push   %ebx
80102a27:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102a2a:	68 a0 26 13 80       	push   $0x801326a0
80102a2f:	e8 e7 13 00 00       	call   80103e1b <acquire>
  log.outstanding -= 1;
80102a34:	a1 dc 26 13 80       	mov    0x801326dc,%eax
80102a39:	83 e8 01             	sub    $0x1,%eax
80102a3c:	a3 dc 26 13 80       	mov    %eax,0x801326dc
  if(log.committing)
80102a41:	8b 1d e0 26 13 80    	mov    0x801326e0,%ebx
80102a47:	83 c4 10             	add    $0x10,%esp
80102a4a:	85 db                	test   %ebx,%ebx
80102a4c:	75 2c                	jne    80102a7a <end_op+0x57>
  if(log.outstanding == 0){
80102a4e:	85 c0                	test   %eax,%eax
80102a50:	75 35                	jne    80102a87 <end_op+0x64>
    log.committing = 1;
80102a52:	c7 05 e0 26 13 80 01 	movl   $0x1,0x801326e0
80102a59:	00 00 00 
    do_commit = 1;
80102a5c:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102a61:	83 ec 0c             	sub    $0xc,%esp
80102a64:	68 a0 26 13 80       	push   $0x801326a0
80102a69:	e8 12 14 00 00       	call   80103e80 <release>
  if(do_commit){
80102a6e:	83 c4 10             	add    $0x10,%esp
80102a71:	85 db                	test   %ebx,%ebx
80102a73:	75 24                	jne    80102a99 <end_op+0x76>
}
80102a75:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a78:	c9                   	leave  
80102a79:	c3                   	ret    
    panic("log.committing");
80102a7a:	83 ec 0c             	sub    $0xc,%esp
80102a7d:	68 e4 6b 10 80       	push   $0x80106be4
80102a82:	e8 c1 d8 ff ff       	call   80100348 <panic>
    wakeup(&log);
80102a87:	83 ec 0c             	sub    $0xc,%esp
80102a8a:	68 a0 26 13 80       	push   $0x801326a0
80102a8f:	e8 7f 0f 00 00       	call   80103a13 <wakeup>
80102a94:	83 c4 10             	add    $0x10,%esp
80102a97:	eb c8                	jmp    80102a61 <end_op+0x3e>
    commit();
80102a99:	e8 91 fe ff ff       	call   8010292f <commit>
    acquire(&log.lock);
80102a9e:	83 ec 0c             	sub    $0xc,%esp
80102aa1:	68 a0 26 13 80       	push   $0x801326a0
80102aa6:	e8 70 13 00 00       	call   80103e1b <acquire>
    log.committing = 0;
80102aab:	c7 05 e0 26 13 80 00 	movl   $0x0,0x801326e0
80102ab2:	00 00 00 
    wakeup(&log);
80102ab5:	c7 04 24 a0 26 13 80 	movl   $0x801326a0,(%esp)
80102abc:	e8 52 0f 00 00       	call   80103a13 <wakeup>
    release(&log.lock);
80102ac1:	c7 04 24 a0 26 13 80 	movl   $0x801326a0,(%esp)
80102ac8:	e8 b3 13 00 00       	call   80103e80 <release>
80102acd:	83 c4 10             	add    $0x10,%esp
}
80102ad0:	eb a3                	jmp    80102a75 <end_op+0x52>

80102ad2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102ad2:	55                   	push   %ebp
80102ad3:	89 e5                	mov    %esp,%ebp
80102ad5:	53                   	push   %ebx
80102ad6:	83 ec 04             	sub    $0x4,%esp
80102ad9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102adc:	8b 15 e8 26 13 80    	mov    0x801326e8,%edx
80102ae2:	83 fa 1d             	cmp    $0x1d,%edx
80102ae5:	7f 45                	jg     80102b2c <log_write+0x5a>
80102ae7:	a1 d8 26 13 80       	mov    0x801326d8,%eax
80102aec:	83 e8 01             	sub    $0x1,%eax
80102aef:	39 c2                	cmp    %eax,%edx
80102af1:	7d 39                	jge    80102b2c <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102af3:	83 3d dc 26 13 80 00 	cmpl   $0x0,0x801326dc
80102afa:	7e 3d                	jle    80102b39 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102afc:	83 ec 0c             	sub    $0xc,%esp
80102aff:	68 a0 26 13 80       	push   $0x801326a0
80102b04:	e8 12 13 00 00       	call   80103e1b <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102b09:	83 c4 10             	add    $0x10,%esp
80102b0c:	b8 00 00 00 00       	mov    $0x0,%eax
80102b11:	8b 15 e8 26 13 80    	mov    0x801326e8,%edx
80102b17:	39 c2                	cmp    %eax,%edx
80102b19:	7e 2b                	jle    80102b46 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102b1b:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102b1e:	39 0c 85 ec 26 13 80 	cmp    %ecx,-0x7fecd914(,%eax,4)
80102b25:	74 1f                	je     80102b46 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102b27:	83 c0 01             	add    $0x1,%eax
80102b2a:	eb e5                	jmp    80102b11 <log_write+0x3f>
    panic("too big a transaction");
80102b2c:	83 ec 0c             	sub    $0xc,%esp
80102b2f:	68 f3 6b 10 80       	push   $0x80106bf3
80102b34:	e8 0f d8 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102b39:	83 ec 0c             	sub    $0xc,%esp
80102b3c:	68 09 6c 10 80       	push   $0x80106c09
80102b41:	e8 02 d8 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102b46:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102b49:	89 0c 85 ec 26 13 80 	mov    %ecx,-0x7fecd914(,%eax,4)
  if (i == log.lh.n)
80102b50:	39 c2                	cmp    %eax,%edx
80102b52:	74 18                	je     80102b6c <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102b54:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102b57:	83 ec 0c             	sub    $0xc,%esp
80102b5a:	68 a0 26 13 80       	push   $0x801326a0
80102b5f:	e8 1c 13 00 00       	call   80103e80 <release>
}
80102b64:	83 c4 10             	add    $0x10,%esp
80102b67:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102b6a:	c9                   	leave  
80102b6b:	c3                   	ret    
    log.lh.n++;
80102b6c:	83 c2 01             	add    $0x1,%edx
80102b6f:	89 15 e8 26 13 80    	mov    %edx,0x801326e8
80102b75:	eb dd                	jmp    80102b54 <log_write+0x82>

80102b77 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102b77:	55                   	push   %ebp
80102b78:	89 e5                	mov    %esp,%ebp
80102b7a:	53                   	push   %ebx
80102b7b:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102b7e:	68 8a 00 00 00       	push   $0x8a
80102b83:	68 8c a4 10 80       	push   $0x8010a48c
80102b88:	68 00 70 00 80       	push   $0x80007000
80102b8d:	e8 b0 13 00 00       	call   80103f42 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102b92:	83 c4 10             	add    $0x10,%esp
80102b95:	bb a0 27 13 80       	mov    $0x801327a0,%ebx
80102b9a:	eb 06                	jmp    80102ba2 <startothers+0x2b>
80102b9c:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102ba2:	69 05 20 2d 13 80 b0 	imul   $0xb0,0x80132d20,%eax
80102ba9:	00 00 00 
80102bac:	05 a0 27 13 80       	add    $0x801327a0,%eax
80102bb1:	39 d8                	cmp    %ebx,%eax
80102bb3:	76 57                	jbe    80102c0c <startothers+0x95>
    if(c == mycpu())  // We've started already.
80102bb5:	e8 d9 07 00 00       	call   80103393 <mycpu>
80102bba:	39 d8                	cmp    %ebx,%eax
80102bbc:	74 de                	je     80102b9c <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc(myproc()->pid); // need to pass the pid to kalloc?
80102bbe:	e8 47 08 00 00       	call   8010340a <myproc>
80102bc3:	83 ec 0c             	sub    $0xc,%esp
80102bc6:	ff 70 10             	pushl  0x10(%eax)
80102bc9:	e8 09 f6 ff ff       	call   801021d7 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102bce:	05 00 10 00 00       	add    $0x1000,%eax
80102bd3:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102bd8:	c7 05 f8 6f 00 80 50 	movl   $0x80102c50,0x80006ff8
80102bdf:	2c 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102be2:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102be9:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102bec:	83 c4 08             	add    $0x8,%esp
80102bef:	68 00 70 00 00       	push   $0x7000
80102bf4:	0f b6 03             	movzbl (%ebx),%eax
80102bf7:	50                   	push   %eax
80102bf8:	e8 bb f9 ff ff       	call   801025b8 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102bfd:	83 c4 10             	add    $0x10,%esp
80102c00:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102c06:	85 c0                	test   %eax,%eax
80102c08:	74 f6                	je     80102c00 <startothers+0x89>
80102c0a:	eb 90                	jmp    80102b9c <startothers+0x25>
      ;
  }
}
80102c0c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102c0f:	c9                   	leave  
80102c10:	c3                   	ret    

80102c11 <mpmain>:
{
80102c11:	55                   	push   %ebp
80102c12:	89 e5                	mov    %esp,%ebp
80102c14:	53                   	push   %ebx
80102c15:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102c18:	e8 d2 07 00 00       	call   801033ef <cpuid>
80102c1d:	89 c3                	mov    %eax,%ebx
80102c1f:	e8 cb 07 00 00       	call   801033ef <cpuid>
80102c24:	83 ec 04             	sub    $0x4,%esp
80102c27:	53                   	push   %ebx
80102c28:	50                   	push   %eax
80102c29:	68 24 6c 10 80       	push   $0x80106c24
80102c2e:	e8 d8 d9 ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102c33:	e8 61 24 00 00       	call   80105099 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102c38:	e8 56 07 00 00       	call   80103393 <mycpu>
80102c3d:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102c3f:	b8 01 00 00 00       	mov    $0x1,%eax
80102c44:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102c4b:	e8 39 0a 00 00       	call   80103689 <scheduler>

80102c50 <mpenter>:
{
80102c50:	55                   	push   %ebp
80102c51:	89 e5                	mov    %esp,%ebp
80102c53:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102c56:	e8 47 34 00 00       	call   801060a2 <switchkvm>
  seginit();
80102c5b:	e8 f6 32 00 00       	call   80105f56 <seginit>
  lapicinit();
80102c60:	e8 0a f8 ff ff       	call   8010246f <lapicinit>
  mpmain();
80102c65:	e8 a7 ff ff ff       	call   80102c11 <mpmain>

80102c6a <main>:
{
80102c6a:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102c6e:	83 e4 f0             	and    $0xfffffff0,%esp
80102c71:	ff 71 fc             	pushl  -0x4(%ecx)
80102c74:	55                   	push   %ebp
80102c75:	89 e5                	mov    %esp,%ebp
80102c77:	51                   	push   %ecx
80102c78:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102c7b:	68 00 00 40 80       	push   $0x80400000
80102c80:	68 c8 54 13 80       	push   $0x801354c8
80102c85:	e8 fb f4 ff ff       	call   80102185 <kinit1>
  kvmalloc();      // kernel page table
80102c8a:	e8 b9 38 00 00       	call   80106548 <kvmalloc>
  mpinit();        // detect other processors
80102c8f:	e8 c9 01 00 00       	call   80102e5d <mpinit>
  lapicinit();     // interrupt controller
80102c94:	e8 d6 f7 ff ff       	call   8010246f <lapicinit>
  seginit();       // segment descriptors
80102c99:	e8 b8 32 00 00       	call   80105f56 <seginit>
  picinit();       // disable pic
80102c9e:	e8 82 02 00 00       	call   80102f25 <picinit>
  ioapicinit();    // another interrupt controller
80102ca3:	e8 52 f2 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102ca8:	e8 e1 db ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102cad:	e8 95 26 00 00       	call   80105347 <uartinit>
  pinit();         // process table
80102cb2:	e8 c2 06 00 00       	call   80103379 <pinit>
  tvinit();        // trap vectors
80102cb7:	e8 2c 23 00 00       	call   80104fe8 <tvinit>
  binit();         // buffer cache
80102cbc:	e8 33 d4 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102cc1:	e8 4d df ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102cc6:	e8 35 f0 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102ccb:	e8 a7 fe ff ff       	call   80102b77 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102cd0:	83 c4 08             	add    $0x8,%esp
80102cd3:	68 00 00 00 8e       	push   $0x8e000000
80102cd8:	68 00 00 40 80       	push   $0x80400000
80102cdd:	e8 d5 f4 ff ff       	call   801021b7 <kinit2>
  userinit();      // first user process
80102ce2:	e8 47 07 00 00       	call   8010342e <userinit>
  mpmain();        // finish this processor's setup
80102ce7:	e8 25 ff ff ff       	call   80102c11 <mpmain>

80102cec <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102cec:	55                   	push   %ebp
80102ced:	89 e5                	mov    %esp,%ebp
80102cef:	56                   	push   %esi
80102cf0:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102cf1:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102cf6:	b9 00 00 00 00       	mov    $0x0,%ecx
80102cfb:	eb 09                	jmp    80102d06 <sum+0x1a>
    sum += addr[i];
80102cfd:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102d01:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102d03:	83 c1 01             	add    $0x1,%ecx
80102d06:	39 d1                	cmp    %edx,%ecx
80102d08:	7c f3                	jl     80102cfd <sum+0x11>
  return sum;
}
80102d0a:	89 d8                	mov    %ebx,%eax
80102d0c:	5b                   	pop    %ebx
80102d0d:	5e                   	pop    %esi
80102d0e:	5d                   	pop    %ebp
80102d0f:	c3                   	ret    

80102d10 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102d10:	55                   	push   %ebp
80102d11:	89 e5                	mov    %esp,%ebp
80102d13:	56                   	push   %esi
80102d14:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102d15:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102d1b:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102d1d:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102d1f:	eb 03                	jmp    80102d24 <mpsearch1+0x14>
80102d21:	83 c3 10             	add    $0x10,%ebx
80102d24:	39 f3                	cmp    %esi,%ebx
80102d26:	73 29                	jae    80102d51 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102d28:	83 ec 04             	sub    $0x4,%esp
80102d2b:	6a 04                	push   $0x4
80102d2d:	68 38 6c 10 80       	push   $0x80106c38
80102d32:	53                   	push   %ebx
80102d33:	e8 d5 11 00 00       	call   80103f0d <memcmp>
80102d38:	83 c4 10             	add    $0x10,%esp
80102d3b:	85 c0                	test   %eax,%eax
80102d3d:	75 e2                	jne    80102d21 <mpsearch1+0x11>
80102d3f:	ba 10 00 00 00       	mov    $0x10,%edx
80102d44:	89 d8                	mov    %ebx,%eax
80102d46:	e8 a1 ff ff ff       	call   80102cec <sum>
80102d4b:	84 c0                	test   %al,%al
80102d4d:	75 d2                	jne    80102d21 <mpsearch1+0x11>
80102d4f:	eb 05                	jmp    80102d56 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102d51:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102d56:	89 d8                	mov    %ebx,%eax
80102d58:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102d5b:	5b                   	pop    %ebx
80102d5c:	5e                   	pop    %esi
80102d5d:	5d                   	pop    %ebp
80102d5e:	c3                   	ret    

80102d5f <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102d5f:	55                   	push   %ebp
80102d60:	89 e5                	mov    %esp,%ebp
80102d62:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102d65:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102d6c:	c1 e0 08             	shl    $0x8,%eax
80102d6f:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102d76:	09 d0                	or     %edx,%eax
80102d78:	c1 e0 04             	shl    $0x4,%eax
80102d7b:	85 c0                	test   %eax,%eax
80102d7d:	74 1f                	je     80102d9e <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102d7f:	ba 00 04 00 00       	mov    $0x400,%edx
80102d84:	e8 87 ff ff ff       	call   80102d10 <mpsearch1>
80102d89:	85 c0                	test   %eax,%eax
80102d8b:	75 0f                	jne    80102d9c <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102d8d:	ba 00 00 01 00       	mov    $0x10000,%edx
80102d92:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102d97:	e8 74 ff ff ff       	call   80102d10 <mpsearch1>
}
80102d9c:	c9                   	leave  
80102d9d:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102d9e:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102da5:	c1 e0 08             	shl    $0x8,%eax
80102da8:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102daf:	09 d0                	or     %edx,%eax
80102db1:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102db4:	2d 00 04 00 00       	sub    $0x400,%eax
80102db9:	ba 00 04 00 00       	mov    $0x400,%edx
80102dbe:	e8 4d ff ff ff       	call   80102d10 <mpsearch1>
80102dc3:	85 c0                	test   %eax,%eax
80102dc5:	75 d5                	jne    80102d9c <mpsearch+0x3d>
80102dc7:	eb c4                	jmp    80102d8d <mpsearch+0x2e>

80102dc9 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102dc9:	55                   	push   %ebp
80102dca:	89 e5                	mov    %esp,%ebp
80102dcc:	57                   	push   %edi
80102dcd:	56                   	push   %esi
80102dce:	53                   	push   %ebx
80102dcf:	83 ec 1c             	sub    $0x1c,%esp
80102dd2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102dd5:	e8 85 ff ff ff       	call   80102d5f <mpsearch>
80102dda:	85 c0                	test   %eax,%eax
80102ddc:	74 5c                	je     80102e3a <mpconfig+0x71>
80102dde:	89 c7                	mov    %eax,%edi
80102de0:	8b 58 04             	mov    0x4(%eax),%ebx
80102de3:	85 db                	test   %ebx,%ebx
80102de5:	74 5a                	je     80102e41 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102de7:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102ded:	83 ec 04             	sub    $0x4,%esp
80102df0:	6a 04                	push   $0x4
80102df2:	68 3d 6c 10 80       	push   $0x80106c3d
80102df7:	56                   	push   %esi
80102df8:	e8 10 11 00 00       	call   80103f0d <memcmp>
80102dfd:	83 c4 10             	add    $0x10,%esp
80102e00:	85 c0                	test   %eax,%eax
80102e02:	75 44                	jne    80102e48 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102e04:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102e0b:	3c 01                	cmp    $0x1,%al
80102e0d:	0f 95 c2             	setne  %dl
80102e10:	3c 04                	cmp    $0x4,%al
80102e12:	0f 95 c0             	setne  %al
80102e15:	84 c2                	test   %al,%dl
80102e17:	75 36                	jne    80102e4f <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102e19:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102e20:	89 f0                	mov    %esi,%eax
80102e22:	e8 c5 fe ff ff       	call   80102cec <sum>
80102e27:	84 c0                	test   %al,%al
80102e29:	75 2b                	jne    80102e56 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102e2b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e2e:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102e30:	89 f0                	mov    %esi,%eax
80102e32:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e35:	5b                   	pop    %ebx
80102e36:	5e                   	pop    %esi
80102e37:	5f                   	pop    %edi
80102e38:	5d                   	pop    %ebp
80102e39:	c3                   	ret    
    return 0;
80102e3a:	be 00 00 00 00       	mov    $0x0,%esi
80102e3f:	eb ef                	jmp    80102e30 <mpconfig+0x67>
80102e41:	be 00 00 00 00       	mov    $0x0,%esi
80102e46:	eb e8                	jmp    80102e30 <mpconfig+0x67>
    return 0;
80102e48:	be 00 00 00 00       	mov    $0x0,%esi
80102e4d:	eb e1                	jmp    80102e30 <mpconfig+0x67>
    return 0;
80102e4f:	be 00 00 00 00       	mov    $0x0,%esi
80102e54:	eb da                	jmp    80102e30 <mpconfig+0x67>
    return 0;
80102e56:	be 00 00 00 00       	mov    $0x0,%esi
80102e5b:	eb d3                	jmp    80102e30 <mpconfig+0x67>

80102e5d <mpinit>:

void
mpinit(void)
{
80102e5d:	55                   	push   %ebp
80102e5e:	89 e5                	mov    %esp,%ebp
80102e60:	57                   	push   %edi
80102e61:	56                   	push   %esi
80102e62:	53                   	push   %ebx
80102e63:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102e66:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102e69:	e8 5b ff ff ff       	call   80102dc9 <mpconfig>
80102e6e:	85 c0                	test   %eax,%eax
80102e70:	74 19                	je     80102e8b <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102e72:	8b 50 24             	mov    0x24(%eax),%edx
80102e75:	89 15 88 26 13 80    	mov    %edx,0x80132688
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102e7b:	8d 50 2c             	lea    0x2c(%eax),%edx
80102e7e:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102e82:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102e84:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102e89:	eb 34                	jmp    80102ebf <mpinit+0x62>
    panic("Expect to run on an SMP");
80102e8b:	83 ec 0c             	sub    $0xc,%esp
80102e8e:	68 42 6c 10 80       	push   $0x80106c42
80102e93:	e8 b0 d4 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102e98:	8b 35 20 2d 13 80    	mov    0x80132d20,%esi
80102e9e:	83 fe 07             	cmp    $0x7,%esi
80102ea1:	7f 19                	jg     80102ebc <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102ea3:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102ea7:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102ead:	88 87 a0 27 13 80    	mov    %al,-0x7fecd860(%edi)
        ncpu++;
80102eb3:	83 c6 01             	add    $0x1,%esi
80102eb6:	89 35 20 2d 13 80    	mov    %esi,0x80132d20
      }
      p += sizeof(struct mpproc);
80102ebc:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102ebf:	39 ca                	cmp    %ecx,%edx
80102ec1:	73 2b                	jae    80102eee <mpinit+0x91>
    switch(*p){
80102ec3:	0f b6 02             	movzbl (%edx),%eax
80102ec6:	3c 04                	cmp    $0x4,%al
80102ec8:	77 1d                	ja     80102ee7 <mpinit+0x8a>
80102eca:	0f b6 c0             	movzbl %al,%eax
80102ecd:	ff 24 85 7c 6c 10 80 	jmp    *-0x7fef9384(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102ed4:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102ed8:	a2 80 27 13 80       	mov    %al,0x80132780
      p += sizeof(struct mpioapic);
80102edd:	83 c2 08             	add    $0x8,%edx
      continue;
80102ee0:	eb dd                	jmp    80102ebf <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102ee2:	83 c2 08             	add    $0x8,%edx
      continue;
80102ee5:	eb d8                	jmp    80102ebf <mpinit+0x62>
    default:
      ismp = 0;
80102ee7:	bb 00 00 00 00       	mov    $0x0,%ebx
80102eec:	eb d1                	jmp    80102ebf <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102eee:	85 db                	test   %ebx,%ebx
80102ef0:	74 26                	je     80102f18 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102ef2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102ef5:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102ef9:	74 15                	je     80102f10 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102efb:	b8 70 00 00 00       	mov    $0x70,%eax
80102f00:	ba 22 00 00 00       	mov    $0x22,%edx
80102f05:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102f06:	ba 23 00 00 00       	mov    $0x23,%edx
80102f0b:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102f0c:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102f0f:	ee                   	out    %al,(%dx)
  }
}
80102f10:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f13:	5b                   	pop    %ebx
80102f14:	5e                   	pop    %esi
80102f15:	5f                   	pop    %edi
80102f16:	5d                   	pop    %ebp
80102f17:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102f18:	83 ec 0c             	sub    $0xc,%esp
80102f1b:	68 5c 6c 10 80       	push   $0x80106c5c
80102f20:	e8 23 d4 ff ff       	call   80100348 <panic>

80102f25 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102f25:	55                   	push   %ebp
80102f26:	89 e5                	mov    %esp,%ebp
80102f28:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102f2d:	ba 21 00 00 00       	mov    $0x21,%edx
80102f32:	ee                   	out    %al,(%dx)
80102f33:	ba a1 00 00 00       	mov    $0xa1,%edx
80102f38:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102f39:	5d                   	pop    %ebp
80102f3a:	c3                   	ret    

80102f3b <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102f3b:	55                   	push   %ebp
80102f3c:	89 e5                	mov    %esp,%ebp
80102f3e:	57                   	push   %edi
80102f3f:	56                   	push   %esi
80102f40:	53                   	push   %ebx
80102f41:	83 ec 0c             	sub    $0xc,%esp
80102f44:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102f47:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102f4a:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102f50:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102f56:	e8 d2 dc ff ff       	call   80100c2d <filealloc>
80102f5b:	89 03                	mov    %eax,(%ebx)
80102f5d:	85 c0                	test   %eax,%eax
80102f5f:	74 1e                	je     80102f7f <pipealloc+0x44>
80102f61:	e8 c7 dc ff ff       	call   80100c2d <filealloc>
80102f66:	89 06                	mov    %eax,(%esi)
80102f68:	85 c0                	test   %eax,%eax
80102f6a:	74 13                	je     80102f7f <pipealloc+0x44>
    goto bad;
  // need to pass the pid to kalloc?
  if((p = (struct pipe*)kalloc(0)) == 0)
80102f6c:	83 ec 0c             	sub    $0xc,%esp
80102f6f:	6a 00                	push   $0x0
80102f71:	e8 61 f2 ff ff       	call   801021d7 <kalloc>
80102f76:	89 c7                	mov    %eax,%edi
80102f78:	83 c4 10             	add    $0x10,%esp
80102f7b:	85 c0                	test   %eax,%eax
80102f7d:	75 35                	jne    80102fb4 <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102f7f:	8b 03                	mov    (%ebx),%eax
80102f81:	85 c0                	test   %eax,%eax
80102f83:	74 0c                	je     80102f91 <pipealloc+0x56>
    fileclose(*f0);
80102f85:	83 ec 0c             	sub    $0xc,%esp
80102f88:	50                   	push   %eax
80102f89:	e8 45 dd ff ff       	call   80100cd3 <fileclose>
80102f8e:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102f91:	8b 06                	mov    (%esi),%eax
80102f93:	85 c0                	test   %eax,%eax
80102f95:	0f 84 8b 00 00 00    	je     80103026 <pipealloc+0xeb>
    fileclose(*f1);
80102f9b:	83 ec 0c             	sub    $0xc,%esp
80102f9e:	50                   	push   %eax
80102f9f:	e8 2f dd ff ff       	call   80100cd3 <fileclose>
80102fa4:	83 c4 10             	add    $0x10,%esp
  return -1;
80102fa7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102fac:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102faf:	5b                   	pop    %ebx
80102fb0:	5e                   	pop    %esi
80102fb1:	5f                   	pop    %edi
80102fb2:	5d                   	pop    %ebp
80102fb3:	c3                   	ret    
  p->readopen = 1;
80102fb4:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102fbb:	00 00 00 
  p->writeopen = 1;
80102fbe:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102fc5:	00 00 00 
  p->nwrite = 0;
80102fc8:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102fcf:	00 00 00 
  p->nread = 0;
80102fd2:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102fd9:	00 00 00 
  initlock(&p->lock, "pipe");
80102fdc:	83 ec 08             	sub    $0x8,%esp
80102fdf:	68 90 6c 10 80       	push   $0x80106c90
80102fe4:	50                   	push   %eax
80102fe5:	e8 f5 0c 00 00       	call   80103cdf <initlock>
  (*f0)->type = FD_PIPE;
80102fea:	8b 03                	mov    (%ebx),%eax
80102fec:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102ff2:	8b 03                	mov    (%ebx),%eax
80102ff4:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102ff8:	8b 03                	mov    (%ebx),%eax
80102ffa:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102ffe:	8b 03                	mov    (%ebx),%eax
80103000:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103003:	8b 06                	mov    (%esi),%eax
80103005:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
8010300b:	8b 06                	mov    (%esi),%eax
8010300d:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103011:	8b 06                	mov    (%esi),%eax
80103013:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103017:	8b 06                	mov    (%esi),%eax
80103019:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
8010301c:	83 c4 10             	add    $0x10,%esp
8010301f:	b8 00 00 00 00       	mov    $0x0,%eax
80103024:	eb 86                	jmp    80102fac <pipealloc+0x71>
  return -1;
80103026:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010302b:	e9 7c ff ff ff       	jmp    80102fac <pipealloc+0x71>

80103030 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103030:	55                   	push   %ebp
80103031:	89 e5                	mov    %esp,%ebp
80103033:	53                   	push   %ebx
80103034:	83 ec 10             	sub    $0x10,%esp
80103037:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
8010303a:	53                   	push   %ebx
8010303b:	e8 db 0d 00 00       	call   80103e1b <acquire>
  if(writable){
80103040:	83 c4 10             	add    $0x10,%esp
80103043:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103047:	74 3f                	je     80103088 <pipeclose+0x58>
    p->writeopen = 0;
80103049:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80103050:	00 00 00 
    wakeup(&p->nread);
80103053:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103059:	83 ec 0c             	sub    $0xc,%esp
8010305c:	50                   	push   %eax
8010305d:	e8 b1 09 00 00       	call   80103a13 <wakeup>
80103062:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103065:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
8010306c:	75 09                	jne    80103077 <pipeclose+0x47>
8010306e:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80103075:	74 2f                	je     801030a6 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80103077:	83 ec 0c             	sub    $0xc,%esp
8010307a:	53                   	push   %ebx
8010307b:	e8 00 0e 00 00       	call   80103e80 <release>
80103080:	83 c4 10             	add    $0x10,%esp
}
80103083:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103086:	c9                   	leave  
80103087:	c3                   	ret    
    p->readopen = 0;
80103088:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
8010308f:	00 00 00 
    wakeup(&p->nwrite);
80103092:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103098:	83 ec 0c             	sub    $0xc,%esp
8010309b:	50                   	push   %eax
8010309c:	e8 72 09 00 00       	call   80103a13 <wakeup>
801030a1:	83 c4 10             	add    $0x10,%esp
801030a4:	eb bf                	jmp    80103065 <pipeclose+0x35>
    release(&p->lock);
801030a6:	83 ec 0c             	sub    $0xc,%esp
801030a9:	53                   	push   %ebx
801030aa:	e8 d1 0d 00 00       	call   80103e80 <release>
    kfree((char*)p);
801030af:	89 1c 24             	mov    %ebx,(%esp)
801030b2:	e8 0b ef ff ff       	call   80101fc2 <kfree>
801030b7:	83 c4 10             	add    $0x10,%esp
801030ba:	eb c7                	jmp    80103083 <pipeclose+0x53>

801030bc <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
801030bc:	55                   	push   %ebp
801030bd:	89 e5                	mov    %esp,%ebp
801030bf:	57                   	push   %edi
801030c0:	56                   	push   %esi
801030c1:	53                   	push   %ebx
801030c2:	83 ec 18             	sub    $0x18,%esp
801030c5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801030c8:	89 de                	mov    %ebx,%esi
801030ca:	53                   	push   %ebx
801030cb:	e8 4b 0d 00 00       	call   80103e1b <acquire>
  for(i = 0; i < n; i++){
801030d0:	83 c4 10             	add    $0x10,%esp
801030d3:	bf 00 00 00 00       	mov    $0x0,%edi
801030d8:	3b 7d 10             	cmp    0x10(%ebp),%edi
801030db:	0f 8d 88 00 00 00    	jge    80103169 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801030e1:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
801030e7:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
801030ed:	05 00 02 00 00       	add    $0x200,%eax
801030f2:	39 c2                	cmp    %eax,%edx
801030f4:	75 51                	jne    80103147 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
801030f6:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
801030fd:	74 2f                	je     8010312e <pipewrite+0x72>
801030ff:	e8 06 03 00 00       	call   8010340a <myproc>
80103104:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103108:	75 24                	jne    8010312e <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
8010310a:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103110:	83 ec 0c             	sub    $0xc,%esp
80103113:	50                   	push   %eax
80103114:	e8 fa 08 00 00       	call   80103a13 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103119:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010311f:	83 c4 08             	add    $0x8,%esp
80103122:	56                   	push   %esi
80103123:	50                   	push   %eax
80103124:	e8 85 07 00 00       	call   801038ae <sleep>
80103129:	83 c4 10             	add    $0x10,%esp
8010312c:	eb b3                	jmp    801030e1 <pipewrite+0x25>
        release(&p->lock);
8010312e:	83 ec 0c             	sub    $0xc,%esp
80103131:	53                   	push   %ebx
80103132:	e8 49 0d 00 00       	call   80103e80 <release>
        return -1;
80103137:	83 c4 10             	add    $0x10,%esp
8010313a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
8010313f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103142:	5b                   	pop    %ebx
80103143:	5e                   	pop    %esi
80103144:	5f                   	pop    %edi
80103145:	5d                   	pop    %ebp
80103146:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103147:	8d 42 01             	lea    0x1(%edx),%eax
8010314a:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80103150:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80103156:	8b 45 0c             	mov    0xc(%ebp),%eax
80103159:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
8010315d:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80103161:	83 c7 01             	add    $0x1,%edi
80103164:	e9 6f ff ff ff       	jmp    801030d8 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103169:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010316f:	83 ec 0c             	sub    $0xc,%esp
80103172:	50                   	push   %eax
80103173:	e8 9b 08 00 00       	call   80103a13 <wakeup>
  release(&p->lock);
80103178:	89 1c 24             	mov    %ebx,(%esp)
8010317b:	e8 00 0d 00 00       	call   80103e80 <release>
  return n;
80103180:	83 c4 10             	add    $0x10,%esp
80103183:	8b 45 10             	mov    0x10(%ebp),%eax
80103186:	eb b7                	jmp    8010313f <pipewrite+0x83>

80103188 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103188:	55                   	push   %ebp
80103189:	89 e5                	mov    %esp,%ebp
8010318b:	57                   	push   %edi
8010318c:	56                   	push   %esi
8010318d:	53                   	push   %ebx
8010318e:	83 ec 18             	sub    $0x18,%esp
80103191:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103194:	89 df                	mov    %ebx,%edi
80103196:	53                   	push   %ebx
80103197:	e8 7f 0c 00 00       	call   80103e1b <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010319c:	83 c4 10             	add    $0x10,%esp
8010319f:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
801031a5:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
801031ab:	75 3d                	jne    801031ea <piperead+0x62>
801031ad:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
801031b3:	85 f6                	test   %esi,%esi
801031b5:	74 38                	je     801031ef <piperead+0x67>
    if(myproc()->killed){
801031b7:	e8 4e 02 00 00       	call   8010340a <myproc>
801031bc:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801031c0:	75 15                	jne    801031d7 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801031c2:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801031c8:	83 ec 08             	sub    $0x8,%esp
801031cb:	57                   	push   %edi
801031cc:	50                   	push   %eax
801031cd:	e8 dc 06 00 00       	call   801038ae <sleep>
801031d2:	83 c4 10             	add    $0x10,%esp
801031d5:	eb c8                	jmp    8010319f <piperead+0x17>
      release(&p->lock);
801031d7:	83 ec 0c             	sub    $0xc,%esp
801031da:	53                   	push   %ebx
801031db:	e8 a0 0c 00 00       	call   80103e80 <release>
      return -1;
801031e0:	83 c4 10             	add    $0x10,%esp
801031e3:	be ff ff ff ff       	mov    $0xffffffff,%esi
801031e8:	eb 50                	jmp    8010323a <piperead+0xb2>
801031ea:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801031ef:	3b 75 10             	cmp    0x10(%ebp),%esi
801031f2:	7d 2c                	jge    80103220 <piperead+0x98>
    if(p->nread == p->nwrite)
801031f4:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
801031fa:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
80103200:	74 1e                	je     80103220 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80103202:	8d 50 01             	lea    0x1(%eax),%edx
80103205:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
8010320b:	25 ff 01 00 00       	and    $0x1ff,%eax
80103210:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
80103215:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103218:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010321b:	83 c6 01             	add    $0x1,%esi
8010321e:	eb cf                	jmp    801031ef <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103220:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103226:	83 ec 0c             	sub    $0xc,%esp
80103229:	50                   	push   %eax
8010322a:	e8 e4 07 00 00       	call   80103a13 <wakeup>
  release(&p->lock);
8010322f:	89 1c 24             	mov    %ebx,(%esp)
80103232:	e8 49 0c 00 00       	call   80103e80 <release>
  return i;
80103237:	83 c4 10             	add    $0x10,%esp
}
8010323a:	89 f0                	mov    %esi,%eax
8010323c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010323f:	5b                   	pop    %ebx
80103240:	5e                   	pop    %esi
80103241:	5f                   	pop    %edi
80103242:	5d                   	pop    %ebp
80103243:	c3                   	ret    

80103244 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80103244:	55                   	push   %ebp
80103245:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103247:	ba 74 2d 13 80       	mov    $0x80132d74,%edx
8010324c:	eb 03                	jmp    80103251 <wakeup1+0xd>
8010324e:	83 c2 7c             	add    $0x7c,%edx
80103251:	81 fa 74 4c 13 80    	cmp    $0x80134c74,%edx
80103257:	73 14                	jae    8010326d <wakeup1+0x29>
    if (p->state == SLEEPING && p->chan == chan)
80103259:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
8010325d:	75 ef                	jne    8010324e <wakeup1+0xa>
8010325f:	39 42 20             	cmp    %eax,0x20(%edx)
80103262:	75 ea                	jne    8010324e <wakeup1+0xa>
      p->state = RUNNABLE;
80103264:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
8010326b:	eb e1                	jmp    8010324e <wakeup1+0xa>
}
8010326d:	5d                   	pop    %ebp
8010326e:	c3                   	ret    

8010326f <allocproc>:
{
8010326f:	55                   	push   %ebp
80103270:	89 e5                	mov    %esp,%ebp
80103272:	53                   	push   %ebx
80103273:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
80103276:	68 40 2d 13 80       	push   $0x80132d40
8010327b:	e8 9b 0b 00 00       	call   80103e1b <acquire>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103280:	83 c4 10             	add    $0x10,%esp
80103283:	bb 74 2d 13 80       	mov    $0x80132d74,%ebx
80103288:	81 fb 74 4c 13 80    	cmp    $0x80134c74,%ebx
8010328e:	73 0b                	jae    8010329b <allocproc+0x2c>
    if (p->state == UNUSED)
80103290:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
80103294:	74 1c                	je     801032b2 <allocproc+0x43>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103296:	83 c3 7c             	add    $0x7c,%ebx
80103299:	eb ed                	jmp    80103288 <allocproc+0x19>
  release(&ptable.lock);
8010329b:	83 ec 0c             	sub    $0xc,%esp
8010329e:	68 40 2d 13 80       	push   $0x80132d40
801032a3:	e8 d8 0b 00 00       	call   80103e80 <release>
  return 0;
801032a8:	83 c4 10             	add    $0x10,%esp
801032ab:	bb 00 00 00 00       	mov    $0x0,%ebx
801032b0:	eb 6f                	jmp    80103321 <allocproc+0xb2>
  p->state = EMBRYO;
801032b2:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
801032b9:	a1 04 a0 10 80       	mov    0x8010a004,%eax
801032be:	8d 50 01             	lea    0x1(%eax),%edx
801032c1:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
801032c7:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
801032ca:	83 ec 0c             	sub    $0xc,%esp
801032cd:	68 40 2d 13 80       	push   $0x80132d40
801032d2:	e8 a9 0b 00 00       	call   80103e80 <release>
  if ((p->kstack = kalloc(p->pid)) == 0)
801032d7:	83 c4 04             	add    $0x4,%esp
801032da:	ff 73 10             	pushl  0x10(%ebx)
801032dd:	e8 f5 ee ff ff       	call   801021d7 <kalloc>
801032e2:	89 43 08             	mov    %eax,0x8(%ebx)
801032e5:	83 c4 10             	add    $0x10,%esp
801032e8:	85 c0                	test   %eax,%eax
801032ea:	74 3c                	je     80103328 <allocproc+0xb9>
  sp -= sizeof *p->tf;
801032ec:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe *)sp;
801032f2:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint *)sp = (uint)trapret;
801032f5:	c7 80 b0 0f 00 00 dd 	movl   $0x80104fdd,0xfb0(%eax)
801032fc:	4f 10 80 
  sp -= sizeof *p->context;
801032ff:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context *)sp;
80103304:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
80103307:	83 ec 04             	sub    $0x4,%esp
8010330a:	6a 14                	push   $0x14
8010330c:	6a 00                	push   $0x0
8010330e:	50                   	push   %eax
8010330f:	e8 b3 0b 00 00       	call   80103ec7 <memset>
  p->context->eip = (uint)forkret;
80103314:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103317:	c7 40 10 36 33 10 80 	movl   $0x80103336,0x10(%eax)
  return p;
8010331e:	83 c4 10             	add    $0x10,%esp
}
80103321:	89 d8                	mov    %ebx,%eax
80103323:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103326:	c9                   	leave  
80103327:	c3                   	ret    
    p->state = UNUSED;
80103328:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
8010332f:	bb 00 00 00 00       	mov    $0x0,%ebx
80103334:	eb eb                	jmp    80103321 <allocproc+0xb2>

80103336 <forkret>:
{
80103336:	55                   	push   %ebp
80103337:	89 e5                	mov    %esp,%ebp
80103339:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
8010333c:	68 40 2d 13 80       	push   $0x80132d40
80103341:	e8 3a 0b 00 00       	call   80103e80 <release>
  if (first)
80103346:	83 c4 10             	add    $0x10,%esp
80103349:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
80103350:	75 02                	jne    80103354 <forkret+0x1e>
}
80103352:	c9                   	leave  
80103353:	c3                   	ret    
    first = 0;
80103354:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
8010335b:	00 00 00 
    iinit(ROOTDEV);
8010335e:	83 ec 0c             	sub    $0xc,%esp
80103361:	6a 01                	push   $0x1
80103363:	e8 84 df ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
80103368:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010336f:	e8 ec f5 ff ff       	call   80102960 <initlog>
80103374:	83 c4 10             	add    $0x10,%esp
}
80103377:	eb d9                	jmp    80103352 <forkret+0x1c>

80103379 <pinit>:
{
80103379:	55                   	push   %ebp
8010337a:	89 e5                	mov    %esp,%ebp
8010337c:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
8010337f:	68 95 6c 10 80       	push   $0x80106c95
80103384:	68 40 2d 13 80       	push   $0x80132d40
80103389:	e8 51 09 00 00       	call   80103cdf <initlock>
}
8010338e:	83 c4 10             	add    $0x10,%esp
80103391:	c9                   	leave  
80103392:	c3                   	ret    

80103393 <mycpu>:
{
80103393:	55                   	push   %ebp
80103394:	89 e5                	mov    %esp,%ebp
80103396:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103399:	9c                   	pushf  
8010339a:	58                   	pop    %eax
  if (readeflags() & FL_IF)
8010339b:	f6 c4 02             	test   $0x2,%ah
8010339e:	75 28                	jne    801033c8 <mycpu+0x35>
  apicid = lapicid();
801033a0:	e8 d4 f1 ff ff       	call   80102579 <lapicid>
  for (i = 0; i < ncpu; ++i)
801033a5:	ba 00 00 00 00       	mov    $0x0,%edx
801033aa:	39 15 20 2d 13 80    	cmp    %edx,0x80132d20
801033b0:	7e 23                	jle    801033d5 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
801033b2:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801033b8:	0f b6 89 a0 27 13 80 	movzbl -0x7fecd860(%ecx),%ecx
801033bf:	39 c1                	cmp    %eax,%ecx
801033c1:	74 1f                	je     801033e2 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i)
801033c3:	83 c2 01             	add    $0x1,%edx
801033c6:	eb e2                	jmp    801033aa <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
801033c8:	83 ec 0c             	sub    $0xc,%esp
801033cb:	68 78 6d 10 80       	push   $0x80106d78
801033d0:	e8 73 cf ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
801033d5:	83 ec 0c             	sub    $0xc,%esp
801033d8:	68 9c 6c 10 80       	push   $0x80106c9c
801033dd:	e8 66 cf ff ff       	call   80100348 <panic>
      return &cpus[i];
801033e2:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
801033e8:	05 a0 27 13 80       	add    $0x801327a0,%eax
}
801033ed:	c9                   	leave  
801033ee:	c3                   	ret    

801033ef <cpuid>:
{
801033ef:	55                   	push   %ebp
801033f0:	89 e5                	mov    %esp,%ebp
801033f2:	83 ec 08             	sub    $0x8,%esp
  return mycpu() - cpus;
801033f5:	e8 99 ff ff ff       	call   80103393 <mycpu>
801033fa:	2d a0 27 13 80       	sub    $0x801327a0,%eax
801033ff:	c1 f8 04             	sar    $0x4,%eax
80103402:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
80103408:	c9                   	leave  
80103409:	c3                   	ret    

8010340a <myproc>:
{
8010340a:	55                   	push   %ebp
8010340b:	89 e5                	mov    %esp,%ebp
8010340d:	53                   	push   %ebx
8010340e:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103411:	e8 28 09 00 00       	call   80103d3e <pushcli>
  c = mycpu();
80103416:	e8 78 ff ff ff       	call   80103393 <mycpu>
  p = c->proc;
8010341b:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103421:	e8 55 09 00 00       	call   80103d7b <popcli>
}
80103426:	89 d8                	mov    %ebx,%eax
80103428:	83 c4 04             	add    $0x4,%esp
8010342b:	5b                   	pop    %ebx
8010342c:	5d                   	pop    %ebp
8010342d:	c3                   	ret    

8010342e <userinit>:
{
8010342e:	55                   	push   %ebp
8010342f:	89 e5                	mov    %esp,%ebp
80103431:	53                   	push   %ebx
80103432:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
80103435:	e8 35 fe ff ff       	call   8010326f <allocproc>
8010343a:	89 c3                	mov    %eax,%ebx
  initproc = p;
8010343c:	a3 b8 a5 10 80       	mov    %eax,0x8010a5b8
  if ((p->pgdir = setupkvm()) == 0)
80103441:	e8 94 30 00 00       	call   801064da <setupkvm>
80103446:	89 43 04             	mov    %eax,0x4(%ebx)
80103449:	85 c0                	test   %eax,%eax
8010344b:	0f 84 b7 00 00 00    	je     80103508 <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103451:	83 ec 04             	sub    $0x4,%esp
80103454:	68 2c 00 00 00       	push   $0x2c
80103459:	68 60 a4 10 80       	push   $0x8010a460
8010345e:	50                   	push   %eax
8010345f:	e8 68 2d 00 00       	call   801061cc <inituvm>
  p->sz = PGSIZE;
80103464:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
8010346a:	83 c4 0c             	add    $0xc,%esp
8010346d:	6a 4c                	push   $0x4c
8010346f:	6a 00                	push   $0x0
80103471:	ff 73 18             	pushl  0x18(%ebx)
80103474:	e8 4e 0a 00 00       	call   80103ec7 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80103479:	8b 43 18             	mov    0x18(%ebx),%eax
8010347c:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80103482:	8b 43 18             	mov    0x18(%ebx),%eax
80103485:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010348b:	8b 43 18             	mov    0x18(%ebx),%eax
8010348e:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103492:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80103496:	8b 43 18             	mov    0x18(%ebx),%eax
80103499:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
8010349d:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801034a1:	8b 43 18             	mov    0x18(%ebx),%eax
801034a4:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801034ab:	8b 43 18             	mov    0x18(%ebx),%eax
801034ae:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0; // beginning of initcode.S
801034b5:	8b 43 18             	mov    0x18(%ebx),%eax
801034b8:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
801034bf:	8d 43 6c             	lea    0x6c(%ebx),%eax
801034c2:	83 c4 0c             	add    $0xc,%esp
801034c5:	6a 10                	push   $0x10
801034c7:	68 c5 6c 10 80       	push   $0x80106cc5
801034cc:	50                   	push   %eax
801034cd:	e8 5c 0b 00 00       	call   8010402e <safestrcpy>
  p->cwd = namei("/");
801034d2:	c7 04 24 ce 6c 10 80 	movl   $0x80106cce,(%esp)
801034d9:	e8 03 e7 ff ff       	call   80101be1 <namei>
801034de:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
801034e1:	c7 04 24 40 2d 13 80 	movl   $0x80132d40,(%esp)
801034e8:	e8 2e 09 00 00       	call   80103e1b <acquire>
  p->state = RUNNABLE;
801034ed:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
801034f4:	c7 04 24 40 2d 13 80 	movl   $0x80132d40,(%esp)
801034fb:	e8 80 09 00 00       	call   80103e80 <release>
}
80103500:	83 c4 10             	add    $0x10,%esp
80103503:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103506:	c9                   	leave  
80103507:	c3                   	ret    
    panic("userinit: out of memory?");
80103508:	83 ec 0c             	sub    $0xc,%esp
8010350b:	68 ac 6c 10 80       	push   $0x80106cac
80103510:	e8 33 ce ff ff       	call   80100348 <panic>

80103515 <growproc>:
{
80103515:	55                   	push   %ebp
80103516:	89 e5                	mov    %esp,%ebp
80103518:	56                   	push   %esi
80103519:	53                   	push   %ebx
8010351a:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
8010351d:	e8 e8 fe ff ff       	call   8010340a <myproc>
80103522:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103524:	8b 00                	mov    (%eax),%eax
  if (n > 0)
80103526:	85 f6                	test   %esi,%esi
80103528:	7f 21                	jg     8010354b <growproc+0x36>
  else if (n < 0)
8010352a:	85 f6                	test   %esi,%esi
8010352c:	79 33                	jns    80103561 <growproc+0x4c>
    if ((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010352e:	83 ec 04             	sub    $0x4,%esp
80103531:	01 c6                	add    %eax,%esi
80103533:	56                   	push   %esi
80103534:	50                   	push   %eax
80103535:	ff 73 04             	pushl  0x4(%ebx)
80103538:	e8 98 2d 00 00       	call   801062d5 <deallocuvm>
8010353d:	83 c4 10             	add    $0x10,%esp
80103540:	85 c0                	test   %eax,%eax
80103542:	75 1d                	jne    80103561 <growproc+0x4c>
      return -1;
80103544:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103549:	eb 29                	jmp    80103574 <growproc+0x5f>
    if ((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010354b:	83 ec 04             	sub    $0x4,%esp
8010354e:	01 c6                	add    %eax,%esi
80103550:	56                   	push   %esi
80103551:	50                   	push   %eax
80103552:	ff 73 04             	pushl  0x4(%ebx)
80103555:	e8 0d 2e 00 00       	call   80106367 <allocuvm>
8010355a:	83 c4 10             	add    $0x10,%esp
8010355d:	85 c0                	test   %eax,%eax
8010355f:	74 1a                	je     8010357b <growproc+0x66>
  curproc->sz = sz;
80103561:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
80103563:	83 ec 0c             	sub    $0xc,%esp
80103566:	53                   	push   %ebx
80103567:	e8 48 2b 00 00       	call   801060b4 <switchuvm>
  return 0;
8010356c:	83 c4 10             	add    $0x10,%esp
8010356f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103574:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103577:	5b                   	pop    %ebx
80103578:	5e                   	pop    %esi
80103579:	5d                   	pop    %ebp
8010357a:	c3                   	ret    
      return -1;
8010357b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103580:	eb f2                	jmp    80103574 <growproc+0x5f>

80103582 <fork>:
{
80103582:	55                   	push   %ebp
80103583:	89 e5                	mov    %esp,%ebp
80103585:	57                   	push   %edi
80103586:	56                   	push   %esi
80103587:	53                   	push   %ebx
80103588:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
8010358b:	e8 7a fe ff ff       	call   8010340a <myproc>
80103590:	89 c3                	mov    %eax,%ebx
  if ((np = allocproc()) == 0)
80103592:	e8 d8 fc ff ff       	call   8010326f <allocproc>
80103597:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010359a:	85 c0                	test   %eax,%eax
8010359c:	0f 84 e0 00 00 00    	je     80103682 <fork+0x100>
801035a2:	89 c7                	mov    %eax,%edi
  if ((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0)
801035a4:	83 ec 08             	sub    $0x8,%esp
801035a7:	ff 33                	pushl  (%ebx)
801035a9:	ff 73 04             	pushl  0x4(%ebx)
801035ac:	e8 da 2f 00 00       	call   8010658b <copyuvm>
801035b1:	89 47 04             	mov    %eax,0x4(%edi)
801035b4:	83 c4 10             	add    $0x10,%esp
801035b7:	85 c0                	test   %eax,%eax
801035b9:	74 2a                	je     801035e5 <fork+0x63>
  np->sz = curproc->sz;
801035bb:	8b 03                	mov    (%ebx),%eax
801035bd:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801035c0:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
801035c2:	89 c8                	mov    %ecx,%eax
801035c4:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
801035c7:	8b 73 18             	mov    0x18(%ebx),%esi
801035ca:	8b 79 18             	mov    0x18(%ecx),%edi
801035cd:	b9 13 00 00 00       	mov    $0x13,%ecx
801035d2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
801035d4:	8b 40 18             	mov    0x18(%eax),%eax
801035d7:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for (i = 0; i < NOFILE; i++)
801035de:	be 00 00 00 00       	mov    $0x0,%esi
801035e3:	eb 29                	jmp    8010360e <fork+0x8c>
    kfree(np->kstack);
801035e5:	83 ec 0c             	sub    $0xc,%esp
801035e8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801035eb:	ff 73 08             	pushl  0x8(%ebx)
801035ee:	e8 cf e9 ff ff       	call   80101fc2 <kfree>
    np->kstack = 0;
801035f3:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
801035fa:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103601:	83 c4 10             	add    $0x10,%esp
80103604:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103609:	eb 6d                	jmp    80103678 <fork+0xf6>
  for (i = 0; i < NOFILE; i++)
8010360b:	83 c6 01             	add    $0x1,%esi
8010360e:	83 fe 0f             	cmp    $0xf,%esi
80103611:	7f 1d                	jg     80103630 <fork+0xae>
    if (curproc->ofile[i])
80103613:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103617:	85 c0                	test   %eax,%eax
80103619:	74 f0                	je     8010360b <fork+0x89>
      np->ofile[i] = filedup(curproc->ofile[i]);
8010361b:	83 ec 0c             	sub    $0xc,%esp
8010361e:	50                   	push   %eax
8010361f:	e8 6a d6 ff ff       	call   80100c8e <filedup>
80103624:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103627:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
8010362b:	83 c4 10             	add    $0x10,%esp
8010362e:	eb db                	jmp    8010360b <fork+0x89>
  np->cwd = idup(curproc->cwd);
80103630:	83 ec 0c             	sub    $0xc,%esp
80103633:	ff 73 68             	pushl  0x68(%ebx)
80103636:	e8 16 df ff ff       	call   80101551 <idup>
8010363b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010363e:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103641:	83 c3 6c             	add    $0x6c,%ebx
80103644:	8d 47 6c             	lea    0x6c(%edi),%eax
80103647:	83 c4 0c             	add    $0xc,%esp
8010364a:	6a 10                	push   $0x10
8010364c:	53                   	push   %ebx
8010364d:	50                   	push   %eax
8010364e:	e8 db 09 00 00       	call   8010402e <safestrcpy>
  pid = np->pid;
80103653:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
80103656:	c7 04 24 40 2d 13 80 	movl   $0x80132d40,(%esp)
8010365d:	e8 b9 07 00 00       	call   80103e1b <acquire>
  np->state = RUNNABLE;
80103662:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
80103669:	c7 04 24 40 2d 13 80 	movl   $0x80132d40,(%esp)
80103670:	e8 0b 08 00 00       	call   80103e80 <release>
  return pid;
80103675:	83 c4 10             	add    $0x10,%esp
}
80103678:	89 d8                	mov    %ebx,%eax
8010367a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010367d:	5b                   	pop    %ebx
8010367e:	5e                   	pop    %esi
8010367f:	5f                   	pop    %edi
80103680:	5d                   	pop    %ebp
80103681:	c3                   	ret    
    return -1;
80103682:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103687:	eb ef                	jmp    80103678 <fork+0xf6>

80103689 <scheduler>:
{
80103689:	55                   	push   %ebp
8010368a:	89 e5                	mov    %esp,%ebp
8010368c:	56                   	push   %esi
8010368d:	53                   	push   %ebx
  struct cpu *c = mycpu();
8010368e:	e8 00 fd ff ff       	call   80103393 <mycpu>
80103693:	89 c6                	mov    %eax,%esi
  c->proc = 0;
80103695:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
8010369c:	00 00 00 
8010369f:	eb 5a                	jmp    801036fb <scheduler+0x72>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801036a1:	83 c3 7c             	add    $0x7c,%ebx
801036a4:	81 fb 74 4c 13 80    	cmp    $0x80134c74,%ebx
801036aa:	73 3f                	jae    801036eb <scheduler+0x62>
      if (p->state != RUNNABLE)
801036ac:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
801036b0:	75 ef                	jne    801036a1 <scheduler+0x18>
      c->proc = p;
801036b2:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801036b8:	83 ec 0c             	sub    $0xc,%esp
801036bb:	53                   	push   %ebx
801036bc:	e8 f3 29 00 00       	call   801060b4 <switchuvm>
      p->state = RUNNING;
801036c1:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
801036c8:	83 c4 08             	add    $0x8,%esp
801036cb:	ff 73 1c             	pushl  0x1c(%ebx)
801036ce:	8d 46 04             	lea    0x4(%esi),%eax
801036d1:	50                   	push   %eax
801036d2:	e8 aa 09 00 00       	call   80104081 <swtch>
      switchkvm();
801036d7:	e8 c6 29 00 00       	call   801060a2 <switchkvm>
      c->proc = 0;
801036dc:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
801036e3:	00 00 00 
801036e6:	83 c4 10             	add    $0x10,%esp
801036e9:	eb b6                	jmp    801036a1 <scheduler+0x18>
    release(&ptable.lock);
801036eb:	83 ec 0c             	sub    $0xc,%esp
801036ee:	68 40 2d 13 80       	push   $0x80132d40
801036f3:	e8 88 07 00 00       	call   80103e80 <release>
    sti();
801036f8:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
801036fb:	fb                   	sti    
    acquire(&ptable.lock);
801036fc:	83 ec 0c             	sub    $0xc,%esp
801036ff:	68 40 2d 13 80       	push   $0x80132d40
80103704:	e8 12 07 00 00       	call   80103e1b <acquire>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103709:	83 c4 10             	add    $0x10,%esp
8010370c:	bb 74 2d 13 80       	mov    $0x80132d74,%ebx
80103711:	eb 91                	jmp    801036a4 <scheduler+0x1b>

80103713 <sched>:
{
80103713:	55                   	push   %ebp
80103714:	89 e5                	mov    %esp,%ebp
80103716:	56                   	push   %esi
80103717:	53                   	push   %ebx
  struct proc *p = myproc();
80103718:	e8 ed fc ff ff       	call   8010340a <myproc>
8010371d:	89 c3                	mov    %eax,%ebx
  if (!holding(&ptable.lock))
8010371f:	83 ec 0c             	sub    $0xc,%esp
80103722:	68 40 2d 13 80       	push   $0x80132d40
80103727:	e8 af 06 00 00       	call   80103ddb <holding>
8010372c:	83 c4 10             	add    $0x10,%esp
8010372f:	85 c0                	test   %eax,%eax
80103731:	74 4f                	je     80103782 <sched+0x6f>
  if (mycpu()->ncli != 1)
80103733:	e8 5b fc ff ff       	call   80103393 <mycpu>
80103738:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
8010373f:	75 4e                	jne    8010378f <sched+0x7c>
  if (p->state == RUNNING)
80103741:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103745:	74 55                	je     8010379c <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103747:	9c                   	pushf  
80103748:	58                   	pop    %eax
  if (readeflags() & FL_IF)
80103749:	f6 c4 02             	test   $0x2,%ah
8010374c:	75 5b                	jne    801037a9 <sched+0x96>
  intena = mycpu()->intena;
8010374e:	e8 40 fc ff ff       	call   80103393 <mycpu>
80103753:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
80103759:	e8 35 fc ff ff       	call   80103393 <mycpu>
8010375e:	83 ec 08             	sub    $0x8,%esp
80103761:	ff 70 04             	pushl  0x4(%eax)
80103764:	83 c3 1c             	add    $0x1c,%ebx
80103767:	53                   	push   %ebx
80103768:	e8 14 09 00 00       	call   80104081 <swtch>
  mycpu()->intena = intena;
8010376d:	e8 21 fc ff ff       	call   80103393 <mycpu>
80103772:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
80103778:	83 c4 10             	add    $0x10,%esp
8010377b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010377e:	5b                   	pop    %ebx
8010377f:	5e                   	pop    %esi
80103780:	5d                   	pop    %ebp
80103781:	c3                   	ret    
    panic("sched ptable.lock");
80103782:	83 ec 0c             	sub    $0xc,%esp
80103785:	68 d0 6c 10 80       	push   $0x80106cd0
8010378a:	e8 b9 cb ff ff       	call   80100348 <panic>
    panic("sched locks");
8010378f:	83 ec 0c             	sub    $0xc,%esp
80103792:	68 e2 6c 10 80       	push   $0x80106ce2
80103797:	e8 ac cb ff ff       	call   80100348 <panic>
    panic("sched running");
8010379c:	83 ec 0c             	sub    $0xc,%esp
8010379f:	68 ee 6c 10 80       	push   $0x80106cee
801037a4:	e8 9f cb ff ff       	call   80100348 <panic>
    panic("sched interruptible");
801037a9:	83 ec 0c             	sub    $0xc,%esp
801037ac:	68 fc 6c 10 80       	push   $0x80106cfc
801037b1:	e8 92 cb ff ff       	call   80100348 <panic>

801037b6 <exit>:
{
801037b6:	55                   	push   %ebp
801037b7:	89 e5                	mov    %esp,%ebp
801037b9:	56                   	push   %esi
801037ba:	53                   	push   %ebx
  struct proc *curproc = myproc();
801037bb:	e8 4a fc ff ff       	call   8010340a <myproc>
  if (curproc == initproc)
801037c0:	39 05 b8 a5 10 80    	cmp    %eax,0x8010a5b8
801037c6:	74 09                	je     801037d1 <exit+0x1b>
801037c8:	89 c6                	mov    %eax,%esi
  for (fd = 0; fd < NOFILE; fd++)
801037ca:	bb 00 00 00 00       	mov    $0x0,%ebx
801037cf:	eb 10                	jmp    801037e1 <exit+0x2b>
    panic("init exiting");
801037d1:	83 ec 0c             	sub    $0xc,%esp
801037d4:	68 10 6d 10 80       	push   $0x80106d10
801037d9:	e8 6a cb ff ff       	call   80100348 <panic>
  for (fd = 0; fd < NOFILE; fd++)
801037de:	83 c3 01             	add    $0x1,%ebx
801037e1:	83 fb 0f             	cmp    $0xf,%ebx
801037e4:	7f 1e                	jg     80103804 <exit+0x4e>
    if (curproc->ofile[fd])
801037e6:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
801037ea:	85 c0                	test   %eax,%eax
801037ec:	74 f0                	je     801037de <exit+0x28>
      fileclose(curproc->ofile[fd]);
801037ee:	83 ec 0c             	sub    $0xc,%esp
801037f1:	50                   	push   %eax
801037f2:	e8 dc d4 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
801037f7:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
801037fe:	00 
801037ff:	83 c4 10             	add    $0x10,%esp
80103802:	eb da                	jmp    801037de <exit+0x28>
  begin_op();
80103804:	e8 a0 f1 ff ff       	call   801029a9 <begin_op>
  iput(curproc->cwd);
80103809:	83 ec 0c             	sub    $0xc,%esp
8010380c:	ff 76 68             	pushl  0x68(%esi)
8010380f:	e8 74 de ff ff       	call   80101688 <iput>
  end_op();
80103814:	e8 0a f2 ff ff       	call   80102a23 <end_op>
  curproc->cwd = 0;
80103819:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103820:	c7 04 24 40 2d 13 80 	movl   $0x80132d40,(%esp)
80103827:	e8 ef 05 00 00       	call   80103e1b <acquire>
  wakeup1(curproc->parent);
8010382c:	8b 46 14             	mov    0x14(%esi),%eax
8010382f:	e8 10 fa ff ff       	call   80103244 <wakeup1>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103834:	83 c4 10             	add    $0x10,%esp
80103837:	bb 74 2d 13 80       	mov    $0x80132d74,%ebx
8010383c:	eb 03                	jmp    80103841 <exit+0x8b>
8010383e:	83 c3 7c             	add    $0x7c,%ebx
80103841:	81 fb 74 4c 13 80    	cmp    $0x80134c74,%ebx
80103847:	73 1a                	jae    80103863 <exit+0xad>
    if (p->parent == curproc)
80103849:	39 73 14             	cmp    %esi,0x14(%ebx)
8010384c:	75 f0                	jne    8010383e <exit+0x88>
      p->parent = initproc;
8010384e:	a1 b8 a5 10 80       	mov    0x8010a5b8,%eax
80103853:	89 43 14             	mov    %eax,0x14(%ebx)
      if (p->state == ZOMBIE)
80103856:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010385a:	75 e2                	jne    8010383e <exit+0x88>
        wakeup1(initproc);
8010385c:	e8 e3 f9 ff ff       	call   80103244 <wakeup1>
80103861:	eb db                	jmp    8010383e <exit+0x88>
  curproc->state = ZOMBIE;
80103863:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
8010386a:	e8 a4 fe ff ff       	call   80103713 <sched>
  panic("zombie exit");
8010386f:	83 ec 0c             	sub    $0xc,%esp
80103872:	68 1d 6d 10 80       	push   $0x80106d1d
80103877:	e8 cc ca ff ff       	call   80100348 <panic>

8010387c <yield>:
{
8010387c:	55                   	push   %ebp
8010387d:	89 e5                	mov    %esp,%ebp
8010387f:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock); //DOC: yieldlock
80103882:	68 40 2d 13 80       	push   $0x80132d40
80103887:	e8 8f 05 00 00       	call   80103e1b <acquire>
  myproc()->state = RUNNABLE;
8010388c:	e8 79 fb ff ff       	call   8010340a <myproc>
80103891:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80103898:	e8 76 fe ff ff       	call   80103713 <sched>
  release(&ptable.lock);
8010389d:	c7 04 24 40 2d 13 80 	movl   $0x80132d40,(%esp)
801038a4:	e8 d7 05 00 00       	call   80103e80 <release>
}
801038a9:	83 c4 10             	add    $0x10,%esp
801038ac:	c9                   	leave  
801038ad:	c3                   	ret    

801038ae <sleep>:
{
801038ae:	55                   	push   %ebp
801038af:	89 e5                	mov    %esp,%ebp
801038b1:	56                   	push   %esi
801038b2:	53                   	push   %ebx
801038b3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
801038b6:	e8 4f fb ff ff       	call   8010340a <myproc>
  if (p == 0)
801038bb:	85 c0                	test   %eax,%eax
801038bd:	74 66                	je     80103925 <sleep+0x77>
801038bf:	89 c6                	mov    %eax,%esi
  if (lk == 0)
801038c1:	85 db                	test   %ebx,%ebx
801038c3:	74 6d                	je     80103932 <sleep+0x84>
  if (lk != &ptable.lock)
801038c5:	81 fb 40 2d 13 80    	cmp    $0x80132d40,%ebx
801038cb:	74 18                	je     801038e5 <sleep+0x37>
    acquire(&ptable.lock); //DOC: sleeplock1
801038cd:	83 ec 0c             	sub    $0xc,%esp
801038d0:	68 40 2d 13 80       	push   $0x80132d40
801038d5:	e8 41 05 00 00       	call   80103e1b <acquire>
    release(lk);
801038da:	89 1c 24             	mov    %ebx,(%esp)
801038dd:	e8 9e 05 00 00       	call   80103e80 <release>
801038e2:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
801038e5:	8b 45 08             	mov    0x8(%ebp),%eax
801038e8:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
801038eb:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
801038f2:	e8 1c fe ff ff       	call   80103713 <sched>
  p->chan = 0;
801038f7:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if (lk != &ptable.lock)
801038fe:	81 fb 40 2d 13 80    	cmp    $0x80132d40,%ebx
80103904:	74 18                	je     8010391e <sleep+0x70>
    release(&ptable.lock);
80103906:	83 ec 0c             	sub    $0xc,%esp
80103909:	68 40 2d 13 80       	push   $0x80132d40
8010390e:	e8 6d 05 00 00       	call   80103e80 <release>
    acquire(lk);
80103913:	89 1c 24             	mov    %ebx,(%esp)
80103916:	e8 00 05 00 00       	call   80103e1b <acquire>
8010391b:	83 c4 10             	add    $0x10,%esp
}
8010391e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103921:	5b                   	pop    %ebx
80103922:	5e                   	pop    %esi
80103923:	5d                   	pop    %ebp
80103924:	c3                   	ret    
    panic("sleep");
80103925:	83 ec 0c             	sub    $0xc,%esp
80103928:	68 29 6d 10 80       	push   $0x80106d29
8010392d:	e8 16 ca ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103932:	83 ec 0c             	sub    $0xc,%esp
80103935:	68 2f 6d 10 80       	push   $0x80106d2f
8010393a:	e8 09 ca ff ff       	call   80100348 <panic>

8010393f <wait>:
{
8010393f:	55                   	push   %ebp
80103940:	89 e5                	mov    %esp,%ebp
80103942:	56                   	push   %esi
80103943:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103944:	e8 c1 fa ff ff       	call   8010340a <myproc>
80103949:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
8010394b:	83 ec 0c             	sub    $0xc,%esp
8010394e:	68 40 2d 13 80       	push   $0x80132d40
80103953:	e8 c3 04 00 00       	call   80103e1b <acquire>
80103958:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
8010395b:	b8 00 00 00 00       	mov    $0x0,%eax
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103960:	bb 74 2d 13 80       	mov    $0x80132d74,%ebx
80103965:	eb 5b                	jmp    801039c2 <wait+0x83>
        pid = p->pid;
80103967:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
8010396a:	83 ec 0c             	sub    $0xc,%esp
8010396d:	ff 73 08             	pushl  0x8(%ebx)
80103970:	e8 4d e6 ff ff       	call   80101fc2 <kfree>
        p->kstack = 0;
80103975:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
8010397c:	83 c4 04             	add    $0x4,%esp
8010397f:	ff 73 04             	pushl  0x4(%ebx)
80103982:	e8 e3 2a 00 00       	call   8010646a <freevm>
        p->pid = 0;
80103987:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
8010398e:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103995:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
80103999:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
801039a0:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
801039a7:	c7 04 24 40 2d 13 80 	movl   $0x80132d40,(%esp)
801039ae:	e8 cd 04 00 00       	call   80103e80 <release>
        return pid;
801039b3:	83 c4 10             	add    $0x10,%esp
}
801039b6:	89 f0                	mov    %esi,%eax
801039b8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801039bb:	5b                   	pop    %ebx
801039bc:	5e                   	pop    %esi
801039bd:	5d                   	pop    %ebp
801039be:	c3                   	ret    
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801039bf:	83 c3 7c             	add    $0x7c,%ebx
801039c2:	81 fb 74 4c 13 80    	cmp    $0x80134c74,%ebx
801039c8:	73 12                	jae    801039dc <wait+0x9d>
      if (p->parent != curproc)
801039ca:	39 73 14             	cmp    %esi,0x14(%ebx)
801039cd:	75 f0                	jne    801039bf <wait+0x80>
      if (p->state == ZOMBIE)
801039cf:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801039d3:	74 92                	je     80103967 <wait+0x28>
      havekids = 1;
801039d5:	b8 01 00 00 00       	mov    $0x1,%eax
801039da:	eb e3                	jmp    801039bf <wait+0x80>
    if (!havekids || curproc->killed)
801039dc:	85 c0                	test   %eax,%eax
801039de:	74 06                	je     801039e6 <wait+0xa7>
801039e0:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
801039e4:	74 17                	je     801039fd <wait+0xbe>
      release(&ptable.lock);
801039e6:	83 ec 0c             	sub    $0xc,%esp
801039e9:	68 40 2d 13 80       	push   $0x80132d40
801039ee:	e8 8d 04 00 00       	call   80103e80 <release>
      return -1;
801039f3:	83 c4 10             	add    $0x10,%esp
801039f6:	be ff ff ff ff       	mov    $0xffffffff,%esi
801039fb:	eb b9                	jmp    801039b6 <wait+0x77>
    sleep(curproc, &ptable.lock); //DOC: wait-sleep
801039fd:	83 ec 08             	sub    $0x8,%esp
80103a00:	68 40 2d 13 80       	push   $0x80132d40
80103a05:	56                   	push   %esi
80103a06:	e8 a3 fe ff ff       	call   801038ae <sleep>
    havekids = 0;
80103a0b:	83 c4 10             	add    $0x10,%esp
80103a0e:	e9 48 ff ff ff       	jmp    8010395b <wait+0x1c>

80103a13 <wakeup>:

// Wake up all processes sleeping on chan.
void wakeup(void *chan)
{
80103a13:	55                   	push   %ebp
80103a14:	89 e5                	mov    %esp,%ebp
80103a16:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103a19:	68 40 2d 13 80       	push   $0x80132d40
80103a1e:	e8 f8 03 00 00       	call   80103e1b <acquire>
  wakeup1(chan);
80103a23:	8b 45 08             	mov    0x8(%ebp),%eax
80103a26:	e8 19 f8 ff ff       	call   80103244 <wakeup1>
  release(&ptable.lock);
80103a2b:	c7 04 24 40 2d 13 80 	movl   $0x80132d40,(%esp)
80103a32:	e8 49 04 00 00       	call   80103e80 <release>
}
80103a37:	83 c4 10             	add    $0x10,%esp
80103a3a:	c9                   	leave  
80103a3b:	c3                   	ret    

80103a3c <kill>:

// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int kill(int pid)
{
80103a3c:	55                   	push   %ebp
80103a3d:	89 e5                	mov    %esp,%ebp
80103a3f:	53                   	push   %ebx
80103a40:	83 ec 10             	sub    $0x10,%esp
80103a43:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103a46:	68 40 2d 13 80       	push   $0x80132d40
80103a4b:	e8 cb 03 00 00       	call   80103e1b <acquire>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103a50:	83 c4 10             	add    $0x10,%esp
80103a53:	b8 74 2d 13 80       	mov    $0x80132d74,%eax
80103a58:	3d 74 4c 13 80       	cmp    $0x80134c74,%eax
80103a5d:	73 3a                	jae    80103a99 <kill+0x5d>
  {
    if (p->pid == pid)
80103a5f:	39 58 10             	cmp    %ebx,0x10(%eax)
80103a62:	74 05                	je     80103a69 <kill+0x2d>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103a64:	83 c0 7c             	add    $0x7c,%eax
80103a67:	eb ef                	jmp    80103a58 <kill+0x1c>
    {
      p->killed = 1;
80103a69:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if (p->state == SLEEPING)
80103a70:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103a74:	74 1a                	je     80103a90 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103a76:	83 ec 0c             	sub    $0xc,%esp
80103a79:	68 40 2d 13 80       	push   $0x80132d40
80103a7e:	e8 fd 03 00 00       	call   80103e80 <release>
      return 0;
80103a83:	83 c4 10             	add    $0x10,%esp
80103a86:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103a8b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103a8e:	c9                   	leave  
80103a8f:	c3                   	ret    
        p->state = RUNNABLE;
80103a90:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103a97:	eb dd                	jmp    80103a76 <kill+0x3a>
  release(&ptable.lock);
80103a99:	83 ec 0c             	sub    $0xc,%esp
80103a9c:	68 40 2d 13 80       	push   $0x80132d40
80103aa1:	e8 da 03 00 00       	call   80103e80 <release>
  return -1;
80103aa6:	83 c4 10             	add    $0x10,%esp
80103aa9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103aae:	eb db                	jmp    80103a8b <kill+0x4f>

80103ab0 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
80103ab0:	55                   	push   %ebp
80103ab1:	89 e5                	mov    %esp,%ebp
80103ab3:	56                   	push   %esi
80103ab4:	53                   	push   %ebx
80103ab5:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103ab8:	bb 74 2d 13 80       	mov    $0x80132d74,%ebx
80103abd:	eb 33                	jmp    80103af2 <procdump+0x42>
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103abf:	b8 40 6d 10 80       	mov    $0x80106d40,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103ac4:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103ac7:	52                   	push   %edx
80103ac8:	50                   	push   %eax
80103ac9:	ff 73 10             	pushl  0x10(%ebx)
80103acc:	68 44 6d 10 80       	push   $0x80106d44
80103ad1:	e8 35 cb ff ff       	call   8010060b <cprintf>
    if (p->state == SLEEPING)
80103ad6:	83 c4 10             	add    $0x10,%esp
80103ad9:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103add:	74 39                	je     80103b18 <procdump+0x68>
    {
      getcallerpcs((uint *)p->context->ebp + 2, pc);
      for (i = 0; i < 10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103adf:	83 ec 0c             	sub    $0xc,%esp
80103ae2:	68 bb 70 10 80       	push   $0x801070bb
80103ae7:	e8 1f cb ff ff       	call   8010060b <cprintf>
80103aec:	83 c4 10             	add    $0x10,%esp
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103aef:	83 c3 7c             	add    $0x7c,%ebx
80103af2:	81 fb 74 4c 13 80    	cmp    $0x80134c74,%ebx
80103af8:	73 61                	jae    80103b5b <procdump+0xab>
    if (p->state == UNUSED)
80103afa:	8b 43 0c             	mov    0xc(%ebx),%eax
80103afd:	85 c0                	test   %eax,%eax
80103aff:	74 ee                	je     80103aef <procdump+0x3f>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103b01:	83 f8 05             	cmp    $0x5,%eax
80103b04:	77 b9                	ja     80103abf <procdump+0xf>
80103b06:	8b 04 85 a0 6d 10 80 	mov    -0x7fef9260(,%eax,4),%eax
80103b0d:	85 c0                	test   %eax,%eax
80103b0f:	75 b3                	jne    80103ac4 <procdump+0x14>
      state = "???";
80103b11:	b8 40 6d 10 80       	mov    $0x80106d40,%eax
80103b16:	eb ac                	jmp    80103ac4 <procdump+0x14>
      getcallerpcs((uint *)p->context->ebp + 2, pc);
80103b18:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103b1b:	8b 40 0c             	mov    0xc(%eax),%eax
80103b1e:	83 c0 08             	add    $0x8,%eax
80103b21:	83 ec 08             	sub    $0x8,%esp
80103b24:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103b27:	52                   	push   %edx
80103b28:	50                   	push   %eax
80103b29:	e8 cc 01 00 00       	call   80103cfa <getcallerpcs>
      for (i = 0; i < 10 && pc[i] != 0; i++)
80103b2e:	83 c4 10             	add    $0x10,%esp
80103b31:	be 00 00 00 00       	mov    $0x0,%esi
80103b36:	eb 14                	jmp    80103b4c <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103b38:	83 ec 08             	sub    $0x8,%esp
80103b3b:	50                   	push   %eax
80103b3c:	68 81 67 10 80       	push   $0x80106781
80103b41:	e8 c5 ca ff ff       	call   8010060b <cprintf>
      for (i = 0; i < 10 && pc[i] != 0; i++)
80103b46:	83 c6 01             	add    $0x1,%esi
80103b49:	83 c4 10             	add    $0x10,%esp
80103b4c:	83 fe 09             	cmp    $0x9,%esi
80103b4f:	7f 8e                	jg     80103adf <procdump+0x2f>
80103b51:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103b55:	85 c0                	test   %eax,%eax
80103b57:	75 df                	jne    80103b38 <procdump+0x88>
80103b59:	eb 84                	jmp    80103adf <procdump+0x2f>
  }
}
80103b5b:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b5e:	5b                   	pop    %ebx
80103b5f:	5e                   	pop    %esi
80103b60:	5d                   	pop    %ebp
80103b61:	c3                   	ret    

80103b62 <dump_physmem>:

int dump_physmem(int *frames, int *pids, int numframes)
{
80103b62:	55                   	push   %ebp
80103b63:	89 e5                	mov    %esp,%ebp
80103b65:	57                   	push   %edi
80103b66:	56                   	push   %esi
80103b67:	53                   	push   %ebx
80103b68:	83 ec 1c             	sub    $0x1c,%esp
80103b6b:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103b6e:	8b 75 0c             	mov    0xc(%ebp),%esi
  if(numframes == 0 || frames == 0 || pids == 0) {
80103b71:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80103b75:	0f 94 c2             	sete   %dl
80103b78:	85 db                	test   %ebx,%ebx
80103b7a:	0f 94 c0             	sete   %al
80103b7d:	08 c2                	or     %al,%dl
80103b7f:	75 45                	jne    80103bc6 <dump_physmem+0x64>
80103b81:	85 f6                	test   %esi,%esi
80103b83:	74 48                	je     80103bcd <dump_physmem+0x6b>
    return -1;
  }
  int* framesList = getframesList();
80103b85:	e8 1a e4 ff ff       	call   80101fa4 <getframesList>
80103b8a:	89 c7                	mov    %eax,%edi
  int* pidList = getpidList();
80103b8c:	e8 27 e4 ff ff       	call   80101fb8 <getpidList>
  for (int i = 0; i < numframes; i++) {
80103b91:	ba 00 00 00 00       	mov    $0x0,%edx
80103b96:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80103b99:	eb 19                	jmp    80103bb4 <dump_physmem+0x52>
    frames[i] = framesList[i];
80103b9b:	8d 0c 95 00 00 00 00 	lea    0x0(,%edx,4),%ecx
80103ba2:	8b 04 97             	mov    (%edi,%edx,4),%eax
80103ba5:	89 04 0b             	mov    %eax,(%ebx,%ecx,1)
    pids[i] = pidList[i];
80103ba8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103bab:	8b 04 90             	mov    (%eax,%edx,4),%eax
80103bae:	89 04 0e             	mov    %eax,(%esi,%ecx,1)
  for (int i = 0; i < numframes; i++) {
80103bb1:	83 c2 01             	add    $0x1,%edx
80103bb4:	3b 55 10             	cmp    0x10(%ebp),%edx
80103bb7:	7c e2                	jl     80103b9b <dump_physmem+0x39>
  }
  return 0;
80103bb9:	b8 00 00 00 00       	mov    $0x0,%eax
80103bbe:	83 c4 1c             	add    $0x1c,%esp
80103bc1:	5b                   	pop    %ebx
80103bc2:	5e                   	pop    %esi
80103bc3:	5f                   	pop    %edi
80103bc4:	5d                   	pop    %ebp
80103bc5:	c3                   	ret    
    return -1;
80103bc6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103bcb:	eb f1                	jmp    80103bbe <dump_physmem+0x5c>
80103bcd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103bd2:	eb ea                	jmp    80103bbe <dump_physmem+0x5c>

80103bd4 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103bd4:	55                   	push   %ebp
80103bd5:	89 e5                	mov    %esp,%ebp
80103bd7:	53                   	push   %ebx
80103bd8:	83 ec 0c             	sub    $0xc,%esp
80103bdb:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103bde:	68 b8 6d 10 80       	push   $0x80106db8
80103be3:	8d 43 04             	lea    0x4(%ebx),%eax
80103be6:	50                   	push   %eax
80103be7:	e8 f3 00 00 00       	call   80103cdf <initlock>
  lk->name = name;
80103bec:	8b 45 0c             	mov    0xc(%ebp),%eax
80103bef:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103bf2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103bf8:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103bff:	83 c4 10             	add    $0x10,%esp
80103c02:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103c05:	c9                   	leave  
80103c06:	c3                   	ret    

80103c07 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103c07:	55                   	push   %ebp
80103c08:	89 e5                	mov    %esp,%ebp
80103c0a:	56                   	push   %esi
80103c0b:	53                   	push   %ebx
80103c0c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103c0f:	8d 73 04             	lea    0x4(%ebx),%esi
80103c12:	83 ec 0c             	sub    $0xc,%esp
80103c15:	56                   	push   %esi
80103c16:	e8 00 02 00 00       	call   80103e1b <acquire>
  while (lk->locked) {
80103c1b:	83 c4 10             	add    $0x10,%esp
80103c1e:	eb 0d                	jmp    80103c2d <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103c20:	83 ec 08             	sub    $0x8,%esp
80103c23:	56                   	push   %esi
80103c24:	53                   	push   %ebx
80103c25:	e8 84 fc ff ff       	call   801038ae <sleep>
80103c2a:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103c2d:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c30:	75 ee                	jne    80103c20 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103c32:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103c38:	e8 cd f7 ff ff       	call   8010340a <myproc>
80103c3d:	8b 40 10             	mov    0x10(%eax),%eax
80103c40:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103c43:	83 ec 0c             	sub    $0xc,%esp
80103c46:	56                   	push   %esi
80103c47:	e8 34 02 00 00       	call   80103e80 <release>
}
80103c4c:	83 c4 10             	add    $0x10,%esp
80103c4f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c52:	5b                   	pop    %ebx
80103c53:	5e                   	pop    %esi
80103c54:	5d                   	pop    %ebp
80103c55:	c3                   	ret    

80103c56 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103c56:	55                   	push   %ebp
80103c57:	89 e5                	mov    %esp,%ebp
80103c59:	56                   	push   %esi
80103c5a:	53                   	push   %ebx
80103c5b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103c5e:	8d 73 04             	lea    0x4(%ebx),%esi
80103c61:	83 ec 0c             	sub    $0xc,%esp
80103c64:	56                   	push   %esi
80103c65:	e8 b1 01 00 00       	call   80103e1b <acquire>
  lk->locked = 0;
80103c6a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103c70:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103c77:	89 1c 24             	mov    %ebx,(%esp)
80103c7a:	e8 94 fd ff ff       	call   80103a13 <wakeup>
  release(&lk->lk);
80103c7f:	89 34 24             	mov    %esi,(%esp)
80103c82:	e8 f9 01 00 00       	call   80103e80 <release>
}
80103c87:	83 c4 10             	add    $0x10,%esp
80103c8a:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c8d:	5b                   	pop    %ebx
80103c8e:	5e                   	pop    %esi
80103c8f:	5d                   	pop    %ebp
80103c90:	c3                   	ret    

80103c91 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103c91:	55                   	push   %ebp
80103c92:	89 e5                	mov    %esp,%ebp
80103c94:	56                   	push   %esi
80103c95:	53                   	push   %ebx
80103c96:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103c99:	8d 73 04             	lea    0x4(%ebx),%esi
80103c9c:	83 ec 0c             	sub    $0xc,%esp
80103c9f:	56                   	push   %esi
80103ca0:	e8 76 01 00 00       	call   80103e1b <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103ca5:	83 c4 10             	add    $0x10,%esp
80103ca8:	83 3b 00             	cmpl   $0x0,(%ebx)
80103cab:	75 17                	jne    80103cc4 <holdingsleep+0x33>
80103cad:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103cb2:	83 ec 0c             	sub    $0xc,%esp
80103cb5:	56                   	push   %esi
80103cb6:	e8 c5 01 00 00       	call   80103e80 <release>
  return r;
}
80103cbb:	89 d8                	mov    %ebx,%eax
80103cbd:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103cc0:	5b                   	pop    %ebx
80103cc1:	5e                   	pop    %esi
80103cc2:	5d                   	pop    %ebp
80103cc3:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103cc4:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103cc7:	e8 3e f7 ff ff       	call   8010340a <myproc>
80103ccc:	3b 58 10             	cmp    0x10(%eax),%ebx
80103ccf:	74 07                	je     80103cd8 <holdingsleep+0x47>
80103cd1:	bb 00 00 00 00       	mov    $0x0,%ebx
80103cd6:	eb da                	jmp    80103cb2 <holdingsleep+0x21>
80103cd8:	bb 01 00 00 00       	mov    $0x1,%ebx
80103cdd:	eb d3                	jmp    80103cb2 <holdingsleep+0x21>

80103cdf <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103cdf:	55                   	push   %ebp
80103ce0:	89 e5                	mov    %esp,%ebp
80103ce2:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103ce5:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ce8:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103ceb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103cf1:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103cf8:	5d                   	pop    %ebp
80103cf9:	c3                   	ret    

80103cfa <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103cfa:	55                   	push   %ebp
80103cfb:	89 e5                	mov    %esp,%ebp
80103cfd:	53                   	push   %ebx
80103cfe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103d01:	8b 45 08             	mov    0x8(%ebp),%eax
80103d04:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103d07:	b8 00 00 00 00       	mov    $0x0,%eax
80103d0c:	83 f8 09             	cmp    $0x9,%eax
80103d0f:	7f 25                	jg     80103d36 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103d11:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103d17:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103d1d:	77 17                	ja     80103d36 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103d1f:	8b 5a 04             	mov    0x4(%edx),%ebx
80103d22:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103d25:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103d27:	83 c0 01             	add    $0x1,%eax
80103d2a:	eb e0                	jmp    80103d0c <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103d2c:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103d33:	83 c0 01             	add    $0x1,%eax
80103d36:	83 f8 09             	cmp    $0x9,%eax
80103d39:	7e f1                	jle    80103d2c <getcallerpcs+0x32>
}
80103d3b:	5b                   	pop    %ebx
80103d3c:	5d                   	pop    %ebp
80103d3d:	c3                   	ret    

80103d3e <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103d3e:	55                   	push   %ebp
80103d3f:	89 e5                	mov    %esp,%ebp
80103d41:	53                   	push   %ebx
80103d42:	83 ec 04             	sub    $0x4,%esp
80103d45:	9c                   	pushf  
80103d46:	5b                   	pop    %ebx
  asm volatile("cli");
80103d47:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103d48:	e8 46 f6 ff ff       	call   80103393 <mycpu>
80103d4d:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103d54:	74 12                	je     80103d68 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103d56:	e8 38 f6 ff ff       	call   80103393 <mycpu>
80103d5b:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103d62:	83 c4 04             	add    $0x4,%esp
80103d65:	5b                   	pop    %ebx
80103d66:	5d                   	pop    %ebp
80103d67:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103d68:	e8 26 f6 ff ff       	call   80103393 <mycpu>
80103d6d:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103d73:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103d79:	eb db                	jmp    80103d56 <pushcli+0x18>

80103d7b <popcli>:

void
popcli(void)
{
80103d7b:	55                   	push   %ebp
80103d7c:	89 e5                	mov    %esp,%ebp
80103d7e:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103d81:	9c                   	pushf  
80103d82:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103d83:	f6 c4 02             	test   $0x2,%ah
80103d86:	75 28                	jne    80103db0 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103d88:	e8 06 f6 ff ff       	call   80103393 <mycpu>
80103d8d:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103d93:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103d96:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103d9c:	85 d2                	test   %edx,%edx
80103d9e:	78 1d                	js     80103dbd <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103da0:	e8 ee f5 ff ff       	call   80103393 <mycpu>
80103da5:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103dac:	74 1c                	je     80103dca <popcli+0x4f>
    sti();
}
80103dae:	c9                   	leave  
80103daf:	c3                   	ret    
    panic("popcli - interruptible");
80103db0:	83 ec 0c             	sub    $0xc,%esp
80103db3:	68 c3 6d 10 80       	push   $0x80106dc3
80103db8:	e8 8b c5 ff ff       	call   80100348 <panic>
    panic("popcli");
80103dbd:	83 ec 0c             	sub    $0xc,%esp
80103dc0:	68 da 6d 10 80       	push   $0x80106dda
80103dc5:	e8 7e c5 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103dca:	e8 c4 f5 ff ff       	call   80103393 <mycpu>
80103dcf:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103dd6:	74 d6                	je     80103dae <popcli+0x33>
  asm volatile("sti");
80103dd8:	fb                   	sti    
}
80103dd9:	eb d3                	jmp    80103dae <popcli+0x33>

80103ddb <holding>:
{
80103ddb:	55                   	push   %ebp
80103ddc:	89 e5                	mov    %esp,%ebp
80103dde:	53                   	push   %ebx
80103ddf:	83 ec 04             	sub    $0x4,%esp
80103de2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103de5:	e8 54 ff ff ff       	call   80103d3e <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103dea:	83 3b 00             	cmpl   $0x0,(%ebx)
80103ded:	75 12                	jne    80103e01 <holding+0x26>
80103def:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103df4:	e8 82 ff ff ff       	call   80103d7b <popcli>
}
80103df9:	89 d8                	mov    %ebx,%eax
80103dfb:	83 c4 04             	add    $0x4,%esp
80103dfe:	5b                   	pop    %ebx
80103dff:	5d                   	pop    %ebp
80103e00:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103e01:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103e04:	e8 8a f5 ff ff       	call   80103393 <mycpu>
80103e09:	39 c3                	cmp    %eax,%ebx
80103e0b:	74 07                	je     80103e14 <holding+0x39>
80103e0d:	bb 00 00 00 00       	mov    $0x0,%ebx
80103e12:	eb e0                	jmp    80103df4 <holding+0x19>
80103e14:	bb 01 00 00 00       	mov    $0x1,%ebx
80103e19:	eb d9                	jmp    80103df4 <holding+0x19>

80103e1b <acquire>:
{
80103e1b:	55                   	push   %ebp
80103e1c:	89 e5                	mov    %esp,%ebp
80103e1e:	53                   	push   %ebx
80103e1f:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103e22:	e8 17 ff ff ff       	call   80103d3e <pushcli>
  if(holding(lk))
80103e27:	83 ec 0c             	sub    $0xc,%esp
80103e2a:	ff 75 08             	pushl  0x8(%ebp)
80103e2d:	e8 a9 ff ff ff       	call   80103ddb <holding>
80103e32:	83 c4 10             	add    $0x10,%esp
80103e35:	85 c0                	test   %eax,%eax
80103e37:	75 3a                	jne    80103e73 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103e39:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103e3c:	b8 01 00 00 00       	mov    $0x1,%eax
80103e41:	f0 87 02             	lock xchg %eax,(%edx)
80103e44:	85 c0                	test   %eax,%eax
80103e46:	75 f1                	jne    80103e39 <acquire+0x1e>
  __sync_synchronize();
80103e48:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103e4d:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103e50:	e8 3e f5 ff ff       	call   80103393 <mycpu>
80103e55:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103e58:	8b 45 08             	mov    0x8(%ebp),%eax
80103e5b:	83 c0 0c             	add    $0xc,%eax
80103e5e:	83 ec 08             	sub    $0x8,%esp
80103e61:	50                   	push   %eax
80103e62:	8d 45 08             	lea    0x8(%ebp),%eax
80103e65:	50                   	push   %eax
80103e66:	e8 8f fe ff ff       	call   80103cfa <getcallerpcs>
}
80103e6b:	83 c4 10             	add    $0x10,%esp
80103e6e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103e71:	c9                   	leave  
80103e72:	c3                   	ret    
    panic("acquire");
80103e73:	83 ec 0c             	sub    $0xc,%esp
80103e76:	68 e1 6d 10 80       	push   $0x80106de1
80103e7b:	e8 c8 c4 ff ff       	call   80100348 <panic>

80103e80 <release>:
{
80103e80:	55                   	push   %ebp
80103e81:	89 e5                	mov    %esp,%ebp
80103e83:	53                   	push   %ebx
80103e84:	83 ec 10             	sub    $0x10,%esp
80103e87:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103e8a:	53                   	push   %ebx
80103e8b:	e8 4b ff ff ff       	call   80103ddb <holding>
80103e90:	83 c4 10             	add    $0x10,%esp
80103e93:	85 c0                	test   %eax,%eax
80103e95:	74 23                	je     80103eba <release+0x3a>
  lk->pcs[0] = 0;
80103e97:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103e9e:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103ea5:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103eaa:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103eb0:	e8 c6 fe ff ff       	call   80103d7b <popcli>
}
80103eb5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103eb8:	c9                   	leave  
80103eb9:	c3                   	ret    
    panic("release");
80103eba:	83 ec 0c             	sub    $0xc,%esp
80103ebd:	68 e9 6d 10 80       	push   $0x80106de9
80103ec2:	e8 81 c4 ff ff       	call   80100348 <panic>

80103ec7 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103ec7:	55                   	push   %ebp
80103ec8:	89 e5                	mov    %esp,%ebp
80103eca:	57                   	push   %edi
80103ecb:	53                   	push   %ebx
80103ecc:	8b 55 08             	mov    0x8(%ebp),%edx
80103ecf:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103ed2:	f6 c2 03             	test   $0x3,%dl
80103ed5:	75 05                	jne    80103edc <memset+0x15>
80103ed7:	f6 c1 03             	test   $0x3,%cl
80103eda:	74 0e                	je     80103eea <memset+0x23>
  asm volatile("cld; rep stosb" :
80103edc:	89 d7                	mov    %edx,%edi
80103ede:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ee1:	fc                   	cld    
80103ee2:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103ee4:	89 d0                	mov    %edx,%eax
80103ee6:	5b                   	pop    %ebx
80103ee7:	5f                   	pop    %edi
80103ee8:	5d                   	pop    %ebp
80103ee9:	c3                   	ret    
    c &= 0xFF;
80103eea:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103eee:	c1 e9 02             	shr    $0x2,%ecx
80103ef1:	89 f8                	mov    %edi,%eax
80103ef3:	c1 e0 18             	shl    $0x18,%eax
80103ef6:	89 fb                	mov    %edi,%ebx
80103ef8:	c1 e3 10             	shl    $0x10,%ebx
80103efb:	09 d8                	or     %ebx,%eax
80103efd:	89 fb                	mov    %edi,%ebx
80103eff:	c1 e3 08             	shl    $0x8,%ebx
80103f02:	09 d8                	or     %ebx,%eax
80103f04:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103f06:	89 d7                	mov    %edx,%edi
80103f08:	fc                   	cld    
80103f09:	f3 ab                	rep stos %eax,%es:(%edi)
80103f0b:	eb d7                	jmp    80103ee4 <memset+0x1d>

80103f0d <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103f0d:	55                   	push   %ebp
80103f0e:	89 e5                	mov    %esp,%ebp
80103f10:	56                   	push   %esi
80103f11:	53                   	push   %ebx
80103f12:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103f15:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f18:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103f1b:	8d 70 ff             	lea    -0x1(%eax),%esi
80103f1e:	85 c0                	test   %eax,%eax
80103f20:	74 1c                	je     80103f3e <memcmp+0x31>
    if(*s1 != *s2)
80103f22:	0f b6 01             	movzbl (%ecx),%eax
80103f25:	0f b6 1a             	movzbl (%edx),%ebx
80103f28:	38 d8                	cmp    %bl,%al
80103f2a:	75 0a                	jne    80103f36 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103f2c:	83 c1 01             	add    $0x1,%ecx
80103f2f:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103f32:	89 f0                	mov    %esi,%eax
80103f34:	eb e5                	jmp    80103f1b <memcmp+0xe>
      return *s1 - *s2;
80103f36:	0f b6 c0             	movzbl %al,%eax
80103f39:	0f b6 db             	movzbl %bl,%ebx
80103f3c:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103f3e:	5b                   	pop    %ebx
80103f3f:	5e                   	pop    %esi
80103f40:	5d                   	pop    %ebp
80103f41:	c3                   	ret    

80103f42 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103f42:	55                   	push   %ebp
80103f43:	89 e5                	mov    %esp,%ebp
80103f45:	56                   	push   %esi
80103f46:	53                   	push   %ebx
80103f47:	8b 45 08             	mov    0x8(%ebp),%eax
80103f4a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103f4d:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103f50:	39 c1                	cmp    %eax,%ecx
80103f52:	73 3a                	jae    80103f8e <memmove+0x4c>
80103f54:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103f57:	39 c3                	cmp    %eax,%ebx
80103f59:	76 37                	jbe    80103f92 <memmove+0x50>
    s += n;
    d += n;
80103f5b:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103f5e:	eb 0d                	jmp    80103f6d <memmove+0x2b>
      *--d = *--s;
80103f60:	83 eb 01             	sub    $0x1,%ebx
80103f63:	83 e9 01             	sub    $0x1,%ecx
80103f66:	0f b6 13             	movzbl (%ebx),%edx
80103f69:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103f6b:	89 f2                	mov    %esi,%edx
80103f6d:	8d 72 ff             	lea    -0x1(%edx),%esi
80103f70:	85 d2                	test   %edx,%edx
80103f72:	75 ec                	jne    80103f60 <memmove+0x1e>
80103f74:	eb 14                	jmp    80103f8a <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103f76:	0f b6 11             	movzbl (%ecx),%edx
80103f79:	88 13                	mov    %dl,(%ebx)
80103f7b:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103f7e:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103f81:	89 f2                	mov    %esi,%edx
80103f83:	8d 72 ff             	lea    -0x1(%edx),%esi
80103f86:	85 d2                	test   %edx,%edx
80103f88:	75 ec                	jne    80103f76 <memmove+0x34>

  return dst;
}
80103f8a:	5b                   	pop    %ebx
80103f8b:	5e                   	pop    %esi
80103f8c:	5d                   	pop    %ebp
80103f8d:	c3                   	ret    
80103f8e:	89 c3                	mov    %eax,%ebx
80103f90:	eb f1                	jmp    80103f83 <memmove+0x41>
80103f92:	89 c3                	mov    %eax,%ebx
80103f94:	eb ed                	jmp    80103f83 <memmove+0x41>

80103f96 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103f96:	55                   	push   %ebp
80103f97:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103f99:	ff 75 10             	pushl  0x10(%ebp)
80103f9c:	ff 75 0c             	pushl  0xc(%ebp)
80103f9f:	ff 75 08             	pushl  0x8(%ebp)
80103fa2:	e8 9b ff ff ff       	call   80103f42 <memmove>
}
80103fa7:	c9                   	leave  
80103fa8:	c3                   	ret    

80103fa9 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103fa9:	55                   	push   %ebp
80103faa:	89 e5                	mov    %esp,%ebp
80103fac:	53                   	push   %ebx
80103fad:	8b 55 08             	mov    0x8(%ebp),%edx
80103fb0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103fb3:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103fb6:	eb 09                	jmp    80103fc1 <strncmp+0x18>
    n--, p++, q++;
80103fb8:	83 e8 01             	sub    $0x1,%eax
80103fbb:	83 c2 01             	add    $0x1,%edx
80103fbe:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103fc1:	85 c0                	test   %eax,%eax
80103fc3:	74 0b                	je     80103fd0 <strncmp+0x27>
80103fc5:	0f b6 1a             	movzbl (%edx),%ebx
80103fc8:	84 db                	test   %bl,%bl
80103fca:	74 04                	je     80103fd0 <strncmp+0x27>
80103fcc:	3a 19                	cmp    (%ecx),%bl
80103fce:	74 e8                	je     80103fb8 <strncmp+0xf>
  if(n == 0)
80103fd0:	85 c0                	test   %eax,%eax
80103fd2:	74 0b                	je     80103fdf <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103fd4:	0f b6 02             	movzbl (%edx),%eax
80103fd7:	0f b6 11             	movzbl (%ecx),%edx
80103fda:	29 d0                	sub    %edx,%eax
}
80103fdc:	5b                   	pop    %ebx
80103fdd:	5d                   	pop    %ebp
80103fde:	c3                   	ret    
    return 0;
80103fdf:	b8 00 00 00 00       	mov    $0x0,%eax
80103fe4:	eb f6                	jmp    80103fdc <strncmp+0x33>

80103fe6 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103fe6:	55                   	push   %ebp
80103fe7:	89 e5                	mov    %esp,%ebp
80103fe9:	57                   	push   %edi
80103fea:	56                   	push   %esi
80103feb:	53                   	push   %ebx
80103fec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103fef:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103ff2:	8b 45 08             	mov    0x8(%ebp),%eax
80103ff5:	eb 04                	jmp    80103ffb <strncpy+0x15>
80103ff7:	89 fb                	mov    %edi,%ebx
80103ff9:	89 f0                	mov    %esi,%eax
80103ffb:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103ffe:	85 c9                	test   %ecx,%ecx
80104000:	7e 1d                	jle    8010401f <strncpy+0x39>
80104002:	8d 7b 01             	lea    0x1(%ebx),%edi
80104005:	8d 70 01             	lea    0x1(%eax),%esi
80104008:	0f b6 1b             	movzbl (%ebx),%ebx
8010400b:	88 18                	mov    %bl,(%eax)
8010400d:	89 d1                	mov    %edx,%ecx
8010400f:	84 db                	test   %bl,%bl
80104011:	75 e4                	jne    80103ff7 <strncpy+0x11>
80104013:	89 f0                	mov    %esi,%eax
80104015:	eb 08                	jmp    8010401f <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80104017:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
8010401a:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
8010401c:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
8010401f:	8d 4a ff             	lea    -0x1(%edx),%ecx
80104022:	85 d2                	test   %edx,%edx
80104024:	7f f1                	jg     80104017 <strncpy+0x31>
  return os;
}
80104026:	8b 45 08             	mov    0x8(%ebp),%eax
80104029:	5b                   	pop    %ebx
8010402a:	5e                   	pop    %esi
8010402b:	5f                   	pop    %edi
8010402c:	5d                   	pop    %ebp
8010402d:	c3                   	ret    

8010402e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010402e:	55                   	push   %ebp
8010402f:	89 e5                	mov    %esp,%ebp
80104031:	57                   	push   %edi
80104032:	56                   	push   %esi
80104033:	53                   	push   %ebx
80104034:	8b 45 08             	mov    0x8(%ebp),%eax
80104037:	8b 5d 0c             	mov    0xc(%ebp),%ebx
8010403a:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
8010403d:	85 d2                	test   %edx,%edx
8010403f:	7e 23                	jle    80104064 <safestrcpy+0x36>
80104041:	89 c1                	mov    %eax,%ecx
80104043:	eb 04                	jmp    80104049 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80104045:	89 fb                	mov    %edi,%ebx
80104047:	89 f1                	mov    %esi,%ecx
80104049:	83 ea 01             	sub    $0x1,%edx
8010404c:	85 d2                	test   %edx,%edx
8010404e:	7e 11                	jle    80104061 <safestrcpy+0x33>
80104050:	8d 7b 01             	lea    0x1(%ebx),%edi
80104053:	8d 71 01             	lea    0x1(%ecx),%esi
80104056:	0f b6 1b             	movzbl (%ebx),%ebx
80104059:	88 19                	mov    %bl,(%ecx)
8010405b:	84 db                	test   %bl,%bl
8010405d:	75 e6                	jne    80104045 <safestrcpy+0x17>
8010405f:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80104061:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80104064:	5b                   	pop    %ebx
80104065:	5e                   	pop    %esi
80104066:	5f                   	pop    %edi
80104067:	5d                   	pop    %ebp
80104068:	c3                   	ret    

80104069 <strlen>:

int
strlen(const char *s)
{
80104069:	55                   	push   %ebp
8010406a:	89 e5                	mov    %esp,%ebp
8010406c:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
8010406f:	b8 00 00 00 00       	mov    $0x0,%eax
80104074:	eb 03                	jmp    80104079 <strlen+0x10>
80104076:	83 c0 01             	add    $0x1,%eax
80104079:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
8010407d:	75 f7                	jne    80104076 <strlen+0xd>
    ;
  return n;
}
8010407f:	5d                   	pop    %ebp
80104080:	c3                   	ret    

80104081 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80104081:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80104085:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80104089:	55                   	push   %ebp
  pushl %ebx
8010408a:	53                   	push   %ebx
  pushl %esi
8010408b:	56                   	push   %esi
  pushl %edi
8010408c:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010408d:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010408f:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80104091:	5f                   	pop    %edi
  popl %esi
80104092:	5e                   	pop    %esi
  popl %ebx
80104093:	5b                   	pop    %ebx
  popl %ebp
80104094:	5d                   	pop    %ebp
  ret
80104095:	c3                   	ret    

80104096 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80104096:	55                   	push   %ebp
80104097:	89 e5                	mov    %esp,%ebp
80104099:	53                   	push   %ebx
8010409a:	83 ec 04             	sub    $0x4,%esp
8010409d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
801040a0:	e8 65 f3 ff ff       	call   8010340a <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
801040a5:	8b 00                	mov    (%eax),%eax
801040a7:	39 d8                	cmp    %ebx,%eax
801040a9:	76 19                	jbe    801040c4 <fetchint+0x2e>
801040ab:	8d 53 04             	lea    0x4(%ebx),%edx
801040ae:	39 d0                	cmp    %edx,%eax
801040b0:	72 19                	jb     801040cb <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
801040b2:	8b 13                	mov    (%ebx),%edx
801040b4:	8b 45 0c             	mov    0xc(%ebp),%eax
801040b7:	89 10                	mov    %edx,(%eax)
  return 0;
801040b9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801040be:	83 c4 04             	add    $0x4,%esp
801040c1:	5b                   	pop    %ebx
801040c2:	5d                   	pop    %ebp
801040c3:	c3                   	ret    
    return -1;
801040c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040c9:	eb f3                	jmp    801040be <fetchint+0x28>
801040cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040d0:	eb ec                	jmp    801040be <fetchint+0x28>

801040d2 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
801040d2:	55                   	push   %ebp
801040d3:	89 e5                	mov    %esp,%ebp
801040d5:	53                   	push   %ebx
801040d6:	83 ec 04             	sub    $0x4,%esp
801040d9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
801040dc:	e8 29 f3 ff ff       	call   8010340a <myproc>

  if(addr >= curproc->sz)
801040e1:	39 18                	cmp    %ebx,(%eax)
801040e3:	76 26                	jbe    8010410b <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
801040e5:	8b 55 0c             	mov    0xc(%ebp),%edx
801040e8:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
801040ea:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
801040ec:	89 d8                	mov    %ebx,%eax
801040ee:	39 d0                	cmp    %edx,%eax
801040f0:	73 0e                	jae    80104100 <fetchstr+0x2e>
    if(*s == 0)
801040f2:	80 38 00             	cmpb   $0x0,(%eax)
801040f5:	74 05                	je     801040fc <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
801040f7:	83 c0 01             	add    $0x1,%eax
801040fa:	eb f2                	jmp    801040ee <fetchstr+0x1c>
      return s - *pp;
801040fc:	29 d8                	sub    %ebx,%eax
801040fe:	eb 05                	jmp    80104105 <fetchstr+0x33>
  }
  return -1;
80104100:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104105:	83 c4 04             	add    $0x4,%esp
80104108:	5b                   	pop    %ebx
80104109:	5d                   	pop    %ebp
8010410a:	c3                   	ret    
    return -1;
8010410b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104110:	eb f3                	jmp    80104105 <fetchstr+0x33>

80104112 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80104112:	55                   	push   %ebp
80104113:	89 e5                	mov    %esp,%ebp
80104115:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80104118:	e8 ed f2 ff ff       	call   8010340a <myproc>
8010411d:	8b 50 18             	mov    0x18(%eax),%edx
80104120:	8b 45 08             	mov    0x8(%ebp),%eax
80104123:	c1 e0 02             	shl    $0x2,%eax
80104126:	03 42 44             	add    0x44(%edx),%eax
80104129:	83 ec 08             	sub    $0x8,%esp
8010412c:	ff 75 0c             	pushl  0xc(%ebp)
8010412f:	83 c0 04             	add    $0x4,%eax
80104132:	50                   	push   %eax
80104133:	e8 5e ff ff ff       	call   80104096 <fetchint>
}
80104138:	c9                   	leave  
80104139:	c3                   	ret    

8010413a <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
8010413a:	55                   	push   %ebp
8010413b:	89 e5                	mov    %esp,%ebp
8010413d:	56                   	push   %esi
8010413e:	53                   	push   %ebx
8010413f:	83 ec 10             	sub    $0x10,%esp
80104142:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80104145:	e8 c0 f2 ff ff       	call   8010340a <myproc>
8010414a:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
8010414c:	83 ec 08             	sub    $0x8,%esp
8010414f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104152:	50                   	push   %eax
80104153:	ff 75 08             	pushl  0x8(%ebp)
80104156:	e8 b7 ff ff ff       	call   80104112 <argint>
8010415b:	83 c4 10             	add    $0x10,%esp
8010415e:	85 c0                	test   %eax,%eax
80104160:	78 24                	js     80104186 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80104162:	85 db                	test   %ebx,%ebx
80104164:	78 27                	js     8010418d <argptr+0x53>
80104166:	8b 16                	mov    (%esi),%edx
80104168:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010416b:	39 c2                	cmp    %eax,%edx
8010416d:	76 25                	jbe    80104194 <argptr+0x5a>
8010416f:	01 c3                	add    %eax,%ebx
80104171:	39 da                	cmp    %ebx,%edx
80104173:	72 26                	jb     8010419b <argptr+0x61>
    return -1;
  *pp = (char*)i;
80104175:	8b 55 0c             	mov    0xc(%ebp),%edx
80104178:	89 02                	mov    %eax,(%edx)
  return 0;
8010417a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010417f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104182:	5b                   	pop    %ebx
80104183:	5e                   	pop    %esi
80104184:	5d                   	pop    %ebp
80104185:	c3                   	ret    
    return -1;
80104186:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010418b:	eb f2                	jmp    8010417f <argptr+0x45>
    return -1;
8010418d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104192:	eb eb                	jmp    8010417f <argptr+0x45>
80104194:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104199:	eb e4                	jmp    8010417f <argptr+0x45>
8010419b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041a0:	eb dd                	jmp    8010417f <argptr+0x45>

801041a2 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
801041a2:	55                   	push   %ebp
801041a3:	89 e5                	mov    %esp,%ebp
801041a5:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
801041a8:	8d 45 f4             	lea    -0xc(%ebp),%eax
801041ab:	50                   	push   %eax
801041ac:	ff 75 08             	pushl  0x8(%ebp)
801041af:	e8 5e ff ff ff       	call   80104112 <argint>
801041b4:	83 c4 10             	add    $0x10,%esp
801041b7:	85 c0                	test   %eax,%eax
801041b9:	78 13                	js     801041ce <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
801041bb:	83 ec 08             	sub    $0x8,%esp
801041be:	ff 75 0c             	pushl  0xc(%ebp)
801041c1:	ff 75 f4             	pushl  -0xc(%ebp)
801041c4:	e8 09 ff ff ff       	call   801040d2 <fetchstr>
801041c9:	83 c4 10             	add    $0x10,%esp
}
801041cc:	c9                   	leave  
801041cd:	c3                   	ret    
    return -1;
801041ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041d3:	eb f7                	jmp    801041cc <argstr+0x2a>

801041d5 <syscall>:
[SYS_dump_physmem]  sys_dump_physmem,
};

void
syscall(void)
{
801041d5:	55                   	push   %ebp
801041d6:	89 e5                	mov    %esp,%ebp
801041d8:	53                   	push   %ebx
801041d9:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
801041dc:	e8 29 f2 ff ff       	call   8010340a <myproc>
801041e1:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
801041e3:	8b 40 18             	mov    0x18(%eax),%eax
801041e6:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801041e9:	8d 50 ff             	lea    -0x1(%eax),%edx
801041ec:	83 fa 15             	cmp    $0x15,%edx
801041ef:	77 18                	ja     80104209 <syscall+0x34>
801041f1:	8b 14 85 20 6e 10 80 	mov    -0x7fef91e0(,%eax,4),%edx
801041f8:	85 d2                	test   %edx,%edx
801041fa:	74 0d                	je     80104209 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
801041fc:	ff d2                	call   *%edx
801041fe:	8b 53 18             	mov    0x18(%ebx),%edx
80104201:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
80104204:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104207:	c9                   	leave  
80104208:	c3                   	ret    
            curproc->pid, curproc->name, num);
80104209:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
8010420c:	50                   	push   %eax
8010420d:	52                   	push   %edx
8010420e:	ff 73 10             	pushl  0x10(%ebx)
80104211:	68 f1 6d 10 80       	push   $0x80106df1
80104216:	e8 f0 c3 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
8010421b:	8b 43 18             	mov    0x18(%ebx),%eax
8010421e:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
80104225:	83 c4 10             	add    $0x10,%esp
80104228:	eb da                	jmp    80104204 <syscall+0x2f>

8010422a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010422a:	55                   	push   %ebp
8010422b:	89 e5                	mov    %esp,%ebp
8010422d:	56                   	push   %esi
8010422e:	53                   	push   %ebx
8010422f:	83 ec 18             	sub    $0x18,%esp
80104232:	89 d6                	mov    %edx,%esi
80104234:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80104236:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104239:	52                   	push   %edx
8010423a:	50                   	push   %eax
8010423b:	e8 d2 fe ff ff       	call   80104112 <argint>
80104240:	83 c4 10             	add    $0x10,%esp
80104243:	85 c0                	test   %eax,%eax
80104245:	78 2e                	js     80104275 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
80104247:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
8010424b:	77 2f                	ja     8010427c <argfd+0x52>
8010424d:	e8 b8 f1 ff ff       	call   8010340a <myproc>
80104252:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104255:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
80104259:	85 c0                	test   %eax,%eax
8010425b:	74 26                	je     80104283 <argfd+0x59>
    return -1;
  if(pfd)
8010425d:	85 f6                	test   %esi,%esi
8010425f:	74 02                	je     80104263 <argfd+0x39>
    *pfd = fd;
80104261:	89 16                	mov    %edx,(%esi)
  if(pf)
80104263:	85 db                	test   %ebx,%ebx
80104265:	74 23                	je     8010428a <argfd+0x60>
    *pf = f;
80104267:	89 03                	mov    %eax,(%ebx)
  return 0;
80104269:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010426e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104271:	5b                   	pop    %ebx
80104272:	5e                   	pop    %esi
80104273:	5d                   	pop    %ebp
80104274:	c3                   	ret    
    return -1;
80104275:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010427a:	eb f2                	jmp    8010426e <argfd+0x44>
    return -1;
8010427c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104281:	eb eb                	jmp    8010426e <argfd+0x44>
80104283:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104288:	eb e4                	jmp    8010426e <argfd+0x44>
  return 0;
8010428a:	b8 00 00 00 00       	mov    $0x0,%eax
8010428f:	eb dd                	jmp    8010426e <argfd+0x44>

80104291 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104291:	55                   	push   %ebp
80104292:	89 e5                	mov    %esp,%ebp
80104294:	53                   	push   %ebx
80104295:	83 ec 04             	sub    $0x4,%esp
80104298:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
8010429a:	e8 6b f1 ff ff       	call   8010340a <myproc>

  for(fd = 0; fd < NOFILE; fd++){
8010429f:	ba 00 00 00 00       	mov    $0x0,%edx
801042a4:	83 fa 0f             	cmp    $0xf,%edx
801042a7:	7f 18                	jg     801042c1 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
801042a9:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
801042ae:	74 05                	je     801042b5 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
801042b0:	83 c2 01             	add    $0x1,%edx
801042b3:	eb ef                	jmp    801042a4 <fdalloc+0x13>
      curproc->ofile[fd] = f;
801042b5:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
801042b9:	89 d0                	mov    %edx,%eax
801042bb:	83 c4 04             	add    $0x4,%esp
801042be:	5b                   	pop    %ebx
801042bf:	5d                   	pop    %ebp
801042c0:	c3                   	ret    
  return -1;
801042c1:	ba ff ff ff ff       	mov    $0xffffffff,%edx
801042c6:	eb f1                	jmp    801042b9 <fdalloc+0x28>

801042c8 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801042c8:	55                   	push   %ebp
801042c9:	89 e5                	mov    %esp,%ebp
801042cb:	56                   	push   %esi
801042cc:	53                   	push   %ebx
801042cd:	83 ec 10             	sub    $0x10,%esp
801042d0:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801042d2:	b8 20 00 00 00       	mov    $0x20,%eax
801042d7:	89 c6                	mov    %eax,%esi
801042d9:	39 43 58             	cmp    %eax,0x58(%ebx)
801042dc:	76 2e                	jbe    8010430c <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801042de:	6a 10                	push   $0x10
801042e0:	50                   	push   %eax
801042e1:	8d 45 e8             	lea    -0x18(%ebp),%eax
801042e4:	50                   	push   %eax
801042e5:	53                   	push   %ebx
801042e6:	e8 88 d4 ff ff       	call   80101773 <readi>
801042eb:	83 c4 10             	add    $0x10,%esp
801042ee:	83 f8 10             	cmp    $0x10,%eax
801042f1:	75 0c                	jne    801042ff <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
801042f3:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
801042f8:	75 1e                	jne    80104318 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801042fa:	8d 46 10             	lea    0x10(%esi),%eax
801042fd:	eb d8                	jmp    801042d7 <isdirempty+0xf>
      panic("isdirempty: readi");
801042ff:	83 ec 0c             	sub    $0xc,%esp
80104302:	68 7c 6e 10 80       	push   $0x80106e7c
80104307:	e8 3c c0 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
8010430c:	b8 01 00 00 00       	mov    $0x1,%eax
}
80104311:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104314:	5b                   	pop    %ebx
80104315:	5e                   	pop    %esi
80104316:	5d                   	pop    %ebp
80104317:	c3                   	ret    
      return 0;
80104318:	b8 00 00 00 00       	mov    $0x0,%eax
8010431d:	eb f2                	jmp    80104311 <isdirempty+0x49>

8010431f <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
8010431f:	55                   	push   %ebp
80104320:	89 e5                	mov    %esp,%ebp
80104322:	57                   	push   %edi
80104323:	56                   	push   %esi
80104324:	53                   	push   %ebx
80104325:	83 ec 44             	sub    $0x44,%esp
80104328:	89 55 c4             	mov    %edx,-0x3c(%ebp)
8010432b:	89 4d c0             	mov    %ecx,-0x40(%ebp)
8010432e:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104331:	8d 55 d6             	lea    -0x2a(%ebp),%edx
80104334:	52                   	push   %edx
80104335:	50                   	push   %eax
80104336:	e8 be d8 ff ff       	call   80101bf9 <nameiparent>
8010433b:	89 c6                	mov    %eax,%esi
8010433d:	83 c4 10             	add    $0x10,%esp
80104340:	85 c0                	test   %eax,%eax
80104342:	0f 84 3a 01 00 00    	je     80104482 <create+0x163>
    return 0;
  ilock(dp);
80104348:	83 ec 0c             	sub    $0xc,%esp
8010434b:	50                   	push   %eax
8010434c:	e8 30 d2 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104351:	83 c4 0c             	add    $0xc,%esp
80104354:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104357:	50                   	push   %eax
80104358:	8d 45 d6             	lea    -0x2a(%ebp),%eax
8010435b:	50                   	push   %eax
8010435c:	56                   	push   %esi
8010435d:	e8 4e d6 ff ff       	call   801019b0 <dirlookup>
80104362:	89 c3                	mov    %eax,%ebx
80104364:	83 c4 10             	add    $0x10,%esp
80104367:	85 c0                	test   %eax,%eax
80104369:	74 3f                	je     801043aa <create+0x8b>
    iunlockput(dp);
8010436b:	83 ec 0c             	sub    $0xc,%esp
8010436e:	56                   	push   %esi
8010436f:	e8 b4 d3 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
80104374:	89 1c 24             	mov    %ebx,(%esp)
80104377:	e8 05 d2 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010437c:	83 c4 10             	add    $0x10,%esp
8010437f:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
80104384:	75 11                	jne    80104397 <create+0x78>
80104386:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
8010438b:	75 0a                	jne    80104397 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
8010438d:	89 d8                	mov    %ebx,%eax
8010438f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104392:	5b                   	pop    %ebx
80104393:	5e                   	pop    %esi
80104394:	5f                   	pop    %edi
80104395:	5d                   	pop    %ebp
80104396:	c3                   	ret    
    iunlockput(ip);
80104397:	83 ec 0c             	sub    $0xc,%esp
8010439a:	53                   	push   %ebx
8010439b:	e8 88 d3 ff ff       	call   80101728 <iunlockput>
    return 0;
801043a0:	83 c4 10             	add    $0x10,%esp
801043a3:	bb 00 00 00 00       	mov    $0x0,%ebx
801043a8:	eb e3                	jmp    8010438d <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
801043aa:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
801043ae:	83 ec 08             	sub    $0x8,%esp
801043b1:	50                   	push   %eax
801043b2:	ff 36                	pushl  (%esi)
801043b4:	e8 c5 cf ff ff       	call   8010137e <ialloc>
801043b9:	89 c3                	mov    %eax,%ebx
801043bb:	83 c4 10             	add    $0x10,%esp
801043be:	85 c0                	test   %eax,%eax
801043c0:	74 55                	je     80104417 <create+0xf8>
  ilock(ip);
801043c2:	83 ec 0c             	sub    $0xc,%esp
801043c5:	50                   	push   %eax
801043c6:	e8 b6 d1 ff ff       	call   80101581 <ilock>
  ip->major = major;
801043cb:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
801043cf:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
801043d3:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
801043d7:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
801043dd:	89 1c 24             	mov    %ebx,(%esp)
801043e0:	e8 3b d0 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
801043e5:	83 c4 10             	add    $0x10,%esp
801043e8:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
801043ed:	74 35                	je     80104424 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
801043ef:	83 ec 04             	sub    $0x4,%esp
801043f2:	ff 73 04             	pushl  0x4(%ebx)
801043f5:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801043f8:	50                   	push   %eax
801043f9:	56                   	push   %esi
801043fa:	e8 31 d7 ff ff       	call   80101b30 <dirlink>
801043ff:	83 c4 10             	add    $0x10,%esp
80104402:	85 c0                	test   %eax,%eax
80104404:	78 6f                	js     80104475 <create+0x156>
  iunlockput(dp);
80104406:	83 ec 0c             	sub    $0xc,%esp
80104409:	56                   	push   %esi
8010440a:	e8 19 d3 ff ff       	call   80101728 <iunlockput>
  return ip;
8010440f:	83 c4 10             	add    $0x10,%esp
80104412:	e9 76 ff ff ff       	jmp    8010438d <create+0x6e>
    panic("create: ialloc");
80104417:	83 ec 0c             	sub    $0xc,%esp
8010441a:	68 8e 6e 10 80       	push   $0x80106e8e
8010441f:	e8 24 bf ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
80104424:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104428:	83 c0 01             	add    $0x1,%eax
8010442b:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
8010442f:	83 ec 0c             	sub    $0xc,%esp
80104432:	56                   	push   %esi
80104433:	e8 e8 cf ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80104438:	83 c4 0c             	add    $0xc,%esp
8010443b:	ff 73 04             	pushl  0x4(%ebx)
8010443e:	68 9e 6e 10 80       	push   $0x80106e9e
80104443:	53                   	push   %ebx
80104444:	e8 e7 d6 ff ff       	call   80101b30 <dirlink>
80104449:	83 c4 10             	add    $0x10,%esp
8010444c:	85 c0                	test   %eax,%eax
8010444e:	78 18                	js     80104468 <create+0x149>
80104450:	83 ec 04             	sub    $0x4,%esp
80104453:	ff 76 04             	pushl  0x4(%esi)
80104456:	68 9d 6e 10 80       	push   $0x80106e9d
8010445b:	53                   	push   %ebx
8010445c:	e8 cf d6 ff ff       	call   80101b30 <dirlink>
80104461:	83 c4 10             	add    $0x10,%esp
80104464:	85 c0                	test   %eax,%eax
80104466:	79 87                	jns    801043ef <create+0xd0>
      panic("create dots");
80104468:	83 ec 0c             	sub    $0xc,%esp
8010446b:	68 a0 6e 10 80       	push   $0x80106ea0
80104470:	e8 d3 be ff ff       	call   80100348 <panic>
    panic("create: dirlink");
80104475:	83 ec 0c             	sub    $0xc,%esp
80104478:	68 ac 6e 10 80       	push   $0x80106eac
8010447d:	e8 c6 be ff ff       	call   80100348 <panic>
    return 0;
80104482:	89 c3                	mov    %eax,%ebx
80104484:	e9 04 ff ff ff       	jmp    8010438d <create+0x6e>

80104489 <sys_dup>:
{
80104489:	55                   	push   %ebp
8010448a:	89 e5                	mov    %esp,%ebp
8010448c:	53                   	push   %ebx
8010448d:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104490:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104493:	ba 00 00 00 00       	mov    $0x0,%edx
80104498:	b8 00 00 00 00       	mov    $0x0,%eax
8010449d:	e8 88 fd ff ff       	call   8010422a <argfd>
801044a2:	85 c0                	test   %eax,%eax
801044a4:	78 23                	js     801044c9 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
801044a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044a9:	e8 e3 fd ff ff       	call   80104291 <fdalloc>
801044ae:	89 c3                	mov    %eax,%ebx
801044b0:	85 c0                	test   %eax,%eax
801044b2:	78 1c                	js     801044d0 <sys_dup+0x47>
  filedup(f);
801044b4:	83 ec 0c             	sub    $0xc,%esp
801044b7:	ff 75 f4             	pushl  -0xc(%ebp)
801044ba:	e8 cf c7 ff ff       	call   80100c8e <filedup>
  return fd;
801044bf:	83 c4 10             	add    $0x10,%esp
}
801044c2:	89 d8                	mov    %ebx,%eax
801044c4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801044c7:	c9                   	leave  
801044c8:	c3                   	ret    
    return -1;
801044c9:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801044ce:	eb f2                	jmp    801044c2 <sys_dup+0x39>
    return -1;
801044d0:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801044d5:	eb eb                	jmp    801044c2 <sys_dup+0x39>

801044d7 <sys_read>:
{
801044d7:	55                   	push   %ebp
801044d8:	89 e5                	mov    %esp,%ebp
801044da:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801044dd:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801044e0:	ba 00 00 00 00       	mov    $0x0,%edx
801044e5:	b8 00 00 00 00       	mov    $0x0,%eax
801044ea:	e8 3b fd ff ff       	call   8010422a <argfd>
801044ef:	85 c0                	test   %eax,%eax
801044f1:	78 43                	js     80104536 <sys_read+0x5f>
801044f3:	83 ec 08             	sub    $0x8,%esp
801044f6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801044f9:	50                   	push   %eax
801044fa:	6a 02                	push   $0x2
801044fc:	e8 11 fc ff ff       	call   80104112 <argint>
80104501:	83 c4 10             	add    $0x10,%esp
80104504:	85 c0                	test   %eax,%eax
80104506:	78 35                	js     8010453d <sys_read+0x66>
80104508:	83 ec 04             	sub    $0x4,%esp
8010450b:	ff 75 f0             	pushl  -0x10(%ebp)
8010450e:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104511:	50                   	push   %eax
80104512:	6a 01                	push   $0x1
80104514:	e8 21 fc ff ff       	call   8010413a <argptr>
80104519:	83 c4 10             	add    $0x10,%esp
8010451c:	85 c0                	test   %eax,%eax
8010451e:	78 24                	js     80104544 <sys_read+0x6d>
  return fileread(f, p, n);
80104520:	83 ec 04             	sub    $0x4,%esp
80104523:	ff 75 f0             	pushl  -0x10(%ebp)
80104526:	ff 75 ec             	pushl  -0x14(%ebp)
80104529:	ff 75 f4             	pushl  -0xc(%ebp)
8010452c:	e8 a6 c8 ff ff       	call   80100dd7 <fileread>
80104531:	83 c4 10             	add    $0x10,%esp
}
80104534:	c9                   	leave  
80104535:	c3                   	ret    
    return -1;
80104536:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010453b:	eb f7                	jmp    80104534 <sys_read+0x5d>
8010453d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104542:	eb f0                	jmp    80104534 <sys_read+0x5d>
80104544:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104549:	eb e9                	jmp    80104534 <sys_read+0x5d>

8010454b <sys_write>:
{
8010454b:	55                   	push   %ebp
8010454c:	89 e5                	mov    %esp,%ebp
8010454e:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104551:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104554:	ba 00 00 00 00       	mov    $0x0,%edx
80104559:	b8 00 00 00 00       	mov    $0x0,%eax
8010455e:	e8 c7 fc ff ff       	call   8010422a <argfd>
80104563:	85 c0                	test   %eax,%eax
80104565:	78 43                	js     801045aa <sys_write+0x5f>
80104567:	83 ec 08             	sub    $0x8,%esp
8010456a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010456d:	50                   	push   %eax
8010456e:	6a 02                	push   $0x2
80104570:	e8 9d fb ff ff       	call   80104112 <argint>
80104575:	83 c4 10             	add    $0x10,%esp
80104578:	85 c0                	test   %eax,%eax
8010457a:	78 35                	js     801045b1 <sys_write+0x66>
8010457c:	83 ec 04             	sub    $0x4,%esp
8010457f:	ff 75 f0             	pushl  -0x10(%ebp)
80104582:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104585:	50                   	push   %eax
80104586:	6a 01                	push   $0x1
80104588:	e8 ad fb ff ff       	call   8010413a <argptr>
8010458d:	83 c4 10             	add    $0x10,%esp
80104590:	85 c0                	test   %eax,%eax
80104592:	78 24                	js     801045b8 <sys_write+0x6d>
  return filewrite(f, p, n);
80104594:	83 ec 04             	sub    $0x4,%esp
80104597:	ff 75 f0             	pushl  -0x10(%ebp)
8010459a:	ff 75 ec             	pushl  -0x14(%ebp)
8010459d:	ff 75 f4             	pushl  -0xc(%ebp)
801045a0:	e8 b7 c8 ff ff       	call   80100e5c <filewrite>
801045a5:	83 c4 10             	add    $0x10,%esp
}
801045a8:	c9                   	leave  
801045a9:	c3                   	ret    
    return -1;
801045aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045af:	eb f7                	jmp    801045a8 <sys_write+0x5d>
801045b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045b6:	eb f0                	jmp    801045a8 <sys_write+0x5d>
801045b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045bd:	eb e9                	jmp    801045a8 <sys_write+0x5d>

801045bf <sys_close>:
{
801045bf:	55                   	push   %ebp
801045c0:	89 e5                	mov    %esp,%ebp
801045c2:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
801045c5:	8d 4d f0             	lea    -0x10(%ebp),%ecx
801045c8:	8d 55 f4             	lea    -0xc(%ebp),%edx
801045cb:	b8 00 00 00 00       	mov    $0x0,%eax
801045d0:	e8 55 fc ff ff       	call   8010422a <argfd>
801045d5:	85 c0                	test   %eax,%eax
801045d7:	78 25                	js     801045fe <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
801045d9:	e8 2c ee ff ff       	call   8010340a <myproc>
801045de:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045e1:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
801045e8:	00 
  fileclose(f);
801045e9:	83 ec 0c             	sub    $0xc,%esp
801045ec:	ff 75 f0             	pushl  -0x10(%ebp)
801045ef:	e8 df c6 ff ff       	call   80100cd3 <fileclose>
  return 0;
801045f4:	83 c4 10             	add    $0x10,%esp
801045f7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801045fc:	c9                   	leave  
801045fd:	c3                   	ret    
    return -1;
801045fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104603:	eb f7                	jmp    801045fc <sys_close+0x3d>

80104605 <sys_fstat>:
{
80104605:	55                   	push   %ebp
80104606:	89 e5                	mov    %esp,%ebp
80104608:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010460b:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010460e:	ba 00 00 00 00       	mov    $0x0,%edx
80104613:	b8 00 00 00 00       	mov    $0x0,%eax
80104618:	e8 0d fc ff ff       	call   8010422a <argfd>
8010461d:	85 c0                	test   %eax,%eax
8010461f:	78 2a                	js     8010464b <sys_fstat+0x46>
80104621:	83 ec 04             	sub    $0x4,%esp
80104624:	6a 14                	push   $0x14
80104626:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104629:	50                   	push   %eax
8010462a:	6a 01                	push   $0x1
8010462c:	e8 09 fb ff ff       	call   8010413a <argptr>
80104631:	83 c4 10             	add    $0x10,%esp
80104634:	85 c0                	test   %eax,%eax
80104636:	78 1a                	js     80104652 <sys_fstat+0x4d>
  return filestat(f, st);
80104638:	83 ec 08             	sub    $0x8,%esp
8010463b:	ff 75 f0             	pushl  -0x10(%ebp)
8010463e:	ff 75 f4             	pushl  -0xc(%ebp)
80104641:	e8 4a c7 ff ff       	call   80100d90 <filestat>
80104646:	83 c4 10             	add    $0x10,%esp
}
80104649:	c9                   	leave  
8010464a:	c3                   	ret    
    return -1;
8010464b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104650:	eb f7                	jmp    80104649 <sys_fstat+0x44>
80104652:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104657:	eb f0                	jmp    80104649 <sys_fstat+0x44>

80104659 <sys_link>:
{
80104659:	55                   	push   %ebp
8010465a:	89 e5                	mov    %esp,%ebp
8010465c:	56                   	push   %esi
8010465d:	53                   	push   %ebx
8010465e:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104661:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104664:	50                   	push   %eax
80104665:	6a 00                	push   $0x0
80104667:	e8 36 fb ff ff       	call   801041a2 <argstr>
8010466c:	83 c4 10             	add    $0x10,%esp
8010466f:	85 c0                	test   %eax,%eax
80104671:	0f 88 32 01 00 00    	js     801047a9 <sys_link+0x150>
80104677:	83 ec 08             	sub    $0x8,%esp
8010467a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010467d:	50                   	push   %eax
8010467e:	6a 01                	push   $0x1
80104680:	e8 1d fb ff ff       	call   801041a2 <argstr>
80104685:	83 c4 10             	add    $0x10,%esp
80104688:	85 c0                	test   %eax,%eax
8010468a:	0f 88 20 01 00 00    	js     801047b0 <sys_link+0x157>
  begin_op();
80104690:	e8 14 e3 ff ff       	call   801029a9 <begin_op>
  if((ip = namei(old)) == 0){
80104695:	83 ec 0c             	sub    $0xc,%esp
80104698:	ff 75 e0             	pushl  -0x20(%ebp)
8010469b:	e8 41 d5 ff ff       	call   80101be1 <namei>
801046a0:	89 c3                	mov    %eax,%ebx
801046a2:	83 c4 10             	add    $0x10,%esp
801046a5:	85 c0                	test   %eax,%eax
801046a7:	0f 84 99 00 00 00    	je     80104746 <sys_link+0xed>
  ilock(ip);
801046ad:	83 ec 0c             	sub    $0xc,%esp
801046b0:	50                   	push   %eax
801046b1:	e8 cb ce ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
801046b6:	83 c4 10             	add    $0x10,%esp
801046b9:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801046be:	0f 84 8e 00 00 00    	je     80104752 <sys_link+0xf9>
  ip->nlink++;
801046c4:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801046c8:	83 c0 01             	add    $0x1,%eax
801046cb:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801046cf:	83 ec 0c             	sub    $0xc,%esp
801046d2:	53                   	push   %ebx
801046d3:	e8 48 cd ff ff       	call   80101420 <iupdate>
  iunlock(ip);
801046d8:	89 1c 24             	mov    %ebx,(%esp)
801046db:	e8 63 cf ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
801046e0:	83 c4 08             	add    $0x8,%esp
801046e3:	8d 45 ea             	lea    -0x16(%ebp),%eax
801046e6:	50                   	push   %eax
801046e7:	ff 75 e4             	pushl  -0x1c(%ebp)
801046ea:	e8 0a d5 ff ff       	call   80101bf9 <nameiparent>
801046ef:	89 c6                	mov    %eax,%esi
801046f1:	83 c4 10             	add    $0x10,%esp
801046f4:	85 c0                	test   %eax,%eax
801046f6:	74 7e                	je     80104776 <sys_link+0x11d>
  ilock(dp);
801046f8:	83 ec 0c             	sub    $0xc,%esp
801046fb:	50                   	push   %eax
801046fc:	e8 80 ce ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80104701:	83 c4 10             	add    $0x10,%esp
80104704:	8b 03                	mov    (%ebx),%eax
80104706:	39 06                	cmp    %eax,(%esi)
80104708:	75 60                	jne    8010476a <sys_link+0x111>
8010470a:	83 ec 04             	sub    $0x4,%esp
8010470d:	ff 73 04             	pushl  0x4(%ebx)
80104710:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104713:	50                   	push   %eax
80104714:	56                   	push   %esi
80104715:	e8 16 d4 ff ff       	call   80101b30 <dirlink>
8010471a:	83 c4 10             	add    $0x10,%esp
8010471d:	85 c0                	test   %eax,%eax
8010471f:	78 49                	js     8010476a <sys_link+0x111>
  iunlockput(dp);
80104721:	83 ec 0c             	sub    $0xc,%esp
80104724:	56                   	push   %esi
80104725:	e8 fe cf ff ff       	call   80101728 <iunlockput>
  iput(ip);
8010472a:	89 1c 24             	mov    %ebx,(%esp)
8010472d:	e8 56 cf ff ff       	call   80101688 <iput>
  end_op();
80104732:	e8 ec e2 ff ff       	call   80102a23 <end_op>
  return 0;
80104737:	83 c4 10             	add    $0x10,%esp
8010473a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010473f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104742:	5b                   	pop    %ebx
80104743:	5e                   	pop    %esi
80104744:	5d                   	pop    %ebp
80104745:	c3                   	ret    
    end_op();
80104746:	e8 d8 e2 ff ff       	call   80102a23 <end_op>
    return -1;
8010474b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104750:	eb ed                	jmp    8010473f <sys_link+0xe6>
    iunlockput(ip);
80104752:	83 ec 0c             	sub    $0xc,%esp
80104755:	53                   	push   %ebx
80104756:	e8 cd cf ff ff       	call   80101728 <iunlockput>
    end_op();
8010475b:	e8 c3 e2 ff ff       	call   80102a23 <end_op>
    return -1;
80104760:	83 c4 10             	add    $0x10,%esp
80104763:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104768:	eb d5                	jmp    8010473f <sys_link+0xe6>
    iunlockput(dp);
8010476a:	83 ec 0c             	sub    $0xc,%esp
8010476d:	56                   	push   %esi
8010476e:	e8 b5 cf ff ff       	call   80101728 <iunlockput>
    goto bad;
80104773:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80104776:	83 ec 0c             	sub    $0xc,%esp
80104779:	53                   	push   %ebx
8010477a:	e8 02 ce ff ff       	call   80101581 <ilock>
  ip->nlink--;
8010477f:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104783:	83 e8 01             	sub    $0x1,%eax
80104786:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010478a:	89 1c 24             	mov    %ebx,(%esp)
8010478d:	e8 8e cc ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104792:	89 1c 24             	mov    %ebx,(%esp)
80104795:	e8 8e cf ff ff       	call   80101728 <iunlockput>
  end_op();
8010479a:	e8 84 e2 ff ff       	call   80102a23 <end_op>
  return -1;
8010479f:	83 c4 10             	add    $0x10,%esp
801047a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047a7:	eb 96                	jmp    8010473f <sys_link+0xe6>
    return -1;
801047a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047ae:	eb 8f                	jmp    8010473f <sys_link+0xe6>
801047b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047b5:	eb 88                	jmp    8010473f <sys_link+0xe6>

801047b7 <sys_unlink>:
{
801047b7:	55                   	push   %ebp
801047b8:	89 e5                	mov    %esp,%ebp
801047ba:	57                   	push   %edi
801047bb:	56                   	push   %esi
801047bc:	53                   	push   %ebx
801047bd:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
801047c0:	8d 45 c4             	lea    -0x3c(%ebp),%eax
801047c3:	50                   	push   %eax
801047c4:	6a 00                	push   $0x0
801047c6:	e8 d7 f9 ff ff       	call   801041a2 <argstr>
801047cb:	83 c4 10             	add    $0x10,%esp
801047ce:	85 c0                	test   %eax,%eax
801047d0:	0f 88 83 01 00 00    	js     80104959 <sys_unlink+0x1a2>
  begin_op();
801047d6:	e8 ce e1 ff ff       	call   801029a9 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
801047db:	83 ec 08             	sub    $0x8,%esp
801047de:	8d 45 ca             	lea    -0x36(%ebp),%eax
801047e1:	50                   	push   %eax
801047e2:	ff 75 c4             	pushl  -0x3c(%ebp)
801047e5:	e8 0f d4 ff ff       	call   80101bf9 <nameiparent>
801047ea:	89 c6                	mov    %eax,%esi
801047ec:	83 c4 10             	add    $0x10,%esp
801047ef:	85 c0                	test   %eax,%eax
801047f1:	0f 84 ed 00 00 00    	je     801048e4 <sys_unlink+0x12d>
  ilock(dp);
801047f7:	83 ec 0c             	sub    $0xc,%esp
801047fa:	50                   	push   %eax
801047fb:	e8 81 cd ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104800:	83 c4 08             	add    $0x8,%esp
80104803:	68 9e 6e 10 80       	push   $0x80106e9e
80104808:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010480b:	50                   	push   %eax
8010480c:	e8 8a d1 ff ff       	call   8010199b <namecmp>
80104811:	83 c4 10             	add    $0x10,%esp
80104814:	85 c0                	test   %eax,%eax
80104816:	0f 84 fc 00 00 00    	je     80104918 <sys_unlink+0x161>
8010481c:	83 ec 08             	sub    $0x8,%esp
8010481f:	68 9d 6e 10 80       	push   $0x80106e9d
80104824:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104827:	50                   	push   %eax
80104828:	e8 6e d1 ff ff       	call   8010199b <namecmp>
8010482d:	83 c4 10             	add    $0x10,%esp
80104830:	85 c0                	test   %eax,%eax
80104832:	0f 84 e0 00 00 00    	je     80104918 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
80104838:	83 ec 04             	sub    $0x4,%esp
8010483b:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010483e:	50                   	push   %eax
8010483f:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104842:	50                   	push   %eax
80104843:	56                   	push   %esi
80104844:	e8 67 d1 ff ff       	call   801019b0 <dirlookup>
80104849:	89 c3                	mov    %eax,%ebx
8010484b:	83 c4 10             	add    $0x10,%esp
8010484e:	85 c0                	test   %eax,%eax
80104850:	0f 84 c2 00 00 00    	je     80104918 <sys_unlink+0x161>
  ilock(ip);
80104856:	83 ec 0c             	sub    $0xc,%esp
80104859:	50                   	push   %eax
8010485a:	e8 22 cd ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
8010485f:	83 c4 10             	add    $0x10,%esp
80104862:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80104867:	0f 8e 83 00 00 00    	jle    801048f0 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010486d:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104872:	0f 84 85 00 00 00    	je     801048fd <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
80104878:	83 ec 04             	sub    $0x4,%esp
8010487b:	6a 10                	push   $0x10
8010487d:	6a 00                	push   $0x0
8010487f:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104882:	57                   	push   %edi
80104883:	e8 3f f6 ff ff       	call   80103ec7 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104888:	6a 10                	push   $0x10
8010488a:	ff 75 c0             	pushl  -0x40(%ebp)
8010488d:	57                   	push   %edi
8010488e:	56                   	push   %esi
8010488f:	e8 dc cf ff ff       	call   80101870 <writei>
80104894:	83 c4 20             	add    $0x20,%esp
80104897:	83 f8 10             	cmp    $0x10,%eax
8010489a:	0f 85 90 00 00 00    	jne    80104930 <sys_unlink+0x179>
  if(ip->type == T_DIR){
801048a0:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801048a5:	0f 84 92 00 00 00    	je     8010493d <sys_unlink+0x186>
  iunlockput(dp);
801048ab:	83 ec 0c             	sub    $0xc,%esp
801048ae:	56                   	push   %esi
801048af:	e8 74 ce ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
801048b4:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801048b8:	83 e8 01             	sub    $0x1,%eax
801048bb:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801048bf:	89 1c 24             	mov    %ebx,(%esp)
801048c2:	e8 59 cb ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
801048c7:	89 1c 24             	mov    %ebx,(%esp)
801048ca:	e8 59 ce ff ff       	call   80101728 <iunlockput>
  end_op();
801048cf:	e8 4f e1 ff ff       	call   80102a23 <end_op>
  return 0;
801048d4:	83 c4 10             	add    $0x10,%esp
801048d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801048dc:	8d 65 f4             	lea    -0xc(%ebp),%esp
801048df:	5b                   	pop    %ebx
801048e0:	5e                   	pop    %esi
801048e1:	5f                   	pop    %edi
801048e2:	5d                   	pop    %ebp
801048e3:	c3                   	ret    
    end_op();
801048e4:	e8 3a e1 ff ff       	call   80102a23 <end_op>
    return -1;
801048e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048ee:	eb ec                	jmp    801048dc <sys_unlink+0x125>
    panic("unlink: nlink < 1");
801048f0:	83 ec 0c             	sub    $0xc,%esp
801048f3:	68 bc 6e 10 80       	push   $0x80106ebc
801048f8:	e8 4b ba ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801048fd:	89 d8                	mov    %ebx,%eax
801048ff:	e8 c4 f9 ff ff       	call   801042c8 <isdirempty>
80104904:	85 c0                	test   %eax,%eax
80104906:	0f 85 6c ff ff ff    	jne    80104878 <sys_unlink+0xc1>
    iunlockput(ip);
8010490c:	83 ec 0c             	sub    $0xc,%esp
8010490f:	53                   	push   %ebx
80104910:	e8 13 ce ff ff       	call   80101728 <iunlockput>
    goto bad;
80104915:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104918:	83 ec 0c             	sub    $0xc,%esp
8010491b:	56                   	push   %esi
8010491c:	e8 07 ce ff ff       	call   80101728 <iunlockput>
  end_op();
80104921:	e8 fd e0 ff ff       	call   80102a23 <end_op>
  return -1;
80104926:	83 c4 10             	add    $0x10,%esp
80104929:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010492e:	eb ac                	jmp    801048dc <sys_unlink+0x125>
    panic("unlink: writei");
80104930:	83 ec 0c             	sub    $0xc,%esp
80104933:	68 ce 6e 10 80       	push   $0x80106ece
80104938:	e8 0b ba ff ff       	call   80100348 <panic>
    dp->nlink--;
8010493d:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104941:	83 e8 01             	sub    $0x1,%eax
80104944:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104948:	83 ec 0c             	sub    $0xc,%esp
8010494b:	56                   	push   %esi
8010494c:	e8 cf ca ff ff       	call   80101420 <iupdate>
80104951:	83 c4 10             	add    $0x10,%esp
80104954:	e9 52 ff ff ff       	jmp    801048ab <sys_unlink+0xf4>
    return -1;
80104959:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010495e:	e9 79 ff ff ff       	jmp    801048dc <sys_unlink+0x125>

80104963 <sys_open>:

int
sys_open(void)
{
80104963:	55                   	push   %ebp
80104964:	89 e5                	mov    %esp,%ebp
80104966:	57                   	push   %edi
80104967:	56                   	push   %esi
80104968:	53                   	push   %ebx
80104969:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
8010496c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010496f:	50                   	push   %eax
80104970:	6a 00                	push   $0x0
80104972:	e8 2b f8 ff ff       	call   801041a2 <argstr>
80104977:	83 c4 10             	add    $0x10,%esp
8010497a:	85 c0                	test   %eax,%eax
8010497c:	0f 88 30 01 00 00    	js     80104ab2 <sys_open+0x14f>
80104982:	83 ec 08             	sub    $0x8,%esp
80104985:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104988:	50                   	push   %eax
80104989:	6a 01                	push   $0x1
8010498b:	e8 82 f7 ff ff       	call   80104112 <argint>
80104990:	83 c4 10             	add    $0x10,%esp
80104993:	85 c0                	test   %eax,%eax
80104995:	0f 88 21 01 00 00    	js     80104abc <sys_open+0x159>
    return -1;

  begin_op();
8010499b:	e8 09 e0 ff ff       	call   801029a9 <begin_op>

  if(omode & O_CREATE){
801049a0:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
801049a4:	0f 84 84 00 00 00    	je     80104a2e <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
801049aa:	83 ec 0c             	sub    $0xc,%esp
801049ad:	6a 00                	push   $0x0
801049af:	b9 00 00 00 00       	mov    $0x0,%ecx
801049b4:	ba 02 00 00 00       	mov    $0x2,%edx
801049b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801049bc:	e8 5e f9 ff ff       	call   8010431f <create>
801049c1:	89 c6                	mov    %eax,%esi
    if(ip == 0){
801049c3:	83 c4 10             	add    $0x10,%esp
801049c6:	85 c0                	test   %eax,%eax
801049c8:	74 58                	je     80104a22 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801049ca:	e8 5e c2 ff ff       	call   80100c2d <filealloc>
801049cf:	89 c3                	mov    %eax,%ebx
801049d1:	85 c0                	test   %eax,%eax
801049d3:	0f 84 ae 00 00 00    	je     80104a87 <sys_open+0x124>
801049d9:	e8 b3 f8 ff ff       	call   80104291 <fdalloc>
801049de:	89 c7                	mov    %eax,%edi
801049e0:	85 c0                	test   %eax,%eax
801049e2:	0f 88 9f 00 00 00    	js     80104a87 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
801049e8:	83 ec 0c             	sub    $0xc,%esp
801049eb:	56                   	push   %esi
801049ec:	e8 52 cc ff ff       	call   80101643 <iunlock>
  end_op();
801049f1:	e8 2d e0 ff ff       	call   80102a23 <end_op>

  f->type = FD_INODE;
801049f6:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
801049fc:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
801049ff:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104a06:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104a09:	83 c4 10             	add    $0x10,%esp
80104a0c:	a8 01                	test   $0x1,%al
80104a0e:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104a12:	a8 03                	test   $0x3,%al
80104a14:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104a18:	89 f8                	mov    %edi,%eax
80104a1a:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104a1d:	5b                   	pop    %ebx
80104a1e:	5e                   	pop    %esi
80104a1f:	5f                   	pop    %edi
80104a20:	5d                   	pop    %ebp
80104a21:	c3                   	ret    
      end_op();
80104a22:	e8 fc df ff ff       	call   80102a23 <end_op>
      return -1;
80104a27:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a2c:	eb ea                	jmp    80104a18 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104a2e:	83 ec 0c             	sub    $0xc,%esp
80104a31:	ff 75 e4             	pushl  -0x1c(%ebp)
80104a34:	e8 a8 d1 ff ff       	call   80101be1 <namei>
80104a39:	89 c6                	mov    %eax,%esi
80104a3b:	83 c4 10             	add    $0x10,%esp
80104a3e:	85 c0                	test   %eax,%eax
80104a40:	74 39                	je     80104a7b <sys_open+0x118>
    ilock(ip);
80104a42:	83 ec 0c             	sub    $0xc,%esp
80104a45:	50                   	push   %eax
80104a46:	e8 36 cb ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104a4b:	83 c4 10             	add    $0x10,%esp
80104a4e:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104a53:	0f 85 71 ff ff ff    	jne    801049ca <sys_open+0x67>
80104a59:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104a5d:	0f 84 67 ff ff ff    	je     801049ca <sys_open+0x67>
      iunlockput(ip);
80104a63:	83 ec 0c             	sub    $0xc,%esp
80104a66:	56                   	push   %esi
80104a67:	e8 bc cc ff ff       	call   80101728 <iunlockput>
      end_op();
80104a6c:	e8 b2 df ff ff       	call   80102a23 <end_op>
      return -1;
80104a71:	83 c4 10             	add    $0x10,%esp
80104a74:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a79:	eb 9d                	jmp    80104a18 <sys_open+0xb5>
      end_op();
80104a7b:	e8 a3 df ff ff       	call   80102a23 <end_op>
      return -1;
80104a80:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a85:	eb 91                	jmp    80104a18 <sys_open+0xb5>
    if(f)
80104a87:	85 db                	test   %ebx,%ebx
80104a89:	74 0c                	je     80104a97 <sys_open+0x134>
      fileclose(f);
80104a8b:	83 ec 0c             	sub    $0xc,%esp
80104a8e:	53                   	push   %ebx
80104a8f:	e8 3f c2 ff ff       	call   80100cd3 <fileclose>
80104a94:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104a97:	83 ec 0c             	sub    $0xc,%esp
80104a9a:	56                   	push   %esi
80104a9b:	e8 88 cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104aa0:	e8 7e df ff ff       	call   80102a23 <end_op>
    return -1;
80104aa5:	83 c4 10             	add    $0x10,%esp
80104aa8:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104aad:	e9 66 ff ff ff       	jmp    80104a18 <sys_open+0xb5>
    return -1;
80104ab2:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104ab7:	e9 5c ff ff ff       	jmp    80104a18 <sys_open+0xb5>
80104abc:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104ac1:	e9 52 ff ff ff       	jmp    80104a18 <sys_open+0xb5>

80104ac6 <sys_mkdir>:

int
sys_mkdir(void)
{
80104ac6:	55                   	push   %ebp
80104ac7:	89 e5                	mov    %esp,%ebp
80104ac9:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104acc:	e8 d8 de ff ff       	call   801029a9 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104ad1:	83 ec 08             	sub    $0x8,%esp
80104ad4:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ad7:	50                   	push   %eax
80104ad8:	6a 00                	push   $0x0
80104ada:	e8 c3 f6 ff ff       	call   801041a2 <argstr>
80104adf:	83 c4 10             	add    $0x10,%esp
80104ae2:	85 c0                	test   %eax,%eax
80104ae4:	78 36                	js     80104b1c <sys_mkdir+0x56>
80104ae6:	83 ec 0c             	sub    $0xc,%esp
80104ae9:	6a 00                	push   $0x0
80104aeb:	b9 00 00 00 00       	mov    $0x0,%ecx
80104af0:	ba 01 00 00 00       	mov    $0x1,%edx
80104af5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104af8:	e8 22 f8 ff ff       	call   8010431f <create>
80104afd:	83 c4 10             	add    $0x10,%esp
80104b00:	85 c0                	test   %eax,%eax
80104b02:	74 18                	je     80104b1c <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104b04:	83 ec 0c             	sub    $0xc,%esp
80104b07:	50                   	push   %eax
80104b08:	e8 1b cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104b0d:	e8 11 df ff ff       	call   80102a23 <end_op>
  return 0;
80104b12:	83 c4 10             	add    $0x10,%esp
80104b15:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b1a:	c9                   	leave  
80104b1b:	c3                   	ret    
    end_op();
80104b1c:	e8 02 df ff ff       	call   80102a23 <end_op>
    return -1;
80104b21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b26:	eb f2                	jmp    80104b1a <sys_mkdir+0x54>

80104b28 <sys_mknod>:

int
sys_mknod(void)
{
80104b28:	55                   	push   %ebp
80104b29:	89 e5                	mov    %esp,%ebp
80104b2b:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104b2e:	e8 76 de ff ff       	call   801029a9 <begin_op>
  if((argstr(0, &path)) < 0 ||
80104b33:	83 ec 08             	sub    $0x8,%esp
80104b36:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b39:	50                   	push   %eax
80104b3a:	6a 00                	push   $0x0
80104b3c:	e8 61 f6 ff ff       	call   801041a2 <argstr>
80104b41:	83 c4 10             	add    $0x10,%esp
80104b44:	85 c0                	test   %eax,%eax
80104b46:	78 62                	js     80104baa <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104b48:	83 ec 08             	sub    $0x8,%esp
80104b4b:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104b4e:	50                   	push   %eax
80104b4f:	6a 01                	push   $0x1
80104b51:	e8 bc f5 ff ff       	call   80104112 <argint>
  if((argstr(0, &path)) < 0 ||
80104b56:	83 c4 10             	add    $0x10,%esp
80104b59:	85 c0                	test   %eax,%eax
80104b5b:	78 4d                	js     80104baa <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104b5d:	83 ec 08             	sub    $0x8,%esp
80104b60:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104b63:	50                   	push   %eax
80104b64:	6a 02                	push   $0x2
80104b66:	e8 a7 f5 ff ff       	call   80104112 <argint>
     argint(1, &major) < 0 ||
80104b6b:	83 c4 10             	add    $0x10,%esp
80104b6e:	85 c0                	test   %eax,%eax
80104b70:	78 38                	js     80104baa <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104b72:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104b76:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104b7a:	83 ec 0c             	sub    $0xc,%esp
80104b7d:	50                   	push   %eax
80104b7e:	ba 03 00 00 00       	mov    $0x3,%edx
80104b83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b86:	e8 94 f7 ff ff       	call   8010431f <create>
80104b8b:	83 c4 10             	add    $0x10,%esp
80104b8e:	85 c0                	test   %eax,%eax
80104b90:	74 18                	je     80104baa <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104b92:	83 ec 0c             	sub    $0xc,%esp
80104b95:	50                   	push   %eax
80104b96:	e8 8d cb ff ff       	call   80101728 <iunlockput>
  end_op();
80104b9b:	e8 83 de ff ff       	call   80102a23 <end_op>
  return 0;
80104ba0:	83 c4 10             	add    $0x10,%esp
80104ba3:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ba8:	c9                   	leave  
80104ba9:	c3                   	ret    
    end_op();
80104baa:	e8 74 de ff ff       	call   80102a23 <end_op>
    return -1;
80104baf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bb4:	eb f2                	jmp    80104ba8 <sys_mknod+0x80>

80104bb6 <sys_chdir>:

int
sys_chdir(void)
{
80104bb6:	55                   	push   %ebp
80104bb7:	89 e5                	mov    %esp,%ebp
80104bb9:	56                   	push   %esi
80104bba:	53                   	push   %ebx
80104bbb:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104bbe:	e8 47 e8 ff ff       	call   8010340a <myproc>
80104bc3:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104bc5:	e8 df dd ff ff       	call   801029a9 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104bca:	83 ec 08             	sub    $0x8,%esp
80104bcd:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104bd0:	50                   	push   %eax
80104bd1:	6a 00                	push   $0x0
80104bd3:	e8 ca f5 ff ff       	call   801041a2 <argstr>
80104bd8:	83 c4 10             	add    $0x10,%esp
80104bdb:	85 c0                	test   %eax,%eax
80104bdd:	78 52                	js     80104c31 <sys_chdir+0x7b>
80104bdf:	83 ec 0c             	sub    $0xc,%esp
80104be2:	ff 75 f4             	pushl  -0xc(%ebp)
80104be5:	e8 f7 cf ff ff       	call   80101be1 <namei>
80104bea:	89 c3                	mov    %eax,%ebx
80104bec:	83 c4 10             	add    $0x10,%esp
80104bef:	85 c0                	test   %eax,%eax
80104bf1:	74 3e                	je     80104c31 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104bf3:	83 ec 0c             	sub    $0xc,%esp
80104bf6:	50                   	push   %eax
80104bf7:	e8 85 c9 ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104bfc:	83 c4 10             	add    $0x10,%esp
80104bff:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104c04:	75 37                	jne    80104c3d <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104c06:	83 ec 0c             	sub    $0xc,%esp
80104c09:	53                   	push   %ebx
80104c0a:	e8 34 ca ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104c0f:	83 c4 04             	add    $0x4,%esp
80104c12:	ff 76 68             	pushl  0x68(%esi)
80104c15:	e8 6e ca ff ff       	call   80101688 <iput>
  end_op();
80104c1a:	e8 04 de ff ff       	call   80102a23 <end_op>
  curproc->cwd = ip;
80104c1f:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104c22:	83 c4 10             	add    $0x10,%esp
80104c25:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c2a:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104c2d:	5b                   	pop    %ebx
80104c2e:	5e                   	pop    %esi
80104c2f:	5d                   	pop    %ebp
80104c30:	c3                   	ret    
    end_op();
80104c31:	e8 ed dd ff ff       	call   80102a23 <end_op>
    return -1;
80104c36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c3b:	eb ed                	jmp    80104c2a <sys_chdir+0x74>
    iunlockput(ip);
80104c3d:	83 ec 0c             	sub    $0xc,%esp
80104c40:	53                   	push   %ebx
80104c41:	e8 e2 ca ff ff       	call   80101728 <iunlockput>
    end_op();
80104c46:	e8 d8 dd ff ff       	call   80102a23 <end_op>
    return -1;
80104c4b:	83 c4 10             	add    $0x10,%esp
80104c4e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c53:	eb d5                	jmp    80104c2a <sys_chdir+0x74>

80104c55 <sys_exec>:

int
sys_exec(void)
{
80104c55:	55                   	push   %ebp
80104c56:	89 e5                	mov    %esp,%ebp
80104c58:	53                   	push   %ebx
80104c59:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104c5f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c62:	50                   	push   %eax
80104c63:	6a 00                	push   $0x0
80104c65:	e8 38 f5 ff ff       	call   801041a2 <argstr>
80104c6a:	83 c4 10             	add    $0x10,%esp
80104c6d:	85 c0                	test   %eax,%eax
80104c6f:	0f 88 a8 00 00 00    	js     80104d1d <sys_exec+0xc8>
80104c75:	83 ec 08             	sub    $0x8,%esp
80104c78:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104c7e:	50                   	push   %eax
80104c7f:	6a 01                	push   $0x1
80104c81:	e8 8c f4 ff ff       	call   80104112 <argint>
80104c86:	83 c4 10             	add    $0x10,%esp
80104c89:	85 c0                	test   %eax,%eax
80104c8b:	0f 88 93 00 00 00    	js     80104d24 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104c91:	83 ec 04             	sub    $0x4,%esp
80104c94:	68 80 00 00 00       	push   $0x80
80104c99:	6a 00                	push   $0x0
80104c9b:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104ca1:	50                   	push   %eax
80104ca2:	e8 20 f2 ff ff       	call   80103ec7 <memset>
80104ca7:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104caa:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104caf:	83 fb 1f             	cmp    $0x1f,%ebx
80104cb2:	77 77                	ja     80104d2b <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104cb4:	83 ec 08             	sub    $0x8,%esp
80104cb7:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104cbd:	50                   	push   %eax
80104cbe:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104cc4:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104cc7:	50                   	push   %eax
80104cc8:	e8 c9 f3 ff ff       	call   80104096 <fetchint>
80104ccd:	83 c4 10             	add    $0x10,%esp
80104cd0:	85 c0                	test   %eax,%eax
80104cd2:	78 5e                	js     80104d32 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104cd4:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104cda:	85 c0                	test   %eax,%eax
80104cdc:	74 1d                	je     80104cfb <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104cde:	83 ec 08             	sub    $0x8,%esp
80104ce1:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104ce8:	52                   	push   %edx
80104ce9:	50                   	push   %eax
80104cea:	e8 e3 f3 ff ff       	call   801040d2 <fetchstr>
80104cef:	83 c4 10             	add    $0x10,%esp
80104cf2:	85 c0                	test   %eax,%eax
80104cf4:	78 46                	js     80104d3c <sys_exec+0xe7>
  for(i=0;; i++){
80104cf6:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104cf9:	eb b4                	jmp    80104caf <sys_exec+0x5a>
      argv[i] = 0;
80104cfb:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104d02:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104d06:	83 ec 08             	sub    $0x8,%esp
80104d09:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104d0f:	50                   	push   %eax
80104d10:	ff 75 f4             	pushl  -0xc(%ebp)
80104d13:	e8 ba bb ff ff       	call   801008d2 <exec>
80104d18:	83 c4 10             	add    $0x10,%esp
80104d1b:	eb 1a                	jmp    80104d37 <sys_exec+0xe2>
    return -1;
80104d1d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d22:	eb 13                	jmp    80104d37 <sys_exec+0xe2>
80104d24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d29:	eb 0c                	jmp    80104d37 <sys_exec+0xe2>
      return -1;
80104d2b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d30:	eb 05                	jmp    80104d37 <sys_exec+0xe2>
      return -1;
80104d32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104d37:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d3a:	c9                   	leave  
80104d3b:	c3                   	ret    
      return -1;
80104d3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d41:	eb f4                	jmp    80104d37 <sys_exec+0xe2>

80104d43 <sys_pipe>:

int
sys_pipe(void)
{
80104d43:	55                   	push   %ebp
80104d44:	89 e5                	mov    %esp,%ebp
80104d46:	53                   	push   %ebx
80104d47:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104d4a:	6a 08                	push   $0x8
80104d4c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d4f:	50                   	push   %eax
80104d50:	6a 00                	push   $0x0
80104d52:	e8 e3 f3 ff ff       	call   8010413a <argptr>
80104d57:	83 c4 10             	add    $0x10,%esp
80104d5a:	85 c0                	test   %eax,%eax
80104d5c:	78 77                	js     80104dd5 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104d5e:	83 ec 08             	sub    $0x8,%esp
80104d61:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104d64:	50                   	push   %eax
80104d65:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104d68:	50                   	push   %eax
80104d69:	e8 cd e1 ff ff       	call   80102f3b <pipealloc>
80104d6e:	83 c4 10             	add    $0x10,%esp
80104d71:	85 c0                	test   %eax,%eax
80104d73:	78 67                	js     80104ddc <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104d75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d78:	e8 14 f5 ff ff       	call   80104291 <fdalloc>
80104d7d:	89 c3                	mov    %eax,%ebx
80104d7f:	85 c0                	test   %eax,%eax
80104d81:	78 21                	js     80104da4 <sys_pipe+0x61>
80104d83:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104d86:	e8 06 f5 ff ff       	call   80104291 <fdalloc>
80104d8b:	85 c0                	test   %eax,%eax
80104d8d:	78 15                	js     80104da4 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104d8f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d92:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104d94:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d97:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104d9a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d9f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104da2:	c9                   	leave  
80104da3:	c3                   	ret    
    if(fd0 >= 0)
80104da4:	85 db                	test   %ebx,%ebx
80104da6:	78 0d                	js     80104db5 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104da8:	e8 5d e6 ff ff       	call   8010340a <myproc>
80104dad:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104db4:	00 
    fileclose(rf);
80104db5:	83 ec 0c             	sub    $0xc,%esp
80104db8:	ff 75 f0             	pushl  -0x10(%ebp)
80104dbb:	e8 13 bf ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104dc0:	83 c4 04             	add    $0x4,%esp
80104dc3:	ff 75 ec             	pushl  -0x14(%ebp)
80104dc6:	e8 08 bf ff ff       	call   80100cd3 <fileclose>
    return -1;
80104dcb:	83 c4 10             	add    $0x10,%esp
80104dce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dd3:	eb ca                	jmp    80104d9f <sys_pipe+0x5c>
    return -1;
80104dd5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dda:	eb c3                	jmp    80104d9f <sys_pipe+0x5c>
    return -1;
80104ddc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104de1:	eb bc                	jmp    80104d9f <sys_pipe+0x5c>

80104de3 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104de3:	55                   	push   %ebp
80104de4:	89 e5                	mov    %esp,%ebp
80104de6:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104de9:	e8 94 e7 ff ff       	call   80103582 <fork>
}
80104dee:	c9                   	leave  
80104def:	c3                   	ret    

80104df0 <sys_exit>:

int
sys_exit(void)
{
80104df0:	55                   	push   %ebp
80104df1:	89 e5                	mov    %esp,%ebp
80104df3:	83 ec 08             	sub    $0x8,%esp
  exit();
80104df6:	e8 bb e9 ff ff       	call   801037b6 <exit>
  return 0;  // not reached
}
80104dfb:	b8 00 00 00 00       	mov    $0x0,%eax
80104e00:	c9                   	leave  
80104e01:	c3                   	ret    

80104e02 <sys_wait>:

int
sys_wait(void)
{
80104e02:	55                   	push   %ebp
80104e03:	89 e5                	mov    %esp,%ebp
80104e05:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104e08:	e8 32 eb ff ff       	call   8010393f <wait>
}
80104e0d:	c9                   	leave  
80104e0e:	c3                   	ret    

80104e0f <sys_kill>:

int
sys_kill(void)
{
80104e0f:	55                   	push   %ebp
80104e10:	89 e5                	mov    %esp,%ebp
80104e12:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104e15:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e18:	50                   	push   %eax
80104e19:	6a 00                	push   $0x0
80104e1b:	e8 f2 f2 ff ff       	call   80104112 <argint>
80104e20:	83 c4 10             	add    $0x10,%esp
80104e23:	85 c0                	test   %eax,%eax
80104e25:	78 10                	js     80104e37 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104e27:	83 ec 0c             	sub    $0xc,%esp
80104e2a:	ff 75 f4             	pushl  -0xc(%ebp)
80104e2d:	e8 0a ec ff ff       	call   80103a3c <kill>
80104e32:	83 c4 10             	add    $0x10,%esp
}
80104e35:	c9                   	leave  
80104e36:	c3                   	ret    
    return -1;
80104e37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e3c:	eb f7                	jmp    80104e35 <sys_kill+0x26>

80104e3e <sys_getpid>:

int
sys_getpid(void)
{
80104e3e:	55                   	push   %ebp
80104e3f:	89 e5                	mov    %esp,%ebp
80104e41:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104e44:	e8 c1 e5 ff ff       	call   8010340a <myproc>
80104e49:	8b 40 10             	mov    0x10(%eax),%eax
}
80104e4c:	c9                   	leave  
80104e4d:	c3                   	ret    

80104e4e <sys_sbrk>:

int
sys_sbrk(void)
{
80104e4e:	55                   	push   %ebp
80104e4f:	89 e5                	mov    %esp,%ebp
80104e51:	53                   	push   %ebx
80104e52:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104e55:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e58:	50                   	push   %eax
80104e59:	6a 00                	push   $0x0
80104e5b:	e8 b2 f2 ff ff       	call   80104112 <argint>
80104e60:	83 c4 10             	add    $0x10,%esp
80104e63:	85 c0                	test   %eax,%eax
80104e65:	78 27                	js     80104e8e <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104e67:	e8 9e e5 ff ff       	call   8010340a <myproc>
80104e6c:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104e6e:	83 ec 0c             	sub    $0xc,%esp
80104e71:	ff 75 f4             	pushl  -0xc(%ebp)
80104e74:	e8 9c e6 ff ff       	call   80103515 <growproc>
80104e79:	83 c4 10             	add    $0x10,%esp
80104e7c:	85 c0                	test   %eax,%eax
80104e7e:	78 07                	js     80104e87 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104e80:	89 d8                	mov    %ebx,%eax
80104e82:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e85:	c9                   	leave  
80104e86:	c3                   	ret    
    return -1;
80104e87:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104e8c:	eb f2                	jmp    80104e80 <sys_sbrk+0x32>
    return -1;
80104e8e:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104e93:	eb eb                	jmp    80104e80 <sys_sbrk+0x32>

80104e95 <sys_sleep>:

int
sys_sleep(void)
{
80104e95:	55                   	push   %ebp
80104e96:	89 e5                	mov    %esp,%ebp
80104e98:	53                   	push   %ebx
80104e99:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104e9c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e9f:	50                   	push   %eax
80104ea0:	6a 00                	push   $0x0
80104ea2:	e8 6b f2 ff ff       	call   80104112 <argint>
80104ea7:	83 c4 10             	add    $0x10,%esp
80104eaa:	85 c0                	test   %eax,%eax
80104eac:	78 75                	js     80104f23 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104eae:	83 ec 0c             	sub    $0xc,%esp
80104eb1:	68 80 4c 13 80       	push   $0x80134c80
80104eb6:	e8 60 ef ff ff       	call   80103e1b <acquire>
  ticks0 = ticks;
80104ebb:	8b 1d c0 54 13 80    	mov    0x801354c0,%ebx
  while(ticks - ticks0 < n){
80104ec1:	83 c4 10             	add    $0x10,%esp
80104ec4:	a1 c0 54 13 80       	mov    0x801354c0,%eax
80104ec9:	29 d8                	sub    %ebx,%eax
80104ecb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104ece:	73 39                	jae    80104f09 <sys_sleep+0x74>
    if(myproc()->killed){
80104ed0:	e8 35 e5 ff ff       	call   8010340a <myproc>
80104ed5:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104ed9:	75 17                	jne    80104ef2 <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104edb:	83 ec 08             	sub    $0x8,%esp
80104ede:	68 80 4c 13 80       	push   $0x80134c80
80104ee3:	68 c0 54 13 80       	push   $0x801354c0
80104ee8:	e8 c1 e9 ff ff       	call   801038ae <sleep>
80104eed:	83 c4 10             	add    $0x10,%esp
80104ef0:	eb d2                	jmp    80104ec4 <sys_sleep+0x2f>
      release(&tickslock);
80104ef2:	83 ec 0c             	sub    $0xc,%esp
80104ef5:	68 80 4c 13 80       	push   $0x80134c80
80104efa:	e8 81 ef ff ff       	call   80103e80 <release>
      return -1;
80104eff:	83 c4 10             	add    $0x10,%esp
80104f02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f07:	eb 15                	jmp    80104f1e <sys_sleep+0x89>
  }
  release(&tickslock);
80104f09:	83 ec 0c             	sub    $0xc,%esp
80104f0c:	68 80 4c 13 80       	push   $0x80134c80
80104f11:	e8 6a ef ff ff       	call   80103e80 <release>
  return 0;
80104f16:	83 c4 10             	add    $0x10,%esp
80104f19:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f1e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f21:	c9                   	leave  
80104f22:	c3                   	ret    
    return -1;
80104f23:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f28:	eb f4                	jmp    80104f1e <sys_sleep+0x89>

80104f2a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104f2a:	55                   	push   %ebp
80104f2b:	89 e5                	mov    %esp,%ebp
80104f2d:	53                   	push   %ebx
80104f2e:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104f31:	68 80 4c 13 80       	push   $0x80134c80
80104f36:	e8 e0 ee ff ff       	call   80103e1b <acquire>
  xticks = ticks;
80104f3b:	8b 1d c0 54 13 80    	mov    0x801354c0,%ebx
  release(&tickslock);
80104f41:	c7 04 24 80 4c 13 80 	movl   $0x80134c80,(%esp)
80104f48:	e8 33 ef ff ff       	call   80103e80 <release>
  return xticks;
}
80104f4d:	89 d8                	mov    %ebx,%eax
80104f4f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f52:	c9                   	leave  
80104f53:	c3                   	ret    

80104f54 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104f54:	55                   	push   %ebp
80104f55:	89 e5                	mov    %esp,%ebp
80104f57:	83 ec 1c             	sub    $0x1c,%esp
  int* frames;
  int* pids;
  int numframes;

  if(argptr(0, (void*)&frames,sizeof(frames)) < 0)
80104f5a:	6a 04                	push   $0x4
80104f5c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f5f:	50                   	push   %eax
80104f60:	6a 00                	push   $0x0
80104f62:	e8 d3 f1 ff ff       	call   8010413a <argptr>
80104f67:	83 c4 10             	add    $0x10,%esp
80104f6a:	85 c0                	test   %eax,%eax
80104f6c:	78 42                	js     80104fb0 <sys_dump_physmem+0x5c>
    return -1;
  
  if(argptr(1, (void*)&pids, sizeof(pids)) < 0)
80104f6e:	83 ec 04             	sub    $0x4,%esp
80104f71:	6a 04                	push   $0x4
80104f73:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104f76:	50                   	push   %eax
80104f77:	6a 01                	push   $0x1
80104f79:	e8 bc f1 ff ff       	call   8010413a <argptr>
80104f7e:	83 c4 10             	add    $0x10,%esp
80104f81:	85 c0                	test   %eax,%eax
80104f83:	78 32                	js     80104fb7 <sys_dump_physmem+0x63>
    return -1;
  
  if(argint(2, &numframes) < 0)
80104f85:	83 ec 08             	sub    $0x8,%esp
80104f88:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104f8b:	50                   	push   %eax
80104f8c:	6a 02                	push   $0x2
80104f8e:	e8 7f f1 ff ff       	call   80104112 <argint>
80104f93:	83 c4 10             	add    $0x10,%esp
80104f96:	85 c0                	test   %eax,%eax
80104f98:	78 24                	js     80104fbe <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
80104f9a:	83 ec 04             	sub    $0x4,%esp
80104f9d:	ff 75 ec             	pushl  -0x14(%ebp)
80104fa0:	ff 75 f0             	pushl  -0x10(%ebp)
80104fa3:	ff 75 f4             	pushl  -0xc(%ebp)
80104fa6:	e8 b7 eb ff ff       	call   80103b62 <dump_physmem>
80104fab:	83 c4 10             	add    $0x10,%esp
80104fae:	c9                   	leave  
80104faf:	c3                   	ret    
    return -1;
80104fb0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fb5:	eb f7                	jmp    80104fae <sys_dump_physmem+0x5a>
    return -1;
80104fb7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fbc:	eb f0                	jmp    80104fae <sys_dump_physmem+0x5a>
    return -1;
80104fbe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fc3:	eb e9                	jmp    80104fae <sys_dump_physmem+0x5a>

80104fc5 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104fc5:	1e                   	push   %ds
  pushl %es
80104fc6:	06                   	push   %es
  pushl %fs
80104fc7:	0f a0                	push   %fs
  pushl %gs
80104fc9:	0f a8                	push   %gs
  pushal
80104fcb:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104fcc:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104fd0:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104fd2:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104fd4:	54                   	push   %esp
  call trap
80104fd5:	e8 e3 00 00 00       	call   801050bd <trap>
  addl $4, %esp
80104fda:	83 c4 04             	add    $0x4,%esp

80104fdd <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104fdd:	61                   	popa   
  popl %gs
80104fde:	0f a9                	pop    %gs
  popl %fs
80104fe0:	0f a1                	pop    %fs
  popl %es
80104fe2:	07                   	pop    %es
  popl %ds
80104fe3:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104fe4:	83 c4 08             	add    $0x8,%esp
  iret
80104fe7:	cf                   	iret   

80104fe8 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104fe8:	55                   	push   %ebp
80104fe9:	89 e5                	mov    %esp,%ebp
80104feb:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104fee:	b8 00 00 00 00       	mov    $0x0,%eax
80104ff3:	eb 4a                	jmp    8010503f <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104ff5:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
80104ffc:	66 89 0c c5 c0 4c 13 	mov    %cx,-0x7fecb340(,%eax,8)
80105003:	80 
80105004:	66 c7 04 c5 c2 4c 13 	movw   $0x8,-0x7fecb33e(,%eax,8)
8010500b:	80 08 00 
8010500e:	c6 04 c5 c4 4c 13 80 	movb   $0x0,-0x7fecb33c(,%eax,8)
80105015:	00 
80105016:	0f b6 14 c5 c5 4c 13 	movzbl -0x7fecb33b(,%eax,8),%edx
8010501d:	80 
8010501e:	83 e2 f0             	and    $0xfffffff0,%edx
80105021:	83 ca 0e             	or     $0xe,%edx
80105024:	83 e2 8f             	and    $0xffffff8f,%edx
80105027:	83 ca 80             	or     $0xffffff80,%edx
8010502a:	88 14 c5 c5 4c 13 80 	mov    %dl,-0x7fecb33b(,%eax,8)
80105031:	c1 e9 10             	shr    $0x10,%ecx
80105034:	66 89 0c c5 c6 4c 13 	mov    %cx,-0x7fecb33a(,%eax,8)
8010503b:	80 
  for(i = 0; i < 256; i++)
8010503c:	83 c0 01             	add    $0x1,%eax
8010503f:	3d ff 00 00 00       	cmp    $0xff,%eax
80105044:	7e af                	jle    80104ff5 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80105046:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
8010504c:	66 89 15 c0 4e 13 80 	mov    %dx,0x80134ec0
80105053:	66 c7 05 c2 4e 13 80 	movw   $0x8,0x80134ec2
8010505a:	08 00 
8010505c:	c6 05 c4 4e 13 80 00 	movb   $0x0,0x80134ec4
80105063:	0f b6 05 c5 4e 13 80 	movzbl 0x80134ec5,%eax
8010506a:	83 c8 0f             	or     $0xf,%eax
8010506d:	83 e0 ef             	and    $0xffffffef,%eax
80105070:	83 c8 e0             	or     $0xffffffe0,%eax
80105073:	a2 c5 4e 13 80       	mov    %al,0x80134ec5
80105078:	c1 ea 10             	shr    $0x10,%edx
8010507b:	66 89 15 c6 4e 13 80 	mov    %dx,0x80134ec6

  initlock(&tickslock, "time");
80105082:	83 ec 08             	sub    $0x8,%esp
80105085:	68 dd 6e 10 80       	push   $0x80106edd
8010508a:	68 80 4c 13 80       	push   $0x80134c80
8010508f:	e8 4b ec ff ff       	call   80103cdf <initlock>
}
80105094:	83 c4 10             	add    $0x10,%esp
80105097:	c9                   	leave  
80105098:	c3                   	ret    

80105099 <idtinit>:

void
idtinit(void)
{
80105099:	55                   	push   %ebp
8010509a:	89 e5                	mov    %esp,%ebp
8010509c:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
8010509f:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
801050a5:	b8 c0 4c 13 80       	mov    $0x80134cc0,%eax
801050aa:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801050ae:	c1 e8 10             	shr    $0x10,%eax
801050b1:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
801050b5:	8d 45 fa             	lea    -0x6(%ebp),%eax
801050b8:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
801050bb:	c9                   	leave  
801050bc:	c3                   	ret    

801050bd <trap>:

void
trap(struct trapframe *tf)
{
801050bd:	55                   	push   %ebp
801050be:	89 e5                	mov    %esp,%ebp
801050c0:	57                   	push   %edi
801050c1:	56                   	push   %esi
801050c2:	53                   	push   %ebx
801050c3:	83 ec 1c             	sub    $0x1c,%esp
801050c6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
801050c9:	8b 43 30             	mov    0x30(%ebx),%eax
801050cc:	83 f8 40             	cmp    $0x40,%eax
801050cf:	74 13                	je     801050e4 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
801050d1:	83 e8 20             	sub    $0x20,%eax
801050d4:	83 f8 1f             	cmp    $0x1f,%eax
801050d7:	0f 87 3a 01 00 00    	ja     80105217 <trap+0x15a>
801050dd:	ff 24 85 84 6f 10 80 	jmp    *-0x7fef907c(,%eax,4)
    if(myproc()->killed)
801050e4:	e8 21 e3 ff ff       	call   8010340a <myproc>
801050e9:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801050ed:	75 1f                	jne    8010510e <trap+0x51>
    myproc()->tf = tf;
801050ef:	e8 16 e3 ff ff       	call   8010340a <myproc>
801050f4:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
801050f7:	e8 d9 f0 ff ff       	call   801041d5 <syscall>
    if(myproc()->killed)
801050fc:	e8 09 e3 ff ff       	call   8010340a <myproc>
80105101:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105105:	74 7e                	je     80105185 <trap+0xc8>
      exit();
80105107:	e8 aa e6 ff ff       	call   801037b6 <exit>
8010510c:	eb 77                	jmp    80105185 <trap+0xc8>
      exit();
8010510e:	e8 a3 e6 ff ff       	call   801037b6 <exit>
80105113:	eb da                	jmp    801050ef <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80105115:	e8 d5 e2 ff ff       	call   801033ef <cpuid>
8010511a:	85 c0                	test   %eax,%eax
8010511c:	74 6f                	je     8010518d <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
8010511e:	e8 71 d4 ff ff       	call   80102594 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105123:	e8 e2 e2 ff ff       	call   8010340a <myproc>
80105128:	85 c0                	test   %eax,%eax
8010512a:	74 1c                	je     80105148 <trap+0x8b>
8010512c:	e8 d9 e2 ff ff       	call   8010340a <myproc>
80105131:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105135:	74 11                	je     80105148 <trap+0x8b>
80105137:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
8010513b:	83 e0 03             	and    $0x3,%eax
8010513e:	66 83 f8 03          	cmp    $0x3,%ax
80105142:	0f 84 62 01 00 00    	je     801052aa <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80105148:	e8 bd e2 ff ff       	call   8010340a <myproc>
8010514d:	85 c0                	test   %eax,%eax
8010514f:	74 0f                	je     80105160 <trap+0xa3>
80105151:	e8 b4 e2 ff ff       	call   8010340a <myproc>
80105156:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
8010515a:	0f 84 54 01 00 00    	je     801052b4 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105160:	e8 a5 e2 ff ff       	call   8010340a <myproc>
80105165:	85 c0                	test   %eax,%eax
80105167:	74 1c                	je     80105185 <trap+0xc8>
80105169:	e8 9c e2 ff ff       	call   8010340a <myproc>
8010516e:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105172:	74 11                	je     80105185 <trap+0xc8>
80105174:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105178:	83 e0 03             	and    $0x3,%eax
8010517b:	66 83 f8 03          	cmp    $0x3,%ax
8010517f:	0f 84 43 01 00 00    	je     801052c8 <trap+0x20b>
    exit();
}
80105185:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105188:	5b                   	pop    %ebx
80105189:	5e                   	pop    %esi
8010518a:	5f                   	pop    %edi
8010518b:	5d                   	pop    %ebp
8010518c:	c3                   	ret    
      acquire(&tickslock);
8010518d:	83 ec 0c             	sub    $0xc,%esp
80105190:	68 80 4c 13 80       	push   $0x80134c80
80105195:	e8 81 ec ff ff       	call   80103e1b <acquire>
      ticks++;
8010519a:	83 05 c0 54 13 80 01 	addl   $0x1,0x801354c0
      wakeup(&ticks);
801051a1:	c7 04 24 c0 54 13 80 	movl   $0x801354c0,(%esp)
801051a8:	e8 66 e8 ff ff       	call   80103a13 <wakeup>
      release(&tickslock);
801051ad:	c7 04 24 80 4c 13 80 	movl   $0x80134c80,(%esp)
801051b4:	e8 c7 ec ff ff       	call   80103e80 <release>
801051b9:	83 c4 10             	add    $0x10,%esp
801051bc:	e9 5d ff ff ff       	jmp    8010511e <trap+0x61>
    ideintr();
801051c1:	e8 ad cb ff ff       	call   80101d73 <ideintr>
    lapiceoi();
801051c6:	e8 c9 d3 ff ff       	call   80102594 <lapiceoi>
    break;
801051cb:	e9 53 ff ff ff       	jmp    80105123 <trap+0x66>
    kbdintr();
801051d0:	e8 03 d2 ff ff       	call   801023d8 <kbdintr>
    lapiceoi();
801051d5:	e8 ba d3 ff ff       	call   80102594 <lapiceoi>
    break;
801051da:	e9 44 ff ff ff       	jmp    80105123 <trap+0x66>
    uartintr();
801051df:	e8 05 02 00 00       	call   801053e9 <uartintr>
    lapiceoi();
801051e4:	e8 ab d3 ff ff       	call   80102594 <lapiceoi>
    break;
801051e9:	e9 35 ff ff ff       	jmp    80105123 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801051ee:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
801051f1:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801051f5:	e8 f5 e1 ff ff       	call   801033ef <cpuid>
801051fa:	57                   	push   %edi
801051fb:	0f b7 f6             	movzwl %si,%esi
801051fe:	56                   	push   %esi
801051ff:	50                   	push   %eax
80105200:	68 e8 6e 10 80       	push   $0x80106ee8
80105205:	e8 01 b4 ff ff       	call   8010060b <cprintf>
    lapiceoi();
8010520a:	e8 85 d3 ff ff       	call   80102594 <lapiceoi>
    break;
8010520f:	83 c4 10             	add    $0x10,%esp
80105212:	e9 0c ff ff ff       	jmp    80105123 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
80105217:	e8 ee e1 ff ff       	call   8010340a <myproc>
8010521c:	85 c0                	test   %eax,%eax
8010521e:	74 5f                	je     8010527f <trap+0x1c2>
80105220:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80105224:	74 59                	je     8010527f <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80105226:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105229:	8b 43 38             	mov    0x38(%ebx),%eax
8010522c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010522f:	e8 bb e1 ff ff       	call   801033ef <cpuid>
80105234:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105237:	8b 53 34             	mov    0x34(%ebx),%edx
8010523a:	89 55 dc             	mov    %edx,-0x24(%ebp)
8010523d:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
80105240:	e8 c5 e1 ff ff       	call   8010340a <myproc>
80105245:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105248:	89 4d d8             	mov    %ecx,-0x28(%ebp)
8010524b:	e8 ba e1 ff ff       	call   8010340a <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105250:	57                   	push   %edi
80105251:	ff 75 e4             	pushl  -0x1c(%ebp)
80105254:	ff 75 e0             	pushl  -0x20(%ebp)
80105257:	ff 75 dc             	pushl  -0x24(%ebp)
8010525a:	56                   	push   %esi
8010525b:	ff 75 d8             	pushl  -0x28(%ebp)
8010525e:	ff 70 10             	pushl  0x10(%eax)
80105261:	68 40 6f 10 80       	push   $0x80106f40
80105266:	e8 a0 b3 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
8010526b:	83 c4 20             	add    $0x20,%esp
8010526e:	e8 97 e1 ff ff       	call   8010340a <myproc>
80105273:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010527a:	e9 a4 fe ff ff       	jmp    80105123 <trap+0x66>
8010527f:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80105282:	8b 73 38             	mov    0x38(%ebx),%esi
80105285:	e8 65 e1 ff ff       	call   801033ef <cpuid>
8010528a:	83 ec 0c             	sub    $0xc,%esp
8010528d:	57                   	push   %edi
8010528e:	56                   	push   %esi
8010528f:	50                   	push   %eax
80105290:	ff 73 30             	pushl  0x30(%ebx)
80105293:	68 0c 6f 10 80       	push   $0x80106f0c
80105298:	e8 6e b3 ff ff       	call   8010060b <cprintf>
      panic("trap");
8010529d:	83 c4 14             	add    $0x14,%esp
801052a0:	68 e2 6e 10 80       	push   $0x80106ee2
801052a5:	e8 9e b0 ff ff       	call   80100348 <panic>
    exit();
801052aa:	e8 07 e5 ff ff       	call   801037b6 <exit>
801052af:	e9 94 fe ff ff       	jmp    80105148 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
801052b4:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
801052b8:	0f 85 a2 fe ff ff    	jne    80105160 <trap+0xa3>
    yield();
801052be:	e8 b9 e5 ff ff       	call   8010387c <yield>
801052c3:	e9 98 fe ff ff       	jmp    80105160 <trap+0xa3>
    exit();
801052c8:	e8 e9 e4 ff ff       	call   801037b6 <exit>
801052cd:	e9 b3 fe ff ff       	jmp    80105185 <trap+0xc8>

801052d2 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
801052d2:	55                   	push   %ebp
801052d3:	89 e5                	mov    %esp,%ebp
  if(!uart)
801052d5:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
801052dc:	74 15                	je     801052f3 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801052de:	ba fd 03 00 00       	mov    $0x3fd,%edx
801052e3:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
801052e4:	a8 01                	test   $0x1,%al
801052e6:	74 12                	je     801052fa <uartgetc+0x28>
801052e8:	ba f8 03 00 00       	mov    $0x3f8,%edx
801052ed:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
801052ee:	0f b6 c0             	movzbl %al,%eax
}
801052f1:	5d                   	pop    %ebp
801052f2:	c3                   	ret    
    return -1;
801052f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052f8:	eb f7                	jmp    801052f1 <uartgetc+0x1f>
    return -1;
801052fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052ff:	eb f0                	jmp    801052f1 <uartgetc+0x1f>

80105301 <uartputc>:
  if(!uart)
80105301:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
80105308:	74 3b                	je     80105345 <uartputc+0x44>
{
8010530a:	55                   	push   %ebp
8010530b:	89 e5                	mov    %esp,%ebp
8010530d:	53                   	push   %ebx
8010530e:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105311:	bb 00 00 00 00       	mov    $0x0,%ebx
80105316:	eb 10                	jmp    80105328 <uartputc+0x27>
    microdelay(10);
80105318:	83 ec 0c             	sub    $0xc,%esp
8010531b:	6a 0a                	push   $0xa
8010531d:	e8 91 d2 ff ff       	call   801025b3 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105322:	83 c3 01             	add    $0x1,%ebx
80105325:	83 c4 10             	add    $0x10,%esp
80105328:	83 fb 7f             	cmp    $0x7f,%ebx
8010532b:	7f 0a                	jg     80105337 <uartputc+0x36>
8010532d:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105332:	ec                   	in     (%dx),%al
80105333:	a8 20                	test   $0x20,%al
80105335:	74 e1                	je     80105318 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80105337:	8b 45 08             	mov    0x8(%ebp),%eax
8010533a:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010533f:	ee                   	out    %al,(%dx)
}
80105340:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105343:	c9                   	leave  
80105344:	c3                   	ret    
80105345:	f3 c3                	repz ret 

80105347 <uartinit>:
{
80105347:	55                   	push   %ebp
80105348:	89 e5                	mov    %esp,%ebp
8010534a:	56                   	push   %esi
8010534b:	53                   	push   %ebx
8010534c:	b9 00 00 00 00       	mov    $0x0,%ecx
80105351:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105356:	89 c8                	mov    %ecx,%eax
80105358:	ee                   	out    %al,(%dx)
80105359:	be fb 03 00 00       	mov    $0x3fb,%esi
8010535e:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80105363:	89 f2                	mov    %esi,%edx
80105365:	ee                   	out    %al,(%dx)
80105366:	b8 0c 00 00 00       	mov    $0xc,%eax
8010536b:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105370:	ee                   	out    %al,(%dx)
80105371:	bb f9 03 00 00       	mov    $0x3f9,%ebx
80105376:	89 c8                	mov    %ecx,%eax
80105378:	89 da                	mov    %ebx,%edx
8010537a:	ee                   	out    %al,(%dx)
8010537b:	b8 03 00 00 00       	mov    $0x3,%eax
80105380:	89 f2                	mov    %esi,%edx
80105382:	ee                   	out    %al,(%dx)
80105383:	ba fc 03 00 00       	mov    $0x3fc,%edx
80105388:	89 c8                	mov    %ecx,%eax
8010538a:	ee                   	out    %al,(%dx)
8010538b:	b8 01 00 00 00       	mov    $0x1,%eax
80105390:	89 da                	mov    %ebx,%edx
80105392:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105393:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105398:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
80105399:	3c ff                	cmp    $0xff,%al
8010539b:	74 45                	je     801053e2 <uartinit+0x9b>
  uart = 1;
8010539d:	c7 05 bc a5 10 80 01 	movl   $0x1,0x8010a5bc
801053a4:	00 00 00 
801053a7:	ba fa 03 00 00       	mov    $0x3fa,%edx
801053ac:	ec                   	in     (%dx),%al
801053ad:	ba f8 03 00 00       	mov    $0x3f8,%edx
801053b2:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
801053b3:	83 ec 08             	sub    $0x8,%esp
801053b6:	6a 00                	push   $0x0
801053b8:	6a 04                	push   $0x4
801053ba:	e8 bf cb ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
801053bf:	83 c4 10             	add    $0x10,%esp
801053c2:	bb 04 70 10 80       	mov    $0x80107004,%ebx
801053c7:	eb 12                	jmp    801053db <uartinit+0x94>
    uartputc(*p);
801053c9:	83 ec 0c             	sub    $0xc,%esp
801053cc:	0f be c0             	movsbl %al,%eax
801053cf:	50                   	push   %eax
801053d0:	e8 2c ff ff ff       	call   80105301 <uartputc>
  for(p="xv6...\n"; *p; p++)
801053d5:	83 c3 01             	add    $0x1,%ebx
801053d8:	83 c4 10             	add    $0x10,%esp
801053db:	0f b6 03             	movzbl (%ebx),%eax
801053de:	84 c0                	test   %al,%al
801053e0:	75 e7                	jne    801053c9 <uartinit+0x82>
}
801053e2:	8d 65 f8             	lea    -0x8(%ebp),%esp
801053e5:	5b                   	pop    %ebx
801053e6:	5e                   	pop    %esi
801053e7:	5d                   	pop    %ebp
801053e8:	c3                   	ret    

801053e9 <uartintr>:

void
uartintr(void)
{
801053e9:	55                   	push   %ebp
801053ea:	89 e5                	mov    %esp,%ebp
801053ec:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
801053ef:	68 d2 52 10 80       	push   $0x801052d2
801053f4:	e8 45 b3 ff ff       	call   8010073e <consoleintr>
}
801053f9:	83 c4 10             	add    $0x10,%esp
801053fc:	c9                   	leave  
801053fd:	c3                   	ret    

801053fe <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801053fe:	6a 00                	push   $0x0
  pushl $0
80105400:	6a 00                	push   $0x0
  jmp alltraps
80105402:	e9 be fb ff ff       	jmp    80104fc5 <alltraps>

80105407 <vector1>:
.globl vector1
vector1:
  pushl $0
80105407:	6a 00                	push   $0x0
  pushl $1
80105409:	6a 01                	push   $0x1
  jmp alltraps
8010540b:	e9 b5 fb ff ff       	jmp    80104fc5 <alltraps>

80105410 <vector2>:
.globl vector2
vector2:
  pushl $0
80105410:	6a 00                	push   $0x0
  pushl $2
80105412:	6a 02                	push   $0x2
  jmp alltraps
80105414:	e9 ac fb ff ff       	jmp    80104fc5 <alltraps>

80105419 <vector3>:
.globl vector3
vector3:
  pushl $0
80105419:	6a 00                	push   $0x0
  pushl $3
8010541b:	6a 03                	push   $0x3
  jmp alltraps
8010541d:	e9 a3 fb ff ff       	jmp    80104fc5 <alltraps>

80105422 <vector4>:
.globl vector4
vector4:
  pushl $0
80105422:	6a 00                	push   $0x0
  pushl $4
80105424:	6a 04                	push   $0x4
  jmp alltraps
80105426:	e9 9a fb ff ff       	jmp    80104fc5 <alltraps>

8010542b <vector5>:
.globl vector5
vector5:
  pushl $0
8010542b:	6a 00                	push   $0x0
  pushl $5
8010542d:	6a 05                	push   $0x5
  jmp alltraps
8010542f:	e9 91 fb ff ff       	jmp    80104fc5 <alltraps>

80105434 <vector6>:
.globl vector6
vector6:
  pushl $0
80105434:	6a 00                	push   $0x0
  pushl $6
80105436:	6a 06                	push   $0x6
  jmp alltraps
80105438:	e9 88 fb ff ff       	jmp    80104fc5 <alltraps>

8010543d <vector7>:
.globl vector7
vector7:
  pushl $0
8010543d:	6a 00                	push   $0x0
  pushl $7
8010543f:	6a 07                	push   $0x7
  jmp alltraps
80105441:	e9 7f fb ff ff       	jmp    80104fc5 <alltraps>

80105446 <vector8>:
.globl vector8
vector8:
  pushl $8
80105446:	6a 08                	push   $0x8
  jmp alltraps
80105448:	e9 78 fb ff ff       	jmp    80104fc5 <alltraps>

8010544d <vector9>:
.globl vector9
vector9:
  pushl $0
8010544d:	6a 00                	push   $0x0
  pushl $9
8010544f:	6a 09                	push   $0x9
  jmp alltraps
80105451:	e9 6f fb ff ff       	jmp    80104fc5 <alltraps>

80105456 <vector10>:
.globl vector10
vector10:
  pushl $10
80105456:	6a 0a                	push   $0xa
  jmp alltraps
80105458:	e9 68 fb ff ff       	jmp    80104fc5 <alltraps>

8010545d <vector11>:
.globl vector11
vector11:
  pushl $11
8010545d:	6a 0b                	push   $0xb
  jmp alltraps
8010545f:	e9 61 fb ff ff       	jmp    80104fc5 <alltraps>

80105464 <vector12>:
.globl vector12
vector12:
  pushl $12
80105464:	6a 0c                	push   $0xc
  jmp alltraps
80105466:	e9 5a fb ff ff       	jmp    80104fc5 <alltraps>

8010546b <vector13>:
.globl vector13
vector13:
  pushl $13
8010546b:	6a 0d                	push   $0xd
  jmp alltraps
8010546d:	e9 53 fb ff ff       	jmp    80104fc5 <alltraps>

80105472 <vector14>:
.globl vector14
vector14:
  pushl $14
80105472:	6a 0e                	push   $0xe
  jmp alltraps
80105474:	e9 4c fb ff ff       	jmp    80104fc5 <alltraps>

80105479 <vector15>:
.globl vector15
vector15:
  pushl $0
80105479:	6a 00                	push   $0x0
  pushl $15
8010547b:	6a 0f                	push   $0xf
  jmp alltraps
8010547d:	e9 43 fb ff ff       	jmp    80104fc5 <alltraps>

80105482 <vector16>:
.globl vector16
vector16:
  pushl $0
80105482:	6a 00                	push   $0x0
  pushl $16
80105484:	6a 10                	push   $0x10
  jmp alltraps
80105486:	e9 3a fb ff ff       	jmp    80104fc5 <alltraps>

8010548b <vector17>:
.globl vector17
vector17:
  pushl $17
8010548b:	6a 11                	push   $0x11
  jmp alltraps
8010548d:	e9 33 fb ff ff       	jmp    80104fc5 <alltraps>

80105492 <vector18>:
.globl vector18
vector18:
  pushl $0
80105492:	6a 00                	push   $0x0
  pushl $18
80105494:	6a 12                	push   $0x12
  jmp alltraps
80105496:	e9 2a fb ff ff       	jmp    80104fc5 <alltraps>

8010549b <vector19>:
.globl vector19
vector19:
  pushl $0
8010549b:	6a 00                	push   $0x0
  pushl $19
8010549d:	6a 13                	push   $0x13
  jmp alltraps
8010549f:	e9 21 fb ff ff       	jmp    80104fc5 <alltraps>

801054a4 <vector20>:
.globl vector20
vector20:
  pushl $0
801054a4:	6a 00                	push   $0x0
  pushl $20
801054a6:	6a 14                	push   $0x14
  jmp alltraps
801054a8:	e9 18 fb ff ff       	jmp    80104fc5 <alltraps>

801054ad <vector21>:
.globl vector21
vector21:
  pushl $0
801054ad:	6a 00                	push   $0x0
  pushl $21
801054af:	6a 15                	push   $0x15
  jmp alltraps
801054b1:	e9 0f fb ff ff       	jmp    80104fc5 <alltraps>

801054b6 <vector22>:
.globl vector22
vector22:
  pushl $0
801054b6:	6a 00                	push   $0x0
  pushl $22
801054b8:	6a 16                	push   $0x16
  jmp alltraps
801054ba:	e9 06 fb ff ff       	jmp    80104fc5 <alltraps>

801054bf <vector23>:
.globl vector23
vector23:
  pushl $0
801054bf:	6a 00                	push   $0x0
  pushl $23
801054c1:	6a 17                	push   $0x17
  jmp alltraps
801054c3:	e9 fd fa ff ff       	jmp    80104fc5 <alltraps>

801054c8 <vector24>:
.globl vector24
vector24:
  pushl $0
801054c8:	6a 00                	push   $0x0
  pushl $24
801054ca:	6a 18                	push   $0x18
  jmp alltraps
801054cc:	e9 f4 fa ff ff       	jmp    80104fc5 <alltraps>

801054d1 <vector25>:
.globl vector25
vector25:
  pushl $0
801054d1:	6a 00                	push   $0x0
  pushl $25
801054d3:	6a 19                	push   $0x19
  jmp alltraps
801054d5:	e9 eb fa ff ff       	jmp    80104fc5 <alltraps>

801054da <vector26>:
.globl vector26
vector26:
  pushl $0
801054da:	6a 00                	push   $0x0
  pushl $26
801054dc:	6a 1a                	push   $0x1a
  jmp alltraps
801054de:	e9 e2 fa ff ff       	jmp    80104fc5 <alltraps>

801054e3 <vector27>:
.globl vector27
vector27:
  pushl $0
801054e3:	6a 00                	push   $0x0
  pushl $27
801054e5:	6a 1b                	push   $0x1b
  jmp alltraps
801054e7:	e9 d9 fa ff ff       	jmp    80104fc5 <alltraps>

801054ec <vector28>:
.globl vector28
vector28:
  pushl $0
801054ec:	6a 00                	push   $0x0
  pushl $28
801054ee:	6a 1c                	push   $0x1c
  jmp alltraps
801054f0:	e9 d0 fa ff ff       	jmp    80104fc5 <alltraps>

801054f5 <vector29>:
.globl vector29
vector29:
  pushl $0
801054f5:	6a 00                	push   $0x0
  pushl $29
801054f7:	6a 1d                	push   $0x1d
  jmp alltraps
801054f9:	e9 c7 fa ff ff       	jmp    80104fc5 <alltraps>

801054fe <vector30>:
.globl vector30
vector30:
  pushl $0
801054fe:	6a 00                	push   $0x0
  pushl $30
80105500:	6a 1e                	push   $0x1e
  jmp alltraps
80105502:	e9 be fa ff ff       	jmp    80104fc5 <alltraps>

80105507 <vector31>:
.globl vector31
vector31:
  pushl $0
80105507:	6a 00                	push   $0x0
  pushl $31
80105509:	6a 1f                	push   $0x1f
  jmp alltraps
8010550b:	e9 b5 fa ff ff       	jmp    80104fc5 <alltraps>

80105510 <vector32>:
.globl vector32
vector32:
  pushl $0
80105510:	6a 00                	push   $0x0
  pushl $32
80105512:	6a 20                	push   $0x20
  jmp alltraps
80105514:	e9 ac fa ff ff       	jmp    80104fc5 <alltraps>

80105519 <vector33>:
.globl vector33
vector33:
  pushl $0
80105519:	6a 00                	push   $0x0
  pushl $33
8010551b:	6a 21                	push   $0x21
  jmp alltraps
8010551d:	e9 a3 fa ff ff       	jmp    80104fc5 <alltraps>

80105522 <vector34>:
.globl vector34
vector34:
  pushl $0
80105522:	6a 00                	push   $0x0
  pushl $34
80105524:	6a 22                	push   $0x22
  jmp alltraps
80105526:	e9 9a fa ff ff       	jmp    80104fc5 <alltraps>

8010552b <vector35>:
.globl vector35
vector35:
  pushl $0
8010552b:	6a 00                	push   $0x0
  pushl $35
8010552d:	6a 23                	push   $0x23
  jmp alltraps
8010552f:	e9 91 fa ff ff       	jmp    80104fc5 <alltraps>

80105534 <vector36>:
.globl vector36
vector36:
  pushl $0
80105534:	6a 00                	push   $0x0
  pushl $36
80105536:	6a 24                	push   $0x24
  jmp alltraps
80105538:	e9 88 fa ff ff       	jmp    80104fc5 <alltraps>

8010553d <vector37>:
.globl vector37
vector37:
  pushl $0
8010553d:	6a 00                	push   $0x0
  pushl $37
8010553f:	6a 25                	push   $0x25
  jmp alltraps
80105541:	e9 7f fa ff ff       	jmp    80104fc5 <alltraps>

80105546 <vector38>:
.globl vector38
vector38:
  pushl $0
80105546:	6a 00                	push   $0x0
  pushl $38
80105548:	6a 26                	push   $0x26
  jmp alltraps
8010554a:	e9 76 fa ff ff       	jmp    80104fc5 <alltraps>

8010554f <vector39>:
.globl vector39
vector39:
  pushl $0
8010554f:	6a 00                	push   $0x0
  pushl $39
80105551:	6a 27                	push   $0x27
  jmp alltraps
80105553:	e9 6d fa ff ff       	jmp    80104fc5 <alltraps>

80105558 <vector40>:
.globl vector40
vector40:
  pushl $0
80105558:	6a 00                	push   $0x0
  pushl $40
8010555a:	6a 28                	push   $0x28
  jmp alltraps
8010555c:	e9 64 fa ff ff       	jmp    80104fc5 <alltraps>

80105561 <vector41>:
.globl vector41
vector41:
  pushl $0
80105561:	6a 00                	push   $0x0
  pushl $41
80105563:	6a 29                	push   $0x29
  jmp alltraps
80105565:	e9 5b fa ff ff       	jmp    80104fc5 <alltraps>

8010556a <vector42>:
.globl vector42
vector42:
  pushl $0
8010556a:	6a 00                	push   $0x0
  pushl $42
8010556c:	6a 2a                	push   $0x2a
  jmp alltraps
8010556e:	e9 52 fa ff ff       	jmp    80104fc5 <alltraps>

80105573 <vector43>:
.globl vector43
vector43:
  pushl $0
80105573:	6a 00                	push   $0x0
  pushl $43
80105575:	6a 2b                	push   $0x2b
  jmp alltraps
80105577:	e9 49 fa ff ff       	jmp    80104fc5 <alltraps>

8010557c <vector44>:
.globl vector44
vector44:
  pushl $0
8010557c:	6a 00                	push   $0x0
  pushl $44
8010557e:	6a 2c                	push   $0x2c
  jmp alltraps
80105580:	e9 40 fa ff ff       	jmp    80104fc5 <alltraps>

80105585 <vector45>:
.globl vector45
vector45:
  pushl $0
80105585:	6a 00                	push   $0x0
  pushl $45
80105587:	6a 2d                	push   $0x2d
  jmp alltraps
80105589:	e9 37 fa ff ff       	jmp    80104fc5 <alltraps>

8010558e <vector46>:
.globl vector46
vector46:
  pushl $0
8010558e:	6a 00                	push   $0x0
  pushl $46
80105590:	6a 2e                	push   $0x2e
  jmp alltraps
80105592:	e9 2e fa ff ff       	jmp    80104fc5 <alltraps>

80105597 <vector47>:
.globl vector47
vector47:
  pushl $0
80105597:	6a 00                	push   $0x0
  pushl $47
80105599:	6a 2f                	push   $0x2f
  jmp alltraps
8010559b:	e9 25 fa ff ff       	jmp    80104fc5 <alltraps>

801055a0 <vector48>:
.globl vector48
vector48:
  pushl $0
801055a0:	6a 00                	push   $0x0
  pushl $48
801055a2:	6a 30                	push   $0x30
  jmp alltraps
801055a4:	e9 1c fa ff ff       	jmp    80104fc5 <alltraps>

801055a9 <vector49>:
.globl vector49
vector49:
  pushl $0
801055a9:	6a 00                	push   $0x0
  pushl $49
801055ab:	6a 31                	push   $0x31
  jmp alltraps
801055ad:	e9 13 fa ff ff       	jmp    80104fc5 <alltraps>

801055b2 <vector50>:
.globl vector50
vector50:
  pushl $0
801055b2:	6a 00                	push   $0x0
  pushl $50
801055b4:	6a 32                	push   $0x32
  jmp alltraps
801055b6:	e9 0a fa ff ff       	jmp    80104fc5 <alltraps>

801055bb <vector51>:
.globl vector51
vector51:
  pushl $0
801055bb:	6a 00                	push   $0x0
  pushl $51
801055bd:	6a 33                	push   $0x33
  jmp alltraps
801055bf:	e9 01 fa ff ff       	jmp    80104fc5 <alltraps>

801055c4 <vector52>:
.globl vector52
vector52:
  pushl $0
801055c4:	6a 00                	push   $0x0
  pushl $52
801055c6:	6a 34                	push   $0x34
  jmp alltraps
801055c8:	e9 f8 f9 ff ff       	jmp    80104fc5 <alltraps>

801055cd <vector53>:
.globl vector53
vector53:
  pushl $0
801055cd:	6a 00                	push   $0x0
  pushl $53
801055cf:	6a 35                	push   $0x35
  jmp alltraps
801055d1:	e9 ef f9 ff ff       	jmp    80104fc5 <alltraps>

801055d6 <vector54>:
.globl vector54
vector54:
  pushl $0
801055d6:	6a 00                	push   $0x0
  pushl $54
801055d8:	6a 36                	push   $0x36
  jmp alltraps
801055da:	e9 e6 f9 ff ff       	jmp    80104fc5 <alltraps>

801055df <vector55>:
.globl vector55
vector55:
  pushl $0
801055df:	6a 00                	push   $0x0
  pushl $55
801055e1:	6a 37                	push   $0x37
  jmp alltraps
801055e3:	e9 dd f9 ff ff       	jmp    80104fc5 <alltraps>

801055e8 <vector56>:
.globl vector56
vector56:
  pushl $0
801055e8:	6a 00                	push   $0x0
  pushl $56
801055ea:	6a 38                	push   $0x38
  jmp alltraps
801055ec:	e9 d4 f9 ff ff       	jmp    80104fc5 <alltraps>

801055f1 <vector57>:
.globl vector57
vector57:
  pushl $0
801055f1:	6a 00                	push   $0x0
  pushl $57
801055f3:	6a 39                	push   $0x39
  jmp alltraps
801055f5:	e9 cb f9 ff ff       	jmp    80104fc5 <alltraps>

801055fa <vector58>:
.globl vector58
vector58:
  pushl $0
801055fa:	6a 00                	push   $0x0
  pushl $58
801055fc:	6a 3a                	push   $0x3a
  jmp alltraps
801055fe:	e9 c2 f9 ff ff       	jmp    80104fc5 <alltraps>

80105603 <vector59>:
.globl vector59
vector59:
  pushl $0
80105603:	6a 00                	push   $0x0
  pushl $59
80105605:	6a 3b                	push   $0x3b
  jmp alltraps
80105607:	e9 b9 f9 ff ff       	jmp    80104fc5 <alltraps>

8010560c <vector60>:
.globl vector60
vector60:
  pushl $0
8010560c:	6a 00                	push   $0x0
  pushl $60
8010560e:	6a 3c                	push   $0x3c
  jmp alltraps
80105610:	e9 b0 f9 ff ff       	jmp    80104fc5 <alltraps>

80105615 <vector61>:
.globl vector61
vector61:
  pushl $0
80105615:	6a 00                	push   $0x0
  pushl $61
80105617:	6a 3d                	push   $0x3d
  jmp alltraps
80105619:	e9 a7 f9 ff ff       	jmp    80104fc5 <alltraps>

8010561e <vector62>:
.globl vector62
vector62:
  pushl $0
8010561e:	6a 00                	push   $0x0
  pushl $62
80105620:	6a 3e                	push   $0x3e
  jmp alltraps
80105622:	e9 9e f9 ff ff       	jmp    80104fc5 <alltraps>

80105627 <vector63>:
.globl vector63
vector63:
  pushl $0
80105627:	6a 00                	push   $0x0
  pushl $63
80105629:	6a 3f                	push   $0x3f
  jmp alltraps
8010562b:	e9 95 f9 ff ff       	jmp    80104fc5 <alltraps>

80105630 <vector64>:
.globl vector64
vector64:
  pushl $0
80105630:	6a 00                	push   $0x0
  pushl $64
80105632:	6a 40                	push   $0x40
  jmp alltraps
80105634:	e9 8c f9 ff ff       	jmp    80104fc5 <alltraps>

80105639 <vector65>:
.globl vector65
vector65:
  pushl $0
80105639:	6a 00                	push   $0x0
  pushl $65
8010563b:	6a 41                	push   $0x41
  jmp alltraps
8010563d:	e9 83 f9 ff ff       	jmp    80104fc5 <alltraps>

80105642 <vector66>:
.globl vector66
vector66:
  pushl $0
80105642:	6a 00                	push   $0x0
  pushl $66
80105644:	6a 42                	push   $0x42
  jmp alltraps
80105646:	e9 7a f9 ff ff       	jmp    80104fc5 <alltraps>

8010564b <vector67>:
.globl vector67
vector67:
  pushl $0
8010564b:	6a 00                	push   $0x0
  pushl $67
8010564d:	6a 43                	push   $0x43
  jmp alltraps
8010564f:	e9 71 f9 ff ff       	jmp    80104fc5 <alltraps>

80105654 <vector68>:
.globl vector68
vector68:
  pushl $0
80105654:	6a 00                	push   $0x0
  pushl $68
80105656:	6a 44                	push   $0x44
  jmp alltraps
80105658:	e9 68 f9 ff ff       	jmp    80104fc5 <alltraps>

8010565d <vector69>:
.globl vector69
vector69:
  pushl $0
8010565d:	6a 00                	push   $0x0
  pushl $69
8010565f:	6a 45                	push   $0x45
  jmp alltraps
80105661:	e9 5f f9 ff ff       	jmp    80104fc5 <alltraps>

80105666 <vector70>:
.globl vector70
vector70:
  pushl $0
80105666:	6a 00                	push   $0x0
  pushl $70
80105668:	6a 46                	push   $0x46
  jmp alltraps
8010566a:	e9 56 f9 ff ff       	jmp    80104fc5 <alltraps>

8010566f <vector71>:
.globl vector71
vector71:
  pushl $0
8010566f:	6a 00                	push   $0x0
  pushl $71
80105671:	6a 47                	push   $0x47
  jmp alltraps
80105673:	e9 4d f9 ff ff       	jmp    80104fc5 <alltraps>

80105678 <vector72>:
.globl vector72
vector72:
  pushl $0
80105678:	6a 00                	push   $0x0
  pushl $72
8010567a:	6a 48                	push   $0x48
  jmp alltraps
8010567c:	e9 44 f9 ff ff       	jmp    80104fc5 <alltraps>

80105681 <vector73>:
.globl vector73
vector73:
  pushl $0
80105681:	6a 00                	push   $0x0
  pushl $73
80105683:	6a 49                	push   $0x49
  jmp alltraps
80105685:	e9 3b f9 ff ff       	jmp    80104fc5 <alltraps>

8010568a <vector74>:
.globl vector74
vector74:
  pushl $0
8010568a:	6a 00                	push   $0x0
  pushl $74
8010568c:	6a 4a                	push   $0x4a
  jmp alltraps
8010568e:	e9 32 f9 ff ff       	jmp    80104fc5 <alltraps>

80105693 <vector75>:
.globl vector75
vector75:
  pushl $0
80105693:	6a 00                	push   $0x0
  pushl $75
80105695:	6a 4b                	push   $0x4b
  jmp alltraps
80105697:	e9 29 f9 ff ff       	jmp    80104fc5 <alltraps>

8010569c <vector76>:
.globl vector76
vector76:
  pushl $0
8010569c:	6a 00                	push   $0x0
  pushl $76
8010569e:	6a 4c                	push   $0x4c
  jmp alltraps
801056a0:	e9 20 f9 ff ff       	jmp    80104fc5 <alltraps>

801056a5 <vector77>:
.globl vector77
vector77:
  pushl $0
801056a5:	6a 00                	push   $0x0
  pushl $77
801056a7:	6a 4d                	push   $0x4d
  jmp alltraps
801056a9:	e9 17 f9 ff ff       	jmp    80104fc5 <alltraps>

801056ae <vector78>:
.globl vector78
vector78:
  pushl $0
801056ae:	6a 00                	push   $0x0
  pushl $78
801056b0:	6a 4e                	push   $0x4e
  jmp alltraps
801056b2:	e9 0e f9 ff ff       	jmp    80104fc5 <alltraps>

801056b7 <vector79>:
.globl vector79
vector79:
  pushl $0
801056b7:	6a 00                	push   $0x0
  pushl $79
801056b9:	6a 4f                	push   $0x4f
  jmp alltraps
801056bb:	e9 05 f9 ff ff       	jmp    80104fc5 <alltraps>

801056c0 <vector80>:
.globl vector80
vector80:
  pushl $0
801056c0:	6a 00                	push   $0x0
  pushl $80
801056c2:	6a 50                	push   $0x50
  jmp alltraps
801056c4:	e9 fc f8 ff ff       	jmp    80104fc5 <alltraps>

801056c9 <vector81>:
.globl vector81
vector81:
  pushl $0
801056c9:	6a 00                	push   $0x0
  pushl $81
801056cb:	6a 51                	push   $0x51
  jmp alltraps
801056cd:	e9 f3 f8 ff ff       	jmp    80104fc5 <alltraps>

801056d2 <vector82>:
.globl vector82
vector82:
  pushl $0
801056d2:	6a 00                	push   $0x0
  pushl $82
801056d4:	6a 52                	push   $0x52
  jmp alltraps
801056d6:	e9 ea f8 ff ff       	jmp    80104fc5 <alltraps>

801056db <vector83>:
.globl vector83
vector83:
  pushl $0
801056db:	6a 00                	push   $0x0
  pushl $83
801056dd:	6a 53                	push   $0x53
  jmp alltraps
801056df:	e9 e1 f8 ff ff       	jmp    80104fc5 <alltraps>

801056e4 <vector84>:
.globl vector84
vector84:
  pushl $0
801056e4:	6a 00                	push   $0x0
  pushl $84
801056e6:	6a 54                	push   $0x54
  jmp alltraps
801056e8:	e9 d8 f8 ff ff       	jmp    80104fc5 <alltraps>

801056ed <vector85>:
.globl vector85
vector85:
  pushl $0
801056ed:	6a 00                	push   $0x0
  pushl $85
801056ef:	6a 55                	push   $0x55
  jmp alltraps
801056f1:	e9 cf f8 ff ff       	jmp    80104fc5 <alltraps>

801056f6 <vector86>:
.globl vector86
vector86:
  pushl $0
801056f6:	6a 00                	push   $0x0
  pushl $86
801056f8:	6a 56                	push   $0x56
  jmp alltraps
801056fa:	e9 c6 f8 ff ff       	jmp    80104fc5 <alltraps>

801056ff <vector87>:
.globl vector87
vector87:
  pushl $0
801056ff:	6a 00                	push   $0x0
  pushl $87
80105701:	6a 57                	push   $0x57
  jmp alltraps
80105703:	e9 bd f8 ff ff       	jmp    80104fc5 <alltraps>

80105708 <vector88>:
.globl vector88
vector88:
  pushl $0
80105708:	6a 00                	push   $0x0
  pushl $88
8010570a:	6a 58                	push   $0x58
  jmp alltraps
8010570c:	e9 b4 f8 ff ff       	jmp    80104fc5 <alltraps>

80105711 <vector89>:
.globl vector89
vector89:
  pushl $0
80105711:	6a 00                	push   $0x0
  pushl $89
80105713:	6a 59                	push   $0x59
  jmp alltraps
80105715:	e9 ab f8 ff ff       	jmp    80104fc5 <alltraps>

8010571a <vector90>:
.globl vector90
vector90:
  pushl $0
8010571a:	6a 00                	push   $0x0
  pushl $90
8010571c:	6a 5a                	push   $0x5a
  jmp alltraps
8010571e:	e9 a2 f8 ff ff       	jmp    80104fc5 <alltraps>

80105723 <vector91>:
.globl vector91
vector91:
  pushl $0
80105723:	6a 00                	push   $0x0
  pushl $91
80105725:	6a 5b                	push   $0x5b
  jmp alltraps
80105727:	e9 99 f8 ff ff       	jmp    80104fc5 <alltraps>

8010572c <vector92>:
.globl vector92
vector92:
  pushl $0
8010572c:	6a 00                	push   $0x0
  pushl $92
8010572e:	6a 5c                	push   $0x5c
  jmp alltraps
80105730:	e9 90 f8 ff ff       	jmp    80104fc5 <alltraps>

80105735 <vector93>:
.globl vector93
vector93:
  pushl $0
80105735:	6a 00                	push   $0x0
  pushl $93
80105737:	6a 5d                	push   $0x5d
  jmp alltraps
80105739:	e9 87 f8 ff ff       	jmp    80104fc5 <alltraps>

8010573e <vector94>:
.globl vector94
vector94:
  pushl $0
8010573e:	6a 00                	push   $0x0
  pushl $94
80105740:	6a 5e                	push   $0x5e
  jmp alltraps
80105742:	e9 7e f8 ff ff       	jmp    80104fc5 <alltraps>

80105747 <vector95>:
.globl vector95
vector95:
  pushl $0
80105747:	6a 00                	push   $0x0
  pushl $95
80105749:	6a 5f                	push   $0x5f
  jmp alltraps
8010574b:	e9 75 f8 ff ff       	jmp    80104fc5 <alltraps>

80105750 <vector96>:
.globl vector96
vector96:
  pushl $0
80105750:	6a 00                	push   $0x0
  pushl $96
80105752:	6a 60                	push   $0x60
  jmp alltraps
80105754:	e9 6c f8 ff ff       	jmp    80104fc5 <alltraps>

80105759 <vector97>:
.globl vector97
vector97:
  pushl $0
80105759:	6a 00                	push   $0x0
  pushl $97
8010575b:	6a 61                	push   $0x61
  jmp alltraps
8010575d:	e9 63 f8 ff ff       	jmp    80104fc5 <alltraps>

80105762 <vector98>:
.globl vector98
vector98:
  pushl $0
80105762:	6a 00                	push   $0x0
  pushl $98
80105764:	6a 62                	push   $0x62
  jmp alltraps
80105766:	e9 5a f8 ff ff       	jmp    80104fc5 <alltraps>

8010576b <vector99>:
.globl vector99
vector99:
  pushl $0
8010576b:	6a 00                	push   $0x0
  pushl $99
8010576d:	6a 63                	push   $0x63
  jmp alltraps
8010576f:	e9 51 f8 ff ff       	jmp    80104fc5 <alltraps>

80105774 <vector100>:
.globl vector100
vector100:
  pushl $0
80105774:	6a 00                	push   $0x0
  pushl $100
80105776:	6a 64                	push   $0x64
  jmp alltraps
80105778:	e9 48 f8 ff ff       	jmp    80104fc5 <alltraps>

8010577d <vector101>:
.globl vector101
vector101:
  pushl $0
8010577d:	6a 00                	push   $0x0
  pushl $101
8010577f:	6a 65                	push   $0x65
  jmp alltraps
80105781:	e9 3f f8 ff ff       	jmp    80104fc5 <alltraps>

80105786 <vector102>:
.globl vector102
vector102:
  pushl $0
80105786:	6a 00                	push   $0x0
  pushl $102
80105788:	6a 66                	push   $0x66
  jmp alltraps
8010578a:	e9 36 f8 ff ff       	jmp    80104fc5 <alltraps>

8010578f <vector103>:
.globl vector103
vector103:
  pushl $0
8010578f:	6a 00                	push   $0x0
  pushl $103
80105791:	6a 67                	push   $0x67
  jmp alltraps
80105793:	e9 2d f8 ff ff       	jmp    80104fc5 <alltraps>

80105798 <vector104>:
.globl vector104
vector104:
  pushl $0
80105798:	6a 00                	push   $0x0
  pushl $104
8010579a:	6a 68                	push   $0x68
  jmp alltraps
8010579c:	e9 24 f8 ff ff       	jmp    80104fc5 <alltraps>

801057a1 <vector105>:
.globl vector105
vector105:
  pushl $0
801057a1:	6a 00                	push   $0x0
  pushl $105
801057a3:	6a 69                	push   $0x69
  jmp alltraps
801057a5:	e9 1b f8 ff ff       	jmp    80104fc5 <alltraps>

801057aa <vector106>:
.globl vector106
vector106:
  pushl $0
801057aa:	6a 00                	push   $0x0
  pushl $106
801057ac:	6a 6a                	push   $0x6a
  jmp alltraps
801057ae:	e9 12 f8 ff ff       	jmp    80104fc5 <alltraps>

801057b3 <vector107>:
.globl vector107
vector107:
  pushl $0
801057b3:	6a 00                	push   $0x0
  pushl $107
801057b5:	6a 6b                	push   $0x6b
  jmp alltraps
801057b7:	e9 09 f8 ff ff       	jmp    80104fc5 <alltraps>

801057bc <vector108>:
.globl vector108
vector108:
  pushl $0
801057bc:	6a 00                	push   $0x0
  pushl $108
801057be:	6a 6c                	push   $0x6c
  jmp alltraps
801057c0:	e9 00 f8 ff ff       	jmp    80104fc5 <alltraps>

801057c5 <vector109>:
.globl vector109
vector109:
  pushl $0
801057c5:	6a 00                	push   $0x0
  pushl $109
801057c7:	6a 6d                	push   $0x6d
  jmp alltraps
801057c9:	e9 f7 f7 ff ff       	jmp    80104fc5 <alltraps>

801057ce <vector110>:
.globl vector110
vector110:
  pushl $0
801057ce:	6a 00                	push   $0x0
  pushl $110
801057d0:	6a 6e                	push   $0x6e
  jmp alltraps
801057d2:	e9 ee f7 ff ff       	jmp    80104fc5 <alltraps>

801057d7 <vector111>:
.globl vector111
vector111:
  pushl $0
801057d7:	6a 00                	push   $0x0
  pushl $111
801057d9:	6a 6f                	push   $0x6f
  jmp alltraps
801057db:	e9 e5 f7 ff ff       	jmp    80104fc5 <alltraps>

801057e0 <vector112>:
.globl vector112
vector112:
  pushl $0
801057e0:	6a 00                	push   $0x0
  pushl $112
801057e2:	6a 70                	push   $0x70
  jmp alltraps
801057e4:	e9 dc f7 ff ff       	jmp    80104fc5 <alltraps>

801057e9 <vector113>:
.globl vector113
vector113:
  pushl $0
801057e9:	6a 00                	push   $0x0
  pushl $113
801057eb:	6a 71                	push   $0x71
  jmp alltraps
801057ed:	e9 d3 f7 ff ff       	jmp    80104fc5 <alltraps>

801057f2 <vector114>:
.globl vector114
vector114:
  pushl $0
801057f2:	6a 00                	push   $0x0
  pushl $114
801057f4:	6a 72                	push   $0x72
  jmp alltraps
801057f6:	e9 ca f7 ff ff       	jmp    80104fc5 <alltraps>

801057fb <vector115>:
.globl vector115
vector115:
  pushl $0
801057fb:	6a 00                	push   $0x0
  pushl $115
801057fd:	6a 73                	push   $0x73
  jmp alltraps
801057ff:	e9 c1 f7 ff ff       	jmp    80104fc5 <alltraps>

80105804 <vector116>:
.globl vector116
vector116:
  pushl $0
80105804:	6a 00                	push   $0x0
  pushl $116
80105806:	6a 74                	push   $0x74
  jmp alltraps
80105808:	e9 b8 f7 ff ff       	jmp    80104fc5 <alltraps>

8010580d <vector117>:
.globl vector117
vector117:
  pushl $0
8010580d:	6a 00                	push   $0x0
  pushl $117
8010580f:	6a 75                	push   $0x75
  jmp alltraps
80105811:	e9 af f7 ff ff       	jmp    80104fc5 <alltraps>

80105816 <vector118>:
.globl vector118
vector118:
  pushl $0
80105816:	6a 00                	push   $0x0
  pushl $118
80105818:	6a 76                	push   $0x76
  jmp alltraps
8010581a:	e9 a6 f7 ff ff       	jmp    80104fc5 <alltraps>

8010581f <vector119>:
.globl vector119
vector119:
  pushl $0
8010581f:	6a 00                	push   $0x0
  pushl $119
80105821:	6a 77                	push   $0x77
  jmp alltraps
80105823:	e9 9d f7 ff ff       	jmp    80104fc5 <alltraps>

80105828 <vector120>:
.globl vector120
vector120:
  pushl $0
80105828:	6a 00                	push   $0x0
  pushl $120
8010582a:	6a 78                	push   $0x78
  jmp alltraps
8010582c:	e9 94 f7 ff ff       	jmp    80104fc5 <alltraps>

80105831 <vector121>:
.globl vector121
vector121:
  pushl $0
80105831:	6a 00                	push   $0x0
  pushl $121
80105833:	6a 79                	push   $0x79
  jmp alltraps
80105835:	e9 8b f7 ff ff       	jmp    80104fc5 <alltraps>

8010583a <vector122>:
.globl vector122
vector122:
  pushl $0
8010583a:	6a 00                	push   $0x0
  pushl $122
8010583c:	6a 7a                	push   $0x7a
  jmp alltraps
8010583e:	e9 82 f7 ff ff       	jmp    80104fc5 <alltraps>

80105843 <vector123>:
.globl vector123
vector123:
  pushl $0
80105843:	6a 00                	push   $0x0
  pushl $123
80105845:	6a 7b                	push   $0x7b
  jmp alltraps
80105847:	e9 79 f7 ff ff       	jmp    80104fc5 <alltraps>

8010584c <vector124>:
.globl vector124
vector124:
  pushl $0
8010584c:	6a 00                	push   $0x0
  pushl $124
8010584e:	6a 7c                	push   $0x7c
  jmp alltraps
80105850:	e9 70 f7 ff ff       	jmp    80104fc5 <alltraps>

80105855 <vector125>:
.globl vector125
vector125:
  pushl $0
80105855:	6a 00                	push   $0x0
  pushl $125
80105857:	6a 7d                	push   $0x7d
  jmp alltraps
80105859:	e9 67 f7 ff ff       	jmp    80104fc5 <alltraps>

8010585e <vector126>:
.globl vector126
vector126:
  pushl $0
8010585e:	6a 00                	push   $0x0
  pushl $126
80105860:	6a 7e                	push   $0x7e
  jmp alltraps
80105862:	e9 5e f7 ff ff       	jmp    80104fc5 <alltraps>

80105867 <vector127>:
.globl vector127
vector127:
  pushl $0
80105867:	6a 00                	push   $0x0
  pushl $127
80105869:	6a 7f                	push   $0x7f
  jmp alltraps
8010586b:	e9 55 f7 ff ff       	jmp    80104fc5 <alltraps>

80105870 <vector128>:
.globl vector128
vector128:
  pushl $0
80105870:	6a 00                	push   $0x0
  pushl $128
80105872:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80105877:	e9 49 f7 ff ff       	jmp    80104fc5 <alltraps>

8010587c <vector129>:
.globl vector129
vector129:
  pushl $0
8010587c:	6a 00                	push   $0x0
  pushl $129
8010587e:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80105883:	e9 3d f7 ff ff       	jmp    80104fc5 <alltraps>

80105888 <vector130>:
.globl vector130
vector130:
  pushl $0
80105888:	6a 00                	push   $0x0
  pushl $130
8010588a:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010588f:	e9 31 f7 ff ff       	jmp    80104fc5 <alltraps>

80105894 <vector131>:
.globl vector131
vector131:
  pushl $0
80105894:	6a 00                	push   $0x0
  pushl $131
80105896:	68 83 00 00 00       	push   $0x83
  jmp alltraps
8010589b:	e9 25 f7 ff ff       	jmp    80104fc5 <alltraps>

801058a0 <vector132>:
.globl vector132
vector132:
  pushl $0
801058a0:	6a 00                	push   $0x0
  pushl $132
801058a2:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801058a7:	e9 19 f7 ff ff       	jmp    80104fc5 <alltraps>

801058ac <vector133>:
.globl vector133
vector133:
  pushl $0
801058ac:	6a 00                	push   $0x0
  pushl $133
801058ae:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801058b3:	e9 0d f7 ff ff       	jmp    80104fc5 <alltraps>

801058b8 <vector134>:
.globl vector134
vector134:
  pushl $0
801058b8:	6a 00                	push   $0x0
  pushl $134
801058ba:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801058bf:	e9 01 f7 ff ff       	jmp    80104fc5 <alltraps>

801058c4 <vector135>:
.globl vector135
vector135:
  pushl $0
801058c4:	6a 00                	push   $0x0
  pushl $135
801058c6:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801058cb:	e9 f5 f6 ff ff       	jmp    80104fc5 <alltraps>

801058d0 <vector136>:
.globl vector136
vector136:
  pushl $0
801058d0:	6a 00                	push   $0x0
  pushl $136
801058d2:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801058d7:	e9 e9 f6 ff ff       	jmp    80104fc5 <alltraps>

801058dc <vector137>:
.globl vector137
vector137:
  pushl $0
801058dc:	6a 00                	push   $0x0
  pushl $137
801058de:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801058e3:	e9 dd f6 ff ff       	jmp    80104fc5 <alltraps>

801058e8 <vector138>:
.globl vector138
vector138:
  pushl $0
801058e8:	6a 00                	push   $0x0
  pushl $138
801058ea:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801058ef:	e9 d1 f6 ff ff       	jmp    80104fc5 <alltraps>

801058f4 <vector139>:
.globl vector139
vector139:
  pushl $0
801058f4:	6a 00                	push   $0x0
  pushl $139
801058f6:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801058fb:	e9 c5 f6 ff ff       	jmp    80104fc5 <alltraps>

80105900 <vector140>:
.globl vector140
vector140:
  pushl $0
80105900:	6a 00                	push   $0x0
  pushl $140
80105902:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105907:	e9 b9 f6 ff ff       	jmp    80104fc5 <alltraps>

8010590c <vector141>:
.globl vector141
vector141:
  pushl $0
8010590c:	6a 00                	push   $0x0
  pushl $141
8010590e:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105913:	e9 ad f6 ff ff       	jmp    80104fc5 <alltraps>

80105918 <vector142>:
.globl vector142
vector142:
  pushl $0
80105918:	6a 00                	push   $0x0
  pushl $142
8010591a:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
8010591f:	e9 a1 f6 ff ff       	jmp    80104fc5 <alltraps>

80105924 <vector143>:
.globl vector143
vector143:
  pushl $0
80105924:	6a 00                	push   $0x0
  pushl $143
80105926:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
8010592b:	e9 95 f6 ff ff       	jmp    80104fc5 <alltraps>

80105930 <vector144>:
.globl vector144
vector144:
  pushl $0
80105930:	6a 00                	push   $0x0
  pushl $144
80105932:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105937:	e9 89 f6 ff ff       	jmp    80104fc5 <alltraps>

8010593c <vector145>:
.globl vector145
vector145:
  pushl $0
8010593c:	6a 00                	push   $0x0
  pushl $145
8010593e:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105943:	e9 7d f6 ff ff       	jmp    80104fc5 <alltraps>

80105948 <vector146>:
.globl vector146
vector146:
  pushl $0
80105948:	6a 00                	push   $0x0
  pushl $146
8010594a:	68 92 00 00 00       	push   $0x92
  jmp alltraps
8010594f:	e9 71 f6 ff ff       	jmp    80104fc5 <alltraps>

80105954 <vector147>:
.globl vector147
vector147:
  pushl $0
80105954:	6a 00                	push   $0x0
  pushl $147
80105956:	68 93 00 00 00       	push   $0x93
  jmp alltraps
8010595b:	e9 65 f6 ff ff       	jmp    80104fc5 <alltraps>

80105960 <vector148>:
.globl vector148
vector148:
  pushl $0
80105960:	6a 00                	push   $0x0
  pushl $148
80105962:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105967:	e9 59 f6 ff ff       	jmp    80104fc5 <alltraps>

8010596c <vector149>:
.globl vector149
vector149:
  pushl $0
8010596c:	6a 00                	push   $0x0
  pushl $149
8010596e:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80105973:	e9 4d f6 ff ff       	jmp    80104fc5 <alltraps>

80105978 <vector150>:
.globl vector150
vector150:
  pushl $0
80105978:	6a 00                	push   $0x0
  pushl $150
8010597a:	68 96 00 00 00       	push   $0x96
  jmp alltraps
8010597f:	e9 41 f6 ff ff       	jmp    80104fc5 <alltraps>

80105984 <vector151>:
.globl vector151
vector151:
  pushl $0
80105984:	6a 00                	push   $0x0
  pushl $151
80105986:	68 97 00 00 00       	push   $0x97
  jmp alltraps
8010598b:	e9 35 f6 ff ff       	jmp    80104fc5 <alltraps>

80105990 <vector152>:
.globl vector152
vector152:
  pushl $0
80105990:	6a 00                	push   $0x0
  pushl $152
80105992:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105997:	e9 29 f6 ff ff       	jmp    80104fc5 <alltraps>

8010599c <vector153>:
.globl vector153
vector153:
  pushl $0
8010599c:	6a 00                	push   $0x0
  pushl $153
8010599e:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801059a3:	e9 1d f6 ff ff       	jmp    80104fc5 <alltraps>

801059a8 <vector154>:
.globl vector154
vector154:
  pushl $0
801059a8:	6a 00                	push   $0x0
  pushl $154
801059aa:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801059af:	e9 11 f6 ff ff       	jmp    80104fc5 <alltraps>

801059b4 <vector155>:
.globl vector155
vector155:
  pushl $0
801059b4:	6a 00                	push   $0x0
  pushl $155
801059b6:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801059bb:	e9 05 f6 ff ff       	jmp    80104fc5 <alltraps>

801059c0 <vector156>:
.globl vector156
vector156:
  pushl $0
801059c0:	6a 00                	push   $0x0
  pushl $156
801059c2:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801059c7:	e9 f9 f5 ff ff       	jmp    80104fc5 <alltraps>

801059cc <vector157>:
.globl vector157
vector157:
  pushl $0
801059cc:	6a 00                	push   $0x0
  pushl $157
801059ce:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801059d3:	e9 ed f5 ff ff       	jmp    80104fc5 <alltraps>

801059d8 <vector158>:
.globl vector158
vector158:
  pushl $0
801059d8:	6a 00                	push   $0x0
  pushl $158
801059da:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801059df:	e9 e1 f5 ff ff       	jmp    80104fc5 <alltraps>

801059e4 <vector159>:
.globl vector159
vector159:
  pushl $0
801059e4:	6a 00                	push   $0x0
  pushl $159
801059e6:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801059eb:	e9 d5 f5 ff ff       	jmp    80104fc5 <alltraps>

801059f0 <vector160>:
.globl vector160
vector160:
  pushl $0
801059f0:	6a 00                	push   $0x0
  pushl $160
801059f2:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801059f7:	e9 c9 f5 ff ff       	jmp    80104fc5 <alltraps>

801059fc <vector161>:
.globl vector161
vector161:
  pushl $0
801059fc:	6a 00                	push   $0x0
  pushl $161
801059fe:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105a03:	e9 bd f5 ff ff       	jmp    80104fc5 <alltraps>

80105a08 <vector162>:
.globl vector162
vector162:
  pushl $0
80105a08:	6a 00                	push   $0x0
  pushl $162
80105a0a:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105a0f:	e9 b1 f5 ff ff       	jmp    80104fc5 <alltraps>

80105a14 <vector163>:
.globl vector163
vector163:
  pushl $0
80105a14:	6a 00                	push   $0x0
  pushl $163
80105a16:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105a1b:	e9 a5 f5 ff ff       	jmp    80104fc5 <alltraps>

80105a20 <vector164>:
.globl vector164
vector164:
  pushl $0
80105a20:	6a 00                	push   $0x0
  pushl $164
80105a22:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105a27:	e9 99 f5 ff ff       	jmp    80104fc5 <alltraps>

80105a2c <vector165>:
.globl vector165
vector165:
  pushl $0
80105a2c:	6a 00                	push   $0x0
  pushl $165
80105a2e:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105a33:	e9 8d f5 ff ff       	jmp    80104fc5 <alltraps>

80105a38 <vector166>:
.globl vector166
vector166:
  pushl $0
80105a38:	6a 00                	push   $0x0
  pushl $166
80105a3a:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105a3f:	e9 81 f5 ff ff       	jmp    80104fc5 <alltraps>

80105a44 <vector167>:
.globl vector167
vector167:
  pushl $0
80105a44:	6a 00                	push   $0x0
  pushl $167
80105a46:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105a4b:	e9 75 f5 ff ff       	jmp    80104fc5 <alltraps>

80105a50 <vector168>:
.globl vector168
vector168:
  pushl $0
80105a50:	6a 00                	push   $0x0
  pushl $168
80105a52:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105a57:	e9 69 f5 ff ff       	jmp    80104fc5 <alltraps>

80105a5c <vector169>:
.globl vector169
vector169:
  pushl $0
80105a5c:	6a 00                	push   $0x0
  pushl $169
80105a5e:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105a63:	e9 5d f5 ff ff       	jmp    80104fc5 <alltraps>

80105a68 <vector170>:
.globl vector170
vector170:
  pushl $0
80105a68:	6a 00                	push   $0x0
  pushl $170
80105a6a:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105a6f:	e9 51 f5 ff ff       	jmp    80104fc5 <alltraps>

80105a74 <vector171>:
.globl vector171
vector171:
  pushl $0
80105a74:	6a 00                	push   $0x0
  pushl $171
80105a76:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105a7b:	e9 45 f5 ff ff       	jmp    80104fc5 <alltraps>

80105a80 <vector172>:
.globl vector172
vector172:
  pushl $0
80105a80:	6a 00                	push   $0x0
  pushl $172
80105a82:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105a87:	e9 39 f5 ff ff       	jmp    80104fc5 <alltraps>

80105a8c <vector173>:
.globl vector173
vector173:
  pushl $0
80105a8c:	6a 00                	push   $0x0
  pushl $173
80105a8e:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105a93:	e9 2d f5 ff ff       	jmp    80104fc5 <alltraps>

80105a98 <vector174>:
.globl vector174
vector174:
  pushl $0
80105a98:	6a 00                	push   $0x0
  pushl $174
80105a9a:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105a9f:	e9 21 f5 ff ff       	jmp    80104fc5 <alltraps>

80105aa4 <vector175>:
.globl vector175
vector175:
  pushl $0
80105aa4:	6a 00                	push   $0x0
  pushl $175
80105aa6:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105aab:	e9 15 f5 ff ff       	jmp    80104fc5 <alltraps>

80105ab0 <vector176>:
.globl vector176
vector176:
  pushl $0
80105ab0:	6a 00                	push   $0x0
  pushl $176
80105ab2:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105ab7:	e9 09 f5 ff ff       	jmp    80104fc5 <alltraps>

80105abc <vector177>:
.globl vector177
vector177:
  pushl $0
80105abc:	6a 00                	push   $0x0
  pushl $177
80105abe:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105ac3:	e9 fd f4 ff ff       	jmp    80104fc5 <alltraps>

80105ac8 <vector178>:
.globl vector178
vector178:
  pushl $0
80105ac8:	6a 00                	push   $0x0
  pushl $178
80105aca:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105acf:	e9 f1 f4 ff ff       	jmp    80104fc5 <alltraps>

80105ad4 <vector179>:
.globl vector179
vector179:
  pushl $0
80105ad4:	6a 00                	push   $0x0
  pushl $179
80105ad6:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105adb:	e9 e5 f4 ff ff       	jmp    80104fc5 <alltraps>

80105ae0 <vector180>:
.globl vector180
vector180:
  pushl $0
80105ae0:	6a 00                	push   $0x0
  pushl $180
80105ae2:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105ae7:	e9 d9 f4 ff ff       	jmp    80104fc5 <alltraps>

80105aec <vector181>:
.globl vector181
vector181:
  pushl $0
80105aec:	6a 00                	push   $0x0
  pushl $181
80105aee:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105af3:	e9 cd f4 ff ff       	jmp    80104fc5 <alltraps>

80105af8 <vector182>:
.globl vector182
vector182:
  pushl $0
80105af8:	6a 00                	push   $0x0
  pushl $182
80105afa:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105aff:	e9 c1 f4 ff ff       	jmp    80104fc5 <alltraps>

80105b04 <vector183>:
.globl vector183
vector183:
  pushl $0
80105b04:	6a 00                	push   $0x0
  pushl $183
80105b06:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105b0b:	e9 b5 f4 ff ff       	jmp    80104fc5 <alltraps>

80105b10 <vector184>:
.globl vector184
vector184:
  pushl $0
80105b10:	6a 00                	push   $0x0
  pushl $184
80105b12:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105b17:	e9 a9 f4 ff ff       	jmp    80104fc5 <alltraps>

80105b1c <vector185>:
.globl vector185
vector185:
  pushl $0
80105b1c:	6a 00                	push   $0x0
  pushl $185
80105b1e:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105b23:	e9 9d f4 ff ff       	jmp    80104fc5 <alltraps>

80105b28 <vector186>:
.globl vector186
vector186:
  pushl $0
80105b28:	6a 00                	push   $0x0
  pushl $186
80105b2a:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105b2f:	e9 91 f4 ff ff       	jmp    80104fc5 <alltraps>

80105b34 <vector187>:
.globl vector187
vector187:
  pushl $0
80105b34:	6a 00                	push   $0x0
  pushl $187
80105b36:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105b3b:	e9 85 f4 ff ff       	jmp    80104fc5 <alltraps>

80105b40 <vector188>:
.globl vector188
vector188:
  pushl $0
80105b40:	6a 00                	push   $0x0
  pushl $188
80105b42:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105b47:	e9 79 f4 ff ff       	jmp    80104fc5 <alltraps>

80105b4c <vector189>:
.globl vector189
vector189:
  pushl $0
80105b4c:	6a 00                	push   $0x0
  pushl $189
80105b4e:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105b53:	e9 6d f4 ff ff       	jmp    80104fc5 <alltraps>

80105b58 <vector190>:
.globl vector190
vector190:
  pushl $0
80105b58:	6a 00                	push   $0x0
  pushl $190
80105b5a:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105b5f:	e9 61 f4 ff ff       	jmp    80104fc5 <alltraps>

80105b64 <vector191>:
.globl vector191
vector191:
  pushl $0
80105b64:	6a 00                	push   $0x0
  pushl $191
80105b66:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105b6b:	e9 55 f4 ff ff       	jmp    80104fc5 <alltraps>

80105b70 <vector192>:
.globl vector192
vector192:
  pushl $0
80105b70:	6a 00                	push   $0x0
  pushl $192
80105b72:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105b77:	e9 49 f4 ff ff       	jmp    80104fc5 <alltraps>

80105b7c <vector193>:
.globl vector193
vector193:
  pushl $0
80105b7c:	6a 00                	push   $0x0
  pushl $193
80105b7e:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105b83:	e9 3d f4 ff ff       	jmp    80104fc5 <alltraps>

80105b88 <vector194>:
.globl vector194
vector194:
  pushl $0
80105b88:	6a 00                	push   $0x0
  pushl $194
80105b8a:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105b8f:	e9 31 f4 ff ff       	jmp    80104fc5 <alltraps>

80105b94 <vector195>:
.globl vector195
vector195:
  pushl $0
80105b94:	6a 00                	push   $0x0
  pushl $195
80105b96:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105b9b:	e9 25 f4 ff ff       	jmp    80104fc5 <alltraps>

80105ba0 <vector196>:
.globl vector196
vector196:
  pushl $0
80105ba0:	6a 00                	push   $0x0
  pushl $196
80105ba2:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105ba7:	e9 19 f4 ff ff       	jmp    80104fc5 <alltraps>

80105bac <vector197>:
.globl vector197
vector197:
  pushl $0
80105bac:	6a 00                	push   $0x0
  pushl $197
80105bae:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105bb3:	e9 0d f4 ff ff       	jmp    80104fc5 <alltraps>

80105bb8 <vector198>:
.globl vector198
vector198:
  pushl $0
80105bb8:	6a 00                	push   $0x0
  pushl $198
80105bba:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105bbf:	e9 01 f4 ff ff       	jmp    80104fc5 <alltraps>

80105bc4 <vector199>:
.globl vector199
vector199:
  pushl $0
80105bc4:	6a 00                	push   $0x0
  pushl $199
80105bc6:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105bcb:	e9 f5 f3 ff ff       	jmp    80104fc5 <alltraps>

80105bd0 <vector200>:
.globl vector200
vector200:
  pushl $0
80105bd0:	6a 00                	push   $0x0
  pushl $200
80105bd2:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105bd7:	e9 e9 f3 ff ff       	jmp    80104fc5 <alltraps>

80105bdc <vector201>:
.globl vector201
vector201:
  pushl $0
80105bdc:	6a 00                	push   $0x0
  pushl $201
80105bde:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105be3:	e9 dd f3 ff ff       	jmp    80104fc5 <alltraps>

80105be8 <vector202>:
.globl vector202
vector202:
  pushl $0
80105be8:	6a 00                	push   $0x0
  pushl $202
80105bea:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105bef:	e9 d1 f3 ff ff       	jmp    80104fc5 <alltraps>

80105bf4 <vector203>:
.globl vector203
vector203:
  pushl $0
80105bf4:	6a 00                	push   $0x0
  pushl $203
80105bf6:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105bfb:	e9 c5 f3 ff ff       	jmp    80104fc5 <alltraps>

80105c00 <vector204>:
.globl vector204
vector204:
  pushl $0
80105c00:	6a 00                	push   $0x0
  pushl $204
80105c02:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105c07:	e9 b9 f3 ff ff       	jmp    80104fc5 <alltraps>

80105c0c <vector205>:
.globl vector205
vector205:
  pushl $0
80105c0c:	6a 00                	push   $0x0
  pushl $205
80105c0e:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105c13:	e9 ad f3 ff ff       	jmp    80104fc5 <alltraps>

80105c18 <vector206>:
.globl vector206
vector206:
  pushl $0
80105c18:	6a 00                	push   $0x0
  pushl $206
80105c1a:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105c1f:	e9 a1 f3 ff ff       	jmp    80104fc5 <alltraps>

80105c24 <vector207>:
.globl vector207
vector207:
  pushl $0
80105c24:	6a 00                	push   $0x0
  pushl $207
80105c26:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105c2b:	e9 95 f3 ff ff       	jmp    80104fc5 <alltraps>

80105c30 <vector208>:
.globl vector208
vector208:
  pushl $0
80105c30:	6a 00                	push   $0x0
  pushl $208
80105c32:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105c37:	e9 89 f3 ff ff       	jmp    80104fc5 <alltraps>

80105c3c <vector209>:
.globl vector209
vector209:
  pushl $0
80105c3c:	6a 00                	push   $0x0
  pushl $209
80105c3e:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105c43:	e9 7d f3 ff ff       	jmp    80104fc5 <alltraps>

80105c48 <vector210>:
.globl vector210
vector210:
  pushl $0
80105c48:	6a 00                	push   $0x0
  pushl $210
80105c4a:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105c4f:	e9 71 f3 ff ff       	jmp    80104fc5 <alltraps>

80105c54 <vector211>:
.globl vector211
vector211:
  pushl $0
80105c54:	6a 00                	push   $0x0
  pushl $211
80105c56:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105c5b:	e9 65 f3 ff ff       	jmp    80104fc5 <alltraps>

80105c60 <vector212>:
.globl vector212
vector212:
  pushl $0
80105c60:	6a 00                	push   $0x0
  pushl $212
80105c62:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105c67:	e9 59 f3 ff ff       	jmp    80104fc5 <alltraps>

80105c6c <vector213>:
.globl vector213
vector213:
  pushl $0
80105c6c:	6a 00                	push   $0x0
  pushl $213
80105c6e:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105c73:	e9 4d f3 ff ff       	jmp    80104fc5 <alltraps>

80105c78 <vector214>:
.globl vector214
vector214:
  pushl $0
80105c78:	6a 00                	push   $0x0
  pushl $214
80105c7a:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105c7f:	e9 41 f3 ff ff       	jmp    80104fc5 <alltraps>

80105c84 <vector215>:
.globl vector215
vector215:
  pushl $0
80105c84:	6a 00                	push   $0x0
  pushl $215
80105c86:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105c8b:	e9 35 f3 ff ff       	jmp    80104fc5 <alltraps>

80105c90 <vector216>:
.globl vector216
vector216:
  pushl $0
80105c90:	6a 00                	push   $0x0
  pushl $216
80105c92:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105c97:	e9 29 f3 ff ff       	jmp    80104fc5 <alltraps>

80105c9c <vector217>:
.globl vector217
vector217:
  pushl $0
80105c9c:	6a 00                	push   $0x0
  pushl $217
80105c9e:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105ca3:	e9 1d f3 ff ff       	jmp    80104fc5 <alltraps>

80105ca8 <vector218>:
.globl vector218
vector218:
  pushl $0
80105ca8:	6a 00                	push   $0x0
  pushl $218
80105caa:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105caf:	e9 11 f3 ff ff       	jmp    80104fc5 <alltraps>

80105cb4 <vector219>:
.globl vector219
vector219:
  pushl $0
80105cb4:	6a 00                	push   $0x0
  pushl $219
80105cb6:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105cbb:	e9 05 f3 ff ff       	jmp    80104fc5 <alltraps>

80105cc0 <vector220>:
.globl vector220
vector220:
  pushl $0
80105cc0:	6a 00                	push   $0x0
  pushl $220
80105cc2:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105cc7:	e9 f9 f2 ff ff       	jmp    80104fc5 <alltraps>

80105ccc <vector221>:
.globl vector221
vector221:
  pushl $0
80105ccc:	6a 00                	push   $0x0
  pushl $221
80105cce:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105cd3:	e9 ed f2 ff ff       	jmp    80104fc5 <alltraps>

80105cd8 <vector222>:
.globl vector222
vector222:
  pushl $0
80105cd8:	6a 00                	push   $0x0
  pushl $222
80105cda:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105cdf:	e9 e1 f2 ff ff       	jmp    80104fc5 <alltraps>

80105ce4 <vector223>:
.globl vector223
vector223:
  pushl $0
80105ce4:	6a 00                	push   $0x0
  pushl $223
80105ce6:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105ceb:	e9 d5 f2 ff ff       	jmp    80104fc5 <alltraps>

80105cf0 <vector224>:
.globl vector224
vector224:
  pushl $0
80105cf0:	6a 00                	push   $0x0
  pushl $224
80105cf2:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105cf7:	e9 c9 f2 ff ff       	jmp    80104fc5 <alltraps>

80105cfc <vector225>:
.globl vector225
vector225:
  pushl $0
80105cfc:	6a 00                	push   $0x0
  pushl $225
80105cfe:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105d03:	e9 bd f2 ff ff       	jmp    80104fc5 <alltraps>

80105d08 <vector226>:
.globl vector226
vector226:
  pushl $0
80105d08:	6a 00                	push   $0x0
  pushl $226
80105d0a:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105d0f:	e9 b1 f2 ff ff       	jmp    80104fc5 <alltraps>

80105d14 <vector227>:
.globl vector227
vector227:
  pushl $0
80105d14:	6a 00                	push   $0x0
  pushl $227
80105d16:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105d1b:	e9 a5 f2 ff ff       	jmp    80104fc5 <alltraps>

80105d20 <vector228>:
.globl vector228
vector228:
  pushl $0
80105d20:	6a 00                	push   $0x0
  pushl $228
80105d22:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105d27:	e9 99 f2 ff ff       	jmp    80104fc5 <alltraps>

80105d2c <vector229>:
.globl vector229
vector229:
  pushl $0
80105d2c:	6a 00                	push   $0x0
  pushl $229
80105d2e:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105d33:	e9 8d f2 ff ff       	jmp    80104fc5 <alltraps>

80105d38 <vector230>:
.globl vector230
vector230:
  pushl $0
80105d38:	6a 00                	push   $0x0
  pushl $230
80105d3a:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105d3f:	e9 81 f2 ff ff       	jmp    80104fc5 <alltraps>

80105d44 <vector231>:
.globl vector231
vector231:
  pushl $0
80105d44:	6a 00                	push   $0x0
  pushl $231
80105d46:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105d4b:	e9 75 f2 ff ff       	jmp    80104fc5 <alltraps>

80105d50 <vector232>:
.globl vector232
vector232:
  pushl $0
80105d50:	6a 00                	push   $0x0
  pushl $232
80105d52:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105d57:	e9 69 f2 ff ff       	jmp    80104fc5 <alltraps>

80105d5c <vector233>:
.globl vector233
vector233:
  pushl $0
80105d5c:	6a 00                	push   $0x0
  pushl $233
80105d5e:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105d63:	e9 5d f2 ff ff       	jmp    80104fc5 <alltraps>

80105d68 <vector234>:
.globl vector234
vector234:
  pushl $0
80105d68:	6a 00                	push   $0x0
  pushl $234
80105d6a:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105d6f:	e9 51 f2 ff ff       	jmp    80104fc5 <alltraps>

80105d74 <vector235>:
.globl vector235
vector235:
  pushl $0
80105d74:	6a 00                	push   $0x0
  pushl $235
80105d76:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105d7b:	e9 45 f2 ff ff       	jmp    80104fc5 <alltraps>

80105d80 <vector236>:
.globl vector236
vector236:
  pushl $0
80105d80:	6a 00                	push   $0x0
  pushl $236
80105d82:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105d87:	e9 39 f2 ff ff       	jmp    80104fc5 <alltraps>

80105d8c <vector237>:
.globl vector237
vector237:
  pushl $0
80105d8c:	6a 00                	push   $0x0
  pushl $237
80105d8e:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105d93:	e9 2d f2 ff ff       	jmp    80104fc5 <alltraps>

80105d98 <vector238>:
.globl vector238
vector238:
  pushl $0
80105d98:	6a 00                	push   $0x0
  pushl $238
80105d9a:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105d9f:	e9 21 f2 ff ff       	jmp    80104fc5 <alltraps>

80105da4 <vector239>:
.globl vector239
vector239:
  pushl $0
80105da4:	6a 00                	push   $0x0
  pushl $239
80105da6:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105dab:	e9 15 f2 ff ff       	jmp    80104fc5 <alltraps>

80105db0 <vector240>:
.globl vector240
vector240:
  pushl $0
80105db0:	6a 00                	push   $0x0
  pushl $240
80105db2:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105db7:	e9 09 f2 ff ff       	jmp    80104fc5 <alltraps>

80105dbc <vector241>:
.globl vector241
vector241:
  pushl $0
80105dbc:	6a 00                	push   $0x0
  pushl $241
80105dbe:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105dc3:	e9 fd f1 ff ff       	jmp    80104fc5 <alltraps>

80105dc8 <vector242>:
.globl vector242
vector242:
  pushl $0
80105dc8:	6a 00                	push   $0x0
  pushl $242
80105dca:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105dcf:	e9 f1 f1 ff ff       	jmp    80104fc5 <alltraps>

80105dd4 <vector243>:
.globl vector243
vector243:
  pushl $0
80105dd4:	6a 00                	push   $0x0
  pushl $243
80105dd6:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105ddb:	e9 e5 f1 ff ff       	jmp    80104fc5 <alltraps>

80105de0 <vector244>:
.globl vector244
vector244:
  pushl $0
80105de0:	6a 00                	push   $0x0
  pushl $244
80105de2:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105de7:	e9 d9 f1 ff ff       	jmp    80104fc5 <alltraps>

80105dec <vector245>:
.globl vector245
vector245:
  pushl $0
80105dec:	6a 00                	push   $0x0
  pushl $245
80105dee:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105df3:	e9 cd f1 ff ff       	jmp    80104fc5 <alltraps>

80105df8 <vector246>:
.globl vector246
vector246:
  pushl $0
80105df8:	6a 00                	push   $0x0
  pushl $246
80105dfa:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105dff:	e9 c1 f1 ff ff       	jmp    80104fc5 <alltraps>

80105e04 <vector247>:
.globl vector247
vector247:
  pushl $0
80105e04:	6a 00                	push   $0x0
  pushl $247
80105e06:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105e0b:	e9 b5 f1 ff ff       	jmp    80104fc5 <alltraps>

80105e10 <vector248>:
.globl vector248
vector248:
  pushl $0
80105e10:	6a 00                	push   $0x0
  pushl $248
80105e12:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105e17:	e9 a9 f1 ff ff       	jmp    80104fc5 <alltraps>

80105e1c <vector249>:
.globl vector249
vector249:
  pushl $0
80105e1c:	6a 00                	push   $0x0
  pushl $249
80105e1e:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105e23:	e9 9d f1 ff ff       	jmp    80104fc5 <alltraps>

80105e28 <vector250>:
.globl vector250
vector250:
  pushl $0
80105e28:	6a 00                	push   $0x0
  pushl $250
80105e2a:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105e2f:	e9 91 f1 ff ff       	jmp    80104fc5 <alltraps>

80105e34 <vector251>:
.globl vector251
vector251:
  pushl $0
80105e34:	6a 00                	push   $0x0
  pushl $251
80105e36:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105e3b:	e9 85 f1 ff ff       	jmp    80104fc5 <alltraps>

80105e40 <vector252>:
.globl vector252
vector252:
  pushl $0
80105e40:	6a 00                	push   $0x0
  pushl $252
80105e42:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105e47:	e9 79 f1 ff ff       	jmp    80104fc5 <alltraps>

80105e4c <vector253>:
.globl vector253
vector253:
  pushl $0
80105e4c:	6a 00                	push   $0x0
  pushl $253
80105e4e:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105e53:	e9 6d f1 ff ff       	jmp    80104fc5 <alltraps>

80105e58 <vector254>:
.globl vector254
vector254:
  pushl $0
80105e58:	6a 00                	push   $0x0
  pushl $254
80105e5a:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105e5f:	e9 61 f1 ff ff       	jmp    80104fc5 <alltraps>

80105e64 <vector255>:
.globl vector255
vector255:
  pushl $0
80105e64:	6a 00                	push   $0x0
  pushl $255
80105e66:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105e6b:	e9 55 f1 ff ff       	jmp    80104fc5 <alltraps>

80105e70 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105e70:	55                   	push   %ebp
80105e71:	89 e5                	mov    %esp,%ebp
80105e73:	57                   	push   %edi
80105e74:	56                   	push   %esi
80105e75:	53                   	push   %ebx
80105e76:	83 ec 0c             	sub    $0xc,%esp
80105e79:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105e7b:	c1 ea 16             	shr    $0x16,%edx
80105e7e:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105e81:	8b 1f                	mov    (%edi),%ebx
80105e83:	f6 c3 01             	test   $0x1,%bl
80105e86:	74 22                	je     80105eaa <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105e88:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105e8e:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105e94:	c1 ee 0c             	shr    $0xc,%esi
80105e97:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105e9d:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105ea0:	89 d8                	mov    %ebx,%eax
80105ea2:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105ea5:	5b                   	pop    %ebx
80105ea6:	5e                   	pop    %esi
80105ea7:	5f                   	pop    %edi
80105ea8:	5d                   	pop    %ebp
80105ea9:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc2()) == 0)
80105eaa:	85 c9                	test   %ecx,%ecx
80105eac:	74 2b                	je     80105ed9 <walkpgdir+0x69>
80105eae:	e8 bd c3 ff ff       	call   80102270 <kalloc2>
80105eb3:	89 c3                	mov    %eax,%ebx
80105eb5:	85 c0                	test   %eax,%eax
80105eb7:	74 e7                	je     80105ea0 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105eb9:	83 ec 04             	sub    $0x4,%esp
80105ebc:	68 00 10 00 00       	push   $0x1000
80105ec1:	6a 00                	push   $0x0
80105ec3:	50                   	push   %eax
80105ec4:	e8 fe df ff ff       	call   80103ec7 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105ec9:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105ecf:	83 c8 07             	or     $0x7,%eax
80105ed2:	89 07                	mov    %eax,(%edi)
80105ed4:	83 c4 10             	add    $0x10,%esp
80105ed7:	eb bb                	jmp    80105e94 <walkpgdir+0x24>
      return 0;
80105ed9:	bb 00 00 00 00       	mov    $0x0,%ebx
80105ede:	eb c0                	jmp    80105ea0 <walkpgdir+0x30>

80105ee0 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105ee0:	55                   	push   %ebp
80105ee1:	89 e5                	mov    %esp,%ebp
80105ee3:	57                   	push   %edi
80105ee4:	56                   	push   %esi
80105ee5:	53                   	push   %ebx
80105ee6:	83 ec 1c             	sub    $0x1c,%esp
80105ee9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105eec:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80105eef:	89 d3                	mov    %edx,%ebx
80105ef1:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105ef7:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105efb:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105f01:	b9 01 00 00 00       	mov    $0x1,%ecx
80105f06:	89 da                	mov    %ebx,%edx
80105f08:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f0b:	e8 60 ff ff ff       	call   80105e70 <walkpgdir>
80105f10:	85 c0                	test   %eax,%eax
80105f12:	74 2e                	je     80105f42 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105f14:	f6 00 01             	testb  $0x1,(%eax)
80105f17:	75 1c                	jne    80105f35 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105f19:	89 f2                	mov    %esi,%edx
80105f1b:	0b 55 0c             	or     0xc(%ebp),%edx
80105f1e:	83 ca 01             	or     $0x1,%edx
80105f21:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105f23:	39 fb                	cmp    %edi,%ebx
80105f25:	74 28                	je     80105f4f <mappages+0x6f>
      break;
    a += PGSIZE;
80105f27:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105f2d:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105f33:	eb cc                	jmp    80105f01 <mappages+0x21>
      panic("remap");
80105f35:	83 ec 0c             	sub    $0xc,%esp
80105f38:	68 0c 70 10 80       	push   $0x8010700c
80105f3d:	e8 06 a4 ff ff       	call   80100348 <panic>
      return -1;
80105f42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105f47:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105f4a:	5b                   	pop    %ebx
80105f4b:	5e                   	pop    %esi
80105f4c:	5f                   	pop    %edi
80105f4d:	5d                   	pop    %ebp
80105f4e:	c3                   	ret    
  return 0;
80105f4f:	b8 00 00 00 00       	mov    $0x0,%eax
80105f54:	eb f1                	jmp    80105f47 <mappages+0x67>

80105f56 <seginit>:
{
80105f56:	55                   	push   %ebp
80105f57:	89 e5                	mov    %esp,%ebp
80105f59:	53                   	push   %ebx
80105f5a:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105f5d:	e8 8d d4 ff ff       	call   801033ef <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105f62:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105f68:	66 c7 80 18 28 13 80 	movw   $0xffff,-0x7fecd7e8(%eax)
80105f6f:	ff ff 
80105f71:	66 c7 80 1a 28 13 80 	movw   $0x0,-0x7fecd7e6(%eax)
80105f78:	00 00 
80105f7a:	c6 80 1c 28 13 80 00 	movb   $0x0,-0x7fecd7e4(%eax)
80105f81:	0f b6 88 1d 28 13 80 	movzbl -0x7fecd7e3(%eax),%ecx
80105f88:	83 e1 f0             	and    $0xfffffff0,%ecx
80105f8b:	83 c9 1a             	or     $0x1a,%ecx
80105f8e:	83 e1 9f             	and    $0xffffff9f,%ecx
80105f91:	83 c9 80             	or     $0xffffff80,%ecx
80105f94:	88 88 1d 28 13 80    	mov    %cl,-0x7fecd7e3(%eax)
80105f9a:	0f b6 88 1e 28 13 80 	movzbl -0x7fecd7e2(%eax),%ecx
80105fa1:	83 c9 0f             	or     $0xf,%ecx
80105fa4:	83 e1 cf             	and    $0xffffffcf,%ecx
80105fa7:	83 c9 c0             	or     $0xffffffc0,%ecx
80105faa:	88 88 1e 28 13 80    	mov    %cl,-0x7fecd7e2(%eax)
80105fb0:	c6 80 1f 28 13 80 00 	movb   $0x0,-0x7fecd7e1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105fb7:	66 c7 80 20 28 13 80 	movw   $0xffff,-0x7fecd7e0(%eax)
80105fbe:	ff ff 
80105fc0:	66 c7 80 22 28 13 80 	movw   $0x0,-0x7fecd7de(%eax)
80105fc7:	00 00 
80105fc9:	c6 80 24 28 13 80 00 	movb   $0x0,-0x7fecd7dc(%eax)
80105fd0:	0f b6 88 25 28 13 80 	movzbl -0x7fecd7db(%eax),%ecx
80105fd7:	83 e1 f0             	and    $0xfffffff0,%ecx
80105fda:	83 c9 12             	or     $0x12,%ecx
80105fdd:	83 e1 9f             	and    $0xffffff9f,%ecx
80105fe0:	83 c9 80             	or     $0xffffff80,%ecx
80105fe3:	88 88 25 28 13 80    	mov    %cl,-0x7fecd7db(%eax)
80105fe9:	0f b6 88 26 28 13 80 	movzbl -0x7fecd7da(%eax),%ecx
80105ff0:	83 c9 0f             	or     $0xf,%ecx
80105ff3:	83 e1 cf             	and    $0xffffffcf,%ecx
80105ff6:	83 c9 c0             	or     $0xffffffc0,%ecx
80105ff9:	88 88 26 28 13 80    	mov    %cl,-0x7fecd7da(%eax)
80105fff:	c6 80 27 28 13 80 00 	movb   $0x0,-0x7fecd7d9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80106006:	66 c7 80 28 28 13 80 	movw   $0xffff,-0x7fecd7d8(%eax)
8010600d:	ff ff 
8010600f:	66 c7 80 2a 28 13 80 	movw   $0x0,-0x7fecd7d6(%eax)
80106016:	00 00 
80106018:	c6 80 2c 28 13 80 00 	movb   $0x0,-0x7fecd7d4(%eax)
8010601f:	c6 80 2d 28 13 80 fa 	movb   $0xfa,-0x7fecd7d3(%eax)
80106026:	0f b6 88 2e 28 13 80 	movzbl -0x7fecd7d2(%eax),%ecx
8010602d:	83 c9 0f             	or     $0xf,%ecx
80106030:	83 e1 cf             	and    $0xffffffcf,%ecx
80106033:	83 c9 c0             	or     $0xffffffc0,%ecx
80106036:	88 88 2e 28 13 80    	mov    %cl,-0x7fecd7d2(%eax)
8010603c:	c6 80 2f 28 13 80 00 	movb   $0x0,-0x7fecd7d1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80106043:	66 c7 80 30 28 13 80 	movw   $0xffff,-0x7fecd7d0(%eax)
8010604a:	ff ff 
8010604c:	66 c7 80 32 28 13 80 	movw   $0x0,-0x7fecd7ce(%eax)
80106053:	00 00 
80106055:	c6 80 34 28 13 80 00 	movb   $0x0,-0x7fecd7cc(%eax)
8010605c:	c6 80 35 28 13 80 f2 	movb   $0xf2,-0x7fecd7cb(%eax)
80106063:	0f b6 88 36 28 13 80 	movzbl -0x7fecd7ca(%eax),%ecx
8010606a:	83 c9 0f             	or     $0xf,%ecx
8010606d:	83 e1 cf             	and    $0xffffffcf,%ecx
80106070:	83 c9 c0             	or     $0xffffffc0,%ecx
80106073:	88 88 36 28 13 80    	mov    %cl,-0x7fecd7ca(%eax)
80106079:	c6 80 37 28 13 80 00 	movb   $0x0,-0x7fecd7c9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80106080:	05 10 28 13 80       	add    $0x80132810,%eax
  pd[0] = size-1;
80106085:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
8010608b:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
8010608f:	c1 e8 10             	shr    $0x10,%eax
80106092:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80106096:	8d 45 f2             	lea    -0xe(%ebp),%eax
80106099:	0f 01 10             	lgdtl  (%eax)
}
8010609c:	83 c4 14             	add    $0x14,%esp
8010609f:	5b                   	pop    %ebx
801060a0:	5d                   	pop    %ebp
801060a1:	c3                   	ret    

801060a2 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
801060a2:	55                   	push   %ebp
801060a3:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
801060a5:	a1 c4 54 13 80       	mov    0x801354c4,%eax
801060aa:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
801060af:	0f 22 d8             	mov    %eax,%cr3
}
801060b2:	5d                   	pop    %ebp
801060b3:	c3                   	ret    

801060b4 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801060b4:	55                   	push   %ebp
801060b5:	89 e5                	mov    %esp,%ebp
801060b7:	57                   	push   %edi
801060b8:	56                   	push   %esi
801060b9:	53                   	push   %ebx
801060ba:	83 ec 1c             	sub    $0x1c,%esp
801060bd:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
801060c0:	85 f6                	test   %esi,%esi
801060c2:	0f 84 dd 00 00 00    	je     801061a5 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
801060c8:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
801060cc:	0f 84 e0 00 00 00    	je     801061b2 <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
801060d2:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
801060d6:	0f 84 e3 00 00 00    	je     801061bf <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
801060dc:	e8 5d dc ff ff       	call   80103d3e <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
801060e1:	e8 ad d2 ff ff       	call   80103393 <mycpu>
801060e6:	89 c3                	mov    %eax,%ebx
801060e8:	e8 a6 d2 ff ff       	call   80103393 <mycpu>
801060ed:	8d 78 08             	lea    0x8(%eax),%edi
801060f0:	e8 9e d2 ff ff       	call   80103393 <mycpu>
801060f5:	83 c0 08             	add    $0x8,%eax
801060f8:	c1 e8 10             	shr    $0x10,%eax
801060fb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801060fe:	e8 90 d2 ff ff       	call   80103393 <mycpu>
80106103:	83 c0 08             	add    $0x8,%eax
80106106:	c1 e8 18             	shr    $0x18,%eax
80106109:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80106110:	67 00 
80106112:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80106119:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
8010611d:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80106123:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
8010612a:	83 e2 f0             	and    $0xfffffff0,%edx
8010612d:	83 ca 19             	or     $0x19,%edx
80106130:	83 e2 9f             	and    $0xffffff9f,%edx
80106133:	83 ca 80             	or     $0xffffff80,%edx
80106136:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
8010613c:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80106143:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80106149:	e8 45 d2 ff ff       	call   80103393 <mycpu>
8010614e:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106155:	83 e2 ef             	and    $0xffffffef,%edx
80106158:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
8010615e:	e8 30 d2 ff ff       	call   80103393 <mycpu>
80106163:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80106169:	8b 5e 08             	mov    0x8(%esi),%ebx
8010616c:	e8 22 d2 ff ff       	call   80103393 <mycpu>
80106171:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106177:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
8010617a:	e8 14 d2 ff ff       	call   80103393 <mycpu>
8010617f:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80106185:	b8 28 00 00 00       	mov    $0x28,%eax
8010618a:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
8010618d:	8b 46 04             	mov    0x4(%esi),%eax
80106190:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106195:	0f 22 d8             	mov    %eax,%cr3
  popcli();
80106198:	e8 de db ff ff       	call   80103d7b <popcli>
}
8010619d:	8d 65 f4             	lea    -0xc(%ebp),%esp
801061a0:	5b                   	pop    %ebx
801061a1:	5e                   	pop    %esi
801061a2:	5f                   	pop    %edi
801061a3:	5d                   	pop    %ebp
801061a4:	c3                   	ret    
    panic("switchuvm: no process");
801061a5:	83 ec 0c             	sub    $0xc,%esp
801061a8:	68 12 70 10 80       	push   $0x80107012
801061ad:	e8 96 a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
801061b2:	83 ec 0c             	sub    $0xc,%esp
801061b5:	68 28 70 10 80       	push   $0x80107028
801061ba:	e8 89 a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
801061bf:	83 ec 0c             	sub    $0xc,%esp
801061c2:	68 3d 70 10 80       	push   $0x8010703d
801061c7:	e8 7c a1 ff ff       	call   80100348 <panic>

801061cc <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801061cc:	55                   	push   %ebp
801061cd:	89 e5                	mov    %esp,%ebp
801061cf:	56                   	push   %esi
801061d0:	53                   	push   %ebx
801061d1:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
801061d4:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801061da:	77 4c                	ja     80106228 <inituvm+0x5c>
    panic("inituvm: more than a page");
  // ignore this call to kalloc. Mark as UNKNOWN
  mem = kalloc2();
801061dc:	e8 8f c0 ff ff       	call   80102270 <kalloc2>
801061e1:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
801061e3:	83 ec 04             	sub    $0x4,%esp
801061e6:	68 00 10 00 00       	push   $0x1000
801061eb:	6a 00                	push   $0x0
801061ed:	50                   	push   %eax
801061ee:	e8 d4 dc ff ff       	call   80103ec7 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
801061f3:	83 c4 08             	add    $0x8,%esp
801061f6:	6a 06                	push   $0x6
801061f8:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801061fe:	50                   	push   %eax
801061ff:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106204:	ba 00 00 00 00       	mov    $0x0,%edx
80106209:	8b 45 08             	mov    0x8(%ebp),%eax
8010620c:	e8 cf fc ff ff       	call   80105ee0 <mappages>
  memmove(mem, init, sz);
80106211:	83 c4 0c             	add    $0xc,%esp
80106214:	56                   	push   %esi
80106215:	ff 75 0c             	pushl  0xc(%ebp)
80106218:	53                   	push   %ebx
80106219:	e8 24 dd ff ff       	call   80103f42 <memmove>
}
8010621e:	83 c4 10             	add    $0x10,%esp
80106221:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106224:	5b                   	pop    %ebx
80106225:	5e                   	pop    %esi
80106226:	5d                   	pop    %ebp
80106227:	c3                   	ret    
    panic("inituvm: more than a page");
80106228:	83 ec 0c             	sub    $0xc,%esp
8010622b:	68 51 70 10 80       	push   $0x80107051
80106230:	e8 13 a1 ff ff       	call   80100348 <panic>

80106235 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80106235:	55                   	push   %ebp
80106236:	89 e5                	mov    %esp,%ebp
80106238:	57                   	push   %edi
80106239:	56                   	push   %esi
8010623a:	53                   	push   %ebx
8010623b:	83 ec 0c             	sub    $0xc,%esp
8010623e:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80106241:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
80106248:	75 07                	jne    80106251 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
8010624a:	bb 00 00 00 00       	mov    $0x0,%ebx
8010624f:	eb 3c                	jmp    8010628d <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
80106251:	83 ec 0c             	sub    $0xc,%esp
80106254:	68 0c 71 10 80       	push   $0x8010710c
80106259:	e8 ea a0 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
8010625e:	83 ec 0c             	sub    $0xc,%esp
80106261:	68 6b 70 10 80       	push   $0x8010706b
80106266:	e8 dd a0 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
8010626b:	05 00 00 00 80       	add    $0x80000000,%eax
80106270:	56                   	push   %esi
80106271:	89 da                	mov    %ebx,%edx
80106273:	03 55 14             	add    0x14(%ebp),%edx
80106276:	52                   	push   %edx
80106277:	50                   	push   %eax
80106278:	ff 75 10             	pushl  0x10(%ebp)
8010627b:	e8 f3 b4 ff ff       	call   80101773 <readi>
80106280:	83 c4 10             	add    $0x10,%esp
80106283:	39 f0                	cmp    %esi,%eax
80106285:	75 47                	jne    801062ce <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
80106287:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010628d:	39 fb                	cmp    %edi,%ebx
8010628f:	73 30                	jae    801062c1 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80106291:	89 da                	mov    %ebx,%edx
80106293:	03 55 0c             	add    0xc(%ebp),%edx
80106296:	b9 00 00 00 00       	mov    $0x0,%ecx
8010629b:	8b 45 08             	mov    0x8(%ebp),%eax
8010629e:	e8 cd fb ff ff       	call   80105e70 <walkpgdir>
801062a3:	85 c0                	test   %eax,%eax
801062a5:	74 b7                	je     8010625e <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
801062a7:	8b 00                	mov    (%eax),%eax
801062a9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
801062ae:	89 fe                	mov    %edi,%esi
801062b0:	29 de                	sub    %ebx,%esi
801062b2:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801062b8:	76 b1                	jbe    8010626b <loaduvm+0x36>
      n = PGSIZE;
801062ba:	be 00 10 00 00       	mov    $0x1000,%esi
801062bf:	eb aa                	jmp    8010626b <loaduvm+0x36>
      return -1;
  }
  return 0;
801062c1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801062c6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801062c9:	5b                   	pop    %ebx
801062ca:	5e                   	pop    %esi
801062cb:	5f                   	pop    %edi
801062cc:	5d                   	pop    %ebp
801062cd:	c3                   	ret    
      return -1;
801062ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062d3:	eb f1                	jmp    801062c6 <loaduvm+0x91>

801062d5 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801062d5:	55                   	push   %ebp
801062d6:	89 e5                	mov    %esp,%ebp
801062d8:	57                   	push   %edi
801062d9:	56                   	push   %esi
801062da:	53                   	push   %ebx
801062db:	83 ec 0c             	sub    $0xc,%esp
801062de:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801062e1:	39 7d 10             	cmp    %edi,0x10(%ebp)
801062e4:	73 11                	jae    801062f7 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
801062e6:	8b 45 10             	mov    0x10(%ebp),%eax
801062e9:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801062ef:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801062f5:	eb 19                	jmp    80106310 <deallocuvm+0x3b>
    return oldsz;
801062f7:	89 f8                	mov    %edi,%eax
801062f9:	eb 64                	jmp    8010635f <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
801062fb:	c1 eb 16             	shr    $0x16,%ebx
801062fe:	83 c3 01             	add    $0x1,%ebx
80106301:	c1 e3 16             	shl    $0x16,%ebx
80106304:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010630a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106310:	39 fb                	cmp    %edi,%ebx
80106312:	73 48                	jae    8010635c <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
80106314:	b9 00 00 00 00       	mov    $0x0,%ecx
80106319:	89 da                	mov    %ebx,%edx
8010631b:	8b 45 08             	mov    0x8(%ebp),%eax
8010631e:	e8 4d fb ff ff       	call   80105e70 <walkpgdir>
80106323:	89 c6                	mov    %eax,%esi
    if(!pte)
80106325:	85 c0                	test   %eax,%eax
80106327:	74 d2                	je     801062fb <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
80106329:	8b 00                	mov    (%eax),%eax
8010632b:	a8 01                	test   $0x1,%al
8010632d:	74 db                	je     8010630a <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
8010632f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106334:	74 19                	je     8010634f <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
80106336:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
8010633b:	83 ec 0c             	sub    $0xc,%esp
8010633e:	50                   	push   %eax
8010633f:	e8 7e bc ff ff       	call   80101fc2 <kfree>
      *pte = 0;
80106344:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
8010634a:	83 c4 10             	add    $0x10,%esp
8010634d:	eb bb                	jmp    8010630a <deallocuvm+0x35>
        panic("kfree");
8010634f:	83 ec 0c             	sub    $0xc,%esp
80106352:	68 a6 69 10 80       	push   $0x801069a6
80106357:	e8 ec 9f ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
8010635c:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010635f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106362:	5b                   	pop    %ebx
80106363:	5e                   	pop    %esi
80106364:	5f                   	pop    %edi
80106365:	5d                   	pop    %ebp
80106366:	c3                   	ret    

80106367 <allocuvm>:
{
80106367:	55                   	push   %ebp
80106368:	89 e5                	mov    %esp,%ebp
8010636a:	57                   	push   %edi
8010636b:	56                   	push   %esi
8010636c:	53                   	push   %ebx
8010636d:	83 ec 1c             	sub    $0x1c,%esp
80106370:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
80106373:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106376:	85 ff                	test   %edi,%edi
80106378:	0f 88 e0 00 00 00    	js     8010645e <allocuvm+0xf7>
  if(newsz < oldsz)
8010637e:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106381:	73 11                	jae    80106394 <allocuvm+0x2d>
    return oldsz;
80106383:	8b 45 0c             	mov    0xc(%ebp),%eax
80106386:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}
80106389:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010638c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010638f:	5b                   	pop    %ebx
80106390:	5e                   	pop    %esi
80106391:	5f                   	pop    %edi
80106392:	5d                   	pop    %ebp
80106393:	c3                   	ret    
  a = PGROUNDUP(oldsz);
80106394:	8b 45 0c             	mov    0xc(%ebp),%eax
80106397:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
8010639d:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  int pid = myproc()->pid;
801063a3:	e8 62 d0 ff ff       	call   8010340a <myproc>
801063a8:	8b 40 10             	mov    0x10(%eax),%eax
801063ab:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(; a < newsz; a += PGSIZE){
801063ae:	39 fb                	cmp    %edi,%ebx
801063b0:	73 d7                	jae    80106389 <allocuvm+0x22>
    mem = kalloc(pid);
801063b2:	83 ec 0c             	sub    $0xc,%esp
801063b5:	ff 75 e0             	pushl  -0x20(%ebp)
801063b8:	e8 1a be ff ff       	call   801021d7 <kalloc>
801063bd:	89 c6                	mov    %eax,%esi
    if(mem == 0){
801063bf:	83 c4 10             	add    $0x10,%esp
801063c2:	85 c0                	test   %eax,%eax
801063c4:	74 3a                	je     80106400 <allocuvm+0x99>
    memset(mem, 0, PGSIZE);
801063c6:	83 ec 04             	sub    $0x4,%esp
801063c9:	68 00 10 00 00       	push   $0x1000
801063ce:	6a 00                	push   $0x0
801063d0:	50                   	push   %eax
801063d1:	e8 f1 da ff ff       	call   80103ec7 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
801063d6:	83 c4 08             	add    $0x8,%esp
801063d9:	6a 06                	push   $0x6
801063db:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
801063e1:	50                   	push   %eax
801063e2:	b9 00 10 00 00       	mov    $0x1000,%ecx
801063e7:	89 da                	mov    %ebx,%edx
801063e9:	8b 45 08             	mov    0x8(%ebp),%eax
801063ec:	e8 ef fa ff ff       	call   80105ee0 <mappages>
801063f1:	83 c4 10             	add    $0x10,%esp
801063f4:	85 c0                	test   %eax,%eax
801063f6:	78 33                	js     8010642b <allocuvm+0xc4>
  for(; a < newsz; a += PGSIZE){
801063f8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801063fe:	eb ae                	jmp    801063ae <allocuvm+0x47>
      cprintf("allocuvm out of memory\n");
80106400:	83 ec 0c             	sub    $0xc,%esp
80106403:	68 89 70 10 80       	push   $0x80107089
80106408:	e8 fe a1 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010640d:	83 c4 0c             	add    $0xc,%esp
80106410:	ff 75 0c             	pushl  0xc(%ebp)
80106413:	57                   	push   %edi
80106414:	ff 75 08             	pushl  0x8(%ebp)
80106417:	e8 b9 fe ff ff       	call   801062d5 <deallocuvm>
      return 0;
8010641c:	83 c4 10             	add    $0x10,%esp
8010641f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106426:	e9 5e ff ff ff       	jmp    80106389 <allocuvm+0x22>
      cprintf("allocuvm out of memory (2)\n");
8010642b:	83 ec 0c             	sub    $0xc,%esp
8010642e:	68 a1 70 10 80       	push   $0x801070a1
80106433:	e8 d3 a1 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106438:	83 c4 0c             	add    $0xc,%esp
8010643b:	ff 75 0c             	pushl  0xc(%ebp)
8010643e:	57                   	push   %edi
8010643f:	ff 75 08             	pushl  0x8(%ebp)
80106442:	e8 8e fe ff ff       	call   801062d5 <deallocuvm>
      kfree(mem);
80106447:	89 34 24             	mov    %esi,(%esp)
8010644a:	e8 73 bb ff ff       	call   80101fc2 <kfree>
      return 0;
8010644f:	83 c4 10             	add    $0x10,%esp
80106452:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106459:	e9 2b ff ff ff       	jmp    80106389 <allocuvm+0x22>
    return 0;
8010645e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106465:	e9 1f ff ff ff       	jmp    80106389 <allocuvm+0x22>

8010646a <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
8010646a:	55                   	push   %ebp
8010646b:	89 e5                	mov    %esp,%ebp
8010646d:	56                   	push   %esi
8010646e:	53                   	push   %ebx
8010646f:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
80106472:	85 f6                	test   %esi,%esi
80106474:	74 1a                	je     80106490 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
80106476:	83 ec 04             	sub    $0x4,%esp
80106479:	6a 00                	push   $0x0
8010647b:	68 00 00 00 80       	push   $0x80000000
80106480:	56                   	push   %esi
80106481:	e8 4f fe ff ff       	call   801062d5 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80106486:	83 c4 10             	add    $0x10,%esp
80106489:	bb 00 00 00 00       	mov    $0x0,%ebx
8010648e:	eb 10                	jmp    801064a0 <freevm+0x36>
    panic("freevm: no pgdir");
80106490:	83 ec 0c             	sub    $0xc,%esp
80106493:	68 bd 70 10 80       	push   $0x801070bd
80106498:	e8 ab 9e ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
8010649d:	83 c3 01             	add    $0x1,%ebx
801064a0:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
801064a6:	77 1f                	ja     801064c7 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
801064a8:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
801064ab:	a8 01                	test   $0x1,%al
801064ad:	74 ee                	je     8010649d <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801064af:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801064b4:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801064b9:	83 ec 0c             	sub    $0xc,%esp
801064bc:	50                   	push   %eax
801064bd:	e8 00 bb ff ff       	call   80101fc2 <kfree>
801064c2:	83 c4 10             	add    $0x10,%esp
801064c5:	eb d6                	jmp    8010649d <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
801064c7:	83 ec 0c             	sub    $0xc,%esp
801064ca:	56                   	push   %esi
801064cb:	e8 f2 ba ff ff       	call   80101fc2 <kfree>
}
801064d0:	83 c4 10             	add    $0x10,%esp
801064d3:	8d 65 f8             	lea    -0x8(%ebp),%esp
801064d6:	5b                   	pop    %ebx
801064d7:	5e                   	pop    %esi
801064d8:	5d                   	pop    %ebp
801064d9:	c3                   	ret    

801064da <setupkvm>:
{
801064da:	55                   	push   %ebp
801064db:	89 e5                	mov    %esp,%ebp
801064dd:	56                   	push   %esi
801064de:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc2()) == 0)
801064df:	e8 8c bd ff ff       	call   80102270 <kalloc2>
801064e4:	89 c6                	mov    %eax,%esi
801064e6:	85 c0                	test   %eax,%eax
801064e8:	74 55                	je     8010653f <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
801064ea:	83 ec 04             	sub    $0x4,%esp
801064ed:	68 00 10 00 00       	push   $0x1000
801064f2:	6a 00                	push   $0x0
801064f4:	50                   	push   %eax
801064f5:	e8 cd d9 ff ff       	call   80103ec7 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801064fa:	83 c4 10             	add    $0x10,%esp
801064fd:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
80106502:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
80106508:	73 35                	jae    8010653f <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
8010650a:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
8010650d:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106510:	29 c1                	sub    %eax,%ecx
80106512:	83 ec 08             	sub    $0x8,%esp
80106515:	ff 73 0c             	pushl  0xc(%ebx)
80106518:	50                   	push   %eax
80106519:	8b 13                	mov    (%ebx),%edx
8010651b:	89 f0                	mov    %esi,%eax
8010651d:	e8 be f9 ff ff       	call   80105ee0 <mappages>
80106522:	83 c4 10             	add    $0x10,%esp
80106525:	85 c0                	test   %eax,%eax
80106527:	78 05                	js     8010652e <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106529:	83 c3 10             	add    $0x10,%ebx
8010652c:	eb d4                	jmp    80106502 <setupkvm+0x28>
      freevm(pgdir);
8010652e:	83 ec 0c             	sub    $0xc,%esp
80106531:	56                   	push   %esi
80106532:	e8 33 ff ff ff       	call   8010646a <freevm>
      return 0;
80106537:	83 c4 10             	add    $0x10,%esp
8010653a:	be 00 00 00 00       	mov    $0x0,%esi
}
8010653f:	89 f0                	mov    %esi,%eax
80106541:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106544:	5b                   	pop    %ebx
80106545:	5e                   	pop    %esi
80106546:	5d                   	pop    %ebp
80106547:	c3                   	ret    

80106548 <kvmalloc>:
{
80106548:	55                   	push   %ebp
80106549:	89 e5                	mov    %esp,%ebp
8010654b:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
8010654e:	e8 87 ff ff ff       	call   801064da <setupkvm>
80106553:	a3 c4 54 13 80       	mov    %eax,0x801354c4
  switchkvm();
80106558:	e8 45 fb ff ff       	call   801060a2 <switchkvm>
}
8010655d:	c9                   	leave  
8010655e:	c3                   	ret    

8010655f <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010655f:	55                   	push   %ebp
80106560:	89 e5                	mov    %esp,%ebp
80106562:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106565:	b9 00 00 00 00       	mov    $0x0,%ecx
8010656a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010656d:	8b 45 08             	mov    0x8(%ebp),%eax
80106570:	e8 fb f8 ff ff       	call   80105e70 <walkpgdir>
  if(pte == 0)
80106575:	85 c0                	test   %eax,%eax
80106577:	74 05                	je     8010657e <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
80106579:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
8010657c:	c9                   	leave  
8010657d:	c3                   	ret    
    panic("clearpteu");
8010657e:	83 ec 0c             	sub    $0xc,%esp
80106581:	68 ce 70 10 80       	push   $0x801070ce
80106586:	e8 bd 9d ff ff       	call   80100348 <panic>

8010658b <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010658b:	55                   	push   %ebp
8010658c:	89 e5                	mov    %esp,%ebp
8010658e:	57                   	push   %edi
8010658f:	56                   	push   %esi
80106590:	53                   	push   %ebx
80106591:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80106594:	e8 41 ff ff ff       	call   801064da <setupkvm>
80106599:	89 45 dc             	mov    %eax,-0x24(%ebp)
8010659c:	85 c0                	test   %eax,%eax
8010659e:	0f 84 d2 00 00 00    	je     80106676 <copyuvm+0xeb>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801065a4:	bf 00 00 00 00       	mov    $0x0,%edi
801065a9:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801065ac:	0f 83 c4 00 00 00    	jae    80106676 <copyuvm+0xeb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801065b2:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801065b5:	b9 00 00 00 00       	mov    $0x0,%ecx
801065ba:	89 fa                	mov    %edi,%edx
801065bc:	8b 45 08             	mov    0x8(%ebp),%eax
801065bf:	e8 ac f8 ff ff       	call   80105e70 <walkpgdir>
801065c4:	85 c0                	test   %eax,%eax
801065c6:	74 73                	je     8010663b <copyuvm+0xb0>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
801065c8:	8b 00                	mov    (%eax),%eax
801065ca:	a8 01                	test   $0x1,%al
801065cc:	74 7a                	je     80106648 <copyuvm+0xbd>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
801065ce:	89 c6                	mov    %eax,%esi
801065d0:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
801065d6:	25 ff 0f 00 00       	and    $0xfff,%eax
801065db:	89 45 e0             	mov    %eax,-0x20(%ebp)
    // manipulate this call to kalloc. Need to pass the pid?
    int pid = myproc()->pid;
801065de:	e8 27 ce ff ff       	call   8010340a <myproc>

    if((mem = kalloc(pid)) == 0)
801065e3:	83 ec 0c             	sub    $0xc,%esp
801065e6:	ff 70 10             	pushl  0x10(%eax)
801065e9:	e8 e9 bb ff ff       	call   801021d7 <kalloc>
801065ee:	89 c3                	mov    %eax,%ebx
801065f0:	83 c4 10             	add    $0x10,%esp
801065f3:	85 c0                	test   %eax,%eax
801065f5:	74 6a                	je     80106661 <copyuvm+0xd6>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801065f7:	81 c6 00 00 00 80    	add    $0x80000000,%esi
801065fd:	83 ec 04             	sub    $0x4,%esp
80106600:	68 00 10 00 00       	push   $0x1000
80106605:	56                   	push   %esi
80106606:	50                   	push   %eax
80106607:	e8 36 d9 ff ff       	call   80103f42 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
8010660c:	83 c4 08             	add    $0x8,%esp
8010660f:	ff 75 e0             	pushl  -0x20(%ebp)
80106612:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106618:	50                   	push   %eax
80106619:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010661e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106621:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106624:	e8 b7 f8 ff ff       	call   80105ee0 <mappages>
80106629:	83 c4 10             	add    $0x10,%esp
8010662c:	85 c0                	test   %eax,%eax
8010662e:	78 25                	js     80106655 <copyuvm+0xca>
  for(i = 0; i < sz; i += PGSIZE){
80106630:	81 c7 00 10 00 00    	add    $0x1000,%edi
80106636:	e9 6e ff ff ff       	jmp    801065a9 <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
8010663b:	83 ec 0c             	sub    $0xc,%esp
8010663e:	68 d8 70 10 80       	push   $0x801070d8
80106643:	e8 00 9d ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
80106648:	83 ec 0c             	sub    $0xc,%esp
8010664b:	68 f2 70 10 80       	push   $0x801070f2
80106650:	e8 f3 9c ff ff       	call   80100348 <panic>
      kfree(mem);
80106655:	83 ec 0c             	sub    $0xc,%esp
80106658:	53                   	push   %ebx
80106659:	e8 64 b9 ff ff       	call   80101fc2 <kfree>
      goto bad;
8010665e:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106661:	83 ec 0c             	sub    $0xc,%esp
80106664:	ff 75 dc             	pushl  -0x24(%ebp)
80106667:	e8 fe fd ff ff       	call   8010646a <freevm>
  return 0;
8010666c:	83 c4 10             	add    $0x10,%esp
8010666f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
80106676:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106679:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010667c:	5b                   	pop    %ebx
8010667d:	5e                   	pop    %esi
8010667e:	5f                   	pop    %edi
8010667f:	5d                   	pop    %ebp
80106680:	c3                   	ret    

80106681 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106681:	55                   	push   %ebp
80106682:	89 e5                	mov    %esp,%ebp
80106684:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106687:	b9 00 00 00 00       	mov    $0x0,%ecx
8010668c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010668f:	8b 45 08             	mov    0x8(%ebp),%eax
80106692:	e8 d9 f7 ff ff       	call   80105e70 <walkpgdir>
  if((*pte & PTE_P) == 0)
80106697:	8b 00                	mov    (%eax),%eax
80106699:	a8 01                	test   $0x1,%al
8010669b:	74 10                	je     801066ad <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
8010669d:	a8 04                	test   $0x4,%al
8010669f:	74 13                	je     801066b4 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
801066a1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801066a6:	05 00 00 00 80       	add    $0x80000000,%eax
}
801066ab:	c9                   	leave  
801066ac:	c3                   	ret    
    return 0;
801066ad:	b8 00 00 00 00       	mov    $0x0,%eax
801066b2:	eb f7                	jmp    801066ab <uva2ka+0x2a>
    return 0;
801066b4:	b8 00 00 00 00       	mov    $0x0,%eax
801066b9:	eb f0                	jmp    801066ab <uva2ka+0x2a>

801066bb <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801066bb:	55                   	push   %ebp
801066bc:	89 e5                	mov    %esp,%ebp
801066be:	57                   	push   %edi
801066bf:	56                   	push   %esi
801066c0:	53                   	push   %ebx
801066c1:	83 ec 0c             	sub    $0xc,%esp
801066c4:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801066c7:	eb 25                	jmp    801066ee <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801066c9:	8b 55 0c             	mov    0xc(%ebp),%edx
801066cc:	29 f2                	sub    %esi,%edx
801066ce:	01 d0                	add    %edx,%eax
801066d0:	83 ec 04             	sub    $0x4,%esp
801066d3:	53                   	push   %ebx
801066d4:	ff 75 10             	pushl  0x10(%ebp)
801066d7:	50                   	push   %eax
801066d8:	e8 65 d8 ff ff       	call   80103f42 <memmove>
    len -= n;
801066dd:	29 df                	sub    %ebx,%edi
    buf += n;
801066df:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801066e2:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801066e8:	89 45 0c             	mov    %eax,0xc(%ebp)
801066eb:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
801066ee:	85 ff                	test   %edi,%edi
801066f0:	74 2f                	je     80106721 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
801066f2:	8b 75 0c             	mov    0xc(%ebp),%esi
801066f5:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
801066fb:	83 ec 08             	sub    $0x8,%esp
801066fe:	56                   	push   %esi
801066ff:	ff 75 08             	pushl  0x8(%ebp)
80106702:	e8 7a ff ff ff       	call   80106681 <uva2ka>
    if(pa0 == 0)
80106707:	83 c4 10             	add    $0x10,%esp
8010670a:	85 c0                	test   %eax,%eax
8010670c:	74 20                	je     8010672e <copyout+0x73>
    n = PGSIZE - (va - va0);
8010670e:	89 f3                	mov    %esi,%ebx
80106710:	2b 5d 0c             	sub    0xc(%ebp),%ebx
80106713:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
80106719:	39 df                	cmp    %ebx,%edi
8010671b:	73 ac                	jae    801066c9 <copyout+0xe>
      n = len;
8010671d:	89 fb                	mov    %edi,%ebx
8010671f:	eb a8                	jmp    801066c9 <copyout+0xe>
  }
  return 0;
80106721:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106726:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106729:	5b                   	pop    %ebx
8010672a:	5e                   	pop    %esi
8010672b:	5f                   	pop    %edi
8010672c:	5d                   	pop    %ebp
8010672d:	c3                   	ret    
      return -1;
8010672e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106733:	eb f1                	jmp    80106726 <copyout+0x6b>
