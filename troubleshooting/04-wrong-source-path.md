# 04 — Wrong source path

**Scenario:** the Argo CD Application points at a path that does not exist.
**You learn:** how to diagnose a sync failure and tell which layer is responsible.

## Break it

Introduce a typo into the Application's source path:

```bash
# in argocd-app.yaml, change:
#   path: demo-app/k8s
# to:
#   path: demo-app/k8   # <- typo
```

```bash
kubectl apply -f argocd-app.yaml -n argocd
```

## Observe

```bash
kubectl get applications -n argocd
```

The `demo-app` Application reports an error / `OutOfSync` state and the sync cannot complete. Inspect the details:

```bash
kubectl describe application demo-app -n argocd
```

Look at `Status.Conditions` — Argo CD reports that the repository path cannot be resolved. The manifests themselves are fine; the problem is one level up, in the Application definition.

## Diagnose by layer

When a sync fails, narrow it down in order:

1. **Repository access** — can Argo CD read the repo at all? (Here yes: other paths resolve, and the error names the path.)
2. **Manifest generation** — are the YAML files valid? (Untouched in this scenario.)
3. **Synchronization** — this is where it fails: the declared `path` does not exist in the repo.
4. **Kubernetes runtime / application runtime** — not reached; nothing was applied.

## Fix it

```bash
# in argocd-app.yaml, restore:
#   path: demo-app/k8s
```

```bash
kubectl apply -f argocd-app.yaml -n argocd
kubectl get applications -n argocd   # back to Synced / Healthy
```

## Takeaway

Most "Argo CD is broken" incidents are configuration errors in the Application resource, not platform failures. Read the status conditions first — they usually name the exact layer.
