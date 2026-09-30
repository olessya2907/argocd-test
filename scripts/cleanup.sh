#!/usr/bin/env bash
set -e

echo "Deleting demo application..."
kubectl delete application gitops-demo -n argocd --ignore-not-found=true

echo "Deleting demo namespace..."
kubectl delete namespace argocd-demo --ignore-not-found=true

echo
echo "Argo CD itself was left installed."
echo "To remove it too, run:"
echo "  kubectl delete namespace argocd"
