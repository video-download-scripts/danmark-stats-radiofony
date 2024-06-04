# Danmarks Radio video download helper

[![goal](https://reck.dk/fileproxy/?name=sp_goal_spirillen)](https://liberapay.com/spirillen/donate)
[![liberapay](https://reck.dk/fileproxy/?name=sp_receives_spirillen)](https://liberapay.com/spirillen/donate)

This project aims tp build and maintain installation and download bash scripts,
to help you download videos from [DR][DR]

This project is inspired by [@0HAg0][0HAg0] in this [comment][comment]

<!-- TOC -->

* [Danmarks Radio video download helper](#danmarks-radio-video-download-helper)
    * [Requirements](#requirements)
    * [Usage](#usage)
    * [Sources](#sources)
        * [Series](#series)
        * [Films](#films)
        * [Documentary](#documentary)
        * [Humor](#humor)
        * [Other](#other)
    * [Execute](#execute)

<!-- TOC -->

## Requirements

To use this script you need to run on a Linux distribution, that runs with bash.

## Usage

This script should be able to figure out whether you are downloading a series
or just a film, and then name the output file accordingly.

Create a file that contains the URIs of series or film you want to download
from `https://www.dr.dk`

## Sources

### Series

You can find the alphabetical list of active series
at `https://www.dr.dk/drtv/kategorier/fiktionsserier_a-aa`

### Films

You can find the alphabetical list of active Films
at `https://www.dr.dk/drtv/kategorier/film_a_aa`

### Documentary

You can find the alphabetical list of active documentary
at `https://www.dr.dk/drtv/kategorier/dokumentar_a-aa`

### Humor

You can find the alphabetical list of active humor
at `https://www.dr.dk/drtv/kategorier/humor-satire_a_aa`

### Other

For other type of contents, please use the default tv index
at `https://www.dr.dk/drtv/`

## Execute

Now run `src/dr.sh` and feed it with the full path to the file you created
in the first step wut URI's to be downloaded


<!-- LINKS -->

[DR]: https://www.dr.dk/drtv/kategorier/fiktionsserier_a-aa

[0HAg0]: https://github.com/0HAg0

[comment]: https://github.com/yt-dlp/yt-dlp/issues/3810#issuecomment-2094925139
<!-- LINKS -->
