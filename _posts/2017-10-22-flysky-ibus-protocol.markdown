---
layout: post
title: The FlySky iBus protocol
slug: flysky-ibus-protocol
---

This is the FlySky iBus protocol that I've gleaned from [a blog post][ibus-blog] and a [single library][ibus-library].

Data is transmitted as serial UART data, 115200bps, 8N1.  A message is sent every 7 milliseconds.  [My receiver][my-receiver] sends this over its white wire, and stops sending a few tenths of a second after the transmitter is switched off (unlike the PPM signal on the yellow wire, which keeps sending its last value).

The first byte is 0x20, the second is 0x40.

Next are 14 pairs of bytes, which is the channel value in little endian byte order.  The FS-i6 is a 6 channel receiver, so it fills in the first 6 values.  The remainder are set to 0x05DC.  My transmitter sends values between 0x3E8 and 0x7D0.

Finally a 2 byte checksum is sent.  It's in little endian byte order, it starts at 0xFFFF, from which every byte's value is subtracted except for the checksum.

I've written [a library][my-library] to decode this data.  An Arduino could measure the time of the message start to improve detection of the message start.

ibus-blog: https://basejunction.wordpress.com/2015/08/23/en-flysky-i6-14-channels-part1/
ibus-library: https://github.com/aanon4/FlySkyIBus
my-library: https://github.com/33d/ibus-library
my-receiver: https://www.banggood.com/818CH-Mini-Receiver-With-PPM-iBus-SBUS-Output-for-Flysky-i6-i6x-AFHDS-2A-Transmitter-p-1183313.html

