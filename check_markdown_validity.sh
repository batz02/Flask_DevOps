#!/bin/bash

# ==============================================================================
# SCRIPT DI VALIDAZIONE MARKDOWN
# Corso: Cloud and Edge Computing
# Obiettivo: Validare la conformità dei post rispetto al template (Quality Assurance)
# ==============================================================================

# Directory contenente i post (come da struttura legacy del progetto)
POST_DIR="posts/en"
EXIT_CODE=0

# Colori per l'output (per renderlo leggibile nei log della CI/CD)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔍 Starting Markdown Validity Check in directory: $POST_DIR...${NC}"

# 1. Verifica che la directory esista
if [ ! -d "$POST_DIR" ]; then
    echo -e "${RED}❌ Error: Directory $POST_DIR not found!${NC}"
    exit 1
fi

# Campi obbligatori definiti nel README del progetto
# Nota: "three dash" (---) è gestito separatamente
REQUIRED_FIELDS=("title:" "subtitle:" "author:" "author_image:" "date:" "permalink:" "tags:" "shortcontent:")

# Funzione per validare un singolo file
validate_file() {
    local file=$1
    local filename=$(basename "$file")
    local file_errors=0

    # A. Controlla il separatore "---" (Header separator)
    if ! grep -q "\-\-\-" "$file"; then
        echo -e "${RED}❌ [$filename] MISSING SEPARATOR:${NC} File must contain '---' to separate headers."
        return 1
    fi

    # Leggi l'header (tutto ciò che c'è prima del primo '---')
    # Sed qui estrae dalla riga 1 alla prima occorrenza di ---
    header=$(sed -n '1,/---/p' "$file")

    # B. Controlla la presenza di tutti i campi obbligatori
    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! echo "$header" | grep -q "$field"; then
            echo -e "${RED}❌ [$filename] MISSING FIELD:${NC} '$field' is required."
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
            echo -e "${RED}❌ [$filename] INVALID DATE FORMAT:${NC} Found '$date_value'. Expected format '%B %d, %Y' (e.g., 'January 17, 2020')."
            file_errors=1
        fi
    fi

    if [ $file_errors -eq 0 ]; then
        echo -e "${GREEN}✅ [$filename] Passed.${NC}"
        return 0
    else
        return 1
    fi
}

# Conta i file processati
count=0
found_files=false

# Loop su tutti i file .md nella directory
for post in "$POST_DIR"/*.md; do
    # Gestisce il caso in cui non ci siano file (il glob non espande)
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
    echo -e "${YELLOW}⚠️  No markdown files found in $POST_DIR to check.${NC}"
    # Non falliamo se la cartella è vuota, ma avvisiamo. 
    # Se per il progetto DEVE esserci almeno un post, cambia exit 0 in exit 1.
    exit 0 
fi

echo "------------------------------------------------"
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}🎉 SUCCESS: All $count posts are valid! The pipeline can proceed.${NC}"
else
    echo -e "${RED}🚫 FAILURE: Some posts violate the template. Build aborted.${NC}"
fi

exit $EXIT_CODE