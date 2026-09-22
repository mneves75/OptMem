#!/bin/sh
# OptMem installer. Run it again to update: it only replaces the tool, and
# `memo init` never touches memories that already exist.
#
#   curl -fsSL https://raw.githubusercontent.com/mneves75/OptMem/main/install.sh | sh

set -e

# One function, called on the last line: `curl | sh` cut short by a dropped
# connection defines half a function and runs nothing.
main() {
  DIR="$HOME/.optmem"

  command -v python3 >/dev/null || {
    echo "OptMem is one Python file, and this machine has no python3." >&2
    echo "Install python3, then run this line again." >&2
    exit 1
  }

  mkdir -p "$DIR"
  curl -fsSL https://raw.githubusercontent.com/mneves75/OptMem/main/memo -o "$DIR/memo.new"
  # A captive portal or a proxy answers 200 with a page of its own. Replace a
  # working tool only with a Python file that parses.
  if [ "$(head -n 1 "$DIR/memo.new")" != "#!/usr/bin/env python3" ] ||
     ! python3 -c 'import ast, sys; ast.parse(open(sys.argv[1], "rb").read())' \
       "$DIR/memo.new" 2>/dev/null; then
    rm -f "$DIR/memo.new"
    echo "The download is not the OptMem tool; nothing was changed." >&2
    echo "Check the network (a sign-in page?), then run this line again." >&2
    exit 1
  fi
  chmod +x "$DIR/memo.new"
  mv "$DIR/memo.new" "$DIR/memo"

  exec "$DIR/memo" init
}

main
