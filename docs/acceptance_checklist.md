# Acceptance checklist (A01–A27)

Mapped to brief §15. Automated via `tests/run_tests.gd` unless noted.

| ID | Description | Method | Status |
|---|---|---|---|
| A01 | Clean import; title/main load | Headless + manual | Automated **PASS**; visual smoke **PASS** (title + village) |
| A02 | Cardinal/diagonal speed; walls/water block | Automated + manual | Math/speed **PASS**; collision manual/partial |
| A03 | Y-sort / tall props | Manual | **PASS** (CG-3 playtest) |
| A04 | Nearest target; occluded reject | Automated + manual | **PASS** |
| A05 | Inventory merge / overflow | Automated | **PASS** |
| A06 | Valid/invalid trades | Automated | **PASS** |
| A07 | Economic command dedup | Automated | **PASS** |
| A08 | Plant/water/grow/harvest barley | Automated | **PASS** |
| A09 | Dry day; full inventory harvest | Automated | **PASS** |
| A10 | Multi-dawn; no double process | Automated | **PASS** |
| A11 | Fishing success/fail/cancel/full | Automated + manual | Automated **PASS**; timing UI simplified |
| A12 | Friendship daily gate + cap | Automated | **PASS** |
| A13 | Schedules + Sabbath stall | Automated + manual | Automated **PASS**; trap check manual |
| A14 | Sabbath begin/end exact | Automated | **PASS** |
| A15 | Civil midnight ≠ religious day | Automated | **PASS** |
| A16 | Month / Nisan 15 festival once | Automated | **PASS** |
| A17 | Delivery quest rewards once | Automated | **PASS** |
| A18 | Save round-trip + RNG | Automated | **PASS** |
| A19 | Backup / future schema | Automated | **PASS** |
| A20 | Write/rename failure | Automated | **PASS** |
| A21 | No duplicate growth/reward after reload | Automated | **PASS** |
| A22 | Everyday vs biblical filtering | Automated + manual | Automated **PASS** |
| A23 | Modal UI pauses sim | Manual | **PASS** — inventory/pause/dialogue freeze clock |
| A24 | Resolutions / keyboard / muted | Manual | **PASS** (single size); full 960/1280/1920 matrix optional |
| A25 | Full loop quit/restart | Manual | **PASS** — owner confirmed fishing, delivery, save/Continue |
| A26 | Two actors one harvest | Automated | **PASS** |
| A27 | Malformed save rejected | Automated | **PASS** |
