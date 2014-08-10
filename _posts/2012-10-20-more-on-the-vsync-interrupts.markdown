---
author: sourcegate
comments: true
date: 2012-10-20 00:39:25+00:00
layout: post
slug: more-on-the-vsync-interrupts
title: More on the vsync interrupts
wordpress_id: 260
categories:
- STM32L Discovery
tags:
- arm
- chibios
- interrupt
- pwm
- stm
- stm32
- stm32l
- timer
---

I had a thought after [my previous disheartening attempt to get the vsync working](http://sourcegate.wordpress.com/2012/10/18/starting-on-the-vsync-interrupts/): since they might have stuffed up timer 11 in ChibiOS, I might change to timer 4.  One massive advantage is that timers 2, 3 and 4 have 4 compare registers, instead of one!  This means I can use one to turn off the vsync pulse, and one to trigger the DMA interrupt and adjust the sync timings on the next line.  Changing everything to use TIM4 was fairly straightforward, the only tricky part being changing the single compare register to use compare register 4, and enabling APB1 instead of APB2 since that's where timer 4 is.  (I originally used register 1, but that is connected to PORTB6 which is attached to the blue LED.)

There was one catch though when compiling:

    
    $ <strong>make</strong>
    Compiling main.c
    Linking build/ch.elf
    build/obj/main.o: In function `VectorB8':
    /home/damien/projects/stm32/video/main.c:8: multiple definition of `VectorB8'
    build/obj/pwm_lld.o:/opt/ChibiOS_2.4.2/os/hal/platforms/STM32/pwm_lld.c:221: first defined here


Looking in pwm_lld.c suggests that I need to unset `STM32_PWM_USE_TIM4`.  I notice that one example has another configuration file: `/demos/ARMCM3-STM32L152-DISCOVERY/mcuconf.h`, which declares this symbol.  I copied this file to my project directory, hoping the makefile would use it in preference.  Now there were no timers available for ChibiOS, its PWM module made the compiler complain because it had no timers to use, so I had to set `HAL_USE_PWM` to `FALSE` in `halconf.h`.

The good news: my interrupt is being called! I connected the debugger and used [the "p" command](http://sourceware.org/gdb/current/onlinedocs/gdb/Variables.html) to show the contents of "line".  The bad news: my PB7 light isn't blinking, which means the ChibiOS main thread isn't working.  Maybe the interrupt is using all of the CPU?  It shouldn't, since I thought each line took about 1000 cycles to run, and the interrupt shouldn't be using more than about 50.

I remember seeing somewhere that ARMs don't reset their interrupt flags automatically, like AVRs do.  If this is the case, my interrupt will return, and the NVIC (the "nested vectored interrupt controller", apparently) will see the flag is still set, and call the interrupt again.  The interrupt handler in ChibiOS' `pal_lld.c` contains this line, which would clear this flag:

    
    STM32_TIM1->SR = ~TIM_SR_UIF;


In my case, this would be:

    
    TIM4->SR &= ~TIM_SR_UIF;


and my light blinks again, so that seems to have worked!  I checked with gdb that the "line" variable is still incrementing.

I'll try setting the PWM duration registers during the interrupt, so my interrupt handler looks like this:

    
        if (line & 1) {
            TIM4->ARR = STM32_SYSCLK * 0.0001;   // horizontal line duration
            TIM4->CCR4 = STM32_SYSCLK * 0.00009; // hsync pulse duration
        } else {
            TIM4->ARR = STM32_SYSCLK * 0.000064;   // horizontal line duration
            TIM4->CCR4 = STM32_SYSCLK * 0.0000047; // hsync pulse duration
        }


That seems to have worked fine.  That's about everything I need to generate the vsync signals.  I've done something slightly wrong though - I'd be better off using one of the compare registers to trigger the interrupt instead.  In the interrupt handler, I'd initiate a DMA transfer for the current line, then set the timing registers for the next line.

Now my code looks like this (maybe I should start putting it on Github):

    
    #include "ch.h"
    #include "hal.h"
    #include "stm32l1xx.h"
    
    volatile int line;
    
    CH_IRQ_HANDLER(TIM4_IRQHandler) {
        TIM4->SR &= ~TIM_SR_UIF;
        ++line;
    
        if (line & 1) {
            TIM4->ARR = STM32_SYSCLK * 0.0001;   // horizontal line duration
            TIM4->CCR4 = STM32_SYSCLK * 0.00009; // hsync pulse duration
        } else {
            TIM4->ARR = STM32_SYSCLK * 0.000064;   // horizontal line duration
            TIM4->CCR4 = STM32_SYSCLK * 0.0000047; // hsync pulse duration
        }
    }
    
    int main(void) {
      halInit();
      chSysInit();
    
      rccEnableAPB1(RCC_APB1ENR_TIM4EN, 0); // Enable TIM4 clock, run at SYSCLK
    
      nvicEnableVector(TIM4_IRQn, CORTEX_PRIORITY_MASK(7));
    
      // TIM11 outputs on PB6
      GPIOB->OTYPER &= ~GPIO_OTYPER_OT_9;        // Push-pull output
      GPIOB->OSPEEDR |= GPIO_OSPEEDER_OSPEEDR9; // 40MHz
      GPIOB->PUPDR &= ~GPIO_PUPDR_PUPDR9;
      GPIOB->PUPDR |= GPIO_PUPDR_PUPDR9_0;      // Pull-up
      GPIOB->MODER &= ~GPIO_MODER_MODER9;
      GPIOB->MODER |= GPIO_MODER_MODER9_1; // alternate function on pin B9
    
      // Reassign port B9
      GPIOB->AFRH &= ~GPIO_AFRH_AFRH9;
      GPIOB->AFRH |= 0x2 << 4; // ChibiOS doesn't seem to have constants for these   TIM4->CR1 |= TIM_CR1_ARPE; // buffer ARR, needed for PWM (?)
      TIM4->CCMR2 &= ~(TIM_CCMR2_CC4S); // configure output pin
      TIM4->CCMR2 =
              TIM_CCMR2_OC4M_2 | TIM_CCMR2_OC4M_1 /*| TIM_CCMR1_OC1M_0*/  // output high on compare match
              | TIM_CCMR2_OC4PE; // preload enable
      TIM4->CCER = TIM_CCER_CC4P // active low output
               | TIM_CCER_CC4E; // enable output
      TIM4->DIER = TIM_DIER_UIE; // enable interrupt on "update" (ie. overflow)
      TIM4->ARR = STM32_SYSCLK * 0.000064;   // horizontal line duration
      TIM4->CCR4 = STM32_SYSCLK * 0.0000047; // hsync pulse duration
    
      TIM4->CR1 |= TIM_CR1_CEN; // enable the counter
    
      palSetPadMode(GPIOB, 7, PAL_MODE_OUTPUT_PUSHPULL);
      while (1) {
        palSetPad(GPIOB, 7);
        chThdSleepMilliseconds(500);
        palClearPad(GPIOB, 7);
        chThdSleepMilliseconds(500);
      }
    }


Next I'll try using DMA, which I've never used before.  With any luck I'll be able to use ChibiOS to do this.
