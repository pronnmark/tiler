# tiler

yabai + skhd configuration for pmac: **only the rightmost monitor tiles**.
Center and left (laptop) screens stay floating/native macOS behavior.

## Layout mapping (yabai display index → physical position)

| yabai index | id | physical position | tiling |
|---|---|---|---|
| 1 | 5 | center (primary) | float |
| 3 | 1 | left (MacBook built-in) | float |
| 2 | 3 | **right (secondary external)** | **bsp (tiled)** |

## How it works

- `yabai -m space <N> --layout bsp|float` sets tiling per-space (not per-app —
  yabai rejects a blanket `manage=on/off` rule with no `app`/`title` filter).
- `scripts/handle-new-window.sh` runs on the `window_created` signal: every
  new window (except a small exception list of real utility apps) gets moved
  to display 2 and tiled.
- `scripts/handle-space-created.sh` runs on `space_created`: keeps any newly
  created Mission Control space correctly floating/tiling based on which
  display it lands on.
- `scripts/retile-all.sh` runs once at yabai startup to fix windows that
  existed *before* the config loaded (yabai can mark a window `manage=true`
  without actually inserting it into the BSP tree — `split-type` stays
  `"none"` and the frame never moves). Confirmed empirically that
  `--toggle float` twice does **not** reliably fix this on macOS 26 — only
  `--focus` reliably forces a proper BSP re-insert.

## Known quirks (macOS 26 + yabai 7.1.25)

- **`--toggle float` is unreliable** for forcing BSP re-insertion of windows
  that predate a rule/layout change. Use `--focus` instead (confirmed via
  `yabai -V` trace).
- **Don't use `subrole="^AXDialog$"` as a blanket float-exception rule.**
  Some full app main windows report `AXDialog` as their subrole (e.g.
  CloakBrowser Manager, Clearly) and would get wrongly excluded from tiling.
- yabai's scripting addition (`--load-sa`) is **not installed**
  (`/Library/ScriptingAdditions/` empty) and SIP is fully enabled. This
  limits some features (sticky, pip, shadow toggles, opacity, raise/lower)
  but basic BSP tiling, moving between displays, and `--focus`-based
  re-insertion all work fine without it.
- yabai requires `YABAI_SOCKET=/tmp/yabai_<user>.socket` to be exported in
  non-interactive/script contexts if the default lookup fails.

## No GUI

yabai has **no graphical interface** — it's 100% CLI/config-file driven
(`~/.config/yabai/yabairc`, `yabai -m ...` messages, `yabai -m query ...`
JSON output). Status/visibility options:
- `yabai -m query --windows` / `--spaces` / `--displays` (JSON, pipe to `jq`)
- Third-party menu bar add-ons exist (e.g. **borders**, **JankyBorders**) for
  a visual focus indicator, and **SketchyBar**/**Übersicht** widgets can show
  yabai state in the menu bar, but yabai itself ships CLI-only.

## Files

- `.yabairc` — main config, loaded from `~/.config/yabai/yabairc`
- `.skhdrc` — keybindings, loaded from `~/.skhdrc`
- `scripts/` — signal handlers + startup retile fixer

## Apply changes

```bash
cp .yabairc ~/.config/yabai/yabairc
cp .skhdrc ~/.skhdrc
launchctl unload ~/Library/LaunchAgents/com.asmvik.yabai.plist
launchctl load ~/Library/LaunchAgents/com.asmvik.yabai.plist
skhd --reload
```
