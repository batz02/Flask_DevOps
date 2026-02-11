#!/bin/bash

POST_DIR="posts/en"
EXIT_CODE=0


echo -e "Starting Markdown Validity Check in directory: $POST_DIR..."

if [ ! -d "$POST_DIR" ]; then
    echo -e "Error: Directory $POST_DIR not found!"
    exit 1
fi

REQUIRED_FIELDS=("title:" "subtitle:" "author:" "author_image:" "date:" "permalink:" "tags:" "shortcontent:")

validate_file() {
    local file=$1
    local filename=$(basename "$file")
    local file_errors=0

    if ! grep -q "\-\-\-" "$file"; then
        echo -e "[$filename] MISSING SEPARATOR: File must contain '---' to separate headers."
        return 1
    fi

    header=$(sed -n '1,/---/p' "$file")

    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! echo "$header" | grep -q "$field"; then
            echo -e " [$filename] MISSING FIELD: '$field' is required."
            file_errors=1
        fi
    done

    # C. Validazione specifica della DATA (Richiesta esplicita del README)
    # Formato richiesto: %B %d, %Y (es. "January 17, 2020")
    # Il README dice: "January 17, 2020 is correct, 17 January 2020 is not"
    
    date_line=$(echo "$header" | grep "date:")
    if [[ ! -z "$date_line" ]]; then
        # Estrae il valore dopo "date:" e rimuove spazi bianchi iniziali/finali
        date_value=$(echo "$date_line" | cut -d':' -f2 | sed 's/^[ \t]*//;s/[ \t]*$//')
        
        # Regex Bash per: Mese (parola iniziante con Maiuscola) + Spazio + 1 o 2 cifre + Virgola + Spazio + 4 cifre
        # Esempio match: "January 17, 2020"
        if ! [[ "$date_value" =~ ^[A-Z][a-z]+\ [0-9]{1,2},\ [0-9]{4}$ ]]; then
            echo -e "[$filename] INVALID DATE FORMAT: Found '$date_value'. Expected format '%B %d, %Y' (e.g., 'January 17, 2020')."
            file_errors=1
        fi
    fi

    if [ $file_errors -eq 0 ]; then
        echo -e "[$filename] Passed."
        return 0
    else
        return 1
    fi
}

count=0
found_files=false

for post in "$POST_DIR"/*.md; do
    if [ -f "$post" ]; then
        found_files=true
        validate_file "$post"
        if [ $? -ne 0 ]; then
            EXIT_CODE=1
        fi
        ((count++))
    fi
done

if [ "$found_files" = false ]; then
    echo -e "No markdown files found in $POST_DIR to check."
    exit 0 
fi

echo "------------------------------------------------"
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "SUCCESS: All $count posts are valid! The pipeline can proceed."
else
    echo -e "FAILURE: Some posts violate the template. Build aborted."
fi

exit $EXIT_CODE