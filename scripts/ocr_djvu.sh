#!/bin/bash
set -e

INPUT_DJVU="$1"
LANG="fra"

if [ -z "$INPUT_DJVU" ]; then
    echo "Usage: $0 fichier.djvu"
    exit 1
fi

# Récupérer le nombre total de pages
PAGES=$(djvused -e "n" "$INPUT_DJVU")
TMP_DIR=$(mktemp -d)
SCRIPT_FINAL="$TMP_DIR/all_pages.djvused"

echo "Traitement de $PAGES page(s) pour $INPUT_DJVU..."

for ((i=1; i<=PAGES; i++)); do
    echo "-> Page $i / $PAGES"
    
    # 1. Extraire la page en image TIFF (300 dpi)
    ddjvu -format=tiff -page=$i -r 300 "$INPUT_DJVU" "$TMP_DIR/page_$i.tif"
    
    # 2. Exécuter Tesseract pour produire du hOCR
    tesseract "$TMP_DIR/page_$i.tif" "$TMP_DIR/page_$i" -l "$LANG" hocr quiet
    
    # 3. Convertir le hOCR en script djvused et cibler la bonne page
    echo "select $i" >> "$SCRIPT_FINAL"
    hocr2djvused.py "$TMP_DIR/page_$i.hocr" | sed 's/^select 1$//' >> "$SCRIPT_FINAL"
done

# 4. Injecter l'ensemble du texte dans le fichier DjVu original
djvused -f "$SCRIPT_FINAL" -s "$INPUT_DJVU"

# Nettoyage
rm -rf "$TMP_DIR"
echo "Terminé ! Le fichier $INPUT_DJVU est maintenant indexable."
