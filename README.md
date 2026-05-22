# The Case of the Missing Pods

A noir detective puzzle game played with **real `kubectl`** and **real `helm`** against a real Kubernetes cluster. Designed as a 45–50 minute capstone for a *Kubernetes & Helm for Developers* course. Every clue lives in a genuine Pod, ConfigMap, Secret, Service, Deployment, volume, or label — there is no fake "game engine".

```
  +-------------------------------------------+
  |     THE CASE OF THE MISSING PODS          |
  |     three pods went silent overnight      |
  +-------------------------------------------+
       8 pieces of evidence. 1 culprit. ~45 minutes.
```

## Install (Helm repo — recommended for players)

```sh
helm repo add missing-pods https://petercorcoran90.github.io/missing-pods
helm repo update
helm install case missing-pods/missing-pods \
  --namespace case --create-namespace
```

## Install (clone — for developers / hackers)

```sh
git clone https://github.com/petercorcoran90/missing-pods.git
cd missing-pods
helm install case ./missing-pods --namespace case --create-namespace
```

## Your first command (after install)

```sh
kubectl get pods -n case
kubectl logs case-file -n case
```

The case file tells you exactly what to do next. From there, every clue points to the next one. **Trust the resources, not the names.**

## Reset

```sh
helm uninstall case -n case
helm install case missing-pods/missing-pods --namespace case --create-namespace
```

A reinstall is a clean reset — all game state lives in the Precinct HQ pod's memory.

## Documentation

| Audience | File |
| --- | --- |
| Players | [missing-pods/PLAYER-GUIDE.md](missing-pods/PLAYER-GUIDE.md) — story, rules, the single starting command, how to ask for hints. No spoilers. |
| Facilitators | [missing-pods/FACILITATOR.md](missing-pods/FACILITATOR.md) — full solution walkthrough, per-level timings, reskin recipes. |
| Chart README | [missing-pods/README.md](missing-pods/README.md) — chart-level docs (prereqs, values knobs). |

## How the Helm-repo publishing works

`.github/workflows/release.yml` runs [`helm/chart-releaser-action`](https://github.com/helm/chart-releaser-action) on every push to `main`. When the version in `missing-pods/Chart.yaml` is **higher** than the last release, the action:

1. Packages `missing-pods/` into `missing-pods-<version>.tgz`.
2. Creates a GitHub Release with the tarball attached.
3. Updates `index.yaml` on the `gh-pages` branch.

So to publish a new version after editing the chart:

```sh
# bump the version, e.g. 0.1.0 -> 0.1.1
sed -i '' 's/^version: .*/version: 0.1.1/' missing-pods/Chart.yaml
git add missing-pods/Chart.yaml
git commit -m "chart: 0.1.1"
git push
```

Pushes that don't bump the version are a no-op for the release step (the action skips already-released versions). Edits to docs alone won't trigger a release until you bump the chart version.

## License

MIT — see notes in the chart README if you reskin or redistribute.
