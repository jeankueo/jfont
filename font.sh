#!/bin/bash

VERSION="1.1.0"

# ══ CONFIGURATION ════════════════════════════════════════════════════════════
# Assignment practice sheet — directories
ASSIGN_FONT_TEXT_DIR_DEFAULT="./text"    # source .txt files
ASSIGN_FONT_HANDOUT_DIR_DEFAULT="./handout" # output: content.json and PNGs

# Assignment practice sheet — fonts (path : ttc index)
# HanziPen SC Regular — header title and example characters; Kaiti SC / PingFang SC as fallbacks
ASSIGN_FONT_PRIMARY="/System/Library/AssetsV2/com_apple_MobileAsset_Font8/a3c69464b629577766c23bcdb12ffbfe3759b923.asset/AssetData/Hanzipen.ttc"
ASSIGN_FONT_PRIMARY_IDX=2
ASSIGN_FONT_FALLBACK1="/System/Library/AssetsV2/com_apple_MobileAsset_Font8/88d6cc32a907955efa1d014207889413890573be.asset/AssetData/Kaiti.ttc"
ASSIGN_FONT_FALLBACK1_IDX=0
ASSIGN_FONT_FALLBACK2="/System/Library/Fonts/PingFang.ttc"
ASSIGN_FONT_FALLBACK2_IDX=4
ASSIGN_FONT_FALLBACK3="/System/Library/Fonts/PingFang.ttc"
ASSIGN_FONT_FALLBACK3_IDX=0

# Typeface pipeline — source and output directories
TYPEFACE_HANDIN_DIR_DEFAULT="./handin"
TYPEFACE_FONT_DIR_DEFAULT="./font"   # .sfd, .ttf and temp/ subdirectory
TYPEFACE_FONT_NAME_DEFAULT="myfont"
PUBLISH_TARGET_DIR_DEFAULT="./html"
# ═════════════════════════════════════════════════════════════════════════════

TTF_FILE=""
SFD_FILE=""
TYPEFACE_HANDIN_DIR="$TYPEFACE_HANDIN_DIR_DEFAULT"
TYPEFACE_HANDIN_FILE=""
TYPEFACE_FONT_DIR="$TYPEFACE_FONT_DIR_DEFAULT"
ASSIGN_FONT_HANDOUT_DIR="$ASSIGN_FONT_HANDOUT_DIR_DEFAULT"
TYPEFACE_JSON_DIR=""
TYPEFACE_PNG_DIR=""
TYPEFACE_PBM_DIR=""
TYPEFACE_SVG_DIR=""

# ── colors ────────────────────────────────────────────────────────────────────
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

info()  { echo -e "${GREEN}✔${RESET}  $*"; }
warn()  { echo -e "${YELLOW}⚠${RESET}  $*"; }
error() { echo -e "${RED}✘${RESET}  $*" >&2; }
step()  { echo -e "${CYAN}→${RESET}  $*"; }

# ── usage ─────────────────────────────────────────────────────────────────────
usage() {
    echo -e "
${BOLD}font${RESET} v${VERSION}  —  typeface builder & assignment sheet generator

${BOLD}USAGE${RESET}
  ${CYAN}font${RESET} [-v] <command> [subcommand] [options]

${BOLD}WORKFLOW${RESET}
  1. ${CYAN}assignment${RESET}  Generate practice sheets → students write characters
  2. ${CYAN}typeface${RESET}    Scan handwritten PNGs → build TTF font
  3. ${CYAN}publish${RESET}     Install TTF into the system font directory

${BOLD}font assignment${RESET} [subcommand] [options]
  ${DIM}(no subcommand)${RESET}       Pipeline: [reset?] → content → png
    ${YELLOW}-text <file/folder>${RESET}     .txt source; default: ${DIM}ASSIGN_FONT_TEXT_DIR_DEFAULT=\"$ASSIGN_FONT_TEXT_DIR_DEFAULT\"${RESET}
    ${YELLOW}-handout <folder>${RESET}       Output folder; default: ${DIM}ASSIGN_FONT_HANDOUT_DIR_DEFAULT=\"$ASSIGN_FONT_HANDOUT_DIR_DEFAULT\"${RESET}
  ${CYAN}content${RESET} [options]     Append lessons to content.json (creates if absent)
    ${YELLOW}-text <file/folder>${RESET}     File: that lesson · Folder: all, alphabetical
    ${YELLOW}-handout <folder>${RESET}       Override output folder
  ${CYAN}png${RESET} [options]         Generate practice-sheet PNGs into handout folder
    ${YELLOW}-text <file/folder>${RESET}     Filter lessons; omit to generate all
    ${YELLOW}-handout <folder>${RESET}       Override output folder
  ${CYAN}reset${RESET} [options]       ${YELLOW}-handout <folder>${RESET}: clear folder · ${YELLOW}-handout <file>${RESET}: delete its PNGs
                        No -handout: clear the default handout folder

${BOLD}font typeface${RESET} [subcommand] [options]
  ${DIM}(no subcommand)${RESET}       Full pipeline: char-2-uni → png-crop → png-2-pbm → pbm-2-svg → svg-import → generate → cleanup
    ${YELLOW}-handin <file/folder>${RESET}   Source PNGs; default: ${DIM}TYPEFACE_HANDIN_DIR_DEFAULT=\"$TYPEFACE_HANDIN_DIR_DEFAULT\"${RESET}
    ${YELLOW}-font-name <name>${RESET}       Base name for .sfd and .ttf; default: ${DIM}TYPEFACE_FONT_NAME_DEFAULT=\"$TYPEFACE_FONT_NAME_DEFAULT\"${RESET}
    ${YELLOW}-font-dir <folder>${RESET}      Output for .sfd/.ttf and temp/; default: ${DIM}TYPEFACE_FONT_DIR_DEFAULT=\"$TYPEFACE_FONT_DIR_DEFAULT\"${RESET}
  ${CYAN}char-2-uni${RESET} [options]  .png filename → Unicode JSON
  ${CYAN}png-crop${RESET} [options]    Crop handin PNGs → per-glyph 200×200 PNGs
  ${CYAN}png-2-pbm${RESET}             PNG → PBM bitmaps
  ${CYAN}pbm-2-svg${RESET}             PBM → SVG outlines
  ${CYAN}svg-import${RESET} [options]  SVG → FontForge .sfd
  ${CYAN}generate${RESET} [options]    .sfd → .ttf
  ${CYAN}cleanup${RESET}               Delete font-dir/temp/

${BOLD}font publish${RESET} <subcommand> [options]
  ${CYAN}mac${RESET} [options]        Install TTF into ~/Library/Fonts (macOS user font library)
    ${YELLOW}-font-name <name>${RESET}       Font to publish; default: ${DIM}TYPEFACE_FONT_NAME_DEFAULT=\"$TYPEFACE_FONT_NAME_DEFAULT\"${RESET}
    ${YELLOW}-font-dir <folder>${RESET}      Folder containing the .ttf; default: ${DIM}TYPEFACE_FONT_DIR_DEFAULT=\"$TYPEFACE_FONT_DIR_DEFAULT\"${RESET}
    ${YELLOW}-dest <folder>${RESET}          Destination directory; default: ${DIM}~/Library/Fonts${RESET}
  ${CYAN}html${RESET} [options]       Generate HTML files from .txt sources, rendered in the built font
    ${YELLOW}-text <file/folder>${RESET}     Source .txt; default: ${DIM}ASSIGN_FONT_TEXT_DIR_DEFAULT=\"$ASSIGN_FONT_TEXT_DIR_DEFAULT\"${RESET}
    ${YELLOW}-target <folder>${RESET}        Output folder; default: ${DIM}PUBLISH_TARGET_DIR_DEFAULT=\"$PUBLISH_TARGET_DIR_DEFAULT\"${RESET}
    ${YELLOW}-font-name <name>${RESET}       Font to embed; default: ${DIM}TYPEFACE_FONT_NAME_DEFAULT=\"$TYPEFACE_FONT_NAME_DEFAULT\"${RESET}
    ${YELLOW}-font-dir <folder>${RESET}      Folder containing the .ttf; default: ${DIM}TYPEFACE_FONT_DIR_DEFAULT=\"$TYPEFACE_FONT_DIR_DEFAULT\"${RESET}

${BOLD}EXAMPLES${RESET}
  ${DIM}font assignment -text han/001.txt${RESET}
  ${DIM}font assignment -text han/${RESET}
  ${DIM}font assignment content -text han/001${RESET}
  ${DIM}font assignment png -text 001${RESET}
  ${DIM}font assignment reset -handout han/001.txt${RESET}
  ${DIM}font typeface -font-name myfont${RESET}
  ${DIM}font typeface -font-name myfont -font-dir ./output${RESET}
  ${DIM}font typeface svg-import -font-name myfont${RESET}
  ${DIM}font typeface char-2-uni -handin handin/001.png${RESET}
  ${DIM}font publish mac -font-name myfont${RESET}
  ${DIM}font publish mac -font-name myfont -dest ~/Library/Fonts${RESET}
  ${DIM}font publish html${RESET}
  ${DIM}font publish html -text han/001.txt -font-name myfont${RESET}
  ${DIM}font publish html -text han/ -target ./html${RESET}
"
}

# ── helpers ───────────────────────────────────────────────────────────────────
_require_sfd() { :; }  # kept for compatibility; font-name always has a default now

_parse_font_name() {
    local val="$1"
    mkdir -p "$TYPEFACE_FONT_DIR"
    SFD_FILE="$TYPEFACE_FONT_DIR/$val.sfd"
    TTF_FILE="$TYPEFACE_FONT_DIR/$val.ttf"
}

_lesson_key_from_path() {
    local fname
    fname=$(basename -- "$1")
    local base="${fname%.*}"
    echo "${base:0:3}"
}

_typeface_handin_files() {
    if [ -n "$TYPEFACE_HANDIN_FILE" ]; then
        echo "$TYPEFACE_HANDIN_FILE"
    else
        find "$TYPEFACE_HANDIN_DIR" -name "*.png" | sort
    fi
}

# ── global option parsing ─────────────────────────────────────────────────────
while [[ "${1:-}" =~ ^- ]]; do
    case "$1" in
        --version|-v) echo "$VERSION"; exit 0 ;;
        *) break ;;
    esac
done

# ── typeface pipeline ─────────────────────────────────────────────────────────
char_2_uni() {
    local content_file="$ASSIGN_FONT_HANDOUT_DIR/content.json"
    if [ ! -f "$content_file" ]; then
        error "content.json not found at $content_file — run 'font assignment content' first."
        exit 1
    fi
    mkdir -p "$TYPEFACE_JSON_DIR"
    while IFS= read -r png_file; do
        [ -f "$png_file" ] || continue
        step "Processing $png_file"
        local filename key json_out
        filename=$(basename -- "$png_file")
        key="${filename:0:3}"
        json_out="$TYPEFACE_JSON_DIR/${filename%.*}.json"
        python3 - "$content_file" "$key" "$json_out" <<'PYEOF'
import json, sys

content_file, key, json_out = sys.argv[1], sys.argv[2], sys.argv[3]

with open(content_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

chars = data.get('assignment', {}).get(key, '')
if not chars:
    print(f"Key '{key}' not found in assignment", file=sys.stderr)
    sys.exit(1)

with open(json_out, 'w', encoding='utf-8') as f:
    json.dump([f"uni{ord(c):04x}" for c in chars], f, ensure_ascii=False)
PYEOF
        [ $? -ne 0 ] && exit 1
        info "Saved $json_out"
    done < <(_typeface_handin_files)
}

png_crop() {
    rm -rf "$TYPEFACE_PNG_DIR"
    mkdir -p "$TYPEFACE_PNG_DIR"
    # Template layout: 2400x1600 total
    #   top 100px: title (skipped)
    #   remaining 2400x1500: 12 cols x 5 rows of 200x300 cells
    #   each cell: top 100px = example character (skipped), bottom 200x200 = target area
    local COLS=12 ROWS=5 CELL_W=200 CELL_H=300 TITLE_H=100 EXAMPLE_H=100

    while IFS= read -r input_file; do
        [ -f "$input_file" ] || continue
        step "Processing $input_file"
        local filename filename_no_ext json_file
        filename=$(basename -- "$input_file")
        filename_no_ext="${filename%.*}"
        json_file="$TYPEFACE_JSON_DIR/$filename_no_ext.json"
        if [ ! -f "$json_file" ]; then
            warn "JSON not found for $input_file — skipping."
            continue
        fi
        local names=()
        while IFS= read -r line; do names+=("$line"); done < <(jq -r '.[]' "$json_file")
        local i=0
        for (( row=0; row<ROWS; row++ )); do
            for (( col=0; col<COLS; col++ )); do
                [ -n "${names[$i]}" ] || break 2
                local x=$(( col * CELL_W ))
                local y=$(( TITLE_H + row * CELL_H + EXAMPLE_H ))
                local out="$TYPEFACE_PNG_DIR/${names[$i]}.png"
                magick "$input_file" -crop "${CELL_W}x${CELL_W}+${x}+${y}" +repage "$out"
                info "Created $out"
                i=$(( i + 1 ))
            done
        done
    done < <(_typeface_handin_files)
    info "Cropping complete → $TYPEFACE_PNG_DIR"
}

png_2_pbm() {
    mkdir -p "$TYPEFACE_PBM_DIR"
    for file in "$TYPEFACE_PNG_DIR"/*.png; do
        step "Converting $file → PBM"
        local filename
        filename=$(basename -- "$file")
        magick "$file" -background white -alpha remove -colorspace Gray "$TYPEFACE_PBM_DIR/${filename%.*}.pbm"
    done
}

pbm_2_svg() {
    mkdir -p "$TYPEFACE_SVG_DIR"
    for file in "$TYPEFACE_PBM_DIR"/*.pbm; do
        step "Converting $file → SVG"
        local filename
        filename=$(basename -- "$file")
        potrace "$file" -s -o "$TYPEFACE_SVG_DIR/${filename%.*}.svg"
    done
}

svg_import() {
    local script_file
    script_file=$(mktemp)
    if [ ! -f "$SFD_FILE" ]; then
        warn "SFD not found: $SFD_FILE — creating new font."
        local sfd_basename font_name postscript_name
        sfd_basename=$(basename -- "$SFD_FILE")
        font_name="${sfd_basename%.*}"
        postscript_name=$(echo "$font_name" | tr -d ' ')
        {
            echo "New()"
            echo 'Reencode("UnicodeFull")'
            echo "SetFontNames(\"$postscript_name\", \"$font_name\", \"$font_name\")"
            echo "SetTTFName(0x409, 1, \"$font_name\")"
            echo "SetTTFName(0x409, 2, \"Regular\")"
            echo "SetTTFName(0x409, 4, \"$font_name\")"
            echo "SetTTFName(0x409, 5, \"$VERSION\")"
            echo "SetTTFName(0x409, 6, \"$postscript_name\")"
            echo "SetTTFName(0x409, 7, \"Private\")"
            echo "SetTTFName(0x804, 1, \"$font_name\")"
            echo "SetTTFName(0x804, 2, \"常规\")"
            echo "SetTTFName(0x804, 4, \"$font_name\")"
            echo "SetTTFName(0x804, 5, \"$VERSION\")"
            echo "SetTTFName(0x804, 6, \"$postscript_name\")"
            echo "SetTTFName(0x804, 7, \"Private\")"
        } > "$script_file"
    else
        echo "Open(\"$SFD_FILE\")" > "$script_file"
    fi
    for file in "$TYPEFACE_SVG_DIR"/*.svg; do
        local filename filename_no_ext unicode_hex
        filename=$(basename -- "$file")
        filename_no_ext="${filename%.*}"
        unicode_hex="${filename_no_ext:3}"
        echo "Select(0x$unicode_hex); Clear(); Import(\"$file\"); Scale(150); Move(250, 0); SetLBearing(50); SetRBearing(50);" >> "$script_file"
        step "Queued $file → U+$unicode_hex"
    done
    echo "Save(\"$SFD_FILE\")" >> "$script_file"
    echo "Close()" >> "$script_file"
    step "Running fontforge…"
    fontforge -script "$script_file"
    rm "$script_file"
    info "SFD saved → $SFD_FILE"
}

font_generate() {
    if [ ! -f "$SFD_FILE" ]; then
        error "SFD not found: $SFD_FILE"
        exit 1
    fi
    step "Generating TTF…"
    fontforge -script -c "import fontforge; font = fontforge.open('$SFD_FILE'); font.generate('$TTF_FILE'); font.close()"
    info "TTF generated → $TTF_FILE"
}

typeface_run() {
    local subcommand=""
    if [[ "${1:-}" != -* ]]; then subcommand="${1:-}"; shift 2>/dev/null || true; fi
    local font_name_arg=""
    while [[ "${1:-}" == -* ]]; do
        case "$1" in
            -font-name) font_name_arg="$2"; shift 2 ;;
            -font-dir)  TYPEFACE_FONT_DIR="$2"; shift 2 ;;
            -handin)
                if [ -f "$2" ]; then
                    TYPEFACE_HANDIN_FILE="$2"
                elif [ -d "$2" ]; then
                    TYPEFACE_HANDIN_DIR="$2"
                    TYPEFACE_HANDIN_FILE=""
                else
                    error "-handin: not found: $2"; exit 1
                fi
                shift 2 ;;
            *) error "Unknown option: $1"; exit 1 ;;
        esac
    done
    _parse_font_name "${font_name_arg:-$TYPEFACE_FONT_NAME_DEFAULT}"
    local TYPEFACE_TEMP_DIR="$TYPEFACE_FONT_DIR/temp"
    TYPEFACE_JSON_DIR="$TYPEFACE_TEMP_DIR/json"
    TYPEFACE_PNG_DIR="$TYPEFACE_TEMP_DIR/png"
    TYPEFACE_PBM_DIR="$TYPEFACE_TEMP_DIR/pbm"
    TYPEFACE_SVG_DIR="$TYPEFACE_TEMP_DIR/svg"
    case "$subcommand" in
        char-2-uni) char_2_uni ;;
        png-crop)   png_crop ;;
        png-2-pbm)  png_2_pbm ;;
        pbm-2-svg)  pbm_2_svg ;;
        svg-import) _require_sfd; svg_import ;;
        generate)   _require_sfd; font_generate ;;
        cleanup)
            if [ -d "$TYPEFACE_TEMP_DIR" ]; then
                rm -rf "$TYPEFACE_TEMP_DIR"
                info "Removed $TYPEFACE_TEMP_DIR"
            else
                warn "$TYPEFACE_TEMP_DIR does not exist — nothing to clean."
            fi
            ;;
        "")
            _require_sfd
            char_2_uni; png_crop; png_2_pbm; pbm_2_svg; svg_import; font_generate
            rm -rf "$TYPEFACE_TEMP_DIR" && info "Removed $TYPEFACE_TEMP_DIR"
            ;;
        *) error "Unknown typeface subcommand: $1"; usage; exit 1 ;;
    esac
}

# ── assignment ────────────────────────────────────────────────────────────────
_assign_add_file() {
    local target_file="$1"
    local content_file="$ASSIGN_FONT_HANDOUT_DIR/content.json"
    local name_no_ext
    name_no_ext=$(basename -- "$target_file")
    name_no_ext="${name_no_ext%.*}"
    python3 - "$target_file" "$name_no_ext" "$content_file" <<'PYEOF'
import json, sys

input_file, name_no_ext, content_file = sys.argv[1], sys.argv[2], sys.argv[3]

with open(input_file, 'r', encoding='utf-8') as f:
    text = f.read()
with open(content_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

if isinstance(data['dictionary'], dict):
    data['dictionary'] = ''

key = name_no_ext[:3]
data.setdefault('names', {})[key] = name_no_ext

for char in text:
    if char.isspace() or char in data['dictionary']:
        continue
    data['dictionary'] += char
    if key not in data['assignment']:
        data['assignment'][key] = ''
    elif isinstance(data['assignment'][key], list):
        data['assignment'][key] = ''.join(data['assignment'][key])
    data['assignment'][key] += char

with open(content_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
PYEOF
    info "Processed $target_file"
}

assign_reset() {
    local handout=""
    while [[ "${1:-}" == -* ]]; do
        case "$1" in
            -handout) handout="$2"; shift 2 ;;
            *) error "Unknown option: $1"; exit 1 ;;
        esac
    done

    if [ -d "$handout" ]; then
        # explicit directory: clear it
        echo -e "${YELLOW}This will permanently delete all contents of ${BOLD}$handout/${RESET}${YELLOW} (directory kept).${RESET}"
        echo -en "${BOLD}Confirm? [y/N] ${RESET}"
        read -r reply
        case "$reply" in
            [yY][eE][sS]|[yY])
                find "$handout" -mindepth 1 -delete
                info "Cleared $handout"
                ;;
            *) echo "Aborted." ;;
        esac
    elif [ -n "$handout" ]; then
        # treat as a source file path: extract key and delete its PNGs
        local key content_file name
        key=$(_lesson_key_from_path "$handout")
        content_file="$ASSIGN_FONT_HANDOUT_DIR/content.json"
        if [ ! -f "$content_file" ]; then
            info "No content.json yet — nothing to reset for lesson '$key'."
            return
        fi
        name=$(jq -r --arg k "$key" '.names[$k] // $k' "$content_file")
        local files=( "$ASSIGN_FONT_HANDOUT_DIR/${name}_p"*.png )
        if [ ! -f "${files[0]}" ]; then
            info "No PNGs found for lesson '$key' ($name) — nothing to reset."
            return
        fi
        echo -e "${YELLOW}Delete ${#files[@]} PNG(s) for lesson ${BOLD}$key${RESET}${YELLOW} ($name)?${RESET}"
        echo -en "${BOLD}Confirm? [y/N] ${RESET}"
        read -r reply
        case "$reply" in
            [yY][eE][sS]|[yY])
                rm "${files[@]}"
                info "Deleted ${#files[@]} PNG(s) for $name"
                ;;
            *) echo "Aborted." ;;
        esac
    else
        # no argument: clear ASSIGN_FONT_HANDOUT_DIR
        local dir="$ASSIGN_FONT_HANDOUT_DIR"
        if [ ! -d "$dir" ]; then
            warn "$dir does not exist — nothing to reset."
            return
        fi
        echo -e "${YELLOW}This will permanently delete all contents of ${BOLD}$dir/${RESET}${YELLOW} (directory kept).${RESET}"
        echo -en "${BOLD}Confirm? [y/N] ${RESET}"
        read -r reply
        case "$reply" in
            [yY][eE][sS]|[yY])
                find "$dir" -mindepth 1 -delete
                info "Cleared $dir"
                ;;
            *) echo "Aborted." ;;
        esac
    fi
}

assign_content() {
    local src="$ASSIGN_FONT_TEXT_DIR_DEFAULT"
    while [[ "${1:-}" == -* ]]; do
        case "$1" in
            -text)    src="$2"; shift 2 ;;
            -handout) ASSIGN_FONT_HANDOUT_DIR="$2"; shift 2 ;;
            *) error "Unknown option: $1"; exit 1 ;;
        esac
    done
    [ ! -f "$src" ] && [ ! -d "$src" ] && [ -f "$src.txt" ] && src="$src.txt"

    if [ ! -f "$src" ] && [ ! -d "$src" ]; then
        error "Source not found: $src"
        exit 1
    fi

    local content_file="$ASSIGN_FONT_HANDOUT_DIR/content.json"
    if [ ! -f "$content_file" ]; then
        mkdir -p "$ASSIGN_FONT_HANDOUT_DIR"
        printf '{\n  "dictionary": "",\n  "names": {},\n  "assignment": {}\n}\n' > "$content_file"
        info "Created $content_file"
    fi

    if [ -f "$src" ]; then
        _assign_add_file "$src"
    else
        while IFS= read -r file; do
            _assign_add_file "$file"
        done < <(find "$src" -type f -name "*.txt" | sort)
    fi
}

assign_png() {
    local src="" explicit_src=0
    while [[ "${1:-}" == -* ]]; do
        case "$1" in
            -text)    src="$2"; explicit_src=1; shift 2 ;;
            -handout) ASSIGN_FONT_HANDOUT_DIR="$2"; shift 2 ;;
            *) error "Unknown option: $1"; exit 1 ;;
        esac
    done

    local filter_keys=""
    if [ "$explicit_src" -eq 1 ]; then
        [ ! -f "$src" ] && [ ! -d "$src" ] && [ -f "$src.txt" ] && src="$src.txt"
        if [ -f "$src" ]; then
            filter_keys=$(_lesson_key_from_path "$src")
        elif [ -d "$src" ]; then
            filter_keys=$(find "$src" -type f -name "*.txt" | sort | while IFS= read -r f; do _lesson_key_from_path "$f"; done | paste -sd,)
        else
            error "Source not found: $src"
            exit 1
        fi
    fi
    # filter_keys="" means generate all keys from content.json

    local content_file="$ASSIGN_FONT_HANDOUT_DIR/content.json"
    if [ ! -f "$content_file" ]; then
        error "content.json not found — run 'font assignment content' first."
        exit 1
    fi

    local png_output_dir="$ASSIGN_FONT_HANDOUT_DIR"
    mkdir -p "$png_output_dir"
    step "Generating assignment PNGs → $png_output_dir"

    ASSIGN_FONT_PRIMARY="$ASSIGN_FONT_PRIMARY" \
    ASSIGN_FONT_PRIMARY_IDX="$ASSIGN_FONT_PRIMARY_IDX" \
    ASSIGN_FONT_FALLBACK1="$ASSIGN_FONT_FALLBACK1" \
    ASSIGN_FONT_FALLBACK1_IDX="$ASSIGN_FONT_FALLBACK1_IDX" \
    ASSIGN_FONT_FALLBACK2="$ASSIGN_FONT_FALLBACK2" \
    ASSIGN_FONT_FALLBACK2_IDX="$ASSIGN_FONT_FALLBACK2_IDX" \
    ASSIGN_FONT_FALLBACK3="$ASSIGN_FONT_FALLBACK3" \
    ASSIGN_FONT_FALLBACK3_IDX="$ASSIGN_FONT_FALLBACK3_IDX" \
    python3 - "$content_file" "$png_output_dir" "$filter_keys" <<'PYEOF'
import json, os, sys
from PIL import Image, ImageDraw, ImageFont

content_file = sys.argv[1]
output_dir   = sys.argv[2]
filter_keys = sys.argv[3] if len(sys.argv) > 3 else ""

with open(content_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

COLS           = 12
ROWS           = 5
CHARS_PER_PAGE = COLS * ROWS
CELL_W         = 200
CELL_H         = 300
HEADER_H       = 100
CHAR_AREA_H    = 100
PAGE_W         = COLS * CELL_W
PAGE_H         = HEADER_H + ROWS * CELL_H
WHITE          = (255, 255, 255, 255)
TEXT_DARK      = (40,  40,  40,  255)
TEXT_GRAY      = (130, 130, 130, 255)

FONT_CANDIDATES = [
    (os.environ.get('ASSIGN_FONT_PRIMARY',   ''), int(os.environ.get('ASSIGN_FONT_PRIMARY_IDX',   2))),
    (os.environ.get('ASSIGN_FONT_FALLBACK1', ''), int(os.environ.get('ASSIGN_FONT_FALLBACK1_IDX', 0))),
    (os.environ.get('ASSIGN_FONT_FALLBACK2', ''), int(os.environ.get('ASSIGN_FONT_FALLBACK2_IDX', 4))),
    (os.environ.get('ASSIGN_FONT_FALLBACK3', ''), int(os.environ.get('ASSIGN_FONT_FALLBACK3_IDX', 0))),
]

def build_unit_cell():
    img = Image.new('RGBA', (200, 300), (255, 255, 255, 255))
    d   = ImageDraw.Draw(img)
    LIGHT = (221, 221, 221, 255)
    DARK  = (153, 153, 153, 255)
    d.line([(1,  101), (199, 299)], fill=LIGHT)
    d.line([(199, 101), (1,  299)], fill=LIGHT)
    d.line([(100, 101), (100, 299)], fill=LIGHT)
    d.line([(1,   200), (199, 200)], fill=LIGHT)
    d.rectangle([(67, 167), (133, 233)], outline=LIGHT)
    d.rectangle([(1, 1), (199, 299)], outline=DARK)
    d.line([(1, 101), (199, 101)], fill=DARK)
    d.rectangle([(34, 134), (166, 266)], outline=DARK)
    return img

def build_template():
    unit = build_unit_cell()
    page = Image.new('RGBA', (PAGE_W, PAGE_H), WHITE)
    for row in range(ROWS):
        for col in range(COLS):
            page.paste(unit, (col * CELL_W, HEADER_H + row * CELL_H))
    draw = ImageDraw.Draw(page)
    draw.line([(0, HEADER_H), (PAGE_W, HEADER_H)], fill=(160, 160, 160, 255), width=2)
    draw.rectangle([0, HEADER_H, PAGE_W - 1, PAGE_H - 1], outline=(140, 140, 140, 255), width=2)
    return page

def load_font(size):
    for path, idx in FONT_CANDIDATES:
        if not path:
            continue
        try:
            return ImageFont.truetype(path, size, index=idx)
        except Exception:
            pass
    return ImageFont.load_default()

char_font   = load_font(78)
header_font = load_font(50)
template    = build_template()
assignment  = data.get('assignment', {})
names       = data.get('names', {})

def make_pages(key, chars):
    pages = [chars[i:i+CHARS_PER_PAGE] for i in range(0, len(chars), CHARS_PER_PAGE)]
    total = len(pages)
    for pn, pchars in enumerate(pages, 1):
        img  = template.copy()
        draw = ImageDraw.Draw(img)
        draw.text((60, HEADER_H // 2),
                  names.get(key, f"第 {key} 课"),
                  font=header_font, fill=TEXT_DARK, anchor="lm")
        draw.text((PAGE_W - 60, HEADER_H // 2),
                  f"第 {pn} 页 / 共 {total} 页",
                  font=header_font, fill=TEXT_GRAY, anchor="rm")
        for i, ch in enumerate(pchars):
            col, row = i % COLS, i // COLS
            cx = col * CELL_W + CELL_W // 2
            cy = HEADER_H + row * CELL_H + CHAR_AREA_H // 2
            draw.text((cx, cy), ch, font=char_font, fill=TEXT_GRAY, anchor="mm")
        out = f"{output_dir}/{names.get(key, key)}_p{pn:02d}.png"
        img.save(out, "PNG")
        print(f"Saved {out}")

keys  = filter_keys.split(',') if filter_keys else sorted(assignment)
saved = 0
for k in keys:
    if k not in assignment:
        print(f"Key '{k}' not found in assignment", file=sys.stderr)
        sys.exit(1)
    if assignment[k]:
        make_pages(k, assignment[k])
        saved += 1
if saved == 0:
    print("No pages generated — assignment may be empty.", file=sys.stderr)
    sys.exit(1)
PYEOF
    local py_exit=$?
    [ $py_exit -ne 0 ] && { error "PNG generation failed (exit $py_exit)."; exit 1; }
    info "Done."
}

assignment_run() {
    local subcommand=""
    if [[ "${1:-}" != -* ]]; then subcommand="${1:-}"; shift 2>/dev/null || true; fi
    case "$subcommand" in
        reset)   assign_reset "$@" ;;
        content) assign_content "$@" ;;
        png)     assign_png "$@" ;;
        "")
            local text_arg=""
            while [[ "${1:-}" == -* ]]; do
                case "$1" in
                    -text)    text_arg="$2"; shift 2 ;;
                    -handout) ASSIGN_FONT_HANDOUT_DIR="$2"; shift 2 ;;
                    *) error "Unknown option: $1"; exit 1 ;;
                esac
            done
            echo -en "${BOLD}Reset before generating? [y/N] ${RESET}"
            read -r do_reset
            case "$do_reset" in
                [yY][eE][sS]|[yY])
                    if [ -n "$text_arg" ]; then
                        assign_reset -handout "$text_arg"
                    else
                        assign_reset
                    fi
                    ;;
            esac
            assign_content ${text_arg:+-text "$text_arg"}
            assign_png ${text_arg:+-text "$text_arg"}
            ;;
        *) error "Unknown assignment subcommand: $subcommand"; usage; exit 1 ;;
    esac
}

# ── publish ───────────────────────────────────────────────────────────────────
_publish_html_one() {
    local txt_file="$1" out_file="$2" abs_ttf="$3" font_family="$4"
    mkdir -p "$(dirname "$out_file")"
    python3 - "$txt_file" "$out_file" "$abs_ttf" "$font_family" <<'PYEOF'
import sys, html as _html, base64, os
txt_file, out_file, ttf_path, font_family = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
title = os.path.splitext(os.path.basename(txt_file))[0][4:]
with open(txt_file, 'r', encoding='utf-8') as f:
    text = f.read()
with open(ttf_path, 'rb') as f:
    font_b64 = base64.b64encode(f.read()).decode('ascii')
page = f"""<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="utf-8">
<title>{_html.escape(title)}</title>
<style>
  @font-face {{
    font-family: '{font_family}';
    src: url('data:font/truetype;base64,{font_b64}') format('truetype');
  }}
  body {{
    font-family: '{font_family}', 'Kaiti SC', 'STKaiti', 'KaiTi', serif;
    font-size: 3rem;
    line-height: 2;
    padding: 2rem;
    background: #fff;
    color: #222;
  }}
  h1 {{ font-family: '{font_family}', 'Kaiti SC', 'STKaiti', 'KaiTi', serif; font-size: 2rem; margin-bottom: 1.5rem; color: #666; font-weight: normal; }}
  pre {{ font-family: inherit; white-space: pre-wrap; word-break: break-all; margin: 0; }}
</style>
</head>
<body>
<h1>{_html.escape(title)}</h1>
<pre>{_html.escape(text)}</pre>
</body>
</html>"""
with open(out_file, 'w', encoding='utf-8') as f:
    f.write(page)
print(f"Saved {out_file}")
PYEOF
}

publish_run() {
    local subcommand=""
    if [[ "${1:-}" != -* ]]; then subcommand="${1:-}"; shift 2>/dev/null || true; fi
    case "$subcommand" in
        mac)
            local font_name_arg="" dest="$HOME/Library/Fonts"
            while [[ "${1:-}" == -* ]]; do
                case "$1" in
                    -font-name) font_name_arg="$2"; shift 2 ;;
                    -font-dir)  TYPEFACE_FONT_DIR="$2"; shift 2 ;;
                    -dest)      dest="$2"; shift 2 ;;
                    *) error "Unknown option: $1"; exit 1 ;;
                esac
            done
            _parse_font_name "${font_name_arg:-$TYPEFACE_FONT_NAME_DEFAULT}"
            if [ ! -f "$TTF_FILE" ]; then
                error "TTF not found: $TTF_FILE — run 'font typeface' first."
                exit 1
            fi
            mkdir -p "$dest"
            cp "$TTF_FILE" "$dest/"
            info "Installed $(basename "$TTF_FILE") → $dest/"
            ;;
        html)
            local src="$ASSIGN_FONT_TEXT_DIR_DEFAULT"
            local target="$PUBLISH_TARGET_DIR_DEFAULT"
            local font_name_arg=""
            while [[ "${1:-}" == -* ]]; do
                case "$1" in
                    -text)      src="$2"; shift 2 ;;
                    -target)    target="$2"; shift 2 ;;
                    -font-name) font_name_arg="$2"; shift 2 ;;
                    -font-dir)  TYPEFACE_FONT_DIR="$2"; shift 2 ;;
                    *) error "Unknown option: $1"; exit 1 ;;
                esac
            done
            _parse_font_name "${font_name_arg:-$TYPEFACE_FONT_NAME_DEFAULT}"
            if [ ! -f "$TTF_FILE" ]; then
                error "TTF not found: $TTF_FILE — run 'font typeface' first."
                exit 1
            fi
            [ ! -f "$src" ] && [ ! -d "$src" ] && { error "Source not found: $src"; exit 1; }
            local abs_ttf font_family
            abs_ttf=$(cd "$(dirname "$TTF_FILE")" && pwd)/$(basename "$TTF_FILE")
            font_family=$(basename "$TTF_FILE" .ttf)
            mkdir -p "$target"
            if [ -f "$src" ]; then
                local base
                base=$(basename "$src" .txt)
                _publish_html_one "$src" "$target/$base.html" "$abs_ttf" "$font_family"
            else
                while IFS= read -r txt_file; do
                    local rel out_file
                    rel="${txt_file#${src%/}/}"
                    out_file="$target/${rel%.txt}.html"
                    _publish_html_one "$txt_file" "$out_file" "$abs_ttf" "$font_family"
                done < <(find "$src" -type f -name "*.txt" | sort)
            fi
            info "Done → $target"
            ;;
        "") error "publish requires a subcommand (e.g. 'mac', 'html')"; usage; exit 1 ;;
        *)  error "Unknown publish subcommand: $subcommand"; usage; exit 1 ;;
    esac
}

# ── dispatch ──────────────────────────────────────────────────────────────────
case "${1:-}" in
    typeface)   shift; typeface_run "$@" ;;
    assignment) shift; assignment_run "$@" ;;
    publish)    shift; publish_run "$@" ;;
    ""|help|-h|--help) usage ;;
    *) error "Unknown command: $1"; usage; exit 1 ;;
esac
