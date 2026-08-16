# Propagation Engine Implementation Plan
## Vision 5: The Long Propagation

*Champions: Tucker Taft (Ada) + Hamfast Gamgee (Hobbit)*

---

## Overview

The propagation engine traces spacecraft trajectories through time. Given an initial state, it numerically integrates the equations of motion to predict future positions and velocities.

---

## Current State

**Existing**: Basic RK4 in example code
**Needed**: Proper package with multiple integrators, force models, parallel capability

---

## Package Design

### New Package: `Hale_Orbital.Propagation`

```ada
-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Propagation Engine
-------------------------------------------------------------------------------
-- Numerical integration for orbit propagation with configurable accuracy,
-- multiple integration schemes, and pluggable force models.
-------------------------------------------------------------------------------

with Hale_Orbital.Types; use Hale_Orbital.Types;

package Hale_Orbital.Propagation
   with SPARK_Mode => On
is
   ---------------------------------------------------------------------------
   -- Force Model Interface
   ---------------------------------------------------------------------------

   type Force_Model is interface;

   function Compute_Acceleration
      (Model : Force_Model;
       T     : Time_Seconds;
       Pos   : Position_Vector;
       Vel   : Velocity_Vector) return Acceleration_Vector is abstract;

   ---------------------------------------------------------------------------
   -- Standard Force Models
   ---------------------------------------------------------------------------

   -- Two-body (Keplerian) force model
   type Two_Body_Model is new Force_Model with record
      Mu : Gravitational_Parameter;
   end record;

   overriding function Compute_Acceleration
      (Model : Two_Body_Model;
       T     : Time_Seconds;
       Pos   : Position_Vector;
       Vel   : Velocity_Vector) return Acceleration_Vector;

   -- J2 perturbation model (Earth oblateness)
   type J2_Model is new Force_Model with record
      Mu    : Gravitational_Parameter;
      J2    : Real;
      R_Eq  : Distance_Km;  -- Equatorial radius
   end record;

   overriding function Compute_Acceleration
      (Model : J2_Model;
       T     : Time_Seconds;
       Pos   : Position_Vector;
       Vel   : Velocity_Vector) return Acceleration_Vector;

   -- Earth J2 model with standard constants
   Earth_J2_Model : constant J2_Model;

   ---------------------------------------------------------------------------
   -- State Types
   ---------------------------------------------------------------------------

   type Propagator_State is record
      Position : Position_Vector;
      Velocity : Velocity_Vector;
      Time     : Time_Seconds;
   end record;

   type Trajectory is array (Positive range <>) of Propagator_State;
   type Trajectory_Access is access Trajectory;

   ---------------------------------------------------------------------------
   -- Integration Methods
   ---------------------------------------------------------------------------

   type Integration_Method is (RK4, RK78_Dormand_Prince, RKF45);

   ---------------------------------------------------------------------------
   -- Single Step Propagation
   ---------------------------------------------------------------------------

   -- Propagate one step using RK4 (fixed step)
   function Step_RK4
      (State : Propagator_State;
       Step  : Time_Seconds;
       Model : Force_Model'Class) return Propagator_State
      with Pre => Real(Step) > 0.0;

   -- Propagate one step using RK78 (adaptive step)
   procedure Step_RK78
      (State     : in out Propagator_State;
       Step      : in out Time_Seconds;
       Tolerance : in     Real;
       Model     : in     Force_Model'Class)
      with Pre => Real(Step) > 0.0 and Tolerance > 0.0;

   ---------------------------------------------------------------------------
   -- Full Propagation
   ---------------------------------------------------------------------------

   -- Propagate from T_Start to T_End with fixed step
   function Propagate_Fixed
      (Initial : Propagator_State;
       T_End   : Time_Seconds;
       Step    : Time_Seconds;
       Model   : Force_Model'Class) return Propagator_State
      with Pre => Real(Step) > 0.0;

   -- Propagate with adaptive step size
   function Propagate_Adaptive
      (Initial   : Propagator_State;
       T_End     : Time_Seconds;
       Tolerance : Real;
       Model     : Force_Model'Class) return Propagator_State
      with Pre => Tolerance > 0.0;

   -- Generate trajectory (array of states)
   function Generate_Trajectory
      (Initial  : Propagator_State;
       T_End    : Time_Seconds;
       N_Points : Positive;
       Model    : Force_Model'Class) return Trajectory
      with Post => Generate_Trajectory'Result'Length = N_Points;

   ---------------------------------------------------------------------------
   -- Parallel Propagation (Ada 2022)
   ---------------------------------------------------------------------------

   type State_Array is array (Positive range <>) of Propagator_State;

   -- Propagate multiple initial conditions in parallel
   function Propagate_Parallel
      (Initials  : State_Array;
       T_End     : Time_Seconds;
       Tolerance : Real;
       Model     : Force_Model'Class) return State_Array
      with Pre  => Initials'Length > 0,
           Post => Propagate_Parallel'Result'Length = Initials'Length;

   ---------------------------------------------------------------------------
   -- Energy and Validation
   ---------------------------------------------------------------------------

   -- Compute specific orbital energy (should be conserved)
   function Specific_Energy
      (State : Propagator_State;
       Mu    : Gravitational_Parameter) return Real;

   -- Compute specific angular momentum magnitude (should be conserved)
   function Angular_Momentum
      (State : Propagator_State) return Real;

end Hale_Orbital.Propagation;
```

---

## Implementation Details

### Two-Body Acceleration

```ada
overriding function Compute_Acceleration
   (Model : Two_Body_Model;
    T     : Time_Seconds;
    Pos   : Position_Vector;
    Vel   : Velocity_Vector) return Acceleration_Vector
is
   pragma Unreferenced (T, Vel);  -- Two-body doesn't depend on time or velocity

   R_Mag : constant Real := Magnitude(Pos);
   R_Cubed : constant Real := R_Mag ** 3;
begin
   -- a = -μ/r³ * r
   return Acceleration_Vector'
      (X => Acceleration_Km_S2(-Real(Model.Mu) * Real(Pos.X) / R_Cubed),
       Y => Acceleration_Km_S2(-Real(Model.Mu) * Real(Pos.Y) / R_Cubed),
       Z => Acceleration_Km_S2(-Real(Model.Mu) * Real(Pos.Z) / R_Cubed));
end Compute_Acceleration;
```

### J2 Perturbation

```ada
overriding function Compute_Acceleration
   (Model : J2_Model;
    T     : Time_Seconds;
    Pos   : Position_Vector;
    Vel   : Velocity_Vector) return Acceleration_Vector
is
   pragma Unreferenced (T, Vel);

   X : constant Real := Real(Pos.X);
   Y : constant Real := Real(Pos.Y);
   Z : constant Real := Real(Pos.Z);
   R : constant Real := Sqrt(X**2 + Y**2 + Z**2);
   R2 : constant Real := R ** 2;
   R5 : constant Real := R ** 5;
   Re2 : constant Real := Real(Model.R_Eq) ** 2;
   Z2_R2 : constant Real := (Z / R) ** 2;

   -- J2 perturbation factor
   Factor : constant Real := 1.5 * Model.J2 * Real(Model.Mu) * Re2 / R5;

   -- Two-body plus J2
   A_Two_Body_X : constant Real := -Real(Model.Mu) * X / (R ** 3);
   A_Two_Body_Y : constant Real := -Real(Model.Mu) * Y / (R ** 3);
   A_Two_Body_Z : constant Real := -Real(Model.Mu) * Z / (R ** 3);

   A_J2_X : constant Real := Factor * X * (5.0 * Z2_R2 - 1.0);
   A_J2_Y : constant Real := Factor * Y * (5.0 * Z2_R2 - 1.0);
   A_J2_Z : constant Real := Factor * Z * (5.0 * Z2_R2 - 3.0);
begin
   return Acceleration_Vector'
      (X => Acceleration_Km_S2(A_Two_Body_X + A_J2_X),
       Y => Acceleration_Km_S2(A_Two_Body_Y + A_J2_Y),
       Z => Acceleration_Km_S2(A_Two_Body_Z + A_J2_Z));
end Compute_Acceleration;
```

### RK4 Integration Step

```ada
function Step_RK4
   (State : Propagator_State;
    Step  : Time_Seconds;
    Model : Force_Model'Class) return Propagator_State
is
   H : constant Real := Real(Step);
   H2 : constant Real := H / 2.0;
   H6 : constant Real := H / 6.0;

   -- State components
   R0 : constant Position_Vector := State.Position;
   V0 : constant Velocity_Vector := State.Velocity;
   T0 : constant Time_Seconds := State.Time;

   -- k1
   A1 : constant Acceleration_Vector := Model.Compute_Acceleration(T0, R0, V0);
   V1 : constant Velocity_Vector := V0;

   -- k2 (midpoint)
   R2 : constant Position_Vector := R0 + Scale(V1, H2);
   V2 : constant Velocity_Vector := V0 + Scale(A1, H2);
   A2 : constant Acceleration_Vector :=
      Model.Compute_Acceleration(T0 + Time_Seconds(H2), R2, V2);

   -- k3 (midpoint with k2 slopes)
   R3 : constant Position_Vector := R0 + Scale(V2, H2);
   V3 : constant Velocity_Vector := V0 + Scale(A2, H2);
   A3 : constant Acceleration_Vector :=
      Model.Compute_Acceleration(T0 + Time_Seconds(H2), R3, V3);

   -- k4 (endpoint)
   R4 : constant Position_Vector := R0 + Scale(V3, H);
   V4 : constant Velocity_Vector := V0 + Scale(A3, H);
   A4 : constant Acceleration_Vector :=
      Model.Compute_Acceleration(T0 + Step, R4, V4);

begin
   -- Weighted average
   return Propagator_State'
      (Position => R0 + Scale(V1 + 2.0*V2 + 2.0*V3 + V4, H6),
       Velocity => V0 + Scale(A1 + 2.0*A2 + 2.0*A3 + A4, H6),
       Time     => T0 + Step);
end Step_RK4;
```

### RK78 Dormand-Prince (Adaptive)

```ada
procedure Step_RK78
   (State     : in out Propagator_State;
    Step      : in Out Time_Seconds;
    Tolerance : in     Real;
    Model     : in     Force_Model'Class)
is
   -- Dormand-Prince 7(8) coefficients
   -- (Butcher tableau - abbreviated for clarity)

   H : Real := Real(Step);
   Error : Real;
   New_State_7 : Propagator_State;  -- 7th order solution
   New_State_8 : Propagator_State;  -- 8th order solution (for error estimate)

begin
   loop
      -- Compute both 7th and 8th order solutions
      -- ...RK78 coefficient calculations...

      -- Estimate error as difference between orders
      Error := Magnitude(New_State_8.Position - New_State_7.Position);

      if Error < Tolerance then
         -- Accept step
         State := New_State_7;

         -- Increase step size for next iteration (up to 2x)
         H := H * Min(2.0, 0.9 * (Tolerance / Error) ** (1.0 / 8.0));
         Step := Time_Seconds(H);
         exit;
      else
         -- Reject step, reduce step size
         H := H * Max(0.1, 0.9 * (Tolerance / Error) ** (1.0 / 7.0));
      end if;
   end loop;
end Step_RK78;
```

### Parallel Propagation (Ada 2022)

```ada
function Propagate_Parallel
   (Initials  : State_Array;
    T_End     : Time_Seconds;
    Tolerance : Real;
    Model     : Force_Model'Class) return State_Array
is
   Results : State_Array (Initials'Range);
begin
   -- Ada 2022 parallel loop
   parallel for I in Initials'Range loop
      Results(I) := Propagate_Adaptive
         (Initial   => Initials(I),
          T_End     => T_End,
          Tolerance => Tolerance,
          Model     => Model);
   end loop;

   return Results;
end Propagate_Parallel;
```

---

## Test Plan

### Energy Conservation (Sam)

```ada
procedure Test_Energy_Conservation is
   Initial : constant Propagator_State :=
      (Position => (7000.0, 0.0, 0.0),
       Velocity => (0.0, 7.5, 0.0),
       Time     => 0.0);

   Model : constant Two_Body_Model := (Mu => 398600.4418);

   E_Initial : constant Real := Specific_Energy(Initial, Model.Mu);

   -- Propagate 100 orbits
   Final : constant Propagator_State :=
      Propagate_Adaptive (Initial, 100.0 * 5400.0, 1.0e-12, Model);

   E_Final : constant Real := Specific_Energy(Final, Model.Mu);
begin
   Assert_Near (E_Initial, E_Final, Tolerance => 1.0e-10);
end Test_Energy_Conservation;
```

### Angular Momentum Conservation

```ada
procedure Test_Angular_Momentum_Conservation is
   -- Similar to energy test
   H_Initial : constant Real := Angular_Momentum(Initial);
   H_Final   : constant Real := Angular_Momentum(Final);
begin
   Assert_Near (H_Initial, H_Final, Tolerance => 1.0e-10);
end Test_Angular_Momentum_Conservation;
```

### J2 Perturbation Effects

```ada
procedure Test_J2_Secular_Drift is
   -- LEO satellite should show RAAN regression due to J2
   -- ~7° per day for typical LEO inclination
begin
   -- Verify qualitative behavior matches expected secular drift
end Test_J2_Secular_Drift;
```

---

## Performance Targets (Tom + Gaffer)

| Operation | Target | Notes |
|-----------|--------|-------|
| RK4 single step | < 500 ns | Inline acceleration |
| RK78 single step | < 2 μs | Adaptive overhead |
| 1 orbit (RK4, 60 steps) | < 50 μs | LEO period ~90 min |
| 100 orbits (RK78) | < 10 ms | Energy conserved |
| Parallel (1000 samples) | < 100 ms | 8 cores |

**Gaffer's Wisdom**:
> "RK4 with 60 steps per orbit has served us well for decades. Don't fix what ain't broken. Use RK78 only when high precision is truly needed."

---

## SPARK Annotations (Ben)

```ada
function Step_RK4 (State : Propagator_State;
                   Step  : Time_Seconds;
                   Model : Force_Model'Class) return Propagator_State
   with SPARK_Mode => On,
        Global => null,
        Pre    => Real(Step) > 0.0,
        Post   => Step_RK4'Result.Time = State.Time + Step;

function Specific_Energy (State : Propagator_State;
                          Mu    : Gravitational_Parameter) return Real
   with Global => null;
   -- Note: Cannot prove energy conservation without loop invariants
```

---

## Deliverables Checklist

- [ ] `hale_orbital-propagation.ads` - Package specification
- [ ] `hale_orbital-propagation.adb` - Implementation
- [ ] Two_Body_Model force model
- [ ] J2_Model force model
- [ ] Step_RK4 integrator
- [ ] Step_RK78 adaptive integrator
- [ ] Propagate_Fixed / Propagate_Adaptive
- [ ] Generate_Trajectory
- [ ] Propagate_Parallel (Ada 2022)
- [ ] Energy/angular momentum validators
- [ ] Test suite (conservation tests)
- [ ] Performance benchmarks
- [ ] SPARK annotations
- [ ] Lobelia's approval

---

*"Time is the canvas. The propagator is the brush. Paint accurate trajectories."*

— Gaffer Gamgee, Legacy Expert

