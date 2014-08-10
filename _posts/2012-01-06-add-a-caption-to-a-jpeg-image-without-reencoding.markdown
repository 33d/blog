---
author: sourcegate
comments: true
date: 2012-01-06 12:02:12+00:00
layout: post
slug: add-a-caption-to-a-jpeg-image-without-reencoding
title: Add a caption to a JPEG image without reencoding
wordpress_id: 129
tags:
- caption
- jpeg
- label
- lossless
- overlay
- re-encode
- reencode
---

I was looking for a way to add captions to JPEG images without re-encoding them.  It turns out there's [a patch to jpegtran](http://jpegclub.org/jpegtran/) that overlay one JPEG image over another one, without re-encoding either.  Here's how I built it:



	
  1. Download [the sources of the IJG version of jpegtran](http://www.ijg.org/) (I used version 8c), and decompress it somewhere

	
  2. Download [the "drop" patch](http://jpegclub.org/droppatch.v8.tar.gz), and copy the source files into the source extracted in the previous step

	
  3. configure, make (as usual)


I made a script that automatically adds a label using Imagemagick to create the label, and this version of jpegtran to put them together:

    
    #!/bin/sh
    
    JPEGTRAN="/opt/jpeg-8c/bin/jpegtran"
    
    if [ $# -lt 3 ] ; then
    echo "Usage: jpeglabel [label] [in] [out]" >2
    exit 2
    fi
    
    LABELFILE=`mktemp`
    convert -type truecolor -size 256x16 "label:$1" jpg:"$LABELFILE"
    "$JPEGTRAN" -drop +16-16 "$LABELFILE" -outfile "$3" "$2"
    
    rm "$LABELFILE"


I tried making some examples to show, but it turns out the (experimental) "drop" patch is very fussy about the files you give it.  I got it to work on 320x240 pictures from my camera, but not on some other images I tried.  It requires the "sampling ratio" to be the same on both images, which is found in the advanced JPEG settings in Gimp.
