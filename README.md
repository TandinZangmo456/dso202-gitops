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
