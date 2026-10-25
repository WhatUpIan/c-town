# Windows export (CG-4)

## Prerequisites

- Godot **4.7.2.stable** editor matching this project
- Export templates `4.7.2.stable` installed under  
  `~/.local/share/godot/export_templates/4.7.2.stable/`  
  (from `Godot_v4.7.2-stable_export_templates.tpz`)

## Command

```bash
godot --headless --path . --export-release "Windows Desktop" builds/Capernaum.exe
```

Preset name must match `export_presets.cfg`: **Windows Desktop**.  
Outputs (gitignored under `builds/`):

- `builds/Capernaum.exe` — PE32+ x86-64 GUI
- `builds/Capernaum.pck` — game pack (required beside the exe)

## Verify on Windows

1. Copy **both** `.exe` and `.pck` to the same folder.
2. Double-click `Capernaum.exe` (do not run only from a zip without the `.pck`).
3. Confirm title screen loads. Editor play does **not** count as export verification.

## Checksums (prototype build 2026-10-25)

```
7312a16f20668255d18631e4015af8ed9c35c9e69d35f591d2283dcd74f926d7  Capernaum.exe
e5499b945d23c8b811dc7eaaeb5f298c5aa38d4ebf3d85846f777d9b84f2b3f0  Capernaum.pck
```
