-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Lambert Problem Solver
-------------------------------------------------------------------------------
-- Solves the Lambert boundary-value problem: given two position vectors
-- and a time of flight, find the orbit connecting them.
--
-- Reference: Hale, F.J. (1994). Introduction to Space Flight.
--            Prentice Hall. Chapter 5.
--
-- SPARK Status: Contracts enable verification of input validity.
-------------------------------------------------------------------------------

with Hale_Orbital.Types;     use Hale_Orbital.Types;
with Hale_Orbital.Vectors;   use Hale_Orbital.Vectors;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;

package Hale_Orbital.Lambert
   with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Lambert Solution Type
   ---------------------------------------------------------------------------

   type Lambert_Result is record
      V1         : Velocity_Vector;    -- Departure velocity at R1
      V2         : Velocity_Vector;    -- Arrival velocity at R2
      A          : Distance_Km;        -- Semi-major axis of transfer orbit
      E          : Real;               -- Eccentricity of transfer orbit
      Iterations : Natural;            -- Number of iterations to converge
      Converged  : Boolean;            -- Did solver converge?
   end record;

   --  Array of solutions for multi-revolution cases
   type Lambert_Solution_Array is array (Natural range <>) of Lambert_Result;

   ---------------------------------------------------------------------------
   -- Lambert Solvers
   ---------------------------------------------------------------------------

   --  Solve Lambert's problem (single revolution)
   --  R1: Initial position vector
   --  R2: Final position vector
   --  Tof: Time of flight
   --  Mu: Gravitational parameter
   --  Long_Way: If true, use the long-way trajectory (> 180 degrees)
   --  Tolerance: Convergence tolerance
   function Solve_Lambert (R1        : Position_Vector;
                           R2        : Position_Vector;
                           Tof       : Time_Seconds;
                           Mu        : Gravitational_Parameter;
                           Long_Way  : Boolean := False;
                           Tolerance : Real := Default_Tolerance) return Lambert_Result
      with Pre  => Magnitude (R1) > 0.0
                   and Magnitude (R2) > 0.0
                   and Real (Tof) > 0.0
                   and Real (Mu) > 0.0
                   and Tolerance > 0.0,
           Post => (if Solve_Lambert'Result.Converged then
                      Solve_Lambert'Result.Iterations <= 100
                      and Real (Solve_Lambert'Result.A) > 0.0),
           Global => null;

   --  Solve Lambert's problem with multi-revolution options.
   --  Returns all found solutions: the zero-revolution transfer (when the
   --  single-revolution solver converges) plus, for each N in 1 .. Max_Revs,
   --  the solutions of the true N-rev elliptic band
   --     z in (4*pi**2*N**2, 4*pi**2*(N+1)**2)   (z = dE**2).
   --  TOF(z) is U-shaped over each band (+infinity at both edges, one
   --  interior minimum), so a band contributes 0 or 2 roots (short and
   --  long period), found by bisection on the two monotone branches around
   --  the minimum.  Results are de-duplicated (no two entries within
   --  tolerance of the same root), so 'Length <= 1 + 2*Max_Revs, and
   --  'Length equals Count_Multi_Rev_Solutions for the same arguments with
   --  Long_Way = False (both run the same enumeration).
   function Solve_Lambert_Multi (R1       : Position_Vector;
                                 R2       : Position_Vector;
                                 Tof      : Time_Seconds;
                                 Mu       : Gravitational_Parameter;
                                 Max_Revs : Natural := 0;
                                 Long_Way : Boolean := False) return Lambert_Solution_Array
      with Pre => Magnitude (R1) > 0.0
                  and Magnitude (R2) > 0.0
                  and Real (Tof) > 0.0
                  and Real (Mu) > 0.0,
           Global => null;

   ---------------------------------------------------------------------------
   -- Utility Functions
   ---------------------------------------------------------------------------

   --  Parabolic minimum time of flight for the transfer geometry
   --  (Barker/Battin):
   --     t_p = (1/3) * sqrt(2/mu) * (s**1.5 - sign * (s - c)**1.5)
   --  with s the semiperimeter, c the chord, and sign = +1 for the short
   --  way / -1 for the long way.  Elliptic zero-revolution solutions exist
   --  exactly for TOF at or above this bound; Solution_Exists compares
   --  against it.  NOTE: despite the historic name this is the parabolic
   --  TOF bound, not the TOF of the minimum-energy ellipse.
   function Minimum_Energy_Tof (R1 : Position_Vector;
                                R2 : Position_Vector;
                                Mu : Gravitational_Parameter;
                                Long_Way : Boolean := False) return Time_Seconds
      with Pre  => Magnitude (R1) > 0.0
                   and Magnitude (R2) > 0.0
                   and Real (Mu) > 0.0,
           Post => Real (Minimum_Energy_Tof'Result) >= 0.0,
           Global => null;

   --  Compute the transfer angle between two positions
   function Transfer_Angle (R1 : Position_Vector;
                            R2 : Position_Vector;
                            Long_Way : Boolean := False) return Angle_Radians
      with Pre  => Magnitude (R1) > 0.0 and Magnitude (R2) > 0.0,
           Post => Real (Transfer_Angle'Result) >= 0.0
                   and Real (Transfer_Angle'Result) <= Two_Pi,
           Global => null;

   --  Check if a zero-revolution elliptic Lambert solution exists: True
   --  exactly when Tof is at or above the way-specific parabolic bound
   --  returned by Minimum_Energy_Tof
   function Solution_Exists (R1       : Position_Vector;
                             R2       : Position_Vector;
                             Tof      : Time_Seconds;
                             Mu       : Gravitational_Parameter;
                             Long_Way : Boolean := False) return Boolean
      with Pre => Magnitude (R1) > 0.0
                  and Magnitude (R2) > 0.0
                  and Real (Tof) > 0.0
                  and Real (Mu) > 0.0,
           Global => null;

   ---------------------------------------------------------------------------
   -- Orbit from Lambert Solution
   ---------------------------------------------------------------------------

   --  Get orbital elements from Lambert solution
   --  Pre (Q-14): the solution must come from a converged solve with a
   --  physically meaningful (positive semi-major axis) transfer orbit.
   function Get_Transfer_Elements (R1     : Position_Vector;
                                   Result : Lambert_Result;
                                   Mu     : Gravitational_Parameter) return Orbital_Elements
      with Pre    => Magnitude (R1) > 0.0
                     and then Real (Mu) > 0.0
                     and then Result.Converged
                     and then Real (Result.A) > 0.0,
           Global => null;

   --  Get the delta-V required at each endpoint
   --  Pre (Q-14): endpoint velocities must be finite ('Valid is False for
   --  NaN and infinities) and the solution converged and non-degenerate.
   function Departure_Delta_V (V_Initial : Velocity_Vector;
                               Result    : Lambert_Result) return Velocity_Km_S
      with Pre    => V_Initial (1)'Valid
                     and then V_Initial (2)'Valid
                     and then V_Initial (3)'Valid
                     and then Result.Converged
                     and then Real (Result.A) > 0.0,
           Global => null;

   function Arrival_Delta_V (V_Final : Velocity_Vector;
                             Result  : Lambert_Result) return Velocity_Km_S
      with Pre    => V_Final (1)'Valid
                     and then V_Final (2)'Valid
                     and then V_Final (3)'Valid
                     and then Result.Converged
                     and then Real (Result.A) > 0.0,
           Global => null;

   --  Total delta-V for the transfer
   function Total_Delta_V (V_Initial : Velocity_Vector;
                           V_Final   : Velocity_Vector;
                           Result    : Lambert_Result) return Velocity_Km_S
      with Pre    => V_Initial (1)'Valid
                     and then V_Initial (2)'Valid
                     and then V_Initial (3)'Valid
                     and then V_Final (1)'Valid
                     and then V_Final (2)'Valid
                     and then V_Final (3)'Valid
                     and then Result.Converged
                     and then Real (Result.A) > 0.0,
           Global => null;

   ---------------------------------------------------------------------------
   -- Multi-Revolution Utilities
   ---------------------------------------------------------------------------

   --  Compute minimum TOF for N complete revolutions.
   --  N = 0: the way-specific parabolic bound (see Minimum_Energy_Tof).
   --  N >= 1: TOF at the interior minimum of the true N-rev band, located
   --  by the same minimization Solve_Lambert_Multi uses; N-rev solutions
   --  exist exactly for requested TOF at or above this value.
   function Min_Tof_N_Revs (R1       : Position_Vector;
                            R2       : Position_Vector;
                            Mu       : Gravitational_Parameter;
                            N_Revs   : Natural;
                            Long_Way : Boolean := False) return Time_Seconds
      with Pre => Magnitude (R1) > 0.0
                  and Magnitude (R2) > 0.0
                  and Real (Mu) > 0.0,
           Global => null;

   --  Check if transfer is degenerate (180 degree, collinear positions)
   function Is_Degenerate_Transfer (R1 : Position_Vector;
                                    R2 : Position_Vector) return Boolean
      with Pre => Magnitude (R1) > 0.0 and Magnitude (R2) > 0.0,
           Global => null;

   --  Number of solutions the multi-revolution enumeration finds for this
   --  TOF: runs the SAME enumeration as Solve_Lambert_Multi (with
   --  Long_Way = False) and returns the length of its solution array, so
   --  count and returned solutions cannot disagree
   function Count_Multi_Rev_Solutions (R1       : Position_Vector;
                                       R2       : Position_Vector;
                                       Tof      : Time_Seconds;
                                       Mu       : Gravitational_Parameter;
                                       Max_Revs : Natural := 5) return Natural
      with Pre => Magnitude (R1) > 0.0
                  and Magnitude (R2) > 0.0
                  and Real (Tof) > 0.0
                  and Real (Mu) > 0.0,
           Global => null;

end Hale_Orbital.Lambert;
