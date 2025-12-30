# MAC AUDIT PUNK — mac-audit.sh

Deutsch / German (English below!)

Kurzbeschreibung

mac-audit.sh ist ein interaktives, Read‑Only Bash‑Skript zur schnellen Überprüfung gebrauchter Macs vor dem Kauf. Es führt zahlreiche automatische Checks (Hardware‑/Software‑Identität, MDM/DEP, Activation Lock, Speicher‑/Batterie‑Zustand, GPU, Sensoren, Konnektivität, Kernel‑Panics, Recovery/TimeMachine) und eine optionale 60‑Sekunden Thermik‑/Lautstärke‑Stresstest durch.

Wichtig: Das Skript verändert das System nicht, benötigt keine sudo‑Rechte und kann vollständig offline arbeiten. Es kann jedoch Audio abspielen und einen HTML‑Displaytest im Standardbrowser öffnen.

Funktionen

- Vergleicht Gehäuse‑Serial mit System‑Serial (wichtig für Manipulationsprüfung)
- Erkennt MDM/DEP/JAMF‑Reste und andere Enterprise Artefakte
- Prüft Activation Lock (iCloud) und Find My Token
- S.M.A.R.T.‑Prüfung, freie Speicherauslastung
- Batteriezyklen, Health‑Prozente und Herstellerinfo
- GPU‑Erkennung (integriert vs diskret) und VRAM/Metal‑Info
- Kamera, Audio, Display (inkl. interaktivem Display‑Test)
- SIP, FileVault, Gatekeeper, Firewall, Firmware/SECURE BOOT Checks
- Ports (Thunderbolt/USB‑C), Wi‑Fi, Bluetooth, Ethernet, SD‑Slot Hinweise
- Kernel‑Panic‑Analyse und macOS‑Stabilitätschecks
- Recovery/Time Machine Checks
- Optionaler Thermischer Stresstest (Standard: 60s)
- Generierung eines optionalen Text‑Reports auf dem Desktop

Voraussetzungen

- macOS 10.15 (Catalina) oder neuer
- Terminalzugriff (keine Administratorrechte erforderlich)
- Systemprogramme: system_profiler, diskutil, profiles, ioreg, csrutil, nvram (Standard auf macOS)
- Optional: Internet für Online‑Warranty‑Checks (funktioniert aber offline)

Sicherheitshinweis

- Read‑Only: Es werden keine Systemänderungen, keine sudo‑Befehle und keine Datenübertragungen vorgenommen.
- Das Skript schreibt nur optional eine einfache Textdatei auf den Desktop als Bericht.

Benutzung

Im Terminal ausführen (im Verzeichnis scripts/mac-audit oder mit vollem Pfad):

bash mac-audit.sh [--quick] [--no-report] [--verbose] [--help]

Optionen

- --quick : Überspringt den 60‑sekündigen Thermik‑Stresstest (schneller Lauf)
- --no-report : Speichert keinen Bericht auf dem Desktop
- --verbose : Zeigt zusätzliche diagnostische Informationen
- --help : Zeigt Kurzhilfe

Interaktive Hinweise

Das Skript fragt z.B. nach der Seriennummer vom Gehäuse, startet Klang‑ und Displaytests und bittet um kurze Bestätigungen. Bei erkannten Problemen erscheinen farbig hervorgehobene Warnungen und Empfehlungen.

Beispielausgabe (Kurzform)

Checks Passed: 20
Warnings: 2
Critical Fails: 0
Risk Assessment: LOW RISK

Report

Standard: Ein Textreport wird auf dem Desktop gespeichert: MacAudit_YYYYMMDD_HHMMSS.txt (sofern nicht --no-report)

============

English — Short description

mac-audit.sh is an interactive, read‑only Bash script designed for quick inspections of used Macs before purchase. It runs numerous automated checks (hardware/software identity, disk and battery info, security and system checks) and offers optional interactive tests such as audio and display checks.

Important: The script does not modify the system, does not require sudo privileges, and can operate completely offline. It may play audio and open an HTML display test in the default browser.

Features

- Compares chassis serial to system serial (important to detect tampering)
- Detects leftover MDM/DEP/JAMF and other enterprise artifacts
- Checks Activation Lock (iCloud) and Find My token
- S.M.A.R.T. checks and free disk space
- Battery cycle count, health percentage, and manufacturer info
- GPU detection (integrated vs. discrete), VRAM and Metal details
- Camera, audio, display (including interactive display test)
- SIP, FileVault, Gatekeeper, Firewall, Firmware/Secure Boot checks
- Notes on ports (Thunderbolt/USB‑C), Wi‑Fi, Bluetooth, Ethernet, SD slot
- Kernel panic analysis and macOS stability checks
- Recovery and Time Machine checks
- Optional thermal stress test (default: 60 s)
- Optional generation of a text report on the Desktop

Requirements
- macOS 10.15 (Catalina) or newer
- Terminal access (no administrator privileges required)
- System utilities available: system_profiler, diskutil, profiles, ioreg, csrutil, nvram
- Optional: Internet for online warranty checks (but the script works offline)

Security notice
- Read‑Only: No system changes, no sudo commands, and no unexpected data transfers are performed.
- The script may optionally write a simple text report to the Desktop.

Usage

Run in Terminal (from scripts/mac-audit or via full path):

bash mac-audit.sh [--quick] [--no-report] [--verbose] [--help]

Options
- --quick : Skips the default 60‑second thermal stress test (faster run)
- --no-report : Do not save a report to the Desktop
- --verbose : Show additional diagnostic details
- --help : Show short help

Interactive notes

The script may prompt for the chassis serial number, run audio and display tests, and ask for quick confirmations. Detected issues are highlighted clearly.

Sample output (short)

Checks Passed: 20
Warnings: 2
Critical Fails: 0
Risk Assessment: LOW RISK

Report

By default a text report is saved to the Desktop: MacAudit_YYYYMMDD_HHMMSS.txt (unless --no-report is used).
