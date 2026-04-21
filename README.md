# vims

`vims` is a Bash wrapper around Vim that targets a **single Vim server**.

- First call: starts Vim with a fixed `--servername`.
- Next calls: bring that instance to foreground (best effort) and forward arguments using Vim remote mode.

This is useful when you want many shell invocations (`vims file1`, `vims file2`, …) to reuse one persistent Vim UI/session.

## Requirements

- Vim compiled with `+clientserver`.
- A terminal/GUI environment where your Vim build supports `--serverlist` and `--remote*`.

Quick check:

```bash
vim --version | grep clientserver
```

You should see `+clientserver` (not `-clientserver`).

## Ubuntu: getting Vim with `+clientserver`

On Ubuntu, minimal terminal Vim builds may not include clientserver. A reliable option is usually a GTK Vim package.

```bash
sudo apt update
sudo apt install vim-gtk3
```

Then verify:

```bash
vim --version | grep clientserver
```

If your default `vim` still does not report `+clientserver`, call the wrapper with a specific Vim binary:

```bash
VIMS_VIM=/usr/bin/vim.gtk3 vims README.md
```

## Installation

### Option 1: install directly to `/usr/local/bin` with `wget`

```bash
sudo wget -O /usr/local/bin/vims https://raw.githubusercontent.com/<OWNER>/<REPO>/<BRANCH>/vims
sudo chmod 0755 /usr/local/bin/vims
```

After this, `vims` should be available from anywhere.

### Option 2: copy/paste into your `~/.bashrc`

If you prefer not to install a standalone file, add this function to `~/.bashrc`:

```bash
vims() {
  local server_name="${VIMS_SERVER:-VIMS}"
  local vim_bin="${VIMS_VIM:-vim}"

  command -v "$vim_bin" >/dev/null 2>&1 || {
    echo "vims: '$vim_bin' was not found in PATH" >&2
    return 127
  }

  "$vim_bin" --version 2>/dev/null | grep -Eq '^\+clientserver\b' || {
    echo "vims: $vim_bin does not have +clientserver" >&2
    return 2
  }

  if "$vim_bin" --serverlist 2>/dev/null | tr ' ' '\n' | grep -Fxq "$server_name"; then
    "$vim_bin" --servername "$server_name" --remote-expr 'foreground()' >/dev/null 2>&1 || true
    if [ "$#" -eq 0 ]; then
      return 0
    fi
    "$vim_bin" --servername "$server_name" --remote-silent "$@"
  else
    "$vim_bin" --servername "$server_name" "$@"
  fi
}
```

Then reload your shell:

```bash
source ~/.bashrc
```

## Usage

```bash
vims file1.txt
vims src/main.c
vims +123 README.md
```

By default the server name is `VIMS`. Override it:

```bash
VIMS_SERVER=WORK vims app.py
```

Use a different Vim executable:

```bash
VIMS_VIM=vim.gtk3 vims notes.md
```

## Notes on compatibility

When a server already exists, `vims` first calls Vim's `foreground()` function (best effort) so the existing instance is focused, then forwards arguments with `vim --remote-silent`. Exact focus behavior still depends on your terminal/window manager/Vim build.
