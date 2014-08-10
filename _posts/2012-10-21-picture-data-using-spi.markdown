---
author: sourcegate
comments: true
date: 2012-10-21 08:54:02+00:00
layout: post
slug: picture-data-using-spi
title: Picture data using SPI
wordpress_id: 268
categories:
- STM32L Discovery
tags:
- discovery
- dma
- picture
- signal
- spi
- stm
- stm32
- stm32l
- stm32l1xx
- video
---

I plan to use SPI to send the picture data for my video generator.

First I need to work out what speed to run the port at.  Each line goes for 52 μs, or 1664 cycles.  I could divide this by 4 for 416 pixels per line or 8 for 208 per line.  This sets the baud rate, so I shouldn't need to divide this by 8 again to get a bytes per second speed.  It looks (from the clock registers) like SPI1 is connected to the APB2 clock, and SPI2 is connected to APB1.  I'm already running APB1 at the system clock (32MHz), so I'd like to use that if I can.  The speed is set in the CR1 register, by the BR bits, which supports dividing by 4 or 8.  I might as well use SPI2.  [The datasheet](http://www.st.com/internet/com/TECHNICAL_RESOURCES/TECHNICAL_LITERATURE/DATASHEET/CD00277537.pdf) says that SPI2_MOSI can only be on pin B15.  I won't need the clock output, so I won't configure a pin for that.

The CR1 register contains a setting for 8 or 16-bit operation.  This affects the size of the data being written.  Since I plan to use DMA I'll leave it at 8 bits.

It turns out there are very few settings to get SPI working.  I had to stuff around a lot before I got it working though - eventually I copied the ChibiOS code, and set the SPI_CR1_CPOL, SPI_CR1_SSM, SPI_CR1_SSI and SPI_CR2_SSOE flags even though I wouldn't have thought I need them, and it suddenly worked!

This was enough to get SPI working:

    
      rccEnableAPB1(RCC_APB1ENR_SPI2EN, 0); // Enable SPI2 clock, run at SYSCLK
      palSetPadMode(GPIOB, 15, PAL_MODE_ALTERNATE(5) |
                               PAL_STM32_OSPEED_HIGHEST);           /* MOSI.    */
      SPI2->CR1 = //SPI_CR1_BR_0 // divide clock by 4
              SPI_CR1_CPOL | SPI_CR1_SSM | SPI_CR1_SSI |
              SPI_CR1_BR // divide clock by 256
              | SPI_CR1_MSTR;  // master mode
      SPI2->CR2 = SPI_CR2_SSOE;
      SPI2->CR1 |= SPI_CR1_SPE; // Enable SPI


To send data, write bytes to `SPI2->DR`.  The output appears on PB15.  I think in the future I'll try using [`palSetPadMode`](http://chibios.sourceforge.net/docs/hal_stm32l1xx_rm/group___p_a_l.html#gab6377829df3700e742044a2e669c7db7) for configuring the pins, since it's better than the 8 lines of code I've been using previously to do this.  The above code divides the clock by 256 so I could see the output on my DSO Nano, but I'll change this to 4 later.

The next step will be using DMA to write the data to SPI instead.
