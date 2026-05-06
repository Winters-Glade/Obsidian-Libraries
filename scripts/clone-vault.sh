#!/usr/bin/env bash
#===============================================================================
# Obsidian Libraries — Vault Cloner for Linux / macOS
# Clones selected vaults into ~/Documents/Obsidian Libraries
#
# Usage:  chmod +x clone-vault.sh && ./clone-vault.sh
#===============================================================================

REPO_URL="https://github.com/Winters-Glade/Obsidian-Libraries.git"
REPO_NAME="Obsidian-Libraries"
DEST_BASE="$HOME/Documents/Obsidian Libraries"
TEMP_DIR="/tmp/$REPO_NAME-$$"

set -e

# Colors
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}   🏛️  Obsidian Libraries — Vault Cloner${NC}"
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${NC}"
echo ""

# Check for git
if ! command -v git &>/dev/null; then
    echo -e "${YELLOW}Error: git is not installed.${NC}"
    echo "Install it from https://git-scm.com/ or use your package manager."
    exit 1
fi

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Step 1 — Clone (shallow) to temp
echo -e "${BOLD}📥 Downloading vault catalog...${NC}"
git clone --depth 1 --quiet "$REPO_URL" "$TEMP_DIR"
echo -e "${GREEN}✓${NC} Catalog downloaded."
echo ""

# Step 2 — List available vaults
echo -e "${BOLD}📚 Available Vaults:${NC}"
echo ""

VAULTS=()
INDEX=1
for dir in "$TEMP_DIR"/*/; do
    name="$(basename "$dir")"
    # Skip hidden directories and non-vault directories
    [[ "$name" == .* ]] && continue
    [[ "$name" == "scripts" ]] && continue
    VAULTS+=("$name")
    # Try to get a description from the vault's README
    desc=""
    if [[ -f "$dir/README.md" ]]; then
        desc=$(head -5 "$dir/README.md" | grep -oP '(?<=^> ).*' | head -1 || echo "")
    fi
    if [[ -z "$desc" ]]; then
        file_count=$(find "$dir" -maxdepth 1 -name "*.md" | wc -l)
        desc="$file_count markdown files"
    fi
    echo -e "  ${BOLD}$INDEX.${NC} ${CYAN}$name${NC} — $desc"
    INDEX=$((INDEX + 1))
done

echo ""

# Step 3 — Let user choose
echo -e "Enter the ${BOLD}numbers${NC} of the vault(s) you want to clone"
echo -e "(e.g., ${YELLOW}1${NC} for one vault, ${YELLOW}1 3${NC} for multiple, or ${YELLOW}all${NC} for everything):"
read -p "→ " -r SELECTION

# Create destination
mkdir -p "$DEST_BASE"

SELECTED_VAULTS=()
if [[ "$SELECTION" == "all" ]]; then
    SELECTED_VAULTS=("${VAULTS[@]}")
else
    for num in $SELECTION; do
        idx=$((num - 1))
        if [[ $idx -ge 0 && $idx -lt ${#VAULTS[@]} ]]; then
            SELECTED_VAULTS+=("${VAULTS[$idx]}")
        fi
    done
fi

if [[ ${#SELECTED_VAULTS[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No valid vaults selected. Exiting.${NC}"
    exit 0
fi

echo ""
echo -e "${BOLD}📋 Copying ${#SELECTED_VAULTS[@]} vault(s) to ${CYAN}$DEST_BASE${NC}${NC}..."
echo ""

for vault in "${SELECTED_VAULTS[@]}"; do
    echo -ne "  ${CYAN}$vault${NC} ... "
    if [[ -d "$DEST_BASE/$vault" ]]; then
        echo -e "${YELLOW}already exists, skipping.${NC}"
    else
        cp -r "$TEMP_DIR/$vault" "$DEST_BASE/"
        echo -e "${GREEN}done ✓${NC}"
    fi
done

echo ""
echo -e "${GREEN}${BOLD}✅ All done!${NC} Your vault(s) are in: ${CYAN}$DEST_BASE${NC}"
echo ""
echo -e "${BOLD}📖 Next steps:${NC}"
echo "  1. Open Obsidian"
echo "  2. Click the folder icon (Open another vault) in the bottom-left"
echo "  3. Select 'Open folder as vault'"
echo "  4. Navigate to: $DEST_BASE"
echo "  5. Pick the vault folder and open it"
echo ""
echo -e "${BOLD}🔄 To update later, re-run this script."
echo ""

# Try to open the folder
if command -v xdg-open &>/dev/null; then
    xdg-open "$DEST_BASE" 2>/dev/null || true
elif command -v open &>/dev/null; then
    open "$DEST_BASE" 2>/dev/null || true
fi
