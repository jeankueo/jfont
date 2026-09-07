# Prerequisite
- **perl**, **jq** (usually preinstalled in mac already)
```sh
# install and check
perl --version
jq --version
```
- install [magick](https://github.com/ImageMagick/ImageMagick) 
    - for png processing (cropping, convert to pbm)
    - [install from source](https://imagemagick.org/script/install-source.php#gsc.tab=0)
```sh
# install and check
git clone --depth 1 --branch [latest_release_tag] https://github.com/ImageMagick/ImageMagick.git ImageMagick-7.1.2
cd ImageMagick-7.1.2
./configure
make
sudo make install
magick --version
```
- install [potrace](https://potrace.sourceforge.net/)
    - for pbm to svg conversion
    - [install from source](https://potrace.sourceforge.net/INSTALL) or from brew
```sh
# install and check
brew install potrace
potrace --version
```
- install [fontforge](https://fontforge.org/en-US/) GUI
    - for finetuning
- install [fontforge](https://fontforge.org/en-US/) CLI
    - for batch .svg importing and .ttf generation
    - install from brew
```sh
# install and check
brew install fontforge
fontforge --version
```
- add following command to your .bashrc or "~/.oh-my-zsh/oh-my-zsh.sh"
```sh
# install and check
alias font=<path_to>/font.sh
font --version
```

# Usage of the Script
```sh
font v1.1.0  —  typeface builder & assignment sheet generator

USAGE
  font [-v] <command> [subcommand] [options]

WORKFLOW
  1. assignment  Generate practice sheets → students write characters
  2. typeface    Scan handwritten PNGs → build TTF font
  3. publish     Install TTF into the system font directory

font assignment [subcommand] [options]
  (no subcommand)       Pipeline: [reset?] → content → png
    -text <file/folder>     .txt source; default: ASSIGN_FONT_TEXT_DIR_DEFAULT="./text"
    -handout <folder>       Output folder; default: ASSIGN_FONT_HANDOUT_DIR_DEFAULT="./handout"
  content [options]     Append lessons to content.json (creates if absent)
    -text <file/folder>     File: that lesson · Folder: all, alphabetical
    -handout <folder>       Override output folder
  png [options]         Generate practice-sheet PNGs into handout folder
    -text <file/folder>     Filter lessons; omit to generate all
    -handout <folder>       Override output folder
  reset [options]       -handout <folder>: clear folder · -handout <file>: delete its PNGs
                        No -handout: clear the default handout folder

font typeface [subcommand] [options]
  (no subcommand)       Full pipeline: char-2-uni → png-crop → png-2-pbm → pbm-2-svg → svg-import → generate → cleanup
    -handin <file/folder>   Source PNGs; default: TYPEFACE_HANDIN_DIR_DEFAULT="./handin"
    -font-name <name>       Base name for .sfd and .ttf; default: TYPEFACE_FONT_NAME_DEFAULT="myfont"
    -font-dir <folder>      Output for .sfd/.ttf and temp/; default: TYPEFACE_FONT_DIR_DEFAULT="./font"
  char-2-uni [options]  .png filename → Unicode JSON
  png-crop [options]    Crop handin PNGs → per-glyph 200×200 PNGs
  png-2-pbm             PNG → PBM bitmaps
  pbm-2-svg             PBM → SVG outlines
  svg-import [options]  SVG → FontForge .sfd
  generate [options]    .sfd → .ttf
  cleanup               Delete font-dir/temp/

font publish <subcommand> [options]
  mac [options]        Install TTF into ~/Library/Fonts (macOS user font library)
    -font-name <name>       Font to publish; default: TYPEFACE_FONT_NAME_DEFAULT="myfont"
    -font-dir <folder>      Folder containing the .ttf; default: TYPEFACE_FONT_DIR_DEFAULT="./font"
    -dest <folder>          Destination directory; default: ~/Library/Fonts
  html [options]       Generate HTML files from .txt sources, rendered in the built font
    -text <file/folder>     Source .txt; default: ASSIGN_FONT_TEXT_DIR_DEFAULT="./text"
    -target <folder>        Output folder; default: PUBLISH_TARGET_DIR_DEFAULT="./html"
    -font-name <name>       Font to embed; default: TYPEFACE_FONT_NAME_DEFAULT="myfont"
    -font-dir <folder>      Folder containing the .ttf; default: TYPEFACE_FONT_DIR_DEFAULT="./font"
```