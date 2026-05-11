#!/usr/bin/env bats
#
# Layer 2 (Hive) — warehouse object inventory.

load "${BATS_TEST_DIRNAME}/../helpers/common.bash"

setup() {
    require_cmd beeline
    require_secret "secrets/.hive.pass"
}

@test "Hive database team30_projectdb is reachable" {
    run hive_query "SHOW DATABASES LIKE 'team30_projectdb';"
    assert_success
    assert_output --partial "team30_projectdb"
}

@test "all expected Hive tables exist" {
    run hive_query "SHOW TABLES IN team30_projectdb;"
    assert_success
    for tbl in \
        captures \
        network_connections \
        captures_bucketed \
        network_connections_part \
        q1_results q2_results q3_results q4_results q5_results q6_results q7_results
    do
        assert_output --partial "${tbl}"
    done
}

@test "network_connections_part is partitioned by label" {
    run hive_query "SHOW PARTITIONS team30_projectdb.network_connections_part;"
    assert_success
    # Stage-2 should expose at least 4 of the 7 labels as non-empty partitions.
    run bash -c "echo \"$output\" | wc -l"
    [ "$output" -ge 4 ]
}
