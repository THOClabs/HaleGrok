<!-- BEGIN REPO-REVIEW (generated) -->
# Repo Review Summary — HALE Orbital Mechanics
Full-repository review completed **2026-07-12** (commit 0345758); full remediation of its
findings landed **2026-07-13** on the same PR (risks R1–R10, Q-1..Q-18 addressed). Review
corpus: `docs/review/` (start with `60-executive-summary.md`; per-entry fix status in
`50-risk-register.md`). Historical claims inside `docs/review/` describe the PRE-remediation
state — trust this section and the code for current reality.

## System map
- **Dimensional foundation** — `ada/src/hale_orbital-{types,constants,vectors,matrices}.ads/.adb`: `pragma Pure` base layer (Real=Long_Float, dimensional scalar types, 3D/6x6 algebra); imported by nearly every other unit.
- **Classical astrodynamics** — `twobody`, `elements`, `kepler`, `stumpff`, `maneuvers`: two-body dynamics, Cartesian↔Keplerian, Kepler solvers, impulsive maneuvers.
- **Trajectory optimization** — `lambert` (standard universal-variable/BMW formulation, single+multi-rev, guarded numerics), `propagation` (RK4, real Dormand-Prince 5(4), real Fehlberg 7(8), task-pool parallel ensembles), `interplanetary` (patched conics).
- **Restricted astrodynamics** — `ada/src/threebody/hale_orbital-threebody.adb` (CR3BP: Lagrange points, Jacobi, real Fehlberg 4(5), STM/monodromy, palindromic Floquet eigensolver, periodic orbits) plus `python/three-body-extension/` (independent NumPy/SciPy oracle) connected via `validation/` (committed CSV reference data + `Hale_Tests.Oracle`).
- **Certification/infrastructure** — `docs/certification/` (SRS v2.0 is the canonical requirement set: 144 IDs, level-prefixed `HLR-1A-*` scheme; rtm.md carries Legacy ID column), `.github/workflows/ci.yml`, `scripts/merge_coverage.sh`, `ada/*.gpr`.

## Build / run / test / lint (verified 2026-07-13)
- **Toolchain:** Alire path or `apt-get install gnat-14 gprbuild` (what CI compile-gates and `.claude/setup.sh`'s fallback use; unversioned symlinks may be needed — see setup.sh).
- **Library:** `gprbuild -P ada/hale_orbital.gpr -p -XBUILD_MODE=debug|release|spark|deterministic` — all four modes build warning-free under `-gnatwe`.
- **Tests:** `gprbuild -P ada/tests/hale_tests.gpr -p` then `./ada/bin/run_tests` (77/77) and `./ada/bin/run_all_tests` (399/399, includes the Python-oracle cross-validation; run from repo root so `validation/data/` resolves). Both propagate failures via exit status.
- **Examples:** `gprbuild -P ada/examples/hale_examples.gpr -p` — all 7 build.
- **Python oracle:** `cd python/three-body-extension && python3 -m pytest` (134 fast; `-m slow` adds 5 + 3 xfail). Ruff configured in its `pyproject.toml`.
- **Cross-validation:** `python3 validation/generate_reference.py` regenerates `validation/data/*.csv`; `--check` is the CI drift gate (numeric compare — per-column tolerances documented in the script).
- **CI (all jobs gate except spark-flow):** build-and-test (debug+release, both runners), compile-gates (examples + coverage closure + Units-list sync), python-oracle (ruff + pytest + drift gate), doc-lint. `spark-flow` is informational only — gnatprove is genuinely unavailable; do NOT cite it as verification evidence.
- **Still never runs:** gnatprove and gnatcov (AdaCore tooling unavailable in CI/containers). SPARK status is Bronze everywhere: contracts defined, proof pending.

## Conventions and invariants to respect
- Dimensional scalar types are distinct derived types; convert with explicit `Real(...)` casts at boundaries. This catches swapped-quantity bugs only — it is NOT dimensional analysis, and `Position_Vector`/`Velocity_Vector` are interchangeable subtypes.
- Shared exception set (`types.ads`): `Convergence_Error`, `Invalid_Orbit`, `Physical_Error`, `Singularity_Error`. Solvers use bounded iteration (`Max_Iter` + `pragma Loop_Invariant`) and report failure via `Converged`/`Valid` flags — keep it that way.
- `-gnata` applies to ALL build modes: Pre/Post contracts stay live even in release. No mode traps float division by zero (no `-gnateF`) — guard denominators explicitly; Lambert/matrices show the pattern (`Small_Threshold`, `Singularity_Threshold`). Every numeric tolerance gets a DEC-009 entry.
- SPARK pattern: `SPARK_Mode => On` on specs, `Off` on bodies (all 12, `Generic_Elementary_Functions` instantiation). Never write "proven free of runtime errors" claims — gnatprove has never run.
- CR3BP: mass ratio `mu = m2/(m1+m2)`, smaller body second, `0 < mu < 0.5`; state ordering `[x,y,z,vx,vy,vz]` (+36 STM elements row-major). Predefined systems' `Mass_Ratio` must equal `Mu2/(Mu1+Mu2)` — tested.
- Lambert `Tolerance` is RELATIVE to the requested TOF (documented in-code); `Solve_Lambert` raises `Invalid_Orbit` for ~180° geometry and never returns `Converged=True` with non-finite or non-positive-A results.
- `-gnatwe` (warnings-as-errors) + `-gnaty3M200` (3-space indent, ≤200 cols) in the library gpr — new warnings/style breaks fail builds.
- Doc-lint CI greps `.claude/` and `docs/plans/` for archived persona names (frodo/gandalf/hobbit/bilbo/sam-wise).
- `ada/coverage.gpr`'s `Units` list mirrors `ada/src/*.ads` — CI diffs the two sets; update both when adding a package.
- Requirement IDs: SRS.md (level scheme, `HLR-1A-*` …) is canonical; new requirements get new SRS entries first, then rtm/test-rtm rows.

## Danger zones (extra care required)
- `ada/src/threebody/hale_orbital-threebody.adb` — still the largest file (~1,500 LOC after fixes); DEC-005 now recommends splitting it once stable. `Analyze_Floquet` assumes symplectic (monodromy) input — its `Valid` flag reports residual checks; don't feed it arbitrary matrices and trust the multipliers.
- `ada/src/hale_orbital-types.ads` — shared record shapes (`Orbital_Elements`, `State_Vector`, Lambert Z-bounds); changes ripple through every domain. Historic drift here broke builds for months because nothing compiled the test estate — the compile-gates CI job now exists precisely for this.
- `validation/data/*.csv` — committed reference data; regenerate with the script (never hand-edit) and keep `--check` green. Headers carry tool versions but deliberately no dates.
- `ada/tests/hale_tests-oracle.adb` — tolerance rationale is documented in its header; loosening a tolerance requires a DEC-009-style justification.
- `docs/review/` — a historical record of the 2026-07-12 review; do not "fix" its findings text retroactively (the risk register carries the fix-status annotations instead).
<!-- END REPO-REVIEW (generated) -->
