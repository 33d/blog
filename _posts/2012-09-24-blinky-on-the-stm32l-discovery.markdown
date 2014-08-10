---
author: sourcegate
comments: true
date: 2012-09-24 09:42:10+00:00
layout: post
slug: blinky-on-the-stm32l-discovery
title: Blinky on the STM32L Discovery
wordpress_id: 213
categories:
- STM32L Discovery
tags:
- blink
- blinky
- led
- programming
- stm
- stm32
---

My program seems to have [locked-in syndrome](http://en.wikipedia.org/wiki/Locked-in_syndrome), so now I'll see if I can get it to flash an LED.

A good start would be to check [the schematic](http://www.st.com/internet/com/TECHNICAL_RESOURCES/TECHNICAL_DIAGRAM/SCHEMATICPACK/stm32l-discovery_sch.zip) for where the LED is connected.  There's one connected to PB6 and PB7, and they're actually marked with this on the PCB, next to the two push buttons.

Now how to interface them?  The [programming manual](http://www.st.com/internet/com/TECHNICAL_RESOURCES/TECHNICAL_LITERATURE/PROGRAMMING_MANUAL/CD00242299.pdf) has a whole section on GPIOs.  It mentions that there are registers for selecting the alternate function (which is how you activate SPI, the USARTs etc), selecting whether the pin is an output or input, whether there are pull-up or pull-down resistors activated, among other things.  One thing worth noting is section 6.3.1, which says "During and just after reset, the alternate functions are not active and the I/O ports are configured in input floating mode."  What it doesn't say though is how the registers map to the I/O pins.

The first page of the reference manual mentions one document I haven't looked at yet: [the datasheet](http://www.st.com/internet/com/TECHNICAL_RESOURCES/TECHNICAL_LITERATURE/DATASHEET/CD00277537.pdf).  And sure enough, the memory map in section 5 says that port B is at memory location 0x40020400.  There's still no mention of how these map to the I/O registers, or how to access the registers from C code.

Figure 1 of the reference manual suggests the GPIO access is via the "AHB system bus".  A search of [the CPU reference manual](http://infocenter.arm.com/help/topic/com.arm.doc.ddi0337g/DDI0337G_cortex_m3_r2p0_trm.pdf) says that AHB is the "Advanced High-performance Bus", which doesn't really mean anything for this.

Another look at the memory map shows that port B goes from 0x40020400 to 0x400207FF.  That's 1kB of address space, so maybe all of the port registers live here?  If I assume that, I need to set a few bits in GPIOA_MODER at 0x40020400, and turn on the output pin in GPIOA_ODR at 0x40020414 (the reference manual shows the offset of this register as 0x14).  Like this:

    
        *((int*) 0x40020400) = 0x00005000;
        *((int*) 0x40020414) = 0x00000080;


No that doesn't work... time to cheat.  I'll look at "blinky.c", which is included with the Keil IDE.  It mentions a GPIO clock, maybe I need to enable that.  This idea is a bit unusual to me, since AVRs don't have a clock for the output pins, but maybe in an ARM you need one so DMA works or something.  Figure 12 contains a rather elaborate map of how the clocks work, but the important bit is on the right: HCLK goes to the AHB bus (which I saw earlier and dismissed!)  This is fed through a prescaler from SYSCLK.  Section 5.3.8 discusses the AHB peripheral clock enable register (RCC_AHBENR) which has a "GPIOB EN" bit at bit 1.  RCC is at 0x40023800, AHBENR is at offset 1C, so this register is at 0x4002381C.

So this gets the LED to light:

    
      *((uint32_t*) 0x4002381C) = 0x00000002; /* Enable GPIO clock */
      *((uint32_t*) 0x40020400) = 0x00005000; /* Output mode */
      *((uint32_t*) 0x40020408) = 0x00005000; /* 2MHz clock speed */
      *((uint32_t*) 0x40020418) = 0x00000080; /* LED on */


That's pretty ugly and you wouldn't want to write too much code like that, so I'll look at libraries that contain these numbers instead.
