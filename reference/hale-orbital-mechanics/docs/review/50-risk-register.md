# Risk Register (Phase 5 Synthesis)

**Author:** Chief Architect (L5-L6)
**Date:** 2026-07-12
**Ranking:** impact x likelihood, highest first. Impact/Likelihood on a 1-5 scale, judged
against the project's stated purpose: a certification-track, safety-critical astrodynamics
library whose product is *trustworthy numbers*. All evidence spot-checked in source unless
marked otherwise; report references given per entry.
**Owner levels:** quick fix (< 1 day, mechanical) / project (planned work, days-weeks) /
strategic (governance, cannot be closed by a patch).

---

## Remediation status (2026-07-13, same PR)

| Risk | Status |
|------|--------|
| R1 — verification pipeline cannot fail | **FIXED**: exit statuses propagate from both runners, pytest unmasked, `continue-on-error` removed from build-and-test, hard compile-gates job added; CI green with gates armed (58-failure baseline → 399/399 estate) |
| R2 — "RK78" not a valid RK method | **FIXED**: real Fehlberg 7(8) (measured order 6.99) + real Dormand-Prince 5(4) (4.78); an additional time-advance bug (T stepped by the *next* H) found and fixed; SDS carries measured numbers |
| R3 — false formal-verification claims | **FIXED**: five spec headers, spark-scope.md rows, checklist SPARK rows all state proof-pending truthfully |
| R4 — DO-178C evidence chain broken | **FIXED**: SRS v2.0 canonical union (144 IDs), rtm renumbered w/ Legacy column, HLR-3B-035 collision resolved, test-rtm statuses reflect CI reality; coverage closure compiles and is CI-gated |
| R5 — Lambert NaN with Converged=True | **FIXED**: denominator guards + finiteness/A>0 gate + 180° rejection; beyond that, the iteration formulas were restored to the standard universal-variable formulation (the loop had never implemented it — Vallado 7-1 now reproduces published velocities to the book's rounding limit; all reachable *elliptic* grid cases converge — reachable hyperbolic transfers below the parabolic TOF still report Converged=False, documented) |
| R6 — bus factor of one | **Mitigated in part** (strategic): this remediation is itself independent review + written transfer; release tagging and a human second maintainer remain open |
| R7 — orphaned test estate | **FIXED**: run_all_tests wired and CI-run (378 tests incl. all suites + new oracle suite); examples all build; coverage driver compiles |
| R8 — aspirational docs as present tense | **FIXED**: README truth pass; the CSV cross-validation pipeline it promised now actually exists (`validation/` + `Hale_Tests.Oracle`) |
| R9 — silent-wrong-answer cluster | **FIXED**: real RK45, full Floquet eigensolver (palindromic reduction) with `Valid` flag, `Lagrange_Result.Converged`, mass ratios derived and tested, matrices thresholds unified |
| R10 — supply-chain/bootstrap gaps | **FIXED** (except one upstream gap): setup.sh trap + apt fallback + version assertion (upstream publishes no checksum to pin), CI least-privilege token, SHA-pinned actions where immutable tags exist, pinned Python constraints |

---

## R1 — The verification pipeline cannot fail (score 25: impact 5 x likelihood 5)

**Risk:** No code regression — broken build, failing test, invalid algorithm, or malicious
change — can turn CI red. Three independent defects stack: `continue-on-error: true` on
`build-and-test` and `spark-flow` (`.github/workflows/ci.yml:21,56`); the pytest step
swallows its own exit code (`ci.yml:96`); and the only test binary CI builds
(`ada/tests/run_tests.adb`, sole Main of `ada/tests/hale_tests.gpr:11`) never calls
`Ada.Command_Line.Set_Exit_Status` — it exits 0 unconditionally (grep-confirmed). Only the
doc-lint job gates, and it checks persona-narrative regressions and four files' existence.
Meanwhile `docs/certification/DO-178C-compliance-checklist.md:74` claims "A-6.2 Results
correct — COMPLETE — CI validates."
**Evidence:** 30-security.md H1; 31-quality.md Q-7/Q-8/§3; 20-domain-certification-safety.md
§3, §5; independently re-verified this phase.
**Blast radius:** the entire repository plus every downstream consumer and every
certification claim — green CI currently certifies nothing. Also masks risks R2, R4, R5, R7
from ever being detected automatically.
**Smallest credible mitigation:** (1) one-line `Set_Exit_Status` failure check in
`run_tests.adb` (the pattern already exists at `run_all_tests.adb:382-386`); (2) delete the
`|| echo` on `ci.yml:96` (the Python suite passes 49/49 today, so this is safe immediately);
(3) after one clean week, remove `continue-on-error: true` from `build-and-test`.
**Owner level:** quick fix.

## R2 — The flagship "RK78" integrator is not a valid Runge-Kutta method (score 25: 5 x 5)

**Risk:** Every trajectory produced via `Propagate_RK78`/`Generate_Trajectory` is computed
by a structurally invalid integrator: stages 2-7 are all built from `K(1)` alone (no Butcher
A-matrix exists in the file), combined with Dormand-Prince 5(4) weights under DOP853 nodes,
with a step controller assuming 8th-order error (`ada/src/hale_orbital-propagation.adb:
252-302,319,333` — read directly this phase). `docs/certification/SDS.md:210-213` cites
"RK78 provides 1e-12 energy conservation per orbit" as a certification claim. Actual order
and accuracy are unknown (toolchain unavailable to all reviewers), but they cannot be what
is claimed.
**Evidence:** 20-domain-trajectory-optimization.md Quality 1; 31-quality.md Q-1
(independently re-derived); code re-confirmed this phase.
**Blast radius:** all numerical propagation except plain RK4; `earth_mars_mission` example;
the SDS accuracy claim; any downstream user selecting the "high-accuracy" integrator.
**Smallest credible mitigation:** short term, rename to reflect reality (RK-with-Euler-stages
is closest to low order) and correct the step-controller exponent and SDS claim; real fix is
implementing an actual tableau (DOPRI5 fully, since its weights are already present, or
DOP853), then adding the free cross-check against `Kepler.Propagate` for two-body cases.
**Owner level:** project.

## R3 — False formal-verification claims in shipped source and scope docs (score 20: 4 x 5)

**Risk:** Source headers state "proven free of runtime errors"/"formally verified"
(`vectors.ads:7`, `kepler.ads:10`, `stumpff.ads:11`, `matrices.ads:7`, `twobody.ads:10`)
while 11 of 12 library bodies are `SPARK_Mode => Off`; gnatprove has never run in any
pipeline (absent from the Alire 2.0.2 toolchain, `ci.yml:70-73`). The authoritative scope
table is wrong in both directions: `spark-scope.md:54-55` claims Vectors=Gold "Fully
proven"/Matrices=Silver "Proven" (bodies Off), and `spark-scope.md:73` claims Threebody's
body is Off when it is the only body that is On (`threebody.adb:8`). README markets
"silver across the codebase, gold on kernel routines, platinum experiments."
**Evidence:** 30-security.md M3; 31-quality.md Q-9/§5; 20-domain-dimensional-foundation.md
§6; 20-domain-classical-astrodynamics.md §6; all SPARK_Mode aspects grep-confirmed this
phase.
**Blast radius:** any consumer who skips defensive checks because the library says it is
proven; the project's certification credibility (a false assurance claim discovered by an
auditor is far more damaging than an honest "pending"); Threebody's contradicted pragma
will also break the first real gnatprove run.
**Smallest credible mitigation:** one editing pass replacing "proven/verified" with
"contracts defined; body proof pending (Bronze)"; fix `spark-scope.md` rows 54-55 and 73;
set `threebody.adb:8` to `Off` with the standard exemption comment (or record a dated
decision reversing ISS-040 for that file).
**Owner level:** quick fix.

## R4 — The DO-178C evidence chain is structurally broken end to end (score 20: 4 x 5)

**Risk:** Independent of R1's gating problem, the certification artifacts cannot support the
claims they make: (a) RTM uses `HLR-TB-*`-style IDs, SRS/test-RTM use `HLR-1A-*` — disjoint
namespaces, zero mechanical cross-references, so the claimed "bidirectional traceability"
(`rtm.md:13`) cannot be walked; SDS contains no HLR IDs at all; (b) test-rtm.md marks 234
tests in 10 packages "Complete" but none are reachable from any CI build; (c) the MC/DC
coverage build (`ada/coverage.gpr` → `test_driver_coverage.adb`) does not compile — its
dependencies reference `Elements.Arg_Periapsis` and an `Epoch` field that
`Orbital_Elements` does not have (`hale_tests-vallado.adb:71,110`,
`hale_tests-exceptions.adb:185-214` vs `hale_orbital-types.ads:114`, re-confirmed);
(d) `coverage-guide.md` and `level-b-roadmap.md` reference a `.github/workflows/coverage.yml`
that does not exist, and the roadmap checkboxes are stale against the file tree.
**Evidence:** 20-domain-certification-safety.md §3-§6; 31-quality.md Q-5/Q-8;
20-domain-classical-astrodynamics.md §6.
**Blast radius:** the entire certification work product — the paper trail is currently
evidence of intent, not evidence. Any external DO-178C-literate reviewer would fail it in
the first hour.
**Smallest credible mitigation:** fix the two field names so `coverage.gpr` compiles; pick
one HLR namespace and mechanically rewrite the other document; annotate test-rtm.md
"Complete" as "implemented, not CI-executed" until R1/R7 land.
**Owner level:** project.

## R5 — Lambert returns Converged=True with NaN/Inf velocities in every build mode (score 16: 4 x 4)

**Risk:** `Solve_Lambert`/`Solve_Lambert_Bounded` divide by `C_Z`, `Sqrt(C_Z)`,
`1.0 - Z*C_Z`, and `G_Func` with no positivity guards (`lambert.adb:156,161,171-176,187,
224-228,236-237,311-322,353-364`, re-confirmed); `Stumpff.C`'s postcondition is `>= 0.0`,
zero permitted. On IEEE GNAT targets float division by zero silently yields Inf/NaN in
**all four build modes** (`-gnato` is integer-overflow only; no mode sets `-gnateF` —
confirmed against `hale_orbital.gpr`). Nothing downstream checks finiteness, so a maneuver
planner can consume non-finite delta-Vs under a `Converged = True` flag. Tracked as
Critical/Open ISS-010 in `compliance-issues.csv` — the project knows, and no regression net
exists (R1). Related: `Solve_Lambert` also silently accepts collinear R1/R2 despite
`docs/specs/05-lambert.md` claiming it raises `Invalid_Orbit` (30-security.md L3).
**Evidence:** 30-security.md H2 (including its correction of the domain report's `-gnato`
claim — verified correct this phase); 31-quality.md Q-6; 20-domain-trajectory-optimization.md
§5-§6.
**Blast radius:** all trajectory-design callers; both Lambert code paths (the ~90%
duplicated pair guarantees a one-sided fix is possible, compounding drift).
**Smallest credible mitigation:** guard the three denominator families with
`Small_Threshold` and set `Converged := False` on violation, plus a single `'Valid`
finiteness gate on `Result.V1/V2/A` before returning `Converged := True`; apply to both
copies; add the degenerate-geometry check (`Is_Degenerate_Transfer` already exists) at
`Solve_Lambert` entry.
**Owner level:** quick fix.

## R6 — Bus factor of one, with abandonment signals (score 15: 5 x 3)

**Risk:** THOClabs is sole author of all Ada source, all tests, the Python oracle, and all
certification docs (5 of 6 commits; the 6th is review tooling). `main` is 52 days stale;
the repo has a 41-day commit gap and no tags/releases; knowledge of why RK78/RK45/Floquet
were left as stubs, or how the two issue trackers relate, exists only in one person. DO-178C
Level B itself requires verification independence the project cannot currently provide.
**Evidence:** 10-history.md §3-§4, §6; 20-domain-certification-safety.md §6 (bus factor
note); commit log.
**Blast radius:** project continuity itself — loss of the single author strands ~12k LOC of
sole-sourced, partially-documented safety-critical code plus an unfinished certification
program.
**Smallest credible mitigation:** this review corpus is itself the first mitigation (written
knowledge transfer); next steps are tagging a versioned release of the current state,
merging review output to `main`, and recruiting/assigning one independent reviewer for the
certification domain specifically (doubles as the DO-178C independence requirement).
**Owner level:** strategic.

## R7 — The real test estate is orphaned, and what CI runs is the smallest harness (score 15: 3 x 5)

**Risk:** The repository's substantive test coverage — `hale_tests-boundaries`, `-negative`,
`-periodic_orbits` (20+ CR3BP tests), `-lambert_multirev`, `-integration`, etc. — is
unreachable: `run_all_tests.adb`, the only runner that wires all 10 suites and propagates
exit status, is Main of no `.gpr` (grep-confirmed); the coverage driver that wires 6 suites
does not compile (R4c); CI builds only the self-contained 64-assertion `run_tests.adb`.
Additionally two assertion conventions coexist with opposite semantics (raising `Assert*` vs
counter-only `Run_Test`), and the examples project is never built by CI —
`orbit_propagation.adb` calls nonexistent `Periapsis_Radius`/`Apoapsis_Radius`
(`orbit_propagation.adb:72,75`, re-confirmed) and cannot compile.
**Evidence:** 20-domain-certification-safety.md §2-§3; 20-domain-restricted-astrodynamics.md
§6; 31-quality.md Q-4/Q-8/§2; 20-domain-classical-astrodynamics.md §6.
**Blast radius:** every domain's regression safety; the hyperbolic/near-parabolic/exception
paths of the classical kernel and the entire STM/Floquet/Halo machinery have zero executed
coverage anywhere; onboarding (examples are the documented entry point and one is broken).
**Smallest credible mitigation:** add `run_all_tests.adb` to `hale_tests.gpr`'s Main list
and run it in CI; fix the two example call sites; add a compile-only CI step for
`hale_examples.gpr` and `coverage.gpr`.
**Owner level:** quick fix (wiring) + project (rationalize the two assertion mechanisms).

## R8 — Aspirational documentation presented as current state (score 15: 3 x 5)

**Risk:** README.md describes nonexistent `data/` and `validation/` directories, a
copy-pasteable test command that fails on a path error (`pytest validation/`), "Lambert
(Izzo)", Gold/Platinum proof levels, and a "Python oracle generates CSV reference data the
Ada tests compare against" pipeline — none true. This is proven harmful, not cosmetic: the
Phase-1 inventory ingested three of these claims verbatim and re-emitted them as findings
(see 40-architecture.md §6), and any human contributor or automated tool reading README
inherits the same false model. DEC-005 and level-b-roadmap checkboxes are similarly stale.
**Evidence:** 31-quality.md Q-10/Q-15/§7; 20-domain-trajectory-optimization.md Quality 5-6;
20-domain-restricted-astrodynamics.md §3, §6; verified against README this phase.
**Blast radius:** every downstream reader, reviewer, and tool; new-contributor onboarding
(the documented fresh-container path fails at step 2 of 6, 31-quality.md §7).
**Smallest credible mitigation:** one truth-pass over README (present vs. "planned" split —
`docs/ARCHITECTURE.md` already models the right convention); update DEC-005 and roadmap
checkboxes.
**Owner level:** quick fix.

## R9 — Silent-wrong-answer cluster in foundation and CR3BP (score 9: 3 x 3)

**Risk:** A family of small, confirmed defects that return plausible-but-wrong numbers with
no diagnostic: `Is_Singular` (1e-12) vs `Inverse` (1e-15) disagree by 1000x, so a
"singular" matrix inverts silently (`matrices.ads:69` vs `matrices.adb:128-130`);
`Integration_Method.RK45` silently executes fixed-step RK4 (`threebody.adb:304`,
re-confirmed); `Analyze_Floquet` returns 4 of 6 multipliers that are not eigenvalues, with
no validity flag; `Compute_Lagrange_Point` has no convergence signal at all (stalled Newton
returns silently); `Sun_Earth_System.Mass_Ratio` disagrees with its own `Mu1/Mu2` fields by
~4.5 ppm; precondition density is inconsistent across sibling functions (`twobody.ads:
127-148`, `lambert.ads:118-137`).
**Evidence:** 31-quality.md Q-3/Q-14; 20-domain-dimensional-foundation.md §5;
20-domain-restricted-astrodynamics.md §4-§6; 30-security.md I4/L4.
**Blast radius:** contained per defect, but the foundation items sit in the layer 22 of 24
files import, and all are invisible to callers by construction — exactly the defect class a
safety library exists to prevent.
**Smallest credible mitigation:** align the two Matrices thresholds to one named constant;
remove or implement `RK45`; add `Valid`/`Converged` fields to `Floquet_Result` and
`Lagrange_Result`; derive `Mass_Ratio` from `Mu1`/`Mu2` (or assert the invariant); add the
missing `Pre` contracts.
**Owner level:** project (a batch of quick fixes, but needs the R1/R7 net in place first so
the fixes are locked in by tests).

## R10 — Supply-chain and bootstrap integrity gaps (score 8: 4 x 2)

**Risk:** The toolchain that would compile the "certified" library has no provenance
controls: `.claude/setup.sh:44-68` downloads and installs the `alr` binary with no
checksum/signature (currently moot only because the URL 403s in this environment);
GitHub Actions are pinned by mutable tag, not SHA (`ci.yml:27,30,58,61,80,81,102`);
`ci.yml` has no `permissions:` block and checkouts persist credentials, so unpinned,
floor-only PyPI installs execute with token access; there is no lockfile anywhere (no
`alire.lock`, no Python pin). Additionally `setup.sh` always exits 1 via a leaked `RETURN`
trap and the SessionStart hook masks it (`settings.json:9` `| tail -40`), so the bootstrap
cannot report real failures either — reproduced live twice by independent reviewers.
**Evidence:** 30-security.md M1/M2/L1/L5/L6; 31-quality.md Q-2/Q-17;
20-domain-certification-safety.md §6.
**Blast radius:** toolchain and CI trust — the exact tool-qualification surface DO-178C
cares about; developer onboarding (bootstrap is the documented path and it is broken).
**Smallest credible mitigation:** SHA-256 pin the alr download; `permissions: contents:
read` + `persist-credentials: false` in ci.yml; SHA-pin the three actions; add a
`constraints.txt`; fix the trap (`trap 'rm -rf "${tmp:-}"; trap - RETURN' RETURN`) and
remove the exit-code-masking `tail` pipe.
**Owner level:** quick fix.

---

## Reading the register as a whole

The top four risks are one story: **the project's assurance layer asserts things its code
does not do** — CI that validates nothing (R1), an integrator that isn't the method its
certification docs cite (R2), proofs that were never run (R3), and a traceability chain
with no working links (R4). None of these is expensive to fix; R1, R3, R5, R8, and R10 are
each under a day. The strategic risk (R6) is the only one a patch cannot close, and it
argues for landing the quick fixes *now*, while the sole author's context is still warm and
this review corpus is fresh enough to serve as the transfer document.

Recommended sequence: R1 → R7(wiring) → R5 → R3 → R8 → R10 (all quick fixes, ~2-3 days
total, each locked in by the newly-gating CI), then R4 and R2 as planned projects, with R9
batched behind them, and R6 addressed by governance in parallel.
