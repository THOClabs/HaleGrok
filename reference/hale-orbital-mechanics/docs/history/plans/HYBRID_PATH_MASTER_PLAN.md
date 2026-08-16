# Mission Planning Hybrid Path
## Master Implementation Plan

*Champions: Tucker Taft (Ada Lead), Frodo Baggins (Integration Lead)*

---

## Executive Summary

This plan combines four of Gandalf's visions into a single hybrid implementation:

| Vision | Component | Status | Priority |
|--------|-----------|--------|----------|
| 2 | Lambert Solver | Specification exists | P1 |
| 4 | Maneuvers Package | Specification exists | P1 |
| 5 | Propagation Engine | Partial implementation | P2 |
| 8 | Example Applications | 3 exist, need mission example | P2 |

**Goal**: A complete mission planning capability that can design an Earth-to-Mars transfer mission end-to-end.

---

## Architecture Overview

```
                         Mission Planning System
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        ▼                         ▼                         ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│    Lambert    │       │   Maneuvers   │       │  Propagation  │
│    Package    │       │    Package    │       │    Package    │
├───────────────┤       ├───────────────┤       ├───────────────┤
│ Solve_Lambert │       │ Hohmann_Xfer  │       │ Propagate_RK4 │
│ Multi_Rev     │       │ Bielliptic    │       │ Propagate_RK78│
│ Transfer_Angle│       │ Plane_Change  │       │ Force_Models  │
│ Delta_V_Calc  │       │ Phasing       │       │ Parallel_Prop │
└───────┬───────┘       └───────┬───────┘       └───────┬───────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │   Mission Planner     │
                    │      (Example)        │
                    ├───────────────────────┤
                    │ Earth_Mars_Transfer   │
                    │ Trajectory_Display    │
                    │ Delta_V_Budget        │
                    └───────────────────────┘
```

---

## Component Plans

### 1. Lambert Solver Completion

**File**: `ada/src/hale_orbital-lambert.adb`

**Current State**: Specification complete, body needs implementation

**Implementation Tasks**:

```ada
-- Task 1.1: Implement universal variable formulation
-- Reference: Battin, "An Introduction to the Mathematics and
--            Methods of Astrodynamics", Section 6.3

function Solve_Lambert (...) return Lambert_Result is
   -- Use Battin's universal variable approach
   -- Stumpff functions C(z) and S(z) for all orbit types
   -- Newton-Raphson iteration on universal variable
begin
   -- 1. Compute geometry (chord, semi-perimeter)
   -- 2. Initialize universal variable guess
   -- 3. Iterate until convergence
   -- 4. Compute velocity vectors from converged solution
end Solve_Lambert;
```

**Contracts** (Tucker Taft):
```ada
function Solve_Lambert (R1, R2 : Position_Vector;
                        Tof    : Time_Seconds;
                        Mu     : Gravitational_Parameter;
                        ...) return Lambert_Result
   with Pre  => Magnitude(R1) > 0.0
            and Magnitude(R2) > 0.0
            and Tof > 0.0
            and Mu > 0.0,
        Post => (if Solve_Lambert'Result.Converged then
                   Position_At_Time(Solve_Lambert'Result, 0.0, R1, Mu)
                   within 1.0e-6 of R1);
```

**Test Cases** (Sam):
| Test | R1 | R2 | TOF | Expected V1 | Source |
|------|----|----|-----|-------------|--------|
| LEO-GEO | 6678 km | 42164 km | 5.3 hr | 10.15 km/s | Vallado Ex 5-1 |
| Earth-Mars | 1 AU | 1.524 AU | 200 d | 32.7 km/s | Vallado Ex 5-2 |

**Edge Cases** (Pippin):
- 180° transfer (degenerate)
- Very short TOF (hyperbolic)
- Very long TOF (multi-revolution)
- R1 = R2 (invalid)

---

### 2. Maneuvers Package Implementation

**File**: `ada/src/hale_orbital-maneuvers.adb`

**Current State**: Specification complete, body needs implementation

**Implementation Tasks**:

```ada
-- Task 2.1: Hohmann Transfer
function Hohmann_Transfer (R_Initial : Distance_Km;
                           R_Final   : Distance_Km;
                           Mu        : Gravitational_Parameter)
   return Hohmann_Result
is
   A_Transfer : constant Distance_Km :=
      Distance_Km ((Real(R_Initial) + Real(R_Final)) / 2.0);

   V_Initial : constant Velocity_Km_S :=
      Velocity_Km_S (Sqrt (Real(Mu) / Real(R_Initial)));

   V_Transfer_Periapsis : constant Velocity_Km_S :=
      Velocity_Km_S (Sqrt (Real(Mu) * (2.0/Real(R_Initial) -
                                        1.0/Real(A_Transfer))));
begin
   -- Compute both burns and transfer time
   return (Delta_V1      => V_Transfer_Periapsis - V_Initial,
           Delta_V2      => ...,
           Total_Delta_V => ...,
           Transfer_Time => ...,
           A_Transfer    => A_Transfer,
           E_Transfer    => ...);
end Hohmann_Transfer;
```

**Performance Target** (Tom Cotton):
- Hohmann calculation: < 100 ns
- All functions inlined where beneficial
- No heap allocation

**Validation Data** (Sam):
| Transfer | R1 | R2 | Expected ΔV | Source |
|----------|----|----|-------------|--------|
| LEO-GEO | 6678 km | 42164 km | 3.935 km/s | Hale Table 6-1 |
| LEO-Moon | 6678 km | 384400 km | 3.13 km/s | Hale Table 6-2 |

---

### 3. Propagation Engine Enhancement

**File**: `ada/src/hale_orbital-propagation.ads/adb` (new package)

**Current State**: Basic RK4 exists in examples, needs proper package

**Implementation Tasks**:

```ada
-- Task 3.1: Create propagation package
package Hale_Orbital.Propagation
   with SPARK_Mode => On
is
   -- Force model interface
   type Force_Model is interface;

   function Acceleration (Model : Force_Model;
                          T     : Time_Seconds;
                          State : State_Vector) return Acceleration_Vector
      is abstract;

   -- Two-body force model
   type Two_Body_Model is new Force_Model with record
      Mu : Gravitational_Parameter;
   end record;

   -- Propagators
   function Propagate_RK4 (Initial : State_Vector;
                           T_Start : Time_Seconds;
                           T_End   : Time_Seconds;
                           Step    : Time_Seconds;
                           Model   : Force_Model'Class) return State_Vector;

   function Propagate_RK78 (Initial   : State_Vector;
                            T_Start   : Time_Seconds;
                            T_End     : Time_Seconds;
                            Tolerance : Real;
                            Model     : Force_Model'Class) return State_Vector;

   -- Trajectory generation
   type Trajectory is array (Positive range <>) of State_Vector;

   function Generate_Trajectory (Initial : State_Vector;
                                 T_Start : Time_Seconds;
                                 T_End   : Time_Seconds;
                                 N_Points: Positive;
                                 Model   : Force_Model'Class) return Trajectory;
end Hale_Orbital.Propagation;
```

**Parallel Propagation** (Tucker Taft):
```ada
-- Ada 2022 parallel blocks for Monte Carlo
function Monte_Carlo_Propagation (Samples   : State_Vector_Array;
                                  T_End     : Time_Seconds;
                                  Model     : Force_Model'Class)
   return State_Vector_Array
is
   Results : State_Vector_Array (Samples'Range);
begin
   parallel for I in Samples'Range loop
      Results(I) := Propagate_RK78 (Samples(I), 0.0, T_End, 1.0e-12, Model);
   end loop;
   return Results;
end Monte_Carlo_Propagation;
```

---

### 4. Mission Planning Example

**File**: `ada/examples/earth_mars_mission.adb`

**Purpose**: Demonstrate complete mission planning workflow

**Structure**:

```ada
-- earth_mars_mission.adb
-- Complete Earth to Mars transfer mission planning example

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Float_Text_IO; use Ada.Float_Text_IO;
with Hale_Orbital.Types; use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Lambert;
with Hale_Orbital.Maneuvers;
with Hale_Orbital.Propagation;

procedure Earth_Mars_Mission is
   -- Mission parameters
   Earth_Orbit_Radius : constant Distance_Km := 149_597_870.7;  -- 1 AU
   Mars_Orbit_Radius  : constant Distance_Km := 227_939_200.0;  -- 1.524 AU
   Transfer_Time      : constant Time_Seconds := 200.0 * 86400.0; -- 200 days

   -- Departure conditions
   Earth_Position : Position_Vector;
   Mars_Position  : Position_Vector;

   -- Results
   Lambert_Sol    : Hale_Orbital.Lambert.Lambert_Result;
   Departure_DV   : Velocity_Km_S;
   Arrival_DV     : Velocity_Km_S;
   Trajectory     : Hale_Orbital.Propagation.Trajectory;

begin
   Put_Line ("===========================================");
   Put_Line ("     EARTH TO MARS MISSION PLANNER        ");
   Put_Line ("===========================================");
   Put_Line ("");

   -- Step 1: Define planetary positions at departure
   -- (Simplified: assumes circular, coplanar orbits)
   Earth_Position := (Earth_Orbit_Radius, 0.0, 0.0);

   -- Mars position after transfer time
   -- (In reality, would use ephemeris data)
   Mars_Position := (Mars_Orbit_Radius * Cos(Phase_Angle),
                     Mars_Orbit_Radius * Sin(Phase_Angle),
                     0.0);

   -- Step 2: Solve Lambert problem
   Put_Line ("Step 1: Solving Lambert Problem...");
   Lambert_Sol := Hale_Orbital.Lambert.Solve_Lambert
      (R1       => Earth_Position,
       R2       => Mars_Position,
       Tof      => Transfer_Time,
       Mu       => Mu_Sun,
       Long_Way => False);

   if Lambert_Sol.Converged then
      Put_Line ("  Solution converged in" &
                Lambert_Sol.Iterations'Image & " iterations");
   else
      Put_Line ("  ERROR: Lambert solver did not converge");
      return;
   end if;

   -- Step 3: Calculate delta-V budget
   Put_Line ("");
   Put_Line ("Step 2: Delta-V Budget");

   Departure_DV := Hale_Orbital.Lambert.Departure_Delta_V
      (V_Initial => Earth_Velocity,
       Result    => Lambert_Sol);

   Arrival_DV := Hale_Orbital.Lambert.Arrival_Delta_V
      (V_Final => Mars_Velocity,
       Result  => Lambert_Sol);

   Put ("  Departure ΔV: ");
   Put (Real(Departure_DV), Fore => 1, Aft => 3, Exp => 0);
   Put_Line (" km/s");

   Put ("  Arrival ΔV:   ");
   Put (Real(Arrival_DV), Fore => 1, Aft => 3, Exp => 0);
   Put_Line (" km/s");

   Put ("  Total ΔV:     ");
   Put (Real(Departure_DV + Arrival_DV), Fore => 1, Aft => 3, Exp => 0);
   Put_Line (" km/s");

   -- Step 4: Propagate trajectory
   Put_Line ("");
   Put_Line ("Step 3: Trajectory Propagation");

   Trajectory := Hale_Orbital.Propagation.Generate_Trajectory
      (Initial  => (Earth_Position, Lambert_Sol.V1),
       T_Start  => 0.0,
       T_End    => Transfer_Time,
       N_Points => 100,
       Model    => Two_Body_Model'(Mu => Mu_Sun));

   Put_Line ("  Generated" & Trajectory'Length'Image & " trajectory points");

   -- Step 5: Display mission summary
   Put_Line ("");
   Put_Line ("===========================================");
   Put_Line ("           MISSION SUMMARY                 ");
   Put_Line ("===========================================");
   Put_Line ("  Transfer Time:  200 days");
   Put ("  Semi-major Axis: ");
   Put (Real(Lambert_Sol.A), Fore => 1, Aft => 0, Exp => 0);
   Put_Line (" km");
   Put ("  Eccentricity:    ");
   Put (Lambert_Sol.E, Fore => 1, Aft => 4, Exp => 0);
   Put_Line ("");
   Put_Line ("===========================================");

end Earth_Mars_Mission;
```

---

## Implementation Schedule

### Phase 1: Lambert Completion
**Lead**: Tucker Taft + Merry
**Tasks**:
1. Implement Stumpff functions
2. Implement universal variable solver
3. Add multi-revolution capability
4. Handle degenerate cases
5. Validate against Vallado

### Phase 2: Maneuvers Implementation
**Lead**: Robert Dewar + Tom Cotton
**Tasks**:
1. Implement Hohmann_Transfer body
2. Implement Bielliptic_Transfer
3. Implement plane change functions
4. Implement phasing maneuvers
5. Optimize for performance

### Phase 3: Propagation Package
**Lead**: Tucker Taft + Gaffer
**Tasks**:
1. Create package structure
2. Implement RK4 propagator
3. Implement RK78 adaptive
4. Add force model interface
5. Add parallel propagation

### Phase 4: Integration & Examples
**Lead**: Jean Ichbiah + Frodo
**Tasks**:
1. Integration testing
2. Earth-Mars example
3. Additional examples
4. Documentation
5. Final review

---

## Quality Gates

### Per-Component Gates (Sam + Lobelia)

| Gate | Criteria | Verified By |
|------|----------|-------------|
| G1 | Compiles clean with -gnatwe | CI |
| G2 | All tests pass | Sam |
| G3 | SPARK flow analysis clean | Ben |
| G4 | Performance targets met | Tom |
| G5 | Code review approved | Lobelia |
| G6 | Documentation complete | Folco |

### Integration Gates (Frodo)

| Gate | Criteria |
|------|----------|
| I1 | Lambert + Maneuvers work together |
| I2 | Propagation validates Lambert solutions |
| I3 | Example runs end-to-end |
| I4 | No regressions in existing tests |

---

## Risk Register

| Risk | Impact | Mitigation | Owner |
|------|--------|------------|-------|
| Lambert convergence issues | High | Multiple solver approaches | Tucker |
| Performance targets missed | Medium | Early profiling | Tom |
| SPARK proof failures | Medium | Incremental annotation | Ben |
| Integration conflicts | Low | Daily integration builds | Frodo |

---

## Success Definition

The Hybrid Path is **COMPLETE** when:

1. ✅ Lambert solver passes all Vallado test cases
2. ✅ Maneuvers package matches Hale reference values
3. ✅ Propagator conserves energy to 1e-12
4. ✅ Earth-Mars example runs successfully
5. ✅ All quality gates passed
6. ✅ Lobelia approves the final PR

---

*"Four visions, one path, one destination: working mission planning in Ada."*

— The Council and Fellowship

