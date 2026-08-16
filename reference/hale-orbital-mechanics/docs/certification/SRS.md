# Software Requirements Specification (SRS)

**Project:** HALE Orbital Mechanics Library
**Document Version:** 2.0
**Date:** 2026-07-13
**DO-178C Reference:** Section 5.1 - Software Requirements Process
**DAL:** Level C (Major Failure Condition)

---

## 1. Introduction

### 1.1 Purpose

This Software Requirements Specification (SRS) defines the software requirements for the HALE Orbital Mechanics Library. These requirements are derived from system-level requirements and form the basis for software design and verification.

### 1.2 Scope

The HALE library provides orbital mechanics calculations for spacecraft mission planning and analysis. It includes:
- Two-body orbital mechanics
- Orbital element conversions
- Vector and matrix algebra (dimensional foundation)
- Lambert problem solver
- Orbit propagation
- Maneuver calculations
- Interplanetary patched-conic transfers
- Stumpff functions (universal-variable formulation)
- Three-body (CR3BP) mechanics

### 1.3 Definitions and Acronyms

| Term | Definition |
|------|------------|
| COE | Classical Orbital Elements |
| CR3BP | Circular Restricted Three-Body Problem |
| DAL | Design Assurance Level |
| HLR | High-Level Requirement |
| LEO | Low Earth Orbit |
| GEO | Geostationary Earth Orbit |
| NFR | Non-Functional Requirement |
| SMA | Semi-Major Axis |
| SOI | Sphere of Influence |
| STM | State Transition Matrix |
| TOF | Time of Flight |

### 1.4 Requirement Identification Scheme

This document is the canonical registry of requirement IDs for the project. All
requirement IDs follow the level-based scheme:

| Prefix | Section | Domain |
|--------|---------|--------|
| HLR-1A | 2.1 | Two-body mechanics (energy, momentum, geometry, Kepler solvers, TOF) |
| HLR-1B | 2.2 | Anomaly conversions |
| HLR-1C | 2.3 | Vector operations |
| HLR-1D | 2.4 | Matrix operations |
| HLR-2A | 2.5 | Lambert problem |
| HLR-2B | 2.6 | Propagation and cross-domain integration (incl. multi-revolution transfers) |
| HLR-2C | 2.7 | Orbital maneuvers |
| HLR-2D | 2.8 | Interplanetary transfer |
| HLR-3A | 2.9 | Stumpff functions |
| HLR-3B | 2.10 | Three-body (CR3BP) mechanics |
| NFR-* | 3 | Non-functional requirements |

Earlier revisions of `docs/certification/rtm.md` used domain prefixes
(HLR-TB, HLR-OE, HLR-KE, HLR-LB, HLR-MN, HLR-IP, HLR-3B, HLR-VEC, HLR-MAT).
Those legacy IDs are retired; the RTM's "Legacy ID" column preserves the
mapping from each legacy ID to its canonical ID. This SRS defines
106 high-level requirements (HLR) and 38 non-functional requirements (NFR).

---

## 2. High-Level Requirements

### 2.1 Two-Body Mechanics (HLR-1A)

#### HLR-1A-001: Kepler Equation Solver (Elliptic)
**Description:** The software shall solve the elliptic Kepler equation E - e·sin(E) = M for eccentric anomaly E given mean anomaly M and eccentricity e.

**Inputs:**
- Mean anomaly M: [0, 2π] radians
- Eccentricity e: [0, 1)

**Outputs:**
- Eccentric anomaly E: [0, 2π] radians

**Accuracy:** |E - e·sin(E) - M| < 1.0e-12

**Verification:** Test with Vallado examples, boundary cases

---

#### HLR-1A-002: Kepler Equation Solver (Hyperbolic)
**Description:** The software shall solve the hyperbolic Kepler equation e·sinh(H) - H = N for hyperbolic anomaly H.

**Inputs:**
- Mean anomaly N: (-∞, +∞)
- Eccentricity e: (1, ∞)

**Outputs:**
- Hyperbolic anomaly H: (-∞, +∞)

**Accuracy:** |e·sinh(H) - H - N| < 1.0e-12

---

#### HLR-1A-003: Kepler Equation Solver (Parabolic)
**Description:** The software shall solve the parabolic Kepler equation using Barker's equation.

**Inputs:**
- Mean anomaly M: (-∞, +∞)

**Outputs:**
- True anomaly ν: (-π, π]

**Accuracy:** < 1.0e-10 radians

---

#### HLR-1A-004: State-to-Elements Conversion
**Description:** The software shall convert position and velocity vectors to classical orbital elements.

**Inputs:**
- Position vector R: [km] (|R| > 0)
- Velocity vector V: [km/s]
- Gravitational parameter μ: [km³/s²]

**Outputs:**
- Semi-major axis a: [km]
- Eccentricity e: [0, ∞)
- Inclination i: [0, π] radians
- RAAN Ω: [0, 2π) radians
- Argument of periapsis ω: [0, 2π) radians
- True anomaly ν: [0, 2π) radians

**Special Cases:**
- Circular orbits (e < 1e-10): ω = 0
- Equatorial orbits (i < 1e-10): Ω = 0

---

#### HLR-1A-005: Elements-to-State Conversion
**Description:** The software shall convert classical orbital elements to position and velocity vectors.

**Inputs:**
- Orbital elements (a, e, i, Ω, ω, ν)
- Gravitational parameter μ

**Outputs:**
- Position vector R: [km]
- Velocity vector V: [km/s]

**Accuracy:** Round-trip conversion error < 1e-10 (relative)

---

#### HLR-1A-006: Circular Velocity
**Description:** The software shall compute circular orbital velocity at a given radius.

**Formula:** V_circ = √(μ/r)

**Inputs:**
- Radius r: (0, ∞) km
- Gravitational parameter μ: (0, ∞) km³/s²

**Outputs:**
- Velocity V_circ: (0, ∞) km/s

---

#### HLR-1A-007: Escape Velocity
**Description:** The software shall compute escape velocity at a given radius.

**Formula:** V_esc = √(2μ/r) = √2 × V_circ

**Inputs:**
- Radius r: (0, ∞) km
- Gravitational parameter μ: (0, ∞) km³/s²

**Outputs:**
- Velocity V_esc: (0, ∞) km/s

---

#### HLR-1A-008: Orbital Period
**Description:** The software shall compute the orbital period for elliptic orbits.

**Formula:** T = 2π√(a³/μ)

**Inputs:**
- Semi-major axis a: (0, ∞) km
- Gravitational parameter μ: (0, ∞) km³/s²

**Outputs:**
- Period T: (0, ∞) seconds

---

#### HLR-1A-009: Vis-Viva Equation
**Description:** The software shall compute velocity magnitude at any orbital position.

**Formula:** V = √(μ(2/r - 1/a))

**Inputs:**
- Radius r: (0, ∞) km
- Semi-major axis a: ≠ 0 km
- Gravitational parameter μ: (0, ∞) km³/s²

**Outputs:**
- Velocity V: [0, ∞) km/s

---

#### HLR-1A-010: Specific Energy
**Description:** The software shall compute specific orbital energy.

**Formula:** ε = V²/2 - μ/r = -μ/(2a)

**Inputs:**
- State vector (R, V) or semi-major axis a
- Gravitational parameter μ

**Outputs:**
- Specific energy ε: [km²/s²]
  - ε < 0: Elliptic orbit
  - ε = 0: Parabolic trajectory
  - ε > 0: Hyperbolic trajectory

---

#### HLR-1A-011: Angular Momentum Vector
**Description:** The software shall compute the specific angular momentum vector from state vectors.

**Formula:** h = r × v

**Source:** Hale Eq. 2.28

---

#### HLR-1A-012: Angular Momentum Magnitude
**Description:** The software shall compute the specific angular momentum magnitude, from state vectors or from orbital elements.

**Formula:** h = |r × v| = √(μp)

**Outputs:** h ≥ 0 [km²/s]

**Source:** Hale Eq. 2.29

---

#### HLR-1A-013: Mean Motion
**Description:** The software shall compute the mean motion for elliptic orbits.

**Formula:** n = √(μ/a³)

**Inputs:** Semi-major axis a: (0, ∞) km; gravitational parameter μ: (0, ∞) km³/s²

**Outputs:** Mean motion n: (0, ∞) rad/s

**Source:** Hale Eq. 2.25

---

#### HLR-1A-014: Semi-Latus Rectum
**Description:** The software shall compute the semi-latus rectum (parameter) of a conic orbit.

**Formula:** p = a(1 - e²)

**Source:** Hale Eq. 3.5

---

#### HLR-1A-015: Periapsis Distance
**Description:** The software shall compute the periapsis distance of a conic orbit.

**Formula:** r_p = a(1 - e)

**Outputs:** r_p > 0 km

**Source:** Hale Eq. 3.7

---

#### HLR-1A-016: Apoapsis Distance
**Description:** The software shall compute the apoapsis distance of an elliptic orbit.

**Formula:** r_a = a(1 + e)

**Pre-condition:** e < 1

**Source:** Hale Eq. 3.8

---

#### HLR-1A-017: Radius at True Anomaly
**Description:** The software shall compute the orbital radius at a given true anomaly from the conic equation.

**Formula:** r = p / (1 + e·cos ν)

**Pre-condition:** 1 + e·cos ν > 0

**Source:** Hale Eq. 3.4

---

#### HLR-1A-018: Eccentricity Vector
**Description:** The software shall compute the eccentricity vector from state vectors.

**Formula:** e = ((v² - μ/r)·r - (r·v)·v) / μ

**Outputs:** Vector with |e| equal to the scalar eccentricity, pointing toward periapsis.

**Source:** Hale Eq. 3.12

---

#### HLR-1A-019: Eccentricity Magnitude
**Description:** The software shall compute the scalar eccentricity from state vectors.

**Formula:** e = |e_vec|

**Outputs:** e ≥ 0

---

#### HLR-1A-020: Universal-Variable Kepler Solver
**Description:** The software shall solve the universal Kepler equation using Stumpff functions (see HLR-3A), valid for elliptic, parabolic, and hyperbolic orbits.

**Inputs:** Initial state, time interval Δt, gravitational parameter μ

**Outputs:** Universal anomaly χ; convergence status

**Source:** Battin universal-variable formulation

---

#### HLR-1A-021: Elliptic Time of Flight
**Description:** The software shall compute the time of flight between two true anomalies on an elliptic orbit.

**Pre-condition:** 0 ≤ e < 1

---

#### HLR-1A-022: Hyperbolic Time of Flight
**Description:** The software shall compute the time of flight between two true anomalies on a hyperbolic trajectory.

**Pre-condition:** e > 1

---

#### HLR-1A-023: Circular-Orbit Singularity Handling
**Description:** For near-circular orbits (e < 1e-10), state-to-elements conversion shall apply the ω = 0 convention and shall not raise an exception. (Refines the special-case clause of HLR-1A-004.)

---

#### HLR-1A-024: Equatorial-Orbit Singularity Handling
**Description:** For near-equatorial orbits (i < 1e-10), state-to-elements conversion shall apply the Ω = 0 convention and shall not raise an exception. (Refines the special-case clause of HLR-1A-004.)

---

#### HLR-1A-025: Independent Reference Validation
**Description:** Two-body, element-conversion, Kepler-solver, maneuver, and Lambert results shall reproduce the published Vallado (4th ed.) reference examples 2-1, 2-2, 2-3, 5-1, 5-5, and 7-1 within the tolerances documented in the Vallado test suite.

**Verification:** Test (`hale_tests-vallado.adb`)

---

### 2.2 Anomaly Conversions (HLR-1B)

#### HLR-1B-001: True-to-Eccentric Anomaly
**Description:** Convert true anomaly to eccentric anomaly for elliptic orbits.

**Pre-condition:** 0 ≤ e < 1

---

#### HLR-1B-002: Eccentric-to-True Anomaly
**Description:** Convert eccentric anomaly to true anomaly for elliptic orbits.

**Pre-condition:** 0 ≤ e < 1

---

#### HLR-1B-003: True-to-Mean Anomaly
**Description:** Convert true anomaly to mean anomaly.

---

#### HLR-1B-004: Mean-to-Eccentric Anomaly
**Description:** Convert mean anomaly to eccentric anomaly (inverse Kepler equation).

---

#### HLR-1B-005: Hyperbolic Anomaly Conversions
**Description:** Convert between hyperbolic anomaly and true anomaly.

**Pre-condition:** e > 1

---

#### HLR-1B-006: Eccentric-to-Mean Anomaly
**Description:** Convert eccentric anomaly to mean anomaly (forward Kepler equation).

**Formula:** M = E - e·sin(E)

**Pre-condition:** 0 ≤ e < 1

---

### 2.3 Vector Operations (HLR-1C)

#### HLR-1C-001: Vector Addition
**Description:** The software shall compute the component-wise sum of two 3D vectors.

---

#### HLR-1C-002: Vector Subtraction
**Description:** The software shall compute the component-wise difference of two 3D vectors.

---

#### HLR-1C-003: Dot Product
**Description:** The software shall compute the dot product of two 3D vectors. The operation shall be commutative.

---

#### HLR-1C-004: Cross Product
**Description:** The software shall compute the cross product of two 3D vectors. The result shall be orthogonal to both operands.

---

#### HLR-1C-005: Vector Magnitude
**Description:** The software shall compute the Euclidean magnitude of a 3D vector.

**Outputs:** |v| ≥ 0

---

#### HLR-1C-006: Vector Normalization
**Description:** The software shall normalize a non-zero 3D vector to unit length.

**Pre-condition:** |v| > 0

**Outputs:** Unit vector with | |v| - 1 | below tolerance

---

### 2.4 Matrix Operations (HLR-1D)

#### HLR-1D-001: Matrix Multiplication
**Description:** The software shall compute matrix-matrix and matrix-vector products for 3x3 (and 6x6) matrices.

---

#### HLR-1D-002: Matrix Transpose
**Description:** The software shall compute the transpose of a matrix.

---

#### HLR-1D-003: Matrix Determinant
**Description:** The software shall compute the determinant of a 3x3 matrix.

---

#### HLR-1D-004: Rotation Matrices
**Description:** The software shall construct elementary rotation matrices about the X, Y, and Z axes. Rotation matrices shall be orthogonal.

---

### 2.5 Lambert Problem (HLR-2A)

#### HLR-2A-001: Single-Revolution Lambert Solver
**Description:** The software shall solve the Lambert boundary-value problem for single-revolution transfers.

**Inputs:**
- Position vectors R1, R2: (|R| > 0)
- Time of flight TOF: > 0
- Gravitational parameter μ: > 0
- Transfer direction (short-way/long-way)

**Outputs:**
- Departure velocity V1
- Arrival velocity V2
- Transfer orbit parameters (a, e)
- Convergence status

**Accuracy:** TOF error < 1e-8 seconds

---

#### HLR-2A-002: Multi-Revolution Lambert Solver
**Description:** The software shall find all valid multi-revolution solutions.

---

#### HLR-2A-003: Degenerate Transfer Detection
**Description:** The software shall detect and handle 180-degree (degenerate) transfers.

---

#### HLR-2A-004: Minimum-Energy Transfer Time
**Description:** The software shall compute the minimum-energy (parabolic-limit) time of flight between two position vectors, providing the lower TOF bound for Lambert solutions.

---

#### HLR-2A-005: Transfer Angle Computation
**Description:** The software shall compute the transfer angle between two position vectors, accounting for the short-way/long-way direction.

**Outputs:** θ in [0, 2π]

---

#### HLR-2A-006: Solution Existence Check
**Description:** The software shall provide a predicate indicating whether a Lambert solution exists for a given geometry, time of flight, and revolution count.

**Outputs:** Boolean result

---

### 2.6 Propagation (HLR-2B)

#### HLR-2B-001: RK4 Propagation
**Description:** Fourth-order Runge-Kutta integration for orbit propagation.

---

#### HLR-2B-002: RK78 Propagation
**Description:** Runge-Kutta-Fehlberg 7(8) adaptive integration.

---

#### HLR-2B-003: Energy Conservation
**Description:** Specific energy shall be conserved to within 1e-10 (relative) over one orbital period.

---

#### HLR-2B-004: Backward Propagation
**Description:** Propagation with a reversed time interval shall return the state to its initial value (forward-backward consistency) within integration tolerance.

---

#### HLR-2B-005: Zero-Duration Propagation
**Description:** Propagation over a zero-length interval shall return the initial state unchanged.

---

#### HLR-2B-006: High-Eccentricity Propagation Stability
**Description:** Numerical propagation shall remain stable (valid states, bounded energy error) for high-eccentricity elliptic orbits.

---

*HLR-2B-007 through HLR-2B-013 are cross-domain integration requirements verified by `hale_tests-integration.adb`.*

#### HLR-2B-007: Lambert-Propagation Consistency
**Description:** Numerically propagating the departure state produced by the Lambert solver (HLR-2A-001) for the specified time of flight shall arrive at the target position and arrival velocity within documented tolerances.

---

#### HLR-2B-008: Element Round-Trip Consistency
**Description:** State-to-elements and elements-to-state conversions shall compose losslessly within propagation workflows: position, velocity, semi-major axis, and eccentricity shall be preserved through the conversion chain, including high-eccentricity cases.

---

#### HLR-2B-009: Maneuver-Propagation Consistency
**Description:** Applying a Hohmann departure impulse (HLR-2C-001) and numerically propagating the transfer arc shall arrive at the target radius with near-zero radial velocity and the predicted transfer semi-major axis.

---

#### HLR-2B-010: End-to-End Mission Profile
**Description:** A chained LEO-to-GEO mission computation (initial orbit, transfer, circularization) shall produce a bound, near-circular final orbit at GEO radius with the correct period and total delta-V.

---

#### HLR-2B-011: CR3BP Propagation Integration
**Description:** CR3BP propagation shall be consistent with Lagrange-point and stability results (HLR-3B), preserving the Jacobi constant within tolerance.

---

#### HLR-2B-012: Interplanetary Chain Integration
**Description:** The patched-conic pipeline (HLR-2D) shall produce mutually consistent departure energy, arrival conditions, SOI radii, and synodic timing for reference planet pairs.

---

#### HLR-2B-013: Conservation Laws Under Propagation
**Description:** Specific energy and the angular momentum vector shall be conserved under unperturbed two-body propagation; an applied prograde impulse shall increase orbital energy.

---

#### HLR-2B-014: Analytical Kepler Propagation
**Description:** The software shall propagate a two-body state analytically by solving the universal Kepler equation (HLR-1A-020), conserving energy.

---

#### HLR-2B-015: Parallel Ensemble Propagation
**Description:** The software shall propagate an array of states over the same interval, producing results identical to sequential single-state propagation, and shall compute ensemble statistics.

---

*HLR-2B-016 through HLR-2B-020 refine the multi-revolution Lambert capability (HLR-2A-002); they are numbered under HLR-2B for continuity with the established test traceability.*

#### HLR-2B-016: Multi-Revolution Minimum TOF
**Description:** The software shall compute the minimum time of flight for an N-revolution Lambert transfer.

---

#### HLR-2B-017: Multi-Revolution Solution Counting
**Description:** The software shall count the valid Lambert solutions available for a given geometry and time of flight across revolution numbers.

---

#### HLR-2B-018: N-Revolution Transfer Construction
**Description:** The software shall construct valid transfer solutions for one, two, and three complete revolutions, with velocities consistent with the requested TOF, including published reference cases.

---

#### HLR-2B-019: Revolution Boundary Handling
**Description:** The software shall behave correctly for times of flight near the boundary between N and N+1 revolution solution families.

---

#### HLR-2B-020: Energy Branch Selection
**Description:** For multi-revolution transfers the software shall distinguish and select between the high-energy and low-energy solution branches.

---

### 2.7 Maneuvers (HLR-2C)

#### HLR-2C-001: Hohmann Transfer
**Description:** Compute minimum-energy two-impulse transfer between circular orbits.

---

#### HLR-2C-002: Bielliptic Transfer
**Description:** Compute three-impulse transfer for high orbit ratio cases.

---

#### HLR-2C-003: Plane Change
**Description:** Compute single-impulse plane change maneuver.

---

#### HLR-2C-004: Same-Orbit (Zero Delta-V) Transfer
**Description:** A transfer computed between two identical circular orbits shall yield zero total delta-V and shall not raise an exception.

---

#### HLR-2C-005: Bielliptic Efficiency Criterion
**Description:** The software shall determine whether a bielliptic transfer is more efficient than a Hohmann transfer using the radius-ratio criterion (r_final/r_initial > 11.94).

**Source:** Hale Sec. 6.3

---

#### HLR-2C-006: Combined Plane Change
**Description:** Compute the combined plane-change-plus-magnitude maneuver delta-V at the optimal location.

**Source:** Hale Sec. 6.4

---

### 2.8 Interplanetary Transfer (HLR-2D)

#### HLR-2D-001: Sphere of Influence
**Description:** The software shall compute a planet's sphere-of-influence radius using the Laplace formula.

**Formula:** r_SOI = a·(m_planet/m_Sun)^(2/5)

**Outputs:** r_SOI > 0 km

---

#### HLR-2D-002: Departure Characteristic Energy (C3)
**Description:** The software shall compute the departure characteristic energy C3 for a patched-conic interplanetary transfer.

**Formula:** C3 = V∞²

---

#### HLR-2D-003: Arrival Hyperbolic Excess Speed
**Description:** The software shall compute the arrival hyperbolic excess speed V∞ for a patched-conic interplanetary transfer.

---

#### HLR-2D-004: Interplanetary Hohmann Transfer
**Description:** The software shall compute a simplified Hohmann interplanetary transfer (delta-Vs and transfer time) between two planets, e.g. Earth-Mars.

---

#### HLR-2D-005: Flyby Turn Angle
**Description:** The software shall compute the hyperbolic turn angle of a planetary flyby.

**Formula:** δ = 2·asin(1/e)

---

#### HLR-2D-006: Flyby Delta-V Gain
**Description:** The software shall compute the delta-V change obtainable from a gravity-assist flyby.

---

### 2.9 Stumpff Functions (HLR-3A)

#### HLR-3A-001: Stumpff Function C(z)
**Description:** The software shall evaluate the Stumpff function C(z) for all z, with the exact limit C(0) = 1/2 at z = 0.

**Formula:** C(z) = (1 - cos√z)/z for z > 0; (cosh√(-z) - 1)/(-z) for z < 0

**Source:** Battin Sec. 4.4

---

#### HLR-3A-002: Stumpff Function S(z)
**Description:** The software shall evaluate the Stumpff function S(z) for all z, with the exact limit S(0) = 1/6 at z = 0.

**Formula:** S(z) = (√z - sin√z)/(√z)³ for z > 0; (sinh√(-z) - √(-z))/(√(-z))³ for z < 0

**Source:** Battin Sec. 4.4

---

#### HLR-3A-003: Stumpff Elliptic Domain (z > 0)
**Description:** For z > 0 (elliptic regime), C(z) and S(z) shall be positive and continuous, approaching the z = 0 limits as z → 0+.

---

#### HLR-3A-004: Stumpff Hyperbolic Domain (z < 0)
**Description:** For z < 0 (hyperbolic regime), C(z) and S(z) shall be evaluated via hyperbolic functions, positive and continuous, approaching the z = 0 limits as z → 0-.

---

### 2.10 Three-Body Mechanics (HLR-3B)

#### HLR-3B-001: L1 Lagrange Point
**Description:** Compute the position of the collinear libration point L1 (between the primaries, on the x-axis).

---

#### HLR-3B-002: L2 Lagrange Point
**Description:** Compute the position of the collinear libration point L2 (beyond the smaller primary, on the x-axis).

---

#### HLR-3B-003: L3 Lagrange Point
**Description:** Compute the position of the collinear libration point L3 (beyond the larger primary, on the x-axis).

---

#### HLR-3B-004: L4 Lagrange Point
**Description:** Compute the position of the triangular libration point L4 (equilateral, leading).

---

#### HLR-3B-005: L5 Lagrange Point
**Description:** Compute the position of the triangular libration point L5 (equilateral, trailing).

---

#### HLR-3B-010: Collinear Point Stability
**Description:** Stability analysis shall classify the collinear points L1/L2/L3 as unstable.

---

#### HLR-3B-011: Triangular Point Stability
**Description:** Stability analysis shall classify the triangular points L4/L5 as stable when the mass ratio satisfies the Routh criterion (μ < 0.03852).

---

#### HLR-3B-020: Jacobi Constant
**Description:** Compute the Jacobi constant of a CR3BP state; it shall be conserved along trajectories.

---

#### HLR-3B-021: Zero-Velocity Surface Check
**Description:** Determine whether a CR3BP state lies above the zero-velocity surface (i.e., outside the forbidden region) for a given Jacobi constant.

---

#### HLR-3B-033: Lyapunov Orbit Finding
**Description:** Find planar Lyapunov periodic orbits around L1/L2 points.

---

#### HLR-3B-034: Halo Orbit Finding
**Description:** Find three-dimensional halo periodic orbits.

---

#### HLR-3B-035: Richardson Approximation
**Description:** Provide third-order analytical approximation for halo orbit initial conditions.

---

#### HLR-3B-036: Northern Halo Family
**Description:** Halo orbit finding (HLR-3B-034) shall support the northern (z > 0) family.

---

#### HLR-3B-037: Southern Halo Family
**Description:** Halo orbit finding (HLR-3B-034) shall support the southern (z < 0) family.

---

#### HLR-3B-038: Halo Periodicity Verification
**Description:** A converged halo orbit shall return to its initial state after one period within the differential-correction tolerance.

---

#### HLR-3B-039: Richardson Approximation at L1
**Description:** The Richardson approximation (HLR-3B-035) shall produce an initial guess in the vicinity of L1 (x near L1, y near zero).

---

#### HLR-3B-040: Richardson Approximation at L2
**Description:** The Richardson approximation (HLR-3B-035) shall produce an initial guess in the vicinity of L2 (x near L2, y near zero).

---

#### HLR-3B-041: STM Initial Identity
**Description:** The state transition matrix shall equal the 6x6 identity matrix at the initial epoch.

---

#### HLR-3B-042: State Transition Matrix Propagation
**Description:** Propagate the 6x6 state transition matrix along a CR3BP trajectory via the variational equations.

---

#### HLR-3B-043: STM Symplectic Property
**Description:** The propagated state transition matrix shall satisfy the symplectic condition (Φᵀ J Φ = J) within tolerance.

---

#### HLR-3B-044: Monodromy Matrix
**Description:** Compute the monodromy matrix (state transition matrix over one full period) of a periodic orbit.

---

#### HLR-3B-045: Floquet Multiplier Analysis
**Description:** Determine the Floquet multipliers of the monodromy matrix, including the reciprocal stable/unstable pair, for periodic-orbit stability assessment.

---

#### HLR-3B-046: Orbit Family Generation
**Description:** Generate families of periodic orbits by numerical continuation (amplitude sweep).

---

---

## 3. Non-Functional Requirements

### 3.1 Robustness (NFR-ROB)

#### NFR-ROB-001: Input Validation
**Description:** All public functions shall validate inputs via Pre conditions.

#### NFR-ROB-002: Division Safety
**Description:** The software shall not perform division by values < Small_Threshold (1e-15).

#### NFR-ROB-003: Singularity Handling
**Description:** The software shall handle geometric singularities gracefully.

#### NFR-ROB-004: NaN/Inf Propagation
**Description:** The software shall not produce NaN or Inf outputs for valid inputs.

#### NFR-ROB-005: Near-Circular Orbit Robustness
**Description:** The software shall handle near-circular orbits (e < 1.0e-10) without numerical failure.

#### NFR-ROB-006: Near-Equatorial Orbit Robustness
**Description:** The software shall handle near-equatorial orbits (i < 1.0e-10) without numerical failure.

#### NFR-ROB-007: Near-Parabolic Orbit Robustness
**Description:** The software shall handle near-parabolic orbits (|e - 1| < 1.0e-6) without numerical failure.

#### NFR-ROB-008: High-Eccentricity Robustness
**Description:** The software shall handle eccentricities up to 0.999 without numerical failure.

#### NFR-ROB-009: Numerical Instability Mitigation
**Description:** Intermediate values subject to rounding (e.g., arguments to acos/asin) shall be clamped to their mathematical domains.

---

### 3.2 Error Handling (NFR-ERR)

#### NFR-ERR-001: Convergence_Error
**Description:** Raised when iterative solvers fail to converge within maximum iterations.

#### NFR-ERR-002: Invalid_Orbit
**Description:** Raised when orbital parameters are physically inconsistent.

#### NFR-ERR-003: Singularity_Error
**Description:** Raised when singular geometric configurations are encountered.

#### NFR-ERR-004: Physical_Error
**Description:** Raised when a computation would violate physical constraints.

#### NFR-ERR-005: Contract Violation Detection
**Description:** Violations of Pre/Post contracts shall raise Assertion_Error or Constraint_Error in all build modes (assertions are enabled via `-gnata`).

#### NFR-ERR-006: Exception Message Quality
**Description:** Raised exceptions shall carry meaningful diagnostic messages.

#### NFR-ERR-007: Non-Convergence Detection and Recovery
**Description:** Iterative solvers shall detect iteration-limit exhaustion (bounded iteration) and report it, either via a Converged = False status or by raising Convergence_Error; no solver shall loop unboundedly.

#### NFR-ERR-008: Overflow Detection
**Description:** Out-of-range values for constrained dimensional types shall be detected via Ada range checks. (Note: floating-point overflow to infinity is not trapped; `-gnateF` is not enabled.)

---

### 3.3 Determinism (NFR-DET)

#### NFR-DET-001: Reproducibility
**Description:** Identical inputs shall produce identical outputs across all supported platforms.

#### NFR-DET-002: Ordering Independence
**Description:** Results shall not depend on evaluation order of floating-point operations.

---

### 3.4 Performance (NFR-PERF)

#### NFR-PERF-001: Kepler Convergence
**Description:** Kepler solvers shall converge within 50 iterations for e < 0.99.

#### NFR-PERF-002: Lambert Convergence
**Description:** Lambert solver shall converge within 100 iterations.

#### NFR-PERF-003: Hohmann Computation Time
**Description:** Hohmann transfer computation shall complete in < 100 ns (target; benchmark program in `ada/examples`).

#### NFR-PERF-004: Lambert Computation Time
**Description:** Lambert solver computation shall complete in < 10 μs (target; benchmark program in `ada/examples`).

#### NFR-PERF-005: RK4 Step Time
**Description:** RK4 state propagation shall complete in < 1 ms per step (target; benchmark program in `ada/examples`).

#### NFR-PERF-006: Parallel Propagation Scaling
**Description:** Ensemble propagation shall scale linearly with core count (target; the current implementation is sequential — see `hale_orbital-propagation.adb`).

---

### 3.5 Thread Safety (NFR-THR)

#### NFR-THR-001: Reentrancy
**Description:** All functions shall be reentrant and thread-safe.

#### NFR-THR-002: No Global State
**Description:** Functions shall not modify global state (Global => null).

---

### 3.6 Accuracy (NFR-ACC)

#### NFR-ACC-001: Kepler Solver Tolerance
**Description:** Kepler solver residual shall be < 1.0e-12.

#### NFR-ACC-002: Lambert Solver Tolerance
**Description:** Lambert solver tolerance shall be < 1.0e-10.

#### NFR-ACC-003: Element Conversion Round-Trip
**Description:** Element/state round-trip conversion error shall be < 1.0e-10 (relative).

#### NFR-ACC-004: Two-Body Energy Conservation
**Description:** Two-body propagation energy error shall be < 1.0e-10 (relative). (See HLR-2B-003.)

#### NFR-ACC-005: Angular Momentum Conservation
**Description:** Angular momentum conservation error under two-body propagation shall be < 1.0e-10 (relative).

#### NFR-ACC-006: Jacobi Constant Conservation
**Description:** Jacobi constant conservation error under CR3BP propagation shall be < 1.0e-8.

---

### 3.7 Portability (NFR-PORT)

#### NFR-PORT-001: Linux Support
**Description:** The software shall build and pass tests on Linux (GCC/GNAT).

#### NFR-PORT-002: Windows Support
**Description:** The software shall build with GNAT on Windows.

#### NFR-PORT-003: macOS Support
**Description:** The software shall build with GNAT on macOS.

#### NFR-PORT-004: Ada 2012 Compliance
**Description:** The source shall comply with the Ada 2012 standard (or later).

#### NFR-PORT-005: SPARK 2014 Compliance
**Description:** Package specifications shall be SPARK 2014 compatible. (GNATprove has not yet been executed; no proof claims are made.)

---

## 4. Requirements Traceability

See `docs/certification/rtm.md` for complete bidirectional traceability between:
- System requirements → HLR
- HLR → Test procedures
- HLR → Source code

The RTM's "Legacy ID" column maps retired domain-prefixed IDs (HLR-TB-*,
HLR-OE-*, HLR-KE-*, HLR-LB-*, HLR-MN-*, HLR-IP-*, HLR-VEC-*, HLR-MAT-*, and
pre-unification HLR-3B-030/031/032/035 and NFR/ERR numbering) to the canonical
IDs defined in this document. Test-to-requirement traceability is in
`docs/certification/test-rtm.md`.

---

## 5. Verification Methods

| Method | Application |
|--------|-------------|
| Review | All requirements |
| Analysis | Mathematical derivations |
| Test | Functional verification |
| Proof | SPARK contracts (planned; GNATprove has not yet been executed) |

---

*Document Version: 2.0*
*Last Updated: 2026-07-13*
*Prepared for: DO-178C Level C Certification*
