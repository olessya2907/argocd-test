#!/usr/bin/env bash
# One-command cleanup for the Kubernetes CI/CD & GitOps Starter Kit.
# Removes the demo app; optionally removes Argo CD as well.
# Run from the repository root.
set -euo pipefail

echo "==> Removing demo-app Application from Argo CD..."
kubectl delete -f argocd-app.yaml -n argocd --ignore-not-found

echo "==> Removing demo-app resources from the cluster..."
kubectl delete -f demo-app/k8s/ --ignore-not-found

read -r -p "Remove Argo CD itself? [y/N] " answer
if [[ "${answer}" =~ ^[Yy]$ ]]; then
  echo "==> Removing Argo CD..."
  kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --ignore-not-found
  kubectl delete namespace argocd --ignore-not-found
fi

echo ""
echo "Cleanup done."
