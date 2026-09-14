# tiler

**AeroSpace** config for pmac: only the rightmost monitor tiles.
Center and left (laptop) screens stay floating/native macOS behavior.

Switched from yabai → [AeroSpace](https://github.com/nikitabobko/AeroSpace)
(open-source, actively maintained, i3-like) after two real problems with
yabai on macOS 26 / yabai 7.1.25 that turned out to be unfixable at the
config level — see "Why we moved off yabai" below.

## Layout mapping

| AeroSpace monitor-id | physical position | workspace | tiling |
|---|---|---|---|
| 1 | left (MacBook built-in) | `L` | float |
| 2 | center (primary external) | `C` | float |
| 3 | **right (secondary external)** | **`T`** | **accordion (tiled)** |

Confirmed via `cliclick` mouse-move + `aerospace list-monitors --focused`,
cross-checked against `displayplacer list` (contextual screen id 3, origin
`(1920,0)`). Both external monitors share the same model name
(`LS24DG30X`), so monitor **id** is used, not name, to avoid ambiguity.

## Why `accordion`, not `tiles`

`tiles` (the classic BSP-style grid) halves available space for every new
window with no floor. Confirmed on this exact setup: **9 real windows on a
1920×1080 screen shrank to ~500px-wide slivers** — the same "cutting off
major parts of the application" problem the original yabai BSP setup had.

`accordion` keeps **every** window near full monitor size (an offset stack
of full-height windows, only the focused one fully on top, others peek at
the edge) — cycle through them with `alt-tab` / focus keys instead of
seeing them all shrunk simultaneously. Verified: 9-window accordion layout
put every window at ~1844×1033 on the 1920×1080 screen (vs ~500×1033 under
tiles).

## Why we moved off yabai

1. **Blanket `manage=on/off` rules with no `app`/`title` filter are
   silently rejected.** Tiling scope has to be controlled per-space
   (`yabai -m space N --layout bsp|float`), not via a catch-all rule —
   easy to get wrong, no error surfaced when it silently no-ops.
2. **`--toggle float` (twice) does not reliably force BSP re-insertion**
   on macOS 26 / yabai 7.1.25. Confirmed via `yabai -V` trace: the daemon
   message is sent and returns cleanly, but `split-type` stays `"none"`
   and the window frame never actually moves into the tree. `--focus`
   was the only command that reliably fixed it — an undocumented,
   fragile workaround.
3. yabai's own manual `--stack` command **also proved unreliable** in
   testing — caused overlapping/hidden windows rather than a clean stack.
4. yabai's full feature set needs a **SIP-disabled scripting addition**
   (`/Library/ScriptingAdditions`) that most users (including this
   machine) don't have installed; AeroSpace works fully through the
   public Accessibility API with SIP left on.

AeroSpace hit the *same* crushing problem under its `tiles` layout, but
unlike yabai it has a first-class `accordion` layout that's a one-line
config fix — no custom scripts, no signal handlers, no empirically-reverse-
engineered CLI workarounds.

## Files

- `aerospace.toml` — the config, loaded from `~/.config/aerospace/aerospace.toml`
- (legacy `.yabairc` / `.skhdrc` history remains in git log for reference;
  yabai/skhd launch agents have been renamed `*.disabled` on this machine,
  not deleted, in case of rollback)

## Apply changes

```bash
mkdir -p ~/.config/aerospace
cp aerospace.toml ~/.config/aerospace/aerospace.toml
aerospace reload-config
```

If AeroSpace isn't running: `open -a AeroSpace` (requires one-time
Accessibility permission grant in System Settings → Privacy & Security →
Accessibility — this is a hard macOS security boundary and cannot be
granted programmatically).

## Keybindings (workspace T = rightmost/tiled, C = center, L = left)

| Key | Action |
|---|---|
| `alt+h/j/k/l` | focus window left/down/up/right |
| `alt+shift+h/j/k/l` | move window |
| `alt+1/2/3` | switch to workspace T/C/L |
| `alt+shift+1/2/3` | move focused window to workspace T/C/L |
| `alt+t` | set focused window's container to tiles |
| `alt+,` | set focused window's container to accordion |
| `alt+f` | toggle floating/tiling |
| `alt+tab` | workspace back-and-forth |
| `cmd+alt+r` | reload config |

## No GUI (same as yabai)

AeroSpace is also CLI/config-file driven (`~/.config/aerospace/aerospace.toml`,
`aerospace <command>`). No settings app. If you want visual feedback,
AeroSpace ships a built-in menu-bar app indicator (unlike yabai, which
needs a third-party add-on like JankyBorders/SketchyBar for any UI at all).
