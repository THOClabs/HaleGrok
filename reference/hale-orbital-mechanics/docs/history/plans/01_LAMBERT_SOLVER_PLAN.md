# Lambert Solver Implementation Plan
## Vision 2: The Bridge Between Worlds

*Champions: Tucker Taft (Ada) + Meriadoc Brandybuck (Hobbit)*

---

## Overview

The Lambert problem is the cornerstone of mission planning: given two positions and a time of flight, find the orbit connecting them. This plan details completing the Lambert solver implementation.

---

## Current State

**Specification**: ✅ Complete (`hale_orbital-lambert.ads`)
**Body**: ❌ Needs implementation (`hale_orbital-lambert.adb`)

### Existing API

```ada
function Solve_Lambert (R1        : Position_Vector;
                        R2        : Position_Vector;
                        Tof       : Time_Seconds;
                        Mu        : Gravitational_Parameter;
                        Long_Way  : Boolean := False;
                        Tolerance : Real := Default_Tolerance) return Lambert_Result;
```

---

## Implementation Approach

### Algorithm Selection

**Tucker Taft**:
> "We'll use Battin's universal variable formulation. It handles elliptic, parabolic, and hyperbolic transfers uniformly. The Stumpff functions provide numerical stability."

### Mathematical Foundation

**1. Transfer Geometry**

```
Given: R1, R2 (position vectors), TOF (time of flight), μ (gravitational parameter)
Find:  V1, V2 (velocity vectors at departure and arrival)

Geometry:
  r1 = |R1|           -- magnitude of initial position
  r2 = |R2|           -- magnitude of final position
  cos(Δν) = R1·R2 / (r1·r2)  -- transfer angle
  c = |R2 - R1|       -- chord length
  s = (r1 + r2 + c)/2 -- semi-perimeter
```

**2. Stumpff Functions**

```ada
-- Stumpff C function
function Stumpff_C (Z : Real) return Real is
   (if Z > 1.0e-6 then
       (1.0 - Cos(Sqrt(Z))) / Z
    elsif Z < -1.0e-6 then
       (Cosh(Sqrt(-Z)) - 1.0) / (-Z)
    else
       1.0/2.0 - Z/24.0 + Z**2/720.0);  -- Taylor series near zero

-- Stumpff S function
function Stumpff_S (Z : Real) return Real is
   (if Z > 1.0e-6 then
       (Sqrt(Z) - Sin(Sqrt(Z))) / Sqrt(Z**3)
    elsif Z < -1.0e-6 then
       (Sinh(Sqrt(-Z)) - Sqrt(-Z)) / Sqrt((-Z)**3)
    else
       1.0/6.0 - Z/120.0 + Z**2/5040.0);  -- Taylor series near zero
```

**3. Universal Variable Iteration**

```ada
-- Time of flight equation in universal variable form
-- TOF = (x³·S(z) + A·√y) / √μ
-- where:
--   z = α·x²  (α = 1/a for ellipse, negative for hyperbola)
--   y = r1 + r2 + A·(x³·S(z) - 1)/√y

-- Newton-Raphson iteration to find x that satisfies TOF equation
loop
   z := Alpha * x**2;
   C_z := Stumpff_C(z);
   S_z := Stumpff_S(z);

   y := r1 + r2 + A * (x**3 * S_z - 1.0) / Sqrt(y);
   F := x**3 * S_z + A * Sqrt(y) - Sqrt(Mu) * Tof;
   F_Prime := ...;  -- derivative

   x := x - F / F_Prime;

   exit when abs(F) < Tolerance;
end loop;
```

---

## Implementation Tasks

### Task 1: Stumpff Functions Module

**File**: `ada/src/hale_orbital-stumpff.ads/adb`

```ada
package Hale_Orbital.Stumpff
   with SPARK_Mode => On
is
   function C (Z : Real) return Real
      with Post => C'Result >= 0.0;

   function S (Z : Real) return Real
      with Post => S'Result >= 0.0;

   function C_Prime (Z : Real) return Real;
   function S_Prime (Z : Real) return Real;
end Hale_Orbital.Stumpff;
```

**Validation** (Sam):
| Z | Expected C(z) | Expected S(z) |
|---|---------------|---------------|
| 0.0 | 0.5 | 0.166667 |
| 1.0 | 0.459698 | 0.158529 |
| -1.0 | 0.543081 | 0.175201 |
| 10.0 | 0.183772 | 0.047514 |

---

### Task 2: Core Lambert Solver

**File**: `ada/src/hale_orbital-lambert.adb`

```ada
function Solve_Lambert (R1        : Position_Vector;
                        R2        : Position_Vector;
                        Tof       : Time_Seconds;
                        Mu        : Gravitational_Parameter;
                        Long_Way  : Boolean := False;
                        Tolerance : Real := Default_Tolerance)
   return Lambert_Result
is
   -- Geometry
   r1 : constant Real := Magnitude(R1);
   r2 : constant Real := Magnitude(R2);
   Cos_Delta_Nu : constant Real := Dot_Product(R1, R2) / (r1 * r2);

   -- Transfer direction
   D_M : constant Real := (if Long_Way then -1.0 else 1.0);
   Sin_Delta_Nu : constant Real := D_M * Sqrt(1.0 - Cos_Delta_Nu**2);

   -- Chord and semi-perimeter
   C : constant Real := Sqrt(r1**2 + r2**2 - 2.0*r1*r2*Cos_Delta_Nu);
   S : constant Real := (r1 + r2 + C) / 2.0;

   -- A parameter (Battin formulation)
   A : constant Real := D_M * Sqrt(r1 * r2 * (1.0 + Cos_Delta_Nu));

   -- Initial guess for universal variable x
   X : Real := ...;  -- Depends on expected orbit type

   -- Iteration variables
   Z, Y, F, F_Prime : Real;
   Iterations : Natural := 0;

begin
   -- Check for degenerate case (180° transfer)
   if abs(Sin_Delta_Nu) < 1.0e-10 then
      return (Converged => False, others => <>);
   end if;

   -- Newton-Raphson iteration
   loop
      Iterations := Iterations + 1;

      -- Evaluate time-of-flight function
      Z := Alpha * X**2;
      Y := r1 + r2 + A * (X**3 * Stumpff.S(Z) - 1.0) / Sqrt(Y_Prev);
      F := X**3 * Stumpff.S(Z) + A * Sqrt(Y) - Sqrt(Real(Mu)) * Real(Tof);
      F_Prime := ...;

      -- Update
      X := X - F / F_Prime;

      -- Check convergence
      exit when abs(F) < Tolerance or Iterations > Max_Iterations;
   end loop;

   -- Compute velocity vectors from converged solution
   -- f, g, f_dot, g_dot Lagrange coefficients
   declare
      F_Coef : constant Real := 1.0 - Y / r1;
      G_Coef : constant Real := A * Sqrt(Y / Real(Mu));
      G_Dot  : constant Real := 1.0 - Y / r2;
   begin
      return (V1         => (R2 - F_Coef * R1) / G_Coef,
              V2         => (G_Dot * R2 - R1) / G_Coef,
              A          => Distance_Km(1.0 / Alpha),
              E          => Compute_Eccentricity(...),
              Iterations => Iterations,
              Converged  => Iterations <= Max_Iterations);
   end;
end Solve_Lambert;
```

---

### Task 3: Multi-Revolution Solutions

**Concept** (Merry):
> "When TOF is long enough, spacecraft can complete one or more full orbits during transfer. Each revolution count gives a different solution with different energy."

```ada
function Solve_Lambert_Multi (R1       : Position_Vector;
                              R2       : Position_Vector;
                              Tof      : Time_Seconds;
                              Mu       : Gravitational_Parameter;
                              Max_Revs : Natural := 0;
                              Long_Way : Boolean := False)
   return Lambert_Solution_Array
is
   Solutions : Lambert_Solution_Array (0 .. Max_Revs * 2);
   Count     : Natural := 0;
begin
   -- Zero-revolution solution
   Solutions(Count) := Solve_Lambert(R1, R2, Tof, Mu, Long_Way);
   Count := Count + 1;

   -- Multi-revolution solutions (if TOF permits)
   for N in 1 .. Max_Revs loop
      -- Low-energy solution for N revolutions
      declare
         Sol_Low : constant Lambert_Result :=
            Solve_Lambert_N_Rev(R1, R2, Tof, Mu, N, Low_Energy => True);
      begin
         if Sol_Low.Converged then
            Solutions(Count) := Sol_Low;
            Count := Count + 1;
         end if;
      end;

      -- High-energy solution for N revolutions
      declare
         Sol_High : constant Lambert_Result :=
            Solve_Lambert_N_Rev(R1, R2, Tof, Mu, N, Low_Energy => False);
      begin
         if Sol_High.Converged then
            Solutions(Count) := Sol_High;
            Count := Count + 1;
         end if;
      end;
   end loop;

   return Solutions(0 .. Count - 1);
end Solve_Lambert_Multi;
```

---

### Task 4: Edge Case Handling

**Pippin's Chaos Cases**:

| Case | Condition | Handling |
|------|-----------|----------|
| 180° transfer | `Sin_Delta_Nu ≈ 0` | Return not converged + flag |
| TOF too short | `Tof < Min_Energy_Tof` | Hyperbolic, may not converge |
| TOF very long | Multi-rev threshold | Offer multi-rev solutions |
| R1 = R2 | Same position | Invalid input, return error |
| Parabolic | `E ≈ 1.0` | Special handling in Stumpff |

```ada
-- Degenerate case detection
function Is_Degenerate_Transfer (R1, R2 : Position_Vector) return Boolean is
   Cos_Angle : constant Real := Dot_Product(Normalize(R1), Normalize(R2));
begin
   return abs(Cos_Angle + 1.0) < 1.0e-10;  -- ~180° transfer
end Is_Degenerate_Transfer;
```

---

## Test Plan

### Unit Tests (Sam)

```ada
-- test_lambert.adb
procedure Test_Vallado_Example_5_1 is
   -- LEO to GEO transfer
   R1 : constant Position_Vector := (6678.0, 0.0, 0.0);
   R2 : constant Position_Vector := (0.0, 42164.0, 0.0);
   Tof : constant Time_Seconds := 5.0 * 3600.0;  -- 5 hours

   Result : constant Lambert_Result := Solve_Lambert(R1, R2, Tof, Mu_Earth);
begin
   Assert (Result.Converged, "Should converge");
   Assert_Near (Magnitude(Result.V1), 10.15, Tolerance => 0.01);
end Test_Vallado_Example_5_1;
```

### Reference Validation Matrix

| Test Case | Source | R1 | R2 | TOF | Expected |
|-----------|--------|----|----|-----|----------|
| Ex 5-1 | Vallado | LEO | GEO | 5h | V1=10.15 |
| Ex 5-2 | Vallado | Earth | Mars | 200d | V1=32.7 |
| Multi-1 | Curtis | LEO | LEO+180° | 1 orbit | Circular |

### Chaos Tests (Pippin)

```ada
procedure Test_Near_180_Degree is
   R1 : constant Position_Vector := (10000.0, 0.0, 0.0);
   R2 : constant Position_Vector := (-10000.0, 0.001, 0.0);  -- Nearly opposite
begin
   -- Should handle gracefully, not crash
   declare
      Result : constant Lambert_Result := Solve_Lambert(R1, R2, 10000.0, Mu_Earth);
   begin
      -- May or may not converge, but shouldn't crash
      null;
   end;
end Test_Near_180_Degree;
```

---

## SPARK Annotations (Ben)

```ada
package Hale_Orbital.Lambert
   with SPARK_Mode => On
is
   function Solve_Lambert (...)
      with Global  => null,
           Depends => (Solve_Lambert'Result =>
                        (R1, R2, Tof, Mu, Long_Way, Tolerance)),
           Pre     => Magnitude(R1) > 0.0
                  and Magnitude(R2) > 0.0
                  and Tof > 0.0
                  and Mu > 0.0
                  and Tolerance > 0.0,
           Post    => (if Solve_Lambert'Result.Converged then
                         Solve_Lambert'Result.Iterations <= Max_Iterations);
```

---

## Performance Targets (Tom)

| Operation | Target | Measurement |
|-----------|--------|-------------|
| Single Lambert solve | < 10 μs | `clock_gettime` |
| Stumpff evaluation | < 100 ns | Inlined |
| Multi-rev (5 revs) | < 50 μs | 10 solutions |

**Optimization Strategy**:
- Inline Stumpff functions
- Precompute geometry once
- Use expression functions for simple conversions
- Cache Sqrt computations where possible

---

## Deliverables Checklist

- [ ] `hale_orbital-stumpff.ads/adb` - Stumpff functions
- [ ] `hale_orbital-lambert.adb` - Core solver implementation
- [ ] Multi-revolution capability
- [ ] Degenerate case handling
- [ ] Unit test suite (15+ tests)
- [ ] Vallado validation (3+ examples)
- [ ] SPARK flow analysis clean
- [ ] Performance benchmarks
- [ ] Lobelia's code review approval

---

## Dependencies

| Depends On | For |
|------------|-----|
| `Hale_Orbital.Vectors` | Position/Velocity vectors |
| `Hale_Orbital.Types` | Dimensional types |
| `Hale_Orbital.Constants` | Mu values |
| `Ada.Numerics.Elementary_Functions` | Sqrt, Sin, Cos |

---

*"The Lambert problem is the bridge between any two points in space. Build it well, and all worlds become reachable."*

— Merry, Mission Planner

