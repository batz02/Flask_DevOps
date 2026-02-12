#!/bin/bash

POST_DIR="posts/en"
IMG_DIR="static/assets/blog-images" 

EXIT_CODE=0

echo "Starting Markdown Validity Check..."

if [ ! -d "$POST_DIR" ]; then
    echo "Error: Directory $POST_DIR not found!"
    exit 1
fi

REQUIRED_FIELDS=("title:" "subtitle:" "author:" "author_image:" "date:" "permalink:" "tags:" "shortcontent:")

validate_file() {
    local file=$1
    local filename=$(basename "$file")
    local file_errors=0

    if ! grep -q "\-\-\-" "$file"; then
        echo -e "[$filename] \033[0;31mFAIL\033[0m: Missing '---' separator."
        return 1
    fi

    header=$(sed -n '1,/^---$/p' "$file")

    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! echo "$header" | grep -q "^$field"; then
            echo -e "[$filename] \033[0;31mFAIL\033[0m: Missing required field '$field'."
            file_errors=1
        fi
    done

    date_line=$(echo "$header" | grep "^date:")
    
    if [[ ! -z "$date_line" ]]; then
        date_value=$(echo "$date_line" | cut -d':' -f2- | sed 's/^[ \t]*//;s/[ \t]*$//')
        
        if ! [[ "$date_value" =~ ^[A-Z][a-z]+\ [0-9]{1,2},\ [0-9]{4}$ ]]; then
            echo -e "[$filename] \033[0;31mFAIL\033[0m: Invalid date format '$date_value'. Expected '%B %d, %Y' (e.g. November 2, 2022)."
            file_errors=1
        fi
    fi

    img_lines=$(echo "$header" | grep -E "^(image|author_image):")
    
    while read -r line; do
        if [ ! -z "$line" ]; then
            img_name=$(echo "$line" | cut -d':' -f2- | sed 's/^[ \t]*//;s/[ \t]*$//')
            
            if [ ! -z "$img_name" ]; then
                if [ ! -f "$IMG_DIR/$img_name" ]; then
                     echo -e "[$filename] \033[0;31mFAIL\033[0m: Image '$img_name' not found in $IMG_DIR."
                     file_errors=1
                fi
            fi
        fi
    done <<< "$img_lines"

    if [ $file_errors -eq 0 ]; then
        echo -e "[$filename] \033[0;32mOK\033[0m"
        return 0
    else
        return 1
    fi
}

count=0
found_files=false

for post in "$POST_DIR"/*.md; do
    if [ -e "$post" ]; then
        found_files=true
        validate_file "$post"
        if [ $? -ne 0 ]; then
            EXIT_CODE=1
        fi
        ((count++))
    fi
done

if [ "$found_files" = false ]; then
    echo "No markdown files found in $POST_DIR."
    exit 0 
fi

echo "------------------------------------------------"
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "\033[0;32mSUCCESS\033[0m: All $count posts are valid!"
else
    echo -e "\033[0;31mFAILURE\033[0m: Some posts violate the template."
fi

exit $EXIT_CODE