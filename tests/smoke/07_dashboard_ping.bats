#!/usr/bin/env bats
#
# Layer 4 (Dashboard) — public Superset URL is reachable without SSO.
# Set DASHBOARD_URL when invoking run_tests.sh to enable.

load "${BATS_TEST_DIRNAME}/../helpers/common.bash"

setup() {
    [ -n "${DASHBOARD_URL}" ] || skip "DASHBOARD_URL not set"
    require_cmd curl
}

@test "public dashboard returns HTTP 200 anonymously" {
    run curl -sS -o /dev/null -w "%{http_code}" --max-time 10 "${DASHBOARD_URL}"
    assert_success
    [ "$output" = "200" ]
}
