---
author: sourcegate
comments: true
date: 2010-05-22 09:16:29+00:00
layout: post
slug: changing-8-pins-at-a-time-with-the-arduino-environment
title: Changing 8 pins at a time with the Arduino environment
wordpress_id: 62
---

A quick demo of how to change 8 pins at a time with an Arduino, using some AVR C code:


    
    
    void setup() {
      DDRD = 0xFF;
    }
    
    void loop() {
      static uint8_t lights;
    
      lights >>= 1;
      lights ^= (~lights) << 7;
      PORTD = lights;
      delay(100);
    }
    



This makes lights connected to pins 0-7 flash (I [have a video](http://www.mediafire.com/?yjmzz3oqkrk)).  I used LEDs connected to 220Ω resistors.



I needed to use port D since that's the only port the Arduino exposes all pins on.  The problem is you need to disconnect pins 0 and 1 to upload a new sketch, because they're also the serial lines to the FTDI chip.



A bit about how it works:



`DDRD` is the Data Direction Register (DDR) for port D.  Bits set to 1 are outputs, and 0 are inputs.  This line sets them all to outputs.  Calling `pinMode()` on pins 0-7 manipulates this register.



In `loop()`, `static` means this value doesn't reset for each function call.  `uint8_t` means "unsigned 8-bit integer".  By using this instead of an `int`, the AVR only needs one instruction to manipulate it instead of the two it needs for the 16-bit `int`.



Setting `PORTD` changes the pins on port D.  Calling `digitalWrite()` with pins 0-7 changes this register, but writing to `PORTD` directly changes all of the pins at once.
