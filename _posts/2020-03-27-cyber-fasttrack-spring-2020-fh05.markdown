---
layout: post
title: Cyber FastTrack 2020 Forensics HF05 challenge
slug: cyber-fasttrack-spring-2020-fh05
---

This is challenge HF05 from the Cyber FastTrack Spring 2020 challenges.

The challenge:

> The attacker created a shared folder on the victims machine. Find this folder and give us the absolute path of the directory, including drive letter.
>
> files.allyourbases.co/fi02.zip

These are the files:

```
$ sha1sum fi02.zip memory-image.vmem 
78c544a8e5cbb9764fd009760a7e4e3ae035db6a  fi02.zip
7ea854fc529c7517dedbdf0c287a3c4e2a7f3903  memory-image.vmem
```

Volatility is a memory forensics tool which apparently comes with Kali - I've never used any tools like this before, so that will do for startes.

It turns out it *doesn't* come with Kali.  To get volatility working in Kali, I found it easiest to download it from the web site, extract it, and create an alias to it:

```
$ cd /tmp
$ wget 'http://downloads.volatilityfoundation.org/releases/2.6/volatility_2.6_lin64_standalone.zip'
$ unzip volatility_2.6_lin64_standalone.zip 
$ cd volatility_2.6_lin64_standalone/
$ alias vol=/tmp/volatility_2.6_lin64_standalone/volatility_2.6_lin64_standalone 
```

Start by identifying the image:

```
$ vol imageinfo -f memory-image.vmem 
Volatility Foundation Volatility Framework 2.6
INFO    : volatility.debug    : Determining profile based on KDBG search...
          Suggested Profile(s) : Win7SP1x64, Win7SP0x64, Win2008R2SP0x64, Win2008R2SP1x64_23418, Win2008R2SP1x64, Win7SP1x64_23418
```

I'll guess `Win7SP1x64` for starters.  See whether this works:

```
$ vol --profile=Win7SP1x64 pslist -f memory-image.vmem 
Volatility Foundation Volatility Framework 2.6
Offset(V)          Name                    PID   PPID   Thds     Hnds   Sess  Wow64 Start                          Exit                          
------------------ -------------------- ------ ------ ------ -------- ------ ------ ------------------------------ ------------------------------
0xfffffa8000ca1890 System                    4      0     89      480 ------      0 2019-09-05 14:39:08 UTC+0000                                 
0xfffffa8001a5b440 smss.exe                268      4      2       29 ------      0 2019-09-05 14:39:08 UTC+0000                                 
0xfffffa8002cadb30 csrss.exe               368    344      8      402      0      0 2019-09-05 14:39:23 UTC+0000                                 
0xfffffa8002d34b30 wininit.exe             420    344      3       74      0      0 2019-09-05 14:39:23 UTC+0000                                 
```

Typing the --profile and -f is going to get annoying.  These can go in environment files instead:

```
$ export VOLATILITY_PROFILE=Win7SP1x64
$ export VOLATILITY_LOCATION=file:///tmp/memory-image.vmem
$ vol pslist
```

The last command shows that the environment variables are working.

How can I find the share?  Maybe the attacker used a console?

```
$ vol consoles
```

There's some things like IP addresses there, and commands which I guess disable the firewall:

```
c:\Users\Redacted\Desktop\IT Support Software>NetSh Advfirewall set allprofiles state off                                                     
Ok.
```

and the actual version of Windows ([a quick search](https://www.gaijin.at/en/infos/windows-version-numbers) tells us it's Windows 7 service pack 1, so my guess might have been correct):

```
Microsoft Windows [Version 6.1.7601]
Copyright (c) 2009 Microsoft Corporation.  All rights reserved.            
```

but other than that, nothing stands out.

I guess Windows would keep its file shares in the registry.  I used a web search to find out where these are, and tried to find that key:

```
$ vol printkey -K 'System\CurrentcontrolSet\Services\Lanmanserver\Shares'
Volatility Foundation Volatility Framework 2.6
Legend: (S) = Stable   (V) = Volatile

The requested key could not be found in the hive(s) searched
```

That's no good... does that command work at all?  I'll try something from the manual:

```
$ vol printkey -K 'Microsoft\Security Center\Svc'
Volatility Foundation Volatility Framework 2.6
Legend: (S) = Stable   (V) = Volatile

----------------------------
Registry: \SystemRoot\System32\Config\SOFTWARE
Key name: Svc (S)
Last updated: 2019-09-05 14:41:28 UTC+0000

Subkeys:
  (V) Vol

Values:
REG_QWORD     VistaSp1        : (S) 128920218544262440
REG_DWORD     AntiVirusOverride : (S) 0
```

That seems to work.  I notice that there's some `CurrentControlSet` stuff in the share query.  I have a feeling that Windows somehow maps this somewhere else in the registry, [which is correct](https://renenyffenegger.ch/notes/Windows/registry/tree/HKEY_LOCAL_MACHINE/System/CurrentControlSet/index).  Searching for `SYSTEM\ControlSet001` found nothing, but on a hunch I tried just `ControlSet001`:

```
$ vol printkey -K 'ControlSet001'
Volatility Foundation Volatility Framework 2.6
Legend: (S) = Stable   (V) = Volatile

----------------------------
Registry: \REGISTRY\MACHINE\SYSTEM
Key name: ControlSet001 (S)
Last updated: 2019-09-05 21:58:26 UTC+0000

Subkeys:
  (S) Control
  (S) Enum
  (S) Hardware Profiles
  (S) Policies
  (S) services

Values:
```

That's looking more interesting!  Let's see whether that helps:

```
$ vol printkey -K 'Services\LanmanServer\Shares'
Volatility Foundation Volatility Framework 2.6
Legend: (S) = Stable   (V) = Volatile

The requested key could not be found in the hive(s) searched
```

maybe just the end will do?

```
$ vol printkey -K 'Shares'
Volatility Foundation Volatility Framework 2.6
Legend: (S) = Stable   (V) = Volatile

The requested key could not be found in the hive(s) searched
```

I also noticed what `CurrentControlSet` does:

```
$ vol printkey -K 'CurrentControlSet'
Volatility Foundation Volatility Framework 2.6
Legend: (S) = Stable   (V) = Volatile

----------------------------
Registry: \REGISTRY\MACHINE\SYSTEM
Key name: CurrentControlSet (V)
Last updated: 2019-09-05 14:39:01 UTC+0000

Subkeys:

Values:
REG_LINK      SymbolicLinkValue : (V) \Registry\Machine\System\ControlSet001
```

I should have a closer look at the output: ControlSet001 lists a subkey of "services".

```
$ vol printkey -K 'ControlSet001\services'
Volatility Foundation Volatility Framework 2.6
Legend: (S) = Stable   (V) = Volatile

----------------------------
Registry: \REGISTRY\MACHINE\SYSTEM
Key name: services (S)
Last updated: 2019-09-05 14:17:34 UTC+0000

Subkeys:
  (S) .NET CLR Data
  (S) .NET CLR Networking
...
  (S) KtmRm
  (S) LanmanServer
  (S) LanmanWorkstation
  (S) ldap
...
```

I'll keep digging:

```
$ vol printkey -K 'ControlSet001\services\LanmanServer'
Volatility Foundation Volatility Framework 2.6
Legend: (S) = Stable   (V) = Volatile

----------------------------
Registry: \REGISTRY\MACHINE\SYSTEM
Key name: LanmanServer (S)
Last updated: 2009-07-14 04:53:33 UTC+0000

Subkeys:
  (S) Aliases
  (S) AutotunedParameters
  (S) DefaultSecurity
  (S) Linkage
  (S) Parameters
  (S) ShareProviders
  (S) Shares

Values:
REG_SZ        DisplayName     : (S) @%systemroot%\system32\srvsvc.dll,-100
REG_EXPAND_SZ ImagePath       : (S) %SystemRoot%\system32\svchost.exe -k netsvcs
REG_SZ        Description     : (S) @%systemroot%\system32\srvsvc.dll,-101
REG_SZ        ObjectName      : (S) LocalSystem
REG_DWORD     ErrorControl    : (S) 1
REG_DWORD     Start           : (S) 2
REG_DWORD     Type            : (S) 32
REG_MULTI_SZ  DependOnService : (S) ['SamSS', 'Srv', '', '']
REG_DWORD     ServiceSidType  : (S) 1
REG_MULTI_SZ  RequiredPrivileges : (S) ['SeChangeNotifyPrivilege', 'SeImpersonatePrivilege', 'SeAuditPrivilege', 'SeLoadDriverPrivilege', '', '']
REG_BINARY    FailureActions  : (S) 
0x00000000  80 51 01 00 00 00 00 00 00 00 00 00 03 00 00 00   .Q..............
0x00000010  14 00 00 00 01 00 00 00 60 ea 00 00 01 00 00 00   ........`.......
0x00000020  c0 d4 01 00 00 00 00 00 00 00 00 00               ............
```

```
$ vol printkey -K 'ControlSet001\services\LanmanServer\Shares'
Volatility Foundation Volatility Framework 2.6
Legend: (S) = Stable   (V) = Volatile

----------------------------
Registry: \REGISTRY\MACHINE\SYSTEM
Key name: Shares (S)
Last updated: 2019-09-05 15:02:37 UTC+0000

Subkeys:
  (S) Security

Values:
REG_MULTI_SZ  exfil           : (S) ['CSCFlags=0', 'MaxUses=4294967295', 'Path=c:\\recyc1e_bin', 'Permissions=63', 'ShareName=exfil', 'Type=0', '', '']
```

`c:\recycle_bin` is correct!  I'm happy with about half an hour for a beginner, and I didn't hit any dead ends.

