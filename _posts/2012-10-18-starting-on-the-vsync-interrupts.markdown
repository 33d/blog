---
author: sourcegate
comments: true
date: 2012-10-18 10:11:27+00:00
layout: post
slug: starting-on-the-vsync-interrupts
title: Starting on the vsync interrupts
wordpress_id: 254
categories:
- STM32L Discovery
tags:
- chibios
- interrupts
- irq
- nvic
- pwm
- stm
- stm32
- stm32l
- timer
---

Now it's time to adjust the sync signals to get vsync working, so I need an interrupt when the signal goes low so I can adjust the sync pulse on the next cycle.  I have no idea how to start the interrupts.

I did a search in the ChibiOS code for the term "vect", and found a bunch of them in `hal/platforms/STM32L1xx/hal_lld.h`, of which TIM11_IRQHandler looks the most appropriate.  But there seems to be only one vector all possible events, like an overflow or a compare match.

It [looks like "fast" interrupt handlers](http://www.chibios.org/dokuwiki/doku.php?id=chibios:howtos:interrupts) look like this:

    
    volatile int line;
    CH_IRQ_HANDLER(TIM11_IRQHandler) {
      ++line;
    }


It compiles at least... but did it register as an interrupt handler?  I tried the trick with AVRs that shows disassembled code:

    
    arm-none-eabi-objdump -S -h build/ch.elf


It shows that the first section starts at address 0x08000100... just after the vector table, which should appear at the start! Right at the top though, there's a "startup" section at the correct address. After stuffing around with various objdump options, this showed me the vector table:

    
    arm-none-eabi-objdump -h -s --special-syms build/ch.elf


Table 34 of the reference manual lists all of the interrupts, and TIM11 is at offset 0xAC. Objdump doesn't show anything promising in this location!  But there's something strange in `hal_lld.h`:

    
    #define TIM9_IRQHandler         VectorA0    /**< TIM9.                      */
    #define TIM10_IRQHandler        VectorA4    /**< TIM10.                     */
    #define TIM11_IRQHandler        VectorA8    /**< TIM11.                     */
    #define LCD_IRQHandler          VectorAC    /**< LCD.                       */


The datasheet though says that the LCD is vector A0, TIM9 is A4, 10 is A8 and 11 is AC.  I guess the way to find out is to try both and see what happens.

First the timer needs to be configured to use those interrupts.

    
      TIM11->DIER = TIM_DIER_UIE; // enable interrupt on "update" (ie. overflow)


So does this do anything? I used the debugger to find out:

    
    $ <strong>arm-none-eabi-gdb build/ch.elf </strong>
    ....
    Reading symbols from /home/damien/projects/stm32/video/build/ch.elf...done.
    (gdb) <strong>p lineA8</strong>
    $1 = 0
    (gdb) <strong>p lineAC</strong>
    $2 = 0
    (gdb) <strong>cont</strong>
    ^C
    Program received signal SIGINT, Interrupt.
    0x08000598 in _idle_thread (p=)
        at /opt/ChibiOS_2.4.2/os/kernel/src/chsys.c:62
    62	  chRegSetThreadName("idle");
    (gdb) <strong>p lineAC</strong>
    $3 = 0
    (gdb) <strong>p lineA8</strong>
    $4 = 0
    (gdb)


So it's doing nothing!  Why not? I looked through the ChibiOS sources where the timers are configured, and [found a call to nvicEnableVector](http://chibios.sourceforge.net/docs/hal_stm32l1xx_rm/gpt__lld_8c_source.html#l00296), which looks promising.  It needs a "priority" parameter though, so what should that be?  [gpt_lld.h](http://chibios.sourceforge.net/docs/hal_stm32l1xx_rm/gpt__lld_8h.html) lists some priorities.  ChibiOS always sends the priorities through a macro called [CORTEX_PRIORITY_MASK](http://chibios.sourceforge.net/docs/kernel_cmx_gcc_rm/group___a_r_m_c_mx___c_o_r_e.html#gabf50672d926743f012521dad719f3a0f), but that seems to move the number to the correct place in a register.  The CPU manual (section 5.3) says that lower numbers have higher priority, and this needs to be very high, so I'll choose 2.

    
      nvicEnableVector(TIM11_IRQn, CORTEX_PRIORITY_MASK(2));


It doesn't like that much - the light doesn't blink, so it looks like the chip crashed!  I'm starting to get a bit annoyed with my slow progress; maybe I'll try to rewrite my code using ChibiOS as much as I can.  While this chip is powerful, its also very complicated, which makes me think it's not that practical to program it directly.  [I soldiered on anyway](http://sourcegate.wordpress.com/2012/10/20/more-on-the-vsync-interrupts/)...
