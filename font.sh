#!/bin/bash
# Example of Usage:
    # font char_2_uni
    # font png_crop
    # font png_2_pbm
    # font pbm_2_svg
    # font svg_import
    # font generate
    # font -name <sfd file name> pipeline

VERSION="1.0.0"

ORIGIN_DIR=./src
JSON_DIR=./output/json
PNG_DIR=./output/png
PBM_DIR=./output/pbm
SVG_DIR=./output/svg

TTF_FILE="" # Will be set based on SFD_FILE

# Function to check if font name is provided
check_font_name() {
    if [ -z "$SFD_FILE" ]; then
        echo "Error: -name <font_name> is required for this command."
        exit 1
    fi
}

# Parse command-line options
while [[ "$1" =~ ^- ]]; do
  case "$1" in
    -name)
      SFD_FILE="./$2.sfd"
      TTF_FILE="./output/$2.ttf"
      shift 2
      ;;
    --version|-v)
      echo "$VERSION"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

char_2_uni() {
    mkdir -p "$JSON_DIR"
    for txt_file in "$ORIGIN_DIR"/*.txt; do
        if [ -f "$txt_file" ]; then
            echo "Processing $txt_file..."
            input_string=$(cat "$txt_file")
            json_array=$(echo -n "$input_string" | perl -CS -MJSON -ne 'print encode_json([map { sprintf("uni%04x", ord) } split //])')
            
            filename=$(basename -- "$txt_file")
            filename_no_ext="${filename%.*}"
            json_file="$JSON_DIR/$filename_no_ext.json"
            echo "$json_array" > "$json_file"
            echo "Unicode values saved to $json_file"
        fi
    done
}

png_crop() {
    rm -rf "$PNG_DIR"
    mkdir -p "$PNG_DIR"

    for input_file in "$ORIGIN_DIR"/*.png; do
        if [ ! -f "$input_file" ]; then
            continue
        fi

        echo "Processing $input_file..."

        local filename=$(basename -- "$input_file")
        local filename_no_ext="${filename%.*}"
        local json_file="$JSON_DIR/$filename_no_ext.json"

        if [ ! -f "$json_file" ]; then
            echo "Warning: JSON file not found for $input_file. Skipping."
            continue
        fi

        local names=()
        while IFS= read -r line; do
            names+=("$line")
        done < <(jq -r '.[]' "$json_file")

        local temp_crop_dir=$(mktemp -d)
        echo "Cropping $input_file into temporary directory $temp_crop_dir..."
        magick "$input_file" -crop 200x200 +repage +adjoin "$temp_crop_dir/%02d.png"

        echo "Renaming and moving cropped images..."
        local i=0
        for file in $(find "$temp_crop_dir" -name "*.png" | sort); do
            if [ -n "${names[$i]}" ]; then
                local new_name="${names[$i]}.png"
                mv "$file" "$PNG_DIR/$new_name"
                echo "Created $PNG_DIR/$new_name"
            else
                echo "Warning: No name found for $file at index $i. Deleting file."
                rm "$file"
            fi
            i=$((i+1))
        done
        rm -r "$temp_crop_dir"
    done

    echo "Cropping and renaming complete. All files are in $PNG_DIR"
}

png_2_pbm() {
    mkdir -p "$PBM_DIR"
    for file in "$PNG_DIR"/*.png; do
        echo "Converting $file to PBM..."
        _png_to_pbm "$file" "$PBM_DIR"
    done
}

pbm_2_svg() {
    mkdir -p "$SVG_DIR"
    for file in "$PBM_DIR"/*.pbm; do
        echo "Converting $file to SVG..."
        _pbm_to_svg "$file" "$SVG_DIR"
    done
}

_png_to_pbm(){
    local filename=$(basename -- "$1")
    local filename_no_ext="${filename%.*}"
    magick "$1" -background white -alpha remove -colorspace Gray "$2/$filename_no_ext.pbm"
}

_pbm_to_svg(){
    local filename=$(basename -- "$1")
    local filename_no_ext="${filename%.*}"
    potrace "$1" -s -o "$2/$filename_no_ext.svg"
}

svg_import() {
    SCRIPT_FILE=$(mktemp)
    
    if [ ! -f "$SFD_FILE" ]; then
        echo "SFD file not found: $SFD_FILE. Creating a new one."
        local sfd_basename=$(basename -- "$SFD_FILE")
        local font_name="${sfd_basename%.*}"
        # PostScript name cannot contain spaces.
        local postscript_name=$(echo "$font_name" | tr -d ' ')

        {
            echo "New()"
            echo 'Reencode("UnicodeFull")'
            # Set core font names: PostScript, Family Name, and Full Name (Name for Humans)
            echo "SetFontNames(\"$postscript_name\", \"$font_name\", \"$font_name\")"

            # Set TTF naming table for English (0x409) for maximum compatibility
            echo "SetTTFName(0x409, 1, \"$font_name\")"      # 1: Font Family Name
            echo "SetTTFName(0x409, 2, \"Regular\")"         # 2: Font Subfamily Name
            echo "SetTTFName(0x409, 4, \"$font_name\")"      # 4: Full Font Name
            echo "SetTTFName(0x409, 5, \"$VERSION\")"        # 5: Version
            echo "SetTTFName(0x409, 6, \"$postscript_name\")" # 6: PostScript Name
            echo "SetTTFName(0x409, 7, \"Private\")"         # 7: Trademark

            # Set TTF naming table for Chinese, PRC (0x804)
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
        local filename=$(basename -- "$file")
        local filename_no_ext="${filename%.*}"
        # filename is like uniXXXX
        local unicode_hex=${filename_no_ext:3}
        echo "Select(0x$unicode_hex); Clear(); Import(\"$file\"); Scale(150); Move(250, 0);" >> "$SCRIPT_FILE"
        echo "Processing $file for U+$unicode_hex"
    done

    echo "Save(\"$SFD_FILE\")" >> "$SCRIPT_FILE"
    echo "Close()" >> "$SCRIPT_FILE"

    echo "Running fontforge script to generate SFD..."
    fontforge -script "$SCRIPT_FILE"
    
    rm "$SCRIPT_FILE"
    echo "Fontforge script finished. SFD file saved at $SFD_FILE"
}

font_generate() {
    if [ ! -f "$SFD_FILE" ]; then
        echo "SFD file not found: $SFD_FILE"
        exit 1
    fi

    echo "Generating TTF font..."
    fontforge -script -c "import fontforge; font = fontforge.open('$SFD_FILE'); font.generate('$TTF_FILE'); font.close()"
    echo "TTF font generated at $TTF_FILE"
}

case "$1" in
    "png_2_pbm")
        png_2_pbm
        ;;
    "png_crop")
        png_crop
        ;;
    "pbm_2_svg")
        pbm_2_svg
        ;;
    "char_2_uni")
        char_2_uni
        ;;
    "svg_import")
        check_font_name
        svg_import
        ;;
    "generate")
        check_font_name
        font_generate
        ;;
    pipeline)
        check_font_name
        char_2_uni
        png_crop
        png_2_pbm
        pbm_2_svg
        svg_import
        font_generate
        ;;
    *)
        echo "Usage: font [--version|-v] [-name <filename>] [char_2_uni|png_crop|png_2_pbm|pbm_2_svg|svg_import|generate]|pipeline"
        exit 1
        ;;
esac
