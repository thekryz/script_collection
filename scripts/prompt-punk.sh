#!/usr/bin/env zsh
# ============================================================================
#  PROMPT-PUNK v1.0 — Zsh Prompts Without the Bullshit
# ============================================================================
#
#  One command to change your prompt. Auto-backups. No plugins. No bloat.
#
#  USAGE
#    prompt-punk              Interactive style picker
#    prompt-punk -s N         Set style N (1-8)
#    prompt-punk -s r         Random style
#    prompt-punk -c           Show current config
#    prompt-punk -l           List backups
#    prompt-punk -r           Restore last backup
#    prompt-punk -h/-v        Help/Version
#
#  REQUIREMENTS
#    zsh >= 5.0
#    Required: sed grep diff cp mkdir date mv
#    Optional: rm touch readlink stat chmod (graceful degradation)
#
#  PLATFORMS
#    macOS, Linux, FreeBSD, OpenBSD, NetBSD, DragonFly, Solaris, WSL
#
#  ENVIRONMENT
#    ZDOTDIR   Config directory (default: $HOME). Supports ~/path syntax.
#    NO_COLOR  Disables colored output (no-color.org)
#
#  BACKUPS
#    Location: $ZDOTDIR/.zshrc_backups/
#    Limit:    10 files, auto-rotated, content-deduplicated
#
#  EXIT CODES
#    0   Success
#    1   Error
#    130 Interrupted (Ctrl+C / SIGINT)
#    143 Terminated (SIGTERM/SIGHUP)
#
#  LIMITATIONS
#    • Only modifies lines starting with ^PROMPT= (ignores export/indented)
#    • Inline comments after PROMPT= are discarded
#    • Multi-line PROMPT definitions not supported
#    • No file locking — avoid concurrent instances
#    • Reserved chars: § (field separator), \x01 (sed delimiter)
# ============================================================================

# ============================================================================
# SHELL ENVIRONMENT
# ============================================================================

emulate -L zsh
set -euo pipefail
IFS=$' \t\n'

# ============================================================================
# GLOBAL STATE
# ============================================================================

_PP_TEMP_FILE=""

# ============================================================================
# EARLY VALIDATION
# ============================================================================

if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
    print -u2 "FATAL: \$HOME is unset or not a directory"
    exit 1
fi

if ! (( ${ZSH_VERSION%%.*} >= 5 )) 2>/dev/null; then
    print -u2 "FATAL: Requires zsh >= 5.0 (have: ${ZSH_VERSION:-unknown})"
    exit 1
fi

for _pp_t in sed grep diff cp mkdir date mv; do
    command -v "$_pp_t" >/dev/null 2>&1 || {
        print -u2 "FATAL: Required tool '$_pp_t' not found in PATH"
        exit 1
    }
done
unset _pp_t

# ============================================================================
# ZDOTDIR RESOLUTION
# ============================================================================

_pp_cfg="$HOME"
if [[ -n "${ZDOTDIR:-}" ]]; then
    _pp_raw="$ZDOTDIR"
    # Expand ~/path to $HOME/path (but not ~user/path)
    [[ "$_pp_raw" == "~/"* ]] && _pp_raw="${HOME}${_pp_raw#"~"}"
    [[ "$_pp_raw" == "~" ]] && _pp_raw="$HOME"
    # Strip trailing slash to avoid //path issues
    _pp_raw="${_pp_raw%/}"
    if [[ -d "$_pp_raw" ]]; then
        _pp_cfg="$_pp_raw"
    else
        print -u2 "[!] ZDOTDIR '$ZDOTDIR' is not a directory, using \$HOME"
    fi
    unset _pp_raw
fi
readonly CFG_DIR="$_pp_cfg"
unset _pp_cfg

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly VERSION="1.0"
readonly ZSHRC="${CFG_DIR}/.zshrc"
readonly BACKUP_DIR="${CFG_DIR}/.zshrc_backups"
readonly MAX_BACKUPS=10

if [[ -z "${NO_COLOR:-}" && -t 1 && -t 2 ]]; then
    readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m'
    readonly B=$'\e[34m' M=$'\e[35m' C=$'\e[36m' N=$'\e[0m'
else
    readonly R='' G='' Y='' B='' M='' C='' N=''
fi

# ============================================================================
# STYLES — Format: CODE§NAME§PREVIEW
# ============================================================================

readonly -a STYLES=(
    'PROMPT="%~ %# "§Full Path§~/code %'
    'PROMPT="%1~ %# "§Dir Only§code %'
    'PROMPT="%# "§Minimal§%'
    'PROMPT="-> "§Arrow§->'
    'PROMPT="%F{cyan}%~%f %# "§Cyan§~/code %'
    'PROMPT="%B%F{red}>>%f%b %1~ "§Bold Red§>> code'
    'PROMPT="%F{green}%n%f@%F{blue}%m%f:%~ %# "§Classic§user@host:~ %'
    'PROMPT="%F{yellow}%T%f %1~ %# "§Timed§14:30 code %'
)
readonly NUM_STYLES=${#STYLES[@]}

(( NUM_STYLES > 0 )) || { print -u2 "FATAL: No styles defined"; exit 1; }

# ============================================================================
# OUTPUT FUNCTIONS
# ============================================================================

_die()  { print -ru2 -- "${R}[X]${N} $*"; exit 1; }
_warn() { print -ru2 -- "${Y}[!]${N} $*"; }
_ok()   { print -r   -- "${G}[+]${N} $*"; }
_info() { print -r   -- "${B}[>]${N} $*"; }

_hint() { _info "Activate: ${Y}exec zsh${N} or ${Y}source $(_pretty "$ZSHRC")${N}"; }

# ============================================================================
# CLEANUP
# ============================================================================

_cleanup() {
    [[ -n "$_PP_TEMP_FILE" ]] && command rm -f -- "$_PP_TEMP_FILE" 2>/dev/null
    return 0
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

_pretty() {
    local p="${1%/}" h="${HOME%/}"
    [[ -z "$h" ]] && { print -r -- "$p"; return; }
    [[ "$p" == "$h" ]] && { print -r -- "~"; return; }
    [[ "$p" == "$h/"* ]] && { print -r -- "~${p#"$h"}"; return; }
    print -r -- "$p"
}

_readlink_safe() {
    command -v readlink >/dev/null 2>&1 && \
        command readlink -- "$1" 2>/dev/null || print -r -- "?"
}

_target() {
    if [[ -L "$ZSHRC" && ! -e "$ZSHRC" ]]; then
        _die "Broken symlink: '$ZSHRC' -> '$(_readlink_safe "$ZSHRC")'"
    fi
    # ${:A} resolves symlinks to absolute path (zsh 5.0+)
    local r="${ZSHRC:A}"
    [[ -z "$r" ]] && r="$ZSHRC"
    if [[ -e "$r" ]]; then
        [[ -d "$r" ]] && _die "'$r' is a directory, expected file"
        [[ ! -f "$r" ]] && _die "'$r' is not a regular file (FIFO/socket/device?)"
    fi
    print -r -- "$r"
}

_parse() {
    local n="$1"
    [[ "$n" == [rR] ]] && n=$(( RANDOM % NUM_STYLES + 1 ))
    (( ${#n} > 9 )) && return 1
    [[ "$n" =~ ^[0-9]+$ ]] || return 1
    (( n >= 1 && n <= NUM_STYLES )) || return 1
    # Split style on § separator: reply[1]=CODE, reply[2]=NAME, reply[3]=PREVIEW
    reply=("${(@s:§:)STYLES[n]}" "$n")
    (( ${#reply[@]} == 4 ))
}

_backups() {
    reply=()
    [[ -d "$BACKUP_DIR" && -r "$BACKUP_DIR" ]] || return 0
    reply=("$BACKUP_DIR"/zshrc_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]_<1->(NOm))
    return 0
}

_same() {
    [[ -f "$1" && -f "$2" ]] && command diff -q -- "$1" "$2" >/dev/null 2>&1
}

_has_special() {
    [[ -f "$1" && -r "$1" ]] || return 1
    LC_ALL=C command grep -E \
        '^(export[[:space:]]+PROMPT=|[[:space:]]+PROMPT=)' "$1" >/dev/null 2>&1
}

_match_style() {
    local cur="$1" i; local -a p
    for i in {1..${NUM_STYLES}}; do
        p=("${(@s:§:)STYLES[i]}")
        (( ${#p[@]} == 3 )) && [[ "$cur" == "${p[1]}" ]] && \
            { print -r -- "${p[2]}"; return; }
    done
}

_safe_cp() {
    command cp -p -- "$1" "$2" 2>/dev/null || command cp -- "$1" "$2"
}

_get_prompt_info() {
    local f="$1"; reply=("" "0")
    [[ -f "$f" && -r "$f" ]] || return 1
    local out
    out=$(LC_ALL=C command grep -- '^PROMPT=' "$f" 2>/dev/null) || return 0
    [[ -z "$out" ]] && return 0
    local -a lines=("${(@f)out}")
    reply[1]="${lines[-1]}"   # Last PROMPT= line (the one that takes effect)
    reply[2]="${#lines[@]}"   # Total count (for warning if >1)
    return 0
}

# ============================================================================
# BACKUP SYSTEM
# ============================================================================

_backup() {
    local target="$1" quiet="${2:-}"
    [[ -s "$target" ]] || return 0

    if [[ -L "$BACKUP_DIR" && ! -e "$BACKUP_DIR" ]]; then
        _die "Broken symlink: '$BACKUP_DIR' -> '$(_readlink_safe "$BACKUP_DIR")'"
    fi

    [[ -e "$BACKUP_DIR" && ! -d "$BACKUP_DIR" ]] && \
        _die "'$BACKUP_DIR' exists but is not a directory"

    if [[ -d "$BACKUP_DIR" ]]; then
        [[ -w "$BACKUP_DIR" && -x "$BACKUP_DIR" ]] || \
            _die "Cannot write to backup directory '$BACKUP_DIR'"
    else
        command mkdir -p -- "$BACKUP_DIR" || _die "Cannot create '$BACKUP_DIR'"
    fi

    _backups; local -a existing=("${reply[@]}")
    if (( ${#existing[@]} )) && _same "$target" "${existing[1]}"; then
        [[ -z "$quiet" ]] && _info "Backup skipped (unchanged from latest)"
        return 0
    fi

    local bak="${BACKUP_DIR}/zshrc_$(LC_ALL=C command date +%Y%m%d_%H%M%S)_$$"

    _safe_cp "$target" "$bak" || _die "Backup failed: '$target' -> '$bak'"
    [[ -z "$quiet" ]] && _ok "Backup: ${bak:t}"

    _backups; local -a old=("${reply[@]:$MAX_BACKUPS}")
    (( ${#old[@]} )) && command rm -f -- "${old[@]}" 2>/dev/null || true
    return 0
}

_restore() {
    [[ -d "$BACKUP_DIR" ]] || _die "No backup directory: '$BACKUP_DIR'"
    _backups
    (( ${#reply[@]} )) || _die "No backups found in '$BACKUP_DIR'"
    local -a bks=("${reply[@]}")

    local target; target=$(_target) || exit 1
    [[ -f "$target" ]] && _backup "$target" quiet

    print
    _info "Restoring: ${Y}${bks[1]:t}${N}"
    _safe_cp "${bks[1]}" "$target" || _die "Restore failed: '${bks[1]:t}' -> '$target'"
    _ok "Restored successfully"
    print; _hint; print
}

_list() {
    _backups; local -a bks=("${reply[@]}")
    print
    if (( ${#bks[@]} == 0 )); then
        [[ -d "$BACKUP_DIR" ]] \
            && _warn "No backups yet in $(_pretty "$BACKUP_DIR")" \
            || _warn "No backup directory (will be created on first change)"
    else
        print -r -- "${B}Backups in${N} $(_pretty "$BACKUP_DIR")${B}:${N}"
        print
        local f; for f in "${bks[@]}"; do print -r -- "  ${f:t}"; done
        print
        _info "${#bks[@]}/${MAX_BACKUPS} slots used"
    fi
    print
}

# ============================================================================
# CORE FUNCTIONS
# ============================================================================

_status() {
    if [[ -L "$ZSHRC" && ! -e "$ZSHRC" ]]; then
        _warn "Broken symlink: '$ZSHRC' -> '$(_readlink_safe "$ZSHRC")'"
        _backups
        print -r -- "  ${B}Backups:${N} ${C}${#reply[@]}/${MAX_BACKUPS}${N}"
        return
    fi

    local target="${ZSHRC:A}"; [[ -z "$target" ]] && target="$ZSHRC"

    if [[ ! -f "$target" ]]; then
        print -r -- "  ${B}File:${N}    $(_pretty "$ZSHRC") ${Y}(will be created)${N}"
        _backups
        print -r -- "  ${B}Backups:${N} ${C}${#reply[@]}/${MAX_BACKUPS}${N}"
        return
    fi

    # Show symlink chain if ZSHRC is a symlink
    [[ "$ZSHRC" != "$target" ]] \
        && print -r -- "  ${B}File:${N}    $(_pretty "$ZSHRC") -> $(_pretty "$target")" \
        || print -r -- "  ${B}File:${N}    $(_pretty "$target")"

    # Show ZDOTDIR only if it differs from default ($HOME)
    [[ -n "${ZDOTDIR:-}" && "${ZDOTDIR%/}" != "${HOME%/}" ]] && \
        print -r -- "  ${B}ZDOTDIR:${N} ${C}$ZDOTDIR${N}"

    _get_prompt_info "$target" || true
    local cur="${reply[1]}" cnt="${reply[2]}"

    if [[ -n "$cur" ]]; then
        local name; name=$(_match_style "$cur")
        [[ -n "$name" ]] \
            && print -r -- "  ${B}Prompt:${N}  ${Y}${cur}${N}  ${C}[${name}]${N}" \
            || print -r -- "  ${B}Prompt:${N}  ${Y}${cur}${N}  ${M}[custom]${N}"
        (( cnt > 1 )) && _warn "${cnt} PROMPT= lines found (last one wins)"
    else
        print -r -- "  ${B}Prompt:${N}  ${Y}(zsh default)${N}"
    fi

    _backups
    print -r -- "  ${B}Backups:${N} ${C}${#reply[@]}/${MAX_BACKUPS}${N}"

    _has_special "$target" && \
        _warn "Found 'export PROMPT=' or indented PROMPT= (won't modify these)"
}

_apply() {
    local input="$1"

    if [[ -z "$input" ]]; then
        _styles >&2
        _die "Style number required (1-${NUM_STYLES} or 'r' for random)"
    fi

    local is_random=""; [[ "$input" == [rR] ]] && is_random=1

    if ! _parse "$input"; then
        _styles >&2
        _die "Invalid style: '$input' (expected 1-${NUM_STYLES} or 'r')"
    fi
    local code="${reply[1]}" name="${reply[2]}" preview="${reply[3]}" num="${reply[4]}"

    local target; target=$(_target) || exit 1

    if [[ -e "$target" ]]; then
        [[ -w "$target" ]] || _die "Cannot write to '$target' (permission denied)"
    else
        local parent="${target:h}"
        [[ -d "$parent" && -w "$parent" ]] || _die "Cannot create '$target' (parent not writable)"
        command -v touch >/dev/null 2>&1 && command touch -- "$target" 2>/dev/null || true
    fi

    _backup "$target"
    _get_prompt_info "$target" || true
    local count="${reply[2]}"

    if (( count > 0 )); then
        local safe="${code//\\/\\\\}"; safe="${safe//&/\\&}"

        local perms=""
        command -v stat >/dev/null 2>&1 && {
            # Try GNU stat format first (-c), then BSD format (-f)
            perms=$(command stat -c '%a' "$target" 2>/dev/null) || \
            perms=$(command stat -f '%Lp' "$target" 2>/dev/null) || true
        }

        local tmp="${target}.prompt-punk.$$"
        [[ -e "$tmp" || -L "$tmp" ]] && _die "Stale temp file exists: '$tmp' — please remove it"
        _PP_TEMP_FILE="$tmp"

        LC_ALL=C command sed $'s\x01^PROMPT=.*\x01'"${safe}"$'\x01' \
            -- "$target" > "$tmp" || { _cleanup; _die "sed failed on '$target'"; }

        [[ -s "$target" && ! -s "$tmp" ]] && \
            { _cleanup; _die "Write failed (disk full? check available space)"; }

        command mv -f -- "$tmp" "$target" || \
            { _cleanup; _die "Cannot replace '$target' (filesystem issue?)"; }
        _PP_TEMP_FILE=""

        [[ -n "$perms" ]] && command -v chmod >/dev/null 2>&1 && \
            command chmod "$perms" "$target" 2>/dev/null || true

        (( count > 1 )) \
            && _ok "Prompt updated (replaced ${count} PROMPT= lines)" \
            || _ok "Prompt updated"
    else
        local stamp="# PROMPT-PUNK v${VERSION} [$(LC_ALL=C command date +%F)]"
        print -r -- $'\n'"${stamp}"$'\n'"${code}" >> "$target" || \
            _die "Write failed on '$target'"
        _ok "Prompt added to $(_pretty "$target")"
    fi

    print
    print -r -- "${G}================================================${N}"
    [[ -n "$is_random" ]] && print -r -- "  ${B}Random:${N}  ${M}#${num} of ${NUM_STYLES}${N}"
    print -r -- "  ${B}Style:${N}   ${C}${name}${N}"
    print -r -- "  ${B}Preview:${N} ${Y}${preview}${N}"
    print -r -- "${G}================================================${N}"
    print; _hint; print
}

# ============================================================================
# USER INTERFACE
# ============================================================================

_styles() {
    local i; local -a p
    for i in {1..${NUM_STYLES}}; do
        p=("${(@s:§:)STYLES[i]}")
        (( ${#p[@]} == 3 )) && \
            printf "  %s%d)%s %-11s %s%s%s\n" "$C" "$i" "$N" "${p[2]}" "$Y" "${p[3]}" "$N"
    done
}

_help() {
    cat <<EOF

  ${M}██████╗ ██████╗  ██████╗ ███╗   ███╗██████╗ ████████╗${N}
  ${M}██╔══██╗██╔══██╗██╔═══██╗████╗ ████║██╔══██╗╚══██╔══╝${N}
  ${M}██████╔╝██████╔╝██║   ██║██╔████╔██║██████╔╝   ██║   ${N}
  ${M}██╔═══╝ ██╔══██╗██║   ██║██║╚██╔╝██║██╔═══╝    ██║   ${N}
  ${M}██║     ██║  ██║╚██████╔╝██║ ╚═╝ ██║██║        ██║   ${N}
  ${M}╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝        ╚═╝   ${N}
                  ${B}PUNK EDITION${N} v${VERSION}

  ${C}Screw boring prompts. Make it yours.${N}

  ${B}USAGE${N}
    ${C}prompt-punk${N}              Interactive style picker
    ${C}prompt-punk -s N${N}         Set style 1-${NUM_STYLES}
    ${C}prompt-punk -s r${N}         Random style
    ${C}prompt-punk -c${N}           Show current config
    ${C}prompt-punk -l${N}           List backups
    ${C}prompt-punk -r${N}           Restore last backup
    ${C}prompt-punk -h${N} / ${C}-v${N}      Help / Version

  ${B}STYLES${N}
EOF
    _styles
    print
}

_interactive() {
    [[ -r /dev/tty && -w /dev/tty ]] || _die "No terminal available — use: prompt-punk -s N"

    {
        print
        print -r -- "${M}+================================================+${N}"
        print -r -- "${M}|${N}                ${B}PROMPT-PUNK${N} v${VERSION}                ${M}|${N}"
        print -r -- "${M}+================================================+${N}"
        print
        _status
        print
        print -r -- "${B}Pick your poison:${N}"
        print
        _styles
        print
        print -rn -- "[1-${NUM_STYLES}], ${C}r${N}andom, ${C}q${N}uit: "
    } >&2

    local choice
    read -r choice </dev/tty 2>/dev/null || { print -ru2 ""; print -ru2 "Aborted."; exit 0; }
    [[ -z "$choice" || "$choice" == [qQ] ]] && { print -ru2 "Aborted."; exit 0; }

    _apply "$choice"
}

# ============================================================================
# MAIN
# ============================================================================

trap '_cleanup; print -u2 "${N}"; _warn "Interrupted."; exit 130' INT
trap '_cleanup; print -u2 "${N}"; _warn "Terminated."; exit 143' TERM HUP

main() {
    case "${1:-}" in
        "")           _interactive ;;
        -s|--style)   _apply "${2:-}" ;;
        -c|--current) print; _status; print ;;
        -l|--list)    _list ;;
        -r|--restore) _restore ;;
        -v|--version) print "PROMPT-PUNK v${VERSION}" ;;
        -h|--help)    _help ;;
        --)           shift; [[ $# -eq 0 ]] && _interactive || _die "Unknown: '$1'" ;;
        -*)           _die "Unknown option: '$1' (try -h)" ;;
        *)            _die "Unknown: '$1' (try -h)" ;;
    esac
}

main "$@"
