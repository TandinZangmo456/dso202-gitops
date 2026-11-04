# DSO202 Assignment 4, GitOps Delivery of the Task Tracker with Argo CD

**Tandin Zangmo**
**Student number:** 02230305
**Submission date:** [submission date]

---

## 1. Introduction

In Assignments 1 to 3 I deployed the three-tier Task Tracker by running commands myself: `kubectl apply`, then Kustomize, then `helm install`. In this assignment that step is removed. Argo CD runs inside the cluster, reads my Git repository `dso202-gitops`, and makes the cluster match it. My job was to build the repository, prove that each GitOps principle holds in the running system, and record the evidence.

All command output is kept in [evidence.md](evidence.md). This report explains what I did, what I saw, and what went wrong along the way.

## 2. Architecture and the two environments

(Written after Task 5.)

## 3. Tasks

### Task 1: Repository, chart contract and cluster

I created the public repository `TandinZangmo456/dso202-gitops` with `gh` and cloned it into my assignment folder. The first commit is only the `.gitignore` from Listing 1, so key backups and plaintext secrets were ignored before any other file existed.

I then copied in the Practical 1 kind configuration, my Assignment 3 Helm chart, and the Assignment 2 quota, LimitRange, Role and RoleBinding. I imported the chart unchanged first and then fixed it one contract item at a time, so each change has its own commit. The main changes were:

- The chart rendered a Secret and a ResourceQuota and LimitRange. I deleted those templates (C3, C8). The Pods now read the Secret named in `credentials.existingSecret`, which is `tasktracker-credentials`.
- Image tags fell back to the chart `appVersion`. Now every tier has its own `image.tag` value and the chart refuses to render without it (C1). I also added an `extraEnv` list for each tier (C2).
- There were no readiness probes, sync waves or progress deadlines. I added all three (C4, C5, C6). The probes are values, and the backend one calls `/api/status`.
- I renamed the chart from `task-tracker` to `tasktracker`. Otherwise the objects would have been called `tasktracker-task-tracker-backend`. I also removed the old `helm test` Pod, because the smoke-test Job in Task 5 does the same job.

The tutor's images are built for arm64 only and my laptop is amd64. My tutor approved using my own amd64 rebuilds, which I already had locally from the earlier assignments. I pushed them to my Docker Hub account as `penguintandinzangmo/dso202-{frontend,backend,db}:1.0`.

Memory was a problem from the start. Docker Desktop on my laptop only gave its VM 1.7 GiB, and the brief recommends at least 6 GB. My laptop has 7.1 GiB in total. I switched to the native Docker Engine, which can use all of the host memory, and stopped Docker Desktop to free its VM.

Both `helm lint` runs were clean, and the chart renders only ConfigMap, Deployment, PersistentVolumeClaim and Service. The kind cluster `dso202-gitops` came up with three nodes, and host port 30080 is mapped on the control-plane node. The first `kubectl get nodes` showed the nodes as `NotReady` because I ran it straight after creation. After waiting they were all `Ready`.

![Figure 1: kind cluster, port mapping and helm lint for both environments](screenshots/task1-cluster-and-lint.png)

*Figure 1: kind cluster, port mapping and helm lint for both environments*
