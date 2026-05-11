#!/usr/bin/env bats
#
# Layer 5 (artifacts) — runs on the cluster against on-disk outputs.

load "${BATS_TEST_DIRNAME}/../helpers/common.bash"

@test "output/ has all required Stage-3 artifacts" {
    for f in \
        "${PROJECT_ROOT}/output/model1_predictions.csv" \
        "${PROJECT_ROOT}/output/model2_predictions.csv" \
        "${PROJECT_ROOT}/output/evaluation.csv"; do
        assert_file "$f"
        [ -s "$f" ]
    done
}

@test "model1_predictions.csv contains all seven labels" {
    local f="${PROJECT_ROOT}/output/model1_predictions.csv"
    assert_file "$f"

    # Count distinct label-like values in column 1 (skip header).
    run bash -c "tail -n +2 '$f' | awk -F, '{print \$1}' | sort -u | wc -l"
    [ "$output" -ge 7 ]
}

@test "presentation PDF is non-empty" {
    local f="${PROJECT_ROOT}/presentation/presentation.pdf"
    assert_file "$f"
    [ "$(wc -c < "$f")" -gt 100000 ]
}
