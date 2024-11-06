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

# Make sure PATH is present as not all distros have this by default
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Variables
ffmpegPath="$HOME/yt-dlp/ffmpeg"
downloadDir="$HOME/Videos"

title() {
    # Extracting filename from info.info.json
    yt-dlp "${line}" --no-download --write-info-json --ignore-config -o "info.%(ext)s"

    jtitle="$(jq -r .title info.info.json)"
    jseason="$(jq -r .season_number info.info.json)"
    jepisode="$(jq -r .episode_number info.info.json)"

    # todo: We can not combine the series and episodes variables into one
    #  sentence... for now. We need to figure out how
    if [ "$jepisode" != null ] && [ "$jseason" != null ]; then
        filename="${jtitle} - S$jseason E$jepisode"
    elif [ "$jepisode" == null ] && [ "$jseason" != null ]; then
        filename="${jtitle} - S$jseason"
    elif [ "$jepisode" == null ] && [ "$jseason" == null ]; then
        # We assume this is a movie and not a series
        filename="${jtitle}"
    fi

    find . -maxdepth 1 -mindepth 1 -type f -iname "info.*" -delete
}

# set PATH to includes user's private bin, if it exists, and before
# default PATH
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi

# Help text
# TODO: Update the help text
# TODO: write options for uri and file as direct source

#Help() {
#    # Display Help
#    echo "Add description of the script functions here."
#    echo
#    echo "Syntax: scriptTemplate [-g|h|v|V]"
#    echo "options:"
#    echo "g     Print the GPL license notification."
#    echo "h     Print this Help."
#    echo "v     Verbose mode."
#    echo "V     Print software version and exit."
#    echo
#}
#
## Process the input options. Add options as needed.
## Get the options
#while getopts ":h" option; do
#    case $option in
#    h) # display Help
#        Help
#        exit
#        ;;
#    \?) # incorrect option
#        echo "Error: Invalid option"
#        exit
#        ;;
#    esac
#done

# get file with urls
read -erp "Location of URI list: " URI

if [ -f "${URI}" ]; then
    grep -vE '^($|#)' "${URI}" >"${URI}.tmp"
    sourceUri="${URI}.tmp"
fi

if [ -r "${sourceUri}" ]; then
    cd "$downloadDir/" || exit

    while read -r line; do
        # shellcheck disable=SC2086
        # filename="$(yt-dlp --ignore-config --restrict-filenames --print '%(title)s - S%(season_number)02dE%(episode_number)02d' ${line})"
        title

        # Download the audio and convert to aac
        yt-dlp -f "ba*" \
            --downloader ffmpeg \
            --ffmpeg-location "${ffmpegPath}" \
            --abort-on-unavailable-fragments \
            --no-keep-fragments \
            --extract-audio \
            --audio-format aac \
            --audio-quality 0 \
            -P "$downloadDir/" \
            --abort-on-error \
            --ignore-config \
            --restrict-filenames \
            -o "$filename.%(ext)s" "${line}"
        # -o "%(title)s - S%(season_number)02dE%(episode_number)02d.%(ext)s" "${line}"

        # Download the video, subtitles and thumbnail
        yt-dlp -f "bv*" \
            --downloader ffmpeg \
            --ffmpeg-location "${ffmpegPath}" \
            --abort-on-unavailable-fragments \
            --no-keep-fragments \
            --no-simulate \
            --write-subs \
            --no-embed-subs \
            --convert-subs srt \
            --sub-langs da_foreign \
            --write-thumbnail \
            --convert-thumbnails jpg \
            -4 -c -P "$downloadDir/" \
            --abort-on-error \
            --ignore-config \
            --restrict-filenames \
            -o "$filename.%(ext)s" "${line}"
        # -o "%(title)s - S%(season_number)02dE%(episode_number)02d.%(ext)s" "${line}"

        # Merge the files into a mkv container
        mkvmerge -o "$downloadDir/${filename}".mkv \
            --language 0:eng "$downloadDir/${filename}.mp4" \
            --language 0:eng "$downloadDir/${filename}.m4a" \
            --language 0:dan "$downloadDir/${filename}.da_foreign.srt" \
            --attach-file "$downloadDir/${filename}.jpg" \
            --attachment-name "cover.jpg"

        # Copy cover to jellyfin fanart
        mv "$downloadDir/${filename}.jpg" "$downloadDir/${filename}-thumb.jpg"

        # Cleanup the source files
        rm -f "$downloadDir/${filename}".{m4a,mp4,*.srt}

    done <"${sourceUri}"
else
    echo "Could not locate given file"
    exit
fi

# Cleanup the temp source file
rm -f "${sourceUri}"
