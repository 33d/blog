---
author: sourcegate
comments: true
date: 2012-10-23 20:42:32+00:00
layout: post
slug: dma-on-the-stm32l-discovery
title: DMA on the STM32L Discovery
wordpress_id: 156
categories:
- STM32L Discovery
tags:
- discovery
- dma
- generator
- signal
- spi
- stm
- stm32
- stm32l
- stm32l1xx
- video
---

There's one more part to my video generator - the picture data, which I want to transfer to the SPI port using DMA. This actually looks fairly straightforward, these are the available registers:
<table >
<tbody >
<tr >

<td >MEM2MEM
</td>

<td >I'm transferring from memory to a peripheral, so this should be off.
</td>
</tr>
<tr >

<td >PL
</td>

<td >I'll make this "very high" priority, because I want to keep the picture stable at all costs. If a program writes to the framebuffer during this DMA transfer, it will be blocked.
</td>
</tr>
<tr >

<td >MSIZE
</td>

<td >I've set the SPI port to 8 bits so I'll stick with that. I don't think it will make any difference whether it's 8 or 16.
</td>
</tr>
<tr >

<td >MINC
</td>

<td >I want the memory pointer to increment during the transfer
</td>
</tr>
<tr >

<td >PINC
</td>

<td >I guess this should be off, because to write SPI you keep sending data to the same memory location.
</td>
</tr>
<tr >

<td >CIRC
</td>

<td >I don't want the memory pointer to circle around.
</td>
</tr>
<tr >

<td >DIR
</td>

<td >Read from memory
</td>
</tr>
<tr >

<td >Interrupts
</td>

<td >I won't need any yet, but eventually I'll have to turn off the SPI port at the end of the transfer, otherwise I'll get white bars down the sides of the screen.
</td>
</tr>
</tbody>
</table>
`DMA_CNDTRx` contains how much data to transfer. There are 7 channels, and table 40 of the reference manual says `SPI2_TX` is on channel 5. This needs to be set to the number of pixels / 8, since I'll have 8 pixels in one byte.  There's a "auto-reload" setting somewhere which resets this counter value after a transfer; I think this happens in circular mode.

Table 40 also suggests I must use DMA1 for these transfers.

The peripheral address register should point to the SPI data register (`&(SPI2->DR)`), and the memory register is the start of the current line of pixels.

That's all of the available settings!  There's one more thing to do though: section 10.3.7 says this:


<blockquote>The peripheral DMA requests can be independently activated/de-activated by programming the DMA control bit in the registers of the corresponding peripheral.</blockquote>


I guess this is the `TXDMAEN` bit in the `SPI_CR2` register.

Now for some code... first I'll make some data to send:

    
    const uint8_t image[] = { 0xAA, 0x55, 0xAA, 0x55 };


Of course later on I'll have a lot more data...

Now to set the above settings:

    
      DMA1_Channel5->CCR = DMA_CCR5_PL // very high priority
              | DMA_CCR5_MINC  // memory increment mode
              | DMA_CCR5_DIR;  // read from memory, not peripheral


Section 10.3.3 has this useful bit of information:


<blockquote>The first transfer address is the one programmed in the DMA_CPARx/DMA_CMARx registers. During transfer operations, these registers keep the initially programmed value. The current transfer addresses (in the current internal peripheral/memory address register) are not accessible by software.</blockquote>


This suggests that I only need to set these at the start and shouldn't need to touch them again.

To set these:

    
      DMA1_Channel5->CMAR = (uint32_t) image;       // where to read from
      DMA1_Channel5->CPAR = (uint32_t) &(SPI2->DR); // where to write to


Time to try it out... and... nothing!  Maybe there's another clock setting for DMA, and sure enough there is:

    
      rccEnableAHB(RCC_AHBENR_DMA1EN, 0); // Enable DMA clock, run at SYSCLK


I still haven't got anything, so I tried setting the source and destination registers each time before I start a DMA transfer. It looks like now I get a single transfer, but I'm trying to get a transfer on every hsync.

I poked around with the debugger, especially at `0x40026058` which is `DMA5->CCR1` (I calculated the address from values in stm32l1xx.h), and noticed that the Enable flag is still set.  Maybe it has to be toggled each time?  Now I get a square wave instead of my data... I then tried decreasing my hsync timer, and decreasing the SPI speed, and I got a reasonable output.  I'm getting some nasty aliasing on my DSO Nano though, maybe I should have borrowed a faster scope!  I think I was triggering the DMA transfers too quickly, which produced that square wave.  Conveniently, I notice the SPI line is now low when it's idle, which is the output I want.  I'm not sure why it's gone low, but I'm not complaining.

So to sum up:

    
      rccEnableAHB(RCC_AHBENR_DMA1EN, 0); // Enable DMA clock, run at SYSCLK
      // Configure DMA
      DMA1_Channel5->CCR = DMA_CCR5_PL // very high priority
              | DMA_CCR5_MINC  // memory increment mode
              | DMA_CCR5_DIR;  // read from memory, not peripheral
      DMA1_Channel5->CMAR = (uint32_t) image;       // where to read from
      DMA1_Channel5->CPAR = (uint32_t) &(SPI2->DR); // where to write to
    ...
      SPI2->CR2 = SPI_CR2_SSOE | SPI_CR2_TXDMAEN;


then in my hsync handler:

    
        // Activate the DMA transfer
        DMA1_Channel5->CCR &= ~DMA_CCR5_EN;
        DMA1_Channel5->CNDTR = sizeof(image);
        DMA1_Channel5->CCR |= DMA_CCR5_EN;


I didn't need to reset `CMAR` and `CPAR` after all.

I think that's now demonstrated everything I need for the video signal generator! My code needs a big cleanup, and I'd like to use ChibiOS functions where I can (`palSetPadMode` instead of messing around with memory locations and data structures, etc).
