#!/usr/bin/env bats
#
# Layer 2 (Hive) — sanity-check q1 against the committed q1.csv.
# We don't rerun q1.hql (it's DROP+CREATE TABLE — slow and noisy);
# we just verify the materialised q1_results table matches the CSV
# export the dashboard reads.

load "${BATS_TEST_DIRNAME}/../helpers/common.bash"

setup() {
    require_cmd beeline
    require_secret "secrets/.hive.pass"
}

# beeline --outputformat=csv2 prints the column header as the first line
# (e.g. "_c0") and the value on the second. Pull the last non-empty line
# and strip everything but digits.
_last_int() {
    grep -E '[0-9]+' <<<"$1" | tail -n1 | tr -dc '0-9'
}

@test "q1_results table is populated (> 0 rows)" {
    run hive_query "SELECT count(*) FROM team30_projectdb.q1_results;"
    assert_success
    local n
    n="$(_last_int "$output")"
    [ -n "$n" ] && [ "$n" -gt 0 ]
}

@test "q1_results row count matches committed output/q1.csv" {
    run hive_query "SELECT count(*) FROM team30_projectdb.q1_results;"
    assert_success
    local hive_rows committed
    hive_rows="$(_last_int "$output")"
    committed="$(tail -n +2 "${PROJECT_ROOT}/output/q1.csv" | wc -l | tr -d ' ')"
    [ "${hive_rows}" = "${committed}" ]
}
