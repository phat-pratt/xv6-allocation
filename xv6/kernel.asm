
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
8010002d:	b8 90 2d 10 80       	mov    $0x80102d90,%eax
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
80100046:	e8 08 3f 00 00       	call   80103f53 <acquire>

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
8010007c:	e8 37 3f 00 00       	call   80103fb8 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 b3 3c 00 00       	call   80103d3f <acquiresleep>
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
801000ca:	e8 e9 3e 00 00       	call   80103fb8 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 65 3c 00 00       	call   80103d3f <acquiresleep>
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
801000ea:	68 80 68 10 80       	push   $0x80106880
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 91 68 10 80       	push   $0x80106891
80100100:	68 c0 b5 10 80       	push   $0x8010b5c0
80100105:	e8 0d 3d 00 00       	call   80103e17 <initlock>
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
8010013a:	68 98 68 10 80       	push   $0x80106898
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 c4 3b 00 00       	call   80103d0c <initsleeplock>
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
801001a8:	e8 1c 3c 00 00       	call   80103dc9 <holdingsleep>
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
801001cb:	68 9f 68 10 80       	push   $0x8010689f
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
801001e4:	e8 e0 3b 00 00       	call   80103dc9 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 95 3b 00 00       	call   80103d8e <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100200:	e8 4e 3d 00 00       	call   80103f53 <acquire>
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
8010024c:	e8 67 3d 00 00       	call   80103fb8 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 a6 68 10 80       	push   $0x801068a6
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
8010028a:	e8 c4 3c 00 00       	call   80103f53 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 a0 ff 10 80       	mov    0x8010ffa0,%eax
8010029f:	3b 05 a4 ff 10 80    	cmp    0x8010ffa4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 84 32 00 00       	call   80103530 <myproc>
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
801002bf:	e8 10 37 00 00       	call   801039d4 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 10 80       	push   $0x8010a520
801002d1:	e8 e2 3c 00 00       	call   80103fb8 <release>
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
80100331:	e8 82 3c 00 00       	call   80103fb8 <release>
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
8010035a:	e8 40 23 00 00       	call   8010269f <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 ad 68 10 80       	push   $0x801068ad
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 fb 71 10 80 	movl   $0x801071fb,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 9e 3a 00 00       	call   80103e32 <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 c1 68 10 80       	push   $0x801068c1
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
8010049e:	68 c5 68 10 80       	push   $0x801068c5
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 bb 3b 00 00       	call   8010407a <memmove>
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
801004d9:	e8 21 3b 00 00       	call   80103fff <memset>
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
80100506:	e8 2e 4f 00 00       	call   80105439 <uartputc>
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
8010051f:	e8 15 4f 00 00       	call   80105439 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 09 4f 00 00       	call   80105439 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 fd 4e 00 00       	call   80105439 <uartputc>
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
80100576:	0f b6 92 f0 68 10 80 	movzbl -0x7fef9710(%edx),%edx
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
801005ca:	e8 84 39 00 00       	call   80103f53 <acquire>
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
801005f1:	e8 c2 39 00 00       	call   80103fb8 <release>
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
80100638:	e8 16 39 00 00       	call   80103f53 <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 df 68 10 80       	push   $0x801068df
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
801006ee:	be d8 68 10 80       	mov    $0x801068d8,%esi
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
80100734:	e8 7f 38 00 00       	call   80103fb8 <release>
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
8010074f:	e8 ff 37 00 00       	call   80103f53 <acquire>
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
801007de:	e8 56 33 00 00       	call   80103b39 <wakeup>
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
80100873:	e8 40 37 00 00       	call   80103fb8 <release>
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
80100887:	e8 4a 33 00 00       	call   80103bd6 <procdump>
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
80100894:	68 e8 68 10 80       	push   $0x801068e8
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 74 35 00 00       	call   80103e17 <initlock>

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
801008de:	e8 4d 2c 00 00       	call   80103530 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 e1 21 00 00       	call   80102acf <begin_op>

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
80100935:	e8 0f 22 00 00       	call   80102b49 <end_op>
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
8010094a:	e8 fa 21 00 00       	call   80102b49 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 01 69 10 80       	push   $0x80106901
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
80100972:	e8 9b 5c 00 00       	call   80106612 <setupkvm>
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
80100a06:	e8 94 5a 00 00       	call   8010649f <allocuvm>
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
80100a38:	e8 30 59 00 00       	call   8010636d <loaduvm>
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
80100a53:	e8 f1 20 00 00       	call   80102b49 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 26 5a 00 00       	call   8010649f <allocuvm>
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
80100a9d:	e8 00 5b 00 00       	call   801065a2 <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 d6 5b 00 00       	call   80106697 <clearpteu>
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
80100ae2:	e8 ba 36 00 00       	call   801041a1 <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 a8 36 00 00       	call   801041a1 <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 e8 5c 00 00       	call   801067f3 <copyout>
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
80100b66:	e8 88 5c 00 00       	call   801067f3 <copyout>
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
80100ba3:	e8 be 35 00 00       	call   80104166 <safestrcpy>
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
80100bd1:	e8 16 56 00 00       	call   801061ec <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 c4 59 00 00       	call   801065a2 <freevm>
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
80100c19:	68 0d 69 10 80       	push   $0x8010690d
80100c1e:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c23:	e8 ef 31 00 00       	call   80103e17 <initlock>
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
80100c39:	e8 15 33 00 00       	call   80103f53 <acquire>
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
80100c68:	e8 4b 33 00 00       	call   80103fb8 <release>
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
80100c7f:	e8 34 33 00 00       	call   80103fb8 <release>
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
80100c9d:	e8 b1 32 00 00       	call   80103f53 <acquire>
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
80100cba:	e8 f9 32 00 00       	call   80103fb8 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 14 69 10 80       	push   $0x80106914
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
80100ce2:	e8 6c 32 00 00       	call   80103f53 <acquire>
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
80100d03:	e8 b0 32 00 00       	call   80103fb8 <release>
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
80100d13:	68 1c 69 10 80       	push   $0x8010691c
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
80100d49:	e8 6a 32 00 00       	call   80103fb8 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 6c 1d 00 00       	call   80102acf <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 d6 1d 00 00       	call   80102b49 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 ce 23 00 00       	call   80103156 <pipeclose>
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
80100e3c:	e8 6d 24 00 00       	call   801032ae <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 26 69 10 80       	push   $0x80106926
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
80100e95:	e8 48 23 00 00       	call   801031e2 <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 28 1c 00 00       	call   80102acf <begin_op>
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
80100edd:	e8 67 1c 00 00       	call   80102b49 <end_op>

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
80100f10:	68 2f 69 10 80       	push   $0x8010692f
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
80100f2d:	68 35 69 10 80       	push   $0x80106935
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
80100f8a:	e8 eb 30 00 00       	call   8010407a <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 db 30 00 00       	call   8010407a <memmove>
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
80100fdf:	e8 1b 30 00 00       	call   80103fff <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 0c 1c 00 00       	call   80102bf8 <log_write>
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
801010a3:	68 3f 69 10 80       	push   $0x8010693f
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
801010bf:	e8 34 1b 00 00       	call   80102bf8 <log_write>
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
80101170:	e8 83 1a 00 00       	call   80102bf8 <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 55 69 10 80       	push   $0x80106955
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
8010119a:	e8 b4 2d 00 00       	call   80103f53 <acquire>
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
801011e1:	e8 d2 2d 00 00       	call   80103fb8 <release>
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
80101217:	e8 9c 2d 00 00       	call   80103fb8 <release>
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
8010122c:	68 68 69 10 80       	push   $0x80106968
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
80101255:	e8 20 2e 00 00       	call   8010407a <memmove>
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
801012c8:	e8 2b 19 00 00       	call   80102bf8 <log_write>
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
801012e2:	68 78 69 10 80       	push   $0x80106978
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 8b 69 10 80       	push   $0x8010698b
801012f8:	68 e0 09 11 80       	push   $0x801109e0
801012fd:	e8 15 2b 00 00       	call   80103e17 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 92 69 10 80       	push   $0x80106992
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 20 0a 11 80       	add    $0x80110a20,%eax
80101321:	50                   	push   %eax
80101322:	e8 e5 29 00 00       	call   80103d0c <initsleeplock>
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
8010136c:	68 f8 69 10 80       	push   $0x801069f8
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
801013df:	68 98 69 10 80       	push   $0x80106998
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 09 2c 00 00       	call   80103fff <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 f3 17 00 00       	call   80102bf8 <log_write>
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
80101480:	e8 f5 2b 00 00       	call   8010407a <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 6b 17 00 00       	call   80102bf8 <log_write>
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
80101560:	e8 ee 29 00 00       	call   80103f53 <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
80101575:	e8 3e 2a 00 00       	call   80103fb8 <release>
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
8010159a:	e8 a0 27 00 00       	call   80103d3f <acquiresleep>
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
801015b2:	68 aa 69 10 80       	push   $0x801069aa
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
80101614:	e8 61 2a 00 00       	call   8010407a <memmove>
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
80101639:	68 b0 69 10 80       	push   $0x801069b0
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
80101656:	e8 6e 27 00 00       	call   80103dc9 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 1d 27 00 00       	call   80103d8e <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 bf 69 10 80       	push   $0x801069bf
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
80101698:	e8 a2 26 00 00       	call   80103d3f <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 d8 26 00 00       	call   80103d8e <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016bd:	e8 91 28 00 00       	call   80103f53 <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016d2:	e8 e1 28 00 00       	call   80103fb8 <release>
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
801016ea:	e8 64 28 00 00       	call   80103f53 <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016f9:	e8 ba 28 00 00       	call   80103fb8 <release>
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
8010182a:	e8 4b 28 00 00       	call   8010407a <memmove>
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
80101926:	e8 4f 27 00 00       	call   8010407a <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 c5 12 00 00       	call   80102bf8 <log_write>
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
801019a9:	e8 33 27 00 00       	call   801040e1 <strncmp>
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
801019d0:	68 c7 69 10 80       	push   $0x801069c7
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 d9 69 10 80       	push   $0x801069d9
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
80101a5a:	e8 d1 1a 00 00       	call   80103530 <myproc>
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
80101b92:	68 e8 69 10 80       	push   $0x801069e8
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 70 25 00 00       	call   8010411e <strncpy>
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
80101bd7:	68 f4 6f 10 80       	push   $0x80106ff4
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
80101ccc:	68 4b 6a 10 80       	push   $0x80106a4b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 54 6a 10 80       	push   $0x80106a54
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
80101d06:	68 66 6a 10 80       	push   $0x80106a66
80101d0b:	68 80 a5 10 80       	push   $0x8010a580
80101d10:	e8 02 21 00 00       	call   80103e17 <initlock>
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
80101d80:	e8 ce 21 00 00       	call   80103f53 <acquire>

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
80101dad:	e8 87 1d 00 00       	call   80103b39 <wakeup>

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
80101dcb:	e8 e8 21 00 00       	call   80103fb8 <release>
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
80101de2:	e8 d1 21 00 00       	call   80103fb8 <release>
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
80101e1a:	e8 aa 1f 00 00       	call   80103dc9 <holdingsleep>
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
80101e47:	e8 07 21 00 00       	call   80103f53 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 6a 6a 10 80       	push   $0x80106a6a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 80 6a 10 80       	push   $0x80106a80
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 95 6a 10 80       	push   $0x80106a95
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
80101ea9:	e8 26 1b 00 00       	call   801039d4 <sleep>
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
80101ec3:	e8 f0 20 00 00       	call   80103fb8 <release>
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
80101f3f:	68 b4 6a 10 80       	push   $0x80106ab4
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
  //add to track add. which page was alloacted by which procs
} kmem;

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
80101fbc:	75 4d                	jne    8010200b <kfree+0x5d>
80101fbe:	81 fb c8 54 15 80    	cmp    $0x801554c8,%ebx
80101fc4:	72 45                	jb     8010200b <kfree+0x5d>
80101fc6:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
80101fcc:	81 fe ff ff ff 0d    	cmp    $0xdffffff,%esi
80101fd2:	77 37                	ja     8010200b <kfree+0x5d>
    panic("kfree");

  // cprintf("freeing: %x\n", V2P(v)>>12);

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fd4:	83 ec 04             	sub    $0x4,%esp
80101fd7:	68 00 10 00 00       	push   $0x1000
80101fdc:	6a 01                	push   $0x1
80101fde:	53                   	push   %ebx
80101fdf:	e8 1b 20 00 00       	call   80103fff <memset>

  if (kmem.use_lock)
80101fe4:	83 c4 10             	add    $0x10,%esp
80101fe7:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80101fee:	75 28                	jne    80102018 <kfree+0x6a>
    acquire(&kmem.lock);
  r = (struct run *)v;
  r->pid = -1;
80101ff0:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
  //we need to ensure that the freelist is sorted when a freed frame is added. 
  //iterate through the freelist to find the frame that
  int i = V2P(r)>>12;
80101ff7:	c1 ee 0c             	shr    $0xc,%esi
  if(i == 0xdffb){
80101ffa:	81 fe fb df 00 00    	cmp    $0xdffb,%esi
80102000:	74 28                	je     8010202a <kfree+0x7c>
      cprintf("");
    }
  struct run *curr = kmem.freelist;
80102002:	a1 78 26 11 80       	mov    0x80112678,%eax
  struct run *prev = kmem.freelist;
80102007:	89 c2                	mov    %eax,%edx
  while(r<curr) {
80102009:	eb 35                	jmp    80102040 <kfree+0x92>
    panic("kfree");
8010200b:	83 ec 0c             	sub    $0xc,%esp
8010200e:	68 e6 6a 10 80       	push   $0x80106ae6
80102013:	e8 30 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
80102018:	83 ec 0c             	sub    $0xc,%esp
8010201b:	68 40 26 11 80       	push   $0x80112640
80102020:	e8 2e 1f 00 00       	call   80103f53 <acquire>
80102025:	83 c4 10             	add    $0x10,%esp
80102028:	eb c6                	jmp    80101ff0 <kfree+0x42>
      cprintf("");
8010202a:	83 ec 0c             	sub    $0xc,%esp
8010202d:	68 fc 71 10 80       	push   $0x801071fc
80102032:	e8 d4 e5 ff ff       	call   8010060b <cprintf>
80102037:	83 c4 10             	add    $0x10,%esp
8010203a:	eb c6                	jmp    80102002 <kfree+0x54>
    prev = curr;
8010203c:	89 c2                	mov    %eax,%edx
    curr = curr->next;
8010203e:	8b 00                	mov    (%eax),%eax
  while(r<curr) {
80102040:	39 d8                	cmp    %ebx,%eax
80102042:	77 f8                	ja     8010203c <kfree+0x8e>
  }
  curr->prev = r;
80102044:	89 58 08             	mov    %ebx,0x8(%eax)
  r->next = curr;
80102047:	89 03                	mov    %eax,(%ebx)
  if(prev == curr){
80102049:	39 d0                	cmp    %edx,%eax
8010204b:	74 20                	je     8010206d <kfree+0xbf>
    kmem.freelist = r;
  } else{
    prev->next = r;
8010204d:	89 1a                	mov    %ebx,(%edx)
    r->prev = prev;
8010204f:	89 53 08             	mov    %edx,0x8(%ebx)
  }
  //find the frame being freed in the allocated list
  
  framesList[i] = -1;
80102052:	c7 04 b5 80 26 11 80 	movl   $0xffffffff,-0x7feed980(,%esi,4)
80102059:	ff ff ff ff 
  // r->next = kmem.freelist;
  // kmem.freelist = r;
  
  if (kmem.use_lock)
8010205d:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80102064:	75 0f                	jne    80102075 <kfree+0xc7>
    release(&kmem.lock);
}
80102066:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102069:	5b                   	pop    %ebx
8010206a:	5e                   	pop    %esi
8010206b:	5d                   	pop    %ebp
8010206c:	c3                   	ret    
    kmem.freelist = r;
8010206d:	89 1d 78 26 11 80    	mov    %ebx,0x80112678
80102073:	eb dd                	jmp    80102052 <kfree+0xa4>
    release(&kmem.lock);
80102075:	83 ec 0c             	sub    $0xc,%esp
80102078:	68 40 26 11 80       	push   $0x80112640
8010207d:	e8 36 1f 00 00       	call   80103fb8 <release>
80102082:	83 c4 10             	add    $0x10,%esp
}
80102085:	eb df                	jmp    80102066 <kfree+0xb8>

80102087 <kfree2>:
void kfree2(char *v)
{
80102087:	55                   	push   %ebp
80102088:	89 e5                	mov    %esp,%ebp
8010208a:	56                   	push   %esi
8010208b:	53                   	push   %ebx
8010208c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if ((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
8010208f:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80102095:	75 6c                	jne    80102103 <kfree2+0x7c>
80102097:	81 fb c8 54 15 80    	cmp    $0x801554c8,%ebx
8010209d:	72 64                	jb     80102103 <kfree2+0x7c>
8010209f:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
801020a5:	81 fe ff ff ff 0d    	cmp    $0xdffffff,%esi
801020ab:	77 56                	ja     80102103 <kfree2+0x7c>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
801020ad:	83 ec 04             	sub    $0x4,%esp
801020b0:	68 00 10 00 00       	push   $0x1000
801020b5:	6a 01                	push   $0x1
801020b7:	53                   	push   %ebx
801020b8:	e8 42 1f 00 00       	call   80103fff <memset>

  if (kmem.use_lock)
801020bd:	83 c4 10             	add    $0x10,%esp
801020c0:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801020c7:	75 47                	jne    80102110 <kfree2+0x89>
    acquire(&kmem.lock);
  r = (struct run *)v;
  r->next = kmem.freelist;
801020c9:	a1 78 26 11 80       	mov    0x80112678,%eax
801020ce:	89 03                	mov    %eax,(%ebx)
  r->pid = -1;
801020d0:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
  int i = V2P(r)>>12;
801020d7:	c1 ee 0c             	shr    $0xc,%esi
  if(i == 0xdffb){
801020da:	81 fe fb df 00 00    	cmp    $0xdffb,%esi
801020e0:	74 40                	je     80102122 <kfree2+0x9b>
      cprintf("");
    }
  framesList[i] = -1;
801020e2:	c7 04 b5 80 26 11 80 	movl   $0xffffffff,-0x7feed980(,%esi,4)
801020e9:	ff ff ff ff 
  kmem.freelist = r;
801020ed:	89 1d 78 26 11 80    	mov    %ebx,0x80112678
  if (kmem.use_lock)
801020f3:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801020fa:	75 38                	jne    80102134 <kfree2+0xad>
    release(&kmem.lock);
}
801020fc:	8d 65 f8             	lea    -0x8(%ebp),%esp
801020ff:	5b                   	pop    %ebx
80102100:	5e                   	pop    %esi
80102101:	5d                   	pop    %ebp
80102102:	c3                   	ret    
    panic("kfree");
80102103:	83 ec 0c             	sub    $0xc,%esp
80102106:	68 e6 6a 10 80       	push   $0x80106ae6
8010210b:	e8 38 e2 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
80102110:	83 ec 0c             	sub    $0xc,%esp
80102113:	68 40 26 11 80       	push   $0x80112640
80102118:	e8 36 1e 00 00       	call   80103f53 <acquire>
8010211d:	83 c4 10             	add    $0x10,%esp
80102120:	eb a7                	jmp    801020c9 <kfree2+0x42>
      cprintf("");
80102122:	83 ec 0c             	sub    $0xc,%esp
80102125:	68 fc 71 10 80       	push   $0x801071fc
8010212a:	e8 dc e4 ff ff       	call   8010060b <cprintf>
8010212f:	83 c4 10             	add    $0x10,%esp
80102132:	eb ae                	jmp    801020e2 <kfree2+0x5b>
    release(&kmem.lock);
80102134:	83 ec 0c             	sub    $0xc,%esp
80102137:	68 40 26 11 80       	push   $0x80112640
8010213c:	e8 77 1e 00 00       	call   80103fb8 <release>
80102141:	83 c4 10             	add    $0x10,%esp
}
80102144:	eb b6                	jmp    801020fc <kfree2+0x75>

80102146 <freerange>:
{
80102146:	55                   	push   %ebp
80102147:	89 e5                	mov    %esp,%ebp
80102149:	56                   	push   %esi
8010214a:	53                   	push   %ebx
8010214b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char *)PGROUNDUP((uint)vstart);
8010214e:	8b 45 08             	mov    0x8(%ebp),%eax
80102151:	05 ff 0f 00 00       	add    $0xfff,%eax
80102156:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
8010215b:	eb 0e                	jmp    8010216b <freerange+0x25>
    kfree2(p);
8010215d:	83 ec 0c             	sub    $0xc,%esp
80102160:	50                   	push   %eax
80102161:	e8 21 ff ff ff       	call   80102087 <kfree2>
  for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
80102166:	83 c4 10             	add    $0x10,%esp
80102169:	89 f0                	mov    %esi,%eax
8010216b:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
80102171:	39 de                	cmp    %ebx,%esi
80102173:	76 e8                	jbe    8010215d <freerange+0x17>
}
80102175:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102178:	5b                   	pop    %ebx
80102179:	5e                   	pop    %esi
8010217a:	5d                   	pop    %ebp
8010217b:	c3                   	ret    

8010217c <kinit1>:
{
8010217c:	55                   	push   %ebp
8010217d:	89 e5                	mov    %esp,%ebp
8010217f:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
80102182:	68 ec 6a 10 80       	push   $0x80106aec
80102187:	68 40 26 11 80       	push   $0x80112640
8010218c:	e8 86 1c 00 00       	call   80103e17 <initlock>
  kmem.use_lock = 0;
80102191:	c7 05 74 26 11 80 00 	movl   $0x0,0x80112674
80102198:	00 00 00 
  freerange(vstart, vend);
8010219b:	83 c4 08             	add    $0x8,%esp
8010219e:	ff 75 0c             	pushl  0xc(%ebp)
801021a1:	ff 75 08             	pushl  0x8(%ebp)
801021a4:	e8 9d ff ff ff       	call   80102146 <freerange>
}
801021a9:	83 c4 10             	add    $0x10,%esp
801021ac:	c9                   	leave  
801021ad:	c3                   	ret    

801021ae <kinit2>:
{
801021ae:	55                   	push   %ebp
801021af:	89 e5                	mov    %esp,%ebp
801021b1:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
801021b4:	ff 75 0c             	pushl  0xc(%ebp)
801021b7:	ff 75 08             	pushl  0x8(%ebp)
801021ba:	e8 87 ff ff ff       	call   80102146 <freerange>
  kmem.use_lock = 1;
801021bf:	c7 05 74 26 11 80 01 	movl   $0x1,0x80112674
801021c6:	00 00 00 
}
801021c9:	83 c4 10             	add    $0x10,%esp
801021cc:	c9                   	leave  
801021cd:	c3                   	ret    

801021ce <kalloc>:
// Returns 0 if the memory cannot be allocated.
// From spec - kalloc manages freelist and allocates physical memory
// returns first page on the freelist
char *
kalloc(int pid)
{
801021ce:	55                   	push   %ebp
801021cf:	89 e5                	mov    %esp,%ebp
801021d1:	57                   	push   %edi
801021d2:	56                   	push   %esi
801021d3:	53                   	push   %ebx
801021d4:	83 ec 0c             	sub    $0xc,%esp
801021d7:	8b 7d 08             	mov    0x8(%ebp),%edi
  struct run *r;

  if (kmem.use_lock)
801021da:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801021e1:	75 1d                	jne    80102200 <kalloc+0x32>
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;
801021e3:	8b 35 78 26 11 80    	mov    0x80112678,%esi

  // we need to get the PA to retrieve the frame number
  if(pid == 3){
801021e9:	83 ff 03             	cmp    $0x3,%edi
801021ec:	75 5d                	jne    8010224b <kalloc+0x7d>
    cprintf("");
801021ee:	83 ec 0c             	sub    $0xc,%esp
801021f1:	68 fc 71 10 80       	push   $0x801071fc
801021f6:	e8 10 e4 ff ff       	call   8010060b <cprintf>
801021fb:	83 c4 10             	add    $0x10,%esp
801021fe:	eb 4b                	jmp    8010224b <kalloc+0x7d>
    acquire(&kmem.lock);
80102200:	83 ec 0c             	sub    $0xc,%esp
80102203:	68 40 26 11 80       	push   $0x80112640
80102208:	e8 46 1d 00 00       	call   80103f53 <acquire>
8010220d:	83 c4 10             	add    $0x10,%esp
80102210:	eb d1                	jmp    801021e3 <kalloc+0x15>
  int frameNumber;
  while (r) {
  
    frameNumber = V2P(r) >> 12;
    if(frameNumber == 0xdffb){
      cprintf("");
80102212:	83 ec 0c             	sub    $0xc,%esp
80102215:	68 fc 71 10 80       	push   $0x801071fc
8010221a:	e8 ec e3 ff ff       	call   8010060b <cprintf>
8010221f:	83 c4 10             	add    $0x10,%esp
80102222:	eb 3c                	jmp    80102260 <kalloc+0x92>
    }
    if(framesList[frameNumber + 1] == 0){
      framesList[frameNumber + 1] = -1;
    }
    //if the previous addr is allocated to the same pid and the next is not -> Allocate
    if((framesList[frameNumber - 1] == pid)
80102224:	8b 04 85 80 26 11 80 	mov    -0x7feed980(,%eax,4),%eax
8010222b:	39 f8                	cmp    %edi,%eax
8010222d:	74 66                	je     80102295 <kalloc+0xc7>
    && (framesList[frameNumber + 1] ==  -1)) {
      break;
    }
    // if the previous and next proc is allocated to the same pid -> Allocate.
    if((framesList[frameNumber - 1] == pid)
8010222f:	39 f8                	cmp    %edi,%eax
80102231:	0f 84 a6 00 00 00    	je     801022dd <kalloc+0x10f>
    && (framesList[frameNumber + 1] ==  pid)) {
      break;
    }
    //if the previous frame if free and the next frame is free -> Allocate
    if((framesList[frameNumber - 1] == -1)
80102237:	83 f8 ff             	cmp    $0xffffffff,%eax
8010223a:	0f 84 ac 00 00 00    	je     801022ec <kalloc+0x11e>
    && (framesList[frameNumber + 1] ==  -1)) {
      break;
    }
    if((framesList[frameNumber - 1] == -1)
80102240:	83 f8 ff             	cmp    $0xffffffff,%eax
80102243:	0f 84 b3 00 00 00    	je     801022fc <kalloc+0x12e>
    && (framesList[frameNumber + 1] ==  pid)) {
      break;
    }
    r = r->next;
80102249:	8b 36                	mov    (%esi),%esi
  while (r) {
8010224b:	85 f6                	test   %esi,%esi
8010224d:	74 50                	je     8010229f <kalloc+0xd1>
    frameNumber = V2P(r) >> 12;
8010224f:	8d 9e 00 00 00 80    	lea    -0x80000000(%esi),%ebx
80102255:	c1 eb 0c             	shr    $0xc,%ebx
    if(frameNumber == 0xdffb){
80102258:	81 fb fb df 00 00    	cmp    $0xdffb,%ebx
8010225e:	74 b2                	je     80102212 <kalloc+0x44>
    r->pid = pid;
80102260:	89 7e 04             	mov    %edi,0x4(%esi)
    if(framesList[frameNumber - 1] == 0){
80102263:	8d 43 ff             	lea    -0x1(%ebx),%eax
80102266:	83 3c 85 80 26 11 80 	cmpl   $0x0,-0x7feed980(,%eax,4)
8010226d:	00 
8010226e:	75 0b                	jne    8010227b <kalloc+0xad>
      framesList[frameNumber - 1] = -1;
80102270:	c7 04 85 80 26 11 80 	movl   $0xffffffff,-0x7feed980(,%eax,4)
80102277:	ff ff ff ff 
    if(framesList[frameNumber + 1] == 0){
8010227b:	83 c3 01             	add    $0x1,%ebx
8010227e:	83 3c 9d 80 26 11 80 	cmpl   $0x0,-0x7feed980(,%ebx,4)
80102285:	00 
80102286:	75 9c                	jne    80102224 <kalloc+0x56>
      framesList[frameNumber + 1] = -1;
80102288:	c7 04 9d 80 26 11 80 	movl   $0xffffffff,-0x7feed980(,%ebx,4)
8010228f:	ff ff ff ff 
80102293:	eb 8f                	jmp    80102224 <kalloc+0x56>
    && (framesList[frameNumber + 1] ==  -1)) {
80102295:	83 3c 9d 80 26 11 80 	cmpl   $0xffffffff,-0x7feed980(,%ebx,4)
8010229c:	ff 
8010229d:	75 90                	jne    8010222f <kalloc+0x61>
  }

  if (r){
8010229f:	85 f6                	test   %esi,%esi
801022a1:	74 27                	je     801022ca <kalloc+0xfc>
    
    frameNumber = V2P(r) >> 12;
801022a3:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
801022a9:	c1 e8 0c             	shr    $0xc,%eax

    // need to check if the frame r meets the security requirement.
    // if the previous frame is allocated and equal to the pid.
    if(framesList[frameNumber - 1] == pid) {
801022ac:	39 3c 85 7c 26 11 80 	cmp    %edi,-0x7feed984(,%eax,4)
801022b3:	74 56                	je     8010230b <kalloc+0x13d>
      }
      
    }

    // if the last process allocated is the same as the current, then create a free frame
    if(frameNumber > 1023) {
801022b5:	3d ff 03 00 00       	cmp    $0x3ff,%eax
801022ba:	7e 07                	jle    801022c3 <kalloc+0xf5>
      framesList[frameNumber] = pid;
801022bc:	89 3c 85 80 26 11 80 	mov    %edi,-0x7feed980(,%eax,4)
    }  
    kmem.freelist = r->next;
801022c3:	8b 06                	mov    (%esi),%eax
801022c5:	a3 78 26 11 80       	mov    %eax,0x80112678
    
  }
  if (kmem.use_lock)
801022ca:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801022d1:	75 4c                	jne    8010231f <kalloc+0x151>
  {
    release(&kmem.lock);
  }
  return (char *)r;
}
801022d3:	89 f0                	mov    %esi,%eax
801022d5:	8d 65 f4             	lea    -0xc(%ebp),%esp
801022d8:	5b                   	pop    %ebx
801022d9:	5e                   	pop    %esi
801022da:	5f                   	pop    %edi
801022db:	5d                   	pop    %ebp
801022dc:	c3                   	ret    
    && (framesList[frameNumber + 1] ==  pid)) {
801022dd:	39 3c 9d 80 26 11 80 	cmp    %edi,-0x7feed980(,%ebx,4)
801022e4:	0f 85 4d ff ff ff    	jne    80102237 <kalloc+0x69>
801022ea:	eb b3                	jmp    8010229f <kalloc+0xd1>
    && (framesList[frameNumber + 1] ==  -1)) {
801022ec:	83 3c 9d 80 26 11 80 	cmpl   $0xffffffff,-0x7feed980(,%ebx,4)
801022f3:	ff 
801022f4:	0f 85 46 ff ff ff    	jne    80102240 <kalloc+0x72>
801022fa:	eb a3                	jmp    8010229f <kalloc+0xd1>
    && (framesList[frameNumber + 1] ==  pid)) {
801022fc:	39 3c 9d 80 26 11 80 	cmp    %edi,-0x7feed980(,%ebx,4)
80102303:	0f 85 40 ff ff ff    	jne    80102249 <kalloc+0x7b>
80102309:	eb 94                	jmp    8010229f <kalloc+0xd1>
      if(framesList[frameNumber + 1] ==  -1) {
8010230b:	83 3c 85 84 26 11 80 	cmpl   $0xffffffff,-0x7feed97c(,%eax,4)
80102312:	ff 
80102313:	75 a0                	jne    801022b5 <kalloc+0xe7>
          kmem.freelist = r->next;
80102315:	8b 16                	mov    (%esi),%edx
80102317:	89 15 78 26 11 80    	mov    %edx,0x80112678
8010231d:	eb 96                	jmp    801022b5 <kalloc+0xe7>
    release(&kmem.lock);
8010231f:	83 ec 0c             	sub    $0xc,%esp
80102322:	68 40 26 11 80       	push   $0x80112640
80102327:	e8 8c 1c 00 00       	call   80103fb8 <release>
8010232c:	83 c4 10             	add    $0x10,%esp
  return (char *)r;
8010232f:	eb a2                	jmp    801022d3 <kalloc+0x105>

80102331 <kalloc2>:

// called by the excluded methods (inituvm, setupkvm, walkpgdir). We need to
// "mark these pages as belonging to an unknown process". (-2)
char *
kalloc2(void)
{
80102331:	55                   	push   %ebp
80102332:	89 e5                	mov    %esp,%ebp
80102334:	56                   	push   %esi
80102335:	53                   	push   %ebx
  struct run *r;

  if (kmem.use_lock)
80102336:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
8010233d:	75 0b                	jne    8010234a <kalloc2+0x19>
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;
8010233f:	8b 35 78 26 11 80    	mov    0x80112678,%esi
 
  int frameNumber;
  while (r) {
80102345:	e9 84 00 00 00       	jmp    801023ce <kalloc2+0x9d>
    acquire(&kmem.lock);
8010234a:	83 ec 0c             	sub    $0xc,%esp
8010234d:	68 40 26 11 80       	push   $0x80112640
80102352:	e8 fc 1b 00 00       	call   80103f53 <acquire>
80102357:	83 c4 10             	add    $0x10,%esp
8010235a:	eb e3                	jmp    8010233f <kalloc2+0xe>
  
    frameNumber = V2P(r) >> 12;
    if(frameNumber == 0xdffb){
      cprintf("");
8010235c:	83 ec 0c             	sub    $0xc,%esp
8010235f:	68 fc 71 10 80       	push   $0x801071fc
80102364:	e8 a2 e2 ff ff       	call   8010060b <cprintf>
80102369:	83 c4 10             	add    $0x10,%esp
8010236c:	eb 79                	jmp    801023e7 <kalloc2+0xb6>
    }
    r->pid = -2;

    //if the previous addr is allocated to the same pid and the next is not -> Allocate
    if((framesList[frameNumber - 1] == -2)
    && (framesList[frameNumber + 1] ==  -1)) {
8010236e:	83 3c 9d 84 26 11 80 	cmpl   $0xffffffff,-0x7feed97c(,%ebx,4)
80102375:	ff 
80102376:	0f 85 82 00 00 00    	jne    801023fe <kalloc2+0xcd>
    }
    r = r->next;
  }

  // we need to get the PA to retrieve the frame number
  if (r)
8010237c:	85 f6                	test   %esi,%esi
8010237e:	74 22                	je     801023a2 <kalloc2+0x71>
  {
    frameNumber = V2P(r) >> 12; 
80102380:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
80102386:	c1 e8 0c             	shr    $0xc,%eax

    if(frameNumber > 1023) {
80102389:	3d ff 03 00 00       	cmp    $0x3ff,%eax
8010238e:	7e 0b                	jle    8010239b <kalloc2+0x6a>
      framesList[frameNumber] = -2;
80102390:	c7 04 85 80 26 11 80 	movl   $0xfffffffe,-0x7feed980(,%eax,4)
80102397:	fe ff ff ff 
    }    
    kmem.freelist = r->next;
8010239b:	8b 06                	mov    (%esi),%eax
8010239d:	a3 78 26 11 80       	mov    %eax,0x80112678
   
  }
  if (kmem.use_lock)
801023a2:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801023a9:	75 71                	jne    8010241c <kalloc2+0xeb>
  {
    release(&kmem.lock);
  }
  return (char *)r;
}
801023ab:	89 f0                	mov    %esi,%eax
801023ad:	8d 65 f8             	lea    -0x8(%ebp),%esp
801023b0:	5b                   	pop    %ebx
801023b1:	5e                   	pop    %esi
801023b2:	5d                   	pop    %ebp
801023b3:	c3                   	ret    
    && (framesList[frameNumber + 1] ==  -2)) {
801023b4:	83 3c 9d 84 26 11 80 	cmpl   $0xfffffffe,-0x7feed97c(,%ebx,4)
801023bb:	fe 
801023bc:	75 45                	jne    80102403 <kalloc2+0xd2>
801023be:	eb bc                	jmp    8010237c <kalloc2+0x4b>
    && (framesList[frameNumber + 1] ==  -1)) {
801023c0:	83 3c 9d 84 26 11 80 	cmpl   $0xffffffff,-0x7feed97c(,%ebx,4)
801023c7:	ff 
801023c8:	75 3e                	jne    80102408 <kalloc2+0xd7>
801023ca:	eb b0                	jmp    8010237c <kalloc2+0x4b>
    r = r->next;
801023cc:	8b 36                	mov    (%esi),%esi
  while (r) {
801023ce:	85 f6                	test   %esi,%esi
801023d0:	74 aa                	je     8010237c <kalloc2+0x4b>
    frameNumber = V2P(r) >> 12;
801023d2:	8d 9e 00 00 00 80    	lea    -0x80000000(%esi),%ebx
801023d8:	c1 eb 0c             	shr    $0xc,%ebx
    if(frameNumber == 0xdffb){
801023db:	81 fb fb df 00 00    	cmp    $0xdffb,%ebx
801023e1:	0f 84 75 ff ff ff    	je     8010235c <kalloc2+0x2b>
    r->pid = -2;
801023e7:	c7 46 04 fe ff ff ff 	movl   $0xfffffffe,0x4(%esi)
    if((framesList[frameNumber - 1] == -2)
801023ee:	8b 04 9d 7c 26 11 80 	mov    -0x7feed984(,%ebx,4),%eax
801023f5:	83 f8 fe             	cmp    $0xfffffffe,%eax
801023f8:	0f 84 70 ff ff ff    	je     8010236e <kalloc2+0x3d>
    if((framesList[frameNumber - 1] == -2)
801023fe:	83 f8 fe             	cmp    $0xfffffffe,%eax
80102401:	74 b1                	je     801023b4 <kalloc2+0x83>
    if((framesList[frameNumber - 1] == -1)
80102403:	83 f8 ff             	cmp    $0xffffffff,%eax
80102406:	74 b8                	je     801023c0 <kalloc2+0x8f>
    if((framesList[frameNumber - 1] == -1)
80102408:	83 f8 ff             	cmp    $0xffffffff,%eax
8010240b:	75 bf                	jne    801023cc <kalloc2+0x9b>
    && (framesList[frameNumber + 1] ==  -2)) {
8010240d:	83 3c 9d 84 26 11 80 	cmpl   $0xfffffffe,-0x7feed97c(,%ebx,4)
80102414:	fe 
80102415:	75 b5                	jne    801023cc <kalloc2+0x9b>
80102417:	e9 60 ff ff ff       	jmp    8010237c <kalloc2+0x4b>
    release(&kmem.lock);
8010241c:	83 ec 0c             	sub    $0xc,%esp
8010241f:	68 40 26 11 80       	push   $0x80112640
80102424:	e8 8f 1b 00 00       	call   80103fb8 <release>
80102429:	83 c4 10             	add    $0x10,%esp
  return (char *)r;
8010242c:	e9 7a ff ff ff       	jmp    801023ab <kalloc2+0x7a>

80102431 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102431:	55                   	push   %ebp
80102432:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102434:	ba 64 00 00 00       	mov    $0x64,%edx
80102439:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
8010243a:	a8 01                	test   $0x1,%al
8010243c:	0f 84 b5 00 00 00    	je     801024f7 <kbdgetc+0xc6>
80102442:	ba 60 00 00 00       	mov    $0x60,%edx
80102447:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102448:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
8010244b:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
80102451:	74 5c                	je     801024af <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102453:	84 c0                	test   %al,%al
80102455:	78 66                	js     801024bd <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102457:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
8010245d:	f6 c1 40             	test   $0x40,%cl
80102460:	74 0f                	je     80102471 <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102462:	83 c8 80             	or     $0xffffff80,%eax
80102465:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
80102468:	83 e1 bf             	and    $0xffffffbf,%ecx
8010246b:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  }

  shift |= shiftcode[data];
80102471:	0f b6 8a 20 6c 10 80 	movzbl -0x7fef93e0(%edx),%ecx
80102478:	0b 0d b4 a5 10 80    	or     0x8010a5b4,%ecx
  shift ^= togglecode[data];
8010247e:	0f b6 82 20 6b 10 80 	movzbl -0x7fef94e0(%edx),%eax
80102485:	31 c1                	xor    %eax,%ecx
80102487:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  c = charcode[shift & (CTL | SHIFT)][data];
8010248d:	89 c8                	mov    %ecx,%eax
8010248f:	83 e0 03             	and    $0x3,%eax
80102492:	8b 04 85 00 6b 10 80 	mov    -0x7fef9500(,%eax,4),%eax
80102499:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
8010249d:	f6 c1 08             	test   $0x8,%cl
801024a0:	74 19                	je     801024bb <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
801024a2:	8d 50 9f             	lea    -0x61(%eax),%edx
801024a5:	83 fa 19             	cmp    $0x19,%edx
801024a8:	77 40                	ja     801024ea <kbdgetc+0xb9>
      c += 'A' - 'a';
801024aa:	83 e8 20             	sub    $0x20,%eax
801024ad:	eb 0c                	jmp    801024bb <kbdgetc+0x8a>
    shift |= E0ESC;
801024af:	83 0d b4 a5 10 80 40 	orl    $0x40,0x8010a5b4
    return 0;
801024b6:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
801024bb:	5d                   	pop    %ebp
801024bc:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
801024bd:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
801024c3:	f6 c1 40             	test   $0x40,%cl
801024c6:	75 05                	jne    801024cd <kbdgetc+0x9c>
801024c8:	89 c2                	mov    %eax,%edx
801024ca:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
801024cd:	0f b6 82 20 6c 10 80 	movzbl -0x7fef93e0(%edx),%eax
801024d4:	83 c8 40             	or     $0x40,%eax
801024d7:	0f b6 c0             	movzbl %al,%eax
801024da:	f7 d0                	not    %eax
801024dc:	21 c8                	and    %ecx,%eax
801024de:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    return 0;
801024e3:	b8 00 00 00 00       	mov    $0x0,%eax
801024e8:	eb d1                	jmp    801024bb <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
801024ea:	8d 50 bf             	lea    -0x41(%eax),%edx
801024ed:	83 fa 19             	cmp    $0x19,%edx
801024f0:	77 c9                	ja     801024bb <kbdgetc+0x8a>
      c += 'a' - 'A';
801024f2:	83 c0 20             	add    $0x20,%eax
  return c;
801024f5:	eb c4                	jmp    801024bb <kbdgetc+0x8a>
    return -1;
801024f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801024fc:	eb bd                	jmp    801024bb <kbdgetc+0x8a>

801024fe <kbdintr>:

void
kbdintr(void)
{
801024fe:	55                   	push   %ebp
801024ff:	89 e5                	mov    %esp,%ebp
80102501:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
80102504:	68 31 24 10 80       	push   $0x80102431
80102509:	e8 30 e2 ff ff       	call   8010073e <consoleintr>
}
8010250e:	83 c4 10             	add    $0x10,%esp
80102511:	c9                   	leave  
80102512:	c3                   	ret    

80102513 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102513:	55                   	push   %ebp
80102514:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102516:	8b 0d 84 26 15 80    	mov    0x80152684,%ecx
8010251c:	8d 04 81             	lea    (%ecx,%eax,4),%eax
8010251f:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
80102521:	a1 84 26 15 80       	mov    0x80152684,%eax
80102526:	8b 40 20             	mov    0x20(%eax),%eax
}
80102529:	5d                   	pop    %ebp
8010252a:	c3                   	ret    

8010252b <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
8010252b:	55                   	push   %ebp
8010252c:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010252e:	ba 70 00 00 00       	mov    $0x70,%edx
80102533:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102534:	ba 71 00 00 00       	mov    $0x71,%edx
80102539:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
8010253a:	0f b6 c0             	movzbl %al,%eax
}
8010253d:	5d                   	pop    %ebp
8010253e:	c3                   	ret    

8010253f <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
8010253f:	55                   	push   %ebp
80102540:	89 e5                	mov    %esp,%ebp
80102542:	53                   	push   %ebx
80102543:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
80102545:	b8 00 00 00 00       	mov    $0x0,%eax
8010254a:	e8 dc ff ff ff       	call   8010252b <cmos_read>
8010254f:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
80102551:	b8 02 00 00 00       	mov    $0x2,%eax
80102556:	e8 d0 ff ff ff       	call   8010252b <cmos_read>
8010255b:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
8010255e:	b8 04 00 00 00       	mov    $0x4,%eax
80102563:	e8 c3 ff ff ff       	call   8010252b <cmos_read>
80102568:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
8010256b:	b8 07 00 00 00       	mov    $0x7,%eax
80102570:	e8 b6 ff ff ff       	call   8010252b <cmos_read>
80102575:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102578:	b8 08 00 00 00       	mov    $0x8,%eax
8010257d:	e8 a9 ff ff ff       	call   8010252b <cmos_read>
80102582:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
80102585:	b8 09 00 00 00       	mov    $0x9,%eax
8010258a:	e8 9c ff ff ff       	call   8010252b <cmos_read>
8010258f:	89 43 14             	mov    %eax,0x14(%ebx)
}
80102592:	5b                   	pop    %ebx
80102593:	5d                   	pop    %ebp
80102594:	c3                   	ret    

80102595 <lapicinit>:
  if(!lapic)
80102595:	83 3d 84 26 15 80 00 	cmpl   $0x0,0x80152684
8010259c:	0f 84 fb 00 00 00    	je     8010269d <lapicinit+0x108>
{
801025a2:	55                   	push   %ebp
801025a3:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801025a5:	ba 3f 01 00 00       	mov    $0x13f,%edx
801025aa:	b8 3c 00 00 00       	mov    $0x3c,%eax
801025af:	e8 5f ff ff ff       	call   80102513 <lapicw>
  lapicw(TDCR, X1);
801025b4:	ba 0b 00 00 00       	mov    $0xb,%edx
801025b9:	b8 f8 00 00 00       	mov    $0xf8,%eax
801025be:	e8 50 ff ff ff       	call   80102513 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801025c3:	ba 20 00 02 00       	mov    $0x20020,%edx
801025c8:	b8 c8 00 00 00       	mov    $0xc8,%eax
801025cd:	e8 41 ff ff ff       	call   80102513 <lapicw>
  lapicw(TICR, 10000000);
801025d2:	ba 80 96 98 00       	mov    $0x989680,%edx
801025d7:	b8 e0 00 00 00       	mov    $0xe0,%eax
801025dc:	e8 32 ff ff ff       	call   80102513 <lapicw>
  lapicw(LINT0, MASKED);
801025e1:	ba 00 00 01 00       	mov    $0x10000,%edx
801025e6:	b8 d4 00 00 00       	mov    $0xd4,%eax
801025eb:	e8 23 ff ff ff       	call   80102513 <lapicw>
  lapicw(LINT1, MASKED);
801025f0:	ba 00 00 01 00       	mov    $0x10000,%edx
801025f5:	b8 d8 00 00 00       	mov    $0xd8,%eax
801025fa:	e8 14 ff ff ff       	call   80102513 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801025ff:	a1 84 26 15 80       	mov    0x80152684,%eax
80102604:	8b 40 30             	mov    0x30(%eax),%eax
80102607:	c1 e8 10             	shr    $0x10,%eax
8010260a:	3c 03                	cmp    $0x3,%al
8010260c:	77 7b                	ja     80102689 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010260e:	ba 33 00 00 00       	mov    $0x33,%edx
80102613:	b8 dc 00 00 00       	mov    $0xdc,%eax
80102618:	e8 f6 fe ff ff       	call   80102513 <lapicw>
  lapicw(ESR, 0);
8010261d:	ba 00 00 00 00       	mov    $0x0,%edx
80102622:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102627:	e8 e7 fe ff ff       	call   80102513 <lapicw>
  lapicw(ESR, 0);
8010262c:	ba 00 00 00 00       	mov    $0x0,%edx
80102631:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102636:	e8 d8 fe ff ff       	call   80102513 <lapicw>
  lapicw(EOI, 0);
8010263b:	ba 00 00 00 00       	mov    $0x0,%edx
80102640:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102645:	e8 c9 fe ff ff       	call   80102513 <lapicw>
  lapicw(ICRHI, 0);
8010264a:	ba 00 00 00 00       	mov    $0x0,%edx
8010264f:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102654:	e8 ba fe ff ff       	call   80102513 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102659:	ba 00 85 08 00       	mov    $0x88500,%edx
8010265e:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102663:	e8 ab fe ff ff       	call   80102513 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102668:	a1 84 26 15 80       	mov    0x80152684,%eax
8010266d:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
80102673:	f6 c4 10             	test   $0x10,%ah
80102676:	75 f0                	jne    80102668 <lapicinit+0xd3>
  lapicw(TPR, 0);
80102678:	ba 00 00 00 00       	mov    $0x0,%edx
8010267d:	b8 20 00 00 00       	mov    $0x20,%eax
80102682:	e8 8c fe ff ff       	call   80102513 <lapicw>
}
80102687:	5d                   	pop    %ebp
80102688:	c3                   	ret    
    lapicw(PCINT, MASKED);
80102689:	ba 00 00 01 00       	mov    $0x10000,%edx
8010268e:	b8 d0 00 00 00       	mov    $0xd0,%eax
80102693:	e8 7b fe ff ff       	call   80102513 <lapicw>
80102698:	e9 71 ff ff ff       	jmp    8010260e <lapicinit+0x79>
8010269d:	f3 c3                	repz ret 

8010269f <lapicid>:
{
8010269f:	55                   	push   %ebp
801026a0:	89 e5                	mov    %esp,%ebp
  if (!lapic)
801026a2:	a1 84 26 15 80       	mov    0x80152684,%eax
801026a7:	85 c0                	test   %eax,%eax
801026a9:	74 08                	je     801026b3 <lapicid+0x14>
  return lapic[ID] >> 24;
801026ab:	8b 40 20             	mov    0x20(%eax),%eax
801026ae:	c1 e8 18             	shr    $0x18,%eax
}
801026b1:	5d                   	pop    %ebp
801026b2:	c3                   	ret    
    return 0;
801026b3:	b8 00 00 00 00       	mov    $0x0,%eax
801026b8:	eb f7                	jmp    801026b1 <lapicid+0x12>

801026ba <lapiceoi>:
  if(lapic)
801026ba:	83 3d 84 26 15 80 00 	cmpl   $0x0,0x80152684
801026c1:	74 14                	je     801026d7 <lapiceoi+0x1d>
{
801026c3:	55                   	push   %ebp
801026c4:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
801026c6:	ba 00 00 00 00       	mov    $0x0,%edx
801026cb:	b8 2c 00 00 00       	mov    $0x2c,%eax
801026d0:	e8 3e fe ff ff       	call   80102513 <lapicw>
}
801026d5:	5d                   	pop    %ebp
801026d6:	c3                   	ret    
801026d7:	f3 c3                	repz ret 

801026d9 <microdelay>:
{
801026d9:	55                   	push   %ebp
801026da:	89 e5                	mov    %esp,%ebp
}
801026dc:	5d                   	pop    %ebp
801026dd:	c3                   	ret    

801026de <lapicstartap>:
{
801026de:	55                   	push   %ebp
801026df:	89 e5                	mov    %esp,%ebp
801026e1:	57                   	push   %edi
801026e2:	56                   	push   %esi
801026e3:	53                   	push   %ebx
801026e4:	8b 75 08             	mov    0x8(%ebp),%esi
801026e7:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801026ea:	b8 0f 00 00 00       	mov    $0xf,%eax
801026ef:	ba 70 00 00 00       	mov    $0x70,%edx
801026f4:	ee                   	out    %al,(%dx)
801026f5:	b8 0a 00 00 00       	mov    $0xa,%eax
801026fa:	ba 71 00 00 00       	mov    $0x71,%edx
801026ff:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
80102700:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80102707:	00 00 
  wrv[1] = addr >> 4;
80102709:	89 f8                	mov    %edi,%eax
8010270b:	c1 e8 04             	shr    $0x4,%eax
8010270e:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
80102714:	c1 e6 18             	shl    $0x18,%esi
80102717:	89 f2                	mov    %esi,%edx
80102719:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010271e:	e8 f0 fd ff ff       	call   80102513 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102723:	ba 00 c5 00 00       	mov    $0xc500,%edx
80102728:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010272d:	e8 e1 fd ff ff       	call   80102513 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
80102732:	ba 00 85 00 00       	mov    $0x8500,%edx
80102737:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010273c:	e8 d2 fd ff ff       	call   80102513 <lapicw>
  for(i = 0; i < 2; i++){
80102741:	bb 00 00 00 00       	mov    $0x0,%ebx
80102746:	eb 21                	jmp    80102769 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102748:	89 f2                	mov    %esi,%edx
8010274a:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010274f:	e8 bf fd ff ff       	call   80102513 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102754:	89 fa                	mov    %edi,%edx
80102756:	c1 ea 0c             	shr    $0xc,%edx
80102759:	80 ce 06             	or     $0x6,%dh
8010275c:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102761:	e8 ad fd ff ff       	call   80102513 <lapicw>
  for(i = 0; i < 2; i++){
80102766:	83 c3 01             	add    $0x1,%ebx
80102769:	83 fb 01             	cmp    $0x1,%ebx
8010276c:	7e da                	jle    80102748 <lapicstartap+0x6a>
}
8010276e:	5b                   	pop    %ebx
8010276f:	5e                   	pop    %esi
80102770:	5f                   	pop    %edi
80102771:	5d                   	pop    %ebp
80102772:	c3                   	ret    

80102773 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
80102773:	55                   	push   %ebp
80102774:	89 e5                	mov    %esp,%ebp
80102776:	57                   	push   %edi
80102777:	56                   	push   %esi
80102778:	53                   	push   %ebx
80102779:	83 ec 3c             	sub    $0x3c,%esp
8010277c:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
8010277f:	b8 0b 00 00 00       	mov    $0xb,%eax
80102784:	e8 a2 fd ff ff       	call   8010252b <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
80102789:	83 e0 04             	and    $0x4,%eax
8010278c:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
8010278e:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102791:	e8 a9 fd ff ff       	call   8010253f <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80102796:	b8 0a 00 00 00       	mov    $0xa,%eax
8010279b:	e8 8b fd ff ff       	call   8010252b <cmos_read>
801027a0:	a8 80                	test   $0x80,%al
801027a2:	75 ea                	jne    8010278e <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
801027a4:	8d 5d b8             	lea    -0x48(%ebp),%ebx
801027a7:	89 d8                	mov    %ebx,%eax
801027a9:	e8 91 fd ff ff       	call   8010253f <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801027ae:	83 ec 04             	sub    $0x4,%esp
801027b1:	6a 18                	push   $0x18
801027b3:	53                   	push   %ebx
801027b4:	8d 45 d0             	lea    -0x30(%ebp),%eax
801027b7:	50                   	push   %eax
801027b8:	e8 88 18 00 00       	call   80104045 <memcmp>
801027bd:	83 c4 10             	add    $0x10,%esp
801027c0:	85 c0                	test   %eax,%eax
801027c2:	75 ca                	jne    8010278e <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
801027c4:	85 ff                	test   %edi,%edi
801027c6:	0f 85 84 00 00 00    	jne    80102850 <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801027cc:	8b 55 d0             	mov    -0x30(%ebp),%edx
801027cf:	89 d0                	mov    %edx,%eax
801027d1:	c1 e8 04             	shr    $0x4,%eax
801027d4:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027d7:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027da:	83 e2 0f             	and    $0xf,%edx
801027dd:	01 d0                	add    %edx,%eax
801027df:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
801027e2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
801027e5:	89 d0                	mov    %edx,%eax
801027e7:	c1 e8 04             	shr    $0x4,%eax
801027ea:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027ed:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027f0:	83 e2 0f             	and    $0xf,%edx
801027f3:	01 d0                	add    %edx,%eax
801027f5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801027f8:	8b 55 d8             	mov    -0x28(%ebp),%edx
801027fb:	89 d0                	mov    %edx,%eax
801027fd:	c1 e8 04             	shr    $0x4,%eax
80102800:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102803:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102806:	83 e2 0f             	and    $0xf,%edx
80102809:	01 d0                	add    %edx,%eax
8010280b:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
8010280e:	8b 55 dc             	mov    -0x24(%ebp),%edx
80102811:	89 d0                	mov    %edx,%eax
80102813:	c1 e8 04             	shr    $0x4,%eax
80102816:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102819:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010281c:	83 e2 0f             	and    $0xf,%edx
8010281f:	01 d0                	add    %edx,%eax
80102821:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
80102824:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102827:	89 d0                	mov    %edx,%eax
80102829:	c1 e8 04             	shr    $0x4,%eax
8010282c:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010282f:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102832:	83 e2 0f             	and    $0xf,%edx
80102835:	01 d0                	add    %edx,%eax
80102837:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
8010283a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010283d:	89 d0                	mov    %edx,%eax
8010283f:	c1 e8 04             	shr    $0x4,%eax
80102842:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102845:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102848:	83 e2 0f             	and    $0xf,%edx
8010284b:	01 d0                	add    %edx,%eax
8010284d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
80102850:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102853:	89 06                	mov    %eax,(%esi)
80102855:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102858:	89 46 04             	mov    %eax,0x4(%esi)
8010285b:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010285e:	89 46 08             	mov    %eax,0x8(%esi)
80102861:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102864:	89 46 0c             	mov    %eax,0xc(%esi)
80102867:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010286a:	89 46 10             	mov    %eax,0x10(%esi)
8010286d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102870:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
80102873:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
8010287a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010287d:	5b                   	pop    %ebx
8010287e:	5e                   	pop    %esi
8010287f:	5f                   	pop    %edi
80102880:	5d                   	pop    %ebp
80102881:	c3                   	ret    

80102882 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80102882:	55                   	push   %ebp
80102883:	89 e5                	mov    %esp,%ebp
80102885:	53                   	push   %ebx
80102886:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102889:	ff 35 d4 26 15 80    	pushl  0x801526d4
8010288f:	ff 35 e4 26 15 80    	pushl  0x801526e4
80102895:	e8 d2 d8 ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
8010289a:	8b 58 5c             	mov    0x5c(%eax),%ebx
8010289d:	89 1d e8 26 15 80    	mov    %ebx,0x801526e8
  for (i = 0; i < log.lh.n; i++) {
801028a3:	83 c4 10             	add    $0x10,%esp
801028a6:	ba 00 00 00 00       	mov    $0x0,%edx
801028ab:	eb 0e                	jmp    801028bb <read_head+0x39>
    log.lh.block[i] = lh->block[i];
801028ad:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
801028b1:	89 0c 95 ec 26 15 80 	mov    %ecx,-0x7fead914(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801028b8:	83 c2 01             	add    $0x1,%edx
801028bb:	39 d3                	cmp    %edx,%ebx
801028bd:	7f ee                	jg     801028ad <read_head+0x2b>
  }
  brelse(buf);
801028bf:	83 ec 0c             	sub    $0xc,%esp
801028c2:	50                   	push   %eax
801028c3:	e8 0d d9 ff ff       	call   801001d5 <brelse>
}
801028c8:	83 c4 10             	add    $0x10,%esp
801028cb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801028ce:	c9                   	leave  
801028cf:	c3                   	ret    

801028d0 <install_trans>:
{
801028d0:	55                   	push   %ebp
801028d1:	89 e5                	mov    %esp,%ebp
801028d3:	57                   	push   %edi
801028d4:	56                   	push   %esi
801028d5:	53                   	push   %ebx
801028d6:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
801028d9:	bb 00 00 00 00       	mov    $0x0,%ebx
801028de:	eb 66                	jmp    80102946 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801028e0:	89 d8                	mov    %ebx,%eax
801028e2:	03 05 d4 26 15 80    	add    0x801526d4,%eax
801028e8:	83 c0 01             	add    $0x1,%eax
801028eb:	83 ec 08             	sub    $0x8,%esp
801028ee:	50                   	push   %eax
801028ef:	ff 35 e4 26 15 80    	pushl  0x801526e4
801028f5:	e8 72 d8 ff ff       	call   8010016c <bread>
801028fa:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801028fc:	83 c4 08             	add    $0x8,%esp
801028ff:	ff 34 9d ec 26 15 80 	pushl  -0x7fead914(,%ebx,4)
80102906:	ff 35 e4 26 15 80    	pushl  0x801526e4
8010290c:	e8 5b d8 ff ff       	call   8010016c <bread>
80102911:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80102913:	8d 57 5c             	lea    0x5c(%edi),%edx
80102916:	8d 40 5c             	lea    0x5c(%eax),%eax
80102919:	83 c4 0c             	add    $0xc,%esp
8010291c:	68 00 02 00 00       	push   $0x200
80102921:	52                   	push   %edx
80102922:	50                   	push   %eax
80102923:	e8 52 17 00 00       	call   8010407a <memmove>
    bwrite(dbuf);  // write dst to disk
80102928:	89 34 24             	mov    %esi,(%esp)
8010292b:	e8 6a d8 ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
80102930:	89 3c 24             	mov    %edi,(%esp)
80102933:	e8 9d d8 ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
80102938:	89 34 24             	mov    %esi,(%esp)
8010293b:	e8 95 d8 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102940:	83 c3 01             	add    $0x1,%ebx
80102943:	83 c4 10             	add    $0x10,%esp
80102946:	39 1d e8 26 15 80    	cmp    %ebx,0x801526e8
8010294c:	7f 92                	jg     801028e0 <install_trans+0x10>
}
8010294e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102951:	5b                   	pop    %ebx
80102952:	5e                   	pop    %esi
80102953:	5f                   	pop    %edi
80102954:	5d                   	pop    %ebp
80102955:	c3                   	ret    

80102956 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102956:	55                   	push   %ebp
80102957:	89 e5                	mov    %esp,%ebp
80102959:	53                   	push   %ebx
8010295a:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
8010295d:	ff 35 d4 26 15 80    	pushl  0x801526d4
80102963:	ff 35 e4 26 15 80    	pushl  0x801526e4
80102969:	e8 fe d7 ff ff       	call   8010016c <bread>
8010296e:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
80102970:	8b 0d e8 26 15 80    	mov    0x801526e8,%ecx
80102976:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102979:	83 c4 10             	add    $0x10,%esp
8010297c:	b8 00 00 00 00       	mov    $0x0,%eax
80102981:	eb 0e                	jmp    80102991 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
80102983:	8b 14 85 ec 26 15 80 	mov    -0x7fead914(,%eax,4),%edx
8010298a:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
8010298e:	83 c0 01             	add    $0x1,%eax
80102991:	39 c1                	cmp    %eax,%ecx
80102993:	7f ee                	jg     80102983 <write_head+0x2d>
  }
  bwrite(buf);
80102995:	83 ec 0c             	sub    $0xc,%esp
80102998:	53                   	push   %ebx
80102999:	e8 fc d7 ff ff       	call   8010019a <bwrite>
  brelse(buf);
8010299e:	89 1c 24             	mov    %ebx,(%esp)
801029a1:	e8 2f d8 ff ff       	call   801001d5 <brelse>
}
801029a6:	83 c4 10             	add    $0x10,%esp
801029a9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801029ac:	c9                   	leave  
801029ad:	c3                   	ret    

801029ae <recover_from_log>:

static void
recover_from_log(void)
{
801029ae:	55                   	push   %ebp
801029af:	89 e5                	mov    %esp,%ebp
801029b1:	83 ec 08             	sub    $0x8,%esp
  read_head();
801029b4:	e8 c9 fe ff ff       	call   80102882 <read_head>
  install_trans(); // if committed, copy from log to disk
801029b9:	e8 12 ff ff ff       	call   801028d0 <install_trans>
  log.lh.n = 0;
801029be:	c7 05 e8 26 15 80 00 	movl   $0x0,0x801526e8
801029c5:	00 00 00 
  write_head(); // clear the log
801029c8:	e8 89 ff ff ff       	call   80102956 <write_head>
}
801029cd:	c9                   	leave  
801029ce:	c3                   	ret    

801029cf <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
801029cf:	55                   	push   %ebp
801029d0:	89 e5                	mov    %esp,%ebp
801029d2:	57                   	push   %edi
801029d3:	56                   	push   %esi
801029d4:	53                   	push   %ebx
801029d5:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801029d8:	bb 00 00 00 00       	mov    $0x0,%ebx
801029dd:	eb 66                	jmp    80102a45 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
801029df:	89 d8                	mov    %ebx,%eax
801029e1:	03 05 d4 26 15 80    	add    0x801526d4,%eax
801029e7:	83 c0 01             	add    $0x1,%eax
801029ea:	83 ec 08             	sub    $0x8,%esp
801029ed:	50                   	push   %eax
801029ee:	ff 35 e4 26 15 80    	pushl  0x801526e4
801029f4:	e8 73 d7 ff ff       	call   8010016c <bread>
801029f9:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801029fb:	83 c4 08             	add    $0x8,%esp
801029fe:	ff 34 9d ec 26 15 80 	pushl  -0x7fead914(,%ebx,4)
80102a05:	ff 35 e4 26 15 80    	pushl  0x801526e4
80102a0b:	e8 5c d7 ff ff       	call   8010016c <bread>
80102a10:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
80102a12:	8d 50 5c             	lea    0x5c(%eax),%edx
80102a15:	8d 46 5c             	lea    0x5c(%esi),%eax
80102a18:	83 c4 0c             	add    $0xc,%esp
80102a1b:	68 00 02 00 00       	push   $0x200
80102a20:	52                   	push   %edx
80102a21:	50                   	push   %eax
80102a22:	e8 53 16 00 00       	call   8010407a <memmove>
    bwrite(to);  // write the log
80102a27:	89 34 24             	mov    %esi,(%esp)
80102a2a:	e8 6b d7 ff ff       	call   8010019a <bwrite>
    brelse(from);
80102a2f:	89 3c 24             	mov    %edi,(%esp)
80102a32:	e8 9e d7 ff ff       	call   801001d5 <brelse>
    brelse(to);
80102a37:	89 34 24             	mov    %esi,(%esp)
80102a3a:	e8 96 d7 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102a3f:	83 c3 01             	add    $0x1,%ebx
80102a42:	83 c4 10             	add    $0x10,%esp
80102a45:	39 1d e8 26 15 80    	cmp    %ebx,0x801526e8
80102a4b:	7f 92                	jg     801029df <write_log+0x10>
  }
}
80102a4d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102a50:	5b                   	pop    %ebx
80102a51:	5e                   	pop    %esi
80102a52:	5f                   	pop    %edi
80102a53:	5d                   	pop    %ebp
80102a54:	c3                   	ret    

80102a55 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
80102a55:	83 3d e8 26 15 80 00 	cmpl   $0x0,0x801526e8
80102a5c:	7e 26                	jle    80102a84 <commit+0x2f>
{
80102a5e:	55                   	push   %ebp
80102a5f:	89 e5                	mov    %esp,%ebp
80102a61:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
80102a64:	e8 66 ff ff ff       	call   801029cf <write_log>
    write_head();    // Write header to disk -- the real commit
80102a69:	e8 e8 fe ff ff       	call   80102956 <write_head>
    install_trans(); // Now install writes to home locations
80102a6e:	e8 5d fe ff ff       	call   801028d0 <install_trans>
    log.lh.n = 0;
80102a73:	c7 05 e8 26 15 80 00 	movl   $0x0,0x801526e8
80102a7a:	00 00 00 
    write_head();    // Erase the transaction from the log
80102a7d:	e8 d4 fe ff ff       	call   80102956 <write_head>
  }
}
80102a82:	c9                   	leave  
80102a83:	c3                   	ret    
80102a84:	f3 c3                	repz ret 

80102a86 <initlog>:
{
80102a86:	55                   	push   %ebp
80102a87:	89 e5                	mov    %esp,%ebp
80102a89:	53                   	push   %ebx
80102a8a:	83 ec 2c             	sub    $0x2c,%esp
80102a8d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
80102a90:	68 20 6d 10 80       	push   $0x80106d20
80102a95:	68 a0 26 15 80       	push   $0x801526a0
80102a9a:	e8 78 13 00 00       	call   80103e17 <initlock>
  readsb(dev, &sb);
80102a9f:	83 c4 08             	add    $0x8,%esp
80102aa2:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102aa5:	50                   	push   %eax
80102aa6:	53                   	push   %ebx
80102aa7:	e8 8a e7 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
80102aac:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102aaf:	a3 d4 26 15 80       	mov    %eax,0x801526d4
  log.size = sb.nlog;
80102ab4:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102ab7:	a3 d8 26 15 80       	mov    %eax,0x801526d8
  log.dev = dev;
80102abc:	89 1d e4 26 15 80    	mov    %ebx,0x801526e4
  recover_from_log();
80102ac2:	e8 e7 fe ff ff       	call   801029ae <recover_from_log>
}
80102ac7:	83 c4 10             	add    $0x10,%esp
80102aca:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102acd:	c9                   	leave  
80102ace:	c3                   	ret    

80102acf <begin_op>:
{
80102acf:	55                   	push   %ebp
80102ad0:	89 e5                	mov    %esp,%ebp
80102ad2:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102ad5:	68 a0 26 15 80       	push   $0x801526a0
80102ada:	e8 74 14 00 00       	call   80103f53 <acquire>
80102adf:	83 c4 10             	add    $0x10,%esp
80102ae2:	eb 15                	jmp    80102af9 <begin_op+0x2a>
      sleep(&log, &log.lock);
80102ae4:	83 ec 08             	sub    $0x8,%esp
80102ae7:	68 a0 26 15 80       	push   $0x801526a0
80102aec:	68 a0 26 15 80       	push   $0x801526a0
80102af1:	e8 de 0e 00 00       	call   801039d4 <sleep>
80102af6:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
80102af9:	83 3d e0 26 15 80 00 	cmpl   $0x0,0x801526e0
80102b00:	75 e2                	jne    80102ae4 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102b02:	a1 dc 26 15 80       	mov    0x801526dc,%eax
80102b07:	83 c0 01             	add    $0x1,%eax
80102b0a:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102b0d:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102b10:	03 15 e8 26 15 80    	add    0x801526e8,%edx
80102b16:	83 fa 1e             	cmp    $0x1e,%edx
80102b19:	7e 17                	jle    80102b32 <begin_op+0x63>
      sleep(&log, &log.lock);
80102b1b:	83 ec 08             	sub    $0x8,%esp
80102b1e:	68 a0 26 15 80       	push   $0x801526a0
80102b23:	68 a0 26 15 80       	push   $0x801526a0
80102b28:	e8 a7 0e 00 00       	call   801039d4 <sleep>
80102b2d:	83 c4 10             	add    $0x10,%esp
80102b30:	eb c7                	jmp    80102af9 <begin_op+0x2a>
      log.outstanding += 1;
80102b32:	a3 dc 26 15 80       	mov    %eax,0x801526dc
      release(&log.lock);
80102b37:	83 ec 0c             	sub    $0xc,%esp
80102b3a:	68 a0 26 15 80       	push   $0x801526a0
80102b3f:	e8 74 14 00 00       	call   80103fb8 <release>
}
80102b44:	83 c4 10             	add    $0x10,%esp
80102b47:	c9                   	leave  
80102b48:	c3                   	ret    

80102b49 <end_op>:
{
80102b49:	55                   	push   %ebp
80102b4a:	89 e5                	mov    %esp,%ebp
80102b4c:	53                   	push   %ebx
80102b4d:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102b50:	68 a0 26 15 80       	push   $0x801526a0
80102b55:	e8 f9 13 00 00       	call   80103f53 <acquire>
  log.outstanding -= 1;
80102b5a:	a1 dc 26 15 80       	mov    0x801526dc,%eax
80102b5f:	83 e8 01             	sub    $0x1,%eax
80102b62:	a3 dc 26 15 80       	mov    %eax,0x801526dc
  if(log.committing)
80102b67:	8b 1d e0 26 15 80    	mov    0x801526e0,%ebx
80102b6d:	83 c4 10             	add    $0x10,%esp
80102b70:	85 db                	test   %ebx,%ebx
80102b72:	75 2c                	jne    80102ba0 <end_op+0x57>
  if(log.outstanding == 0){
80102b74:	85 c0                	test   %eax,%eax
80102b76:	75 35                	jne    80102bad <end_op+0x64>
    log.committing = 1;
80102b78:	c7 05 e0 26 15 80 01 	movl   $0x1,0x801526e0
80102b7f:	00 00 00 
    do_commit = 1;
80102b82:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102b87:	83 ec 0c             	sub    $0xc,%esp
80102b8a:	68 a0 26 15 80       	push   $0x801526a0
80102b8f:	e8 24 14 00 00       	call   80103fb8 <release>
  if(do_commit){
80102b94:	83 c4 10             	add    $0x10,%esp
80102b97:	85 db                	test   %ebx,%ebx
80102b99:	75 24                	jne    80102bbf <end_op+0x76>
}
80102b9b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102b9e:	c9                   	leave  
80102b9f:	c3                   	ret    
    panic("log.committing");
80102ba0:	83 ec 0c             	sub    $0xc,%esp
80102ba3:	68 24 6d 10 80       	push   $0x80106d24
80102ba8:	e8 9b d7 ff ff       	call   80100348 <panic>
    wakeup(&log);
80102bad:	83 ec 0c             	sub    $0xc,%esp
80102bb0:	68 a0 26 15 80       	push   $0x801526a0
80102bb5:	e8 7f 0f 00 00       	call   80103b39 <wakeup>
80102bba:	83 c4 10             	add    $0x10,%esp
80102bbd:	eb c8                	jmp    80102b87 <end_op+0x3e>
    commit();
80102bbf:	e8 91 fe ff ff       	call   80102a55 <commit>
    acquire(&log.lock);
80102bc4:	83 ec 0c             	sub    $0xc,%esp
80102bc7:	68 a0 26 15 80       	push   $0x801526a0
80102bcc:	e8 82 13 00 00       	call   80103f53 <acquire>
    log.committing = 0;
80102bd1:	c7 05 e0 26 15 80 00 	movl   $0x0,0x801526e0
80102bd8:	00 00 00 
    wakeup(&log);
80102bdb:	c7 04 24 a0 26 15 80 	movl   $0x801526a0,(%esp)
80102be2:	e8 52 0f 00 00       	call   80103b39 <wakeup>
    release(&log.lock);
80102be7:	c7 04 24 a0 26 15 80 	movl   $0x801526a0,(%esp)
80102bee:	e8 c5 13 00 00       	call   80103fb8 <release>
80102bf3:	83 c4 10             	add    $0x10,%esp
}
80102bf6:	eb a3                	jmp    80102b9b <end_op+0x52>

80102bf8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102bf8:	55                   	push   %ebp
80102bf9:	89 e5                	mov    %esp,%ebp
80102bfb:	53                   	push   %ebx
80102bfc:	83 ec 04             	sub    $0x4,%esp
80102bff:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102c02:	8b 15 e8 26 15 80    	mov    0x801526e8,%edx
80102c08:	83 fa 1d             	cmp    $0x1d,%edx
80102c0b:	7f 45                	jg     80102c52 <log_write+0x5a>
80102c0d:	a1 d8 26 15 80       	mov    0x801526d8,%eax
80102c12:	83 e8 01             	sub    $0x1,%eax
80102c15:	39 c2                	cmp    %eax,%edx
80102c17:	7d 39                	jge    80102c52 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102c19:	83 3d dc 26 15 80 00 	cmpl   $0x0,0x801526dc
80102c20:	7e 3d                	jle    80102c5f <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102c22:	83 ec 0c             	sub    $0xc,%esp
80102c25:	68 a0 26 15 80       	push   $0x801526a0
80102c2a:	e8 24 13 00 00       	call   80103f53 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102c2f:	83 c4 10             	add    $0x10,%esp
80102c32:	b8 00 00 00 00       	mov    $0x0,%eax
80102c37:	8b 15 e8 26 15 80    	mov    0x801526e8,%edx
80102c3d:	39 c2                	cmp    %eax,%edx
80102c3f:	7e 2b                	jle    80102c6c <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102c41:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102c44:	39 0c 85 ec 26 15 80 	cmp    %ecx,-0x7fead914(,%eax,4)
80102c4b:	74 1f                	je     80102c6c <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102c4d:	83 c0 01             	add    $0x1,%eax
80102c50:	eb e5                	jmp    80102c37 <log_write+0x3f>
    panic("too big a transaction");
80102c52:	83 ec 0c             	sub    $0xc,%esp
80102c55:	68 33 6d 10 80       	push   $0x80106d33
80102c5a:	e8 e9 d6 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102c5f:	83 ec 0c             	sub    $0xc,%esp
80102c62:	68 49 6d 10 80       	push   $0x80106d49
80102c67:	e8 dc d6 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102c6c:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102c6f:	89 0c 85 ec 26 15 80 	mov    %ecx,-0x7fead914(,%eax,4)
  if (i == log.lh.n)
80102c76:	39 c2                	cmp    %eax,%edx
80102c78:	74 18                	je     80102c92 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102c7a:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102c7d:	83 ec 0c             	sub    $0xc,%esp
80102c80:	68 a0 26 15 80       	push   $0x801526a0
80102c85:	e8 2e 13 00 00       	call   80103fb8 <release>
}
80102c8a:	83 c4 10             	add    $0x10,%esp
80102c8d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102c90:	c9                   	leave  
80102c91:	c3                   	ret    
    log.lh.n++;
80102c92:	83 c2 01             	add    $0x1,%edx
80102c95:	89 15 e8 26 15 80    	mov    %edx,0x801526e8
80102c9b:	eb dd                	jmp    80102c7a <log_write+0x82>

80102c9d <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102c9d:	55                   	push   %ebp
80102c9e:	89 e5                	mov    %esp,%ebp
80102ca0:	53                   	push   %ebx
80102ca1:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102ca4:	68 8a 00 00 00       	push   $0x8a
80102ca9:	68 8c a4 10 80       	push   $0x8010a48c
80102cae:	68 00 70 00 80       	push   $0x80007000
80102cb3:	e8 c2 13 00 00       	call   8010407a <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102cb8:	83 c4 10             	add    $0x10,%esp
80102cbb:	bb a0 27 15 80       	mov    $0x801527a0,%ebx
80102cc0:	eb 06                	jmp    80102cc8 <startothers+0x2b>
80102cc2:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102cc8:	69 05 20 2d 15 80 b0 	imul   $0xb0,0x80152d20,%eax
80102ccf:	00 00 00 
80102cd2:	05 a0 27 15 80       	add    $0x801527a0,%eax
80102cd7:	39 d8                	cmp    %ebx,%eax
80102cd9:	76 57                	jbe    80102d32 <startothers+0x95>
    if(c == mycpu())  // We've started already.
80102cdb:	e8 d9 07 00 00       	call   801034b9 <mycpu>
80102ce0:	39 d8                	cmp    %ebx,%eax
80102ce2:	74 de                	je     80102cc2 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc(myproc()->pid); // need to pass the pid to kalloc?
80102ce4:	e8 47 08 00 00       	call   80103530 <myproc>
80102ce9:	83 ec 0c             	sub    $0xc,%esp
80102cec:	ff 70 10             	pushl  0x10(%eax)
80102cef:	e8 da f4 ff ff       	call   801021ce <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102cf4:	05 00 10 00 00       	add    $0x1000,%eax
80102cf9:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102cfe:	c7 05 f8 6f 00 80 76 	movl   $0x80102d76,0x80006ff8
80102d05:	2d 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102d08:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102d0f:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102d12:	83 c4 08             	add    $0x8,%esp
80102d15:	68 00 70 00 00       	push   $0x7000
80102d1a:	0f b6 03             	movzbl (%ebx),%eax
80102d1d:	50                   	push   %eax
80102d1e:	e8 bb f9 ff ff       	call   801026de <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102d23:	83 c4 10             	add    $0x10,%esp
80102d26:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102d2c:	85 c0                	test   %eax,%eax
80102d2e:	74 f6                	je     80102d26 <startothers+0x89>
80102d30:	eb 90                	jmp    80102cc2 <startothers+0x25>
      ;
  }
}
80102d32:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102d35:	c9                   	leave  
80102d36:	c3                   	ret    

80102d37 <mpmain>:
{
80102d37:	55                   	push   %ebp
80102d38:	89 e5                	mov    %esp,%ebp
80102d3a:	53                   	push   %ebx
80102d3b:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102d3e:	e8 d2 07 00 00       	call   80103515 <cpuid>
80102d43:	89 c3                	mov    %eax,%ebx
80102d45:	e8 cb 07 00 00       	call   80103515 <cpuid>
80102d4a:	83 ec 04             	sub    $0x4,%esp
80102d4d:	53                   	push   %ebx
80102d4e:	50                   	push   %eax
80102d4f:	68 64 6d 10 80       	push   $0x80106d64
80102d54:	e8 b2 d8 ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102d59:	e8 73 24 00 00       	call   801051d1 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102d5e:	e8 56 07 00 00       	call   801034b9 <mycpu>
80102d63:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102d65:	b8 01 00 00 00       	mov    $0x1,%eax
80102d6a:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102d71:	e8 39 0a 00 00       	call   801037af <scheduler>

80102d76 <mpenter>:
{
80102d76:	55                   	push   %ebp
80102d77:	89 e5                	mov    %esp,%ebp
80102d79:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102d7c:	e8 59 34 00 00       	call   801061da <switchkvm>
  seginit();
80102d81:	e8 08 33 00 00       	call   8010608e <seginit>
  lapicinit();
80102d86:	e8 0a f8 ff ff       	call   80102595 <lapicinit>
  mpmain();
80102d8b:	e8 a7 ff ff ff       	call   80102d37 <mpmain>

80102d90 <main>:
{
80102d90:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102d94:	83 e4 f0             	and    $0xfffffff0,%esp
80102d97:	ff 71 fc             	pushl  -0x4(%ecx)
80102d9a:	55                   	push   %ebp
80102d9b:	89 e5                	mov    %esp,%ebp
80102d9d:	51                   	push   %ecx
80102d9e:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102da1:	68 00 00 40 80       	push   $0x80400000
80102da6:	68 c8 54 15 80       	push   $0x801554c8
80102dab:	e8 cc f3 ff ff       	call   8010217c <kinit1>
  kvmalloc();      // kernel page table
80102db0:	e8 cb 38 00 00       	call   80106680 <kvmalloc>
  mpinit();        // detect other processors
80102db5:	e8 c9 01 00 00       	call   80102f83 <mpinit>
  lapicinit();     // interrupt controller
80102dba:	e8 d6 f7 ff ff       	call   80102595 <lapicinit>
  seginit();       // segment descriptors
80102dbf:	e8 ca 32 00 00       	call   8010608e <seginit>
  picinit();       // disable pic
80102dc4:	e8 82 02 00 00       	call   8010304b <picinit>
  ioapicinit();    // another interrupt controller
80102dc9:	e8 2c f1 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102dce:	e8 bb da ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102dd3:	e8 a7 26 00 00       	call   8010547f <uartinit>
  pinit();         // process table
80102dd8:	e8 c2 06 00 00       	call   8010349f <pinit>
  tvinit();        // trap vectors
80102ddd:	e8 3e 23 00 00       	call   80105120 <tvinit>
  binit();         // buffer cache
80102de2:	e8 0d d3 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102de7:	e8 27 de ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102dec:	e8 0f ef ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102df1:	e8 a7 fe ff ff       	call   80102c9d <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102df6:	83 c4 08             	add    $0x8,%esp
80102df9:	68 00 00 00 8e       	push   $0x8e000000
80102dfe:	68 00 00 40 80       	push   $0x80400000
80102e03:	e8 a6 f3 ff ff       	call   801021ae <kinit2>
  userinit();      // first user process
80102e08:	e8 47 07 00 00       	call   80103554 <userinit>
  mpmain();        // finish this processor's setup
80102e0d:	e8 25 ff ff ff       	call   80102d37 <mpmain>

80102e12 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102e12:	55                   	push   %ebp
80102e13:	89 e5                	mov    %esp,%ebp
80102e15:	56                   	push   %esi
80102e16:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102e17:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102e1c:	b9 00 00 00 00       	mov    $0x0,%ecx
80102e21:	eb 09                	jmp    80102e2c <sum+0x1a>
    sum += addr[i];
80102e23:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102e27:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102e29:	83 c1 01             	add    $0x1,%ecx
80102e2c:	39 d1                	cmp    %edx,%ecx
80102e2e:	7c f3                	jl     80102e23 <sum+0x11>
  return sum;
}
80102e30:	89 d8                	mov    %ebx,%eax
80102e32:	5b                   	pop    %ebx
80102e33:	5e                   	pop    %esi
80102e34:	5d                   	pop    %ebp
80102e35:	c3                   	ret    

80102e36 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102e36:	55                   	push   %ebp
80102e37:	89 e5                	mov    %esp,%ebp
80102e39:	56                   	push   %esi
80102e3a:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102e3b:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102e41:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102e43:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102e45:	eb 03                	jmp    80102e4a <mpsearch1+0x14>
80102e47:	83 c3 10             	add    $0x10,%ebx
80102e4a:	39 f3                	cmp    %esi,%ebx
80102e4c:	73 29                	jae    80102e77 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102e4e:	83 ec 04             	sub    $0x4,%esp
80102e51:	6a 04                	push   $0x4
80102e53:	68 78 6d 10 80       	push   $0x80106d78
80102e58:	53                   	push   %ebx
80102e59:	e8 e7 11 00 00       	call   80104045 <memcmp>
80102e5e:	83 c4 10             	add    $0x10,%esp
80102e61:	85 c0                	test   %eax,%eax
80102e63:	75 e2                	jne    80102e47 <mpsearch1+0x11>
80102e65:	ba 10 00 00 00       	mov    $0x10,%edx
80102e6a:	89 d8                	mov    %ebx,%eax
80102e6c:	e8 a1 ff ff ff       	call   80102e12 <sum>
80102e71:	84 c0                	test   %al,%al
80102e73:	75 d2                	jne    80102e47 <mpsearch1+0x11>
80102e75:	eb 05                	jmp    80102e7c <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102e77:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102e7c:	89 d8                	mov    %ebx,%eax
80102e7e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102e81:	5b                   	pop    %ebx
80102e82:	5e                   	pop    %esi
80102e83:	5d                   	pop    %ebp
80102e84:	c3                   	ret    

80102e85 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102e85:	55                   	push   %ebp
80102e86:	89 e5                	mov    %esp,%ebp
80102e88:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102e8b:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102e92:	c1 e0 08             	shl    $0x8,%eax
80102e95:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102e9c:	09 d0                	or     %edx,%eax
80102e9e:	c1 e0 04             	shl    $0x4,%eax
80102ea1:	85 c0                	test   %eax,%eax
80102ea3:	74 1f                	je     80102ec4 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102ea5:	ba 00 04 00 00       	mov    $0x400,%edx
80102eaa:	e8 87 ff ff ff       	call   80102e36 <mpsearch1>
80102eaf:	85 c0                	test   %eax,%eax
80102eb1:	75 0f                	jne    80102ec2 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102eb3:	ba 00 00 01 00       	mov    $0x10000,%edx
80102eb8:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102ebd:	e8 74 ff ff ff       	call   80102e36 <mpsearch1>
}
80102ec2:	c9                   	leave  
80102ec3:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102ec4:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102ecb:	c1 e0 08             	shl    $0x8,%eax
80102ece:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102ed5:	09 d0                	or     %edx,%eax
80102ed7:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102eda:	2d 00 04 00 00       	sub    $0x400,%eax
80102edf:	ba 00 04 00 00       	mov    $0x400,%edx
80102ee4:	e8 4d ff ff ff       	call   80102e36 <mpsearch1>
80102ee9:	85 c0                	test   %eax,%eax
80102eeb:	75 d5                	jne    80102ec2 <mpsearch+0x3d>
80102eed:	eb c4                	jmp    80102eb3 <mpsearch+0x2e>

80102eef <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102eef:	55                   	push   %ebp
80102ef0:	89 e5                	mov    %esp,%ebp
80102ef2:	57                   	push   %edi
80102ef3:	56                   	push   %esi
80102ef4:	53                   	push   %ebx
80102ef5:	83 ec 1c             	sub    $0x1c,%esp
80102ef8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102efb:	e8 85 ff ff ff       	call   80102e85 <mpsearch>
80102f00:	85 c0                	test   %eax,%eax
80102f02:	74 5c                	je     80102f60 <mpconfig+0x71>
80102f04:	89 c7                	mov    %eax,%edi
80102f06:	8b 58 04             	mov    0x4(%eax),%ebx
80102f09:	85 db                	test   %ebx,%ebx
80102f0b:	74 5a                	je     80102f67 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102f0d:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102f13:	83 ec 04             	sub    $0x4,%esp
80102f16:	6a 04                	push   $0x4
80102f18:	68 7d 6d 10 80       	push   $0x80106d7d
80102f1d:	56                   	push   %esi
80102f1e:	e8 22 11 00 00       	call   80104045 <memcmp>
80102f23:	83 c4 10             	add    $0x10,%esp
80102f26:	85 c0                	test   %eax,%eax
80102f28:	75 44                	jne    80102f6e <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102f2a:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102f31:	3c 01                	cmp    $0x1,%al
80102f33:	0f 95 c2             	setne  %dl
80102f36:	3c 04                	cmp    $0x4,%al
80102f38:	0f 95 c0             	setne  %al
80102f3b:	84 c2                	test   %al,%dl
80102f3d:	75 36                	jne    80102f75 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102f3f:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102f46:	89 f0                	mov    %esi,%eax
80102f48:	e8 c5 fe ff ff       	call   80102e12 <sum>
80102f4d:	84 c0                	test   %al,%al
80102f4f:	75 2b                	jne    80102f7c <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102f51:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102f54:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102f56:	89 f0                	mov    %esi,%eax
80102f58:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f5b:	5b                   	pop    %ebx
80102f5c:	5e                   	pop    %esi
80102f5d:	5f                   	pop    %edi
80102f5e:	5d                   	pop    %ebp
80102f5f:	c3                   	ret    
    return 0;
80102f60:	be 00 00 00 00       	mov    $0x0,%esi
80102f65:	eb ef                	jmp    80102f56 <mpconfig+0x67>
80102f67:	be 00 00 00 00       	mov    $0x0,%esi
80102f6c:	eb e8                	jmp    80102f56 <mpconfig+0x67>
    return 0;
80102f6e:	be 00 00 00 00       	mov    $0x0,%esi
80102f73:	eb e1                	jmp    80102f56 <mpconfig+0x67>
    return 0;
80102f75:	be 00 00 00 00       	mov    $0x0,%esi
80102f7a:	eb da                	jmp    80102f56 <mpconfig+0x67>
    return 0;
80102f7c:	be 00 00 00 00       	mov    $0x0,%esi
80102f81:	eb d3                	jmp    80102f56 <mpconfig+0x67>

80102f83 <mpinit>:

void
mpinit(void)
{
80102f83:	55                   	push   %ebp
80102f84:	89 e5                	mov    %esp,%ebp
80102f86:	57                   	push   %edi
80102f87:	56                   	push   %esi
80102f88:	53                   	push   %ebx
80102f89:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102f8c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102f8f:	e8 5b ff ff ff       	call   80102eef <mpconfig>
80102f94:	85 c0                	test   %eax,%eax
80102f96:	74 19                	je     80102fb1 <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102f98:	8b 50 24             	mov    0x24(%eax),%edx
80102f9b:	89 15 84 26 15 80    	mov    %edx,0x80152684
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102fa1:	8d 50 2c             	lea    0x2c(%eax),%edx
80102fa4:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102fa8:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102faa:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102faf:	eb 34                	jmp    80102fe5 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102fb1:	83 ec 0c             	sub    $0xc,%esp
80102fb4:	68 82 6d 10 80       	push   $0x80106d82
80102fb9:	e8 8a d3 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102fbe:	8b 35 20 2d 15 80    	mov    0x80152d20,%esi
80102fc4:	83 fe 07             	cmp    $0x7,%esi
80102fc7:	7f 19                	jg     80102fe2 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102fc9:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102fcd:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102fd3:	88 87 a0 27 15 80    	mov    %al,-0x7fead860(%edi)
        ncpu++;
80102fd9:	83 c6 01             	add    $0x1,%esi
80102fdc:	89 35 20 2d 15 80    	mov    %esi,0x80152d20
      }
      p += sizeof(struct mpproc);
80102fe2:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102fe5:	39 ca                	cmp    %ecx,%edx
80102fe7:	73 2b                	jae    80103014 <mpinit+0x91>
    switch(*p){
80102fe9:	0f b6 02             	movzbl (%edx),%eax
80102fec:	3c 04                	cmp    $0x4,%al
80102fee:	77 1d                	ja     8010300d <mpinit+0x8a>
80102ff0:	0f b6 c0             	movzbl %al,%eax
80102ff3:	ff 24 85 bc 6d 10 80 	jmp    *-0x7fef9244(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102ffa:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102ffe:	a2 80 27 15 80       	mov    %al,0x80152780
      p += sizeof(struct mpioapic);
80103003:	83 c2 08             	add    $0x8,%edx
      continue;
80103006:	eb dd                	jmp    80102fe5 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103008:	83 c2 08             	add    $0x8,%edx
      continue;
8010300b:	eb d8                	jmp    80102fe5 <mpinit+0x62>
    default:
      ismp = 0;
8010300d:	bb 00 00 00 00       	mov    $0x0,%ebx
80103012:	eb d1                	jmp    80102fe5 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80103014:	85 db                	test   %ebx,%ebx
80103016:	74 26                	je     8010303e <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80103018:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010301b:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
8010301f:	74 15                	je     80103036 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103021:	b8 70 00 00 00       	mov    $0x70,%eax
80103026:	ba 22 00 00 00       	mov    $0x22,%edx
8010302b:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010302c:	ba 23 00 00 00       	mov    $0x23,%edx
80103031:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103032:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103035:	ee                   	out    %al,(%dx)
  }
}
80103036:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103039:	5b                   	pop    %ebx
8010303a:	5e                   	pop    %esi
8010303b:	5f                   	pop    %edi
8010303c:	5d                   	pop    %ebp
8010303d:	c3                   	ret    
    panic("Didn't find a suitable machine");
8010303e:	83 ec 0c             	sub    $0xc,%esp
80103041:	68 9c 6d 10 80       	push   $0x80106d9c
80103046:	e8 fd d2 ff ff       	call   80100348 <panic>

8010304b <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
8010304b:	55                   	push   %ebp
8010304c:	89 e5                	mov    %esp,%ebp
8010304e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103053:	ba 21 00 00 00       	mov    $0x21,%edx
80103058:	ee                   	out    %al,(%dx)
80103059:	ba a1 00 00 00       	mov    $0xa1,%edx
8010305e:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
8010305f:	5d                   	pop    %ebp
80103060:	c3                   	ret    

80103061 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103061:	55                   	push   %ebp
80103062:	89 e5                	mov    %esp,%ebp
80103064:	57                   	push   %edi
80103065:	56                   	push   %esi
80103066:	53                   	push   %ebx
80103067:	83 ec 0c             	sub    $0xc,%esp
8010306a:	8b 5d 08             	mov    0x8(%ebp),%ebx
8010306d:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80103070:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80103076:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
8010307c:	e8 ac db ff ff       	call   80100c2d <filealloc>
80103081:	89 03                	mov    %eax,(%ebx)
80103083:	85 c0                	test   %eax,%eax
80103085:	74 1e                	je     801030a5 <pipealloc+0x44>
80103087:	e8 a1 db ff ff       	call   80100c2d <filealloc>
8010308c:	89 06                	mov    %eax,(%esi)
8010308e:	85 c0                	test   %eax,%eax
80103090:	74 13                	je     801030a5 <pipealloc+0x44>
    goto bad;
  // need to pass the pid to kalloc?
  if((p = (struct pipe*)kalloc(0)) == 0)
80103092:	83 ec 0c             	sub    $0xc,%esp
80103095:	6a 00                	push   $0x0
80103097:	e8 32 f1 ff ff       	call   801021ce <kalloc>
8010309c:	89 c7                	mov    %eax,%edi
8010309e:	83 c4 10             	add    $0x10,%esp
801030a1:	85 c0                	test   %eax,%eax
801030a3:	75 35                	jne    801030da <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
801030a5:	8b 03                	mov    (%ebx),%eax
801030a7:	85 c0                	test   %eax,%eax
801030a9:	74 0c                	je     801030b7 <pipealloc+0x56>
    fileclose(*f0);
801030ab:	83 ec 0c             	sub    $0xc,%esp
801030ae:	50                   	push   %eax
801030af:	e8 1f dc ff ff       	call   80100cd3 <fileclose>
801030b4:	83 c4 10             	add    $0x10,%esp
  if(*f1)
801030b7:	8b 06                	mov    (%esi),%eax
801030b9:	85 c0                	test   %eax,%eax
801030bb:	0f 84 8b 00 00 00    	je     8010314c <pipealloc+0xeb>
    fileclose(*f1);
801030c1:	83 ec 0c             	sub    $0xc,%esp
801030c4:	50                   	push   %eax
801030c5:	e8 09 dc ff ff       	call   80100cd3 <fileclose>
801030ca:	83 c4 10             	add    $0x10,%esp
  return -1;
801030cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801030d2:	8d 65 f4             	lea    -0xc(%ebp),%esp
801030d5:	5b                   	pop    %ebx
801030d6:	5e                   	pop    %esi
801030d7:	5f                   	pop    %edi
801030d8:	5d                   	pop    %ebp
801030d9:	c3                   	ret    
  p->readopen = 1;
801030da:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
801030e1:	00 00 00 
  p->writeopen = 1;
801030e4:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801030eb:	00 00 00 
  p->nwrite = 0;
801030ee:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801030f5:	00 00 00 
  p->nread = 0;
801030f8:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
801030ff:	00 00 00 
  initlock(&p->lock, "pipe");
80103102:	83 ec 08             	sub    $0x8,%esp
80103105:	68 d0 6d 10 80       	push   $0x80106dd0
8010310a:	50                   	push   %eax
8010310b:	e8 07 0d 00 00       	call   80103e17 <initlock>
  (*f0)->type = FD_PIPE;
80103110:	8b 03                	mov    (%ebx),%eax
80103112:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103118:	8b 03                	mov    (%ebx),%eax
8010311a:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
8010311e:	8b 03                	mov    (%ebx),%eax
80103120:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103124:	8b 03                	mov    (%ebx),%eax
80103126:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103129:	8b 06                	mov    (%esi),%eax
8010312b:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103131:	8b 06                	mov    (%esi),%eax
80103133:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103137:	8b 06                	mov    (%esi),%eax
80103139:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
8010313d:	8b 06                	mov    (%esi),%eax
8010313f:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80103142:	83 c4 10             	add    $0x10,%esp
80103145:	b8 00 00 00 00       	mov    $0x0,%eax
8010314a:	eb 86                	jmp    801030d2 <pipealloc+0x71>
  return -1;
8010314c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103151:	e9 7c ff ff ff       	jmp    801030d2 <pipealloc+0x71>

80103156 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103156:	55                   	push   %ebp
80103157:	89 e5                	mov    %esp,%ebp
80103159:	53                   	push   %ebx
8010315a:	83 ec 10             	sub    $0x10,%esp
8010315d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80103160:	53                   	push   %ebx
80103161:	e8 ed 0d 00 00       	call   80103f53 <acquire>
  if(writable){
80103166:	83 c4 10             	add    $0x10,%esp
80103169:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010316d:	74 3f                	je     801031ae <pipeclose+0x58>
    p->writeopen = 0;
8010316f:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80103176:	00 00 00 
    wakeup(&p->nread);
80103179:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010317f:	83 ec 0c             	sub    $0xc,%esp
80103182:	50                   	push   %eax
80103183:	e8 b1 09 00 00       	call   80103b39 <wakeup>
80103188:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
8010318b:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103192:	75 09                	jne    8010319d <pipeclose+0x47>
80103194:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
8010319b:	74 2f                	je     801031cc <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
8010319d:	83 ec 0c             	sub    $0xc,%esp
801031a0:	53                   	push   %ebx
801031a1:	e8 12 0e 00 00       	call   80103fb8 <release>
801031a6:	83 c4 10             	add    $0x10,%esp
}
801031a9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801031ac:	c9                   	leave  
801031ad:	c3                   	ret    
    p->readopen = 0;
801031ae:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
801031b5:	00 00 00 
    wakeup(&p->nwrite);
801031b8:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
801031be:	83 ec 0c             	sub    $0xc,%esp
801031c1:	50                   	push   %eax
801031c2:	e8 72 09 00 00       	call   80103b39 <wakeup>
801031c7:	83 c4 10             	add    $0x10,%esp
801031ca:	eb bf                	jmp    8010318b <pipeclose+0x35>
    release(&p->lock);
801031cc:	83 ec 0c             	sub    $0xc,%esp
801031cf:	53                   	push   %ebx
801031d0:	e8 e3 0d 00 00       	call   80103fb8 <release>
    kfree((char*)p);
801031d5:	89 1c 24             	mov    %ebx,(%esp)
801031d8:	e8 d1 ed ff ff       	call   80101fae <kfree>
801031dd:	83 c4 10             	add    $0x10,%esp
801031e0:	eb c7                	jmp    801031a9 <pipeclose+0x53>

801031e2 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
801031e2:	55                   	push   %ebp
801031e3:	89 e5                	mov    %esp,%ebp
801031e5:	57                   	push   %edi
801031e6:	56                   	push   %esi
801031e7:	53                   	push   %ebx
801031e8:	83 ec 18             	sub    $0x18,%esp
801031eb:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801031ee:	89 de                	mov    %ebx,%esi
801031f0:	53                   	push   %ebx
801031f1:	e8 5d 0d 00 00       	call   80103f53 <acquire>
  for(i = 0; i < n; i++){
801031f6:	83 c4 10             	add    $0x10,%esp
801031f9:	bf 00 00 00 00       	mov    $0x0,%edi
801031fe:	3b 7d 10             	cmp    0x10(%ebp),%edi
80103201:	0f 8d 88 00 00 00    	jge    8010328f <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103207:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
8010320d:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103213:	05 00 02 00 00       	add    $0x200,%eax
80103218:	39 c2                	cmp    %eax,%edx
8010321a:	75 51                	jne    8010326d <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
8010321c:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103223:	74 2f                	je     80103254 <pipewrite+0x72>
80103225:	e8 06 03 00 00       	call   80103530 <myproc>
8010322a:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010322e:	75 24                	jne    80103254 <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
80103230:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103236:	83 ec 0c             	sub    $0xc,%esp
80103239:	50                   	push   %eax
8010323a:	e8 fa 08 00 00       	call   80103b39 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
8010323f:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103245:	83 c4 08             	add    $0x8,%esp
80103248:	56                   	push   %esi
80103249:	50                   	push   %eax
8010324a:	e8 85 07 00 00       	call   801039d4 <sleep>
8010324f:	83 c4 10             	add    $0x10,%esp
80103252:	eb b3                	jmp    80103207 <pipewrite+0x25>
        release(&p->lock);
80103254:	83 ec 0c             	sub    $0xc,%esp
80103257:	53                   	push   %ebx
80103258:	e8 5b 0d 00 00       	call   80103fb8 <release>
        return -1;
8010325d:	83 c4 10             	add    $0x10,%esp
80103260:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80103265:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103268:	5b                   	pop    %ebx
80103269:	5e                   	pop    %esi
8010326a:	5f                   	pop    %edi
8010326b:	5d                   	pop    %ebp
8010326c:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
8010326d:	8d 42 01             	lea    0x1(%edx),%eax
80103270:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80103276:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
8010327c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010327f:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
80103283:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80103287:	83 c7 01             	add    $0x1,%edi
8010328a:	e9 6f ff ff ff       	jmp    801031fe <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
8010328f:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103295:	83 ec 0c             	sub    $0xc,%esp
80103298:	50                   	push   %eax
80103299:	e8 9b 08 00 00       	call   80103b39 <wakeup>
  release(&p->lock);
8010329e:	89 1c 24             	mov    %ebx,(%esp)
801032a1:	e8 12 0d 00 00       	call   80103fb8 <release>
  return n;
801032a6:	83 c4 10             	add    $0x10,%esp
801032a9:	8b 45 10             	mov    0x10(%ebp),%eax
801032ac:	eb b7                	jmp    80103265 <pipewrite+0x83>

801032ae <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801032ae:	55                   	push   %ebp
801032af:	89 e5                	mov    %esp,%ebp
801032b1:	57                   	push   %edi
801032b2:	56                   	push   %esi
801032b3:	53                   	push   %ebx
801032b4:	83 ec 18             	sub    $0x18,%esp
801032b7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801032ba:	89 df                	mov    %ebx,%edi
801032bc:	53                   	push   %ebx
801032bd:	e8 91 0c 00 00       	call   80103f53 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801032c2:	83 c4 10             	add    $0x10,%esp
801032c5:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
801032cb:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
801032d1:	75 3d                	jne    80103310 <piperead+0x62>
801032d3:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
801032d9:	85 f6                	test   %esi,%esi
801032db:	74 38                	je     80103315 <piperead+0x67>
    if(myproc()->killed){
801032dd:	e8 4e 02 00 00       	call   80103530 <myproc>
801032e2:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801032e6:	75 15                	jne    801032fd <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801032e8:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801032ee:	83 ec 08             	sub    $0x8,%esp
801032f1:	57                   	push   %edi
801032f2:	50                   	push   %eax
801032f3:	e8 dc 06 00 00       	call   801039d4 <sleep>
801032f8:	83 c4 10             	add    $0x10,%esp
801032fb:	eb c8                	jmp    801032c5 <piperead+0x17>
      release(&p->lock);
801032fd:	83 ec 0c             	sub    $0xc,%esp
80103300:	53                   	push   %ebx
80103301:	e8 b2 0c 00 00       	call   80103fb8 <release>
      return -1;
80103306:	83 c4 10             	add    $0x10,%esp
80103309:	be ff ff ff ff       	mov    $0xffffffff,%esi
8010330e:	eb 50                	jmp    80103360 <piperead+0xb2>
80103310:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103315:	3b 75 10             	cmp    0x10(%ebp),%esi
80103318:	7d 2c                	jge    80103346 <piperead+0x98>
    if(p->nread == p->nwrite)
8010331a:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103320:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
80103326:	74 1e                	je     80103346 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80103328:	8d 50 01             	lea    0x1(%eax),%edx
8010332b:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80103331:	25 ff 01 00 00       	and    $0x1ff,%eax
80103336:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
8010333b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010333e:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103341:	83 c6 01             	add    $0x1,%esi
80103344:	eb cf                	jmp    80103315 <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103346:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010334c:	83 ec 0c             	sub    $0xc,%esp
8010334f:	50                   	push   %eax
80103350:	e8 e4 07 00 00       	call   80103b39 <wakeup>
  release(&p->lock);
80103355:	89 1c 24             	mov    %ebx,(%esp)
80103358:	e8 5b 0c 00 00       	call   80103fb8 <release>
  return i;
8010335d:	83 c4 10             	add    $0x10,%esp
}
80103360:	89 f0                	mov    %esi,%eax
80103362:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103365:	5b                   	pop    %ebx
80103366:	5e                   	pop    %esi
80103367:	5f                   	pop    %edi
80103368:	5d                   	pop    %ebp
80103369:	c3                   	ret    

8010336a <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
8010336a:	55                   	push   %ebp
8010336b:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010336d:	ba 74 2d 15 80       	mov    $0x80152d74,%edx
80103372:	eb 03                	jmp    80103377 <wakeup1+0xd>
80103374:	83 c2 7c             	add    $0x7c,%edx
80103377:	81 fa 74 4c 15 80    	cmp    $0x80154c74,%edx
8010337d:	73 14                	jae    80103393 <wakeup1+0x29>
    if (p->state == SLEEPING && p->chan == chan)
8010337f:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
80103383:	75 ef                	jne    80103374 <wakeup1+0xa>
80103385:	39 42 20             	cmp    %eax,0x20(%edx)
80103388:	75 ea                	jne    80103374 <wakeup1+0xa>
      p->state = RUNNABLE;
8010338a:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
80103391:	eb e1                	jmp    80103374 <wakeup1+0xa>
}
80103393:	5d                   	pop    %ebp
80103394:	c3                   	ret    

80103395 <allocproc>:
{
80103395:	55                   	push   %ebp
80103396:	89 e5                	mov    %esp,%ebp
80103398:	53                   	push   %ebx
80103399:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
8010339c:	68 40 2d 15 80       	push   $0x80152d40
801033a1:	e8 ad 0b 00 00       	call   80103f53 <acquire>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801033a6:	83 c4 10             	add    $0x10,%esp
801033a9:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
801033ae:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
801033b4:	73 0b                	jae    801033c1 <allocproc+0x2c>
    if (p->state == UNUSED)
801033b6:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
801033ba:	74 1c                	je     801033d8 <allocproc+0x43>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801033bc:	83 c3 7c             	add    $0x7c,%ebx
801033bf:	eb ed                	jmp    801033ae <allocproc+0x19>
  release(&ptable.lock);
801033c1:	83 ec 0c             	sub    $0xc,%esp
801033c4:	68 40 2d 15 80       	push   $0x80152d40
801033c9:	e8 ea 0b 00 00       	call   80103fb8 <release>
  return 0;
801033ce:	83 c4 10             	add    $0x10,%esp
801033d1:	bb 00 00 00 00       	mov    $0x0,%ebx
801033d6:	eb 6f                	jmp    80103447 <allocproc+0xb2>
  p->state = EMBRYO;
801033d8:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
801033df:	a1 04 a0 10 80       	mov    0x8010a004,%eax
801033e4:	8d 50 01             	lea    0x1(%eax),%edx
801033e7:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
801033ed:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
801033f0:	83 ec 0c             	sub    $0xc,%esp
801033f3:	68 40 2d 15 80       	push   $0x80152d40
801033f8:	e8 bb 0b 00 00       	call   80103fb8 <release>
  if ((p->kstack = kalloc(p->pid)) == 0)
801033fd:	83 c4 04             	add    $0x4,%esp
80103400:	ff 73 10             	pushl  0x10(%ebx)
80103403:	e8 c6 ed ff ff       	call   801021ce <kalloc>
80103408:	89 43 08             	mov    %eax,0x8(%ebx)
8010340b:	83 c4 10             	add    $0x10,%esp
8010340e:	85 c0                	test   %eax,%eax
80103410:	74 3c                	je     8010344e <allocproc+0xb9>
  sp -= sizeof *p->tf;
80103412:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe *)sp;
80103418:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint *)sp = (uint)trapret;
8010341b:	c7 80 b0 0f 00 00 15 	movl   $0x80105115,0xfb0(%eax)
80103422:	51 10 80 
  sp -= sizeof *p->context;
80103425:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context *)sp;
8010342a:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
8010342d:	83 ec 04             	sub    $0x4,%esp
80103430:	6a 14                	push   $0x14
80103432:	6a 00                	push   $0x0
80103434:	50                   	push   %eax
80103435:	e8 c5 0b 00 00       	call   80103fff <memset>
  p->context->eip = (uint)forkret;
8010343a:	8b 43 1c             	mov    0x1c(%ebx),%eax
8010343d:	c7 40 10 5c 34 10 80 	movl   $0x8010345c,0x10(%eax)
  return p;
80103444:	83 c4 10             	add    $0x10,%esp
}
80103447:	89 d8                	mov    %ebx,%eax
80103449:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010344c:	c9                   	leave  
8010344d:	c3                   	ret    
    p->state = UNUSED;
8010344e:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
80103455:	bb 00 00 00 00       	mov    $0x0,%ebx
8010345a:	eb eb                	jmp    80103447 <allocproc+0xb2>

8010345c <forkret>:
{
8010345c:	55                   	push   %ebp
8010345d:	89 e5                	mov    %esp,%ebp
8010345f:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
80103462:	68 40 2d 15 80       	push   $0x80152d40
80103467:	e8 4c 0b 00 00       	call   80103fb8 <release>
  if (first)
8010346c:	83 c4 10             	add    $0x10,%esp
8010346f:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
80103476:	75 02                	jne    8010347a <forkret+0x1e>
}
80103478:	c9                   	leave  
80103479:	c3                   	ret    
    first = 0;
8010347a:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
80103481:	00 00 00 
    iinit(ROOTDEV);
80103484:	83 ec 0c             	sub    $0xc,%esp
80103487:	6a 01                	push   $0x1
80103489:	e8 5e de ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
8010348e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103495:	e8 ec f5 ff ff       	call   80102a86 <initlog>
8010349a:	83 c4 10             	add    $0x10,%esp
}
8010349d:	eb d9                	jmp    80103478 <forkret+0x1c>

8010349f <pinit>:
{
8010349f:	55                   	push   %ebp
801034a0:	89 e5                	mov    %esp,%ebp
801034a2:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801034a5:	68 d5 6d 10 80       	push   $0x80106dd5
801034aa:	68 40 2d 15 80       	push   $0x80152d40
801034af:	e8 63 09 00 00       	call   80103e17 <initlock>
}
801034b4:	83 c4 10             	add    $0x10,%esp
801034b7:	c9                   	leave  
801034b8:	c3                   	ret    

801034b9 <mycpu>:
{
801034b9:	55                   	push   %ebp
801034ba:	89 e5                	mov    %esp,%ebp
801034bc:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801034bf:	9c                   	pushf  
801034c0:	58                   	pop    %eax
  if (readeflags() & FL_IF)
801034c1:	f6 c4 02             	test   $0x2,%ah
801034c4:	75 28                	jne    801034ee <mycpu+0x35>
  apicid = lapicid();
801034c6:	e8 d4 f1 ff ff       	call   8010269f <lapicid>
  for (i = 0; i < ncpu; ++i)
801034cb:	ba 00 00 00 00       	mov    $0x0,%edx
801034d0:	39 15 20 2d 15 80    	cmp    %edx,0x80152d20
801034d6:	7e 23                	jle    801034fb <mycpu+0x42>
    if (cpus[i].apicid == apicid)
801034d8:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801034de:	0f b6 89 a0 27 15 80 	movzbl -0x7fead860(%ecx),%ecx
801034e5:	39 c1                	cmp    %eax,%ecx
801034e7:	74 1f                	je     80103508 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i)
801034e9:	83 c2 01             	add    $0x1,%edx
801034ec:	eb e2                	jmp    801034d0 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
801034ee:	83 ec 0c             	sub    $0xc,%esp
801034f1:	68 b8 6e 10 80       	push   $0x80106eb8
801034f6:	e8 4d ce ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
801034fb:	83 ec 0c             	sub    $0xc,%esp
801034fe:	68 dc 6d 10 80       	push   $0x80106ddc
80103503:	e8 40 ce ff ff       	call   80100348 <panic>
      return &cpus[i];
80103508:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
8010350e:	05 a0 27 15 80       	add    $0x801527a0,%eax
}
80103513:	c9                   	leave  
80103514:	c3                   	ret    

80103515 <cpuid>:
{
80103515:	55                   	push   %ebp
80103516:	89 e5                	mov    %esp,%ebp
80103518:	83 ec 08             	sub    $0x8,%esp
  return mycpu() - cpus;
8010351b:	e8 99 ff ff ff       	call   801034b9 <mycpu>
80103520:	2d a0 27 15 80       	sub    $0x801527a0,%eax
80103525:	c1 f8 04             	sar    $0x4,%eax
80103528:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
8010352e:	c9                   	leave  
8010352f:	c3                   	ret    

80103530 <myproc>:
{
80103530:	55                   	push   %ebp
80103531:	89 e5                	mov    %esp,%ebp
80103533:	53                   	push   %ebx
80103534:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103537:	e8 3a 09 00 00       	call   80103e76 <pushcli>
  c = mycpu();
8010353c:	e8 78 ff ff ff       	call   801034b9 <mycpu>
  p = c->proc;
80103541:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103547:	e8 67 09 00 00       	call   80103eb3 <popcli>
}
8010354c:	89 d8                	mov    %ebx,%eax
8010354e:	83 c4 04             	add    $0x4,%esp
80103551:	5b                   	pop    %ebx
80103552:	5d                   	pop    %ebp
80103553:	c3                   	ret    

80103554 <userinit>:
{
80103554:	55                   	push   %ebp
80103555:	89 e5                	mov    %esp,%ebp
80103557:	53                   	push   %ebx
80103558:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
8010355b:	e8 35 fe ff ff       	call   80103395 <allocproc>
80103560:	89 c3                	mov    %eax,%ebx
  initproc = p;
80103562:	a3 b8 a5 10 80       	mov    %eax,0x8010a5b8
  if ((p->pgdir = setupkvm()) == 0)
80103567:	e8 a6 30 00 00       	call   80106612 <setupkvm>
8010356c:	89 43 04             	mov    %eax,0x4(%ebx)
8010356f:	85 c0                	test   %eax,%eax
80103571:	0f 84 b7 00 00 00    	je     8010362e <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103577:	83 ec 04             	sub    $0x4,%esp
8010357a:	68 2c 00 00 00       	push   $0x2c
8010357f:	68 60 a4 10 80       	push   $0x8010a460
80103584:	50                   	push   %eax
80103585:	e8 7a 2d 00 00       	call   80106304 <inituvm>
  p->sz = PGSIZE;
8010358a:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
80103590:	83 c4 0c             	add    $0xc,%esp
80103593:	6a 4c                	push   $0x4c
80103595:	6a 00                	push   $0x0
80103597:	ff 73 18             	pushl  0x18(%ebx)
8010359a:	e8 60 0a 00 00       	call   80103fff <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010359f:	8b 43 18             	mov    0x18(%ebx),%eax
801035a2:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801035a8:	8b 43 18             	mov    0x18(%ebx),%eax
801035ab:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801035b1:	8b 43 18             	mov    0x18(%ebx),%eax
801035b4:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801035b8:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801035bc:	8b 43 18             	mov    0x18(%ebx),%eax
801035bf:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801035c3:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801035c7:	8b 43 18             	mov    0x18(%ebx),%eax
801035ca:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801035d1:	8b 43 18             	mov    0x18(%ebx),%eax
801035d4:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0; // beginning of initcode.S
801035db:	8b 43 18             	mov    0x18(%ebx),%eax
801035de:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
801035e5:	8d 43 6c             	lea    0x6c(%ebx),%eax
801035e8:	83 c4 0c             	add    $0xc,%esp
801035eb:	6a 10                	push   $0x10
801035ed:	68 05 6e 10 80       	push   $0x80106e05
801035f2:	50                   	push   %eax
801035f3:	e8 6e 0b 00 00       	call   80104166 <safestrcpy>
  p->cwd = namei("/");
801035f8:	c7 04 24 0e 6e 10 80 	movl   $0x80106e0e,(%esp)
801035ff:	e8 dd e5 ff ff       	call   80101be1 <namei>
80103604:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
80103607:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
8010360e:	e8 40 09 00 00       	call   80103f53 <acquire>
  p->state = RUNNABLE;
80103613:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
8010361a:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
80103621:	e8 92 09 00 00       	call   80103fb8 <release>
}
80103626:	83 c4 10             	add    $0x10,%esp
80103629:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010362c:	c9                   	leave  
8010362d:	c3                   	ret    
    panic("userinit: out of memory?");
8010362e:	83 ec 0c             	sub    $0xc,%esp
80103631:	68 ec 6d 10 80       	push   $0x80106dec
80103636:	e8 0d cd ff ff       	call   80100348 <panic>

8010363b <growproc>:
{
8010363b:	55                   	push   %ebp
8010363c:	89 e5                	mov    %esp,%ebp
8010363e:	56                   	push   %esi
8010363f:	53                   	push   %ebx
80103640:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
80103643:	e8 e8 fe ff ff       	call   80103530 <myproc>
80103648:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
8010364a:	8b 00                	mov    (%eax),%eax
  if (n > 0)
8010364c:	85 f6                	test   %esi,%esi
8010364e:	7f 21                	jg     80103671 <growproc+0x36>
  else if (n < 0)
80103650:	85 f6                	test   %esi,%esi
80103652:	79 33                	jns    80103687 <growproc+0x4c>
    if ((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103654:	83 ec 04             	sub    $0x4,%esp
80103657:	01 c6                	add    %eax,%esi
80103659:	56                   	push   %esi
8010365a:	50                   	push   %eax
8010365b:	ff 73 04             	pushl  0x4(%ebx)
8010365e:	e8 aa 2d 00 00       	call   8010640d <deallocuvm>
80103663:	83 c4 10             	add    $0x10,%esp
80103666:	85 c0                	test   %eax,%eax
80103668:	75 1d                	jne    80103687 <growproc+0x4c>
      return -1;
8010366a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010366f:	eb 29                	jmp    8010369a <growproc+0x5f>
    if ((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103671:	83 ec 04             	sub    $0x4,%esp
80103674:	01 c6                	add    %eax,%esi
80103676:	56                   	push   %esi
80103677:	50                   	push   %eax
80103678:	ff 73 04             	pushl  0x4(%ebx)
8010367b:	e8 1f 2e 00 00       	call   8010649f <allocuvm>
80103680:	83 c4 10             	add    $0x10,%esp
80103683:	85 c0                	test   %eax,%eax
80103685:	74 1a                	je     801036a1 <growproc+0x66>
  curproc->sz = sz;
80103687:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
80103689:	83 ec 0c             	sub    $0xc,%esp
8010368c:	53                   	push   %ebx
8010368d:	e8 5a 2b 00 00       	call   801061ec <switchuvm>
  return 0;
80103692:	83 c4 10             	add    $0x10,%esp
80103695:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010369a:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010369d:	5b                   	pop    %ebx
8010369e:	5e                   	pop    %esi
8010369f:	5d                   	pop    %ebp
801036a0:	c3                   	ret    
      return -1;
801036a1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801036a6:	eb f2                	jmp    8010369a <growproc+0x5f>

801036a8 <fork>:
{
801036a8:	55                   	push   %ebp
801036a9:	89 e5                	mov    %esp,%ebp
801036ab:	57                   	push   %edi
801036ac:	56                   	push   %esi
801036ad:	53                   	push   %ebx
801036ae:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801036b1:	e8 7a fe ff ff       	call   80103530 <myproc>
801036b6:	89 c3                	mov    %eax,%ebx
  if ((np = allocproc()) == 0)
801036b8:	e8 d8 fc ff ff       	call   80103395 <allocproc>
801036bd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801036c0:	85 c0                	test   %eax,%eax
801036c2:	0f 84 e0 00 00 00    	je     801037a8 <fork+0x100>
801036c8:	89 c7                	mov    %eax,%edi
  if ((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0)
801036ca:	83 ec 08             	sub    $0x8,%esp
801036cd:	ff 33                	pushl  (%ebx)
801036cf:	ff 73 04             	pushl  0x4(%ebx)
801036d2:	e8 ec 2f 00 00       	call   801066c3 <copyuvm>
801036d7:	89 47 04             	mov    %eax,0x4(%edi)
801036da:	83 c4 10             	add    $0x10,%esp
801036dd:	85 c0                	test   %eax,%eax
801036df:	74 2a                	je     8010370b <fork+0x63>
  np->sz = curproc->sz;
801036e1:	8b 03                	mov    (%ebx),%eax
801036e3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801036e6:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
801036e8:	89 c8                	mov    %ecx,%eax
801036ea:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
801036ed:	8b 73 18             	mov    0x18(%ebx),%esi
801036f0:	8b 79 18             	mov    0x18(%ecx),%edi
801036f3:	b9 13 00 00 00       	mov    $0x13,%ecx
801036f8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
801036fa:	8b 40 18             	mov    0x18(%eax),%eax
801036fd:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for (i = 0; i < NOFILE; i++)
80103704:	be 00 00 00 00       	mov    $0x0,%esi
80103709:	eb 29                	jmp    80103734 <fork+0x8c>
    kfree(np->kstack);
8010370b:	83 ec 0c             	sub    $0xc,%esp
8010370e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80103711:	ff 73 08             	pushl  0x8(%ebx)
80103714:	e8 95 e8 ff ff       	call   80101fae <kfree>
    np->kstack = 0;
80103719:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
80103720:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103727:	83 c4 10             	add    $0x10,%esp
8010372a:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010372f:	eb 6d                	jmp    8010379e <fork+0xf6>
  for (i = 0; i < NOFILE; i++)
80103731:	83 c6 01             	add    $0x1,%esi
80103734:	83 fe 0f             	cmp    $0xf,%esi
80103737:	7f 1d                	jg     80103756 <fork+0xae>
    if (curproc->ofile[i])
80103739:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
8010373d:	85 c0                	test   %eax,%eax
8010373f:	74 f0                	je     80103731 <fork+0x89>
      np->ofile[i] = filedup(curproc->ofile[i]);
80103741:	83 ec 0c             	sub    $0xc,%esp
80103744:	50                   	push   %eax
80103745:	e8 44 d5 ff ff       	call   80100c8e <filedup>
8010374a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010374d:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
80103751:	83 c4 10             	add    $0x10,%esp
80103754:	eb db                	jmp    80103731 <fork+0x89>
  np->cwd = idup(curproc->cwd);
80103756:	83 ec 0c             	sub    $0xc,%esp
80103759:	ff 73 68             	pushl  0x68(%ebx)
8010375c:	e8 f0 dd ff ff       	call   80101551 <idup>
80103761:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103764:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103767:	83 c3 6c             	add    $0x6c,%ebx
8010376a:	8d 47 6c             	lea    0x6c(%edi),%eax
8010376d:	83 c4 0c             	add    $0xc,%esp
80103770:	6a 10                	push   $0x10
80103772:	53                   	push   %ebx
80103773:	50                   	push   %eax
80103774:	e8 ed 09 00 00       	call   80104166 <safestrcpy>
  pid = np->pid;
80103779:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
8010377c:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
80103783:	e8 cb 07 00 00       	call   80103f53 <acquire>
  np->state = RUNNABLE;
80103788:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
8010378f:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
80103796:	e8 1d 08 00 00       	call   80103fb8 <release>
  return pid;
8010379b:	83 c4 10             	add    $0x10,%esp
}
8010379e:	89 d8                	mov    %ebx,%eax
801037a0:	8d 65 f4             	lea    -0xc(%ebp),%esp
801037a3:	5b                   	pop    %ebx
801037a4:	5e                   	pop    %esi
801037a5:	5f                   	pop    %edi
801037a6:	5d                   	pop    %ebp
801037a7:	c3                   	ret    
    return -1;
801037a8:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801037ad:	eb ef                	jmp    8010379e <fork+0xf6>

801037af <scheduler>:
{
801037af:	55                   	push   %ebp
801037b0:	89 e5                	mov    %esp,%ebp
801037b2:	56                   	push   %esi
801037b3:	53                   	push   %ebx
  struct cpu *c = mycpu();
801037b4:	e8 00 fd ff ff       	call   801034b9 <mycpu>
801037b9:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801037bb:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801037c2:	00 00 00 
801037c5:	eb 5a                	jmp    80103821 <scheduler+0x72>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801037c7:	83 c3 7c             	add    $0x7c,%ebx
801037ca:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
801037d0:	73 3f                	jae    80103811 <scheduler+0x62>
      if (p->state != RUNNABLE)
801037d2:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
801037d6:	75 ef                	jne    801037c7 <scheduler+0x18>
      c->proc = p;
801037d8:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801037de:	83 ec 0c             	sub    $0xc,%esp
801037e1:	53                   	push   %ebx
801037e2:	e8 05 2a 00 00       	call   801061ec <switchuvm>
      p->state = RUNNING;
801037e7:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
801037ee:	83 c4 08             	add    $0x8,%esp
801037f1:	ff 73 1c             	pushl  0x1c(%ebx)
801037f4:	8d 46 04             	lea    0x4(%esi),%eax
801037f7:	50                   	push   %eax
801037f8:	e8 bc 09 00 00       	call   801041b9 <swtch>
      switchkvm();
801037fd:	e8 d8 29 00 00       	call   801061da <switchkvm>
      c->proc = 0;
80103802:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
80103809:	00 00 00 
8010380c:	83 c4 10             	add    $0x10,%esp
8010380f:	eb b6                	jmp    801037c7 <scheduler+0x18>
    release(&ptable.lock);
80103811:	83 ec 0c             	sub    $0xc,%esp
80103814:	68 40 2d 15 80       	push   $0x80152d40
80103819:	e8 9a 07 00 00       	call   80103fb8 <release>
    sti();
8010381e:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
80103821:	fb                   	sti    
    acquire(&ptable.lock);
80103822:	83 ec 0c             	sub    $0xc,%esp
80103825:	68 40 2d 15 80       	push   $0x80152d40
8010382a:	e8 24 07 00 00       	call   80103f53 <acquire>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010382f:	83 c4 10             	add    $0x10,%esp
80103832:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
80103837:	eb 91                	jmp    801037ca <scheduler+0x1b>

80103839 <sched>:
{
80103839:	55                   	push   %ebp
8010383a:	89 e5                	mov    %esp,%ebp
8010383c:	56                   	push   %esi
8010383d:	53                   	push   %ebx
  struct proc *p = myproc();
8010383e:	e8 ed fc ff ff       	call   80103530 <myproc>
80103843:	89 c3                	mov    %eax,%ebx
  if (!holding(&ptable.lock))
80103845:	83 ec 0c             	sub    $0xc,%esp
80103848:	68 40 2d 15 80       	push   $0x80152d40
8010384d:	e8 c1 06 00 00       	call   80103f13 <holding>
80103852:	83 c4 10             	add    $0x10,%esp
80103855:	85 c0                	test   %eax,%eax
80103857:	74 4f                	je     801038a8 <sched+0x6f>
  if (mycpu()->ncli != 1)
80103859:	e8 5b fc ff ff       	call   801034b9 <mycpu>
8010385e:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
80103865:	75 4e                	jne    801038b5 <sched+0x7c>
  if (p->state == RUNNING)
80103867:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
8010386b:	74 55                	je     801038c2 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010386d:	9c                   	pushf  
8010386e:	58                   	pop    %eax
  if (readeflags() & FL_IF)
8010386f:	f6 c4 02             	test   $0x2,%ah
80103872:	75 5b                	jne    801038cf <sched+0x96>
  intena = mycpu()->intena;
80103874:	e8 40 fc ff ff       	call   801034b9 <mycpu>
80103879:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
8010387f:	e8 35 fc ff ff       	call   801034b9 <mycpu>
80103884:	83 ec 08             	sub    $0x8,%esp
80103887:	ff 70 04             	pushl  0x4(%eax)
8010388a:	83 c3 1c             	add    $0x1c,%ebx
8010388d:	53                   	push   %ebx
8010388e:	e8 26 09 00 00       	call   801041b9 <swtch>
  mycpu()->intena = intena;
80103893:	e8 21 fc ff ff       	call   801034b9 <mycpu>
80103898:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
8010389e:	83 c4 10             	add    $0x10,%esp
801038a1:	8d 65 f8             	lea    -0x8(%ebp),%esp
801038a4:	5b                   	pop    %ebx
801038a5:	5e                   	pop    %esi
801038a6:	5d                   	pop    %ebp
801038a7:	c3                   	ret    
    panic("sched ptable.lock");
801038a8:	83 ec 0c             	sub    $0xc,%esp
801038ab:	68 10 6e 10 80       	push   $0x80106e10
801038b0:	e8 93 ca ff ff       	call   80100348 <panic>
    panic("sched locks");
801038b5:	83 ec 0c             	sub    $0xc,%esp
801038b8:	68 22 6e 10 80       	push   $0x80106e22
801038bd:	e8 86 ca ff ff       	call   80100348 <panic>
    panic("sched running");
801038c2:	83 ec 0c             	sub    $0xc,%esp
801038c5:	68 2e 6e 10 80       	push   $0x80106e2e
801038ca:	e8 79 ca ff ff       	call   80100348 <panic>
    panic("sched interruptible");
801038cf:	83 ec 0c             	sub    $0xc,%esp
801038d2:	68 3c 6e 10 80       	push   $0x80106e3c
801038d7:	e8 6c ca ff ff       	call   80100348 <panic>

801038dc <exit>:
{
801038dc:	55                   	push   %ebp
801038dd:	89 e5                	mov    %esp,%ebp
801038df:	56                   	push   %esi
801038e0:	53                   	push   %ebx
  struct proc *curproc = myproc();
801038e1:	e8 4a fc ff ff       	call   80103530 <myproc>
  if (curproc == initproc)
801038e6:	39 05 b8 a5 10 80    	cmp    %eax,0x8010a5b8
801038ec:	74 09                	je     801038f7 <exit+0x1b>
801038ee:	89 c6                	mov    %eax,%esi
  for (fd = 0; fd < NOFILE; fd++)
801038f0:	bb 00 00 00 00       	mov    $0x0,%ebx
801038f5:	eb 10                	jmp    80103907 <exit+0x2b>
    panic("init exiting");
801038f7:	83 ec 0c             	sub    $0xc,%esp
801038fa:	68 50 6e 10 80       	push   $0x80106e50
801038ff:	e8 44 ca ff ff       	call   80100348 <panic>
  for (fd = 0; fd < NOFILE; fd++)
80103904:	83 c3 01             	add    $0x1,%ebx
80103907:	83 fb 0f             	cmp    $0xf,%ebx
8010390a:	7f 1e                	jg     8010392a <exit+0x4e>
    if (curproc->ofile[fd])
8010390c:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
80103910:	85 c0                	test   %eax,%eax
80103912:	74 f0                	je     80103904 <exit+0x28>
      fileclose(curproc->ofile[fd]);
80103914:	83 ec 0c             	sub    $0xc,%esp
80103917:	50                   	push   %eax
80103918:	e8 b6 d3 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
8010391d:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103924:	00 
80103925:	83 c4 10             	add    $0x10,%esp
80103928:	eb da                	jmp    80103904 <exit+0x28>
  begin_op();
8010392a:	e8 a0 f1 ff ff       	call   80102acf <begin_op>
  iput(curproc->cwd);
8010392f:	83 ec 0c             	sub    $0xc,%esp
80103932:	ff 76 68             	pushl  0x68(%esi)
80103935:	e8 4e dd ff ff       	call   80101688 <iput>
  end_op();
8010393a:	e8 0a f2 ff ff       	call   80102b49 <end_op>
  curproc->cwd = 0;
8010393f:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103946:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
8010394d:	e8 01 06 00 00       	call   80103f53 <acquire>
  wakeup1(curproc->parent);
80103952:	8b 46 14             	mov    0x14(%esi),%eax
80103955:	e8 10 fa ff ff       	call   8010336a <wakeup1>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010395a:	83 c4 10             	add    $0x10,%esp
8010395d:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
80103962:	eb 03                	jmp    80103967 <exit+0x8b>
80103964:	83 c3 7c             	add    $0x7c,%ebx
80103967:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
8010396d:	73 1a                	jae    80103989 <exit+0xad>
    if (p->parent == curproc)
8010396f:	39 73 14             	cmp    %esi,0x14(%ebx)
80103972:	75 f0                	jne    80103964 <exit+0x88>
      p->parent = initproc;
80103974:	a1 b8 a5 10 80       	mov    0x8010a5b8,%eax
80103979:	89 43 14             	mov    %eax,0x14(%ebx)
      if (p->state == ZOMBIE)
8010397c:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103980:	75 e2                	jne    80103964 <exit+0x88>
        wakeup1(initproc);
80103982:	e8 e3 f9 ff ff       	call   8010336a <wakeup1>
80103987:	eb db                	jmp    80103964 <exit+0x88>
  curproc->state = ZOMBIE;
80103989:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
80103990:	e8 a4 fe ff ff       	call   80103839 <sched>
  panic("zombie exit");
80103995:	83 ec 0c             	sub    $0xc,%esp
80103998:	68 5d 6e 10 80       	push   $0x80106e5d
8010399d:	e8 a6 c9 ff ff       	call   80100348 <panic>

801039a2 <yield>:
{
801039a2:	55                   	push   %ebp
801039a3:	89 e5                	mov    %esp,%ebp
801039a5:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock); //DOC: yieldlock
801039a8:	68 40 2d 15 80       	push   $0x80152d40
801039ad:	e8 a1 05 00 00       	call   80103f53 <acquire>
  myproc()->state = RUNNABLE;
801039b2:	e8 79 fb ff ff       	call   80103530 <myproc>
801039b7:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801039be:	e8 76 fe ff ff       	call   80103839 <sched>
  release(&ptable.lock);
801039c3:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
801039ca:	e8 e9 05 00 00       	call   80103fb8 <release>
}
801039cf:	83 c4 10             	add    $0x10,%esp
801039d2:	c9                   	leave  
801039d3:	c3                   	ret    

801039d4 <sleep>:
{
801039d4:	55                   	push   %ebp
801039d5:	89 e5                	mov    %esp,%ebp
801039d7:	56                   	push   %esi
801039d8:	53                   	push   %ebx
801039d9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
801039dc:	e8 4f fb ff ff       	call   80103530 <myproc>
  if (p == 0)
801039e1:	85 c0                	test   %eax,%eax
801039e3:	74 66                	je     80103a4b <sleep+0x77>
801039e5:	89 c6                	mov    %eax,%esi
  if (lk == 0)
801039e7:	85 db                	test   %ebx,%ebx
801039e9:	74 6d                	je     80103a58 <sleep+0x84>
  if (lk != &ptable.lock)
801039eb:	81 fb 40 2d 15 80    	cmp    $0x80152d40,%ebx
801039f1:	74 18                	je     80103a0b <sleep+0x37>
    acquire(&ptable.lock); //DOC: sleeplock1
801039f3:	83 ec 0c             	sub    $0xc,%esp
801039f6:	68 40 2d 15 80       	push   $0x80152d40
801039fb:	e8 53 05 00 00       	call   80103f53 <acquire>
    release(lk);
80103a00:	89 1c 24             	mov    %ebx,(%esp)
80103a03:	e8 b0 05 00 00       	call   80103fb8 <release>
80103a08:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103a0b:	8b 45 08             	mov    0x8(%ebp),%eax
80103a0e:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
80103a11:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
80103a18:	e8 1c fe ff ff       	call   80103839 <sched>
  p->chan = 0;
80103a1d:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if (lk != &ptable.lock)
80103a24:	81 fb 40 2d 15 80    	cmp    $0x80152d40,%ebx
80103a2a:	74 18                	je     80103a44 <sleep+0x70>
    release(&ptable.lock);
80103a2c:	83 ec 0c             	sub    $0xc,%esp
80103a2f:	68 40 2d 15 80       	push   $0x80152d40
80103a34:	e8 7f 05 00 00       	call   80103fb8 <release>
    acquire(lk);
80103a39:	89 1c 24             	mov    %ebx,(%esp)
80103a3c:	e8 12 05 00 00       	call   80103f53 <acquire>
80103a41:	83 c4 10             	add    $0x10,%esp
}
80103a44:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a47:	5b                   	pop    %ebx
80103a48:	5e                   	pop    %esi
80103a49:	5d                   	pop    %ebp
80103a4a:	c3                   	ret    
    panic("sleep");
80103a4b:	83 ec 0c             	sub    $0xc,%esp
80103a4e:	68 69 6e 10 80       	push   $0x80106e69
80103a53:	e8 f0 c8 ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103a58:	83 ec 0c             	sub    $0xc,%esp
80103a5b:	68 6f 6e 10 80       	push   $0x80106e6f
80103a60:	e8 e3 c8 ff ff       	call   80100348 <panic>

80103a65 <wait>:
{
80103a65:	55                   	push   %ebp
80103a66:	89 e5                	mov    %esp,%ebp
80103a68:	56                   	push   %esi
80103a69:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103a6a:	e8 c1 fa ff ff       	call   80103530 <myproc>
80103a6f:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
80103a71:	83 ec 0c             	sub    $0xc,%esp
80103a74:	68 40 2d 15 80       	push   $0x80152d40
80103a79:	e8 d5 04 00 00       	call   80103f53 <acquire>
80103a7e:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
80103a81:	b8 00 00 00 00       	mov    $0x0,%eax
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103a86:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
80103a8b:	eb 5b                	jmp    80103ae8 <wait+0x83>
        pid = p->pid;
80103a8d:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
80103a90:	83 ec 0c             	sub    $0xc,%esp
80103a93:	ff 73 08             	pushl  0x8(%ebx)
80103a96:	e8 13 e5 ff ff       	call   80101fae <kfree>
        p->kstack = 0;
80103a9b:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
80103aa2:	83 c4 04             	add    $0x4,%esp
80103aa5:	ff 73 04             	pushl  0x4(%ebx)
80103aa8:	e8 f5 2a 00 00       	call   801065a2 <freevm>
        p->pid = 0;
80103aad:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103ab4:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103abb:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
80103abf:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
80103ac6:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
80103acd:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
80103ad4:	e8 df 04 00 00       	call   80103fb8 <release>
        return pid;
80103ad9:	83 c4 10             	add    $0x10,%esp
}
80103adc:	89 f0                	mov    %esi,%eax
80103ade:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ae1:	5b                   	pop    %ebx
80103ae2:	5e                   	pop    %esi
80103ae3:	5d                   	pop    %ebp
80103ae4:	c3                   	ret    
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103ae5:	83 c3 7c             	add    $0x7c,%ebx
80103ae8:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
80103aee:	73 12                	jae    80103b02 <wait+0x9d>
      if (p->parent != curproc)
80103af0:	39 73 14             	cmp    %esi,0x14(%ebx)
80103af3:	75 f0                	jne    80103ae5 <wait+0x80>
      if (p->state == ZOMBIE)
80103af5:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103af9:	74 92                	je     80103a8d <wait+0x28>
      havekids = 1;
80103afb:	b8 01 00 00 00       	mov    $0x1,%eax
80103b00:	eb e3                	jmp    80103ae5 <wait+0x80>
    if (!havekids || curproc->killed)
80103b02:	85 c0                	test   %eax,%eax
80103b04:	74 06                	je     80103b0c <wait+0xa7>
80103b06:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103b0a:	74 17                	je     80103b23 <wait+0xbe>
      release(&ptable.lock);
80103b0c:	83 ec 0c             	sub    $0xc,%esp
80103b0f:	68 40 2d 15 80       	push   $0x80152d40
80103b14:	e8 9f 04 00 00       	call   80103fb8 <release>
      return -1;
80103b19:	83 c4 10             	add    $0x10,%esp
80103b1c:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103b21:	eb b9                	jmp    80103adc <wait+0x77>
    sleep(curproc, &ptable.lock); //DOC: wait-sleep
80103b23:	83 ec 08             	sub    $0x8,%esp
80103b26:	68 40 2d 15 80       	push   $0x80152d40
80103b2b:	56                   	push   %esi
80103b2c:	e8 a3 fe ff ff       	call   801039d4 <sleep>
    havekids = 0;
80103b31:	83 c4 10             	add    $0x10,%esp
80103b34:	e9 48 ff ff ff       	jmp    80103a81 <wait+0x1c>

80103b39 <wakeup>:

// Wake up all processes sleeping on chan.
void wakeup(void *chan)
{
80103b39:	55                   	push   %ebp
80103b3a:	89 e5                	mov    %esp,%ebp
80103b3c:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103b3f:	68 40 2d 15 80       	push   $0x80152d40
80103b44:	e8 0a 04 00 00       	call   80103f53 <acquire>
  wakeup1(chan);
80103b49:	8b 45 08             	mov    0x8(%ebp),%eax
80103b4c:	e8 19 f8 ff ff       	call   8010336a <wakeup1>
  release(&ptable.lock);
80103b51:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
80103b58:	e8 5b 04 00 00       	call   80103fb8 <release>
}
80103b5d:	83 c4 10             	add    $0x10,%esp
80103b60:	c9                   	leave  
80103b61:	c3                   	ret    

80103b62 <kill>:

// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int kill(int pid)
{
80103b62:	55                   	push   %ebp
80103b63:	89 e5                	mov    %esp,%ebp
80103b65:	53                   	push   %ebx
80103b66:	83 ec 10             	sub    $0x10,%esp
80103b69:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103b6c:	68 40 2d 15 80       	push   $0x80152d40
80103b71:	e8 dd 03 00 00       	call   80103f53 <acquire>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103b76:	83 c4 10             	add    $0x10,%esp
80103b79:	b8 74 2d 15 80       	mov    $0x80152d74,%eax
80103b7e:	3d 74 4c 15 80       	cmp    $0x80154c74,%eax
80103b83:	73 3a                	jae    80103bbf <kill+0x5d>
  {
    if (p->pid == pid)
80103b85:	39 58 10             	cmp    %ebx,0x10(%eax)
80103b88:	74 05                	je     80103b8f <kill+0x2d>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103b8a:	83 c0 7c             	add    $0x7c,%eax
80103b8d:	eb ef                	jmp    80103b7e <kill+0x1c>
    {
      p->killed = 1;
80103b8f:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if (p->state == SLEEPING)
80103b96:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103b9a:	74 1a                	je     80103bb6 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103b9c:	83 ec 0c             	sub    $0xc,%esp
80103b9f:	68 40 2d 15 80       	push   $0x80152d40
80103ba4:	e8 0f 04 00 00       	call   80103fb8 <release>
      return 0;
80103ba9:	83 c4 10             	add    $0x10,%esp
80103bac:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103bb1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103bb4:	c9                   	leave  
80103bb5:	c3                   	ret    
        p->state = RUNNABLE;
80103bb6:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103bbd:	eb dd                	jmp    80103b9c <kill+0x3a>
  release(&ptable.lock);
80103bbf:	83 ec 0c             	sub    $0xc,%esp
80103bc2:	68 40 2d 15 80       	push   $0x80152d40
80103bc7:	e8 ec 03 00 00       	call   80103fb8 <release>
  return -1;
80103bcc:	83 c4 10             	add    $0x10,%esp
80103bcf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103bd4:	eb db                	jmp    80103bb1 <kill+0x4f>

80103bd6 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
80103bd6:	55                   	push   %ebp
80103bd7:	89 e5                	mov    %esp,%ebp
80103bd9:	56                   	push   %esi
80103bda:	53                   	push   %ebx
80103bdb:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103bde:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
80103be3:	eb 33                	jmp    80103c18 <procdump+0x42>
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103be5:	b8 80 6e 10 80       	mov    $0x80106e80,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103bea:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103bed:	52                   	push   %edx
80103bee:	50                   	push   %eax
80103bef:	ff 73 10             	pushl  0x10(%ebx)
80103bf2:	68 84 6e 10 80       	push   $0x80106e84
80103bf7:	e8 0f ca ff ff       	call   8010060b <cprintf>
    if (p->state == SLEEPING)
80103bfc:	83 c4 10             	add    $0x10,%esp
80103bff:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103c03:	74 39                	je     80103c3e <procdump+0x68>
    {
      getcallerpcs((uint *)p->context->ebp + 2, pc);
      for (i = 0; i < 10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103c05:	83 ec 0c             	sub    $0xc,%esp
80103c08:	68 fb 71 10 80       	push   $0x801071fb
80103c0d:	e8 f9 c9 ff ff       	call   8010060b <cprintf>
80103c12:	83 c4 10             	add    $0x10,%esp
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103c15:	83 c3 7c             	add    $0x7c,%ebx
80103c18:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
80103c1e:	73 61                	jae    80103c81 <procdump+0xab>
    if (p->state == UNUSED)
80103c20:	8b 43 0c             	mov    0xc(%ebx),%eax
80103c23:	85 c0                	test   %eax,%eax
80103c25:	74 ee                	je     80103c15 <procdump+0x3f>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103c27:	83 f8 05             	cmp    $0x5,%eax
80103c2a:	77 b9                	ja     80103be5 <procdump+0xf>
80103c2c:	8b 04 85 e0 6e 10 80 	mov    -0x7fef9120(,%eax,4),%eax
80103c33:	85 c0                	test   %eax,%eax
80103c35:	75 b3                	jne    80103bea <procdump+0x14>
      state = "???";
80103c37:	b8 80 6e 10 80       	mov    $0x80106e80,%eax
80103c3c:	eb ac                	jmp    80103bea <procdump+0x14>
      getcallerpcs((uint *)p->context->ebp + 2, pc);
80103c3e:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103c41:	8b 40 0c             	mov    0xc(%eax),%eax
80103c44:	83 c0 08             	add    $0x8,%eax
80103c47:	83 ec 08             	sub    $0x8,%esp
80103c4a:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103c4d:	52                   	push   %edx
80103c4e:	50                   	push   %eax
80103c4f:	e8 de 01 00 00       	call   80103e32 <getcallerpcs>
      for (i = 0; i < 10 && pc[i] != 0; i++)
80103c54:	83 c4 10             	add    $0x10,%esp
80103c57:	be 00 00 00 00       	mov    $0x0,%esi
80103c5c:	eb 14                	jmp    80103c72 <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103c5e:	83 ec 08             	sub    $0x8,%esp
80103c61:	50                   	push   %eax
80103c62:	68 c1 68 10 80       	push   $0x801068c1
80103c67:	e8 9f c9 ff ff       	call   8010060b <cprintf>
      for (i = 0; i < 10 && pc[i] != 0; i++)
80103c6c:	83 c6 01             	add    $0x1,%esi
80103c6f:	83 c4 10             	add    $0x10,%esp
80103c72:	83 fe 09             	cmp    $0x9,%esi
80103c75:	7f 8e                	jg     80103c05 <procdump+0x2f>
80103c77:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103c7b:	85 c0                	test   %eax,%eax
80103c7d:	75 df                	jne    80103c5e <procdump+0x88>
80103c7f:	eb 84                	jmp    80103c05 <procdump+0x2f>
  }
}
80103c81:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c84:	5b                   	pop    %ebx
80103c85:	5e                   	pop    %esi
80103c86:	5d                   	pop    %ebp
80103c87:	c3                   	ret    

80103c88 <dump_physmem>:

int dump_physmem(int *frames, int *pids, int numframes)
{
80103c88:	55                   	push   %ebp
80103c89:	89 e5                	mov    %esp,%ebp
80103c8b:	57                   	push   %edi
80103c8c:	56                   	push   %esi
80103c8d:	53                   	push   %ebx
80103c8e:	83 ec 0c             	sub    $0xc,%esp
80103c91:	8b 5d 10             	mov    0x10(%ebp),%ebx
  if(numframes == 0 || frames == 0 || pids == 0) {
80103c94:	85 db                	test   %ebx,%ebx
80103c96:	0f 94 c2             	sete   %dl
80103c99:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80103c9d:	0f 94 c0             	sete   %al
80103ca0:	08 c2                	or     %al,%dl
80103ca2:	75 5a                	jne    80103cfe <dump_physmem+0x76>
80103ca4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103ca8:	74 5b                	je     80103d05 <dump_physmem+0x7d>
    return -1;
  }
  int* framesList = getframesList();
80103caa:	e8 f5 e2 ff ff       	call   80101fa4 <getframesList>
  int j = 0;
  for(int i = 65535; i >=0; i--) {
80103caf:	ba ff ff 00 00       	mov    $0xffff,%edx
  int j = 0;
80103cb4:	bf 00 00 00 00       	mov    $0x0,%edi
80103cb9:	89 5d 10             	mov    %ebx,0x10(%ebp)
  for(int i = 65535; i >=0; i--) {
80103cbc:	eb 03                	jmp    80103cc1 <dump_physmem+0x39>
80103cbe:	83 ea 01             	sub    $0x1,%edx
80103cc1:	85 d2                	test   %edx,%edx
80103cc3:	78 2c                	js     80103cf1 <dump_physmem+0x69>
    if(framesList[i] != 0 && framesList[i] != -1 && j < numframes){
80103cc5:	8d 34 90             	lea    (%eax,%edx,4),%esi
80103cc8:	8b 0e                	mov    (%esi),%ecx
80103cca:	83 c1 01             	add    $0x1,%ecx
80103ccd:	83 f9 01             	cmp    $0x1,%ecx
80103cd0:	76 ec                	jbe    80103cbe <dump_physmem+0x36>
80103cd2:	3b 7d 10             	cmp    0x10(%ebp),%edi
80103cd5:	7d e7                	jge    80103cbe <dump_physmem+0x36>
      frames[j] = i;
80103cd7:	8d 0c bd 00 00 00 00 	lea    0x0(,%edi,4),%ecx
80103cde:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103ce1:	89 14 0b             	mov    %edx,(%ebx,%ecx,1)
      pids[j++] = framesList[i];
80103ce4:	83 c7 01             	add    $0x1,%edi
80103ce7:	8b 36                	mov    (%esi),%esi
80103ce9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103cec:	89 34 0b             	mov    %esi,(%ebx,%ecx,1)
80103cef:	eb cd                	jmp    80103cbe <dump_physmem+0x36>
    }
  }
  return 0;
80103cf1:	b8 00 00 00 00       	mov    $0x0,%eax
80103cf6:	83 c4 0c             	add    $0xc,%esp
80103cf9:	5b                   	pop    %ebx
80103cfa:	5e                   	pop    %esi
80103cfb:	5f                   	pop    %edi
80103cfc:	5d                   	pop    %ebp
80103cfd:	c3                   	ret    
    return -1;
80103cfe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103d03:	eb f1                	jmp    80103cf6 <dump_physmem+0x6e>
80103d05:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103d0a:	eb ea                	jmp    80103cf6 <dump_physmem+0x6e>

80103d0c <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103d0c:	55                   	push   %ebp
80103d0d:	89 e5                	mov    %esp,%ebp
80103d0f:	53                   	push   %ebx
80103d10:	83 ec 0c             	sub    $0xc,%esp
80103d13:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103d16:	68 f8 6e 10 80       	push   $0x80106ef8
80103d1b:	8d 43 04             	lea    0x4(%ebx),%eax
80103d1e:	50                   	push   %eax
80103d1f:	e8 f3 00 00 00       	call   80103e17 <initlock>
  lk->name = name;
80103d24:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d27:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103d2a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103d30:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103d37:	83 c4 10             	add    $0x10,%esp
80103d3a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d3d:	c9                   	leave  
80103d3e:	c3                   	ret    

80103d3f <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103d3f:	55                   	push   %ebp
80103d40:	89 e5                	mov    %esp,%ebp
80103d42:	56                   	push   %esi
80103d43:	53                   	push   %ebx
80103d44:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103d47:	8d 73 04             	lea    0x4(%ebx),%esi
80103d4a:	83 ec 0c             	sub    $0xc,%esp
80103d4d:	56                   	push   %esi
80103d4e:	e8 00 02 00 00       	call   80103f53 <acquire>
  while (lk->locked) {
80103d53:	83 c4 10             	add    $0x10,%esp
80103d56:	eb 0d                	jmp    80103d65 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103d58:	83 ec 08             	sub    $0x8,%esp
80103d5b:	56                   	push   %esi
80103d5c:	53                   	push   %ebx
80103d5d:	e8 72 fc ff ff       	call   801039d4 <sleep>
80103d62:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103d65:	83 3b 00             	cmpl   $0x0,(%ebx)
80103d68:	75 ee                	jne    80103d58 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103d6a:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103d70:	e8 bb f7 ff ff       	call   80103530 <myproc>
80103d75:	8b 40 10             	mov    0x10(%eax),%eax
80103d78:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103d7b:	83 ec 0c             	sub    $0xc,%esp
80103d7e:	56                   	push   %esi
80103d7f:	e8 34 02 00 00       	call   80103fb8 <release>
}
80103d84:	83 c4 10             	add    $0x10,%esp
80103d87:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103d8a:	5b                   	pop    %ebx
80103d8b:	5e                   	pop    %esi
80103d8c:	5d                   	pop    %ebp
80103d8d:	c3                   	ret    

80103d8e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103d8e:	55                   	push   %ebp
80103d8f:	89 e5                	mov    %esp,%ebp
80103d91:	56                   	push   %esi
80103d92:	53                   	push   %ebx
80103d93:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103d96:	8d 73 04             	lea    0x4(%ebx),%esi
80103d99:	83 ec 0c             	sub    $0xc,%esp
80103d9c:	56                   	push   %esi
80103d9d:	e8 b1 01 00 00       	call   80103f53 <acquire>
  lk->locked = 0;
80103da2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103da8:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103daf:	89 1c 24             	mov    %ebx,(%esp)
80103db2:	e8 82 fd ff ff       	call   80103b39 <wakeup>
  release(&lk->lk);
80103db7:	89 34 24             	mov    %esi,(%esp)
80103dba:	e8 f9 01 00 00       	call   80103fb8 <release>
}
80103dbf:	83 c4 10             	add    $0x10,%esp
80103dc2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103dc5:	5b                   	pop    %ebx
80103dc6:	5e                   	pop    %esi
80103dc7:	5d                   	pop    %ebp
80103dc8:	c3                   	ret    

80103dc9 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103dc9:	55                   	push   %ebp
80103dca:	89 e5                	mov    %esp,%ebp
80103dcc:	56                   	push   %esi
80103dcd:	53                   	push   %ebx
80103dce:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103dd1:	8d 73 04             	lea    0x4(%ebx),%esi
80103dd4:	83 ec 0c             	sub    $0xc,%esp
80103dd7:	56                   	push   %esi
80103dd8:	e8 76 01 00 00       	call   80103f53 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103ddd:	83 c4 10             	add    $0x10,%esp
80103de0:	83 3b 00             	cmpl   $0x0,(%ebx)
80103de3:	75 17                	jne    80103dfc <holdingsleep+0x33>
80103de5:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103dea:	83 ec 0c             	sub    $0xc,%esp
80103ded:	56                   	push   %esi
80103dee:	e8 c5 01 00 00       	call   80103fb8 <release>
  return r;
}
80103df3:	89 d8                	mov    %ebx,%eax
80103df5:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103df8:	5b                   	pop    %ebx
80103df9:	5e                   	pop    %esi
80103dfa:	5d                   	pop    %ebp
80103dfb:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103dfc:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103dff:	e8 2c f7 ff ff       	call   80103530 <myproc>
80103e04:	3b 58 10             	cmp    0x10(%eax),%ebx
80103e07:	74 07                	je     80103e10 <holdingsleep+0x47>
80103e09:	bb 00 00 00 00       	mov    $0x0,%ebx
80103e0e:	eb da                	jmp    80103dea <holdingsleep+0x21>
80103e10:	bb 01 00 00 00       	mov    $0x1,%ebx
80103e15:	eb d3                	jmp    80103dea <holdingsleep+0x21>

80103e17 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103e17:	55                   	push   %ebp
80103e18:	89 e5                	mov    %esp,%ebp
80103e1a:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103e1d:	8b 55 0c             	mov    0xc(%ebp),%edx
80103e20:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103e23:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103e29:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103e30:	5d                   	pop    %ebp
80103e31:	c3                   	ret    

80103e32 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103e32:	55                   	push   %ebp
80103e33:	89 e5                	mov    %esp,%ebp
80103e35:	53                   	push   %ebx
80103e36:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103e39:	8b 45 08             	mov    0x8(%ebp),%eax
80103e3c:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103e3f:	b8 00 00 00 00       	mov    $0x0,%eax
80103e44:	83 f8 09             	cmp    $0x9,%eax
80103e47:	7f 25                	jg     80103e6e <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103e49:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103e4f:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103e55:	77 17                	ja     80103e6e <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103e57:	8b 5a 04             	mov    0x4(%edx),%ebx
80103e5a:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103e5d:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103e5f:	83 c0 01             	add    $0x1,%eax
80103e62:	eb e0                	jmp    80103e44 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103e64:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103e6b:	83 c0 01             	add    $0x1,%eax
80103e6e:	83 f8 09             	cmp    $0x9,%eax
80103e71:	7e f1                	jle    80103e64 <getcallerpcs+0x32>
}
80103e73:	5b                   	pop    %ebx
80103e74:	5d                   	pop    %ebp
80103e75:	c3                   	ret    

80103e76 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103e76:	55                   	push   %ebp
80103e77:	89 e5                	mov    %esp,%ebp
80103e79:	53                   	push   %ebx
80103e7a:	83 ec 04             	sub    $0x4,%esp
80103e7d:	9c                   	pushf  
80103e7e:	5b                   	pop    %ebx
  asm volatile("cli");
80103e7f:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103e80:	e8 34 f6 ff ff       	call   801034b9 <mycpu>
80103e85:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103e8c:	74 12                	je     80103ea0 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103e8e:	e8 26 f6 ff ff       	call   801034b9 <mycpu>
80103e93:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103e9a:	83 c4 04             	add    $0x4,%esp
80103e9d:	5b                   	pop    %ebx
80103e9e:	5d                   	pop    %ebp
80103e9f:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103ea0:	e8 14 f6 ff ff       	call   801034b9 <mycpu>
80103ea5:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103eab:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103eb1:	eb db                	jmp    80103e8e <pushcli+0x18>

80103eb3 <popcli>:

void
popcli(void)
{
80103eb3:	55                   	push   %ebp
80103eb4:	89 e5                	mov    %esp,%ebp
80103eb6:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103eb9:	9c                   	pushf  
80103eba:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103ebb:	f6 c4 02             	test   $0x2,%ah
80103ebe:	75 28                	jne    80103ee8 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103ec0:	e8 f4 f5 ff ff       	call   801034b9 <mycpu>
80103ec5:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103ecb:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103ece:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103ed4:	85 d2                	test   %edx,%edx
80103ed6:	78 1d                	js     80103ef5 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103ed8:	e8 dc f5 ff ff       	call   801034b9 <mycpu>
80103edd:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103ee4:	74 1c                	je     80103f02 <popcli+0x4f>
    sti();
}
80103ee6:	c9                   	leave  
80103ee7:	c3                   	ret    
    panic("popcli - interruptible");
80103ee8:	83 ec 0c             	sub    $0xc,%esp
80103eeb:	68 03 6f 10 80       	push   $0x80106f03
80103ef0:	e8 53 c4 ff ff       	call   80100348 <panic>
    panic("popcli");
80103ef5:	83 ec 0c             	sub    $0xc,%esp
80103ef8:	68 1a 6f 10 80       	push   $0x80106f1a
80103efd:	e8 46 c4 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103f02:	e8 b2 f5 ff ff       	call   801034b9 <mycpu>
80103f07:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103f0e:	74 d6                	je     80103ee6 <popcli+0x33>
  asm volatile("sti");
80103f10:	fb                   	sti    
}
80103f11:	eb d3                	jmp    80103ee6 <popcli+0x33>

80103f13 <holding>:
{
80103f13:	55                   	push   %ebp
80103f14:	89 e5                	mov    %esp,%ebp
80103f16:	53                   	push   %ebx
80103f17:	83 ec 04             	sub    $0x4,%esp
80103f1a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103f1d:	e8 54 ff ff ff       	call   80103e76 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103f22:	83 3b 00             	cmpl   $0x0,(%ebx)
80103f25:	75 12                	jne    80103f39 <holding+0x26>
80103f27:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103f2c:	e8 82 ff ff ff       	call   80103eb3 <popcli>
}
80103f31:	89 d8                	mov    %ebx,%eax
80103f33:	83 c4 04             	add    $0x4,%esp
80103f36:	5b                   	pop    %ebx
80103f37:	5d                   	pop    %ebp
80103f38:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103f39:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103f3c:	e8 78 f5 ff ff       	call   801034b9 <mycpu>
80103f41:	39 c3                	cmp    %eax,%ebx
80103f43:	74 07                	je     80103f4c <holding+0x39>
80103f45:	bb 00 00 00 00       	mov    $0x0,%ebx
80103f4a:	eb e0                	jmp    80103f2c <holding+0x19>
80103f4c:	bb 01 00 00 00       	mov    $0x1,%ebx
80103f51:	eb d9                	jmp    80103f2c <holding+0x19>

80103f53 <acquire>:
{
80103f53:	55                   	push   %ebp
80103f54:	89 e5                	mov    %esp,%ebp
80103f56:	53                   	push   %ebx
80103f57:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103f5a:	e8 17 ff ff ff       	call   80103e76 <pushcli>
  if(holding(lk))
80103f5f:	83 ec 0c             	sub    $0xc,%esp
80103f62:	ff 75 08             	pushl  0x8(%ebp)
80103f65:	e8 a9 ff ff ff       	call   80103f13 <holding>
80103f6a:	83 c4 10             	add    $0x10,%esp
80103f6d:	85 c0                	test   %eax,%eax
80103f6f:	75 3a                	jne    80103fab <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103f71:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103f74:	b8 01 00 00 00       	mov    $0x1,%eax
80103f79:	f0 87 02             	lock xchg %eax,(%edx)
80103f7c:	85 c0                	test   %eax,%eax
80103f7e:	75 f1                	jne    80103f71 <acquire+0x1e>
  __sync_synchronize();
80103f80:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103f85:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103f88:	e8 2c f5 ff ff       	call   801034b9 <mycpu>
80103f8d:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103f90:	8b 45 08             	mov    0x8(%ebp),%eax
80103f93:	83 c0 0c             	add    $0xc,%eax
80103f96:	83 ec 08             	sub    $0x8,%esp
80103f99:	50                   	push   %eax
80103f9a:	8d 45 08             	lea    0x8(%ebp),%eax
80103f9d:	50                   	push   %eax
80103f9e:	e8 8f fe ff ff       	call   80103e32 <getcallerpcs>
}
80103fa3:	83 c4 10             	add    $0x10,%esp
80103fa6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103fa9:	c9                   	leave  
80103faa:	c3                   	ret    
    panic("acquire");
80103fab:	83 ec 0c             	sub    $0xc,%esp
80103fae:	68 21 6f 10 80       	push   $0x80106f21
80103fb3:	e8 90 c3 ff ff       	call   80100348 <panic>

80103fb8 <release>:
{
80103fb8:	55                   	push   %ebp
80103fb9:	89 e5                	mov    %esp,%ebp
80103fbb:	53                   	push   %ebx
80103fbc:	83 ec 10             	sub    $0x10,%esp
80103fbf:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103fc2:	53                   	push   %ebx
80103fc3:	e8 4b ff ff ff       	call   80103f13 <holding>
80103fc8:	83 c4 10             	add    $0x10,%esp
80103fcb:	85 c0                	test   %eax,%eax
80103fcd:	74 23                	je     80103ff2 <release+0x3a>
  lk->pcs[0] = 0;
80103fcf:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103fd6:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103fdd:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103fe2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103fe8:	e8 c6 fe ff ff       	call   80103eb3 <popcli>
}
80103fed:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103ff0:	c9                   	leave  
80103ff1:	c3                   	ret    
    panic("release");
80103ff2:	83 ec 0c             	sub    $0xc,%esp
80103ff5:	68 29 6f 10 80       	push   $0x80106f29
80103ffa:	e8 49 c3 ff ff       	call   80100348 <panic>

80103fff <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103fff:	55                   	push   %ebp
80104000:	89 e5                	mov    %esp,%ebp
80104002:	57                   	push   %edi
80104003:	53                   	push   %ebx
80104004:	8b 55 08             	mov    0x8(%ebp),%edx
80104007:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
8010400a:	f6 c2 03             	test   $0x3,%dl
8010400d:	75 05                	jne    80104014 <memset+0x15>
8010400f:	f6 c1 03             	test   $0x3,%cl
80104012:	74 0e                	je     80104022 <memset+0x23>
  asm volatile("cld; rep stosb" :
80104014:	89 d7                	mov    %edx,%edi
80104016:	8b 45 0c             	mov    0xc(%ebp),%eax
80104019:	fc                   	cld    
8010401a:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
8010401c:	89 d0                	mov    %edx,%eax
8010401e:	5b                   	pop    %ebx
8010401f:	5f                   	pop    %edi
80104020:	5d                   	pop    %ebp
80104021:	c3                   	ret    
    c &= 0xFF;
80104022:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80104026:	c1 e9 02             	shr    $0x2,%ecx
80104029:	89 f8                	mov    %edi,%eax
8010402b:	c1 e0 18             	shl    $0x18,%eax
8010402e:	89 fb                	mov    %edi,%ebx
80104030:	c1 e3 10             	shl    $0x10,%ebx
80104033:	09 d8                	or     %ebx,%eax
80104035:	89 fb                	mov    %edi,%ebx
80104037:	c1 e3 08             	shl    $0x8,%ebx
8010403a:	09 d8                	or     %ebx,%eax
8010403c:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
8010403e:	89 d7                	mov    %edx,%edi
80104040:	fc                   	cld    
80104041:	f3 ab                	rep stos %eax,%es:(%edi)
80104043:	eb d7                	jmp    8010401c <memset+0x1d>

80104045 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80104045:	55                   	push   %ebp
80104046:	89 e5                	mov    %esp,%ebp
80104048:	56                   	push   %esi
80104049:	53                   	push   %ebx
8010404a:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010404d:	8b 55 0c             	mov    0xc(%ebp),%edx
80104050:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80104053:	8d 70 ff             	lea    -0x1(%eax),%esi
80104056:	85 c0                	test   %eax,%eax
80104058:	74 1c                	je     80104076 <memcmp+0x31>
    if(*s1 != *s2)
8010405a:	0f b6 01             	movzbl (%ecx),%eax
8010405d:	0f b6 1a             	movzbl (%edx),%ebx
80104060:	38 d8                	cmp    %bl,%al
80104062:	75 0a                	jne    8010406e <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80104064:	83 c1 01             	add    $0x1,%ecx
80104067:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
8010406a:	89 f0                	mov    %esi,%eax
8010406c:	eb e5                	jmp    80104053 <memcmp+0xe>
      return *s1 - *s2;
8010406e:	0f b6 c0             	movzbl %al,%eax
80104071:	0f b6 db             	movzbl %bl,%ebx
80104074:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80104076:	5b                   	pop    %ebx
80104077:	5e                   	pop    %esi
80104078:	5d                   	pop    %ebp
80104079:	c3                   	ret    

8010407a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
8010407a:	55                   	push   %ebp
8010407b:	89 e5                	mov    %esp,%ebp
8010407d:	56                   	push   %esi
8010407e:	53                   	push   %ebx
8010407f:	8b 45 08             	mov    0x8(%ebp),%eax
80104082:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80104085:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80104088:	39 c1                	cmp    %eax,%ecx
8010408a:	73 3a                	jae    801040c6 <memmove+0x4c>
8010408c:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
8010408f:	39 c3                	cmp    %eax,%ebx
80104091:	76 37                	jbe    801040ca <memmove+0x50>
    s += n;
    d += n;
80104093:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80104096:	eb 0d                	jmp    801040a5 <memmove+0x2b>
      *--d = *--s;
80104098:	83 eb 01             	sub    $0x1,%ebx
8010409b:	83 e9 01             	sub    $0x1,%ecx
8010409e:	0f b6 13             	movzbl (%ebx),%edx
801040a1:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
801040a3:	89 f2                	mov    %esi,%edx
801040a5:	8d 72 ff             	lea    -0x1(%edx),%esi
801040a8:	85 d2                	test   %edx,%edx
801040aa:	75 ec                	jne    80104098 <memmove+0x1e>
801040ac:	eb 14                	jmp    801040c2 <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
801040ae:	0f b6 11             	movzbl (%ecx),%edx
801040b1:	88 13                	mov    %dl,(%ebx)
801040b3:	8d 5b 01             	lea    0x1(%ebx),%ebx
801040b6:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
801040b9:	89 f2                	mov    %esi,%edx
801040bb:	8d 72 ff             	lea    -0x1(%edx),%esi
801040be:	85 d2                	test   %edx,%edx
801040c0:	75 ec                	jne    801040ae <memmove+0x34>

  return dst;
}
801040c2:	5b                   	pop    %ebx
801040c3:	5e                   	pop    %esi
801040c4:	5d                   	pop    %ebp
801040c5:	c3                   	ret    
801040c6:	89 c3                	mov    %eax,%ebx
801040c8:	eb f1                	jmp    801040bb <memmove+0x41>
801040ca:	89 c3                	mov    %eax,%ebx
801040cc:	eb ed                	jmp    801040bb <memmove+0x41>

801040ce <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801040ce:	55                   	push   %ebp
801040cf:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
801040d1:	ff 75 10             	pushl  0x10(%ebp)
801040d4:	ff 75 0c             	pushl  0xc(%ebp)
801040d7:	ff 75 08             	pushl  0x8(%ebp)
801040da:	e8 9b ff ff ff       	call   8010407a <memmove>
}
801040df:	c9                   	leave  
801040e0:	c3                   	ret    

801040e1 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801040e1:	55                   	push   %ebp
801040e2:	89 e5                	mov    %esp,%ebp
801040e4:	53                   	push   %ebx
801040e5:	8b 55 08             	mov    0x8(%ebp),%edx
801040e8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801040eb:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
801040ee:	eb 09                	jmp    801040f9 <strncmp+0x18>
    n--, p++, q++;
801040f0:	83 e8 01             	sub    $0x1,%eax
801040f3:	83 c2 01             	add    $0x1,%edx
801040f6:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
801040f9:	85 c0                	test   %eax,%eax
801040fb:	74 0b                	je     80104108 <strncmp+0x27>
801040fd:	0f b6 1a             	movzbl (%edx),%ebx
80104100:	84 db                	test   %bl,%bl
80104102:	74 04                	je     80104108 <strncmp+0x27>
80104104:	3a 19                	cmp    (%ecx),%bl
80104106:	74 e8                	je     801040f0 <strncmp+0xf>
  if(n == 0)
80104108:	85 c0                	test   %eax,%eax
8010410a:	74 0b                	je     80104117 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
8010410c:	0f b6 02             	movzbl (%edx),%eax
8010410f:	0f b6 11             	movzbl (%ecx),%edx
80104112:	29 d0                	sub    %edx,%eax
}
80104114:	5b                   	pop    %ebx
80104115:	5d                   	pop    %ebp
80104116:	c3                   	ret    
    return 0;
80104117:	b8 00 00 00 00       	mov    $0x0,%eax
8010411c:	eb f6                	jmp    80104114 <strncmp+0x33>

8010411e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
8010411e:	55                   	push   %ebp
8010411f:	89 e5                	mov    %esp,%ebp
80104121:	57                   	push   %edi
80104122:	56                   	push   %esi
80104123:	53                   	push   %ebx
80104124:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80104127:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
8010412a:	8b 45 08             	mov    0x8(%ebp),%eax
8010412d:	eb 04                	jmp    80104133 <strncpy+0x15>
8010412f:	89 fb                	mov    %edi,%ebx
80104131:	89 f0                	mov    %esi,%eax
80104133:	8d 51 ff             	lea    -0x1(%ecx),%edx
80104136:	85 c9                	test   %ecx,%ecx
80104138:	7e 1d                	jle    80104157 <strncpy+0x39>
8010413a:	8d 7b 01             	lea    0x1(%ebx),%edi
8010413d:	8d 70 01             	lea    0x1(%eax),%esi
80104140:	0f b6 1b             	movzbl (%ebx),%ebx
80104143:	88 18                	mov    %bl,(%eax)
80104145:	89 d1                	mov    %edx,%ecx
80104147:	84 db                	test   %bl,%bl
80104149:	75 e4                	jne    8010412f <strncpy+0x11>
8010414b:	89 f0                	mov    %esi,%eax
8010414d:	eb 08                	jmp    80104157 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
8010414f:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80104152:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80104154:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80104157:	8d 4a ff             	lea    -0x1(%edx),%ecx
8010415a:	85 d2                	test   %edx,%edx
8010415c:	7f f1                	jg     8010414f <strncpy+0x31>
  return os;
}
8010415e:	8b 45 08             	mov    0x8(%ebp),%eax
80104161:	5b                   	pop    %ebx
80104162:	5e                   	pop    %esi
80104163:	5f                   	pop    %edi
80104164:	5d                   	pop    %ebp
80104165:	c3                   	ret    

80104166 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80104166:	55                   	push   %ebp
80104167:	89 e5                	mov    %esp,%ebp
80104169:	57                   	push   %edi
8010416a:	56                   	push   %esi
8010416b:	53                   	push   %ebx
8010416c:	8b 45 08             	mov    0x8(%ebp),%eax
8010416f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80104172:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80104175:	85 d2                	test   %edx,%edx
80104177:	7e 23                	jle    8010419c <safestrcpy+0x36>
80104179:	89 c1                	mov    %eax,%ecx
8010417b:	eb 04                	jmp    80104181 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
8010417d:	89 fb                	mov    %edi,%ebx
8010417f:	89 f1                	mov    %esi,%ecx
80104181:	83 ea 01             	sub    $0x1,%edx
80104184:	85 d2                	test   %edx,%edx
80104186:	7e 11                	jle    80104199 <safestrcpy+0x33>
80104188:	8d 7b 01             	lea    0x1(%ebx),%edi
8010418b:	8d 71 01             	lea    0x1(%ecx),%esi
8010418e:	0f b6 1b             	movzbl (%ebx),%ebx
80104191:	88 19                	mov    %bl,(%ecx)
80104193:	84 db                	test   %bl,%bl
80104195:	75 e6                	jne    8010417d <safestrcpy+0x17>
80104197:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80104199:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
8010419c:	5b                   	pop    %ebx
8010419d:	5e                   	pop    %esi
8010419e:	5f                   	pop    %edi
8010419f:	5d                   	pop    %ebp
801041a0:	c3                   	ret    

801041a1 <strlen>:

int
strlen(const char *s)
{
801041a1:	55                   	push   %ebp
801041a2:	89 e5                	mov    %esp,%ebp
801041a4:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
801041a7:	b8 00 00 00 00       	mov    $0x0,%eax
801041ac:	eb 03                	jmp    801041b1 <strlen+0x10>
801041ae:	83 c0 01             	add    $0x1,%eax
801041b1:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
801041b5:	75 f7                	jne    801041ae <strlen+0xd>
    ;
  return n;
}
801041b7:	5d                   	pop    %ebp
801041b8:	c3                   	ret    

801041b9 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
801041b9:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801041bd:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
801041c1:	55                   	push   %ebp
  pushl %ebx
801041c2:	53                   	push   %ebx
  pushl %esi
801041c3:	56                   	push   %esi
  pushl %edi
801041c4:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801041c5:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801041c7:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
801041c9:	5f                   	pop    %edi
  popl %esi
801041ca:	5e                   	pop    %esi
  popl %ebx
801041cb:	5b                   	pop    %ebx
  popl %ebp
801041cc:	5d                   	pop    %ebp
  ret
801041cd:	c3                   	ret    

801041ce <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
801041ce:	55                   	push   %ebp
801041cf:	89 e5                	mov    %esp,%ebp
801041d1:	53                   	push   %ebx
801041d2:	83 ec 04             	sub    $0x4,%esp
801041d5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
801041d8:	e8 53 f3 ff ff       	call   80103530 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
801041dd:	8b 00                	mov    (%eax),%eax
801041df:	39 d8                	cmp    %ebx,%eax
801041e1:	76 19                	jbe    801041fc <fetchint+0x2e>
801041e3:	8d 53 04             	lea    0x4(%ebx),%edx
801041e6:	39 d0                	cmp    %edx,%eax
801041e8:	72 19                	jb     80104203 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
801041ea:	8b 13                	mov    (%ebx),%edx
801041ec:	8b 45 0c             	mov    0xc(%ebp),%eax
801041ef:	89 10                	mov    %edx,(%eax)
  return 0;
801041f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801041f6:	83 c4 04             	add    $0x4,%esp
801041f9:	5b                   	pop    %ebx
801041fa:	5d                   	pop    %ebp
801041fb:	c3                   	ret    
    return -1;
801041fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104201:	eb f3                	jmp    801041f6 <fetchint+0x28>
80104203:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104208:	eb ec                	jmp    801041f6 <fetchint+0x28>

8010420a <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
8010420a:	55                   	push   %ebp
8010420b:	89 e5                	mov    %esp,%ebp
8010420d:	53                   	push   %ebx
8010420e:	83 ec 04             	sub    $0x4,%esp
80104211:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80104214:	e8 17 f3 ff ff       	call   80103530 <myproc>

  if(addr >= curproc->sz)
80104219:	39 18                	cmp    %ebx,(%eax)
8010421b:	76 26                	jbe    80104243 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
8010421d:	8b 55 0c             	mov    0xc(%ebp),%edx
80104220:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80104222:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80104224:	89 d8                	mov    %ebx,%eax
80104226:	39 d0                	cmp    %edx,%eax
80104228:	73 0e                	jae    80104238 <fetchstr+0x2e>
    if(*s == 0)
8010422a:	80 38 00             	cmpb   $0x0,(%eax)
8010422d:	74 05                	je     80104234 <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
8010422f:	83 c0 01             	add    $0x1,%eax
80104232:	eb f2                	jmp    80104226 <fetchstr+0x1c>
      return s - *pp;
80104234:	29 d8                	sub    %ebx,%eax
80104236:	eb 05                	jmp    8010423d <fetchstr+0x33>
  }
  return -1;
80104238:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010423d:	83 c4 04             	add    $0x4,%esp
80104240:	5b                   	pop    %ebx
80104241:	5d                   	pop    %ebp
80104242:	c3                   	ret    
    return -1;
80104243:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104248:	eb f3                	jmp    8010423d <fetchstr+0x33>

8010424a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010424a:	55                   	push   %ebp
8010424b:	89 e5                	mov    %esp,%ebp
8010424d:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80104250:	e8 db f2 ff ff       	call   80103530 <myproc>
80104255:	8b 50 18             	mov    0x18(%eax),%edx
80104258:	8b 45 08             	mov    0x8(%ebp),%eax
8010425b:	c1 e0 02             	shl    $0x2,%eax
8010425e:	03 42 44             	add    0x44(%edx),%eax
80104261:	83 ec 08             	sub    $0x8,%esp
80104264:	ff 75 0c             	pushl  0xc(%ebp)
80104267:	83 c0 04             	add    $0x4,%eax
8010426a:	50                   	push   %eax
8010426b:	e8 5e ff ff ff       	call   801041ce <fetchint>
}
80104270:	c9                   	leave  
80104271:	c3                   	ret    

80104272 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80104272:	55                   	push   %ebp
80104273:	89 e5                	mov    %esp,%ebp
80104275:	56                   	push   %esi
80104276:	53                   	push   %ebx
80104277:	83 ec 10             	sub    $0x10,%esp
8010427a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
8010427d:	e8 ae f2 ff ff       	call   80103530 <myproc>
80104282:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80104284:	83 ec 08             	sub    $0x8,%esp
80104287:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010428a:	50                   	push   %eax
8010428b:	ff 75 08             	pushl  0x8(%ebp)
8010428e:	e8 b7 ff ff ff       	call   8010424a <argint>
80104293:	83 c4 10             	add    $0x10,%esp
80104296:	85 c0                	test   %eax,%eax
80104298:	78 24                	js     801042be <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
8010429a:	85 db                	test   %ebx,%ebx
8010429c:	78 27                	js     801042c5 <argptr+0x53>
8010429e:	8b 16                	mov    (%esi),%edx
801042a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042a3:	39 c2                	cmp    %eax,%edx
801042a5:	76 25                	jbe    801042cc <argptr+0x5a>
801042a7:	01 c3                	add    %eax,%ebx
801042a9:	39 da                	cmp    %ebx,%edx
801042ab:	72 26                	jb     801042d3 <argptr+0x61>
    return -1;
  *pp = (char*)i;
801042ad:	8b 55 0c             	mov    0xc(%ebp),%edx
801042b0:	89 02                	mov    %eax,(%edx)
  return 0;
801042b2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801042b7:	8d 65 f8             	lea    -0x8(%ebp),%esp
801042ba:	5b                   	pop    %ebx
801042bb:	5e                   	pop    %esi
801042bc:	5d                   	pop    %ebp
801042bd:	c3                   	ret    
    return -1;
801042be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042c3:	eb f2                	jmp    801042b7 <argptr+0x45>
    return -1;
801042c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042ca:	eb eb                	jmp    801042b7 <argptr+0x45>
801042cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042d1:	eb e4                	jmp    801042b7 <argptr+0x45>
801042d3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042d8:	eb dd                	jmp    801042b7 <argptr+0x45>

801042da <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
801042da:	55                   	push   %ebp
801042db:	89 e5                	mov    %esp,%ebp
801042dd:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
801042e0:	8d 45 f4             	lea    -0xc(%ebp),%eax
801042e3:	50                   	push   %eax
801042e4:	ff 75 08             	pushl  0x8(%ebp)
801042e7:	e8 5e ff ff ff       	call   8010424a <argint>
801042ec:	83 c4 10             	add    $0x10,%esp
801042ef:	85 c0                	test   %eax,%eax
801042f1:	78 13                	js     80104306 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
801042f3:	83 ec 08             	sub    $0x8,%esp
801042f6:	ff 75 0c             	pushl  0xc(%ebp)
801042f9:	ff 75 f4             	pushl  -0xc(%ebp)
801042fc:	e8 09 ff ff ff       	call   8010420a <fetchstr>
80104301:	83 c4 10             	add    $0x10,%esp
}
80104304:	c9                   	leave  
80104305:	c3                   	ret    
    return -1;
80104306:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010430b:	eb f7                	jmp    80104304 <argstr+0x2a>

8010430d <syscall>:
[SYS_dump_physmem]  sys_dump_physmem,
};

void
syscall(void)
{
8010430d:	55                   	push   %ebp
8010430e:	89 e5                	mov    %esp,%ebp
80104310:	53                   	push   %ebx
80104311:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
80104314:	e8 17 f2 ff ff       	call   80103530 <myproc>
80104319:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
8010431b:	8b 40 18             	mov    0x18(%eax),%eax
8010431e:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80104321:	8d 50 ff             	lea    -0x1(%eax),%edx
80104324:	83 fa 15             	cmp    $0x15,%edx
80104327:	77 18                	ja     80104341 <syscall+0x34>
80104329:	8b 14 85 60 6f 10 80 	mov    -0x7fef90a0(,%eax,4),%edx
80104330:	85 d2                	test   %edx,%edx
80104332:	74 0d                	je     80104341 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
80104334:	ff d2                	call   *%edx
80104336:	8b 53 18             	mov    0x18(%ebx),%edx
80104339:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
8010433c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010433f:	c9                   	leave  
80104340:	c3                   	ret    
            curproc->pid, curproc->name, num);
80104341:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
80104344:	50                   	push   %eax
80104345:	52                   	push   %edx
80104346:	ff 73 10             	pushl  0x10(%ebx)
80104349:	68 31 6f 10 80       	push   $0x80106f31
8010434e:	e8 b8 c2 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
80104353:	8b 43 18             	mov    0x18(%ebx),%eax
80104356:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
8010435d:	83 c4 10             	add    $0x10,%esp
80104360:	eb da                	jmp    8010433c <syscall+0x2f>

80104362 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80104362:	55                   	push   %ebp
80104363:	89 e5                	mov    %esp,%ebp
80104365:	56                   	push   %esi
80104366:	53                   	push   %ebx
80104367:	83 ec 18             	sub    $0x18,%esp
8010436a:	89 d6                	mov    %edx,%esi
8010436c:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010436e:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104371:	52                   	push   %edx
80104372:	50                   	push   %eax
80104373:	e8 d2 fe ff ff       	call   8010424a <argint>
80104378:	83 c4 10             	add    $0x10,%esp
8010437b:	85 c0                	test   %eax,%eax
8010437d:	78 2e                	js     801043ad <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
8010437f:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
80104383:	77 2f                	ja     801043b4 <argfd+0x52>
80104385:	e8 a6 f1 ff ff       	call   80103530 <myproc>
8010438a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010438d:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
80104391:	85 c0                	test   %eax,%eax
80104393:	74 26                	je     801043bb <argfd+0x59>
    return -1;
  if(pfd)
80104395:	85 f6                	test   %esi,%esi
80104397:	74 02                	je     8010439b <argfd+0x39>
    *pfd = fd;
80104399:	89 16                	mov    %edx,(%esi)
  if(pf)
8010439b:	85 db                	test   %ebx,%ebx
8010439d:	74 23                	je     801043c2 <argfd+0x60>
    *pf = f;
8010439f:	89 03                	mov    %eax,(%ebx)
  return 0;
801043a1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801043a6:	8d 65 f8             	lea    -0x8(%ebp),%esp
801043a9:	5b                   	pop    %ebx
801043aa:	5e                   	pop    %esi
801043ab:	5d                   	pop    %ebp
801043ac:	c3                   	ret    
    return -1;
801043ad:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043b2:	eb f2                	jmp    801043a6 <argfd+0x44>
    return -1;
801043b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043b9:	eb eb                	jmp    801043a6 <argfd+0x44>
801043bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043c0:	eb e4                	jmp    801043a6 <argfd+0x44>
  return 0;
801043c2:	b8 00 00 00 00       	mov    $0x0,%eax
801043c7:	eb dd                	jmp    801043a6 <argfd+0x44>

801043c9 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801043c9:	55                   	push   %ebp
801043ca:	89 e5                	mov    %esp,%ebp
801043cc:	53                   	push   %ebx
801043cd:	83 ec 04             	sub    $0x4,%esp
801043d0:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
801043d2:	e8 59 f1 ff ff       	call   80103530 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
801043d7:	ba 00 00 00 00       	mov    $0x0,%edx
801043dc:	83 fa 0f             	cmp    $0xf,%edx
801043df:	7f 18                	jg     801043f9 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
801043e1:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
801043e6:	74 05                	je     801043ed <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
801043e8:	83 c2 01             	add    $0x1,%edx
801043eb:	eb ef                	jmp    801043dc <fdalloc+0x13>
      curproc->ofile[fd] = f;
801043ed:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
801043f1:	89 d0                	mov    %edx,%eax
801043f3:	83 c4 04             	add    $0x4,%esp
801043f6:	5b                   	pop    %ebx
801043f7:	5d                   	pop    %ebp
801043f8:	c3                   	ret    
  return -1;
801043f9:	ba ff ff ff ff       	mov    $0xffffffff,%edx
801043fe:	eb f1                	jmp    801043f1 <fdalloc+0x28>

80104400 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80104400:	55                   	push   %ebp
80104401:	89 e5                	mov    %esp,%ebp
80104403:	56                   	push   %esi
80104404:	53                   	push   %ebx
80104405:	83 ec 10             	sub    $0x10,%esp
80104408:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010440a:	b8 20 00 00 00       	mov    $0x20,%eax
8010440f:	89 c6                	mov    %eax,%esi
80104411:	39 43 58             	cmp    %eax,0x58(%ebx)
80104414:	76 2e                	jbe    80104444 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104416:	6a 10                	push   $0x10
80104418:	50                   	push   %eax
80104419:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010441c:	50                   	push   %eax
8010441d:	53                   	push   %ebx
8010441e:	e8 50 d3 ff ff       	call   80101773 <readi>
80104423:	83 c4 10             	add    $0x10,%esp
80104426:	83 f8 10             	cmp    $0x10,%eax
80104429:	75 0c                	jne    80104437 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
8010442b:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
80104430:	75 1e                	jne    80104450 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104432:	8d 46 10             	lea    0x10(%esi),%eax
80104435:	eb d8                	jmp    8010440f <isdirempty+0xf>
      panic("isdirempty: readi");
80104437:	83 ec 0c             	sub    $0xc,%esp
8010443a:	68 bc 6f 10 80       	push   $0x80106fbc
8010443f:	e8 04 bf ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
80104444:	b8 01 00 00 00       	mov    $0x1,%eax
}
80104449:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010444c:	5b                   	pop    %ebx
8010444d:	5e                   	pop    %esi
8010444e:	5d                   	pop    %ebp
8010444f:	c3                   	ret    
      return 0;
80104450:	b8 00 00 00 00       	mov    $0x0,%eax
80104455:	eb f2                	jmp    80104449 <isdirempty+0x49>

80104457 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104457:	55                   	push   %ebp
80104458:	89 e5                	mov    %esp,%ebp
8010445a:	57                   	push   %edi
8010445b:	56                   	push   %esi
8010445c:	53                   	push   %ebx
8010445d:	83 ec 44             	sub    $0x44,%esp
80104460:	89 55 c4             	mov    %edx,-0x3c(%ebp)
80104463:	89 4d c0             	mov    %ecx,-0x40(%ebp)
80104466:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104469:	8d 55 d6             	lea    -0x2a(%ebp),%edx
8010446c:	52                   	push   %edx
8010446d:	50                   	push   %eax
8010446e:	e8 86 d7 ff ff       	call   80101bf9 <nameiparent>
80104473:	89 c6                	mov    %eax,%esi
80104475:	83 c4 10             	add    $0x10,%esp
80104478:	85 c0                	test   %eax,%eax
8010447a:	0f 84 3a 01 00 00    	je     801045ba <create+0x163>
    return 0;
  ilock(dp);
80104480:	83 ec 0c             	sub    $0xc,%esp
80104483:	50                   	push   %eax
80104484:	e8 f8 d0 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104489:	83 c4 0c             	add    $0xc,%esp
8010448c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010448f:	50                   	push   %eax
80104490:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104493:	50                   	push   %eax
80104494:	56                   	push   %esi
80104495:	e8 16 d5 ff ff       	call   801019b0 <dirlookup>
8010449a:	89 c3                	mov    %eax,%ebx
8010449c:	83 c4 10             	add    $0x10,%esp
8010449f:	85 c0                	test   %eax,%eax
801044a1:	74 3f                	je     801044e2 <create+0x8b>
    iunlockput(dp);
801044a3:	83 ec 0c             	sub    $0xc,%esp
801044a6:	56                   	push   %esi
801044a7:	e8 7c d2 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
801044ac:	89 1c 24             	mov    %ebx,(%esp)
801044af:	e8 cd d0 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801044b4:	83 c4 10             	add    $0x10,%esp
801044b7:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
801044bc:	75 11                	jne    801044cf <create+0x78>
801044be:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
801044c3:	75 0a                	jne    801044cf <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
801044c5:	89 d8                	mov    %ebx,%eax
801044c7:	8d 65 f4             	lea    -0xc(%ebp),%esp
801044ca:	5b                   	pop    %ebx
801044cb:	5e                   	pop    %esi
801044cc:	5f                   	pop    %edi
801044cd:	5d                   	pop    %ebp
801044ce:	c3                   	ret    
    iunlockput(ip);
801044cf:	83 ec 0c             	sub    $0xc,%esp
801044d2:	53                   	push   %ebx
801044d3:	e8 50 d2 ff ff       	call   80101728 <iunlockput>
    return 0;
801044d8:	83 c4 10             	add    $0x10,%esp
801044db:	bb 00 00 00 00       	mov    $0x0,%ebx
801044e0:	eb e3                	jmp    801044c5 <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
801044e2:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
801044e6:	83 ec 08             	sub    $0x8,%esp
801044e9:	50                   	push   %eax
801044ea:	ff 36                	pushl  (%esi)
801044ec:	e8 8d ce ff ff       	call   8010137e <ialloc>
801044f1:	89 c3                	mov    %eax,%ebx
801044f3:	83 c4 10             	add    $0x10,%esp
801044f6:	85 c0                	test   %eax,%eax
801044f8:	74 55                	je     8010454f <create+0xf8>
  ilock(ip);
801044fa:	83 ec 0c             	sub    $0xc,%esp
801044fd:	50                   	push   %eax
801044fe:	e8 7e d0 ff ff       	call   80101581 <ilock>
  ip->major = major;
80104503:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
80104507:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
8010450b:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
8010450f:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
80104515:	89 1c 24             	mov    %ebx,(%esp)
80104518:	e8 03 cf ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
8010451d:	83 c4 10             	add    $0x10,%esp
80104520:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
80104525:	74 35                	je     8010455c <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
80104527:	83 ec 04             	sub    $0x4,%esp
8010452a:	ff 73 04             	pushl  0x4(%ebx)
8010452d:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104530:	50                   	push   %eax
80104531:	56                   	push   %esi
80104532:	e8 f9 d5 ff ff       	call   80101b30 <dirlink>
80104537:	83 c4 10             	add    $0x10,%esp
8010453a:	85 c0                	test   %eax,%eax
8010453c:	78 6f                	js     801045ad <create+0x156>
  iunlockput(dp);
8010453e:	83 ec 0c             	sub    $0xc,%esp
80104541:	56                   	push   %esi
80104542:	e8 e1 d1 ff ff       	call   80101728 <iunlockput>
  return ip;
80104547:	83 c4 10             	add    $0x10,%esp
8010454a:	e9 76 ff ff ff       	jmp    801044c5 <create+0x6e>
    panic("create: ialloc");
8010454f:	83 ec 0c             	sub    $0xc,%esp
80104552:	68 ce 6f 10 80       	push   $0x80106fce
80104557:	e8 ec bd ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
8010455c:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104560:	83 c0 01             	add    $0x1,%eax
80104563:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104567:	83 ec 0c             	sub    $0xc,%esp
8010456a:	56                   	push   %esi
8010456b:	e8 b0 ce ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80104570:	83 c4 0c             	add    $0xc,%esp
80104573:	ff 73 04             	pushl  0x4(%ebx)
80104576:	68 de 6f 10 80       	push   $0x80106fde
8010457b:	53                   	push   %ebx
8010457c:	e8 af d5 ff ff       	call   80101b30 <dirlink>
80104581:	83 c4 10             	add    $0x10,%esp
80104584:	85 c0                	test   %eax,%eax
80104586:	78 18                	js     801045a0 <create+0x149>
80104588:	83 ec 04             	sub    $0x4,%esp
8010458b:	ff 76 04             	pushl  0x4(%esi)
8010458e:	68 dd 6f 10 80       	push   $0x80106fdd
80104593:	53                   	push   %ebx
80104594:	e8 97 d5 ff ff       	call   80101b30 <dirlink>
80104599:	83 c4 10             	add    $0x10,%esp
8010459c:	85 c0                	test   %eax,%eax
8010459e:	79 87                	jns    80104527 <create+0xd0>
      panic("create dots");
801045a0:	83 ec 0c             	sub    $0xc,%esp
801045a3:	68 e0 6f 10 80       	push   $0x80106fe0
801045a8:	e8 9b bd ff ff       	call   80100348 <panic>
    panic("create: dirlink");
801045ad:	83 ec 0c             	sub    $0xc,%esp
801045b0:	68 ec 6f 10 80       	push   $0x80106fec
801045b5:	e8 8e bd ff ff       	call   80100348 <panic>
    return 0;
801045ba:	89 c3                	mov    %eax,%ebx
801045bc:	e9 04 ff ff ff       	jmp    801044c5 <create+0x6e>

801045c1 <sys_dup>:
{
801045c1:	55                   	push   %ebp
801045c2:	89 e5                	mov    %esp,%ebp
801045c4:	53                   	push   %ebx
801045c5:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
801045c8:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801045cb:	ba 00 00 00 00       	mov    $0x0,%edx
801045d0:	b8 00 00 00 00       	mov    $0x0,%eax
801045d5:	e8 88 fd ff ff       	call   80104362 <argfd>
801045da:	85 c0                	test   %eax,%eax
801045dc:	78 23                	js     80104601 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
801045de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045e1:	e8 e3 fd ff ff       	call   801043c9 <fdalloc>
801045e6:	89 c3                	mov    %eax,%ebx
801045e8:	85 c0                	test   %eax,%eax
801045ea:	78 1c                	js     80104608 <sys_dup+0x47>
  filedup(f);
801045ec:	83 ec 0c             	sub    $0xc,%esp
801045ef:	ff 75 f4             	pushl  -0xc(%ebp)
801045f2:	e8 97 c6 ff ff       	call   80100c8e <filedup>
  return fd;
801045f7:	83 c4 10             	add    $0x10,%esp
}
801045fa:	89 d8                	mov    %ebx,%eax
801045fc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801045ff:	c9                   	leave  
80104600:	c3                   	ret    
    return -1;
80104601:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104606:	eb f2                	jmp    801045fa <sys_dup+0x39>
    return -1;
80104608:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010460d:	eb eb                	jmp    801045fa <sys_dup+0x39>

8010460f <sys_read>:
{
8010460f:	55                   	push   %ebp
80104610:	89 e5                	mov    %esp,%ebp
80104612:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104615:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104618:	ba 00 00 00 00       	mov    $0x0,%edx
8010461d:	b8 00 00 00 00       	mov    $0x0,%eax
80104622:	e8 3b fd ff ff       	call   80104362 <argfd>
80104627:	85 c0                	test   %eax,%eax
80104629:	78 43                	js     8010466e <sys_read+0x5f>
8010462b:	83 ec 08             	sub    $0x8,%esp
8010462e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104631:	50                   	push   %eax
80104632:	6a 02                	push   $0x2
80104634:	e8 11 fc ff ff       	call   8010424a <argint>
80104639:	83 c4 10             	add    $0x10,%esp
8010463c:	85 c0                	test   %eax,%eax
8010463e:	78 35                	js     80104675 <sys_read+0x66>
80104640:	83 ec 04             	sub    $0x4,%esp
80104643:	ff 75 f0             	pushl  -0x10(%ebp)
80104646:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104649:	50                   	push   %eax
8010464a:	6a 01                	push   $0x1
8010464c:	e8 21 fc ff ff       	call   80104272 <argptr>
80104651:	83 c4 10             	add    $0x10,%esp
80104654:	85 c0                	test   %eax,%eax
80104656:	78 24                	js     8010467c <sys_read+0x6d>
  return fileread(f, p, n);
80104658:	83 ec 04             	sub    $0x4,%esp
8010465b:	ff 75 f0             	pushl  -0x10(%ebp)
8010465e:	ff 75 ec             	pushl  -0x14(%ebp)
80104661:	ff 75 f4             	pushl  -0xc(%ebp)
80104664:	e8 6e c7 ff ff       	call   80100dd7 <fileread>
80104669:	83 c4 10             	add    $0x10,%esp
}
8010466c:	c9                   	leave  
8010466d:	c3                   	ret    
    return -1;
8010466e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104673:	eb f7                	jmp    8010466c <sys_read+0x5d>
80104675:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010467a:	eb f0                	jmp    8010466c <sys_read+0x5d>
8010467c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104681:	eb e9                	jmp    8010466c <sys_read+0x5d>

80104683 <sys_write>:
{
80104683:	55                   	push   %ebp
80104684:	89 e5                	mov    %esp,%ebp
80104686:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104689:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010468c:	ba 00 00 00 00       	mov    $0x0,%edx
80104691:	b8 00 00 00 00       	mov    $0x0,%eax
80104696:	e8 c7 fc ff ff       	call   80104362 <argfd>
8010469b:	85 c0                	test   %eax,%eax
8010469d:	78 43                	js     801046e2 <sys_write+0x5f>
8010469f:	83 ec 08             	sub    $0x8,%esp
801046a2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801046a5:	50                   	push   %eax
801046a6:	6a 02                	push   $0x2
801046a8:	e8 9d fb ff ff       	call   8010424a <argint>
801046ad:	83 c4 10             	add    $0x10,%esp
801046b0:	85 c0                	test   %eax,%eax
801046b2:	78 35                	js     801046e9 <sys_write+0x66>
801046b4:	83 ec 04             	sub    $0x4,%esp
801046b7:	ff 75 f0             	pushl  -0x10(%ebp)
801046ba:	8d 45 ec             	lea    -0x14(%ebp),%eax
801046bd:	50                   	push   %eax
801046be:	6a 01                	push   $0x1
801046c0:	e8 ad fb ff ff       	call   80104272 <argptr>
801046c5:	83 c4 10             	add    $0x10,%esp
801046c8:	85 c0                	test   %eax,%eax
801046ca:	78 24                	js     801046f0 <sys_write+0x6d>
  return filewrite(f, p, n);
801046cc:	83 ec 04             	sub    $0x4,%esp
801046cf:	ff 75 f0             	pushl  -0x10(%ebp)
801046d2:	ff 75 ec             	pushl  -0x14(%ebp)
801046d5:	ff 75 f4             	pushl  -0xc(%ebp)
801046d8:	e8 7f c7 ff ff       	call   80100e5c <filewrite>
801046dd:	83 c4 10             	add    $0x10,%esp
}
801046e0:	c9                   	leave  
801046e1:	c3                   	ret    
    return -1;
801046e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046e7:	eb f7                	jmp    801046e0 <sys_write+0x5d>
801046e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046ee:	eb f0                	jmp    801046e0 <sys_write+0x5d>
801046f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046f5:	eb e9                	jmp    801046e0 <sys_write+0x5d>

801046f7 <sys_close>:
{
801046f7:	55                   	push   %ebp
801046f8:	89 e5                	mov    %esp,%ebp
801046fa:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
801046fd:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104700:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104703:	b8 00 00 00 00       	mov    $0x0,%eax
80104708:	e8 55 fc ff ff       	call   80104362 <argfd>
8010470d:	85 c0                	test   %eax,%eax
8010470f:	78 25                	js     80104736 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
80104711:	e8 1a ee ff ff       	call   80103530 <myproc>
80104716:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104719:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
80104720:	00 
  fileclose(f);
80104721:	83 ec 0c             	sub    $0xc,%esp
80104724:	ff 75 f0             	pushl  -0x10(%ebp)
80104727:	e8 a7 c5 ff ff       	call   80100cd3 <fileclose>
  return 0;
8010472c:	83 c4 10             	add    $0x10,%esp
8010472f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104734:	c9                   	leave  
80104735:	c3                   	ret    
    return -1;
80104736:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010473b:	eb f7                	jmp    80104734 <sys_close+0x3d>

8010473d <sys_fstat>:
{
8010473d:	55                   	push   %ebp
8010473e:	89 e5                	mov    %esp,%ebp
80104740:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80104743:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104746:	ba 00 00 00 00       	mov    $0x0,%edx
8010474b:	b8 00 00 00 00       	mov    $0x0,%eax
80104750:	e8 0d fc ff ff       	call   80104362 <argfd>
80104755:	85 c0                	test   %eax,%eax
80104757:	78 2a                	js     80104783 <sys_fstat+0x46>
80104759:	83 ec 04             	sub    $0x4,%esp
8010475c:	6a 14                	push   $0x14
8010475e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104761:	50                   	push   %eax
80104762:	6a 01                	push   $0x1
80104764:	e8 09 fb ff ff       	call   80104272 <argptr>
80104769:	83 c4 10             	add    $0x10,%esp
8010476c:	85 c0                	test   %eax,%eax
8010476e:	78 1a                	js     8010478a <sys_fstat+0x4d>
  return filestat(f, st);
80104770:	83 ec 08             	sub    $0x8,%esp
80104773:	ff 75 f0             	pushl  -0x10(%ebp)
80104776:	ff 75 f4             	pushl  -0xc(%ebp)
80104779:	e8 12 c6 ff ff       	call   80100d90 <filestat>
8010477e:	83 c4 10             	add    $0x10,%esp
}
80104781:	c9                   	leave  
80104782:	c3                   	ret    
    return -1;
80104783:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104788:	eb f7                	jmp    80104781 <sys_fstat+0x44>
8010478a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010478f:	eb f0                	jmp    80104781 <sys_fstat+0x44>

80104791 <sys_link>:
{
80104791:	55                   	push   %ebp
80104792:	89 e5                	mov    %esp,%ebp
80104794:	56                   	push   %esi
80104795:	53                   	push   %ebx
80104796:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104799:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010479c:	50                   	push   %eax
8010479d:	6a 00                	push   $0x0
8010479f:	e8 36 fb ff ff       	call   801042da <argstr>
801047a4:	83 c4 10             	add    $0x10,%esp
801047a7:	85 c0                	test   %eax,%eax
801047a9:	0f 88 32 01 00 00    	js     801048e1 <sys_link+0x150>
801047af:	83 ec 08             	sub    $0x8,%esp
801047b2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801047b5:	50                   	push   %eax
801047b6:	6a 01                	push   $0x1
801047b8:	e8 1d fb ff ff       	call   801042da <argstr>
801047bd:	83 c4 10             	add    $0x10,%esp
801047c0:	85 c0                	test   %eax,%eax
801047c2:	0f 88 20 01 00 00    	js     801048e8 <sys_link+0x157>
  begin_op();
801047c8:	e8 02 e3 ff ff       	call   80102acf <begin_op>
  if((ip = namei(old)) == 0){
801047cd:	83 ec 0c             	sub    $0xc,%esp
801047d0:	ff 75 e0             	pushl  -0x20(%ebp)
801047d3:	e8 09 d4 ff ff       	call   80101be1 <namei>
801047d8:	89 c3                	mov    %eax,%ebx
801047da:	83 c4 10             	add    $0x10,%esp
801047dd:	85 c0                	test   %eax,%eax
801047df:	0f 84 99 00 00 00    	je     8010487e <sys_link+0xed>
  ilock(ip);
801047e5:	83 ec 0c             	sub    $0xc,%esp
801047e8:	50                   	push   %eax
801047e9:	e8 93 cd ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
801047ee:	83 c4 10             	add    $0x10,%esp
801047f1:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801047f6:	0f 84 8e 00 00 00    	je     8010488a <sys_link+0xf9>
  ip->nlink++;
801047fc:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104800:	83 c0 01             	add    $0x1,%eax
80104803:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104807:	83 ec 0c             	sub    $0xc,%esp
8010480a:	53                   	push   %ebx
8010480b:	e8 10 cc ff ff       	call   80101420 <iupdate>
  iunlock(ip);
80104810:	89 1c 24             	mov    %ebx,(%esp)
80104813:	e8 2b ce ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
80104818:	83 c4 08             	add    $0x8,%esp
8010481b:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010481e:	50                   	push   %eax
8010481f:	ff 75 e4             	pushl  -0x1c(%ebp)
80104822:	e8 d2 d3 ff ff       	call   80101bf9 <nameiparent>
80104827:	89 c6                	mov    %eax,%esi
80104829:	83 c4 10             	add    $0x10,%esp
8010482c:	85 c0                	test   %eax,%eax
8010482e:	74 7e                	je     801048ae <sys_link+0x11d>
  ilock(dp);
80104830:	83 ec 0c             	sub    $0xc,%esp
80104833:	50                   	push   %eax
80104834:	e8 48 cd ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80104839:	83 c4 10             	add    $0x10,%esp
8010483c:	8b 03                	mov    (%ebx),%eax
8010483e:	39 06                	cmp    %eax,(%esi)
80104840:	75 60                	jne    801048a2 <sys_link+0x111>
80104842:	83 ec 04             	sub    $0x4,%esp
80104845:	ff 73 04             	pushl  0x4(%ebx)
80104848:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010484b:	50                   	push   %eax
8010484c:	56                   	push   %esi
8010484d:	e8 de d2 ff ff       	call   80101b30 <dirlink>
80104852:	83 c4 10             	add    $0x10,%esp
80104855:	85 c0                	test   %eax,%eax
80104857:	78 49                	js     801048a2 <sys_link+0x111>
  iunlockput(dp);
80104859:	83 ec 0c             	sub    $0xc,%esp
8010485c:	56                   	push   %esi
8010485d:	e8 c6 ce ff ff       	call   80101728 <iunlockput>
  iput(ip);
80104862:	89 1c 24             	mov    %ebx,(%esp)
80104865:	e8 1e ce ff ff       	call   80101688 <iput>
  end_op();
8010486a:	e8 da e2 ff ff       	call   80102b49 <end_op>
  return 0;
8010486f:	83 c4 10             	add    $0x10,%esp
80104872:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104877:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010487a:	5b                   	pop    %ebx
8010487b:	5e                   	pop    %esi
8010487c:	5d                   	pop    %ebp
8010487d:	c3                   	ret    
    end_op();
8010487e:	e8 c6 e2 ff ff       	call   80102b49 <end_op>
    return -1;
80104883:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104888:	eb ed                	jmp    80104877 <sys_link+0xe6>
    iunlockput(ip);
8010488a:	83 ec 0c             	sub    $0xc,%esp
8010488d:	53                   	push   %ebx
8010488e:	e8 95 ce ff ff       	call   80101728 <iunlockput>
    end_op();
80104893:	e8 b1 e2 ff ff       	call   80102b49 <end_op>
    return -1;
80104898:	83 c4 10             	add    $0x10,%esp
8010489b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048a0:	eb d5                	jmp    80104877 <sys_link+0xe6>
    iunlockput(dp);
801048a2:	83 ec 0c             	sub    $0xc,%esp
801048a5:	56                   	push   %esi
801048a6:	e8 7d ce ff ff       	call   80101728 <iunlockput>
    goto bad;
801048ab:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
801048ae:	83 ec 0c             	sub    $0xc,%esp
801048b1:	53                   	push   %ebx
801048b2:	e8 ca cc ff ff       	call   80101581 <ilock>
  ip->nlink--;
801048b7:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801048bb:	83 e8 01             	sub    $0x1,%eax
801048be:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801048c2:	89 1c 24             	mov    %ebx,(%esp)
801048c5:	e8 56 cb ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
801048ca:	89 1c 24             	mov    %ebx,(%esp)
801048cd:	e8 56 ce ff ff       	call   80101728 <iunlockput>
  end_op();
801048d2:	e8 72 e2 ff ff       	call   80102b49 <end_op>
  return -1;
801048d7:	83 c4 10             	add    $0x10,%esp
801048da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048df:	eb 96                	jmp    80104877 <sys_link+0xe6>
    return -1;
801048e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048e6:	eb 8f                	jmp    80104877 <sys_link+0xe6>
801048e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048ed:	eb 88                	jmp    80104877 <sys_link+0xe6>

801048ef <sys_unlink>:
{
801048ef:	55                   	push   %ebp
801048f0:	89 e5                	mov    %esp,%ebp
801048f2:	57                   	push   %edi
801048f3:	56                   	push   %esi
801048f4:	53                   	push   %ebx
801048f5:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
801048f8:	8d 45 c4             	lea    -0x3c(%ebp),%eax
801048fb:	50                   	push   %eax
801048fc:	6a 00                	push   $0x0
801048fe:	e8 d7 f9 ff ff       	call   801042da <argstr>
80104903:	83 c4 10             	add    $0x10,%esp
80104906:	85 c0                	test   %eax,%eax
80104908:	0f 88 83 01 00 00    	js     80104a91 <sys_unlink+0x1a2>
  begin_op();
8010490e:	e8 bc e1 ff ff       	call   80102acf <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80104913:	83 ec 08             	sub    $0x8,%esp
80104916:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104919:	50                   	push   %eax
8010491a:	ff 75 c4             	pushl  -0x3c(%ebp)
8010491d:	e8 d7 d2 ff ff       	call   80101bf9 <nameiparent>
80104922:	89 c6                	mov    %eax,%esi
80104924:	83 c4 10             	add    $0x10,%esp
80104927:	85 c0                	test   %eax,%eax
80104929:	0f 84 ed 00 00 00    	je     80104a1c <sys_unlink+0x12d>
  ilock(dp);
8010492f:	83 ec 0c             	sub    $0xc,%esp
80104932:	50                   	push   %eax
80104933:	e8 49 cc ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104938:	83 c4 08             	add    $0x8,%esp
8010493b:	68 de 6f 10 80       	push   $0x80106fde
80104940:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104943:	50                   	push   %eax
80104944:	e8 52 d0 ff ff       	call   8010199b <namecmp>
80104949:	83 c4 10             	add    $0x10,%esp
8010494c:	85 c0                	test   %eax,%eax
8010494e:	0f 84 fc 00 00 00    	je     80104a50 <sys_unlink+0x161>
80104954:	83 ec 08             	sub    $0x8,%esp
80104957:	68 dd 6f 10 80       	push   $0x80106fdd
8010495c:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010495f:	50                   	push   %eax
80104960:	e8 36 d0 ff ff       	call   8010199b <namecmp>
80104965:	83 c4 10             	add    $0x10,%esp
80104968:	85 c0                	test   %eax,%eax
8010496a:	0f 84 e0 00 00 00    	je     80104a50 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
80104970:	83 ec 04             	sub    $0x4,%esp
80104973:	8d 45 c0             	lea    -0x40(%ebp),%eax
80104976:	50                   	push   %eax
80104977:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010497a:	50                   	push   %eax
8010497b:	56                   	push   %esi
8010497c:	e8 2f d0 ff ff       	call   801019b0 <dirlookup>
80104981:	89 c3                	mov    %eax,%ebx
80104983:	83 c4 10             	add    $0x10,%esp
80104986:	85 c0                	test   %eax,%eax
80104988:	0f 84 c2 00 00 00    	je     80104a50 <sys_unlink+0x161>
  ilock(ip);
8010498e:	83 ec 0c             	sub    $0xc,%esp
80104991:	50                   	push   %eax
80104992:	e8 ea cb ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
80104997:	83 c4 10             	add    $0x10,%esp
8010499a:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
8010499f:	0f 8e 83 00 00 00    	jle    80104a28 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
801049a5:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801049aa:	0f 84 85 00 00 00    	je     80104a35 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
801049b0:	83 ec 04             	sub    $0x4,%esp
801049b3:	6a 10                	push   $0x10
801049b5:	6a 00                	push   $0x0
801049b7:	8d 7d d8             	lea    -0x28(%ebp),%edi
801049ba:	57                   	push   %edi
801049bb:	e8 3f f6 ff ff       	call   80103fff <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801049c0:	6a 10                	push   $0x10
801049c2:	ff 75 c0             	pushl  -0x40(%ebp)
801049c5:	57                   	push   %edi
801049c6:	56                   	push   %esi
801049c7:	e8 a4 ce ff ff       	call   80101870 <writei>
801049cc:	83 c4 20             	add    $0x20,%esp
801049cf:	83 f8 10             	cmp    $0x10,%eax
801049d2:	0f 85 90 00 00 00    	jne    80104a68 <sys_unlink+0x179>
  if(ip->type == T_DIR){
801049d8:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801049dd:	0f 84 92 00 00 00    	je     80104a75 <sys_unlink+0x186>
  iunlockput(dp);
801049e3:	83 ec 0c             	sub    $0xc,%esp
801049e6:	56                   	push   %esi
801049e7:	e8 3c cd ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
801049ec:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801049f0:	83 e8 01             	sub    $0x1,%eax
801049f3:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801049f7:	89 1c 24             	mov    %ebx,(%esp)
801049fa:	e8 21 ca ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
801049ff:	89 1c 24             	mov    %ebx,(%esp)
80104a02:	e8 21 cd ff ff       	call   80101728 <iunlockput>
  end_op();
80104a07:	e8 3d e1 ff ff       	call   80102b49 <end_op>
  return 0;
80104a0c:	83 c4 10             	add    $0x10,%esp
80104a0f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a14:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104a17:	5b                   	pop    %ebx
80104a18:	5e                   	pop    %esi
80104a19:	5f                   	pop    %edi
80104a1a:	5d                   	pop    %ebp
80104a1b:	c3                   	ret    
    end_op();
80104a1c:	e8 28 e1 ff ff       	call   80102b49 <end_op>
    return -1;
80104a21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a26:	eb ec                	jmp    80104a14 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
80104a28:	83 ec 0c             	sub    $0xc,%esp
80104a2b:	68 fc 6f 10 80       	push   $0x80106ffc
80104a30:	e8 13 b9 ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104a35:	89 d8                	mov    %ebx,%eax
80104a37:	e8 c4 f9 ff ff       	call   80104400 <isdirempty>
80104a3c:	85 c0                	test   %eax,%eax
80104a3e:	0f 85 6c ff ff ff    	jne    801049b0 <sys_unlink+0xc1>
    iunlockput(ip);
80104a44:	83 ec 0c             	sub    $0xc,%esp
80104a47:	53                   	push   %ebx
80104a48:	e8 db cc ff ff       	call   80101728 <iunlockput>
    goto bad;
80104a4d:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104a50:	83 ec 0c             	sub    $0xc,%esp
80104a53:	56                   	push   %esi
80104a54:	e8 cf cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104a59:	e8 eb e0 ff ff       	call   80102b49 <end_op>
  return -1;
80104a5e:	83 c4 10             	add    $0x10,%esp
80104a61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a66:	eb ac                	jmp    80104a14 <sys_unlink+0x125>
    panic("unlink: writei");
80104a68:	83 ec 0c             	sub    $0xc,%esp
80104a6b:	68 0e 70 10 80       	push   $0x8010700e
80104a70:	e8 d3 b8 ff ff       	call   80100348 <panic>
    dp->nlink--;
80104a75:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104a79:	83 e8 01             	sub    $0x1,%eax
80104a7c:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104a80:	83 ec 0c             	sub    $0xc,%esp
80104a83:	56                   	push   %esi
80104a84:	e8 97 c9 ff ff       	call   80101420 <iupdate>
80104a89:	83 c4 10             	add    $0x10,%esp
80104a8c:	e9 52 ff ff ff       	jmp    801049e3 <sys_unlink+0xf4>
    return -1;
80104a91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a96:	e9 79 ff ff ff       	jmp    80104a14 <sys_unlink+0x125>

80104a9b <sys_open>:

int
sys_open(void)
{
80104a9b:	55                   	push   %ebp
80104a9c:	89 e5                	mov    %esp,%ebp
80104a9e:	57                   	push   %edi
80104a9f:	56                   	push   %esi
80104aa0:	53                   	push   %ebx
80104aa1:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104aa4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104aa7:	50                   	push   %eax
80104aa8:	6a 00                	push   $0x0
80104aaa:	e8 2b f8 ff ff       	call   801042da <argstr>
80104aaf:	83 c4 10             	add    $0x10,%esp
80104ab2:	85 c0                	test   %eax,%eax
80104ab4:	0f 88 30 01 00 00    	js     80104bea <sys_open+0x14f>
80104aba:	83 ec 08             	sub    $0x8,%esp
80104abd:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104ac0:	50                   	push   %eax
80104ac1:	6a 01                	push   $0x1
80104ac3:	e8 82 f7 ff ff       	call   8010424a <argint>
80104ac8:	83 c4 10             	add    $0x10,%esp
80104acb:	85 c0                	test   %eax,%eax
80104acd:	0f 88 21 01 00 00    	js     80104bf4 <sys_open+0x159>
    return -1;

  begin_op();
80104ad3:	e8 f7 df ff ff       	call   80102acf <begin_op>

  if(omode & O_CREATE){
80104ad8:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104adc:	0f 84 84 00 00 00    	je     80104b66 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
80104ae2:	83 ec 0c             	sub    $0xc,%esp
80104ae5:	6a 00                	push   $0x0
80104ae7:	b9 00 00 00 00       	mov    $0x0,%ecx
80104aec:	ba 02 00 00 00       	mov    $0x2,%edx
80104af1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104af4:	e8 5e f9 ff ff       	call   80104457 <create>
80104af9:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104afb:	83 c4 10             	add    $0x10,%esp
80104afe:	85 c0                	test   %eax,%eax
80104b00:	74 58                	je     80104b5a <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104b02:	e8 26 c1 ff ff       	call   80100c2d <filealloc>
80104b07:	89 c3                	mov    %eax,%ebx
80104b09:	85 c0                	test   %eax,%eax
80104b0b:	0f 84 ae 00 00 00    	je     80104bbf <sys_open+0x124>
80104b11:	e8 b3 f8 ff ff       	call   801043c9 <fdalloc>
80104b16:	89 c7                	mov    %eax,%edi
80104b18:	85 c0                	test   %eax,%eax
80104b1a:	0f 88 9f 00 00 00    	js     80104bbf <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104b20:	83 ec 0c             	sub    $0xc,%esp
80104b23:	56                   	push   %esi
80104b24:	e8 1a cb ff ff       	call   80101643 <iunlock>
  end_op();
80104b29:	e8 1b e0 ff ff       	call   80102b49 <end_op>

  f->type = FD_INODE;
80104b2e:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104b34:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104b37:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104b3e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b41:	83 c4 10             	add    $0x10,%esp
80104b44:	a8 01                	test   $0x1,%al
80104b46:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104b4a:	a8 03                	test   $0x3,%al
80104b4c:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104b50:	89 f8                	mov    %edi,%eax
80104b52:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104b55:	5b                   	pop    %ebx
80104b56:	5e                   	pop    %esi
80104b57:	5f                   	pop    %edi
80104b58:	5d                   	pop    %ebp
80104b59:	c3                   	ret    
      end_op();
80104b5a:	e8 ea df ff ff       	call   80102b49 <end_op>
      return -1;
80104b5f:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b64:	eb ea                	jmp    80104b50 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104b66:	83 ec 0c             	sub    $0xc,%esp
80104b69:	ff 75 e4             	pushl  -0x1c(%ebp)
80104b6c:	e8 70 d0 ff ff       	call   80101be1 <namei>
80104b71:	89 c6                	mov    %eax,%esi
80104b73:	83 c4 10             	add    $0x10,%esp
80104b76:	85 c0                	test   %eax,%eax
80104b78:	74 39                	je     80104bb3 <sys_open+0x118>
    ilock(ip);
80104b7a:	83 ec 0c             	sub    $0xc,%esp
80104b7d:	50                   	push   %eax
80104b7e:	e8 fe c9 ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104b83:	83 c4 10             	add    $0x10,%esp
80104b86:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104b8b:	0f 85 71 ff ff ff    	jne    80104b02 <sys_open+0x67>
80104b91:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104b95:	0f 84 67 ff ff ff    	je     80104b02 <sys_open+0x67>
      iunlockput(ip);
80104b9b:	83 ec 0c             	sub    $0xc,%esp
80104b9e:	56                   	push   %esi
80104b9f:	e8 84 cb ff ff       	call   80101728 <iunlockput>
      end_op();
80104ba4:	e8 a0 df ff ff       	call   80102b49 <end_op>
      return -1;
80104ba9:	83 c4 10             	add    $0x10,%esp
80104bac:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104bb1:	eb 9d                	jmp    80104b50 <sys_open+0xb5>
      end_op();
80104bb3:	e8 91 df ff ff       	call   80102b49 <end_op>
      return -1;
80104bb8:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104bbd:	eb 91                	jmp    80104b50 <sys_open+0xb5>
    if(f)
80104bbf:	85 db                	test   %ebx,%ebx
80104bc1:	74 0c                	je     80104bcf <sys_open+0x134>
      fileclose(f);
80104bc3:	83 ec 0c             	sub    $0xc,%esp
80104bc6:	53                   	push   %ebx
80104bc7:	e8 07 c1 ff ff       	call   80100cd3 <fileclose>
80104bcc:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104bcf:	83 ec 0c             	sub    $0xc,%esp
80104bd2:	56                   	push   %esi
80104bd3:	e8 50 cb ff ff       	call   80101728 <iunlockput>
    end_op();
80104bd8:	e8 6c df ff ff       	call   80102b49 <end_op>
    return -1;
80104bdd:	83 c4 10             	add    $0x10,%esp
80104be0:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104be5:	e9 66 ff ff ff       	jmp    80104b50 <sys_open+0xb5>
    return -1;
80104bea:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104bef:	e9 5c ff ff ff       	jmp    80104b50 <sys_open+0xb5>
80104bf4:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104bf9:	e9 52 ff ff ff       	jmp    80104b50 <sys_open+0xb5>

80104bfe <sys_mkdir>:

int
sys_mkdir(void)
{
80104bfe:	55                   	push   %ebp
80104bff:	89 e5                	mov    %esp,%ebp
80104c01:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104c04:	e8 c6 de ff ff       	call   80102acf <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104c09:	83 ec 08             	sub    $0x8,%esp
80104c0c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c0f:	50                   	push   %eax
80104c10:	6a 00                	push   $0x0
80104c12:	e8 c3 f6 ff ff       	call   801042da <argstr>
80104c17:	83 c4 10             	add    $0x10,%esp
80104c1a:	85 c0                	test   %eax,%eax
80104c1c:	78 36                	js     80104c54 <sys_mkdir+0x56>
80104c1e:	83 ec 0c             	sub    $0xc,%esp
80104c21:	6a 00                	push   $0x0
80104c23:	b9 00 00 00 00       	mov    $0x0,%ecx
80104c28:	ba 01 00 00 00       	mov    $0x1,%edx
80104c2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c30:	e8 22 f8 ff ff       	call   80104457 <create>
80104c35:	83 c4 10             	add    $0x10,%esp
80104c38:	85 c0                	test   %eax,%eax
80104c3a:	74 18                	je     80104c54 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104c3c:	83 ec 0c             	sub    $0xc,%esp
80104c3f:	50                   	push   %eax
80104c40:	e8 e3 ca ff ff       	call   80101728 <iunlockput>
  end_op();
80104c45:	e8 ff de ff ff       	call   80102b49 <end_op>
  return 0;
80104c4a:	83 c4 10             	add    $0x10,%esp
80104c4d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c52:	c9                   	leave  
80104c53:	c3                   	ret    
    end_op();
80104c54:	e8 f0 de ff ff       	call   80102b49 <end_op>
    return -1;
80104c59:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c5e:	eb f2                	jmp    80104c52 <sys_mkdir+0x54>

80104c60 <sys_mknod>:

int
sys_mknod(void)
{
80104c60:	55                   	push   %ebp
80104c61:	89 e5                	mov    %esp,%ebp
80104c63:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104c66:	e8 64 de ff ff       	call   80102acf <begin_op>
  if((argstr(0, &path)) < 0 ||
80104c6b:	83 ec 08             	sub    $0x8,%esp
80104c6e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c71:	50                   	push   %eax
80104c72:	6a 00                	push   $0x0
80104c74:	e8 61 f6 ff ff       	call   801042da <argstr>
80104c79:	83 c4 10             	add    $0x10,%esp
80104c7c:	85 c0                	test   %eax,%eax
80104c7e:	78 62                	js     80104ce2 <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104c80:	83 ec 08             	sub    $0x8,%esp
80104c83:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104c86:	50                   	push   %eax
80104c87:	6a 01                	push   $0x1
80104c89:	e8 bc f5 ff ff       	call   8010424a <argint>
  if((argstr(0, &path)) < 0 ||
80104c8e:	83 c4 10             	add    $0x10,%esp
80104c91:	85 c0                	test   %eax,%eax
80104c93:	78 4d                	js     80104ce2 <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104c95:	83 ec 08             	sub    $0x8,%esp
80104c98:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104c9b:	50                   	push   %eax
80104c9c:	6a 02                	push   $0x2
80104c9e:	e8 a7 f5 ff ff       	call   8010424a <argint>
     argint(1, &major) < 0 ||
80104ca3:	83 c4 10             	add    $0x10,%esp
80104ca6:	85 c0                	test   %eax,%eax
80104ca8:	78 38                	js     80104ce2 <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104caa:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104cae:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104cb2:	83 ec 0c             	sub    $0xc,%esp
80104cb5:	50                   	push   %eax
80104cb6:	ba 03 00 00 00       	mov    $0x3,%edx
80104cbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cbe:	e8 94 f7 ff ff       	call   80104457 <create>
80104cc3:	83 c4 10             	add    $0x10,%esp
80104cc6:	85 c0                	test   %eax,%eax
80104cc8:	74 18                	je     80104ce2 <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104cca:	83 ec 0c             	sub    $0xc,%esp
80104ccd:	50                   	push   %eax
80104cce:	e8 55 ca ff ff       	call   80101728 <iunlockput>
  end_op();
80104cd3:	e8 71 de ff ff       	call   80102b49 <end_op>
  return 0;
80104cd8:	83 c4 10             	add    $0x10,%esp
80104cdb:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ce0:	c9                   	leave  
80104ce1:	c3                   	ret    
    end_op();
80104ce2:	e8 62 de ff ff       	call   80102b49 <end_op>
    return -1;
80104ce7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cec:	eb f2                	jmp    80104ce0 <sys_mknod+0x80>

80104cee <sys_chdir>:

int
sys_chdir(void)
{
80104cee:	55                   	push   %ebp
80104cef:	89 e5                	mov    %esp,%ebp
80104cf1:	56                   	push   %esi
80104cf2:	53                   	push   %ebx
80104cf3:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104cf6:	e8 35 e8 ff ff       	call   80103530 <myproc>
80104cfb:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104cfd:	e8 cd dd ff ff       	call   80102acf <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104d02:	83 ec 08             	sub    $0x8,%esp
80104d05:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d08:	50                   	push   %eax
80104d09:	6a 00                	push   $0x0
80104d0b:	e8 ca f5 ff ff       	call   801042da <argstr>
80104d10:	83 c4 10             	add    $0x10,%esp
80104d13:	85 c0                	test   %eax,%eax
80104d15:	78 52                	js     80104d69 <sys_chdir+0x7b>
80104d17:	83 ec 0c             	sub    $0xc,%esp
80104d1a:	ff 75 f4             	pushl  -0xc(%ebp)
80104d1d:	e8 bf ce ff ff       	call   80101be1 <namei>
80104d22:	89 c3                	mov    %eax,%ebx
80104d24:	83 c4 10             	add    $0x10,%esp
80104d27:	85 c0                	test   %eax,%eax
80104d29:	74 3e                	je     80104d69 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104d2b:	83 ec 0c             	sub    $0xc,%esp
80104d2e:	50                   	push   %eax
80104d2f:	e8 4d c8 ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104d34:	83 c4 10             	add    $0x10,%esp
80104d37:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104d3c:	75 37                	jne    80104d75 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104d3e:	83 ec 0c             	sub    $0xc,%esp
80104d41:	53                   	push   %ebx
80104d42:	e8 fc c8 ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104d47:	83 c4 04             	add    $0x4,%esp
80104d4a:	ff 76 68             	pushl  0x68(%esi)
80104d4d:	e8 36 c9 ff ff       	call   80101688 <iput>
  end_op();
80104d52:	e8 f2 dd ff ff       	call   80102b49 <end_op>
  curproc->cwd = ip;
80104d57:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104d5a:	83 c4 10             	add    $0x10,%esp
80104d5d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d62:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104d65:	5b                   	pop    %ebx
80104d66:	5e                   	pop    %esi
80104d67:	5d                   	pop    %ebp
80104d68:	c3                   	ret    
    end_op();
80104d69:	e8 db dd ff ff       	call   80102b49 <end_op>
    return -1;
80104d6e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d73:	eb ed                	jmp    80104d62 <sys_chdir+0x74>
    iunlockput(ip);
80104d75:	83 ec 0c             	sub    $0xc,%esp
80104d78:	53                   	push   %ebx
80104d79:	e8 aa c9 ff ff       	call   80101728 <iunlockput>
    end_op();
80104d7e:	e8 c6 dd ff ff       	call   80102b49 <end_op>
    return -1;
80104d83:	83 c4 10             	add    $0x10,%esp
80104d86:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d8b:	eb d5                	jmp    80104d62 <sys_chdir+0x74>

80104d8d <sys_exec>:

int
sys_exec(void)
{
80104d8d:	55                   	push   %ebp
80104d8e:	89 e5                	mov    %esp,%ebp
80104d90:	53                   	push   %ebx
80104d91:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104d97:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d9a:	50                   	push   %eax
80104d9b:	6a 00                	push   $0x0
80104d9d:	e8 38 f5 ff ff       	call   801042da <argstr>
80104da2:	83 c4 10             	add    $0x10,%esp
80104da5:	85 c0                	test   %eax,%eax
80104da7:	0f 88 a8 00 00 00    	js     80104e55 <sys_exec+0xc8>
80104dad:	83 ec 08             	sub    $0x8,%esp
80104db0:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104db6:	50                   	push   %eax
80104db7:	6a 01                	push   $0x1
80104db9:	e8 8c f4 ff ff       	call   8010424a <argint>
80104dbe:	83 c4 10             	add    $0x10,%esp
80104dc1:	85 c0                	test   %eax,%eax
80104dc3:	0f 88 93 00 00 00    	js     80104e5c <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104dc9:	83 ec 04             	sub    $0x4,%esp
80104dcc:	68 80 00 00 00       	push   $0x80
80104dd1:	6a 00                	push   $0x0
80104dd3:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104dd9:	50                   	push   %eax
80104dda:	e8 20 f2 ff ff       	call   80103fff <memset>
80104ddf:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104de2:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104de7:	83 fb 1f             	cmp    $0x1f,%ebx
80104dea:	77 77                	ja     80104e63 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104dec:	83 ec 08             	sub    $0x8,%esp
80104def:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104df5:	50                   	push   %eax
80104df6:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104dfc:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104dff:	50                   	push   %eax
80104e00:	e8 c9 f3 ff ff       	call   801041ce <fetchint>
80104e05:	83 c4 10             	add    $0x10,%esp
80104e08:	85 c0                	test   %eax,%eax
80104e0a:	78 5e                	js     80104e6a <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104e0c:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104e12:	85 c0                	test   %eax,%eax
80104e14:	74 1d                	je     80104e33 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104e16:	83 ec 08             	sub    $0x8,%esp
80104e19:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104e20:	52                   	push   %edx
80104e21:	50                   	push   %eax
80104e22:	e8 e3 f3 ff ff       	call   8010420a <fetchstr>
80104e27:	83 c4 10             	add    $0x10,%esp
80104e2a:	85 c0                	test   %eax,%eax
80104e2c:	78 46                	js     80104e74 <sys_exec+0xe7>
  for(i=0;; i++){
80104e2e:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104e31:	eb b4                	jmp    80104de7 <sys_exec+0x5a>
      argv[i] = 0;
80104e33:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104e3a:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104e3e:	83 ec 08             	sub    $0x8,%esp
80104e41:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104e47:	50                   	push   %eax
80104e48:	ff 75 f4             	pushl  -0xc(%ebp)
80104e4b:	e8 82 ba ff ff       	call   801008d2 <exec>
80104e50:	83 c4 10             	add    $0x10,%esp
80104e53:	eb 1a                	jmp    80104e6f <sys_exec+0xe2>
    return -1;
80104e55:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e5a:	eb 13                	jmp    80104e6f <sys_exec+0xe2>
80104e5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e61:	eb 0c                	jmp    80104e6f <sys_exec+0xe2>
      return -1;
80104e63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e68:	eb 05                	jmp    80104e6f <sys_exec+0xe2>
      return -1;
80104e6a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104e6f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e72:	c9                   	leave  
80104e73:	c3                   	ret    
      return -1;
80104e74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e79:	eb f4                	jmp    80104e6f <sys_exec+0xe2>

80104e7b <sys_pipe>:

int
sys_pipe(void)
{
80104e7b:	55                   	push   %ebp
80104e7c:	89 e5                	mov    %esp,%ebp
80104e7e:	53                   	push   %ebx
80104e7f:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104e82:	6a 08                	push   $0x8
80104e84:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e87:	50                   	push   %eax
80104e88:	6a 00                	push   $0x0
80104e8a:	e8 e3 f3 ff ff       	call   80104272 <argptr>
80104e8f:	83 c4 10             	add    $0x10,%esp
80104e92:	85 c0                	test   %eax,%eax
80104e94:	78 77                	js     80104f0d <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104e96:	83 ec 08             	sub    $0x8,%esp
80104e99:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104e9c:	50                   	push   %eax
80104e9d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104ea0:	50                   	push   %eax
80104ea1:	e8 bb e1 ff ff       	call   80103061 <pipealloc>
80104ea6:	83 c4 10             	add    $0x10,%esp
80104ea9:	85 c0                	test   %eax,%eax
80104eab:	78 67                	js     80104f14 <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104ead:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104eb0:	e8 14 f5 ff ff       	call   801043c9 <fdalloc>
80104eb5:	89 c3                	mov    %eax,%ebx
80104eb7:	85 c0                	test   %eax,%eax
80104eb9:	78 21                	js     80104edc <sys_pipe+0x61>
80104ebb:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104ebe:	e8 06 f5 ff ff       	call   801043c9 <fdalloc>
80104ec3:	85 c0                	test   %eax,%eax
80104ec5:	78 15                	js     80104edc <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104ec7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104eca:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104ecc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ecf:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104ed2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ed7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104eda:	c9                   	leave  
80104edb:	c3                   	ret    
    if(fd0 >= 0)
80104edc:	85 db                	test   %ebx,%ebx
80104ede:	78 0d                	js     80104eed <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104ee0:	e8 4b e6 ff ff       	call   80103530 <myproc>
80104ee5:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104eec:	00 
    fileclose(rf);
80104eed:	83 ec 0c             	sub    $0xc,%esp
80104ef0:	ff 75 f0             	pushl  -0x10(%ebp)
80104ef3:	e8 db bd ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104ef8:	83 c4 04             	add    $0x4,%esp
80104efb:	ff 75 ec             	pushl  -0x14(%ebp)
80104efe:	e8 d0 bd ff ff       	call   80100cd3 <fileclose>
    return -1;
80104f03:	83 c4 10             	add    $0x10,%esp
80104f06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f0b:	eb ca                	jmp    80104ed7 <sys_pipe+0x5c>
    return -1;
80104f0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f12:	eb c3                	jmp    80104ed7 <sys_pipe+0x5c>
    return -1;
80104f14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f19:	eb bc                	jmp    80104ed7 <sys_pipe+0x5c>

80104f1b <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104f1b:	55                   	push   %ebp
80104f1c:	89 e5                	mov    %esp,%ebp
80104f1e:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104f21:	e8 82 e7 ff ff       	call   801036a8 <fork>
}
80104f26:	c9                   	leave  
80104f27:	c3                   	ret    

80104f28 <sys_exit>:

int
sys_exit(void)
{
80104f28:	55                   	push   %ebp
80104f29:	89 e5                	mov    %esp,%ebp
80104f2b:	83 ec 08             	sub    $0x8,%esp
  exit();
80104f2e:	e8 a9 e9 ff ff       	call   801038dc <exit>
  return 0;  // not reached
}
80104f33:	b8 00 00 00 00       	mov    $0x0,%eax
80104f38:	c9                   	leave  
80104f39:	c3                   	ret    

80104f3a <sys_wait>:

int
sys_wait(void)
{
80104f3a:	55                   	push   %ebp
80104f3b:	89 e5                	mov    %esp,%ebp
80104f3d:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104f40:	e8 20 eb ff ff       	call   80103a65 <wait>
}
80104f45:	c9                   	leave  
80104f46:	c3                   	ret    

80104f47 <sys_kill>:

int
sys_kill(void)
{
80104f47:	55                   	push   %ebp
80104f48:	89 e5                	mov    %esp,%ebp
80104f4a:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104f4d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f50:	50                   	push   %eax
80104f51:	6a 00                	push   $0x0
80104f53:	e8 f2 f2 ff ff       	call   8010424a <argint>
80104f58:	83 c4 10             	add    $0x10,%esp
80104f5b:	85 c0                	test   %eax,%eax
80104f5d:	78 10                	js     80104f6f <sys_kill+0x28>
    return -1;
  return kill(pid);
80104f5f:	83 ec 0c             	sub    $0xc,%esp
80104f62:	ff 75 f4             	pushl  -0xc(%ebp)
80104f65:	e8 f8 eb ff ff       	call   80103b62 <kill>
80104f6a:	83 c4 10             	add    $0x10,%esp
}
80104f6d:	c9                   	leave  
80104f6e:	c3                   	ret    
    return -1;
80104f6f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f74:	eb f7                	jmp    80104f6d <sys_kill+0x26>

80104f76 <sys_getpid>:

int
sys_getpid(void)
{
80104f76:	55                   	push   %ebp
80104f77:	89 e5                	mov    %esp,%ebp
80104f79:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104f7c:	e8 af e5 ff ff       	call   80103530 <myproc>
80104f81:	8b 40 10             	mov    0x10(%eax),%eax
}
80104f84:	c9                   	leave  
80104f85:	c3                   	ret    

80104f86 <sys_sbrk>:

int
sys_sbrk(void)
{
80104f86:	55                   	push   %ebp
80104f87:	89 e5                	mov    %esp,%ebp
80104f89:	53                   	push   %ebx
80104f8a:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104f8d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f90:	50                   	push   %eax
80104f91:	6a 00                	push   $0x0
80104f93:	e8 b2 f2 ff ff       	call   8010424a <argint>
80104f98:	83 c4 10             	add    $0x10,%esp
80104f9b:	85 c0                	test   %eax,%eax
80104f9d:	78 27                	js     80104fc6 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104f9f:	e8 8c e5 ff ff       	call   80103530 <myproc>
80104fa4:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104fa6:	83 ec 0c             	sub    $0xc,%esp
80104fa9:	ff 75 f4             	pushl  -0xc(%ebp)
80104fac:	e8 8a e6 ff ff       	call   8010363b <growproc>
80104fb1:	83 c4 10             	add    $0x10,%esp
80104fb4:	85 c0                	test   %eax,%eax
80104fb6:	78 07                	js     80104fbf <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104fb8:	89 d8                	mov    %ebx,%eax
80104fba:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104fbd:	c9                   	leave  
80104fbe:	c3                   	ret    
    return -1;
80104fbf:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104fc4:	eb f2                	jmp    80104fb8 <sys_sbrk+0x32>
    return -1;
80104fc6:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104fcb:	eb eb                	jmp    80104fb8 <sys_sbrk+0x32>

80104fcd <sys_sleep>:

int
sys_sleep(void)
{
80104fcd:	55                   	push   %ebp
80104fce:	89 e5                	mov    %esp,%ebp
80104fd0:	53                   	push   %ebx
80104fd1:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104fd4:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104fd7:	50                   	push   %eax
80104fd8:	6a 00                	push   $0x0
80104fda:	e8 6b f2 ff ff       	call   8010424a <argint>
80104fdf:	83 c4 10             	add    $0x10,%esp
80104fe2:	85 c0                	test   %eax,%eax
80104fe4:	78 75                	js     8010505b <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104fe6:	83 ec 0c             	sub    $0xc,%esp
80104fe9:	68 80 4c 15 80       	push   $0x80154c80
80104fee:	e8 60 ef ff ff       	call   80103f53 <acquire>
  ticks0 = ticks;
80104ff3:	8b 1d c0 54 15 80    	mov    0x801554c0,%ebx
  while(ticks - ticks0 < n){
80104ff9:	83 c4 10             	add    $0x10,%esp
80104ffc:	a1 c0 54 15 80       	mov    0x801554c0,%eax
80105001:	29 d8                	sub    %ebx,%eax
80105003:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80105006:	73 39                	jae    80105041 <sys_sleep+0x74>
    if(myproc()->killed){
80105008:	e8 23 e5 ff ff       	call   80103530 <myproc>
8010500d:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105011:	75 17                	jne    8010502a <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80105013:	83 ec 08             	sub    $0x8,%esp
80105016:	68 80 4c 15 80       	push   $0x80154c80
8010501b:	68 c0 54 15 80       	push   $0x801554c0
80105020:	e8 af e9 ff ff       	call   801039d4 <sleep>
80105025:	83 c4 10             	add    $0x10,%esp
80105028:	eb d2                	jmp    80104ffc <sys_sleep+0x2f>
      release(&tickslock);
8010502a:	83 ec 0c             	sub    $0xc,%esp
8010502d:	68 80 4c 15 80       	push   $0x80154c80
80105032:	e8 81 ef ff ff       	call   80103fb8 <release>
      return -1;
80105037:	83 c4 10             	add    $0x10,%esp
8010503a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010503f:	eb 15                	jmp    80105056 <sys_sleep+0x89>
  }
  release(&tickslock);
80105041:	83 ec 0c             	sub    $0xc,%esp
80105044:	68 80 4c 15 80       	push   $0x80154c80
80105049:	e8 6a ef ff ff       	call   80103fb8 <release>
  return 0;
8010504e:	83 c4 10             	add    $0x10,%esp
80105051:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105056:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105059:	c9                   	leave  
8010505a:	c3                   	ret    
    return -1;
8010505b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105060:	eb f4                	jmp    80105056 <sys_sleep+0x89>

80105062 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80105062:	55                   	push   %ebp
80105063:	89 e5                	mov    %esp,%ebp
80105065:	53                   	push   %ebx
80105066:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80105069:	68 80 4c 15 80       	push   $0x80154c80
8010506e:	e8 e0 ee ff ff       	call   80103f53 <acquire>
  xticks = ticks;
80105073:	8b 1d c0 54 15 80    	mov    0x801554c0,%ebx
  release(&tickslock);
80105079:	c7 04 24 80 4c 15 80 	movl   $0x80154c80,(%esp)
80105080:	e8 33 ef ff ff       	call   80103fb8 <release>
  return xticks;
}
80105085:	89 d8                	mov    %ebx,%eax
80105087:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010508a:	c9                   	leave  
8010508b:	c3                   	ret    

8010508c <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
8010508c:	55                   	push   %ebp
8010508d:	89 e5                	mov    %esp,%ebp
8010508f:	83 ec 1c             	sub    $0x1c,%esp
  int* frames;
  int* pids;
  int numframes;

  if(argptr(0, (void*)&frames,sizeof(frames)) < 0)
80105092:	6a 04                	push   $0x4
80105094:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105097:	50                   	push   %eax
80105098:	6a 00                	push   $0x0
8010509a:	e8 d3 f1 ff ff       	call   80104272 <argptr>
8010509f:	83 c4 10             	add    $0x10,%esp
801050a2:	85 c0                	test   %eax,%eax
801050a4:	78 42                	js     801050e8 <sys_dump_physmem+0x5c>
    return -1;
  
  if(argptr(1, (void*)&pids, sizeof(pids)) < 0)
801050a6:	83 ec 04             	sub    $0x4,%esp
801050a9:	6a 04                	push   $0x4
801050ab:	8d 45 f0             	lea    -0x10(%ebp),%eax
801050ae:	50                   	push   %eax
801050af:	6a 01                	push   $0x1
801050b1:	e8 bc f1 ff ff       	call   80104272 <argptr>
801050b6:	83 c4 10             	add    $0x10,%esp
801050b9:	85 c0                	test   %eax,%eax
801050bb:	78 32                	js     801050ef <sys_dump_physmem+0x63>
    return -1;
  
  if(argint(2, &numframes) < 0)
801050bd:	83 ec 08             	sub    $0x8,%esp
801050c0:	8d 45 ec             	lea    -0x14(%ebp),%eax
801050c3:	50                   	push   %eax
801050c4:	6a 02                	push   $0x2
801050c6:	e8 7f f1 ff ff       	call   8010424a <argint>
801050cb:	83 c4 10             	add    $0x10,%esp
801050ce:	85 c0                	test   %eax,%eax
801050d0:	78 24                	js     801050f6 <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
801050d2:	83 ec 04             	sub    $0x4,%esp
801050d5:	ff 75 ec             	pushl  -0x14(%ebp)
801050d8:	ff 75 f0             	pushl  -0x10(%ebp)
801050db:	ff 75 f4             	pushl  -0xc(%ebp)
801050de:	e8 a5 eb ff ff       	call   80103c88 <dump_physmem>
801050e3:	83 c4 10             	add    $0x10,%esp
801050e6:	c9                   	leave  
801050e7:	c3                   	ret    
    return -1;
801050e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050ed:	eb f7                	jmp    801050e6 <sys_dump_physmem+0x5a>
    return -1;
801050ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050f4:	eb f0                	jmp    801050e6 <sys_dump_physmem+0x5a>
    return -1;
801050f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050fb:	eb e9                	jmp    801050e6 <sys_dump_physmem+0x5a>

801050fd <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801050fd:	1e                   	push   %ds
  pushl %es
801050fe:	06                   	push   %es
  pushl %fs
801050ff:	0f a0                	push   %fs
  pushl %gs
80105101:	0f a8                	push   %gs
  pushal
80105103:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80105104:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80105108:	8e d8                	mov    %eax,%ds
  movw %ax, %es
8010510a:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
8010510c:	54                   	push   %esp
  call trap
8010510d:	e8 e3 00 00 00       	call   801051f5 <trap>
  addl $4, %esp
80105112:	83 c4 04             	add    $0x4,%esp

80105115 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80105115:	61                   	popa   
  popl %gs
80105116:	0f a9                	pop    %gs
  popl %fs
80105118:	0f a1                	pop    %fs
  popl %es
8010511a:	07                   	pop    %es
  popl %ds
8010511b:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010511c:	83 c4 08             	add    $0x8,%esp
  iret
8010511f:	cf                   	iret   

80105120 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80105120:	55                   	push   %ebp
80105121:	89 e5                	mov    %esp,%ebp
80105123:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80105126:	b8 00 00 00 00       	mov    $0x0,%eax
8010512b:	eb 4a                	jmp    80105177 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
8010512d:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
80105134:	66 89 0c c5 c0 4c 15 	mov    %cx,-0x7feab340(,%eax,8)
8010513b:	80 
8010513c:	66 c7 04 c5 c2 4c 15 	movw   $0x8,-0x7feab33e(,%eax,8)
80105143:	80 08 00 
80105146:	c6 04 c5 c4 4c 15 80 	movb   $0x0,-0x7feab33c(,%eax,8)
8010514d:	00 
8010514e:	0f b6 14 c5 c5 4c 15 	movzbl -0x7feab33b(,%eax,8),%edx
80105155:	80 
80105156:	83 e2 f0             	and    $0xfffffff0,%edx
80105159:	83 ca 0e             	or     $0xe,%edx
8010515c:	83 e2 8f             	and    $0xffffff8f,%edx
8010515f:	83 ca 80             	or     $0xffffff80,%edx
80105162:	88 14 c5 c5 4c 15 80 	mov    %dl,-0x7feab33b(,%eax,8)
80105169:	c1 e9 10             	shr    $0x10,%ecx
8010516c:	66 89 0c c5 c6 4c 15 	mov    %cx,-0x7feab33a(,%eax,8)
80105173:	80 
  for(i = 0; i < 256; i++)
80105174:	83 c0 01             	add    $0x1,%eax
80105177:	3d ff 00 00 00       	cmp    $0xff,%eax
8010517c:	7e af                	jle    8010512d <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
8010517e:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
80105184:	66 89 15 c0 4e 15 80 	mov    %dx,0x80154ec0
8010518b:	66 c7 05 c2 4e 15 80 	movw   $0x8,0x80154ec2
80105192:	08 00 
80105194:	c6 05 c4 4e 15 80 00 	movb   $0x0,0x80154ec4
8010519b:	0f b6 05 c5 4e 15 80 	movzbl 0x80154ec5,%eax
801051a2:	83 c8 0f             	or     $0xf,%eax
801051a5:	83 e0 ef             	and    $0xffffffef,%eax
801051a8:	83 c8 e0             	or     $0xffffffe0,%eax
801051ab:	a2 c5 4e 15 80       	mov    %al,0x80154ec5
801051b0:	c1 ea 10             	shr    $0x10,%edx
801051b3:	66 89 15 c6 4e 15 80 	mov    %dx,0x80154ec6

  initlock(&tickslock, "time");
801051ba:	83 ec 08             	sub    $0x8,%esp
801051bd:	68 1d 70 10 80       	push   $0x8010701d
801051c2:	68 80 4c 15 80       	push   $0x80154c80
801051c7:	e8 4b ec ff ff       	call   80103e17 <initlock>
}
801051cc:	83 c4 10             	add    $0x10,%esp
801051cf:	c9                   	leave  
801051d0:	c3                   	ret    

801051d1 <idtinit>:

void
idtinit(void)
{
801051d1:	55                   	push   %ebp
801051d2:	89 e5                	mov    %esp,%ebp
801051d4:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
801051d7:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
801051dd:	b8 c0 4c 15 80       	mov    $0x80154cc0,%eax
801051e2:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801051e6:	c1 e8 10             	shr    $0x10,%eax
801051e9:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
801051ed:	8d 45 fa             	lea    -0x6(%ebp),%eax
801051f0:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
801051f3:	c9                   	leave  
801051f4:	c3                   	ret    

801051f5 <trap>:

void
trap(struct trapframe *tf)
{
801051f5:	55                   	push   %ebp
801051f6:	89 e5                	mov    %esp,%ebp
801051f8:	57                   	push   %edi
801051f9:	56                   	push   %esi
801051fa:	53                   	push   %ebx
801051fb:	83 ec 1c             	sub    $0x1c,%esp
801051fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80105201:	8b 43 30             	mov    0x30(%ebx),%eax
80105204:	83 f8 40             	cmp    $0x40,%eax
80105207:	74 13                	je     8010521c <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80105209:	83 e8 20             	sub    $0x20,%eax
8010520c:	83 f8 1f             	cmp    $0x1f,%eax
8010520f:	0f 87 3a 01 00 00    	ja     8010534f <trap+0x15a>
80105215:	ff 24 85 c4 70 10 80 	jmp    *-0x7fef8f3c(,%eax,4)
    if(myproc()->killed)
8010521c:	e8 0f e3 ff ff       	call   80103530 <myproc>
80105221:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105225:	75 1f                	jne    80105246 <trap+0x51>
    myproc()->tf = tf;
80105227:	e8 04 e3 ff ff       	call   80103530 <myproc>
8010522c:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
8010522f:	e8 d9 f0 ff ff       	call   8010430d <syscall>
    if(myproc()->killed)
80105234:	e8 f7 e2 ff ff       	call   80103530 <myproc>
80105239:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010523d:	74 7e                	je     801052bd <trap+0xc8>
      exit();
8010523f:	e8 98 e6 ff ff       	call   801038dc <exit>
80105244:	eb 77                	jmp    801052bd <trap+0xc8>
      exit();
80105246:	e8 91 e6 ff ff       	call   801038dc <exit>
8010524b:	eb da                	jmp    80105227 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
8010524d:	e8 c3 e2 ff ff       	call   80103515 <cpuid>
80105252:	85 c0                	test   %eax,%eax
80105254:	74 6f                	je     801052c5 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80105256:	e8 5f d4 ff ff       	call   801026ba <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010525b:	e8 d0 e2 ff ff       	call   80103530 <myproc>
80105260:	85 c0                	test   %eax,%eax
80105262:	74 1c                	je     80105280 <trap+0x8b>
80105264:	e8 c7 e2 ff ff       	call   80103530 <myproc>
80105269:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010526d:	74 11                	je     80105280 <trap+0x8b>
8010526f:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105273:	83 e0 03             	and    $0x3,%eax
80105276:	66 83 f8 03          	cmp    $0x3,%ax
8010527a:	0f 84 62 01 00 00    	je     801053e2 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80105280:	e8 ab e2 ff ff       	call   80103530 <myproc>
80105285:	85 c0                	test   %eax,%eax
80105287:	74 0f                	je     80105298 <trap+0xa3>
80105289:	e8 a2 e2 ff ff       	call   80103530 <myproc>
8010528e:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80105292:	0f 84 54 01 00 00    	je     801053ec <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105298:	e8 93 e2 ff ff       	call   80103530 <myproc>
8010529d:	85 c0                	test   %eax,%eax
8010529f:	74 1c                	je     801052bd <trap+0xc8>
801052a1:	e8 8a e2 ff ff       	call   80103530 <myproc>
801052a6:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801052aa:	74 11                	je     801052bd <trap+0xc8>
801052ac:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
801052b0:	83 e0 03             	and    $0x3,%eax
801052b3:	66 83 f8 03          	cmp    $0x3,%ax
801052b7:	0f 84 43 01 00 00    	je     80105400 <trap+0x20b>
    exit();
}
801052bd:	8d 65 f4             	lea    -0xc(%ebp),%esp
801052c0:	5b                   	pop    %ebx
801052c1:	5e                   	pop    %esi
801052c2:	5f                   	pop    %edi
801052c3:	5d                   	pop    %ebp
801052c4:	c3                   	ret    
      acquire(&tickslock);
801052c5:	83 ec 0c             	sub    $0xc,%esp
801052c8:	68 80 4c 15 80       	push   $0x80154c80
801052cd:	e8 81 ec ff ff       	call   80103f53 <acquire>
      ticks++;
801052d2:	83 05 c0 54 15 80 01 	addl   $0x1,0x801554c0
      wakeup(&ticks);
801052d9:	c7 04 24 c0 54 15 80 	movl   $0x801554c0,(%esp)
801052e0:	e8 54 e8 ff ff       	call   80103b39 <wakeup>
      release(&tickslock);
801052e5:	c7 04 24 80 4c 15 80 	movl   $0x80154c80,(%esp)
801052ec:	e8 c7 ec ff ff       	call   80103fb8 <release>
801052f1:	83 c4 10             	add    $0x10,%esp
801052f4:	e9 5d ff ff ff       	jmp    80105256 <trap+0x61>
    ideintr();
801052f9:	e8 75 ca ff ff       	call   80101d73 <ideintr>
    lapiceoi();
801052fe:	e8 b7 d3 ff ff       	call   801026ba <lapiceoi>
    break;
80105303:	e9 53 ff ff ff       	jmp    8010525b <trap+0x66>
    kbdintr();
80105308:	e8 f1 d1 ff ff       	call   801024fe <kbdintr>
    lapiceoi();
8010530d:	e8 a8 d3 ff ff       	call   801026ba <lapiceoi>
    break;
80105312:	e9 44 ff ff ff       	jmp    8010525b <trap+0x66>
    uartintr();
80105317:	e8 05 02 00 00       	call   80105521 <uartintr>
    lapiceoi();
8010531c:	e8 99 d3 ff ff       	call   801026ba <lapiceoi>
    break;
80105321:	e9 35 ff ff ff       	jmp    8010525b <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105326:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
80105329:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010532d:	e8 e3 e1 ff ff       	call   80103515 <cpuid>
80105332:	57                   	push   %edi
80105333:	0f b7 f6             	movzwl %si,%esi
80105336:	56                   	push   %esi
80105337:	50                   	push   %eax
80105338:	68 28 70 10 80       	push   $0x80107028
8010533d:	e8 c9 b2 ff ff       	call   8010060b <cprintf>
    lapiceoi();
80105342:	e8 73 d3 ff ff       	call   801026ba <lapiceoi>
    break;
80105347:	83 c4 10             	add    $0x10,%esp
8010534a:	e9 0c ff ff ff       	jmp    8010525b <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
8010534f:	e8 dc e1 ff ff       	call   80103530 <myproc>
80105354:	85 c0                	test   %eax,%eax
80105356:	74 5f                	je     801053b7 <trap+0x1c2>
80105358:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
8010535c:	74 59                	je     801053b7 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010535e:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105361:	8b 43 38             	mov    0x38(%ebx),%eax
80105364:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105367:	e8 a9 e1 ff ff       	call   80103515 <cpuid>
8010536c:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010536f:	8b 53 34             	mov    0x34(%ebx),%edx
80105372:	89 55 dc             	mov    %edx,-0x24(%ebp)
80105375:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
80105378:	e8 b3 e1 ff ff       	call   80103530 <myproc>
8010537d:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105380:	89 4d d8             	mov    %ecx,-0x28(%ebp)
80105383:	e8 a8 e1 ff ff       	call   80103530 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105388:	57                   	push   %edi
80105389:	ff 75 e4             	pushl  -0x1c(%ebp)
8010538c:	ff 75 e0             	pushl  -0x20(%ebp)
8010538f:	ff 75 dc             	pushl  -0x24(%ebp)
80105392:	56                   	push   %esi
80105393:	ff 75 d8             	pushl  -0x28(%ebp)
80105396:	ff 70 10             	pushl  0x10(%eax)
80105399:	68 80 70 10 80       	push   $0x80107080
8010539e:	e8 68 b2 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
801053a3:	83 c4 20             	add    $0x20,%esp
801053a6:	e8 85 e1 ff ff       	call   80103530 <myproc>
801053ab:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801053b2:	e9 a4 fe ff ff       	jmp    8010525b <trap+0x66>
801053b7:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801053ba:	8b 73 38             	mov    0x38(%ebx),%esi
801053bd:	e8 53 e1 ff ff       	call   80103515 <cpuid>
801053c2:	83 ec 0c             	sub    $0xc,%esp
801053c5:	57                   	push   %edi
801053c6:	56                   	push   %esi
801053c7:	50                   	push   %eax
801053c8:	ff 73 30             	pushl  0x30(%ebx)
801053cb:	68 4c 70 10 80       	push   $0x8010704c
801053d0:	e8 36 b2 ff ff       	call   8010060b <cprintf>
      panic("trap");
801053d5:	83 c4 14             	add    $0x14,%esp
801053d8:	68 22 70 10 80       	push   $0x80107022
801053dd:	e8 66 af ff ff       	call   80100348 <panic>
    exit();
801053e2:	e8 f5 e4 ff ff       	call   801038dc <exit>
801053e7:	e9 94 fe ff ff       	jmp    80105280 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
801053ec:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
801053f0:	0f 85 a2 fe ff ff    	jne    80105298 <trap+0xa3>
    yield();
801053f6:	e8 a7 e5 ff ff       	call   801039a2 <yield>
801053fb:	e9 98 fe ff ff       	jmp    80105298 <trap+0xa3>
    exit();
80105400:	e8 d7 e4 ff ff       	call   801038dc <exit>
80105405:	e9 b3 fe ff ff       	jmp    801052bd <trap+0xc8>

8010540a <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
8010540a:	55                   	push   %ebp
8010540b:	89 e5                	mov    %esp,%ebp
  if(!uart)
8010540d:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
80105414:	74 15                	je     8010542b <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105416:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010541b:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
8010541c:	a8 01                	test   $0x1,%al
8010541e:	74 12                	je     80105432 <uartgetc+0x28>
80105420:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105425:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
80105426:	0f b6 c0             	movzbl %al,%eax
}
80105429:	5d                   	pop    %ebp
8010542a:	c3                   	ret    
    return -1;
8010542b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105430:	eb f7                	jmp    80105429 <uartgetc+0x1f>
    return -1;
80105432:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105437:	eb f0                	jmp    80105429 <uartgetc+0x1f>

80105439 <uartputc>:
  if(!uart)
80105439:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
80105440:	74 3b                	je     8010547d <uartputc+0x44>
{
80105442:	55                   	push   %ebp
80105443:	89 e5                	mov    %esp,%ebp
80105445:	53                   	push   %ebx
80105446:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105449:	bb 00 00 00 00       	mov    $0x0,%ebx
8010544e:	eb 10                	jmp    80105460 <uartputc+0x27>
    microdelay(10);
80105450:	83 ec 0c             	sub    $0xc,%esp
80105453:	6a 0a                	push   $0xa
80105455:	e8 7f d2 ff ff       	call   801026d9 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010545a:	83 c3 01             	add    $0x1,%ebx
8010545d:	83 c4 10             	add    $0x10,%esp
80105460:	83 fb 7f             	cmp    $0x7f,%ebx
80105463:	7f 0a                	jg     8010546f <uartputc+0x36>
80105465:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010546a:	ec                   	in     (%dx),%al
8010546b:	a8 20                	test   $0x20,%al
8010546d:	74 e1                	je     80105450 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010546f:	8b 45 08             	mov    0x8(%ebp),%eax
80105472:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105477:	ee                   	out    %al,(%dx)
}
80105478:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010547b:	c9                   	leave  
8010547c:	c3                   	ret    
8010547d:	f3 c3                	repz ret 

8010547f <uartinit>:
{
8010547f:	55                   	push   %ebp
80105480:	89 e5                	mov    %esp,%ebp
80105482:	56                   	push   %esi
80105483:	53                   	push   %ebx
80105484:	b9 00 00 00 00       	mov    $0x0,%ecx
80105489:	ba fa 03 00 00       	mov    $0x3fa,%edx
8010548e:	89 c8                	mov    %ecx,%eax
80105490:	ee                   	out    %al,(%dx)
80105491:	be fb 03 00 00       	mov    $0x3fb,%esi
80105496:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
8010549b:	89 f2                	mov    %esi,%edx
8010549d:	ee                   	out    %al,(%dx)
8010549e:	b8 0c 00 00 00       	mov    $0xc,%eax
801054a3:	ba f8 03 00 00       	mov    $0x3f8,%edx
801054a8:	ee                   	out    %al,(%dx)
801054a9:	bb f9 03 00 00       	mov    $0x3f9,%ebx
801054ae:	89 c8                	mov    %ecx,%eax
801054b0:	89 da                	mov    %ebx,%edx
801054b2:	ee                   	out    %al,(%dx)
801054b3:	b8 03 00 00 00       	mov    $0x3,%eax
801054b8:	89 f2                	mov    %esi,%edx
801054ba:	ee                   	out    %al,(%dx)
801054bb:	ba fc 03 00 00       	mov    $0x3fc,%edx
801054c0:	89 c8                	mov    %ecx,%eax
801054c2:	ee                   	out    %al,(%dx)
801054c3:	b8 01 00 00 00       	mov    $0x1,%eax
801054c8:	89 da                	mov    %ebx,%edx
801054ca:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801054cb:	ba fd 03 00 00       	mov    $0x3fd,%edx
801054d0:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
801054d1:	3c ff                	cmp    $0xff,%al
801054d3:	74 45                	je     8010551a <uartinit+0x9b>
  uart = 1;
801054d5:	c7 05 bc a5 10 80 01 	movl   $0x1,0x8010a5bc
801054dc:	00 00 00 
801054df:	ba fa 03 00 00       	mov    $0x3fa,%edx
801054e4:	ec                   	in     (%dx),%al
801054e5:	ba f8 03 00 00       	mov    $0x3f8,%edx
801054ea:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
801054eb:	83 ec 08             	sub    $0x8,%esp
801054ee:	6a 00                	push   $0x0
801054f0:	6a 04                	push   $0x4
801054f2:	e8 87 ca ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
801054f7:	83 c4 10             	add    $0x10,%esp
801054fa:	bb 44 71 10 80       	mov    $0x80107144,%ebx
801054ff:	eb 12                	jmp    80105513 <uartinit+0x94>
    uartputc(*p);
80105501:	83 ec 0c             	sub    $0xc,%esp
80105504:	0f be c0             	movsbl %al,%eax
80105507:	50                   	push   %eax
80105508:	e8 2c ff ff ff       	call   80105439 <uartputc>
  for(p="xv6...\n"; *p; p++)
8010550d:	83 c3 01             	add    $0x1,%ebx
80105510:	83 c4 10             	add    $0x10,%esp
80105513:	0f b6 03             	movzbl (%ebx),%eax
80105516:	84 c0                	test   %al,%al
80105518:	75 e7                	jne    80105501 <uartinit+0x82>
}
8010551a:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010551d:	5b                   	pop    %ebx
8010551e:	5e                   	pop    %esi
8010551f:	5d                   	pop    %ebp
80105520:	c3                   	ret    

80105521 <uartintr>:

void
uartintr(void)
{
80105521:	55                   	push   %ebp
80105522:	89 e5                	mov    %esp,%ebp
80105524:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
80105527:	68 0a 54 10 80       	push   $0x8010540a
8010552c:	e8 0d b2 ff ff       	call   8010073e <consoleintr>
}
80105531:	83 c4 10             	add    $0x10,%esp
80105534:	c9                   	leave  
80105535:	c3                   	ret    

80105536 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80105536:	6a 00                	push   $0x0
  pushl $0
80105538:	6a 00                	push   $0x0
  jmp alltraps
8010553a:	e9 be fb ff ff       	jmp    801050fd <alltraps>

8010553f <vector1>:
.globl vector1
vector1:
  pushl $0
8010553f:	6a 00                	push   $0x0
  pushl $1
80105541:	6a 01                	push   $0x1
  jmp alltraps
80105543:	e9 b5 fb ff ff       	jmp    801050fd <alltraps>

80105548 <vector2>:
.globl vector2
vector2:
  pushl $0
80105548:	6a 00                	push   $0x0
  pushl $2
8010554a:	6a 02                	push   $0x2
  jmp alltraps
8010554c:	e9 ac fb ff ff       	jmp    801050fd <alltraps>

80105551 <vector3>:
.globl vector3
vector3:
  pushl $0
80105551:	6a 00                	push   $0x0
  pushl $3
80105553:	6a 03                	push   $0x3
  jmp alltraps
80105555:	e9 a3 fb ff ff       	jmp    801050fd <alltraps>

8010555a <vector4>:
.globl vector4
vector4:
  pushl $0
8010555a:	6a 00                	push   $0x0
  pushl $4
8010555c:	6a 04                	push   $0x4
  jmp alltraps
8010555e:	e9 9a fb ff ff       	jmp    801050fd <alltraps>

80105563 <vector5>:
.globl vector5
vector5:
  pushl $0
80105563:	6a 00                	push   $0x0
  pushl $5
80105565:	6a 05                	push   $0x5
  jmp alltraps
80105567:	e9 91 fb ff ff       	jmp    801050fd <alltraps>

8010556c <vector6>:
.globl vector6
vector6:
  pushl $0
8010556c:	6a 00                	push   $0x0
  pushl $6
8010556e:	6a 06                	push   $0x6
  jmp alltraps
80105570:	e9 88 fb ff ff       	jmp    801050fd <alltraps>

80105575 <vector7>:
.globl vector7
vector7:
  pushl $0
80105575:	6a 00                	push   $0x0
  pushl $7
80105577:	6a 07                	push   $0x7
  jmp alltraps
80105579:	e9 7f fb ff ff       	jmp    801050fd <alltraps>

8010557e <vector8>:
.globl vector8
vector8:
  pushl $8
8010557e:	6a 08                	push   $0x8
  jmp alltraps
80105580:	e9 78 fb ff ff       	jmp    801050fd <alltraps>

80105585 <vector9>:
.globl vector9
vector9:
  pushl $0
80105585:	6a 00                	push   $0x0
  pushl $9
80105587:	6a 09                	push   $0x9
  jmp alltraps
80105589:	e9 6f fb ff ff       	jmp    801050fd <alltraps>

8010558e <vector10>:
.globl vector10
vector10:
  pushl $10
8010558e:	6a 0a                	push   $0xa
  jmp alltraps
80105590:	e9 68 fb ff ff       	jmp    801050fd <alltraps>

80105595 <vector11>:
.globl vector11
vector11:
  pushl $11
80105595:	6a 0b                	push   $0xb
  jmp alltraps
80105597:	e9 61 fb ff ff       	jmp    801050fd <alltraps>

8010559c <vector12>:
.globl vector12
vector12:
  pushl $12
8010559c:	6a 0c                	push   $0xc
  jmp alltraps
8010559e:	e9 5a fb ff ff       	jmp    801050fd <alltraps>

801055a3 <vector13>:
.globl vector13
vector13:
  pushl $13
801055a3:	6a 0d                	push   $0xd
  jmp alltraps
801055a5:	e9 53 fb ff ff       	jmp    801050fd <alltraps>

801055aa <vector14>:
.globl vector14
vector14:
  pushl $14
801055aa:	6a 0e                	push   $0xe
  jmp alltraps
801055ac:	e9 4c fb ff ff       	jmp    801050fd <alltraps>

801055b1 <vector15>:
.globl vector15
vector15:
  pushl $0
801055b1:	6a 00                	push   $0x0
  pushl $15
801055b3:	6a 0f                	push   $0xf
  jmp alltraps
801055b5:	e9 43 fb ff ff       	jmp    801050fd <alltraps>

801055ba <vector16>:
.globl vector16
vector16:
  pushl $0
801055ba:	6a 00                	push   $0x0
  pushl $16
801055bc:	6a 10                	push   $0x10
  jmp alltraps
801055be:	e9 3a fb ff ff       	jmp    801050fd <alltraps>

801055c3 <vector17>:
.globl vector17
vector17:
  pushl $17
801055c3:	6a 11                	push   $0x11
  jmp alltraps
801055c5:	e9 33 fb ff ff       	jmp    801050fd <alltraps>

801055ca <vector18>:
.globl vector18
vector18:
  pushl $0
801055ca:	6a 00                	push   $0x0
  pushl $18
801055cc:	6a 12                	push   $0x12
  jmp alltraps
801055ce:	e9 2a fb ff ff       	jmp    801050fd <alltraps>

801055d3 <vector19>:
.globl vector19
vector19:
  pushl $0
801055d3:	6a 00                	push   $0x0
  pushl $19
801055d5:	6a 13                	push   $0x13
  jmp alltraps
801055d7:	e9 21 fb ff ff       	jmp    801050fd <alltraps>

801055dc <vector20>:
.globl vector20
vector20:
  pushl $0
801055dc:	6a 00                	push   $0x0
  pushl $20
801055de:	6a 14                	push   $0x14
  jmp alltraps
801055e0:	e9 18 fb ff ff       	jmp    801050fd <alltraps>

801055e5 <vector21>:
.globl vector21
vector21:
  pushl $0
801055e5:	6a 00                	push   $0x0
  pushl $21
801055e7:	6a 15                	push   $0x15
  jmp alltraps
801055e9:	e9 0f fb ff ff       	jmp    801050fd <alltraps>

801055ee <vector22>:
.globl vector22
vector22:
  pushl $0
801055ee:	6a 00                	push   $0x0
  pushl $22
801055f0:	6a 16                	push   $0x16
  jmp alltraps
801055f2:	e9 06 fb ff ff       	jmp    801050fd <alltraps>

801055f7 <vector23>:
.globl vector23
vector23:
  pushl $0
801055f7:	6a 00                	push   $0x0
  pushl $23
801055f9:	6a 17                	push   $0x17
  jmp alltraps
801055fb:	e9 fd fa ff ff       	jmp    801050fd <alltraps>

80105600 <vector24>:
.globl vector24
vector24:
  pushl $0
80105600:	6a 00                	push   $0x0
  pushl $24
80105602:	6a 18                	push   $0x18
  jmp alltraps
80105604:	e9 f4 fa ff ff       	jmp    801050fd <alltraps>

80105609 <vector25>:
.globl vector25
vector25:
  pushl $0
80105609:	6a 00                	push   $0x0
  pushl $25
8010560b:	6a 19                	push   $0x19
  jmp alltraps
8010560d:	e9 eb fa ff ff       	jmp    801050fd <alltraps>

80105612 <vector26>:
.globl vector26
vector26:
  pushl $0
80105612:	6a 00                	push   $0x0
  pushl $26
80105614:	6a 1a                	push   $0x1a
  jmp alltraps
80105616:	e9 e2 fa ff ff       	jmp    801050fd <alltraps>

8010561b <vector27>:
.globl vector27
vector27:
  pushl $0
8010561b:	6a 00                	push   $0x0
  pushl $27
8010561d:	6a 1b                	push   $0x1b
  jmp alltraps
8010561f:	e9 d9 fa ff ff       	jmp    801050fd <alltraps>

80105624 <vector28>:
.globl vector28
vector28:
  pushl $0
80105624:	6a 00                	push   $0x0
  pushl $28
80105626:	6a 1c                	push   $0x1c
  jmp alltraps
80105628:	e9 d0 fa ff ff       	jmp    801050fd <alltraps>

8010562d <vector29>:
.globl vector29
vector29:
  pushl $0
8010562d:	6a 00                	push   $0x0
  pushl $29
8010562f:	6a 1d                	push   $0x1d
  jmp alltraps
80105631:	e9 c7 fa ff ff       	jmp    801050fd <alltraps>

80105636 <vector30>:
.globl vector30
vector30:
  pushl $0
80105636:	6a 00                	push   $0x0
  pushl $30
80105638:	6a 1e                	push   $0x1e
  jmp alltraps
8010563a:	e9 be fa ff ff       	jmp    801050fd <alltraps>

8010563f <vector31>:
.globl vector31
vector31:
  pushl $0
8010563f:	6a 00                	push   $0x0
  pushl $31
80105641:	6a 1f                	push   $0x1f
  jmp alltraps
80105643:	e9 b5 fa ff ff       	jmp    801050fd <alltraps>

80105648 <vector32>:
.globl vector32
vector32:
  pushl $0
80105648:	6a 00                	push   $0x0
  pushl $32
8010564a:	6a 20                	push   $0x20
  jmp alltraps
8010564c:	e9 ac fa ff ff       	jmp    801050fd <alltraps>

80105651 <vector33>:
.globl vector33
vector33:
  pushl $0
80105651:	6a 00                	push   $0x0
  pushl $33
80105653:	6a 21                	push   $0x21
  jmp alltraps
80105655:	e9 a3 fa ff ff       	jmp    801050fd <alltraps>

8010565a <vector34>:
.globl vector34
vector34:
  pushl $0
8010565a:	6a 00                	push   $0x0
  pushl $34
8010565c:	6a 22                	push   $0x22
  jmp alltraps
8010565e:	e9 9a fa ff ff       	jmp    801050fd <alltraps>

80105663 <vector35>:
.globl vector35
vector35:
  pushl $0
80105663:	6a 00                	push   $0x0
  pushl $35
80105665:	6a 23                	push   $0x23
  jmp alltraps
80105667:	e9 91 fa ff ff       	jmp    801050fd <alltraps>

8010566c <vector36>:
.globl vector36
vector36:
  pushl $0
8010566c:	6a 00                	push   $0x0
  pushl $36
8010566e:	6a 24                	push   $0x24
  jmp alltraps
80105670:	e9 88 fa ff ff       	jmp    801050fd <alltraps>

80105675 <vector37>:
.globl vector37
vector37:
  pushl $0
80105675:	6a 00                	push   $0x0
  pushl $37
80105677:	6a 25                	push   $0x25
  jmp alltraps
80105679:	e9 7f fa ff ff       	jmp    801050fd <alltraps>

8010567e <vector38>:
.globl vector38
vector38:
  pushl $0
8010567e:	6a 00                	push   $0x0
  pushl $38
80105680:	6a 26                	push   $0x26
  jmp alltraps
80105682:	e9 76 fa ff ff       	jmp    801050fd <alltraps>

80105687 <vector39>:
.globl vector39
vector39:
  pushl $0
80105687:	6a 00                	push   $0x0
  pushl $39
80105689:	6a 27                	push   $0x27
  jmp alltraps
8010568b:	e9 6d fa ff ff       	jmp    801050fd <alltraps>

80105690 <vector40>:
.globl vector40
vector40:
  pushl $0
80105690:	6a 00                	push   $0x0
  pushl $40
80105692:	6a 28                	push   $0x28
  jmp alltraps
80105694:	e9 64 fa ff ff       	jmp    801050fd <alltraps>

80105699 <vector41>:
.globl vector41
vector41:
  pushl $0
80105699:	6a 00                	push   $0x0
  pushl $41
8010569b:	6a 29                	push   $0x29
  jmp alltraps
8010569d:	e9 5b fa ff ff       	jmp    801050fd <alltraps>

801056a2 <vector42>:
.globl vector42
vector42:
  pushl $0
801056a2:	6a 00                	push   $0x0
  pushl $42
801056a4:	6a 2a                	push   $0x2a
  jmp alltraps
801056a6:	e9 52 fa ff ff       	jmp    801050fd <alltraps>

801056ab <vector43>:
.globl vector43
vector43:
  pushl $0
801056ab:	6a 00                	push   $0x0
  pushl $43
801056ad:	6a 2b                	push   $0x2b
  jmp alltraps
801056af:	e9 49 fa ff ff       	jmp    801050fd <alltraps>

801056b4 <vector44>:
.globl vector44
vector44:
  pushl $0
801056b4:	6a 00                	push   $0x0
  pushl $44
801056b6:	6a 2c                	push   $0x2c
  jmp alltraps
801056b8:	e9 40 fa ff ff       	jmp    801050fd <alltraps>

801056bd <vector45>:
.globl vector45
vector45:
  pushl $0
801056bd:	6a 00                	push   $0x0
  pushl $45
801056bf:	6a 2d                	push   $0x2d
  jmp alltraps
801056c1:	e9 37 fa ff ff       	jmp    801050fd <alltraps>

801056c6 <vector46>:
.globl vector46
vector46:
  pushl $0
801056c6:	6a 00                	push   $0x0
  pushl $46
801056c8:	6a 2e                	push   $0x2e
  jmp alltraps
801056ca:	e9 2e fa ff ff       	jmp    801050fd <alltraps>

801056cf <vector47>:
.globl vector47
vector47:
  pushl $0
801056cf:	6a 00                	push   $0x0
  pushl $47
801056d1:	6a 2f                	push   $0x2f
  jmp alltraps
801056d3:	e9 25 fa ff ff       	jmp    801050fd <alltraps>

801056d8 <vector48>:
.globl vector48
vector48:
  pushl $0
801056d8:	6a 00                	push   $0x0
  pushl $48
801056da:	6a 30                	push   $0x30
  jmp alltraps
801056dc:	e9 1c fa ff ff       	jmp    801050fd <alltraps>

801056e1 <vector49>:
.globl vector49
vector49:
  pushl $0
801056e1:	6a 00                	push   $0x0
  pushl $49
801056e3:	6a 31                	push   $0x31
  jmp alltraps
801056e5:	e9 13 fa ff ff       	jmp    801050fd <alltraps>

801056ea <vector50>:
.globl vector50
vector50:
  pushl $0
801056ea:	6a 00                	push   $0x0
  pushl $50
801056ec:	6a 32                	push   $0x32
  jmp alltraps
801056ee:	e9 0a fa ff ff       	jmp    801050fd <alltraps>

801056f3 <vector51>:
.globl vector51
vector51:
  pushl $0
801056f3:	6a 00                	push   $0x0
  pushl $51
801056f5:	6a 33                	push   $0x33
  jmp alltraps
801056f7:	e9 01 fa ff ff       	jmp    801050fd <alltraps>

801056fc <vector52>:
.globl vector52
vector52:
  pushl $0
801056fc:	6a 00                	push   $0x0
  pushl $52
801056fe:	6a 34                	push   $0x34
  jmp alltraps
80105700:	e9 f8 f9 ff ff       	jmp    801050fd <alltraps>

80105705 <vector53>:
.globl vector53
vector53:
  pushl $0
80105705:	6a 00                	push   $0x0
  pushl $53
80105707:	6a 35                	push   $0x35
  jmp alltraps
80105709:	e9 ef f9 ff ff       	jmp    801050fd <alltraps>

8010570e <vector54>:
.globl vector54
vector54:
  pushl $0
8010570e:	6a 00                	push   $0x0
  pushl $54
80105710:	6a 36                	push   $0x36
  jmp alltraps
80105712:	e9 e6 f9 ff ff       	jmp    801050fd <alltraps>

80105717 <vector55>:
.globl vector55
vector55:
  pushl $0
80105717:	6a 00                	push   $0x0
  pushl $55
80105719:	6a 37                	push   $0x37
  jmp alltraps
8010571b:	e9 dd f9 ff ff       	jmp    801050fd <alltraps>

80105720 <vector56>:
.globl vector56
vector56:
  pushl $0
80105720:	6a 00                	push   $0x0
  pushl $56
80105722:	6a 38                	push   $0x38
  jmp alltraps
80105724:	e9 d4 f9 ff ff       	jmp    801050fd <alltraps>

80105729 <vector57>:
.globl vector57
vector57:
  pushl $0
80105729:	6a 00                	push   $0x0
  pushl $57
8010572b:	6a 39                	push   $0x39
  jmp alltraps
8010572d:	e9 cb f9 ff ff       	jmp    801050fd <alltraps>

80105732 <vector58>:
.globl vector58
vector58:
  pushl $0
80105732:	6a 00                	push   $0x0
  pushl $58
80105734:	6a 3a                	push   $0x3a
  jmp alltraps
80105736:	e9 c2 f9 ff ff       	jmp    801050fd <alltraps>

8010573b <vector59>:
.globl vector59
vector59:
  pushl $0
8010573b:	6a 00                	push   $0x0
  pushl $59
8010573d:	6a 3b                	push   $0x3b
  jmp alltraps
8010573f:	e9 b9 f9 ff ff       	jmp    801050fd <alltraps>

80105744 <vector60>:
.globl vector60
vector60:
  pushl $0
80105744:	6a 00                	push   $0x0
  pushl $60
80105746:	6a 3c                	push   $0x3c
  jmp alltraps
80105748:	e9 b0 f9 ff ff       	jmp    801050fd <alltraps>

8010574d <vector61>:
.globl vector61
vector61:
  pushl $0
8010574d:	6a 00                	push   $0x0
  pushl $61
8010574f:	6a 3d                	push   $0x3d
  jmp alltraps
80105751:	e9 a7 f9 ff ff       	jmp    801050fd <alltraps>

80105756 <vector62>:
.globl vector62
vector62:
  pushl $0
80105756:	6a 00                	push   $0x0
  pushl $62
80105758:	6a 3e                	push   $0x3e
  jmp alltraps
8010575a:	e9 9e f9 ff ff       	jmp    801050fd <alltraps>

8010575f <vector63>:
.globl vector63
vector63:
  pushl $0
8010575f:	6a 00                	push   $0x0
  pushl $63
80105761:	6a 3f                	push   $0x3f
  jmp alltraps
80105763:	e9 95 f9 ff ff       	jmp    801050fd <alltraps>

80105768 <vector64>:
.globl vector64
vector64:
  pushl $0
80105768:	6a 00                	push   $0x0
  pushl $64
8010576a:	6a 40                	push   $0x40
  jmp alltraps
8010576c:	e9 8c f9 ff ff       	jmp    801050fd <alltraps>

80105771 <vector65>:
.globl vector65
vector65:
  pushl $0
80105771:	6a 00                	push   $0x0
  pushl $65
80105773:	6a 41                	push   $0x41
  jmp alltraps
80105775:	e9 83 f9 ff ff       	jmp    801050fd <alltraps>

8010577a <vector66>:
.globl vector66
vector66:
  pushl $0
8010577a:	6a 00                	push   $0x0
  pushl $66
8010577c:	6a 42                	push   $0x42
  jmp alltraps
8010577e:	e9 7a f9 ff ff       	jmp    801050fd <alltraps>

80105783 <vector67>:
.globl vector67
vector67:
  pushl $0
80105783:	6a 00                	push   $0x0
  pushl $67
80105785:	6a 43                	push   $0x43
  jmp alltraps
80105787:	e9 71 f9 ff ff       	jmp    801050fd <alltraps>

8010578c <vector68>:
.globl vector68
vector68:
  pushl $0
8010578c:	6a 00                	push   $0x0
  pushl $68
8010578e:	6a 44                	push   $0x44
  jmp alltraps
80105790:	e9 68 f9 ff ff       	jmp    801050fd <alltraps>

80105795 <vector69>:
.globl vector69
vector69:
  pushl $0
80105795:	6a 00                	push   $0x0
  pushl $69
80105797:	6a 45                	push   $0x45
  jmp alltraps
80105799:	e9 5f f9 ff ff       	jmp    801050fd <alltraps>

8010579e <vector70>:
.globl vector70
vector70:
  pushl $0
8010579e:	6a 00                	push   $0x0
  pushl $70
801057a0:	6a 46                	push   $0x46
  jmp alltraps
801057a2:	e9 56 f9 ff ff       	jmp    801050fd <alltraps>

801057a7 <vector71>:
.globl vector71
vector71:
  pushl $0
801057a7:	6a 00                	push   $0x0
  pushl $71
801057a9:	6a 47                	push   $0x47
  jmp alltraps
801057ab:	e9 4d f9 ff ff       	jmp    801050fd <alltraps>

801057b0 <vector72>:
.globl vector72
vector72:
  pushl $0
801057b0:	6a 00                	push   $0x0
  pushl $72
801057b2:	6a 48                	push   $0x48
  jmp alltraps
801057b4:	e9 44 f9 ff ff       	jmp    801050fd <alltraps>

801057b9 <vector73>:
.globl vector73
vector73:
  pushl $0
801057b9:	6a 00                	push   $0x0
  pushl $73
801057bb:	6a 49                	push   $0x49
  jmp alltraps
801057bd:	e9 3b f9 ff ff       	jmp    801050fd <alltraps>

801057c2 <vector74>:
.globl vector74
vector74:
  pushl $0
801057c2:	6a 00                	push   $0x0
  pushl $74
801057c4:	6a 4a                	push   $0x4a
  jmp alltraps
801057c6:	e9 32 f9 ff ff       	jmp    801050fd <alltraps>

801057cb <vector75>:
.globl vector75
vector75:
  pushl $0
801057cb:	6a 00                	push   $0x0
  pushl $75
801057cd:	6a 4b                	push   $0x4b
  jmp alltraps
801057cf:	e9 29 f9 ff ff       	jmp    801050fd <alltraps>

801057d4 <vector76>:
.globl vector76
vector76:
  pushl $0
801057d4:	6a 00                	push   $0x0
  pushl $76
801057d6:	6a 4c                	push   $0x4c
  jmp alltraps
801057d8:	e9 20 f9 ff ff       	jmp    801050fd <alltraps>

801057dd <vector77>:
.globl vector77
vector77:
  pushl $0
801057dd:	6a 00                	push   $0x0
  pushl $77
801057df:	6a 4d                	push   $0x4d
  jmp alltraps
801057e1:	e9 17 f9 ff ff       	jmp    801050fd <alltraps>

801057e6 <vector78>:
.globl vector78
vector78:
  pushl $0
801057e6:	6a 00                	push   $0x0
  pushl $78
801057e8:	6a 4e                	push   $0x4e
  jmp alltraps
801057ea:	e9 0e f9 ff ff       	jmp    801050fd <alltraps>

801057ef <vector79>:
.globl vector79
vector79:
  pushl $0
801057ef:	6a 00                	push   $0x0
  pushl $79
801057f1:	6a 4f                	push   $0x4f
  jmp alltraps
801057f3:	e9 05 f9 ff ff       	jmp    801050fd <alltraps>

801057f8 <vector80>:
.globl vector80
vector80:
  pushl $0
801057f8:	6a 00                	push   $0x0
  pushl $80
801057fa:	6a 50                	push   $0x50
  jmp alltraps
801057fc:	e9 fc f8 ff ff       	jmp    801050fd <alltraps>

80105801 <vector81>:
.globl vector81
vector81:
  pushl $0
80105801:	6a 00                	push   $0x0
  pushl $81
80105803:	6a 51                	push   $0x51
  jmp alltraps
80105805:	e9 f3 f8 ff ff       	jmp    801050fd <alltraps>

8010580a <vector82>:
.globl vector82
vector82:
  pushl $0
8010580a:	6a 00                	push   $0x0
  pushl $82
8010580c:	6a 52                	push   $0x52
  jmp alltraps
8010580e:	e9 ea f8 ff ff       	jmp    801050fd <alltraps>

80105813 <vector83>:
.globl vector83
vector83:
  pushl $0
80105813:	6a 00                	push   $0x0
  pushl $83
80105815:	6a 53                	push   $0x53
  jmp alltraps
80105817:	e9 e1 f8 ff ff       	jmp    801050fd <alltraps>

8010581c <vector84>:
.globl vector84
vector84:
  pushl $0
8010581c:	6a 00                	push   $0x0
  pushl $84
8010581e:	6a 54                	push   $0x54
  jmp alltraps
80105820:	e9 d8 f8 ff ff       	jmp    801050fd <alltraps>

80105825 <vector85>:
.globl vector85
vector85:
  pushl $0
80105825:	6a 00                	push   $0x0
  pushl $85
80105827:	6a 55                	push   $0x55
  jmp alltraps
80105829:	e9 cf f8 ff ff       	jmp    801050fd <alltraps>

8010582e <vector86>:
.globl vector86
vector86:
  pushl $0
8010582e:	6a 00                	push   $0x0
  pushl $86
80105830:	6a 56                	push   $0x56
  jmp alltraps
80105832:	e9 c6 f8 ff ff       	jmp    801050fd <alltraps>

80105837 <vector87>:
.globl vector87
vector87:
  pushl $0
80105837:	6a 00                	push   $0x0
  pushl $87
80105839:	6a 57                	push   $0x57
  jmp alltraps
8010583b:	e9 bd f8 ff ff       	jmp    801050fd <alltraps>

80105840 <vector88>:
.globl vector88
vector88:
  pushl $0
80105840:	6a 00                	push   $0x0
  pushl $88
80105842:	6a 58                	push   $0x58
  jmp alltraps
80105844:	e9 b4 f8 ff ff       	jmp    801050fd <alltraps>

80105849 <vector89>:
.globl vector89
vector89:
  pushl $0
80105849:	6a 00                	push   $0x0
  pushl $89
8010584b:	6a 59                	push   $0x59
  jmp alltraps
8010584d:	e9 ab f8 ff ff       	jmp    801050fd <alltraps>

80105852 <vector90>:
.globl vector90
vector90:
  pushl $0
80105852:	6a 00                	push   $0x0
  pushl $90
80105854:	6a 5a                	push   $0x5a
  jmp alltraps
80105856:	e9 a2 f8 ff ff       	jmp    801050fd <alltraps>

8010585b <vector91>:
.globl vector91
vector91:
  pushl $0
8010585b:	6a 00                	push   $0x0
  pushl $91
8010585d:	6a 5b                	push   $0x5b
  jmp alltraps
8010585f:	e9 99 f8 ff ff       	jmp    801050fd <alltraps>

80105864 <vector92>:
.globl vector92
vector92:
  pushl $0
80105864:	6a 00                	push   $0x0
  pushl $92
80105866:	6a 5c                	push   $0x5c
  jmp alltraps
80105868:	e9 90 f8 ff ff       	jmp    801050fd <alltraps>

8010586d <vector93>:
.globl vector93
vector93:
  pushl $0
8010586d:	6a 00                	push   $0x0
  pushl $93
8010586f:	6a 5d                	push   $0x5d
  jmp alltraps
80105871:	e9 87 f8 ff ff       	jmp    801050fd <alltraps>

80105876 <vector94>:
.globl vector94
vector94:
  pushl $0
80105876:	6a 00                	push   $0x0
  pushl $94
80105878:	6a 5e                	push   $0x5e
  jmp alltraps
8010587a:	e9 7e f8 ff ff       	jmp    801050fd <alltraps>

8010587f <vector95>:
.globl vector95
vector95:
  pushl $0
8010587f:	6a 00                	push   $0x0
  pushl $95
80105881:	6a 5f                	push   $0x5f
  jmp alltraps
80105883:	e9 75 f8 ff ff       	jmp    801050fd <alltraps>

80105888 <vector96>:
.globl vector96
vector96:
  pushl $0
80105888:	6a 00                	push   $0x0
  pushl $96
8010588a:	6a 60                	push   $0x60
  jmp alltraps
8010588c:	e9 6c f8 ff ff       	jmp    801050fd <alltraps>

80105891 <vector97>:
.globl vector97
vector97:
  pushl $0
80105891:	6a 00                	push   $0x0
  pushl $97
80105893:	6a 61                	push   $0x61
  jmp alltraps
80105895:	e9 63 f8 ff ff       	jmp    801050fd <alltraps>

8010589a <vector98>:
.globl vector98
vector98:
  pushl $0
8010589a:	6a 00                	push   $0x0
  pushl $98
8010589c:	6a 62                	push   $0x62
  jmp alltraps
8010589e:	e9 5a f8 ff ff       	jmp    801050fd <alltraps>

801058a3 <vector99>:
.globl vector99
vector99:
  pushl $0
801058a3:	6a 00                	push   $0x0
  pushl $99
801058a5:	6a 63                	push   $0x63
  jmp alltraps
801058a7:	e9 51 f8 ff ff       	jmp    801050fd <alltraps>

801058ac <vector100>:
.globl vector100
vector100:
  pushl $0
801058ac:	6a 00                	push   $0x0
  pushl $100
801058ae:	6a 64                	push   $0x64
  jmp alltraps
801058b0:	e9 48 f8 ff ff       	jmp    801050fd <alltraps>

801058b5 <vector101>:
.globl vector101
vector101:
  pushl $0
801058b5:	6a 00                	push   $0x0
  pushl $101
801058b7:	6a 65                	push   $0x65
  jmp alltraps
801058b9:	e9 3f f8 ff ff       	jmp    801050fd <alltraps>

801058be <vector102>:
.globl vector102
vector102:
  pushl $0
801058be:	6a 00                	push   $0x0
  pushl $102
801058c0:	6a 66                	push   $0x66
  jmp alltraps
801058c2:	e9 36 f8 ff ff       	jmp    801050fd <alltraps>

801058c7 <vector103>:
.globl vector103
vector103:
  pushl $0
801058c7:	6a 00                	push   $0x0
  pushl $103
801058c9:	6a 67                	push   $0x67
  jmp alltraps
801058cb:	e9 2d f8 ff ff       	jmp    801050fd <alltraps>

801058d0 <vector104>:
.globl vector104
vector104:
  pushl $0
801058d0:	6a 00                	push   $0x0
  pushl $104
801058d2:	6a 68                	push   $0x68
  jmp alltraps
801058d4:	e9 24 f8 ff ff       	jmp    801050fd <alltraps>

801058d9 <vector105>:
.globl vector105
vector105:
  pushl $0
801058d9:	6a 00                	push   $0x0
  pushl $105
801058db:	6a 69                	push   $0x69
  jmp alltraps
801058dd:	e9 1b f8 ff ff       	jmp    801050fd <alltraps>

801058e2 <vector106>:
.globl vector106
vector106:
  pushl $0
801058e2:	6a 00                	push   $0x0
  pushl $106
801058e4:	6a 6a                	push   $0x6a
  jmp alltraps
801058e6:	e9 12 f8 ff ff       	jmp    801050fd <alltraps>

801058eb <vector107>:
.globl vector107
vector107:
  pushl $0
801058eb:	6a 00                	push   $0x0
  pushl $107
801058ed:	6a 6b                	push   $0x6b
  jmp alltraps
801058ef:	e9 09 f8 ff ff       	jmp    801050fd <alltraps>

801058f4 <vector108>:
.globl vector108
vector108:
  pushl $0
801058f4:	6a 00                	push   $0x0
  pushl $108
801058f6:	6a 6c                	push   $0x6c
  jmp alltraps
801058f8:	e9 00 f8 ff ff       	jmp    801050fd <alltraps>

801058fd <vector109>:
.globl vector109
vector109:
  pushl $0
801058fd:	6a 00                	push   $0x0
  pushl $109
801058ff:	6a 6d                	push   $0x6d
  jmp alltraps
80105901:	e9 f7 f7 ff ff       	jmp    801050fd <alltraps>

80105906 <vector110>:
.globl vector110
vector110:
  pushl $0
80105906:	6a 00                	push   $0x0
  pushl $110
80105908:	6a 6e                	push   $0x6e
  jmp alltraps
8010590a:	e9 ee f7 ff ff       	jmp    801050fd <alltraps>

8010590f <vector111>:
.globl vector111
vector111:
  pushl $0
8010590f:	6a 00                	push   $0x0
  pushl $111
80105911:	6a 6f                	push   $0x6f
  jmp alltraps
80105913:	e9 e5 f7 ff ff       	jmp    801050fd <alltraps>

80105918 <vector112>:
.globl vector112
vector112:
  pushl $0
80105918:	6a 00                	push   $0x0
  pushl $112
8010591a:	6a 70                	push   $0x70
  jmp alltraps
8010591c:	e9 dc f7 ff ff       	jmp    801050fd <alltraps>

80105921 <vector113>:
.globl vector113
vector113:
  pushl $0
80105921:	6a 00                	push   $0x0
  pushl $113
80105923:	6a 71                	push   $0x71
  jmp alltraps
80105925:	e9 d3 f7 ff ff       	jmp    801050fd <alltraps>

8010592a <vector114>:
.globl vector114
vector114:
  pushl $0
8010592a:	6a 00                	push   $0x0
  pushl $114
8010592c:	6a 72                	push   $0x72
  jmp alltraps
8010592e:	e9 ca f7 ff ff       	jmp    801050fd <alltraps>

80105933 <vector115>:
.globl vector115
vector115:
  pushl $0
80105933:	6a 00                	push   $0x0
  pushl $115
80105935:	6a 73                	push   $0x73
  jmp alltraps
80105937:	e9 c1 f7 ff ff       	jmp    801050fd <alltraps>

8010593c <vector116>:
.globl vector116
vector116:
  pushl $0
8010593c:	6a 00                	push   $0x0
  pushl $116
8010593e:	6a 74                	push   $0x74
  jmp alltraps
80105940:	e9 b8 f7 ff ff       	jmp    801050fd <alltraps>

80105945 <vector117>:
.globl vector117
vector117:
  pushl $0
80105945:	6a 00                	push   $0x0
  pushl $117
80105947:	6a 75                	push   $0x75
  jmp alltraps
80105949:	e9 af f7 ff ff       	jmp    801050fd <alltraps>

8010594e <vector118>:
.globl vector118
vector118:
  pushl $0
8010594e:	6a 00                	push   $0x0
  pushl $118
80105950:	6a 76                	push   $0x76
  jmp alltraps
80105952:	e9 a6 f7 ff ff       	jmp    801050fd <alltraps>

80105957 <vector119>:
.globl vector119
vector119:
  pushl $0
80105957:	6a 00                	push   $0x0
  pushl $119
80105959:	6a 77                	push   $0x77
  jmp alltraps
8010595b:	e9 9d f7 ff ff       	jmp    801050fd <alltraps>

80105960 <vector120>:
.globl vector120
vector120:
  pushl $0
80105960:	6a 00                	push   $0x0
  pushl $120
80105962:	6a 78                	push   $0x78
  jmp alltraps
80105964:	e9 94 f7 ff ff       	jmp    801050fd <alltraps>

80105969 <vector121>:
.globl vector121
vector121:
  pushl $0
80105969:	6a 00                	push   $0x0
  pushl $121
8010596b:	6a 79                	push   $0x79
  jmp alltraps
8010596d:	e9 8b f7 ff ff       	jmp    801050fd <alltraps>

80105972 <vector122>:
.globl vector122
vector122:
  pushl $0
80105972:	6a 00                	push   $0x0
  pushl $122
80105974:	6a 7a                	push   $0x7a
  jmp alltraps
80105976:	e9 82 f7 ff ff       	jmp    801050fd <alltraps>

8010597b <vector123>:
.globl vector123
vector123:
  pushl $0
8010597b:	6a 00                	push   $0x0
  pushl $123
8010597d:	6a 7b                	push   $0x7b
  jmp alltraps
8010597f:	e9 79 f7 ff ff       	jmp    801050fd <alltraps>

80105984 <vector124>:
.globl vector124
vector124:
  pushl $0
80105984:	6a 00                	push   $0x0
  pushl $124
80105986:	6a 7c                	push   $0x7c
  jmp alltraps
80105988:	e9 70 f7 ff ff       	jmp    801050fd <alltraps>

8010598d <vector125>:
.globl vector125
vector125:
  pushl $0
8010598d:	6a 00                	push   $0x0
  pushl $125
8010598f:	6a 7d                	push   $0x7d
  jmp alltraps
80105991:	e9 67 f7 ff ff       	jmp    801050fd <alltraps>

80105996 <vector126>:
.globl vector126
vector126:
  pushl $0
80105996:	6a 00                	push   $0x0
  pushl $126
80105998:	6a 7e                	push   $0x7e
  jmp alltraps
8010599a:	e9 5e f7 ff ff       	jmp    801050fd <alltraps>

8010599f <vector127>:
.globl vector127
vector127:
  pushl $0
8010599f:	6a 00                	push   $0x0
  pushl $127
801059a1:	6a 7f                	push   $0x7f
  jmp alltraps
801059a3:	e9 55 f7 ff ff       	jmp    801050fd <alltraps>

801059a8 <vector128>:
.globl vector128
vector128:
  pushl $0
801059a8:	6a 00                	push   $0x0
  pushl $128
801059aa:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801059af:	e9 49 f7 ff ff       	jmp    801050fd <alltraps>

801059b4 <vector129>:
.globl vector129
vector129:
  pushl $0
801059b4:	6a 00                	push   $0x0
  pushl $129
801059b6:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801059bb:	e9 3d f7 ff ff       	jmp    801050fd <alltraps>

801059c0 <vector130>:
.globl vector130
vector130:
  pushl $0
801059c0:	6a 00                	push   $0x0
  pushl $130
801059c2:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801059c7:	e9 31 f7 ff ff       	jmp    801050fd <alltraps>

801059cc <vector131>:
.globl vector131
vector131:
  pushl $0
801059cc:	6a 00                	push   $0x0
  pushl $131
801059ce:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801059d3:	e9 25 f7 ff ff       	jmp    801050fd <alltraps>

801059d8 <vector132>:
.globl vector132
vector132:
  pushl $0
801059d8:	6a 00                	push   $0x0
  pushl $132
801059da:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801059df:	e9 19 f7 ff ff       	jmp    801050fd <alltraps>

801059e4 <vector133>:
.globl vector133
vector133:
  pushl $0
801059e4:	6a 00                	push   $0x0
  pushl $133
801059e6:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801059eb:	e9 0d f7 ff ff       	jmp    801050fd <alltraps>

801059f0 <vector134>:
.globl vector134
vector134:
  pushl $0
801059f0:	6a 00                	push   $0x0
  pushl $134
801059f2:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801059f7:	e9 01 f7 ff ff       	jmp    801050fd <alltraps>

801059fc <vector135>:
.globl vector135
vector135:
  pushl $0
801059fc:	6a 00                	push   $0x0
  pushl $135
801059fe:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105a03:	e9 f5 f6 ff ff       	jmp    801050fd <alltraps>

80105a08 <vector136>:
.globl vector136
vector136:
  pushl $0
80105a08:	6a 00                	push   $0x0
  pushl $136
80105a0a:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105a0f:	e9 e9 f6 ff ff       	jmp    801050fd <alltraps>

80105a14 <vector137>:
.globl vector137
vector137:
  pushl $0
80105a14:	6a 00                	push   $0x0
  pushl $137
80105a16:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80105a1b:	e9 dd f6 ff ff       	jmp    801050fd <alltraps>

80105a20 <vector138>:
.globl vector138
vector138:
  pushl $0
80105a20:	6a 00                	push   $0x0
  pushl $138
80105a22:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105a27:	e9 d1 f6 ff ff       	jmp    801050fd <alltraps>

80105a2c <vector139>:
.globl vector139
vector139:
  pushl $0
80105a2c:	6a 00                	push   $0x0
  pushl $139
80105a2e:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105a33:	e9 c5 f6 ff ff       	jmp    801050fd <alltraps>

80105a38 <vector140>:
.globl vector140
vector140:
  pushl $0
80105a38:	6a 00                	push   $0x0
  pushl $140
80105a3a:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105a3f:	e9 b9 f6 ff ff       	jmp    801050fd <alltraps>

80105a44 <vector141>:
.globl vector141
vector141:
  pushl $0
80105a44:	6a 00                	push   $0x0
  pushl $141
80105a46:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105a4b:	e9 ad f6 ff ff       	jmp    801050fd <alltraps>

80105a50 <vector142>:
.globl vector142
vector142:
  pushl $0
80105a50:	6a 00                	push   $0x0
  pushl $142
80105a52:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105a57:	e9 a1 f6 ff ff       	jmp    801050fd <alltraps>

80105a5c <vector143>:
.globl vector143
vector143:
  pushl $0
80105a5c:	6a 00                	push   $0x0
  pushl $143
80105a5e:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105a63:	e9 95 f6 ff ff       	jmp    801050fd <alltraps>

80105a68 <vector144>:
.globl vector144
vector144:
  pushl $0
80105a68:	6a 00                	push   $0x0
  pushl $144
80105a6a:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105a6f:	e9 89 f6 ff ff       	jmp    801050fd <alltraps>

80105a74 <vector145>:
.globl vector145
vector145:
  pushl $0
80105a74:	6a 00                	push   $0x0
  pushl $145
80105a76:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105a7b:	e9 7d f6 ff ff       	jmp    801050fd <alltraps>

80105a80 <vector146>:
.globl vector146
vector146:
  pushl $0
80105a80:	6a 00                	push   $0x0
  pushl $146
80105a82:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105a87:	e9 71 f6 ff ff       	jmp    801050fd <alltraps>

80105a8c <vector147>:
.globl vector147
vector147:
  pushl $0
80105a8c:	6a 00                	push   $0x0
  pushl $147
80105a8e:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105a93:	e9 65 f6 ff ff       	jmp    801050fd <alltraps>

80105a98 <vector148>:
.globl vector148
vector148:
  pushl $0
80105a98:	6a 00                	push   $0x0
  pushl $148
80105a9a:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105a9f:	e9 59 f6 ff ff       	jmp    801050fd <alltraps>

80105aa4 <vector149>:
.globl vector149
vector149:
  pushl $0
80105aa4:	6a 00                	push   $0x0
  pushl $149
80105aa6:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80105aab:	e9 4d f6 ff ff       	jmp    801050fd <alltraps>

80105ab0 <vector150>:
.globl vector150
vector150:
  pushl $0
80105ab0:	6a 00                	push   $0x0
  pushl $150
80105ab2:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80105ab7:	e9 41 f6 ff ff       	jmp    801050fd <alltraps>

80105abc <vector151>:
.globl vector151
vector151:
  pushl $0
80105abc:	6a 00                	push   $0x0
  pushl $151
80105abe:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105ac3:	e9 35 f6 ff ff       	jmp    801050fd <alltraps>

80105ac8 <vector152>:
.globl vector152
vector152:
  pushl $0
80105ac8:	6a 00                	push   $0x0
  pushl $152
80105aca:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105acf:	e9 29 f6 ff ff       	jmp    801050fd <alltraps>

80105ad4 <vector153>:
.globl vector153
vector153:
  pushl $0
80105ad4:	6a 00                	push   $0x0
  pushl $153
80105ad6:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105adb:	e9 1d f6 ff ff       	jmp    801050fd <alltraps>

80105ae0 <vector154>:
.globl vector154
vector154:
  pushl $0
80105ae0:	6a 00                	push   $0x0
  pushl $154
80105ae2:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105ae7:	e9 11 f6 ff ff       	jmp    801050fd <alltraps>

80105aec <vector155>:
.globl vector155
vector155:
  pushl $0
80105aec:	6a 00                	push   $0x0
  pushl $155
80105aee:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105af3:	e9 05 f6 ff ff       	jmp    801050fd <alltraps>

80105af8 <vector156>:
.globl vector156
vector156:
  pushl $0
80105af8:	6a 00                	push   $0x0
  pushl $156
80105afa:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105aff:	e9 f9 f5 ff ff       	jmp    801050fd <alltraps>

80105b04 <vector157>:
.globl vector157
vector157:
  pushl $0
80105b04:	6a 00                	push   $0x0
  pushl $157
80105b06:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105b0b:	e9 ed f5 ff ff       	jmp    801050fd <alltraps>

80105b10 <vector158>:
.globl vector158
vector158:
  pushl $0
80105b10:	6a 00                	push   $0x0
  pushl $158
80105b12:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105b17:	e9 e1 f5 ff ff       	jmp    801050fd <alltraps>

80105b1c <vector159>:
.globl vector159
vector159:
  pushl $0
80105b1c:	6a 00                	push   $0x0
  pushl $159
80105b1e:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105b23:	e9 d5 f5 ff ff       	jmp    801050fd <alltraps>

80105b28 <vector160>:
.globl vector160
vector160:
  pushl $0
80105b28:	6a 00                	push   $0x0
  pushl $160
80105b2a:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105b2f:	e9 c9 f5 ff ff       	jmp    801050fd <alltraps>

80105b34 <vector161>:
.globl vector161
vector161:
  pushl $0
80105b34:	6a 00                	push   $0x0
  pushl $161
80105b36:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105b3b:	e9 bd f5 ff ff       	jmp    801050fd <alltraps>

80105b40 <vector162>:
.globl vector162
vector162:
  pushl $0
80105b40:	6a 00                	push   $0x0
  pushl $162
80105b42:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105b47:	e9 b1 f5 ff ff       	jmp    801050fd <alltraps>

80105b4c <vector163>:
.globl vector163
vector163:
  pushl $0
80105b4c:	6a 00                	push   $0x0
  pushl $163
80105b4e:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105b53:	e9 a5 f5 ff ff       	jmp    801050fd <alltraps>

80105b58 <vector164>:
.globl vector164
vector164:
  pushl $0
80105b58:	6a 00                	push   $0x0
  pushl $164
80105b5a:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105b5f:	e9 99 f5 ff ff       	jmp    801050fd <alltraps>

80105b64 <vector165>:
.globl vector165
vector165:
  pushl $0
80105b64:	6a 00                	push   $0x0
  pushl $165
80105b66:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105b6b:	e9 8d f5 ff ff       	jmp    801050fd <alltraps>

80105b70 <vector166>:
.globl vector166
vector166:
  pushl $0
80105b70:	6a 00                	push   $0x0
  pushl $166
80105b72:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105b77:	e9 81 f5 ff ff       	jmp    801050fd <alltraps>

80105b7c <vector167>:
.globl vector167
vector167:
  pushl $0
80105b7c:	6a 00                	push   $0x0
  pushl $167
80105b7e:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105b83:	e9 75 f5 ff ff       	jmp    801050fd <alltraps>

80105b88 <vector168>:
.globl vector168
vector168:
  pushl $0
80105b88:	6a 00                	push   $0x0
  pushl $168
80105b8a:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105b8f:	e9 69 f5 ff ff       	jmp    801050fd <alltraps>

80105b94 <vector169>:
.globl vector169
vector169:
  pushl $0
80105b94:	6a 00                	push   $0x0
  pushl $169
80105b96:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105b9b:	e9 5d f5 ff ff       	jmp    801050fd <alltraps>

80105ba0 <vector170>:
.globl vector170
vector170:
  pushl $0
80105ba0:	6a 00                	push   $0x0
  pushl $170
80105ba2:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105ba7:	e9 51 f5 ff ff       	jmp    801050fd <alltraps>

80105bac <vector171>:
.globl vector171
vector171:
  pushl $0
80105bac:	6a 00                	push   $0x0
  pushl $171
80105bae:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105bb3:	e9 45 f5 ff ff       	jmp    801050fd <alltraps>

80105bb8 <vector172>:
.globl vector172
vector172:
  pushl $0
80105bb8:	6a 00                	push   $0x0
  pushl $172
80105bba:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105bbf:	e9 39 f5 ff ff       	jmp    801050fd <alltraps>

80105bc4 <vector173>:
.globl vector173
vector173:
  pushl $0
80105bc4:	6a 00                	push   $0x0
  pushl $173
80105bc6:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105bcb:	e9 2d f5 ff ff       	jmp    801050fd <alltraps>

80105bd0 <vector174>:
.globl vector174
vector174:
  pushl $0
80105bd0:	6a 00                	push   $0x0
  pushl $174
80105bd2:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105bd7:	e9 21 f5 ff ff       	jmp    801050fd <alltraps>

80105bdc <vector175>:
.globl vector175
vector175:
  pushl $0
80105bdc:	6a 00                	push   $0x0
  pushl $175
80105bde:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105be3:	e9 15 f5 ff ff       	jmp    801050fd <alltraps>

80105be8 <vector176>:
.globl vector176
vector176:
  pushl $0
80105be8:	6a 00                	push   $0x0
  pushl $176
80105bea:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105bef:	e9 09 f5 ff ff       	jmp    801050fd <alltraps>

80105bf4 <vector177>:
.globl vector177
vector177:
  pushl $0
80105bf4:	6a 00                	push   $0x0
  pushl $177
80105bf6:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105bfb:	e9 fd f4 ff ff       	jmp    801050fd <alltraps>

80105c00 <vector178>:
.globl vector178
vector178:
  pushl $0
80105c00:	6a 00                	push   $0x0
  pushl $178
80105c02:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105c07:	e9 f1 f4 ff ff       	jmp    801050fd <alltraps>

80105c0c <vector179>:
.globl vector179
vector179:
  pushl $0
80105c0c:	6a 00                	push   $0x0
  pushl $179
80105c0e:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105c13:	e9 e5 f4 ff ff       	jmp    801050fd <alltraps>

80105c18 <vector180>:
.globl vector180
vector180:
  pushl $0
80105c18:	6a 00                	push   $0x0
  pushl $180
80105c1a:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105c1f:	e9 d9 f4 ff ff       	jmp    801050fd <alltraps>

80105c24 <vector181>:
.globl vector181
vector181:
  pushl $0
80105c24:	6a 00                	push   $0x0
  pushl $181
80105c26:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105c2b:	e9 cd f4 ff ff       	jmp    801050fd <alltraps>

80105c30 <vector182>:
.globl vector182
vector182:
  pushl $0
80105c30:	6a 00                	push   $0x0
  pushl $182
80105c32:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105c37:	e9 c1 f4 ff ff       	jmp    801050fd <alltraps>

80105c3c <vector183>:
.globl vector183
vector183:
  pushl $0
80105c3c:	6a 00                	push   $0x0
  pushl $183
80105c3e:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105c43:	e9 b5 f4 ff ff       	jmp    801050fd <alltraps>

80105c48 <vector184>:
.globl vector184
vector184:
  pushl $0
80105c48:	6a 00                	push   $0x0
  pushl $184
80105c4a:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105c4f:	e9 a9 f4 ff ff       	jmp    801050fd <alltraps>

80105c54 <vector185>:
.globl vector185
vector185:
  pushl $0
80105c54:	6a 00                	push   $0x0
  pushl $185
80105c56:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105c5b:	e9 9d f4 ff ff       	jmp    801050fd <alltraps>

80105c60 <vector186>:
.globl vector186
vector186:
  pushl $0
80105c60:	6a 00                	push   $0x0
  pushl $186
80105c62:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105c67:	e9 91 f4 ff ff       	jmp    801050fd <alltraps>

80105c6c <vector187>:
.globl vector187
vector187:
  pushl $0
80105c6c:	6a 00                	push   $0x0
  pushl $187
80105c6e:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105c73:	e9 85 f4 ff ff       	jmp    801050fd <alltraps>

80105c78 <vector188>:
.globl vector188
vector188:
  pushl $0
80105c78:	6a 00                	push   $0x0
  pushl $188
80105c7a:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105c7f:	e9 79 f4 ff ff       	jmp    801050fd <alltraps>

80105c84 <vector189>:
.globl vector189
vector189:
  pushl $0
80105c84:	6a 00                	push   $0x0
  pushl $189
80105c86:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105c8b:	e9 6d f4 ff ff       	jmp    801050fd <alltraps>

80105c90 <vector190>:
.globl vector190
vector190:
  pushl $0
80105c90:	6a 00                	push   $0x0
  pushl $190
80105c92:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105c97:	e9 61 f4 ff ff       	jmp    801050fd <alltraps>

80105c9c <vector191>:
.globl vector191
vector191:
  pushl $0
80105c9c:	6a 00                	push   $0x0
  pushl $191
80105c9e:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105ca3:	e9 55 f4 ff ff       	jmp    801050fd <alltraps>

80105ca8 <vector192>:
.globl vector192
vector192:
  pushl $0
80105ca8:	6a 00                	push   $0x0
  pushl $192
80105caa:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105caf:	e9 49 f4 ff ff       	jmp    801050fd <alltraps>

80105cb4 <vector193>:
.globl vector193
vector193:
  pushl $0
80105cb4:	6a 00                	push   $0x0
  pushl $193
80105cb6:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105cbb:	e9 3d f4 ff ff       	jmp    801050fd <alltraps>

80105cc0 <vector194>:
.globl vector194
vector194:
  pushl $0
80105cc0:	6a 00                	push   $0x0
  pushl $194
80105cc2:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105cc7:	e9 31 f4 ff ff       	jmp    801050fd <alltraps>

80105ccc <vector195>:
.globl vector195
vector195:
  pushl $0
80105ccc:	6a 00                	push   $0x0
  pushl $195
80105cce:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105cd3:	e9 25 f4 ff ff       	jmp    801050fd <alltraps>

80105cd8 <vector196>:
.globl vector196
vector196:
  pushl $0
80105cd8:	6a 00                	push   $0x0
  pushl $196
80105cda:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105cdf:	e9 19 f4 ff ff       	jmp    801050fd <alltraps>

80105ce4 <vector197>:
.globl vector197
vector197:
  pushl $0
80105ce4:	6a 00                	push   $0x0
  pushl $197
80105ce6:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105ceb:	e9 0d f4 ff ff       	jmp    801050fd <alltraps>

80105cf0 <vector198>:
.globl vector198
vector198:
  pushl $0
80105cf0:	6a 00                	push   $0x0
  pushl $198
80105cf2:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105cf7:	e9 01 f4 ff ff       	jmp    801050fd <alltraps>

80105cfc <vector199>:
.globl vector199
vector199:
  pushl $0
80105cfc:	6a 00                	push   $0x0
  pushl $199
80105cfe:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105d03:	e9 f5 f3 ff ff       	jmp    801050fd <alltraps>

80105d08 <vector200>:
.globl vector200
vector200:
  pushl $0
80105d08:	6a 00                	push   $0x0
  pushl $200
80105d0a:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105d0f:	e9 e9 f3 ff ff       	jmp    801050fd <alltraps>

80105d14 <vector201>:
.globl vector201
vector201:
  pushl $0
80105d14:	6a 00                	push   $0x0
  pushl $201
80105d16:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105d1b:	e9 dd f3 ff ff       	jmp    801050fd <alltraps>

80105d20 <vector202>:
.globl vector202
vector202:
  pushl $0
80105d20:	6a 00                	push   $0x0
  pushl $202
80105d22:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105d27:	e9 d1 f3 ff ff       	jmp    801050fd <alltraps>

80105d2c <vector203>:
.globl vector203
vector203:
  pushl $0
80105d2c:	6a 00                	push   $0x0
  pushl $203
80105d2e:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105d33:	e9 c5 f3 ff ff       	jmp    801050fd <alltraps>

80105d38 <vector204>:
.globl vector204
vector204:
  pushl $0
80105d38:	6a 00                	push   $0x0
  pushl $204
80105d3a:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105d3f:	e9 b9 f3 ff ff       	jmp    801050fd <alltraps>

80105d44 <vector205>:
.globl vector205
vector205:
  pushl $0
80105d44:	6a 00                	push   $0x0
  pushl $205
80105d46:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105d4b:	e9 ad f3 ff ff       	jmp    801050fd <alltraps>

80105d50 <vector206>:
.globl vector206
vector206:
  pushl $0
80105d50:	6a 00                	push   $0x0
  pushl $206
80105d52:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105d57:	e9 a1 f3 ff ff       	jmp    801050fd <alltraps>

80105d5c <vector207>:
.globl vector207
vector207:
  pushl $0
80105d5c:	6a 00                	push   $0x0
  pushl $207
80105d5e:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105d63:	e9 95 f3 ff ff       	jmp    801050fd <alltraps>

80105d68 <vector208>:
.globl vector208
vector208:
  pushl $0
80105d68:	6a 00                	push   $0x0
  pushl $208
80105d6a:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105d6f:	e9 89 f3 ff ff       	jmp    801050fd <alltraps>

80105d74 <vector209>:
.globl vector209
vector209:
  pushl $0
80105d74:	6a 00                	push   $0x0
  pushl $209
80105d76:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105d7b:	e9 7d f3 ff ff       	jmp    801050fd <alltraps>

80105d80 <vector210>:
.globl vector210
vector210:
  pushl $0
80105d80:	6a 00                	push   $0x0
  pushl $210
80105d82:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105d87:	e9 71 f3 ff ff       	jmp    801050fd <alltraps>

80105d8c <vector211>:
.globl vector211
vector211:
  pushl $0
80105d8c:	6a 00                	push   $0x0
  pushl $211
80105d8e:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105d93:	e9 65 f3 ff ff       	jmp    801050fd <alltraps>

80105d98 <vector212>:
.globl vector212
vector212:
  pushl $0
80105d98:	6a 00                	push   $0x0
  pushl $212
80105d9a:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105d9f:	e9 59 f3 ff ff       	jmp    801050fd <alltraps>

80105da4 <vector213>:
.globl vector213
vector213:
  pushl $0
80105da4:	6a 00                	push   $0x0
  pushl $213
80105da6:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105dab:	e9 4d f3 ff ff       	jmp    801050fd <alltraps>

80105db0 <vector214>:
.globl vector214
vector214:
  pushl $0
80105db0:	6a 00                	push   $0x0
  pushl $214
80105db2:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105db7:	e9 41 f3 ff ff       	jmp    801050fd <alltraps>

80105dbc <vector215>:
.globl vector215
vector215:
  pushl $0
80105dbc:	6a 00                	push   $0x0
  pushl $215
80105dbe:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105dc3:	e9 35 f3 ff ff       	jmp    801050fd <alltraps>

80105dc8 <vector216>:
.globl vector216
vector216:
  pushl $0
80105dc8:	6a 00                	push   $0x0
  pushl $216
80105dca:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105dcf:	e9 29 f3 ff ff       	jmp    801050fd <alltraps>

80105dd4 <vector217>:
.globl vector217
vector217:
  pushl $0
80105dd4:	6a 00                	push   $0x0
  pushl $217
80105dd6:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105ddb:	e9 1d f3 ff ff       	jmp    801050fd <alltraps>

80105de0 <vector218>:
.globl vector218
vector218:
  pushl $0
80105de0:	6a 00                	push   $0x0
  pushl $218
80105de2:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105de7:	e9 11 f3 ff ff       	jmp    801050fd <alltraps>

80105dec <vector219>:
.globl vector219
vector219:
  pushl $0
80105dec:	6a 00                	push   $0x0
  pushl $219
80105dee:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105df3:	e9 05 f3 ff ff       	jmp    801050fd <alltraps>

80105df8 <vector220>:
.globl vector220
vector220:
  pushl $0
80105df8:	6a 00                	push   $0x0
  pushl $220
80105dfa:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105dff:	e9 f9 f2 ff ff       	jmp    801050fd <alltraps>

80105e04 <vector221>:
.globl vector221
vector221:
  pushl $0
80105e04:	6a 00                	push   $0x0
  pushl $221
80105e06:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105e0b:	e9 ed f2 ff ff       	jmp    801050fd <alltraps>

80105e10 <vector222>:
.globl vector222
vector222:
  pushl $0
80105e10:	6a 00                	push   $0x0
  pushl $222
80105e12:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105e17:	e9 e1 f2 ff ff       	jmp    801050fd <alltraps>

80105e1c <vector223>:
.globl vector223
vector223:
  pushl $0
80105e1c:	6a 00                	push   $0x0
  pushl $223
80105e1e:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105e23:	e9 d5 f2 ff ff       	jmp    801050fd <alltraps>

80105e28 <vector224>:
.globl vector224
vector224:
  pushl $0
80105e28:	6a 00                	push   $0x0
  pushl $224
80105e2a:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105e2f:	e9 c9 f2 ff ff       	jmp    801050fd <alltraps>

80105e34 <vector225>:
.globl vector225
vector225:
  pushl $0
80105e34:	6a 00                	push   $0x0
  pushl $225
80105e36:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105e3b:	e9 bd f2 ff ff       	jmp    801050fd <alltraps>

80105e40 <vector226>:
.globl vector226
vector226:
  pushl $0
80105e40:	6a 00                	push   $0x0
  pushl $226
80105e42:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105e47:	e9 b1 f2 ff ff       	jmp    801050fd <alltraps>

80105e4c <vector227>:
.globl vector227
vector227:
  pushl $0
80105e4c:	6a 00                	push   $0x0
  pushl $227
80105e4e:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105e53:	e9 a5 f2 ff ff       	jmp    801050fd <alltraps>

80105e58 <vector228>:
.globl vector228
vector228:
  pushl $0
80105e58:	6a 00                	push   $0x0
  pushl $228
80105e5a:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105e5f:	e9 99 f2 ff ff       	jmp    801050fd <alltraps>

80105e64 <vector229>:
.globl vector229
vector229:
  pushl $0
80105e64:	6a 00                	push   $0x0
  pushl $229
80105e66:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105e6b:	e9 8d f2 ff ff       	jmp    801050fd <alltraps>

80105e70 <vector230>:
.globl vector230
vector230:
  pushl $0
80105e70:	6a 00                	push   $0x0
  pushl $230
80105e72:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105e77:	e9 81 f2 ff ff       	jmp    801050fd <alltraps>

80105e7c <vector231>:
.globl vector231
vector231:
  pushl $0
80105e7c:	6a 00                	push   $0x0
  pushl $231
80105e7e:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105e83:	e9 75 f2 ff ff       	jmp    801050fd <alltraps>

80105e88 <vector232>:
.globl vector232
vector232:
  pushl $0
80105e88:	6a 00                	push   $0x0
  pushl $232
80105e8a:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105e8f:	e9 69 f2 ff ff       	jmp    801050fd <alltraps>

80105e94 <vector233>:
.globl vector233
vector233:
  pushl $0
80105e94:	6a 00                	push   $0x0
  pushl $233
80105e96:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105e9b:	e9 5d f2 ff ff       	jmp    801050fd <alltraps>

80105ea0 <vector234>:
.globl vector234
vector234:
  pushl $0
80105ea0:	6a 00                	push   $0x0
  pushl $234
80105ea2:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105ea7:	e9 51 f2 ff ff       	jmp    801050fd <alltraps>

80105eac <vector235>:
.globl vector235
vector235:
  pushl $0
80105eac:	6a 00                	push   $0x0
  pushl $235
80105eae:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105eb3:	e9 45 f2 ff ff       	jmp    801050fd <alltraps>

80105eb8 <vector236>:
.globl vector236
vector236:
  pushl $0
80105eb8:	6a 00                	push   $0x0
  pushl $236
80105eba:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105ebf:	e9 39 f2 ff ff       	jmp    801050fd <alltraps>

80105ec4 <vector237>:
.globl vector237
vector237:
  pushl $0
80105ec4:	6a 00                	push   $0x0
  pushl $237
80105ec6:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105ecb:	e9 2d f2 ff ff       	jmp    801050fd <alltraps>

80105ed0 <vector238>:
.globl vector238
vector238:
  pushl $0
80105ed0:	6a 00                	push   $0x0
  pushl $238
80105ed2:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105ed7:	e9 21 f2 ff ff       	jmp    801050fd <alltraps>

80105edc <vector239>:
.globl vector239
vector239:
  pushl $0
80105edc:	6a 00                	push   $0x0
  pushl $239
80105ede:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105ee3:	e9 15 f2 ff ff       	jmp    801050fd <alltraps>

80105ee8 <vector240>:
.globl vector240
vector240:
  pushl $0
80105ee8:	6a 00                	push   $0x0
  pushl $240
80105eea:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105eef:	e9 09 f2 ff ff       	jmp    801050fd <alltraps>

80105ef4 <vector241>:
.globl vector241
vector241:
  pushl $0
80105ef4:	6a 00                	push   $0x0
  pushl $241
80105ef6:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105efb:	e9 fd f1 ff ff       	jmp    801050fd <alltraps>

80105f00 <vector242>:
.globl vector242
vector242:
  pushl $0
80105f00:	6a 00                	push   $0x0
  pushl $242
80105f02:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105f07:	e9 f1 f1 ff ff       	jmp    801050fd <alltraps>

80105f0c <vector243>:
.globl vector243
vector243:
  pushl $0
80105f0c:	6a 00                	push   $0x0
  pushl $243
80105f0e:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105f13:	e9 e5 f1 ff ff       	jmp    801050fd <alltraps>

80105f18 <vector244>:
.globl vector244
vector244:
  pushl $0
80105f18:	6a 00                	push   $0x0
  pushl $244
80105f1a:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105f1f:	e9 d9 f1 ff ff       	jmp    801050fd <alltraps>

80105f24 <vector245>:
.globl vector245
vector245:
  pushl $0
80105f24:	6a 00                	push   $0x0
  pushl $245
80105f26:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105f2b:	e9 cd f1 ff ff       	jmp    801050fd <alltraps>

80105f30 <vector246>:
.globl vector246
vector246:
  pushl $0
80105f30:	6a 00                	push   $0x0
  pushl $246
80105f32:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105f37:	e9 c1 f1 ff ff       	jmp    801050fd <alltraps>

80105f3c <vector247>:
.globl vector247
vector247:
  pushl $0
80105f3c:	6a 00                	push   $0x0
  pushl $247
80105f3e:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105f43:	e9 b5 f1 ff ff       	jmp    801050fd <alltraps>

80105f48 <vector248>:
.globl vector248
vector248:
  pushl $0
80105f48:	6a 00                	push   $0x0
  pushl $248
80105f4a:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105f4f:	e9 a9 f1 ff ff       	jmp    801050fd <alltraps>

80105f54 <vector249>:
.globl vector249
vector249:
  pushl $0
80105f54:	6a 00                	push   $0x0
  pushl $249
80105f56:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105f5b:	e9 9d f1 ff ff       	jmp    801050fd <alltraps>

80105f60 <vector250>:
.globl vector250
vector250:
  pushl $0
80105f60:	6a 00                	push   $0x0
  pushl $250
80105f62:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105f67:	e9 91 f1 ff ff       	jmp    801050fd <alltraps>

80105f6c <vector251>:
.globl vector251
vector251:
  pushl $0
80105f6c:	6a 00                	push   $0x0
  pushl $251
80105f6e:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105f73:	e9 85 f1 ff ff       	jmp    801050fd <alltraps>

80105f78 <vector252>:
.globl vector252
vector252:
  pushl $0
80105f78:	6a 00                	push   $0x0
  pushl $252
80105f7a:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105f7f:	e9 79 f1 ff ff       	jmp    801050fd <alltraps>

80105f84 <vector253>:
.globl vector253
vector253:
  pushl $0
80105f84:	6a 00                	push   $0x0
  pushl $253
80105f86:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105f8b:	e9 6d f1 ff ff       	jmp    801050fd <alltraps>

80105f90 <vector254>:
.globl vector254
vector254:
  pushl $0
80105f90:	6a 00                	push   $0x0
  pushl $254
80105f92:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105f97:	e9 61 f1 ff ff       	jmp    801050fd <alltraps>

80105f9c <vector255>:
.globl vector255
vector255:
  pushl $0
80105f9c:	6a 00                	push   $0x0
  pushl $255
80105f9e:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105fa3:	e9 55 f1 ff ff       	jmp    801050fd <alltraps>

80105fa8 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105fa8:	55                   	push   %ebp
80105fa9:	89 e5                	mov    %esp,%ebp
80105fab:	57                   	push   %edi
80105fac:	56                   	push   %esi
80105fad:	53                   	push   %ebx
80105fae:	83 ec 0c             	sub    $0xc,%esp
80105fb1:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105fb3:	c1 ea 16             	shr    $0x16,%edx
80105fb6:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105fb9:	8b 1f                	mov    (%edi),%ebx
80105fbb:	f6 c3 01             	test   $0x1,%bl
80105fbe:	74 22                	je     80105fe2 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105fc0:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105fc6:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105fcc:	c1 ee 0c             	shr    $0xc,%esi
80105fcf:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105fd5:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105fd8:	89 d8                	mov    %ebx,%eax
80105fda:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105fdd:	5b                   	pop    %ebx
80105fde:	5e                   	pop    %esi
80105fdf:	5f                   	pop    %edi
80105fe0:	5d                   	pop    %ebp
80105fe1:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc2()) == 0)
80105fe2:	85 c9                	test   %ecx,%ecx
80105fe4:	74 2b                	je     80106011 <walkpgdir+0x69>
80105fe6:	e8 46 c3 ff ff       	call   80102331 <kalloc2>
80105feb:	89 c3                	mov    %eax,%ebx
80105fed:	85 c0                	test   %eax,%eax
80105fef:	74 e7                	je     80105fd8 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105ff1:	83 ec 04             	sub    $0x4,%esp
80105ff4:	68 00 10 00 00       	push   $0x1000
80105ff9:	6a 00                	push   $0x0
80105ffb:	50                   	push   %eax
80105ffc:	e8 fe df ff ff       	call   80103fff <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80106001:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106007:	83 c8 07             	or     $0x7,%eax
8010600a:	89 07                	mov    %eax,(%edi)
8010600c:	83 c4 10             	add    $0x10,%esp
8010600f:	eb bb                	jmp    80105fcc <walkpgdir+0x24>
      return 0;
80106011:	bb 00 00 00 00       	mov    $0x0,%ebx
80106016:	eb c0                	jmp    80105fd8 <walkpgdir+0x30>

80106018 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80106018:	55                   	push   %ebp
80106019:	89 e5                	mov    %esp,%ebp
8010601b:	57                   	push   %edi
8010601c:	56                   	push   %esi
8010601d:	53                   	push   %ebx
8010601e:	83 ec 1c             	sub    $0x1c,%esp
80106021:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106024:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80106027:	89 d3                	mov    %edx,%ebx
80106029:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
8010602f:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80106033:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80106039:	b9 01 00 00 00       	mov    $0x1,%ecx
8010603e:	89 da                	mov    %ebx,%edx
80106040:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106043:	e8 60 ff ff ff       	call   80105fa8 <walkpgdir>
80106048:	85 c0                	test   %eax,%eax
8010604a:	74 2e                	je     8010607a <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
8010604c:	f6 00 01             	testb  $0x1,(%eax)
8010604f:	75 1c                	jne    8010606d <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80106051:	89 f2                	mov    %esi,%edx
80106053:	0b 55 0c             	or     0xc(%ebp),%edx
80106056:	83 ca 01             	or     $0x1,%edx
80106059:	89 10                	mov    %edx,(%eax)
    if(a == last)
8010605b:	39 fb                	cmp    %edi,%ebx
8010605d:	74 28                	je     80106087 <mappages+0x6f>
      break;
    a += PGSIZE;
8010605f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80106065:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
8010606b:	eb cc                	jmp    80106039 <mappages+0x21>
      panic("remap");
8010606d:	83 ec 0c             	sub    $0xc,%esp
80106070:	68 4c 71 10 80       	push   $0x8010714c
80106075:	e8 ce a2 ff ff       	call   80100348 <panic>
      return -1;
8010607a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
8010607f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106082:	5b                   	pop    %ebx
80106083:	5e                   	pop    %esi
80106084:	5f                   	pop    %edi
80106085:	5d                   	pop    %ebp
80106086:	c3                   	ret    
  return 0;
80106087:	b8 00 00 00 00       	mov    $0x0,%eax
8010608c:	eb f1                	jmp    8010607f <mappages+0x67>

8010608e <seginit>:
{
8010608e:	55                   	push   %ebp
8010608f:	89 e5                	mov    %esp,%ebp
80106091:	53                   	push   %ebx
80106092:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80106095:	e8 7b d4 ff ff       	call   80103515 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
8010609a:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
801060a0:	66 c7 80 18 28 15 80 	movw   $0xffff,-0x7fead7e8(%eax)
801060a7:	ff ff 
801060a9:	66 c7 80 1a 28 15 80 	movw   $0x0,-0x7fead7e6(%eax)
801060b0:	00 00 
801060b2:	c6 80 1c 28 15 80 00 	movb   $0x0,-0x7fead7e4(%eax)
801060b9:	0f b6 88 1d 28 15 80 	movzbl -0x7fead7e3(%eax),%ecx
801060c0:	83 e1 f0             	and    $0xfffffff0,%ecx
801060c3:	83 c9 1a             	or     $0x1a,%ecx
801060c6:	83 e1 9f             	and    $0xffffff9f,%ecx
801060c9:	83 c9 80             	or     $0xffffff80,%ecx
801060cc:	88 88 1d 28 15 80    	mov    %cl,-0x7fead7e3(%eax)
801060d2:	0f b6 88 1e 28 15 80 	movzbl -0x7fead7e2(%eax),%ecx
801060d9:	83 c9 0f             	or     $0xf,%ecx
801060dc:	83 e1 cf             	and    $0xffffffcf,%ecx
801060df:	83 c9 c0             	or     $0xffffffc0,%ecx
801060e2:	88 88 1e 28 15 80    	mov    %cl,-0x7fead7e2(%eax)
801060e8:	c6 80 1f 28 15 80 00 	movb   $0x0,-0x7fead7e1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801060ef:	66 c7 80 20 28 15 80 	movw   $0xffff,-0x7fead7e0(%eax)
801060f6:	ff ff 
801060f8:	66 c7 80 22 28 15 80 	movw   $0x0,-0x7fead7de(%eax)
801060ff:	00 00 
80106101:	c6 80 24 28 15 80 00 	movb   $0x0,-0x7fead7dc(%eax)
80106108:	0f b6 88 25 28 15 80 	movzbl -0x7fead7db(%eax),%ecx
8010610f:	83 e1 f0             	and    $0xfffffff0,%ecx
80106112:	83 c9 12             	or     $0x12,%ecx
80106115:	83 e1 9f             	and    $0xffffff9f,%ecx
80106118:	83 c9 80             	or     $0xffffff80,%ecx
8010611b:	88 88 25 28 15 80    	mov    %cl,-0x7fead7db(%eax)
80106121:	0f b6 88 26 28 15 80 	movzbl -0x7fead7da(%eax),%ecx
80106128:	83 c9 0f             	or     $0xf,%ecx
8010612b:	83 e1 cf             	and    $0xffffffcf,%ecx
8010612e:	83 c9 c0             	or     $0xffffffc0,%ecx
80106131:	88 88 26 28 15 80    	mov    %cl,-0x7fead7da(%eax)
80106137:	c6 80 27 28 15 80 00 	movb   $0x0,-0x7fead7d9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
8010613e:	66 c7 80 28 28 15 80 	movw   $0xffff,-0x7fead7d8(%eax)
80106145:	ff ff 
80106147:	66 c7 80 2a 28 15 80 	movw   $0x0,-0x7fead7d6(%eax)
8010614e:	00 00 
80106150:	c6 80 2c 28 15 80 00 	movb   $0x0,-0x7fead7d4(%eax)
80106157:	c6 80 2d 28 15 80 fa 	movb   $0xfa,-0x7fead7d3(%eax)
8010615e:	0f b6 88 2e 28 15 80 	movzbl -0x7fead7d2(%eax),%ecx
80106165:	83 c9 0f             	or     $0xf,%ecx
80106168:	83 e1 cf             	and    $0xffffffcf,%ecx
8010616b:	83 c9 c0             	or     $0xffffffc0,%ecx
8010616e:	88 88 2e 28 15 80    	mov    %cl,-0x7fead7d2(%eax)
80106174:	c6 80 2f 28 15 80 00 	movb   $0x0,-0x7fead7d1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010617b:	66 c7 80 30 28 15 80 	movw   $0xffff,-0x7fead7d0(%eax)
80106182:	ff ff 
80106184:	66 c7 80 32 28 15 80 	movw   $0x0,-0x7fead7ce(%eax)
8010618b:	00 00 
8010618d:	c6 80 34 28 15 80 00 	movb   $0x0,-0x7fead7cc(%eax)
80106194:	c6 80 35 28 15 80 f2 	movb   $0xf2,-0x7fead7cb(%eax)
8010619b:	0f b6 88 36 28 15 80 	movzbl -0x7fead7ca(%eax),%ecx
801061a2:	83 c9 0f             	or     $0xf,%ecx
801061a5:	83 e1 cf             	and    $0xffffffcf,%ecx
801061a8:	83 c9 c0             	or     $0xffffffc0,%ecx
801061ab:	88 88 36 28 15 80    	mov    %cl,-0x7fead7ca(%eax)
801061b1:	c6 80 37 28 15 80 00 	movb   $0x0,-0x7fead7c9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
801061b8:	05 10 28 15 80       	add    $0x80152810,%eax
  pd[0] = size-1;
801061bd:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
801061c3:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
801061c7:	c1 e8 10             	shr    $0x10,%eax
801061ca:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
801061ce:	8d 45 f2             	lea    -0xe(%ebp),%eax
801061d1:	0f 01 10             	lgdtl  (%eax)
}
801061d4:	83 c4 14             	add    $0x14,%esp
801061d7:	5b                   	pop    %ebx
801061d8:	5d                   	pop    %ebp
801061d9:	c3                   	ret    

801061da <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
801061da:	55                   	push   %ebp
801061db:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
801061dd:	a1 c4 54 15 80       	mov    0x801554c4,%eax
801061e2:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
801061e7:	0f 22 d8             	mov    %eax,%cr3
}
801061ea:	5d                   	pop    %ebp
801061eb:	c3                   	ret    

801061ec <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801061ec:	55                   	push   %ebp
801061ed:	89 e5                	mov    %esp,%ebp
801061ef:	57                   	push   %edi
801061f0:	56                   	push   %esi
801061f1:	53                   	push   %ebx
801061f2:	83 ec 1c             	sub    $0x1c,%esp
801061f5:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
801061f8:	85 f6                	test   %esi,%esi
801061fa:	0f 84 dd 00 00 00    	je     801062dd <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80106200:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80106204:	0f 84 e0 00 00 00    	je     801062ea <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
8010620a:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
8010620e:	0f 84 e3 00 00 00    	je     801062f7 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80106214:	e8 5d dc ff ff       	call   80103e76 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80106219:	e8 9b d2 ff ff       	call   801034b9 <mycpu>
8010621e:	89 c3                	mov    %eax,%ebx
80106220:	e8 94 d2 ff ff       	call   801034b9 <mycpu>
80106225:	8d 78 08             	lea    0x8(%eax),%edi
80106228:	e8 8c d2 ff ff       	call   801034b9 <mycpu>
8010622d:	83 c0 08             	add    $0x8,%eax
80106230:	c1 e8 10             	shr    $0x10,%eax
80106233:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106236:	e8 7e d2 ff ff       	call   801034b9 <mycpu>
8010623b:	83 c0 08             	add    $0x8,%eax
8010623e:	c1 e8 18             	shr    $0x18,%eax
80106241:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80106248:	67 00 
8010624a:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80106251:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80106255:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
8010625b:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80106262:	83 e2 f0             	and    $0xfffffff0,%edx
80106265:	83 ca 19             	or     $0x19,%edx
80106268:	83 e2 9f             	and    $0xffffff9f,%edx
8010626b:	83 ca 80             	or     $0xffffff80,%edx
8010626e:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80106274:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
8010627b:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80106281:	e8 33 d2 ff ff       	call   801034b9 <mycpu>
80106286:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010628d:	83 e2 ef             	and    $0xffffffef,%edx
80106290:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80106296:	e8 1e d2 ff ff       	call   801034b9 <mycpu>
8010629b:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
801062a1:	8b 5e 08             	mov    0x8(%esi),%ebx
801062a4:	e8 10 d2 ff ff       	call   801034b9 <mycpu>
801062a9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801062af:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
801062b2:	e8 02 d2 ff ff       	call   801034b9 <mycpu>
801062b7:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
801062bd:	b8 28 00 00 00       	mov    $0x28,%eax
801062c2:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
801062c5:	8b 46 04             	mov    0x4(%esi),%eax
801062c8:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
801062cd:	0f 22 d8             	mov    %eax,%cr3
  popcli();
801062d0:	e8 de db ff ff       	call   80103eb3 <popcli>
}
801062d5:	8d 65 f4             	lea    -0xc(%ebp),%esp
801062d8:	5b                   	pop    %ebx
801062d9:	5e                   	pop    %esi
801062da:	5f                   	pop    %edi
801062db:	5d                   	pop    %ebp
801062dc:	c3                   	ret    
    panic("switchuvm: no process");
801062dd:	83 ec 0c             	sub    $0xc,%esp
801062e0:	68 52 71 10 80       	push   $0x80107152
801062e5:	e8 5e a0 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
801062ea:	83 ec 0c             	sub    $0xc,%esp
801062ed:	68 68 71 10 80       	push   $0x80107168
801062f2:	e8 51 a0 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
801062f7:	83 ec 0c             	sub    $0xc,%esp
801062fa:	68 7d 71 10 80       	push   $0x8010717d
801062ff:	e8 44 a0 ff ff       	call   80100348 <panic>

80106304 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80106304:	55                   	push   %ebp
80106305:	89 e5                	mov    %esp,%ebp
80106307:	56                   	push   %esi
80106308:	53                   	push   %ebx
80106309:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
8010630c:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106312:	77 4c                	ja     80106360 <inituvm+0x5c>
    panic("inituvm: more than a page");
  // ignore this call to kalloc. Mark as UNKNOWN
  mem = kalloc2();
80106314:	e8 18 c0 ff ff       	call   80102331 <kalloc2>
80106319:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
8010631b:	83 ec 04             	sub    $0x4,%esp
8010631e:	68 00 10 00 00       	push   $0x1000
80106323:	6a 00                	push   $0x0
80106325:	50                   	push   %eax
80106326:	e8 d4 dc ff ff       	call   80103fff <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
8010632b:	83 c4 08             	add    $0x8,%esp
8010632e:	6a 06                	push   $0x6
80106330:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106336:	50                   	push   %eax
80106337:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010633c:	ba 00 00 00 00       	mov    $0x0,%edx
80106341:	8b 45 08             	mov    0x8(%ebp),%eax
80106344:	e8 cf fc ff ff       	call   80106018 <mappages>
  memmove(mem, init, sz);
80106349:	83 c4 0c             	add    $0xc,%esp
8010634c:	56                   	push   %esi
8010634d:	ff 75 0c             	pushl  0xc(%ebp)
80106350:	53                   	push   %ebx
80106351:	e8 24 dd ff ff       	call   8010407a <memmove>
}
80106356:	83 c4 10             	add    $0x10,%esp
80106359:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010635c:	5b                   	pop    %ebx
8010635d:	5e                   	pop    %esi
8010635e:	5d                   	pop    %ebp
8010635f:	c3                   	ret    
    panic("inituvm: more than a page");
80106360:	83 ec 0c             	sub    $0xc,%esp
80106363:	68 91 71 10 80       	push   $0x80107191
80106368:	e8 db 9f ff ff       	call   80100348 <panic>

8010636d <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
8010636d:	55                   	push   %ebp
8010636e:	89 e5                	mov    %esp,%ebp
80106370:	57                   	push   %edi
80106371:	56                   	push   %esi
80106372:	53                   	push   %ebx
80106373:	83 ec 0c             	sub    $0xc,%esp
80106376:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80106379:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
80106380:	75 07                	jne    80106389 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80106382:	bb 00 00 00 00       	mov    $0x0,%ebx
80106387:	eb 3c                	jmp    801063c5 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
80106389:	83 ec 0c             	sub    $0xc,%esp
8010638c:	68 4c 72 10 80       	push   $0x8010724c
80106391:	e8 b2 9f ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
80106396:	83 ec 0c             	sub    $0xc,%esp
80106399:	68 ab 71 10 80       	push   $0x801071ab
8010639e:	e8 a5 9f ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
801063a3:	05 00 00 00 80       	add    $0x80000000,%eax
801063a8:	56                   	push   %esi
801063a9:	89 da                	mov    %ebx,%edx
801063ab:	03 55 14             	add    0x14(%ebp),%edx
801063ae:	52                   	push   %edx
801063af:	50                   	push   %eax
801063b0:	ff 75 10             	pushl  0x10(%ebp)
801063b3:	e8 bb b3 ff ff       	call   80101773 <readi>
801063b8:	83 c4 10             	add    $0x10,%esp
801063bb:	39 f0                	cmp    %esi,%eax
801063bd:	75 47                	jne    80106406 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
801063bf:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801063c5:	39 fb                	cmp    %edi,%ebx
801063c7:	73 30                	jae    801063f9 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801063c9:	89 da                	mov    %ebx,%edx
801063cb:	03 55 0c             	add    0xc(%ebp),%edx
801063ce:	b9 00 00 00 00       	mov    $0x0,%ecx
801063d3:	8b 45 08             	mov    0x8(%ebp),%eax
801063d6:	e8 cd fb ff ff       	call   80105fa8 <walkpgdir>
801063db:	85 c0                	test   %eax,%eax
801063dd:	74 b7                	je     80106396 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
801063df:	8b 00                	mov    (%eax),%eax
801063e1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
801063e6:	89 fe                	mov    %edi,%esi
801063e8:	29 de                	sub    %ebx,%esi
801063ea:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801063f0:	76 b1                	jbe    801063a3 <loaduvm+0x36>
      n = PGSIZE;
801063f2:	be 00 10 00 00       	mov    $0x1000,%esi
801063f7:	eb aa                	jmp    801063a3 <loaduvm+0x36>
      return -1;
  }
  return 0;
801063f9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063fe:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106401:	5b                   	pop    %ebx
80106402:	5e                   	pop    %esi
80106403:	5f                   	pop    %edi
80106404:	5d                   	pop    %ebp
80106405:	c3                   	ret    
      return -1;
80106406:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010640b:	eb f1                	jmp    801063fe <loaduvm+0x91>

8010640d <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010640d:	55                   	push   %ebp
8010640e:	89 e5                	mov    %esp,%ebp
80106410:	57                   	push   %edi
80106411:	56                   	push   %esi
80106412:	53                   	push   %ebx
80106413:	83 ec 0c             	sub    $0xc,%esp
80106416:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80106419:	39 7d 10             	cmp    %edi,0x10(%ebp)
8010641c:	73 11                	jae    8010642f <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
8010641e:	8b 45 10             	mov    0x10(%ebp),%eax
80106421:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106427:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010642d:	eb 19                	jmp    80106448 <deallocuvm+0x3b>
    return oldsz;
8010642f:	89 f8                	mov    %edi,%eax
80106431:	eb 64                	jmp    80106497 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80106433:	c1 eb 16             	shr    $0x16,%ebx
80106436:	83 c3 01             	add    $0x1,%ebx
80106439:	c1 e3 16             	shl    $0x16,%ebx
8010643c:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106442:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106448:	39 fb                	cmp    %edi,%ebx
8010644a:	73 48                	jae    80106494 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
8010644c:	b9 00 00 00 00       	mov    $0x0,%ecx
80106451:	89 da                	mov    %ebx,%edx
80106453:	8b 45 08             	mov    0x8(%ebp),%eax
80106456:	e8 4d fb ff ff       	call   80105fa8 <walkpgdir>
8010645b:	89 c6                	mov    %eax,%esi
    if(!pte)
8010645d:	85 c0                	test   %eax,%eax
8010645f:	74 d2                	je     80106433 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
80106461:	8b 00                	mov    (%eax),%eax
80106463:	a8 01                	test   $0x1,%al
80106465:	74 db                	je     80106442 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
80106467:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010646c:	74 19                	je     80106487 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
8010646e:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106473:	83 ec 0c             	sub    $0xc,%esp
80106476:	50                   	push   %eax
80106477:	e8 32 bb ff ff       	call   80101fae <kfree>
      *pte = 0;
8010647c:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80106482:	83 c4 10             	add    $0x10,%esp
80106485:	eb bb                	jmp    80106442 <deallocuvm+0x35>
        panic("kfree");
80106487:	83 ec 0c             	sub    $0xc,%esp
8010648a:	68 e6 6a 10 80       	push   $0x80106ae6
8010648f:	e8 b4 9e ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
80106494:	8b 45 10             	mov    0x10(%ebp),%eax
}
80106497:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010649a:	5b                   	pop    %ebx
8010649b:	5e                   	pop    %esi
8010649c:	5f                   	pop    %edi
8010649d:	5d                   	pop    %ebp
8010649e:	c3                   	ret    

8010649f <allocuvm>:
{
8010649f:	55                   	push   %ebp
801064a0:	89 e5                	mov    %esp,%ebp
801064a2:	57                   	push   %edi
801064a3:	56                   	push   %esi
801064a4:	53                   	push   %ebx
801064a5:	83 ec 1c             	sub    $0x1c,%esp
801064a8:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
801064ab:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801064ae:	85 ff                	test   %edi,%edi
801064b0:	0f 88 e0 00 00 00    	js     80106596 <allocuvm+0xf7>
  if(newsz < oldsz)
801064b6:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801064b9:	73 11                	jae    801064cc <allocuvm+0x2d>
    return oldsz;
801064bb:	8b 45 0c             	mov    0xc(%ebp),%eax
801064be:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}
801064c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801064c4:	8d 65 f4             	lea    -0xc(%ebp),%esp
801064c7:	5b                   	pop    %ebx
801064c8:	5e                   	pop    %esi
801064c9:	5f                   	pop    %edi
801064ca:	5d                   	pop    %ebp
801064cb:	c3                   	ret    
  a = PGROUNDUP(oldsz);
801064cc:	8b 45 0c             	mov    0xc(%ebp),%eax
801064cf:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801064d5:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  int pid = myproc()->pid;
801064db:	e8 50 d0 ff ff       	call   80103530 <myproc>
801064e0:	8b 40 10             	mov    0x10(%eax),%eax
801064e3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(; a < newsz; a += PGSIZE){
801064e6:	39 fb                	cmp    %edi,%ebx
801064e8:	73 d7                	jae    801064c1 <allocuvm+0x22>
    mem = kalloc(pid);
801064ea:	83 ec 0c             	sub    $0xc,%esp
801064ed:	ff 75 e0             	pushl  -0x20(%ebp)
801064f0:	e8 d9 bc ff ff       	call   801021ce <kalloc>
801064f5:	89 c6                	mov    %eax,%esi
    if(mem == 0){
801064f7:	83 c4 10             	add    $0x10,%esp
801064fa:	85 c0                	test   %eax,%eax
801064fc:	74 3a                	je     80106538 <allocuvm+0x99>
    memset(mem, 0, PGSIZE);
801064fe:	83 ec 04             	sub    $0x4,%esp
80106501:	68 00 10 00 00       	push   $0x1000
80106506:	6a 00                	push   $0x0
80106508:	50                   	push   %eax
80106509:	e8 f1 da ff ff       	call   80103fff <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
8010650e:	83 c4 08             	add    $0x8,%esp
80106511:	6a 06                	push   $0x6
80106513:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
80106519:	50                   	push   %eax
8010651a:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010651f:	89 da                	mov    %ebx,%edx
80106521:	8b 45 08             	mov    0x8(%ebp),%eax
80106524:	e8 ef fa ff ff       	call   80106018 <mappages>
80106529:	83 c4 10             	add    $0x10,%esp
8010652c:	85 c0                	test   %eax,%eax
8010652e:	78 33                	js     80106563 <allocuvm+0xc4>
  for(; a < newsz; a += PGSIZE){
80106530:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106536:	eb ae                	jmp    801064e6 <allocuvm+0x47>
      cprintf("allocuvm out of memory\n");
80106538:	83 ec 0c             	sub    $0xc,%esp
8010653b:	68 c9 71 10 80       	push   $0x801071c9
80106540:	e8 c6 a0 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106545:	83 c4 0c             	add    $0xc,%esp
80106548:	ff 75 0c             	pushl  0xc(%ebp)
8010654b:	57                   	push   %edi
8010654c:	ff 75 08             	pushl  0x8(%ebp)
8010654f:	e8 b9 fe ff ff       	call   8010640d <deallocuvm>
      return 0;
80106554:	83 c4 10             	add    $0x10,%esp
80106557:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010655e:	e9 5e ff ff ff       	jmp    801064c1 <allocuvm+0x22>
      cprintf("allocuvm out of memory (2)\n");
80106563:	83 ec 0c             	sub    $0xc,%esp
80106566:	68 e1 71 10 80       	push   $0x801071e1
8010656b:	e8 9b a0 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106570:	83 c4 0c             	add    $0xc,%esp
80106573:	ff 75 0c             	pushl  0xc(%ebp)
80106576:	57                   	push   %edi
80106577:	ff 75 08             	pushl  0x8(%ebp)
8010657a:	e8 8e fe ff ff       	call   8010640d <deallocuvm>
      kfree(mem);
8010657f:	89 34 24             	mov    %esi,(%esp)
80106582:	e8 27 ba ff ff       	call   80101fae <kfree>
      return 0;
80106587:	83 c4 10             	add    $0x10,%esp
8010658a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106591:	e9 2b ff ff ff       	jmp    801064c1 <allocuvm+0x22>
    return 0;
80106596:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010659d:	e9 1f ff ff ff       	jmp    801064c1 <allocuvm+0x22>

801065a2 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801065a2:	55                   	push   %ebp
801065a3:	89 e5                	mov    %esp,%ebp
801065a5:	56                   	push   %esi
801065a6:	53                   	push   %ebx
801065a7:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
801065aa:	85 f6                	test   %esi,%esi
801065ac:	74 1a                	je     801065c8 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
801065ae:	83 ec 04             	sub    $0x4,%esp
801065b1:	6a 00                	push   $0x0
801065b3:	68 00 00 00 80       	push   $0x80000000
801065b8:	56                   	push   %esi
801065b9:	e8 4f fe ff ff       	call   8010640d <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801065be:	83 c4 10             	add    $0x10,%esp
801065c1:	bb 00 00 00 00       	mov    $0x0,%ebx
801065c6:	eb 10                	jmp    801065d8 <freevm+0x36>
    panic("freevm: no pgdir");
801065c8:	83 ec 0c             	sub    $0xc,%esp
801065cb:	68 fd 71 10 80       	push   $0x801071fd
801065d0:	e8 73 9d ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
801065d5:	83 c3 01             	add    $0x1,%ebx
801065d8:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
801065de:	77 1f                	ja     801065ff <freevm+0x5d>
    if(pgdir[i] & PTE_P){
801065e0:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
801065e3:	a8 01                	test   $0x1,%al
801065e5:	74 ee                	je     801065d5 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801065e7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801065ec:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801065f1:	83 ec 0c             	sub    $0xc,%esp
801065f4:	50                   	push   %eax
801065f5:	e8 b4 b9 ff ff       	call   80101fae <kfree>
801065fa:	83 c4 10             	add    $0x10,%esp
801065fd:	eb d6                	jmp    801065d5 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
801065ff:	83 ec 0c             	sub    $0xc,%esp
80106602:	56                   	push   %esi
80106603:	e8 a6 b9 ff ff       	call   80101fae <kfree>
}
80106608:	83 c4 10             	add    $0x10,%esp
8010660b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010660e:	5b                   	pop    %ebx
8010660f:	5e                   	pop    %esi
80106610:	5d                   	pop    %ebp
80106611:	c3                   	ret    

80106612 <setupkvm>:
{
80106612:	55                   	push   %ebp
80106613:	89 e5                	mov    %esp,%ebp
80106615:	56                   	push   %esi
80106616:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc2()) == 0)
80106617:	e8 15 bd ff ff       	call   80102331 <kalloc2>
8010661c:	89 c6                	mov    %eax,%esi
8010661e:	85 c0                	test   %eax,%eax
80106620:	74 55                	je     80106677 <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
80106622:	83 ec 04             	sub    $0x4,%esp
80106625:	68 00 10 00 00       	push   $0x1000
8010662a:	6a 00                	push   $0x0
8010662c:	50                   	push   %eax
8010662d:	e8 cd d9 ff ff       	call   80103fff <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106632:	83 c4 10             	add    $0x10,%esp
80106635:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
8010663a:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
80106640:	73 35                	jae    80106677 <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
80106642:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80106645:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106648:	29 c1                	sub    %eax,%ecx
8010664a:	83 ec 08             	sub    $0x8,%esp
8010664d:	ff 73 0c             	pushl  0xc(%ebx)
80106650:	50                   	push   %eax
80106651:	8b 13                	mov    (%ebx),%edx
80106653:	89 f0                	mov    %esi,%eax
80106655:	e8 be f9 ff ff       	call   80106018 <mappages>
8010665a:	83 c4 10             	add    $0x10,%esp
8010665d:	85 c0                	test   %eax,%eax
8010665f:	78 05                	js     80106666 <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106661:	83 c3 10             	add    $0x10,%ebx
80106664:	eb d4                	jmp    8010663a <setupkvm+0x28>
      freevm(pgdir);
80106666:	83 ec 0c             	sub    $0xc,%esp
80106669:	56                   	push   %esi
8010666a:	e8 33 ff ff ff       	call   801065a2 <freevm>
      return 0;
8010666f:	83 c4 10             	add    $0x10,%esp
80106672:	be 00 00 00 00       	mov    $0x0,%esi
}
80106677:	89 f0                	mov    %esi,%eax
80106679:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010667c:	5b                   	pop    %ebx
8010667d:	5e                   	pop    %esi
8010667e:	5d                   	pop    %ebp
8010667f:	c3                   	ret    

80106680 <kvmalloc>:
{
80106680:	55                   	push   %ebp
80106681:	89 e5                	mov    %esp,%ebp
80106683:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80106686:	e8 87 ff ff ff       	call   80106612 <setupkvm>
8010668b:	a3 c4 54 15 80       	mov    %eax,0x801554c4
  switchkvm();
80106690:	e8 45 fb ff ff       	call   801061da <switchkvm>
}
80106695:	c9                   	leave  
80106696:	c3                   	ret    

80106697 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106697:	55                   	push   %ebp
80106698:	89 e5                	mov    %esp,%ebp
8010669a:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010669d:	b9 00 00 00 00       	mov    $0x0,%ecx
801066a2:	8b 55 0c             	mov    0xc(%ebp),%edx
801066a5:	8b 45 08             	mov    0x8(%ebp),%eax
801066a8:	e8 fb f8 ff ff       	call   80105fa8 <walkpgdir>
  if(pte == 0)
801066ad:	85 c0                	test   %eax,%eax
801066af:	74 05                	je     801066b6 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
801066b1:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
801066b4:	c9                   	leave  
801066b5:	c3                   	ret    
    panic("clearpteu");
801066b6:	83 ec 0c             	sub    $0xc,%esp
801066b9:	68 0e 72 10 80       	push   $0x8010720e
801066be:	e8 85 9c ff ff       	call   80100348 <panic>

801066c3 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801066c3:	55                   	push   %ebp
801066c4:	89 e5                	mov    %esp,%ebp
801066c6:	57                   	push   %edi
801066c7:	56                   	push   %esi
801066c8:	53                   	push   %ebx
801066c9:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801066cc:	e8 41 ff ff ff       	call   80106612 <setupkvm>
801066d1:	89 45 dc             	mov    %eax,-0x24(%ebp)
801066d4:	85 c0                	test   %eax,%eax
801066d6:	0f 84 d2 00 00 00    	je     801067ae <copyuvm+0xeb>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801066dc:	bf 00 00 00 00       	mov    $0x0,%edi
801066e1:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801066e4:	0f 83 c4 00 00 00    	jae    801067ae <copyuvm+0xeb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801066ea:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801066ed:	b9 00 00 00 00       	mov    $0x0,%ecx
801066f2:	89 fa                	mov    %edi,%edx
801066f4:	8b 45 08             	mov    0x8(%ebp),%eax
801066f7:	e8 ac f8 ff ff       	call   80105fa8 <walkpgdir>
801066fc:	85 c0                	test   %eax,%eax
801066fe:	74 73                	je     80106773 <copyuvm+0xb0>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
80106700:	8b 00                	mov    (%eax),%eax
80106702:	a8 01                	test   $0x1,%al
80106704:	74 7a                	je     80106780 <copyuvm+0xbd>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
80106706:	89 c6                	mov    %eax,%esi
80106708:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
8010670e:	25 ff 0f 00 00       	and    $0xfff,%eax
80106713:	89 45 e0             	mov    %eax,-0x20(%ebp)
    // manipulate this call to kalloc. Need to pass the pid?
    int pid = myproc()->pid;
80106716:	e8 15 ce ff ff       	call   80103530 <myproc>

    if((mem = kalloc(pid)) == 0)
8010671b:	83 ec 0c             	sub    $0xc,%esp
8010671e:	ff 70 10             	pushl  0x10(%eax)
80106721:	e8 a8 ba ff ff       	call   801021ce <kalloc>
80106726:	89 c3                	mov    %eax,%ebx
80106728:	83 c4 10             	add    $0x10,%esp
8010672b:	85 c0                	test   %eax,%eax
8010672d:	74 6a                	je     80106799 <copyuvm+0xd6>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
8010672f:	81 c6 00 00 00 80    	add    $0x80000000,%esi
80106735:	83 ec 04             	sub    $0x4,%esp
80106738:	68 00 10 00 00       	push   $0x1000
8010673d:	56                   	push   %esi
8010673e:	50                   	push   %eax
8010673f:	e8 36 d9 ff ff       	call   8010407a <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
80106744:	83 c4 08             	add    $0x8,%esp
80106747:	ff 75 e0             	pushl  -0x20(%ebp)
8010674a:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106750:	50                   	push   %eax
80106751:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106756:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106759:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010675c:	e8 b7 f8 ff ff       	call   80106018 <mappages>
80106761:	83 c4 10             	add    $0x10,%esp
80106764:	85 c0                	test   %eax,%eax
80106766:	78 25                	js     8010678d <copyuvm+0xca>
  for(i = 0; i < sz; i += PGSIZE){
80106768:	81 c7 00 10 00 00    	add    $0x1000,%edi
8010676e:	e9 6e ff ff ff       	jmp    801066e1 <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
80106773:	83 ec 0c             	sub    $0xc,%esp
80106776:	68 18 72 10 80       	push   $0x80107218
8010677b:	e8 c8 9b ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
80106780:	83 ec 0c             	sub    $0xc,%esp
80106783:	68 32 72 10 80       	push   $0x80107232
80106788:	e8 bb 9b ff ff       	call   80100348 <panic>
      kfree(mem);
8010678d:	83 ec 0c             	sub    $0xc,%esp
80106790:	53                   	push   %ebx
80106791:	e8 18 b8 ff ff       	call   80101fae <kfree>
      goto bad;
80106796:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106799:	83 ec 0c             	sub    $0xc,%esp
8010679c:	ff 75 dc             	pushl  -0x24(%ebp)
8010679f:	e8 fe fd ff ff       	call   801065a2 <freevm>
  return 0;
801067a4:	83 c4 10             	add    $0x10,%esp
801067a7:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
801067ae:	8b 45 dc             	mov    -0x24(%ebp),%eax
801067b1:	8d 65 f4             	lea    -0xc(%ebp),%esp
801067b4:	5b                   	pop    %ebx
801067b5:	5e                   	pop    %esi
801067b6:	5f                   	pop    %edi
801067b7:	5d                   	pop    %ebp
801067b8:	c3                   	ret    

801067b9 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801067b9:	55                   	push   %ebp
801067ba:	89 e5                	mov    %esp,%ebp
801067bc:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801067bf:	b9 00 00 00 00       	mov    $0x0,%ecx
801067c4:	8b 55 0c             	mov    0xc(%ebp),%edx
801067c7:	8b 45 08             	mov    0x8(%ebp),%eax
801067ca:	e8 d9 f7 ff ff       	call   80105fa8 <walkpgdir>
  if((*pte & PTE_P) == 0)
801067cf:	8b 00                	mov    (%eax),%eax
801067d1:	a8 01                	test   $0x1,%al
801067d3:	74 10                	je     801067e5 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
801067d5:	a8 04                	test   $0x4,%al
801067d7:	74 13                	je     801067ec <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
801067d9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801067de:	05 00 00 00 80       	add    $0x80000000,%eax
}
801067e3:	c9                   	leave  
801067e4:	c3                   	ret    
    return 0;
801067e5:	b8 00 00 00 00       	mov    $0x0,%eax
801067ea:	eb f7                	jmp    801067e3 <uva2ka+0x2a>
    return 0;
801067ec:	b8 00 00 00 00       	mov    $0x0,%eax
801067f1:	eb f0                	jmp    801067e3 <uva2ka+0x2a>

801067f3 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801067f3:	55                   	push   %ebp
801067f4:	89 e5                	mov    %esp,%ebp
801067f6:	57                   	push   %edi
801067f7:	56                   	push   %esi
801067f8:	53                   	push   %ebx
801067f9:	83 ec 0c             	sub    $0xc,%esp
801067fc:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801067ff:	eb 25                	jmp    80106826 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
80106801:	8b 55 0c             	mov    0xc(%ebp),%edx
80106804:	29 f2                	sub    %esi,%edx
80106806:	01 d0                	add    %edx,%eax
80106808:	83 ec 04             	sub    $0x4,%esp
8010680b:	53                   	push   %ebx
8010680c:	ff 75 10             	pushl  0x10(%ebp)
8010680f:	50                   	push   %eax
80106810:	e8 65 d8 ff ff       	call   8010407a <memmove>
    len -= n;
80106815:	29 df                	sub    %ebx,%edi
    buf += n;
80106817:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
8010681a:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
80106820:	89 45 0c             	mov    %eax,0xc(%ebp)
80106823:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
80106826:	85 ff                	test   %edi,%edi
80106828:	74 2f                	je     80106859 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
8010682a:	8b 75 0c             	mov    0xc(%ebp),%esi
8010682d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
80106833:	83 ec 08             	sub    $0x8,%esp
80106836:	56                   	push   %esi
80106837:	ff 75 08             	pushl  0x8(%ebp)
8010683a:	e8 7a ff ff ff       	call   801067b9 <uva2ka>
    if(pa0 == 0)
8010683f:	83 c4 10             	add    $0x10,%esp
80106842:	85 c0                	test   %eax,%eax
80106844:	74 20                	je     80106866 <copyout+0x73>
    n = PGSIZE - (va - va0);
80106846:	89 f3                	mov    %esi,%ebx
80106848:	2b 5d 0c             	sub    0xc(%ebp),%ebx
8010684b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
80106851:	39 df                	cmp    %ebx,%edi
80106853:	73 ac                	jae    80106801 <copyout+0xe>
      n = len;
80106855:	89 fb                	mov    %edi,%ebx
80106857:	eb a8                	jmp    80106801 <copyout+0xe>
  }
  return 0;
80106859:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010685e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106861:	5b                   	pop    %ebx
80106862:	5e                   	pop    %esi
80106863:	5f                   	pop    %edi
80106864:	5d                   	pop    %ebp
80106865:	c3                   	ret    
      return -1;
80106866:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010686b:	eb f1                	jmp    8010685e <copyout+0x6b>
