---
author: sourcegate
comments: true
date: 2012-09-27 12:05:17+00:00
layout: post
slug: using-sts-libraries-with-the-stm32l-discovery
title: Using ST's libraries with the STM32L Discovery
wordpress_id: 219
categories:
- STM32L Discovery
tags:
- library
- peripheral
- spl
- standard peripheral library
- stm32
- stm32l
---

Now that I've got the LED to light by [accessing the registers directly](http://sourcegate.wordpress.com/2012/09/24/blinky-on-the-stm32l-discovery/), I'll try again this time using ST's libraries.  ST calls this the "standard peripheral library", and can be downloaded from the [CPU page](http://www.st.com/internet/mcu/product/248820.jsp#FIRMWARE).

Their license isn't the nicest, but it should be fine for any development for this board.  It essentially says that it can only be used for software designed for this chip.  This seems pretty stupid to me, what else is it going to be used for?  Maybe ST's law department is like the guy who changes speed limits on roads; making random changes to keep their jobs. (Rant ends here.)

Unzip this somewhere.  The more interesting stuff looks like it's in the directory `STM32L1xx_StdPeriph_Lib_V1.1.1/Libraries/STM32L1xx_StdPeriph_Driver/src/`. Let's build something in here:

    
    $ <strong>arm-none-eabi-gcc -fno-common -O0 -g -mcpu=cortex-m0 -mthumb -c stm32l1xx_gpio.c</strong>
    stm32l1xx_gpio.c:76:28: fatal error: stm32l1xx_gpio.h: No such file or directory
    compilation terminated.


Let's tell the compiler where the headers are:

    
    $ <strong>arm-none-eabi-gcc -fno-common -O0 -g -mcpu=cortex-m0 -mthumb -c -I../inc stm32l1xx_gpio.c</strong> 
    In file included from stm32l1xx_gpio.c:76:0:
    ../inc/stm32l1xx_gpio.h:38:23: fatal error: stm32l1xx.h: No such file or directory
    compilation terminated.


Still no good...

    
    $ <strong>arm-none-eabi-gcc -fno-common -O0 -g -mcpu=cortex-m0 -mthumb -c -I../inc -I../../CMSIS/Device/ST/STM32L1xx/Include/ stm32l1xx_gpio.c</strong>
    In file included from ../inc/stm32l1xx_gpio.h:38:0,
                     from stm32l1xx_gpio.c:76:
    ../../CMSIS/Device/ST/STM32L1xx/Include/stm32l1xx.h:266:22: fatal error: core_cm3.h: No such file or directory
    compilation terminated.


and another one:

    
    $ <strong>arm-none-eabi-gcc -fno-common -O0 -g -mcpu=cortex-m0 -mthumb -c -I../inc -I../../CMSIS/Device/ST/STM32L1xx/Include/ -I../../CMSIS/Include stm32l1xx_gpio.c
    </strong>


At last!

This can be added to a Makefile, to compile all of the libraries.

Previously I used this ghastly code to turn on the LED:

    
      *((uint32_t*) 0x4002381C) = 0x00000002; /* Enable GPIO clock */
      *((uint32_t*) 0x40020400) = 0x00005000; /* Output mode */
      *((uint32_t*) 0x40020408) = 0x00005000; /* 2MHz clock speed */
      *((uint32_t*) 0x40020418) = 0x00000080; /* LED on */


Using the ST code, this now looks like:

    
        RCC->AHBENR |=  (1UL <<  1);        /* Enable GPIOB clock         */     GPIOB->MODER   |=   (0x00005000);   /* General purpose output mode*/
        GPIOB->OSPEEDR |=   (0x00005000);   /* 2 MHz Low speed            */
        GPIOB->BSRRL = 1L << 7;             /* LED on */


This include needs to be added at the top:

    
    #include <stm32l1xx.h>


This needs to be compiled with the headers from the SPL, and linked with the compiled SPL.

I've [linked my C code so far and makefiles to build the SPL and the final binary](https://docs.google.com/open?id=0B4_b067bayWtcE1xNUVLaUJyUnM).

[Next I'll try controlling the LED using ChibiOS](http://sourcegate.wordpress.com/2012/10/01/chibios-on-the-stm32l-discovery/).


