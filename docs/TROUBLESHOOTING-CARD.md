# GitOps Troubleshooting Card

Use this order instead of randomly running commands.

```text
Something is wrong
        |
        v
Can Argo read the repository?
        |
   +----+----+
   |         |
  NO        YES
   |         |
repo/auth    v
         Can manifests render?
             |
        +----+----+
        |         |
       NO        YES
        |         |
 YAML/Helm/Kustomize
                  |
                  v
             Is it Synced?
                |
           +----+----+
           |         |
          NO        YES
           |         |
       inspect Diff  v
                 Is it Healthy?
                    |
               +----+----+
               |         |
              NO        YES
               |         |
          inspect K8s    done
          resources,
          Pods, Events
```

## Evidence ladder

Start high level:

```bash
kubectl get applications -n argocd
```

Then workload:

```bash
kubectl get deployment,pods,svc -n argocd-demo
```

Then inspect one failing resource:

```bash
kubectl describe pod -n argocd-demo POD_NAME
```

Then events:

```bash
kubectl get events -n argocd-demo --sort-by=.lastTimestamp
```

## Do not confuse

```text
Synced
```

with:

```text
Healthy
```

A deployment may perfectly match Git and still be broken.
