#!/usr/bin/env bash
set -o pipefail

BASE=/opt/doc-gen
INBOX="$BASE/inbox"
TEMPLATES="$BASE/templates"
OUTPUT="$BASE/output"
SCRIPTS="$BASE/scripts"
ARCHIVE="$BASE/archive"
LOGDIR="$BASE/logs"
LOG="$LOGDIR/render.log"

TEMPLATE_DOCX="$TEMPLATES/brand.docx"
TEMPLATE_LATEX="$TEMPLATES/brand.latex"

# Ensure folders exist
mkdir -p "$INBOX" "$TEMPLATES" "$OUTPUT" "$SCRIPTS" "$ARCHIVE" "$LOGDIR"

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"
}

# Helper: strip leading two-digit numeric prefix "NN-" if present
strip_numeric_prefix() {
  local name="$1"
  if [[ "$name" =~ ^[0-9]{2}-(.*)$ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo "$name"
  fi
}

# Process files in inbox
process_inbox() {
  shopt -s nullglob
  md_files=("$INBOX"/*.md)
  shopt -u nullglob

  if [ ${#md_files[@]} -eq 0 ]; then
    return
  fi

  # Files that have a numeric prefix like 01- 02-
  shopt -s nullglob
  prefixed=("$INBOX"/[0-9][0-9]-*.md)
  shopt -u nullglob

  DATE_PREFIX=$(date +%Y%m%d)
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)

  # If we have more than one prefixed file, merge those (ordered)
  if [ ${#prefixed[@]} -gt 1 ]; then
    IFS=$'\n' sorted_prefixed=($(printf "%s\n" "${prefixed[@]}" | sort))
    unset IFS

    # Determine base name from first file after removing numeric prefix
    first_base=$(basename "${sorted_prefixed[0]}" .md)
    rest_base=$(strip_numeric_prefix "$first_base")
    if [ -z "$rest_base" ]; then
      out_base="$DATE_PREFIX"
    else
      out_base="$DATE_PREFIX-$rest_base"
    fi

    merged="$SCRIPTS/merged-${TIMESTAMP}.md"
    log "Merging ${#sorted_prefixed[@]} prefixed files into $merged (output base: $out_base)"
    : > "$merged"
    for f in "${sorted_prefixed[@]}"; do
      cat "$f" >> "$merged"
      echo -e "\n\n" >> "$merged"
    done

    out_pdf="$OUTPUT/${out_base}.pdf"
    out_docx="$OUTPUT/${out_base}.docx"

    if pandoc "$merged" -o "$out_pdf" --pdf-engine=xelatex --template="$TEMPLATE_LATEX" 2>>"$LOG"; then
      log "PDF created: $out_pdf"
    else
      log "ERROR: Failed to create PDF for merged file"
    fi

    if pandoc "$merged" -o "$out_docx" --reference-doc="$TEMPLATE_DOCX" 2>>"$LOG"; then
      log "DOCX created: $out_docx"
    else
      log "ERROR: Failed to create DOCX for merged file"
    fi

    # Move originals to archive with timestamp suffix
    for f in "${sorted_prefixed[@]}"; do
      base=$(basename "$f" .md)
      mv "$f" "$ARCHIVE/${base}_${TIMESTAMP}.md" 2>>"$LOG" || log "WARN: Could not move $f to archive"
    done

    rm -f "$merged"
    return
  fi

  # If not merging prefixed files, process files individually.
  IFS=$'\n' sorted=($(printf "%s\n" "${md_files[@]}" | sort))
  unset IFS

  for f in "${sorted[@]}"; do
    base=$(basename "$f" .md)

    # Build output base: replace leading NN- with DATE_PREFIX or prepend DATE_PREFIX-
    if [[ "$base" =~ ^[0-9]{2}-(.*)$ ]]; then
      rest="${BASH_REMATCH[1]}"
      out_base="$DATE_PREFIX-$rest"
    else
      out_base="$DATE_PREFIX-$base"
    fi

    out_pdf="$OUTPUT/${out_base}.pdf"
    out_docx="$OUTPUT/${out_base}.docx"

    log "Processing single file: $f -> $out_pdf, $out_docx"

    if pandoc "$f" -o "$out_pdf" --pdf-engine=xelatex --template="$TEMPLATE_LATEX" 2>>"$LOG"; then
      log "PDF created: $out_pdf"
    else
      log "ERROR: Failed to create PDF for $f"
    fi

    if pandoc "$f" -o "$out_docx" --reference-doc="$TEMPLATE_DOCX" 2>>"$LOG"; then
      log "DOCX created: $out_docx"
    else
      log "ERROR: Failed to create DOCX for $f"
    fi

    # Move source to archive with timestamp suffix
    mv "$f" "$ARCHIVE/${base}_${TIMESTAMP}.md" 2>>"$LOG" || log "WARN: Could not move $f to archive"
  done
}

# Check dependencies at runtime
check_deps() {
  for c in pandoc inotifywait; do
    if ! command -v "$c" >/dev/null 2>&1; then
      log "ERROR: Required command '$c' not found. Please install dependencies."
      exit 1
    fi
  done
}

main() {
  check_deps

  log "Starting doc-gen watcher"

  # Process any files already in the inbox
  process_inbox

  # Watch for new/modified files
  inotifywait -m -e close_write,create --format '%w%f' "$INBOX" | while read -r path; do
    # Only react to .md files
    case "$path" in
      *.md)
        # Small delay to allow other tools to finish writing
        sleep 1
        log "Event detected for $path, processing inbox"
        process_inbox
        ;;
      *)
        ;;
    esac
  done
}

main
