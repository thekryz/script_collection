# MAC AUDIT PUNK — mac-audit.sh

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

Lizenz & Haftung

Dieses Skript ist unter der MIT‑Lizenz lizenziert (siehe LICENSE im Repo). Verwenden Sie das Tool auf eigene Verantwortung; es gibt keine Garantien.

Autor

Community Edition — MAC AUDIT PUNK v1.0 (im Repository scripts/mac-audit/mac-audit.sh)

Änderungen / Mitwirkung

Pull Requests, Verbesserungen oder Korrekturen willkommen. Bitte Issues öffnen oder direkt Änderungen per Pull Request vorschlagen.

Kontakt

Bei Fragen: Öffnen Sie ein Issue in diesem Repository oder kontaktieren Sie den Repo‑Maintainer.
