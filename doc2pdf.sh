#!/bin/bash
# /usr/lib/cups/filter/doc2pdf
set -e

JOB_ID="$1"
USER="$2"
TITLE="$3"
COPIES="$4"
OPTIONS="$5"
FILE="$6"

# Função para extrair extensão a partir do document-format (se existir)
ext_from_options() {
  echo "$OPTIONS" \
    | sed -n 's/.*document-format=\([^ ,]*\).*/\1/p' \
    | awk -F/ '{print $2}' \
    | sed -e 's/+xml//g' -e 's/xlsx/spreadsheetml.sheet/' \
            -e 's/wordprocessingml.document/docx/' \
            -e 's/spreadsheetml.sheet/xlsx/'
}

# Se o CUPS passou o arquivo via stdin, ou se FILE não termina em .docx/.xlsx
if [ "$FILE" = "-" ] || ! echo "$FILE" | grep -E '\.(docx|xlsx)$' >/dev/null; then
  # detecta extensão: primeiro tenta pelas OPTIONS
  EXT=$(ext_from_options)
  # se ainda vazio, usa file --mime-type
  if [ -z "$EXT" ]; then
    MIME=$(file --mime-type -b "$FILE")
    case "$MIME" in
      application/vnd.openxmlformats-officedocument.wordprocessingml.document) EXT=docx ;;
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)        EXT=xlsx ;;
      *)                                                                       EXT="" ;;
    esac
  fi

  if [ -z "$EXT" ]; then
    echo "Não consegui determinar extensão para conversão (mime: $MIME, options: $OPTIONS)" >&2
    exit 1
  fi

  TMPFILE="/tmp/job-${JOB_ID}.$EXT"
  cat "${FILE:-/dev/stdin}" > "$TMPFILE"
  FILE="$TMPFILE"
fi

# Por fim, converte DOCX/XLSX válidos
case "${FILE##*.}" in
  docx|xlsx)
    libreoffice --headless --convert-to pdf:"writer_pdf_Export" \
      --outdir /tmp "$FILE"
    PDF="/tmp/$(basename "${FILE%.*}.pdf")"
    cat "$PDF"
    ;;
  *)
    echo "Formato não suportado: ${FILE##*.}" >&2
    exit 1
    ;;
esac