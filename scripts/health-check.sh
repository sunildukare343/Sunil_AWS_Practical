
#!/usr/bin/env bash
set -uo pipefail

NAMESPACE="devops-app"
API_DEPLOYMENT="devops-api"
DB_STATEFULSET="postgres"

FAILED=0

check() {
    echo
    echo "===== $1 ====="
    shift

    if "$@"; then
        echo "PASS"
    else
        echo "FAIL"
        FAILED=1
    fi
}

echo "===== EKS APPLICATION HEALTH CHECK ====="

echo
echo "===== NODE STATUS ====="
kubectl get nodes -o wide || FAILED=1

echo
echo "===== POD STATUS ====="
kubectl get pods -n "$NAMESPACE" -o wide || FAILED=1

check "API deployment rollout" \
    kubectl rollout status deployment/"$API_DEPLOYMENT" \
    -n "$NAMESPACE" --timeout=30s

check "PostgreSQL StatefulSet rollout" \
    kubectl rollout status statefulset/"$DB_STATEFULSET" \
    -n "$NAMESPACE" --timeout=30s

echo
echo "===== SERVICE AND ENDPOINT STATUS ====="
kubectl get services,endpoints -n "$NAMESPACE" || FAILED=1

echo
echo "===== API LOGS ====="
kubectl logs deployment/"$API_DEPLOYMENT" \
    -n "$NAMESPACE" --tail=50 || FAILED=1

echo
echo "===== POSTGRESQL LOGS ====="
kubectl logs statefulset/"$DB_STATEFULSET" \
    -n "$NAMESPACE" --tail=50 || FAILED=1

echo
echo "===== RECENT EVENTS ====="
kubectl get events -n "$NAMESPACE" \
    --sort-by='.lastTimestamp' | tail -20 || FAILED=1

echo
if [ "$FAILED" -eq 0 ]; then
    echo "HEALTH CHECK PASSED"
    exit 0
else
    echo "HEALTH CHECK FAILED"
    exit 1
fi
