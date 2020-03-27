---
layout: post
title: Cyber FastTrack 2020 Forensics FE01 challenge
slug: cyber-fasttrack-spring-2020-fe01
---

This is a challenge from Cyber FastTrack Spring 2020, using the same image as FH05.

> Take a look at the memory image provided and see if you can see what was written on Notepad while it was open on the user's screen.

A good place to start might be to look at the memory for notepad?

```
$ vol pslist
Volatility Foundation Volatility Framework 2.6
Offset(V)          Name                    PID   PPID   Thds     Hnds   Sess  Wow64 Start                          Exit                          
------------------ -------------------- ------ ------ ------ -------- ------ ------ ------------------------------ ------------------------------
...
0xfffffa8002642610 notepad.exe            2740    612      1       57      1      0 2019-09-05 15:33:20 UTC+0000 
```

I'll start by dumping the memory:

```
$ mkdir dump
 vol procdump -D dump/ -p 2740
Volatility Foundation Volatility Framework 2.6
Process(V)         ImageBase          Name                 Result
------------------ ------------------ -------------------- ------
0xfffffa8002642610 0x00000000ff410000 notepad.exe          OK: executable.2740.exe
$ xxd dump/executable.2740.exe |less
$ ls -al dump/executable.2740.exe 
-rw-r--r-- 1 kali kali 193536 Mar 26 16:48 dump/executable.2740.exe
```

Not too big.  Normally I'd use `strings` on something like this, but Windows has a habit of using UTF-16 to store text, so I thought this command won't help - but the `-el` option does just that!  It didn't show anything interesting though.

There's a screenshot command! That would be too easy if it worked...

```
$ mkdir shots
$ vol screenshot -D shots
Volatility Foundation Volatility Framework 2.6
Wrote shots/session_0.Service-0x0-3e4$.Default.png
Wrote shots/session_0.Service-0x0-3e5$.Default.png
```

No luck, but there is one image which shows where notepad and cmd.exe is on the display.

There's a `wintree` command, which shows the GUI components:

```
$ vol wintree
...
Untitled - Notepad (visible) notepad.exe:2740 Notepad
..#50188  notepad.exe:2740 6.0.7601.17514!msctls_statusbar32
..#501ca (visible) notepad.exe:2740 6.0.7601.17514!Edit
.Default IME  notepad.exe:2740 IME
.MSCTFIME UI  notepad.exe:2740 MSCTFIME UI

```

Maybe "edit" controls are what's used to enter text?

I spent a while trying to get the contents of the controls, then I wondered whether there was some memory not being dumped earlier, but no luck after an hour or so.

I looked through the list of commands (in the README, not the wiki) and noticed the `editbox` command:

```
 vol editbox
Volatility Foundation Volatility Framework 2.6
******************************
Wnd Context       : 1\WinSta0\Default
Process ID        : 2740
ImageFileName     : notepad.exe
IsWow64           : No
atom_class        : 6.0.7601.17514!Edit
value-of WndExtra : 0x350490
nChars            : 33
selStart          : 33
selEnd            : 33
isPwdControl      : False
undoPos           : 31
undoLen           : 3
address-of undoBuf: 0x354740
undoBuf           : qay
-------------------------
flag:noting_notes_in_a_noting_way
```

That's a bit annoying.  I would like to know how to get this using more generic commands, but I don't know anything about Windows user interfaces and there would be plenty to learn there first.  This does make sense that an older application like notepad would use the control itself for storing its data, so it wouldn't appear in the memory space.


