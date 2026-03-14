Document Generation Service

Overview

This lightweight document factory watches /opt/doc-gen/inbox for Markdown (.md)
files, converts them to PDF and DOCX using pandoc + XeLaTeX, applies a
brand.docx (for Word) and brand.latex (for PDF), and places outputs into
/opt/doc-gen/output. Processed sources are moved to /opt/doc-gen/archive and
logs are written to /opt/doc-gen/logs/render.log.

Installation

1. Run as root: sudo ./install.sh
2. Provide your branding files in /opt/doc-gen/templates/brand.docx and
   /opt/doc-gen/templates/brand.latex
3. Drop .md files into /opt/doc-gen/inbox/ to trigger a conversion.

Service

A systemd service docgen.service is installed and starts the watcher on boot.

Notes

- Installer attempts to install pandoc, texlive-xetex, and inotify-tools using
  apt-get. Modify install.sh if you use another package manager.
- The script moves processed files to archive/ with a timestamp suffix to
  prevent reprocessing.
