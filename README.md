# gitpp-examples

> A collection of annotated example record sets for the git.pp fold. Each example is a self-contained `records/` directory plus a walkthrough that explains the design.

## Why

The spec is dry. The "hello world" is "compute the closure root of an 8-record set." This repo is the *useful* world: a family calendar, a tournament score, a service monitor. Each example:

- Has a `records/` directory with one JSON per record.
- Has a `WALKTHROUGH.md` that explains the design choices.
- Has a `expected.json` with the closure root, the derived state, the conflicts.
- Verifies byte-for-byte against the live ports (`gitpp-js`, `git.pp-doctor`).

If you're a port author, these are the "realistic" tests — bigger than the conformance corpus, smaller than a production set, and they come with intent (you can see *why* the design is what it is).

## Examples

| Example | Records | Use case |
|---|---|---|
| [family-calendar](family-calendar/) | 8 | A shared family calendar: tasks set "available", overrides handle "doctor's appointment", witnesses confirm "I see the calendar" |
| [tournament-scoring](tournament-scoring/) | 12 | A small tournament: each captain authors an override, witnesses record final scores, the state is the final standings |
| [service-monitoring](service-monitoring/) | 10 | A monitoring dashboard: tasks set thresholds, witnesses report live metrics, the state is the dashboard |

## Verifying the examples

```bash
# Clone and run
git clone https://github.com/SuperInstance/gitpp-examples
cd gitpp-examples
for d in family-calendar tournament-scoring service-monitoring; do
  echo "=== $d ==="
  python3 /path/to/git.pp-doctor/gitpp_doctor.py check $d/records.json --at root --expected $(cat $d/expected.json | jq -r .closureRoot)
done
```

Or use the JS port:

```bash
for d in family-calendar tournament-scoring service-monitoring; do
  node -e "
    import('gitpp-js/src/gitpp.js').then(async (p) => {
      const records = JSON.parse(require('fs').readFileSync('$d/records.json'));
      const root = await p.closureRoot(records, 'root');
      console.log('$d root:', root);
    });
  "
done
```

## The "hello world" — in three lines

```bash
curl -sS https://gitpp.superinstance.dev/api/records?project=poc-quilt-1 | \
  python3 /path/to/git.pp-doctor/gitpp_doctor.py explain - --at task-c | jq .closureRoot
# → "60effe23970d8a5cc837636c44685502361288c1f00577e9addfa10cbd4fc91d"
```

That's it. Three lines: fetch the live set, run the doctor, read the root.
