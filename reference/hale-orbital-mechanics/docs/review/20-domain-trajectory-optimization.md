# Domain Report: Trajectory Design & Interplanetary Mission (`trajectory-optimization`)

**Reviewer:** Domain Analyst (L3), Phase 3 Deep Dive
**Scope:** `ada/src/hale_orbital-lambert.ads/.adb`, `ada/src/hale_orbital-interplanetary.ads/.adb`,
`ada/src/hale_orbital-propagation.ads/.adb`, plus usage evidence from
`ada/examples/lambert_intercept.adb`, `ada/examples/earth_mars_mission.adb`,
`ada/examples/performance_benchmarks.adb`.
**Method:** Static reading only. No GNAT/gprbuild/gnatprove toolchain is installed in this
container, so nothing below reflects a compiled, executed, or proved result — all claims are
derived from source text, doc cross-references, and the repository's own tracking artifacts
(`remaining_issues.csv`, `docs/certification/compliance-issues.csv`).

---

## 1. Responsibility

This domain turns two position/time boundary conditions or an initial state into a flyable
trajectory: `Lambert` solves the two-point boundary-value problem for a conic connecting `R1`
and `R2` in a given time of flight, `Propagation` numerically integrates a state forward under a
pluggable force model, and `Interplanetary` chains these primitives across sphere-of-influence
boundaries using patched-conic approximations (departure hyperbola → heliocentric transfer →
arrival hyperbola, plus gravity-assist flybys). Together they are the "trajectory design" layer
that sits above the two-body/Kepler primitives (Domain 2) and below mission-level examples.

## 2. Key modules

| Path | Role |
|---|---|
| `ada/src/hale_orbital-lambert.ads:17-172` | `Hale_Orbital.Lambert` spec — `Lambert_Result` record, `Solve_Lambert`, `Solve_Lambert_Multi`, transfer-angle/degeneracy/min-TOF utilities, all with SPARK `Pre`/`Post`/`Global => null` contracts. |
| `ada/src/hale_orbital-lambert.adb:67-246` | `Solve_Lambert` — single-revolution universal-variable Lambert solver via bisection on Stumpff parameter `Z`. |
| `ada/src/hale_orbital-lambert.adb:249-371` | `Solve_Lambert_Bounded` — near-duplicate of `Solve_Lambert` restricted to a caller-supplied `[Z_Low, Z_High]` bracket; used for multi-revolution branches. |
| `ada/src/hale_orbital-lambert.adb:373-473` | `Solve_Lambert_Multi` — enumerates zero-rev plus short/long-period N-rev solutions into a dynamically sized result array. |
| `ada/src/hale_orbital-lambert.adb:622-644` | `Is_Degenerate_Transfer` — flags near-collinear `R1`/`R2` (≈0°/180°) via cross-product magnitude threshold. |
| `ada/src/hale_orbital-interplanetary.ads:19-277` | `Hale_Orbital.Interplanetary` spec — `Planet_Type`/`Planet_Data` (8 planets, hard-coded constants), SOI, hyperbolic excess velocity/C3, patched-conic transfer, gravity assist, synodic period. |
| `ada/src/hale_orbital-interplanetary.adb:138-216` | `Compute_Patched_Conic` — builds a Hohmann-like heliocentric transfer between two planets' semi-major-axis circles, then departure/arrival hyperbolas at given parking/capture altitudes. |
| `ada/src/hale_orbital-interplanetary.adb:242-264` | `Compute_Flyby` — turn angle + Δv gain from a hyperbolic planetary flyby. |
| `ada/src/hale_orbital-propagation.ads:18-230` | `Hale_Orbital.Propagation` spec — `Force_Model` interface, `Two_Body_Model`/`J2_Model`, `Propagator_Config`, RK4/RK78 propagator signatures, `Propagate_Parallel*` (Ada 2022), `Conserved_Energy`/`Energy_Error`. |
| `ada/src/hale_orbital-propagation.adb:101-142` | `RK4_Step` — textbook fixed-step classical RK4. |
| `ada/src/hale_orbital-propagation.adb:229-346` | `RK78_Step` — the adaptive integrator; see §6 for a structural defect found here. |
| `ada/src/hale_orbital-propagation.adb:497-528` | `Propagate_Parallel` / `Propagate_Parallel_RK4` — currently **sequential** `for` loops (see §6), despite spec-level "Ada 2022 parallel" framing. |

## 3. Data flow (representative trace: `earth_mars_mission.adb`)

1. **Entry / input construction.** The example builds two `Position_Vector`/`Velocity_Vector`
   pairs analytically (circular, coplanar orbits) rather than reading any file or network input:
   `ada/examples/earth_mars_mission.adb:125-134`. No external data enters this domain at
   runtime; all inputs are either literal constants or values computed by upstream Domain-2
   packages (`Twobody`, `Elements`).
2. **Lambert solve.** `Solve_Lambert (Earth_Position, Mars_Position, Transfer_Time, Mu_Sun, …)`
   (`earth_mars_mission.adb:181-186`) → `hale_orbital-lambert.adb:67-246`. Internally: transfer
   angle via `Dot`/`Cross` (`lambert.adb:105-133`), chord/semi-perimeter geometry
   (`lambert.adb:141-147`), bisection on `Z` bounded by `Z_Bound_Hyperbolic`/`Z_Bound_Elliptic`
   (`±4π²`, `hale_orbital-types.ads:145-146`), each iteration evaluating `Stumpff.C`/`Stumpff.S`
   (cross-domain call into `Hale_Orbital.Stumpff`, Domain 2) to get a candidate time of flight,
   compared against `Tolerance` (default `1.0e-12`, `types.ads:25`), capped at `Max_Iter = 100`
   (`lambert.adb:101`). On convergence, `f`/`g` functions produce `V1`, `V2`
   (`lambert.adb:230-237`), and `Result.E` is obtained via a cross-domain call to
   `Hale_Orbital.Elements.Eccentricity` (`lambert.adb:241`).
3. **Δv budget.** The example recomputes Δv directly (`earth_mars_mission.adb:247-249`) rather
   than calling `Lambert.Departure_Delta_V`/`Arrival_Delta_V` (`lambert.ads:125-137`) — both
   paths exist and are logically equivalent, but this shows the utility functions are optional
   sugar, not mandatory entry points.
4. **Propagation.** `Generate_Timed_Trajectory` (`propagation.ads:158-163`) →
   `Generate_Trajectory` (`propagation.adb:418-446`), which repeatedly calls
   `Propagate_RK4` (`propagation.adb:148-176`) with 10 substeps per requested output point
   (`propagation.adb:428-429`) using a `Two_Body_Model` force model
   (`Acceleration` at `propagation.adb:20-36`, heliocentric `Mu_Sun`).
5. **Exit / validation.** `Energy_Error` (`propagation.adb:480-491`) compares specific orbital
   energy at the trajectory's start and end and is printed with a `1.0e-6` pass threshold
   (`earth_mars_mission.adb:325-337`) — looser than the `1.0e-10`/`1.0e-12` figures asserted
   elsewhere in the certification docs (see §6). Output is textual (`Ada.Text_IO`) only; nothing
   is written to disk or a network socket by this domain.

For an interplanetary (patched-conic) trace: `Interplanetary.Hohmann_Interplanetary` →
`Compute_Patched_Conic` (`interplanetary.adb:138-236`) computes a heliocentric transfer directly
from the two planets' `Semi_Major_Axis` fields (no ephemeris, no actual position vectors, no use
of `Lambert` at all) and calls into Domain 2's `Twobody.Circular_Velocity`
(`interplanetary.adb:171-172`, `with Hale_Orbital.Twobody`). This is a materially different,
independent code path from the Lambert-based trajectory shown in `earth_mars_mission.adb` — the
two "interplanetary mission design" approaches in the repository do not share an implementation.

## 4. External dependencies

- **`Ada.Numerics.Generic_Elementary_Functions`** (stdlib) — instantiated for `Real` in both
  `lambert.adb:19` and `interplanetary.adb:14` and (transitively) in `propagation.adb:13` for
  `Sqrt`. This forces `SPARK_Mode => Off` on all three bodies (`lambert.adb:16`,
  `interplanetary.adb:11`, and implicitly `propagation.adb` per the comment at
  `propagation.adb:9-11`), even though the corresponding specs (`lambert.ads:18`,
  `interplanetary.ads:20`) are `SPARK_Mode => On`. Net effect: contracts are declared and
  (per `hale_orbital.gpr:28`, `-gnata` is common to all build modes) enforced at runtime as
  assertions, but the bodies are outside `gnatprove`'s reach — matches the tracked gap
  `ISS-042` (`docs/certification/compliance-issues.csv:43`: "SPARK spec/body mismatch - solver
  verification blocked").
- **Domain 2 (`classical-astrodynamics`)**: `Hale_Orbital.Twobody` (`Circular_Velocity`, used by
  `interplanetary.adb:171-172`), `Hale_Orbital.Elements` (`Eccentricity`, `State_To_Elements`,
  used by `lambert.adb:241`, `lambert.adb:548`), `Hale_Orbital.Kepler` (with'd by
  `lambert.adb:12` but not directly called in the reviewed body — likely vestigial import),
  `Hale_Orbital.Stumpff` (`C`, `S`, called throughout `lambert.adb`'s bisection loop; contract
  guarantees `C'Result >= 0.0`/`S'Result >= 0.0`, `hale_orbital-stumpff.ads:36-58`, which
  `Lambert` relies on implicitly — see §5), `Hale_Orbital.Maneuvers` (with'd by
  `interplanetary.adb:8`, not directly exercised in the read code paths). **Domain 1**
  (`Hale_Orbital.Types`, `.Vectors`, `.Constants`) supplies all dimensional types
  (`Distance_Km`, `Velocity_Km_S`, `State_Vector`, `Vector_3D`) and physical constants
  (`Mu_Sun`, `Two_Pi`, `Pi`) used throughout.
- **Ada 2022 parallel loop feature**: declared as a design intent in `propagation.ads:186-189`
  ("Monte Carlo and ensemble propagation using Ada 2022 parallel features") but the bodies
  contain plain sequential `for` loops with an explicit `TODO` (`propagation.adb:506`,
  `propagation.adb:522`: "re-enable `parallel` once GNAT Ada 2022 runtime support is verified").
  Callers relying on the spec's documented parallelism will get correct but non-parallel
  behavior.
- **No filesystem, network, or OS interaction** anywhere in this domain — no file I/O, no
  environment variable reads, no external process calls. The only I/O touchpoints are in the
  example programs (`Ada.Text_IO` console output), which are usage demos, not library code.
- **Contract with Domain 5 (certification)**: `remaining_issues.csv` marks ISS-002 (multi-rev
  Lambert), ISS-004 (propagation energy test), ISS-010 (Ada 2022 parallel), ISS-011 (RK78
  implementation), ISS-022 (interplanetary/patched conics) all `COMPLETED`, while
  `docs/certification/compliance-issues.csv` independently tracks `ISS-004`, `ISS-010`,
  `ISS-025`, `ISS-030`, `ISS-042`, `ISS-044`, `ISS-050`, `ISS-052`, `ISS-062`, `ISS-063`,
  `ISS-064` for this domain as **`Open`**. Two of those (`ISS-062`, `ISS-063`, named-constant
  requests) already appear resolved in the current source (`lambert.adb:150-151` uses
  `Z_Bound_Hyperbolic`/`Z_Bound_Elliptic`; `lambert.adb:42,46` uses `Invalid_Function_Value`,
  both defined in `types.ads:145-150`) — the two tracking sheets are not mutually consistent,
  a Domain-5 concern to flag but out of this domain's remit to resolve.

## 5. Invariants and conventions

- **Convergence tolerance / iteration cap.** `Solve_Lambert`'s default tolerance is
  `Default_Tolerance = 1.0e-12` (`types.ads:25`), iteration cap `Max_Iter = 100`
  (`lambert.adb:101`), and the postcondition only promises `Iterations <= 100 and A > 0.0` when
  `Converged` (`lambert.ads:59-61`) — i.e., there is **no contract at all** on the non-converged
  case beyond `Converged = False`, so callers must always check `.Converged` before trusting any
  other field (the example programs do this correctly, e.g. `earth_mars_mission.adb:188`).
- **Semi-major-axis sign convention differs across the domain.** `Lambert.Solve_Lambert`
  computes `A := Y / (1.0 - Z * C_Z)` (`lambert.adb:187,228`); since `Stumpff.C'Result >= 0.0`
  always (`stumpff.ads:37`) and `Y >= 0.0` is enforced before this line, `A` as returned by
  `Lambert` is non-negative for every converged case in the coded `Z` bracket — this is why the
  postcondition `A > 0.0` (`lambert.ads:61`) is satisfiable. By contrast,
  `Interplanetary.Hyperbolic_Semi_Major_Axis` returns a **negative** value for hyperbolic legs
  by the standard vis-viva convention (`interplanetary.adb:100-110`, `return -Mu/V_inf²`).
  Code that mixes `Lambert.Result.A` with `Interplanetary`'s hyperbolic SMA must not assume a
  single sign convention.
- **Bisection bracket is never validated.** `Solve_Lambert` evaluates `F_Low`/`F_High` at the
  hard bounds (`lambert.adb:150-162`) but never checks that they bracket a root (opposite
  signs) before entering the main loop, and in fact never reads `F_Low`/`F_High` again after
  computing them — the loop restarts from `Z := 0.0` regardless
  (`lambert.adb:165-219`, confirmed by absence of `F_Low`/`F_High` in the loop body). This
  matches the open tracker item `ISS-030` ("bisection loop invariant missing bracket
  verification", `compliance-issues.csv:31`). The `pragma Loop_Invariant (Iter < Max_Iter)` at
  `lambert.adb:168` only bounds iteration count, not convergence correctness, and — because the
  body is `SPARK_Mode => Off` — is not formally discharged by `gnatprove` regardless.
  `Solve_Lambert_Bounded` (`lambert.adb:249-371`) diverges further: on `Y < 0.0` it moves
  `Z_High`/`Z_Low` based on `sign(Z)` (`lambert.adb:314-319`), a different recovery rule than
  `Solve_Lambert`'s `Z := Z*0.5`-or-`Z*2` rule (`lambert.adb:180-184`) for the nominally same
  algorithm — a maintenance/drift risk from the ~90%-duplicated implementation.
- **Degeneracy is checked inconsistently.** `Is_Degenerate_Transfer` (`lambert.adb:622-644`,
  threshold `Degenerate_Transfer_Threshold = 1.0e-6`, `types.ads:154`) is called by
  `Solve_Lambert_Multi` (`lambert.adb:395`) and `Count_Multi_Rev_Solutions`
  (`lambert.adb:655`), but **not** by `Solve_Lambert` itself. `docs/specs/05-lambert.md:40,57`
  documents that a ~180° transfer "raises `Invalid_Orbit`" — the `Invalid_Orbit` exception
  exists (`types.ads:194`) and is used extensively elsewhere in the library
  (`elements.adb`, `twobody.adb`, `kepler.adb`), but `Solve_Lambert` never raises it; a
  near-collinear `R1`/`R2` instead silently picks an arbitrary transfer plane via the
  `Cross_Z >= 0.0` tie-break (`lambert.adb:117-133`) and returns a numeric (possibly
  meaningless) answer rather than failing loudly. This is a real spec/implementation mismatch,
  not a documentation lag on a removed feature.
- **RK78 step-size control** follows a documented policy (growth capped at 2×, shrink floor at
  0.1×, `propagation.adb:319-320,333-334`, matching `ISS-011`'s "COMPLETED" note in
  `remaining_issues.csv:12`) and clamps to `[Min_Step, Max_Step]`
  (`propagation.adb:322-324,339-344`, defaults `0.001s`/`86400s`, `propagation.ads:72-73`).
  Error estimate is scale-relative (`propagation.adb:305-314`, `Pos_Scale = max(|Y7.Position|,
  1.0)`, `Vel_Scale = max(|Y7.Velocity|, 1e-6)`). See §6 for why the *order* this scheme assumes
  (`1/8` power law at `propagation.adb:319,333`, i.e., an 8th-order method) does not match what
  is actually being integrated.
- **Build-mode contract enforcement.** `hale_orbital.gpr:28` puts `-gnata` (enable
  assertions/contracts) in `Common_Switches`, applied to *all* four build modes, so
  `Pre`/`Post` on `Solve_Lambert`, `Sphere_Of_Influence`, etc. remain live checks even in
  `release` mode. However, `-gnato` (float overflow checking) is present in `debug`/`spark`/
  `deterministic` (`hale_orbital.gpr:36,50,58`) but **absent from `release`**
  (`hale_orbital.gpr:40-44`) — see Security observations.

## MATRIX FLAGS

### Security observations

This domain has no auth, secrets, network, or deserialization surface — it is pure numerical
code. The relevant "input parsing" risk is malformed/adversarial *numeric* input (attacker- or
fuzzer-controlled state vectors, times, tolerances) propagating into unguarded floating-point
operations:

1. **Unguarded division inside the Lambert bisection loop.** `lambert.adb:154,159,161,171-176,
   224-225,311-312,355-356` divide by `Sqrt (C_Z)` / `C_Z` (`C_Z = Stumpff.C(Z)`) with no
   explicit check that `C_Z > 0` before dividing, beyond `Stumpff.C`'s postcondition of
   `>= 0.0` (not `> 0.0`) (`stumpff.ads:37`). This is the tracked, still-`Open` **Critical**
   finding `ISS-010` (`compliance-issues.csv:11`: "Solve_Lambert divisions by Sqrt(C_Z) and C_Z
   without explicit pre-checks for C_Z > 0"). Because `release` mode omits `-gnato`
   (`hale_orbital.gpr:40-44`), a division producing `Infinity`/`NaN` in that mode would **not**
   raise `Constraint_Error` — it would silently propagate into `Result.V1`/`Result.V2`/`Result.A`
   and outward to any caller (e.g., a downstream maneuver planner) that trusts
   `Result.Converged = True` without a finiteness check. `debug`/`spark`/`deterministic` modes
   retain `-gnato` and would likely catch this.
2. **Degenerate-input silent misbehavior, not rejection.** As noted in §5, `Solve_Lambert` has
   no guard for near-collinear `R1`/`R2` (0°/180° transfers) even though the package-level docs
   (`docs/specs/05-lambert.md:40,57`) claim it raises `Invalid_Orbit`. An attacker or a buggy
   upstream caller supplying antiparallel position vectors gets a numerically "successful"
   (`Converged = True`) but physically undefined transfer plane rather than an exception —
   worth treating as an input-validation gap for any caller that treats `Converged` as a
   sufficient correctness signal.
3. **No filesystem/network/deserialization code** exists in `lambert.*`, `interplanetary.*`,
   or `propagation.*` — confirmed by absence of `Ada.Text_IO`/`Ada.Streams`/`GNAT.Sockets` `with`
   clauses in all six reviewed files. The only I/O in this domain's file set is in the example
   programs (`Ada.Text_IO` console output), which are demonstration code, not library entry
   points, and pose no meaningful attack surface.
4. **Contracts are runtime-enforced across all build modes** (`-gnata` common to all modes,
   `hale_orbital.gpr:28`) — a genuine positive: `Pre` conditions like `Magnitude (R1) > 0.0`,
   `Real (Tof) > 0.0` (`lambert.ads:54-58`) are not silently compiled away in `release`, unlike
   many C/C++ `assert`-based codebases. This mitigates (but does not eliminate, per point 1
   above) the numeric-input risk.

### Quality observations

1. **`RK78_Step` does not implement a valid Runge–Kutta stage computation, and the coefficients
   used do not correspond to a 7(8)-order method** (`propagation.adb:229-346`). Concretely:
   - The stage-generation loop (`propagation.adb:268-273`) computes every intermediate state
     `Temp` as `State + (H*C(I)) * K(1)` for `I in 2 .. 7` — i.e., **every stage 2–7 is built
     from `K(1)` only**, never from `K(2)`, `K(3)`, …, `K(6)` as a real explicit Butcher
     tableau requires (`Temp = y + h * Σ a_ij k_j`, with `j < i`, multiple nonzero `a_ij` per
     row for stages beyond the second). There is no `A`-matrix in this code at all, only the
     node vector `C` (`propagation.adb:252-255`). This is a structural defect discoverable by
     reading the code, independent of any runtime test.
   - The final combination weights (`propagation.adb:277-302`) —
     `35/384, 500/1113, 125/192, -2187/6784, 11/84` for the "7th order" solution and
     `5179/57600, 7571/16695, 393/640, -92097/339200, 187/2100` for the "8th order" estimate —
     are the literal, verifiable published coefficients of the classical **Dormand–Prince
     5(4) 7-stage pair (DOPRI5 / "ode45")**, not a 7(8) 13-stage method. The `C` array
     (`propagation.adb:252-255`) instead contains node values resembling the unrelated
     **DOP853 13-stage tableau** (e.g. `5490023248.0/9719169821.0`,
     `1201146811.0/1299019798.0`), of which only indices `1..7` are ever read; indices `8..13`
     are declared and initialized but dead. The `K`/`A` arrays are declared `(1 .. 13)`
     (`propagation.adb:243-244`) but only `1..7` are ever assigned.
   - Net effect: the function's name, header comment ("RK78 Dormand-Prince coefficients... 7th
     order with 8th order error estimate", `propagation.adb:223-226`; also asserted in
     `docs/certification/SDS.md:210,213` — "RK78 provides 1e-12 energy conservation per orbit")
     and its step-size controller's `1/8`-power law (`propagation.adb:319,333`, which assumes
     8th-order local truncation error) do not match what the code actually computes. This is
     very likely the substance behind the task brief's "known RK78 energy-conservation
     follow-up from the Phase 1 merge commit" — it is not yet called out as its own line item
     in `remaining_issues.csv` (ISS-011 there only claims the *step-scaling policy*, i.e. the
     2×/0.1× bounds, was fixed) or in `compliance-issues.csv`. Given this cannot be compiled
     or executed in this container, the actual resulting accuracy/energy-conservation numbers
     are **not verified here** — only the structural mismatch between the coefficients/stage
     logic and the documented order is a static, source-verifiable fact.
2. **Dead/duplicated logic in `Interplanetary.Hohmann_Phase_Angle`**
   (`interplanetary.adb:303-342`): the `if`/`else` branches at lines 325-331 both execute
   `Phase := Pi - Theta_Arr;` — the "inbound" branch comment ("departure planet should be
   behind") is not reflected in different code. This function has **zero test coverage**
   (no reference in any `ada/tests/*` file; only declared/defined/documented, confirmed via
   repo-wide search) — an untested function with a dead branch is a moderate correctness risk
   for any future caller doing non-Hohmann inbound phasing (e.g. Mars→Earth).
3. **`Solve_Lambert` and `Solve_Lambert_Bounded` are ~90% duplicated code**
   (`lambert.adb:67-246` vs. `lambert.adb:249-371`) with subtly different recovery behavior on
   `Y < 0.0` (see §5) — a classic copy-paste drift risk; a bug fix to one is easy to forget to
   port to the other.
4. **`Propagate_Parallel`/`Propagate_Parallel_RK4` are not parallel** despite their name, spec
   documentation ("Ada 2022 parallel loops", `propagation.ads:186-189,199-215`), and their
   presence in the domain decomposition inventory — both bodies are plain sequential `for`
   loops with `TODO` comments (`propagation.adb:504-509,520-526`). Tests
   (`ada/tests/hale_tests-parallel.adb`) validate *correctness/determinism* of these functions
   but, as sequential code, cannot exercise any actual concurrency defects (races, etc.) —
   which is currently moot since there is no concurrency, but will become a real gap the day
   `parallel` is re-enabled.
5. **Interplanetary "Test Coverage: JPL Horizons, Orekit reference CSVs" claim (inventory
   §8, Domain 3) is aspirational, not current.** No `data/`, `horizons/*.csv`, or
   `orekit/*.csv` files exist in the repository (confirmed absent; `docs/ARCHITECTURE.md:108,
   120-122` and `docs/ROADMAP.md:27-35` list ephemerides/JPL-Horizons/Orekit validation as
   **planned**, not implemented). Actual test coverage for this domain
   (`ada/tests/hale_tests-integration.adb:389-435`, `hale_tests-vallado.adb:260-298`,
   `hale_tests-lambert_multirev.adb`, `hale_tests-negative.adb:412-471`) is entirely synthetic/
   analytic (Vallado textbook examples, hand-computed SOI/synodic-period sanity checks), which
   is reasonable but should not be conflated with external-oracle cross-validation.
6. **Lambert vs. its own spec doc.** `docs/specs/05-lambert.md:3,35,68-70` and
   `docs/ARCHITECTURE.md:26` both correctly state the *current* implementation is Battin's
   universal-variable method and that Izzo (2014) is a **planned Phase 6 replacement** — but
   `README.md:7,84` markets "Lambert (Izzo)" as a present-tense capability, and the Phase-1
   domain-decomposition inventory (`docs/review/00-inventory.md:492`) labels this domain
   "Lambert's problem solver, Izzo 2014" outright. The actual algorithm in
   `lambert.adb` (bisection over Stumpff functions, no Izzo-style Householder/halley iteration
   on the "vercosine" variable) is Battin/Vallado-style universal variables, not Izzo's method.
   This is a documentation-consistency issue for Domain 5 to reconcile, flagged here because it
   affects how any reviewer should interpret this domain's name.
7. **`Get_Transfer_Elements`/`Departure_Delta_V`/`Arrival_Delta_V`/`Total_Delta_V`**
   (`lambert.ads:118-137`, `lambert.adb:544-571`) have no `Pre` contracts at all (only
   `Global => null`), unlike almost every other function in this domain — inconsistent
   contract density within the same package.
8. **`Solve_Lambert_Multi` has no `Pre` contract validating `Max_Revs`** relative to the
   `Max_Solutions` array sizing (`lambert.adb:381-382`); this matches the open tracker item
   `ISS-025` (`compliance-issues.csv:26`).
