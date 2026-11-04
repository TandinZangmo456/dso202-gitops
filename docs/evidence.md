# DSO202 Assignment 4: Evidence

Every block below shows a command that was run on my laptop (Pop!_OS, x86_64)
and its real output, copied by a small script that appends each command and its
output to this file. Nothing is edited. No password, key or Secret value is
recorded here.

## Task 1

### Tool check (section 3.2)

```text
$ docker version --format '{{.Server.Version}}'
28.5.1
```

```text
$ kind version
kind v0.32.0 go1.26.3 linux/amd64
```

```text
$ kubectl version --client
Client Version: v1.34.1
Kustomize Version: v5.7.1
```

```text
$ helm version --short
v4.3.0+gbec5b06
```

```text
$ git --version
git version 2.34.1
```

```text
$ argocd version --client
argocd: v3.5.6
  BuildDate: 2026-10-20T18:33:20Z
  GitCommit: c2b1e3017e2cec86b122172e861dcd026453ae44
  GitTreeState: clean
  GitTag: v3.5.6
  GoVersion: go1.26.10
  Compiler: gc
  Platform: linux/amd64
```

```text
$ kubeseal --version
kubeseal version: 0.40.0
```

```text
$ helm repo add sealed-secrets https://bitnami.github.io/sealed-secrets
"sealed-secrets" already exists with the same configuration, skipping
```

```text
$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "podinfo" chart repository
...Successfully got an update from the "sealed-secrets" chart repository
...Successfully got an update from the "kong" chart repository
...Successfully got an update from the "hashicorp" chart repository
...Successfully got an update from the "argo" chart repository
Update Complete. ⎈Happy Helming!⎈
```

```text
$ helm search repo sealed-secrets/sealed-secrets --versions | head -5
NAME                         	CHART VERSION	APP VERSION	DESCRIPTION                                  
sealed-secrets/sealed-secrets	2.22.0       	0.41.2     	Helm chart for the sealed-secrets controller.
sealed-secrets/sealed-secrets	2.21.0       	0.41.2     	Helm chart for the sealed-secrets controller.
sealed-secrets/sealed-secrets	2.20.0       	0.40.0     	Helm chart for the sealed-secrets controller.
sealed-secrets/sealed-secrets	2.19.3       	0.39.1     	Helm chart for the sealed-secrets controller.
```

### Cluster (step 7)

```text
$ kind get clusters
No kind clusters found.
```

```text
$ kind create cluster --name dso202-gitops --config cluster/kind-cluster.yaml
Creating cluster "dso202-gitops" ...
 • Ensuring node image (kindest/node:v1.36.1) 🖼  ...
 ✓ Ensuring node image (kindest/node:v1.36.1) 🖼
 • Preparing nodes 📦 📦 📦   ...
 ✓ Preparing nodes 📦 📦 📦 
 • Writing configuration 📜  ...
 ✓ Writing configuration 📜
 • Starting control-plane 🕹️  ...
 ✓ Starting control-plane 🕹️
 • Installing CNI 🔌  ...
 ✓ Installing CNI 🔌
 • Installing StorageClass 💾  ...
 ✓ Installing StorageClass 💾
 • Joining worker nodes 🚜  ...
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-dso202-gitops"
You can now use your cluster with:

kubectl cluster-info --context kind-dso202-gitops

Thanks for using kind! 😊
```

```text
$ kubectl config current-context
kind-dso202-gitops
```

```text
$ kubectl get nodes
NAME            STATUS     ROLES           AGE   VERSION
control-plane   NotReady   control-plane   11s   v1.36.1
worker-node-1   NotReady   <none>          0s    v1.36.1
worker-node-2   NotReady   <none>          1s    v1.36.1
```

```text
$ docker ps --filter name=dso202-gitops --format '{{.Names}}   {{.Ports}}'
dso202-gitops-worker2   
dso202-gitops-control-plane   127.0.0.1:30080->30080/tcp, 127.0.0.1:36331->6443/tcp
dso202-gitops-worker   
```

The first `kubectl get nodes` ran straight after creation, before the CNI was ready, so the nodes were still `NotReady`. Run again after `kubectl wait --for=condition=Ready nodes --all`:

```text
$ kubectl get nodes -o wide
NAME            STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION                    CONTAINER-RUNTIME
control-plane   Ready    control-plane   24s   v1.36.1   172.23.0.4    <none>        Debian GNU/Linux 13 (trixie)   6.16.3-76061603-generic (amd64)   containerd://2.3.1
worker-node-1   Ready    <none>          13s   v1.36.1   172.23.0.2    <none>        Debian GNU/Linux 13 (trixie)   6.16.3-76061603-generic (amd64)   containerd://2.3.1
worker-node-2   Ready    <none>          14s   v1.36.1   172.23.0.3    <none>        Debian GNU/Linux 13 (trixie)   6.16.3-76061603-generic (amd64)   containerd://2.3.1
```

### Chart checks (step 6)

```text
$ helm lint charts/tasktracker -f environments/dev/values.yaml
==> Linting charts/tasktracker
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

```text
$ helm lint charts/tasktracker -f environments/staging/values.yaml
==> Linting charts/tasktracker
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

```text
$ helm template tasktracker charts/tasktracker -f environments/dev/values.yaml | grep '^kind:' | sort | uniq -c
      1 kind: ConfigMap
      3 kind: Deployment
      1 kind: PersistentVolumeClaim
      3 kind: Service
```

```text
$ helm template tasktracker charts/tasktracker -f environments/staging/values.yaml | grep '^kind:' | sort | uniq -c
      1 kind: ConfigMap
      3 kind: Deployment
      1 kind: PersistentVolumeClaim
      3 kind: Service
```

```text
$ helm template tasktracker charts/tasktracker -f environments/dev/values.yaml | grep -E 'image:|sync-wave|progressDeadlineSeconds|path: /api/status|nodePort:|name: tasktracker-credentials' | sed 's/^ *//' | sort | uniq -c
      1 argocd.argoproj.io/sync-wave: "0"
      1 argocd.argoproj.io/sync-wave: "1"
      1 argocd.argoproj.io/sync-wave: "2"
      1 image: "penguintandinzangmo/dso202-backend:1.0"
      1 image: "penguintandinzangmo/dso202-db:1.0"
      1 image: "penguintandinzangmo/dso202-frontend:1.0"
      4 name: tasktracker-credentials
      1 nodePort: 30080
      1 path: /api/status
      2 progressDeadlineSeconds: 120
```

### Chart contract (step 4)

Starting point: the Assignment 3 chart, imported unchanged in commit "Import the
Assignment 3 Helm chart unchanged". Each change after that is its own commit.

| # | Requirement | Where it is satisfied |
| --- | --- | --- |
| C1 | Image repository and tag are values per tier | `charts/tasktracker/values.yaml`: `database.image`, `backend.image`, `frontend.image` (`repository`, `tag`); `templates/_helpers.tpl` `tasktracker.image` uses `required` on the tier tag, no `appVersion` fallback; tags set in `environments/<env>/values.yaml` |
| C2 | Per-tier configuration from values | `values.yaml` `<tier>.extraEnv` (list of name/value), rendered in each `templates/*-deployment.yaml` with `toYaml` |
| C3 | No Secret rendered; `existingSecret` | `templates/secret.yaml` deleted; `values.yaml` `credentials.existingSecret: tasktracker-credentials` (also set in both environment files); `_helpers.tpl` `tasktracker.secretName` |
| C4 | Readiness probes on all tiers | `values.yaml` `<tier>.readinessProbe` (backend `httpGet /api/status`, frontend `httpGet /`, database `pg_isready`), rendered in each Deployment template |
| C5 | Sync waves db 0, backend 1, frontend 2 | `metadata.annotations` in `templates/db-deployment.yaml`, `backend-deployment.yaml`, `frontend-deployment.yaml` |
| C6 | `progressDeadlineSeconds: 120` | `spec` of `templates/backend-deployment.yaml` and `templates/frontend-deployment.yaml` |
| C7 | Requests and limits on every container | `values.yaml` `<tier>.resources`; the smoke-test Job (Task 5) sets its own |
| C8 | No Namespace, ResourceQuota, LimitRange, Role, RoleBinding | `templates/governance.yaml` deleted; these objects are in `platform/<env>/` |
| C9 | Ingress disabled by default | The chart has no Ingress template |
| C10 | Frontend NodePort, port as a value | `templates/frontend-service.yaml` `type: NodePort`; `frontend.service.nodePort` 30080 (dev) and 30081 (staging) |
| C11 | `helm lint` clean, `helm template` works for both | Output above |

Other changes: the chart was renamed from `task-tracker` to `tasktracker`, so
objects are named `tasktracker-db`, `tasktracker-backend`, `tasktracker-frontend`;
the `helm test` Pod was removed because the PostSync smoke-test Job replaces it;
the values schema now allows `dev` and `staging`.

Kinds rendered (needed for the Task 3 whitelist): ConfigMap, Deployment,
PersistentVolumeClaim, Service. The smoke-test Job is added in Task 5.

