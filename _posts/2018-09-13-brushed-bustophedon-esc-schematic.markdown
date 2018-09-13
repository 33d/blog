---
layout: post
title: Schematic for the "Bustodephon" brushed motor electronic speed controller (ESC)
slug: brushed-bustodephon-esc-schematic
---

I tried drawing the schematic for the common "Bustophedon" electronic speed controllers (ESC) for brushed motors.

{% image path: bustodephonschematic.png %}

The circuit is fairly straightforward to follow.  The zener diode based regulator for the receiver power is a bit surprising - I would have thought another regulator would have been cheap enough instead of several components.  I'm guessing the separate supply is to shield the microcontroller from the receiver, especially since it would be easy to supply power from another ESC.

The microcontroller has no markings, but there [are](https://www.lcsc.com/product-detail/_PMS153_C129129.html) [several](https://www.lcsc.com/product-detail/_SN8P2501D-SOP-14_C80639.html) very cheap microcontrollers which have a suitable pinout.

I'll have to analyze the microcontroller's output to see whether it does anything special.

