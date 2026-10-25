# Architecture

## Overview

Capernaum uses a **command/state** architecture (approach 1).

```
Input / UI → GameCommand → GameSession (authority)
                         → validate → mutate WorldState → CommandResult + signals
World views / HUD ← projections
SaveService ← validated snapshot
```

## Composition root

`GameSession` (autoload) owns:

- `ContentDB` — immutable definitions + localization
- `WorldState` — mutable authoritative state
- Systems: calendar, inventory, crops, economy, fishing, quests, relationships, NPC schedules
- `CommandProcessor` — single mutation gateway
- `SaveService` / `SaveCodec` — persistence

Systems are ordinary `RefCounted` instances, not dozens of autoloads.

## Commands

`GameCommand`: `command_id`, `session_id`, `actor_id`, `kind`, `target_id`, `payload`.

`CommandResult`: `ok`, `reason_code`, `events`, `data`.

Economic command IDs are deduplicated (last 256). Wrong-session commands fail.

## Simulation clock

`absolute_minutes` with civil day, religious ordinal (sunset), and dawn index (crops). `advance_minutes` enumerates boundaries chronologically once.

## Persistence

Schema v1 JSON at `user://saves/slot_01.json`. Write `.tmp` → validate → `.bak` previous → replace. Tests use `user://test_saves/`.

## Multiplayer seams (unverified)

Stable IDs, command authority, economic dedup, and `WorldState` snapshots are intentional seams. No networking is implemented or claimed.
