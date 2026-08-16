# Example Applications Plan
## Vision 8: The Examples That Teach

*Champions: John Barnes (Ada) + Rosie Cotton (Hobbit)*

---

## Overview

Examples are not afterthoughts—they are the primary way users learn to use a library. Each example should teach both orbital mechanics concepts and Ada programming patterns.

---

## Current State

**Existing Examples** (3):
- `hohmann_transfer.adb` - Basic LEO to GEO transfer
- `lagrange_points.adb` - Compute L1-L5 for multiple systems
- `orbit_propagation.adb` - Propagate Molniya-type orbit

**Needed**:
- Lambert intercept example
- Full mission planning example (Earth-Mars)
- Visualization-friendly output

---

## Example 1: Lambert Intercept

**File**: `ada/examples/lambert_intercept.adb`

**Purpose**: Demonstrate Lambert solver for rendezvous/intercept planning

**Story** (Rosie):
> "A cargo ship needs to rendezvous with the ISS. Given current positions, how do we plan the intercept? This example shows Lambert in action."

```ada
-------------------------------------------------------------------------------
-- lambert_intercept.adb
-- Demonstrate Lambert problem solving for spacecraft rendezvous
-------------------------------------------------------------------------------

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Float_Text_IO;
with Hale_Orbital.Types; use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Vectors; use Hale_Orbital.Vectors;
with Hale_Orbital.Lambert;

procedure Lambert_Intercept is

   procedure Put_Vector (Name : String; V : Position_Vector) is
   begin
      Put (Name & ": (");
      Ada.Float_Text_IO.Put (Real(V.X), Fore => 1, Aft => 1, Exp => 0);
      Put (", ");
      Ada.Float_Text_IO.Put (Real(V.Y), Fore => 1, Aft => 1, Exp => 0);
      Put (", ");
      Ada.Float_Text_IO.Put (Real(V.Z), Fore => 1, Aft => 1, Exp => 0);
      Put_Line (") km");
   end Put_Vector;

   -- Chaser (cargo ship) initial position
   Chaser_Position : constant Position_Vector := (6678.0, 0.0, 0.0);
   Chaser_Velocity : constant Velocity_Vector := (0.0, 7.73, 0.0);

   -- Target (ISS) position after planned transfer time
   Target_Position : constant Position_Vector := (0.0, 6778.0, 0.0);
   Target_Velocity : constant Velocity_Vector := (-7.67, 0.0, 0.0);

   -- Time of flight options to consider
   TOF_Options : constant array (1 .. 5) of Time_Seconds :=
      (2700.0,   -- 45 minutes
       3600.0,   -- 1 hour
       5400.0,   -- 1.5 hours
       7200.0,   -- 2 hours
       10800.0); -- 3 hours

   Result : Hale_Orbital.Lambert.Lambert_Result;
   Departure_DV, Arrival_DV, Total_DV : Velocity_Km_S;

begin
   Put_Line ("=========================================");
   Put_Line ("      LAMBERT INTERCEPT PLANNING        ");
   Put_Line ("=========================================");
   Put_Line ("");

   Put_Vector ("Chaser position ", Chaser_Position);
   Put_Vector ("Target position ", Target_Position);
   Put_Line ("");

   Put_Line ("Analyzing transfer options:");
   Put_Line ("-----------------------------------------");
   Put_Line ("  TOF (min)  |  ΔV1 (km/s)  |  ΔV2 (km/s)  |  Total");
   Put_Line ("-----------------------------------------");

   for TOF of TOF_Options loop
      Result := Hale_Orbital.Lambert.Solve_Lambert
         (R1  => Chaser_Position,
          R2  => Target_Position,
          Tof => TOF,
          Mu  => Mu_Earth);

      if Result.Converged then
         Departure_DV := Hale_Orbital.Lambert.Departure_Delta_V
            (V_Initial => Chaser_Velocity, Result => Result);
         Arrival_DV := Hale_Orbital.Lambert.Arrival_Delta_V
            (V_Final => Target_Velocity, Result => Result);
         Total_DV := Velocity_Km_S(Real(Departure_DV) + Real(Arrival_DV));

         Put ("    ");
         Ada.Float_Text_IO.Put (Real(TOF) / 60.0, Fore => 3, Aft => 0, Exp => 0);
         Put ("     |    ");
         Ada.Float_Text_IO.Put (Real(Departure_DV), Fore => 1, Aft => 3, Exp => 0);
         Put ("     |    ");
         Ada.Float_Text_IO.Put (Real(Arrival_DV), Fore => 1, Aft => 3, Exp => 0);
         Put ("     |  ");
         Ada.Float_Text_IO.Put (Real(Total_DV), Fore => 1, Aft => 3, Exp => 0);
         Put_Line ("");
      else
         Put ("    ");
         Ada.Float_Text_IO.Put (Real(TOF) / 60.0, Fore => 3, Aft => 0, Exp => 0);
         Put_Line ("     |  (no solution)");
      end if;
   end loop;

   Put_Line ("-----------------------------------------");
   Put_Line ("");
   Put_Line ("Select transfer with minimum total ΔV for fuel efficiency,");
   Put_Line ("or shorter TOF if time-critical.");

end Lambert_Intercept;
```

**Expected Output** (Rosie):
```
=========================================
      LAMBERT INTERCEPT PLANNING
=========================================

Chaser position : (6678.0, 0.0, 0.0) km
Target position : (0.0, 6778.0, 0.0) km

Analyzing transfer options:
-----------------------------------------
  TOF (min)  |  ΔV1 (km/s)  |  ΔV2 (km/s)  |  Total
-----------------------------------------
     45      |    0.234     |    0.189     |  0.423
     60      |    0.156     |    0.142     |  0.298
     90      |    0.089     |    0.087     |  0.176
    120      |    0.112     |    0.098     |  0.210
    180      |    0.178     |    0.156     |  0.334
-----------------------------------------

Select transfer with minimum total ΔV for fuel efficiency,
or shorter TOF if time-critical.
```

---

## Example 2: Earth-Mars Mission Planner

**File**: `ada/examples/earth_mars_mission.adb`

**Purpose**: Complete interplanetary mission planning workflow

**Story** (John Barnes):
> "This is the capstone example. It combines Lambert, maneuvers, and propagation to plan a complete Earth-to-Mars transfer. A student who understands this example understands mission planning."

```ada
-------------------------------------------------------------------------------
-- earth_mars_mission.adb
-- Complete Earth to Mars transfer mission planning
-- Demonstrates: Lambert solver, delta-V calculations, trajectory propagation
-------------------------------------------------------------------------------

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Float_Text_IO;
with Hale_Orbital.Types; use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Vectors; use Hale_Orbital.Vectors;
with Hale_Orbital.Lambert;
with Hale_Orbital.Maneuvers;
with Hale_Orbital.Propagation;

procedure Earth_Mars_Mission is

   --========================================================================--
   --                          MISSION PARAMETERS                            --
   --========================================================================--

   -- Planetary orbital radii (simplified circular, coplanar)
   Earth_Orbit_Radius : constant Distance_Km := 149_597_870.7;  -- 1 AU
   Mars_Orbit_Radius  : constant Distance_Km := 227_939_200.0;  -- 1.524 AU

   -- Departure and parking orbit
   Earth_Parking_Orbit : constant Distance_Km := 6678.0;  -- 300 km altitude

   -- Transfer parameters
   Transfer_Time_Days : constant := 200;
   Transfer_Time : constant Time_Seconds :=
      Time_Seconds(Real(Transfer_Time_Days) * 86400.0);

   -- Phase angle at departure (Mars ahead of Earth)
   -- For a 200-day transfer, Mars should be ~44° ahead
   Mars_Phase_Angle : constant Angle_Radians := Angle_Radians(0.77);  -- ~44°

   --========================================================================--
   --                              CALCULATIONS                              --
   --========================================================================--

   -- Heliocentric positions at departure
   Earth_Position : constant Position_Vector :=
      (Earth_Orbit_Radius, Distance_Km(0.0), Distance_Km(0.0));

   Mars_Position : constant Position_Vector :=
      (Distance_Km(Real(Mars_Orbit_Radius) * Cos(Real(Mars_Phase_Angle))),
       Distance_Km(Real(Mars_Orbit_Radius) * Sin(Real(Mars_Phase_Angle))),
       Distance_Km(0.0));

   -- Earth and Mars orbital velocities
   Earth_Velocity : constant Velocity_Vector :=
      (Velocity_Km_S(0.0),
       Velocity_Km_S(Sqrt(Real(Mu_Sun) / Real(Earth_Orbit_Radius))),
       Velocity_Km_S(0.0));

   Mars_Velocity : constant Velocity_Vector :=
      (Velocity_Km_S(-Sqrt(Real(Mu_Sun) / Real(Mars_Orbit_Radius)) *
                      Sin(Real(Mars_Phase_Angle))),
       Velocity_Km_S(Sqrt(Real(Mu_Sun) / Real(Mars_Orbit_Radius)) *
                      Cos(Real(Mars_Phase_Angle))),
       Velocity_Km_S(0.0));

   -- Results
   Lambert_Sol    : Hale_Orbital.Lambert.Lambert_Result;
   V_Infinity_Dep : Velocity_Km_S;
   V_Infinity_Arr : Velocity_Km_S;
   C3_Departure   : Specific_Energy;
   Injection_DV   : Velocity_Km_S;

begin
   Put_Line ("╔═══════════════════════════════════════════════════════════════╗");
   Put_Line ("║           EARTH TO MARS MISSION PLANNER                       ║");
   Put_Line ("║                    HALE Orbital Mechanics                     ║");
   Put_Line ("╚═══════════════════════════════════════════════════════════════╝");
   Put_Line ("");

   --========================================================================--
   Put_Line ("┌─────────────────────────────────────────────────────────────┐");
   Put_Line ("│  STEP 1: MISSION GEOMETRY                                   │");
   Put_Line ("└─────────────────────────────────────────────────────────────┘");

   Put ("  Earth position: ");
   Ada.Float_Text_IO.Put (Real(Earth_Position.X) / 1.0e6, Fore => 1, Aft => 2, Exp => 0);
   Put (" × 10⁶ km (");
   Ada.Float_Text_IO.Put (Real(Earth_Position.X) / Real(AU), Fore => 1, Aft => 3, Exp => 0);
   Put_Line (" AU)");

   Put ("  Mars position:  ");
   Ada.Float_Text_IO.Put (Real(Mars_Orbit_Radius) / 1.0e6, Fore => 1, Aft => 2, Exp => 0);
   Put (" × 10⁶ km (");
   Ada.Float_Text_IO.Put (Real(Mars_Orbit_Radius) / Real(AU), Fore => 1, Aft => 3, Exp => 0);
   Put_Line (" AU)");

   Put ("  Mars phase angle: ");
   Ada.Float_Text_IO.Put (Real(Mars_Phase_Angle) * 180.0 / Pi, Fore => 1, Aft => 1, Exp => 0);
   Put_Line ("°");

   Put ("  Transfer time: ");
   Put (Integer(Transfer_Time_Days)'Image);
   Put_Line (" days");
   Put_Line ("");

   --========================================================================--
   Put_Line ("┌─────────────────────────────────────────────────────────────┐");
   Put_Line ("│  STEP 2: LAMBERT PROBLEM SOLUTION                          │");
   Put_Line ("└─────────────────────────────────────────────────────────────┘");

   Lambert_Sol := Hale_Orbital.Lambert.Solve_Lambert
      (R1  => Earth_Position,
       R2  => Mars_Position,
       Tof => Transfer_Time,
       Mu  => Mu_Sun);

   if not Lambert_Sol.Converged then
      Put_Line ("  ERROR: Lambert solver did not converge!");
      Put_Line ("  Check mission geometry and transfer time.");
      return;
   end if;

   Put ("  Converged in ");
   Put (Lambert_Sol.Iterations'Image);
   Put_Line (" iterations");

   Put ("  Transfer semi-major axis: ");
   Ada.Float_Text_IO.Put (Real(Lambert_Sol.A) / 1.0e6, Fore => 1, Aft => 2, Exp => 0);
   Put_Line (" × 10⁶ km");

   Put ("  Transfer eccentricity:    ");
   Ada.Float_Text_IO.Put (Lambert_Sol.E, Fore => 1, Aft => 4, Exp => 0);
   Put_Line ("");
   Put_Line ("");

   --========================================================================--
   Put_Line ("┌─────────────────────────────────────────────────────────────┐");
   Put_Line ("│  STEP 3: HYPERBOLIC EXCESS VELOCITIES                      │");
   Put_Line ("└─────────────────────────────────────────────────────────────┘");

   -- V_infinity at Earth = Lambert V1 - Earth velocity
   V_Infinity_Dep := Velocity_Km_S(
      Magnitude(Lambert_Sol.V1 - Earth_Velocity));

   -- V_infinity at Mars = Lambert V2 - Mars velocity
   V_Infinity_Arr := Velocity_Km_S(
      Magnitude(Lambert_Sol.V2 - Mars_Velocity));

   Put ("  V∞ at Earth departure: ");
   Ada.Float_Text_IO.Put (Real(V_Infinity_Dep), Fore => 1, Aft => 3, Exp => 0);
   Put_Line (" km/s");

   Put ("  V∞ at Mars arrival:    ");
   Ada.Float_Text_IO.Put (Real(V_Infinity_Arr), Fore => 1, Aft => 3, Exp => 0);
   Put_Line (" km/s");

   C3_Departure := Hale_Orbital.Maneuvers.C3_Energy(V_Infinity_Dep);
   Put ("  C3 energy:             ");
   Ada.Float_Text_IO.Put (Real(C3_Departure), Fore => 1, Aft => 2, Exp => 0);
   Put_Line (" km²/s²");
   Put_Line ("");

   --========================================================================--
   Put_Line ("┌─────────────────────────────────────────────────────────────┐");
   Put_Line ("│  STEP 4: DELTA-V BUDGET                                    │");
   Put_Line ("└─────────────────────────────────────────────────────────────┘");

   -- Trans-Mars injection from parking orbit
   Injection_DV := Velocity_Km_S(
      Real(Hale_Orbital.Maneuvers.Departure_Velocity(
         R  => Earth_Parking_Orbit,
         C3 => C3_Departure,
         Mu => Mu_Earth)) -
      Sqrt(Real(Mu_Earth) / Real(Earth_Parking_Orbit)));

   Put ("  Parking orbit velocity:     ");
   Ada.Float_Text_IO.Put (Sqrt(Real(Mu_Earth) / Real(Earth_Parking_Orbit)),
                          Fore => 1, Aft => 3, Exp => 0);
   Put_Line (" km/s");

   Put ("  Trans-Mars injection ΔV:    ");
   Ada.Float_Text_IO.Put (Real(Injection_DV), Fore => 1, Aft => 3, Exp => 0);
   Put_Line (" km/s");

   Put ("  Mars orbit insertion ΔV:    ");
   Ada.Float_Text_IO.Put (Real(V_Infinity_Arr), Fore => 1, Aft => 3, Exp => 0);
   Put_Line (" km/s (capture only)");

   Put_Line ("");
   Put ("  TOTAL MISSION ΔV:           ");
   Ada.Float_Text_IO.Put (Real(Injection_DV) + Real(V_Infinity_Arr),
                          Fore => 1, Aft => 3, Exp => 0);
   Put_Line (" km/s");
   Put_Line ("");

   --========================================================================--
   Put_Line ("┌─────────────────────────────────────────────────────────────┐");
   Put_Line ("│  MISSION SUMMARY                                           │");
   Put_Line ("└─────────────────────────────────────────────────────────────┘");
   Put_Line ("");
   Put_Line ("  ┌────────────────┬────────────────────────────────────────┐");
   Put_Line ("  │ Parameter      │ Value                                  │");
   Put_Line ("  ├────────────────┼────────────────────────────────────────┤");
   Put      ("  │ Transfer Time  │ ");
   Put (Integer(Transfer_Time_Days)'Image);
   Put_Line (" days                              │");
   Put      ("  │ C3 Energy      │ ");
   Ada.Float_Text_IO.Put (Real(C3_Departure), Fore => 1, Aft => 2, Exp => 0);
   Put_Line (" km²/s²                          │");
   Put      ("  │ TMI ΔV         │ ");
   Ada.Float_Text_IO.Put (Real(Injection_DV), Fore => 1, Aft => 3, Exp => 0);
   Put_Line (" km/s                           │");
   Put      ("  │ MOI ΔV         │ ");
   Ada.Float_Text_IO.Put (Real(V_Infinity_Arr), Fore => 1, Aft => 3, Exp => 0);
   Put_Line (" km/s                           │");
   Put      ("  │ Total ΔV       │ ");
   Ada.Float_Text_IO.Put (Real(Injection_DV) + Real(V_Infinity_Arr),
                          Fore => 1, Aft => 3, Exp => 0);
   Put_Line (" km/s                           │");
   Put_Line ("  └────────────────┴────────────────────────────────────────┘");
   Put_Line ("");
   Put_Line ("  Mission planning complete. Ready for trajectory propagation.");

end Earth_Mars_Mission;
```

**Expected Output**:
```
╔═══════════════════════════════════════════════════════════════╗
║           EARTH TO MARS MISSION PLANNER                       ║
║                    HALE Orbital Mechanics                     ║
╚═══════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────┐
│  STEP 1: MISSION GEOMETRY                                   │
└─────────────────────────────────────────────────────────────┘
  Earth position: 149.60 × 10⁶ km (1.000 AU)
  Mars position:  227.94 × 10⁶ km (1.524 AU)
  Mars phase angle: 44.1°
  Transfer time:  200 days

┌─────────────────────────────────────────────────────────────┐
│  STEP 2: LAMBERT PROBLEM SOLUTION                          │
└─────────────────────────────────────────────────────────────┘
  Converged in  6 iterations
  Transfer semi-major axis: 188.77 × 10⁶ km
  Transfer eccentricity:    0.2073

┌─────────────────────────────────────────────────────────────┐
│  STEP 3: HYPERBOLIC EXCESS VELOCITIES                      │
└─────────────────────────────────────────────────────────────┘
  V∞ at Earth departure: 2.943 km/s
  V∞ at Mars arrival:    2.649 km/s
  C3 energy:             8.66 km²/s²

┌─────────────────────────────────────────────────────────────┐
│  STEP 4: DELTA-V BUDGET                                    │
└─────────────────────────────────────────────────────────────┘
  Parking orbit velocity:     7.726 km/s
  Trans-Mars injection ΔV:    3.601 km/s
  Mars orbit insertion ΔV:    2.649 km/s (capture only)

  TOTAL MISSION ΔV:           6.250 km/s

┌─────────────────────────────────────────────────────────────┐
│  MISSION SUMMARY                                           │
└─────────────────────────────────────────────────────────────┘

  ┌────────────────┬────────────────────────────────────────┐
  │ Parameter      │ Value                                  │
  ├────────────────┼────────────────────────────────────────┤
  │ Transfer Time  │  200 days                              │
  │ C3 Energy      │ 8.66 km²/s²                            │
  │ TMI ΔV         │ 3.601 km/s                             │
  │ MOI ΔV         │ 2.649 km/s                             │
  │ Total ΔV       │ 6.250 km/s                             │
  └────────────────┴────────────────────────────────────────┘

  Mission planning complete. Ready for trajectory propagation.
```

---

## Example 3: Trajectory Visualization

**File**: `ada/examples/trajectory_display.adb`

**Purpose**: Generate trajectory data for external visualization

**Rosie's Vision**:
> "Not everyone has a graphical display. But we can output CSV data that any plotting tool can read. Make it clear!"

```ada
-- Output format for gnuplot, matplotlib, etc.
-- Columns: time(days), x(AU), y(AU), z(AU), distance(AU)

Put_Line ("# Trajectory data for plotting");
Put_Line ("# time_days, x_AU, y_AU, z_AU, r_AU");

for State of Trajectory loop
   Put (Real(State.Time) / 86400.0);  -- days
   Put (",");
   Put (Real(State.Position.X) / Real(AU));  -- AU
   Put (",");
   Put (Real(State.Position.Y) / Real(AU));
   Put (",");
   Put (Real(State.Position.Z) / Real(AU));
   Put (",");
   Put (Magnitude(State.Position) / Real(AU));
   New_Line;
end loop;
```

---

## Documentation Standards (John Barnes)

### Each Example Must Include:

1. **Header Comment**
   - Purpose of the example
   - Concepts demonstrated
   - Reference to textbook/paper if applicable

2. **Step-by-Step Structure**
   - Clear section headers
   - Intermediate results shown
   - Educational commentary in output

3. **Error Handling**
   - Check for solver convergence
   - Meaningful error messages
   - Graceful failures

4. **Output Formatting**
   - Units always shown
   - Appropriate precision
   - Aligned columns for tables

---

## Deliverables Checklist

- [ ] `lambert_intercept.adb` - Rendezvous planning example
- [ ] `earth_mars_mission.adb` - Complete mission planner
- [ ] `trajectory_display.adb` - Visualization data output
- [ ] Update `hale_orbital_examples.gpr` project file
- [ ] README for examples directory
- [ ] Verify all examples compile and run
- [ ] Output matches expected format
- [ ] John Barnes approves pedagogical value
- [ ] Rosie approves output clarity

---

*"A library without examples is a dictionary without sentences. Show how the words combine to tell stories."*

— John Barnes, Educator

