# Purpose
This project aim provide fast assignment creation from source text to hand out for learners. After learners do their exercise on ipad (procreate recommended), they can hand in assignments, then font can be created out of their handins, hence a good pirnt out can be created.

Functions are provided via shell script.

# Usage
USAGE
  font [-v] <command> [subcommand] [options]

WORKFLOW
  1. assignment  Generate practice sheets → students write characters
  2. typeface    Scan handwritten PNGs → build TTF font

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
# How to use 

## Special Comment
- The template is originally chinese orianted which is "米字格". I add later an assistant square for letters and symbols, now it is called "回米字格".
- By my experience using the template, if the font is created almost exact size of the inner square, generating of .SFD file will scale the font by 1.5 times and move right by 250 pixel. The left and right bearing are set to 50px. Then the size is perfect for using.
- Multiple source .png and .txt is supported.