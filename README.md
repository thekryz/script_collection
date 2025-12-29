# 🔧 The Toolbox (a.k.a. /dev/chaos)

> "Works on my machine." - Unknown

## Manifesto
This isn't a polished library. This isn't a startup product. This is a feral collection of scripts, automations, and digital crowbars that have accumulated over time.

Some of it is elegant; some of it is pure spaghetti code born at 3 AM to solve a very specific problem that shouldn't have existed in the first place. It’s unrefined, pragmatic, and it does exactly what I needed when I needed it.

Use these scripts as inspiration, as tools, or as a cautionary tale. Read the code. Understand it. Run it on machines you can afford to break.

## Contents
An eclectic mix of small utilities and one-off hacks. Expect to find:
* Data munging scripts that force file formats to be friends against their will.
* System utilities I was too lazy to type out manually every time.
* Automations for tasks that were slowly stealing my will to live.

## Available scripts
Below are the main scripts currently in scripts/ with short descriptions. If you want more detailed docs or examples for any script, open an issue or drop a PR.

- scripts/mac-audit.sh
  - Purpose: Interactive, read-only forensic audit for used Macs to detect swapped logic boards, enterprise locks (MDM/DEP), Activation Lock, hardware and thermal issues, storage and battery health, kernel panics, and other red flags.
  - Key features: 15-phase audit (serial verification, MDM/DEP/JAMF detection, Activation Lock check, S.M.A.R.T and disk usage, battery cycles and manufacturer, GPU/display/audio tests, SIP/FileVault/Gatekeeper checks, recovery & Time Machine checks, kernel panic analysis, and a thermal stress test with interactive audio/display checks).
  - Requirements: macOS 10.15+ (Catalina or newer); Terminal access. Designed to be read-only and not require sudo for main checks. Offline-capable. Produces an optional text report on the Desktop.
  - Usage: bash scripts/mac-audit.sh [--quick] [--no-report] [--verbose]
  - Notes: Interactive (prompts, plays short system sounds, opens a temporary HTML display test). MIT-licensed. Full run time ~90–120s (includes 60s stress test); quick mode ~20–40s.

- scripts/prompt-punk.sh
  - Purpose: Lightweight zsh prompt manager — interactive style picker and safe updater for PROMPT= in your .zshrc with automatic backups and deduplication.
  - Key features: Interactive chooser, set-by-number or random, list/restore backups, preserves permissions, supports ZDOTDIR, keeps up to 10 rotated backups.
  - Requirements: zsh >= 5.0 and standard POSIX tools (sed, grep, diff, cp, mkdir, date, mv). Works on macOS, Linux, BSD, and WSL.
  - Usage: scripts/prompt-punk.sh (interactive) or scripts/prompt-punk.sh -s N | -s r | -c | -l | -r | -h
  - Notes: Targets lines beginning with PROMPT= in your zshrc; does not modify indented or exported PROMPT lines or multiline PROMPT definitions.

## Usage & Warning
Use at your own risk. I take no responsibility for exploded servers, lost data, or existential dread caused by reading the source code.

Pro-Tip: Read the code before you run it. Always. Do not blindly slap `sudo` in front of this stuff.

```bash
git clone https://github.com/thekryz/script_collection.git
cd script_collection
chmod +x scripts/*.sh
# Run a script (read its header docs first)
./scripts/mac-audit.sh --help
```

---

If you'd like, I can expand any of the script sections into a longer README per-script (examples, flags, cautions).