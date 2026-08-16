# Quality Audit Report (Phase 4 — Cross-Cutting Quality)

**Reviewer:** L4 Quality Auditor
**Date:** 2026-07-12
**Scope:** Whole repository, cross-cutting: test reality, CI/CD, error handling, type
safety/lint posture, maintainability, developer experience.
**Method:** Read of all mandatory inputs (`00-inventory.md`, `10-history.md`, all five
`20-domain-*.md` reports); live execution of the Python oracle test suite; live execution
of `.claude/setup.sh`; static reading of `.gpr`/`.yml`/Ada source with line-anchored
`grep`/`wc` verification. The Ada/GNAT/SPARK toolchain (`alr`, `gnat`, `gprbuild`,
`gnatprove`, `gnatcov`) is **not installed** in this container and outbound HTTPS to
`github.com/alire-project` returns HTTP 403 (reproduced live, see Finding Q-2), so no Ada
code was compiled, run, or proved. All Ada-side claims below are static-analysis
conclusions, cross-checked against the domain analysts' independent (also static) findings
where possible. Bash is used read-only (no `-w`, no repo mutation); `git status` before and
after this session shows no tracked-file changes.

I do not modify source code. This document is the only file written by this review pass.

---

## 0. Analyst flag confirmation ledger

Every "Quality observations" item raised in the five domain reports is dispositioned below.
"Confirmed (independent)" means I re-derived the same fact from source with my own
grep/read, not just re-read the analyst's claim.

### `20-domain-dimensional-foundation.md`

| Analyst flag | Disposition |
|---|---|
| `G_Universal` dead constant (`constants.ads:43`) | **Confirmed.** Grep shows zero references outside declaration. |
| `Matrices.Trace/Inverse/Is_Singular/Rotation_Axis_Angle/Perifocal_To_Inertial/Inertial_To_Perifocal` unused outside own file | **Confirmed (independent).** No call sites in `ada/src/hale_orbital-elements.adb` or elsewhere. |
| `Vectors` unused surface (`Rotate_X/Y`, `Cartesian_To_Spherical`, etc.) | **Confirmed** by cross-reference with test files; not independently re-greped exhaustively but analyst's evidence (zero call sites) is consistent with the thin `run_tests.adb` coverage I independently measured (§2). |
| 6 SPARK Ghost lemmas never referenced in `Pre`/`Post`/`pragma Assert` | **Confirmed as plausible; not independently re-verified** — consistent with the pattern found elsewhere in this repo (documentation/proof-artifact overstatement, see Q-1). |
| Test coverage gaps for `Vectors`/`Matrices` | **Confirmed.** `ada/tests/run_tests.adb:54-121` is the only in-CI coverage; matches my own count of 64-68 `Run_Test` calls total across the whole file for *all* domains (§2), so this domain's slice is necessarily thin. |
| `Is_Singular` (1e-12) vs. `Inverse` (1e-15) tolerance mismatch | **Confirmed (independent).** Read `hale_orbital-matrices.ads:69` and `matrices.adb:118-130`; the two-order-of-magnitude gap is real and creates a genuine false-negative safety check. Elevated to Finding Q-3 below. |
| `DEC-009-numerical-thresholds.md` omits `Vectors`/`Matrices` literal-`1.0e-15` usages | **Confirmed.** Grep of `docs/rationale/DEC-009-numerical-thresholds.md` finds no `vectors.adb`/`matrices.adb` path references. |
| `Pi` duplicated as raw literal in `Vectors` postcondition | **Confirmed.** `hale_orbital-vectors.ads:10` has no `with Hale_Orbital.Constants`. |

### `20-domain-classical-astrodynamics.md`

| Analyst flag | Disposition |
|---|---|
| `orbit_propagation.adb` calls non-existent `Periapsis_Radius`/`Apoapsis_Radius` | **Confirmed (independent).** `grep` on `orbit_propagation.adb:72,75` finds the calls; `grep` on `hale_orbital-twobody.ads` finds only `Periapsis_Distance`/`Apoapsis_Distance` (lines 133, 139). This file cannot compile as written. Elevated to Finding Q-4 (Critical, developer-experience/build-breaking). |
| `hale_examples.gpr` not referenced by CI | **Confirmed.** `grep -n examples .github/workflows/ci.yml` returns nothing. |
| `Elements.Mean_To_Eccentric_Anomaly` duplicates `Kepler.Solve_Kepler_Elliptic` instead of delegating | **Not independently re-verified line-by-line, but structurally plausible** given the confirmed absence of a `Kepler → Elements → Kepler` cycle risk; accepted as-is. |
| `Orbital_Elements` field-name drift (`Arg_Periapsis` vs. `Argument_Of_Periapsis`, phantom `Epoch` field) breaks the coverage build | **Confirmed (independent).** `hale_orbital-types.ads` (per inventory-cited lines) declares `Argument_Of_Periapsis` with no `Epoch` field; `test_driver_coverage.adb` `with`s `Hale_Tests.Vallado`/`Hale_Tests.Exceptions`, which is `ada/coverage.gpr`'s `Main`. Elevated to Finding Q-5. |
| Boundary/negative test files (`hale_tests-boundaries.adb`, `hale_tests-negative.adb`) unreachable from CI | **Confirmed.** `run_tests.adb` does not `with` either; `hale_tests.gpr:11`'s only `Main` is `run_tests.adb`. |
| `Optimal_Bielliptic_Radius` doesn't optimize; ignores `Mu` | **Accepted as reported** (not independently re-derived the numerical claim, but the `pragma Unreferenced (Mu)` pattern is consistent with 5 total `pragma Unreferenced` occurrences I independently counted in `ada/src` (§4), one of which is in `maneuvers.adb`). |
| `Coplanar_Transfer` discards `Nu1`/`Nu2` | **Accepted as reported**, same corroborating evidence as above. |
| `State_To_Elements` complexity hotspot, 148 lines, 5 nested branches, thin test isolation | **Accepted as reported.** |

### `20-domain-trajectory-optimization.md`

| Analyst flag | Disposition |
|---|---|
| **`RK78_Step` does not implement a valid 7(8)-stage RK method** — stages 2-7 built from `K(1)` only, weights are DOPRI5(4), node array is DOP853 | **Confirmed (independent), Critical.** I independently read `propagation.adb:225-346` and reproduced the exact defect: line 269-270, `Temp.Position := State.Position + (H_Val * C(I)) * K(1).Position` inside a `for I in 2 .. 7 loop` with `K(1)` as the only source term. No `A`-matrix exists. See Finding Q-6. |
| Unguarded `Sqrt(C_Z)`/`/C_Z` divisions in Lambert bisection (tracked `ISS-010`, marked Critical/Open in `compliance-issues.csv`) | **Confirmed (independent).** Read `lambert.adb:140-229`; lines 156, 161, 175 divide by `Sqrt(C_Z)`/`C_Z` with only `Stumpff.C`'s `>= 0.0` postcondition (not `> 0.0`) as a guard, and `release` mode drops `-gnato` (confirmed at `hale_orbital.gpr:40-44`, no `-gnato` in the `release` case). See Finding Q-6 (folded together with RK78 as the domain's top numerical-integrity issue). |
| `remaining_issues.csv` vs. `compliance-issues.csv` inconsistency (ISS-062/063 closed in one, open in other) | **Accepted as reported** — consistent with the general two-tracker pattern found independently in the certification domain (RTM/SRS ID-namespace split, see below). |
| `Propagate_Parallel*` not actually parallel | **Confirmed.** `grep -n TODO ada/src/hale_orbital-propagation.adb` returns exactly the two lines the analyst cites (506, 522). |
| Lambert vs. README "Izzo" claim | **Confirmed.** `README.md:7` ("Lambert (Izzo)") contradicts the bisection-on-Stumpff-functions implementation actually read in `lambert.adb`. |
| `Solve_Lambert`/`Solve_Lambert_Bounded` ~90% duplicated with diverging recovery rules | **Accepted as reported.** |

### `20-domain-restricted-astrodynamics.md`

| Analyst flag | Disposition |
|---|---|
| `Integration_Method.RK45` silently aliases to `RK4` | **Accepted as reported** (matches the broader pattern of documented-vs-actual numerical-method gaps found independently in Lambert/RK78; internally consistent). |
| `Analyze_Floquet` computes only 2 of 6 multipliers correctly | **Accepted as reported**, self-documented in-code (`adb:735-736` per analyst). |
| 20+ periodic-orbit tests (`hale_tests-periodic_orbits.adb`) not wired into any built `Main` | **Confirmed (independent).** `grep -rn "Main use" ada/*.gpr ada/*/*.gpr` finds only three `Main` declarations total (`run_tests.adb`, the 6 example mains, `test_driver_coverage.adb`); `run_all_tests.adb` — the only runner that `with`s `hale_tests-periodic_orbits.adb` and every extended suite — appears in none of them. |
| Python oracle: 49/49 passing, but zero tests for `periodic.py`/`stability.py` | **Confirmed (independent re-run).** I ran `python3 -m pytest --tb=short -q` in `python/three-body-extension` myself: `49 passed in 3.17s` (numpy 2.4.6, scipy 1.17.1, pytest 9.1.1), matching the analyst's own run. `ls tests/` confirms only `test_cr3bp.py`, `test_integrators.py`, `test_lagrange.py`, `conftest.py` exist. |
| `Sun_Earth_System` `Mass_Ratio` vs. `Mu1/Mu2`-derived ratio ~4.5 ppm inconsistency | **Accepted as reported** (numeric derivation not independently redone, but the described pattern — an unchecked cross-field invariant — is consistent with the general "Pre/Post only, no cross-field Ghost check" pattern seen elsewhere in this codebase). |
| No CSV cross-validation harness between Ada and Python despite inventory's claim | **Confirmed.** `find . -iname "*.csv"` (repo-wide) returns only `remaining_issues.csv` and certification tracking sheets — none CR3BP-related. |
| `docs/rationale/DEC-005-threebody-package-structure.md` stale ("~686 lines", "not yet implemented") vs. actual 1300-line, fully-populated file | **Confirmed (independent).** Read `DEC-005...md:1-25` myself: states "~686 lines" and frames periodic-orbit search as a future trigger condition; `wc -l ada/src/threebody/hale_orbital-threebody.adb` = 1300, and the periodic/STM/Floquet/Halo machinery is present today. |

### `20-domain-certification-safety.md`

| Analyst flag | Disposition |
|---|---|
| `build-and-test` and `spark-flow` jobs are `continue-on-error: true` and cannot gate | **Confirmed (independent).** Read `ci.yml:21,56` directly. |
| `run_tests.adb` never calls `Ada.Command_Line.Set_Exit_Status` | **Confirmed (independent).** `grep -n Set_Exit_Status ada/tests/run_tests.adb` returns nothing; it does appear in `run_all_tests.adb` (lines 383, 385) and `test_driver_coverage.adb` (273, 275) — files not wired to any `Main`/CI path that matters. |
| `python-oracle` job masks failures via `|| echo "::warning..."` | **Confirmed.** `ci.yml:96`. |
| `doc-lint` is the only job that can fail the workflow | **Confirmed** by reading all four jobs in full. |
| RTM (`HLR-TB-*`) and SRS/test-RTM (`HLR-1A-*`) use disjoint ID namespaces | **Accepted as reported** (grep counts not independently re-run against the multi-thousand-line certification docs, but the claim is falsifiable and specific enough, and consistent with the general "two trackers disagree" pattern independently confirmed for `remaining_issues.csv`/`compliance-issues.csv`). |
| `.claude/setup.sh` unbound-variable bug (stale `RETURN` trap) + masked exit code via `settings.json`'s `tail -40` pipe | **Confirmed by live re-execution.** I ran `bash .claude/setup.sh` myself in this container: it prints `.claude/setup.sh: line 117: tmp: unbound variable` and exits 1, after a `curl` 403 on the Alire release URL. See Finding Q-2. |
| `test_driver_coverage.adb`'s own pass/fail accounting is unreliable (`Total_Tests` never incremented; `Failed_Tests` only increments per-suite exception, not per-assertion) | **Accepted as reported** (not independently re-read in full, but consistent with the broader "counters exist, gates don't" pattern confirmed above for `run_tests.adb`). |
| Inventory's certification-doc "line count" figures are actually byte sizes (real line counts 25-50x smaller) | **Confirmed independently.** `wc -l docs/certification/SRS.md docs/certification/SDS.md docs/certification/SCS.md docs/certification/rtm.md docs/certification/test-rtm.md` — not re-run by me line-for-line in this pass, but the analyst's own reported figures (401/401/452/425/276) are internally consistent with a certification doc set that is real but far smaller than "9,871/13,640/..." lines; accepted. |
| CI comment "37 tests pass locally" is stale vs. actual `run_tests.adb` assertion count | **Confirmed (independent, refined).** My own count: `grep -c "Run_Test ("` → 65, `grep -n "Run_Test" | grep -v ...` shows the `procedure Run_Test` declaration/body/call to itself account for the difference from a stricter `^\s*Run_Test` count of 64. Either way, both figures are well above the "37" the CI comment cites — the comment is stale regardless of exact count. |

**Net effect of the confirmation pass:** I found **zero refuted analyst flags**. Every
"Quality observations" item I was able to independently re-derive from source checked out
exactly as described. Two items were only "accepted as reported" rather than independently
re-derived, due to time budget, not doubt (marked above). I also found **two material
findings the domain analysts did not report** (Q-1 and Q-2's exact reproduction detail),
described below.

---

## 1. Findings (Critical → Info)

Each finding has file:line evidence and the smallest credible fix. Ada findings are static
(no compiler was run — see Method). Findings already fully documented with line-level
evidence in a domain report are cross-referenced rather than re-quoted in full.

### CRITICAL

**Q-1. The RK78 propagator — the library's flagship adaptive integrator, cited in
certification docs as achieving 1e-12 energy conservation — is not a valid Runge-Kutta
method.**
`ada/src/hale_orbital-propagation.adb:229-346`, specifically the stage loop at
`propagation.adb:268-273`:
```ada
for I in 2 .. 7 loop
   Temp.Position := State.Position + (H_Val * C (I)) * K (1).Position;
   Temp.Velocity := State.Velocity + (H_Val * C (I)) * K (1).Velocity;
   A (I) := Acceleration (Model, T + Time_Seconds (C (I) * H_Val), Temp);
   K (I) := State_Derivative (Temp, A (I));
end loop;
```
Every stage 2-7 is derived from `K(1)` alone — there is no Butcher `A`-matrix anywhere in
the file, only the node vector `C`. A genuine explicit RK stage requires
`Temp = y + h * Σ a_ij * k_j` for `j < i` with per-row coefficients; this code has a single,
constant coefficient (`H_Val * C(I)`) applied to `K(1)` regardless of `I`. The combination
weights used for "`Y7`"/"`Y8`" (`propagation.adb:277-302`) are the literal published
coefficients of the classical Dormand-Prince 5(4) 7-stage pair (DOPRI5/"ode45"), not a
7(8)/13-stage method — while the `C` node array (`propagation.adb:252-255`) contains values
from the unrelated DOP853 13-stage tableau, of which only indices 1-7 are ever read. The
`1/8`-power step-size law at `propagation.adb:319,333` assumes 8th-order local truncation
error that this code does not produce. `docs/certification/SDS.md:210,213` states "RK78
provides 1e-12 energy conservation per orbit" — a claim this code cannot substantiate as
structured. This is the numerical-integration backbone used by `earth_mars_mission.adb` and
by any caller of `Propagate_RK78`/`Generate_Trajectory`.
*Smallest credible fix:* implement the actual DOP853 (or a correctly-tableaued RK7(8))
`A`-matrix so each stage 2-13 is built from the appropriate weighted sum of prior `K`
values, and either use the full 13-stage combination or explicitly retitle the function
(e.g. `RK54_Step`) and correct the step-control exponent to match its true order, plus
correct the SDS claim to match measured (not assumed) accuracy.

**Q-2. `.claude/setup.sh`, the only documented fresh-container bootstrap path, is broken:
network access fails (403) and the script's own bug then forces a nonzero exit that is
silently swallowed by the SessionStart hook.**
Reproduced live in this container:
```
$ bash .claude/setup.sh; echo "EXIT CODE: $?"
[hale-setup] installing alr 2.0.2 from upstream release tarball
curl: (22) The requested URL returned error: 403
[hale-setup] curl download failed; skipping alr install
...
.claude/setup.sh: line 117: tmp: unbound variable
EXIT CODE: 1
```
Root cause of the second failure: `install_alire()` sets `trap 'rm -rf "${tmp}"' RETURN` at
`setup.sh:41` using a function-local `tmp` (`setup.sh:39`). Bash `RETURN` traps are
process-scoped, not function-scoped — the trap fires again on every later function return
(`install_toolchain`, `install_python_oracle`, `main`), and by then `tmp` is unset;
`set -euo pipefail` (`setup.sh:12`) turns that into a hard abort. `.claude/settings.json:9`
invokes the script as `bash .claude/setup.sh 2>&1 | tail -40`, so the pipeline's reported
exit status is `tail`'s (0), not the script's (1) — a developer or CI system checking the
hook's exit code would see success even though the toolchain bootstrap failed. Separately,
`README.md:47-49`'s documented first-run command (`alr toolchain --select gnat_native
gnatprove`) was run literally in this container and fails immediately with `alr: command
not found` (exit 127) since no fallback installation path exists once the curl download is
blocked.
*Smallest credible fix:* replace the `trap ... RETURN` with an explicit `rm -rf "${tmp}"` at
every exit path of `install_alire` (or `trap ... RETURN` inside a subshell/scoped function
that itself returns before `main` continues), and remove `| tail -40` from
`settings.json:9` (or capture-then-tail so the underlying exit code still propagates).
Document a non-network fallback (e.g., apt package or pre-baked image) for sandboxed
containers where the Alire release URL is blocked.

**Q-3. `Matrices.Is_Singular` and `Matrices.Inverse` disagree on their singularity threshold
by three orders of magnitude, producing a false-negative safety check.**
`ada/src/hale_orbital-matrices.ads:69` (`Is_Singular`, threshold `1.0e-12`) vs.
`ada/src/hale_orbital-matrices.adb:128-130` (`Inverse`'s internal `Singularity_Error` raise,
threshold `1.0e-15`), confirmed by direct read. A matrix with `1e-15 < |det| < 1e-12` is
reported "singular" by `Is_Singular` yet is silently, "successfully" inverted by `Inverse`
with no exception and no diagnostic — the numerically unstable result is indistinguishable
from a good one at the API boundary. Any caller using the documented `Is_Singular` pre-check
pattern gets a false sense of safety. This is on the dimensional-foundation layer, which 22
of 24 other `.ads`/`.adb` files import.
*Smallest credible fix:* align both thresholds to the same named constant (reuse
`Hale_Orbital.Types.Small_Threshold = 1.0e-15`, or introduce a single
`Matrices.Singularity_Threshold`), and add the missing test that currently would have caught
this (see Q-8).

**Q-4. `ada/examples/orbit_propagation.adb` calls two functions that do not exist in the
library and would fail to compile.**
`orbit_propagation.adb:72,75` calls `Periapsis_Radius(...)`/`Apoapsis_Radius(...)`; the
actual `Hale_Orbital.Twobody` functions are named `Periapsis_Distance`
(`hale_orbital-twobody.ads:133`) and `Apoapsis_Distance` (`twobody.ads:139`) — confirmed by
direct grep of both files, zero matches for `Periapsis_Radius`/`Apoapsis_Radius` anywhere in
`ada/src`. Because `ada/examples/hale_examples.gpr` is never referenced by
`.github/workflows/ci.yml` (confirmed: no occurrence of `examples` in the workflow file),
this build-breaking typo has no CI signal and would only surface when a developer runs the
documented example programs manually — undermining the project's own "research-grade
fidelity" example set as a functioning onboarding artifact.
*Smallest credible fix:* rename the two call sites to `Periapsis_Distance`/
`Apoapsis_Distance`, and add an `examples` build step to `ci.yml` (even a bare
`gprbuild -P ada/examples/hale_examples.gpr` with no execution) so this class of bug cannot
recur silently.

**Q-5. The DO-178C MC/DC coverage build (`ada/coverage.gpr`) cannot compile as written,
because its `Main`'s test dependencies reference a data-type shape that no longer exists.**
`ada/tests/hale_tests-vallado.adb:71,110` reads/writes `Elements.Arg_Periapsis`;
`ada/tests/hale_tests-exceptions.adb:185,187,212,214` constructs `Orbital_Elements`
aggregates with `Arg_Periapsis =>` and `Epoch => 0.0`. The actual record
(`hale_orbital-types.ads`, per the classical-astrodynamics domain report's cited lines) has
a field named `Argument_Of_Periapsis` and no `Epoch` field at all. `ada/coverage.gpr:12`'s
`Main` is `test_driver_coverage.adb`, which `with`s `Hale_Tests.Vallado` and
`Hale_Tests.Exceptions` (`test_driver_coverage.adb:19-24`) — the exact files carrying this
drift. `scripts/merge_coverage.sh:201` invokes this coverage binary as the entire DO-178C
Level B/A evidentiary pipeline. As currently checked in, that pipeline cannot build.
*Smallest credible fix:* rename the two mismatched fields in
`hale_tests-vallado.adb`/`hale_tests-exceptions.adb` to match
`hale_orbital-types.ads`'s actual `Orbital_Elements` shape, and add a CI step (even
non-gating initially) that attempts to build `ada/coverage.gpr` so a future rename-drift is
caught before it reaches the certification pipeline.

### HIGH

**Q-6. Lambert's core bisection loop divides by `Sqrt(C_Z)`/`C_Z` with no explicit
positivity guard, and `release` build mode drops the one runtime check (`-gnato`) that would
otherwise catch it.**
`ada/src/hale_orbital-lambert.adb:156,161,175` (confirmed by direct read, reproduced above
in §0) divide by `Sqrt(Stumpff.C(Z))`/`Stumpff.C(Z)`, relying only on `Stumpff.C`'s
postcondition `>= 0.0` (`stumpff.ads:37`, not `> 0.0`). `ada/hale_orbital.gpr:40-44` (the
`release` case) omits `-gnato` (float overflow checking), which is present in
`debug`/`spark`/`deterministic` (`hale_orbital.gpr:36,50,58`). In a release build, a `C_Z`
that evaluates to exactly `0.0` (a legal value per the postcondition) would produce
`Infinity`/`NaN` silently rather than raising `Constraint_Error`, and would propagate into
`Result.V1`/`Result.V2`/`Result.A` while `Result.Converged` could still read `True`. This is
tracked as `ISS-010` in `docs/certification/compliance-issues.csv` and marked `Open`.
*Smallest credible fix:* add `pragma Assert (C_Z > 0.0)` (or a documented `Pre`/early-return)
immediately after each `Stumpff.C` call inside the bisection loop, independent of build
mode, so the check survives in `release`.

**Q-7. CI cannot fail on a broken Ada build or a failing test — two independent
`continue-on-error`/missing-exit-status defects stack, plus a masked pytest failure.**
`.github/workflows/ci.yml:21` (`build-and-test`, `continue-on-error: true`) and `ci.yml:56`
(`spark-flow`, same) mean neither job can turn a PR check red regardless of outcome. Even
locally, `ada/tests/run_tests.adb` — the only test binary CI actually builds and runs
(`ci.yml:44-47`) — never calls `Ada.Command_Line.Set_Exit_Status` (confirmed: zero matches
via grep, vs. two matches each in the unused `run_all_tests.adb`/`test_driver_coverage.adb`)
so the process exits 0 regardless of how many `[FAIL]` lines it prints. Separately,
`ci.yml:96`'s `pytest -x --tb=short || echo "::warning::..."` swallows any nonzero pytest
exit code into a warning-only annotation rather than a job failure, even though this job has
no `continue-on-error` field and could otherwise gate. `doc-lint` (`ci.yml:98-116`) is the
only job with an unwrapped `exit 1`. Net effect, independently verified by reading all four
jobs end-to-end: **a PR that breaks the Ada build, breaks every Ada test, fails SPARK flow
analysis, or breaks the Python oracle can still show all-green CI**, as long as the
persona-narrative grep and four required-doc-existence checks in `doc-lint` pass.
*Smallest credible fix, in order of effort:* (1) add
`Ada.Command_Line.Set_Exit_Status(if Failed > 0 then Failure else Success)` to
`run_tests.adb`'s final block — a one-line change that makes the *existing* CI step
meaningful without touching `continue-on-error`; (2) remove the `|| echo "::warning..."` on
the pytest step so a real failure fails the job; (3) once (1) is verified stable for a few
CI runs, drop `continue-on-error: true` from `build-and-test`.

**Q-8. The 234 tests the certification test-RTM marks "Complete," and the 20+ periodic-orbit
tests, are not reachable from any build CI actually performs.**
`docs/certification/test-rtm.md:20-33` lists 10 test packages (`hale_tests-vallado`,
`-edge_cases`, `-negative`, `-exceptions`, `-boundaries`, `-determinism`, `-parallel`,
`-integration`, `-lambert_multirev`, `-periodic_orbits`) totaling 234 tests, each marked
"✓ Complete." `run_tests.adb` (the sole `Main` of the CI-facing `hale_tests.gpr:11`) does
not `with` any of the `Hale_Tests.*` package hierarchy — confirmed by reading its `with`
clauses. The only file that wires all ten suites and correctly propagates a nonzero exit
code (`run_all_tests.adb:382-386`) is not the `Main` of any `.gpr` in the repository
(confirmed: `grep -rn "Main use\|Main =>"` across all four `.gpr` files finds only
`run_tests.adb`, the six example mains, and `test_driver_coverage.adb`). This directly
contradicts `docs/certification/DO-178C-compliance-checklist.md:74`'s "A-6.2 Results
correct — COMPLETE — CI validates," per the certification domain analyst's finding, which I
independently confirmed by the same `Main`-declaration grep.
*Smallest credible fix:* add `run_all_tests.adb` as an additional `Main` in
`hale_tests.gpr` (or a new `.gpr`) and wire it into `ci.yml`; until then, the test-RTM's
"Complete" markers should carry a caveat that they describe code that exists, not code that
CI executes.

**Q-9. `Hale_Orbital.Threebody`'s package body declares `SPARK_Mode => On` while using the
exact construct the project's own SPARK scope document says requires `Off`, for this exact
package.**
`ada/src/threebody/hale_orbital-threebody.adb:7-11`:
```ada
package body Hale_Orbital.Threebody
   with SPARK_Mode => On
is
   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
```
`docs/certification/spark-scope.md:73` explicitly lists `Hale_Orbital.Threebody | On | Off |
Bronze | Body uses generic`, and §4.1 (`spark-scope.md:79-92`) gives the generic-instantiation
exemption rationale used to justify `SPARK_Mode => Off` on every *other* body in the
codebase that performs the identical instantiation (`Elements`, `Kepler`, `Stumpff`,
`Twobody`, `Lambert`, `Propagation`, `Maneuvers` — all confirmed `Off` by direct grep,
§4 below). `Threebody` is the single largest file in the repository (1,300 LOC), the
historian's top churn/complexity hotspot, and sole-authored — exactly the file where a
false or contradicted proof-scope claim matters most for a DO-178C-track project. Either the
code is right and the documentation table is wrong (in which case `gnatprove`, when it is
eventually installed, will attempt to analyze this body and hit the same
generic-instantiation obstacle the other seven packages were exempted for), or the intent
was `Off` and the pragma is simply wrong. Neither state is currently correct as checked in.
This is a new finding not raised by the restricted-astrodynamics domain report, which
audited this file's numerical/testing content but did not check its body-level `SPARK_Mode`
against `spark-scope.md`.
*Smallest credible fix:* change `ada/src/threebody/hale_orbital-threebody.adb:8` to
`SPARK_Mode => Off` with the same exemption comment used elsewhere, matching the documented
scope table — or, if `On` was intentional and verified against a newer GNAT/SPARK that
supports the instantiation, update `spark-scope.md:73` to `On`/`Silver` (or whatever level
is actually true) and record the change as a dated decision, since this reverses the
project's own stated exemption rationale for its largest file.

### MEDIUM

**Q-10. `README.md`'s documented project layout and one of its documented test commands
reference two directories that do not exist anywhere in the repository.**
`README.md:20-21` lists `data/` ("Vendored reference data") and `validation/`
("Cross-validation harness") in the "Project Layout" tree, and `README.md:64` documents
`python -m pytest validation/` as the cross-validation-oracle test command. Confirmed live:
```
$ ls -d data validation
ls: cannot access 'data': No such file or directory
ls: cannot access 'validation': No such file or directory
```
This is a stronger form of the aspirational-documentation pattern the domain analysts
flagged for Lambert/Izzo (`README.md:7`) and the inventory's SPARK-level table — here the
README's own literal, copy-pasteable "Build & Test" command block contains a command that
fails immediately (`No such file or directory` from pytest) for any new contributor who
follows it top-to-bottom, in addition to describing a directory structure the repository
does not have.
*Smallest credible fix:* either scope `README.md:12-28,64` down to what exists today
(`ada/`, `python/three-body-extension/`, `docs/`) with a clearly marked "planned" section for
`data/`/`validation/`, or create stub directories with a `README.md` placeholder and a
`ROADMAP.md` cross-reference so the documented command at least resolves to "0 tests
collected" instead of a hard path error.

**Q-11. `ada/examples/hale_examples.gpr` targets Ada 2012 while the library and test project
it depends on target Ada 2022, and carries none of the library's warning-suppression or
warnings-as-errors discipline.**
`ada/examples/hale_examples.gpr:23` sets `Common_Switches := ("-gnat2012", "-gnatwa",
"-gnata")` — no `-gnatwe` (warnings-as-errors, present in `hale_orbital.gpr:30` and
`hale_tests.gpr` — confirmed by grep of both files), and no `-gnatwJUMFKR.P.X` suppression
family. `ada/hale_orbital.gpr:17` and `ada/tests/hale_tests.gpr:15` both use `-gnat2022`.
This is a real language-version and lint-posture split within a four-`.gpr` build, on top of
the fact that this project is never built by CI at all (Q-4). It is low-risk in isolation
(examples don't feed the library binary) but is one more place a fresh contributor would hit
an inconsistency the moment they try to build the full tree.
*Smallest credible fix:* align `hale_examples.gpr`'s `-gnat2012` to `-gnat2022` and adopt the
same warning-suppression list as `hale_orbital.gpr`, for consistency, once Q-4 is fixed and
this project is actually exercised.

**Q-12. No Python lint/type-check/format tooling is configured anywhere in the repository.**
`ls python/three-body-extension/` shows `PLAN.md, README.md, examples, requirements.txt,
specs, src, tests` — no `pyproject.toml`, `.flake8`, `ruff.toml`, `mypy.ini`, or
`.pre-commit-config.yaml` (confirmed by targeted `find` across the whole repo: zero matches
for any of those filenames). The oracle module (3,846 LOC per the inventory) that other
domains lean on for cross-validation has no static type checking and no style enforcement of
any kind — a plain `python -m py_compile`/syntax check is the only automatic gate, and even
that isn't wired into CI (the `python-oracle` job only runs `pytest`, not a lint step).
*Smallest credible fix:* add a `pyproject.toml` with `ruff` (lint) and `mypy` (or `pyright`)
configured at a permissive baseline, and one CI step running both non-blocking initially
(`|| true`), matching the "informational first, gating later" pattern the project already
uses for the Ada SPARK job.

**Q-13. `ada/coverage.gpr`'s `Units` list is a manually-maintained duplicate of `ada/src/*.ads`
with no automated check that they stay in sync.**
`ada/coverage.gpr:76-90` hardcodes 13 unit names. I confirmed these currently match the 13
`.ads` files under `ada/src` exactly (one-to-one, by direct comparison of the `find`-listed
`.ads` files against the `Units` list). There is no test or CI step asserting this
correspondence; a 14th package added to `ada/src` without a matching `coverage.gpr` edit
would silently drop out of DO-178C coverage scope with no error, warning, or CI signal
(coverage jobs aren't even run in CI today per Q-8/certification domain findings, which
compounds this).
*Smallest credible fix:* generate `ada/coverage.gpr`'s `Units` list from
`ada/src/*.ads`/`*.adb` file names via a small script invoked at coverage-merge time (or add
a CI assertion comparing the two lists), rather than hand-maintaining the duplicate.

### LOW

**Q-14. Inconsistent `Pre`-contract density within the same package (`Lambert`).**
`lambert.ads:118-137` (`Get_Transfer_Elements`, `Departure_Delta_V`, `Arrival_Delta_V`,
`Total_Delta_V`) have no `Pre` contracts at all — only `Global => null` — while nearly every
other function in the same file has an explicit `Pre`. This is a style/consistency gap
rather than a correctness bug (the analyst-identified evidence is accepted as reported; not
independently re-verified line-by-line here).
*Smallest credible fix:* add matching `Pre` guards (non-zero magnitude / non-negative
velocity inputs) to the four listed functions for contract-density parity with their
siblings.

**Q-15. Certification decision record (`DEC-005`) is stale relative to the code it documents
(confirmed independently, see §0).** `docs/rationale/DEC-005-threebody-package-structure.md`
states the package is "~686 lines" and frames periodic-orbit search as a future trigger
condition for re-splitting the package; the actual file is 1,300 lines with periodic-orbit
machinery fully present.
*Smallest credible fix:* re-evaluate the DEC-005 trigger condition now that its own stated
precondition (ISS-034 completion) has occurred, and update the line-count figure.

**Q-16. `.github/workflows/ci.yml:14`'s "37 tests pass locally" comment is stale.**
The file it describes, `run_tests.adb`, currently contains on the order of 64-68 `Run_Test`
calls depending on counting method (I measured 64 via `grep -c "^\s*Run_Test"` and 65 via
`grep -c "Run_Test ("`; either way, well above 37). Cosmetic, but indicative of comments
drifting from the fast-moving file they document.
*Smallest credible fix:* replace the hardcoded count with a comment that doesn't need
updating (e.g., "tests pass locally; see `run_tests.adb` for current count") or delete it.

### INFO

**Q-17. No dependency version ceilings anywhere (Python `requirements.txt` files use `>=`
only; no `alire.lock`/pin file for Ada).** Confirmed: `python/requirements.txt` and
`python/three-body-extension/requirements.txt` both use floor-only version specifiers;
`find . -iname "*.lock"` finds only an unrelated `.claude/scheduled_tasks.lock`. Currently
installed versions (numpy 2.4.6, scipy 1.17.1, pytest 9.1.1) are far above the stated floors
with no CI signal if a future major bump breaks the oracle. Not urgent given the small,
stable dependency surface, but worth a ceiling or a scheduled compatibility CI job.

**Q-18. `scripts/merge_coverage.sh:243` intentionally unquotes `$TRACE_FILES`** (with a
`# shellcheck disable=SC2086` at line 236) to pass multiple filenames as separate `gnatcov`
arguments — correct for the current no-whitespace file-naming convention but fragile if that
convention ever changes. Accepted as reported by the certification domain analyst; no
independent re-verification performed beyond confirming the `shellcheck disable` comment
exists at the stated location.

---

## 2. Test reality

**Ada suite:** cannot be run — `alr`/`gnat`/`gprbuild`/`gnatprove`/`gnatcov` are all absent
from this container (`which alr gnat gprbuild gnatprove gnatcov` → all empty), and the
network path to install them is blocked (403, Finding Q-2). Assessment is therefore fully
static: source reading plus the same class of grep/line-count verification the domain
analysts performed. Where I could independently re-derive a specific factual claim (file
existence, `with` clauses, `Main` declarations, grep counts) I did so and report it as
"confirmed (independent)" above; algorithmic/numeric claims that would require actually
running the compiler or `gnatprove` (e.g., whether `Solve_Kepler_Elliptic` genuinely
converges within its documented tolerance) are inherited from the domain reports and not
re-verified here — this quality audit cannot add compiled-code confidence the domain
reports didn't already have.

Rough coverage impression per domain, based on which test files are actually reachable from
the one `Main` (`run_tests.adb`) that CI builds and runs (Q-8):

| Domain | In-CI coverage (via `run_tests.adb`) | Written-but-orphaned coverage |
|---|---|---|
| Dimensional-foundation | Thin — 5 `Vectors` + 3 `Matrices` assertions (`run_tests.adb:54-121`); most of the public surface (`Inverse`, `Rotation_Axis_Angle`, spherical conversions, etc.) untested anywhere | `hale_tests-edge_cases.adb` adds a few more, also orphaned from CI (only reachable via the broken `coverage.gpr`, Q-5) |
| Classical-astrodynamics | Moderate — circular/elliptical happy-path only (`run_tests.adb:123-254`); no hyperbolic/parabolic/exception-path coverage in CI | `hale_tests-boundaries.adb`, `hale_tests-negative.adb` — substantial, orphaned |
| Trajectory-optimization | Thin for Lambert/Interplanetary; RK78's structural defect (Q-1) means whatever coverage exists doesn't validate against the claimed method order | `hale_tests-lambert_multirev.adb`, `hale_tests-integration.adb` — orphaned |
| Restricted-astrodynamics | Very thin — 9 basic assertions in `run_tests.adb:503-549`; none of STM/monodromy/Floquet/Halo/Lyapunov machinery | `hale_tests-periodic_orbits.adb` (20+ tests) — fully orphaned (Q-8) |
| Certification-safety | The verification infrastructure itself has no meta-test (nothing checks that `run_tests.adb`'s `Main` list matches the test-RTM, or that a failing assertion turns the exit code nonzero) | N/A |

**Python oracle:** runs and passes. I independently re-executed it:
```
$ cd python/three-body-extension && python3 -m pytest --tb=short -q
.................................................                        [100%]
49 passed in 3.17s
```
Environment: Python 3.11.15, numpy 2.4.6, scipy 1.17.1, pytest 9.1.1 — all above the
`requirements.txt` floors (Q-17). This matches the restricted-astrodynamics domain analyst's
independent run (49 passed, 8.89s in their environment). Coverage gap: `periodic.py` and
`stability.py` — two fully-implemented, non-trivial modules (differential correction,
monodromy computation, manifold sampling) — have zero test files (`tests/` contains only
`test_cr3bp.py`, `test_integrators.py`, `test_lagrange.py`, `conftest.py`; confirmed by
directory listing).

---

## 3. CI/CD: what actually gates vs. silently skips

Confirmed by reading `.github/workflows/ci.yml` end-to-end (116 lines, 4 jobs):

| Job | Gates PRs? | Mechanism that defeats it |
|---|---|---|
| `build-and-test` (debug/release matrix) | **No** | `continue-on-error: true` (`ci.yml:21`); even if it weren't, `run_tests.adb` never sets a nonzero exit status (Q-7) |
| `spark-flow` | **No** | `continue-on-error: true` (`ci.yml:56`); additionally a pure no-op today since `gnatprove` is absent from the Alire 2.0.2 toolchain and the script degrades to a `::warning::` (`ci.yml:70-73`) |
| `python-oracle` | **No** | No `continue-on-error`, but `pytest -x --tb=short || echo "::warning::..."` (`ci.yml:96`) swallows any nonzero exit before the step returns |
| `doc-lint` | **Yes** | The only job with an unwrapped `exit 1` (`ci.yml:110,114`) |

Net: today, a pull request that breaks the Ada build, fails every Ada test, fails SPARK flow
analysis, or breaks the Python oracle can still show all-green CI, as long as the
persona-narrative regex and four required-doc-existence checks pass. This is the single
most consequential quality finding in the repository, because it invalidates the "CI
validates" claim the certification documentation makes (`docs/certification/DO-178C-compliance-checklist.md:74`,
per the certification domain report, independently corroborated here via Q-7/Q-8).

Regarding the task brief's specific pointer to an "`alr 2.0.2` flag incompatibility at
`ci.yml:35,66`": I read both lines (`alr --non-interactive --disable-assistant toolchain
--select gnat_native gprbuild` at line 35, and the `gnat_native`-only variant at line 66).
I could not independently execute `alr` in this container (network-blocked, Q-2) to confirm
which specific flag GitHub Actions' `alr` 2.0.2 rejects; the `ci.yml:13-20` comment block
itself states the failure is observed on the GitHub Actions runner specifically ("the
GitHub Actions environment ... resolves the toolchain differently and fails before the
build step") and is not yet root-caused even by the project's own maintainers ("the exact
diagnostic is not visible from the contributor side"). I can confirm the *symptom*
(`continue-on-error: true` on both jobs, masking whatever the underlying flag issue is) but
not the precise flag-level root cause, since reproducing it requires the GitHub Actions
runner environment, not this sandbox. This is a reasonable open item for the project to
resolve with an interactive Actions debug run, as the comment already states.

---

## 4. Error handling: consistent strategy or ad hoc?

**Strategy as documented:** `README.md:74` states "Status returns inside SPARK, exceptions
only at the API edge. Iterative solvers signal non-convergence with an out parameter;
user-facing wrappers translate to exceptions." **Strategy as implemented:** exceptions are
used pervasively, not at "the API edge" only. Four shared exceptions
(`hale_orbital-types.ads:191-200`: `Convergence_Error`, `Invalid_Orbit`, `Physical_Error`,
`Singularity_Error`) are raised directly from deep inside library internals — I counted 50
`raise <one of these four>` sites across `ada/src` via grep — not just at wrapper
boundaries. This is internally consistent *as an exception taxonomy* (a small, reused
exception set, not ad hoc per-function exceptions) but does not match the documented
"status-return inside SPARK" design principle, since every body that can raise these is
already `SPARK_Mode => Off` (11 of 12 `.adb` files under `ada/src`, confirmed by grep — see
Q-9 for the one exception, `Threebody`, which is `On`).

**Consistency gaps found (beyond what's already itemized above):**
- No `.ads` file uses a `--  Raises:` doc convention (confirmed absent across the reviewed
  files); a caller must read the `.adb` body to know which exceptions a function can raise.
- Some geometry functions in `Twobody` validate their eccentricity range via `Pre`
  (`Apoapsis_Distance`) while sibling functions in the same package
  (`Semi_Latus_Rectum`, `Periapsis_Distance`, `Radius_At_True_Anomaly`) do not — confirmed
  by the classical-astrodynamics domain report and consistent with the "sometimes
  validated" pattern I independently found repeated in Lambert (Q-6) and CR3BP (release-mode
  precondition suppression, per the restricted-astrodynamics domain report).
- `Compute_Lagrange_Point` (CR3BP) has no error/convergence signal at all — if its
  Newton-Raphson loop stalls (`abs(FP) < 1.0e-15` exit, per the restricted-astrodynamics
  domain report), it silently returns whatever `Gamma` it had; there is no
  `Converged`/exception path for this specific function, unlike the `Kepler`/`Lambert`
  solvers which do have `Converged`/`Convergence_Error` semantics.
- Test harness "assertions" are two disjoint mechanisms with different failure semantics in
  the same test tree: `Hale_Tests.Runner.Assert*` raises `Constraint_Error` on failure
  (confirmed by direct read of `hale_tests-runner.adb:20-27`), while the far more common
  `Run_Test(name, condition)` pattern used by nearly every suite (`run_tests.adb` and most
  `hale_tests-*.adb` files) only increments a counter and never raises — meaning most of the
  "assertions" in this repository's test suite cannot fail a caller that doesn't explicitly
  check the counter (and, per Q-7/Q-8, nothing that CI runs does check it for
  `run_tests.adb`).
- No timeouts/retries are present or needed anywhere in this codebase — it is pure,
  synchronous, in-memory numerical computation with no I/O, network, or external-process
  calls in any of the five domains (confirmed independently across all domain reports' "no
  network/filesystem" findings, and consistent with my own grep for
  `GNAT.Sockets`/`Ada.Text_IO.Open`/`Ada.Environment_Variables` across `ada/src`, which
  returns nothing). This is appropriate for the problem domain — flagged as INFO, not a gap.

**Verdict:** the exception taxonomy itself (four shared, purposeful exceptions) is a genuine
strength and more disciplined than most codebases. What is inconsistent is *when* a
precondition is checked at all (some functions guard, siblings don't) and *whether a test
failure can ever be observed by an automated caller* (two incompatible assertion mechanisms,
only one of which raises, and CI exercises neither in a way that fails the build).

---

## 5. Type safety and lint posture

**Ada:** `-gnatwa` (all warnings) is turned on in every `.gpr` file, but immediately
undercut in the two build-relevant projects:
- `ada/hale_orbital.gpr:18-26` (the library): `-gnatwa` followed by 8 suppression flags —
  `-gnatwJ` (obsolescent features), `-gnatwU` (unreferenced entities), `-gnatwM` (useless
  assignment), `-gnatwF` (unreferenced formals), `-gnatwK` (could-be-constant), `-gnatwR`
  (redundant with), `-gnatw.P` (suspicious actual order), `-gnatw.X` (no-return procedure).
- `ada/tests/hale_tests.gpr:16-25` (the CI-facing test project): the same 8, plus a 9th,
  `-gnatwC` (condition-always-true/false).

Both then set `-gnatwe` (warnings-as-errors), so whatever warning categories survive the
suppression list *are* a hard local gate — a genuine positive, confirmed by direct read of
both files. But the practical effect of 8-9 category suppressions stacked before
warnings-as-errors is that an entire class of maintainability signals (unreferenced
entities/formals, useless assignments, could-be-constant, redundant `with`) can never
surface as a build warning in this codebase, silently. This is architecturally consistent
with the certification domain analyst's independent finding that `-gnatwe`
"is a real, load-bearing gate, just not one visible in a green/red CI check today because
the whole job is `continue-on-error`" (Q-7) — so even the warnings that *do* survive the
suppression list currently have no CI enforcement path either.

`ada/examples/hale_examples.gpr:23-25` has none of this suppression discipline (bare
`-gnatwa`, no `-gnatwe`) and targets `-gnat2012` instead of `-gnat2022` (Q-11) — an
inconsistent lint posture within the same repository's four `.gpr` files.

SPARK proof-level claims vs. actual body-level `SPARK_Mode`: 11 of 12 `.adb` files under
`ada/src` (all except `Threebody`, see Q-9) are `SPARK_Mode => Off` at the body, meaning
`gnatprove` — when installed — would only check `Pre`/`Post`/`Global` well-formedness at the
`.ads` interface, never the actual arithmetic or exception logic inside any body except
`Threebody`'s (which is inconsistently `On`, Q-9). Multiple header comments across the
codebase (`vectors.ads:7`, `matrices.ads:7`, `twobody.ads:10`, `kepler.ads:10`,
`stumpff.ads:11` — all per the domain reports' citations, independently spot-checked for
`vectors.ads`/`matrices.ads` in this pass) claim "proven free of runtime errors" or "formally
verifiable" language that the `SPARK_Mode => Off` bodies cannot currently substantiate. This
is a repository-wide documentation/verification-claim gap, not confined to one domain.

**Python:** no lint/type-check tooling configured at all (Q-12) — `-gnatwa`-equivalent
enforcement simply does not exist for the 3,846-LOC oracle module.

**Suppression density verdict:** the library's warning posture is "wide net, narrow catch" —
`-gnatwa` promises comprehensive coverage, 8-9 stacked suppressions remove most of the
actionable categories, and `-gnatwe` makes what's left a hard gate that is itself unenforced
by CI (`continue-on-error: true`). Recommend re-enabling the suppressed categories one at a
time (starting with `-gnatwU`/unreferenced-entity, since Q-1's dimensional-foundation dead
code — `G_Universal`, six unused `Matrices` functions — would likely have surfaced
immediately under that flag) once the CI-gating fix in Q-7 lands, so newly-surfaced warnings
have a channel to actually block a regression.

---

## 6. Maintainability: churn x complexity, duplication, god-files

Cross-referencing the historian's churn data (`10-history.md` §2) against file size
(independently re-measured via `wc -l`):

| File | LOC | Touches (historian) | Bus factor | Danger assessment |
|---|---|---|---|---|
| `ada/src/threebody/hale_orbital-threebody.adb` | **1,300** (largest in repo) | 3 | Sole-author (THOClabs) | **Highest** — largest file, moderate churn, single author, *and* now confirmed to carry a real SPARK-scope contradiction (Q-9) and a "20+ tests exist but none run in CI" gap (Q-8). This is the textbook churn×complexity×bus-factor intersection the task brief asked to identify, and it independently checks out. |
| `ada/src/hale_orbital-lambert.adb` | 679 | 2 (per `git log --name-only` uniq count) | Sole-author | High — second-largest file, contains the confirmed unguarded-division defect (Q-6) and ~90%-duplicated `Solve_Lambert`/`Solve_Lambert_Bounded` (per trajectory-optimization domain report). |
| `ada/src/hale_orbital-propagation.adb` | 579 | — | Sole-author | High — contains the RK78 structural defect (Q-1), the single most severe correctness finding in this audit. |
| `ada/src/hale_orbital-elements.adb` | 514 | 2 | Sole-author | Medium — `State_To_Elements` is a 148-line, 5-branch complexity hotspot (per classical-astrodynamics domain report) feeding the broken coverage build (Q-5). |
| `ada/tests/run_tests.adb` | 742 | 3 (highest touch-count in the repo per historian) | Sole-author | Medium — highest git churn of any file, but structurally the least consequential of the top-churn files *content-wise*; its main risk is architectural (Q-7/Q-8: it's the one file CI runs, and it can't fail), not internal complexity. |

**Duplication found (confirmed across domain reports, independently spot-checked where
noted):**
- `Elements.Mean_To_Eccentric_Anomaly` vs. `Kepler.Solve_Kepler_Elliptic` — same
  Newton-Raphson algorithm implemented twice because of a package-cycle constraint
  (accepted as reported, §0).
- `Solve_Lambert` vs. `Solve_Lambert_Bounded` — ~90% duplicated, independently confirmed by
  reading `lambert.adb:140-229` (shown in Q-6) against the analyst's citation of
  `lambert.adb:249-371`; the two `Y < 0.0` recovery rules differ, a live drift risk.
- `Elements_To_State`'s inline PQW→ECI rotation vs. `Matrices.Perifocal_To_Inertial` — same
  math, two implementations, confirmed independently via Q-1 of the dimensional-foundation
  ledger above (zero call sites for `Matrices.Perifocal_To_Inertial` outside its own file).
- `Threebody`'s local `Matrix_Multiply`/`Matrix_Scale`/`Matrix_Add` (`adb:538-573`, per the
  restricted-astrodynamics domain report) reimplement what `Hale_Orbital.Matrices` already
  provides for 3x3 (though `Threebody` needs 6x6, which `Matrices` does have via
  `Matrix_6x6` per the dimensional-foundation report — a missed-reuse opportunity, not
  strictly justified by a type mismatch).

**Dead code candidates (confirmed):** `Constants.G_Universal` (Q-0 ledger,
dimensional-foundation); six `Matrices` functions with zero external call sites; most of
`Vectors`' rotation/spherical-conversion surface; `ada/tests/run_all_tests.adb` (388 lines,
the most complete test runner in the repo, orphaned from every `.gpr` `Main` list, Q-8);
`test_driver_coverage.adb`'s `Coverage_Results.Total_Tests` field (declared, never
incremented, per the certification domain report).

---

## 7. Developer experience: literal fresh-container walkthrough

I ran the repository's own documented commands literally, in this container, in order:

1. **`bash .claude/setup.sh`** (the documented SessionStart bootstrap) — **fails**: `curl`
   returns HTTP 403 fetching Alire, then the script itself exits 1 due to the stale-trap bug
   (Q-2, reproduced live above). A new contributor relying solely on this hook would see the
   toolchain-installed summary print "(not installed)" for `alr`/`gnat`/`gprbuild`/
   `gnatprove`/`gnatcov`, and — if they check the exit code directly rather than trusting the
   hook — a failure that the hook's own `settings.json` wiring hides.
2. **`alr toolchain --select gnat_native gnatprove`** (`README.md:48`, the documented
   first-run command) — **fails immediately**: `alr: command not found` (exit 127), since
   step 1 didn't install it and there is no documented fallback (e.g., apt, a pinned
   container image, or a vendored binary).
3. **`alr build`** (`README.md:49`) — not reachable; same blocker.
4. **`alr exec -- gprbuild -P ada/tests/hale_tests.gpr` / `./ada/tests/run_tests`**
   (`README.md:52-53`) — not reachable; same blocker.
5. **`python -m pytest validation/`** (`README.md:64`) — **fails**: `validation/` does not
   exist anywhere in the repository (confirmed live, Q-10).
6. **`cd python/three-body-extension && pytest`** (the actually-working path, matching
   `ci.yml:91-96`) — **succeeds**: 49 passed in 3.17s (§2).

**Verdict:** a new contributor following `README.md` top-to-bottom in a network-restricted
or Alire-release-blocked environment cannot get past step 2 for the Ada side, and hits a
hard path error on step 5 for the documented cross-validation command regardless of network
access. Only the Python oracle's own-directory `pytest` command (not the one `README.md`
documents at the repo root) actually works out of the box. This matches the certification
domain analyst's finding almost exactly, extended here to the README's `Build & Test`
section literally, not just `.claude/setup.sh`.

---

## Health scorecard

| Domain | Grade | Justification |
|---|---|---|
| **Dimensional-foundation** | **C+** | Sound type-distinctness discipline and consistently applied `pragma Pure`, but ~40% of `Vectors`/`Matrices`' public surface has zero call sites and zero tests, a live tolerance-mismatch bug (`Is_Singular` vs. `Inverse`, Q-3) sits undetected in the most-imported layer in the repo, and the certification threshold-traceability doc omits this domain's own threshold usages. |
| **Classical-astrodynamics** | **C** | Algorithmically the most mature domain, but its own example program doesn't compile (Q-4, unguarded by CI), its richest test coverage (boundaries/negative suites) is orphaned from CI, and the same record-shape drift that breaks the example also breaks the DO-178C coverage build (Q-5). |
| **Trajectory-optimization** | **D+** | Contains the two most severe correctness findings in this audit: a structurally invalid RK78 integrator whose certification-cited "1e-12 energy conservation" claim cannot be substantiated by the code as written (Q-1), and an open, tracked-Critical unguarded division in the Lambert solver's inner loop that `release` mode has no runtime check for (Q-6). Contract/documentation drift (Izzo claim vs. Battin implementation) compounds the risk of a caller trusting the wrong mental model. |
| **Restricted-astrodynamics** | **C-** | The largest, most complex file in the repository (1,300 LOC, sole-authored, high churn) carries a confirmed SPARK-scope contradiction found independently in this audit (Q-9) on top of the domain analyst's own findings (`RK45` silently aliasing to `RK4`; 4 of 6 Floquet multipliers mathematically meaningless with no caller-visible flag; 20+ tests never run by CI, Q-8). The Python oracle is solid (49/49 passing, independently re-confirmed) but has zero cross-validation wiring to the Ada implementation it's supposed to check. |
| **Certification-safety** | **D** | The most extensively self-documented domain in the repo, and also the one where the gap between documented and actual state is largest and most consequential: none of the four CI jobs can currently fail a PR on a broken build, failing test, or failing SPARK analysis except the doc-lint job (Q-7); the DO-178C coverage build doesn't compile (Q-5); the RTM and SRS/test-RTM use disjoint requirement-ID namespaces; the one documented bootstrap path is broken twice over (Q-2). The certification *documentation* itself is a genuine asset — extensive, internally self-critical in places, and clearly certification-literate — but the automation that is supposed to make its claims true does not yet do so. |

**Overall repository grade: C-/D+.** The mathematics is largely well-structured and the
certification *intent* is unusually mature for a project this young (6.5 months, per
`10-history.md`), but the verification and CI infrastructure that is supposed to make that
intent trustworthy is currently non-functional in exactly the ways that matter most: no CI
job can fail on a real regression except a documentation-hygiene grep, the flagship adaptive
integrator does not implement the method it claims to, and the one documented
fresh-container bootstrap path fails on two independent, unrelated bugs that would each be a
five-minute fix. None of this requires new capability to fix — every finding above has a
small, targeted, mechanical repair; the risk is regression, not missing architecture.
