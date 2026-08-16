# Domain Report: Two-Body & Classical Orbital Mechanics (`classical-astrodynamics`)

**Reviewer:** L3 Domain Analyst (Phase 3 Deep Dive)
**Scope:** `ada/src/hale_orbital-twobody.ads/.adb`, `hale_orbital-elements.ads/.adb`,
`hale_orbital-kepler.ads/.adb`, `hale_orbital-stumpff.ads/.adb`, `hale_orbital-maneuvers.ads/.adb`;
usage evidence from `ada/examples/hohmann_transfer.adb`, `ada/examples/orbit_propagation.adb`.
**Method:** Static reading only. The Ada/SPARK toolchain is not installed in this container, so no
compilation, execution, or `gnatprove` run was performed — every claim below is derived from source
text, cross-referenced against sibling files and, where relevant, the repository's own certification
docs. Nothing here should be read as a runtime-verified result.

---

## 1. Responsibility

This domain implements the classical (unperturbed, two-body) orbital-mechanics kernel of the library:
converting between Cartesian state vectors and Keplerian orbital elements, solving Kepler's equation
for all conic types (elliptic/parabolic/hyperbolic/universal-variable), and computing impulsive
maneuvers (Hohmann, bi-elliptic, plane change, phasing, escape/capture). It is the mathematical
foundation that the trajectory-design domain (Lambert, Propagation, Interplanetary) and the example
programs build on to answer "where is the spacecraft, and how much fuel does a burn cost."

## 2. Key modules

| File | Role |
|---|---|
| `ada/src/hale_orbital-twobody.ads/.adb` | Energy/momentum, vis-viva, orbital period/mean motion, conic geometry (semi-latus rectum, periapsis/apoapsis), orbit classification, eccentricity vector — the algebraic identities of two-body motion (Hale Ch. 2-3). `twobody.ads:16-225`, body `twobody.adb:1-294`. |
| `ada/src/hale_orbital-elements.ads/.adb` | Bidirectional Cartesian ↔ Keplerian conversion (`State_To_Elements` `elements.adb:59-212`, `Elements_To_State` `elements.adb:218-310`), anomaly conversions (true/eccentric/mean/hyperbolic), angle normalization, element validation. Handles circular/equatorial singularities explicitly. |
| `ada/src/hale_orbital-kepler.ads/.adb` | Iterative Kepler-equation solvers: `Solve_Kepler_Elliptic` (Newton-Raphson, `kepler.adb:23-67`), `Solve_Kepler_Hyperbolic` (`kepler.adb:69-120`), `Solve_Kepler_Parabolic` (closed-form Cardano/Barker, `kepler.adb:122-137`), `Solve_Kepler_Universal` (universal-variable Newton-Raphson via Stumpff functions, `kepler.adb:144-214`), time-of-flight functions, and `Propagate` (f/g-function state propagation, `kepler.adb:346-424`). |
| `ada/src/hale_orbital-stumpff.ads/.adb` | Stumpff `C(z)`/`S(z)` functions and derivatives underlying the universal-variable formulation; Taylor-series fallback near `z=0` for numerical stability (`stumpff.adb:21-81`, threshold `stumpff.adb:15`). `Pure` package (`stumpff.ads:16-19`). |
| `ada/src/hale_orbital-maneuvers.ads/.adb` | Hohmann transfer (`maneuvers.adb:20-99`), bi-elliptic transfer (`maneuvers.adb:105-193`), simple/combined plane change, general coplanar transfer, phasing orbits, escape/capture delta-V, C3 energy/departure velocity. |

## 3. Data flow — representative trace: propagating an orbit by time Δt

1. **Entry** — caller supplies a `State_Vector` (`Position`, `Velocity` in km, km/s) or `Orbital_Elements`
   plus a `Gravitational_Parameter Mu` (e.g. `Mu_Earth` from the dimensional-foundation domain's
   `Constants` package). Example: `ada/examples/orbit_propagation.adb:44-53` builds a Molniya-type
   element set and converts it via `Elements_To_State` (`elements.adb:218-310`).
2. **Elements → State** — `Elements_To_State` computes semi-latus rectum `p` from `(a,e)`
   (`elements.adb:254-259`, branching on `E<1` vs hyperbolic), radius at true anomaly
   (`elements.adb:266-268`), builds the perifocal-frame position/velocity (`R_PQW`, `V_PQW`,
   `elements.adb:274-283`), then rotates PQW → ECI via the combined `R3(-Ω)·R1(-i)·R3(-ω)` matrix
   inlined as scalar trig expressions (`elements.adb:294-307`) rather than calling
   `Hale_Orbital.Matrices` (cross-domain note: a near-duplicate rotation exists in
   `hale_orbital-matrices.adb:211-239`'s `Perifocal_To_Inertial`).
3. **Propagate** — `Hale_Orbital.Kepler.Propagate(State, Dt, Mu)` (`kepler.adb:416-424`) delegates to
   the vector form (`kepler.adb:346-414`): computes radial velocity `Vr0 = (R0·V0)/|R0|`, reciprocal
   semi-major axis `Alpha`, then calls `Solve_Kepler_Universal` (`kepler.ads:74-84`,
   `kepler.adb:144-214`) which Newton-iterates on the universal anomaly `χ` using `Stumpff.C`/`Stumpff.S`
   (`kepler.adb:183-184`, delegated via `renames` at `kepler.ads:65,69`) until `|Δχ| < Tolerance` or
   `Max_Iter` (default 50, `hale_orbital-types.ads:28`) is exceeded, at which point
   `Convergence_Error` is raised (`kepler.adb:198-199, 208-209`). The `f`/`g` functions then map the
   new `χ` back to `R_Out`, `V_Out` (`kepler.adb:400-413`).
4. **State → Elements (verification/telemetry)** — the example converts the propagated state back to
   elements via `State_To_Elements` (`elements.adb:59-212`) to read off true anomaly for display
   (`orbit_propagation.adb:113-117`). This function derives `h = r×v`, the node vector `n = Ẑ×h`, and
   the eccentricity vector `e_vec` (from `Twobody.Eccentricity_Vector`, `twobody.adb:271-285`), then
   resolves the six classical elements with explicit branches for circular (`E_Mag < Circular_Threshold`,
   `elements.adb:135-137,167-187`) and equatorial (`N_Mag < 1.0e-10`, `elements.adb:138-145,169-171`)
   singularities.
5. **Exit** — results leave the domain as `State_Vector` / `Orbital_Elements` records (plain arrays of
   `Real`-derived dimensional types, no allocation, no I/O) consumed by callers: example programs via
   `Ada.Text_IO`, or the trajectory-design domain (Lambert/Interplanetary — see §4).

A second representative flow, the Hohmann transfer (`ada/examples/hohmann_transfer.adb:47-61`), is
purely algebraic (no iteration): `Circular_Velocity` → `Hohmann_Transfer` (`maneuvers.adb:20-71`,
vis-viva at both radii) → `Hohmann_Result` record with ΔV1/ΔV2/transfer time/eccentricity, all in one
non-recursive function call with no iteration or exception paths beyond the `R1,R2 <= 0` guard
(`maneuvers.adb:35-37`).

## 4. External dependencies

- **`Hale_Orbital.Types`** (dimensional-foundation domain) — supplies all dimensional subtypes
  (`Distance_Km`, `Velocity_Km_S`, `Angle_Radians`, `Gravitational_Parameter`, …, each `is new Real`,
  `hale_orbital-types.ads:34-52`), the `Orbital_Elements` and `State_Vector` records
  (`types.ads:97-119`), solver defaults `Default_Tolerance = 1.0e-12` / `Default_Max_Iterations = 50`
  (`types.ads:25,28`), classification thresholds (`Circular_Threshold`, `Parabolic_Threshold`,
  `High_Eccentricity_Threshold`, `Small_Threshold`, `types.ads:125-135`), and the three exceptions this
  domain raises (`Convergence_Error`, `Invalid_Orbit`, `Physical_Error`, `types.ads:191-197`). Contract
  assumed: callers treat these as opaque numeric-strong-typed wrappers and only convert between them
  via explicit `Real(...)` casts — every body in this domain does so pervasively (e.g.
  `twobody.adb:32,44,67`).
- **`Hale_Orbital.Constants`** (dimensional-foundation) — physical constants (`Mu_Earth`, `Mu_Sun`,
  `R_Earth`, `Pi`, `Two_Pi`, …, `hale_orbital-constants.ads:20-75`) and math constants used throughout.
- **`Hale_Orbital.Vectors`** (dimensional-foundation) — `Dot`, `Cross`, `Magnitude`, `Magnitude_Squared`
  (`hale_orbital-vectors.ads:50-68`) used by `Twobody` and `Elements` for angular-momentum and
  eccentricity-vector algebra. Assumed contract: operates on plain `Vector_3D` arrays with no
  dimensional tagging beyond what the caller re-wraps.
- **`Ada.Numerics.Generic_Elementary_Functions`** — instantiated per body (`twobody.adb:5,13`,
  `elements.adb:5,14`, `kepler.adb:5,16`, `stumpff.adb:5,11`, `maneuvers.adb:5,13`) for
  `Sqrt/Sin/Cos/Tan/Arctan/Arccos/Exp/Log`. This is the stated reason every body in this domain sets
  `SPARK_Mode => Off` (see §5/§6 — SPARK 2014 does not support generic instantiation in proved bodies,
  per `docs/certification/spark-scope.md:79-92`).
- **Downstream consumers (trajectory-optimization domain, out of scope but touching this domain):**
  `hale_orbital-lambert.adb` and `hale_orbital-interplanetary.ads/.adb` both `with` this domain's
  packages (confirmed via grep; `hale_orbital-elements.adb`, `-kepler.adb`, `-maneuvers.adb` are the
  only in-domain files that in turn `with` each other). Notably `Hale_Orbital.Propagation` (numerical
  RK4/RK7(8) integrator, Domain 3) does **not** depend on `Hale_Orbital.Kepler` — the repo has two
  independent orbit-propagation code paths (analytic universal-variable in this domain vs. numerical
  integration in Propagation) and no test found in `ada/tests/` cross-validates them against each
  other for a plain two-body case; a shared regression fixture would be cheap insurance.
  `Hale_Orbital.Threebody` (CR3BP, Domain 4) also does not depend on this domain — it is dynamically
  self-contained.

## 5. Invariants and conventions

- **Dimensional-type discipline.** Every physical quantity is a distinct Ada type derived from `Real`
  (`Long_Float`); arithmetic across types requires explicit `Real(...)` conversion. All five modules
  follow this consistently — no raw `Float`/`Long_Float` literals leak into public signatures.
- **`SPARK_Mode => On` at spec level, `Off` at body level, everywhere in this domain.** Confirmed for
  all five `.ads`/`.adb` pairs (e.g. `twobody.ads:17` vs `twobody.adb:10`; same pattern in
  `elements.ads:14`/`elements.adb:11`, `kepler.ads:17`/`kepler.adb:13`, `stumpff.ads:17`/`stumpff.adb:8`,
  `maneuvers.ads:17`/`maneuvers.adb:10`). This means `gnatprove` only checks Pre/Post/Global contract
  well-formedness at the interface, never the actual arithmetic, exception raises, or loop convergence
  inside the bodies. See §6 for why the "formally verified" framing in header comments is misleading.
- **Circular dependency avoidance via duplication, not delegation.** `Hale_Orbital.Kepler` `with`s
  `Hale_Orbital.Elements` (`kepler.adb:9`) to reuse anomaly conversions for time-of-flight. This forces
  the opposite direction to be impossible: `Elements.Mean_To_Eccentric_Anomaly`
  (`elements.ads:86-93`, doc comment "This is just a wrapper that calls the Kepler solver") cannot
  actually call `Hale_Orbital.Kepler.Solve_Kepler_Elliptic` without creating a package cycle, so
  `elements.adb:377-416` **re-implements** the identical Newton-Raphson loop found in
  `kepler.adb:23-67` (same initial-guess heuristic at `High_Eccentricity_Threshold`, same
  convergence/`Convergence_Error` structure). The two copies are algorithmically equivalent today but
  a fix to one (e.g. a numerical-stability improvement) will not propagate to the other unless the
  maintainer remembers both exist.
- **Threshold-driven orbit-type dispatch is used inconsistently.** `Classify_Orbit`
  (`twobody.adb:194-207`) and most anomaly/TOF functions guard against `E >= 1` using
  `Parabolic_Threshold = 1.0e-10` (`types.ads:126`). But several conic-geometry functions accept any
  `Real` eccentricity with **no precondition at all**: `Semi_Latus_Rectum` (`twobody.ads:127-128`),
  `Periapsis_Distance` (`twobody.ads:133-134`), and `Radius_At_True_Anomaly` (`twobody.ads:145-148`,
  guarded only against a zero denominator, not against `E<0`/`E>=1` producing physically nonsensical
  radii). `Apoapsis_Distance` is the outlier that does raise `Invalid_Orbit` for
  `E > 1 - Parabolic_Threshold` (`twobody.adb:156-158`). Callers relying on exceptions to catch bad
  eccentricities cannot assume every sibling function in the same package enforces them.
- **Bounded iteration.** Every Newton-Raphson loop in `Kepler` carries `pragma Loop_Invariant (Iter <
  Max_Iter)` (`kepler.adb:45,95,177`) and raises `Convergence_Error` deterministically at `Max_Iter`
  (default 50) — a good DO-178C-relevant invariant (bounded worst-case iteration count) that is
  actually enforced in code, not just documented.
- **Exception contract.** Three domain exceptions are used purposefully but without a documented
  mapping table: `Physical_Error` for degenerate/near-zero magnitudes (e.g.
  `twobody.adb:28-30,79-81`), `Invalid_Orbit` for out-of-range eccentricity/orbit-type mismatches (e.g.
  `elements.adb:249-251`, `twobody.adb:156-158,185-186`), `Convergence_Error` for iteration failure and
  degenerate-derivative Newton steps (`kepler.adb:51-52,104-105,198-199`). All three are Ada exceptions
  (not `Result`/status-code returns), so every caller across domains must handle them or accept
  propagation — none of the `.ads` specs declare which exceptions a function may raise (no
  `--  Raises:` convention), so this is discoverable only by reading bodies.

## 6. MATRIX FLAGS

### Security observations

- **No traditional attack surface** (no network, filesystem, deserialization, auth, or secrets) in
  this domain — it is pure numerical computation over in-memory records. The relevant "security" lens
  here is closer to safety/robustness of the numeric kernel, since this is a certification-flavored
  (DO-178C) codebase where a formally-unverified body performing spacecraft trajectory math is the
  functional equivalent of an unvalidated-input problem in other domains.
- **Documentation overstates SPARK verification level for this exact domain.** The Phase-1 inventory
  (`docs/review/00-inventory.md:486`) states Domain 2's "SPARK Proof Level: Gold on kernel routines
  (high criticality)." The repository's own certification scope document contradicts this directly:
  `docs/certification/spark-scope.md:59-64` classifies `Hale_Orbital.Elements`, `.Kepler`, `.Stumpff`,
  and `.Twobody` bodies as **Bronze** ("flow analysis only" — the *weakest* of the three defined
  levels, not even AoRTE proof), explicitly because of the generic-instantiation exemption
  (`spark-scope.md:79-98`). Further, `spark-scope.md:251-252` lists even the Silver/Gold targets for
  *other* packages (Vectors, foundation) as "Pending," and CI's SPARK job is `continue-on-error: true`
  because `gnatprove` is not installed in the Alire 2.0.2 toolchain
  (`docs/review/00-inventory.md:396,220-224`). Net effect: none of the iterative Newton-Raphson solvers,
  coordinate-frame rotations, or exception-raising arithmetic in this domain has ever been machine-proved
  free of runtime errors; the only enforced check is that the `.ads` contract shapes are legal SPARK.
  Header comments in the domain reinforce the overstated impression, e.g. `twobody.ads:10` "formally
  verifiable," `kepler.ads:10` "Core solvers proven free of runtime errors," `stumpff.ads:11` "Pure
  mathematical functions, formally verified" — none of which is currently true for the bodies as
  written (`SPARK_Mode => Off` on all of them).
- **Numeric-input validation is exception-based and inconsistent (see §5).** Because several
  geometry functions (`Semi_Latus_Rectum`, `Periapsis_Distance`, `Radius_At_True_Anomaly`) have no
  `Pre` guarding eccentricity range, a caller passing an out-of-physical-range `E` (e.g. negative, or
  ≥1 where an elliptical assumption is implied elsewhere) gets silently-wrong output instead of a
  raised exception, unlike `Apoapsis_Distance` (`twobody.adb:156-158`) or the anomaly-conversion
  functions in `Elements` which do check (`elements.ads:64,71,91,99`). This "sometimes validated,
  sometimes not" pattern across sibling functions in the same package is the closest analogue to an
  input-validation gap in this domain.
- **Deep recursion/DoS surface:** none observed — all iteration is bounded by `Max_Iter` (default 50)
  with a hard `Convergence_Error` raise (`kepler.adb:61-63,114-116,208-210`, plus the duplicated
  version in `elements.adb:408-412`), so this domain cannot hang.

### Quality observations

- **Confirmed compile-breaking bug in an example file within this domain's usage-evidence scope.**
  `ada/examples/orbit_propagation.adb:72,75` calls `Periapsis_Radius (...)` and `Apoapsis_Radius (...)`.
  No such functions exist anywhere in the Ada tree; the actual `Hale_Orbital.Twobody` functions are
  named `Periapsis_Distance` (`twobody.ads:133`, defined `twobody.adb:147-151`) and
  `Apoapsis_Distance` (`twobody.ads:139`, defined `twobody.adb:153-161`). This file would fail to
  compile as written. Consistent with this: `ada/examples/hale_examples.gpr` is never invoked by
  `.github/workflows/ci.yml` (no reference to `examples` or `hale_examples.gpr` found in the workflow),
  so the example tree is not build-verified — this bug has apparently sat uncaught.
- **Duplicated Kepler solver logic (see §5).** `Elements.Mean_To_Eccentric_Anomaly`
  (`elements.adb:377-416`) re-implements the same Newton-Raphson algorithm as
  `Kepler.Solve_Kepler_Elliptic` (`kepler.adb:23-67`) instead of delegating, contradicting its own doc
  comment ("This is just a wrapper that calls the Kepler solver," `elements.ads:87`). A future fix
  to one copy (tolerance handling, initial-guess heuristic, iteration cap) risks silently not applying
  to the other.
- **Validation-suite / production-type contract mismatch (cross-domain, rooted in this domain's
  `Orbital_Elements` record).** `hale_orbital-types.ads:109-115` defines `Orbital_Elements` with field
  `Argument_Of_Periapsis` and exactly six components (no epoch field). Two files under `ada/tests/`
  reference a **different, non-existent shape**: `ada/tests/hale_tests-vallado.adb:71,110` read/write
  `Elements.Arg_Periapsis` (wrong field name — would fail to compile), and
  `ada/tests/hale_tests-exceptions.adb:185,187,212,214` build `Orbital_Elements` aggregates with both
  `Arg_Periapsis =>` (wrong name) and `Epoch => 0.0` (field that does not exist in the record at all).
  These would not compile against the current type. This did **not** break the documented "37 tests
  pass locally" claim because the officially wired test binary, `ada/tests/run_tests.adb`
  (`Main` per `ada/tests/hale_tests.gpr:11`), is a self-contained 742-line file that does not `with`
  `Hale_Tests.Vallado` or `Hale_Tests.Exceptions` at all (`run_tests.adb:8-19` shows no such
  dependency) — it re-implements its own smaller `Test_Twobody`/`Test_Elements`/`Test_Kepler`/
  `Test_Maneuvers` suites (`run_tests.adb:123-501`) that do use the correct field names. However, the
  broken files *are* pulled in by `ada/tests/test_driver_coverage.adb:19-24` (`with Hale_Tests.Vallado`,
  `with Hale_Tests.Exceptions`), which is the `Main` of `ada/coverage.gpr:12` — the project used by
  `scripts/merge_coverage.sh:201` (`./bin/test_driver_coverage --suite=...`) for the DO-178C MC/DC
  coverage pipeline. As read, that coverage build would fail to compile. This is squarely a
  testing/certification-domain issue but the root cause (record shape drift against
  `hale_orbital-types.ads`) is specific to this domain's core data type and worth flagging here for the
  quality auditor and certification-safety reviewer.
- **Test depth for this domain, as actually exercised by CI:** `run_tests.adb` covers basic circular/
  elliptical cases (`Test_Twobody` `run_tests.adb:123-168`, `Test_Elements` `170-221`, `Test_Kepler`
  `223-254`, `Test_Maneuvers` `256-501`) but does not exercise hyperbolic orbits, near-parabolic
  eccentricities, the universal-variable solver directly, or any exception path
  (`Convergence_Error`/`Invalid_Orbit`/`Physical_Error`) for this domain. Substantially richer
  boundary/negative coverage for exactly these gaps exists in `ada/tests/hale_tests-boundaries.adb`
  (near-circular/near-parabolic/just-hyperbolic eccentricity sweeps, e.g.
  `boundaries.adb:40-57,105-162,171-...`) and `ada/tests/hale_tests-negative.adb` (invalid
  eccentricity/SMA/radius/mu/tolerance/angular-momentum, e.g. `negative.adb:42-113,126,201,267,484,540`)
  — but neither file is `with`ed by `run_tests.adb`, `run_all_tests.adb`, nor referenced by any CI job,
  so this coverage is effectively dead/unexercised in the pipeline that produces the "tests pass"
  signal, and (per the point above) the coverage-instrumented build that *would* pull some of it in is
  currently broken.
- **`Optimal_Bielliptic_Radius` doesn't optimize.** Doc comment promises "Returns the radius that
  minimizes total delta-V" (`maneuvers.ads:96-98`), but the implementation
  (`maneuvers.adb:176-193`) performs no minimization — it returns a fixed heuristic (`100.0 *` the
  larger radius) whenever `Bielliptic_Is_Efficient` is true, and ignores `Mu` entirely
  (`pragma Unreferenced (Mu)`, `maneuvers.adb:179`). Functionally reasonable as an
  approaches-infinity approximation, but the name/doc oversell precision the function doesn't deliver.
- **`Coplanar_Transfer` ignores its true-anomaly inputs.** `Nu1`/`Nu2` parameters are explicitly
  discarded (`pragma Unreferenced (Nu1, Nu2)`, `maneuvers.adb:269`); the function reduces to a
  periapsis-to-periapsis Hohmann transfer (`maneuvers.adb:271-276`) regardless of where the two
  spacecraft actually are on their orbits. This is acknowledged in a code comment ("For simplicity...")
  but not in the public `.ads` doc comment (`maneuvers.ads:140-148`), so a caller reading only the spec
  could reasonably expect phase-aware transfer geometry.
- **No dead code found** within the five in-scope files themselves — every exported function in the
  five `.ads` files has a corresponding `.adb` body and appears to be reachable from at least one
  example or (partially, per above) test file.
- **Complexity hotspot:** `State_To_Elements` (`elements.adb:59-206`, ~148 lines) is the most complex
  single function in the domain — five nested singularity branches (parabolic energy, equatorial RAAN,
  circular argument-of-periapsis, circular-equatorial true-longitude, quadrant checks via `r·v` and
  `h_z`/`e_z` sign) with no unit test isolating each branch individually (the one test in
  `run_tests.adb:170-221` only exercises the circular-equatorial path).

---

**Cross-domain touchpoints noted, not investigated further:** `Hale_Orbital.Lambert` and
`Hale_Orbital.Interplanetary` (trajectory-optimization domain) consume this domain's `Elements`,
`Kepler`, and `Twobody` packages; `Hale_Orbital.Matrices.Perifocal_To_Inertial`
(`hale_orbital-matrices.adb:211-239`, dimensional-foundation domain) duplicates the rotation math
inlined in `Elements.Elements_To_State`; the coverage/testing gaps above belong to the testing and
certification-safety domains but are rooted in this domain's `Orbital_Elements` record contract.
