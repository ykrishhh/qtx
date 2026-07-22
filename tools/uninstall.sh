#!/data/data/com.termux/files/usr/bin/bash
# uninstall.sh — Clean QTX removal

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  QTX — Uninstall                 ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

step() { echo -e "\n${YELLOW}[*] $1${NC}"; }
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
removed() { echo -e "  ${RED}✗${NC} $1"; }

# --- 1. Show what will be removed ---
echo -e "${YELLOW}The following QTX components will be removed:${NC}"
echo ""
echo "  Tool symlinks:    ~/.local/bin/tk-*"
echo "  Fish config:      ~/.config/fish/config.fish"
echo "  Starship config:  ~/.config/starship.toml"
echo "  Termux assets:    ~/.termux/font.ttf"
echo "                    ~/.termux/colors.properties"
echo "  MOTD:             ~/.config/qtx"
echo "  Completions:      ~/.config/fish/completions/qtx.fish"
echo "  Bashrc entries:   Security Toolkit lines"
echo ""
echo -e "${YELLOW}This will NOT remove:${NC}"
echo "  - QTX repository (~/QTX)"
echo "  - Git, Python, or other installed packages"
echo "  - Other fish plugins or configs"
echo ""

# --- 2. Confirmation ---
read -rp "Proceed with uninstall? [y/N]: " CONFIRM
if [[ "${CONFIRM,,}" != "y" ]]; then
    echo -e "${RED}Uninstall cancelled.${NC}"
    exit 0
fi

# --- 3. Remove components ---

step "Removing toolkit symlinks"
REMOVED=0
for link in ~/.local/bin/tk-*; do
    if [ -L "$link" ]; then
        rm "$link"
        ok "Removed $(basename "$link")"
        REMOVED=$((REMOVED + 1))
    fi
done
if [ "$REMOVED" -eq 0 ]; then
    removed "No toolkit symlinks found"
fi

step "Removing fish config"
if [ -f ~/.config/fish/config.fish ]; then
    rm ~/.config/fish/config.fish
    ok "Removed config.fish"
else
    removed "config.fish not found"
fi

step "Removing starship config"
if [ -f ~/.config/starship.toml ]; then
    rm ~/.config/starship.toml
    ok "Removed starship.toml"
else
    removed "starship.toml not found"
fi

step "Removing termux assets"
if [ -f ~/.termux/font.ttf ]; then
    rm ~/.termux/font.ttf
    ok "Removed font.ttf"
else
    removed "font.ttf not found"
fi
if [ -f ~/.termux/colors.properties ]; then
    rm ~/.termux/colors.properties
    ok "Removed colors.properties"
else
    removed "colors.properties not found"
fi

step "Removing qtx MOTD"
if [ -f ~/.config/qtx ]; then
    rm ~/.config/qtx
    ok "Removed qtx"
else
    removed "qtx not found"
fi

step "Removing fish completions"
if [ -f ~/.config/fish/completions/qtx.fish ]; then
    rm ~/.config/fish/completions/qtx.fish
    ok "Removed qtx.fish completions"
else
    removed "completions not found"
fi

step "Cleaning ~/.bashrc"
if [ -f ~/.bashrc ]; then
    if grep -q '# --- Security Toolkit' ~/.bashrc 2>/dev/null; then
        sed -i '/# --- Security Toolkit/,/^$/d' ~/.bashrc
        ok "Removed Security Toolkit block from bashrc"
    elif grep -q 'tk-' ~/.bashrc 2>/dev/null; then
        sed -i '/tk-/d' ~/.bashrc
        ok "Removed toolkit lines from bashrc"
    else
        removed "No toolkit lines found in bashrc"
    fi
else
    removed "bashrc not found"
fi

# --- Done ---
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Uninstall Complete!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "To restore default Termux shell:"
echo "  chsh -s bash"
echo ""
echo "The QTX repository remains at ~/QTX"
echo "Delete it manually if no longer needed: rm -rf ~/QTX"
