# Source this file from ~/.bashrc to define `vims`.
# Optional env vars:
#   VIMS_SERVER  (default: VIMS)
#   VIMS_VIM     (default: vim)
#   VIMS_JOB_ID  (set by vims when it backgrounds a vim process)

_vims_prepare_cmd() {
  local base
  base="${1##*/}"

  VIMS_CMD=("$1")
  VIMS_GUI=0

  if [[ "$base" == gvim* ]]; then
    VIMS_GUI=1
  fi
}

_vims_fg_by_pid() {
  local pid line jobspec
  pid="${1:-}"
  [[ -n "$pid" ]] || return 1

  # Parse `jobs -l` and bring matching job to foreground.
  while IFS= read -r line; do
    if [[ "$line" =~ ^\[([0-9]+)\][+-]?[[:space:]]+([0-9]+)[[:space:]] ]]; then
      jobspec="${BASH_REMATCH[1]}"
      if [[ "${BASH_REMATCH[2]}" == "$pid" ]]; then
        fg "%${jobspec}" >/dev/null
        return 0
      fi
    fi
  done < <(jobs -l 2>/dev/null)

  return 1
}

_vims_focus_existing() {
  if ((VIMS_GUI)); then
    "${VIMS_CMD[@]}" --servername "${VIMS_SERVER:-VIMS}" --remote-send "<C-\\><C-N>:silent! call foreground()<CR>" >/dev/null 2>&1
  fi
}

vims_() {
  local server_name vim_bin
  local -a launch_cmd
  server_name="${VIMS_SERVER:-VIMS}"
  vim_bin="${VIMS_VIM:-vim}"

  if ! command -v "$vim_bin" >/dev/null 2>&1; then
    echo "vims: '$vim_bin' was not found in PATH" >&2
    return 127
  fi

  if ! "$vim_bin" --version 2>/dev/null | grep -Eq '^\+clientserver\b'; then
    cat >&2 <<MSG
vims: $vim_bin does not have +clientserver.
Install a Vim build with +clientserver support.
MSG
    return 2
  fi

  _vims_prepare_cmd "$vim_bin"

  if "${VIMS_CMD[@]}" --serverlist 2>/dev/null | tr ' ' '\n' | grep -Fxq "$server_name"; then
    if (($# > 0)); then
      "${VIMS_CMD[@]}" --servername "$server_name" --remote-tab-silent "$@" || return $?
      _vims_focus_existing
      return 0
    fi

    _vims_focus_existing
    return 0
  fi

  launch_cmd=("${VIMS_CMD[@]}")
  if ((VIMS_GUI)); then
    launch_cmd+=(-f)
    "${launch_cmd[@]}" --servername "$server_name" "$@" &
    VIMS_JOB_ID="$!"
    export VIMS_JOB_ID
    return 0
  fi

  "${launch_cmd[@]}" --servername "$server_name" "$@" &
  VIMS_JOB_ID="$!"
  export VIMS_JOB_ID
}

vims() {
  local status
  vims_ "$@"
  status=$?

  if (( status == 0 && ! VIMS_GUI )); then
    _vims_fg_by_pid "${VIMS_JOB_ID:-}" || true
  fi

  return "$status"
}
