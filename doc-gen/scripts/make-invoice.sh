#!/usr/bin/env bash
set -euo pipefail

# Simple invoice generator
# Usage: ./make-invoice.sh data.md out.docx
# data.md is a Markdown file with invoice fields using pandoc metadata

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 data.md out.docx"
  exit 1
fi

DATA="$1"
OUT="$2"
TEMPLATE_DIR=/opt/doc-gen/templates
TEMPLATE_DOCX="$TEMPLATE_DIR/invoice_template.docx"
LOG=/opt/doc-gen/logs/render.log

if [ ! -f "$TEMPLATE_DOCX" ]; then
  echo "Template $TEMPLATE_DOCX not found. Please create it first." >&2
  exit 2
fi

pandoc "$DATA" -o "$OUT" --reference-doc="$TEMPLATE_DOCX" --resource-path="$TEMPLATE_DIR" 2>>"$LOG" && echo "Invoice written to $OUT" || { echo "Failed to create invoice (see $LOG)" >&2; exit 3; }
