#!/usr/bin/env bats
#
# Layer 1 (Ingestion) — PostgreSQL sanity checks against team30_projectdb.
# Skips automatically if psql or the password file is missing.

load "${BATS_TEST_DIRNAME}/../helpers/common.bash"

setup() {
    require_cmd psql
    require_secret "secrets/.psql.pass"
    PGPASSWORD="$(head -n1 "${PROJECT_ROOT}/secrets/.psql.pass")"
    export PGPASSWORD
}

psql_query() {
    psql -h "${PG_HOST}" -U "${PG_USER}" -d "${PG_DB}" -At -c "$1"
}

@test "captures table has 12 rows" {
    run psql_query "SELECT count(*) FROM captures;"
    assert_success
    [ "$output" = "12" ]
}

@test "network_connections has ~25M rows (regression guard, > 24M)" {
    run psql_query "SELECT count(*) FROM network_connections;"
    assert_success
    [ "$output" -gt 24000000 ]
}

@test "all 7 label values present in network_connections" {
    run psql_query "SELECT count(DISTINCT label) FROM network_connections;"
    assert_success
    [ "$output" = "7" ]
}

@test "every connection references an existing capture (FK integrity)" {
    run psql_query "SELECT count(*) FROM network_connections nc
                    LEFT JOIN captures c USING (capture_id)
                    WHERE c.capture_id IS NULL;"
    assert_success
    [ "$output" = "0" ]
}

@test "no leftover '-' sentinel in id_orig_h after typed insert" {
    # id_orig_h is inet, so '-' would have failed cast — this is belt-and-braces.
    run psql_query "SELECT count(*) FROM network_connections WHERE id_orig_h IS NULL;"
    assert_success
    # Allow some NULLs (Zeek really does emit them), but flag a flood.
    [ "$output" -lt 1000000 ]
}

@test "sql/test_database.sql runs cleanly end-to-end" {
    skip_if_missing="${PROJECT_ROOT}/sql/test_database.sql"
    [ -f "$skip_if_missing" ] || skip "sql/test_database.sql missing"
    run psql -h "${PG_HOST}" -U "${PG_USER}" -d "${PG_DB}" \
        -v ON_ERROR_STOP=1 -f "$skip_if_missing"
    assert_success
}
