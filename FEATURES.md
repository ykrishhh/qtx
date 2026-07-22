# Features Plan

QTX roadmap — what's done, what's next.

## v2.0 (Current)

### Shell Theme
- [x] Animated ASCII banner (tte)
- [x] Dynamic name prompt (starship)
- [x] Syntax highlighting
- [x] Fish shell + eza + bat
- [x] Custom font + color scheme

### Security Toolkit (10 tools)
- [x] `tk-scanner` — nmap port scanner
- [x] `tk-recon` — OSINT reconnaissance
- [x] `tk-audit` — password strength auditor
- [x] `tk-ssl-check` — SSL/TLS certificate inspector
- [x] `tk-hash-id` — hash identification & cracking
- [x] `tk-log-analyzer` — auth log brute force detector
- [x] `tk-vuln-check` — web vulnerability scanner
- [x] `tk-wifi-recon` — WiFi network scanner
- [x] `tk-dir-brute` — directory/file brute-forcer
- [x] `tk-nikto` — nikto wrapper with Termux fixes

### Setup
- [x] One-shot install script
- [x] Auto dependency installation
- [x] /tmp fix for Termux
- [x] Nikto auto-fix (SSL, config)
- [x] Fish aliases for all tools
- [x] Fish completions for all tk-* commands
- [x] Uninstall script
- [x] TROUBLESHOOTING.md
- [x] CHEATSHEET.md

---

## v2.1 (Planned)

### New Tools
- [ ] `tk-subdomain` — subdomain brute-force enumerator
- [ ] `tk-api-fuzz` — API endpoint fuzzer

### Shell Improvements
- [ ] Fish plugin manager (fisher) integration
- [ ] Custom starship prompt with git + security status
- [ ] Auto-update checker for QTX
- [ ] Motd randomizer (multiple banner designs)

### Toolkit Improvements
- [ ] JSON output mode for all tools
- [ ] HTML report generation
- [ ] Save/compare scan results (diff mode)
- [ ] Config file for custom wordlists, targets
- [ ] Colored output toggle (NO_COLOR support)

---

## v2.2 (Future)

### Advanced Security
- [ ] `tk-credential-check` — check breached credential databases
- [ ] `tk-certificate-monitor` — track cert expiry across targets
- [ ] `tk-network-map` — visual network topology from scan results
- [ ] `tk-incident-response` — automated IR playbook runner
- [ ] `tk-compliance` — CIS/OWASP compliance checker

### Integration
- [ ] Composio MCP integration (LinkedIn, GitHub, email)
- [ ] Shodan/Censys API integration
- [ ] Notification system (termux-notification on scan complete)
- [ ] Schedule scans with cron (termux-job-scheduler)
- [ ] Export to Notion/Sheets via Composio

### Shell Power Features
- [ ] Fish theme switcher (qtx theme list)
- [ ] Project detection (auto-cd, auto-venv, auto-nvm)
- [ ] Smart history (per-project, searchable, deduped)
- [ ] Fish hooks for security (warn on suspicious commands)
- [ ] Tab completion for git, docker, kubectl

---

## v3.0 (Dream)

### Full Pentest Suite
- [ ] `tk-hunt` — autonomous vulnerability hunter
- [ ] `tk-exploit` — exploit framework wrapper
- [ ] `tk-post` — post-exploitation toolkit
- [ ] `tk-report` — auto-generate pentest reports
- [ ] `tk-cloud` — cloud security auditor (AWS/GCP/Azure)

### AI-Powered
- [ ] AI scan analysis (summarize findings, suggest fixes)
- [ ] Natural language pentest queries ("scan for SQLi on example.com")
- [ ] Auto-remediation suggestions
- [ ] Threat intelligence integration
- [ ] Anomaly detection in logs

---

## Completed Milestones

| Date | Milestone |
|------|-----------|
| 2026-07-22 | v2.0 — 10 security tools, completions, uninstall, bug fixes |
| 2026-07-22 | First release by @harry6e |
| 2026-07-22 | First commit: theme + toolkit |

---

## How to Contribute

1. Pick an item from v2.1 or v2.2
2. Create a branch: `git checkout -b feat/tool-name`
3. Build it in `tools/`
4. Add fish alias in `assets/config.fish`
5. Update README + FEATURES.md
6. PR to `main`
