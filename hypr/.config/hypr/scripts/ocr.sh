#!/usr/bin/env bash

GEOM=$(slurp -b 00000077 -s 00000000 -w 0)
[ -z "$GEOM" ] && exit 0

TMP=$(mktemp /tmp/ocr-XXXXXX.png)
grim -g "$GEOM" "$TMP" || { rm -f "$TMP"; exit 0; }

TEXT=$(tesseract "$TMP" stdout -l rus+eng 2>/dev/null)
rm -f "$TMP"

TRIMMED=$(echo "$TEXT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

if [ -n "$TRIMMED" ]; then
    printf "%s" "$TRIMMED" | wl-copy
    PREVIEW=$(echo "$TRIMMED" | head -n 3 | cut -c 1-120)
    notify-send -a "OCR" -i "accessories-character-map" "Текст скопирован в буфер" "$PREVIEW"
else
    notify-send -a "OCR" -i "dialog-warning" "OCR" "Текст не распознан"
fi
