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
- eval command injection in scanner.sh
- Python code injection in hash-id.sh
- Date parsing fallback chains
- Undefined has_cmd() function
- Symlink naming (hyphens preserved)
- Hash type prefix matching
- Unquoted variable expansions

### Changed
- install.sh: added --uninstall, --skip-deps flags
- install.sh: installs fish completions
- config.fish: added security aliases and PATH setup
