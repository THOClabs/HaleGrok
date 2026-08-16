# Roadmap

Live phase status. The full plan and rationale live in the master plan file (not committed); this roadmap is the operational tracker.

Each phase is a milestone PR (or small series). Subsequent phases assume predecessors merged.

## Phase 0 — Foundation `[in progress]`

- [x] Doc truth pass: rewrite README, replace stale plans with `ARCHITECTURE.md` + `ROADMAP.md`, archive personas/governance/python-skeleton to `docs/history/`.
- [x] Finish the one real stub: `Time_Of_Flight_Parabolic` (Barker's equation) in `Hale_Orbital.Kepler`.
- [x] `with SPARK_Mode => On` baseline + minimum contracts on `TwoBody`, `Elements`, `Lambert`, `Maneuvers`.
- [x] Alire manifest (`alire.toml`) and GPRbuild profile cleanup.
- [x] Container bootstrap: `.claude/settings.json` SessionStart hook + `.claude/setup.sh` installs Alire, GNAT, GNATprove.
- [x] GitHub Actions CI workflow scaffold.
- [ ] AUnit test framework migration (placeholder until toolchain available in CI).
- [ ] Cross-validation harness skeleton under `validation/` (placeholder).
- [ ] Specs 05/06/07 (`docs/specs/`) — Lambert, maneuvers, interplanetary — reflecting the implemented API.

## Phase 1 — Time & Frames `[planned]`

- `Hale_Orbital.Time`: TAI/UTC/UT1/TT/TDB/GPS, leap seconds, EOP, JD↔calendar.
- `Hale_Orbital.Frames`: IAU 2006/2000A precession-nutation (CIO-based); GCRF/ICRF/EME2000/MOD/TOD/TEME/ITRF; polar motion; GMST/GAST/ERA.
- Cross-validate against IAU SOFA test vectors to ≤ 1e-12 rad / 1 μs.

## Phase 2 — Ephemerides `[planned]`

- `Hale_Orbital.Ephemerides`: JPL SPK type 2/3 (Chebyshev) reader, DE440.
- Light-time iteration.
- Validate vs JPL Horizons to ≤ 1 m / 1 mm/s.

## Phase 3 — Gravity Models `[planned]`

- `Hale_Orbital.Gravity`: Pines-formulation spherical harmonics (pole-singularity-free), EGM2008 truncated to degree 70 by default, generalisable to 2190.
- J2-only fast path with `pragma Inline_Always`.
- Validate vs Orekit acceleration CSV to ≤ 1e-10 relative.

## Phase 4 — Atmosphere, Drag, SRP, Third-Body `[planned]`

- `Atmosphere` (NRLMSISE-00 + Harris-Priester); drag; `SRP` (cannonball + box-wing, dual-cone shadow).
- Third-body via `Ephemerides`.
- `Forces.Force_Model'Class` composable additive interface.

## Phase 5 — Propagators `[planned]`

- RK4, RK7(8) Dormand-Prince adaptive with dense output, Gauss-Jackson 8th-order multistep, Gauss-Radau IAS15-style, Yoshida symplectic, Kustaanheimo-Stiefel regularisation.
- Cowell / Encke / VOP formulations.
- Event detection (root-find + Hermite interpolation), STM/variational equations.
- Energy & angular-momentum conservation regression: < 1e-12 / 100 LEO orbits with RK7(8); < 1e-14 with IAS15.

## Phase 6 — Lambert & Trajectory Tools `[planned]`

- Replace Battin body with Izzo's universal vercosine; add Gooding fallback and Russell second-order sensitivities.
- Porkchop generator, B-plane targeting, patched conics, gravity-assist geometry.

## Phase 7 — Three-Body Completion `[planned]`

- Multiple-shooting differential corrector.
- Lyapunov / Halo / NRHO / Lissajous families with pseudo-arclength continuation.
- Monodromy + Floquet stability, stable/unstable manifolds, Poincaré sections.
- Low-energy Earth-Moon ballistic-capture transfer demo.
- Cross-validate vs `python/three-body-extension/` outputs.

## Phase 8 — Estimation, Uncertainty, Conjunction `[planned]`

- Batch LSQ, EKF, UKF, CKF, Square-Root UKF.
- Range / Doppler / optical / GNSS measurement models.
- STM and sigma-point covariance propagation.
- Conjunction (Foster/Akella, Chan), Pc, B-plane mapping.

## Phase 9 — Optimization & Low-Thrust `[planned]`

- Sims-Flanagan, direct collocation (Hermite-Simpson, Radau pseudospectral), indirect (Pontryagin, single + multiple shooting), primer vector.
- Ipopt binding via C interface for the direct methods.
- TLE/SGP4 (Vallado reference).

## Phase 10 — SPARK Verification Push `[planned]`

- `Hale_Orbital.Verification.Lemmas` — orbital-mechanics lemma library.
- GNATprove silver across the codebase.
- Gold on Kepler convergence, Stumpff series bound, vis-viva monotonicity, vector magnitude/normalize, RK4 local-error order.
- Platinum experiment on at least one closed-form routine.
- gnatcov MC/DC ≥ 100 % on core packages.
- DO-178C-aligned traceability matrix.

## Phase 11 — Mission Examples & Polish `[planned]`

- Earth-Mars porkchop, Apollo TLI, JWST L2 halo, Artemis Gateway NRHO, Starlink station-keep, conjunction screening, simulated DSN OD.
- Final user guide, SPARK proof guide, mission examples doc, certification traceability doc.
- Alire crate publication.

## Definition of Done (overall)

1. All packages exist, compile clean with `-gnatwe`, AUnit test suite green.
2. GNATprove silver clean; gold proofs land for the kernels listed in Phase 10; ≥ 1 platinum experiment merged.
3. gnatcov MC/DC ≥ 100 % on core packages.
4. Energy/angular-momentum conservation regression: < 1e-12 over 100 LEO orbits with RK7(8) two-body; < 1e-14 with IAS15.
5. Each Phase 11 mission example runs to completion and produces a CSV trajectory plus a 1-page Markdown analysis under `docs/missions/`.
6. README, ARCHITECTURE, ROADMAP, SPARK_PROOF_GUIDE, USER_GUIDE, MISSION_EXAMPLES, CERTIFICATION_TRACEABILITY all present and cross-linked.
7. CI: every PR runs build + tests + flow + silver proof + coverage + cross-validation; nightly: gold proofs + performance regression.
8. Alire crate `hale_orbital` published to the community index.
