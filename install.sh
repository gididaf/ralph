#!/bin/bash
set -euo pipefail

# =============================================================================
# Ralph Installer
# Installs Ralph slash commands and loop script for Claude Code
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/gididaf/ralph/main/install.sh | bash
#
# Or clone and run locally:
#   git clone https://github.com/gididaf/ralph.git && cd ralph && bash install.sh
# =============================================================================

CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
REPO_URL="https://github.com/gididaf/ralph.git"

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

# Determine source: are we inside the cloned repo, or running via curl?
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null || echo ".")" && pwd)"
if [[ -f "$SCRIPT_DIR/commands/ralph-init.md" ]]; then
  REPO_DIR="$SCRIPT_DIR"
  CLEANUP=""
else
  # Running via curl — clone to temp directory
  if ! command -v git &>/dev/null; then
    echo "[ralph] ERROR: git is required. Install git first." >&2
    exit 1
  fi
  REPO_DIR=$(mktemp -d)
  CLEANUP="$REPO_DIR"
  echo "[ralph] Downloading Ralph..."
  git clone --quiet --depth 1 "$REPO_URL" "$REPO_DIR"
fi

# Cleanup on exit if we cloned
cleanup() {
  if [[ -n "${CLEANUP:-}" ]] && [[ -d "$CLEANUP" ]]; then
    rm -rf "$CLEANUP"
  fi
}
trap cleanup EXIT

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
