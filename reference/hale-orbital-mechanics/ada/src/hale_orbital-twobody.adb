-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Two-Body Dynamics Body
-------------------------------------------------------------------------------

with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Vectors; use Hale_Orbital.Vectors;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;

package body Hale_Orbital.Twobody
   with SPARK_Mode => Off  --  Body uses generic instantiation and exceptions
is

   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   ---------------------------------------------------------------------------
   -- Energy and Momentum
   ---------------------------------------------------------------------------

   function Specific_Energy (R  : Position_Vector;
                             V  : Velocity_Vector;
                             Mu : Gravitational_Parameter)
      return Hale_Orbital.Types.Specific_Energy
   is
      R_Mag : constant Real := Magnitude (R);
      V_Mag_Sq : constant Real := Magnitude_Squared (V);
   begin
      if R_Mag < 1.0e-10 then
         raise Physical_Error with "Position vector magnitude too small";
      end if;
      --  epsilon = v^2/2 - mu/r
      return Types.Specific_Energy (V_Mag_Sq / 2.0 - Real (Mu) / R_Mag);
   end Specific_Energy;

   function Specific_Energy (A  : Distance_Km;
                             Mu : Gravitational_Parameter)
      return Hale_Orbital.Types.Specific_Energy
   is
   begin
      if abs (Real (A)) < 1.0e-10 then
         raise Physical_Error with "Semi-major axis too small";
      end if;
      --  epsilon = -mu / (2*a)
      return Types.Specific_Energy (-Real (Mu) / (2.0 * Real (A)));
   end Specific_Energy;

   function Angular_Momentum_Vector (R : Position_Vector;
                                     V : Velocity_Vector) return Vector_3D is
   begin
      return Cross (R, V);
   end Angular_Momentum_Vector;

   function Angular_Momentum (R : Position_Vector;
                              V : Velocity_Vector) return Specific_Angular_Momentum is
   begin
      return Specific_Angular_Momentum (Magnitude (Cross (R, V)));
   end Angular_Momentum;

   function Angular_Momentum (A  : Distance_Km;
                              E  : Real;
                              Mu : Gravitational_Parameter) return Specific_Angular_Momentum is
      P : Distance_Km;
   begin
      --  p = a(1 - e^2)
      P := Semi_Latus_Rectum (A, E);
      --  h = sqrt(mu * p)
      return Specific_Angular_Momentum (Sqrt (Real (Mu) * Real (P)));
   end Angular_Momentum;

   ---------------------------------------------------------------------------
   -- Vis-Viva Equation
   ---------------------------------------------------------------------------

   function Vis_Viva (R  : Distance_Km;
                      A  : Distance_Km;
                      Mu : Gravitational_Parameter) return Velocity_Km_S is
      V_Sq : Real;
   begin
      if Real (R) < 1.0e-10 then
         raise Physical_Error with "Radius too small";
      end if;

      --  v^2 = mu * (2/r - 1/a)
      V_Sq := Real (Mu) * (2.0 / Real (R) - 1.0 / Real (A));

      if V_Sq < 0.0 then
         raise Physical_Error with "Negative velocity squared - invalid orbit parameters";
      end if;

      return Velocity_Km_S (Sqrt (V_Sq));
   end Vis_Viva;

   function Circular_Velocity (R  : Distance_Km;
                               Mu : Gravitational_Parameter) return Velocity_Km_S is
   begin
      if Real (R) < 1.0e-10 then
         raise Physical_Error with "Radius too small";
      end if;
      --  v_c = sqrt(mu/r)
      return Velocity_Km_S (Sqrt (Real (Mu) / Real (R)));
   end Circular_Velocity;

   function Escape_Velocity (R  : Distance_Km;
                             Mu : Gravitational_Parameter) return Velocity_Km_S is
   begin
      if Real (R) < 1.0e-10 then
         raise Physical_Error with "Radius too small";
      end if;
      --  v_esc = sqrt(2*mu/r)
      return Velocity_Km_S (Sqrt (2.0 * Real (Mu) / Real (R)));
   end Escape_Velocity;

   ---------------------------------------------------------------------------
   -- Orbital Period and Mean Motion
   ---------------------------------------------------------------------------

   function Orbital_Period (A  : Distance_Km;
                            Mu : Gravitational_Parameter) return Time_Seconds is
   begin
      if Real (A) <= 0.0 then
         raise Physical_Error with "Semi-major axis must be positive for period calculation";
      end if;
      --  T = 2*pi * sqrt(a^3/mu)
      return Time_Seconds (Two_Pi * Sqrt (Real (A)**3 / Real (Mu)));
   end Orbital_Period;

   function Mean_Motion (A  : Distance_Km;
                         Mu : Gravitational_Parameter) return Real is
   begin
      if Real (A) <= 0.0 then
         raise Physical_Error with "Semi-major axis must be positive for mean motion";
      end if;
      --  n = sqrt(mu/a^3)
      return Sqrt (Real (Mu) / Real (A)**3);
   end Mean_Motion;

   ---------------------------------------------------------------------------
   -- Conic Section Geometry
   ---------------------------------------------------------------------------

   function Semi_Latus_Rectum (A : Distance_Km; E : Real) return Distance_Km is
   begin
      --  p = a(1 - e^2)
      return Distance_Km (Real (A) * (1.0 - E * E));
   end Semi_Latus_Rectum;

   function Periapsis_Distance (A : Distance_Km; E : Real) return Distance_Km is
   begin
      --  r_p = a(1 - e)
      return Distance_Km (Real (A) * (1.0 - E));
   end Periapsis_Distance;

   function Apoapsis_Distance (A : Distance_Km; E : Real) return Distance_Km is
   begin
      --  Check for non-elliptic orbit (ISS-033: use threshold for consistency)
      if E > 1.0 - Parabolic_Threshold then
         raise Invalid_Orbit with "Apoapsis undefined for parabolic/hyperbolic orbits";
      end if;
      --  r_a = a(1 + e)
      return Distance_Km (Real (A) * (1.0 + E));
   end Apoapsis_Distance;

   function Radius_At_True_Anomaly (P  : Distance_Km;
                                    E  : Real;
                                    Nu : Angle_Radians) return Distance_Km is
      Denom : Real;
   begin
      --  r = p / (1 + e*cos(nu))
      Denom := 1.0 + E * Cos (Real (Nu));
      if abs (Denom) < 1.0e-15 then
         raise Physical_Error with "Radius calculation singularity";
      end if;
      return Distance_Km (Real (P) / Denom);
   end Radius_At_True_Anomaly;

   function Semi_Major_Axis (R  : Distance_Km;
                             V  : Velocity_Km_S;
                             Mu : Gravitational_Parameter) return Distance_Km is
      Term : Real;
   begin
      --  a = 1 / (2/r - v^2/mu)
      Term := 2.0 / Real (R) - Real (V)**2 / Real (Mu);
      if abs (Term) < 1.0e-15 then
         --  Parabolic orbit, a = infinity
         raise Invalid_Orbit with "Parabolic orbit has infinite semi-major axis";
      end if;
      return Distance_Km (1.0 / Term);
   end Semi_Major_Axis;

   ---------------------------------------------------------------------------
   -- Orbit Classification
   ---------------------------------------------------------------------------

   function Classify_Orbit (E : Real) return Orbit_Type is
   begin
      if E < 0.0 then
         raise Invalid_Orbit with "Eccentricity cannot be negative";
      elsif E < Circular_Threshold then
         return Circular;
      elsif E < 1.0 - Parabolic_Threshold then
         return Elliptical;
      elsif E < 1.0 + Parabolic_Threshold then
         return Parabolic;
      else
         return Hyperbolic;
      end if;
   end Classify_Orbit;

   function Is_Closed_Orbit (E : Real) return Boolean is
   begin
      return E < 1.0 - Parabolic_Threshold;
   end Is_Closed_Orbit;

   function Is_Escape_Orbit (E : Real) return Boolean is
   begin
      return E >= 1.0 - Parabolic_Threshold;
   end Is_Escape_Orbit;

   ---------------------------------------------------------------------------
   -- Velocity Components
   ---------------------------------------------------------------------------

   function Radial_Velocity (Mu : Gravitational_Parameter;
                             H  : Specific_Angular_Momentum;
                             E  : Real;
                             Nu : Angle_Radians) return Velocity_Km_S is
   begin
      if Real (H) < 1.0e-15 then
         raise Physical_Error with "Angular momentum too small";
      end if;
      --  v_r = (mu/h) * e * sin(nu)
      return Velocity_Km_S ((Real (Mu) / Real (H)) * E * Sin (Real (Nu)));
   end Radial_Velocity;

   function Transverse_Velocity (Mu : Gravitational_Parameter;
                                 H  : Specific_Angular_Momentum;
                                 E  : Real;
                                 Nu : Angle_Radians) return Velocity_Km_S is
   begin
      if Real (H) < 1.0e-15 then
         raise Physical_Error with "Angular momentum too small";
      end if;
      --  v_t = (mu/h) * (1 + e*cos(nu))
      return Velocity_Km_S ((Real (Mu) / Real (H)) * (1.0 + E * Cos (Real (Nu))));
   end Transverse_Velocity;

   function Flight_Path_Angle (E  : Real;
                               Nu : Angle_Radians) return Angle_Radians is
      Num, Denom : Real;
   begin
      --  tan(gamma) = e*sin(nu) / (1 + e*cos(nu))
      Num := E * Sin (Real (Nu));
      Denom := 1.0 + E * Cos (Real (Nu));

      if abs (Denom) < 1.0e-15 then
         --  At the asymptote of a hyperbola
         if Num > 0.0 then
            return Angle_Radians (Half_Pi);
         else
            return Angle_Radians (-Half_Pi);
         end if;
      end if;

      return Angle_Radians (Arctan (Num, Denom));
   end Flight_Path_Angle;

   ---------------------------------------------------------------------------
   -- Eccentricity Vector
   ---------------------------------------------------------------------------

   function Eccentricity_Vector (R  : Position_Vector;
                                 V  : Velocity_Vector;
                                 Mu : Gravitational_Parameter) return Vector_3D is
      R_Mag : constant Real := Magnitude (R);
      V_Mag_Sq : constant Real := Magnitude_Squared (V);
      R_Dot_V : constant Real := Dot (R, V);
      Mu_Val : constant Real := Real (Mu);
   begin
      if R_Mag < 1.0e-10 then
         raise Physical_Error with "Position magnitude too small";
      end if;

      --  e_vec = (1/mu) * ((v^2 - mu/r)*r - (r.v)*v)
      return (1.0 / Mu_Val) * ((V_Mag_Sq - Mu_Val / R_Mag) * R - R_Dot_V * V);
   end Eccentricity_Vector;

   function Eccentricity (R  : Position_Vector;
                          V  : Velocity_Vector;
                          Mu : Gravitational_Parameter) return Real is
   begin
      return Magnitude (Eccentricity_Vector (R, V, Mu));
   end Eccentricity;

end Hale_Orbital.Twobody;
