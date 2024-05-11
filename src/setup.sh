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
if [ "$(whoami)" != "root" ]; then
    echo "Please run this script as root or using sudo!"
    exit 1
fi

# Variables
USER="$(logname)" # http://support.matrix.lan/articles/REM-A-177
HOME="/home/${USER}"
GIT_DIR="$(git rev-parse --show-toplevel)"

# Determine if this OS is Debian or Redhat based. This is required to now
# if we should be using apt-get or yum to install deps.
# For now, we only support Debian and BSD based OS (dpkg|apt-get).

# Setup mkvToolNix repo
# First we import the gpg keyfile
if [ ! -f /usr/share/keyrings/gpg-pub-moritzbunkus.gpg ]; then
    curl --request GET -sL \
        --url 'https://mkvtoolnix.download/gpg-pub-moritzbunkus.gpg' \
        --output '/usr/share/keyrings/gpg-pub-moritzbunkus.gpg'
fi

# determine the OS and Version
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
if [ "$OS" == "ubuntu" ]; then
    echo -n "deb [arch=amd64 signed-by=/usr/share/keyrings/gpg-pub-moritzbunkus.gpg] https://mkvtoolnix.download/ubuntu/ $codeName main" | tee >/etc/apt/sources.list.d/mkvtoolnix.download.list >/dev/null 2>&1
    echo -n "deb-src [arch=amd64 signed-by=/usr/share/keyrings/gpg-pub-moritzbunkus.gpg] https://mkvtoolnix.download/ubuntu/ $codeName main" | tee >>/etc/apt/sources.list.d/mkvtoolnix.download.list >/dev/null 2>&1
elif [ "$OS" == debian ]; then
    echo -n "deb [signed-by=/usr/share/keyrings/gpg-pub-moritzbunkus.gpg] https://mkvtoolnix.download/debian/ $codeName main" | tee >/etc/apt/sources.list.d/mkvtoolnix.download.list >/dev/null 2>&1
    echo -n "deb-src [signed-by=/usr/share/keyrings/gpg-pub-moritzbunkus.gpg] https://mkvtoolnix.download/debian/ $codeName main" | tee >>/etc/apt/sources.list.d/mkvtoolnix.download.list >/dev/null 2>&1
fi

# Update and install deps
export DEBIAN_FRONTEND=noninteractive
bash -c "$(curl -sL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)"

apt-fast update -yq
apt-fast install -yq curl tar python3.11 python3-pip python3-pip-whl mkvtoolnix

# Install mypdns python module to boost download counter
if [ "$OS" == "ubuntu" ]; then
    python3.11 -m pip install --user -r "$GIT_DIR/requirements.txt"
fi

# Make $HOME/bin/ directory to run local binaries

mkdir -p "$HOME/bin/ffmpeg"

# set PATH to includes user's private bin, if it exists, and before
# default PATH
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi

# Download yt-dlp + yt-dlp ffmpeg variant to download encrypted contents from
# Danmarks Radio

cd "$HOME/bin/" || exit

# Download yt-dlp and set executive bit
curl --request GET -sSL \
    --url 'https://github.com/yt-dlp/yt-dlp/releases/download/2024.04.09/yt-dlp' \
    --output "$HOME/bin/yt-dlp"
sudo chmod a+x "$HOME/bin/yt-dlp"

cd "$HOME/bin/" || exit

# Download yt-dlp's compiled ffmpeg
curl --request GET -sSL \
    --url 'https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz' \
    --output "ffmpeg-master-latest-linux64-gpl.tar.xz"
tar -xvf ffmpeg-master-latest-linux64-gpl.tar.xz -C "$HOME/bin/ffmpeg"

# set user as owner of ~/bin/ and files within
chown -R "$USER:$USER" "$HOME/bin/"

# Move the ffmpeg executables to the root of $HOME/bin
echo
echo "$HOME/bin/"
echo
mv "$HOME/bin/ffmpeg-master-latest-linux64-gpl/bin/*" "$HOME/bin/"

# Delete no longer needed folder files
rm -fr ./ffmpeg/ ./ffmpeg-master-latest-linux64-gpl.tar.xz ./ffmpeg-master-latest-linux64-gpl
