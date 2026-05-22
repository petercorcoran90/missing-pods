# The Case of the Missing Pods — Cheat Sheet

> Step-by-step solution for facilitators. Assumes release name `case` and
> namespace `case` (the defaults shown in the docs). All passphrases below
> are the chart defaults — if you re-`--set` them per cohort, swap your
> own in.

## 0. Install & verify

```sh
# From the project root (the directory that contains missing-pods/)
helm lint missing-pods
helm install case ./missing-pods --namespace case --create-namespace

# Wait for everything to be Running / Completed (~60 s)
kubectl get pods -n case

# Optional: ping Precinct HQ
helm test case -n case
```

## 1. Briefing (~3 min) — Pods, logs

```sh
kubectl get pods -n case
kubectl logs case-file -n case
```

The case file tells you to find the witness.

## 2. Level 1 — The First Witness (~4 min)

**Teaches:** label selectors, `--show-labels`, `describe`, annotations.

```sh
kubectl get pods -n case -l role=witness --show-labels
kubectl describe pod bystander-alpha -n case
```

The clue is in the `case.clue` annotation.

**Passphrase:** `BADGE-7749`

```sh
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/submit?clue=BADGE-7749'
```

## 3. Level 2 — Surveillance Feed (~5 min)

**Teaches:** multi-container logs, `-c`, `--tail`, `grep`.

```sh
kubectl logs surveillance-cam -n case                       # noisy, no clue
kubectl logs surveillance-cam -n case -c noise              # static
kubectl logs surveillance-cam -n case -c camera --tail=20   # the clue
```

**Passphrase:** `CAMERA-NOIR`

```sh
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/submit?clue=CAMERA-NOIR'
```

## 4. Level 3 — The Filing Cabinet (~5 min)

**Teaches:** ConfigMaps, `-o yaml`.

```sh
kubectl get configmap filing-cabinet -n case -o yaml
```

Three files say `DEAD END`. The real clue is in `file-B.txt`.

**Passphrase:** `FILING-CABINET-B`

```sh
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/submit?clue=FILING-CABINET-B'
```

## 5. Level 4 — Cracking the Safe (~6 min)

**Teaches:** Secrets, `-o jsonpath`, base64 decoding.

```sh
kubectl get secret evidence-locker -n case \
  -o jsonpath='{.data.note}' | base64 --decode ; echo
```

**Passphrase:** `OPEN-SESAME`

```sh
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/submit?clue=OPEN-SESAME'
```

## 6. Level 5 — The Hidden Suspect (~6 min)

**Teaches:** Deployments, ReplicaSets, `rollout history`, `scale`.

```sh
kubectl get deployments -n case                                # informant: 0/0
kubectl rollout history deployment/informant -n case           # suspicious change-cause
kubectl scale deployment/informant -n case --replicas=1
kubectl wait --for=condition=Ready pod -l role=informant -n case --timeout=60s
kubectl logs -l role=informant -n case --tail=200
```

**Passphrase:** `INFORMANT-TALKS`

```sh
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/submit?clue=INFORMANT-TALKS'
```

## 7. Level 6 — The Getaway Route (~6 min)

**Teaches:** Services, ClusterIP, `exec`, in-cluster DNS, `curl`.

```sh
kubectl get svc -n case
kubectl describe service getaway-svc -n case
kubectl get endpoints getaway-svc -n case
kubectl exec -it detective-terminal -n case -- \
  curl -s http://getaway-svc.case.svc.cluster.local
```

**Passphrase:** `GETAWAY-CAR`

```sh
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/submit?clue=GETAWAY-CAR'
```

## 8. Level 7 — The Vault (~5 min)

**Teaches:** volumes, `volumeMounts`, `mountPath`, `exec` into the filesystem.

```sh
kubectl describe pod vault-keeper -n case | sed -n '/Volumes/,/Conditions/p'
kubectl exec vault-keeper -n case -- ls -la /evidence
kubectl exec vault-keeper -n case -- cat /evidence/manifest.txt
```

**Passphrase:** `VAULT-OPENED`

```sh
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/submit?clue=VAULT-OPENED'
```

## 9. Finale — The Accusation (~6 min)

**Teaches:** `helm list`, `helm get manifest`, `helm get values`.

```sh
helm list -n case
helm get values case -n case             # spot the worker on the wrong team
helm get manifest case -n case | grep -E "(name:|team:)" | head -40
```

Four workers; three are `team: platform`. **`ledger-worker`** is `team: contractor`.

```sh
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/accuse?name=ledger-worker'
```

Victory banner + elapsed time prints.

## Hints (any time)

```sh
# Progress bar / case status
kubectl exec -it detective-terminal -n case -- \
  curl -s http://precinct-hq.case.svc.cluster.local:8080/

# Graduated hint for a level (1..7) - 1=mild, 3=near spoiler
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/hint?level=3'
```

## Reset / uninstall

```sh
helm uninstall case -n case
kubectl delete namespace case      # optional, only if you created it

# Fresh start - resets the clock and all evidence state
helm install case ./missing-pods --namespace case --create-namespace
```

## Reskin / randomize for a fresh cohort

```sh
helm install case ./missing-pods --namespace case --create-namespace \
  --set answers.level1=ZEBRA-1 \
  --set answers.level2=ZEBRA-2 \
  --set answers.level3=ZEBRA-3 \
  --set answers.level4=ZEBRA-4 \
  --set answers.level5=ZEBRA-5 \
  --set answers.level6=ZEBRA-6 \
  --set answers.level7=ZEBRA-7 \
  --set answers.culprit=auth-worker
```

## Passphrase quick-reference (defaults)

| Level | Passphrase |
| --- | --- |
| 1 | `BADGE-7749` |
| 2 | `CAMERA-NOIR` |
| 3 | `FILING-CABINET-B` |
| 4 | `OPEN-SESAME` |
| 5 | `INFORMANT-TALKS` |
| 6 | `GETAWAY-CAR` |
| 7 | `VAULT-OPENED` |
| Culprit | `ledger-worker` |
