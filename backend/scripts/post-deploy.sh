#!/usr/bin/env bash
# Idempotent post-deploy hooks (migrate already run by entrypoint).
set -euo pipefail
echo "post-deploy: ok"
