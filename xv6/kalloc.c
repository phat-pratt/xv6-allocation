// Physical memory allocator, intended to allocate
// memory for user processes, kernel stacks, page table pages,
// and pipe buffers. Allocates 4096-byte pages.

#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "spinlock.h"

static int frames[4096];
static int frame = 0;

void freerange(void *vstart, void *vend);
extern char end[]; // first address after kernel loaded from ELF file
                   // defined by the kernel linker script in kernel.ld

struct run
{
  struct run *next;
};

struct
{
  struct spinlock lock;
  int use_lock;
  struct run *freelist; //maintains free list
  //add to track add. which page was alloacted by which procs
} kmem;

// Initialization happens in two phases.
// 1. main() calls kinit1() while still using entrypgdir to place just
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void kinit1(void *vstart, void *vend)
{
  initlock(&kmem.lock, "kmem");
  kmem.use_lock = 0;
  freerange(vstart, vend);
}

void kinit2(void *vstart, void *vend)
{
  freerange(vstart, vend);
  kmem.use_lock = 1;
}

//free list is created
// Look at how the original free list is constructed
// and only add every other frame to this list.
void freerange(void *vstart, void *vend)
{
  char *p;
  p = (char *)PGROUNDUP((uint)vstart);
  //we only want to allocate every other frame...
  int i = 0;
  for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
  {
    if((i+1)%2 == 0)
      kfree(p);
    i++;
  }
}
// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(char *v)
{
  struct run *r;

  if ((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);

  if (kmem.use_lock)
    acquire(&kmem.lock);
  r = (struct run *)v;
  r->next = kmem.freelist;
  kmem.freelist = r;
  if (kmem.use_lock)
    release(&kmem.lock);
}
void kfree2(char *v)
{
  struct run *r;

  if ((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);

  if (kmem.use_lock)
    acquire(&kmem.lock);
  r = (struct run *)v;
  r->next = kmem.freelist;
  kmem.freelist = r;
  if (kmem.use_lock)
    release(&kmem.lock);
}
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
// From spec - kalloc manages freelist and allocates physical memory
// returns first page on the freelist
char *
kalloc(void)
{
  // Translating the address allocated in kalloc to a page number:
  //      1. convert the address from a VA in the kernal's address space to a PA
  //      2. shift and mask off the page offset from a 32-bit address to obtain the frame number

  // Modify the allocation routine to ensure that there is a free page between pages

  struct run *r;
  if (kmem.use_lock)
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;

  // we need to get the PA to retrieve the frame number
  if (r)
  {
    int va = (int)&r;
    //cprintf("r(VA): %x\tr(PA): %x\tPA complete: %x\n",  va & 0xFFF, V2P(r)>>12, V2P(r)+(va & 0xFFF));

    kmem.freelist = r->next;
    //frames[frame] = V2P(r)>>12;
  }
  if (kmem.use_lock)
  {
    release(&kmem.lock);
  }
  return (char *)r;
}
