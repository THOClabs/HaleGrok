# Executive Summary (Phase 6 — Board Report)

**Author:** Executive Scribe (L7)
**Date:** 2026-07-12
**Basis:** Distillation of all reports in `docs/review/` (commit 0345758). No new findings. Where the Phase-1 inventory conflicts with later reports (Izzo Lambert, Gold proof levels, CSV cross-validation pipeline), the architect's corrected facts in `40-architecture.md` §6 govern: all three inventory claims traced to README marketing and are wrong.

---

## 1. What this system is

HALE Orbital Mechanics is a pure-computation Ada 2012/SPARK astrodynamics library (~7,900 LOC, 13 packages) implementing textbook orbital mechanics from Hale and Vallado — two-body dynamics, Keplerian conversions, Kepler solvers, Lambert transfers (Battin universal-variable; Izzo is planned, not present), patched-conic interplanetary design, numerical propagation, and the Circular Restricted Three-Body Problem. Alongside it sits an independent Python CR3BP "oracle" (~3,850 LOC, NumPy/SciPy, 49/49 tests passing) intended to cross-validate the Ada math, though no code path, CSV data, or harness yet connects the two. Wrapping both is a DO-178C-flavored assurance layer — SRS/SDS/SCS/RTM/test-RTM documents, SPARK contracts, an MC/DC coverage pipeline, and a 4-job GitHub Actions workflow — built by a single author over 6.5 months and 6 commits.

## 2. Overall health

> **2026-07-13 update:** the remediation landed on this same PR — all ten risks
> addressed (see the status table atop `50-risk-register.md`), full estate
> 399/399 green with CI gates armed, Lambert restored to the standard
> formulation, real DP5(4)/RKF7(8)/RKF4(5) integrators, and the
> Python→CSV→Ada cross-validation pipeline built. The verdict below describes
> the pre-remediation state and is retained as the historical record.

**Verdict: Recoverable but unverified — well-layered, largely sound mathematics wrapped in an assurance layer that currently certifies nothing (quality grade C-/D+).**

The code architecture is clean (strict downward layering, no I/O in library code, bounded iteration, a disciplined shared exception taxonomy) and every defect found has a small, mechanical fix. But the trust machinery is inoperative: only the doc-lint CI job can fail; the one test binary CI runs always exits 0; the 234 tests the certification RTM marks "Complete" are never built; the coverage build does not compile; gnatprove has never run despite "proven free of runtime errors" headers; and the flagship "RK78" integrator is not the method it claims to be. Green CI is currently indistinguishable from a broken build. Compounding all of this: bus factor of one (sole author, `main` 52 days stale).

## 3. Top 5 risks (architect's priority order, from `50-risk-register.md`)

| # | Risk | Score |
|---|------|-------|
| R1 | **The verification pipeline cannot fail.** `continue-on-error` on build/SPARK jobs, a masked pytest step, and a test runner that never sets a nonzero exit status stack so that no regression — accidental or malicious — can turn CI red. Masks R2/R4/R5/R7. | 25 |
| R2 | **The flagship "RK78" integrator is not a valid Runge-Kutta method.** Stages 2–7 are built from K(1) alone (no Butcher A-matrix), combined with DOPRI5(4) weights under an 8th-order step controller; the SDS's "1e-12 energy conservation" claim cannot be substantiated. | 25 |
| R3 | **False formal-verification claims in shipped source and scope docs.** Headers say "proven free of runtime errors" over `SPARK_Mode => Off` bodies; `spark-scope.md` is wrong in both directions; gnatprove has never run. | 20 |
| R4 | **The DO-178C evidence chain is structurally broken end to end.** RTM and SRS/test-RTM use disjoint requirement-ID namespaces; 234 "Complete" tests are unreachable from CI; the MC/DC coverage build does not compile (record field-name drift). | 20 |
| R5 | **Lambert can return `Converged = True` with NaN/Inf velocities in every build mode.** Unguarded divisions by `C_Z`/`Sqrt(C_Z)`/`G_Func`; IEEE float division never raises on GNAT targets and no mode sets `-gnateF`. Tracked as Critical/Open ISS-010. | 16 |

## 4. Top 5 recommendations (register's recommended sequence)

1. **Restore CI gating (R1)** — one-line `Set_Exit_Status` in `run_tests.adb`, drop the `|| echo` pytest mask, then remove `continue-on-error`. *Effort: hours.*
2. **Wire the orphaned test estate (R7, R4c)** — add `run_all_tests.adb` as a built Main and run it in CI; fix the two broken example call sites and the two test-file field names so `coverage.gpr` and the examples compile; add compile-only CI steps for both. *Effort: ~1 day.*
3. **Guard Lambert's non-finite outputs (R5)** — threshold-guard the three denominator families, add a `'Valid` finiteness gate before `Converged := True`, apply to both duplicated solver copies, reject degenerate geometry at entry. *Effort: hours.*
4. **One truth-pass over claims (R3, R8)** — replace "proven/verified" headers with "contracts defined; proof pending," correct `spark-scope.md` and `threebody.adb`'s SPARK_Mode, and rewrite README to separate present from planned (`data/`, `validation/`, Izzo, Gold/Platinum). *Effort: ~1 day.*
5. **Repair the certification substance (R2, R4) and the bus factor (R6)** — implement a real integrator tableau (DOPRI5 weights are already present) with a cross-check against `Kepler.Propagate`; unify the two HLR ID namespaces; tag a release, merge review output to `main`, and recruit one independent reviewer (also a DO-178C Level B independence requirement). *Effort: project-level, days-to-weeks; governance in parallel.*

All quick fixes above total an estimated 2–3 days and should land while the sole author's context is warm.

## 5. Pointers — contents of `docs/review/`

| Report | One line |
|---|---|
| `00-inventory.md` | Phase-1 recon: directory map, LOC, manifests, build commands, 5-domain decomposition — caution: its Izzo/Gold/CSV-pipeline claims were later traced to README and refuted (see 40 §6). |
| `10-history.md` | Git forensics: 6 commits over 6.5 months, single author (THOClabs), linear history, no tags, 41-day silent period, bus-factor-of-one evidence. |
| `20-domain-dimensional-foundation.md` | Types/Constants/Vectors/Matrices deep dive: real but scalar-only dimensional safety, ~40% dead public surface, Is_Singular/Inverse threshold mismatch, SPARK claim/body gap. |
| `20-domain-classical-astrodynamics.md` | Twobody/Elements/Kepler/Stumpff/Maneuvers: sound algorithms; duplicated Newton solver, non-compiling example, test-record field drift that breaks the coverage build. |
| `20-domain-trajectory-optimization.md` | Lambert/Propagation/Interplanetary: the RK78 structural defect, unguarded Lambert divisions (ISS-010), ~90% duplicated solver pair, "parallel" propagators that are sequential. |
| `20-domain-restricted-astrodynamics.md` | Ada CR3BP + Python oracle: RK45 silently aliases RK4, 2-of-6 Floquet multipliers, Sun-Earth mass-ratio inconsistency, no Ada↔Python cross-validation exists, orphaned periodic-orbit tests. |
| `20-domain-certification-safety.md` | CI/toolchain/DO-178C paper trail: only doc-lint gates, disjoint RTM/SRS ID schemes, broken bootstrap script, stale roadmaps, non-existent coverage workflow. |
| `30-security.md` | Cross-cutting security: no classic attack surface; the assurance machinery *is* the perimeter — H1 (CI can't fail), H2 (Lambert NaN in all modes), M3 (false proof claims); 9 analyst flags cleared/corrected. |
| `31-quality.md` | Cross-cutting quality: full flag-confirmation ledger (zero refuted), Q-1..Q-18 findings with smallest fixes, per-domain health grades, fresh-container walkthrough (README path fails at step 2). |
| `40-architecture.md` | Chief architect synthesis: module map, three end-to-end flows, nine inferred design decisions with fitness judgments, boundary violations, and the inter-report conflict-resolution ledger. |
| `50-risk-register.md` | Ten ranked risks (impact × likelihood) R1–R10, each with evidence, blast radius, smallest credible mitigation, owner level, and a recommended fix sequence. |
| `60-executive-summary.md` | This document. |
