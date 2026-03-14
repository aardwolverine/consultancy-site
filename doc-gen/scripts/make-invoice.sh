#!/usr/bin/env bash
set -euo pipefail

# Enhanced invoice generator
# Usage: ./make-invoice.sh data.md [out.docx]
# If out.docx is omitted, the script will auto-name and place outputs in /opt/doc-gen/output

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 data.md [out.docx]"
  exit 1
fi

DATA="$1"
OUT_OVERRIDE="${2:-}"
TEMPLATE_DIR=/opt/doc-gen/templates
TEMPLATE_DOCX="$TEMPLATE_DIR/invoice_template.docx"
TEMPLATE_PDF="$TEMPLATE_DIR/brand.latex"
OUTDIR=/opt/doc-gen/output
LOG=/opt/doc-gen/logs/render.log

mkdir -p "$OUTDIR" || true
mkdir -p "$(dirname "$LOG")" || true

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"
}

if [ ! -f "$TEMPLATE_DOCX" ]; then
  log "ERROR: Template $TEMPLATE_DOCX not found. Please create it first."
  exit 2
fi

if [ ! -f "$DATA" ]; then
  log "ERROR: Data file $DATA not found"
  exit 2
fi

# Extract metadata and compute table sum using embedded Python (handles simple Markdown tables)
read_meta=$(python3 - "$DATA" <<'PY'
import sys, re
fn=sys.argv[1]
s=open(fn,encoding='utf8').read()
meta={}
# YAML front matter
m=re.search(r'^---\s*$([\s\S]*?)^---\s*$', s, re.M)
if m:
    block=m.group(1)
    for line in block.splitlines():
        line=line.strip()
        if not line or line.startswith('#'): continue
        if ':' in line:
            k,v=line.split(':',1)
            meta[k.strip()]=v.strip().strip('"').strip("'")
# find first table header that contains Amount
lines=s.splitlines()
in_table=False
sum_val=0.0
for i,l in enumerate(lines):
    if '|' in l and 'Amount' in l:
        in_table=True
        continue
    if in_table:
        if not l.strip().startswith('|'):
            break
        # skip separator lines that are like | --- | ---: |
        if re.match(r'^\s*\|\s*[:-]+', l):
            continue
        cols=[c.strip() for c in l.strip().strip('|').split('|')]
        if len(cols)>=1:
            amt=cols[-1]
            num=re.sub(r'[^0-9\.\-]', '', amt)
            if num:
                try:
                    sum_val+=float(num)
                except:
                    pass
# Find explicit Total: line
m2=re.search(r'^Total:\s*\**\s*([0-9,\.\$\s-]+)\**', s, re.M)
total_val=''
if m2:
    total_val=re.sub(r'[^0-9\.\-]','', m2.group(1))

print('invoice_no='+meta.get('invoice_no',''))
print('date='+meta.get('date',''))
print('client='+meta.get('client',''))
print('table_sum='+str(sum_val))
print('total_val='+ (total_val if m2 else ''))
PY
)

# Parse the output
invoice_no=$(printf "%s" "$read_meta" | awk -F'=' '/^invoice_no=/{print substr($0,index($0,$2))}' | sed 's/^invoice_no=//')
date_meta=$(printf "%s" "$read_meta" | awk -F'=' '/^date=/{print substr($0,index($0,$2))}' | sed 's/^date=//')
client=$(printf "%s" "$read_meta" | awk -F'=' '/^client=/{print substr($0,index($0,$2))}' | sed 's/^client=//')
table_sum=$(printf "%s" "$read_meta" | awk -F'=' '/^table_sum=/{print $2}')
total_val=$(printf "%s" "$read_meta" | awk -F'=' '/^total_val=/{print $2}')

# Normalize values
invoice_no=$(echo "$invoice_no" | tr -d '"\r')
date_meta=$(echo "$date_meta" | tr -d '"\r')
client=$(echo "$client" | tr -d '"\r')

# Choose base name
DATE_PREFIX=$(date +%Y%m%d)
if [ -n "$invoice_no" ]; then
  base="invoice-${invoice_no}"
elif [ -n "$date_meta" ]; then
  safe_date=$(echo "$date_meta" | tr -cd '0-9')
  if [ -n "$safe_date" ]; then
    base="invoice-${safe_date}"
  else
    base="invoice-${DATE_PREFIX}"
  fi
else
  base="invoice-${DATE_PREFIX}"
fi

OUT_DOCX="${OUT_OVERRIDE:-$OUTDIR/${base}.docx}"
OUT_PDF="${OUTDIR}/${base}.pdf"

# Validation: if explicit Total present, compare to computed table sum
if [ -n "$total_val" ]; then
  # compare as floats
  # use awk for numeric comparison
  same=$(awk -v a="$table_sum" -v b="$total_val" 'BEGIN{if ((a+0)==(b+0)) print "1"; else print "0"}')
  if [ "$same" -ne 1 ]; then
    log "ERROR: Total mismatch. Table sum=$table_sum but Total field=$total_val. Aborting invoice generation."
    exit 4
  else
    log "Validation: total matches table sum ($table_sum)."
  fi
else
  log "Validation: no explicit Total line found; computed table sum is $table_sum."
fi

# Generate DOCX
log "Generating DOCX -> $OUT_DOCX using template $TEMPLATE_DOCX"
if pandoc "$DATA" -o "$OUT_DOCX" --reference-doc="$TEMPLATE_DOCX" --resource-path="$TEMPLATE_DIR" 2>>"$LOG"; then
  log "DOCX created: $OUT_DOCX"
else
  log "ERROR: Failed to create DOCX (see $LOG)"
  exit 5
fi

# Generate PDF
# Prefer using LaTeX template if available; otherwise pandoc will create a PDF via default template
if [ -f "$TEMPLATE_PDF" ]; then
  log "Generating PDF -> $OUT_PDF using LaTeX template $TEMPLATE_PDF"
  if pandoc "$DATA" -o "$OUT_PDF" --pdf-engine=xelatex --template="$TEMPLATE_PDF" --resource-path="$TEMPLATE_DIR" 2>>"$LOG"; then
    log "PDF created: $OUT_PDF"
  else
    log "ERROR: Failed to create PDF (see $LOG)"
    exit 6
  fi
else
  log "LaTeX template $TEMPLATE_PDF not found; attempting default PDF generation"
  if pandoc "$DATA" -o "$OUT_PDF" --pdf-engine=xelatex --resource-path="$TEMPLATE_DIR" 2>>"$LOG"; then
    log "PDF created: $OUT_PDF"
  else
    log "ERROR: Failed to create PDF (see $LOG)"
    exit 6
  fi
fi

log "Invoice generation complete: $OUT_DOCX and $OUT_PDF"
exit 0
