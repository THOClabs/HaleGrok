# Software Design Standards (SDS)

**Project:** HALE Orbital Mechanics Library
**Document Version:** 1.0
**Date:** 2026-01-06
**DO-178C Reference:** Section 5.2 - Software Design Process
**DAL:** Level C (Major Failure Condition)

---

## 1. Introduction

### 1.1 Purpose

This Software Design Standards (SDS) document defines the architectural design, component structure, and design decisions for the HALE Orbital Mechanics Library.

### 1.2 Scope

This document covers:
- High-level architecture
- Package structure
- Algorithm design decisions
- Data flow design
- Error handling architecture

---

## 2. Architectural Overview

### 2.1 Design Philosophy

The HALE library follows these core design principles:

1. **Type Safety**: Dimensional types prevent unit errors at compile time
2. **Contract-Based Design**: SPARK 2014 contracts specify behavior formally
3. **Modularity**: Loosely coupled packages with clear interfaces
4. **Numerical Stability**: Algorithms selected for robustness, not just speed
5. **Determinism**: Reproducible results across platforms

### 2.2 Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
│  (User code, mission planning tools, simulation systems)     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   High-Level Operations                      │
│  ┌───────────┐  ┌──────────┐  ┌───────────┐  ┌───────────┐  │
│  │ Maneuvers │  │ Lambert  │  │Propagation│  │ Threebody │  │
│  └───────────┘  └──────────┘  └───────────┘  └───────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Core Operations                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Elements │  │  Kepler  │  │ Twobody  │  │ Stumpff  │     │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Foundation Layer                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │  Types   │  │ Vectors  │  │ Matrices │  │Constants │     │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘     │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Package Structure

### 3.1 Foundation Packages

#### Hale_Orbital.Types
**Purpose:** Define dimensional types for compile-time unit safety.

**Key Types:**
- `Real`: Base IEEE 754 double precision type
- `Distance_Km`: Distance in kilometers
- `Velocity_Km_S`: Velocity in km/s
- `Time_Seconds`: Time in seconds
- `Angle_Radians`: Angles in radians
- `Gravitational_Parameter`: μ in km³/s²
- `Vector_3D`, `Matrix_3x3`, `Matrix_6x6`
- `Orbital_Elements`, `State_Vector`

**Design Rationale (DEC-001):**
Dimensional types prevent catastrophic unit conversion errors like the Mars Climate Orbiter failure. Ada's strong typing catches these at compile time.

---

#### Hale_Orbital.Constants
**Purpose:** Physical and mathematical constants.

**Key Constants:**
- `Pi`, `Two_Pi`, `Half_Pi`: Mathematical constants
- `Mu_Earth`, `Mu_Sun`, `Mu_Moon`: Gravitational parameters
- `R_Earth`, `R_Moon`: Body radii
- `AU`: Astronomical unit

**Design Rationale (DEC-002):**
Centralized constants ensure consistency and traceability to authoritative sources (IERS 2010, DE430 ephemeris).

---

#### Hale_Orbital.Vectors
**Purpose:** 3D vector operations.

**Key Operations:**
- `Magnitude`, `Magnitude_Squared`
- `Normalize`, `Dot`, `Cross`
- Arithmetic operators (+, -, *, /)

**SPARK Mode:** On (fully proven)

---

#### Hale_Orbital.Matrices
**Purpose:** Matrix operations for rotations and STM.

**Key Operations:**
- `Multiply`, `Transpose`
- `Rotation_X`, `Rotation_Y`, `Rotation_Z`
- `Identity_3x3`, `Identity_6x6`

---

### 3.2 Core Packages

#### Hale_Orbital.Elements
**Purpose:** Orbital element conversions.

**Key Functions:**
- `State_To_Elements`: R, V → (a, e, i, Ω, ω, ν)
- `Elements_To_State`: (a, e, i, Ω, ω, ν) → R, V
- Anomaly conversions (true, eccentric, mean, hyperbolic)

**Design Rationale (DEC-003):**
Two-argument atan2 used for quadrant-correct angle computation. Special handling for singularities (circular, equatorial, radial orbits).

---

#### Hale_Orbital.Kepler
**Purpose:** Kepler equation solvers.

**Algorithms:**
- **Elliptic (e < 1):** Newton-Raphson with convergence guard
- **Hyperbolic (e > 1):** Newton-Raphson with sinh/cosh
- **Parabolic (e = 1):** Barker's equation (closed form)
- **Universal:** Stumpff function formulation

**Design Rationale (DEC-007):**
Newton-Raphson selected for quadratic convergence. High-eccentricity (e > 0.8) cases use improved initial guess to avoid convergence issues.

---

#### Hale_Orbital.Stumpff
**Purpose:** Stumpff functions C(z) and S(z).

**Formulas:**
```
C(z) = (1 - cos(√z)) / z     for z > 0
C(z) = (cosh(√-z) - 1) / (-z) for z < 0
C(0) = 1/2

S(z) = (√z - sin(√z)) / (√z)³ for z > 0
S(z) = (sinh(√-z) - √-z) / (√-z)³ for z < 0
S(0) = 1/6
```

**Design Rationale (DEC-004):**
Taylor series expansion for |z| < 1e-4 to avoid catastrophic cancellation near z = 0.

---

#### Hale_Orbital.Twobody
**Purpose:** Two-body orbital mechanics calculations.

**Key Functions:**
- `Circular_Velocity`, `Escape_Velocity`
- `Orbital_Period`, `Mean_Motion`
- `Vis_Viva`, `Specific_Energy`
- `Periapsis_Distance`, `Apoapsis_Distance`
- `Eccentricity_Vector`, `Angular_Momentum`

---

### 3.3 High-Level Packages

#### Hale_Orbital.Lambert
**Purpose:** Lambert boundary-value problem solver.

**Algorithm:** Universal variable formulation with bisection root-finding.

**Design Rationale (DEC-005):**
Bisection selected over Newton-Raphson for guaranteed convergence. Z-parameter bounds [-4π², 4π²] cover single-revolution transfers. Multi-revolution uses extended Z ranges.

---

#### Hale_Orbital.Propagation
**Purpose:** Orbit propagation using numerical integration.

**Integrators:**
- RK4: Fixed step, 4th order
- DP54: Adaptive Dormand-Prince 5(4), 7-stage embedded pair, controller exponent 1/5
- RKF78: Adaptive Fehlberg 7(8) (NASA TR R-287), 13-stage embedded pair, controller exponent 1/8

**Measured accuracy (GNAT 14.2 x86_64, tolerance 1e-12, one orbital period vs the
analytic Kepler propagator; see run_tests integrator validation suite):**
- RKF78: relative energy drift 1.9e-11 (circular LEO) / 6.7e-13 (e=0.7); terminal
  position error 6.4e-7 km / 4.7e-7 km; observed convergence order 6.99.
- DP54: relative energy drift 2.5e-12 / 3.5e-12; terminal position error 7.2e-8 km /
  1.6e-6 km; observed convergence order 4.78.
- Test bars enforced in CI: energy drift < 1e-10 (RKF78) and < 1e-9 (DP54);
  observed order >= 6.5 / >= 4.5.

**Design Rationale:**
Adaptive embedded pairs provide error-controlled propagation with the bars above;
RK4 remains for short-term, coarse propagation. The earlier "1e-12 energy
conservation" claim predates these measurements and was unsubstantiated (the
pre-2026-07 "RK78" implementation was not a valid RK method — see review R2).

---

#### Hale_Orbital.Maneuvers
**Purpose:** Impulsive maneuver calculations.

**Maneuvers Supported:**
- Hohmann transfer
- Bielliptic transfer
- Plane change
- Combined maneuvers

---

#### Hale_Orbital.Threebody
**Purpose:** Circular Restricted Three-Body Problem (CR3BP).

**Features:**
- Lagrange point computation (L1-L5)
- Jacobi constant calculation
- STM propagation
- Periodic orbit finding (Lyapunov, Halo)

---

## 4. Data Flow Design

### 4.1 State Conversion Flow

```
Input State (R, V, μ)
        │
        ▼
┌───────────────────┐
│ State_To_Elements │
│  - Compute h = R×V│
│  - Compute e vector│
│  - Compute a, e, i│
│  - Handle singularities│
└───────────────────┘
        │
        ▼
Orbital_Elements (a, e, i, Ω, ω, ν)
        │
        ▼
┌───────────────────┐
│ Elements_To_State │
│  - Perifocal frame│
│  - Rotation matrices│
│  - ECI transformation│
└───────────────────┘
        │
        ▼
Output State (R, V)
```

### 4.2 Lambert Solution Flow

```
Input: R1, R2, TOF, μ
        │
        ▼
┌─────────────────┐
│ Geometry Setup  │
│ - Transfer angle│
│ - Chord length  │
│ - Semi-perimeter│
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Bisection Loop  │
│ - Stumpff C, S  │
│ - Y parameter   │
│ - TOF calculation│
│ - Z update      │
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Velocity Calc   │
│ - f, g functions│
│ - V1, V2 vectors│
└─────────────────┘
        │
        ▼
Output: V1, V2, a, e, convergence
```

---

## 5. Error Handling Design

### 5.1 Exception Hierarchy

```
Standard_Ada_Exceptions
├── Constraint_Error (array bounds, overflow)
└── Program_Error (logic errors)

HALE_Exceptions (Hale_Orbital.Types)
├── Convergence_Error (solver non-convergence)
├── Invalid_Orbit (physically impossible)
├── Physical_Error (conservation violation)
└── Singularity_Error (geometric singularity)
```

### 5.2 Contract-Based Prevention

Pre-conditions prevent invalid inputs:
```ada
function Circular_Velocity (R : Distance_Km; Mu : Gravitational_Parameter)
   return Velocity_Km_S
   with Pre => Real (R) > 0.0 and Real (Mu) > 0.0;
```

Post-conditions guarantee valid outputs:
```ada
function Vis_Viva (...) return Velocity_Km_S
   with Post => Real (Vis_Viva'Result) >= 0.0;
```

---

## 6. Numerical Design Decisions

### 6.1 Threshold Values

| Threshold | Value | Purpose | Reference |
|-----------|-------|---------|-----------|
| Small_Threshold | 1.0e-15 | Division safety | DEC-009 |
| Circular_Threshold | 1.0e-10 | e ≈ 0 detection | DEC-003 |
| Parabolic_Threshold | 1.0e-10 | e ≈ 1 detection | DEC-003 |
| High_Eccentricity | 0.8 | Convergence switch | DEC-007 |

### 6.2 Iteration Limits

| Solver | Max Iterations | Typical | Rationale |
|--------|----------------|---------|-----------|
| Kepler (elliptic) | 50 | 4-8 | Quadratic convergence |
| Kepler (hyperbolic) | 50 | 5-10 | Similar to elliptic |
| Lambert | 100 | 20-40 | Bisection linear |
| Periodic orbit | 50 | 10-20 | Differential correction |

---

## 7. SPARK Verification Scope

### 7.1 Packages with SPARK_Mode => On

| Package | Spec | Body | Notes |
|---------|------|------|-------|
| Types | On | N/A | Pure package |
| Constants | On | N/A | Pure package |
| Vectors | On | On | Fully proven |
| Matrices | On | On | Fully proven |
| Elements | On | Off | Body uses generics |
| Kepler | On | Off | Body uses generics |
| Lambert | On | Off | Body uses generics |

### 7.2 Contract Coverage

All public functions have:
- Pre conditions for input validation
- Post conditions for output guarantees
- Global => null for thread safety

---

## 8. Design Decision Log

| ID | Decision | Rationale | Alternatives Considered |
|----|----------|-----------|------------------------|
| DEC-001 | Dimensional types | Compile-time unit safety | Runtime checks (rejected: overhead) |
| DEC-002 | Centralized constants | Consistency, traceability | Per-package constants (rejected: duplication) |
| DEC-003 | Two-argument atan2 | Correct quadrant | atan with quadrant correction (rejected: error-prone) |
| DEC-004 | Taylor series for small z | Avoid cancellation | L'Hôpital limit (rejected: complexity) |
| DEC-005 | Bisection for Lambert | Guaranteed convergence | Newton-Raphson (rejected: may diverge) |
| DEC-006 | SPARK contracts | Formal verification | Assertions (rejected: runtime only) |
| DEC-007 | Newton-Raphson for Kepler | Quadratic convergence | Bisection (rejected: slow) |
| DEC-008 | Test-driven tolerance | Traceable justification | Ad-hoc values (rejected: not certifiable) |
| DEC-009 | 1e-15 small threshold | 5× machine epsilon | 1e-10 (rejected: too conservative) |

---

*Document Version: 1.0*
*Last Updated: 2026-01-06*
*Prepared for: DO-178C Level C Certification*
