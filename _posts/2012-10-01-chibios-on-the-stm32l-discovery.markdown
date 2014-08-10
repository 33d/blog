---
author: sourcegate
comments: true
date: 2012-10-01 06:34:17+00:00
layout: post
slug: chibios-on-the-stm32l-discovery
title: ChibiOS on the STM32L Discovery
wordpress_id: 223
categories:
- STM32L Discovery
tags:
- blinky
- chibios
- discovery
- stm32
- stm32l
- tutorial
---

I [previously used the libraries provided by ST to do something on the STM32L Discovery](http://sourcegate.wordpress.com/2012/09/27/using-sts-libraries-with-the-stm32l-discovery/), now I've made a short demo of using [ChibiOS](http://www.chibios.org/).  Hopefully by using an OS to write code, I don't have to mess around with timers myself to process events periodically, which I always found time consuming on the AVR.  Here's what I did:



	
  1. [Download](http://www.chibios.org/dokuwiki/doku.php?id=chibios:download) and extract ChibiOS.  I used version 2.4.2.  I extracted the archive to /opt.

	
  2. Make a copy of this directory: `ChibiOS_2.4.2/demos/ARMCM3-STM32L152-DISCOVERY`.  This is what I edited for my demo.

	
  3. Delete the `keil` and `iar` directories; they're for different IDEs and we don't need them.

	
  4. Replace main.c with this:

    
    #include <ch.h>
    #include <hal.h>
    
    int main(void) {
      halInit();
      chSysInit();
    
      palSetPadMode(GPIOB, 7, PAL_MODE_OUTPUT_PUSHPULL);
      while (1) {
        palSetPad(GPIOB, 7);
        chThdSleepMilliseconds(500);
        palClearPad(GPIOB, 7);
        chThdSleepMilliseconds(500);
      }
    }


I adapted this from [another blog](http://importgeek.wordpress.com/2012/09/22/stm32f4discovery-gpio-programming-using-chibios-rtos/).

	
  5. In the `Makefile`, change the `CHIBIOS` variable to point to where you extracted ChibiOS.

	
  6. Run `make`, then upload the binary to the Discovery.  The correct compiler should be invoked if the Linaro bare-metal compiler is on your PATH, like I did for [my first coding attempt](http://sourcegate.wordpress.com/2012/09/18/getting-started-with-an-stm32l-discovery-with-linux-and-gcc/).


It's as simple as that - a light that flashes once a second!

So what does this code do?

`halInit()` and `chSysInit()` seem to go at the start of any ChibiOS program. The HAL is what tries to abstract out the peripherals on each chip. The [document about the architecture](http://www.chibios.org/dokuwiki/doku.php?id=chibios:documents:architecture) explains this some more.

`pal` means "Port Abstraction Layer", and functions relating to this start with `pal`. Functions starting with `ch` relate to the kernel. There are two reference manuals in ChibiOS: [one for the kernel](http://chibios.sourceforge.net/docs/kernel_cmx_gcc_rm/index.html) (the cross platform stuff, although there's a separate manual for each compiler), and [one for the peripherals](http://chibios.sourceforge.net/docs/hal_stm32l1xx_rm/index.html) (the more chip-specific stuff).

It looks like once you call `chSysInit`, that function continues to run as a thread.  I would hope because we're calling a sleep function, the CPU is actually sleeping and not busy-waiting.

I'm surprised how easy this was to get running.  The Makefile is very good - you don't need to keep a copy of the entire operating system in your project directory; it will find it and compile the relevant parts.  There's no code directly accessing the hardware either, so the I/O code is no more complicated than Arduino code.  Of course I'm expecting to have to learn more about ChibiOS and the STM32L as I make more complicated things.

I'd like to use ChibiOS to write firmware to drive a television from the Discovery, so I can learn about RTOS scheduling and DMA, which I plan to use to copy the framebuffer to the output.  I imagine I'll need to learn more about how clocks work to control the speed the data is written to the TV.
