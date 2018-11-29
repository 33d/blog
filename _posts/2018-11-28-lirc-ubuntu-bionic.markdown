---
layout: post
title: Serial LIRC devices on recent Ubuntu releases
slug: lirc-ubuntu-bionic
---

I tried to get a "homebrew" infrared receiver attached to the DCD line of a serial port working on Ubuntu Bionic.  It seems that things have changed since Ubuntu 12.04, when I last had it working.

The changes ended up being:

- The kernel modules are in the mainline kernel, but aren't supplied with Ubuntu
- The LIRC driver's name has changed from "serial" to "default"

My first problem is that the receiver wasn't working in the first place.  I attached a DSO Nano to the data line, and noticed that the signal didn't have a high enough voltage to trigger the serial port.  The [data sheet][rx-datasheet] shows the receiver's output being a pull-up resistor with a transistor pulling the output low; maybe this serial port draws a particularly large amount of current.  I wired a 2.2k resistor between the data line and VCC (which should be within the limits of the receiver), and everything works.

I tested it with this program, which displays a time when the DCD line changes:

    #include <stdio.h>
    #include <unistd.h>
    #include <sys/types.h>
    #include <sys/stat.h>
    #include <fcntl.h>
    #include <sys/ioctl.h>
    #include <termios.h>
    #include <stdlib.h>
    #include <string.h>
    #include <errno.h>
    #include <time.h>
        
    int die(const char* msg) {
      perror(msg);
      printf("%s\n", strerror(errno));
      exit(1);
    }

    int main(void) {
      int fd = open("/dev/ttyS0", 0);
      if (fd == -1)
        die("open");
      while (1) {
        struct timespec tm;
        ioctl(fd, TIOCMIWAIT, TIOCM_CD | TIOCM_RNG | TIOCM_DSR | TIOCM_CTS);
        if (clock_gettime(CLOCK_MONOTONIC, &tm) == -1)
          die("clock_gettime");
        printf("%ld\n", tm.tv_nsec);
      }
      close(fd);
      return 0;
    }

(So why does LIRC need the kernel driver, if this works in userspace?  I suspect it's because the LIRC API requires a timeout, which the `ioctl` doesn't support.)

LIRC's serial port support works by using a kernel module to read the hardware, and sends the output to `/dev/lirc0`.  LIRC connects to this device to read the input.  The LIRC userspace driver that does this is called "default" (it used to be called "serial").

It seems a few releases ago the drivers were upstreamed, and aren't supplied with Ubuntu.  I got the driver installed with DKMS:

1. Create a working directory
2. Put the [driver][driver-source] in it.  (Choose the appropriate version for your kernel.)
3. Add this Makefile:

        obj-m += serial_ir.o

        all:
        	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

        clean:
        	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

4. Add this `dkms.conf`:

        PACKAGE_NAME="lirc_serial_ir"
        PACKAGE_VERSION="4.15"
        CLEAN="rm -f *.*o"
        BUILT_MODULE_NAME[0]="serial_ir"
        DEST_MODULE_LOCATION[0]="/updates"
        AUTOINSTALL="no"

 5. Run `sudo dkms add .`
 6. Run `sudo dkms install lirc_serial_ir/4.15`.

Now run `sudo modprobe lirc_serial`.  Run `dmesg`, and you should see:

    [ 1627.908509] serial_ir serial_ir.0: port 03f8 already in use
    [ 1627.908515] serial_ir serial_ir.0: use 'setserial /dev/ttySX uart none'
    [ 1627.908516] serial_ir serial_ir.0: or compile the serial port driver as module and
    [ 1627.908517] serial_ir serial_ir.0: make sure this module is loaded first
    [ 1627.908532] serial_ir: probe of serial_ir.0 failed with error -16

To fix this, install the "setserial" package, and [disable the serial port as the instructions say][disable-serial-port].

Try running mode2, and press some buttons on the remote:

    $ sudo mode2 --driver default
    Using driver default on device auto
    Trying device: /dev/lirc0
    Using device: /dev/lirc0
    Running as regular user
    space 504574
    pulse 9015
    space 4548
    pulse 488

[rx-datasheet]: https://www.mouser.com/ds/2/348/rpm6900-313874.pdf
[driver-source]: https://elixir.bootlin.com/linux/v4.15.18/source/drivers/media/rc/serial_ir.c
[disable-serial-port]: http://www.lirc.org/html/configuration-guide.html#serial_port_reservation

