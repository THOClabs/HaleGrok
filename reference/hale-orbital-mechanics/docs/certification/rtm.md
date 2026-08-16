# Requirements Traceability Matrix

## HALE Orbital Mechanics Library - RTM

**Document Version**: 2.0
**Last Updated**: 2026-07-13 (requirement-ID unification onto the canonical SRS scheme)
**Classification**: Certification Evidence

---

## 1. Overview

This Requirements Traceability Matrix (RTM) provides bidirectional traceability between:
- **High-Level Requirements (HLR)**: Derived from Hale textbook equations and orbital mechanics principles
- **Low-Level Requirements (LLR)**: Implemented as Ada function contracts (Pre/Post conditions)
- **Source Code**: Package implementations
- **Verification**: Test procedures and SPARK proofs

---

## 2. Requirement Identification Scheme

Requirement IDs use the canonical level-based scheme defined in `SRS.md`
Section 1.4 (HLR-1A through HLR-3B, NFR-*). Every row below carries the
canonical ID in the **Req ID** column; the **Legacy ID** column preserves the
domain-prefixed ID used by earlier revisions of this document.

| Canonical Prefix | Domain | Legacy Prefix (retired) | Source |
|------------------|--------|-------------------------|--------|
| HLR-1A | Two-body mechanics (incl. Kepler solvers, TOF) | HLR-TB, HLR-KE (partial), HLR-OE (partial) | Hale Ch. 2-4 |
| HLR-1B | Anomaly conversions | HLR-OE (partial) | Hale Ch. 4 |
| HLR-1C | Vector operations | HLR-VEC | Foundation |
| HLR-1D | Matrix operations | HLR-MAT | Foundation |
| HLR-2A | Lambert problem | HLR-LB | Hale Ch. 5 |
| HLR-2B | Propagation / integration / multi-rev transfers | HLR-KE (partial) | Derived |
| HLR-2C | Orbital maneuvers | HLR-MN | Hale Ch. 6 |
| HLR-2D | Interplanetary transfer | HLR-IP | Hale Ch. 7-8 |
| HLR-3A | Stumpff functions | HLR-KE (partial) | Battin 4.4 |
| HLR-3B | Three-body dynamics | HLR-3B (renumbered: 030→042, 031→044, 032→045, 035→046) | CR3BP theory |

---

## 3. Two-Body Dynamics (Hale Chapters 2-3)

### 3.1 Energy and Momentum Requirements

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-1A-010 | HLR-TB-001 | Compute specific orbital energy from state vectors | Eq. 2.14 | `Twobody.Specific_Energy` | Pre: valid vectors | `Test_Twobody` |
| HLR-1A-010 | HLR-TB-002 | Compute specific orbital energy from SMA | Eq. 2.15 | `Twobody.Specific_Energy` | Pre: a > 0 | `Test_Twobody` |
| HLR-1A-011 | HLR-TB-003 | Compute angular momentum vector | Eq. 2.28 | `Twobody.Angular_Momentum_Vector` | Post: h = r × v | `Integration` |
| HLR-1A-012 | HLR-TB-004 | Compute angular momentum magnitude | Eq. 2.29 | `Twobody.Angular_Momentum` | Post: h >= 0 | `Integration`, `Negative` |

### 3.2 Vis-Viva Equation Requirements

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-1A-009 | HLR-TB-010 | Compute velocity at radius from vis-viva | Eq. 2.19 | `Twobody.Vis_Viva` | Pre: r > 0, a > 0 | `Test_Twobody` |
| HLR-1A-006 | HLR-TB-011 | Compute circular orbit velocity | Derived | `Twobody.Circular_Velocity` | Post: v = sqrt(mu/r) | `Test_Twobody` |
| HLR-1A-007 | HLR-TB-012 | Compute escape velocity | Derived | `Twobody.Escape_Velocity` | Post: v = sqrt(2) * v_circ | `Test_Twobody` |

### 3.3 Orbital Period Requirements

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-1A-008 | HLR-TB-020 | Compute orbital period | Eq. 2.24 | `Twobody.Orbital_Period` | Pre: a > 0, e < 1 | `Test_Twobody` |
| HLR-1A-013 | HLR-TB-021 | Compute mean motion | Eq. 2.25 | `Twobody.Mean_Motion` | Post: n > 0 | `Boundaries`, `Negative` |

### 3.4 Conic Section Requirements

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-1A-014 | HLR-TB-030 | Compute semi-latus rectum | Eq. 3.5 | `Twobody.Semi_Latus_Rectum` | Pre: a > 0 | None (gap; see test-rtm.md) |
| HLR-1A-015 | HLR-TB-031 | Compute periapsis distance | Eq. 3.7 | `Twobody.Periapsis_Distance` | Post: r_p > 0 | None (gap; see test-rtm.md) |
| HLR-1A-016 | HLR-TB-032 | Compute apoapsis distance | Eq. 3.8 | `Twobody.Apoapsis_Distance` | Pre: e < 1 | `Exceptions` |
| HLR-1A-017 | HLR-TB-033 | Compute radius from true anomaly | Eq. 3.4 | `Twobody.Radius_At_True_Anomaly` | Pre: 1+e*cos(nu) > 0 | None (gap; see test-rtm.md) |

### 3.5 Eccentricity Vector Requirements

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-1A-018 | HLR-TB-040 | Compute eccentricity vector | Eq. 3.12 | `Twobody.Eccentricity_Vector` | Post: |e| = e | None (gap; see test-rtm.md) |
| HLR-1A-019 | HLR-TB-041 | Compute eccentricity magnitude | Derived | `Twobody.Eccentricity` | Post: e >= 0 | None (gap; see test-rtm.md) |

---

## 4. Orbital Elements (Hale Chapter 4)

### 4.1 State-Elements Conversion

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-1A-004 | HLR-OE-001 | Convert state to classical elements | Ch. 4 | `Elements.State_To_Elements` | Post: valid elements | `Test_Elements` |
| HLR-1A-005 | HLR-OE-002 | Convert elements to state | Ch. 4 | `Elements.Elements_To_State` | Pre: valid elements | `Test_Elements` |
| HLR-1A-023 | HLR-OE-003 | Handle circular orbit singularity | Note | `Elements.State_To_Elements` | e=0: ω undefined | `Edge_Cases` |
| HLR-1A-024 | HLR-OE-004 | Handle equatorial orbit singularity | Note | `Elements.State_To_Elements` | i=0: Ω undefined | `Edge_Cases` |

### 4.2 Anomaly Conversions

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-1B-001 | HLR-OE-010 | True to eccentric anomaly | Eq. 4.23 | `Elements.True_To_Eccentric_Anomaly` | Pre: e < 1 | `Test_Elements` |
| HLR-1B-002 | HLR-OE-011 | Eccentric to true anomaly | Eq. 4.22 | `Elements.Eccentric_To_True_Anomaly` | Pre: e < 1 | `Test_Elements` |
| HLR-1B-006 | HLR-OE-012 | Eccentric to mean anomaly | Eq. 4.20 | `Elements.Eccentric_To_Mean_Anomaly` | Kepler's eq | None (gap; see test-rtm.md) |
| HLR-1B-005 | HLR-OE-013 | True to hyperbolic anomaly | Eq. 4.30 | `Elements.True_To_Hyperbolic_Anomaly` | Pre: e > 1 | `Test_Elements` |

---

## 5. Kepler Equation Solvers (Hale Chapter 4)

### 5.1 Iterative Solvers

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-1A-001 | HLR-KE-001 | Solve elliptic Kepler equation | Eq. 4.20 | `Kepler.Solve_Kepler_Elliptic` | Pre: 0 ≤ e < 1 | `Test_Kepler` |
| HLR-1A-002 | HLR-KE-002 | Solve hyperbolic Kepler equation | Eq. 4.31 | `Kepler.Solve_Kepler_Hyperbolic` | Pre: e > 1 | `Boundaries` |
| HLR-1A-003 | HLR-KE-003 | Solve parabolic case | Barker | `Kepler.Solve_Kepler_Parabolic` | Pre: e ≈ 1 | None (gap; see test-rtm.md) |
| HLR-1A-020 | HLR-KE-004 | Solve universal Kepler equation | Battin | `Kepler.Solve_Kepler_Universal` | All orbit types | `Exceptions` |

### 5.2 Stumpff Functions

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-3A-001 | HLR-KE-010 | Compute Stumpff C(z) | Battin 4.4 | `Stumpff.C` | Post: C >= 0 | `Test_Kepler`, `Edge_Cases` |
| HLR-3A-002 | HLR-KE-011 | Compute Stumpff S(z) | Battin 4.4 | `Stumpff.S` | Post: S >= 0 | `Test_Kepler`, `Edge_Cases` |
| HLR-3A-001, HLR-3A-002 | HLR-KE-012 | Handle z=0 limit correctly | Taylor | `Stumpff.C`, `Stumpff.S` | C(0)=0.5, S(0)=1/6 | `Test_Kepler` |

### 5.3 Time of Flight

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-1A-021 | HLR-KE-020 | Elliptic time of flight | Derived | `Kepler.Time_Of_Flight_Elliptic` | Pre: e < 1 | None (gap; see test-rtm.md) |
| HLR-1A-022 | HLR-KE-021 | Hyperbolic time of flight | Derived | `Kepler.Time_Of_Flight_Hyperbolic` | Pre: e > 1 | None (gap; see test-rtm.md) |
| HLR-2B-014 | HLR-KE-022 | Propagate state by time | Universal | `Kepler.Propagate` | Energy conserved | None (gap; see test-rtm.md) |

---

## 6. Lambert Problem (Hale Chapter 5)

### 6.1 Lambert Solver

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-2A-001 | HLR-LB-001 | Solve single-rev Lambert problem | Ch. 5 | `Lambert.Solve_Lambert` | Pre: r1,r2 > 0, tof > 0 | `Edge_Cases`, `Vallado` |
| HLR-2A-001 | HLR-LB-002 | Compute transfer velocities | Ch. 5 | `Lambert.Solve_Lambert` | Post: valid V1, V2 | `Edge_Cases`, `Vallado` |
| HLR-2A-001 | HLR-LB-003 | Handle short-way trajectory | Note | `Lambert.Solve_Lambert` | Long_Way = False | `Lambert_MultiRev` |
| HLR-2A-001 | HLR-LB-004 | Handle long-way trajectory | Note | `Lambert.Solve_Lambert` | Long_Way = True | `Lambert_MultiRev` |
| HLR-2A-002 | HLR-LB-005 | Solve multi-rev Lambert | Extended | `Lambert.Solve_Lambert_Multi` | Max_Revs param | `Lambert_MultiRev` |

### 6.2 Lambert Utilities

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-2A-004 | HLR-LB-010 | Compute minimum energy TOF | Derived | `Lambert.Minimum_Energy_Tof` | Parabolic limit | None (gap; see test-rtm.md) |
| HLR-2A-005 | HLR-LB-011 | Compute transfer angle | Geometry | `Lambert.Transfer_Angle` | Post: 0 ≤ θ ≤ 2π | `Vallado`, `Edge_Cases` |
| HLR-2A-006 | HLR-LB-012 | Check solution existence | Derived | `Lambert.Solution_Exists` | Boolean result | None (gap; see test-rtm.md) |

---

## 7. Orbital Maneuvers (Hale Chapter 6)

### 7.1 Hohmann Transfer

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-2C-001 | HLR-MN-001 | Compute Hohmann transfer | Sec. 6.2 | `Maneuvers.Hohmann_Transfer` | Pre: r1,r2 > 0 | `Test_Maneuvers` |
| HLR-2C-001 | HLR-MN-002 | Compute Hohmann delta-V1 | Eq. 6.1 | `Maneuvers.Hohmann_Delta_V1` | Departure burn | `Test_Maneuvers` |
| HLR-2C-001 | HLR-MN-003 | Compute Hohmann delta-V2 | Eq. 6.2 | `Maneuvers.Hohmann_Delta_V2` | Arrival burn | `Test_Maneuvers` |
| HLR-2C-001 | HLR-MN-004 | Compute transfer time | Eq. 6.3 | `Maneuvers.Hohmann_Transfer_Time` | Half period | `Test_Maneuvers` |

### 7.2 Bi-Elliptic Transfer

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-2C-002 | HLR-MN-010 | Compute bi-elliptic transfer | Sec. 6.3 | `Maneuvers.Bielliptic_Transfer` | Three burns | `Edge_Cases` |
| HLR-2C-005 | HLR-MN-011 | Determine efficiency threshold | 11.94 rule | `Maneuvers.Bielliptic_Is_Efficient` | r_f/r_i > 11.94 | `Test_Maneuvers` |

### 7.3 Plane Changes

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-2C-003 | HLR-MN-020 | Simple plane change | Sec. 6.4 | `Maneuvers.Simple_Plane_Change` | Pre: Δi defined | `Vallado`, `Edge_Cases` |
| HLR-2C-006 | HLR-MN-021 | Combined plane change | Sec. 6.4 | `Maneuvers.Combined_Plane_Change` | Optimal location | None (gap; see test-rtm.md) |

---

## 8. Three-Body Dynamics (CR3BP)

### 8.1 Lagrange Points

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-3B-001 | HLR-3B-001 | Compute L1 position | CR3BP | `Threebody.Compute_Lagrange_Point` | L1 on axis | `Test_Threebody` |
| HLR-3B-002 | HLR-3B-002 | Compute L2 position | CR3BP | `Threebody.Compute_Lagrange_Point` | L2 on axis | `Integration` |
| HLR-3B-003 | HLR-3B-003 | Compute L3 position | CR3BP | `Threebody.Compute_Lagrange_Point` | L3 on axis | None (gap; see test-rtm.md) |
| HLR-3B-004 | HLR-3B-004 | Compute L4 position | CR3BP | `Threebody.Compute_Lagrange_Point` | Equilateral | `Test_Threebody` |
| HLR-3B-005 | HLR-3B-005 | Compute L5 position | CR3BP | `Threebody.Compute_Lagrange_Point` | Equilateral | `Test_Threebody` |

### 8.2 Stability Analysis

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-3B-010 | HLR-3B-010 | Analyze L1/L2/L3 stability | Theory | `Threebody.Analyze_Stability` | Unstable | `Test_Threebody` |
| HLR-3B-011 | HLR-3B-011 | Analyze L4/L5 stability | Theory | `Threebody.Analyze_Stability` | Stable if μ < 0.0385 | `Test_Threebody` |

### 8.3 Jacobi Constant

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-3B-020 | HLR-3B-020 | Compute Jacobi constant | CR3BP | `Threebody.Jacobi_Constant` | Conservation test | `Test_Threebody` |
| HLR-3B-021 | HLR-3B-021 | Compute zero-velocity surface check | Theory | `Threebody.Is_Above_Zero_Velocity_Surface` | Boundary | None (gap; see test-rtm.md) |

### 8.4 Periodic Orbits (ISS-034)

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-3B-042 | HLR-3B-030 | Compute State Transition Matrix | Variational | `Threebody.Propagate_With_STM` | 6x6 matrix | `Periodic_Orbits` |
| HLR-3B-044 | HLR-3B-031 | Compute Monodromy matrix | Periodic theory | `Threebody.Compute_Monodromy` | One-period STM | `Periodic_Orbits` |
| HLR-3B-045 | HLR-3B-032 | Analyze Floquet multipliers | Stability | `Threebody.Analyze_Floquet` | Eigenvalue pairs | `Periodic_Orbits` |
| HLR-3B-033 | HLR-3B-033 | Find Lyapunov orbits | Diff. correction | `Threebody.Find_Lyapunov_Orbit` | Planar periodic | `Periodic_Orbits` |
| HLR-3B-034 | HLR-3B-034 | Find Halo orbits | Richardson | `Threebody.Find_Halo_Orbit` | 3D periodic | `Periodic_Orbits` |
| HLR-3B-046 | HLR-3B-035 | Generate orbit families | Continuation | `Threebody.Generate_Orbit_Family` | Amplitude sweep | `Periodic_Orbits` |

*Legacy HLR-3B-030/031/032 were renumbered to HLR-3B-042/044/045, and legacy
HLR-3B-035 ("Generate orbit families") to HLR-3B-046, to resolve the collision
with the SRS, which reserves HLR-3B-035 for the Richardson approximation and
HLR-3B-036..045 for the periodic-orbit verification requirements.*

---

## 9. Interplanetary (Hale Chapters 7-8)

### 9.1 Sphere of Influence

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-2D-001 | HLR-IP-001 | Compute SOI radius | Laplace | `Interplanetary.Sphere_Of_Influence` | Post: r_SOI > 0 | `Integration` |

### 9.2 Patched Conics

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-2D-002 | HLR-IP-010 | Compute departure C3 | Ch. 7 | `Interplanetary.Compute_Patched_Conic` | Launch energy | `Integration` |
| HLR-2D-003 | HLR-IP-011 | Compute arrival V_inf | Ch. 7 | `Interplanetary.Compute_Patched_Conic` | Arrival speed | `Integration` |
| HLR-2D-004 | HLR-IP-012 | Hohmann interplanetary | Simplified | `Interplanetary.Hohmann_Interplanetary` | Earth-Mars | `Integration` |

### 9.3 Gravity Assist

| Req ID | Legacy ID | Requirement | Hale Ref | Implementation | Contract | Test |
|--------|-----------|-------------|----------|----------------|----------|------|
| HLR-2D-005 | HLR-IP-020 | Compute flyby turn angle | Ch. 8 | `Interplanetary.Turn_Angle` | Hyperbolic | None (gap; see test-rtm.md) |
| HLR-2D-006 | HLR-IP-021 | Compute delta-V gain | Ch. 8 | `Interplanetary.Compute_Flyby` | Gravity assist | `Integration` |

---

## 10. Vector/Matrix Operations

### 10.1 Vector Operations

| Req ID | Legacy ID | Requirement | Implementation | Contract | Test |
|--------|-----------|-------------|----------------|----------|------|
| HLR-1C-001 | HLR-VEC-001 | Vector addition | `Vectors."+"` | Global => null | `Test_Vectors` |
| HLR-1C-002 | HLR-VEC-002 | Vector subtraction | `Vectors."-"` | Global => null | `Edge_Cases` |
| HLR-1C-003 | HLR-VEC-003 | Dot product | `Vectors.Dot` | Commutative | `Test_Vectors` |
| HLR-1C-004 | HLR-VEC-004 | Cross product | `Vectors.Cross` | Orthogonal | `Test_Vectors` |
| HLR-1C-005 | HLR-VEC-005 | Magnitude | `Vectors.Magnitude` | Post >= 0 | `Test_Vectors` |
| HLR-1C-006 | HLR-VEC-006 | Normalize | `Vectors.Normalize` | Post: |v| = 1 | `Test_Vectors` |

### 10.2 Matrix Operations

| Req ID | Legacy ID | Requirement | Implementation | Contract | Test |
|--------|-----------|-------------|----------------|----------|------|
| HLR-1D-001 | HLR-MAT-001 | Matrix multiplication | `Matrices."*"` | Global => null | `Test_Matrices` |
| HLR-1D-002 | HLR-MAT-002 | Matrix transpose | `Matrices.Transpose` | Global => null | `Edge_Cases` |
| HLR-1D-003 | HLR-MAT-003 | Matrix determinant | `Matrices.Determinant` | Global => null | `Test_Matrices` |
| HLR-1D-004 | HLR-MAT-004 | Rotation matrices | `Matrices.Rotation_X/Y/Z` | Orthogonal | `Test_Matrices` |

---

## 11. Non-Functional Requirements

### 11.1 Performance Requirements

| Req ID | Legacy ID | Requirement | Target | Verification | Status |
|--------|-----------|-------------|--------|--------------|--------|
| NFR-PERF-003 | NFR-PERF-001 | Hohmann transfer computation time | < 100 ns | Benchmark program (`ada/examples`) | Open (benchmark not run in CI) |
| NFR-PERF-001 | NFR-PERF-002 | Kepler solver convergence | < 50 iterations | Unit test | Verified |
| NFR-PERF-004 | NFR-PERF-003 | Lambert solver computation time | < 10 μs | Benchmark program (`ada/examples`) | Open (benchmark not run in CI) |
| NFR-PERF-005 | NFR-PERF-004 | State propagation (RK4) | < 1 ms per step | Benchmark program (`ada/examples`) | Open (benchmark not run in CI) |
| NFR-PERF-006 | NFR-PERF-005 | Parallel propagation scaling | Linear with cores | Parallel tests | Open (implementation is currently sequential) |

### 11.2 Accuracy Requirements

| Req ID | Legacy ID | Requirement | Target | Verification | Status |
|--------|-----------|-------------|--------|--------------|--------|
| NFR-ACC-001 | NFR-ACC-001 | Kepler solver tolerance | < 1.0e-12 | Unit test | Verified |
| NFR-ACC-002 | NFR-ACC-002 | Lambert solver tolerance | < 1.0e-10 | Unit test | Verified |
| NFR-ACC-003 | NFR-ACC-003 | Element conversion round-trip | < 1.0e-10 | Integration test | Verified |
| NFR-ACC-004 | NFR-ACC-004 | Energy conservation (2-body) | < 1.0e-10 relative | Integration test | Verified |
| NFR-ACC-005 | NFR-ACC-005 | Angular momentum conservation | < 1.0e-10 relative | Integration test | Verified |
| NFR-ACC-006 | NFR-ACC-006 | Jacobi constant conservation (CR3BP) | < 1.0e-8 | Threebody tests | Verified |
| NFR-DET-001 | NFR-ACC-007 | Cross-platform reproducibility | Bit-identical | Determinism tests | Verified |

### 11.3 Robustness Requirements

| Req ID | Legacy ID | Requirement | Target | Verification | Status |
|--------|-----------|-------------|--------|--------------|--------|
| NFR-ROB-005 | NFR-ROB-001 | Handle near-circular orbits | e < 1.0e-10 | Edge case tests | Verified |
| NFR-ROB-006 | NFR-ROB-002 | Handle near-equatorial orbits | i < 1.0e-10 | Edge case tests | Verified |
| NFR-ROB-007 | NFR-ROB-003 | Handle near-parabolic orbits | |e-1| < 1.0e-6 | Edge case tests | Verified |
| NFR-ROB-008 | NFR-ROB-004 | Handle high eccentricity | e up to 0.999 | Edge case tests | Verified |
| NFR-ERR-007 | NFR-ROB-005 | Detect non-convergence | Return flag | Unit tests | Verified |
| NFR-ROB-002 | NFR-ROB-006 | No division by zero | Preconditions | SPARK proof | Partial |

### 11.4 Portability Requirements

| Req ID | Legacy ID | Requirement | Target | Verification | Status |
|--------|-----------|-------------|--------|--------------|--------|
| NFR-PORT-001 | NFR-PORT-001 | Linux support | GCC, GNAT | CI build | Verified |
| NFR-PORT-002 | NFR-PORT-002 | Windows support | GNAT | CI build | Open (CI is Linux-only) |
| NFR-PORT-003 | NFR-PORT-003 | macOS support | GNAT | Manual test | Open (no recorded evidence) |
| NFR-PORT-004 | NFR-PORT-004 | Ada 2012 compliance | Standard | Compiler | Verified |
| NFR-PORT-005 | NFR-PORT-005 | SPARK 2014 compliance | Specs | GNATprove | Open (GNATprove has not been run) |

---

## 12. Error Handling Requirements

### 12.1 Exception Definitions

| Req ID | Legacy ID | Exception | Condition | Package | Test |
|--------|-----------|-----------|-----------|---------|------|
| NFR-ERR-001 | ERR-EXC-001 | `Convergence_Error` | Solver exceeds max iterations | Kepler, Lambert | `Exceptions` |
| NFR-ERR-002 | ERR-EXC-002 | `Invalid_Orbit` | Orbital elements physically invalid | Elements | `Exceptions` |
| NFR-ERR-004 | ERR-EXC-003 | `Physical_Error` | Computation violates physics | Twobody | `Exceptions` |
| NFR-ERR-003 | ERR-EXC-004 | `Singularity_Error` | Singular configuration detected | Elements | `Exceptions` |

### 12.2 Error Detection Requirements

| Req ID | Legacy ID | Requirement | Implementation | Verification | Status |
|--------|-----------|-------------|----------------|--------------|--------|
| NFR-ROB-002 | ERR-DET-001 | Detect division by zero | Preconditions | SPARK proof | Partial |
| NFR-ROB-001 | ERR-DET-002 | Detect invalid eccentricity | Preconditions | SPARK proof | Partial |
| NFR-ERR-007 | ERR-DET-003 | Detect non-convergence | Iteration check | Unit test | Verified |
| NFR-ERR-008 | ERR-DET-004 | Detect overflow | Range types | Compiler | Partial (float overflow not trapped; no `-gnateF`) |
| NFR-ROB-004 | ERR-DET-005 | Detect NaN propagation | Defensive code | TBD | Open |

### 12.3 Error Recovery Requirements

| Req ID | Legacy ID | Requirement | Strategy | Verification | Status |
|--------|-----------|-------------|----------|--------------|--------|
| NFR-ERR-007 | ERR-REC-001 | Non-convergence recovery | Return Converged=False | Unit test | Verified |
| NFR-ROB-003 | ERR-REC-002 | Singular configuration | Use limiting formula | Edge cases | Verified |
| NFR-ROB-009 | ERR-REC-003 | Numerical instability | Clamping | Code review | Verified |

---

## 13. Dependency Requirements

*DEP-* entries are dependency and tool records tracked in this RTM only; they
are not software requirements and are not part of the SRS requirement set.*

### 13.1 Language and Compiler

| Req ID | Dependency | Version | Constraint | Verification |
|--------|------------|---------|------------|--------------|
| DEP-LANG-001 | Ada | 2012 | Minimum | Compiler |
| DEP-LANG-002 | SPARK | 2014 | Minimum | GNATprove |
| DEP-COMP-001 | GNAT Pro | 24.x | Recommended | Build |
| DEP-COMP-002 | FSF GNAT | 12.x+ | Alternate | CI |

### 13.2 Runtime Dependencies

| Req ID | Dependency | Usage | Constraint | Verification |
|--------|------------|-------|------------|--------------|
| DEP-RT-001 | Ada.Numerics.Generic_Elementary_Functions | Sin, Cos, etc. | Standard | Compile |
| DEP-RT-002 | Ada.Numerics.Long_Elementary_Functions | Sqrt, Log, etc. | Standard | Compile |
| DEP-RT-003 | Ada Runtime | Memory, exceptions | Platform | Execute |

### 13.3 Tool Dependencies

| Req ID | Tool | Version | Purpose | Qualification |
|--------|------|---------|---------|---------------|
| DEP-TOOL-001 | GNATprove | 24.x | SPARK proof | TQL-1 |
| DEP-TOOL-002 | GNATcoverage | 24.x | Coverage | TQL-1 |
| DEP-TOOL-003 | gprbuild | 24.x | Build | TQL-3 |
| DEP-TOOL-004 | Git | 2.x | Version control | N/A |

### 13.4 No External Library Dependencies

| Req ID | Requirement | Verification |
|--------|-------------|--------------|
| DEP-EXT-001 | No external Ada libraries | Code inspection |
| DEP-EXT-002 | No C/C++ dependencies | Build analysis |
| DEP-EXT-003 | Self-contained implementation | Architecture |

---

## 14. Requirement Coverage Summary

Distinct canonical HLRs traced to source in this RTM, by package:

| Package | Canonical HLRs traced | Canonical IDs |
|---------|-----------------------|---------------|
| Twobody | 14 | HLR-1A-006..019 |
| Elements | 8 | HLR-1A-004/005/023/024, HLR-1B-001/002/005/006 |
| Kepler | 9 | HLR-1A-001/002/003/020/021/022, HLR-3A-001/002, HLR-2B-014 |
| Lambert | 5 | HLR-2A-001/002/004/005/006 |
| Maneuvers | 5 | HLR-2C-001/002/003/005/006 |
| Threebody | 15 | HLR-3B-001..005/010/011/020/021/033/034/042/044/045/046 |
| Interplanetary | 6 | HLR-2D-001..006 |
| Vectors | 6 | HLR-1C-001..006 |
| Matrices | 4 | HLR-1D-001..004 |
| **Total** | **72** | |

The canonical requirement set (SRS.md v2.0) defines **106 HLR** and **38 NFR**
requirements. 72 of the 106 HLRs are traced to source above; the remaining 34
(HLR-1A-025, HLR-1B-003/004, HLR-2A-003, HLR-2B-001..013/015..020, HLR-2C-004,
HLR-3A-003/004, HLR-3B-035..041/043) are traced to tests in
`docs/certification/test-rtm.md`. Sections 11-12 above trace 35 legacy NFR/ERR
rows onto the canonical NFR set. Section 13 lists 14 DEP-* dependency records
outside the requirement set.

---

## 15. Vallado Validation Cross-Reference

| Test Category | Vallado Section | Test File | Requirements Verified |
|---------------|-----------------|-----------|----------------------|
| State-Elements | Examples 2-1, 2-2 | `Vallado.adb` | HLR-1A-004, HLR-1A-005 |
| Kepler | Example 2-3 | `Vallado.adb` | HLR-1A-001 |
| Hohmann | Example 5-1 | `Vallado.adb` | HLR-2C-001 |
| Plane Change | Example 5-5 | `Vallado.adb` | HLR-2C-003 |
| Lambert | Example 7-1 | `Vallado.adb` | HLR-2A-001, HLR-2A-005 |

---

## 16. Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Requirements Engineer | | | |
| Developer | | | |
| V&V Engineer | | | |
| QA | | | |

---

*This RTM should be updated whenever requirements or implementations change.*
