# Architecture Review (Phase 5 Synthesis)

**Author:** Chief Architect (L5-L6)
**Date:** 2026-07-12
**Inputs:** all of `docs/review/` (00, 10, five 20-domain reports, 30, 31), spot-checked against source at commit 0345758.
**Companion document:** `docs/review/50-risk-register.md`

---

## 1. System Overview

HALE Orbital Mechanics is a pure-computation astrodynamics library: Ada 2012/SPARK (~7,900
LOC in 13 packages under `ada/src/`) implementing textbook orbital mechanics from Hale and
Vallado — two-body dynamics, Keplerian element conversions, Kepler-equation solvers, Lambert
transfers, patched-conic interplanetary design, numerical propagation, and the Circular
Restricted Three-Body Problem — plus an independent Python CR3BP "oracle" (~3,850 LOC,
NumPy/SciPy) intended to cross-validate the Ada CR3BP math. Wrapped around both is a
DO-178C-flavored assurance layer: certification documents (SRS/SDS/SCS/RTM/test-RTM, real but
small — 276-452 lines each), SPARK contracts, an MC/DC coverage pipeline, and a 4-job GitHub
Actions workflow.

The shape is a textbook layered library and unusually clean at the code level: a `pragma
Pure` dimensional foundation (Types/Constants/Vectors/Matrices) at the bottom, classical
astrodynamics above it, trajectory design above that, and a self-contained CR3BP package to
the side. There is **no I/O of any kind in library code** — no filesystem, network,
environment, or process access in any `ada/src/` unit or Python oracle module (verified
independently by the security audit, 30-security.md I2). Error handling is a small shared
exception taxonomy (`Convergence_Error`, `Invalid_Orbit`, `Physical_Error`,
`Singularity_Error`) raised from bounded-iteration solvers. All state is caller-owned records
of IEEE-double-derived types.

The defining architectural fact, however, is not the code — it is the **gap between claimed
and actual assurance**. The project's product is trust (a "safety-critical" library), and
every mechanism that is supposed to manufacture that trust is currently inoperative or
misrepresented: CI cannot fail on a broken build or test (only the doc-lint job gates,
`ci.yml:21,56,96`); the sole CI-executed test binary always exits 0
(`ada/tests/run_tests.adb`, no `Set_Exit_Status`); 234 tests marked "Complete" in the
test-RTM are never built by CI; the DO-178C coverage build does not compile (field-name
drift in `hale_tests-vallado.adb`/`-exceptions.adb`); gnatprove has never run, yet source
headers claim "proven free of runtime errors" over `SPARK_Mode => Off` bodies; the flagship
"RK78" integrator is not a valid Runge-Kutta method; and the README describes directories
(`data/`, `validation/`), algorithms (Izzo Lambert), proof levels (Gold/Platinum), and a
Python-to-CSV-to-Ada validation pipeline that do not exist. The mathematics is largely
sound and well-organized; the evidence machinery around it is currently a facade.

Sociotechnically this is a 6.5-month-old, 6-commit, effectively single-author repository
(THOClabs authored all library, test, oracle, and certification content; `main` is 52 days
stale). Everything below assumes that context: the architecture is young, deliberate, and
recoverable — every defect found has a small mechanical fix — but nothing about it is yet
independently verified, and no second person could currently maintain it.

---

## 2. Module Map

Dependency direction is strictly downward (verified: no cycles; the one near-cycle,
Elements↔Kepler, was broken by duplicating code rather than adding an edge — see §5).

```
                    APPLICATIONS (not built by CI; orbit_propagation.adb does not compile)
  ada/examples/: hohmann_transfer, lambert_intercept, earth_mars_mission,
                 orbit_propagation, lagrange_points, trajectory_display
        │
        ▼
  ┌────────────────────────────────────────────────────────────────────────┐
  │ L2: TRAJECTORY DESIGN            │  L2': RESTRICTED DYNAMICS            │
  │  Lambert ──► Stumpff, Elements   │   Threebody (CR3BP, 1300 LOC)        │
  │  Interplanetary ──► Twobody      │   · depends ONLY on Types/Constants  │
  │  Propagation (RK4, "RK78")       │   · reimplements 6x6 matrix ops      │
  │  · Propagation does NOT use      │   · only body with SPARK_Mode => On  │
  │    Kepler (2 propagation paths)  │                                      │
  └──────────────┬───────────────────┴──────────────┬───────────────────────┘
                 ▼                                  │
  ┌──────────────────────────────────┐              │
  │ L1: CLASSICAL ASTRODYNAMICS      │              │
  │  Twobody, Elements, Kepler,      │              │
  │  Stumpff, Maneuvers              │              │
  │  · Elements does NOT use         │              │
  │    Matrices (inlines rotations)  │              │
  └──────────────┬───────────────────┘              │
                 ▼                                  ▼
  ┌────────────────────────────────────────────────────────────────────────┐
  │ L0: DIMENSIONAL FOUNDATION (pragma Pure, no state, no I/O)             │
  │  Types (Real=Long_Float; dimensional scalar types; exceptions;        │
  │         + misplaced Lambert-domain constants/records, see §5)         │
  │  Constants · Vectors · Matrices (~40% of surface has zero callers)    │
  └────────────────────────────────────────────────────────────────────────┘

  PARALLEL ISLAND (no code path connects to Ada — the intended bridge is unbuilt):
  python/three-body-extension/src/threebody/: cr3bp, lagrange, integrators,
     periodic, stability, systems   [49/49 pytest pass; periodic/stability untested]

  VERIFICATION WRAPPER (currently non-gating):
  ada/tests/  run_tests.adb ──── built+run by CI, exits 0 unconditionally
              run_all_tests.adb ─ wires all 10 suites + exit status; Main of NOTHING
              test_driver_coverage.adb ─ Main of coverage.gpr; does not compile
              hale_tests-{vallado,edge_cases,negative,exceptions,boundaries,
              determinism,integration,lambert_multirev,periodic_orbits,parallel}
                                 ─ orphaned from every CI-reachable build
  .github/workflows/ci.yml  4 jobs; only doc-lint can fail
  docs/certification/       SRS/SDS/SCS/rtm/test-rtm (two disjoint HLR-* ID schemes)
```

Import fan-in confirms the layering: 22 of 24 non-foundation files under `ada/src` import
Types/Constants/Vectors/Matrices; the foundation imports nothing above itself
(20-domain-dimensional-foundation.md §4, spot-confirmed).

---

## 3. The Most Important End-to-End Data Flows

### Flow 1 — Classical orbit propagation (analytic path)

`Orbital_Elements` → `Elements.Elements_To_State` (perifocal build + inlined PQW→ECI
rotation, `elements.adb:218-310`) → `Kepler.Propagate` (`kepler.adb:346-424`): universal
anomaly Newton iteration via `Stumpff.C/S`, bounded at 50 iterations with
`Convergence_Error` on exhaustion → f/g functions → new `State_Vector` →
`Elements.State_To_Elements` (`elements.adb:59-212`, the domain's complexity hotspot: 5
nested singularity branches) for readout. Pure in-memory records end to end; exceptions are
the only failure channel. This is the best-conditioned flow in the library — bounded loops,
live contracts in every build mode.

### Flow 2 — Mission design (Lambert + numerical propagation)

`(R1, R2, ToF, Mu)` → `Lambert.Solve_Lambert` (`lambert.adb:67-246`): bisection on the
universal variable Z over `±4π²`, evaluating Stumpff functions per iteration, max 100
iterations → `(V1, V2, Converged)` → caller feeds the state to
`Propagation.Propagate_RK4` or `Propagate_RK78` → trajectory → `Energy_Error` sanity check
(`earth_mars_mission.adb`). Two verified fragilities live on this path: (a) unguarded
divisions by `C_Z`, `1-Z*C_Z`, and `G_Func` can yield NaN/Inf velocities **with
`Converged = True`, in every build mode** (no `-gnateF`; float ops never raise on IEEE
targets — 30-security.md H2, code-confirmed at `lambert.adb:156,161,175,187,224-228,236-237`);
(b) `RK78_Step` builds stages 2-7 from `K(1)` only with no Butcher A-matrix and combines
them with DOPRI5(4) weights under a 1/8-power step controller
(code-confirmed, `propagation.adb:252-302,319,333`) — it is not the 7(8)-order method its
name, spec, and `SDS.md:210-213` ("1e-12 energy conservation") claim.

### Flow 3 — The assurance pipeline (requirement → evidence), broken at every link

SRS requirement (`HLR-1A-*`) → SDS design section (**no HLR IDs at all** — prose only) →
Ada contract → test in `Hale_Tests.*` (**not built by CI**; the only CI-run binary,
`run_tests.adb`, is a separate 64-assertion harness that **cannot exit nonzero**) →
RTM trace entry (**different ID namespace, `HLR-TB-*` — zero mechanical overlap with the
SRS**) → coverage evidence (`coverage.gpr` **does not compile**: its test dependencies use
field names `Arg_Periapsis`/`Epoch` that `Orbital_Elements` does not have,
`hale_tests-vallado.adb:71,110`, `hale_tests-exceptions.adb:185-214` vs
`hale_orbital-types.ads:114`) → CI gate (**only doc-lint can fail**, `ci.yml`). This flow
is the product for a certification-track library, and it currently transports no
information: green CI is indistinguishable from a broken build. (The intended fourth flow —
Python oracle → CSV reference data → Ada test comparison, described in README.md — does not
exist: no CSV reference data, no bridge code, confirmed repo-wide.)

---

## 4. Design Decisions Inferred from Code, with Fitness Judgments

| # | Decision | Evidence | Still serves the project? |
|---|---|---|---|
| D1 | **Dimensional safety via derived scalar types** (`Distance_Km is new Real` etc.), explicit `Real(...)` casts at boundaries | `hale_orbital-types.ads:35-56`; pervasive cast convention in all bodies | **Partially.** Catches swapped-quantity bugs at compile time — genuinely useful. But it is not dimensional analysis (`Distance*Distance` is still `Distance_Km`), and vectors carry no dimensions at all (`Position_Vector`/`Velocity_Vector` are interchangeable subtypes, `types.ads:66-69`). Keep, but stop describing it as "compile-time unit safety." |
| D2 | **SPARK contracts on specs; `SPARK_Mode => Off` on bodies** because every body instantiates `Generic_Elementary_Functions` (exemption ISS-040) | 11 of 12 `ada/src` bodies `Off` (grep-confirmed); `spark-scope.md:79-98` | **The decision is defensible; the claims around it are not.** Contract-rich specs are real value. But headers claim "proven free of runtime errors" (`vectors.ads:7`, `kepler.ads:10`, `stumpff.ads:11`), `spark-scope.md:54-55` claims Vectors=Gold/Matrices=Silver "proven" (bodies are Off), `spark-scope.md:73` claims Threebody is Off (it is the one body that is On, `threebody.adb:8`), and gnatprove has never run anywhere. The claim set must be corrected before it does harm. |
| D3 | **Small shared exception taxonomy** raised from deep inside solvers; bounded iteration everywhere (`Max_Iter` + `Loop_Invariant`) | `types.ads:191-200`; ~50 raise sites; `kepler.adb:45,95,177` | **Mostly.** Disciplined and consistent as a taxonomy; bounded loops are a genuine DO-178C asset (no hang surface, confirmed by security audit C4). But it contradicts README's documented "status returns inside SPARK, exceptions only at the API edge," no spec documents what it raises, and precondition density is inconsistent (guarded and unguarded siblings in the same package, `twobody.ads:127-148`, `lambert.ads:118-137`). |
| D4 | **Contracts live in every build mode** (`-gnata` in `Common_Switches`); release adds `-gnatp` (language checks off) and no mode traps float overflow (no `-gnateF`) | `hale_orbital.gpr:28,40-44`; confirmed by direct read | **Half-serves.** Keeping Pre/Post live in release is the right call for this library and refutes two domain reports' "compiled out in release" claim (see §6). But the float story undoes it: NaN/Inf propagate silently in all modes, so contracts guard entries, not arithmetic. Needs explicit denominators guards or `'Valid` gates at solver exits. |
| D5 | **Dual-implementation validation** (Ada primary + independent Python oracle) | Directory structure; equivalent physics verified by inspection (20-domain-restricted-astrodynamics.md §3) | **Sound strategy, unrealized.** No code connects them; no CSV reference data exists; oracle's `periodic.py`/`stability.py` have zero tests; Ada L3 Lyapunov path has no oracle counterpart even in principle. Today it is two sole-authored implementations that have never been programmatically compared — validation theater until the bridge is built. |
| D6 | **Documentation-first, aspiration-as-present-tense culture** | README lists nonexistent `data/`, `validation/`, "Lambert (Izzo)", Gold/Platinum proof levels, a CSV cross-validation pipeline; `docs/ARCHITECTURE.md` honestly marks ~20 packages "(planned)" and says "Battin today; Izzo planned" | **No longer serves — actively harmful.** The honest documents (ARCHITECTURE.md, spark-scope.md's exemption rationale) coexist with marketing documents (README) that this review *proved* corrupt downstream analysis: Phase-1 inventory ingested README's false claims verbatim (Izzo, Gold, CSV pipeline) and re-emitted them as findings. One truth-pass over README plus a "planned vs. present" convention fixes this cheaply. |
| D7 | **Monolithic Threebody package** with documented split-trigger (DEC-005) | `docs/rationale/DEC-005-threebody-package-structure.md` says ~686 lines, split when ISS-034 lands; file is now 1,300 lines and ISS-034 is marked complete | **Expired by its own terms.** The decision record's stated trigger condition has occurred; the package also carries the RK45-aliases-RK4 stub, the 2-of-6 Floquet multipliers, and the contradicted SPARK_Mode — the repo's highest concentration of drift. Revisit DEC-005 as it instructs. |
| D8 | **CI as non-gating scaffolding** pending toolchain fixes ("informational first, tighten later") | `continue-on-error: true` (`ci.yml:21,56`), inline `\|\| echo` pytest masking (`ci.yml:96`), comments citing Alire-on-Actions issues | **Has decayed into false assurance.** A reasonable bootstrap posture 2 months ago is now the mechanism by which `DO-178C-compliance-checklist.md:74` "CI validates — COMPLETE" is false. The tightening never happened; meanwhile the one binary CI does run can't fail anyway. This is the cheapest, highest-leverage fix in the repository. |
| D9 | **Duplication instead of dependency** to avoid coupling | `Elements.Mean_To_Eccentric_Anomaly` re-implements `Kepler.Solve_Kepler_Elliptic` (cycle avoidance, `elements.adb:377-416`); `Elements_To_State` inlines rotations instead of using `Matrices.Perifocal_To_Inertial`; `Threebody` reimplements 6x6 ops; `Solve_Lambert`/`Solve_Lambert_Bounded` ~90% duplicated with divergent recovery rules | **Costs now exceed benefits.** Four independent copies of load-bearing math with no shared regression test means fixes will not propagate. Either extract shared kernels (a `Numerics` child below `Elements`/`Kepler` would break the cycle honestly) or add cross-validation tests binding the copies together. |

---

## 5. Coupling and Boundary Violations Worth Naming

1. **Lambert domain types live in the foundation.** `Z_Bound_*`, `Invalid_Function_Value`,
   `Degenerate_Transfer_Threshold`, `Transfer_Result`, `Lambert_Solution` are defined in
   `hale_orbital-types.ads:138-184`, not in `Lambert`. The foundation layer knows about a
   specific solver two layers above it — the only upward conceptual leak in the codebase.
2. **The Elements↔Kepler near-cycle, resolved by cloning.** `Kepler` withs `Elements`, so
   `Elements` cannot call the Kepler solver it documents itself as wrapping
   (`elements.ads:87`) and re-implements it. This is a boundary drawn in the wrong place;
   the shared Newton kernel belongs below both.
3. **Matrices is a boundary nobody crosses.** Six exported functions including
   `Perifocal_To_Inertial`/`Inertial_To_Perifocal` have zero callers; `Elements` — the
   natural consumer — inlines the identical math, and `Threebody` reimplements 6x6
   arithmetic locally. Same rotation physics, three implementations, no shared test.
4. **Threebody bypasses the classical layer entirely** (only Types/Constants). Dynamically
   defensible (CR3BP is not conic mechanics), but combined with #3, its size, its sole
   `SPARK_Mode => On` body (contradicting `spark-scope.md:73`), and its internal
   `Mass_Ratio` vs `Mu1/Mu2` 4.5 ppm inconsistency (`Sun_Earth_System`), it is the least
   architecturally supervised region of the codebase.
5. **Two disconnected propagation paths.** Analytic (`Kepler.Propagate`) and numerical
   (`Propagation.*`) never cross-validate against each other for the plain two-body case —
   a free consistency oracle the test suite does not use.
6. **The test boundary is incoherent.** Two assertion mechanisms with opposite failure
   semantics (raising `Runner.Assert*` vs counter-only `Run_Test`); the complete runner
   (`run_all_tests.adb`) is Main of nothing; the CI runner cannot fail; the coverage runner
   cannot compile. The verification layer has no verified interface to the thing it verifies.
7. **The Python oracle is an island.** Zero coupling where coupling was the entire design
   intent (D5). The README describes the bridge as existing; it does not.

---

## 6. Inter-Report Conflict Resolutions (fact-checked in code)

| # | Conflict | Resolution — who was right |
|---|---|---|
| a | 00-inventory: classical-astrodynamics "SPARK Proof Level: Gold" vs domain report/spark-scope.md "Bronze, bodies Off" | **Inventory wrong.** All five classical bodies are `SPARK_Mode => Off` (grep-confirmed); `spark-scope.md:59-64` says Bronze. Inventory copied README's marketing ("gold on kernel routines"). Note the deeper finding: `spark-scope.md` itself is wrong in both directions for Vectors/Matrices (claims proven; bodies Off) and Threebody (claims Off; body is On) — security audit M3 confirmed at `vectors.adb:8`, `matrices.adb:8`, `threebody.adb:8`. |
| b | 00-inventory: Lambert = "Izzo 2014" vs trajectory report "Battin/universal-variable bisection" | **Inventory wrong** (again sourced from README.md:7). `lambert.adb:4` states "universal variable formulation with Battin's method"; implementation is bisection on Z over Stumpff functions. `docs/ARCHITECTURE.md` has it right: "Battin today; Izzo planned in Phase 6." |
| c | 00-inventory §7.7 cert-doc "line counts" (9,871-21,822) vs certification report "those are bytes" | **Inventory wrong.** Re-measured: the five figures exactly match `ls -la` byte sizes; `wc -l` gives SRS=401, SDS=401, SCS=452, rtm=425, test-rtm=276. The cert docs are ~25-50x smaller than the inventory implies. |
| d | Domain reports: "contracts compiled out in release" and "`-gnato` would catch the Lambert division" vs security audit refutations | **Security audit right on both.** (1) `-gnata` is in `Common_Switches` (`hale_orbital.gpr:28`) applied to all four modes; release's `-gnatp` suppresses language-defined checks, not assertion-policy contracts — dimensional-foundation and restricted-astrodynamics reports were wrong; trajectory report was right. (2) `-gnato` governs integer/arithmetic overflow; IEEE float division by zero never raises on GNAT targets (`Machine_Overflows = False`) and no mode sets `-gnateF` (confirmed absent from the .gpr) — the trajectory report's mitigation claim was wrong, and the exposure is worse than it reported: all build modes. |
| e | 00-inventory: "Cross-validation: Python oracle → CSV reference data → Ada tests" vs restricted report "no CSV reference data exists" | **Inventory wrong** (source: README's own false claim). Repo-wide search finds exactly three CSVs — `remaining_issues.csv`, `docs/certification/compliance-issues.csv`, `docs/certification/decision-point-inventory.csv` — all human tracking sheets; no code anywhere parses CSV (security audit I2 concurs). |

Pattern worth recording: **every inventory error traces to trusting README.md.** The
quality audit's confirmation ledger (31-quality.md §0) reported zero refuted analyst flags,
and my spot-checks agree — the L3/L4 layers were accurate; the Phase-1 recon layer inherited
the repository's own aspirational self-description. Future reviews should treat README.md
as a statement of intent, and `docs/ARCHITECTURE.md` + the code as ground truth.
