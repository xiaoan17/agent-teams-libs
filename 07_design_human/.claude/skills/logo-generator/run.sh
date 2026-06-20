#!/usr/bin/env bash
# Wrapper for logo-generator Python scripts.
# Uses the isolated venv at 07_design_human/.venv and ensures the native
# Homebrew cairo dylib is on the loader path (needed by cairosvg/cairocffi).
#
# Usage:
#   ./run.sh scripts/svg_to_png.py <args...>
#   ./run.sh scripts/generate_showcase.py <args...>
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# .venv lives at the agent root: .../07_design_human/.venv
VENV_PY="$SKILL_DIR/../../../.venv/bin/python"
export DYLD_FALLBACK_LIBRARY_PATH="/opt/homebrew/lib:${DYLD_FALLBACK_LIBRARY_PATH:-}"
# Run from the skill dir so load_dotenv() picks up ./.env
cd "$SKILL_DIR"
exec "$VENV_PY" "$@"
