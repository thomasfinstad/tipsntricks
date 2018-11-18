# ffmpeg-nvenc-ubuntu
ffmpeg with nvenc support for ubuntu 16.04

This script is only tested with ubuntu 16.04.
It will help you compile and install ffmpeg with nvenc support.
Just run the script and follow the directions.

# Uninstall
If you did not modify the script postfix it should be "NvencPenetalAutoScript", try this:
`sudo apt-get remove "$(apt list -i | grep "NvencPenetalAutoScript" | cut -d/ -f1)"`
And if you do not want to force a remove unless there is a new version:
`sudo apt-mark unhold "$(apt list -i | grep "NvencPenetalAutoScript" | cut -d/ -f1)"`
