
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
8010002d:	b8 4a 2e 10 80       	mov    $0x80102e4a,%eax
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
80100046:	e8 c2 3f 00 00       	call   8010400d <acquire>

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
8010007c:	e8 f1 3f 00 00       	call   80104072 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 6d 3d 00 00       	call   80103df9 <acquiresleep>
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
801000ca:	e8 a3 3f 00 00       	call   80104072 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 1f 3d 00 00       	call   80103df9 <acquiresleep>
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
801000ea:	68 40 69 10 80       	push   $0x80106940
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 51 69 10 80       	push   $0x80106951
80100100:	68 c0 b5 10 80       	push   $0x8010b5c0
80100105:	e8 c7 3d 00 00       	call   80103ed1 <initlock>
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
8010013a:	68 58 69 10 80       	push   $0x80106958
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 7e 3c 00 00       	call   80103dc6 <initsleeplock>
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
801001a8:	e8 d6 3c 00 00       	call   80103e83 <holdingsleep>
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
801001cb:	68 5f 69 10 80       	push   $0x8010695f
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
801001e4:	e8 9a 3c 00 00       	call   80103e83 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 4f 3c 00 00       	call   80103e48 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100200:	e8 08 3e 00 00       	call   8010400d <acquire>
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
8010024c:	e8 21 3e 00 00       	call   80104072 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 66 69 10 80       	push   $0x80106966
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
8010028a:	e8 7e 3d 00 00       	call   8010400d <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 a0 ff 10 80       	mov    0x8010ffa0,%eax
8010029f:	3b 05 a4 ff 10 80    	cmp    0x8010ffa4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 3e 33 00 00       	call   801035ea <myproc>
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
801002bf:	e8 ca 37 00 00       	call   80103a8e <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 10 80       	push   $0x8010a520
801002d1:	e8 9c 3d 00 00       	call   80104072 <release>
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
80100331:	e8 3c 3d 00 00       	call   80104072 <release>
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
8010035a:	e8 fa 23 00 00       	call   80102759 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 6d 69 10 80       	push   $0x8010696d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 bb 72 10 80 	movl   $0x801072bb,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 58 3b 00 00       	call   80103eec <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 81 69 10 80       	push   $0x80106981
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
8010049e:	68 85 69 10 80       	push   $0x80106985
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 75 3c 00 00       	call   80104134 <memmove>
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
801004d9:	e8 db 3b 00 00       	call   801040b9 <memset>
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
80100506:	e8 e8 4f 00 00       	call   801054f3 <uartputc>
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
8010051f:	e8 cf 4f 00 00       	call   801054f3 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 c3 4f 00 00       	call   801054f3 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 b7 4f 00 00       	call   801054f3 <uartputc>
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
80100576:	0f b6 92 b0 69 10 80 	movzbl -0x7fef9650(%edx),%edx
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
801005ca:	e8 3e 3a 00 00       	call   8010400d <acquire>
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
801005f1:	e8 7c 3a 00 00       	call   80104072 <release>
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
80100638:	e8 d0 39 00 00       	call   8010400d <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 9f 69 10 80       	push   $0x8010699f
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
801006ee:	be 98 69 10 80       	mov    $0x80106998,%esi
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
80100734:	e8 39 39 00 00       	call   80104072 <release>
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
8010074f:	e8 b9 38 00 00       	call   8010400d <acquire>
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
801007de:	e8 10 34 00 00       	call   80103bf3 <wakeup>
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
80100873:	e8 fa 37 00 00       	call   80104072 <release>
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
80100887:	e8 04 34 00 00       	call   80103c90 <procdump>
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
80100894:	68 a8 69 10 80       	push   $0x801069a8
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 2e 36 00 00       	call   80103ed1 <initlock>

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
801008de:	e8 07 2d 00 00       	call   801035ea <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 9b 22 00 00       	call   80102b89 <begin_op>

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
80100935:	e8 c9 22 00 00       	call   80102c03 <end_op>
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
8010094a:	e8 b4 22 00 00       	call   80102c03 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 c1 69 10 80       	push   $0x801069c1
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
80100972:	e8 55 5d 00 00       	call   801066cc <setupkvm>
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
80100a06:	e8 4e 5b 00 00       	call   80106559 <allocuvm>
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
80100a38:	e8 ea 59 00 00       	call   80106427 <loaduvm>
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
80100a53:	e8 ab 21 00 00       	call   80102c03 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 e0 5a 00 00       	call   80106559 <allocuvm>
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
80100a9d:	e8 ba 5b 00 00       	call   8010665c <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 90 5c 00 00       	call   80106751 <clearpteu>
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
80100ae2:	e8 74 37 00 00       	call   8010425b <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 62 37 00 00       	call   8010425b <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 a2 5d 00 00       	call   801068ad <copyout>
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
80100b66:	e8 42 5d 00 00       	call   801068ad <copyout>
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
80100ba3:	e8 78 36 00 00       	call   80104220 <safestrcpy>
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
80100bd1:	e8 d0 56 00 00       	call   801062a6 <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 7e 5a 00 00       	call   8010665c <freevm>
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
80100c19:	68 cd 69 10 80       	push   $0x801069cd
80100c1e:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c23:	e8 a9 32 00 00       	call   80103ed1 <initlock>
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
80100c39:	e8 cf 33 00 00       	call   8010400d <acquire>
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
80100c68:	e8 05 34 00 00       	call   80104072 <release>
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
80100c7f:	e8 ee 33 00 00       	call   80104072 <release>
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
80100c9d:	e8 6b 33 00 00       	call   8010400d <acquire>
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
80100cba:	e8 b3 33 00 00       	call   80104072 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 d4 69 10 80       	push   $0x801069d4
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
80100ce2:	e8 26 33 00 00       	call   8010400d <acquire>
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
80100d03:	e8 6a 33 00 00       	call   80104072 <release>
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
80100d13:	68 dc 69 10 80       	push   $0x801069dc
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
80100d49:	e8 24 33 00 00       	call   80104072 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 26 1e 00 00       	call   80102b89 <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 90 1e 00 00       	call   80102c03 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 88 24 00 00       	call   80103210 <pipeclose>
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
80100e3c:	e8 27 25 00 00       	call   80103368 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 e6 69 10 80       	push   $0x801069e6
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
80100e95:	e8 02 24 00 00       	call   8010329c <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 e2 1c 00 00       	call   80102b89 <begin_op>
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
80100edd:	e8 21 1d 00 00       	call   80102c03 <end_op>

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
80100f10:	68 ef 69 10 80       	push   $0x801069ef
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
80100f2d:	68 f5 69 10 80       	push   $0x801069f5
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
80100f8a:	e8 a5 31 00 00       	call   80104134 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 95 31 00 00       	call   80104134 <memmove>
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
80100fdf:	e8 d5 30 00 00       	call   801040b9 <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 c6 1c 00 00       	call   80102cb2 <log_write>
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
801010a3:	68 ff 69 10 80       	push   $0x801069ff
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
801010bf:	e8 ee 1b 00 00       	call   80102cb2 <log_write>
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
80101170:	e8 3d 1b 00 00       	call   80102cb2 <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 15 6a 10 80       	push   $0x80106a15
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
8010119a:	e8 6e 2e 00 00       	call   8010400d <acquire>
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
801011e1:	e8 8c 2e 00 00       	call   80104072 <release>
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
80101217:	e8 56 2e 00 00       	call   80104072 <release>
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
8010122c:	68 28 6a 10 80       	push   $0x80106a28
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
80101255:	e8 da 2e 00 00       	call   80104134 <memmove>
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
801012c8:	e8 e5 19 00 00       	call   80102cb2 <log_write>
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
801012e2:	68 38 6a 10 80       	push   $0x80106a38
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 4b 6a 10 80       	push   $0x80106a4b
801012f8:	68 e0 09 11 80       	push   $0x801109e0
801012fd:	e8 cf 2b 00 00       	call   80103ed1 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 52 6a 10 80       	push   $0x80106a52
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 20 0a 11 80       	add    $0x80110a20,%eax
80101321:	50                   	push   %eax
80101322:	e8 9f 2a 00 00       	call   80103dc6 <initsleeplock>
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
8010136c:	68 b8 6a 10 80       	push   $0x80106ab8
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
801013df:	68 58 6a 10 80       	push   $0x80106a58
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 c3 2c 00 00       	call   801040b9 <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 ad 18 00 00       	call   80102cb2 <log_write>
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
80101480:	e8 af 2c 00 00       	call   80104134 <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 25 18 00 00       	call   80102cb2 <log_write>
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
80101560:	e8 a8 2a 00 00       	call   8010400d <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
80101575:	e8 f8 2a 00 00       	call   80104072 <release>
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
8010159a:	e8 5a 28 00 00       	call   80103df9 <acquiresleep>
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
801015b2:	68 6a 6a 10 80       	push   $0x80106a6a
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
80101614:	e8 1b 2b 00 00       	call   80104134 <memmove>
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
80101639:	68 70 6a 10 80       	push   $0x80106a70
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
80101656:	e8 28 28 00 00       	call   80103e83 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 d7 27 00 00       	call   80103e48 <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 7f 6a 10 80       	push   $0x80106a7f
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
80101698:	e8 5c 27 00 00       	call   80103df9 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 92 27 00 00       	call   80103e48 <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016bd:	e8 4b 29 00 00       	call   8010400d <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016d2:	e8 9b 29 00 00       	call   80104072 <release>
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
801016ea:	e8 1e 29 00 00       	call   8010400d <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016f9:	e8 74 29 00 00       	call   80104072 <release>
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
8010182a:	e8 05 29 00 00       	call   80104134 <memmove>
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
80101926:	e8 09 28 00 00       	call   80104134 <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 7f 13 00 00       	call   80102cb2 <log_write>
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
801019a9:	e8 ed 27 00 00       	call   8010419b <strncmp>
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
801019d0:	68 87 6a 10 80       	push   $0x80106a87
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 99 6a 10 80       	push   $0x80106a99
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
80101a5a:	e8 8b 1b 00 00       	call   801035ea <myproc>
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
80101b92:	68 a8 6a 10 80       	push   $0x80106aa8
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 2a 26 00 00       	call   801041d8 <strncpy>
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
80101bd7:	68 b4 70 10 80       	push   $0x801070b4
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
80101ccc:	68 0b 6b 10 80       	push   $0x80106b0b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 14 6b 10 80       	push   $0x80106b14
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
80101d06:	68 26 6b 10 80       	push   $0x80106b26
80101d0b:	68 80 a5 10 80       	push   $0x8010a580
80101d10:	e8 bc 21 00 00       	call   80103ed1 <initlock>
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
80101d80:	e8 88 22 00 00       	call   8010400d <acquire>

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
80101dad:	e8 41 1e 00 00       	call   80103bf3 <wakeup>

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
80101dcb:	e8 a2 22 00 00       	call   80104072 <release>
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
80101de2:	e8 8b 22 00 00       	call   80104072 <release>
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
80101e1a:	e8 64 20 00 00       	call   80103e83 <holdingsleep>
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
80101e47:	e8 c1 21 00 00       	call   8010400d <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 2a 6b 10 80       	push   $0x80106b2a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 40 6b 10 80       	push   $0x80106b40
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 55 6b 10 80       	push   $0x80106b55
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
80101ea9:	e8 e0 1b 00 00       	call   80103a8e <sleep>
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
80101ec3:	e8 aa 21 00 00       	call   80104072 <release>
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
80101f3f:	68 74 6b 10 80       	push   $0x80106b74
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
80101fbc:	75 45                	jne    80102003 <kfree+0x55>
80101fbe:	81 fb c8 54 15 80    	cmp    $0x801554c8,%ebx
80101fc4:	72 3d                	jb     80102003 <kfree+0x55>
80101fc6:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
80101fcc:	81 fe ff ff ff 0d    	cmp    $0xdffffff,%esi
80101fd2:	77 2f                	ja     80102003 <kfree+0x55>
    panic("kfree");

  // cprintf("freeing: %x\n", V2P(v)>>12);

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fd4:	83 ec 04             	sub    $0x4,%esp
80101fd7:	68 00 10 00 00       	push   $0x1000
80101fdc:	6a 01                	push   $0x1
80101fde:	53                   	push   %ebx
80101fdf:	e8 d5 20 00 00       	call   801040b9 <memset>

  if (kmem.use_lock)
80101fe4:	83 c4 10             	add    $0x10,%esp
80101fe7:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80101fee:	75 20                	jne    80102010 <kfree+0x62>
    acquire(&kmem.lock);
  r = (struct run *)v;
  r->pid = -1;
80101ff0:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
  //we need to ensure that the freelist is sorted when a freed frame is added. 
  //iterate through the freelist to find the frame that
  int i = V2P(r)>>12;
80101ff7:	c1 ee 0c             	shr    $0xc,%esi
  struct run *curr = kmem.freelist;
80101ffa:	a1 78 26 11 80       	mov    0x80112678,%eax
  struct run *prev = kmem.freelist;
80101fff:	89 c2                	mov    %eax,%edx
  while(r<curr) {
80102001:	eb 23                	jmp    80102026 <kfree+0x78>
    panic("kfree");
80102003:	83 ec 0c             	sub    $0xc,%esp
80102006:	68 a6 6b 10 80       	push   $0x80106ba6
8010200b:	e8 38 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
80102010:	83 ec 0c             	sub    $0xc,%esp
80102013:	68 40 26 11 80       	push   $0x80112640
80102018:	e8 f0 1f 00 00       	call   8010400d <acquire>
8010201d:	83 c4 10             	add    $0x10,%esp
80102020:	eb ce                	jmp    80101ff0 <kfree+0x42>
    prev = curr;
80102022:	89 c2                	mov    %eax,%edx
    curr = curr->next;
80102024:	8b 00                	mov    (%eax),%eax
  while(r<curr) {
80102026:	39 d8                	cmp    %ebx,%eax
80102028:	77 f8                	ja     80102022 <kfree+0x74>
  }
  curr->prev = r;
8010202a:	89 58 08             	mov    %ebx,0x8(%eax)
  r->next = curr;
8010202d:	89 03                	mov    %eax,(%ebx)
  if(prev == curr){
8010202f:	39 d0                	cmp    %edx,%eax
80102031:	74 20                	je     80102053 <kfree+0xa5>
    r->prev = kmem.freelist;
    kmem.freelist->prev=r;
    kmem.freelist = r;
    
  } else{
    prev->next = r;
80102033:	89 1a                	mov    %ebx,(%edx)
    r->prev = prev;
80102035:	89 53 08             	mov    %edx,0x8(%ebx)
  }
  //find the frame being freed in the allocated list
  
  framesList[i] = -1;
80102038:	c7 04 b5 80 26 11 80 	movl   $0xffffffff,-0x7feed980(,%esi,4)
8010203f:	ff ff ff ff 
  // r->next = kmem.freelist;
  // kmem.freelist = r;
  
  if (kmem.use_lock)
80102043:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
8010204a:	75 1f                	jne    8010206b <kfree+0xbd>
    release(&kmem.lock);
}
8010204c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010204f:	5b                   	pop    %ebx
80102050:	5e                   	pop    %esi
80102051:	5d                   	pop    %ebp
80102052:	c3                   	ret    
    r->prev = kmem.freelist;
80102053:	a1 78 26 11 80       	mov    0x80112678,%eax
80102058:	89 43 08             	mov    %eax,0x8(%ebx)
    kmem.freelist->prev=r;
8010205b:	a1 78 26 11 80       	mov    0x80112678,%eax
80102060:	89 58 08             	mov    %ebx,0x8(%eax)
    kmem.freelist = r;
80102063:	89 1d 78 26 11 80    	mov    %ebx,0x80112678
80102069:	eb cd                	jmp    80102038 <kfree+0x8a>
    release(&kmem.lock);
8010206b:	83 ec 0c             	sub    $0xc,%esp
8010206e:	68 40 26 11 80       	push   $0x80112640
80102073:	e8 fa 1f 00 00       	call   80104072 <release>
80102078:	83 c4 10             	add    $0x10,%esp
}
8010207b:	eb cf                	jmp    8010204c <kfree+0x9e>

8010207d <kfree2>:
void kfree2(char *v)
{
8010207d:	55                   	push   %ebp
8010207e:	89 e5                	mov    %esp,%ebp
80102080:	56                   	push   %esi
80102081:	53                   	push   %ebx
80102082:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if ((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80102085:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
8010208b:	75 74                	jne    80102101 <kfree2+0x84>
8010208d:	81 fb c8 54 15 80    	cmp    $0x801554c8,%ebx
80102093:	72 6c                	jb     80102101 <kfree2+0x84>
80102095:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
8010209b:	81 fe ff ff ff 0d    	cmp    $0xdffffff,%esi
801020a1:	77 5e                	ja     80102101 <kfree2+0x84>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
801020a3:	83 ec 04             	sub    $0x4,%esp
801020a6:	68 00 10 00 00       	push   $0x1000
801020ab:	6a 01                	push   $0x1
801020ad:	53                   	push   %ebx
801020ae:	e8 06 20 00 00       	call   801040b9 <memset>

  if (kmem.use_lock)
801020b3:	83 c4 10             	add    $0x10,%esp
801020b6:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801020bd:	75 4f                	jne    8010210e <kfree2+0x91>
    acquire(&kmem.lock);
  r = (struct run *)v;
  r->next = kmem.freelist;
801020bf:	a1 78 26 11 80       	mov    0x80112678,%eax
801020c4:	89 03                	mov    %eax,(%ebx)
  kmem.freelist->prev = r;
801020c6:	a1 78 26 11 80       	mov    0x80112678,%eax
801020cb:	89 58 08             	mov    %ebx,0x8(%eax)
  r->prev = kmem.freelist;
801020ce:	a1 78 26 11 80       	mov    0x80112678,%eax
801020d3:	89 43 08             	mov    %eax,0x8(%ebx)
  r->pid = -1;
801020d6:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
  int i = V2P(r)>>12;
801020dd:	c1 ee 0c             	shr    $0xc,%esi
  framesList[i] = -1;
801020e0:	c7 04 b5 80 26 11 80 	movl   $0xffffffff,-0x7feed980(,%esi,4)
801020e7:	ff ff ff ff 
  kmem.freelist = r;
801020eb:	89 1d 78 26 11 80    	mov    %ebx,0x80112678
  if (kmem.use_lock)
801020f1:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801020f8:	75 26                	jne    80102120 <kfree2+0xa3>
    release(&kmem.lock);
}
801020fa:	8d 65 f8             	lea    -0x8(%ebp),%esp
801020fd:	5b                   	pop    %ebx
801020fe:	5e                   	pop    %esi
801020ff:	5d                   	pop    %ebp
80102100:	c3                   	ret    
    panic("kfree");
80102101:	83 ec 0c             	sub    $0xc,%esp
80102104:	68 a6 6b 10 80       	push   $0x80106ba6
80102109:	e8 3a e2 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010210e:	83 ec 0c             	sub    $0xc,%esp
80102111:	68 40 26 11 80       	push   $0x80112640
80102116:	e8 f2 1e 00 00       	call   8010400d <acquire>
8010211b:	83 c4 10             	add    $0x10,%esp
8010211e:	eb 9f                	jmp    801020bf <kfree2+0x42>
    release(&kmem.lock);
80102120:	83 ec 0c             	sub    $0xc,%esp
80102123:	68 40 26 11 80       	push   $0x80112640
80102128:	e8 45 1f 00 00       	call   80104072 <release>
8010212d:	83 c4 10             	add    $0x10,%esp
}
80102130:	eb c8                	jmp    801020fa <kfree2+0x7d>

80102132 <freerange>:
{
80102132:	55                   	push   %ebp
80102133:	89 e5                	mov    %esp,%ebp
80102135:	56                   	push   %esi
80102136:	53                   	push   %ebx
80102137:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char *)PGROUNDUP((uint)vstart);
8010213a:	8b 45 08             	mov    0x8(%ebp),%eax
8010213d:	05 ff 0f 00 00       	add    $0xfff,%eax
80102142:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
80102147:	eb 0e                	jmp    80102157 <freerange+0x25>
    kfree2(p);
80102149:	83 ec 0c             	sub    $0xc,%esp
8010214c:	50                   	push   %eax
8010214d:	e8 2b ff ff ff       	call   8010207d <kfree2>
  for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
80102152:	83 c4 10             	add    $0x10,%esp
80102155:	89 f0                	mov    %esi,%eax
80102157:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
8010215d:	39 de                	cmp    %ebx,%esi
8010215f:	76 e8                	jbe    80102149 <freerange+0x17>
}
80102161:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102164:	5b                   	pop    %ebx
80102165:	5e                   	pop    %esi
80102166:	5d                   	pop    %ebp
80102167:	c3                   	ret    

80102168 <kinit1>:
{
80102168:	55                   	push   %ebp
80102169:	89 e5                	mov    %esp,%ebp
8010216b:	83 ec 10             	sub    $0x10,%esp
  kinitdone=0;
8010216e:	c7 05 7c 26 11 80 00 	movl   $0x0,0x8011267c
80102175:	00 00 00 
  initlock(&kmem.lock, "kmem");
80102178:	68 ac 6b 10 80       	push   $0x80106bac
8010217d:	68 40 26 11 80       	push   $0x80112640
80102182:	e8 4a 1d 00 00       	call   80103ed1 <initlock>
  kmem.use_lock = 0;
80102187:	c7 05 74 26 11 80 00 	movl   $0x0,0x80112674
8010218e:	00 00 00 
  freerange(vstart, vend);
80102191:	83 c4 08             	add    $0x8,%esp
80102194:	ff 75 0c             	pushl  0xc(%ebp)
80102197:	ff 75 08             	pushl  0x8(%ebp)
8010219a:	e8 93 ff ff ff       	call   80102132 <freerange>
}
8010219f:	83 c4 10             	add    $0x10,%esp
801021a2:	c9                   	leave  
801021a3:	c3                   	ret    

801021a4 <kinit2>:
{
801021a4:	55                   	push   %ebp
801021a5:	89 e5                	mov    %esp,%ebp
801021a7:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
801021aa:	ff 75 0c             	pushl  0xc(%ebp)
801021ad:	ff 75 08             	pushl  0x8(%ebp)
801021b0:	e8 7d ff ff ff       	call   80102132 <freerange>
  kmem.use_lock = 1;
801021b5:	c7 05 74 26 11 80 01 	movl   $0x1,0x80112674
801021bc:	00 00 00 
  kinitdone =1;
801021bf:	c7 05 7c 26 11 80 01 	movl   $0x1,0x8011267c
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
801021d1:	56                   	push   %esi
801021d2:	53                   	push   %ebx
801021d3:	8b 75 08             	mov    0x8(%ebp),%esi
  struct run *r;
  if (kmem.use_lock)
801021d6:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801021dd:	75 0d                	jne    801021ec <kalloc+0x1e>
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;
801021df:	8b 1d 78 26 11 80    	mov    0x80112678,%ebx
  // we need to get the PA to retrieve the frame number
  int position = 0;
801021e5:	ba 00 00 00 00       	mov    $0x0,%edx
  int frameNumber;
  while (r) {
801021ea:	eb 63                	jmp    8010224f <kalloc+0x81>
    acquire(&kmem.lock);
801021ec:	83 ec 0c             	sub    $0xc,%esp
801021ef:	68 40 26 11 80       	push   $0x80112640
801021f4:	e8 14 1e 00 00       	call   8010400d <acquire>
801021f9:	83 c4 10             	add    $0x10,%esp
801021fc:	eb e1                	jmp    801021df <kalloc+0x11>
    }
    if(framesList[frameNumber + 1] == 0){
      framesList[frameNumber + 1] = -1;
    }
    //if the previous addr is allocated to the same pid and the next is not -> Allocate
    if((framesList[frameNumber - 1] == -1)
801021fe:	8b 0c 8d 80 26 11 80 	mov    -0x7feed980(,%ecx,4),%ecx
80102205:	83 f9 ff             	cmp    $0xffffffff,%ecx
80102208:	0f 84 8a 00 00 00    	je     80102298 <kalloc+0xca>
    && (framesList[frameNumber + 1] ==  -1)) {
      break;
    }
    if((framesList[frameNumber - 1] == pid)
8010220e:	39 f1                	cmp    %esi,%ecx
80102210:	0f 84 c3 00 00 00    	je     801022d9 <kalloc+0x10b>
    && (framesList[frameNumber + 1] ==  -1)) {
      break;
    }
    if((framesList[frameNumber - 1] == -1)
80102216:	83 f9 ff             	cmp    $0xffffffff,%ecx
80102219:	0f 84 ca 00 00 00    	je     801022e9 <kalloc+0x11b>
    && (framesList[frameNumber + 1] ==  pid)) {
      break;
    }
    // if the previous and next proc is allocated to the same pid -> Allocate.
    if((framesList[frameNumber - 1] == pid)
8010221f:	39 f1                	cmp    %esi,%ecx
80102221:	0f 84 d1 00 00 00    	je     801022f8 <kalloc+0x12a>
    && (framesList[frameNumber + 1] ==  pid)) {
      break;
    }
    if((framesList[frameNumber - 1] == pid)
80102227:	39 f1                	cmp    %esi,%ecx
80102229:	0f 84 d8 00 00 00    	je     80102307 <kalloc+0x139>
    && (framesList[frameNumber + 1] ==  -2)) {
      break;
    }
    //if the previous frame if free and the next frame is free -> Allocate
    
    if((framesList[frameNumber - 1] == -2)
8010222f:	83 f9 fe             	cmp    $0xfffffffe,%ecx
80102232:	0f 84 df 00 00 00    	je     80102317 <kalloc+0x149>
    && (framesList[frameNumber + 1] ==  pid)) {
      break;
    }
    if((framesList[frameNumber - 1] == -1)
80102238:	83 f9 ff             	cmp    $0xffffffff,%ecx
8010223b:	0f 84 e5 00 00 00    	je     80102326 <kalloc+0x158>
    && (framesList[frameNumber + 1] ==  -2)) {
      break;
    }
    if((framesList[frameNumber - 1] == -2)
80102241:	83 f9 fe             	cmp    $0xfffffffe,%ecx
80102244:	0f 84 ef 00 00 00    	je     80102339 <kalloc+0x16b>
    && (framesList[frameNumber + 1] ==  -1)) {
      break;
    }
    position++;
8010224a:	83 c2 01             	add    $0x1,%edx
    r = r->next;
8010224d:	8b 1b                	mov    (%ebx),%ebx
  while (r) {
8010224f:	85 db                	test   %ebx,%ebx
80102251:	74 53                	je     801022a6 <kalloc+0xd8>
    frameNumber = V2P(r) >> 12;
80102253:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102259:	c1 e8 0c             	shr    $0xc,%eax
    r->pid = pid;
8010225c:	89 73 04             	mov    %esi,0x4(%ebx)
    if(framesList[frameNumber - 1] == 0){
8010225f:	8d 48 ff             	lea    -0x1(%eax),%ecx
80102262:	83 3c 8d 80 26 11 80 	cmpl   $0x0,-0x7feed980(,%ecx,4)
80102269:	00 
8010226a:	75 0b                	jne    80102277 <kalloc+0xa9>
      framesList[frameNumber - 1] = -1;
8010226c:	c7 04 8d 80 26 11 80 	movl   $0xffffffff,-0x7feed980(,%ecx,4)
80102273:	ff ff ff ff 
    if(framesList[frameNumber + 1] == 0){
80102277:	83 c0 01             	add    $0x1,%eax
8010227a:	83 3c 85 80 26 11 80 	cmpl   $0x0,-0x7feed980(,%eax,4)
80102281:	00 
80102282:	0f 85 76 ff ff ff    	jne    801021fe <kalloc+0x30>
      framesList[frameNumber + 1] = -1;
80102288:	c7 04 85 80 26 11 80 	movl   $0xffffffff,-0x7feed980(,%eax,4)
8010228f:	ff ff ff ff 
80102293:	e9 66 ff ff ff       	jmp    801021fe <kalloc+0x30>
    && (framesList[frameNumber + 1] ==  -1)) {
80102298:	83 3c 85 80 26 11 80 	cmpl   $0xffffffff,-0x7feed980(,%eax,4)
8010229f:	ff 
801022a0:	0f 85 68 ff ff ff    	jne    8010220e <kalloc+0x40>
  }
  if (r){
801022a6:	85 db                	test   %ebx,%ebx
801022a8:	0f 84 b9 00 00 00    	je     80102367 <kalloc+0x199>
    frameNumber = V2P(r) >> 12;
801022ae:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801022b4:	c1 e8 0c             	shr    $0xc,%eax

    // if the last process allocated is the same as the current, then create a free frame
    if(frameNumber > 1023) {
801022b7:	3d ff 03 00 00       	cmp    $0x3ff,%eax
801022bc:	7e 07                	jle    801022c5 <kalloc+0xf7>
      framesList[frameNumber] = pid;
801022be:	89 34 85 80 26 11 80 	mov    %esi,-0x7feed980(,%eax,4)
    }    
    
    if(r == kmem.freelist){
801022c5:	8b 0d 78 26 11 80    	mov    0x80112678,%ecx
801022cb:	39 d9                	cmp    %ebx,%ecx
801022cd:	74 7d                	je     8010234c <kalloc+0x17e>
      kmem.freelist = r->next;
    } else{
      struct run *temp = kmem.freelist;
      for(int i = 0; i<position-1; i++)
801022cf:	b8 00 00 00 00       	mov    $0x0,%eax
801022d4:	e9 81 00 00 00       	jmp    8010235a <kalloc+0x18c>
    && (framesList[frameNumber + 1] ==  -1)) {
801022d9:	83 3c 85 80 26 11 80 	cmpl   $0xffffffff,-0x7feed980(,%eax,4)
801022e0:	ff 
801022e1:	0f 85 2f ff ff ff    	jne    80102216 <kalloc+0x48>
801022e7:	eb bd                	jmp    801022a6 <kalloc+0xd8>
    && (framesList[frameNumber + 1] ==  pid)) {
801022e9:	39 34 85 80 26 11 80 	cmp    %esi,-0x7feed980(,%eax,4)
801022f0:	0f 85 29 ff ff ff    	jne    8010221f <kalloc+0x51>
801022f6:	eb ae                	jmp    801022a6 <kalloc+0xd8>
    && (framesList[frameNumber + 1] ==  pid)) {
801022f8:	39 34 85 80 26 11 80 	cmp    %esi,-0x7feed980(,%eax,4)
801022ff:	0f 85 22 ff ff ff    	jne    80102227 <kalloc+0x59>
80102305:	eb 9f                	jmp    801022a6 <kalloc+0xd8>
    && (framesList[frameNumber + 1] ==  -2)) {
80102307:	83 3c 85 80 26 11 80 	cmpl   $0xfffffffe,-0x7feed980(,%eax,4)
8010230e:	fe 
8010230f:	0f 85 1a ff ff ff    	jne    8010222f <kalloc+0x61>
80102315:	eb 8f                	jmp    801022a6 <kalloc+0xd8>
    && (framesList[frameNumber + 1] ==  pid)) {
80102317:	39 34 85 80 26 11 80 	cmp    %esi,-0x7feed980(,%eax,4)
8010231e:	0f 85 14 ff ff ff    	jne    80102238 <kalloc+0x6a>
80102324:	eb 80                	jmp    801022a6 <kalloc+0xd8>
    && (framesList[frameNumber + 1] ==  -2)) {
80102326:	83 3c 85 80 26 11 80 	cmpl   $0xfffffffe,-0x7feed980(,%eax,4)
8010232d:	fe 
8010232e:	0f 85 0d ff ff ff    	jne    80102241 <kalloc+0x73>
80102334:	e9 6d ff ff ff       	jmp    801022a6 <kalloc+0xd8>
    && (framesList[frameNumber + 1] ==  -1)) {
80102339:	83 3c 85 80 26 11 80 	cmpl   $0xffffffff,-0x7feed980(,%eax,4)
80102340:	ff 
80102341:	0f 85 03 ff ff ff    	jne    8010224a <kalloc+0x7c>
80102347:	e9 5a ff ff ff       	jmp    801022a6 <kalloc+0xd8>
      kmem.freelist = r->next;
8010234c:	8b 03                	mov    (%ebx),%eax
8010234e:	a3 78 26 11 80       	mov    %eax,0x80112678
80102353:	eb 12                	jmp    80102367 <kalloc+0x199>
        temp = temp->next;
80102355:	8b 09                	mov    (%ecx),%ecx
      for(int i = 0; i<position-1; i++)
80102357:	83 c0 01             	add    $0x1,%eax
8010235a:	8d 72 ff             	lea    -0x1(%edx),%esi
8010235d:	39 c6                	cmp    %eax,%esi
8010235f:	7f f4                	jg     80102355 <kalloc+0x187>

      struct run *next = temp->next->next;
80102361:	8b 01                	mov    (%ecx),%eax
80102363:	8b 00                	mov    (%eax),%eax
      temp->next = next;
80102365:	89 01                	mov    %eax,(%ecx)
    }
  }
  if (kmem.use_lock)
80102367:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
8010236e:	75 09                	jne    80102379 <kalloc+0x1ab>
  {
    release(&kmem.lock);
  }
  return (char *)r;
}
80102370:	89 d8                	mov    %ebx,%eax
80102372:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102375:	5b                   	pop    %ebx
80102376:	5e                   	pop    %esi
80102377:	5d                   	pop    %ebp
80102378:	c3                   	ret    
    release(&kmem.lock);
80102379:	83 ec 0c             	sub    $0xc,%esp
8010237c:	68 40 26 11 80       	push   $0x80112640
80102381:	e8 ec 1c 00 00       	call   80104072 <release>
80102386:	83 c4 10             	add    $0x10,%esp
  return (char *)r;
80102389:	eb e5                	jmp    80102370 <kalloc+0x1a2>

8010238b <kalloc2>:

// called by the excluded methods (inituvm, setupkvm, walkpgdir). We need to
// "mark these pages as belonging to an unknown process". (-2)
char *
kalloc2(void)
{
8010238b:	55                   	push   %ebp
8010238c:	89 e5                	mov    %esp,%ebp
8010238e:	56                   	push   %esi
8010238f:	53                   	push   %ebx
  struct run *r;

  if (kmem.use_lock)
80102390:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80102397:	75 0d                	jne    801023a6 <kalloc2+0x1b>
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;
80102399:	8b 1d 78 26 11 80    	mov    0x80112678,%ebx
 
  int frameNumber;
  int position = 0;
8010239f:	b9 00 00 00 00       	mov    $0x0,%ecx
  while (r) {
801023a4:	eb 65                	jmp    8010240b <kalloc2+0x80>
    acquire(&kmem.lock);
801023a6:	83 ec 0c             	sub    $0xc,%esp
801023a9:	68 40 26 11 80       	push   $0x80112640
801023ae:	e8 5a 1c 00 00       	call   8010400d <acquire>
801023b3:	83 c4 10             	add    $0x10,%esp
801023b6:	eb e1                	jmp    80102399 <kalloc2+0xe>
    frameNumber = V2P(r) >> 12;
    r->pid = -2;

    //if the previous addr is allocated to the same pid and the next is not -> Allocate
    if((framesList[frameNumber - 1] == -2)
    && (framesList[frameNumber + 1] ==  -1)) {
801023b8:	83 3c 95 84 26 11 80 	cmpl   $0xffffffff,-0x7feed97c(,%edx,4)
801023bf:	ff 
801023c0:	75 69                	jne    8010242b <kalloc2+0xa0>
801023c2:	e9 a5 00 00 00       	jmp    8010246c <kalloc2+0xe1>
      break;
    }
    // if the previous and next proc is allocated to the same pid -> Allocate.
    if((framesList[frameNumber - 1] == -2)
    && (framesList[frameNumber + 1] ==  -2)) {
801023c7:	83 3c 95 84 26 11 80 	cmpl   $0xfffffffe,-0x7feed97c(,%edx,4)
801023ce:	fe 
801023cf:	75 5f                	jne    80102430 <kalloc2+0xa5>
801023d1:	e9 96 00 00 00       	jmp    8010246c <kalloc2+0xe1>
      break;
    }
    //if the previous frame if free and the next frame is free -> Allocate
    if((framesList[frameNumber - 1] == -1)
    && (framesList[frameNumber + 1] ==  -1)) {
801023d6:	83 3c 95 84 26 11 80 	cmpl   $0xffffffff,-0x7feed97c(,%edx,4)
801023dd:	ff 
801023de:	75 55                	jne    80102435 <kalloc2+0xaa>
801023e0:	e9 87 00 00 00       	jmp    8010246c <kalloc2+0xe1>
      break;
    }
    if((framesList[frameNumber - 1] == -1)
    && (framesList[frameNumber + 1] ==  -2)) {
801023e5:	83 3c 95 84 26 11 80 	cmpl   $0xfffffffe,-0x7feed97c(,%edx,4)
801023ec:	fe 
801023ed:	75 4b                	jne    8010243a <kalloc2+0xaf>
801023ef:	eb 7b                	jmp    8010246c <kalloc2+0xe1>
    if((framesList[frameNumber - 1] != -1)
    && (framesList[frameNumber + 1] ==  -2)) {
      break;
    }
    if((framesList[frameNumber - 1] == -2)
    && (framesList[frameNumber + 1] !=  -1)) {
801023f1:	83 3c 95 84 26 11 80 	cmpl   $0xffffffff,-0x7feed97c(,%edx,4)
801023f8:	ff 
801023f9:	74 53                	je     8010244e <kalloc2+0xc3>
801023fb:	eb 6f                	jmp    8010246c <kalloc2+0xe1>
    }
    if((framesList[frameNumber - 1] != -1)
    && (framesList[frameNumber + 1] ==  -1)) {
      break;
    }
    if((framesList[frameNumber - 1] == -1)
801023fd:	83 f8 ff             	cmp    $0xffffffff,%eax
80102400:	0f 84 96 00 00 00    	je     8010249c <kalloc2+0x111>
    && (framesList[frameNumber + 1] !=  -1)) {
      break;
    }
    position++;
80102406:	83 c1 01             	add    $0x1,%ecx
    r = r->next;
80102409:	8b 1b                	mov    (%ebx),%ebx
  while (r) {
8010240b:	85 db                	test   %ebx,%ebx
8010240d:	74 5d                	je     8010246c <kalloc2+0xe1>
    frameNumber = V2P(r) >> 12;
8010240f:	8d 93 00 00 00 80    	lea    -0x80000000(%ebx),%edx
80102415:	c1 ea 0c             	shr    $0xc,%edx
    r->pid = -2;
80102418:	c7 43 04 fe ff ff ff 	movl   $0xfffffffe,0x4(%ebx)
    if((framesList[frameNumber - 1] == -2)
8010241f:	8b 04 95 7c 26 11 80 	mov    -0x7feed984(,%edx,4),%eax
80102426:	83 f8 fe             	cmp    $0xfffffffe,%eax
80102429:	74 8d                	je     801023b8 <kalloc2+0x2d>
    if((framesList[frameNumber - 1] == -2)
8010242b:	83 f8 fe             	cmp    $0xfffffffe,%eax
8010242e:	74 97                	je     801023c7 <kalloc2+0x3c>
    if((framesList[frameNumber - 1] == -1)
80102430:	83 f8 ff             	cmp    $0xffffffff,%eax
80102433:	74 a1                	je     801023d6 <kalloc2+0x4b>
    if((framesList[frameNumber - 1] == -1)
80102435:	83 f8 ff             	cmp    $0xffffffff,%eax
80102438:	74 ab                	je     801023e5 <kalloc2+0x5a>
    if((framesList[frameNumber - 1] != -1)
8010243a:	83 f8 ff             	cmp    $0xffffffff,%eax
8010243d:	74 0a                	je     80102449 <kalloc2+0xbe>
    && (framesList[frameNumber + 1] ==  -2)) {
8010243f:	83 3c 95 84 26 11 80 	cmpl   $0xfffffffe,-0x7feed97c(,%edx,4)
80102446:	fe 
80102447:	74 23                	je     8010246c <kalloc2+0xe1>
    if((framesList[frameNumber - 1] == -2)
80102449:	83 f8 fe             	cmp    $0xfffffffe,%eax
8010244c:	74 a3                	je     801023f1 <kalloc2+0x66>
    if((framesList[frameNumber - 1] != -1)
8010244e:	83 f8 ff             	cmp    $0xffffffff,%eax
80102451:	74 0a                	je     8010245d <kalloc2+0xd2>
    && (framesList[frameNumber + 1] !=  -1)) {
80102453:	83 3c 95 84 26 11 80 	cmpl   $0xffffffff,-0x7feed97c(,%edx,4)
8010245a:	ff 
8010245b:	75 0f                	jne    8010246c <kalloc2+0xe1>
    if((framesList[frameNumber - 1] != -1)
8010245d:	83 f8 ff             	cmp    $0xffffffff,%eax
80102460:	74 9b                	je     801023fd <kalloc2+0x72>
    && (framesList[frameNumber + 1] ==  -1)) {
80102462:	83 3c 95 84 26 11 80 	cmpl   $0xffffffff,-0x7feed97c(,%edx,4)
80102469:	ff 
8010246a:	75 91                	jne    801023fd <kalloc2+0x72>
  }

  // we need to get the PA to retrieve the frame number
  if (r)
8010246c:	85 db                	test   %ebx,%ebx
8010246e:	74 57                	je     801024c7 <kalloc2+0x13c>
  {
    frameNumber = V2P(r) >> 12; 
80102470:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102476:	c1 e8 0c             	shr    $0xc,%eax
    if(frameNumber > 1023) {
80102479:	3d ff 03 00 00       	cmp    $0x3ff,%eax
8010247e:	7e 0b                	jle    8010248b <kalloc2+0x100>
      framesList[frameNumber] = -2;
80102480:	c7 04 85 80 26 11 80 	movl   $0xfffffffe,-0x7feed980(,%eax,4)
80102487:	fe ff ff ff 
    }    

    if(r == kmem.freelist){
8010248b:	8b 15 78 26 11 80    	mov    0x80112678,%edx
80102491:	39 da                	cmp    %ebx,%edx
80102493:	74 17                	je     801024ac <kalloc2+0x121>
      kmem.freelist = r->next;
    } else{
      struct run *temp = kmem.freelist;
      for(int i = 0; i<position-1; i++)
80102495:	b8 00 00 00 00       	mov    $0x0,%eax
8010249a:	eb 1e                	jmp    801024ba <kalloc2+0x12f>
    && (framesList[frameNumber + 1] !=  -1)) {
8010249c:	83 3c 95 84 26 11 80 	cmpl   $0xffffffff,-0x7feed97c(,%edx,4)
801024a3:	ff 
801024a4:	0f 84 5c ff ff ff    	je     80102406 <kalloc2+0x7b>
801024aa:	eb c0                	jmp    8010246c <kalloc2+0xe1>
      kmem.freelist = r->next;
801024ac:	8b 03                	mov    (%ebx),%eax
801024ae:	a3 78 26 11 80       	mov    %eax,0x80112678
801024b3:	eb 12                	jmp    801024c7 <kalloc2+0x13c>
        temp = temp->next;
801024b5:	8b 12                	mov    (%edx),%edx
      for(int i = 0; i<position-1; i++)
801024b7:	83 c0 01             	add    $0x1,%eax
801024ba:	8d 71 ff             	lea    -0x1(%ecx),%esi
801024bd:	39 c6                	cmp    %eax,%esi
801024bf:	7f f4                	jg     801024b5 <kalloc2+0x12a>

      struct run *next = temp->next->next;
801024c1:	8b 02                	mov    (%edx),%eax
801024c3:	8b 00                	mov    (%eax),%eax
      temp->next = next;
801024c5:	89 02                	mov    %eax,(%edx)
    }  
  }
  if (kmem.use_lock)
801024c7:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801024ce:	75 09                	jne    801024d9 <kalloc2+0x14e>
  {
    release(&kmem.lock);
  }
  return (char *)r;
}
801024d0:	89 d8                	mov    %ebx,%eax
801024d2:	8d 65 f8             	lea    -0x8(%ebp),%esp
801024d5:	5b                   	pop    %ebx
801024d6:	5e                   	pop    %esi
801024d7:	5d                   	pop    %ebp
801024d8:	c3                   	ret    
    release(&kmem.lock);
801024d9:	83 ec 0c             	sub    $0xc,%esp
801024dc:	68 40 26 11 80       	push   $0x80112640
801024e1:	e8 8c 1b 00 00       	call   80104072 <release>
801024e6:	83 c4 10             	add    $0x10,%esp
  return (char *)r;
801024e9:	eb e5                	jmp    801024d0 <kalloc2+0x145>

801024eb <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801024eb:	55                   	push   %ebp
801024ec:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801024ee:	ba 64 00 00 00       	mov    $0x64,%edx
801024f3:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
801024f4:	a8 01                	test   $0x1,%al
801024f6:	0f 84 b5 00 00 00    	je     801025b1 <kbdgetc+0xc6>
801024fc:	ba 60 00 00 00       	mov    $0x60,%edx
80102501:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102502:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
80102505:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
8010250b:	74 5c                	je     80102569 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
8010250d:	84 c0                	test   %al,%al
8010250f:	78 66                	js     80102577 <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102511:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
80102517:	f6 c1 40             	test   $0x40,%cl
8010251a:	74 0f                	je     8010252b <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
8010251c:	83 c8 80             	or     $0xffffff80,%eax
8010251f:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
80102522:	83 e1 bf             	and    $0xffffffbf,%ecx
80102525:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  }

  shift |= shiftcode[data];
8010252b:	0f b6 8a e0 6c 10 80 	movzbl -0x7fef9320(%edx),%ecx
80102532:	0b 0d b4 a5 10 80    	or     0x8010a5b4,%ecx
  shift ^= togglecode[data];
80102538:	0f b6 82 e0 6b 10 80 	movzbl -0x7fef9420(%edx),%eax
8010253f:	31 c1                	xor    %eax,%ecx
80102541:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  c = charcode[shift & (CTL | SHIFT)][data];
80102547:	89 c8                	mov    %ecx,%eax
80102549:	83 e0 03             	and    $0x3,%eax
8010254c:	8b 04 85 c0 6b 10 80 	mov    -0x7fef9440(,%eax,4),%eax
80102553:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
80102557:	f6 c1 08             	test   $0x8,%cl
8010255a:	74 19                	je     80102575 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
8010255c:	8d 50 9f             	lea    -0x61(%eax),%edx
8010255f:	83 fa 19             	cmp    $0x19,%edx
80102562:	77 40                	ja     801025a4 <kbdgetc+0xb9>
      c += 'A' - 'a';
80102564:	83 e8 20             	sub    $0x20,%eax
80102567:	eb 0c                	jmp    80102575 <kbdgetc+0x8a>
    shift |= E0ESC;
80102569:	83 0d b4 a5 10 80 40 	orl    $0x40,0x8010a5b4
    return 0;
80102570:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
80102575:	5d                   	pop    %ebp
80102576:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
80102577:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
8010257d:	f6 c1 40             	test   $0x40,%cl
80102580:	75 05                	jne    80102587 <kbdgetc+0x9c>
80102582:	89 c2                	mov    %eax,%edx
80102584:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
80102587:	0f b6 82 e0 6c 10 80 	movzbl -0x7fef9320(%edx),%eax
8010258e:	83 c8 40             	or     $0x40,%eax
80102591:	0f b6 c0             	movzbl %al,%eax
80102594:	f7 d0                	not    %eax
80102596:	21 c8                	and    %ecx,%eax
80102598:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    return 0;
8010259d:	b8 00 00 00 00       	mov    $0x0,%eax
801025a2:	eb d1                	jmp    80102575 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
801025a4:	8d 50 bf             	lea    -0x41(%eax),%edx
801025a7:	83 fa 19             	cmp    $0x19,%edx
801025aa:	77 c9                	ja     80102575 <kbdgetc+0x8a>
      c += 'a' - 'A';
801025ac:	83 c0 20             	add    $0x20,%eax
  return c;
801025af:	eb c4                	jmp    80102575 <kbdgetc+0x8a>
    return -1;
801025b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801025b6:	eb bd                	jmp    80102575 <kbdgetc+0x8a>

801025b8 <kbdintr>:

void
kbdintr(void)
{
801025b8:	55                   	push   %ebp
801025b9:	89 e5                	mov    %esp,%ebp
801025bb:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
801025be:	68 eb 24 10 80       	push   $0x801024eb
801025c3:	e8 76 e1 ff ff       	call   8010073e <consoleintr>
}
801025c8:	83 c4 10             	add    $0x10,%esp
801025cb:	c9                   	leave  
801025cc:	c3                   	ret    

801025cd <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
801025cd:	55                   	push   %ebp
801025ce:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
801025d0:	8b 0d 80 26 15 80    	mov    0x80152680,%ecx
801025d6:	8d 04 81             	lea    (%ecx,%eax,4),%eax
801025d9:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
801025db:	a1 80 26 15 80       	mov    0x80152680,%eax
801025e0:	8b 40 20             	mov    0x20(%eax),%eax
}
801025e3:	5d                   	pop    %ebp
801025e4:	c3                   	ret    

801025e5 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
801025e5:	55                   	push   %ebp
801025e6:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801025e8:	ba 70 00 00 00       	mov    $0x70,%edx
801025ed:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801025ee:	ba 71 00 00 00       	mov    $0x71,%edx
801025f3:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
801025f4:	0f b6 c0             	movzbl %al,%eax
}
801025f7:	5d                   	pop    %ebp
801025f8:	c3                   	ret    

801025f9 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
801025f9:	55                   	push   %ebp
801025fa:	89 e5                	mov    %esp,%ebp
801025fc:	53                   	push   %ebx
801025fd:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
801025ff:	b8 00 00 00 00       	mov    $0x0,%eax
80102604:	e8 dc ff ff ff       	call   801025e5 <cmos_read>
80102609:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
8010260b:	b8 02 00 00 00       	mov    $0x2,%eax
80102610:	e8 d0 ff ff ff       	call   801025e5 <cmos_read>
80102615:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
80102618:	b8 04 00 00 00       	mov    $0x4,%eax
8010261d:	e8 c3 ff ff ff       	call   801025e5 <cmos_read>
80102622:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
80102625:	b8 07 00 00 00       	mov    $0x7,%eax
8010262a:	e8 b6 ff ff ff       	call   801025e5 <cmos_read>
8010262f:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102632:	b8 08 00 00 00       	mov    $0x8,%eax
80102637:	e8 a9 ff ff ff       	call   801025e5 <cmos_read>
8010263c:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
8010263f:	b8 09 00 00 00       	mov    $0x9,%eax
80102644:	e8 9c ff ff ff       	call   801025e5 <cmos_read>
80102649:	89 43 14             	mov    %eax,0x14(%ebx)
}
8010264c:	5b                   	pop    %ebx
8010264d:	5d                   	pop    %ebp
8010264e:	c3                   	ret    

8010264f <lapicinit>:
  if(!lapic)
8010264f:	83 3d 80 26 15 80 00 	cmpl   $0x0,0x80152680
80102656:	0f 84 fb 00 00 00    	je     80102757 <lapicinit+0x108>
{
8010265c:	55                   	push   %ebp
8010265d:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010265f:	ba 3f 01 00 00       	mov    $0x13f,%edx
80102664:	b8 3c 00 00 00       	mov    $0x3c,%eax
80102669:	e8 5f ff ff ff       	call   801025cd <lapicw>
  lapicw(TDCR, X1);
8010266e:	ba 0b 00 00 00       	mov    $0xb,%edx
80102673:	b8 f8 00 00 00       	mov    $0xf8,%eax
80102678:	e8 50 ff ff ff       	call   801025cd <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
8010267d:	ba 20 00 02 00       	mov    $0x20020,%edx
80102682:	b8 c8 00 00 00       	mov    $0xc8,%eax
80102687:	e8 41 ff ff ff       	call   801025cd <lapicw>
  lapicw(TICR, 10000000);
8010268c:	ba 80 96 98 00       	mov    $0x989680,%edx
80102691:	b8 e0 00 00 00       	mov    $0xe0,%eax
80102696:	e8 32 ff ff ff       	call   801025cd <lapicw>
  lapicw(LINT0, MASKED);
8010269b:	ba 00 00 01 00       	mov    $0x10000,%edx
801026a0:	b8 d4 00 00 00       	mov    $0xd4,%eax
801026a5:	e8 23 ff ff ff       	call   801025cd <lapicw>
  lapicw(LINT1, MASKED);
801026aa:	ba 00 00 01 00       	mov    $0x10000,%edx
801026af:	b8 d8 00 00 00       	mov    $0xd8,%eax
801026b4:	e8 14 ff ff ff       	call   801025cd <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801026b9:	a1 80 26 15 80       	mov    0x80152680,%eax
801026be:	8b 40 30             	mov    0x30(%eax),%eax
801026c1:	c1 e8 10             	shr    $0x10,%eax
801026c4:	3c 03                	cmp    $0x3,%al
801026c6:	77 7b                	ja     80102743 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801026c8:	ba 33 00 00 00       	mov    $0x33,%edx
801026cd:	b8 dc 00 00 00       	mov    $0xdc,%eax
801026d2:	e8 f6 fe ff ff       	call   801025cd <lapicw>
  lapicw(ESR, 0);
801026d7:	ba 00 00 00 00       	mov    $0x0,%edx
801026dc:	b8 a0 00 00 00       	mov    $0xa0,%eax
801026e1:	e8 e7 fe ff ff       	call   801025cd <lapicw>
  lapicw(ESR, 0);
801026e6:	ba 00 00 00 00       	mov    $0x0,%edx
801026eb:	b8 a0 00 00 00       	mov    $0xa0,%eax
801026f0:	e8 d8 fe ff ff       	call   801025cd <lapicw>
  lapicw(EOI, 0);
801026f5:	ba 00 00 00 00       	mov    $0x0,%edx
801026fa:	b8 2c 00 00 00       	mov    $0x2c,%eax
801026ff:	e8 c9 fe ff ff       	call   801025cd <lapicw>
  lapicw(ICRHI, 0);
80102704:	ba 00 00 00 00       	mov    $0x0,%edx
80102709:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010270e:	e8 ba fe ff ff       	call   801025cd <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102713:	ba 00 85 08 00       	mov    $0x88500,%edx
80102718:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010271d:	e8 ab fe ff ff       	call   801025cd <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102722:	a1 80 26 15 80       	mov    0x80152680,%eax
80102727:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
8010272d:	f6 c4 10             	test   $0x10,%ah
80102730:	75 f0                	jne    80102722 <lapicinit+0xd3>
  lapicw(TPR, 0);
80102732:	ba 00 00 00 00       	mov    $0x0,%edx
80102737:	b8 20 00 00 00       	mov    $0x20,%eax
8010273c:	e8 8c fe ff ff       	call   801025cd <lapicw>
}
80102741:	5d                   	pop    %ebp
80102742:	c3                   	ret    
    lapicw(PCINT, MASKED);
80102743:	ba 00 00 01 00       	mov    $0x10000,%edx
80102748:	b8 d0 00 00 00       	mov    $0xd0,%eax
8010274d:	e8 7b fe ff ff       	call   801025cd <lapicw>
80102752:	e9 71 ff ff ff       	jmp    801026c8 <lapicinit+0x79>
80102757:	f3 c3                	repz ret 

80102759 <lapicid>:
{
80102759:	55                   	push   %ebp
8010275a:	89 e5                	mov    %esp,%ebp
  if (!lapic)
8010275c:	a1 80 26 15 80       	mov    0x80152680,%eax
80102761:	85 c0                	test   %eax,%eax
80102763:	74 08                	je     8010276d <lapicid+0x14>
  return lapic[ID] >> 24;
80102765:	8b 40 20             	mov    0x20(%eax),%eax
80102768:	c1 e8 18             	shr    $0x18,%eax
}
8010276b:	5d                   	pop    %ebp
8010276c:	c3                   	ret    
    return 0;
8010276d:	b8 00 00 00 00       	mov    $0x0,%eax
80102772:	eb f7                	jmp    8010276b <lapicid+0x12>

80102774 <lapiceoi>:
  if(lapic)
80102774:	83 3d 80 26 15 80 00 	cmpl   $0x0,0x80152680
8010277b:	74 14                	je     80102791 <lapiceoi+0x1d>
{
8010277d:	55                   	push   %ebp
8010277e:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
80102780:	ba 00 00 00 00       	mov    $0x0,%edx
80102785:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010278a:	e8 3e fe ff ff       	call   801025cd <lapicw>
}
8010278f:	5d                   	pop    %ebp
80102790:	c3                   	ret    
80102791:	f3 c3                	repz ret 

80102793 <microdelay>:
{
80102793:	55                   	push   %ebp
80102794:	89 e5                	mov    %esp,%ebp
}
80102796:	5d                   	pop    %ebp
80102797:	c3                   	ret    

80102798 <lapicstartap>:
{
80102798:	55                   	push   %ebp
80102799:	89 e5                	mov    %esp,%ebp
8010279b:	57                   	push   %edi
8010279c:	56                   	push   %esi
8010279d:	53                   	push   %ebx
8010279e:	8b 75 08             	mov    0x8(%ebp),%esi
801027a1:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801027a4:	b8 0f 00 00 00       	mov    $0xf,%eax
801027a9:	ba 70 00 00 00       	mov    $0x70,%edx
801027ae:	ee                   	out    %al,(%dx)
801027af:	b8 0a 00 00 00       	mov    $0xa,%eax
801027b4:	ba 71 00 00 00       	mov    $0x71,%edx
801027b9:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
801027ba:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
801027c1:	00 00 
  wrv[1] = addr >> 4;
801027c3:	89 f8                	mov    %edi,%eax
801027c5:	c1 e8 04             	shr    $0x4,%eax
801027c8:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
801027ce:	c1 e6 18             	shl    $0x18,%esi
801027d1:	89 f2                	mov    %esi,%edx
801027d3:	b8 c4 00 00 00       	mov    $0xc4,%eax
801027d8:	e8 f0 fd ff ff       	call   801025cd <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801027dd:	ba 00 c5 00 00       	mov    $0xc500,%edx
801027e2:	b8 c0 00 00 00       	mov    $0xc0,%eax
801027e7:	e8 e1 fd ff ff       	call   801025cd <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
801027ec:	ba 00 85 00 00       	mov    $0x8500,%edx
801027f1:	b8 c0 00 00 00       	mov    $0xc0,%eax
801027f6:	e8 d2 fd ff ff       	call   801025cd <lapicw>
  for(i = 0; i < 2; i++){
801027fb:	bb 00 00 00 00       	mov    $0x0,%ebx
80102800:	eb 21                	jmp    80102823 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102802:	89 f2                	mov    %esi,%edx
80102804:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102809:	e8 bf fd ff ff       	call   801025cd <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010280e:	89 fa                	mov    %edi,%edx
80102810:	c1 ea 0c             	shr    $0xc,%edx
80102813:	80 ce 06             	or     $0x6,%dh
80102816:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010281b:	e8 ad fd ff ff       	call   801025cd <lapicw>
  for(i = 0; i < 2; i++){
80102820:	83 c3 01             	add    $0x1,%ebx
80102823:	83 fb 01             	cmp    $0x1,%ebx
80102826:	7e da                	jle    80102802 <lapicstartap+0x6a>
}
80102828:	5b                   	pop    %ebx
80102829:	5e                   	pop    %esi
8010282a:	5f                   	pop    %edi
8010282b:	5d                   	pop    %ebp
8010282c:	c3                   	ret    

8010282d <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
8010282d:	55                   	push   %ebp
8010282e:	89 e5                	mov    %esp,%ebp
80102830:	57                   	push   %edi
80102831:	56                   	push   %esi
80102832:	53                   	push   %ebx
80102833:	83 ec 3c             	sub    $0x3c,%esp
80102836:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80102839:	b8 0b 00 00 00       	mov    $0xb,%eax
8010283e:	e8 a2 fd ff ff       	call   801025e5 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
80102843:	83 e0 04             	and    $0x4,%eax
80102846:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
80102848:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010284b:	e8 a9 fd ff ff       	call   801025f9 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80102850:	b8 0a 00 00 00       	mov    $0xa,%eax
80102855:	e8 8b fd ff ff       	call   801025e5 <cmos_read>
8010285a:	a8 80                	test   $0x80,%al
8010285c:	75 ea                	jne    80102848 <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
8010285e:	8d 5d b8             	lea    -0x48(%ebp),%ebx
80102861:	89 d8                	mov    %ebx,%eax
80102863:	e8 91 fd ff ff       	call   801025f9 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
80102868:	83 ec 04             	sub    $0x4,%esp
8010286b:	6a 18                	push   $0x18
8010286d:	53                   	push   %ebx
8010286e:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102871:	50                   	push   %eax
80102872:	e8 88 18 00 00       	call   801040ff <memcmp>
80102877:	83 c4 10             	add    $0x10,%esp
8010287a:	85 c0                	test   %eax,%eax
8010287c:	75 ca                	jne    80102848 <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
8010287e:	85 ff                	test   %edi,%edi
80102880:	0f 85 84 00 00 00    	jne    8010290a <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80102886:	8b 55 d0             	mov    -0x30(%ebp),%edx
80102889:	89 d0                	mov    %edx,%eax
8010288b:	c1 e8 04             	shr    $0x4,%eax
8010288e:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102891:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102894:	83 e2 0f             	and    $0xf,%edx
80102897:	01 d0                	add    %edx,%eax
80102899:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
8010289c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
8010289f:	89 d0                	mov    %edx,%eax
801028a1:	c1 e8 04             	shr    $0x4,%eax
801028a4:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801028a7:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801028aa:	83 e2 0f             	and    $0xf,%edx
801028ad:	01 d0                	add    %edx,%eax
801028af:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801028b2:	8b 55 d8             	mov    -0x28(%ebp),%edx
801028b5:	89 d0                	mov    %edx,%eax
801028b7:	c1 e8 04             	shr    $0x4,%eax
801028ba:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801028bd:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801028c0:	83 e2 0f             	and    $0xf,%edx
801028c3:	01 d0                	add    %edx,%eax
801028c5:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
801028c8:	8b 55 dc             	mov    -0x24(%ebp),%edx
801028cb:	89 d0                	mov    %edx,%eax
801028cd:	c1 e8 04             	shr    $0x4,%eax
801028d0:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801028d3:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801028d6:	83 e2 0f             	and    $0xf,%edx
801028d9:	01 d0                	add    %edx,%eax
801028db:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
801028de:	8b 55 e0             	mov    -0x20(%ebp),%edx
801028e1:	89 d0                	mov    %edx,%eax
801028e3:	c1 e8 04             	shr    $0x4,%eax
801028e6:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801028e9:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801028ec:	83 e2 0f             	and    $0xf,%edx
801028ef:	01 d0                	add    %edx,%eax
801028f1:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
801028f4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801028f7:	89 d0                	mov    %edx,%eax
801028f9:	c1 e8 04             	shr    $0x4,%eax
801028fc:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801028ff:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102902:	83 e2 0f             	and    $0xf,%edx
80102905:	01 d0                	add    %edx,%eax
80102907:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
8010290a:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010290d:	89 06                	mov    %eax,(%esi)
8010290f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102912:	89 46 04             	mov    %eax,0x4(%esi)
80102915:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102918:	89 46 08             	mov    %eax,0x8(%esi)
8010291b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010291e:	89 46 0c             	mov    %eax,0xc(%esi)
80102921:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102924:	89 46 10             	mov    %eax,0x10(%esi)
80102927:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010292a:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
8010292d:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
80102934:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102937:	5b                   	pop    %ebx
80102938:	5e                   	pop    %esi
80102939:	5f                   	pop    %edi
8010293a:	5d                   	pop    %ebp
8010293b:	c3                   	ret    

8010293c <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010293c:	55                   	push   %ebp
8010293d:	89 e5                	mov    %esp,%ebp
8010293f:	53                   	push   %ebx
80102940:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102943:	ff 35 d4 26 15 80    	pushl  0x801526d4
80102949:	ff 35 e4 26 15 80    	pushl  0x801526e4
8010294f:	e8 18 d8 ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
80102954:	8b 58 5c             	mov    0x5c(%eax),%ebx
80102957:	89 1d e8 26 15 80    	mov    %ebx,0x801526e8
  for (i = 0; i < log.lh.n; i++) {
8010295d:	83 c4 10             	add    $0x10,%esp
80102960:	ba 00 00 00 00       	mov    $0x0,%edx
80102965:	eb 0e                	jmp    80102975 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
80102967:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
8010296b:	89 0c 95 ec 26 15 80 	mov    %ecx,-0x7fead914(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
80102972:	83 c2 01             	add    $0x1,%edx
80102975:	39 d3                	cmp    %edx,%ebx
80102977:	7f ee                	jg     80102967 <read_head+0x2b>
  }
  brelse(buf);
80102979:	83 ec 0c             	sub    $0xc,%esp
8010297c:	50                   	push   %eax
8010297d:	e8 53 d8 ff ff       	call   801001d5 <brelse>
}
80102982:	83 c4 10             	add    $0x10,%esp
80102985:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102988:	c9                   	leave  
80102989:	c3                   	ret    

8010298a <install_trans>:
{
8010298a:	55                   	push   %ebp
8010298b:	89 e5                	mov    %esp,%ebp
8010298d:	57                   	push   %edi
8010298e:	56                   	push   %esi
8010298f:	53                   	push   %ebx
80102990:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
80102993:	bb 00 00 00 00       	mov    $0x0,%ebx
80102998:	eb 66                	jmp    80102a00 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010299a:	89 d8                	mov    %ebx,%eax
8010299c:	03 05 d4 26 15 80    	add    0x801526d4,%eax
801029a2:	83 c0 01             	add    $0x1,%eax
801029a5:	83 ec 08             	sub    $0x8,%esp
801029a8:	50                   	push   %eax
801029a9:	ff 35 e4 26 15 80    	pushl  0x801526e4
801029af:	e8 b8 d7 ff ff       	call   8010016c <bread>
801029b4:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801029b6:	83 c4 08             	add    $0x8,%esp
801029b9:	ff 34 9d ec 26 15 80 	pushl  -0x7fead914(,%ebx,4)
801029c0:	ff 35 e4 26 15 80    	pushl  0x801526e4
801029c6:	e8 a1 d7 ff ff       	call   8010016c <bread>
801029cb:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801029cd:	8d 57 5c             	lea    0x5c(%edi),%edx
801029d0:	8d 40 5c             	lea    0x5c(%eax),%eax
801029d3:	83 c4 0c             	add    $0xc,%esp
801029d6:	68 00 02 00 00       	push   $0x200
801029db:	52                   	push   %edx
801029dc:	50                   	push   %eax
801029dd:	e8 52 17 00 00       	call   80104134 <memmove>
    bwrite(dbuf);  // write dst to disk
801029e2:	89 34 24             	mov    %esi,(%esp)
801029e5:	e8 b0 d7 ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
801029ea:	89 3c 24             	mov    %edi,(%esp)
801029ed:	e8 e3 d7 ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
801029f2:	89 34 24             	mov    %esi,(%esp)
801029f5:	e8 db d7 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801029fa:	83 c3 01             	add    $0x1,%ebx
801029fd:	83 c4 10             	add    $0x10,%esp
80102a00:	39 1d e8 26 15 80    	cmp    %ebx,0x801526e8
80102a06:	7f 92                	jg     8010299a <install_trans+0x10>
}
80102a08:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102a0b:	5b                   	pop    %ebx
80102a0c:	5e                   	pop    %esi
80102a0d:	5f                   	pop    %edi
80102a0e:	5d                   	pop    %ebp
80102a0f:	c3                   	ret    

80102a10 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102a10:	55                   	push   %ebp
80102a11:	89 e5                	mov    %esp,%ebp
80102a13:	53                   	push   %ebx
80102a14:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102a17:	ff 35 d4 26 15 80    	pushl  0x801526d4
80102a1d:	ff 35 e4 26 15 80    	pushl  0x801526e4
80102a23:	e8 44 d7 ff ff       	call   8010016c <bread>
80102a28:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
80102a2a:	8b 0d e8 26 15 80    	mov    0x801526e8,%ecx
80102a30:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102a33:	83 c4 10             	add    $0x10,%esp
80102a36:	b8 00 00 00 00       	mov    $0x0,%eax
80102a3b:	eb 0e                	jmp    80102a4b <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
80102a3d:	8b 14 85 ec 26 15 80 	mov    -0x7fead914(,%eax,4),%edx
80102a44:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
80102a48:	83 c0 01             	add    $0x1,%eax
80102a4b:	39 c1                	cmp    %eax,%ecx
80102a4d:	7f ee                	jg     80102a3d <write_head+0x2d>
  }
  bwrite(buf);
80102a4f:	83 ec 0c             	sub    $0xc,%esp
80102a52:	53                   	push   %ebx
80102a53:	e8 42 d7 ff ff       	call   8010019a <bwrite>
  brelse(buf);
80102a58:	89 1c 24             	mov    %ebx,(%esp)
80102a5b:	e8 75 d7 ff ff       	call   801001d5 <brelse>
}
80102a60:	83 c4 10             	add    $0x10,%esp
80102a63:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a66:	c9                   	leave  
80102a67:	c3                   	ret    

80102a68 <recover_from_log>:

static void
recover_from_log(void)
{
80102a68:	55                   	push   %ebp
80102a69:	89 e5                	mov    %esp,%ebp
80102a6b:	83 ec 08             	sub    $0x8,%esp
  read_head();
80102a6e:	e8 c9 fe ff ff       	call   8010293c <read_head>
  install_trans(); // if committed, copy from log to disk
80102a73:	e8 12 ff ff ff       	call   8010298a <install_trans>
  log.lh.n = 0;
80102a78:	c7 05 e8 26 15 80 00 	movl   $0x0,0x801526e8
80102a7f:	00 00 00 
  write_head(); // clear the log
80102a82:	e8 89 ff ff ff       	call   80102a10 <write_head>
}
80102a87:	c9                   	leave  
80102a88:	c3                   	ret    

80102a89 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
80102a89:	55                   	push   %ebp
80102a8a:	89 e5                	mov    %esp,%ebp
80102a8c:	57                   	push   %edi
80102a8d:	56                   	push   %esi
80102a8e:	53                   	push   %ebx
80102a8f:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80102a92:	bb 00 00 00 00       	mov    $0x0,%ebx
80102a97:	eb 66                	jmp    80102aff <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80102a99:	89 d8                	mov    %ebx,%eax
80102a9b:	03 05 d4 26 15 80    	add    0x801526d4,%eax
80102aa1:	83 c0 01             	add    $0x1,%eax
80102aa4:	83 ec 08             	sub    $0x8,%esp
80102aa7:	50                   	push   %eax
80102aa8:	ff 35 e4 26 15 80    	pushl  0x801526e4
80102aae:	e8 b9 d6 ff ff       	call   8010016c <bread>
80102ab3:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80102ab5:	83 c4 08             	add    $0x8,%esp
80102ab8:	ff 34 9d ec 26 15 80 	pushl  -0x7fead914(,%ebx,4)
80102abf:	ff 35 e4 26 15 80    	pushl  0x801526e4
80102ac5:	e8 a2 d6 ff ff       	call   8010016c <bread>
80102aca:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
80102acc:	8d 50 5c             	lea    0x5c(%eax),%edx
80102acf:	8d 46 5c             	lea    0x5c(%esi),%eax
80102ad2:	83 c4 0c             	add    $0xc,%esp
80102ad5:	68 00 02 00 00       	push   $0x200
80102ada:	52                   	push   %edx
80102adb:	50                   	push   %eax
80102adc:	e8 53 16 00 00       	call   80104134 <memmove>
    bwrite(to);  // write the log
80102ae1:	89 34 24             	mov    %esi,(%esp)
80102ae4:	e8 b1 d6 ff ff       	call   8010019a <bwrite>
    brelse(from);
80102ae9:	89 3c 24             	mov    %edi,(%esp)
80102aec:	e8 e4 d6 ff ff       	call   801001d5 <brelse>
    brelse(to);
80102af1:	89 34 24             	mov    %esi,(%esp)
80102af4:	e8 dc d6 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102af9:	83 c3 01             	add    $0x1,%ebx
80102afc:	83 c4 10             	add    $0x10,%esp
80102aff:	39 1d e8 26 15 80    	cmp    %ebx,0x801526e8
80102b05:	7f 92                	jg     80102a99 <write_log+0x10>
  }
}
80102b07:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102b0a:	5b                   	pop    %ebx
80102b0b:	5e                   	pop    %esi
80102b0c:	5f                   	pop    %edi
80102b0d:	5d                   	pop    %ebp
80102b0e:	c3                   	ret    

80102b0f <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
80102b0f:	83 3d e8 26 15 80 00 	cmpl   $0x0,0x801526e8
80102b16:	7e 26                	jle    80102b3e <commit+0x2f>
{
80102b18:	55                   	push   %ebp
80102b19:	89 e5                	mov    %esp,%ebp
80102b1b:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
80102b1e:	e8 66 ff ff ff       	call   80102a89 <write_log>
    write_head();    // Write header to disk -- the real commit
80102b23:	e8 e8 fe ff ff       	call   80102a10 <write_head>
    install_trans(); // Now install writes to home locations
80102b28:	e8 5d fe ff ff       	call   8010298a <install_trans>
    log.lh.n = 0;
80102b2d:	c7 05 e8 26 15 80 00 	movl   $0x0,0x801526e8
80102b34:	00 00 00 
    write_head();    // Erase the transaction from the log
80102b37:	e8 d4 fe ff ff       	call   80102a10 <write_head>
  }
}
80102b3c:	c9                   	leave  
80102b3d:	c3                   	ret    
80102b3e:	f3 c3                	repz ret 

80102b40 <initlog>:
{
80102b40:	55                   	push   %ebp
80102b41:	89 e5                	mov    %esp,%ebp
80102b43:	53                   	push   %ebx
80102b44:	83 ec 2c             	sub    $0x2c,%esp
80102b47:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
80102b4a:	68 e0 6d 10 80       	push   $0x80106de0
80102b4f:	68 a0 26 15 80       	push   $0x801526a0
80102b54:	e8 78 13 00 00       	call   80103ed1 <initlock>
  readsb(dev, &sb);
80102b59:	83 c4 08             	add    $0x8,%esp
80102b5c:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102b5f:	50                   	push   %eax
80102b60:	53                   	push   %ebx
80102b61:	e8 d0 e6 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
80102b66:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102b69:	a3 d4 26 15 80       	mov    %eax,0x801526d4
  log.size = sb.nlog;
80102b6e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102b71:	a3 d8 26 15 80       	mov    %eax,0x801526d8
  log.dev = dev;
80102b76:	89 1d e4 26 15 80    	mov    %ebx,0x801526e4
  recover_from_log();
80102b7c:	e8 e7 fe ff ff       	call   80102a68 <recover_from_log>
}
80102b81:	83 c4 10             	add    $0x10,%esp
80102b84:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102b87:	c9                   	leave  
80102b88:	c3                   	ret    

80102b89 <begin_op>:
{
80102b89:	55                   	push   %ebp
80102b8a:	89 e5                	mov    %esp,%ebp
80102b8c:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102b8f:	68 a0 26 15 80       	push   $0x801526a0
80102b94:	e8 74 14 00 00       	call   8010400d <acquire>
80102b99:	83 c4 10             	add    $0x10,%esp
80102b9c:	eb 15                	jmp    80102bb3 <begin_op+0x2a>
      sleep(&log, &log.lock);
80102b9e:	83 ec 08             	sub    $0x8,%esp
80102ba1:	68 a0 26 15 80       	push   $0x801526a0
80102ba6:	68 a0 26 15 80       	push   $0x801526a0
80102bab:	e8 de 0e 00 00       	call   80103a8e <sleep>
80102bb0:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
80102bb3:	83 3d e0 26 15 80 00 	cmpl   $0x0,0x801526e0
80102bba:	75 e2                	jne    80102b9e <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102bbc:	a1 dc 26 15 80       	mov    0x801526dc,%eax
80102bc1:	83 c0 01             	add    $0x1,%eax
80102bc4:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102bc7:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102bca:	03 15 e8 26 15 80    	add    0x801526e8,%edx
80102bd0:	83 fa 1e             	cmp    $0x1e,%edx
80102bd3:	7e 17                	jle    80102bec <begin_op+0x63>
      sleep(&log, &log.lock);
80102bd5:	83 ec 08             	sub    $0x8,%esp
80102bd8:	68 a0 26 15 80       	push   $0x801526a0
80102bdd:	68 a0 26 15 80       	push   $0x801526a0
80102be2:	e8 a7 0e 00 00       	call   80103a8e <sleep>
80102be7:	83 c4 10             	add    $0x10,%esp
80102bea:	eb c7                	jmp    80102bb3 <begin_op+0x2a>
      log.outstanding += 1;
80102bec:	a3 dc 26 15 80       	mov    %eax,0x801526dc
      release(&log.lock);
80102bf1:	83 ec 0c             	sub    $0xc,%esp
80102bf4:	68 a0 26 15 80       	push   $0x801526a0
80102bf9:	e8 74 14 00 00       	call   80104072 <release>
}
80102bfe:	83 c4 10             	add    $0x10,%esp
80102c01:	c9                   	leave  
80102c02:	c3                   	ret    

80102c03 <end_op>:
{
80102c03:	55                   	push   %ebp
80102c04:	89 e5                	mov    %esp,%ebp
80102c06:	53                   	push   %ebx
80102c07:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102c0a:	68 a0 26 15 80       	push   $0x801526a0
80102c0f:	e8 f9 13 00 00       	call   8010400d <acquire>
  log.outstanding -= 1;
80102c14:	a1 dc 26 15 80       	mov    0x801526dc,%eax
80102c19:	83 e8 01             	sub    $0x1,%eax
80102c1c:	a3 dc 26 15 80       	mov    %eax,0x801526dc
  if(log.committing)
80102c21:	8b 1d e0 26 15 80    	mov    0x801526e0,%ebx
80102c27:	83 c4 10             	add    $0x10,%esp
80102c2a:	85 db                	test   %ebx,%ebx
80102c2c:	75 2c                	jne    80102c5a <end_op+0x57>
  if(log.outstanding == 0){
80102c2e:	85 c0                	test   %eax,%eax
80102c30:	75 35                	jne    80102c67 <end_op+0x64>
    log.committing = 1;
80102c32:	c7 05 e0 26 15 80 01 	movl   $0x1,0x801526e0
80102c39:	00 00 00 
    do_commit = 1;
80102c3c:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102c41:	83 ec 0c             	sub    $0xc,%esp
80102c44:	68 a0 26 15 80       	push   $0x801526a0
80102c49:	e8 24 14 00 00       	call   80104072 <release>
  if(do_commit){
80102c4e:	83 c4 10             	add    $0x10,%esp
80102c51:	85 db                	test   %ebx,%ebx
80102c53:	75 24                	jne    80102c79 <end_op+0x76>
}
80102c55:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102c58:	c9                   	leave  
80102c59:	c3                   	ret    
    panic("log.committing");
80102c5a:	83 ec 0c             	sub    $0xc,%esp
80102c5d:	68 e4 6d 10 80       	push   $0x80106de4
80102c62:	e8 e1 d6 ff ff       	call   80100348 <panic>
    wakeup(&log);
80102c67:	83 ec 0c             	sub    $0xc,%esp
80102c6a:	68 a0 26 15 80       	push   $0x801526a0
80102c6f:	e8 7f 0f 00 00       	call   80103bf3 <wakeup>
80102c74:	83 c4 10             	add    $0x10,%esp
80102c77:	eb c8                	jmp    80102c41 <end_op+0x3e>
    commit();
80102c79:	e8 91 fe ff ff       	call   80102b0f <commit>
    acquire(&log.lock);
80102c7e:	83 ec 0c             	sub    $0xc,%esp
80102c81:	68 a0 26 15 80       	push   $0x801526a0
80102c86:	e8 82 13 00 00       	call   8010400d <acquire>
    log.committing = 0;
80102c8b:	c7 05 e0 26 15 80 00 	movl   $0x0,0x801526e0
80102c92:	00 00 00 
    wakeup(&log);
80102c95:	c7 04 24 a0 26 15 80 	movl   $0x801526a0,(%esp)
80102c9c:	e8 52 0f 00 00       	call   80103bf3 <wakeup>
    release(&log.lock);
80102ca1:	c7 04 24 a0 26 15 80 	movl   $0x801526a0,(%esp)
80102ca8:	e8 c5 13 00 00       	call   80104072 <release>
80102cad:	83 c4 10             	add    $0x10,%esp
}
80102cb0:	eb a3                	jmp    80102c55 <end_op+0x52>

80102cb2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102cb2:	55                   	push   %ebp
80102cb3:	89 e5                	mov    %esp,%ebp
80102cb5:	53                   	push   %ebx
80102cb6:	83 ec 04             	sub    $0x4,%esp
80102cb9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102cbc:	8b 15 e8 26 15 80    	mov    0x801526e8,%edx
80102cc2:	83 fa 1d             	cmp    $0x1d,%edx
80102cc5:	7f 45                	jg     80102d0c <log_write+0x5a>
80102cc7:	a1 d8 26 15 80       	mov    0x801526d8,%eax
80102ccc:	83 e8 01             	sub    $0x1,%eax
80102ccf:	39 c2                	cmp    %eax,%edx
80102cd1:	7d 39                	jge    80102d0c <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102cd3:	83 3d dc 26 15 80 00 	cmpl   $0x0,0x801526dc
80102cda:	7e 3d                	jle    80102d19 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102cdc:	83 ec 0c             	sub    $0xc,%esp
80102cdf:	68 a0 26 15 80       	push   $0x801526a0
80102ce4:	e8 24 13 00 00       	call   8010400d <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102ce9:	83 c4 10             	add    $0x10,%esp
80102cec:	b8 00 00 00 00       	mov    $0x0,%eax
80102cf1:	8b 15 e8 26 15 80    	mov    0x801526e8,%edx
80102cf7:	39 c2                	cmp    %eax,%edx
80102cf9:	7e 2b                	jle    80102d26 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102cfb:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102cfe:	39 0c 85 ec 26 15 80 	cmp    %ecx,-0x7fead914(,%eax,4)
80102d05:	74 1f                	je     80102d26 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102d07:	83 c0 01             	add    $0x1,%eax
80102d0a:	eb e5                	jmp    80102cf1 <log_write+0x3f>
    panic("too big a transaction");
80102d0c:	83 ec 0c             	sub    $0xc,%esp
80102d0f:	68 f3 6d 10 80       	push   $0x80106df3
80102d14:	e8 2f d6 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102d19:	83 ec 0c             	sub    $0xc,%esp
80102d1c:	68 09 6e 10 80       	push   $0x80106e09
80102d21:	e8 22 d6 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102d26:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102d29:	89 0c 85 ec 26 15 80 	mov    %ecx,-0x7fead914(,%eax,4)
  if (i == log.lh.n)
80102d30:	39 c2                	cmp    %eax,%edx
80102d32:	74 18                	je     80102d4c <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102d34:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102d37:	83 ec 0c             	sub    $0xc,%esp
80102d3a:	68 a0 26 15 80       	push   $0x801526a0
80102d3f:	e8 2e 13 00 00       	call   80104072 <release>
}
80102d44:	83 c4 10             	add    $0x10,%esp
80102d47:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102d4a:	c9                   	leave  
80102d4b:	c3                   	ret    
    log.lh.n++;
80102d4c:	83 c2 01             	add    $0x1,%edx
80102d4f:	89 15 e8 26 15 80    	mov    %edx,0x801526e8
80102d55:	eb dd                	jmp    80102d34 <log_write+0x82>

80102d57 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102d57:	55                   	push   %ebp
80102d58:	89 e5                	mov    %esp,%ebp
80102d5a:	53                   	push   %ebx
80102d5b:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102d5e:	68 8a 00 00 00       	push   $0x8a
80102d63:	68 8c a4 10 80       	push   $0x8010a48c
80102d68:	68 00 70 00 80       	push   $0x80007000
80102d6d:	e8 c2 13 00 00       	call   80104134 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102d72:	83 c4 10             	add    $0x10,%esp
80102d75:	bb a0 27 15 80       	mov    $0x801527a0,%ebx
80102d7a:	eb 06                	jmp    80102d82 <startothers+0x2b>
80102d7c:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102d82:	69 05 20 2d 15 80 b0 	imul   $0xb0,0x80152d20,%eax
80102d89:	00 00 00 
80102d8c:	05 a0 27 15 80       	add    $0x801527a0,%eax
80102d91:	39 d8                	cmp    %ebx,%eax
80102d93:	76 57                	jbe    80102dec <startothers+0x95>
    if(c == mycpu())  // We've started already.
80102d95:	e8 d9 07 00 00       	call   80103573 <mycpu>
80102d9a:	39 d8                	cmp    %ebx,%eax
80102d9c:	74 de                	je     80102d7c <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc(myproc()->pid); // need to pass the pid to kalloc?
80102d9e:	e8 47 08 00 00       	call   801035ea <myproc>
80102da3:	83 ec 0c             	sub    $0xc,%esp
80102da6:	ff 70 10             	pushl  0x10(%eax)
80102da9:	e8 20 f4 ff ff       	call   801021ce <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102dae:	05 00 10 00 00       	add    $0x1000,%eax
80102db3:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102db8:	c7 05 f8 6f 00 80 30 	movl   $0x80102e30,0x80006ff8
80102dbf:	2e 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102dc2:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102dc9:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102dcc:	83 c4 08             	add    $0x8,%esp
80102dcf:	68 00 70 00 00       	push   $0x7000
80102dd4:	0f b6 03             	movzbl (%ebx),%eax
80102dd7:	50                   	push   %eax
80102dd8:	e8 bb f9 ff ff       	call   80102798 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102ddd:	83 c4 10             	add    $0x10,%esp
80102de0:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102de6:	85 c0                	test   %eax,%eax
80102de8:	74 f6                	je     80102de0 <startothers+0x89>
80102dea:	eb 90                	jmp    80102d7c <startothers+0x25>
      ;
  }
}
80102dec:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102def:	c9                   	leave  
80102df0:	c3                   	ret    

80102df1 <mpmain>:
{
80102df1:	55                   	push   %ebp
80102df2:	89 e5                	mov    %esp,%ebp
80102df4:	53                   	push   %ebx
80102df5:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102df8:	e8 d2 07 00 00       	call   801035cf <cpuid>
80102dfd:	89 c3                	mov    %eax,%ebx
80102dff:	e8 cb 07 00 00       	call   801035cf <cpuid>
80102e04:	83 ec 04             	sub    $0x4,%esp
80102e07:	53                   	push   %ebx
80102e08:	50                   	push   %eax
80102e09:	68 24 6e 10 80       	push   $0x80106e24
80102e0e:	e8 f8 d7 ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102e13:	e8 73 24 00 00       	call   8010528b <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102e18:	e8 56 07 00 00       	call   80103573 <mycpu>
80102e1d:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102e1f:	b8 01 00 00 00       	mov    $0x1,%eax
80102e24:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102e2b:	e8 39 0a 00 00       	call   80103869 <scheduler>

80102e30 <mpenter>:
{
80102e30:	55                   	push   %ebp
80102e31:	89 e5                	mov    %esp,%ebp
80102e33:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102e36:	e8 59 34 00 00       	call   80106294 <switchkvm>
  seginit();
80102e3b:	e8 08 33 00 00       	call   80106148 <seginit>
  lapicinit();
80102e40:	e8 0a f8 ff ff       	call   8010264f <lapicinit>
  mpmain();
80102e45:	e8 a7 ff ff ff       	call   80102df1 <mpmain>

80102e4a <main>:
{
80102e4a:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102e4e:	83 e4 f0             	and    $0xfffffff0,%esp
80102e51:	ff 71 fc             	pushl  -0x4(%ecx)
80102e54:	55                   	push   %ebp
80102e55:	89 e5                	mov    %esp,%ebp
80102e57:	51                   	push   %ecx
80102e58:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102e5b:	68 00 00 40 80       	push   $0x80400000
80102e60:	68 c8 54 15 80       	push   $0x801554c8
80102e65:	e8 fe f2 ff ff       	call   80102168 <kinit1>
  kvmalloc();      // kernel page table
80102e6a:	e8 cb 38 00 00       	call   8010673a <kvmalloc>
  mpinit();        // detect other processors
80102e6f:	e8 c9 01 00 00       	call   8010303d <mpinit>
  lapicinit();     // interrupt controller
80102e74:	e8 d6 f7 ff ff       	call   8010264f <lapicinit>
  seginit();       // segment descriptors
80102e79:	e8 ca 32 00 00       	call   80106148 <seginit>
  picinit();       // disable pic
80102e7e:	e8 82 02 00 00       	call   80103105 <picinit>
  ioapicinit();    // another interrupt controller
80102e83:	e8 72 f0 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102e88:	e8 01 da ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102e8d:	e8 a7 26 00 00       	call   80105539 <uartinit>
  pinit();         // process table
80102e92:	e8 c2 06 00 00       	call   80103559 <pinit>
  tvinit();        // trap vectors
80102e97:	e8 3e 23 00 00       	call   801051da <tvinit>
  binit();         // buffer cache
80102e9c:	e8 53 d2 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102ea1:	e8 6d dd ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102ea6:	e8 55 ee ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102eab:	e8 a7 fe ff ff       	call   80102d57 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102eb0:	83 c4 08             	add    $0x8,%esp
80102eb3:	68 00 00 00 8e       	push   $0x8e000000
80102eb8:	68 00 00 40 80       	push   $0x80400000
80102ebd:	e8 e2 f2 ff ff       	call   801021a4 <kinit2>
  userinit();      // first user process
80102ec2:	e8 47 07 00 00       	call   8010360e <userinit>
  mpmain();        // finish this processor's setup
80102ec7:	e8 25 ff ff ff       	call   80102df1 <mpmain>

80102ecc <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102ecc:	55                   	push   %ebp
80102ecd:	89 e5                	mov    %esp,%ebp
80102ecf:	56                   	push   %esi
80102ed0:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102ed1:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102ed6:	b9 00 00 00 00       	mov    $0x0,%ecx
80102edb:	eb 09                	jmp    80102ee6 <sum+0x1a>
    sum += addr[i];
80102edd:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102ee1:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102ee3:	83 c1 01             	add    $0x1,%ecx
80102ee6:	39 d1                	cmp    %edx,%ecx
80102ee8:	7c f3                	jl     80102edd <sum+0x11>
  return sum;
}
80102eea:	89 d8                	mov    %ebx,%eax
80102eec:	5b                   	pop    %ebx
80102eed:	5e                   	pop    %esi
80102eee:	5d                   	pop    %ebp
80102eef:	c3                   	ret    

80102ef0 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102ef0:	55                   	push   %ebp
80102ef1:	89 e5                	mov    %esp,%ebp
80102ef3:	56                   	push   %esi
80102ef4:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102ef5:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102efb:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102efd:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102eff:	eb 03                	jmp    80102f04 <mpsearch1+0x14>
80102f01:	83 c3 10             	add    $0x10,%ebx
80102f04:	39 f3                	cmp    %esi,%ebx
80102f06:	73 29                	jae    80102f31 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102f08:	83 ec 04             	sub    $0x4,%esp
80102f0b:	6a 04                	push   $0x4
80102f0d:	68 38 6e 10 80       	push   $0x80106e38
80102f12:	53                   	push   %ebx
80102f13:	e8 e7 11 00 00       	call   801040ff <memcmp>
80102f18:	83 c4 10             	add    $0x10,%esp
80102f1b:	85 c0                	test   %eax,%eax
80102f1d:	75 e2                	jne    80102f01 <mpsearch1+0x11>
80102f1f:	ba 10 00 00 00       	mov    $0x10,%edx
80102f24:	89 d8                	mov    %ebx,%eax
80102f26:	e8 a1 ff ff ff       	call   80102ecc <sum>
80102f2b:	84 c0                	test   %al,%al
80102f2d:	75 d2                	jne    80102f01 <mpsearch1+0x11>
80102f2f:	eb 05                	jmp    80102f36 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102f31:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102f36:	89 d8                	mov    %ebx,%eax
80102f38:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102f3b:	5b                   	pop    %ebx
80102f3c:	5e                   	pop    %esi
80102f3d:	5d                   	pop    %ebp
80102f3e:	c3                   	ret    

80102f3f <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102f3f:	55                   	push   %ebp
80102f40:	89 e5                	mov    %esp,%ebp
80102f42:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102f45:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102f4c:	c1 e0 08             	shl    $0x8,%eax
80102f4f:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102f56:	09 d0                	or     %edx,%eax
80102f58:	c1 e0 04             	shl    $0x4,%eax
80102f5b:	85 c0                	test   %eax,%eax
80102f5d:	74 1f                	je     80102f7e <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102f5f:	ba 00 04 00 00       	mov    $0x400,%edx
80102f64:	e8 87 ff ff ff       	call   80102ef0 <mpsearch1>
80102f69:	85 c0                	test   %eax,%eax
80102f6b:	75 0f                	jne    80102f7c <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102f6d:	ba 00 00 01 00       	mov    $0x10000,%edx
80102f72:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102f77:	e8 74 ff ff ff       	call   80102ef0 <mpsearch1>
}
80102f7c:	c9                   	leave  
80102f7d:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102f7e:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102f85:	c1 e0 08             	shl    $0x8,%eax
80102f88:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102f8f:	09 d0                	or     %edx,%eax
80102f91:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102f94:	2d 00 04 00 00       	sub    $0x400,%eax
80102f99:	ba 00 04 00 00       	mov    $0x400,%edx
80102f9e:	e8 4d ff ff ff       	call   80102ef0 <mpsearch1>
80102fa3:	85 c0                	test   %eax,%eax
80102fa5:	75 d5                	jne    80102f7c <mpsearch+0x3d>
80102fa7:	eb c4                	jmp    80102f6d <mpsearch+0x2e>

80102fa9 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102fa9:	55                   	push   %ebp
80102faa:	89 e5                	mov    %esp,%ebp
80102fac:	57                   	push   %edi
80102fad:	56                   	push   %esi
80102fae:	53                   	push   %ebx
80102faf:	83 ec 1c             	sub    $0x1c,%esp
80102fb2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102fb5:	e8 85 ff ff ff       	call   80102f3f <mpsearch>
80102fba:	85 c0                	test   %eax,%eax
80102fbc:	74 5c                	je     8010301a <mpconfig+0x71>
80102fbe:	89 c7                	mov    %eax,%edi
80102fc0:	8b 58 04             	mov    0x4(%eax),%ebx
80102fc3:	85 db                	test   %ebx,%ebx
80102fc5:	74 5a                	je     80103021 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102fc7:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102fcd:	83 ec 04             	sub    $0x4,%esp
80102fd0:	6a 04                	push   $0x4
80102fd2:	68 3d 6e 10 80       	push   $0x80106e3d
80102fd7:	56                   	push   %esi
80102fd8:	e8 22 11 00 00       	call   801040ff <memcmp>
80102fdd:	83 c4 10             	add    $0x10,%esp
80102fe0:	85 c0                	test   %eax,%eax
80102fe2:	75 44                	jne    80103028 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102fe4:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102feb:	3c 01                	cmp    $0x1,%al
80102fed:	0f 95 c2             	setne  %dl
80102ff0:	3c 04                	cmp    $0x4,%al
80102ff2:	0f 95 c0             	setne  %al
80102ff5:	84 c2                	test   %al,%dl
80102ff7:	75 36                	jne    8010302f <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102ff9:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80103000:	89 f0                	mov    %esi,%eax
80103002:	e8 c5 fe ff ff       	call   80102ecc <sum>
80103007:	84 c0                	test   %al,%al
80103009:	75 2b                	jne    80103036 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
8010300b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010300e:	89 38                	mov    %edi,(%eax)
  return conf;
}
80103010:	89 f0                	mov    %esi,%eax
80103012:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103015:	5b                   	pop    %ebx
80103016:	5e                   	pop    %esi
80103017:	5f                   	pop    %edi
80103018:	5d                   	pop    %ebp
80103019:	c3                   	ret    
    return 0;
8010301a:	be 00 00 00 00       	mov    $0x0,%esi
8010301f:	eb ef                	jmp    80103010 <mpconfig+0x67>
80103021:	be 00 00 00 00       	mov    $0x0,%esi
80103026:	eb e8                	jmp    80103010 <mpconfig+0x67>
    return 0;
80103028:	be 00 00 00 00       	mov    $0x0,%esi
8010302d:	eb e1                	jmp    80103010 <mpconfig+0x67>
    return 0;
8010302f:	be 00 00 00 00       	mov    $0x0,%esi
80103034:	eb da                	jmp    80103010 <mpconfig+0x67>
    return 0;
80103036:	be 00 00 00 00       	mov    $0x0,%esi
8010303b:	eb d3                	jmp    80103010 <mpconfig+0x67>

8010303d <mpinit>:

void
mpinit(void)
{
8010303d:	55                   	push   %ebp
8010303e:	89 e5                	mov    %esp,%ebp
80103040:	57                   	push   %edi
80103041:	56                   	push   %esi
80103042:	53                   	push   %ebx
80103043:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80103046:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80103049:	e8 5b ff ff ff       	call   80102fa9 <mpconfig>
8010304e:	85 c0                	test   %eax,%eax
80103050:	74 19                	je     8010306b <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80103052:	8b 50 24             	mov    0x24(%eax),%edx
80103055:	89 15 80 26 15 80    	mov    %edx,0x80152680
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010305b:	8d 50 2c             	lea    0x2c(%eax),%edx
8010305e:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80103062:	01 c1                	add    %eax,%ecx
  ismp = 1;
80103064:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103069:	eb 34                	jmp    8010309f <mpinit+0x62>
    panic("Expect to run on an SMP");
8010306b:	83 ec 0c             	sub    $0xc,%esp
8010306e:	68 42 6e 10 80       	push   $0x80106e42
80103073:	e8 d0 d2 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80103078:	8b 35 20 2d 15 80    	mov    0x80152d20,%esi
8010307e:	83 fe 07             	cmp    $0x7,%esi
80103081:	7f 19                	jg     8010309c <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80103083:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80103087:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
8010308d:	88 87 a0 27 15 80    	mov    %al,-0x7fead860(%edi)
        ncpu++;
80103093:	83 c6 01             	add    $0x1,%esi
80103096:	89 35 20 2d 15 80    	mov    %esi,0x80152d20
      }
      p += sizeof(struct mpproc);
8010309c:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010309f:	39 ca                	cmp    %ecx,%edx
801030a1:	73 2b                	jae    801030ce <mpinit+0x91>
    switch(*p){
801030a3:	0f b6 02             	movzbl (%edx),%eax
801030a6:	3c 04                	cmp    $0x4,%al
801030a8:	77 1d                	ja     801030c7 <mpinit+0x8a>
801030aa:	0f b6 c0             	movzbl %al,%eax
801030ad:	ff 24 85 7c 6e 10 80 	jmp    *-0x7fef9184(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
801030b4:	0f b6 42 01          	movzbl 0x1(%edx),%eax
801030b8:	a2 80 27 15 80       	mov    %al,0x80152780
      p += sizeof(struct mpioapic);
801030bd:	83 c2 08             	add    $0x8,%edx
      continue;
801030c0:	eb dd                	jmp    8010309f <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
801030c2:	83 c2 08             	add    $0x8,%edx
      continue;
801030c5:	eb d8                	jmp    8010309f <mpinit+0x62>
    default:
      ismp = 0;
801030c7:	bb 00 00 00 00       	mov    $0x0,%ebx
801030cc:	eb d1                	jmp    8010309f <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
801030ce:	85 db                	test   %ebx,%ebx
801030d0:	74 26                	je     801030f8 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
801030d2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801030d5:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
801030d9:	74 15                	je     801030f0 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801030db:	b8 70 00 00 00       	mov    $0x70,%eax
801030e0:	ba 22 00 00 00       	mov    $0x22,%edx
801030e5:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801030e6:	ba 23 00 00 00       	mov    $0x23,%edx
801030eb:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
801030ec:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801030ef:	ee                   	out    %al,(%dx)
  }
}
801030f0:	8d 65 f4             	lea    -0xc(%ebp),%esp
801030f3:	5b                   	pop    %ebx
801030f4:	5e                   	pop    %esi
801030f5:	5f                   	pop    %edi
801030f6:	5d                   	pop    %ebp
801030f7:	c3                   	ret    
    panic("Didn't find a suitable machine");
801030f8:	83 ec 0c             	sub    $0xc,%esp
801030fb:	68 5c 6e 10 80       	push   $0x80106e5c
80103100:	e8 43 d2 ff ff       	call   80100348 <panic>

80103105 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80103105:	55                   	push   %ebp
80103106:	89 e5                	mov    %esp,%ebp
80103108:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010310d:	ba 21 00 00 00       	mov    $0x21,%edx
80103112:	ee                   	out    %al,(%dx)
80103113:	ba a1 00 00 00       	mov    $0xa1,%edx
80103118:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80103119:	5d                   	pop    %ebp
8010311a:	c3                   	ret    

8010311b <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
8010311b:	55                   	push   %ebp
8010311c:	89 e5                	mov    %esp,%ebp
8010311e:	57                   	push   %edi
8010311f:	56                   	push   %esi
80103120:	53                   	push   %ebx
80103121:	83 ec 0c             	sub    $0xc,%esp
80103124:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103127:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
8010312a:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80103130:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103136:	e8 f2 da ff ff       	call   80100c2d <filealloc>
8010313b:	89 03                	mov    %eax,(%ebx)
8010313d:	85 c0                	test   %eax,%eax
8010313f:	74 1e                	je     8010315f <pipealloc+0x44>
80103141:	e8 e7 da ff ff       	call   80100c2d <filealloc>
80103146:	89 06                	mov    %eax,(%esi)
80103148:	85 c0                	test   %eax,%eax
8010314a:	74 13                	je     8010315f <pipealloc+0x44>
    goto bad;
  // need to pass the pid to kalloc?
  if((p = (struct pipe*)kalloc(0)) == 0)
8010314c:	83 ec 0c             	sub    $0xc,%esp
8010314f:	6a 00                	push   $0x0
80103151:	e8 78 f0 ff ff       	call   801021ce <kalloc>
80103156:	89 c7                	mov    %eax,%edi
80103158:	83 c4 10             	add    $0x10,%esp
8010315b:	85 c0                	test   %eax,%eax
8010315d:	75 35                	jne    80103194 <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
8010315f:	8b 03                	mov    (%ebx),%eax
80103161:	85 c0                	test   %eax,%eax
80103163:	74 0c                	je     80103171 <pipealloc+0x56>
    fileclose(*f0);
80103165:	83 ec 0c             	sub    $0xc,%esp
80103168:	50                   	push   %eax
80103169:	e8 65 db ff ff       	call   80100cd3 <fileclose>
8010316e:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80103171:	8b 06                	mov    (%esi),%eax
80103173:	85 c0                	test   %eax,%eax
80103175:	0f 84 8b 00 00 00    	je     80103206 <pipealloc+0xeb>
    fileclose(*f1);
8010317b:	83 ec 0c             	sub    $0xc,%esp
8010317e:	50                   	push   %eax
8010317f:	e8 4f db ff ff       	call   80100cd3 <fileclose>
80103184:	83 c4 10             	add    $0x10,%esp
  return -1;
80103187:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010318c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010318f:	5b                   	pop    %ebx
80103190:	5e                   	pop    %esi
80103191:	5f                   	pop    %edi
80103192:	5d                   	pop    %ebp
80103193:	c3                   	ret    
  p->readopen = 1;
80103194:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
8010319b:	00 00 00 
  p->writeopen = 1;
8010319e:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801031a5:	00 00 00 
  p->nwrite = 0;
801031a8:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801031af:	00 00 00 
  p->nread = 0;
801031b2:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
801031b9:	00 00 00 
  initlock(&p->lock, "pipe");
801031bc:	83 ec 08             	sub    $0x8,%esp
801031bf:	68 90 6e 10 80       	push   $0x80106e90
801031c4:	50                   	push   %eax
801031c5:	e8 07 0d 00 00       	call   80103ed1 <initlock>
  (*f0)->type = FD_PIPE;
801031ca:	8b 03                	mov    (%ebx),%eax
801031cc:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
801031d2:	8b 03                	mov    (%ebx),%eax
801031d4:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
801031d8:	8b 03                	mov    (%ebx),%eax
801031da:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
801031de:	8b 03                	mov    (%ebx),%eax
801031e0:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
801031e3:	8b 06                	mov    (%esi),%eax
801031e5:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
801031eb:	8b 06                	mov    (%esi),%eax
801031ed:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
801031f1:	8b 06                	mov    (%esi),%eax
801031f3:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
801031f7:	8b 06                	mov    (%esi),%eax
801031f9:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
801031fc:	83 c4 10             	add    $0x10,%esp
801031ff:	b8 00 00 00 00       	mov    $0x0,%eax
80103204:	eb 86                	jmp    8010318c <pipealloc+0x71>
  return -1;
80103206:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010320b:	e9 7c ff ff ff       	jmp    8010318c <pipealloc+0x71>

80103210 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103210:	55                   	push   %ebp
80103211:	89 e5                	mov    %esp,%ebp
80103213:	53                   	push   %ebx
80103214:	83 ec 10             	sub    $0x10,%esp
80103217:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
8010321a:	53                   	push   %ebx
8010321b:	e8 ed 0d 00 00       	call   8010400d <acquire>
  if(writable){
80103220:	83 c4 10             	add    $0x10,%esp
80103223:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103227:	74 3f                	je     80103268 <pipeclose+0x58>
    p->writeopen = 0;
80103229:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80103230:	00 00 00 
    wakeup(&p->nread);
80103233:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103239:	83 ec 0c             	sub    $0xc,%esp
8010323c:	50                   	push   %eax
8010323d:	e8 b1 09 00 00       	call   80103bf3 <wakeup>
80103242:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103245:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
8010324c:	75 09                	jne    80103257 <pipeclose+0x47>
8010324e:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80103255:	74 2f                	je     80103286 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80103257:	83 ec 0c             	sub    $0xc,%esp
8010325a:	53                   	push   %ebx
8010325b:	e8 12 0e 00 00       	call   80104072 <release>
80103260:	83 c4 10             	add    $0x10,%esp
}
80103263:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103266:	c9                   	leave  
80103267:	c3                   	ret    
    p->readopen = 0;
80103268:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
8010326f:	00 00 00 
    wakeup(&p->nwrite);
80103272:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103278:	83 ec 0c             	sub    $0xc,%esp
8010327b:	50                   	push   %eax
8010327c:	e8 72 09 00 00       	call   80103bf3 <wakeup>
80103281:	83 c4 10             	add    $0x10,%esp
80103284:	eb bf                	jmp    80103245 <pipeclose+0x35>
    release(&p->lock);
80103286:	83 ec 0c             	sub    $0xc,%esp
80103289:	53                   	push   %ebx
8010328a:	e8 e3 0d 00 00       	call   80104072 <release>
    kfree((char*)p);
8010328f:	89 1c 24             	mov    %ebx,(%esp)
80103292:	e8 17 ed ff ff       	call   80101fae <kfree>
80103297:	83 c4 10             	add    $0x10,%esp
8010329a:	eb c7                	jmp    80103263 <pipeclose+0x53>

8010329c <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
8010329c:	55                   	push   %ebp
8010329d:	89 e5                	mov    %esp,%ebp
8010329f:	57                   	push   %edi
801032a0:	56                   	push   %esi
801032a1:	53                   	push   %ebx
801032a2:	83 ec 18             	sub    $0x18,%esp
801032a5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801032a8:	89 de                	mov    %ebx,%esi
801032aa:	53                   	push   %ebx
801032ab:	e8 5d 0d 00 00       	call   8010400d <acquire>
  for(i = 0; i < n; i++){
801032b0:	83 c4 10             	add    $0x10,%esp
801032b3:	bf 00 00 00 00       	mov    $0x0,%edi
801032b8:	3b 7d 10             	cmp    0x10(%ebp),%edi
801032bb:	0f 8d 88 00 00 00    	jge    80103349 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801032c1:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
801032c7:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
801032cd:	05 00 02 00 00       	add    $0x200,%eax
801032d2:	39 c2                	cmp    %eax,%edx
801032d4:	75 51                	jne    80103327 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
801032d6:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
801032dd:	74 2f                	je     8010330e <pipewrite+0x72>
801032df:	e8 06 03 00 00       	call   801035ea <myproc>
801032e4:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801032e8:	75 24                	jne    8010330e <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
801032ea:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801032f0:	83 ec 0c             	sub    $0xc,%esp
801032f3:	50                   	push   %eax
801032f4:	e8 fa 08 00 00       	call   80103bf3 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801032f9:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
801032ff:	83 c4 08             	add    $0x8,%esp
80103302:	56                   	push   %esi
80103303:	50                   	push   %eax
80103304:	e8 85 07 00 00       	call   80103a8e <sleep>
80103309:	83 c4 10             	add    $0x10,%esp
8010330c:	eb b3                	jmp    801032c1 <pipewrite+0x25>
        release(&p->lock);
8010330e:	83 ec 0c             	sub    $0xc,%esp
80103311:	53                   	push   %ebx
80103312:	e8 5b 0d 00 00       	call   80104072 <release>
        return -1;
80103317:	83 c4 10             	add    $0x10,%esp
8010331a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
8010331f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103322:	5b                   	pop    %ebx
80103323:	5e                   	pop    %esi
80103324:	5f                   	pop    %edi
80103325:	5d                   	pop    %ebp
80103326:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103327:	8d 42 01             	lea    0x1(%edx),%eax
8010332a:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80103330:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80103336:	8b 45 0c             	mov    0xc(%ebp),%eax
80103339:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
8010333d:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80103341:	83 c7 01             	add    $0x1,%edi
80103344:	e9 6f ff ff ff       	jmp    801032b8 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103349:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010334f:	83 ec 0c             	sub    $0xc,%esp
80103352:	50                   	push   %eax
80103353:	e8 9b 08 00 00       	call   80103bf3 <wakeup>
  release(&p->lock);
80103358:	89 1c 24             	mov    %ebx,(%esp)
8010335b:	e8 12 0d 00 00       	call   80104072 <release>
  return n;
80103360:	83 c4 10             	add    $0x10,%esp
80103363:	8b 45 10             	mov    0x10(%ebp),%eax
80103366:	eb b7                	jmp    8010331f <pipewrite+0x83>

80103368 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103368:	55                   	push   %ebp
80103369:	89 e5                	mov    %esp,%ebp
8010336b:	57                   	push   %edi
8010336c:	56                   	push   %esi
8010336d:	53                   	push   %ebx
8010336e:	83 ec 18             	sub    $0x18,%esp
80103371:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103374:	89 df                	mov    %ebx,%edi
80103376:	53                   	push   %ebx
80103377:	e8 91 0c 00 00       	call   8010400d <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010337c:	83 c4 10             	add    $0x10,%esp
8010337f:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
80103385:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
8010338b:	75 3d                	jne    801033ca <piperead+0x62>
8010338d:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
80103393:	85 f6                	test   %esi,%esi
80103395:	74 38                	je     801033cf <piperead+0x67>
    if(myproc()->killed){
80103397:	e8 4e 02 00 00       	call   801035ea <myproc>
8010339c:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801033a0:	75 15                	jne    801033b7 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801033a2:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801033a8:	83 ec 08             	sub    $0x8,%esp
801033ab:	57                   	push   %edi
801033ac:	50                   	push   %eax
801033ad:	e8 dc 06 00 00       	call   80103a8e <sleep>
801033b2:	83 c4 10             	add    $0x10,%esp
801033b5:	eb c8                	jmp    8010337f <piperead+0x17>
      release(&p->lock);
801033b7:	83 ec 0c             	sub    $0xc,%esp
801033ba:	53                   	push   %ebx
801033bb:	e8 b2 0c 00 00       	call   80104072 <release>
      return -1;
801033c0:	83 c4 10             	add    $0x10,%esp
801033c3:	be ff ff ff ff       	mov    $0xffffffff,%esi
801033c8:	eb 50                	jmp    8010341a <piperead+0xb2>
801033ca:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801033cf:	3b 75 10             	cmp    0x10(%ebp),%esi
801033d2:	7d 2c                	jge    80103400 <piperead+0x98>
    if(p->nread == p->nwrite)
801033d4:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
801033da:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
801033e0:	74 1e                	je     80103400 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801033e2:	8d 50 01             	lea    0x1(%eax),%edx
801033e5:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
801033eb:	25 ff 01 00 00       	and    $0x1ff,%eax
801033f0:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
801033f5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801033f8:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801033fb:	83 c6 01             	add    $0x1,%esi
801033fe:	eb cf                	jmp    801033cf <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103400:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103406:	83 ec 0c             	sub    $0xc,%esp
80103409:	50                   	push   %eax
8010340a:	e8 e4 07 00 00       	call   80103bf3 <wakeup>
  release(&p->lock);
8010340f:	89 1c 24             	mov    %ebx,(%esp)
80103412:	e8 5b 0c 00 00       	call   80104072 <release>
  return i;
80103417:	83 c4 10             	add    $0x10,%esp
}
8010341a:	89 f0                	mov    %esi,%eax
8010341c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010341f:	5b                   	pop    %ebx
80103420:	5e                   	pop    %esi
80103421:	5f                   	pop    %edi
80103422:	5d                   	pop    %ebp
80103423:	c3                   	ret    

80103424 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80103424:	55                   	push   %ebp
80103425:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103427:	ba 74 2d 15 80       	mov    $0x80152d74,%edx
8010342c:	eb 03                	jmp    80103431 <wakeup1+0xd>
8010342e:	83 c2 7c             	add    $0x7c,%edx
80103431:	81 fa 74 4c 15 80    	cmp    $0x80154c74,%edx
80103437:	73 14                	jae    8010344d <wakeup1+0x29>
    if (p->state == SLEEPING && p->chan == chan)
80103439:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
8010343d:	75 ef                	jne    8010342e <wakeup1+0xa>
8010343f:	39 42 20             	cmp    %eax,0x20(%edx)
80103442:	75 ea                	jne    8010342e <wakeup1+0xa>
      p->state = RUNNABLE;
80103444:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
8010344b:	eb e1                	jmp    8010342e <wakeup1+0xa>
}
8010344d:	5d                   	pop    %ebp
8010344e:	c3                   	ret    

8010344f <allocproc>:
{
8010344f:	55                   	push   %ebp
80103450:	89 e5                	mov    %esp,%ebp
80103452:	53                   	push   %ebx
80103453:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
80103456:	68 40 2d 15 80       	push   $0x80152d40
8010345b:	e8 ad 0b 00 00       	call   8010400d <acquire>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103460:	83 c4 10             	add    $0x10,%esp
80103463:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
80103468:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
8010346e:	73 0b                	jae    8010347b <allocproc+0x2c>
    if (p->state == UNUSED)
80103470:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
80103474:	74 1c                	je     80103492 <allocproc+0x43>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103476:	83 c3 7c             	add    $0x7c,%ebx
80103479:	eb ed                	jmp    80103468 <allocproc+0x19>
  release(&ptable.lock);
8010347b:	83 ec 0c             	sub    $0xc,%esp
8010347e:	68 40 2d 15 80       	push   $0x80152d40
80103483:	e8 ea 0b 00 00       	call   80104072 <release>
  return 0;
80103488:	83 c4 10             	add    $0x10,%esp
8010348b:	bb 00 00 00 00       	mov    $0x0,%ebx
80103490:	eb 6f                	jmp    80103501 <allocproc+0xb2>
  p->state = EMBRYO;
80103492:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
80103499:	a1 04 a0 10 80       	mov    0x8010a004,%eax
8010349e:	8d 50 01             	lea    0x1(%eax),%edx
801034a1:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
801034a7:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
801034aa:	83 ec 0c             	sub    $0xc,%esp
801034ad:	68 40 2d 15 80       	push   $0x80152d40
801034b2:	e8 bb 0b 00 00       	call   80104072 <release>
  if ((p->kstack = kalloc(p->pid)) == 0)
801034b7:	83 c4 04             	add    $0x4,%esp
801034ba:	ff 73 10             	pushl  0x10(%ebx)
801034bd:	e8 0c ed ff ff       	call   801021ce <kalloc>
801034c2:	89 43 08             	mov    %eax,0x8(%ebx)
801034c5:	83 c4 10             	add    $0x10,%esp
801034c8:	85 c0                	test   %eax,%eax
801034ca:	74 3c                	je     80103508 <allocproc+0xb9>
  sp -= sizeof *p->tf;
801034cc:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe *)sp;
801034d2:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint *)sp = (uint)trapret;
801034d5:	c7 80 b0 0f 00 00 cf 	movl   $0x801051cf,0xfb0(%eax)
801034dc:	51 10 80 
  sp -= sizeof *p->context;
801034df:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context *)sp;
801034e4:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
801034e7:	83 ec 04             	sub    $0x4,%esp
801034ea:	6a 14                	push   $0x14
801034ec:	6a 00                	push   $0x0
801034ee:	50                   	push   %eax
801034ef:	e8 c5 0b 00 00       	call   801040b9 <memset>
  p->context->eip = (uint)forkret;
801034f4:	8b 43 1c             	mov    0x1c(%ebx),%eax
801034f7:	c7 40 10 16 35 10 80 	movl   $0x80103516,0x10(%eax)
  return p;
801034fe:	83 c4 10             	add    $0x10,%esp
}
80103501:	89 d8                	mov    %ebx,%eax
80103503:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103506:	c9                   	leave  
80103507:	c3                   	ret    
    p->state = UNUSED;
80103508:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
8010350f:	bb 00 00 00 00       	mov    $0x0,%ebx
80103514:	eb eb                	jmp    80103501 <allocproc+0xb2>

80103516 <forkret>:
{
80103516:	55                   	push   %ebp
80103517:	89 e5                	mov    %esp,%ebp
80103519:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
8010351c:	68 40 2d 15 80       	push   $0x80152d40
80103521:	e8 4c 0b 00 00       	call   80104072 <release>
  if (first)
80103526:	83 c4 10             	add    $0x10,%esp
80103529:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
80103530:	75 02                	jne    80103534 <forkret+0x1e>
}
80103532:	c9                   	leave  
80103533:	c3                   	ret    
    first = 0;
80103534:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
8010353b:	00 00 00 
    iinit(ROOTDEV);
8010353e:	83 ec 0c             	sub    $0xc,%esp
80103541:	6a 01                	push   $0x1
80103543:	e8 a4 dd ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
80103548:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010354f:	e8 ec f5 ff ff       	call   80102b40 <initlog>
80103554:	83 c4 10             	add    $0x10,%esp
}
80103557:	eb d9                	jmp    80103532 <forkret+0x1c>

80103559 <pinit>:
{
80103559:	55                   	push   %ebp
8010355a:	89 e5                	mov    %esp,%ebp
8010355c:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
8010355f:	68 95 6e 10 80       	push   $0x80106e95
80103564:	68 40 2d 15 80       	push   $0x80152d40
80103569:	e8 63 09 00 00       	call   80103ed1 <initlock>
}
8010356e:	83 c4 10             	add    $0x10,%esp
80103571:	c9                   	leave  
80103572:	c3                   	ret    

80103573 <mycpu>:
{
80103573:	55                   	push   %ebp
80103574:	89 e5                	mov    %esp,%ebp
80103576:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103579:	9c                   	pushf  
8010357a:	58                   	pop    %eax
  if (readeflags() & FL_IF)
8010357b:	f6 c4 02             	test   $0x2,%ah
8010357e:	75 28                	jne    801035a8 <mycpu+0x35>
  apicid = lapicid();
80103580:	e8 d4 f1 ff ff       	call   80102759 <lapicid>
  for (i = 0; i < ncpu; ++i)
80103585:	ba 00 00 00 00       	mov    $0x0,%edx
8010358a:	39 15 20 2d 15 80    	cmp    %edx,0x80152d20
80103590:	7e 23                	jle    801035b5 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
80103592:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
80103598:	0f b6 89 a0 27 15 80 	movzbl -0x7fead860(%ecx),%ecx
8010359f:	39 c1                	cmp    %eax,%ecx
801035a1:	74 1f                	je     801035c2 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i)
801035a3:	83 c2 01             	add    $0x1,%edx
801035a6:	eb e2                	jmp    8010358a <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
801035a8:	83 ec 0c             	sub    $0xc,%esp
801035ab:	68 78 6f 10 80       	push   $0x80106f78
801035b0:	e8 93 cd ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
801035b5:	83 ec 0c             	sub    $0xc,%esp
801035b8:	68 9c 6e 10 80       	push   $0x80106e9c
801035bd:	e8 86 cd ff ff       	call   80100348 <panic>
      return &cpus[i];
801035c2:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
801035c8:	05 a0 27 15 80       	add    $0x801527a0,%eax
}
801035cd:	c9                   	leave  
801035ce:	c3                   	ret    

801035cf <cpuid>:
{
801035cf:	55                   	push   %ebp
801035d0:	89 e5                	mov    %esp,%ebp
801035d2:	83 ec 08             	sub    $0x8,%esp
  return mycpu() - cpus;
801035d5:	e8 99 ff ff ff       	call   80103573 <mycpu>
801035da:	2d a0 27 15 80       	sub    $0x801527a0,%eax
801035df:	c1 f8 04             	sar    $0x4,%eax
801035e2:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
801035e8:	c9                   	leave  
801035e9:	c3                   	ret    

801035ea <myproc>:
{
801035ea:	55                   	push   %ebp
801035eb:	89 e5                	mov    %esp,%ebp
801035ed:	53                   	push   %ebx
801035ee:	83 ec 04             	sub    $0x4,%esp
  pushcli();
801035f1:	e8 3a 09 00 00       	call   80103f30 <pushcli>
  c = mycpu();
801035f6:	e8 78 ff ff ff       	call   80103573 <mycpu>
  p = c->proc;
801035fb:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103601:	e8 67 09 00 00       	call   80103f6d <popcli>
}
80103606:	89 d8                	mov    %ebx,%eax
80103608:	83 c4 04             	add    $0x4,%esp
8010360b:	5b                   	pop    %ebx
8010360c:	5d                   	pop    %ebp
8010360d:	c3                   	ret    

8010360e <userinit>:
{
8010360e:	55                   	push   %ebp
8010360f:	89 e5                	mov    %esp,%ebp
80103611:	53                   	push   %ebx
80103612:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
80103615:	e8 35 fe ff ff       	call   8010344f <allocproc>
8010361a:	89 c3                	mov    %eax,%ebx
  initproc = p;
8010361c:	a3 b8 a5 10 80       	mov    %eax,0x8010a5b8
  if ((p->pgdir = setupkvm()) == 0)
80103621:	e8 a6 30 00 00       	call   801066cc <setupkvm>
80103626:	89 43 04             	mov    %eax,0x4(%ebx)
80103629:	85 c0                	test   %eax,%eax
8010362b:	0f 84 b7 00 00 00    	je     801036e8 <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103631:	83 ec 04             	sub    $0x4,%esp
80103634:	68 2c 00 00 00       	push   $0x2c
80103639:	68 60 a4 10 80       	push   $0x8010a460
8010363e:	50                   	push   %eax
8010363f:	e8 7a 2d 00 00       	call   801063be <inituvm>
  p->sz = PGSIZE;
80103644:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
8010364a:	83 c4 0c             	add    $0xc,%esp
8010364d:	6a 4c                	push   $0x4c
8010364f:	6a 00                	push   $0x0
80103651:	ff 73 18             	pushl  0x18(%ebx)
80103654:	e8 60 0a 00 00       	call   801040b9 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80103659:	8b 43 18             	mov    0x18(%ebx),%eax
8010365c:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80103662:	8b 43 18             	mov    0x18(%ebx),%eax
80103665:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010366b:	8b 43 18             	mov    0x18(%ebx),%eax
8010366e:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103672:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80103676:	8b 43 18             	mov    0x18(%ebx),%eax
80103679:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
8010367d:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80103681:	8b 43 18             	mov    0x18(%ebx),%eax
80103684:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
8010368b:	8b 43 18             	mov    0x18(%ebx),%eax
8010368e:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0; // beginning of initcode.S
80103695:	8b 43 18             	mov    0x18(%ebx),%eax
80103698:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
8010369f:	8d 43 6c             	lea    0x6c(%ebx),%eax
801036a2:	83 c4 0c             	add    $0xc,%esp
801036a5:	6a 10                	push   $0x10
801036a7:	68 c5 6e 10 80       	push   $0x80106ec5
801036ac:	50                   	push   %eax
801036ad:	e8 6e 0b 00 00       	call   80104220 <safestrcpy>
  p->cwd = namei("/");
801036b2:	c7 04 24 ce 6e 10 80 	movl   $0x80106ece,(%esp)
801036b9:	e8 23 e5 ff ff       	call   80101be1 <namei>
801036be:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
801036c1:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
801036c8:	e8 40 09 00 00       	call   8010400d <acquire>
  p->state = RUNNABLE;
801036cd:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
801036d4:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
801036db:	e8 92 09 00 00       	call   80104072 <release>
}
801036e0:	83 c4 10             	add    $0x10,%esp
801036e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801036e6:	c9                   	leave  
801036e7:	c3                   	ret    
    panic("userinit: out of memory?");
801036e8:	83 ec 0c             	sub    $0xc,%esp
801036eb:	68 ac 6e 10 80       	push   $0x80106eac
801036f0:	e8 53 cc ff ff       	call   80100348 <panic>

801036f5 <growproc>:
{
801036f5:	55                   	push   %ebp
801036f6:	89 e5                	mov    %esp,%ebp
801036f8:	56                   	push   %esi
801036f9:	53                   	push   %ebx
801036fa:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
801036fd:	e8 e8 fe ff ff       	call   801035ea <myproc>
80103702:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103704:	8b 00                	mov    (%eax),%eax
  if (n > 0)
80103706:	85 f6                	test   %esi,%esi
80103708:	7f 21                	jg     8010372b <growproc+0x36>
  else if (n < 0)
8010370a:	85 f6                	test   %esi,%esi
8010370c:	79 33                	jns    80103741 <growproc+0x4c>
    if ((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010370e:	83 ec 04             	sub    $0x4,%esp
80103711:	01 c6                	add    %eax,%esi
80103713:	56                   	push   %esi
80103714:	50                   	push   %eax
80103715:	ff 73 04             	pushl  0x4(%ebx)
80103718:	e8 aa 2d 00 00       	call   801064c7 <deallocuvm>
8010371d:	83 c4 10             	add    $0x10,%esp
80103720:	85 c0                	test   %eax,%eax
80103722:	75 1d                	jne    80103741 <growproc+0x4c>
      return -1;
80103724:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103729:	eb 29                	jmp    80103754 <growproc+0x5f>
    if ((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010372b:	83 ec 04             	sub    $0x4,%esp
8010372e:	01 c6                	add    %eax,%esi
80103730:	56                   	push   %esi
80103731:	50                   	push   %eax
80103732:	ff 73 04             	pushl  0x4(%ebx)
80103735:	e8 1f 2e 00 00       	call   80106559 <allocuvm>
8010373a:	83 c4 10             	add    $0x10,%esp
8010373d:	85 c0                	test   %eax,%eax
8010373f:	74 1a                	je     8010375b <growproc+0x66>
  curproc->sz = sz;
80103741:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
80103743:	83 ec 0c             	sub    $0xc,%esp
80103746:	53                   	push   %ebx
80103747:	e8 5a 2b 00 00       	call   801062a6 <switchuvm>
  return 0;
8010374c:	83 c4 10             	add    $0x10,%esp
8010374f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103754:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103757:	5b                   	pop    %ebx
80103758:	5e                   	pop    %esi
80103759:	5d                   	pop    %ebp
8010375a:	c3                   	ret    
      return -1;
8010375b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103760:	eb f2                	jmp    80103754 <growproc+0x5f>

80103762 <fork>:
{
80103762:	55                   	push   %ebp
80103763:	89 e5                	mov    %esp,%ebp
80103765:	57                   	push   %edi
80103766:	56                   	push   %esi
80103767:	53                   	push   %ebx
80103768:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
8010376b:	e8 7a fe ff ff       	call   801035ea <myproc>
80103770:	89 c3                	mov    %eax,%ebx
  if ((np = allocproc()) == 0)
80103772:	e8 d8 fc ff ff       	call   8010344f <allocproc>
80103777:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010377a:	85 c0                	test   %eax,%eax
8010377c:	0f 84 e0 00 00 00    	je     80103862 <fork+0x100>
80103782:	89 c7                	mov    %eax,%edi
  if ((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0)
80103784:	83 ec 08             	sub    $0x8,%esp
80103787:	ff 33                	pushl  (%ebx)
80103789:	ff 73 04             	pushl  0x4(%ebx)
8010378c:	e8 ec 2f 00 00       	call   8010677d <copyuvm>
80103791:	89 47 04             	mov    %eax,0x4(%edi)
80103794:	83 c4 10             	add    $0x10,%esp
80103797:	85 c0                	test   %eax,%eax
80103799:	74 2a                	je     801037c5 <fork+0x63>
  np->sz = curproc->sz;
8010379b:	8b 03                	mov    (%ebx),%eax
8010379d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801037a0:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
801037a2:	89 c8                	mov    %ecx,%eax
801037a4:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
801037a7:	8b 73 18             	mov    0x18(%ebx),%esi
801037aa:	8b 79 18             	mov    0x18(%ecx),%edi
801037ad:	b9 13 00 00 00       	mov    $0x13,%ecx
801037b2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
801037b4:	8b 40 18             	mov    0x18(%eax),%eax
801037b7:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for (i = 0; i < NOFILE; i++)
801037be:	be 00 00 00 00       	mov    $0x0,%esi
801037c3:	eb 29                	jmp    801037ee <fork+0x8c>
    kfree(np->kstack);
801037c5:	83 ec 0c             	sub    $0xc,%esp
801037c8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801037cb:	ff 73 08             	pushl  0x8(%ebx)
801037ce:	e8 db e7 ff ff       	call   80101fae <kfree>
    np->kstack = 0;
801037d3:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
801037da:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
801037e1:	83 c4 10             	add    $0x10,%esp
801037e4:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801037e9:	eb 6d                	jmp    80103858 <fork+0xf6>
  for (i = 0; i < NOFILE; i++)
801037eb:	83 c6 01             	add    $0x1,%esi
801037ee:	83 fe 0f             	cmp    $0xf,%esi
801037f1:	7f 1d                	jg     80103810 <fork+0xae>
    if (curproc->ofile[i])
801037f3:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
801037f7:	85 c0                	test   %eax,%eax
801037f9:	74 f0                	je     801037eb <fork+0x89>
      np->ofile[i] = filedup(curproc->ofile[i]);
801037fb:	83 ec 0c             	sub    $0xc,%esp
801037fe:	50                   	push   %eax
801037ff:	e8 8a d4 ff ff       	call   80100c8e <filedup>
80103804:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103807:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
8010380b:	83 c4 10             	add    $0x10,%esp
8010380e:	eb db                	jmp    801037eb <fork+0x89>
  np->cwd = idup(curproc->cwd);
80103810:	83 ec 0c             	sub    $0xc,%esp
80103813:	ff 73 68             	pushl  0x68(%ebx)
80103816:	e8 36 dd ff ff       	call   80101551 <idup>
8010381b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010381e:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103821:	83 c3 6c             	add    $0x6c,%ebx
80103824:	8d 47 6c             	lea    0x6c(%edi),%eax
80103827:	83 c4 0c             	add    $0xc,%esp
8010382a:	6a 10                	push   $0x10
8010382c:	53                   	push   %ebx
8010382d:	50                   	push   %eax
8010382e:	e8 ed 09 00 00       	call   80104220 <safestrcpy>
  pid = np->pid;
80103833:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
80103836:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
8010383d:	e8 cb 07 00 00       	call   8010400d <acquire>
  np->state = RUNNABLE;
80103842:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
80103849:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
80103850:	e8 1d 08 00 00       	call   80104072 <release>
  return pid;
80103855:	83 c4 10             	add    $0x10,%esp
}
80103858:	89 d8                	mov    %ebx,%eax
8010385a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010385d:	5b                   	pop    %ebx
8010385e:	5e                   	pop    %esi
8010385f:	5f                   	pop    %edi
80103860:	5d                   	pop    %ebp
80103861:	c3                   	ret    
    return -1;
80103862:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103867:	eb ef                	jmp    80103858 <fork+0xf6>

80103869 <scheduler>:
{
80103869:	55                   	push   %ebp
8010386a:	89 e5                	mov    %esp,%ebp
8010386c:	56                   	push   %esi
8010386d:	53                   	push   %ebx
  struct cpu *c = mycpu();
8010386e:	e8 00 fd ff ff       	call   80103573 <mycpu>
80103873:	89 c6                	mov    %eax,%esi
  c->proc = 0;
80103875:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
8010387c:	00 00 00 
8010387f:	eb 5a                	jmp    801038db <scheduler+0x72>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103881:	83 c3 7c             	add    $0x7c,%ebx
80103884:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
8010388a:	73 3f                	jae    801038cb <scheduler+0x62>
      if (p->state != RUNNABLE)
8010388c:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
80103890:	75 ef                	jne    80103881 <scheduler+0x18>
      c->proc = p;
80103892:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
80103898:	83 ec 0c             	sub    $0xc,%esp
8010389b:	53                   	push   %ebx
8010389c:	e8 05 2a 00 00       	call   801062a6 <switchuvm>
      p->state = RUNNING;
801038a1:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
801038a8:	83 c4 08             	add    $0x8,%esp
801038ab:	ff 73 1c             	pushl  0x1c(%ebx)
801038ae:	8d 46 04             	lea    0x4(%esi),%eax
801038b1:	50                   	push   %eax
801038b2:	e8 bc 09 00 00       	call   80104273 <swtch>
      switchkvm();
801038b7:	e8 d8 29 00 00       	call   80106294 <switchkvm>
      c->proc = 0;
801038bc:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
801038c3:	00 00 00 
801038c6:	83 c4 10             	add    $0x10,%esp
801038c9:	eb b6                	jmp    80103881 <scheduler+0x18>
    release(&ptable.lock);
801038cb:	83 ec 0c             	sub    $0xc,%esp
801038ce:	68 40 2d 15 80       	push   $0x80152d40
801038d3:	e8 9a 07 00 00       	call   80104072 <release>
    sti();
801038d8:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
801038db:	fb                   	sti    
    acquire(&ptable.lock);
801038dc:	83 ec 0c             	sub    $0xc,%esp
801038df:	68 40 2d 15 80       	push   $0x80152d40
801038e4:	e8 24 07 00 00       	call   8010400d <acquire>
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801038e9:	83 c4 10             	add    $0x10,%esp
801038ec:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
801038f1:	eb 91                	jmp    80103884 <scheduler+0x1b>

801038f3 <sched>:
{
801038f3:	55                   	push   %ebp
801038f4:	89 e5                	mov    %esp,%ebp
801038f6:	56                   	push   %esi
801038f7:	53                   	push   %ebx
  struct proc *p = myproc();
801038f8:	e8 ed fc ff ff       	call   801035ea <myproc>
801038fd:	89 c3                	mov    %eax,%ebx
  if (!holding(&ptable.lock))
801038ff:	83 ec 0c             	sub    $0xc,%esp
80103902:	68 40 2d 15 80       	push   $0x80152d40
80103907:	e8 c1 06 00 00       	call   80103fcd <holding>
8010390c:	83 c4 10             	add    $0x10,%esp
8010390f:	85 c0                	test   %eax,%eax
80103911:	74 4f                	je     80103962 <sched+0x6f>
  if (mycpu()->ncli != 1)
80103913:	e8 5b fc ff ff       	call   80103573 <mycpu>
80103918:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
8010391f:	75 4e                	jne    8010396f <sched+0x7c>
  if (p->state == RUNNING)
80103921:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103925:	74 55                	je     8010397c <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103927:	9c                   	pushf  
80103928:	58                   	pop    %eax
  if (readeflags() & FL_IF)
80103929:	f6 c4 02             	test   $0x2,%ah
8010392c:	75 5b                	jne    80103989 <sched+0x96>
  intena = mycpu()->intena;
8010392e:	e8 40 fc ff ff       	call   80103573 <mycpu>
80103933:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
80103939:	e8 35 fc ff ff       	call   80103573 <mycpu>
8010393e:	83 ec 08             	sub    $0x8,%esp
80103941:	ff 70 04             	pushl  0x4(%eax)
80103944:	83 c3 1c             	add    $0x1c,%ebx
80103947:	53                   	push   %ebx
80103948:	e8 26 09 00 00       	call   80104273 <swtch>
  mycpu()->intena = intena;
8010394d:	e8 21 fc ff ff       	call   80103573 <mycpu>
80103952:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
80103958:	83 c4 10             	add    $0x10,%esp
8010395b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010395e:	5b                   	pop    %ebx
8010395f:	5e                   	pop    %esi
80103960:	5d                   	pop    %ebp
80103961:	c3                   	ret    
    panic("sched ptable.lock");
80103962:	83 ec 0c             	sub    $0xc,%esp
80103965:	68 d0 6e 10 80       	push   $0x80106ed0
8010396a:	e8 d9 c9 ff ff       	call   80100348 <panic>
    panic("sched locks");
8010396f:	83 ec 0c             	sub    $0xc,%esp
80103972:	68 e2 6e 10 80       	push   $0x80106ee2
80103977:	e8 cc c9 ff ff       	call   80100348 <panic>
    panic("sched running");
8010397c:	83 ec 0c             	sub    $0xc,%esp
8010397f:	68 ee 6e 10 80       	push   $0x80106eee
80103984:	e8 bf c9 ff ff       	call   80100348 <panic>
    panic("sched interruptible");
80103989:	83 ec 0c             	sub    $0xc,%esp
8010398c:	68 fc 6e 10 80       	push   $0x80106efc
80103991:	e8 b2 c9 ff ff       	call   80100348 <panic>

80103996 <exit>:
{
80103996:	55                   	push   %ebp
80103997:	89 e5                	mov    %esp,%ebp
80103999:	56                   	push   %esi
8010399a:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010399b:	e8 4a fc ff ff       	call   801035ea <myproc>
  if (curproc == initproc)
801039a0:	39 05 b8 a5 10 80    	cmp    %eax,0x8010a5b8
801039a6:	74 09                	je     801039b1 <exit+0x1b>
801039a8:	89 c6                	mov    %eax,%esi
  for (fd = 0; fd < NOFILE; fd++)
801039aa:	bb 00 00 00 00       	mov    $0x0,%ebx
801039af:	eb 10                	jmp    801039c1 <exit+0x2b>
    panic("init exiting");
801039b1:	83 ec 0c             	sub    $0xc,%esp
801039b4:	68 10 6f 10 80       	push   $0x80106f10
801039b9:	e8 8a c9 ff ff       	call   80100348 <panic>
  for (fd = 0; fd < NOFILE; fd++)
801039be:	83 c3 01             	add    $0x1,%ebx
801039c1:	83 fb 0f             	cmp    $0xf,%ebx
801039c4:	7f 1e                	jg     801039e4 <exit+0x4e>
    if (curproc->ofile[fd])
801039c6:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
801039ca:	85 c0                	test   %eax,%eax
801039cc:	74 f0                	je     801039be <exit+0x28>
      fileclose(curproc->ofile[fd]);
801039ce:	83 ec 0c             	sub    $0xc,%esp
801039d1:	50                   	push   %eax
801039d2:	e8 fc d2 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
801039d7:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
801039de:	00 
801039df:	83 c4 10             	add    $0x10,%esp
801039e2:	eb da                	jmp    801039be <exit+0x28>
  begin_op();
801039e4:	e8 a0 f1 ff ff       	call   80102b89 <begin_op>
  iput(curproc->cwd);
801039e9:	83 ec 0c             	sub    $0xc,%esp
801039ec:	ff 76 68             	pushl  0x68(%esi)
801039ef:	e8 94 dc ff ff       	call   80101688 <iput>
  end_op();
801039f4:	e8 0a f2 ff ff       	call   80102c03 <end_op>
  curproc->cwd = 0;
801039f9:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103a00:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
80103a07:	e8 01 06 00 00       	call   8010400d <acquire>
  wakeup1(curproc->parent);
80103a0c:	8b 46 14             	mov    0x14(%esi),%eax
80103a0f:	e8 10 fa ff ff       	call   80103424 <wakeup1>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103a14:	83 c4 10             	add    $0x10,%esp
80103a17:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
80103a1c:	eb 03                	jmp    80103a21 <exit+0x8b>
80103a1e:	83 c3 7c             	add    $0x7c,%ebx
80103a21:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
80103a27:	73 1a                	jae    80103a43 <exit+0xad>
    if (p->parent == curproc)
80103a29:	39 73 14             	cmp    %esi,0x14(%ebx)
80103a2c:	75 f0                	jne    80103a1e <exit+0x88>
      p->parent = initproc;
80103a2e:	a1 b8 a5 10 80       	mov    0x8010a5b8,%eax
80103a33:	89 43 14             	mov    %eax,0x14(%ebx)
      if (p->state == ZOMBIE)
80103a36:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103a3a:	75 e2                	jne    80103a1e <exit+0x88>
        wakeup1(initproc);
80103a3c:	e8 e3 f9 ff ff       	call   80103424 <wakeup1>
80103a41:	eb db                	jmp    80103a1e <exit+0x88>
  curproc->state = ZOMBIE;
80103a43:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
80103a4a:	e8 a4 fe ff ff       	call   801038f3 <sched>
  panic("zombie exit");
80103a4f:	83 ec 0c             	sub    $0xc,%esp
80103a52:	68 1d 6f 10 80       	push   $0x80106f1d
80103a57:	e8 ec c8 ff ff       	call   80100348 <panic>

80103a5c <yield>:
{
80103a5c:	55                   	push   %ebp
80103a5d:	89 e5                	mov    %esp,%ebp
80103a5f:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock); //DOC: yieldlock
80103a62:	68 40 2d 15 80       	push   $0x80152d40
80103a67:	e8 a1 05 00 00       	call   8010400d <acquire>
  myproc()->state = RUNNABLE;
80103a6c:	e8 79 fb ff ff       	call   801035ea <myproc>
80103a71:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80103a78:	e8 76 fe ff ff       	call   801038f3 <sched>
  release(&ptable.lock);
80103a7d:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
80103a84:	e8 e9 05 00 00       	call   80104072 <release>
}
80103a89:	83 c4 10             	add    $0x10,%esp
80103a8c:	c9                   	leave  
80103a8d:	c3                   	ret    

80103a8e <sleep>:
{
80103a8e:	55                   	push   %ebp
80103a8f:	89 e5                	mov    %esp,%ebp
80103a91:	56                   	push   %esi
80103a92:	53                   	push   %ebx
80103a93:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
80103a96:	e8 4f fb ff ff       	call   801035ea <myproc>
  if (p == 0)
80103a9b:	85 c0                	test   %eax,%eax
80103a9d:	74 66                	je     80103b05 <sleep+0x77>
80103a9f:	89 c6                	mov    %eax,%esi
  if (lk == 0)
80103aa1:	85 db                	test   %ebx,%ebx
80103aa3:	74 6d                	je     80103b12 <sleep+0x84>
  if (lk != &ptable.lock)
80103aa5:	81 fb 40 2d 15 80    	cmp    $0x80152d40,%ebx
80103aab:	74 18                	je     80103ac5 <sleep+0x37>
    acquire(&ptable.lock); //DOC: sleeplock1
80103aad:	83 ec 0c             	sub    $0xc,%esp
80103ab0:	68 40 2d 15 80       	push   $0x80152d40
80103ab5:	e8 53 05 00 00       	call   8010400d <acquire>
    release(lk);
80103aba:	89 1c 24             	mov    %ebx,(%esp)
80103abd:	e8 b0 05 00 00       	call   80104072 <release>
80103ac2:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103ac5:	8b 45 08             	mov    0x8(%ebp),%eax
80103ac8:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
80103acb:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
80103ad2:	e8 1c fe ff ff       	call   801038f3 <sched>
  p->chan = 0;
80103ad7:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if (lk != &ptable.lock)
80103ade:	81 fb 40 2d 15 80    	cmp    $0x80152d40,%ebx
80103ae4:	74 18                	je     80103afe <sleep+0x70>
    release(&ptable.lock);
80103ae6:	83 ec 0c             	sub    $0xc,%esp
80103ae9:	68 40 2d 15 80       	push   $0x80152d40
80103aee:	e8 7f 05 00 00       	call   80104072 <release>
    acquire(lk);
80103af3:	89 1c 24             	mov    %ebx,(%esp)
80103af6:	e8 12 05 00 00       	call   8010400d <acquire>
80103afb:	83 c4 10             	add    $0x10,%esp
}
80103afe:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b01:	5b                   	pop    %ebx
80103b02:	5e                   	pop    %esi
80103b03:	5d                   	pop    %ebp
80103b04:	c3                   	ret    
    panic("sleep");
80103b05:	83 ec 0c             	sub    $0xc,%esp
80103b08:	68 29 6f 10 80       	push   $0x80106f29
80103b0d:	e8 36 c8 ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103b12:	83 ec 0c             	sub    $0xc,%esp
80103b15:	68 2f 6f 10 80       	push   $0x80106f2f
80103b1a:	e8 29 c8 ff ff       	call   80100348 <panic>

80103b1f <wait>:
{
80103b1f:	55                   	push   %ebp
80103b20:	89 e5                	mov    %esp,%ebp
80103b22:	56                   	push   %esi
80103b23:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103b24:	e8 c1 fa ff ff       	call   801035ea <myproc>
80103b29:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
80103b2b:	83 ec 0c             	sub    $0xc,%esp
80103b2e:	68 40 2d 15 80       	push   $0x80152d40
80103b33:	e8 d5 04 00 00       	call   8010400d <acquire>
80103b38:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
80103b3b:	b8 00 00 00 00       	mov    $0x0,%eax
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103b40:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
80103b45:	eb 5b                	jmp    80103ba2 <wait+0x83>
        pid = p->pid;
80103b47:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
80103b4a:	83 ec 0c             	sub    $0xc,%esp
80103b4d:	ff 73 08             	pushl  0x8(%ebx)
80103b50:	e8 59 e4 ff ff       	call   80101fae <kfree>
        p->kstack = 0;
80103b55:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
80103b5c:	83 c4 04             	add    $0x4,%esp
80103b5f:	ff 73 04             	pushl  0x4(%ebx)
80103b62:	e8 f5 2a 00 00       	call   8010665c <freevm>
        p->pid = 0;
80103b67:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103b6e:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103b75:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
80103b79:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
80103b80:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
80103b87:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
80103b8e:	e8 df 04 00 00       	call   80104072 <release>
        return pid;
80103b93:	83 c4 10             	add    $0x10,%esp
}
80103b96:	89 f0                	mov    %esi,%eax
80103b98:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b9b:	5b                   	pop    %ebx
80103b9c:	5e                   	pop    %esi
80103b9d:	5d                   	pop    %ebp
80103b9e:	c3                   	ret    
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103b9f:	83 c3 7c             	add    $0x7c,%ebx
80103ba2:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
80103ba8:	73 12                	jae    80103bbc <wait+0x9d>
      if (p->parent != curproc)
80103baa:	39 73 14             	cmp    %esi,0x14(%ebx)
80103bad:	75 f0                	jne    80103b9f <wait+0x80>
      if (p->state == ZOMBIE)
80103baf:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103bb3:	74 92                	je     80103b47 <wait+0x28>
      havekids = 1;
80103bb5:	b8 01 00 00 00       	mov    $0x1,%eax
80103bba:	eb e3                	jmp    80103b9f <wait+0x80>
    if (!havekids || curproc->killed)
80103bbc:	85 c0                	test   %eax,%eax
80103bbe:	74 06                	je     80103bc6 <wait+0xa7>
80103bc0:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103bc4:	74 17                	je     80103bdd <wait+0xbe>
      release(&ptable.lock);
80103bc6:	83 ec 0c             	sub    $0xc,%esp
80103bc9:	68 40 2d 15 80       	push   $0x80152d40
80103bce:	e8 9f 04 00 00       	call   80104072 <release>
      return -1;
80103bd3:	83 c4 10             	add    $0x10,%esp
80103bd6:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103bdb:	eb b9                	jmp    80103b96 <wait+0x77>
    sleep(curproc, &ptable.lock); //DOC: wait-sleep
80103bdd:	83 ec 08             	sub    $0x8,%esp
80103be0:	68 40 2d 15 80       	push   $0x80152d40
80103be5:	56                   	push   %esi
80103be6:	e8 a3 fe ff ff       	call   80103a8e <sleep>
    havekids = 0;
80103beb:	83 c4 10             	add    $0x10,%esp
80103bee:	e9 48 ff ff ff       	jmp    80103b3b <wait+0x1c>

80103bf3 <wakeup>:

// Wake up all processes sleeping on chan.
void wakeup(void *chan)
{
80103bf3:	55                   	push   %ebp
80103bf4:	89 e5                	mov    %esp,%ebp
80103bf6:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103bf9:	68 40 2d 15 80       	push   $0x80152d40
80103bfe:	e8 0a 04 00 00       	call   8010400d <acquire>
  wakeup1(chan);
80103c03:	8b 45 08             	mov    0x8(%ebp),%eax
80103c06:	e8 19 f8 ff ff       	call   80103424 <wakeup1>
  release(&ptable.lock);
80103c0b:	c7 04 24 40 2d 15 80 	movl   $0x80152d40,(%esp)
80103c12:	e8 5b 04 00 00       	call   80104072 <release>
}
80103c17:	83 c4 10             	add    $0x10,%esp
80103c1a:	c9                   	leave  
80103c1b:	c3                   	ret    

80103c1c <kill>:

// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int kill(int pid)
{
80103c1c:	55                   	push   %ebp
80103c1d:	89 e5                	mov    %esp,%ebp
80103c1f:	53                   	push   %ebx
80103c20:	83 ec 10             	sub    $0x10,%esp
80103c23:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103c26:	68 40 2d 15 80       	push   $0x80152d40
80103c2b:	e8 dd 03 00 00       	call   8010400d <acquire>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103c30:	83 c4 10             	add    $0x10,%esp
80103c33:	b8 74 2d 15 80       	mov    $0x80152d74,%eax
80103c38:	3d 74 4c 15 80       	cmp    $0x80154c74,%eax
80103c3d:	73 3a                	jae    80103c79 <kill+0x5d>
  {
    if (p->pid == pid)
80103c3f:	39 58 10             	cmp    %ebx,0x10(%eax)
80103c42:	74 05                	je     80103c49 <kill+0x2d>
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103c44:	83 c0 7c             	add    $0x7c,%eax
80103c47:	eb ef                	jmp    80103c38 <kill+0x1c>
    {
      p->killed = 1;
80103c49:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if (p->state == SLEEPING)
80103c50:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103c54:	74 1a                	je     80103c70 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103c56:	83 ec 0c             	sub    $0xc,%esp
80103c59:	68 40 2d 15 80       	push   $0x80152d40
80103c5e:	e8 0f 04 00 00       	call   80104072 <release>
      return 0;
80103c63:	83 c4 10             	add    $0x10,%esp
80103c66:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103c6b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103c6e:	c9                   	leave  
80103c6f:	c3                   	ret    
        p->state = RUNNABLE;
80103c70:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103c77:	eb dd                	jmp    80103c56 <kill+0x3a>
  release(&ptable.lock);
80103c79:	83 ec 0c             	sub    $0xc,%esp
80103c7c:	68 40 2d 15 80       	push   $0x80152d40
80103c81:	e8 ec 03 00 00       	call   80104072 <release>
  return -1;
80103c86:	83 c4 10             	add    $0x10,%esp
80103c89:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103c8e:	eb db                	jmp    80103c6b <kill+0x4f>

80103c90 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
80103c90:	55                   	push   %ebp
80103c91:	89 e5                	mov    %esp,%ebp
80103c93:	56                   	push   %esi
80103c94:	53                   	push   %ebx
80103c95:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103c98:	bb 74 2d 15 80       	mov    $0x80152d74,%ebx
80103c9d:	eb 33                	jmp    80103cd2 <procdump+0x42>
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103c9f:	b8 40 6f 10 80       	mov    $0x80106f40,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103ca4:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103ca7:	52                   	push   %edx
80103ca8:	50                   	push   %eax
80103ca9:	ff 73 10             	pushl  0x10(%ebx)
80103cac:	68 44 6f 10 80       	push   $0x80106f44
80103cb1:	e8 55 c9 ff ff       	call   8010060b <cprintf>
    if (p->state == SLEEPING)
80103cb6:	83 c4 10             	add    $0x10,%esp
80103cb9:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103cbd:	74 39                	je     80103cf8 <procdump+0x68>
    {
      getcallerpcs((uint *)p->context->ebp + 2, pc);
      for (i = 0; i < 10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103cbf:	83 ec 0c             	sub    $0xc,%esp
80103cc2:	68 bb 72 10 80       	push   $0x801072bb
80103cc7:	e8 3f c9 ff ff       	call   8010060b <cprintf>
80103ccc:	83 c4 10             	add    $0x10,%esp
  for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103ccf:	83 c3 7c             	add    $0x7c,%ebx
80103cd2:	81 fb 74 4c 15 80    	cmp    $0x80154c74,%ebx
80103cd8:	73 61                	jae    80103d3b <procdump+0xab>
    if (p->state == UNUSED)
80103cda:	8b 43 0c             	mov    0xc(%ebx),%eax
80103cdd:	85 c0                	test   %eax,%eax
80103cdf:	74 ee                	je     80103ccf <procdump+0x3f>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103ce1:	83 f8 05             	cmp    $0x5,%eax
80103ce4:	77 b9                	ja     80103c9f <procdump+0xf>
80103ce6:	8b 04 85 a0 6f 10 80 	mov    -0x7fef9060(,%eax,4),%eax
80103ced:	85 c0                	test   %eax,%eax
80103cef:	75 b3                	jne    80103ca4 <procdump+0x14>
      state = "???";
80103cf1:	b8 40 6f 10 80       	mov    $0x80106f40,%eax
80103cf6:	eb ac                	jmp    80103ca4 <procdump+0x14>
      getcallerpcs((uint *)p->context->ebp + 2, pc);
80103cf8:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103cfb:	8b 40 0c             	mov    0xc(%eax),%eax
80103cfe:	83 c0 08             	add    $0x8,%eax
80103d01:	83 ec 08             	sub    $0x8,%esp
80103d04:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103d07:	52                   	push   %edx
80103d08:	50                   	push   %eax
80103d09:	e8 de 01 00 00       	call   80103eec <getcallerpcs>
      for (i = 0; i < 10 && pc[i] != 0; i++)
80103d0e:	83 c4 10             	add    $0x10,%esp
80103d11:	be 00 00 00 00       	mov    $0x0,%esi
80103d16:	eb 14                	jmp    80103d2c <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103d18:	83 ec 08             	sub    $0x8,%esp
80103d1b:	50                   	push   %eax
80103d1c:	68 81 69 10 80       	push   $0x80106981
80103d21:	e8 e5 c8 ff ff       	call   8010060b <cprintf>
      for (i = 0; i < 10 && pc[i] != 0; i++)
80103d26:	83 c6 01             	add    $0x1,%esi
80103d29:	83 c4 10             	add    $0x10,%esp
80103d2c:	83 fe 09             	cmp    $0x9,%esi
80103d2f:	7f 8e                	jg     80103cbf <procdump+0x2f>
80103d31:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103d35:	85 c0                	test   %eax,%eax
80103d37:	75 df                	jne    80103d18 <procdump+0x88>
80103d39:	eb 84                	jmp    80103cbf <procdump+0x2f>
  }
}
80103d3b:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103d3e:	5b                   	pop    %ebx
80103d3f:	5e                   	pop    %esi
80103d40:	5d                   	pop    %ebp
80103d41:	c3                   	ret    

80103d42 <dump_physmem>:

int dump_physmem(int *frames, int *pids, int numframes)
{
80103d42:	55                   	push   %ebp
80103d43:	89 e5                	mov    %esp,%ebp
80103d45:	57                   	push   %edi
80103d46:	56                   	push   %esi
80103d47:	53                   	push   %ebx
80103d48:	83 ec 0c             	sub    $0xc,%esp
80103d4b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  if(numframes == 0 || frames == 0 || pids == 0) {
80103d4e:	85 db                	test   %ebx,%ebx
80103d50:	0f 94 c2             	sete   %dl
80103d53:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80103d57:	0f 94 c0             	sete   %al
80103d5a:	08 c2                	or     %al,%dl
80103d5c:	75 5a                	jne    80103db8 <dump_physmem+0x76>
80103d5e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103d62:	74 5b                	je     80103dbf <dump_physmem+0x7d>
    return -1;
  }
  int* framesList = getframesList();
80103d64:	e8 3b e2 ff ff       	call   80101fa4 <getframesList>
  int j = 0;
  for(int i = 65535; i >=0; i--) {
80103d69:	ba ff ff 00 00       	mov    $0xffff,%edx
  int j = 0;
80103d6e:	bf 00 00 00 00       	mov    $0x0,%edi
80103d73:	89 5d 10             	mov    %ebx,0x10(%ebp)
  for(int i = 65535; i >=0; i--) {
80103d76:	eb 03                	jmp    80103d7b <dump_physmem+0x39>
80103d78:	83 ea 01             	sub    $0x1,%edx
80103d7b:	85 d2                	test   %edx,%edx
80103d7d:	78 2c                	js     80103dab <dump_physmem+0x69>
    if(framesList[i] != 0 && framesList[i] != -1 && j < numframes){
80103d7f:	8d 34 90             	lea    (%eax,%edx,4),%esi
80103d82:	8b 0e                	mov    (%esi),%ecx
80103d84:	83 c1 01             	add    $0x1,%ecx
80103d87:	83 f9 01             	cmp    $0x1,%ecx
80103d8a:	76 ec                	jbe    80103d78 <dump_physmem+0x36>
80103d8c:	3b 7d 10             	cmp    0x10(%ebp),%edi
80103d8f:	7d e7                	jge    80103d78 <dump_physmem+0x36>
      frames[j] = i;
80103d91:	8d 0c bd 00 00 00 00 	lea    0x0(,%edi,4),%ecx
80103d98:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103d9b:	89 14 0b             	mov    %edx,(%ebx,%ecx,1)
      pids[j++] = framesList[i];
80103d9e:	83 c7 01             	add    $0x1,%edi
80103da1:	8b 36                	mov    (%esi),%esi
80103da3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103da6:	89 34 0b             	mov    %esi,(%ebx,%ecx,1)
80103da9:	eb cd                	jmp    80103d78 <dump_physmem+0x36>
    }
  }
  return 0;
80103dab:	b8 00 00 00 00       	mov    $0x0,%eax
80103db0:	83 c4 0c             	add    $0xc,%esp
80103db3:	5b                   	pop    %ebx
80103db4:	5e                   	pop    %esi
80103db5:	5f                   	pop    %edi
80103db6:	5d                   	pop    %ebp
80103db7:	c3                   	ret    
    return -1;
80103db8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103dbd:	eb f1                	jmp    80103db0 <dump_physmem+0x6e>
80103dbf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103dc4:	eb ea                	jmp    80103db0 <dump_physmem+0x6e>

80103dc6 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103dc6:	55                   	push   %ebp
80103dc7:	89 e5                	mov    %esp,%ebp
80103dc9:	53                   	push   %ebx
80103dca:	83 ec 0c             	sub    $0xc,%esp
80103dcd:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103dd0:	68 b8 6f 10 80       	push   $0x80106fb8
80103dd5:	8d 43 04             	lea    0x4(%ebx),%eax
80103dd8:	50                   	push   %eax
80103dd9:	e8 f3 00 00 00       	call   80103ed1 <initlock>
  lk->name = name;
80103dde:	8b 45 0c             	mov    0xc(%ebp),%eax
80103de1:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103de4:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103dea:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103df1:	83 c4 10             	add    $0x10,%esp
80103df4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103df7:	c9                   	leave  
80103df8:	c3                   	ret    

80103df9 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103df9:	55                   	push   %ebp
80103dfa:	89 e5                	mov    %esp,%ebp
80103dfc:	56                   	push   %esi
80103dfd:	53                   	push   %ebx
80103dfe:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103e01:	8d 73 04             	lea    0x4(%ebx),%esi
80103e04:	83 ec 0c             	sub    $0xc,%esp
80103e07:	56                   	push   %esi
80103e08:	e8 00 02 00 00       	call   8010400d <acquire>
  while (lk->locked) {
80103e0d:	83 c4 10             	add    $0x10,%esp
80103e10:	eb 0d                	jmp    80103e1f <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103e12:	83 ec 08             	sub    $0x8,%esp
80103e15:	56                   	push   %esi
80103e16:	53                   	push   %ebx
80103e17:	e8 72 fc ff ff       	call   80103a8e <sleep>
80103e1c:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103e1f:	83 3b 00             	cmpl   $0x0,(%ebx)
80103e22:	75 ee                	jne    80103e12 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103e24:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103e2a:	e8 bb f7 ff ff       	call   801035ea <myproc>
80103e2f:	8b 40 10             	mov    0x10(%eax),%eax
80103e32:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103e35:	83 ec 0c             	sub    $0xc,%esp
80103e38:	56                   	push   %esi
80103e39:	e8 34 02 00 00       	call   80104072 <release>
}
80103e3e:	83 c4 10             	add    $0x10,%esp
80103e41:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103e44:	5b                   	pop    %ebx
80103e45:	5e                   	pop    %esi
80103e46:	5d                   	pop    %ebp
80103e47:	c3                   	ret    

80103e48 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103e48:	55                   	push   %ebp
80103e49:	89 e5                	mov    %esp,%ebp
80103e4b:	56                   	push   %esi
80103e4c:	53                   	push   %ebx
80103e4d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103e50:	8d 73 04             	lea    0x4(%ebx),%esi
80103e53:	83 ec 0c             	sub    $0xc,%esp
80103e56:	56                   	push   %esi
80103e57:	e8 b1 01 00 00       	call   8010400d <acquire>
  lk->locked = 0;
80103e5c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103e62:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103e69:	89 1c 24             	mov    %ebx,(%esp)
80103e6c:	e8 82 fd ff ff       	call   80103bf3 <wakeup>
  release(&lk->lk);
80103e71:	89 34 24             	mov    %esi,(%esp)
80103e74:	e8 f9 01 00 00       	call   80104072 <release>
}
80103e79:	83 c4 10             	add    $0x10,%esp
80103e7c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103e7f:	5b                   	pop    %ebx
80103e80:	5e                   	pop    %esi
80103e81:	5d                   	pop    %ebp
80103e82:	c3                   	ret    

80103e83 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103e83:	55                   	push   %ebp
80103e84:	89 e5                	mov    %esp,%ebp
80103e86:	56                   	push   %esi
80103e87:	53                   	push   %ebx
80103e88:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103e8b:	8d 73 04             	lea    0x4(%ebx),%esi
80103e8e:	83 ec 0c             	sub    $0xc,%esp
80103e91:	56                   	push   %esi
80103e92:	e8 76 01 00 00       	call   8010400d <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103e97:	83 c4 10             	add    $0x10,%esp
80103e9a:	83 3b 00             	cmpl   $0x0,(%ebx)
80103e9d:	75 17                	jne    80103eb6 <holdingsleep+0x33>
80103e9f:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103ea4:	83 ec 0c             	sub    $0xc,%esp
80103ea7:	56                   	push   %esi
80103ea8:	e8 c5 01 00 00       	call   80104072 <release>
  return r;
}
80103ead:	89 d8                	mov    %ebx,%eax
80103eaf:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103eb2:	5b                   	pop    %ebx
80103eb3:	5e                   	pop    %esi
80103eb4:	5d                   	pop    %ebp
80103eb5:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103eb6:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103eb9:	e8 2c f7 ff ff       	call   801035ea <myproc>
80103ebe:	3b 58 10             	cmp    0x10(%eax),%ebx
80103ec1:	74 07                	je     80103eca <holdingsleep+0x47>
80103ec3:	bb 00 00 00 00       	mov    $0x0,%ebx
80103ec8:	eb da                	jmp    80103ea4 <holdingsleep+0x21>
80103eca:	bb 01 00 00 00       	mov    $0x1,%ebx
80103ecf:	eb d3                	jmp    80103ea4 <holdingsleep+0x21>

80103ed1 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103ed1:	55                   	push   %ebp
80103ed2:	89 e5                	mov    %esp,%ebp
80103ed4:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103ed7:	8b 55 0c             	mov    0xc(%ebp),%edx
80103eda:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103edd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103ee3:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103eea:	5d                   	pop    %ebp
80103eeb:	c3                   	ret    

80103eec <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103eec:	55                   	push   %ebp
80103eed:	89 e5                	mov    %esp,%ebp
80103eef:	53                   	push   %ebx
80103ef0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103ef3:	8b 45 08             	mov    0x8(%ebp),%eax
80103ef6:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103ef9:	b8 00 00 00 00       	mov    $0x0,%eax
80103efe:	83 f8 09             	cmp    $0x9,%eax
80103f01:	7f 25                	jg     80103f28 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103f03:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103f09:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103f0f:	77 17                	ja     80103f28 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103f11:	8b 5a 04             	mov    0x4(%edx),%ebx
80103f14:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103f17:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103f19:	83 c0 01             	add    $0x1,%eax
80103f1c:	eb e0                	jmp    80103efe <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103f1e:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103f25:	83 c0 01             	add    $0x1,%eax
80103f28:	83 f8 09             	cmp    $0x9,%eax
80103f2b:	7e f1                	jle    80103f1e <getcallerpcs+0x32>
}
80103f2d:	5b                   	pop    %ebx
80103f2e:	5d                   	pop    %ebp
80103f2f:	c3                   	ret    

80103f30 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103f30:	55                   	push   %ebp
80103f31:	89 e5                	mov    %esp,%ebp
80103f33:	53                   	push   %ebx
80103f34:	83 ec 04             	sub    $0x4,%esp
80103f37:	9c                   	pushf  
80103f38:	5b                   	pop    %ebx
  asm volatile("cli");
80103f39:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103f3a:	e8 34 f6 ff ff       	call   80103573 <mycpu>
80103f3f:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103f46:	74 12                	je     80103f5a <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103f48:	e8 26 f6 ff ff       	call   80103573 <mycpu>
80103f4d:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103f54:	83 c4 04             	add    $0x4,%esp
80103f57:	5b                   	pop    %ebx
80103f58:	5d                   	pop    %ebp
80103f59:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103f5a:	e8 14 f6 ff ff       	call   80103573 <mycpu>
80103f5f:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103f65:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103f6b:	eb db                	jmp    80103f48 <pushcli+0x18>

80103f6d <popcli>:

void
popcli(void)
{
80103f6d:	55                   	push   %ebp
80103f6e:	89 e5                	mov    %esp,%ebp
80103f70:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103f73:	9c                   	pushf  
80103f74:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103f75:	f6 c4 02             	test   $0x2,%ah
80103f78:	75 28                	jne    80103fa2 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103f7a:	e8 f4 f5 ff ff       	call   80103573 <mycpu>
80103f7f:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103f85:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103f88:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103f8e:	85 d2                	test   %edx,%edx
80103f90:	78 1d                	js     80103faf <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103f92:	e8 dc f5 ff ff       	call   80103573 <mycpu>
80103f97:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103f9e:	74 1c                	je     80103fbc <popcli+0x4f>
    sti();
}
80103fa0:	c9                   	leave  
80103fa1:	c3                   	ret    
    panic("popcli - interruptible");
80103fa2:	83 ec 0c             	sub    $0xc,%esp
80103fa5:	68 c3 6f 10 80       	push   $0x80106fc3
80103faa:	e8 99 c3 ff ff       	call   80100348 <panic>
    panic("popcli");
80103faf:	83 ec 0c             	sub    $0xc,%esp
80103fb2:	68 da 6f 10 80       	push   $0x80106fda
80103fb7:	e8 8c c3 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103fbc:	e8 b2 f5 ff ff       	call   80103573 <mycpu>
80103fc1:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103fc8:	74 d6                	je     80103fa0 <popcli+0x33>
  asm volatile("sti");
80103fca:	fb                   	sti    
}
80103fcb:	eb d3                	jmp    80103fa0 <popcli+0x33>

80103fcd <holding>:
{
80103fcd:	55                   	push   %ebp
80103fce:	89 e5                	mov    %esp,%ebp
80103fd0:	53                   	push   %ebx
80103fd1:	83 ec 04             	sub    $0x4,%esp
80103fd4:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103fd7:	e8 54 ff ff ff       	call   80103f30 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103fdc:	83 3b 00             	cmpl   $0x0,(%ebx)
80103fdf:	75 12                	jne    80103ff3 <holding+0x26>
80103fe1:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103fe6:	e8 82 ff ff ff       	call   80103f6d <popcli>
}
80103feb:	89 d8                	mov    %ebx,%eax
80103fed:	83 c4 04             	add    $0x4,%esp
80103ff0:	5b                   	pop    %ebx
80103ff1:	5d                   	pop    %ebp
80103ff2:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103ff3:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103ff6:	e8 78 f5 ff ff       	call   80103573 <mycpu>
80103ffb:	39 c3                	cmp    %eax,%ebx
80103ffd:	74 07                	je     80104006 <holding+0x39>
80103fff:	bb 00 00 00 00       	mov    $0x0,%ebx
80104004:	eb e0                	jmp    80103fe6 <holding+0x19>
80104006:	bb 01 00 00 00       	mov    $0x1,%ebx
8010400b:	eb d9                	jmp    80103fe6 <holding+0x19>

8010400d <acquire>:
{
8010400d:	55                   	push   %ebp
8010400e:	89 e5                	mov    %esp,%ebp
80104010:	53                   	push   %ebx
80104011:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104014:	e8 17 ff ff ff       	call   80103f30 <pushcli>
  if(holding(lk))
80104019:	83 ec 0c             	sub    $0xc,%esp
8010401c:	ff 75 08             	pushl  0x8(%ebp)
8010401f:	e8 a9 ff ff ff       	call   80103fcd <holding>
80104024:	83 c4 10             	add    $0x10,%esp
80104027:	85 c0                	test   %eax,%eax
80104029:	75 3a                	jne    80104065 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
8010402b:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
8010402e:	b8 01 00 00 00       	mov    $0x1,%eax
80104033:	f0 87 02             	lock xchg %eax,(%edx)
80104036:	85 c0                	test   %eax,%eax
80104038:	75 f1                	jne    8010402b <acquire+0x1e>
  __sync_synchronize();
8010403a:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
8010403f:	8b 5d 08             	mov    0x8(%ebp),%ebx
80104042:	e8 2c f5 ff ff       	call   80103573 <mycpu>
80104047:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
8010404a:	8b 45 08             	mov    0x8(%ebp),%eax
8010404d:	83 c0 0c             	add    $0xc,%eax
80104050:	83 ec 08             	sub    $0x8,%esp
80104053:	50                   	push   %eax
80104054:	8d 45 08             	lea    0x8(%ebp),%eax
80104057:	50                   	push   %eax
80104058:	e8 8f fe ff ff       	call   80103eec <getcallerpcs>
}
8010405d:	83 c4 10             	add    $0x10,%esp
80104060:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104063:	c9                   	leave  
80104064:	c3                   	ret    
    panic("acquire");
80104065:	83 ec 0c             	sub    $0xc,%esp
80104068:	68 e1 6f 10 80       	push   $0x80106fe1
8010406d:	e8 d6 c2 ff ff       	call   80100348 <panic>

80104072 <release>:
{
80104072:	55                   	push   %ebp
80104073:	89 e5                	mov    %esp,%ebp
80104075:	53                   	push   %ebx
80104076:	83 ec 10             	sub    $0x10,%esp
80104079:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
8010407c:	53                   	push   %ebx
8010407d:	e8 4b ff ff ff       	call   80103fcd <holding>
80104082:	83 c4 10             	add    $0x10,%esp
80104085:	85 c0                	test   %eax,%eax
80104087:	74 23                	je     801040ac <release+0x3a>
  lk->pcs[0] = 0;
80104089:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80104090:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80104097:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
8010409c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
801040a2:	e8 c6 fe ff ff       	call   80103f6d <popcli>
}
801040a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801040aa:	c9                   	leave  
801040ab:	c3                   	ret    
    panic("release");
801040ac:	83 ec 0c             	sub    $0xc,%esp
801040af:	68 e9 6f 10 80       	push   $0x80106fe9
801040b4:	e8 8f c2 ff ff       	call   80100348 <panic>

801040b9 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
801040b9:	55                   	push   %ebp
801040ba:	89 e5                	mov    %esp,%ebp
801040bc:	57                   	push   %edi
801040bd:	53                   	push   %ebx
801040be:	8b 55 08             	mov    0x8(%ebp),%edx
801040c1:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
801040c4:	f6 c2 03             	test   $0x3,%dl
801040c7:	75 05                	jne    801040ce <memset+0x15>
801040c9:	f6 c1 03             	test   $0x3,%cl
801040cc:	74 0e                	je     801040dc <memset+0x23>
  asm volatile("cld; rep stosb" :
801040ce:	89 d7                	mov    %edx,%edi
801040d0:	8b 45 0c             	mov    0xc(%ebp),%eax
801040d3:	fc                   	cld    
801040d4:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
801040d6:	89 d0                	mov    %edx,%eax
801040d8:	5b                   	pop    %ebx
801040d9:	5f                   	pop    %edi
801040da:	5d                   	pop    %ebp
801040db:	c3                   	ret    
    c &= 0xFF;
801040dc:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801040e0:	c1 e9 02             	shr    $0x2,%ecx
801040e3:	89 f8                	mov    %edi,%eax
801040e5:	c1 e0 18             	shl    $0x18,%eax
801040e8:	89 fb                	mov    %edi,%ebx
801040ea:	c1 e3 10             	shl    $0x10,%ebx
801040ed:	09 d8                	or     %ebx,%eax
801040ef:	89 fb                	mov    %edi,%ebx
801040f1:	c1 e3 08             	shl    $0x8,%ebx
801040f4:	09 d8                	or     %ebx,%eax
801040f6:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
801040f8:	89 d7                	mov    %edx,%edi
801040fa:	fc                   	cld    
801040fb:	f3 ab                	rep stos %eax,%es:(%edi)
801040fd:	eb d7                	jmp    801040d6 <memset+0x1d>

801040ff <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801040ff:	55                   	push   %ebp
80104100:	89 e5                	mov    %esp,%ebp
80104102:	56                   	push   %esi
80104103:	53                   	push   %ebx
80104104:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104107:	8b 55 0c             	mov    0xc(%ebp),%edx
8010410a:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
8010410d:	8d 70 ff             	lea    -0x1(%eax),%esi
80104110:	85 c0                	test   %eax,%eax
80104112:	74 1c                	je     80104130 <memcmp+0x31>
    if(*s1 != *s2)
80104114:	0f b6 01             	movzbl (%ecx),%eax
80104117:	0f b6 1a             	movzbl (%edx),%ebx
8010411a:	38 d8                	cmp    %bl,%al
8010411c:	75 0a                	jne    80104128 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
8010411e:	83 c1 01             	add    $0x1,%ecx
80104121:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80104124:	89 f0                	mov    %esi,%eax
80104126:	eb e5                	jmp    8010410d <memcmp+0xe>
      return *s1 - *s2;
80104128:	0f b6 c0             	movzbl %al,%eax
8010412b:	0f b6 db             	movzbl %bl,%ebx
8010412e:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80104130:	5b                   	pop    %ebx
80104131:	5e                   	pop    %esi
80104132:	5d                   	pop    %ebp
80104133:	c3                   	ret    

80104134 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80104134:	55                   	push   %ebp
80104135:	89 e5                	mov    %esp,%ebp
80104137:	56                   	push   %esi
80104138:	53                   	push   %ebx
80104139:	8b 45 08             	mov    0x8(%ebp),%eax
8010413c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010413f:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80104142:	39 c1                	cmp    %eax,%ecx
80104144:	73 3a                	jae    80104180 <memmove+0x4c>
80104146:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80104149:	39 c3                	cmp    %eax,%ebx
8010414b:	76 37                	jbe    80104184 <memmove+0x50>
    s += n;
    d += n;
8010414d:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80104150:	eb 0d                	jmp    8010415f <memmove+0x2b>
      *--d = *--s;
80104152:	83 eb 01             	sub    $0x1,%ebx
80104155:	83 e9 01             	sub    $0x1,%ecx
80104158:	0f b6 13             	movzbl (%ebx),%edx
8010415b:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
8010415d:	89 f2                	mov    %esi,%edx
8010415f:	8d 72 ff             	lea    -0x1(%edx),%esi
80104162:	85 d2                	test   %edx,%edx
80104164:	75 ec                	jne    80104152 <memmove+0x1e>
80104166:	eb 14                	jmp    8010417c <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80104168:	0f b6 11             	movzbl (%ecx),%edx
8010416b:	88 13                	mov    %dl,(%ebx)
8010416d:	8d 5b 01             	lea    0x1(%ebx),%ebx
80104170:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80104173:	89 f2                	mov    %esi,%edx
80104175:	8d 72 ff             	lea    -0x1(%edx),%esi
80104178:	85 d2                	test   %edx,%edx
8010417a:	75 ec                	jne    80104168 <memmove+0x34>

  return dst;
}
8010417c:	5b                   	pop    %ebx
8010417d:	5e                   	pop    %esi
8010417e:	5d                   	pop    %ebp
8010417f:	c3                   	ret    
80104180:	89 c3                	mov    %eax,%ebx
80104182:	eb f1                	jmp    80104175 <memmove+0x41>
80104184:	89 c3                	mov    %eax,%ebx
80104186:	eb ed                	jmp    80104175 <memmove+0x41>

80104188 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80104188:	55                   	push   %ebp
80104189:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
8010418b:	ff 75 10             	pushl  0x10(%ebp)
8010418e:	ff 75 0c             	pushl  0xc(%ebp)
80104191:	ff 75 08             	pushl  0x8(%ebp)
80104194:	e8 9b ff ff ff       	call   80104134 <memmove>
}
80104199:	c9                   	leave  
8010419a:	c3                   	ret    

8010419b <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
8010419b:	55                   	push   %ebp
8010419c:	89 e5                	mov    %esp,%ebp
8010419e:	53                   	push   %ebx
8010419f:	8b 55 08             	mov    0x8(%ebp),%edx
801041a2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801041a5:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
801041a8:	eb 09                	jmp    801041b3 <strncmp+0x18>
    n--, p++, q++;
801041aa:	83 e8 01             	sub    $0x1,%eax
801041ad:	83 c2 01             	add    $0x1,%edx
801041b0:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
801041b3:	85 c0                	test   %eax,%eax
801041b5:	74 0b                	je     801041c2 <strncmp+0x27>
801041b7:	0f b6 1a             	movzbl (%edx),%ebx
801041ba:	84 db                	test   %bl,%bl
801041bc:	74 04                	je     801041c2 <strncmp+0x27>
801041be:	3a 19                	cmp    (%ecx),%bl
801041c0:	74 e8                	je     801041aa <strncmp+0xf>
  if(n == 0)
801041c2:	85 c0                	test   %eax,%eax
801041c4:	74 0b                	je     801041d1 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
801041c6:	0f b6 02             	movzbl (%edx),%eax
801041c9:	0f b6 11             	movzbl (%ecx),%edx
801041cc:	29 d0                	sub    %edx,%eax
}
801041ce:	5b                   	pop    %ebx
801041cf:	5d                   	pop    %ebp
801041d0:	c3                   	ret    
    return 0;
801041d1:	b8 00 00 00 00       	mov    $0x0,%eax
801041d6:	eb f6                	jmp    801041ce <strncmp+0x33>

801041d8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
801041d8:	55                   	push   %ebp
801041d9:	89 e5                	mov    %esp,%ebp
801041db:	57                   	push   %edi
801041dc:	56                   	push   %esi
801041dd:	53                   	push   %ebx
801041de:	8b 5d 0c             	mov    0xc(%ebp),%ebx
801041e1:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
801041e4:	8b 45 08             	mov    0x8(%ebp),%eax
801041e7:	eb 04                	jmp    801041ed <strncpy+0x15>
801041e9:	89 fb                	mov    %edi,%ebx
801041eb:	89 f0                	mov    %esi,%eax
801041ed:	8d 51 ff             	lea    -0x1(%ecx),%edx
801041f0:	85 c9                	test   %ecx,%ecx
801041f2:	7e 1d                	jle    80104211 <strncpy+0x39>
801041f4:	8d 7b 01             	lea    0x1(%ebx),%edi
801041f7:	8d 70 01             	lea    0x1(%eax),%esi
801041fa:	0f b6 1b             	movzbl (%ebx),%ebx
801041fd:	88 18                	mov    %bl,(%eax)
801041ff:	89 d1                	mov    %edx,%ecx
80104201:	84 db                	test   %bl,%bl
80104203:	75 e4                	jne    801041e9 <strncpy+0x11>
80104205:	89 f0                	mov    %esi,%eax
80104207:	eb 08                	jmp    80104211 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80104209:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
8010420c:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
8010420e:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80104211:	8d 4a ff             	lea    -0x1(%edx),%ecx
80104214:	85 d2                	test   %edx,%edx
80104216:	7f f1                	jg     80104209 <strncpy+0x31>
  return os;
}
80104218:	8b 45 08             	mov    0x8(%ebp),%eax
8010421b:	5b                   	pop    %ebx
8010421c:	5e                   	pop    %esi
8010421d:	5f                   	pop    %edi
8010421e:	5d                   	pop    %ebp
8010421f:	c3                   	ret    

80104220 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80104220:	55                   	push   %ebp
80104221:	89 e5                	mov    %esp,%ebp
80104223:	57                   	push   %edi
80104224:	56                   	push   %esi
80104225:	53                   	push   %ebx
80104226:	8b 45 08             	mov    0x8(%ebp),%eax
80104229:	8b 5d 0c             	mov    0xc(%ebp),%ebx
8010422c:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
8010422f:	85 d2                	test   %edx,%edx
80104231:	7e 23                	jle    80104256 <safestrcpy+0x36>
80104233:	89 c1                	mov    %eax,%ecx
80104235:	eb 04                	jmp    8010423b <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80104237:	89 fb                	mov    %edi,%ebx
80104239:	89 f1                	mov    %esi,%ecx
8010423b:	83 ea 01             	sub    $0x1,%edx
8010423e:	85 d2                	test   %edx,%edx
80104240:	7e 11                	jle    80104253 <safestrcpy+0x33>
80104242:	8d 7b 01             	lea    0x1(%ebx),%edi
80104245:	8d 71 01             	lea    0x1(%ecx),%esi
80104248:	0f b6 1b             	movzbl (%ebx),%ebx
8010424b:	88 19                	mov    %bl,(%ecx)
8010424d:	84 db                	test   %bl,%bl
8010424f:	75 e6                	jne    80104237 <safestrcpy+0x17>
80104251:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80104253:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80104256:	5b                   	pop    %ebx
80104257:	5e                   	pop    %esi
80104258:	5f                   	pop    %edi
80104259:	5d                   	pop    %ebp
8010425a:	c3                   	ret    

8010425b <strlen>:

int
strlen(const char *s)
{
8010425b:	55                   	push   %ebp
8010425c:	89 e5                	mov    %esp,%ebp
8010425e:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80104261:	b8 00 00 00 00       	mov    $0x0,%eax
80104266:	eb 03                	jmp    8010426b <strlen+0x10>
80104268:	83 c0 01             	add    $0x1,%eax
8010426b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
8010426f:	75 f7                	jne    80104268 <strlen+0xd>
    ;
  return n;
}
80104271:	5d                   	pop    %ebp
80104272:	c3                   	ret    

80104273 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80104273:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80104277:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
8010427b:	55                   	push   %ebp
  pushl %ebx
8010427c:	53                   	push   %ebx
  pushl %esi
8010427d:	56                   	push   %esi
  pushl %edi
8010427e:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010427f:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80104281:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80104283:	5f                   	pop    %edi
  popl %esi
80104284:	5e                   	pop    %esi
  popl %ebx
80104285:	5b                   	pop    %ebx
  popl %ebp
80104286:	5d                   	pop    %ebp
  ret
80104287:	c3                   	ret    

80104288 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80104288:	55                   	push   %ebp
80104289:	89 e5                	mov    %esp,%ebp
8010428b:	53                   	push   %ebx
8010428c:	83 ec 04             	sub    $0x4,%esp
8010428f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80104292:	e8 53 f3 ff ff       	call   801035ea <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80104297:	8b 00                	mov    (%eax),%eax
80104299:	39 d8                	cmp    %ebx,%eax
8010429b:	76 19                	jbe    801042b6 <fetchint+0x2e>
8010429d:	8d 53 04             	lea    0x4(%ebx),%edx
801042a0:	39 d0                	cmp    %edx,%eax
801042a2:	72 19                	jb     801042bd <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
801042a4:	8b 13                	mov    (%ebx),%edx
801042a6:	8b 45 0c             	mov    0xc(%ebp),%eax
801042a9:	89 10                	mov    %edx,(%eax)
  return 0;
801042ab:	b8 00 00 00 00       	mov    $0x0,%eax
}
801042b0:	83 c4 04             	add    $0x4,%esp
801042b3:	5b                   	pop    %ebx
801042b4:	5d                   	pop    %ebp
801042b5:	c3                   	ret    
    return -1;
801042b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042bb:	eb f3                	jmp    801042b0 <fetchint+0x28>
801042bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042c2:	eb ec                	jmp    801042b0 <fetchint+0x28>

801042c4 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
801042c4:	55                   	push   %ebp
801042c5:	89 e5                	mov    %esp,%ebp
801042c7:	53                   	push   %ebx
801042c8:	83 ec 04             	sub    $0x4,%esp
801042cb:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
801042ce:	e8 17 f3 ff ff       	call   801035ea <myproc>

  if(addr >= curproc->sz)
801042d3:	39 18                	cmp    %ebx,(%eax)
801042d5:	76 26                	jbe    801042fd <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
801042d7:	8b 55 0c             	mov    0xc(%ebp),%edx
801042da:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
801042dc:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
801042de:	89 d8                	mov    %ebx,%eax
801042e0:	39 d0                	cmp    %edx,%eax
801042e2:	73 0e                	jae    801042f2 <fetchstr+0x2e>
    if(*s == 0)
801042e4:	80 38 00             	cmpb   $0x0,(%eax)
801042e7:	74 05                	je     801042ee <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
801042e9:	83 c0 01             	add    $0x1,%eax
801042ec:	eb f2                	jmp    801042e0 <fetchstr+0x1c>
      return s - *pp;
801042ee:	29 d8                	sub    %ebx,%eax
801042f0:	eb 05                	jmp    801042f7 <fetchstr+0x33>
  }
  return -1;
801042f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801042f7:	83 c4 04             	add    $0x4,%esp
801042fa:	5b                   	pop    %ebx
801042fb:	5d                   	pop    %ebp
801042fc:	c3                   	ret    
    return -1;
801042fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104302:	eb f3                	jmp    801042f7 <fetchstr+0x33>

80104304 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80104304:	55                   	push   %ebp
80104305:	89 e5                	mov    %esp,%ebp
80104307:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
8010430a:	e8 db f2 ff ff       	call   801035ea <myproc>
8010430f:	8b 50 18             	mov    0x18(%eax),%edx
80104312:	8b 45 08             	mov    0x8(%ebp),%eax
80104315:	c1 e0 02             	shl    $0x2,%eax
80104318:	03 42 44             	add    0x44(%edx),%eax
8010431b:	83 ec 08             	sub    $0x8,%esp
8010431e:	ff 75 0c             	pushl  0xc(%ebp)
80104321:	83 c0 04             	add    $0x4,%eax
80104324:	50                   	push   %eax
80104325:	e8 5e ff ff ff       	call   80104288 <fetchint>
}
8010432a:	c9                   	leave  
8010432b:	c3                   	ret    

8010432c <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
8010432c:	55                   	push   %ebp
8010432d:	89 e5                	mov    %esp,%ebp
8010432f:	56                   	push   %esi
80104330:	53                   	push   %ebx
80104331:	83 ec 10             	sub    $0x10,%esp
80104334:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80104337:	e8 ae f2 ff ff       	call   801035ea <myproc>
8010433c:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
8010433e:	83 ec 08             	sub    $0x8,%esp
80104341:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104344:	50                   	push   %eax
80104345:	ff 75 08             	pushl  0x8(%ebp)
80104348:	e8 b7 ff ff ff       	call   80104304 <argint>
8010434d:	83 c4 10             	add    $0x10,%esp
80104350:	85 c0                	test   %eax,%eax
80104352:	78 24                	js     80104378 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80104354:	85 db                	test   %ebx,%ebx
80104356:	78 27                	js     8010437f <argptr+0x53>
80104358:	8b 16                	mov    (%esi),%edx
8010435a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010435d:	39 c2                	cmp    %eax,%edx
8010435f:	76 25                	jbe    80104386 <argptr+0x5a>
80104361:	01 c3                	add    %eax,%ebx
80104363:	39 da                	cmp    %ebx,%edx
80104365:	72 26                	jb     8010438d <argptr+0x61>
    return -1;
  *pp = (char*)i;
80104367:	8b 55 0c             	mov    0xc(%ebp),%edx
8010436a:	89 02                	mov    %eax,(%edx)
  return 0;
8010436c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104371:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104374:	5b                   	pop    %ebx
80104375:	5e                   	pop    %esi
80104376:	5d                   	pop    %ebp
80104377:	c3                   	ret    
    return -1;
80104378:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010437d:	eb f2                	jmp    80104371 <argptr+0x45>
    return -1;
8010437f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104384:	eb eb                	jmp    80104371 <argptr+0x45>
80104386:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010438b:	eb e4                	jmp    80104371 <argptr+0x45>
8010438d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104392:	eb dd                	jmp    80104371 <argptr+0x45>

80104394 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104394:	55                   	push   %ebp
80104395:	89 e5                	mov    %esp,%ebp
80104397:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010439a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010439d:	50                   	push   %eax
8010439e:	ff 75 08             	pushl  0x8(%ebp)
801043a1:	e8 5e ff ff ff       	call   80104304 <argint>
801043a6:	83 c4 10             	add    $0x10,%esp
801043a9:	85 c0                	test   %eax,%eax
801043ab:	78 13                	js     801043c0 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
801043ad:	83 ec 08             	sub    $0x8,%esp
801043b0:	ff 75 0c             	pushl  0xc(%ebp)
801043b3:	ff 75 f4             	pushl  -0xc(%ebp)
801043b6:	e8 09 ff ff ff       	call   801042c4 <fetchstr>
801043bb:	83 c4 10             	add    $0x10,%esp
}
801043be:	c9                   	leave  
801043bf:	c3                   	ret    
    return -1;
801043c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043c5:	eb f7                	jmp    801043be <argstr+0x2a>

801043c7 <syscall>:
[SYS_dump_physmem]  sys_dump_physmem,
};

void
syscall(void)
{
801043c7:	55                   	push   %ebp
801043c8:	89 e5                	mov    %esp,%ebp
801043ca:	53                   	push   %ebx
801043cb:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
801043ce:	e8 17 f2 ff ff       	call   801035ea <myproc>
801043d3:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
801043d5:	8b 40 18             	mov    0x18(%eax),%eax
801043d8:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801043db:	8d 50 ff             	lea    -0x1(%eax),%edx
801043de:	83 fa 15             	cmp    $0x15,%edx
801043e1:	77 18                	ja     801043fb <syscall+0x34>
801043e3:	8b 14 85 20 70 10 80 	mov    -0x7fef8fe0(,%eax,4),%edx
801043ea:	85 d2                	test   %edx,%edx
801043ec:	74 0d                	je     801043fb <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
801043ee:	ff d2                	call   *%edx
801043f0:	8b 53 18             	mov    0x18(%ebx),%edx
801043f3:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
801043f6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801043f9:	c9                   	leave  
801043fa:	c3                   	ret    
            curproc->pid, curproc->name, num);
801043fb:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801043fe:	50                   	push   %eax
801043ff:	52                   	push   %edx
80104400:	ff 73 10             	pushl  0x10(%ebx)
80104403:	68 f1 6f 10 80       	push   $0x80106ff1
80104408:	e8 fe c1 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
8010440d:	8b 43 18             	mov    0x18(%ebx),%eax
80104410:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
80104417:	83 c4 10             	add    $0x10,%esp
8010441a:	eb da                	jmp    801043f6 <syscall+0x2f>

8010441c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010441c:	55                   	push   %ebp
8010441d:	89 e5                	mov    %esp,%ebp
8010441f:	56                   	push   %esi
80104420:	53                   	push   %ebx
80104421:	83 ec 18             	sub    $0x18,%esp
80104424:	89 d6                	mov    %edx,%esi
80104426:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80104428:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010442b:	52                   	push   %edx
8010442c:	50                   	push   %eax
8010442d:	e8 d2 fe ff ff       	call   80104304 <argint>
80104432:	83 c4 10             	add    $0x10,%esp
80104435:	85 c0                	test   %eax,%eax
80104437:	78 2e                	js     80104467 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
80104439:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
8010443d:	77 2f                	ja     8010446e <argfd+0x52>
8010443f:	e8 a6 f1 ff ff       	call   801035ea <myproc>
80104444:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104447:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
8010444b:	85 c0                	test   %eax,%eax
8010444d:	74 26                	je     80104475 <argfd+0x59>
    return -1;
  if(pfd)
8010444f:	85 f6                	test   %esi,%esi
80104451:	74 02                	je     80104455 <argfd+0x39>
    *pfd = fd;
80104453:	89 16                	mov    %edx,(%esi)
  if(pf)
80104455:	85 db                	test   %ebx,%ebx
80104457:	74 23                	je     8010447c <argfd+0x60>
    *pf = f;
80104459:	89 03                	mov    %eax,(%ebx)
  return 0;
8010445b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104460:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104463:	5b                   	pop    %ebx
80104464:	5e                   	pop    %esi
80104465:	5d                   	pop    %ebp
80104466:	c3                   	ret    
    return -1;
80104467:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010446c:	eb f2                	jmp    80104460 <argfd+0x44>
    return -1;
8010446e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104473:	eb eb                	jmp    80104460 <argfd+0x44>
80104475:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010447a:	eb e4                	jmp    80104460 <argfd+0x44>
  return 0;
8010447c:	b8 00 00 00 00       	mov    $0x0,%eax
80104481:	eb dd                	jmp    80104460 <argfd+0x44>

80104483 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104483:	55                   	push   %ebp
80104484:	89 e5                	mov    %esp,%ebp
80104486:	53                   	push   %ebx
80104487:	83 ec 04             	sub    $0x4,%esp
8010448a:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
8010448c:	e8 59 f1 ff ff       	call   801035ea <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104491:	ba 00 00 00 00       	mov    $0x0,%edx
80104496:	83 fa 0f             	cmp    $0xf,%edx
80104499:	7f 18                	jg     801044b3 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
8010449b:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
801044a0:	74 05                	je     801044a7 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
801044a2:	83 c2 01             	add    $0x1,%edx
801044a5:	eb ef                	jmp    80104496 <fdalloc+0x13>
      curproc->ofile[fd] = f;
801044a7:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
801044ab:	89 d0                	mov    %edx,%eax
801044ad:	83 c4 04             	add    $0x4,%esp
801044b0:	5b                   	pop    %ebx
801044b1:	5d                   	pop    %ebp
801044b2:	c3                   	ret    
  return -1;
801044b3:	ba ff ff ff ff       	mov    $0xffffffff,%edx
801044b8:	eb f1                	jmp    801044ab <fdalloc+0x28>

801044ba <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801044ba:	55                   	push   %ebp
801044bb:	89 e5                	mov    %esp,%ebp
801044bd:	56                   	push   %esi
801044be:	53                   	push   %ebx
801044bf:	83 ec 10             	sub    $0x10,%esp
801044c2:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801044c4:	b8 20 00 00 00       	mov    $0x20,%eax
801044c9:	89 c6                	mov    %eax,%esi
801044cb:	39 43 58             	cmp    %eax,0x58(%ebx)
801044ce:	76 2e                	jbe    801044fe <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801044d0:	6a 10                	push   $0x10
801044d2:	50                   	push   %eax
801044d3:	8d 45 e8             	lea    -0x18(%ebp),%eax
801044d6:	50                   	push   %eax
801044d7:	53                   	push   %ebx
801044d8:	e8 96 d2 ff ff       	call   80101773 <readi>
801044dd:	83 c4 10             	add    $0x10,%esp
801044e0:	83 f8 10             	cmp    $0x10,%eax
801044e3:	75 0c                	jne    801044f1 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
801044e5:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
801044ea:	75 1e                	jne    8010450a <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801044ec:	8d 46 10             	lea    0x10(%esi),%eax
801044ef:	eb d8                	jmp    801044c9 <isdirempty+0xf>
      panic("isdirempty: readi");
801044f1:	83 ec 0c             	sub    $0xc,%esp
801044f4:	68 7c 70 10 80       	push   $0x8010707c
801044f9:	e8 4a be ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
801044fe:	b8 01 00 00 00       	mov    $0x1,%eax
}
80104503:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104506:	5b                   	pop    %ebx
80104507:	5e                   	pop    %esi
80104508:	5d                   	pop    %ebp
80104509:	c3                   	ret    
      return 0;
8010450a:	b8 00 00 00 00       	mov    $0x0,%eax
8010450f:	eb f2                	jmp    80104503 <isdirempty+0x49>

80104511 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104511:	55                   	push   %ebp
80104512:	89 e5                	mov    %esp,%ebp
80104514:	57                   	push   %edi
80104515:	56                   	push   %esi
80104516:	53                   	push   %ebx
80104517:	83 ec 44             	sub    $0x44,%esp
8010451a:	89 55 c4             	mov    %edx,-0x3c(%ebp)
8010451d:	89 4d c0             	mov    %ecx,-0x40(%ebp)
80104520:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104523:	8d 55 d6             	lea    -0x2a(%ebp),%edx
80104526:	52                   	push   %edx
80104527:	50                   	push   %eax
80104528:	e8 cc d6 ff ff       	call   80101bf9 <nameiparent>
8010452d:	89 c6                	mov    %eax,%esi
8010452f:	83 c4 10             	add    $0x10,%esp
80104532:	85 c0                	test   %eax,%eax
80104534:	0f 84 3a 01 00 00    	je     80104674 <create+0x163>
    return 0;
  ilock(dp);
8010453a:	83 ec 0c             	sub    $0xc,%esp
8010453d:	50                   	push   %eax
8010453e:	e8 3e d0 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104543:	83 c4 0c             	add    $0xc,%esp
80104546:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104549:	50                   	push   %eax
8010454a:	8d 45 d6             	lea    -0x2a(%ebp),%eax
8010454d:	50                   	push   %eax
8010454e:	56                   	push   %esi
8010454f:	e8 5c d4 ff ff       	call   801019b0 <dirlookup>
80104554:	89 c3                	mov    %eax,%ebx
80104556:	83 c4 10             	add    $0x10,%esp
80104559:	85 c0                	test   %eax,%eax
8010455b:	74 3f                	je     8010459c <create+0x8b>
    iunlockput(dp);
8010455d:	83 ec 0c             	sub    $0xc,%esp
80104560:	56                   	push   %esi
80104561:	e8 c2 d1 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
80104566:	89 1c 24             	mov    %ebx,(%esp)
80104569:	e8 13 d0 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010456e:	83 c4 10             	add    $0x10,%esp
80104571:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
80104576:	75 11                	jne    80104589 <create+0x78>
80104578:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
8010457d:	75 0a                	jne    80104589 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
8010457f:	89 d8                	mov    %ebx,%eax
80104581:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104584:	5b                   	pop    %ebx
80104585:	5e                   	pop    %esi
80104586:	5f                   	pop    %edi
80104587:	5d                   	pop    %ebp
80104588:	c3                   	ret    
    iunlockput(ip);
80104589:	83 ec 0c             	sub    $0xc,%esp
8010458c:	53                   	push   %ebx
8010458d:	e8 96 d1 ff ff       	call   80101728 <iunlockput>
    return 0;
80104592:	83 c4 10             	add    $0x10,%esp
80104595:	bb 00 00 00 00       	mov    $0x0,%ebx
8010459a:	eb e3                	jmp    8010457f <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
8010459c:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
801045a0:	83 ec 08             	sub    $0x8,%esp
801045a3:	50                   	push   %eax
801045a4:	ff 36                	pushl  (%esi)
801045a6:	e8 d3 cd ff ff       	call   8010137e <ialloc>
801045ab:	89 c3                	mov    %eax,%ebx
801045ad:	83 c4 10             	add    $0x10,%esp
801045b0:	85 c0                	test   %eax,%eax
801045b2:	74 55                	je     80104609 <create+0xf8>
  ilock(ip);
801045b4:	83 ec 0c             	sub    $0xc,%esp
801045b7:	50                   	push   %eax
801045b8:	e8 c4 cf ff ff       	call   80101581 <ilock>
  ip->major = major;
801045bd:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
801045c1:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
801045c5:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
801045c9:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
801045cf:	89 1c 24             	mov    %ebx,(%esp)
801045d2:	e8 49 ce ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
801045d7:	83 c4 10             	add    $0x10,%esp
801045da:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
801045df:	74 35                	je     80104616 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
801045e1:	83 ec 04             	sub    $0x4,%esp
801045e4:	ff 73 04             	pushl  0x4(%ebx)
801045e7:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801045ea:	50                   	push   %eax
801045eb:	56                   	push   %esi
801045ec:	e8 3f d5 ff ff       	call   80101b30 <dirlink>
801045f1:	83 c4 10             	add    $0x10,%esp
801045f4:	85 c0                	test   %eax,%eax
801045f6:	78 6f                	js     80104667 <create+0x156>
  iunlockput(dp);
801045f8:	83 ec 0c             	sub    $0xc,%esp
801045fb:	56                   	push   %esi
801045fc:	e8 27 d1 ff ff       	call   80101728 <iunlockput>
  return ip;
80104601:	83 c4 10             	add    $0x10,%esp
80104604:	e9 76 ff ff ff       	jmp    8010457f <create+0x6e>
    panic("create: ialloc");
80104609:	83 ec 0c             	sub    $0xc,%esp
8010460c:	68 8e 70 10 80       	push   $0x8010708e
80104611:	e8 32 bd ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
80104616:	0f b7 46 56          	movzwl 0x56(%esi),%eax
8010461a:	83 c0 01             	add    $0x1,%eax
8010461d:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104621:	83 ec 0c             	sub    $0xc,%esp
80104624:	56                   	push   %esi
80104625:	e8 f6 cd ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010462a:	83 c4 0c             	add    $0xc,%esp
8010462d:	ff 73 04             	pushl  0x4(%ebx)
80104630:	68 9e 70 10 80       	push   $0x8010709e
80104635:	53                   	push   %ebx
80104636:	e8 f5 d4 ff ff       	call   80101b30 <dirlink>
8010463b:	83 c4 10             	add    $0x10,%esp
8010463e:	85 c0                	test   %eax,%eax
80104640:	78 18                	js     8010465a <create+0x149>
80104642:	83 ec 04             	sub    $0x4,%esp
80104645:	ff 76 04             	pushl  0x4(%esi)
80104648:	68 9d 70 10 80       	push   $0x8010709d
8010464d:	53                   	push   %ebx
8010464e:	e8 dd d4 ff ff       	call   80101b30 <dirlink>
80104653:	83 c4 10             	add    $0x10,%esp
80104656:	85 c0                	test   %eax,%eax
80104658:	79 87                	jns    801045e1 <create+0xd0>
      panic("create dots");
8010465a:	83 ec 0c             	sub    $0xc,%esp
8010465d:	68 a0 70 10 80       	push   $0x801070a0
80104662:	e8 e1 bc ff ff       	call   80100348 <panic>
    panic("create: dirlink");
80104667:	83 ec 0c             	sub    $0xc,%esp
8010466a:	68 ac 70 10 80       	push   $0x801070ac
8010466f:	e8 d4 bc ff ff       	call   80100348 <panic>
    return 0;
80104674:	89 c3                	mov    %eax,%ebx
80104676:	e9 04 ff ff ff       	jmp    8010457f <create+0x6e>

8010467b <sys_dup>:
{
8010467b:	55                   	push   %ebp
8010467c:	89 e5                	mov    %esp,%ebp
8010467e:	53                   	push   %ebx
8010467f:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104682:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104685:	ba 00 00 00 00       	mov    $0x0,%edx
8010468a:	b8 00 00 00 00       	mov    $0x0,%eax
8010468f:	e8 88 fd ff ff       	call   8010441c <argfd>
80104694:	85 c0                	test   %eax,%eax
80104696:	78 23                	js     801046bb <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
80104698:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010469b:	e8 e3 fd ff ff       	call   80104483 <fdalloc>
801046a0:	89 c3                	mov    %eax,%ebx
801046a2:	85 c0                	test   %eax,%eax
801046a4:	78 1c                	js     801046c2 <sys_dup+0x47>
  filedup(f);
801046a6:	83 ec 0c             	sub    $0xc,%esp
801046a9:	ff 75 f4             	pushl  -0xc(%ebp)
801046ac:	e8 dd c5 ff ff       	call   80100c8e <filedup>
  return fd;
801046b1:	83 c4 10             	add    $0x10,%esp
}
801046b4:	89 d8                	mov    %ebx,%eax
801046b6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801046b9:	c9                   	leave  
801046ba:	c3                   	ret    
    return -1;
801046bb:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801046c0:	eb f2                	jmp    801046b4 <sys_dup+0x39>
    return -1;
801046c2:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801046c7:	eb eb                	jmp    801046b4 <sys_dup+0x39>

801046c9 <sys_read>:
{
801046c9:	55                   	push   %ebp
801046ca:	89 e5                	mov    %esp,%ebp
801046cc:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801046cf:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801046d2:	ba 00 00 00 00       	mov    $0x0,%edx
801046d7:	b8 00 00 00 00       	mov    $0x0,%eax
801046dc:	e8 3b fd ff ff       	call   8010441c <argfd>
801046e1:	85 c0                	test   %eax,%eax
801046e3:	78 43                	js     80104728 <sys_read+0x5f>
801046e5:	83 ec 08             	sub    $0x8,%esp
801046e8:	8d 45 f0             	lea    -0x10(%ebp),%eax
801046eb:	50                   	push   %eax
801046ec:	6a 02                	push   $0x2
801046ee:	e8 11 fc ff ff       	call   80104304 <argint>
801046f3:	83 c4 10             	add    $0x10,%esp
801046f6:	85 c0                	test   %eax,%eax
801046f8:	78 35                	js     8010472f <sys_read+0x66>
801046fa:	83 ec 04             	sub    $0x4,%esp
801046fd:	ff 75 f0             	pushl  -0x10(%ebp)
80104700:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104703:	50                   	push   %eax
80104704:	6a 01                	push   $0x1
80104706:	e8 21 fc ff ff       	call   8010432c <argptr>
8010470b:	83 c4 10             	add    $0x10,%esp
8010470e:	85 c0                	test   %eax,%eax
80104710:	78 24                	js     80104736 <sys_read+0x6d>
  return fileread(f, p, n);
80104712:	83 ec 04             	sub    $0x4,%esp
80104715:	ff 75 f0             	pushl  -0x10(%ebp)
80104718:	ff 75 ec             	pushl  -0x14(%ebp)
8010471b:	ff 75 f4             	pushl  -0xc(%ebp)
8010471e:	e8 b4 c6 ff ff       	call   80100dd7 <fileread>
80104723:	83 c4 10             	add    $0x10,%esp
}
80104726:	c9                   	leave  
80104727:	c3                   	ret    
    return -1;
80104728:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010472d:	eb f7                	jmp    80104726 <sys_read+0x5d>
8010472f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104734:	eb f0                	jmp    80104726 <sys_read+0x5d>
80104736:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010473b:	eb e9                	jmp    80104726 <sys_read+0x5d>

8010473d <sys_write>:
{
8010473d:	55                   	push   %ebp
8010473e:	89 e5                	mov    %esp,%ebp
80104740:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104743:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104746:	ba 00 00 00 00       	mov    $0x0,%edx
8010474b:	b8 00 00 00 00       	mov    $0x0,%eax
80104750:	e8 c7 fc ff ff       	call   8010441c <argfd>
80104755:	85 c0                	test   %eax,%eax
80104757:	78 43                	js     8010479c <sys_write+0x5f>
80104759:	83 ec 08             	sub    $0x8,%esp
8010475c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010475f:	50                   	push   %eax
80104760:	6a 02                	push   $0x2
80104762:	e8 9d fb ff ff       	call   80104304 <argint>
80104767:	83 c4 10             	add    $0x10,%esp
8010476a:	85 c0                	test   %eax,%eax
8010476c:	78 35                	js     801047a3 <sys_write+0x66>
8010476e:	83 ec 04             	sub    $0x4,%esp
80104771:	ff 75 f0             	pushl  -0x10(%ebp)
80104774:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104777:	50                   	push   %eax
80104778:	6a 01                	push   $0x1
8010477a:	e8 ad fb ff ff       	call   8010432c <argptr>
8010477f:	83 c4 10             	add    $0x10,%esp
80104782:	85 c0                	test   %eax,%eax
80104784:	78 24                	js     801047aa <sys_write+0x6d>
  return filewrite(f, p, n);
80104786:	83 ec 04             	sub    $0x4,%esp
80104789:	ff 75 f0             	pushl  -0x10(%ebp)
8010478c:	ff 75 ec             	pushl  -0x14(%ebp)
8010478f:	ff 75 f4             	pushl  -0xc(%ebp)
80104792:	e8 c5 c6 ff ff       	call   80100e5c <filewrite>
80104797:	83 c4 10             	add    $0x10,%esp
}
8010479a:	c9                   	leave  
8010479b:	c3                   	ret    
    return -1;
8010479c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047a1:	eb f7                	jmp    8010479a <sys_write+0x5d>
801047a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047a8:	eb f0                	jmp    8010479a <sys_write+0x5d>
801047aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047af:	eb e9                	jmp    8010479a <sys_write+0x5d>

801047b1 <sys_close>:
{
801047b1:	55                   	push   %ebp
801047b2:	89 e5                	mov    %esp,%ebp
801047b4:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
801047b7:	8d 4d f0             	lea    -0x10(%ebp),%ecx
801047ba:	8d 55 f4             	lea    -0xc(%ebp),%edx
801047bd:	b8 00 00 00 00       	mov    $0x0,%eax
801047c2:	e8 55 fc ff ff       	call   8010441c <argfd>
801047c7:	85 c0                	test   %eax,%eax
801047c9:	78 25                	js     801047f0 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
801047cb:	e8 1a ee ff ff       	call   801035ea <myproc>
801047d0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801047d3:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
801047da:	00 
  fileclose(f);
801047db:	83 ec 0c             	sub    $0xc,%esp
801047de:	ff 75 f0             	pushl  -0x10(%ebp)
801047e1:	e8 ed c4 ff ff       	call   80100cd3 <fileclose>
  return 0;
801047e6:	83 c4 10             	add    $0x10,%esp
801047e9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801047ee:	c9                   	leave  
801047ef:	c3                   	ret    
    return -1;
801047f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047f5:	eb f7                	jmp    801047ee <sys_close+0x3d>

801047f7 <sys_fstat>:
{
801047f7:	55                   	push   %ebp
801047f8:	89 e5                	mov    %esp,%ebp
801047fa:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801047fd:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104800:	ba 00 00 00 00       	mov    $0x0,%edx
80104805:	b8 00 00 00 00       	mov    $0x0,%eax
8010480a:	e8 0d fc ff ff       	call   8010441c <argfd>
8010480f:	85 c0                	test   %eax,%eax
80104811:	78 2a                	js     8010483d <sys_fstat+0x46>
80104813:	83 ec 04             	sub    $0x4,%esp
80104816:	6a 14                	push   $0x14
80104818:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010481b:	50                   	push   %eax
8010481c:	6a 01                	push   $0x1
8010481e:	e8 09 fb ff ff       	call   8010432c <argptr>
80104823:	83 c4 10             	add    $0x10,%esp
80104826:	85 c0                	test   %eax,%eax
80104828:	78 1a                	js     80104844 <sys_fstat+0x4d>
  return filestat(f, st);
8010482a:	83 ec 08             	sub    $0x8,%esp
8010482d:	ff 75 f0             	pushl  -0x10(%ebp)
80104830:	ff 75 f4             	pushl  -0xc(%ebp)
80104833:	e8 58 c5 ff ff       	call   80100d90 <filestat>
80104838:	83 c4 10             	add    $0x10,%esp
}
8010483b:	c9                   	leave  
8010483c:	c3                   	ret    
    return -1;
8010483d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104842:	eb f7                	jmp    8010483b <sys_fstat+0x44>
80104844:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104849:	eb f0                	jmp    8010483b <sys_fstat+0x44>

8010484b <sys_link>:
{
8010484b:	55                   	push   %ebp
8010484c:	89 e5                	mov    %esp,%ebp
8010484e:	56                   	push   %esi
8010484f:	53                   	push   %ebx
80104850:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104853:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104856:	50                   	push   %eax
80104857:	6a 00                	push   $0x0
80104859:	e8 36 fb ff ff       	call   80104394 <argstr>
8010485e:	83 c4 10             	add    $0x10,%esp
80104861:	85 c0                	test   %eax,%eax
80104863:	0f 88 32 01 00 00    	js     8010499b <sys_link+0x150>
80104869:	83 ec 08             	sub    $0x8,%esp
8010486c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010486f:	50                   	push   %eax
80104870:	6a 01                	push   $0x1
80104872:	e8 1d fb ff ff       	call   80104394 <argstr>
80104877:	83 c4 10             	add    $0x10,%esp
8010487a:	85 c0                	test   %eax,%eax
8010487c:	0f 88 20 01 00 00    	js     801049a2 <sys_link+0x157>
  begin_op();
80104882:	e8 02 e3 ff ff       	call   80102b89 <begin_op>
  if((ip = namei(old)) == 0){
80104887:	83 ec 0c             	sub    $0xc,%esp
8010488a:	ff 75 e0             	pushl  -0x20(%ebp)
8010488d:	e8 4f d3 ff ff       	call   80101be1 <namei>
80104892:	89 c3                	mov    %eax,%ebx
80104894:	83 c4 10             	add    $0x10,%esp
80104897:	85 c0                	test   %eax,%eax
80104899:	0f 84 99 00 00 00    	je     80104938 <sys_link+0xed>
  ilock(ip);
8010489f:	83 ec 0c             	sub    $0xc,%esp
801048a2:	50                   	push   %eax
801048a3:	e8 d9 cc ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
801048a8:	83 c4 10             	add    $0x10,%esp
801048ab:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801048b0:	0f 84 8e 00 00 00    	je     80104944 <sys_link+0xf9>
  ip->nlink++;
801048b6:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801048ba:	83 c0 01             	add    $0x1,%eax
801048bd:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801048c1:	83 ec 0c             	sub    $0xc,%esp
801048c4:	53                   	push   %ebx
801048c5:	e8 56 cb ff ff       	call   80101420 <iupdate>
  iunlock(ip);
801048ca:	89 1c 24             	mov    %ebx,(%esp)
801048cd:	e8 71 cd ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
801048d2:	83 c4 08             	add    $0x8,%esp
801048d5:	8d 45 ea             	lea    -0x16(%ebp),%eax
801048d8:	50                   	push   %eax
801048d9:	ff 75 e4             	pushl  -0x1c(%ebp)
801048dc:	e8 18 d3 ff ff       	call   80101bf9 <nameiparent>
801048e1:	89 c6                	mov    %eax,%esi
801048e3:	83 c4 10             	add    $0x10,%esp
801048e6:	85 c0                	test   %eax,%eax
801048e8:	74 7e                	je     80104968 <sys_link+0x11d>
  ilock(dp);
801048ea:	83 ec 0c             	sub    $0xc,%esp
801048ed:	50                   	push   %eax
801048ee:	e8 8e cc ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801048f3:	83 c4 10             	add    $0x10,%esp
801048f6:	8b 03                	mov    (%ebx),%eax
801048f8:	39 06                	cmp    %eax,(%esi)
801048fa:	75 60                	jne    8010495c <sys_link+0x111>
801048fc:	83 ec 04             	sub    $0x4,%esp
801048ff:	ff 73 04             	pushl  0x4(%ebx)
80104902:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104905:	50                   	push   %eax
80104906:	56                   	push   %esi
80104907:	e8 24 d2 ff ff       	call   80101b30 <dirlink>
8010490c:	83 c4 10             	add    $0x10,%esp
8010490f:	85 c0                	test   %eax,%eax
80104911:	78 49                	js     8010495c <sys_link+0x111>
  iunlockput(dp);
80104913:	83 ec 0c             	sub    $0xc,%esp
80104916:	56                   	push   %esi
80104917:	e8 0c ce ff ff       	call   80101728 <iunlockput>
  iput(ip);
8010491c:	89 1c 24             	mov    %ebx,(%esp)
8010491f:	e8 64 cd ff ff       	call   80101688 <iput>
  end_op();
80104924:	e8 da e2 ff ff       	call   80102c03 <end_op>
  return 0;
80104929:	83 c4 10             	add    $0x10,%esp
8010492c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104931:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104934:	5b                   	pop    %ebx
80104935:	5e                   	pop    %esi
80104936:	5d                   	pop    %ebp
80104937:	c3                   	ret    
    end_op();
80104938:	e8 c6 e2 ff ff       	call   80102c03 <end_op>
    return -1;
8010493d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104942:	eb ed                	jmp    80104931 <sys_link+0xe6>
    iunlockput(ip);
80104944:	83 ec 0c             	sub    $0xc,%esp
80104947:	53                   	push   %ebx
80104948:	e8 db cd ff ff       	call   80101728 <iunlockput>
    end_op();
8010494d:	e8 b1 e2 ff ff       	call   80102c03 <end_op>
    return -1;
80104952:	83 c4 10             	add    $0x10,%esp
80104955:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010495a:	eb d5                	jmp    80104931 <sys_link+0xe6>
    iunlockput(dp);
8010495c:	83 ec 0c             	sub    $0xc,%esp
8010495f:	56                   	push   %esi
80104960:	e8 c3 cd ff ff       	call   80101728 <iunlockput>
    goto bad;
80104965:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80104968:	83 ec 0c             	sub    $0xc,%esp
8010496b:	53                   	push   %ebx
8010496c:	e8 10 cc ff ff       	call   80101581 <ilock>
  ip->nlink--;
80104971:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104975:	83 e8 01             	sub    $0x1,%eax
80104978:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010497c:	89 1c 24             	mov    %ebx,(%esp)
8010497f:	e8 9c ca ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104984:	89 1c 24             	mov    %ebx,(%esp)
80104987:	e8 9c cd ff ff       	call   80101728 <iunlockput>
  end_op();
8010498c:	e8 72 e2 ff ff       	call   80102c03 <end_op>
  return -1;
80104991:	83 c4 10             	add    $0x10,%esp
80104994:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104999:	eb 96                	jmp    80104931 <sys_link+0xe6>
    return -1;
8010499b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049a0:	eb 8f                	jmp    80104931 <sys_link+0xe6>
801049a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049a7:	eb 88                	jmp    80104931 <sys_link+0xe6>

801049a9 <sys_unlink>:
{
801049a9:	55                   	push   %ebp
801049aa:	89 e5                	mov    %esp,%ebp
801049ac:	57                   	push   %edi
801049ad:	56                   	push   %esi
801049ae:	53                   	push   %ebx
801049af:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
801049b2:	8d 45 c4             	lea    -0x3c(%ebp),%eax
801049b5:	50                   	push   %eax
801049b6:	6a 00                	push   $0x0
801049b8:	e8 d7 f9 ff ff       	call   80104394 <argstr>
801049bd:	83 c4 10             	add    $0x10,%esp
801049c0:	85 c0                	test   %eax,%eax
801049c2:	0f 88 83 01 00 00    	js     80104b4b <sys_unlink+0x1a2>
  begin_op();
801049c8:	e8 bc e1 ff ff       	call   80102b89 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
801049cd:	83 ec 08             	sub    $0x8,%esp
801049d0:	8d 45 ca             	lea    -0x36(%ebp),%eax
801049d3:	50                   	push   %eax
801049d4:	ff 75 c4             	pushl  -0x3c(%ebp)
801049d7:	e8 1d d2 ff ff       	call   80101bf9 <nameiparent>
801049dc:	89 c6                	mov    %eax,%esi
801049de:	83 c4 10             	add    $0x10,%esp
801049e1:	85 c0                	test   %eax,%eax
801049e3:	0f 84 ed 00 00 00    	je     80104ad6 <sys_unlink+0x12d>
  ilock(dp);
801049e9:	83 ec 0c             	sub    $0xc,%esp
801049ec:	50                   	push   %eax
801049ed:	e8 8f cb ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801049f2:	83 c4 08             	add    $0x8,%esp
801049f5:	68 9e 70 10 80       	push   $0x8010709e
801049fa:	8d 45 ca             	lea    -0x36(%ebp),%eax
801049fd:	50                   	push   %eax
801049fe:	e8 98 cf ff ff       	call   8010199b <namecmp>
80104a03:	83 c4 10             	add    $0x10,%esp
80104a06:	85 c0                	test   %eax,%eax
80104a08:	0f 84 fc 00 00 00    	je     80104b0a <sys_unlink+0x161>
80104a0e:	83 ec 08             	sub    $0x8,%esp
80104a11:	68 9d 70 10 80       	push   $0x8010709d
80104a16:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104a19:	50                   	push   %eax
80104a1a:	e8 7c cf ff ff       	call   8010199b <namecmp>
80104a1f:	83 c4 10             	add    $0x10,%esp
80104a22:	85 c0                	test   %eax,%eax
80104a24:	0f 84 e0 00 00 00    	je     80104b0a <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
80104a2a:	83 ec 04             	sub    $0x4,%esp
80104a2d:	8d 45 c0             	lea    -0x40(%ebp),%eax
80104a30:	50                   	push   %eax
80104a31:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104a34:	50                   	push   %eax
80104a35:	56                   	push   %esi
80104a36:	e8 75 cf ff ff       	call   801019b0 <dirlookup>
80104a3b:	89 c3                	mov    %eax,%ebx
80104a3d:	83 c4 10             	add    $0x10,%esp
80104a40:	85 c0                	test   %eax,%eax
80104a42:	0f 84 c2 00 00 00    	je     80104b0a <sys_unlink+0x161>
  ilock(ip);
80104a48:	83 ec 0c             	sub    $0xc,%esp
80104a4b:	50                   	push   %eax
80104a4c:	e8 30 cb ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
80104a51:	83 c4 10             	add    $0x10,%esp
80104a54:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80104a59:	0f 8e 83 00 00 00    	jle    80104ae2 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104a5f:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104a64:	0f 84 85 00 00 00    	je     80104aef <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
80104a6a:	83 ec 04             	sub    $0x4,%esp
80104a6d:	6a 10                	push   $0x10
80104a6f:	6a 00                	push   $0x0
80104a71:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104a74:	57                   	push   %edi
80104a75:	e8 3f f6 ff ff       	call   801040b9 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104a7a:	6a 10                	push   $0x10
80104a7c:	ff 75 c0             	pushl  -0x40(%ebp)
80104a7f:	57                   	push   %edi
80104a80:	56                   	push   %esi
80104a81:	e8 ea cd ff ff       	call   80101870 <writei>
80104a86:	83 c4 20             	add    $0x20,%esp
80104a89:	83 f8 10             	cmp    $0x10,%eax
80104a8c:	0f 85 90 00 00 00    	jne    80104b22 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104a92:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104a97:	0f 84 92 00 00 00    	je     80104b2f <sys_unlink+0x186>
  iunlockput(dp);
80104a9d:	83 ec 0c             	sub    $0xc,%esp
80104aa0:	56                   	push   %esi
80104aa1:	e8 82 cc ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
80104aa6:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104aaa:	83 e8 01             	sub    $0x1,%eax
80104aad:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104ab1:	89 1c 24             	mov    %ebx,(%esp)
80104ab4:	e8 67 c9 ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104ab9:	89 1c 24             	mov    %ebx,(%esp)
80104abc:	e8 67 cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104ac1:	e8 3d e1 ff ff       	call   80102c03 <end_op>
  return 0;
80104ac6:	83 c4 10             	add    $0x10,%esp
80104ac9:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ace:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104ad1:	5b                   	pop    %ebx
80104ad2:	5e                   	pop    %esi
80104ad3:	5f                   	pop    %edi
80104ad4:	5d                   	pop    %ebp
80104ad5:	c3                   	ret    
    end_op();
80104ad6:	e8 28 e1 ff ff       	call   80102c03 <end_op>
    return -1;
80104adb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ae0:	eb ec                	jmp    80104ace <sys_unlink+0x125>
    panic("unlink: nlink < 1");
80104ae2:	83 ec 0c             	sub    $0xc,%esp
80104ae5:	68 bc 70 10 80       	push   $0x801070bc
80104aea:	e8 59 b8 ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104aef:	89 d8                	mov    %ebx,%eax
80104af1:	e8 c4 f9 ff ff       	call   801044ba <isdirempty>
80104af6:	85 c0                	test   %eax,%eax
80104af8:	0f 85 6c ff ff ff    	jne    80104a6a <sys_unlink+0xc1>
    iunlockput(ip);
80104afe:	83 ec 0c             	sub    $0xc,%esp
80104b01:	53                   	push   %ebx
80104b02:	e8 21 cc ff ff       	call   80101728 <iunlockput>
    goto bad;
80104b07:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104b0a:	83 ec 0c             	sub    $0xc,%esp
80104b0d:	56                   	push   %esi
80104b0e:	e8 15 cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104b13:	e8 eb e0 ff ff       	call   80102c03 <end_op>
  return -1;
80104b18:	83 c4 10             	add    $0x10,%esp
80104b1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b20:	eb ac                	jmp    80104ace <sys_unlink+0x125>
    panic("unlink: writei");
80104b22:	83 ec 0c             	sub    $0xc,%esp
80104b25:	68 ce 70 10 80       	push   $0x801070ce
80104b2a:	e8 19 b8 ff ff       	call   80100348 <panic>
    dp->nlink--;
80104b2f:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104b33:	83 e8 01             	sub    $0x1,%eax
80104b36:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104b3a:	83 ec 0c             	sub    $0xc,%esp
80104b3d:	56                   	push   %esi
80104b3e:	e8 dd c8 ff ff       	call   80101420 <iupdate>
80104b43:	83 c4 10             	add    $0x10,%esp
80104b46:	e9 52 ff ff ff       	jmp    80104a9d <sys_unlink+0xf4>
    return -1;
80104b4b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b50:	e9 79 ff ff ff       	jmp    80104ace <sys_unlink+0x125>

80104b55 <sys_open>:

int
sys_open(void)
{
80104b55:	55                   	push   %ebp
80104b56:	89 e5                	mov    %esp,%ebp
80104b58:	57                   	push   %edi
80104b59:	56                   	push   %esi
80104b5a:	53                   	push   %ebx
80104b5b:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104b5e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104b61:	50                   	push   %eax
80104b62:	6a 00                	push   $0x0
80104b64:	e8 2b f8 ff ff       	call   80104394 <argstr>
80104b69:	83 c4 10             	add    $0x10,%esp
80104b6c:	85 c0                	test   %eax,%eax
80104b6e:	0f 88 30 01 00 00    	js     80104ca4 <sys_open+0x14f>
80104b74:	83 ec 08             	sub    $0x8,%esp
80104b77:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104b7a:	50                   	push   %eax
80104b7b:	6a 01                	push   $0x1
80104b7d:	e8 82 f7 ff ff       	call   80104304 <argint>
80104b82:	83 c4 10             	add    $0x10,%esp
80104b85:	85 c0                	test   %eax,%eax
80104b87:	0f 88 21 01 00 00    	js     80104cae <sys_open+0x159>
    return -1;

  begin_op();
80104b8d:	e8 f7 df ff ff       	call   80102b89 <begin_op>

  if(omode & O_CREATE){
80104b92:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104b96:	0f 84 84 00 00 00    	je     80104c20 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
80104b9c:	83 ec 0c             	sub    $0xc,%esp
80104b9f:	6a 00                	push   $0x0
80104ba1:	b9 00 00 00 00       	mov    $0x0,%ecx
80104ba6:	ba 02 00 00 00       	mov    $0x2,%edx
80104bab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104bae:	e8 5e f9 ff ff       	call   80104511 <create>
80104bb3:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104bb5:	83 c4 10             	add    $0x10,%esp
80104bb8:	85 c0                	test   %eax,%eax
80104bba:	74 58                	je     80104c14 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104bbc:	e8 6c c0 ff ff       	call   80100c2d <filealloc>
80104bc1:	89 c3                	mov    %eax,%ebx
80104bc3:	85 c0                	test   %eax,%eax
80104bc5:	0f 84 ae 00 00 00    	je     80104c79 <sys_open+0x124>
80104bcb:	e8 b3 f8 ff ff       	call   80104483 <fdalloc>
80104bd0:	89 c7                	mov    %eax,%edi
80104bd2:	85 c0                	test   %eax,%eax
80104bd4:	0f 88 9f 00 00 00    	js     80104c79 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104bda:	83 ec 0c             	sub    $0xc,%esp
80104bdd:	56                   	push   %esi
80104bde:	e8 60 ca ff ff       	call   80101643 <iunlock>
  end_op();
80104be3:	e8 1b e0 ff ff       	call   80102c03 <end_op>

  f->type = FD_INODE;
80104be8:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104bee:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104bf1:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104bf8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104bfb:	83 c4 10             	add    $0x10,%esp
80104bfe:	a8 01                	test   $0x1,%al
80104c00:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104c04:	a8 03                	test   $0x3,%al
80104c06:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104c0a:	89 f8                	mov    %edi,%eax
80104c0c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104c0f:	5b                   	pop    %ebx
80104c10:	5e                   	pop    %esi
80104c11:	5f                   	pop    %edi
80104c12:	5d                   	pop    %ebp
80104c13:	c3                   	ret    
      end_op();
80104c14:	e8 ea df ff ff       	call   80102c03 <end_op>
      return -1;
80104c19:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104c1e:	eb ea                	jmp    80104c0a <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104c20:	83 ec 0c             	sub    $0xc,%esp
80104c23:	ff 75 e4             	pushl  -0x1c(%ebp)
80104c26:	e8 b6 cf ff ff       	call   80101be1 <namei>
80104c2b:	89 c6                	mov    %eax,%esi
80104c2d:	83 c4 10             	add    $0x10,%esp
80104c30:	85 c0                	test   %eax,%eax
80104c32:	74 39                	je     80104c6d <sys_open+0x118>
    ilock(ip);
80104c34:	83 ec 0c             	sub    $0xc,%esp
80104c37:	50                   	push   %eax
80104c38:	e8 44 c9 ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104c3d:	83 c4 10             	add    $0x10,%esp
80104c40:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104c45:	0f 85 71 ff ff ff    	jne    80104bbc <sys_open+0x67>
80104c4b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104c4f:	0f 84 67 ff ff ff    	je     80104bbc <sys_open+0x67>
      iunlockput(ip);
80104c55:	83 ec 0c             	sub    $0xc,%esp
80104c58:	56                   	push   %esi
80104c59:	e8 ca ca ff ff       	call   80101728 <iunlockput>
      end_op();
80104c5e:	e8 a0 df ff ff       	call   80102c03 <end_op>
      return -1;
80104c63:	83 c4 10             	add    $0x10,%esp
80104c66:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104c6b:	eb 9d                	jmp    80104c0a <sys_open+0xb5>
      end_op();
80104c6d:	e8 91 df ff ff       	call   80102c03 <end_op>
      return -1;
80104c72:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104c77:	eb 91                	jmp    80104c0a <sys_open+0xb5>
    if(f)
80104c79:	85 db                	test   %ebx,%ebx
80104c7b:	74 0c                	je     80104c89 <sys_open+0x134>
      fileclose(f);
80104c7d:	83 ec 0c             	sub    $0xc,%esp
80104c80:	53                   	push   %ebx
80104c81:	e8 4d c0 ff ff       	call   80100cd3 <fileclose>
80104c86:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104c89:	83 ec 0c             	sub    $0xc,%esp
80104c8c:	56                   	push   %esi
80104c8d:	e8 96 ca ff ff       	call   80101728 <iunlockput>
    end_op();
80104c92:	e8 6c df ff ff       	call   80102c03 <end_op>
    return -1;
80104c97:	83 c4 10             	add    $0x10,%esp
80104c9a:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104c9f:	e9 66 ff ff ff       	jmp    80104c0a <sys_open+0xb5>
    return -1;
80104ca4:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104ca9:	e9 5c ff ff ff       	jmp    80104c0a <sys_open+0xb5>
80104cae:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104cb3:	e9 52 ff ff ff       	jmp    80104c0a <sys_open+0xb5>

80104cb8 <sys_mkdir>:

int
sys_mkdir(void)
{
80104cb8:	55                   	push   %ebp
80104cb9:	89 e5                	mov    %esp,%ebp
80104cbb:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104cbe:	e8 c6 de ff ff       	call   80102b89 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104cc3:	83 ec 08             	sub    $0x8,%esp
80104cc6:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104cc9:	50                   	push   %eax
80104cca:	6a 00                	push   $0x0
80104ccc:	e8 c3 f6 ff ff       	call   80104394 <argstr>
80104cd1:	83 c4 10             	add    $0x10,%esp
80104cd4:	85 c0                	test   %eax,%eax
80104cd6:	78 36                	js     80104d0e <sys_mkdir+0x56>
80104cd8:	83 ec 0c             	sub    $0xc,%esp
80104cdb:	6a 00                	push   $0x0
80104cdd:	b9 00 00 00 00       	mov    $0x0,%ecx
80104ce2:	ba 01 00 00 00       	mov    $0x1,%edx
80104ce7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cea:	e8 22 f8 ff ff       	call   80104511 <create>
80104cef:	83 c4 10             	add    $0x10,%esp
80104cf2:	85 c0                	test   %eax,%eax
80104cf4:	74 18                	je     80104d0e <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104cf6:	83 ec 0c             	sub    $0xc,%esp
80104cf9:	50                   	push   %eax
80104cfa:	e8 29 ca ff ff       	call   80101728 <iunlockput>
  end_op();
80104cff:	e8 ff de ff ff       	call   80102c03 <end_op>
  return 0;
80104d04:	83 c4 10             	add    $0x10,%esp
80104d07:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d0c:	c9                   	leave  
80104d0d:	c3                   	ret    
    end_op();
80104d0e:	e8 f0 de ff ff       	call   80102c03 <end_op>
    return -1;
80104d13:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d18:	eb f2                	jmp    80104d0c <sys_mkdir+0x54>

80104d1a <sys_mknod>:

int
sys_mknod(void)
{
80104d1a:	55                   	push   %ebp
80104d1b:	89 e5                	mov    %esp,%ebp
80104d1d:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104d20:	e8 64 de ff ff       	call   80102b89 <begin_op>
  if((argstr(0, &path)) < 0 ||
80104d25:	83 ec 08             	sub    $0x8,%esp
80104d28:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d2b:	50                   	push   %eax
80104d2c:	6a 00                	push   $0x0
80104d2e:	e8 61 f6 ff ff       	call   80104394 <argstr>
80104d33:	83 c4 10             	add    $0x10,%esp
80104d36:	85 c0                	test   %eax,%eax
80104d38:	78 62                	js     80104d9c <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104d3a:	83 ec 08             	sub    $0x8,%esp
80104d3d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104d40:	50                   	push   %eax
80104d41:	6a 01                	push   $0x1
80104d43:	e8 bc f5 ff ff       	call   80104304 <argint>
  if((argstr(0, &path)) < 0 ||
80104d48:	83 c4 10             	add    $0x10,%esp
80104d4b:	85 c0                	test   %eax,%eax
80104d4d:	78 4d                	js     80104d9c <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104d4f:	83 ec 08             	sub    $0x8,%esp
80104d52:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104d55:	50                   	push   %eax
80104d56:	6a 02                	push   $0x2
80104d58:	e8 a7 f5 ff ff       	call   80104304 <argint>
     argint(1, &major) < 0 ||
80104d5d:	83 c4 10             	add    $0x10,%esp
80104d60:	85 c0                	test   %eax,%eax
80104d62:	78 38                	js     80104d9c <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104d64:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104d68:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104d6c:	83 ec 0c             	sub    $0xc,%esp
80104d6f:	50                   	push   %eax
80104d70:	ba 03 00 00 00       	mov    $0x3,%edx
80104d75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d78:	e8 94 f7 ff ff       	call   80104511 <create>
80104d7d:	83 c4 10             	add    $0x10,%esp
80104d80:	85 c0                	test   %eax,%eax
80104d82:	74 18                	je     80104d9c <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104d84:	83 ec 0c             	sub    $0xc,%esp
80104d87:	50                   	push   %eax
80104d88:	e8 9b c9 ff ff       	call   80101728 <iunlockput>
  end_op();
80104d8d:	e8 71 de ff ff       	call   80102c03 <end_op>
  return 0;
80104d92:	83 c4 10             	add    $0x10,%esp
80104d95:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d9a:	c9                   	leave  
80104d9b:	c3                   	ret    
    end_op();
80104d9c:	e8 62 de ff ff       	call   80102c03 <end_op>
    return -1;
80104da1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104da6:	eb f2                	jmp    80104d9a <sys_mknod+0x80>

80104da8 <sys_chdir>:

int
sys_chdir(void)
{
80104da8:	55                   	push   %ebp
80104da9:	89 e5                	mov    %esp,%ebp
80104dab:	56                   	push   %esi
80104dac:	53                   	push   %ebx
80104dad:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104db0:	e8 35 e8 ff ff       	call   801035ea <myproc>
80104db5:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104db7:	e8 cd dd ff ff       	call   80102b89 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104dbc:	83 ec 08             	sub    $0x8,%esp
80104dbf:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104dc2:	50                   	push   %eax
80104dc3:	6a 00                	push   $0x0
80104dc5:	e8 ca f5 ff ff       	call   80104394 <argstr>
80104dca:	83 c4 10             	add    $0x10,%esp
80104dcd:	85 c0                	test   %eax,%eax
80104dcf:	78 52                	js     80104e23 <sys_chdir+0x7b>
80104dd1:	83 ec 0c             	sub    $0xc,%esp
80104dd4:	ff 75 f4             	pushl  -0xc(%ebp)
80104dd7:	e8 05 ce ff ff       	call   80101be1 <namei>
80104ddc:	89 c3                	mov    %eax,%ebx
80104dde:	83 c4 10             	add    $0x10,%esp
80104de1:	85 c0                	test   %eax,%eax
80104de3:	74 3e                	je     80104e23 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104de5:	83 ec 0c             	sub    $0xc,%esp
80104de8:	50                   	push   %eax
80104de9:	e8 93 c7 ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104dee:	83 c4 10             	add    $0x10,%esp
80104df1:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104df6:	75 37                	jne    80104e2f <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104df8:	83 ec 0c             	sub    $0xc,%esp
80104dfb:	53                   	push   %ebx
80104dfc:	e8 42 c8 ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104e01:	83 c4 04             	add    $0x4,%esp
80104e04:	ff 76 68             	pushl  0x68(%esi)
80104e07:	e8 7c c8 ff ff       	call   80101688 <iput>
  end_op();
80104e0c:	e8 f2 dd ff ff       	call   80102c03 <end_op>
  curproc->cwd = ip;
80104e11:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104e14:	83 c4 10             	add    $0x10,%esp
80104e17:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e1c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104e1f:	5b                   	pop    %ebx
80104e20:	5e                   	pop    %esi
80104e21:	5d                   	pop    %ebp
80104e22:	c3                   	ret    
    end_op();
80104e23:	e8 db dd ff ff       	call   80102c03 <end_op>
    return -1;
80104e28:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e2d:	eb ed                	jmp    80104e1c <sys_chdir+0x74>
    iunlockput(ip);
80104e2f:	83 ec 0c             	sub    $0xc,%esp
80104e32:	53                   	push   %ebx
80104e33:	e8 f0 c8 ff ff       	call   80101728 <iunlockput>
    end_op();
80104e38:	e8 c6 dd ff ff       	call   80102c03 <end_op>
    return -1;
80104e3d:	83 c4 10             	add    $0x10,%esp
80104e40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e45:	eb d5                	jmp    80104e1c <sys_chdir+0x74>

80104e47 <sys_exec>:

int
sys_exec(void)
{
80104e47:	55                   	push   %ebp
80104e48:	89 e5                	mov    %esp,%ebp
80104e4a:	53                   	push   %ebx
80104e4b:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104e51:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e54:	50                   	push   %eax
80104e55:	6a 00                	push   $0x0
80104e57:	e8 38 f5 ff ff       	call   80104394 <argstr>
80104e5c:	83 c4 10             	add    $0x10,%esp
80104e5f:	85 c0                	test   %eax,%eax
80104e61:	0f 88 a8 00 00 00    	js     80104f0f <sys_exec+0xc8>
80104e67:	83 ec 08             	sub    $0x8,%esp
80104e6a:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104e70:	50                   	push   %eax
80104e71:	6a 01                	push   $0x1
80104e73:	e8 8c f4 ff ff       	call   80104304 <argint>
80104e78:	83 c4 10             	add    $0x10,%esp
80104e7b:	85 c0                	test   %eax,%eax
80104e7d:	0f 88 93 00 00 00    	js     80104f16 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104e83:	83 ec 04             	sub    $0x4,%esp
80104e86:	68 80 00 00 00       	push   $0x80
80104e8b:	6a 00                	push   $0x0
80104e8d:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104e93:	50                   	push   %eax
80104e94:	e8 20 f2 ff ff       	call   801040b9 <memset>
80104e99:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104e9c:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104ea1:	83 fb 1f             	cmp    $0x1f,%ebx
80104ea4:	77 77                	ja     80104f1d <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104ea6:	83 ec 08             	sub    $0x8,%esp
80104ea9:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104eaf:	50                   	push   %eax
80104eb0:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104eb6:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104eb9:	50                   	push   %eax
80104eba:	e8 c9 f3 ff ff       	call   80104288 <fetchint>
80104ebf:	83 c4 10             	add    $0x10,%esp
80104ec2:	85 c0                	test   %eax,%eax
80104ec4:	78 5e                	js     80104f24 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104ec6:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104ecc:	85 c0                	test   %eax,%eax
80104ece:	74 1d                	je     80104eed <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104ed0:	83 ec 08             	sub    $0x8,%esp
80104ed3:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104eda:	52                   	push   %edx
80104edb:	50                   	push   %eax
80104edc:	e8 e3 f3 ff ff       	call   801042c4 <fetchstr>
80104ee1:	83 c4 10             	add    $0x10,%esp
80104ee4:	85 c0                	test   %eax,%eax
80104ee6:	78 46                	js     80104f2e <sys_exec+0xe7>
  for(i=0;; i++){
80104ee8:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104eeb:	eb b4                	jmp    80104ea1 <sys_exec+0x5a>
      argv[i] = 0;
80104eed:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104ef4:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104ef8:	83 ec 08             	sub    $0x8,%esp
80104efb:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104f01:	50                   	push   %eax
80104f02:	ff 75 f4             	pushl  -0xc(%ebp)
80104f05:	e8 c8 b9 ff ff       	call   801008d2 <exec>
80104f0a:	83 c4 10             	add    $0x10,%esp
80104f0d:	eb 1a                	jmp    80104f29 <sys_exec+0xe2>
    return -1;
80104f0f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f14:	eb 13                	jmp    80104f29 <sys_exec+0xe2>
80104f16:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f1b:	eb 0c                	jmp    80104f29 <sys_exec+0xe2>
      return -1;
80104f1d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f22:	eb 05                	jmp    80104f29 <sys_exec+0xe2>
      return -1;
80104f24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104f29:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f2c:	c9                   	leave  
80104f2d:	c3                   	ret    
      return -1;
80104f2e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f33:	eb f4                	jmp    80104f29 <sys_exec+0xe2>

80104f35 <sys_pipe>:

int
sys_pipe(void)
{
80104f35:	55                   	push   %ebp
80104f36:	89 e5                	mov    %esp,%ebp
80104f38:	53                   	push   %ebx
80104f39:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104f3c:	6a 08                	push   $0x8
80104f3e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f41:	50                   	push   %eax
80104f42:	6a 00                	push   $0x0
80104f44:	e8 e3 f3 ff ff       	call   8010432c <argptr>
80104f49:	83 c4 10             	add    $0x10,%esp
80104f4c:	85 c0                	test   %eax,%eax
80104f4e:	78 77                	js     80104fc7 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104f50:	83 ec 08             	sub    $0x8,%esp
80104f53:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104f56:	50                   	push   %eax
80104f57:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104f5a:	50                   	push   %eax
80104f5b:	e8 bb e1 ff ff       	call   8010311b <pipealloc>
80104f60:	83 c4 10             	add    $0x10,%esp
80104f63:	85 c0                	test   %eax,%eax
80104f65:	78 67                	js     80104fce <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104f67:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f6a:	e8 14 f5 ff ff       	call   80104483 <fdalloc>
80104f6f:	89 c3                	mov    %eax,%ebx
80104f71:	85 c0                	test   %eax,%eax
80104f73:	78 21                	js     80104f96 <sys_pipe+0x61>
80104f75:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104f78:	e8 06 f5 ff ff       	call   80104483 <fdalloc>
80104f7d:	85 c0                	test   %eax,%eax
80104f7f:	78 15                	js     80104f96 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104f81:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f84:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104f86:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f89:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104f8c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f91:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f94:	c9                   	leave  
80104f95:	c3                   	ret    
    if(fd0 >= 0)
80104f96:	85 db                	test   %ebx,%ebx
80104f98:	78 0d                	js     80104fa7 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104f9a:	e8 4b e6 ff ff       	call   801035ea <myproc>
80104f9f:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104fa6:	00 
    fileclose(rf);
80104fa7:	83 ec 0c             	sub    $0xc,%esp
80104faa:	ff 75 f0             	pushl  -0x10(%ebp)
80104fad:	e8 21 bd ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104fb2:	83 c4 04             	add    $0x4,%esp
80104fb5:	ff 75 ec             	pushl  -0x14(%ebp)
80104fb8:	e8 16 bd ff ff       	call   80100cd3 <fileclose>
    return -1;
80104fbd:	83 c4 10             	add    $0x10,%esp
80104fc0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fc5:	eb ca                	jmp    80104f91 <sys_pipe+0x5c>
    return -1;
80104fc7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fcc:	eb c3                	jmp    80104f91 <sys_pipe+0x5c>
    return -1;
80104fce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fd3:	eb bc                	jmp    80104f91 <sys_pipe+0x5c>

80104fd5 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104fd5:	55                   	push   %ebp
80104fd6:	89 e5                	mov    %esp,%ebp
80104fd8:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104fdb:	e8 82 e7 ff ff       	call   80103762 <fork>
}
80104fe0:	c9                   	leave  
80104fe1:	c3                   	ret    

80104fe2 <sys_exit>:

int
sys_exit(void)
{
80104fe2:	55                   	push   %ebp
80104fe3:	89 e5                	mov    %esp,%ebp
80104fe5:	83 ec 08             	sub    $0x8,%esp
  exit();
80104fe8:	e8 a9 e9 ff ff       	call   80103996 <exit>
  return 0;  // not reached
}
80104fed:	b8 00 00 00 00       	mov    $0x0,%eax
80104ff2:	c9                   	leave  
80104ff3:	c3                   	ret    

80104ff4 <sys_wait>:

int
sys_wait(void)
{
80104ff4:	55                   	push   %ebp
80104ff5:	89 e5                	mov    %esp,%ebp
80104ff7:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104ffa:	e8 20 eb ff ff       	call   80103b1f <wait>
}
80104fff:	c9                   	leave  
80105000:	c3                   	ret    

80105001 <sys_kill>:

int
sys_kill(void)
{
80105001:	55                   	push   %ebp
80105002:	89 e5                	mov    %esp,%ebp
80105004:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80105007:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010500a:	50                   	push   %eax
8010500b:	6a 00                	push   $0x0
8010500d:	e8 f2 f2 ff ff       	call   80104304 <argint>
80105012:	83 c4 10             	add    $0x10,%esp
80105015:	85 c0                	test   %eax,%eax
80105017:	78 10                	js     80105029 <sys_kill+0x28>
    return -1;
  return kill(pid);
80105019:	83 ec 0c             	sub    $0xc,%esp
8010501c:	ff 75 f4             	pushl  -0xc(%ebp)
8010501f:	e8 f8 eb ff ff       	call   80103c1c <kill>
80105024:	83 c4 10             	add    $0x10,%esp
}
80105027:	c9                   	leave  
80105028:	c3                   	ret    
    return -1;
80105029:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010502e:	eb f7                	jmp    80105027 <sys_kill+0x26>

80105030 <sys_getpid>:

int
sys_getpid(void)
{
80105030:	55                   	push   %ebp
80105031:	89 e5                	mov    %esp,%ebp
80105033:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80105036:	e8 af e5 ff ff       	call   801035ea <myproc>
8010503b:	8b 40 10             	mov    0x10(%eax),%eax
}
8010503e:	c9                   	leave  
8010503f:	c3                   	ret    

80105040 <sys_sbrk>:

int
sys_sbrk(void)
{
80105040:	55                   	push   %ebp
80105041:	89 e5                	mov    %esp,%ebp
80105043:	53                   	push   %ebx
80105044:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80105047:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010504a:	50                   	push   %eax
8010504b:	6a 00                	push   $0x0
8010504d:	e8 b2 f2 ff ff       	call   80104304 <argint>
80105052:	83 c4 10             	add    $0x10,%esp
80105055:	85 c0                	test   %eax,%eax
80105057:	78 27                	js     80105080 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80105059:	e8 8c e5 ff ff       	call   801035ea <myproc>
8010505e:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80105060:	83 ec 0c             	sub    $0xc,%esp
80105063:	ff 75 f4             	pushl  -0xc(%ebp)
80105066:	e8 8a e6 ff ff       	call   801036f5 <growproc>
8010506b:	83 c4 10             	add    $0x10,%esp
8010506e:	85 c0                	test   %eax,%eax
80105070:	78 07                	js     80105079 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80105072:	89 d8                	mov    %ebx,%eax
80105074:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105077:	c9                   	leave  
80105078:	c3                   	ret    
    return -1;
80105079:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010507e:	eb f2                	jmp    80105072 <sys_sbrk+0x32>
    return -1;
80105080:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80105085:	eb eb                	jmp    80105072 <sys_sbrk+0x32>

80105087 <sys_sleep>:

int
sys_sleep(void)
{
80105087:	55                   	push   %ebp
80105088:	89 e5                	mov    %esp,%ebp
8010508a:	53                   	push   %ebx
8010508b:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
8010508e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105091:	50                   	push   %eax
80105092:	6a 00                	push   $0x0
80105094:	e8 6b f2 ff ff       	call   80104304 <argint>
80105099:	83 c4 10             	add    $0x10,%esp
8010509c:	85 c0                	test   %eax,%eax
8010509e:	78 75                	js     80105115 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
801050a0:	83 ec 0c             	sub    $0xc,%esp
801050a3:	68 80 4c 15 80       	push   $0x80154c80
801050a8:	e8 60 ef ff ff       	call   8010400d <acquire>
  ticks0 = ticks;
801050ad:	8b 1d c0 54 15 80    	mov    0x801554c0,%ebx
  while(ticks - ticks0 < n){
801050b3:	83 c4 10             	add    $0x10,%esp
801050b6:	a1 c0 54 15 80       	mov    0x801554c0,%eax
801050bb:	29 d8                	sub    %ebx,%eax
801050bd:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801050c0:	73 39                	jae    801050fb <sys_sleep+0x74>
    if(myproc()->killed){
801050c2:	e8 23 e5 ff ff       	call   801035ea <myproc>
801050c7:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801050cb:	75 17                	jne    801050e4 <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
801050cd:	83 ec 08             	sub    $0x8,%esp
801050d0:	68 80 4c 15 80       	push   $0x80154c80
801050d5:	68 c0 54 15 80       	push   $0x801554c0
801050da:	e8 af e9 ff ff       	call   80103a8e <sleep>
801050df:	83 c4 10             	add    $0x10,%esp
801050e2:	eb d2                	jmp    801050b6 <sys_sleep+0x2f>
      release(&tickslock);
801050e4:	83 ec 0c             	sub    $0xc,%esp
801050e7:	68 80 4c 15 80       	push   $0x80154c80
801050ec:	e8 81 ef ff ff       	call   80104072 <release>
      return -1;
801050f1:	83 c4 10             	add    $0x10,%esp
801050f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050f9:	eb 15                	jmp    80105110 <sys_sleep+0x89>
  }
  release(&tickslock);
801050fb:	83 ec 0c             	sub    $0xc,%esp
801050fe:	68 80 4c 15 80       	push   $0x80154c80
80105103:	e8 6a ef ff ff       	call   80104072 <release>
  return 0;
80105108:	83 c4 10             	add    $0x10,%esp
8010510b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105110:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105113:	c9                   	leave  
80105114:	c3                   	ret    
    return -1;
80105115:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010511a:	eb f4                	jmp    80105110 <sys_sleep+0x89>

8010511c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
8010511c:	55                   	push   %ebp
8010511d:	89 e5                	mov    %esp,%ebp
8010511f:	53                   	push   %ebx
80105120:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80105123:	68 80 4c 15 80       	push   $0x80154c80
80105128:	e8 e0 ee ff ff       	call   8010400d <acquire>
  xticks = ticks;
8010512d:	8b 1d c0 54 15 80    	mov    0x801554c0,%ebx
  release(&tickslock);
80105133:	c7 04 24 80 4c 15 80 	movl   $0x80154c80,(%esp)
8010513a:	e8 33 ef ff ff       	call   80104072 <release>
  return xticks;
}
8010513f:	89 d8                	mov    %ebx,%eax
80105141:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105144:	c9                   	leave  
80105145:	c3                   	ret    

80105146 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80105146:	55                   	push   %ebp
80105147:	89 e5                	mov    %esp,%ebp
80105149:	83 ec 1c             	sub    $0x1c,%esp
  int* frames;
  int* pids;
  int numframes;

  if(argptr(0, (void*)&frames,sizeof(frames)) < 0)
8010514c:	6a 04                	push   $0x4
8010514e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105151:	50                   	push   %eax
80105152:	6a 00                	push   $0x0
80105154:	e8 d3 f1 ff ff       	call   8010432c <argptr>
80105159:	83 c4 10             	add    $0x10,%esp
8010515c:	85 c0                	test   %eax,%eax
8010515e:	78 42                	js     801051a2 <sys_dump_physmem+0x5c>
    return -1;
  
  if(argptr(1, (void*)&pids, sizeof(pids)) < 0)
80105160:	83 ec 04             	sub    $0x4,%esp
80105163:	6a 04                	push   $0x4
80105165:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105168:	50                   	push   %eax
80105169:	6a 01                	push   $0x1
8010516b:	e8 bc f1 ff ff       	call   8010432c <argptr>
80105170:	83 c4 10             	add    $0x10,%esp
80105173:	85 c0                	test   %eax,%eax
80105175:	78 32                	js     801051a9 <sys_dump_physmem+0x63>
    return -1;
  
  if(argint(2, &numframes) < 0)
80105177:	83 ec 08             	sub    $0x8,%esp
8010517a:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010517d:	50                   	push   %eax
8010517e:	6a 02                	push   $0x2
80105180:	e8 7f f1 ff ff       	call   80104304 <argint>
80105185:	83 c4 10             	add    $0x10,%esp
80105188:	85 c0                	test   %eax,%eax
8010518a:	78 24                	js     801051b0 <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
8010518c:	83 ec 04             	sub    $0x4,%esp
8010518f:	ff 75 ec             	pushl  -0x14(%ebp)
80105192:	ff 75 f0             	pushl  -0x10(%ebp)
80105195:	ff 75 f4             	pushl  -0xc(%ebp)
80105198:	e8 a5 eb ff ff       	call   80103d42 <dump_physmem>
8010519d:	83 c4 10             	add    $0x10,%esp
801051a0:	c9                   	leave  
801051a1:	c3                   	ret    
    return -1;
801051a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051a7:	eb f7                	jmp    801051a0 <sys_dump_physmem+0x5a>
    return -1;
801051a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051ae:	eb f0                	jmp    801051a0 <sys_dump_physmem+0x5a>
    return -1;
801051b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051b5:	eb e9                	jmp    801051a0 <sys_dump_physmem+0x5a>

801051b7 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801051b7:	1e                   	push   %ds
  pushl %es
801051b8:	06                   	push   %es
  pushl %fs
801051b9:	0f a0                	push   %fs
  pushl %gs
801051bb:	0f a8                	push   %gs
  pushal
801051bd:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
801051be:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801051c2:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801051c4:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
801051c6:	54                   	push   %esp
  call trap
801051c7:	e8 e3 00 00 00       	call   801052af <trap>
  addl $4, %esp
801051cc:	83 c4 04             	add    $0x4,%esp

801051cf <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801051cf:	61                   	popa   
  popl %gs
801051d0:	0f a9                	pop    %gs
  popl %fs
801051d2:	0f a1                	pop    %fs
  popl %es
801051d4:	07                   	pop    %es
  popl %ds
801051d5:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801051d6:	83 c4 08             	add    $0x8,%esp
  iret
801051d9:	cf                   	iret   

801051da <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801051da:	55                   	push   %ebp
801051db:	89 e5                	mov    %esp,%ebp
801051dd:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
801051e0:	b8 00 00 00 00       	mov    $0x0,%eax
801051e5:	eb 4a                	jmp    80105231 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801051e7:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
801051ee:	66 89 0c c5 c0 4c 15 	mov    %cx,-0x7feab340(,%eax,8)
801051f5:	80 
801051f6:	66 c7 04 c5 c2 4c 15 	movw   $0x8,-0x7feab33e(,%eax,8)
801051fd:	80 08 00 
80105200:	c6 04 c5 c4 4c 15 80 	movb   $0x0,-0x7feab33c(,%eax,8)
80105207:	00 
80105208:	0f b6 14 c5 c5 4c 15 	movzbl -0x7feab33b(,%eax,8),%edx
8010520f:	80 
80105210:	83 e2 f0             	and    $0xfffffff0,%edx
80105213:	83 ca 0e             	or     $0xe,%edx
80105216:	83 e2 8f             	and    $0xffffff8f,%edx
80105219:	83 ca 80             	or     $0xffffff80,%edx
8010521c:	88 14 c5 c5 4c 15 80 	mov    %dl,-0x7feab33b(,%eax,8)
80105223:	c1 e9 10             	shr    $0x10,%ecx
80105226:	66 89 0c c5 c6 4c 15 	mov    %cx,-0x7feab33a(,%eax,8)
8010522d:	80 
  for(i = 0; i < 256; i++)
8010522e:	83 c0 01             	add    $0x1,%eax
80105231:	3d ff 00 00 00       	cmp    $0xff,%eax
80105236:	7e af                	jle    801051e7 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80105238:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
8010523e:	66 89 15 c0 4e 15 80 	mov    %dx,0x80154ec0
80105245:	66 c7 05 c2 4e 15 80 	movw   $0x8,0x80154ec2
8010524c:	08 00 
8010524e:	c6 05 c4 4e 15 80 00 	movb   $0x0,0x80154ec4
80105255:	0f b6 05 c5 4e 15 80 	movzbl 0x80154ec5,%eax
8010525c:	83 c8 0f             	or     $0xf,%eax
8010525f:	83 e0 ef             	and    $0xffffffef,%eax
80105262:	83 c8 e0             	or     $0xffffffe0,%eax
80105265:	a2 c5 4e 15 80       	mov    %al,0x80154ec5
8010526a:	c1 ea 10             	shr    $0x10,%edx
8010526d:	66 89 15 c6 4e 15 80 	mov    %dx,0x80154ec6

  initlock(&tickslock, "time");
80105274:	83 ec 08             	sub    $0x8,%esp
80105277:	68 dd 70 10 80       	push   $0x801070dd
8010527c:	68 80 4c 15 80       	push   $0x80154c80
80105281:	e8 4b ec ff ff       	call   80103ed1 <initlock>
}
80105286:	83 c4 10             	add    $0x10,%esp
80105289:	c9                   	leave  
8010528a:	c3                   	ret    

8010528b <idtinit>:

void
idtinit(void)
{
8010528b:	55                   	push   %ebp
8010528c:	89 e5                	mov    %esp,%ebp
8010528e:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80105291:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80105297:	b8 c0 4c 15 80       	mov    $0x80154cc0,%eax
8010529c:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801052a0:	c1 e8 10             	shr    $0x10,%eax
801052a3:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
801052a7:	8d 45 fa             	lea    -0x6(%ebp),%eax
801052aa:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
801052ad:	c9                   	leave  
801052ae:	c3                   	ret    

801052af <trap>:

void
trap(struct trapframe *tf)
{
801052af:	55                   	push   %ebp
801052b0:	89 e5                	mov    %esp,%ebp
801052b2:	57                   	push   %edi
801052b3:	56                   	push   %esi
801052b4:	53                   	push   %ebx
801052b5:	83 ec 1c             	sub    $0x1c,%esp
801052b8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
801052bb:	8b 43 30             	mov    0x30(%ebx),%eax
801052be:	83 f8 40             	cmp    $0x40,%eax
801052c1:	74 13                	je     801052d6 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
801052c3:	83 e8 20             	sub    $0x20,%eax
801052c6:	83 f8 1f             	cmp    $0x1f,%eax
801052c9:	0f 87 3a 01 00 00    	ja     80105409 <trap+0x15a>
801052cf:	ff 24 85 84 71 10 80 	jmp    *-0x7fef8e7c(,%eax,4)
    if(myproc()->killed)
801052d6:	e8 0f e3 ff ff       	call   801035ea <myproc>
801052db:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801052df:	75 1f                	jne    80105300 <trap+0x51>
    myproc()->tf = tf;
801052e1:	e8 04 e3 ff ff       	call   801035ea <myproc>
801052e6:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
801052e9:	e8 d9 f0 ff ff       	call   801043c7 <syscall>
    if(myproc()->killed)
801052ee:	e8 f7 e2 ff ff       	call   801035ea <myproc>
801052f3:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801052f7:	74 7e                	je     80105377 <trap+0xc8>
      exit();
801052f9:	e8 98 e6 ff ff       	call   80103996 <exit>
801052fe:	eb 77                	jmp    80105377 <trap+0xc8>
      exit();
80105300:	e8 91 e6 ff ff       	call   80103996 <exit>
80105305:	eb da                	jmp    801052e1 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80105307:	e8 c3 e2 ff ff       	call   801035cf <cpuid>
8010530c:	85 c0                	test   %eax,%eax
8010530e:	74 6f                	je     8010537f <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80105310:	e8 5f d4 ff ff       	call   80102774 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105315:	e8 d0 e2 ff ff       	call   801035ea <myproc>
8010531a:	85 c0                	test   %eax,%eax
8010531c:	74 1c                	je     8010533a <trap+0x8b>
8010531e:	e8 c7 e2 ff ff       	call   801035ea <myproc>
80105323:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105327:	74 11                	je     8010533a <trap+0x8b>
80105329:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
8010532d:	83 e0 03             	and    $0x3,%eax
80105330:	66 83 f8 03          	cmp    $0x3,%ax
80105334:	0f 84 62 01 00 00    	je     8010549c <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
8010533a:	e8 ab e2 ff ff       	call   801035ea <myproc>
8010533f:	85 c0                	test   %eax,%eax
80105341:	74 0f                	je     80105352 <trap+0xa3>
80105343:	e8 a2 e2 ff ff       	call   801035ea <myproc>
80105348:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
8010534c:	0f 84 54 01 00 00    	je     801054a6 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105352:	e8 93 e2 ff ff       	call   801035ea <myproc>
80105357:	85 c0                	test   %eax,%eax
80105359:	74 1c                	je     80105377 <trap+0xc8>
8010535b:	e8 8a e2 ff ff       	call   801035ea <myproc>
80105360:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105364:	74 11                	je     80105377 <trap+0xc8>
80105366:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
8010536a:	83 e0 03             	and    $0x3,%eax
8010536d:	66 83 f8 03          	cmp    $0x3,%ax
80105371:	0f 84 43 01 00 00    	je     801054ba <trap+0x20b>
    exit();
}
80105377:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010537a:	5b                   	pop    %ebx
8010537b:	5e                   	pop    %esi
8010537c:	5f                   	pop    %edi
8010537d:	5d                   	pop    %ebp
8010537e:	c3                   	ret    
      acquire(&tickslock);
8010537f:	83 ec 0c             	sub    $0xc,%esp
80105382:	68 80 4c 15 80       	push   $0x80154c80
80105387:	e8 81 ec ff ff       	call   8010400d <acquire>
      ticks++;
8010538c:	83 05 c0 54 15 80 01 	addl   $0x1,0x801554c0
      wakeup(&ticks);
80105393:	c7 04 24 c0 54 15 80 	movl   $0x801554c0,(%esp)
8010539a:	e8 54 e8 ff ff       	call   80103bf3 <wakeup>
      release(&tickslock);
8010539f:	c7 04 24 80 4c 15 80 	movl   $0x80154c80,(%esp)
801053a6:	e8 c7 ec ff ff       	call   80104072 <release>
801053ab:	83 c4 10             	add    $0x10,%esp
801053ae:	e9 5d ff ff ff       	jmp    80105310 <trap+0x61>
    ideintr();
801053b3:	e8 bb c9 ff ff       	call   80101d73 <ideintr>
    lapiceoi();
801053b8:	e8 b7 d3 ff ff       	call   80102774 <lapiceoi>
    break;
801053bd:	e9 53 ff ff ff       	jmp    80105315 <trap+0x66>
    kbdintr();
801053c2:	e8 f1 d1 ff ff       	call   801025b8 <kbdintr>
    lapiceoi();
801053c7:	e8 a8 d3 ff ff       	call   80102774 <lapiceoi>
    break;
801053cc:	e9 44 ff ff ff       	jmp    80105315 <trap+0x66>
    uartintr();
801053d1:	e8 05 02 00 00       	call   801055db <uartintr>
    lapiceoi();
801053d6:	e8 99 d3 ff ff       	call   80102774 <lapiceoi>
    break;
801053db:	e9 35 ff ff ff       	jmp    80105315 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801053e0:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
801053e3:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801053e7:	e8 e3 e1 ff ff       	call   801035cf <cpuid>
801053ec:	57                   	push   %edi
801053ed:	0f b7 f6             	movzwl %si,%esi
801053f0:	56                   	push   %esi
801053f1:	50                   	push   %eax
801053f2:	68 e8 70 10 80       	push   $0x801070e8
801053f7:	e8 0f b2 ff ff       	call   8010060b <cprintf>
    lapiceoi();
801053fc:	e8 73 d3 ff ff       	call   80102774 <lapiceoi>
    break;
80105401:	83 c4 10             	add    $0x10,%esp
80105404:	e9 0c ff ff ff       	jmp    80105315 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
80105409:	e8 dc e1 ff ff       	call   801035ea <myproc>
8010540e:	85 c0                	test   %eax,%eax
80105410:	74 5f                	je     80105471 <trap+0x1c2>
80105412:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80105416:	74 59                	je     80105471 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80105418:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010541b:	8b 43 38             	mov    0x38(%ebx),%eax
8010541e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105421:	e8 a9 e1 ff ff       	call   801035cf <cpuid>
80105426:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105429:	8b 53 34             	mov    0x34(%ebx),%edx
8010542c:	89 55 dc             	mov    %edx,-0x24(%ebp)
8010542f:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
80105432:	e8 b3 e1 ff ff       	call   801035ea <myproc>
80105437:	8d 48 6c             	lea    0x6c(%eax),%ecx
8010543a:	89 4d d8             	mov    %ecx,-0x28(%ebp)
8010543d:	e8 a8 e1 ff ff       	call   801035ea <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105442:	57                   	push   %edi
80105443:	ff 75 e4             	pushl  -0x1c(%ebp)
80105446:	ff 75 e0             	pushl  -0x20(%ebp)
80105449:	ff 75 dc             	pushl  -0x24(%ebp)
8010544c:	56                   	push   %esi
8010544d:	ff 75 d8             	pushl  -0x28(%ebp)
80105450:	ff 70 10             	pushl  0x10(%eax)
80105453:	68 40 71 10 80       	push   $0x80107140
80105458:	e8 ae b1 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
8010545d:	83 c4 20             	add    $0x20,%esp
80105460:	e8 85 e1 ff ff       	call   801035ea <myproc>
80105465:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010546c:	e9 a4 fe ff ff       	jmp    80105315 <trap+0x66>
80105471:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80105474:	8b 73 38             	mov    0x38(%ebx),%esi
80105477:	e8 53 e1 ff ff       	call   801035cf <cpuid>
8010547c:	83 ec 0c             	sub    $0xc,%esp
8010547f:	57                   	push   %edi
80105480:	56                   	push   %esi
80105481:	50                   	push   %eax
80105482:	ff 73 30             	pushl  0x30(%ebx)
80105485:	68 0c 71 10 80       	push   $0x8010710c
8010548a:	e8 7c b1 ff ff       	call   8010060b <cprintf>
      panic("trap");
8010548f:	83 c4 14             	add    $0x14,%esp
80105492:	68 e2 70 10 80       	push   $0x801070e2
80105497:	e8 ac ae ff ff       	call   80100348 <panic>
    exit();
8010549c:	e8 f5 e4 ff ff       	call   80103996 <exit>
801054a1:	e9 94 fe ff ff       	jmp    8010533a <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
801054a6:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
801054aa:	0f 85 a2 fe ff ff    	jne    80105352 <trap+0xa3>
    yield();
801054b0:	e8 a7 e5 ff ff       	call   80103a5c <yield>
801054b5:	e9 98 fe ff ff       	jmp    80105352 <trap+0xa3>
    exit();
801054ba:	e8 d7 e4 ff ff       	call   80103996 <exit>
801054bf:	e9 b3 fe ff ff       	jmp    80105377 <trap+0xc8>

801054c4 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
801054c4:	55                   	push   %ebp
801054c5:	89 e5                	mov    %esp,%ebp
  if(!uart)
801054c7:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
801054ce:	74 15                	je     801054e5 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801054d0:	ba fd 03 00 00       	mov    $0x3fd,%edx
801054d5:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
801054d6:	a8 01                	test   $0x1,%al
801054d8:	74 12                	je     801054ec <uartgetc+0x28>
801054da:	ba f8 03 00 00       	mov    $0x3f8,%edx
801054df:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
801054e0:	0f b6 c0             	movzbl %al,%eax
}
801054e3:	5d                   	pop    %ebp
801054e4:	c3                   	ret    
    return -1;
801054e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054ea:	eb f7                	jmp    801054e3 <uartgetc+0x1f>
    return -1;
801054ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054f1:	eb f0                	jmp    801054e3 <uartgetc+0x1f>

801054f3 <uartputc>:
  if(!uart)
801054f3:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
801054fa:	74 3b                	je     80105537 <uartputc+0x44>
{
801054fc:	55                   	push   %ebp
801054fd:	89 e5                	mov    %esp,%ebp
801054ff:	53                   	push   %ebx
80105500:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105503:	bb 00 00 00 00       	mov    $0x0,%ebx
80105508:	eb 10                	jmp    8010551a <uartputc+0x27>
    microdelay(10);
8010550a:	83 ec 0c             	sub    $0xc,%esp
8010550d:	6a 0a                	push   $0xa
8010550f:	e8 7f d2 ff ff       	call   80102793 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105514:	83 c3 01             	add    $0x1,%ebx
80105517:	83 c4 10             	add    $0x10,%esp
8010551a:	83 fb 7f             	cmp    $0x7f,%ebx
8010551d:	7f 0a                	jg     80105529 <uartputc+0x36>
8010551f:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105524:	ec                   	in     (%dx),%al
80105525:	a8 20                	test   $0x20,%al
80105527:	74 e1                	je     8010550a <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80105529:	8b 45 08             	mov    0x8(%ebp),%eax
8010552c:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105531:	ee                   	out    %al,(%dx)
}
80105532:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105535:	c9                   	leave  
80105536:	c3                   	ret    
80105537:	f3 c3                	repz ret 

80105539 <uartinit>:
{
80105539:	55                   	push   %ebp
8010553a:	89 e5                	mov    %esp,%ebp
8010553c:	56                   	push   %esi
8010553d:	53                   	push   %ebx
8010553e:	b9 00 00 00 00       	mov    $0x0,%ecx
80105543:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105548:	89 c8                	mov    %ecx,%eax
8010554a:	ee                   	out    %al,(%dx)
8010554b:	be fb 03 00 00       	mov    $0x3fb,%esi
80105550:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80105555:	89 f2                	mov    %esi,%edx
80105557:	ee                   	out    %al,(%dx)
80105558:	b8 0c 00 00 00       	mov    $0xc,%eax
8010555d:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105562:	ee                   	out    %al,(%dx)
80105563:	bb f9 03 00 00       	mov    $0x3f9,%ebx
80105568:	89 c8                	mov    %ecx,%eax
8010556a:	89 da                	mov    %ebx,%edx
8010556c:	ee                   	out    %al,(%dx)
8010556d:	b8 03 00 00 00       	mov    $0x3,%eax
80105572:	89 f2                	mov    %esi,%edx
80105574:	ee                   	out    %al,(%dx)
80105575:	ba fc 03 00 00       	mov    $0x3fc,%edx
8010557a:	89 c8                	mov    %ecx,%eax
8010557c:	ee                   	out    %al,(%dx)
8010557d:	b8 01 00 00 00       	mov    $0x1,%eax
80105582:	89 da                	mov    %ebx,%edx
80105584:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105585:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010558a:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
8010558b:	3c ff                	cmp    $0xff,%al
8010558d:	74 45                	je     801055d4 <uartinit+0x9b>
  uart = 1;
8010558f:	c7 05 bc a5 10 80 01 	movl   $0x1,0x8010a5bc
80105596:	00 00 00 
80105599:	ba fa 03 00 00       	mov    $0x3fa,%edx
8010559e:	ec                   	in     (%dx),%al
8010559f:	ba f8 03 00 00       	mov    $0x3f8,%edx
801055a4:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
801055a5:	83 ec 08             	sub    $0x8,%esp
801055a8:	6a 00                	push   $0x0
801055aa:	6a 04                	push   $0x4
801055ac:	e8 cd c9 ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
801055b1:	83 c4 10             	add    $0x10,%esp
801055b4:	bb 04 72 10 80       	mov    $0x80107204,%ebx
801055b9:	eb 12                	jmp    801055cd <uartinit+0x94>
    uartputc(*p);
801055bb:	83 ec 0c             	sub    $0xc,%esp
801055be:	0f be c0             	movsbl %al,%eax
801055c1:	50                   	push   %eax
801055c2:	e8 2c ff ff ff       	call   801054f3 <uartputc>
  for(p="xv6...\n"; *p; p++)
801055c7:	83 c3 01             	add    $0x1,%ebx
801055ca:	83 c4 10             	add    $0x10,%esp
801055cd:	0f b6 03             	movzbl (%ebx),%eax
801055d0:	84 c0                	test   %al,%al
801055d2:	75 e7                	jne    801055bb <uartinit+0x82>
}
801055d4:	8d 65 f8             	lea    -0x8(%ebp),%esp
801055d7:	5b                   	pop    %ebx
801055d8:	5e                   	pop    %esi
801055d9:	5d                   	pop    %ebp
801055da:	c3                   	ret    

801055db <uartintr>:

void
uartintr(void)
{
801055db:	55                   	push   %ebp
801055dc:	89 e5                	mov    %esp,%ebp
801055de:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
801055e1:	68 c4 54 10 80       	push   $0x801054c4
801055e6:	e8 53 b1 ff ff       	call   8010073e <consoleintr>
}
801055eb:	83 c4 10             	add    $0x10,%esp
801055ee:	c9                   	leave  
801055ef:	c3                   	ret    

801055f0 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801055f0:	6a 00                	push   $0x0
  pushl $0
801055f2:	6a 00                	push   $0x0
  jmp alltraps
801055f4:	e9 be fb ff ff       	jmp    801051b7 <alltraps>

801055f9 <vector1>:
.globl vector1
vector1:
  pushl $0
801055f9:	6a 00                	push   $0x0
  pushl $1
801055fb:	6a 01                	push   $0x1
  jmp alltraps
801055fd:	e9 b5 fb ff ff       	jmp    801051b7 <alltraps>

80105602 <vector2>:
.globl vector2
vector2:
  pushl $0
80105602:	6a 00                	push   $0x0
  pushl $2
80105604:	6a 02                	push   $0x2
  jmp alltraps
80105606:	e9 ac fb ff ff       	jmp    801051b7 <alltraps>

8010560b <vector3>:
.globl vector3
vector3:
  pushl $0
8010560b:	6a 00                	push   $0x0
  pushl $3
8010560d:	6a 03                	push   $0x3
  jmp alltraps
8010560f:	e9 a3 fb ff ff       	jmp    801051b7 <alltraps>

80105614 <vector4>:
.globl vector4
vector4:
  pushl $0
80105614:	6a 00                	push   $0x0
  pushl $4
80105616:	6a 04                	push   $0x4
  jmp alltraps
80105618:	e9 9a fb ff ff       	jmp    801051b7 <alltraps>

8010561d <vector5>:
.globl vector5
vector5:
  pushl $0
8010561d:	6a 00                	push   $0x0
  pushl $5
8010561f:	6a 05                	push   $0x5
  jmp alltraps
80105621:	e9 91 fb ff ff       	jmp    801051b7 <alltraps>

80105626 <vector6>:
.globl vector6
vector6:
  pushl $0
80105626:	6a 00                	push   $0x0
  pushl $6
80105628:	6a 06                	push   $0x6
  jmp alltraps
8010562a:	e9 88 fb ff ff       	jmp    801051b7 <alltraps>

8010562f <vector7>:
.globl vector7
vector7:
  pushl $0
8010562f:	6a 00                	push   $0x0
  pushl $7
80105631:	6a 07                	push   $0x7
  jmp alltraps
80105633:	e9 7f fb ff ff       	jmp    801051b7 <alltraps>

80105638 <vector8>:
.globl vector8
vector8:
  pushl $8
80105638:	6a 08                	push   $0x8
  jmp alltraps
8010563a:	e9 78 fb ff ff       	jmp    801051b7 <alltraps>

8010563f <vector9>:
.globl vector9
vector9:
  pushl $0
8010563f:	6a 00                	push   $0x0
  pushl $9
80105641:	6a 09                	push   $0x9
  jmp alltraps
80105643:	e9 6f fb ff ff       	jmp    801051b7 <alltraps>

80105648 <vector10>:
.globl vector10
vector10:
  pushl $10
80105648:	6a 0a                	push   $0xa
  jmp alltraps
8010564a:	e9 68 fb ff ff       	jmp    801051b7 <alltraps>

8010564f <vector11>:
.globl vector11
vector11:
  pushl $11
8010564f:	6a 0b                	push   $0xb
  jmp alltraps
80105651:	e9 61 fb ff ff       	jmp    801051b7 <alltraps>

80105656 <vector12>:
.globl vector12
vector12:
  pushl $12
80105656:	6a 0c                	push   $0xc
  jmp alltraps
80105658:	e9 5a fb ff ff       	jmp    801051b7 <alltraps>

8010565d <vector13>:
.globl vector13
vector13:
  pushl $13
8010565d:	6a 0d                	push   $0xd
  jmp alltraps
8010565f:	e9 53 fb ff ff       	jmp    801051b7 <alltraps>

80105664 <vector14>:
.globl vector14
vector14:
  pushl $14
80105664:	6a 0e                	push   $0xe
  jmp alltraps
80105666:	e9 4c fb ff ff       	jmp    801051b7 <alltraps>

8010566b <vector15>:
.globl vector15
vector15:
  pushl $0
8010566b:	6a 00                	push   $0x0
  pushl $15
8010566d:	6a 0f                	push   $0xf
  jmp alltraps
8010566f:	e9 43 fb ff ff       	jmp    801051b7 <alltraps>

80105674 <vector16>:
.globl vector16
vector16:
  pushl $0
80105674:	6a 00                	push   $0x0
  pushl $16
80105676:	6a 10                	push   $0x10
  jmp alltraps
80105678:	e9 3a fb ff ff       	jmp    801051b7 <alltraps>

8010567d <vector17>:
.globl vector17
vector17:
  pushl $17
8010567d:	6a 11                	push   $0x11
  jmp alltraps
8010567f:	e9 33 fb ff ff       	jmp    801051b7 <alltraps>

80105684 <vector18>:
.globl vector18
vector18:
  pushl $0
80105684:	6a 00                	push   $0x0
  pushl $18
80105686:	6a 12                	push   $0x12
  jmp alltraps
80105688:	e9 2a fb ff ff       	jmp    801051b7 <alltraps>

8010568d <vector19>:
.globl vector19
vector19:
  pushl $0
8010568d:	6a 00                	push   $0x0
  pushl $19
8010568f:	6a 13                	push   $0x13
  jmp alltraps
80105691:	e9 21 fb ff ff       	jmp    801051b7 <alltraps>

80105696 <vector20>:
.globl vector20
vector20:
  pushl $0
80105696:	6a 00                	push   $0x0
  pushl $20
80105698:	6a 14                	push   $0x14
  jmp alltraps
8010569a:	e9 18 fb ff ff       	jmp    801051b7 <alltraps>

8010569f <vector21>:
.globl vector21
vector21:
  pushl $0
8010569f:	6a 00                	push   $0x0
  pushl $21
801056a1:	6a 15                	push   $0x15
  jmp alltraps
801056a3:	e9 0f fb ff ff       	jmp    801051b7 <alltraps>

801056a8 <vector22>:
.globl vector22
vector22:
  pushl $0
801056a8:	6a 00                	push   $0x0
  pushl $22
801056aa:	6a 16                	push   $0x16
  jmp alltraps
801056ac:	e9 06 fb ff ff       	jmp    801051b7 <alltraps>

801056b1 <vector23>:
.globl vector23
vector23:
  pushl $0
801056b1:	6a 00                	push   $0x0
  pushl $23
801056b3:	6a 17                	push   $0x17
  jmp alltraps
801056b5:	e9 fd fa ff ff       	jmp    801051b7 <alltraps>

801056ba <vector24>:
.globl vector24
vector24:
  pushl $0
801056ba:	6a 00                	push   $0x0
  pushl $24
801056bc:	6a 18                	push   $0x18
  jmp alltraps
801056be:	e9 f4 fa ff ff       	jmp    801051b7 <alltraps>

801056c3 <vector25>:
.globl vector25
vector25:
  pushl $0
801056c3:	6a 00                	push   $0x0
  pushl $25
801056c5:	6a 19                	push   $0x19
  jmp alltraps
801056c7:	e9 eb fa ff ff       	jmp    801051b7 <alltraps>

801056cc <vector26>:
.globl vector26
vector26:
  pushl $0
801056cc:	6a 00                	push   $0x0
  pushl $26
801056ce:	6a 1a                	push   $0x1a
  jmp alltraps
801056d0:	e9 e2 fa ff ff       	jmp    801051b7 <alltraps>

801056d5 <vector27>:
.globl vector27
vector27:
  pushl $0
801056d5:	6a 00                	push   $0x0
  pushl $27
801056d7:	6a 1b                	push   $0x1b
  jmp alltraps
801056d9:	e9 d9 fa ff ff       	jmp    801051b7 <alltraps>

801056de <vector28>:
.globl vector28
vector28:
  pushl $0
801056de:	6a 00                	push   $0x0
  pushl $28
801056e0:	6a 1c                	push   $0x1c
  jmp alltraps
801056e2:	e9 d0 fa ff ff       	jmp    801051b7 <alltraps>

801056e7 <vector29>:
.globl vector29
vector29:
  pushl $0
801056e7:	6a 00                	push   $0x0
  pushl $29
801056e9:	6a 1d                	push   $0x1d
  jmp alltraps
801056eb:	e9 c7 fa ff ff       	jmp    801051b7 <alltraps>

801056f0 <vector30>:
.globl vector30
vector30:
  pushl $0
801056f0:	6a 00                	push   $0x0
  pushl $30
801056f2:	6a 1e                	push   $0x1e
  jmp alltraps
801056f4:	e9 be fa ff ff       	jmp    801051b7 <alltraps>

801056f9 <vector31>:
.globl vector31
vector31:
  pushl $0
801056f9:	6a 00                	push   $0x0
  pushl $31
801056fb:	6a 1f                	push   $0x1f
  jmp alltraps
801056fd:	e9 b5 fa ff ff       	jmp    801051b7 <alltraps>

80105702 <vector32>:
.globl vector32
vector32:
  pushl $0
80105702:	6a 00                	push   $0x0
  pushl $32
80105704:	6a 20                	push   $0x20
  jmp alltraps
80105706:	e9 ac fa ff ff       	jmp    801051b7 <alltraps>

8010570b <vector33>:
.globl vector33
vector33:
  pushl $0
8010570b:	6a 00                	push   $0x0
  pushl $33
8010570d:	6a 21                	push   $0x21
  jmp alltraps
8010570f:	e9 a3 fa ff ff       	jmp    801051b7 <alltraps>

80105714 <vector34>:
.globl vector34
vector34:
  pushl $0
80105714:	6a 00                	push   $0x0
  pushl $34
80105716:	6a 22                	push   $0x22
  jmp alltraps
80105718:	e9 9a fa ff ff       	jmp    801051b7 <alltraps>

8010571d <vector35>:
.globl vector35
vector35:
  pushl $0
8010571d:	6a 00                	push   $0x0
  pushl $35
8010571f:	6a 23                	push   $0x23
  jmp alltraps
80105721:	e9 91 fa ff ff       	jmp    801051b7 <alltraps>

80105726 <vector36>:
.globl vector36
vector36:
  pushl $0
80105726:	6a 00                	push   $0x0
  pushl $36
80105728:	6a 24                	push   $0x24
  jmp alltraps
8010572a:	e9 88 fa ff ff       	jmp    801051b7 <alltraps>

8010572f <vector37>:
.globl vector37
vector37:
  pushl $0
8010572f:	6a 00                	push   $0x0
  pushl $37
80105731:	6a 25                	push   $0x25
  jmp alltraps
80105733:	e9 7f fa ff ff       	jmp    801051b7 <alltraps>

80105738 <vector38>:
.globl vector38
vector38:
  pushl $0
80105738:	6a 00                	push   $0x0
  pushl $38
8010573a:	6a 26                	push   $0x26
  jmp alltraps
8010573c:	e9 76 fa ff ff       	jmp    801051b7 <alltraps>

80105741 <vector39>:
.globl vector39
vector39:
  pushl $0
80105741:	6a 00                	push   $0x0
  pushl $39
80105743:	6a 27                	push   $0x27
  jmp alltraps
80105745:	e9 6d fa ff ff       	jmp    801051b7 <alltraps>

8010574a <vector40>:
.globl vector40
vector40:
  pushl $0
8010574a:	6a 00                	push   $0x0
  pushl $40
8010574c:	6a 28                	push   $0x28
  jmp alltraps
8010574e:	e9 64 fa ff ff       	jmp    801051b7 <alltraps>

80105753 <vector41>:
.globl vector41
vector41:
  pushl $0
80105753:	6a 00                	push   $0x0
  pushl $41
80105755:	6a 29                	push   $0x29
  jmp alltraps
80105757:	e9 5b fa ff ff       	jmp    801051b7 <alltraps>

8010575c <vector42>:
.globl vector42
vector42:
  pushl $0
8010575c:	6a 00                	push   $0x0
  pushl $42
8010575e:	6a 2a                	push   $0x2a
  jmp alltraps
80105760:	e9 52 fa ff ff       	jmp    801051b7 <alltraps>

80105765 <vector43>:
.globl vector43
vector43:
  pushl $0
80105765:	6a 00                	push   $0x0
  pushl $43
80105767:	6a 2b                	push   $0x2b
  jmp alltraps
80105769:	e9 49 fa ff ff       	jmp    801051b7 <alltraps>

8010576e <vector44>:
.globl vector44
vector44:
  pushl $0
8010576e:	6a 00                	push   $0x0
  pushl $44
80105770:	6a 2c                	push   $0x2c
  jmp alltraps
80105772:	e9 40 fa ff ff       	jmp    801051b7 <alltraps>

80105777 <vector45>:
.globl vector45
vector45:
  pushl $0
80105777:	6a 00                	push   $0x0
  pushl $45
80105779:	6a 2d                	push   $0x2d
  jmp alltraps
8010577b:	e9 37 fa ff ff       	jmp    801051b7 <alltraps>

80105780 <vector46>:
.globl vector46
vector46:
  pushl $0
80105780:	6a 00                	push   $0x0
  pushl $46
80105782:	6a 2e                	push   $0x2e
  jmp alltraps
80105784:	e9 2e fa ff ff       	jmp    801051b7 <alltraps>

80105789 <vector47>:
.globl vector47
vector47:
  pushl $0
80105789:	6a 00                	push   $0x0
  pushl $47
8010578b:	6a 2f                	push   $0x2f
  jmp alltraps
8010578d:	e9 25 fa ff ff       	jmp    801051b7 <alltraps>

80105792 <vector48>:
.globl vector48
vector48:
  pushl $0
80105792:	6a 00                	push   $0x0
  pushl $48
80105794:	6a 30                	push   $0x30
  jmp alltraps
80105796:	e9 1c fa ff ff       	jmp    801051b7 <alltraps>

8010579b <vector49>:
.globl vector49
vector49:
  pushl $0
8010579b:	6a 00                	push   $0x0
  pushl $49
8010579d:	6a 31                	push   $0x31
  jmp alltraps
8010579f:	e9 13 fa ff ff       	jmp    801051b7 <alltraps>

801057a4 <vector50>:
.globl vector50
vector50:
  pushl $0
801057a4:	6a 00                	push   $0x0
  pushl $50
801057a6:	6a 32                	push   $0x32
  jmp alltraps
801057a8:	e9 0a fa ff ff       	jmp    801051b7 <alltraps>

801057ad <vector51>:
.globl vector51
vector51:
  pushl $0
801057ad:	6a 00                	push   $0x0
  pushl $51
801057af:	6a 33                	push   $0x33
  jmp alltraps
801057b1:	e9 01 fa ff ff       	jmp    801051b7 <alltraps>

801057b6 <vector52>:
.globl vector52
vector52:
  pushl $0
801057b6:	6a 00                	push   $0x0
  pushl $52
801057b8:	6a 34                	push   $0x34
  jmp alltraps
801057ba:	e9 f8 f9 ff ff       	jmp    801051b7 <alltraps>

801057bf <vector53>:
.globl vector53
vector53:
  pushl $0
801057bf:	6a 00                	push   $0x0
  pushl $53
801057c1:	6a 35                	push   $0x35
  jmp alltraps
801057c3:	e9 ef f9 ff ff       	jmp    801051b7 <alltraps>

801057c8 <vector54>:
.globl vector54
vector54:
  pushl $0
801057c8:	6a 00                	push   $0x0
  pushl $54
801057ca:	6a 36                	push   $0x36
  jmp alltraps
801057cc:	e9 e6 f9 ff ff       	jmp    801051b7 <alltraps>

801057d1 <vector55>:
.globl vector55
vector55:
  pushl $0
801057d1:	6a 00                	push   $0x0
  pushl $55
801057d3:	6a 37                	push   $0x37
  jmp alltraps
801057d5:	e9 dd f9 ff ff       	jmp    801051b7 <alltraps>

801057da <vector56>:
.globl vector56
vector56:
  pushl $0
801057da:	6a 00                	push   $0x0
  pushl $56
801057dc:	6a 38                	push   $0x38
  jmp alltraps
801057de:	e9 d4 f9 ff ff       	jmp    801051b7 <alltraps>

801057e3 <vector57>:
.globl vector57
vector57:
  pushl $0
801057e3:	6a 00                	push   $0x0
  pushl $57
801057e5:	6a 39                	push   $0x39
  jmp alltraps
801057e7:	e9 cb f9 ff ff       	jmp    801051b7 <alltraps>

801057ec <vector58>:
.globl vector58
vector58:
  pushl $0
801057ec:	6a 00                	push   $0x0
  pushl $58
801057ee:	6a 3a                	push   $0x3a
  jmp alltraps
801057f0:	e9 c2 f9 ff ff       	jmp    801051b7 <alltraps>

801057f5 <vector59>:
.globl vector59
vector59:
  pushl $0
801057f5:	6a 00                	push   $0x0
  pushl $59
801057f7:	6a 3b                	push   $0x3b
  jmp alltraps
801057f9:	e9 b9 f9 ff ff       	jmp    801051b7 <alltraps>

801057fe <vector60>:
.globl vector60
vector60:
  pushl $0
801057fe:	6a 00                	push   $0x0
  pushl $60
80105800:	6a 3c                	push   $0x3c
  jmp alltraps
80105802:	e9 b0 f9 ff ff       	jmp    801051b7 <alltraps>

80105807 <vector61>:
.globl vector61
vector61:
  pushl $0
80105807:	6a 00                	push   $0x0
  pushl $61
80105809:	6a 3d                	push   $0x3d
  jmp alltraps
8010580b:	e9 a7 f9 ff ff       	jmp    801051b7 <alltraps>

80105810 <vector62>:
.globl vector62
vector62:
  pushl $0
80105810:	6a 00                	push   $0x0
  pushl $62
80105812:	6a 3e                	push   $0x3e
  jmp alltraps
80105814:	e9 9e f9 ff ff       	jmp    801051b7 <alltraps>

80105819 <vector63>:
.globl vector63
vector63:
  pushl $0
80105819:	6a 00                	push   $0x0
  pushl $63
8010581b:	6a 3f                	push   $0x3f
  jmp alltraps
8010581d:	e9 95 f9 ff ff       	jmp    801051b7 <alltraps>

80105822 <vector64>:
.globl vector64
vector64:
  pushl $0
80105822:	6a 00                	push   $0x0
  pushl $64
80105824:	6a 40                	push   $0x40
  jmp alltraps
80105826:	e9 8c f9 ff ff       	jmp    801051b7 <alltraps>

8010582b <vector65>:
.globl vector65
vector65:
  pushl $0
8010582b:	6a 00                	push   $0x0
  pushl $65
8010582d:	6a 41                	push   $0x41
  jmp alltraps
8010582f:	e9 83 f9 ff ff       	jmp    801051b7 <alltraps>

80105834 <vector66>:
.globl vector66
vector66:
  pushl $0
80105834:	6a 00                	push   $0x0
  pushl $66
80105836:	6a 42                	push   $0x42
  jmp alltraps
80105838:	e9 7a f9 ff ff       	jmp    801051b7 <alltraps>

8010583d <vector67>:
.globl vector67
vector67:
  pushl $0
8010583d:	6a 00                	push   $0x0
  pushl $67
8010583f:	6a 43                	push   $0x43
  jmp alltraps
80105841:	e9 71 f9 ff ff       	jmp    801051b7 <alltraps>

80105846 <vector68>:
.globl vector68
vector68:
  pushl $0
80105846:	6a 00                	push   $0x0
  pushl $68
80105848:	6a 44                	push   $0x44
  jmp alltraps
8010584a:	e9 68 f9 ff ff       	jmp    801051b7 <alltraps>

8010584f <vector69>:
.globl vector69
vector69:
  pushl $0
8010584f:	6a 00                	push   $0x0
  pushl $69
80105851:	6a 45                	push   $0x45
  jmp alltraps
80105853:	e9 5f f9 ff ff       	jmp    801051b7 <alltraps>

80105858 <vector70>:
.globl vector70
vector70:
  pushl $0
80105858:	6a 00                	push   $0x0
  pushl $70
8010585a:	6a 46                	push   $0x46
  jmp alltraps
8010585c:	e9 56 f9 ff ff       	jmp    801051b7 <alltraps>

80105861 <vector71>:
.globl vector71
vector71:
  pushl $0
80105861:	6a 00                	push   $0x0
  pushl $71
80105863:	6a 47                	push   $0x47
  jmp alltraps
80105865:	e9 4d f9 ff ff       	jmp    801051b7 <alltraps>

8010586a <vector72>:
.globl vector72
vector72:
  pushl $0
8010586a:	6a 00                	push   $0x0
  pushl $72
8010586c:	6a 48                	push   $0x48
  jmp alltraps
8010586e:	e9 44 f9 ff ff       	jmp    801051b7 <alltraps>

80105873 <vector73>:
.globl vector73
vector73:
  pushl $0
80105873:	6a 00                	push   $0x0
  pushl $73
80105875:	6a 49                	push   $0x49
  jmp alltraps
80105877:	e9 3b f9 ff ff       	jmp    801051b7 <alltraps>

8010587c <vector74>:
.globl vector74
vector74:
  pushl $0
8010587c:	6a 00                	push   $0x0
  pushl $74
8010587e:	6a 4a                	push   $0x4a
  jmp alltraps
80105880:	e9 32 f9 ff ff       	jmp    801051b7 <alltraps>

80105885 <vector75>:
.globl vector75
vector75:
  pushl $0
80105885:	6a 00                	push   $0x0
  pushl $75
80105887:	6a 4b                	push   $0x4b
  jmp alltraps
80105889:	e9 29 f9 ff ff       	jmp    801051b7 <alltraps>

8010588e <vector76>:
.globl vector76
vector76:
  pushl $0
8010588e:	6a 00                	push   $0x0
  pushl $76
80105890:	6a 4c                	push   $0x4c
  jmp alltraps
80105892:	e9 20 f9 ff ff       	jmp    801051b7 <alltraps>

80105897 <vector77>:
.globl vector77
vector77:
  pushl $0
80105897:	6a 00                	push   $0x0
  pushl $77
80105899:	6a 4d                	push   $0x4d
  jmp alltraps
8010589b:	e9 17 f9 ff ff       	jmp    801051b7 <alltraps>

801058a0 <vector78>:
.globl vector78
vector78:
  pushl $0
801058a0:	6a 00                	push   $0x0
  pushl $78
801058a2:	6a 4e                	push   $0x4e
  jmp alltraps
801058a4:	e9 0e f9 ff ff       	jmp    801051b7 <alltraps>

801058a9 <vector79>:
.globl vector79
vector79:
  pushl $0
801058a9:	6a 00                	push   $0x0
  pushl $79
801058ab:	6a 4f                	push   $0x4f
  jmp alltraps
801058ad:	e9 05 f9 ff ff       	jmp    801051b7 <alltraps>

801058b2 <vector80>:
.globl vector80
vector80:
  pushl $0
801058b2:	6a 00                	push   $0x0
  pushl $80
801058b4:	6a 50                	push   $0x50
  jmp alltraps
801058b6:	e9 fc f8 ff ff       	jmp    801051b7 <alltraps>

801058bb <vector81>:
.globl vector81
vector81:
  pushl $0
801058bb:	6a 00                	push   $0x0
  pushl $81
801058bd:	6a 51                	push   $0x51
  jmp alltraps
801058bf:	e9 f3 f8 ff ff       	jmp    801051b7 <alltraps>

801058c4 <vector82>:
.globl vector82
vector82:
  pushl $0
801058c4:	6a 00                	push   $0x0
  pushl $82
801058c6:	6a 52                	push   $0x52
  jmp alltraps
801058c8:	e9 ea f8 ff ff       	jmp    801051b7 <alltraps>

801058cd <vector83>:
.globl vector83
vector83:
  pushl $0
801058cd:	6a 00                	push   $0x0
  pushl $83
801058cf:	6a 53                	push   $0x53
  jmp alltraps
801058d1:	e9 e1 f8 ff ff       	jmp    801051b7 <alltraps>

801058d6 <vector84>:
.globl vector84
vector84:
  pushl $0
801058d6:	6a 00                	push   $0x0
  pushl $84
801058d8:	6a 54                	push   $0x54
  jmp alltraps
801058da:	e9 d8 f8 ff ff       	jmp    801051b7 <alltraps>

801058df <vector85>:
.globl vector85
vector85:
  pushl $0
801058df:	6a 00                	push   $0x0
  pushl $85
801058e1:	6a 55                	push   $0x55
  jmp alltraps
801058e3:	e9 cf f8 ff ff       	jmp    801051b7 <alltraps>

801058e8 <vector86>:
.globl vector86
vector86:
  pushl $0
801058e8:	6a 00                	push   $0x0
  pushl $86
801058ea:	6a 56                	push   $0x56
  jmp alltraps
801058ec:	e9 c6 f8 ff ff       	jmp    801051b7 <alltraps>

801058f1 <vector87>:
.globl vector87
vector87:
  pushl $0
801058f1:	6a 00                	push   $0x0
  pushl $87
801058f3:	6a 57                	push   $0x57
  jmp alltraps
801058f5:	e9 bd f8 ff ff       	jmp    801051b7 <alltraps>

801058fa <vector88>:
.globl vector88
vector88:
  pushl $0
801058fa:	6a 00                	push   $0x0
  pushl $88
801058fc:	6a 58                	push   $0x58
  jmp alltraps
801058fe:	e9 b4 f8 ff ff       	jmp    801051b7 <alltraps>

80105903 <vector89>:
.globl vector89
vector89:
  pushl $0
80105903:	6a 00                	push   $0x0
  pushl $89
80105905:	6a 59                	push   $0x59
  jmp alltraps
80105907:	e9 ab f8 ff ff       	jmp    801051b7 <alltraps>

8010590c <vector90>:
.globl vector90
vector90:
  pushl $0
8010590c:	6a 00                	push   $0x0
  pushl $90
8010590e:	6a 5a                	push   $0x5a
  jmp alltraps
80105910:	e9 a2 f8 ff ff       	jmp    801051b7 <alltraps>

80105915 <vector91>:
.globl vector91
vector91:
  pushl $0
80105915:	6a 00                	push   $0x0
  pushl $91
80105917:	6a 5b                	push   $0x5b
  jmp alltraps
80105919:	e9 99 f8 ff ff       	jmp    801051b7 <alltraps>

8010591e <vector92>:
.globl vector92
vector92:
  pushl $0
8010591e:	6a 00                	push   $0x0
  pushl $92
80105920:	6a 5c                	push   $0x5c
  jmp alltraps
80105922:	e9 90 f8 ff ff       	jmp    801051b7 <alltraps>

80105927 <vector93>:
.globl vector93
vector93:
  pushl $0
80105927:	6a 00                	push   $0x0
  pushl $93
80105929:	6a 5d                	push   $0x5d
  jmp alltraps
8010592b:	e9 87 f8 ff ff       	jmp    801051b7 <alltraps>

80105930 <vector94>:
.globl vector94
vector94:
  pushl $0
80105930:	6a 00                	push   $0x0
  pushl $94
80105932:	6a 5e                	push   $0x5e
  jmp alltraps
80105934:	e9 7e f8 ff ff       	jmp    801051b7 <alltraps>

80105939 <vector95>:
.globl vector95
vector95:
  pushl $0
80105939:	6a 00                	push   $0x0
  pushl $95
8010593b:	6a 5f                	push   $0x5f
  jmp alltraps
8010593d:	e9 75 f8 ff ff       	jmp    801051b7 <alltraps>

80105942 <vector96>:
.globl vector96
vector96:
  pushl $0
80105942:	6a 00                	push   $0x0
  pushl $96
80105944:	6a 60                	push   $0x60
  jmp alltraps
80105946:	e9 6c f8 ff ff       	jmp    801051b7 <alltraps>

8010594b <vector97>:
.globl vector97
vector97:
  pushl $0
8010594b:	6a 00                	push   $0x0
  pushl $97
8010594d:	6a 61                	push   $0x61
  jmp alltraps
8010594f:	e9 63 f8 ff ff       	jmp    801051b7 <alltraps>

80105954 <vector98>:
.globl vector98
vector98:
  pushl $0
80105954:	6a 00                	push   $0x0
  pushl $98
80105956:	6a 62                	push   $0x62
  jmp alltraps
80105958:	e9 5a f8 ff ff       	jmp    801051b7 <alltraps>

8010595d <vector99>:
.globl vector99
vector99:
  pushl $0
8010595d:	6a 00                	push   $0x0
  pushl $99
8010595f:	6a 63                	push   $0x63
  jmp alltraps
80105961:	e9 51 f8 ff ff       	jmp    801051b7 <alltraps>

80105966 <vector100>:
.globl vector100
vector100:
  pushl $0
80105966:	6a 00                	push   $0x0
  pushl $100
80105968:	6a 64                	push   $0x64
  jmp alltraps
8010596a:	e9 48 f8 ff ff       	jmp    801051b7 <alltraps>

8010596f <vector101>:
.globl vector101
vector101:
  pushl $0
8010596f:	6a 00                	push   $0x0
  pushl $101
80105971:	6a 65                	push   $0x65
  jmp alltraps
80105973:	e9 3f f8 ff ff       	jmp    801051b7 <alltraps>

80105978 <vector102>:
.globl vector102
vector102:
  pushl $0
80105978:	6a 00                	push   $0x0
  pushl $102
8010597a:	6a 66                	push   $0x66
  jmp alltraps
8010597c:	e9 36 f8 ff ff       	jmp    801051b7 <alltraps>

80105981 <vector103>:
.globl vector103
vector103:
  pushl $0
80105981:	6a 00                	push   $0x0
  pushl $103
80105983:	6a 67                	push   $0x67
  jmp alltraps
80105985:	e9 2d f8 ff ff       	jmp    801051b7 <alltraps>

8010598a <vector104>:
.globl vector104
vector104:
  pushl $0
8010598a:	6a 00                	push   $0x0
  pushl $104
8010598c:	6a 68                	push   $0x68
  jmp alltraps
8010598e:	e9 24 f8 ff ff       	jmp    801051b7 <alltraps>

80105993 <vector105>:
.globl vector105
vector105:
  pushl $0
80105993:	6a 00                	push   $0x0
  pushl $105
80105995:	6a 69                	push   $0x69
  jmp alltraps
80105997:	e9 1b f8 ff ff       	jmp    801051b7 <alltraps>

8010599c <vector106>:
.globl vector106
vector106:
  pushl $0
8010599c:	6a 00                	push   $0x0
  pushl $106
8010599e:	6a 6a                	push   $0x6a
  jmp alltraps
801059a0:	e9 12 f8 ff ff       	jmp    801051b7 <alltraps>

801059a5 <vector107>:
.globl vector107
vector107:
  pushl $0
801059a5:	6a 00                	push   $0x0
  pushl $107
801059a7:	6a 6b                	push   $0x6b
  jmp alltraps
801059a9:	e9 09 f8 ff ff       	jmp    801051b7 <alltraps>

801059ae <vector108>:
.globl vector108
vector108:
  pushl $0
801059ae:	6a 00                	push   $0x0
  pushl $108
801059b0:	6a 6c                	push   $0x6c
  jmp alltraps
801059b2:	e9 00 f8 ff ff       	jmp    801051b7 <alltraps>

801059b7 <vector109>:
.globl vector109
vector109:
  pushl $0
801059b7:	6a 00                	push   $0x0
  pushl $109
801059b9:	6a 6d                	push   $0x6d
  jmp alltraps
801059bb:	e9 f7 f7 ff ff       	jmp    801051b7 <alltraps>

801059c0 <vector110>:
.globl vector110
vector110:
  pushl $0
801059c0:	6a 00                	push   $0x0
  pushl $110
801059c2:	6a 6e                	push   $0x6e
  jmp alltraps
801059c4:	e9 ee f7 ff ff       	jmp    801051b7 <alltraps>

801059c9 <vector111>:
.globl vector111
vector111:
  pushl $0
801059c9:	6a 00                	push   $0x0
  pushl $111
801059cb:	6a 6f                	push   $0x6f
  jmp alltraps
801059cd:	e9 e5 f7 ff ff       	jmp    801051b7 <alltraps>

801059d2 <vector112>:
.globl vector112
vector112:
  pushl $0
801059d2:	6a 00                	push   $0x0
  pushl $112
801059d4:	6a 70                	push   $0x70
  jmp alltraps
801059d6:	e9 dc f7 ff ff       	jmp    801051b7 <alltraps>

801059db <vector113>:
.globl vector113
vector113:
  pushl $0
801059db:	6a 00                	push   $0x0
  pushl $113
801059dd:	6a 71                	push   $0x71
  jmp alltraps
801059df:	e9 d3 f7 ff ff       	jmp    801051b7 <alltraps>

801059e4 <vector114>:
.globl vector114
vector114:
  pushl $0
801059e4:	6a 00                	push   $0x0
  pushl $114
801059e6:	6a 72                	push   $0x72
  jmp alltraps
801059e8:	e9 ca f7 ff ff       	jmp    801051b7 <alltraps>

801059ed <vector115>:
.globl vector115
vector115:
  pushl $0
801059ed:	6a 00                	push   $0x0
  pushl $115
801059ef:	6a 73                	push   $0x73
  jmp alltraps
801059f1:	e9 c1 f7 ff ff       	jmp    801051b7 <alltraps>

801059f6 <vector116>:
.globl vector116
vector116:
  pushl $0
801059f6:	6a 00                	push   $0x0
  pushl $116
801059f8:	6a 74                	push   $0x74
  jmp alltraps
801059fa:	e9 b8 f7 ff ff       	jmp    801051b7 <alltraps>

801059ff <vector117>:
.globl vector117
vector117:
  pushl $0
801059ff:	6a 00                	push   $0x0
  pushl $117
80105a01:	6a 75                	push   $0x75
  jmp alltraps
80105a03:	e9 af f7 ff ff       	jmp    801051b7 <alltraps>

80105a08 <vector118>:
.globl vector118
vector118:
  pushl $0
80105a08:	6a 00                	push   $0x0
  pushl $118
80105a0a:	6a 76                	push   $0x76
  jmp alltraps
80105a0c:	e9 a6 f7 ff ff       	jmp    801051b7 <alltraps>

80105a11 <vector119>:
.globl vector119
vector119:
  pushl $0
80105a11:	6a 00                	push   $0x0
  pushl $119
80105a13:	6a 77                	push   $0x77
  jmp alltraps
80105a15:	e9 9d f7 ff ff       	jmp    801051b7 <alltraps>

80105a1a <vector120>:
.globl vector120
vector120:
  pushl $0
80105a1a:	6a 00                	push   $0x0
  pushl $120
80105a1c:	6a 78                	push   $0x78
  jmp alltraps
80105a1e:	e9 94 f7 ff ff       	jmp    801051b7 <alltraps>

80105a23 <vector121>:
.globl vector121
vector121:
  pushl $0
80105a23:	6a 00                	push   $0x0
  pushl $121
80105a25:	6a 79                	push   $0x79
  jmp alltraps
80105a27:	e9 8b f7 ff ff       	jmp    801051b7 <alltraps>

80105a2c <vector122>:
.globl vector122
vector122:
  pushl $0
80105a2c:	6a 00                	push   $0x0
  pushl $122
80105a2e:	6a 7a                	push   $0x7a
  jmp alltraps
80105a30:	e9 82 f7 ff ff       	jmp    801051b7 <alltraps>

80105a35 <vector123>:
.globl vector123
vector123:
  pushl $0
80105a35:	6a 00                	push   $0x0
  pushl $123
80105a37:	6a 7b                	push   $0x7b
  jmp alltraps
80105a39:	e9 79 f7 ff ff       	jmp    801051b7 <alltraps>

80105a3e <vector124>:
.globl vector124
vector124:
  pushl $0
80105a3e:	6a 00                	push   $0x0
  pushl $124
80105a40:	6a 7c                	push   $0x7c
  jmp alltraps
80105a42:	e9 70 f7 ff ff       	jmp    801051b7 <alltraps>

80105a47 <vector125>:
.globl vector125
vector125:
  pushl $0
80105a47:	6a 00                	push   $0x0
  pushl $125
80105a49:	6a 7d                	push   $0x7d
  jmp alltraps
80105a4b:	e9 67 f7 ff ff       	jmp    801051b7 <alltraps>

80105a50 <vector126>:
.globl vector126
vector126:
  pushl $0
80105a50:	6a 00                	push   $0x0
  pushl $126
80105a52:	6a 7e                	push   $0x7e
  jmp alltraps
80105a54:	e9 5e f7 ff ff       	jmp    801051b7 <alltraps>

80105a59 <vector127>:
.globl vector127
vector127:
  pushl $0
80105a59:	6a 00                	push   $0x0
  pushl $127
80105a5b:	6a 7f                	push   $0x7f
  jmp alltraps
80105a5d:	e9 55 f7 ff ff       	jmp    801051b7 <alltraps>

80105a62 <vector128>:
.globl vector128
vector128:
  pushl $0
80105a62:	6a 00                	push   $0x0
  pushl $128
80105a64:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80105a69:	e9 49 f7 ff ff       	jmp    801051b7 <alltraps>

80105a6e <vector129>:
.globl vector129
vector129:
  pushl $0
80105a6e:	6a 00                	push   $0x0
  pushl $129
80105a70:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80105a75:	e9 3d f7 ff ff       	jmp    801051b7 <alltraps>

80105a7a <vector130>:
.globl vector130
vector130:
  pushl $0
80105a7a:	6a 00                	push   $0x0
  pushl $130
80105a7c:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80105a81:	e9 31 f7 ff ff       	jmp    801051b7 <alltraps>

80105a86 <vector131>:
.globl vector131
vector131:
  pushl $0
80105a86:	6a 00                	push   $0x0
  pushl $131
80105a88:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105a8d:	e9 25 f7 ff ff       	jmp    801051b7 <alltraps>

80105a92 <vector132>:
.globl vector132
vector132:
  pushl $0
80105a92:	6a 00                	push   $0x0
  pushl $132
80105a94:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105a99:	e9 19 f7 ff ff       	jmp    801051b7 <alltraps>

80105a9e <vector133>:
.globl vector133
vector133:
  pushl $0
80105a9e:	6a 00                	push   $0x0
  pushl $133
80105aa0:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80105aa5:	e9 0d f7 ff ff       	jmp    801051b7 <alltraps>

80105aaa <vector134>:
.globl vector134
vector134:
  pushl $0
80105aaa:	6a 00                	push   $0x0
  pushl $134
80105aac:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80105ab1:	e9 01 f7 ff ff       	jmp    801051b7 <alltraps>

80105ab6 <vector135>:
.globl vector135
vector135:
  pushl $0
80105ab6:	6a 00                	push   $0x0
  pushl $135
80105ab8:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105abd:	e9 f5 f6 ff ff       	jmp    801051b7 <alltraps>

80105ac2 <vector136>:
.globl vector136
vector136:
  pushl $0
80105ac2:	6a 00                	push   $0x0
  pushl $136
80105ac4:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105ac9:	e9 e9 f6 ff ff       	jmp    801051b7 <alltraps>

80105ace <vector137>:
.globl vector137
vector137:
  pushl $0
80105ace:	6a 00                	push   $0x0
  pushl $137
80105ad0:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80105ad5:	e9 dd f6 ff ff       	jmp    801051b7 <alltraps>

80105ada <vector138>:
.globl vector138
vector138:
  pushl $0
80105ada:	6a 00                	push   $0x0
  pushl $138
80105adc:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105ae1:	e9 d1 f6 ff ff       	jmp    801051b7 <alltraps>

80105ae6 <vector139>:
.globl vector139
vector139:
  pushl $0
80105ae6:	6a 00                	push   $0x0
  pushl $139
80105ae8:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105aed:	e9 c5 f6 ff ff       	jmp    801051b7 <alltraps>

80105af2 <vector140>:
.globl vector140
vector140:
  pushl $0
80105af2:	6a 00                	push   $0x0
  pushl $140
80105af4:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105af9:	e9 b9 f6 ff ff       	jmp    801051b7 <alltraps>

80105afe <vector141>:
.globl vector141
vector141:
  pushl $0
80105afe:	6a 00                	push   $0x0
  pushl $141
80105b00:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105b05:	e9 ad f6 ff ff       	jmp    801051b7 <alltraps>

80105b0a <vector142>:
.globl vector142
vector142:
  pushl $0
80105b0a:	6a 00                	push   $0x0
  pushl $142
80105b0c:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105b11:	e9 a1 f6 ff ff       	jmp    801051b7 <alltraps>

80105b16 <vector143>:
.globl vector143
vector143:
  pushl $0
80105b16:	6a 00                	push   $0x0
  pushl $143
80105b18:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105b1d:	e9 95 f6 ff ff       	jmp    801051b7 <alltraps>

80105b22 <vector144>:
.globl vector144
vector144:
  pushl $0
80105b22:	6a 00                	push   $0x0
  pushl $144
80105b24:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105b29:	e9 89 f6 ff ff       	jmp    801051b7 <alltraps>

80105b2e <vector145>:
.globl vector145
vector145:
  pushl $0
80105b2e:	6a 00                	push   $0x0
  pushl $145
80105b30:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105b35:	e9 7d f6 ff ff       	jmp    801051b7 <alltraps>

80105b3a <vector146>:
.globl vector146
vector146:
  pushl $0
80105b3a:	6a 00                	push   $0x0
  pushl $146
80105b3c:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105b41:	e9 71 f6 ff ff       	jmp    801051b7 <alltraps>

80105b46 <vector147>:
.globl vector147
vector147:
  pushl $0
80105b46:	6a 00                	push   $0x0
  pushl $147
80105b48:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105b4d:	e9 65 f6 ff ff       	jmp    801051b7 <alltraps>

80105b52 <vector148>:
.globl vector148
vector148:
  pushl $0
80105b52:	6a 00                	push   $0x0
  pushl $148
80105b54:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105b59:	e9 59 f6 ff ff       	jmp    801051b7 <alltraps>

80105b5e <vector149>:
.globl vector149
vector149:
  pushl $0
80105b5e:	6a 00                	push   $0x0
  pushl $149
80105b60:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80105b65:	e9 4d f6 ff ff       	jmp    801051b7 <alltraps>

80105b6a <vector150>:
.globl vector150
vector150:
  pushl $0
80105b6a:	6a 00                	push   $0x0
  pushl $150
80105b6c:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80105b71:	e9 41 f6 ff ff       	jmp    801051b7 <alltraps>

80105b76 <vector151>:
.globl vector151
vector151:
  pushl $0
80105b76:	6a 00                	push   $0x0
  pushl $151
80105b78:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105b7d:	e9 35 f6 ff ff       	jmp    801051b7 <alltraps>

80105b82 <vector152>:
.globl vector152
vector152:
  pushl $0
80105b82:	6a 00                	push   $0x0
  pushl $152
80105b84:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105b89:	e9 29 f6 ff ff       	jmp    801051b7 <alltraps>

80105b8e <vector153>:
.globl vector153
vector153:
  pushl $0
80105b8e:	6a 00                	push   $0x0
  pushl $153
80105b90:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105b95:	e9 1d f6 ff ff       	jmp    801051b7 <alltraps>

80105b9a <vector154>:
.globl vector154
vector154:
  pushl $0
80105b9a:	6a 00                	push   $0x0
  pushl $154
80105b9c:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105ba1:	e9 11 f6 ff ff       	jmp    801051b7 <alltraps>

80105ba6 <vector155>:
.globl vector155
vector155:
  pushl $0
80105ba6:	6a 00                	push   $0x0
  pushl $155
80105ba8:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105bad:	e9 05 f6 ff ff       	jmp    801051b7 <alltraps>

80105bb2 <vector156>:
.globl vector156
vector156:
  pushl $0
80105bb2:	6a 00                	push   $0x0
  pushl $156
80105bb4:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105bb9:	e9 f9 f5 ff ff       	jmp    801051b7 <alltraps>

80105bbe <vector157>:
.globl vector157
vector157:
  pushl $0
80105bbe:	6a 00                	push   $0x0
  pushl $157
80105bc0:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105bc5:	e9 ed f5 ff ff       	jmp    801051b7 <alltraps>

80105bca <vector158>:
.globl vector158
vector158:
  pushl $0
80105bca:	6a 00                	push   $0x0
  pushl $158
80105bcc:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105bd1:	e9 e1 f5 ff ff       	jmp    801051b7 <alltraps>

80105bd6 <vector159>:
.globl vector159
vector159:
  pushl $0
80105bd6:	6a 00                	push   $0x0
  pushl $159
80105bd8:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105bdd:	e9 d5 f5 ff ff       	jmp    801051b7 <alltraps>

80105be2 <vector160>:
.globl vector160
vector160:
  pushl $0
80105be2:	6a 00                	push   $0x0
  pushl $160
80105be4:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105be9:	e9 c9 f5 ff ff       	jmp    801051b7 <alltraps>

80105bee <vector161>:
.globl vector161
vector161:
  pushl $0
80105bee:	6a 00                	push   $0x0
  pushl $161
80105bf0:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105bf5:	e9 bd f5 ff ff       	jmp    801051b7 <alltraps>

80105bfa <vector162>:
.globl vector162
vector162:
  pushl $0
80105bfa:	6a 00                	push   $0x0
  pushl $162
80105bfc:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105c01:	e9 b1 f5 ff ff       	jmp    801051b7 <alltraps>

80105c06 <vector163>:
.globl vector163
vector163:
  pushl $0
80105c06:	6a 00                	push   $0x0
  pushl $163
80105c08:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105c0d:	e9 a5 f5 ff ff       	jmp    801051b7 <alltraps>

80105c12 <vector164>:
.globl vector164
vector164:
  pushl $0
80105c12:	6a 00                	push   $0x0
  pushl $164
80105c14:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105c19:	e9 99 f5 ff ff       	jmp    801051b7 <alltraps>

80105c1e <vector165>:
.globl vector165
vector165:
  pushl $0
80105c1e:	6a 00                	push   $0x0
  pushl $165
80105c20:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105c25:	e9 8d f5 ff ff       	jmp    801051b7 <alltraps>

80105c2a <vector166>:
.globl vector166
vector166:
  pushl $0
80105c2a:	6a 00                	push   $0x0
  pushl $166
80105c2c:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105c31:	e9 81 f5 ff ff       	jmp    801051b7 <alltraps>

80105c36 <vector167>:
.globl vector167
vector167:
  pushl $0
80105c36:	6a 00                	push   $0x0
  pushl $167
80105c38:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105c3d:	e9 75 f5 ff ff       	jmp    801051b7 <alltraps>

80105c42 <vector168>:
.globl vector168
vector168:
  pushl $0
80105c42:	6a 00                	push   $0x0
  pushl $168
80105c44:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105c49:	e9 69 f5 ff ff       	jmp    801051b7 <alltraps>

80105c4e <vector169>:
.globl vector169
vector169:
  pushl $0
80105c4e:	6a 00                	push   $0x0
  pushl $169
80105c50:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105c55:	e9 5d f5 ff ff       	jmp    801051b7 <alltraps>

80105c5a <vector170>:
.globl vector170
vector170:
  pushl $0
80105c5a:	6a 00                	push   $0x0
  pushl $170
80105c5c:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105c61:	e9 51 f5 ff ff       	jmp    801051b7 <alltraps>

80105c66 <vector171>:
.globl vector171
vector171:
  pushl $0
80105c66:	6a 00                	push   $0x0
  pushl $171
80105c68:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105c6d:	e9 45 f5 ff ff       	jmp    801051b7 <alltraps>

80105c72 <vector172>:
.globl vector172
vector172:
  pushl $0
80105c72:	6a 00                	push   $0x0
  pushl $172
80105c74:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105c79:	e9 39 f5 ff ff       	jmp    801051b7 <alltraps>

80105c7e <vector173>:
.globl vector173
vector173:
  pushl $0
80105c7e:	6a 00                	push   $0x0
  pushl $173
80105c80:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105c85:	e9 2d f5 ff ff       	jmp    801051b7 <alltraps>

80105c8a <vector174>:
.globl vector174
vector174:
  pushl $0
80105c8a:	6a 00                	push   $0x0
  pushl $174
80105c8c:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105c91:	e9 21 f5 ff ff       	jmp    801051b7 <alltraps>

80105c96 <vector175>:
.globl vector175
vector175:
  pushl $0
80105c96:	6a 00                	push   $0x0
  pushl $175
80105c98:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105c9d:	e9 15 f5 ff ff       	jmp    801051b7 <alltraps>

80105ca2 <vector176>:
.globl vector176
vector176:
  pushl $0
80105ca2:	6a 00                	push   $0x0
  pushl $176
80105ca4:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105ca9:	e9 09 f5 ff ff       	jmp    801051b7 <alltraps>

80105cae <vector177>:
.globl vector177
vector177:
  pushl $0
80105cae:	6a 00                	push   $0x0
  pushl $177
80105cb0:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105cb5:	e9 fd f4 ff ff       	jmp    801051b7 <alltraps>

80105cba <vector178>:
.globl vector178
vector178:
  pushl $0
80105cba:	6a 00                	push   $0x0
  pushl $178
80105cbc:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105cc1:	e9 f1 f4 ff ff       	jmp    801051b7 <alltraps>

80105cc6 <vector179>:
.globl vector179
vector179:
  pushl $0
80105cc6:	6a 00                	push   $0x0
  pushl $179
80105cc8:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105ccd:	e9 e5 f4 ff ff       	jmp    801051b7 <alltraps>

80105cd2 <vector180>:
.globl vector180
vector180:
  pushl $0
80105cd2:	6a 00                	push   $0x0
  pushl $180
80105cd4:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105cd9:	e9 d9 f4 ff ff       	jmp    801051b7 <alltraps>

80105cde <vector181>:
.globl vector181
vector181:
  pushl $0
80105cde:	6a 00                	push   $0x0
  pushl $181
80105ce0:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105ce5:	e9 cd f4 ff ff       	jmp    801051b7 <alltraps>

80105cea <vector182>:
.globl vector182
vector182:
  pushl $0
80105cea:	6a 00                	push   $0x0
  pushl $182
80105cec:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105cf1:	e9 c1 f4 ff ff       	jmp    801051b7 <alltraps>

80105cf6 <vector183>:
.globl vector183
vector183:
  pushl $0
80105cf6:	6a 00                	push   $0x0
  pushl $183
80105cf8:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105cfd:	e9 b5 f4 ff ff       	jmp    801051b7 <alltraps>

80105d02 <vector184>:
.globl vector184
vector184:
  pushl $0
80105d02:	6a 00                	push   $0x0
  pushl $184
80105d04:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105d09:	e9 a9 f4 ff ff       	jmp    801051b7 <alltraps>

80105d0e <vector185>:
.globl vector185
vector185:
  pushl $0
80105d0e:	6a 00                	push   $0x0
  pushl $185
80105d10:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105d15:	e9 9d f4 ff ff       	jmp    801051b7 <alltraps>

80105d1a <vector186>:
.globl vector186
vector186:
  pushl $0
80105d1a:	6a 00                	push   $0x0
  pushl $186
80105d1c:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105d21:	e9 91 f4 ff ff       	jmp    801051b7 <alltraps>

80105d26 <vector187>:
.globl vector187
vector187:
  pushl $0
80105d26:	6a 00                	push   $0x0
  pushl $187
80105d28:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105d2d:	e9 85 f4 ff ff       	jmp    801051b7 <alltraps>

80105d32 <vector188>:
.globl vector188
vector188:
  pushl $0
80105d32:	6a 00                	push   $0x0
  pushl $188
80105d34:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105d39:	e9 79 f4 ff ff       	jmp    801051b7 <alltraps>

80105d3e <vector189>:
.globl vector189
vector189:
  pushl $0
80105d3e:	6a 00                	push   $0x0
  pushl $189
80105d40:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105d45:	e9 6d f4 ff ff       	jmp    801051b7 <alltraps>

80105d4a <vector190>:
.globl vector190
vector190:
  pushl $0
80105d4a:	6a 00                	push   $0x0
  pushl $190
80105d4c:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105d51:	e9 61 f4 ff ff       	jmp    801051b7 <alltraps>

80105d56 <vector191>:
.globl vector191
vector191:
  pushl $0
80105d56:	6a 00                	push   $0x0
  pushl $191
80105d58:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105d5d:	e9 55 f4 ff ff       	jmp    801051b7 <alltraps>

80105d62 <vector192>:
.globl vector192
vector192:
  pushl $0
80105d62:	6a 00                	push   $0x0
  pushl $192
80105d64:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105d69:	e9 49 f4 ff ff       	jmp    801051b7 <alltraps>

80105d6e <vector193>:
.globl vector193
vector193:
  pushl $0
80105d6e:	6a 00                	push   $0x0
  pushl $193
80105d70:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105d75:	e9 3d f4 ff ff       	jmp    801051b7 <alltraps>

80105d7a <vector194>:
.globl vector194
vector194:
  pushl $0
80105d7a:	6a 00                	push   $0x0
  pushl $194
80105d7c:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105d81:	e9 31 f4 ff ff       	jmp    801051b7 <alltraps>

80105d86 <vector195>:
.globl vector195
vector195:
  pushl $0
80105d86:	6a 00                	push   $0x0
  pushl $195
80105d88:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105d8d:	e9 25 f4 ff ff       	jmp    801051b7 <alltraps>

80105d92 <vector196>:
.globl vector196
vector196:
  pushl $0
80105d92:	6a 00                	push   $0x0
  pushl $196
80105d94:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105d99:	e9 19 f4 ff ff       	jmp    801051b7 <alltraps>

80105d9e <vector197>:
.globl vector197
vector197:
  pushl $0
80105d9e:	6a 00                	push   $0x0
  pushl $197
80105da0:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105da5:	e9 0d f4 ff ff       	jmp    801051b7 <alltraps>

80105daa <vector198>:
.globl vector198
vector198:
  pushl $0
80105daa:	6a 00                	push   $0x0
  pushl $198
80105dac:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105db1:	e9 01 f4 ff ff       	jmp    801051b7 <alltraps>

80105db6 <vector199>:
.globl vector199
vector199:
  pushl $0
80105db6:	6a 00                	push   $0x0
  pushl $199
80105db8:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105dbd:	e9 f5 f3 ff ff       	jmp    801051b7 <alltraps>

80105dc2 <vector200>:
.globl vector200
vector200:
  pushl $0
80105dc2:	6a 00                	push   $0x0
  pushl $200
80105dc4:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105dc9:	e9 e9 f3 ff ff       	jmp    801051b7 <alltraps>

80105dce <vector201>:
.globl vector201
vector201:
  pushl $0
80105dce:	6a 00                	push   $0x0
  pushl $201
80105dd0:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105dd5:	e9 dd f3 ff ff       	jmp    801051b7 <alltraps>

80105dda <vector202>:
.globl vector202
vector202:
  pushl $0
80105dda:	6a 00                	push   $0x0
  pushl $202
80105ddc:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105de1:	e9 d1 f3 ff ff       	jmp    801051b7 <alltraps>

80105de6 <vector203>:
.globl vector203
vector203:
  pushl $0
80105de6:	6a 00                	push   $0x0
  pushl $203
80105de8:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105ded:	e9 c5 f3 ff ff       	jmp    801051b7 <alltraps>

80105df2 <vector204>:
.globl vector204
vector204:
  pushl $0
80105df2:	6a 00                	push   $0x0
  pushl $204
80105df4:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105df9:	e9 b9 f3 ff ff       	jmp    801051b7 <alltraps>

80105dfe <vector205>:
.globl vector205
vector205:
  pushl $0
80105dfe:	6a 00                	push   $0x0
  pushl $205
80105e00:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105e05:	e9 ad f3 ff ff       	jmp    801051b7 <alltraps>

80105e0a <vector206>:
.globl vector206
vector206:
  pushl $0
80105e0a:	6a 00                	push   $0x0
  pushl $206
80105e0c:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105e11:	e9 a1 f3 ff ff       	jmp    801051b7 <alltraps>

80105e16 <vector207>:
.globl vector207
vector207:
  pushl $0
80105e16:	6a 00                	push   $0x0
  pushl $207
80105e18:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105e1d:	e9 95 f3 ff ff       	jmp    801051b7 <alltraps>

80105e22 <vector208>:
.globl vector208
vector208:
  pushl $0
80105e22:	6a 00                	push   $0x0
  pushl $208
80105e24:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105e29:	e9 89 f3 ff ff       	jmp    801051b7 <alltraps>

80105e2e <vector209>:
.globl vector209
vector209:
  pushl $0
80105e2e:	6a 00                	push   $0x0
  pushl $209
80105e30:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105e35:	e9 7d f3 ff ff       	jmp    801051b7 <alltraps>

80105e3a <vector210>:
.globl vector210
vector210:
  pushl $0
80105e3a:	6a 00                	push   $0x0
  pushl $210
80105e3c:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105e41:	e9 71 f3 ff ff       	jmp    801051b7 <alltraps>

80105e46 <vector211>:
.globl vector211
vector211:
  pushl $0
80105e46:	6a 00                	push   $0x0
  pushl $211
80105e48:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105e4d:	e9 65 f3 ff ff       	jmp    801051b7 <alltraps>

80105e52 <vector212>:
.globl vector212
vector212:
  pushl $0
80105e52:	6a 00                	push   $0x0
  pushl $212
80105e54:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105e59:	e9 59 f3 ff ff       	jmp    801051b7 <alltraps>

80105e5e <vector213>:
.globl vector213
vector213:
  pushl $0
80105e5e:	6a 00                	push   $0x0
  pushl $213
80105e60:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105e65:	e9 4d f3 ff ff       	jmp    801051b7 <alltraps>

80105e6a <vector214>:
.globl vector214
vector214:
  pushl $0
80105e6a:	6a 00                	push   $0x0
  pushl $214
80105e6c:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105e71:	e9 41 f3 ff ff       	jmp    801051b7 <alltraps>

80105e76 <vector215>:
.globl vector215
vector215:
  pushl $0
80105e76:	6a 00                	push   $0x0
  pushl $215
80105e78:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105e7d:	e9 35 f3 ff ff       	jmp    801051b7 <alltraps>

80105e82 <vector216>:
.globl vector216
vector216:
  pushl $0
80105e82:	6a 00                	push   $0x0
  pushl $216
80105e84:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105e89:	e9 29 f3 ff ff       	jmp    801051b7 <alltraps>

80105e8e <vector217>:
.globl vector217
vector217:
  pushl $0
80105e8e:	6a 00                	push   $0x0
  pushl $217
80105e90:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105e95:	e9 1d f3 ff ff       	jmp    801051b7 <alltraps>

80105e9a <vector218>:
.globl vector218
vector218:
  pushl $0
80105e9a:	6a 00                	push   $0x0
  pushl $218
80105e9c:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105ea1:	e9 11 f3 ff ff       	jmp    801051b7 <alltraps>

80105ea6 <vector219>:
.globl vector219
vector219:
  pushl $0
80105ea6:	6a 00                	push   $0x0
  pushl $219
80105ea8:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105ead:	e9 05 f3 ff ff       	jmp    801051b7 <alltraps>

80105eb2 <vector220>:
.globl vector220
vector220:
  pushl $0
80105eb2:	6a 00                	push   $0x0
  pushl $220
80105eb4:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105eb9:	e9 f9 f2 ff ff       	jmp    801051b7 <alltraps>

80105ebe <vector221>:
.globl vector221
vector221:
  pushl $0
80105ebe:	6a 00                	push   $0x0
  pushl $221
80105ec0:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105ec5:	e9 ed f2 ff ff       	jmp    801051b7 <alltraps>

80105eca <vector222>:
.globl vector222
vector222:
  pushl $0
80105eca:	6a 00                	push   $0x0
  pushl $222
80105ecc:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105ed1:	e9 e1 f2 ff ff       	jmp    801051b7 <alltraps>

80105ed6 <vector223>:
.globl vector223
vector223:
  pushl $0
80105ed6:	6a 00                	push   $0x0
  pushl $223
80105ed8:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105edd:	e9 d5 f2 ff ff       	jmp    801051b7 <alltraps>

80105ee2 <vector224>:
.globl vector224
vector224:
  pushl $0
80105ee2:	6a 00                	push   $0x0
  pushl $224
80105ee4:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105ee9:	e9 c9 f2 ff ff       	jmp    801051b7 <alltraps>

80105eee <vector225>:
.globl vector225
vector225:
  pushl $0
80105eee:	6a 00                	push   $0x0
  pushl $225
80105ef0:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105ef5:	e9 bd f2 ff ff       	jmp    801051b7 <alltraps>

80105efa <vector226>:
.globl vector226
vector226:
  pushl $0
80105efa:	6a 00                	push   $0x0
  pushl $226
80105efc:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105f01:	e9 b1 f2 ff ff       	jmp    801051b7 <alltraps>

80105f06 <vector227>:
.globl vector227
vector227:
  pushl $0
80105f06:	6a 00                	push   $0x0
  pushl $227
80105f08:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105f0d:	e9 a5 f2 ff ff       	jmp    801051b7 <alltraps>

80105f12 <vector228>:
.globl vector228
vector228:
  pushl $0
80105f12:	6a 00                	push   $0x0
  pushl $228
80105f14:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105f19:	e9 99 f2 ff ff       	jmp    801051b7 <alltraps>

80105f1e <vector229>:
.globl vector229
vector229:
  pushl $0
80105f1e:	6a 00                	push   $0x0
  pushl $229
80105f20:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105f25:	e9 8d f2 ff ff       	jmp    801051b7 <alltraps>

80105f2a <vector230>:
.globl vector230
vector230:
  pushl $0
80105f2a:	6a 00                	push   $0x0
  pushl $230
80105f2c:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105f31:	e9 81 f2 ff ff       	jmp    801051b7 <alltraps>

80105f36 <vector231>:
.globl vector231
vector231:
  pushl $0
80105f36:	6a 00                	push   $0x0
  pushl $231
80105f38:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105f3d:	e9 75 f2 ff ff       	jmp    801051b7 <alltraps>

80105f42 <vector232>:
.globl vector232
vector232:
  pushl $0
80105f42:	6a 00                	push   $0x0
  pushl $232
80105f44:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105f49:	e9 69 f2 ff ff       	jmp    801051b7 <alltraps>

80105f4e <vector233>:
.globl vector233
vector233:
  pushl $0
80105f4e:	6a 00                	push   $0x0
  pushl $233
80105f50:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105f55:	e9 5d f2 ff ff       	jmp    801051b7 <alltraps>

80105f5a <vector234>:
.globl vector234
vector234:
  pushl $0
80105f5a:	6a 00                	push   $0x0
  pushl $234
80105f5c:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105f61:	e9 51 f2 ff ff       	jmp    801051b7 <alltraps>

80105f66 <vector235>:
.globl vector235
vector235:
  pushl $0
80105f66:	6a 00                	push   $0x0
  pushl $235
80105f68:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105f6d:	e9 45 f2 ff ff       	jmp    801051b7 <alltraps>

80105f72 <vector236>:
.globl vector236
vector236:
  pushl $0
80105f72:	6a 00                	push   $0x0
  pushl $236
80105f74:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105f79:	e9 39 f2 ff ff       	jmp    801051b7 <alltraps>

80105f7e <vector237>:
.globl vector237
vector237:
  pushl $0
80105f7e:	6a 00                	push   $0x0
  pushl $237
80105f80:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105f85:	e9 2d f2 ff ff       	jmp    801051b7 <alltraps>

80105f8a <vector238>:
.globl vector238
vector238:
  pushl $0
80105f8a:	6a 00                	push   $0x0
  pushl $238
80105f8c:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105f91:	e9 21 f2 ff ff       	jmp    801051b7 <alltraps>

80105f96 <vector239>:
.globl vector239
vector239:
  pushl $0
80105f96:	6a 00                	push   $0x0
  pushl $239
80105f98:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105f9d:	e9 15 f2 ff ff       	jmp    801051b7 <alltraps>

80105fa2 <vector240>:
.globl vector240
vector240:
  pushl $0
80105fa2:	6a 00                	push   $0x0
  pushl $240
80105fa4:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105fa9:	e9 09 f2 ff ff       	jmp    801051b7 <alltraps>

80105fae <vector241>:
.globl vector241
vector241:
  pushl $0
80105fae:	6a 00                	push   $0x0
  pushl $241
80105fb0:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105fb5:	e9 fd f1 ff ff       	jmp    801051b7 <alltraps>

80105fba <vector242>:
.globl vector242
vector242:
  pushl $0
80105fba:	6a 00                	push   $0x0
  pushl $242
80105fbc:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105fc1:	e9 f1 f1 ff ff       	jmp    801051b7 <alltraps>

80105fc6 <vector243>:
.globl vector243
vector243:
  pushl $0
80105fc6:	6a 00                	push   $0x0
  pushl $243
80105fc8:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105fcd:	e9 e5 f1 ff ff       	jmp    801051b7 <alltraps>

80105fd2 <vector244>:
.globl vector244
vector244:
  pushl $0
80105fd2:	6a 00                	push   $0x0
  pushl $244
80105fd4:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105fd9:	e9 d9 f1 ff ff       	jmp    801051b7 <alltraps>

80105fde <vector245>:
.globl vector245
vector245:
  pushl $0
80105fde:	6a 00                	push   $0x0
  pushl $245
80105fe0:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105fe5:	e9 cd f1 ff ff       	jmp    801051b7 <alltraps>

80105fea <vector246>:
.globl vector246
vector246:
  pushl $0
80105fea:	6a 00                	push   $0x0
  pushl $246
80105fec:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105ff1:	e9 c1 f1 ff ff       	jmp    801051b7 <alltraps>

80105ff6 <vector247>:
.globl vector247
vector247:
  pushl $0
80105ff6:	6a 00                	push   $0x0
  pushl $247
80105ff8:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105ffd:	e9 b5 f1 ff ff       	jmp    801051b7 <alltraps>

80106002 <vector248>:
.globl vector248
vector248:
  pushl $0
80106002:	6a 00                	push   $0x0
  pushl $248
80106004:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80106009:	e9 a9 f1 ff ff       	jmp    801051b7 <alltraps>

8010600e <vector249>:
.globl vector249
vector249:
  pushl $0
8010600e:	6a 00                	push   $0x0
  pushl $249
80106010:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80106015:	e9 9d f1 ff ff       	jmp    801051b7 <alltraps>

8010601a <vector250>:
.globl vector250
vector250:
  pushl $0
8010601a:	6a 00                	push   $0x0
  pushl $250
8010601c:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80106021:	e9 91 f1 ff ff       	jmp    801051b7 <alltraps>

80106026 <vector251>:
.globl vector251
vector251:
  pushl $0
80106026:	6a 00                	push   $0x0
  pushl $251
80106028:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
8010602d:	e9 85 f1 ff ff       	jmp    801051b7 <alltraps>

80106032 <vector252>:
.globl vector252
vector252:
  pushl $0
80106032:	6a 00                	push   $0x0
  pushl $252
80106034:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80106039:	e9 79 f1 ff ff       	jmp    801051b7 <alltraps>

8010603e <vector253>:
.globl vector253
vector253:
  pushl $0
8010603e:	6a 00                	push   $0x0
  pushl $253
80106040:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80106045:	e9 6d f1 ff ff       	jmp    801051b7 <alltraps>

8010604a <vector254>:
.globl vector254
vector254:
  pushl $0
8010604a:	6a 00                	push   $0x0
  pushl $254
8010604c:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80106051:	e9 61 f1 ff ff       	jmp    801051b7 <alltraps>

80106056 <vector255>:
.globl vector255
vector255:
  pushl $0
80106056:	6a 00                	push   $0x0
  pushl $255
80106058:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
8010605d:	e9 55 f1 ff ff       	jmp    801051b7 <alltraps>

80106062 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80106062:	55                   	push   %ebp
80106063:	89 e5                	mov    %esp,%ebp
80106065:	57                   	push   %edi
80106066:	56                   	push   %esi
80106067:	53                   	push   %ebx
80106068:	83 ec 0c             	sub    $0xc,%esp
8010606b:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
8010606d:	c1 ea 16             	shr    $0x16,%edx
80106070:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80106073:	8b 1f                	mov    (%edi),%ebx
80106075:	f6 c3 01             	test   $0x1,%bl
80106078:	74 22                	je     8010609c <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
8010607a:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80106080:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80106086:	c1 ee 0c             	shr    $0xc,%esi
80106089:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
8010608f:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80106092:	89 d8                	mov    %ebx,%eax
80106094:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106097:	5b                   	pop    %ebx
80106098:	5e                   	pop    %esi
80106099:	5f                   	pop    %edi
8010609a:	5d                   	pop    %ebp
8010609b:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc2()) == 0)
8010609c:	85 c9                	test   %ecx,%ecx
8010609e:	74 2b                	je     801060cb <walkpgdir+0x69>
801060a0:	e8 e6 c2 ff ff       	call   8010238b <kalloc2>
801060a5:	89 c3                	mov    %eax,%ebx
801060a7:	85 c0                	test   %eax,%eax
801060a9:	74 e7                	je     80106092 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
801060ab:	83 ec 04             	sub    $0x4,%esp
801060ae:	68 00 10 00 00       	push   $0x1000
801060b3:	6a 00                	push   $0x0
801060b5:	50                   	push   %eax
801060b6:	e8 fe df ff ff       	call   801040b9 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
801060bb:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801060c1:	83 c8 07             	or     $0x7,%eax
801060c4:	89 07                	mov    %eax,(%edi)
801060c6:	83 c4 10             	add    $0x10,%esp
801060c9:	eb bb                	jmp    80106086 <walkpgdir+0x24>
      return 0;
801060cb:	bb 00 00 00 00       	mov    $0x0,%ebx
801060d0:	eb c0                	jmp    80106092 <walkpgdir+0x30>

801060d2 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
801060d2:	55                   	push   %ebp
801060d3:	89 e5                	mov    %esp,%ebp
801060d5:	57                   	push   %edi
801060d6:	56                   	push   %esi
801060d7:	53                   	push   %ebx
801060d8:	83 ec 1c             	sub    $0x1c,%esp
801060db:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801060de:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
801060e1:	89 d3                	mov    %edx,%ebx
801060e3:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
801060e9:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
801060ed:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
801060f3:	b9 01 00 00 00       	mov    $0x1,%ecx
801060f8:	89 da                	mov    %ebx,%edx
801060fa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801060fd:	e8 60 ff ff ff       	call   80106062 <walkpgdir>
80106102:	85 c0                	test   %eax,%eax
80106104:	74 2e                	je     80106134 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80106106:	f6 00 01             	testb  $0x1,(%eax)
80106109:	75 1c                	jne    80106127 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
8010610b:	89 f2                	mov    %esi,%edx
8010610d:	0b 55 0c             	or     0xc(%ebp),%edx
80106110:	83 ca 01             	or     $0x1,%edx
80106113:	89 10                	mov    %edx,(%eax)
    if(a == last)
80106115:	39 fb                	cmp    %edi,%ebx
80106117:	74 28                	je     80106141 <mappages+0x6f>
      break;
    a += PGSIZE;
80106119:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
8010611f:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80106125:	eb cc                	jmp    801060f3 <mappages+0x21>
      panic("remap");
80106127:	83 ec 0c             	sub    $0xc,%esp
8010612a:	68 0c 72 10 80       	push   $0x8010720c
8010612f:	e8 14 a2 ff ff       	call   80100348 <panic>
      return -1;
80106134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80106139:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010613c:	5b                   	pop    %ebx
8010613d:	5e                   	pop    %esi
8010613e:	5f                   	pop    %edi
8010613f:	5d                   	pop    %ebp
80106140:	c3                   	ret    
  return 0;
80106141:	b8 00 00 00 00       	mov    $0x0,%eax
80106146:	eb f1                	jmp    80106139 <mappages+0x67>

80106148 <seginit>:
{
80106148:	55                   	push   %ebp
80106149:	89 e5                	mov    %esp,%ebp
8010614b:	53                   	push   %ebx
8010614c:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
8010614f:	e8 7b d4 ff ff       	call   801035cf <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80106154:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
8010615a:	66 c7 80 18 28 15 80 	movw   $0xffff,-0x7fead7e8(%eax)
80106161:	ff ff 
80106163:	66 c7 80 1a 28 15 80 	movw   $0x0,-0x7fead7e6(%eax)
8010616a:	00 00 
8010616c:	c6 80 1c 28 15 80 00 	movb   $0x0,-0x7fead7e4(%eax)
80106173:	0f b6 88 1d 28 15 80 	movzbl -0x7fead7e3(%eax),%ecx
8010617a:	83 e1 f0             	and    $0xfffffff0,%ecx
8010617d:	83 c9 1a             	or     $0x1a,%ecx
80106180:	83 e1 9f             	and    $0xffffff9f,%ecx
80106183:	83 c9 80             	or     $0xffffff80,%ecx
80106186:	88 88 1d 28 15 80    	mov    %cl,-0x7fead7e3(%eax)
8010618c:	0f b6 88 1e 28 15 80 	movzbl -0x7fead7e2(%eax),%ecx
80106193:	83 c9 0f             	or     $0xf,%ecx
80106196:	83 e1 cf             	and    $0xffffffcf,%ecx
80106199:	83 c9 c0             	or     $0xffffffc0,%ecx
8010619c:	88 88 1e 28 15 80    	mov    %cl,-0x7fead7e2(%eax)
801061a2:	c6 80 1f 28 15 80 00 	movb   $0x0,-0x7fead7e1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801061a9:	66 c7 80 20 28 15 80 	movw   $0xffff,-0x7fead7e0(%eax)
801061b0:	ff ff 
801061b2:	66 c7 80 22 28 15 80 	movw   $0x0,-0x7fead7de(%eax)
801061b9:	00 00 
801061bb:	c6 80 24 28 15 80 00 	movb   $0x0,-0x7fead7dc(%eax)
801061c2:	0f b6 88 25 28 15 80 	movzbl -0x7fead7db(%eax),%ecx
801061c9:	83 e1 f0             	and    $0xfffffff0,%ecx
801061cc:	83 c9 12             	or     $0x12,%ecx
801061cf:	83 e1 9f             	and    $0xffffff9f,%ecx
801061d2:	83 c9 80             	or     $0xffffff80,%ecx
801061d5:	88 88 25 28 15 80    	mov    %cl,-0x7fead7db(%eax)
801061db:	0f b6 88 26 28 15 80 	movzbl -0x7fead7da(%eax),%ecx
801061e2:	83 c9 0f             	or     $0xf,%ecx
801061e5:	83 e1 cf             	and    $0xffffffcf,%ecx
801061e8:	83 c9 c0             	or     $0xffffffc0,%ecx
801061eb:	88 88 26 28 15 80    	mov    %cl,-0x7fead7da(%eax)
801061f1:	c6 80 27 28 15 80 00 	movb   $0x0,-0x7fead7d9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801061f8:	66 c7 80 28 28 15 80 	movw   $0xffff,-0x7fead7d8(%eax)
801061ff:	ff ff 
80106201:	66 c7 80 2a 28 15 80 	movw   $0x0,-0x7fead7d6(%eax)
80106208:	00 00 
8010620a:	c6 80 2c 28 15 80 00 	movb   $0x0,-0x7fead7d4(%eax)
80106211:	c6 80 2d 28 15 80 fa 	movb   $0xfa,-0x7fead7d3(%eax)
80106218:	0f b6 88 2e 28 15 80 	movzbl -0x7fead7d2(%eax),%ecx
8010621f:	83 c9 0f             	or     $0xf,%ecx
80106222:	83 e1 cf             	and    $0xffffffcf,%ecx
80106225:	83 c9 c0             	or     $0xffffffc0,%ecx
80106228:	88 88 2e 28 15 80    	mov    %cl,-0x7fead7d2(%eax)
8010622e:	c6 80 2f 28 15 80 00 	movb   $0x0,-0x7fead7d1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80106235:	66 c7 80 30 28 15 80 	movw   $0xffff,-0x7fead7d0(%eax)
8010623c:	ff ff 
8010623e:	66 c7 80 32 28 15 80 	movw   $0x0,-0x7fead7ce(%eax)
80106245:	00 00 
80106247:	c6 80 34 28 15 80 00 	movb   $0x0,-0x7fead7cc(%eax)
8010624e:	c6 80 35 28 15 80 f2 	movb   $0xf2,-0x7fead7cb(%eax)
80106255:	0f b6 88 36 28 15 80 	movzbl -0x7fead7ca(%eax),%ecx
8010625c:	83 c9 0f             	or     $0xf,%ecx
8010625f:	83 e1 cf             	and    $0xffffffcf,%ecx
80106262:	83 c9 c0             	or     $0xffffffc0,%ecx
80106265:	88 88 36 28 15 80    	mov    %cl,-0x7fead7ca(%eax)
8010626b:	c6 80 37 28 15 80 00 	movb   $0x0,-0x7fead7c9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80106272:	05 10 28 15 80       	add    $0x80152810,%eax
  pd[0] = size-1;
80106277:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
8010627d:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80106281:	c1 e8 10             	shr    $0x10,%eax
80106284:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80106288:	8d 45 f2             	lea    -0xe(%ebp),%eax
8010628b:	0f 01 10             	lgdtl  (%eax)
}
8010628e:	83 c4 14             	add    $0x14,%esp
80106291:	5b                   	pop    %ebx
80106292:	5d                   	pop    %ebp
80106293:	c3                   	ret    

80106294 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80106294:	55                   	push   %ebp
80106295:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80106297:	a1 c4 54 15 80       	mov    0x801554c4,%eax
8010629c:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
801062a1:	0f 22 d8             	mov    %eax,%cr3
}
801062a4:	5d                   	pop    %ebp
801062a5:	c3                   	ret    

801062a6 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801062a6:	55                   	push   %ebp
801062a7:	89 e5                	mov    %esp,%ebp
801062a9:	57                   	push   %edi
801062aa:	56                   	push   %esi
801062ab:	53                   	push   %ebx
801062ac:	83 ec 1c             	sub    $0x1c,%esp
801062af:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
801062b2:	85 f6                	test   %esi,%esi
801062b4:	0f 84 dd 00 00 00    	je     80106397 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
801062ba:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
801062be:	0f 84 e0 00 00 00    	je     801063a4 <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
801062c4:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
801062c8:	0f 84 e3 00 00 00    	je     801063b1 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
801062ce:	e8 5d dc ff ff       	call   80103f30 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
801062d3:	e8 9b d2 ff ff       	call   80103573 <mycpu>
801062d8:	89 c3                	mov    %eax,%ebx
801062da:	e8 94 d2 ff ff       	call   80103573 <mycpu>
801062df:	8d 78 08             	lea    0x8(%eax),%edi
801062e2:	e8 8c d2 ff ff       	call   80103573 <mycpu>
801062e7:	83 c0 08             	add    $0x8,%eax
801062ea:	c1 e8 10             	shr    $0x10,%eax
801062ed:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801062f0:	e8 7e d2 ff ff       	call   80103573 <mycpu>
801062f5:	83 c0 08             	add    $0x8,%eax
801062f8:	c1 e8 18             	shr    $0x18,%eax
801062fb:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80106302:	67 00 
80106304:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
8010630b:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
8010630f:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80106315:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
8010631c:	83 e2 f0             	and    $0xfffffff0,%edx
8010631f:	83 ca 19             	or     $0x19,%edx
80106322:	83 e2 9f             	and    $0xffffff9f,%edx
80106325:	83 ca 80             	or     $0xffffff80,%edx
80106328:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
8010632e:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80106335:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
8010633b:	e8 33 d2 ff ff       	call   80103573 <mycpu>
80106340:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106347:	83 e2 ef             	and    $0xffffffef,%edx
8010634a:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80106350:	e8 1e d2 ff ff       	call   80103573 <mycpu>
80106355:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
8010635b:	8b 5e 08             	mov    0x8(%esi),%ebx
8010635e:	e8 10 d2 ff ff       	call   80103573 <mycpu>
80106363:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106369:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
8010636c:	e8 02 d2 ff ff       	call   80103573 <mycpu>
80106371:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80106377:	b8 28 00 00 00       	mov    $0x28,%eax
8010637c:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
8010637f:	8b 46 04             	mov    0x4(%esi),%eax
80106382:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106387:	0f 22 d8             	mov    %eax,%cr3
  popcli();
8010638a:	e8 de db ff ff       	call   80103f6d <popcli>
}
8010638f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106392:	5b                   	pop    %ebx
80106393:	5e                   	pop    %esi
80106394:	5f                   	pop    %edi
80106395:	5d                   	pop    %ebp
80106396:	c3                   	ret    
    panic("switchuvm: no process");
80106397:	83 ec 0c             	sub    $0xc,%esp
8010639a:	68 12 72 10 80       	push   $0x80107212
8010639f:	e8 a4 9f ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
801063a4:	83 ec 0c             	sub    $0xc,%esp
801063a7:	68 28 72 10 80       	push   $0x80107228
801063ac:	e8 97 9f ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
801063b1:	83 ec 0c             	sub    $0xc,%esp
801063b4:	68 3d 72 10 80       	push   $0x8010723d
801063b9:	e8 8a 9f ff ff       	call   80100348 <panic>

801063be <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801063be:	55                   	push   %ebp
801063bf:	89 e5                	mov    %esp,%ebp
801063c1:	56                   	push   %esi
801063c2:	53                   	push   %ebx
801063c3:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
801063c6:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801063cc:	77 4c                	ja     8010641a <inituvm+0x5c>
    panic("inituvm: more than a page");
  // ignore this call to kalloc. Mark as UNKNOWN
  mem = kalloc2();
801063ce:	e8 b8 bf ff ff       	call   8010238b <kalloc2>
801063d3:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
801063d5:	83 ec 04             	sub    $0x4,%esp
801063d8:	68 00 10 00 00       	push   $0x1000
801063dd:	6a 00                	push   $0x0
801063df:	50                   	push   %eax
801063e0:	e8 d4 dc ff ff       	call   801040b9 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
801063e5:	83 c4 08             	add    $0x8,%esp
801063e8:	6a 06                	push   $0x6
801063ea:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801063f0:	50                   	push   %eax
801063f1:	b9 00 10 00 00       	mov    $0x1000,%ecx
801063f6:	ba 00 00 00 00       	mov    $0x0,%edx
801063fb:	8b 45 08             	mov    0x8(%ebp),%eax
801063fe:	e8 cf fc ff ff       	call   801060d2 <mappages>
  memmove(mem, init, sz);
80106403:	83 c4 0c             	add    $0xc,%esp
80106406:	56                   	push   %esi
80106407:	ff 75 0c             	pushl  0xc(%ebp)
8010640a:	53                   	push   %ebx
8010640b:	e8 24 dd ff ff       	call   80104134 <memmove>
}
80106410:	83 c4 10             	add    $0x10,%esp
80106413:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106416:	5b                   	pop    %ebx
80106417:	5e                   	pop    %esi
80106418:	5d                   	pop    %ebp
80106419:	c3                   	ret    
    panic("inituvm: more than a page");
8010641a:	83 ec 0c             	sub    $0xc,%esp
8010641d:	68 51 72 10 80       	push   $0x80107251
80106422:	e8 21 9f ff ff       	call   80100348 <panic>

80106427 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80106427:	55                   	push   %ebp
80106428:	89 e5                	mov    %esp,%ebp
8010642a:	57                   	push   %edi
8010642b:	56                   	push   %esi
8010642c:	53                   	push   %ebx
8010642d:	83 ec 0c             	sub    $0xc,%esp
80106430:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80106433:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
8010643a:	75 07                	jne    80106443 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
8010643c:	bb 00 00 00 00       	mov    $0x0,%ebx
80106441:	eb 3c                	jmp    8010647f <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
80106443:	83 ec 0c             	sub    $0xc,%esp
80106446:	68 0c 73 10 80       	push   $0x8010730c
8010644b:	e8 f8 9e ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
80106450:	83 ec 0c             	sub    $0xc,%esp
80106453:	68 6b 72 10 80       	push   $0x8010726b
80106458:	e8 eb 9e ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
8010645d:	05 00 00 00 80       	add    $0x80000000,%eax
80106462:	56                   	push   %esi
80106463:	89 da                	mov    %ebx,%edx
80106465:	03 55 14             	add    0x14(%ebp),%edx
80106468:	52                   	push   %edx
80106469:	50                   	push   %eax
8010646a:	ff 75 10             	pushl  0x10(%ebp)
8010646d:	e8 01 b3 ff ff       	call   80101773 <readi>
80106472:	83 c4 10             	add    $0x10,%esp
80106475:	39 f0                	cmp    %esi,%eax
80106477:	75 47                	jne    801064c0 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
80106479:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010647f:	39 fb                	cmp    %edi,%ebx
80106481:	73 30                	jae    801064b3 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80106483:	89 da                	mov    %ebx,%edx
80106485:	03 55 0c             	add    0xc(%ebp),%edx
80106488:	b9 00 00 00 00       	mov    $0x0,%ecx
8010648d:	8b 45 08             	mov    0x8(%ebp),%eax
80106490:	e8 cd fb ff ff       	call   80106062 <walkpgdir>
80106495:	85 c0                	test   %eax,%eax
80106497:	74 b7                	je     80106450 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
80106499:	8b 00                	mov    (%eax),%eax
8010649b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
801064a0:	89 fe                	mov    %edi,%esi
801064a2:	29 de                	sub    %ebx,%esi
801064a4:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801064aa:	76 b1                	jbe    8010645d <loaduvm+0x36>
      n = PGSIZE;
801064ac:	be 00 10 00 00       	mov    $0x1000,%esi
801064b1:	eb aa                	jmp    8010645d <loaduvm+0x36>
      return -1;
  }
  return 0;
801064b3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801064b8:	8d 65 f4             	lea    -0xc(%ebp),%esp
801064bb:	5b                   	pop    %ebx
801064bc:	5e                   	pop    %esi
801064bd:	5f                   	pop    %edi
801064be:	5d                   	pop    %ebp
801064bf:	c3                   	ret    
      return -1;
801064c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064c5:	eb f1                	jmp    801064b8 <loaduvm+0x91>

801064c7 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801064c7:	55                   	push   %ebp
801064c8:	89 e5                	mov    %esp,%ebp
801064ca:	57                   	push   %edi
801064cb:	56                   	push   %esi
801064cc:	53                   	push   %ebx
801064cd:	83 ec 0c             	sub    $0xc,%esp
801064d0:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801064d3:	39 7d 10             	cmp    %edi,0x10(%ebp)
801064d6:	73 11                	jae    801064e9 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
801064d8:	8b 45 10             	mov    0x10(%ebp),%eax
801064db:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801064e1:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801064e7:	eb 19                	jmp    80106502 <deallocuvm+0x3b>
    return oldsz;
801064e9:	89 f8                	mov    %edi,%eax
801064eb:	eb 64                	jmp    80106551 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
801064ed:	c1 eb 16             	shr    $0x16,%ebx
801064f0:	83 c3 01             	add    $0x1,%ebx
801064f3:	c1 e3 16             	shl    $0x16,%ebx
801064f6:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801064fc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106502:	39 fb                	cmp    %edi,%ebx
80106504:	73 48                	jae    8010654e <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
80106506:	b9 00 00 00 00       	mov    $0x0,%ecx
8010650b:	89 da                	mov    %ebx,%edx
8010650d:	8b 45 08             	mov    0x8(%ebp),%eax
80106510:	e8 4d fb ff ff       	call   80106062 <walkpgdir>
80106515:	89 c6                	mov    %eax,%esi
    if(!pte)
80106517:	85 c0                	test   %eax,%eax
80106519:	74 d2                	je     801064ed <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
8010651b:	8b 00                	mov    (%eax),%eax
8010651d:	a8 01                	test   $0x1,%al
8010651f:	74 db                	je     801064fc <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
80106521:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106526:	74 19                	je     80106541 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
80106528:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
8010652d:	83 ec 0c             	sub    $0xc,%esp
80106530:	50                   	push   %eax
80106531:	e8 78 ba ff ff       	call   80101fae <kfree>
      *pte = 0;
80106536:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
8010653c:	83 c4 10             	add    $0x10,%esp
8010653f:	eb bb                	jmp    801064fc <deallocuvm+0x35>
        panic("kfree");
80106541:	83 ec 0c             	sub    $0xc,%esp
80106544:	68 a6 6b 10 80       	push   $0x80106ba6
80106549:	e8 fa 9d ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
8010654e:	8b 45 10             	mov    0x10(%ebp),%eax
}
80106551:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106554:	5b                   	pop    %ebx
80106555:	5e                   	pop    %esi
80106556:	5f                   	pop    %edi
80106557:	5d                   	pop    %ebp
80106558:	c3                   	ret    

80106559 <allocuvm>:
{
80106559:	55                   	push   %ebp
8010655a:	89 e5                	mov    %esp,%ebp
8010655c:	57                   	push   %edi
8010655d:	56                   	push   %esi
8010655e:	53                   	push   %ebx
8010655f:	83 ec 1c             	sub    $0x1c,%esp
80106562:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
80106565:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106568:	85 ff                	test   %edi,%edi
8010656a:	0f 88 e0 00 00 00    	js     80106650 <allocuvm+0xf7>
  if(newsz < oldsz)
80106570:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106573:	73 11                	jae    80106586 <allocuvm+0x2d>
    return oldsz;
80106575:	8b 45 0c             	mov    0xc(%ebp),%eax
80106578:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}
8010657b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010657e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106581:	5b                   	pop    %ebx
80106582:	5e                   	pop    %esi
80106583:	5f                   	pop    %edi
80106584:	5d                   	pop    %ebp
80106585:	c3                   	ret    
  a = PGROUNDUP(oldsz);
80106586:	8b 45 0c             	mov    0xc(%ebp),%eax
80106589:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
8010658f:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  int pid = myproc()->pid;
80106595:	e8 50 d0 ff ff       	call   801035ea <myproc>
8010659a:	8b 40 10             	mov    0x10(%eax),%eax
8010659d:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(; a < newsz; a += PGSIZE){
801065a0:	39 fb                	cmp    %edi,%ebx
801065a2:	73 d7                	jae    8010657b <allocuvm+0x22>
    mem = kalloc(pid);
801065a4:	83 ec 0c             	sub    $0xc,%esp
801065a7:	ff 75 e0             	pushl  -0x20(%ebp)
801065aa:	e8 1f bc ff ff       	call   801021ce <kalloc>
801065af:	89 c6                	mov    %eax,%esi
    if(mem == 0){
801065b1:	83 c4 10             	add    $0x10,%esp
801065b4:	85 c0                	test   %eax,%eax
801065b6:	74 3a                	je     801065f2 <allocuvm+0x99>
    memset(mem, 0, PGSIZE);
801065b8:	83 ec 04             	sub    $0x4,%esp
801065bb:	68 00 10 00 00       	push   $0x1000
801065c0:	6a 00                	push   $0x0
801065c2:	50                   	push   %eax
801065c3:	e8 f1 da ff ff       	call   801040b9 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
801065c8:	83 c4 08             	add    $0x8,%esp
801065cb:	6a 06                	push   $0x6
801065cd:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
801065d3:	50                   	push   %eax
801065d4:	b9 00 10 00 00       	mov    $0x1000,%ecx
801065d9:	89 da                	mov    %ebx,%edx
801065db:	8b 45 08             	mov    0x8(%ebp),%eax
801065de:	e8 ef fa ff ff       	call   801060d2 <mappages>
801065e3:	83 c4 10             	add    $0x10,%esp
801065e6:	85 c0                	test   %eax,%eax
801065e8:	78 33                	js     8010661d <allocuvm+0xc4>
  for(; a < newsz; a += PGSIZE){
801065ea:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801065f0:	eb ae                	jmp    801065a0 <allocuvm+0x47>
      cprintf("allocuvm out of memory\n");
801065f2:	83 ec 0c             	sub    $0xc,%esp
801065f5:	68 89 72 10 80       	push   $0x80107289
801065fa:	e8 0c a0 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801065ff:	83 c4 0c             	add    $0xc,%esp
80106602:	ff 75 0c             	pushl  0xc(%ebp)
80106605:	57                   	push   %edi
80106606:	ff 75 08             	pushl  0x8(%ebp)
80106609:	e8 b9 fe ff ff       	call   801064c7 <deallocuvm>
      return 0;
8010660e:	83 c4 10             	add    $0x10,%esp
80106611:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106618:	e9 5e ff ff ff       	jmp    8010657b <allocuvm+0x22>
      cprintf("allocuvm out of memory (2)\n");
8010661d:	83 ec 0c             	sub    $0xc,%esp
80106620:	68 a1 72 10 80       	push   $0x801072a1
80106625:	e8 e1 9f ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010662a:	83 c4 0c             	add    $0xc,%esp
8010662d:	ff 75 0c             	pushl  0xc(%ebp)
80106630:	57                   	push   %edi
80106631:	ff 75 08             	pushl  0x8(%ebp)
80106634:	e8 8e fe ff ff       	call   801064c7 <deallocuvm>
      kfree(mem);
80106639:	89 34 24             	mov    %esi,(%esp)
8010663c:	e8 6d b9 ff ff       	call   80101fae <kfree>
      return 0;
80106641:	83 c4 10             	add    $0x10,%esp
80106644:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010664b:	e9 2b ff ff ff       	jmp    8010657b <allocuvm+0x22>
    return 0;
80106650:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106657:	e9 1f ff ff ff       	jmp    8010657b <allocuvm+0x22>

8010665c <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
8010665c:	55                   	push   %ebp
8010665d:	89 e5                	mov    %esp,%ebp
8010665f:	56                   	push   %esi
80106660:	53                   	push   %ebx
80106661:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
80106664:	85 f6                	test   %esi,%esi
80106666:	74 1a                	je     80106682 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
80106668:	83 ec 04             	sub    $0x4,%esp
8010666b:	6a 00                	push   $0x0
8010666d:	68 00 00 00 80       	push   $0x80000000
80106672:	56                   	push   %esi
80106673:	e8 4f fe ff ff       	call   801064c7 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80106678:	83 c4 10             	add    $0x10,%esp
8010667b:	bb 00 00 00 00       	mov    $0x0,%ebx
80106680:	eb 10                	jmp    80106692 <freevm+0x36>
    panic("freevm: no pgdir");
80106682:	83 ec 0c             	sub    $0xc,%esp
80106685:	68 bd 72 10 80       	push   $0x801072bd
8010668a:	e8 b9 9c ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
8010668f:	83 c3 01             	add    $0x1,%ebx
80106692:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
80106698:	77 1f                	ja     801066b9 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
8010669a:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
8010669d:	a8 01                	test   $0x1,%al
8010669f:	74 ee                	je     8010668f <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801066a1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801066a6:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801066ab:	83 ec 0c             	sub    $0xc,%esp
801066ae:	50                   	push   %eax
801066af:	e8 fa b8 ff ff       	call   80101fae <kfree>
801066b4:	83 c4 10             	add    $0x10,%esp
801066b7:	eb d6                	jmp    8010668f <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
801066b9:	83 ec 0c             	sub    $0xc,%esp
801066bc:	56                   	push   %esi
801066bd:	e8 ec b8 ff ff       	call   80101fae <kfree>
}
801066c2:	83 c4 10             	add    $0x10,%esp
801066c5:	8d 65 f8             	lea    -0x8(%ebp),%esp
801066c8:	5b                   	pop    %ebx
801066c9:	5e                   	pop    %esi
801066ca:	5d                   	pop    %ebp
801066cb:	c3                   	ret    

801066cc <setupkvm>:
{
801066cc:	55                   	push   %ebp
801066cd:	89 e5                	mov    %esp,%ebp
801066cf:	56                   	push   %esi
801066d0:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc2()) == 0)
801066d1:	e8 b5 bc ff ff       	call   8010238b <kalloc2>
801066d6:	89 c6                	mov    %eax,%esi
801066d8:	85 c0                	test   %eax,%eax
801066da:	74 55                	je     80106731 <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
801066dc:	83 ec 04             	sub    $0x4,%esp
801066df:	68 00 10 00 00       	push   $0x1000
801066e4:	6a 00                	push   $0x0
801066e6:	50                   	push   %eax
801066e7:	e8 cd d9 ff ff       	call   801040b9 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801066ec:	83 c4 10             	add    $0x10,%esp
801066ef:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
801066f4:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
801066fa:	73 35                	jae    80106731 <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
801066fc:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
801066ff:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106702:	29 c1                	sub    %eax,%ecx
80106704:	83 ec 08             	sub    $0x8,%esp
80106707:	ff 73 0c             	pushl  0xc(%ebx)
8010670a:	50                   	push   %eax
8010670b:	8b 13                	mov    (%ebx),%edx
8010670d:	89 f0                	mov    %esi,%eax
8010670f:	e8 be f9 ff ff       	call   801060d2 <mappages>
80106714:	83 c4 10             	add    $0x10,%esp
80106717:	85 c0                	test   %eax,%eax
80106719:	78 05                	js     80106720 <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010671b:	83 c3 10             	add    $0x10,%ebx
8010671e:	eb d4                	jmp    801066f4 <setupkvm+0x28>
      freevm(pgdir);
80106720:	83 ec 0c             	sub    $0xc,%esp
80106723:	56                   	push   %esi
80106724:	e8 33 ff ff ff       	call   8010665c <freevm>
      return 0;
80106729:	83 c4 10             	add    $0x10,%esp
8010672c:	be 00 00 00 00       	mov    $0x0,%esi
}
80106731:	89 f0                	mov    %esi,%eax
80106733:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106736:	5b                   	pop    %ebx
80106737:	5e                   	pop    %esi
80106738:	5d                   	pop    %ebp
80106739:	c3                   	ret    

8010673a <kvmalloc>:
{
8010673a:	55                   	push   %ebp
8010673b:	89 e5                	mov    %esp,%ebp
8010673d:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80106740:	e8 87 ff ff ff       	call   801066cc <setupkvm>
80106745:	a3 c4 54 15 80       	mov    %eax,0x801554c4
  switchkvm();
8010674a:	e8 45 fb ff ff       	call   80106294 <switchkvm>
}
8010674f:	c9                   	leave  
80106750:	c3                   	ret    

80106751 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106751:	55                   	push   %ebp
80106752:	89 e5                	mov    %esp,%ebp
80106754:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106757:	b9 00 00 00 00       	mov    $0x0,%ecx
8010675c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010675f:	8b 45 08             	mov    0x8(%ebp),%eax
80106762:	e8 fb f8 ff ff       	call   80106062 <walkpgdir>
  if(pte == 0)
80106767:	85 c0                	test   %eax,%eax
80106769:	74 05                	je     80106770 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
8010676b:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
8010676e:	c9                   	leave  
8010676f:	c3                   	ret    
    panic("clearpteu");
80106770:	83 ec 0c             	sub    $0xc,%esp
80106773:	68 ce 72 10 80       	push   $0x801072ce
80106778:	e8 cb 9b ff ff       	call   80100348 <panic>

8010677d <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010677d:	55                   	push   %ebp
8010677e:	89 e5                	mov    %esp,%ebp
80106780:	57                   	push   %edi
80106781:	56                   	push   %esi
80106782:	53                   	push   %ebx
80106783:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80106786:	e8 41 ff ff ff       	call   801066cc <setupkvm>
8010678b:	89 45 dc             	mov    %eax,-0x24(%ebp)
8010678e:	85 c0                	test   %eax,%eax
80106790:	0f 84 d2 00 00 00    	je     80106868 <copyuvm+0xeb>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80106796:	bf 00 00 00 00       	mov    $0x0,%edi
8010679b:	3b 7d 0c             	cmp    0xc(%ebp),%edi
8010679e:	0f 83 c4 00 00 00    	jae    80106868 <copyuvm+0xeb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801067a4:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801067a7:	b9 00 00 00 00       	mov    $0x0,%ecx
801067ac:	89 fa                	mov    %edi,%edx
801067ae:	8b 45 08             	mov    0x8(%ebp),%eax
801067b1:	e8 ac f8 ff ff       	call   80106062 <walkpgdir>
801067b6:	85 c0                	test   %eax,%eax
801067b8:	74 73                	je     8010682d <copyuvm+0xb0>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
801067ba:	8b 00                	mov    (%eax),%eax
801067bc:	a8 01                	test   $0x1,%al
801067be:	74 7a                	je     8010683a <copyuvm+0xbd>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
801067c0:	89 c6                	mov    %eax,%esi
801067c2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
801067c8:	25 ff 0f 00 00       	and    $0xfff,%eax
801067cd:	89 45 e0             	mov    %eax,-0x20(%ebp)
    // manipulate this call to kalloc. Need to pass the pid?
    int pid = myproc()->pid;
801067d0:	e8 15 ce ff ff       	call   801035ea <myproc>

    if((mem = kalloc(pid)) == 0)
801067d5:	83 ec 0c             	sub    $0xc,%esp
801067d8:	ff 70 10             	pushl  0x10(%eax)
801067db:	e8 ee b9 ff ff       	call   801021ce <kalloc>
801067e0:	89 c3                	mov    %eax,%ebx
801067e2:	83 c4 10             	add    $0x10,%esp
801067e5:	85 c0                	test   %eax,%eax
801067e7:	74 6a                	je     80106853 <copyuvm+0xd6>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801067e9:	81 c6 00 00 00 80    	add    $0x80000000,%esi
801067ef:	83 ec 04             	sub    $0x4,%esp
801067f2:	68 00 10 00 00       	push   $0x1000
801067f7:	56                   	push   %esi
801067f8:	50                   	push   %eax
801067f9:	e8 36 d9 ff ff       	call   80104134 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
801067fe:	83 c4 08             	add    $0x8,%esp
80106801:	ff 75 e0             	pushl  -0x20(%ebp)
80106804:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010680a:	50                   	push   %eax
8010680b:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106810:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106813:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106816:	e8 b7 f8 ff ff       	call   801060d2 <mappages>
8010681b:	83 c4 10             	add    $0x10,%esp
8010681e:	85 c0                	test   %eax,%eax
80106820:	78 25                	js     80106847 <copyuvm+0xca>
  for(i = 0; i < sz; i += PGSIZE){
80106822:	81 c7 00 10 00 00    	add    $0x1000,%edi
80106828:	e9 6e ff ff ff       	jmp    8010679b <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
8010682d:	83 ec 0c             	sub    $0xc,%esp
80106830:	68 d8 72 10 80       	push   $0x801072d8
80106835:	e8 0e 9b ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
8010683a:	83 ec 0c             	sub    $0xc,%esp
8010683d:	68 f2 72 10 80       	push   $0x801072f2
80106842:	e8 01 9b ff ff       	call   80100348 <panic>
      kfree(mem);
80106847:	83 ec 0c             	sub    $0xc,%esp
8010684a:	53                   	push   %ebx
8010684b:	e8 5e b7 ff ff       	call   80101fae <kfree>
      goto bad;
80106850:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106853:	83 ec 0c             	sub    $0xc,%esp
80106856:	ff 75 dc             	pushl  -0x24(%ebp)
80106859:	e8 fe fd ff ff       	call   8010665c <freevm>
  return 0;
8010685e:	83 c4 10             	add    $0x10,%esp
80106861:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
80106868:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010686b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010686e:	5b                   	pop    %ebx
8010686f:	5e                   	pop    %esi
80106870:	5f                   	pop    %edi
80106871:	5d                   	pop    %ebp
80106872:	c3                   	ret    

80106873 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106873:	55                   	push   %ebp
80106874:	89 e5                	mov    %esp,%ebp
80106876:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106879:	b9 00 00 00 00       	mov    $0x0,%ecx
8010687e:	8b 55 0c             	mov    0xc(%ebp),%edx
80106881:	8b 45 08             	mov    0x8(%ebp),%eax
80106884:	e8 d9 f7 ff ff       	call   80106062 <walkpgdir>
  if((*pte & PTE_P) == 0)
80106889:	8b 00                	mov    (%eax),%eax
8010688b:	a8 01                	test   $0x1,%al
8010688d:	74 10                	je     8010689f <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
8010688f:	a8 04                	test   $0x4,%al
80106891:	74 13                	je     801068a6 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106893:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106898:	05 00 00 00 80       	add    $0x80000000,%eax
}
8010689d:	c9                   	leave  
8010689e:	c3                   	ret    
    return 0;
8010689f:	b8 00 00 00 00       	mov    $0x0,%eax
801068a4:	eb f7                	jmp    8010689d <uva2ka+0x2a>
    return 0;
801068a6:	b8 00 00 00 00       	mov    $0x0,%eax
801068ab:	eb f0                	jmp    8010689d <uva2ka+0x2a>

801068ad <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801068ad:	55                   	push   %ebp
801068ae:	89 e5                	mov    %esp,%ebp
801068b0:	57                   	push   %edi
801068b1:	56                   	push   %esi
801068b2:	53                   	push   %ebx
801068b3:	83 ec 0c             	sub    $0xc,%esp
801068b6:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801068b9:	eb 25                	jmp    801068e0 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801068bb:	8b 55 0c             	mov    0xc(%ebp),%edx
801068be:	29 f2                	sub    %esi,%edx
801068c0:	01 d0                	add    %edx,%eax
801068c2:	83 ec 04             	sub    $0x4,%esp
801068c5:	53                   	push   %ebx
801068c6:	ff 75 10             	pushl  0x10(%ebp)
801068c9:	50                   	push   %eax
801068ca:	e8 65 d8 ff ff       	call   80104134 <memmove>
    len -= n;
801068cf:	29 df                	sub    %ebx,%edi
    buf += n;
801068d1:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801068d4:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801068da:	89 45 0c             	mov    %eax,0xc(%ebp)
801068dd:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
801068e0:	85 ff                	test   %edi,%edi
801068e2:	74 2f                	je     80106913 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
801068e4:	8b 75 0c             	mov    0xc(%ebp),%esi
801068e7:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
801068ed:	83 ec 08             	sub    $0x8,%esp
801068f0:	56                   	push   %esi
801068f1:	ff 75 08             	pushl  0x8(%ebp)
801068f4:	e8 7a ff ff ff       	call   80106873 <uva2ka>
    if(pa0 == 0)
801068f9:	83 c4 10             	add    $0x10,%esp
801068fc:	85 c0                	test   %eax,%eax
801068fe:	74 20                	je     80106920 <copyout+0x73>
    n = PGSIZE - (va - va0);
80106900:	89 f3                	mov    %esi,%ebx
80106902:	2b 5d 0c             	sub    0xc(%ebp),%ebx
80106905:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
8010690b:	39 df                	cmp    %ebx,%edi
8010690d:	73 ac                	jae    801068bb <copyout+0xe>
      n = len;
8010690f:	89 fb                	mov    %edi,%ebx
80106911:	eb a8                	jmp    801068bb <copyout+0xe>
  }
  return 0;
80106913:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106918:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010691b:	5b                   	pop    %ebx
8010691c:	5e                   	pop    %esi
8010691d:	5f                   	pop    %edi
8010691e:	5d                   	pop    %ebp
8010691f:	c3                   	ret    
      return -1;
80106920:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106925:	eb f1                	jmp    80106918 <copyout+0x6b>
