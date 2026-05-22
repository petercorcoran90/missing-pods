# The Case of the Missing Pods

A noir detective puzzle game played with real `kubectl` and `helm` against a real Kubernetes cluster. Designed as a 45–50 minute capstone for a *Kubernetes & Helm for Developers* course: every clue lives in a real Pod, ConfigMap, Secret, Service, Deployment, volume, log line or label, and the player progresses by running the same commands the course teaches.

```
+------------------------------------------------------------+
|   THE CASE OF THE MISSING PODS  -  case file                          |
+------------------------------------------------------------+
   8 pieces of evidence. 1 culprit. ~45 minutes.
   Tools: kubectl, helm.
```

## Prerequisites

- A small local Kubernetes cluster: **kind**, **minikube**, **k3s**, or **Docker Desktop**.
  Tested envelope: 2 CPU / 2 GB free in the cluster.
- `kubectl` (1.25+) and `helm` (3.10+) on your `$PATH`.
- Outbound network access **only** for pulling the chart images on first install: `busybox`, `alpine`, `nginx:alpine`, `python:3-alpine`, `curlimages/curl`, `nicolaka/netshoot`. Once images are local, the game runs offline.

Confirm the cluster is reachable:

```sh
kubectl cluster-info
```

## Install

One command, fresh namespace:

```sh
helm install case ./missing-pods \
  --namespace case --create-namespace
```

Within ~60 seconds every pod should be `Running` (or `Completed`):

```sh
kubectl get pods -n case
```

The `helm install` output (the `NOTES.txt`) is the **briefing**. Hand it to the players and they have everything they need to begin.

## Uninstall / reset

```sh
helm uninstall case -n case
kubectl delete namespace case   # optional, if you created it
```

A fresh `helm install` is a clean reset. All game state lives in the Precinct HQ pod's memory, so reinstalling wipes the clock and the evidence log.

## Reskin or randomize

The full theme (case name, briefing copy, detective name, victory banner) and **every passphrase + the culprit's identity** are in `values.yaml`. Change them per cohort so teams cannot share answers:

```sh
helm install case ./missing-pods \
  --namespace case --create-namespace \
  --set answers.level1=ZEBRA-1 \
  --set answers.level4=TIGER-9 \
  --set answers.culprit=auth-worker \
  --set theme.caseName="The Haunted Cluster"
```

To make the culprit somebody else, also flip which entry in `workers:` has the off-team value — exactly one worker's `team` must differ from the rest. See `FACILITATOR.md`.

## Difficulty knobs

In `values.yaml`:

- `difficulty.decoys: false` — turn off the dead-end pods / ConfigMaps / Secrets.
- `difficulty.hints: false` — strip the per-resource `case.hint` annotations.
- `validator.enabled: false` — disable Precinct HQ; the pure discovery chain still works (the last clue itself names the culprit).
- `rbac.enabled: true` — ship a `ServiceAccount` + `Role` + `RoleBinding` scoped to the game namespace so you can hand players a limited kubeconfig.

## What's in the box

- `Chart.yaml`, `values.yaml`
- `templates/`
  - `NOTES.txt` — the briefing
  - `_helpers.tpl` — shared labels, name and DNS helpers
  - `00-briefing.yaml` — case-file pod + case-file-text ConfigMap
  - `10-level1-witness.yaml`
  - `20-level2-surveillance.yaml`
  - `30-level3-cabinet.yaml`
  - `40-level4-safe.yaml`
  - `50-level5-suspect.yaml`
  - `60-level6-getaway.yaml`
  - `70-level7-vault.yaml`
  - `80-finale.yaml`
  - `90-detective-terminal.yaml`
  - `95-validator.yaml` — Precinct HQ (Python stdlib `http.server`)
  - `decoys.yaml`, `rbac.yaml`
  - `tests/test-case-closed.yaml` — `helm test case` health-check
- `README.md`, `PLAYER-GUIDE.md`, `FACILITATOR.md`

## Player guide & facilitator notes

- **`PLAYER-GUIDE.md`** — hand to the team. The story, the rules, the **one** command they need to start, how to ask for hints. No spoilers.
- **`FACILITATOR.md`** — full solution walkthrough with expected outputs, per-level timings, reset instructions, reskin recipes, how to `--set` fresh answers.

## A note on lockdown

On a real cluster a determined player with broad read access can dump every resource and skim the answers. The difficulty comes from the **chain** (each clue requires the previous one), the **decoys**, the **base64/combine** steps, and the **scale-to-reveal** mechanic — not from RBAC. If you want stricter rules, enable `rbac.enabled=true` and hand the team a kubeconfig that maps to the `detective` ServiceAccount in the game namespace.
