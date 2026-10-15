# tournament-scoring — annotated example

> A weekly round-robin tournament where each match is an override (the event), each player has a task with their starting ELO (the baseline), and a final-standings task records the cumulative state. 10 records.

## The shape

```
genesis (task)
├── alice (task)        — player.alice.elo = 1500
├── bob (task)          — player.bob.elo = 1500
└── carol (task)        — player.carol.elo = 1500

match-1 (override)     — alice beat bob
└── match-1-witness     — match confirmed
match-2 (override)     — carol beat alice
└── match-2-witness     — match confirmed

final-standings (task) — current.alice.elo = 1500, current.bob.elo = 1484, etc.
└── week-summary (task) — tournament.week = 1, tournament.matches_played = 2
```

## What the fold produces

- Each match has its own keys (`match-1.alice.elo_after`, `match-2.alice.elo_after`) so the per-match state is preserved in the ledger.
- The `current.*` keys (in `final-standings`) give the *cumulative* state.
- The `player.*` keys (from the task records) give the *baseline* state.
- The `tournament.*` keys (in `week-summary`) give the *aggregate* state.

## What this example teaches

- **Tasks as baseline**: the player records are the *starting point*. They set the baseline ELO.
- **Overrides as events**: each match is one override. The override's effects are *facts about the match*, not the cumulative state.
- **Tasks as derived state**: `final-standings` is a task that depends on the match witnesses. Its effects are the *cumulative* state. The fold runs and the cumulative state shows up alongside the per-match state.
- **Why this design**: if you only stored the cumulative state, you'd lose the per-match history. If you only stored the per-match state, you'd have to recompute the cumulative state every time. The git.pp design lets you store both, derived from the same record set.
- **Conflict-free**: because each match has its own keys, there are no conflicts. The `conflicts` array is empty.

## A real design question

You might ask: "why not just have the override set the cumulative state directly?" The answer is that the fold does NOT merge two overrides on the same key by recency — when two overrides conflict, the *earlier* one wins (the latest-override-wins rule would require a different precedence design). The current design forces you to *name* your keys per match and aggregate explicitly via a final-standings task. That's a feature, not a bug — it forces the design to be auditable.

## Verifying

```bash
python3 /path/to/git.pp-doctor/gitpp_doctor.py explain records.json --at week-summary
```

The state at `week-summary` shows alice with 1 win, 1 loss (1500 ELO), bob with 0 wins, 1 loss (1484 ELO), carol with 1 win, 0 losses (1516 ELO). The tournament leader is carol.

## Variations to try

- Add a third match where bob beats carol. The `current.bob.elo` would need to be updated in `final-standings`. (Or, replace `final-standings` with a task that re-derives from the matches.)
- Add a witness for a match dispute. The witness shows up in state but doesn't change the ELO.
- Add an orphan: a record that references a non-existent player. Watch it get excluded.
