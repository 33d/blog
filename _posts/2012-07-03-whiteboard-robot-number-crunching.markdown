---
author: sourcegate
comments: true
date: 2012-07-03 10:59:32+00:00
layout: post
slug: whiteboard-robot-number-crunching
title: Whiteboard robot number crunching
wordpress_id: 157
tags:
- calculation
- drawing
- length
- math
- maths
- robot
- string
- whiteboard
---

I'm thinking of building a robot that suspends a whiteboard marker from two strings, and draws on a whiteboard.  There would be two motors that can change the length of the strings.

I was playing with some calculations for this robot, literally on the back of an envelope.  I need to calculate how long each string will be for a particular coordinate.

{% wpimage block whiteboard-robot-maths-1.png %}

Pythagoras' theorem gives:

$latex l_1^2=x^2+y^2 &s=1$

and

$latex l_1^2=r^2+s^2 &s=1$

If we smash them together, we get:

$latex r^2 + s_1^2 = x^2 + y^2 &s=1$

$latex s_1 = \sqrt{x^2+y^2-r^2} &s=1$

and of course

$latex s_2 = \sqrt{(w-x)^2+y^2-r^2} &s=1$

That was easier than I expected - the maths wasn't too hard!  This should be enough to draw short segments with linear interpolation.

But, I'd like to know how the string length changes as I draw a straight line.  Imagine a line being drawn perpendicular to the string; when the length of the string gets very long, it should lengthen at the same rate as the line.  This suggests that the string length and the line length forms a hyperbola.

Consider a horizontal line beneath one of the wheels.  Let _x_ be the distance from the closest point on the line to the wheel.  _s_ is the string length.  If the line went through the wheel, the graph

$latex \frac{x}{s}=1 &s=1$

would give the line where the _x_ position is the same as the string length.

If the line does not pass through the wheel, this equation from earlier where _r_ is the wheel radius and _y_ is the shortest distance from the wheel to the line:

$latex s^2 = x^2 + y^2 - r^2 &s=1$

can become

$latex 1 = \frac{x^2 + y^2 - r^2}{s^2} &s=1$

which should produce a hyperbola.  When the string is long enough, _y²-r²_ becomes negligible.

Previously I've implemented Bresenham's algorithm to interpolate values on an AVR; it would be nice to do the same thing to calculate this parabola while drawing a straight line segment.  It turns out [ someone has worked out how to use calculations like this for hyperbolae](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.19.2194&rep=rep1&type=pdf).

