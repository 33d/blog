---
author: sourcegate
comments: true
date: 2010-03-12 12:46:47+00:00
layout: post
slug: microcontroller-ttl-to-rs232-communication
title: Microcontroller TTL to RS232 communication
wordpress_id: 17
---

I purchased [a USB to serial converter](http://cgi.ebay.com.au/ws/eBayISAPI.dll?ViewItem&item=280329271714&ru=http%3A%2F%2Fshop.ebay.com.au%3A80%2F%3F_from%3DR40%26_trksid%3Dm38%26_nkw%3D280329271714%26_sacat%3DSee-All-Categories%26_fvi%3D1&_rdc=1), popped it open and observed the two chips inside: a [PL-2303HX USB to Serial Bridge Controller](http://www.prolific.com.tw/support/files/%5CIO%20Cable%5CPL-2303HX%5CDocuments%5CDatasheet%5Cds_pl2303HXD_v1.1.pdf) for a USB to TTL serial converter, and a [ADM211](http://pdf1.alldatasheet.com/datasheet-pdf/view/48750/AD/ADM211ARS/+355W2utzXvDM-9-.VZ+/datasheet.pdf) for converting those TTL levels to RS232 levels.  Which is fine if you wanted to actually talk RS232.



But I want to talk to a microcontroller, with TTL level signals.  I thought about adding a few extra wires to the USB adapter, but I'd prefer to use the plug as-is.  It should be possible, looking at the datasheets.



The ADM211 will accept up to +0.5V for a "high" signal, so a TTL output from the microcontroller should be fine to communicate back to a computer, but the signal will be inverted.  That can be fixed in software.



The input is a bit trickier.  An ATmega32 will only accept -0.5V on an input pin before it fries itself, but the ADM211 sends its signals at ±10V.  A BS170 MOSFET though can handle a gate-to-source voltage of up to -20V - which is well outside what the ADM211 supplies.  I found [a circuit that
uses exactly that component](http://www.botkin.org/dale/rs232_interface.htm).  The guts of it looks like this:



{% wpimage block test1.png %}

It looks like it should work as advertised.  On a HIGH input from the microcontroller, the gate voltage will create a conducting channel within the FET, sending a low signal to the ADM211.  A LOW signal will turn off the FET, bringing the output to 5V through the pull-up resistor.



I also thought about using a logic IC, so I looked at a 74HC00.  The input voltage is the main problem - it's -0.5 to 7V.  A resistor will deal with the 7V, but I'll have to think about the -0.5V.



I have no idea whether I'll give it a shot one day...
