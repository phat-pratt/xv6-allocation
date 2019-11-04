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
int kinitdone;
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

int framesList[65536];
int* getframesList(void)
{
  return framesList;
}



// Initialization happens in two phases.
// 1. main() calls kinit1() while still using entrypgdir to place just
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void kinit1(void *vstart, void *vend)
{
  kinitdone=0;
  initlock(&kmem.lock, "kmem");
  kmem.use_lock = 0;
  freerange(vstart, vend);
}

void kinit2(void *vstart, void *vend)
{
  freerange(vstart, vend);
  kmem.use_lock = 1;
  kinitdone =1;

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
  int i = V2P(r)>>12;
  struct run *curr = kmem.freelist;
  struct run *prev = kmem.freelist;
  while(r<curr) {
    prev = curr;
    curr = curr->next;
  }
  curr->prev = r;
  r->next = curr;
  if(prev == curr){
    r->prev = kmem.freelist;
    kmem.freelist->prev=r;
    kmem.freelist = r;
    
  } else{
    prev->next = r;
    r->prev = prev;
  }
  //find the frame being freed in the allocated list
  
  framesList[i] = -1;
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
  kmem.freelist->prev = r;
  r->prev = kmem.freelist;
  r->pid = -1;
  int i = V2P(r)>>12;
  framesList[i] = -1;
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
  if (kmem.use_lock)
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;
  // we need to get the PA to retrieve the frame number
  int position = 0;
  int frameNumber;
  while (r) {
    frameNumber = V2P(r) >> 12;
    r->pid = pid;
    if(framesList[frameNumber - 1] == 0){
      framesList[frameNumber - 1] = -1;
    }
    if(framesList[frameNumber + 1] == 0){
      framesList[frameNumber + 1] = -1;
    }
    //if the previous addr is allocated to the same pid and the next is not -> Allocate
    if((framesList[frameNumber - 1] == -1)
    && (framesList[frameNumber + 1] ==  -1)) {
      break;
    }
    if((framesList[frameNumber - 1] == pid)
    && (framesList[frameNumber + 1] ==  -1)) {
      break;
    }
    if((framesList[frameNumber - 1] == -1)
    && (framesList[frameNumber + 1] ==  pid)) {
      break;
    }
    // if the previous and next proc is allocated to the same pid -> Allocate.
    if((framesList[frameNumber - 1] == pid)
    && (framesList[frameNumber + 1] ==  pid)) {
      break;
    }
    if((framesList[frameNumber - 1] == pid)
    && (framesList[frameNumber + 1] ==  -2)) {
      break;
    }
    //if the previous frame if free and the next frame is free -> Allocate
    
    if((framesList[frameNumber - 1] == -2)
    && (framesList[frameNumber + 1] ==  pid)) {
      break;
    }
    if((framesList[frameNumber - 1] == -1)
    && (framesList[frameNumber + 1] ==  -2)) {
      break;
    }
    if((framesList[frameNumber - 1] == -2)
    && (framesList[frameNumber + 1] ==  -1)) {
      break;
    }
    position++;
    r = r->next;
  }
  if (r){
    frameNumber = V2P(r) >> 12;

    // if the last process allocated is the same as the current, then create a free frame
    if(frameNumber > 1023) {
      framesList[frameNumber] = pid;
    }    
    
    if(r == kmem.freelist){
      kmem.freelist = r->next;
    } else{
      struct run *temp = kmem.freelist;
      for(int i = 0; i<position-1; i++)
        temp = temp->next;

      struct run *next = temp->next->next;
      temp->next = next;
    }
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

  if (kmem.use_lock)
  {
    acquire(&kmem.lock);
  }
  r = kmem.freelist;
 
  int frameNumber;
  int position = 0;
  while (r) {
  
    frameNumber = V2P(r) >> 12;
    r->pid = -2;

    //if the previous addr is allocated to the same pid and the next is not -> Allocate
    if((framesList[frameNumber - 1] == -2)
    && (framesList[frameNumber + 1] ==  -1)) {
      break;
    }
    // if the previous and next proc is allocated to the same pid -> Allocate.
    if((framesList[frameNumber - 1] == -2)
    && (framesList[frameNumber + 1] ==  -2)) {
      break;
    }
    //if the previous frame if free and the next frame is free -> Allocate
    if((framesList[frameNumber - 1] == -1)
    && (framesList[frameNumber + 1] ==  -1)) {
      break;
    }
    if((framesList[frameNumber - 1] == -1)
    && (framesList[frameNumber + 1] ==  -2)) {
      break;
    }
    if((framesList[frameNumber - 1] != -1)
    && (framesList[frameNumber + 1] ==  -2)) {
      break;
    }
    if((framesList[frameNumber - 1] == -2)
    && (framesList[frameNumber + 1] !=  -1)) {
      break;
    }
    if((framesList[frameNumber - 1] != -1)
    && (framesList[frameNumber + 1] !=  -1)) {
      break;
    }
    if((framesList[frameNumber - 1] != -1)
    && (framesList[frameNumber + 1] ==  -1)) {
      break;
    }
    if((framesList[frameNumber - 1] == -1)
    && (framesList[frameNumber + 1] !=  -1)) {
      break;
    }
    position++;
    r = r->next;
  }

  // we need to get the PA to retrieve the frame number
  if (r)
  {
    frameNumber = V2P(r) >> 12; 
    if(frameNumber > 1023) {
      framesList[frameNumber] = -2;
    }    

    if(r == kmem.freelist){
      kmem.freelist = r->next;
    } else{
      struct run *temp = kmem.freelist;
      for(int i = 0; i<position-1; i++)
        temp = temp->next;

      struct run *next = temp->next->next;
      temp->next = next;
    }  
  }
  if (kmem.use_lock)
  {
    release(&kmem.lock);
  }
  return (char *)r;
}
