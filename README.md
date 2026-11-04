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
