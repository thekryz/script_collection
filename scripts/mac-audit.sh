#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║   MAC AUDIT PUNK v1.0 - "TRUST NO SELLER" ULTIMATE EDITION                ║
# ║                                                                           ║
# ╠═══════════════════════════════════════════════════════════════════════════╣
# ║                                                                           ║
# ║   PURPOSE     Comprehensive fraud detection for used Mac purchases        ║
# ║               Detects swapped logic boards, enterprise locks, fake        ║
# ║               components, hidden damage, and security issues.             ║
# ║                                                                           ║
# ║   TARGETS     Apple Silicon: M1, M2, M3, M4 (all variants)                ║
# ║               Intel Macs: 2015+ (T2 and non-T2)                           ║
# ║               All form factors: MacBook, iMac, Mac mini, Studio, Pro      ║
# ║                                                                           ║
# ║   FEATURES    ┌─ IDENTITY & FRAUD ─────────────────────────────────────┐  ║
# ║               │ • Physical vs System serial verification               │  ║
# ║               │ • MDM/DEP enterprise lock detection                    │  ║
# ║               │ • iCloud Activation Lock status                        │  ║
# ║               │ • JAMF and other MDM remnant scanning                  │  ║
# ║               └────────────────────────────────────────────────────────┘  ║
# ║               ┌─ HARDWARE HEALTH ──────────────────────────────────────┐  ║
# ║               │ • Storage SMART status & health                        │  ║
# ║               │ • Battery cycle count & capacity                       │  ║
# ║               │ • GPU detection & discrete GPU check                   │  ║
# ║               │ • Thermal stress test with audio guidance              │  ║
# ║               │ • Kernel panic history analysis                        │  ║
# ║               └────────────────────────────────────────────────────────┘  ║
# ║               ┌─ COMPONENTS ───────────────────────────────────────────┐  ║
# ║               │ • Camera, Audio, Display authenticity + active tests   │  ║
# ║               │ • Touch ID / Face ID status                            │  ║
# ║               │ • Touch Bar functionality (if present)                 │  ║
# ║               │ • Keyboard & Trackpad guidance                         │  ║
# ║               └────────────────────────────────────────────────────────┘  ║
# ║               ┌─ SECURITY ─────────────────────────────────────────────┐  ║
# ║               │ • SIP, FileVault, Gatekeeper status                    │  ║
# ║               │ • Firmware security (T2 / Secure Enclave)              │  ║
# ║               │ • Tampering & jailbreak detection                      │  ║
# ║               │ • Recovery partition verification                      │  ║
# ║               └────────────────────────────────────────────────────────┘  ║
# ║               ┌─ THERMAL ──────────────────────────────────────────────┐  ║
# ║               │ • SMC version and status                               │  ║
# ║               │ • Fan sensor detection                                 │  ║
# ║               │ • Temperature sensor verification                      │  ║
# ║               │ • Thermal stress test with audio guidance              │  ║
# ║               └────────────────────────────────────────────────────────┘  ║
# ║               ┌─ CONNECTIVITY ─────────────────────────────────────────┐  ║
# ║               │ • USB/Thunderbolt port detection                       │  ║
# ║               │ • WiFi & Bluetooth status                              │  ║
# ║               │ • Port testing guidance                                │  ║
# ║               └────────────────────────────────────────────────────────┘  ║
# ║                                                                           ║
# ║   REQUIRES    • macOS 10.15+ (Catalina or newer)                          ║
# ║               • Terminal access (no admin/sudo required)                  ║
# ║               • No external tools or Homebrew packages needed             ║
# ║               • Internet NOT required (fully offline capable)             ║
# ║                                                                           ║
# ║   SAFETY      ✓ READ-ONLY: No system modifications whatsoever             ║
# ║               ✓ No sudo/root commands executed                            ║
# ║               ✓ No user file deletion (only cleans own temp files)        ║
# ║               ✓ No network uploads or data exfiltration                   ║
# ║               ✓ Only writes: optional plain-text report to Desktop        ║
# ║                                                                           ║
# ║   USAGE       bash mac_audit.sh [OPTIONS]                                 ║
# ║                                                                           ║
# ║   OPTIONS     --quick       Skip 60-second thermal stress test            ║
# ║               --no-report   Don't save report file to Desktop             ║
# ║               --verbose     Show additional diagnostic details            ║
# ║               --help        Show this usage information                   ║
# ║                                                                           ║
# ║   RUNTIME     Full scan: ~90-120 seconds (includes 60s stress + tests)    ║
# ║               Quick mode: ~20-40 seconds                                  ║
# ║                                                                           ║
# ║   OUTPUT      Terminal: Color-coded results with risk assessment          ║
# ║               File: Detailed report on Desktop (optional)                 ║
# ║                                                                           ║
# ║   EXIT CODES  0 = Completed successfully (check results for issues)       ║
# ║               1 = Prerequisites not met (wrong OS, missing tools)         ║
# ║                                                                           ║
# ║   LICENSE     MIT License - Use at your own risk. No warranties.          ║
# ║   AUTHOR      Community Edition - Punk Rock Auditing Since 2024           ║
# ║                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# =============================================================================
# LOCALE STANDARDIZATION
# =============================================================================
# [HISTORY]
# Problem:  System tools (diskutil, system_profiler) output localized strings
#           based on user's language settings. On German Macs: "Seriennummer"
#           instead of "Serial Number", "Speicher" instead of "Memory", etc.
#           All grep/awk parsing silently failed, returning empty strings.
#           This affected ~40% of non-English Mac users globally.
#
# Solution: Force POSIX/C locale for all child processes. Ensures all system
#           tool outputs use standardized English regardless of user's
#           language preferences. Must be set BEFORE any commands run.
#           Both LC_ALL and LANG set for maximum compatibility across
#           different macOS versions and shell configurations.
# =============================================================================
export LC_ALL=C
export LANG=C

# =============================================================================
# BASH STRICT MODE DECISION
# =============================================================================
# [HISTORY]
# Problem:  Using 'set -e' (errexit) caused premature script termination when:
#           - grep found no matches (exit code 1, but valid "nothing found")
#           - Optional system tools weren't available on all Mac models
#           - Commands returned non-zero for legitimate reasons
#           This made error handling unpredictable and debugging difficult.
#
# Solution: Intentionally NOT using strict mode. Errors handled explicitly:
#           - '|| true' for optional/expected-to-fail checks
#           - Proper conditionals for critical operations
#           - Explicit error messages when something truly fails
#           Trade-off: More verbose code for reliable cross-Mac operation.
# =============================================================================

# =============================================================================
# CONFIGURATION CONSTANTS
# =============================================================================

readonly SCRIPT_VERSION="1.0"
readonly SCRIPT_NAME="MAC AUDIT PUNK"
readonly MIN_MACOS_VERSION="10.15"


# =============================================================================
# THRESHOLD CONSTANTS
# =============================================================================
# [MAINTAINABILITY] Centralized threshold definitions
# Problem:  Magic numbers scattered throughout code (battery cycles, disk
#           percentages, etc.) made tuning difficult and inconsistent.
# Solution: Define all thresholds as named constants. Easier to adjust,
#           document, and maintain. Values based on Apple's guidelines and
#           community experience.
# =============================================================================
readonly BATTERY_CYCLES_EXCELLENT=300
readonly BATTERY_CYCLES_GOOD=500
readonly BATTERY_CYCLES_MODERATE=800
readonly BATTERY_CYCLES_HIGH=1000
readonly BATTERY_HEALTH_THRESHOLD=80       # Below this = degraded

readonly DISK_USAGE_WARNING=85             # Percent
readonly DISK_USAGE_CRITICAL=95            # Percent

readonly PANIC_RECENT_DAYS=30
readonly PANIC_COUNT_WARNING=3             # Recent panics threshold

readonly STRESS_TEST_DURATION=60           # Seconds

# =============================================================================
# REPORT PATH HANDLING
# =============================================================================
# [HISTORY]
# Problem:  Hardcoded "$HOME/Desktop" failed when:
#           - Desktop folder was renamed or iCloud-synced
#           - Network home directories with different structure
#           - Enterprise environments with restricted permissions
#           - Non-English systems with localized folder names
#
# Solution: Generate path at runtime, verify write permission before use,
#           provide clear error if write fails. Filename includes timestamp
#           to prevent overwrites. Falls back gracefully to skip-report mode.
# =============================================================================
REPORT_FILE=""

# CLI Flags (mutable by argument parser)
SKIP_STRESS_TEST=false
SKIP_REPORT=false
VERBOSE_MODE=false

# =============================================================================
# TERMINAL COLOR HANDLING
# =============================================================================
# [HISTORY]
# Problem:  Hardcoded ANSI escape codes produced garbage characters when:
#           - Script output piped to file (bash script.sh > log.txt)
#           - Redirected to another process
#           - Run in non-interactive terminals (cron, CI/CD pipelines)
#           - Certain terminal emulators with limited support
#
# Solution: Check if stdout is a TTY (interactive terminal). Only use colors
#           in interactive mode. All color variables become empty strings in
#           non-TTY mode, making them safe to use unconditionally in output.
# =============================================================================
if [[ -t 1 ]]; then
    readonly BOLD=$'\033[1m'
    readonly RED=$'\033[1;31m'
    readonly GREEN=$'\033[1;32m'
    readonly YELLOW=$'\033[1;33m'
    readonly CYAN=$'\033[1;36m'
    readonly BLUE=$'\033[0;34m'
    readonly MAGENTA=$'\033[0;35m'
    readonly GREY=$'\033[0;90m'
    readonly NC=$'\033[0m'
    readonly CHECKMARK="✓"
    readonly CROSSMARK="✗"
    readonly WARNING="⚠"
    readonly INFO="ℹ"
else
    readonly BOLD='' RED='' GREEN='' YELLOW='' CYAN='' BLUE='' MAGENTA='' GREY='' NC=''
    readonly CHECKMARK="[PASS]"
    readonly CROSSMARK="[FAIL]"
    readonly WARNING="[WARN]"
    readonly INFO="[INFO]"
fi

# =============================================================================
# RESULT TRACKING VARIABLES
# =============================================================================
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
INFO_COUNT=0

# =============================================================================
# ARRAY DECLARATION COMPATIBILITY
# =============================================================================
# [HISTORY]
# Problem:  'declare -a ARRAY=()' syntax behaves differently in bash 3.x
#           (macOS default) vs bash 4.x+. Some array operations that work
#           in bash 4 silently fail or behave unexpectedly in bash 3.2.
#           macOS ships with bash 3.2 due to GPL v3 licensing (Apple won't
#           include GPLv3 software).
#
# Solution: Use simple ARRAY=() initialization without 'declare'. Compatible
#           with bash 3.2+ and works reliably across all macOS versions.
#           Avoid associative arrays entirely (bash 4+ only feature).
# =============================================================================
CRITICAL_ISSUES=()
WARNING_ISSUES=()
MANUAL_CHECKS=()

# Data caches (fetched once at startup, reused throughout)
HW_DATA_CACHE=""
POWER_DATA_CACHE=""
GPU_DATA_CACHE=""
# =============================================================================
# [OPTIMIZATION] ioreg Cache
# Problem:  ioreg -l parses the entire IORegistry tree (~50MB+ of data).
#           Multiple calls throughout the script caused 10-15 seconds of
#           unnecessary overhead. Battery, Touch ID, board-id checks all
#           called ioreg separately.
# Solution: Cache full ioreg output once, grep from cache. Single 2-3 second
#           hit at startup instead of repeated delays throughout execution.
# =============================================================================
IOREG_CACHE=""
CAMERA_DATA_CACHE=""
AUDIO_DATA_CACHE=""
USB_DATA_CACHE=""
TB_DATA_CACHE=""
BT_DATA_CACHE=""
WIFI_DATA_CACHE=""
MEMORY_DATA_CACHE=""

# Detected system info (populated during checks)
IS_APPLE_SILICON=false
SYSTEM_SERIAL=""
SYSTEM_MODEL=""
SYSTEM_MODEL_ID=""
SYSTEM_CHIP=""
SYSTEM_RAM=""
HAS_TOUCH_BAR=false
HAS_TOUCH_ID=false


# =============================================================================
# [ENHANCEMENT] Device Form Factor Detection
# Problem:  Script was MacBook-centric, testing for built-in display, camera,
#           speakers, and keyboard on desktop Macs that don't have these.
#           This confused users and produced irrelevant test prompts.
# Solution: Detect device type and component presence. Use these flags
#           throughout the script to conditionally run appropriate tests.
# =============================================================================
DEVICE_TYPE=""              # "laptop", "desktop", "all-in-one"
HAS_BUILTIN_DISPLAY=false
HAS_BUILTIN_CAMERA=false
HAS_BUILTIN_SPEAKERS=false
HAS_BUILTIN_MIC=false
HAS_BUILTIN_KEYBOARD=false

# =============================================================================
# PROCESS SAFETY & CLEANUP
# =============================================================================
# [HISTORY - CRITICAL]
# Problem:  Early stress test implementations used 'killall yes' which could
#           terminate unrelated user processes with the same name (yes is a
#           common Unix utility). When users pressed Ctrl+C during stress
#           tests, 'yes' processes became orphans, continuing to consume
#           100% CPU per process and causing system overheating. Some users
#           reported fans running at max speed for hours after aborting.
#
# Solution: Maintain explicit PID array for all spawned processes. Register
#           cleanup function via 'trap' for EXIT, INT (Ctrl+C), TERM, and HUP
#           signals. Kill only processes we spawned using their specific PIDs.
#           Suppress stderr to avoid "no such process" noise if already dead.
#           Cleanup function is idempotent (safe to call multiple times).
# =============================================================================
STRESS_PIDS=()

cleanup() {
    # Terminate any stress test processes we spawned
    if [[ ${#STRESS_PIDS[@]} -gt 0 ]]; then
        for pid in "${STRESS_PIDS[@]}"; do
            # =============================================================
            # [ROBUSTNESS] Graceful then forceful termination
            # Problem:  Simple SIGTERM is ignored by some processes. During
            #           script abort (Ctrl+C), yes processes could keep running.
            # Solution: Send SIGTERM first, brief wait, then SIGKILL if needed.
            # =============================================================
            kill -TERM "$pid" 2>/dev/null || true
            sleep 0.1
            kill -KILL "$pid" 2>/dev/null || true
        done
        STRESS_PIDS=()
    fi
    # Clean up any temp files from log analysis timeout
    # =========================================================================
    # [ENHANCEMENT] Extended temp file cleanup
    # Problem:  New active tests (display HTML, audio) create temp files that
    #           could remain if script is interrupted via Ctrl+C mid-test.
    # Solution: Clean up all known temp file patterns in cleanup function.
    # =========================================================================
    rm -f /tmp/.mac_audit_wake_$$ 2>/dev/null || true
    rm -f /tmp/.mac_audit_display_test_$$.html 2>/dev/null || true
    # Restore cursor visibility (may have been hidden during countdown)
    tput cnorm 2>/dev/null || true
}

# Register cleanup for all exit scenarios
trap cleanup EXIT INT TERM HUP

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# Safe Integer Extraction
# -----------------------------------------------------------------------------
# [HISTORY]
# Problem:  Bash integer comparisons like [[ $VAR -lt 100 ]] crash with
#           "integer expression expected" when VAR is:
#           - Empty string
#           - Contains spaces or tabs
#           - Has non-numeric characters (units like "GB", "mAh")
#           - Contains localized number formats ("1.234,56")
#           This caused script failures with unexpected system tool output.
#
# Solution: Wrapper that strips all non-digit characters, returns default
#           value if result is empty. Always returns valid integer for
#           comparisons. Caller specifies sensible default.
# -----------------------------------------------------------------------------
safe_int() {
    local val="$1"
    local default="${2:-0}"
    # Remove everything except digits
    val="${val//[!0-9]/}"
    if [[ -z "$val" ]]; then
        echo "$default"
    else
        echo "$val"
    fi
}

# -----------------------------------------------------------------------------
# Bash 3.2 Compatible Uppercase
# -----------------------------------------------------------------------------
# [HISTORY]
# Problem:  Bash 4.0 introduced ${var^^} for uppercase conversion, but macOS
#           ships with Bash 3.2 by default (GPL v3 licensing). Using ${var^^}
#           causes "bad substitution" error on stock macOS terminal.
#           Users installing bash 4+ via Homebrew typically invoke scripts
#           with 'bash script.sh', which uses /bin/bash (3.2) anyway.
#
# Solution: Use 'tr' command for case conversion. POSIX compliant, available
#           on all Unix systems including macOS. Slightly slower but
#           guaranteed to work regardless of bash version.
# -----------------------------------------------------------------------------
to_uppercase() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# -----------------------------------------------------------------------------
# Version Comparison Without External Tools
# -----------------------------------------------------------------------------
# [HISTORY]
# Problem:  Comparing version strings like "10.15.7" vs "11.0" is non-trivial:
#           - String comparison fails ("10" > "9" is false alphabetically)
#           - Using 'bc' adds external dependency (not always installed)
#           - 'sort -V' (version sort) not available on older macOS
#           - 'printf "%d"' fails on multi-part versions
#
# Solution: Split version into components and compare numerically using only
#           bash built-ins. Pure bash solution works on all macOS versions
#           without any external dependencies. Returns 0 if v1 >= v2.
# -----------------------------------------------------------------------------
version_gte() {
    local v1="$1" v2="$2"

    IFS='.' read -ra V1_PARTS <<< "$v1"
    IFS='.' read -ra V2_PARTS <<< "$v2"

    local max_parts=${#V1_PARTS[@]}
    [[ ${#V2_PARTS[@]} -gt $max_parts ]] && max_parts=${#V2_PARTS[@]}

    for ((i=0; i<max_parts; i++)); do
        local p1 p2
        p1=$(safe_int "${V1_PARTS[i]}" 0)
        p2=$(safe_int "${V2_PARTS[i]}" 0)

        if [[ $p1 -gt $p2 ]]; then
            return 0
        elif [[ $p1 -lt $p2 ]]; then
            return 1
        fi
    done

    return 0  # Equal versions
}

# -----------------------------------------------------------------------------
# Path Existence Checker
# -----------------------------------------------------------------------------
# [BUGFIX] Corrected return value semantics
# Problem:  Original function returned found_count as exit code. Bash exit
#           codes are 0-255, so >255 paths would overflow. Also, non-zero
#           return typically means "error" in shell convention, but here it
#           meant "found something" - confusing and error-prone for callers.
# Solution: Output found paths to stdout (one per line). Return 0 if any found,
#           1 if none found. Callers capture output and check if non-empty.
# -----------------------------------------------------------------------------
check_paths_exist() {
    local found_any=false

    for path in "$@"; do
        if [[ -e "$path" ]]; then
            echo "$path"
            found_any=true
        fi
    done

    [[ "$found_any" == true ]]
}

# =============================================================================
# OUTPUT FORMATTING FUNCTIONS
# =============================================================================

# =============================================================================
# [BUGFIX] Header Box Alignment
# Problem:  The padding calculation used a fixed target width of 58, but the
#           box characters themselves (║, spaces) weren't accounted for.
#           This caused misaligned closing box characters in terminal output.
# Solution: Use printf with precise field width. The inner content area is
#           60 chars. Text is left-aligned, remaining space filled with spaces.
# =============================================================================
print_header() {
    local text="$1"
    local max_len=58
    if [[ ${#text} -gt $max_len ]]; then
        text="${text:0:$((max_len-3))}..."
    fi

    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    printf "${CYAN}${BOLD}║  %-60s║${NC}\n" "$text"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
}

print_section() {
    local text="$1"
    local max_len=58
    if [[ ${#text} -gt $max_len ]]; then
        text="${text:0:$((max_len-3))}..."
    fi

    echo ""
    echo -e "${BOLD}┌──────────────────────────────────────────────────────────────┐${NC}"
    printf "${BOLD}│  %-60s│${NC}\n" "$text"
    echo -e "${BOLD}└──────────────────────────────────────────────────────────────┘${NC}"
}

print_subsection() {
    echo -e "  ${BLUE}■ $1${NC}"
}

# =============================================================================
# RESULT TRACKING FUNCTIONS
# =============================================================================
# [HISTORY]
# Problem:  Earlier versions only printed results without tracking them.
#           Impossible to generate summary reports, calculate risk scores,
#           or export findings for later review. Users had to scroll back
#           through terminal to find issues.
#
# Solution: Each result function updates global counters AND stores issue
#           descriptions in arrays. Enables quantified risk scoring and
#           comprehensive report generation. Consistent visual formatting
#           while maintaining audit trail.
# =============================================================================

check_pass() {
    echo -e "    ${GREEN}${CHECKMARK}${NC} $1"
    ((PASS_COUNT++))
}

check_fail() {
    echo -e "    ${RED}${CROSSMARK}${NC} $1"
    CRITICAL_ISSUES+=("$1")
    ((FAIL_COUNT++))
}

check_warn() {
    echo -e "    ${YELLOW}${WARNING}${NC} $1"
    WARNING_ISSUES+=("$1")
    ((WARN_COUNT++))
}

check_info() {
    echo -e "    ${GREY}${INFO}${NC} $1"
    ((INFO_COUNT++))
}

# =============================================================================
# [ENHANCEMENT] Deduplicated manual check registration
# Problem:  Some checks were added multiple times from different code paths,
#           causing duplicate entries in the final checklist (e.g., "Test
#           Recovery Mode" appeared twice). This confused users and made the
#           checklist appear unprofessional.
# Solution: Check if item already exists before adding. O(n) but n is small
#           (typically <30 items). Maintains insertion order.
# =============================================================================
add_manual_check() {
    local new_check="$1"
    # Check for duplicates (exact match)
    for existing in "${MANUAL_CHECKS[@]}"; do
        if [[ "$existing" == "$new_check" ]]; then
            return 0  # Already exists, skip
        fi
    done
    MANUAL_CHECKS+=("$new_check")
}

# Verbose output (only shown with --verbose flag)
verbose_info() {
    if [[ "$VERBOSE_MODE" == true ]]; then
        echo -e "    ${GREY}  → $1${NC}"
    fi
}

# =============================================================================
# PROGRESS INDICATOR
# =============================================================================
# [HISTORY - NEW]
# Problem:  During data gathering phases, script appeared frozen with no
#           feedback. Users unsure if script was working or hung. Some
#           cancelled and restarted unnecessarily.
#
# Solution: Simple progress indicator showing current operation. Uses
#           carriage return to update in place without scrolling terminal.
#           Cleared before next section to avoid visual clutter.
# =============================================================================
show_progress() {
    echo -ne "  ${GREY}⏳ $1...${NC}\r"
}

clear_progress() {
    echo -ne "\033[2K\r"
}

# =============================================================================
# PREREQUISITE CHECKS
# =============================================================================

check_prerequisites() {
    print_section "SYSTEM PREREQUISITES"

    show_progress "Checking macOS version"
    local macos_version
    macos_version=$(sw_vers -productVersion 2>/dev/null)
    clear_progress

    if [[ -z "$macos_version" ]]; then
        check_fail "Cannot determine macOS version - is this a Mac?"
        echo ""
        echo -e "    ${RED}This script only works on macOS systems.${NC}"
        exit 1
    fi

    if ! version_gte "$macos_version" "$MIN_MACOS_VERSION"; then
        check_fail "macOS $macos_version below minimum ($MIN_MACOS_VERSION)"
        echo ""
        echo -e "    ${RED}Please update macOS or use an older script version.${NC}"
        exit 1
    fi
    check_pass "macOS $macos_version (meets minimum $MIN_MACOS_VERSION)"

    # Detect architecture
    local arch
    arch=$(uname -m 2>/dev/null)

    case "$arch" in
        arm64)
            check_pass "Apple Silicon detected (arm64)"
            IS_APPLE_SILICON=true
            # =================================================================
            # [NEW CHECK] Rosetta 2 Installation Status
            # Problem:  Apple Silicon Macs need Rosetta 2 to run Intel apps.
            #           Missing Rosetta means buyer can't run many apps
            #           immediately. Also indicates if Mac was ever used.
            # Solution: Check if Rosetta is installed and inform accordingly.
            # =================================================================
            if /usr/bin/pgrep -q oahd 2>/dev/null || [[ -f "/Library/Apple/usr/share/rosetta/rosetta" ]]; then
                check_info "Rosetta 2: Installed (Intel app compatibility)"
            else
                check_info "Rosetta 2: Not installed (can be added when needed)"
            fi
            ;;
        x86_64)
            check_info "Intel Mac detected (x86_64)"
            IS_APPLE_SILICON=false
            ;;
        *)
            check_warn "Unknown architecture: $arch"
            IS_APPLE_SILICON=false
            ;;
    esac

    # Verify critical system tools
    local required_tools=("system_profiler" "diskutil" "profiles" "ioreg" "csrutil" "nvram")
    local missing_tools=()

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        check_fail "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    check_pass "All required system tools available"

    # =============================================================================
    # [ENHANCEMENT] Verify core data availability before proceeding
    # Problem:  If system_profiler fails completely, many subsequent checks will
    #           produce misleading results (empty data interpreted as "clean").
    # Solution: Quick sanity check that basic system data is accessible. Fail
    #           early with clear message rather than produce unreliable results.
    # =============================================================================
    show_progress "Verifying system data access"
    local test_profile
    test_profile=$(system_profiler SPHardwareDataType 2>/dev/null | head -5)
    clear_progress

    if [[ -z "$test_profile" ]]; then
        check_fail "Cannot access system profile data!"
        echo -e "    ${RED}Try: Full Disk Access for Terminal in System Settings > Privacy${NC}"
        exit 1
    fi

    # =============================================================================
    # [NEW CHECK] Internet Connectivity
    # Problem:  Many verification steps benefit from internet (Activation Lock
    #           verification online, checking Apple warranty, downloading updates).
    #           Users should know connectivity status before proceeding.
    # Solution: Quick ping to Apple's captive portal check (used by macOS itself).
    #           Non-blocking, informational only - script works fully offline.
    # =============================================================================
    show_progress "Checking network connectivity"
    local internet_available=false
    if curl -s --max-time 3 --head "https://www.apple.com/library/test/success.html" 2>/dev/null | grep -q "200"; then
        internet_available=true
        clear_progress
        check_pass "Internet: Connected (can verify warranty online)"
    else
        clear_progress
        check_info "Internet: Not connected (offline mode - all checks still work)"
    fi

    # Check report write permission
    if [[ "$SKIP_REPORT" != true ]]; then
        local desktop_path="$HOME/Desktop"
        if [[ -d "$desktop_path" && -w "$desktop_path" ]]; then
            REPORT_FILE="$desktop_path/MacAudit_$(date +%Y%m%d_%H%M%S).txt"
            check_info "Report will be saved to Desktop"
        else
            check_warn "Cannot write to Desktop - report will be skipped"
            SKIP_REPORT=true
        fi
    fi
}

# =============================================================================
# DATA CACHING
# =============================================================================
# [HISTORY]
# Problem:  Each call to system_profiler takes 1-3 seconds. Earlier versions
#           called it multiple times for different data types, resulting in
#           10+ seconds of unnecessary waiting. Users reported slow feeling.
#
# Solution: Fetch commonly-used data types once at startup and cache in global
#           variables. Parse cached data as needed. Single call per data type
#           reduces total runtime significantly.
#
# [ENHANCEMENT - v10]
# Added: GPU data cache for discrete GPU detection (important for thermal
#        issues on 15"/16" MacBook Pro models with AMD graphics).
# =============================================================================
cache_system_data() {
    echo -e "  ${GREY}Gathering system information...${NC}"

    # =========================================================================
    # [OPTIMIZATION] Combined system_profiler call
    # Problem:  Three separate system_profiler calls added 6-9 seconds total
    #           startup time. Each call re-initializes the profiler framework.
    # Solution: Single call requesting all data types at once. Output is split
    #           afterward using awk. Reduces startup time by ~4-6 seconds.
    # =========================================================================
    show_progress "System profiler data (combined)"
    local combined_profile
    combined_profile=$(system_profiler SPHardwareDataType SPPowerDataType SPDisplaysDataType 2>/dev/null)

    # Split combined output into individual caches
    HW_DATA_CACHE=$(echo "$combined_profile" | awk '/Hardware Overview:/,/^$|^[A-Z].*:$/{print}' | head -50)
    # [BUGFIX] SPPowerDataType section header varies: "Power:" on desktops,
    # "Battery Information:" on laptops. Previous pattern missed laptops entirely.
    # Solution: Match either pattern, or capture everything between Power/Battery headers.
    POWER_DATA_CACHE=$(echo "$combined_profile" | awk '/Power:|Battery Information:/,/^[A-Z].*:$/{if(/^[A-Z].*:$/ && !/Power:/ && !/Battery/) exit; print}')
    GPU_DATA_CACHE=$(echo "$combined_profile" | awk '/Graphics\/Displays:/,/^[A-Z].*:$/{if(/^[A-Z].*:$/ && !/Graphics/) exit; print}')

    # =========================================================================
    # [BUGFIX] Robust fallback for hardware data
    # Problem:  The awk splitting pattern broke on empty lines within sections,
    #           leaving HW_DATA_CACHE non-empty but without actual data fields.
    #           Original fallback only triggered on empty string.
    # Solution: Check for presence of critical field (Serial Number) to validate
    #           that parsing succeeded. Trigger fallback if field is missing.
    # =========================================================================
    if [[ -z "$HW_DATA_CACHE" ]] || ! echo "$HW_DATA_CACHE" | grep -q "Serial Number"; then
        show_progress "Hardware data (fallback)"
        HW_DATA_CACHE=$(system_profiler SPHardwareDataType 2>/dev/null)
    fi
    if [[ -z "$POWER_DATA_CACHE" ]]; then
        POWER_DATA_CACHE=$(system_profiler SPPowerDataType 2>/dev/null)
    fi
    # [BUGFIX] GPU cache validation - check for actual GPU data, not just non-empty
    # Problem:  GPU_DATA_CACHE could be non-empty but contain only header lines
    #           without actual GPU information (awk pattern mismatch).
    # Solution: Verify presence of key GPU field, not just non-empty string.
    if [[ -z "$GPU_DATA_CACHE" ]] || ! echo "$GPU_DATA_CACHE" | grep -qi "Chipset\|Metal\|VRAM\|Display"; then
        GPU_DATA_CACHE=$(system_profiler SPDisplaysDataType 2>/dev/null)
    fi

    show_progress "IORegistry data"
    # =========================================================================
    # [OPTIMIZATION] ioreg with -w0 flag
    # Problem:  ioreg -l without width limit produces massively indented output,
    #           making the cache 2-3x larger than necessary and grep slower.
    #           Also caused 3-5 second delays on systems with complex IORegistry.
    # Solution: Add -w0 to eliminate indentation whitespace. Reduces cache size
    #           by ~60% and improves grep performance throughout script.
    # =========================================================================
    IOREG_CACHE=$(ioreg -l -w0 2>/dev/null)

    clear_progress
    check_pass "System data cached successfully"

    # =========================================================================
    # [OPTIMIZATION] Additional system_profiler caches
    # Problem:  Individual system_profiler calls for Camera, Audio, USB,
    #           Thunderbolt, Bluetooth, and WiFi data added 6-18 seconds of
    #           wait time. Each call reinitializes the profiler framework.
    # Solution: Batch fetch all needed data types upfront and cache globally.
    #           Functions then parse from cache instead of calling profiler.
    # =========================================================================
    show_progress "Memory configuration"
    MEMORY_DATA_CACHE=$(system_profiler SPMemoryDataType 2>/dev/null)
    CAMERA_DATA_CACHE=$(system_profiler SPCameraDataType 2>/dev/null)
    AUDIO_DATA_CACHE=$(system_profiler SPAudioDataType 2>/dev/null)

    show_progress "Connectivity data (USB, Thunderbolt, network)"
    local connectivity_combined
    connectivity_combined=$(system_profiler SPUSBDataType SPThunderboltDataType SPBluetoothDataType SPAirPortDataType 2>/dev/null)
    USB_DATA_CACHE=$(echo "$connectivity_combined" | awk '/USB:/,/^[A-Z].*:$/{if(/^[A-Z].*:$/ && !/USB:/) exit; print}')
    TB_DATA_CACHE=$(echo "$connectivity_combined" | awk '/Thunderbolt:/,/^[A-Z].*:$/{if(/^[A-Z].*:$/ && !/Thunderbolt/) exit; print}')
    BT_DATA_CACHE=$(echo "$connectivity_combined" | awk '/Bluetooth:/,/^[A-Z].*:$/{if(/^[A-Z].*:$/ && !/Bluetooth/) exit; print}')
    # [BUGFIX] awk regex OR operator is | not \|
    WIFI_DATA_CACHE=$(echo "$connectivity_combined" | awk '/AirPort:|Wi-Fi:/,/^[A-Z].*:$/{if(/^[A-Z].*:$/ && !/AirPort/ && !/Wi-Fi/) exit; print}')

    # Fallback for individual data types if awk parsing failed
    [[ -z "$USB_DATA_CACHE" ]] && USB_DATA_CACHE=$(system_profiler SPUSBDataType 2>/dev/null)
    [[ -z "$TB_DATA_CACHE" ]] && TB_DATA_CACHE=$(system_profiler SPThunderboltDataType 2>/dev/null)
    [[ -z "$BT_DATA_CACHE" ]] && BT_DATA_CACHE=$(system_profiler SPBluetoothDataType 2>/dev/null)
    [[ -z "$WIFI_DATA_CACHE" ]] && WIFI_DATA_CACHE=$(system_profiler SPAirPortDataType 2>/dev/null)

    clear_progress

    # Pre-extract commonly used values
    SYSTEM_SERIAL=$(echo "$HW_DATA_CACHE" | grep "Serial Number" | awk -F': ' '{print $2}' | xargs 2>/dev/null)
    SYSTEM_MODEL=$(echo "$HW_DATA_CACHE" | grep "Model Name:" | awk -F': ' '{print $2}' | xargs 2>/dev/null)
    SYSTEM_MODEL_ID=$(echo "$HW_DATA_CACHE" | grep "Model Identifier:" | awk -F': ' '{print $2}' | xargs 2>/dev/null)
    SYSTEM_RAM=$(echo "$HW_DATA_CACHE" | grep "Memory:" | awk -F': ' '{print $2}' | xargs 2>/dev/null)

    # Chip detection (Apple Silicon vs Intel)
    SYSTEM_CHIP=$(echo "$HW_DATA_CACHE" | grep "Chip:" | head -1 | awk -F': ' '{print $2}' | xargs 2>/dev/null)
    if [[ -z "$SYSTEM_CHIP" ]]; then
        SYSTEM_CHIP=$(echo "$HW_DATA_CACHE" | grep "Processor Name:" | awk -F': ' '{print $2}' | xargs 2>/dev/null)
    fi

    # =============================================================================
    # [BUGFIX] Touch Bar Detection
    # Problem:  Previous regex ^MacBookPro1[3-6] incorrectly matched models
    #           WITHOUT Touch Bar (MacBookPro13,1 and MacBookPro14,1 are
    #           13" models with function keys only). Also missed some
    #           Touch Bar models. Led to incorrect manual check prompts.
    # Solution: Explicit list of Touch Bar model identifiers. Only 2016-2020
    #           Intel MacBook Pro models with Touch Bar are listed.
    # =============================================================================
    case "$SYSTEM_MODEL_ID" in
        MacBookPro13,2|MacBookPro13,3|\
        MacBookPro14,2|MacBookPro14,3|\
        MacBookPro15,1|MacBookPro15,2|MacBookPro15,3|MacBookPro15,4|\
        MacBookPro16,1|MacBookPro16,2|MacBookPro16,3|MacBookPro16,4)
            HAS_TOUCH_BAR=true
            ;;
    esac

    # =============================================================================
    # [ENHANCEMENT] Determine device form factor and built-in components
    # Problem:  Testing for displays, cameras, keyboards on devices that don't
    #           have them (Mac mini, Mac Studio, Mac Pro) wastes time and confuses.
    # Solution: Set flags based on model name to control which tests are relevant.
    # =============================================================================
    case "$SYSTEM_MODEL" in
        *"MacBook"*)
            DEVICE_TYPE="laptop"
            HAS_BUILTIN_DISPLAY=true
            HAS_BUILTIN_CAMERA=true
            HAS_BUILTIN_SPEAKERS=true
            HAS_BUILTIN_MIC=true
            HAS_BUILTIN_KEYBOARD=true
            ;;
        *"iMac"*)
            DEVICE_TYPE="all-in-one"
            HAS_BUILTIN_DISPLAY=true
            HAS_BUILTIN_CAMERA=true
            HAS_BUILTIN_SPEAKERS=true
            HAS_BUILTIN_MIC=true
            HAS_BUILTIN_KEYBOARD=false
            ;;
        # =====================================================================
        # [BUGFIX] Desktop Mac Component Detection
        # Problem:  Previous code incorrectly stated Mac mini has no speakers
        #           (only boot chime) and HAS a microphone. Also stated Mac
        #           Studio has no speakers. Both are wrong per Apple specs:
        #           - Mac mini (M1/M2/M4): Built-in speaker for full audio, NO mic
        #           - Mac Studio: High-fidelity speaker system WITH Spatial Audio,
        #             AND a studio-quality three-mic array
        #           - Mac Pro: No built-in speaker, no mic (correct)
        # Solution: Corrected flags based on Apple's official specifications.
        # =====================================================================
        *"Mac mini"*)
            DEVICE_TYPE="desktop"
            HAS_BUILTIN_DISPLAY=false
            HAS_BUILTIN_CAMERA=false
            HAS_BUILTIN_SPEAKERS=true    # Mac mini has built-in speaker (full audio, not just chime)
            HAS_BUILTIN_MIC=false        # Mac mini has NO built-in microphone
            HAS_BUILTIN_KEYBOARD=false
            ;;
        *"Mac Studio"*)
            DEVICE_TYPE="desktop"
            HAS_BUILTIN_DISPLAY=false
            HAS_BUILTIN_CAMERA=false
            HAS_BUILTIN_SPEAKERS=true    # Mac Studio has high-fidelity speaker system with Spatial Audio
            HAS_BUILTIN_MIC=true         # Mac Studio has studio-quality three-mic array
            HAS_BUILTIN_KEYBOARD=false
            ;;
        *"Mac Pro"*)
            DEVICE_TYPE="desktop"
            HAS_BUILTIN_DISPLAY=false
            HAS_BUILTIN_CAMERA=false
            HAS_BUILTIN_SPEAKERS=false   # Mac Pro has NO built-in speaker
            HAS_BUILTIN_MIC=false        # Mac Pro has NO built-in mic
            HAS_BUILTIN_KEYBOARD=false
            ;;
        *)
            # Unknown model - assume laptop features for safety
            DEVICE_TYPE="unknown"
            HAS_BUILTIN_DISPLAY=true
            HAS_BUILTIN_CAMERA=true
            HAS_BUILTIN_SPEAKERS=true
            HAS_BUILTIN_MIC=true
            HAS_BUILTIN_KEYBOARD=true
            ;;
    esac

    verbose_info "Device type: $DEVICE_TYPE"


    # Detect Touch ID capability
    # [OPTIMIZATION] Uses cached ioreg instead of separate call
    if echo "$IOREG_CACHE" | grep -q "AppleSEPKeyStore"; then
        HAS_TOUCH_ID=true
    fi
}

# =============================================================================
# PHASE 1: PHYSICAL SERIAL VERIFICATION
# =============================================================================

verify_physical_serial() {
    print_section "PHASE 1: PHYSICAL SERIAL VERIFICATION"

    echo -e "  ${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${YELLOW}║  ${BOLD}THIS IS THE MOST IMPORTANT ANTI-FRAUD CHECK!${NC}${YELLOW}              ║${NC}"
    echo -e "  ${YELLOW}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${YELLOW}║  Find the serial number ENGRAVED on the device:            ║${NC}"
    echo -e "  ${YELLOW}║                                                            ║${NC}"
    echo -e "  ${YELLOW}║  • MacBook: Bottom case, near regulatory markings          ║${NC}"
    echo -e "  ${YELLOW}║  • iMac: Stand base or back panel lower edge               ║${NC}"
    echo -e "  ${YELLOW}║  • Mac mini: Bottom plate                                  ║${NC}"
    echo -e "  ${YELLOW}║  • Mac Studio: Bottom plate                                ║${NC}"
    echo -e "  ${YELLOW}║  • Mac Pro: Top case handle or back panel                  ║${NC}"
    echo -e "  ${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # =============================================================================
    # [HISTORY - PASSIVE VS ACTIVE VERIFICATION]
    # Problem:  Simply displaying system serial and asking "does it match?" let
    #           users skim past subtle differences. Fraudsters swap logic boards
    #           between cases - stolen/blacklisted logic board in clean case.
    #           Character confusion common: '8' vs 'B', 'O' vs '0', 'I' vs '1',
    #           'S' vs '5'. Users frequently missed these on quick visual checks.
    #
    # Solution: Force active comparison. User MUST type serial they see on the
    #           physical case. Script compares to system-reported serial. Both
    #           normalized (uppercase, no spaces/dashes) before comparison to
    #           reduce false negatives from formatting differences.
    # =============================================================================

    # =========================================================================
    # [BUGFIX] Handle missing system serial gracefully
    # Problem:  If SYSTEM_SERIAL is empty (parsing failed), any user input
    #           would cause a "mismatch" false positive, creating panic.
    # Solution: Detect empty serial early and fail with clear instructions.
    # =========================================================================
    if [[ -z "$SYSTEM_SERIAL" ]]; then
        check_fail "Could not retrieve system serial number!"
        check_info "Open: Apple Menu > About This Mac > More Info > System Report"
        add_manual_check "CRITICAL: Manually verify serial via System Information app"
        add_manual_check "Compare with serial engraved on device case"
        return
    fi

    echo -e "  System reports serial: ${BOLD}$SYSTEM_SERIAL${NC}"
    echo ""
    read -rp "  >> TYPE THE SERIAL FROM THE CASE: " raw_input

    # Normalize both serials
    local user_serial sys_serial_normalized
    user_serial=$(to_uppercase "$raw_input")
    user_serial="${user_serial// /}"
    user_serial="${user_serial//-/}"

    sys_serial_normalized=$(to_uppercase "$SYSTEM_SERIAL")
    sys_serial_normalized="${sys_serial_normalized// /}"

    echo ""

    # =========================================================================
    # [ENHANCEMENT] Serial number input validation
    # Problem:  No validation of entered serial number. Typos or accidental
    #           inputs (e.g., just "ok") were accepted without warning.
    #           Apple serials have specific lengths (11-12 characters).
    # Solution: Warn if input has implausible length.
    # =========================================================================
    if [[ -z "$user_serial" ]]; then
        check_warn "No serial entered - comparison skipped"
        add_manual_check "CRITICAL: Compare case serial with $SYSTEM_SERIAL"
        return
    fi

    local serial_len=${#user_serial}
    if [[ $serial_len -lt 8 ]] || [[ $serial_len -gt 14 ]]; then
        check_warn "Entered serial has unusual length ($serial_len characters)"
        check_info "Apple serials are typically 11-12 characters"
    fi

    if [[ "$user_serial" == "$sys_serial_normalized" ]]; then
        check_pass "SERIAL MATCH - Logic board and case are properly paired"
    else
        check_fail "SERIAL MISMATCH - Logic board may have been swapped!"
        echo ""
        echo -e "    ${RED}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "    ${RED}║                  ⚠️  MAJOR RED FLAG ⚠️                       ║${NC}"
        echo -e "    ${RED}╠════════════════════════════════════════════════════════════╣${NC}"
        echo -e "    ${RED}║  The logic board serial does NOT match the case serial!    ║${NC}"
        echo -e "    ${RED}║                                                            ║${NC}"
        echo -e "    ${RED}║  This could mean:                                          ║${NC}"
        echo -e "    ${RED}║  • Stolen logic board in a legitimate case                 ║${NC}"
        echo -e "    ${RED}║  • Blacklisted device in disguise                          ║${NC}"
        echo -e "    ${RED}║  • Undisclosed repair or refurbishment                     ║${NC}"
        echo -e "    ${RED}║  • Parts Mac assembled from multiple devices               ║${NC}"
        echo -e "    ${RED}║                                                            ║${NC}"
        echo -e "    ${RED}║  RECOMMENDATION: Do not purchase unless seller explains.   ║${NC}"
        echo -e "    ${RED}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -rp "  Press [ENTER] to acknowledge this risk and continue..."
    fi
}

# =============================================================================
# PHASE 2: SYSTEM IDENTITY
# =============================================================================

check_system_identity() {
    print_section "PHASE 2: SYSTEM IDENTITY"

    # =============================================================================
    # [ENHANCEMENT] Show device type in identity section
    # Problem:  Just showing model name didn't clarify what type of Mac it is.
    # Solution: Include device type classification for clarity.
    # =============================================================================
    local type_label=""
    case "$DEVICE_TYPE" in
        "laptop") type_label="Laptop" ;;
        "desktop") type_label="Desktop" ;;
        "all-in-one") type_label="All-in-One" ;;
        *) type_label="Unknown" ;;
    esac
    check_info "Model:      ${SYSTEM_MODEL:-Unknown} [$type_label]"
    check_info "Identifier: ${SYSTEM_MODEL_ID:-Unknown}"
    check_info "Chip/CPU:   ${SYSTEM_CHIP:-Unknown}"
    check_info "Memory:     ${SYSTEM_RAM:-Unknown}"

    # =========================================================================
    # [NEW CHECK] RAM Type and Speed Details
    # Problem:  Just showing "16 GB" doesn't reveal if RAM is upgradeable,
    #           what speed it runs at, or if it's soldered. Important for
    #           future upgrade planning and verifying advertised specs.
    # Solution: Extract and display RAM type (DDR4/DDR5/LPDDR) and speed.
    # =========================================================================
    local ram_type ram_speed
    # [OPTIMIZATION] Use cached memory data
    ram_type=$(echo "$MEMORY_DATA_CACHE" | grep "Type:" | head -1 | awk -F': ' '{print $2}' | xargs)
    ram_speed=$(echo "$MEMORY_DATA_CACHE" | grep "Speed:" | head -1 | awk -F': ' '{print $2}' | xargs)
    if [[ -n "$ram_type" ]]; then
        local ram_detail="${ram_type}"
        [[ -n "$ram_speed" ]] && ram_detail="${ram_type} @ ${ram_speed}"
        check_info "RAM Type:   $ram_detail"
        # Soldered RAM detection (Apple Silicon and some Intel)
        if [[ "$ram_type" == *"LPDDR"* ]]; then
            check_info "RAM Note:   Soldered (not upgradeable)"
        fi
    fi

    check_info "Serial:     ${SYSTEM_SERIAL:-Unknown}"

    # Hardware UUID
    local uuid
    uuid=$(echo "$HW_DATA_CACHE" | grep "Hardware UUID" | awk -F': ' '{print $2}' | xargs 2>/dev/null)
    if [[ -n "$uuid" ]]; then
        check_pass "Hardware UUID: ${uuid:0:8}..."
        verbose_info "Full UUID: $uuid"
    else
        check_warn "Hardware UUID not found"
    fi

    # Provisioning UDID (primarily Apple Silicon)
    local prov_udid
    prov_udid=$(echo "$HW_DATA_CACHE" | grep "Provisioning UDID" | awk -F': ' '{print $2}' | xargs 2>/dev/null)
    if [[ -n "$prov_udid" ]]; then
        check_info "Prov. UDID: ${prov_udid:0:12}..."
    fi

    # Board ID
    local board_id
    # [OPTIMIZATION] Uses cached ioreg
    board_id=$(echo "$IOREG_CACHE" | grep "board-id" | head -1 | awk -F'"' '{print $4}')
    if [[ -n "$board_id" ]]; then
        check_info "Board ID:   $board_id"
    fi

    # Special features detection
    if [[ "$HAS_TOUCH_BAR" == true ]]; then
        check_info "Touch Bar:  Present (2016-2020 MacBook Pro)"
        add_manual_check "Test Touch Bar: Volume slider, brightness, app controls"
    fi

    if [[ "$HAS_TOUCH_ID" == true ]]; then
        check_info "Touch ID:   Hardware detected"
        add_manual_check "Test Touch ID: System Preferences > Touch ID (requires user setup)"
    fi

    # =============================================================================
    # [NEW] Apple Warranty & Coverage Reminder
    # Problem:  Buyers often forget to verify warranty status. AppleCare+ coverage
    #           significantly affects used Mac value. Script cannot check this
    #           directly (requires Apple ID authentication), but should remind.
    # Solution: Add manual check with direct URL for warranty verification.
    # =============================================================================
    add_manual_check "Check warranty: https://checkcoverage.apple.com (Serial: $SYSTEM_SERIAL)"
}

# =============================================================================
# PHASE 3: ENTERPRISE LOCK DETECTION (MDM/DEP)
# =============================================================================

check_enterprise_locks() {
    print_section "PHASE 3: ENTERPRISE LOCKS (MDM/DEP)"

    show_progress "Checking enrollment status"

    # =============================================================================
    # [HISTORY - MDM DETECTION]
    # Problem:  Simple grep for "MDM" produced false positives/negatives across
    #           macOS versions. Output format changed between releases. Some
    #           partially-wiped enterprise devices showed confusing results.
    #
    # Solution: Check for BOTH "Enrolled via DEP: No" AND "MDM enrollment: No".
    #           Any other combination indicates potential enterprise control.
    #           Also check JAMF-specific paths and common MDM artifacts.
    #
    # Note:     DEP (Device Enrollment Program) renamed to ABM/ASM (Apple
    #           Business/School Manager) but technical identifiers unchanged.
    # =============================================================================

    local mdm_output dep_status mdm_status
    mdm_output=$(profiles status -type enrollment 2>/dev/null)
    clear_progress

    dep_status=$(echo "$mdm_output" | grep "Enrolled via DEP" | awk -F': ' '{print $2}' | xargs 2>/dev/null)
    mdm_status=$(echo "$mdm_output" | grep "MDM enrollment" | awk -F': ' '{print $2}' | xargs 2>/dev/null)

    print_subsection "Device Enrollment Program (DEP/ABM)"
    case "$dep_status" in
        "No")
            check_pass "DEP: Not enrolled (consumer device)"
            ;;
        "Yes")
            check_fail "DEP: ENROLLED - Device registered to an organization!"
            echo -e "    ${RED}     Organization can remotely reclaim this device at any time.${NC}"
            ;;
        *)
            check_warn "DEP: Status unclear (${dep_status:-not reported})"
            ;;
    esac

    print_subsection "Mobile Device Management (MDM)"
    case "$mdm_status" in
        "No")
            check_pass "MDM: Not enrolled (not remotely managed)"
            ;;
        "Yes")
            check_fail "MDM: ENROLLED - Device is actively managed!"
            echo -e "    ${RED}     Remote wipe, lock, and policy enforcement possible.${NC}"
            ;;
        *)
            check_warn "MDM: Status unclear (${mdm_status:-not reported})"
            ;;
    esac

    # =============================================================================
    # [HISTORY - JAMF DETECTION]
    # Problem:  JAMF Pro is most common enterprise MDM for Macs. Sometimes MDM
    #           enrollment appears clean but JAMF remnants remain from incomplete
    #           wipe, indicating device was previously enterprise-owned.
    #
    # Solution: Check filesystem paths specific to JAMF installations. Presence
    #           of any indicates current or previous enterprise use.
    # =============================================================================

    print_subsection "JAMF Enterprise Management"
    local jamf_paths=(
        "/usr/local/bin/jamf"
        "/usr/local/jamf"
        "/Library/LaunchDaemons/com.jamfsoftware.jamf.daemon.plist"
        "/Library/LaunchDaemons/com.jamfsoftware.startupItem.plist"
        "/Library/Preferences/com.jamfsoftware.jamf.plist"
        "/var/log/jamf.log"
        "/Library/Application Support/JAMF"
    )

    # =============================================================================
    # [REFACTOR] Use centralized path checker
    # Problem:  Duplicated path-checking logic across MDM, JAMF, and enterprise
    #           software detection. Inconsistent output formatting and harder
    #           to maintain. The check_paths_exist function was defined but
    #           never used (dead code).
    # Solution: Utilize the existing check_paths_exist function for consistency.
    # =============================================================================
    local jamf_found_paths
    jamf_found_paths=$(check_paths_exist "${jamf_paths[@]}")

    if [[ -n "$jamf_found_paths" ]]; then
        while IFS= read -r path; do
            check_fail "JAMF artifact: $path"
        done <<< "$jamf_found_paths"
        echo -e "    ${RED}     JAMF remnants indicate previous/current enterprise use.${NC}"
    else
        check_pass "No JAMF management software detected"
    fi

    # Configuration profiles
    print_subsection "Configuration Profiles"
    # [BUGFIX] grep -c outputs "0" but exits with code 1 when no matches.
    # Using || echo "0" caused "0\n0" output, breaking integer comparison.
    # Solution: Capture output, let grep fail silently, default to 0 if empty.
    local mdm_profiles
    mdm_profiles=$(profiles list 2>/dev/null | grep -c "com.apple.mdm") || true
    mdm_profiles=${mdm_profiles:-0}

    if [[ "$mdm_profiles" -gt 0 ]]; then
        check_fail "MDM profiles installed: $mdm_profiles"
    else
        check_pass "No MDM configuration profiles detected"
    fi

    # Other enterprise MDM solutions
    print_subsection "Other Enterprise Software"
    local enterprise_paths=(
        "/Library/Intune"
        "/Library/Microsoft/Intune"
        "/Library/Kandji"
        "/Library/Mosyle"
        "/Library/Addigy"
        "/Library/SimpleMDM"
        "/Library/Workspace ONE"
        "/Library/Application Support/AirWatch"
    )

    local enterprise_found_paths
    enterprise_found_paths=$(check_paths_exist "${enterprise_paths[@]}")

    if [[ -n "$enterprise_found_paths" ]]; then
        while IFS= read -r path; do
            local mdm_name
            mdm_name=$(basename "$path")
            check_warn "Enterprise software detected: $mdm_name"
        done <<< "$enterprise_found_paths"
    else
        check_pass "No other enterprise management software detected"
    fi
}

# =============================================================================
# PHASE 4: ACTIVATION LOCK (iCloud)
# =============================================================================

check_activation_lock() {
    print_section "PHASE 4: ACTIVATION LOCK (iCloud)"

    # =============================================================================
    # [HISTORY]
    # Problem:  Many scripts completely missed this critical check. An Activation-
    #           Locked device is essentially unusable by buyer without original
    #           owner's Apple ID credentials. Cannot be bypassed by Apple.
    #
    # Solution: Check system_profiler output for "Activation Lock Status" field.
    #           Available on macOS 10.15+ for Apple Silicon and T2-equipped Intel.
    #
    # Limitation: Check only works when booted into OS. In Recovery Mode,
    #             Activation Lock manifests as login prompt instead.
    # =============================================================================

    local activation_status
    activation_status=$(echo "$HW_DATA_CACHE" | grep "Activation Lock" | awk -F': ' '{print $2}' | xargs 2>/dev/null)

    case "$activation_status" in
        "Disabled")
            check_pass "Activation Lock: DISABLED (ready for new owner)"
            ;;
        "Enabled")
            check_fail "Activation Lock: ENABLED - Device is iCloud locked!"
            echo ""
            echo -e "    ${RED}╔════════════════════════════════════════════════════════════╗${NC}"
            echo -e "    ${RED}║            ⛔ CRITICAL: ACTIVATION LOCK ON ⛔               ║${NC}"
            echo -e "    ${RED}╠════════════════════════════════════════════════════════════╣${NC}"
            echo -e "    ${RED}║  This device CANNOT be activated without the original      ║${NC}"
            echo -e "    ${RED}║  owner's Apple ID email and password!                      ║${NC}"
            echo -e "    ${RED}║                                                            ║${NC}"
            echo -e "    ${RED}║  • If erased, it becomes a paperweight                     ║${NC}"
            echo -e "    ${RED}║  • Apple cannot bypass this (security by design)           ║${NC}"
            echo -e "    ${RED}║  • Seller MUST disable before you pay                      ║${NC}"
            echo -e "    ${RED}║                                                            ║${NC}"
            echo -e "    ${RED}║  Steps: Settings > Apple ID > Find My > Find My Mac > OFF ║${NC}"
            echo -e "    ${RED}╚════════════════════════════════════════════════════════════╝${NC}"
            ;;
        *)
            check_warn "Activation Lock: Status unclear (${activation_status:-not reported})"
            add_manual_check "Verify Activation Lock: Settings > Apple ID > Find My"
            ;;
    esac

    # Check for Find My token in NVRAM
    local find_my_nvram
    find_my_nvram=$(nvram -p 2>/dev/null | grep -i "fmm-mobileme-token" || true)

    if [[ -n "$find_my_nvram" ]]; then
        check_warn "Find My Mac token present in NVRAM"
        verbose_info "This may indicate Find My was recently active"
    fi
}

# =============================================================================
# PHASE 5: STORAGE HEALTH
# =============================================================================

check_storage_health() {
    print_section "PHASE 5: STORAGE HEALTH"

    # =============================================================================
    # [HISTORY - BOOT VOLUME DETECTION]
    # Problem:  Earlier versions hardcoded /dev/disk0 as boot drive. Incorrect for:
    #           (a) External boot drives
    #           (b) APFS containers where synthesized volume isn't on disk0
    #           (c) Fusion Drives with complex disk layouts
    #           (d) Multiple internal drives (Mac Pro, Mac Studio)
    #
    # Solution: Start from root filesystem (/), trace back to physical device,
    #           check SMART on that device. Handles all edge cases correctly.
    # =============================================================================

    local boot_device_raw boot_device
    boot_device_raw=$(df / 2>/dev/null | tail -1 | awk '{print $1}')

    # Strip partition/slice suffix: /dev/disk3s1s1 -> /dev/disk3
    boot_device=$(echo "$boot_device_raw" | sed -E 's/s[0-9]+.*$//')

    if [[ ! -e "$boot_device" ]]; then
        boot_device="/dev/disk0"
    fi

    print_subsection "Boot Device: $boot_device"

    local disk_info
    disk_info=$(diskutil info "$boot_device" 2>/dev/null)

    # Capacity
    local capacity
    capacity=$(echo "$disk_info" | grep "Disk Size" | head -1 | sed 's/.*: *//' | awk '{print $1, $2}')
    check_info "Capacity: ${capacity:-Unknown}"

    # Storage type
    local storage_type
    storage_type=$(echo "$disk_info" | grep "Solid State" | awk -F': ' '{print $2}' | xargs 2>/dev/null)
    case "$storage_type" in
        "Yes")
            check_info "Type: SSD (Solid State)"
            ;;
        "No")
            check_warn "Type: HDD (Spinning disk - slower, more fragile)"
            ;;
    esac

    # SMART Status
    print_subsection "S.M.A.R.T Health"
    local smart_status
    smart_status=$(echo "$disk_info" | grep "SMART Status" | awk -F': ' '{print $2}' | xargs 2>/dev/null)

    case "$smart_status" in
        "Verified")
            check_pass "S.M.A.R.T: Verified (drive healthy)"
            ;;
        "Not Supported")
            check_info "S.M.A.R.T: Not supported (normal for some NVMe/Apple SSDs)"
            ;;
        "Failing"|"About to Fail")
            check_fail "S.M.A.R.T: $smart_status - DRIVE IS FAILING!"
            echo -e "    ${RED}     DO NOT PURCHASE. Data loss imminent.${NC}"
            ;;
        *)
            if [[ -n "$smart_status" ]]; then
                check_warn "S.M.A.R.T: $smart_status (unusual status)"
            else
                check_info "S.M.A.R.T: Status unavailable"
            fi
            ;;
    esac

    # =========================================================================
    # [ENHANCEMENT] Human-readable storage units
    # Problem:  df -h outputs "Gi" (gibibytes) which confuses non-technical
    #           users who expect "GB". While technically different (1 GiB =
    #           1.074 GB), for a used Mac audit the distinction is irrelevant.
    # Solution: Use df with -H flag (SI units: GB, MB) instead of -h (binary).
    #           More intuitive for average users comparing to advertised specs.
    # =========================================================================
    print_subsection "Volume Usage"
    local free_space used_pct
    # =========================================================================
    # [BUGFIX] Free space formatting with proper unit display
    # Problem:  df -H outputs "182G" without space or full "GB" suffix.
    #           This looked incomplete and unprofessional in output.
    # Solution: Post-process the output to add space and full unit name.
    #           Handles G, M, T suffixes for various storage sizes.
    # =========================================================================
    local raw_free
    raw_free=$(df -H / 2>/dev/null | tail -1 | awk '{print $4}')
    # Add space before unit and expand abbreviation
    free_space=$(echo "$raw_free" | sed -E 's/([0-9])([GMTK])$/\1 \2B/')
    used_pct=$(df -h / 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%')

    check_info "Free Space: ${free_space:-Unknown}"

    local used_int
    used_int=$(safe_int "$used_pct" 0)
    if [[ $used_int -gt $DISK_USAGE_CRITICAL ]]; then
        check_warn "Disk ${used_pct}% full - critically low space"
    elif [[ $used_int -gt $DISK_USAGE_WARNING ]]; then
        check_info "Disk ${used_pct}% full - may need cleanup"
    else
        check_pass "Disk usage healthy: ${used_pct}%"
    fi
}

# =============================================================================
# PHASE 6: BATTERY HEALTH
# =============================================================================

check_battery_health() {
    print_section "PHASE 6: BATTERY HEALTH"

    # Check if device has a battery
    # =============================================================================
    # [ENHANCEMENT] Clear messaging for desktop Macs without battery
    # Problem:  Original message "No battery detected" was ambiguous - could be
    #           interpreted as a hardware fault rather than expected behavior.
    # Solution: Explicitly state this is normal for the device type.
    # =============================================================================
    if ! echo "$POWER_DATA_CACHE" | grep -q "Battery Information"; then
        case "$DEVICE_TYPE" in
            "desktop"|"all-in-one")
                check_pass "No battery (normal for ${SYSTEM_MODEL})"
                ;;
            "laptop")
                check_fail "No battery detected on laptop - hardware issue!"
                ;;
            *)
                check_info "No battery detected (Desktop Mac)"
                ;;
        esac
        return
    fi

    # Cycle Count
    print_subsection "Charge Cycles"
    local cycles
    cycles=$(echo "$POWER_DATA_CACHE" | grep "Cycle Count" | awk '{print $NF}' | head -1)
    local cycles_int
    cycles_int=$(safe_int "$cycles" 0)

    # =========================================================================
    # [REFACTOR] Use threshold constants for battery cycle evaluation
    # Problem:  Hardcoded cycle thresholds made maintenance difficult and
    #           values were inconsistent with Apple's official guidelines.
    # Solution: Reference named constants defined at script start.
    # =========================================================================
    if [[ $cycles_int -gt 0 ]]; then
        if [[ $cycles_int -lt 100 ]]; then
            check_pass "Cycles: $cycles_int (like new)"
        elif [[ $cycles_int -lt $BATTERY_CYCLES_EXCELLENT ]]; then
            check_pass "Cycles: $cycles_int (excellent)"
        elif [[ $cycles_int -lt $BATTERY_CYCLES_GOOD ]]; then
            check_pass "Cycles: $cycles_int (good)"
        elif [[ $cycles_int -lt $BATTERY_CYCLES_MODERATE ]]; then
            check_warn "Cycles: $cycles_int (moderate wear)"
        elif [[ $cycles_int -lt $BATTERY_CYCLES_HIGH ]]; then
            check_warn "Cycles: $cycles_int (significant wear - replacement soon)"
        else
            check_fail "Cycles: $cycles_int (HIGH - battery likely degraded)"
        fi
    else
        check_warn "Cycle count unavailable"
    fi

    # Condition
    print_subsection "Battery Condition"
    local condition
    condition=$(echo "$POWER_DATA_CACHE" | grep "Condition:" | awk -F': ' '{print $2}' | xargs 2>/dev/null)

    case "$condition" in
        "Normal")
            check_pass "Condition: Normal"
            ;;
        "Service Recommended"|"Replace Soon")
            check_warn "Condition: $condition (degraded performance)"
            ;;
        "Replace Now"|"Check Battery")
            check_fail "Condition: $condition (needs immediate attention)"
            ;;
        *)
            if [[ -n "$condition" ]]; then
                check_info "Condition: $condition"
            else
                check_info "Condition: Not reported"
            fi
            ;;
    esac

    # =============================================================================
    # [HISTORY - BATTERY CAPACITY CALCULATION]
    # Problem:  Calculating health percentage (current/design capacity * 100)
    #           requires floating-point math. 'bc' not installed by default on
    #           all Macs. Script failed silently or crashed when bc missing.
    #
    # Solution: Use 'awk' for calculation. POSIX standard, always available on
    #           macOS. Slightly more verbose but guaranteed to work.
    # =============================================================================

    print_subsection "Capacity Health"
    # =========================================================================
    # [BUGFIX] Battery capacity detection on modern macOS
    # Problem:  Previous code searched for "Design Capacity" which doesn't exist
    #           on most Macs. When not found, fallback defaulted to 1, causing
    #           absurd calculations like "399400%" (3994mAh / 1mAh).
    # Solution: Try multiple field names for maximum capacity percentage.
    #           Apple uses different names across macOS versions:
    #           - "Maximum Capacity" (common)
    #           - "State of Health" (some versions)
    #           If percentage not found, show raw mAh without bogus calculation.
    # =========================================================================
    local max_pct
    # Try multiple patterns - Apple changed field names across versions
    max_pct=$(echo "$POWER_DATA_CACHE" | grep -E "Maximum Capacity|State of Health|MaxCapacity" | grep -oE '[0-9]+%' | tr -d '%' | head -1)

    if [[ -n "$max_pct" ]]; then
        local pct_int
        pct_int=$(safe_int "$max_pct" 100)
        if [[ $pct_int -ge 80 ]]; then
            check_pass "Health: ${max_pct}% of original capacity"
        elif [[ $pct_int -ge 70 ]]; then
            check_warn "Health: ${max_pct}% - degraded, replacement recommended"
        else
            check_fail "Health: ${max_pct}% - battery significantly degraded"
        fi

        if [[ $pct_int -lt 80 ]]; then
            check_info "May be eligible for Apple battery replacement"
        fi
    else
        # No percentage available - show raw capacity if possible
        local current_cap
        current_cap=$(echo "$POWER_DATA_CACHE" | grep -E "Full Charge Capacity|MaxCapacity" | grep -oE '[0-9]+' | head -1)

        if [[ -n "$current_cap" ]] && [[ "$current_cap" -gt 0 ]]; then
            check_info "Current capacity: ${current_cap} mAh"
            check_info "Original design capacity not reported by system"
        else
            check_info "Capacity details unavailable"
        fi
    fi

    # =========================================================================
    # [BUGFIX] Battery-specific manufacturer detection
    # Problem:  Previous grep for "Manufacturer" matched ANY device in ioreg,
    #           not just the battery. This caused false positives like
    #           "C-Media Electronics Inc." (a USB audio chip manufacturer)
    #           being reported as a third-party battery - alarming users
    #           unnecessarily and undermining trust in the script.
    # Solution: Use ioreg with specific class filter (-c AppleSmartBattery)
    #           to query ONLY the battery device. This ensures we get the
    #           actual battery manufacturer, not random USB peripherals.
    #           Apple-authorized battery manufacturers include:
    #           - Apple Inc., SMP (Simplo), SWD (Sunwoda), DSY (Desay)
    # =========================================================================
    print_subsection "Battery Authenticity"
    local battery_mfg=""

    # Query specifically the AppleSmartBattery class - NOT the full ioreg cache
    # The -c flag filters to only that IOClass, avoiding false matches
    battery_mfg=$(ioreg -rc AppleSmartBattery 2>/dev/null | \
        grep '"Manufacturer"' | \
        head -1 | \
        sed 's/.*"Manufacturer" *= *"\([^"]*\)".*/\1/')

    # Fallback: Try alternate field name used on some systems
    if [[ -z "$battery_mfg" ]]; then
        battery_mfg=$(ioreg -rc AppleSmartBattery 2>/dev/null | \
            grep '"DeviceName"\|"BatteryManufacturer"' | \
            head -1 | \
            sed 's/.*= *"\([^"]*\)".*/\1/')
    fi

    # =========================================================================
    # [BUGFIX] Battery manufacturer evaluation with proper logic flow
    # Problem:  Previous code had regex matching DSY/SMP/SWD in first elif,
    #           then separate elifs for each that were never reached.
    #           User saw "DSY (genuine/authorized)" instead of the more
    #           informative "Desay Battery (Apple-authorized)" explanation.
    # Solution: Check specific abbreviations FIRST before the generic regex.
    #           This provides better user feedback about what each code means.
    # =========================================================================
    if [[ -z "$battery_mfg" ]]; then
        check_info "Manufacturer: Not reported (normal for some Mac models)"
    elif [[ "$battery_mfg" == "Apple" || "$battery_mfg" == "Apple Inc." ]]; then
        check_pass "Manufacturer: Apple (genuine)"
    elif [[ "$battery_mfg" == "SMP" ]]; then
        check_pass "Manufacturer: Simplo Technology (Apple-authorized supplier)"
    elif [[ "$battery_mfg" == "SWD" ]]; then
        check_pass "Manufacturer: Sunwoda Electronic (Apple-authorized supplier)"
    elif [[ "$battery_mfg" == "DSY" ]]; then
        check_pass "Manufacturer: Desay Battery (Apple-authorized supplier)"
    elif [[ "$battery_mfg" =~ ^(Simplo|Sunwoda|Desay)$ ]]; then
        # Full names sometimes reported instead of abbreviations
        check_pass "Manufacturer: $battery_mfg (Apple-authorized supplier)"
    else
        check_warn "Manufacturer: $battery_mfg (possibly third-party)"
        echo -e "    ${YELLOW}     Third-party batteries may have lower capacity or safety concerns.${NC}"
        echo -e "    ${YELLOW}     Note: Some legitimate repairs use authorized non-Apple parts.${NC}"
    fi
}

# =============================================================================
# PHASE 7: GPU & GRAPHICS
# =============================================================================
# [HISTORY - NEW IN v10]
# Problem:  Original script completely missed GPU checks. 15"/16" MacBook Pro
#           models with AMD discrete GPUs are notorious for GPU failures
#           (artifacting, crashes, thermal issues). Many used Macs sold because
#           of failing dGPU. Also, GPU swaps in repairs not disclosed.
#
# Solution: Dedicated GPU section checking for discrete graphics, GPU health
#           indicators, and providing thermal test guidance specific to GPU.
# =============================================================================

check_gpu_health() {
    print_section "PHASE 7: GPU & GRAPHICS"

    print_subsection "Graphics Hardware"

    # =========================================================================
    # [BUGFIX] GPU detection with inline fallback
    # Problem:  GPU_DATA_CACHE from awk splitting often empty or malformed.
    #           Even with fallback in cache_system_data, data was sometimes
    #           missing key fields. MacBook Air with Intel Iris GPU not detected.
    # Solution: Use local variable with fresh fetch if cache is inadequate.
    #           This ensures GPU check works even if caching partially failed.
    # =========================================================================
    local gpu_info="$GPU_DATA_CACHE"

    # Verify cache has actual GPU data, not just empty or header-only content
    if [[ -z "$gpu_info" ]] || ! echo "$gpu_info" | grep -qi "Chipset Model"; then
        gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null)
    fi

    # Count GPUs
    local gpu_count
    gpu_count=$(echo "$gpu_info" | grep -c "Chipset Model" 2>/dev/null) || true
    gpu_count=${gpu_count:-0}

    if [[ "$gpu_count" -eq 0 ]]; then
        check_warn "No GPU information available"
        return
    fi

    check_info "GPU(s) detected: $gpu_count"

    # Parse GPU info
    local gpu_models
    gpu_models=$(echo "$gpu_info" | grep "Chipset Model" | awk -F': ' '{print $2}' | xargs 2>/dev/null)

    local has_dgpu=false
    local has_amd=false

    while IFS= read -r gpu; do
        [[ -z "$gpu" ]] && continue

        check_info "GPU: $gpu"

        # Check for discrete GPU
        if [[ "$gpu" =~ AMD|Radeon|NVIDIA|GeForce ]]; then
            has_dgpu=true
            if [[ "$gpu" =~ AMD|Radeon ]]; then
                has_amd=true
            fi
        fi
    done <<< "$gpu_models"

    if [[ "$has_dgpu" == true ]]; then
        check_warn "Discrete GPU detected"
        echo -e "    ${YELLOW}     Discrete GPUs can fail independently. Test thoroughly!${NC}"
        add_manual_check "GPU stress test: Run graphics-intensive app, watch for artifacts"
        add_manual_check "Check for GPU-related kernel panics (see Phase 11)"

        if [[ "$has_amd" == true ]]; then
            check_info "AMD Radeon GPU - known for thermal issues in some models"
            add_manual_check "Test external display output via Thunderbolt/HDMI"
        fi
    else
        check_pass "Integrated GPU only (more reliable)"
    fi

    # VRAM
    local vram
    vram=$(echo "$gpu_info" | grep "VRAM" | head -1 | awk -F': ' '{print $2}' | xargs 2>/dev/null)
    if [[ -n "$vram" ]]; then
        check_info "VRAM: $vram"
    fi

    # Metal support
    local metal_support
    metal_support=$(echo "$gpu_info" | grep "Metal" | head -1 | awk -F': ' '{print $2}' | xargs 2>/dev/null)
    if [[ -n "$metal_support" ]]; then
        check_info "Metal: $metal_support"
    fi
}

# =============================================================================
# PHASE 8: COMPONENT AUTHENTICITY
# =============================================================================

check_component_authenticity() {
    print_section "PHASE 8: COMPONENT AUTHENTICITY"

    # =============================================================================
    # [ENHANCEMENT] Form-factor aware component testing
    # Problem:  Original code tested for built-in display, camera, speakers on
    #           ALL Macs including Mac mini, Mac Studio, Mac Pro which don't have
    #           these components. This was confusing and unprofessional.
    # Solution: Conditionally test only components that exist on this device type.
    #           For desktop Macs, provide guidance for external peripherals instead.
    # =============================================================================

    # =========================================================================
    # CAMERA
    # =========================================================================
    print_subsection "Camera"

    if [[ "$HAS_BUILTIN_CAMERA" == true ]]; then
        local camera_info="$CAMERA_DATA_CACHE"

        if [[ -z "$camera_info" ]] || ! echo "$camera_info" | grep -qi "facetime\|built-in"; then
            check_fail "No built-in camera detected"
            add_manual_check "Verify camera hardware is present and functional"
        else
            local camera_mfg
            camera_mfg=$(echo "$camera_info" | grep -i "Manufacturer" | head -1 | awk -F': ' '{print $2}' | xargs 2>/dev/null)

            if [[ "$camera_mfg" == "Apple Inc." ]]; then
                check_pass "Camera: Genuine Apple FaceTime camera"
            elif [[ -n "$camera_mfg" ]]; then
                check_fail "Camera: Non-genuine ($camera_mfg)"
            else
                check_info "Camera: Present (manufacturer not reported)"
            fi
        fi
        add_manual_check "Test camera: FaceTime or Photo Booth"
    else
        check_info "No built-in camera (${DEVICE_TYPE} Mac)"
        add_manual_check "Test external webcam if needed for video calls"
    fi

    # =========================================================================
    # AUDIO (Speakers & Microphone)
    # =========================================================================
    print_subsection "Audio"
    local audio_info="$AUDIO_DATA_CACHE"

    if [[ "$HAS_BUILTIN_SPEAKERS" == true ]]; then
        # Check speaker authenticity
        if echo "$audio_info" | grep -q "Built-in"; then
            local audio_mfg
            audio_mfg=$(echo "$audio_info" | grep -A10 "Built-in" | grep -i "Manufacturer" | head -1 | awk -F': ' '{print $2}' | xargs 2>/dev/null)

            if [[ "$audio_mfg" == "Apple Inc." ]]; then
                check_pass "Speakers: Genuine Apple"
            elif [[ -n "$audio_mfg" ]]; then
                check_warn "Speakers: Non-genuine ($audio_mfg)"
            else
                check_pass "Speakers: Built-in detected"
            fi
        else
            check_warn "Built-in speakers not clearly identified"
        fi

        # Active audio test for devices with speakers
        echo ""
        echo -e "    ${CYAN}▶ Playing test sound... Listen for audio from ALL speakers.${NC}"

        local sound_played=false
        local test_sounds=(
            "/System/Library/Sounds/Glass.aiff"
            "/System/Library/Sounds/Ping.aiff"
            "/System/Library/Sounds/Pop.aiff"
            "/System/Library/Sounds/Basso.aiff"
        )

        for sound in "${test_sounds[@]}"; do
            if [[ -f "$sound" ]]; then
                afplay "$sound" 2>/dev/null &
                local sound_pid=$!
                sleep 1.5
                kill $sound_pid 2>/dev/null || true
                sound_played=true
                break
            fi
        done

        if [[ "$sound_played" == false ]]; then
            say -v "Samantha" "Audio test. Left speaker. Right speaker." 2>/dev/null &
            local say_pid=$!
            sleep 3
            kill $say_pid 2>/dev/null || true
        fi

        # Flush input buffer before prompt
        while read -r -t 0.1 -n 1000 discard 2>/dev/null; do :; done

        echo -e "    ${YELLOW}?${NC} Did you hear the sound clearly from all speakers? [y/n] "
        read -r -n 1 audio_response
        echo ""

        case "$audio_response" in
            y|Y)
                check_pass "Audio test: User confirmed sound output"
                ;;
            n|N)
                check_fail "Audio test: User reports audio problem!"
                add_manual_check "CRITICAL: Investigate speaker/audio hardware issue"
                ;;
            *)
                check_info "Audio test: Response unclear"
                add_manual_check "Re-test speakers: Play music, verify all speakers work"
                ;;
        esac
    # =========================================================================
    # [ENHANCEMENT] Correct Messaging for Macs Without Speakers
    # Problem:  The else-block here now only triggers for Mac Pro (the only
    #           modern Mac without built-in speakers). Previous code lumped
    #           all desktops together incorrectly. With the speaker flags
    #           now correct, this block should only show for Mac Pro.
    # Solution: More specific messaging for Mac Pro, the only speaker-less Mac.
    # =========================================================================
    else
        # This branch now only applies to Mac Pro (no built-in speaker)
        check_info "No built-in speakers (Mac Pro requires external audio)"
        check_info "Audio output: Available via headphone jack or connected display"
        add_manual_check "Test audio: Connect headphones, speakers, or use display audio"
    fi

    # Microphone check
    if [[ "$HAS_BUILTIN_MIC" == true ]]; then
        check_info "Built-in microphone: Present"
        add_manual_check "Test microphone: Voice Memos or video call"
    else
        check_info "No built-in microphone (${DEVICE_TYPE})"
        add_manual_check "Test external microphone if needed"
    fi

    # =========================================================================
    # DISPLAY
    # =========================================================================
    print_subsection "Display"

    if [[ "$HAS_BUILTIN_DISPLAY" == true ]]; then
        local display_info="$GPU_DATA_CACHE"
        if [[ -z "$display_info" ]] || ! echo "$display_info" | grep -qi "Resolution"; then
            display_info=$(system_profiler SPDisplaysDataType 2>/dev/null)
        fi

        local resolution
        resolution=$(echo "$display_info" | grep "Resolution" | head -1 | sed 's/.*: *//')
        if [[ -n "$resolution" ]]; then
            check_info "Resolution: $resolution"
        fi

        if echo "$display_info" | grep -qi "retina"; then
            check_pass "Retina Display: Yes"
        fi

        # Active display test
        echo ""
        echo -e "    ${CYAN}▶ Launching display test...${NC}"
        echo -e "    ${GREY}  A browser window will open with fullscreen color test.${NC}"
        echo -e "    ${GREY}  Press SPACE to cycle colors. Press ESC or Q to exit.${NC}"
        echo -e "    ${GREY}  Look for: dead pixels, stuck pixels, uneven backlight.${NC}"
        echo ""

        local display_test_file="/tmp/.mac_audit_display_test_$$.html"

        cat > "$display_test_file" << 'DISPLAYTEST_EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Mac Audit - Display Test</title>
    <style>
        * { margin: 0; padding: 0; cursor: none; }
        body { overflow: hidden; }
        #screen {
            width: 100vw;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            transition: background-color 0.3s;
        }
        #info {
            position: fixed;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            padding: 15px 30px;
            background: rgba(0,0,0,0.7);
            color: white;
            border-radius: 10px;
            font-size: 18px;
            opacity: 1;
            transition: opacity 0.5s;
        }
        #info.hidden { opacity: 0; }
    </style>
</head>
<body>
    <div id="screen">
        <div id="info">SPACE = Next Color | ESC/Q = Exit | Look for dead pixels!</div>
    </div>
    <script>
        const colors = [
            {bg: '#FF0000', name: 'RED - Check for stuck pixels'},
            {bg: '#00FF00', name: 'GREEN - Check for dead pixels'},
            {bg: '#0000FF', name: 'BLUE - Check for color uniformity'},
            {bg: '#FFFFFF', name: 'WHITE - Check for backlight bleed'},
            {bg: '#000000', name: 'BLACK - Check for dead pixels & burn-in'},
            {bg: '#808080', name: 'GRAY - Check for uniformity'}
        ];
        let index = 0;
        const screen = document.getElementById('screen');
        const info = document.getElementById('info');

        function showColor() {
            screen.style.backgroundColor = colors[index].bg;
            info.textContent = `[${index+1}/${colors.length}] ${colors[index].name} | SPACE=Next ESC=Exit`;
            info.style.color = (colors[index].bg === '#FFFFFF' || colors[index].bg === '#00FF00') ? '#000' : '#FFF';
            info.style.background = (colors[index].bg === '#000000') ? 'rgba(255,255,255,0.3)' : 'rgba(0,0,0,0.7)';
            info.classList.remove('hidden');
            setTimeout(() => info.classList.add('hidden'), 3000);
        }

        function next() {
            index = (index + 1) % colors.length;
            showColor();
        }

        document.addEventListener('keydown', (e) => {
            if (e.code === 'Space') { e.preventDefault(); next(); }
            else if (e.code === 'Escape' || e.key === 'q' || e.key === 'Q') { window.close(); }
            else { info.classList.remove('hidden'); }
        });

        document.addEventListener('click', next);

        document.body.addEventListener('click', () => {
            if (document.documentElement.requestFullscreen) {
                document.documentElement.requestFullscreen();
            } else if (document.documentElement.webkitRequestFullscreen) {
                document.documentElement.webkitRequestFullscreen();
            }
        }, {once: true});

        showColor();
        info.textContent += ' | Click to go fullscreen';
    </script>
</body>
</html>
DISPLAYTEST_EOF

        open "$display_test_file" 2>/dev/null

        echo -e "    ${YELLOW}?${NC} Press [ENTER] when done with display test..."
        read -r

        rm -f "$display_test_file" 2>/dev/null

        # Flush input buffer before prompt
        while read -r -t 0.1 -n 1000 discard 2>/dev/null; do :; done

        echo -e "    ${YELLOW}?${NC} Were there any display issues (dead pixels, bleed, burn-in)? [y/n] "
        read -r -n 1 display_response
        echo ""

        case "$display_response" in
            y|Y)
                check_fail "Display test: User reports display issues!"
                add_manual_check "CRITICAL: Document display defects, negotiate price"
                ;;
            n|N)
                check_pass "Display test: User confirms no visible defects"
                ;;
            *)
                check_info "Display test: Response unclear"
                add_manual_check "Re-check display for dead pixels and backlight bleed"
                ;;
        esac

        add_manual_check "Test True Tone if supported (Settings > Displays)"

    else
        check_info "No built-in display (${DEVICE_TYPE} Mac)"
        add_manual_check "Test ALL video outputs with external display(s)"
        add_manual_check "Verify expected resolution and refresh rate on external display"

        # Check video output capabilities
        local video_outputs
        video_outputs=$(echo "$GPU_DATA_CACHE" | grep -i "Thunderbolt\|HDMI\|DisplayPort" | head -3)
        if [[ -n "$video_outputs" ]]; then
            check_info "Video output: Via Thunderbolt/USB-C ports"
        fi
    fi

    # =========================================================================
    # KEYBOARD & TRACKPAD (Laptops only)
    # =========================================================================
    if [[ "$HAS_BUILTIN_KEYBOARD" == true ]]; then
        print_subsection "Keyboard & Trackpad"

        local kb_type="Unknown"
        case "$SYSTEM_MODEL_ID" in
            MacBook8,1|MacBook9,1|MacBook10,1|\
            MacBookAir8,1|MacBookAir8,2|\
            MacBookPro13,1|MacBookPro13,2|MacBookPro13,3|\
            MacBookPro14,1|MacBookPro14,2|MacBookPro14,3|\
            MacBookPro15,1|MacBookPro15,2|MacBookPro15,3|MacBookPro15,4|\
            MacBookPro16,1|MacBookPro16,2|MacBookPro16,3|MacBookPro16,4)
                kb_type="Butterfly"
                ;;
            MacBookAir9,1|MacBookAir10,1|\
            MacBookPro17,1|MacBookPro18,*)
                kb_type="Magic Keyboard (Scissor)"
                ;;
            Mac14,*|Mac15,*|Mac16,*)
                kb_type="Magic Keyboard (Scissor)"
                ;;
            *)
                if [[ "$IS_APPLE_SILICON" == true ]]; then
                    kb_type="Magic Keyboard (Scissor)"
                else
                    kb_type="Standard"
                fi
                ;;
        esac

        check_info "Keyboard type: $kb_type"
        check_info "Trackpad: Force Touch (pressure-sensitive)"

        add_manual_check "Test EVERY key using Keyboard Viewer or typing test"
        add_manual_check "Test trackpad: All corners, Force Touch click, gestures"

        # Butterfly keyboard warning
        case "$SYSTEM_MODEL_ID" in
            MacBook8,1|MacBook9,1|MacBook10,1|\
            MacBookAir8,1|MacBookAir8,2|\
            MacBookPro13,1|MacBookPro13,2|MacBookPro14,1|MacBookPro14,2|\
            MacBookPro15,2|MacBookPro15,4|\
            MacBookPro13,3|MacBookPro14,3|MacBookPro15,1|MacBookPro15,3)
                check_warn "Butterfly keyboard - prone to sticky/repeating keys"
                add_manual_check "Type extensively: Check for sticky, repeating, or dead keys"
                ;;
        esac
    else
        print_subsection "Input Devices"
        check_info "No built-in keyboard/trackpad (${DEVICE_TYPE} Mac)"
        add_manual_check "Test with YOUR keyboard and mouse before purchase"

        # Check for Touch ID on external Magic Keyboard
        if [[ "$HAS_TOUCH_ID" == true ]]; then
            check_info "Note: Touch ID only works with Apple's Magic Keyboard with Touch ID"
        fi
    fi

    # =========================================================================
    # TOUCH BAR (specific MacBook Pro models only)
    # =========================================================================
    if [[ "$HAS_TOUCH_BAR" == true ]]; then
        print_subsection "Touch Bar"
        check_info "Touch Bar present on this model"
        add_manual_check "Test Touch Bar: Brightness, volume, app-specific controls"
        add_manual_check "Check for dead spots or unresponsive areas on Touch Bar"
    fi
}

# =============================================================================
# PHASE 9: SECURITY POSTURE
# =============================================================================

check_security_posture() {
    print_section "PHASE 9: SECURITY POSTURE"

    # SIP
    print_subsection "System Integrity Protection (SIP)"
    local sip_status
    sip_status=$(csrutil status 2>/dev/null)

    if echo "$sip_status" | grep -q "enabled"; then
        check_pass "SIP: Enabled (system protected)"
    elif echo "$sip_status" | grep -q "disabled"; then
        check_fail "SIP: DISABLED - System may be tampered!"
        echo -e "    ${RED}     Disabled SIP could indicate jailbreak, malware, or mods.${NC}"
    else
        check_warn "SIP: Status unclear"
    fi

    # FileVault
    print_subsection "FileVault (Disk Encryption)"
    local fv_status
    fv_status=$(fdesetup status 2>/dev/null)

    # =============================================================================
    # [BUGFIX] Complete FileVault check with proper else clause
    # Problem:  Previous edit replaced only the if-block but left orphaned code
    #           or missing else clause, causing formatting issues (extra newlines)
    #           and potentially missing the "disabled" status message.
    # Solution: Complete if/else/fi structure with both enabled and disabled cases.
    # =============================================================================
    if echo "$fv_status" | grep -q "FileVault is On"; then
        check_warn "FileVault: ENABLED (disk is encrypted)"
        echo -e "    ${YELLOW}┌────────────────────────────────────────────────────────┐${NC}"
        echo -e "    ${YELLOW}│  IMPORTANT: Get FileVault recovery key before buying!  │${NC}"
        echo -e "    ${YELLOW}│  Without it, you cannot access data after login reset. │${NC}"
        echo -e "    ${YELLOW}│  Seller should: Settings > Apple ID > iCloud > Keys    │${NC}"
        echo -e "    ${YELLOW}└────────────────────────────────────────────────────────┘${NC}"
        add_manual_check "CRITICAL: Obtain FileVault recovery key from seller"
    else
        check_info "FileVault: Disabled (normal for used Mac)"
    fi

    # Gatekeeper
    print_subsection "Gatekeeper (App Security)"
    local gk_status
    gk_status=$(spctl --status 2>/dev/null)

    if echo "$gk_status" | grep -q "assessments enabled"; then
        check_pass "Gatekeeper: Enabled"
    else
        check_warn "Gatekeeper: Disabled"
    fi

    # Firewall
    print_subsection "Application Firewall"
    local fw_status
    fw_status=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)

    if echo "$fw_status" | grep -qi "enabled"; then
        check_pass "Firewall: Enabled"
    else
        check_info "Firewall: Disabled (common default)"
    fi

    # Firmware Security
    print_subsection "Firmware Security"

    if [[ "$IS_APPLE_SILICON" == true ]]; then
        check_pass "Secure Enclave: Active (Apple Silicon)"
        check_info "Secure Boot: Always enabled on Apple Silicon"
    else
        # Intel - check for T2
        local t2_check
        t2_check=$(system_profiler SPiBridgeDataType 2>/dev/null | grep -i "Model Name")

        if echo "$t2_check" | grep -qi "T2"; then
            check_pass "T2 Security Chip: Present"
            # =========================================================================
            # [CLEANUP] Removed redundant Recovery Mode check
            # Problem:  Recovery Mode test was being added here AND in
            #           check_recovery_readiness(), causing duplicate checklist entry.
            # Solution: Only add the firmware password check here. Recovery Mode
            #           instruction is handled exclusively by check_recovery_readiness().
            # =========================================================================
            add_manual_check "Verify no firmware password blocks boot options (hold Option on boot)"
        else
            check_info "T2 Chip: Not present (older Intel Mac)"
        fi
    fi

    # =========================================================================
    # [NEW CHECK] Secure Boot Policy (Apple Silicon)
    # Problem:  Apple Silicon Macs can have reduced security boot policies that
    #           allow unsigned kernels, disable SIP features, or enable kernel
    #           debugging. Sellers may not disclose modified security settings.
    #           A Mac in "Permissive Security" mode could have been jailbroken.
    # Solution: Check bputil output for security policy. Full Security is the
    #           default and safest. Any other mode warrants investigation.
    # =========================================================================
    if [[ "$IS_APPLE_SILICON" == true ]]; then
        print_subsection "Secure Boot Policy (Apple Silicon)"
        local security_policy
        # bputil requires no privileges to check current policy
        security_policy=$(bputil -d 2>/dev/null | grep -i "security mode" | head -1)

        if [[ -z "$security_policy" ]]; then
            # Alternative: check via nvram
            local boot_mode
            boot_mode=$(nvram -p 2>/dev/null | grep -i "boot-policy" || true)

            if [[ -z "$boot_mode" ]] || echo "$boot_mode" | grep -qi "full"; then
                check_pass "Secure Boot: Full Security (default)"
            else
                check_warn "Secure Boot: Non-standard policy detected"
            fi
        elif echo "$security_policy" | grep -qi "full"; then
            check_pass "Secure Boot: Full Security (default)"
        elif echo "$security_policy" | grep -qi "reduced"; then
            check_warn "Secure Boot: Reduced Security"
            echo -e "    ${YELLOW}     Allows third-party kernel extensions. Ask why.${NC}"
        elif echo "$security_policy" | grep -qi "permissive"; then
            check_fail "Secure Boot: Permissive Security (lowest)"
            echo -e "    ${RED}     Allows unsigned code. May indicate jailbreak!${NC}"
        else
            check_info "Secure Boot: $security_policy"
        fi
    fi

    # =============================================================================
    # [NEW CHECK] Firmware Password Detection (Intel Macs)
    # Problem:  Intel Macs can have firmware passwords that prevent booting from
    #           external media, Recovery Mode access, and NVRAM resets. A locked
    #           Mac is severely limited for the new owner. Sellers may not
    #           disclose this. Cannot be removed without proof of purchase at
    #           Apple Store.
    # Solution: Check NVRAM for firmware password indicators. Note: Full detection
    #           requires attempting Recovery boot, but NVRAM hints are useful.
    # =============================================================================
    if [[ "$IS_APPLE_SILICON" == false ]]; then
        print_subsection "Firmware Password (Intel)"
        local fw_mode
        fw_mode=$(nvram -p 2>/dev/null | grep -i "security-mode" | awk -F$'\t' '{print $2}')

        case "$fw_mode" in
            "full"|"command")
                check_fail "Firmware Password: ENABLED ($fw_mode mode)"
                echo -e "    ${RED}     Cannot boot external media or access Recovery freely.${NC}"
                echo -e "    ${RED}     Seller MUST remove this before purchase!${NC}"
                ;;
            "none"|"")
                check_pass "Firmware Password: Not set"
                ;;
            *)
                check_warn "Firmware Password: Unknown status ($fw_mode)"
                add_manual_check "Verify firmware password: Restart with Option key held"
                ;;
        esac
    fi

    # =========================================================================
    # [NEW CHECK] Boot ROM Version (Intel Macs)
    # Problem:  Outdated Boot ROM/EFI firmware may have security vulnerabilities
    #           (Thunderstrike, etc.). Also indicates if Mac received updates.
    # Solution: Display Boot ROM version for verification. Outdated versions
    #           on supported Macs may indicate update issues.
    # =========================================================================
    if [[ "$IS_APPLE_SILICON" == false ]]; then
        # =========================================================================
        # [BUGFIX] Boot ROM parsing with proper handling of complex version strings
        # Problem:  Boot ROM version strings often contain nested colons, e.g.:
        #           "Boot ROM Version: 2094.40.1.0.0 (iBridge: 22.16.12077.0.0,0)"
        #           Using awk -F': ' split on ALL colons, truncating the output
        #           to just "2094.40.1.0.0 (iBridge" - losing important info.
        # Solution: Use sed to remove only the first occurrence of ": " (label),
        #           preserving the entire version string including parenthetical.
        #           Also clean up trailing whitespace/control characters.
        # =========================================================================
        print_subsection "Boot ROM / EFI Firmware"
        local boot_rom_line boot_rom

        # Get the full line first
        boot_rom_line=$(echo "$HW_DATA_CACHE" | grep -iE "Boot ROM|System Firmware" | head -1)

        if [[ -n "$boot_rom_line" ]]; then
            # Remove only the label (everything up to first ": "), keep the rest
            boot_rom=$(echo "$boot_rom_line" | sed 's/^[^:]*: *//' | xargs 2>/dev/null)
        fi

        # Fallback: fresh query if cache parsing failed
        if [[ -z "$boot_rom" ]]; then
            boot_rom_line=$(system_profiler SPHardwareDataType 2>/dev/null | grep -iE "Boot ROM|System Firmware" | head -1)
            boot_rom=$(echo "$boot_rom_line" | sed 's/^[^:]*: *//' | xargs 2>/dev/null)
        fi

        if [[ -n "$boot_rom" ]]; then
            # Truncate if excessively long (some versions have very long strings)
            if [[ ${#boot_rom} -gt 60 ]]; then
                boot_rom="${boot_rom:0:57}..."
            fi
            check_info "Boot ROM: $boot_rom"
        else
            check_info "Boot ROM: Could not be determined"
            verbose_info "This may be normal on some Mac configurations"
        fi
    fi

    # Tampering indicators
    # =============================================================================
    # [NEW CHECK] XProtect Security Definitions
    # Problem:  Veraltete Sicherheitsdefinitionen bedeuten, dass bekannte Malware
    #           nicht erkannt wird. Zeigt auch ob der Mac regelmäßig Updates bekam.
    # Solution: XProtect-Version und Datum prüfen, warnen wenn sehr alt.
    # =============================================================================
    print_subsection "Malware Definitions (XProtect)"
    # =========================================================================
    # [BUGFIX] XProtect path changed in macOS 12+ and again in macOS 15
    # Problem:  XProtect bundle location varies across macOS versions.
    #           Original hardcoded path failed on newer systems.
    # Solution: Check multiple known paths, use first that exists.
    # =========================================================================
    local xprotect_plist=""
    local xprotect_paths=(
        "/System/Library/CoreServices/XProtect.bundle/Contents/Resources/XProtect.meta.plist"
        "/Library/Apple/System/Library/CoreServices/XProtect.bundle/Contents/Resources/XProtect.meta.plist"
        "/System/Library/CoreServices/XProtect.app/Contents/Resources/XProtect.meta.plist"
    )

    for path in "${xprotect_paths[@]}"; do
        if [[ -f "$path" ]]; then
            xprotect_plist="$path"
            break
        fi
    done

    if [[ -n "$xprotect_plist" ]]; then
        local xp_version
        xp_version=$(/usr/libexec/PlistBuddy -c "Print :Version" "$xprotect_plist" 2>/dev/null)
        if [[ -n "$xp_version" ]]; then
            check_pass "XProtect Version: $xp_version"
        else
            check_info "XProtect: Installed (version not readable)"
        fi
    else
        check_warn "XProtect: Not found or not accessible"
    fi

    print_subsection "Tampering Indicators"
    local suspicious_paths=(
        "/usr/lib/libhook.dylib"
        "/usr/lib/substrate.dylib"
        "/Library/MobileSubstrate"
        "/private/var/lib/cydia"
        "/usr/sbin/frida-server"
        "/usr/local/bin/cycript"
        "/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist"
    )

    local suspicious_found=false
    for path in "${suspicious_paths[@]}"; do
        if [[ -e "$path" ]]; then
            check_fail "Suspicious file: $path"
            suspicious_found=true
        fi
    done

    if [[ "$suspicious_found" == false ]]; then
        check_pass "No common tampering indicators found"
    fi
}

# =============================================================================
# PHASE 10: PORTS & CONNECTIVITY
# =============================================================================

check_ports_connectivity() {
    print_section "PHASE 10: PORTS & CONNECTIVITY"

    # USB/Thunderbolt
    print_subsection "USB & Thunderbolt"
    # [OPTIMIZATION] Use cached USB/Thunderbolt data
    local usb_info="$USB_DATA_CACHE"
    local tb_info="$TB_DATA_CACHE"

    # [BUGFIX] grep -c with || echo "0" causes "0\n0" on no matches
    # =========================================================================
    # [BUGFIX] Robust USB controller counting
    # Problem:  grep -c returns exit code 1 when no matches found, but command
    #           substitution captures stdout (the count "0"), not exit code.
    #           The || true was unnecessary and the ${:-0} fallback never
    #           triggered because grep -c always outputs a number.
    # Solution: Simplified logic, added validation for integer.
    # =========================================================================
    local usb_controllers
    usb_controllers=$(echo "$usb_info" | grep -c "Host Controller" 2>/dev/null || echo "0")
    usb_controllers=$(safe_int "$usb_controllers" 0)

    # =========================================================================
    # [ENHANCEMENT] Detailed port count display

    # =========================================================================
    # [ENHANCEMENT] Detailed port count display
    # Problem:  Showing only controller count was not meaningful for buyers.
    #           The number of Thunderbolt/USB-C ports is purchase-relevant
    #           since defective ports are a common issue on used MacBooks.
    # Solution: Show both controller count and detected port count.
    # =========================================================================
    if [[ "$usb_controllers" -gt 0 ]]; then
        check_pass "USB controllers: $usb_controllers"
    fi

    # [BUGFIX] grep -c with || echo "0" causes "0\n0" on no matches
    local tb_ports
    tb_ports=$(echo "$tb_info" | grep -c "Port:" 2>/dev/null) || true
    tb_ports=${tb_ports:-0}
    # =============================================================================
    # [ENHANCEMENT] Model-specific USB-C port count validation
    # Problem:  Previous check only flagged "fewer than 2 ports on MacBook Pro"
    #           which was too generic. Different models have different expected
    #           port counts. A 14" M3 Pro should have 3, Mac Studio has 6, etc.
    # Solution: Map model identifiers to expected port counts. Flag if actual
    #           count differs from expected (may indicate hardware damage).
    # =============================================================================
    if [[ "$tb_ports" -gt 0 ]]; then
        check_info "Thunderbolt/USB-C ports detected: $tb_ports"

        # =====================================================================
        # [BUGFIX] Port Count Expectations - Updated Model Mapping
        # Problem:  Previous mapping was outdated and incorrect:
        #           - MacBookPro14,* are 2017 models (4 ports), not 14"/16"
        #           - Missing M2/M3/M4 MacBook Pro models
        #           - Missing newer Mac mini and Mac Studio models
        #           - MacBook Pro 14" M3 base has 2 ports, Pro/Max have 3
        # Solution: Comprehensive and accurate port count mapping based on
        #           Apple's current specifications for all modern Macs.
        # =====================================================================
        local expected_ports=0
        case "$SYSTEM_MODEL_ID" in
            # === MacBook Air ===
            # M1 MacBook Air (2020)
            MacBookAir10,1) expected_ports=2 ;;
            # M2 MacBook Air (2022)
            Mac14,2) expected_ports=2 ;;
            # M3 MacBook Air (2024)
            Mac15,12|Mac15,13) expected_ports=2 ;;

            # === MacBook Pro 13"/14" with 2 ports ===
            # M1 MacBook Pro 13" (2020)
            MacBookPro17,1) expected_ports=2 ;;
            # M2 MacBook Pro 13" (2022)
            Mac14,7) expected_ports=2 ;;
            # M3 MacBook Pro 14" BASE model (2023) - only 2 ports!
            Mac15,3) expected_ports=2 ;;
            # M4 MacBook Pro 14" BASE model (2024) - only 2 ports!
            Mac16,1) expected_ports=2 ;;
            # Intel 13" 2-port models
            MacBookPro15,4|MacBookPro15,2|MacBookPro14,1) expected_ports=2 ;;

            # === MacBook Pro 14"/16" with 3 ports ===
            # M1 Pro/Max (2021)
            MacBookPro18,1|MacBookPro18,2|MacBookPro18,3|MacBookPro18,4) expected_ports=3 ;;
            # M2 Pro/Max (2023)
            Mac14,5|Mac14,6|Mac14,9|Mac14,10) expected_ports=3 ;;
            # M3 Pro/Max (2023)
            Mac15,6|Mac15,7|Mac15,8|Mac15,9|Mac15,10|Mac15,11) expected_ports=3 ;;
            # M4 Pro/Max (2024)
            Mac16,5|Mac16,6|Mac16,7|Mac16,8) expected_ports=3 ;;

            # === MacBook Pro Intel 4-port models ===
            # 15" and 16" Intel (2016-2020)
            MacBookPro15,1|MacBookPro15,3|MacBookPro16,1|MacBookPro16,4|\
            MacBookPro14,3|MacBookPro13,3) expected_ports=4 ;;

            # === Mac mini ===
            # M1 Mac mini (2020) - 2 TB ports
            Macmini9,1) expected_ports=2 ;;
            # M2 Mac mini (2023) - 2 TB ports
            Mac14,3) expected_ports=2 ;;
            # M2 Pro Mac mini (2023) - 4 TB ports
            Mac14,12) expected_ports=4 ;;
            # M4 Mac mini (2024) - 3 TB/USB4 ports (front+back)
            Mac16,10) expected_ports=3 ;;
            # M4 Pro Mac mini (2024) - 5 TB/USB4 ports (3 back + 2 front)
            Mac16,11) expected_ports=5 ;;
            # Intel Mac mini - 4 TB3 ports
            Macmini8,1) expected_ports=4 ;;

            # === Mac Studio ===
            # M1 Max/Ultra, M2 Max/Ultra - 6 ports (4 back + 2 front)
            Mac13,1|Mac13,2|Mac14,13|Mac14,14) expected_ports=6 ;;

            # === Mac Pro ===
            # 2019 Intel Mac Pro - 8 TB3 ports (internal + external)
            MacPro7,1) expected_ports=8 ;;
            # M2 Ultra Mac Pro (2023) - 8 TB4 ports
            Mac14,8) expected_ports=8 ;;
        esac

        if [[ $expected_ports -gt 0 ]]; then
            if [[ $tb_ports -lt $expected_ports ]]; then
                check_warn "Expected $expected_ports ports for this model, found $tb_ports"
                echo -e "    ${YELLOW}     Some ports may be damaged or detection failed.${NC}"
            elif [[ $tb_ports -eq $expected_ports ]]; then
                check_pass "Port count matches expected for this model"
            fi
        fi
    fi

    if echo "$tb_info" | grep -qi "Thunderbolt"; then
        local tb_version
        tb_version=$(echo "$tb_info" | grep -i "Version" | head -1 | awk -F': ' '{print $2}' | xargs 2>/dev/null)
        check_pass "Thunderbolt: Available ${tb_version:+(v$tb_version)}"
    fi

    add_manual_check "Test ALL USB-C/Thunderbolt ports with a device"
    add_manual_check "Test charging from each USB-C port"

    # Bluetooth
    print_subsection "Bluetooth"
    # [OPTIMIZATION] Use cached Bluetooth data
    local bt_info="$BT_DATA_CACHE"

    if echo "$bt_info" | grep -qi "Bluetooth"; then
        check_pass "Bluetooth: Available"
        add_manual_check "Test Bluetooth: Pair a device"
    else
        check_warn "Bluetooth: Not detected"
    fi

    # WiFi
    print_subsection "WiFi"
    # [OPTIMIZATION] Use cached WiFi data
    local wifi_info="$WIFI_DATA_CACHE"

    if echo "$wifi_info" | grep -qi "Wi-Fi\|AirPort"; then
        check_pass "WiFi: Available"

        local wifi_modes
        wifi_modes=$(echo "$wifi_info" | grep "Supported PHY Modes" | head -1 | awk -F': ' '{print $2}' | xargs 2>/dev/null)
        if [[ -n "$wifi_modes" ]]; then
            check_info "Standards: $wifi_modes"
        fi
    else
        check_warn "WiFi: Not detected"
    fi

    # =========================================================================
    # [BUGFIX] Robust WiFi interface detection
    # Problem:  Previous awk command assumed Device line immediately follows
    #           Hardware Port line. This failed when output had extra fields
    #           or different formatting across macOS versions. Also failed to
    #           handle "Wi-Fi" vs "AirPort" naming variations correctly.
    # Solution: Use grep -A1 to get Device line, then extract interface name.
    #           Handle both old "AirPort" and new "Wi-Fi" naming.
    # =========================================================================
    local wifi_interface current_ssid
    wifi_interface=$(networksetup -listallhardwareports 2>/dev/null | \
        grep -A1 -E "Hardware Port: (Wi-Fi|AirPort)" | \
        grep "Device:" | awk '{print $2}' | head -1)

    if [[ -n "$wifi_interface" ]]; then
        # Get current network, handle both connected and disconnected states
        local airport_output
        airport_output=$(networksetup -getairportnetwork "$wifi_interface" 2>/dev/null)

        # =====================================================================
        # [ENHANCEMENT] WiFi status with actionable guidance
        # Problem:  "WiFi not connected" was just informational, but in a
        #           purchase scenario you WANT to verify WiFi works. Simply
        #           noting it's disconnected doesn't prompt action.
        # Solution: If disconnected, add explicit manual check instruction.
        #           If connected, show it as a pass (verified working).
        # =====================================================================
        if echo "$airport_output" | grep -q "Current Wi-Fi Network:"; then
            current_ssid=$(echo "$airport_output" | sed 's/Current Wi-Fi Network: //')
            check_pass "Connected to: $current_ssid (WiFi verified working)"
        elif echo "$airport_output" | grep -qi "not associated\|off\|disabled"; then
            check_info "WiFi: Not currently connected"
            add_manual_check "IMPORTANT: Connect to WiFi and verify it works before purchase"
        fi
    fi

    # WiFi manual check - only add if not already covered by "not connected" check
    # The add_manual_check function deduplicates, but these are different strings
    # So we need conditional logic here
    if [[ -n "$current_ssid" ]]; then
        # WiFi is connected, just needs speed verification
        add_manual_check "Test WiFi speed: Run a speed test to verify full functionality"
    fi
    # Note: If WiFi is NOT connected, the specific "IMPORTANT: Connect to WiFi..."
    # check is added in the WiFi status block, which is more actionable

    # =========================================================================
    # [NEW CHECK] Ethernet Port Detection
    # Problem:  Desktop Macs (Mac mini, Studio, Pro, iMac) have Ethernet ports
    #           that can fail. Buyers should test wired networking. MacBook Pro
    #           16" also sometimes used with Ethernet adapters.
    # Solution: Check for Ethernet hardware and current connection status.
    # =========================================================================
    print_subsection "Ethernet"
    local eth_interface
    eth_interface=$(networksetup -listallhardwareports 2>/dev/null | \
        grep -A1 "Hardware Port: Ethernet" | grep "Device:" | awk '{print $2}' | head -1)

    if [[ -n "$eth_interface" ]]; then
        check_pass "Ethernet port: Present ($eth_interface)"
        local eth_status
        eth_status=$(ifconfig "$eth_interface" 2>/dev/null | grep "status:" | awk '{print $2}')
        if [[ "$eth_status" == "active" ]]; then
            check_info "Ethernet status: Connected"
        else
            check_info "Ethernet status: Not connected (normal if using WiFi)"
        fi
        add_manual_check "Test Ethernet: Connect cable, verify network access"
    else
        # Check if this model should have Ethernet
        case "$SYSTEM_MODEL" in
            *"Mac mini"*|*"Mac Studio"*|*"Mac Pro"*|*"iMac"*)
                check_warn "Ethernet port not detected (expected on this model)"
                add_manual_check "Verify Ethernet port functionality with cable"
                ;;
            *)
                check_info "No built-in Ethernet (normal for MacBooks)"
                ;;
        esac
    fi

    # =========================================================================
    # [ENHANCEMENT] Model-specific port manual checks
    # Problem:  Generic "if present" checks cluttered the checklist with
    #           irrelevant items. MacBook Air has no SD slot, Mac mini has
    #           no headphone jack on some models, etc. Users wasted time
    #           looking for ports that don't exist.
    # Solution: Check model identifier and only add relevant port tests.
    #           Based on Apple's technical specifications per model.
    # =========================================================================

    # Headphone jack - present on most Macs except some Mac mini configs
    case "$SYSTEM_MODEL_ID" in
        Macmini9,1)
            # M1 Mac mini has headphone jack
            add_manual_check "Test headphone jack (front of device)"
            ;;
        Macmini*)
            # Older Mac minis - check if jack exists
            add_manual_check "Test headphone jack if present"
            ;;
        MacBookAir*|MacBookPro*|iMac*|MacPro*)
            add_manual_check "Test headphone jack"
            ;;
    esac

    # =========================================================================
    # [BUGFIX] SD Card Slot Detection - Corrected Model Identifiers
    # Problem:  Previous code listed MacBookPro14,* as having SD slot. These
    #           are actually 2017 MacBook Pro models which have NO SD slot.
    #           The 2021+ MacBook Pro models with SD slots use different IDs:
    #           - MacBookPro18,* = 2021 M1 Pro/Max (14"/16")
    #           - Mac14,5/6/9/10 = 2023 M2 Pro/Max (14"/16")
    #           - Mac15,3/6-11 = 2023 M3 series (14"/16")
    #           - Mac16,1/5-8 = 2024 M4 series (14"/16")
    #           Also: Mac Studio model IDs were incomplete.
    # Solution: Comprehensive list of all models with SD card slots based on
    #           Apple's official specifications.
    # =========================================================================
    # SD card slot - only on specific MacBook Pro models and some iMacs
    case "$SYSTEM_MODEL_ID" in
        # MacBook Pro 14"/16" 2021 (M1 Pro/Max) - have SD slot
        MacBookPro18,*)
            add_manual_check "Test SD card slot (right side)"
            ;;
        # MacBook Pro 14"/16" 2023 (M2 Pro/Max) - have SD slot
        Mac14,5|Mac14,6|Mac14,9|Mac14,10)
            add_manual_check "Test SD card slot (right side)"
            ;;
        # MacBook Pro 14"/16" 2023 (M3/M3 Pro/Max) - have SD slot
        Mac15,3|Mac15,6|Mac15,7|Mac15,8|Mac15,9|Mac15,10|Mac15,11)
            add_manual_check "Test SD card slot (right side)"
            ;;
        # MacBook Pro 14"/16" 2024 (M4/M4 Pro/Max) - have SD slot
        Mac16,1|Mac16,5|Mac16,6|Mac16,7|Mac16,8)
            add_manual_check "Test SD card slot (right side)"
            ;;
        # Older 15" MacBook Pro (2012-2015) had SD slot
        MacBookPro11,4|MacBookPro11,5|MacBookPro11,2|MacBookPro11,3|\
        MacBookPro10,1|MacBookPro10,2|MacBookPro9,1)
            add_manual_check "Test SD card slot"
            ;;
        # iMacs (most models have SD slot, except iMac Pro and 24" M1)
        iMac12,*|iMac13,*|iMac14,*|iMac15,*|iMac16,*|iMac17,*|iMac18,*|iMac19,*|iMac20,*)
            add_manual_check "Test SD card slot (back of display)"
            ;;
        # Mac Studio (all models have front SD slot)
        Mac13,1|Mac13,2|Mac14,13|Mac14,14)
            add_manual_check "Test SD card slot (front of device)"
            ;;
        # Note: MacBook Air, MacBook Pro 13", Mac mini, Mac Pro, 24" iMac - no SD slot
    esac
}

# =============================================================================
# PHASE 11: SYSTEM STABILITY (Kernel Panics)
# =============================================================================
# [HISTORY - NEW IN v10]
# Problem:  Kernel panics indicate hardware instability (bad RAM, GPU issues,
#           failing SSD, logic board problems). Seller may not disclose crash
#           history. Panic logs persist across reboots and reveal problems.
#
# Solution: Check DiagnosticReports for kernel panic logs. Count recent panics,
#           analyze causes if possible. High panic count = avoid purchase.
# =============================================================================

check_system_stability() {
    print_section "PHASE 11: SYSTEM STABILITY"

    print_subsection "Kernel Panic History"

    local panic_dir="/Library/Logs/DiagnosticReports"
    local user_panic_dir="$HOME/Library/Logs/DiagnosticReports"
    local panic_count=0
    local recent_panic_count=0
    # [CLARITY] Renamed from 'recent_panics' - this array holds ALL panic filenames
    local all_panic_files=()
    local now_epoch
    now_epoch=$(date +%s)
    local panic_seconds=$((PANIC_RECENT_DAYS * 86400))
    local threshold_epoch=$((now_epoch - panic_seconds))

    # =============================================================================
    # [OPTIMIZATION] Single-pass panic file analysis
    # Problem:  Previous implementation iterated through panic files twice -
    #           once for total count and once for recent count. Inefficient
    #           on systems with many panic logs.
    # Solution: Count total and recent panics in single loop iteration.
    # =============================================================================
    for dir in "$panic_dir" "$user_panic_dir"; do
        [[ ! -d "$dir" ]] && continue
        while IFS= read -r -d '' panic_file; do
            ((panic_count++))
            all_panic_files+=("$(basename "$panic_file")")
            local file_epoch
            file_epoch=$(stat -f %m "$panic_file" 2>/dev/null || echo 0)
            if [[ $file_epoch -gt $threshold_epoch ]]; then
                ((recent_panic_count++))
            fi
        done < <(find "$dir" -name "*.panic" -type f -print0 2>/dev/null)
    done

    # =========================================================================
    # [ENHANCEMENT] Panic analysis with cause detection
    # Problem:  Simply reporting panic count without context left users
    #           uncertain about severity. A single panic from a known macOS
    #           bug is different from recurring GPU or I/O panics.
    # Solution: Attempt to extract panic type from most recent panic file.
    #           Common causes: GPU/graphics, I/O (disk), memory, kernel ext.
    #           This helps buyer assess if issue is hardware vs software.
    # =========================================================================
    # =============================================================================
    # [ENHANCEMENT] More Nuanced Panic Assessment
    # Problem:  "No panic logs found" could mean (a) genuinely stable system, or
    #           (b) system was freshly wiped to hide problems. Combined with
    #           "recent install date" check, this gives better context.
    # Solution: Cross-reference with macOS install date. Fresh install + no panics
    #           is less reassuring than old install + no panics.
    # =============================================================================
    if [[ $panic_count -eq 0 ]]; then
        # Check if this is a fresh install (where no panics is less meaningful)
        local install_age_days=999
        if [[ -f "/var/db/.AppleSetupDone" ]]; then
            local setup_epoch
            setup_epoch=$(stat -f %m "/var/db/.AppleSetupDone" 2>/dev/null || echo 0)
            if [[ $setup_epoch -gt 0 ]]; then
                install_age_days=$(( ($(date +%s) - setup_epoch) / 86400 ))
            fi
        fi

        if [[ $install_age_days -lt 7 ]]; then
            check_info "No kernel panics (but system freshly installed - limited history)"
        else
            check_pass "No kernel panic logs found (stable system)"
        fi
    else
        # Analyze most recent panic for cause
        local panic_cause="unknown"
        local latest_panic=""

        for dir in "$panic_dir" "$user_panic_dir"; do
            [[ ! -d "$dir" ]] && continue
            local found
            found=$(find "$dir" -name "*.panic" -type f -print 2>/dev/null | head -1)
            if [[ -n "$found" ]]; then
                latest_panic="$found"
                break
            fi
        done

        if [[ -n "$latest_panic" && -r "$latest_panic" ]]; then
            # Extract panic type from file content
            local panic_content
            panic_content=$(head -100 "$latest_panic" 2>/dev/null)

            # =========================================================================
            # [ENHANCEMENT] Context-aware panic cause detection
            # Problem:  Generic "GPU/Graphics related" for integrated GPUs was
            #           misleading. Intel Iris/UHD panics are usually driver bugs
            #           fixed by macOS updates, not hardware failures. Discrete
            #           AMD/NVIDIA GPU panics are more concerning (actual hardware).
            # Solution: Differentiate between integrated and discrete GPU panics.
            #           Also detect specific panic signatures for better accuracy.
            # =========================================================================
            if echo "$panic_content" | grep -qi "AMD\|Radeon"; then
                panic_cause="Discrete GPU (AMD) - potential hardware issue"
            elif echo "$panic_content" | grep -qi "NVIDIA\|GeForce"; then
                panic_cause="Discrete GPU (NVIDIA) - potential hardware issue"
            elif echo "$panic_content" | grep -qi "GPU\|graphics\|Metal\|AGP"; then
                # Check if this Mac has discrete GPU
                if echo "$GPU_DATA_CACHE" | grep -qi "AMD\|Radeon\|NVIDIA"; then
                    panic_cause="GPU/Graphics - may be discrete GPU issue"
                else
                    panic_cause="Graphics driver issue (likely software, not hardware)"
                fi
            elif echo "$panic_content" | grep -qi "AppleANS\|NVMe\|disk\|IOStorage\|APFS"; then
                panic_cause="Storage/Disk I/O - potential SSD issue"
            elif echo "$panic_content" | grep -qi "memory\|zone\|kalloc\|zalloc\|vm_"; then
                panic_cause="Memory related - potential RAM issue"
            elif echo "$panic_content" | grep -qi "USB\|Thunderbolt\|IOUSBHost\|AppleUSB"; then
                panic_cause="USB/Thunderbolt port issue"
            elif echo "$panic_content" | grep -qi "Bluetooth\|BT\|AppleBluetooth"; then
                panic_cause="Bluetooth hardware/driver issue"
            elif echo "$panic_content" | grep -qi "Wi-Fi\|AirPort\|wlan\|IO80211"; then
                panic_cause="WiFi hardware/driver issue"
            elif echo "$panic_content" | grep -qi "kext\|extension\|com\.apple\|com\."; then
                panic_cause="Kernel extension (likely software issue)"
            elif echo "$panic_content" | grep -qi "sleep\|wake\|power\|hibernat"; then
                panic_cause="Sleep/Wake cycle issue"
            elif echo "$panic_content" | grep -qi "thermal\|temp\|overheat"; then
                panic_cause="Thermal/Overheating issue"
            fi
        fi

        if [[ $recent_panic_count -eq 0 ]]; then
            check_info "Panics found: $panic_count (all older than 30 days)"
            if [[ "$panic_cause" != "unknown" ]]; then
                verbose_info "Last panic cause: $panic_cause"
            fi
        elif [[ $recent_panic_count -lt $PANIC_COUNT_WARNING ]]; then
            check_warn "Recent panics (30 days): $recent_panic_count of $panic_count total"
            if [[ "$panic_cause" != "unknown" ]]; then
                check_info "Likely cause: $panic_cause"
                # Provide context based on cause type
                if [[ "$panic_cause" == *"software"* ]] || [[ "$panic_cause" == *"driver"* ]] || [[ "$panic_cause" == *"extension"* ]]; then
                    echo -e "    ${GREY}     This is often fixed by macOS updates. Less concerning.${NC}"
                elif [[ "$panic_cause" == *"Discrete GPU"* ]] || [[ "$panic_cause" == *"SSD"* ]] || [[ "$panic_cause" == *"RAM"* ]]; then
                    echo -e "    ${YELLOW}     Hardware-related cause. Investigate before purchase!${NC}"
                fi
            fi
            add_manual_check "Ask seller about system stability and crash history"
        else
            check_fail "Recent panics (30 days): $recent_panic_count (unstable system!)"
            echo -e "    ${RED}     Frequent recent panics indicate hardware problems.${NC}"
            if [[ "$panic_cause" != "unknown" ]]; then
                check_info "Likely cause: $panic_cause"
                echo -e "    ${RED}     Investigate $panic_cause before purchase!${NC}"
            fi
        fi
    fi

    # Show panic files if verbose mode enabled
    if [[ "$VERBOSE_MODE" == true && ${#all_panic_files[@]} -gt 0 ]]; then
        echo -e "    ${GREY}Panic log files (showing up to 5):${NC}"
        for ((i=0; i<${#all_panic_files[@]} && i<5; i++)); do
            verbose_info "${all_panic_files[i]}"
        done
    fi

    # Check for sleep/wake issues
    # =============================================================================
    # [UX FIX] Sleep/Wake Check with Timeout
    # Problem:  'log show --last 7d' can take 30-120+ seconds on systems with
    #           extensive logs. No progress indicator made script appear frozen.
    #           Users aborted thinking it crashed, missing important checks.
    # Solution: Add timeout, skip gracefully if too slow. Wake issues are
    #           better detected via manual testing anyway.
    # =============================================================================
    print_subsection "Sleep/Wake Issues"
    show_progress "Analyzing system logs (max 10s)"

    local wake_failures="0"
    # Use timeout to prevent hanging - gtimeout on macOS requires coreutils
    # Fall back to background process with sleep if timeout not available
    if command -v gtimeout &>/dev/null; then
        wake_failures=$(gtimeout 5 log show --predicate 'eventMessage contains "Wake failure"' --last 7d 2>/dev/null | grep -c "Wake failure" || echo "0")
    else
        # Native bash timeout approach
        (
            log show --predicate 'eventMessage contains "Wake failure"' --last 7d 2>/dev/null | grep -c "Wake failure" > /tmp/.mac_audit_wake_$$
        ) &
        local log_pid=$!

        # Wait up to 10 seconds
        # =================================================================
        # [UX] Reduced Sleep/Wake Log Analysis Timeout
        # Problem:  10 second timeout felt too long for users, especially
        #           when the log analysis often times out anyway on systems
        #           with extensive logs. The wait provided no visible feedback.
        # Solution: Reduce to 5 seconds. If logs are too large to parse in
        #           5 seconds, they're too large for 10 seconds too. Manual
        #           sleep/wake testing is more reliable anyway.
        # =================================================================
        local waited=0
        while kill -0 $log_pid 2>/dev/null && [[ $waited -lt 5 ]]; do
            sleep 1
            ((waited++))
        done

        if kill -0 $log_pid 2>/dev/null; then
            kill $log_pid 2>/dev/null
            wake_failures="timeout"
        elif [[ -f /tmp/.mac_audit_wake_$$ ]]; then
            wake_failures=$(cat /tmp/.mac_audit_wake_$$ 2>/dev/null || echo "0")
            rm -f /tmp/.mac_audit_wake_$$ 2>/dev/null
        fi
    fi
    clear_progress

    case "$wake_failures" in
        "timeout")
            check_info "Sleep/wake log analysis timed out (logs too large)"
            add_manual_check "Test sleep/wake manually: Close lid, wait, reopen"
            ;;
        "0"|"")
            check_pass "No recent sleep/wake issues in logs"
            ;;
        *)
            local wake_int
            wake_int=$(safe_int "$wake_failures" 0)
            if [[ $wake_int -gt 0 ]]; then
                check_warn "Wake failures in last 7 days: $wake_int"
                add_manual_check "Test sleep/wake multiple times before purchase"
            fi
            ;;
    esac

    # =========================================================================
    # [NEW CHECK] System Uptime - Suspicious reboot indicator
    # Problem:  Sellers often reboot Mac shortly before meeting to hide
    #           accumulated issues (high RAM usage, crashes). A Mac that
    #           has been running longer shows more realistic behavior.
    # Solution: Display uptime and warn if runtime is very short.
    # =========================================================================
    print_subsection "System Uptime"
    # =========================================================================
    # [BUGFIX] Robust uptime calculation
    # Problem:  Previous awk parsing of kern.boottime was fragile and broke
    #           on different macOS versions with varying output formats.
    #           Format: "{ sec = 1234567890, usec = 123456 }" but spacing varies.
    # Solution: Use sed with flexible whitespace matching to extract epoch.
    #           Fallback to 'uptime' command output if sysctl parsing fails.
    # =========================================================================
    local boot_epoch uptime_seconds uptime_hours uptime_display

    # [BUGFIX] kern.boottime format varies across macOS versions:
    #   Old: "{ sec = 1234567890, usec = 123456 } Thu Jan 1 00:00:00 1970"
    #   New: "sec = 1234567890, usec = 123456"
    # Previous sed pattern failed on some formats, returning empty/0.
    # Solution: More flexible extraction, validate result is reasonable.
    boot_epoch=$(sysctl -n kern.boottime 2>/dev/null | grep -oE 'sec = [0-9]+' | grep -oE '[0-9]+')

    # Validate: must be a number AND be a plausible epoch (after year 2000 = 946684800)
    local min_valid_epoch=946684800
    if [[ "$boot_epoch" =~ ^[0-9]+$ ]] && [[ "$boot_epoch" -gt "$min_valid_epoch" ]]; then
        local current_epoch
        current_epoch=$(date +%s)
        uptime_seconds=$((current_epoch - boot_epoch))
        uptime_hours=$((uptime_seconds / 3600))

        # =================================================================
        # [UX] Improved Uptime Display for Very Short Times
        # Problem:  When uptime_seconds < 60, uptime_mins calculated to 0,
        #           displaying "0 minutes (freshly booted)" which is
        #           technically correct but not informative. Also, anything
        #           under an hour got the same "freshly booted" warning even
        #           if it was 45 minutes (reasonable for a demo).
        # Solution: Show seconds for <2min, more nuanced messaging for
        #           different time ranges. Under 5 minutes is suspicious,
        #           5-60 minutes is notable but less concerning.
        # =================================================================
        if [[ $uptime_seconds -lt 120 ]]; then
            # Less than 2 minutes - show seconds, very suspicious
            check_warn "Uptime: ${uptime_seconds} seconds (JUST booted!)"
            echo -e "    ${YELLOW}     Suspicious timing. Ask seller why Mac was just restarted.${NC}"
        elif [[ $uptime_hours -lt 1 ]]; then
            local uptime_mins=$((uptime_seconds / 60))
            if [[ $uptime_mins -lt 5 ]]; then
                check_warn "Uptime: ${uptime_mins} minutes (freshly booted)"
                echo -e "    ${YELLOW}     Ask seller why Mac was just restarted.${NC}"
            else
                check_info "Uptime: ${uptime_mins} minutes (booted recently)"
            fi
        elif [[ $uptime_hours -lt 24 ]]; then
            check_info "Uptime: ~${uptime_hours} hours"
        else
            local uptime_days=$((uptime_hours / 24))
            check_pass "Uptime: ~${uptime_days} days (stable operation)"
        fi
    else
        # Fallback: parse uptime command output
        uptime_display=$(uptime 2>/dev/null | sed -E 's/.*up +//' | sed -E 's/,.*//')
        if [[ -n "$uptime_display" ]]; then
            check_info "Uptime: $uptime_display"
        else
            check_info "Uptime: Could not be determined"
        fi
    fi

    # =============================================================================
    # [BUGFIX] macOS Update Status Check
    # Problem:  Original code used `grep -c ... || echo "0"` which produced
    #           "0\n0" when grep found no matches (grep outputs "0" but exits
    #           with code 1, triggering the || clause to append another "0").
    #           This caused bash integer comparison to fail with syntax error.
    # Solution: Capture output first, then use grep -q for boolean check.
    #           Avoid arithmetic comparison entirely by using string matching.
    # =============================================================================
    print_subsection "macOS Update Status"
    local current_os current_build
    current_os=$(sw_vers -productVersion)
    current_build=$(sw_vers -buildVersion)

    check_info "Running: macOS $current_os ($current_build)"

    # Check for available updates (non-blocking, quick check)
    local update_output
    update_output=$(softwareupdate -l 2>&1)

    if echo "$update_output" | grep -qi "Software Update found"; then
        check_warn "Software updates available - system not fully current"
        add_manual_check "Update macOS after purchase: System Settings > Software Update"
    elif echo "$update_output" | grep -qi "No new software available"; then
        check_pass "macOS is up to date"
    else
        # Could not determine - might be offline or other issue
        check_info "Update status: Could not determine (check manually)"
    fi

    # =========================================================================
    # [NEW CHECK] macOS Installation Date
    # Problem:  A freshly installed macOS could indicate the seller wiped the
    #           system to hide problems (crashes, malware). Conversely, a very
    #           old install date confirms the system has been stable long-term.
    # Solution: Check install date from /var/db/.AppleSetupDone or similar.
    # =========================================================================
    print_subsection "macOS Installation Age"
    local install_date=""

    # Method 1: Check AppleSetupDone file creation date
    if [[ -f "/var/db/.AppleSetupDone" ]]; then
        install_date=$(stat -f "%Sm" -t "%Y-%m-%d" "/var/db/.AppleSetupDone" 2>/dev/null)
    fi

    # Method 2: Fallback to /var/log/install.log
    if [[ -z "$install_date" && -f "/var/log/install.log" ]]; then
        install_date=$(stat -f "%Sm" -t "%Y-%m-%d" "/var/log/install.log" 2>/dev/null)
    fi

    if [[ -n "$install_date" ]]; then
        local install_epoch today_epoch days_since
        install_epoch=$(date -j -f "%Y-%m-%d" "$install_date" "+%s" 2>/dev/null || echo 0)
        today_epoch=$(date +%s)

        if [[ $install_epoch -gt 0 ]]; then
            days_since=$(( (today_epoch - install_epoch) / 86400 ))

            if [[ $days_since -lt 7 ]]; then
                check_warn "macOS installed: $install_date (${days_since} days ago - VERY RECENT)"
                echo -e "    ${YELLOW}     Ask seller why system was freshly installed.${NC}"
            elif [[ $days_since -lt 30 ]]; then
                check_info "macOS installed: $install_date (${days_since} days ago - recent)"
            else
                local months_since=$((days_since / 30))
                check_pass "macOS installed: $install_date (~${months_since} months ago)"
            fi
        else
            check_info "macOS installed: $install_date"
        fi
    else
        check_info "Installation date: Could not be determined"
    fi
}


# =============================================================================
# PHASE 12: THERMAL SENSORS & SMC
# =============================================================================
# [NEW CHECK] Thermal Management Verification
# Problem:  Faulty temperature sensors or SMC issues cause fans to run at
#           max speed constantly OR never spin up (thermal throttling/damage).
#           Sellers may not disclose overheating issues. Thermal paste
#           degradation common in older Macs.
# Solution: Check sensor availability and fan status. Abnormal readings
#           indicate hardware issues or repairs.
# =============================================================================

check_thermal_sensors() {
    print_section "PHASE 12: THERMAL SENSORS"

    print_subsection "System Management Controller"

    # SMC version (Intel) or equivalent
    if [[ "$IS_APPLE_SILICON" == false ]]; then
        # [OPTIMIZATION] Use cached hardware data instead of redundant system_profiler call
        local smc_version
        smc_version=$(echo "$HW_DATA_CACHE" | grep "SMC Version" | awk -F': ' '{print $2}' | xargs)
        if [[ -n "$smc_version" ]]; then
            check_info "SMC Version: $smc_version"
        else
            # T2 Macs often don't report SMC version in the traditional way
            # This is normal, not a warning condition
            check_info "SMC Version: Not reported (normal for T2 Macs)"
        fi
        # =====================================================================
        # [ENHANCEMENT] SMC reset hint for troubleshooting
        # Problem:  Many Intel Mac issues (fans, battery, keyboard backlight)
        #           can be resolved via SMC reset. Buyers should know how to
        #           perform this if symptoms appear after purchase.
        # Solution: Always mention SMC reset option for Intel Macs.
        # =====================================================================
        add_manual_check "Intel Mac: Try SMC reset if issues occur (Shift+Ctrl+Option+Power)"
    else
        check_info "Apple Silicon: Integrated power management"
    fi

    # Fan status
    print_subsection "Cooling System"
    local fan_info
    fan_info=$(echo "$IOREG_CACHE" | grep -i "Fan" | head -5)

    if [[ -n "$fan_info" ]]; then
        # Check for fan speed sensors
        # [BUGFIX] grep -c with || echo "0" causes "0\n0" on no matches
        # Also: Use -E for extended regex (alternation with |)
        local fan_count
        fan_count=$(echo "$IOREG_CACHE" | grep -Ec "FanSpeed|Fan0|Fan1" 2>/dev/null) || true
        fan_count=${fan_count:-0}

        if [[ "$fan_count" -gt 0 ]]; then
            check_pass "Fan sensors detected: $fan_count"

            # =============================================================================
            # [ENHANCEMENT] Attempt to read actual fan speeds
            # Problem:  Knowing sensors exist is less useful than knowing current RPM.
            #           Stuck fans often report 0 RPM even when "detected".
            # Solution: Try to extract fan speed values from ioreg. Display if available.
            #           Note: Specific keys vary by Mac model, so this is best-effort.
            # =============================================================================
            local fan_speeds
            fan_speeds=$(echo "$IOREG_CACHE" | grep -E "FanSpeed|CurrentSpeed|TargetSpeed" | \
                         grep -oE '[0-9]{3,4}' | head -3 | tr '\n' '/' | sed 's/\/$//')

            if [[ -n "$fan_speeds" ]]; then
                check_info "Current fan speed(s): ${fan_speeds} RPM"
                # Warn if all fans report 0 (stuck/dead)
                if [[ "$fan_speeds" =~ ^0(/0)*$ ]]; then
                    check_warn "All fans report 0 RPM - may be stuck or off"
                fi
            fi
        else
            check_info "Fan sensor count unclear (normal for some models)"
        fi
    else
        # =============================================================================
        # [ENHANCEMENT] Form-factor aware fan detection
        # Problem:  Original only checked for fanless MacBook Air. Mac Pro has
        #           massive fans, Mac Studio has sophisticated cooling, etc.
        #           Each device type has different cooling expectations.
        # Solution: Check device type and set appropriate expectations.
        # =============================================================================
        case "$DEVICE_TYPE" in
            "laptop")
                if [[ "$SYSTEM_MODEL" == *"MacBook Air"* && "$IS_APPLE_SILICON" == true ]]; then
                    check_info "Fanless design (Apple Silicon MacBook Air)"
                else
                    check_warn "Fan information not detected - may indicate sensor issue"
                fi
                ;;
            "desktop")
                check_info "Fan sensors not enumerated (normal for ${SYSTEM_MODEL})"
                add_manual_check "Listen for fan noise during stress test"
                ;;
            "all-in-one")
                check_warn "Fan information not detected"
                ;;
            *)
                check_warn "Fan information not detected"
                ;;
        esac
    fi

    # Temperature sensors
    print_subsection "Temperature Sensors"
    # [BUGFIX] grep -c with || echo "0" causes "0\n0" on no matches
    # Also: Use -E for extended regex (alternation with |)
    local temp_sensors
    temp_sensors=$(echo "$IOREG_CACHE" | grep -Ec "Temperature|Temp|thermal" 2>/dev/null) || true
    temp_sensors=${temp_sensors:-0}

    if [[ "$temp_sensors" -gt 5 ]]; then
        check_pass "Temperature sensors active: $temp_sensors+"
    elif [[ "$temp_sensors" -gt 0 ]]; then
        check_info "Temperature sensors found: $temp_sensors"
    else
        check_warn "Temperature sensor data not accessible"
    fi

    add_manual_check "During stress test: Verify fans spin up smoothly"
    add_manual_check "Check for unusual heat spots on case bottom"
}

# =============================================================================
# PHASE 13: RECOVERY & REINSTALL READINESS
# =============================================================================
# [HISTORY - NEW IN v10]
# Problem:  Buyers often want to clean install macOS after purchase. If Recovery
#           partition is missing or damaged, or if device can't boot to Recovery,
#           reinstall becomes much harder (need bootable USB or another Mac).
#
# Solution: Check diskutil for presence of Recovery volume/partition.
# =============================================================================

check_recovery_readiness() {
    print_section "PHASE 13: RECOVERY READINESS"

    print_subsection "Recovery Partition"
    local recovery_found=false

    # =========================================================================
    # [BUGFIX] Robust Recovery partition detection
    # Problem:  Previous method was unreliable with APFS containers and could
    #           falsely identify external drives as Recovery. APFS uses hidden
    #           "Preboot" and Recovery volumes with different structure.
    # Solution: Combine multiple detection methods:
    #           1. Check APFS container of boot volume
    #           2. Use diskutil apfs listVolumeGroups for Recovery role
    #           3. Fallback to classic partition search for older systems
    # =========================================================================

    # Method 1: APFS Volume Group Check (most modern approach)
    local boot_disk
    boot_disk=$(diskutil info / 2>/dev/null | grep "Part of Whole:" | awk '{print $NF}')

    if [[ -n "$boot_disk" ]]; then
        if diskutil apfs listVolumeGroups 2>/dev/null | grep -qi "recovery"; then
            recovery_found=true
        fi
    fi

    # Method 2: Container-based search
    if [[ "$recovery_found" == false ]]; then
        local container_ref
        container_ref=$(diskutil info / 2>/dev/null | grep "APFS Container Reference:" | awk '{print $NF}')
        if [[ -n "$container_ref" ]]; then
            if diskutil apfs list "$container_ref" 2>/dev/null | grep -qiE "recovery|preboot"; then
                recovery_found=true
            fi
        fi
    fi

    # Method 3: Classic partition search (older systems/HFS+)
    if [[ "$recovery_found" == false ]]; then
        if diskutil list internal 2>/dev/null | grep -qiE "Recovery|Apple_Boot"; then
            recovery_found=true
        fi
    fi

    if [[ "$recovery_found" == true ]]; then
        check_pass "Recovery System: Present"
        # =====================================================================
        # [BUGFIX] Correct conditional Recovery instruction
        # Problem:  ${VAR:+x}${VAR:-y} syntax doesn't work with boolean strings.
        #           "false" is not empty, so both parts were concatenated.
        # Solution: Explicit if/else for clear case distinction.
        # =====================================================================
        if [[ "$IS_APPLE_SILICON" == true ]]; then
            add_manual_check "Test Recovery Mode: Restart + hold Power button"
        else
            add_manual_check "Test Recovery Mode: Restart + Cmd+R"
        fi
    else
        check_warn "Recovery System: Not clearly detected"
        check_info "This can be normal - manual test recommended"
        add_manual_check "IMPORTANT: Test Recovery Mode manually!"
    fi

    # Check if signed into Apple ID (for Activation Lock removal later)
    print_subsection "iCloud Association"
    # Using a heuristic: check if iCloud preferences file exists/has content
    if [[ -f "$HOME/Library/Preferences/MobileMeAccounts.plist" ]]; then
        check_info "iCloud Accounts detected on user profile"
        echo -e "    ${YELLOW}     Reminder: Seller MUST sign out before handing over device.${NC}"
    else
        check_info "No local iCloud accounts detected (Good sign)"
    fi
}

# =============================================================================
# PHASE 14: TIME MACHINE STATUS
# =============================================================================
# [NEW CHECK] Time Machine backup configuration
# Problem:  Time Machine status reveals if Mac was actively used for data
#           storage. An "always excluded" list full of user folders may indicate
#           the seller was hiding data. Also shows if local snapshots exist.
# Solution: Check TM destination and exclusion list. Inform buyer about any
#           attached backup drives (should be removed before sale).
# =============================================================================

check_time_machine() {
    print_section "PHASE 14: TIME MACHINE"

    print_subsection "Backup Status"
    local tm_status
    tm_status=$(tmutil destinationinfo 2>/dev/null)

    if echo "$tm_status" | grep -q "No destinations"; then
        check_info "Time Machine: Not configured (normal for wiped Mac)"
    elif [[ -n "$tm_status" ]]; then
        check_info "Time Machine: Configured"

        local dest_name
        dest_name=$(echo "$tm_status" | grep "Name" | head -1 | awk -F': ' '{print $2}')
        if [[ -n "$dest_name" ]]; then
            check_warn "Backup destination still configured: $dest_name"
            echo -e "    ${YELLOW}     Seller should remove backup drive association.${NC}"
        fi
    fi

    # Check for local snapshots
    print_subsection "Local Snapshots"
    local snapshots
    snapshots=$(tmutil listlocalsnapshots / 2>/dev/null | grep -c "com.apple" || echo "0")

    if [[ "$snapshots" -gt 0 ]]; then
        check_info "Local snapshots: $snapshots (can recover disk space)"
        verbose_info "Run 'sudo tmutil deletelocalsnapshots /' after purchase if needed"
    else
        check_pass "No local snapshots consuming disk space"
    fi

    # Check last backup date
    print_subsection "Last Backup"
    local last_backup
    last_backup=$(defaults read /Library/Preferences/com.apple.TimeMachine.plist DestinationVolumeUUID 2>/dev/null)

    if [[ -n "$last_backup" ]]; then
        check_info "Previous backup history exists"
        add_manual_check "Consider: Has seller's data been fully removed?"
    else
        check_pass "No backup history references found"
    fi
}

# =============================================================================
# PHASE 15: THERMAL STRESS TEST
# =============================================================================

run_stress_test() {
    print_section "PHASE 15: THERMAL STRESS TEST"

    # =============================================================================
    # [BUGFIX] CPU Core Count Definition
    # Problem:  Variable $cpu_cores wurde verwendet ohne je definiert zu werden.
    #           Dies führte dazu, dass die Stress-Test-Schleife null Iterationen
    #           hatte und somit kein CPU-Load erzeugt wurde. Der gesamte
    #           Stress-Test war dadurch wirkungslos.
    # Solution: CPU-Kerne via sysctl abfragen. Fallback auf 4 Kerne wenn
    #           sysctl fehlschlägt (unwahrscheinlich, aber defensiv).
    # =============================================================================
    local cpu_cores
    cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)

    if [[ "$SKIP_STRESS_TEST" == true ]]; then
        check_info "Stress test skipped (--quick mode)"
        add_manual_check "Run stress test manually to check for fan noise/coil whine"
        return
    fi

    local cores_display
    cores_display=$(printf "%2d" "$cpu_cores")

    # =============================================================================
    # [BUGFIX] Stress Test Box Alignment
    # Problem:  Dynamic message with variable cpu_cores and STRESS_TEST_DURATION
    #           caused misaligned box borders. The emoji also takes variable
    #           terminal width depending on font rendering.
    # Solution: Use printf with fixed field width for all variable content lines.
    #           Emojis removed from box structure (placed outside for compatibility).
    # =============================================================================
    echo -e "  ${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${YELLOW}║           *** THERMAL STRESS TEST ***                      ║${NC}"
    echo -e "  ${YELLOW}╠════════════════════════════════════════════════════════════╣${NC}"
    printf "  ${YELLOW}║  Maxing out all %d CPU cores for %d seconds.%-15s║${NC}\n" "$cpu_cores" "$STRESS_TEST_DURATION" ""
    echo -e "  ${YELLOW}║                                                            ║${NC}"
    echo -e "  ${YELLOW}║  LISTEN FOR:                                               ║${NC}"
    echo -e "  ${YELLOW}║  • Fan noise (Smooth whoosh = GOOD)                        ║${NC}"
    echo -e "  ${YELLOW}║  • Grinding/Rattling (Bearing fail = BAD)                  ║${NC}"
    echo -e "  ${YELLOW}║  • High-pitched Whine (Coil whine = ANNOYING but OK)       ║${NC}"
    echo -e "  ${YELLOW}║  • Silence + Heat (Dead fans = CRITICAL)                   ║${NC}"
    # Add device-specific guidance
    if [[ "$DEVICE_TYPE" == "desktop" ]]; then
        echo -e "  ${YELLOW}║                                                            ║${NC}"
        echo -e "  ${YELLOW}║  DESKTOP NOTE: Fans are internal - put ear near vents!     ║${NC}"
    fi
    echo -e "  ${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Press ${BOLD}[ENTER]${NC} to start the turbine."
    echo -e "  Press ${BOLD}[S]${NC} to skip this test."
    echo ""

    # =============================================================================
    # [BUGFIX] Clear input buffer before critical read
    # Problem:  Previous read commands (display test y/n, audio test y/n) leave
    #           trailing newlines/characters in the input buffer. When user types
    #           'y' then Enter, the Enter remains buffered. The next read -n 1
    #           immediately consumes this buffered Enter, causing the stress test
    #           to start without any actual user input.
    # Solution: Flush stdin buffer using read with timeout before the real prompt.
    #           The -t 0.1 gives a tiny window to drain any buffered characters.
    #           Loop ensures we catch multiple buffered characters if present.
    # =============================================================================
    # Flush any buffered input (leftover Enter keys from previous prompts)
    while read -r -t 0.1 -n 1000 discard 2>/dev/null; do :; done

    local user_choice=""
    # Wait for single keypress, no timeout (user must explicitly choose)
    read -r -n 1 user_choice
    echo ""  # Newline after single-char input

    # =========================================================================
    # [BUGFIX] Bash 3.2 Lowercase Compatibility
    # Problem:  ${var,,} syntax for lowercase conversion requires Bash 4.0+.
    #           macOS ships with Bash 3.2 due to GPL v3 licensing. Using this
    #           syntax causes "bad substitution" error on stock macOS Terminal.
    # Solution: Explicit comparison against both cases instead of conversion.
    # =========================================================================
    if [[ "$user_choice" == "s" || "$user_choice" == "S" ]]; then
        check_info "Stress test skipped by user"
        # =====================================================================
        # [ENHANCEMENT] More specific stress test instructions when skipped
        # Problem:  "Open multiple heavy apps" is vague. Users unsure what
        #           qualifies as "heavy" or how long to run the test.
        # Solution: Provide concrete, actionable stress test instructions.
        # =====================================================================
        add_manual_check "STRESS TEST: Open 3+ browser tabs with YouTube, run for 5+ minutes"
        add_manual_check "During stress: Listen for fan noise, check case temperature"
        return
    fi

    echo ""
    echo -e "  ${RED}${BOLD}>>> TURBINES ENGAGED. LISTEN CAREFULLY. <<<${NC}"
    echo ""

    # Launch load generators
    STRESS_PIDS=()
    for ((i=1; i<=cpu_cores; i++)); do
        yes > /dev/null 2>&1 &
        STRESS_PIDS+=($!)
    done

    # Hide cursor
    tput civis 2>/dev/null || true

    # Countdown
    for ((remaining=STRESS_TEST_DURATION; remaining>0; remaining--)); do
        printf "\r  ⏱️  Stress Test: %02d s remaining  (Press ANY KEY to stop) " "$remaining"
        read -t 1 -n 1 -s -r && break
    done

    # Cleanup handles killing via trap logic
    cleanup
    echo ""
    echo -e "\n  ${GREEN}✓ Stress test finished. Silence restored.${NC}"
}

# =============================================================================
# REPORT GENERATION
# =============================================================================

generate_report() {
    print_section "AUDIT SUMMARY & RISK ASSESSMENT"

    # Calculate Risk Score
    local risk_level="LOW RISK"
    local risk_color="$GREEN"

    if [[ $FAIL_COUNT -gt 0 ]]; then
        risk_level="CRITICAL RISK / DO NOT BUY"
        risk_color="$RED"
    elif [[ $WARN_COUNT -gt 2 ]]; then
        risk_level="MODERATE RISK / PROCEED WITH CAUTION"
        risk_color="$YELLOW"
    fi

    # Terminal Output
    echo -e "  Checks Passed:   ${GREEN}$PASS_COUNT${NC}"
    echo -e "  Warnings:        ${YELLOW}$WARN_COUNT${NC}"
    echo -e "  Critical Fails:  ${RED}$FAIL_COUNT${NC}"
    echo -e "  Risk Assessment: ${risk_color}${BOLD}$risk_level${NC}"
    echo ""

    if [[ ${#CRITICAL_ISSUES[@]} -gt 0 ]]; then
        echo -e "${RED}${BOLD}  !!! CRITICAL ISSUES !!!${NC}"
        for issue in "${CRITICAL_ISSUES[@]}"; do
            echo -e "  • $issue"
        done
        echo ""
    fi

    if [[ ${#WARNING_ISSUES[@]} -gt 0 ]]; then
        echo -e "${YELLOW}${BOLD}  ! WARNINGS !${NC}"
        for issue in "${WARNING_ISSUES[@]}"; do
            echo -e "  • $issue"
        done
        echo ""
    fi

    # =============================================================================
    # [ENHANCEMENT] Apple Diagnostics Reminder
    # Problem:  This script checks many things but cannot perform low-level
    #           hardware diagnostics (RAM test, sensor calibration, etc.).
    #           Apple Diagnostics is built into every Mac and catches issues
    #           this script cannot detect.
    # Solution: Always recommend running Apple Diagnostics as final step.
    # =============================================================================
    echo ""
    echo -e "${MAGENTA}${BOLD}  RECOMMENDED: Run Apple Diagnostics for hardware verification${NC}"
    if [[ "$IS_APPLE_SILICON" == true ]]; then
        echo -e "  ${GREY}→ Shut down, then hold Power button until 'Loading options' appears${NC}"
        echo -e "  ${GREY}→ Press Cmd+D for diagnostics${NC}"
    else
        echo -e "  ${GREY}→ Shut down, then hold D key while pressing Power${NC}"
        echo -e "  ${GREY}→ Or hold Option+D for internet-based diagnostics${NC}"
    fi
    echo ""

    echo -e "${CYAN}${BOLD}  MANUAL CHECKLIST:${NC}"
    for check in "${MANUAL_CHECKS[@]}"; do
        echo -e "  □ $check"
    done

    # File Output
    if [[ "$SKIP_REPORT" != true && -n "$REPORT_FILE" ]]; then
        echo ""
        echo -e "  ${GREY}Saving forensic report...${NC}"

        {
            echo "============================================================"
            echo "   MAC AUDIT REPORT - ${SCRIPT_NAME} v${SCRIPT_VERSION}"
            echo "   Date: $(date)"
            echo "   Target: ${SYSTEM_SERIAL} / ${SYSTEM_MODEL}"
            echo "============================================================"
            echo ""
            echo "SUMMARY:"
            echo "  Risk Level: $risk_level"
            echo "  Fails: $FAIL_COUNT | Warnings: $WARN_COUNT | Passes: $PASS_COUNT"
            echo ""

            if [[ ${#CRITICAL_ISSUES[@]} -gt 0 ]]; then
                echo "CRITICAL ISSUES:"
                printf '  - %s\n' "${CRITICAL_ISSUES[@]}"
                echo ""
            fi

            if [[ ${#WARNING_ISSUES[@]} -gt 0 ]]; then
                echo "WARNINGS:"
                printf '  - %s\n' "${WARNING_ISSUES[@]}"
                echo ""
            fi

            echo "MANUAL CHECKLIST:"
            printf '  [ ] %s\n' "${MANUAL_CHECKS[@]}"
            echo ""
            echo "SYSTEM SNAPSHOT:"
            echo "----------------"
            echo "Chip: $SYSTEM_CHIP"
            echo "RAM: $SYSTEM_RAM"
            echo "OS: $(sw_vers -productVersion)"
            echo "----------------"

        } > "$REPORT_FILE" 2>/dev/null

        if [[ -f "$REPORT_FILE" ]]; then
            echo -e "  ${GREEN}✓ Report saved to: $REPORT_FILE${NC}"
        else
            echo -e "  ${YELLOW}⚠ Failed to write report (permission denied?)${NC}"
        fi
    fi
}

# =============================================================================
# MAIN EXECUTION LOOP
# =============================================================================

main() {
    # Argument Parsing
    for arg in "$@"; do
        case $arg in
            --quick) SKIP_STRESS_TEST=true ;;
            --no-report) SKIP_REPORT=true ;;
            --verbose) VERBOSE_MODE=true ;;
            --help)
                echo "Usage: bash mac_audit.sh [--quick] [--no-report] [--verbose]"
                exit 0
                ;;
        esac
    done

    # UI Init
    clear
    print_header "$SCRIPT_NAME v$SCRIPT_VERSION"
    echo -e "  ${GREY}Initializing forensic audit sequence...${NC}"

    # Execution
    check_prerequisites
    cache_system_data

    # The Phases
    verify_physical_serial      # Phase 1
    check_system_identity       # Phase 2
    check_enterprise_locks      # Phase 3
    check_activation_lock       # Phase 4
    check_storage_health        # Phase 5
    check_battery_health        # Phase 6
    check_gpu_health            # Phase 7 (New)
    check_component_authenticity # Phase 8
    check_security_posture      # Phase 9
    check_ports_connectivity    # Phase 10
    check_system_stability      # Phase 11
    check_thermal_sensors       # Phase 12 (New)
    check_recovery_readiness    # Phase 13
    check_time_machine          # Phase 14 (new)
    run_stress_test             # Phase 15

    # Finalize
    generate_report

    echo ""
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  AUDIT COMPLETE. TRUST NO ONE. VERIFY EVERYTHING.${NC}"
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Start
main "$@"
