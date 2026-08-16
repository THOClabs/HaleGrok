-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Core Type Definitions
-------------------------------------------------------------------------------
-- This package defines the fundamental types used throughout the library.
-- Types are designed to enforce dimensional correctness at compile time.
--
-- Precision: IEEE 754 Double Precision (Long_Float)
-- Tolerance: 1.0e-12 for iterative solvers
-------------------------------------------------------------------------------

package Hale_Orbital.Types
   with SPARK_Mode => On
is

   pragma Pure;

   ---------------------------------------------------------------------------
   -- Fundamental Numeric Types
   ---------------------------------------------------------------------------

   --  Base real type for all calculations (64-bit IEEE 754)
   type Real is new Long_Float;

   --  Default solver tolerance
   Default_Tolerance : constant Real := 1.0e-12;

   --  Maximum iterations for solvers
   Default_Max_Iterations : constant Positive := 50;

   ---------------------------------------------------------------------------
   -- Dimensional Types (Compile-Time Unit Safety)
   ---------------------------------------------------------------------------

   --  Distance in kilometers
   type Distance_Km is new Real;

   --  Velocity in kilometers per second
   type Velocity_Km_S is new Real;

   --  Time in seconds
   type Time_Seconds is new Real;

   --  Angles in radians
   type Angle_Radians is new Real;

   --  Mass in kilograms
   type Mass_Kg is new Real;

   --  Gravitational parameter (km^3/s^2)
   type Gravitational_Parameter is new Real;

   --  Specific energy (km^2/s^2)
   type Specific_Energy is new Real;

   --  Specific angular momentum (km^2/s)
   type Specific_Angular_Momentum is new Real;

   ---------------------------------------------------------------------------
   -- Vector Types
   ---------------------------------------------------------------------------

   --  Generic 3D vector
   type Vector_3D is array (1 .. 3) of Real;

   --  Position vector (km)
   subtype Position_Vector is Vector_3D;

   --  Velocity vector (km/s)
   subtype Velocity_Vector is Vector_3D;

   --  Zero vector constant
   Zero_Vector : constant Vector_3D := (0.0, 0.0, 0.0);

   --  Unit vectors
   Unit_X : constant Vector_3D := (1.0, 0.0, 0.0);
   Unit_Y : constant Vector_3D := (0.0, 1.0, 0.0);
   Unit_Z : constant Vector_3D := (0.0, 0.0, 1.0);

   ---------------------------------------------------------------------------
   -- Matrix Types
   ---------------------------------------------------------------------------

   --  3x3 matrix for rotations and transformations
   type Matrix_3x3 is array (1 .. 3, 1 .. 3) of Real;

   --  6x6 matrix for state transition matrices
   type Matrix_6x6 is array (1 .. 6, 1 .. 6) of Real;

   --  Identity matrices
   Identity_3x3 : constant Matrix_3x3 :=
      ((1.0, 0.0, 0.0),
       (0.0, 1.0, 0.0),
       (0.0, 0.0, 1.0));

   ---------------------------------------------------------------------------
   -- State Vector
   ---------------------------------------------------------------------------

   --  Complete state (position and velocity)
   type State_Vector is record
      Position : Position_Vector;
      Velocity : Velocity_Vector;
   end record;

   ---------------------------------------------------------------------------
   -- Orbital Elements (Classical Keplerian)
   ---------------------------------------------------------------------------

   type Orbital_Elements is record
      Semi_Major_Axis       : Distance_Km;       -- a: semi-major axis
      Eccentricity          : Real;              -- e: eccentricity (dimensionless)
      Inclination           : Angle_Radians;     -- i: inclination
      RAAN                  : Angle_Radians;     -- Omega: right ascension of ascending node
      Argument_Of_Periapsis : Angle_Radians;     -- omega: argument of periapsis
      True_Anomaly          : Angle_Radians;     -- nu: true anomaly
   end record;

   ---------------------------------------------------------------------------
   -- Orbit Classification
   ---------------------------------------------------------------------------

   type Orbit_Type is (Circular, Elliptical, Parabolic, Hyperbolic);

   --  Eccentricity thresholds for orbit classification
   Circular_Threshold  : constant Real := 1.0e-10;
   Parabolic_Threshold : constant Real := 1.0e-10;

   --  Threshold for high eccentricity where Newton-Raphson needs better initial guess
   --  Kepler equation convergence degrades for e > 0.8
   High_Eccentricity_Threshold : constant Real := 0.8;

   --  Numerical threshold for division safety (see DEC-009)
   --  Values below this are considered too small for safe division
   --  Approximately 5× machine epsilon for IEEE 754 double precision
   Small_Threshold : constant Real := 1.0e-15;

   ---------------------------------------------------------------------------
   -- Lambert Solver Constants (ISS-062, ISS-063, ISS-065)
   ---------------------------------------------------------------------------

   --  Z parameter bounds for Lambert bisection (universal variable formulation)
   --  Z < 0: hyperbolic orbit, Z > 0: elliptic orbit, Z = 0: parabolic
   --  Bounds are ±4π² to cover single-revolution transfers
   --  Reference: Battin (1999), Section 7.6
   Z_Bound_Hyperbolic : constant Real := -39.478417604357432;  -- -4π²
   Z_Bound_Elliptic   : constant Real :=  39.478417604357432;  --  4π²

   --  Threshold for degenerate (180-degree) transfer detection
   --  |sin(θ)| < threshold indicates nearly collinear positions
   Degenerate_Transfer_Threshold : constant Real := 1.0e-6;

   ---------------------------------------------------------------------------
   -- Transfer Orbit Types
   ---------------------------------------------------------------------------

   type Transfer_Direction is (Short_Way, Long_Way);
   type Transfer_Type is (Type_I, Type_II);

   ---------------------------------------------------------------------------
   -- Maneuver Results
   ---------------------------------------------------------------------------

   type Transfer_Result is record
      Delta_V1       : Velocity_Km_S;    -- First burn magnitude
      Delta_V2       : Velocity_Km_S;    -- Second burn magnitude
      Total_Delta_V  : Velocity_Km_S;    -- Total delta-V
      Transfer_Time  : Time_Seconds;     -- Time of flight
      Transfer_Orbit : Orbital_Elements; -- Transfer orbit elements
   end record;

   ---------------------------------------------------------------------------
   -- Lambert Solution
   ---------------------------------------------------------------------------

   type Lambert_Solution is record
      V1        : Velocity_Vector;  -- Departure velocity
      V2        : Velocity_Vector;  -- Arrival velocity
      A         : Distance_Km;      -- Semi-major axis of transfer
      Converged : Boolean;          -- Did the solver converge?
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   --  Raised when an iterative solver fails to converge
   Convergence_Error : exception;

   --  Raised when orbit parameters are physically invalid
   Invalid_Orbit : exception;

   --  Raised when a calculation violates physical constraints
   Physical_Error : exception;

   --  Raised when singularity conditions are encountered
   Singularity_Error : exception;

end Hale_Orbital.Types;
