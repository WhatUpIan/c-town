# Historical notes

Each record distinguishes claim type. Placeholders must not silently become facts.
Tags: `fictional` | `provisional` | `textual_tradition` | `reviewed`.

## hn.setting_capernaum

- **content_id:** hn.setting_capernaum
- **claim:** Game map is a fictional village inspired by Capernaum / lakeside Galilee, not a surveyed reconstruction of a particular year.
- **source_url:** https://www.custodia.org/en/sanctuaries/capernaum/
- **source_type:** site presentation / tradition overview
- **confidence:** low for spatial accuracy
- **disputed_points:** Traditional site identifications do not independently prove historical identification of every structure.
- **gameplay_adaptation:** Compact isometric map with home, shore, stall, courtyard, modest synagogue exterior.
- **review_status:** provisional
- **tag:** provisional

## hn.synagogue_placeholder

- **content_id:** hn.synagogue_placeholder
- **claim:** Modest synagogue exterior placeholder is not a reconstruction of surviving later monumental ruins.
- **source_url:** (excavation publications — consult before release claims)
- **source_type:** design constraint
- **confidence:** n/a (negative claim / caution)
- **disputed_points:** Dating and form of first-century synagogue architecture debated.
- **gameplay_adaptation:** Simple basalt-colored block labeled “Synagogue”.
- **review_status:** provisional
- **tag:** provisional

## hn.barley

- **content_id:** hn.barley
- **claim:** Barley is a plausible regional crop candidate; three-day growth is a gameplay shortcut.
- **source_url:** https://www.sbl-site.org/wp-content/uploads/2024/12/Galilean-Economy-in-the-Time-of-Jesus.pdf
- **source_type:** scholarly starting point
- **confidence:** medium for crop presence; none for growth timing
- **disputed_points:** Seasonal labor and yields need further research.
- **gameplay_adaptation:** `barley_crop` growth_days=3, water each agricultural day.
- **review_status:** provisional
- **tag:** provisional

## hn.fish

- **content_id:** hn.fish
- **claim:** Freshwater lake fish as a livelihood is thematically appropriate; species unspecified.
- **source_url:** (fishing/species research queue)
- **source_type:** pending research
- **confidence:** low
- **disputed_points:** Species, gear, and market role need review.
- **gameplay_adaptation:** Item `lake_fish`; single shoreline minigame.
- **review_status:** provisional
- **tag:** provisional

## hn.bread

- **content_id:** hn.bread
- **claim:** Bread as staple food is a provisional household item.
- **source_url:** (foodways research queue)
- **source_type:** pending research
- **confidence:** low–medium
- **disputed_points:** Preparation/household economics simplified away.
- **gameplay_adaptation:** Starting inventory + stall goods.
- **review_status:** provisional
- **tag:** provisional

## hn.trade_units

- **content_id:** hn.trade_units
- **claim:** “Trade units” are visibly provisional and not historical coinage.
- **source_url:** (coinage/markets research queue)
- **source_type:** design shortcut
- **confidence:** n/a
- **disputed_points:** Actual circulation and purchasing power unresolved.
- **gameplay_adaptation:** Integer wallet; MVP prices.
- **review_status:** provisional
- **tag:** provisional

## hn.calendar

- **content_id:** hn.calendar
- **claim:** Prototype lunar labels (Nisan 1 = ordinal 0; 30/29 months) are a **simplified game calendar**, not today’s fixed Hebrew calendar nor an observational reconstruction.
- **source_url:** (calendar research queue)
- **source_type:** design simplification
- **confidence:** none for historical accuracy
- **disputed_points:** Intercalation, observation, and seasonality unresolved.
- **gameplay_adaptation:** `prototype_lunar_v1`; Sabbath weekday 7 via religious ordinal.
- **review_status:** provisional
- **tag:** provisional

## hn.sabbath_accommodation

- **content_id:** hn.sabbath_accommodation
- **claim:** Stall closes on Sabbath; gardening/fishing remain mechanically possible with a neutral rest-custom reminder and no penalty. This is a design accommodation under review — not an assertion about historical permission.
- **source_url:** (Jewish cultural review required)
- **source_type:** design proposal
- **confidence:** n/a
- **disputed_points:** Requires Jewish historical/cultural review before stronger claims.
- **gameplay_adaptation:** Schedule overrides; notification key `notify.rest_custom`.
- **review_status:** provisional
- **tag:** provisional

## hn.npc_names

- **content_id:** hn.npc_names
- **claim:** Miriam, Yehudah, and Hannah are fictional provisional names requiring review.
- **source_url:** (names/languages research queue)
- **source_type:** invented
- **confidence:** n/a
- **disputed_points:** Period-appropriate naming and language presentation need research.
- **gameplay_adaptation:** Three NPC defs with English presentation.
- **review_status:** provisional
- **tag:** fictional

## hn.passover_notice

- **content_id:** hn.passover_notice
- **claim:** Provisional Passover notice at Nisan 15 with courtyard dialogue change; no reconstructed ritual.
- **source_url:** (festival research queue)
- **source_type:** provisional gameplay beat
- **confidence:** low
- **disputed_points:** Festival practice needs review.
- **gameplay_adaptation:** `evt.passover_notice`.
- **review_status:** provisional
- **tag:** provisional

## hn.biblical_rumor

- **content_id:** hn.biblical_rumor
- **claim:** Optional biblical mode includes an original rumor/journal summary with a passage **reference** only; no Bible translation is reproduced.
- **source_url:** Mark 1:21 (reference)
- **source_type:** textual_tradition reference + invented framing
- **confidence:** n/a for invented dialogue
- **disputed_points:** Licensing must be verified before any translation text.
- **gameplay_adaptation:** Flag `story.biblical_rumor`; Everyday mode omits it.
- **review_status:** provisional
- **tag:** fictional + textual_tradition
