---
author: sourcegate
comments: true
date: 2012-12-06 11:02:06+00:00
layout: post
slug: frickin-lasers
title: Frickin' lasers
wordpress_id: 319
---

I purchased a [quantity of cheap laser modules](http://www.ebay.com.au/itm/271020487750) for a project.  They were advertised as 3V modules, but they all have 39Ω resistors in series for current limiting.  When connected to two AAA batteries, I measured 15mA and a forward voltage of 2.15V.  This makes the resistor value 0.85V/15mA=57Ω though.


{% image wp: true path: laser_module_1.jpg %}{% image wp:true path: laser_module_3.jpg %}{% image wp:true path: laser_module_2.jpg %}
