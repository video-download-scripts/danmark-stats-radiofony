#!/usr/bin/env bash
#
# Copyright (c) 2024.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# This script is to install and update dependencies for the rest of the
# script to function properly

# Make sure PATH is present as not all distros have this by default
PATH="$HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

#set -e
#set -x

# First we ensure to run this script as root

# shellcheck disable=SC2050
# shellcheck disable=SC2046
if [ "$(whoami)" != "root" ]; then
    echo "Please run this script as root or using sudo!"
    exit 1
fi

# Variables
ffmpegVersion="ffmpeg-master-latest-linux64-gpl" # DO NOT ADD EXTENSION
USER="$(logname)"                                # http://support.matrix.lan/articles/REM-A-177
HOME="/home/${USER}"
workDir="$HOME/yt-dlp"
GIT_DIR="$(git rev-parse --show-toplevel)"

# Determine if this OS is Debian or Redhat based. This is required to now
# if we should be using apt-get or yum to install deps.
# For now, we only support Debian and BSD based OS (dpkg|apt-get).

# Setup mkvToolNix repo
# First we import the gpg keyfile
echo "Import mkvToolNix gpg keyfile"
if [ ! -f /usr/share/keyrings/gpg-pub-moritzbunkus.gpg ]; then
    curl --request GET -sL \
        --url 'https://mkvtoolnix.download/gpg-pub-moritzbunkus.gpg' \
        --output '/usr/share/keyrings/gpg-pub-moritzbunkus.gpg'
fi

# determine the OS and Version
echo "Find the OS and Release"
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$ID
    codeName=$VERSION_CODENAME
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    codeName=$(lsb_release -sc)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    codeName=$DISTRIB_CODENAME
fi

# Ensure OS name is lowercased
OS="${OS,,}"
codeName="${codeName,,}"

# Setup the apt.source
echo "Setup the apt.source"
if [ "$OS" == "ubuntu" ]; then
    echo "OS: $OS, CodeName: $codeName"
    if [ ! -f /etc/apt/sources.list.d/mkvtoolnix.download.list ]; then
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/gpg-pub-moritzbunkus.gpg] https://mkvtoolnix.download/ubuntu/ $codeName main" | tee -a /etc/apt/sources.list.d/mkvtoolnix.download.list >/dev/null
        echo "deb-src [arch=amd64 signed-by=/usr/share/keyrings/gpg-pub-moritzbunkus.gpg] https://mkvtoolnix.download/ubuntu/ $codeName main" | tee -a /etc/apt/sources.list.d/mkvtoolnix.download.list >/dev/null
    else
        echo "apt-get source already up to date"
    fi

elif [ "$OS" == debian ]; then
    echo "OS: $OS, CodeName: $codeName"
    if [ ! -f /etc/apt/sources.list.d/mkvtoolnix.download.list ]; then
        echo "deb [signed-by=/usr/share/keyrings/gpg-pub-moritzbunkus.gpg] https://mkvtoolnix.download/debian/ $codeName main" | tee -a /etc/apt/sources.list.d/mkvtoolnix.download.list >/dev/null
        echo "deb-src [signed-by=/usr/share/keyrings/gpg-pub-moritzbunkus.gpg] https://mkvtoolnix.download/debian/ $codeName main" | tee -a /etc/apt/sources.list.d/mkvtoolnix.download.list >/dev/null
    else
        echo "apt-get source already up to date"
    fi
fi

# Update and install deps
export DEBIAN_FRONTEND=noninteractive

echo "Installing apt-fast"
bash -c "$(curl -sSL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)"

echo "Updating the OS"
apt-fast update -yq

echo "Installing dependencies"
apt-fast install -yq curl tar python3.11 python3-pip python3-pip-whl mkvtoolnix
apt autoremove -yq

# Install mypdns python module to boost download counter
echo "(un)Install mypdns python module to boost download counter"
if [ "$OS" == "ubuntu" ]; then
    sudo -u "$USER" python3.11 -m pip install --user -r "$GIT_DIR/requirements.txt"
    sudo -u "$USER" python3.11 -m pip uninstall mypdns --yes
elif [ "$OS" == debian ] || [ "$OS" == Debian ]; then
    sudo -u "$USER" python3.11 -m pip install --user -r "$GIT_DIR/requirements.txt" --break-system-packages
    sudo -u "$USER" python3.11 -m pip uninstall mypdns --yes --break-system-packages
fi

# Make $HOME/bin/ directory to run local binaries

mkdir -p "${workDir}/"

# set PATH to includes user's private bin, if it exists, and before
# default PATH
if [ -d "${workDir}" ]; then
    PATH="${workDir}:$PATH"
fi

# Download yt-dlp + yt-dlp ffmpeg variant to download encrypted contents from
# Danmarks Radio

cd "${workDir}/" || exit

# Download yt-dlp and set executive bit
echo "Download yt-dlp and set executive bit"
curl --request GET -sSL \
    --url 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp' \
    --output "$HOME/bin/yt-dlp"
sudo chmod a+x "${workDir}"

cd "${workDir}/" || exit

# Download yt-dlp's compiled ffmpeg
echo "Downloading ffmpeg"
curl --request GET -sSL \
    --url "https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/$ffmpegVersion.tar.xz" \
    --output "$ffmpegVersion.tar.xz"

echo "Unpacking ffmpeg"
tar -xvf $ffmpegVersion.tar.xz -C "${workDir}/"

# set user as owner of ~/bin/ and files within
echo "Changing ownership recursively on ~/bin"
chown -R "$USER:$USER" "${workDir}/"

# Used for debugging
#cd "${workDir}/" || exit
#echo ""
#echo "${workDir}/"
#echo ""
#echo "current dir: ($PWD)"
#echo "You should be in: ${workDir}/"
#echo ""

# Move the ffmpeg executables to the root of ${workDir}
mv "$ffmpegVersion/bin/"* "${workDir}/" # Asterix fails to drink his potion if put inside the ""

#echo "list files in ${workDir}/"
#ls -lha "${workDir}/"

# Delete no longer needed folder files
# shellcheck disable=SC2115
rm -fr "${workDir}/$ffmpegVersion.tar.xz" "${workDir}/$ffmpegVersion"
