# Changelog — Capernaum 0.1.0 (first playable)

## Added

- Godot 4.7.2 Compatibility project with InputMap, title/main/village scenes
- Command/state architecture (`GameSession`, `CommandProcessor`, systems)
- Everyday + Biblical new-game modes (biblical rumor filtered)
- Six barley plots, fishing, stall trade, three NPCs, delivery quest
- Civil/religious/dawn clocks, Sabbath, provisional Passover notice
- Save slot with tmp/bak recovery, settings (font scale, volume, reduced motion)
- Headless acceptance runner `tests/run_tests.gd`
- Docs: architecture, decisions, historical notes, verification, acceptance checklist

## Limitations

- Placeholder geometric art only; no audio
- Fishing is instant success/fail (injectable), not a full timing minigame feel
- Ground uses diamond sprites (not authored TileMapLayer tileset)
- NPC pathing is direct anchor walks, not full A\* footprints
- Trade units and calendar are explicit simplifications
- No Steam, networking, or Windows export artifact (templates missing)
- Manual A03/A23–A25 not completed in verification

## Next three tasks

1. Native Windows launch of `builds/Capernaum.exe` + `.pck` (CG-4 export built; Wine ≠ Windows)  
2. Replace sprite ground with TileMapLayer tileset; add simple fishing timing band UI (CG-5)  
3. Create real repo and open PR from `cursor/capernaum-prototype-f53f` (CG-6)  
