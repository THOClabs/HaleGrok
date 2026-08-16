# HaleGrok — Continue Protocol

When the user says **continue** (or "continue*"), do not restart.
Read this file, then `docs/SESSION.md`, then execute the **next open item**.

## What this is

HaleGrok is a **code simulator that drives video prompts**, then posts to X
**only if the user clicks Approve**.

```
Ada/Hale scripted sims  →  gauntlet  →  review room  →  Imagine  →  Approve  →  X (@thenlaguna)
```

Not a playable game. Each production has a **storyboard** (one color wash + one
astronaut event) born from numbers the script actually produced.

A production does not exist until its scripted Hale simulations have run
and passed. Video is last. Never generate Imagine media to skip a sim.

Each continue-round offers **six to ten films** (a slate), not one.

## Contract

1. Physics source of truth: `reference/hale-orbital-mechanics/` (Ada).
   Runtime: `src/hale/`, faithful to Hale / Vallado / Ada oracles.
2. **100 productions.** Scripted sims before production.
3. **Gauntlet + review room before Imagine.**
   Reviewers: Vallado (numbers), Hopper (audience), Murch (cut), Sagan (wonder).
4. **Approve is the only publish action.** Draft for `@thenlaguna`. No auto-post.
5. User mostly says **continue**, sometimes **steer**. Apply steer, resume queue.
6. Leave the live preview running. Edit in place.
7. **Git:** work on a `continue/sN-*` branch. Regularly push. **Squash-merge to
   `main`**. Never force-push `main`. Repo: `THOClabs/HaleGrok`.

## Gauntlet

| Gate | Meaning |
| --- | --- |
| SPEC | Brief + storyboard complete |
| SIM | All scripted Hale steps ran, finite, physical |
| CONSERVE | Energy / Jacobi / h within tolerance |
| ORACLE | Matches Hale / Vallado / Ada when one exists |
| BEATS | Shot list + Imagine prompts from telemetry |
| REVIEW | Vallado / Hopper / Murch / Sagan all sign |
| IMAGINE | Clips requested (gated, signed-in, one at a time) |
| ASSEMBLE | Shots stitched |
| APPROVE | User clicked Approve — X draft opened |
| RELEASE | Posted / archived |

## Queue

- [x] S1 — Desk shell, Hale TS core, CR3BP, 8-film slate, review room, Approve→X
- [ ] S2 — Kepler elliptic/hyperbolic + universal propagation (Ada Kepler)
- [ ] S3 — Production 021 Earth–Mars patched-conic (Ada earth_mars_mission)
- [ ] S4 — Halo / Lyapunov differential correction (Ada Find_Halo_Orbit)
- [ ] S5 — Shot-list compiler: telemetry → multi-shot Imagine prompts
- [ ] S6 — Imagine request pipeline (signed-in, capped, persisted) + review polish
- [ ] S7 — First assembled film for 001
- [ ] S8 — Lambert intercept (Ada lambert_intercept)
- [ ] S9 — Bi-elliptic, plane change, phasing (Ada maneuvers)
- [ ] S10 — Next 8-film slate through REVIEW
- [ ] S11+ — Next slate per continue burst

## How to continue

1. Read CONTINUE.md and docs/SESSION.md
2. Branch `continue/sN-short-name` from latest `main`
3. Do the first unchecked item fully (real sims, not stubs)
4. Update docs/SESSION.md
5. Push the branch. Open a PR. **Squash-merge to main.**
6. Check the box only when it runs in preview
7. Summarize in product language

## GitHub

- Owner: `THOClabs`
- Repo: `HaleGrok`
- Default branch: `main`
- Cadence: push every session; squash-merge when the slate item works
