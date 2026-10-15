# service-monitoring — annotated example

> A monitoring dashboard for a single service. Tasks set thresholds and per-environment configs. Witnesses report live metrics scraped from prometheus. An override (by the on-call) adjusts the latency threshold during a planned migration. 9 records.

## The shape

```
genesis (task)              — service, version
├── thresholds (task)       — alert.latency_ms.warn=200, alert.error_rate.warn=0.01, etc.
├── prod-config (task)      — env.prod.region=us-east-1, env.prod.replicas=6
├── staging-config (task)   — env.staging.region=us-east-2, env.staging.replicas=2
├── latency-now (witness)   — now.latency_ms=142
├── error-rate-now (witness) — now.error_rate=0.003
└── disk-now (witness)      — now.disk_pct=73

latency-bump (override)     — alert.latency_ms.warn=400, alert.latency_ms.crit=800
                              (reason: "planned migration 22:00-23:00")

alert-state (task)          — depends on the override + the 3 witnesses
```

## What the fold produces

The state at `alert-state` shows:
- `alert.latency_ms.warn = 400` (the override wins against the threshold task).
- `alert.latency_ms.crit = 800` (same).
- `alert.error_rate.warn = 0.01` (the original threshold).
- `now.latency_ms = 142` (the witness).
- `env.prod.replicas = 6` (the prod config task).
- A conflict: `alert.latency_ms.warn` has `winner: latency-bump, losers: [thresholds]`. Same for `alert.latency_ms.crit`.

## What this example teaches

- **Tasks for static config** (thresholds, per-env settings) — set once, read often.
- **Witnesses for live metrics** — read-only reports of what's happening right now. They're not the "truth" of the system; they're a snapshot of what the metrics reported.
- **Overrides for captain-class adjustments** — the on-call has the authority to bump a threshold. The override is *named* (`latency-bump`) and the reason is in the record. When the migration is done, the override can be removed (or superseded by a new one).
- **Tasks for derived state** (`alert-state`) — depends on the override + the witnesses. The fold runs and the state shows the *current* alert posture.
- **Why no orphans or cycles**: all parents are in the set; the override depends on the threshold task, the alert-state depends on the override + witnesses.

## Verifying

```bash
python3 /path/to/git.pp-doctor/gitpp_doctor.py explain records.json --at alert-state
```

The closure of `alert-state` is 6 records: `alert-state, latency-bump, latency-now, error-rate-now, disk-now, thresholds, genesis`. The `prod-config` and `staging-config` records are in the set but *not* in the closure of `alert-state` (they don't affect the alert state).

## Variations to try

- **Add a second override** that reverts the latency bump (e.g. "migration done at 22:45"). Watch the conflict: the earlier override wins (per the current fold design), so the alert-state is still `warn=400`. To actually revert, you need to either remove the first override or use unique keys.
- **Add a witness with stale data** (e.g. a different timestamp). The witness shows up in state but doesn't trigger an alert; alerts are derived state, not direct witnesses.
- **Add an orphan**: a witness whose `parents` references a record that doesn't exist. Watch the orphan be excluded; the closure root changes.
