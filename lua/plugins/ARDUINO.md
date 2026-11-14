# Arduino + Neovim setup

Neovim as the Arduino editor: LSP, build/upload, serial monitor. Default board: UNO R4 WiFi.
Arduino IDE is **not** required. Tested on macOS (Apple Silicon); Linux steps are untested.

Every step is idempotent and has a check. Run them in order; stop and fix if a check fails.

## Prerequisites

- This config at `~/.config/nvim`, Neovim >= 0.12, `curl`, `tar`.
- `DATA` = arduino-cli data dir: macOS `~/Library/Arduino15`, Linux `~/.arduino15`.

## 1. arduino-cli

```sh
# macOS
brew install arduino-cli
# Linux (ensure ~/.local/bin is on PATH)
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | BINDIR=~/.local/bin sh
```

Check: `arduino-cli version`

## 2. Config and board core

```sh
[ -f "$DATA/arduino-cli.yaml" ] || arduino-cli config init
arduino-cli core update-index
arduino-cli core install arduino:renesas_uno
```

Check: `arduino-cli core list` lists `arduino:renesas_uno`.

## 3. Standard libraries (Servo, LiquidCrystal, Stepper, ...)

```sh
arduino-cli lib install Arduino_BuiltIn
```

Check: `arduino-cli lib list` lists `Servo`.
Exception: if Arduino IDE 2 already installed them into `$DATA/libraries`, skip the install and run
`arduino-cli config set directories.builtin.libraries "$DATA/libraries"` instead.

## 4. clangd 14 (Arduino language server only)

arduino-language-server 0.7.7 crashes with new clangd (Mason's 23.x). clangd 14 (Arduino's build) and Apple clangd 17 work.
Install it outside PATH; regular C/C++ keeps using Mason's clangd.

| OS / arch | `ASSET` |
|---|---|
| macOS arm64 | `macOS_ARM64` |
| macOS x86_64 | `macOS_64bit` |
| Linux x86_64 | `Linux_64bit` |
| Linux aarch64 | `Linux_ARM64` |

```sh
mkdir -p ~/.local/share/nvim/arduino-clangd
curl -fsSL "https://downloads.arduino.cc/tools/clangd_14.0.0_${ASSET}.tar.bz2" \
  | tar -xjf - -C ~/.local/share/nvim/arduino-clangd --strip-components=1
```

Check: `~/.local/share/nvim/arduino-clangd/clangd --version` prints `clangd version 14.0.0`.

## 5. Language server

```sh
nvim --headless "+MasonInstall arduino-language-server" +qa
```

Check: `~/.local/share/nvim/mason/bin/arduino-language-server -h` prints usage.

## 6. Serial access (Linux only)

```sh
sudo usermod -aG dialout "$USER"   # Arch: uucp. Log out and back in.
```

If upload still fails with a permission error: `sudo "$DATA"/packages/arduino/hardware/renesas_uno/*/post_install.sh`

## 7. Verify

```sh
mkdir -p /tmp/ardtest && cd /tmp/ardtest
[ -f ardtest/ardtest.ino ] || arduino-cli sketch new ardtest
arduino-cli compile -b arduino:renesas_uno:unor4wifi ardtest     # expect "Sketch uses ..."
arduino-cli board list                                           # board plugged in: expect arduino:renesas_uno:unor4wifi
nvim --headless ardtest/ardtest.ino \
  "+lua vim.defer_fn(function() local c = vim.lsp.get_clients({ bufnr = 0 })[1]; io.stdout:write((c and c.name or 'NO LSP') .. '\n'); vim.cmd('qa!') end, 30000)"
# expect: arduino_language_server  (first launch may be slow: plugins/parsers install; rerun if NO LSP)
```

## Usage

Sketch layout: `<name>/<name>.ino` (`arduino-cli sketch new <name>`). Keys in `.ino` buffers:

| Key | Action |
|---|---|
| `<Leader>ab` | Build in background; errors -> quickfix (`]q`) + log |
| `<Leader>au` | Build + upload; port auto-detected; monitor paused and reopened |
| `<Leader>am` | Toggle serial monitor (right split, no focus) |
| `<Leader>al` | Toggle last build log |

Settings:
- Other board: `default_fqbn: <fqbn>` in `<sketch>/sketch.yaml` (`arduino-cli board listall` for FQBNs).
- Baud: `vim.g.arduino_baud` (default 9600).
- clangd override: `vim.g.arduino_clangd = "/path/to/clangd"`.

## How it fits together

- `lua/plugins/arduino.lua`: LSP config, keymaps, monitor, compile DB for board-package sources.
- `bin/arduino-clangd`: clangd wrapper; keeps clangd's index in `~/.cache/arduino-clangd` (startup indexing ~25s -> <1s).
- Go-to-definition into core files uses the regular clangd with a generated compile DB
  (`~/.cache/nvim/arduino-cdb/`, symlinked into the board package dir). Those files open read-only.
- Stale index or odd diagnostics: `rm -rf ~/.cache/arduino-clangd ~/.cache/nvim/arduino-cdb`, restart Neovim.
