# Ultrawide with nvidia linux

## Problem 1

Due to nvidias lack of support for Display Stream Compression (DSC) on my hardware I can not use 240Hz with my Samsung G9 Neo with full resolution.

## Solution 1

The solution is to reduce the resolution to 3840x1080@240hz.

You can do this in normal display settings, just remember to lower the resolution if you can not see 240hz as an option.

Or you can run nvidia-settings command, more on this in **Solution 2**

```bash
$ nvidia-settings --assign CurrentMetaMode="DPY-1: 3840x1080_240 +0+0 {ViewPortIn=3840x1080, ViewPortOut=3840x1080+0+0}"
```



## Problem 2

However in Counter-Strike:Global Offensive  (csgo) the support for ultrawide is quite... meh, and the image contorts more than what is playable.

I am used to playing with a resolution from a 4:3 aspect ratio, streched out to a 16:9 screen, but that is just preference.

When playing a 16:9 resolution streched out to a 32:9 screen, things become too much, even for people who like to play streched.

## Solution 2

I gathered up some nvidia commands to help make the switch quick and easy, tips: I made them into aliases for myself for quick and easy access.

### View current mode

```bash
$ nvidia-settings -q CurrentMetaMode

  Attribute 'CurrentMetaMode' (dsk01:0.0): id=51, switchable=no, source=nv-control :: DPY-1: 5120x1440_120 @5120x1440 +0+0 {ViewPortIn=5120x1440, ViewPortOut=5120x1440+0+0}
```

**DPY-1**: *my output device, I believe it stands for Display Port, what the Y stands for I don't know.*

### Set display back to normal mode

*Remember to disable "game mode" on the monitor, or how you like to configure it, to go from 240hz back to 120hz.*

```bash
$ nvidia-settings --assign CurrentMetaMode="DPY-1: 5120x1440_120 +0+0 {ViewPortIn=5120x1440, ViewPortOut=5120x1440+0+0}"
```

### Set 1080p

This will leave black bars at the edge of your screen

*Remember to start "game mode" on the monitor, or how you like to configure it, to enable 240hz.*

```bash
$ nvidia-settings --assign CurrentMetaMode="DPY-1: 3840x1080_240 {ViewPortIn=1920x1080, ViewPortOut=1920x1080+960+0}"
```

### Set 1080p streched

This will leave black bars at the edge of your screen and strech out the image to make the 16:9 image on ultrawide as streched as 4:3 looked on a normal 16:9 monitor.

*Remember to start "game mode" on the monitor, or how you like to configure it, to enable 240hz.*

```bash
$ nvidia-settings --assign CurrentMetaMode="DPY-1: 3840x1080_240 {ViewPortIn=2560x1080, ViewPortOut=2560x1080+640+0}"
```

## KDE Plasma panels and widgets

If running plasma like me you might notice some panels etc are not where they should be after running a command that changes the display.

I just restart plasma so it can settle back in on its own:

```bash
$ kquitapp5 plasmashell & sleep 5; killall -9 plasmashell; kstart5 plasmashell
```



