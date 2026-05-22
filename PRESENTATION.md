# Presentation script — *The Case of the Missing Pods*

> ~2.5 minutes spoken. Slide cues in `[brackets]`.

---

**[Slide 1 — title card]**

Hey everyone. What you're about to play is a Kubernetes detective game we built called *The Case of the Missing Pods*. Eight clues, one culprit, forty-five minutes of investigation — played entirely with real `kubectl` and `helm` commands against a real cluster. No simulated terminals, no fake game engine. The dungeon *is* the cluster.

We vibe-coded this with Claude Code. But before "vibe-coded" sounds like there was no plan — the unlock here was a really, really specific prompt.

---

**[Slide 2 — "The prompt was three pages"]**

The prompt was about three pages long. It set hard constraints:

- No simulation — every clue had to live in a real Pod, ConfigMap, Secret, Service, or volume.
- One `helm install` to deploy. One `helm uninstall` to tear down. Clean reset on reinstall.
- Only the `kubectl` commands taught in the course — no advanced jq, no operators, no CRDs.
- An explicit syllabus mapping per level: label selectors, multi-container logs, base64 decoding, scaling deployments, ClusterIP services, volumes, and `helm get values` for the finale.

That specificity is the difference between a toy and a thing you can hand to a team and trust.

---

**[Slide 3 — "What Claude built in one pass"]**

From that prompt, Claude Code generated the whole Helm chart in one shot: 25 manifests, a Python standard-library validator running an HTTP server, per-level passphrases threaded through values.yaml, graduated hints, decoy pods, optional RBAC. `helm lint` was clean on the first run. `helm template` rendered every manifest. The full discovery chain — witness → camera → ConfigMap → base64 Secret → scaled-down Deployment → ClusterIP Service → volume → Helm finale — was wired up end-to-end before we touched a single line ourselves.

---

**[Slide 4 — "But then we ran it"]**

The honest part of this story is that the most interesting work came *after* the first build, when we actually tested.

**Refinement one: the name.** Another team had claimed "Cluster Heist" — our working title. So we did one coordinated rename: chart slug, label prefixes, annotation prefixes, branding strings — forty-plus references swapped across every file in a single pass, then re-linted and re-rendered to make sure nothing broke.

**Refinement two: distribution.** We wanted teammates to install with `helm repo add`, not `git clone`. So we wired up `chart-releaser-action` on GitHub Pages. That took three rounds of debugging: workflow permissions had to be flipped to "read and write," the `gh-pages` branch had to be pre-created manually, and the action turned out to only release when the chart's *files* actually change in a commit — pushing the workflow on its own didn't count.

**Refinement three: player UX.** When we tested as a player would, we hit the most obvious gap. Every clue said "submit this passphrase to Precinct HQ" — but the game never told you *how* to submit. The full `kubectl exec ... curl .../submit?clue=...` command lived in the README and the install notes, but not in the running game. So we patched every single one of the seven levels to put the literal copy-paste-able command next to each passphrase, plus a Precinct HQ instructions block in the case file itself.

---

**[Slide 5 — takeaway]**

So the takeaway:

Vibe-coding works. But the magic isn't the vibe. It's writing a sharp spec, letting the model do the cheap, broad 80% — and then doing the actual engineering on the things that only show up when you *run* the thing. Distribution. Branding. Player UX. None of that came from the model; all of it came from sitting with the product and being honest about what was missing.

Now let's play.
