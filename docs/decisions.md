# Decisions log

Reversible implementation choices for the Capernaum first-playable prototype.

| Date | Decision | Rationale | Reversible? |
|---|---|---|---|
| 2026-10-25 | Pin Godot **4.7.2.stable** (Compatibility / GL Compatibility) | Released stable with TileMapLayer support; matches brief default | Yes — retarget patch in README/project |
| 2026-10-25 | Architecture approach **1** (command/state) | Brief recommended default; preserves co-op seams | Yes — costly later if abandoned |
| 2026-10-25 | Content bundled in `ContentDB` builtins + mirrored JSON under `data/` | Avoids fragile `.tres` authoring before editor pipeline; JSON is source-of-truth for review | Yes — migrate to Resources |
| 2026-10-25 | Ground rendered with diamond sprites instead of authored TileMapLayer tileset | Faster headless-safe prototype; IsoMath matches brief; TileMapLayer can replace sprites | Yes |
| 2026-10-25 | NPC IDs: `npc.merchant_01` (Miriam), `npc.fisher_01`, `npc.stall_01` | Stable IDs per brief style; display names provisional pending review | Yes — rename map |
| 2026-10-25 | Fishing success injectable via command payload / system override | Deterministic A11 without flaky timing UI | Yes |
| 2026-10-25 | Trade unit label kept generic | Brief: provisional units until coinage research | Yes |
| 2026-10-25 | Single-player modal UI pauses simulation via `GameSession.modal_pause` | Brief session policy | Yes — co-op can disable |
| 2026-10-25 | Windows export preset added only if templates present | Honest verification; no false export claims | Yes |
| 2026-10-25 | Install official `4.7.2.stable` Windows x86_64 templates; preset **Windows Desktop** → `builds/Capernaum.exe` | Matches pinned editor; templates not committed | Yes |
| 2026-10-25 | Do not claim Wine launch as Windows verification | Brief: exported executable must be launched separately on target | Yes |
