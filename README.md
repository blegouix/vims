# vims

`vims` is a Bash wrapper around Vim that targets a **single Vim server**.

- First call: starts Vim with a fixed `--servername`.
- Next calls: forward arguments to that same instance using Vim remote mode.

This is useful when you want many shell invocations (`vims file1`, `vims -O file2 file3`, …) to reuse one persistent Vim UI/session.

## Requirements

- Vim compiled with `+clientserver` (ie., `vim-gtk3` for Ubuntu).
- A terminal/GUI environment where your Vim build supports `--serverlist` and `--remote*`.

Quick check:

```bash
vim --version | grep clientserver
```

You should see `+clientserver`. If your default `vim` still does not report `+clientserver`, call the wrapper with a specific Vim binary:

```bash
VIMS_VIM=/usr/bin/vim.gtk3 vims README.md
```

## Installation

Install directly to `/usr/local/bin` with `wget`

```bash
sudo wget -O /usr/local/bin/vims https://raw.githubusercontent.com/blegouix/vims/main/vims_
sudo wget -O /usr/local/bin/vims https://raw.githubusercontent.com/blegouix/vims/main/vims
sudo chmod 0755 /usr/local/bin/vims_
sudo chmod 0755 /usr/local/bin/vims 
```

Or copy-paste directly the content of the files in your `~/.bashrc`.

## Usage

```bash
vims file1.txt
vims -O file2.txt file3.txt
```

By default the server name is `VIMS`. Override it:

```bash
VIMS_SERVER=HELLO_WORLD vims hello_world.cpp
```

Use a different Vim executable:

```bash
VIMS_VIM=vim.gtk3 vims
```
