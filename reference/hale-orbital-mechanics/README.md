# HALE Orbital Mechanics

A research-grade **Ada 2022 / SPARK** astrodynamics library, based on Francis J. Hale's *Introduction to Space Flight* (Prentice Hall, 1994) and on Vallado's *Fundamentals of Astrodynamics and Applications* (4ᵗʰ ed., 2013), with selected algorithms from the astrodynamics literature.

**What exists today:**

- Two-body dynamics, Keplerian ↔ Cartesian conversions, Kepler solvers (elliptic / hyperbolic / parabolic / universal), impulsive maneuvers (Hohmann, bi-elliptic, plane change, phasing).
- Lambert's problem via **Battin-style universal-variable bisection** (single and multi-revolution), with guarded numerics: degenerate 180° geometry is rejected, and a result is never marked converged with non-finite or non-physical values.
- Numerical propagation: RK4, embedded **Dormand–Prince 5(4)** and **Fehlberg 7(8)** adaptive integrators (validated against the analytic Kepler propagator), J2 perturbation model, task-parallel ensemble propagation.
- Circular Restricted Three-Body Problem: Lagrange points, Jacobi constant, equations of motion, STM/monodromy propagation, Floquet stability analysis (full 6-eigenvalue symplectic solver), periodic-orbit machinery (Richardson guess, differential correction, family continuation) — adaptive-propagation and manifold portions still partial.
- Patched-conic interplanetary design (SOI, gravity assist, Hohmann phase angles).
- Compile-time dimensional scalar types, Ada 2022 `Pre`/`Post` contracts live in **all** build modes, `SPARK_Mode => On` specifications.
- An independent **Python (NumPy/SciPy) CR3BP oracle** with a CSV cross-validation pipeline: `validation/generate_reference.py` produces committed reference data that the Ada test suite re-derives and compares against.

**Aspirational (planned, not present — see `docs/ROADMAP.md`):** IAU/IERS-2010 frames, EGM2008 gravity, third-body/SRP/drag forces, Gauss-Jackson/Gauss-Radau/symplectic propagators, orbit determination, Izzo-method Lambert, low-thrust optimization, invariant-manifold design tools.

**Assurance status, honestly stated:** contracts are enforced at runtime in every build mode (`-gnata` is unconditional), the test estate (both runners, examples, coverage closure) builds and gates in CI, and certification documents (DO-178C reference) trace requirements to tests. SPARK **proof has not run** — `gnatprove` is not available in the CI toolchain; all packages are at Bronze (flow-analysis scope defined, bodies exempted for generic instantiation per `docs/certification/spark-scope.md`). MC/DC coverage tooling (`gnatcov`) is likewise configured but not exercised in CI.

## Project Layout

```
hale-orbital-mechanics/
├── ada/                       # Primary implementation
│   ├── src/                   # Hale_Orbital.* packages
│   ├── tests/                 # Test programs (run_tests, run_all_tests, coverage driver)
│   └── examples/              # End-to-end mission examples
├── python/
│   └── three-body-extension/  # Validation oracle (CR3BP, Lagrange, halo families)
├── validation/                # Python→CSV→Ada cross-validation reference data
├── docs/
│   ├── ARCHITECTURE.md        # Package design and dependency graph
│   ├── ROADMAP.md             # Live phase status
│   ├── specs/                 # Equation specifications (cross-link with code)
│   ├── certification/         # DO-178C reference artifacts (SRS/SDS/RTM/...)
│   └── history/               # Archived earlier governance/persona/skeleton docs
└── alire.toml                 # Alire crate manifest
```

The Ada code under `ada/src/` is the only general implementation. The Python module under `python/three-body-extension/` is a **validation oracle**: `validation/generate_reference.py` uses its CR3BP, Lagrange, and stability routines to generate the committed CSV reference data under `validation/data/`, which the Ada oracle test suite parses and compares against. There is no parallel Python primary implementation; an earlier skeleton is archived in `docs/history/python-skeleton/`.

## Status

| Package | Status |
|---------|--------|
| `Hale_Orbital.Types`, `Constants`, `Vectors`, `Matrices` | Implemented |
| `TwoBody`, `Elements`, `Kepler`, `Lambert`, `Maneuvers` | Implemented |
| `Propagation` — RK4, DP5(4), RKF7(8), J2, parallel ensembles | Implemented |
| `Threebody` (CR3BP) — Lagrange + Jacobi + EOM + RK4/RKF4(5) + Floquet | Implemented |
| `Threebody` — manifolds, family tooling beyond Lyapunov/Halo basics | Partial |
| `Time`, `Frames`, `Ephemerides`, `Gravity`, `Atmosphere`, `SRP`, `Forces`, `Estimation`, `Uncertainty`, `Optimization`, `TLE_SGP4`, `Mission` | Planned (see `docs/ROADMAP.md`) |

See [docs/ROADMAP.md](docs/ROADMAP.md) for live phase tracking and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the target package tree.

## Build & Test

```bash
# Toolchain option A — Alire-managed GNAT:
alr toolchain --select gnat_native gprbuild
alr build                                  # library, BUILD_MODE=debug|release

# Toolchain option B — Ubuntu archive (used by CI's compile gates and by
# .claude/setup.sh as a fallback):
apt-get install gnat-14 gprbuild

# Tests (two runners; both propagate failures via exit status):
gprbuild -P ada/tests/hale_tests.gpr -p
./ada/bin/run_tests          # compact suite (~65 tests)
./ada/bin/run_all_tests      # full estate (all Hale_Tests.* suites)

# Examples (all seven build; CI compile-gates them):
gprbuild -P ada/examples/hale_examples.gpr -p

# Python oracle tests:
cd python/three-body-extension && python3 -m pytest

# Cross-validation reference data (regenerate + check):
python3 validation/generate_reference.py            # writes validation/data/*.csv
python3 validation/generate_reference.py --check    # numeric drift gate (used in CI)

# SPARK proofs / MC/DC coverage — require AdaCore tooling (gnatprove /
# gnatcov) that is NOT available in CI or the default containers; these
# commands are the intended invocation once that tooling is provisioned:
gnatprove -P ada/hale_orbital.gpr --level=2 --mode=all
scripts/merge_coverage.sh
```

On a fresh remote-execution container, the Claude Code `SessionStart` hook in [`.claude/settings.json`](.claude/settings.json) bootstraps the toolchain via [`.claude/setup.sh`](.claude/setup.sh) (Alire first, Ubuntu-archive GNAT as fallback).

## Design Principles

1. **Dimensional types are not optional.** Position, velocity, time, angle, mass, GM, energy, and momentum are derived `Real` subtypes — mixing them is a compile-time error. (This catches swapped quantities; it is not full dimensional analysis.)
2. **Contracts are the public surface.** Public subprograms declare `Pre`/`Post`; bodies live in `SPARK_Mode => Off` only where they reach for non-SPARK primitives (e.g. `Ada.Numerics.Generic_Elementary_Functions`).
3. **Reference oracles, not invention.** Numerical claims are checked against published oracles: Hale examples, Vallado test cases, the analytic Kepler propagator, and the Python three-body extension via the CSV pipeline.
4. **Fail loudly.** Iterative solvers use bounded iteration and report non-convergence explicitly (`Converged`/`Valid` flags or exceptions at the API edge); guarded denominators, not silent NaN.
5. **No heap allocation in computational paths.** Stack and static storage only.

## References

- Hale, F. J. (1994). *Introduction to Space Flight*. Prentice Hall.
- Vallado, D. A. (2013). *Fundamentals of Astrodynamics and Applications*, 4ᵗʰ ed. Microcosm Press.
- Battin, R. H. (1999). *An Introduction to the Mathematics and Methods of Astrodynamics*. AIAA.
- Fehlberg, E. (1968). *Classical Fifth-, Sixth-, Seventh-, and Eighth-Order Runge-Kutta Formulas with Stepsize Control.* NASA TR R-287.
- Dormand, J. R., Prince, P. J. (1980). *A family of embedded Runge-Kutta formulae.* J. Comp. Appl. Math. 6(1).
- Izzo, D. (2014). *Revisiting Lambert's Problem.* CMDA 121:1–15. *(planned algorithm upgrade — not the implemented method)*
- Brosgol, B. (2019). *Safety and Security: Certification Issues and Technologies.* DO-178C reference.

## License

Apache-2.0 (see [LICENSE](LICENSE)).
