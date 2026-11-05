# 02 — Broken image rollback

**Scenario:** a bad image tag gets deployed through Git.
**You learn:** `Synced` ≠ `Healthy`, how to read pod evidence, and why the fix belongs in Git.

## Break it

Point the Deployment at an image tag that does not exist:

```bash
# in demo-app/k8s/deployment.yaml, change:
#   image: ghcr.io/olessya2907/demo-app:latest
# to:
#   image: ghcr.io/olessya2907/demo-app:does-not-exist
```

```bash
git add demo-app/k8s/deployment.yaml
git commit -m "feat: try new image tag"
git push
```

Argo CD syncs automatically — Git now declares a broken image, so the cluster follows.

## Observe

```bash
kubectl get pods
```

Pods go to `ImagePullBackOff` / `ErrImagePull`. Check the Application status:

```bash
kubectl get applications -n argocd
```

Note the combination: the app is `Synced` (the cluster matches Git) but **not** `Healthy` (the pods cannot run). Sync status answers "does the cluster match Git?"; health answers "does the app actually work?".

## Diagnose

Collect evidence before touching anything:

```bash
kubectl describe pod -l app=demo-app | grep -A5 Events
kubectl get events --sort-by=.lastTimestamp | tail -20
```

The events show the kubelet failing to pull `demo-app:does-not-exist`. Root cause: the image tag in Git is wrong. The responsible layer is the container image, not Kubernetes networking or Argo CD.

## Fix the source of truth

Revert the bad commit — do not patch the cluster with `kubectl set image`:

```bash
git log --oneline -3        # find the bad commit SHA
git revert <BAD_COMMIT_SHA>
git push
```

Argo CD syncs the revert, the Deployment goes back to `:latest`, and the pods return to `Running`.

## Takeaway

`kubectl set image` would fix the pods for about three minutes — then Argo CD would re-apply the broken tag from Git. Durable recovery always goes through Git history.
