
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
8010002d:	b8 bf 2b 10 80       	mov    $0x80102bbf,%eax
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
80100046:	e8 11 3d 00 00       	call   80103d5c <acquire>

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
8010007c:	e8 40 3d 00 00       	call   80103dc1 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 bc 3a 00 00       	call   80103b48 <acquiresleep>
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
801000ca:	e8 f2 3c 00 00       	call   80103dc1 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 6e 3a 00 00       	call   80103b48 <acquiresleep>
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
801000ea:	68 60 66 10 80       	push   $0x80106660
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 71 66 10 80       	push   $0x80106671
80100100:	68 c0 b5 10 80       	push   $0x8010b5c0
80100105:	e8 16 3b 00 00       	call   80103c20 <initlock>
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
8010013a:	68 78 66 10 80       	push   $0x80106678
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 cd 39 00 00       	call   80103b15 <initsleeplock>
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
801001a8:	e8 25 3a 00 00       	call   80103bd2 <holdingsleep>
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
801001cb:	68 7f 66 10 80       	push   $0x8010667f
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
801001e4:	e8 e9 39 00 00       	call   80103bd2 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 9e 39 00 00       	call   80103b97 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100200:	e8 57 3b 00 00       	call   80103d5c <acquire>
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
8010024c:	e8 70 3b 00 00       	call   80103dc1 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 86 66 10 80       	push   $0x80106686
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
8010028a:	e8 cd 3a 00 00       	call   80103d5c <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 a0 ff 10 80       	mov    0x8010ffa0,%eax
8010029f:	3b 05 a4 ff 10 80    	cmp    0x8010ffa4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 a5 30 00 00       	call   80103351 <myproc>
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
801002bf:	e8 31 35 00 00       	call   801037f5 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 10 80       	push   $0x8010a520
801002d1:	e8 eb 3a 00 00       	call   80103dc1 <release>
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
80100331:	e8 8b 3a 00 00       	call   80103dc1 <release>
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
8010035a:	e8 7a 21 00 00       	call   801024d9 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 8d 66 10 80       	push   $0x8010668d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 db 6f 10 80 	movl   $0x80106fdb,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 a7 38 00 00       	call   80103c3b <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 a1 66 10 80       	push   $0x801066a1
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
8010049e:	68 a5 66 10 80       	push   $0x801066a5
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 c4 39 00 00       	call   80103e83 <memmove>
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
801004d9:	e8 2a 39 00 00       	call   80103e08 <memset>
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
80100506:	e8 37 4d 00 00       	call   80105242 <uartputc>
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
8010051f:	e8 1e 4d 00 00       	call   80105242 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 12 4d 00 00       	call   80105242 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 06 4d 00 00       	call   80105242 <uartputc>
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
80100576:	0f b6 92 d0 66 10 80 	movzbl -0x7fef9930(%edx),%edx
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
801005ca:	e8 8d 37 00 00       	call   80103d5c <acquire>
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
801005f1:	e8 cb 37 00 00       	call   80103dc1 <release>
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
80100638:	e8 1f 37 00 00       	call   80103d5c <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 bf 66 10 80       	push   $0x801066bf
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
801006ee:	be b8 66 10 80       	mov    $0x801066b8,%esi
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
80100734:	e8 88 36 00 00       	call   80103dc1 <release>
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
8010074f:	e8 08 36 00 00       	call   80103d5c <acquire>
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
801007de:	e8 77 31 00 00       	call   8010395a <wakeup>
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
80100873:	e8 49 35 00 00       	call   80103dc1 <release>
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
80100887:	e8 6b 31 00 00       	call   801039f7 <procdump>
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
80100894:	68 c8 66 10 80       	push   $0x801066c8
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 7d 33 00 00       	call   80103c20 <initlock>

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
801008de:	e8 6e 2a 00 00       	call   80103351 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 1b 20 00 00       	call   80102909 <begin_op>

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
80100935:	e8 49 20 00 00       	call   80102983 <end_op>
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
8010094a:	e8 34 20 00 00       	call   80102983 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 e1 66 10 80       	push   $0x801066e1
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
80100972:	e8 8b 5a 00 00       	call   80106402 <setupkvm>
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
80100a06:	e8 9d 58 00 00       	call   801062a8 <allocuvm>
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
80100a38:	e8 39 57 00 00       	call   80106176 <loaduvm>
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
80100a53:	e8 2b 1f 00 00       	call   80102983 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 2f 58 00 00       	call   801062a8 <allocuvm>
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
80100a9d:	e8 f0 58 00 00       	call   80106392 <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 c6 59 00 00       	call   80106487 <clearpteu>
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
80100ae2:	e8 c3 34 00 00       	call   80103faa <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 b1 34 00 00       	call   80103faa <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 ca 5a 00 00       	call   801065d5 <copyout>
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
80100b66:	e8 6a 5a 00 00       	call   801065d5 <copyout>
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
80100ba3:	e8 c7 33 00 00       	call   80103f6f <safestrcpy>
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
80100bd1:	e8 1f 54 00 00       	call   80105ff5 <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 b4 57 00 00       	call   80106392 <freevm>
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
80100c19:	68 ed 66 10 80       	push   $0x801066ed
80100c1e:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c23:	e8 f8 2f 00 00       	call   80103c20 <initlock>
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
80100c39:	e8 1e 31 00 00       	call   80103d5c <acquire>
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
80100c68:	e8 54 31 00 00       	call   80103dc1 <release>
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
80100c7f:	e8 3d 31 00 00       	call   80103dc1 <release>
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
80100c9d:	e8 ba 30 00 00       	call   80103d5c <acquire>
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
80100cba:	e8 02 31 00 00       	call   80103dc1 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 f4 66 10 80       	push   $0x801066f4
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
80100ce2:	e8 75 30 00 00       	call   80103d5c <acquire>
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
80100d03:	e8 b9 30 00 00       	call   80103dc1 <release>
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
80100d13:	68 fc 66 10 80       	push   $0x801066fc
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
80100d49:	e8 73 30 00 00       	call   80103dc1 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 a6 1b 00 00       	call   80102909 <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 10 1c 00 00       	call   80102983 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 f5 21 00 00       	call   80102f7d <pipeclose>
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
80100e3c:	e8 94 22 00 00       	call   801030d5 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 06 67 10 80       	push   $0x80106706
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
80100e95:	e8 6f 21 00 00       	call   80103009 <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 62 1a 00 00       	call   80102909 <begin_op>
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
80100edd:	e8 a1 1a 00 00       	call   80102983 <end_op>

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
80100f10:	68 0f 67 10 80       	push   $0x8010670f
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
80100f2d:	68 15 67 10 80       	push   $0x80106715
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
80100f8a:	e8 f4 2e 00 00       	call   80103e83 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 e4 2e 00 00       	call   80103e83 <memmove>
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
80100fdf:	e8 24 2e 00 00       	call   80103e08 <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 46 1a 00 00       	call   80102a32 <log_write>
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
801010a3:	68 1f 67 10 80       	push   $0x8010671f
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
801010bf:	e8 6e 19 00 00       	call   80102a32 <log_write>
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
80101170:	e8 bd 18 00 00       	call   80102a32 <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 35 67 10 80       	push   $0x80106735
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
8010119a:	e8 bd 2b 00 00       	call   80103d5c <acquire>
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
801011e1:	e8 db 2b 00 00       	call   80103dc1 <release>
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
80101217:	e8 a5 2b 00 00       	call   80103dc1 <release>
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
8010122c:	68 48 67 10 80       	push   $0x80106748
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
80101255:	e8 29 2c 00 00       	call   80103e83 <memmove>
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
801012c8:	e8 65 17 00 00       	call   80102a32 <log_write>
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
801012e2:	68 58 67 10 80       	push   $0x80106758
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 6b 67 10 80       	push   $0x8010676b
801012f8:	68 e0 09 11 80       	push   $0x801109e0
801012fd:	e8 1e 29 00 00       	call   80103c20 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 72 67 10 80       	push   $0x80106772
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 20 0a 11 80       	add    $0x80110a20,%eax
80101321:	50                   	push   %eax
80101322:	e8 ee 27 00 00       	call   80103b15 <initsleeplock>
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
8010136c:	68 d8 67 10 80       	push   $0x801067d8
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
801013df:	68 78 67 10 80       	push   $0x80106778
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 12 2a 00 00       	call   80103e08 <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 2d 16 00 00       	call   80102a32 <log_write>
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
80101480:	e8 fe 29 00 00       	call   80103e83 <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 a5 15 00 00       	call   80102a32 <log_write>
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
80101560:	e8 f7 27 00 00       	call   80103d5c <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
80101575:	e8 47 28 00 00       	call   80103dc1 <release>
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
8010159a:	e8 a9 25 00 00       	call   80103b48 <acquiresleep>
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
801015b2:	68 8a 67 10 80       	push   $0x8010678a
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
80101614:	e8 6a 28 00 00       	call   80103e83 <memmove>
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
80101639:	68 90 67 10 80       	push   $0x80106790
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
80101656:	e8 77 25 00 00       	call   80103bd2 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 26 25 00 00       	call   80103b97 <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 9f 67 10 80       	push   $0x8010679f
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
80101698:	e8 ab 24 00 00       	call   80103b48 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 e1 24 00 00       	call   80103b97 <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016bd:	e8 9a 26 00 00       	call   80103d5c <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016d2:	e8 ea 26 00 00       	call   80103dc1 <release>
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
801016ea:	e8 6d 26 00 00       	call   80103d5c <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016f9:	e8 c3 26 00 00       	call   80103dc1 <release>
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
8010182a:	e8 54 26 00 00       	call   80103e83 <memmove>
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
80101926:	e8 58 25 00 00       	call   80103e83 <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 ff 10 00 00       	call   80102a32 <log_write>
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
801019a9:	e8 3c 25 00 00       	call   80103eea <strncmp>
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
801019d0:	68 a7 67 10 80       	push   $0x801067a7
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 b9 67 10 80       	push   $0x801067b9
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
80101a5a:	e8 f2 18 00 00       	call   80103351 <myproc>
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
80101b92:	68 c8 67 10 80       	push   $0x801067c8
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 79 23 00 00       	call   80103f27 <strncpy>
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
80101bd7:	68 d4 6d 10 80       	push   $0x80106dd4
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
80101ccc:	68 2b 68 10 80       	push   $0x8010682b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 34 68 10 80       	push   $0x80106834
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
80101d06:	68 46 68 10 80       	push   $0x80106846
80101d0b:	68 80 a5 10 80       	push   $0x8010a580
80101d10:	e8 0b 1f 00 00       	call   80103c20 <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d15:	83 c4 08             	add    $0x8,%esp
80101d18:	a1 20 2d 12 80       	mov    0x80122d20,%eax
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
80101d80:	e8 d7 1f 00 00       	call   80103d5c <acquire>

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
80101dad:	e8 a8 1b 00 00       	call   8010395a <wakeup>

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
80101dcb:	e8 f1 1f 00 00       	call   80103dc1 <release>
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
80101de2:	e8 da 1f 00 00       	call   80103dc1 <release>
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
80101e1a:	e8 b3 1d 00 00       	call   80103bd2 <holdingsleep>
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
80101e47:	e8 10 1f 00 00       	call   80103d5c <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 4a 68 10 80       	push   $0x8010684a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 60 68 10 80       	push   $0x80106860
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 75 68 10 80       	push   $0x80106875
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
80101ea9:	e8 47 19 00 00       	call   801037f5 <sleep>
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
80101ec3:	e8 f9 1e 00 00       	call   80103dc1 <release>
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
80101f2a:	0f b6 15 80 27 12 80 	movzbl 0x80122780,%edx
80101f31:	39 c2                	cmp    %eax,%edx
80101f33:	75 07                	jne    80101f3c <ioapicinit+0x42>
{
80101f35:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f3a:	eb 36                	jmp    80101f72 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f3c:	83 ec 0c             	sub    $0xc,%esp
80101f3f:	68 94 68 10 80       	push   $0x80106894
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
//int pidsList[16384];
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
80101fb1:	a1 80 26 12 80       	mov    0x80122680,%eax
80101fb6:	5d                   	pop    %ebp
80101fb7:	c3                   	ret    

80101fb8 <kfree>:
// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(char *v)
{
80101fb8:	55                   	push   %ebp
80101fb9:	89 e5                	mov    %esp,%ebp
80101fbb:	53                   	push   %ebx
80101fbc:	83 ec 04             	sub    $0x4,%esp
80101fbf:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if ((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80101fc2:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80101fc8:	75 4c                	jne    80102016 <kfree+0x5e>
80101fca:	81 fb c8 54 12 80    	cmp    $0x801254c8,%ebx
80101fd0:	72 44                	jb     80102016 <kfree+0x5e>
80101fd2:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80101fd8:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80101fdd:	77 37                	ja     80102016 <kfree+0x5e>
    panic("kfree");

  // cprintf("freeing: %x\n", V2P(v)>>12);

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fdf:	83 ec 04             	sub    $0x4,%esp
80101fe2:	68 00 10 00 00       	push   $0x1000
80101fe7:	6a 01                	push   $0x1
80101fe9:	53                   	push   %ebx
80101fea:	e8 19 1e 00 00       	call   80103e08 <memset>

  if (kmem.use_lock)
80101fef:	83 c4 10             	add    $0x10,%esp
80101ff2:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80101ff9:	75 28                	jne    80102023 <kfree+0x6b>
    acquire(&kmem.lock);
  r = (struct run *)v;
  r->next = kmem.freelist;
80101ffb:	a1 78 26 11 80       	mov    0x80112678,%eax
80102000:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
80102002:	89 1d 78 26 11 80    	mov    %ebx,0x80112678
  if (kmem.use_lock)
80102008:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
8010200f:	75 24                	jne    80102035 <kfree+0x7d>
    release(&kmem.lock);
}
80102011:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102014:	c9                   	leave  
80102015:	c3                   	ret    
    panic("kfree");
80102016:	83 ec 0c             	sub    $0xc,%esp
80102019:	68 c6 68 10 80       	push   $0x801068c6
8010201e:	e8 25 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
80102023:	83 ec 0c             	sub    $0xc,%esp
80102026:	68 40 26 11 80       	push   $0x80112640
8010202b:	e8 2c 1d 00 00       	call   80103d5c <acquire>
80102030:	83 c4 10             	add    $0x10,%esp
80102033:	eb c6                	jmp    80101ffb <kfree+0x43>
    release(&kmem.lock);
80102035:	83 ec 0c             	sub    $0xc,%esp
80102038:	68 40 26 11 80       	push   $0x80112640
8010203d:	e8 7f 1d 00 00       	call   80103dc1 <release>
80102042:	83 c4 10             	add    $0x10,%esp
}
80102045:	eb ca                	jmp    80102011 <kfree+0x59>

80102047 <kfree2>:
void kfree2(char *v)
{
80102047:	55                   	push   %ebp
80102048:	89 e5                	mov    %esp,%ebp
8010204a:	53                   	push   %ebx
8010204b:	83 ec 04             	sub    $0x4,%esp
8010204e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if ((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80102051:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80102057:	75 4c                	jne    801020a5 <kfree2+0x5e>
80102059:	81 fb c8 54 12 80    	cmp    $0x801254c8,%ebx
8010205f:	72 44                	jb     801020a5 <kfree2+0x5e>
80102061:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102067:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
8010206c:	77 37                	ja     801020a5 <kfree2+0x5e>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
8010206e:	83 ec 04             	sub    $0x4,%esp
80102071:	68 00 10 00 00       	push   $0x1000
80102076:	6a 01                	push   $0x1
80102078:	53                   	push   %ebx
80102079:	e8 8a 1d 00 00       	call   80103e08 <memset>

  if (kmem.use_lock)
8010207e:	83 c4 10             	add    $0x10,%esp
80102081:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80102088:	75 28                	jne    801020b2 <kfree2+0x6b>
    acquire(&kmem.lock);
  r = (struct run *)v;
  r->next = kmem.freelist;
8010208a:	a1 78 26 11 80       	mov    0x80112678,%eax
8010208f:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
80102091:	89 1d 78 26 11 80    	mov    %ebx,0x80112678
  if (kmem.use_lock)
80102097:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
8010209e:	75 24                	jne    801020c4 <kfree2+0x7d>
    release(&kmem.lock);
}
801020a0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801020a3:	c9                   	leave  
801020a4:	c3                   	ret    
    panic("kfree");
801020a5:	83 ec 0c             	sub    $0xc,%esp
801020a8:	68 c6 68 10 80       	push   $0x801068c6
801020ad:	e8 96 e2 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
801020b2:	83 ec 0c             	sub    $0xc,%esp
801020b5:	68 40 26 11 80       	push   $0x80112640
801020ba:	e8 9d 1c 00 00       	call   80103d5c <acquire>
801020bf:	83 c4 10             	add    $0x10,%esp
801020c2:	eb c6                	jmp    8010208a <kfree2+0x43>
    release(&kmem.lock);
801020c4:	83 ec 0c             	sub    $0xc,%esp
801020c7:	68 40 26 11 80       	push   $0x80112640
801020cc:	e8 f0 1c 00 00       	call   80103dc1 <release>
801020d1:	83 c4 10             	add    $0x10,%esp
}
801020d4:	eb ca                	jmp    801020a0 <kfree2+0x59>

801020d6 <freerange>:
{
801020d6:	55                   	push   %ebp
801020d7:	89 e5                	mov    %esp,%ebp
801020d9:	57                   	push   %edi
801020da:	56                   	push   %esi
801020db:	53                   	push   %ebx
801020dc:	83 ec 0c             	sub    $0xc,%esp
801020df:	8b 7d 0c             	mov    0xc(%ebp),%edi
  p = (char *)PGROUNDUP((uint)vstart);
801020e2:	8b 45 08             	mov    0x8(%ebp),%eax
801020e5:	05 ff 0f 00 00       	add    $0xfff,%eax
801020ea:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  int i = 0;
801020ef:	be 00 00 00 00       	mov    $0x0,%esi
  for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
801020f4:	eb 02                	jmp    801020f8 <freerange+0x22>
{
801020f6:	89 d8                	mov    %ebx,%eax
  for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
801020f8:	8d 98 00 10 00 00    	lea    0x1000(%eax),%ebx
801020fe:	39 fb                	cmp    %edi,%ebx
80102100:	77 19                	ja     8010211b <freerange+0x45>
    if ((i + 1) % 2 == 0)
80102102:	83 c6 01             	add    $0x1,%esi
80102105:	f7 c6 01 00 00 00    	test   $0x1,%esi
8010210b:	75 e9                	jne    801020f6 <freerange+0x20>
      kfree2(p);
8010210d:	83 ec 0c             	sub    $0xc,%esp
80102110:	50                   	push   %eax
80102111:	e8 31 ff ff ff       	call   80102047 <kfree2>
80102116:	83 c4 10             	add    $0x10,%esp
80102119:	eb db                	jmp    801020f6 <freerange+0x20>
}
8010211b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010211e:	5b                   	pop    %ebx
8010211f:	5e                   	pop    %esi
80102120:	5f                   	pop    %edi
80102121:	5d                   	pop    %ebp
80102122:	c3                   	ret    

80102123 <kinit1>:
{
80102123:	55                   	push   %ebp
80102124:	89 e5                	mov    %esp,%ebp
80102126:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
80102129:	68 cc 68 10 80       	push   $0x801068cc
8010212e:	68 40 26 11 80       	push   $0x80112640
80102133:	e8 e8 1a 00 00       	call   80103c20 <initlock>
  kmem.use_lock = 0;
80102138:	c7 05 74 26 11 80 00 	movl   $0x0,0x80112674
8010213f:	00 00 00 
  freerange(vstart, vend);
80102142:	83 c4 08             	add    $0x8,%esp
80102145:	ff 75 0c             	pushl  0xc(%ebp)
80102148:	ff 75 08             	pushl  0x8(%ebp)
8010214b:	e8 86 ff ff ff       	call   801020d6 <freerange>
}
80102150:	83 c4 10             	add    $0x10,%esp
80102153:	c9                   	leave  
80102154:	c3                   	ret    

80102155 <kinit2>:
{
80102155:	55                   	push   %ebp
80102156:	89 e5                	mov    %esp,%ebp
80102158:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
8010215b:	ff 75 0c             	pushl  0xc(%ebp)
8010215e:	ff 75 08             	pushl  0x8(%ebp)
80102161:	e8 70 ff ff ff       	call   801020d6 <freerange>
  kmem.use_lock = 1;
80102166:	c7 05 74 26 11 80 01 	movl   $0x1,0x80112674
8010216d:	00 00 00 
}
80102170:	83 c4 10             	add    $0x10,%esp
80102173:	c9                   	leave  
80102174:	c3                   	ret    

80102175 <kalloc>:
// Returns 0 if the memory cannot be allocated.
// From spec - kalloc manages freelist and allocates physical memory
// returns first page on the freelist
char *
kalloc(void)
{
80102175:	55                   	push   %ebp
80102176:	89 e5                	mov    %esp,%ebp
80102178:	53                   	push   %ebx
80102179:	83 ec 04             	sub    $0x4,%esp
  struct run *r;
  if (kmem.use_lock)
8010217c:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80102183:	75 47                	jne    801021cc <kalloc+0x57>
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;
80102185:	8b 1d 78 26 11 80    	mov    0x80112678,%ebx

  // we need to get the PA to retrieve the frame number
  if (r)
8010218b:	85 db                	test   %ebx,%ebx
8010218d:	74 2d                	je     801021bc <kalloc+0x47>
  {
     int frameNumber = V2P(r) >> 12;
8010218f:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102195:	c1 e8 0c             	shr    $0xc,%eax
    if(frameNumber > 1023){
80102198:	3d ff 03 00 00       	cmp    $0x3ff,%eax
8010219d:	7e 16                	jle    801021b5 <kalloc+0x40>
      //pidList[frame] = myproc()->pid;
      framesList[frame++] = frameNumber;
8010219f:	8b 15 80 26 12 80    	mov    0x80122680,%edx
801021a5:	8d 4a 01             	lea    0x1(%edx),%ecx
801021a8:	89 0d 80 26 12 80    	mov    %ecx,0x80122680
801021ae:	89 04 95 80 26 11 80 	mov    %eax,-0x7feed980(,%edx,4)
    }   
    kmem.freelist = r->next;
801021b5:	8b 03                	mov    (%ebx),%eax
801021b7:	a3 78 26 11 80       	mov    %eax,0x80112678
    
  }
  if (kmem.use_lock)
801021bc:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801021c3:	75 19                	jne    801021de <kalloc+0x69>
  {
    release(&kmem.lock);
  }
  return (char *)r;
}
801021c5:	89 d8                	mov    %ebx,%eax
801021c7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801021ca:	c9                   	leave  
801021cb:	c3                   	ret    
    acquire(&kmem.lock);
801021cc:	83 ec 0c             	sub    $0xc,%esp
801021cf:	68 40 26 11 80       	push   $0x80112640
801021d4:	e8 83 1b 00 00       	call   80103d5c <acquire>
801021d9:	83 c4 10             	add    $0x10,%esp
801021dc:	eb a7                	jmp    80102185 <kalloc+0x10>
    release(&kmem.lock);
801021de:	83 ec 0c             	sub    $0xc,%esp
801021e1:	68 40 26 11 80       	push   $0x80112640
801021e6:	e8 d6 1b 00 00       	call   80103dc1 <release>
801021eb:	83 c4 10             	add    $0x10,%esp
  return (char *)r;
801021ee:	eb d5                	jmp    801021c5 <kalloc+0x50>

801021f0 <kalloc2>:

// called by the excluded methods (inituvm, setupkvm, walkpgdir). We need to
// "mark these pages as belonging to an unknown process". (-2)
char *
kalloc2(void)
{
801021f0:	55                   	push   %ebp
801021f1:	89 e5                	mov    %esp,%ebp
801021f3:	53                   	push   %ebx
801021f4:	83 ec 04             	sub    $0x4,%esp
  struct run *r;
  if (kmem.use_lock)
801021f7:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801021fe:	75 47                	jne    80102247 <kalloc2+0x57>
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;
80102200:	8b 1d 78 26 11 80    	mov    0x80112678,%ebx

  // we need to get the PA to retrieve the frame number
  if (r)
80102206:	85 db                	test   %ebx,%ebx
80102208:	74 2d                	je     80102237 <kalloc2+0x47>
  {
    int frameNumber = V2P(r) >> 12; 
8010220a:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102210:	c1 e8 0c             	shr    $0xc,%eax
    if(frameNumber > 1023){
80102213:	3d ff 03 00 00       	cmp    $0x3ff,%eax
80102218:	7e 16                	jle    80102230 <kalloc2+0x40>
      //pidList[frame] = myproc()->pid
      framesList[frame++] = frameNumber;
8010221a:	8b 15 80 26 12 80    	mov    0x80122680,%edx
80102220:	8d 4a 01             	lea    0x1(%edx),%ecx
80102223:	89 0d 80 26 12 80    	mov    %ecx,0x80122680
80102229:	89 04 95 80 26 11 80 	mov    %eax,-0x7feed980(,%edx,4)
    }    
    kmem.freelist = r->next;
80102230:	8b 03                	mov    (%ebx),%eax
80102232:	a3 78 26 11 80       	mov    %eax,0x80112678
  }
  if (kmem.use_lock)
80102237:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
8010223e:	75 19                	jne    80102259 <kalloc2+0x69>
  {
    release(&kmem.lock);
  }
  return (char *)r;
80102240:	89 d8                	mov    %ebx,%eax
80102242:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102245:	c9                   	leave  
80102246:	c3                   	ret    
    acquire(&kmem.lock);
80102247:	83 ec 0c             	sub    $0xc,%esp
8010224a:	68 40 26 11 80       	push   $0x80112640
8010224f:	e8 08 1b 00 00       	call   80103d5c <acquire>
80102254:	83 c4 10             	add    $0x10,%esp
80102257:	eb a7                	jmp    80102200 <kalloc2+0x10>
    release(&kmem.lock);
80102259:	83 ec 0c             	sub    $0xc,%esp
8010225c:	68 40 26 11 80       	push   $0x80112640
80102261:	e8 5b 1b 00 00       	call   80103dc1 <release>
80102266:	83 c4 10             	add    $0x10,%esp
  return (char *)r;
80102269:	eb d5                	jmp    80102240 <kalloc2+0x50>

8010226b <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
8010226b:	55                   	push   %ebp
8010226c:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010226e:	ba 64 00 00 00       	mov    $0x64,%edx
80102273:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
80102274:	a8 01                	test   $0x1,%al
80102276:	0f 84 b5 00 00 00    	je     80102331 <kbdgetc+0xc6>
8010227c:	ba 60 00 00 00       	mov    $0x60,%edx
80102281:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102282:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
80102285:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
8010228b:	74 5c                	je     801022e9 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
8010228d:	84 c0                	test   %al,%al
8010228f:	78 66                	js     801022f7 <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102291:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
80102297:	f6 c1 40             	test   $0x40,%cl
8010229a:	74 0f                	je     801022ab <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
8010229c:	83 c8 80             	or     $0xffffff80,%eax
8010229f:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
801022a2:	83 e1 bf             	and    $0xffffffbf,%ecx
801022a5:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  }

  shift |= shiftcode[data];
801022ab:	0f b6 8a 00 6a 10 80 	movzbl -0x7fef9600(%edx),%ecx
801022b2:	0b 0d b4 a5 10 80    	or     0x8010a5b4,%ecx
  shift ^= togglecode[data];
801022b8:	0f b6 82 00 69 10 80 	movzbl -0x7fef9700(%edx),%eax
801022bf:	31 c1                	xor    %eax,%ecx
801022c1:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  c = charcode[shift & (CTL | SHIFT)][data];
801022c7:	89 c8                	mov    %ecx,%eax
801022c9:	83 e0 03             	and    $0x3,%eax
801022cc:	8b 04 85 e0 68 10 80 	mov    -0x7fef9720(,%eax,4),%eax
801022d3:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
801022d7:	f6 c1 08             	test   $0x8,%cl
801022da:	74 19                	je     801022f5 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
801022dc:	8d 50 9f             	lea    -0x61(%eax),%edx
801022df:	83 fa 19             	cmp    $0x19,%edx
801022e2:	77 40                	ja     80102324 <kbdgetc+0xb9>
      c += 'A' - 'a';
801022e4:	83 e8 20             	sub    $0x20,%eax
801022e7:	eb 0c                	jmp    801022f5 <kbdgetc+0x8a>
    shift |= E0ESC;
801022e9:	83 0d b4 a5 10 80 40 	orl    $0x40,0x8010a5b4
    return 0;
801022f0:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
801022f5:	5d                   	pop    %ebp
801022f6:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
801022f7:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
801022fd:	f6 c1 40             	test   $0x40,%cl
80102300:	75 05                	jne    80102307 <kbdgetc+0x9c>
80102302:	89 c2                	mov    %eax,%edx
80102304:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
80102307:	0f b6 82 00 6a 10 80 	movzbl -0x7fef9600(%edx),%eax
8010230e:	83 c8 40             	or     $0x40,%eax
80102311:	0f b6 c0             	movzbl %al,%eax
80102314:	f7 d0                	not    %eax
80102316:	21 c8                	and    %ecx,%eax
80102318:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    return 0;
8010231d:	b8 00 00 00 00       	mov    $0x0,%eax
80102322:	eb d1                	jmp    801022f5 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
80102324:	8d 50 bf             	lea    -0x41(%eax),%edx
80102327:	83 fa 19             	cmp    $0x19,%edx
8010232a:	77 c9                	ja     801022f5 <kbdgetc+0x8a>
      c += 'a' - 'A';
8010232c:	83 c0 20             	add    $0x20,%eax
  return c;
8010232f:	eb c4                	jmp    801022f5 <kbdgetc+0x8a>
    return -1;
80102331:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102336:	eb bd                	jmp    801022f5 <kbdgetc+0x8a>

80102338 <kbdintr>:

void
kbdintr(void)
{
80102338:	55                   	push   %ebp
80102339:	89 e5                	mov    %esp,%ebp
8010233b:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
8010233e:	68 6b 22 10 80       	push   $0x8010226b
80102343:	e8 f6 e3 ff ff       	call   8010073e <consoleintr>
}
80102348:	83 c4 10             	add    $0x10,%esp
8010234b:	c9                   	leave  
8010234c:	c3                   	ret    

8010234d <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
8010234d:	55                   	push   %ebp
8010234e:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102350:	8b 0d 84 26 12 80    	mov    0x80122684,%ecx
80102356:	8d 04 81             	lea    (%ecx,%eax,4),%eax
80102359:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
8010235b:	a1 84 26 12 80       	mov    0x80122684,%eax
80102360:	8b 40 20             	mov    0x20(%eax),%eax
}
80102363:	5d                   	pop    %ebp
80102364:	c3                   	ret    

80102365 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
80102365:	55                   	push   %ebp
80102366:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102368:	ba 70 00 00 00       	mov    $0x70,%edx
8010236d:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010236e:	ba 71 00 00 00       	mov    $0x71,%edx
80102373:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
80102374:	0f b6 c0             	movzbl %al,%eax
}
80102377:	5d                   	pop    %ebp
80102378:	c3                   	ret    

80102379 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
80102379:	55                   	push   %ebp
8010237a:	89 e5                	mov    %esp,%ebp
8010237c:	53                   	push   %ebx
8010237d:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
8010237f:	b8 00 00 00 00       	mov    $0x0,%eax
80102384:	e8 dc ff ff ff       	call   80102365 <cmos_read>
80102389:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
8010238b:	b8 02 00 00 00       	mov    $0x2,%eax
80102390:	e8 d0 ff ff ff       	call   80102365 <cmos_read>
80102395:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
80102398:	b8 04 00 00 00       	mov    $0x4,%eax
8010239d:	e8 c3 ff ff ff       	call   80102365 <cmos_read>
801023a2:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
801023a5:	b8 07 00 00 00       	mov    $0x7,%eax
801023aa:	e8 b6 ff ff ff       	call   80102365 <cmos_read>
801023af:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
801023b2:	b8 08 00 00 00       	mov    $0x8,%eax
801023b7:	e8 a9 ff ff ff       	call   80102365 <cmos_read>
801023bc:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
801023bf:	b8 09 00 00 00       	mov    $0x9,%eax
801023c4:	e8 9c ff ff ff       	call   80102365 <cmos_read>
801023c9:	89 43 14             	mov    %eax,0x14(%ebx)
}
801023cc:	5b                   	pop    %ebx
801023cd:	5d                   	pop    %ebp
801023ce:	c3                   	ret    

801023cf <lapicinit>:
  if(!lapic)
801023cf:	83 3d 84 26 12 80 00 	cmpl   $0x0,0x80122684
801023d6:	0f 84 fb 00 00 00    	je     801024d7 <lapicinit+0x108>
{
801023dc:	55                   	push   %ebp
801023dd:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801023df:	ba 3f 01 00 00       	mov    $0x13f,%edx
801023e4:	b8 3c 00 00 00       	mov    $0x3c,%eax
801023e9:	e8 5f ff ff ff       	call   8010234d <lapicw>
  lapicw(TDCR, X1);
801023ee:	ba 0b 00 00 00       	mov    $0xb,%edx
801023f3:	b8 f8 00 00 00       	mov    $0xf8,%eax
801023f8:	e8 50 ff ff ff       	call   8010234d <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801023fd:	ba 20 00 02 00       	mov    $0x20020,%edx
80102402:	b8 c8 00 00 00       	mov    $0xc8,%eax
80102407:	e8 41 ff ff ff       	call   8010234d <lapicw>
  lapicw(TICR, 10000000);
8010240c:	ba 80 96 98 00       	mov    $0x989680,%edx
80102411:	b8 e0 00 00 00       	mov    $0xe0,%eax
80102416:	e8 32 ff ff ff       	call   8010234d <lapicw>
  lapicw(LINT0, MASKED);
8010241b:	ba 00 00 01 00       	mov    $0x10000,%edx
80102420:	b8 d4 00 00 00       	mov    $0xd4,%eax
80102425:	e8 23 ff ff ff       	call   8010234d <lapicw>
  lapicw(LINT1, MASKED);
8010242a:	ba 00 00 01 00       	mov    $0x10000,%edx
8010242f:	b8 d8 00 00 00       	mov    $0xd8,%eax
80102434:	e8 14 ff ff ff       	call   8010234d <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102439:	a1 84 26 12 80       	mov    0x80122684,%eax
8010243e:	8b 40 30             	mov    0x30(%eax),%eax
80102441:	c1 e8 10             	shr    $0x10,%eax
80102444:	3c 03                	cmp    $0x3,%al
80102446:	77 7b                	ja     801024c3 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102448:	ba 33 00 00 00       	mov    $0x33,%edx
8010244d:	b8 dc 00 00 00       	mov    $0xdc,%eax
80102452:	e8 f6 fe ff ff       	call   8010234d <lapicw>
  lapicw(ESR, 0);
80102457:	ba 00 00 00 00       	mov    $0x0,%edx
8010245c:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102461:	e8 e7 fe ff ff       	call   8010234d <lapicw>
  lapicw(ESR, 0);
80102466:	ba 00 00 00 00       	mov    $0x0,%edx
8010246b:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102470:	e8 d8 fe ff ff       	call   8010234d <lapicw>
  lapicw(EOI, 0);
80102475:	ba 00 00 00 00       	mov    $0x0,%edx
8010247a:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010247f:	e8 c9 fe ff ff       	call   8010234d <lapicw>
  lapicw(ICRHI, 0);
80102484:	ba 00 00 00 00       	mov    $0x0,%edx
80102489:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010248e:	e8 ba fe ff ff       	call   8010234d <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102493:	ba 00 85 08 00       	mov    $0x88500,%edx
80102498:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010249d:	e8 ab fe ff ff       	call   8010234d <lapicw>
  while(lapic[ICRLO] & DELIVS)
801024a2:	a1 84 26 12 80       	mov    0x80122684,%eax
801024a7:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
801024ad:	f6 c4 10             	test   $0x10,%ah
801024b0:	75 f0                	jne    801024a2 <lapicinit+0xd3>
  lapicw(TPR, 0);
801024b2:	ba 00 00 00 00       	mov    $0x0,%edx
801024b7:	b8 20 00 00 00       	mov    $0x20,%eax
801024bc:	e8 8c fe ff ff       	call   8010234d <lapicw>
}
801024c1:	5d                   	pop    %ebp
801024c2:	c3                   	ret    
    lapicw(PCINT, MASKED);
801024c3:	ba 00 00 01 00       	mov    $0x10000,%edx
801024c8:	b8 d0 00 00 00       	mov    $0xd0,%eax
801024cd:	e8 7b fe ff ff       	call   8010234d <lapicw>
801024d2:	e9 71 ff ff ff       	jmp    80102448 <lapicinit+0x79>
801024d7:	f3 c3                	repz ret 

801024d9 <lapicid>:
{
801024d9:	55                   	push   %ebp
801024da:	89 e5                	mov    %esp,%ebp
  if (!lapic)
801024dc:	a1 84 26 12 80       	mov    0x80122684,%eax
801024e1:	85 c0                	test   %eax,%eax
801024e3:	74 08                	je     801024ed <lapicid+0x14>
  return lapic[ID] >> 24;
801024e5:	8b 40 20             	mov    0x20(%eax),%eax
801024e8:	c1 e8 18             	shr    $0x18,%eax
}
801024eb:	5d                   	pop    %ebp
801024ec:	c3                   	ret    
    return 0;
801024ed:	b8 00 00 00 00       	mov    $0x0,%eax
801024f2:	eb f7                	jmp    801024eb <lapicid+0x12>

801024f4 <lapiceoi>:
  if(lapic)
801024f4:	83 3d 84 26 12 80 00 	cmpl   $0x0,0x80122684
801024fb:	74 14                	je     80102511 <lapiceoi+0x1d>
{
801024fd:	55                   	push   %ebp
801024fe:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
80102500:	ba 00 00 00 00       	mov    $0x0,%edx
80102505:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010250a:	e8 3e fe ff ff       	call   8010234d <lapicw>
}
8010250f:	5d                   	pop    %ebp
80102510:	c3                   	ret    
80102511:	f3 c3                	repz ret 

80102513 <microdelay>:
{
80102513:	55                   	push   %ebp
80102514:	89 e5                	mov    %esp,%ebp
}
80102516:	5d                   	pop    %ebp
80102517:	c3                   	ret    

80102518 <lapicstartap>:
{
80102518:	55                   	push   %ebp
80102519:	89 e5                	mov    %esp,%ebp
8010251b:	57                   	push   %edi
8010251c:	56                   	push   %esi
8010251d:	53                   	push   %ebx
8010251e:	8b 75 08             	mov    0x8(%ebp),%esi
80102521:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102524:	b8 0f 00 00 00       	mov    $0xf,%eax
80102529:	ba 70 00 00 00       	mov    $0x70,%edx
8010252e:	ee                   	out    %al,(%dx)
8010252f:	b8 0a 00 00 00       	mov    $0xa,%eax
80102534:	ba 71 00 00 00       	mov    $0x71,%edx
80102539:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
8010253a:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80102541:	00 00 
  wrv[1] = addr >> 4;
80102543:	89 f8                	mov    %edi,%eax
80102545:	c1 e8 04             	shr    $0x4,%eax
80102548:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
8010254e:	c1 e6 18             	shl    $0x18,%esi
80102551:	89 f2                	mov    %esi,%edx
80102553:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102558:	e8 f0 fd ff ff       	call   8010234d <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
8010255d:	ba 00 c5 00 00       	mov    $0xc500,%edx
80102562:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102567:	e8 e1 fd ff ff       	call   8010234d <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
8010256c:	ba 00 85 00 00       	mov    $0x8500,%edx
80102571:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102576:	e8 d2 fd ff ff       	call   8010234d <lapicw>
  for(i = 0; i < 2; i++){
8010257b:	bb 00 00 00 00       	mov    $0x0,%ebx
80102580:	eb 21                	jmp    801025a3 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102582:	89 f2                	mov    %esi,%edx
80102584:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102589:	e8 bf fd ff ff       	call   8010234d <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010258e:	89 fa                	mov    %edi,%edx
80102590:	c1 ea 0c             	shr    $0xc,%edx
80102593:	80 ce 06             	or     $0x6,%dh
80102596:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010259b:	e8 ad fd ff ff       	call   8010234d <lapicw>
  for(i = 0; i < 2; i++){
801025a0:	83 c3 01             	add    $0x1,%ebx
801025a3:	83 fb 01             	cmp    $0x1,%ebx
801025a6:	7e da                	jle    80102582 <lapicstartap+0x6a>
}
801025a8:	5b                   	pop    %ebx
801025a9:	5e                   	pop    %esi
801025aa:	5f                   	pop    %edi
801025ab:	5d                   	pop    %ebp
801025ac:	c3                   	ret    

801025ad <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
801025ad:	55                   	push   %ebp
801025ae:	89 e5                	mov    %esp,%ebp
801025b0:	57                   	push   %edi
801025b1:	56                   	push   %esi
801025b2:	53                   	push   %ebx
801025b3:	83 ec 3c             	sub    $0x3c,%esp
801025b6:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801025b9:	b8 0b 00 00 00       	mov    $0xb,%eax
801025be:	e8 a2 fd ff ff       	call   80102365 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
801025c3:	83 e0 04             	and    $0x4,%eax
801025c6:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
801025c8:	8d 45 d0             	lea    -0x30(%ebp),%eax
801025cb:	e8 a9 fd ff ff       	call   80102379 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
801025d0:	b8 0a 00 00 00       	mov    $0xa,%eax
801025d5:	e8 8b fd ff ff       	call   80102365 <cmos_read>
801025da:	a8 80                	test   $0x80,%al
801025dc:	75 ea                	jne    801025c8 <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
801025de:	8d 5d b8             	lea    -0x48(%ebp),%ebx
801025e1:	89 d8                	mov    %ebx,%eax
801025e3:	e8 91 fd ff ff       	call   80102379 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801025e8:	83 ec 04             	sub    $0x4,%esp
801025eb:	6a 18                	push   $0x18
801025ed:	53                   	push   %ebx
801025ee:	8d 45 d0             	lea    -0x30(%ebp),%eax
801025f1:	50                   	push   %eax
801025f2:	e8 57 18 00 00       	call   80103e4e <memcmp>
801025f7:	83 c4 10             	add    $0x10,%esp
801025fa:	85 c0                	test   %eax,%eax
801025fc:	75 ca                	jne    801025c8 <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
801025fe:	85 ff                	test   %edi,%edi
80102600:	0f 85 84 00 00 00    	jne    8010268a <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80102606:	8b 55 d0             	mov    -0x30(%ebp),%edx
80102609:	89 d0                	mov    %edx,%eax
8010260b:	c1 e8 04             	shr    $0x4,%eax
8010260e:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102611:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102614:	83 e2 0f             	and    $0xf,%edx
80102617:	01 d0                	add    %edx,%eax
80102619:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
8010261c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
8010261f:	89 d0                	mov    %edx,%eax
80102621:	c1 e8 04             	shr    $0x4,%eax
80102624:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102627:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010262a:	83 e2 0f             	and    $0xf,%edx
8010262d:	01 d0                	add    %edx,%eax
8010262f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
80102632:	8b 55 d8             	mov    -0x28(%ebp),%edx
80102635:	89 d0                	mov    %edx,%eax
80102637:	c1 e8 04             	shr    $0x4,%eax
8010263a:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010263d:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102640:	83 e2 0f             	and    $0xf,%edx
80102643:	01 d0                	add    %edx,%eax
80102645:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
80102648:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010264b:	89 d0                	mov    %edx,%eax
8010264d:	c1 e8 04             	shr    $0x4,%eax
80102650:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102653:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102656:	83 e2 0f             	and    $0xf,%edx
80102659:	01 d0                	add    %edx,%eax
8010265b:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
8010265e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102661:	89 d0                	mov    %edx,%eax
80102663:	c1 e8 04             	shr    $0x4,%eax
80102666:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102669:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010266c:	83 e2 0f             	and    $0xf,%edx
8010266f:	01 d0                	add    %edx,%eax
80102671:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
80102674:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102677:	89 d0                	mov    %edx,%eax
80102679:	c1 e8 04             	shr    $0x4,%eax
8010267c:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010267f:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102682:	83 e2 0f             	and    $0xf,%edx
80102685:	01 d0                	add    %edx,%eax
80102687:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
8010268a:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010268d:	89 06                	mov    %eax,(%esi)
8010268f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102692:	89 46 04             	mov    %eax,0x4(%esi)
80102695:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102698:	89 46 08             	mov    %eax,0x8(%esi)
8010269b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010269e:	89 46 0c             	mov    %eax,0xc(%esi)
801026a1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801026a4:	89 46 10             	mov    %eax,0x10(%esi)
801026a7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801026aa:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
801026ad:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
801026b4:	8d 65 f4             	lea    -0xc(%ebp),%esp
801026b7:	5b                   	pop    %ebx
801026b8:	5e                   	pop    %esi
801026b9:	5f                   	pop    %edi
801026ba:	5d                   	pop    %ebp
801026bb:	c3                   	ret    

801026bc <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801026bc:	55                   	push   %ebp
801026bd:	89 e5                	mov    %esp,%ebp
801026bf:	53                   	push   %ebx
801026c0:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801026c3:	ff 35 d4 26 12 80    	pushl  0x801226d4
801026c9:	ff 35 e4 26 12 80    	pushl  0x801226e4
801026cf:	e8 98 da ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
801026d4:	8b 58 5c             	mov    0x5c(%eax),%ebx
801026d7:	89 1d e8 26 12 80    	mov    %ebx,0x801226e8
  for (i = 0; i < log.lh.n; i++) {
801026dd:	83 c4 10             	add    $0x10,%esp
801026e0:	ba 00 00 00 00       	mov    $0x0,%edx
801026e5:	eb 0e                	jmp    801026f5 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
801026e7:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
801026eb:	89 0c 95 ec 26 12 80 	mov    %ecx,-0x7fedd914(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801026f2:	83 c2 01             	add    $0x1,%edx
801026f5:	39 d3                	cmp    %edx,%ebx
801026f7:	7f ee                	jg     801026e7 <read_head+0x2b>
  }
  brelse(buf);
801026f9:	83 ec 0c             	sub    $0xc,%esp
801026fc:	50                   	push   %eax
801026fd:	e8 d3 da ff ff       	call   801001d5 <brelse>
}
80102702:	83 c4 10             	add    $0x10,%esp
80102705:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102708:	c9                   	leave  
80102709:	c3                   	ret    

8010270a <install_trans>:
{
8010270a:	55                   	push   %ebp
8010270b:	89 e5                	mov    %esp,%ebp
8010270d:	57                   	push   %edi
8010270e:	56                   	push   %esi
8010270f:	53                   	push   %ebx
80102710:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
80102713:	bb 00 00 00 00       	mov    $0x0,%ebx
80102718:	eb 66                	jmp    80102780 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010271a:	89 d8                	mov    %ebx,%eax
8010271c:	03 05 d4 26 12 80    	add    0x801226d4,%eax
80102722:	83 c0 01             	add    $0x1,%eax
80102725:	83 ec 08             	sub    $0x8,%esp
80102728:	50                   	push   %eax
80102729:	ff 35 e4 26 12 80    	pushl  0x801226e4
8010272f:	e8 38 da ff ff       	call   8010016c <bread>
80102734:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80102736:	83 c4 08             	add    $0x8,%esp
80102739:	ff 34 9d ec 26 12 80 	pushl  -0x7fedd914(,%ebx,4)
80102740:	ff 35 e4 26 12 80    	pushl  0x801226e4
80102746:	e8 21 da ff ff       	call   8010016c <bread>
8010274b:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
8010274d:	8d 57 5c             	lea    0x5c(%edi),%edx
80102750:	8d 40 5c             	lea    0x5c(%eax),%eax
80102753:	83 c4 0c             	add    $0xc,%esp
80102756:	68 00 02 00 00       	push   $0x200
8010275b:	52                   	push   %edx
8010275c:	50                   	push   %eax
8010275d:	e8 21 17 00 00       	call   80103e83 <memmove>
    bwrite(dbuf);  // write dst to disk
80102762:	89 34 24             	mov    %esi,(%esp)
80102765:	e8 30 da ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
8010276a:	89 3c 24             	mov    %edi,(%esp)
8010276d:	e8 63 da ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
80102772:	89 34 24             	mov    %esi,(%esp)
80102775:	e8 5b da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
8010277a:	83 c3 01             	add    $0x1,%ebx
8010277d:	83 c4 10             	add    $0x10,%esp
80102780:	39 1d e8 26 12 80    	cmp    %ebx,0x801226e8
80102786:	7f 92                	jg     8010271a <install_trans+0x10>
}
80102788:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010278b:	5b                   	pop    %ebx
8010278c:	5e                   	pop    %esi
8010278d:	5f                   	pop    %edi
8010278e:	5d                   	pop    %ebp
8010278f:	c3                   	ret    

80102790 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102790:	55                   	push   %ebp
80102791:	89 e5                	mov    %esp,%ebp
80102793:	53                   	push   %ebx
80102794:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102797:	ff 35 d4 26 12 80    	pushl  0x801226d4
8010279d:	ff 35 e4 26 12 80    	pushl  0x801226e4
801027a3:	e8 c4 d9 ff ff       	call   8010016c <bread>
801027a8:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
801027aa:	8b 0d e8 26 12 80    	mov    0x801226e8,%ecx
801027b0:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
801027b3:	83 c4 10             	add    $0x10,%esp
801027b6:	b8 00 00 00 00       	mov    $0x0,%eax
801027bb:	eb 0e                	jmp    801027cb <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
801027bd:	8b 14 85 ec 26 12 80 	mov    -0x7fedd914(,%eax,4),%edx
801027c4:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
801027c8:	83 c0 01             	add    $0x1,%eax
801027cb:	39 c1                	cmp    %eax,%ecx
801027cd:	7f ee                	jg     801027bd <write_head+0x2d>
  }
  bwrite(buf);
801027cf:	83 ec 0c             	sub    $0xc,%esp
801027d2:	53                   	push   %ebx
801027d3:	e8 c2 d9 ff ff       	call   8010019a <bwrite>
  brelse(buf);
801027d8:	89 1c 24             	mov    %ebx,(%esp)
801027db:	e8 f5 d9 ff ff       	call   801001d5 <brelse>
}
801027e0:	83 c4 10             	add    $0x10,%esp
801027e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801027e6:	c9                   	leave  
801027e7:	c3                   	ret    

801027e8 <recover_from_log>:

static void
recover_from_log(void)
{
801027e8:	55                   	push   %ebp
801027e9:	89 e5                	mov    %esp,%ebp
801027eb:	83 ec 08             	sub    $0x8,%esp
  read_head();
801027ee:	e8 c9 fe ff ff       	call   801026bc <read_head>
  install_trans(); // if committed, copy from log to disk
801027f3:	e8 12 ff ff ff       	call   8010270a <install_trans>
  log.lh.n = 0;
801027f8:	c7 05 e8 26 12 80 00 	movl   $0x0,0x801226e8
801027ff:	00 00 00 
  write_head(); // clear the log
80102802:	e8 89 ff ff ff       	call   80102790 <write_head>
}
80102807:	c9                   	leave  
80102808:	c3                   	ret    

80102809 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
80102809:	55                   	push   %ebp
8010280a:	89 e5                	mov    %esp,%ebp
8010280c:	57                   	push   %edi
8010280d:	56                   	push   %esi
8010280e:	53                   	push   %ebx
8010280f:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80102812:	bb 00 00 00 00       	mov    $0x0,%ebx
80102817:	eb 66                	jmp    8010287f <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80102819:	89 d8                	mov    %ebx,%eax
8010281b:	03 05 d4 26 12 80    	add    0x801226d4,%eax
80102821:	83 c0 01             	add    $0x1,%eax
80102824:	83 ec 08             	sub    $0x8,%esp
80102827:	50                   	push   %eax
80102828:	ff 35 e4 26 12 80    	pushl  0x801226e4
8010282e:	e8 39 d9 ff ff       	call   8010016c <bread>
80102833:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80102835:	83 c4 08             	add    $0x8,%esp
80102838:	ff 34 9d ec 26 12 80 	pushl  -0x7fedd914(,%ebx,4)
8010283f:	ff 35 e4 26 12 80    	pushl  0x801226e4
80102845:	e8 22 d9 ff ff       	call   8010016c <bread>
8010284a:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
8010284c:	8d 50 5c             	lea    0x5c(%eax),%edx
8010284f:	8d 46 5c             	lea    0x5c(%esi),%eax
80102852:	83 c4 0c             	add    $0xc,%esp
80102855:	68 00 02 00 00       	push   $0x200
8010285a:	52                   	push   %edx
8010285b:	50                   	push   %eax
8010285c:	e8 22 16 00 00       	call   80103e83 <memmove>
    bwrite(to);  // write the log
80102861:	89 34 24             	mov    %esi,(%esp)
80102864:	e8 31 d9 ff ff       	call   8010019a <bwrite>
    brelse(from);
80102869:	89 3c 24             	mov    %edi,(%esp)
8010286c:	e8 64 d9 ff ff       	call   801001d5 <brelse>
    brelse(to);
80102871:	89 34 24             	mov    %esi,(%esp)
80102874:	e8 5c d9 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102879:	83 c3 01             	add    $0x1,%ebx
8010287c:	83 c4 10             	add    $0x10,%esp
8010287f:	39 1d e8 26 12 80    	cmp    %ebx,0x801226e8
80102885:	7f 92                	jg     80102819 <write_log+0x10>
  }
}
80102887:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010288a:	5b                   	pop    %ebx
8010288b:	5e                   	pop    %esi
8010288c:	5f                   	pop    %edi
8010288d:	5d                   	pop    %ebp
8010288e:	c3                   	ret    

8010288f <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
8010288f:	83 3d e8 26 12 80 00 	cmpl   $0x0,0x801226e8
80102896:	7e 26                	jle    801028be <commit+0x2f>
{
80102898:	55                   	push   %ebp
80102899:	89 e5                	mov    %esp,%ebp
8010289b:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
8010289e:	e8 66 ff ff ff       	call   80102809 <write_log>
    write_head();    // Write header to disk -- the real commit
801028a3:	e8 e8 fe ff ff       	call   80102790 <write_head>
    install_trans(); // Now install writes to home locations
801028a8:	e8 5d fe ff ff       	call   8010270a <install_trans>
    log.lh.n = 0;
801028ad:	c7 05 e8 26 12 80 00 	movl   $0x0,0x801226e8
801028b4:	00 00 00 
    write_head();    // Erase the transaction from the log
801028b7:	e8 d4 fe ff ff       	call   80102790 <write_head>
  }
}
801028bc:	c9                   	leave  
801028bd:	c3                   	ret    
801028be:	f3 c3                	repz ret 

801028c0 <initlog>:
{
801028c0:	55                   	push   %ebp
801028c1:	89 e5                	mov    %esp,%ebp
801028c3:	53                   	push   %ebx
801028c4:	83 ec 2c             	sub    $0x2c,%esp
801028c7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
801028ca:	68 00 6b 10 80       	push   $0x80106b00
801028cf:	68 a0 26 12 80       	push   $0x801226a0
801028d4:	e8 47 13 00 00       	call   80103c20 <initlock>
  readsb(dev, &sb);
801028d9:	83 c4 08             	add    $0x8,%esp
801028dc:	8d 45 dc             	lea    -0x24(%ebp),%eax
801028df:	50                   	push   %eax
801028e0:	53                   	push   %ebx
801028e1:	e8 50 e9 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
801028e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801028e9:	a3 d4 26 12 80       	mov    %eax,0x801226d4
  log.size = sb.nlog;
801028ee:	8b 45 e8             	mov    -0x18(%ebp),%eax
801028f1:	a3 d8 26 12 80       	mov    %eax,0x801226d8
  log.dev = dev;
801028f6:	89 1d e4 26 12 80    	mov    %ebx,0x801226e4
  recover_from_log();
801028fc:	e8 e7 fe ff ff       	call   801027e8 <recover_from_log>
}
80102901:	83 c4 10             	add    $0x10,%esp
80102904:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102907:	c9                   	leave  
80102908:	c3                   	ret    

80102909 <begin_op>:
{
80102909:	55                   	push   %ebp
8010290a:	89 e5                	mov    %esp,%ebp
8010290c:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
8010290f:	68 a0 26 12 80       	push   $0x801226a0
80102914:	e8 43 14 00 00       	call   80103d5c <acquire>
80102919:	83 c4 10             	add    $0x10,%esp
8010291c:	eb 15                	jmp    80102933 <begin_op+0x2a>
      sleep(&log, &log.lock);
8010291e:	83 ec 08             	sub    $0x8,%esp
80102921:	68 a0 26 12 80       	push   $0x801226a0
80102926:	68 a0 26 12 80       	push   $0x801226a0
8010292b:	e8 c5 0e 00 00       	call   801037f5 <sleep>
80102930:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
80102933:	83 3d e0 26 12 80 00 	cmpl   $0x0,0x801226e0
8010293a:	75 e2                	jne    8010291e <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
8010293c:	a1 dc 26 12 80       	mov    0x801226dc,%eax
80102941:	83 c0 01             	add    $0x1,%eax
80102944:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102947:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
8010294a:	03 15 e8 26 12 80    	add    0x801226e8,%edx
80102950:	83 fa 1e             	cmp    $0x1e,%edx
80102953:	7e 17                	jle    8010296c <begin_op+0x63>
      sleep(&log, &log.lock);
80102955:	83 ec 08             	sub    $0x8,%esp
80102958:	68 a0 26 12 80       	push   $0x801226a0
8010295d:	68 a0 26 12 80       	push   $0x801226a0
80102962:	e8 8e 0e 00 00       	call   801037f5 <sleep>
80102967:	83 c4 10             	add    $0x10,%esp
8010296a:	eb c7                	jmp    80102933 <begin_op+0x2a>
      log.outstanding += 1;
8010296c:	a3 dc 26 12 80       	mov    %eax,0x801226dc
      release(&log.lock);
80102971:	83 ec 0c             	sub    $0xc,%esp
80102974:	68 a0 26 12 80       	push   $0x801226a0
80102979:	e8 43 14 00 00       	call   80103dc1 <release>
}
8010297e:	83 c4 10             	add    $0x10,%esp
80102981:	c9                   	leave  
80102982:	c3                   	ret    

80102983 <end_op>:
{
80102983:	55                   	push   %ebp
80102984:	89 e5                	mov    %esp,%ebp
80102986:	53                   	push   %ebx
80102987:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
8010298a:	68 a0 26 12 80       	push   $0x801226a0
8010298f:	e8 c8 13 00 00       	call   80103d5c <acquire>
  log.outstanding -= 1;
80102994:	a1 dc 26 12 80       	mov    0x801226dc,%eax
80102999:	83 e8 01             	sub    $0x1,%eax
8010299c:	a3 dc 26 12 80       	mov    %eax,0x801226dc
  if(log.committing)
801029a1:	8b 1d e0 26 12 80    	mov    0x801226e0,%ebx
801029a7:	83 c4 10             	add    $0x10,%esp
801029aa:	85 db                	test   %ebx,%ebx
801029ac:	75 2c                	jne    801029da <end_op+0x57>
  if(log.outstanding == 0){
801029ae:	85 c0                	test   %eax,%eax
801029b0:	75 35                	jne    801029e7 <end_op+0x64>
    log.committing = 1;
801029b2:	c7 05 e0 26 12 80 01 	movl   $0x1,0x801226e0
801029b9:	00 00 00 
    do_commit = 1;
801029bc:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
801029c1:	83 ec 0c             	sub    $0xc,%esp
801029c4:	68 a0 26 12 80       	push   $0x801226a0
801029c9:	e8 f3 13 00 00       	call   80103dc1 <release>
  if(do_commit){
801029ce:	83 c4 10             	add    $0x10,%esp
801029d1:	85 db                	test   %ebx,%ebx
801029d3:	75 24                	jne    801029f9 <end_op+0x76>
}
801029d5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801029d8:	c9                   	leave  
801029d9:	c3                   	ret    
    panic("log.committing");
801029da:	83 ec 0c             	sub    $0xc,%esp
801029dd:	68 04 6b 10 80       	push   $0x80106b04
801029e2:	e8 61 d9 ff ff       	call   80100348 <panic>
    wakeup(&log);
801029e7:	83 ec 0c             	sub    $0xc,%esp
801029ea:	68 a0 26 12 80       	push   $0x801226a0
801029ef:	e8 66 0f 00 00       	call   8010395a <wakeup>
801029f4:	83 c4 10             	add    $0x10,%esp
801029f7:	eb c8                	jmp    801029c1 <end_op+0x3e>
    commit();
801029f9:	e8 91 fe ff ff       	call   8010288f <commit>
    acquire(&log.lock);
801029fe:	83 ec 0c             	sub    $0xc,%esp
80102a01:	68 a0 26 12 80       	push   $0x801226a0
80102a06:	e8 51 13 00 00       	call   80103d5c <acquire>
    log.committing = 0;
80102a0b:	c7 05 e0 26 12 80 00 	movl   $0x0,0x801226e0
80102a12:	00 00 00 
    wakeup(&log);
80102a15:	c7 04 24 a0 26 12 80 	movl   $0x801226a0,(%esp)
80102a1c:	e8 39 0f 00 00       	call   8010395a <wakeup>
    release(&log.lock);
80102a21:	c7 04 24 a0 26 12 80 	movl   $0x801226a0,(%esp)
80102a28:	e8 94 13 00 00       	call   80103dc1 <release>
80102a2d:	83 c4 10             	add    $0x10,%esp
}
80102a30:	eb a3                	jmp    801029d5 <end_op+0x52>

80102a32 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102a32:	55                   	push   %ebp
80102a33:	89 e5                	mov    %esp,%ebp
80102a35:	53                   	push   %ebx
80102a36:	83 ec 04             	sub    $0x4,%esp
80102a39:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102a3c:	8b 15 e8 26 12 80    	mov    0x801226e8,%edx
80102a42:	83 fa 1d             	cmp    $0x1d,%edx
80102a45:	7f 45                	jg     80102a8c <log_write+0x5a>
80102a47:	a1 d8 26 12 80       	mov    0x801226d8,%eax
80102a4c:	83 e8 01             	sub    $0x1,%eax
80102a4f:	39 c2                	cmp    %eax,%edx
80102a51:	7d 39                	jge    80102a8c <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102a53:	83 3d dc 26 12 80 00 	cmpl   $0x0,0x801226dc
80102a5a:	7e 3d                	jle    80102a99 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102a5c:	83 ec 0c             	sub    $0xc,%esp
80102a5f:	68 a0 26 12 80       	push   $0x801226a0
80102a64:	e8 f3 12 00 00       	call   80103d5c <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102a69:	83 c4 10             	add    $0x10,%esp
80102a6c:	b8 00 00 00 00       	mov    $0x0,%eax
80102a71:	8b 15 e8 26 12 80    	mov    0x801226e8,%edx
80102a77:	39 c2                	cmp    %eax,%edx
80102a79:	7e 2b                	jle    80102aa6 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102a7b:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a7e:	39 0c 85 ec 26 12 80 	cmp    %ecx,-0x7fedd914(,%eax,4)
80102a85:	74 1f                	je     80102aa6 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102a87:	83 c0 01             	add    $0x1,%eax
80102a8a:	eb e5                	jmp    80102a71 <log_write+0x3f>
    panic("too big a transaction");
80102a8c:	83 ec 0c             	sub    $0xc,%esp
80102a8f:	68 13 6b 10 80       	push   $0x80106b13
80102a94:	e8 af d8 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102a99:	83 ec 0c             	sub    $0xc,%esp
80102a9c:	68 29 6b 10 80       	push   $0x80106b29
80102aa1:	e8 a2 d8 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102aa6:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102aa9:	89 0c 85 ec 26 12 80 	mov    %ecx,-0x7fedd914(,%eax,4)
  if (i == log.lh.n)
80102ab0:	39 c2                	cmp    %eax,%edx
80102ab2:	74 18                	je     80102acc <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102ab4:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102ab7:	83 ec 0c             	sub    $0xc,%esp
80102aba:	68 a0 26 12 80       	push   $0x801226a0
80102abf:	e8 fd 12 00 00       	call   80103dc1 <release>
}
80102ac4:	83 c4 10             	add    $0x10,%esp
80102ac7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102aca:	c9                   	leave  
80102acb:	c3                   	ret    
    log.lh.n++;
80102acc:	83 c2 01             	add    $0x1,%edx
80102acf:	89 15 e8 26 12 80    	mov    %edx,0x801226e8
80102ad5:	eb dd                	jmp    80102ab4 <log_write+0x82>

80102ad7 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102ad7:	55                   	push   %ebp
80102ad8:	89 e5                	mov    %esp,%ebp
80102ada:	53                   	push   %ebx
80102adb:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102ade:	68 8a 00 00 00       	push   $0x8a
80102ae3:	68 8c a4 10 80       	push   $0x8010a48c
80102ae8:	68 00 70 00 80       	push   $0x80007000
80102aed:	e8 91 13 00 00       	call   80103e83 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102af2:	83 c4 10             	add    $0x10,%esp
80102af5:	bb a0 27 12 80       	mov    $0x801227a0,%ebx
80102afa:	eb 06                	jmp    80102b02 <startothers+0x2b>
80102afc:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102b02:	69 05 20 2d 12 80 b0 	imul   $0xb0,0x80122d20,%eax
80102b09:	00 00 00 
80102b0c:	05 a0 27 12 80       	add    $0x801227a0,%eax
80102b11:	39 d8                	cmp    %ebx,%eax
80102b13:	76 4c                	jbe    80102b61 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102b15:	e8 c0 07 00 00       	call   801032da <mycpu>
80102b1a:	39 d8                	cmp    %ebx,%eax
80102b1c:	74 de                	je     80102afc <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc(); // need to pass the pid to kalloc?
80102b1e:	e8 52 f6 ff ff       	call   80102175 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102b23:	05 00 10 00 00       	add    $0x1000,%eax
80102b28:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102b2d:	c7 05 f8 6f 00 80 a5 	movl   $0x80102ba5,0x80006ff8
80102b34:	2b 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102b37:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102b3e:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102b41:	83 ec 08             	sub    $0x8,%esp
80102b44:	68 00 70 00 00       	push   $0x7000
80102b49:	0f b6 03             	movzbl (%ebx),%eax
80102b4c:	50                   	push   %eax
80102b4d:	e8 c6 f9 ff ff       	call   80102518 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102b52:	83 c4 10             	add    $0x10,%esp
80102b55:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102b5b:	85 c0                	test   %eax,%eax
80102b5d:	74 f6                	je     80102b55 <startothers+0x7e>
80102b5f:	eb 9b                	jmp    80102afc <startothers+0x25>
      ;
  }
}
80102b61:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102b64:	c9                   	leave  
80102b65:	c3                   	ret    

80102b66 <mpmain>:
{
80102b66:	55                   	push   %ebp
80102b67:	89 e5                	mov    %esp,%ebp
80102b69:	53                   	push   %ebx
80102b6a:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102b6d:	e8 c4 07 00 00       	call   80103336 <cpuid>
80102b72:	89 c3                	mov    %eax,%ebx
80102b74:	e8 bd 07 00 00       	call   80103336 <cpuid>
80102b79:	83 ec 04             	sub    $0x4,%esp
80102b7c:	53                   	push   %ebx
80102b7d:	50                   	push   %eax
80102b7e:	68 44 6b 10 80       	push   $0x80106b44
80102b83:	e8 83 da ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102b88:	e8 4d 24 00 00       	call   80104fda <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102b8d:	e8 48 07 00 00       	call   801032da <mycpu>
80102b92:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102b94:	b8 01 00 00 00       	mov    $0x1,%eax
80102b99:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102ba0:	e8 2b 0a 00 00       	call   801035d0 <scheduler>

80102ba5 <mpenter>:
{
80102ba5:	55                   	push   %ebp
80102ba6:	89 e5                	mov    %esp,%ebp
80102ba8:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102bab:	e8 33 34 00 00       	call   80105fe3 <switchkvm>
  seginit();
80102bb0:	e8 e2 32 00 00       	call   80105e97 <seginit>
  lapicinit();
80102bb5:	e8 15 f8 ff ff       	call   801023cf <lapicinit>
  mpmain();
80102bba:	e8 a7 ff ff ff       	call   80102b66 <mpmain>

80102bbf <main>:
{
80102bbf:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102bc3:	83 e4 f0             	and    $0xfffffff0,%esp
80102bc6:	ff 71 fc             	pushl  -0x4(%ecx)
80102bc9:	55                   	push   %ebp
80102bca:	89 e5                	mov    %esp,%ebp
80102bcc:	51                   	push   %ecx
80102bcd:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102bd0:	68 00 00 40 80       	push   $0x80400000
80102bd5:	68 c8 54 12 80       	push   $0x801254c8
80102bda:	e8 44 f5 ff ff       	call   80102123 <kinit1>
  kvmalloc();      // kernel page table
80102bdf:	e8 8c 38 00 00       	call   80106470 <kvmalloc>
  mpinit();        // detect other processors
80102be4:	e8 c9 01 00 00       	call   80102db2 <mpinit>
  lapicinit();     // interrupt controller
80102be9:	e8 e1 f7 ff ff       	call   801023cf <lapicinit>
  seginit();       // segment descriptors
80102bee:	e8 a4 32 00 00       	call   80105e97 <seginit>
  picinit();       // disable pic
80102bf3:	e8 82 02 00 00       	call   80102e7a <picinit>
  ioapicinit();    // another interrupt controller
80102bf8:	e8 fd f2 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102bfd:	e8 8c dc ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102c02:	e8 81 26 00 00       	call   80105288 <uartinit>
  pinit();         // process table
80102c07:	e8 b4 06 00 00       	call   801032c0 <pinit>
  tvinit();        // trap vectors
80102c0c:	e8 18 23 00 00       	call   80104f29 <tvinit>
  binit();         // buffer cache
80102c11:	e8 de d4 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102c16:	e8 f8 df ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102c1b:	e8 e0 f0 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102c20:	e8 b2 fe ff ff       	call   80102ad7 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102c25:	83 c4 08             	add    $0x8,%esp
80102c28:	68 00 00 00 8e       	push   $0x8e000000
80102c2d:	68 00 00 40 80       	push   $0x80400000
80102c32:	e8 1e f5 ff ff       	call   80102155 <kinit2>
  userinit();      // first user process
80102c37:	e8 39 07 00 00       	call   80103375 <userinit>
  mpmain();        // finish this processor's setup
80102c3c:	e8 25 ff ff ff       	call   80102b66 <mpmain>

80102c41 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102c41:	55                   	push   %ebp
80102c42:	89 e5                	mov    %esp,%ebp
80102c44:	56                   	push   %esi
80102c45:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102c46:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102c4b:	b9 00 00 00 00       	mov    $0x0,%ecx
80102c50:	eb 09                	jmp    80102c5b <sum+0x1a>
    sum += addr[i];
80102c52:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102c56:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102c58:	83 c1 01             	add    $0x1,%ecx
80102c5b:	39 d1                	cmp    %edx,%ecx
80102c5d:	7c f3                	jl     80102c52 <sum+0x11>
  return sum;
}
80102c5f:	89 d8                	mov    %ebx,%eax
80102c61:	5b                   	pop    %ebx
80102c62:	5e                   	pop    %esi
80102c63:	5d                   	pop    %ebp
80102c64:	c3                   	ret    

80102c65 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102c65:	55                   	push   %ebp
80102c66:	89 e5                	mov    %esp,%ebp
80102c68:	56                   	push   %esi
80102c69:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102c6a:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102c70:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102c72:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102c74:	eb 03                	jmp    80102c79 <mpsearch1+0x14>
80102c76:	83 c3 10             	add    $0x10,%ebx
80102c79:	39 f3                	cmp    %esi,%ebx
80102c7b:	73 29                	jae    80102ca6 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102c7d:	83 ec 04             	sub    $0x4,%esp
80102c80:	6a 04                	push   $0x4
80102c82:	68 58 6b 10 80       	push   $0x80106b58
80102c87:	53                   	push   %ebx
80102c88:	e8 c1 11 00 00       	call   80103e4e <memcmp>
80102c8d:	83 c4 10             	add    $0x10,%esp
80102c90:	85 c0                	test   %eax,%eax
80102c92:	75 e2                	jne    80102c76 <mpsearch1+0x11>
80102c94:	ba 10 00 00 00       	mov    $0x10,%edx
80102c99:	89 d8                	mov    %ebx,%eax
80102c9b:	e8 a1 ff ff ff       	call   80102c41 <sum>
80102ca0:	84 c0                	test   %al,%al
80102ca2:	75 d2                	jne    80102c76 <mpsearch1+0x11>
80102ca4:	eb 05                	jmp    80102cab <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102ca6:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102cab:	89 d8                	mov    %ebx,%eax
80102cad:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102cb0:	5b                   	pop    %ebx
80102cb1:	5e                   	pop    %esi
80102cb2:	5d                   	pop    %ebp
80102cb3:	c3                   	ret    

80102cb4 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102cb4:	55                   	push   %ebp
80102cb5:	89 e5                	mov    %esp,%ebp
80102cb7:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102cba:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102cc1:	c1 e0 08             	shl    $0x8,%eax
80102cc4:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102ccb:	09 d0                	or     %edx,%eax
80102ccd:	c1 e0 04             	shl    $0x4,%eax
80102cd0:	85 c0                	test   %eax,%eax
80102cd2:	74 1f                	je     80102cf3 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102cd4:	ba 00 04 00 00       	mov    $0x400,%edx
80102cd9:	e8 87 ff ff ff       	call   80102c65 <mpsearch1>
80102cde:	85 c0                	test   %eax,%eax
80102ce0:	75 0f                	jne    80102cf1 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102ce2:	ba 00 00 01 00       	mov    $0x10000,%edx
80102ce7:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102cec:	e8 74 ff ff ff       	call   80102c65 <mpsearch1>
}
80102cf1:	c9                   	leave  
80102cf2:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102cf3:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102cfa:	c1 e0 08             	shl    $0x8,%eax
80102cfd:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102d04:	09 d0                	or     %edx,%eax
80102d06:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102d09:	2d 00 04 00 00       	sub    $0x400,%eax
80102d0e:	ba 00 04 00 00       	mov    $0x400,%edx
80102d13:	e8 4d ff ff ff       	call   80102c65 <mpsearch1>
80102d18:	85 c0                	test   %eax,%eax
80102d1a:	75 d5                	jne    80102cf1 <mpsearch+0x3d>
80102d1c:	eb c4                	jmp    80102ce2 <mpsearch+0x2e>

80102d1e <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102d1e:	55                   	push   %ebp
80102d1f:	89 e5                	mov    %esp,%ebp
80102d21:	57                   	push   %edi
80102d22:	56                   	push   %esi
80102d23:	53                   	push   %ebx
80102d24:	83 ec 1c             	sub    $0x1c,%esp
80102d27:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102d2a:	e8 85 ff ff ff       	call   80102cb4 <mpsearch>
80102d2f:	85 c0                	test   %eax,%eax
80102d31:	74 5c                	je     80102d8f <mpconfig+0x71>
80102d33:	89 c7                	mov    %eax,%edi
80102d35:	8b 58 04             	mov    0x4(%eax),%ebx
80102d38:	85 db                	test   %ebx,%ebx
80102d3a:	74 5a                	je     80102d96 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102d3c:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102d42:	83 ec 04             	sub    $0x4,%esp
80102d45:	6a 04                	push   $0x4
80102d47:	68 5d 6b 10 80       	push   $0x80106b5d
80102d4c:	56                   	push   %esi
80102d4d:	e8 fc 10 00 00       	call   80103e4e <memcmp>
80102d52:	83 c4 10             	add    $0x10,%esp
80102d55:	85 c0                	test   %eax,%eax
80102d57:	75 44                	jne    80102d9d <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102d59:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102d60:	3c 01                	cmp    $0x1,%al
80102d62:	0f 95 c2             	setne  %dl
80102d65:	3c 04                	cmp    $0x4,%al
80102d67:	0f 95 c0             	setne  %al
80102d6a:	84 c2                	test   %al,%dl
80102d6c:	75 36                	jne    80102da4 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102d6e:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102d75:	89 f0                	mov    %esi,%eax
80102d77:	e8 c5 fe ff ff       	call   80102c41 <sum>
80102d7c:	84 c0                	test   %al,%al
80102d7e:	75 2b                	jne    80102dab <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102d80:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d83:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102d85:	89 f0                	mov    %esi,%eax
80102d87:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102d8a:	5b                   	pop    %ebx
80102d8b:	5e                   	pop    %esi
80102d8c:	5f                   	pop    %edi
80102d8d:	5d                   	pop    %ebp
80102d8e:	c3                   	ret    
    return 0;
80102d8f:	be 00 00 00 00       	mov    $0x0,%esi
80102d94:	eb ef                	jmp    80102d85 <mpconfig+0x67>
80102d96:	be 00 00 00 00       	mov    $0x0,%esi
80102d9b:	eb e8                	jmp    80102d85 <mpconfig+0x67>
    return 0;
80102d9d:	be 00 00 00 00       	mov    $0x0,%esi
80102da2:	eb e1                	jmp    80102d85 <mpconfig+0x67>
    return 0;
80102da4:	be 00 00 00 00       	mov    $0x0,%esi
80102da9:	eb da                	jmp    80102d85 <mpconfig+0x67>
    return 0;
80102dab:	be 00 00 00 00       	mov    $0x0,%esi
80102db0:	eb d3                	jmp    80102d85 <mpconfig+0x67>

80102db2 <mpinit>:

void
mpinit(void)
{
80102db2:	55                   	push   %ebp
80102db3:	89 e5                	mov    %esp,%ebp
80102db5:	57                   	push   %edi
80102db6:	56                   	push   %esi
80102db7:	53                   	push   %ebx
80102db8:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102dbb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102dbe:	e8 5b ff ff ff       	call   80102d1e <mpconfig>
80102dc3:	85 c0                	test   %eax,%eax
80102dc5:	74 19                	je     80102de0 <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102dc7:	8b 50 24             	mov    0x24(%eax),%edx
80102dca:	89 15 84 26 12 80    	mov    %edx,0x80122684
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102dd0:	8d 50 2c             	lea    0x2c(%eax),%edx
80102dd3:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102dd7:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102dd9:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102dde:	eb 34                	jmp    80102e14 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102de0:	83 ec 0c             	sub    $0xc,%esp
80102de3:	68 62 6b 10 80       	push   $0x80106b62
80102de8:	e8 5b d5 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102ded:	8b 35 20 2d 12 80    	mov    0x80122d20,%esi
80102df3:	83 fe 07             	cmp    $0x7,%esi
80102df6:	7f 19                	jg     80102e11 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102df8:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102dfc:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102e02:	88 87 a0 27 12 80    	mov    %al,-0x7fedd860(%edi)
        ncpu++;
80102e08:	83 c6 01             	add    $0x1,%esi
80102e0b:	89 35 20 2d 12 80    	mov    %esi,0x80122d20
      }
      p += sizeof(struct mpproc);
80102e11:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102e14:	39 ca                	cmp    %ecx,%edx
80102e16:	73 2b                	jae    80102e43 <mpinit+0x91>
    switch(*p){
80102e18:	0f b6 02             	movzbl (%edx),%eax
80102e1b:	3c 04                	cmp    $0x4,%al
80102e1d:	77 1d                	ja     80102e3c <mpinit+0x8a>
80102e1f:	0f b6 c0             	movzbl %al,%eax
80102e22:	ff 24 85 9c 6b 10 80 	jmp    *-0x7fef9464(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102e29:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102e2d:	a2 80 27 12 80       	mov    %al,0x80122780
      p += sizeof(struct mpioapic);
80102e32:	83 c2 08             	add    $0x8,%edx
      continue;
80102e35:	eb dd                	jmp    80102e14 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102e37:	83 c2 08             	add    $0x8,%edx
      continue;
80102e3a:	eb d8                	jmp    80102e14 <mpinit+0x62>
    default:
      ismp = 0;
80102e3c:	bb 00 00 00 00       	mov    $0x0,%ebx
80102e41:	eb d1                	jmp    80102e14 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102e43:	85 db                	test   %ebx,%ebx
80102e45:	74 26                	je     80102e6d <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102e47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e4a:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102e4e:	74 15                	je     80102e65 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e50:	b8 70 00 00 00       	mov    $0x70,%eax
80102e55:	ba 22 00 00 00       	mov    $0x22,%edx
80102e5a:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102e5b:	ba 23 00 00 00       	mov    $0x23,%edx
80102e60:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102e61:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e64:	ee                   	out    %al,(%dx)
  }
}
80102e65:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e68:	5b                   	pop    %ebx
80102e69:	5e                   	pop    %esi
80102e6a:	5f                   	pop    %edi
80102e6b:	5d                   	pop    %ebp
80102e6c:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102e6d:	83 ec 0c             	sub    $0xc,%esp
80102e70:	68 7c 6b 10 80       	push   $0x80106b7c
80102e75:	e8 ce d4 ff ff       	call   80100348 <panic>

80102e7a <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102e7a:	55                   	push   %ebp
80102e7b:	89 e5                	mov    %esp,%ebp
80102e7d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e82:	ba 21 00 00 00       	mov    $0x21,%edx
80102e87:	ee                   	out    %al,(%dx)
80102e88:	ba a1 00 00 00       	mov    $0xa1,%edx
80102e8d:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102e8e:	5d                   	pop    %ebp
80102e8f:	c3                   	ret    

80102e90 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102e90:	55                   	push   %ebp
80102e91:	89 e5                	mov    %esp,%ebp
80102e93:	57                   	push   %edi
80102e94:	56                   	push   %esi
80102e95:	53                   	push   %ebx
80102e96:	83 ec 0c             	sub    $0xc,%esp
80102e99:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102e9c:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102e9f:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102ea5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102eab:	e8 7d dd ff ff       	call   80100c2d <filealloc>
80102eb0:	89 03                	mov    %eax,(%ebx)
80102eb2:	85 c0                	test   %eax,%eax
80102eb4:	74 16                	je     80102ecc <pipealloc+0x3c>
80102eb6:	e8 72 dd ff ff       	call   80100c2d <filealloc>
80102ebb:	89 06                	mov    %eax,(%esi)
80102ebd:	85 c0                	test   %eax,%eax
80102ebf:	74 0b                	je     80102ecc <pipealloc+0x3c>
    goto bad;
  // need to pass the pid to kalloc?
  if((p = (struct pipe*)kalloc()) == 0)
80102ec1:	e8 af f2 ff ff       	call   80102175 <kalloc>
80102ec6:	89 c7                	mov    %eax,%edi
80102ec8:	85 c0                	test   %eax,%eax
80102eca:	75 35                	jne    80102f01 <pipealloc+0x71>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102ecc:	8b 03                	mov    (%ebx),%eax
80102ece:	85 c0                	test   %eax,%eax
80102ed0:	74 0c                	je     80102ede <pipealloc+0x4e>
    fileclose(*f0);
80102ed2:	83 ec 0c             	sub    $0xc,%esp
80102ed5:	50                   	push   %eax
80102ed6:	e8 f8 dd ff ff       	call   80100cd3 <fileclose>
80102edb:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102ede:	8b 06                	mov    (%esi),%eax
80102ee0:	85 c0                	test   %eax,%eax
80102ee2:	0f 84 8b 00 00 00    	je     80102f73 <pipealloc+0xe3>
    fileclose(*f1);
80102ee8:	83 ec 0c             	sub    $0xc,%esp
80102eeb:	50                   	push   %eax
80102eec:	e8 e2 dd ff ff       	call   80100cd3 <fileclose>
80102ef1:	83 c4 10             	add    $0x10,%esp
  return -1;
80102ef4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102ef9:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102efc:	5b                   	pop    %ebx
80102efd:	5e                   	pop    %esi
80102efe:	5f                   	pop    %edi
80102eff:	5d                   	pop    %ebp
80102f00:	c3                   	ret    
  p->readopen = 1;
80102f01:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102f08:	00 00 00 
  p->writeopen = 1;
80102f0b:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102f12:	00 00 00 
  p->nwrite = 0;
80102f15:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102f1c:	00 00 00 
  p->nread = 0;
80102f1f:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102f26:	00 00 00 
  initlock(&p->lock, "pipe");
80102f29:	83 ec 08             	sub    $0x8,%esp
80102f2c:	68 b0 6b 10 80       	push   $0x80106bb0
80102f31:	50                   	push   %eax
80102f32:	e8 e9 0c 00 00       	call   80103c20 <initlock>
  (*f0)->type = FD_PIPE;
80102f37:	8b 03                	mov    (%ebx),%eax
80102f39:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102f3f:	8b 03                	mov    (%ebx),%eax
80102f41:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102f45:	8b 03                	mov    (%ebx),%eax
80102f47:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102f4b:	8b 03                	mov    (%ebx),%eax
80102f4d:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102f50:	8b 06                	mov    (%esi),%eax
80102f52:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102f58:	8b 06                	mov    (%esi),%eax
80102f5a:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102f5e:	8b 06                	mov    (%esi),%eax
80102f60:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102f64:	8b 06                	mov    (%esi),%eax
80102f66:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102f69:	83 c4 10             	add    $0x10,%esp
80102f6c:	b8 00 00 00 00       	mov    $0x0,%eax
80102f71:	eb 86                	jmp    80102ef9 <pipealloc+0x69>
  return -1;
80102f73:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102f78:	e9 7c ff ff ff       	jmp    80102ef9 <pipealloc+0x69>

80102f7d <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102f7d:	55                   	push   %ebp
80102f7e:	89 e5                	mov    %esp,%ebp
80102f80:	53                   	push   %ebx
80102f81:	83 ec 10             	sub    $0x10,%esp
80102f84:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102f87:	53                   	push   %ebx
80102f88:	e8 cf 0d 00 00       	call   80103d5c <acquire>
  if(writable){
80102f8d:	83 c4 10             	add    $0x10,%esp
80102f90:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102f94:	74 3f                	je     80102fd5 <pipeclose+0x58>
    p->writeopen = 0;
80102f96:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102f9d:	00 00 00 
    wakeup(&p->nread);
80102fa0:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102fa6:	83 ec 0c             	sub    $0xc,%esp
80102fa9:	50                   	push   %eax
80102faa:	e8 ab 09 00 00       	call   8010395a <wakeup>
80102faf:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102fb2:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102fb9:	75 09                	jne    80102fc4 <pipeclose+0x47>
80102fbb:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102fc2:	74 2f                	je     80102ff3 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102fc4:	83 ec 0c             	sub    $0xc,%esp
80102fc7:	53                   	push   %ebx
80102fc8:	e8 f4 0d 00 00       	call   80103dc1 <release>
80102fcd:	83 c4 10             	add    $0x10,%esp
}
80102fd0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102fd3:	c9                   	leave  
80102fd4:	c3                   	ret    
    p->readopen = 0;
80102fd5:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102fdc:	00 00 00 
    wakeup(&p->nwrite);
80102fdf:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102fe5:	83 ec 0c             	sub    $0xc,%esp
80102fe8:	50                   	push   %eax
80102fe9:	e8 6c 09 00 00       	call   8010395a <wakeup>
80102fee:	83 c4 10             	add    $0x10,%esp
80102ff1:	eb bf                	jmp    80102fb2 <pipeclose+0x35>
    release(&p->lock);
80102ff3:	83 ec 0c             	sub    $0xc,%esp
80102ff6:	53                   	push   %ebx
80102ff7:	e8 c5 0d 00 00       	call   80103dc1 <release>
    kfree((char*)p);
80102ffc:	89 1c 24             	mov    %ebx,(%esp)
80102fff:	e8 b4 ef ff ff       	call   80101fb8 <kfree>
80103004:	83 c4 10             	add    $0x10,%esp
80103007:	eb c7                	jmp    80102fd0 <pipeclose+0x53>

80103009 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80103009:	55                   	push   %ebp
8010300a:	89 e5                	mov    %esp,%ebp
8010300c:	57                   	push   %edi
8010300d:	56                   	push   %esi
8010300e:	53                   	push   %ebx
8010300f:	83 ec 18             	sub    $0x18,%esp
80103012:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103015:	89 de                	mov    %ebx,%esi
80103017:	53                   	push   %ebx
80103018:	e8 3f 0d 00 00       	call   80103d5c <acquire>
  for(i = 0; i < n; i++){
8010301d:	83 c4 10             	add    $0x10,%esp
80103020:	bf 00 00 00 00       	mov    $0x0,%edi
80103025:	3b 7d 10             	cmp    0x10(%ebp),%edi
80103028:	0f 8d 88 00 00 00    	jge    801030b6 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010302e:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80103034:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
8010303a:	05 00 02 00 00       	add    $0x200,%eax
8010303f:	39 c2                	cmp    %eax,%edx
80103041:	75 51                	jne    80103094 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80103043:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
8010304a:	74 2f                	je     8010307b <pipewrite+0x72>
8010304c:	e8 00 03 00 00       	call   80103351 <myproc>
80103051:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103055:	75 24                	jne    8010307b <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
80103057:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010305d:	83 ec 0c             	sub    $0xc,%esp
80103060:	50                   	push   %eax
80103061:	e8 f4 08 00 00       	call   8010395a <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103066:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010306c:	83 c4 08             	add    $0x8,%esp
8010306f:	56                   	push   %esi
80103070:	50                   	push   %eax
80103071:	e8 7f 07 00 00       	call   801037f5 <sleep>
80103076:	83 c4 10             	add    $0x10,%esp
80103079:	eb b3                	jmp    8010302e <pipewrite+0x25>
        release(&p->lock);
8010307b:	83 ec 0c             	sub    $0xc,%esp
8010307e:	53                   	push   %ebx
8010307f:	e8 3d 0d 00 00       	call   80103dc1 <release>
        return -1;
80103084:	83 c4 10             	add    $0x10,%esp
80103087:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
8010308c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010308f:	5b                   	pop    %ebx
80103090:	5e                   	pop    %esi
80103091:	5f                   	pop    %edi
80103092:	5d                   	pop    %ebp
80103093:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103094:	8d 42 01             	lea    0x1(%edx),%eax
80103097:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
8010309d:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
801030a3:	8b 45 0c             	mov    0xc(%ebp),%eax
801030a6:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
801030aa:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
801030ae:	83 c7 01             	add    $0x1,%edi
801030b1:	e9 6f ff ff ff       	jmp    80103025 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801030b6:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801030bc:	83 ec 0c             	sub    $0xc,%esp
801030bf:	50                   	push   %eax
801030c0:	e8 95 08 00 00       	call   8010395a <wakeup>
  release(&p->lock);
801030c5:	89 1c 24             	mov    %ebx,(%esp)
801030c8:	e8 f4 0c 00 00       	call   80103dc1 <release>
  return n;
801030cd:	83 c4 10             	add    $0x10,%esp
801030d0:	8b 45 10             	mov    0x10(%ebp),%eax
801030d3:	eb b7                	jmp    8010308c <pipewrite+0x83>

801030d5 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801030d5:	55                   	push   %ebp
801030d6:	89 e5                	mov    %esp,%ebp
801030d8:	57                   	push   %edi
801030d9:	56                   	push   %esi
801030da:	53                   	push   %ebx
801030db:	83 ec 18             	sub    $0x18,%esp
801030de:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801030e1:	89 df                	mov    %ebx,%edi
801030e3:	53                   	push   %ebx
801030e4:	e8 73 0c 00 00       	call   80103d5c <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801030e9:	83 c4 10             	add    $0x10,%esp
801030ec:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
801030f2:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
801030f8:	75 3d                	jne    80103137 <piperead+0x62>
801030fa:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
80103100:	85 f6                	test   %esi,%esi
80103102:	74 38                	je     8010313c <piperead+0x67>
    if(myproc()->killed){
80103104:	e8 48 02 00 00       	call   80103351 <myproc>
80103109:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010310d:	75 15                	jne    80103124 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010310f:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103115:	83 ec 08             	sub    $0x8,%esp
80103118:	57                   	push   %edi
80103119:	50                   	push   %eax
8010311a:	e8 d6 06 00 00       	call   801037f5 <sleep>
8010311f:	83 c4 10             	add    $0x10,%esp
80103122:	eb c8                	jmp    801030ec <piperead+0x17>
      release(&p->lock);
80103124:	83 ec 0c             	sub    $0xc,%esp
80103127:	53                   	push   %ebx
80103128:	e8 94 0c 00 00       	call   80103dc1 <release>
      return -1;
8010312d:	83 c4 10             	add    $0x10,%esp
80103130:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103135:	eb 50                	jmp    80103187 <piperead+0xb2>
80103137:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010313c:	3b 75 10             	cmp    0x10(%ebp),%esi
8010313f:	7d 2c                	jge    8010316d <piperead+0x98>
    if(p->nread == p->nwrite)
80103141:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103147:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
8010314d:	74 1e                	je     8010316d <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010314f:	8d 50 01             	lea    0x1(%eax),%edx
80103152:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80103158:	25 ff 01 00 00       	and    $0x1ff,%eax
8010315d:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
80103162:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103165:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103168:	83 c6 01             	add    $0x1,%esi
8010316b:	eb cf                	jmp    8010313c <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010316d:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103173:	83 ec 0c             	sub    $0xc,%esp
80103176:	50                   	push   %eax
80103177:	e8 de 07 00 00       	call   8010395a <wakeup>
  release(&p->lock);
8010317c:	89 1c 24             	mov    %ebx,(%esp)
8010317f:	e8 3d 0c 00 00       	call   80103dc1 <release>
  return i;
80103184:	83 c4 10             	add    $0x10,%esp
}
80103187:	89 f0                	mov    %esi,%eax
80103189:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010318c:	5b                   	pop    %ebx
8010318d:	5e                   	pop    %esi
8010318e:	5f                   	pop    %edi
8010318f:	5d                   	pop    %ebp
80103190:	c3                   	ret    

80103191 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80103191:	55                   	push   %ebp
80103192:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103194:	ba 74 2d 12 80       	mov    $0x80122d74,%edx
80103199:	eb 03                	jmp    8010319e <wakeup1+0xd>
8010319b:	83 c2 7c             	add    $0x7c,%edx
8010319e:	81 fa 74 4c 12 80    	cmp    $0x80124c74,%edx
801031a4:	73 14                	jae    801031ba <wakeup1+0x29>
    if (p->state == SLEEPING && p->chan == chan)
801031a6:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
801031aa:	75 ef                	jne    8010319b <wakeup1+0xa>
801031ac:	39 42 20             	cmp    %eax,0x20(%edx)
801031af:	75 ea                	jne    8010319b <wakeup1+0xa>
      p->state = RUNNABLE;
801031b1:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
801031b8:	eb e1                	jmp    8010319b <wakeup1+0xa>
}
801031ba:	5d                   	pop    %ebp
801031bb:	c3                   	ret    

801031bc <allocproc>:
{
801031bc:	55                   	push   %ebp
801031bd:	89 e5                	mov    %esp,%ebp
801031bf:	53                   	push   %ebx
801031c0:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
801031c3:	68 40 2d 12 80       	push   $0x80122d40
801031c8:	e8 8f 0b 00 00       	call   80103d5c <acquire>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801031cd:	83 c4 10             	add    $0x10,%esp
801031d0:	bb 74 2d 12 80       	mov    $0x80122d74,%ebx
801031d5:	81 fb 74 4c 12 80    	cmp    $0x80124c74,%ebx
801031db:	73 0b                	jae    801031e8 <allocproc+0x2c>
    if (p->state == UNUSED)
801031dd:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
801031e1:	74 1c                	je     801031ff <allocproc+0x43>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801031e3:	83 c3 7c             	add    $0x7c,%ebx
801031e6:	eb ed                	jmp    801031d5 <allocproc+0x19>
  release(&ptable.lock);
801031e8:	83 ec 0c             	sub    $0xc,%esp
801031eb:	68 40 2d 12 80       	push   $0x80122d40
801031f0:	e8 cc 0b 00 00       	call   80103dc1 <release>
  return 0;
801031f5:	83 c4 10             	add    $0x10,%esp
801031f8:	bb 00 00 00 00       	mov    $0x0,%ebx
801031fd:	eb 69                	jmp    80103268 <allocproc+0xac>
  p->state = EMBRYO;
801031ff:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
80103206:	a1 04 a0 10 80       	mov    0x8010a004,%eax
8010320b:	8d 50 01             	lea    0x1(%eax),%edx
8010320e:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
80103214:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
80103217:	83 ec 0c             	sub    $0xc,%esp
8010321a:	68 40 2d 12 80       	push   $0x80122d40
8010321f:	e8 9d 0b 00 00       	call   80103dc1 <release>
  if ((p->kstack = kalloc()) == 0)
80103224:	e8 4c ef ff ff       	call   80102175 <kalloc>
80103229:	89 43 08             	mov    %eax,0x8(%ebx)
8010322c:	83 c4 10             	add    $0x10,%esp
8010322f:	85 c0                	test   %eax,%eax
80103231:	74 3c                	je     8010326f <allocproc+0xb3>
  sp -= sizeof *p->tf;
80103233:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe *)sp;
80103239:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint *)sp = (uint)trapret;
8010323c:	c7 80 b0 0f 00 00 1e 	movl   $0x80104f1e,0xfb0(%eax)
80103243:	4f 10 80 
  sp -= sizeof *p->context;
80103246:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context *)sp;
8010324b:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
8010324e:	83 ec 04             	sub    $0x4,%esp
80103251:	6a 14                	push   $0x14
80103253:	6a 00                	push   $0x0
80103255:	50                   	push   %eax
80103256:	e8 ad 0b 00 00       	call   80103e08 <memset>
  p->context->eip = (uint)forkret;
8010325b:	8b 43 1c             	mov    0x1c(%ebx),%eax
8010325e:	c7 40 10 7d 32 10 80 	movl   $0x8010327d,0x10(%eax)
  return p;
80103265:	83 c4 10             	add    $0x10,%esp
}
80103268:	89 d8                	mov    %ebx,%eax
8010326a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010326d:	c9                   	leave  
8010326e:	c3                   	ret    
    p->state = UNUSED;
8010326f:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
80103276:	bb 00 00 00 00       	mov    $0x0,%ebx
8010327b:	eb eb                	jmp    80103268 <allocproc+0xac>

8010327d <forkret>:
{
8010327d:	55                   	push   %ebp
8010327e:	89 e5                	mov    %esp,%ebp
80103280:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
80103283:	68 40 2d 12 80       	push   $0x80122d40
80103288:	e8 34 0b 00 00       	call   80103dc1 <release>
  if (first)
8010328d:	83 c4 10             	add    $0x10,%esp
80103290:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
80103297:	75 02                	jne    8010329b <forkret+0x1e>
}
80103299:	c9                   	leave  
8010329a:	c3                   	ret    
    first = 0;
8010329b:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
801032a2:	00 00 00 
    iinit(ROOTDEV);
801032a5:	83 ec 0c             	sub    $0xc,%esp
801032a8:	6a 01                	push   $0x1
801032aa:	e8 3d e0 ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
801032af:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032b6:	e8 05 f6 ff ff       	call   801028c0 <initlog>
801032bb:	83 c4 10             	add    $0x10,%esp
}
801032be:	eb d9                	jmp    80103299 <forkret+0x1c>

801032c0 <pinit>:
{
801032c0:	55                   	push   %ebp
801032c1:	89 e5                	mov    %esp,%ebp
801032c3:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801032c6:	68 b5 6b 10 80       	push   $0x80106bb5
801032cb:	68 40 2d 12 80       	push   $0x80122d40
801032d0:	e8 4b 09 00 00       	call   80103c20 <initlock>
}
801032d5:	83 c4 10             	add    $0x10,%esp
801032d8:	c9                   	leave  
801032d9:	c3                   	ret    

801032da <mycpu>:
{
801032da:	55                   	push   %ebp
801032db:	89 e5                	mov    %esp,%ebp
801032dd:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801032e0:	9c                   	pushf  
801032e1:	58                   	pop    %eax
  if (readeflags() & FL_IF)
801032e2:	f6 c4 02             	test   $0x2,%ah
801032e5:	75 28                	jne    8010330f <mycpu+0x35>
  apicid = lapicid();
801032e7:	e8 ed f1 ff ff       	call   801024d9 <lapicid>
  for (i = 0; i < ncpu; ++i)
801032ec:	ba 00 00 00 00       	mov    $0x0,%edx
801032f1:	39 15 20 2d 12 80    	cmp    %edx,0x80122d20
801032f7:	7e 23                	jle    8010331c <mycpu+0x42>
    if (cpus[i].apicid == apicid)
801032f9:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801032ff:	0f b6 89 a0 27 12 80 	movzbl -0x7fedd860(%ecx),%ecx
80103306:	39 c1                	cmp    %eax,%ecx
80103308:	74 1f                	je     80103329 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i)
8010330a:	83 c2 01             	add    $0x1,%edx
8010330d:	eb e2                	jmp    801032f1 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
8010330f:	83 ec 0c             	sub    $0xc,%esp
80103312:	68 98 6c 10 80       	push   $0x80106c98
80103317:	e8 2c d0 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
8010331c:	83 ec 0c             	sub    $0xc,%esp
8010331f:	68 bc 6b 10 80       	push   $0x80106bbc
80103324:	e8 1f d0 ff ff       	call   80100348 <panic>
      return &cpus[i];
80103329:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
8010332f:	05 a0 27 12 80       	add    $0x801227a0,%eax
}
80103334:	c9                   	leave  
80103335:	c3                   	ret    

80103336 <cpuid>:
{
80103336:	55                   	push   %ebp
80103337:	89 e5                	mov    %esp,%ebp
80103339:	83 ec 08             	sub    $0x8,%esp
  return mycpu() - cpus;
8010333c:	e8 99 ff ff ff       	call   801032da <mycpu>
80103341:	2d a0 27 12 80       	sub    $0x801227a0,%eax
80103346:	c1 f8 04             	sar    $0x4,%eax
80103349:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
8010334f:	c9                   	leave  
80103350:	c3                   	ret    

80103351 <myproc>:
{
80103351:	55                   	push   %ebp
80103352:	89 e5                	mov    %esp,%ebp
80103354:	53                   	push   %ebx
80103355:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103358:	e8 22 09 00 00       	call   80103c7f <pushcli>
  c = mycpu();
8010335d:	e8 78 ff ff ff       	call   801032da <mycpu>
  p = c->proc;
80103362:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103368:	e8 4f 09 00 00       	call   80103cbc <popcli>
}
8010336d:	89 d8                	mov    %ebx,%eax
8010336f:	83 c4 04             	add    $0x4,%esp
80103372:	5b                   	pop    %ebx
80103373:	5d                   	pop    %ebp
80103374:	c3                   	ret    

80103375 <userinit>:
{
80103375:	55                   	push   %ebp
80103376:	89 e5                	mov    %esp,%ebp
80103378:	53                   	push   %ebx
80103379:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
8010337c:	e8 3b fe ff ff       	call   801031bc <allocproc>
80103381:	89 c3                	mov    %eax,%ebx
  initproc = p;
80103383:	a3 b8 a5 10 80       	mov    %eax,0x8010a5b8
  if ((p->pgdir = setupkvm()) == 0)
80103388:	e8 75 30 00 00       	call   80106402 <setupkvm>
8010338d:	89 43 04             	mov    %eax,0x4(%ebx)
80103390:	85 c0                	test   %eax,%eax
80103392:	0f 84 b7 00 00 00    	je     8010344f <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103398:	83 ec 04             	sub    $0x4,%esp
8010339b:	68 2c 00 00 00       	push   $0x2c
801033a0:	68 60 a4 10 80       	push   $0x8010a460
801033a5:	50                   	push   %eax
801033a6:	e8 62 2d 00 00       	call   8010610d <inituvm>
  p->sz = PGSIZE;
801033ab:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
801033b1:	83 c4 0c             	add    $0xc,%esp
801033b4:	6a 4c                	push   $0x4c
801033b6:	6a 00                	push   $0x0
801033b8:	ff 73 18             	pushl  0x18(%ebx)
801033bb:	e8 48 0a 00 00       	call   80103e08 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801033c0:	8b 43 18             	mov    0x18(%ebx),%eax
801033c3:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801033c9:	8b 43 18             	mov    0x18(%ebx),%eax
801033cc:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801033d2:	8b 43 18             	mov    0x18(%ebx),%eax
801033d5:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033d9:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801033dd:	8b 43 18             	mov    0x18(%ebx),%eax
801033e0:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033e4:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801033e8:	8b 43 18             	mov    0x18(%ebx),%eax
801033eb:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801033f2:	8b 43 18             	mov    0x18(%ebx),%eax
801033f5:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0; // beginning of initcode.S
801033fc:	8b 43 18             	mov    0x18(%ebx),%eax
801033ff:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
80103406:	8d 43 6c             	lea    0x6c(%ebx),%eax
80103409:	83 c4 0c             	add    $0xc,%esp
8010340c:	6a 10                	push   $0x10
8010340e:	68 e5 6b 10 80       	push   $0x80106be5
80103413:	50                   	push   %eax
80103414:	e8 56 0b 00 00       	call   80103f6f <safestrcpy>
  p->cwd = namei("/");
80103419:	c7 04 24 ee 6b 10 80 	movl   $0x80106bee,(%esp)
80103420:	e8 bc e7 ff ff       	call   80101be1 <namei>
80103425:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
80103428:	c7 04 24 40 2d 12 80 	movl   $0x80122d40,(%esp)
8010342f:	e8 28 09 00 00       	call   80103d5c <acquire>
  p->state = RUNNABLE;
80103434:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
8010343b:	c7 04 24 40 2d 12 80 	movl   $0x80122d40,(%esp)
80103442:	e8 7a 09 00 00       	call   80103dc1 <release>
}
80103447:	83 c4 10             	add    $0x10,%esp
8010344a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010344d:	c9                   	leave  
8010344e:	c3                   	ret    
    panic("userinit: out of memory?");
8010344f:	83 ec 0c             	sub    $0xc,%esp
80103452:	68 cc 6b 10 80       	push   $0x80106bcc
80103457:	e8 ec ce ff ff       	call   80100348 <panic>

8010345c <growproc>:
{
8010345c:	55                   	push   %ebp
8010345d:	89 e5                	mov    %esp,%ebp
8010345f:	56                   	push   %esi
80103460:	53                   	push   %ebx
80103461:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
80103464:	e8 e8 fe ff ff       	call   80103351 <myproc>
80103469:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
8010346b:	8b 00                	mov    (%eax),%eax
  if (n > 0)
8010346d:	85 f6                	test   %esi,%esi
8010346f:	7f 21                	jg     80103492 <growproc+0x36>
  else if (n < 0)
80103471:	85 f6                	test   %esi,%esi
80103473:	79 33                	jns    801034a8 <growproc+0x4c>
    if ((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103475:	83 ec 04             	sub    $0x4,%esp
80103478:	01 c6                	add    %eax,%esi
8010347a:	56                   	push   %esi
8010347b:	50                   	push   %eax
8010347c:	ff 73 04             	pushl  0x4(%ebx)
8010347f:	e8 92 2d 00 00       	call   80106216 <deallocuvm>
80103484:	83 c4 10             	add    $0x10,%esp
80103487:	85 c0                	test   %eax,%eax
80103489:	75 1d                	jne    801034a8 <growproc+0x4c>
      return -1;
8010348b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103490:	eb 29                	jmp    801034bb <growproc+0x5f>
    if ((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103492:	83 ec 04             	sub    $0x4,%esp
80103495:	01 c6                	add    %eax,%esi
80103497:	56                   	push   %esi
80103498:	50                   	push   %eax
80103499:	ff 73 04             	pushl  0x4(%ebx)
8010349c:	e8 07 2e 00 00       	call   801062a8 <allocuvm>
801034a1:	83 c4 10             	add    $0x10,%esp
801034a4:	85 c0                	test   %eax,%eax
801034a6:	74 1a                	je     801034c2 <growproc+0x66>
  curproc->sz = sz;
801034a8:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
801034aa:	83 ec 0c             	sub    $0xc,%esp
801034ad:	53                   	push   %ebx
801034ae:	e8 42 2b 00 00       	call   80105ff5 <switchuvm>
  return 0;
801034b3:	83 c4 10             	add    $0x10,%esp
801034b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801034bb:	8d 65 f8             	lea    -0x8(%ebp),%esp
801034be:	5b                   	pop    %ebx
801034bf:	5e                   	pop    %esi
801034c0:	5d                   	pop    %ebp
801034c1:	c3                   	ret    
      return -1;
801034c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801034c7:	eb f2                	jmp    801034bb <growproc+0x5f>

801034c9 <fork>:
{
801034c9:	55                   	push   %ebp
801034ca:	89 e5                	mov    %esp,%ebp
801034cc:	57                   	push   %edi
801034cd:	56                   	push   %esi
801034ce:	53                   	push   %ebx
801034cf:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801034d2:	e8 7a fe ff ff       	call   80103351 <myproc>
801034d7:	89 c3                	mov    %eax,%ebx
  if ((np = allocproc()) == 0)
801034d9:	e8 de fc ff ff       	call   801031bc <allocproc>
801034de:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801034e1:	85 c0                	test   %eax,%eax
801034e3:	0f 84 e0 00 00 00    	je     801035c9 <fork+0x100>
801034e9:	89 c7                	mov    %eax,%edi
  if ((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0)
801034eb:	83 ec 08             	sub    $0x8,%esp
801034ee:	ff 33                	pushl  (%ebx)
801034f0:	ff 73 04             	pushl  0x4(%ebx)
801034f3:	e8 bb 2f 00 00       	call   801064b3 <copyuvm>
801034f8:	89 47 04             	mov    %eax,0x4(%edi)
801034fb:	83 c4 10             	add    $0x10,%esp
801034fe:	85 c0                	test   %eax,%eax
80103500:	74 2a                	je     8010352c <fork+0x63>
  np->sz = curproc->sz;
80103502:	8b 03                	mov    (%ebx),%eax
80103504:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80103507:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
80103509:	89 c8                	mov    %ecx,%eax
8010350b:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
8010350e:	8b 73 18             	mov    0x18(%ebx),%esi
80103511:	8b 79 18             	mov    0x18(%ecx),%edi
80103514:	b9 13 00 00 00       	mov    $0x13,%ecx
80103519:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
8010351b:	8b 40 18             	mov    0x18(%eax),%eax
8010351e:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for (i = 0; i < NOFILE; i++)
80103525:	be 00 00 00 00       	mov    $0x0,%esi
8010352a:	eb 29                	jmp    80103555 <fork+0x8c>
    kfree(np->kstack);
8010352c:	83 ec 0c             	sub    $0xc,%esp
8010352f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80103532:	ff 73 08             	pushl  0x8(%ebx)
80103535:	e8 7e ea ff ff       	call   80101fb8 <kfree>
    np->kstack = 0;
8010353a:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
80103541:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103548:	83 c4 10             	add    $0x10,%esp
8010354b:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103550:	eb 6d                	jmp    801035bf <fork+0xf6>
  for (i = 0; i < NOFILE; i++)
80103552:	83 c6 01             	add    $0x1,%esi
80103555:	83 fe 0f             	cmp    $0xf,%esi
80103558:	7f 1d                	jg     80103577 <fork+0xae>
    if (curproc->ofile[i])
8010355a:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
8010355e:	85 c0                	test   %eax,%eax
80103560:	74 f0                	je     80103552 <fork+0x89>
      np->ofile[i] = filedup(curproc->ofile[i]);
80103562:	83 ec 0c             	sub    $0xc,%esp
80103565:	50                   	push   %eax
80103566:	e8 23 d7 ff ff       	call   80100c8e <filedup>
8010356b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010356e:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
80103572:	83 c4 10             	add    $0x10,%esp
80103575:	eb db                	jmp    80103552 <fork+0x89>
  np->cwd = idup(curproc->cwd);
80103577:	83 ec 0c             	sub    $0xc,%esp
8010357a:	ff 73 68             	pushl  0x68(%ebx)
8010357d:	e8 cf df ff ff       	call   80101551 <idup>
80103582:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103585:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103588:	83 c3 6c             	add    $0x6c,%ebx
8010358b:	8d 47 6c             	lea    0x6c(%edi),%eax
8010358e:	83 c4 0c             	add    $0xc,%esp
80103591:	6a 10                	push   $0x10
80103593:	53                   	push   %ebx
80103594:	50                   	push   %eax
80103595:	e8 d5 09 00 00       	call   80103f6f <safestrcpy>
  pid = np->pid;
8010359a:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
8010359d:	c7 04 24 40 2d 12 80 	movl   $0x80122d40,(%esp)
801035a4:	e8 b3 07 00 00       	call   80103d5c <acquire>
  np->state = RUNNABLE;
801035a9:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
801035b0:	c7 04 24 40 2d 12 80 	movl   $0x80122d40,(%esp)
801035b7:	e8 05 08 00 00       	call   80103dc1 <release>
  return pid;
801035bc:	83 c4 10             	add    $0x10,%esp
}
801035bf:	89 d8                	mov    %ebx,%eax
801035c1:	8d 65 f4             	lea    -0xc(%ebp),%esp
801035c4:	5b                   	pop    %ebx
801035c5:	5e                   	pop    %esi
801035c6:	5f                   	pop    %edi
801035c7:	5d                   	pop    %ebp
801035c8:	c3                   	ret    
    return -1;
801035c9:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801035ce:	eb ef                	jmp    801035bf <fork+0xf6>

801035d0 <scheduler>:
{
801035d0:	55                   	push   %ebp
801035d1:	89 e5                	mov    %esp,%ebp
801035d3:	56                   	push   %esi
801035d4:	53                   	push   %ebx
  struct cpu *c = mycpu();
801035d5:	e8 00 fd ff ff       	call   801032da <mycpu>
801035da:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801035dc:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801035e3:	00 00 00 
801035e6:	eb 5a                	jmp    80103642 <scheduler+0x72>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801035e8:	83 c3 7c             	add    $0x7c,%ebx
801035eb:	81 fb 74 4c 12 80    	cmp    $0x80124c74,%ebx
801035f1:	73 3f                	jae    80103632 <scheduler+0x62>
      if (p->state != RUNNABLE)
801035f3:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
801035f7:	75 ef                	jne    801035e8 <scheduler+0x18>
      c->proc = p;
801035f9:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801035ff:	83 ec 0c             	sub    $0xc,%esp
80103602:	53                   	push   %ebx
80103603:	e8 ed 29 00 00       	call   80105ff5 <switchuvm>
      p->state = RUNNING;
80103608:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
8010360f:	83 c4 08             	add    $0x8,%esp
80103612:	ff 73 1c             	pushl  0x1c(%ebx)
80103615:	8d 46 04             	lea    0x4(%esi),%eax
80103618:	50                   	push   %eax
80103619:	e8 a4 09 00 00       	call   80103fc2 <swtch>
      switchkvm();
8010361e:	e8 c0 29 00 00       	call   80105fe3 <switchkvm>
      c->proc = 0;
80103623:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
8010362a:	00 00 00 
8010362d:	83 c4 10             	add    $0x10,%esp
80103630:	eb b6                	jmp    801035e8 <scheduler+0x18>
    release(&ptable.lock);
80103632:	83 ec 0c             	sub    $0xc,%esp
80103635:	68 40 2d 12 80       	push   $0x80122d40
8010363a:	e8 82 07 00 00       	call   80103dc1 <release>
    sti();
8010363f:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
80103642:	fb                   	sti    
    acquire(&ptable.lock);
80103643:	83 ec 0c             	sub    $0xc,%esp
80103646:	68 40 2d 12 80       	push   $0x80122d40
8010364b:	e8 0c 07 00 00       	call   80103d5c <acquire>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103650:	83 c4 10             	add    $0x10,%esp
80103653:	bb 74 2d 12 80       	mov    $0x80122d74,%ebx
80103658:	eb 91                	jmp    801035eb <scheduler+0x1b>

8010365a <sched>:
{
8010365a:	55                   	push   %ebp
8010365b:	89 e5                	mov    %esp,%ebp
8010365d:	56                   	push   %esi
8010365e:	53                   	push   %ebx
  struct proc *p = myproc();
8010365f:	e8 ed fc ff ff       	call   80103351 <myproc>
80103664:	89 c3                	mov    %eax,%ebx
  if (!holding(&ptable.lock))
80103666:	83 ec 0c             	sub    $0xc,%esp
80103669:	68 40 2d 12 80       	push   $0x80122d40
8010366e:	e8 a9 06 00 00       	call   80103d1c <holding>
80103673:	83 c4 10             	add    $0x10,%esp
80103676:	85 c0                	test   %eax,%eax
80103678:	74 4f                	je     801036c9 <sched+0x6f>
  if (mycpu()->ncli != 1)
8010367a:	e8 5b fc ff ff       	call   801032da <mycpu>
8010367f:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
80103686:	75 4e                	jne    801036d6 <sched+0x7c>
  if (p->state == RUNNING)
80103688:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
8010368c:	74 55                	je     801036e3 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010368e:	9c                   	pushf  
8010368f:	58                   	pop    %eax
  if (readeflags() & FL_IF)
80103690:	f6 c4 02             	test   $0x2,%ah
80103693:	75 5b                	jne    801036f0 <sched+0x96>
  intena = mycpu()->intena;
80103695:	e8 40 fc ff ff       	call   801032da <mycpu>
8010369a:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
801036a0:	e8 35 fc ff ff       	call   801032da <mycpu>
801036a5:	83 ec 08             	sub    $0x8,%esp
801036a8:	ff 70 04             	pushl  0x4(%eax)
801036ab:	83 c3 1c             	add    $0x1c,%ebx
801036ae:	53                   	push   %ebx
801036af:	e8 0e 09 00 00       	call   80103fc2 <swtch>
  mycpu()->intena = intena;
801036b4:	e8 21 fc ff ff       	call   801032da <mycpu>
801036b9:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
801036bf:	83 c4 10             	add    $0x10,%esp
801036c2:	8d 65 f8             	lea    -0x8(%ebp),%esp
801036c5:	5b                   	pop    %ebx
801036c6:	5e                   	pop    %esi
801036c7:	5d                   	pop    %ebp
801036c8:	c3                   	ret    
    panic("sched ptable.lock");
801036c9:	83 ec 0c             	sub    $0xc,%esp
801036cc:	68 f0 6b 10 80       	push   $0x80106bf0
801036d1:	e8 72 cc ff ff       	call   80100348 <panic>
    panic("sched locks");
801036d6:	83 ec 0c             	sub    $0xc,%esp
801036d9:	68 02 6c 10 80       	push   $0x80106c02
801036de:	e8 65 cc ff ff       	call   80100348 <panic>
    panic("sched running");
801036e3:	83 ec 0c             	sub    $0xc,%esp
801036e6:	68 0e 6c 10 80       	push   $0x80106c0e
801036eb:	e8 58 cc ff ff       	call   80100348 <panic>
    panic("sched interruptible");
801036f0:	83 ec 0c             	sub    $0xc,%esp
801036f3:	68 1c 6c 10 80       	push   $0x80106c1c
801036f8:	e8 4b cc ff ff       	call   80100348 <panic>

801036fd <exit>:
{
801036fd:	55                   	push   %ebp
801036fe:	89 e5                	mov    %esp,%ebp
80103700:	56                   	push   %esi
80103701:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103702:	e8 4a fc ff ff       	call   80103351 <myproc>
  if (curproc == initproc)
80103707:	39 05 b8 a5 10 80    	cmp    %eax,0x8010a5b8
8010370d:	74 09                	je     80103718 <exit+0x1b>
8010370f:	89 c6                	mov    %eax,%esi
  for (fd = 0; fd < NOFILE; fd++)
80103711:	bb 00 00 00 00       	mov    $0x0,%ebx
80103716:	eb 10                	jmp    80103728 <exit+0x2b>
    panic("init exiting");
80103718:	83 ec 0c             	sub    $0xc,%esp
8010371b:	68 30 6c 10 80       	push   $0x80106c30
80103720:	e8 23 cc ff ff       	call   80100348 <panic>
  for (fd = 0; fd < NOFILE; fd++)
80103725:	83 c3 01             	add    $0x1,%ebx
80103728:	83 fb 0f             	cmp    $0xf,%ebx
8010372b:	7f 1e                	jg     8010374b <exit+0x4e>
    if (curproc->ofile[fd])
8010372d:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
80103731:	85 c0                	test   %eax,%eax
80103733:	74 f0                	je     80103725 <exit+0x28>
      fileclose(curproc->ofile[fd]);
80103735:	83 ec 0c             	sub    $0xc,%esp
80103738:	50                   	push   %eax
80103739:	e8 95 d5 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
8010373e:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103745:	00 
80103746:	83 c4 10             	add    $0x10,%esp
80103749:	eb da                	jmp    80103725 <exit+0x28>
  begin_op();
8010374b:	e8 b9 f1 ff ff       	call   80102909 <begin_op>
  iput(curproc->cwd);
80103750:	83 ec 0c             	sub    $0xc,%esp
80103753:	ff 76 68             	pushl  0x68(%esi)
80103756:	e8 2d df ff ff       	call   80101688 <iput>
  end_op();
8010375b:	e8 23 f2 ff ff       	call   80102983 <end_op>
  curproc->cwd = 0;
80103760:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103767:	c7 04 24 40 2d 12 80 	movl   $0x80122d40,(%esp)
8010376e:	e8 e9 05 00 00       	call   80103d5c <acquire>
  wakeup1(curproc->parent);
80103773:	8b 46 14             	mov    0x14(%esi),%eax
80103776:	e8 16 fa ff ff       	call   80103191 <wakeup1>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010377b:	83 c4 10             	add    $0x10,%esp
8010377e:	bb 74 2d 12 80       	mov    $0x80122d74,%ebx
80103783:	eb 03                	jmp    80103788 <exit+0x8b>
80103785:	83 c3 7c             	add    $0x7c,%ebx
80103788:	81 fb 74 4c 12 80    	cmp    $0x80124c74,%ebx
8010378e:	73 1a                	jae    801037aa <exit+0xad>
    if (p->parent == curproc)
80103790:	39 73 14             	cmp    %esi,0x14(%ebx)
80103793:	75 f0                	jne    80103785 <exit+0x88>
      p->parent = initproc;
80103795:	a1 b8 a5 10 80       	mov    0x8010a5b8,%eax
8010379a:	89 43 14             	mov    %eax,0x14(%ebx)
      if (p->state == ZOMBIE)
8010379d:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801037a1:	75 e2                	jne    80103785 <exit+0x88>
        wakeup1(initproc);
801037a3:	e8 e9 f9 ff ff       	call   80103191 <wakeup1>
801037a8:	eb db                	jmp    80103785 <exit+0x88>
  curproc->state = ZOMBIE;
801037aa:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
801037b1:	e8 a4 fe ff ff       	call   8010365a <sched>
  panic("zombie exit");
801037b6:	83 ec 0c             	sub    $0xc,%esp
801037b9:	68 3d 6c 10 80       	push   $0x80106c3d
801037be:	e8 85 cb ff ff       	call   80100348 <panic>

801037c3 <yield>:
{
801037c3:	55                   	push   %ebp
801037c4:	89 e5                	mov    %esp,%ebp
801037c6:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock); //DOC: yieldlock
801037c9:	68 40 2d 12 80       	push   $0x80122d40
801037ce:	e8 89 05 00 00       	call   80103d5c <acquire>
  myproc()->state = RUNNABLE;
801037d3:	e8 79 fb ff ff       	call   80103351 <myproc>
801037d8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801037df:	e8 76 fe ff ff       	call   8010365a <sched>
  release(&ptable.lock);
801037e4:	c7 04 24 40 2d 12 80 	movl   $0x80122d40,(%esp)
801037eb:	e8 d1 05 00 00       	call   80103dc1 <release>
}
801037f0:	83 c4 10             	add    $0x10,%esp
801037f3:	c9                   	leave  
801037f4:	c3                   	ret    

801037f5 <sleep>:
{
801037f5:	55                   	push   %ebp
801037f6:	89 e5                	mov    %esp,%ebp
801037f8:	56                   	push   %esi
801037f9:	53                   	push   %ebx
801037fa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
801037fd:	e8 4f fb ff ff       	call   80103351 <myproc>
  if (p == 0)
80103802:	85 c0                	test   %eax,%eax
80103804:	74 66                	je     8010386c <sleep+0x77>
80103806:	89 c6                	mov    %eax,%esi
  if (lk == 0)
80103808:	85 db                	test   %ebx,%ebx
8010380a:	74 6d                	je     80103879 <sleep+0x84>
  if (lk != &ptable.lock)
8010380c:	81 fb 40 2d 12 80    	cmp    $0x80122d40,%ebx
80103812:	74 18                	je     8010382c <sleep+0x37>
    acquire(&ptable.lock); //DOC: sleeplock1
80103814:	83 ec 0c             	sub    $0xc,%esp
80103817:	68 40 2d 12 80       	push   $0x80122d40
8010381c:	e8 3b 05 00 00       	call   80103d5c <acquire>
    release(lk);
80103821:	89 1c 24             	mov    %ebx,(%esp)
80103824:	e8 98 05 00 00       	call   80103dc1 <release>
80103829:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
8010382c:	8b 45 08             	mov    0x8(%ebp),%eax
8010382f:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
80103832:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
80103839:	e8 1c fe ff ff       	call   8010365a <sched>
  p->chan = 0;
8010383e:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if (lk != &ptable.lock)
80103845:	81 fb 40 2d 12 80    	cmp    $0x80122d40,%ebx
8010384b:	74 18                	je     80103865 <sleep+0x70>
    release(&ptable.lock);
8010384d:	83 ec 0c             	sub    $0xc,%esp
80103850:	68 40 2d 12 80       	push   $0x80122d40
80103855:	e8 67 05 00 00       	call   80103dc1 <release>
    acquire(lk);
8010385a:	89 1c 24             	mov    %ebx,(%esp)
8010385d:	e8 fa 04 00 00       	call   80103d5c <acquire>
80103862:	83 c4 10             	add    $0x10,%esp
}
80103865:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103868:	5b                   	pop    %ebx
80103869:	5e                   	pop    %esi
8010386a:	5d                   	pop    %ebp
8010386b:	c3                   	ret    
    panic("sleep");
8010386c:	83 ec 0c             	sub    $0xc,%esp
8010386f:	68 49 6c 10 80       	push   $0x80106c49
80103874:	e8 cf ca ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103879:	83 ec 0c             	sub    $0xc,%esp
8010387c:	68 4f 6c 10 80       	push   $0x80106c4f
80103881:	e8 c2 ca ff ff       	call   80100348 <panic>

80103886 <wait>:
{
80103886:	55                   	push   %ebp
80103887:	89 e5                	mov    %esp,%ebp
80103889:	56                   	push   %esi
8010388a:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010388b:	e8 c1 fa ff ff       	call   80103351 <myproc>
80103890:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
80103892:	83 ec 0c             	sub    $0xc,%esp
80103895:	68 40 2d 12 80       	push   $0x80122d40
8010389a:	e8 bd 04 00 00       	call   80103d5c <acquire>
8010389f:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
801038a2:	b8 00 00 00 00       	mov    $0x0,%eax
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801038a7:	bb 74 2d 12 80       	mov    $0x80122d74,%ebx
801038ac:	eb 5b                	jmp    80103909 <wait+0x83>
        pid = p->pid;
801038ae:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
801038b1:	83 ec 0c             	sub    $0xc,%esp
801038b4:	ff 73 08             	pushl  0x8(%ebx)
801038b7:	e8 fc e6 ff ff       	call   80101fb8 <kfree>
        p->kstack = 0;
801038bc:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
801038c3:	83 c4 04             	add    $0x4,%esp
801038c6:	ff 73 04             	pushl  0x4(%ebx)
801038c9:	e8 c4 2a 00 00       	call   80106392 <freevm>
        p->pid = 0;
801038ce:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
801038d5:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
801038dc:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
801038e0:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
801038e7:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
801038ee:	c7 04 24 40 2d 12 80 	movl   $0x80122d40,(%esp)
801038f5:	e8 c7 04 00 00       	call   80103dc1 <release>
        return pid;
801038fa:	83 c4 10             	add    $0x10,%esp
}
801038fd:	89 f0                	mov    %esi,%eax
801038ff:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103902:	5b                   	pop    %ebx
80103903:	5e                   	pop    %esi
80103904:	5d                   	pop    %ebp
80103905:	c3                   	ret    
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103906:	83 c3 7c             	add    $0x7c,%ebx
80103909:	81 fb 74 4c 12 80    	cmp    $0x80124c74,%ebx
8010390f:	73 12                	jae    80103923 <wait+0x9d>
      if (p->parent != curproc)
80103911:	39 73 14             	cmp    %esi,0x14(%ebx)
80103914:	75 f0                	jne    80103906 <wait+0x80>
      if (p->state == ZOMBIE)
80103916:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010391a:	74 92                	je     801038ae <wait+0x28>
      havekids = 1;
8010391c:	b8 01 00 00 00       	mov    $0x1,%eax
80103921:	eb e3                	jmp    80103906 <wait+0x80>
    if (!havekids || curproc->killed)
80103923:	85 c0                	test   %eax,%eax
80103925:	74 06                	je     8010392d <wait+0xa7>
80103927:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
8010392b:	74 17                	je     80103944 <wait+0xbe>
      release(&ptable.lock);
8010392d:	83 ec 0c             	sub    $0xc,%esp
80103930:	68 40 2d 12 80       	push   $0x80122d40
80103935:	e8 87 04 00 00       	call   80103dc1 <release>
      return -1;
8010393a:	83 c4 10             	add    $0x10,%esp
8010393d:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103942:	eb b9                	jmp    801038fd <wait+0x77>
    sleep(curproc, &ptable.lock); //DOC: wait-sleep
80103944:	83 ec 08             	sub    $0x8,%esp
80103947:	68 40 2d 12 80       	push   $0x80122d40
8010394c:	56                   	push   %esi
8010394d:	e8 a3 fe ff ff       	call   801037f5 <sleep>
    havekids = 0;
80103952:	83 c4 10             	add    $0x10,%esp
80103955:	e9 48 ff ff ff       	jmp    801038a2 <wait+0x1c>

8010395a <wakeup>:

// Wake up all processes sleeping on chan.
void wakeup(void *chan)
{
8010395a:	55                   	push   %ebp
8010395b:	89 e5                	mov    %esp,%ebp
8010395d:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103960:	68 40 2d 12 80       	push   $0x80122d40
80103965:	e8 f2 03 00 00       	call   80103d5c <acquire>
  wakeup1(chan);
8010396a:	8b 45 08             	mov    0x8(%ebp),%eax
8010396d:	e8 1f f8 ff ff       	call   80103191 <wakeup1>
  release(&ptable.lock);
80103972:	c7 04 24 40 2d 12 80 	movl   $0x80122d40,(%esp)
80103979:	e8 43 04 00 00       	call   80103dc1 <release>
}
8010397e:	83 c4 10             	add    $0x10,%esp
80103981:	c9                   	leave  
80103982:	c3                   	ret    

80103983 <kill>:

// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int kill(int pid)
{
80103983:	55                   	push   %ebp
80103984:	89 e5                	mov    %esp,%ebp
80103986:	53                   	push   %ebx
80103987:	83 ec 10             	sub    $0x10,%esp
8010398a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
8010398d:	68 40 2d 12 80       	push   $0x80122d40
80103992:	e8 c5 03 00 00       	call   80103d5c <acquire>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103997:	83 c4 10             	add    $0x10,%esp
8010399a:	b8 74 2d 12 80       	mov    $0x80122d74,%eax
8010399f:	3d 74 4c 12 80       	cmp    $0x80124c74,%eax
801039a4:	73 3a                	jae    801039e0 <kill+0x5d>
  {
    if (p->pid == pid)
801039a6:	39 58 10             	cmp    %ebx,0x10(%eax)
801039a9:	74 05                	je     801039b0 <kill+0x2d>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801039ab:	83 c0 7c             	add    $0x7c,%eax
801039ae:	eb ef                	jmp    8010399f <kill+0x1c>
    {
      p->killed = 1;
801039b0:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if (p->state == SLEEPING)
801039b7:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
801039bb:	74 1a                	je     801039d7 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
801039bd:	83 ec 0c             	sub    $0xc,%esp
801039c0:	68 40 2d 12 80       	push   $0x80122d40
801039c5:	e8 f7 03 00 00       	call   80103dc1 <release>
      return 0;
801039ca:	83 c4 10             	add    $0x10,%esp
801039cd:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
801039d2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801039d5:	c9                   	leave  
801039d6:	c3                   	ret    
        p->state = RUNNABLE;
801039d7:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
801039de:	eb dd                	jmp    801039bd <kill+0x3a>
  release(&ptable.lock);
801039e0:	83 ec 0c             	sub    $0xc,%esp
801039e3:	68 40 2d 12 80       	push   $0x80122d40
801039e8:	e8 d4 03 00 00       	call   80103dc1 <release>
  return -1;
801039ed:	83 c4 10             	add    $0x10,%esp
801039f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801039f5:	eb db                	jmp    801039d2 <kill+0x4f>

801039f7 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
801039f7:	55                   	push   %ebp
801039f8:	89 e5                	mov    %esp,%ebp
801039fa:	56                   	push   %esi
801039fb:	53                   	push   %ebx
801039fc:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801039ff:	bb 74 2d 12 80       	mov    $0x80122d74,%ebx
80103a04:	eb 33                	jmp    80103a39 <procdump+0x42>
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103a06:	b8 60 6c 10 80       	mov    $0x80106c60,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103a0b:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103a0e:	52                   	push   %edx
80103a0f:	50                   	push   %eax
80103a10:	ff 73 10             	pushl  0x10(%ebx)
80103a13:	68 64 6c 10 80       	push   $0x80106c64
80103a18:	e8 ee cb ff ff       	call   8010060b <cprintf>
    if (p->state == SLEEPING)
80103a1d:	83 c4 10             	add    $0x10,%esp
80103a20:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103a24:	74 39                	je     80103a5f <procdump+0x68>
    {
      getcallerpcs((uint *)p->context->ebp + 2, pc);
      for (i = 0; i < 10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103a26:	83 ec 0c             	sub    $0xc,%esp
80103a29:	68 db 6f 10 80       	push   $0x80106fdb
80103a2e:	e8 d8 cb ff ff       	call   8010060b <cprintf>
80103a33:	83 c4 10             	add    $0x10,%esp
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103a36:	83 c3 7c             	add    $0x7c,%ebx
80103a39:	81 fb 74 4c 12 80    	cmp    $0x80124c74,%ebx
80103a3f:	73 61                	jae    80103aa2 <procdump+0xab>
    if (p->state == UNUSED)
80103a41:	8b 43 0c             	mov    0xc(%ebx),%eax
80103a44:	85 c0                	test   %eax,%eax
80103a46:	74 ee                	je     80103a36 <procdump+0x3f>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103a48:	83 f8 05             	cmp    $0x5,%eax
80103a4b:	77 b9                	ja     80103a06 <procdump+0xf>
80103a4d:	8b 04 85 c0 6c 10 80 	mov    -0x7fef9340(,%eax,4),%eax
80103a54:	85 c0                	test   %eax,%eax
80103a56:	75 b3                	jne    80103a0b <procdump+0x14>
      state = "???";
80103a58:	b8 60 6c 10 80       	mov    $0x80106c60,%eax
80103a5d:	eb ac                	jmp    80103a0b <procdump+0x14>
      getcallerpcs((uint *)p->context->ebp + 2, pc);
80103a5f:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103a62:	8b 40 0c             	mov    0xc(%eax),%eax
80103a65:	83 c0 08             	add    $0x8,%eax
80103a68:	83 ec 08             	sub    $0x8,%esp
80103a6b:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103a6e:	52                   	push   %edx
80103a6f:	50                   	push   %eax
80103a70:	e8 c6 01 00 00       	call   80103c3b <getcallerpcs>
      for (i = 0; i < 10 && pc[i] != 0; i++)
80103a75:	83 c4 10             	add    $0x10,%esp
80103a78:	be 00 00 00 00       	mov    $0x0,%esi
80103a7d:	eb 14                	jmp    80103a93 <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103a7f:	83 ec 08             	sub    $0x8,%esp
80103a82:	50                   	push   %eax
80103a83:	68 a1 66 10 80       	push   $0x801066a1
80103a88:	e8 7e cb ff ff       	call   8010060b <cprintf>
      for (i = 0; i < 10 && pc[i] != 0; i++)
80103a8d:	83 c6 01             	add    $0x1,%esi
80103a90:	83 c4 10             	add    $0x10,%esp
80103a93:	83 fe 09             	cmp    $0x9,%esi
80103a96:	7f 8e                	jg     80103a26 <procdump+0x2f>
80103a98:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103a9c:	85 c0                	test   %eax,%eax
80103a9e:	75 df                	jne    80103a7f <procdump+0x88>
80103aa0:	eb 84                	jmp    80103a26 <procdump+0x2f>
  }
}
80103aa2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103aa5:	5b                   	pop    %ebx
80103aa6:	5e                   	pop    %esi
80103aa7:	5d                   	pop    %ebp
80103aa8:	c3                   	ret    

80103aa9 <dump_physmem>:

int dump_physmem(int *frames, int *pids, int numframes)
{
80103aa9:	55                   	push   %ebp
80103aaa:	89 e5                	mov    %esp,%ebp
80103aac:	57                   	push   %edi
80103aad:	56                   	push   %esi
80103aae:	53                   	push   %ebx
80103aaf:	83 ec 0c             	sub    $0xc,%esp
80103ab2:	8b 75 08             	mov    0x8(%ebp),%esi
80103ab5:	8b 7d 0c             	mov    0xc(%ebp),%edi
80103ab8:	8b 5d 10             	mov    0x10(%ebp),%ebx
  if(numframes == 0 || frames == 0 || pids == 0) {
80103abb:	85 db                	test   %ebx,%ebx
80103abd:	0f 94 c2             	sete   %dl
80103ac0:	85 f6                	test   %esi,%esi
80103ac2:	0f 94 c0             	sete   %al
80103ac5:	08 c2                	or     %al,%dl
80103ac7:	75 3e                	jne    80103b07 <dump_physmem+0x5e>
80103ac9:	85 ff                	test   %edi,%edi
80103acb:	74 41                	je     80103b0e <dump_physmem+0x65>
    return -1;
  }
  int* framesList = getframesList();
80103acd:	e8 d2 e4 ff ff       	call   80101fa4 <getframesList>
  for (int i = 0; i < numframes; i++) {
80103ad2:	ba 00 00 00 00       	mov    $0x0,%edx
80103ad7:	89 7d 0c             	mov    %edi,0xc(%ebp)
80103ada:	eb 1a                	jmp    80103af6 <dump_physmem+0x4d>
    frames[i] = framesList[i];
80103adc:	8d 0c 95 00 00 00 00 	lea    0x0(,%edx,4),%ecx
80103ae3:	8b 3c 90             	mov    (%eax,%edx,4),%edi
80103ae6:	89 3c 0e             	mov    %edi,(%esi,%ecx,1)
    pids[i] = -2;
80103ae9:	8b 7d 0c             	mov    0xc(%ebp),%edi
80103aec:	c7 04 0f fe ff ff ff 	movl   $0xfffffffe,(%edi,%ecx,1)
  for (int i = 0; i < numframes; i++) {
80103af3:	83 c2 01             	add    $0x1,%edx
80103af6:	39 da                	cmp    %ebx,%edx
80103af8:	7c e2                	jl     80103adc <dump_physmem+0x33>
  }
  return 0;
80103afa:	b8 00 00 00 00       	mov    $0x0,%eax
80103aff:	83 c4 0c             	add    $0xc,%esp
80103b02:	5b                   	pop    %ebx
80103b03:	5e                   	pop    %esi
80103b04:	5f                   	pop    %edi
80103b05:	5d                   	pop    %ebp
80103b06:	c3                   	ret    
    return -1;
80103b07:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103b0c:	eb f1                	jmp    80103aff <dump_physmem+0x56>
80103b0e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103b13:	eb ea                	jmp    80103aff <dump_physmem+0x56>

80103b15 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103b15:	55                   	push   %ebp
80103b16:	89 e5                	mov    %esp,%ebp
80103b18:	53                   	push   %ebx
80103b19:	83 ec 0c             	sub    $0xc,%esp
80103b1c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103b1f:	68 d8 6c 10 80       	push   $0x80106cd8
80103b24:	8d 43 04             	lea    0x4(%ebx),%eax
80103b27:	50                   	push   %eax
80103b28:	e8 f3 00 00 00       	call   80103c20 <initlock>
  lk->name = name;
80103b2d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103b30:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103b33:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103b39:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103b40:	83 c4 10             	add    $0x10,%esp
80103b43:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103b46:	c9                   	leave  
80103b47:	c3                   	ret    

80103b48 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103b48:	55                   	push   %ebp
80103b49:	89 e5                	mov    %esp,%ebp
80103b4b:	56                   	push   %esi
80103b4c:	53                   	push   %ebx
80103b4d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103b50:	8d 73 04             	lea    0x4(%ebx),%esi
80103b53:	83 ec 0c             	sub    $0xc,%esp
80103b56:	56                   	push   %esi
80103b57:	e8 00 02 00 00       	call   80103d5c <acquire>
  while (lk->locked) {
80103b5c:	83 c4 10             	add    $0x10,%esp
80103b5f:	eb 0d                	jmp    80103b6e <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103b61:	83 ec 08             	sub    $0x8,%esp
80103b64:	56                   	push   %esi
80103b65:	53                   	push   %ebx
80103b66:	e8 8a fc ff ff       	call   801037f5 <sleep>
80103b6b:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103b6e:	83 3b 00             	cmpl   $0x0,(%ebx)
80103b71:	75 ee                	jne    80103b61 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103b73:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103b79:	e8 d3 f7 ff ff       	call   80103351 <myproc>
80103b7e:	8b 40 10             	mov    0x10(%eax),%eax
80103b81:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103b84:	83 ec 0c             	sub    $0xc,%esp
80103b87:	56                   	push   %esi
80103b88:	e8 34 02 00 00       	call   80103dc1 <release>
}
80103b8d:	83 c4 10             	add    $0x10,%esp
80103b90:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b93:	5b                   	pop    %ebx
80103b94:	5e                   	pop    %esi
80103b95:	5d                   	pop    %ebp
80103b96:	c3                   	ret    

80103b97 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103b97:	55                   	push   %ebp
80103b98:	89 e5                	mov    %esp,%ebp
80103b9a:	56                   	push   %esi
80103b9b:	53                   	push   %ebx
80103b9c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103b9f:	8d 73 04             	lea    0x4(%ebx),%esi
80103ba2:	83 ec 0c             	sub    $0xc,%esp
80103ba5:	56                   	push   %esi
80103ba6:	e8 b1 01 00 00       	call   80103d5c <acquire>
  lk->locked = 0;
80103bab:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103bb1:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103bb8:	89 1c 24             	mov    %ebx,(%esp)
80103bbb:	e8 9a fd ff ff       	call   8010395a <wakeup>
  release(&lk->lk);
80103bc0:	89 34 24             	mov    %esi,(%esp)
80103bc3:	e8 f9 01 00 00       	call   80103dc1 <release>
}
80103bc8:	83 c4 10             	add    $0x10,%esp
80103bcb:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103bce:	5b                   	pop    %ebx
80103bcf:	5e                   	pop    %esi
80103bd0:	5d                   	pop    %ebp
80103bd1:	c3                   	ret    

80103bd2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103bd2:	55                   	push   %ebp
80103bd3:	89 e5                	mov    %esp,%ebp
80103bd5:	56                   	push   %esi
80103bd6:	53                   	push   %ebx
80103bd7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103bda:	8d 73 04             	lea    0x4(%ebx),%esi
80103bdd:	83 ec 0c             	sub    $0xc,%esp
80103be0:	56                   	push   %esi
80103be1:	e8 76 01 00 00       	call   80103d5c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103be6:	83 c4 10             	add    $0x10,%esp
80103be9:	83 3b 00             	cmpl   $0x0,(%ebx)
80103bec:	75 17                	jne    80103c05 <holdingsleep+0x33>
80103bee:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103bf3:	83 ec 0c             	sub    $0xc,%esp
80103bf6:	56                   	push   %esi
80103bf7:	e8 c5 01 00 00       	call   80103dc1 <release>
  return r;
}
80103bfc:	89 d8                	mov    %ebx,%eax
80103bfe:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c01:	5b                   	pop    %ebx
80103c02:	5e                   	pop    %esi
80103c03:	5d                   	pop    %ebp
80103c04:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103c05:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103c08:	e8 44 f7 ff ff       	call   80103351 <myproc>
80103c0d:	3b 58 10             	cmp    0x10(%eax),%ebx
80103c10:	74 07                	je     80103c19 <holdingsleep+0x47>
80103c12:	bb 00 00 00 00       	mov    $0x0,%ebx
80103c17:	eb da                	jmp    80103bf3 <holdingsleep+0x21>
80103c19:	bb 01 00 00 00       	mov    $0x1,%ebx
80103c1e:	eb d3                	jmp    80103bf3 <holdingsleep+0x21>

80103c20 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103c20:	55                   	push   %ebp
80103c21:	89 e5                	mov    %esp,%ebp
80103c23:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103c26:	8b 55 0c             	mov    0xc(%ebp),%edx
80103c29:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103c2c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103c32:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103c39:	5d                   	pop    %ebp
80103c3a:	c3                   	ret    

80103c3b <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103c3b:	55                   	push   %ebp
80103c3c:	89 e5                	mov    %esp,%ebp
80103c3e:	53                   	push   %ebx
80103c3f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103c42:	8b 45 08             	mov    0x8(%ebp),%eax
80103c45:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103c48:	b8 00 00 00 00       	mov    $0x0,%eax
80103c4d:	83 f8 09             	cmp    $0x9,%eax
80103c50:	7f 25                	jg     80103c77 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103c52:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103c58:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103c5e:	77 17                	ja     80103c77 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103c60:	8b 5a 04             	mov    0x4(%edx),%ebx
80103c63:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103c66:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103c68:	83 c0 01             	add    $0x1,%eax
80103c6b:	eb e0                	jmp    80103c4d <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103c6d:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103c74:	83 c0 01             	add    $0x1,%eax
80103c77:	83 f8 09             	cmp    $0x9,%eax
80103c7a:	7e f1                	jle    80103c6d <getcallerpcs+0x32>
}
80103c7c:	5b                   	pop    %ebx
80103c7d:	5d                   	pop    %ebp
80103c7e:	c3                   	ret    

80103c7f <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103c7f:	55                   	push   %ebp
80103c80:	89 e5                	mov    %esp,%ebp
80103c82:	53                   	push   %ebx
80103c83:	83 ec 04             	sub    $0x4,%esp
80103c86:	9c                   	pushf  
80103c87:	5b                   	pop    %ebx
  asm volatile("cli");
80103c88:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103c89:	e8 4c f6 ff ff       	call   801032da <mycpu>
80103c8e:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c95:	74 12                	je     80103ca9 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103c97:	e8 3e f6 ff ff       	call   801032da <mycpu>
80103c9c:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103ca3:	83 c4 04             	add    $0x4,%esp
80103ca6:	5b                   	pop    %ebx
80103ca7:	5d                   	pop    %ebp
80103ca8:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103ca9:	e8 2c f6 ff ff       	call   801032da <mycpu>
80103cae:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103cb4:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103cba:	eb db                	jmp    80103c97 <pushcli+0x18>

80103cbc <popcli>:

void
popcli(void)
{
80103cbc:	55                   	push   %ebp
80103cbd:	89 e5                	mov    %esp,%ebp
80103cbf:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103cc2:	9c                   	pushf  
80103cc3:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103cc4:	f6 c4 02             	test   $0x2,%ah
80103cc7:	75 28                	jne    80103cf1 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103cc9:	e8 0c f6 ff ff       	call   801032da <mycpu>
80103cce:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103cd4:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103cd7:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103cdd:	85 d2                	test   %edx,%edx
80103cdf:	78 1d                	js     80103cfe <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103ce1:	e8 f4 f5 ff ff       	call   801032da <mycpu>
80103ce6:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103ced:	74 1c                	je     80103d0b <popcli+0x4f>
    sti();
}
80103cef:	c9                   	leave  
80103cf0:	c3                   	ret    
    panic("popcli - interruptible");
80103cf1:	83 ec 0c             	sub    $0xc,%esp
80103cf4:	68 e3 6c 10 80       	push   $0x80106ce3
80103cf9:	e8 4a c6 ff ff       	call   80100348 <panic>
    panic("popcli");
80103cfe:	83 ec 0c             	sub    $0xc,%esp
80103d01:	68 fa 6c 10 80       	push   $0x80106cfa
80103d06:	e8 3d c6 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103d0b:	e8 ca f5 ff ff       	call   801032da <mycpu>
80103d10:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103d17:	74 d6                	je     80103cef <popcli+0x33>
  asm volatile("sti");
80103d19:	fb                   	sti    
}
80103d1a:	eb d3                	jmp    80103cef <popcli+0x33>

80103d1c <holding>:
{
80103d1c:	55                   	push   %ebp
80103d1d:	89 e5                	mov    %esp,%ebp
80103d1f:	53                   	push   %ebx
80103d20:	83 ec 04             	sub    $0x4,%esp
80103d23:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103d26:	e8 54 ff ff ff       	call   80103c7f <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103d2b:	83 3b 00             	cmpl   $0x0,(%ebx)
80103d2e:	75 12                	jne    80103d42 <holding+0x26>
80103d30:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103d35:	e8 82 ff ff ff       	call   80103cbc <popcli>
}
80103d3a:	89 d8                	mov    %ebx,%eax
80103d3c:	83 c4 04             	add    $0x4,%esp
80103d3f:	5b                   	pop    %ebx
80103d40:	5d                   	pop    %ebp
80103d41:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103d42:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103d45:	e8 90 f5 ff ff       	call   801032da <mycpu>
80103d4a:	39 c3                	cmp    %eax,%ebx
80103d4c:	74 07                	je     80103d55 <holding+0x39>
80103d4e:	bb 00 00 00 00       	mov    $0x0,%ebx
80103d53:	eb e0                	jmp    80103d35 <holding+0x19>
80103d55:	bb 01 00 00 00       	mov    $0x1,%ebx
80103d5a:	eb d9                	jmp    80103d35 <holding+0x19>

80103d5c <acquire>:
{
80103d5c:	55                   	push   %ebp
80103d5d:	89 e5                	mov    %esp,%ebp
80103d5f:	53                   	push   %ebx
80103d60:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103d63:	e8 17 ff ff ff       	call   80103c7f <pushcli>
  if(holding(lk))
80103d68:	83 ec 0c             	sub    $0xc,%esp
80103d6b:	ff 75 08             	pushl  0x8(%ebp)
80103d6e:	e8 a9 ff ff ff       	call   80103d1c <holding>
80103d73:	83 c4 10             	add    $0x10,%esp
80103d76:	85 c0                	test   %eax,%eax
80103d78:	75 3a                	jne    80103db4 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103d7a:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103d7d:	b8 01 00 00 00       	mov    $0x1,%eax
80103d82:	f0 87 02             	lock xchg %eax,(%edx)
80103d85:	85 c0                	test   %eax,%eax
80103d87:	75 f1                	jne    80103d7a <acquire+0x1e>
  __sync_synchronize();
80103d89:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103d8e:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103d91:	e8 44 f5 ff ff       	call   801032da <mycpu>
80103d96:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103d99:	8b 45 08             	mov    0x8(%ebp),%eax
80103d9c:	83 c0 0c             	add    $0xc,%eax
80103d9f:	83 ec 08             	sub    $0x8,%esp
80103da2:	50                   	push   %eax
80103da3:	8d 45 08             	lea    0x8(%ebp),%eax
80103da6:	50                   	push   %eax
80103da7:	e8 8f fe ff ff       	call   80103c3b <getcallerpcs>
}
80103dac:	83 c4 10             	add    $0x10,%esp
80103daf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103db2:	c9                   	leave  
80103db3:	c3                   	ret    
    panic("acquire");
80103db4:	83 ec 0c             	sub    $0xc,%esp
80103db7:	68 01 6d 10 80       	push   $0x80106d01
80103dbc:	e8 87 c5 ff ff       	call   80100348 <panic>

80103dc1 <release>:
{
80103dc1:	55                   	push   %ebp
80103dc2:	89 e5                	mov    %esp,%ebp
80103dc4:	53                   	push   %ebx
80103dc5:	83 ec 10             	sub    $0x10,%esp
80103dc8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103dcb:	53                   	push   %ebx
80103dcc:	e8 4b ff ff ff       	call   80103d1c <holding>
80103dd1:	83 c4 10             	add    $0x10,%esp
80103dd4:	85 c0                	test   %eax,%eax
80103dd6:	74 23                	je     80103dfb <release+0x3a>
  lk->pcs[0] = 0;
80103dd8:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103ddf:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103de6:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103deb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103df1:	e8 c6 fe ff ff       	call   80103cbc <popcli>
}
80103df6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103df9:	c9                   	leave  
80103dfa:	c3                   	ret    
    panic("release");
80103dfb:	83 ec 0c             	sub    $0xc,%esp
80103dfe:	68 09 6d 10 80       	push   $0x80106d09
80103e03:	e8 40 c5 ff ff       	call   80100348 <panic>

80103e08 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103e08:	55                   	push   %ebp
80103e09:	89 e5                	mov    %esp,%ebp
80103e0b:	57                   	push   %edi
80103e0c:	53                   	push   %ebx
80103e0d:	8b 55 08             	mov    0x8(%ebp),%edx
80103e10:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103e13:	f6 c2 03             	test   $0x3,%dl
80103e16:	75 05                	jne    80103e1d <memset+0x15>
80103e18:	f6 c1 03             	test   $0x3,%cl
80103e1b:	74 0e                	je     80103e2b <memset+0x23>
  asm volatile("cld; rep stosb" :
80103e1d:	89 d7                	mov    %edx,%edi
80103e1f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e22:	fc                   	cld    
80103e23:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103e25:	89 d0                	mov    %edx,%eax
80103e27:	5b                   	pop    %ebx
80103e28:	5f                   	pop    %edi
80103e29:	5d                   	pop    %ebp
80103e2a:	c3                   	ret    
    c &= 0xFF;
80103e2b:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103e2f:	c1 e9 02             	shr    $0x2,%ecx
80103e32:	89 f8                	mov    %edi,%eax
80103e34:	c1 e0 18             	shl    $0x18,%eax
80103e37:	89 fb                	mov    %edi,%ebx
80103e39:	c1 e3 10             	shl    $0x10,%ebx
80103e3c:	09 d8                	or     %ebx,%eax
80103e3e:	89 fb                	mov    %edi,%ebx
80103e40:	c1 e3 08             	shl    $0x8,%ebx
80103e43:	09 d8                	or     %ebx,%eax
80103e45:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103e47:	89 d7                	mov    %edx,%edi
80103e49:	fc                   	cld    
80103e4a:	f3 ab                	rep stos %eax,%es:(%edi)
80103e4c:	eb d7                	jmp    80103e25 <memset+0x1d>

80103e4e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103e4e:	55                   	push   %ebp
80103e4f:	89 e5                	mov    %esp,%ebp
80103e51:	56                   	push   %esi
80103e52:	53                   	push   %ebx
80103e53:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103e56:	8b 55 0c             	mov    0xc(%ebp),%edx
80103e59:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103e5c:	8d 70 ff             	lea    -0x1(%eax),%esi
80103e5f:	85 c0                	test   %eax,%eax
80103e61:	74 1c                	je     80103e7f <memcmp+0x31>
    if(*s1 != *s2)
80103e63:	0f b6 01             	movzbl (%ecx),%eax
80103e66:	0f b6 1a             	movzbl (%edx),%ebx
80103e69:	38 d8                	cmp    %bl,%al
80103e6b:	75 0a                	jne    80103e77 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103e6d:	83 c1 01             	add    $0x1,%ecx
80103e70:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103e73:	89 f0                	mov    %esi,%eax
80103e75:	eb e5                	jmp    80103e5c <memcmp+0xe>
      return *s1 - *s2;
80103e77:	0f b6 c0             	movzbl %al,%eax
80103e7a:	0f b6 db             	movzbl %bl,%ebx
80103e7d:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103e7f:	5b                   	pop    %ebx
80103e80:	5e                   	pop    %esi
80103e81:	5d                   	pop    %ebp
80103e82:	c3                   	ret    

80103e83 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103e83:	55                   	push   %ebp
80103e84:	89 e5                	mov    %esp,%ebp
80103e86:	56                   	push   %esi
80103e87:	53                   	push   %ebx
80103e88:	8b 45 08             	mov    0x8(%ebp),%eax
80103e8b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e8e:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103e91:	39 c1                	cmp    %eax,%ecx
80103e93:	73 3a                	jae    80103ecf <memmove+0x4c>
80103e95:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103e98:	39 c3                	cmp    %eax,%ebx
80103e9a:	76 37                	jbe    80103ed3 <memmove+0x50>
    s += n;
    d += n;
80103e9c:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103e9f:	eb 0d                	jmp    80103eae <memmove+0x2b>
      *--d = *--s;
80103ea1:	83 eb 01             	sub    $0x1,%ebx
80103ea4:	83 e9 01             	sub    $0x1,%ecx
80103ea7:	0f b6 13             	movzbl (%ebx),%edx
80103eaa:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103eac:	89 f2                	mov    %esi,%edx
80103eae:	8d 72 ff             	lea    -0x1(%edx),%esi
80103eb1:	85 d2                	test   %edx,%edx
80103eb3:	75 ec                	jne    80103ea1 <memmove+0x1e>
80103eb5:	eb 14                	jmp    80103ecb <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103eb7:	0f b6 11             	movzbl (%ecx),%edx
80103eba:	88 13                	mov    %dl,(%ebx)
80103ebc:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103ebf:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103ec2:	89 f2                	mov    %esi,%edx
80103ec4:	8d 72 ff             	lea    -0x1(%edx),%esi
80103ec7:	85 d2                	test   %edx,%edx
80103ec9:	75 ec                	jne    80103eb7 <memmove+0x34>

  return dst;
}
80103ecb:	5b                   	pop    %ebx
80103ecc:	5e                   	pop    %esi
80103ecd:	5d                   	pop    %ebp
80103ece:	c3                   	ret    
80103ecf:	89 c3                	mov    %eax,%ebx
80103ed1:	eb f1                	jmp    80103ec4 <memmove+0x41>
80103ed3:	89 c3                	mov    %eax,%ebx
80103ed5:	eb ed                	jmp    80103ec4 <memmove+0x41>

80103ed7 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103ed7:	55                   	push   %ebp
80103ed8:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103eda:	ff 75 10             	pushl  0x10(%ebp)
80103edd:	ff 75 0c             	pushl  0xc(%ebp)
80103ee0:	ff 75 08             	pushl  0x8(%ebp)
80103ee3:	e8 9b ff ff ff       	call   80103e83 <memmove>
}
80103ee8:	c9                   	leave  
80103ee9:	c3                   	ret    

80103eea <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103eea:	55                   	push   %ebp
80103eeb:	89 e5                	mov    %esp,%ebp
80103eed:	53                   	push   %ebx
80103eee:	8b 55 08             	mov    0x8(%ebp),%edx
80103ef1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103ef4:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103ef7:	eb 09                	jmp    80103f02 <strncmp+0x18>
    n--, p++, q++;
80103ef9:	83 e8 01             	sub    $0x1,%eax
80103efc:	83 c2 01             	add    $0x1,%edx
80103eff:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103f02:	85 c0                	test   %eax,%eax
80103f04:	74 0b                	je     80103f11 <strncmp+0x27>
80103f06:	0f b6 1a             	movzbl (%edx),%ebx
80103f09:	84 db                	test   %bl,%bl
80103f0b:	74 04                	je     80103f11 <strncmp+0x27>
80103f0d:	3a 19                	cmp    (%ecx),%bl
80103f0f:	74 e8                	je     80103ef9 <strncmp+0xf>
  if(n == 0)
80103f11:	85 c0                	test   %eax,%eax
80103f13:	74 0b                	je     80103f20 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103f15:	0f b6 02             	movzbl (%edx),%eax
80103f18:	0f b6 11             	movzbl (%ecx),%edx
80103f1b:	29 d0                	sub    %edx,%eax
}
80103f1d:	5b                   	pop    %ebx
80103f1e:	5d                   	pop    %ebp
80103f1f:	c3                   	ret    
    return 0;
80103f20:	b8 00 00 00 00       	mov    $0x0,%eax
80103f25:	eb f6                	jmp    80103f1d <strncmp+0x33>

80103f27 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103f27:	55                   	push   %ebp
80103f28:	89 e5                	mov    %esp,%ebp
80103f2a:	57                   	push   %edi
80103f2b:	56                   	push   %esi
80103f2c:	53                   	push   %ebx
80103f2d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103f30:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103f33:	8b 45 08             	mov    0x8(%ebp),%eax
80103f36:	eb 04                	jmp    80103f3c <strncpy+0x15>
80103f38:	89 fb                	mov    %edi,%ebx
80103f3a:	89 f0                	mov    %esi,%eax
80103f3c:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103f3f:	85 c9                	test   %ecx,%ecx
80103f41:	7e 1d                	jle    80103f60 <strncpy+0x39>
80103f43:	8d 7b 01             	lea    0x1(%ebx),%edi
80103f46:	8d 70 01             	lea    0x1(%eax),%esi
80103f49:	0f b6 1b             	movzbl (%ebx),%ebx
80103f4c:	88 18                	mov    %bl,(%eax)
80103f4e:	89 d1                	mov    %edx,%ecx
80103f50:	84 db                	test   %bl,%bl
80103f52:	75 e4                	jne    80103f38 <strncpy+0x11>
80103f54:	89 f0                	mov    %esi,%eax
80103f56:	eb 08                	jmp    80103f60 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103f58:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103f5b:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103f5d:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103f60:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103f63:	85 d2                	test   %edx,%edx
80103f65:	7f f1                	jg     80103f58 <strncpy+0x31>
  return os;
}
80103f67:	8b 45 08             	mov    0x8(%ebp),%eax
80103f6a:	5b                   	pop    %ebx
80103f6b:	5e                   	pop    %esi
80103f6c:	5f                   	pop    %edi
80103f6d:	5d                   	pop    %ebp
80103f6e:	c3                   	ret    

80103f6f <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103f6f:	55                   	push   %ebp
80103f70:	89 e5                	mov    %esp,%ebp
80103f72:	57                   	push   %edi
80103f73:	56                   	push   %esi
80103f74:	53                   	push   %ebx
80103f75:	8b 45 08             	mov    0x8(%ebp),%eax
80103f78:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103f7b:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80103f7e:	85 d2                	test   %edx,%edx
80103f80:	7e 23                	jle    80103fa5 <safestrcpy+0x36>
80103f82:	89 c1                	mov    %eax,%ecx
80103f84:	eb 04                	jmp    80103f8a <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103f86:	89 fb                	mov    %edi,%ebx
80103f88:	89 f1                	mov    %esi,%ecx
80103f8a:	83 ea 01             	sub    $0x1,%edx
80103f8d:	85 d2                	test   %edx,%edx
80103f8f:	7e 11                	jle    80103fa2 <safestrcpy+0x33>
80103f91:	8d 7b 01             	lea    0x1(%ebx),%edi
80103f94:	8d 71 01             	lea    0x1(%ecx),%esi
80103f97:	0f b6 1b             	movzbl (%ebx),%ebx
80103f9a:	88 19                	mov    %bl,(%ecx)
80103f9c:	84 db                	test   %bl,%bl
80103f9e:	75 e6                	jne    80103f86 <safestrcpy+0x17>
80103fa0:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80103fa2:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80103fa5:	5b                   	pop    %ebx
80103fa6:	5e                   	pop    %esi
80103fa7:	5f                   	pop    %edi
80103fa8:	5d                   	pop    %ebp
80103fa9:	c3                   	ret    

80103faa <strlen>:

int
strlen(const char *s)
{
80103faa:	55                   	push   %ebp
80103fab:	89 e5                	mov    %esp,%ebp
80103fad:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103fb0:	b8 00 00 00 00       	mov    $0x0,%eax
80103fb5:	eb 03                	jmp    80103fba <strlen+0x10>
80103fb7:	83 c0 01             	add    $0x1,%eax
80103fba:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103fbe:	75 f7                	jne    80103fb7 <strlen+0xd>
    ;
  return n;
}
80103fc0:	5d                   	pop    %ebp
80103fc1:	c3                   	ret    

80103fc2 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103fc2:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80103fc6:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80103fca:	55                   	push   %ebp
  pushl %ebx
80103fcb:	53                   	push   %ebx
  pushl %esi
80103fcc:	56                   	push   %esi
  pushl %edi
80103fcd:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80103fce:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80103fd0:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80103fd2:	5f                   	pop    %edi
  popl %esi
80103fd3:	5e                   	pop    %esi
  popl %ebx
80103fd4:	5b                   	pop    %ebx
  popl %ebp
80103fd5:	5d                   	pop    %ebp
  ret
80103fd6:	c3                   	ret    

80103fd7 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80103fd7:	55                   	push   %ebp
80103fd8:	89 e5                	mov    %esp,%ebp
80103fda:	53                   	push   %ebx
80103fdb:	83 ec 04             	sub    $0x4,%esp
80103fde:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80103fe1:	e8 6b f3 ff ff       	call   80103351 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80103fe6:	8b 00                	mov    (%eax),%eax
80103fe8:	39 d8                	cmp    %ebx,%eax
80103fea:	76 19                	jbe    80104005 <fetchint+0x2e>
80103fec:	8d 53 04             	lea    0x4(%ebx),%edx
80103fef:	39 d0                	cmp    %edx,%eax
80103ff1:	72 19                	jb     8010400c <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80103ff3:	8b 13                	mov    (%ebx),%edx
80103ff5:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ff8:	89 10                	mov    %edx,(%eax)
  return 0;
80103ffa:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103fff:	83 c4 04             	add    $0x4,%esp
80104002:	5b                   	pop    %ebx
80104003:	5d                   	pop    %ebp
80104004:	c3                   	ret    
    return -1;
80104005:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010400a:	eb f3                	jmp    80103fff <fetchint+0x28>
8010400c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104011:	eb ec                	jmp    80103fff <fetchint+0x28>

80104013 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80104013:	55                   	push   %ebp
80104014:	89 e5                	mov    %esp,%ebp
80104016:	53                   	push   %ebx
80104017:	83 ec 04             	sub    $0x4,%esp
8010401a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
8010401d:	e8 2f f3 ff ff       	call   80103351 <myproc>

  if(addr >= curproc->sz)
80104022:	39 18                	cmp    %ebx,(%eax)
80104024:	76 26                	jbe    8010404c <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80104026:	8b 55 0c             	mov    0xc(%ebp),%edx
80104029:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
8010402b:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
8010402d:	89 d8                	mov    %ebx,%eax
8010402f:	39 d0                	cmp    %edx,%eax
80104031:	73 0e                	jae    80104041 <fetchstr+0x2e>
    if(*s == 0)
80104033:	80 38 00             	cmpb   $0x0,(%eax)
80104036:	74 05                	je     8010403d <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80104038:	83 c0 01             	add    $0x1,%eax
8010403b:	eb f2                	jmp    8010402f <fetchstr+0x1c>
      return s - *pp;
8010403d:	29 d8                	sub    %ebx,%eax
8010403f:	eb 05                	jmp    80104046 <fetchstr+0x33>
  }
  return -1;
80104041:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104046:	83 c4 04             	add    $0x4,%esp
80104049:	5b                   	pop    %ebx
8010404a:	5d                   	pop    %ebp
8010404b:	c3                   	ret    
    return -1;
8010404c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104051:	eb f3                	jmp    80104046 <fetchstr+0x33>

80104053 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80104053:	55                   	push   %ebp
80104054:	89 e5                	mov    %esp,%ebp
80104056:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80104059:	e8 f3 f2 ff ff       	call   80103351 <myproc>
8010405e:	8b 50 18             	mov    0x18(%eax),%edx
80104061:	8b 45 08             	mov    0x8(%ebp),%eax
80104064:	c1 e0 02             	shl    $0x2,%eax
80104067:	03 42 44             	add    0x44(%edx),%eax
8010406a:	83 ec 08             	sub    $0x8,%esp
8010406d:	ff 75 0c             	pushl  0xc(%ebp)
80104070:	83 c0 04             	add    $0x4,%eax
80104073:	50                   	push   %eax
80104074:	e8 5e ff ff ff       	call   80103fd7 <fetchint>
}
80104079:	c9                   	leave  
8010407a:	c3                   	ret    

8010407b <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
8010407b:	55                   	push   %ebp
8010407c:	89 e5                	mov    %esp,%ebp
8010407e:	56                   	push   %esi
8010407f:	53                   	push   %ebx
80104080:	83 ec 10             	sub    $0x10,%esp
80104083:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80104086:	e8 c6 f2 ff ff       	call   80103351 <myproc>
8010408b:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
8010408d:	83 ec 08             	sub    $0x8,%esp
80104090:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104093:	50                   	push   %eax
80104094:	ff 75 08             	pushl  0x8(%ebp)
80104097:	e8 b7 ff ff ff       	call   80104053 <argint>
8010409c:	83 c4 10             	add    $0x10,%esp
8010409f:	85 c0                	test   %eax,%eax
801040a1:	78 24                	js     801040c7 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
801040a3:	85 db                	test   %ebx,%ebx
801040a5:	78 27                	js     801040ce <argptr+0x53>
801040a7:	8b 16                	mov    (%esi),%edx
801040a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040ac:	39 c2                	cmp    %eax,%edx
801040ae:	76 25                	jbe    801040d5 <argptr+0x5a>
801040b0:	01 c3                	add    %eax,%ebx
801040b2:	39 da                	cmp    %ebx,%edx
801040b4:	72 26                	jb     801040dc <argptr+0x61>
    return -1;
  *pp = (char*)i;
801040b6:	8b 55 0c             	mov    0xc(%ebp),%edx
801040b9:	89 02                	mov    %eax,(%edx)
  return 0;
801040bb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801040c0:	8d 65 f8             	lea    -0x8(%ebp),%esp
801040c3:	5b                   	pop    %ebx
801040c4:	5e                   	pop    %esi
801040c5:	5d                   	pop    %ebp
801040c6:	c3                   	ret    
    return -1;
801040c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040cc:	eb f2                	jmp    801040c0 <argptr+0x45>
    return -1;
801040ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040d3:	eb eb                	jmp    801040c0 <argptr+0x45>
801040d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040da:	eb e4                	jmp    801040c0 <argptr+0x45>
801040dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040e1:	eb dd                	jmp    801040c0 <argptr+0x45>

801040e3 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
801040e3:	55                   	push   %ebp
801040e4:	89 e5                	mov    %esp,%ebp
801040e6:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
801040e9:	8d 45 f4             	lea    -0xc(%ebp),%eax
801040ec:	50                   	push   %eax
801040ed:	ff 75 08             	pushl  0x8(%ebp)
801040f0:	e8 5e ff ff ff       	call   80104053 <argint>
801040f5:	83 c4 10             	add    $0x10,%esp
801040f8:	85 c0                	test   %eax,%eax
801040fa:	78 13                	js     8010410f <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
801040fc:	83 ec 08             	sub    $0x8,%esp
801040ff:	ff 75 0c             	pushl  0xc(%ebp)
80104102:	ff 75 f4             	pushl  -0xc(%ebp)
80104105:	e8 09 ff ff ff       	call   80104013 <fetchstr>
8010410a:	83 c4 10             	add    $0x10,%esp
}
8010410d:	c9                   	leave  
8010410e:	c3                   	ret    
    return -1;
8010410f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104114:	eb f7                	jmp    8010410d <argstr+0x2a>

80104116 <syscall>:
[SYS_dump_physmem]  sys_dump_physmem,
};

void
syscall(void)
{
80104116:	55                   	push   %ebp
80104117:	89 e5                	mov    %esp,%ebp
80104119:	53                   	push   %ebx
8010411a:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
8010411d:	e8 2f f2 ff ff       	call   80103351 <myproc>
80104122:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80104124:	8b 40 18             	mov    0x18(%eax),%eax
80104127:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010412a:	8d 50 ff             	lea    -0x1(%eax),%edx
8010412d:	83 fa 15             	cmp    $0x15,%edx
80104130:	77 18                	ja     8010414a <syscall+0x34>
80104132:	8b 14 85 40 6d 10 80 	mov    -0x7fef92c0(,%eax,4),%edx
80104139:	85 d2                	test   %edx,%edx
8010413b:	74 0d                	je     8010414a <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
8010413d:	ff d2                	call   *%edx
8010413f:	8b 53 18             	mov    0x18(%ebx),%edx
80104142:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
80104145:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104148:	c9                   	leave  
80104149:	c3                   	ret    
            curproc->pid, curproc->name, num);
8010414a:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
8010414d:	50                   	push   %eax
8010414e:	52                   	push   %edx
8010414f:	ff 73 10             	pushl  0x10(%ebx)
80104152:	68 11 6d 10 80       	push   $0x80106d11
80104157:	e8 af c4 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
8010415c:	8b 43 18             	mov    0x18(%ebx),%eax
8010415f:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
80104166:	83 c4 10             	add    $0x10,%esp
80104169:	eb da                	jmp    80104145 <syscall+0x2f>

8010416b <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010416b:	55                   	push   %ebp
8010416c:	89 e5                	mov    %esp,%ebp
8010416e:	56                   	push   %esi
8010416f:	53                   	push   %ebx
80104170:	83 ec 18             	sub    $0x18,%esp
80104173:	89 d6                	mov    %edx,%esi
80104175:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80104177:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010417a:	52                   	push   %edx
8010417b:	50                   	push   %eax
8010417c:	e8 d2 fe ff ff       	call   80104053 <argint>
80104181:	83 c4 10             	add    $0x10,%esp
80104184:	85 c0                	test   %eax,%eax
80104186:	78 2e                	js     801041b6 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
80104188:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
8010418c:	77 2f                	ja     801041bd <argfd+0x52>
8010418e:	e8 be f1 ff ff       	call   80103351 <myproc>
80104193:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104196:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
8010419a:	85 c0                	test   %eax,%eax
8010419c:	74 26                	je     801041c4 <argfd+0x59>
    return -1;
  if(pfd)
8010419e:	85 f6                	test   %esi,%esi
801041a0:	74 02                	je     801041a4 <argfd+0x39>
    *pfd = fd;
801041a2:	89 16                	mov    %edx,(%esi)
  if(pf)
801041a4:	85 db                	test   %ebx,%ebx
801041a6:	74 23                	je     801041cb <argfd+0x60>
    *pf = f;
801041a8:	89 03                	mov    %eax,(%ebx)
  return 0;
801041aa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801041af:	8d 65 f8             	lea    -0x8(%ebp),%esp
801041b2:	5b                   	pop    %ebx
801041b3:	5e                   	pop    %esi
801041b4:	5d                   	pop    %ebp
801041b5:	c3                   	ret    
    return -1;
801041b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041bb:	eb f2                	jmp    801041af <argfd+0x44>
    return -1;
801041bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041c2:	eb eb                	jmp    801041af <argfd+0x44>
801041c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041c9:	eb e4                	jmp    801041af <argfd+0x44>
  return 0;
801041cb:	b8 00 00 00 00       	mov    $0x0,%eax
801041d0:	eb dd                	jmp    801041af <argfd+0x44>

801041d2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801041d2:	55                   	push   %ebp
801041d3:	89 e5                	mov    %esp,%ebp
801041d5:	53                   	push   %ebx
801041d6:	83 ec 04             	sub    $0x4,%esp
801041d9:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
801041db:	e8 71 f1 ff ff       	call   80103351 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
801041e0:	ba 00 00 00 00       	mov    $0x0,%edx
801041e5:	83 fa 0f             	cmp    $0xf,%edx
801041e8:	7f 18                	jg     80104202 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
801041ea:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
801041ef:	74 05                	je     801041f6 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
801041f1:	83 c2 01             	add    $0x1,%edx
801041f4:	eb ef                	jmp    801041e5 <fdalloc+0x13>
      curproc->ofile[fd] = f;
801041f6:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
801041fa:	89 d0                	mov    %edx,%eax
801041fc:	83 c4 04             	add    $0x4,%esp
801041ff:	5b                   	pop    %ebx
80104200:	5d                   	pop    %ebp
80104201:	c3                   	ret    
  return -1;
80104202:	ba ff ff ff ff       	mov    $0xffffffff,%edx
80104207:	eb f1                	jmp    801041fa <fdalloc+0x28>

80104209 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80104209:	55                   	push   %ebp
8010420a:	89 e5                	mov    %esp,%ebp
8010420c:	56                   	push   %esi
8010420d:	53                   	push   %ebx
8010420e:	83 ec 10             	sub    $0x10,%esp
80104211:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104213:	b8 20 00 00 00       	mov    $0x20,%eax
80104218:	89 c6                	mov    %eax,%esi
8010421a:	39 43 58             	cmp    %eax,0x58(%ebx)
8010421d:	76 2e                	jbe    8010424d <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010421f:	6a 10                	push   $0x10
80104221:	50                   	push   %eax
80104222:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104225:	50                   	push   %eax
80104226:	53                   	push   %ebx
80104227:	e8 47 d5 ff ff       	call   80101773 <readi>
8010422c:	83 c4 10             	add    $0x10,%esp
8010422f:	83 f8 10             	cmp    $0x10,%eax
80104232:	75 0c                	jne    80104240 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
80104234:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
80104239:	75 1e                	jne    80104259 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010423b:	8d 46 10             	lea    0x10(%esi),%eax
8010423e:	eb d8                	jmp    80104218 <isdirempty+0xf>
      panic("isdirempty: readi");
80104240:	83 ec 0c             	sub    $0xc,%esp
80104243:	68 9c 6d 10 80       	push   $0x80106d9c
80104248:	e8 fb c0 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
8010424d:	b8 01 00 00 00       	mov    $0x1,%eax
}
80104252:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104255:	5b                   	pop    %ebx
80104256:	5e                   	pop    %esi
80104257:	5d                   	pop    %ebp
80104258:	c3                   	ret    
      return 0;
80104259:	b8 00 00 00 00       	mov    $0x0,%eax
8010425e:	eb f2                	jmp    80104252 <isdirempty+0x49>

80104260 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104260:	55                   	push   %ebp
80104261:	89 e5                	mov    %esp,%ebp
80104263:	57                   	push   %edi
80104264:	56                   	push   %esi
80104265:	53                   	push   %ebx
80104266:	83 ec 44             	sub    $0x44,%esp
80104269:	89 55 c4             	mov    %edx,-0x3c(%ebp)
8010426c:	89 4d c0             	mov    %ecx,-0x40(%ebp)
8010426f:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104272:	8d 55 d6             	lea    -0x2a(%ebp),%edx
80104275:	52                   	push   %edx
80104276:	50                   	push   %eax
80104277:	e8 7d d9 ff ff       	call   80101bf9 <nameiparent>
8010427c:	89 c6                	mov    %eax,%esi
8010427e:	83 c4 10             	add    $0x10,%esp
80104281:	85 c0                	test   %eax,%eax
80104283:	0f 84 3a 01 00 00    	je     801043c3 <create+0x163>
    return 0;
  ilock(dp);
80104289:	83 ec 0c             	sub    $0xc,%esp
8010428c:	50                   	push   %eax
8010428d:	e8 ef d2 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104292:	83 c4 0c             	add    $0xc,%esp
80104295:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104298:	50                   	push   %eax
80104299:	8d 45 d6             	lea    -0x2a(%ebp),%eax
8010429c:	50                   	push   %eax
8010429d:	56                   	push   %esi
8010429e:	e8 0d d7 ff ff       	call   801019b0 <dirlookup>
801042a3:	89 c3                	mov    %eax,%ebx
801042a5:	83 c4 10             	add    $0x10,%esp
801042a8:	85 c0                	test   %eax,%eax
801042aa:	74 3f                	je     801042eb <create+0x8b>
    iunlockput(dp);
801042ac:	83 ec 0c             	sub    $0xc,%esp
801042af:	56                   	push   %esi
801042b0:	e8 73 d4 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
801042b5:	89 1c 24             	mov    %ebx,(%esp)
801042b8:	e8 c4 d2 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801042bd:	83 c4 10             	add    $0x10,%esp
801042c0:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
801042c5:	75 11                	jne    801042d8 <create+0x78>
801042c7:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
801042cc:	75 0a                	jne    801042d8 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
801042ce:	89 d8                	mov    %ebx,%eax
801042d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
801042d3:	5b                   	pop    %ebx
801042d4:	5e                   	pop    %esi
801042d5:	5f                   	pop    %edi
801042d6:	5d                   	pop    %ebp
801042d7:	c3                   	ret    
    iunlockput(ip);
801042d8:	83 ec 0c             	sub    $0xc,%esp
801042db:	53                   	push   %ebx
801042dc:	e8 47 d4 ff ff       	call   80101728 <iunlockput>
    return 0;
801042e1:	83 c4 10             	add    $0x10,%esp
801042e4:	bb 00 00 00 00       	mov    $0x0,%ebx
801042e9:	eb e3                	jmp    801042ce <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
801042eb:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
801042ef:	83 ec 08             	sub    $0x8,%esp
801042f2:	50                   	push   %eax
801042f3:	ff 36                	pushl  (%esi)
801042f5:	e8 84 d0 ff ff       	call   8010137e <ialloc>
801042fa:	89 c3                	mov    %eax,%ebx
801042fc:	83 c4 10             	add    $0x10,%esp
801042ff:	85 c0                	test   %eax,%eax
80104301:	74 55                	je     80104358 <create+0xf8>
  ilock(ip);
80104303:	83 ec 0c             	sub    $0xc,%esp
80104306:	50                   	push   %eax
80104307:	e8 75 d2 ff ff       	call   80101581 <ilock>
  ip->major = major;
8010430c:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
80104310:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
80104314:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
80104318:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
8010431e:	89 1c 24             	mov    %ebx,(%esp)
80104321:	e8 fa d0 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80104326:	83 c4 10             	add    $0x10,%esp
80104329:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
8010432e:	74 35                	je     80104365 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
80104330:	83 ec 04             	sub    $0x4,%esp
80104333:	ff 73 04             	pushl  0x4(%ebx)
80104336:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104339:	50                   	push   %eax
8010433a:	56                   	push   %esi
8010433b:	e8 f0 d7 ff ff       	call   80101b30 <dirlink>
80104340:	83 c4 10             	add    $0x10,%esp
80104343:	85 c0                	test   %eax,%eax
80104345:	78 6f                	js     801043b6 <create+0x156>
  iunlockput(dp);
80104347:	83 ec 0c             	sub    $0xc,%esp
8010434a:	56                   	push   %esi
8010434b:	e8 d8 d3 ff ff       	call   80101728 <iunlockput>
  return ip;
80104350:	83 c4 10             	add    $0x10,%esp
80104353:	e9 76 ff ff ff       	jmp    801042ce <create+0x6e>
    panic("create: ialloc");
80104358:	83 ec 0c             	sub    $0xc,%esp
8010435b:	68 ae 6d 10 80       	push   $0x80106dae
80104360:	e8 e3 bf ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
80104365:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104369:	83 c0 01             	add    $0x1,%eax
8010436c:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104370:	83 ec 0c             	sub    $0xc,%esp
80104373:	56                   	push   %esi
80104374:	e8 a7 d0 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80104379:	83 c4 0c             	add    $0xc,%esp
8010437c:	ff 73 04             	pushl  0x4(%ebx)
8010437f:	68 be 6d 10 80       	push   $0x80106dbe
80104384:	53                   	push   %ebx
80104385:	e8 a6 d7 ff ff       	call   80101b30 <dirlink>
8010438a:	83 c4 10             	add    $0x10,%esp
8010438d:	85 c0                	test   %eax,%eax
8010438f:	78 18                	js     801043a9 <create+0x149>
80104391:	83 ec 04             	sub    $0x4,%esp
80104394:	ff 76 04             	pushl  0x4(%esi)
80104397:	68 bd 6d 10 80       	push   $0x80106dbd
8010439c:	53                   	push   %ebx
8010439d:	e8 8e d7 ff ff       	call   80101b30 <dirlink>
801043a2:	83 c4 10             	add    $0x10,%esp
801043a5:	85 c0                	test   %eax,%eax
801043a7:	79 87                	jns    80104330 <create+0xd0>
      panic("create dots");
801043a9:	83 ec 0c             	sub    $0xc,%esp
801043ac:	68 c0 6d 10 80       	push   $0x80106dc0
801043b1:	e8 92 bf ff ff       	call   80100348 <panic>
    panic("create: dirlink");
801043b6:	83 ec 0c             	sub    $0xc,%esp
801043b9:	68 cc 6d 10 80       	push   $0x80106dcc
801043be:	e8 85 bf ff ff       	call   80100348 <panic>
    return 0;
801043c3:	89 c3                	mov    %eax,%ebx
801043c5:	e9 04 ff ff ff       	jmp    801042ce <create+0x6e>

801043ca <sys_dup>:
{
801043ca:	55                   	push   %ebp
801043cb:	89 e5                	mov    %esp,%ebp
801043cd:	53                   	push   %ebx
801043ce:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
801043d1:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801043d4:	ba 00 00 00 00       	mov    $0x0,%edx
801043d9:	b8 00 00 00 00       	mov    $0x0,%eax
801043de:	e8 88 fd ff ff       	call   8010416b <argfd>
801043e3:	85 c0                	test   %eax,%eax
801043e5:	78 23                	js     8010440a <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
801043e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043ea:	e8 e3 fd ff ff       	call   801041d2 <fdalloc>
801043ef:	89 c3                	mov    %eax,%ebx
801043f1:	85 c0                	test   %eax,%eax
801043f3:	78 1c                	js     80104411 <sys_dup+0x47>
  filedup(f);
801043f5:	83 ec 0c             	sub    $0xc,%esp
801043f8:	ff 75 f4             	pushl  -0xc(%ebp)
801043fb:	e8 8e c8 ff ff       	call   80100c8e <filedup>
  return fd;
80104400:	83 c4 10             	add    $0x10,%esp
}
80104403:	89 d8                	mov    %ebx,%eax
80104405:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104408:	c9                   	leave  
80104409:	c3                   	ret    
    return -1;
8010440a:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010440f:	eb f2                	jmp    80104403 <sys_dup+0x39>
    return -1;
80104411:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104416:	eb eb                	jmp    80104403 <sys_dup+0x39>

80104418 <sys_read>:
{
80104418:	55                   	push   %ebp
80104419:	89 e5                	mov    %esp,%ebp
8010441b:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010441e:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104421:	ba 00 00 00 00       	mov    $0x0,%edx
80104426:	b8 00 00 00 00       	mov    $0x0,%eax
8010442b:	e8 3b fd ff ff       	call   8010416b <argfd>
80104430:	85 c0                	test   %eax,%eax
80104432:	78 43                	js     80104477 <sys_read+0x5f>
80104434:	83 ec 08             	sub    $0x8,%esp
80104437:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010443a:	50                   	push   %eax
8010443b:	6a 02                	push   $0x2
8010443d:	e8 11 fc ff ff       	call   80104053 <argint>
80104442:	83 c4 10             	add    $0x10,%esp
80104445:	85 c0                	test   %eax,%eax
80104447:	78 35                	js     8010447e <sys_read+0x66>
80104449:	83 ec 04             	sub    $0x4,%esp
8010444c:	ff 75 f0             	pushl  -0x10(%ebp)
8010444f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104452:	50                   	push   %eax
80104453:	6a 01                	push   $0x1
80104455:	e8 21 fc ff ff       	call   8010407b <argptr>
8010445a:	83 c4 10             	add    $0x10,%esp
8010445d:	85 c0                	test   %eax,%eax
8010445f:	78 24                	js     80104485 <sys_read+0x6d>
  return fileread(f, p, n);
80104461:	83 ec 04             	sub    $0x4,%esp
80104464:	ff 75 f0             	pushl  -0x10(%ebp)
80104467:	ff 75 ec             	pushl  -0x14(%ebp)
8010446a:	ff 75 f4             	pushl  -0xc(%ebp)
8010446d:	e8 65 c9 ff ff       	call   80100dd7 <fileread>
80104472:	83 c4 10             	add    $0x10,%esp
}
80104475:	c9                   	leave  
80104476:	c3                   	ret    
    return -1;
80104477:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010447c:	eb f7                	jmp    80104475 <sys_read+0x5d>
8010447e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104483:	eb f0                	jmp    80104475 <sys_read+0x5d>
80104485:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010448a:	eb e9                	jmp    80104475 <sys_read+0x5d>

8010448c <sys_write>:
{
8010448c:	55                   	push   %ebp
8010448d:	89 e5                	mov    %esp,%ebp
8010448f:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104492:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104495:	ba 00 00 00 00       	mov    $0x0,%edx
8010449a:	b8 00 00 00 00       	mov    $0x0,%eax
8010449f:	e8 c7 fc ff ff       	call   8010416b <argfd>
801044a4:	85 c0                	test   %eax,%eax
801044a6:	78 43                	js     801044eb <sys_write+0x5f>
801044a8:	83 ec 08             	sub    $0x8,%esp
801044ab:	8d 45 f0             	lea    -0x10(%ebp),%eax
801044ae:	50                   	push   %eax
801044af:	6a 02                	push   $0x2
801044b1:	e8 9d fb ff ff       	call   80104053 <argint>
801044b6:	83 c4 10             	add    $0x10,%esp
801044b9:	85 c0                	test   %eax,%eax
801044bb:	78 35                	js     801044f2 <sys_write+0x66>
801044bd:	83 ec 04             	sub    $0x4,%esp
801044c0:	ff 75 f0             	pushl  -0x10(%ebp)
801044c3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801044c6:	50                   	push   %eax
801044c7:	6a 01                	push   $0x1
801044c9:	e8 ad fb ff ff       	call   8010407b <argptr>
801044ce:	83 c4 10             	add    $0x10,%esp
801044d1:	85 c0                	test   %eax,%eax
801044d3:	78 24                	js     801044f9 <sys_write+0x6d>
  return filewrite(f, p, n);
801044d5:	83 ec 04             	sub    $0x4,%esp
801044d8:	ff 75 f0             	pushl  -0x10(%ebp)
801044db:	ff 75 ec             	pushl  -0x14(%ebp)
801044de:	ff 75 f4             	pushl  -0xc(%ebp)
801044e1:	e8 76 c9 ff ff       	call   80100e5c <filewrite>
801044e6:	83 c4 10             	add    $0x10,%esp
}
801044e9:	c9                   	leave  
801044ea:	c3                   	ret    
    return -1;
801044eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044f0:	eb f7                	jmp    801044e9 <sys_write+0x5d>
801044f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044f7:	eb f0                	jmp    801044e9 <sys_write+0x5d>
801044f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044fe:	eb e9                	jmp    801044e9 <sys_write+0x5d>

80104500 <sys_close>:
{
80104500:	55                   	push   %ebp
80104501:	89 e5                	mov    %esp,%ebp
80104503:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104506:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104509:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010450c:	b8 00 00 00 00       	mov    $0x0,%eax
80104511:	e8 55 fc ff ff       	call   8010416b <argfd>
80104516:	85 c0                	test   %eax,%eax
80104518:	78 25                	js     8010453f <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
8010451a:	e8 32 ee ff ff       	call   80103351 <myproc>
8010451f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104522:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
80104529:	00 
  fileclose(f);
8010452a:	83 ec 0c             	sub    $0xc,%esp
8010452d:	ff 75 f0             	pushl  -0x10(%ebp)
80104530:	e8 9e c7 ff ff       	call   80100cd3 <fileclose>
  return 0;
80104535:	83 c4 10             	add    $0x10,%esp
80104538:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010453d:	c9                   	leave  
8010453e:	c3                   	ret    
    return -1;
8010453f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104544:	eb f7                	jmp    8010453d <sys_close+0x3d>

80104546 <sys_fstat>:
{
80104546:	55                   	push   %ebp
80104547:	89 e5                	mov    %esp,%ebp
80104549:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010454c:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010454f:	ba 00 00 00 00       	mov    $0x0,%edx
80104554:	b8 00 00 00 00       	mov    $0x0,%eax
80104559:	e8 0d fc ff ff       	call   8010416b <argfd>
8010455e:	85 c0                	test   %eax,%eax
80104560:	78 2a                	js     8010458c <sys_fstat+0x46>
80104562:	83 ec 04             	sub    $0x4,%esp
80104565:	6a 14                	push   $0x14
80104567:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010456a:	50                   	push   %eax
8010456b:	6a 01                	push   $0x1
8010456d:	e8 09 fb ff ff       	call   8010407b <argptr>
80104572:	83 c4 10             	add    $0x10,%esp
80104575:	85 c0                	test   %eax,%eax
80104577:	78 1a                	js     80104593 <sys_fstat+0x4d>
  return filestat(f, st);
80104579:	83 ec 08             	sub    $0x8,%esp
8010457c:	ff 75 f0             	pushl  -0x10(%ebp)
8010457f:	ff 75 f4             	pushl  -0xc(%ebp)
80104582:	e8 09 c8 ff ff       	call   80100d90 <filestat>
80104587:	83 c4 10             	add    $0x10,%esp
}
8010458a:	c9                   	leave  
8010458b:	c3                   	ret    
    return -1;
8010458c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104591:	eb f7                	jmp    8010458a <sys_fstat+0x44>
80104593:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104598:	eb f0                	jmp    8010458a <sys_fstat+0x44>

8010459a <sys_link>:
{
8010459a:	55                   	push   %ebp
8010459b:	89 e5                	mov    %esp,%ebp
8010459d:	56                   	push   %esi
8010459e:	53                   	push   %ebx
8010459f:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801045a2:	8d 45 e0             	lea    -0x20(%ebp),%eax
801045a5:	50                   	push   %eax
801045a6:	6a 00                	push   $0x0
801045a8:	e8 36 fb ff ff       	call   801040e3 <argstr>
801045ad:	83 c4 10             	add    $0x10,%esp
801045b0:	85 c0                	test   %eax,%eax
801045b2:	0f 88 32 01 00 00    	js     801046ea <sys_link+0x150>
801045b8:	83 ec 08             	sub    $0x8,%esp
801045bb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801045be:	50                   	push   %eax
801045bf:	6a 01                	push   $0x1
801045c1:	e8 1d fb ff ff       	call   801040e3 <argstr>
801045c6:	83 c4 10             	add    $0x10,%esp
801045c9:	85 c0                	test   %eax,%eax
801045cb:	0f 88 20 01 00 00    	js     801046f1 <sys_link+0x157>
  begin_op();
801045d1:	e8 33 e3 ff ff       	call   80102909 <begin_op>
  if((ip = namei(old)) == 0){
801045d6:	83 ec 0c             	sub    $0xc,%esp
801045d9:	ff 75 e0             	pushl  -0x20(%ebp)
801045dc:	e8 00 d6 ff ff       	call   80101be1 <namei>
801045e1:	89 c3                	mov    %eax,%ebx
801045e3:	83 c4 10             	add    $0x10,%esp
801045e6:	85 c0                	test   %eax,%eax
801045e8:	0f 84 99 00 00 00    	je     80104687 <sys_link+0xed>
  ilock(ip);
801045ee:	83 ec 0c             	sub    $0xc,%esp
801045f1:	50                   	push   %eax
801045f2:	e8 8a cf ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
801045f7:	83 c4 10             	add    $0x10,%esp
801045fa:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801045ff:	0f 84 8e 00 00 00    	je     80104693 <sys_link+0xf9>
  ip->nlink++;
80104605:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104609:	83 c0 01             	add    $0x1,%eax
8010460c:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104610:	83 ec 0c             	sub    $0xc,%esp
80104613:	53                   	push   %ebx
80104614:	e8 07 ce ff ff       	call   80101420 <iupdate>
  iunlock(ip);
80104619:	89 1c 24             	mov    %ebx,(%esp)
8010461c:	e8 22 d0 ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
80104621:	83 c4 08             	add    $0x8,%esp
80104624:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104627:	50                   	push   %eax
80104628:	ff 75 e4             	pushl  -0x1c(%ebp)
8010462b:	e8 c9 d5 ff ff       	call   80101bf9 <nameiparent>
80104630:	89 c6                	mov    %eax,%esi
80104632:	83 c4 10             	add    $0x10,%esp
80104635:	85 c0                	test   %eax,%eax
80104637:	74 7e                	je     801046b7 <sys_link+0x11d>
  ilock(dp);
80104639:	83 ec 0c             	sub    $0xc,%esp
8010463c:	50                   	push   %eax
8010463d:	e8 3f cf ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80104642:	83 c4 10             	add    $0x10,%esp
80104645:	8b 03                	mov    (%ebx),%eax
80104647:	39 06                	cmp    %eax,(%esi)
80104649:	75 60                	jne    801046ab <sys_link+0x111>
8010464b:	83 ec 04             	sub    $0x4,%esp
8010464e:	ff 73 04             	pushl  0x4(%ebx)
80104651:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104654:	50                   	push   %eax
80104655:	56                   	push   %esi
80104656:	e8 d5 d4 ff ff       	call   80101b30 <dirlink>
8010465b:	83 c4 10             	add    $0x10,%esp
8010465e:	85 c0                	test   %eax,%eax
80104660:	78 49                	js     801046ab <sys_link+0x111>
  iunlockput(dp);
80104662:	83 ec 0c             	sub    $0xc,%esp
80104665:	56                   	push   %esi
80104666:	e8 bd d0 ff ff       	call   80101728 <iunlockput>
  iput(ip);
8010466b:	89 1c 24             	mov    %ebx,(%esp)
8010466e:	e8 15 d0 ff ff       	call   80101688 <iput>
  end_op();
80104673:	e8 0b e3 ff ff       	call   80102983 <end_op>
  return 0;
80104678:	83 c4 10             	add    $0x10,%esp
8010467b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104680:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104683:	5b                   	pop    %ebx
80104684:	5e                   	pop    %esi
80104685:	5d                   	pop    %ebp
80104686:	c3                   	ret    
    end_op();
80104687:	e8 f7 e2 ff ff       	call   80102983 <end_op>
    return -1;
8010468c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104691:	eb ed                	jmp    80104680 <sys_link+0xe6>
    iunlockput(ip);
80104693:	83 ec 0c             	sub    $0xc,%esp
80104696:	53                   	push   %ebx
80104697:	e8 8c d0 ff ff       	call   80101728 <iunlockput>
    end_op();
8010469c:	e8 e2 e2 ff ff       	call   80102983 <end_op>
    return -1;
801046a1:	83 c4 10             	add    $0x10,%esp
801046a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046a9:	eb d5                	jmp    80104680 <sys_link+0xe6>
    iunlockput(dp);
801046ab:	83 ec 0c             	sub    $0xc,%esp
801046ae:	56                   	push   %esi
801046af:	e8 74 d0 ff ff       	call   80101728 <iunlockput>
    goto bad;
801046b4:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
801046b7:	83 ec 0c             	sub    $0xc,%esp
801046ba:	53                   	push   %ebx
801046bb:	e8 c1 ce ff ff       	call   80101581 <ilock>
  ip->nlink--;
801046c0:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801046c4:	83 e8 01             	sub    $0x1,%eax
801046c7:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801046cb:	89 1c 24             	mov    %ebx,(%esp)
801046ce:	e8 4d cd ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
801046d3:	89 1c 24             	mov    %ebx,(%esp)
801046d6:	e8 4d d0 ff ff       	call   80101728 <iunlockput>
  end_op();
801046db:	e8 a3 e2 ff ff       	call   80102983 <end_op>
  return -1;
801046e0:	83 c4 10             	add    $0x10,%esp
801046e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046e8:	eb 96                	jmp    80104680 <sys_link+0xe6>
    return -1;
801046ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046ef:	eb 8f                	jmp    80104680 <sys_link+0xe6>
801046f1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046f6:	eb 88                	jmp    80104680 <sys_link+0xe6>

801046f8 <sys_unlink>:
{
801046f8:	55                   	push   %ebp
801046f9:	89 e5                	mov    %esp,%ebp
801046fb:	57                   	push   %edi
801046fc:	56                   	push   %esi
801046fd:	53                   	push   %ebx
801046fe:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104701:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104704:	50                   	push   %eax
80104705:	6a 00                	push   $0x0
80104707:	e8 d7 f9 ff ff       	call   801040e3 <argstr>
8010470c:	83 c4 10             	add    $0x10,%esp
8010470f:	85 c0                	test   %eax,%eax
80104711:	0f 88 83 01 00 00    	js     8010489a <sys_unlink+0x1a2>
  begin_op();
80104717:	e8 ed e1 ff ff       	call   80102909 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
8010471c:	83 ec 08             	sub    $0x8,%esp
8010471f:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104722:	50                   	push   %eax
80104723:	ff 75 c4             	pushl  -0x3c(%ebp)
80104726:	e8 ce d4 ff ff       	call   80101bf9 <nameiparent>
8010472b:	89 c6                	mov    %eax,%esi
8010472d:	83 c4 10             	add    $0x10,%esp
80104730:	85 c0                	test   %eax,%eax
80104732:	0f 84 ed 00 00 00    	je     80104825 <sys_unlink+0x12d>
  ilock(dp);
80104738:	83 ec 0c             	sub    $0xc,%esp
8010473b:	50                   	push   %eax
8010473c:	e8 40 ce ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104741:	83 c4 08             	add    $0x8,%esp
80104744:	68 be 6d 10 80       	push   $0x80106dbe
80104749:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010474c:	50                   	push   %eax
8010474d:	e8 49 d2 ff ff       	call   8010199b <namecmp>
80104752:	83 c4 10             	add    $0x10,%esp
80104755:	85 c0                	test   %eax,%eax
80104757:	0f 84 fc 00 00 00    	je     80104859 <sys_unlink+0x161>
8010475d:	83 ec 08             	sub    $0x8,%esp
80104760:	68 bd 6d 10 80       	push   $0x80106dbd
80104765:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104768:	50                   	push   %eax
80104769:	e8 2d d2 ff ff       	call   8010199b <namecmp>
8010476e:	83 c4 10             	add    $0x10,%esp
80104771:	85 c0                	test   %eax,%eax
80104773:	0f 84 e0 00 00 00    	je     80104859 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
80104779:	83 ec 04             	sub    $0x4,%esp
8010477c:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010477f:	50                   	push   %eax
80104780:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104783:	50                   	push   %eax
80104784:	56                   	push   %esi
80104785:	e8 26 d2 ff ff       	call   801019b0 <dirlookup>
8010478a:	89 c3                	mov    %eax,%ebx
8010478c:	83 c4 10             	add    $0x10,%esp
8010478f:	85 c0                	test   %eax,%eax
80104791:	0f 84 c2 00 00 00    	je     80104859 <sys_unlink+0x161>
  ilock(ip);
80104797:	83 ec 0c             	sub    $0xc,%esp
8010479a:	50                   	push   %eax
8010479b:	e8 e1 cd ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
801047a0:	83 c4 10             	add    $0x10,%esp
801047a3:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801047a8:	0f 8e 83 00 00 00    	jle    80104831 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
801047ae:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801047b3:	0f 84 85 00 00 00    	je     8010483e <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
801047b9:	83 ec 04             	sub    $0x4,%esp
801047bc:	6a 10                	push   $0x10
801047be:	6a 00                	push   $0x0
801047c0:	8d 7d d8             	lea    -0x28(%ebp),%edi
801047c3:	57                   	push   %edi
801047c4:	e8 3f f6 ff ff       	call   80103e08 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801047c9:	6a 10                	push   $0x10
801047cb:	ff 75 c0             	pushl  -0x40(%ebp)
801047ce:	57                   	push   %edi
801047cf:	56                   	push   %esi
801047d0:	e8 9b d0 ff ff       	call   80101870 <writei>
801047d5:	83 c4 20             	add    $0x20,%esp
801047d8:	83 f8 10             	cmp    $0x10,%eax
801047db:	0f 85 90 00 00 00    	jne    80104871 <sys_unlink+0x179>
  if(ip->type == T_DIR){
801047e1:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801047e6:	0f 84 92 00 00 00    	je     8010487e <sys_unlink+0x186>
  iunlockput(dp);
801047ec:	83 ec 0c             	sub    $0xc,%esp
801047ef:	56                   	push   %esi
801047f0:	e8 33 cf ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
801047f5:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801047f9:	83 e8 01             	sub    $0x1,%eax
801047fc:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104800:	89 1c 24             	mov    %ebx,(%esp)
80104803:	e8 18 cc ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104808:	89 1c 24             	mov    %ebx,(%esp)
8010480b:	e8 18 cf ff ff       	call   80101728 <iunlockput>
  end_op();
80104810:	e8 6e e1 ff ff       	call   80102983 <end_op>
  return 0;
80104815:	83 c4 10             	add    $0x10,%esp
80104818:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010481d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104820:	5b                   	pop    %ebx
80104821:	5e                   	pop    %esi
80104822:	5f                   	pop    %edi
80104823:	5d                   	pop    %ebp
80104824:	c3                   	ret    
    end_op();
80104825:	e8 59 e1 ff ff       	call   80102983 <end_op>
    return -1;
8010482a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010482f:	eb ec                	jmp    8010481d <sys_unlink+0x125>
    panic("unlink: nlink < 1");
80104831:	83 ec 0c             	sub    $0xc,%esp
80104834:	68 dc 6d 10 80       	push   $0x80106ddc
80104839:	e8 0a bb ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010483e:	89 d8                	mov    %ebx,%eax
80104840:	e8 c4 f9 ff ff       	call   80104209 <isdirempty>
80104845:	85 c0                	test   %eax,%eax
80104847:	0f 85 6c ff ff ff    	jne    801047b9 <sys_unlink+0xc1>
    iunlockput(ip);
8010484d:	83 ec 0c             	sub    $0xc,%esp
80104850:	53                   	push   %ebx
80104851:	e8 d2 ce ff ff       	call   80101728 <iunlockput>
    goto bad;
80104856:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104859:	83 ec 0c             	sub    $0xc,%esp
8010485c:	56                   	push   %esi
8010485d:	e8 c6 ce ff ff       	call   80101728 <iunlockput>
  end_op();
80104862:	e8 1c e1 ff ff       	call   80102983 <end_op>
  return -1;
80104867:	83 c4 10             	add    $0x10,%esp
8010486a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010486f:	eb ac                	jmp    8010481d <sys_unlink+0x125>
    panic("unlink: writei");
80104871:	83 ec 0c             	sub    $0xc,%esp
80104874:	68 ee 6d 10 80       	push   $0x80106dee
80104879:	e8 ca ba ff ff       	call   80100348 <panic>
    dp->nlink--;
8010487e:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104882:	83 e8 01             	sub    $0x1,%eax
80104885:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104889:	83 ec 0c             	sub    $0xc,%esp
8010488c:	56                   	push   %esi
8010488d:	e8 8e cb ff ff       	call   80101420 <iupdate>
80104892:	83 c4 10             	add    $0x10,%esp
80104895:	e9 52 ff ff ff       	jmp    801047ec <sys_unlink+0xf4>
    return -1;
8010489a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010489f:	e9 79 ff ff ff       	jmp    8010481d <sys_unlink+0x125>

801048a4 <sys_open>:

int
sys_open(void)
{
801048a4:	55                   	push   %ebp
801048a5:	89 e5                	mov    %esp,%ebp
801048a7:	57                   	push   %edi
801048a8:	56                   	push   %esi
801048a9:	53                   	push   %ebx
801048aa:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801048ad:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801048b0:	50                   	push   %eax
801048b1:	6a 00                	push   $0x0
801048b3:	e8 2b f8 ff ff       	call   801040e3 <argstr>
801048b8:	83 c4 10             	add    $0x10,%esp
801048bb:	85 c0                	test   %eax,%eax
801048bd:	0f 88 30 01 00 00    	js     801049f3 <sys_open+0x14f>
801048c3:	83 ec 08             	sub    $0x8,%esp
801048c6:	8d 45 e0             	lea    -0x20(%ebp),%eax
801048c9:	50                   	push   %eax
801048ca:	6a 01                	push   $0x1
801048cc:	e8 82 f7 ff ff       	call   80104053 <argint>
801048d1:	83 c4 10             	add    $0x10,%esp
801048d4:	85 c0                	test   %eax,%eax
801048d6:	0f 88 21 01 00 00    	js     801049fd <sys_open+0x159>
    return -1;

  begin_op();
801048dc:	e8 28 e0 ff ff       	call   80102909 <begin_op>

  if(omode & O_CREATE){
801048e1:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
801048e5:	0f 84 84 00 00 00    	je     8010496f <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
801048eb:	83 ec 0c             	sub    $0xc,%esp
801048ee:	6a 00                	push   $0x0
801048f0:	b9 00 00 00 00       	mov    $0x0,%ecx
801048f5:	ba 02 00 00 00       	mov    $0x2,%edx
801048fa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801048fd:	e8 5e f9 ff ff       	call   80104260 <create>
80104902:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104904:	83 c4 10             	add    $0x10,%esp
80104907:	85 c0                	test   %eax,%eax
80104909:	74 58                	je     80104963 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010490b:	e8 1d c3 ff ff       	call   80100c2d <filealloc>
80104910:	89 c3                	mov    %eax,%ebx
80104912:	85 c0                	test   %eax,%eax
80104914:	0f 84 ae 00 00 00    	je     801049c8 <sys_open+0x124>
8010491a:	e8 b3 f8 ff ff       	call   801041d2 <fdalloc>
8010491f:	89 c7                	mov    %eax,%edi
80104921:	85 c0                	test   %eax,%eax
80104923:	0f 88 9f 00 00 00    	js     801049c8 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104929:	83 ec 0c             	sub    $0xc,%esp
8010492c:	56                   	push   %esi
8010492d:	e8 11 cd ff ff       	call   80101643 <iunlock>
  end_op();
80104932:	e8 4c e0 ff ff       	call   80102983 <end_op>

  f->type = FD_INODE;
80104937:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
8010493d:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104940:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104947:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010494a:	83 c4 10             	add    $0x10,%esp
8010494d:	a8 01                	test   $0x1,%al
8010494f:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104953:	a8 03                	test   $0x3,%al
80104955:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104959:	89 f8                	mov    %edi,%eax
8010495b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010495e:	5b                   	pop    %ebx
8010495f:	5e                   	pop    %esi
80104960:	5f                   	pop    %edi
80104961:	5d                   	pop    %ebp
80104962:	c3                   	ret    
      end_op();
80104963:	e8 1b e0 ff ff       	call   80102983 <end_op>
      return -1;
80104968:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010496d:	eb ea                	jmp    80104959 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
8010496f:	83 ec 0c             	sub    $0xc,%esp
80104972:	ff 75 e4             	pushl  -0x1c(%ebp)
80104975:	e8 67 d2 ff ff       	call   80101be1 <namei>
8010497a:	89 c6                	mov    %eax,%esi
8010497c:	83 c4 10             	add    $0x10,%esp
8010497f:	85 c0                	test   %eax,%eax
80104981:	74 39                	je     801049bc <sys_open+0x118>
    ilock(ip);
80104983:	83 ec 0c             	sub    $0xc,%esp
80104986:	50                   	push   %eax
80104987:	e8 f5 cb ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
8010498c:	83 c4 10             	add    $0x10,%esp
8010498f:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104994:	0f 85 71 ff ff ff    	jne    8010490b <sys_open+0x67>
8010499a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010499e:	0f 84 67 ff ff ff    	je     8010490b <sys_open+0x67>
      iunlockput(ip);
801049a4:	83 ec 0c             	sub    $0xc,%esp
801049a7:	56                   	push   %esi
801049a8:	e8 7b cd ff ff       	call   80101728 <iunlockput>
      end_op();
801049ad:	e8 d1 df ff ff       	call   80102983 <end_op>
      return -1;
801049b2:	83 c4 10             	add    $0x10,%esp
801049b5:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049ba:	eb 9d                	jmp    80104959 <sys_open+0xb5>
      end_op();
801049bc:	e8 c2 df ff ff       	call   80102983 <end_op>
      return -1;
801049c1:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049c6:	eb 91                	jmp    80104959 <sys_open+0xb5>
    if(f)
801049c8:	85 db                	test   %ebx,%ebx
801049ca:	74 0c                	je     801049d8 <sys_open+0x134>
      fileclose(f);
801049cc:	83 ec 0c             	sub    $0xc,%esp
801049cf:	53                   	push   %ebx
801049d0:	e8 fe c2 ff ff       	call   80100cd3 <fileclose>
801049d5:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
801049d8:	83 ec 0c             	sub    $0xc,%esp
801049db:	56                   	push   %esi
801049dc:	e8 47 cd ff ff       	call   80101728 <iunlockput>
    end_op();
801049e1:	e8 9d df ff ff       	call   80102983 <end_op>
    return -1;
801049e6:	83 c4 10             	add    $0x10,%esp
801049e9:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049ee:	e9 66 ff ff ff       	jmp    80104959 <sys_open+0xb5>
    return -1;
801049f3:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049f8:	e9 5c ff ff ff       	jmp    80104959 <sys_open+0xb5>
801049fd:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a02:	e9 52 ff ff ff       	jmp    80104959 <sys_open+0xb5>

80104a07 <sys_mkdir>:

int
sys_mkdir(void)
{
80104a07:	55                   	push   %ebp
80104a08:	89 e5                	mov    %esp,%ebp
80104a0a:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104a0d:	e8 f7 de ff ff       	call   80102909 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104a12:	83 ec 08             	sub    $0x8,%esp
80104a15:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a18:	50                   	push   %eax
80104a19:	6a 00                	push   $0x0
80104a1b:	e8 c3 f6 ff ff       	call   801040e3 <argstr>
80104a20:	83 c4 10             	add    $0x10,%esp
80104a23:	85 c0                	test   %eax,%eax
80104a25:	78 36                	js     80104a5d <sys_mkdir+0x56>
80104a27:	83 ec 0c             	sub    $0xc,%esp
80104a2a:	6a 00                	push   $0x0
80104a2c:	b9 00 00 00 00       	mov    $0x0,%ecx
80104a31:	ba 01 00 00 00       	mov    $0x1,%edx
80104a36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a39:	e8 22 f8 ff ff       	call   80104260 <create>
80104a3e:	83 c4 10             	add    $0x10,%esp
80104a41:	85 c0                	test   %eax,%eax
80104a43:	74 18                	je     80104a5d <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104a45:	83 ec 0c             	sub    $0xc,%esp
80104a48:	50                   	push   %eax
80104a49:	e8 da cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104a4e:	e8 30 df ff ff       	call   80102983 <end_op>
  return 0;
80104a53:	83 c4 10             	add    $0x10,%esp
80104a56:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a5b:	c9                   	leave  
80104a5c:	c3                   	ret    
    end_op();
80104a5d:	e8 21 df ff ff       	call   80102983 <end_op>
    return -1;
80104a62:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a67:	eb f2                	jmp    80104a5b <sys_mkdir+0x54>

80104a69 <sys_mknod>:

int
sys_mknod(void)
{
80104a69:	55                   	push   %ebp
80104a6a:	89 e5                	mov    %esp,%ebp
80104a6c:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104a6f:	e8 95 de ff ff       	call   80102909 <begin_op>
  if((argstr(0, &path)) < 0 ||
80104a74:	83 ec 08             	sub    $0x8,%esp
80104a77:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a7a:	50                   	push   %eax
80104a7b:	6a 00                	push   $0x0
80104a7d:	e8 61 f6 ff ff       	call   801040e3 <argstr>
80104a82:	83 c4 10             	add    $0x10,%esp
80104a85:	85 c0                	test   %eax,%eax
80104a87:	78 62                	js     80104aeb <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104a89:	83 ec 08             	sub    $0x8,%esp
80104a8c:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104a8f:	50                   	push   %eax
80104a90:	6a 01                	push   $0x1
80104a92:	e8 bc f5 ff ff       	call   80104053 <argint>
  if((argstr(0, &path)) < 0 ||
80104a97:	83 c4 10             	add    $0x10,%esp
80104a9a:	85 c0                	test   %eax,%eax
80104a9c:	78 4d                	js     80104aeb <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104a9e:	83 ec 08             	sub    $0x8,%esp
80104aa1:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104aa4:	50                   	push   %eax
80104aa5:	6a 02                	push   $0x2
80104aa7:	e8 a7 f5 ff ff       	call   80104053 <argint>
     argint(1, &major) < 0 ||
80104aac:	83 c4 10             	add    $0x10,%esp
80104aaf:	85 c0                	test   %eax,%eax
80104ab1:	78 38                	js     80104aeb <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104ab3:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104ab7:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104abb:	83 ec 0c             	sub    $0xc,%esp
80104abe:	50                   	push   %eax
80104abf:	ba 03 00 00 00       	mov    $0x3,%edx
80104ac4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ac7:	e8 94 f7 ff ff       	call   80104260 <create>
80104acc:	83 c4 10             	add    $0x10,%esp
80104acf:	85 c0                	test   %eax,%eax
80104ad1:	74 18                	je     80104aeb <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104ad3:	83 ec 0c             	sub    $0xc,%esp
80104ad6:	50                   	push   %eax
80104ad7:	e8 4c cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104adc:	e8 a2 de ff ff       	call   80102983 <end_op>
  return 0;
80104ae1:	83 c4 10             	add    $0x10,%esp
80104ae4:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ae9:	c9                   	leave  
80104aea:	c3                   	ret    
    end_op();
80104aeb:	e8 93 de ff ff       	call   80102983 <end_op>
    return -1;
80104af0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104af5:	eb f2                	jmp    80104ae9 <sys_mknod+0x80>

80104af7 <sys_chdir>:

int
sys_chdir(void)
{
80104af7:	55                   	push   %ebp
80104af8:	89 e5                	mov    %esp,%ebp
80104afa:	56                   	push   %esi
80104afb:	53                   	push   %ebx
80104afc:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104aff:	e8 4d e8 ff ff       	call   80103351 <myproc>
80104b04:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104b06:	e8 fe dd ff ff       	call   80102909 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104b0b:	83 ec 08             	sub    $0x8,%esp
80104b0e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b11:	50                   	push   %eax
80104b12:	6a 00                	push   $0x0
80104b14:	e8 ca f5 ff ff       	call   801040e3 <argstr>
80104b19:	83 c4 10             	add    $0x10,%esp
80104b1c:	85 c0                	test   %eax,%eax
80104b1e:	78 52                	js     80104b72 <sys_chdir+0x7b>
80104b20:	83 ec 0c             	sub    $0xc,%esp
80104b23:	ff 75 f4             	pushl  -0xc(%ebp)
80104b26:	e8 b6 d0 ff ff       	call   80101be1 <namei>
80104b2b:	89 c3                	mov    %eax,%ebx
80104b2d:	83 c4 10             	add    $0x10,%esp
80104b30:	85 c0                	test   %eax,%eax
80104b32:	74 3e                	je     80104b72 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104b34:	83 ec 0c             	sub    $0xc,%esp
80104b37:	50                   	push   %eax
80104b38:	e8 44 ca ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104b3d:	83 c4 10             	add    $0x10,%esp
80104b40:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104b45:	75 37                	jne    80104b7e <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104b47:	83 ec 0c             	sub    $0xc,%esp
80104b4a:	53                   	push   %ebx
80104b4b:	e8 f3 ca ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104b50:	83 c4 04             	add    $0x4,%esp
80104b53:	ff 76 68             	pushl  0x68(%esi)
80104b56:	e8 2d cb ff ff       	call   80101688 <iput>
  end_op();
80104b5b:	e8 23 de ff ff       	call   80102983 <end_op>
  curproc->cwd = ip;
80104b60:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104b63:	83 c4 10             	add    $0x10,%esp
80104b66:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b6b:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104b6e:	5b                   	pop    %ebx
80104b6f:	5e                   	pop    %esi
80104b70:	5d                   	pop    %ebp
80104b71:	c3                   	ret    
    end_op();
80104b72:	e8 0c de ff ff       	call   80102983 <end_op>
    return -1;
80104b77:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b7c:	eb ed                	jmp    80104b6b <sys_chdir+0x74>
    iunlockput(ip);
80104b7e:	83 ec 0c             	sub    $0xc,%esp
80104b81:	53                   	push   %ebx
80104b82:	e8 a1 cb ff ff       	call   80101728 <iunlockput>
    end_op();
80104b87:	e8 f7 dd ff ff       	call   80102983 <end_op>
    return -1;
80104b8c:	83 c4 10             	add    $0x10,%esp
80104b8f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b94:	eb d5                	jmp    80104b6b <sys_chdir+0x74>

80104b96 <sys_exec>:

int
sys_exec(void)
{
80104b96:	55                   	push   %ebp
80104b97:	89 e5                	mov    %esp,%ebp
80104b99:	53                   	push   %ebx
80104b9a:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104ba0:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ba3:	50                   	push   %eax
80104ba4:	6a 00                	push   $0x0
80104ba6:	e8 38 f5 ff ff       	call   801040e3 <argstr>
80104bab:	83 c4 10             	add    $0x10,%esp
80104bae:	85 c0                	test   %eax,%eax
80104bb0:	0f 88 a8 00 00 00    	js     80104c5e <sys_exec+0xc8>
80104bb6:	83 ec 08             	sub    $0x8,%esp
80104bb9:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104bbf:	50                   	push   %eax
80104bc0:	6a 01                	push   $0x1
80104bc2:	e8 8c f4 ff ff       	call   80104053 <argint>
80104bc7:	83 c4 10             	add    $0x10,%esp
80104bca:	85 c0                	test   %eax,%eax
80104bcc:	0f 88 93 00 00 00    	js     80104c65 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104bd2:	83 ec 04             	sub    $0x4,%esp
80104bd5:	68 80 00 00 00       	push   $0x80
80104bda:	6a 00                	push   $0x0
80104bdc:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104be2:	50                   	push   %eax
80104be3:	e8 20 f2 ff ff       	call   80103e08 <memset>
80104be8:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104beb:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104bf0:	83 fb 1f             	cmp    $0x1f,%ebx
80104bf3:	77 77                	ja     80104c6c <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104bf5:	83 ec 08             	sub    $0x8,%esp
80104bf8:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104bfe:	50                   	push   %eax
80104bff:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104c05:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104c08:	50                   	push   %eax
80104c09:	e8 c9 f3 ff ff       	call   80103fd7 <fetchint>
80104c0e:	83 c4 10             	add    $0x10,%esp
80104c11:	85 c0                	test   %eax,%eax
80104c13:	78 5e                	js     80104c73 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104c15:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104c1b:	85 c0                	test   %eax,%eax
80104c1d:	74 1d                	je     80104c3c <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104c1f:	83 ec 08             	sub    $0x8,%esp
80104c22:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104c29:	52                   	push   %edx
80104c2a:	50                   	push   %eax
80104c2b:	e8 e3 f3 ff ff       	call   80104013 <fetchstr>
80104c30:	83 c4 10             	add    $0x10,%esp
80104c33:	85 c0                	test   %eax,%eax
80104c35:	78 46                	js     80104c7d <sys_exec+0xe7>
  for(i=0;; i++){
80104c37:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104c3a:	eb b4                	jmp    80104bf0 <sys_exec+0x5a>
      argv[i] = 0;
80104c3c:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104c43:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104c47:	83 ec 08             	sub    $0x8,%esp
80104c4a:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104c50:	50                   	push   %eax
80104c51:	ff 75 f4             	pushl  -0xc(%ebp)
80104c54:	e8 79 bc ff ff       	call   801008d2 <exec>
80104c59:	83 c4 10             	add    $0x10,%esp
80104c5c:	eb 1a                	jmp    80104c78 <sys_exec+0xe2>
    return -1;
80104c5e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c63:	eb 13                	jmp    80104c78 <sys_exec+0xe2>
80104c65:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c6a:	eb 0c                	jmp    80104c78 <sys_exec+0xe2>
      return -1;
80104c6c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c71:	eb 05                	jmp    80104c78 <sys_exec+0xe2>
      return -1;
80104c73:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104c78:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104c7b:	c9                   	leave  
80104c7c:	c3                   	ret    
      return -1;
80104c7d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c82:	eb f4                	jmp    80104c78 <sys_exec+0xe2>

80104c84 <sys_pipe>:

int
sys_pipe(void)
{
80104c84:	55                   	push   %ebp
80104c85:	89 e5                	mov    %esp,%ebp
80104c87:	53                   	push   %ebx
80104c88:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104c8b:	6a 08                	push   $0x8
80104c8d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c90:	50                   	push   %eax
80104c91:	6a 00                	push   $0x0
80104c93:	e8 e3 f3 ff ff       	call   8010407b <argptr>
80104c98:	83 c4 10             	add    $0x10,%esp
80104c9b:	85 c0                	test   %eax,%eax
80104c9d:	78 77                	js     80104d16 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104c9f:	83 ec 08             	sub    $0x8,%esp
80104ca2:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104ca5:	50                   	push   %eax
80104ca6:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104ca9:	50                   	push   %eax
80104caa:	e8 e1 e1 ff ff       	call   80102e90 <pipealloc>
80104caf:	83 c4 10             	add    $0x10,%esp
80104cb2:	85 c0                	test   %eax,%eax
80104cb4:	78 67                	js     80104d1d <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104cb6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cb9:	e8 14 f5 ff ff       	call   801041d2 <fdalloc>
80104cbe:	89 c3                	mov    %eax,%ebx
80104cc0:	85 c0                	test   %eax,%eax
80104cc2:	78 21                	js     80104ce5 <sys_pipe+0x61>
80104cc4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104cc7:	e8 06 f5 ff ff       	call   801041d2 <fdalloc>
80104ccc:	85 c0                	test   %eax,%eax
80104cce:	78 15                	js     80104ce5 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104cd0:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104cd3:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104cd5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104cd8:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104cdb:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ce0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104ce3:	c9                   	leave  
80104ce4:	c3                   	ret    
    if(fd0 >= 0)
80104ce5:	85 db                	test   %ebx,%ebx
80104ce7:	78 0d                	js     80104cf6 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104ce9:	e8 63 e6 ff ff       	call   80103351 <myproc>
80104cee:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104cf5:	00 
    fileclose(rf);
80104cf6:	83 ec 0c             	sub    $0xc,%esp
80104cf9:	ff 75 f0             	pushl  -0x10(%ebp)
80104cfc:	e8 d2 bf ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104d01:	83 c4 04             	add    $0x4,%esp
80104d04:	ff 75 ec             	pushl  -0x14(%ebp)
80104d07:	e8 c7 bf ff ff       	call   80100cd3 <fileclose>
    return -1;
80104d0c:	83 c4 10             	add    $0x10,%esp
80104d0f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d14:	eb ca                	jmp    80104ce0 <sys_pipe+0x5c>
    return -1;
80104d16:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d1b:	eb c3                	jmp    80104ce0 <sys_pipe+0x5c>
    return -1;
80104d1d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d22:	eb bc                	jmp    80104ce0 <sys_pipe+0x5c>

80104d24 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104d24:	55                   	push   %ebp
80104d25:	89 e5                	mov    %esp,%ebp
80104d27:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104d2a:	e8 9a e7 ff ff       	call   801034c9 <fork>
}
80104d2f:	c9                   	leave  
80104d30:	c3                   	ret    

80104d31 <sys_exit>:

int
sys_exit(void)
{
80104d31:	55                   	push   %ebp
80104d32:	89 e5                	mov    %esp,%ebp
80104d34:	83 ec 08             	sub    $0x8,%esp
  exit();
80104d37:	e8 c1 e9 ff ff       	call   801036fd <exit>
  return 0;  // not reached
}
80104d3c:	b8 00 00 00 00       	mov    $0x0,%eax
80104d41:	c9                   	leave  
80104d42:	c3                   	ret    

80104d43 <sys_wait>:

int
sys_wait(void)
{
80104d43:	55                   	push   %ebp
80104d44:	89 e5                	mov    %esp,%ebp
80104d46:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104d49:	e8 38 eb ff ff       	call   80103886 <wait>
}
80104d4e:	c9                   	leave  
80104d4f:	c3                   	ret    

80104d50 <sys_kill>:

int
sys_kill(void)
{
80104d50:	55                   	push   %ebp
80104d51:	89 e5                	mov    %esp,%ebp
80104d53:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104d56:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d59:	50                   	push   %eax
80104d5a:	6a 00                	push   $0x0
80104d5c:	e8 f2 f2 ff ff       	call   80104053 <argint>
80104d61:	83 c4 10             	add    $0x10,%esp
80104d64:	85 c0                	test   %eax,%eax
80104d66:	78 10                	js     80104d78 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104d68:	83 ec 0c             	sub    $0xc,%esp
80104d6b:	ff 75 f4             	pushl  -0xc(%ebp)
80104d6e:	e8 10 ec ff ff       	call   80103983 <kill>
80104d73:	83 c4 10             	add    $0x10,%esp
}
80104d76:	c9                   	leave  
80104d77:	c3                   	ret    
    return -1;
80104d78:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d7d:	eb f7                	jmp    80104d76 <sys_kill+0x26>

80104d7f <sys_getpid>:

int
sys_getpid(void)
{
80104d7f:	55                   	push   %ebp
80104d80:	89 e5                	mov    %esp,%ebp
80104d82:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104d85:	e8 c7 e5 ff ff       	call   80103351 <myproc>
80104d8a:	8b 40 10             	mov    0x10(%eax),%eax
}
80104d8d:	c9                   	leave  
80104d8e:	c3                   	ret    

80104d8f <sys_sbrk>:

int
sys_sbrk(void)
{
80104d8f:	55                   	push   %ebp
80104d90:	89 e5                	mov    %esp,%ebp
80104d92:	53                   	push   %ebx
80104d93:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104d96:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d99:	50                   	push   %eax
80104d9a:	6a 00                	push   $0x0
80104d9c:	e8 b2 f2 ff ff       	call   80104053 <argint>
80104da1:	83 c4 10             	add    $0x10,%esp
80104da4:	85 c0                	test   %eax,%eax
80104da6:	78 27                	js     80104dcf <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104da8:	e8 a4 e5 ff ff       	call   80103351 <myproc>
80104dad:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104daf:	83 ec 0c             	sub    $0xc,%esp
80104db2:	ff 75 f4             	pushl  -0xc(%ebp)
80104db5:	e8 a2 e6 ff ff       	call   8010345c <growproc>
80104dba:	83 c4 10             	add    $0x10,%esp
80104dbd:	85 c0                	test   %eax,%eax
80104dbf:	78 07                	js     80104dc8 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104dc1:	89 d8                	mov    %ebx,%eax
80104dc3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104dc6:	c9                   	leave  
80104dc7:	c3                   	ret    
    return -1;
80104dc8:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104dcd:	eb f2                	jmp    80104dc1 <sys_sbrk+0x32>
    return -1;
80104dcf:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104dd4:	eb eb                	jmp    80104dc1 <sys_sbrk+0x32>

80104dd6 <sys_sleep>:

int
sys_sleep(void)
{
80104dd6:	55                   	push   %ebp
80104dd7:	89 e5                	mov    %esp,%ebp
80104dd9:	53                   	push   %ebx
80104dda:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104ddd:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104de0:	50                   	push   %eax
80104de1:	6a 00                	push   $0x0
80104de3:	e8 6b f2 ff ff       	call   80104053 <argint>
80104de8:	83 c4 10             	add    $0x10,%esp
80104deb:	85 c0                	test   %eax,%eax
80104ded:	78 75                	js     80104e64 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104def:	83 ec 0c             	sub    $0xc,%esp
80104df2:	68 80 4c 12 80       	push   $0x80124c80
80104df7:	e8 60 ef ff ff       	call   80103d5c <acquire>
  ticks0 = ticks;
80104dfc:	8b 1d c0 54 12 80    	mov    0x801254c0,%ebx
  while(ticks - ticks0 < n){
80104e02:	83 c4 10             	add    $0x10,%esp
80104e05:	a1 c0 54 12 80       	mov    0x801254c0,%eax
80104e0a:	29 d8                	sub    %ebx,%eax
80104e0c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104e0f:	73 39                	jae    80104e4a <sys_sleep+0x74>
    if(myproc()->killed){
80104e11:	e8 3b e5 ff ff       	call   80103351 <myproc>
80104e16:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104e1a:	75 17                	jne    80104e33 <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104e1c:	83 ec 08             	sub    $0x8,%esp
80104e1f:	68 80 4c 12 80       	push   $0x80124c80
80104e24:	68 c0 54 12 80       	push   $0x801254c0
80104e29:	e8 c7 e9 ff ff       	call   801037f5 <sleep>
80104e2e:	83 c4 10             	add    $0x10,%esp
80104e31:	eb d2                	jmp    80104e05 <sys_sleep+0x2f>
      release(&tickslock);
80104e33:	83 ec 0c             	sub    $0xc,%esp
80104e36:	68 80 4c 12 80       	push   $0x80124c80
80104e3b:	e8 81 ef ff ff       	call   80103dc1 <release>
      return -1;
80104e40:	83 c4 10             	add    $0x10,%esp
80104e43:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e48:	eb 15                	jmp    80104e5f <sys_sleep+0x89>
  }
  release(&tickslock);
80104e4a:	83 ec 0c             	sub    $0xc,%esp
80104e4d:	68 80 4c 12 80       	push   $0x80124c80
80104e52:	e8 6a ef ff ff       	call   80103dc1 <release>
  return 0;
80104e57:	83 c4 10             	add    $0x10,%esp
80104e5a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e5f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e62:	c9                   	leave  
80104e63:	c3                   	ret    
    return -1;
80104e64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e69:	eb f4                	jmp    80104e5f <sys_sleep+0x89>

80104e6b <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104e6b:	55                   	push   %ebp
80104e6c:	89 e5                	mov    %esp,%ebp
80104e6e:	53                   	push   %ebx
80104e6f:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104e72:	68 80 4c 12 80       	push   $0x80124c80
80104e77:	e8 e0 ee ff ff       	call   80103d5c <acquire>
  xticks = ticks;
80104e7c:	8b 1d c0 54 12 80    	mov    0x801254c0,%ebx
  release(&tickslock);
80104e82:	c7 04 24 80 4c 12 80 	movl   $0x80124c80,(%esp)
80104e89:	e8 33 ef ff ff       	call   80103dc1 <release>
  return xticks;
}
80104e8e:	89 d8                	mov    %ebx,%eax
80104e90:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e93:	c9                   	leave  
80104e94:	c3                   	ret    

80104e95 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104e95:	55                   	push   %ebp
80104e96:	89 e5                	mov    %esp,%ebp
80104e98:	83 ec 1c             	sub    $0x1c,%esp
  int* frames;
  int* pids;
  int numframes;

  if(argptr(0, (void*)&frames,sizeof(frames)) < 0)
80104e9b:	6a 04                	push   $0x4
80104e9d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ea0:	50                   	push   %eax
80104ea1:	6a 00                	push   $0x0
80104ea3:	e8 d3 f1 ff ff       	call   8010407b <argptr>
80104ea8:	83 c4 10             	add    $0x10,%esp
80104eab:	85 c0                	test   %eax,%eax
80104ead:	78 42                	js     80104ef1 <sys_dump_physmem+0x5c>
    return -1;
  
  if(argptr(1, (void*)&pids, sizeof(pids)) < 0)
80104eaf:	83 ec 04             	sub    $0x4,%esp
80104eb2:	6a 04                	push   $0x4
80104eb4:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104eb7:	50                   	push   %eax
80104eb8:	6a 01                	push   $0x1
80104eba:	e8 bc f1 ff ff       	call   8010407b <argptr>
80104ebf:	83 c4 10             	add    $0x10,%esp
80104ec2:	85 c0                	test   %eax,%eax
80104ec4:	78 32                	js     80104ef8 <sys_dump_physmem+0x63>
    return -1;
  
  if(argint(2, &numframes) < 0)
80104ec6:	83 ec 08             	sub    $0x8,%esp
80104ec9:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104ecc:	50                   	push   %eax
80104ecd:	6a 02                	push   $0x2
80104ecf:	e8 7f f1 ff ff       	call   80104053 <argint>
80104ed4:	83 c4 10             	add    $0x10,%esp
80104ed7:	85 c0                	test   %eax,%eax
80104ed9:	78 24                	js     80104eff <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
80104edb:	83 ec 04             	sub    $0x4,%esp
80104ede:	ff 75 ec             	pushl  -0x14(%ebp)
80104ee1:	ff 75 f0             	pushl  -0x10(%ebp)
80104ee4:	ff 75 f4             	pushl  -0xc(%ebp)
80104ee7:	e8 bd eb ff ff       	call   80103aa9 <dump_physmem>
80104eec:	83 c4 10             	add    $0x10,%esp
80104eef:	c9                   	leave  
80104ef0:	c3                   	ret    
    return -1;
80104ef1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ef6:	eb f7                	jmp    80104eef <sys_dump_physmem+0x5a>
    return -1;
80104ef8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104efd:	eb f0                	jmp    80104eef <sys_dump_physmem+0x5a>
    return -1;
80104eff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f04:	eb e9                	jmp    80104eef <sys_dump_physmem+0x5a>

80104f06 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104f06:	1e                   	push   %ds
  pushl %es
80104f07:	06                   	push   %es
  pushl %fs
80104f08:	0f a0                	push   %fs
  pushl %gs
80104f0a:	0f a8                	push   %gs
  pushal
80104f0c:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104f0d:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104f11:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104f13:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104f15:	54                   	push   %esp
  call trap
80104f16:	e8 e3 00 00 00       	call   80104ffe <trap>
  addl $4, %esp
80104f1b:	83 c4 04             	add    $0x4,%esp

80104f1e <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104f1e:	61                   	popa   
  popl %gs
80104f1f:	0f a9                	pop    %gs
  popl %fs
80104f21:	0f a1                	pop    %fs
  popl %es
80104f23:	07                   	pop    %es
  popl %ds
80104f24:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104f25:	83 c4 08             	add    $0x8,%esp
  iret
80104f28:	cf                   	iret   

80104f29 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104f29:	55                   	push   %ebp
80104f2a:	89 e5                	mov    %esp,%ebp
80104f2c:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104f2f:	b8 00 00 00 00       	mov    $0x0,%eax
80104f34:	eb 4a                	jmp    80104f80 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104f36:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
80104f3d:	66 89 0c c5 c0 4c 12 	mov    %cx,-0x7fedb340(,%eax,8)
80104f44:	80 
80104f45:	66 c7 04 c5 c2 4c 12 	movw   $0x8,-0x7fedb33e(,%eax,8)
80104f4c:	80 08 00 
80104f4f:	c6 04 c5 c4 4c 12 80 	movb   $0x0,-0x7fedb33c(,%eax,8)
80104f56:	00 
80104f57:	0f b6 14 c5 c5 4c 12 	movzbl -0x7fedb33b(,%eax,8),%edx
80104f5e:	80 
80104f5f:	83 e2 f0             	and    $0xfffffff0,%edx
80104f62:	83 ca 0e             	or     $0xe,%edx
80104f65:	83 e2 8f             	and    $0xffffff8f,%edx
80104f68:	83 ca 80             	or     $0xffffff80,%edx
80104f6b:	88 14 c5 c5 4c 12 80 	mov    %dl,-0x7fedb33b(,%eax,8)
80104f72:	c1 e9 10             	shr    $0x10,%ecx
80104f75:	66 89 0c c5 c6 4c 12 	mov    %cx,-0x7fedb33a(,%eax,8)
80104f7c:	80 
  for(i = 0; i < 256; i++)
80104f7d:	83 c0 01             	add    $0x1,%eax
80104f80:	3d ff 00 00 00       	cmp    $0xff,%eax
80104f85:	7e af                	jle    80104f36 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104f87:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
80104f8d:	66 89 15 c0 4e 12 80 	mov    %dx,0x80124ec0
80104f94:	66 c7 05 c2 4e 12 80 	movw   $0x8,0x80124ec2
80104f9b:	08 00 
80104f9d:	c6 05 c4 4e 12 80 00 	movb   $0x0,0x80124ec4
80104fa4:	0f b6 05 c5 4e 12 80 	movzbl 0x80124ec5,%eax
80104fab:	83 c8 0f             	or     $0xf,%eax
80104fae:	83 e0 ef             	and    $0xffffffef,%eax
80104fb1:	83 c8 e0             	or     $0xffffffe0,%eax
80104fb4:	a2 c5 4e 12 80       	mov    %al,0x80124ec5
80104fb9:	c1 ea 10             	shr    $0x10,%edx
80104fbc:	66 89 15 c6 4e 12 80 	mov    %dx,0x80124ec6

  initlock(&tickslock, "time");
80104fc3:	83 ec 08             	sub    $0x8,%esp
80104fc6:	68 fd 6d 10 80       	push   $0x80106dfd
80104fcb:	68 80 4c 12 80       	push   $0x80124c80
80104fd0:	e8 4b ec ff ff       	call   80103c20 <initlock>
}
80104fd5:	83 c4 10             	add    $0x10,%esp
80104fd8:	c9                   	leave  
80104fd9:	c3                   	ret    

80104fda <idtinit>:

void
idtinit(void)
{
80104fda:	55                   	push   %ebp
80104fdb:	89 e5                	mov    %esp,%ebp
80104fdd:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104fe0:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104fe6:	b8 c0 4c 12 80       	mov    $0x80124cc0,%eax
80104feb:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104fef:	c1 e8 10             	shr    $0x10,%eax
80104ff2:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104ff6:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104ff9:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104ffc:	c9                   	leave  
80104ffd:	c3                   	ret    

80104ffe <trap>:

void
trap(struct trapframe *tf)
{
80104ffe:	55                   	push   %ebp
80104fff:	89 e5                	mov    %esp,%ebp
80105001:	57                   	push   %edi
80105002:	56                   	push   %esi
80105003:	53                   	push   %ebx
80105004:	83 ec 1c             	sub    $0x1c,%esp
80105007:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
8010500a:	8b 43 30             	mov    0x30(%ebx),%eax
8010500d:	83 f8 40             	cmp    $0x40,%eax
80105010:	74 13                	je     80105025 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80105012:	83 e8 20             	sub    $0x20,%eax
80105015:	83 f8 1f             	cmp    $0x1f,%eax
80105018:	0f 87 3a 01 00 00    	ja     80105158 <trap+0x15a>
8010501e:	ff 24 85 a4 6e 10 80 	jmp    *-0x7fef915c(,%eax,4)
    if(myproc()->killed)
80105025:	e8 27 e3 ff ff       	call   80103351 <myproc>
8010502a:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010502e:	75 1f                	jne    8010504f <trap+0x51>
    myproc()->tf = tf;
80105030:	e8 1c e3 ff ff       	call   80103351 <myproc>
80105035:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80105038:	e8 d9 f0 ff ff       	call   80104116 <syscall>
    if(myproc()->killed)
8010503d:	e8 0f e3 ff ff       	call   80103351 <myproc>
80105042:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105046:	74 7e                	je     801050c6 <trap+0xc8>
      exit();
80105048:	e8 b0 e6 ff ff       	call   801036fd <exit>
8010504d:	eb 77                	jmp    801050c6 <trap+0xc8>
      exit();
8010504f:	e8 a9 e6 ff ff       	call   801036fd <exit>
80105054:	eb da                	jmp    80105030 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80105056:	e8 db e2 ff ff       	call   80103336 <cpuid>
8010505b:	85 c0                	test   %eax,%eax
8010505d:	74 6f                	je     801050ce <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
8010505f:	e8 90 d4 ff ff       	call   801024f4 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105064:	e8 e8 e2 ff ff       	call   80103351 <myproc>
80105069:	85 c0                	test   %eax,%eax
8010506b:	74 1c                	je     80105089 <trap+0x8b>
8010506d:	e8 df e2 ff ff       	call   80103351 <myproc>
80105072:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105076:	74 11                	je     80105089 <trap+0x8b>
80105078:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
8010507c:	83 e0 03             	and    $0x3,%eax
8010507f:	66 83 f8 03          	cmp    $0x3,%ax
80105083:	0f 84 62 01 00 00    	je     801051eb <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80105089:	e8 c3 e2 ff ff       	call   80103351 <myproc>
8010508e:	85 c0                	test   %eax,%eax
80105090:	74 0f                	je     801050a1 <trap+0xa3>
80105092:	e8 ba e2 ff ff       	call   80103351 <myproc>
80105097:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
8010509b:	0f 84 54 01 00 00    	je     801051f5 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
801050a1:	e8 ab e2 ff ff       	call   80103351 <myproc>
801050a6:	85 c0                	test   %eax,%eax
801050a8:	74 1c                	je     801050c6 <trap+0xc8>
801050aa:	e8 a2 e2 ff ff       	call   80103351 <myproc>
801050af:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801050b3:	74 11                	je     801050c6 <trap+0xc8>
801050b5:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
801050b9:	83 e0 03             	and    $0x3,%eax
801050bc:	66 83 f8 03          	cmp    $0x3,%ax
801050c0:	0f 84 43 01 00 00    	je     80105209 <trap+0x20b>
    exit();
}
801050c6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801050c9:	5b                   	pop    %ebx
801050ca:	5e                   	pop    %esi
801050cb:	5f                   	pop    %edi
801050cc:	5d                   	pop    %ebp
801050cd:	c3                   	ret    
      acquire(&tickslock);
801050ce:	83 ec 0c             	sub    $0xc,%esp
801050d1:	68 80 4c 12 80       	push   $0x80124c80
801050d6:	e8 81 ec ff ff       	call   80103d5c <acquire>
      ticks++;
801050db:	83 05 c0 54 12 80 01 	addl   $0x1,0x801254c0
      wakeup(&ticks);
801050e2:	c7 04 24 c0 54 12 80 	movl   $0x801254c0,(%esp)
801050e9:	e8 6c e8 ff ff       	call   8010395a <wakeup>
      release(&tickslock);
801050ee:	c7 04 24 80 4c 12 80 	movl   $0x80124c80,(%esp)
801050f5:	e8 c7 ec ff ff       	call   80103dc1 <release>
801050fa:	83 c4 10             	add    $0x10,%esp
801050fd:	e9 5d ff ff ff       	jmp    8010505f <trap+0x61>
    ideintr();
80105102:	e8 6c cc ff ff       	call   80101d73 <ideintr>
    lapiceoi();
80105107:	e8 e8 d3 ff ff       	call   801024f4 <lapiceoi>
    break;
8010510c:	e9 53 ff ff ff       	jmp    80105064 <trap+0x66>
    kbdintr();
80105111:	e8 22 d2 ff ff       	call   80102338 <kbdintr>
    lapiceoi();
80105116:	e8 d9 d3 ff ff       	call   801024f4 <lapiceoi>
    break;
8010511b:	e9 44 ff ff ff       	jmp    80105064 <trap+0x66>
    uartintr();
80105120:	e8 05 02 00 00       	call   8010532a <uartintr>
    lapiceoi();
80105125:	e8 ca d3 ff ff       	call   801024f4 <lapiceoi>
    break;
8010512a:	e9 35 ff ff ff       	jmp    80105064 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010512f:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
80105132:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105136:	e8 fb e1 ff ff       	call   80103336 <cpuid>
8010513b:	57                   	push   %edi
8010513c:	0f b7 f6             	movzwl %si,%esi
8010513f:	56                   	push   %esi
80105140:	50                   	push   %eax
80105141:	68 08 6e 10 80       	push   $0x80106e08
80105146:	e8 c0 b4 ff ff       	call   8010060b <cprintf>
    lapiceoi();
8010514b:	e8 a4 d3 ff ff       	call   801024f4 <lapiceoi>
    break;
80105150:	83 c4 10             	add    $0x10,%esp
80105153:	e9 0c ff ff ff       	jmp    80105064 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
80105158:	e8 f4 e1 ff ff       	call   80103351 <myproc>
8010515d:	85 c0                	test   %eax,%eax
8010515f:	74 5f                	je     801051c0 <trap+0x1c2>
80105161:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80105165:	74 59                	je     801051c0 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80105167:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010516a:	8b 43 38             	mov    0x38(%ebx),%eax
8010516d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105170:	e8 c1 e1 ff ff       	call   80103336 <cpuid>
80105175:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105178:	8b 53 34             	mov    0x34(%ebx),%edx
8010517b:	89 55 dc             	mov    %edx,-0x24(%ebp)
8010517e:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
80105181:	e8 cb e1 ff ff       	call   80103351 <myproc>
80105186:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105189:	89 4d d8             	mov    %ecx,-0x28(%ebp)
8010518c:	e8 c0 e1 ff ff       	call   80103351 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105191:	57                   	push   %edi
80105192:	ff 75 e4             	pushl  -0x1c(%ebp)
80105195:	ff 75 e0             	pushl  -0x20(%ebp)
80105198:	ff 75 dc             	pushl  -0x24(%ebp)
8010519b:	56                   	push   %esi
8010519c:	ff 75 d8             	pushl  -0x28(%ebp)
8010519f:	ff 70 10             	pushl  0x10(%eax)
801051a2:	68 60 6e 10 80       	push   $0x80106e60
801051a7:	e8 5f b4 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
801051ac:	83 c4 20             	add    $0x20,%esp
801051af:	e8 9d e1 ff ff       	call   80103351 <myproc>
801051b4:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801051bb:	e9 a4 fe ff ff       	jmp    80105064 <trap+0x66>
801051c0:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801051c3:	8b 73 38             	mov    0x38(%ebx),%esi
801051c6:	e8 6b e1 ff ff       	call   80103336 <cpuid>
801051cb:	83 ec 0c             	sub    $0xc,%esp
801051ce:	57                   	push   %edi
801051cf:	56                   	push   %esi
801051d0:	50                   	push   %eax
801051d1:	ff 73 30             	pushl  0x30(%ebx)
801051d4:	68 2c 6e 10 80       	push   $0x80106e2c
801051d9:	e8 2d b4 ff ff       	call   8010060b <cprintf>
      panic("trap");
801051de:	83 c4 14             	add    $0x14,%esp
801051e1:	68 02 6e 10 80       	push   $0x80106e02
801051e6:	e8 5d b1 ff ff       	call   80100348 <panic>
    exit();
801051eb:	e8 0d e5 ff ff       	call   801036fd <exit>
801051f0:	e9 94 fe ff ff       	jmp    80105089 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
801051f5:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
801051f9:	0f 85 a2 fe ff ff    	jne    801050a1 <trap+0xa3>
    yield();
801051ff:	e8 bf e5 ff ff       	call   801037c3 <yield>
80105204:	e9 98 fe ff ff       	jmp    801050a1 <trap+0xa3>
    exit();
80105209:	e8 ef e4 ff ff       	call   801036fd <exit>
8010520e:	e9 b3 fe ff ff       	jmp    801050c6 <trap+0xc8>

80105213 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
80105213:	55                   	push   %ebp
80105214:	89 e5                	mov    %esp,%ebp
  if(!uart)
80105216:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
8010521d:	74 15                	je     80105234 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010521f:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105224:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
80105225:	a8 01                	test   $0x1,%al
80105227:	74 12                	je     8010523b <uartgetc+0x28>
80105229:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010522e:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
8010522f:	0f b6 c0             	movzbl %al,%eax
}
80105232:	5d                   	pop    %ebp
80105233:	c3                   	ret    
    return -1;
80105234:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105239:	eb f7                	jmp    80105232 <uartgetc+0x1f>
    return -1;
8010523b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105240:	eb f0                	jmp    80105232 <uartgetc+0x1f>

80105242 <uartputc>:
  if(!uart)
80105242:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
80105249:	74 3b                	je     80105286 <uartputc+0x44>
{
8010524b:	55                   	push   %ebp
8010524c:	89 e5                	mov    %esp,%ebp
8010524e:	53                   	push   %ebx
8010524f:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105252:	bb 00 00 00 00       	mov    $0x0,%ebx
80105257:	eb 10                	jmp    80105269 <uartputc+0x27>
    microdelay(10);
80105259:	83 ec 0c             	sub    $0xc,%esp
8010525c:	6a 0a                	push   $0xa
8010525e:	e8 b0 d2 ff ff       	call   80102513 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105263:	83 c3 01             	add    $0x1,%ebx
80105266:	83 c4 10             	add    $0x10,%esp
80105269:	83 fb 7f             	cmp    $0x7f,%ebx
8010526c:	7f 0a                	jg     80105278 <uartputc+0x36>
8010526e:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105273:	ec                   	in     (%dx),%al
80105274:	a8 20                	test   $0x20,%al
80105276:	74 e1                	je     80105259 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80105278:	8b 45 08             	mov    0x8(%ebp),%eax
8010527b:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105280:	ee                   	out    %al,(%dx)
}
80105281:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105284:	c9                   	leave  
80105285:	c3                   	ret    
80105286:	f3 c3                	repz ret 

80105288 <uartinit>:
{
80105288:	55                   	push   %ebp
80105289:	89 e5                	mov    %esp,%ebp
8010528b:	56                   	push   %esi
8010528c:	53                   	push   %ebx
8010528d:	b9 00 00 00 00       	mov    $0x0,%ecx
80105292:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105297:	89 c8                	mov    %ecx,%eax
80105299:	ee                   	out    %al,(%dx)
8010529a:	be fb 03 00 00       	mov    $0x3fb,%esi
8010529f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
801052a4:	89 f2                	mov    %esi,%edx
801052a6:	ee                   	out    %al,(%dx)
801052a7:	b8 0c 00 00 00       	mov    $0xc,%eax
801052ac:	ba f8 03 00 00       	mov    $0x3f8,%edx
801052b1:	ee                   	out    %al,(%dx)
801052b2:	bb f9 03 00 00       	mov    $0x3f9,%ebx
801052b7:	89 c8                	mov    %ecx,%eax
801052b9:	89 da                	mov    %ebx,%edx
801052bb:	ee                   	out    %al,(%dx)
801052bc:	b8 03 00 00 00       	mov    $0x3,%eax
801052c1:	89 f2                	mov    %esi,%edx
801052c3:	ee                   	out    %al,(%dx)
801052c4:	ba fc 03 00 00       	mov    $0x3fc,%edx
801052c9:	89 c8                	mov    %ecx,%eax
801052cb:	ee                   	out    %al,(%dx)
801052cc:	b8 01 00 00 00       	mov    $0x1,%eax
801052d1:	89 da                	mov    %ebx,%edx
801052d3:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801052d4:	ba fd 03 00 00       	mov    $0x3fd,%edx
801052d9:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
801052da:	3c ff                	cmp    $0xff,%al
801052dc:	74 45                	je     80105323 <uartinit+0x9b>
  uart = 1;
801052de:	c7 05 bc a5 10 80 01 	movl   $0x1,0x8010a5bc
801052e5:	00 00 00 
801052e8:	ba fa 03 00 00       	mov    $0x3fa,%edx
801052ed:	ec                   	in     (%dx),%al
801052ee:	ba f8 03 00 00       	mov    $0x3f8,%edx
801052f3:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
801052f4:	83 ec 08             	sub    $0x8,%esp
801052f7:	6a 00                	push   $0x0
801052f9:	6a 04                	push   $0x4
801052fb:	e8 7e cc ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
80105300:	83 c4 10             	add    $0x10,%esp
80105303:	bb 24 6f 10 80       	mov    $0x80106f24,%ebx
80105308:	eb 12                	jmp    8010531c <uartinit+0x94>
    uartputc(*p);
8010530a:	83 ec 0c             	sub    $0xc,%esp
8010530d:	0f be c0             	movsbl %al,%eax
80105310:	50                   	push   %eax
80105311:	e8 2c ff ff ff       	call   80105242 <uartputc>
  for(p="xv6...\n"; *p; p++)
80105316:	83 c3 01             	add    $0x1,%ebx
80105319:	83 c4 10             	add    $0x10,%esp
8010531c:	0f b6 03             	movzbl (%ebx),%eax
8010531f:	84 c0                	test   %al,%al
80105321:	75 e7                	jne    8010530a <uartinit+0x82>
}
80105323:	8d 65 f8             	lea    -0x8(%ebp),%esp
80105326:	5b                   	pop    %ebx
80105327:	5e                   	pop    %esi
80105328:	5d                   	pop    %ebp
80105329:	c3                   	ret    

8010532a <uartintr>:

void
uartintr(void)
{
8010532a:	55                   	push   %ebp
8010532b:	89 e5                	mov    %esp,%ebp
8010532d:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
80105330:	68 13 52 10 80       	push   $0x80105213
80105335:	e8 04 b4 ff ff       	call   8010073e <consoleintr>
}
8010533a:	83 c4 10             	add    $0x10,%esp
8010533d:	c9                   	leave  
8010533e:	c3                   	ret    

8010533f <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
8010533f:	6a 00                	push   $0x0
  pushl $0
80105341:	6a 00                	push   $0x0
  jmp alltraps
80105343:	e9 be fb ff ff       	jmp    80104f06 <alltraps>

80105348 <vector1>:
.globl vector1
vector1:
  pushl $0
80105348:	6a 00                	push   $0x0
  pushl $1
8010534a:	6a 01                	push   $0x1
  jmp alltraps
8010534c:	e9 b5 fb ff ff       	jmp    80104f06 <alltraps>

80105351 <vector2>:
.globl vector2
vector2:
  pushl $0
80105351:	6a 00                	push   $0x0
  pushl $2
80105353:	6a 02                	push   $0x2
  jmp alltraps
80105355:	e9 ac fb ff ff       	jmp    80104f06 <alltraps>

8010535a <vector3>:
.globl vector3
vector3:
  pushl $0
8010535a:	6a 00                	push   $0x0
  pushl $3
8010535c:	6a 03                	push   $0x3
  jmp alltraps
8010535e:	e9 a3 fb ff ff       	jmp    80104f06 <alltraps>

80105363 <vector4>:
.globl vector4
vector4:
  pushl $0
80105363:	6a 00                	push   $0x0
  pushl $4
80105365:	6a 04                	push   $0x4
  jmp alltraps
80105367:	e9 9a fb ff ff       	jmp    80104f06 <alltraps>

8010536c <vector5>:
.globl vector5
vector5:
  pushl $0
8010536c:	6a 00                	push   $0x0
  pushl $5
8010536e:	6a 05                	push   $0x5
  jmp alltraps
80105370:	e9 91 fb ff ff       	jmp    80104f06 <alltraps>

80105375 <vector6>:
.globl vector6
vector6:
  pushl $0
80105375:	6a 00                	push   $0x0
  pushl $6
80105377:	6a 06                	push   $0x6
  jmp alltraps
80105379:	e9 88 fb ff ff       	jmp    80104f06 <alltraps>

8010537e <vector7>:
.globl vector7
vector7:
  pushl $0
8010537e:	6a 00                	push   $0x0
  pushl $7
80105380:	6a 07                	push   $0x7
  jmp alltraps
80105382:	e9 7f fb ff ff       	jmp    80104f06 <alltraps>

80105387 <vector8>:
.globl vector8
vector8:
  pushl $8
80105387:	6a 08                	push   $0x8
  jmp alltraps
80105389:	e9 78 fb ff ff       	jmp    80104f06 <alltraps>

8010538e <vector9>:
.globl vector9
vector9:
  pushl $0
8010538e:	6a 00                	push   $0x0
  pushl $9
80105390:	6a 09                	push   $0x9
  jmp alltraps
80105392:	e9 6f fb ff ff       	jmp    80104f06 <alltraps>

80105397 <vector10>:
.globl vector10
vector10:
  pushl $10
80105397:	6a 0a                	push   $0xa
  jmp alltraps
80105399:	e9 68 fb ff ff       	jmp    80104f06 <alltraps>

8010539e <vector11>:
.globl vector11
vector11:
  pushl $11
8010539e:	6a 0b                	push   $0xb
  jmp alltraps
801053a0:	e9 61 fb ff ff       	jmp    80104f06 <alltraps>

801053a5 <vector12>:
.globl vector12
vector12:
  pushl $12
801053a5:	6a 0c                	push   $0xc
  jmp alltraps
801053a7:	e9 5a fb ff ff       	jmp    80104f06 <alltraps>

801053ac <vector13>:
.globl vector13
vector13:
  pushl $13
801053ac:	6a 0d                	push   $0xd
  jmp alltraps
801053ae:	e9 53 fb ff ff       	jmp    80104f06 <alltraps>

801053b3 <vector14>:
.globl vector14
vector14:
  pushl $14
801053b3:	6a 0e                	push   $0xe
  jmp alltraps
801053b5:	e9 4c fb ff ff       	jmp    80104f06 <alltraps>

801053ba <vector15>:
.globl vector15
vector15:
  pushl $0
801053ba:	6a 00                	push   $0x0
  pushl $15
801053bc:	6a 0f                	push   $0xf
  jmp alltraps
801053be:	e9 43 fb ff ff       	jmp    80104f06 <alltraps>

801053c3 <vector16>:
.globl vector16
vector16:
  pushl $0
801053c3:	6a 00                	push   $0x0
  pushl $16
801053c5:	6a 10                	push   $0x10
  jmp alltraps
801053c7:	e9 3a fb ff ff       	jmp    80104f06 <alltraps>

801053cc <vector17>:
.globl vector17
vector17:
  pushl $17
801053cc:	6a 11                	push   $0x11
  jmp alltraps
801053ce:	e9 33 fb ff ff       	jmp    80104f06 <alltraps>

801053d3 <vector18>:
.globl vector18
vector18:
  pushl $0
801053d3:	6a 00                	push   $0x0
  pushl $18
801053d5:	6a 12                	push   $0x12
  jmp alltraps
801053d7:	e9 2a fb ff ff       	jmp    80104f06 <alltraps>

801053dc <vector19>:
.globl vector19
vector19:
  pushl $0
801053dc:	6a 00                	push   $0x0
  pushl $19
801053de:	6a 13                	push   $0x13
  jmp alltraps
801053e0:	e9 21 fb ff ff       	jmp    80104f06 <alltraps>

801053e5 <vector20>:
.globl vector20
vector20:
  pushl $0
801053e5:	6a 00                	push   $0x0
  pushl $20
801053e7:	6a 14                	push   $0x14
  jmp alltraps
801053e9:	e9 18 fb ff ff       	jmp    80104f06 <alltraps>

801053ee <vector21>:
.globl vector21
vector21:
  pushl $0
801053ee:	6a 00                	push   $0x0
  pushl $21
801053f0:	6a 15                	push   $0x15
  jmp alltraps
801053f2:	e9 0f fb ff ff       	jmp    80104f06 <alltraps>

801053f7 <vector22>:
.globl vector22
vector22:
  pushl $0
801053f7:	6a 00                	push   $0x0
  pushl $22
801053f9:	6a 16                	push   $0x16
  jmp alltraps
801053fb:	e9 06 fb ff ff       	jmp    80104f06 <alltraps>

80105400 <vector23>:
.globl vector23
vector23:
  pushl $0
80105400:	6a 00                	push   $0x0
  pushl $23
80105402:	6a 17                	push   $0x17
  jmp alltraps
80105404:	e9 fd fa ff ff       	jmp    80104f06 <alltraps>

80105409 <vector24>:
.globl vector24
vector24:
  pushl $0
80105409:	6a 00                	push   $0x0
  pushl $24
8010540b:	6a 18                	push   $0x18
  jmp alltraps
8010540d:	e9 f4 fa ff ff       	jmp    80104f06 <alltraps>

80105412 <vector25>:
.globl vector25
vector25:
  pushl $0
80105412:	6a 00                	push   $0x0
  pushl $25
80105414:	6a 19                	push   $0x19
  jmp alltraps
80105416:	e9 eb fa ff ff       	jmp    80104f06 <alltraps>

8010541b <vector26>:
.globl vector26
vector26:
  pushl $0
8010541b:	6a 00                	push   $0x0
  pushl $26
8010541d:	6a 1a                	push   $0x1a
  jmp alltraps
8010541f:	e9 e2 fa ff ff       	jmp    80104f06 <alltraps>

80105424 <vector27>:
.globl vector27
vector27:
  pushl $0
80105424:	6a 00                	push   $0x0
  pushl $27
80105426:	6a 1b                	push   $0x1b
  jmp alltraps
80105428:	e9 d9 fa ff ff       	jmp    80104f06 <alltraps>

8010542d <vector28>:
.globl vector28
vector28:
  pushl $0
8010542d:	6a 00                	push   $0x0
  pushl $28
8010542f:	6a 1c                	push   $0x1c
  jmp alltraps
80105431:	e9 d0 fa ff ff       	jmp    80104f06 <alltraps>

80105436 <vector29>:
.globl vector29
vector29:
  pushl $0
80105436:	6a 00                	push   $0x0
  pushl $29
80105438:	6a 1d                	push   $0x1d
  jmp alltraps
8010543a:	e9 c7 fa ff ff       	jmp    80104f06 <alltraps>

8010543f <vector30>:
.globl vector30
vector30:
  pushl $0
8010543f:	6a 00                	push   $0x0
  pushl $30
80105441:	6a 1e                	push   $0x1e
  jmp alltraps
80105443:	e9 be fa ff ff       	jmp    80104f06 <alltraps>

80105448 <vector31>:
.globl vector31
vector31:
  pushl $0
80105448:	6a 00                	push   $0x0
  pushl $31
8010544a:	6a 1f                	push   $0x1f
  jmp alltraps
8010544c:	e9 b5 fa ff ff       	jmp    80104f06 <alltraps>

80105451 <vector32>:
.globl vector32
vector32:
  pushl $0
80105451:	6a 00                	push   $0x0
  pushl $32
80105453:	6a 20                	push   $0x20
  jmp alltraps
80105455:	e9 ac fa ff ff       	jmp    80104f06 <alltraps>

8010545a <vector33>:
.globl vector33
vector33:
  pushl $0
8010545a:	6a 00                	push   $0x0
  pushl $33
8010545c:	6a 21                	push   $0x21
  jmp alltraps
8010545e:	e9 a3 fa ff ff       	jmp    80104f06 <alltraps>

80105463 <vector34>:
.globl vector34
vector34:
  pushl $0
80105463:	6a 00                	push   $0x0
  pushl $34
80105465:	6a 22                	push   $0x22
  jmp alltraps
80105467:	e9 9a fa ff ff       	jmp    80104f06 <alltraps>

8010546c <vector35>:
.globl vector35
vector35:
  pushl $0
8010546c:	6a 00                	push   $0x0
  pushl $35
8010546e:	6a 23                	push   $0x23
  jmp alltraps
80105470:	e9 91 fa ff ff       	jmp    80104f06 <alltraps>

80105475 <vector36>:
.globl vector36
vector36:
  pushl $0
80105475:	6a 00                	push   $0x0
  pushl $36
80105477:	6a 24                	push   $0x24
  jmp alltraps
80105479:	e9 88 fa ff ff       	jmp    80104f06 <alltraps>

8010547e <vector37>:
.globl vector37
vector37:
  pushl $0
8010547e:	6a 00                	push   $0x0
  pushl $37
80105480:	6a 25                	push   $0x25
  jmp alltraps
80105482:	e9 7f fa ff ff       	jmp    80104f06 <alltraps>

80105487 <vector38>:
.globl vector38
vector38:
  pushl $0
80105487:	6a 00                	push   $0x0
  pushl $38
80105489:	6a 26                	push   $0x26
  jmp alltraps
8010548b:	e9 76 fa ff ff       	jmp    80104f06 <alltraps>

80105490 <vector39>:
.globl vector39
vector39:
  pushl $0
80105490:	6a 00                	push   $0x0
  pushl $39
80105492:	6a 27                	push   $0x27
  jmp alltraps
80105494:	e9 6d fa ff ff       	jmp    80104f06 <alltraps>

80105499 <vector40>:
.globl vector40
vector40:
  pushl $0
80105499:	6a 00                	push   $0x0
  pushl $40
8010549b:	6a 28                	push   $0x28
  jmp alltraps
8010549d:	e9 64 fa ff ff       	jmp    80104f06 <alltraps>

801054a2 <vector41>:
.globl vector41
vector41:
  pushl $0
801054a2:	6a 00                	push   $0x0
  pushl $41
801054a4:	6a 29                	push   $0x29
  jmp alltraps
801054a6:	e9 5b fa ff ff       	jmp    80104f06 <alltraps>

801054ab <vector42>:
.globl vector42
vector42:
  pushl $0
801054ab:	6a 00                	push   $0x0
  pushl $42
801054ad:	6a 2a                	push   $0x2a
  jmp alltraps
801054af:	e9 52 fa ff ff       	jmp    80104f06 <alltraps>

801054b4 <vector43>:
.globl vector43
vector43:
  pushl $0
801054b4:	6a 00                	push   $0x0
  pushl $43
801054b6:	6a 2b                	push   $0x2b
  jmp alltraps
801054b8:	e9 49 fa ff ff       	jmp    80104f06 <alltraps>

801054bd <vector44>:
.globl vector44
vector44:
  pushl $0
801054bd:	6a 00                	push   $0x0
  pushl $44
801054bf:	6a 2c                	push   $0x2c
  jmp alltraps
801054c1:	e9 40 fa ff ff       	jmp    80104f06 <alltraps>

801054c6 <vector45>:
.globl vector45
vector45:
  pushl $0
801054c6:	6a 00                	push   $0x0
  pushl $45
801054c8:	6a 2d                	push   $0x2d
  jmp alltraps
801054ca:	e9 37 fa ff ff       	jmp    80104f06 <alltraps>

801054cf <vector46>:
.globl vector46
vector46:
  pushl $0
801054cf:	6a 00                	push   $0x0
  pushl $46
801054d1:	6a 2e                	push   $0x2e
  jmp alltraps
801054d3:	e9 2e fa ff ff       	jmp    80104f06 <alltraps>

801054d8 <vector47>:
.globl vector47
vector47:
  pushl $0
801054d8:	6a 00                	push   $0x0
  pushl $47
801054da:	6a 2f                	push   $0x2f
  jmp alltraps
801054dc:	e9 25 fa ff ff       	jmp    80104f06 <alltraps>

801054e1 <vector48>:
.globl vector48
vector48:
  pushl $0
801054e1:	6a 00                	push   $0x0
  pushl $48
801054e3:	6a 30                	push   $0x30
  jmp alltraps
801054e5:	e9 1c fa ff ff       	jmp    80104f06 <alltraps>

801054ea <vector49>:
.globl vector49
vector49:
  pushl $0
801054ea:	6a 00                	push   $0x0
  pushl $49
801054ec:	6a 31                	push   $0x31
  jmp alltraps
801054ee:	e9 13 fa ff ff       	jmp    80104f06 <alltraps>

801054f3 <vector50>:
.globl vector50
vector50:
  pushl $0
801054f3:	6a 00                	push   $0x0
  pushl $50
801054f5:	6a 32                	push   $0x32
  jmp alltraps
801054f7:	e9 0a fa ff ff       	jmp    80104f06 <alltraps>

801054fc <vector51>:
.globl vector51
vector51:
  pushl $0
801054fc:	6a 00                	push   $0x0
  pushl $51
801054fe:	6a 33                	push   $0x33
  jmp alltraps
80105500:	e9 01 fa ff ff       	jmp    80104f06 <alltraps>

80105505 <vector52>:
.globl vector52
vector52:
  pushl $0
80105505:	6a 00                	push   $0x0
  pushl $52
80105507:	6a 34                	push   $0x34
  jmp alltraps
80105509:	e9 f8 f9 ff ff       	jmp    80104f06 <alltraps>

8010550e <vector53>:
.globl vector53
vector53:
  pushl $0
8010550e:	6a 00                	push   $0x0
  pushl $53
80105510:	6a 35                	push   $0x35
  jmp alltraps
80105512:	e9 ef f9 ff ff       	jmp    80104f06 <alltraps>

80105517 <vector54>:
.globl vector54
vector54:
  pushl $0
80105517:	6a 00                	push   $0x0
  pushl $54
80105519:	6a 36                	push   $0x36
  jmp alltraps
8010551b:	e9 e6 f9 ff ff       	jmp    80104f06 <alltraps>

80105520 <vector55>:
.globl vector55
vector55:
  pushl $0
80105520:	6a 00                	push   $0x0
  pushl $55
80105522:	6a 37                	push   $0x37
  jmp alltraps
80105524:	e9 dd f9 ff ff       	jmp    80104f06 <alltraps>

80105529 <vector56>:
.globl vector56
vector56:
  pushl $0
80105529:	6a 00                	push   $0x0
  pushl $56
8010552b:	6a 38                	push   $0x38
  jmp alltraps
8010552d:	e9 d4 f9 ff ff       	jmp    80104f06 <alltraps>

80105532 <vector57>:
.globl vector57
vector57:
  pushl $0
80105532:	6a 00                	push   $0x0
  pushl $57
80105534:	6a 39                	push   $0x39
  jmp alltraps
80105536:	e9 cb f9 ff ff       	jmp    80104f06 <alltraps>

8010553b <vector58>:
.globl vector58
vector58:
  pushl $0
8010553b:	6a 00                	push   $0x0
  pushl $58
8010553d:	6a 3a                	push   $0x3a
  jmp alltraps
8010553f:	e9 c2 f9 ff ff       	jmp    80104f06 <alltraps>

80105544 <vector59>:
.globl vector59
vector59:
  pushl $0
80105544:	6a 00                	push   $0x0
  pushl $59
80105546:	6a 3b                	push   $0x3b
  jmp alltraps
80105548:	e9 b9 f9 ff ff       	jmp    80104f06 <alltraps>

8010554d <vector60>:
.globl vector60
vector60:
  pushl $0
8010554d:	6a 00                	push   $0x0
  pushl $60
8010554f:	6a 3c                	push   $0x3c
  jmp alltraps
80105551:	e9 b0 f9 ff ff       	jmp    80104f06 <alltraps>

80105556 <vector61>:
.globl vector61
vector61:
  pushl $0
80105556:	6a 00                	push   $0x0
  pushl $61
80105558:	6a 3d                	push   $0x3d
  jmp alltraps
8010555a:	e9 a7 f9 ff ff       	jmp    80104f06 <alltraps>

8010555f <vector62>:
.globl vector62
vector62:
  pushl $0
8010555f:	6a 00                	push   $0x0
  pushl $62
80105561:	6a 3e                	push   $0x3e
  jmp alltraps
80105563:	e9 9e f9 ff ff       	jmp    80104f06 <alltraps>

80105568 <vector63>:
.globl vector63
vector63:
  pushl $0
80105568:	6a 00                	push   $0x0
  pushl $63
8010556a:	6a 3f                	push   $0x3f
  jmp alltraps
8010556c:	e9 95 f9 ff ff       	jmp    80104f06 <alltraps>

80105571 <vector64>:
.globl vector64
vector64:
  pushl $0
80105571:	6a 00                	push   $0x0
  pushl $64
80105573:	6a 40                	push   $0x40
  jmp alltraps
80105575:	e9 8c f9 ff ff       	jmp    80104f06 <alltraps>

8010557a <vector65>:
.globl vector65
vector65:
  pushl $0
8010557a:	6a 00                	push   $0x0
  pushl $65
8010557c:	6a 41                	push   $0x41
  jmp alltraps
8010557e:	e9 83 f9 ff ff       	jmp    80104f06 <alltraps>

80105583 <vector66>:
.globl vector66
vector66:
  pushl $0
80105583:	6a 00                	push   $0x0
  pushl $66
80105585:	6a 42                	push   $0x42
  jmp alltraps
80105587:	e9 7a f9 ff ff       	jmp    80104f06 <alltraps>

8010558c <vector67>:
.globl vector67
vector67:
  pushl $0
8010558c:	6a 00                	push   $0x0
  pushl $67
8010558e:	6a 43                	push   $0x43
  jmp alltraps
80105590:	e9 71 f9 ff ff       	jmp    80104f06 <alltraps>

80105595 <vector68>:
.globl vector68
vector68:
  pushl $0
80105595:	6a 00                	push   $0x0
  pushl $68
80105597:	6a 44                	push   $0x44
  jmp alltraps
80105599:	e9 68 f9 ff ff       	jmp    80104f06 <alltraps>

8010559e <vector69>:
.globl vector69
vector69:
  pushl $0
8010559e:	6a 00                	push   $0x0
  pushl $69
801055a0:	6a 45                	push   $0x45
  jmp alltraps
801055a2:	e9 5f f9 ff ff       	jmp    80104f06 <alltraps>

801055a7 <vector70>:
.globl vector70
vector70:
  pushl $0
801055a7:	6a 00                	push   $0x0
  pushl $70
801055a9:	6a 46                	push   $0x46
  jmp alltraps
801055ab:	e9 56 f9 ff ff       	jmp    80104f06 <alltraps>

801055b0 <vector71>:
.globl vector71
vector71:
  pushl $0
801055b0:	6a 00                	push   $0x0
  pushl $71
801055b2:	6a 47                	push   $0x47
  jmp alltraps
801055b4:	e9 4d f9 ff ff       	jmp    80104f06 <alltraps>

801055b9 <vector72>:
.globl vector72
vector72:
  pushl $0
801055b9:	6a 00                	push   $0x0
  pushl $72
801055bb:	6a 48                	push   $0x48
  jmp alltraps
801055bd:	e9 44 f9 ff ff       	jmp    80104f06 <alltraps>

801055c2 <vector73>:
.globl vector73
vector73:
  pushl $0
801055c2:	6a 00                	push   $0x0
  pushl $73
801055c4:	6a 49                	push   $0x49
  jmp alltraps
801055c6:	e9 3b f9 ff ff       	jmp    80104f06 <alltraps>

801055cb <vector74>:
.globl vector74
vector74:
  pushl $0
801055cb:	6a 00                	push   $0x0
  pushl $74
801055cd:	6a 4a                	push   $0x4a
  jmp alltraps
801055cf:	e9 32 f9 ff ff       	jmp    80104f06 <alltraps>

801055d4 <vector75>:
.globl vector75
vector75:
  pushl $0
801055d4:	6a 00                	push   $0x0
  pushl $75
801055d6:	6a 4b                	push   $0x4b
  jmp alltraps
801055d8:	e9 29 f9 ff ff       	jmp    80104f06 <alltraps>

801055dd <vector76>:
.globl vector76
vector76:
  pushl $0
801055dd:	6a 00                	push   $0x0
  pushl $76
801055df:	6a 4c                	push   $0x4c
  jmp alltraps
801055e1:	e9 20 f9 ff ff       	jmp    80104f06 <alltraps>

801055e6 <vector77>:
.globl vector77
vector77:
  pushl $0
801055e6:	6a 00                	push   $0x0
  pushl $77
801055e8:	6a 4d                	push   $0x4d
  jmp alltraps
801055ea:	e9 17 f9 ff ff       	jmp    80104f06 <alltraps>

801055ef <vector78>:
.globl vector78
vector78:
  pushl $0
801055ef:	6a 00                	push   $0x0
  pushl $78
801055f1:	6a 4e                	push   $0x4e
  jmp alltraps
801055f3:	e9 0e f9 ff ff       	jmp    80104f06 <alltraps>

801055f8 <vector79>:
.globl vector79
vector79:
  pushl $0
801055f8:	6a 00                	push   $0x0
  pushl $79
801055fa:	6a 4f                	push   $0x4f
  jmp alltraps
801055fc:	e9 05 f9 ff ff       	jmp    80104f06 <alltraps>

80105601 <vector80>:
.globl vector80
vector80:
  pushl $0
80105601:	6a 00                	push   $0x0
  pushl $80
80105603:	6a 50                	push   $0x50
  jmp alltraps
80105605:	e9 fc f8 ff ff       	jmp    80104f06 <alltraps>

8010560a <vector81>:
.globl vector81
vector81:
  pushl $0
8010560a:	6a 00                	push   $0x0
  pushl $81
8010560c:	6a 51                	push   $0x51
  jmp alltraps
8010560e:	e9 f3 f8 ff ff       	jmp    80104f06 <alltraps>

80105613 <vector82>:
.globl vector82
vector82:
  pushl $0
80105613:	6a 00                	push   $0x0
  pushl $82
80105615:	6a 52                	push   $0x52
  jmp alltraps
80105617:	e9 ea f8 ff ff       	jmp    80104f06 <alltraps>

8010561c <vector83>:
.globl vector83
vector83:
  pushl $0
8010561c:	6a 00                	push   $0x0
  pushl $83
8010561e:	6a 53                	push   $0x53
  jmp alltraps
80105620:	e9 e1 f8 ff ff       	jmp    80104f06 <alltraps>

80105625 <vector84>:
.globl vector84
vector84:
  pushl $0
80105625:	6a 00                	push   $0x0
  pushl $84
80105627:	6a 54                	push   $0x54
  jmp alltraps
80105629:	e9 d8 f8 ff ff       	jmp    80104f06 <alltraps>

8010562e <vector85>:
.globl vector85
vector85:
  pushl $0
8010562e:	6a 00                	push   $0x0
  pushl $85
80105630:	6a 55                	push   $0x55
  jmp alltraps
80105632:	e9 cf f8 ff ff       	jmp    80104f06 <alltraps>

80105637 <vector86>:
.globl vector86
vector86:
  pushl $0
80105637:	6a 00                	push   $0x0
  pushl $86
80105639:	6a 56                	push   $0x56
  jmp alltraps
8010563b:	e9 c6 f8 ff ff       	jmp    80104f06 <alltraps>

80105640 <vector87>:
.globl vector87
vector87:
  pushl $0
80105640:	6a 00                	push   $0x0
  pushl $87
80105642:	6a 57                	push   $0x57
  jmp alltraps
80105644:	e9 bd f8 ff ff       	jmp    80104f06 <alltraps>

80105649 <vector88>:
.globl vector88
vector88:
  pushl $0
80105649:	6a 00                	push   $0x0
  pushl $88
8010564b:	6a 58                	push   $0x58
  jmp alltraps
8010564d:	e9 b4 f8 ff ff       	jmp    80104f06 <alltraps>

80105652 <vector89>:
.globl vector89
vector89:
  pushl $0
80105652:	6a 00                	push   $0x0
  pushl $89
80105654:	6a 59                	push   $0x59
  jmp alltraps
80105656:	e9 ab f8 ff ff       	jmp    80104f06 <alltraps>

8010565b <vector90>:
.globl vector90
vector90:
  pushl $0
8010565b:	6a 00                	push   $0x0
  pushl $90
8010565d:	6a 5a                	push   $0x5a
  jmp alltraps
8010565f:	e9 a2 f8 ff ff       	jmp    80104f06 <alltraps>

80105664 <vector91>:
.globl vector91
vector91:
  pushl $0
80105664:	6a 00                	push   $0x0
  pushl $91
80105666:	6a 5b                	push   $0x5b
  jmp alltraps
80105668:	e9 99 f8 ff ff       	jmp    80104f06 <alltraps>

8010566d <vector92>:
.globl vector92
vector92:
  pushl $0
8010566d:	6a 00                	push   $0x0
  pushl $92
8010566f:	6a 5c                	push   $0x5c
  jmp alltraps
80105671:	e9 90 f8 ff ff       	jmp    80104f06 <alltraps>

80105676 <vector93>:
.globl vector93
vector93:
  pushl $0
80105676:	6a 00                	push   $0x0
  pushl $93
80105678:	6a 5d                	push   $0x5d
  jmp alltraps
8010567a:	e9 87 f8 ff ff       	jmp    80104f06 <alltraps>

8010567f <vector94>:
.globl vector94
vector94:
  pushl $0
8010567f:	6a 00                	push   $0x0
  pushl $94
80105681:	6a 5e                	push   $0x5e
  jmp alltraps
80105683:	e9 7e f8 ff ff       	jmp    80104f06 <alltraps>

80105688 <vector95>:
.globl vector95
vector95:
  pushl $0
80105688:	6a 00                	push   $0x0
  pushl $95
8010568a:	6a 5f                	push   $0x5f
  jmp alltraps
8010568c:	e9 75 f8 ff ff       	jmp    80104f06 <alltraps>

80105691 <vector96>:
.globl vector96
vector96:
  pushl $0
80105691:	6a 00                	push   $0x0
  pushl $96
80105693:	6a 60                	push   $0x60
  jmp alltraps
80105695:	e9 6c f8 ff ff       	jmp    80104f06 <alltraps>

8010569a <vector97>:
.globl vector97
vector97:
  pushl $0
8010569a:	6a 00                	push   $0x0
  pushl $97
8010569c:	6a 61                	push   $0x61
  jmp alltraps
8010569e:	e9 63 f8 ff ff       	jmp    80104f06 <alltraps>

801056a3 <vector98>:
.globl vector98
vector98:
  pushl $0
801056a3:	6a 00                	push   $0x0
  pushl $98
801056a5:	6a 62                	push   $0x62
  jmp alltraps
801056a7:	e9 5a f8 ff ff       	jmp    80104f06 <alltraps>

801056ac <vector99>:
.globl vector99
vector99:
  pushl $0
801056ac:	6a 00                	push   $0x0
  pushl $99
801056ae:	6a 63                	push   $0x63
  jmp alltraps
801056b0:	e9 51 f8 ff ff       	jmp    80104f06 <alltraps>

801056b5 <vector100>:
.globl vector100
vector100:
  pushl $0
801056b5:	6a 00                	push   $0x0
  pushl $100
801056b7:	6a 64                	push   $0x64
  jmp alltraps
801056b9:	e9 48 f8 ff ff       	jmp    80104f06 <alltraps>

801056be <vector101>:
.globl vector101
vector101:
  pushl $0
801056be:	6a 00                	push   $0x0
  pushl $101
801056c0:	6a 65                	push   $0x65
  jmp alltraps
801056c2:	e9 3f f8 ff ff       	jmp    80104f06 <alltraps>

801056c7 <vector102>:
.globl vector102
vector102:
  pushl $0
801056c7:	6a 00                	push   $0x0
  pushl $102
801056c9:	6a 66                	push   $0x66
  jmp alltraps
801056cb:	e9 36 f8 ff ff       	jmp    80104f06 <alltraps>

801056d0 <vector103>:
.globl vector103
vector103:
  pushl $0
801056d0:	6a 00                	push   $0x0
  pushl $103
801056d2:	6a 67                	push   $0x67
  jmp alltraps
801056d4:	e9 2d f8 ff ff       	jmp    80104f06 <alltraps>

801056d9 <vector104>:
.globl vector104
vector104:
  pushl $0
801056d9:	6a 00                	push   $0x0
  pushl $104
801056db:	6a 68                	push   $0x68
  jmp alltraps
801056dd:	e9 24 f8 ff ff       	jmp    80104f06 <alltraps>

801056e2 <vector105>:
.globl vector105
vector105:
  pushl $0
801056e2:	6a 00                	push   $0x0
  pushl $105
801056e4:	6a 69                	push   $0x69
  jmp alltraps
801056e6:	e9 1b f8 ff ff       	jmp    80104f06 <alltraps>

801056eb <vector106>:
.globl vector106
vector106:
  pushl $0
801056eb:	6a 00                	push   $0x0
  pushl $106
801056ed:	6a 6a                	push   $0x6a
  jmp alltraps
801056ef:	e9 12 f8 ff ff       	jmp    80104f06 <alltraps>

801056f4 <vector107>:
.globl vector107
vector107:
  pushl $0
801056f4:	6a 00                	push   $0x0
  pushl $107
801056f6:	6a 6b                	push   $0x6b
  jmp alltraps
801056f8:	e9 09 f8 ff ff       	jmp    80104f06 <alltraps>

801056fd <vector108>:
.globl vector108
vector108:
  pushl $0
801056fd:	6a 00                	push   $0x0
  pushl $108
801056ff:	6a 6c                	push   $0x6c
  jmp alltraps
80105701:	e9 00 f8 ff ff       	jmp    80104f06 <alltraps>

80105706 <vector109>:
.globl vector109
vector109:
  pushl $0
80105706:	6a 00                	push   $0x0
  pushl $109
80105708:	6a 6d                	push   $0x6d
  jmp alltraps
8010570a:	e9 f7 f7 ff ff       	jmp    80104f06 <alltraps>

8010570f <vector110>:
.globl vector110
vector110:
  pushl $0
8010570f:	6a 00                	push   $0x0
  pushl $110
80105711:	6a 6e                	push   $0x6e
  jmp alltraps
80105713:	e9 ee f7 ff ff       	jmp    80104f06 <alltraps>

80105718 <vector111>:
.globl vector111
vector111:
  pushl $0
80105718:	6a 00                	push   $0x0
  pushl $111
8010571a:	6a 6f                	push   $0x6f
  jmp alltraps
8010571c:	e9 e5 f7 ff ff       	jmp    80104f06 <alltraps>

80105721 <vector112>:
.globl vector112
vector112:
  pushl $0
80105721:	6a 00                	push   $0x0
  pushl $112
80105723:	6a 70                	push   $0x70
  jmp alltraps
80105725:	e9 dc f7 ff ff       	jmp    80104f06 <alltraps>

8010572a <vector113>:
.globl vector113
vector113:
  pushl $0
8010572a:	6a 00                	push   $0x0
  pushl $113
8010572c:	6a 71                	push   $0x71
  jmp alltraps
8010572e:	e9 d3 f7 ff ff       	jmp    80104f06 <alltraps>

80105733 <vector114>:
.globl vector114
vector114:
  pushl $0
80105733:	6a 00                	push   $0x0
  pushl $114
80105735:	6a 72                	push   $0x72
  jmp alltraps
80105737:	e9 ca f7 ff ff       	jmp    80104f06 <alltraps>

8010573c <vector115>:
.globl vector115
vector115:
  pushl $0
8010573c:	6a 00                	push   $0x0
  pushl $115
8010573e:	6a 73                	push   $0x73
  jmp alltraps
80105740:	e9 c1 f7 ff ff       	jmp    80104f06 <alltraps>

80105745 <vector116>:
.globl vector116
vector116:
  pushl $0
80105745:	6a 00                	push   $0x0
  pushl $116
80105747:	6a 74                	push   $0x74
  jmp alltraps
80105749:	e9 b8 f7 ff ff       	jmp    80104f06 <alltraps>

8010574e <vector117>:
.globl vector117
vector117:
  pushl $0
8010574e:	6a 00                	push   $0x0
  pushl $117
80105750:	6a 75                	push   $0x75
  jmp alltraps
80105752:	e9 af f7 ff ff       	jmp    80104f06 <alltraps>

80105757 <vector118>:
.globl vector118
vector118:
  pushl $0
80105757:	6a 00                	push   $0x0
  pushl $118
80105759:	6a 76                	push   $0x76
  jmp alltraps
8010575b:	e9 a6 f7 ff ff       	jmp    80104f06 <alltraps>

80105760 <vector119>:
.globl vector119
vector119:
  pushl $0
80105760:	6a 00                	push   $0x0
  pushl $119
80105762:	6a 77                	push   $0x77
  jmp alltraps
80105764:	e9 9d f7 ff ff       	jmp    80104f06 <alltraps>

80105769 <vector120>:
.globl vector120
vector120:
  pushl $0
80105769:	6a 00                	push   $0x0
  pushl $120
8010576b:	6a 78                	push   $0x78
  jmp alltraps
8010576d:	e9 94 f7 ff ff       	jmp    80104f06 <alltraps>

80105772 <vector121>:
.globl vector121
vector121:
  pushl $0
80105772:	6a 00                	push   $0x0
  pushl $121
80105774:	6a 79                	push   $0x79
  jmp alltraps
80105776:	e9 8b f7 ff ff       	jmp    80104f06 <alltraps>

8010577b <vector122>:
.globl vector122
vector122:
  pushl $0
8010577b:	6a 00                	push   $0x0
  pushl $122
8010577d:	6a 7a                	push   $0x7a
  jmp alltraps
8010577f:	e9 82 f7 ff ff       	jmp    80104f06 <alltraps>

80105784 <vector123>:
.globl vector123
vector123:
  pushl $0
80105784:	6a 00                	push   $0x0
  pushl $123
80105786:	6a 7b                	push   $0x7b
  jmp alltraps
80105788:	e9 79 f7 ff ff       	jmp    80104f06 <alltraps>

8010578d <vector124>:
.globl vector124
vector124:
  pushl $0
8010578d:	6a 00                	push   $0x0
  pushl $124
8010578f:	6a 7c                	push   $0x7c
  jmp alltraps
80105791:	e9 70 f7 ff ff       	jmp    80104f06 <alltraps>

80105796 <vector125>:
.globl vector125
vector125:
  pushl $0
80105796:	6a 00                	push   $0x0
  pushl $125
80105798:	6a 7d                	push   $0x7d
  jmp alltraps
8010579a:	e9 67 f7 ff ff       	jmp    80104f06 <alltraps>

8010579f <vector126>:
.globl vector126
vector126:
  pushl $0
8010579f:	6a 00                	push   $0x0
  pushl $126
801057a1:	6a 7e                	push   $0x7e
  jmp alltraps
801057a3:	e9 5e f7 ff ff       	jmp    80104f06 <alltraps>

801057a8 <vector127>:
.globl vector127
vector127:
  pushl $0
801057a8:	6a 00                	push   $0x0
  pushl $127
801057aa:	6a 7f                	push   $0x7f
  jmp alltraps
801057ac:	e9 55 f7 ff ff       	jmp    80104f06 <alltraps>

801057b1 <vector128>:
.globl vector128
vector128:
  pushl $0
801057b1:	6a 00                	push   $0x0
  pushl $128
801057b3:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801057b8:	e9 49 f7 ff ff       	jmp    80104f06 <alltraps>

801057bd <vector129>:
.globl vector129
vector129:
  pushl $0
801057bd:	6a 00                	push   $0x0
  pushl $129
801057bf:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801057c4:	e9 3d f7 ff ff       	jmp    80104f06 <alltraps>

801057c9 <vector130>:
.globl vector130
vector130:
  pushl $0
801057c9:	6a 00                	push   $0x0
  pushl $130
801057cb:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801057d0:	e9 31 f7 ff ff       	jmp    80104f06 <alltraps>

801057d5 <vector131>:
.globl vector131
vector131:
  pushl $0
801057d5:	6a 00                	push   $0x0
  pushl $131
801057d7:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801057dc:	e9 25 f7 ff ff       	jmp    80104f06 <alltraps>

801057e1 <vector132>:
.globl vector132
vector132:
  pushl $0
801057e1:	6a 00                	push   $0x0
  pushl $132
801057e3:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801057e8:	e9 19 f7 ff ff       	jmp    80104f06 <alltraps>

801057ed <vector133>:
.globl vector133
vector133:
  pushl $0
801057ed:	6a 00                	push   $0x0
  pushl $133
801057ef:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801057f4:	e9 0d f7 ff ff       	jmp    80104f06 <alltraps>

801057f9 <vector134>:
.globl vector134
vector134:
  pushl $0
801057f9:	6a 00                	push   $0x0
  pushl $134
801057fb:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80105800:	e9 01 f7 ff ff       	jmp    80104f06 <alltraps>

80105805 <vector135>:
.globl vector135
vector135:
  pushl $0
80105805:	6a 00                	push   $0x0
  pushl $135
80105807:	68 87 00 00 00       	push   $0x87
  jmp alltraps
8010580c:	e9 f5 f6 ff ff       	jmp    80104f06 <alltraps>

80105811 <vector136>:
.globl vector136
vector136:
  pushl $0
80105811:	6a 00                	push   $0x0
  pushl $136
80105813:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105818:	e9 e9 f6 ff ff       	jmp    80104f06 <alltraps>

8010581d <vector137>:
.globl vector137
vector137:
  pushl $0
8010581d:	6a 00                	push   $0x0
  pushl $137
8010581f:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80105824:	e9 dd f6 ff ff       	jmp    80104f06 <alltraps>

80105829 <vector138>:
.globl vector138
vector138:
  pushl $0
80105829:	6a 00                	push   $0x0
  pushl $138
8010582b:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105830:	e9 d1 f6 ff ff       	jmp    80104f06 <alltraps>

80105835 <vector139>:
.globl vector139
vector139:
  pushl $0
80105835:	6a 00                	push   $0x0
  pushl $139
80105837:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
8010583c:	e9 c5 f6 ff ff       	jmp    80104f06 <alltraps>

80105841 <vector140>:
.globl vector140
vector140:
  pushl $0
80105841:	6a 00                	push   $0x0
  pushl $140
80105843:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105848:	e9 b9 f6 ff ff       	jmp    80104f06 <alltraps>

8010584d <vector141>:
.globl vector141
vector141:
  pushl $0
8010584d:	6a 00                	push   $0x0
  pushl $141
8010584f:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105854:	e9 ad f6 ff ff       	jmp    80104f06 <alltraps>

80105859 <vector142>:
.globl vector142
vector142:
  pushl $0
80105859:	6a 00                	push   $0x0
  pushl $142
8010585b:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105860:	e9 a1 f6 ff ff       	jmp    80104f06 <alltraps>

80105865 <vector143>:
.globl vector143
vector143:
  pushl $0
80105865:	6a 00                	push   $0x0
  pushl $143
80105867:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
8010586c:	e9 95 f6 ff ff       	jmp    80104f06 <alltraps>

80105871 <vector144>:
.globl vector144
vector144:
  pushl $0
80105871:	6a 00                	push   $0x0
  pushl $144
80105873:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105878:	e9 89 f6 ff ff       	jmp    80104f06 <alltraps>

8010587d <vector145>:
.globl vector145
vector145:
  pushl $0
8010587d:	6a 00                	push   $0x0
  pushl $145
8010587f:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105884:	e9 7d f6 ff ff       	jmp    80104f06 <alltraps>

80105889 <vector146>:
.globl vector146
vector146:
  pushl $0
80105889:	6a 00                	push   $0x0
  pushl $146
8010588b:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105890:	e9 71 f6 ff ff       	jmp    80104f06 <alltraps>

80105895 <vector147>:
.globl vector147
vector147:
  pushl $0
80105895:	6a 00                	push   $0x0
  pushl $147
80105897:	68 93 00 00 00       	push   $0x93
  jmp alltraps
8010589c:	e9 65 f6 ff ff       	jmp    80104f06 <alltraps>

801058a1 <vector148>:
.globl vector148
vector148:
  pushl $0
801058a1:	6a 00                	push   $0x0
  pushl $148
801058a3:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801058a8:	e9 59 f6 ff ff       	jmp    80104f06 <alltraps>

801058ad <vector149>:
.globl vector149
vector149:
  pushl $0
801058ad:	6a 00                	push   $0x0
  pushl $149
801058af:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801058b4:	e9 4d f6 ff ff       	jmp    80104f06 <alltraps>

801058b9 <vector150>:
.globl vector150
vector150:
  pushl $0
801058b9:	6a 00                	push   $0x0
  pushl $150
801058bb:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801058c0:	e9 41 f6 ff ff       	jmp    80104f06 <alltraps>

801058c5 <vector151>:
.globl vector151
vector151:
  pushl $0
801058c5:	6a 00                	push   $0x0
  pushl $151
801058c7:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801058cc:	e9 35 f6 ff ff       	jmp    80104f06 <alltraps>

801058d1 <vector152>:
.globl vector152
vector152:
  pushl $0
801058d1:	6a 00                	push   $0x0
  pushl $152
801058d3:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801058d8:	e9 29 f6 ff ff       	jmp    80104f06 <alltraps>

801058dd <vector153>:
.globl vector153
vector153:
  pushl $0
801058dd:	6a 00                	push   $0x0
  pushl $153
801058df:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801058e4:	e9 1d f6 ff ff       	jmp    80104f06 <alltraps>

801058e9 <vector154>:
.globl vector154
vector154:
  pushl $0
801058e9:	6a 00                	push   $0x0
  pushl $154
801058eb:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801058f0:	e9 11 f6 ff ff       	jmp    80104f06 <alltraps>

801058f5 <vector155>:
.globl vector155
vector155:
  pushl $0
801058f5:	6a 00                	push   $0x0
  pushl $155
801058f7:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801058fc:	e9 05 f6 ff ff       	jmp    80104f06 <alltraps>

80105901 <vector156>:
.globl vector156
vector156:
  pushl $0
80105901:	6a 00                	push   $0x0
  pushl $156
80105903:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105908:	e9 f9 f5 ff ff       	jmp    80104f06 <alltraps>

8010590d <vector157>:
.globl vector157
vector157:
  pushl $0
8010590d:	6a 00                	push   $0x0
  pushl $157
8010590f:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105914:	e9 ed f5 ff ff       	jmp    80104f06 <alltraps>

80105919 <vector158>:
.globl vector158
vector158:
  pushl $0
80105919:	6a 00                	push   $0x0
  pushl $158
8010591b:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105920:	e9 e1 f5 ff ff       	jmp    80104f06 <alltraps>

80105925 <vector159>:
.globl vector159
vector159:
  pushl $0
80105925:	6a 00                	push   $0x0
  pushl $159
80105927:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
8010592c:	e9 d5 f5 ff ff       	jmp    80104f06 <alltraps>

80105931 <vector160>:
.globl vector160
vector160:
  pushl $0
80105931:	6a 00                	push   $0x0
  pushl $160
80105933:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105938:	e9 c9 f5 ff ff       	jmp    80104f06 <alltraps>

8010593d <vector161>:
.globl vector161
vector161:
  pushl $0
8010593d:	6a 00                	push   $0x0
  pushl $161
8010593f:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105944:	e9 bd f5 ff ff       	jmp    80104f06 <alltraps>

80105949 <vector162>:
.globl vector162
vector162:
  pushl $0
80105949:	6a 00                	push   $0x0
  pushl $162
8010594b:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105950:	e9 b1 f5 ff ff       	jmp    80104f06 <alltraps>

80105955 <vector163>:
.globl vector163
vector163:
  pushl $0
80105955:	6a 00                	push   $0x0
  pushl $163
80105957:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
8010595c:	e9 a5 f5 ff ff       	jmp    80104f06 <alltraps>

80105961 <vector164>:
.globl vector164
vector164:
  pushl $0
80105961:	6a 00                	push   $0x0
  pushl $164
80105963:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105968:	e9 99 f5 ff ff       	jmp    80104f06 <alltraps>

8010596d <vector165>:
.globl vector165
vector165:
  pushl $0
8010596d:	6a 00                	push   $0x0
  pushl $165
8010596f:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105974:	e9 8d f5 ff ff       	jmp    80104f06 <alltraps>

80105979 <vector166>:
.globl vector166
vector166:
  pushl $0
80105979:	6a 00                	push   $0x0
  pushl $166
8010597b:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105980:	e9 81 f5 ff ff       	jmp    80104f06 <alltraps>

80105985 <vector167>:
.globl vector167
vector167:
  pushl $0
80105985:	6a 00                	push   $0x0
  pushl $167
80105987:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
8010598c:	e9 75 f5 ff ff       	jmp    80104f06 <alltraps>

80105991 <vector168>:
.globl vector168
vector168:
  pushl $0
80105991:	6a 00                	push   $0x0
  pushl $168
80105993:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105998:	e9 69 f5 ff ff       	jmp    80104f06 <alltraps>

8010599d <vector169>:
.globl vector169
vector169:
  pushl $0
8010599d:	6a 00                	push   $0x0
  pushl $169
8010599f:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801059a4:	e9 5d f5 ff ff       	jmp    80104f06 <alltraps>

801059a9 <vector170>:
.globl vector170
vector170:
  pushl $0
801059a9:	6a 00                	push   $0x0
  pushl $170
801059ab:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801059b0:	e9 51 f5 ff ff       	jmp    80104f06 <alltraps>

801059b5 <vector171>:
.globl vector171
vector171:
  pushl $0
801059b5:	6a 00                	push   $0x0
  pushl $171
801059b7:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801059bc:	e9 45 f5 ff ff       	jmp    80104f06 <alltraps>

801059c1 <vector172>:
.globl vector172
vector172:
  pushl $0
801059c1:	6a 00                	push   $0x0
  pushl $172
801059c3:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801059c8:	e9 39 f5 ff ff       	jmp    80104f06 <alltraps>

801059cd <vector173>:
.globl vector173
vector173:
  pushl $0
801059cd:	6a 00                	push   $0x0
  pushl $173
801059cf:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801059d4:	e9 2d f5 ff ff       	jmp    80104f06 <alltraps>

801059d9 <vector174>:
.globl vector174
vector174:
  pushl $0
801059d9:	6a 00                	push   $0x0
  pushl $174
801059db:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801059e0:	e9 21 f5 ff ff       	jmp    80104f06 <alltraps>

801059e5 <vector175>:
.globl vector175
vector175:
  pushl $0
801059e5:	6a 00                	push   $0x0
  pushl $175
801059e7:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801059ec:	e9 15 f5 ff ff       	jmp    80104f06 <alltraps>

801059f1 <vector176>:
.globl vector176
vector176:
  pushl $0
801059f1:	6a 00                	push   $0x0
  pushl $176
801059f3:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801059f8:	e9 09 f5 ff ff       	jmp    80104f06 <alltraps>

801059fd <vector177>:
.globl vector177
vector177:
  pushl $0
801059fd:	6a 00                	push   $0x0
  pushl $177
801059ff:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105a04:	e9 fd f4 ff ff       	jmp    80104f06 <alltraps>

80105a09 <vector178>:
.globl vector178
vector178:
  pushl $0
80105a09:	6a 00                	push   $0x0
  pushl $178
80105a0b:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105a10:	e9 f1 f4 ff ff       	jmp    80104f06 <alltraps>

80105a15 <vector179>:
.globl vector179
vector179:
  pushl $0
80105a15:	6a 00                	push   $0x0
  pushl $179
80105a17:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105a1c:	e9 e5 f4 ff ff       	jmp    80104f06 <alltraps>

80105a21 <vector180>:
.globl vector180
vector180:
  pushl $0
80105a21:	6a 00                	push   $0x0
  pushl $180
80105a23:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105a28:	e9 d9 f4 ff ff       	jmp    80104f06 <alltraps>

80105a2d <vector181>:
.globl vector181
vector181:
  pushl $0
80105a2d:	6a 00                	push   $0x0
  pushl $181
80105a2f:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105a34:	e9 cd f4 ff ff       	jmp    80104f06 <alltraps>

80105a39 <vector182>:
.globl vector182
vector182:
  pushl $0
80105a39:	6a 00                	push   $0x0
  pushl $182
80105a3b:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105a40:	e9 c1 f4 ff ff       	jmp    80104f06 <alltraps>

80105a45 <vector183>:
.globl vector183
vector183:
  pushl $0
80105a45:	6a 00                	push   $0x0
  pushl $183
80105a47:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105a4c:	e9 b5 f4 ff ff       	jmp    80104f06 <alltraps>

80105a51 <vector184>:
.globl vector184
vector184:
  pushl $0
80105a51:	6a 00                	push   $0x0
  pushl $184
80105a53:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105a58:	e9 a9 f4 ff ff       	jmp    80104f06 <alltraps>

80105a5d <vector185>:
.globl vector185
vector185:
  pushl $0
80105a5d:	6a 00                	push   $0x0
  pushl $185
80105a5f:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105a64:	e9 9d f4 ff ff       	jmp    80104f06 <alltraps>

80105a69 <vector186>:
.globl vector186
vector186:
  pushl $0
80105a69:	6a 00                	push   $0x0
  pushl $186
80105a6b:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105a70:	e9 91 f4 ff ff       	jmp    80104f06 <alltraps>

80105a75 <vector187>:
.globl vector187
vector187:
  pushl $0
80105a75:	6a 00                	push   $0x0
  pushl $187
80105a77:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105a7c:	e9 85 f4 ff ff       	jmp    80104f06 <alltraps>

80105a81 <vector188>:
.globl vector188
vector188:
  pushl $0
80105a81:	6a 00                	push   $0x0
  pushl $188
80105a83:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105a88:	e9 79 f4 ff ff       	jmp    80104f06 <alltraps>

80105a8d <vector189>:
.globl vector189
vector189:
  pushl $0
80105a8d:	6a 00                	push   $0x0
  pushl $189
80105a8f:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105a94:	e9 6d f4 ff ff       	jmp    80104f06 <alltraps>

80105a99 <vector190>:
.globl vector190
vector190:
  pushl $0
80105a99:	6a 00                	push   $0x0
  pushl $190
80105a9b:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105aa0:	e9 61 f4 ff ff       	jmp    80104f06 <alltraps>

80105aa5 <vector191>:
.globl vector191
vector191:
  pushl $0
80105aa5:	6a 00                	push   $0x0
  pushl $191
80105aa7:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105aac:	e9 55 f4 ff ff       	jmp    80104f06 <alltraps>

80105ab1 <vector192>:
.globl vector192
vector192:
  pushl $0
80105ab1:	6a 00                	push   $0x0
  pushl $192
80105ab3:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105ab8:	e9 49 f4 ff ff       	jmp    80104f06 <alltraps>

80105abd <vector193>:
.globl vector193
vector193:
  pushl $0
80105abd:	6a 00                	push   $0x0
  pushl $193
80105abf:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105ac4:	e9 3d f4 ff ff       	jmp    80104f06 <alltraps>

80105ac9 <vector194>:
.globl vector194
vector194:
  pushl $0
80105ac9:	6a 00                	push   $0x0
  pushl $194
80105acb:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105ad0:	e9 31 f4 ff ff       	jmp    80104f06 <alltraps>

80105ad5 <vector195>:
.globl vector195
vector195:
  pushl $0
80105ad5:	6a 00                	push   $0x0
  pushl $195
80105ad7:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105adc:	e9 25 f4 ff ff       	jmp    80104f06 <alltraps>

80105ae1 <vector196>:
.globl vector196
vector196:
  pushl $0
80105ae1:	6a 00                	push   $0x0
  pushl $196
80105ae3:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105ae8:	e9 19 f4 ff ff       	jmp    80104f06 <alltraps>

80105aed <vector197>:
.globl vector197
vector197:
  pushl $0
80105aed:	6a 00                	push   $0x0
  pushl $197
80105aef:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105af4:	e9 0d f4 ff ff       	jmp    80104f06 <alltraps>

80105af9 <vector198>:
.globl vector198
vector198:
  pushl $0
80105af9:	6a 00                	push   $0x0
  pushl $198
80105afb:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105b00:	e9 01 f4 ff ff       	jmp    80104f06 <alltraps>

80105b05 <vector199>:
.globl vector199
vector199:
  pushl $0
80105b05:	6a 00                	push   $0x0
  pushl $199
80105b07:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105b0c:	e9 f5 f3 ff ff       	jmp    80104f06 <alltraps>

80105b11 <vector200>:
.globl vector200
vector200:
  pushl $0
80105b11:	6a 00                	push   $0x0
  pushl $200
80105b13:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105b18:	e9 e9 f3 ff ff       	jmp    80104f06 <alltraps>

80105b1d <vector201>:
.globl vector201
vector201:
  pushl $0
80105b1d:	6a 00                	push   $0x0
  pushl $201
80105b1f:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105b24:	e9 dd f3 ff ff       	jmp    80104f06 <alltraps>

80105b29 <vector202>:
.globl vector202
vector202:
  pushl $0
80105b29:	6a 00                	push   $0x0
  pushl $202
80105b2b:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105b30:	e9 d1 f3 ff ff       	jmp    80104f06 <alltraps>

80105b35 <vector203>:
.globl vector203
vector203:
  pushl $0
80105b35:	6a 00                	push   $0x0
  pushl $203
80105b37:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105b3c:	e9 c5 f3 ff ff       	jmp    80104f06 <alltraps>

80105b41 <vector204>:
.globl vector204
vector204:
  pushl $0
80105b41:	6a 00                	push   $0x0
  pushl $204
80105b43:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105b48:	e9 b9 f3 ff ff       	jmp    80104f06 <alltraps>

80105b4d <vector205>:
.globl vector205
vector205:
  pushl $0
80105b4d:	6a 00                	push   $0x0
  pushl $205
80105b4f:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105b54:	e9 ad f3 ff ff       	jmp    80104f06 <alltraps>

80105b59 <vector206>:
.globl vector206
vector206:
  pushl $0
80105b59:	6a 00                	push   $0x0
  pushl $206
80105b5b:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105b60:	e9 a1 f3 ff ff       	jmp    80104f06 <alltraps>

80105b65 <vector207>:
.globl vector207
vector207:
  pushl $0
80105b65:	6a 00                	push   $0x0
  pushl $207
80105b67:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105b6c:	e9 95 f3 ff ff       	jmp    80104f06 <alltraps>

80105b71 <vector208>:
.globl vector208
vector208:
  pushl $0
80105b71:	6a 00                	push   $0x0
  pushl $208
80105b73:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105b78:	e9 89 f3 ff ff       	jmp    80104f06 <alltraps>

80105b7d <vector209>:
.globl vector209
vector209:
  pushl $0
80105b7d:	6a 00                	push   $0x0
  pushl $209
80105b7f:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105b84:	e9 7d f3 ff ff       	jmp    80104f06 <alltraps>

80105b89 <vector210>:
.globl vector210
vector210:
  pushl $0
80105b89:	6a 00                	push   $0x0
  pushl $210
80105b8b:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105b90:	e9 71 f3 ff ff       	jmp    80104f06 <alltraps>

80105b95 <vector211>:
.globl vector211
vector211:
  pushl $0
80105b95:	6a 00                	push   $0x0
  pushl $211
80105b97:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105b9c:	e9 65 f3 ff ff       	jmp    80104f06 <alltraps>

80105ba1 <vector212>:
.globl vector212
vector212:
  pushl $0
80105ba1:	6a 00                	push   $0x0
  pushl $212
80105ba3:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105ba8:	e9 59 f3 ff ff       	jmp    80104f06 <alltraps>

80105bad <vector213>:
.globl vector213
vector213:
  pushl $0
80105bad:	6a 00                	push   $0x0
  pushl $213
80105baf:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105bb4:	e9 4d f3 ff ff       	jmp    80104f06 <alltraps>

80105bb9 <vector214>:
.globl vector214
vector214:
  pushl $0
80105bb9:	6a 00                	push   $0x0
  pushl $214
80105bbb:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105bc0:	e9 41 f3 ff ff       	jmp    80104f06 <alltraps>

80105bc5 <vector215>:
.globl vector215
vector215:
  pushl $0
80105bc5:	6a 00                	push   $0x0
  pushl $215
80105bc7:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105bcc:	e9 35 f3 ff ff       	jmp    80104f06 <alltraps>

80105bd1 <vector216>:
.globl vector216
vector216:
  pushl $0
80105bd1:	6a 00                	push   $0x0
  pushl $216
80105bd3:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105bd8:	e9 29 f3 ff ff       	jmp    80104f06 <alltraps>

80105bdd <vector217>:
.globl vector217
vector217:
  pushl $0
80105bdd:	6a 00                	push   $0x0
  pushl $217
80105bdf:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105be4:	e9 1d f3 ff ff       	jmp    80104f06 <alltraps>

80105be9 <vector218>:
.globl vector218
vector218:
  pushl $0
80105be9:	6a 00                	push   $0x0
  pushl $218
80105beb:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105bf0:	e9 11 f3 ff ff       	jmp    80104f06 <alltraps>

80105bf5 <vector219>:
.globl vector219
vector219:
  pushl $0
80105bf5:	6a 00                	push   $0x0
  pushl $219
80105bf7:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105bfc:	e9 05 f3 ff ff       	jmp    80104f06 <alltraps>

80105c01 <vector220>:
.globl vector220
vector220:
  pushl $0
80105c01:	6a 00                	push   $0x0
  pushl $220
80105c03:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105c08:	e9 f9 f2 ff ff       	jmp    80104f06 <alltraps>

80105c0d <vector221>:
.globl vector221
vector221:
  pushl $0
80105c0d:	6a 00                	push   $0x0
  pushl $221
80105c0f:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105c14:	e9 ed f2 ff ff       	jmp    80104f06 <alltraps>

80105c19 <vector222>:
.globl vector222
vector222:
  pushl $0
80105c19:	6a 00                	push   $0x0
  pushl $222
80105c1b:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105c20:	e9 e1 f2 ff ff       	jmp    80104f06 <alltraps>

80105c25 <vector223>:
.globl vector223
vector223:
  pushl $0
80105c25:	6a 00                	push   $0x0
  pushl $223
80105c27:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105c2c:	e9 d5 f2 ff ff       	jmp    80104f06 <alltraps>

80105c31 <vector224>:
.globl vector224
vector224:
  pushl $0
80105c31:	6a 00                	push   $0x0
  pushl $224
80105c33:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105c38:	e9 c9 f2 ff ff       	jmp    80104f06 <alltraps>

80105c3d <vector225>:
.globl vector225
vector225:
  pushl $0
80105c3d:	6a 00                	push   $0x0
  pushl $225
80105c3f:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105c44:	e9 bd f2 ff ff       	jmp    80104f06 <alltraps>

80105c49 <vector226>:
.globl vector226
vector226:
  pushl $0
80105c49:	6a 00                	push   $0x0
  pushl $226
80105c4b:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105c50:	e9 b1 f2 ff ff       	jmp    80104f06 <alltraps>

80105c55 <vector227>:
.globl vector227
vector227:
  pushl $0
80105c55:	6a 00                	push   $0x0
  pushl $227
80105c57:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105c5c:	e9 a5 f2 ff ff       	jmp    80104f06 <alltraps>

80105c61 <vector228>:
.globl vector228
vector228:
  pushl $0
80105c61:	6a 00                	push   $0x0
  pushl $228
80105c63:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105c68:	e9 99 f2 ff ff       	jmp    80104f06 <alltraps>

80105c6d <vector229>:
.globl vector229
vector229:
  pushl $0
80105c6d:	6a 00                	push   $0x0
  pushl $229
80105c6f:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105c74:	e9 8d f2 ff ff       	jmp    80104f06 <alltraps>

80105c79 <vector230>:
.globl vector230
vector230:
  pushl $0
80105c79:	6a 00                	push   $0x0
  pushl $230
80105c7b:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105c80:	e9 81 f2 ff ff       	jmp    80104f06 <alltraps>

80105c85 <vector231>:
.globl vector231
vector231:
  pushl $0
80105c85:	6a 00                	push   $0x0
  pushl $231
80105c87:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105c8c:	e9 75 f2 ff ff       	jmp    80104f06 <alltraps>

80105c91 <vector232>:
.globl vector232
vector232:
  pushl $0
80105c91:	6a 00                	push   $0x0
  pushl $232
80105c93:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105c98:	e9 69 f2 ff ff       	jmp    80104f06 <alltraps>

80105c9d <vector233>:
.globl vector233
vector233:
  pushl $0
80105c9d:	6a 00                	push   $0x0
  pushl $233
80105c9f:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105ca4:	e9 5d f2 ff ff       	jmp    80104f06 <alltraps>

80105ca9 <vector234>:
.globl vector234
vector234:
  pushl $0
80105ca9:	6a 00                	push   $0x0
  pushl $234
80105cab:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105cb0:	e9 51 f2 ff ff       	jmp    80104f06 <alltraps>

80105cb5 <vector235>:
.globl vector235
vector235:
  pushl $0
80105cb5:	6a 00                	push   $0x0
  pushl $235
80105cb7:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105cbc:	e9 45 f2 ff ff       	jmp    80104f06 <alltraps>

80105cc1 <vector236>:
.globl vector236
vector236:
  pushl $0
80105cc1:	6a 00                	push   $0x0
  pushl $236
80105cc3:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105cc8:	e9 39 f2 ff ff       	jmp    80104f06 <alltraps>

80105ccd <vector237>:
.globl vector237
vector237:
  pushl $0
80105ccd:	6a 00                	push   $0x0
  pushl $237
80105ccf:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105cd4:	e9 2d f2 ff ff       	jmp    80104f06 <alltraps>

80105cd9 <vector238>:
.globl vector238
vector238:
  pushl $0
80105cd9:	6a 00                	push   $0x0
  pushl $238
80105cdb:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105ce0:	e9 21 f2 ff ff       	jmp    80104f06 <alltraps>

80105ce5 <vector239>:
.globl vector239
vector239:
  pushl $0
80105ce5:	6a 00                	push   $0x0
  pushl $239
80105ce7:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105cec:	e9 15 f2 ff ff       	jmp    80104f06 <alltraps>

80105cf1 <vector240>:
.globl vector240
vector240:
  pushl $0
80105cf1:	6a 00                	push   $0x0
  pushl $240
80105cf3:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105cf8:	e9 09 f2 ff ff       	jmp    80104f06 <alltraps>

80105cfd <vector241>:
.globl vector241
vector241:
  pushl $0
80105cfd:	6a 00                	push   $0x0
  pushl $241
80105cff:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105d04:	e9 fd f1 ff ff       	jmp    80104f06 <alltraps>

80105d09 <vector242>:
.globl vector242
vector242:
  pushl $0
80105d09:	6a 00                	push   $0x0
  pushl $242
80105d0b:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105d10:	e9 f1 f1 ff ff       	jmp    80104f06 <alltraps>

80105d15 <vector243>:
.globl vector243
vector243:
  pushl $0
80105d15:	6a 00                	push   $0x0
  pushl $243
80105d17:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105d1c:	e9 e5 f1 ff ff       	jmp    80104f06 <alltraps>

80105d21 <vector244>:
.globl vector244
vector244:
  pushl $0
80105d21:	6a 00                	push   $0x0
  pushl $244
80105d23:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105d28:	e9 d9 f1 ff ff       	jmp    80104f06 <alltraps>

80105d2d <vector245>:
.globl vector245
vector245:
  pushl $0
80105d2d:	6a 00                	push   $0x0
  pushl $245
80105d2f:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105d34:	e9 cd f1 ff ff       	jmp    80104f06 <alltraps>

80105d39 <vector246>:
.globl vector246
vector246:
  pushl $0
80105d39:	6a 00                	push   $0x0
  pushl $246
80105d3b:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105d40:	e9 c1 f1 ff ff       	jmp    80104f06 <alltraps>

80105d45 <vector247>:
.globl vector247
vector247:
  pushl $0
80105d45:	6a 00                	push   $0x0
  pushl $247
80105d47:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105d4c:	e9 b5 f1 ff ff       	jmp    80104f06 <alltraps>

80105d51 <vector248>:
.globl vector248
vector248:
  pushl $0
80105d51:	6a 00                	push   $0x0
  pushl $248
80105d53:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105d58:	e9 a9 f1 ff ff       	jmp    80104f06 <alltraps>

80105d5d <vector249>:
.globl vector249
vector249:
  pushl $0
80105d5d:	6a 00                	push   $0x0
  pushl $249
80105d5f:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105d64:	e9 9d f1 ff ff       	jmp    80104f06 <alltraps>

80105d69 <vector250>:
.globl vector250
vector250:
  pushl $0
80105d69:	6a 00                	push   $0x0
  pushl $250
80105d6b:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105d70:	e9 91 f1 ff ff       	jmp    80104f06 <alltraps>

80105d75 <vector251>:
.globl vector251
vector251:
  pushl $0
80105d75:	6a 00                	push   $0x0
  pushl $251
80105d77:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105d7c:	e9 85 f1 ff ff       	jmp    80104f06 <alltraps>

80105d81 <vector252>:
.globl vector252
vector252:
  pushl $0
80105d81:	6a 00                	push   $0x0
  pushl $252
80105d83:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105d88:	e9 79 f1 ff ff       	jmp    80104f06 <alltraps>

80105d8d <vector253>:
.globl vector253
vector253:
  pushl $0
80105d8d:	6a 00                	push   $0x0
  pushl $253
80105d8f:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105d94:	e9 6d f1 ff ff       	jmp    80104f06 <alltraps>

80105d99 <vector254>:
.globl vector254
vector254:
  pushl $0
80105d99:	6a 00                	push   $0x0
  pushl $254
80105d9b:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105da0:	e9 61 f1 ff ff       	jmp    80104f06 <alltraps>

80105da5 <vector255>:
.globl vector255
vector255:
  pushl $0
80105da5:	6a 00                	push   $0x0
  pushl $255
80105da7:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105dac:	e9 55 f1 ff ff       	jmp    80104f06 <alltraps>

80105db1 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105db1:	55                   	push   %ebp
80105db2:	89 e5                	mov    %esp,%ebp
80105db4:	57                   	push   %edi
80105db5:	56                   	push   %esi
80105db6:	53                   	push   %ebx
80105db7:	83 ec 0c             	sub    $0xc,%esp
80105dba:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105dbc:	c1 ea 16             	shr    $0x16,%edx
80105dbf:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105dc2:	8b 1f                	mov    (%edi),%ebx
80105dc4:	f6 c3 01             	test   $0x1,%bl
80105dc7:	74 22                	je     80105deb <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105dc9:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105dcf:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105dd5:	c1 ee 0c             	shr    $0xc,%esi
80105dd8:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105dde:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105de1:	89 d8                	mov    %ebx,%eax
80105de3:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105de6:	5b                   	pop    %ebx
80105de7:	5e                   	pop    %esi
80105de8:	5f                   	pop    %edi
80105de9:	5d                   	pop    %ebp
80105dea:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc2()) == 0)
80105deb:	85 c9                	test   %ecx,%ecx
80105ded:	74 2b                	je     80105e1a <walkpgdir+0x69>
80105def:	e8 fc c3 ff ff       	call   801021f0 <kalloc2>
80105df4:	89 c3                	mov    %eax,%ebx
80105df6:	85 c0                	test   %eax,%eax
80105df8:	74 e7                	je     80105de1 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105dfa:	83 ec 04             	sub    $0x4,%esp
80105dfd:	68 00 10 00 00       	push   $0x1000
80105e02:	6a 00                	push   $0x0
80105e04:	50                   	push   %eax
80105e05:	e8 fe df ff ff       	call   80103e08 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105e0a:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105e10:	83 c8 07             	or     $0x7,%eax
80105e13:	89 07                	mov    %eax,(%edi)
80105e15:	83 c4 10             	add    $0x10,%esp
80105e18:	eb bb                	jmp    80105dd5 <walkpgdir+0x24>
      return 0;
80105e1a:	bb 00 00 00 00       	mov    $0x0,%ebx
80105e1f:	eb c0                	jmp    80105de1 <walkpgdir+0x30>

80105e21 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105e21:	55                   	push   %ebp
80105e22:	89 e5                	mov    %esp,%ebp
80105e24:	57                   	push   %edi
80105e25:	56                   	push   %esi
80105e26:	53                   	push   %ebx
80105e27:	83 ec 1c             	sub    $0x1c,%esp
80105e2a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105e2d:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80105e30:	89 d3                	mov    %edx,%ebx
80105e32:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105e38:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105e3c:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105e42:	b9 01 00 00 00       	mov    $0x1,%ecx
80105e47:	89 da                	mov    %ebx,%edx
80105e49:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105e4c:	e8 60 ff ff ff       	call   80105db1 <walkpgdir>
80105e51:	85 c0                	test   %eax,%eax
80105e53:	74 2e                	je     80105e83 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105e55:	f6 00 01             	testb  $0x1,(%eax)
80105e58:	75 1c                	jne    80105e76 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105e5a:	89 f2                	mov    %esi,%edx
80105e5c:	0b 55 0c             	or     0xc(%ebp),%edx
80105e5f:	83 ca 01             	or     $0x1,%edx
80105e62:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105e64:	39 fb                	cmp    %edi,%ebx
80105e66:	74 28                	je     80105e90 <mappages+0x6f>
      break;
    a += PGSIZE;
80105e68:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105e6e:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105e74:	eb cc                	jmp    80105e42 <mappages+0x21>
      panic("remap");
80105e76:	83 ec 0c             	sub    $0xc,%esp
80105e79:	68 2c 6f 10 80       	push   $0x80106f2c
80105e7e:	e8 c5 a4 ff ff       	call   80100348 <panic>
      return -1;
80105e83:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105e88:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105e8b:	5b                   	pop    %ebx
80105e8c:	5e                   	pop    %esi
80105e8d:	5f                   	pop    %edi
80105e8e:	5d                   	pop    %ebp
80105e8f:	c3                   	ret    
  return 0;
80105e90:	b8 00 00 00 00       	mov    $0x0,%eax
80105e95:	eb f1                	jmp    80105e88 <mappages+0x67>

80105e97 <seginit>:
{
80105e97:	55                   	push   %ebp
80105e98:	89 e5                	mov    %esp,%ebp
80105e9a:	53                   	push   %ebx
80105e9b:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105e9e:	e8 93 d4 ff ff       	call   80103336 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105ea3:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105ea9:	66 c7 80 18 28 12 80 	movw   $0xffff,-0x7fedd7e8(%eax)
80105eb0:	ff ff 
80105eb2:	66 c7 80 1a 28 12 80 	movw   $0x0,-0x7fedd7e6(%eax)
80105eb9:	00 00 
80105ebb:	c6 80 1c 28 12 80 00 	movb   $0x0,-0x7fedd7e4(%eax)
80105ec2:	0f b6 88 1d 28 12 80 	movzbl -0x7fedd7e3(%eax),%ecx
80105ec9:	83 e1 f0             	and    $0xfffffff0,%ecx
80105ecc:	83 c9 1a             	or     $0x1a,%ecx
80105ecf:	83 e1 9f             	and    $0xffffff9f,%ecx
80105ed2:	83 c9 80             	or     $0xffffff80,%ecx
80105ed5:	88 88 1d 28 12 80    	mov    %cl,-0x7fedd7e3(%eax)
80105edb:	0f b6 88 1e 28 12 80 	movzbl -0x7fedd7e2(%eax),%ecx
80105ee2:	83 c9 0f             	or     $0xf,%ecx
80105ee5:	83 e1 cf             	and    $0xffffffcf,%ecx
80105ee8:	83 c9 c0             	or     $0xffffffc0,%ecx
80105eeb:	88 88 1e 28 12 80    	mov    %cl,-0x7fedd7e2(%eax)
80105ef1:	c6 80 1f 28 12 80 00 	movb   $0x0,-0x7fedd7e1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105ef8:	66 c7 80 20 28 12 80 	movw   $0xffff,-0x7fedd7e0(%eax)
80105eff:	ff ff 
80105f01:	66 c7 80 22 28 12 80 	movw   $0x0,-0x7fedd7de(%eax)
80105f08:	00 00 
80105f0a:	c6 80 24 28 12 80 00 	movb   $0x0,-0x7fedd7dc(%eax)
80105f11:	0f b6 88 25 28 12 80 	movzbl -0x7fedd7db(%eax),%ecx
80105f18:	83 e1 f0             	and    $0xfffffff0,%ecx
80105f1b:	83 c9 12             	or     $0x12,%ecx
80105f1e:	83 e1 9f             	and    $0xffffff9f,%ecx
80105f21:	83 c9 80             	or     $0xffffff80,%ecx
80105f24:	88 88 25 28 12 80    	mov    %cl,-0x7fedd7db(%eax)
80105f2a:	0f b6 88 26 28 12 80 	movzbl -0x7fedd7da(%eax),%ecx
80105f31:	83 c9 0f             	or     $0xf,%ecx
80105f34:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f37:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f3a:	88 88 26 28 12 80    	mov    %cl,-0x7fedd7da(%eax)
80105f40:	c6 80 27 28 12 80 00 	movb   $0x0,-0x7fedd7d9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105f47:	66 c7 80 28 28 12 80 	movw   $0xffff,-0x7fedd7d8(%eax)
80105f4e:	ff ff 
80105f50:	66 c7 80 2a 28 12 80 	movw   $0x0,-0x7fedd7d6(%eax)
80105f57:	00 00 
80105f59:	c6 80 2c 28 12 80 00 	movb   $0x0,-0x7fedd7d4(%eax)
80105f60:	c6 80 2d 28 12 80 fa 	movb   $0xfa,-0x7fedd7d3(%eax)
80105f67:	0f b6 88 2e 28 12 80 	movzbl -0x7fedd7d2(%eax),%ecx
80105f6e:	83 c9 0f             	or     $0xf,%ecx
80105f71:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f74:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f77:	88 88 2e 28 12 80    	mov    %cl,-0x7fedd7d2(%eax)
80105f7d:	c6 80 2f 28 12 80 00 	movb   $0x0,-0x7fedd7d1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105f84:	66 c7 80 30 28 12 80 	movw   $0xffff,-0x7fedd7d0(%eax)
80105f8b:	ff ff 
80105f8d:	66 c7 80 32 28 12 80 	movw   $0x0,-0x7fedd7ce(%eax)
80105f94:	00 00 
80105f96:	c6 80 34 28 12 80 00 	movb   $0x0,-0x7fedd7cc(%eax)
80105f9d:	c6 80 35 28 12 80 f2 	movb   $0xf2,-0x7fedd7cb(%eax)
80105fa4:	0f b6 88 36 28 12 80 	movzbl -0x7fedd7ca(%eax),%ecx
80105fab:	83 c9 0f             	or     $0xf,%ecx
80105fae:	83 e1 cf             	and    $0xffffffcf,%ecx
80105fb1:	83 c9 c0             	or     $0xffffffc0,%ecx
80105fb4:	88 88 36 28 12 80    	mov    %cl,-0x7fedd7ca(%eax)
80105fba:	c6 80 37 28 12 80 00 	movb   $0x0,-0x7fedd7c9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105fc1:	05 10 28 12 80       	add    $0x80122810,%eax
  pd[0] = size-1;
80105fc6:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105fcc:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80105fd0:	c1 e8 10             	shr    $0x10,%eax
80105fd3:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80105fd7:	8d 45 f2             	lea    -0xe(%ebp),%eax
80105fda:	0f 01 10             	lgdtl  (%eax)
}
80105fdd:	83 c4 14             	add    $0x14,%esp
80105fe0:	5b                   	pop    %ebx
80105fe1:	5d                   	pop    %ebp
80105fe2:	c3                   	ret    

80105fe3 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80105fe3:	55                   	push   %ebp
80105fe4:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80105fe6:	a1 c4 54 12 80       	mov    0x801254c4,%eax
80105feb:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105ff0:	0f 22 d8             	mov    %eax,%cr3
}
80105ff3:	5d                   	pop    %ebp
80105ff4:	c3                   	ret    

80105ff5 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80105ff5:	55                   	push   %ebp
80105ff6:	89 e5                	mov    %esp,%ebp
80105ff8:	57                   	push   %edi
80105ff9:	56                   	push   %esi
80105ffa:	53                   	push   %ebx
80105ffb:	83 ec 1c             	sub    $0x1c,%esp
80105ffe:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80106001:	85 f6                	test   %esi,%esi
80106003:	0f 84 dd 00 00 00    	je     801060e6 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80106009:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
8010600d:	0f 84 e0 00 00 00    	je     801060f3 <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80106013:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80106017:	0f 84 e3 00 00 00    	je     80106100 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
8010601d:	e8 5d dc ff ff       	call   80103c7f <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80106022:	e8 b3 d2 ff ff       	call   801032da <mycpu>
80106027:	89 c3                	mov    %eax,%ebx
80106029:	e8 ac d2 ff ff       	call   801032da <mycpu>
8010602e:	8d 78 08             	lea    0x8(%eax),%edi
80106031:	e8 a4 d2 ff ff       	call   801032da <mycpu>
80106036:	83 c0 08             	add    $0x8,%eax
80106039:	c1 e8 10             	shr    $0x10,%eax
8010603c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010603f:	e8 96 d2 ff ff       	call   801032da <mycpu>
80106044:	83 c0 08             	add    $0x8,%eax
80106047:	c1 e8 18             	shr    $0x18,%eax
8010604a:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80106051:	67 00 
80106053:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
8010605a:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
8010605e:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80106064:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
8010606b:	83 e2 f0             	and    $0xfffffff0,%edx
8010606e:	83 ca 19             	or     $0x19,%edx
80106071:	83 e2 9f             	and    $0xffffff9f,%edx
80106074:	83 ca 80             	or     $0xffffff80,%edx
80106077:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
8010607d:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80106084:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
8010608a:	e8 4b d2 ff ff       	call   801032da <mycpu>
8010608f:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106096:	83 e2 ef             	and    $0xffffffef,%edx
80106099:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
8010609f:	e8 36 d2 ff ff       	call   801032da <mycpu>
801060a4:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
801060aa:	8b 5e 08             	mov    0x8(%esi),%ebx
801060ad:	e8 28 d2 ff ff       	call   801032da <mycpu>
801060b2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801060b8:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
801060bb:	e8 1a d2 ff ff       	call   801032da <mycpu>
801060c0:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
801060c6:	b8 28 00 00 00       	mov    $0x28,%eax
801060cb:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
801060ce:	8b 46 04             	mov    0x4(%esi),%eax
801060d1:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
801060d6:	0f 22 d8             	mov    %eax,%cr3
  popcli();
801060d9:	e8 de db ff ff       	call   80103cbc <popcli>
}
801060de:	8d 65 f4             	lea    -0xc(%ebp),%esp
801060e1:	5b                   	pop    %ebx
801060e2:	5e                   	pop    %esi
801060e3:	5f                   	pop    %edi
801060e4:	5d                   	pop    %ebp
801060e5:	c3                   	ret    
    panic("switchuvm: no process");
801060e6:	83 ec 0c             	sub    $0xc,%esp
801060e9:	68 32 6f 10 80       	push   $0x80106f32
801060ee:	e8 55 a2 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
801060f3:	83 ec 0c             	sub    $0xc,%esp
801060f6:	68 48 6f 10 80       	push   $0x80106f48
801060fb:	e8 48 a2 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80106100:	83 ec 0c             	sub    $0xc,%esp
80106103:	68 5d 6f 10 80       	push   $0x80106f5d
80106108:	e8 3b a2 ff ff       	call   80100348 <panic>

8010610d <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
8010610d:	55                   	push   %ebp
8010610e:	89 e5                	mov    %esp,%ebp
80106110:	56                   	push   %esi
80106111:	53                   	push   %ebx
80106112:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
80106115:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
8010611b:	77 4c                	ja     80106169 <inituvm+0x5c>
    panic("inituvm: more than a page");
  // ignore this call to kalloc. Mark as UNKNOWN
  mem = kalloc2();
8010611d:	e8 ce c0 ff ff       	call   801021f0 <kalloc2>
80106122:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
80106124:	83 ec 04             	sub    $0x4,%esp
80106127:	68 00 10 00 00       	push   $0x1000
8010612c:	6a 00                	push   $0x0
8010612e:	50                   	push   %eax
8010612f:	e8 d4 dc ff ff       	call   80103e08 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
80106134:	83 c4 08             	add    $0x8,%esp
80106137:	6a 06                	push   $0x6
80106139:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010613f:	50                   	push   %eax
80106140:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106145:	ba 00 00 00 00       	mov    $0x0,%edx
8010614a:	8b 45 08             	mov    0x8(%ebp),%eax
8010614d:	e8 cf fc ff ff       	call   80105e21 <mappages>
  memmove(mem, init, sz);
80106152:	83 c4 0c             	add    $0xc,%esp
80106155:	56                   	push   %esi
80106156:	ff 75 0c             	pushl  0xc(%ebp)
80106159:	53                   	push   %ebx
8010615a:	e8 24 dd ff ff       	call   80103e83 <memmove>
}
8010615f:	83 c4 10             	add    $0x10,%esp
80106162:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106165:	5b                   	pop    %ebx
80106166:	5e                   	pop    %esi
80106167:	5d                   	pop    %ebp
80106168:	c3                   	ret    
    panic("inituvm: more than a page");
80106169:	83 ec 0c             	sub    $0xc,%esp
8010616c:	68 71 6f 10 80       	push   $0x80106f71
80106171:	e8 d2 a1 ff ff       	call   80100348 <panic>

80106176 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80106176:	55                   	push   %ebp
80106177:	89 e5                	mov    %esp,%ebp
80106179:	57                   	push   %edi
8010617a:	56                   	push   %esi
8010617b:	53                   	push   %ebx
8010617c:	83 ec 0c             	sub    $0xc,%esp
8010617f:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80106182:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
80106189:	75 07                	jne    80106192 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
8010618b:	bb 00 00 00 00       	mov    $0x0,%ebx
80106190:	eb 3c                	jmp    801061ce <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
80106192:	83 ec 0c             	sub    $0xc,%esp
80106195:	68 2c 70 10 80       	push   $0x8010702c
8010619a:	e8 a9 a1 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
8010619f:	83 ec 0c             	sub    $0xc,%esp
801061a2:	68 8b 6f 10 80       	push   $0x80106f8b
801061a7:	e8 9c a1 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
801061ac:	05 00 00 00 80       	add    $0x80000000,%eax
801061b1:	56                   	push   %esi
801061b2:	89 da                	mov    %ebx,%edx
801061b4:	03 55 14             	add    0x14(%ebp),%edx
801061b7:	52                   	push   %edx
801061b8:	50                   	push   %eax
801061b9:	ff 75 10             	pushl  0x10(%ebp)
801061bc:	e8 b2 b5 ff ff       	call   80101773 <readi>
801061c1:	83 c4 10             	add    $0x10,%esp
801061c4:	39 f0                	cmp    %esi,%eax
801061c6:	75 47                	jne    8010620f <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
801061c8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801061ce:	39 fb                	cmp    %edi,%ebx
801061d0:	73 30                	jae    80106202 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801061d2:	89 da                	mov    %ebx,%edx
801061d4:	03 55 0c             	add    0xc(%ebp),%edx
801061d7:	b9 00 00 00 00       	mov    $0x0,%ecx
801061dc:	8b 45 08             	mov    0x8(%ebp),%eax
801061df:	e8 cd fb ff ff       	call   80105db1 <walkpgdir>
801061e4:	85 c0                	test   %eax,%eax
801061e6:	74 b7                	je     8010619f <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
801061e8:	8b 00                	mov    (%eax),%eax
801061ea:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
801061ef:	89 fe                	mov    %edi,%esi
801061f1:	29 de                	sub    %ebx,%esi
801061f3:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801061f9:	76 b1                	jbe    801061ac <loaduvm+0x36>
      n = PGSIZE;
801061fb:	be 00 10 00 00       	mov    $0x1000,%esi
80106200:	eb aa                	jmp    801061ac <loaduvm+0x36>
      return -1;
  }
  return 0;
80106202:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106207:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010620a:	5b                   	pop    %ebx
8010620b:	5e                   	pop    %esi
8010620c:	5f                   	pop    %edi
8010620d:	5d                   	pop    %ebp
8010620e:	c3                   	ret    
      return -1;
8010620f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106214:	eb f1                	jmp    80106207 <loaduvm+0x91>

80106216 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80106216:	55                   	push   %ebp
80106217:	89 e5                	mov    %esp,%ebp
80106219:	57                   	push   %edi
8010621a:	56                   	push   %esi
8010621b:	53                   	push   %ebx
8010621c:	83 ec 0c             	sub    $0xc,%esp
8010621f:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80106222:	39 7d 10             	cmp    %edi,0x10(%ebp)
80106225:	73 11                	jae    80106238 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
80106227:	8b 45 10             	mov    0x10(%ebp),%eax
8010622a:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106230:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106236:	eb 19                	jmp    80106251 <deallocuvm+0x3b>
    return oldsz;
80106238:	89 f8                	mov    %edi,%eax
8010623a:	eb 64                	jmp    801062a0 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
8010623c:	c1 eb 16             	shr    $0x16,%ebx
8010623f:	83 c3 01             	add    $0x1,%ebx
80106242:	c1 e3 16             	shl    $0x16,%ebx
80106245:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010624b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106251:	39 fb                	cmp    %edi,%ebx
80106253:	73 48                	jae    8010629d <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
80106255:	b9 00 00 00 00       	mov    $0x0,%ecx
8010625a:	89 da                	mov    %ebx,%edx
8010625c:	8b 45 08             	mov    0x8(%ebp),%eax
8010625f:	e8 4d fb ff ff       	call   80105db1 <walkpgdir>
80106264:	89 c6                	mov    %eax,%esi
    if(!pte)
80106266:	85 c0                	test   %eax,%eax
80106268:	74 d2                	je     8010623c <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
8010626a:	8b 00                	mov    (%eax),%eax
8010626c:	a8 01                	test   $0x1,%al
8010626e:	74 db                	je     8010624b <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
80106270:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106275:	74 19                	je     80106290 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
80106277:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
8010627c:	83 ec 0c             	sub    $0xc,%esp
8010627f:	50                   	push   %eax
80106280:	e8 33 bd ff ff       	call   80101fb8 <kfree>
      *pte = 0;
80106285:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
8010628b:	83 c4 10             	add    $0x10,%esp
8010628e:	eb bb                	jmp    8010624b <deallocuvm+0x35>
        panic("kfree");
80106290:	83 ec 0c             	sub    $0xc,%esp
80106293:	68 c6 68 10 80       	push   $0x801068c6
80106298:	e8 ab a0 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
8010629d:	8b 45 10             	mov    0x10(%ebp),%eax
}
801062a0:	8d 65 f4             	lea    -0xc(%ebp),%esp
801062a3:	5b                   	pop    %ebx
801062a4:	5e                   	pop    %esi
801062a5:	5f                   	pop    %edi
801062a6:	5d                   	pop    %ebp
801062a7:	c3                   	ret    

801062a8 <allocuvm>:
{
801062a8:	55                   	push   %ebp
801062a9:	89 e5                	mov    %esp,%ebp
801062ab:	57                   	push   %edi
801062ac:	56                   	push   %esi
801062ad:	53                   	push   %ebx
801062ae:	83 ec 1c             	sub    $0x1c,%esp
801062b1:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
801062b4:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801062b7:	85 ff                	test   %edi,%edi
801062b9:	0f 88 c1 00 00 00    	js     80106380 <allocuvm+0xd8>
  if(newsz < oldsz)
801062bf:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801062c2:	72 5c                	jb     80106320 <allocuvm+0x78>
  a = PGROUNDUP(oldsz);
801062c4:	8b 45 0c             	mov    0xc(%ebp),%eax
801062c7:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801062cd:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
801062d3:	39 fb                	cmp    %edi,%ebx
801062d5:	0f 83 ac 00 00 00    	jae    80106387 <allocuvm+0xdf>
    mem = kalloc();
801062db:	e8 95 be ff ff       	call   80102175 <kalloc>
801062e0:	89 c6                	mov    %eax,%esi
    if(mem == 0){
801062e2:	85 c0                	test   %eax,%eax
801062e4:	74 42                	je     80106328 <allocuvm+0x80>
    memset(mem, 0, PGSIZE);
801062e6:	83 ec 04             	sub    $0x4,%esp
801062e9:	68 00 10 00 00       	push   $0x1000
801062ee:	6a 00                	push   $0x0
801062f0:	50                   	push   %eax
801062f1:	e8 12 db ff ff       	call   80103e08 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
801062f6:	83 c4 08             	add    $0x8,%esp
801062f9:	6a 06                	push   $0x6
801062fb:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
80106301:	50                   	push   %eax
80106302:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106307:	89 da                	mov    %ebx,%edx
80106309:	8b 45 08             	mov    0x8(%ebp),%eax
8010630c:	e8 10 fb ff ff       	call   80105e21 <mappages>
80106311:	83 c4 10             	add    $0x10,%esp
80106314:	85 c0                	test   %eax,%eax
80106316:	78 38                	js     80106350 <allocuvm+0xa8>
  for(; a < newsz; a += PGSIZE){
80106318:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010631e:	eb b3                	jmp    801062d3 <allocuvm+0x2b>
    return oldsz;
80106320:	8b 45 0c             	mov    0xc(%ebp),%eax
80106323:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106326:	eb 5f                	jmp    80106387 <allocuvm+0xdf>
      cprintf("allocuvm out of memory\n");
80106328:	83 ec 0c             	sub    $0xc,%esp
8010632b:	68 a9 6f 10 80       	push   $0x80106fa9
80106330:	e8 d6 a2 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106335:	83 c4 0c             	add    $0xc,%esp
80106338:	ff 75 0c             	pushl  0xc(%ebp)
8010633b:	57                   	push   %edi
8010633c:	ff 75 08             	pushl  0x8(%ebp)
8010633f:	e8 d2 fe ff ff       	call   80106216 <deallocuvm>
      return 0;
80106344:	83 c4 10             	add    $0x10,%esp
80106347:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010634e:	eb 37                	jmp    80106387 <allocuvm+0xdf>
      cprintf("allocuvm out of memory (2)\n");
80106350:	83 ec 0c             	sub    $0xc,%esp
80106353:	68 c1 6f 10 80       	push   $0x80106fc1
80106358:	e8 ae a2 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010635d:	83 c4 0c             	add    $0xc,%esp
80106360:	ff 75 0c             	pushl  0xc(%ebp)
80106363:	57                   	push   %edi
80106364:	ff 75 08             	pushl  0x8(%ebp)
80106367:	e8 aa fe ff ff       	call   80106216 <deallocuvm>
      kfree(mem);
8010636c:	89 34 24             	mov    %esi,(%esp)
8010636f:	e8 44 bc ff ff       	call   80101fb8 <kfree>
      return 0;
80106374:	83 c4 10             	add    $0x10,%esp
80106377:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010637e:	eb 07                	jmp    80106387 <allocuvm+0xdf>
    return 0;
80106380:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106387:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010638a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010638d:	5b                   	pop    %ebx
8010638e:	5e                   	pop    %esi
8010638f:	5f                   	pop    %edi
80106390:	5d                   	pop    %ebp
80106391:	c3                   	ret    

80106392 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80106392:	55                   	push   %ebp
80106393:	89 e5                	mov    %esp,%ebp
80106395:	56                   	push   %esi
80106396:	53                   	push   %ebx
80106397:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
8010639a:	85 f6                	test   %esi,%esi
8010639c:	74 1a                	je     801063b8 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
8010639e:	83 ec 04             	sub    $0x4,%esp
801063a1:	6a 00                	push   $0x0
801063a3:	68 00 00 00 80       	push   $0x80000000
801063a8:	56                   	push   %esi
801063a9:	e8 68 fe ff ff       	call   80106216 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801063ae:	83 c4 10             	add    $0x10,%esp
801063b1:	bb 00 00 00 00       	mov    $0x0,%ebx
801063b6:	eb 10                	jmp    801063c8 <freevm+0x36>
    panic("freevm: no pgdir");
801063b8:	83 ec 0c             	sub    $0xc,%esp
801063bb:	68 dd 6f 10 80       	push   $0x80106fdd
801063c0:	e8 83 9f ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
801063c5:	83 c3 01             	add    $0x1,%ebx
801063c8:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
801063ce:	77 1f                	ja     801063ef <freevm+0x5d>
    if(pgdir[i] & PTE_P){
801063d0:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
801063d3:	a8 01                	test   $0x1,%al
801063d5:	74 ee                	je     801063c5 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801063d7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801063dc:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801063e1:	83 ec 0c             	sub    $0xc,%esp
801063e4:	50                   	push   %eax
801063e5:	e8 ce bb ff ff       	call   80101fb8 <kfree>
801063ea:	83 c4 10             	add    $0x10,%esp
801063ed:	eb d6                	jmp    801063c5 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
801063ef:	83 ec 0c             	sub    $0xc,%esp
801063f2:	56                   	push   %esi
801063f3:	e8 c0 bb ff ff       	call   80101fb8 <kfree>
}
801063f8:	83 c4 10             	add    $0x10,%esp
801063fb:	8d 65 f8             	lea    -0x8(%ebp),%esp
801063fe:	5b                   	pop    %ebx
801063ff:	5e                   	pop    %esi
80106400:	5d                   	pop    %ebp
80106401:	c3                   	ret    

80106402 <setupkvm>:
{
80106402:	55                   	push   %ebp
80106403:	89 e5                	mov    %esp,%ebp
80106405:	56                   	push   %esi
80106406:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc2()) == 0)
80106407:	e8 e4 bd ff ff       	call   801021f0 <kalloc2>
8010640c:	89 c6                	mov    %eax,%esi
8010640e:	85 c0                	test   %eax,%eax
80106410:	74 55                	je     80106467 <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
80106412:	83 ec 04             	sub    $0x4,%esp
80106415:	68 00 10 00 00       	push   $0x1000
8010641a:	6a 00                	push   $0x0
8010641c:	50                   	push   %eax
8010641d:	e8 e6 d9 ff ff       	call   80103e08 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106422:	83 c4 10             	add    $0x10,%esp
80106425:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
8010642a:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
80106430:	73 35                	jae    80106467 <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
80106432:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80106435:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106438:	29 c1                	sub    %eax,%ecx
8010643a:	83 ec 08             	sub    $0x8,%esp
8010643d:	ff 73 0c             	pushl  0xc(%ebx)
80106440:	50                   	push   %eax
80106441:	8b 13                	mov    (%ebx),%edx
80106443:	89 f0                	mov    %esi,%eax
80106445:	e8 d7 f9 ff ff       	call   80105e21 <mappages>
8010644a:	83 c4 10             	add    $0x10,%esp
8010644d:	85 c0                	test   %eax,%eax
8010644f:	78 05                	js     80106456 <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106451:	83 c3 10             	add    $0x10,%ebx
80106454:	eb d4                	jmp    8010642a <setupkvm+0x28>
      freevm(pgdir);
80106456:	83 ec 0c             	sub    $0xc,%esp
80106459:	56                   	push   %esi
8010645a:	e8 33 ff ff ff       	call   80106392 <freevm>
      return 0;
8010645f:	83 c4 10             	add    $0x10,%esp
80106462:	be 00 00 00 00       	mov    $0x0,%esi
}
80106467:	89 f0                	mov    %esi,%eax
80106469:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010646c:	5b                   	pop    %ebx
8010646d:	5e                   	pop    %esi
8010646e:	5d                   	pop    %ebp
8010646f:	c3                   	ret    

80106470 <kvmalloc>:
{
80106470:	55                   	push   %ebp
80106471:	89 e5                	mov    %esp,%ebp
80106473:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80106476:	e8 87 ff ff ff       	call   80106402 <setupkvm>
8010647b:	a3 c4 54 12 80       	mov    %eax,0x801254c4
  switchkvm();
80106480:	e8 5e fb ff ff       	call   80105fe3 <switchkvm>
}
80106485:	c9                   	leave  
80106486:	c3                   	ret    

80106487 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106487:	55                   	push   %ebp
80106488:	89 e5                	mov    %esp,%ebp
8010648a:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010648d:	b9 00 00 00 00       	mov    $0x0,%ecx
80106492:	8b 55 0c             	mov    0xc(%ebp),%edx
80106495:	8b 45 08             	mov    0x8(%ebp),%eax
80106498:	e8 14 f9 ff ff       	call   80105db1 <walkpgdir>
  if(pte == 0)
8010649d:	85 c0                	test   %eax,%eax
8010649f:	74 05                	je     801064a6 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
801064a1:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
801064a4:	c9                   	leave  
801064a5:	c3                   	ret    
    panic("clearpteu");
801064a6:	83 ec 0c             	sub    $0xc,%esp
801064a9:	68 ee 6f 10 80       	push   $0x80106fee
801064ae:	e8 95 9e ff ff       	call   80100348 <panic>

801064b3 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801064b3:	55                   	push   %ebp
801064b4:	89 e5                	mov    %esp,%ebp
801064b6:	57                   	push   %edi
801064b7:	56                   	push   %esi
801064b8:	53                   	push   %ebx
801064b9:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801064bc:	e8 41 ff ff ff       	call   80106402 <setupkvm>
801064c1:	89 45 dc             	mov    %eax,-0x24(%ebp)
801064c4:	85 c0                	test   %eax,%eax
801064c6:	0f 84 c4 00 00 00    	je     80106590 <copyuvm+0xdd>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801064cc:	bf 00 00 00 00       	mov    $0x0,%edi
801064d1:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801064d4:	0f 83 b6 00 00 00    	jae    80106590 <copyuvm+0xdd>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801064da:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801064dd:	b9 00 00 00 00       	mov    $0x0,%ecx
801064e2:	89 fa                	mov    %edi,%edx
801064e4:	8b 45 08             	mov    0x8(%ebp),%eax
801064e7:	e8 c5 f8 ff ff       	call   80105db1 <walkpgdir>
801064ec:	85 c0                	test   %eax,%eax
801064ee:	74 65                	je     80106555 <copyuvm+0xa2>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
801064f0:	8b 00                	mov    (%eax),%eax
801064f2:	a8 01                	test   $0x1,%al
801064f4:	74 6c                	je     80106562 <copyuvm+0xaf>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
801064f6:	89 c6                	mov    %eax,%esi
801064f8:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
801064fe:	25 ff 0f 00 00       	and    $0xfff,%eax
80106503:	89 45 e0             	mov    %eax,-0x20(%ebp)
    // manipulate this call to kalloc. Need to pass the pid?
    if((mem = kalloc()) == 0)
80106506:	e8 6a bc ff ff       	call   80102175 <kalloc>
8010650b:	89 c3                	mov    %eax,%ebx
8010650d:	85 c0                	test   %eax,%eax
8010650f:	74 6a                	je     8010657b <copyuvm+0xc8>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
80106511:	81 c6 00 00 00 80    	add    $0x80000000,%esi
80106517:	83 ec 04             	sub    $0x4,%esp
8010651a:	68 00 10 00 00       	push   $0x1000
8010651f:	56                   	push   %esi
80106520:	50                   	push   %eax
80106521:	e8 5d d9 ff ff       	call   80103e83 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
80106526:	83 c4 08             	add    $0x8,%esp
80106529:	ff 75 e0             	pushl  -0x20(%ebp)
8010652c:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106532:	50                   	push   %eax
80106533:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106538:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010653b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010653e:	e8 de f8 ff ff       	call   80105e21 <mappages>
80106543:	83 c4 10             	add    $0x10,%esp
80106546:	85 c0                	test   %eax,%eax
80106548:	78 25                	js     8010656f <copyuvm+0xbc>
  for(i = 0; i < sz; i += PGSIZE){
8010654a:	81 c7 00 10 00 00    	add    $0x1000,%edi
80106550:	e9 7c ff ff ff       	jmp    801064d1 <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
80106555:	83 ec 0c             	sub    $0xc,%esp
80106558:	68 f8 6f 10 80       	push   $0x80106ff8
8010655d:	e8 e6 9d ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
80106562:	83 ec 0c             	sub    $0xc,%esp
80106565:	68 12 70 10 80       	push   $0x80107012
8010656a:	e8 d9 9d ff ff       	call   80100348 <panic>
      kfree(mem);
8010656f:	83 ec 0c             	sub    $0xc,%esp
80106572:	53                   	push   %ebx
80106573:	e8 40 ba ff ff       	call   80101fb8 <kfree>
      goto bad;
80106578:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
8010657b:	83 ec 0c             	sub    $0xc,%esp
8010657e:	ff 75 dc             	pushl  -0x24(%ebp)
80106581:	e8 0c fe ff ff       	call   80106392 <freevm>
  return 0;
80106586:	83 c4 10             	add    $0x10,%esp
80106589:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
80106590:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106593:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106596:	5b                   	pop    %ebx
80106597:	5e                   	pop    %esi
80106598:	5f                   	pop    %edi
80106599:	5d                   	pop    %ebp
8010659a:	c3                   	ret    

8010659b <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010659b:	55                   	push   %ebp
8010659c:	89 e5                	mov    %esp,%ebp
8010659e:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801065a1:	b9 00 00 00 00       	mov    $0x0,%ecx
801065a6:	8b 55 0c             	mov    0xc(%ebp),%edx
801065a9:	8b 45 08             	mov    0x8(%ebp),%eax
801065ac:	e8 00 f8 ff ff       	call   80105db1 <walkpgdir>
  if((*pte & PTE_P) == 0)
801065b1:	8b 00                	mov    (%eax),%eax
801065b3:	a8 01                	test   $0x1,%al
801065b5:	74 10                	je     801065c7 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
801065b7:	a8 04                	test   $0x4,%al
801065b9:	74 13                	je     801065ce <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
801065bb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801065c0:	05 00 00 00 80       	add    $0x80000000,%eax
}
801065c5:	c9                   	leave  
801065c6:	c3                   	ret    
    return 0;
801065c7:	b8 00 00 00 00       	mov    $0x0,%eax
801065cc:	eb f7                	jmp    801065c5 <uva2ka+0x2a>
    return 0;
801065ce:	b8 00 00 00 00       	mov    $0x0,%eax
801065d3:	eb f0                	jmp    801065c5 <uva2ka+0x2a>

801065d5 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801065d5:	55                   	push   %ebp
801065d6:	89 e5                	mov    %esp,%ebp
801065d8:	57                   	push   %edi
801065d9:	56                   	push   %esi
801065da:	53                   	push   %ebx
801065db:	83 ec 0c             	sub    $0xc,%esp
801065de:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801065e1:	eb 25                	jmp    80106608 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801065e3:	8b 55 0c             	mov    0xc(%ebp),%edx
801065e6:	29 f2                	sub    %esi,%edx
801065e8:	01 d0                	add    %edx,%eax
801065ea:	83 ec 04             	sub    $0x4,%esp
801065ed:	53                   	push   %ebx
801065ee:	ff 75 10             	pushl  0x10(%ebp)
801065f1:	50                   	push   %eax
801065f2:	e8 8c d8 ff ff       	call   80103e83 <memmove>
    len -= n;
801065f7:	29 df                	sub    %ebx,%edi
    buf += n;
801065f9:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801065fc:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
80106602:	89 45 0c             	mov    %eax,0xc(%ebp)
80106605:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
80106608:	85 ff                	test   %edi,%edi
8010660a:	74 2f                	je     8010663b <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
8010660c:	8b 75 0c             	mov    0xc(%ebp),%esi
8010660f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
80106615:	83 ec 08             	sub    $0x8,%esp
80106618:	56                   	push   %esi
80106619:	ff 75 08             	pushl  0x8(%ebp)
8010661c:	e8 7a ff ff ff       	call   8010659b <uva2ka>
    if(pa0 == 0)
80106621:	83 c4 10             	add    $0x10,%esp
80106624:	85 c0                	test   %eax,%eax
80106626:	74 20                	je     80106648 <copyout+0x73>
    n = PGSIZE - (va - va0);
80106628:	89 f3                	mov    %esi,%ebx
8010662a:	2b 5d 0c             	sub    0xc(%ebp),%ebx
8010662d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
80106633:	39 df                	cmp    %ebx,%edi
80106635:	73 ac                	jae    801065e3 <copyout+0xe>
      n = len;
80106637:	89 fb                	mov    %edi,%ebx
80106639:	eb a8                	jmp    801065e3 <copyout+0xe>
  }
  return 0;
8010663b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106640:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106643:	5b                   	pop    %ebx
80106644:	5e                   	pop    %esi
80106645:	5f                   	pop    %edi
80106646:	5d                   	pop    %ebp
80106647:	c3                   	ret    
      return -1;
80106648:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010664d:	eb f1                	jmp    80106640 <copyout+0x6b>
