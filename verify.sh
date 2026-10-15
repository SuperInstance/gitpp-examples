#!/usr/bin/env bash
# verify.sh — verify all 3 examples pass
set -e

DOCTOR="${DOCTOR:-python3 /path/to/git.pp-doctor/gitpp_doctor.py}"

for d in family-calendar tournament-scoring service-monitoring; do
  at=$(jq -r .at $d/expected.json)
  expected=$(jq -r .closureRoot $d/expected.json)
  echo -n "$d: "
  if $DOCTOR check $d/records.json --at "$at" --expected "$expected" 2>&1 | grep -q VERIFIED; then
    echo "VERIFIED"
  else
    echo "FAIL"
    $DOCTOR check $d/records.json --at "$at" --expected "$expected"
    exit 1
  fi
done

echo
echo "All 3 examples verified."
