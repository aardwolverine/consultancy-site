#!/bin/bash
# Local preview for Hugo. Use localhost to avoid embedding local network hostnames in generated builds.
hugo server -D --bind=0.0.0.0 --baseURL=http://localhost:1313/
