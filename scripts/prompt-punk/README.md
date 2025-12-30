# prompt-punk

Deutsch / German (English below!)

## Kurzbeschreibung
prompt-punk ist ein kleines zsh-Skript, das es dir erlaubt, deine Zsh-PROMPT-Definition schnell zu ändern. Es bietet eine interaktive Auswahl von vordefinierten Stilen, setzt einzelne Stile per Option, erstellt automatische Backups deiner .zshrc und erlaubt das Wiederherstellen eines Backups.

## Anforderungen
- zsh >= 5.0
- Erforderliche externe Tools: sed, grep, diff, cp, mkdir, date, mv
- Optionale Tools (graceful degradation): rm, touch, readlink, stat, chmod
- Plattformen: macOS, Linux, FreeBSD, OpenBSD, NetBSD, DragonFly, Solaris, WSL

## Installation
Kopiere das Skript nach `scripts/prompt-punk/prompt-punk.sh` (ist bereits im Repository) und stelle sicher, dass es ausführbar ist:

  chmod +x scripts/prompt-punk/prompt-punk.sh

Du kannst das Skript in deinem PATH ablegen oder mit dem vollständigen Pfad aufrufen.

## Nutzung
- Interaktiv (Style-Auswahl):
  - `prompt-punk` oder `./prompt-punk.sh`
- Stil setzen:
  - `prompt-punk -s N`  (Setzt Stil N, 1–8)
  - `prompt-punk -s r`  (Setzt einen zufälligen Stil)
- Aktuelle Konfiguration anzeigen:
  - `prompt-punk -c`
- Backups auflisten:
  - `prompt-punk -l`
- Letztes Backup wiederherstellen:
  - `prompt-punk -r`
- Hilfe / Version:
  - `prompt-punk -h` / `prompt-punk -v`

Nach Änderung: aktiviere die neue Konfiguration mit `exec zsh` oder `source ~/.zshrc`.

## Backups
- Standard-Location: `${ZDOTDIR:-$HOME}/.zshrc_backups/`
- Limit: 10 Dateien, automatisch rotiert, identische Inhalte werden nicht erneut gesichert
- Dateinamen-Format: `zshrc_YYYYMMDD_HHMMSS_<pid>`

## Hinweise & Limitierungen
- Das Skript verändert nur Zeilen, die mit `^PROMPT=` beginnen. Exportierte oder eingerückte `PROMPT=`-Definitionen werden nicht verändert.
- Inline-Kommentare nach `PROMPT=` werden verworfen.
- Mehrzeilige PROMPT-Definitionen werden nicht unterstützt.
- Keine Dateisperre: Führe das Skript nicht parallel auf derselben Datei aus.
- Reservierte Zeichen: § (Trennzeichen), \x01 (sed-Delimiter)

## Fehlerbehebung
- Prüfe, ob `$ZSHRC` existiert oder symlink ist. Das Skript meldet gebrochene Symlinks.
- Bei Schreibproblemen: Berechtigungen der `.zshrc` bzw. des Elternverzeichnisses prüfen.
- Wenn das Skript nichts ändert, wurde möglicherweise bereits der gleiche Prompt gesichert (Deduplication).

---

English

## Summary
prompt-punk is a small zsh script that lets you quickly change your zsh PROMPT. It provides an interactive picker of predefined styles, allows setting a style via CLI, automatically backs up your .zshrc, and can restore backups.

## Requirements
- zsh >= 5.0
- Required external tools: sed, grep, diff, cp, mkdir, date, mv
- Optional tools (graceful degradation): rm, touch, readlink, stat, chmod
- Supported platforms: macOS, Linux, BSDs, Solaris, WSL

## Installation
Make the script executable if needed:

  chmod +x scripts/prompt-punk/prompt-punk.sh

Place it in your PATH or call it by full path.

## Usage
- Interactive (pick a style):
  - `prompt-punk` or `./prompt-punk.sh`
- Set a style:
  - `prompt-punk -s N`  (Set style N, 1–8)
  - `prompt-punk -s r`  (Set a random style)
- Show current config:
  - `prompt-punk -c`
- List backups:
  - `prompt-punk -l`
- Restore last backup:
  - `prompt-punk -r`
- Help / Version:
  - `prompt-punk -h` / `prompt-punk -v`

After making changes: activate the new config with `exec zsh` or `source ~/.zshrc`.

## Backups
- Default location: `${ZDOTDIR:-$HOME}/.zshrc_backups/`
- Limit: 10 files, auto-rotated, content-deduplicated
- Filename format: `zshrc_YYYYMMDD_HHMMSS_<pid>`

## Notes & Limitations
- Only modifies lines that start with `^PROMPT=`. Exported or indented `PROMPT=` lines are ignored.
- Inline comments after `PROMPT=` are discarded.
- Multiline PROMPT definitions are not supported.
- No file locking — avoid running concurrent instances against the same file.
- Reserved characters: § (field separator), \x01 (sed delimiter)

## Troubleshooting
- The script warns about broken symlinks for `$ZSHRC` and the backup directory.
- For write errors, check permissions of `.zshrc` and its parent directory.
- If a change is skipped, it may be identical to the latest backup (deduplication).
