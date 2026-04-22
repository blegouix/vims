# vims

`vims` is a Bash function around Vim that targets a **single Vim server**.

- First call: starts Vim with a fixed `--servername`; terminal Vim is then brought to the foreground through shell job control.
- Next calls: open files in tabs in that same instance and bring it back to the foreground when this shell owns it.

This is useful when you want many shell invocations (`vims`, `vims file1`, `vims file2`, …) to reuse one persistent Vim UI/session.

## Requirements

- Vim compiled with `+clientserver` (ie., `vim-gtk3` for Ubuntu).
- A terminal/GUI environment where your Vim build supports `--serverlist` and `--remote*`.

Quick check:

```bash
vim --version | grep clientserver
```

You should see `+clientserver`. By default `vims` uses terminal `vim`. If you want GUI Vim, set `VIMS_VIM=gvim` explicitly:

```bash
VIMS_VIM=/usr/bin/gvim vims README.md
```

## Installation

Install `vims.bash` somewhere stable, then source it from your `~/.bashrc`.

```bash
mkdir -p "$HOME/.local/share/vims"
wget -O "$HOME/.local/share/vims/vims.bash" \
  https://raw.githubusercontent.com/blegouix/vims/main/vims.bash
echo 'source "$HOME/.local/share/vims/vims.bash"' >> "$HOME/.bashrc"
```

Then reload your shell:

```bash
source ~/.bashrc
```

If you prefer another location, keep the same idea: download `vims.bash` with `wget` and source that file from your `~/.bashrc`.

## Usage

```bash
vims
vims file1.txt
vims file2.txt
```

By default the server name is `VIMS`. Override it:

```bash
VIMS_SERVER=HELLO_WORLD vims hello_world.cpp
```

Use a different Vim executable:

```bash
VIMS_VIM=vim.gtk3 vims
VIMS_VIM=gvim vims
```

Run `vims` with no arguments to focus the existing Vim instance when possible.
Run `vims some_file` to open that file in a new tab in the existing instance.
For terminal Vim, foregrounding only works from the same interactive shell that started the job.
