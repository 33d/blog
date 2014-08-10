---
author: sourcegate
comments: true
date: 2014-04-06 06:44:08+00:00
layout: post
slug: running-a-z-machine-on-an-avr
title: Running a Z-machine on an AVR
wordpress_id: 383
tags:
- advenure
- arduino
- avr
- infocom
- text
- tv
- video
- z-machine
graphic: zork.png
---

Can you make a [Z-machine](http://en.wikipedia.org/wiki/Z-machine) console - a virtual machine for text adventure games -  complete with screen and keyboard on an AVR?

No. Well, probably not on a ATmega328P.

I [got the code for ZIP](ftp://sunsite.unc.edu/pub/Linux/games/textrpg/zipinfocm-2.0.linux.tar.gz), and stripped out all of the code for reading files and displaying stuff on the screen.  This let me compile it with avr-gcc.

I looked at the result of objdump:

    
    $ avr-objdump -h zip_linux
    
    zip_linux:     file format elf32-avr
    
    Sections:
    Idx Name          Size      VMA       LMA       File off  Algn
      0 .data         000001e4  00800100  0000579c  00005830  2**0
                      CONTENTS, ALLOC, LOAD, DATA
      1 .text         0000579c  00000000  00000000  00000094  2**1
                      CONTENTS, ALLOC, LOAD, READONLY, CODE
      2 .bss          00000ac8  008002e4  008002e4  00005a14  2**0
                      ALLOC
      3 .stab         0000dcec  00000000  00000000  00005a14  2**2
                      CONTENTS, READONLY, DEBUGGING
      4 .stabstr      00003aad  00000000  00000000  00013700  2**0
                      CONTENTS, READONLY, DEBUGGING
      5 .comment      00000022  00000000  00000000  000171ad  2**0
                      CONTENTS, READONLY
    
    


The good news is that the code (the .text section) fits into 22k.  That leaves 10k for the screen rendering code (probably from [TellyMate](http://www.batsocks.co.uk/products/Other/TellyMate.htm)), the keyboard and the SD card code.

The .data section is quite small too, which means there aren't many strings in the interpreter itself.

The problem is the .bss section, which gets copied to RAM on startup.  It's 2760 bytes, much more than the 2048 which this chip has.

Let's look at this further:

    
    $ avr-objdump -t zip_linux | grep bss | sort -t $'\t' -k 2
    ...
    
    0080030c g     O .bss    00000004 pc
    00800da6 g     O .bss    00000006 __iob
    00000114 g       .text    00000010 __do_clear_bss
    00800552 g     O .bss    0000004e lookup_table
    00800436 l     O .bss    00000100 record_name
    00800332 l     O .bss    00000100 save_name
    008005a0 g     O .bss    00000800 stack


There's a 2048 byte stack, which fills the entire memory!  The Infocom games [might only need a 1k stack](http://www.gnelson.demon.co.uk/zspec/sect06.html), which will help.

Tellymate has a 38x25 screen, which needs 950 bytes.  This could be brought down to 10 lines, but games might be tricky to play.  The ZX80 didn't store a full line if it didn't fill the width of the screen, but adventure games tend to be wordy so this won't help much.

An SD card library needs about 600 bytes of RAM, which blows the budget.  We'd have to go without a filesystem on the SD card, because it takes up too much flash space.  It sounds like the 512 byte buffer might be optional.

4k of RAM should be plenty.  But with ARM chips being much cheaper than the larger AVRs, that might be the way to go - if I can sort out the [jittering image problems](http://sourcegate.wordpress.com/2012/11/04/code-to-produce-video-signals-on-the-stm32l-discovery/).

You might be able to squeeze the interpreter only onto the chip, and communicate with it via its serial port, or another AVR running TellyMate.

**Update:** It turns out I wasn't the only one to look at this - Rossum [implemented it on the 2560-byte ATmega32U4](http://rossumblog.com/2011/04/19/zork-for-the-microtouch/), but needed to store a 1MB swap file on the SD card!  I don't know why you need that much - maybe you don't - but I forgot to include dynamic memory and room for the stack.
