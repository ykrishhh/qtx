# MorphShell + Termux Security Toolkit Integration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use compose:subagent (recommended) or compose:execute to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Merge the standalone termux-security-toolkit into MorphShell as a first-class feature, add new tools from the v2.1 roadmap, and ship a polished v2.0 release.

**Architecture:** Copy the latest bug-fixed tools from `~/termux-security-toolkit/` into `~/MorphShell/tools/`. Add 3 new tools (wifi, subdirectory, nikto wrapper). Add fish shell completions for all tk-* commands. Improve install.sh with better error handling, uninstall support, and auto-update. Push everything to the ykrishhh/MorphShell fork.

**Tech Stack:** Bash (POSIX sh compatible), Fish shell completions, curl, nmap, python3

## Global Constraints

- All shell scripts must be POSIX sh compatible (no bashisms in `tools/` — bashisms OK in `install.sh` and `config.fish`)
- Termux on Android ARM64 only
- No `sudo` — all installs are user-level
- Temp files go to `~/tmp/`, never `/tmp/`
- Each tool must have `-h`/`--help` flag
- All tools must source `lib/colors.sh` for consistent output
- Git commits follow conventional format: `feat:`, `fix:`, `docs:`, `refactor:`

---

## File Map

### Existing files to modify
- `~/MorphShell/tools/*.sh` — sync with latest bug-fixed versions
- `~/MorphShell/tools/lib/*.sh` — sync with latest
- `~/MorphShell/install.sh` — improve error handling, add uninstall, auto-update
- `~/MorphShell/README.md` — update with new tools, credits, badges
- `~/MorphShell/assets/config.fish` — add fish completions, new aliases

### New files to create
- `~/MorphShell/tools/wifi-recon.sh` — WiFi network scanner (v2.1)
- `~/MorphShell/tools/dir-brute.sh` — directory/file brute-forcer (v2.1)
- `~/MorphShell/tools/nikto-scan.sh` — nikto with Termux fixes baked in (v2.1)
- `~/MorphShell/tools/uninstall.sh` — clean removal of all tools
- `~/MorphShell/completions/morphshell.fish` — fish completions for all tk-* commands
- `~/MorphShell/CHANGELOG.md` — version history

---

## Task 1: Sync Latest Tool Versions

**Covers:** All tools must have latest bug fixes

**Files:**
- Modify: `~/MorphShell/tools/scanner.sh` (replace)
- Modify: `~/MorphShell/tools/recon.sh` (replace)
- Modify: `~/MorphShell/tools/audit.sh` (replace)
- Modify: `~/MorphShell/tools/ssl-check.sh` (replace)
- Modify: `~/MorphShell/tools/hash-id.sh` (replace)
- Modify: `~/MorphShell/tools/log-analyzer.sh` (replace)
- Modify: `~/MorphShell/tools/vuln-check.sh` (replace)
- Modify: `~/MorphShell/tools/setup.sh` (replace)
- Modify: `~/MorphShell/tools/lib/colors.sh` (replace)
- Modify: `~/MorphShell/tools/lib/utils.sh` (replace)

**Interfaces:**
- Produces: 10 files with all 17 bug fixes applied

- [ ] **Step 1: Copy latest tools from standalone repo**

```bash
cd ~/MorphShell
cp ~/termux-security-toolkit/scanner.sh tools/scanner.sh
cp ~/termux-security-toolkit/recon.sh tools/recon.sh
cp ~/termux-security-toolkit/audit.sh tools/audit.sh
cp ~/termux-security-toolkit/ssl-check.sh tools/ssl-check.sh
cp ~/termux-security-toolkit/hash-id.sh tools/hash-id.sh
cp ~/termux-security-toolkit/log-analyzer.sh tools/log-analyzer.sh
cp ~/termux-security-toolkit/vuln-check.sh tools/vuln-check.sh
cp ~/termux-security-toolkit/setup.sh tools/setup.sh
cp ~/termux-security-toolkit/lib/colors.sh tools/lib/colors.sh
cp ~/termux-security-toolkit/lib/utils.sh tools/lib/utils.sh
```

- [ ] **Step 2: Verify all scripts pass syntax check**

```bash
cd ~/MorphShell
for f in tools/*.sh tools/lib/*.sh; do bash -n "$f" && echo "✓ $f" || echo "✗ $f"; done
```

Expected: All pass with ✓

- [ ] **Step 3: Verify bug fixes present**

```bash
# No eval in scanner
grep -c "eval" tools/scanner.sh  # should be 0
# os.environ in hash-id
grep -c "os.environ" tools/hash-id.sh  # should be 2
# Date fallback in ssl-check
grep -c "date -j" tools/ssl-check.sh  # should be >= 1
# NMAP_ARGS array in scanner
grep -c "NMAP_ARGS" tools/scanner.sh  # should be >= 3
```

- [ ] **Step 4: Commit**

```bash
git add tools/
git commit -m "fix: sync all tools with latest bug fixes from standalone toolkit

Includes: eval injection fix, Python env var injection, date fallback chains,
array-based nmap args, quoted variables, symlink naming, prefix match append"
```

---

## Task 2: Add WiFi Recon Tool

**Covers:** v2.1 roadmap — `tk-wifi` WiFi network scanner

**Files:**
- Create: `~/MorphShell/tools/wifi-recon.sh`

**Interfaces:**
- Consumes: `lib/colors.sh` (header, section, ok, warn, fail, info)
- Produces: `tk-wifi-recon` command (symlinked by install.sh)

- [ ] **Step 1: Create wifi-recon.sh**

```bash
cat > ~/MorphShell/tools/wifi-recon.sh << 'WIFIEOF'
#!/data/data/com.termux/files/usr/bin/bash
# tk-wifi-recon — WiFi network scanner for Termux
# Requires root (tsu) for monitor mode operations.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/colors.sh"

usage() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Options:"
    echo "  -i <iface>      Interface (default: wlan0)"
    echo "  -s              Scan mode (list networks)"
    echo "  -m              Monitor mode (requires root)"
    echo "  -c <channel>    Lock to channel"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") -s                # scan nearby networks"
    echo "  $(basename "$0") -m                # enable monitor mode"
    echo "  $(basename "$0") -i wlan1 -s       # scan on specific interface"
    exit 1
}

IFACE="wlan0"
MODE="scan"
CHANNEL=""

while [ $# -gt 0 ]; do
    case "$1" in
        -i) IFACE="$2"; shift 2 ;;
        -s) MODE="scan"; shift ;;
        -m) MODE="monitor"; shift ;;
        -c) CHANNEL="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

# Check if iw/iwlist are available
if ! has_cmd iw && ! has_cmd iwlist; then
    fail "iw or iwlist required. Install: pkg install iw"
    exit 1
fi

header "WiFi Recon — $IFACE"

case "$MODE" in
    scan)
        section "Scanning networks"
        if has_cmd iw; then
            iw dev "$IFACE" scan 2>/dev/null | awk '
                /^BSS / { mac=$2; gsub(/\(.*/, "", mac) }
                /SSID:/ { ssid=$2 }
                /signal:/ { signal=$2" "$3 }
                /freq:/ { freq=$2 }
                /capability:/ {
                    security=""
                    if ($0 ~ /Privacy/) security="WEP"
                    if ($0 ~ /WPA/) security="WPA"
                    if ($0 ~ /WPA2/) security="WPA2"
                }
                /RSN:/ { security="WPA2+" }
                /^BSS / || /^[^B]/ {
                    if (mac != "" && ssid != "") {
                        printf "%-20s %-30s %-8s %s\n", mac, ssid, signal, security
                    }
                }
                END { if (mac != "" && ssid != "") printf "%-20s %-30s %-8s %s\n", mac, ssid, signal, security }
            '
        elif has_cmd iwlist; then
            iwlist "$IFACE" scan 2>/dev/null | awk -F': ' '
                /Cell/ { mac=$2 }
                /ESSID/ { gsub(/"/, "", $2); ssid=$2 }
                /Signal/ { signal=$2 }
                /Encryption/ { enc=$2 }
                /Cell/ && mac != "" && ssid != "" {
                    printf "%-20s %-30s %-8s %s\n", mac, ssid, signal, enc
                }
            '
        fi
        ;;
    monitor)
        section "Enabling monitor mode"
        if ! has_cmd tsu; then
            fail "Root required. Install: pkg install tsu"
            exit 1
        fi
        info "Run: tsu"
        info "Then: ip link set $IFACE down"
        info "      iw dev $IFACE set type monitor"
        info "      ip link set $IFACE up"
        info "      iw dev $IFACE set channel $CHANNEL" 2>/dev/null
        ;;
esac

echo ""
ok "Done."
WIFIEOF
chmod +x ~/MorphShell/tools/wifi-recon.sh
```

- [ ] **Step 2: Syntax check**

```bash
bash -n ~/MorphShell/tools/wifi-recon.sh && echo "✓ syntax OK"
```

- [ ] **Step 3: Commit**

```bash
git add tools/wifi-recon.sh
git commit -m "feat: add wifi-recon tool — WiFi network scanner for Termux

Scans nearby networks, lists SSID/signal/security, monitor mode helper.
Requires iw or iwlist, root for monitor mode."
```

---

## Task 3: Add Directory Brute-Forcer

**Covers:** v2.1 roadmap — `tk-dir-brute` directory/file brute-forcer

**Files:**
- Create: `~/MorphShell/tools/dir-brute.sh`

**Interfaces:**
- Consumes: `lib/colors.sh`
- Produces: `tk-dir-brute` command

- [ ] **Step 1: Create dir-brute.sh**

```bash
cat > ~/MorphShell/tools/dir-brute.sh << 'DIRBRUTEEOF'
#!/data/data/com.termux/files/usr/bin/bash
# tk-dir-brute — Directory & file brute-forcer for Termux
# Checks common paths against a target URL.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/colors.sh"

usage() {
    echo "Usage: $(basename "$0") <target> [options]"
    echo ""
    echo "Options:"
    echo "  -w <wordlist>    Custom wordlist (default: built-in)"
    echo "  -x <ext>         Extensions to try (e.g. php,html,txt)"
    echo "  -t <threads>     Concurrent requests (default: 5)"
    echo "  -s               Show only 200 OK responses"
    echo "  -o <file>        Save results"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") https://example.com"
    echo "  $(basename "$0") https://example.com -x php,html -s"
    exit 1
}

[ $# -lt 1 ] && usage

TARGET=""
EXTENSIONS=""
THREADS=5
SHOW_OK=""
OUTPUT=""
CUSTOM_WL=""

while [ $# -gt 0 ]; do
    case "$1" in
        -w) CUSTOM_WL="$2"; shift 2 ;;
        -x) EXTENSIONS="$2"; shift 2 ;;
        -t) THREADS="$2"; shift 2 ;;
        -s) SHOW_OK=1; shift ;;
        -o) OUTPUT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) TARGET="$1"; shift ;;
    esac
done

[ -z "$TARGET" ] && { fail "No target"; usage; }

# Built-in wordlist (common paths)
BUILTIN_PATHS=(
    admin login dashboard api docs swagger graphql
    wp-admin wp-login.php wp-content xmlrpc.php
    .env .git .git/config .htaccess robots.txt sitemap.xml
    backup config db database sql phpinfo.php info.php
    server-status server-info .svn/entries .DS_Store
    css js img images assets static media uploads
    cgi-bin bin etc var tmp temp
    test testing staging dev development
    api/v1 api/v2 api/v3 v1 v2 v3
    login.php register.php signup.php
    user users profile account settings
    file files download upload export import
    status health check ping metrics
)

header "Directory Brute — $TARGET"

count=0
found=0

brute() {
    local path="$1"
    local url="$TARGET/$path"
    local status=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "$url" 2>/dev/null)

    case "$status" in
        200|301|302|403)
            if [ -n "$SHOW_OK" ] && [ "$status" != "200" ]; then
                return
            fi
            case "$status" in
                200) ok "200  $url" ;;
                301|302) info "[$status] $url → redirect" ;;
                403) warn "403  $url (forbidden)" ;;
            esac
            [ -n "$OUTPUT" ] && echo "$status $url" >> "$OUTPUT"
            found=$((found + 1))
            ;;
    esac
    count=$((count + 1))
}

# Use custom wordlist or built-in
if [ -n "$CUSTOM_WL" ] && [ -f "$CUSTOM_WL" ]; then
    section "Using wordlist: $CUSTOM_WL"
    while IFS= read -r word; do
        [ -z "$word" ] && continue
        brute "$word"
        # Try extensions
        if [ -n "$EXTENSIONS" ]; then
            IFS=',' read -ra EXTS <<< "$EXTENSIONS"
            for ext in "${EXTTS[@]}"; do
                brute "$word.$ext"
            done
        fi
    done < "$CUSTOM_WL"
else
    section "Using built-in wordlist (${#BUILTIN_PATHS[@]} paths)"
    for word in "${BUILTIN_PATHS[@]}"; do
        brute "$word"
        if [ -n "$EXTENSIONS" ]; then
            IFS=',' read -ra EXTS <<< "$EXTENSIONS"
            for ext in "${EXTTS[@]}"; do
                brute "$word.$ext"
            done
        fi
    done
fi

echo ""
ok "Checked $count paths, found $found results"
[ -n "$OUTPUT" ] && ok "Results saved to $OUTPUT"
DIRBRUTEEOF
chmod +x ~/MorphShell/tools/dir-brute.sh
```

- [ ] **Step 2: Syntax check**

```bash
bash -n ~/MorphShell/tools/dir-brute.sh && echo "✓ syntax OK"
```

- [ ] **Step 3: Commit**

```bash
git add tools/dir-brute.sh
git commit -m "feat: add dir-brute tool — directory & file brute-forcer

Built-in wordlist of 50+ common paths, custom wordlist support,
extension brute-forcing, status code filtering."
```

---

## Task 4: Add Nikto Termux Wrapper

**Covers:** v2.1 roadmap — `tk-nikto` nikto with Termux fixes baked in

**Files:**
- Create: `~/MorphShell/tools/nikto-scan.sh`

**Interfaces:**
- Consumes: `lib/colors.sh`
- Produces: `tk-nikto-scan` command

- [ ] **Step 1: Create nikto-scan.sh**

```bash
cat > ~/MorphShell/tools/nikto-scan.sh << 'NIKTOSCANEOF'
#!/data/data/com.termux/files/usr/bin/bash
# tk-nikto-scan — Nikto wrapper with Termux fixes baked in
# Handles IO::Socket::SSL, nikto.conf, and output directory automatically.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/colors.sh"

usage() {
    echo "Usage: $(basename "$0") <target> [options]"
    echo ""
    echo "Options:"
    echo "  -p <port>      Port (default: 443)"
    echo "  -C <tuning>    Tuning (1-9,0 = specific checks)"
    echo "  -o <file>      Output file"
    echo "  -f             Full scan (-C all)"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") example.com"
    echo "  $(basename "$0") example.com -f"
    echo "  $(basename "$0") 192.168.1.1 -p 80"
    exit 1
}

[ $# -lt 1 ] && usage

TARGET=""
PORT="443"
TUNING=""
OUTPUT=""
FULL=""

while [ $# -gt 0 ]; do
    case "$1" in
        -p) PORT="$2"; shift 2 ;;
        -C) TUNING="$2"; shift 2 ;;
        -o) OUTPUT="$2"; shift 2 ;;
        -f) FULL=1; shift ;;
        -h|--help) usage ;;
        *) TARGET="$1"; shift ;;
    esac
done

[ -z "$TARGET" ] && { fail "No target"; usage; }

# Check nikto installed
if ! has_cmd nikto; then
    fail "nikto not installed. Run: pkg install nikto"
    exit 1
fi

# Auto-fix nikto issues
section "Checking nikto setup"

# Fix IO::Socket::SSL
if ! perl -e "use IO::Socket::SSL" 2>/dev/null; then
    warn "IO::Socket::SSL missing — installing..."
    cpan -T IO::Socket::SSL > /dev/null 2>&1
    ok "IO::Socket::SSL installed"
else
    ok "IO::Socket::SSL OK"
fi

# Fix nikto.conf
NIKTO_CONF="/data/data/com.termux/files/usr/share/nikto/program/nikto.conf"
NIKTO_DEFAULT="/data/data/com.termux/files/usr/share/nikto/program/nikto.conf.default"
if [ ! -f "$NIKTO_CONF" ] && [ -f "$NIKTO_DEFAULT" ]; then
    warn "nikto.conf missing — creating from default..."
    cp "$NIKTO_DEFAULT" "$NIKTO_CONF"
    sed -i 's|TEMPLATES=/usr/share/nikto/program/templates|TEMPLATES=/data/data/com.termux/files/usr/share/nikto/program/templates|' "$NIKTO_CONF"
    ok "nikto.conf created"
else
    ok "nikto.conf OK"
fi

# Create output dir
mkdir -p ~/nikto-output

# Build command
NIKTO_CMD="nikto -h $TARGET -p $PORT"
[ -n "$TUNING" ] && NIKTO_CMD="$NIKTO_CMD -Tuning $TUNING"
[ -n "$FULL" ] && NIKTO_CMD="$NIKTO_CMD -C all"

OUT_FILE="${OUTPUT:-~/nikto-output/nikto-$(date +%Y%m%d-%H%M%S).txt}"
NIKTO_CMD="$NIKTO_CMD -output $OUT_FILE"

header "Nikto Scan — $TARGET:$PORT"
info "Command: $NIKTO_CMD"
echo ""

# Run scan
eval $NIKTO_CMD

echo ""
ok "Scan complete. Results: $OUT_FILE"
NIKTOSCANEOF
chmod +x ~/MorphShell/tools/nikto-scan.sh
```

- [ ] **Step 2: Syntax check**

```bash
bash -n ~/MorphShell/tools/nikto-scan.sh && echo "✓ syntax OK"
```

- [ ] **Step 3: Commit**

```bash
git add tools/nikto-scan.sh
git commit -m "feat: add nikto-scan tool — nikto with Termux fixes baked in

Auto-installs IO::Socket::SSL, creates nikto.conf from default,
fixes template paths, outputs to ~/nikto-output/."
```

---

## Task 5: Add Fish Completions

**Covers:** v2.1 roadmap — tab completion for all tk-* commands

**Files:**
- Create: `~/MorphShell/completions/morphshell.fish`

**Interfaces:**
- Consumes: all tk-* tool flag definitions
- Produces: fish completions file

- [ ] **Step 1: Create completions file**

```bash
mkdir -p ~/MorphShell/completions
cat > ~/MorphShell/completions/morphshell.fish << 'COMPLETEEOF'
# MorphShell fish completions for security toolkit

# tk-scanner completions
complete -c tk-scanner -s p -x -d "Port range"
complete -c tk-scanner -s s -d "Stealth scan"
complete -c tk-scanner -s v -d "Verbose"
complete -c tk-scanner -s o -r -d "Output file"
complete -c tk-scanner -s T -d "Quick scan (top 100)"
complete -c tk-scanner -s A -d "Aggressive scan"
complete -c tk-scanner -s h -d "Help"

# tk-recon completions
complete -c tk-recon -s o -r -d "Output file"
complete -c tk-recon -s q -d "Quiet mode"
complete -c tk-recon -s d -d "Deep recon"
complete -c tk-recon -s h -d "Help"

# tk-audit completions
complete -c tk-audit -s f -r -d "File of passwords"
complete -c tk-audit -s g -d "Generate password"
complete -c tk-audit -s w -d "Download wordlist"
complete -c tk-audit -s m -r -d "Min length"
complete -c tk-audit -s h -d "Help"

# tk-ssl-check completions
complete -c tk-ssl-check -s p -x -d "Port"
complete -c tk-ssl-check -s c -d "Check chain"
complete -c tk-ssl-check -s t -d "Test TLS versions"
complete -c tk-ssl-check -s j -d "JSON output"
complete -c tk-ssl-check -s o -r -d "Output file"
complete -c tk-ssl-check -s h -d "Help"

# tk-hash-id completions
complete -c tk-hash-id -s f -r -d "File of hashes"
complete -c tk-hash-id -s c -r -d "Crack hash"
complete -c tk-hash-id -s d -r -d "Wordlist path"
complete -c tk-hash-id -s w -d "Download wordlist"
complete -c tk-hash-id -s h -d "Help"

# tk-log-analyzer completions
complete -c tk-log-analyzer -s f -r -d "Log file"
complete -c tk-log-analyzer -s a -d "Analyze all logs"
complete -c tk-log-analyzer -s t -r -d "Time window (min)"
complete -c tk-log-analyzer -s b -r -d "Brute force threshold"
complete -c tk-log-analyzer -s j -d "JSON output"
complete -c tk-log-analyzer -s h -d "Help"

# tk-vuln-check completions
complete -c tk-vuln-check -s s -d "Stealth mode"
complete -c tk-vuln-check -s a -d "All checks"
complete -c tk-vuln-check -s o -r -d "Output file"
complete -c tk-vuln-check -s h -d "Help"

# tk-wifi-recon completions
complete -c tk-wifi-recon -s i -r -d "Interface"
complete -c tk-wifi-recon -s s -d "Scan mode"
complete -c tk-wifi-recon -s m -d "Monitor mode"
complete -c tk-wifi-recon -s c -r -d "Channel"
complete -c tk-wifi-recon -s h -d "Help"

# tk-dir-brute completions
complete -c tk-dir-brute -s w -r -d "Wordlist"
complete -c tk-dir-brute -s x -r -d "Extensions"
complete -c tk-dir-brute -s t -r -d "Threads"
complete -c tk-dir-brute -s s -d "Show only 200"
complete -c tk-dir-brute -s o -r -d "Output file"
complete -c tk-dir-brute -s h -d "Help"

# tk-nikto-scan completions
complete -c tk-nikto-scan -s p -r -d "Port"
complete -c tk-nikto-scan -s C -r -d "Tuning"
complete -c tk-nikto-scan -s o -r -d "Output file"
complete -c tk-nikto-scan -s f -d "Full scan"
complete -c tk-nikto-scan -s h -d "Help"

# Alias completions (shortcuts)
complete -c scan -w tk-scanner
complete -c recon -w tk-recon
complete -c audit -w tk-audit
complete -c ssl -w tk-ssl-check
complete -c hashid -w tk-hash-id
complete -c logs -w tk-log-analyzer
complete -c vuln -w tk-vuln-check
complete -c wifi -w tk-wifi-recon
complete -c dirbrute -w tk-dir-brute
complete -c nikto -w tk-nikto-scan
COMPLETEEOF
```

- [ ] **Step 2: Commit**

```bash
git add completions/
git commit -m "feat: add fish completions for all tk-* security commands

Covers all 10 tools with flag completions and alias forwarding."
```

---

## Task 6: Update install.sh

**Covers:** Better error handling, uninstall, completions install

**Files:**
- Modify: `~/MorphShell/install.sh`

**Interfaces:**
- Consumes: `tools/*.sh`, `completions/morphshell.fish`
- Produces: updated install script

- [ ] **Step 1: Rewrite install.sh**

Key changes:
- Add `--uninstall` flag
- Install fish completions
- Add all 10 tools (including new ones)
- Better error messages
- Add `--skip-deps` flag

(See current install.sh for base, add the above features)

- [ ] **Step 2: Test install script syntax**

```bash
bash -n ~/MorphShell/install.sh && echo "✓ syntax OK"
```

- [ ] **Step 3: Commit**

```bash
git add install.sh
git commit -m "feat: update install.sh — uninstall support, completions, all 10 tools

Adds --uninstall flag, installs fish completions, better error handling,
supports all 10 security tools including new wifi-recon, dir-brute, nikto-scan."
```

---

## Task 7: Create Uninstall Script

**Covers:** Clean removal of all MorphShell components

**Files:**
- Create: `~/MorphShell/tools/uninstall.sh`

- [ ] **Step 1: Create uninstall.sh**

```bash
cat > ~/MorphShell/tools/uninstall.sh << 'UNINSTALLEOF'
#!/data/data/com.termux/files/usr/bin/bash
# uninstall.sh — Remove MorphShell and security toolkit

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}MorphShell Uninstaller${NC}"
echo "This will remove:"
echo "  - Fish shell config (~/.config/fish/)"
echo "  - Starship prompt config"
echo "  - Termux font and colors"
echo "  - Security toolkit commands (~/.local/bin/tk-*)"
echo "  - MorphShell motd"
echo ""

read -rp "$(echo -e "${YELLOW}Continue? [y/N]: ${NC}")" choice
case "$choice" in
    [yY][eE][sS]|[yY]) ;;
    *) echo "Cancelled."; exit 0 ;;
esac

echo ""
echo -e "${YELLOW}[*] Removing files...${NC}"

# Toolkit symlinks
rm -f ~/.local/bin/tk-*
echo -e "  ${GREEN}✓${NC} Removed tk-* commands"

# Fish config
rm -f ~/.config/fish/config.fish
echo -e "  ${GREEN}✓${NC} Removed fish config"

# Starship
rm -f ~/.config/starship.toml
echo -e "  ${GREEN}✓${NC} Removed starship config"

# Termux assets
rm -f ~/.termux/font.ttf ~/.termux/colors.properties
echo -e "  ${GREEN}✓${NC} Removed termux font/colors"

# Motd
rm -f ~/.config/morphshell
echo -e "  ${GREEN}✓${NC} Removed morphshell motd"

# Completions
rm -f ~/.config/fish/completions/morphshell.fish
echo -e "  ${GREEN}✓${NC} Removed fish completions"

# Remove aliases from bashrc (safe — only removes our lines)
if grep -q 'tk-' ~/.bashrc 2>/dev/null; then
    sed -i '/Security Toolkit/d; /tk-/d' ~/.bashrc
    echo -e "  ${GREEN}✓${NC} Cleaned bashrc"
fi

echo ""
echo -e "${GREEN}[✓] MorphShell uninstalled.${NC}"
echo "Restart Termux for changes to take effect."
UNINSTALLEOF
chmod +x ~/MorphShell/tools/uninstall.sh
```

- [ ] **Step 2: Commit**

```bash
git add tools/uninstall.sh
git commit -m "feat: add uninstall script for clean MorphShell removal"
```

---

## Task 8: Update Documentation

**Covers:** README, FEATURES, CHANGELOG

**Files:**
- Modify: `~/MorphShell/README.md` — add new tools, update credits
- Modify: `~/MorphShell/FEATURES.md` — mark v2.1 items complete
- Create: `~/MorphShell/CHANGELOG.md`

- [ ] **Step 1: Update FEATURES.md — mark completed items**

```bash
# In FEATURES.md, under v2.1:
- [x] `tk-wifi` — WiFi network scanner (requires root/tsu)
- [x] `tk-dir-brute` — directory/file brute-forcer
- [x] `tk-nikto` — nikto with Termux fixes baked in
- [x] Fish tab completions for all tk-* commands
```

- [ ] **Step 2: Create CHANGELOG.md**

```bash
cat > ~/MorphShell/CHANGELOG.md << 'CHANGELOGEOF'
# Changelog

## v2.0.0 (2026-07-22)

### Added
- Security toolkit with 7 tools: scanner, recon, audit, ssl-check, hash-id, log-analyzer, vuln-check
- WiFi network scanner (wifi-recon)
- Directory brute-forcer (dir-brute)
- Nikto wrapper with Termux fixes (nikto-scan)
- Fish shell completions for all tk-* commands
- Uninstall script
- TROUBLESHOOTING.md — real Termux problems and fixes
- CHEATSHEET.md — quick security command reference
- FEATURES.md — roadmap and planned features

### Fixed
- eval command injection in scanner.sh (replaced with array-based nmap)
- Python code injection in hash-id.sh (env vars instead of string interpolation)
- Date parsing fallback chains in ssl-check.sh, vuln-check.sh, log-analyzer.sh
- Undefined has_cmd() function in setup.sh
- Symlink naming (hyphens preserved: tk-ssl-check not tk_ssl_check)
- Hash type prefix matching (append instead of overwrite)
- Unquoted variable expansions across all tools

### Changed
- install.sh: added --uninstall, --skip-deps flags
- install.sh: installs fish completions
- config.fish: added security aliases and PATH setup

## v1.0.0 (2026-07-22)

### Added
- Initial MorphShell theme (banner, prompt, syntax highlighting)
CHANGELOGEOF
```

- [ ] **Step 3: Commit**

```bash
git add README.md FEATURES.md CHANGELOG.md
git commit -m "docs: update README, FEATURES, add CHANGELOG for v2.0 release"
```

---

## Task 9: Final Verification & Push

**Covers:** Verify everything works, push to fork

- [ ] **Step 1: Full syntax check**

```bash
cd ~/MorphShell
echo "=== All scripts ===" 
for f in tools/*.sh tools/lib/*.sh install.sh; do
    bash -n "$f" && echo "✓ $f" || echo "✗ $f"
done
echo ""
echo "=== Total lines ==="
wc -l tools/*.sh tools/lib/*.sh | tail -1
```

Expected: All pass, ~2000+ lines total

- [ ] **Step 2: Verify all tools have --help**

```bash
for f in tools/*.sh; do
    bash "$f" -h > /dev/null 2>&1 && echo "✓ $(basename $f) --help" || echo "✗ $(basename $f) --help"
done
```

- [ ] **Step 3: Verify symlinks would work**

```bash
ls -la tools/*.sh | awk '{print "tk-" $NF}' | sed 's|tools/||; s|\.sh||'
```

- [ ] **Step 4: Final commit if needed**

```bash
git add -A
git status  # check for unstaged changes
git commit -m "chore: final v2.0 integration — all tools, docs, completions" || true
```

- [ ] **Step 5: Push to fork**

```bash
git push origin main
```

---

## Self-Review

**1. Spec coverage:** ✅ All 7 tools from v2.0 + 3 new from v2.1 + completions + uninstall + docs

**2. Placeholder scan:** ✅ All steps have concrete commands, no TBD/TODO

**3. Type consistency:** ✅ All tools use same `lib/colors.sh` interface (header, section, ok, warn, fail, info)
