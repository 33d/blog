---
author: sourcegate
comments: true
date: 2012-08-14 10:40:59+00:00
layout: post
slug: whiteboard-bots-first-drawing
title: Whiteboard bot's first drawing
wordpress_id: 181
---

{% image wp: true path: whiteboard-bots-first-drawing.jpg %}Here's the first drawing from my whiteboard robot! It doesn't draw anything by itself because I must have messed up the maths, but I was able to operate it manually and draw some circles. The lines are wonky because the wall the board was attached to was shaking. I didn't get the pen to move in and out, to draw separate lines.

The robot suspends a whiteboard marker from two strings.  The strings are wrapped around pulleys.  The strings are wound onto spools, driven by motors connected via a serial link to a PC.  The PC interprets an SVG image, and calculates how much each motor needs to turn to draw each line segment.

It's currently being driven with a [Pololu Baby Oranguatan](http://www.pololu.com/docs/0J14) and some [DC motors](http://www.goldmine-elec-products.com/prodinfo.asp?number=G16279)  that were lent to me, and various 3D printed parts to hold the pen and wind the string.

I have a few complaints about the Baby Orangutan.  First is their choice to use two wires to connect the H-bridge driver.  This makes the motors slightly easier to move, but means that to drive two motors, you need to use both 8-bit timers on the AVR.  With a 3-wire connection (two for direction, one for PWM), I would only have needed to use one timer, leaving the other one for Arduino compatibility or to drive the servo which moves the pen in and out.  My other issue is the placement of the status LED: I would have thought it goes on port B5 - like the Arduino - but they put it on one of the serial port pins, making it useless if you're using the serial port.

I had the circuit powered at Science Alive for a few hours, but the manual movement function stopped working.  I connected the circuit on perfboard using very thin enamelled wire.  I doubled the wires between the H-bridge chip and the motors, but wasn't smart enough to do the same for the power supply, so there might have been some brownouts when the motors started.  I should add some capacitors too.  The motors were less powerful than I expected, so my 10cm reels put a bit too much strain on the motors.  I'll have to get some smaller reels printed.

I think I'll get the simulator running again - hopefully that will help me get the calculations for the reel movement correct.
