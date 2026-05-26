# Player Guide — The Case of the Missing Pods

```
+------------------------------------------------------------+
|   THE CASE OF THE MISSING PODS                                        |
|   the payments service has gone dark.                      |
+------------------------------------------------------------+
```

## The pitch

> *Detective, the `payments` service has gone dark and a batch of customer records is missing. The intruder is still hiding somewhere in the cluster, masquerading as a legitimate workload. Follow the evidence from pod to pod, crack what they tried to hide, and unmask the culprit before the trail goes cold.*

You have ~45 minutes. Eight pieces of evidence. One culprit.

## Rules

1. The whole crime scene lives in **one Kubernetes namespace** (default: `case`). Everything you need is in there.
2. You investigate with **real `kubectl`** (and one bit of `helm` at the very end). There is no fake "game engine" — every clue is a property of a real resource.
3. Each clue **names the resource you go to next and the technique to use** — it won't hand you the command. Working out the `kubectl` is the game. If you get stuck, the desk's `/hint` will spell it out.
4. **Crime scenes ship sealed.** Most workloads start scaled to zero — nothing running until you bring it up. Open a scene when you reach it, seal it again when you're done (see "Opening and closing scenes" below).
5. **Trust the resources, not their names.** Pod names can be misleading. Decoys are clearly labelled "dead end" — don't rat-hole on them.
6. You can ask Precinct HQ for a hint at any time (see below). Hints are graduated: hint 1 is mild, hint 3 is a near-spoiler.

## The single starting command

After the instructor runs `helm install`, your first move is:

```sh
kubectl get pods -n case
```

That gives you the lay of the bullpen. Then read the case file:

```sh
kubectl logs case-file -n case
```

The case file tells you exactly what to do next. From there, every clue points to the next one. Follow the trail.

## Opening and closing scenes

To keep the cluster light, every crime scene is a **Deployment parked at zero replicas** — nothing is running until you say so. When a clue sends you to a scene:

- **Bring it online** — scale the Deployment to one replica, and give the pod a moment to start.
- **Investigate** — read its logs, describe it, exec into it, or curl its Service.
- **Seal it again** — scale it back to zero before you move on. Leave scenes running and a small cluster gets heavy fast.

A scene's pod gets a random suffix when it comes up, so target it by its Deployment (`deploy/<name>`) or by label (`-l role=<role>`), not by guessing the pod name. ConfigMaps and Secrets (some levels are just data) don't run at all — there's nothing to scale, just read them.

Three things stay up the whole case and you never touch them: the `case-file`, the `detective-terminal`, and Precinct HQ. Not sure of the exact command to scale something up or down? Ask the desk: `/hint?level=<n>`.

## How to ask for a hint

There's a desk at Precinct HQ inside the cluster. You reach it from the detective terminal:

```sh
# pop the lid on the precinct status / progress bar:
kubectl exec -it detective-terminal -n case -- \
  curl -s http://precinct-hq.case.svc.cluster.local:8080/

# ask the desk for a hint on a level (1..7), graduated 1=mild .. 3=near spoiler:
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/hint?level=3'

# log a level's passphrase at the desk (you'll find one in each clue):
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/submit?clue=<passphrase-from-the-clue>'
```

The progress bar at `/` is your sense of momentum. Each `/submit` of the right passphrase bumps the bar.

## How the case is closed

The last clue tells you to use `helm` to audit the workloads that were deployed in this namespace. One of them doesn't fit. When you've found the impostor, accuse them:

```sh
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/accuse?name=<their-name>'
```

If you nailed it you'll get the victory banner with your time. If not, the desk politely tells you to keep digging.

## Things you can rely on

- Every clue names **the next resource and what kind it is** — turning that into the right `kubectl` is your job (the desk's `/hint` has it if you're stuck).
- Every red herring is labelled with a `case.note` annotation that says "DEAD END" in some form.
- If you're stuck for more than 3–4 minutes on a level, **ask for a hint**. That's what they're there for.

Good hunting.
