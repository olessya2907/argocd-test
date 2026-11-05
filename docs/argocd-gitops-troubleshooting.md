# Argo CD GitOps Troubleshooting Lab

## Goal

In this lab you will use Git as the desired state for a Kubernetes application.

You will:

- install Argo CD;
- deploy an application from Git;
- enable automated synchronization;
- create configuration drift manually;
- observe Argo CD self-healing;
- deploy a valid but broken configuration;
- troubleshoot it using Argo CD and Kubernetes evidence;
- recover by fixing Git instead of patching the cluster.

The important mental model is:

```text
Git = Desired State
Kubernetes = Live State
Argo CD = Reconciliation
```

---

## 0. Requirements

You need:

- Git
- Docker, if your local Kubernetes distribution needs it
- `kubectl`
- a running Kubernetes cluster
- a GitHub account
- this repository copied to your own GitHub account

Supported local clusters include Docker Desktop Kubernetes, kind, and minikube.

### Preflight

Linux/macOS:

```bash
chmod +x scripts/preflight.sh
./scripts/preflight.sh
```

Do not continue until `kubectl get nodes` works and at least one node is `Ready`.

---

# PART 1 - Install Argo CD

Create the namespace:

```bash
kubectl create namespace argocd
```

Install Argo CD v3.5.3:

```bash
kubectl apply \
  -n argocd \
  --server-side \
  --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.3/manifests/install.yaml
```

Wait for the deployments:

```bash
kubectl wait \
  --for=condition=Available \
  deployment \
  --all \
  -n argocd \
  --timeout=300s
```

Inspect the components:

```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

## Question

Why can you not normally open the `argocd-server` ClusterIP directly from your
browser?

Do not continue until you can explain the role of a Kubernetes `ClusterIP`.

---

# PART 2 - Open the Argo CD UI

Start a port-forward in a separate terminal:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open:

```text
https://localhost:8080
```

The local installation uses a self-signed certificate, so your browser may display
a certificate warning.

Username:

```text
admin
```

Get the initial password:

```bash
kubectl -n argocd \
  get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo
```

Log in.

---

# PART 3 - Connect Git to Argo CD

Open:

```text
argocd-lab/bootstrap/application.yaml
```

Replace:

```text
https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
```

with your repository URL.

Example:

```text
https://github.com/alice/devops-gitops-lab.git
```

For this classroom lab, a public repository is recommended.

Commit the change:

```bash
git add argocd-lab/bootstrap/application.yaml
git commit -m "chore: configure Argo CD application source"
git push
```

Before the next command, answer:

> Will this Git push alone create anything in Kubernetes?

Now bootstrap the Argo CD Application:

```bash
kubectl apply -f argocd-lab/bootstrap/application.yaml
```

Check:

```bash
kubectl get applications -n argocd
```

Open the application in the Argo CD UI.

It should initially be:

```text
OutOfSync
```

## Question

Is `OutOfSync` automatically an error?

Explain what Argo CD is comparing.

---

# PART 4 - First deployment

In Argo CD:

1. Open `gitops-demo`.
2. Inspect the resource tree.
3. Click **SYNC**.
4. Review the resources.
5. Click **SYNCHRONIZE**.

Verify from the CLI:

```bash
kubectl get all -n argocd-demo
```

You should have:

- one Deployment;
- two Pods;
- one Service.

Open the application in another terminal:

```bash
kubectl port-forward -n argocd-demo svc/gitops-demo 8081:80
```

Open:

```text
http://localhost:8081
```

Expected page:

```text
Argo CD GitOps Lab
Application version: v1
Managed from Git.
```

---

# PART 5 - Turn on automated delivery

Open:

```text
argocd-lab/bootstrap/application.yaml
```

Change the sync policy to:

```yaml
syncPolicy:
  automated:
    enabled: true
    prune: true
    selfHeal: false
  syncOptions:
    - CreateNamespace=true
```

Apply the Argo CD Application configuration:

```bash
kubectl apply -f argocd-lab/bootstrap/application.yaml
```

We intentionally start with:

```yaml
selfHeal: false
```

Do not change it yet.

---

# PART 6 - Deploy version v2 through Git

Open:

```text
argocd-lab/manifests/deployment.yaml
```

Change:

```yaml
value: "v1"
```

to:

```yaml
value: "v2"
```

Before committing, inspect the diff:

```bash
git diff
```

Answer before pushing:

> Which Kubernetes resource should change, and why should Kubernetes replace the Pods?

Commit:

```bash
git add argocd-lab/manifests/deployment.yaml
git commit -m "feat: deploy application v2"
git push
```

In Argo CD, click **Refresh**.

Observe the rollout:

```bash
kubectl get pods -n argocd-demo -w
```

Refresh:

```text
http://localhost:8081
```

Expected result:

```text
Application version: v2
```

## Important distinction

Be ready to explain the difference between:

```text
Refresh
```

and:

```text
Sync
```

---

# INCIDENT 1 - Somebody changed production

An engineer decides not to use Git:

```bash
kubectl scale \
  deployment gitops-demo \
  -n argocd-demo \
  --replicas=5
```

Check:

```bash
kubectl get deployment gitops-demo -n argocd-demo
```

Now inspect Argo CD.

## Your task

Without changing anything yet, determine:

1. What does Git say the replica count should be?
2. What does Kubernetes currently have?
3. What status does Argo CD show?
4. Why has Argo CD not automatically returned the Deployment to two replicas?

Use the Argo CD **Diff** view as evidence.

---

## Enable self-healing

Only after discussing Incident 1, change:

```yaml
selfHeal: false
```

to:

```yaml
selfHeal: true
```

Apply:

```bash
kubectl apply -f argocd-lab/bootstrap/application.yaml
```

Now repeat the unauthorized change:

```bash
kubectl scale \
  deployment gitops-demo \
  -n argocd-demo \
  --replicas=5
```

Watch:

```bash
kubectl get deployment gitops-demo -n argocd-demo
```

Repeat the command a few times if necessary.

Record what happens.

## Question

Kubernetes accepted your `kubectl scale` command. Why did the change disappear?

---

# INCIDENT 2 - Git broke production

Open:

```text
argocd-lab/manifests/deployment.yaml
```

Change:

```yaml
image: nginx:1.27-alpine
```

to:

```yaml
image: nginx:9.9.9-does-not-exist
```

Do not test the image manually.

Commit the change:

```bash
git add argocd-lab/manifests/deployment.yaml
git commit -m "feat: upgrade nginx version"
git push
```

Click **Refresh** in Argo CD.

Wait and inspect the application.

## Your task

Treat this as a production incident.

Do not immediately edit anything.

Find evidence for the root cause.

Use this troubleshooting sequence:

```text
1. Observe
2. Form a hypothesis
3. Collect evidence
4. Identify the responsible layer
5. Fix the source of truth
6. Verify recovery
```

Useful commands may include:

```bash
kubectl get pods -n argocd-demo
```

```bash
kubectl describe pod -n argocd-demo POD_NAME
```

```bash
kubectl get events \
  -n argocd-demo \
  --sort-by=.lastTimestamp
```

### Questions

1. Is Argo CD `Synced` or `OutOfSync`?
2. Is the application `Healthy`?
3. What is the Pod status?
4. Which evidence proves the root cause?
5. Would `kubectl set image` be a durable GitOps fix?

Do not continue until you can explain:

```text
Synced != Healthy
```

---

# PART 7 - Recover correctly

Inspect your recent commits:

```bash
git log --oneline -5
```

Identify the bad image commit.

Revert it:

```bash
git revert BAD_COMMIT_SHA
git push
```

Click **Refresh** in Argo CD.

Watch the recovery:

```bash
kubectl get pods -n argocd-demo -w
```

Verify:

```bash
kubectl get deployment -n argocd-demo
kubectl get pods -n argocd-demo
```

Expected final state:

```text
Synced
Healthy
```

and the browser application works again.

---

# OPTIONAL INCIDENT 3 - Prune

Check the training ConfigMap:

```bash
kubectl get configmap lab-marker -n argocd-demo
```

Delete its manifest from Git:

```bash
git rm argocd-lab/manifests/lab-marker.yaml
git commit -m "chore: remove obsolete lab marker"
git push
```

Click **Refresh**.

Check again:

```bash
kubectl get configmap lab-marker -n argocd-demo
```

## Question

Why did a Git file deletion cause a live Kubernetes resource to disappear?

Which Argo CD option enabled this behavior?

---

# OPTIONAL INCIDENT 4 - Wrong path

Change the Argo CD Application source path from:

```yaml
path: argocd-lab/manifests
```

to:

```yaml
path: argocd-lab/manifest
```

Apply it:

```bash
kubectl apply -f argocd-lab/bootstrap/application.yaml
```

Troubleshoot without being told the answer.

Decide whether the failure is primarily:

- repository access;
- manifest generation;
- synchronization;
- Kubernetes runtime;
- application runtime.

Restore the correct path when finished.

---

# Final check

You should be able to explain these without memorizing commands:

| Concept | Meaning |
|---|---|
| Desired state | What Git declares should exist |
| Live state | What currently exists in Kubernetes |
| OutOfSync | Desired and live state differ |
| Sync | Make Kubernetes match Git |
| Refresh | Re-read/recompare sources and live state |
| Auto Sync | Automatically sync when desired state changes |
| Self Heal | Correct live-cluster drift |
| Prune | Remove managed resources removed from desired state |
| Healthy | Workload health, not merely configuration equality |

---

# AI usage rule for this lab

AI is allowed.

Before executing an AI-generated troubleshooting command, state:

1. Which layer am I investigating?
2. What should this command tell me?
3. What result would confirm or reject my hypothesis?

The goal is not command memorization.

The goal is to know **what evidence you need next**.

---

# Cleanup

Linux/macOS:

```bash
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh
```
