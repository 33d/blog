---
layout: post
title: Check that your flash memory isn't fake
slug: check-for-fake-flash
---

Here's how I've checked that my flash memory (USB stick, SD card etc) isn't fake.  The idea is to use a cipher to produce a psuedorandom stream, write its output to the flash memory, then genenrate the stream again comparing it to the card.

First, find out how big the flash is:

    $ cat /proc/paritions
    major minor  #blocks  name
    ...
    8       16   30736384 sdb

Some quick maths tells me the block size is 1024 bytes.  Next, use `openssl` to encrypt some zeroes, writing the output to the card:

    $ dd if=/dev/zero bs=1024 count=30736384 | openssl enc -aes128 -k some-passworrd -nosalt | sudo tee /dev/sdb > /dev/null
    30736384+0 records in
    30736384+0 records out
    31474057216 bytes (31 GB) copied, 989.076 s, 31.8 MB/s
    tee: /dev/sdb: No space left on device

I don't know why it complains about no space, but the number of bytes written looks correct.

(Change some-password to some other word.)  `-nosalt` prevents openssl writing a header, which contains the password salt.  Because our encryption key (the `some-password` above) doesn't need to be secure, we don't care about it, and will stop the same stream being output next time.

Now check the result:

    $ dd if=/dev/zero bs=1024 count=30736384 | openssl enc -aes128 -k some-password -nosalt | sudo cmp - /dev/sdb
    30736384+0 records in
    30736384+0 records out
    31474057216 bytes (31 GB) copied, 367.183 s, 85.7 MB/s
    cmp: EOF on /dev/sdb

If it hits the end without complaining about differences, what's on the card is what was produced again by the cipher stream, so the card contains the advertised flash chip.

