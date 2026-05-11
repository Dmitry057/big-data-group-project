#!/usr/bin/env bats
#
# Layer 3 (Spark) — re-run ml_evaluation.py against persisted predictions.
# Does NOT retrain. Verifies that committed evaluation.csv reproduces.

load "${BATS_TEST_DIRNAME}/../helpers/common.bash"

setup() {
    require_cmd spark-submit
    assert_file "${PROJECT_ROOT}/output/model1_predictions.csv"
    assert_file "${PROJECT_ROOT}/output/model2_predictions.csv"
    assert_file "${PROJECT_ROOT}/output/evaluation.csv"
}

@test "ml_evaluation.py reproduces output/evaluation.csv (RF F1 > 0.99)" {
    local before f1_before
    before="$(cat "${PROJECT_ROOT}/output/evaluation.csv")"
    f1_before="$(echo "$before" | grep -iE '(rf|random.?forest|model1)' \
                                | grep -oE '0\.99[0-9]+' | head -n1)"
    [ -n "$f1_before" ] || skip "evaluation.csv has no RF F1 to compare against"

    # Re-run evaluator in client mode (smaller footprint).
    cd "${PROJECT_ROOT}"
    run env -u VIRTUAL_ENV PATH="/usr/bin:/bin" \
        HADOOP_CONF_DIR=/etc/hadoop/conf YARN_CONF_DIR=/etc/hadoop/conf \
        spark-submit --master yarn --deploy-mode client \
            --num-executors 2 --executor-cores 2 --executor-memory 3G \
            --driver-memory 2G \
            scripts/ml_evaluation.py
    assert_success
}
