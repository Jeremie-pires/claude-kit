#!/usr/bin/env bash
# Claude Code status line — compact multi-line block

input=$(cat)

# --- JSON parsing via Python (jq not available) ---
py_get() {
  python -c "
import json, sys
try:
  d = json.loads(sys.stdin.read())
  keys = '$1'.split('.')
  v = d
  for k in keys:
    if isinstance(v, dict): v = v.get(k)
    else: v = None
  print('' if v is None else v)
except: print('')
" <<< "$input"
}

# --- ANSI colors ($'...' = vrai escape byte) ---
R=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
C_SKY=$'\033[96m'
C_BLUE=$'\033[34m'
C_GREEN=$'\033[32m'
C_YELLOW=$'\033[33m'
C_ORANGE=$'\033[38;5;208m'
C_RED=$'\033[31m'
C_CYAN=$'\033[36m'
C_MAG=$'\033[35m'
C_WHITE=$'\033[37m'

WARN="⚠️ "

# --- Couleur selon palier — écrit dans PCT_COL ---
pct_color() {
  local p=$1
  if   [ "$p" -lt 20 ]; then PCT_COL=$C_SKY
  elif [ "$p" -lt 40 ]; then PCT_COL=$C_BLUE
  elif [ "$p" -lt 60 ]; then PCT_COL=$C_GREEN
  elif [ "$p" -lt 75 ]; then PCT_COL=$C_YELLOW
  elif [ "$p" -lt 80 ]; then PCT_COL=$C_ORANGE
  else                        PCT_COL=$C_RED
  fi
}

# --- Barre segmentée — écrit dans BAR_OUT ---
fill_bar() {
  local pct=$1 col=$2 width=12 i
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))
  BAR_OUT=""
  for ((i=0; i<filled; i++)); do BAR_OUT+="${col}▰${R}"; done
  for ((i=0; i<empty;  i++)); do BAR_OUT+="${DIM}▱${R}"; done
}

# --- Durée avant reset ---
format_duration() {
  local secs=$(( $1 - $(date +%s) ))
  [ "$secs" -le 0 ] && { printf "now"; return; }
  local h=$(( secs / 3600 )) m=$(( (secs % 3600) / 60 ))
  [ "$h" -gt 0 ] && printf "%dh %dm" "$h" "$m" || printf "%dm" "$m"
}

# --- Extraction ---
model=$(py_get "model.display_name")
[ -z "$model" ] && model="?"

project_dir=$(py_get "workspace.project_dir")
[ -z "$project_dir" ] && project_dir=$(py_get "workspace.current_dir")
[ -z "$project_dir" ] && project_dir=$(py_get "cwd")
[ -z "$project_dir" ] && project_dir="."
project=$(basename "$project_dir")

branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$project_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)

used_pct=$(py_get "context_window.used_percentage")
five_pct=$(py_get "rate_limits.five_hour.used_percentage")
five_reset=$(py_get "rate_limits.five_hour.resets_at")
week_pct=$(py_get "rate_limits.seven_day.used_percentage")
week_reset=$(py_get "rate_limits.seven_day.resets_at")

# ── Ligne 1 ──────────────────────────────────────────────────────────────────
printf "${C_CYAN}${BOLD}🤖 %s${R}" "$model"
printf "${DIM} │ ${R}${C_MAG}📁 %s${R}" "$project"
[ -n "$branch" ] && printf "${DIM} │ ${R}${C_WHITE}⎇  %s${R}" "$branch"
printf "\n"

# ── Ligne 2 : Contexte ───────────────────────────────────────────────────────
if [ -n "$used_pct" ]; then
  p=$(printf "%.0f" "$used_pct")
  pct_color "$p"; fill_bar "$p" "$PCT_COL"
  w=""; [ "$p" -ge 80 ] && w=" $WARN"
  printf "${C_CYAN}🧠 ctx ${R}%s ${PCT_COL}${BOLD}%d%%${R}%s\n" "$BAR_OUT" "$p" "$w"
else
  printf "${DIM}🧠 ctx  —${R}\n"
fi

# ── Ligne 3 : 5h ─────────────────────────────────────────────────────────────
if [ -n "$five_pct" ]; then
  p=$(printf "%.0f" "$five_pct")
  pct_color "$p"; fill_bar "$p" "$PCT_COL"
  w=""; [ "$p" -ge 80 ] && w=" $WARN"
  reset_in=""
  [ -n "$five_reset" ] && reset_in=" ${DIM}(reset $(format_duration "$five_reset"))${R}"
  printf "${C_YELLOW}⏱️  5h  ${R}%s ${PCT_COL}${BOLD}%d%%${R}%s%s\n" "$BAR_OUT" "$p" "$w" "$reset_in"
else
  printf "${DIM}⏱️  5h   —${R}\n"
fi

# ── Ligne 4 : 7j ─────────────────────────────────────────────────────────────
if [ -n "$week_pct" ]; then
  p=$(printf "%.0f" "$week_pct")
  pct_color "$p"; fill_bar "$p" "$PCT_COL"
  w=""; [ "$p" -ge 80 ] && w=" $WARN"
  reset_in=""
  [ -n "$week_reset" ] && reset_in=" ${DIM}(reset $(format_duration "$week_reset"))${R}"
  printf "${C_GREEN}📅 7j   ${R}%s ${PCT_COL}${BOLD}%d%%${R}%s%s\n" "$BAR_OUT" "$p" "$w" "$reset_in"
else
  printf "${DIM}📅 7j    —${R}\n"
fi
