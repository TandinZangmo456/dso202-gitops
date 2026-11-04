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

(Bootstrap commands, cleanup, credential handling and the answers to Q1 to Q6
are added as the tasks are done.)

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
