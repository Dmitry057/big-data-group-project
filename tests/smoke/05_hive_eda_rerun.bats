#!/usr/bin/env bats
#
# Layer 2 (Hive) — re-run q1 and compare against the committed q1.csv.
# Only q1 is re-run by default; the rest take longer and add little signal.

load "${BATS_TEST_DIRNAME}/../helpers/common.bash"

setup() {
    require_cmd beeline
    require_secret "secrets/.hive.pass"
}

@test "q1.hql re-runs cleanly via beeline" {
    local tmp
    tmp="$(mktemp)"
    run bash -c "$(declare -f hive_file); hive_file '${PROJECT_ROOT}/sql/q1.hql' > '${tmp}'"
    assert_success
    [ -s "$tmp" ]
    rm -f "$tmp"
}

@test "q1_results row count matches committed output/q1.csv" {
    run hive_query "SELECT count(*) FROM team30_projectdb.q1_results;"
    assert_success
    local hive_rows="${output//[!0-9]/}"

    local committed
    committed="$(tail -n +2 "${PROJECT_ROOT}/output/q1.csv" | wc -l | tr -d ' ')"

    [ "${hive_rows}" = "${committed}" ]
}
