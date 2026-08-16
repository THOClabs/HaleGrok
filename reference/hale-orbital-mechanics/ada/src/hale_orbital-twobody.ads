-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Two-Body Dynamics
-------------------------------------------------------------------------------
-- Two-body orbital mechanics equations from Hale Chapters 2-3.
-- Implements the fundamental equations of Keplerian motion.
--
-- Reference: Hale, F.J. (1994). Introduction to Space Flight.
--            Prentice Hall. Chapters 2-3.
--
-- SPARK Status: contracts defined on the spec; body is SPARK_Mode Off
-- (generic instantiation) and has NOT been proven — gnatprove has never run.
-------------------------------------------------------------------------------

with Hale_Orbital.Types; use Hale_Orbital.Types;
with Hale_Orbital.Vectors;

package Hale_Orbital.Twobody
   with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Energy and Momentum (Hale Chapter 2)
   ---------------------------------------------------------------------------

   --  Specific orbital energy (km^2/s^2)
   --  epsilon = v^2/2 - mu/r
   --  Hale Eq. 2.14
   function Specific_Energy (R  : Position_Vector;
                             V  : Velocity_Vector;
                             Mu : Gravitational_Parameter)
      return Hale_Orbital.Types.Specific_Energy
      with Pre    => Vectors.Magnitude_Squared (R) > 0.0
                     and then Real (Mu) > 0.0,
           Global => null;

   --  Specific orbital energy from semi-major axis
   --  epsilon = -mu / (2*a)
   function Specific_Energy (A  : Distance_Km;
                             Mu : Gravitational_Parameter)
      return Hale_Orbital.Types.Specific_Energy
      with Pre    => abs (Real (A)) > Small_Threshold
                     and then Real (Mu) > 0.0,
           Global => null;

   --  Specific angular momentum vector (km^2/s)
   --  h = r x v
   --  Hale Eq. 2.28
   function Angular_Momentum_Vector (R : Position_Vector;
                                     V : Velocity_Vector) return Vector_3D
      with Global => null;

   --  Specific angular momentum magnitude
   function Angular_Momentum (R : Position_Vector;
                              V : Velocity_Vector) return Specific_Angular_Momentum
      with Global => null;

   --  Specific angular momentum from orbital parameters
   --  h = sqrt(mu * p) where p = a(1-e^2)
   function Angular_Momentum (A  : Distance_Km;
                              E  : Real;
                              Mu : Gravitational_Parameter) return Specific_Angular_Momentum
      with Global => null;

   ---------------------------------------------------------------------------
   -- Vis-Viva Equation (Hale Chapter 2)
   ---------------------------------------------------------------------------

   --  Velocity magnitude at given radius from vis-viva equation
   --  v = sqrt(mu * (2/r - 1/a))
   --  Hale Eq. 2.19
   function Vis_Viva (R  : Distance_Km;
                      A  : Distance_Km;
                      Mu : Gravitational_Parameter) return Velocity_Km_S
      with Pre    => Real (R) > 0.0
                     and then abs (Real (A)) > Small_Threshold
                     and then Real (Mu) > 0.0,
           Post   => Real (Vis_Viva'Result) >= 0.0,
           Global => null;

   --  Velocity magnitude for circular orbit
   --  v_c = sqrt(mu/r)
   function Circular_Velocity (R  : Distance_Km;
                               Mu : Gravitational_Parameter) return Velocity_Km_S
      with Pre    => Real (R) > 0.0
                     and then Real (Mu) > 0.0,
           Post   => Real (Circular_Velocity'Result) > 0.0,
           Global => null;

   --  Escape velocity at given radius
   --  v_esc = sqrt(2*mu/r)
   function Escape_Velocity (R  : Distance_Km;
                             Mu : Gravitational_Parameter) return Velocity_Km_S
      with Pre    => Real (R) > 0.0
                     and then Real (Mu) > 0.0,
           Post   => Real (Escape_Velocity'Result) > 0.0,
           Global => null;

   ---------------------------------------------------------------------------
   -- Orbital Period and Mean Motion (Hale Chapter 2)
   ---------------------------------------------------------------------------

   --  Orbital period for elliptical orbit
   --  T = 2*pi * sqrt(a^3/mu)
   --  Hale Eq. 2.24
   function Orbital_Period (A  : Distance_Km;
                            Mu : Gravitational_Parameter) return Time_Seconds
      with Pre    => Real (A) > 0.0
                     and then Real (Mu) > 0.0,
           Post   => Real (Orbital_Period'Result) > 0.0,
           Global => null;

   --  Mean motion (angular rate)
   --  n = sqrt(mu/a^3) = 2*pi/T
   function Mean_Motion (A  : Distance_Km;
                         Mu : Gravitational_Parameter) return Real
      with Pre    => Real (A) > 0.0
                     and then Real (Mu) > 0.0,
           Post   => Mean_Motion'Result > 0.0,
           Global => null;

   ---------------------------------------------------------------------------
   -- Conic Section Geometry (Hale Chapter 3)
   ---------------------------------------------------------------------------

   --  Semi-latus rectum
   --  p = a(1 - e^2) for ellipse/hyperbola
   --  Hale Eq. 3.5
   function Semi_Latus_Rectum (A : Distance_Km; E : Real) return Distance_Km
      with Global => null;

   --  Periapsis distance (closest approach)
   --  r_p = a(1 - e)
   --  Hale Eq. 3.7
   function Periapsis_Distance (A : Distance_Km; E : Real) return Distance_Km
      with Global => null;

   --  Apoapsis distance (farthest point, ellipse only)
   --  r_a = a(1 + e)
   --  Hale Eq. 3.8
   function Apoapsis_Distance (A : Distance_Km; E : Real) return Distance_Km
      with Global => null;

   --  Radius at given true anomaly (orbit equation)
   --  r = p / (1 + e*cos(nu))
   --  Hale Eq. 3.4
   function Radius_At_True_Anomaly (P  : Distance_Km;
                                    E  : Real;
                                    Nu : Angle_Radians) return Distance_Km
      with Global => null;

   --  Semi-major axis from radius and velocity
   --  a = 1 / (2/r - v^2/mu)
   function Semi_Major_Axis (R  : Distance_Km;
                             V  : Velocity_Km_S;
                             Mu : Gravitational_Parameter) return Distance_Km
      with Global => null;

   ---------------------------------------------------------------------------
   -- Orbit Classification
   ---------------------------------------------------------------------------

   --  Classify orbit type based on eccentricity
   function Classify_Orbit (E : Real) return Orbit_Type
      with Global => null;

   --  Check if orbit is closed (elliptical or circular)
   function Is_Closed_Orbit (E : Real) return Boolean
      with Global => null;

   --  Check if orbit escapes (parabolic or hyperbolic)
   function Is_Escape_Orbit (E : Real) return Boolean
      with Global => null;

   ---------------------------------------------------------------------------
   -- Velocity Components (Hale Chapter 3)
   ---------------------------------------------------------------------------

   --  Radial velocity component (along radius vector)
   --  v_r = (mu/h) * e * sin(nu)
   function Radial_Velocity (Mu : Gravitational_Parameter;
                             H  : Specific_Angular_Momentum;
                             E  : Real;
                             Nu : Angle_Radians) return Velocity_Km_S
      with Pre    => Real (Mu) > 0.0
                     and then abs (Real (H)) > Small_Threshold,
           Global => null;

   --  Transverse velocity component (perpendicular to radius)
   --  v_t = (mu/h) * (1 + e*cos(nu))
   function Transverse_Velocity (Mu : Gravitational_Parameter;
                                 H  : Specific_Angular_Momentum;
                                 E  : Real;
                                 Nu : Angle_Radians) return Velocity_Km_S
      with Pre    => Real (Mu) > 0.0
                     and then abs (Real (H)) > Small_Threshold,
           Global => null;

   --  Flight path angle (angle between velocity and local horizontal)
   --  tan(gamma) = e*sin(nu) / (1 + e*cos(nu))
   function Flight_Path_Angle (E  : Real;
                               Nu : Angle_Radians) return Angle_Radians
      with Global => null;

   ---------------------------------------------------------------------------
   -- Eccentricity Vector
   ---------------------------------------------------------------------------

   --  Eccentricity vector pointing toward periapsis
   --  e_vec = (1/mu) * ((v^2 - mu/r)*r - (r.v)*v)
   function Eccentricity_Vector (R  : Position_Vector;
                                 V  : Velocity_Vector;
                                 Mu : Gravitational_Parameter) return Vector_3D
      with Pre    => Vectors.Magnitude_Squared (R) > 0.0
                     and then Real (Mu) > 0.0,
           Global => null;

   --  Eccentricity magnitude from state vectors
   function Eccentricity (R  : Position_Vector;
                          V  : Velocity_Vector;
                          Mu : Gravitational_Parameter) return Real
      with Pre    => Vectors.Magnitude_Squared (R) > 0.0
                     and then Real (Mu) > 0.0,
           Post   => Eccentricity'Result >= 0.0,
           Global => null;

end Hale_Orbital.Twobody;
