---
layout: post
title: Sub 50 cent microcontrollers
slug: sub-50c-microcontrollers
---

[$1 microcontrollers][one-dollar], pfft.  What useful ones are around for under 50 cents?

The qualifications:

 * There needs to be adequate documentation
 * Programmamble with readly available (and cheap) hardware.  This rules out a lot of ones from Megawin, Sinowealth and so on; while they have reasonable user manuals, there's no information on how to program them, short of buying a $20 programmer.
 * Are readily available.  I ruled out parts only available from Taobao, for instance.

I was left with these:

 * The STM8S103.  They're not *the* cheapest, but are readily available in the West.  There's a cheaper STM8S003, but its flash is rated to only 100 writes, so it sounds like the idea is to develop for the S103 first.
 * The Nuvoton N76E003.  It has loads of peripherals, and is pin compatible with the STM8S103.
 * The STC microcontrollers.  Not quite as much bang for buck as the Nuvoton, and unavailable in the West, but come in 8 pin packages.

The Atmel ATtiny13 also qualifies, but I already know how to program those!

All should be programmable using [SDCC], and either a ST-Link or USB-Serial dongle.  I've purchased development boards for the [STM8][board-stm8], [Nuvoton][board-nuvoton] and a [STC15W204][board-stc].  I hope to try these out and write about them.

[one-dollar]: https://jaycarlson.net/microcontrollers/
[board-stm8]: https://www.aliexpress.com/item/STM8S103F3P6-System-Board-STM8S-STM8-Development-Board-Minimum-Core-Board/32885918852.html
[board-nuvoton]: https://www.aliexpress.com/item/51-Development-Board-N76E003AT20-Development-Board-System-Board-Core-Board-N76E003/32898770085.html
[board-stc]: https://www.aliexpress.com/item/STC15W204S-SCM-Minimum-System-Board-Development-Board-51-SOP8-STC15F104E/32899351974.html
[SDCC]: http://sdcc.sourceforge.net/

