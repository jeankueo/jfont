# Purpose
This project provides a shell script that can generate font file .ttf from source png. The script is created in MACOS, MS users need to adapt all commands to fit windows shell.

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
## Step Description
- create .png file
    - create a canvas size 1400x2200 in procreate
    - import template.png as a layer
    - add a layer and write your font into each 200x200 boxes
    - hide template layer
    - export a png without background and put under /src folder with chosen file name x
- create .txt file
    - type in all characters in .png file in sequence to .txt file
    - use a same name .x and place under /src folder
- for the first time run command "font pipeline"
    - ./output folder is created, under which
        -   /json folder contains a json file with all unicodes from .txt file
        - /png folder contains at most 77 pngs cropped from origin x.png file and all renamed to unicode correspondingly
        - /pbm folder contains at most 77 pbm files grayed from png
        - /svg folder contains at most 77 svg files ready to be imported to font file
    - at root folder x.sfd file is created which is the project file of fontforge
    - in ./output folder x.ttf is created which is a font file ready to be used
- for repeating run
    - clear /src, replace with new .txt and .png
    - delete /output
    - se command "font -name x pipeline", so font edit file will be change accumulately

## Special Comment
- The template is originally chinese orianted. I will add some assistant line for letters and symbols
- According to my daughter' writing habits, my script will automatically do 1.6 scale when importing SVGs into .sfd file
- I usually do not use the generated .ttf directly, because i always do some finetuning in fontforge GUI after importing, and will generate .ttf file from the GUI tool.
- the procreate template is called "米回字格"，which is perfect for chinese character writing. Also fit for letters and symbols.