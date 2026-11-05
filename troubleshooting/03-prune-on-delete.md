# 03 — Prune on delete

**Scenario:** a manifest is removed from Git.
**You learn:** how `prune: true` keeps the cluster free of orphaned resources.

## Set it up

Create a throwaway ConfigMap manifest so there is something safe to delete:

```yaml
# demo-app/k8s/configmap-demo.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-marker
data:
  note: "delete me via Git to see pruning"
```

```bash
git add demo-app/k8s/configmap-demo.yaml
git commit -m "chore: add demo marker configmap"
git push
```

Verify it exists in the cluster:

```bash
kubectl get configmap demo-marker
```

## Break it (the GitOps way)

Delete the file from Git — not from the cluster:

```bash
git rm demo-app/k8s/configmap-demo.yaml
git commit -m "chore: remove demo marker configmap"
git push
```

Do **not** run `kubectl delete configmap`.

## Observe

```bash
kubectl get configmap demo-marker
```

The ConfigMap is gone from the cluster, even though nobody deleted it with `kubectl`. Argo CD's `prune: true` removed the live resource because its manifest disappeared from the desired state.

## Why it matters

Without pruning, deleted manifests leave orphaned resources behind — old ConfigMaps, Services, even Deployments pile up over months. With pruning, Git remains the complete inventory: what is not in Git does not exist in the cluster.

## Takeaway

Deletion is a deployment too. In GitOps you delete by removing the manifest and pushing, and the platform does the rest.
