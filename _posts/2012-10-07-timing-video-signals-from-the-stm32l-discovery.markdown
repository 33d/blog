---
author: sourcegate
comments: true
date: 2012-10-07 01:41:38+00:00
layout: post
slug: timing-video-signals-from-the-stm32l-discovery
title: Timing video signals from the STM32L Discovery
wordpress_id: 227
categories:
- STM32L Discovery
tags:
- discovery
- exception
- interrupt
- stm32
- stm32l
- systick
- timer
- video
- video signals
---

In [my last post](http://sourcegate.wordpress.com/2012/10/01/chibios-on-the-stm32l-discovery/), I suggested using [ChibiOS](http://www.chibios.org/) to produce video signals from the [STM32L Discovery](http://www.st.com/internet/evalboard/product/250990.jsp).

The configuration for ChibiOS is held in `chconf.h`.  An interesting section is this one:

    
    /**
     * @brief   System tick frequency.
     * @details Frequency of the system timer that drives the system ticks. This
     *          setting also defines the system tick time unit.
     */
    #if !defined(CH_FREQUENCY) || defined(__DOXYGEN__)
    #define CH_FREQUENCY                    1000
    #endif


It looks like the operating system wakes up periodically, checking whether there's anything to do.  It also means that to produce video signals, this number may not be accurate enough.

So what is this number used for?  The only interesting reference I can find is in `os/hal/platforms/STM32L1xx/hal_lld.c`:

    
    SysTick->LOAD = STM32_HCLK / CH_FREQUENCY - 1;


and of course that's where the system ticks are initialized.  `STM32_HCLK` looks interesting, there's plenty of references to this in `os/hal/platforms/STM32F4xx/hal_lld.h`:

    
    /**
    * @brief   AHB frequency.
    */
    #if (STM32_HPRE == STM32_HPRE_DIV1) || defined(__DOXYGEN__)
    #define STM32_HCLK                  (STM32_SYSCLK / 1)
    #elif STM32_HPRE == STM32_HPRE_DIV2
    #define STM32_HCLK                  (STM32_SYSCLK / 2)
    ...


I remember [seeing the text AHB before](http://sourcegate.wordpress.com/2012/09/24/blinky-on-the-stm32l-discovery/), this is the bus that connects the CPU to the GPIO ports, and other peripherals.  This code suggests that it's related to the CPU clock via a prescaler, which the clock tree in the [reference manual](http://www.st.com/internet/com/TECHNICAL_RESOURCES/TECHNICAL_LITERATURE/REFERENCE_MANUAL/CD00240193.pdf) confirms.  This led me here:

    
    /**
    * @brief   System clock source.
    */
    #if STM32_NO_INIT || defined(__DOXYGEN__)
    #define STM32_SYSCLK                STM32_HSICLK
    #elif (STM32_SW == STM32_SW_HSI)
    #define STM32_SYSCLK                STM32_HSICLK
    ...


so STM32_SYSCLK is the system clock, and we can choose the source for this.  "HSI" would be the High Speed Internal clock, which is fixed at 16MHz.  It's possible to use the PLL to run the CPU at 32MHz too.

So working backwards, with the default setting, STM32_HCLK is 16MHz, and ChibiOS' default tick is 1000 cycles, which is 62.5μs.  For PAL, the sync pulse length is 4.7µs, and the front porch is much shorter than that, so the ChibiOS timer is far too inaccurate for that.  I could change the system tick to 100, but there's the risk that ChibiOS won't have enough time to do its scheduling after it wakes up, and that number still isn't accurate enough.

While I'm rummaging around the ChibiOS code, what does it use to trigger its scheduler?  It never seems to be read anywhere, but looking at SysTick_Type in os/ports/common/ARMCMx/CMSIS/include/core_cm3.h it looks like some part of the address space, specifically at address 0xE000E010.  [The datasheet](http://www.st.com/internet/com/TECHNICAL_RESOURCES/TECHNICAL_LITERATURE/DATASHEET/CD00277537.pdf) says this is part of the "Cortex-M3 Internal Peripherals", but that's all it says.  [The CPU manual](http://infocenter.arm.com/help/topic/com.arm.doc.ddi0337g/DDI0337G_cortex_m3_r2p0_trm.pdf) might be more helpful here, and it says this is part of the "System Control Space".  Section 3.1.1 says this address contains the "SysTick Control and Status Register", and the following registers correspond to the SysTick variable in ChibiOS.

So what is the SysTick for?  Section 5.2 suggests that an interrupt can be triggered on the SysTick firing, which might be what ChibiOS uses for its scheduling.  (Wordpress didn't save my draft from here, so I might be missing a few steps.)  So where is the handler for this?

Earler [I found that each program starts with an interrupt table](http://sourcegate.wordpress.com/2012/09/18/getting-started-with-an-stm32l-discovery-with-linux-and-gcc/).  The example there has 4 entries, but it can be longer.  The linker script (`os/ports/GCC/ARMCMx/STM32L1xx/ld/STM32L152xB.ld`) contains a section called "vectors", which is defined in `os/ports/GCC/ARMCMx/STM32L1xx/vectors.c`.  The SysTick handler is called SysTickVector, which looks like this (from `os/ports/GCC/ARMCMx/chcore_v7m.c`; I don't know whether this is an arm6 or an arm7):

    
    CH_IRQ_HANDLER(SysTickVector) {
    
      CH_IRQ_PROLOGUE();
    
      chSysLockFromIsr();
      chSysTimerHandlerI();
      chSysUnlockFromIsr();
    
      CH_IRQ_EPILOGUE();
    }


So this is how the SysTick facility works.  Now this can't be used for generating the video signals, since it's not accurate enough - I'd need to use another timer for that.  The timer interrupt would need to be of higher priority than SysTick, otherwise the CPU might be doing something else which would make the image jump around.  The ChibiOS docs suggest that interrupt handlers are [like a special thread with higher priority than everything else](http://www.chibios.org/dokuwiki/doku.php?id=chibios:kb:priority#what_about_interrupts), which is what I want.

All of this suggests that ARMs are a lot trickier than 8-bit CPUs, because of all of the available features.  I don't think I've even found all of the relevant documentation - with the AVR, one document contains everything you need to know.

Next I'll [look at how the timers work](http://sourcegate.wordpress.com/2012/10/10/more-timing-video-signals-on-the-stm32l-discovery/).
