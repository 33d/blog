---
layout: post
title: Save space used by an Ubuntu VM by using the live CD
slug: save-space-used-by-an-ubuntu-vm
---

I like to use VMs when doing things which might put stuff all over the filesystem or needs root access to install.  But at a few gigabytes each they quickly take up space.  I managed to use the live CD image as a base, which is compressed and can be shared among virtual machines.

1.  Create a virtual machine with a hard disk of your choosing.  Boot the Ubuntu live CD in it.
2.  Create a partition on the virtual hard disk for persistence, and make it bootable.
3.  Format it, give it a label:

        $ sudo bash
        # mkfs.ext2 /dev/sda1 -L overlay
4.  

        # mount /dev/sda1 /mnt

5.  

        # mkdir /mnt/boot

6.  

        # cp -p /cdrom/casper/vmlinuz.efi /mnt/boot

7.  We need to [edit <code>/etc/casper.conf</code> inside the initrd](https://wiki.ubuntu.com/CustomizeLiveInitrd):

        # cd /tmp
        # mkdir i
        # cd i
        # lzcat /cdrom/casper/initrd.lz | cpio -i

    now put in /tmp/i/etc/casper.conf (I found out the variables by looking through [<code>/usr/share/initramfs-tools/scripts/casper</code>](http://bazaar.launchpad.net/~ubuntu-branches/ubuntu/trusty/casper/trusty/view/head:/scripts/casper), which is run by the kernel command line's `boot` parameter.):
        
        # This file should go in /etc/casper.conf
        # Supported variables are:
        # USERNAME, USERFULLNAME, HOST, BUILD_SYSTEM, FLAVOUR
        
        export USERNAME="user"
        export USERFULLNAME="Live session user"
        export HOST="vm"
        export BUILD_SYSTEM="Ubuntu"
        
        # USERNAME and HOSTNAME as specified above won't be honoured and will be set to
        # flavour string acquired at boot time, unless you set FLAVOUR to any
        # non-empty string.
        
        export FLAVOUR="Ubuntu"
        
        export PERSISTENT="Yes"
        export root_persistence="overlay"

    You can customize your username and host name in this file too.  Note `root_persistence` is the label we specified in step 3.  Now compress the initramfs:

        # cd /tmp/i
        # find . | cpio --quiet --dereference -o -H newc | lzma -7 > /mnt/boot/initrd.lz

8.  Now for a bootloader which uses the above stuff.  Install the extlinux package.  I grabbed the .deb [from the package search](http://packages.ubuntu.com/trusty/extlinux).

9.  Install extlinux:

        # extlinux -i /mnt/boot/extlinux

    Put this in `/mnt/boot/extlinux/extlinux.conf`:

        DEFAULT linux
        
        LABEL linux
        KERNEL /boot/vmlinuz.efi
        APPEND boot=casper initrd=/boot/initrd.lz noprompt

10. The hard disk is probably missing a master boot record.

        # dd if=/usr/lib/syslinux/mbr.bin of=/dev/sda

11. Unmount `/mnt` and reboot.


