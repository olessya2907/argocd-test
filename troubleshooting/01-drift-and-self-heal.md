# 01 — Drift and self-heal

**Scenario:** someone changes the cluster by hand, bypassing Git.
**You learn:** desired state vs live state, and why manual fixes do not stick.

## Break it

Scale the Deployment directly, without touching Git:

```bash
kubectl scale deployment demo-app --replicas=5
```

## Observe

```bash
kubectl get deployment demo-app
kubectl get pods
```

The Deployment now wants 5 replicas, and extra pods appear. Now check Argo CD:

```bash
kubectl get applications -n argocd
```

The `demo-app` Application turns `OutOfSync` — Git still declares `replicas: 2`, but the cluster has 5.

## Watch the recovery

This repo's Application enables `selfHeal: true`, so do nothing and keep watching:

```bash
kubectl get deployment demo-app -w
```

Within a couple of minutes Argo CD reverts the replica count to 2 and the extra pods terminate. Nobody ran `kubectl scale` back — Argo CD did it.

## Why it happened

- **Desired state** (Git, `demo-app/k8s/deployment.yaml`): `replicas: 2`.
- **Live state** (cluster): someone set 5.
- Argo CD compares the two on every reconciliation loop and enforces the desired state.

## Takeaway

In a GitOps workflow the cluster is read-only for humans. The only durable fix is a Git commit — hand edits are reverted by design.
