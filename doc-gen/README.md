Document Generation Service

Overview

This repository provides a lightweight self-hosted "document factory" that:
- Watches /opt/doc-gen/inbox for Markdown (.md) files
- Converts Markdown to branded PDF and DOCX using pandoc + XeLaTeX
- Applies branding via a Word reference docx (brand.docx) and a LaTeX template (brand.latex)
- Merges multiple source files when they are named with a numeric prefix (e.g., 01-, 02-)
- Outputs results to /opt/doc-gen/output and moves processed sources to /opt/doc-gen/archive
- Runs continuously as a systemd service (docgen.service)

What I added (files in this repo)
- /doc-gen/scripts/render.sh — inbox watcher and conversion/merge logic
- /doc-gen/install.sh — installer that copies files to /opt/doc-gen and enables the systemd service
- /doc-gen/scripts/make-invoice.sh — invoice generator (auto-naming, PDF output, validation)
- /doc-gen/templates/
  - brand.latex (LaTeX template used for PDF)
  - brand.docx (sample Word reference file for DOCX styling)
  - invoice_template.docx (sample DOCX invoice template)
  - logo-light.png, logo-dark.png (copies of your site logos for use in templates)
- /doc-gen/examples/engagements.md — example content
- /doc-gen/examples/invoice-data.md — example invoice data (see below)

Prerequisites

On a Debian/Ubuntu system you need:
- pandoc (you said this is already installed)
- texlive-xetex (XeLaTeX engine for PDF rendering)
- inotify-tools (inotifywait used by the watcher)
- python3 (used by make-invoice.sh for simple validation/parsing)

If you have only installed pandoc so far, remaining quick install:

sudo apt-get update
sudo apt-get install -y texlive-xetex inotify-tools python3

(If you already installed texlive in another package set, ensure xelatex is available.)

Installation (automated)

1. From the repository root run as root:
   sudo ./doc-gen/install.sh

   What this does:
   - Installs required packages (apt-get) — pandoc, texlive-xetex, inotify-tools
   - Copies the doc-gen directory to /opt/doc-gen
   - Makes scripts executable and sets basic permissions
   - Installs and starts a systemd unit: /etc/systemd/system/docgen.service

2. After installer finishes, verify the service:
   sudo systemctl status docgen
   sudo journalctl -u docgen -f

Manual installation (if you prefer)

If you don't want to use the installer, do these steps manually:

sudo mkdir -p /opt/doc-gen
sudo rsync -av --exclude '.git' ./doc-gen/ /opt/doc-gen/
sudo chmod +x /opt/doc-gen/scripts/*.sh
sudo mkdir -p /opt/doc-gen/{inbox,templates,output,archive,logs}

Create the systemd unit at /etc/systemd/system/docgen.service:

[Unit]
Description=Document Generation Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c '/opt/doc-gen/scripts/render.sh'
Restart=always
RestartSec=5
WorkingDirectory=/opt/doc-gen
# Optionally set User= and Group= here to run as a non-root user

[Install]
WantedBy=multi-user.target

Then enable/start:

sudo systemctl daemon-reload
sudo systemctl enable --now docgen.service

Configuration you must do (remaining manual steps)

1. Provide brand assets and templates
   - Review and if desired replace the sample templates in /opt/doc-gen/templates/:
     - brand.docx — Word reference document (controls Word styles)
     - brand.latex — LaTeX template used to generate PDFs
     - invoice_template.docx — example invoice template used by the invoice generator
     - logo-light.png / logo-dark.png — logo images used by templates
   - You can edit brand.latex directly to adjust fonts, colors, and header/footer content.
   - If you need a custom Word reference file, open brand.docx in Word, change styles, save.

2. Set permissions (recommended)
   - To avoid running the service as root, create a service user and grant ownership:
     sudo useradd --system --no-create-home docuser || true
     sudo chown -R docuser:docuser /opt/doc-gen
     Edit /etc/systemd/system/docgen.service and add under [Service]:
       User=docuser
       Group=docuser
     Then:
       sudo systemctl daemon-reload
       sudo systemctl restart docgen

3. If you already have only pandoc installed (as you mentioned), install the remaining packages listed above.

How the watcher handles files

- Single-file conversion:
  - Drop a single file (e.g., proposal.md) into /opt/doc-gen/inbox
  - It will be converted to /opt/doc-gen/output/YYYYMMDD-proposal.pdf and YYYYMMDD-proposal.docx
  - The source file is moved to /opt/doc-gen/archive with a timestamp suffix: proposal_YYYYmmdd-HHMMSS.md

- Merging multiple files:
  - If several files with numeric prefixes exist (01-*, 02-*), the watcher will merge all files matching the NN- prefix (sorted) into one merged document.
  - The merged output is named: YYYYMMDD-<basename-of-first-file-without-prefix>.pdf/.docx
    Example: 01-engagements.md + 02-terms.md -> 20260314-engagements.pdf/.docx
  - Originals are moved to archive with timestamp suffixes.

Invoice generation (make-invoice.sh)

- The script doc-gen/scripts/make-invoice.sh:
  - Accepts a Markdown invoice data file and auto-generates a DOCX and PDF in /opt/doc-gen/output
  - Features:
    - Auto-naming: uses invoice_no metadata if present, otherwise date or YYYYMMDD prefix
    - Validation: computes the sum of the table Amount column and compares to an explicit Total: line if present; aborts on mismatch
    - Generates DOCX using invoice_template.docx and PDF using brand.latex (if present)

- Example data file (doc-gen/examples/invoice-data.md):

---
invoice_no: INV-0001
date: 2026-03-14
client: Example Client Pty Ltd
---

Client: Example Client Pty Ltd

| Description | Qty | Rate | Amount |
| --- | ---: | ---: | ---: |
| Consulting hours | 10 | 280 | 2800 |
| Travel | 1 | 180 | 180 |

Total: 2980

- Run the script:
  sudo /opt/doc-gen/scripts/make-invoice.sh doc-gen/examples/invoice-data.md
  (or run as the service user if you configured one; no sudo required if permissions allow)

Testing

- Drop a test file in the inbox to exercise the watcher:
  sudo cp doc-gen/examples/engagements.md /opt/doc-gen/inbox/01-engagements.md
  sudo chown -R <service-user> /opt/doc-gen
- Check logs:
  sudo tail -f /opt/doc-gen/logs/render.log
- Check service status and logs:
  sudo systemctl status docgen
  sudo journalctl -u docgen -f

Troubleshooting

- If xelatex is missing or PDF generation fails, install texlive-xetex and any additional TeX packages your LaTeX template uses.
- If inotifywait is missing, install inotify-tools.
- If make-invoice.sh fails with a validation error, inspect the table and Total line in the Markdown file.
- Logs are written to /opt/doc-gen/logs/render.log; systemd logs are in journalctl.

Security and hardening

- Prefer running the service as a dedicated non-root user (docuser) and chown /opt/doc-gen to that account.
- Lock down permissions on /opt/doc-gen/templates if they contain sensitive logos/credentials.
- Consider placing /opt/doc-gen/inbox on a monitored network share if you will drop files remotely — ensure proper access controls.

Next steps you should perform (since you mentioned you only installed pandoc so far)

1. Install the remaining packages:
   sudo apt-get update && sudo apt-get install -y texlive-xetex inotify-tools python3

2. Run the installer to place files under /opt/doc-gen and enable the service:
   sudo ./doc-gen/install.sh

3. Review and update the templates in /opt/doc-gen/templates (brand.docx, brand.latex, invoice_template.docx) with your real branding and contact info.

4. Optionally create a non-root service user (docuser), chown /opt/doc-gen to that user, and update the systemd unit to run as that user.

5. Place test files in /opt/doc-gen/inbox (use 01- prefix for multi-file merges) and monitor logs for successful outputs in /opt/doc-gen/output.

If you want, I can:
- Update install.sh to create the service user and set ownership automatically
- Add more robust field parsing and currency handling for invoices
- Provide a small web UI or simple HTTP endpoint for uploading Markdown files

Contact me which of the above you'd like automated and I will implement it.
