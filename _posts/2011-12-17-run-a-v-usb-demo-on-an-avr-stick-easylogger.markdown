---
author: sourcegate
comments: true
date: 2011-12-17 03:21:24+00:00
layout: post
slug: run-a-v-usb-demo-on-an-avr-stick-easylogger
title: Run a V-USB demo on an AVR stick (Easylogger)
wordpress_id: 117
tags:
- avr
- easylogger
- led
- sample
- stick
- usb
- v-usb
- vusb
---

This article describes how to run one of the [V-USB](http://www.obdev.at/products/vusb/index.html) demos on an [AVR stick](http://www.sparkfun.com/products/9147) (which is an [Easylogger](http://www.obdev.at/products/vusb/easylogger.html) clone).

V-USB is a firmware-only USB implementation for AVR 8-bit microcontrollers.  This means that it's possible for most AVR chips to communicate via USB, even though they have no hardware support for that.

[caption id="" align="alignright" width="188" caption="The AVR stick"]![](http://dlnmh9ip6v2uc.cloudfront.net/images/products/09147-1_i_ma.jpg)[/caption]

The AVR stick is a tiny circuit board that contains the minimum components to get a somewhat useful USB device, based on an ATmega85.  It costs about $10, and [is available in Australia from Little Bird Electronics](http://littlebirdelectronics.com/products/avr-stick) and also from [Sparkfun](http://www.sparkfun.com/products/9147).

I'll use the USB HID class, because it doesn't require any fancy drivers to get running.

First, grab the [V-USB code](http://www.obdev.at/products/vusb/download.html), (I'm using version 20100715), and extract the `/examples/hid-custom-rq` directory somewhere.

Let's get the firmware working first.  The AVR stick works a bit differently to the circuit the demo is for, so we need a few changes.

The ATmega85 only has one port: port B.  The sample uses port D.  Edit these lines in /firmware/usbconfig.h:

    
    #define USB_CFG_IOPORTNAME      B
    #define USB_CFG_DMINUS_BIT      0


The LED is on PORTB1, not PORTB0, so change `/firmware/main.c`:

    
    #define LED_BIT             1


Finally, we need to change the Makefile to match the ATmega85:

    
    DEVICE  = attiny85
    F_CPU   = 16500000


Where does 16500000 come from? The AVR stick uses the internal RC oscillator for its clock, which runs at about 8MHz.  The problem is, V-USB needs a clock speed of at least 12MHz to run.  ATmega5s have a fuse setting which doubles its clock speed (they call it the PLL clock or something like that).

While the internal RC clock is fairly stable, it's not very accurate.  When V-USB starts, it uses the USB signal to calibrate the clock so it runs at the same speed as the USB bus.  Using this calibration, it's possible to run the internal clock at 8.25MHz, which is doubled to 16.5MHz.  This is the speed the AVR stick must run at.

Since I was using the Bus Pirate to program the AVR stick, I had to change the `AVRDUDE=` line also.

That was it for the firmware - hopefully it compiles and uploads to the AVR stick.

Now for the software that runs on the computer.  When I compiled and ran `./set-led on`, I got this message:

    
    Could not find USB device "LEDCtlHID" with vid=0x16c0 pid=0x5df


but when I ran lsusb, I saw this line:

    
    Bus 002 Device 023: ID 16c0:05df VOTI


"VOTI" doesn't match "LEDCtlHID", no wonder it couldn't find it!  But when I ran `sudo lsusb -v`, I saw this instead:

    
    iProduct                2 LEDCtlHID


OK, so "VOTI" is simply the string form of the USB vendor ID 0x16c0, and the name "LEDCtlHID" is correct after all.  What's going on then?

I noticed that the usbOpenDevice function takes a few file descriptors, of which the final one is called `warningsFp`.  This is called from `set-led.c`; perhaps I'll change this last parameter from `NULL` to `stderr`.

When I ran `./set-led on` again, I got this:

    
    Warning: cannot query manufacturer for VID=0x16c0 PID=0x05df: error sending control message: Operation not permitted


That's a slightly more useful error message!  So the USB library doesn't seem to be able to use the device.  I read that some USB devices appear under `/dev/usb`, so let's have a look with `ls -l /dev/usb`:

    
    crw------- 1 root root 180, 96 2011-12-14 22:50 hiddev0
    crw------- 1 root root 180, 97 2011-12-16 21:33 hiddev1


Maybe that's the problem - there's no write permissions on the device.  To fix this, I'll make this device writable by everyone.  Create the file `/etc/udev/rules.d/90-avrstick.rules`, and put this in it:

    
    SUBSYSTEM=="usb", DEVTYPE="usb_device", SYSFS{idVendor}=="16c0", SYSFS{idProduct}=="05df", MODE="0666"


then `sudo reload udev`.  Remove the stick then put it back in, then look at `/dev/usb` again:

    
    crw------- 1 root root 180, 96 2011-12-14 22:50 hiddev0
    crw-rw-rw- 1 root root 180, 97 2011-12-16 21:42 hiddev1


That's a bit better.  Now run `./set-led on` - the white LED on the AVR stick should come on!

There's one improvement I can think of - the C code is pretty ugly, so I had a go in Python.  I copied the USB calls from the C code.  The Python code follows:

    
    import sys
    import usb
    import itertools
    
    vid=0x16C0; pid=0x05DF;
    
    devs = itertools.ifilter(
        lambda dev: dev.idVendor==vid and dev.idProduct==pid,
        (dev for bus in usb.busses() for dev in bus.devices)
    )         
    
    if len(sys.argv) == 1:
        print 'Specify "on", "off" or "status"'
        sys.exit(1)
    op = sys.argv[1]
    
    for dev in devs:
        #print "Handling device %04x:%04x" % (dev.idVendor, dev.idProduct)
        handle = dev.open()
        if op == "on" or op == "off":
            handle.controlMsg(
                usb.TYPE_VENDOR | usb.RECIP_DEVICE | usb.ENDPOINT_OUT,
                1, # = CUSTOM_RQ_SET_STATUS
                [], # Empty payload - the data goes in the "wValue" field
                value = (op == "on" and 1 or 0 )
            )
        else:
            data = handle.controlMsg(
                usb.TYPE_VENDOR | usb.RECIP_DEVICE | usb.ENDPOINT_IN,
                2, # = CUSTOM_RQ_GET_STATUS
                1, # How many bytes to read
            )
            print "LED is " + (data[0] and "on" or "off")


That's much shorter than the C code, and does the same thing (admittedly there's much less error handling here).  I used the [pyusb library](http://pyusb.sourceforge.net/) version 0.4.2.  The documentation for this library is a bit thin, but I found the Python command "`help(usb)`" of some use, as well as the source code for the library.

Talking to the USB device is all using Control signals, which I think you need to do because it's pretending to be an HID device.  I found it interesting that they never send data _to_ the AVR stick - they send the desired LED status in the "wValue" field, which sounds like a 16-bit field that's in every control message.  I don't know much about USB, but conveniently copying the C code worked fine.
