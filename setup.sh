#!/usr/bin/env bash
# One-command setup for the Kubernetes CI/CD & GitOps Starter Kit.
#
# Installs Argo CD, registers the demo-app Application, and waits until
# the app is running. Run from the repository root.
#
# Usage:
#   ./setup.sh [REPO_URL]
#
# If you forked this repo, pass your fork's URL so Argo CD watches it:
#   ./setup.sh https://github.com/YOUR_USERNAME/argocd-test.git
set -euo pipefail

REPO_URL="${1:-https://github.com/olessya2907/argocd-test.git}"

echo "==> Checking prerequisites..."
command -v kubectl >/dev/null || { echo "ERROR: kubectl not found. Install it: https://kubernetes.io/docs/tasks/tools/"; exit 1; }
kubectl get nodes >/dev/null 2>&1 || { echo "ERROR: no Kubernetes cluster reachable. Start one (e.g. 'minikube start') and retry."; exit 1; }
echo "    kubectl OK, cluster reachable."

echo "==> Installing Argo CD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "    Waiting for Argo CD to become ready (up to 5 min)..."
kubectl wait --for=condition=Available deployment --all -n argocd --timeout=300s

echo "==> Registering demo-app with Argo CD (repo: ${REPO_URL})..."
tmp_manifest="$(mktemp)"
sed "s|repoURL: .*|repoURL: ${REPO_URL}|" argocd-app.yaml > "${tmp_manifest}"
kubectl apply -f "${tmp_manifest}" -n argocd
rm -f "${tmp_manifest}"

echo "==> Waiting for Argo CD to sync and the app to become ready (up to 5 min)..."
for _ in $(seq 1 60); do
  kubectl get deployment demo-app >/dev/null 2>&1 && break
  sleep 5
done
kubectl wait --for=condition=Available deployment/demo-app --timeout=300s

echo ""
echo "Done! The pipeline is live:"
kubectl get pods -l app=demo-app
echo ""
echo "Open the app with:"
echo "  kubectl port-forward svc/demo-app 8080:80"
echo "then visit http://localhost:8080"
