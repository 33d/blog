---
layout: post
title: How to install OSX El Captian
slug: osx-el-capitan-install
---

I acquired an [aluminium Intel iMac](https://en.wikipedia.org/wiki/IMac_(Intel-based)#Aluminum_(2007%E2%80%932009). I proceeded to ruin the installation. Recovery still worked (if it doesn't, try some [other instructions](https://gist.github.com/coolaj86/22d08c4b582779485e0df11c5d84063a)). Attempting to reinstall from recovery wants to download from the app store, but apparently El Capitan isn't in there anymore. How can I recover it?

1. Download El Capitan [from Apple](https://support.apple.com/en-us/HT211683).  Its sha256sum is `bca6d2b699fc03e7876be9c9185d45bf4574517033548a47cb0d0938c5732d59`, md5 is `5040a59d785d7da609755244c4ed136c`.
1. Most guides - including those from Apple - say that you have a `.app` file. This downloaded file clearly isn't. Boot into recovery, then transfer the `.dmg` file to the Mac (try using an exfat partition for a USB drive).
1. Use disk manager to mount the image. The partition on the USB disk didn't show up for me, so open a terminal, then:
   1. `diskutil list` to identify the partition
   1. `cd /Volumes`
   1. `mkdir usb`
   1. `mount -t exfat /dev/disk2s1 usb`
   1. Close the terminal, open Disk Utility
   1. Go to File, Open Disk Image
   1. Find the mounted USB disk, and open `InstallMacOSX.dmg`
1. Create a volume to store the files if necessary. (Don't format it as FAT - it can't store files big enough!)
1. 
   ```
   $ cd (the volume to put files in)
   $ pkgutil --expand InstallMacOSX.pkg elcapitan
   $ ls -F elcapitan
   Distribution*       InstallMacOSX.pkg/ Resources/
   $ cd elcapitan/InstallMacOSX.pkg/
   $ tar -xvf Payload
   x .
   x ./Install OS X El Capitan.app
   x ./Install OS X El Capitan.app/Contents
   …
   $ mv InstallESD.dmg "Install OS X El Capitan.app/Contents/SharedSupport"
   ```
1. Erase the disk and mount it
   ```
   # diskutil eraseDisk HFS+ elcapitan disk2
   # diskutil mount /dev/disk2s2
   ```
1. 
   ```
   # "Install OS X El Capitan.app/Contents/Resources/createinstallmedia" --volume /Volumes/elcapitan --applicationpath "Install OS X El Capitan.app"
   Ready to start.
   To continue we need to erase the disk at /Volumes/MyBlankUSBDrive.
   If you wish to continue type (Y) then press return:
   ```
1. Boot to the USB drive (hold Command/Alt). If you try to install the obvious way, the installation will fail, saying the installer is corrupt. Open a terminal instead, and run:
   ```
   installer -pkg  /Volumes/Mac\ OS\ X\ Install\ DVD/Packages/OSInstall.mpkg -target /Volumes/"XXX"
   ```

That was way more complicated than it had to be! Why can't I download a bootable ISO? I'm keeping an image of the install USB stick.

= Resources =

* https://chriswarrick.com/blog/2020/06/03/reinstalling-macos-what-to-try-when-all-else-fails/#toc-entry-4
* https://gist.github.com/coolaj86/22d08c4b582779485e0df11c5d84063a
* https://apple.stackexchange.com/a/232016


