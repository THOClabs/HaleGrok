# HALE Orbital Mechanics - Ada Conversion Plan

## Executive Summary

This document outlines the plan to convert the HALE Orbital Mechanics library from Python to Ada. The conversion will produce a safety-critical, high-precision orbital mechanics library suitable for aerospace applications where Ada's strong typing and reliability guarantees are essential.

---

## 1. Project Scope

### 1.1 Current Python Codebase

| Component | Status | Lines of Code | Priority |
|-----------|--------|---------------|----------|
| Main HALE Project (Phases 1-8) | Planned/Specs Ready | ~5,000-8,000 (est.) | High |
| Three-Body Extension | Partially Implemented | ~2,740 | Medium |
| Test Infrastructure | Fixtures Ready | ~500 | High |
| Specifications | Complete | ~2,000 | Reference |

### 1.2 Conversion Targets

- **Ada Standard**: Ada 2012 (with Ada 2022 features where beneficial)
- **Compiler**: GNAT Community Edition / GNAT Pro
- **Precision**: IEEE 754 Double Precision (Long_Float)
- **Target Platforms**: Linux, Windows, RTEMS (real-time systems)

---

## 2. Ada Project Architecture

### 2.1 Proposed Package Structure

```
ada_conversion/
├── hale_orbital.gpr              -- GNAT Project file
├── src/
│   ├── hale_orbital.ads          -- Root package specification
│   ├── hale_orbital-constants.ads/adb    -- Physical constants (Phase 1)
│   ├── hale_orbital-types.ads            -- Core type definitions
│   ├── hale_orbital-vectors.ads/adb      -- 3D vector operations
│   ├── hale_orbital-matrices.ads/adb     -- Matrix operations
│   ├── hale_orbital-twobody.ads/adb      -- Two-body dynamics (Phase 2)
│   ├── hale_orbital-elements.ads/adb     -- Orbital elements (Phase 3)
│   ├── hale_orbital-kepler.ads/adb       -- Kepler's equation (Phase 4)
│   ├── hale_orbital-lambert.ads/adb      -- Lambert problem (Phase 5)
│   ├── hale_orbital-maneuvers.ads/adb    -- Orbital maneuvers (Phase 6)
│   ├── hale_orbital-interplanetary.ads/adb -- Patched conics (Phase 7)
│   ├── hale_orbital-mission.ads/adb      -- Mission integration (Phase 8)
│   └── hale_orbital-threebody/           -- Three-body extension
│       ├── hale_orbital-threebody.ads
│       ├── hale_orbital-threebody-cr3bp.ads/adb
│       ├── hale_orbital-threebody-lagrange.ads/adb
│       ├── hale_orbital-threebody-integrators.ads/adb
│       ├── hale_orbital-threebody-periodic.ads/adb
│       └── hale_orbital-threebody-stability.ads/adb
├── tests/
│   ├── hale_tests.gpr            -- Test project file
│   ├── test_constants.adb
│   ├── test_twobody.adb
│   ├── test_elements.adb
│   ├── test_kepler.adb
│   ├── test_lambert.adb
│   ├── test_maneuvers.adb
│   └── test_interplanetary.adb
└── docs/
    ├── api_reference/
    └── conversion_notes/
```

### 2.2 Core Type Definitions

```ada
-- hale_orbital-types.ads

package Hale_Orbital.Types is

   -- Precision type for all calculations
   type Real is new Long_Float;

   -- Physical dimension types (compile-time safety)
   type Distance_Km is new Real;           -- kilometers
   type Velocity_Km_S is new Real;         -- km/s
   type Time_Seconds is new Real;          -- seconds
   type Angle_Radians is new Real;         -- radians
   type Mass_Kg is new Real;               -- kilograms
   type Gravitational_Parameter is new Real; -- km^3/s^2

   -- 3D Vector types
   type Vector_3D is array (1 .. 3) of Real;
   type Position_Vector is new Vector_3D;  -- km
   type Velocity_Vector is new Vector_3D;  -- km/s

   -- State vector (position + velocity)
   type State_Vector is record
      Position : Position_Vector;
      Velocity : Velocity_Vector;
   end record;

   -- Orbital elements (classical Keplerian)
   type Orbital_Elements is record
      Semi_Major_Axis      : Distance_Km;        -- a
      Eccentricity         : Real;               -- e (dimensionless)
      Inclination          : Angle_Radians;      -- i
      RAAN                 : Angle_Radians;      -- Omega (right ascension)
      Argument_Of_Periapsis: Angle_Radians;      -- omega
      True_Anomaly         : Angle_Radians;      -- nu
   end record;

   -- Orbit classification
   type Orbit_Type is (Circular, Elliptical, Parabolic, Hyperbolic);

   -- Exception types
   Convergence_Error : exception;
   Invalid_Orbit     : exception;
   Physical_Error    : exception;

end Hale_Orbital.Types;
```

---

## 3. Conversion Phases

### Phase 1: Foundation & Constants

**Duration Estimate**: Week 1-2

**Tasks**:
1. Set up GNAT project structure
2. Define core type system with dimensional types
3. Implement physical constants from Hale Appendix B
4. Create basic test framework using AUnit

**Key Constants to Convert**:
```ada
-- hale_orbital-constants.ads

package Hale_Orbital.Constants is

   -- Universal Constants
   G : constant := 6.67430e-11;  -- Gravitational constant (m^3/kg/s^2)
   C : constant := 299_792.458;  -- Speed of light (km/s)

   -- Earth Parameters
   Mu_Earth    : constant Gravitational_Parameter := 398_600.4418;
   R_Earth     : constant Distance_Km := 6_378.137;
   J2_Earth    : constant := 1.08263e-3;

   -- Sun Parameters
   Mu_Sun      : constant Gravitational_Parameter := 1.32712440018e11;
   R_Sun       : constant Distance_Km := 696_000.0;
   AU          : constant Distance_Km := 149_597_870.7;

   -- Moon Parameters
   Mu_Moon     : constant Gravitational_Parameter := 4_902.8;
   R_Moon      : constant Distance_Km := 1_737.4;

   -- Mathematical Constants
   Two_Pi      : constant := 2.0 * Ada.Numerics.Pi;
   Deg_To_Rad  : constant := Ada.Numerics.Pi / 180.0;
   Rad_To_Deg  : constant := 180.0 / Ada.Numerics.Pi;

end Hale_Orbital.Constants;
```

**Validation Criteria**:
- All constants match Hale Appendix B within machine precision
- Type safety prevents unit mixing (km vs m, radians vs degrees)

---

### Phase 2: Vector & Matrix Operations

**Duration Estimate**: Week 2-3

**Tasks**:
1. Implement 3D vector operations (cross, dot, magnitude, normalize)
2. Implement rotation matrices (Euler angles, axis-angle)
3. Implement 3x3 and 6x6 matrix operations
4. Add eigenvalue computation for stability analysis

**Critical Functions**:
```ada
-- Vector operations
function Cross_Product (A, B : Vector_3D) return Vector_3D;
function Dot_Product (A, B : Vector_3D) return Real;
function Magnitude (V : Vector_3D) return Real;
function Normalize (V : Vector_3D) return Vector_3D;

-- Matrix operations
function Rotation_X (Angle : Angle_Radians) return Matrix_3x3;
function Rotation_Y (Angle : Angle_Radians) return Matrix_3x3;
function Rotation_Z (Angle : Angle_Radians) return Matrix_3x3;
function Matrix_Multiply (A, B : Matrix_3x3) return Matrix_3x3;
function Matrix_Vector_Multiply (M : Matrix_3x3; V : Vector_3D) return Vector_3D;
function Transpose (M : Matrix_3x3) return Matrix_3x3;
function Determinant (M : Matrix_3x3) return Real;
function Inverse (M : Matrix_3x3) return Matrix_3x3;
```

---

### Phase 3: Two-Body Dynamics

**Duration Estimate**: Week 3-4

**Reference**: Hale Chapters 2-3

**Tasks**:
1. Vis-viva equation implementation
2. Specific energy and angular momentum
3. Orbital period and mean motion
4. Conic section geometry
5. Orbit type classification

**Critical Functions**:
```ada
-- Energy and momentum
function Specific_Energy (R, V : Vector_3D; Mu : Gravitational_Parameter) return Real;
function Angular_Momentum (R, V : Vector_3D) return Vector_3D;
function Specific_Angular_Momentum (R, V : Vector_3D) return Real;

-- Orbital parameters
function Vis_Viva (R : Distance_Km; A : Distance_Km; Mu : Gravitational_Parameter) return Velocity_Km_S;
function Orbital_Period (A : Distance_Km; Mu : Gravitational_Parameter) return Time_Seconds;
function Mean_Motion (A : Distance_Km; Mu : Gravitational_Parameter) return Real;
function Semi_Latus_Rectum (A : Distance_Km; E : Real) return Distance_Km;

-- Orbit classification
function Classify_Orbit (E : Real) return Orbit_Type;
function Periapsis_Distance (A : Distance_Km; E : Real) return Distance_Km;
function Apoapsis_Distance (A : Distance_Km; E : Real) return Distance_Km;
```

---

### Phase 4: Orbital Elements

**Duration Estimate**: Week 4-5

**Reference**: Hale Chapters 3-4

**Tasks**:
1. State vector to orbital elements conversion
2. Orbital elements to state vector conversion
3. Handle singularities (circular, equatorial orbits)
4. Anomaly conversions (true, eccentric, mean)

**Critical Functions**:
```ada
-- Element conversions
function State_To_Elements (State : State_Vector; Mu : Gravitational_Parameter) return Orbital_Elements;
function Elements_To_State (Elements : Orbital_Elements; Mu : Gravitational_Parameter) return State_Vector;

-- Anomaly conversions
function True_To_Eccentric_Anomaly (Nu : Angle_Radians; E : Real) return Angle_Radians;
function Eccentric_To_True_Anomaly (Ecc_Anom : Angle_Radians; E : Real) return Angle_Radians;
function Eccentric_To_Mean_Anomaly (Ecc_Anom : Angle_Radians; E : Real) return Angle_Radians;
function Mean_To_Eccentric_Anomaly (M : Angle_Radians; E : Real; Tolerance : Real := 1.0e-12) return Angle_Radians;
```

---

### Phase 5: Kepler's Equation

**Duration Estimate**: Week 5-6

**Reference**: Hale Chapter 4

**Tasks**:
1. Newton-Raphson solver for Kepler's equation
2. Hyperbolic and parabolic cases
3. Universal variable formulation
4. Stumpff functions (C and S)
5. Time of flight calculations

**Critical Functions**:
```ada
-- Kepler solvers
function Solve_Kepler (Mean_Anomaly : Angle_Radians; Eccentricity : Real;
                       Tolerance : Real := 1.0e-12; Max_Iterations : Positive := 50) return Angle_Radians;
function Solve_Kepler_Hyperbolic (Mean_Anomaly : Angle_Radians; Eccentricity : Real;
                                   Tolerance : Real := 1.0e-12) return Angle_Radians;
function Solve_Kepler_Universal (Dt : Time_Seconds; R0 : Distance_Km; Vr0 : Real;
                                  A : Distance_Km; Mu : Gravitational_Parameter) return Real;

-- Stumpff functions
function Stumpff_C (Z : Real) return Real;
function Stumpff_S (Z : Real) return Real;

-- Time of flight
function Time_Of_Flight (R1, R2 : Distance_Km; A : Distance_Km;
                         Mu : Gravitational_Parameter; Transfer_Type : Transfer_Direction) return Time_Seconds;
```

---

### Phase 6: Lambert Problem

**Duration Estimate**: Week 6-7

**Reference**: Hale Chapter 5

**Tasks**:
1. Lambert solver implementation
2. Multi-revolution solutions
3. Short-way and long-way transfers
4. Transfer orbit determination

**Critical Functions**:
```ada
type Lambert_Solution is record
   V1 : Velocity_Vector;  -- Departure velocity
   V2 : Velocity_Vector;  -- Arrival velocity
   A  : Distance_Km;      -- Semi-major axis
   Converged : Boolean;
end record;

function Solve_Lambert (R1, R2 : Position_Vector; Tof : Time_Seconds;
                        Mu : Gravitational_Parameter;
                        Long_Way : Boolean := False;
                        Revolutions : Natural := 0) return Lambert_Solution;

function Lambert_Multi_Rev (R1, R2 : Position_Vector; Tof : Time_Seconds;
                            Mu : Gravitational_Parameter;
                            Max_Revs : Positive := 5) return Lambert_Solution_Array;
```

---

### Phase 7: Orbital Maneuvers

**Duration Estimate**: Week 7-8

**Reference**: Hale Chapter 6

**Tasks**:
1. Hohmann transfer calculations
2. Bi-elliptic transfer analysis
3. Plane change maneuvers
4. Rendezvous timing
5. Delta-V optimization

**Critical Functions**:
```ada
type Transfer_Result is record
   Delta_V1    : Velocity_Km_S;
   Delta_V2    : Velocity_Km_S;
   Total_Delta_V : Velocity_Km_S;
   Transfer_Time : Time_Seconds;
   Transfer_Orbit : Orbital_Elements;
end record;

function Hohmann_Transfer (R_Initial, R_Final : Distance_Km;
                           Mu : Gravitational_Parameter) return Transfer_Result;
function Bielliptic_Transfer (R_Initial, R_Intermediate, R_Final : Distance_Km;
                              Mu : Gravitational_Parameter) return Transfer_Result;
function Plane_Change (V : Velocity_Km_S; Delta_I : Angle_Radians) return Velocity_Km_S;
function Combined_Maneuver (R_Initial, R_Final : Distance_Km;
                            Delta_I : Angle_Radians;
                            Mu : Gravitational_Parameter) return Transfer_Result;
```

---

### Phase 8: Interplanetary Trajectories

**Duration Estimate**: Week 8-10

**Reference**: Hale Chapters 7-8

**Tasks**:
1. Sphere of influence calculations
2. Patched conic methodology
3. Hyperbolic excess velocity (C3)
4. Gravity assist trajectories
5. Planetary departure/arrival

**Critical Functions**:
```ada
function Sphere_Of_Influence (A_Planet : Distance_Km; M_Planet, M_Sun : Mass_Kg) return Distance_Km;
function Hyperbolic_Excess_Velocity (V_Infinity : Velocity_Km_S; R_Periapsis : Distance_Km;
                                      Mu : Gravitational_Parameter) return Velocity_Km_S;
function C3_Energy (V_Infinity : Velocity_Km_S) return Real;

type Patched_Conic_Trajectory is record
   Departure_Hyperbola : Orbital_Elements;
   Heliocentric_Transfer : Orbital_Elements;
   Arrival_Hyperbola : Orbital_Elements;
   Launch_C3 : Real;
   Arrival_V_Infinity : Velocity_Km_S;
end record;

function Compute_Patched_Conic (Departure_Planet, Arrival_Planet : Planet_Type;
                                 Launch_Date, Arrival_Date : Time_Seconds) return Patched_Conic_Trajectory;
```

---

### Phase 9: Three-Body Dynamics

**Duration Estimate**: Week 10-12

**Tasks**:
1. Convert CR3BP equations of motion
2. Lagrange point calculations
3. Numerical integrators (RK4, RK45)
4. Jacobi constant and zero-velocity curves
5. Stability analysis (monodromy matrix, Floquet)
6. Periodic orbit computation

---

## 4. Numerical Methods Library

Ada does not have a built-in equivalent to NumPy/SciPy. The following numerical methods must be implemented:

### 4.1 Root Finding

```ada
-- Newton-Raphson solver
generic
   type Real_Type is digits <>;
   with function F (X : Real_Type) return Real_Type;
   with function F_Prime (X : Real_Type) return Real_Type;
function Newton_Raphson (Initial_Guess : Real_Type;
                         Tolerance : Real_Type := 1.0e-12;
                         Max_Iterations : Positive := 50) return Real_Type;

-- Brent's method (bracketing)
generic
   type Real_Type is digits <>;
   with function F (X : Real_Type) return Real_Type;
function Brents_Method (A, B : Real_Type;
                        Tolerance : Real_Type := 1.0e-12) return Real_Type;
```

### 4.2 ODE Integration

```ada
-- Runge-Kutta 4th order
generic
   type State_Type is private;
   type Real_Type is digits <>;
   with function Derivatives (T : Real_Type; Y : State_Type) return State_Type;
   with function "+" (A, B : State_Type) return State_Type;
   with function "*" (S : Real_Type; A : State_Type) return State_Type;
procedure RK4_Step (T : in out Real_Type; Y : in out State_Type; H : Real_Type);

-- Runge-Kutta-Fehlberg (adaptive step)
generic
   type State_Type is private;
   type Real_Type is digits <>;
   with function Derivatives (T : Real_Type; Y : State_Type) return State_Type;
   with function "+" (A, B : State_Type) return State_Type;
   with function "*" (S : Real_Type; A : State_Type) return State_Type;
   with function Error_Norm (Y4, Y5 : State_Type) return Real_Type;
procedure RK45_Step (T : in Out Real_Type; Y : in out State_Type;
                     H : in out Real_Type; Tolerance : Real_Type);
```

### 4.3 Linear Algebra

```ada
-- Matrix types
type Matrix_3x3 is array (1 .. 3, 1 .. 3) of Real;
type Matrix_6x6 is array (1 .. 6, 1 .. 6) of Real;

-- Core operations
function Inverse (M : Matrix_3x3) return Matrix_3x3;
function Eigenvalues (M : Matrix_3x3) return Complex_Vector_3;
function LU_Decomposition (M : Matrix_NxN) return LU_Result;
function Solve_Linear_System (A : Matrix_NxN; B : Vector_N) return Vector_N;
```

---

## 5. Testing Strategy

### 5.1 Test Framework

Use **AUnit** (GNAT's unit testing framework) for all tests.

```ada
with AUnit.Test_Cases;
with AUnit.Assertions;

package Test_Constants is
   type Test is new AUnit.Test_Cases.Test_Case with null record;

   procedure Register_Tests (T : in out Test);

   -- Test procedures
   procedure Test_Earth_Mu (T : in out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Sun_Mu (T : in Out AUnit.Test_Cases.Test_Case'Class);
   procedure Test_Unit_Conversions (T : in Out AUnit.Test_Cases.Test_Case'Class);
end Test_Constants;
```

### 5.2 Validation Data

All test cases will use the same validation data as Python:
- Hale textbook examples (pages cited)
- Apollo 11 mission parameters
- Mars mission data
- ISS orbital parameters
- GEO satellite parameters

### 5.3 Numerical Precision Tests

```ada
-- Tolerance for orbital mechanics calculations
Orbital_Tolerance : constant := 1.0e-10;

-- Test example
procedure Test_Hohmann_Transfer (T : in out Test_Case'Class) is
   Result : Transfer_Result;
begin
   Result := Hohmann_Transfer (R_Initial => 6_678.0,  -- LEO
                               R_Final => 42_164.0,   -- GEO
                               Mu => Mu_Earth);

   Assert (abs(Result.Total_Delta_V - 3.935) < 0.001,
           "Hohmann delta-V should match Hale Example 6.1");
   Assert (abs(Result.Transfer_Time - 18_924.8) < 1.0,
           "Transfer time should match expected value");
end Test_Hohmann_Transfer;
```

---

## 6. Dependencies

### 6.1 Required Ada Libraries

| Library | Purpose | Source |
|---------|---------|--------|
| GNAT.OS_Lib | File I/O operations | GNAT standard |
| Ada.Numerics.Generic_Elementary_Functions | Trig, exp, log | Ada standard |
| Ada.Numerics.Generic_Complex_Types | Complex numbers | Ada standard |
| AUnit | Unit testing | GNAT community |

### 6.2 Optional External Libraries

| Library | Purpose | Notes |
|---------|---------|-------|
| BLAS/LAPACK bindings | Fast linear algebra | For large matrices |
| Ada-SPARK subset | Formal verification | Safety-critical applications |

---

## 7. Build System

### 7.1 GNAT Project File

```ada
-- hale_orbital.gpr
project Hale_Orbital is

   for Source_Dirs use ("src", "src/threebody");
   for Object_Dir use "obj";
   for Exec_Dir use "bin";

   for Library_Name use "hale_orbital";
   for Library_Dir use "lib";
   for Library_Kind use "static";

   package Compiler is
      for Default_Switches ("Ada") use
         ("-gnat2012",      -- Ada 2012 standard
          "-gnatwa",        -- All warnings
          "-gnatyg",        -- GNAT style checks
          "-gnata",         -- Enable assertions
          "-O2",            -- Optimization level 2
          "-gnatn");        -- Enable inlining
   end Compiler;

   package Binder is
      for Default_Switches ("Ada") use ("-E");  -- Store tracebacks
   end Binder;

end Hale_Orbital;
```

### 7.2 Build Commands

```bash
# Build library
gprbuild -P hale_orbital.gpr

# Build and run tests
gprbuild -P tests/hale_tests.gpr
./bin/run_tests

# Build with coverage
gprbuild -P hale_orbital.gpr -cargs -fprofile-arcs -ftest-coverage
```

---

## 8. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Numerical precision differences | Medium | High | Extensive cross-validation with Python |
| Missing linear algebra library | Low | High | Implement custom or use BLAS bindings |
| Complex eigenvalue computation | Medium | Medium | Use established algorithms (QR, etc.) |
| Testing framework limitations | Low | Low | AUnit is mature and full-featured |
| Build complexity | Low | Low | GNAT project files are straightforward |

---

## 9. Milestones & Deliverables

| Milestone | Deliverables | Success Criteria |
|-----------|--------------|------------------|
| M1: Foundation | Types, constants, vectors | All constants validated |
| M2: Core Dynamics | Two-body, elements | State/element conversions pass |
| M3: Solvers | Kepler, Lambert | Textbook examples validated |
| M4: Maneuvers | Hohmann, plane change | Delta-V calculations match |
| M5: Interplanetary | Patched conics | Mars mission validated |
| M6: Three-Body | CR3BP, Lagrange | Lagrange points accurate |
| M7: Integration | Full library | All 150+ tests passing |

---

## 10. Next Steps

1. **Immediate**: Set up GNAT project structure in `ada_conversion/`
2. **Week 1**: Implement core types and constants package
3. **Week 2**: Implement vector/matrix operations
4. **Ongoing**: Convert modules phase by phase with continuous testing

---

## Appendix A: Python to Ada Mapping

| Python | Ada |
|--------|-----|
| `float` | `Long_Float` or custom `Real` |
| `numpy.ndarray` | `array (1..N) of Real` |
| `class` | `record` or tagged type |
| `def function():` | `function ... return ...` |
| `try/except` | `begin/exception when` |
| `import` | `with` clause |
| `__init__.py` | Package specification |
| `pytest` | AUnit |

---

## Appendix B: File Naming Conventions

| Python | Ada |
|--------|-----|
| `constants.py` | `hale_orbital-constants.ads/adb` |
| `twobody.py` | `hale_orbital-twobody.ads/adb` |
| `elements.py` | `hale_orbital-elements.ads/adb` |
| `class OrbitElements:` | `type Orbital_Elements is record` |
| `def solve_kepler():` | `function Solve_Kepler () return` |

---

*Document Version: 1.0*
*Created: 2026-01-04*
*Status: Initial Planning*
