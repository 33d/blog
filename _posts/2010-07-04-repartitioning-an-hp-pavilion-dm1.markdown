---
author: sourcegate
comments: true
date: 2010-07-04 14:23:37+00:00
excerpt: How I repartitioned a hard disk that has all four primary partitions allocated.
layout: post
slug: repartitioning-an-hp-pavilion-dm1
title: Repartitioning a computer with four primary partitions
wordpress_id: 92
tags:
- '4'
- dm1
- four
- partition
- pavilion
- primary
- repartition
---

I recently bought a HP Pavilion DM1 with Windows 7 on it. I'm obviously not happy just having Windows on it, so I have to repartition the hard disk. The problem is that it came with four primary partitions from the factory. These are:



	
  1. A boot partition

	
  2. The main parition

	
  3. A recovery partition

	
  4. A HP Tools partition


I'd like to touch only the main partition, leaving the others intact, so the recovery and tools still work.

I took an image of the disk before I booted Windows for the first time. I'd like to move the main partition into an extended partition. The plan is to shrink the boot partition slightly, leaving some room for an extended partition header for the main partition. Then I'll add a logical partition in the same place the main partition is. Then I'll see how happy Windows is.

Here's `sfdisk -d` at the moment:

    
    unit: sectors
    
    /dev/sda1 : start=     2048, size=   407552, Id= 7, bootable
    /dev/sda2 : start=   409600, size=121634816, Id= 7
    /dev/sda3 : start=463384576, size= 24799232, Id= 7
    /dev/sda4 : start=488183808, size=   211312, Id= c


I'll fire up parted, and try to resize the boot partition:

    
    GNU Parted 2.2
    Using /dev/sda
    Welcome to GNU Parted! Type 'help' to view a list of commands.
    (parted) unit cyl
    (parted) p
    Model: ATA ST9250315AS (scsi)
    Disk /dev/sda: 30401cyl
    Sector size (logical/physical): 512B/512B
    BIOS cylinder,head,sector geometry: 30401,255,63.  Each cylinder is 8225kB.
    Partition Table: msdos
    
    Number  Start     End       Size     Type     File system  Flags
     1      0cyl      25cyl     25cyl    primary  ntfs         boot
     2      25cyl     7596cyl   7571cyl  primary  ntfs
     3      28844cyl  30388cyl  1543cyl  primary  ntfs
     4      30388cyl  30401cyl  13cyl    primary  fat32        lba
    
    (parted) resize 1 0cyl 24cyl
    WARNING: you are attempting to use parted to operate on (resize) a file system.
    parted's file system manipulation code is not as robust as what you'll find in
    dedicated, file-system-specific packages like e2fsprogs.  We recommend
    you use parted only to manipulate partition tables, whenever possible.
    Support for performing most operations on most types of file systems
    will be removed in an upcoming release.
    No Implementation: Support for opening ntfs file systems is not implemented yet.


I didn't notice the boot partition is NTFS!

    
    ubuntu@ubuntu:~$ sudo ntfsinfo -m /dev/sda1
    Volume Information
            Name of device: /dev/sda1
            Device state: 11
            Volume Name: SYSTEM
            Volume State: 1
            Volume Version: 3.1
            Sector Size: 512
            Cluster Size: 4096
            Volume Size in Clusters: 50943


So the filesystem is 208662528 bytes long. I want it 24 cylinders, which is 8225280 (according to `fdisk`) × 24=197406720.

    
    ubuntu@ubuntu:~$ sudo ntfsresize --size 197406720 /dev/sda1


I'll copy the output of `sfdisk -d`, then update the size of sda1 to 197406720÷512=385560 sectors:

    
    /dev/sda1 : start=     2048, size=   385560, Id= 7, bootable


Now to change sda2 to be the extended partition - observe that sda2 only takes up about 1/4 of the available space - it must get resized when Windows starts. I'll subtract 63 sectors from the start to make room for the new sda5 header, then make the end right before sda3. Then I'll change the partition type to 5.

    
    /dev/sda2 : start=   409537, size=462975039, Id= 5


I'll put the Windows partition back as sda5:

    
    /dev/sda5 : start=   409600, size=121634816, Id= 7


Now it's the moment of truth:

    
    ubuntu@ubuntu:/tmp$ sudo sfdisk -uS /dev/sda < sfdisk
    Checking that no-one is using this disk right now ...
    OK
    
    Disk /dev/sda: 30401 cylinders, 255 heads, 63 sectors/track
    Old situation:
    Units = sectors of 512 bytes, counting from 0
    
       Device Boot    Start       End   #sectors  Id  System
    /dev/sda1   *      2048    409599     407552   7  HPFS/NTFS
    /dev/sda2        409600 122044415  121634816   7  HPFS/NTFS
    /dev/sda3     463384576 488183807   24799232   7  HPFS/NTFS
    /dev/sda4     488183808 488395119     211312   c  W95 FAT32 (LBA)
    New situation:
    Units = sectors of 512 bytes, counting from 0
    
       Device Boot    Start       End   #sectors  Id  System
    /dev/sda1   *      2048    387607     385560   7  HPFS/NTFS
    /dev/sda2        409537 463384575  462975039   5  Extended
    /dev/sda3     463384576 488183807   24799232   7  HPFS/NTFS
    /dev/sda4     488183808 488395119     211312   c  W95 FAT32 (LBA)
    /dev/sda5        409600 122044415  121634816   7  HPFS/NTFS
    Warning: partition 1 does not end at a cylinder boundary
    
    sfdisk: I don't like these partitions - nothing changed.
    (If you really want this, use the --force option.)


Hmm, I don't think it ended on a cylinder boundary before either! I'll take a gamble - I can restore from the image if I need to - so I'll use `--force`.

I'll check that everything looks OK with the main parition:

    
    ubuntu@ubuntu:/tmp$ sudo dd if=/dev/sda bs=512 count=100k skip=$((409600 - 63)) | hexdump -C | less


I can see the partition signature at offset 1fd as expected, and the partition at offset 7c00 - right at the start of the 63rd sector. It looks good!

To be safe, I'll force Windows to check it:

    
    ubuntu@ubuntu:/tmp$ sudo ntfsfix /dev/sda5


Now I'll reboot and hope for the best!

It's checked the disks and is "preparing your computer for first use"...

... and everything starts fine! Windows did expand the partition to fill the remaining space, but I can shrink it again later. It also claims that I left 11 MB unallocated between the boot partition and the extended partition, but that's no big deal. The recovery partition and the HP tools still seem to work too.
