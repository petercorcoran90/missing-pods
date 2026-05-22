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
3. Each clue **explicitly tells you where to go next**, including the exact command. If a clue feels ambiguous, you've probably looked at the wrong thing — back out and try again.
4. **Trust the resources, not their names.** Pod names can be misleading. Decoys are clearly labelled "dead end" — don't rat-hole on them.
5. You can ask Precinct HQ for a hint at any time (see below). Hints are graduated: hint 1 is mild, hint 3 is a near-spoiler.

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

## How to ask for a hint

There's a desk at Precinct HQ inside the cluster. You reach it from the detective terminal:

```sh
# pop the lid on the precinct status / progress bar:
kubectl exec -it detective-terminal -n case -- \
  curl -s http://precinct-hq.case.svc.cluster.local:8080/

# ask the desk for a hint on a level (1..7), graduated 1=mild .. 3=near spoiler:
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/hint?level=3'

# log a level's passphrase at the desk (you'll find these in each clue):
kubectl exec -it detective-terminal -n case -- \
  curl -s 'http://precinct-hq.case.svc.cluster.local:8080/submit?clue=BADGE-7749'
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

- Every clue mentions **the exact `kubectl`/`helm` command** you need next.
- Every red herring is labelled with a `case.note` annotation that says "DEAD END" in some form.
- If you're stuck for more than 3–4 minutes on a level, **ask for a hint**. That's what they're there for.

Good hunting.
