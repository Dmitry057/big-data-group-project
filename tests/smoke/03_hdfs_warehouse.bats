#!/usr/bin/env bats
#
# Layer 1 (Ingestion) — HDFS warehouse sanity checks.

load "${BATS_TEST_DIRNAME}/../helpers/common.bash"

setup() {
    require_cmd hdfs
}

@test "HDFS warehouse directory exists" {
    run hdfs dfs -test -d project/warehouse
    assert_success
}

@test "captures table directory exists on HDFS" {
    run hdfs dfs -test -d project/warehouse/captures
    assert_success
}

@test "network_connections table is non-trivial on HDFS (> 500 MB)" {
    run bash -c "hdfs dfs -du -s project/warehouse/network_connections 2>/dev/null | awk '{print \$1}'"
    assert_success
    # Stage-1 import lands roughly 979 MB of Parquet/Snappy.
    [ "$output" -gt 500000000 ]
}

@test "train/test parquet are present in project/data" {
    run hdfs dfs -test -d project/data/train
    assert_success
    run hdfs dfs -test -d project/data/test
    assert_success
}
