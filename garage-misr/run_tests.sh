#!/usr/bin/env bash
# Runs the GUT suite headless. Usage: GODOT=/path/to/godot ./run_tests.sh [gut args]
# Fails on any script/parse error too: GUT silently skips scripts that fail to load.
set -uo pipefail
cd "$(dirname "$0")"
GODOT="${GODOT:-godot}"
"$GODOT" --headless --import >/dev/null 2>&1 || true
log="$(mktemp)"
"$GODOT" --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json "$@" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
if grep -qE "SCRIPT ERROR|Parse Error|Failed to load script" "$log"; then
	echo "run_tests.sh: script errors found (see above)" >&2
	status=1
fi
rm -f "$log"
exit "$status"
