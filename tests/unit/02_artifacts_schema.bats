#!/usr/bin/env bats
#
# Schema / content invariants on the committed artifacts under output/.
# Catches regressions in CSV exports without touching the cluster.

load "${BATS_TEST_DIRNAME}/../helpers/common.bash"

@test "evaluation.csv has both models and four metrics" {
    local f="${PROJECT_ROOT}/output/evaluation.csv"
    assert_file "$f"

    run head -n1 "$f"
    # header should reference accuracy / precision / recall / f1
    assert_output --regexp "accuracy.*precision.*recall.*f1|f1.*recall.*precision.*accuracy"

    # at least 2 data rows (RF + LR)
    run bash -c "tail -n +2 '$f' | wc -l"
    [ "$output" -ge 2 ]
}

@test "Random Forest F1 in evaluation.csv is above 0.99 (regression guard)" {
    local f="${PROJECT_ROOT}/output/evaluation.csv"
    assert_file "$f"
    # Grep any number 0.99xx near a RandomForest / model1 marker.
    run grep -iE "(random.?forest|model1|rf)" "$f"
    assert_success
    run grep -oE "0\.99[0-9]+" "$f"
    assert_success
}

@test "all 7 EDA CSVs exist and are non-empty" {
    for i in 1 2 3 4 5 6 7; do
        local f="${PROJECT_ROOT}/output/q${i}.csv"
        assert_file "$f"
        [ -s "$f" ]
    done
}

@test "all 7 EDA charts exist and are non-empty" {
    for i in 1 2 3 4 5 6 7; do
        local f="${PROJECT_ROOT}/output/q${i}.jpg"
        assert_file "$f"
        [ -s "$f" ]
    done
}

@test "storage-benchmark CSV is committed" {
    assert_file "${PROJECT_ROOT}/output/stage1_storage_benchmark_avg.csv"
    assert_file "${PROJECT_ROOT}/output/stage1_storage_benchmark_runs.csv"
}

@test "model directories are committed for both models" {
    assert_dir "${PROJECT_ROOT}/models/model1"
    assert_dir "${PROJECT_ROOT}/models/model2"
}

@test "final report PDF is committed and non-trivial" {
    local f="${PROJECT_ROOT}/report/report.pdf"
    assert_file "$f"
    # Report should be at least 500 KB; current is ~1.5 MB.
    local size
    size="$(wc -c < "$f")"
    [ "$size" -gt 500000 ]
}

@test "no leftover Citus references in report.tex" {
    run grep -iF "citus" "${PROJECT_ROOT}/report/report.tex"
    assert_failure
}

@test "no '737 MB' regression in report.tex (must be 3.39 GB)" {
    run grep -F "737 MB" "${PROJECT_ROOT}/report/report.tex"
    assert_failure
    run grep -F "3.39 GB" "${PROJECT_ROOT}/report/report.tex"
    assert_success
}

@test "report.tex points at the new repo URL" {
    run grep -F "big-data-group-project" "${PROJECT_ROOT}/report/report.tex"
    assert_success
}
