#!/bin/bash
set -euo pipefail

# =============================================================================
# Ralph Uninstaller
# Removes Ralph slash commands and loop script from Claude Code
# =============================================================================

CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"

echo "[ralph] Uninstalling Ralph..."

# Remove commands
COMMANDS=(ralph-init ralph-run ralph-status ralph-stop ralph-signs)
for cmd in "${COMMANDS[@]}"; do
  if [[ -f "$COMMANDS_DIR/$cmd.md" ]]; then
    rm "$COMMANDS_DIR/$cmd.md"
    echo "  Removed /$cmd"
  fi
done

# Remove loop script
if [[ -f "$SCRIPTS_DIR/ralph-loop.sh" ]]; then
  rm "$SCRIPTS_DIR/ralph-loop.sh"
  echo "  Removed ralph-loop.sh"
fi

echo ""
echo "[ralph] Uninstall complete. Your project files (PROMPT.md, fix_plan.md, .ralph/) are untouched."
echo ""
