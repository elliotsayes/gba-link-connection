#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: tools/scaffold_project.sh <project-dir> [--title <rom-title>] [--force]

Creates a new GBA project scaffold with:
- Makefile
- src/main.c
- data/

Examples:
  tools/scaffold_project.sh scenarios/HelloWorld
  tools/scaffold_project.sh scenarios/demo/AuthFlow --title AuthFlow --force
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_MAKEFILE="$REPO_ROOT/examples/LinkCable_basic/Makefile"

if [[ ! -f "$TEMPLATE_MAKEFILE" ]]; then
  echo "error: template not found: $TEMPLATE_MAKEFILE" >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

PROJECT_ARG=""
TITLE=""
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      if [[ $# -lt 2 ]]; then
        echo "error: --title requires a value" >&2
        exit 1
      fi
      TITLE="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -n "$PROJECT_ARG" ]]; then
        echo "error: unexpected extra argument: $1" >&2
        exit 1
      fi
      PROJECT_ARG="$1"
      shift
      ;;
  esac
done

if [[ -z "$PROJECT_ARG" ]]; then
  echo "error: missing <project-dir>" >&2
  usage
  exit 1
fi

if [[ "$PROJECT_ARG" = /* ]]; then
  PROJECT_DIR="$PROJECT_ARG"
else
  PROJECT_DIR="$REPO_ROOT/$PROJECT_ARG"
fi

PROJECT_NAME="$(basename "$PROJECT_DIR")"

if [[ -z "$TITLE" ]]; then
  TITLE="$PROJECT_NAME"
fi

if [[ -e "$PROJECT_DIR" && $FORCE -eq 0 ]]; then
  if [[ -e "$PROJECT_DIR/Makefile" || -e "$PROJECT_DIR/src/main.c" ]]; then
    echo "error: project already exists at $PROJECT_DIR (use --force to overwrite files)" >&2
    exit 1
  fi
fi

mkdir -p "$PROJECT_DIR/src" "$PROJECT_DIR/data"

cp "$TEMPLATE_MAKEFILE" "$PROJECT_DIR/Makefile"

# Keep defaults generic: standalone/cart build, no repo-specific libs, C hello world.
awk -v title="$TITLE" '
  /^TITLE[[:space:]]*:=[[:space:]]*/ { print "TITLE\t\t:= " title; next }
  /^LIBS[[:space:]]*:=[[:space:]]*/ { print "LIBS\t\t:= -ltonc"; next }
  /^SRCDIRS[[:space:]]*:=[[:space:]]*/ { print "SRCDIRS\t\t:= src"; next }
  /^INCDIRS[[:space:]]*:=[[:space:]]*/ { print "INCDIRS\t\t:= src"; next }
  /^LIBDIRS[[:space:]]*:=[[:space:]]*/ { print "LIBDIRS\t\t:= $(TONCLIB)"; next }
  { print }
' "$PROJECT_DIR/Makefile" > "$PROJECT_DIR/Makefile.tmp"
mv "$PROJECT_DIR/Makefile.tmp" "$PROJECT_DIR/Makefile"

cat > "$PROJECT_DIR/src/main.c" <<'EOF'
#include <tonc.h>

int main(void) {
  REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;
  tte_init_se_default(0, BG_CBB(0) | BG_SBB(31));

  tte_write("Hello, world!\n");
  tte_write("Scaffold project is running.\n");
  tte_write("Press reset in emulator to restart.\n");

  while (1) {
    vid_vsync();
  }

  return 0;
}
EOF

echo "Created project scaffold:"
echo "  $PROJECT_DIR"
echo "  - Makefile"
echo "  - src/main.c"
echo "  - data/"
