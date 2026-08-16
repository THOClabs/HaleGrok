# HALE Orbital Mechanics Library - API Reference

Complete API documentation for the HALE Orbital Mechanics Ada library.

**Version:** 1.0
**Reference:** Hale, F.J. (1994). *Introduction to Space Flight*. Prentice Hall.

---

## Table of Contents

1. [Core Types (Hale_Orbital.Types)](#core-types)
2. [Physical Constants (Hale_Orbital.Constants)](#physical-constants)
3. [Vector Operations (Hale_Orbital.Vectors)](#vector-operations)
4. [Matrix Operations (Hale_Orbital.Matrices)](#matrix-operations)
5. [Two-Body Dynamics (Hale_Orbital.Twobody)](#two-body-dynamics)
6. [Orbital Elements (Hale_Orbital.Elements)](#orbital-elements)
7. [Kepler Solvers (Hale_Orbital.Kepler)](#kepler-solvers)
8. [Lambert Problem (Hale_Orbital.Lambert)](#lambert-problem)
9. [Orbital Maneuvers (Hale_Orbital.Maneuvers)](#orbital-maneuvers)
10. [Numerical Propagation (Hale_Orbital.Propagation)](#numerical-propagation)
11. [Three-Body Dynamics (Hale_Orbital.Threebody)](#three-body-dynamics)
12. [Stumpff Functions (Hale_Orbital.Stumpff)](#stumpff-functions)
13. [Interplanetary Trajectories (Hale_Orbital.Interplanetary)](#interplanetary-trajectories)
14. [Exception Handling](#exception-handling)
15. [Performance Requirements](#performance-requirements)
16. [Numerical Accuracy by Orbital Regime](#numerical-accuracy-by-orbital-regime)
17. [Build Modes and Determinism](#build-modes-and-determinism)

---

## Core Types

**Package:** `Hale_Orbital.Types`
**SPARK Mode:** On
**Purpose:** Fundamental types with compile-time dimensional safety.

### Numeric Types

| Type | Description | Units |
|------|-------------|-------|
| `Real` | Base floating-point type (64-bit IEEE 754) | - |
| `Distance_Km` | Distance | kilometers |
| `Velocity_Km_S` | Velocity | km/s |
| `Time_Seconds` | Time duration | seconds |
| `Angle_Radians` | Angle | radians |
| `Mass_Kg` | Mass | kilograms |
| `Gravitational_Parameter` | mu = G*M | km^3/s^2 |
| `Specific_Energy` | Energy per unit mass | km^2/s^2 |
| `Specific_Angular_Momentum` | Angular momentum per unit mass | km^2/s |

### Vector and Matrix Types

```ada
type Vector_3D is array (1 .. 3) of Real;
subtype Position_Vector is Vector_3D;  -- (km)
subtype Velocity_Vector is Vector_3D;  -- (km/s)

type Matrix_3x3 is array (1 .. 3, 1 .. 3) of Real;
type Matrix_6x6 is array (1 .. 6, 1 .. 6) of Real;
```

### State Vector

```ada
type State_Vector is record
   Position : Position_Vector;  -- (km)
   Velocity : Velocity_Vector;  -- (km/s)
end record;
```

### Orbital Elements (Classical Keplerian)

```ada
type Orbital_Elements is record
   Semi_Major_Axis       : Distance_Km;    -- a
   Eccentricity          : Real;           -- e (dimensionless)
   Inclination           : Angle_Radians;  -- i
   RAAN                  : Angle_Radians;  -- Omega
   Argument_Of_Periapsis : Angle_Radians;  -- omega
   True_Anomaly          : Angle_Radians;  -- nu
end record;
```

### Orbit Classification

```ada
type Orbit_Type is (Circular, Elliptical, Parabolic, Hyperbolic);
```

### Exceptions

| Exception | Description |
|-----------|-------------|
| `Convergence_Error` | Iterative solver failed to converge |
| `Invalid_Orbit` | Orbit parameters are physically invalid |
| `Physical_Error` | Calculation violates physical constraints |
| `Singularity_Error` | Singularity condition encountered |

---

## Physical Constants

**Package:** `Hale_Orbital.Constants`
**SPARK Mode:** On
**Source:** Hale Appendix B

### Mathematical Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `Pi` | 3.14159265358979... | Pi |
| `Two_Pi` | 6.28318... | 2 * Pi |
| `Deg_To_Rad` | 0.01745... | Degrees to radians conversion |
| `Rad_To_Deg` | 57.2957... | Radians to degrees conversion |

### Celestial Body Parameters

#### Earth
| Constant | Value | Units |
|----------|-------|-------|
| `Mu_Earth` | 398,600.4418 | km^3/s^2 |
| `R_Earth` | 6,378.137 | km |
| `J2_Earth` | 1.08263e-3 | - |
| `R_GEO` | 42,164.0 | km |

#### Moon
| Constant | Value | Units |
|----------|-------|-------|
| `Mu_Moon` | 4,902.8 | km^3/s^2 |
| `R_Moon` | 1,737.4 | km |
| `A_Moon` | 384,400.0 | km |

#### Sun
| Constant | Value | Units |
|----------|-------|-------|
| `Mu_Sun` | 1.327e11 | km^3/s^2 |
| `AU` | 149,597,870.7 | km |

#### Mars
| Constant | Value | Units |
|----------|-------|-------|
| `Mu_Mars` | 42,828.37 | km^3/s^2 |
| `R_Mars` | 3,396.2 | km |

---

## Vector Operations

**Package:** `Hale_Orbital.Vectors`
**SPARK Mode:** On

### Functions

```ada
function "+" (Left, Right : Vector_3D) return Vector_3D;
function "-" (Left, Right : Vector_3D) return Vector_3D;
function "*" (Scalar : Real; V : Vector_3D) return Vector_3D;

function Dot (A, B : Vector_3D) return Real;
--  Dot product: A . B

function Cross (A, B : Vector_3D) return Vector_3D;
--  Cross product: A x B

function Magnitude (V : Vector_3D) return Real;
--  |V| = sqrt(V.V)

function Normalize (V : Vector_3D) return Vector_3D;
--  V / |V|

function Angle_Between (A, B : Vector_3D) return Angle_Radians;
--  arccos((A.B) / (|A||B|))
```

---

## Matrix Operations

**Package:** `Hale_Orbital.Matrices`
**SPARK Mode:** On

### Functions

```ada
function "*" (M : Matrix_3x3; V : Vector_3D) return Vector_3D;
function "*" (A, B : Matrix_3x3) return Matrix_3x3;

function Transpose (M : Matrix_3x3) return Matrix_3x3;
function Determinant (M : Matrix_3x3) return Real;
function Inverse (M : Matrix_3x3) return Matrix_3x3;

--  Rotation matrices
function Rotation_X (Angle : Angle_Radians) return Matrix_3x3;
function Rotation_Y (Angle : Angle_Radians) return Matrix_3x3;
function Rotation_Z (Angle : Angle_Radians) return Matrix_3x3;
```

---

## Two-Body Dynamics

**Package:** `Hale_Orbital.Twobody`
**SPARK Mode:** On
**Reference:** Hale Chapters 2-3

### Energy and Momentum

```ada
function Specific_Energy (R : Position_Vector;
                          V : Velocity_Vector;
                          Mu : Gravitational_Parameter) return Specific_Energy;
--  epsilon = v^2/2 - mu/r (Hale Eq. 2.14)

function Angular_Momentum_Vector (R : Position_Vector;
                                  V : Velocity_Vector) return Vector_3D;
--  h = r x v (Hale Eq. 2.28)

function Angular_Momentum (R : Position_Vector;
                           V : Velocity_Vector) return Specific_Angular_Momentum;
--  |h| = |r x v|
```

### Vis-Viva Equation

```ada
function Vis_Viva (R : Distance_Km;
                   A : Distance_Km;
                   Mu : Gravitational_Parameter) return Velocity_Km_S;
--  v = sqrt(mu * (2/r - 1/a)) (Hale Eq. 2.19)

function Circular_Velocity (R : Distance_Km;
                            Mu : Gravitational_Parameter) return Velocity_Km_S;
--  v_c = sqrt(mu/r)

function Escape_Velocity (R : Distance_Km;
                          Mu : Gravitational_Parameter) return Velocity_Km_S;
--  v_esc = sqrt(2*mu/r)
```

### Orbital Period

```ada
function Orbital_Period (A : Distance_Km;
                         Mu : Gravitational_Parameter) return Time_Seconds;
--  T = 2*pi * sqrt(a^3/mu) (Hale Eq. 2.24)

function Mean_Motion (A : Distance_Km;
                      Mu : Gravitational_Parameter) return Real;
--  n = sqrt(mu/a^3)
```

### Conic Geometry

```ada
function Semi_Latus_Rectum (A : Distance_Km; E : Real) return Distance_Km;
--  p = a(1 - e^2)

function Periapsis_Distance (A : Distance_Km; E : Real) return Distance_Km;
--  r_p = a(1 - e)

function Apoapsis_Distance (A : Distance_Km; E : Real) return Distance_Km;
--  r_a = a(1 + e)

function Radius_At_True_Anomaly (P : Distance_Km;
                                  E : Real;
                                  Nu : Angle_Radians) return Distance_Km;
--  r = p / (1 + e*cos(nu)) (Hale Eq. 3.4)
```

---

## Orbital Elements

**Package:** `Hale_Orbital.Elements`
**SPARK Mode:** On
**Reference:** Hale Chapter 4

### State-Elements Conversion

```ada
function State_To_Elements (R : Position_Vector;
                            V : Velocity_Vector;
                            Mu : Gravitational_Parameter) return Orbital_Elements;
--  Convert Cartesian state to Keplerian elements

function Elements_To_State (Elements : Orbital_Elements;
                            Mu : Gravitational_Parameter) return State_Vector;
--  Convert Keplerian elements to Cartesian state
```

### Anomaly Conversions

```ada
function True_To_Eccentric_Anomaly (Nu : Angle_Radians;
                                    E : Real) return Angle_Radians;

function Eccentric_To_True_Anomaly (Ecc_Anom : Angle_Radians;
                                    E : Real) return Angle_Radians;

function Mean_To_True_Anomaly (M : Angle_Radians;
                               E : Real;
                               Tolerance : Real := Default_Tolerance) return Angle_Radians;
```

---

## Kepler Solvers

**Package:** `Hale_Orbital.Kepler`
**SPARK Mode:** On
**Reference:** Hale Chapter 4

### Kepler's Equation Solvers

```ada
function Solve_Kepler_Elliptic (M : Angle_Radians;
                                 E : Real;
                                 Tolerance : Real := Default_Tolerance) return Angle_Radians;
--  Solve M = E_anom - e*sin(E_anom) for E_anom
--  Uses Newton-Raphson iteration

function Solve_Kepler_Hyperbolic (M : Real;
                                   E : Real;
                                   Tolerance : Real := Default_Tolerance) return Real;
--  Solve M = e*sinh(H) - H for H
```

### Universal Variable Formulation

```ada
function Solve_Kepler_Universal (R0 : Position_Vector;
                                  V0 : Velocity_Vector;
                                  Dt : Time_Seconds;
                                  Mu : Gravitational_Parameter) return State_Vector;
--  Propagate state using universal variable (chi)
```

---

## Lambert Problem

**Package:** `Hale_Orbital.Lambert`
**SPARK Mode:** On
**Reference:** Hale Chapter 5

### Lambert Result Type

```ada
type Lambert_Result is record
   V1         : Velocity_Vector;  -- Departure velocity at R1
   V2         : Velocity_Vector;  -- Arrival velocity at R2
   A          : Distance_Km;      -- Semi-major axis
   E          : Real;             -- Eccentricity
   Iterations : Natural;          -- Convergence iterations
   Converged  : Boolean;          -- Success flag
end record;
```

### Single-Revolution Solver

```ada
function Solve_Lambert (R1 : Position_Vector;
                        R2 : Position_Vector;
                        Tof : Time_Seconds;
                        Mu : Gravitational_Parameter;
                        Long_Way : Boolean := False;
                        Tolerance : Real := Default_Tolerance) return Lambert_Result
   with Pre => Magnitude (R1) > 0.0
               and Magnitude (R2) > 0.0
               and Real (Tof) > 0.0;
```

### Multi-Revolution Solver

```ada
function Solve_Lambert_Multi (R1 : Position_Vector;
                              R2 : Position_Vector;
                              Tof : Time_Seconds;
                              Mu : Gravitational_Parameter;
                              Max_Revs : Natural := 0;
                              Long_Way : Boolean := False) return Lambert_Solution_Array;
--  Returns all valid solutions including N-revolution transfers
--  Each N-rev case has short-period and long-period solutions
```

### Utility Functions

```ada
function Is_Degenerate_Transfer (R1 : Position_Vector;
                                  R2 : Position_Vector) return Boolean;
--  Detects 180-degree collinear transfers

function Min_Tof_N_Revs (R1 : Position_Vector;
                         R2 : Position_Vector;
                         Mu : Gravitational_Parameter;
                         N_Revs : Natural) return Time_Seconds;
--  Minimum TOF for N complete revolutions

function Transfer_Angle (R1 : Position_Vector;
                         R2 : Position_Vector;
                         Long_Way : Boolean := False) return Angle_Radians;
```

### Delta-V Computation

```ada
function Departure_Delta_V (V_Initial : Velocity_Vector;
                            Result : Lambert_Result) return Velocity_Km_S;

function Arrival_Delta_V (V_Final : Velocity_Vector;
                          Result : Lambert_Result) return Velocity_Km_S;

function Total_Delta_V (V_Initial : Velocity_Vector;
                        V_Final : Velocity_Vector;
                        Result : Lambert_Result) return Velocity_Km_S;
```

---

## Orbital Maneuvers

**Package:** `Hale_Orbital.Maneuvers`
**SPARK Mode:** On, Pure
**Reference:** Hale Chapter 6

### Hohmann Transfer

```ada
type Hohmann_Result is record
   Delta_V1       : Velocity_Km_S;   -- First burn
   Delta_V2       : Velocity_Km_S;   -- Second burn
   Total_Delta_V  : Velocity_Km_S;   -- Total
   Transfer_Time  : Time_Seconds;    -- Half period
   A_Transfer     : Distance_Km;     -- Transfer SMA
   E_Transfer     : Real;            -- Transfer eccentricity
end record;

function Hohmann_Transfer (R_Initial : Distance_Km;
                           R_Final : Distance_Km;
                           Mu : Gravitational_Parameter) return Hohmann_Result;

function Hohmann_Total_Delta_V (R_Initial : Distance_Km;
                                 R_Final : Distance_Km;
                                 Mu : Gravitational_Parameter) return Velocity_Km_S;
```

### Bi-Elliptic Transfer

```ada
function Bielliptic_Transfer (R_Initial : Distance_Km;
                              R_Final : Distance_Km;
                              R_Intermediate : Distance_Km;
                              Mu : Gravitational_Parameter) return Bielliptic_Result;

function Bielliptic_Is_Efficient (R_Initial : Distance_Km;
                                   R_Final : Distance_Km) return Boolean;
--  True when R_Final/R_Initial > 11.94
```

### Plane Change

```ada
function Simple_Plane_Change (Delta_I : Angle_Radians;
                              V : Velocity_Km_S) return Velocity_Km_S;
--  Delta-V = 2 * V * sin(Delta_I / 2)

function Combined_Plane_Change (R_Initial : Distance_Km;
                                R_Final : Distance_Km;
                                Delta_I : Angle_Radians;
                                Mu : Gravitational_Parameter) return Velocity_Km_S;
```

### Phasing Maneuvers

```ada
function Phasing_Orbit_SMA (R_Orbit : Distance_Km;
                            Phase_Angle : Angle_Radians;
                            N_Orbits : Positive;
                            Mu : Gravitational_Parameter) return Distance_Km;

function Phasing_Delta_V (R_Orbit : Distance_Km;
                          Phase_Angle : Angle_Radians;
                          N_Orbits : Positive;
                          Mu : Gravitational_Parameter) return Velocity_Km_S;
```

### Escape and Capture

```ada
function Escape_Delta_V (R : Distance_Km;
                         Mu : Gravitational_Parameter) return Velocity_Km_S;

function C3_Energy (V_Infinity : Velocity_Km_S) return Specific_Energy;
--  C3 = V_infinity^2

function Departure_Velocity (R : Distance_Km;
                             C3 : Specific_Energy;
                             Mu : Gravitational_Parameter) return Velocity_Km_S;
```

---

## Numerical Propagation

**Package:** `Hale_Orbital.Propagation`
**SPARK Mode:** Off (uses generics)
**Reference:** Vallado Chapter 8

### Force Models

```ada
type Force_Model is interface;

type Two_Body_Model is new Force_Model with record
   Mu : Gravitational_Parameter;
end record;

type J2_Model is new Force_Model with record
   Mu   : Gravitational_Parameter;
   J2   : Real;
   R_Eq : Distance_Km;
end record;
```

### RK4 Fixed-Step Propagator

```ada
function Propagate_RK4 (Initial : State_Vector;
                        T_Start : Time_Seconds;
                        T_End : Time_Seconds;
                        Step : Time_Seconds;
                        Model : Force_Model'Class) return State_Vector;
```

### RK78 Adaptive-Step Propagator

```ada
function Propagate_RK78 (Initial : State_Vector;
                         T_Start : Time_Seconds;
                         T_End : Time_Seconds;
                         Tolerance : Real;
                         Model : Force_Model'Class) return State_Vector;
--  Dormand-Prince 7(8) with automatic step size control
```

### Parallel Propagation (Ada 2022)

```ada
type State_Array is array (Positive range <>) of State_Vector;

function Propagate_Parallel (Samples : State_Array;
                             T_Start : Time_Seconds;
                             T_End : Time_Seconds;
                             Tolerance : Real;
                             Model : Two_Body_Model) return State_Array;
--  Monte Carlo ensemble propagation using Ada 2022 parallel loops

function Compute_Statistics (States : State_Array) return Statistics_Record;
--  Mean, std dev, min/max radius for uncertainty quantification
```

### Energy Conservation

```ada
function Conserved_Energy (State : State_Vector;
                           Mu : Gravitational_Parameter) return Specific_Energy;

function Energy_Error (Initial : State_Vector;
                       Final : State_Vector;
                       Mu : Gravitational_Parameter) return Real;
--  Relative energy error for validation
```

---

## Three-Body Dynamics

**Package:** `Hale_Orbital.Threebody`
**SPARK Mode:** Off

### Lagrange Points

```ada
type Lagrange_Point is (L1, L2, L3, L4, L5);

type Lagrange_Result is record
   X, Y : Real;  -- Normalized coordinates
end record;

function Compute_Lagrange_Point (System : CR3BP_System;
                                  Point : Lagrange_Point) return Lagrange_Result;
```

### Stability Analysis

```ada
function Analyze_Stability (System : CR3BP_System;
                            Point : Lagrange_Point) return Stability_Result;

function Jacobi_Constant (State : Normalized_State;
                          Mu : Real) return Real;
--  Conserved quantity in CR3BP
```

### Predefined Systems

```ada
Earth_Moon_System : constant CR3BP_System;
Sun_Earth_System  : constant CR3BP_System;
Sun_Jupiter_System : constant CR3BP_System;
```

---

## Stumpff Functions

**Package:** `Hale_Orbital.Stumpff`
**SPARK Mode:** On, Pure

```ada
function C (Z : Real) return Real
   with Post => C'Result >= 0.0;
--  C(z) = (1 - cos(sqrt(z))) / z  for z > 0
--  C(z) = (cosh(sqrt(-z)) - 1) / (-z)  for z < 0
--  C(0) = 1/2

function S (Z : Real) return Real
   with Post => S'Result >= 0.0;
--  S(z) = (sqrt(z) - sin(sqrt(z))) / sqrt(z^3)  for z > 0
--  S(z) = (sinh(sqrt(-z)) - sqrt(-z)) / sqrt((-z)^3)  for z < 0
--  S(0) = 1/6
```

---

## Interplanetary Trajectories

**Package:** `Hale_Orbital.Interplanetary`
**SPARK Mode:** On
**Reference:** Hale Chapters 7-8, Vallado Chapter 12

### Planetary Data

```ada
type Planet_Type is (Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune);

type Planet_Data is record
   Name            : String (1 .. 10);
   Mu              : Gravitational_Parameter;  -- GM (km^3/s^2)
   Semi_Major_Axis : Distance_Km;              -- Heliocentric orbit (km)
   Eccentricity    : Real;                     -- Orbital eccentricity
   Radius          : Distance_Km;              -- Mean radius (km)
   SOI_Radius      : Distance_Km;              -- Sphere of influence (km)
end record;

function Get_Planet_Data (Planet : Planet_Type) return Planet_Data;
```

### Sphere of Influence

```ada
function Sphere_Of_Influence (A_Planet  : Distance_Km;
                               Mu_Planet : Gravitational_Parameter;
                               Mu_Star   : Gravitational_Parameter := Mu_Sun) return Distance_Km;
--  r_SOI = a * (m_planet / m_sun)^(2/5)  (Laplace formula)

function Within_SOI (R_From_Planet : Distance_Km;
                     Planet        : Planet_Type) return Boolean;
```

### Hyperbolic Trajectory Parameters

```ada
function Hyperbolic_Excess_Velocity (V_Total : Velocity_Km_S;
                                     R       : Distance_Km;
                                     Mu      : Gravitational_Parameter) return Velocity_Km_S;
--  V_inf = sqrt(V^2 - 2*mu/r)

function V_Infinity_From_C3 (C3 : Specific_Energy) return Velocity_Km_S;
function C3_From_V_Infinity (V_Inf : Velocity_Km_S) return Specific_Energy;

function Hyperbolic_Periapsis_Velocity (V_Infinity  : Velocity_Km_S;
                                        R_Periapsis : Distance_Km;
                                        Mu          : Gravitational_Parameter) return Velocity_Km_S;

function Hyperbolic_Semi_Major_Axis (V_Infinity : Velocity_Km_S;
                                     Mu         : Gravitational_Parameter) return Distance_Km;
--  a_hyp = -mu / V_inf^2 (negative for hyperbola)

function Turn_Angle (V_Infinity  : Velocity_Km_S;
                     R_Periapsis : Distance_Km;
                     Mu          : Gravitational_Parameter) return Angle_Radians;
--  Deflection angle for hyperbolic flyby
```

### Patched Conic Transfers

```ada
type Patched_Conic_Result is record
   Departure_C3       : Specific_Energy;    -- Launch energy (C3)
   Departure_V_Inf    : Velocity_Km_S;      -- V_infinity at departure
   Departure_DV       : Velocity_Km_S;      -- Delta-V from parking orbit
   Transfer_TOF       : Time_Seconds;       -- Heliocentric time of flight
   Transfer_SMA       : Distance_Km;        -- Transfer orbit semi-major axis
   Transfer_Ecc       : Real;               -- Transfer orbit eccentricity
   Arrival_V_Inf      : Velocity_Km_S;      -- V_infinity at arrival
   Arrival_C3         : Specific_Energy;    -- Arrival energy
   Capture_DV         : Velocity_Km_S;      -- Delta-V for orbit insertion
   Total_DV           : Velocity_Km_S;      -- Total mission delta-V
   Valid              : Boolean;            -- Solution validity flag
end record;

function Compute_Patched_Conic (Departure_Planet  : Planet_Type;
                                 Arrival_Planet    : Planet_Type;
                                 Time_Of_Flight    : Time_Seconds;
                                 Parking_Altitude  : Distance_Km;
                                 Capture_Altitude  : Distance_Km) return Patched_Conic_Result;

function Hohmann_Interplanetary (Departure_Planet : Planet_Type;
                                 Arrival_Planet   : Planet_Type) return Patched_Conic_Result;
```

### Gravity Assist (Flyby)

```ada
type Flyby_Result is record
   Turn_Angle     : Angle_Radians;   -- Deflection angle
   Delta_V_Gain   : Velocity_Km_S;   -- Effective delta-V from flyby
   Exit_V_Inf     : Velocity_Km_S;   -- Exit V_infinity magnitude
   R_Periapsis    : Distance_Km;     -- Closest approach distance
   Valid          : Boolean;         -- Flyby is valid (above surface)
end record;

function Compute_Flyby (V_Infinity_In : Velocity_Km_S;
                        R_Periapsis   : Distance_Km;
                        Planet        : Planet_Type) return Flyby_Result;

function Maximum_Flyby_DeltaV (V_Infinity : Velocity_Km_S;
                                Planet     : Planet_Type) return Velocity_Km_S;
```

### Launch Windows

```ada
function Synodic_Period (Inner_Planet : Planet_Type;
                         Outer_Planet : Planet_Type) return Time_Seconds;
--  Time between successive alignments

function Hohmann_Phase_Angle (Departure_Planet : Planet_Type;
                              Arrival_Planet   : Planet_Type) return Angle_Radians;
--  Required phase angle for minimum-energy transfer
```

---

## Usage Examples

### Hohmann Transfer

```ada
with Hale_Orbital.Types;     use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Maneuvers; use Hale_Orbital.Maneuvers;

procedure Example is
   R_LEO : constant Distance_Km := R_Earth + 200.0;
   Result : Hohmann_Result;
begin
   Result := Hohmann_Transfer (R_LEO, R_GEO, Mu_Earth);
   --  Result.Total_Delta_V ≈ 3.935 km/s (Hale Table 6-1)
end Example;
```

### Lambert Problem

```ada
with Hale_Orbital.Lambert; use Hale_Orbital.Lambert;

procedure Intercept is
   R1 : constant Position_Vector := (7000.0, 0.0, 0.0);
   R2 : constant Position_Vector := (0.0, 10000.0, 0.0);
   Tof : constant Time_Seconds := 3600.0;
   Result : Lambert_Result;
begin
   Result := Solve_Lambert (R1, R2, Tof, Mu_Earth);
   if Result.Converged then
      --  Use Result.V1 for departure velocity
   end if;
end Intercept;
```

### Orbit Propagation

```ada
with Hale_Orbital.Propagation; use Hale_Orbital.Propagation;

procedure Propagate is
   Model : constant Two_Body_Model := (Mu => Mu_Earth);
   Initial : State_Vector := ((7000.0, 0.0, 0.0), (0.0, 7.5, 0.0));
   Final : State_Vector;
begin
   Final := Propagate_RK78 (Initial, 0.0, 5400.0, 1.0e-12, Model);
end Propagate;
```

### Interplanetary Transfer

```ada
with Hale_Orbital.Interplanetary; use Hale_Orbital.Interplanetary;

procedure Mars_Mission is
   Result : Patched_Conic_Result;
begin
   --  Compute Earth-Mars Hohmann transfer
   Result := Hohmann_Interplanetary (Earth, Mars);

   --  C3 energy requirement (km^2/s^2)
   --  Result.Departure_C3 ≈ 8.6 km^2/s^2

   --  Total delta-V requirement
   --  Result.Total_DV ≈ 5.6 km/s (from 200 km parking orbit)
end Mars_Mission;
```

### Gravity Assist

```ada
with Hale_Orbital.Interplanetary; use Hale_Orbital.Interplanetary;

procedure Jupiter_Flyby is
   Result : Flyby_Result;
   V_In   : constant Velocity_Km_S := 10.0;  -- V_infinity at Jupiter
begin
   --  Compute minimum-radius flyby
   Result := Compute_Flyby (V_In, Minimum_Flyby_Radius (Jupiter), Jupiter);

   --  Maximum delta-V gain from Jupiter flyby
   --  Result.Delta_V_Gain can exceed 20 km/s
end Jupiter_Flyby;
```

---

## Performance Notes

- All maneuver functions are inlined (`pragma Inline`)
- Tolerance default: `1.0e-12` for iterative solvers
- Maximum iterations default: 50 for Newton-Raphson
- Parallel propagation uses Ada 2022 `parallel for` loops
- Target performance: Hohmann < 100 ns, Lambert < 10 us

---

## SPARK Verification

Core computational packages have `SPARK_Mode => On`:
- Types, Constants, Vectors, Matrices
- Twobody, Elements, Kepler, Lambert (spec)
- Maneuvers, Stumpff, Interplanetary

Bodies with generic instantiation or exceptions use `SPARK_Mode => Off`.
Package bodies that use Ada.Numerics.Generic_Elementary_Functions have SPARK_Mode => Off
because generic instantiation is not supported in SPARK 2014.

Pre/Post contracts are provided for numerical stability:
```ada
function Solve_Lambert (...)
   with Pre  => Magnitude (R1) > 0.0 and Real (Tof) > 0.0,
        Post => (if Solve_Lambert'Result.Converged then
                   Solve_Lambert'Result.Iterations <= 100);
```

---

## Exception Handling

This section documents all exceptions that can be raised and their triggering conditions.
See [DEC-006](rationale/DEC-006-error-handling.md) for the error handling design rationale.

### Exception Taxonomy

| Exception | Package | Condition | Recovery |
|-----------|---------|-----------|----------|
| `Convergence_Error` | Types | Iterative solver fails within max iterations | Use wider tolerance or different initial guess |
| `Invalid_Orbit` | Types | Physically impossible orbit parameters | Validate input state vectors |
| `Physical_Error` | Types | Calculation violates physics (negative mass, etc.) | Check input constraints |
| `Singularity_Error` | Types | Division by near-zero denominator | Avoid degenerate geometries |

### Exception Conditions by Function

#### Kepler Solvers (Hale_Orbital.Kepler)

| Function | Exception | Condition |
|----------|-----------|-----------|
| `Solve_Kepler_Elliptic` | `Convergence_Error` | |F| > tolerance after 50 iterations |
| `Solve_Kepler_Elliptic` | `Singularity_Error` | |1 - e*cos(E)| < 1.0e-15 (F' near zero) |
| `Solve_Kepler_Hyperbolic` | `Convergence_Error` | |F| > tolerance after 50 iterations |
| `Solve_Kepler_Hyperbolic` | `Singularity_Error` | |e*cosh(H) - 1| < 1.0e-15 |
| `Solve_Kepler_Parabolic` | `Convergence_Error` | |F| > tolerance after 50 iterations |
| `Solve_Kepler_Universal` | `Convergence_Error` | No convergence after 50 iterations |

#### Lambert Solver (Hale_Orbital.Lambert)

| Function | Exception | Condition |
|----------|-----------|-----------|
| `Solve_Lambert` | `Invalid_Orbit` | R1 or R2 magnitude ≤ 0 |
| `Solve_Lambert` | `Invalid_Orbit` | TOF ≤ 0 |
| `Solve_Lambert` | `Convergence_Error` | Bisection fails in 50 iterations |
| `Solve_Lambert` | `Singularity_Error` | Degenerate 180° transfer detected |

#### Two-Body Functions (Hale_Orbital.Twobody)

| Function | Exception | Condition |
|----------|-----------|-----------|
| `Specific_Energy` | `Singularity_Error` | |R| < 1.0e-15 km |
| `Semi_Major_Axis` | `Singularity_Error` | |2/r - v²/μ| < 1.0e-15 (parabolic) |
| `Vis_Viva` | `Invalid_Orbit` | R ≤ 0 or |A| < 1.0e-15 |
| `Orbital_Period` | `Invalid_Orbit` | A ≤ 0 (non-elliptic) |
| `Radius_At_True_Anomaly` | `Singularity_Error` | |1 + e*cos(ν)| < 1.0e-15 |

#### Element Conversions (Hale_Orbital.Elements)

| Function | Exception | Condition |
|----------|-----------|-----------|
| `State_To_Elements` | `Invalid_Orbit` | Zero angular momentum (radial orbit) |
| `State_To_Elements` | `Singularity_Error` | Unable to compute eccentricity |
| `Elements_To_State` | `Invalid_Orbit` | e < 0 or invalid SMA for orbit type |

#### Propagation (Hale_Orbital.Propagation)

| Function | Exception | Condition |
|----------|-----------|-----------|
| `Propagate_RK4` | `Physical_Error` | Step size ≤ 0 |
| `Propagate_RK78` | `Convergence_Error` | Step size underflow (< 1.0e-12 s) |

### Contract Violation Exceptions

Pre-condition violations raise `Assertion_Error` (standard Ada behavior). This occurs when:
- Passing zero-magnitude vectors to functions requiring non-zero inputs
- Providing negative gravitational parameters
- Specifying invalid eccentricity ranges for orbit type

**Best Practice:** Always validate inputs before calling library functions in safety-critical code.

---

## Performance Requirements

This section documents performance characteristics for timing-critical applications.
See [NFR-PERF requirements](certification/rtm.md#11-non-functional-requirements) for formal specifications.

### Timing Bounds (Reference: AMD Ryzen 7 @ 3.6 GHz)

| Function | Typical Time | Worst Case | Max Iterations |
|----------|--------------|------------|----------------|
| Hohmann_Transfer | < 50 ns | < 100 ns | N/A (closed-form) |
| Bielliptic_Transfer | < 100 ns | < 200 ns | N/A (closed-form) |
| Solve_Kepler_Elliptic (e<0.8) | < 200 ns | < 500 ns | 10 |
| Solve_Kepler_Elliptic (e>0.8) | < 500 ns | < 2 μs | 20 |
| Solve_Kepler_Universal | < 1 μs | < 5 μs | 50 |
| Solve_Lambert | < 5 μs | < 20 μs | 50 |
| Solve_Lambert_Multi (N=2) | < 50 μs | < 100 μs | 50 per solution |
| Propagate_RK4 (1 orbit) | < 1 ms | < 5 ms | N/A |
| Propagate_RK78 (1 orbit) | < 2 ms | < 10 ms | Adaptive |

### Iteration Guarantees

| Solver | Max Iterations | Termination Guarantee |
|--------|----------------|----------------------|
| Newton-Raphson (Kepler) | 50 | Always terminates |
| Laguerre (high-e Kepler) | 50 | Always terminates |
| Bisection (Lambert) | 50 | Always terminates (2⁵⁰ ≈ 10¹⁵ precision) |
| Newton (Lambert refinement) | 20 | Always terminates |

### Memory Usage

| Operation | Stack | Heap |
|-----------|-------|------|
| Scalar functions | < 1 KB | None |
| Vector/Matrix operations | < 2 KB | None |
| State propagation (RK4) | < 4 KB | None |
| Lambert multi-rev (N=5) | < 8 KB | Array allocation |
| Parallel propagation | < 16 KB per task | Sample array |

### Real-Time Considerations

1. **No dynamic allocation** in core computational packages (Maneuvers, Stumpff, Kepler solvers)
2. **Bounded iteration counts** guarantee termination
3. **No recursion** in SPARK-verified code paths
4. **Deterministic floating-point** available via build mode

---

## Numerical Accuracy by Orbital Regime

This section provides accuracy guidance specific to different orbital scenarios.
See [DEC-009](rationale/DEC-009-numerical-thresholds.md) for threshold derivations.

### Accuracy Classification

| Regime | Accuracy | Notes |
|--------|----------|-------|
| LEO Circular | Excellent (12+ digits) | Well-conditioned |
| LEO Elliptical (e<0.1) | Excellent (12+ digits) | Well-conditioned |
| HEO (e>0.7) | Good (10+ digits) | Use Laguerre for Kepler |
| Near-Parabolic (|e-1|<1e-6) | Fair (8+ digits) | Use universal variables |
| Hyperbolic | Good (10+ digits) | Watch for high V∞ |
| Three-Body (CR3BP) | Good (10+ digits) | Jacobi constant preserved |

### Regime-Specific Recommendations

#### Low Earth Orbit (LEO)

- **Eccentricity:** 0 ≤ e ≤ 0.1 typical
- **Recommended tolerance:** 1.0e-12 (default)
- **Propagation step:** ≤ 60 seconds for RK4
- **Accuracy achieved:** Position < 1 meter per orbit
- **Notes:** J2 perturbation significant for >1 day propagations

```ada
--  LEO example configuration
Tolerance : constant := 1.0e-12;
Step      : constant := 60.0;  -- seconds
```

#### Geostationary (GEO)

- **Eccentricity:** < 0.001 nominal
- **Recommended tolerance:** 1.0e-12
- **Propagation step:** ≤ 300 seconds for RK4
- **Accuracy achieved:** Position < 100 meters per day
- **Notes:** Near-circular formulas safe; avoid ω/Ω at low inclination

#### Highly Elliptical Orbit (HEO)

- **Eccentricity:** 0.6 ≤ e ≤ 0.9 typical (Molniya, Tundra)
- **Recommended tolerance:** 1.0e-10 (looser for speed)
- **Propagation step:** Variable (small near periapsis)
- **Accuracy achieved:** Position < 1 km at apoapsis
- **Notes:** Kepler solver may need 10-15 iterations; use RK78 adaptive

```ada
--  HEO example: use adaptive propagator
Final := Propagate_RK78 (Initial, T0, T_End, 1.0e-10, Model);
```

#### Near-Parabolic (e ≈ 1.0)

- **Classification threshold:** |e - 1| < 1.0e-10 treated as parabolic
- **Recommended approach:** Universal variable formulation
- **Tolerance:** 1.0e-10 (higher due to conditioning)
- **Accuracy achieved:** Limited by definition (SMA → ∞)
- **Notes:** Period undefined; use time-of-flight methods

#### Hyperbolic Trajectories

- **Eccentricity:** e > 1.0
- **Recommended tolerance:** 1.0e-12
- **Accuracy achieved:** V∞ to 0.1 mm/s for interplanetary
- **Notes:** Use `Solve_Kepler_Hyperbolic` or universal variables

#### Three-Body (CR3BP)

- **Accuracy metric:** Jacobi constant conservation
- **Recommended tolerance:** 1.0e-12 for integrator
- **Expected conservation:** |ΔC| < 1.0e-10 over 10 periods
- **Notes:** Use symplectic integrator for long-term stability studies

### Condition Numbers and Numerical Sensitivity

| Operation | Condition Number | Sensitive When |
|-----------|------------------|----------------|
| r = p/(1+e·cos ν) | κ = 1/|1+e·cos ν| | ν → π, e → 1 |
| E from M (elliptic) | κ = 1/|1-e·cos E| | E → 0, e → 1 |
| SMA from energy | κ = |2r/(2-rv²/μ)| | Parabolic (ε → 0) |
| Lambert z-parameter | κ ∝ |dF/dz|⁻¹ | Near minimum TOF |

### Recommended Tolerances by Application

| Application | Position Tol | Velocity Tol | Solver Tol |
|-------------|--------------|--------------|------------|
| Mission planning | 1 km | 1 m/s | 1.0e-10 |
| Conjunction screening | 100 m | 0.1 m/s | 1.0e-11 |
| Navigation/OD | 10 m | 0.01 m/s | 1.0e-12 |
| Precision maneuvers | 1 m | 0.001 m/s | 1.0e-12 |
| Validation/Reference | 0.1 m | 0.0001 m/s | 1.0e-14 |

---

## Build Modes and Determinism

This section documents build configuration options and their effects on numerical behavior.

### Available Build Modes

| Mode | Flag | Purpose | Performance | Determinism |
|------|------|---------|-------------|-------------|
| Debug | `-g -O0` | Development/debugging | Slow | Platform-dependent |
| Release | `-O2 -gnatn` | Production use | Fast | Platform-dependent |
| SPARK | `--mode=prove` | Formal verification | N/A | N/A |
| **Deterministic** | `-msse2 -mfpmath=sse` | Cross-platform reproducibility | ~5% slower | **Guaranteed** |

### Deterministic Mode

**Purpose:** Guarantee identical floating-point results across different:
- CPU architectures (Intel, AMD, ARM via emulation)
- Compiler versions
- Operating systems
- Optimization levels

**Usage:**
```bash
gprbuild -XBUILD_MODE=deterministic hale_orbital.gpr
```

**Guarantees:**
1. No x87 extended precision (80-bit) intermediate results
2. Strict IEEE 754 double precision (64-bit) throughout
3. Fused multiply-add (FMA) disabled
4. Reproducible across runs and platforms

**Trade-offs:**
- ~5% performance penalty vs optimized release build
- No exploitation of CPU-specific fast paths
- Some loss of precision in long chains (no 80-bit intermediates)

### Floating-Point Behavior Comparison

| Aspect | Standard Mode | Deterministic Mode |
|--------|---------------|-------------------|
| Intermediate precision | 80-bit x87 possible | 64-bit IEEE 754 strict |
| FMA operations | May be used | Disabled |
| Result reproducibility | Same CPU only | Cross-platform |
| Suitable for | Performance-critical | Certification, validation |

### When to Use Deterministic Mode

**Use deterministic mode when:**
- Running validation test suites
- Comparing results across different machines
- Certification evidence generation
- Debugging numerical discrepancies
- Regression testing with exact values

**Use standard release mode when:**
- Performance is critical
- Running on consistent hardware
- Results compared within tolerances (not exact)

### Compiler Flags Reference

```ada
--  deterministic.gpr excerpt
package Compiler is
   case Build_Mode is
      when "deterministic" =>
         for Default_Switches ("Ada") use
           ("-O2", "-gnatn",        --  Optimization
            "-msse2", "-mfpmath=sse",  --  SSE math only
            "-ffp-contract=off",    --  No FMA
            "-fno-fast-math");      --  Strict IEEE 754
   end case;
end Compiler;
```

### Verification of Determinism

The test suite includes determinism verification:
```ada
--  From hale_tests-determinism.adb
procedure Test_Cross_Platform_Determinism is
   Expected_Position : constant Vector_3D :=
     (6778.137_000_000_001, 0.0, 0.0);  --  Reference value
begin
   --  Exact bit-for-bit comparison (deterministic mode only)
   Assert (Actual = Expected, "Determinism violation detected");
end Test_Cross_Platform_Determinism;
```

---

## Version Information

| Document | Version | Date |
|----------|---------|------|
| API Reference | 1.1 | 2026-01-06 |
| Library Version | 1.0.0 | 2026-01-06 |

### Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-05 | Initial release |
| 1.1 | 2026-01-06 | Added exception handling, performance, accuracy, and determinism sections |
