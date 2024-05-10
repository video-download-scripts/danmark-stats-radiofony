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
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# First we ensure to run this script as root

# shellcheck disable=SC2050
# shellcheck disable=SC2046
if [ $(id -u) -ne 0 ]; then
    echo Please run this script as root or using sudo!
    exit
fi

# Vars
USER="$(logname)" # http://support.matrix.lan/articles/REM-A-177
HOME="/home/${USER}"

echo "$USER"

# Determine if this OS is Debian or Redhat based. This is required to now
# if we should be using apt-get or yum to install deps.
# For now we only support Debian based systems (dpkg|apt).

sudo apt-get install -y curl tar python3.11

# Make $HOME/bin/ directory to run local binaries

mkdir -p "$HOME/bin"

# set PATH so it includes user's private bin if it exists before default PATH
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi

# Download yt-dlp + yt-dlp ffmpeg variant to download encrypted contents from
# Danmarks Radio

cd "$HOME/bin" || exit

# Download yt-dlp and set executive bit
curl --request GET -sL \
    --url 'https://github.com/yt-dlp/yt-dlp/releases/download/2024.04.09/yt-dlp' \
    --output "$HOME/bin/yt-dlp"
sudo chmod +x "$HOME/bin/yt-dlp"

# Download yt-dlp's compiled ffmpeg
curl --request GET -sL \
    --url 'https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz' \
    --output "$HOME/bin/ffmpeg.tar.xz"
# wget "https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz"
tar -xvf ffmpeg.tar.xz --directory "$HOME/bin/ffmpeg"

# Move the ffmpeg executables to the root of $HOME/bin
mv ffmpeg/bin/* "$HOME/bin"

# Delete no longer needed folder files
rm -fr ffmpeg ffmpeg.tar.xz
