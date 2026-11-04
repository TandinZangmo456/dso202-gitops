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

### Task 2: Install Argo CD declaratively

I saved Listings 2 to 5 in `bootstrap/argocd/` and committed them before applying anything. The kustomization points at the upstream `install.yaml` for the exact tag `v3.5.6`, and two patches add my own settings: a 60 second polling interval, the `reviewer` account, the health check for Application objects, and an RBAC policy that only lets `reviewer` read the `dso202` project.

Before applying, I rendered the result with `kubectl kustomize`. It had 6 Deployments and 1 StatefulSet. All 59 namespaced objects were in `argocd`, and the images came from ghcr.io, public.ecr.aws and quay.io, so none of them count against the Docker Hub pull limit. I then applied it with server-side apply as the brief says, and every object was created.

This is where I hit my biggest problem so far. While the Pods were starting, my laptop disk filled up completely. The first wait timed out for `argocd-repo-server` and `argocd-server`, and the repo-server log said `mkdir /tmp/_argocd-repo: no space left on device`. My shell could not even show output any more. I checked what was using the space and removed old Docker images from other courses, the Docker build cache, and some rebuildable caches. That freed about 17 GB. I did not change anything in the cluster or in Git. Once there was space, the Pods restarted by themselves, and the second wait passed with all seven Pods `Running` and the three CRDs present.

Signing in also took a few tries. I ran `argocd login` through the chat panel, which cannot pass keyboard input to the password prompt, so the login never finished. My first `argocd account get-user-info` failed with "server address unspecified", and I kept that in the evidence. I then did the login in a normal terminal window, where it worked. `argocd version` shows that both the client and the server are v3.5.6, and the `argocd-cm` ConfigMap has my three settings.

![Figure 2: Argo CD UI after signing in as admin](screenshots/task2-argocd-ui.png)

*Figure 2: Argo CD UI after signing in as admin*
