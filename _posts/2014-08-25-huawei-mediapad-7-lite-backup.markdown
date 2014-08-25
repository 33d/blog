---
layout: post
title: Back up the flash of a Huawei Mediapad 7 Lite
---

I recently purchased a Huawei Mediapad 7 Lite 4GB very cheaply on clearance.  It’s based on a Rockchip RK2918, which there are tools for to read and write the flash directly.  Before I start trying to hack it, I should get a backup of what’s already on it.

I found [a post](http://valentijn.sessink.nl/?p=382) which describes how the flash of a different Rockchip tablet can be backed up.  Maybe I can catch the USB device being recognized as I restart the tablet.

So, in one terminal:

    tail -f /var/log/kern.log
    
and then turn off the tablet.  The battery charge screen appears, and there’s nothing useful yet.

So I held down Volume + and the power button, the screen goes blank.  So I switched it off.  But wait: in the kernel log:             

    Aug 24 22:29:24 xpee kernel: [ 2187.324056] usb 1-5: new high-speed USB device number 7 using ehci-pci
    Aug 24 22:29:25 xpee kernel: [ 2187.869050] usb 1-5: unable to get BOS descriptor
    Aug 24 22:29:25 xpee kernel: [ 2187.869674] usb 1-5: New USB device found, idVendor=2207, idProduct=290a
    Aug 24 22:29:25 xpee kernel: [ 2187.869681] usb 1-5: New USB device strings: Mfr=0, Product=0, SerialNumber=0
    
and a quick search for vendor 2207… Rockchip!  Interesting… 

Following [the post mentioned earlier](http://valentijn.sessink.nl/?p=382):

    $ sudo ./rkflashtool r 0x0000 0x2000 > dump^C
    $ strings dump
    PARM
    FIRMWARE_VER:0.2.3
    MACHINE_MODEL:MediaPad 7 Lite
    MACHINE_ID:007
    MANUFACTURER:HUAWEI
    MAGIC: 0x5041524B
    ATAG: 0x60000800
    MACHINE: 2929
    CHECK_MASK: 0x80
    KERNEL_IMG: 0x60408000
    COMBINATION_KEY: 0,6,A,1,0
    CMDLINE: console=ttyS1,115200n8n androidboot.console=ttyS1 init=/init initrd=0x62000000,0x800000 mtdparts=rk29xxnand:0x00002000@0x00002000(misc),0x00004000@0x00004000(kernel),0x00008000@0x00008000(boot),0x00008000@0x00010000(recovery),0x00002000@0x00018000(backup),0x00006000@0x0001a000(oeminfo),0x00004000@0x00020000(vrcb),0x00008000@0x00024000(reserved),0x00100000@0x0002c000(cust),0x000e6000@0x0012c000(system),0x00080000@0x00212000(cache),0x00008000@0x00292000(userdata),0x00002000@0x0029a000(kpanic),-@0x0029c000(user)

I notice that this text appears several times, so I’d better keep this in mind.

The [Linux MTD documentation describes what `mtdparts` is for](https://www.kernel.org/doc/menuconfig/drivers-mtd-Kconfig.html#MTD_CMDLINE_PARTS).
So after copying the `mtdparts` bit to a file, with a bit of Perl magic I can dump each “part” to a file:

    $ perl -pe 's/([0-9a-fx-]*)@([a-f0-9x]*)\(([a-z]*)\).?/\2 \1 \3\n/g' < mtdparts | while read off len name ; do sudo ./rkflashtool r $off $len 2>/dev/null | xz > $name.xz ; done

But what about the last one, which lists the size as `-`?  I’ll try reading a block which shouldn’t exist:

    $ sudo ./rkflashtool r 0xfffffffd 1 | hexdump -C

It doesn’t seem to matter what I change the offset to, it seems to output part of the first block at some seemingly arbitrary offset.  Also, the offset seems to be the start offset in 512 byte blocks, but trying to read one block returns 0x4000 bytes of data.  Looking at [the source](http://sourceforge.net/p/rkflashtool/Git/ci/2bd62daeb5e63f4f1f92d1876b053a2be8cf428c/tree/rkflashtool.c#l248) suggests that it reads blocks of 0x4000 bytes, so that’s the minimum it’s going to return.  I tried hacking the code to fail [if the error flag in the response](http://sourceforge.net/p/rkflashtool/Git/ci/2bd62daeb5e63f4f1f92d1876b053a2be8cf428c/tree/doc/protocol.txt#l46) is set, but that didn’t help.

But [the bottom of the protocol description lists a FlashInfo structure](http://sourceforge.net/p/rkflashtool/Git/ci/2bd62daeb5e63f4f1f92d1876b053a2be8cf428c/tree/doc/protocol.txt#l94), which contains the number of blocks of flash, but I notice that command hasn’t been implemented.  I hope they didn’t leave it out because it bricks devices… ([hack hack hack](https://github.com/33d/rkflashtool/commit/3955541b14adbb8ad55198e870165752a52e4271)) I tried implementing it, but got this:

    $ sudo ./rkflashtool l | hexdump -C
    00000000  00 00 80 00 00 08 08 18  21 04 01 00 00 00 00 00  |........!.......|
    00000010  44 4e 41 4e 20 01 65 00  02 00 00 00 01 01 01 00  |DNAN .e.........|
    00000020  01 01 18 21 04 10 08 70  00 10 00 00 00 08 00 00  |...!...p........|
    00000030  00 01 00 00 00 00 10 00  00 00 80 00 00 00 80 00  |................|
    00000040  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
    *
    00000060  00 00 00 00 00 00 00 00  30 00 10 80 d0 60 70 00  |........0....`p.|
    00000070  30 60 10 80 d0 60 70 00  80 80 78 00 78 00 15 80  |0`...`p...x.x...|
    00000080  85 00 e0 05 e0 06 10 85  35 00 00 00 00 00 00 00  |........5.......|
    00000090  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
    *
    00000200

No permutations of those first 6 bytes and their endianness seem to produce anything useful, so I’ll try something else.

Maybe `/proc/mtd` will yield some secrets:

    1|shell@android:/ $ cat /proc/mtd
    dev:    size   erasesize  name
    mtd0: 00400000 00004000 "misc"
    mtd1: 00800000 00004000 "kernel"
    mtd2: 01000000 00004000 "boot"
    mtd3: 01000000 00004000 "recovery"
    mtd4: 00400000 00004000 "backup"
    mtd5: 00c00000 00004000 "oeminfo"
    mtd6: 00800000 00004000 "vrcb"
    mtd7: 01000000 00004000 "reserved"
    mtd8: 20000000 00004000 "cust"
    mtd9: 1cc00000 00004000 "system"
    mtd10: 10000000 00004000 "cache"
    mtd11: 01000000 00004000 "userdata"
    mtd12: 00400000 00004000 "kpanic"
    mtd13: 9a800000 00004000 "user"

Everything in the “size” column seems to be 512*what was listed in `mtdparts`.  This makes the `user` part 0x4D4000 long.  I can finally back up that part:

    $ sudo ./rkflashtool r 0x0029c000 0x4d4000 2>user.log | xz > user.xz

I ran `fsck.ext4 -c` on the result, and it was happy, so I guess I have the right length.

But I think it might be better to just grab the whole lot:

    $ sudo ./rkflashtool r 0 0x800000 2>all.log | xz > all.xz

where 0x800000 is 4GB/512, and is a bit bigger than the 0x0029c000+0x4d4000 that I calculated earlier.  I can verify various parts:

    $ diff <(xzcat user.xz | dd bs=512 ) <( xzcat all.xz | dd bs=512 count=$((0x4d4000))     skip=$((0x29c000)) )
    5062656+0 records in
    5062656+0 records out
    2592079872 bytes (2.6 GB) copied, 56.8184 s, 45.6 MB/s
    5062656+0 records in
    5062656+0 records out
    2592079872 bytes (2.6 GB) copied, 56.8161 s, 45.6 MB/s

`diff` produced no output, so the data are the same.  I’ll keep a copy of `all.xz` and the output from `./rkflashtool p` and `cat /proc/mtd`, which will let me recover whatever I need to. 

