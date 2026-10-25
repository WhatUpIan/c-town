# Verification

## Environment

| Field | Value |
|---|---|
| Date (UTC) | 2026-10-25 |
| Engine | Godot 4.7.2.stable.official.ed1daf0bf |
| Renderer | gl_compatibility (Compatibility) |
| OS | Ubuntu 24.04.5 LTS, x86_64 |
| Branch | `cursor/capernaum-prototype-f53f` |

## Commands run

```bash
godot --version
# 4.7.2.stable.official.ed1daf0bf

godot --headless --path . --editor --import --quit
# exit 0

godot --headless --path . --script res://tests/run_tests.gd
# === Summary: 79 passed, 0 failed, 4 skipped ===
# exit 0
```

## Automated results

- **79 passed**, **0 failed**, **4 skipped** in runner (A03/A23–A25 are manual)

## Manual acceptance (CG-3)

| ID | Result | Notes |
|---|---|---|
| A01 (visual) | Pass | Title + Everyday load |
| A03 | Pass | Y-sort / prompts visible ([playtest](bc-bb8778fe-e893-5066-bf92-d7d46e29138a)) |
| A23 | Pass | Inventory, Pause, and Dialogue freeze clock (dialogue after UI-path fix) |
| A24 | Pass (partial sizes) | Keyboard + muted OK; single window size checked — not full 960/1280/1920 matrix |
| A25 | Pass (owner) | Fishing ×2, Miriam delivery, Save → Title → Continue restore confirmed by owner 2026-10-25 |
| Controller | Skipped | No controller |
| Windows export | Built; native launch pending | See CG-4 below |

### Bugs found and fixed during CG-3

1. **Dialogue/stall UI unreachable** — village looked up `UI` on `VillageHost` instead of `Main`. Fixed via `_main_ui()`.
2. **Continue vs New Game confusion** — Continue path hardened; focus prefers Continue when a save exists. “Replace save?” is New Game only.
3. **Fishing hard to reach** — marker moved to walkable shoreline cell; activity markers preferred over NPCs; interact range 64px; speed ~160.

### Remaining for owner

- Optional: full 960×540 / 1920×1080 matrix for A24.
- **Native Windows launch** of `builds/Capernaum.exe` + `.pck` (Wine on this Linux VM page-faulted; does not count as Windows verification).

## CG-4 Windows export

| Field | Value |
|---|---|
| Date (UTC) | 2026-10-25 |
| Templates | `4.7.2.stable` (`windows_release_x86_64.exe`) |
| Command | `godot --headless --path . --export-release "Windows Desktop" builds/Capernaum.exe` |
| Exit | 0 |
| Outputs | `builds/Capernaum.exe` (105M, PE32+ x86-64 GUI), `builds/Capernaum.pck` (1.6M) |
| SHA-256 exe | `7312a16f20668255d18631e4015af8ed9c35c9e69d35f591d2283dcd74f926d7` |
| SHA-256 pck | `e5499b945d23c8b811dc7eaaeb5f298c5aa38d4ebf3d85846f777d9b84f2b3f0` |
| Wine smoke | Exit 124 / page fault — **not** a Windows pass |
| Native Windows | **Not run in this environment** — owner should launch separately |

Details: `docs/export_windows.md`. Preset: `export_presets.cfg`.

## Screenshots

- Smoke: `docs/media/smoke-title.webp`, `docs/media/smoke-village.webp`
- Playtest store copies: `media/playtest-a03-a25/` (Project store)


## CG-5 vertical polish

| Item | Status |
|---|---|
| TileMapLayer ground | Implemented (`GroundBuilder` + `GroundLayer`) |
| Fishing timing UI | Implemented (`scenes/ui/fishing_minigame.tscn`) |
| Automated suite | 79 passed / 0 failed after change |
| Manual fishing band | Owner should verify locally after pull |
