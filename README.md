# dso202-gitops

DSO202 Assignment 4: GitOps delivery of the Task Tracker with Argo CD.
Tandin Zangmo, student number 02230305.

## Purpose

This repository is the whole desired state of my Task Tracker cluster. Argo CD
runs in the cluster, reads this repository, and keeps two environments in line
with it:

- `dev` (namespace `dso202-dev`) follows the `main` branch and syncs by itself.
- `staging` (namespace `dso202-staging`) is pinned to a Git tag and only changes
  when a person syncs it.

Database credentials are stored here only as SealedSecrets.

## Pinned versions

| Component | Version |
| --- | --- |
| Argo CD and `argocd` CLI | v3.5.6 |
| Sealed Secrets Helm chart | 2.20.0 (controller 0.40.0) |
| `kubeseal` | v0.40.0 |
| kind | v0.32.0, node image `kindest/node:v1.36.1` (pinned by digest, from Practical 1) |
| kubectl | v1.34.1 (client) |
| Helm | v4.3.0 |
| Images | `penguintandinzangmo/dso202-frontend`, `-backend`, `-db`, tag `1.0` (amd64 rebuilds of the tutor images, approved by the tutor) |

## Layout

| Path | Contents |
| --- | --- |
| `cluster/` | kind configuration from Practical 1 |
| `bootstrap/` | applied by hand once per cluster: Argo CD itself, the `platform` project and the root Application |
| `argocd/` | every other AppProject and Application, created by the root Application |
| `platform/<env>/` | namespace, quota, limits, RBAC and sealed credentials per environment |
| `charts/tasktracker/` | the Assignment 3 Helm chart, adjusted for GitOps |
| `environments/<env>/values.yaml` | everything that differs between dev and staging |
| `docs/` | `evidence.md` (command output per task), `report.md`, screenshots |

## Building everything from an empty machine

This is the sequence I used in Task 9. It needs Docker, kind, kubectl and the
`argocd` CLI at the versions above, this repository cloned, and the sealing key
backup in `../dso202-keys/` next to it.

```bash
# 1. Cluster (Practical 1 configuration, 3 nodes, host port 30080)
kind create cluster --name dso202-gitops --config cluster/kind-cluster.yaml

# 2. Put the old sealing key back BEFORE the controller exists
kubectl create namespace sealed-secrets
kubectl apply -f ../dso202-keys/sealing-key.backup.yaml

# 3. Argo CD (the only manifests applied by hand, besides step 5)
kubectl apply -k bootstrap/argocd --server-side --force-conflicts
kubectl wait --for=condition=Available deployment --all -n argocd --timeout=300s
kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=300s

# 4. Sign in (in your own terminal, the password is never written down)
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
argocd admin initial-password -n argocd
argocd login localhost:8080 --username admin --insecure

# 5. The platform project and the root Application; the root creates the rest
kubectl apply -f bootstrap/root
kubectl get applications -n argocd -w

# 6. Staging has no automated sync, so it is synced once by a person
argocd app sync tasktracker-staging

# 7. Back up the key again from the new cluster
kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > ../dso202-keys/sealing-key.backup.yaml
chmod 600 ../dso202-keys/sealing-key.backup.yaml
```

Dev is then at `http://localhost:30080`. Staging is reached with
`kubectl port-forward svc/tasktracker-frontend -n dso202-staging 8081:8080`.

On a fresh cluster the first image pulls can be very slow. In Task 9 one hung
pull on a worker blocked the others. Pulling the image on the laptop and
loading it with `kind load docker-image <image> --name dso202-gitops` fixed it.
On a fresh first install (no key backup yet), skip step 2 and run step 7 as
soon as the Sealed Secrets controller is running.

## Cleanup

```bash
# Back up the key first if the cluster will be needed again
kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > ../dso202-keys/sealing-key.backup.yaml
kind delete cluster --name dso202-gitops
```

Deleting the cluster removes everything, including the database data. Git and
the key backup are all that is needed to build it again.

## How credentials are handled

- The database credentials are in Git only as SealedSecrets
  (`platform/<env>/tasktracker-credentials.sealed.yaml`), sealed separately for
  dev and staging with strict scope. Only the controller in the cluster can
  decrypt them.
- The plaintext input files live in `secrets-plain/`, which is in
  `.gitignore` and was never committed. They were made with random values
  that were never printed. A search of the whole Git history for every value
  found nothing (Task 4).
- The sealing key backup is kept outside the repository in
  `../dso202-keys/` with mode 600, and it is never opened or shown.
- The Argo CD admin and reviewer passwords were typed only in my own terminal
  and are not written anywhere in this repository.

## Written answers

### Q1. Why is `platform` applied by hand while `dso202` is created by the root, and what is the risk if `dso202` may deploy into `argocd`?

Every Application has to belong to a project, and that project must already
exist when the Application is created. The root Application belongs to
`platform`, so `platform` cannot be created by the root: it is needed before the
root exists. That is why `platform` and the root are the two files I apply by
hand in `bootstrap/root`. Once the root is running, every other Argo CD object,
including the `dso202` project, is just a file under `argocd/` that the root
delivers. My cluster shows this: `dso202` has the tracking annotation
`root:argoproj.io/AppProject:argocd/dso202` and appears in the resource list of
`argocd app get root`, while `platform` has no tracking annotation at all.

Applications and AppProjects are themselves objects in the `argocd` namespace.
If `dso202` were allowed to deploy into `argocd`, then a commit to the chart
could add an Application that names the `platform` project (which allows every
kind and every namespace), or could edit an AppProject or `argocd-rbac-cm`.
The workload project would then be able to give itself administrator rights,
and the whole least-privilege split between `platform` and `dso202` would mean
nothing. That is why only `platform` may target `argocd`.

### Q2. What does strict scope prevent, and what is lost and what must be done if the sealing key is lost?

With the default strict scope, the name and the namespace of the Secret are
part of what is encrypted. My dev file can only become a Secret called
`tasktracker-credentials` in `dso202-dev`. If someone copies that file into
`dso202-staging`, or renames it, the controller refuses to decrypt it. This
stops a person who can only write to one namespace from taking a sealed file
from another namespace and reading its values there. It is also why I had to
seal dev and staging separately.

If the sealing key is lost, for example because the cluster is deleted
without a backup, every SealedSecret in Git becomes useless. The ciphertext is
still there, but no controller can decrypt it, because a new controller makes
a new key pair. The running Secrets survive only as long as the old cluster
does. To recover, someone has to get the plaintext values again (from the
password manager, or by setting new passwords in the database), seal both
environments again against the new controller, and commit the new files.
That is why I back up the key to `../dso202-keys/` outside the repository
before sealing anything, and again after the rebuild in Task 9, since the
controller also makes a new key every 30 days.

### Q3. What is the difference between `Synced` and `Healthy`? Give an example where an Application is `Synced` but not `Healthy`.

`Synced` compares Git with the cluster. It means the objects in the cluster
match what the chart renders from Git at the target revision. `Healthy` looks
at whether those objects actually work: a Deployment is only Healthy when its
Pods are ready, a Job when it has succeeded, and so on. The two are checked
separately, so an Application can match Git perfectly and still not be working.

I saw this in my own dev deploy. My timestamped watch of
`kubectl get applications -n argocd -w` (evidence, Task 5) shows:

```text
01:16:33 tasktracker-dev       Synced        Progressing
01:16:34 tasktracker-dev       Synced        Progressing
01:17:19 tasktracker-dev       Synced        Healthy
```

At 01:16:33 Argo CD had applied the frontend Deployment from Git, so the
Application was `Synced`, but the frontend Pod was still pulling its image and
was not ready yet, so the health was `Progressing`. It only became `Healthy` at
01:17:19, when the readiness probe passed. The same thing can be provoked on
purpose: a release with an image that crashes at start-up would be `Synced`
(the Deployment matches Git) but `Degraded` once the 120 second progress
deadline runs out. Task 7 does exactly that.

The opposite also happens. `tasktracker-staging` was `OutOfSync` and `Missing`
before its first manual sync: Git describes objects that do not exist yet.

### Q4. What does Argo CD RBAC control, what does Kubernetes RBAC control, where is each configured, and what would change with SSO?

Argo CD RBAC controls what a person may do through Argo CD itself: which
Applications and projects they can see, and whether they can sync, delete or
read logs. It is configured in the `argocd-rbac-cm` ConfigMap (my
`bootstrap/argocd/argocd-rbac-cm-patch.yaml`), and the accounts are declared in
`argocd-cm`. The API server of Argo CD checks these rules. Kubernetes never sees
the `reviewer` user, because Argo CD talks to the cluster with its own service
account.

Kubernetes RBAC, which I used in Assignment 2, controls what a user or service
account may do directly against the Kubernetes API, for example with `kubectl`.
It is configured with Role, ClusterRole, RoleBinding and ClusterRoleBinding
objects. My `task-reader` Role and RoleBinding in `platform/<env>/rbac.yaml` are
an example. So `reviewer` cannot sync in Argo CD, but that says nothing about
what a person with a kubeconfig can do, and the other way round.

In Task 6 I also found that a third thing limits what Argo CD shows: the
project's resource whitelist. Pod logs only appeared after I added ReplicaSet
and Pod to the `dso202` project, even though the logs rule was already in place.

With SSO, the users would come from the organisation's identity provider and
not from `accounts.*` entries in `argocd-cm`. In `policy.csv` I would then bind
roles to the identity provider's groups instead of to single local accounts,
for example a role `role:dso202-reviewer` with the same three `p,` lines, and a
line `g, <idp-group-name>, role:dso202-reviewer`. People would get or lose
access by joining or leaving the group, and the local `reviewer` account could
be removed.

### Q5. Why is `argocd app rollback` refused, what is the GitOps equivalent, and why is `git revert` better than deleting the bad commit?

I could not do Task 7, because the frontend and backend `1.1` images were not
available, so this answer is not based on my own output.

`tasktracker-dev` has automated sync. If Argo CD rolled it back to an older
revision, the automated sync would compare the cluster with `main` again and
re-apply the bad commit straight away, so the Argo CD documentation says that
rollback cannot be done on an Application with automated sync. The equivalent
in GitOps is a new commit that undoes the bad one, `git revert <sha>`, merged
like any other change; Argo CD then deploys the old state because Git says so.

`git revert` is better than deleting the commit with a reset and a force push
because it keeps the history complete and true: the bad release and its undo
are both visible, with who did them and when. A force push would rewrite
`main` under everyone who has cloned it, could break tags such as `v1.1.0`
that point at those commits, and would hide what actually ran in the cluster.

### Q6. (a) One repository for chart and configuration: two advantages and two disadvantages. (b) What is not under GitOps control after the rebuild?

(a) Advantages for this project:

1. One commit can change the chart and the values that use it together. In
   Task 5 the smoke-test Job and the dev values went out as one reviewed
   change, and a tag like `v1.0.0` pins both at once, so staging can never get
   a chart that does not match its values.
2. It is simple. One repository, one URL in every Application, one place to
   read the history. For one student and two environments, a second repository
   would only add more credentials and more places to keep in step.

Disadvantages:

1. Every commit to `main`, even a change to `docs/evidence.md`, is a new
   revision for `tasktracker-dev`, `root` and the platform Applications. Argo CD
   has to render the chart again, and the history fills with commits that have
   nothing to do with the cluster.
2. Access cannot be split. Anyone who may change the chart may also change the
   staging pin, the AppProjects and the platform layer. In a real team the
   people who write the app and the people who approve environment changes
   would usually be different, and separate repositories make that easy.

(b) Not under GitOps control after the rebuild:

- **The bootstrap layer** (Argo CD itself, `argocd-cm`, `argocd-rbac-cm`). I
  applied it by hand with `kubectl apply -k`, and in Task 6 a commit to it
  changed nothing until I applied it again. Teams usually let Argo CD manage its
  own installation with an Application after the first install, or install it
  with Terraform or a cluster provisioning tool.
- **The root Application and the `platform` project.** They are in Git but
  applied by hand, and nothing re-applies them if they change. Teams usually
  apply them from the same automated pipeline that creates the cluster.
- **The sealing key.** It lives only in the cluster and in my backup file
  outside Git. Teams usually keep it in a secrets manager or vault, or replace
  Sealed Secrets with an operator that reads secrets from an external store.
- **The database contents.** They were lost in the rebuild, and only the seed
  data came back. Teams usually use scheduled database backups or volume
  snapshots, with regular restore tests.
- **The cluster itself and my laptop setup** (kind, the inotify limit, the
  images I had to load into the nodes). Teams usually describe clusters with
  infrastructure as code, so they can be recreated the same way.
