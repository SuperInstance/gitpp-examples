# family-calendar — annotated example

> A shared family calendar where one captain (a parent) can override a child's recurring event with a doctor's appointment. The override is the load-bearing mechanic.

## The shape

```
genesis (task)
├── caleb (task)         — sets caleb.tuesday=soccer
├── marina (task)        — sets marina.monday=yoga
├── leo (task)           — sets leo.friday=drum lesson
├── caregiver (task)     — sets caregiver.saturday=with grandma
└── grandma (witness)    — confirms "see kids Saturday"
└── dr-visit (override)  — overrides caleb.tuesday=soccer → doctor
    └── caleb-confirm (witness) — confirms the doctor visit happened
```

8 records. The closure of `dr-visit` is `dr-visit, caleb, genesis, caleb-confirm` — 4 records.

## What the fold produces

- `caleb.tuesday` = `"doctor"` (the override wins, not the task).
- `caleb.tuesday_confirmed` = `true` (a witness — never loses, never wins against the override's effect on the *same* key; here the witness sets a *different* key, so it just shows up in state).
- The `caleb.tuesday` conflict is recorded: `winner: dr-visit, losers: [caleb]`. This is informational — the state is what it is, but the conflict ledger says "this key was contested."

## What this example teaches

- **Tasks** set the default state. A task is a declarative "this is the way it is."
- **Overrides** are captain-class. They win against tasks on the same key. The reason field is required (`reason: "annual checkup, soccer can move"`); the override is *not* a silent mutation.
- **Witnesses** confirm events. They never lose to anyone, but they don't *win* against an override on the same key either. The semantic is "this thing happened"; it's not a "vote."
- **Closure** at `dr-visit` is just `dr-visit, caleb, genesis, caleb-confirm`. Marina, leo, caregiver, grandma are *not* in the closure — they don't affect the state at `dr-visit`.

## Verifying

```bash
# State and root
python3 /path/to/git.pp-doctor/gitpp_doctor.py explain records.json --at dr-visit

# The closure root
python3 /path/to/git.pp-doctor/gitpp_doctor.py root records.json --at dr-visit
# → a487b2df4c6941a2aa47deecb058d98f0ec0b7efe607143d5c1055117d06c294

# Compare against expected.json
python3 /path/to/git.pp-doctor/gitpp_doctor.py compare records.json /path/to/expected.json --at dr-visit
```

## Variations to try

- Add a second override on `marina.monday` (e.g. "marina sick today → rest"). Watch the state change; the conflict moves.
- Add a witness to `dr-visit` that says `caleb.tuesday_attended: true`. The witness shows up in state but doesn't change `caleb.tuesday` (it sets a different key).
- Add an orphan: a new record whose `parents` references a nonexistent id. Watch the orphan get excluded from state and the closure root change.
