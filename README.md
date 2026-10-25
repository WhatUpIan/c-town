# Capernaum

Cozy isometric 2D life simulation set in a fictional first-century Jewish Galilee village. This repository is the **first playable prototype** (milestones P0–P5): Everyday Life loop with talk, delivery quest, fishing, barley gardening, trade, Sabbath schedule, sleep, save/load.

## Engine

| Field | Value |
|---|---|
| Engine | **Godot 4.7.2.stable** (`4.7.2.stable.official.ed1daf0bf`) |
| Language | GDScript |
| Renderer | **Compatibility** (`gl_compatibility`) |
| Docs version | [Godot 4.7 stable docs](https://docs.godotengine.org/en/stable/) |
| Target OS (dev) | Linux x86_64 (prototype also designed for Windows desktop first) |

Do not use Godot 3 tutorials. Avoid preview builds.

## Launch

```bash
# Pin matching editor:
godot --version   # expect 4.7.2.stable...

# Import once, then play:
godot --headless --path . --editor --import --quit
godot --path .
```

Main scene: `res://scenes/main.tscn`.

### Controls

| Action | Keys |
|---|---|
| Move | WASD / arrows |
| Interact | E |
| Primary action | Space / left click |
| Inventory | I |
| Journal | J |
| Cycle tool | Tab |
| Pause | Escape |

### Playable loop (Everyday)

1. New Game → Everyday Life  
2. Talk to Miriam / Yehudah / Hannah  
3. Accept Miriam’s delivery (two lake fish)  
4. Fish at the shoreline marker  
5. Hoe / plant / water / harvest barley on home plots  
6. Buy/sell at Hannah’s stall (08:00–18:00, closed Sabbath)  
7. Complete delivery  
8. Experience Sabbath schedule change  
9. Sleep at the bed after 18:00  
10. Quit and Continue — progress restored  

## Tests

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/run_tests.gd
```

Exit code nonzero on failure. See `docs/verification.md` and `docs/acceptance_checklist.md`.

## Windows export

Requires matching **4.7.2.stable** export templates. Preset name: `Windows Desktop`.

```bash
godot --headless --path . --export-release "Windows Desktop" builds/Capernaum.exe
```

Ship **both** `builds/Capernaum.exe` and `builds/Capernaum.pck`. See `docs/export_windows.md`. Artifacts are gitignored under `builds/`.

## Docs

- `docs/architecture.md` — command/state design  
- `docs/decisions.md` — reversible defaults  
- `docs/historical_notes.md` — claims vs inventions  
- `docs/verification.md` — test evidence  
- `docs/acceptance_checklist.md` — A01–A27 map  
- `docs/changelog.md` — prototype notes / limits / next tasks  

## License note

Original placeholder art is project-owned (CC0 placeholders). Historical content is provisional — see `docs/historical_notes.md`. Do not treat placeholders as archaeological reconstructions.
