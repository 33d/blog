---
author: sourcegate
comments: true
date: 2012-03-11 00:57:41+00:00
layout: post
slug: a-very-cheap-avr-dev-board
title: A very cheap AVR dev board
wordpress_id: 133
tags:
- avr
- board
- dev
- programmer
- usb
- v-usb
---

I bought [one of these boards](http://item.taobao.com/item.htm?spm=1103qnJ8.1-482lN.b-24JqD0&id=10052532429) for about $4 on eBay.  It's based on the [USB ASP](http://www.fischl.de/usbasp/) - a cheap AVR programming board.  I remember seeing [a post on Hack A Day](http://hackaday.com/2011/08/26/dev-board-from-an-avr-programmer/) a while ago about using them as a general purpose dev board, with 5 lines broken out to the black pin header.  By removing a link on the bottom of the board, you can get 3.3V from a regulator.

![](http://img01.taobaocdn.com/imgextra/i1/47424247/T2rpXoXl0MXXXXXXXX_!!47424247.jpg_b.jpg)

First I wanted to see what the stock firmware was.  I shorted J2, which connects the reset pin to the header pins, allowing the chip to be programmed.  I dumped the data, and saw this:

    
    00000000  00 00 01 01 02 02 03 03  04 04 05 05 06 06 07 07  |................|
    00000010  08 08 09 09 0a 0a 0b 0b  0c 0c 0d 0d 0e 0e 0f 0f  |................|
    00000020  10 10 11 11 12 12 13 13  14 14 15 15 16 16 17 17  |................|
    00000030  18 18 19 19 1a 1a 1b 1b  1c 1c 1d 1d 1e 1e 1f 1f  |................|


It sounds like that's what you get when the chip is locked.  I used avrdude to erase the chip, and I was able to program it again using the original firmware from the USB ASP site.  I had a quick look at the fuse bits, and they seem to be correct.  I haven't actually tried this firmware, so no doubt some of the pins are in different places.

The pinout appears to be the same as the original.  The pins themselves are different because of the chip packaging:

<table >
<tbody >
<tr >

<td >D+
</td>

<td >13, 32
</td>

<td >PB1, PD2 (INT0)
</td>
</tr>
<tr >

<td >D-
</td>

<td >12
</td>

<td >PB0
</td>
</tr>
<tr >

<td >MOSI
</td>

<td >15
</td>

<td >PB3 (MOSI)
</td>
</tr>
<tr >

<td >RST
</td>

<td >14
</td>

<td >PB2
</td>
</tr>
<tr >

<td >J2
</td>

<td >29
</td>

<td >RESET
</td>
</tr>
<tr >

<td >SCK
</td>

<td >17
</td>

<td >PB5 (SCK)
</td>
</tr>
<tr >

<td >MISO
</td>

<td >16
</td>

<td >PB4 (MISO)
</td>
</tr>
</tbody>
</table>

The price is amazing since the [AVR stick](http://www.sparkfun.com/products/9147) costs about $10, and contains fewer parts.  Perhaps I should retry [my V-USB experiment](http://sourcegate.wordpress.com/2011/12/17/run-a-v-usb-demo-on-an-avr-stick-easylogger/) with it.

A while ago I found [some V-USB tutorials](http://codeandlife.com/tags/v-usb/), but I haven't gone through them yet.
