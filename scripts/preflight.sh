#!/usr/bin/env bash
set -u

fail=0

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf "[OK]   %-12s %s\n" "$cmd" "$($cmd --version 2>/dev/null | head -n 1)"
  else
    printf "[FAIL] %-12s not found\n" "$cmd"
    fail=1
  fi
}

echo "=== Argo CD Lab Preflight ==="
check_cmd git
check_cmd kubectl

if command -v docker >/dev/null 2>&1; then
  echo "[OK]   docker       $(docker --version 2>/dev/null)"
else
  echo "[INFO] docker       not found (okay if your Kubernetes does not require it)"
fi

echo
echo "=== Kubernetes context ==="
if kubectl config current-context >/dev/null 2>&1; then
  kubectl config current-context
else
  echo "[FAIL] No usable kubectl context"
  fail=1
fi

echo
echo "=== Kubernetes nodes ==="
if kubectl get nodes; then
  :
else
  echo "[FAIL] Kubernetes API is not reachable"
  fail=1
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "PRECHECK RESULT: PASS"
else
  echo "PRECHECK RESULT: FAIL"
  exit 1
fi
