# Facilitator Notes — The Case of the Missing Pods

This is the **spoiler doc**. It contains the full solution walkthrough, per-level timings, reset and reskin recipes, and notes on what each level is teaching. Hand it to whoever is running the session, not the players.

## Time budget

| Phase | Target time | Cumulative |
| --- | --- | --- |
| Briefing (read NOTES + case file) | 3 min | 3 |
| Level 1 — The First Witness | 4 min | 7 |
| Level 2 — Surveillance Feed | 5 min | 12 |
| Level 3 — The Filing Cabinet | 5 min | 17 |
| Level 4 — Cracking the Safe (base64) | 6 min | 23 |
| Level 5 — The Hidden Suspect (scale) | 6 min | 29 |
| Level 6 — The Getaway Route (Service + exec) | 6 min | 35 |
| Level 7 — The Vault (volumes + exec) | 5 min | 40 |
| Finale — The Accusation (Helm) | 6 min | 46 |
| Buffer | 4 min | 50 |

Every scene ships sealed (a Deployment at 0 replicas); players scale it up to investigate and back down to seal it, so each level now carries a `kubectl scale` step — levels 3–4 are the exception (plain ConfigMap/Secret data, nothing to run). Levels 4–6 are where the difficulty actually steps up. Hints are graduated — encourage teams to ask the desk after ~3 minutes stuck. The 4-minute buffer absorbs the extra scale keystrokes.

## Sealed scenes (the open/close mechanic)

To keep the footprint small on testers' VMs, **every crime scene is a Deployment that ships at `replicas: 0`** — it consumes nothing until a player brings it up. The intended loop per scene:

1. Scale the Deployment to 1 (`kubectl scale deployment/<name> --replicas=1`).
2. Investigate (logs / describe / exec / curl).
3. Scale it back to 0 to seal it before moving on.

Only `precinct-hq`, `detective-terminal`, and `case-file` run the whole time. Levels 3 (ConfigMap) and 4 (Secret) are pure data — nothing to scale. The finale's four worker Deployments also ship at 0; the audit reads their **labels/manifest**, which exist regardless of replicas, so they never need to run.

Steady-state running pods land at ~3 (plus the one scene in play, plus 2 decoys if enabled) — down from ~13 with everything up at once. Because a scene's pod gets a ReplicaSet suffix, target reads at `deploy/<name>` or `-l role=<role>`, not the bare name. The literal `scale` commands live in each Deployment's `case.hint` and the desk's `/hint`; the clues themselves only say a scene is "powered down — bring it online."

## Install / live verification

```sh
helm lint missing-pods
helm install --dry-run=client --debug case ./missing-pods \
  --namespace case --create-namespace
helm install case ./missing-pods \
  --namespace case --create-namespace
kubectl get pods -n case   # only ~3 run at rest — scenes stay sealed until played, so this is expected
helm test case -n case     # optional: pings the Precinct HQ /healthz
```

> **Live-cluster note.** The walkthrough below is derived from the rendered manifests (`helm template`). The chart passes `helm lint` and `helm install --dry-run=client --debug` cleanly. **A live end-to-end run on a kind/minikube cluster is still pending** in the authoring environment; if you find a clue that ambiguously points to the wrong resource on a live install, please file the discrepancy. The per-scene scale-up/-down flow has likewise only been checked via `helm template` / `helm lint`, not a live run — sanity-check the `kubectl scale` + `wait` steps on first use.

## Solution walkthrough

All commands assume namespace `case`. With the **default** `values.yaml`, the passphrases are:

| Level | Passphrase | Source |
| --- | --- | --- |
| 1 | `BADGE-7749` | witness annotation |
| 2 | `CAMERA-NOIR` | surveillance-cam logs |
| 3 | `FILING-CABINET-B` | `filing-cabinet` ConfigMap, `file-B.txt` |
| 4 | `OPEN-SESAME` | `evidence-locker` secret, base64-decoded |
| 5 | `INFORMANT-TALKS` | `informant` deployment pod logs |
| 6 | `GETAWAY-CAR` | `getaway-svc` HTTP response |
| 7 | `VAULT-OPENED` | `vault-keeper` pod, `/evidence/manifest.txt` |
| Culprit | `ledger-worker` | the only `team: contractor` worker |

### Briefing

```sh
kubectl get pods -n case
kubectl logs case-file -n case
```

Expected: the printed briefing + the level-1 instruction (find the witness with `-l role=witness`).

### Level 1 — The First Witness

**Teaches:** `scale`, label selectors, `--show-labels`, `describe`, annotations.

The witness is a Deployment scaled to 0 — bring them in for questioning first:

```sh
kubectl scale deployment/bystander-alpha -n case --replicas=1
kubectl get pods -n case -l role=witness --show-labels
kubectl describe pod -l role=witness -n case
kubectl scale deployment/bystander-alpha -n case --replicas=0   # let them go
```

Expected: the `case.clue` annotation contains the level-1 passphrase `BADGE-7749` and points the team to `surveillance-cam`. (A team can also read the annotation straight off `kubectl describe deployment bystander-alpha` without scaling — a fair shortcut, and even lighter on the cluster.)

```sh
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/submit?clue=BADGE-7749'
```

### Level 2 — Surveillance Feed

**Teaches:** `scale`, multi-container logs, `-c`, `--tail`.

surveillance-cam is also a Deployment at 0 — bring it up, then scope logs to the right container:

```sh
kubectl scale deployment/surveillance-cam -n case --replicas=1
# two containers, so kubectl makes you choose one with -c:
kubectl logs deploy/surveillance-cam -n case -c noise        # static garbage, no clue
kubectl logs deploy/surveillance-cam -n case -c camera --tail=20
kubectl scale deployment/surveillance-cam -n case --replicas=0   # seal it
```

Expected: the `camera` container's loop prints the level-2 passphrase `CAMERA-NOIR` and points at the `filing-cabinet` ConfigMap.

### Level 3 — The Filing Cabinet

**Teaches:** ConfigMaps, `-o yaml`.

```sh
kubectl get configmap filing-cabinet -n case -o yaml
```

Expected: keys `file-A.txt`, `file-B.txt`, `file-C.txt`, `file-D.txt`. Three are flagged `DEAD END`. `file-B.txt` carries passphrase `FILING-CABINET-B` and points at the `evidence-locker` Secret.

### Level 4 — Cracking the Safe

**Teaches:** Secrets, `-o jsonpath`, base64 decoding.

```sh
kubectl get secret evidence-locker -n case \
  -o jsonpath='{.data.note}' | base64 --decode ; echo
```

Expected: decoded text gives passphrase `OPEN-SESAME` and points at the `informant` Deployment.

### Level 5 — The Hidden Suspect

**Teaches:** Deployments / ReplicaSets, `rollout history`, `scale`.

```sh
kubectl get deployments -n case                              # most scenes sit at 0; the informant is the one to wake here
kubectl rollout history deployment/informant -n case         # change-cause hints at sabotage
kubectl scale deployment/informant -n case --replicas=1
kubectl wait --for=condition=Ready pod -l role=informant -n case --timeout=60s
kubectl logs -l role=informant -n case --tail=200
kubectl scale deployment/informant -n case --replicas=0      # seal it once it's talked
```

Expected: the freshly-spawned informant pod's logs print passphrase `INFORMANT-TALKS` and point at the `getaway-svc` ClusterIP Service.

### Level 6 — The Getaway Route

**Teaches:** Services, ClusterIP, `exec`, in-cluster DNS.

```sh
kubectl get svc -n case
kubectl describe service getaway-svc -n case                 # note the selector: app=getaway
kubectl get endpoints getaway-svc -n case                    # EMPTY: the getaway Deployment behind it is at 0
kubectl scale deployment/getaway -n case --replicas=1
kubectl wait --for=condition=Ready pod -l role=getaway -n case --timeout=60s
kubectl get endpoints getaway-svc -n case                    # now populated
kubectl exec -it detective-terminal -n case -- \
  curl -s http://getaway-svc.case.svc.cluster.local
kubectl scale deployment/getaway -n case --replicas=0        # seal it
```

Expected: the response (served by `nginx:alpine` with a ConfigMap-backed `index.html`) contains passphrase `GETAWAY-CAR` and tells the team to exec into `vault-keeper` and read `/evidence/manifest.txt`.

### Level 7 — The Vault

**Teaches:** volumes, `volumeMounts`, `mountPath`, exec into the filesystem.

```sh
kubectl scale deployment/vault-keeper -n case --replicas=1
kubectl wait --for=condition=Ready pod -l role=vault -n case --timeout=60s
kubectl describe pod -l role=vault -n case          # see the emptyDir 'evidence' volume + mount
kubectl exec deploy/vault-keeper -n case -- ls -la /evidence
kubectl exec deploy/vault-keeper -n case -- cat /evidence/manifest.txt
kubectl scale deployment/vault-keeper -n case --replicas=0   # seal the vault
```

Expected: `/evidence/manifest.txt` (seeded by an initContainer from a configMap volume into an emptyDir) carries passphrase `VAULT-OPENED` and hands the team to the Helm finale.

> The chart uses `emptyDir` for the evidence volume so it has no StorageClass dependency. The same template trivially swaps to a PVC if you want to demo dynamic provisioning — see the "Reskin / variants" section.

### Finale — The Accusation

**Teaches:** `helm list`, `helm get manifest`, `helm get values`.

```sh
helm list -n case
helm get values case -n case           # shows the 'workers' list
helm get manifest case -n case | grep -A2 "team:" | head -40
kubectl get deploy -l role=worker -n case --show-labels   # the 'team' label shows even at 0 replicas
```

Expected: four worker Deployments — `payments-worker`, `auth-worker`, `notifications-worker`, `ledger-worker`. Three are `team: platform`; **`ledger-worker` is `team: contractor`**. That's the impostor. All four ship at `replicas: 0`; nobody needs to start them — the labels and the manifest tell the story. (Scale them up for a theatrical line-up if you want.)

Close the case:

```sh
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/accuse?name=ledger-worker'
```

Expected: the victory banner + elapsed time since `helm install`.

## Reset

```sh
helm uninstall case -n case
helm install case ./missing-pods -n case --create-namespace
```

All progress state lives in the Precinct HQ pod's memory, so reinstall = clean reset. The countdown starts on `helm install`.

## Reskin / variants

Everything player-facing is in `values.yaml`:

```sh
helm install case ./missing-pods -n case --create-namespace \
  --set theme.caseName="The Haunted Cluster" \
  --set theme.detectiveName="Inspector" \
  --set theme.briefing="A ghost is in the cluster..." \
  --set answers.level1=GHOST-1 \
  --set answers.level2=GHOST-2 \
  --set answers.level3=GHOST-3 \
  --set answers.level4=GHOST-4 \
  --set answers.level5=GHOST-5 \
  --set answers.level6=GHOST-6 \
  --set answers.level7=GHOST-7 \
  --set answers.culprit=auth-worker
```

To make a different worker the culprit:

1. Set `answers.culprit` to one of the worker names in `values.yaml`.
2. Edit the `workers:` list so that **only that worker** has the off-team value (default convention: legitimate workers are `team: platform`; the culprit is `team: contractor`). The chart does not enforce this — it's an authorial constraint — so double-check that exactly one worker stands out.

## Difficulty knobs

- `--set difficulty.decoys=false` — remove the dead-end pods / ConfigMaps / Secrets for a faster speed-run.
- `--set difficulty.hints=false` — strip the `case.hint` annotations and refuse to serve `/hint` cleanly. Use sparingly; the budget assumes hints are available.
- `--set validator.enabled=false` — pure discovery chain; the level-7 vault clue is rewritten by the chart to spell the culprit's name out, so the chain still completes.
- `--set rbac.enabled=true` — ship a `detective` ServiceAccount with a namespace-scoped Role. To hand the players a limited kubeconfig, mint a token and embed it in a kubeconfig file (kube-1.24+):

  ```sh
  kubectl -n case create token detective --duration=2h
  ```

  Wire the token into a kubeconfig that points at the cluster API server with the case namespace as default — players will be able to do everything the game expects and nothing else.

## Common stumbling points

- **Players try to read a scene that's still sealed.** If `kubectl logs`/`exec`/`describe pod <name>` says "not found" or "no pods", the scene is a Deployment at 0 replicas — they need `kubectl scale deployment/<name> --replicas=1` first. And since the pod gets a ReplicaSet suffix, target `deploy/<name>` or `-l role=<role>`, not the bare name.
- **Players run `kubectl logs` on the witness and see no clue.** Once scaled up, the witness pod's logs only say "I talk on the record" — the clue is in the annotations. Point them at `kubectl describe pod -l role=witness`.
- **Players don't pass `-c camera` to `kubectl logs surveillance-cam`** and see only the noise stream. Hint 2 of level 2.
- **`base64 --decode` on macOS** requires `-D` instead on older bash, but `--decode` is the standard long flag and is supported on every modern coreutils. If a team's machine balks, `base64 -d` works.
- **`kubectl scale` returns immediately, but the pod takes a moment to come up.** This applies to every scene now, not just the informant. Have the team `kubectl wait --for=condition=Ready pod -l role=<role>` or just re-run the read command until it answers.
- **The validator's progress bar moves only when a passphrase is `/submit`ted.** Walking the chain without submitting is fine; the case closes on `/accuse`.

## How to reach for help during the session

- The `case-file` pod logs are the single source of truth for the briefing — if a team has lost the thread, `kubectl logs case-file -n case` re-prints everything.
- The Precinct HQ desk also responds to `GET /` with the current progress bar and the list of endpoints.
