# Architecture

This document describes the package structure of `Hale_Orbital`, the design principles every package follows, and the dependency graph between packages.

## Package Tree

Implemented packages are shown unmarked. Partial implementations are marked **(partial)**. Planned packages are marked **(planned)**.

```
Hale_Orbital
├── Types               -- dimensional types, exceptions, state-vector/elements records
├── Constants           -- physical constants (Hale Appendix B; will add IAU/IERS/DE440)
├── Numerics (planned)  -- robust root finding, eigendecomp, AD, compensated summation
├── Vectors             -- 3D vector ops with SPARK contracts (Magnitude, Cross, Rotate_*)
├── Matrices            -- 3×3 + 6×6 ops, rotations, Perifocal↔Inertial
├── Time (planned)      -- TAI/UTC/UT1/TT/TDB/GPS scales, EOP ingest, JD↔calendar
├── Frames (planned)    -- IAU 2006/2000A precession-nutation, GCRF/MOD/TOD/TEME/ITRF
├── Ephemerides (planned)  -- JPL SPK Chebyshev reader, body states, light-time
├── Gravity (planned)   -- Pines-formulation spherical harmonics, EGM2008/JGM-3/EGM96
├── Atmosphere (planned)   -- NRLMSISE-00, Harris-Priester, Jacchia-Bowman
├── SRP (planned)       -- Cannonball + box-wing, dual-cone shadow
├── Forces (planned)    -- Composable Force_Model'Class (J2, NBody, Drag, SRP, Relativistic)
├── TwoBody             -- vis-viva, energy, angular momentum, eccentricity vector
├── Elements            -- state ↔ classical, anomaly conversions, singularity handling
├── Kepler              -- Newton/Laguerre solvers, Stumpff, universal variable, ToF
├── Lambert             -- transfer solver (Battin today; Izzo planned in Phase 6)
├── Maneuvers           -- Hohmann, bi-elliptic, plane change, phasing, escape/capture
├── Propagators (planned)  -- RK4, RK7(8), Gauss-Jackson, IAS15, symplectic, KS
├── TLE_SGP4 (planned)  -- Vallado reference SGP4/SDP4
├── Estimation (planned)   -- batch LSQ, EKF, UKF, CKF, SR-UKF
├── Uncertainty (planned)  -- Monte-Carlo, conjunction (Foster/Akella), Pc
├── Optimization (planned) -- porkchop, B-plane, low-thrust (Sims-Flanagan, collocation, indirect)
├── Threebody           -- CR3BP, all 5 Lagrange points, Jacobi, pseudo-potential, RK4 propagation
│   ├── Corrector (planned)
│   ├── Continuation (planned)
│   ├── Manifolds (planned)
│   ├── Poincare (planned)
│   └── Transfers (planned)
├── IO (planned)        -- CSV, CCSDS OEM/OPM/OMM, SP3, SPK ingest
├── Validation (planned)   -- cross-validation harness driver
├── Verification (planned) -- SPARK lemma library
└── Mission (planned)   -- end-to-end mission demos
```

## Dependency Graph

```
Types  ←  everything
Constants  ←  TwoBody, Maneuvers, Threebody, Ephemerides, Gravity, …
Vectors, Matrices  ←  TwoBody, Elements, Lambert, Frames, Propagators, …
TwoBody  ←  Elements, Maneuvers, Propagators, Estimation
Elements  ←  Lambert, Maneuvers, Mission examples
Kepler  ←  Lambert, Propagators (universal variable shares Stumpff)
Time  ←  Frames, Ephemerides, Estimation, Mission
Frames  ←  Ephemerides, Estimation, Mission
Ephemerides  ←  Forces (third-body), Mission
Gravity, Atmosphere, SRP  ←  Forces
Forces  ←  Propagators
Propagators  ←  Optimization, Estimation, Mission
Threebody  ←  Threebody.* sub-packages, Mission
Estimation  ←  Uncertainty, Mission
Optimization  ←  Mission
Validation, Verification  ←  every package (orthogonal cross-cutting)
```

## Design Principles

1. **Dimensional types are derived (not subtypes).** `type Distance_Km is new Real;` etc. so the compiler rejects `Distance_Km + Velocity_Km_S`. See `ada/src/hale_orbital-types.ads` lines 32–54.
2. **`with SPARK_Mode => On` on every package spec.** Bodies switch `SPARK_Mode => Off` only where they reach for non-SPARK constructs (`Ada.Numerics.Generic_Elementary_Functions`, foreign-language bindings). The spec surface is contract-based; the body proves what it can.
3. **`Pre` / `Post` / `Contract_Cases` on every public subprogram.** Postconditions express the algebraic invariant where reasonable (e.g. rotation matrices: orthonormality; Kepler solvers: residual < tolerance).
4. **Status returns inside SPARK regions, exceptions only at the user-facing wrapper.** Iterative solvers carry a `Status : out Solver_Status` parameter; the public wrapper raises `Convergence_Error`.
5. **No heap in computational paths.** Stack and static storage only; `Ada.Containers` confined to the user-facing edge.
6. **Cross-validate, don't claim.** Every algorithm's correctness is gated by an oracle CSV under `validation/oracles/`.

## SPARK Verification Tiers

| Tier | Goal | Targets |
|------|------|---------|
| Silver | Absence of runtime errors (AoRTE); flow analysis clean | Every package |
| Gold | Functional postconditions proved | Kepler convergence, Stumpff series bound, vis-viva monotonicity, vector magnitude/normalize, RK4 local error order |
| Platinum | Tight floating-point ULP-aware bound proofs via Why3/nonlinear-real provers | At least one closed-form routine (`Circular_Velocity`, `Escape_Velocity`) per Springer-2022 auto-active method |

## Build & Toolchain

- **Alire** (`alr`) — toolchain selection and dependency management. Crate manifest: `alire.toml`.
- **GPRbuild** — primary build driver via `hale_orbital.gpr`. Library build: static archive `lib/libhale_orbital.a`.
- **Build modes:** `debug` (`-O0 -g -gnato -fstack-check`) and `release` (`-O3 -gnatn2 -gnatp`); SPARK build switches a third `prove` mode that enables full assertion policy.
- **GNATprove** — SPARK proof checker; `--level=2 --mode=all` baseline in CI.
- **gnatcov** — instrumented coverage (statement + decision + MC/DC) on core packages.
- **gnatpp** — formatter; `--check` in CI.

## Numerical Conventions

- **Base type:** `type Real is new Long_Float` (IEEE 754 double).
- **Length units:** kilometres internally.
- **Time units:** seconds internally; Julian Date as `Long_Float` days for astronomical epochs (TDB / TT).
- **Angle units:** radians internally; degrees only at the API edge.
- **Frame default:** GCRF (Earth-centred inertial) for spacecraft; ICRF/barycentric for solar-system bodies.
- **Tolerance defaults:** `1.0e-12` for iterative solvers; `Default_Max_Iterations = 50`.
- **Compensated summation:** Kahan summation in any series accumulation (Stumpff, spherical-harmonics, Chebyshev).

## Reference Data Layout (`data/`)

| Path | Contents | Source / Licence |
|------|----------|------------------|
| `data/eop/eopc04_IAU2000.62-now` | IERS C04 Earth Orientation Parameters | IERS (public) |
| `data/gravity/egm2008_truncated.tab` | EGM2008 coefficients, truncated to selected n×m | NGA (public) |
| `data/spk/de440.bsp` *or* `data/de440/*` | JPL DE440 ephemeris | NASA JPL (public) |
| `data/atmosphere/nrlmsise00.tab` | NRLMSISE-00 coefficient tables | US NRL (public domain) |
| `data/sofa/test_vectors.csv` | IAU SOFA test vectors | IAU SOFA (BSD-style) |
| `data/leapseconds.tab` | Leap-second history | IERS Bulletin C |

A `data/NOTICE` file records each source and licence.

## Cross-Validation Oracle Layout (`validation/oracles/`)

| Path | Contents |
|------|----------|
| `sofa/*.csv` | IAU SOFA reference time/frame conversions |
| `horizons/*.csv` | JPL Horizons body-state queries |
| `orekit/forces_*.csv` | Orekit precomputed accelerations |
| `orekit/propagation_*.csv` | Orekit reference trajectories |
| `vallado/*.csv` | Vallado textbook test cases |
| `python_three_body/*.csv` | Python three-body extension reference outputs |

Each Ada AUnit test compares against the appropriate CSV oracle with a documented tolerance.

## Out of Scope

- Mobile / embedded targets — code is portable but tested only on Linux x86-64.
- GUI / web visualisation — examples emit CSV; plotting via external `gnuplot` / `matplotlib`.
- Real-time / Ravenscar profile beyond what the SPARK kernel naturally satisfies.
- Operational TLE catalogue ingest at scale (SGP4 implementation is provided; catalogue management is not).
