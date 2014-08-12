---
author: sourcegate
comments: true
date: 2010-04-15 12:37:00+00:00
layout: post
slug: a-10mhz-usb-oscilloscope-for-under-50
title: A 10MHz USB oscilloscope for under $50?
wordpress_id: 47
---

Oscilloscopes are expensive.  USB ones are too.  I reckon one can be built for under $50.



Here's the idea:



{% wpimage block usbosc.png %}  
(The "WR" on the FIFO are the two write pins, not a read and a write pin.)



A sawtooth wave is fed into a comparator whose output goes high when the input signal is above the wave.  This output causes the FIFO to read the state from its input pins.  This input is fed by an 8-bit counter, whose value represents the input signal (counters and op-amps are much cheaper than ADCs).  The counter also supplies the 12MHz clock to the USB FIFO, as well as pulling down the "ramp generator" (which is one of the op-amps configured as an integrator).



Here are some of the parts:



<table >
<tr >PartExample partCost
<tr >
<td >Comparator  
Ramp generator
<td >LMV339 quad op-amp
<td >$2.50
<tr >
<td >8-bit counter
<td >74F269 100MHz counter
<td >$2.00
<tr >
<td >USB FIFO
<td >FT2232H dual USB 2.0 FIFO
<td >$20.00
<tr >
<td colspan="2" >Parts for FT2232H (EEPROM, regulator)  
PCB  
Other components
<td >$25.00
</table>

The high frequencies involved might be a bit beyond me.  The parts above should be able to handle it, but no doubt there's plenty of issues involving AC signals that I have no idea about.



One problem might be the input impedance - real scopes are about 1MΩ, but if necessary we can add a voltage follower on each input.



It probably won't be the most accurate device in the world, but as long as you just want to see the signal and don't need to know it's 3.17863 volts, it should be fine.  And it's a _lot_ cheaper than an off-the-shelf one.
