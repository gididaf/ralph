#!/bin/bash
set -euo pipefail

# =============================================================================
# Ralph Installer
# Installs Ralph slash commands and loop script for Claude Code
# =============================================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"

echo ""
echo "  ______      _       _     "
echo " |  __  |    | |     | |    "
echo " | |__| |__ _| |_ __ | |__  "
echo " |  _  / _\` | | '_ \\| '_ \\ "
echo " | | \\ \\ (_| | | |_) | | | |"
echo " |_|  \\_\\__,_|_| .__/|_| |_|"
echo "               | |          "
echo "               |_|          "
echo ""
echo " Autonomous loop for Claude Code"
echo ""

# Check if Claude Code config directory exists
if [[ ! -d "$CLAUDE_DIR" ]]; then
  echo "[ralph] Creating ~/.claude directory..."
  mkdir -p "$CLAUDE_DIR"
fi

# Create target directories
mkdir -p "$COMMANDS_DIR"
mkdir -p "$SCRIPTS_DIR"

# Install commands
echo "[ralph] Installing slash commands..."
COMMANDS=(ralph-init ralph-run ralph-status ralph-stop ralph-signs)
for cmd in "${COMMANDS[@]}"; do
  if [[ -f "$COMMANDS_DIR/$cmd.md" ]]; then
    echo "  Updating /$cmd"
  else
    echo "  Installing /$cmd"
  fi
  cp "$REPO_DIR/commands/$cmd.md" "$COMMANDS_DIR/$cmd.md"
done

# Install loop script
echo "[ralph] Installing loop script..."
cp "$REPO_DIR/scripts/ralph-loop.sh" "$SCRIPTS_DIR/ralph-loop.sh"
chmod +x "$SCRIPTS_DIR/ralph-loop.sh"

echo ""
echo "[ralph] Installation complete!"
echo ""
echo "  Commands installed:"
echo "    /ralph-init   - Plan and set up a Ralph loop"
echo "    /ralph-run    - Launch the loop in tmux"
echo "    /ralph-status - Check loop progress"
echo "    /ralph-stop   - Gracefully stop the loop"
echo "    /ralph-signs  - Add guardrails from failures"
echo ""
echo "  Quick start:"
echo "    1. Open Claude Code in your project"
echo "    2. Run: /ralph-init build a REST API with tests"
echo "    3. Run: /ralph-run"
echo "    4. Watch: /ralph-status"
echo ""
