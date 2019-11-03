// Physical memory allocator, intended to allocate
// memory for user processes, kernel stacks, page table pages,
// and pipe buffers. Allocates 4096-byte pages.

#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "spinlock.h"

void freerange(void *vstart, void *vend);
extern char end[]; // first address after kernel loaded from ELF file
                   // defined by the kernel linker script in kernel.ld
int lastPid;
struct run
{
  struct run *next;
  int pid;
  struct run *prev;
};
struct
{
  struct spinlock lock;
  int use_lock;
  struct run *freelist; //maintains free list
  //add to track add. which page was alloacted by which procs
} kmem;

struct af
{
  int addr;
  int pid;
  struct af *next;
  struct af *prev;
};
struct 
{
  struct af *aFrames;
} allocFrames;

int framesList[16384];
int pidList[16384];
int frame;
int* getframesList(void)
{
  return framesList;
}
int
getframe(void) {
  return frame;
}
int* getpidList(void) {
  return pidList;
}


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
  for (; p + PGSIZE <= (char *)vend; p += PGSIZE)
  {
    kfree2(p);
    
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

  // cprintf("freeing: %x\n", V2P(v)>>12);

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);

  if (kmem.use_lock)
    acquire(&kmem.lock);
  r = (struct run *)v;
  r->pid = -1;
  //we need to ensure that the freelist is sorted when a freed frame is added. 
  //iterate through the freelist to find the frame that
  
  // if the freelist is empty add it to head.
  if(r > kmem.freelist) {
    
  } else {
    // if the list is not empty, find the first element smaller than 

  }
  struct run *curr = kmem.freelist;
  struct run *prev = kmem.freelist;
  while(r<curr) {
    prev = curr;
    curr = curr->next;
  }
  curr->prev = r;
  r->next = curr;
  if(prev == kmem.freelist){
    kmem.freelist = r;
  } else{
    prev->next = r;
    r->prev = prev;
  }
  //find the frame being freed in the allocated list
  for(int i = 0; i<frame; i++){
    if(framesList[i] == V2P(r)>>12){
      //if the process is found, remove it and shift list
      for(int j = i; j<frame-1;j++) {
        framesList[j] = framesList[j+1];
      }
      frame--;
      break;
    }
  }
  // r->next = kmem.freelist;
  // kmem.freelist = r;
  
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
  r->pid = -1;
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
kalloc(int pid)
{
  struct run *r;
  struct af *a;

  if (kmem.use_lock)
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;

  // we need to get the PA to retrieve the frame number
  if (r)
  {
    
    r->pid = pid;
    // if the last process allocated is the same as the current, then create a free frame
    int frameNumber = V2P(r) >> 12;
    if(frameNumber > 1023) {
      pidList[frame] = pid;
      framesList[frame++] = frameNumber;
      a = (struct af *)r;
      //we can get the frameNumber of a with V2P>>12
      a->next = allocFrames.aFrames;
      a->pid = pid;
      allocFrames.aFrames = a;
      
    }  
    kmem.freelist = r->next;
    
  }
  if (kmem.use_lock)
  {
    release(&kmem.lock);
  }
  return (char *)r;
}

// called by the excluded methods (inituvm, setupkvm, walkpgdir). We need to
// "mark these pages as belonging to an unknown process". (-2)
char *
kalloc2(void)
{
  struct run *r;
  struct af *a;

  if (kmem.use_lock)
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;

  // we need to get the PA to retrieve the frame number
  if (r)
  {
    int frameNumber = V2P(r) >> 12; 
    if(frameNumber > 1023) {
      pidList[frame] = -2; // -2 for unknown process.
      framesList[frame++] = frameNumber;
       a = (struct af *)r;
      //we can get the frameNumber of a with V2P>>12
      a->next = allocFrames.aFrames;
      a->pid = -2;
      allocFrames.aFrames = a;
      
    }    
    kmem.freelist = r->next;
   
  }
  if (kmem.use_lock)
  {
    release(&kmem.lock);
  }
  return (char *)r;
}