
_v1atest1:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:
#include "stat.h"
#include "user.h"

int
main(int argc, char *argv[])
{
   0:	8d 4c 24 04          	lea    0x4(%esp),%ecx
   4:	83 e4 f0             	and    $0xfffffff0,%esp
   7:	ff 71 fc             	pushl  -0x4(%ecx)
   a:	55                   	push   %ebp
   b:	89 e5                	mov    %esp,%ebp
   d:	57                   	push   %edi
   e:	56                   	push   %esi
   f:	53                   	push   %ebx
  10:	51                   	push   %ecx
  11:	83 ec 14             	sub    $0x14,%esp
    int numframes = 100;
    int* frames = malloc(numframes * sizeof(int));
  14:	68 90 01 00 00       	push   $0x190
  19:	e8 65 05 00 00       	call   583 <malloc>
  1e:	89 c6                	mov    %eax,%esi
    int* pids = malloc(numframes * sizeof(int));
  20:	c7 04 24 90 01 00 00 	movl   $0x190,(%esp)
  27:	e8 57 05 00 00       	call   583 <malloc>
  2c:	89 c7                	mov    %eax,%edi
    frames[0] = 1;
  2e:	c7 06 01 00 00 00    	movl   $0x1,(%esi)
    int flag = dump_physmem(frames, pids, numframes);
  34:	83 c4 0c             	add    $0xc,%esp
  37:	6a 64                	push   $0x64
  39:	50                   	push   %eax
  3a:	56                   	push   %esi
  3b:	e8 78 02 00 00       	call   2b8 <dump_physmem>
  40:	89 c3                	mov    %eax,%ebx

    if(flag == 0)
  42:	83 c4 10             	add    $0x10,%esp
  45:	85 c0                	test   %eax,%eax
  47:	74 33                	je     7c <main+0x7c>

            printf(0,"Frames: %x PIDs: %d\n", *(frames+i), *(pids+i));
    }
    else// if(flag == -1)
    {
        printf(0,"error\n");
  49:	83 ec 08             	sub    $0x8,%esp
  4c:	68 29 06 00 00       	push   $0x629
  51:	6a 00                	push   $0x0
  53:	e8 02 03 00 00       	call   35a <printf>
  58:	83 c4 10             	add    $0x10,%esp
  5b:	eb 24                	jmp    81 <main+0x81>
            printf(0,"Frames: %x PIDs: %d\n", *(frames+i), *(pids+i));
  5d:	8d 04 9d 00 00 00 00 	lea    0x0(,%ebx,4),%eax
  64:	ff 34 07             	pushl  (%edi,%eax,1)
  67:	ff 34 06             	pushl  (%esi,%eax,1)
  6a:	68 14 06 00 00       	push   $0x614
  6f:	6a 00                	push   $0x0
  71:	e8 e4 02 00 00       	call   35a <printf>
        for (int i = 0; i < numframes; i++)
  76:	83 c3 01             	add    $0x1,%ebx
  79:	83 c4 10             	add    $0x10,%esp
  7c:	83 fb 63             	cmp    $0x63,%ebx
  7f:	7e dc                	jle    5d <main+0x5d>
    }
    wait();
  81:	e8 9a 01 00 00       	call   220 <wait>
    exit();
  86:	e8 8d 01 00 00       	call   218 <exit>

0000008b <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, const char *t)
{
  8b:	55                   	push   %ebp
  8c:	89 e5                	mov    %esp,%ebp
  8e:	53                   	push   %ebx
  8f:	8b 45 08             	mov    0x8(%ebp),%eax
  92:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  95:	89 c2                	mov    %eax,%edx
  97:	0f b6 19             	movzbl (%ecx),%ebx
  9a:	88 1a                	mov    %bl,(%edx)
  9c:	8d 52 01             	lea    0x1(%edx),%edx
  9f:	8d 49 01             	lea    0x1(%ecx),%ecx
  a2:	84 db                	test   %bl,%bl
  a4:	75 f1                	jne    97 <strcpy+0xc>
    ;
  return os;
}
  a6:	5b                   	pop    %ebx
  a7:	5d                   	pop    %ebp
  a8:	c3                   	ret    

000000a9 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  a9:	55                   	push   %ebp
  aa:	89 e5                	mov    %esp,%ebp
  ac:	8b 4d 08             	mov    0x8(%ebp),%ecx
  af:	8b 55 0c             	mov    0xc(%ebp),%edx
  while(*p && *p == *q)
  b2:	eb 06                	jmp    ba <strcmp+0x11>
    p++, q++;
  b4:	83 c1 01             	add    $0x1,%ecx
  b7:	83 c2 01             	add    $0x1,%edx
  while(*p && *p == *q)
  ba:	0f b6 01             	movzbl (%ecx),%eax
  bd:	84 c0                	test   %al,%al
  bf:	74 04                	je     c5 <strcmp+0x1c>
  c1:	3a 02                	cmp    (%edx),%al
  c3:	74 ef                	je     b4 <strcmp+0xb>
  return (uchar)*p - (uchar)*q;
  c5:	0f b6 c0             	movzbl %al,%eax
  c8:	0f b6 12             	movzbl (%edx),%edx
  cb:	29 d0                	sub    %edx,%eax
}
  cd:	5d                   	pop    %ebp
  ce:	c3                   	ret    

000000cf <strlen>:

uint
strlen(const char *s)
{
  cf:	55                   	push   %ebp
  d0:	89 e5                	mov    %esp,%ebp
  d2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  for(n = 0; s[n]; n++)
  d5:	ba 00 00 00 00       	mov    $0x0,%edx
  da:	eb 03                	jmp    df <strlen+0x10>
  dc:	83 c2 01             	add    $0x1,%edx
  df:	89 d0                	mov    %edx,%eax
  e1:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  e5:	75 f5                	jne    dc <strlen+0xd>
    ;
  return n;
}
  e7:	5d                   	pop    %ebp
  e8:	c3                   	ret    

000000e9 <memset>:

void*
memset(void *dst, int c, uint n)
{
  e9:	55                   	push   %ebp
  ea:	89 e5                	mov    %esp,%ebp
  ec:	57                   	push   %edi
  ed:	8b 55 08             	mov    0x8(%ebp),%edx
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
  f0:	89 d7                	mov    %edx,%edi
  f2:	8b 4d 10             	mov    0x10(%ebp),%ecx
  f5:	8b 45 0c             	mov    0xc(%ebp),%eax
  f8:	fc                   	cld    
  f9:	f3 aa                	rep stos %al,%es:(%edi)
  stosb(dst, c, n);
  return dst;
}
  fb:	89 d0                	mov    %edx,%eax
  fd:	5f                   	pop    %edi
  fe:	5d                   	pop    %ebp
  ff:	c3                   	ret    

00000100 <strchr>:

char*
strchr(const char *s, char c)
{
 100:	55                   	push   %ebp
 101:	89 e5                	mov    %esp,%ebp
 103:	8b 45 08             	mov    0x8(%ebp),%eax
 106:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
  for(; *s; s++)
 10a:	0f b6 10             	movzbl (%eax),%edx
 10d:	84 d2                	test   %dl,%dl
 10f:	74 09                	je     11a <strchr+0x1a>
    if(*s == c)
 111:	38 ca                	cmp    %cl,%dl
 113:	74 0a                	je     11f <strchr+0x1f>
  for(; *s; s++)
 115:	83 c0 01             	add    $0x1,%eax
 118:	eb f0                	jmp    10a <strchr+0xa>
      return (char*)s;
  return 0;
 11a:	b8 00 00 00 00       	mov    $0x0,%eax
}
 11f:	5d                   	pop    %ebp
 120:	c3                   	ret    

00000121 <gets>:

char*
gets(char *buf, int max)
{
 121:	55                   	push   %ebp
 122:	89 e5                	mov    %esp,%ebp
 124:	57                   	push   %edi
 125:	56                   	push   %esi
 126:	53                   	push   %ebx
 127:	83 ec 1c             	sub    $0x1c,%esp
 12a:	8b 7d 08             	mov    0x8(%ebp),%edi
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 12d:	bb 00 00 00 00       	mov    $0x0,%ebx
 132:	8d 73 01             	lea    0x1(%ebx),%esi
 135:	3b 75 0c             	cmp    0xc(%ebp),%esi
 138:	7d 2e                	jge    168 <gets+0x47>
    cc = read(0, &c, 1);
 13a:	83 ec 04             	sub    $0x4,%esp
 13d:	6a 01                	push   $0x1
 13f:	8d 45 e7             	lea    -0x19(%ebp),%eax
 142:	50                   	push   %eax
 143:	6a 00                	push   $0x0
 145:	e8 e6 00 00 00       	call   230 <read>
    if(cc < 1)
 14a:	83 c4 10             	add    $0x10,%esp
 14d:	85 c0                	test   %eax,%eax
 14f:	7e 17                	jle    168 <gets+0x47>
      break;
    buf[i++] = c;
 151:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
 155:	88 04 1f             	mov    %al,(%edi,%ebx,1)
    if(c == '\n' || c == '\r')
 158:	3c 0a                	cmp    $0xa,%al
 15a:	0f 94 c2             	sete   %dl
 15d:	3c 0d                	cmp    $0xd,%al
 15f:	0f 94 c0             	sete   %al
    buf[i++] = c;
 162:	89 f3                	mov    %esi,%ebx
    if(c == '\n' || c == '\r')
 164:	08 c2                	or     %al,%dl
 166:	74 ca                	je     132 <gets+0x11>
      break;
  }
  buf[i] = '\0';
 168:	c6 04 1f 00          	movb   $0x0,(%edi,%ebx,1)
  return buf;
}
 16c:	89 f8                	mov    %edi,%eax
 16e:	8d 65 f4             	lea    -0xc(%ebp),%esp
 171:	5b                   	pop    %ebx
 172:	5e                   	pop    %esi
 173:	5f                   	pop    %edi
 174:	5d                   	pop    %ebp
 175:	c3                   	ret    

00000176 <stat>:

int
stat(const char *n, struct stat *st)
{
 176:	55                   	push   %ebp
 177:	89 e5                	mov    %esp,%ebp
 179:	56                   	push   %esi
 17a:	53                   	push   %ebx
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 17b:	83 ec 08             	sub    $0x8,%esp
 17e:	6a 00                	push   $0x0
 180:	ff 75 08             	pushl  0x8(%ebp)
 183:	e8 d0 00 00 00       	call   258 <open>
  if(fd < 0)
 188:	83 c4 10             	add    $0x10,%esp
 18b:	85 c0                	test   %eax,%eax
 18d:	78 24                	js     1b3 <stat+0x3d>
 18f:	89 c3                	mov    %eax,%ebx
    return -1;
  r = fstat(fd, st);
 191:	83 ec 08             	sub    $0x8,%esp
 194:	ff 75 0c             	pushl  0xc(%ebp)
 197:	50                   	push   %eax
 198:	e8 d3 00 00 00       	call   270 <fstat>
 19d:	89 c6                	mov    %eax,%esi
  close(fd);
 19f:	89 1c 24             	mov    %ebx,(%esp)
 1a2:	e8 99 00 00 00       	call   240 <close>
  return r;
 1a7:	83 c4 10             	add    $0x10,%esp
}
 1aa:	89 f0                	mov    %esi,%eax
 1ac:	8d 65 f8             	lea    -0x8(%ebp),%esp
 1af:	5b                   	pop    %ebx
 1b0:	5e                   	pop    %esi
 1b1:	5d                   	pop    %ebp
 1b2:	c3                   	ret    
    return -1;
 1b3:	be ff ff ff ff       	mov    $0xffffffff,%esi
 1b8:	eb f0                	jmp    1aa <stat+0x34>

000001ba <atoi>:

int
atoi(const char *s)
{
 1ba:	55                   	push   %ebp
 1bb:	89 e5                	mov    %esp,%ebp
 1bd:	53                   	push   %ebx
 1be:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  n = 0;
 1c1:	b8 00 00 00 00       	mov    $0x0,%eax
  while('0' <= *s && *s <= '9')
 1c6:	eb 10                	jmp    1d8 <atoi+0x1e>
    n = n*10 + *s++ - '0';
 1c8:	8d 1c 80             	lea    (%eax,%eax,4),%ebx
 1cb:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
 1ce:	83 c1 01             	add    $0x1,%ecx
 1d1:	0f be d2             	movsbl %dl,%edx
 1d4:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
  while('0' <= *s && *s <= '9')
 1d8:	0f b6 11             	movzbl (%ecx),%edx
 1db:	8d 5a d0             	lea    -0x30(%edx),%ebx
 1de:	80 fb 09             	cmp    $0x9,%bl
 1e1:	76 e5                	jbe    1c8 <atoi+0xe>
  return n;
}
 1e3:	5b                   	pop    %ebx
 1e4:	5d                   	pop    %ebp
 1e5:	c3                   	ret    

000001e6 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1e6:	55                   	push   %ebp
 1e7:	89 e5                	mov    %esp,%ebp
 1e9:	56                   	push   %esi
 1ea:	53                   	push   %ebx
 1eb:	8b 45 08             	mov    0x8(%ebp),%eax
 1ee:	8b 5d 0c             	mov    0xc(%ebp),%ebx
 1f1:	8b 55 10             	mov    0x10(%ebp),%edx
  char *dst;
  const char *src;

  dst = vdst;
 1f4:	89 c1                	mov    %eax,%ecx
  src = vsrc;
  while(n-- > 0)
 1f6:	eb 0d                	jmp    205 <memmove+0x1f>
    *dst++ = *src++;
 1f8:	0f b6 13             	movzbl (%ebx),%edx
 1fb:	88 11                	mov    %dl,(%ecx)
 1fd:	8d 5b 01             	lea    0x1(%ebx),%ebx
 200:	8d 49 01             	lea    0x1(%ecx),%ecx
  while(n-- > 0)
 203:	89 f2                	mov    %esi,%edx
 205:	8d 72 ff             	lea    -0x1(%edx),%esi
 208:	85 d2                	test   %edx,%edx
 20a:	7f ec                	jg     1f8 <memmove+0x12>
  return vdst;
}
 20c:	5b                   	pop    %ebx
 20d:	5e                   	pop    %esi
 20e:	5d                   	pop    %ebp
 20f:	c3                   	ret    

00000210 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 210:	b8 01 00 00 00       	mov    $0x1,%eax
 215:	cd 40                	int    $0x40
 217:	c3                   	ret    

00000218 <exit>:
SYSCALL(exit)
 218:	b8 02 00 00 00       	mov    $0x2,%eax
 21d:	cd 40                	int    $0x40
 21f:	c3                   	ret    

00000220 <wait>:
SYSCALL(wait)
 220:	b8 03 00 00 00       	mov    $0x3,%eax
 225:	cd 40                	int    $0x40
 227:	c3                   	ret    

00000228 <pipe>:
SYSCALL(pipe)
 228:	b8 04 00 00 00       	mov    $0x4,%eax
 22d:	cd 40                	int    $0x40
 22f:	c3                   	ret    

00000230 <read>:
SYSCALL(read)
 230:	b8 05 00 00 00       	mov    $0x5,%eax
 235:	cd 40                	int    $0x40
 237:	c3                   	ret    

00000238 <write>:
SYSCALL(write)
 238:	b8 10 00 00 00       	mov    $0x10,%eax
 23d:	cd 40                	int    $0x40
 23f:	c3                   	ret    

00000240 <close>:
SYSCALL(close)
 240:	b8 15 00 00 00       	mov    $0x15,%eax
 245:	cd 40                	int    $0x40
 247:	c3                   	ret    

00000248 <kill>:
SYSCALL(kill)
 248:	b8 06 00 00 00       	mov    $0x6,%eax
 24d:	cd 40                	int    $0x40
 24f:	c3                   	ret    

00000250 <exec>:
SYSCALL(exec)
 250:	b8 07 00 00 00       	mov    $0x7,%eax
 255:	cd 40                	int    $0x40
 257:	c3                   	ret    

00000258 <open>:
SYSCALL(open)
 258:	b8 0f 00 00 00       	mov    $0xf,%eax
 25d:	cd 40                	int    $0x40
 25f:	c3                   	ret    

00000260 <mknod>:
SYSCALL(mknod)
 260:	b8 11 00 00 00       	mov    $0x11,%eax
 265:	cd 40                	int    $0x40
 267:	c3                   	ret    

00000268 <unlink>:
SYSCALL(unlink)
 268:	b8 12 00 00 00       	mov    $0x12,%eax
 26d:	cd 40                	int    $0x40
 26f:	c3                   	ret    

00000270 <fstat>:
SYSCALL(fstat)
 270:	b8 08 00 00 00       	mov    $0x8,%eax
 275:	cd 40                	int    $0x40
 277:	c3                   	ret    

00000278 <link>:
SYSCALL(link)
 278:	b8 13 00 00 00       	mov    $0x13,%eax
 27d:	cd 40                	int    $0x40
 27f:	c3                   	ret    

00000280 <mkdir>:
SYSCALL(mkdir)
 280:	b8 14 00 00 00       	mov    $0x14,%eax
 285:	cd 40                	int    $0x40
 287:	c3                   	ret    

00000288 <chdir>:
SYSCALL(chdir)
 288:	b8 09 00 00 00       	mov    $0x9,%eax
 28d:	cd 40                	int    $0x40
 28f:	c3                   	ret    

00000290 <dup>:
SYSCALL(dup)
 290:	b8 0a 00 00 00       	mov    $0xa,%eax
 295:	cd 40                	int    $0x40
 297:	c3                   	ret    

00000298 <getpid>:
SYSCALL(getpid)
 298:	b8 0b 00 00 00       	mov    $0xb,%eax
 29d:	cd 40                	int    $0x40
 29f:	c3                   	ret    

000002a0 <sbrk>:
SYSCALL(sbrk)
 2a0:	b8 0c 00 00 00       	mov    $0xc,%eax
 2a5:	cd 40                	int    $0x40
 2a7:	c3                   	ret    

000002a8 <sleep>:
SYSCALL(sleep)
 2a8:	b8 0d 00 00 00       	mov    $0xd,%eax
 2ad:	cd 40                	int    $0x40
 2af:	c3                   	ret    

000002b0 <uptime>:
SYSCALL(uptime)
 2b0:	b8 0e 00 00 00       	mov    $0xe,%eax
 2b5:	cd 40                	int    $0x40
 2b7:	c3                   	ret    

000002b8 <dump_physmem>:
 2b8:	b8 16 00 00 00       	mov    $0x16,%eax
 2bd:	cd 40                	int    $0x40
 2bf:	c3                   	ret    

000002c0 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 2c0:	55                   	push   %ebp
 2c1:	89 e5                	mov    %esp,%ebp
 2c3:	83 ec 1c             	sub    $0x1c,%esp
 2c6:	88 55 f4             	mov    %dl,-0xc(%ebp)
  write(fd, &c, 1);
 2c9:	6a 01                	push   $0x1
 2cb:	8d 55 f4             	lea    -0xc(%ebp),%edx
 2ce:	52                   	push   %edx
 2cf:	50                   	push   %eax
 2d0:	e8 63 ff ff ff       	call   238 <write>
}
 2d5:	83 c4 10             	add    $0x10,%esp
 2d8:	c9                   	leave  
 2d9:	c3                   	ret    

000002da <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 2da:	55                   	push   %ebp
 2db:	89 e5                	mov    %esp,%ebp
 2dd:	57                   	push   %edi
 2de:	56                   	push   %esi
 2df:	53                   	push   %ebx
 2e0:	83 ec 2c             	sub    $0x2c,%esp
 2e3:	89 c7                	mov    %eax,%edi
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 2e5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
 2e9:	0f 95 c3             	setne  %bl
 2ec:	89 d0                	mov    %edx,%eax
 2ee:	c1 e8 1f             	shr    $0x1f,%eax
 2f1:	84 c3                	test   %al,%bl
 2f3:	74 10                	je     305 <printint+0x2b>
    neg = 1;
    x = -xx;
 2f5:	f7 da                	neg    %edx
    neg = 1;
 2f7:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  } else {
    x = xx;
  }

  i = 0;
 2fe:	be 00 00 00 00       	mov    $0x0,%esi
 303:	eb 0b                	jmp    310 <printint+0x36>
  neg = 0;
 305:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
 30c:	eb f0                	jmp    2fe <printint+0x24>
  do{
    buf[i++] = digits[x % base];
 30e:	89 c6                	mov    %eax,%esi
 310:	89 d0                	mov    %edx,%eax
 312:	ba 00 00 00 00       	mov    $0x0,%edx
 317:	f7 f1                	div    %ecx
 319:	89 c3                	mov    %eax,%ebx
 31b:	8d 46 01             	lea    0x1(%esi),%eax
 31e:	0f b6 92 38 06 00 00 	movzbl 0x638(%edx),%edx
 325:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
 329:	89 da                	mov    %ebx,%edx
 32b:	85 db                	test   %ebx,%ebx
 32d:	75 df                	jne    30e <printint+0x34>
 32f:	89 c3                	mov    %eax,%ebx
  if(neg)
 331:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
 335:	74 16                	je     34d <printint+0x73>
    buf[i++] = '-';
 337:	c6 44 05 d8 2d       	movb   $0x2d,-0x28(%ebp,%eax,1)
 33c:	8d 5e 02             	lea    0x2(%esi),%ebx
 33f:	eb 0c                	jmp    34d <printint+0x73>

  while(--i >= 0)
    putc(fd, buf[i]);
 341:	0f be 54 1d d8       	movsbl -0x28(%ebp,%ebx,1),%edx
 346:	89 f8                	mov    %edi,%eax
 348:	e8 73 ff ff ff       	call   2c0 <putc>
  while(--i >= 0)
 34d:	83 eb 01             	sub    $0x1,%ebx
 350:	79 ef                	jns    341 <printint+0x67>
}
 352:	83 c4 2c             	add    $0x2c,%esp
 355:	5b                   	pop    %ebx
 356:	5e                   	pop    %esi
 357:	5f                   	pop    %edi
 358:	5d                   	pop    %ebp
 359:	c3                   	ret    

0000035a <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, const char *fmt, ...)
{
 35a:	55                   	push   %ebp
 35b:	89 e5                	mov    %esp,%ebp
 35d:	57                   	push   %edi
 35e:	56                   	push   %esi
 35f:	53                   	push   %ebx
 360:	83 ec 1c             	sub    $0x1c,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
 363:	8d 45 10             	lea    0x10(%ebp),%eax
 366:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  state = 0;
 369:	be 00 00 00 00       	mov    $0x0,%esi
  for(i = 0; fmt[i]; i++){
 36e:	bb 00 00 00 00       	mov    $0x0,%ebx
 373:	eb 14                	jmp    389 <printf+0x2f>
    c = fmt[i] & 0xff;
    if(state == 0){
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
 375:	89 fa                	mov    %edi,%edx
 377:	8b 45 08             	mov    0x8(%ebp),%eax
 37a:	e8 41 ff ff ff       	call   2c0 <putc>
 37f:	eb 05                	jmp    386 <printf+0x2c>
      }
    } else if(state == '%'){
 381:	83 fe 25             	cmp    $0x25,%esi
 384:	74 25                	je     3ab <printf+0x51>
  for(i = 0; fmt[i]; i++){
 386:	83 c3 01             	add    $0x1,%ebx
 389:	8b 45 0c             	mov    0xc(%ebp),%eax
 38c:	0f b6 04 18          	movzbl (%eax,%ebx,1),%eax
 390:	84 c0                	test   %al,%al
 392:	0f 84 23 01 00 00    	je     4bb <printf+0x161>
    c = fmt[i] & 0xff;
 398:	0f be f8             	movsbl %al,%edi
 39b:	0f b6 c0             	movzbl %al,%eax
    if(state == 0){
 39e:	85 f6                	test   %esi,%esi
 3a0:	75 df                	jne    381 <printf+0x27>
      if(c == '%'){
 3a2:	83 f8 25             	cmp    $0x25,%eax
 3a5:	75 ce                	jne    375 <printf+0x1b>
        state = '%';
 3a7:	89 c6                	mov    %eax,%esi
 3a9:	eb db                	jmp    386 <printf+0x2c>
      if(c == 'd'){
 3ab:	83 f8 64             	cmp    $0x64,%eax
 3ae:	74 49                	je     3f9 <printf+0x9f>
        printint(fd, *ap, 10, 1);
        ap++;
      } else if(c == 'x' || c == 'p'){
 3b0:	83 f8 78             	cmp    $0x78,%eax
 3b3:	0f 94 c1             	sete   %cl
 3b6:	83 f8 70             	cmp    $0x70,%eax
 3b9:	0f 94 c2             	sete   %dl
 3bc:	08 d1                	or     %dl,%cl
 3be:	75 63                	jne    423 <printf+0xc9>
        printint(fd, *ap, 16, 0);
        ap++;
      } else if(c == 's'){
 3c0:	83 f8 73             	cmp    $0x73,%eax
 3c3:	0f 84 84 00 00 00    	je     44d <printf+0xf3>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 3c9:	83 f8 63             	cmp    $0x63,%eax
 3cc:	0f 84 b7 00 00 00    	je     489 <printf+0x12f>
        putc(fd, *ap);
        ap++;
      } else if(c == '%'){
 3d2:	83 f8 25             	cmp    $0x25,%eax
 3d5:	0f 84 cc 00 00 00    	je     4a7 <printf+0x14d>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 3db:	ba 25 00 00 00       	mov    $0x25,%edx
 3e0:	8b 45 08             	mov    0x8(%ebp),%eax
 3e3:	e8 d8 fe ff ff       	call   2c0 <putc>
        putc(fd, c);
 3e8:	89 fa                	mov    %edi,%edx
 3ea:	8b 45 08             	mov    0x8(%ebp),%eax
 3ed:	e8 ce fe ff ff       	call   2c0 <putc>
      }
      state = 0;
 3f2:	be 00 00 00 00       	mov    $0x0,%esi
 3f7:	eb 8d                	jmp    386 <printf+0x2c>
        printint(fd, *ap, 10, 1);
 3f9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 3fc:	8b 17                	mov    (%edi),%edx
 3fe:	83 ec 0c             	sub    $0xc,%esp
 401:	6a 01                	push   $0x1
 403:	b9 0a 00 00 00       	mov    $0xa,%ecx
 408:	8b 45 08             	mov    0x8(%ebp),%eax
 40b:	e8 ca fe ff ff       	call   2da <printint>
        ap++;
 410:	83 c7 04             	add    $0x4,%edi
 413:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 416:	83 c4 10             	add    $0x10,%esp
      state = 0;
 419:	be 00 00 00 00       	mov    $0x0,%esi
 41e:	e9 63 ff ff ff       	jmp    386 <printf+0x2c>
        printint(fd, *ap, 16, 0);
 423:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 426:	8b 17                	mov    (%edi),%edx
 428:	83 ec 0c             	sub    $0xc,%esp
 42b:	6a 00                	push   $0x0
 42d:	b9 10 00 00 00       	mov    $0x10,%ecx
 432:	8b 45 08             	mov    0x8(%ebp),%eax
 435:	e8 a0 fe ff ff       	call   2da <printint>
        ap++;
 43a:	83 c7 04             	add    $0x4,%edi
 43d:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 440:	83 c4 10             	add    $0x10,%esp
      state = 0;
 443:	be 00 00 00 00       	mov    $0x0,%esi
 448:	e9 39 ff ff ff       	jmp    386 <printf+0x2c>
        s = (char*)*ap;
 44d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 450:	8b 30                	mov    (%eax),%esi
        ap++;
 452:	83 c0 04             	add    $0x4,%eax
 455:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if(s == 0)
 458:	85 f6                	test   %esi,%esi
 45a:	75 28                	jne    484 <printf+0x12a>
          s = "(null)";
 45c:	be 30 06 00 00       	mov    $0x630,%esi
 461:	8b 7d 08             	mov    0x8(%ebp),%edi
 464:	eb 0d                	jmp    473 <printf+0x119>
          putc(fd, *s);
 466:	0f be d2             	movsbl %dl,%edx
 469:	89 f8                	mov    %edi,%eax
 46b:	e8 50 fe ff ff       	call   2c0 <putc>
          s++;
 470:	83 c6 01             	add    $0x1,%esi
        while(*s != 0){
 473:	0f b6 16             	movzbl (%esi),%edx
 476:	84 d2                	test   %dl,%dl
 478:	75 ec                	jne    466 <printf+0x10c>
      state = 0;
 47a:	be 00 00 00 00       	mov    $0x0,%esi
 47f:	e9 02 ff ff ff       	jmp    386 <printf+0x2c>
 484:	8b 7d 08             	mov    0x8(%ebp),%edi
 487:	eb ea                	jmp    473 <printf+0x119>
        putc(fd, *ap);
 489:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 48c:	0f be 17             	movsbl (%edi),%edx
 48f:	8b 45 08             	mov    0x8(%ebp),%eax
 492:	e8 29 fe ff ff       	call   2c0 <putc>
        ap++;
 497:	83 c7 04             	add    $0x4,%edi
 49a:	89 7d e4             	mov    %edi,-0x1c(%ebp)
      state = 0;
 49d:	be 00 00 00 00       	mov    $0x0,%esi
 4a2:	e9 df fe ff ff       	jmp    386 <printf+0x2c>
        putc(fd, c);
 4a7:	89 fa                	mov    %edi,%edx
 4a9:	8b 45 08             	mov    0x8(%ebp),%eax
 4ac:	e8 0f fe ff ff       	call   2c0 <putc>
      state = 0;
 4b1:	be 00 00 00 00       	mov    $0x0,%esi
 4b6:	e9 cb fe ff ff       	jmp    386 <printf+0x2c>
    }
  }
}
 4bb:	8d 65 f4             	lea    -0xc(%ebp),%esp
 4be:	5b                   	pop    %ebx
 4bf:	5e                   	pop    %esi
 4c0:	5f                   	pop    %edi
 4c1:	5d                   	pop    %ebp
 4c2:	c3                   	ret    

000004c3 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 4c3:	55                   	push   %ebp
 4c4:	89 e5                	mov    %esp,%ebp
 4c6:	57                   	push   %edi
 4c7:	56                   	push   %esi
 4c8:	53                   	push   %ebx
 4c9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  Header *bp, *p;

  bp = (Header*)ap - 1;
 4cc:	8d 4b f8             	lea    -0x8(%ebx),%ecx
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 4cf:	a1 dc 08 00 00       	mov    0x8dc,%eax
 4d4:	eb 02                	jmp    4d8 <free+0x15>
 4d6:	89 d0                	mov    %edx,%eax
 4d8:	39 c8                	cmp    %ecx,%eax
 4da:	73 04                	jae    4e0 <free+0x1d>
 4dc:	39 08                	cmp    %ecx,(%eax)
 4de:	77 12                	ja     4f2 <free+0x2f>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 4e0:	8b 10                	mov    (%eax),%edx
 4e2:	39 c2                	cmp    %eax,%edx
 4e4:	77 f0                	ja     4d6 <free+0x13>
 4e6:	39 c8                	cmp    %ecx,%eax
 4e8:	72 08                	jb     4f2 <free+0x2f>
 4ea:	39 ca                	cmp    %ecx,%edx
 4ec:	77 04                	ja     4f2 <free+0x2f>
 4ee:	89 d0                	mov    %edx,%eax
 4f0:	eb e6                	jmp    4d8 <free+0x15>
      break;
  if(bp + bp->s.size == p->s.ptr){
 4f2:	8b 73 fc             	mov    -0x4(%ebx),%esi
 4f5:	8d 3c f1             	lea    (%ecx,%esi,8),%edi
 4f8:	8b 10                	mov    (%eax),%edx
 4fa:	39 d7                	cmp    %edx,%edi
 4fc:	74 19                	je     517 <free+0x54>
    bp->s.size += p->s.ptr->s.size;
    bp->s.ptr = p->s.ptr->s.ptr;
  } else
    bp->s.ptr = p->s.ptr;
 4fe:	89 53 f8             	mov    %edx,-0x8(%ebx)
  if(p + p->s.size == bp){
 501:	8b 50 04             	mov    0x4(%eax),%edx
 504:	8d 34 d0             	lea    (%eax,%edx,8),%esi
 507:	39 ce                	cmp    %ecx,%esi
 509:	74 1b                	je     526 <free+0x63>
    p->s.size += bp->s.size;
    p->s.ptr = bp->s.ptr;
  } else
    p->s.ptr = bp;
 50b:	89 08                	mov    %ecx,(%eax)
  freep = p;
 50d:	a3 dc 08 00 00       	mov    %eax,0x8dc
}
 512:	5b                   	pop    %ebx
 513:	5e                   	pop    %esi
 514:	5f                   	pop    %edi
 515:	5d                   	pop    %ebp
 516:	c3                   	ret    
    bp->s.size += p->s.ptr->s.size;
 517:	03 72 04             	add    0x4(%edx),%esi
 51a:	89 73 fc             	mov    %esi,-0x4(%ebx)
    bp->s.ptr = p->s.ptr->s.ptr;
 51d:	8b 10                	mov    (%eax),%edx
 51f:	8b 12                	mov    (%edx),%edx
 521:	89 53 f8             	mov    %edx,-0x8(%ebx)
 524:	eb db                	jmp    501 <free+0x3e>
    p->s.size += bp->s.size;
 526:	03 53 fc             	add    -0x4(%ebx),%edx
 529:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 52c:	8b 53 f8             	mov    -0x8(%ebx),%edx
 52f:	89 10                	mov    %edx,(%eax)
 531:	eb da                	jmp    50d <free+0x4a>

00000533 <morecore>:

static Header*
morecore(uint nu)
{
 533:	55                   	push   %ebp
 534:	89 e5                	mov    %esp,%ebp
 536:	53                   	push   %ebx
 537:	83 ec 04             	sub    $0x4,%esp
 53a:	89 c3                	mov    %eax,%ebx
  char *p;
  Header *hp;

  if(nu < 4096)
 53c:	3d ff 0f 00 00       	cmp    $0xfff,%eax
 541:	77 05                	ja     548 <morecore+0x15>
    nu = 4096;
 543:	bb 00 10 00 00       	mov    $0x1000,%ebx
  p = sbrk(nu * sizeof(Header));
 548:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
 54f:	83 ec 0c             	sub    $0xc,%esp
 552:	50                   	push   %eax
 553:	e8 48 fd ff ff       	call   2a0 <sbrk>
  if(p == (char*)-1)
 558:	83 c4 10             	add    $0x10,%esp
 55b:	83 f8 ff             	cmp    $0xffffffff,%eax
 55e:	74 1c                	je     57c <morecore+0x49>
    return 0;
  hp = (Header*)p;
  hp->s.size = nu;
 560:	89 58 04             	mov    %ebx,0x4(%eax)
  free((void*)(hp + 1));
 563:	83 c0 08             	add    $0x8,%eax
 566:	83 ec 0c             	sub    $0xc,%esp
 569:	50                   	push   %eax
 56a:	e8 54 ff ff ff       	call   4c3 <free>
  return freep;
 56f:	a1 dc 08 00 00       	mov    0x8dc,%eax
 574:	83 c4 10             	add    $0x10,%esp
}
 577:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 57a:	c9                   	leave  
 57b:	c3                   	ret    
    return 0;
 57c:	b8 00 00 00 00       	mov    $0x0,%eax
 581:	eb f4                	jmp    577 <morecore+0x44>

00000583 <malloc>:

void*
malloc(uint nbytes)
{
 583:	55                   	push   %ebp
 584:	89 e5                	mov    %esp,%ebp
 586:	53                   	push   %ebx
 587:	83 ec 04             	sub    $0x4,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 58a:	8b 45 08             	mov    0x8(%ebp),%eax
 58d:	8d 58 07             	lea    0x7(%eax),%ebx
 590:	c1 eb 03             	shr    $0x3,%ebx
 593:	83 c3 01             	add    $0x1,%ebx
  if((prevp = freep) == 0){
 596:	8b 0d dc 08 00 00    	mov    0x8dc,%ecx
 59c:	85 c9                	test   %ecx,%ecx
 59e:	74 04                	je     5a4 <malloc+0x21>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 5a0:	8b 01                	mov    (%ecx),%eax
 5a2:	eb 4d                	jmp    5f1 <malloc+0x6e>
    base.s.ptr = freep = prevp = &base;
 5a4:	c7 05 dc 08 00 00 e0 	movl   $0x8e0,0x8dc
 5ab:	08 00 00 
 5ae:	c7 05 e0 08 00 00 e0 	movl   $0x8e0,0x8e0
 5b5:	08 00 00 
    base.s.size = 0;
 5b8:	c7 05 e4 08 00 00 00 	movl   $0x0,0x8e4
 5bf:	00 00 00 
    base.s.ptr = freep = prevp = &base;
 5c2:	b9 e0 08 00 00       	mov    $0x8e0,%ecx
 5c7:	eb d7                	jmp    5a0 <malloc+0x1d>
    if(p->s.size >= nunits){
      if(p->s.size == nunits)
 5c9:	39 da                	cmp    %ebx,%edx
 5cb:	74 1a                	je     5e7 <malloc+0x64>
        prevp->s.ptr = p->s.ptr;
      else {
        p->s.size -= nunits;
 5cd:	29 da                	sub    %ebx,%edx
 5cf:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 5d2:	8d 04 d0             	lea    (%eax,%edx,8),%eax
        p->s.size = nunits;
 5d5:	89 58 04             	mov    %ebx,0x4(%eax)
      }
      freep = prevp;
 5d8:	89 0d dc 08 00 00    	mov    %ecx,0x8dc
      return (void*)(p + 1);
 5de:	83 c0 08             	add    $0x8,%eax
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 5e1:	83 c4 04             	add    $0x4,%esp
 5e4:	5b                   	pop    %ebx
 5e5:	5d                   	pop    %ebp
 5e6:	c3                   	ret    
        prevp->s.ptr = p->s.ptr;
 5e7:	8b 10                	mov    (%eax),%edx
 5e9:	89 11                	mov    %edx,(%ecx)
 5eb:	eb eb                	jmp    5d8 <malloc+0x55>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 5ed:	89 c1                	mov    %eax,%ecx
 5ef:	8b 00                	mov    (%eax),%eax
    if(p->s.size >= nunits){
 5f1:	8b 50 04             	mov    0x4(%eax),%edx
 5f4:	39 da                	cmp    %ebx,%edx
 5f6:	73 d1                	jae    5c9 <malloc+0x46>
    if(p == freep)
 5f8:	39 05 dc 08 00 00    	cmp    %eax,0x8dc
 5fe:	75 ed                	jne    5ed <malloc+0x6a>
      if((p = morecore(nunits)) == 0)
 600:	89 d8                	mov    %ebx,%eax
 602:	e8 2c ff ff ff       	call   533 <morecore>
 607:	85 c0                	test   %eax,%eax
 609:	75 e2                	jne    5ed <malloc+0x6a>
        return 0;
 60b:	b8 00 00 00 00       	mov    $0x0,%eax
 610:	eb cf                	jmp    5e1 <malloc+0x5e>
