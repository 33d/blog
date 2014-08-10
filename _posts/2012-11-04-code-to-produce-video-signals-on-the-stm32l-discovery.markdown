---
author: sourcegate
comments: true
date: 2012-11-04 05:50:58+00:00
layout: post
slug: code-to-produce-video-signals-on-the-stm32l-discovery
title: Code to produce video signals on the STM32L Discovery
wordpress_id: 302
categories:
- STM32L Discovery
tags:
- composite
- discovery
- pal
- signal
- stm
- stm32
- stm32l
- stm32l1xx
- video.generation
---

I've finally coded the program that produces a video signal.  There weren't too many surprises.

One issue I had was that there was that occasionally a line would be drawn slightly to the right.  I changed the interrupt priority from 7 to 0, and disabled ChibiOS' thread preemption. Probably only changing the interrupt will do, but I had no trouble after that.

A bigger problem is that any vertical line wriggles around on the screen a lot.  I don't think there's anything in my code that might cause this.  I came across a question on the STM site, which [suggests that an instruction must complete before an interrupt will be triggered](https://my.st.com/public/FAQ/Lists/faqlist/DispForm.aspx?ID=143&level=1&objectid=141&type=product&Source=/public/FAQ/Tags.aspx?tags=interrupt).  If the CPU happens to be running a long instruction, the line produced by the following interrupt will be shifted over slightly.  The [Arduino TV-Out library](http://code.google.com/p/arduino-tvout/) doesn't have this problem, even though the AVRs instructions can take different amounts of time.  I'm not sure what I can do about this - the timer should still be correct, so maybe I'd need a busy-wait loop while waiting for the timer to hit a particular value.  It looks like the TV-Out library does this.  It might need some assembler, which I don't plan to learn right now (but maybe check [this ST forum post](https://my.st.com/public/STe2ecommunities/mcu/Lists/cortex_mx_stm32/Flat.aspx?RootFolder=%2Fpublic%2FSTe2ecommunities%2Fmcu%2FLists%2Fcortex_mx_stm32%2Fcompensating%20latencies%20on%20STM32F4%20interrupts&FolderCTID=0x01200200770978C69A1141439FE559EB459D7580009C4E14902C3CDE46A77F0FFD06506F5B&currentviews=150)).  But the [author of the RBox suggests it's because of the wait states](http://rossum.posterous.com/20131601).  I don't know why there would be anything non-deterministic with wait states, unless there was caching involved, which I don't think the STM32 has.  I suspect it's ChibiOS running stuff during the timing interrupt, which would cause jitter.


[![](http://sourcegate.files.wordpress.com/2012/11/stm32-video-squiggly-lines.jpg)](http://sourcegate.files.wordpress.com/2012/11/stm32-video-squiggly-lines.jpg)


I don't plan to do any more work on this program, since it's served its task of teaching me about ARM processors.  It has potential to show data its capturing or interacting with an operator.  There's plenty of memory for a framebuffer for its its 400×288 display, It should be fairly easy to port the TVOut library to it, to add graphics and text rendering capabilities.  The advantage of the ARM chip is that because it uses DMA to write to the screen, the CPU is doing almost nothing while it's displaying an image.  An AVR needs to work hard while a line is being drawn.

I've seen one project where [an ARM chip produced colour signals](http://rossum.posterous.com/20131601).  The CPU didn't have DMA though, but was faster than the STM32L.  The [Freescale Freedom board](http://www.freescale.com/webapp/sps/site/prod_summary.jsp?code=FRDM-KL25Z) looks like a good target (although ChibiOS doesn't support it yet).  I was thinking about the way that 2D polygons are drawn, and I think it might be possible to render a number of 3D polygons with occlusion as each line is being drawn.  The unusual part of this rendering is that instead of the frame rate slowing when the CPU was busy, the vertical resolution would decrease instead as the previous line keeps getting rendered as a new line is being drawn.

Generating video signals like is is nifty, but maybe a bit pointless since there are chips around with composite output anyway.  The [OLinuXino iMX233](https://www.olimex.com/Products/OLinuXino/iMX233) would be ideal for this, as [its CPU](http://www.freescale.com/webapp/sps/site/prod_summary.jsp?code=i.MX233) has [a complete reference manual](http://cache.freescale.com/files/dsp/doc/ref_manual/IMX23RM.pdf) available.  It's designed for running Linux, but some low level programming like I did here would provide an "instant-on" function.  The same could be done with the [Raspberry Pi](http://www.raspberrypi.org/wp-content/uploads/2012/02/BCM2835-ARM-Peripherals.pdf), but since there's no user manual available, you'd need to rely on [its limited documentation](http://www.raspberrypi.org/wp-content/uploads/2012/02/BCM2835-ARM-Peripherals.pdf) and Linux drivers.  I like the idea of porting the [RTEMS](http://www.rtems.org/) operating system to the OLinuXino, since that OS provides a POSIX API and BSD networking, so porting other applications would be easier.

[Here's a video of my results](http://tinypic.com/r/j6j51k/6).  My code is here: [https://github.com/33d/stm32-video](https://github.com/33d/stm32-video)
