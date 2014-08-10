---
author: sourcegate
comments: true
date: 2014-02-23 11:39:06+00:00
layout: post
slug: openwrt-on-a-nokia-n800
title: OpenWRT on a Nokia N800
wordpress_id: 373
tags:
- n800
- nokia
- openwrt
---

**This is work in progress, so expect it to be added to/abandoned (probably the latter) at any time.**

I've got a Nokia N800 whose screen is on its way out that I'd like to find some other use for. Since Nokia seems [to](http://talk.maemo.org/showthread.php?t=89268) [have](http://discussions.nokia.com/t5/Maemo-and-MeeGo-Devices/How-to-obtain-firmware-when-tablets-dev-nokia-com-site-is-down/td-p/1779564) [abandoned this device](http://tablets-dev.nokia.com/), it looks like I'm on my own.  (To think I used to like their products!)  Good thing I still have a copy of the firmware, and found [a copy](http://213.128.137.28/showthread.php?t=90144) of the flasher software.  Let's hope Nokia really doesn't care, and lets this link stay here.

Anyway it looks like OpenWRT supported it once upon a time - [it's still listed in the source tree](https://dev.openwrt.org/browser/trunk/target/linux/omap24xx?rev=39554), albeit broken.  The omap24xx doesn't seem to be in any of the branches or tags, so I don't know how things get there.  Revision 30798 seems to be before they added the "broken" tag, so maybe that's a good place to start.

    
    $ git clone https://github.com/mirrors/openwrt.git
    $ cd openwrt.git
    $ git checkout 2f3210027ca1393766b0293b1bdd9fc6a13e88d7
    $ git branch n800
    $ git checkout n800


So now you apparently:

    
    $ make defconfig
    $ make menuconfig


select the N800/810 as the target

    
    $ make


I had a problem with mklibs not working with GCC 4.7, which [was easily fixed](https://lists.debian.org/debian-boot/2012/04/msg00057.html) (I made it [as a patch](http://wiki.openwrt.org/doc/devel/patches)).

And that worked for me!  In `bin`, I have a kernel, root filesystem and so on.


# Testing it out


I happened to notice [that you can boot a kernel that's been loaded into RAM](https://web.archive.org/web/20130401071739/http://wiki.meego.com/ARM/N900/Using_Rescue_Initrd):

    
    $ sudo flasher-3.5 -k openwrt-omap24xx-zImage \
        -r openwrt-omap24xx-root.squashfs -l -b"root=/dev/ram0"


That seemed to work, and the kernel output appears on my dodgy screen.  That stuff with the root filesystem didn't seem to work, but I noticed that the kernel was trying to look for the root filesystem on an MMC card.  I grabbed a convenient SD card and put the root filesystem on it, and the boot process seemed to go a bit further.

One problem: I get "Press enter to activate this console".  Without a keyboard, how will I do that?


# Adding a keyboard


Now that it boots, how am I going to communicate with it?  It's alright for a N810, which has a keyboard, but the N800 doesn't.  Apparently [there's a serial port in the back near the battery](http://wiki.maemo.org/Compiling_the_kernel#Serial_Console), but I don't know how I'd attach cables to those pads.  Maybe I can plug a USB keyboard into the USB OTG port.

Maybe someone has sorted it out - [Google to the rescue](https://www.google.com.au/search?q=openwrt+usb+keyboard) again!  [Apparently you have to](http://h-wrt.com/en/doc/kb):

    
    $ make menuconfig
    Base system:
     <*> busybox:
       Linux System Utilities:
         <*> lsusb
     Kernel modules:
       USB Support:
         <M> kmod-usb-hid


The kernel module was already selected for me.  Exit, save, then `make`.

Looking in the new root filesystem, lsusb is there.

I just found out about [0xFFFF](http://nopcode.org/0xFFFF/), another flasher for this device.  Let's give it a whirl:

    
    $ sudo 0xFFFF -i
    ...
    Device's USB mode is 'client


Maybe the USB port needs to be switched into OTG mode.

    
    $ sudo src/0xFFFF -U 1
    ...
    Set USB mode to: 'host'.


I'll try loading the kernel again, and... no luck

Maybe OpenWRT doesn't have any hotplugging function.  I'll try logging as much as possible on the console by [setting `klogconloglevel` to 8 in `/etc/config/system`](http://wiki.openwrt.org/doc/uci/system?s#system).  But there are two problems with this: I want to see syslog, not the kernel log; and that property [doesn't seem to be used](https://dev.openwrt.org/browser/trunk/package/base-files/files/etc/init.d/system?rev=39615) anyway.

During random googling, I found a link to Qemu. It turns out Qemu can emulate the N800! There seemed to be no keyboard input - since the n800 doesn't have a keyboard - but apparently the connector near the battery is [the 3rd serial port](http://lists.gnu.org/archive/html/qemu-devel/2008-04/msg00368.html). So you can solicit a terminal like this:

    
    $ qemu-system-arm -machine n800 -drive file=root,if=sd -kernel \
      openwrt-omap24xx-zImage -serial vc -serial vc -serial stdio


where `root` is an SD card image containing the root filesystem.

Now I've got something I can interact with, which should make things easier! (It sounds like [the Bluetooth module is connected to one of the UARTs](http://qemu.weilnetz.de/qemu-doc.html#ARM-System-emulator), which the above command might upset.)
