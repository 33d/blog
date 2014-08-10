---
author: sourcegate
comments: true
date: 2010-07-04 09:47:51+00:00
layout: post
slug: find-the-progress-of-a-command
title: Find the progress of a command
wordpress_id: 89
---

If you're running some command that takes a while, perhaps compressing a large file, you often want to know how far along it is.  This is when the `/proc/_pid_/io` file is useful.



I might have a `bzip2` process running with PID 3722, so `/proc/3722/io` might look like this:




    
    
    rchar: 1791093411
    wchar: 224891624
    syscr: 1308428
    syscw: 2992919
    read_bytes: 250478592
    write_bytes: 183074816
    cancelled_write_bytes: 0
    



The most useful are "rchar" and "wchar" - the number of bytes read and written by this process.



The [kernel documentation](http://kernel.org/doc/Documentation/filesystems/proc.txt) tells you more about this file.
