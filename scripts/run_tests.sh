#!/usr/bin/env bash
#
# Manual test runner for project30.
#
# Usage:
#   bash scripts/run_tests.sh                # all suites (unit + smoke)
#   bash scripts/run_tests.sh unit           # only cloud-safe unit tests
#   bash scripts/run_tests.sh smoke          # only cluster smoke tests
#   bash scripts/run_tests.sh smoke 02_postgres   # one suite by prefix
#   bash scripts/run_tests.sh -h | --help
#
# Environment overrides:
#   DASHBOARD_URL=https://...  enable tests/smoke/07_dashboard_ping.bats
#   HIVE_JDBC, HIVE_USER, PG_HOST, PG_DB, PG_USER override defaults
#
# Exit code: 0 if all selected tests pass, non-zero otherwise.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PROJECT_ROOT

BATS="${PROJECT_ROOT}/tests/bats/bats-core/bin/bats"
if [ ! -x "${BATS}" ]; then
    echo "vendored bats not found at ${BATS}" >&2
    exit 2
fi

usage() {
    sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage; exit 0
fi

SUITES_ARG="${1:-all}"
FILTER="${2:-}"

declare -a TARGETS=()
case "${SUITES_ARG}" in
    all)     TARGETS=("unit" "smoke") ;;
    unit)    TARGETS=("unit") ;;
    smoke)   TARGETS=("smoke") ;;
    *) echo "unknown suite: ${SUITES_ARG} (expected: all | unit | smoke)" >&2; exit 2 ;;
esac

# ANSI colours (skip if not a TTY).
if [ -t 1 ]; then
    BOLD=$'\e[1m'; DIM=$'\e[2m'; GREEN=$'\e[32m'; RED=$'\e[31m'; YELLOW=$'\e[33m'; RESET=$'\e[0m'
else
    BOLD=""; DIM=""; GREEN=""; RED=""; YELLOW=""; RESET=""
fi

header() {
    echo
    echo "${BOLD}=== $* ===${RESET}"
}

run_suite() {
    local suite="$1"
    local dir="${PROJECT_ROOT}/tests/${suite}"
    local files=()

    if [ ! -d "$dir" ]; then
        echo "${YELLOW}skip${RESET}: ${dir} not found"
        return 0
    fi

    while IFS= read -r -d '' f; do
        if [ -z "${FILTER}" ] || [[ "$(basename "$f")" == *"${FILTER}"* ]]; then
            files+=("$f")
        fi
    done < <(find "$dir" -maxdepth 1 -name '*.bats' -print0 | sort -z)

    if [ ${#files[@]} -eq 0 ]; then
        echo "${YELLOW}no matching tests in ${dir}${RESET}"
        return 0
    fi

    header "Running ${suite} suite (${#files[@]} file(s))"
    "${BATS}" --print-output-on-failure "${files[@]}"
}

overall=0
for s in "${TARGETS[@]}"; do
    if ! run_suite "$s"; then
        overall=$?
    fi
done

echo
if [ "${overall}" -eq 0 ]; then
    echo "${GREEN}${BOLD}All selected tests passed.${RESET}"
else
    echo "${RED}${BOLD}Some tests failed (exit ${overall}).${RESET}"
fi
exit "${overall}"
