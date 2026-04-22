# Source this file from ~/.bashrc to define `vims`.
# Optional env vars:
#   VIMS_SERVER  (default: VIMS)
#   VIMS_VIM     (default: vim)
#   VIMS_JOB_ID  (set by vims when it backgrounds a vim process)

vims() {
  local server_name vim_bin base status line jobspec
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

  base="${vim_bin##*/}"
  VIMS_CMD=("$vim_bin")
  VIMS_GUI=0

  if [[ "$base" == gvim* ]]; then
    VIMS_GUI=1
  fi

  if "${VIMS_CMD[@]}" --serverlist 2>/dev/null | tr ' ' '\n' | grep -Fxq "$server_name"; then
    if (($# > 0)); then
      "${VIMS_CMD[@]}" --servername "$server_name" --remote-tab-silent "$@" || return $?
      if ((VIMS_GUI)); then
        "${VIMS_CMD[@]}" --servername "$server_name" --remote-send "<C-\\><C-N>:silent! call foreground()<CR>" >/dev/null 2>&1
      elif [[ -n "${VIMS_JOB_ID:-}" ]]; then
        while IFS= read -r line; do
          if [[ "$line" =~ ^\[([0-9]+)\][+-]?[[:space:]]+([0-9]+)[[:space:]] ]] && [[ "${BASH_REMATCH[2]}" == "$VIMS_JOB_ID" ]]; then
            jobspec="${BASH_REMATCH[1]}"
            fg "%${jobspec}" >/dev/null
            break
          fi
        done < <(jobs -l 2>/dev/null)
      fi
      return 0
    fi

    if ((VIMS_GUI)); then
      "${VIMS_CMD[@]}" --servername "$server_name" --remote-send "<C-\\><C-N>:silent! call foreground()<CR>" >/dev/null 2>&1
    elif [[ -n "${VIMS_JOB_ID:-}" ]]; then
      while IFS= read -r line; do
        if [[ "$line" =~ ^\[([0-9]+)\][+-]?[[:space:]]+([0-9]+)[[:space:]] ]] && [[ "${BASH_REMATCH[2]}" == "$VIMS_JOB_ID" ]]; then
          jobspec="${BASH_REMATCH[1]}"
          fg "%${jobspec}" >/dev/null
          break
        fi
      done < <(jobs -l 2>/dev/null)
    fi
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
  status=$?

  if (( status == 0 )) && [[ -n "${VIMS_JOB_ID:-}" ]]; then
    while IFS= read -r line; do
      if [[ "$line" =~ ^\[([0-9]+)\][+-]?[[:space:]]+([0-9]+)[[:space:]] ]] && [[ "${BASH_REMATCH[2]}" == "$VIMS_JOB_ID" ]]; then
        jobspec="${BASH_REMATCH[1]}"
        fg "%${jobspec}" >/dev/null
        break
      fi
    done < <(jobs -l 2>/dev/null)
  fi

  return "$status"
}
