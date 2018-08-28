#!/bin/bash

# Change the format if you wish, its only used to apend the date to the foler name. (only tested without spaces, but SHOULD work either way)
date=$(date +%Y-%m-%d_%H-%M-%S)

# Nvidia SDK filename pattern (NEEDS to be compatible with 'find -iname'
nvidia_sdk_package_name="Video_Codec_SDK_*.zip" # Seems nvidia likes to break everything by chainging names for no reason, this format seems to start at version 7
# nvidia_sdk_package_name="nvidia_video_sdk_*.zip" # Older format? Was used on the version 6 branch

# Directories
wrkdir="$(pwd)/files"
nvidiadir="$wrkdir/nvidia"
sourcedir="$wrkdir/ffmpeg"

# Indicator that this script is talking to you
prefix="\033[92m[FFMpeg Nvenc]\e[0m"

# This NEEDS to be a uniq string in the world of APT Packages, otherwise something might get deleted from your system.
nvenc_postfix="NvencPenetalAutoScript"

#################################################
# Script, only edit if you know what you are doing
#################################################
clear

echo -e "\n\n"
echo "#############################################################################"
echo "#                                                                           #"
echo "#                      Welcome to ugly auto!                                #"
echo "#                                                                           #"
echo "#                                                                           #"
echo "#          Lets see if we can get some NVENC up in here....                 #"
echo "#                                                                           #"
echo "#                                                                           #"
echo "#                                                          PS: I need sudo  #"
echo "#                                                                           #"
echo "#############################################################################"
echo -e "\n\n\n\n"

if [[ $EUID -eq 0 ]]; then
  echo -e "$prefix Do not run this script as root."
  echo -e "$prefix Dude you got it from some random site. Think, then do!"
  echo
  exit 1
fi

# Just asking for sudo access now because why not.
sudo echo "Nvidia makes using NVENC way harder than it has to be in linux" 2>&1 >/dev/null 

chkexit (){
  if [[ $1 -ne 0 ]]; then
    echo "Something fucked up"
    exit 1
  fi
}

mkdir -p "$wrkdir" "$nvidiadir" "$sourcedir"
chkexit $?
cd "$wrkdir"

if [ -e packages.installed.from.build-dep ]; then
  echo -e "$prefix Found uncleaned list of packages installed during a previous run at: \n$(realpath packages.installed.from.build-dep)\n"
  echo -e "$prefix Remove the list if you want to keep the packages or uninstall packages with these commands:"
  echo
  echo "sudo apt-mark auto $(cat packages.installed.from.build-dep | tr '\n' ' ')"
  echo
  echo "sudo apt-get autoremove && rm $(realpath packages.installed.from.build-dep)"
  echo
  exit 1
fi

#echo -e "$prefix Removing previously installed '$nvenc_postfix' packages, if you want to keep them press [Ctrl-C] now."
#sudo apt-get remove $(apt list --installed | grep "$nvenc_postfix" | cut -d"/" -f1)
#chkexit $?
#sudo apt-get autoremove -y
#chkexit $?

echo -e "\n\n"
echo -e "$prefix Download 'NVIDIA Video Codec SDK' and put it in the current working directory [$nvidiadir]"
echo -e "$prefix You might have to register as a developer for some fucking reason they don't want features on linux so hoops be jumped."
echo -e "$prefix Download Page: https://developer.nvidia.com/nvidia-video-codec-sdk#agreement"
echo "Press [Enter] to continue."
read

nvidia_sdk_zip=$(find "$nvidiadir" -maxdepth 1 -iname "$nvidia_sdk_package_name" | tail -n1)
nvidia_sdk_folder="${nvidia_sdk_zip/.zip/}"

echo -e "$prefix Unzipping $nvidia_sdk_zip"
unzip "$nvidia_sdk_zip" -d "$nvidiadir"
chkexit $?

echo -e "$prefix Finding files to copy over to system"
nvidia_include_files=$(ls $nvidia_sdk_folder/Samples/common/inc/*.h | xargs -n1 basename)

echo -e "$prefix Copying files from '$nvidia_sdk_folder/Samples/common/inc' to '/usr/local/include'"
for file in $nvidia_include_files; do
  sudo cp -i "$nvidia_sdk_folder/Samples/common/inc/$file" "/usr/local/include"
  chkexit $?
done

echo -e "$prefix Updating APT database"
sudo apt-get update

echo -e "$prefix This step requires sources repositories to be enabled."
echo -e "$prefix For help see: https://help.ubuntu.com/community/Repositories/Ubuntu or https://help.ubuntu.com/community/Repositories/CommandLine"
echo
echo -e "$prefix Found FFMpeg in these repositories, enable sources for them:"
apt-cache madison ffmpeg

echo -e "$prefix Installing build dependencies for ffmpeg"
echo -e "$prefix   Saving currently installed packages to ffmpeg.apt.pre"
apt-mark showmanual > ffmpeg.apt.pre
chkexit $?

echo -e "$prefix Starting install of dependencies, this might take a moment."
sudo apt-get build-dep -y ffmpeg
chkexit $?

echo -e "$prefix Starting install of required dev packages"
sudo apt-get install -y devscripts
chkexit $?

echo -e "$prefix Saving currently installed packages to ffmpeg.apt.post"
apt-mark showmanual > ffmpeg.apt.post
chkexit $?

cat ffmpeg.apt.pre ffmpeg.apt.post | sort | uniq -u > "packages.installed.from.build-dep"
rm ffmpeg.apt.pre ffmpeg.apt.post
chkexit $?

echo -e "$prefix Marking packaged installed as build dependencies as auto for autoremove-ability"
if [[ "$(cat packages.installed.from.build-dep | wc -l)" -gt 0 ]]; then
  sudo apt-mark auto $(cat packages.installed.from.build-dep)
  chkexit $?
fi

echo -e "$prefix Removing list of installed build-dep packages"
rm packages.installed.from.build-dep
chkexit $?

cd "$sourcedir"
  echo -e "\n\n"
  echo -e "$prefix Attempting to download source for ffmpeg"
  apt-get source ffmpeg
  chkexit $?

  echo -e "$prefix Changing directory to latest ffmpeg version source dir"
  ffmpeg_source_folder="$(find "$sourcedir" -maxdepth 1 -type d -iname "ffmpeg*" | tail -n1)"

  cd "$ffmpeg_source_folder"
    echo -e "$prefix Adding '--enable-nonfree' and '--enable-nvenc' to 'CONFIG' in '$(pwd)/debian/rules'"
    sed -i 's/CONFIG :=/CONFIG := --enable-nonfree --enable-nvenc/' debian/rules
    chkexit $?

    echo -e "$prefix Adding '$nvenc_postfix' to package version number"
    sed -i "1,1s/\(ffmpeg (.*\))/\1-${nvenc_postfix})/" debian/changelog
    chkexit $?

    echo -e "\n\n\n"
    echo -e "$prefix Will start package build in 30 seconds, this will take a long time."
    sleep 30
    debuild -us -uc -b
    chkexit $?

cd "$wrkdir"
echo -e "\n\n\n"

echo -e "$prefix Deleteing files that were copied into '/usr/local/include'"
for file in $nvidia_include_files; do
  echo -e "  File: $file"
  sudo rm -- "/usr/local/include/$file"
  chkexit $?
done

#echo -e "$prefix Delete unneeded packages."
#sudo apt-get autoremove -y
#chkexit $?

echo -e "$prefix Deleting ffmpeg sources"
rm -rf "$ffmpeg_source_folder"
chkexit $?

echo -e "$prefix Deleting unziped nvidia files"
rm -r "$nvidiadir"
chkexit $?

echo -e "$prefix Moving files into versioned folder"
versiondir="$wrkdir/$(basename "$ffmpeg_source_folder")_compiled-$date"
mv "$sourcedir" "$versiondir"

echo -e "$prefix Moving unwanted package files to disabled folder"
mkdir "$versiondir/disabled"
chkexit $?
find "$versiondir" -iname "libavcodec-ffmpeg56_*.deb" -execdir mv "{}" "$versiondir/disabled/" \;
chkexit $?

echo -e "$prefix Installing built packages"
sudo dpkg -i "$versiondir/*.deb"
sudo apt-get -f install -y
sudo dpkg -i "$versiondir/*.deb" # Conflict problems for libavcodec-ffmpeg-extra56 if libavcodec-ffmpeg56 were already installed and I can't be bothered to find the propper way to deal.
chkexit $?

echo -e "$prefix Marking packages with hold so they dont get overwritten when new versions come to the repos."
sudo apt-mark hold $(ls $versiondir | grep .deb | cut -d_ -f1)
chkexit $?

echo 
echo -e "#############################################################################"
echo -e "#"
echo -e "#"
echo -e "#   To see the new NVENC packages installed on the system just run:"
echo -e "#     dpkg -l | grep $nvenc_postfix"
echo -e "#"
echo -e "#"
echo -e "#   To reinstall the packages run:"
echo -e "#     dpkg -i $versiondir/*.deb"
echo -e "#"
echo -e "#"
echo -e "#   To uninstall the packages run:"
echo -e "#     sudo apt-get remove \$(apt list -i | grep $nvenc_postfix | cut -d/ -f1)"
echo -e "#"
echo -e "#   The packages are currently marked as hold,"
echo -e "#   this means they will not be updated by the distro."
echo -e "#   To compile and update the packages when a new version lands in distro,"
echo -e "#   just run this script again."
echo -e "#"
echo -e "#"
echo -e "#"
echo -e "#   PS some packages are left from the compiling of ffmpeg, if you are done you can run:"
echo -e "#     sudo apt-get autoremove"
echo -e "#"
echo -e "#############################################################################"
echo
