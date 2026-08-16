-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Orbital Elements
-------------------------------------------------------------------------------
-- Conversion between state vectors and classical orbital elements.
-- Handles singularities for circular and equatorial orbits.
--
-- Reference: Hale, F.J. (1994). Introduction to Space Flight.
--            Prentice Hall. Chapters 3-4.
-------------------------------------------------------------------------------

with Hale_Orbital.Types; use Hale_Orbital.Types;

package Hale_Orbital.Elements
   with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- State to Elements Conversion
   ---------------------------------------------------------------------------

   --  Convert state vector to classical orbital elements
   --  Handles singularities:
   --    - Circular orbits (e=0): argument of periapsis undefined
   --    - Equatorial orbits (i=0): RAAN undefined
   --  Hale Chapter 4
   function State_To_Elements (R  : Position_Vector;
                               V  : Velocity_Vector;
                               Mu : Gravitational_Parameter) return Orbital_Elements
      with Global => null;

   --  Convert state vector record to elements
   function State_To_Elements (State : State_Vector;
                               Mu    : Gravitational_Parameter) return Orbital_Elements
      with Global => null;

   ---------------------------------------------------------------------------
   -- Elements to State Conversion
   ---------------------------------------------------------------------------

   --  Convert classical orbital elements to state vector
   --  Hale Chapter 4
   function Elements_To_State (Elements : Orbital_Elements;
                               Mu       : Gravitational_Parameter) return State_Vector
      with Global => null;

   --  Get position vector from orbital elements
   function Elements_To_Position (Elements : Orbital_Elements;
                                  Mu       : Gravitational_Parameter) return Position_Vector
      with Global => null;

   --  Get velocity vector from orbital elements
   function Elements_To_Velocity (Elements : Orbital_Elements;
                                  Mu       : Gravitational_Parameter) return Velocity_Vector
      with Global => null;

   ---------------------------------------------------------------------------
   -- Anomaly Conversions (Hale Chapter 4)
   ---------------------------------------------------------------------------

   --  True anomaly to eccentric anomaly (elliptical orbits)
   --  tan(E/2) = sqrt((1-e)/(1+e)) * tan(nu/2)
   function True_To_Eccentric_Anomaly (Nu : Angle_Radians;
                                       E  : Real) return Angle_Radians
      with Pre    => E >= 0.0 and then E < 1.0,
           Global => null;

   --  Eccentric anomaly to true anomaly (elliptical orbits)
   --  tan(nu/2) = sqrt((1+e)/(1-e)) * tan(E/2)
   function Eccentric_To_True_Anomaly (Ecc_Anom : Angle_Radians;
                                       E        : Real) return Angle_Radians
      with Pre    => E >= 0.0 and then E < 1.0,
           Global => null;

   --  Eccentric anomaly to mean anomaly (Kepler's equation)
   --  M = E - e*sin(E)
   function Eccentric_To_Mean_Anomaly (Ecc_Anom : Angle_Radians;
                                       E        : Real) return Angle_Radians
      with Global => null;

   --  True anomaly to mean anomaly (combined conversion)
   function True_To_Mean_Anomaly (Nu : Angle_Radians;
                                  E  : Real) return Angle_Radians
      with Pre    => E >= 0.0 and then E < 1.0,
           Global => null;

   --  Mean anomaly to eccentric anomaly (requires iteration - see Kepler package)
   --  This is just a wrapper that calls the Kepler solver
   function Mean_To_Eccentric_Anomaly (M         : Angle_Radians;
                                       E         : Real;
                                       Tolerance : Real := Default_Tolerance) return Angle_Radians
      with Pre    => E >= 0.0 and then E < 1.0
                     and then Tolerance > 0.0,
           Global => null;

   --  Mean anomaly to true anomaly
   function Mean_To_True_Anomaly (M         : Angle_Radians;
                                  E         : Real;
                                  Tolerance : Real := Default_Tolerance) return Angle_Radians
      with Pre    => E >= 0.0 and then E < 1.0
                     and then Tolerance > 0.0,
           Global => null;

   ---------------------------------------------------------------------------
   -- Hyperbolic Anomaly Conversions
   ---------------------------------------------------------------------------

   --  True anomaly to hyperbolic anomaly (hyperbolic orbits)
   --  tanh(H/2) = sqrt((e-1)/(e+1)) * tan(nu/2)
   function True_To_Hyperbolic_Anomaly (Nu : Angle_Radians;
                                        E  : Real) return Real
      with Pre    => E > 1.0,
           Global => null;

   --  Hyperbolic anomaly to true anomaly
   function Hyperbolic_To_True_Anomaly (H : Real;
                                        E : Real) return Angle_Radians
      with Pre    => E > 1.0,
           Global => null;

   --  Hyperbolic anomaly to mean anomaly
   --  M = e*sinh(H) - H
   function Hyperbolic_To_Mean_Anomaly (H : Real;
                                        E : Real) return Real
      with Global => null;

   ---------------------------------------------------------------------------
   -- Angle Normalization
   ---------------------------------------------------------------------------

   --  Normalize angle to [0, 2*pi)
   function Normalize_Angle (Angle : Angle_Radians) return Angle_Radians
      with Global => null;

   --  Normalize angle to [-pi, pi)
   function Normalize_Angle_Symmetric (Angle : Angle_Radians) return Angle_Radians
      with Global => null;

   ---------------------------------------------------------------------------
   -- Element Validation
   ---------------------------------------------------------------------------

   --  Check if orbital elements are physically valid
   function Is_Valid (Elements : Orbital_Elements) return Boolean
      with Global => null;

   --  Get orbit type from elements
   function Get_Orbit_Type (Elements : Orbital_Elements) return Orbit_Type
      with Global => null;

end Hale_Orbital.Elements;
