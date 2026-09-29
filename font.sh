#!/bin/bash

VERSION="1.2.0"

# ══ CONFIGURATION ════════════════════════════════════════════════════════════
# Assignment practice sheet — directories
ASSIGN_FONT_TEXT_DIR_DEFAULT="./text"    # source .txt files
ASSIGN_FONT_HANDOUT_DIR_DEFAULT="./handout" # output: content.json and PNGs
ASSIGN_DICT_DIR_DEFAULT="../font"             # shared dictionary.json across books
ASSIGN_BOOK_NAME_DEFAULT="myBook"          # book id written into content.json

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
TYPEFACE_FONT_DIR_DEFAULT="../font"   # .sfd, .ttf and temp/ subdirectory
TYPEFACE_FONT_NAME_DEFAULT="myfont"
PUBLISH_HTML_DIR_DEFAULT="./html"
PUBLISH_EPUB_DIR_DEFAULT="./epub"
PUBLISH_EPUB_NAME_DEFAULT="myEpub"
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
${BOLD}font${RESET} v${VERSION}  —  typeface builder & practice-sheet generator

${BOLD}USAGE${RESET}
  font [-v] <command> [subcommand] [options]

${BOLD}COMMANDS${RESET}
  ${CYAN}assignment${RESET}   Generate practice sheets (content.json + PNGs)
  ${CYAN}typeface${RESET}     Build TTF font from handwritten PNGs
  ${CYAN}publish${RESET}      Publish font or generate HTML/EPUB
  ${CYAN}point${RESET}        Track writing and reading points

──────────────────────────────────────────────────────────────
${BOLD}font assignment${RESET} [subcommand] [options]
  ${DIM}(no sub)${RESET}      Pipeline: [reset?] → content → png
  ${CYAN}content${RESET}      Append lessons to handout/content.json
  ${CYAN}png${RESET}          Render practice-sheet PNGs
  ${CYAN}reset${RESET}        Clear handout folder or delete a lesson's PNGs

  ${YELLOW}-text <path>${RESET}      .txt source file or folder    ${DIM}[./text]${RESET}
  ${YELLOW}-handout <dir>${RESET}    output / content.json folder  ${DIM}[./handout]${RESET}
  ${YELLOW}-dict-dir <dir>${RESET}   shared dictionary folder      ${DIM}[../font]${RESET}
  ${YELLOW}-book <id>${RESET}        book id stored in content     ${DIM}[myBook]${RESET}

──────────────────────────────────────────────────────────────
${BOLD}font typeface${RESET} [subcommand] [options]
  ${DIM}(no sub)${RESET}      Full pipeline: char-2-uni → png-crop → png-2-pbm
                 → pbm-2-svg → svg-import → generate → cleanup
  ${CYAN}char-2-uni${RESET}   PNG filename → Unicode JSON
  ${CYAN}png-crop${RESET}     Crop handin PNGs → per-glyph 200×200
  ${CYAN}png-2-pbm${RESET}    PNG → PBM bitmaps
  ${CYAN}pbm-2-svg${RESET}    PBM → SVG outlines
  ${CYAN}svg-import${RESET}   SVG → FontForge .sfd
  ${CYAN}generate${RESET}     .sfd → .ttf
  ${CYAN}cleanup${RESET}      Delete temp/

  ${YELLOW}-handin <path>${RESET}    source PNGs (file or folder)  ${DIM}[./handin]${RESET}
  ${YELLOW}-font-name <n>${RESET}    .sfd / .ttf base name         ${DIM}[myfont]${RESET}
  ${YELLOW}-font-dir <dir>${RESET}   output for .sfd, .ttf, temp/  ${DIM}[../font]${RESET}
  ${YELLOW}-handout <dir>${RESET}    content.json source           ${DIM}[./handout]${RESET}

──────────────────────────────────────────────────────────────
${BOLD}font publish${RESET} <subcommand> [options]
  ${CYAN}mac${RESET}          Install TTF → ~/Library/Fonts
  ${CYAN}html${RESET}         Generate HTML files using the built font
  ${CYAN}epub${RESET}         Generate EPUB using the built font

  ${YELLOW}-font-name <n>${RESET}    font base name                ${DIM}[myfont]${RESET}
  ${YELLOW}-font-dir <dir>${RESET}   folder containing .ttf        ${DIM}[../font]${RESET}
  ${YELLOW}-text <path>${RESET}      .txt source file or folder    ${DIM}[./text]${RESET}
  ${YELLOW}-html-dir <dir>${RESET}   HTML output folder            ${DIM}[./html]${RESET}
  ${YELLOW}-epub-dir <dir>${RESET}   EPUB output folder            ${DIM}[./epub]${RESET}
  ${YELLOW}-epub-name <n>${RESET}    EPUB filename (no .epub)      ${DIM}[myEpub]${RESET}
  ${YELLOW}-dest <dir>${RESET}       mac install destination       ${DIM}[~/Library/Fonts]${RESET}

──────────────────────────────────────────────────────────────
${BOLD}font point${RESET} <subcommand> [options]
  ${CYAN}add-write${RESET}    Scan handin → update point-font, then recalculate
  ${CYAN}add-read${RESET}     Mark a text as read → update point-read, then recalculate
  ${CYAN}update${RESET}       Recalculate total and available from stored data
  ${CYAN}redeem${RESET}       Log a redemption, then recalculate

  ${YELLOW}-handin <dir>${RESET}     handin folder                 ${DIM}[./handin]${RESET}
  ${YELLOW}-handout <dir>${RESET}    content.json folder           ${DIM}[./handout]${RESET}
  ${YELLOW}-dict-dir <dir>${RESET}   points.json folder            ${DIM}[../font]${RESET}
  ${YELLOW}-text <file>${RESET}      text file to mark read        ${DIM}(add-read)${RESET}
  ${YELLOW}-hour <n>${RESET}         hours redeemed; points=n×36  ${DIM}(redeem)${RESET}
  ${YELLOW}-halfday${RESET}          half-day; points=60          ${DIM}(redeem)${RESET}
  ${YELLOW}-point <n>${RESET}        points redeemed directly      ${DIM}(redeem)${RESET}

──────────────────────────────────────────────────────────────
${BOLD}EXAMPLES${RESET}
  ${DIM}font assignment -book gwgz${RESET}
  ${DIM}font typeface -font-name Kexin${RESET}
  ${DIM}font publish html -font-name Kexin${RESET}
  ${DIM}font publish epub -font-name Kexin -epub-name 古文观止-可心手抄本${RESET}
  ${DIM}font point add-write${RESET}
  ${DIM}font point add-read -text ./text/done/008_曹刿论战.txt${RESET}
  ${DIM}font point redeem -hour 2${RESET}
"
}

# ── helpers ───────────────────────────────────────────────────────────────────
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
        python3 - "$content_file" "$key" "$json_out" "$filename" <<'PYEOF'
import json, sys, re

content_file, key, json_out = sys.argv[1], sys.argv[2], sys.argv[3]
filename = sys.argv[4] if len(sys.argv) > 4 else ''

CHARS_PER_PAGE = 12 * 5  # COLS * ROWS, must match png_crop layout

with open(content_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

all_chars = data.get('assignment', {}).get(key, '')
if not all_chars:
    print(f"Key '{key}' not found in assignment", file=sys.stderr)
    sys.exit(1)

page_match = re.search(r'_p(\d+)\.[^.]+$', filename)
page_num = int(page_match.group(1)) if page_match else 1
offset = (page_num - 1) * CHARS_PER_PAGE
chars = all_chars[offset:offset + CHARS_PER_PAGE]

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
            echo "SetOS2Value('WinAscent', 860)"
            echo "SetOS2Value('WinDescent', 140)"
            echo "SetOS2Value('TypoAscent', 860)"
            echo "SetOS2Value('TypoDescent', -140)"
            echo "SetOS2Value('HHeadAscent', 860)"
            echo "SetOS2Value('HHeadDescent', -140)"
        } > "$script_file"
    else
        echo "Open(\"$SFD_FILE\")" > "$script_file"
    fi
    for file in "$TYPEFACE_SVG_DIR"/*.svg; do
        local filename filename_no_ext unicode_hex
        filename=$(basename -- "$file")
        filename_no_ext="${filename%.*}"
        unicode_hex="${filename_no_ext:3}"
        echo "Select(0x$unicode_hex); Clear(); Import(\"$file\"); Scale(200); SetWidth(1000); CenterInWidth();" >> "$script_file"
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
            -handout) ASSIGN_FONT_HANDOUT_DIR="$2"; shift 2 ;;
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
        svg-import) svg_import ;;
        generate)   font_generate ;;
        cleanup)
            if [ -d "$TYPEFACE_TEMP_DIR" ]; then
                rm -rf "$TYPEFACE_TEMP_DIR"
                info "Removed $TYPEFACE_TEMP_DIR"
            else
                warn "$TYPEFACE_TEMP_DIR does not exist — nothing to clean."
            fi
            ;;
        "")
            char_2_uni; png_crop; png_2_pbm; pbm_2_svg; svg_import; font_generate
            rm -rf "$TYPEFACE_TEMP_DIR" && info "Removed $TYPEFACE_TEMP_DIR"
            ;;
        *) error "Unknown typeface subcommand: $1"; usage; exit 1 ;;
    esac
}

# ── assignment ────────────────────────────────────────────────────────────────
_assign_add_file() {
    local target_file="$1"
    local dict_dir="$2"
    local book_name="$3"
    local content_file="$ASSIGN_FONT_HANDOUT_DIR/content.json"
    local name_no_ext
    name_no_ext=$(basename -- "$target_file")
    name_no_ext="${name_no_ext%.*}"
    python3 - "$target_file" "$name_no_ext" "$content_file" "$dict_dir" "$book_name" <<'PYEOF'
import json, sys, os

input_file, name_no_ext, content_file, dict_dir, book_name = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]

with open(input_file, 'r', encoding='utf-8') as f:
    text = f.read()
with open(content_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

dict_file = os.path.join(dict_dir, 'dictionary.json')
if os.path.exists(dict_file):
    with open(dict_file, 'r', encoding='utf-8') as f:
        dict_data = json.load(f)
else:
    os.makedirs(dict_dir, exist_ok=True)
    dict_data = {"index": "", "assignment": []}

# migrate: remove old dictionary key if present
data.pop('dictionary', None)
data['book'] = book_name

key = name_no_ext[:3]
data.setdefault('names', {})[key] = name_no_ext

assignment_map = data.setdefault('assignment', {})
if isinstance(assignment_map, list):
    assignment_map = {}
    data['assignment'] = assignment_map
if key not in assignment_map:
    assignment_map[key] = ''
elif isinstance(assignment_map[key], list):
    assignment_map[key] = ''.join(assignment_map[key])

seen_chars = set(assignment_map[key])
char_sources = {}
for idx, char in enumerate(dict_data.get('index', '')):
    source = None
    if idx < len(dict_data.get('assignment', [])):
        source = dict_data['assignment'][idx]
    char_sources[char] = source

for char in text:
    if char.isspace() or char in seen_chars:
        continue
    source = char_sources.get(char)
    if source is None:
        dict_data['index'] += char
        source = {"book": book_name, "text": key}
        dict_data['assignment'].append(source)
        char_sources[char] = source
    if isinstance(source, dict) and source.get('book') == book_name:
        assignment_map[key] += char
        seen_chars.add(char)

with open(content_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
with open(dict_file, 'w', encoding='utf-8') as f:
    json.dump(dict_data, f, ensure_ascii=False, indent=2)
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
    local dict_dir="$ASSIGN_DICT_DIR_DEFAULT"
    local book_name="$ASSIGN_BOOK_NAME_DEFAULT"
    while [[ "${1:-}" == -* ]]; do
        case "$1" in
            -text)     src="$2"; shift 2 ;;
            -handout)  ASSIGN_FONT_HANDOUT_DIR="$2"; shift 2 ;;
            -dict-dir) dict_dir="$2"; shift 2 ;;
            -book)     book_name="$2"; shift 2 ;;
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
        printf '{\n  "book": "%s",\n  "names": {},\n  "assignment": {}\n}\n' "$book_name" > "$content_file"
        info "Created $content_file"
    fi

    if [ -f "$src" ]; then
        _assign_add_file "$src" "$dict_dir" "$book_name"
    else
        while IFS= read -r file; do
            _assign_add_file "$file" "$dict_dir" "$book_name"
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
            filter_keys=$(find "$src" -type f -name "*.txt" | sort | while IFS= read -r f; do _lesson_key_from_path "$f"; done | paste -sd, -)
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
            local text_arg="" dict_dir="$ASSIGN_DICT_DIR_DEFAULT" book_name="$ASSIGN_BOOK_NAME_DEFAULT"
            while [[ "${1:-}" == -* ]]; do
                case "$1" in
                    -text)     text_arg="$2"; shift 2 ;;
                    -handout)  ASSIGN_FONT_HANDOUT_DIR="$2"; shift 2 ;;
                    -dict-dir) dict_dir="$2"; shift 2 ;;
                    -book)     book_name="$2"; shift 2 ;;
                    *) error "Unknown option: $1"; exit 1 ;;
                esac
            done
            echo -en "${BOLD}Reset before generating? [y/N] ${RESET}"
            read -r do_reset
            case "$do_reset" in
                [yY][eE][sS]|[yY])
                    assign_reset
                    ;;
            esac
            assign_content ${text_arg:+-text "$text_arg"} -dict-dir "$dict_dir" -book "$book_name"
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
    font-size: 2rem;
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
            local html_dir="$PUBLISH_HTML_DIR_DEFAULT"
            local font_name_arg=""
            while [[ "${1:-}" == -* ]]; do
                case "$1" in
                    -text)      src="$2"; shift 2 ;;
                    -html-dir)  html_dir="$2"; shift 2 ;;
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
            mkdir -p "$html_dir"
            if [ -f "$src" ]; then
                local base
                base=$(basename "$src" .txt)
                _publish_html_one "$src" "$html_dir/$base.html" "$abs_ttf" "$font_family"
            else
                while IFS= read -r txt_file; do
                    local rel out_file
                    rel="${txt_file#${src%/}/}"
                    out_file="$html_dir/${rel%.txt}.html"
                    _publish_html_one "$txt_file" "$out_file" "$abs_ttf" "$font_family"
                done < <(find "$src" -type f -name "*.txt" | sort)
            fi
            info "Done → $html_dir"
            ;;
        epub)
            local src="$ASSIGN_FONT_TEXT_DIR_DEFAULT"
            local epub_dir="$PUBLISH_EPUB_DIR_DEFAULT"
            local font_name_arg=""
            local epub_name="$PUBLISH_EPUB_NAME_DEFAULT"
            while [[ "${1:-}" == -* ]]; do
                case "$1" in
                    -text)      src="$2"; shift 2 ;;
                    -epub-dir)  epub_dir="$2"; shift 2 ;;
                    -font-name) font_name_arg="$2"; shift 2 ;;
                    -font-dir)  TYPEFACE_FONT_DIR="$2"; shift 2 ;;
                    -epub-name) epub_name="$2"; shift 2 ;;
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
            mkdir -p "$epub_dir"
            local txt_files=()
            if [ -f "$src" ]; then
                txt_files=("$src")
            else
                while IFS= read -r f; do txt_files+=("$f"); done < <(find "$src" -type f -name "*.txt" | sort)
            fi
            python3 - "$abs_ttf" "$font_family" "$epub_dir/$epub_name.epub" "$epub_name" "${txt_files[@]}" <<'PYEOF'
import sys, os, html as _html, zipfile, uuid, base64
from datetime import datetime

ttf_path, font_family, epub_out, book_title_raw = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
txt_files = sys.argv[5:]

book_id = str(uuid.uuid4())
now = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

chapters = []
for txt_file in txt_files:
    base = os.path.splitext(os.path.basename(txt_file))[0]
    with open(txt_file, 'r', encoding='utf-8') as f:
        text = f.read()
    chapters.append({'title': base, 'text': text})

with open(ttf_path, 'rb') as f:
    font_b64 = base64.b64encode(f.read()).decode('ascii')

css = f"""@font-face {{
  font-family: '{font_family}';
  src: url('data:font/truetype;base64,{font_b64}') format('truetype');
}}
body {{
  font-family: '{font_family}', 'Kaiti SC', 'STKaiti', 'KaiTi', serif;
  font-size: 2rem;
  line-height: 2;
  padding: 2rem;
  background: #fff;
  color: #222;
}}
h1 {{ font-family: '{font_family}', 'Kaiti SC', 'STKaiti', 'KaiTi', serif; font-size: 2rem; margin-bottom: 1.5rem; color: #666; font-weight: normal; }}
pre {{ font-family: inherit; white-space: pre-wrap; word-break: break-all; margin: 0; }}
nav ol {{ list-style: none; padding: 0; margin: 0; }}
nav ol li {{ margin: 0.4em 0; }}
nav ol li a {{ font-family: '{font_family}', 'Kaiti SC', 'STKaiti', 'KaiTi', serif; color: #222; text-decoration: none; }}"""

with zipfile.ZipFile(epub_out, 'w', zipfile.ZIP_DEFLATED) as zf:
    info = zipfile.ZipInfo('mimetype')
    info.compress_type = zipfile.ZIP_STORED
    zf.writestr(info, 'application/epub+zip')

    zf.writestr('META-INF/container.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''')

    zf.writestr('OEBPS/styles/style.css', css)

    chapter_items = []
    for i, ch in enumerate(chapters, 1):
        chid = f'chapter{i:03d}'
        chfile = f'text/{chid}.xhtml'
        xhtml = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="zh">
<head>
<meta charset="utf-8"/>
<title>{_html.escape(ch['title'])}</title>
<link rel="stylesheet" type="text/css" href="../styles/style.css"/>
</head>
<body>
<h1>{_html.escape(ch['title'])}</h1>
<pre>{_html.escape(ch['text'])}</pre>
</body>
</html>'''
        zf.writestr(f'OEBPS/{chfile}', xhtml)
        chapter_items.append({'id': chid, 'href': chfile, 'title': ch['title']})

    toc_entries = '\n    '.join(
        f'<li><a href="{c["href"]}">{_html.escape(c["title"])}</a></li>'
        for c in chapter_items
    )
    zf.writestr('OEBPS/nav.xhtml', f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="zh">
<head><meta charset="utf-8"/><title>目录</title>
<link rel="stylesheet" type="text/css" href="styles/style.css"/>
</head>
<body>
<h1>目录</h1>
<nav epub:type="toc">
<ol>
    {toc_entries}
</ol>
</nav>
</body>
</html>''')

    book_title = _html.escape(book_title_raw)
    manifest_items = '\n    '.join([
        f'<item id="css" href="styles/style.css" media-type="text/css"/>',
        f'<item id="nav" href="nav.xhtml"        media-type="application/xhtml+xml" properties="nav"/>',
    ] + [
        f'<item id="{c["id"]}" href="{c["href"]}" media-type="application/xhtml+xml"/>'
        for c in chapter_items
    ])
    spine_items = '\n    '.join(f'<itemref idref="{c["id"]}"/>' for c in chapter_items)
    zf.writestr('OEBPS/content.opf', f'''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="uid">{book_id}</dc:identifier>
    <dc:title>{book_title}</dc:title>
    <dc:language>zh</dc:language>
    <meta property="dcterms:modified">{now}</meta>
  </metadata>
  <manifest>
    {manifest_items}
  </manifest>
  <spine>
    <itemref idref="nav" linear="yes"/>
    {spine_items}
  </spine>
</package>''')

print(f"Saved {epub_out}")
PYEOF
            local py_exit=$?
            [ $py_exit -ne 0 ] && { error "EPUB generation failed (exit $py_exit)."; exit 1; }
            info "Done → $epub_dir/$epub_name.epub"
            ;;
        "") error "publish requires a subcommand (e.g. 'mac', 'html', 'epub')"; usage; exit 1 ;;
        *)  error "Unknown publish subcommand: $subcommand"; usage; exit 1 ;;
    esac
}

# ── point-write ───────────────────────────────────────────────────────────────
point_write_run() {
    local handin_dir="$TYPEFACE_HANDIN_DIR_DEFAULT"
    local dict_dir="$ASSIGN_DICT_DIR_DEFAULT"
    local handout_dir="$ASSIGN_FONT_HANDOUT_DIR_DEFAULT"
    while [[ "${1:-}" == -* ]]; do
        case "$1" in
            -handin)   handin_dir="$2"; shift 2 ;;
            -dict-dir) dict_dir="$2"; shift 2 ;;
            -handout)  handout_dir="$2"; shift 2 ;;
            *) error "Unknown option: $1"; exit 1 ;;
        esac
    done

    if [ ! -f "$handin_dir" ] && [ ! -d "$handin_dir" ]; then
        error "Handin path not found: $handin_dir"
        exit 1
    fi

    echo -e "${YELLOW}This will replace all write points for ${BOLD}$(basename "$PWD")${RESET}${YELLOW}.${RESET}"
    echo -en "${BOLD}Confirm? [y/N] ${RESET}"
    read -r reply
    case "$reply" in
        [yY][eE][sS]|[yY]) ;;
        *) echo "Aborted."; exit 0 ;;
    esac

    local content_file="$handout_dir/content.json"
    if [ ! -f "$content_file" ]; then
        error "content.json not found: $content_file — run 'font assignment content' first."
        exit 1
    fi

    local points_file="$dict_dir/points.json"

    local book_name
    book_name="$(basename "$PWD")"
    python3 - "$handin_dir" "$content_file" "$points_file" "$book_name" <<'PYEOF'
import json, sys, os, re
from datetime import datetime

handin_dir, content_file, points_file, book_name = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

CHARS_PER_PAGE = 60

with open(content_file, 'r', encoding='utf-8') as f:
    content = json.load(f)
assignment = content.get('assignment', {})

if os.path.isfile(handin_dir):
    png_files = [(os.path.basename(handin_dir), os.path.abspath(handin_dir))]
else:
    png_files = [(f, os.path.join(handin_dir, f)) for f in os.listdir(handin_dir)]

entries = []
for fname, fpath in png_files:
    if not fname.endswith('.png'):
        continue
    m = re.match(r'^(\d{3}).*_p(\d+)\.png$', fname)
    if not m:
        continue
    key, page = m.group(1), int(m.group(2))
    stat = os.stat(fpath)
    ctime = getattr(stat, 'st_birthtime', stat.st_mtime)
    entries.append({'name': fname, 'key': key, 'page': page, 'ctime': ctime})

entries.sort(key=lambda x: x['ctime'])

history = []
lesson_pages = {}

for e in entries:
    key, page = e['key'], e['page']
    chars = assignment.get(key, '')
    start = (page - 1) * CHARS_PER_PAGE
    page_points = len(chars[start:start + CHARS_PER_PAGE])
    lesson_pages.setdefault(key, set()).add(page)
    history.append({
        'name': e['name'],
        'time': datetime.fromtimestamp(e['ctime']).strftime('%Y-%m-%d %H:%M:%S'),
        'points': page_points,
    })

for key in sorted(lesson_pages):
    pages = lesson_pages[key]
    chars = assignment.get(key, '')
    print(f"  {key}: {len(pages)} page(s), {sum(len(chars[(p-1)*CHARS_PER_PAGE:p*CHARS_PER_PAGE]) for p in pages)} chars")

if os.path.exists(points_file):
    with open(points_file, 'r', encoding='utf-8') as f:
        points = json.load(f)
else:
    points = {}

if 'redeem' not in points:
    points['redeem'] = []

pf = points.get('point-font', {})
if isinstance(pf, list):
    from collections import defaultdict
    migrated = defaultdict(list)
    for e in pf:
        migrated[e.get('book', 'unknown')].append(e)
    pf = dict(migrated)
pf[book_name] = history
points['point-font'] = pf

os.makedirs(os.path.dirname(os.path.abspath(points_file)), exist_ok=True)
with open(points_file, 'w', encoding='utf-8') as f:
    json.dump(points, f, ensure_ascii=False, indent=2)
PYEOF
    local py_exit=$?
    [ $py_exit -ne 0 ] && { error "Calculation failed (exit $py_exit)."; exit 1; }
    info "Updated $points_file"
    point_update_run -dict-dir "$dict_dir"
}

# ── point-update ──────────────────────────────────────────────────────────────
point_update_run() {
    local dict_dir="$ASSIGN_DICT_DIR_DEFAULT"
    while [[ "${1:-}" == -* ]]; do
        case "$1" in
            -dict-dir) dict_dir="$2"; shift 2 ;;
            *) error "Unknown option: $1"; exit 1 ;;
        esac
    done

    local points_file="$dict_dir/points.json"
    if [ ! -f "$points_file" ]; then
        error "points.json not found: $points_file — run 'font point add-write' first."
        exit 1
    fi

    python3 - "$points_file" <<'PYEOF'
import json, sys

points_file = sys.argv[1]

with open(points_file, 'r', encoding='utf-8') as f:
    points = json.load(f)

pf = points.get('point-font', {})
if isinstance(pf, list):
    font_total = sum(e.get('points', 0) for e in pf)
else:
    font_total = sum(e.get('points', 0) for book_entries in pf.values() for e in book_entries)
read_total = sum(v.get('points', 0) for book_entries in points.get('point-read', {}).values() for v in book_entries.values())
total = font_total + read_total
redeemed = sum(e.get('points', 0) for e in points.get('redeem', []))
available = total - redeemed

points['total'] = total
points['available'] = available

with open(points_file, 'w', encoding='utf-8') as f:
    json.dump(points, f, ensure_ascii=False, indent=2)

print(f"Total: {total} (write: {font_total}, read: {read_total}), redeemed: {redeemed}, available: {available}")
PYEOF
    local py_exit=$?
    [ $py_exit -ne 0 ] && { error "Update failed (exit $py_exit)."; exit 1; }
    info "Updated $points_file"
}

# ── point-read ────────────────────────────────────────────────────────────────
point_read_run() {
    local src=""
    local dict_dir="$ASSIGN_DICT_DIR_DEFAULT"
    while [[ "${1:-}" == -* ]]; do
        case "$1" in
            -text)     src="$2"; shift 2 ;;
            -dict-dir) dict_dir="$2"; shift 2 ;;
            *) error "Unknown option: $1"; exit 1 ;;
        esac
    done

    if [ -z "$src" ]; then
        error "read requires -text <path>"
        exit 1
    fi
    if [ ! -f "$src" ]; then
        error "File not found: $src"
        exit 1
    fi

    local points_file="$dict_dir/points.json"
    local book_name
    book_name="$(basename "$PWD")"

    python3 - "$src" "$points_file" "$book_name" <<'PYEOF'
import json, sys, os
from datetime import datetime

src, points_file, book_name = sys.argv[1], sys.argv[2], sys.argv[3]

with open(src, 'r', encoding='utf-8') as f:
    text = f.read()
no_of_char = sum(1 for c in text if not c.isspace())

if os.path.exists(points_file):
    with open(points_file, 'r', encoding='utf-8') as f:
        points = json.load(f)
else:
    points = {}

pr = points.get('point-read', {})
if isinstance(pr, dict) and pr:
    first_val = next(iter(pr.values()))
    if isinstance(first_val, dict) and 'points' in first_val:
        pr = {book_name: pr}

key = os.path.splitext(os.path.basename(src))[0][:3]

book_entries = pr.get(book_name, {})
if key in book_entries:
    print(f"error: {key} already recorded — will not overwrite", file=sys.stderr)
    sys.exit(1)

root_dir = os.path.dirname(os.path.dirname(os.path.abspath(points_file)))
text_rel = os.path.relpath(os.path.abspath(src), root_dir)

book_entries[key] = {
    'time': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
    'text': text_rel,
    'no-of-char': no_of_char,
    'points': (no_of_char + 19) // 20,
}
pr[book_name] = book_entries
points['point-read'] = pr

os.makedirs(os.path.dirname(os.path.abspath(points_file)), exist_ok=True)
with open(points_file, 'w', encoding='utf-8') as f:
    json.dump(points, f, ensure_ascii=False, indent=2)

print(f"{key}: {no_of_char} chars, {(no_of_char + 19) // 20} points")
PYEOF
    local py_exit=$?
    [ $py_exit -ne 0 ] && { error "fail to add points"; exit 1; }
    info "Updated $points_file"
    point_update_run -dict-dir "$dict_dir"
}

# ── point-redeem ──────────────────────────────────────────────────────────────
point_redeem_run() {
    local dict_dir="$ASSIGN_DICT_DIR_DEFAULT"
    local hour="" point_arg="" message="" halfday=""
    while [[ "${1:-}" == -* ]]; do
        case "$1" in
            -hour)     hour="$2"; shift 2 ;;
            -point)    point_arg="$2"; shift 2 ;;
            -halfday)  halfday=1; shift ;;
            -m)        message="$2"; shift 2 ;;
            -dict-dir) dict_dir="$2"; shift 2 ;;
            *) error "Unknown option: $1"; exit 1 ;;
        esac
    done

    local _h=0 _p=0 _d=0
    [ -n "$hour" ]      && _h=1
    [ -n "$point_arg" ] && _p=1
    [ -n "$halfday" ]   && _d=1
    local provided=$(( _h + _p + _d ))
    if [ "$provided" -eq 0 ]; then
        error "point redeem requires one of: -halfday, -hour <n>, -point <n>"
        exit 1
    fi
    if [ "$provided" -gt 1 ]; then
        error "point redeem: only one of -halfday, -hour, -point may be used"
        exit 1
    fi

    local points_file="$dict_dir/points.json"

    python3 - "$points_file" "$hour" "$point_arg" "$message" "$halfday" <<'PYEOF'
import json, sys, os
from datetime import datetime

points_file, hour_arg, point_arg, message, halfday = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]

now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

if halfday:
    pts = 60
    record = {'time': now, 'halfday': True, 'points': pts}
elif hour_arg:
    hour = float(hour_arg)
    pts = round(hour * 36)
    record = {'time': now, 'hour': hour, 'points': pts}
else:
    pts = int(point_arg)
    record = {'time': now, 'points': pts}

if message:
    record['message'] = message

if os.path.exists(points_file):
    with open(points_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
else:
    data = {}

data.setdefault('redeem', []).append(record)

os.makedirs(os.path.dirname(os.path.abspath(points_file)), exist_ok=True)
with open(points_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"Redeemed: {pts} points")
PYEOF
    local py_exit=$?
    [ $py_exit -ne 0 ] && { error "Redeem failed (exit $py_exit)."; exit 1; }
    info "Updated $points_file"
    point_update_run -dict-dir "$dict_dir"
}

# ── point dispatcher ──────────────────────────────────────────────────────────
point_run() {
    local subcommand=""
    if [[ "${1:-}" != -* ]]; then subcommand="${1:-}"; shift 2>/dev/null || true; fi
    case "$subcommand" in
        add-write) point_write_run "$@" ;;
        add-read)  point_read_run "$@" ;;
        update)    point_update_run "$@" ;;
        redeem)    point_redeem_run "$@" ;;
        "")        error "point requires a subcommand (add-write, add-read, update, redeem)"; usage; exit 1 ;;
        *)         error "Unknown point subcommand: $subcommand"; usage; exit 1 ;;
    esac
}

# ── dispatch ──────────────────────────────────────────────────────────────────
case "${1:-}" in
    typeface)   shift; typeface_run "$@" ;;
    assignment) shift; assignment_run "$@" ;;
    publish)    shift; publish_run "$@" ;;
    point)      shift; point_run "$@" ;;
    ""|help|-h|--help) usage ;;
    *) error "Unknown command: $1"; usage; exit 1 ;;
esac
