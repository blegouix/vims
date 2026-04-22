# vims

`vims` is a Bash function around Vim that targets a **single Vim server**.

- First call: starts Vim with a fixed `--servername` in the foreground for terminal Vim.
- Next calls: open files in tabs in that same instance and bring it back to the foreground when this shell owns it.

This is useful when you want many shell invocations (`vims`, `vims file1`, `vims -O file2 file3`, …) to reuse one persistent Vim UI/session.

There is a special treatment of `-o`, `-O` and `-p` flags to convert them into remote `vim` commands.

## Requirements

- Vim compiled with `+clientserver` (ie., `vim-gtk3` or `gvim` for Ubuntu).
- A terminal/GUI environment where your Vim build supports `--serverlist` and `--remote*`.

Quick check:

```bash
vim --version | grep clientserver
```

You should see `+clientserver`.

## Installation

Install `vims.bash`, then source it from your `~/.bashrc`.

```bash
mkdir -p "$HOME/.local/share/vims"
wget -O "$HOME/.local/share/vims/vims.bash" https://raw.githubusercontent.com/blegouix/vims/main/vims.bash
echo 'source "$HOME/.local/share/vims/vims.bash"' >> "$HOME/.bashrc"
```

Then reload your shell:

```bash
source ~/.bashrc
```

## Usage

```bash
vims
<Ctrl-Z>
vims file1
<Ctrl-Z>
vims -O file2 file3
<Ctrl-Z>
vims
gt
gT
gt
gt
```

By default the server name is `VIMS`. Override it:

```bash
VIMS_SERVER=HELLO_WORLD vims hello_world.cpp
```

Use a different Vim executable:

```bash
export VIMS_VIM=gvim
```
