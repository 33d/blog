---
author: sourcegate
comments: true
date: 2012-10-28 08:19:27+00:00
layout: post
slug: video-signal-output-circuitry
title: Video signal output circuitry
wordpress_id: 286
tags:
- discovery
- mixer
- output.sync
- resistors
- signals
- stm32
- video
---

I'll need a simple circuit to mix my video signals together. [The Arduino TV Out library shows how to do this](http://code.google.com/p/arduino-tvout/), but that works with 5V IOs, but the [STM32L Discovery](http://www.st.com/internet/evalboard/product/250990.jsp) (and all ARM chips AFAIK) uses 3.3V.

So which resistors will I need?  To produce a white signal, the sync and video lines will be high.  The equivalent circuit looks like this:

[![](http://sourcegate.files.wordpress.com/2012/10/video-out-high-schematic.png)](http://sourcegate.files.wordpress.com/2012/10/video-out-high-schematic.png)(The 75Ω resistor is the resistance inside the TV).

To show a black signal, the sync line will be high, and the video line will be low, which looks like this:

[![](http://sourcegate.files.wordpress.com/2012/10/video-out-low-schematic.png)](http://sourcegate.files.wordpress.com/2012/10/video-out-low-schematic.png)

[Wikipedia gives the formula for a voltage divider](http://en.wikipedia.org/wiki/Voltage_divider#General_case), so the resistors in the first diagram can be calculated with this formula:

FIXME

and in the second:

FIXME

I tried solving these, but that's well beyond my mathematical ability.  Instead I found some online site that could [plot the two formulas](http://www.quickmath.com/webMathematica3/quickmath/graphs/equations/advanced.jsp#c=plot_advancedgraphequations&v1=1%3D75%2F(75%2B1%2F(1%2Fy%2B1%2Fx))*3.3&v2=0.3%3D(1%2F(1%2Fy%2B1%2F75))%2F((1%2F(1%2Fy%2B1%2F75))%2Bx)*3.3&v7=x&v8=y&v9=0&v10=1000&v11=0&v12=1000&v19=1&v24=1&v25=Video+generator+resistors) (edit: I could have [used Wolfram Alpha](http://www.wolframalpha.com/input/?i=1%3D75%2F%2875%2B1%2F%281%2Fy%2B1%2Fx%29%29*3.3%2C+0.3%3D%281%2F%281%2Fy%2B1%2F75%29%29%2F%28%281%2F%281%2Fy%2B1%2F75%29%29%2Bx%29*3.3)).  The lines crossed at about RV=250Ω and RS=580Ω. These resistor values don't exist, so RV=270Ω and RS=560Ω is close enough.  They seem to work fine in the circuit.
