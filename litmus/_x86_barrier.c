/**********************/
/* User level barrier */
/**********************/

typedef struct {
  volatile int c,sense ;
} sense_t ;


static void barrier_init(sense_t *p) {
  p->c = N ;
  p->sense = 0 ;
}

static void barrier_wait(sense_t *p, int *mySense) {
  int sense = *mySense ;
  int r1 ;
  asm __volatile__ (
    "movl $-1,%[eax]\n\t"
    "lock xaddl %[eax],%[c]\n\t"
    "subl $1,%[eax]\n\t"
    "je 0f\n\t"
    "1:\n\t"
    "cmpl %[ms],%[s]\n\t"
    "je 1b\n\t"
    "jmp 2f\n\t"
    "0:\n\t"
    "movl %[np],%[c]\n\t"
    "xorl %[eax],%[eax]\n\t"
    "testl %[ms],%[ms]\n\t"
    "sete %%al\n\t"
    "movl %[eax],%[s]\n\t"
    "mfence\n\t"
    "jmp 3f\n\t"
    "2:\n\t"
    "xorl %[eax],%[eax]\n\t"
    "testl %[ms],%[ms]\n\t"
    "sete %%al\n\t"
    "3:\n\t"
    : [eax] "=&a" (r1)
    : [ms] "r" (sense), [s] "m" (p->sense), [c] "m" (p->c), [np] "n" (N)
    : "memory") ;
  *mySense = r1 ;
}

