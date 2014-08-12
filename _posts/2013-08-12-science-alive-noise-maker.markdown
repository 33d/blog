---
author: sourcegate
comments: true
date: 2013-08-12 12:25:49+00:00
layout: post
slug: science-alive-noise-maker
title: Science Alive noise maker
wordpress_id: 359
---

For [Science Alive](https://www.facebook.com/Science4Everyone), I made a simple circuit that made noises in response to light changes.  Being something which makes noise it was popular with the kids.  It's based on circuits described in Nicolas Collins' "[Handmade Electronic Music](http://www.nicolascollins.com/handmade.htm)".  A few people asked me a circuit so I'll describe it here.

The circuit contains four oscillators provided by a [4093 Schmitt Trigger quad 2-input NAND gate](http://www.ti.com/lit/ds/symlink/cd4093bc.pdf‎).  [Individual inverting Schmitt trigger gates can oscillate](http://www.fairchildsemi.com/an/AN/AN-118.pdf), and by having more than one I could get one to turn another on and off, and mix the output of different oscillators together.

You'll need to play with different valued capacitors, I've listed the values I've used but try some different ones, particularly since your LDRs might be different to mine.

You'll need:



	
  * 1 4093 CMOS Schmitt trigger quad 2-input NAND gate

	
  * 2 small value electrolytic capacitors (I used 1µF)

	
  * 2 ceramic or greencap capacitors (I used 47pf)

	
  * 2 diodes (I used 1n914)

	
  * 4 light dependent resistors (LDRs) aka Cadmium Sulphide (CdS) cells

	
  * Batteries which provide 3-12V (I used 4×AAs) and a way to connect them to the breadboard

	
  * An amplifier and speaker, computer speakers or those battery powered speakers you get for music players should work

	
  * A breadboard (mine is a 390 hole "half size" one), and suitable wire


Here's the schematic.  I chose to pair my oscillators so that one turns the other on and off, and connected their outputs with diodes.  You can connect all four together in a line, or connect all of the outputs using diodes.  I've shown  a resistor to pull the output down when the oscillators are all low, but the amplifier probably has enough resistance at its input for that.

{% wpimage block science-alive-noisemaker-schematic-l.jpg %}

It looks like this wired up on a breadboard:

{% wpimage block science-alive-noisemaker-breadboard-l.jpg %}Mine looks like this:

{% wpimage block science-alive-noisemaker-photo.jpg %}

You can also see [this video of it in action](http://tinypic.com/r/144a5vd/5).
