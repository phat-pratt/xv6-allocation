
_test1:     file format elf32-i386


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
  19:	e8 76 05 00 00       	call   594 <malloc>
  1e:	89 c6                	mov    %eax,%esi
    int* pids = malloc(numframes * sizeof(int));
  20:	c7 04 24 90 01 00 00 	movl   $0x190,(%esp)
  27:	e8 68 05 00 00       	call   594 <malloc>
  2c:	89 c7                	mov    %eax,%edi
    frames[0] = 1;
  2e:	c7 06 01 00 00 00    	movl   $0x1,(%esi)
    printf(1, "frames[0] : %d", frames[0]);
  34:	83 c4 0c             	add    $0xc,%esp
  37:	6a 01                	push   $0x1
  39:	68 24 06 00 00       	push   $0x624
  3e:	6a 01                	push   $0x1
  40:	e8 26 03 00 00       	call   36b <printf>
    int flag = dump_physmem(frames, pids, numframes);
  45:	83 c4 0c             	add    $0xc,%esp
  48:	6a 64                	push   $0x64
  4a:	57                   	push   %edi
  4b:	56                   	push   %esi
  4c:	e8 78 02 00 00       	call   2c9 <dump_physmem>
  51:	89 c3                	mov    %eax,%ebx

    if(flag == 0)
  53:	83 c4 10             	add    $0x10,%esp
  56:	85 c0                	test   %eax,%eax
  58:	74 33                	je     8d <main+0x8d>

            printf(0,"Frames: %x PIDs: %d\n", *(frames+i), *(pids+i));
    }
    else// if(flag == -1)
    {
        printf(0,"error\n");
  5a:	83 ec 08             	sub    $0x8,%esp
  5d:	68 48 06 00 00       	push   $0x648
  62:	6a 00                	push   $0x0
  64:	e8 02 03 00 00       	call   36b <printf>
  69:	83 c4 10             	add    $0x10,%esp
  6c:	eb 24                	jmp    92 <main+0x92>
            printf(0,"Frames: %x PIDs: %d\n", *(frames+i), *(pids+i));
  6e:	8d 04 9d 00 00 00 00 	lea    0x0(,%ebx,4),%eax
  75:	ff 34 07             	pushl  (%edi,%eax,1)
  78:	ff 34 06             	pushl  (%esi,%eax,1)
  7b:	68 33 06 00 00       	push   $0x633
  80:	6a 00                	push   $0x0
  82:	e8 e4 02 00 00       	call   36b <printf>
        for (int i = 0; i < numframes; i++)
  87:	83 c3 01             	add    $0x1,%ebx
  8a:	83 c4 10             	add    $0x10,%esp
  8d:	83 fb 63             	cmp    $0x63,%ebx
  90:	7e dc                	jle    6e <main+0x6e>
    }
    wait();
  92:	e8 9a 01 00 00       	call   231 <wait>
    exit();
  97:	e8 8d 01 00 00       	call   229 <exit>

0000009c <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, const char *t)
{
  9c:	55                   	push   %ebp
  9d:	89 e5                	mov    %esp,%ebp
  9f:	53                   	push   %ebx
  a0:	8b 45 08             	mov    0x8(%ebp),%eax
  a3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  a6:	89 c2                	mov    %eax,%edx
  a8:	0f b6 19             	movzbl (%ecx),%ebx
  ab:	88 1a                	mov    %bl,(%edx)
  ad:	8d 52 01             	lea    0x1(%edx),%edx
  b0:	8d 49 01             	lea    0x1(%ecx),%ecx
  b3:	84 db                	test   %bl,%bl
  b5:	75 f1                	jne    a8 <strcpy+0xc>
    ;
  return os;
}
  b7:	5b                   	pop    %ebx
  b8:	5d                   	pop    %ebp
  b9:	c3                   	ret    

000000ba <strcmp>:

int
strcmp(const char *p, const char *q)
{
  ba:	55                   	push   %ebp
  bb:	89 e5                	mov    %esp,%ebp
  bd:	8b 4d 08             	mov    0x8(%ebp),%ecx
  c0:	8b 55 0c             	mov    0xc(%ebp),%edx
  while(*p && *p == *q)
  c3:	eb 06                	jmp    cb <strcmp+0x11>
    p++, q++;
  c5:	83 c1 01             	add    $0x1,%ecx
  c8:	83 c2 01             	add    $0x1,%edx
  while(*p && *p == *q)
  cb:	0f b6 01             	movzbl (%ecx),%eax
  ce:	84 c0                	test   %al,%al
  d0:	74 04                	je     d6 <strcmp+0x1c>
  d2:	3a 02                	cmp    (%edx),%al
  d4:	74 ef                	je     c5 <strcmp+0xb>
  return (uchar)*p - (uchar)*q;
  d6:	0f b6 c0             	movzbl %al,%eax
  d9:	0f b6 12             	movzbl (%edx),%edx
  dc:	29 d0                	sub    %edx,%eax
}
  de:	5d                   	pop    %ebp
  df:	c3                   	ret    

000000e0 <strlen>:

uint
strlen(const char *s)
{
  e0:	55                   	push   %ebp
  e1:	89 e5                	mov    %esp,%ebp
  e3:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  for(n = 0; s[n]; n++)
  e6:	ba 00 00 00 00       	mov    $0x0,%edx
  eb:	eb 03                	jmp    f0 <strlen+0x10>
  ed:	83 c2 01             	add    $0x1,%edx
  f0:	89 d0                	mov    %edx,%eax
  f2:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  f6:	75 f5                	jne    ed <strlen+0xd>
    ;
  return n;
}
  f8:	5d                   	pop    %ebp
  f9:	c3                   	ret    

000000fa <memset>:

void*
memset(void *dst, int c, uint n)
{
  fa:	55                   	push   %ebp
  fb:	89 e5                	mov    %esp,%ebp
  fd:	57                   	push   %edi
  fe:	8b 55 08             	mov    0x8(%ebp),%edx
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
 101:	89 d7                	mov    %edx,%edi
 103:	8b 4d 10             	mov    0x10(%ebp),%ecx
 106:	8b 45 0c             	mov    0xc(%ebp),%eax
 109:	fc                   	cld    
 10a:	f3 aa                	rep stos %al,%es:(%edi)
  stosb(dst, c, n);
  return dst;
}
 10c:	89 d0                	mov    %edx,%eax
 10e:	5f                   	pop    %edi
 10f:	5d                   	pop    %ebp
 110:	c3                   	ret    

00000111 <strchr>:

char*
strchr(const char *s, char c)
{
 111:	55                   	push   %ebp
 112:	89 e5                	mov    %esp,%ebp
 114:	8b 45 08             	mov    0x8(%ebp),%eax
 117:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
  for(; *s; s++)
 11b:	0f b6 10             	movzbl (%eax),%edx
 11e:	84 d2                	test   %dl,%dl
 120:	74 09                	je     12b <strchr+0x1a>
    if(*s == c)
 122:	38 ca                	cmp    %cl,%dl
 124:	74 0a                	je     130 <strchr+0x1f>
  for(; *s; s++)
 126:	83 c0 01             	add    $0x1,%eax
 129:	eb f0                	jmp    11b <strchr+0xa>
      return (char*)s;
  return 0;
 12b:	b8 00 00 00 00       	mov    $0x0,%eax
}
 130:	5d                   	pop    %ebp
 131:	c3                   	ret    

00000132 <gets>:

char*
gets(char *buf, int max)
{
 132:	55                   	push   %ebp
 133:	89 e5                	mov    %esp,%ebp
 135:	57                   	push   %edi
 136:	56                   	push   %esi
 137:	53                   	push   %ebx
 138:	83 ec 1c             	sub    $0x1c,%esp
 13b:	8b 7d 08             	mov    0x8(%ebp),%edi
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 13e:	bb 00 00 00 00       	mov    $0x0,%ebx
 143:	8d 73 01             	lea    0x1(%ebx),%esi
 146:	3b 75 0c             	cmp    0xc(%ebp),%esi
 149:	7d 2e                	jge    179 <gets+0x47>
    cc = read(0, &c, 1);
 14b:	83 ec 04             	sub    $0x4,%esp
 14e:	6a 01                	push   $0x1
 150:	8d 45 e7             	lea    -0x19(%ebp),%eax
 153:	50                   	push   %eax
 154:	6a 00                	push   $0x0
 156:	e8 e6 00 00 00       	call   241 <read>
    if(cc < 1)
 15b:	83 c4 10             	add    $0x10,%esp
 15e:	85 c0                	test   %eax,%eax
 160:	7e 17                	jle    179 <gets+0x47>
      break;
    buf[i++] = c;
 162:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
 166:	88 04 1f             	mov    %al,(%edi,%ebx,1)
    if(c == '\n' || c == '\r')
 169:	3c 0a                	cmp    $0xa,%al
 16b:	0f 94 c2             	sete   %dl
 16e:	3c 0d                	cmp    $0xd,%al
 170:	0f 94 c0             	sete   %al
    buf[i++] = c;
 173:	89 f3                	mov    %esi,%ebx
    if(c == '\n' || c == '\r')
 175:	08 c2                	or     %al,%dl
 177:	74 ca                	je     143 <gets+0x11>
      break;
  }
  buf[i] = '\0';
 179:	c6 04 1f 00          	movb   $0x0,(%edi,%ebx,1)
  return buf;
}
 17d:	89 f8                	mov    %edi,%eax
 17f:	8d 65 f4             	lea    -0xc(%ebp),%esp
 182:	5b                   	pop    %ebx
 183:	5e                   	pop    %esi
 184:	5f                   	pop    %edi
 185:	5d                   	pop    %ebp
 186:	c3                   	ret    

00000187 <stat>:

int
stat(const char *n, struct stat *st)
{
 187:	55                   	push   %ebp
 188:	89 e5                	mov    %esp,%ebp
 18a:	56                   	push   %esi
 18b:	53                   	push   %ebx
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 18c:	83 ec 08             	sub    $0x8,%esp
 18f:	6a 00                	push   $0x0
 191:	ff 75 08             	pushl  0x8(%ebp)
 194:	e8 d0 00 00 00       	call   269 <open>
  if(fd < 0)
 199:	83 c4 10             	add    $0x10,%esp
 19c:	85 c0                	test   %eax,%eax
 19e:	78 24                	js     1c4 <stat+0x3d>
 1a0:	89 c3                	mov    %eax,%ebx
    return -1;
  r = fstat(fd, st);
 1a2:	83 ec 08             	sub    $0x8,%esp
 1a5:	ff 75 0c             	pushl  0xc(%ebp)
 1a8:	50                   	push   %eax
 1a9:	e8 d3 00 00 00       	call   281 <fstat>
 1ae:	89 c6                	mov    %eax,%esi
  close(fd);
 1b0:	89 1c 24             	mov    %ebx,(%esp)
 1b3:	e8 99 00 00 00       	call   251 <close>
  return r;
 1b8:	83 c4 10             	add    $0x10,%esp
}
 1bb:	89 f0                	mov    %esi,%eax
 1bd:	8d 65 f8             	lea    -0x8(%ebp),%esp
 1c0:	5b                   	pop    %ebx
 1c1:	5e                   	pop    %esi
 1c2:	5d                   	pop    %ebp
 1c3:	c3                   	ret    
    return -1;
 1c4:	be ff ff ff ff       	mov    $0xffffffff,%esi
 1c9:	eb f0                	jmp    1bb <stat+0x34>

000001cb <atoi>:

int
atoi(const char *s)
{
 1cb:	55                   	push   %ebp
 1cc:	89 e5                	mov    %esp,%ebp
 1ce:	53                   	push   %ebx
 1cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  n = 0;
 1d2:	b8 00 00 00 00       	mov    $0x0,%eax
  while('0' <= *s && *s <= '9')
 1d7:	eb 10                	jmp    1e9 <atoi+0x1e>
    n = n*10 + *s++ - '0';
 1d9:	8d 1c 80             	lea    (%eax,%eax,4),%ebx
 1dc:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
 1df:	83 c1 01             	add    $0x1,%ecx
 1e2:	0f be d2             	movsbl %dl,%edx
 1e5:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
  while('0' <= *s && *s <= '9')
 1e9:	0f b6 11             	movzbl (%ecx),%edx
 1ec:	8d 5a d0             	lea    -0x30(%edx),%ebx
 1ef:	80 fb 09             	cmp    $0x9,%bl
 1f2:	76 e5                	jbe    1d9 <atoi+0xe>
  return n;
}
 1f4:	5b                   	pop    %ebx
 1f5:	5d                   	pop    %ebp
 1f6:	c3                   	ret    

000001f7 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1f7:	55                   	push   %ebp
 1f8:	89 e5                	mov    %esp,%ebp
 1fa:	56                   	push   %esi
 1fb:	53                   	push   %ebx
 1fc:	8b 45 08             	mov    0x8(%ebp),%eax
 1ff:	8b 5d 0c             	mov    0xc(%ebp),%ebx
 202:	8b 55 10             	mov    0x10(%ebp),%edx
  char *dst;
  const char *src;

  dst = vdst;
 205:	89 c1                	mov    %eax,%ecx
  src = vsrc;
  while(n-- > 0)
 207:	eb 0d                	jmp    216 <memmove+0x1f>
    *dst++ = *src++;
 209:	0f b6 13             	movzbl (%ebx),%edx
 20c:	88 11                	mov    %dl,(%ecx)
 20e:	8d 5b 01             	lea    0x1(%ebx),%ebx
 211:	8d 49 01             	lea    0x1(%ecx),%ecx
  while(n-- > 0)
 214:	89 f2                	mov    %esi,%edx
 216:	8d 72 ff             	lea    -0x1(%edx),%esi
 219:	85 d2                	test   %edx,%edx
 21b:	7f ec                	jg     209 <memmove+0x12>
  return vdst;
}
 21d:	5b                   	pop    %ebx
 21e:	5e                   	pop    %esi
 21f:	5d                   	pop    %ebp
 220:	c3                   	ret    

00000221 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 221:	b8 01 00 00 00       	mov    $0x1,%eax
 226:	cd 40                	int    $0x40
 228:	c3                   	ret    

00000229 <exit>:
SYSCALL(exit)
 229:	b8 02 00 00 00       	mov    $0x2,%eax
 22e:	cd 40                	int    $0x40
 230:	c3                   	ret    

00000231 <wait>:
SYSCALL(wait)
 231:	b8 03 00 00 00       	mov    $0x3,%eax
 236:	cd 40                	int    $0x40
 238:	c3                   	ret    

00000239 <pipe>:
SYSCALL(pipe)
 239:	b8 04 00 00 00       	mov    $0x4,%eax
 23e:	cd 40                	int    $0x40
 240:	c3                   	ret    

00000241 <read>:
SYSCALL(read)
 241:	b8 05 00 00 00       	mov    $0x5,%eax
 246:	cd 40                	int    $0x40
 248:	c3                   	ret    

00000249 <write>:
SYSCALL(write)
 249:	b8 10 00 00 00       	mov    $0x10,%eax
 24e:	cd 40                	int    $0x40
 250:	c3                   	ret    

00000251 <close>:
SYSCALL(close)
 251:	b8 15 00 00 00       	mov    $0x15,%eax
 256:	cd 40                	int    $0x40
 258:	c3                   	ret    

00000259 <kill>:
SYSCALL(kill)
 259:	b8 06 00 00 00       	mov    $0x6,%eax
 25e:	cd 40                	int    $0x40
 260:	c3                   	ret    

00000261 <exec>:
SYSCALL(exec)
 261:	b8 07 00 00 00       	mov    $0x7,%eax
 266:	cd 40                	int    $0x40
 268:	c3                   	ret    

00000269 <open>:
SYSCALL(open)
 269:	b8 0f 00 00 00       	mov    $0xf,%eax
 26e:	cd 40                	int    $0x40
 270:	c3                   	ret    

00000271 <mknod>:
SYSCALL(mknod)
 271:	b8 11 00 00 00       	mov    $0x11,%eax
 276:	cd 40                	int    $0x40
 278:	c3                   	ret    

00000279 <unlink>:
SYSCALL(unlink)
 279:	b8 12 00 00 00       	mov    $0x12,%eax
 27e:	cd 40                	int    $0x40
 280:	c3                   	ret    

00000281 <fstat>:
SYSCALL(fstat)
 281:	b8 08 00 00 00       	mov    $0x8,%eax
 286:	cd 40                	int    $0x40
 288:	c3                   	ret    

00000289 <link>:
SYSCALL(link)
 289:	b8 13 00 00 00       	mov    $0x13,%eax
 28e:	cd 40                	int    $0x40
 290:	c3                   	ret    

00000291 <mkdir>:
SYSCALL(mkdir)
 291:	b8 14 00 00 00       	mov    $0x14,%eax
 296:	cd 40                	int    $0x40
 298:	c3                   	ret    

00000299 <chdir>:
SYSCALL(chdir)
 299:	b8 09 00 00 00       	mov    $0x9,%eax
 29e:	cd 40                	int    $0x40
 2a0:	c3                   	ret    

000002a1 <dup>:
SYSCALL(dup)
 2a1:	b8 0a 00 00 00       	mov    $0xa,%eax
 2a6:	cd 40                	int    $0x40
 2a8:	c3                   	ret    

000002a9 <getpid>:
SYSCALL(getpid)
 2a9:	b8 0b 00 00 00       	mov    $0xb,%eax
 2ae:	cd 40                	int    $0x40
 2b0:	c3                   	ret    

000002b1 <sbrk>:
SYSCALL(sbrk)
 2b1:	b8 0c 00 00 00       	mov    $0xc,%eax
 2b6:	cd 40                	int    $0x40
 2b8:	c3                   	ret    

000002b9 <sleep>:
SYSCALL(sleep)
 2b9:	b8 0d 00 00 00       	mov    $0xd,%eax
 2be:	cd 40                	int    $0x40
 2c0:	c3                   	ret    

000002c1 <uptime>:
SYSCALL(uptime)
 2c1:	b8 0e 00 00 00       	mov    $0xe,%eax
 2c6:	cd 40                	int    $0x40
 2c8:	c3                   	ret    

000002c9 <dump_physmem>:
 2c9:	b8 16 00 00 00       	mov    $0x16,%eax
 2ce:	cd 40                	int    $0x40
 2d0:	c3                   	ret    

000002d1 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 2d1:	55                   	push   %ebp
 2d2:	89 e5                	mov    %esp,%ebp
 2d4:	83 ec 1c             	sub    $0x1c,%esp
 2d7:	88 55 f4             	mov    %dl,-0xc(%ebp)
  write(fd, &c, 1);
 2da:	6a 01                	push   $0x1
 2dc:	8d 55 f4             	lea    -0xc(%ebp),%edx
 2df:	52                   	push   %edx
 2e0:	50                   	push   %eax
 2e1:	e8 63 ff ff ff       	call   249 <write>
}
 2e6:	83 c4 10             	add    $0x10,%esp
 2e9:	c9                   	leave  
 2ea:	c3                   	ret    

000002eb <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 2eb:	55                   	push   %ebp
 2ec:	89 e5                	mov    %esp,%ebp
 2ee:	57                   	push   %edi
 2ef:	56                   	push   %esi
 2f0:	53                   	push   %ebx
 2f1:	83 ec 2c             	sub    $0x2c,%esp
 2f4:	89 c7                	mov    %eax,%edi
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 2f6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
 2fa:	0f 95 c3             	setne  %bl
 2fd:	89 d0                	mov    %edx,%eax
 2ff:	c1 e8 1f             	shr    $0x1f,%eax
 302:	84 c3                	test   %al,%bl
 304:	74 10                	je     316 <printint+0x2b>
    neg = 1;
    x = -xx;
 306:	f7 da                	neg    %edx
    neg = 1;
 308:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  } else {
    x = xx;
  }

  i = 0;
 30f:	be 00 00 00 00       	mov    $0x0,%esi
 314:	eb 0b                	jmp    321 <printint+0x36>
  neg = 0;
 316:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
 31d:	eb f0                	jmp    30f <printint+0x24>
  do{
    buf[i++] = digits[x % base];
 31f:	89 c6                	mov    %eax,%esi
 321:	89 d0                	mov    %edx,%eax
 323:	ba 00 00 00 00       	mov    $0x0,%edx
 328:	f7 f1                	div    %ecx
 32a:	89 c3                	mov    %eax,%ebx
 32c:	8d 46 01             	lea    0x1(%esi),%eax
 32f:	0f b6 92 58 06 00 00 	movzbl 0x658(%edx),%edx
 336:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
 33a:	89 da                	mov    %ebx,%edx
 33c:	85 db                	test   %ebx,%ebx
 33e:	75 df                	jne    31f <printint+0x34>
 340:	89 c3                	mov    %eax,%ebx
  if(neg)
 342:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
 346:	74 16                	je     35e <printint+0x73>
    buf[i++] = '-';
 348:	c6 44 05 d8 2d       	movb   $0x2d,-0x28(%ebp,%eax,1)
 34d:	8d 5e 02             	lea    0x2(%esi),%ebx
 350:	eb 0c                	jmp    35e <printint+0x73>

  while(--i >= 0)
    putc(fd, buf[i]);
 352:	0f be 54 1d d8       	movsbl -0x28(%ebp,%ebx,1),%edx
 357:	89 f8                	mov    %edi,%eax
 359:	e8 73 ff ff ff       	call   2d1 <putc>
  while(--i >= 0)
 35e:	83 eb 01             	sub    $0x1,%ebx
 361:	79 ef                	jns    352 <printint+0x67>
}
 363:	83 c4 2c             	add    $0x2c,%esp
 366:	5b                   	pop    %ebx
 367:	5e                   	pop    %esi
 368:	5f                   	pop    %edi
 369:	5d                   	pop    %ebp
 36a:	c3                   	ret    

0000036b <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, const char *fmt, ...)
{
 36b:	55                   	push   %ebp
 36c:	89 e5                	mov    %esp,%ebp
 36e:	57                   	push   %edi
 36f:	56                   	push   %esi
 370:	53                   	push   %ebx
 371:	83 ec 1c             	sub    $0x1c,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
 374:	8d 45 10             	lea    0x10(%ebp),%eax
 377:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  state = 0;
 37a:	be 00 00 00 00       	mov    $0x0,%esi
  for(i = 0; fmt[i]; i++){
 37f:	bb 00 00 00 00       	mov    $0x0,%ebx
 384:	eb 14                	jmp    39a <printf+0x2f>
    c = fmt[i] & 0xff;
    if(state == 0){
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
 386:	89 fa                	mov    %edi,%edx
 388:	8b 45 08             	mov    0x8(%ebp),%eax
 38b:	e8 41 ff ff ff       	call   2d1 <putc>
 390:	eb 05                	jmp    397 <printf+0x2c>
      }
    } else if(state == '%'){
 392:	83 fe 25             	cmp    $0x25,%esi
 395:	74 25                	je     3bc <printf+0x51>
  for(i = 0; fmt[i]; i++){
 397:	83 c3 01             	add    $0x1,%ebx
 39a:	8b 45 0c             	mov    0xc(%ebp),%eax
 39d:	0f b6 04 18          	movzbl (%eax,%ebx,1),%eax
 3a1:	84 c0                	test   %al,%al
 3a3:	0f 84 23 01 00 00    	je     4cc <printf+0x161>
    c = fmt[i] & 0xff;
 3a9:	0f be f8             	movsbl %al,%edi
 3ac:	0f b6 c0             	movzbl %al,%eax
    if(state == 0){
 3af:	85 f6                	test   %esi,%esi
 3b1:	75 df                	jne    392 <printf+0x27>
      if(c == '%'){
 3b3:	83 f8 25             	cmp    $0x25,%eax
 3b6:	75 ce                	jne    386 <printf+0x1b>
        state = '%';
 3b8:	89 c6                	mov    %eax,%esi
 3ba:	eb db                	jmp    397 <printf+0x2c>
      if(c == 'd'){
 3bc:	83 f8 64             	cmp    $0x64,%eax
 3bf:	74 49                	je     40a <printf+0x9f>
        printint(fd, *ap, 10, 1);
        ap++;
      } else if(c == 'x' || c == 'p'){
 3c1:	83 f8 78             	cmp    $0x78,%eax
 3c4:	0f 94 c1             	sete   %cl
 3c7:	83 f8 70             	cmp    $0x70,%eax
 3ca:	0f 94 c2             	sete   %dl
 3cd:	08 d1                	or     %dl,%cl
 3cf:	75 63                	jne    434 <printf+0xc9>
        printint(fd, *ap, 16, 0);
        ap++;
      } else if(c == 's'){
 3d1:	83 f8 73             	cmp    $0x73,%eax
 3d4:	0f 84 84 00 00 00    	je     45e <printf+0xf3>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 3da:	83 f8 63             	cmp    $0x63,%eax
 3dd:	0f 84 b7 00 00 00    	je     49a <printf+0x12f>
        putc(fd, *ap);
        ap++;
      } else if(c == '%'){
 3e3:	83 f8 25             	cmp    $0x25,%eax
 3e6:	0f 84 cc 00 00 00    	je     4b8 <printf+0x14d>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 3ec:	ba 25 00 00 00       	mov    $0x25,%edx
 3f1:	8b 45 08             	mov    0x8(%ebp),%eax
 3f4:	e8 d8 fe ff ff       	call   2d1 <putc>
        putc(fd, c);
 3f9:	89 fa                	mov    %edi,%edx
 3fb:	8b 45 08             	mov    0x8(%ebp),%eax
 3fe:	e8 ce fe ff ff       	call   2d1 <putc>
      }
      state = 0;
 403:	be 00 00 00 00       	mov    $0x0,%esi
 408:	eb 8d                	jmp    397 <printf+0x2c>
        printint(fd, *ap, 10, 1);
 40a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 40d:	8b 17                	mov    (%edi),%edx
 40f:	83 ec 0c             	sub    $0xc,%esp
 412:	6a 01                	push   $0x1
 414:	b9 0a 00 00 00       	mov    $0xa,%ecx
 419:	8b 45 08             	mov    0x8(%ebp),%eax
 41c:	e8 ca fe ff ff       	call   2eb <printint>
        ap++;
 421:	83 c7 04             	add    $0x4,%edi
 424:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 427:	83 c4 10             	add    $0x10,%esp
      state = 0;
 42a:	be 00 00 00 00       	mov    $0x0,%esi
 42f:	e9 63 ff ff ff       	jmp    397 <printf+0x2c>
        printint(fd, *ap, 16, 0);
 434:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 437:	8b 17                	mov    (%edi),%edx
 439:	83 ec 0c             	sub    $0xc,%esp
 43c:	6a 00                	push   $0x0
 43e:	b9 10 00 00 00       	mov    $0x10,%ecx
 443:	8b 45 08             	mov    0x8(%ebp),%eax
 446:	e8 a0 fe ff ff       	call   2eb <printint>
        ap++;
 44b:	83 c7 04             	add    $0x4,%edi
 44e:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 451:	83 c4 10             	add    $0x10,%esp
      state = 0;
 454:	be 00 00 00 00       	mov    $0x0,%esi
 459:	e9 39 ff ff ff       	jmp    397 <printf+0x2c>
        s = (char*)*ap;
 45e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 461:	8b 30                	mov    (%eax),%esi
        ap++;
 463:	83 c0 04             	add    $0x4,%eax
 466:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if(s == 0)
 469:	85 f6                	test   %esi,%esi
 46b:	75 28                	jne    495 <printf+0x12a>
          s = "(null)";
 46d:	be 4f 06 00 00       	mov    $0x64f,%esi
 472:	8b 7d 08             	mov    0x8(%ebp),%edi
 475:	eb 0d                	jmp    484 <printf+0x119>
          putc(fd, *s);
 477:	0f be d2             	movsbl %dl,%edx
 47a:	89 f8                	mov    %edi,%eax
 47c:	e8 50 fe ff ff       	call   2d1 <putc>
          s++;
 481:	83 c6 01             	add    $0x1,%esi
        while(*s != 0){
 484:	0f b6 16             	movzbl (%esi),%edx
 487:	84 d2                	test   %dl,%dl
 489:	75 ec                	jne    477 <printf+0x10c>
      state = 0;
 48b:	be 00 00 00 00       	mov    $0x0,%esi
 490:	e9 02 ff ff ff       	jmp    397 <printf+0x2c>
 495:	8b 7d 08             	mov    0x8(%ebp),%edi
 498:	eb ea                	jmp    484 <printf+0x119>
        putc(fd, *ap);
 49a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 49d:	0f be 17             	movsbl (%edi),%edx
 4a0:	8b 45 08             	mov    0x8(%ebp),%eax
 4a3:	e8 29 fe ff ff       	call   2d1 <putc>
        ap++;
 4a8:	83 c7 04             	add    $0x4,%edi
 4ab:	89 7d e4             	mov    %edi,-0x1c(%ebp)
      state = 0;
 4ae:	be 00 00 00 00       	mov    $0x0,%esi
 4b3:	e9 df fe ff ff       	jmp    397 <printf+0x2c>
        putc(fd, c);
 4b8:	89 fa                	mov    %edi,%edx
 4ba:	8b 45 08             	mov    0x8(%ebp),%eax
 4bd:	e8 0f fe ff ff       	call   2d1 <putc>
      state = 0;
 4c2:	be 00 00 00 00       	mov    $0x0,%esi
 4c7:	e9 cb fe ff ff       	jmp    397 <printf+0x2c>
    }
  }
}
 4cc:	8d 65 f4             	lea    -0xc(%ebp),%esp
 4cf:	5b                   	pop    %ebx
 4d0:	5e                   	pop    %esi
 4d1:	5f                   	pop    %edi
 4d2:	5d                   	pop    %ebp
 4d3:	c3                   	ret    

000004d4 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 4d4:	55                   	push   %ebp
 4d5:	89 e5                	mov    %esp,%ebp
 4d7:	57                   	push   %edi
 4d8:	56                   	push   %esi
 4d9:	53                   	push   %ebx
 4da:	8b 5d 08             	mov    0x8(%ebp),%ebx
  Header *bp, *p;

  bp = (Header*)ap - 1;
 4dd:	8d 4b f8             	lea    -0x8(%ebx),%ecx
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 4e0:	a1 fc 08 00 00       	mov    0x8fc,%eax
 4e5:	eb 02                	jmp    4e9 <free+0x15>
 4e7:	89 d0                	mov    %edx,%eax
 4e9:	39 c8                	cmp    %ecx,%eax
 4eb:	73 04                	jae    4f1 <free+0x1d>
 4ed:	39 08                	cmp    %ecx,(%eax)
 4ef:	77 12                	ja     503 <free+0x2f>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 4f1:	8b 10                	mov    (%eax),%edx
 4f3:	39 c2                	cmp    %eax,%edx
 4f5:	77 f0                	ja     4e7 <free+0x13>
 4f7:	39 c8                	cmp    %ecx,%eax
 4f9:	72 08                	jb     503 <free+0x2f>
 4fb:	39 ca                	cmp    %ecx,%edx
 4fd:	77 04                	ja     503 <free+0x2f>
 4ff:	89 d0                	mov    %edx,%eax
 501:	eb e6                	jmp    4e9 <free+0x15>
      break;
  if(bp + bp->s.size == p->s.ptr){
 503:	8b 73 fc             	mov    -0x4(%ebx),%esi
 506:	8d 3c f1             	lea    (%ecx,%esi,8),%edi
 509:	8b 10                	mov    (%eax),%edx
 50b:	39 d7                	cmp    %edx,%edi
 50d:	74 19                	je     528 <free+0x54>
    bp->s.size += p->s.ptr->s.size;
    bp->s.ptr = p->s.ptr->s.ptr;
  } else
    bp->s.ptr = p->s.ptr;
 50f:	89 53 f8             	mov    %edx,-0x8(%ebx)
  if(p + p->s.size == bp){
 512:	8b 50 04             	mov    0x4(%eax),%edx
 515:	8d 34 d0             	lea    (%eax,%edx,8),%esi
 518:	39 ce                	cmp    %ecx,%esi
 51a:	74 1b                	je     537 <free+0x63>
    p->s.size += bp->s.size;
    p->s.ptr = bp->s.ptr;
  } else
    p->s.ptr = bp;
 51c:	89 08                	mov    %ecx,(%eax)
  freep = p;
 51e:	a3 fc 08 00 00       	mov    %eax,0x8fc
}
 523:	5b                   	pop    %ebx
 524:	5e                   	pop    %esi
 525:	5f                   	pop    %edi
 526:	5d                   	pop    %ebp
 527:	c3                   	ret    
    bp->s.size += p->s.ptr->s.size;
 528:	03 72 04             	add    0x4(%edx),%esi
 52b:	89 73 fc             	mov    %esi,-0x4(%ebx)
    bp->s.ptr = p->s.ptr->s.ptr;
 52e:	8b 10                	mov    (%eax),%edx
 530:	8b 12                	mov    (%edx),%edx
 532:	89 53 f8             	mov    %edx,-0x8(%ebx)
 535:	eb db                	jmp    512 <free+0x3e>
    p->s.size += bp->s.size;
 537:	03 53 fc             	add    -0x4(%ebx),%edx
 53a:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 53d:	8b 53 f8             	mov    -0x8(%ebx),%edx
 540:	89 10                	mov    %edx,(%eax)
 542:	eb da                	jmp    51e <free+0x4a>

00000544 <morecore>:

static Header*
morecore(uint nu)
{
 544:	55                   	push   %ebp
 545:	89 e5                	mov    %esp,%ebp
 547:	53                   	push   %ebx
 548:	83 ec 04             	sub    $0x4,%esp
 54b:	89 c3                	mov    %eax,%ebx
  char *p;
  Header *hp;

  if(nu < 4096)
 54d:	3d ff 0f 00 00       	cmp    $0xfff,%eax
 552:	77 05                	ja     559 <morecore+0x15>
    nu = 4096;
 554:	bb 00 10 00 00       	mov    $0x1000,%ebx
  p = sbrk(nu * sizeof(Header));
 559:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
 560:	83 ec 0c             	sub    $0xc,%esp
 563:	50                   	push   %eax
 564:	e8 48 fd ff ff       	call   2b1 <sbrk>
  if(p == (char*)-1)
 569:	83 c4 10             	add    $0x10,%esp
 56c:	83 f8 ff             	cmp    $0xffffffff,%eax
 56f:	74 1c                	je     58d <morecore+0x49>
    return 0;
  hp = (Header*)p;
  hp->s.size = nu;
 571:	89 58 04             	mov    %ebx,0x4(%eax)
  free((void*)(hp + 1));
 574:	83 c0 08             	add    $0x8,%eax
 577:	83 ec 0c             	sub    $0xc,%esp
 57a:	50                   	push   %eax
 57b:	e8 54 ff ff ff       	call   4d4 <free>
  return freep;
 580:	a1 fc 08 00 00       	mov    0x8fc,%eax
 585:	83 c4 10             	add    $0x10,%esp
}
 588:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 58b:	c9                   	leave  
 58c:	c3                   	ret    
    return 0;
 58d:	b8 00 00 00 00       	mov    $0x0,%eax
 592:	eb f4                	jmp    588 <morecore+0x44>

00000594 <malloc>:

void*
malloc(uint nbytes)
{
 594:	55                   	push   %ebp
 595:	89 e5                	mov    %esp,%ebp
 597:	53                   	push   %ebx
 598:	83 ec 04             	sub    $0x4,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 59b:	8b 45 08             	mov    0x8(%ebp),%eax
 59e:	8d 58 07             	lea    0x7(%eax),%ebx
 5a1:	c1 eb 03             	shr    $0x3,%ebx
 5a4:	83 c3 01             	add    $0x1,%ebx
  if((prevp = freep) == 0){
 5a7:	8b 0d fc 08 00 00    	mov    0x8fc,%ecx
 5ad:	85 c9                	test   %ecx,%ecx
 5af:	74 04                	je     5b5 <malloc+0x21>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 5b1:	8b 01                	mov    (%ecx),%eax
 5b3:	eb 4d                	jmp    602 <malloc+0x6e>
    base.s.ptr = freep = prevp = &base;
 5b5:	c7 05 fc 08 00 00 00 	movl   $0x900,0x8fc
 5bc:	09 00 00 
 5bf:	c7 05 00 09 00 00 00 	movl   $0x900,0x900
 5c6:	09 00 00 
    base.s.size = 0;
 5c9:	c7 05 04 09 00 00 00 	movl   $0x0,0x904
 5d0:	00 00 00 
    base.s.ptr = freep = prevp = &base;
 5d3:	b9 00 09 00 00       	mov    $0x900,%ecx
 5d8:	eb d7                	jmp    5b1 <malloc+0x1d>
    if(p->s.size >= nunits){
      if(p->s.size == nunits)
 5da:	39 da                	cmp    %ebx,%edx
 5dc:	74 1a                	je     5f8 <malloc+0x64>
        prevp->s.ptr = p->s.ptr;
      else {
        p->s.size -= nunits;
 5de:	29 da                	sub    %ebx,%edx
 5e0:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 5e3:	8d 04 d0             	lea    (%eax,%edx,8),%eax
        p->s.size = nunits;
 5e6:	89 58 04             	mov    %ebx,0x4(%eax)
      }
      freep = prevp;
 5e9:	89 0d fc 08 00 00    	mov    %ecx,0x8fc
      return (void*)(p + 1);
 5ef:	83 c0 08             	add    $0x8,%eax
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 5f2:	83 c4 04             	add    $0x4,%esp
 5f5:	5b                   	pop    %ebx
 5f6:	5d                   	pop    %ebp
 5f7:	c3                   	ret    
        prevp->s.ptr = p->s.ptr;
 5f8:	8b 10                	mov    (%eax),%edx
 5fa:	89 11                	mov    %edx,(%ecx)
 5fc:	eb eb                	jmp    5e9 <malloc+0x55>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 5fe:	89 c1                	mov    %eax,%ecx
 600:	8b 00                	mov    (%eax),%eax
    if(p->s.size >= nunits){
 602:	8b 50 04             	mov    0x4(%eax),%edx
 605:	39 da                	cmp    %ebx,%edx
 607:	73 d1                	jae    5da <malloc+0x46>
    if(p == freep)
 609:	39 05 fc 08 00 00    	cmp    %eax,0x8fc
 60f:	75 ed                	jne    5fe <malloc+0x6a>
      if((p = morecore(nunits)) == 0)
 611:	89 d8                	mov    %ebx,%eax
 613:	e8 2c ff ff ff       	call   544 <morecore>
 618:	85 c0                	test   %eax,%eax
 61a:	75 e2                	jne    5fe <malloc+0x6a>
        return 0;
 61c:	b8 00 00 00 00       	mov    $0x0,%eax
 621:	eb cf                	jmp    5f2 <malloc+0x5e>
