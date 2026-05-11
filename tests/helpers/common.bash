# Shared helpers for project30 bats tests.
#
# Source from any *.bats file:
#   load "${BATS_TEST_DIRNAME}/../helpers/common.bash"

# Project root = two levels up from any test file under tests/{unit,smoke}/.
export PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)}"

# Vendored bats-support / bats-assert.
load "${PROJECT_ROOT}/tests/bats/bats-support/load.bash"
load "${PROJECT_ROOT}/tests/bats/bats-assert/load.bash"

# --- cluster endpoints -------------------------------------------------------
HIVE_JDBC="${HIVE_JDBC:-jdbc:hive2://hadoop-03.uni.innopolis.ru:10001}"
HIVE_USER="${HIVE_USER:-team30}"
PG_HOST="${PG_HOST:-hadoop-04.uni.innopolis.ru}"
PG_DB="${PG_DB:-team30_projectdb}"
PG_USER="${PG_USER:-team30}"
DASHBOARD_URL="${DASHBOARD_URL:-}"   # injected by run_tests.sh if set

# --- file assertion helpers --------------------------------------------------
# bats-assert has no built-in file checks; we provide minimal ones so tests
# stay readable without pulling in a third vendored repo (bats-file).
assert_file() {
    local path="$1"
    if [ ! -f "$path" ]; then
        echo "expected file to exist: $path" >&2
        return 1
    fi
}

assert_dir() {
    local path="$1"
    if [ ! -d "$path" ]; then
        echo "expected directory to exist: $path" >&2
        return 1
    fi
}

# --- skip helpers ------------------------------------------------------------
# Skip a test if a required binary is missing on PATH.
require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        skip "required command not on PATH: $cmd"
    fi
}

# Skip a test if a required secret file is missing.
require_secret() {
    local path="$1"
    if [ ! -s "${PROJECT_ROOT}/${path}" ]; then
        skip "secret not found: ${path}"
    fi
}

# Wrapper around beeline that reads the password from secrets/.hive.pass.
hive_query() {
    local query="$1"
    local password
    password="$(head -n1 "${PROJECT_ROOT}/secrets/.hive.pass")"
    beeline -u "${HIVE_JDBC}" -n "${HIVE_USER}" -p "${password}" \
        --silent=true --outputformat=csv2 -e "${query}" 2>/dev/null
}

# Wrapper around beeline -f for HQL files.
hive_file() {
    local hql="$1"
    local password
    password="$(head -n1 "${PROJECT_ROOT}/secrets/.hive.pass")"
    beeline -u "${HIVE_JDBC}" -n "${HIVE_USER}" -p "${password}" \
        --silent=true --outputformat=csv2 -f "${hql}" 2>/dev/null
}
