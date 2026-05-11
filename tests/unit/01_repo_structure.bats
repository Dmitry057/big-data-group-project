#!/usr/bin/env bats
#
# Repo-structure invariants. Pure file checks, no cluster access.

load "${BATS_TEST_DIRNAME}/../helpers/common.bash"

@test "main.sh exists at repo root" {
    assert_file "${PROJECT_ROOT}/main.sh"
}

@test "all four stage scripts exist and start with bash shebang" {
    for stage in 1 2 3 4; do
        assert_file "${PROJECT_ROOT}/scripts/stage${stage}.sh"
        run head -n1 "${PROJECT_ROOT}/scripts/stage${stage}.sh"
        assert_output --partial "#!/bin/bash"
    done
}

@test "every stage script uses set -euo pipefail" {
    for stage in 1 2 3 4; do
        run grep -E "^set -[a-zA-Z]*euo" "${PROJECT_ROOT}/scripts/stage${stage}.sh"
        assert_success
    done
}

@test "all 7 HQL EDA queries are present" {
    for i in 1 2 3 4 5 6 7; do
        assert_file "${PROJECT_ROOT}/sql/q${i}.hql"
    done
}

@test "Hive warehouse DDL exists" {
    assert_file "${PROJECT_ROOT}/sql/db.hql"
}

@test "PostgreSQL DDL and test queries exist" {
    assert_file "${PROJECT_ROOT}/sql/create_tables.sql"
    assert_file "${PROJECT_ROOT}/sql/test_database.sql"
}

@test "ML pipeline scripts are all present" {
    assert_file "${PROJECT_ROOT}/scripts/ml_data_preparation.py"
    assert_file "${PROJECT_ROOT}/scripts/ml_models_training.py"
    assert_file "${PROJECT_ROOT}/scripts/ml_evaluation.py"
}

@test ".gitignore excludes data/, secrets/, .venv/" {
    for path in "data/" "secrets/" ".venv"; do
        run grep -F "${path}" "${PROJECT_ROOT}/.gitignore"
        assert_success
    done
}

@test "secrets/ contents are not tracked by git" {
    cd "${PROJECT_ROOT}"
    run git ls-files secrets/
    assert_output ""
}
