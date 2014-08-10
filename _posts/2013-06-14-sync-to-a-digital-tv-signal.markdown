---
author: sourcegate
comments: true
date: 2013-06-14 09:54:55+00:00
layout: post
slug: sync-to-a-digital-tv-signal
title: Synchronize a Linux box to a digital TV signal
wordpress_id: 353
---

I remembered seeing some command which could synchronize the system clock to the digital TV (DVB) signal. This is ideal for a MythTV box which isn't connected to the internet.  It's `dvbdate`. One problem: [it ignores the system time zone](http://www.mythtv.org/wiki/Dvbdate). It can use the `TZ` environment variable, whose current value can be obtained using the date `command`:

    
    date +'%z'


so this will set the date:

    
    sudo TZ=$(date +'%:z') dvbdate --set


so you can put this script in `/etc/cron.hourly`, and make it executable:

    
    #!/bin/sh -e
    TZ=$(date +'%:z') dvbdate --set
