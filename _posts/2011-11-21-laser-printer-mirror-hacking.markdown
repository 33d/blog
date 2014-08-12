---
author: sourcegate
comments: true
date: 2011-11-21 10:11:11+00:00
layout: post
slug: laser-printer-mirror-hacking
title: Laser printer mirror hacking
wordpress_id: 101
---

I pulled the mirror out of a laster pinter, and I had a go making it work.

{% wpimage block printer_mirror_circuit.jpg %}

I'd seen an article before that does this, but I [had a datasheet for the driver chip](http://www.google.com/url?sa=t&rct=j&q=lb11872&source=web&cd=1&ved=0CBsQFjAA&url=http%3A%2F%2Fwww.alldatasheet.com%2Fview.jsp%3FSearchword%3DLB11872-SOP&ei=Ph_KTvPjM8OaiQf0k_DeDw&usg=AFQjCNEoIPeeMnwf_LmETZxn0WEhLxJbsg&cad=rja).  Conveniently all of the pins I needed had test points on the board - that saves me having to attach something to the original plug.

{% wpimage block mirror_labelled.jpg %}It was pretty easy to drive - apply 12V, put a square wave on CLK and pull SS low.  The datasheet says that 5V is fine for the clock signal.  Apparently LD changes state once the mirror is up to speed.  The laster started spinning at 50Hz, but ran a bit rough below 500Hz.  It didn't get any faster once the signal was at 5kHz.

To test out the relationship between the mirror and the clock signal, I made an Arduino flash a light 6 times for each clock pulse.  I saw 6 reflections in the mirror, so I guess the mirror spins 1/6 of a resolution for each clock pulse.

I tried running it at 5V, but I had no luck there.
