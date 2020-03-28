---
layout: post
title: Cyber FastTrack 2020 Forensics RH01 challenge
slug: cyber-fasttrack-spring-2020-rh01
---

This is the RH01 challenge from Cyber FastTrack Spring 2020.

> We received this file, our analysts believe it is too random to be solved. Can you do anything with this?

the target file:

```
2b991035290d99b2fbf37fb54320ad6ce84b136d  rh01.zip
```

The program asks for three numbers, then produces a message that the numbers were wrong.

I haven't done much reverse engineering before, but knew about Ghidra, and blundered by way into opening the binary in that, searching for the last message, then looking at the routine which produces it.  When you look at a routine in Ghidra, it shows a psuedo-C implementation of it, so I could see what was going on:

```
  FUN_000108a1("I\'m thinking of three random numbers, guess which three:");
  local_44 = 0;
  while (local_44 < 3) {
    printf("\nnumber %d:",local_44 + 1);
    __isoc99_scanf(&DAT_00010c21,local_20 + local_44 * 4);
    local_44 = local_44 + 1;
  }
  uVar2 = memcmp(&local_2c,local_20,0xc);
  iVar3 = memcmp(&local_2c,local_20,0xc);
  if (iVar3 != 0) {
    printf("\nI was actually thinking of %d, %d and %d.\n",local_2c,local_28,local_24);
                    /* WARNING: Subroutine does not return */
    exit(0);
  }
  FUN_0001070d(uVar2,uVar2);
  uVar2 = 0;
  if (local_14 != *(int *)(in_GS_OFFSET + 0x14)) {
    uVar2 = FUN_00010b40();
  }
  return uVar2;
```

What I think is going on:

* Three numbers are typed in, they're stored as 4 bytes each after `local_20`.  (It looks like the number is some local variable offset, perhaps relative to the stack pointer when the function is running.)
* 12 bytes are compared - those from the numbers typed in, to another 12 bytes where the first 4 is a number produced by `rand()`, but I don't know what's in the other 8 bytes.
* The result of memcmp - which should be 0 if the numbers are correct - are passed to another function.

A good start is to simply replace the branch with one which doesn't exit.  When I put the cursor on the comparison, I see a `JNZ` (jump if not zero) instruction.  I used a hex editor to replace it (`75 24`) with a JZ (jump if zero) instruction (`74 24`).

This seems to have worked, but now displays some garbage after typing the numbers in.  I suspect the flag is unscrambled using some of the numbers, by that last function.  But if the number comparison succeeds, the `memcmp`s will return 0, which are passed to that function.  How can I change this?

The function call looks like:

```
        00010a73 ff 75 d4        PUSH       dword ptr [EBP + local_34]
        00010a76 ff 75 d8        PUSH       dword ptr [EBP + local_30]
        00010a79 e8 8f fc        CALL       FUN_0001070d
```

Two local numbers are pushed on to the stack, then the function is called.  Perhaps I can put zeroes on the stack instead.

First I need the instructions for this.  Can `nasm` easily do this, or does it require sections and other stuff I don't know much about?  Let's see what happens:

```
$ echo 'push 0' > zero.asm
$ nasm -o zero zero.asm
$ hd zero
00000000  6a 00                                             |j.|
```

If I look at [a x86 opcode table](http://sparksandflames.com/files/x86InstructionChart.html), 6a is indeed `PUSH`.

There original pushes were 6 bytes, now there are 4; something needs to fill the last two bytes.  NOPs will do, which is the value 90.

So I'll replace:

```
ff 75 d4 ff 75 d8
```

with

```
6a 00 6a 00 90 90
```

and see what happens:

```
$ ./RH01
I'm thinking of three random numbers, guess which three:
number 1:1

number 2:1

number 3:1
Wait, how did you do that? I thought I was totally random...
Flag: Sow_The_Seeds_Of_Doubt
```

Not bad for a first effort!

