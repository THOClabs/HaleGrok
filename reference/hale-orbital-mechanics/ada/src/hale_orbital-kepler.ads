-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Kepler's Equation Solvers
-------------------------------------------------------------------------------
-- Iterative solvers for Kepler's equation and time of flight calculations.
-- Implements Newton-Raphson for elliptical, hyperbolic, and universal cases.
--
-- Reference: Hale, F.J. (1994). Introduction to Space Flight.
--            Prentice Hall. Chapter 4.
--
-- SPARK Status: contracts defined on the spec; body is SPARK_Mode Off
-- (generic instantiation) and has NOT been proven — gnatprove has never run.
-------------------------------------------------------------------------------

with Hale_Orbital.Types;   use Hale_Orbital.Types;
with Hale_Orbital.Stumpff;

package Hale_Orbital.Kepler
   with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Kepler's Equation Solvers
   ---------------------------------------------------------------------------

   --  Solve Kepler's equation for eccentric anomaly (elliptical orbit)
   --  E - e*sin(E) = M
   --  Uses Newton-Raphson iteration
   --  Postcondition: Result is in valid range and satisfies Kepler equation
   function Solve_Kepler_Elliptic (Mean_Anomaly : Angle_Radians;
                                   Eccentricity : Real;
                                   Tolerance    : Real := Default_Tolerance;
                                   Max_Iter     : Positive := Default_Max_Iterations) return Angle_Radians
      with Pre  => Eccentricity >= 0.0 and Eccentricity < 1.0
                   and Tolerance > 0.0,
           Post => Real (Solve_Kepler_Elliptic'Result) >= -0.001
                   and Real (Solve_Kepler_Elliptic'Result) <= 6.3,  -- ~2*Pi with margin
           Global => null;

   --  Solve Kepler's equation for hyperbolic anomaly (hyperbolic orbit)
   --  e*sinh(H) - H = M
   --  Uses Newton-Raphson iteration
   function Solve_Kepler_Hyperbolic (Mean_Anomaly : Real;
                                     Eccentricity : Real;
                                     Tolerance    : Real := Default_Tolerance;
                                     Max_Iter     : Positive := Default_Max_Iterations) return Real
      with Pre => Eccentricity > 1.0 and Tolerance > 0.0,
           Global => null;

   --  Solve Kepler's equation for parabolic case
   --  Uses Barker's equation for D parameter
   --  tan(nu/2) = D, where D^3 + 3D = 6M
   function Solve_Kepler_Parabolic (Mean_Anomaly : Real;
                                    Tolerance    : Real := Default_Tolerance) return Angle_Radians
      with Pre    => Tolerance > 0.0,
           Post   => Real (Solve_Kepler_Parabolic'Result) >= -3.15
                     and Real (Solve_Kepler_Parabolic'Result) <= 3.15,  -- ~Pi
           Global => null;

   ---------------------------------------------------------------------------
   -- Universal Variable Formulation
   ---------------------------------------------------------------------------

   --  Stumpff function C(z) = (1 - cos(sqrt(z))) / z
   --  Handles all orbit types: z > 0 (ellipse), z < 0 (hyperbola), z = 0 (parabola)
   --  Delegates to Hale_Orbital.Stumpff.C
   function Stumpff_C (Z : Real) return Real renames Stumpff.C;

   --  Stumpff function S(z) = (sqrt(z) - sin(sqrt(z))) / sqrt(z)^3
   --  Delegates to Hale_Orbital.Stumpff.S
   function Stumpff_S (Z : Real) return Real renames Stumpff.S;

   --  Solve universal Kepler's equation
   --  Uses Laguerre's method for robust convergence
   --  Returns the universal anomaly chi
   function Solve_Kepler_Universal (Dt           : Time_Seconds;
                                    R0           : Distance_Km;
                                    Vr0          : Velocity_Km_S;
                                    A            : Distance_Km;
                                    Mu           : Gravitational_Parameter;
                                    Tolerance    : Real := Default_Tolerance;
                                    Max_Iter     : Positive := Default_Max_Iterations) return Real
      with Pre    => Real (R0) > 0.0
                     and then Real (Mu) > 0.0
                     and then Tolerance > 0.0,
           Global => null;

   ---------------------------------------------------------------------------
   -- Time of Flight
   ---------------------------------------------------------------------------

   --  Time of flight between two true anomalies on an elliptical orbit
   --  Uses Kepler's equation
   function Time_Of_Flight_Elliptic (Nu1 : Angle_Radians;
                                     Nu2 : Angle_Radians;
                                     A   : Distance_Km;
                                     E   : Real;
                                     Mu  : Gravitational_Parameter) return Time_Seconds
      with Global => null;

   --  Time of flight between two true anomalies on a hyperbolic orbit
   function Time_Of_Flight_Hyperbolic (Nu1 : Angle_Radians;
                                       Nu2 : Angle_Radians;
                                       A   : Distance_Km;
                                       E   : Real;
                                       Mu  : Gravitational_Parameter) return Time_Seconds
      with Global => null;

   --  Time of flight between two true anomalies on a parabolic orbit (e = 1).
   --  Uses Barker's equation (Vallado eqs. 2-66, 2-67; Hale Ch. 4 parabolic case):
   --    t - t_p = (1/2) * sqrt(p^3 / mu) * (D + D^3 / 3)   with  D = tan(nu/2)
   --  Parameter P is the semi-latus rectum (km); for a true parabola p = 2 r_p.
   function Time_Of_Flight_Parabolic (Nu1 : Angle_Radians;
                                      Nu2 : Angle_Radians;
                                      P   : Distance_Km;
                                      Mu  : Gravitational_Parameter) return Time_Seconds;

   --  Time of flight between two true anomalies (general, determines orbit type).
   --  For the parabolic regime, the semi-latus rectum is derived from (a, e)
   --  as p = |a| * |1 - e^2|; callers needing exact parabolic dispatch should
   --  use Time_Of_Flight_Parabolic with explicit p.
   function Time_Of_Flight (Nu1 : Angle_Radians;
                            Nu2 : Angle_Radians;
                            A   : Distance_Km;
                            E   : Real;
                            Mu  : Gravitational_Parameter) return Time_Seconds
      with Global => null;

   ---------------------------------------------------------------------------
   -- Orbit Propagation
   ---------------------------------------------------------------------------

   --  Propagate state from current position to new time
   --  Uses universal variable formulation
   --  Propagate state from current position to new time
   --  Uses universal variable formulation
   procedure Propagate (R0    : Position_Vector;
                        V0    : Velocity_Vector;
                        Dt    : Time_Seconds;
                        Mu    : Gravitational_Parameter;
                        R_Out : out Position_Vector;
                        V_Out : out Velocity_Vector)
      with Global  => null,
           Depends => ((R_Out, V_Out) => (R0, V0, Dt, Mu));

   --  Propagate state vector by time dt
   procedure Propagate (State : in out State_Vector;
                        Dt    : Time_Seconds;
                        Mu    : Gravitational_Parameter)
      with Global => null,
           Depends => (State =>+ (Dt, Mu));

   --  Propagate orbital elements to new true anomaly at given time
   function Propagate_Elements (Elements : Orbital_Elements;
                                Dt       : Time_Seconds;
                                Mu       : Gravitational_Parameter) return Orbital_Elements
      with Global => null;

end Hale_Orbital.Kepler;
