# Test-to-Requirement Traceability Matrix

**Document Version:** 1.1
**Created:** 2026-01-06
**Last Updated:** 2026-07-13 (requirement IDs validated against SRS.md v2.0 canonical scheme)
**DO-178C Reference:** A-6.4 Test-to-Requirement Traceability
**Status:** Phase 3 - Test Completeness

---

## Overview

This document provides bidirectional traceability between test procedures and requirements for the HALE Orbital Mechanics Library. It ensures that:

1. Every high-level requirement has at least one test
2. Every test traces to at least one requirement
3. Coverage gaps are identified and resolved

---

## Test Suite Summary

Test counts are the number of executed assertions in each package. Status
semantics: suites wired into `run_all_tests` (built and executed by the CI
`build-and-test` job) are marked **Implemented; CI-executed**; suites reachable
only through `test_driver_coverage` are compiled by the CI `compile-gates` job
but executed only locally, and are marked **Implemented; compile-gated in CI,
run via coverage driver locally**.

| Test Package | Test Count | Requirements Covered | Status |
|--------------|------------|---------------------|--------|
| hale_tests-vallado | 28 | HLR-1A-001, HLR-1A-004, HLR-1A-005, HLR-1A-025, HLR-2A-001, HLR-2A-005, HLR-2C-001, HLR-2C-003 | Implemented; CI-executed |
| hale_tests-edge_cases | 92 | HLR-1A-*, HLR-1B-001/002, HLR-1C-*, HLR-1D-*, HLR-2A-001/002/003/005, HLR-2B-001 to HLR-2B-006, HLR-2C-001/002/003/004, HLR-3A-* | Implemented; CI-executed |
| hale_tests-determinism | 22 | NFR-DET-001, NFR-DET-002 | Implemented; CI-executed |
| hale_tests-parallel | 11 | NFR-THR-001, NFR-THR-002, HLR-2B-015 | Implemented; CI-executed |
| hale_tests-integration | 48 | HLR-2B-007 to HLR-2B-013, HLR-2D-001/002/003/004/006, HLR-1A-011/012, HLR-3B-002, NFR-ACC-003/004/005 | Implemented; CI-executed |
| hale_tests-lambert_multirev | 53 | HLR-2A-002, HLR-2B-016 to HLR-2B-020 | Implemented; CI-executed |
| hale_tests-periodic_orbits | 26 | HLR-3B-033 to HLR-3B-046, NFR-ACC-006 | Implemented; CI-executed |
| hale_tests-negative | 30 | NFR-ROB-001, NFR-ROB-002 | Implemented; compile-gated in CI, run via coverage driver locally |
| hale_tests-exceptions | 24 | NFR-ERR-001 to NFR-ERR-006, HLR-1A-016/020 | Implemented; compile-gated in CI, run via coverage driver locally |
| hale_tests-boundaries | 40 | HLR-1A-001/002/004/006/007/008/013/023/024, HLR-1B-001/002/004/005, NFR-ROB-005 to NFR-ROB-008 | Implemented; compile-gated in CI, run via coverage driver locally |

The core suites in `run_tests.adb` / `run_all_tests.adb` (Test_Vectors,
Test_Matrices, Test_Twobody, Test_Elements, Test_Kepler, Test_Maneuvers,
Test_Threebody, Test_Propagation) are also CI-executed; see "Core Functional
Suites" below.

---

## Requirement-to-Test Mapping

### Functional Requirements (HLR-1A: Two-Body Mechanics)

| Requirement ID | Description | Test Procedure | Test File |
|----------------|-------------|----------------|-----------|
| HLR-1A-001 | Kepler equation solver (elliptic) | Test_Kepler_Edge_Cases | edge_cases.adb |
| HLR-1A-001 | Kepler equation solver (elliptic) | Test_Mean_Anomaly_Boundaries | boundaries.adb |
| HLR-1A-002 | Kepler equation solver (hyperbolic) | Test_Just_Hyperbolic_Eccentricity | boundaries.adb |
| HLR-1A-003 | Kepler equation solver (parabolic) | None — gap (no test exercises Solve_Kepler_Parabolic) | — |
| HLR-1A-004 | State-to-elements conversion | Test_Elements_Edge_Cases | edge_cases.adb |
| HLR-1A-005 | Elements-to-state conversion | Test_Elements_Edge_Cases | edge_cases.adb |
| HLR-1A-006 | Circular velocity computation | Test_Twobody_Edge_Cases | edge_cases.adb |
| HLR-1A-006 | Circular velocity computation | Test_LEO_Altitude_Boundary | boundaries.adb |
| HLR-1A-007 | Escape velocity computation | Test_Twobody_Edge_Cases | edge_cases.adb |
| HLR-1A-008 | Orbital period computation | Test_Twobody_Edge_Cases | edge_cases.adb |
| HLR-1A-008 | Orbital period computation | Test_GEO_Radius_Boundary | boundaries.adb |
| HLR-1A-009 | Vis-viva equation | Test_Twobody_Edge_Cases | edge_cases.adb |
| HLR-1A-010 | Specific energy computation | Test_Twobody_Edge_Cases | edge_cases.adb |
| HLR-1A-011 | Angular momentum vector | Test_Conservation_Laws_Integration | integration.adb |
| HLR-1A-012 | Angular momentum magnitude | Test_Invalid_Angular_Momentum | negative.adb |
| HLR-1A-013 | Mean motion | Test_Invalid_SMA | negative.adb |
| HLR-1A-016 | Apoapsis distance | Test_Physical_Error_Paths | exceptions.adb |
| HLR-1A-020 | Universal-variable Kepler solver | Test_Convergence_Error_Paths | exceptions.adb |
| HLR-1A-023 | Circular-orbit singularity handling | Test_Near_Circular_Eccentricity | boundaries.adb |
| HLR-1A-024 | Equatorial-orbit singularity handling | Test_Near_Equatorial_Prograde | boundaries.adb |
| HLR-1A-025 | Independent reference validation (Vallado) | Run_All_Vallado_Tests | vallado.adb |

### Functional Requirements (HLR-1B: Anomaly Conversions)

| Requirement ID | Description | Test Procedure | Test File |
|----------------|-------------|----------------|-----------|
| HLR-1B-001 | True-to-eccentric anomaly | Test_True_Anomaly_Boundaries | boundaries.adb |
| HLR-1B-002 | Eccentric-to-true anomaly | Test_Eccentric_Anomaly_Boundaries | boundaries.adb |
| HLR-1B-003 | True-to-mean anomaly | None — gap (no test exercises True_To_Mean_Anomaly) | — |
| HLR-1B-004 | Mean-to-eccentric anomaly | Test_Mean_Anomaly_Boundaries | boundaries.adb |
| HLR-1B-005 | Hyperbolic anomaly conversions | Test_Just_Hyperbolic_Eccentricity | boundaries.adb |
| HLR-1B-005 | Hyperbolic anomaly conversions | Test_Invalid_Orbit_Paths | exceptions.adb |
| HLR-1B-006 | Eccentric-to-mean anomaly | None — gap (no test exercises Eccentric_To_Mean_Anomaly) | — |

### Functional Requirements (HLR-2A: Lambert Problem)

| Requirement ID | Description | Test Procedure | Test File |
|----------------|-------------|----------------|-----------|
| HLR-2A-001 | Single-revolution Lambert solver (short, 90-degree, and long arcs) | Test_Lambert_Edge_Cases | edge_cases.adb |
| HLR-2A-002 | Multi-revolution Lambert solver | Run_All_Lambert_MultiRev_Tests | lambert_multirev.adb |
| HLR-2A-003 | Degenerate (near-180 degree) transfer detection | Test_Lambert_Edge_Cases | edge_cases.adb |
| HLR-2A-004 | Minimum-energy transfer time | None — gap (no test exercises Minimum_Energy_Tof) | — |
| HLR-2A-005 | Transfer angle computation | Test_Lambert_Edge_Cases | edge_cases.adb |
| HLR-2A-006 | Solution existence check | None — gap (no test exercises Solution_Exists) | — |

### Functional Requirements (HLR-2B: Propagation and Integration)

| Requirement ID | Description | Test Procedure | Test File |
|----------------|-------------|----------------|-----------|
| HLR-2B-001 | RK4 propagation | Test_Propagation_Edge_Cases | edge_cases.adb |
| HLR-2B-002 | RK78 propagation | Test_Propagation_Edge_Cases | edge_cases.adb |
| HLR-2B-003 | Energy conservation | Test_Propagation_Edge_Cases | edge_cases.adb |
| HLR-2B-004 | Backward propagation | Test_Propagation_Edge_Cases | edge_cases.adb |
| HLR-2B-005 | Zero-duration propagation | Test_Propagation_Edge_Cases | edge_cases.adb |
| HLR-2B-006 | High-eccentricity propagation stability | Test_Propagation_Edge_Cases | edge_cases.adb |
| HLR-2B-007 | Lambert-propagation consistency | Test_Lambert_Propagation_Consistency | integration.adb |
| HLR-2B-008 | Element round-trip consistency | Test_Elements_State_Round_Trip | integration.adb |
| HLR-2B-009 | Maneuver-propagation consistency | Test_Hohmann_Transfer_Propagation | integration.adb |
| HLR-2B-010 | End-to-end mission profile | Test_LEO_GEO_Mission_Profile | integration.adb |
| HLR-2B-011 | CR3BP propagation integration | Test_Threebody_Propagation_Integration | integration.adb |
| HLR-2B-012 | Interplanetary chain integration | Test_Interplanetary_Integration | integration.adb |
| HLR-2B-013 | Conservation laws under propagation | Test_Conservation_Laws_Integration | integration.adb |
| HLR-2B-014 | Analytical Kepler propagation | None — gap (no test exercises Kepler.Propagate) | — |
| HLR-2B-015 | Parallel ensemble propagation | Run_All_Parallel_Tests | parallel.adb |
| HLR-2B-016 | Multi-revolution minimum TOF | Test_Multi_Rev_Min_TOF | lambert_multirev.adb |
| HLR-2B-017 | Multi-revolution solution counting | Test_Multi_Rev_Solution_Counting | lambert_multirev.adb |
| HLR-2B-018 | N-revolution transfer construction | Test_One/Two/Three_Revolution_Transfer, Test_Published_Multi_Rev_Cases | lambert_multirev.adb |
| HLR-2B-019 | Revolution boundary handling | Test_Revolution_Boundary_Cases | lambert_multirev.adb |
| HLR-2B-020 | Energy branch selection | Test_Energy_Branch_Selection | lambert_multirev.adb |

### Functional Requirements (HLR-2C: Maneuvers)

| Requirement ID | Description | Test Procedure | Test File |
|----------------|-------------|----------------|-----------|
| HLR-2C-001 | Hohmann transfer | Test_Maneuvers_Edge_Cases | edge_cases.adb |
| HLR-2C-002 | Bielliptic transfer | Test_Maneuvers_Edge_Cases | edge_cases.adb |
| HLR-2C-003 | Plane change maneuver | Test_Maneuvers_Edge_Cases | edge_cases.adb |
| HLR-2C-004 | Zero-DV transfer (same orbit) | Test_Maneuvers_Edge_Cases | edge_cases.adb |
| HLR-2C-005 | Bielliptic efficiency criterion | Test_Maneuvers (core suite) | run_all_tests.adb |
| HLR-2C-006 | Combined plane change | None — gap (no test exercises Combined_Plane_Change) | — |

### Functional Requirements (HLR-3A: Stumpff Functions)

| Requirement ID | Description | Test Procedure | Test File |
|----------------|-------------|----------------|-----------|
| HLR-3A-001 | Stumpff C(z) at z=0 | Test_Stumpff_Edge_Cases | edge_cases.adb |
| HLR-3A-002 | Stumpff S(z) at z=0 | Test_Stumpff_Edge_Cases | edge_cases.adb |
| HLR-3A-003 | Stumpff functions (z>0, elliptic) | Test_Stumpff_Edge_Cases | edge_cases.adb |
| HLR-3A-004 | Stumpff functions (z<0, hyperbolic) | Test_Stumpff_Edge_Cases | edge_cases.adb |

### Functional Requirements (HLR-3B: Three-Body/Periodic Orbits)

| Requirement ID | Description | Test Procedure | Test File |
|----------------|-------------|----------------|-----------|
| HLR-3B-033 | Lyapunov orbit finding (L1) | Test_Lyapunov_L1_Earth_Moon | periodic_orbits.adb |
| HLR-3B-033 | Lyapunov orbit finding (L2) | Test_Lyapunov_L2_Earth_Moon | periodic_orbits.adb |
| HLR-3B-033 | Lyapunov periodicity verification | Test_Lyapunov_Periodicity | periodic_orbits.adb |
| HLR-3B-034 | Halo orbit finding | Test_Halo_L1_Northern, Test_Halo_L2_Southern | periodic_orbits.adb |
| HLR-3B-035 | Richardson approximation | Test_Richardson_Guess_L1, Test_Richardson_Guess_L2 | periodic_orbits.adb |
| HLR-3B-036 | Halo orbit finding (Northern family) | Test_Halo_L1_Northern | periodic_orbits.adb |
| HLR-3B-037 | Halo orbit finding (Southern family) | Test_Halo_L2_Southern | periodic_orbits.adb |
| HLR-3B-038 | Halo periodicity verification | Test_Halo_Periodicity | periodic_orbits.adb |
| HLR-3B-039 | Richardson approximation (L1) | Test_Richardson_Guess_L1 | periodic_orbits.adb |
| HLR-3B-040 | Richardson approximation (L2) | Test_Richardson_Guess_L2 | periodic_orbits.adb |
| HLR-3B-041 | State transition matrix (identity) | Test_STM_Identity_Initial | periodic_orbits.adb |
| HLR-3B-042 | State transition matrix (propagation) | Test_STM_Propagation | periodic_orbits.adb |
| HLR-3B-043 | STM symplectic property | Test_STM_Symplectic_Property | periodic_orbits.adb |
| HLR-3B-044 | Monodromy matrix computation | Test_Monodromy_Matrix | periodic_orbits.adb |
| HLR-3B-045 | Floquet multipliers | Test_Floquet_Multipliers | periodic_orbits.adb |
| HLR-3B-046 | Orbit family generation | Test_Lyapunov_Family | periodic_orbits.adb |

### Functional Requirements (HLR-2D: Interplanetary Transfer)

| Requirement ID | Description | Test Procedure | Test File |
|----------------|-------------|----------------|-----------|
| HLR-2D-001 | Sphere-of-influence radius | Test_Interplanetary_Integration | integration.adb |
| HLR-2D-002 | Departure characteristic energy (C3) | Test_Interplanetary_Integration | integration.adb |
| HLR-2D-003 | Arrival hyperbolic excess speed | Test_Interplanetary_Integration | integration.adb |
| HLR-2D-004 | Interplanetary Hohmann transfer | Test_Interplanetary_Integration | integration.adb |
| HLR-2D-005 | Flyby turn angle | None — gap (no test exercises Turn_Angle) | — |
| HLR-2D-006 | Flyby delta-V gain | Test_Interplanetary_Integration | integration.adb |

### Functional Requirements (HLR-1C/HLR-1D: Vector and Matrix Operations)

| Requirement ID | Description | Test Procedure | Test File |
|----------------|-------------|----------------|-----------|
| HLR-1C-001 to HLR-1C-006 | Vector add/subtract/dot/cross/magnitude/normalize | Test_Vectors (core suite), Test_Vector_Edge_Cases | run_all_tests.adb, edge_cases.adb |
| HLR-1D-001 to HLR-1D-004 | Matrix multiply/transpose/determinant/rotations | Test_Matrices (core suite), Test_Matrix_Edge_Cases | run_all_tests.adb, edge_cases.adb |

### Core Functional Suites (run_tests.adb / run_all_tests.adb, CI-executed)

| Test Suite | Requirements Traced |
|------------|---------------------|
| Test_Vectors | HLR-1C-001, HLR-1C-003, HLR-1C-004, HLR-1C-005, HLR-1C-006 |
| Test_Matrices | HLR-1D-001, HLR-1D-003, HLR-1D-004 |
| Test_Twobody | HLR-1A-006, HLR-1A-007, HLR-1A-008 |
| Test_Elements | HLR-1A-004, HLR-1A-023, HLR-1A-024 |
| Test_Kepler | HLR-1A-001, HLR-3A-001, HLR-3A-002 |
| Test_Maneuvers | HLR-2C-001, HLR-2C-005 |
| Test_Threebody | HLR-3B-001, HLR-3B-004, HLR-3B-005, HLR-3B-010, HLR-3B-011, HLR-3B-020 |
| Test_Propagation | HLR-2B-001, HLR-2B-002, HLR-2B-003 |

### Non-Functional Requirements (NFR-ROB: Robustness)

| Requirement ID | Description | Test Procedure | Test File |
|----------------|-------------|----------------|-----------|
| NFR-ROB-001 | Invalid eccentricity rejection (input validation) | Test_Invalid_Eccentricity | negative.adb |
| NFR-ROB-001 | Invalid SMA rejection (input validation) | Test_Invalid_SMA | negative.adb |
| NFR-ROB-001 | Invalid radius rejection (input validation) | Test_Invalid_Radius | negative.adb |
| NFR-ROB-001 | Invalid Mu rejection (input validation) | Test_Invalid_Mu | negative.adb |
| NFR-ROB-001 | Invalid angular momentum (input validation) | Test_Invalid_Angular_Momentum | negative.adb |
| NFR-ROB-001 | Invalid TOF handling (input validation) | Test_Invalid_TOF | negative.adb |
| NFR-ROB-001 | Invalid tolerance handling (input validation) | Test_Invalid_Tolerance | negative.adb |
| NFR-ROB-002 | Zero vector handling (division safety) | Test_Zero_Vectors | negative.adb |
| NFR-ROB-003 | Singularity handling (limiting formulas) | Test_Elements_Edge_Cases | edge_cases.adb |
| NFR-ROB-005 | Near-circular orbit robustness | Test_Near_Circular_Eccentricity | boundaries.adb |
| NFR-ROB-006 | Near-equatorial orbit robustness | Test_Near_Equatorial_Prograde, Test_Near_Equatorial_Retrograde | boundaries.adb |
| NFR-ROB-007 | Near-parabolic orbit robustness | Test_Near_Parabolic_Eccentricity | boundaries.adb |
| NFR-ROB-008 | High-eccentricity robustness | Test_Kepler_Edge_Cases | edge_cases.adb |

### Non-Functional Requirements (NFR-ERR: Error Handling)

| Requirement ID | Description | Test Procedure | Test File |
|----------------|-------------|----------------|-----------|
| NFR-ERR-001 | Convergence error paths | Test_Convergence_Error_Paths | exceptions.adb |
| NFR-ERR-002 | Invalid orbit error paths | Test_Invalid_Orbit_Paths | exceptions.adb |
| NFR-ERR-003 | Singularity error paths | Test_Singularity_Error_Paths | exceptions.adb |
| NFR-ERR-004 | Physical error paths | Test_Physical_Error_Paths | exceptions.adb |
| NFR-ERR-005 | Contract violation (constraint error) paths | Test_Constraint_Error_Paths | exceptions.adb |
| NFR-ERR-006 | Exception message quality | Test_Exception_Messages | exceptions.adb |
| NFR-ERR-007 | Non-convergence detection and recovery | Test_Invalid_TOF, Test_Multi_Rev_Min_TOF | negative.adb, lambert_multirev.adb |

### Non-Functional Requirements (NFR-DET: Determinism)

| Requirement ID | Description | Test Procedure | Test File |
|----------------|-------------|----------------|-----------|
| NFR-DET-001 | Reproducibility (deterministic execution, reference values) | Test_Calculation_Repeatability, Test_Against_References | determinism.adb |
| NFR-DET-002 | Ordering independence (summation stability) | Test_Summation_Stability | determinism.adb |

### Non-Functional Requirements (NFR-THR: Thread Safety)

| Requirement ID | Description | Test Procedure | Test File |
|----------------|-------------|----------------|-----------|
| NFR-THR-001 | Reentrancy (parallel execution safety) | Run_All_Parallel_Tests | parallel.adb |
| NFR-THR-002 | No global state (no race conditions) | Run_All_Parallel_Tests | parallel.adb |

---

## Test-to-Requirement Mapping

### hale_tests-negative.adb

| Test Procedure | Requirements Traced |
|----------------|---------------------|
| Test_Invalid_Eccentricity | NFR-ROB-001 |
| Test_Invalid_SMA | NFR-ROB-001, HLR-1A-013 |
| Test_Invalid_Radius | NFR-ROB-001 |
| Test_Invalid_Mu | NFR-ROB-001 |
| Test_Zero_Vectors | NFR-ROB-002 |
| Test_Invalid_TOF | NFR-ROB-001, NFR-ERR-007 |
| Test_Invalid_Tolerance | NFR-ROB-001 |
| Test_Invalid_Angular_Momentum | NFR-ROB-001, HLR-1A-012 |

### hale_tests-exceptions.adb

| Test Procedure | Requirements Traced |
|----------------|---------------------|
| Test_Convergence_Error_Paths | NFR-ERR-001, HLR-1A-020 |
| Test_Invalid_Orbit_Paths | NFR-ERR-002, HLR-1B-005 |
| Test_Physical_Error_Paths | NFR-ERR-004, HLR-1A-016 |
| Test_Singularity_Error_Paths | NFR-ERR-003 |
| Test_Constraint_Error_Paths | NFR-ERR-005 |
| Test_Exception_Messages | NFR-ERR-006 |

### hale_tests-boundaries.adb

| Test Procedure | Requirements Traced |
|----------------|---------------------|
| Test_Near_Circular_Eccentricity | HLR-1A-001, HLR-1A-023, HLR-1B-001, HLR-1B-002, NFR-ROB-005 |
| Test_Near_Parabolic_Eccentricity | HLR-1A-001, HLR-1A-002, NFR-ROB-007 |
| Test_Just_Hyperbolic_Eccentricity | HLR-1A-002, HLR-1B-005 |
| Test_Near_Equatorial_Prograde | HLR-1A-004, HLR-1A-024, NFR-ROB-006 |
| Test_Near_Equatorial_Retrograde | HLR-1A-004, HLR-1A-024, NFR-ROB-006 |
| Test_True_Anomaly_Boundaries | HLR-1B-001, HLR-1B-002 |
| Test_Mean_Anomaly_Boundaries | HLR-1A-001, HLR-1B-004 |
| Test_Eccentric_Anomaly_Boundaries | HLR-1B-001, HLR-1B-002 |
| Test_LEO_Altitude_Boundary | HLR-1A-006, HLR-1A-007, HLR-1A-008 |
| Test_GEO_Radius_Boundary | HLR-1A-006, HLR-1A-008, HLR-1A-013 |

### hale_tests-periodic_orbits.adb

| Test Procedure | Requirements Traced |
|----------------|---------------------|
| Test_STM_Identity_Initial | HLR-3B-041 |
| Test_STM_Propagation | HLR-3B-042 |
| Test_STM_Symplectic_Property | HLR-3B-043 |
| Test_Monodromy_Matrix | HLR-3B-044 |
| Test_Monodromy_Determinant | HLR-3B-044 |
| Test_Floquet_Multipliers | HLR-3B-045 |
| Test_Floquet_Reciprocal_Pairs | HLR-3B-045 |
| Test_Lyapunov_L1_Earth_Moon | HLR-3B-033 |
| Test_Lyapunov_L2_Earth_Moon | HLR-3B-033 |
| Test_Lyapunov_Periodicity | HLR-3B-033 |
| Test_Richardson_Guess_L1 | HLR-3B-035, HLR-3B-039 |
| Test_Richardson_Guess_L2 | HLR-3B-035, HLR-3B-040 |
| Test_Halo_L1_Northern | HLR-3B-034, HLR-3B-036 |
| Test_Halo_L2_Southern | HLR-3B-034, HLR-3B-037 |
| Test_Halo_Periodicity | HLR-3B-038 |
| Test_Lyapunov_Family | HLR-3B-046 |
| Test_Periodic_Orbit_Jacobi_Conservation | HLR-3B-020, HLR-3B-033 to HLR-3B-038 |

---

## Coverage Analysis

Totals are the canonical requirement counts defined in SRS.md v2.0
(106 HLR + 38 NFR).

### Requirements with Test Coverage

| Category | Total Requirements | Covered | Coverage % |
|----------|-------------------|---------|------------|
| HLR-1A (Two-Body) | 25 | 17 | 68% |
| HLR-1B (Anomaly) | 6 | 4 | 67% |
| HLR-1C (Vectors) | 6 | 6 | 100% |
| HLR-1D (Matrices) | 4 | 4 | 100% |
| HLR-2A (Lambert) | 6 | 4 | 67% |
| HLR-2B (Propagation/Integration) | 20 | 19 | 95% |
| HLR-2C (Maneuvers) | 6 | 5 | 83% |
| HLR-2D (Interplanetary) | 6 | 5 | 83% |
| HLR-3A (Stumpff) | 4 | 4 | 100% |
| HLR-3B (Three-Body) | 23 | 21 | 91% |
| NFR-ROB (Robustness) | 9 | 7 | 78% |
| NFR-ERR (Error Handling) | 8 | 7 | 88% |
| NFR-DET (Determinism) | 2 | 2 | 100% |
| NFR-THR (Thread Safety) | 2 | 2 | 100% |
| NFR-PERF (Performance) | 6 | 2 | 33% |
| NFR-ACC (Accuracy) | 6 | 6 | 100% |
| NFR-PORT (Portability) | 5 | 0 | N/A (verified by build/CI configuration, not test) |
| **TOTAL** | **144** | **115** | **80%** |

### Gap Analysis

The following canonical requirements currently have **no test coverage**:

- **HLR-1A-003** (parabolic Kepler solver), **HLR-1A-014** (semi-latus rectum),
  **HLR-1A-015** (periapsis distance), **HLR-1A-017** (radius at true anomaly),
  **HLR-1A-018/019** (eccentricity vector/magnitude), **HLR-1A-021/022**
  (elliptic/hyperbolic time of flight)
- **HLR-1B-003** (true-to-mean anomaly), **HLR-1B-006** (eccentric-to-mean anomaly)
- **HLR-2A-004** (minimum-energy TOF), **HLR-2A-006** (solution existence check)
- **HLR-2B-014** (analytical Kepler propagation)
- **HLR-2C-006** (combined plane change)
- **HLR-2D-005** (flyby turn angle)
- **HLR-3B-003** (L3 position), **HLR-3B-021** (zero-velocity surface check)
- **NFR-ROB-004** (NaN/Inf propagation), **NFR-ROB-009** (numerical clamping —
  verified by code review only)
- **NFR-ERR-008** (overflow detection — compiler-level, no dedicated test)
- **NFR-PERF-003..006** (timing/scaling targets — benchmark program exists in
  `ada/examples` but is not executed in CI)

NFR-PORT-001..005 are verified by build/CI configuration and review rather
than by test procedures.

---

## Appendix A: Test File Locations

| File | Path | Description |
|------|------|-------------|
| hale_tests.ads | ada/tests/ | Test framework root package |
| hale_tests-runner.ads/adb | ada/tests/ | Test execution framework |
| hale_tests-vallado.ads/adb | ada/tests/ | Vallado reference tests |
| hale_tests-edge_cases.ads/adb | ada/tests/ | Edge case tests |
| hale_tests-determinism.ads/adb | ada/tests/ | Determinism tests |
| hale_tests-parallel.ads/adb | ada/tests/ | Parallel execution tests |
| hale_tests-integration.ads/adb | ada/tests/ | Integration tests |
| hale_tests-lambert_multirev.ads/adb | ada/tests/ | Multi-rev Lambert tests |
| hale_tests-periodic_orbits.ads/adb | ada/tests/ | Periodic orbit tests |
| hale_tests-negative.ads/adb | ada/tests/ | Negative (invalid input) tests |
| hale_tests-exceptions.ads/adb | ada/tests/ | Exception path tests |
| hale_tests-boundaries.ads/adb | ada/tests/ | Boundary condition tests |
| run_tests.adb | ada/tests/ | Legacy core-suite driver (CI-executed) |
| run_all_tests.adb | ada/tests/ | Full-suite driver: core suites + edge_cases, vallado, lambert_multirev, determinism, integration, parallel, periodic_orbits (CI-executed) |
| test_driver_coverage.adb | ada/tests/ | Coverage driver: vallado, edge_cases, negative, exceptions, boundaries, periodic_orbits (compile-gated in CI; run locally) |

---

*Document Version: 1.1*
*Last Updated: 2026-07-13*
*Prepared for: DO-178C Level C Certification*
