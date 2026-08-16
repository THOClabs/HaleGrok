# HALE Orbital Mechanics - Type System Design

*Compile-time dimensional correctness for orbital mechanics*

---

## Overview

The HALE type system prevents unit confusion errors at compile time through Ada's strong typing. A Mars Climate Orbiter-style error (mixing metric and imperial) is impossible with this type system.

---

## Type Hierarchy

```
Long_Float (64-bit IEEE 754)
    │
    └── Real (library base type)
            │
            ├── Distance_Km         -- Position measurements
            ├── Velocity_Km_S       -- Velocity measurements
            ├── Time_Seconds        -- Time intervals
            ├── Angle_Radians       -- Angular measurements
            ├── Mass_Kg             -- Mass values
            ├── Gravitational_Parameter  -- km³/s²
            ├── Specific_Energy     -- km²/s² (vis-viva)
            └── Specific_Angular_Momentum -- km²/s
```

---

## Dimensional Types

### Distance_Km

```ada
type Distance_Km is new Real;
```

Used for:
- Orbital radii (semi-major axis, periapsis, apoapsis)
- Position vector components
- Sphere of influence radii

**Example:**
```ada
R_Earth : constant Distance_Km := 6378.137;
Altitude : Distance_Km := 400.0;
Radius : Distance_Km := R_Earth + Altitude;  -- OK
```

### Velocity_Km_S

```ada
type Velocity_Km_S is new Real;
```

Used for:
- Orbital velocities
- Delta-V magnitudes
- Escape velocities

**Example:**
```ada
V_Circular : Velocity_Km_S := Circular_Velocity (R_Earth + 400.0, Mu_Earth);
Delta_V : Velocity_Km_S := 2.5;
```

### Time_Seconds

```ada
type Time_Seconds is new Real;
```

Used for:
- Orbital periods
- Time of flight
- Propagation intervals

**Example:**
```ada
Period : Time_Seconds := Orbital_Period (Elements.Semi_Major_Axis, Mu_Earth);
TOF : Time_Seconds := 3600.0 * 24.0;  -- One day
```

### Angle_Radians

```ada
type Angle_Radians is new Real;
```

Used for:
- All angular quantities internally
- True anomaly, mean anomaly, eccentric anomaly
- Orbital elements (i, RAAN, omega, nu)

**Note:** User-facing documentation uses degrees, but all internal calculations use radians.

---

## Composite Types

### Vector_3D

```ada
type Vector_3D is array (1 .. 3) of Real;
```

Generic 3D vector used for position and velocity. Subtypes provide semantic clarity:

```ada
subtype Position_Vector is Vector_3D;  -- km
subtype Velocity_Vector is Vector_3D;  -- km/s
```

**Operations:**
```ada
function Magnitude (V : Vector_3D) return Real;
function Normalize (V : Vector_3D) return Vector_3D;
function Dot (A, B : Vector_3D) return Real;
function Cross (A, B : Vector_3D) return Vector_3D;
```

### State_Vector

```ada
type State_Vector is record
   Position : Position_Vector;  -- km
   Velocity : Velocity_Vector;  -- km/s
end record;
```

Complete state for propagation and element conversion.

### Orbital_Elements

```ada
type Orbital_Elements is record
   Semi_Major_Axis       : Distance_Km;     -- a
   Eccentricity          : Real;            -- e (dimensionless)
   Inclination           : Angle_Radians;   -- i
   RAAN                  : Angle_Radians;   -- Omega
   Argument_Of_Periapsis : Angle_Radians;   -- omega
   True_Anomaly          : Angle_Radians;   -- nu
end record;
```

Classical Keplerian elements following aerospace conventions.

---

## Type Safety Examples

### Prevented: Unit Mixing

```ada
D : Distance_Km := 1000.0;
V : Velocity_Km_S := 7.5;
T : Time_Seconds := D / V;  -- COMPILE ERROR: type mismatch
```

**Resolution:** Use explicit conversion or compute via library functions:
```ada
T : Time_Seconds := Time_Seconds (Real (D) / Real (V));  -- Explicit
```

### Prevented: Dimensionless Confusion

```ada
function Scale_Orbit (A : Distance_Km; Factor : Real) return Distance_Km is
begin
   return Distance_Km (Real (A) * Factor);  -- Explicit conversion
end Scale_Orbit;
```

### Allowed: Same-Type Operations

```ada
R1 : Distance_Km := 7000.0;
R2 : Distance_Km := 42164.0;
Delta_R : Distance_Km := R2 - R1;  -- OK: same types
```

---

## Type Conversion Patterns

### Explicit Conversion

When mixing dimensional types is mathematically correct:

```ada
--  Period = 2 * Pi * sqrt(a^3 / mu)
--  Units: s = sqrt(km³ / (km³/s²)) = sqrt(s²) = s
function Orbital_Period (A : Distance_Km; Mu : Gravitational_Parameter)
   return Time_Seconds
is
   A_Real : constant Real := Real (A);
   Mu_Real : constant Real := Real (Mu);
begin
   return Time_Seconds (Two_Pi * Sqrt (A_Real ** 3 / Mu_Real));
end Orbital_Period;
```

### Function-Based Conversion

Prefer library functions that handle units correctly:

```ada
--  Instead of manual calculation:
V : Velocity_Km_S := Circular_Velocity (Radius, Mu_Earth);
E : Specific_Energy := Specific_Mechanical_Energy (State, Mu_Earth);
```

---

## Enumeration Types

### Orbit_Type

```ada
type Orbit_Type is (Circular, Elliptical, Parabolic, Hyperbolic);
```

Determined by eccentricity:
- `Circular`: e < 1e-10
- `Elliptical`: 1e-10 <= e < 1 - 1e-10
- `Parabolic`: |e - 1| < 1e-10
- `Hyperbolic`: e > 1 + 1e-10

### Transfer_Direction

```ada
type Transfer_Direction is (Short_Way, Long_Way);
```

Lambert problem path selection:
- `Short_Way`: Transfer angle < 180°
- `Long_Way`: Transfer angle >= 180°

### Transfer_Type

```ada
type Transfer_Type is (Type_I, Type_II);
```

Lambert energy branch:
- `Type_I`: Low-energy (usually faster)
- `Type_II`: High-energy (usually slower)

---

## Constants

### Physical Constants

```ada
--  Gravitational parameters (km³/s²)
Mu_Sun     : constant Gravitational_Parameter := 1.32712440018e11;
Mu_Earth   : constant Gravitational_Parameter := 3.986004418e5;
Mu_Moon    : constant Gravitational_Parameter := 4.9028695e3;

--  Planetary radii (km)
R_Earth    : constant Distance_Km := 6378.137;
R_Sun      : constant Distance_Km := 695700.0;

--  Mathematical constants
Pi         : constant Real := 3.14159265358979323846;
Two_Pi     : constant Real := 2.0 * Pi;
Deg_To_Rad : constant Real := Pi / 180.0;
Rad_To_Deg : constant Real := 180.0 / Pi;
```

### Solver Parameters

```ada
Default_Tolerance      : constant Real := 1.0e-12;
Default_Max_Iterations : constant Positive := 50;
```

---

## Matrix Types

### Matrix_3x3

```ada
type Matrix_3x3 is array (1 .. 3, 1 .. 3) of Real;
```

Used for:
- Rotation matrices (coordinate transformations)
- Direction cosine matrices
- Jacobian matrices (3x3 sub-blocks)

### Matrix_6x6

```ada
type Matrix_6x6 is array (1 .. 6, 1 .. 6) of Real;
```

Used for:
- State transition matrices
- Covariance matrices
- Full Jacobians

---

## Exception Types

```ada
Convergence_Error : exception;  -- Solver failed to converge
Invalid_Orbit     : exception;  -- Unphysical orbital parameters
Physical_Error    : exception;  -- Violated physical constraints
Singularity_Error : exception;  -- Encountered mathematical singularity
```

**Usage:**
```ada
function Solve_Kepler_Elliptic (...) return Angle_Radians
   with Pre => E >= 0.0 and E < 1.0,
        Post => Solve_Kepler_Elliptic'Result in 0.0 .. Two_Pi;
--  Raises Convergence_Error if Max_Iterations exceeded
```

---

## SPARK Considerations

### Type Flow Analysis

Dimensional types enable SPARK flow analysis:

```ada
function Magnitude (V : Vector_3D) return Real
   with Global  => null,
        Depends => (Magnitude'Result => V),
        Post    => Magnitude'Result >= 0.0;
```

### Contract Support

Types support precise contracts:

```ada
function Normalize (V : Vector_3D) return Vector_3D
   with Pre  => Magnitude (V) > 0.0,
        Post => abs (Magnitude (Normalize'Result) - 1.0) < 1.0e-10;
```

---

## Design Rationale

### Why Derived Types (Not Subtypes)?

Derived types (`type Distance_Km is new Real`) prevent accidental mixing:

```ada
--  With derived types (current):
D : Distance_Km := 1000.0;
V : Velocity_Km_S := D;  -- COMPILE ERROR

--  With subtypes (rejected approach):
subtype Distance_Km is Real;
subtype Velocity_Km_S is Real;
D : Distance_Km := 1000.0;
V : Velocity_Km_S := D;  -- Compiles, but wrong!
```

### Why Long_Float Base?

- IEEE 754 double precision (64-bit)
- ~15 decimal digits precision
- Sufficient for:
  - Solar system scales (10^12 km)
  - Microsecond timing (10^-6 s)
  - Position accuracy (< 1 meter at GEO)

### Why Radians Internal?

- Trigonometric functions expect radians
- Eliminates repeated deg-to-rad conversions
- Standard in orbital mechanics literature

---

## Related Documents

- [DEC-001: Dimensional Types](../rationale/DEC-001-dimensional-types.md)
- [Package Hierarchy](package-hierarchy.md)
- [API Reference](../api-reference.md)

---

*"Strong typing is documentation that the compiler can check."* — John Barnes
