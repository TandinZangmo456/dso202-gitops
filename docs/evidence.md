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

## Task 4

### Controller installed through Git (step 1)

```text
$ kubectl get applications -n argocd
NAME             SYNC STATUS   HEALTH STATUS
root             Synced        Healthy
sealed-secrets   Synced        Healthy
```

```text
$ kubectl get pods -n sealed-secrets -o wide
NAME                                        READY   STATUS    RESTARTS   AGE   IP           NODE            NOMINATED NODE   READINESS GATES
sealed-secrets-controller-8b5ffdf69-f9nlq   1/1     Running   0          50s   10.244.1.5   worker-node-2   <none>           <none>
```

```text
$ kubectl get crd sealedsecrets.bitnami.com
NAME                        CREATED AT
sealedsecrets.bitnami.com   2026-11-04T18:49:20Z
```

```text
$ kubectl get deploy -n sealed-secrets -o jsonpath='{.items[0].spec.template.spec.containers[0].image}{"\n"}'
docker.io/bitnami/sealed-secrets-controller:0.40.0
```

### Sealing key backup (step 2)

Commands run (their output went only into the backup file, which is outside the repository and is never shown):

```text
$ mkdir -p ../dso202-keys
$ kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > ../dso202-keys/sealing-key.backup.yaml
$ chmod 600 ../dso202-keys/sealing-key.backup.yaml
```

```text
$ ls -l ../dso202-keys/
total 8
-rw------- 1 tandinzangmo tandinzangmo 7087 Nov  5 00:50 sealing-key.backup.yaml
```

```text
$ kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key
NAME                      TYPE                DATA   AGE
sealed-secrets-keyqtzg5   kubernetes.io/tls   2      22s
```

```text
$ git check-ignore -v ../dso202-keys/sealing-key.backup.yaml secrets-plain/dev.env
fatal: ../dso202-keys/sealing-key.backup.yaml: '../dso202-keys/sealing-key.backup.yaml' is outside repository at '/home/tandinzangmo/Desktop/SEM7/DSO202/assignments/assignment4/dso202-gitops'
```

### Plaintext input (step 3)

The plan was to type both files in a text editor. Only their existence and permissions are recorded, never their contents:

```text
$ ls -l secrets-plain/
ls: cannot access 'secrets-plain/': No such file or directory
```

```text
$ git check-ignore -v secrets-plain/dev.env secrets-plain/staging.env
.gitignore:14:secrets-plain/	secrets-plain/dev.env
.gitignore:14:secrets-plain/	secrets-plain/staging.env
```

The first check found no `secrets-plain/` directory: the files had not been saved yet (a search of the whole disk found no `dev.env` or `staging.env`). The `git check-ignore` lines above only show that the paths would be ignored. The check is repeated below after the files were saved.

Saving the files from the editor did not work for me, so the files were generated with a script instead, at my request. The user name and the password (32 random hex characters from `openssl rand -hex 16`) of each environment were chosen by the script. Each value was written straight into the file under `umask 077` and never printed. The DB_* and POSTGRES_* values match inside each file, and dev and staging have different passwords. I read the files myself afterwards to store the values in my password manager.

```text
$ ls -l secrets-plain/
total 8
-rw------- 1 tandinzangmo tandinzangmo 150 Nov  5 00:59 dev.env
-rw------- 1 tandinzangmo tandinzangmo 158 Nov  5 00:59 staging.env
```

```text
$ git check-ignore -v secrets-plain/dev.env secrets-plain/staging.env
.gitignore:14:secrets-plain/	secrets-plain/dev.env
.gitignore:14:secrets-plain/	secrets-plain/staging.env
```

```text
$ cmp -s secrets-plain/dev.env secrets-plain/staging.env && echo same || echo 'dev.env and staging.env differ'
dev.env and staging.env differ
```

```text
$ git status --short --ignored
 M docs/evidence.md
!! secrets-plain/
```

### Sealing (step 4)

Commands run (the plaintext Secret only exists inside the pipe; the ciphertext files are in the repository and are not copied here):

```text
$ export SEALED_SECRETS_CONTROLLER_NAMESPACE=sealed-secrets
$ kubectl create secret generic tasktracker-credentials --namespace dso202-dev --from-env-file=secrets-plain/dev.env --dry-run=client -o yaml | kubeseal --format yaml > platform/dev/tasktracker-credentials.sealed.yaml
$ kubectl create secret generic tasktracker-credentials --namespace dso202-staging --from-env-file=secrets-plain/staging.env --dry-run=client -o yaml | kubeseal --format yaml > platform/staging/tasktracker-credentials.sealed.yaml
```

Key names only (values replaced by `<ciphertext>` in the display):

```text
$ grep -hE '^  (name|namespace):|^    [A-Z_]+:' platform/*/tasktracker-credentials.sealed.yaml | sed -E 's/^(    [A-Z_]+): .*/\1: <ciphertext>/'
  name: tasktracker-credentials
  namespace: dso202-dev
    DB_PASSWORD: <ciphertext>
    DB_USER: <ciphertext>
    POSTGRES_PASSWORD: <ciphertext>
    POSTGRES_USER: <ciphertext>
  name: tasktracker-credentials
  namespace: dso202-staging
    DB_PASSWORD: <ciphertext>
    DB_USER: <ciphertext>
    POSTGRES_PASSWORD: <ciphertext>
    POSTGRES_USER: <ciphertext>
```

### Platform layer delivered (step 6)

```text
$ kubectl get applications -n argocd
NAME               SYNC STATUS   HEALTH STATUS
platform-dev       Synced        Healthy
platform-staging   Synced        Healthy
root               Synced        Healthy
sealed-secrets     Synced        Healthy
```

```text
$ kubectl get namespaces | grep dso202
dso202-dev           Active   14s
dso202-staging       Active   14s
```

```text
$ kubectl get sealedsecret -n dso202-dev
NAME                      STATUS   SYNCED   AGE
tasktracker-credentials            True     13s
```

```text
$ kubectl get sealedsecret -n dso202-staging
NAME                      STATUS   SYNCED   AGE
tasktracker-credentials            True     13s
```

```text
$ kubectl describe secret tasktracker-credentials -n dso202-dev
Name:         tasktracker-credentials
Namespace:    dso202-dev
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
DB_PASSWORD:        32 bytes
DB_USER:            15 bytes
POSTGRES_PASSWORD:  32 bytes
POSTGRES_USER:      15 bytes
```

```text
$ kubectl describe secret tasktracker-credentials -n dso202-staging
Name:         tasktracker-credentials
Namespace:    dso202-staging
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
DB_PASSWORD:        32 bytes
DB_USER:            19 bytes
POSTGRES_PASSWORD:  32 bytes
POSTGRES_USER:      19 bytes
```

```text
$ kubectl get resourcequota,limitrange -n dso202-dev
NAME                             REQUEST                                                                                                                                                                LIMIT                                      AGE
resourcequota/assignment-quota   persistentvolumeclaims: 0/2, pods: 0/10, requests.cpu: 0/500m, requests.memory: 0/1Gi, requests.storage: 0/2Gi, services.loadbalancers: 0/0, services.nodeports: 0/1   limits.cpu: 0/2, limits.memory: 0/1536Mi   14s

NAME                           CREATED AT
limitrange/assignment-limits   2026-11-04T19:00:16Z
```

```text
$ kubectl get resourcequota,limitrange,role,rolebinding -n dso202-staging
NAME                             REQUEST                                                                                                                                                                LIMIT                                      AGE
resourcequota/assignment-quota   persistentvolumeclaims: 0/2, pods: 0/10, requests.cpu: 0/500m, requests.memory: 0/1Gi, requests.storage: 0/2Gi, services.loadbalancers: 0/0, services.nodeports: 0/1   limits.cpu: 0/2, limits.memory: 0/1536Mi   14s

NAME                           CREATED AT
limitrange/assignment-limits   2026-11-04T19:00:16Z

NAME                                         CREATED AT
role.rbac.authorization.k8s.io/task-reader   2026-11-04T19:00:16Z

NAME                                                        ROLE               AGE
rolebinding.rbac.authorization.k8s.io/task-reader-binding   Role/task-reader   14s
```

```text
$ kubectl get secret tasktracker-credentials -n dso202-dev -o jsonpath='{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}{"\n"}'
SealedSecret/tasktracker-credentials
```

### History search for plaintext (step 7)

I ran this myself, because it uses the credential values. The script
(`../history-search.sh`, outside the repository) reads each value from
`secrets-plain/<env>.env` and runs `git log -p --all -S'<value>' | head` for it,
printing only the key name and how many lines came back. Keys tested: DB_USER,
DB_PASSWORD, POSTGRES_USER and POSTGRES_PASSWORD, for dev and for staging
(8 searches). Output as printed:

```text
$ bash ~/Desktop/SEM7/DSO202/assignments/assignment4/history-search.sh
dev DB_USER: git log -p --all -S'<value>' | head printed 0 lines
dev DB_PASSWORD: git log -p --all -S'<value>' | head printed 0 lines
dev POSTGRES_USER: git log -p --all -S'<value>' | head printed 0 lines
dev POSTGRES_PASSWORD: git log -p --all -S'<value>' | head printed 0 lines
staging DB_USER: git log -p --all -S'<value>' | head printed 0 lines
staging DB_PASSWORD: git log -p --all -S'<value>' | head printed 0 lines
staging POSTGRES_USER: git log -p --all -S'<value>' | head printed 0 lines
staging POSTGRES_PASSWORD: git log -p --all -S'<value>' | head printed 0 lines

$ git status --short --ignored
!! secrets-plain/
```

Every search printed nothing, and `secrets-plain/` is listed only as ignored.

### Screenshot

`docs/screenshots/task4-platform-apps.png`: the four Applications (root, sealed-secrets at chart 2.20.0, platform-dev, platform-staging), all Synced and Healthy.

Answer Q2: see README.md.

## Task 5

### Smoke test and baseline tag (steps 1 and 2)

The Service name in Listing 13 was replaced by the name the chart renders (`tasktracker-backend`). Kinds rendered now, matching the dso202 whitelist exactly:

```text
$ helm template tasktracker charts/tasktracker -f environments/dev/values.yaml | grep '^kind:' | sort | uniq -c
      1 kind: ConfigMap
      3 kind: Deployment
      1 kind: Job
      1 kind: PersistentVolumeClaim
      3 kind: Service
```

```text
$ git tag -a v1.0.0 -m 'Baseline release: images 1.0'

```

```text
$ git push origin v1.0.0
To https://github.com/TandinZangmo456/dso202-gitops.git
 * [new tag]         v1.0.0 -> v1.0.0
```

```text
$ git ls-remote --tags origin
4b3d93445b552dbee59242cb7ea1d1730f4a67eb	refs/tags/v1.0.0
63d4c4fc60e88718839cd052a8878b9edb4eaf9c	refs/tags/v1.0.0^{}
```

```text
$ git ls-tree -r --name-only v1.0.0 | grep -E 'smoke-test-job|environments/staging/values.yaml'
charts/tasktracker/templates/smoke-test-job.yaml
environments/staging/values.yaml
```

### Applications added (step 3)

The two Application files were committed and pushed at 01:12:37, then `argocd app get root --refresh` was run.

### Watching dev deploy (step 4)

Before the push I started `kubectl get pods -n dso202-dev -w --output-watch-events`, with each line prefixed by the time (`date +%T`), writing to a log file. The log, with only the first line of each Pod state kept (the full log repeats some lines):

```text
$ awk '!seen[$3" "$4" "$5]++' ../watch-logs/dev-pods-watch.log | awk '{print $1, $2, $3, $4, $5}'
01:13:02 EVENT NAME READY STATUS
01:13:02 ADDED tasktracker-db-9bf76c557-xdtlr 0/1 Pending
01:13:07 MODIFIED tasktracker-db-9bf76c557-xdtlr 0/1 ContainerCreating
01:15:17 MODIFIED tasktracker-db-9bf76c557-xdtlr 0/1 Running
01:15:23 MODIFIED tasktracker-db-9bf76c557-xdtlr 1/1 Running
01:15:24 ADDED tasktracker-backend-55bf5d6bd6-c8rng 0/1 Pending
01:15:24 MODIFIED tasktracker-backend-55bf5d6bd6-c8rng 0/1 ContainerCreating
01:16:27 MODIFIED tasktracker-backend-55bf5d6bd6-c8rng 0/1 Running
01:16:32 MODIFIED tasktracker-backend-55bf5d6bd6-c8rng 1/1 Running
01:16:33 ADDED tasktracker-frontend-686db4c7cd-j4mt6 0/1 Pending
01:16:33 MODIFIED tasktracker-frontend-686db4c7cd-j4mt6 0/1 ContainerCreating
01:17:18 MODIFIED tasktracker-frontend-686db4c7cd-j4mt6 0/1 Running
01:17:19 MODIFIED tasktracker-frontend-686db4c7cd-j4mt6 1/1 Running
01:17:19 ADDED tasktracker-smoke-test-rdhzj 0/1 Pending
01:17:20 MODIFIED tasktracker-smoke-test-rdhzj 0/1 ContainerCreating
01:17:32 MODIFIED tasktracker-smoke-test-rdhzj 1/1 Running
01:17:33 MODIFIED tasktracker-smoke-test-rdhzj 0/1 Completed
```

Order: the database Pod became ready (01:15:23) before the backend Pod was created (01:15:24); the backend became ready (01:16:32) before the frontend Pod was created (01:16:33); the smoke-test Pod was created only after the frontend was ready (01:17:19) and completed at 01:17:33. That is waves 0, 1, 2 and then the PostSync hook. The first two minutes of the database were spent pulling images onto the new node.

```text
$ kubectl get job -n dso202-dev
NAME                     STATUS     COMPLETIONS   DURATION   AGE
tasktracker-smoke-test   Complete   1/1           16s        59s
```

```text
$ kubectl logs job/tasktracker-smoke-test -n dso202-dev
[{"id":1,"title":"Set up kind cluster","description":"Bring up the local cluster from Practical 1","status":"done","created_at":"2026-11-04T19:15:20.712Z"},{"id":2,"title":"Write namespace manifest","description":"One namespace for all assignment resources","status":"in_progress","created_at":"2026-11-04T19:15:20.712Z"},{"id":3,"title":"Wire ConfigMap and Secret","description":"DB_* and POSTGRES_* must carry matching values","status":"pending","created_at":"2026-11-04T19:15:20.712Z"}]
```

```text
$ argocd app get tasktracker-dev
Name:               argocd/tasktracker-dev
Project:            dso202
Server:             https://kubernetes.default.svc
Namespace:          dso202-dev
URL:                https://localhost:8080/applications/tasktracker-dev
Source:
- Repo:             https://github.com/TandinZangmo456/dso202-gitops.git
  Target:           main
  Path:             charts/tasktracker
  Helm Values:      ../../environments/dev/values.yaml
SyncWindow:         Sync Allowed
Sync Policy:        Automated (Prune)
Sync Status:        Synced to main (d6403df)
Health Status:      Healthy

GROUP  KIND                   NAMESPACE   NAME                    STATUS     HEALTH   HOOK      MESSAGE
       ConfigMap              dso202-dev  tasktracker-config      Synced                        configmap/tasktracker-config created
       PersistentVolumeClaim  dso202-dev  tasktracker-db-data     Synced     Healthy            persistentvolumeclaim/tasktracker-db-data created
       Service                dso202-dev  tasktracker-db          Synced     Healthy            service/tasktracker-db created
       Service                dso202-dev  tasktracker-backend     Synced     Healthy            service/tasktracker-backend created
       Service                dso202-dev  tasktracker-frontend    Synced     Healthy            service/tasktracker-frontend created
apps   Deployment             dso202-dev  tasktracker-db          Synced     Healthy            deployment.apps/tasktracker-db created
apps   Deployment             dso202-dev  tasktracker-backend     Synced     Healthy            deployment.apps/tasktracker-backend created
apps   Deployment             dso202-dev  tasktracker-frontend    Synced     Healthy            deployment.apps/tasktracker-frontend created
batch  Job                    dso202-dev  tasktracker-smoke-test  Succeeded  Synced   PostSync  Reached expected number of succeeded pods
```

### Dev frontend and CRUD cycle (step 4)

The frontend page is served on the kind port mapping:

```text
$ curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:30080/ && curl -s http://localhost:30080/ | grep -i '<title>'
HTTP 200
<title>Field Log — Task Tracker</title>
```

```text
$ curl -s http://localhost:30080/config.js
// Rendered at container start by docker-entrypoint.sh via envsubst.
// Static assets can't read environment variables at request time, so the
// real value gets baked into config.js once, right before nginx starts.
window.__CONFIG__ = {
  BACKEND_URL: "http://tasktracker-backend:8080"
};
```

As in Assignment 1, `app.js` calls `BACKEND_URL` from the browser, and `tasktracker-backend` only resolves inside the cluster, so the page alone cannot reach the API. The CRUD cycle was done through a port-forward to the backend Service (`kubectl port-forward -n dso202-dev svc/tasktracker-backend 18080:8080`, running in the background), as in Assignment 1:

```text
$ curl -s http://localhost:18080/api/status
{"status":"ok","db":"connected"}
```

```text
$ curl -s -X POST http://localhost:18080/api/tasks -H 'Content-Type: application/json' -d '{"title":"A4 GitOps test","description":"created in dso202-dev"}'
{"id":4,"title":"A4 GitOps test","description":"created in dso202-dev","status":"pending","created_at":"2026-11-04T19:19:10.674Z"}
```

```text
$ curl -s http://localhost:18080/api/tasks/4
{"id":4,"title":"A4 GitOps test","description":"created in dso202-dev","status":"pending","created_at":"2026-11-04T19:19:10.674Z"}
```

```text
$ curl -s -X PUT http://localhost:18080/api/tasks/4 -H 'Content-Type: application/json' -d '{"title":"A4 GitOps test","description":"updated in dso202-dev","status":"done"}'
{"id":4,"title":"A4 GitOps test","description":"updated in dso202-dev","status":"done","created_at":"2026-11-04T19:19:10.674Z"}
```

```text
$ curl -s http://localhost:18080/api/tasks/4
{"id":4,"title":"A4 GitOps test","description":"updated in dso202-dev","status":"done","created_at":"2026-11-04T19:19:10.674Z"}
```

```text
$ curl -s -o /dev/null -w 'HTTP %{http_code}\n' -X DELETE http://localhost:18080/api/tasks/4
HTTP 204
```

```text
$ curl -s -w '\nHTTP %{http_code}\n' http://localhost:18080/api/tasks/4
{"error":"task not found"}
HTTP 404
```

```text
$ curl -s http://localhost:18080/api/tasks
[{"id":1,"title":"Set up kind cluster","description":"Bring up the local cluster from Practical 1","status":"done","created_at":"2026-11-04T19:15:20.712Z"},{"id":2,"title":"Write namespace manifest","description":"One namespace for all assignment resources","status":"in_progress","created_at":"2026-11-04T19:15:20.712Z"},{"id":3,"title":"Wire ConfigMap and Secret","description":"DB_* and POSTGRES_* must carry matching values","status":"pending","created_at":"2026-11-04T19:15:20.712Z"}]
```

### Staging before the first sync (step 5)

State of every Application, and of `root`, before staging was synchronised:

```text
$ kubectl get applications -n argocd
NAME                  SYNC STATUS   HEALTH STATUS
platform-dev          Synced        Healthy
platform-staging      Synced        Healthy
root                  Synced        Healthy
sealed-secrets        Synced        Healthy
tasktracker-dev       Synced        Healthy
tasktracker-staging   OutOfSync     Missing
```

```text
$ argocd app get tasktracker-staging
Name:               argocd/tasktracker-staging
Project:            dso202
Server:             https://kubernetes.default.svc
Namespace:          dso202-staging
URL:                https://localhost:8080/applications/tasktracker-staging
Source:
- Repo:             https://github.com/TandinZangmo456/dso202-gitops.git
  Target:           v1.0.0
  Path:             charts/tasktracker
  Helm Values:      ../../environments/staging/values.yaml
SyncWindow:         Sync Allowed
Sync Policy:        Manual
Sync Status:        OutOfSync from v1.0.0 (63d4c4f)
Health Status:      Missing

GROUP  KIND                   NAMESPACE       NAME                  STATUS     HEALTH   HOOK  MESSAGE
       ConfigMap              dso202-staging  tasktracker-config    OutOfSync  Missing        
       PersistentVolumeClaim  dso202-staging  tasktracker-db-data   OutOfSync  Missing        
       Service                dso202-staging  tasktracker-backend   OutOfSync  Missing        
       Service                dso202-staging  tasktracker-db        OutOfSync  Missing        
       Service                dso202-staging  tasktracker-frontend  OutOfSync  Missing        
apps   Deployment             dso202-staging  tasktracker-backend   OutOfSync  Missing        
apps   Deployment             dso202-staging  tasktracker-db        OutOfSync  Missing        
apps   Deployment             dso202-staging  tasktracker-frontend  OutOfSync  Missing        
```

```text
$ argocd app get root | sed -n '1,14p'
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
Sync Status:        Synced to main (d6403df)
Health Status:      Healthy
```

```text
$ argocd app get root | sed -n '/^GROUP/,$p'
GROUP        KIND         NAMESPACE  NAME                 STATUS  HEALTH   HOOK  MESSAGE
argoproj.io  Application  argocd     tasktracker-dev      Synced  Healthy        application.argoproj.io/tasktracker-dev unchanged
argoproj.io  Application  argocd     tasktracker-staging  Synced  Missing        application.argoproj.io/tasktracker-staging unchanged
argoproj.io  AppProject   argocd     dso202               Synced                 
argoproj.io  Application  argocd     platform-dev         Synced  Healthy        
argoproj.io  Application  argocd     platform-staging     Synced  Healthy        
argoproj.io  Application  argocd     sealed-secrets       Synced  Healthy        
```

```text
$ kubectl get application root -n argocd -o jsonpath='{range .status.resources[*]}{.kind}/{.name}: health={.health.status}{"\n"}{end}'
AppProject/dso202: health=
Application/platform-dev: health=
Application/platform-staging: health=
Application/sealed-secrets: health=
Application/tasktracker-dev: health=
Application/tasktracker-staging: health=
```

In my cluster `root` was already `Synced` and `Healthy` here, although `tasktracker-staging` was `OutOfSync` and `Missing`. The root does see the child as `Missing` (resource list above), but its own health is not lowered by it. Section 13 of the brief expected `Progressing`; this is what I observed.

### First staging sync (step 5)

```text
$ argocd app sync tasktracker-staging --timeout 600
{"level":"fatal","msg":"Failed to establish connection to localhost:8080: error dial proxy: dial tcp [::1]:8080: connect: connection refused","time":"2026-11-05T01:32:48+06:00"}
```


The sync above failed because nothing was listening on `localhost:8080`. My
laptop ran out of memory: `argocd-server` and `argocd-repo-server` were
restarted, and the `kubectl port-forward` to Argo CD died with them ("lost
connection to pod"). I closed Chrome and VS Code to free memory, checked that
all seven Argo CD Pods were `Running` again, restarted the port-forward and ran
the same sync again. Nothing in Git or in the cluster was changed in between.

```text
$ kubectl get pods -n argocd
NAME                                                READY   STATUS    RESTARTS        AGE
argocd-application-controller-0                     1/1     Running   0               156m
argocd-applicationset-controller-58bb5c7479-lb67f   1/1     Running   0               156m
argocd-dex-server-dd6b85d9c-jc4pd                   1/1     Running   6 (150m ago)    156m
argocd-notifications-controller-6b85c65458-c6v7s    1/1     Running   0               156m
argocd-redis-869b85489d-2njct                       1/1     Running   0               156m
argocd-repo-server-5bf66565cd-f74df                 1/1     Running   9 (5m35s ago)   156m
argocd-server-7474bb8f76-dbbxk                      1/1     Running   3 (5m49s ago)   156m
```

```text
$ argocd app sync tasktracker-staging --timeout 600
TIMESTAMP                  GROUP        KIND              NAMESPACE                      NAME    STATUS    HEALTH        HOOK  MESSAGE
2026-11-05T01:43:15+06:00   apps  Deployment             dso202-staging   tasktracker-backend  OutOfSync  Missing              
2026-11-05T01:43:15+06:00   apps  Deployment             dso202-staging        tasktracker-db  OutOfSync  Missing              
2026-11-05T01:43:15+06:00   apps  Deployment             dso202-staging  tasktracker-frontend  OutOfSync  Missing              
2026-11-05T01:43:15+06:00          ConfigMap             dso202-staging    tasktracker-config  OutOfSync  Missing              
2026-11-05T01:43:15+06:00         PersistentVolumeClaim  dso202-staging   tasktracker-db-data  OutOfSync  Missing              
2026-11-05T01:43:15+06:00            Service             dso202-staging   tasktracker-backend  OutOfSync  Missing              
2026-11-05T01:43:15+06:00            Service             dso202-staging        tasktracker-db  OutOfSync  Missing              
2026-11-05T01:43:15+06:00            Service             dso202-staging  tasktracker-frontend  OutOfSync  Missing              
2026-11-05T01:43:15+06:00          ConfigMap  dso202-staging    tasktracker-config    Synced  Missing              
2026-11-05T01:43:15+06:00         PersistentVolumeClaim  dso202-staging   tasktracker-db-data    Synced  Progressing              
2026-11-05T01:43:15+06:00            Service             dso202-staging   tasktracker-backend    Synced  Healthy                  
2026-11-05T01:43:15+06:00            Service             dso202-staging        tasktracker-db    Synced  Healthy                  
2026-11-05T01:43:15+06:00            Service             dso202-staging  tasktracker-frontend    Synced  Healthy                  
2026-11-05T01:43:15+06:00   apps  Deployment  dso202-staging        tasktracker-db    Synced  Progressing              
2026-11-05T01:43:17+06:00          ConfigMap             dso202-staging    tasktracker-config    Synced  Missing                  configmap/tasktracker-config created
2026-11-05T01:43:17+06:00         PersistentVolumeClaim  dso202-staging   tasktracker-db-data    Synced  Progressing              persistentvolumeclaim/tasktracker-db-data created
2026-11-05T01:43:17+06:00            Service             dso202-staging        tasktracker-db    Synced  Healthy                  service/tasktracker-db created
2026-11-05T01:43:17+06:00            Service             dso202-staging  tasktracker-frontend    Synced  Healthy                  service/tasktracker-frontend created
2026-11-05T01:43:17+06:00            Service             dso202-staging   tasktracker-backend    Synced  Healthy                  service/tasktracker-backend created
2026-11-05T01:43:17+06:00   apps  Deployment             dso202-staging        tasktracker-db    Synced  Progressing              deployment.apps/tasktracker-db created
2026-11-05T01:43:18+06:00         PersistentVolumeClaim  dso202-staging   tasktracker-db-data    Synced  Healthy              persistentvolumeclaim/tasktracker-db-data created
2026-11-05T01:44:16+06:00   apps  Deployment  dso202-staging        tasktracker-db    Synced  Healthy              deployment.apps/tasktracker-db created
2026-11-05T01:44:16+06:00   apps  Deployment  dso202-staging   tasktracker-backend    Synced  Progressing              
2026-11-05T01:44:18+06:00   apps  Deployment  dso202-staging   tasktracker-backend    Synced  Progressing              deployment.apps/tasktracker-backend created
2026-11-05T01:44:47+06:00   apps  Deployment  dso202-staging   tasktracker-backend    Synced  Healthy              deployment.apps/tasktracker-backend created
2026-11-05T01:44:47+06:00   apps  Deployment  dso202-staging  tasktracker-frontend    Synced  Progressing              
2026-11-05T01:44:49+06:00   apps  Deployment  dso202-staging  tasktracker-frontend    Synced  Progressing              deployment.apps/tasktracker-frontend created
2026-11-05T01:45:14+06:00   apps  Deployment  dso202-staging  tasktracker-frontend    Synced  Healthy              deployment.apps/tasktracker-frontend created
2026-11-05T01:45:14+06:00  batch         Job  dso202-staging  tasktracker-smoke-test   Running   Synced    PostSync  job.batch/tasktracker-smoke-test created
2026-11-05T01:45:19+06:00  batch         Job  dso202-staging  tasktracker-smoke-test  Succeeded   Synced    PostSync  Reached expected number of succeeded pods

Name:               argocd/tasktracker-staging
Project:            dso202
Server:             https://kubernetes.default.svc
Namespace:          dso202-staging
URL:                https://localhost:8080/applications/tasktracker-staging
Source:
- Repo:             https://github.com/TandinZangmo456/dso202-gitops.git
  Target:           v1.0.0
  Path:             charts/tasktracker
  Helm Values:      ../../environments/staging/values.yaml
SyncWindow:         Sync Allowed
Sync Policy:        Manual
Sync Status:        Synced to v1.0.0 (63d4c4f)
Health Status:      Healthy

Operation:          Sync
Sync Revision:      63d4c4fc60e88718839cd052a8878b9edb4eaf9c
Phase:              Succeeded
Start:              2026-11-05 01:43:15 +0600 +06
Finished:           2026-11-05 01:45:19 +0600 +06
Duration:           2m4s
Message:            successfully synced (no more tasks)

GROUP  KIND                   NAMESPACE       NAME                    STATUS     HEALTH   HOOK      MESSAGE
       ConfigMap              dso202-staging  tasktracker-config      Synced                        configmap/tasktracker-config created
       PersistentVolumeClaim  dso202-staging  tasktracker-db-data     Synced     Healthy            persistentvolumeclaim/tasktracker-db-data created
       Service                dso202-staging  tasktracker-db          Synced     Healthy            service/tasktracker-db created
       Service                dso202-staging  tasktracker-frontend    Synced     Healthy            service/tasktracker-frontend created
       Service                dso202-staging  tasktracker-backend     Synced     Healthy            service/tasktracker-backend created
apps   Deployment             dso202-staging  tasktracker-db          Synced     Healthy            deployment.apps/tasktracker-db created
apps   Deployment             dso202-staging  tasktracker-backend     Synced     Healthy            deployment.apps/tasktracker-backend created
apps   Deployment             dso202-staging  tasktracker-frontend    Synced     Healthy            deployment.apps/tasktracker-frontend created
batch  Job                    dso202-staging  tasktracker-smoke-test  Succeeded  Synced   PostSync  Reached expected number of succeeded pods
```


### Staging after the first sync

```text
$ kubectl get applications -n argocd
NAME                  SYNC STATUS   HEALTH STATUS
platform-dev          Synced        Healthy
platform-staging      Synced        Healthy
root                  Synced        Healthy
sealed-secrets        Synced        Healthy
tasktracker-dev       Synced        Healthy
tasktracker-staging   Synced        Healthy
```

```text
$ kubectl get pods,svc -n dso202-staging
NAME                                        READY   STATUS      RESTARTS   AGE
pod/tasktracker-backend-54ff767596-2fq9g    1/1     Running     0          73s
pod/tasktracker-db-7994c9dc8c-5lzg9         1/1     Running     0          2m14s
pod/tasktracker-frontend-74b976dd8d-cvrnv   1/1     Running     0          42s
pod/tasktracker-smoke-test-j4jvp            0/1     Completed   0          15s

NAME                           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/tasktracker-backend    ClusterIP   10.96.147.151   <none>        8080/TCP         2m14s
service/tasktracker-db         ClusterIP   None            <none>        5432/TCP         2m14s
service/tasktracker-frontend   NodePort    10.96.189.6     <none>        8080:30081/TCP   2m14s
```

```text
$ kubectl logs job/tasktracker-smoke-test -n dso202-staging
[{"id":1,"title":"Set up kind cluster","description":"Bring up the local cluster from Practical 1","status":"done","created_at":"2026-11-04T19:44:12.662Z"},{"id":2,"title":"Write namespace manifest","description":"One namespace for all assignment resources","status":"in_progress","created_at":"2026-11-04T19:44:12.662Z"},{"id":3,"title":"Wire ConfigMap and Secret","description":"DB_* and POSTGRES_* must carry matching values","status":"pending","created_at":"2026-11-04T19:44:12.662Z"}]
```


The staging frontend has no host port mapping, so I reached it with `kubectl port-forward svc/tasktracker-frontend -n dso202-staging 8081:8080` running in the background.

```text
$ curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:8081/
HTTP 200
```

```text
$ curl -s http://localhost:8081/config.js
// Rendered at container start by docker-entrypoint.sh via envsubst.
// Static assets can't read environment variables at request time, so the
// real value gets baked into config.js once, right before nginx starts.
window.__CONFIG__ = {
  BACKEND_URL: "http://tasktracker-backend:8080"
};
```


## Task 6

### Accounts (step 1)

```text
$ argocd account list
NAME      ENABLED  CAPABILITIES
admin     true     login
reviewer  true     login
```

```text
$ argocd context
CURRENT  NAME            SERVER
*        localhost:8080  localhost:8080
```


### Reviewer permissions before the logs rule (steps 2 and 3)

I set the reviewer password with `argocd account update-password --account reviewer` and signed in with `argocd login localhost:8080 --username reviewer --insecure --name reviewer`, both typed by me in my own terminal, so the passwords are not recorded here.

```text
$ argocd context
CURRENT  NAME            SERVER
         localhost:8080  localhost:8080
*        reviewer        localhost:8080
```

```text
$ argocd --argocd-context reviewer account get-user-info
Logged In: true
Username: reviewer
Issuer: argocd
Groups: 
```

```text
$ argocd --argocd-context reviewer app list
NAME                        CLUSTER                         NAMESPACE       PROJECT  STATUS  HEALTH   SYNCPOLICY  CONDITIONS  REPO                                                  PATH                TARGET
argocd/tasktracker-dev      https://kubernetes.default.svc  dso202-dev      dso202   Synced  Healthy  Auto-Prune  <none>      https://github.com/TandinZangmo456/dso202-gitops.git  charts/tasktracker  main
argocd/tasktracker-staging  https://kubernetes.default.svc  dso202-staging  dso202   Synced  Healthy  Manual      <none>      https://github.com/TandinZangmo456/dso202-gitops.git  charts/tasktracker  v1.0.0
```

```text
$ argocd --argocd-context reviewer account can-i get applications 'dso202/tasktracker-dev'
yes
```

```text
$ argocd --argocd-context reviewer account can-i sync applications 'dso202/tasktracker-dev'
no
```

```text
$ argocd --argocd-context reviewer account can-i get logs 'dso202/tasktracker-dev'
no
```

```text
$ argocd --argocd-context reviewer proj get platform
{"level":"fatal","msg":"rpc error: code = PermissionDenied desc = permission denied: projects, get, platform, sub: reviewer, iat: 2026-11-04T19:50:11Z","time":"2026-11-05T01:50:51+06:00"}
```

```text
$ argocd --argocd-context reviewer app sync tasktracker-dev
{"level":"fatal","msg":"rpc error: code = PermissionDenied desc = permission denied: applications, sync, dso202/tasktracker-dev, sub: reviewer, iat: 2026-11-04T19:50:11Z","time":"2026-11-05T01:50:51+06:00"}
```


### Mistake in the UI test: the private window was signed in as admin

When I first tested the UI, the private window was by mistake signed in as `admin`, not `reviewer`. I clicked Sync and then Synchronize on `tasktracker-dev`, and the sync was accepted. It re-synced dev to the commit it was already on (bd9f029), so only the smoke-test hook ran again. The server log and the operation state show it was `admin`:

```text
$ kubectl logs deploy/argocd-server -n argocd --since=15m | grep -E 'Login successful|initiated sync' | grep -v GetApplication
{"application":"tasktracker-staging","dest-namespace":"dso202-staging","dest-server":"https://kubernetes.default.svc","level":"info","msg":"admin initiated sync to v1.0.0 (63d4c4fc60e88718839cd052a8878b9edb4eaf9c)","reason":"OperationStarted","time":"2026-11-04T19:43:15Z","type":"Normal","user":"admin"}
{"level":"info","login.type":"local","msg":"Login successful","time":"2026-11-04T19:50:11Z","username":"reviewer"}
{"level":"info","login.type":"local","msg":"Login successful","time":"2026-11-04T19:51:29Z","username":"admin"}
{"application":"tasktracker-dev","dest-namespace":"dso202-dev","dest-server":"https://kubernetes.default.svc","level":"info","msg":"admin initiated sync to main (bd9f029d9238040bf5c3ace40d37d362a24c1a3e)","reason":"OperationStarted","time":"2026-11-04T19:51:59Z","type":"Normal","user":"admin"}
```

```text
$ kubectl get application tasktracker-dev -n argocd -o jsonpath='{.status.operationState.operation.initiatedBy}{"\n"}{.status.operationState.phase} {.status.operationState.message}{"\n"}'
{"username":"admin"}
Succeeded successfully synced (no more tasks)
```

I signed the private window out and signed in again as `reviewer` for the real UI test below.

### Reviewer in the UI (step 3)

Signed in again in the private window, this time as `reviewer` (server log line and User Info page):

```text
$ kubectl logs deploy/argocd-server -n argocd --since=20m | grep 'Login successful'
{"level":"info","login.type":"local","msg":"Login successful","time":"2026-11-04T19:50:11Z","username":"reviewer"}
{"level":"info","login.type":"local","msg":"Login successful","time":"2026-11-04T19:51:29Z","username":"admin"}
{"level":"info","login.type":"local","msg":"Login successful","time":"2026-11-04T19:57:03Z","username":"reviewer"}
```


What I saw in the private window as `reviewer`:

- The Applications page lists only `tasktracker-dev` and `tasktracker-staging` (screenshot `task6-reviewer-app-list.png`).
- Sync, then Synchronize on `tasktracker-dev` shows the error "Unable to sync: permission denied: applications, sync, dso202/tasktracker-dev, sub: reviewer" (screenshot `task6-reviewer-sync-denied.png`).
- The panel of the `tasktracker-backend` Deployment has only the Summary and Events tabs. There is no Logs tab (screenshot `task6-reviewer-logs-hidden.png`).

### Logs rule added (step 4)

I removed the leading `#` from the logs line in `bootstrap/argocd/argocd-rbac-cm-patch.yaml`, committed and pushed it, and then applied the bootstrap layer again by hand.

```text
$ git show --stat --format='%h %s' HEAD
e989442 Grant reviewer read access to Pod logs in dso202 (Task 6, step 4)

 bootstrap/argocd/argocd-rbac-cm-patch.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

```text
$ git show HEAD -- bootstrap/argocd/argocd-rbac-cm-patch.yaml | grep -E '^[-+] '
-    # p, reviewer, logs, get, dso202/*, allow
+    p, reviewer, logs, get, dso202/*, allow
```

```text
$ kubectl apply -k bootstrap/argocd --server-side --force-conflicts 2>&1 | grep -v unchanged
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

```text
$ kubectl get configmap argocd-rbac-cm -n argocd -o jsonpath='{.data.policy\.csv}' | grep '^p,'
p, reviewer, applications, get, dso202/*, allow
p, reviewer, projects, get, dso202, allow
p, reviewer, logs, get, dso202/*, allow
```

```text
$ argocd --argocd-context reviewer account can-i get logs 'dso202/tasktracker-dev'
yes
```


After the rule, the CLI answers `yes`, but the reviewer UI still showed no Logs tab after a reload. I looked into why:

```text
$ argocd app get tasktracker-dev --output tree | sed -n '/^KIND/,$p'
KIND/NAME                                  STATUS     HEALTH   MESSAGE
Deployment/tasktracker-backend             Synced     Healthy  deployment.apps/tasktracker-backend unchanged
Deployment/tasktracker-frontend            Synced     Healthy  deployment.apps/tasktracker-frontend unchanged
ConfigMap/tasktracker-config               Synced              configmap/tasktracker-config unchanged
Service/tasktracker-db                     Synced     Healthy  service/tasktracker-db unchanged
Deployment/tasktracker-db                  Synced     Healthy  deployment.apps/tasktracker-db unchanged
Job/tasktracker-smoke-test                 Succeeded  Synced   Reached expected number of succeeded pods
PersistentVolumeClaim/tasktracker-db-data  Synced     Healthy  persistentvolumeclaim/tasktracker-db-data unchanged
Service/tasktracker-backend                Synced     Healthy  service/tasktracker-backend unchanged
Service/tasktracker-frontend               Synced     Healthy  service/tasktracker-frontend unchanged
```

```text
$ kubectl get replicasets,pods -n dso202-dev
NAME                                              DESIRED   CURRENT   READY   AGE
replicaset.apps/tasktracker-backend-55bf5d6bd6    1         1         1       44m
replicaset.apps/tasktracker-db-9bf76c557          1         1         1       46m
replicaset.apps/tasktracker-frontend-686db4c7cd   1         1         1       43m

NAME                                        READY   STATUS      RESTARTS   AGE
pod/tasktracker-backend-55bf5d6bd6-c8rng    1/1     Running     0          44m
pod/tasktracker-db-9bf76c557-xdtlr          1/1     Running     0          46m
pod/tasktracker-frontend-686db4c7cd-j4mt6   1/1     Running     0          43m
pod/tasktracker-smoke-test-92j6t            0/1     Completed   0          7m27s
```

```text
$ argocd --argocd-context reviewer app logs tasktracker-dev --kind Deployment --name tasktracker-backend --tail 3; echo "exit=$?"
exit=0
```

```text
$ argocd --argocd-context localhost:8080 app logs tasktracker-dev --kind Deployment --name tasktracker-backend --tail 3; echo "exit=$?"
exit=0
```

```text
$ kubectl get appproject dso202 -n argocd -o jsonpath='{range .spec.namespaceResourceWhitelist[*]}{.group}/{.kind}{"\n"}{end}'
apps/Deployment
/Service
/ConfigMap
/PersistentVolumeClaim
batch/Job
```


The ReplicaSets and Pods exist in `dso202-dev`, but they are missing from the Argo CD tree, and `argocd app logs` prints nothing for `reviewer` and for `admin` alike. So the logs rule is working; the UI simply has no Pod to open logs from. The Argo CD projects documentation (https://argo-cd.readthedocs.io/en/stable/user-guide/projects/) says: "Any child resource whose GroupKind is not permitted by the project is omitted from the tree". My `dso202` whitelist lists only the five kinds the chart renders, so the `ReplicaSet` and `Pod` children of each Deployment are hidden. The documented fix is to add `apps/ReplicaSet` and `Pod` to the whitelist.

### Whitelist widened for visibility

I added `apps/ReplicaSet` and `Pod` to `argocd/projects/dso202.yaml` in its own commit, with a comment, and pushed it. The root delivers the project, so no command against the cluster was needed.

```text
$ git show --format='%h %s' HEAD -- argocd/projects/dso202.yaml | grep -E '^[0-9a-f]{7} |^\+ '
2b4fe60 Permit ReplicaSet and Pod in dso202 so the tree shows them (Task 6)
+    # Added in Task 6: Argo CD omits from the resource tree any child whose kind
+    # the project does not permit, so without these two lines the ReplicaSets
+    # and Pods of each Deployment are hidden and no Pod logs can be opened in
+    # the UI, even with the logs RBAC rule. The chart renders neither kind, so
+    # they are only needed for visibility. The cost is that a commit could now
+    # also create a bare Pod or ReplicaSet in the two app namespaces.
+    - group: apps
+      kind: ReplicaSet
+    - group: ""
+      kind: Pod
```

```text
$ kubectl get appproject dso202 -n argocd -o jsonpath='{range .spec.namespaceResourceWhitelist[*]}{.group}/{.kind}{"\n"}{end}'
apps/Deployment
/Service
/ConfigMap
/PersistentVolumeClaim
batch/Job
```

```text
$ argocd app get tasktracker-dev --output tree | sed -n '/^KIND/,$p'
KIND/NAME                                  STATUS     HEALTH   MESSAGE
Deployment/tasktracker-db                  Synced     Healthy  deployment.apps/tasktracker-db unchanged
Deployment/tasktracker-frontend            Synced     Healthy  deployment.apps/tasktracker-frontend unchanged
Job/tasktracker-smoke-test                 Succeeded  Synced   Reached expected number of succeeded pods
PersistentVolumeClaim/tasktracker-db-data  Synced     Healthy  persistentvolumeclaim/tasktracker-db-data unchanged
Service/tasktracker-backend                Synced     Healthy  service/tasktracker-backend unchanged
ConfigMap/tasktracker-config               Synced              configmap/tasktracker-config unchanged
Service/tasktracker-db                     Synced     Healthy  service/tasktracker-db unchanged
Service/tasktracker-frontend               Synced     Healthy  service/tasktracker-frontend unchanged
Deployment/tasktracker-backend             Synced     Healthy  deployment.apps/tasktracker-backend unchanged
```

```text
$ argocd --argocd-context reviewer app logs tasktracker-dev --kind Deployment --name tasktracker-backend --tail 3

```

```text
$ kubectl get appproject dso202 -n argocd -o jsonpath='{range .spec.namespaceResourceWhitelist[*]}{.group}/{.kind}{"\n"}{end}'
apps/Deployment
/Service
/ConfigMap
/PersistentVolumeClaim
batch/Job
apps/ReplicaSet
/Pod
```


The first check above still showed five kinds because the root had not polled Git yet. Also, my refresh of the root failed with "permission denied": the reviewer login in step 3 had made `reviewer` the current CLI context. I switched back with `argocd context localhost:8080` (the admin session from Task 2), refreshed the root, and checked again:

```text
$ argocd context
CURRENT  NAME            SERVER
*        localhost:8080  localhost:8080
         reviewer        localhost:8080
```

```text
$ argocd app get tasktracker-dev --output tree | sed -n '/^KIND/,$p'
KIND/NAME                                      STATUS     HEALTH   MESSAGE
Service/tasktracker-backend                    Synced     Healthy  service/tasktracker-backend unchanged
Service/tasktracker-db                         Synced     Healthy  service/tasktracker-db unchanged
Service/tasktracker-frontend                   Synced     Healthy  service/tasktracker-frontend unchanged
Deployment/tasktracker-backend                 Synced     Healthy  deployment.apps/tasktracker-backend unchanged
└─ReplicaSet/tasktracker-backend-55bf5d6bd6               Healthy  
  └─Pod/tasktracker-backend-55bf5d6bd6-c8rng              Healthy  
Deployment/tasktracker-db                      Synced     Healthy  deployment.apps/tasktracker-db unchanged
└─ReplicaSet/tasktracker-db-9bf76c557                     Healthy  
  └─Pod/tasktracker-db-9bf76c557-xdtlr                    Healthy  
Job/tasktracker-smoke-test                     Succeeded  Synced   Reached expected number of succeeded pods
└─Pod/tasktracker-smoke-test-92j6t                        Healthy  
Deployment/tasktracker-frontend                Synced     Healthy  deployment.apps/tasktracker-frontend unchanged
└─ReplicaSet/tasktracker-frontend-686db4c7cd              Healthy  
  └─Pod/tasktracker-frontend-686db4c7cd-j4mt6             Healthy  
ConfigMap/tasktracker-config                   Synced              configmap/tasktracker-config unchanged
PersistentVolumeClaim/tasktracker-db-data      Synced     Healthy  persistentvolumeclaim/tasktracker-db-data unchanged
```

```text
$ argocd --argocd-context reviewer app logs tasktracker-dev --kind Deployment --name tasktracker-backend --tail 3
[db] connected
[server] listening on :8080
```


### Reviewer sees Pod logs in the UI (step 4)

In the private window as `reviewer`, the `tasktracker-backend` Deployment panel now has a Logs tab. It first stayed blank. The argocd-server log showed the PodLogs call failing with `parsing time "failed"`, because following a log in my kind cluster fails:

```text
$ timeout 5 kubectl logs -f --timestamps deploy/tasktracker-backend -n dso202-dev --tail 2
2026-11-04T19:16:28.996691837Z [db] connected
2026-11-04T19:16:29.000779028Z [server] listening on :8080
failed to create fsnotify watcher: too many open files
```

```text
$ cat /proc/sys/fs/inotify/max_user_instances
128
```


The kubelet cannot open another file watcher, because my laptop allows only 128 inotify instances per user. I did not change this kernel setting. I switched off the Follow button in the log viewer instead, and the logs appeared (screenshot `task6-reviewer-pod-logs.png`).

### Back to the admin session (step 5)

The `reviewer` login had become the current CLI context. Instead of typing the admin password again, I switched back to the admin context saved in Task 2 (`argocd context localhost:8080`, recorded above):

```text
$ argocd account get-user-info
Logged In: true
Username: admin
Issuer: argocd
Groups: 
```

```text
$ argocd account can-i sync applications 'dso202/tasktracker-dev'
yes
```

