---
author: sourcegate
comments: true
date: 2013-05-20 10:20:59+00:00
layout: post
slug: the-virtual-guestbook
title: The Virtual Guestbook
wordpress_id: 327
---

_This is work in progress, so there's plenty of gaps!_

I've been asked to look at using a venerable [TP-Link TL-WR703N](http://wiki.openwrt.org/toh/tp-link/tl-wr703n) as a virtual guestbook, where people can connect using Wi-fi and leave a message.  I plan to use OpenWRT on it, since they support that device.

It will have a USB stick attached to it, so there will be plenty of storage space (kind of, see below) and the CPU is adequate, but the system needs to fit in 32MB of RAM, so there's a few things to consider.


# The web server


The OpenWRT wiki [lists a bunch of available web servers](http://wiki.openwrt.org/doc/howto/http.overview).  Here's what I think of them:
<table >
<tbody >
<tr >
Server
Notes
</tr>
<tr >

<td >Apache HTTPD
</td>

<td >✗ Big. Not really designed for this kind of thing.
</td>
</tr>
<tr >

<td >Hiawatha
</td>

<td >✓ Small
✓ Virtual hosts
✓ CGI
✓ FastCGI
✗ No CGI process limiting
</td>
</tr>
<tr >

<td >Busybox HTTPD
</td>

<td >✓ Small
✓ FastCGI
✗ No logging to Syslog
✗ No connection limiting
</td>
</tr>
<tr >

<td >lighttpd
</td>

<td >✓ Very configurable
✓ FastCGI
✓ Built-in PHP support
✓ Virtual hosts
✗ No 302 redirection support
✗ A bit big
</td>
</tr>
<tr >

<td >mini-httpd
</td>

<td >✓ Small
✓ CGI
✗ No virtual hosts
✗ No connection limiting
</td>
</tr>
<tr >

<td >nginx
</td>

<td >✓ Very configurable
✓ CGI and FastCGI
✓ Virtual hosts
✗ No CGI connection limiting
</td>
</tr>
<tr >

<td >uhttpd
</td>

<td >✗ No setuid
✗ Single threaded
</td>
</tr>
<tr >

<td >An inetd wrapper
</td>

<td >✓ Control of the number of processes
✗ I'd have to write stuff myself, with the associated performance, conformance and security gotchas.
</td>
</tr>
</tbody>
</table>
I need virtual hosts so when people open their web browser and go to some random site (whatever their home page is), they get redirected to the guestbook. Ideally this won't be a 301 permanent redirect, so when people go to their [Kittenwar](http://www.kittenwar.com/) home page they don't end up being sent to the (now non-existent) guestbook.

None of these can log to syslog. I'd rather not log to a file because it causes extra flash wear. Busybox provides a ring buffer for logging. I tried messing around with fifos instead but couldn't get it to work.  Maybe I'll use a tmpfs for /var/log and logrotate them to flash.  (Actually /var already points to /tmp, which is tmpfs.)

I can only run a few processes at a time before the RAM fills up. This could be handled by the web server, or if fastCGI is used, the runtime for the script. I first thought I'd only server one at a time, but if one client isn't responding that will block all other users. 4 processes should be enough.

Setuid would be handy so the server can run at port 80 as an unprivileged process, but I could use iptables to redirect the port instead.

Hiawatha looks like the most suitable, but nginx would be OK too. Neither can control how many CGI processes are run, but PHP has a FastCGI option that does this.


# The post script


Something needs to handle the form submission. For a small environment C would be the ideal choice, but it's hard to avoid security problems and I'd rather avoid having to use the OpenWRT build environment.

The options I see are PHP, Perl and Lua. PHP is good for this kind of thing and I've actually used it before, so it will do. PHP also has control over POST sizes (I don't want people filling up the storage) and how many processes it starts.

While running, PHP seems to use about 1MB of private space per instance, so a few processes can run. I'll need to try it in FastCGI mode too.


# The filesystem


The device only has 4MB of storage, so jamming the web server and PHP into that could take some doing. I do have perfectly good and relatively unlimited storage on the USB stick. I'd like to overlay a filesystem on the USB stick over the stock OpenWRT image to give me plenty of space.  I'll also know exactly what I've changed by looking at the overlay filesystem.

One problem with this system is it can have its power cut at any time. I'll have to live with that risk. ext4's journal should help avoid fscks, and there won't be that many writes so the journal shouldn't make much difference to the flash life (I'd expect hundreds of writes a day, not millions).


# The database


I can think of three options for this: one flat file, one file per post and sqlite.  I'll rule out sqlite because I don't know what its memory consumption is like, and PHP doesn't seem to give you access to any [memory tuning options](http://www.sqlite.org/malloc.html).

One flat file would be the most space efficient, but corruption could be a problem if the device loses power or I stuff up the post script and there's concurrent access.  I don't get random access either, should I want to "show the last few messages" or something.

One small file for each post allows random access and reduces the chance of corruption.  It wastes a lot of space, but I have a whole USB stick to use, and using smaller clusters on the filesystem should limit that.


# Recording stuff


There are some other small problems: the device has no idea what time it is or where it is.  This information can come from Javascript in the browser.


# The captive portal


When you use some wireless hotspots, they first redirect you to a page with their legalese on it.  This is called a [Captive Portal](http://en.wikipedia.org/wiki/Captive_portal).  I can use the same thing here to redirect the user to the guestbook when they open their browser.

The idea in this case is to tell the client computers to use the router as the default gateway.  iptables then redirects all connections to a web server, which does a temporary redirect to the real web server.  If the clients have cached DNS entries, this method should affect that the least.  This is why virtual hosts are useful in a web server - any host but the correct one will get the redirect page.
