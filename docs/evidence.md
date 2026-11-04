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

## Task 2

### Render checks (step 2)

```text
$ kubectl kustomize bootstrap/argocd | grep -E '^kind: (Deployment|StatefulSet)$' | sort | uniq -c
      6 kind: Deployment
      1 kind: StatefulSet
```

```text
$ kubectl kustomize bootstrap/argocd | grep 'image:' | sort -u
        image: ghcr.io/dexidp/dex:v2.45.1
        image: public.ecr.aws/docker/library/redis:8.2.3-alpine
        image: quay.io/argoproj/argocd:v3.5.6
```

```text
$ kubectl kustomize bootstrap/argocd | grep -E '^  namespace:' | sort | uniq -c
     59   namespace: argocd
```

### Apply (step 3)

```text
$ kubectl apply -k bootstrap/argocd --server-side --force-conflicts
namespace/argocd serverside-applied
customresourcedefinition.apiextensions.k8s.io/applications.argoproj.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/applicationsets.argoproj.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/appprojects.argoproj.io serverside-applied
serviceaccount/argocd-application-controller serverside-applied
serviceaccount/argocd-applicationset-controller serverside-applied
serviceaccount/argocd-dex-server serverside-applied
serviceaccount/argocd-notifications-controller serverside-applied
serviceaccount/argocd-redis serverside-applied
serviceaccount/argocd-repo-server serverside-applied
serviceaccount/argocd-server serverside-applied
role.rbac.authorization.k8s.io/argocd-application-controller serverside-applied
role.rbac.authorization.k8s.io/argocd-applicationset-controller serverside-applied
role.rbac.authorization.k8s.io/argocd-dex-server serverside-applied
role.rbac.authorization.k8s.io/argocd-notifications-controller serverside-applied
role.rbac.authorization.k8s.io/argocd-redis serverside-applied
role.rbac.authorization.k8s.io/argocd-server serverside-applied
clusterrole.rbac.authorization.k8s.io/argocd-application-controller serverside-applied
clusterrole.rbac.authorization.k8s.io/argocd-applicationset-controller serverside-applied
clusterrole.rbac.authorization.k8s.io/argocd-server serverside-applied
rolebinding.rbac.authorization.k8s.io/argocd-application-controller serverside-applied
rolebinding.rbac.authorization.k8s.io/argocd-applicationset-controller serverside-applied
rolebinding.rbac.authorization.k8s.io/argocd-dex-server serverside-applied
rolebinding.rbac.authorization.k8s.io/argocd-notifications-controller serverside-applied
rolebinding.rbac.authorization.k8s.io/argocd-redis serverside-applied
rolebinding.rbac.authorization.k8s.io/argocd-server serverside-applied
clusterrolebinding.rbac.authorization.k8s.io/argocd-application-controller serverside-applied
clusterrolebinding.rbac.authorization.k8s.io/argocd-applicationset-controller serverside-applied
clusterrolebinding.rbac.authorization.k8s.io/argocd-server serverside-applied
configmap/argocd-cm serverside-applied
configmap/argocd-cmd-params-cm serverside-applied
configmap/argocd-gpg-keys-cm serverside-applied
configmap/argocd-notifications-cm serverside-applied
configmap/argocd-rbac-cm serverside-applied
configmap/argocd-ssh-known-hosts-cm serverside-applied
configmap/argocd-tls-certs-cm serverside-applied
secret/argocd-notifications-secret serverside-applied
secret/argocd-secret serverside-applied
service/argocd-applicationset-controller serverside-applied
service/argocd-dex-server serverside-applied
service/argocd-metrics serverside-applied
service/argocd-notifications-controller-metrics serverside-applied
service/argocd-redis serverside-applied
service/argocd-repo-server serverside-applied
service/argocd-server serverside-applied
service/argocd-server-metrics serverside-applied
deployment.apps/argocd-applicationset-controller serverside-applied
deployment.apps/argocd-dex-server serverside-applied
deployment.apps/argocd-notifications-controller serverside-applied
deployment.apps/argocd-redis serverside-applied
deployment.apps/argocd-repo-server serverside-applied
deployment.apps/argocd-server serverside-applied
statefulset.apps/argocd-application-controller serverside-applied
networkpolicy.networking.k8s.io/argocd-application-controller-network-policy serverside-applied
networkpolicy.networking.k8s.io/argocd-applicationset-controller-network-policy serverside-applied
networkpolicy.networking.k8s.io/argocd-dex-server-network-policy serverside-applied
networkpolicy.networking.k8s.io/argocd-notifications-controller-network-policy serverside-applied
networkpolicy.networking.k8s.io/argocd-redis-network-policy serverside-applied
networkpolicy.networking.k8s.io/argocd-repo-server-network-policy serverside-applied
networkpolicy.networking.k8s.io/argocd-server-network-policy serverside-applied
```

### Wait for components (step 4)

```text
$ kubectl wait --for=condition=Available deployment --all -n argocd --timeout=300s
deployment.apps/argocd-applicationset-controller condition met
deployment.apps/argocd-dex-server condition met
deployment.apps/argocd-notifications-controller condition met
deployment.apps/argocd-redis condition met
timed out waiting for the condition on deployments/argocd-repo-server
timed out waiting for the condition on deployments/argocd-server
```

```text
$ kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=300s
partitioned roll out complete: 1 new pods have been updated...
```

```text
$ kubectl get pods -n argocd
NAME                                                READY   STATUS             RESTARTS      AGE
argocd-application-controller-0                     1/1     Running            0             5m7s
argocd-applicationset-controller-58bb5c7479-lb67f   1/1     Running            0             5m7s
argocd-dex-server-dd6b85d9c-jc4pd                   0/1     Error              3 (75s ago)   5m7s
argocd-notifications-controller-6b85c65458-c6v7s    1/1     Running            0             5m7s
argocd-redis-869b85489d-2njct                       1/1     Running            0             5m7s
argocd-repo-server-5bf66565cd-f74df                 0/1     CrashLoopBackOff   4 (4s ago)    5m7s
argocd-server-7474bb8f76-dbbxk                      1/1     Running            0             5m7s
```

```text
$ kubectl get crd | grep argoproj.io
applications.argoproj.io      2026-11-04T17:06:22Z
applicationsets.argoproj.io   2026-11-04T17:06:23Z
appprojects.argoproj.io       2026-11-04T17:06:23Z
```

The first wait failed: `argocd-repo-server` and `argocd-server` timed out, and dex was restarting. The laptop disk had filled up (0 bytes free). The repo-server log showed the cause:

```text
$ kubectl logs -n argocd deploy/argocd-repo-server --previous --tail=5
Defaulted container "argocd-repo-server" out of: argocd-repo-server, copyutil (init)
{"built":"2026-10-20T18:33:20Z","commit":"c2b1e3017e2cec86b122172e861dcd026453ae44","level":"info","msg":"ArgoCD Repository Server is starting","port":8081,"time":"2026-11-04T17:13:03Z","version":"v3.5.6"}
{"level":"info","msg":"Loading Redis credentials from environment variables","time":"2026-11-04T17:13:03Z"}
{"level":"info","msg":"Generating self-signed TLS certificate for this session","time":"2026-11-04T17:13:03Z"}
{"level":"fatal","msg":"failed to initialize the repo service: mkdir /tmp/_argocd-repo: no space left on device","time":"2026-11-04T17:13:03Z"}
```

I freed about 17 GB (old Docker images and rebuildable caches, with my approval) and ran the wait again. No change was made to the cluster or the repository.

```text
$ kubectl wait --for=condition=Available deployment --all -n argocd --timeout=300s
deployment.apps/argocd-applicationset-controller condition met
deployment.apps/argocd-dex-server condition met
deployment.apps/argocd-notifications-controller condition met
deployment.apps/argocd-redis condition met
deployment.apps/argocd-repo-server condition met
deployment.apps/argocd-server condition met
```

```text
$ kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=300s
partitioned roll out complete: 1 new pods have been updated...
```

```text
$ kubectl get pods -n argocd
NAME                                                READY   STATUS    RESTARTS        AGE
argocd-application-controller-0                     1/1     Running   0               9m55s
argocd-applicationset-controller-58bb5c7479-lb67f   1/1     Running   0               9m55s
argocd-dex-server-dd6b85d9c-jc4pd                   1/1     Running   6 (3m9s ago)    9m55s
argocd-notifications-controller-6b85c65458-c6v7s    1/1     Running   0               9m55s
argocd-redis-869b85489d-2njct                       1/1     Running   0               9m55s
argocd-repo-server-5bf66565cd-f74df                 1/1     Running   6 (3m15s ago)   9m55s
argocd-server-7474bb8f76-dbbxk                      1/1     Running   0               9m55s
```

```text
$ kubectl get crd | grep argoproj.io
applications.argoproj.io      2026-11-04T17:06:22Z
applicationsets.argoproj.io   2026-11-04T17:06:23Z
appprojects.argoproj.io       2026-11-04T17:06:23Z
```

### Sign-in and settings (steps 5 and 6)

The port-forward ran in its own terminal. I printed the initial admin password and ran `argocd login` myself in my own terminal, so neither the password nor the login prompt is recorded here. Check that the CLI is signed in:

```text
$ argocd account get-user-info
{"level":"fatal","msg":"Argo CD server address unspecified","time":"2026-11-05T00:19:55+06:00"}
```

```text
$ kubectl get configmap argocd-cm -n argocd -o yaml | grep -E 'timeout.reconciliation|accounts.reviewer'
  accounts.reviewer: login
  timeout.reconciliation: 60s
  timeout.reconciliation.jitter: 10s
```

```text
$ argocd version
argocd: v3.5.6
  BuildDate: 2026-10-20T18:33:20Z
  GitCommit: c2b1e3017e2cec86b122172e861dcd026453ae44
  GitTreeState: clean
  GitTag: v3.5.6
  GoVersion: go1.26.10
  Compiler: gc
  Platform: linux/amd64
{"level":"fatal","msg":"Argo CD server address unspecified","time":"2026-11-05T00:19:55+06:00"}
```

The `argocd account get-user-info` above failed because my `argocd login` had not finished yet (the password prompt was still waiting). After I completed the login in my own terminal (it printed `'admin:login' logged in successfully`), I ran the checks again:

```text
$ argocd account get-user-info
Logged In: true
Username: admin
Issuer: argocd
Groups: 
```

```text
$ argocd version
argocd: v3.5.6
  BuildDate: 2026-10-20T18:33:20Z
  GitCommit: c2b1e3017e2cec86b122172e861dcd026453ae44
  GitTreeState: clean
  GitTag: v3.5.6
  GoVersion: go1.26.10
  Compiler: gc
  Platform: linux/amd64
argocd-server: v3.5.6
  BuildDate: 2026-10-20T18:33:20Z
  GitCommit: c2b1e3017e2cec86b122172e861dcd026453ae44
  GitTreeState: clean
  GitTag: v3.5.6
  GoVersion: go1.26.10
  Compiler: gc
  Platform: linux/amd64
  Kustomize Version: v5.8.1 2026-02-09T16:15:27Z
  Helm Version: v4.2.1+gd591a19
  Kubectl Version: v0.36.1
  Jsonnet Version: v0.22.0
```

### Screenshot

`docs/screenshots/task2-argocd-ui.png`: the Argo CD v3.5.6 UI after signing in as admin (no Applications yet).

## Task 3

### Whitelist compared with the chart (step 1)

Kinds the chart renders (the smoke-test Job is added in Task 5):

```text
$ helm template tasktracker charts/tasktracker -f environments/dev/values.yaml | grep '^kind:' | sort | uniq -c
      1 kind: ConfigMap
      3 kind: Deployment
      1 kind: PersistentVolumeClaim
      3 kind: Service
```

Final whitelist in `argocd/projects/dso202.yaml`:

```text
$ grep -A12 '^  namespaceResourceWhitelist:' argocd/projects/dso202.yaml | grep -E 'group|kind'
    - group: apps
      kind: Deployment
    - group: ""
      kind: Service
    - group: ""
      kind: ConfigMap
    - group: ""
      kind: PersistentVolumeClaim
    - group: batch
      kind: Job
```

Compared with Listing 8: StatefulSet and ServiceAccount were removed because my chart renders neither (the database is a Deployment with a PersistentVolumeClaim). PersistentVolumeClaim was added, with a comment, because the chart renders `tasktracker-db-data`. Job stays for the PostSync smoke test. No Namespace, ResourceQuota, LimitRange, Role, RoleBinding or SealedSecret is listed.

### Apply the bootstrap layer (step 4)

Committed and pushed first:

```text
$ git ls-remote origin main
e5d19a347b2f6d973f24e92e0fa58356865fcdb4	refs/heads/main
```

```text
$ kubectl apply -f bootstrap/root
appproject.argoproj.io/platform created
Warning: metadata.finalizers: "resources-finalizer.argocd.argoproj.io": prefer a domain-qualified finalizer name including a path (/) to avoid accidental conflicts with other finalizer writers
application.argoproj.io/root created
```

### Result (step 5)

```text
$ kubectl get appproject,application -n argocd
NAME                              AGE
appproject.argoproj.io/default    98m
appproject.argoproj.io/dso202     7s
appproject.argoproj.io/platform   12s

NAME                           SYNC STATUS   HEALTH STATUS
application.argoproj.io/root   Synced        Healthy
```

```text
$ argocd app get root
Name:               argocd/root
Project:            platform
Server:             https://kubernetes.default.svc
Namespace:          argocd
URL:                https://localhost:8080/applications/root
Source:
- Repo:             https://github.com/TandinZangmo456/dso202-gitops.git
  Target:           main
  Path:             argocd
SyncWindow:         Sync Allowed
Sync Policy:        Automated (Prune)
Sync Status:        Synced to main (e5d19a3)
Health Status:      Healthy

GROUP        KIND        NAMESPACE  NAME    STATUS  HEALTH  HOOK  MESSAGE
argoproj.io  AppProject  argocd     dso202  Synced                appproject.argoproj.io/dso202 unchanged
```

```text
$ argocd proj get dso202
Name:                        dso202
Description:                 Task Tracker workloads for the dev and staging environments
Destinations:                https://kubernetes.default.svc,dso202-dev
                             https://kubernetes.default.svc,dso202-staging
Repositories:                https://github.com/TandinZangmo456/dso202-gitops.git
Source Namespaces:           <none>
Scoped Repositories:         <none>
Allowed Cluster Resources:   <none>
Scoped Clusters:             <none>
Denied Namespaced Resources: <none>
Signature keys:              <none>
Orphaned Resources:          disabled
```

`argocd proj get` does not print the namespaced whitelist, so it is read from the object. The tracking annotation shows that the `root` Application created `dso202`; `platform` (applied by hand) has none:

```text
$ kubectl get appproject dso202 -n argocd -o jsonpath='{range .spec.namespaceResourceWhitelist[*]}{.group}/{.kind}{"\n"}{end}'
apps/Deployment
/Service
/ConfigMap
/PersistentVolumeClaim
batch/Job
```

```text
$ kubectl get appproject dso202 platform -n argocd -o custom-columns='NAME:.metadata.name,TRACKING-ID:.metadata.annotations.argocd\.argoproj\.io/tracking-id'
NAME       TRACKING-ID
dso202     root:argoproj.io/AppProject:argocd/dso202
platform   <none>
```

### Screenshot

`docs/screenshots/task3-root-app-tree.png`: the root Application, Synced and Healthy, with the dso202 AppProject as its only resource.

Answer Q1: see README.md.

