# Getting Started with HALE Orbital Mechanics

This tutorial walks you through your first orbital mechanics calculations using the HALE library.

## Prerequisites

### Install GNAT Ada Compiler

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install gnat gprbuild
```

**macOS (using Homebrew):**
```bash
brew install gprbuild
```

**Windows:**
Download GNAT Community Edition from [AdaCore](https://www.adacore.com/download) or use Alire.

**Using Alire (Recommended):**
```bash
# Install Alire from https://alire.ada.dev/
alr toolchain --select gnat_native
```

### Clone the Repository

```bash
git clone https://github.com/THOClabs/hale-orbital-mechanics.git
cd hale-orbital-mechanics
```

## Build the Library

```bash
cd ada
gprbuild -P hale_orbital.gpr -XBUILD_MODE=debug
```

This creates:
- `lib/libhale_orbital.a` - Static library
- `obj/` - Object files

## Your First Program: Hohmann Transfer

Create a file `my_first_orbit.adb`:

```ada
with Ada.Text_IO;           use Ada.Text_IO;
with Hale_Orbital.Types;    use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Maneuvers; use Hale_Orbital.Maneuvers;

procedure My_First_Orbit is
   --  LEO to GEO transfer (classic example)
   R_LEO : constant Distance_Km := 6578.0;   -- 200 km altitude
   R_GEO : constant Distance_Km := 42164.0;  -- Geostationary orbit

   Result : Hohmann_Result;
begin
   Put_Line ("=== Hohmann Transfer: LEO to GEO ===");
   Put_Line ("");

   --  Compute the transfer
   Result := Hohmann_Transfer (R_LEO, R_GEO, Mu_Earth);

   --  Display results
   Put_Line ("Initial orbit radius: " & Distance_Km'Image (R_LEO) & " km");
   Put_Line ("Final orbit radius:   " & Distance_Km'Image (R_GEO) & " km");
   Put_Line ("");
   Put_Line ("Delta-V 1 (departure): " & Velocity_Km_S'Image (Result.Delta_V1) & " km/s");
   Put_Line ("Delta-V 2 (arrival):   " & Velocity_Km_S'Image (Result.Delta_V2) & " km/s");
   Put_Line ("Total Delta-V:         " & Velocity_Km_S'Image (Result.Total_Delta_V) & " km/s");
   Put_Line ("");
   Put_Line ("Transfer time: " & Time_Seconds'Image (Result.Transfer_Time) & " seconds");
   Put_Line ("             = " & Real'Image (Real (Result.Transfer_Time) / 3600.0) & " hours");
end My_First_Orbit;
```

### Build and Run

Create a simple project file `my_first_orbit.gpr`:

```ada
with "../hale_orbital.gpr";

project My_First_Orbit is
   for Source_Dirs use (".");
   for Object_Dir use "obj";
   for Main use ("my_first_orbit.adb");
end My_First_Orbit;
```

Build and run:

```bash
gprbuild -P my_first_orbit.gpr
./obj/my_first_orbit
```

Expected output:
```
=== Hohmann Transfer: LEO to GEO ===

Initial orbit radius:  6.57800E+03 km
Final orbit radius:    4.21640E+04 km

Delta-V 1 (departure):  2.45700E+00 km/s
Delta-V 2 (arrival):    1.47800E+00 km/s
Total Delta-V:          3.93500E+00 km/s

Transfer time:  1.90800E+04 seconds
             =  5.30000E+00 hours
```

## Orbit Propagation Example

Propagate a satellite's position over time using numerical integration:

```ada
with Ada.Text_IO;             use Ada.Text_IO;
with Hale_Orbital.Types;      use Hale_Orbital.Types;
with Hale_Orbital.Constants;  use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;    use Hale_Orbital.Vectors;
with Hale_Orbital.Twobody;    use Hale_Orbital.Twobody;
with Hale_Orbital.Propagation; use Hale_Orbital.Propagation;

procedure Propagate_Orbit is
   --  ISS-like initial conditions (circular orbit at 400 km altitude)
   R_Altitude : constant Real := Real (R_Earth) + 400.0;  -- km
   V_Circ : constant Velocity_Km_S := Circular_Velocity (Distance_Km (R_Altitude), Mu_Earth);

   --  Initial state: position along X, velocity along Y
   Initial : constant State_Vector := (
      Position => (R_Altitude, 0.0, 0.0),
      Velocity => (0.0, Real (V_Circ), 0.0)
   );

   --  Two-body dynamics model
   Model : constant Two_Body_Model := (Mu => Mu_Earth);

   --  Propagation time: one orbital period
   Period : constant Time_Seconds := Orbital_Period (Distance_Km (R_Altitude), Mu_Earth);

   --  Final state after propagation
   Final : State_Vector;
begin
   Put_Line ("=== Orbit Propagation (RK4) ===");
   Put_Line ("");
   Put_Line ("Initial orbit: " & Real'Image (R_Altitude) & " km radius (circular)");
   Put_Line ("Orbital period: " & Real'Image (Real (Period) / 60.0) & " minutes");
   Put_Line ("");
   Put_Line ("Initial position: (" &
             Real'Image (Initial.Position (1)) & ", " &
             Real'Image (Initial.Position (2)) & ", " &
             Real'Image (Initial.Position (3)) & ") km");
   Put_Line ("Initial velocity: (" &
             Real'Image (Initial.Velocity (1)) & ", " &
             Real'Image (Initial.Velocity (2)) & ", " &
             Real'Image (Initial.Velocity (3)) & ") km/s");
   Put_Line ("");

   --  Propagate using RK4 with 10-second step size
   Final := Propagate_RK4 (Initial, 0.0, Period, 10.0, Model);

   Put_Line ("After one orbit:");
   Put_Line ("Final position: (" &
             Real'Image (Final.Position (1)) & ", " &
             Real'Image (Final.Position (2)) & ", " &
             Real'Image (Final.Position (3)) & ") km");
   Put_Line ("Final velocity: (" &
             Real'Image (Final.Velocity (1)) & ", " &
             Real'Image (Final.Velocity (2)) & ", " &
             Real'Image (Final.Velocity (3)) & ") km/s");
   Put_Line ("");

   --  Verify orbit closure (should return to start)
   Put_Line ("Position error: " &
             Real'Image (Magnitude (Final.Position - Initial.Position)) & " km");
end Propagate_Orbit;
```

### High-Precision Propagation (RK78)

For more accurate results, use the adaptive Dormand-Prince integrator:

```ada
--  RK78 with adaptive step size (tolerance-based)
Final := Propagate_RK78 (Initial, 0.0, Period, 1.0e-12, Model);
```

## Lambert Problem: Interplanetary Transfer

Solve for a transfer trajectory between two positions:

```ada
with Ada.Text_IO;            use Ada.Text_IO;
with Hale_Orbital.Types;     use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Lambert;   use Hale_Orbital.Lambert;

procedure Lambert_Transfer is
   --  Earth departure position (1 AU from Sun, in ecliptic plane)
   R1 : constant Position_Vector := (149.6e6, 0.0, 0.0);  -- km

   --  Mars arrival position (1.524 AU, 45 degrees ahead)
   R2 : constant Position_Vector := (161.3e6, 161.3e6, 0.0);  -- km

   --  Time of flight: 200 days
   Tof : constant Time_Seconds := 200.0 * 86400.0;

   Result : Lambert_Result;
begin
   Put_Line ("=== Lambert Transfer: Earth to Mars ===");
   Put_Line ("");

   Result := Solve_Lambert (R1, R2, Tof, Mu_Sun);

   if Result.Converged then
      Put_Line ("Solution converged in " &
                Natural'Image (Result.Iterations) & " iterations");
      Put_Line ("");
      Put_Line ("Departure velocity: (" &
                Real'Image (Result.V1 (1)) & "," &
                Real'Image (Result.V1 (2)) & "," &
                Real'Image (Result.V1 (3)) & ") km/s");
      Put_Line ("Arrival velocity:   (" &
                Real'Image (Result.V2 (1)) & "," &
                Real'Image (Result.V2 (2)) & "," &
                Real'Image (Result.V2 (3)) & ") km/s");
      Put_Line ("");
      Put_Line ("Transfer semi-major axis: " &
                Distance_Km'Image (Result.A) & " km");
   else
      Put_Line ("Solution did not converge!");
   end if;
end Lambert_Transfer;
```

## Key Concepts

### Dimensional Types

The library uses Ada's strong typing for unit safety:

```ada
type Distance_Km is new Real;           -- Distance in kilometers
type Velocity_Km_S is new Real;         -- Velocity in km/s
type Time_Seconds is new Real;          -- Time in seconds
type Angle_Radians is new Real;         -- Angles in radians
type Gravitational_Parameter is new Real; -- km^3/s^2
```

This prevents unit errors at compile time:

```ada
--  This will NOT compile (type mismatch):
Distance : Distance_Km := 1000.0;
Velocity : Velocity_Km_S := Distance;  -- Error!

--  Must explicitly convert if intentional:
Velocity := Velocity_Km_S (Distance);  -- OK, developer acknowledges
```

### Constants

Common gravitational parameters are provided:

```ada
Mu_Earth : constant Gravitational_Parameter := 398600.4418;  -- km^3/s^2
Mu_Sun   : constant Gravitational_Parameter := 1.32712440018e11;
Mu_Moon  : constant Gravitational_Parameter := 4902.8;
```

### Vector Operations

```ada
with Hale_Orbital.Vectors; use Hale_Orbital.Vectors;

V1 : Vector_3D := (1.0, 2.0, 3.0);
V2 : Vector_3D := (4.0, 5.0, 6.0);

Sum    : Vector_3D := V1 + V2;           -- Vector addition
Diff   : Vector_3D := V1 - V2;           -- Vector subtraction
Scaled : Vector_3D := 2.0 * V1;          -- Scalar multiplication
Dot_P  : Real := Dot (V1, V2);           -- Dot product
Cross_P: Vector_3D := Cross (V1, V2);    -- Cross product
Mag    : Real := Magnitude (V1);         -- Euclidean magnitude
Unit   : Vector_3D := Normalize (V1);    -- Unit vector
```

## Next Steps

1. **Explore Examples**: Check `ada/examples/` for more complete examples
2. **Read the API**: Browse `ada/src/` for package specifications
3. **Run Tests**: Execute `ada/tests/obj/run_tests` to verify installation
4. **Read Rationale**: See `docs/rationale/` for design decisions

## Troubleshooting

### "gnat: command not found"
Ensure GNAT is installed and in your PATH. Try `which gnat` or use Alire.

### Build errors about missing packages
Build the library first: `gprbuild -P hale_orbital.gpr`

### Floating-point precision issues
The library uses `Long_Float` (64-bit IEEE 754). For extreme precision needs, consider validation against Vallado's test cases.

## References

- Hale, F.J. (1994). *Introduction to Space Flight*. Prentice Hall.
- Vallado, D.A. (2013). *Fundamentals of Astrodynamics and Applications*. 4th ed.
- Battin, R.H. (1999). *An Introduction to the Mathematics and Methods of Astrodynamics*. AIAA.
