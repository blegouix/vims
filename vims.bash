# Source this file from ~/.bashrc to define `vims`.
# Optional env vars:
#   VIMS_SERVER  (default: VIMS)
#   VIMS_VIM     (default: vim)
#   VIMS_JOB_ID  (set by vims when it backgrounds a vim process)

vims() {
  local server_name vim_bin base status line jobspec arg layout_mode layout_count
  local parsing_files unsupported_remote opened_count escaped keys layout_cmd
  local -a launch_cmd
  local -a remote_files
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
    status=0
    if (($# > 0)); then
      layout_mode=""
      layout_count=0
      parsing_files=0
      unsupported_remote=0
      remote_files=()

      for arg in "$@"; do
        if ((parsing_files)); then
          remote_files+=("$arg")
          continue
        fi

        case "$arg" in
          --)
            parsing_files=1
            ;;
          -p|-p[0-9]*)
            layout_mode="tab"
            layout_count="${arg#-p}"
            [[ -n "$layout_count" ]] || layout_count=0
            ;;
          -o|-o[0-9]*)
            layout_mode="split"
            layout_count="${arg#-o}"
            [[ -n "$layout_count" ]] || layout_count=0
            ;;
          -O|-O[0-9]*)
            layout_mode="vsplit"
            layout_count="${arg#-O}"
            [[ -n "$layout_count" ]] || layout_count=0
            ;;
          -*)
            unsupported_remote=1
            break
            ;;
          *)
            remote_files+=("$arg")
            ;;
        esac
      done

      if ((unsupported_remote)); then
        "${VIMS_CMD[@]}" --servername "$server_name" --remote-tab-silent "$@"
        status=$?
      elif [[ "$layout_mode" == "split" || "$layout_mode" == "vsplit" ]]; then
        layout_cmd="$layout_mode"
        keys="<C-\\><C-N>"
        if ((${#remote_files[@]} > 0)); then
          escaped="${remote_files[0]//\'/\'\'}"
          keys+=":execute 'silent tabedit ' . fnameescape('$escaped')<CR>"
        else
          keys+=":silent tabnew<CR>"
        fi

        opened_count=1
        for arg in "${remote_files[@]:1}"; do
          escaped="${arg//\'/\'\'}"
          keys+=":execute 'silent ${layout_cmd} ' . fnameescape('$escaped')<CR>"
          ((opened_count++))
        done

        while ((layout_count > opened_count)); do
          keys+=":silent ${layout_cmd}<CR>"
          ((opened_count++))
        done

        "${VIMS_CMD[@]}" --servername "$server_name" --remote-send "$keys" >/dev/null 2>&1
        status=$?
      else
        if ((${#remote_files[@]} > 0)); then
          "${VIMS_CMD[@]}" --servername "$server_name" --remote-tab-silent "${remote_files[@]}"
          status=$?
          opened_count=${#remote_files[@]}
        elif ((layout_count > 0)); then
          keys="<C-\\><C-N>:silent tabnew<CR>"
          opened_count=1
          while ((layout_count > opened_count)); do
            keys+=":silent tabnew<CR>"
            ((opened_count++))
          done
          "${VIMS_CMD[@]}" --servername "$server_name" --remote-send "$keys" >/dev/null 2>&1
          status=$?
        fi
      fi

      (( status == 0 )) || return "$status"
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
