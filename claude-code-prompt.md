# Claude Code Prompt — "The Cluster Heist": a Kubernetes detective game (Helm chart)

> Paste this whole file into Claude Code, or run `claude < claude-code-prompt.md` from an empty project directory. It is the full spec for the build.

## Role & goal

You are building a self-contained, single-player/team **detective puzzle game that runs on a real Kubernetes cluster, packaged as a Helm chart** — in the spirit of `bashcrawl`, but where the "dungeon" is the cluster itself and the player explores it with real `kubectl` and `helm` commands.

The game is a teaching tool for a *Kubernetes & Helm for Developers* course. A team of learners plays it after the course to consolidate what they learned. It must keep a small team productively occupied for **45–50 minutes**, start trivially easy so they get an early win, and ramp up steadily so there is a clear **sense of progression**.

Deliver a working project, then walk the solution path yourself to prove it works.

## Hard constraints (do not violate)

1. **No simulation.** The game must use *real* Kubernetes resources on a *real* cluster. Clues live in real Pods, ConfigMaps, Secrets, Services, Deployments, volumes, annotations, labels, env vars, and logs. The player progresses by running genuine `kubectl`/`helm` commands and reading genuine cluster state — not by talking to a fake "game engine" that pretends to be Kubernetes.
2. **Packaged as a Helm chart.** The entire game installs with `helm install` and fully removes with `helm uninstall`. One command to deploy, one to tear down. `helm lint` and `helm install --dry-run --debug` must pass cleanly.
3. **Runs on a tiny dev cluster.** Assume kind / minikube / k3s / Docker Desktop with modest resources. Use only lightweight images (`busybox`, `alpine`, `nginx:alpine`, `python:3-alpine`, `curlimages/curl`, or `nicolaka/netshoot`). Everything should reach `Running`/`Completed` within ~60 seconds of install. **No external network pulls at play time** beyond the images themselves — no `pip install`, no `apk add` at runtime that could fail offline. Use Python **standard library only** for any service.
4. **Only use concepts the course actually teaches** (see "Course content to cover" below). Every command on the intended solution path must be one a learner has seen.
5. **Idempotent & resettable.** `helm uninstall <release> && helm install <release> .` must produce a clean fresh game with no leftover state. Keep all game state in-memory or in chart-managed resources so a reinstall resets it.

## Theme & narrative (default — keep it, but make it easy to reskin)

**"The Cluster Heist."** A noir detective case. Pitch:

> *Detective, the `payments` service has gone dark and a batch of customer records is missing. The intruder is still hiding somewhere in the cluster, masquerading as a legitimate workload. Follow the evidence from pod to pod, crack what they tried to hide, and unmask the culprit before the trail goes cold.*

Each level is a scene in the investigation. The player follows a chain of clues: each discovered resource tells them (clearly) what they found and points (unambiguously) to where to look next. Keep the tone fun and light — short noir flavor text, never walls of lore. Put the theme strings in `values.yaml` so an instructor can reskin the whole game (e.g. to a heist, a haunted cluster, a space station) without touching templates.

## Level design — easy → hard, ~6–8 min each, mapped to the syllabus

Design **8 levels plus a briefing and a finale**. The curve: levels 1–2 are a single command each (instant success); the middle levels are 2–3 steps; the last levels chain several commands and require decoding/combining earlier findings. Target total wall-clock for a team: **45–55 minutes**.

For each level, the discovered resource must contain (a) a short success line confirming what they found ("✓ Evidence 3 of 8 recovered"), and (b) a clear pointer to the next step. Hide clues so they require the *taught technique* to surface — not so obscure that a team burns 10 minutes guessing.

- **Briefing (warm-up, ~2 min).** `helm install` prints a `NOTES.txt` briefing and the single first command. The player runs `kubectl get pods -n <ns>` to see the crime scene, then `kubectl logs <case-file-pod>` to read the case intro and get the first instruction. **Teaches:** `get pods`, `logs`. Goal: immediate, can't-fail success.

- **Level 1 — The First Witness (Pods, labels/selectors, describe, annotations).** Among many pods, one wears a badge. `kubectl get pods -l role=witness --show-labels`, then `kubectl describe pod <witness>` surfaces an **annotation** with the next clue. **Teaches:** label selectors, `--show-labels`, `describe`, annotations.

- **Level 2 — Surveillance Feed (logs deep-dive, multi-container).** A multi-container pod streams a noisy "camera feed"; the clue is in one specific container — `kubectl logs <pod> -c camera` (and/or piping to `grep`, using `--tail`). Optionally one clue lives in a previous crashed instance reachable with `--previous`. **Teaches:** `logs -c`, `grep`, `--tail`, `--previous`.

- **Level 3 — The Filing Cabinet (ConfigMaps).** `kubectl get configmap <name> -o yaml` reveals several keys; one holds the instruction, others are red herrings labelled as dead ends. Points to a sealed Secret. **Teaches:** ConfigMaps, `get … -o yaml`.

- **Level 4 — Cracking the Safe (Secrets + base64). The signature "aha".** `kubectl get secret evidence-locker -o jsonpath='{.data.note}'` then pipe to `base64 --decode` to reveal a passphrase + the next lead. **Teaches:** Secrets, `-o jsonpath`, base64 decoding.

- **Level 5 — The Hidden Suspect (Deployments, ReplicaSets, rollout, scale).** The intruder scaled an "informant" Deployment to 0 to silence it. The player inspects `kubectl rollout history deployment/<x>` (a suspicious `change-cause`) and must `kubectl scale deployment/<informant> --replicas=1` to bring its pod up, then read **that** pod's logs for the next clue. **Teaches:** deployments, replicasets, `rollout history`, `scale`. (The scale-to-reveal mechanic only works on a real cluster — lean into it.)

- **Level 6 — The Getaway Route (Services & Ingress, exec, in-cluster DNS).** The next clue is only reachable by hitting an internal **ClusterIP Service** from inside the cluster. Provide a long-running **"detective-terminal" pod** (alpine/netshoot/curl image) so the toolbox is consistent; the player does `kubectl exec -it detective-terminal -- curl http://<svc>.<ns>.svc.cluster.local` to retrieve the response. Optionally inspect `kubectl get endpoints`/`describe service`. **Teaches:** Services, ClusterIP, `exec`, cluster DNS, `curl`, Ingress concept.

- **Level 7 — The Vault (Storage / volumes).** A pod mounts a volume (a `configMap` volume or PVC + `emptyDir`) at a path; the final physical evidence is a file inside it. `kubectl exec <pod> -- cat /evidence/manifest.txt` (or `ls` the `mountPath`). **Teaches:** volumes, `volumeMounts`, `mountPath`, PVC, exec into the filesystem.

- **Level 8 / Finale — The Accusation (Helm + close the case).** Tie it back to Helm: the whole crime scene was deployed by a Helm release. The player confirms with `helm list -n <ns>` and inspects `helm get manifest`/`helm get values` to spot the one workload whose values/labels don't match the legitimate set — the culprit. They then **submit the culprit's name** to close the case (see validator below), which prints a victory screen with their elapsed time. Optionally provide a `helm test` hook as an on-theme "case closed" check. **Teaches:** `helm list`, `helm get manifest`, `helm get values`, (optional) `helm test`.

Across these 8 levels you cover: Pods, labels/selectors, describe/annotations, logs (multi-container/grep/tail/previous), ConfigMaps, Secrets+base64, Deployments/ReplicaSets/rollout/scale, Services/Ingress/exec/DNS, Storage/volumes/PVC, and the Helm lifecycle — i.e. the whole syllabus.

## Course content to cover (the only commands/concepts allowed on the solution path)

Chapters: Intro to K8s & Helm · First Deployment · K8s Objects · Workloads · Spring Boot & Docker · Services & Ingress · Storage · ConfigMaps & Secrets · Deployments · Up & Running with Helm · Helm Charts · Working with Templates · Debugging & Logging · Monitoring.

Concretely, the game may rely on the player knowing: `kubectl get/describe pods|deployments|rs|svc|endpoints|configmap|secret|pv|pvc`, `-o yaml|wide|jsonpath`, `--show-labels`, `-l <selector>`, `kubectl logs (-c, --tail, --previous)`, `kubectl exec`, `kubectl scale`, `kubectl rollout history/status/undo`, `base64 --decode`, `grep`; and `helm install (--dry-run --debug --set)`, `helm list`, `helm get manifest/values`, `helm lint`, `helm uninstall`, plus chart anatomy (`Chart.yaml`, `values.yaml`, `templates/`, `_helpers.tpl`, `NOTES.txt`). Do **not** require anything outside this set on the critical path (advanced jq, custom CRDs, operators, service meshes, etc. are off-limits).

## Progression, success feedback & the validator ("Precinct HQ")

The discovery chain above is the backbone and must stand on its own. On top of it, build a small **"Precinct HQ" validator** to give explicit success and a sense of momentum:

- A `Deployment` running a tiny **Python stdlib `http.server`** (script delivered via ConfigMap, image `python:3-alpine`), fronted by a **ClusterIP Service**.
- Endpoints (reachable via the detective-terminal pod or `kubectl port-forward`/`minikube service`):
  - `GET /` → current case status + an ASCII progress bar (Evidence X of 8).
  - `GET /submit?clue=<passphrase>` → validates a level's passphrase, marks it found, returns the success line + confirms progress. Wrong answers get an in-character "that lead's a dead end" nudge.
  - `GET /hint?level=<n>` → returns a graduated hint for that level (so a stuck team self-serves and stays inside the time budget).
  - `GET /accuse?name=<culprit>` → the finale; correct accusation prints the victory screen + elapsed time since install.
- Keep all state **in memory** (resets on reinstall). No database. No pip packages.
- Make the validator **toggleable** in `values.yaml` (`validator.enabled`). If disabled, the pure discovery chain still completes (the final clue itself states the culprit). Build the chain first; the validator is an enhancement, not a dependency.

## Difficulty tuning (respect the 45–50 min budget)

- **Decoys / red herrings:** add a handful of plausibly-named extra pods/configmaps/secrets so a team can't trivially `get all -o yaml` and read the answer. But mark obvious dead ends with a tiny "nothing here, detective" note so nobody rat-holes. Make decoys toggleable via `values.yaml` (`difficulty.decoys`).
- **Hints:** every level embeds a graduated hint (in an annotation/`hints` ConfigMap and via `/hint`). Toggle via `values.yaml`.
- **Randomizable answers:** generate the per-level passphrases and the culprit identity from `values.yaml` (with sensible defaults) so an instructor can `--set` fresh answers per cohort and teams can't share solutions. Use Helm templating/`_helpers.tpl` to thread these values into the clue data, the Secret, and the validator consistently.
- **Note the trade-off honestly in the docs:** on a real cluster a determined player with broad read access can dump resources; full lockout would need RBAC and isn't the goal. Rely on the narrative chain, decoys, and base64/combination steps for difficulty. Optionally scaffold an RBAC `Role`/`RoleBinding` + `ServiceAccount` (toggle `rbac.enabled`) that scopes the game to its namespace, and document how to hand players a limited context — but don't make the game depend on it.

## Project structure (suggested)

```
cluster-heist/
  Chart.yaml
  values.yaml
  README.md                 # what it is, prerequisites, quick start
  PLAYER-GUIDE.md           # scenario, rules, the single starting command, how to get hints
  FACILITATOR.md            # full solution walkthrough, expected timings, reset, reskin, --set answers
  templates/
    NOTES.txt               # printed on install: the briefing + first command
    _helpers.tpl
    00-namespace.yaml       # optional, if not using --create-namespace
    00-briefing.yaml
    10-level1-witness.yaml
    20-level2-surveillance.yaml
    30-level3-cabinet.yaml
    40-level4-safe.yaml      # Secret with base64'd clue
    50-level5-suspect.yaml   # informant deployment scaled to 0
    60-level6-getaway.yaml   # internal ClusterIP service + clue
    70-level7-vault.yaml     # volume/PVC + evidence file
    80-finale.yaml
    90-detective-terminal.yaml
    95-validator.yaml        # Precinct HQ deployment + service + script ConfigMap
    decoys.yaml
    rbac.yaml                # optional, gated by values
    tests/
      test-case-closed.yaml  # optional helm test hook
```

Split levels into separate template files for readability. Use `_helpers.tpl` for shared labels, names, and answer threading.

## Deliverables

1. The complete, installable Helm chart under `cluster-heist/`.
2. `PLAYER-GUIDE.md` — player-facing: the story, the rules, the **one** command to start, and how to ask for a hint. No spoilers.
3. `FACILITATOR.md` — the **full solution walkthrough** (every command and expected output per level), expected per-level timings totalling 45–50 min, how to reset, how to reskin via `values.yaml`, and how to randomize answers with `--set`.
4. `README.md` — prerequisites, one-command install/uninstall, supported clusters.

## Acceptance criteria — verify these before declaring done

- `helm lint cluster-heist` passes with no errors.
- `helm install --dry-run --debug` renders all templates cleanly.
- If a cluster is available (`kubectl cluster-info` succeeds — spin up `kind`/`minikube` if you can), actually install it. Confirm every pod reaches `Running`/`Completed` within ~60s (`kubectl get pods -n <ns>`).
- **Walk the entire solution path yourself**, level 0 → finale, using only the allowed commands. Capture the real outputs and use them to write `FACILITATOR.md`. Fix anything where a clue is ambiguous, points to the wrong place, or needs a non-taught command.
- Each level gives explicit success feedback and an unambiguous pointer to the next.
- The validator's `/submit`, `/hint`, and `/accuse` work end-to-end from the detective-terminal pod; the victory screen prints elapsed time.
- `helm uninstall` removes everything; a fresh `helm install` is a clean reset.
- Re-running with `--set` for answers/theme threads the new values through clues, Secret, and validator consistently.

## How to work

Plan first, then build incrementally and test as you go (chain skeleton → flesh out each level → add validator → add decoys/hints → docs). If a live cluster isn't reachable, still complete `helm lint` and `--dry-run --debug`, and write `FACILITATOR.md` from the rendered manifests — but clearly flag that a live end-to-end run is still pending. Prefer the simplest robust implementation; keep images tiny and scripts stdlib-only. When you finish, give me a short summary, the install command, and the first player command.
