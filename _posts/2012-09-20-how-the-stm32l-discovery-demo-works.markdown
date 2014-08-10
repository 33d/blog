---
author: sourcegate
comments: true
date: 2012-09-20 12:46:34+00:00
layout: post
slug: how-the-stm32l-discovery-demo-works
title: How the STM32L Discovery demo works
wordpress_id: 209
categories:
- STM32L Discovery
tags:
- demo
- discovery
- example
- startup
- stm
- stm32
- stm32l
- tutorial
- vector table
---

In [my previous post](http://sourcegate.wordpress.com/2012/09/18/getting-started-with-an-stm32l-discovery-with-linux-and-gcc/), I got a basic program running on a STM32L Discovery board.  Now I hope to work out what the program works.

The program contained this data structure:

    
    // Define the vector table
    unsigned int *myvectors[4]
    __attribute__ ((section("vectors"))) = {
        (unsigned int *) STACK_TOP,         // stack pointer
        (unsigned int *) main,              // code entry point
        (unsigned int *) nmi_handler,       // NMI handler (not really)
        (unsigned int *) hardfault_handler  // hard fault handler
    };


This is a structure with four pointers.  It also has this in front: `__attribute__ ((section("vectors")))`.  The linker script contains a section with a similar name, and while I don't know anything about linker scripts, it looks like it goes right at the start of the flash memory. In other words, these four pointers look like the first 32 bytes of any program.

Is there any documentation that describes this? After suffering through ST's "product selector", I found [the page for the CPU](http://www.st.com/internet/mcu/product/248820.jsp), where I found the reference manual. This is a bit like a AVR datasheet; it tells you all about the interfaces the chip has. Since my program doesn't talk to the outside world yet, this document isn't terribly helpful; but it does point to [a document from ARM about the CPU core](http://infocenter.arm.com/help/topic/com.arm.doc.ddi0337g/DDI0337G_cortex_m3_r2p0_trm.pdf).

After searching for various terms in this document, I eventually found out that this table is called the "vector table" and is described in section 5.9.1. Although the table in the code is self-explanatory, it's nice to find the reference to what exactly it does. The document also says there's other vectors that may appear after these, so that may be useful to know one day.

Now that I've started to find my way around the documentation, maybe I can go on to making the chip actually do something!
