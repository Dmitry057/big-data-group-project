#!/usr/bin/env bats
#
# Layer 3 (Spark) — re-run ml_evaluation.py against persisted predictions.
# Does NOT retrain. Verifies that evaluation.csv can be reproduced.

load "${BATS_TEST_DIRNAME}/../helpers/common.bash"

setup() {
    require_cmd spark-submit
    assert_file "${PROJECT_ROOT}/output/model1_predictions.csv"
    assert_file "${PROJECT_ROOT}/output/model2_predictions.csv"
    assert_file "${PROJECT_ROOT}/output/evaluation.csv"
}

@test "ml_evaluation.py re-runs successfully on YARN" {
    cd "${PROJECT_ROOT}"
    # ml_evaluation.py uses f-strings (Python 3.6+). The cluster's
    # default PYSPARK_PYTHON is /usr/bin/python (2.7); pin it to
    # python3 like stage3.sh does.
    run env -u VIRTUAL_ENV \
        PATH="/usr/bin:/bin" \
        HADOOP_CONF_DIR=/etc/hadoop/conf \
        YARN_CONF_DIR=/etc/hadoop/conf \
        PYSPARK_PYTHON=/usr/bin/python3 \
        PYSPARK_DRIVER_PYTHON=/usr/bin/python3 \
        spark-submit --master yarn --deploy-mode client \
            --num-executors 2 --executor-cores 2 --executor-memory 3G \
            --driver-memory 2G \
            scripts/ml_evaluation.py
    assert_success
}
