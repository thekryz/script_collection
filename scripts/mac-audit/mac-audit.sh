#!/bin/bash

# ╔════════════════════════════════════════════════════════════════[...]
# ║                                                                           ║
# ║   MAC AUDIT PUNK v1.0 - "TRUST NO SELLER" ULTIMATE EDITION                ║
# ║                                                                           ║
# ╠════════════════════════════════════════════════════════════════[...]
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
# ║               └────────────────────────────────────────────────────────┘  [...]
# ║               ┌─ HARDWARE HEALTH ──────────────────────────────────────┐  ║
# ║               │ • Storage SMART status & health                        │  ║
# ║               │ • Battery cycle count & capacity                       │  ║
# ║               │ • GPU detection & discrete GPU check                   │  ║
# ║               │ • Thermal stress test with audio guidance              │  ║
# ║               │ • Kernel panic history analysis                        │  ║
# ║               └────────────────────────────────────────────────────────┘  [...]
# ║               ┌─ COMPONENTS ───────────────────────────────────────────┐  ║
# ║               │ • Camera, Audio, Display authenticity + active tests   │  ║
# ║               │ • Touch ID / Face ID status                            │  ║
# ║               │ • Touch Bar functionality (if present)                 │  ║
# ║               │ • Keyboard & Trackpad guidance                         │  ║
# ║               └────────────────────────────────────────────────────────┘  [...]
# ║               ┌─ SECURITY ─────────────────────────────────────────────┐  ║
# ║               │ • SIP, FileVault, Gatekeeper status                    │  ║
# ║               │ • Firmware security (T2 / Secure Enclave)              │  ║
# ║               │ • Tampering & jailbreak detection                      │  ║
# ║               │ • Recovery partition verification                      │  ║
# ║               └────────────────────────────────────────────────────────┘  [...]
# ║               ┌─ THERMAL ──────────────────────────────────────────────┐  ║
# ║               │ • SMC version and status                               │  ║
# ║               │ • Fan sensor detection                                 │  ║
# ║               │ • Temperature sensor verification                      │  ║
# ║               │ • Thermal stress test with audio guidance              │  ║
# ║               └────────────────────────────────────────────────────────┘  [...]
# ║               ┌─ CONNECTIVITY ─────────────────────────────────────────┐  ║
# ║               │ • USB/Thunderbolt port detection                       │  ║
# ║               │ • WiFi & Bluetooth status                              │  ║
# ║               │ • Port testing guidance                                │  ║
# ║               └────────────────────────────────────────────────────────┘  [...]
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
# ╚═══════════════════════════════════════════════════════════════��[...]

export LC_ALL=C
export LANG=C

# =============================================================================
# CONFIGURATION CONSTANTS
# =============================================================================

readonly SCRIPT_VERSION="1.0"
readonly SCRIPT_NAME="MAC AUDIT PUNK"
readonly MIN_MACOS_VERSION="10.15"


# =============================================================================
# THRESHOLD CONSTANTS
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
REPORT_FILE=""

# CLI Flags (mutable by argument parser)
SKIP_STRESS_TEST=false
SKIP_REPORT=false
VERBOSE_MODE=false

# =============================================================================
# TERMINAL COLOR HANDLING
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
CRITICAL_ISSUES=()
WARNING_ISSUES=()
MANUAL_CHECKS=()

# Data caches (fetched once at startup, reused throughout)
HW_DATA_CACHE=""
POWER_DATA_CACHE=""
GPU_DATA_CACHE=""
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
DEVICE_TYPE=""              # "laptop", "desktop", "all-in-one"
HAS_BUILTIN_DISPLAY=false
HAS_BUILTIN_CAMERA=false
HAS_BUILTIN_SPEAKERS=false
HAS_BUILTIN_MIC=false
HAS_BUILTIN_KEYBOARD=false

# =============================================================================
# PROCESS SAFETY & CLEANUP
# =============================================================================
STRESS_PIDS=()

cleanup() {
    # Terminate any stress test processes we spawned
    if [[ ${#STRESS_PIDS[@]} -gt 0 ]]; then
        for pid in "${STRESS_PIDS[@]}"; do
            kill -TERM "$pid" 2>/dev/null || true
            sleep 0.1
            kill -KILL "$pid" 2>/dev/null || true
        done
        STRESS_PIDS=()
    fi
    rm -f /tmp/.mac_audit_w$$ 2>/dev/null || true
    rm -f /tmp/.mac_audit_display_test_$$.html 2>/dev/null || true
    tput cnorm 2>/dev/null || true
}

trap cleanup EXIT INT TERM HUP

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

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

to_uppercase() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

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

print_header() {
    local text="$1"
    local max_len=58
    if [[ ${#text} -gt $max_len ]]; then
        text="${text:0:$((max_len-3))}..."
    fi

    echo ""
    echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════[...]"
    printf "${CYAN}${BOLD}║  %-60s║${NC}\n" "$text"
    echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════[...]"
}

print_section() {
    local text="$1"
    local max_len=58
    if [[ ${#text} -gt $max_len ]]; then
        text="${text:0:$((max_len-3))}..."
    fi

    echo ""
    echo -e "${BOLD}┌─────────────────────────────────────────────────────────�[...]"
    printf "${BOLD}│  %-60s│${NC}\n" "$text"
    echo -e "${BOLD}└─────────────────────────────────────────────────────────�[...]"
}

print_subsection() {
    echo -e "  ${BLUE}■ $1${NC}"
}

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

    show_progress "Verifying system data access"
    local test_profile
    test_profile=$(system_profiler SPHardwareDataType 2>/dev/null | head -5)
    clear_progress

    if [[ -z "$test_profile" ]]; then
        check_fail "Cannot access system profile data!"
        echo -e "    ${RED}Try: Full Disk Access for Terminal in System Settings > Privacy${NC}"
        exit 1
    fi

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
cache_system_data() {
    echo -e "  ${GREY}Gathering system information...${NC}"

    show_progress "System profiler data (combined)"
    local combined_profile
    combined_profile=$(system_profiler SPHardwareDataType SPPowerDataType SPDisplaysDataType 2>/dev/null)

    # Split combined output into individual caches
    HW_DATA_CACHE=$(echo "$combined_profile" | awk '/Hardware Overview:/,/^$|^[A-Z].*:$/{print}' | head -50)
    POWER_DATA_CACHE=$(echo "$combined_profile" | awk '/Power:|Battery Information:/,/^[A-Z].*:$/{if(/^[A-Z].*:$/ && !/Power:/ && !/Battery/) exit; print}')
    GPU_DATA_CACHE=$(echo "$combined_profile" | awk '/Graphics\/Displays:/,/^[A-Z].*:$/{if(/^[A-Z].*:$/ && !/Graphics/) exit; print}')

    if [[ -z "$HW_DATA_CACHE" ]] || ! echo "$HW_DATA_CACHE" | grep -q "Serial Number"; then
        show_progress "Hardware data (fallback)"
        HW_DATA_CACHE=$(system_profiler SPHardwareDataType 2>/dev/null)
    fi
    if [[ -z "$POWER_DATA_CACHE" ]]; then
        POWER_DATA_CACHE=$(system_profiler SPPowerDataType 2>/dev/null)
    fi
    if [[ -z "$GPU_DATA_CACHE" ]] || ! echo "$GPU_DATA_CACHE" | grep -qi "Chipset\|Metal\|VRAM\|Display"; then
        GPU_DATA_CACHE=$(system_profiler SPDisplaysDataType 2>/dev/null)
    fi

    show_progress "IORegistry data"
    IOREG_CACHE=$(ioreg -l -w0 2>/dev/null)

    clear_progress
    check_pass "System data cached successfully"

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

    case "$SYSTEM_MODEL_ID" in
        MacBookPro13,2|MacBookPro13,3|\
        MacBookPro14,2|MacBookPro14,3|\
        MacBookPro15,1|MacBookPro15,2|MacBookPro15,3|MacBookPro15,4|\
        MacBookPro16,1|MacBookPro16,2|MacBookPro16,3|MacBookPro16,4)
            HAS_TOUCH_BAR=true
            ;;
    esac

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
    if echo "$IOREG_CACHE" | grep -q "AppleSEPKeyStore"; then
        HAS_TOUCH_ID=true
    fi
}

# =============================================================================
# PHASE 1: PHYSICAL SERIAL VERIFICATION
# =============================================================================

verify_physical_serial() {
    print_section "PHASE 1: PHYSICAL SERIAL VERIFICATION"

    echo -e "  ${YELLOW}╔════════════════════════════════════════════════════════[...]
    echo -e "  ${YELLOW}║  ${BOLD}THIS IS THE MOST IMPORTANT ANTI-FRAUD CHECK!${NC}${YELLOW}              ║${NC}"
    echo -e "  ${YELLOW}╠════════════════════════════════════════════════════════[...]
    echo -e "  ${YELLOW}║  Find the serial number ENGRAVED on the device:            ║${NC}"
    echo -e "  ${YELLOW}║                                                            ║${NC}"
    echo -e "  ${YELLOW}║  • MacBook: Bottom case, near regulatory markings          ║${NC}"
    echo -e "  ${YELLOW}║  • iMac: Stand base or back panel lower edge               ║${NC}"
    echo -e "  ${YELLOW}║  • Mac mini: Bottom plate                                  ║${NC}"
    echo -e "  ${YELLOW}║  • Mac Studio: Bottom plate                                ║${NC}"
    echo -e "  ${YELLOW}║  • Mac Pro: Top case handle or back panel                  ║${NC}"
    echo -e "  ${YELLOW}╚════════════════════════════════════════════════════════[...]
    echo ""

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
        echo -e "    ${RED}╔═══════════════════════════════════════════════════════[...]
        echo -e "    ${RED}║                  ⚠️  MAJOR RED FLAG ⚠️                       ║${NC}"
        echo -e "    ${RED}╠═══════════════════════════════════════════════════════[...]
        echo -e "    ${RED}║  The logic board serial does NOT match the case serial!    ║${NC}"
        echo -e "    ${RED}║                                                            ║${NC}"
        echo -e "    ${RED}║  This could mean:                                          ║${NC}"
        echo -e "    ${RED}║  • Stolen logic board in a legitimate case                 ║${NC}"
        echo -e "    ${RED}║  • Blacklisted device in disguise                          ║${NC}"
        echo -e "    ${RED}║  • Undisclosed repair or refurbishment                     ║${NC}"
        echo -e "    ${RED}║  • Parts Mac assembled from multiple devices               ║${NC}"
        echo -e "    ${RED}║                                                            ║${NC}"
        echo -e "    ${RED}║  RECOMMENDATION: Do not purchase unless seller explains.   ║${NC}"
        echo -e "    ${RED}╚═══════════════════════════════════════════════════════[...]
        echo ""
        read -rp "  Press [ENTER] to acknowledge this risk and continue..."
    fi
}

# =============================================================================
# PHASE 2: SYSTEM IDENTITY
# =============================================================================

check_system_identity() {
    print_section "PHASE 2: SYSTEM IDENTITY"

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

    add_manual_check "Check warranty: https://checkcoverage.apple.com (Serial: $SYSTEM_SERIAL)"
}

# =============================================================================
# PHASE 3: ENTERPRISE LOCK DETECTION (MDM/DEP)
# =============================================================================

check_enterprise_locks() {
    print_section "PHASE 3: ENTERPRISE LOCKS (MDM/DEP)"

    show_progress "Checking enrollment status"

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

    local activation_status
    activation_status=$(echo "$HW_DATA_CACHE" | grep "Activation Lock" | awk -F': ' '{print $2}' | xargs 2>/dev/null)

    case "$activation_status" in
        "Disabled")
            check_pass "Activation Lock: DISABLED (ready for new owner)"
            ;;
        "Enabled")
            check_fail "Activation Lock: ENABLED - Device is iCloud locked!"
            echo ""
            echo -e "    ${RED}╔═════════════════════════════════════════════════════��[...]
            echo -e "    ${RED}║            ⛔ CRITICAL: ACTIVATION LOCK ON ⛔               ║${NC}"
            echo -e "    ${RED}╠═════════════════════════════════════════════════════��[...]
            echo -e "    ${RED}║  This device CANNOT be activated without the original      ║${NC}"
            echo -e "    ${RED}║  owner's Apple ID email and password!                      ║${NC}"
            echo -e "    ${RED}║                                                            ║${NC}"
            echo -e "    ${RED}║  • If erased, it becomes a paperweight                     ║${NC}"
            echo -e "    ${RED}║  • Apple cannot bypass this (security by design)           ║${NC}"
            echo -e "    ${RED}║  • Seller MUST disable before you pay                      ║${NC}"
            echo -e "    ${RED}║                                                            ║${NC}"
            echo -e "    ${RED}║  Steps: Settings > Apple ID > Find My > Find My Mac > OFF ║${NC}"
            echo -e "    ${RED}╚═════════════════════════════════════════════════════��[...]
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

    print_subsection "Volume Usage"
    local free_space used_pct
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

    print_subsection "Capacity Health"
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

    print_subsection "Battery Authenticity"
    local battery_mfg=""

    # Query specifically the AppleSmartBattery class - NOT the full ioreg cache
    battery_mfg=$(ioreg -rc AppleSmartBattery 2>/dev/null | \
        grep '"Manufacturer"' | \
        head -1 | \
        sed 's/.*"Manufacturer" *= *"\([^\"]*\)".*/\1/')

    # Fallback: Try alternate field name used on some systems
    if [[ -z "$battery_mfg" ]]; then
        battery_mfg=$(ioreg -rc AppleSmartBattery 2>/dev/null | \
            grep '"DeviceName"\|"BatteryManufacturer"' | \
            head -1 | \
            sed 's/.*= *"\([^\"]*\)".*/\1/')
    fi

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

check_gpu_health() {
    print_section "PHASE 7: GPU & GRAPHICS"

    print_subsection "Graphics Hardware"

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

    # =========================================================================
# [...] (file truncated in this query for brevity)
