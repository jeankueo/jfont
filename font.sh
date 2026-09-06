#!/bin/bash

VERSION="1.1.0"

ORIGIN_DIR=./src
JSON_DIR=/Users/I037379/Desktop/output/json
PNG_DIR=/Users/I037379/Desktop/output/png
PBM_DIR=/Users/I037379/Desktop/output/pbm
SVG_DIR=/Users/I037379/Desktop/output/svg
TTF_DIR=./output
TTF_FILE=""
SFD_FILE=""

# ── colors ────────────────────────────────────────────────────────────────────
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

info()    { echo -e "${GREEN}✔${RESET}  $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET}  $*"; }
error()   { echo -e "${RED}✘${RESET}  $*" >&2; }
step()    { echo -e "${CYAN}→${RESET}  $*"; }

# ── usage ─────────────────────────────────────────────────────────────────────
usage() {
    echo -e "
${BOLD}font${RESET} v${VERSION}

${BOLD}USAGE${RESET}
  ${CYAN}font${RESET} [${YELLOW}-name <sfd>${RESET}] [${YELLOW}-v${RESET}] ${CYAN}<command>${RESET} [options]

${BOLD}GLOBAL OPTIONS${RESET}
  ${YELLOW}-name <sfd>${RESET}       SFD font file (no extension); required by svg-import, generate, pipeline
  ${YELLOW}-v, --version${RESET}     Print version and exit

${BOLD}FONT PIPELINE${RESET}
  ${CYAN}char-2-uni${RESET}          .txt → Unicode JSON  ${DIM}(src/*.txt → output/json/)${RESET}
  ${CYAN}png-crop${RESET}            .png → per-glyph PNGs  ${DIM}(src/*.png → output/png/)${RESET}
  ${CYAN}png-2-pbm${RESET}           PNG → PBM bitmaps  ${DIM}(output/png/ → output/pbm/)${RESET}
  ${CYAN}pbm-2-svg${RESET}           PBM → SVG outlines via potrace  ${DIM}(output/pbm/ → output/svg/)${RESET}
  ${CYAN}svg-import${RESET}          SVG → FontForge .sfd  ${DIM}(requires -name)${RESET}
  ${CYAN}generate${RESET}            .sfd → .ttf  ${DIM}(requires -name)${RESET}
  ${CYAN}pipeline${RESET}            Run all steps in sequence  ${DIM}(requires -name)${RESET}

${BOLD}ASSIGNMENT${RESET}
  ${CYAN}assignment${RESET} [options]
    Scan source text files and populate ${YELLOW}assignment/content.json${RESET}.

    ${BOLD}content.json structure:${RESET}
      ${DIM}dictionary${RESET}   string — all unique characters seen across all processed files
      ${DIM}assignment${RESET}   object — key: first 3 chars of filename; value: chars from that batch

    ${BOLD}Options:${RESET}
      ${YELLOW}-f${RESET}             Force-recreate ${DIM}content.json${RESET} before processing
      ${YELLOW}-n <file>${RESET}      Process a single file only

    ${BOLD}Subcommands:${RESET}
      ${CYAN}reset${RESET}          Delete the entire ${DIM}assignment/${RESET} directory (prompts for confirmation)

    ${BOLD}Examples:${RESET}
      ${DIM}font assignment${RESET}                     process all files; auto-create content.json if absent
      ${DIM}font assignment -f${RESET}                  recreate content.json then process all files
      ${DIM}font assignment -n han/074_赞.txt${RESET}   process a single file
      ${DIM}font assignment -f -n han/001.txt${RESET}   recreate then process a single file
      ${DIM}font assignment reset${RESET}               delete assignment/ directory
"
}

# ── helpers ───────────────────────────────────────────────────────────────────
check_font_name() {
    if [ -z "$SFD_FILE" ]; then
        error "-name <font_name> is required for this command."
        exit 1
    fi
}

# ── global option parsing ─────────────────────────────────────────────────────
while [[ "${1:-}" =~ ^- ]]; do
    case "$1" in
        -name)
            SFD_FILE="./$2.sfd"
            rm -rf "$TTF_DIR"
            mkdir -p "$TTF_DIR"
            TTF_FILE="$TTF_DIR/$2.ttf"
            shift 2
            ;;
        --version|-v)
            echo "$VERSION"
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

# ── font pipeline ─────────────────────────────────────────────────────────────
char_2_uni() {
    mkdir -p "$JSON_DIR"
    for txt_file in "$ORIGIN_DIR"/*.txt; do
        [ -f "$txt_file" ] || continue
        step "Processing $txt_file"
        local input_string
        input_string=$(cat "$txt_file")
        local json_array
        json_array=$(echo -n "$input_string" | perl -CS -MJSON -ne 'print encode_json([map { sprintf("uni%04x", ord) } split //])')
        local filename
        filename=$(basename -- "$txt_file")
        local json_file="$JSON_DIR/${filename%.*}.json"
        echo "$json_array" > "$json_file"
        info "Saved $json_file"
    done
}

png_crop() {
    rm -rf "$PNG_DIR"
    mkdir -p "$PNG_DIR"

    for input_file in "$ORIGIN_DIR"/*.png; do
        [ -f "$input_file" ] || continue
        step "Processing $input_file"

        local filename
        filename=$(basename -- "$input_file")
        local filename_no_ext="${filename%.*}"
        local json_file="$JSON_DIR/$filename_no_ext.json"

        if [ ! -f "$json_file" ]; then
            warn "JSON not found for $input_file — skipping."
            continue
        fi

        local names=()
        while IFS= read -r line; do
            names+=("$line")
        done < <(jq -r '.[]' "$json_file")

        local temp_crop_dir
        temp_crop_dir=$(mktemp -d)
        step "Cropping into $temp_crop_dir"
        magick "$input_file" -crop 200x200 +repage +adjoin "$temp_crop_dir/%02d.png"

        local i=0
        for file in $(find "$temp_crop_dir" -name "*.png" | sort); do
            if [ -n "${names[$i]}" ]; then
                mv "$file" "$PNG_DIR/${names[$i]}.png"
                info "Created $PNG_DIR/${names[$i]}.png"
            else
                warn "No name for index $i — deleted."
                rm "$file"
            fi
            i=$((i+1))
        done
        rm -r "$temp_crop_dir"
    done
    info "Cropping complete → $PNG_DIR"
}

png_2_pbm() {
    mkdir -p "$PBM_DIR"
    for file in "$PNG_DIR"/*.png; do
        step "Converting $file → PBM"
        _png_to_pbm "$file" "$PBM_DIR"
    done
}

pbm_2_svg() {
    mkdir -p "$SVG_DIR"
    for file in "$PBM_DIR"/*.pbm; do
        step "Converting $file → SVG"
        _pbm_to_svg "$file" "$SVG_DIR"
    done
}

_png_to_pbm() {
    local filename
    filename=$(basename -- "$1")
    magick "$1" -background white -alpha remove -colorspace Gray "$2/${filename%.*}.pbm"
}

_pbm_to_svg() {
    local filename
    filename=$(basename -- "$1")
    potrace "$1" -s -o "$2/${filename%.*}.svg"
}

svg_import() {
    local SCRIPT_FILE
    SCRIPT_FILE=$(mktemp)

    if [ ! -f "$SFD_FILE" ]; then
        warn "SFD not found: $SFD_FILE — creating new font."
        local sfd_basename
        sfd_basename=$(basename -- "$SFD_FILE")
        local font_name="${sfd_basename%.*}"
        local postscript_name
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
        } > "$SCRIPT_FILE"
    else
        echo "Open(\"$SFD_FILE\")" > "$SCRIPT_FILE"
    fi

    for file in "$SVG_DIR"/*.svg; do
        local filename
        filename=$(basename -- "$file")
        local filename_no_ext="${filename%.*}"
        local unicode_hex="${filename_no_ext:3}"
        echo "Select(0x$unicode_hex); Clear(); Import(\"$file\"); Scale(150); Move(250, 0); SetLBearing(50); SetRBearing(50);" >> "$SCRIPT_FILE"
        step "Queued $file → U+$unicode_hex"
    done

    echo "Save(\"$SFD_FILE\")" >> "$SCRIPT_FILE"
    echo "Close()" >> "$SCRIPT_FILE"

    step "Running fontforge…"
    fontforge -script "$SCRIPT_FILE"
    rm "$SCRIPT_FILE"
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

# ── assignment ───────────────────────────────────────────────────────────────
_assign_homework_add_file() {
    local target_file="$1"
    local content_file="./assignment/content.json"
    local basename
    basename=$(basename -- "$target_file")
    local name_no_ext="${basename%.*}"

    python3 - "$target_file" "$name_no_ext" "$content_file" <<'PYEOF'
import json, sys

input_file, name_no_ext, content_file = sys.argv[1], sys.argv[2], sys.argv[3]

with open(input_file, 'r', encoding='utf-8') as f:
    text = f.read()

with open(content_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

if isinstance(data['dictionary'], dict):
    data['dictionary'] = ''

for char in text:
    if char in data['dictionary']:
        continue
    data['dictionary'] += char
    key = name_no_ext[:3]
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

assign_homework_reset() {
    local assignment_dir="./assignment"
    if [ ! -d "$assignment_dir" ]; then
        warn "$assignment_dir does not exist — nothing to reset."
        return
    fi
    echo -e "${YELLOW}This will permanently delete ${BOLD}$assignment_dir/${RESET}${YELLOW} and all its contents.${RESET}"
    echo -en "${BOLD}Confirm? [y/N] ${RESET}"
    read -r reply
    case "$reply" in
        [yY][eE][sS]|[yY])
            rm -rf "$assignment_dir"
            info "Deleted $assignment_dir"
            ;;
        *)
            echo "Aborted."
            ;;
    esac
}

assign_homework_process() {
    local force=false
    local target_file=""
    while [[ "${1:-}" == -* ]]; do
        case "$1" in
            -f) force=true; shift ;;
            -n) target_file="$2"; shift 2 ;;
            *)  error "Unknown option: $1"; exit 1 ;;
        esac
    done

    local assignment_dir="./assignment"
    local content_file="$assignment_dir/content.json"
    if $force || [ ! -f "$content_file" ]; then
        mkdir -p "$assignment_dir"
        printf '{\n  "dictionary": "",\n  "assignment": {}\n}\n' > "$content_file"
        info "Created $content_file"
    fi

    if [ -n "$target_file" ]; then
        if [ ! -f "$target_file" ]; then
            error "File not found: $target_file"
            exit 1
        fi
        _assign_homework_add_file "$target_file"
    else
        while IFS= read -r file; do
            _assign_homework_add_file "$file"
        done < <(find . -not -path "./assignment/*" -type f | sort)
    fi
}

# ── dispatch ──────────────────────────────────────────────────────────────────
case "${1:-}" in
    char-2-uni)      char_2_uni ;;
    png-crop)        png_crop ;;
    png-2-pbm)       png_2_pbm ;;
    pbm-2-svg)       pbm_2_svg ;;
    svg-import)      check_font_name; svg_import ;;
    generate)        check_font_name; font_generate ;;
    pipeline)
        check_font_name
        char_2_uni; png_crop; png_2_pbm; pbm_2_svg; svg_import; font_generate
        ;;
    assignment)
        case "${2:-}" in
            reset) assign_homework_reset ;;
            *)     assign_homework_process "${@:2}" ;;
        esac
        ;;
    ""|help|-h|--help) usage ;;
    *)
        error "Unknown command: $1"
        usage
        exit 1
        ;;
esac
